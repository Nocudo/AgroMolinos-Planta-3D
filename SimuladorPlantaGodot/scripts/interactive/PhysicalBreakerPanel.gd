class_name PhysicalBreakerPanel
extends Node3D

# ==============================================================================
# GABINETE CCM 460 V: PALANCAS DE BREAKERS, VOLTAGE SAGS & LOTO 5 REGLAS DE ORO
# ==============================================================================

const SoundSynth = preload("res://scripts/core/IndustrialSoundSynthesizer.gd")
const CABINET_MODEL_CANDIDATES: Array[String] = [
	"res://assets/models/panel_control.glb",
	"res://assets/models/tablero_electrico.glb",
	"res://assets/models/tablero_ccm.glb",
	"res://assets/models/ccm_panel.glb"
]

enum BreakerState { NORMAL_460V, BROWNOUT_340V, ISOLATED_0V }

@onready var door_pivot: Node3D = $DoorPivot
@onready var lever_l1: Node3D = $BreakerL1/LeverPivot
@onready var lever_l2: Node3D = $BreakerL2/LeverPivot
@onready var lever_l3: Node3D = $BreakerL3/LeverPivot
@onready var audio_click: AudioStreamPlayer3D = $AudioClick
@onready var interactable_area: Area3D = $InteractableArea

var is_door_open: bool = false
var l1_active: bool = true
var l2_active: bool = true
var l3_active: bool = true
var breaker_state: int = BreakerState.NORMAL_460V

func _ready() -> void:
	if interactable_area != null:
		interactable_area.add_to_group("interactable")
	if audio_click != null and audio_click.stream == null:
		audio_click.stream = SoundSynth.create_breaker_clunk_sound()
		audio_click.unit_size = 8.0
		audio_click.volume_db = 2.0
	_try_mount_downloaded_cabinet_model()

func _try_mount_downloaded_cabinet_model() -> void:
	for res_path in CABINET_MODEL_CANDIDATES:
		if ResourceLoader.exists(res_path):
			var packed := ResourceLoader.load(res_path) as PackedScene
			if packed != null:
				var inst := packed.instantiate() as Node3D
				if inst == null:
					continue
				inst.name = "DownloadedCabinetModel"
				if res_path.ends_with("panel_control.glb"):
					# Eliminar tubos/cables salientes en piso (defaultMaterial3) y centrar gabinete limpio en recuadro CCM
					var tubes := inst.find_child("defaultMaterial3", true, false)
					if tubes != null and is_instance_valid(tubes):
						if tubes.get_parent() != null:
							tubes.get_parent().remove_child(tubes)
						tubes.free()
					var s := 1.48 / 976.23
					inst.scale = Vector3.ONE * s
					inst.rotation_degrees = Vector3(0.0, -90.0, 0.0)
					inst.position = Vector3(0.0, 202.57 * s - 0.0235, 0.0)
				add_child(inst)
				var glow := get_tree().root.find_child("InteractableGlowController", true, false) if is_inside_tree() else null
				if glow != null and glow.has_method("register_breaker_meshes"):
					glow.call_deferred("register_breaker_meshes")
				return

func interact(tool_id: int) -> String:
	if not is_door_open:
		toggle_door()
		return "Has abierto la puerta del gabinete CCM 460 V. Breakers y barrajes accesibles."

	# Herramienta 4 = Multímetro Digital CAT III -> Regla 3 (Verificación de ausencia de tensión)
	if tool_id == 4:
		return _measure_with_multimeter()

	# Herramienta 5 = Kit LOTO -> Ejecución guiada de las 5 Reglas de Oro en el CCM
	if tool_id == 5:
		return _advance_loto_procedure()

	# Herramientas 2 (Alicates) o 3 (Llave 3/4") -> Manipulación física de palanca Breaker L3 (Brownout 340 V / Normal 460 V)
	if tool_id in [2, 3]:
		toggle_breaker_l3()
		if not l3_active:
			return "Breaker L3 abierto. Bajón de tensión a 340 V."
		else:
			return "Breaker L3 rearmado. Tensión nominal 460 V."
	return "Tablero energizado. Usa Alicates, Llave 3/4\", Multímetro o Kit LOTO."

