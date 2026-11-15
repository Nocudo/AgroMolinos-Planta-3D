class_name PhysicalHopperFeeder
extends Node3D

# ==============================================================================
# TOLVA RECEPTORA Y SOBREALIMENTACIÓN MECÁNICA DE CEREAL EN 3D
# ==============================================================================

@export var max_nominal_feed_rate: float = 1.0     # kg/s nominal
@export var current_feed_rate: float = 0.8         # kg/s actual
@export var manual_gate_opening_pct: float = 80.0  # % apertura compuerta

@onready var reception_area: Area3D = $ReceptionArea
@onready var gate_wheel: Node3D = $GateWheelMesh
@onready var dust_particles: GPUParticles3D = $DustParticles
@onready var audio_feed: AudioStreamPlayer3D = $AudioFeed

func _ready() -> void:
	if reception_area != null:
		reception_area.body_entered.connect(_on_grain_body_entered)
		reception_area.add_to_group("interactable")

func interact(_tool_id: int) -> String:
	# Al interactuar directamente, se gira la compuerta manual alternando entre 80% y 150% (sobrealimentación masiva)
	if manual_gate_opening_pct <= 80.0:
		set_gate_opening(160.0)
		return "Has abierto la compuerta manual al 160%. ¡Sobrealimentación masiva de cereal!"
	else:
		set_gate_opening(80.0)
		return "Has ajustado la compuerta manual al 80% (caudal nominal de molienda)."

func set_gate_opening(pct: float) -> void:
	manual_gate_opening_pct = pct
	if gate_wheel != null:
		var target_rot: float = deg_to_rad(manual_gate_opening_pct * 1.8)
		var t = create_tween()
		t.tween_property(gate_wheel, "rotation:z", target_rot, 0.3)

	current_feed_rate = (manual_gate_opening_pct / 100.0) * max_nominal_feed_rate
	if manual_gate_opening_pct > 120.0:
		current_feed_rate = 4.2 # Salto masivo de par resistente
		if dust_particles != null:
			dust_particles.emitting = true
	else:
		if dust_particles != null:
			dust_particles.emitting = false

	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.hopper_overfed.emit(current_feed_rate)
		if manual_gate_opening_pct > 120.0:
			bus.notification_posted.emit(
				"SOBREALIMENTACIÓN MASIVA DE GRANO",
				"Flujo másico supera 4.0 kg/s. Par resistente excede el par crítico de Kloss.",
				"error"
			)
		else:
			bus.notification_posted.emit(
				"FLUJO NORMALIZADO EN TOLVA",
				"Compuerta en 80%. Caudal de cereal dosificado a 0.8 kg/s.",
				"info"
			)

func _on_grain_body_entered(body: Node3D) -> void:
	if body is RigidBody3D and (body.is_in_group("grain_bag") or body.name.begins_with("GrainBag")):
		body.queue_free() # Grano consumido por la boca trituradora
		set_gate_opening(160.0)
