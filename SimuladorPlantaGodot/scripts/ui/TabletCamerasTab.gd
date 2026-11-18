class_name TabletCamerasTab
extends Control

## Apartado dedicado de Cámaras CCTV Multi-Punto de la Planta (8 cámaras en vivo)
## con modo Vista Principal HD y Mosaico 2x2 simultáneo + Auto-Tour.

const TTheme = preload("res://scripts/ui/TabletThemeHelper.gd")
const TCatalog = preload("res://scripts/ui/TabletDataCatalog.gd")

var selected_camera_idx: int = 0
var view_mode: String = "QUAD" # "SINGLE" | "QUAD"
var quad_bank: int = 0 # 0 = CAM 01..04, 1 = CAM 05..08
var auto_tour_enabled: bool = false
var _auto_tour_timer: float = 0.0
var _is_tab_active: bool = false

var _lbl_status: Label = null
var _btn_single: Button = null
var _btn_quad: Button = null
var _btn_bank0: Button = null
var _btn_bank1: Button = null
var _btn_tour: Button = null
var _single_wrap: Control = null
var _quad_grid: GridContainer = null
var _cam_list_btns: Array[Button] = []

var _single_vp: SubViewport = null
var _single_cam: Camera3D = null
var _single_hud_top: Label = null
var _single_hud_tel: Label = null

var _quad_slots: Array[Dictionary] = []

func _ready() -> void:
	name = "TabCamarasCCTV"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	call_deferred("_bind_world_contexts")

func _build_ui() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 8)
	add_child(vb)

	# Barra de control VMS superior
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", TTheme.make_panel_style(TTheme.BG_CARD, TTheme.BORDER_SUBTLE, 6, 10, 6))
	vb.add_child(bar)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	bar.add_child(hb)

	var rec_pill := PanelContainer.new()
	rec_pill.add_theme_stylebox_override("panel", TTheme.make_pill_style(Color(0.32, 0.06, 0.07), TTheme.ACCENT_RED))
	rec_pill.add_child(TTheme.make_label("En vivo", 10, Color(1.0, 0.65, 0.65)))
	hb.add_child(rec_pill)

	_lbl_status = TTheme.make_label("CAM 01 · Molienda", 11, TTheme.TEXT_WHITE)
	_lbl_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_status.clip_text = true
	hb.add_child(_lbl_status)

	_btn_single = _make_bar_btn("Vista principal", func(): set_view_mode("SINGLE"))
	_btn_quad = _make_bar_btn("Mosaico 2×2", func(): set_view_mode("QUAD"))
	_btn_bank0 = _make_bar_btn("CAM 01–04", func(): _set_quad_bank(0))
	_btn_bank1 = _make_bar_btn("CAM 05–08", func(): _set_quad_bank(1))
	_btn_tour = _make_bar_btn("Ronda auto", _toggle_auto_tour)

	for b in [_btn_single, _btn_quad, _btn_bank0, _btn_bank1, _btn_tour]:
		hb.add_child(b)

	# Cuerpo principal: Visores a la izquierda + Selector lateral de 8 puntos a la derecha
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	vb.add_child(body)

	var stage := PanelContainer.new()
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_theme_stylebox_override("panel", TTheme.make_panel_style(Color(0.025, 0.038, 0.070), TTheme.BORDER_SUBTLE, 8, 6, 6))
	body.add_child(stage)

	var stage_inner := Control.new()
	stage_inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage_inner.clip_contents = true
	stage.add_child(stage_inner)

	_build_single_view(stage_inner)
	_build_quad_view(stage_inner)
	_build_camera_sidebar(body)

	select_camera_index(0)
	set_view_mode("QUAD")