func toggle_door() -> void:
	is_door_open = not is_door_open
	if audio_click != null:
		audio_click.play()
	if door_pivot != null and is_inside_tree():
		var target_angle: float = deg_to_rad(105.0) if is_door_open else 0.0
		var t = create_tween()
		t.tween_property(door_pivot, "rotation:y", target_angle, 0.4).set_trans(Tween.TRANS_QUAD)

func toggle_breaker_l3() -> void:
	l3_active = not l3_active
	breaker_state = BreakerState.NORMAL_460V if l3_active else BreakerState.BROWNOUT_340V
	if audio_click != null:
		audio_click.play()
	_animate_lever(lever_l3, l3_active)

	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.breaker_changed.emit("Breaker_L3", l3_active)
		if not l3_active:
			bus.notification_posted.emit(
				"Bajón de tensión en CCM",
				"Breaker L3 abierto. Tensión cae a 340 V.",
				"error"
			)
		else:
			if bus.has_signal("fault_resolved"):
				bus.fault_resolved.emit("BAJON_TENSION_CCM")
			bus.notification_posted.emit(
				"Breaker CCM rearmado",
				"Tensión restablecida a 460 V.",
				"info"
			)

func set_main_disconnect_isolated(isolated: bool) -> void:
	l1_active = not isolated
	l2_active = not isolated
	l3_active = not isolated
	breaker_state = BreakerState.ISOLATED_0V if isolated else BreakerState.NORMAL_460V
	if audio_click != null:
		audio_click.play()
	_animate_lever(lever_l1, l1_active)
	_animate_lever(lever_l2, l2_active)
	_animate_lever(lever_l3, l3_active)
	var sm = get_node_or_null("/root/SimulationManager")
	if sm != null and sm.induction_motor != null:
		sm.induction_motor.set_loto_isolated(isolated)

func _measure_with_multimeter() -> String:
	var measured_v: float = 0.0
	if breaker_state == BreakerState.NORMAL_460V:
		measured_v = 460.0
	elif breaker_state == BreakerState.BROWNOUT_340V:
		measured_v = 340.0
	else:
		measured_v = 0.0

	var tutorial = get_tree().root.find_child("TutorialInductionManager", true, false) if is_inside_tree() else null
	if breaker_state == BreakerState.ISOLATED_0V and tutorial != null and tutorial.has_method("execute_loto_rule"):
		var res: Dictionary = tutorial.execute_loto_rule(3)
		return "Multímetro CAT III: Lectura 0.0 V AC en L1-L2-L3. " + str(res.get("message", ""))

	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("notification_posted"):
		bus.notification_posted.emit("MEDICIÓN MULTÍMETRO CAT III", "Tensión medida en bornes CCM: %.1f V AC." % measured_v, "info")
	return "Multímetro CAT III: Tensión medida en barraje = %.1f V AC." % measured_v

func _advance_loto_procedure() -> String:
	var tutorial = get_tree().root.find_child("TutorialInductionManager", true, false) if is_inside_tree() else null
	if tutorial == null or tutorial.loto_controller == null:
		return "Abre y bloquea el seccionador principal."

	var step: int = tutorial.loto_controller.get_current_step()
	var next_rule: int = step + 1
	if next_rule == 1:
		set_main_disconnect_isolated(true)
		var res1: Dictionary = tutorial.execute_loto_rule(1)
		return str(res1.get("message", "Regla 1 ejecutada."))
	elif next_rule == 2:
		var res2: Dictionary = tutorial.execute_loto_rule(2)
		return str(res2.get("message", "Regla 2 ejecutada."))
	elif next_rule == 3:
		return "Usa el multímetro para verificar 0 V en el CCM."
	elif next_rule == 4 or next_rule == 5:
		var resn: Dictionary = tutorial.execute_loto_rule(next_rule)
		return str(resn.get("message", "Regla ejecutada."))
	else:
		# Si ya completó LOTO 5/5 y vuelve a usar Kit LOTO, desenergiza/rearma a estado operativo normal
		set_main_disconnect_isolated(false)
		tutorial.loto_controller.reset_loto()
		return "Candado LOTO retirado y seccionador principal rearmado a 460 V."

func _animate_lever(lever: Node3D, active: bool) -> void:
	if lever != null and is_inside_tree():
		var target_rot: float = 0.0 if active else deg_to_rad(-45.0)
		var t = create_tween()
		t.tween_property(lever, "rotation:x", target_rot, 0.15)
