class_name InteractiveDoor
extends Node3D

const IndustrialSoundSynthesizerScript = preload("res://scripts/core/IndustrialSoundSynthesizer.gd")

enum DoorMode {
	HINGED_SINGLE,
	HINGED_DOUBLE,
	ROLL_UP_Y,
	SLIDE_Z,
}

@export var door_label: String = "Puerta"
@export var door_mode: DoorMode = DoorMode.HINGED_SINGLE
@export var is_open: bool = false
@export var is_motorized: bool = false
@export var anim_duration: float = 0.42

var primary_pivot: Node3D = null
var primary_closed_angle: float = 0.0
var primary_open_angle: float = 0.0

var secondary_pivot: Node3D = null
var secondary_closed_angle: float = 0.0
var secondary_open_angle: float = 0.0

var curtain_pivot: Node3D = null
var curtain_closed_scale_y: float = 1.0
var curtain_open_scale_y: float = 0.07

var slide_pivot: Node3D = null
var slide_closed_pos: Vector3 = Vector3.ZERO
var slide_open_pos: Vector3 = Vector3.ZERO

var _blocker_shapes: Array[CollisionShape3D] = []
var _curtain_interact_shapes: Array[CollisionShape3D] = []
var _clearance_zone: Area3D = null
var _audio_player: AudioStreamPlayer3D = null
var _tween: Tween = null
var _pending_lock: bool = false

func _ready() -> void:
	if not is_in_group("interactive_doors"):
		add_to_group("interactive_doors")
	if not is_in_group("interactable"):
		add_to_group("interactable")
	_setup_audio()
	_apply_instant_state(is_open)

func configure_hinged_single(
	p_label: String,
	p_pivot: Node3D,
	p_closed_angle: float,
	p_open_angle: float,
	p_doorway_center: Vector3,
	p_doorway_size: Vector3
) -> void:
	door_label = p_label
	door_mode = DoorMode.HINGED_SINGLE
	is_motorized = false
	anim_duration = 0.42
	primary_pivot = p_pivot
	primary_closed_angle = p_closed_angle
	primary_open_angle = p_open_angle
	_add_blocker_on_pivot(primary_pivot, p_doorway_center, p_doorway_size)
	_add_interact_area_on_pivot(primary_pivot, p_doorway_center, p_doorway_size + Vector3(0.25, 0.2, 0.25))
	_create_clearance_zone(p_doorway_center, p_doorway_size)
	_finalize_configuration()

func configure_hinged_double(
	p_label: String,
	p_pivot_a: Node3D,
	p_closed_a: float,
	p_open_a: float,
	p_center_a: Vector3,
	p_size_a: Vector3,
	p_pivot_b: Node3D,
	p_closed_b: float,
	p_open_b: float,
	p_center_b: Vector3,
	p_size_b: Vector3,
	p_full_center: Vector3,
	p_full_size: Vector3
) -> void:
	door_label = p_label
	door_mode = DoorMode.HINGED_DOUBLE
	is_motorized = false
	anim_duration = 0.50
	primary_pivot = p_pivot_a
	primary_closed_angle = p_closed_a
	primary_open_angle = p_open_a
	secondary_pivot = p_pivot_b
	secondary_closed_angle = p_closed_b
	secondary_open_angle = p_open_b
	_add_blocker_on_pivot(primary_pivot, p_center_a, p_size_a)
	_add_interact_area_on_pivot(primary_pivot, p_center_a, p_size_a + Vector3(0.25, 0.2, 0.25))
	_add_blocker_on_pivot(secondary_pivot, p_center_b, p_size_b)
	_add_interact_area_on_pivot(secondary_pivot, p_center_b, p_size_b + Vector3(0.25, 0.2, 0.25))
	_create_clearance_zone(p_full_center, p_full_size)
	_finalize_configuration()

func configure_roll_up(
	p_label: String,
	p_curtain_pivot: Node3D,
	p_curtain_center: Vector3,
	p_curtain_size: Vector3,
	p_switch_world_pos: Vector3
) -> void:
	door_label = p_label
	door_mode = DoorMode.ROLL_UP_Y
	is_motorized = true
	anim_duration = 0.90
	curtain_pivot = p_curtain_pivot
	_add_blocker_on_pivot(self, p_curtain_center, p_curtain_size)
	_add_interact_area_on_pivot(self, p_curtain_center, p_curtain_size + Vector3(0.35, 0.2, 0.35), true)
	# Stationary control box / jamb trigger so user can always close it when curtain is rolled up
	_add_interact_area_on_pivot(self, p_switch_world_pos, Vector3(0.70, 1.80, 0.70))
	_create_clearance_zone(p_curtain_center, p_curtain_size)
	_finalize_configuration()

