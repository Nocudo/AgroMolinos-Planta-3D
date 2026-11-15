extends Node

# ==============================================================================
# SIMULATION MANAGER - COORDINADOR GLOBAL DEL SERIOUS GAME
# ==============================================================================

var induction_motor: InductionMotorKloss = null
var cloud_bridge: CloudIoTBridge = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_cloud_bridge()

func _init_cloud_bridge() -> void:
	cloud_bridge = CloudIoTBridge.new()
	add_child(cloud_bridge)

func register_motor(motor: InductionMotorKloss) -> void:
	induction_motor = motor
	# Iniciar motor a 60 Hz nominales
	induction_motor.start_motor()
	induction_motor.set_vfd_target_frequency(60.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("e_stop"):
		if induction_motor != null:
			if not induction_motor.is_e_stop_engaged:
				EventBus.emergency_stop_triggered.emit("KEYBOARD_E_STOP")
				EventBus.notification_posted.emit(
					"PARADA DE EMERGENCIA ACCIONADA (E-STOP)",
					"Desconexión inmediata de fuerza por el operario. Parada Cat 0.",
					"error"
				)
			else:
				EventBus.emergency_stop_reset.emit()
				induction_motor.start_motor()
				EventBus.notification_posted.emit(
					"PARADA DE EMERGENCIA REARMADA",
					"Circuito de seguridad habilitado. Motor reiniciando marcha suave.",
					"info"
				)
