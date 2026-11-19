class_name Tablet3DViewportCard
extends PanelContainer

## Tarjeta 3D interactiva estilo Lab 3 con SubViewport, HUD flotante en vivo,
## botones de cámara (Iso, Frente, Top, Rotar), órbita con mouse y zoom con rueda.

const TTheme = preload("res://scripts/ui/TabletThemeHelper.gd")
const GaitHelper = preload("res://scripts/interactive/HumanGaitAnimator.gd")

var card_id: String = ""
var glow_group: String = ""
var target_node_name: String = ""
var studio_glb_path: String = ""
var target_offset: Vector3 = Vector3.ZERO
var default_target: Vector3 = Vector3.ZERO
var default_yaw_deg: float = 35.0
var default_front_yaw_deg: float = -12.0
var default_pitch_deg: float = 22.0
var default_dist: float = 5.0
var _yaw_deg: float = 35.0
var _pitch_deg: float = 22.0
var _dist: float = 5.0
var _auto_rotate: bool = false
var _dragging: bool = false
var _is_studio: bool = false

var _lbl_title: Label = null
var _lbl_sub: Label = null
var _badge_panel: PanelContainer = null
var _badge_lbl: Label = null
var _hud_lbl: Label = null
var _btn_rotate: Button = null
var _vp_container: SubViewportContainer = null
var _sub_vp: SubViewport = null
var _camera: Camera3D = null
var _tracked_node: Node3D = null
var _cached_tracked_center: Vector3 = Vector3.ZERO
var _has_cached_center: bool = false
var _studio_anim_player: AnimationPlayer = null

func setup(spec: Dictionary, is_worker_studio: bool = false) -> void:
	card_id = str(spec.get("id", ""))
	glow_group = str(spec.get("glow_group", ""))
	target_node_name = str(spec.get("target_node", ""))
	studio_glb_path = str(spec.get("model_path", "")) if is_worker_studio else ""
	_is_studio = is_worker_studio
	default_target = spec.get("fallback_pos", Vector3(0.0, 0.95, 0.0)) if not is_worker_studio else Vector3(0.0, 1.0, 0.0)
	target_offset = Vector3(0.0, 0.9, 0.0) if not is_worker_studio else Vector3.ZERO
	default_yaw_deg = float(spec.get("yaw_deg", -65.0 if is_worker_studio else -24.0))
	default_front_yaw_deg = float(spec.get("front_yaw_deg", -90.0 if is_worker_studio else -12.0))
	default_pitch_deg = float(spec.get("pitch_deg", 12.0 if is_worker_studio else 22.0))
	default_dist = float(spec.get("dist", 2.35 if is_worker_studio else 5.2))
	_yaw_deg = default_yaw_deg
	_pitch_deg = default_pitch_deg
	_dist = default_dist

	_build_ui(
		str(spec.get("title", spec.get("name", "Activo 3D"))),
		str(spec.get("subtitle", spec.get("role", "")))
	)

