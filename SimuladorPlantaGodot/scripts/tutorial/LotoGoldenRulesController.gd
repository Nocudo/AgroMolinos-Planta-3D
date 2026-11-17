class_name LotoGoldenRulesController
extends Node

# ==============================================================================
# CONTROLADOR DE LAS 5 REGLAS DE ORO DE SEGURIDAD ELÉCTRICA (RETIE / LOTO)
# Exige secuencia estricta 1 -> 2 -> 3 -> 4 -> 5 antes de intervenir circuitos
# ==============================================================================

const GOLDEN_RULES: Array[Dictionary] = [
	{"step": 1, "name": "Regla 1: Corte Visible", "desc": "Abrir seccionador/breaker principal en CCM 460 V (apertura visible de circuito)."},
	{"step": 2, "name": "Regla 2: Bloqueo y Tarjeteo (LOTO)", "desc": "Colocar candado rojo de seguridad y tarjeta 'PELIGRO - NO OPERAR' (Kit LOTO [5])."},
	{"step": 3, "name": "Regla 3: Verificación de Ausencia de Tensión", "desc": "Medir 0.0 V AC entre fases L1-L2, L2-L3, L3-L1 y a tierra con Multímetro CAT III [4]."},
	{"step": 4, "name": "Regla 4: Puesta a Tierra y en Cortocircuito", "desc": "Instalar pértiga y grapas de puesta a tierra portátil en bornes del motor 10 HP."},
	{"step": 5, "name": "Regla 5: Señalización y Delimitación", "desc": "Delimitar perímetro de seguridad de 1.0 m alrededor del tablero y área intervenida."}
]

var completed_steps: Array[bool] = [false, false, false, false, false]
var current_step_index: int = 0 # 0..4 (Siguiente paso esperado = current_step_index + 1)
var loto_completed: bool = false

func reset_loto() -> void:
	completed_steps = [false, false, false, false, false]
	current_step_index = 0
	loto_completed = false
	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("loto_applied"):
		bus.loto_applied.emit(false)

func execute_rule(rule_num: int) -> Dictionary:
	if rule_num < 1 or rule_num > 5:
		return {"ok": false, "step": current_step_index, "message": "Regla inválida (debe ser 1 a 5)."}

	var expected_rule: int = current_step_index + 1
	if loto_completed:
		return {"ok": true, "step": 5, "message": "Las 5 Reglas de Oro LOTO ya están completadas y certificadas."}

	if rule_num != expected_rule:
		var expected_name: String = GOLDEN_RULES[current_step_index]["name"]
		var msg := "Secuencia RETIE incorrecta: Se intentó Regla %d, pero corresponde %s." % [rule_num, expected_name]
		var bus_err = get_node_or_null("/root/EventBus")
		if bus_err != null and bus_err.has_signal("notification_posted"):
			bus_err.notification_posted.emit("SECUENCIA LOTO INCORRECTA", msg, "warning")
		return {"ok": false, "step": current_step_index, "message": msg}

	completed_steps[current_step_index] = true
	var rule_info: Dictionary = GOLDEN_RULES[current_step_index]
	current_step_index += 1

	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		if bus.has_signal("golden_rule_step_completed"):
			bus.golden_rule_step_completed.emit(rule_num, rule_info["name"])
		if bus.has_signal("notification_posted"):
			bus.notification_posted.emit(rule_info["name"].to_upper() + " COMPLETADA", rule_info["desc"], "info")

	if current_step_index >= 5:
		loto_completed = true
		if bus != null:
			if bus.has_signal("loto_applied"):
				bus.loto_applied.emit(true)
			if bus.has_signal("golden_rules_completed"):
				bus.golden_rules_completed.emit()
			if bus.has_signal("safety_bonus_awarded"):
				bus.safety_bonus_awarded.emit(
					"LOTO_5_REGLAS",
					"Ejecución en orden estricto de las 5 Reglas de Oro RETIE.",
					1.0
				)

	return {
		"ok": true,
		"step": current_step_index,
		"completed": loto_completed,
		"message": "%s completada (%d/5)." % [rule_info["name"], current_step_index]
	}

func is_loto_complete() -> bool:
	return loto_completed

func get_current_step() -> int:
	return current_step_index

func get_rules_status() -> Array[Dictionary]:
	var status: Array[Dictionary] = []
	for i in range(GOLDEN_RULES.size()):
		var entry := GOLDEN_RULES[i].duplicate()
		entry["done"] = completed_steps[i]
		status.append(entry)
	return status
