extends Node

# ==============================================================================
# SIMULATION MANAGER - COORDINADOR GLOBAL DEL SERIOUS GAME (100% IN-GAME)
# ==============================================================================

const EdgeAIEngineScript = preload("res://scripts/ai/EdgeAIEngine.gd")

var induction_motor = null
var edge_ai = null
var _plant_started: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_edge_ai()
	_connect_events()

func _init_edge_ai() -> void:
	edge_ai = get_node_or_null("EdgeAIEngine")
	if edge_ai == null:
		edge_ai = EdgeAIEngineScript.new()
		edge_ai.name = "EdgeAIEngine"
		add_child(edge_ai)

func _connect_events() -> void:
	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		if bus.has_signal("tutorial_station_reached") and not bus.tutorial_station_reached.is_connected(_on_tutorial_station_reached):
			bus.tutorial_station_reached.connect(_on_tutorial_station_reached)
		if bus.has_signal("tutorial_completed") and not bus.tutorial_completed.is_connected(_on_tutorial_completed):
			bus.tutorial_completed.connect(_on_tutorial_completed)
		if bus.has_signal("golden_rules_completed") and not bus.golden_rules_completed.is_connected(_on_golden_rules_completed):
			bus.golden_rules_completed.connect(_on_golden_rules_completed)
		if bus.has_signal("safety_bonus_awarded") and not bus.safety_bonus_awarded.is_connected(_on_safety_bonus_awarded):
			bus.safety_bonus_awarded.connect(_on_safety_bonus_awarded)

func register_motor(motor) -> void:
	induction_motor = motor
	var tut = _get_tutorial_manager()
	# Si no hay gestor de tutorial o el recorrido ya está completado/saltado, arrancar de inmediato
	if tut == null or (tut.has_method("is_tour_completed") and tut.is_tour_completed()):
		start_plant_machines()
	else:
		stop_plant_machines()

func _get_tutorial_manager() -> Node:
	if not is_inside_tree():
		return null
	var r := get_tree().root
	return r.find_child("TutorialInductionManager", true, false)

func start_plant_machines() -> void:
	if induction_motor != null and is_instance_valid(induction_motor):
		if not induction_motor.is_running:
			induction_motor.start_motor()
			induction_motor.set_vfd_target_frequency(60.0)
			_plant_started = true
			var bus = get_node_or_null("/root/EventBus")
			if bus != null and bus.has_signal("notification_posted"):
				bus.notification_posted.emit(
					"Planta en operación",
					"Máquinas encendidas.",
					"success"
				)

func stop_plant_machines() -> void:
	if induction_motor != null and is_instance_valid(induction_motor):
		induction_motor.stop_motor()
		_plant_started = false

func _on_tutorial_station_reached(station_index: int, _station_title: String) -> void:
	var tut = _get_tutorial_manager()
	var total_sts: int = tut.STATIONS.size() if (tut != null and "STATIONS" in tut) else 19
	if station_index >= total_sts:
		start_plant_machines()

func _on_tutorial_completed() -> void:
	start_plant_machines()

func _on_golden_rules_completed() -> void:
	var tut = _get_tutorial_manager()
	if tut != null and tut.has_method("is_tour_completed") and tut.is_tour_completed():
		start_plant_machines()

func _on_safety_bonus_awarded(code: String, _desc: String, _bonus: float) -> void:
	if code == "INDUCCION_12_ESTACIONES":
		start_plant_machines()

func toggle_drive_mode() -> String:
	if induction_motor != null and induction_motor.vfd_controller != null:
		return induction_motor.vfd_controller.toggle_drive_mode()
	return "VFD"

func is_emergency_stop_engaged() -> bool:
	return induction_motor != null and is_instance_valid(induction_motor) and bool(induction_motor.is_e_stop_engaged)

func toggle_emergency_stop(source: String = "TABLET_SCADA") -> bool:
	if induction_motor == null or not is_instance_valid(induction_motor):
		return false
	return set_emergency_stop(not bool(induction_motor.is_e_stop_engaged), source)

func set_emergency_stop(engaged: bool, source: String = "TABLET_SCADA") -> bool:
	if induction_motor == null or not is_instance_valid(induction_motor):
		return false
	var bus = get_node_or_null("/root/EventBus")
	if engaged:
		if bus != null and bus.has_signal("emergency_stop_triggered"):
			bus.emergency_stop_triggered.emit(source)
		else:
			induction_motor.is_e_stop_engaged = true
		if bus != null and bus.has_signal("notification_posted"):
			bus.notification_posted.emit(
				"Parada de emergencia",
				"Máquinas detenidas.",
				"error"
			)
		return true
	if bus != null and bus.has_signal("emergency_stop_reset"):
		bus.emergency_stop_reset.emit()
	else:
		induction_motor.is_e_stop_engaged = false
	induction_motor.start_motor()
	if induction_motor.has_method("set_vfd_target_frequency"):
		induction_motor.set_vfd_target_frequency(60.0)
	if bus != null and bus.has_signal("notification_posted"):
		bus.notification_posted.emit(
			"Máquinas reanudadas",
			"Parada liberada.",
			"info"
		)
	return false
