class_name VentilationCover
extends Node3D

# ==============================================================================
# REJILLA DE VENTILACIÓN FORZADA DEL MOTOR 10 HP
# Permite arrojar o retirar un trapo/saco para inducir sobrecalentamiento térmico
# ==============================================================================

@export var is_blocked: bool = false
@onready var rag_mesh: Node3D = $RagMesh
@onready var interactable_area: Area3D = $InteractableArea

func _ready() -> void:
	if rag_mesh != null:
		rag_mesh.visible = is_blocked
	if interactable_area != null:
		interactable_area.add_to_group("interactable")

func interact(tool_id: int) -> String:
	# Tool 2 = Alicates / pinzas aisladas para intervenir rejilla cerca de partes móviles
	if tool_id != 2:
		return "Usa los alicates para obstruir o despejar la rejilla."
	set_blocked(not is_blocked)
	if is_blocked:
		return "Rejilla de ventilación obstruida."
	else:
		return "Rejilla de ventilación despejada."

func set_blocked(blocked: bool) -> void:
	is_blocked = blocked
	if rag_mesh != null:
		rag_mesh.visible = is_blocked

	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.ventilation_blocked.emit(is_blocked)
		if is_blocked:
			bus.notification_posted.emit(
				"Ventilación obstruida",
				"Enfriamiento del motor bloqueado. Alza térmica en curso.",
				"error"
			)
		else:
			if bus.has_signal("fault_resolved"):
				bus.fault_resolved.emit("VENTILACION_OBSTRUIDA")
			bus.notification_posted.emit(
				"Ventilación despejada",
				"Flujo de aire restaurado.",
				"info"
			)
