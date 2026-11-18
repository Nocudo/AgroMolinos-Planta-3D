class_name PlayerOperator
extends CharacterBody3D

# ==============================================================================
# CONTROLADOR DEL OPERARIO TÉCNICO EN PLANTA (PRIMERA PERSONA SIN CABEZA)
# Control suave con cámara FPS, marcha biomecánica natural, vestimenta EPP e
# interacción física diegética.
# ==============================================================================

const HumanGaitAnimatorScript = preload("res://scripts/interactive/HumanGaitAnimator.gd")
const SoundSynth = preload("res://scripts/core/IndustrialSoundSynthesizer.gd")
const MAX_SELECTION_DISTANCE_M: float = 30.0

@export var walk_speed: float = 2.6
@export var sprint_speed: float = 4.6
@export var jump_velocity: float = 4.8
@export var mouse_sensitivity: float = 0.003
@export var max_step_height: float = 0.82
@export var min_step_height: float = 0.02

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

# Referencias a nodos (100% Primera Persona)
@onready var head: Node3D = $Head
@onready var camera_fps: Camera3D = $Head/CameraFPS
@onready var interaction_ray: RayCast3D = $Head/CameraFPS/InteractionRay
@onready var hand_mount: Node3D = $Head/CameraFPS/HandMount
@onready var character_visual: Node3D = $CharacterVisual

# Animaciones y marcha
var anim_player: AnimationPlayer = null
var is_action_playing: bool = false
var action_timer: float = 0.0
var current_anim_name: String = ""
var _walk_bob_phase: float = 0.0
var _last_step_half_cycle: int = 0
var footstep_player: AudioStreamPlayer3D = null
var _is_head_removed: bool = false
var _step_camera_offset_y: float = 0.0
var _was_on_floor_recently: float = 0.0
var _wearing_epp: bool = false
var _base_body_materials: Dictionary = {}

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
var _hover_poll_timer: float = 0.0

# Detección y rescate anti-atasco por múltiples inputs sin desplazamiento
const STUCK_DISPLACEMENT_MAX_M: float = 0.24
const STUCK_INPUT_TIME_THRESHOLD_S: float = 1.85
const STUCK_INPUT_PRESSES_THRESHOLD: int = 6
const STUCK_PRESS_MIN_ELAPSED_S: float = 0.55

var _stuck_anchor_pos: Vector3 = Vector3.ZERO
var _last_safe_pos: Vector3 = Vector3.ZERO
var _stuck_input_timer: float = 0.0
var _stuck_window_timer: float = 0.0
var _stuck_idle_timer: float = 0.0
var _stuck_input_presses: int = 0
var _prev_input_dir: Vector2 = Vector2.ZERO
var _unstuck_cooldown: float = 0.0
var unstuck_teleport_count: int = 0

func _ready() -> void:
	floor_snap_length = 0.50
	safe_margin = 0.02
	floor_stop_on_slope = true
	floor_max_angle = deg_to_rad(50.0)
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_select_tool(1)

	if camera_fps != null:
		camera_fps.current = true
		camera_fps.near = 0.08
	if head != null and head.get_node_or_null("AudioListener3D") == null:
		var listener := AudioListener3D.new()
		listener.name = "AudioListener3D"
		head.add_child(listener)
		listener.make_current()

	if character_visual != null:
		character_visual.position = Vector3(0.0, 0.0, 0.16)
		anim_player = character_visual.find_child("AnimationPlayer", true, false)
		if anim_player != null:
			HumanGaitAnimatorScript.upgrade_animations(anim_player, character_visual)
			_play_anim("idle")
			anim_player.advance(0.02)
		_remove_player_head_mesh()

	footstep_player = AudioStreamPlayer3D.new()
	footstep_player.name = "FootstepAudio"
	footstep_player.stream = SoundSynth.create_footstep_sound()
	footstep_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
	footstep_player.volume_db = -1.0
	footstep_player.unit_size = 8.0
	footstep_player.max_distance = 20.0
	add_child(footstep_player)

	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("epp_state_changed"):
		if not bus.epp_state_changed.is_connected(_on_epp_state_changed):
			bus.epp_state_changed.connect(_on_epp_state_changed)

	_stuck_anchor_pos = global_position
	_last_safe_pos = global_position

