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
		return "Rejilla de ventilación Motor 10 HP. Equipa [2] Alicates (tecla 2) para obstruir o despejar."
	set_blocked(not is_blocked)
	if is_blocked:
		return "Has obstruido la rejilla de ventilación con [2] Alicates. ¡Enfriamiento bloqueado!"
	else:
		return "Has retirado la obstrucción de la rejilla con [2] Alicates. Flujo de aire normalizado."

func set_blocked(blocked: bool) -> void:
	is_blocked = blocked
	if rag_mesh != null:
		rag_mesh.visible = is_blocked

	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.ventilation_blocked.emit(is_blocked)
		if is_blocked:
			bus.notification_posted.emit(
				"VENTILACIÓN TRASERA OBSTRUIDA",
				"Saco arrojado sobre la tapa del ventilador. Rth sube de 0.068 a 0.210 °C/W. Alza térmica acelerada.",
				"error"
			)
		else:
			if bus.has_signal("fault_resolved"):
				bus.fault_resolved.emit("VENTILACION_OBSTRUIDA")
			bus.notification_posted.emit(
				"OBSTRUCCIÓN DE VENTILACIÓN RETIRADA",
				"Flujo de aire forzado restaurado. Enfriamiento progresivo.",
				"info"
			)
