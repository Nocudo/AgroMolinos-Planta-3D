class_name SafetyEvaluationScorecard
extends Node

# ==============================================================================
# RÚBRICA ACADÉMICA AUTOMÁTICA DE SEGURIDAD INDUSTRIAL RETIE / OSHA (0.0 - 5.0)
# Bloque 8 - Proyecto Final Máquinas Eléctricas (AgroMolinos del Valle S.A.)
# ==============================================================================

const INITIAL_SCORE: float = 5.0
const MIN_SCORE: float = 0.0
const MAX_SCORE: float = 5.0

const PENALTY_CATALOG: Dictionary = {
	"INGRESO_SIN_EPP": {"points": 0.8, "desc": "Ingreso a nave industrial sin equipamiento completo de EPP RETIE."},
	"SIN_BOTAS": {"points": 1.0, "desc": "Tránsito por zona industrial sin botas dieléctricas."},
	"SIN_AUDITIVA": {"points": 0.6, "desc": "Ingreso a Zona 1 Molienda (>85 dBA) sin protección auditiva."},
	"INVASION_CCM_SIN_GUANTES": {"points": 1.5, "desc": "Aproximación a tablero CCM 460 V sin guantes dieléctricos Clase 00."},
	"ABRIR_MOLINO_GIRANDO": {"points": 2.5, "desc": "Intento de apertura o intervención mecánica con rotor en movimiento."},
	"CORTE_SIN_LOTO": {"points": 3.0, "desc": "Falta grave RETIE: intervención/corte de conductor energizado sin 5 Reglas de Oro LOTO."}
}

const BONUS_CATALOG: Dictionary = {
	"LOTO_5_REGLAS": {"points": 1.0, "desc": "Aplicación secuencial correcta de las 5 Reglas de Oro RETIE Art. 18."},
	"FALLA_RESUELTA": {"points": 1.0, "desc": "Diagnóstico y remediación física segura de anomalía en planta."},
	"INDUCCION_12_ESTACIONES": {"points": 0.5, "desc": "Certificación completa de recorrido de 12 estaciones de planta."}
}

var score: float = INITIAL_SCORE
var history: Array[Dictionary] = []
var violations_count: int = 0
var bonuses_count: int = 0
var current_zone_id: String = ""
var epp_equipped_items: Dictionary = {}
var epp_all_equipped: bool = false
var loto_completed: bool = false
var resolved_faults: Array[String] = []

func _ready() -> void:
	_connect_bus()
	call_deferred("_emit_score_update")

func _connect_bus() -> void:
	var bus = get_node_or_null("/root/EventBus")
	if bus == null:
		return
	if bus.has_signal("safety_violation_committed") and not bus.safety_violation_committed.is_connected(_on_safety_violation_committed):
		bus.safety_violation_committed.connect(_on_safety_violation_committed)
	if bus.has_signal("safety_bonus_awarded") and not bus.safety_bonus_awarded.is_connected(_on_safety_bonus_awarded):
		bus.safety_bonus_awarded.connect(_on_safety_bonus_awarded)
	if bus.has_signal("safety_zone_entered") and not bus.safety_zone_entered.is_connected(_on_safety_zone_entered):
		bus.safety_zone_entered.connect(_on_safety_zone_entered)
	if bus.has_signal("safety_zone_exited") and not bus.safety_zone_exited.is_connected(_on_safety_zone_exited):
		bus.safety_zone_exited.connect(_on_safety_zone_exited)
	if bus.has_signal("epp_state_changed") and not bus.epp_state_changed.is_connected(_on_epp_state_changed):
		bus.epp_state_changed.connect(_on_epp_state_changed)
	if bus.has_signal("fault_resolved") and not bus.fault_resolved.is_connected(_on_fault_resolved):
		bus.fault_resolved.connect(_on_fault_resolved)
	if bus.has_signal("golden_rules_completed") and not bus.golden_rules_completed.is_connected(_on_golden_rules_completed):
		bus.golden_rules_completed.connect(_on_golden_rules_completed)

func record_violation(code: String, custom_description: String = "", custom_penalty: float = -1.0) -> float:
	var penalty_val: float = custom_penalty
	var desc: String = custom_description
	if PENALTY_CATALOG.has(code):
		var item: Dictionary = PENALTY_CATALOG[code]
		if penalty_val < 0.0:
			penalty_val = float(item["points"])
		if desc.is_empty():
			desc = str(item["desc"])
	elif penalty_val < 0.0:
		penalty_val = 0.5
	if desc.is_empty():
		desc = "Infracción de seguridad industrial (%s)" % code

	score = clamp(score - absf(penalty_val), MIN_SCORE, MAX_SCORE)
	violations_count += 1
	history.append({
		"type": "VIOLATION",
		"code": code,
		"description": desc,
		"delta": -absf(penalty_val),
		"resulting_score": snappedf(score, 0.01),
		"timestamp_s": snappedf(Time.get_ticks_msec() / 1000.0, 0.1)
	})
	_emit_score_update()
	return score