func _remove_player_head_mesh() -> void:
	if character_visual == null:
		return

	var skel := character_visual.find_child("Skeleton3D", true, false) as Skeleton3D
	if skel != null:
		for hbone in ["CC_Base_Head_015", "CC_Base_NeckTwist01_014"]:
			var bi := skel.find_bone(hbone)
			if bi >= 0:
				skel.set_bone_pose_scale(bi, Vector3(0.001, 0.001, 0.001))

	var mesh_instances := character_visual.find_children("*", "MeshInstance3D", true, false)
	for child in mesh_instances:
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var orig_mesh := mi.mesh
		var skin_ref := mi.skin
		var new_mesh := ArrayMesh.new()
		for bsi in range(orig_mesh.get_blend_shape_count()):
			new_mesh.add_blend_shape(orig_mesh.get_blend_shape_name(bsi))
		if orig_mesh.get_blend_shape_count() > 0:
			new_mesh.blend_shape_mode = orig_mesh.blend_shape_mode

		var flag_mask: int = ~((1 << Mesh.ARRAY_MAX) - 1)
		for surf_idx in range(orig_mesh.get_surface_count()):
			var arrays := orig_mesh.surface_get_arrays(surf_idx)
			var bs_arrays := orig_mesh.surface_get_blend_shape_arrays(surf_idx)
			var fmt_flags: int = orig_mesh.surface_get_format(surf_idx) & flag_mask
			var mat := orig_mesh.surface_get_material(surf_idx)
			if mat != null and not _base_body_materials.has(surf_idx):
				_base_body_materials[surf_idx] = mat

			var removed_any := false
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices_var = arrays[Mesh.ARRAY_INDEX]
			if verts.size() > 0 and indices_var != null:
				var orig_idx: PackedInt32Array = indices_var
				var filtered_idx := PackedInt32Array()
				var i: int = 0
				while i + 2 < orig_idx.size():
					var i0: int = orig_idx[i]
					var i1: int = orig_idx[i + 1]
					var i2: int = orig_idx[i + 2]
					var v0: Vector3 = verts[i0]
					var v1: Vector3 = verts[i1]
					var v2: Vector3 = verts[i2]
					var is_head0: bool = v0.z > 155.0 and absf(v0.x) < 24.0
					var is_head1: bool = v1.z > 155.0 and absf(v1.x) < 24.0
					var is_head2: bool = v2.z > 155.0 and absf(v2.x) < 24.0
					if is_head0 or is_head1 or is_head2:
						removed_any = true
					else:
						filtered_idx.append(i0)
						filtered_idx.append(i1)
						filtered_idx.append(i2)
					i += 3
				if removed_any and filtered_idx.size() >= 3:
					arrays[Mesh.ARRAY_INDEX] = filtered_idx
			new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, bs_arrays, {}, fmt_flags)
			if mat != null:
				new_mesh.surface_set_material(new_mesh.get_surface_count() - 1, mat)

		mi.mesh = new_mesh
		if skin_ref != null:
			mi.skin = skin_ref
		_is_head_removed = true