func _build_single_view(parent: Control) -> void:
	_single_wrap = Control.new()
	_single_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(_single_wrap)

	var vpc := SubViewportContainer.new()
	vpc.set_anchors_preset(Control.PRESET_FULL_RECT)
	vpc.stretch = true
	_single_wrap.add_child(vpc)

	_single_vp = SubViewport.new()
	_single_vp.size = Vector2i(1024, 576)
	_single_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_single_vp.msaa_3d = Viewport.MSAA_2X
	vpc.add_child(_single_vp)

	_single_cam = Camera3D.new()
	_single_cam.current = true
	_single_vp.add_child(_single_cam)

	# Overlay HUD estilo cámara CCTV de planta
	var overlay_top := PanelContainer.new()
	overlay_top.position = Vector2(10, 10)
	overlay_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_top.add_theme_stylebox_override("panel", TTheme.make_panel_style(Color(0.02, 0.04, 0.08, 0.78), TTheme.ACCENT_CYAN, 6, 10, 5))
	_single_wrap.add_child(overlay_top)
	_single_hud_top = TTheme.make_label("CAM_01_MOLIENDA", 11, TTheme.ACCENT_CYAN)
	overlay_top.add_child(_single_hud_top)

	var overlay_bot := PanelContainer.new()
	overlay_bot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	overlay_bot.offset_left = 10
	overlay_bot.offset_top = -34
	overlay_bot.offset_right = -10
	overlay_bot.offset_bottom = -8
	overlay_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_bot.add_theme_stylebox_override("panel", TTheme.make_panel_style(Color(0.02, 0.04, 0.08, 0.78), TTheme.BORDER_SUBTLE, 6, 10, 4))
	_single_wrap.add_child(overlay_bot)
	_single_hud_tel = TTheme.make_label("Motor 10 HP: 1750 RPM | 460 V | 58 °C | Estado OK", 10, TTheme.TEXT_WHITE)
	_single_hud_tel.clip_text = true
	overlay_bot.add_child(_single_hud_tel)

func _build_quad_view(parent: Control) -> void:
	_quad_grid = GridContainer.new()
	_quad_grid.columns = 2
	_quad_grid.visible = false
	_quad_grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	_quad_grid.add_theme_constant_override("h_separation", 6)
	_quad_grid.add_theme_constant_override("v_separation", 6)
	parent.add_child(_quad_grid)

	_quad_slots.clear()
	for i in range(4):
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cell.add_theme_stylebox_override("panel", TTheme.make_panel_style(Color(0.02, 0.03, 0.06), TTheme.BORDER_SUBTLE, 5, 2, 2))
		_quad_grid.add_child(cell)

		var wrap := Control.new()
		wrap.clip_contents = true
		cell.add_child(wrap)

		var vpc := SubViewportContainer.new()
		vpc.set_anchors_preset(Control.PRESET_FULL_RECT)
		vpc.stretch = true
		vpc.gui_input.connect(_on_quad_clicked.bind(i))
		wrap.add_child(vpc)

		var vp := SubViewport.new()
		vp.size = Vector2i(512, 288)
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		vp.msaa_3d = Viewport.MSAA_2X
		vpc.add_child(vp)

		var cam := Camera3D.new()
		cam.current = true
		vp.add_child(cam)

		var tag := PanelContainer.new()
		tag.position = Vector2(6, 6)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.add_theme_stylebox_override("panel", TTheme.make_panel_style(Color(0.02, 0.04, 0.08, 0.80), TTheme.BORDER_SUBTLE, 4, 6, 3))
		wrap.add_child(tag)
		var lbl := TTheme.make_label("CAM 0%d" % (i + 1), 10, TTheme.ACCENT_CYAN)
		tag.add_child(lbl)

		_quad_slots.append({"vp": vp, "cam": cam, "lbl": lbl, "cam_idx": i})

func _build_camera_sidebar(body: HBoxContainer) -> void:
	var side := PanelContainer.new()
	side.custom_minimum_size.x = 310
	side.add_theme_stylebox_override("panel", TTheme.make_panel_style())
	body.add_child(side)

	var svb := VBoxContainer.new()
	svb.add_theme_constant_override("separation", 6)
	side.add_child(svb)
	svb.add_child(TTheme.make_label("Cámaras", 12, TTheme.ACCENT_CYAN))

	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	svb.add_child(sc)

	var lvb := VBoxContainer.new()
	lvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lvb.add_theme_constant_override("separation", 5)
	sc.add_child(lvb)

	_cam_list_btns.clear()
	for i in range(TCatalog.PLANT_CCTV_CAMERAS.size()):
		var c: Dictionary = TCatalog.PLANT_CCTV_CAMERAS[i]
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = "%s\n  %s" % [c["short"], c["zone"]]
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_on_sidebar_camera_clicked.bind(i))
		lvb.add_child(btn)
		_cam_list_btns.append(btn)

	var nav_hb := HBoxContainer.new()
	nav_hb.add_theme_constant_override("separation", 6)
	svb.add_child(nav_hb)
	var b_prev := _make_bar_btn("Anterior", func(): step_camera(-1))
	var b_next := _make_bar_btn("Siguiente", func(): step_camera(1))
	b_prev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_hb.add_child(b_prev)
	nav_hb.add_child(b_next)