func configure_sliding_z(
	p_label: String,
	p_slide_pivot: Node3D,
	p_slide_offset: Vector3,
	p_gate_center: Vector3,
	p_gate_size: Vector3,
	p_motor_world_pos: Vector3
) -> void:
	door_label = p_label
	door_mode = DoorMode.SLIDE_Z
	is_motorized = true
	anim_duration = 0.95
	slide_pivot = p_slide_pivot
	slide_closed_pos = p_slide_pivot.position
	slide_open_pos = slide_closed_pos + p_slide_offset
	_add_blocker_on_pivot(slide_pivot, p_gate_center, p_gate_size)
	_add_interact_area_on_pivot(slide_pivot, p_gate_center, p_gate_size + Vector3(0.45, 0.3, 0.3))
	# Stationary motor post trigger so user can toggle gate even when slid clear
	_add_interact_area_on_pivot(self, p_motor_world_pos, Vector3(1.10, 2.00, 1.10))
	_create_clearance_zone(p_gate_center, p_gate_size)
	_finalize_configuration()

func _finalize_configuration() -> void:
	_setup_audio()
	_apply_instant_state(is_open)

func interact(_tool_id: int = 1) -> String:
	var target_open := not is_open
	set_door_open(target_open, true)
	var verb := "Abriendo" if target_open else "Cerrando"
	_emit_notification(door_label, "%s %s." % [verb, door_label.to_lower()], "INFO")
	return "%s: %s" % [door_label, verb]

func open_door(play_sfx: bool = true) -> void:
	if is_open:
		return
	set_door_open(true, play_sfx)

func close_door(play_sfx: bool = true) -> void:
	if not is_open:
		return
	set_door_open(false, play_sfx)

func get_interact_prompt() -> String:
	return "[E] Cerrar %s" % door_label if is_open else "[E] Abrir %s" % door_label

func set_door_open(open_state: bool, play_sfx: bool = true) -> void:
	is_open = open_state
	_pending_lock = false
	if is_open:
		# Disable collision immediately so the operator can step through smoothly.
		_set_blockers_enabled(false)

	if _tween != null and _tween.is_valid():
		_tween.kill()

	if not is_inside_tree():
		_apply_instant_state(is_open)
		return

	if play_sfx and _audio_player != null and _audio_player.stream != null:
		_audio_player.pitch_scale = randf_range(0.94, 1.07)
		_audio_player.play()

	_tween = create_tween()
	_tween.set_parallel(true)
	if is_motorized:
		_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	else:
		_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT if is_open else Tween.EASE_IN_OUT)

	match door_mode:
		DoorMode.HINGED_SINGLE:
			if primary_pivot != null:
				var ang := primary_open_angle if is_open else primary_closed_angle
				_tween.tween_property(primary_pivot, "rotation:y", ang, anim_duration)
		DoorMode.HINGED_DOUBLE:
			if primary_pivot != null:
				var ang_a := primary_open_angle if is_open else primary_closed_angle
				_tween.tween_property(primary_pivot, "rotation:y", ang_a, anim_duration)
			if secondary_pivot != null:
				var ang_b := secondary_open_angle if is_open else secondary_closed_angle
				_tween.tween_property(secondary_pivot, "rotation:y", ang_b, anim_duration)
		DoorMode.ROLL_UP_Y:
			if curtain_pivot != null:
				var sy := curtain_open_scale_y if is_open else curtain_closed_scale_y
				_tween.tween_property(curtain_pivot, "scale:y", sy, anim_duration)
		DoorMode.SLIDE_Z:
			if slide_pivot != null:
				var pos := slide_open_pos if is_open else slide_closed_pos
				_tween.tween_property(slide_pivot, "position", pos, anim_duration)

	_tween.chain().tween_callback(_on_motion_finished)

func _on_motion_finished() -> void:
	if is_open:
		_set_blockers_enabled(false)
		return
	if _has_occupant_in_doorway():
		_pending_lock = true
	else:
		_set_blockers_enabled(true)