func _on_epp_state_changed(all_equipped: bool, _items: Dictionary) -> void:
	_wearing_epp = all_equipped
	if character_visual == null:
		return
	var tex_epp := load("res://assets/models/trabajador_logistica_trabajador_logistica_0.jpg") as Texture2D if ResourceLoader.exists("res://assets/models/trabajador_logistica_trabajador_logistica_0.jpg") else null
	var tex_civil := load("res://assets/models/trabajador_operario_trabajador_operario_0.jpg") as Texture2D if ResourceLoader.exists("res://assets/models/trabajador_operario_trabajador_operario_0.jpg") else null
	var mesh_instances := character_visual.find_children("*", "MeshInstance3D", true, false)
	for child in mesh_instances:
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for s in range(mi.mesh.get_surface_count()):
			var base_mat: Material = _base_body_materials.get(s, mi.mesh.surface_get_material(s)) as Material
			if base_mat is StandardMaterial3D:
				var std := base_mat.duplicate() as StandardMaterial3D
				if all_equipped:
					# Indumentaria ignífuga / dieléctrica naranja de alta visibilidad RETIE
					if tex_epp != null:
						std.albedo_texture = tex_epp
						std.albedo_color = Color(1.04, 1.02, 0.98, 1.0)
					else:
						std.albedo_color = Color(1.0, 0.68, 0.25, 1.0)
					std.roughness = 0.55
				else:
					if tex_civil != null:
						std.albedo_texture = tex_civil
					std.albedo_color = (base_mat as StandardMaterial3D).albedo_color
				mi.set_surface_override_material(s, std)

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
			var pause_menu = get_tree().root.find_child("PauseMenuController", true, false)
			var pause_open: bool = pause_menu != null and pause_menu.has_method("is_pause_open") and bool(pause_menu.is_pause_open())
			if (tablet == null or not tablet.visible) and not pause_open:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				get_viewport().set_input_as_handled()
				return

	# 3. Menú de pausa o interacción de escape con ESC
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		var tablet = get_tree().root.find_child("TabletRoot", true, false)
		if tablet != null and tablet.visible:
			tablet.toggle_tablet()
			get_viewport().set_input_as_handled()
			return
		var hud = get_tree().root.find_child("HUDController", true, false)
		if hud != null and hud.has_method("is_briefing_visible") and hud.is_briefing_visible():
			hud.close_briefing_panel()
			get_viewport().set_input_as_handled()
			return
		var c_modal = get_tree().root.find_child("RetieCourseModal", true, false)
		if c_modal != null and c_modal.visible:
			c_modal.close_modal(false)
			get_viewport().set_input_as_handled()
			return
		var pause_menu = get_tree().root.find_child("PauseMenuController", true, false)
		if pause_menu != null and pause_menu.has_method("toggle_pause"):
			pause_menu.toggle_pause()
			get_viewport().set_input_as_handled()
			return
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return

	# 4. Movimiento de vista con el Mouse (100% FPS Look)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, -deg_to_rad(85.0), deg_to_rad(85.0))

	# 5. Cambio de herramienta con teclas 1-5 o rueda del mouse (bloqueado cuando se navega la tablet/menús)
	var ui_blocks_tools := _is_ui_blocking_tool_input()
	if not ui_blocks_tools:
		if event.is_action_pressed("tool_1"): _select_tool(1)
		elif event.is_action_pressed("tool_2"): _select_tool(2)
		elif event.is_action_pressed("tool_3"): _select_tool(3)
		elif event.is_action_pressed("tool_4"): _select_tool(4)
		elif event.is_action_pressed("tool_5"): _select_tool(5)
		elif event is InputEventMouseButton and event.pressed:
			# Rueda hacia abajo aumenta slot (1->2->3->4->5), hacia arriba disminuye (5->4->3->2->1)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				var next_id: int = (active_tool_id % 5) + 1
				_select_tool(next_id)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				var prev_id: int = active_tool_id - 1 if active_tool_id > 1 else 5
				_select_tool(prev_id)

	# 6. Interacción física (E siempre en juego activo; Clic Izquierdo cuando el mouse está capturado)
	if event.is_action_pressed("interact") and (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or not (event is InputEventMouseButton)):
		var tablet_chk = get_tree().root.find_child("TabletRoot", true, false)
		if (tablet_chk == null or not tablet_chk.visible) and not get_tree().paused:
			_handle_interaction()

func _select_tool(id: int) -> void:
	active_tool_id = id
	var t_name: String = tool_names.get(id, "Desconocida")
	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("tool_changed"):
		bus.tool_changed.emit(id, t_name)

func _get_glow_controller() -> Node:
	if not is_inside_tree() or get_tree() == null:
		return null
	return get_tree().root.find_child("InteractableGlowController", true, false)

func _is_tablet_open() -> bool:
	if not is_inside_tree() or get_tree() == null:
		return false
	var tablet := get_tree().root.find_child("TabletRoot", true, false)
	return tablet != null and bool(tablet.visible)

func _is_ui_blocking_tool_input() -> bool:
	if not is_inside_tree() or get_tree() == null:
		return false
	if get_tree().paused or _is_tablet_open():
		return true
	var root := get_tree().root
	var pause_menu := root.find_child("PauseMenuController", true, false)
	if pause_menu != null and pause_menu.has_method("is_pause_open") and bool(pause_menu.is_pause_open()):
		return true
	var c_modal := root.find_child("RetieCourseModal", true, false)
	if c_modal != null and bool(c_modal.visible):
		return true
	var hud := root.find_child("HUDController", true, false)
	if hud != null and hud.has_method("is_briefing_visible") and bool(hud.is_briefing_visible()):
		return true
	return false

func _get_aim_screen_position() -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return Vector2.ZERO
	if DisplayServer.get_name() != "headless" and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		return vp.get_mouse_position()
	return vp.get_visible_rect().size * 0.5