func record_bonus(code: String, custom_description: String = "", custom_bonus: float = -1.0) -> float:
	var bonus_val: float = custom_bonus
	var desc: String = custom_description
	if BONUS_CATALOG.has(code):
		var item: Dictionary = BONUS_CATALOG[code]
		if bonus_val < 0.0:
			bonus_val = float(item["points"])
		if desc.is_empty():
			desc = str(item["desc"])
	elif bonus_val < 0.0:
		bonus_val = 0.5
	if desc.is_empty():
		desc = "Bonificación por procedimiento seguro (%s)" % code

	score = clamp(score + absf(bonus_val), MIN_SCORE, MAX_SCORE)
	bonuses_count += 1
	history.append({
		"type": "BONUS",
		"code": code,
		"description": desc,
		"delta": absf(bonus_val),
		"resulting_score": snappedf(score, 0.01),
		"timestamp_s": snappedf(Time.get_ticks_msec() / 1000.0, 0.1)
	})
	_emit_score_update()
	return score

func _on_safety_violation_committed(code: String, description: String, penalty: float) -> void:
	record_violation(code, description, penalty)

func _on_safety_bonus_awarded(code: String, description: String, bonus: float) -> void:
	record_bonus(code, description, bonus)

func _on_epp_state_changed(all_equipped: bool, items: Dictionary) -> void:
	epp_all_equipped = all_equipped
	epp_equipped_items = items.duplicate(true)

func _on_safety_zone_entered(zone_id: String, _zone_name: String) -> void:
	current_zone_id = zone_id
	if not epp_all_equipped and epp_equipped_items.size() > 0:
		var has_aud := bool(epp_equipped_items.get("proteccion_auditiva", epp_equipped_items.get("auditiva", false)))
		var has_gloves := bool(epp_equipped_items.get("guantes_dielectricos", epp_equipped_items.get("guantes", false)))
		var has_boots := bool(epp_equipped_items.get("botas_dielectricas", epp_equipped_items.get("botas", false)))
		if zone_id == "Zone1_Milling_OSHA" and not has_aud:
			record_violation("SIN_AUDITIVA")
		elif zone_id == "Zone2_CCM460V_RETIE" and not has_gloves:
			record_violation("INVASION_CCM_SIN_GUANTES")
		elif not has_boots:
			record_violation("SIN_BOTAS")

func _on_safety_zone_exited(_zone_id: String) -> void:
	current_zone_id = ""

func _on_fault_resolved(fault_code: String) -> void:
	if not resolved_faults.has(fault_code):
		resolved_faults.append(fault_code)
	record_bonus("FALLA_RESUELTA", "Falla resuelta físicamente en campo: %s" % fault_code)

func _on_golden_rules_completed() -> void:
	if not loto_completed:
		loto_completed = true
		# LotoGoldenRulesController suele emitir safety_bonus_awarded, evitar doble conteo si ya está en historial
		var already_logged := false
		for h in history:
			if str(h.get("code", "")) == "LOTO_5_REGLAS":
				already_logged = true
				break
		if not already_logged:
			record_bonus("LOTO_5_REGLAS")

func _emit_score_update() -> void:
	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("safety_score_updated"):
		bus.safety_score_updated.emit(snappedf(score, 0.01), history.duplicate(true))

func get_performance_grade_label() -> String:
	if score >= 4.5:
		return "EXCELENTE (Certificado RETIE)"
	if score >= 3.8:
		return "APROBADO (Operación Segura)"
	if score >= 3.0:
		return "APROBADO CON OBSERVACIONES"
	return "REPROBADO (Riesgo Crítico RETIE / OSHA)"

func get_scorecard_summary() -> Dictionary:
	return {
		"project": "Planta Molino de Granos - AgroMolinos del Valle S.A.",
		"normative": "RETIE / OSHA 1910 / ISO 10816-3 / IEEE 43",
		"final_score": snappedf(score, 0.01),
		"scale": "0.0 - 5.0",
		"classification": get_performance_grade_label(),
		"violations_count": violations_count,
		"bonuses_count": bonuses_count,
		"epp_all_equipped": epp_all_equipped,
		"loto_5_rules_completed": loto_completed,
		"resolved_faults": resolved_faults.duplicate(),
		"events_history": history.duplicate(true)
	}

func export_report_json(file_path: String = "user://Reporte_Estudiante_RETIE.json") -> String:
	var payload: Dictionary = get_scorecard_summary()
	var json_str: String = JSON.stringify(payload, "\t")
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file != null:
		file.store_string(json_str)
		file.close()
		return file_path
	return ""

func reset_scorecard() -> void:
	score = INITIAL_SCORE
	history.clear()
	violations_count = 0
	bonuses_count = 0
	resolved_faults.clear()
	loto_completed = false
	_emit_score_update()
