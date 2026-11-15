class_name PhysicalCableConductor
extends Node3D

# ==============================================================================
# CONDUCTOR ELÉCTRICO CORTABLE FÍSICAMENTE EN 3D (CERO BOTONES 2D)
# Representa un conductor de fuerza 12 AWG con aislamiento de 600 V (RETIE)
# ==============================================================================

@export_enum("L1_Rojo", "L2_Negro", "L3_Azul", "Tierra_Verde") var phase_id: String = "L3_Azul"
@export var is_cut: bool = false

@onready var mesh_intact: Node3D = $MeshIntact
@onready var mesh_cut_a: Node3D = $MeshCutA
@onready var mesh_cut_b: Node3D = $MeshCutB
@onready var spark_particles: GPUParticles3D = $SparkParticles
@onready var arc_light: OmniLight3D = $ArcLight
@onready var audio_arc: AudioStreamPlayer3D = $AudioArc
@onready var interactable_area: Area3D = $InteractableArea

func _ready() -> void:
	_update_visuals()
	if interactable_area != null:
		interactable_area.add_to_group("interactable")

func interact(tool_id: int) -> String:
	# Tool 2 = Alicates dieléctricos 1000V
	# Tool 5 = Kit LOTO / Reparación de conductores
	if tool_id == 2:
		if not is_cut:
			cut_cable()
			return "Has cortado físicamente el conductor " + phase_id + " con los alicates."
		else:
			return "El conductor " + phase_id + " ya se encuentra cortado."
	elif tool_id == 5:
		if is_cut:
			repair_cable()
			return "Has empalmado y aislado el conductor " + phase_id + " bajo norma RETIE."
		else:
			return "El conductor " + phase_id + " está en perfecto estado."
	else:
		if is_cut:
			return "Conductor " + phase_id + " cortado. Usa el Kit de Reparación (tecla 5) para empalmar."
		else:
			return "Conductor " + phase_id + " activo (460 V). Usa los Alicates 1000V (tecla 2) para cortar."

func cut_cable() -> void:
	is_cut = true
	_update_visuals()
	
	# Efectos físicos de arco voltaico
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
		bus.notification_posted.emit(
			"CORTE FÍSICO DE CONDUCTOR ELÉCTRICO",
			"Se ha seccionado el conductor " + phase_id + ". Desbalance crítico y monofasización activa.",
			"error"
		)

func repair_cable() -> void:
	is_cut = false
	_update_visuals()
	
	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.conductor_repaired_event.emit(phase_id)
		bus.notification_posted.emit(
			"CONDUCTOR RESTAURADO CONFORME A RETIE",
			"Empalme y aislamiento certificado en " + phase_id + ". Fases balanceadas a 460 V.",
			"info"
		)

func _update_visuals() -> void:
	if mesh_intact != null:
		mesh_intact.visible = not is_cut
	if mesh_cut_a != null and mesh_cut_b != null:
		mesh_cut_a.visible = is_cut
		mesh_cut_b.visible = is_cut