func _update_machine_hover_selection() -> void:
	var glow := _get_glow_controller()
	if glow == null or camera_fps == null:
		return
	if get_tree().paused or _is_tablet_open() or carried_bag != null:
		glow.set_hovered_machine_group("")
		return
	if glow.has_method("update_hover_from_camera"):
		glow.update_hover_from_camera(camera_fps, _get_aim_screen_position(), MAX_SELECTION_DISTANCE_M, get_rid())

func _is_tour_showcase_machine_locked(target: Node) -> bool:
	if target == null:
		return false
	var is_machine_part := (
		target is PhysicalBreakerPanel
		or target is PhysicalCableConductor
		or target is MechanicalBolt
		or target is VentilationCover
		or target is PhysicalHopperFeeder
	)
	if not is_machine_part:
		return false
	var tut := get_tree().root.find_child("TutorialInductionManager", true, false) if is_inside_tree() else null
	if tut != null and tut.has_method("is_tutorial_glow_unlocked"):
		return not bool(tut.is_tutorial_glow_unlocked())
	return false

func _should_use_close_priority(target: Node) -> bool:
	if target == null or _is_tour_showcase_machine_locked(target):
		return false
	if target is WorkerNPC or target is InteractiveDoor or target is InteractiveGrainBag or "epp_equipped" in target:
		return true
	if target is PhysicalBreakerPanel and active_tool_id in [2, 3, 4, 5]:
		return true
	if target is PhysicalCableConductor and active_tool_id in [2, 5]:
		return true
	if target is MechanicalBolt and active_tool_id == 3:
		return true
	if target is VentilationCover and active_tool_id == 2:
		return true
	if target is PhysicalHopperFeeder and active_tool_id == 3:
		return true
	return false

func _handle_interaction() -> void:
	if carried_bag != null:
		_trigger_action_anim("interact", 1.4)
		var throw_dir: Vector3 = -head.global_transform.basis.z * 5.0 + Vector3.UP * 2.0
		if carried_bag.has_method("drop_bag"):
			carried_bag.drop_bag(throw_dir)
		carried_bag = null
		_emit_prompt("")
		return

	var close_target: Node = null
	if interaction_ray != null and interaction_ray.is_colliding():
		close_target = _find_interactable(interaction_ray.get_collider())
		if _is_tour_showcase_machine_locked(close_target):
			close_target = null

	if close_target != null and _should_use_close_priority(close_target):
		if close_target.has_method("can_interact") and not close_target.can_interact():
			return
		_trigger_action_anim("interact", 1.1)
		if close_target is InteractiveGrainBag and active_tool_id == 1:
			carried_bag = close_target
			close_target.pick_up(hand_mount)
			_emit_prompt("Soltar bulto")
			return
		if close_target.has_method("interact"):
			var result_msg: String = close_target.interact(active_tool_id)
			var bus = get_node_or_null("/root/EventBus")
			if bus != null and result_msg != "" and bus.has_signal("notification_posted"):
				bus.notification_posted.emit("Acción", result_msg, "info")
		return

	var glow := _get_glow_controller()
	if glow != null and glow.has_method("has_active_green_selection") and glow.has_active_green_selection():
		_trigger_action_anim("interact", 1.1)
		var fault_msg: String = str(glow.induce_fault_for_hovered_machine(active_tool_id))
		var bus_f = get_node_or_null("/root/EventBus")
		if bus_f != null and fault_msg != "" and bus_f.has_signal("notification_posted"):
			bus_f.notification_posted.emit("Equipo", fault_msg, "info")
		_update_ray_prompt()
		return

	if close_target != null:
		if close_target.has_method("can_interact") and not close_target.can_interact():
			return
		_trigger_action_anim("interact", 1.1)
		if close_target.has_method("interact"):
			var result_msg2: String = close_target.interact(active_tool_id)
			var bus2 = get_node_or_null("/root/EventBus")
			if bus2 != null and result_msg2 != "" and bus2.has_signal("notification_posted"):
				bus2.notification_posted.emit("Acción", result_msg2, "info")
		return

	# Si el jugador está dentro de la estación activa (3..12) y presiona [E] sin apuntar a otro equipo, avanzar de estación
	var tut := get_tree().root.find_child("TutorialInductionManager", true, false) if is_inside_tree() else null
	if tut != null and tut.has_method("try_advance_station_by_interact"):
		var adv_msg: String = String(tut.try_advance_station_by_interact())
		if adv_msg != "":
			_trigger_action_anim("interact", 1.1)
			var bus3 = get_node_or_null("/root/EventBus")
			if bus3 != null and bus3.has_signal("notification_posted"):
				bus3.notification_posted.emit("RECORRIDO GUIADO", adv_msg, "info")

