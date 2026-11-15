class_name FreeLookCamera
extends Camera3D

@export var default_speed: float = 25.0
@export var sprint_speed: float = 75.0
@export var mouse_sensitivity: float = 0.003
@export var acceleration: float = 10.0

var _velocity: Vector3 = Vector3.ZERO
var _initial_transform: Transform3D
var _mouse_captured: bool = false

func _ready() -> void:
	_initial_transform = transform
	current = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_set_mouse_captured(true)
			else:
				_set_mouse_captured(false)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			default_speed = clampf(default_speed + 2.0, 5.0, 150.0)
			sprint_speed = default_speed * 3.0
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			default_speed = clampf(default_speed - 2.0, 5.0, 150.0)
			sprint_speed = default_speed * 3.0

	elif event is InputEventMouseMotion and _mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotation.x = clampf(rotation.x - event.relative.y * mouse_sensitivity, -1.5, 1.5)

	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_set_mouse_captured(false)
		elif event.keycode == KEY_F:
			reset_view()

func _set_mouse_captured(captured: bool) -> void:
	_mouse_captured = captured
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE

func reset_view() -> void:
	transform = _initial_transform
	_velocity = Vector3.ZERO

func _process(delta: float) -> void:
	var move_vec := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("move_forward"):
		move_vec -= transform.basis.z
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("move_backward"):
		move_vec += transform.basis.z
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("move_left"):
		move_vec -= transform.basis.x
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("move_right"):
		move_vec += transform.basis.x
	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_E) or Input.is_action_pressed("move_up"):
		move_vec += Vector3.UP
	if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_Q) or Input.is_action_pressed("move_down"):
		move_vec += Vector3.DOWN

	var speed: float = sprint_speed if Input.is_key_pressed(KEY_SHIFT) else default_speed
	var target_vel: Vector3 = move_vec.normalized() * speed
	_velocity = _velocity.lerp(target_vel, acceleration * delta)
	position += _velocity * delta
