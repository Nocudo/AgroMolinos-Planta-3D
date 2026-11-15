class_name MainPlantScene
extends Node3D

# ==============================================================================
# ESCENA MAESTRA DE LA PLANTA AGROMOLINOS DEL VALLE S.A.
# ==============================================================================

@onready var motor_mill: Node3D = $MotorMillUnit
@onready var plant_lights: Node3D = $PlantLights

func _ready() -> void:
	# Activar modo pantalla completa
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	if motor_mill != null:
		var motor = motor_mill.get_node_or_null("InductionMotor")
		if motor != null:
			var sm = get_node_or_null("/root/SimulationManager")
			if sm != null and sm.has_method("register_motor"):
				sm.register_motor(motor)
	
	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.breaker_changed.connect(_on_breaker_changed)

func _on_breaker_changed(_breaker_id: String, active: bool) -> void:
	if plant_lights == null: return
	
	# Flicker / bajón de intensidad en luminarias
	var target_energy: float = 1.0 if active else 0.55
	for light in plant_lights.get_children():
		if light is Light3D:
			var t = create_tween()
			t.tween_property(light, "light_energy", 0.2, 0.08)
			t.tween_property(light, "light_energy", target_energy, 0.15)