func _physics_process(delta: float) -> void:
	if is_on_floor():
		_was_on_floor_recently = 0.15
	else:
		_was_on_floor_recently = maxf(0.0, _was_on_floor_recently - delta)
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var is_sprinting: bool = Input.is_action_pressed("sprint")
	var current_speed: float = sprint_speed if is_sprinting else walk_speed

	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * current_speed, 24.0 * delta)
		velocity.z = move_toward(velocity.z, direction.z * current_speed, 24.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 26.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 26.0 * delta)

	_try_auto_step(delta)
	move_and_slide()
	var new_inputs := _count_movement_inputs(input_dir)
	update_stuck_detector(delta, input_dir, new_inputs)
	_update_fps_head_bob(delta)
	_hover_poll_timer += delta
	if _hover_poll_timer >= 0.033:
		_hover_poll_timer = 0.0
		_update_machine_hover_selection()
		_update_ray_prompt()
	_update_animations(delta, input_dir, is_sprinting)

func _count_movement_inputs(input_dir: Vector2) -> int:
	var count := 0
	for act in ["move_forward", "move_backward", "move_left", "move_right", "jump"]:
		if Input.is_action_just_pressed(act):
			count += 1
	if input_dir.length() > 0.25:
		if _prev_input_dir.length() <= 0.20 or absf(input_dir.angle_to(_prev_input_dir)) > 0.42:
			count += 1
	_prev_input_dir = input_dir
	return count

func update_stuck_detector(delta: float, input_dir: Vector2, new_input_count: int = 0) -> bool:
	if _unstuck_cooldown > 0.0:
		_unstuck_cooldown = maxf(0.0, _unstuck_cooldown - delta)
		_stuck_anchor_pos = global_position
		return false

	var flat_disp := Vector2(global_position.x - _stuck_anchor_pos.x, global_position.z - _stuck_anchor_pos.z).length()
	var vert_disp := absf(global_position.y - _stuck_anchor_pos.y)

	# Si el operario realmente avanzó en horizontal o subió de nivel aterrizando firme, reiniciamos ventana
	if flat_disp >= 0.45 or (is_on_floor() and vert_disp >= 0.85):
		if is_on_floor() and _is_capsule_free_at(global_position + Vector3(0.0, 0.04, 0.0)):
			_last_safe_pos = global_position
		_reset_stuck_counters()
		return false

	var has_active_input := input_dir.length() > 0.20 or new_input_count > 0
	if has_active_input:
		_stuck_idle_timer = 0.0
		_stuck_window_timer += delta
		if input_dir.length() > 0.20:
			_stuck_input_timer += delta
		_stuck_input_presses += maxi(new_input_count, 0)
	else:
		_stuck_idle_timer += delta
		if _stuck_idle_timer >= 0.85:
			_reset_stuck_counters()
		return false

	if flat_disp < STUCK_DISPLACEMENT_MAX_M:
		var spam_stuck := _stuck_input_presses >= STUCK_INPUT_PRESSES_THRESHOLD and _stuck_window_timer >= STUCK_PRESS_MIN_ELAPSED_S
		var hold_stuck := _stuck_input_timer >= STUCK_INPUT_TIME_THRESHOLD_S
		if spam_stuck or hold_stuck:
			return teleport_to_nearby_safe_spot()
	return false

func _reset_stuck_counters() -> void:
	_stuck_anchor_pos = global_position
	_stuck_input_timer = 0.0
	_stuck_window_timer = 0.0
	_stuck_idle_timer = 0.0
	_stuck_input_presses = 0

func teleport_to_nearby_safe_spot() -> bool:
	var safe_pos := find_nearby_safe_position()
	if not safe_pos.is_finite():
		_reset_stuck_counters()
		return false

	var moved_dist := global_position.distance_to(safe_pos)
	global_position = safe_pos
	velocity = Vector3.ZERO
	_unstuck_cooldown = 1.5
	unstuck_teleport_count += 1
	_last_safe_pos = safe_pos
	_reset_stuck_counters()

	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("notification_posted"):
		bus.notification_posted.emit(
			"ANTI-ATASCO",
			"Personaje reubicado a zona segura cercana (%.1f m)." % moved_dist,
			"info"
		)
	return true

