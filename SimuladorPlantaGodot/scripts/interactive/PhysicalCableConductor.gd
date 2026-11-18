class_name PhysicalCableConductor
extends Node3D

# ==============================================================================
# CONDUCTOR ELÉCTRICO CORTABLE FÍSICAMENTE EN 3D (CERO BOTONES 2D)
# Representa un conductor de fuerza 12 AWG con aislamiento de 600 V (RETIE)
# ==============================================================================

const SoundSynth = preload("res://scripts/core/IndustrialSoundSynthesizer.gd")

@export_enum("L1_Rojo", "L2_Negro", "L3_Azul", "Tierra_Verde") var phase_id: String = "L3_Azul"
@export var is_cut: bool = false

@onready var mesh_intact: Node3D = $MeshIntact
@onready var mesh_cut_a: Node3D = $MeshCutA
@onready var mesh_cut_b: Node3D = $MeshCutB
@onready var spark_particles: GPUParticles3D = $SparkParticles
@onready var arc_light: OmniLight3D = $ArcLight
@onready var audio_arc: AudioStreamPlayer3D = $AudioArc
@onready var interactable_area: Area3D = $InteractableArea

var loto_is_active: bool = false

func _ready() -> void:
	_update_visuals()
	if interactable_area != null:
		interactable_area.add_to_group("interactable")
	if audio_arc != null and audio_arc.stream == null:
		audio_arc.stream = SoundSynth.create_electric_arc_sound()
		audio_arc.unit_size = 10.0
		audio_arc.volume_db = 2.5
	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("loto_applied"):
		if not bus.loto_applied.is_connected(_on_loto_applied):
			bus.loto_applied.connect(_on_loto_applied)

func _on_loto_applied(applied: bool) -> void:
	loto_is_active = applied

func interact(tool_id: int) -> String:
	# Tool 2 = Alicates dieléctricos 1000V
	# Tool 5 = Kit LOTO / Reparación de conductores
	if tool_id == 2:
		if not is_cut:
			cut_cable()
			return "Conductor " + phase_id + " cortado."
		else:
			return "El conductor " + phase_id + " ya está cortado."
	elif tool_id == 5:
		if is_cut:
			repair_cable()
			return "Conductor " + phase_id + " empalmado y aislado."
		else:
			return "El conductor " + phase_id + " está en buen estado."
	else:
		if is_cut:
			return "Conductor " + phase_id + " cortado. Usa el Kit LOTO para empalmar."
		else:
			return "Conductor " + phase_id + " activo. Usa los alicates para cortar."

func cut_cable() -> void:
	is_cut = true
	_update_visuals()

	# Efectos físicos de arco voltaico solo si hay tensión (sin LOTO)
	if not loto_is_active:
		if spark_particles != null:
			spark_particles.emitting = true
		if arc_light != null:
			arc_light.visible = true
			var t = create_tween()
			t.tween_property(arc_light, "light_energy", 0.0, 0.4)
		if audio_arc != null:
			audio_arc.play()

	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.conductor_cut_event.emit(phase_id)
		if not loto_is_active and bus.has_signal("safety_violation_committed"):
			bus.safety_violation_committed.emit(
				"CORTE_SIN_LOTO",
				"Corte en conductor " + phase_id + " energizado sin LOTO.",
				3.0
			)
		bus.notification_posted.emit(
			"Conductor cortado",
			"Fase " + phase_id + " abierta. Desbalance crítico activo.",
			"error"
		)

func repair_cable() -> void:
	is_cut = false
	_update_visuals()

	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.conductor_repaired_event.emit(phase_id)
		if bus.has_signal("fault_resolved"):
			bus.fault_resolved.emit("FALLA_ELECTRICA_CABLE")
		bus.notification_posted.emit(
			"Conductor restaurado",
			"Empalme completado en " + phase_id + ". Fases balanceadas.",
			"info"
		)

func _update_visuals() -> void:
	if mesh_intact != null:
		mesh_intact.visible = not is_cut
	if mesh_cut_a != null and mesh_cut_b != null:
		mesh_cut_a.visible = is_cut
		mesh_cut_b.visible = is_cut