func _build_ui(title_txt: String, sub_txt: String) -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", TTheme.make_panel_style(TTheme.BG_CARD, TTheme.BORDER_SUBTLE, 8, 8, 8, 1))

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	add_child(vb)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	vb.add_child(top_row)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 1)
	top_row.add_child(title_box)

	_lbl_title = TTheme.make_label(title_txt, 12, TTheme.ACCENT_CYAN)
	_lbl_title.clip_text = true
	title_box.add_child(_lbl_title)

	_lbl_sub = TTheme.make_label(sub_txt, 10, TTheme.TEXT_MUTED)
	_lbl_sub.clip_text = true
	_lbl_sub.visible = (sub_txt != "")
	title_box.add_child(_lbl_sub)

	_badge_panel = PanelContainer.new()
	_badge_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_badge_panel.add_theme_stylebox_override("panel", TTheme.make_pill_style(Color(0.04, 0.25, 0.16, 0.9), TTheme.ACCENT_EMERALD))
	top_row.add_child(_badge_panel)

	_badge_lbl = TTheme.make_label("NORMAL", 9, Color(0.55, 0.98, 0.78), HORIZONTAL_ALIGNMENT_CENTER)
	_badge_panel.add_child(_badge_lbl)

	# Contenedor SubViewport con HUD flotante y controles Iso/Frente/Top/Rotar encima
	var stage_wrap := Control.new()
	stage_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_wrap.clip_contents = true
	vb.add_child(stage_wrap)

	_vp_container = SubViewportContainer.new()
	_vp_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vp_container.stretch = true
	_vp_container.mouse_filter = Control.MOUSE_FILTER_STOP
	_vp_container.gui_input.connect(_on_viewport_gui_input)
	stage_wrap.add_child(_vp_container)

	_sub_vp = SubViewport.new()
	_sub_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_sub_vp.msaa_3d = Viewport.MSAA_2X
	_vp_container.add_child(_sub_vp)

	_camera = Camera3D.new()
	_camera.fov = 48.0 if _is_studio else 52.0
	_camera.current = true
	_sub_vp.add_child(_camera)

	# HUD flotante translúcido arriba a la izquierda (como Lab 3 ui_3d.png)
	var hud_panel := PanelContainer.new()
	hud_panel.position = Vector2(8.0, 8.0)
	hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_panel.add_theme_stylebox_override("panel", TTheme.make_panel_style(Color(0.03, 0.05, 0.10, 0.78), Color(0.22, 0.40, 0.65, 0.7), 6, 8, 5, 1))
	stage_wrap.add_child(hud_panel)

	_hud_lbl = TTheme.make_label("Cargando...", 10, Color(0.86, 0.94, 1.0))
	_hud_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_panel.add_child(_hud_lbl)

	# Botones de cámara rápida abajo a la izquierda: Iso | Frente | Top | Rotar
	var cam_bar := HBoxContainer.new()
	cam_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	cam_bar.position = Vector2(8.0, -32.0)
	cam_bar.offset_left = 8.0
	cam_bar.offset_top = -32.0
	cam_bar.offset_bottom = -6.0
	cam_bar.offset_right = 230.0
	cam_bar.add_theme_constant_override("separation", 4)
	stage_wrap.add_child(cam_bar)

	for preset in [
		{"label": "Iso", "yaw": default_yaw_deg, "pitch": default_pitch_deg, "dist": default_dist},
		{"label": "Frente", "yaw": default_front_yaw_deg, "pitch": 10.0, "dist": default_dist * 0.92},
		{"label": "Top", "yaw": default_yaw_deg, "pitch": 58.0 if _is_studio else 42.0, "dist": default_dist * 1.08}
	]:
		var b := Button.new()
		b.text = preset["label"]
		b.add_theme_font_size_override("font_size", 10)
		TTheme.apply_btn_colors(b, Color(0.08, 0.25, 0.45, 0.9), TTheme.ACCENT_CYAN)
		b.pressed.connect(_set_preset.bind(float(preset["yaw"]), float(preset["pitch"]), float(preset["dist"])))
		cam_bar.add_child(b)

	_btn_rotate = Button.new()
	_btn_rotate.text = "Rotar"
	_btn_rotate.add_theme_font_size_override("font_size", 10)
	_sync_rotate_button_style()
	_btn_rotate.pressed.connect(_toggle_auto_rotate)
	cam_bar.add_child(_btn_rotate)

func initialize_world(tree_root: Node) -> void:
	if _sub_vp == null:
		return
	if _is_studio and not studio_glb_path.is_empty():
		_setup_studio_glb_world()
		return

	var plant := tree_root.find_child("PlantaCompletaSketchUp", true, false) if tree_root != null else null
	if plant != null and tree_root != null and is_inside_tree():
		_sub_vp.own_world_3d = false
		_sub_vp.world_3d = get_viewport().world_3d
		if not target_node_name.is_empty():
			_tracked_node = tree_root.find_child(target_node_name, true, false) as Node3D
	else:
		_setup_studio_fallback_world()
	_update_camera_transform()

func _setup_studio_glb_world() -> void:
	_sub_vp.own_world_3d = true
	_setup_studio_environment()
	if ResourceLoader.exists(studio_glb_path):
		var packed := ResourceLoader.load(studio_glb_path) as PackedScene
		if packed != null:
			var model := packed.instantiate() as Node3D
			model.name = "StudioModel"
			_sub_vp.add_child(model)
			var ap := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
			if ap != null:
				_studio_anim_player = ap
				GaitHelper.upgrade_animations(ap, model)
				if ap.has_animation("idle"):
					ap.play("idle")
				# Pausar inicialmente mientras el viewport esté inactivo para evitar cálculos de esqueleto en CPU
				if _sub_vp.render_target_update_mode == SubViewport.UPDATE_DISABLED:
					ap.pause()
	_update_camera_transform()

func _setup_studio_fallback_world() -> void:
	_sub_vp.own_world_3d = true
	_setup_studio_environment()
	_update_camera_transform()

func _setup_studio_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.032, 0.052, 0.095, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.75, 0.90, 1.0)
	env.ambient_light_energy = 0.85
	we.environment = env
	_sub_vp.add_child(we)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-38.0, 35.0, 0.0)
	key_light.light_energy = 1.35
	_sub_vp.add_child(key_light)

	var rim_light := OmniLight3D.new()
	rim_light.position = Vector3(-1.8, 2.2, -1.8)
	rim_light.light_color = Color(0.35, 0.78, 1.0)
	rim_light.light_energy = 1.4
	rim_light.omni_range = 8.0
	_sub_vp.add_child(rim_light)

