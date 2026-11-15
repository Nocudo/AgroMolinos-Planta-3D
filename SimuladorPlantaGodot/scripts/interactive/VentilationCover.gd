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

func interact(_tool_id: int) -> String:
	is_blocked = not is_blocked
	if rag_mesh != null:
		rag_mesh.visible = is_blocked

	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.ventilation_blocked.emit(is_blocked)
		if is_blocked:
			bus.notification_posted.emit(
				"VENTILACIÓN TRASERA OBSTRUIDA",
				"Saco arrojado sobre la tapa del ventilador. Convección reducida 85%. Alza térmica acelerada.",
				"error"
			)
		else:
			bus.notification_posted.emit(
				"OBSTRUCCIÓN DE VENTILACIÓN RETIRADA",
				"Flujo de aire forzado restaurado. Enfriamiento progresivo.",
				"info"
			)

	if is_blocked:
		return "Has colocado un saco sobre la rejilla de ventilación. ¡Enfriamiento bloqueado!"
	else:
		return "Has retirado la obstrucción de la rejilla. Flujo de aire normalizado."