func _bind_world_contexts() -> void:
	if not is_inside_tree():
		return
	var plant := get_tree().root.find_child("PlantaCompletaSketchUp", true, false)
	var use_shared := (plant != null and get_viewport() != null and get_viewport().world_3d != null)
	if use_shared:
		var shared_w := get_viewport().world_3d
		_single_vp.own_world_3d = false
		_single_vp.world_3d = shared_w
		for slot in _quad_slots:
			var qvp: SubViewport = slot["vp"]
			qvp.own_world_3d = false
			qvp.world_3d = shared_w
	else:
		_setup_fallback_world(_single_vp)
		for slot in _quad_slots:
			_setup_fallback_world(slot["vp"] as SubViewport)
	_apply_single_camera_pose()
	_apply_quad_bank_poses()

func _setup_fallback_world(vp: SubViewport) -> void:
	if vp == null:
		return
	vp.own_world_3d = true
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.05, 0.09)
	we.environment = env
	vp.add_child(we)

func set_rendering_active(active: bool) -> void:
	_is_tab_active = active
	var allow := active and DisplayServer.get_name() != "headless"
	if _single_vp != null:
		_single_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if (allow and view_mode == "SINGLE") else SubViewport.UPDATE_DISABLED
	for slot in _quad_slots:
		var qvp: SubViewport = slot["vp"]
		qvp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if (allow and view_mode == "QUAD") else SubViewport.UPDATE_DISABLED

func set_view_mode(mode: String) -> void:
	view_mode = mode
	if _single_wrap != null: _single_wrap.visible = (mode == "SINGLE")
	if _quad_grid != null: _quad_grid.visible = (mode == "QUAD")
	if _btn_bank0 != null: _btn_bank0.visible = (mode == "QUAD")
	if _btn_bank1 != null: _btn_bank1.visible = (mode == "QUAD")
	_sync_bar_buttons()
	if mode == "QUAD":
		_apply_quad_bank_poses()
	set_rendering_active(_is_tab_active)

func _set_quad_bank(bank: int) -> void:
	quad_bank = clampi(bank, 0, 1)
	_sync_bar_buttons()
	_apply_quad_bank_poses()

func _toggle_auto_tour() -> void:
	auto_tour_enabled = not auto_tour_enabled
	_auto_tour_timer = 0.0
	_sync_bar_buttons()

func _process(delta: float) -> void:
	if not _is_tab_active or not auto_tour_enabled or view_mode != "SINGLE":
		return
	_auto_tour_timer += delta
	if _auto_tour_timer >= 4.0:
		_auto_tour_timer = 0.0
		step_camera(1)

func step_camera(dir: int) -> void:
	var n := TCatalog.PLANT_CCTV_CAMERAS.size()
	select_camera_index((selected_camera_idx + dir + n) % n)

func _on_sidebar_camera_clicked(idx: int) -> void:
	select_camera_index(idx)
	if view_mode != "SINGLE":
		set_view_mode("SINGLE")

func select_camera_by_id(cam_id: String) -> void:
	for i in range(TCatalog.PLANT_CCTV_CAMERAS.size()):
		if TCatalog.PLANT_CCTV_CAMERAS[i]["id"] == cam_id:
			select_camera_index(i)
			return

func select_camera_index(idx: int) -> void:
	selected_camera_idx = clampi(idx, 0, TCatalog.PLANT_CCTV_CAMERAS.size() - 1)
	var spec: Dictionary = TCatalog.PLANT_CCTV_CAMERAS[selected_camera_idx]
	if _lbl_status != null:
		_lbl_status.text = "%s — %s" % [spec["short"], spec["zone"]]
	if _single_hud_top != null:
		_single_hud_top.text = "%s  |  %s" % [spec["id"], spec["zone"]]
	for i in range(_cam_list_btns.size()):
		var active := (i == selected_camera_idx)
		TTheme.apply_btn_colors(_cam_list_btns[i], TTheme.ACCENT_BLUE if active else TTheme.BG_SUBCARD, TTheme.ACCENT_CYAN if active else TTheme.BORDER_SUBTLE)
	_apply_single_camera_pose()