func set_rendering_active(active: bool) -> void:
	if _sub_vp == null:
		return
	if DisplayServer.get_name() == "headless":
		_sub_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		if _studio_anim_player != null:
			_studio_anim_player.pause()
		return
	_sub_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	if _studio_anim_player != null:
		if active:
			if not _studio_anim_player.is_playing() and _studio_anim_player.has_animation("idle"):
				_studio_anim_player.play("idle")
		else:
			_studio_anim_player.pause()

func set_hud_status(lines: PackedStringArray, state_txt: String, severity: String) -> void:
	if _hud_lbl != null:
		_hud_lbl.text = "\n".join(lines)
	TTheme.set_badge_state(_badge_panel, _badge_lbl, state_txt, severity)

func _process(delta: float) -> void:
	if _sub_vp == null or _sub_vp.render_target_update_mode != SubViewport.UPDATE_ALWAYS:
		return
	if _auto_rotate:
		_yaw_deg = fmod(_yaw_deg + delta * 24.0, 360.0)
	_update_camera_transform()

func _compute_tracked_center() -> Vector3:
	if _tracked_node == null or not is_instance_valid(_tracked_node):
		return default_target
	if _tracked_node.name == "MotorMillUnit":
		return _tracked_node.global_position + Vector3(0.0, 0.9, 0.0)
	if _tracked_node.name == "PhysicalBreakerPanel":
		return _tracked_node.global_position + Vector3(0.0, 0.74, 0.0)
	var is_moving := ("Truck" in target_node_name)
	if _has_cached_center and not is_moving:
		return _cached_tracked_center
	var has_box := false
	var wb := AABB()
	for ch in _tracked_node.find_children("*", "MeshInstance3D", true, false):
		var mi := ch as MeshInstance3D
		if mi == null or mi.mesh == null or mi.name == "GlowOutlineShell" or mi.name == "defaultMaterial3":
			continue
		var lb := mi.mesh.get_aabb()
		var xf := mi.global_transform
		for i in range(8):
			var wp := xf * Vector3(
				lb.position.x + (lb.size.x if (i & 1) != 0 else 0.0),
				lb.position.y + (lb.size.y if (i & 2) != 0 else 0.0),
				lb.position.z + (lb.size.z if (i & 4) != 0 else 0.0)
			)
			if not has_box:
				wb = AABB(wp, Vector3.ZERO)
				has_box = true
			else:
				wb = wb.expand(wp)
	if has_box:
		_cached_tracked_center = wb.get_center()
		_has_cached_center = true
		return _cached_tracked_center
	return default_target

func _update_camera_transform() -> void:
	if _camera == null or not _camera.is_inside_tree():
		return
	var focus := default_target
	if not _is_studio and _tracked_node != null and is_instance_valid(_tracked_node):
		focus = _compute_tracked_center()

	var yaw_rad := deg_to_rad(_yaw_deg)
	var pitch_rad := deg_to_rad(_pitch_deg)
	var offset := Vector3(
		_dist * cos(pitch_rad) * cos(yaw_rad),
		_dist * sin(pitch_rad),
		_dist * cos(pitch_rad) * sin(yaw_rad)
	)
	_camera.global_position = focus + offset
	if not _camera.global_position.is_equal_approx(focus):
		_camera.look_at(focus, Vector3.UP)

func _set_preset(yaw: float, pitch: float, dist: float) -> void:
	_auto_rotate = false
	_sync_rotate_button_style()
	_yaw_deg = yaw
	_pitch_deg = pitch
	_dist = dist
	_update_camera_transform()

func _toggle_auto_rotate() -> void:
	_auto_rotate = not _auto_rotate
	_sync_rotate_button_style()

func _sync_rotate_button_style() -> void:
	if _btn_rotate == null:
		return
	var bg := Color(0.75, 0.42, 0.05, 0.95) if _auto_rotate else Color(0.25, 0.22, 0.14, 0.9)
	var bd := TTheme.ACCENT_AMBER if _auto_rotate else TTheme.BORDER_SUBTLE
	TTheme.apply_btn_colors(_btn_rotate, bg, bd)

func _on_viewport_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_dist = clampf(_dist * 0.88, 1.4, 28.0)
			_update_camera_transform()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_dist = clampf(_dist * 1.12, 1.4, 28.0)
			_update_camera_transform()
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		_auto_rotate = false
		_sync_rotate_button_style()
		_yaw_deg -= mm.relative.x * 0.55
		var min_p := 6.0 if _is_studio else 8.0
		var max_p := 72.0 if _is_studio else 46.0
		_pitch_deg = clampf(_pitch_deg + mm.relative.y * 0.45, min_p, max_p)
		_update_camera_transform()