func find_nearby_safe_position(max_radius: float = 3.2) -> Vector3:
	if not is_inside_tree() or get_world_3d() == null:
		return Vector3.INF

	var radii: Array[float] = [0.55, 0.95, 1.40, 2.00, 2.60, max_radius]
	var forward_xz := -transform.basis.z
	var base_yaw := atan2(forward_xz.z, forward_xz.x)

	# Pasada 1: busca punto libre cercano con línea de visión despejada (nunca cruza muros ni puertas cerradas)
	for r in radii:
		for step_i in range(12):
			# Empieza por los costados/atrás para retroceder de esquinas obstruidas antes de probar al frente
			var ang := base_yaw + PI + (float(step_i) / 12.0) * TAU
			var probe := global_position + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
			var valid := _validate_safe_landing(probe, true)
			if valid.is_finite():
				return valid

	# Pasada 2: si quedó atrapado dentro de una malla/colisionador, intenta volver al último punto seguro válido
	if _last_safe_pos != Vector3.ZERO and global_position.distance_to(_last_safe_pos) <= 6.5:
		var valid_prev := _validate_safe_landing(_last_safe_pos, false)
		if valid_prev.is_finite():
			return valid_prev

	# Pasada 3: búsqueda radial más amplia ignorando rayos de salida desde el interior del colisionador
	for r in [0.65, 1.15, 1.75, 2.45, 3.20, 4.00]:
		for step_i in range(16):
			var ang := base_yaw + PI + (float(step_i) / 16.0) * TAU
			var probe := global_position + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
			var valid := _validate_safe_landing(probe, false)
			if valid.is_finite():
				return valid

	return Vector3.INF

func _validate_safe_landing(candidate: Vector3, require_los: bool) -> Vector3:
	var space := get_world_3d().direct_space_state
	var exclude: Array[RID] = [get_rid()]
	var floor_q := PhysicsRayQueryParameters3D.create(
		Vector3(candidate.x, global_position.y + 1.4, candidate.z),
		Vector3(candidate.x, global_position.y - 1.2, candidate.z),
		1,
		exclude
	)
	var floor_hit := space.intersect_ray(floor_q)
	if floor_hit.is_empty():
		return Vector3.INF
	if float(floor_hit["normal"].y) < 0.78:
		return Vector3.INF
	var floor_y: float = float(floor_hit["position"].y)
	if absf(floor_y - global_position.y) > 1.1:
		return Vector3.INF

	var landing := Vector3(candidate.x, floor_y + 0.03, candidate.z)
	if _crosses_locked_epp_interlock(landing):
		return Vector3.INF

	if require_los:
		var los_q := PhysicsRayQueryParameters3D.create(
			global_position + Vector3(0.0, 1.0, 0.0),
			landing + Vector3(0.0, 1.0, 0.0),
			1,
			exclude
		)
		if not space.intersect_ray(los_q).is_empty():
			return Vector3.INF

	if not _is_capsule_free_at(landing):
		return Vector3.INF
	return landing

func _is_capsule_free_at(pos: Vector3) -> bool:
	var col_node := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col_node == null or col_node.shape == null or get_world_3d() == null:
		return false
	var space := get_world_3d().direct_space_state
	var sq := PhysicsShapeQueryParameters3D.new()
	sq.shape = col_node.shape
	sq.transform = Transform3D(Basis.IDENTITY, pos + Vector3(0.0, 0.94, 0.0))
	sq.collision_mask = 1
	sq.exclude = [get_rid()]
	if not space.intersect_shape(sq, 1).is_empty():
		return false
	var head_q := PhysicsRayQueryParameters3D.create(
		pos + Vector3(0.0, 0.9, 0.0),
		pos + Vector3(0.0, 1.85, 0.0),
		1,
		[get_rid()]
	)
	return space.intersect_ray(head_q).is_empty()

