class_name PlayerOperator
extends CharacterBody3D

# ==============================================================================
# CONTROLADOR DEL OPERARIO TÉCNICO EN PLANTA (FPS)
# Control de cámara con mouse suave, interacción física diegética y hotbar minimalista
# ==============================================================================

@export var walk_speed: float = 4.2
@export var sprint_speed: float = 7.5
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

# Referencias a nodos
@onready var head: Node3D = $Head
@onready var camera_fps: Camera3D = $Head/CameraFPS
@onready var interaction_ray: RayCast3D = $Head/CameraFPS/InteractionRay
@onready var hand_mount: Node3D = $Head/CameraFPS/HandMount

# Herramientas del Cinturón Técnico (Minimalista)
var active_tool_id: int = 1
var tool_names: Dictionary = {
	1: "1 • Manos",
	2: "2 • Alicates",
	3: "3 • Llave 3/4\"",
	4: "4 • Multímetro",
	5: "5 • Kit LOTO"
}

var carried_bag: Node3D = null
var current_interactable = null
var last_prompt_text: String = ""

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_select_tool(1)

func _input(event: InputEvent) -> void:
	# 1. Alternar pantalla completa con F11
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		var mode = DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()
		return

	# 2. Capturar mouse al hacer clic en cualquier parte de la ventana
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			var tablet = get_tree().root.find_child("TabletRoot", true, false)
			if tablet == null or not tablet.visible:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				get_viewport().set_input_as_handled()
				return

	# 3. Liberar cursor con ESC (o re-capturar si ya estaba libre)
	if event.is_action_pressed("ui_cancel"):
		var tablet = get_tree().root.find_child("TabletRoot", true, false)
		if tablet != null and tablet.visible:
			tablet.toggle_tablet()
		else:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return

	# 4. Movimiento de vista con el Mouse (FPS Look)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, -deg_to_rad(85.0), deg_to_rad(85.0))

	# 5. Cambio de herramienta con teclas 1-5 o rueda del mouse
	if event.is_action_pressed("tool_1"): _select_tool(1)
	elif event.is_action_pressed("tool_2"): _select_tool(2)
	elif event.is_action_pressed("tool_3"): _select_tool(3)
	elif event.is_action_pressed("tool_4"): _select_tool(4)
	elif event.is_action_pressed("tool_5"): _select_tool(5)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var next_id = (active_tool_id % 5) + 1
			_select_tool(next_id)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var prev_id = active_tool_id - 1 if active_tool_id > 1 else 5
			_select_tool(prev_id)

	# 6. Interacción física (E o Clic Izquierdo si el mouse está capturado)
	if event.is_action_pressed("interact") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_handle_interaction()

func _select_tool(id: int) -> void:
	active_tool_id = id
	var t_name: String = tool_names.get(id, "Desconocida")
	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.tool_changed.emit(id, t_name)

func _handle_interaction() -> void:
	if carried_bag != null:
		# Soltar bulto al frente
		var throw_dir: Vector3 = -head.global_transform.basis.z * 5.0 + Vector3.UP * 2.0
		if carried_bag.has_method("drop_bag"):
			carried_bag.drop_bag(throw_dir)
		carried_bag = null
		_emit_prompt("")
		return

	if interaction_ray != null and interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		var target = _find_interactable(collider)
		if target != null:
			if target is InteractiveGrainBag and active_tool_id == 1:
				# Cargar bulto
				carried_bag = target
				target.pick_up(hand_mount)
				_emit_prompt("[E / Clic] Soltar bulto")
				return
			
			if target.has_method("interact"):
				var result_msg: String = target.interact(active_tool_id)
				var bus = get_node_or_null("/root/EventBus")
				if bus != null and result_msg != "":
					bus.notification_posted.emit("INTERACCIÓN", result_msg, "info")

func _physics_process(delta: float) -> void:
	# Gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Salto
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Movimiento horizontal WASD
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed: float = sprint_speed if Input.is_action_pressed("sprint") else walk_speed

	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
	_update_ray_prompt()

func _find_interactable(node: Node) -> Node:
	var curr = node
	while curr != null:
		if curr.has_method("interact") or curr.is_in_group("interactable"):
			return curr
		curr = curr.get_parent()
	return null

func _update_ray_prompt() -> void:
	if carried_bag != null:
		_emit_prompt("[E / Clic] Soltar bulto")
		return

	if interaction_ray != null and interaction_ray.is_colliding():
		var col = interaction_ray.get_collider()
		var target = _find_interactable(col)
		if target != null:
			current_interactable = target
			var prompt_msg = _get_minimal_prompt_for(target)
			_emit_prompt(prompt_msg)
			return

	current_interactable = null
	_emit_prompt("")

func _get_minimal_prompt_for(target: Node) -> String:
	if target is PhysicalCableConductor:
		if target.is_cut:
			return "[5] Reparar cable L3" if active_tool_id == 5 else "[E] Cable L3 cortado"
		else:
			return "[2] Cortar cable L3" if active_tool_id == 2 else "[E] Conductor L3"
	elif target is PhysicalBreakerPanel:
		return "[E] Palanca Breaker 460V"
	elif target is PhysicalHopperFeeder:
		return "[E] Compuerta tolva"
	elif target is MechanicalBolt:
		return "[3] Ajustar/Aflojar perno" if active_tool_id == 3 else "[E] Perno 3/4\""
	elif target is VentilationCover:
		return "[E] Obstruir/Despejar rejilla"
	elif target is InteractiveGrainBag:
		return "[E] Cargar bulto 50 kg"
	elif "epp_equipped" in target:
		return "[E] Guardar EPP" if target.epp_equipped else "[E] Equipar Dotación de EPP"
	return "[E] Interactuar"

func _emit_prompt(txt: String) -> void:
	if txt != last_prompt_text:
		last_prompt_text = txt
		var bus = get_node_or_null("/root/EventBus")
		if bus != null and bus.has_signal("prompt_updated"):
			bus.prompt_updated.emit(txt)