func _apply_single_camera_pose() -> void:
	if _single_cam == null:
		return
	var spec: Dictionary = TCatalog.PLANT_CCTV_CAMERAS[selected_camera_idx]
	_aim_cam(_single_cam, spec)

func _apply_quad_bank_poses() -> void:
	var base := quad_bank * 4
	for i in range(_quad_slots.size()):
		var cam_idx := (base + i) % TCatalog.PLANT_CCTV_CAMERAS.size()
		var spec: Dictionary = TCatalog.PLANT_CCTV_CAMERAS[cam_idx]
		var slot: Dictionary = _quad_slots[i]
		slot["cam_idx"] = cam_idx
		(slot["lbl"] as Label).text = spec["short"]
		_aim_cam(slot["cam"] as Camera3D, spec)

func _aim_cam(cam: Camera3D, spec: Dictionary) -> void:
	if cam == null:
		return
	cam.fov = float(spec.get("fov", 60.0))
	var pos: Vector3 = spec["position"]
	var tgt: Vector3 = spec["look_at"]
	cam.position = pos
	if cam.is_inside_tree() and not pos.is_equal_approx(tgt):
		cam.look_at(tgt, Vector3.UP)

func _on_quad_clicked(event: InputEvent, slot_idx: int) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var cam_idx := int(_quad_slots[slot_idx]["cam_idx"])
		select_camera_index(cam_idx)
		set_view_mode("SINGLE")

func update_telemetry_overlay(t: Dictionary) -> void:
	if _single_hud_tel == null or t.is_empty():
		return
	_single_hud_tel.text = "Motor 10 HP: %.0f RPM | I_max: %.1f A | V_LL: %.0f V | T°: %.1f °C | Vib: %.2f mm/s" % [
		float(t.get("rpm", 0.0)),
		maxf(float(t.get("current_a", 0.0)), maxf(float(t.get("current_b", 0.0)), float(t.get("current_c", 0.0)))),
		float(t.get("voltage", 460.0)),
		float(t.get("temp_c", 28.0)),
		float(t.get("vibration_rms", 0.0))
	]

func _sync_bar_buttons() -> void:
	TTheme.apply_btn_colors(_btn_single, TTheme.ACCENT_BLUE if view_mode == "SINGLE" else TTheme.BG_SUBCARD, TTheme.ACCENT_CYAN if view_mode == "SINGLE" else TTheme.BORDER_SUBTLE)
	TTheme.apply_btn_colors(_btn_quad, TTheme.ACCENT_BLUE if view_mode == "QUAD" else TTheme.BG_SUBCARD, TTheme.ACCENT_CYAN if view_mode == "QUAD" else TTheme.BORDER_SUBTLE)
	TTheme.apply_btn_colors(_btn_bank0, TTheme.ACCENT_BLUE if quad_bank == 0 else TTheme.BG_SUBCARD, TTheme.ACCENT_CYAN if quad_bank == 0 else TTheme.BORDER_SUBTLE)
	TTheme.apply_btn_colors(_btn_bank1, TTheme.ACCENT_BLUE if quad_bank == 1 else TTheme.BG_SUBCARD, TTheme.ACCENT_CYAN if quad_bank == 1 else TTheme.BORDER_SUBTLE)
	TTheme.apply_btn_colors(_btn_tour, Color(0.06, 0.42, 0.28) if auto_tour_enabled else TTheme.BG_SUBCARD, TTheme.ACCENT_EMERALD if auto_tour_enabled else TTheme.BORDER_SUBTLE)
	if _lbl_status != null:
		if view_mode == "QUAD":
			_lbl_status.text = "Mosaico 2×2 · %s" % ("CAM 01–04" if quad_bank == 0 else "CAM 05–08")
		else:
			var spec: Dictionary = TCatalog.PLANT_CCTV_CAMERAS[selected_camera_idx]
			_lbl_status.text = "%s · %s" % [spec["short"], spec["zone"]]

func _make_bar_btn(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_size_override("font_size", 10)
	b.pressed.connect(cb)
	return b
