class_name InteractiveGrainBag
extends RigidBody3D

# ==============================================================================
# BULTO DE CEREAL DE 50 KG - OBJETO RÍGIDO INTERACTIVO
# ==============================================================================

@export var mass_kg: float = 50.0
var is_held: bool = false
var holder_node: Node3D = null

func _ready() -> void:
	add_to_group("grain_bag")
	add_to_group("interactable")
	mass = mass_kg

func interact(_tool_id: int) -> String:
	if not is_held:
		return "Bulto de cereal de 50 kg. Puedes cargarlo y arrojarlo dentro de la tolva del molino."
	return ""

func pick_up(carrier: Node3D) -> void:
	is_held = true
	holder_node = carrier
	freeze = true
	reparent(carrier)
	position = Vector3(0.0, -0.2, -1.2)
	rotation = Vector3.ZERO

func drop_bag(throw_impulse: Vector3 = Vector3.ZERO) -> void:
	if not is_held: return
	is_held = false
	var root_scene = get_tree().current_scene
	var global_pos = global_position
	reparent(root_scene)
	global_position = global_pos
	freeze = false
	if throw_impulse != Vector3.ZERO:
		apply_central_impulse(throw_impulse)