func _crosses_locked_epp_interlock(landing: Vector3) -> bool:
	if _wearing_epp or not is_inside_tree():
		return false
	var barrier := get_tree().root.find_child("AccessInterlockBarrier", true, false) as StaticBody3D
	if barrier == null:
		return false
	var cs := barrier.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if cs == null or cs.disabled:
		return false
	var bx := barrier.global_position.x
	var bz := barrier.global_position.z
	if absf(landing.z - bz) <= 2.2 and (global_position.x - bx) * (landing.x - bx) <= 0.0:
		return true
	return false

func _try_auto_step(delta: float) -> bool:
	if not is_on_floor() and _was_on_floor_recently <= 0.0:
		return false
	var horiz_vel := Vector3(velocity.x, 0.0, velocity.z)
	var h_speed := horiz_vel.length()
	if h_speed < 0.15:
		return false

	var horiz_dir := horiz_vel.normalized()
	var fwd_dist := clampf(h_speed * delta * 2.5, 0.18, 0.36)
	var step_vec := horiz_dir * fwd_dist
	var fwd_col := KinematicCollision3D.new()
	if not test_move(global_transform, step_vec, fwd_col):
		return false
	# Permitir rampas muy suaves (< ~20°) en move_and_slide(), pero escalar cualquier bordillo/desnivel >= 0.02 m
	if fwd_col.get_normal().y >= 0.94:
		return false

	var up_vec := Vector3(0.0, max_step_height, 0.0)
	if test_move(global_transform, up_vec):
		return false
	var lifted_xf := global_transform.translated(up_vec)
	if test_move(lifted_xf, step_vec):
		return false

	var params := PhysicsTestMotionParameters3D.new()
	params.from = lifted_xf.translated(step_vec)
	params.motion = Vector3(0.0, -max_step_height, 0.0)
	var result := PhysicsTestMotionResult3D.new()
	if PhysicsServer3D.body_test_motion(get_rid(), params, result):
		if result.get_collision_normal().y >= 0.35:
			var step_h: float = max_step_height + result.get_travel().y
			if step_h >= min_step_height and step_h <= max_step_height:
				var lift: float = step_h + 0.015
				var nudge: Vector3 = horiz_dir * minf(fwd_dist * 0.35, 0.10)
				if not test_move(global_transform.translated(Vector3(0.0, lift, 0.0)), nudge):
					global_position += Vector3(nudge.x, lift, nudge.z)
				else:
					global_position.y += lift
				if velocity.y < 0.0:
					velocity.y = 0.0
				if step_h >= 0.04:
					_step_camera_offset_y = clampf(_step_camera_offset_y - step_h, -0.55, 0.0)
				return true
	return false

func _update_fps_head_bob(delta: float) -> void:
	if head == null:
		return
	_step_camera_offset_y = lerpf(_step_camera_offset_y, 0.0, clampf(14.0 * delta, 0.0, 1.0))
	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horiz_speed > 0.35:
		_walk_bob_phase += delta * horiz_speed * 2.1
		var step_cycle := int(floor(_walk_bob_phase / PI))
		if step_cycle != _last_step_half_cycle:
			_last_step_half_cycle = step_cycle
			if footstep_player != null and footstep_player.stream != null:
				footstep_player.pitch_scale = randf_range(0.92, 1.08)
				footstep_player.play()
		var target_y: float = 1.65 + sin(_walk_bob_phase * 2.0) * 0.032 + _step_camera_offset_y
		var target_x: float = cos(_walk_bob_phase) * 0.018
		head.position.x = lerpf(head.position.x, target_x, clampf(12.0 * delta, 0.0, 1.0))
		head.position.y = lerpf(head.position.y, target_y, clampf(12.0 * delta, 0.0, 1.0))
	else:
		head.position.x = lerpf(head.position.x, 0.0, clampf(10.0 * delta, 0.0, 1.0))
		head.position.y = lerpf(head.position.y, 1.65 + _step_camera_offset_y, clampf(10.0 * delta, 0.0, 1.0))

func _update_animations(delta: float, _input_dir: Vector2, is_sprinting: bool) -> void:
	if anim_player == null:
		return

	if is_action_playing:
		action_timer -= delta
		if action_timer <= 0.0:
			is_action_playing = false
			anim_player.speed_scale = 1.0
		else:
			return

	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.3:
		anim_player.speed_scale = clampf(horizontal_speed / walk_speed, 0.65, 1.35)
		if is_sprinting:
			_play_anim("run", 0.2)
		else:
			_play_anim("walk", 0.2)
	else:
		anim_player.speed_scale = 1.0
		_play_anim("idle", 0.3)

