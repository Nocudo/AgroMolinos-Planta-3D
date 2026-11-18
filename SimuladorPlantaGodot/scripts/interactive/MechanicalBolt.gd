class_name MechanicalBolt
extends Node3D

# ==============================================================================
# PERNO DE ANCLAJE MECÁNICO EN BANCADA DEL MOTOR
# Usar llave fija 3/4" (Herramienta 3) para aflojar o apretar
# ==============================================================================

@export var bolt_id: String = "Bolt_Front_Right"
@export var is_loosened: bool = false

@onready var bolt_head: Node3D = $BoltMesh
@onready var interactable_area: Area3D = $InteractableArea

func _ready() -> void:
	if interactable_area != null:
		interactable_area.add_to_group("interactable")

func interact(tool_id: int) -> String:
	# Tool 3 = Llave fija 3/4"
	if tool_id == 3:
		set_loosened(not is_loosened)
		return "Perno " + ("aflojado." if is_loosened else "apretado.")
	else:
		return "Usa la llave 3/4\" para intervenir el perno."

func set_loosened(loosened: bool) -> void:
	is_loosened = loosened
	if bolt_head != null and is_inside_tree():
		var target_y: float = 0.04 if is_loosened else 0.0
		var t = create_tween()
		t.tween_property(bolt_head, "position:y", target_y, 0.2)
		t.parallel().tween_property(bolt_head, "rotation:y", deg_to_rad(180.0 if is_loosened else 0.0), 0.2)

	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.bolt_loosened.emit(bolt_id, is_loosened)
		if is_loosened:
			bus.notification_posted.emit(
				"Perno de bancada aflojado",
				"Desajuste mecánico. Vibración en Zona D.",
				"error"
			)
		else:
			if bus.has_signal("fault_resolved"):
				bus.fault_resolved.emit("PERNOS_FLOJOS")
			bus.notification_posted.emit(
				"Perno de bancada apretado",
				"Torque ajustado. Vibración normalizada.",
				"info"
			)