func _apply_instant_state(open_state: bool) -> void:
	match door_mode:
		DoorMode.HINGED_SINGLE:
			if primary_pivot != null:
				primary_pivot.rotation.y = primary_open_angle if open_state else primary_closed_angle
		DoorMode.HINGED_DOUBLE:
			if primary_pivot != null:
				primary_pivot.rotation.y = primary_open_angle if open_state else primary_closed_angle
			if secondary_pivot != null:
				secondary_pivot.rotation.y = secondary_open_angle if open_state else secondary_closed_angle
		DoorMode.ROLL_UP_Y:
			if curtain_pivot != null:
				curtain_pivot.scale.y = curtain_open_scale_y if open_state else curtain_closed_scale_y
		DoorMode.SLIDE_Z:
			if slide_pivot != null:
				slide_pivot.position = slide_open_pos if open_state else slide_closed_pos
	_set_blockers_enabled(not open_state)

func _set_blockers_enabled(enabled: bool) -> void:
	for cs in _blocker_shapes:
		if is_instance_valid(cs):
			cs.disabled = not enabled
	for cs in _curtain_interact_shapes:
		if is_instance_valid(cs):
			cs.disabled = not enabled

func is_door_blocking() -> bool:
	for cs in _blocker_shapes:
		if is_instance_valid(cs) and not cs.disabled:
			return true
	return false

func _has_occupant_in_doorway() -> bool:
	if _clearance_zone == null or not is_instance_valid(_clearance_zone) or not is_inside_tree():
		return false
	for b in _clearance_zone.get_overlapping_bodies():
		if b is CharacterBody3D:
			return true
	return false

func _on_clearance_body_exited(_body: Node3D) -> void:
	if _pending_lock and not is_open and not _has_occupant_in_doorway():
		_pending_lock = false
		call_deferred("_set_blockers_enabled", true)

func _add_blocker_on_pivot(parent_node: Node3D, world_center: Vector3, world_size: Vector3) -> void:
	if parent_node == null:
		return
	var sb := StaticBody3D.new()
	sb.name = "DoorLeafBlocker"
	sb.collision_layer = 1
	sb.collision_mask = 0
	parent_node.add_child(sb)
	sb.global_position = world_center
	sb.global_basis = Basis.IDENTITY

	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(
		maxf(world_size.x, 0.14),
		maxf(world_size.y, 1.80),
		maxf(world_size.z, 0.14)
	)
	cs.shape = box
	sb.add_child(cs)
	_blocker_shapes.append(cs)

func _add_interact_area_on_pivot(parent_node: Node3D, world_center: Vector3, world_size: Vector3, is_curtain: bool = false) -> void:
	if parent_node == null:
		return
	var area := Area3D.new()
	area.name = "DoorInteractArea"
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	parent_node.add_child(area)
	area.global_position = world_center
	area.global_basis = Basis.IDENTITY

	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(
		maxf(world_size.x, 0.40),
		maxf(world_size.y, 1.85),
		maxf(world_size.z, 0.40)
	)
	cs.shape = box
	area.add_child(cs)
	if is_curtain:
		_curtain_interact_shapes.append(cs)

func _create_clearance_zone(world_center: Vector3, world_size: Vector3) -> void:
	_clearance_zone = Area3D.new()
	_clearance_zone.name = "DoorClearanceZone"
	_clearance_zone.collision_layer = 0
	_clearance_zone.collision_mask = 1
	_clearance_zone.monitoring = true
	_clearance_zone.monitorable = false
	add_child(_clearance_zone)
	_clearance_zone.global_position = world_center

	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(
		maxf(world_size.x, 0.55),
		maxf(world_size.y, 1.90),
		maxf(world_size.z, 0.55)
	)
	cs.shape = box
	_clearance_zone.add_child(cs)
	_clearance_zone.body_exited.connect(_on_clearance_body_exited)

func _setup_audio() -> void:
	if _audio_player == null:
		_audio_player = AudioStreamPlayer3D.new()
		_audio_player.name = "DoorAudio"
		_audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_audio_player)
	_audio_player.unit_size = 6.0
	_audio_player.max_distance = 24.0 if is_motorized else 16.0
	_audio_player.volume_db = 2.0 if is_motorized else 1.5
	_audio_player.stream = (
		IndustrialSoundSynthesizerScript.create_gate_motor_sound()
		if is_motorized
		else IndustrialSoundSynthesizerScript.create_door_latch_sound()
	)

func _emit_notification(title: String, msg: String, severity: String) -> void:
	if not is_inside_tree():
		return
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("notification_posted"):
		bus.notification_posted.emit(title, msg, severity)
