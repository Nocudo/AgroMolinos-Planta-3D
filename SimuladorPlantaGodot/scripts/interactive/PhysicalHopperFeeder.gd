class_name PhysicalHopperFeeder
extends Node3D

# ==============================================================================
# TOLVA RECEPTORA Y SOBREALIMENTACIÓN MECÁNICA DE CEREAL EN 3D
# Permite inducir atasco arrojando bultos de 50 kg o abriendo compuerta al 160%
# ==============================================================================

const SoundSynth = preload("res://scripts/core/IndustrialSoundSynthesizer.gd")

@export var max_nominal_feed_rate: float = 1.0     # kg/s nominal
@export var current_feed_rate: float = 0.8         # kg/s actual
@export var manual_gate_opening_pct: float = 80.0  # % apertura compuerta

@onready var reception_area: Area3D = $ReceptionArea
@onready var gate_wheel: Node3D = $GateWheelMesh
@onready var dust_particles: GPUParticles3D = $DustParticles
@onready var audio_feed: AudioStreamPlayer3D = $AudioFeed

var bags_thrown_count: int = 0
var is_jammed: bool = false

func _ready() -> void:
	if reception_area != null:
		if not reception_area.body_entered.is_connected(_on_grain_body_entered):
			reception_area.body_entered.connect(_on_grain_body_entered)
		reception_area.add_to_group("interactable")
	if audio_feed != null:
		if audio_feed.stream == null:
			audio_feed.stream = SoundSynth.create_hopper_grain_loop()
		audio_feed.volume_db = -3.0
		audio_feed.unit_size = 10.0
		audio_feed.max_distance = 45.0
		audio_feed.play()

func interact(tool_id: int) -> String:
	if tool_id != 3:
		return "Usa la llave 3/4\" para operar la tolva."
	if is_jammed or manual_gate_opening_pct > 120.0:
		clear_jam()
		return "Tolva desatascada. Flujo normalizado a 0.8 kg/s."
	else:
		set_gate_opening(160.0)
		return "Compuerta forzada al 160%. Sobrealimentación activa."

func throw_bag_into_hopper() -> void:
	bags_thrown_count += 1
	if bags_thrown_count >= 2:
		set_gate_opening(160.0)
	else:
		set_gate_opening(110.0)

func clear_jam() -> void:
	bags_thrown_count = 0
	is_jammed = false
	set_gate_opening(80.0)
	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("fault_resolved"):
		bus.fault_resolved.emit("SOBRECARGA_TOLVA")

func set_gate_opening(pct: float) -> void:
	manual_gate_opening_pct = pct
	if gate_wheel != null and is_inside_tree():
		var target_rot: float = deg_to_rad(manual_gate_opening_pct * 1.8)
		var t = create_tween()
		t.tween_property(gate_wheel, "rotation:z", target_rot, 0.3)

	current_feed_rate = (manual_gate_opening_pct / 100.0) * max_nominal_feed_rate
	if manual_gate_opening_pct > 120.0:
		current_feed_rate = 4.5 # Salto masivo > Tmax de Kloss
		is_jammed = true
		if dust_particles != null:
			dust_particles.emitting = true
	else:
		is_jammed = false
		if dust_particles != null:
			dust_particles.emitting = false

	if audio_feed != null:
		audio_feed.pitch_scale = 0.72 if is_jammed else 1.0
		audio_feed.volume_db = 1.0 if is_jammed else -3.0
		if not audio_feed.playing:
			audio_feed.play()

	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.hopper_overfed.emit(current_feed_rate)
		if is_jammed:
			bus.notification_posted.emit(
				"Atasco en tolva",
				"Sobrealimentación sobre 4.0 kg/s. Riesgo de polvo ATEX.",
				"error"
			)
		else:
			bus.notification_posted.emit(
				"Flujo normalizado en tolva",
				"Compuerta en %.0f%% · %.2f kg/s." % [manual_gate_opening_pct, current_feed_rate],
				"info"
			)

func _on_grain_body_entered(body: Node3D) -> void:
	if body is RigidBody3D and (body.is_in_group("grain_bag") or body.name.begins_with("GrainBag")):
		body.queue_free()
		throw_bag_into_hopper()

func _exit_tree() -> void:
	if audio_feed != null:
		audio_feed.stop()
		audio_feed.stream = null