func _play_anim(anim_name: String, blend_time: float = 0.2) -> void:
	if anim_player == null or not anim_player.has_animation(anim_name):
		return
	if current_anim_name != anim_name:
		current_anim_name = anim_name
		anim_player.play(anim_name, blend_time)
		var anim = anim_player.get_animation(anim_name)
		if anim != null and anim_name in ["idle", "walk", "run"]:
			anim.loop_mode = Animation.LOOP_LINEAR

func _trigger_action_anim(anim_name: String, duration: float) -> void:
	if anim_player != null and anim_player.has_animation(anim_name):
		is_action_playing = true
		action_timer = duration
		anim_player.speed_scale = 1.0
		current_anim_name = anim_name
		anim_player.play(anim_name, 0.15)
		var anim = anim_player.get_animation(anim_name)
		if anim != null:
			anim.loop_mode = Animation.LOOP_NONE

func _find_interactable(node: Node) -> Node:
	var curr = node
	var group_fallback: Node = null
	while curr != null:
		if curr.has_method("interact"):
			return curr
		if group_fallback == null and curr.is_in_group("interactable"):
			group_fallback = curr
		curr = curr.get_parent()
	return group_fallback

func _update_ray_prompt() -> void:
	if carried_bag != null:
		_emit_prompt("Soltar bulto")
		return

	var close_target: Node = null
	if interaction_ray != null and interaction_ray.is_colliding():
		close_target = _find_interactable(interaction_ray.get_collider())
		if _is_tour_showcase_machine_locked(close_target):
			close_target = null

	if close_target != null and _should_use_close_priority(close_target):
		current_interactable = close_target
		_emit_prompt(_get_minimal_prompt_for(close_target))
		return

	var glow := _get_glow_controller()
	if glow != null and glow.has_method("has_active_green_selection") and glow.has_active_green_selection():
		current_interactable = null
		_emit_prompt(str(glow.get_hover_selection_prompt(active_tool_id)))
		return

	if close_target != null:
		current_interactable = close_target
		_emit_prompt(_get_minimal_prompt_for(close_target))
		return

	current_interactable = null
	var tut := get_tree().root.find_child("TutorialInductionManager", true, false) if is_inside_tree() else null
	if tut != null and tut.has_method("get_interact_advance_prompt"):
		var adv_prompt := String(tut.get_interact_advance_prompt())
		if adv_prompt != "":
			_emit_prompt(adv_prompt)
			return
	_emit_prompt("")

func _get_minimal_prompt_for(target: Node) -> String:
	if target is WorkerNPC:
		if target.has_method("can_interact") and not target.can_interact():
			if target.guide_has_target:
				return "En camino..."
			return "Hablando..."
		if target.is_tour_guide:
			if target.has_method("get_interact_prompt"):
				return target.get_interact_prompt()
			return "Hablar"
		return "Hablar con " + target.worker_role_name
	elif target is PhysicalCableConductor:
		return "Reparar falla · Kit LOTO" if target.is_cut else "Inducir falla · Alicates"
	elif target is PhysicalBreakerPanel:
		if not target.is_door_open:
			return "Abrir tablero CCM"
		var is_tripped: bool = target.breaker_state != PhysicalBreakerPanel.BreakerState.NORMAL_460V
		return "Reparar falla · Kit LOTO" if is_tripped else "Inducir falla · Alicates"
	elif target is PhysicalHopperFeeder:
		return "Reparar falla · Llave 3/4\"" if target.is_jammed else "Inducir falla · Llave 3/4\""
	elif target is MechanicalBolt:
		return "Reparar falla · Llave 3/4\"" if target.is_loosened else "Inducir falla · Llave 3/4\""
	elif target is VentilationCover:
		return "Reparar falla · Alicates" if target.is_blocked else "Inducir falla · Alicates"
	elif target is InteractiveGrainBag:
		return "Cargar bulto"
	elif "epp_equipped" in target:
		return "Guardar EPP" if target.epp_equipped else "Equipar EPP"
	elif target.has_method("get_interact_prompt"):
		return target.get_interact_prompt()
	return "Interactuar"

func _emit_prompt(txt: String) -> void:
	if txt != last_prompt_text:
		last_prompt_text = txt
		var bus = get_node_or_null("/root/EventBus")
		if bus != null and bus.has_signal("prompt_updated"):
			bus.prompt_updated.emit(txt)
