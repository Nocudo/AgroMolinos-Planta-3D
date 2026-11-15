class_name WorkerNPC
extends CharacterBody3D

# ==============================================================================
# NPC DE TRABAJADOR INDUSTRIAL DE LA PLANTA (MOLINO DE GRANOS 10 HP)
# Animaciones autónomas, interacción RETIE/OSHA y estados de trabajo
# ==============================================================================

@export var worker_role_name: String = "Trabajador Industrial"
@export var worker_dialogue: String = "Operando en planta según normatividad RETIE y OSHA."
@export var primary_animation: String = "idle"
@export var secondary_animation: String = "inspect"
@export var animation_switch_time: float = 6.0

@onready var anim_player: AnimationPlayer = find_child("AnimationPlayer", true, false)
@onready var label_role: Label3D = $RoleLabel3D

var timer: float = 0.0
var current_anim: String = ""

func _ready() -> void:
	add_to_group("interactable")
	if label_role != null:
		label_role.text = worker_role_name
	
	if anim_player != null:
		current_anim = primary_animation
		if anim_player.has_animation(current_anim):
			anim_player.play(current_anim)
			anim_player.get_animation(current_anim).loop_mode = Animation.LOOP_LINEAR

func _process(delta: float) -> void:
	timer += delta
	if timer >= animation_switch_time:
		timer = 0.0
		_toggle_idle_animation()

func _toggle_idle_animation() -> void:
	if anim_player == null:
		return
	if current_anim == primary_animation:
		current_anim = secondary_animation
	else:
		current_anim = primary_animation
		
	if anim_player.has_animation(current_anim):
		anim_player.play(current_anim, 0.5)
		anim_player.get_animation(current_anim).loop_mode = Animation.LOOP_LINEAR

func interact(tool_id: int = 1) -> String:
	# Al interactuar, mira al jugador temporalmente y reproduce animación de interacción
	if anim_player != null and anim_player.has_animation("interact"):
		anim_player.play("interact", 0.2)
		anim_player.queue(primary_animation)
	
	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("notification_posted"):
		bus.notification_posted.emit(worker_role_name.to_upper(), worker_dialogue, "info")
	
	return worker_dialogue
