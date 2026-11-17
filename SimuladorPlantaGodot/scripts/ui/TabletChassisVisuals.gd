extends Control
class_name TabletChassisVisuals

## Generador procedural de textura y controles físicos decorativos (no funcionales)
## para la Tablet Industrial AgroMolinos, más candado estricto de tamaño invariante.

const CHASSIS_SIZE := Vector2(1320.0, 830.0)
const SCREEN_SIZE := Vector2(1180.0, 700.0)
const SCREEN_POS_IN_CHASSIS := Vector2(70.0, 58.0)

var _frame: PanelContainer = null
var _chassis_tex_rect: TextureRect = null
var _enforcing_size: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	clip_contents = true

	_frame = get_parent().get_node_or_null("Frame") as PanelContainer
	_build_chassis_texture_layer()
	_build_decorative_hardware_controls()
	_lock_frame_descendants()
	enforce_invariant_size()

	if not resized.is_connected(enforce_invariant_size):
		resized.connect(enforce_invariant_size)
	if _frame != null:
		if not _frame.resized.is_connected(enforce_invariant_size):
			_frame.resized.connect(enforce_invariant_size)
		if not _frame.sort_children.is_connected(enforce_invariant_size):
			_frame.sort_children.connect(enforce_invariant_size)
	var parent_ctrl := get_parent() as Control
	if parent_ctrl != null and not parent_ctrl.visibility_changed.is_connected(enforce_invariant_size):
		parent_ctrl.visibility_changed.connect(enforce_invariant_size)
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(enforce_invariant_size):
		vp.size_changed.connect(enforce_invariant_size)

func enforce_invariant_size() -> void:
	if _enforcing_size:
		return
	_enforcing_size = true

	# Fija invariante absoluto del chasis de la tablet (1320 x 830) centrado en pantalla
	custom_minimum_size = CHASSIS_SIZE
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -660.0
	offset_top = -408.0
	offset_right = 660.0
	offset_bottom = 422.0
	size = CHASSIS_SIZE
	scale = Vector2.ONE

	# Fija invariante absoluto del panel interior de pantalla (1180 x 700)
	if _frame != null and is_instance_valid(_frame):
		_frame.custom_minimum_size = SCREEN_SIZE
		_frame.clip_contents = true
		_frame.anchor_left = 0.5
		_frame.anchor_top = 0.5
		_frame.anchor_right = 0.5
		_frame.anchor_bottom = 0.5
		_frame.offset_left = -590.0
		_frame.offset_top = -350.0
		_frame.offset_right = 590.0
		_frame.offset_bottom = 350.0
		_frame.size = SCREEN_SIZE
		_frame.scale = Vector2.ONE

	_enforcing_size = false

func _lock_frame_descendants() -> void:
	if _frame == null:
		return
	_frame.clip_contents = true
	var vbox := _frame.get_node_or_null("VBox") as Control
	if vbox != null:
		vbox.clip_contents = true
	var chk_vbox := _frame.find_child("ChecklistVBox", true, false)
	if chk_vbox != null and not chk_vbox.child_entered_tree.is_connected(_on_checklist_item_added):
		chk_vbox.child_entered_tree.connect(_on_checklist_item_added)

func _on_checklist_item_added(node: Node) -> void:
	if node is Button:
		var btn := node as Button
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size.x = 0.0
	call_deferred("enforce_invariant_size")

func _clamp_label(lbl: Label, expand_x: bool) -> void:
	if lbl == null:
		return
	lbl.clip_text = true
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if expand_x:
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _build_chassis_texture_layer() -> void:
	_chassis_tex_rect = TextureRect.new()
	_chassis_tex_rect.name = "ChassisTexture"
	_chassis_tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chassis_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chassis_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_chassis_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chassis_tex_rect.focus_mode = Control.FOCUS_NONE
	_chassis_tex_rect.texture = _generate_rugged_tablet_texture(int(CHASSIS_SIZE.x), int(CHASSIS_SIZE.y))
	add_child(_chassis_tex_rect)

func _generate_rugged_tablet_texture(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))

	# 1. Cuerpo metálico anodizado titanio-pizarra con gradiente sutil vertical + grano cepillado
	var bx0: int = 8
	var by0: int = 8
	var bw: int = w - 16
	var bh: int = h - 16
	for y in range(by0, by0 + bh):
		var t: float = float(y - by0) / float(bh)
		var base_v: float = lerpf(0.215, 0.140, t)
		var streak: float = sin(float(y) * 0.85) * 0.005 + sin(float(y) * 2.3) * 0.003
		var row_col := Color(base_v + streak, base_v + 0.015 + streak, base_v + 0.032 + streak, 1.0)
		img.fill_rect(Rect2i(bx0, y, bw, 1), row_col)

	# Líneas finas de textura metal cepillado horizontal en los biseles
	for i in range(36):
		var sy: int = 16 + ((i * 23) % (h - 32))
		var sx: int = 18 + ((i * 73) % 120)
		var sw: int = mini(w - 36 - sx, 190 + ((i * 53) % 360))
		img.fill_rect(Rect2i(sx, sy, sw, 1), Color(0.36, 0.41, 0.48, 0.16))

	# 2. Marco protector de elastómero negro mate + biseles 3D exteriores
	_paint_frame_bands(img, bx0, by0, bw, bh)

	# 3. Parachoques reforzados en las 4 esquinas con redondeo externo limpio
	_paint_corner_bumpers(img, bx0, by0, bw, bh, 38)
	_round_outer_corners(img, bx0, by0, bw, bh, 28)

	# 4. Estrías ergonómicas antideslizantes en agarres laterales izquierdo y derecho
	var grip_col := Color(0.055, 0.062, 0.075, 1.0)
	var grip_hi := Color(0.22, 0.25, 0.30, 0.7)
	for side_x in [11, w - 19]:
		for notch in range(18):
			var ny: int = 430 + notch * 12
			if ny + 6 < h - 90:
				img.fill_rect(Rect2i(side_x, ny, 8, 5), grip_col)
				img.fill_rect(Rect2i(side_x, ny + 5, 8, 1), grip_hi)

	# 5. Cavidad biselada donde se aloja la pantalla LCD (70, 58, 1180, 700)
	var sx0: int = int(SCREEN_POS_IN_CHASSIS.x)
	var sy0: int = int(SCREEN_POS_IN_CHASSIS.y)
	var sw_s: int = int(SCREEN_SIZE.x)
	var sh_s: int = int(SCREEN_SIZE.y)
	# Bisel metálico interior + junta de goma negra
	img.fill_rect(Rect2i(sx0 - 7, sy0 - 7, sw_s + 14, sh_s + 14), Color(0.03, 0.035, 0.045, 1.0))
	img.fill_rect(Rect2i(sx0 - 9, sy0 - 9, sw_s + 18, 2), Color(0.06, 0.07, 0.09, 1.0))
	img.fill_rect(Rect2i(sx0 - 9, sy0 + sh_s + 7, sw_s + 18, 2), Color(0.26, 0.31, 0.38, 0.85))
	img.fill_rect(Rect2i(sx0 - 9, sy0 - 9, 2, sh_s + 18), Color(0.06, 0.07, 0.09, 1.0))
	img.fill_rect(Rect2i(sx0 + sw_s + 7, sy0 - 9, 2, sh_s + 18), Color(0.24, 0.29, 0.36, 0.85))
	img.fill_rect(Rect2i(sx0, sy0, sw_s, sh_s), Color(0.025, 0.032, 0.05, 1.0))

	# 6. Tornillos hexagonales industriales empotrados en chasis
	var screws := [
		Vector2i(32, 32), Vector2i(w - 32, 32),
		Vector2i(32, h - 32), Vector2i(w - 32, h - 32),
		Vector2i(36, int(h * 0.5)), Vector2i(w - 36, int(h * 0.5)),
	]
	for sc in screws:
		_paint_hex_screw(img, sc.x, sc.y)

	# 7. Micro-rejillas simétricas de altavoces frontales libres de la barra superior derecha
	for spk_x0 in [335, 818]:
		for gx in range(0, 66, 6):
			for gy in [25, 31]:
				img.fill_rect(Rect2i(spk_x0 + gx, gy, 3, 3), Color(0.035, 0.04, 0.05, 1.0))
				img.fill_rect(Rect2i(spk_x0 + gx, gy + 3, 3, 1), Color(0.30, 0.35, 0.42, 0.72))

	return ImageTexture.create_from_image(img)

func _paint_frame_bands(img: Image, bx0: int, by0: int, bw: int, bh: int) -> void:
	# Borde goma exterior oscuro (8 px) + bisel luminoso superior/izquierdo + sombra inferior/derecha
	var rubber := Color(0.075, 0.082, 0.095, 1.0)
	img.fill_rect(Rect2i(bx0, by0, bw, 9), rubber)
	img.fill_rect(Rect2i(bx0, by0 + bh - 9, bw, 9), rubber)
	img.fill_rect(Rect2i(bx0, by0, 9, bh), rubber)
	img.fill_rect(Rect2i(bx0 + bw - 9, by0, 9, bh), rubber)

	img.fill_rect(Rect2i(bx0 + 9, by0 + 9, bw - 18, 2), Color(0.32, 0.37, 0.44, 0.9))
	img.fill_rect(Rect2i(bx0 + 9, by0 + 9, 2, bh - 18), Color(0.28, 0.33, 0.40, 0.85))
	img.fill_rect(Rect2i(bx0 + 9, by0 + bh - 11, bw - 18, 2), Color(0.04, 0.045, 0.06, 0.95))
	img.fill_rect(Rect2i(bx0 + bw - 11, by0 + 9, 2, bh - 18), Color(0.04, 0.045, 0.06, 0.95))

	# Banda industrial decorativa naranja/ámbar en el borde superior izquierdo y esquinas
	img.fill_rect(Rect2i(bx0 + 62, by0 + 9, 64, 3), Color(0.95, 0.52, 0.12, 0.85))

func _paint_corner_bumpers(img: Image, bx0: int, by0: int, bw: int, bh: int, span: int) -> void:
	var bumper_col := Color(0.065, 0.072, 0.084, 1.0)
	var accent_col := Color(0.22, 0.25, 0.30, 0.9)
	var corners := [
		Vector2i(bx0, by0),
		Vector2i(bx0 + bw - span, by0),
		Vector2i(bx0, by0 + bh - span),
		Vector2i(bx0 + bw - span, by0 + bh - span),
	]
	for idx in range(corners.size()):
		var cx: int = corners[idx].x
		var cy: int = corners[idx].y
		img.fill_rect(Rect2i(cx, cy, span, span), bumper_col)
		# Costura metálica interior del parachoques
		if idx == 0:
			img.fill_rect(Rect2i(cx + span - 2, cy, 2, span), accent_col)
			img.fill_rect(Rect2i(cx, cy + span - 2, span, 2), accent_col)
		elif idx == 1:
			img.fill_rect(Rect2i(cx, cy, 2, span), accent_col)
			img.fill_rect(Rect2i(cx, cy + span - 2, span, 2), accent_col)
		elif idx == 2:
			img.fill_rect(Rect2i(cx + span - 2, cy, 2, span), accent_col)
			img.fill_rect(Rect2i(cx, cy, span, 2), accent_col)
		else:
			img.fill_rect(Rect2i(cx, cy, 2, span), accent_col)
			img.fill_rect(Rect2i(cx, cy, span, 2), accent_col)

func _round_outer_corners(img: Image, bx0: int, by0: int, bw: int, bh: int, r: int) -> void:
	var bx1: int = bx0 + bw - 1
	var by1: int = by0 + bh - 1
	var r2: float = float(r * r)
	for dy in range(r):
		for dx in range(r):
			var dist_sq: float = float((r - dx) * (r - dx) + (r - dy) * (r - dy))
			if dist_sq > r2:
				img.set_pixel(bx0 + dx, by0 + dy, Color(0, 0, 0, 0))
				img.set_pixel(bx1 - dx, by0 + dy, Color(0, 0, 0, 0))
				img.set_pixel(bx0 + dx, by1 - dy, Color(0, 0, 0, 0))
				img.set_pixel(bx1 - dx, by1 - dy, Color(0, 0, 0, 0))

func _paint_hex_screw(img: Image, cx: int, cy: int) -> void:
	for dy in range(-7, 8):
		for dx in range(-7, 8):
			var d2: int = dx * dx + dy * dy
			if d2 <= 49:
				if d2 >= 30:
					img.set_pixel(cx + dx, cy + dy, Color(0.03, 0.035, 0.045, 1.0))
				elif abs(dx) <= 3 and abs(dy) <= 1 or abs(dy) <= 3 and abs(dx) <= 1:
					img.set_pixel(cx + dx, cy + dy, Color(0.06, 0.065, 0.08, 1.0))
				else:
					var shade: float = 0.38 - float(dx + dy) * 0.015
					img.set_pixel(cx + dx, cy + dy, Color(shade, shade + 0.03, shade + 0.06, 1.0))

func _build_decorative_hardware_controls() -> void:
	var chrome_root := Control.new()
	chrome_root.name = "DecorativeHardwareUI"
	chrome_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	chrome_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome_root.focus_mode = Control.FOCUS_NONE
	add_child(chrome_root)

	# --- 1. BOTONES FÍSICOS SOBRESALIENTES EN BORDES (NO FUNCIONALES) ---
	_add_bezel_hw_key(chrome_root, "HwBtnPower", Rect2(68, 1, 66, 9), Color(0.88, 0.42, 0.10), Color(1.0, 0.62, 0.24))
	_add_bezel_hw_key(chrome_root, "HwSwitchHold", Rect2(148, 1, 46, 9), Color(0.24, 0.27, 0.32), Color(0.42, 0.46, 0.54))
	_add_bezel_hw_key(chrome_root, "HwBtnVolUp", Rect2(1, 185, 9, 54), Color(0.22, 0.25, 0.30), Color(0.38, 0.43, 0.50))
	_add_bezel_hw_key(chrome_root, "HwBtnVolDown", Rect2(1, 245, 9, 54), Color(0.22, 0.25, 0.30), Color(0.38, 0.43, 0.50))
	_add_bezel_hw_key(chrome_root, "HwBtnFnAux", Rect2(1, 330, 9, 64), Color(0.82, 0.44, 0.12), Color(0.98, 0.62, 0.22))
	_add_bezel_hw_key(chrome_root, "HwPortCover", Rect2(1310, 495, 9, 130), Color(0.11, 0.13, 0.16), Color(0.28, 0.32, 0.38))

	# Serigrafías laterales alineadas con botones físicos
	_add_silkscreen(chrome_root, "ON/OFF", Vector2(78, 19), 9, Color(0.95, 0.62, 0.28))
	_add_silkscreen(chrome_root, "HOLD", Vector2(154, 19), 9, Color(0.68, 0.74, 0.82))
	_add_silkscreen(chrome_root, "VOL+", Vector2(18, 204), 9, Color(0.68, 0.75, 0.84))
	_add_silkscreen(chrome_root, "VOL-", Vector2(18, 264), 9, Color(0.68, 0.75, 0.84))
	_add_silkscreen(chrome_root, "FN1", Vector2(20, 355), 9, Color(0.95, 0.62, 0.25))
	_add_silkscreen(chrome_root, "USB-C\nRS485", Vector2(1260, 542), 9, Color(0.55, 0.64, 0.74))
	_add_silkscreen(chrome_root, "IP65\nIEC", Vector2(1272, 168), 9, Color(0.48, 0.68, 0.82))

	# --- 2. BISEL SUPERIOR: CÁMARA FRONTAL, LEDS, MARCA Y BARRA DE ESTADO OS ---
	_build_top_bezel_strip(chrome_root)

	# --- 3. BISEL INFERIOR: CONTROLES BÁSICOS Y BOTONES DE NAVEGACIÓN (NO FUNCIONALES) ---
	_build_bottom_control_bar(chrome_root)

func _build_top_bezel_strip(parent: Control) -> void:
	# Lente cámara frontal + sensor + 2 LEDs de estado hardware
	_add_round_lens(parent, "FrontCameraOuter", Vector2(416, 20), 20, Color(0.04, 0.045, 0.06), Color(0.32, 0.38, 0.46))
	_add_round_lens(parent, "FrontCameraGlass", Vector2(420, 24), 12, Color(0.05, 0.16, 0.28), Color(0.25, 0.68, 0.92))
	_add_round_lens(parent, "AmbientSensor", Vector2(444, 26), 8, Color(0.04, 0.05, 0.07), Color(0.18, 0.22, 0.28))
	_add_round_lens(parent, "LedPower", Vector2(226, 26), 8, Color(0.16, 0.95, 0.42), Color(0.45, 1.0, 0.65))
	_add_silkscreen(parent, "RUN", Vector2(238, 22), 9, Color(0.58, 0.78, 0.66))
	_add_round_lens(parent, "LedLink", Vector2(272, 26), 8, Color(0.18, 0.72, 1.0), Color(0.50, 0.88, 1.0))
	_add_silkscreen(parent, "LINK", Vector2(284, 22), 9, Color(0.58, 0.68, 0.78))

	# Placa frontal de identificación de tablet
	var brand := Label.new()
	brand.name = "TabletBrandLabel"
	brand.position = Vector2(474, 19)
	brand.size = Vector2(372, 22)
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	brand.text = "AGROMOLINOS  RUGGED-PAD 10X  •  SCADA HMI"
	brand.add_theme_font_size_override("font_size", 11)
	brand.add_theme_color_override("font_color", Color(0.76, 0.83, 0.92, 0.92))
	brand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(brand)

	# Barra de estado básica del sistema operativo de tablet (decorativa, no funcional)
	var status_pill := PanelContainer.new()
	status_pill.name = "DecorativeStatusPill"
	status_pill.position = Vector2(898, 17)
	status_pill.size = Vector2(342, 26)
	status_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill_sb := StyleBoxFlat.new()
	pill_sb.bg_color = Color(0.055, 0.068, 0.09, 0.92)
	pill_sb.border_color = Color(0.22, 0.28, 0.36, 0.9)
	pill_sb.set_border_width_all(1)
	pill_sb.set_corner_radius_all(6)
	pill_sb.set_content_margin_all(4)
	status_pill.add_theme_stylebox_override("panel", pill_sb)
	parent.add_child(status_pill)

	var st_hbox := HBoxContainer.new()
	st_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	st_hbox.add_theme_constant_override("separation", 12)
	st_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_pill.add_child(st_hbox)

	for item in [
		{"text": "Wi-Fi", "color": Color(0.32, 0.88, 1.0)},
		{"text": "5G", "color": Color(0.42, 0.95, 0.62)},
		{"text": "BT", "color": Color(0.55, 0.78, 1.0)},
		{"text": "14:28", "color": Color(0.86, 0.90, 0.96)},
		{"text": "BAT 94%", "color": Color(0.38, 0.96, 0.56)},
	]:
		var lbl := Label.new()
		lbl.text = item["text"]
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", item["color"])
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		st_hbox.add_child(lbl)

func _build_bottom_control_bar(parent: Control) -> void:
	var bar_hbox := HBoxContainer.new()
	bar_hbox.name = "BottomTabletControls"
	bar_hbox.position = Vector2(76, 768)
	bar_hbox.size = Vector2(1168, 42)
	bar_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bar_hbox.add_theme_constant_override("separation", 14)
	bar_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bar_hbox)

	# Controles básicos izquierda (Brillo y Audio - puramente gráficos)
	var left_specs := [
		{"name": "CtrlBrightDown", "label": "LUZ -", "accent": Color(0.28, 0.34, 0.42), "w": 68.0},
		{"name": "CtrlBrightUp", "label": "LUZ +", "accent": Color(0.28, 0.34, 0.42), "w": 68.0},
		{"name": "CtrlVolDown", "label": "VOL -", "accent": Color(0.28, 0.34, 0.42), "w": 72.0},
		{"name": "CtrlVolUp", "label": "VOL +", "accent": Color(0.28, 0.34, 0.42), "w": 72.0},
	]
	for spec in left_specs:
		bar_hbox.add_child(_make_non_functional_keycap(spec["name"], spec["label"], spec["w"], spec["accent"], false))

	var sp1 := Control.new()
	sp1.custom_minimum_size = Vector2(24, 1)
	sp1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_hbox.add_child(sp1)

	# Controles centrales de navegación de tablet (Atrás / Inicio / Apps - puramente gráficos)
	var nav_specs := [
		{"name": "CtrlNavBack", "label": "◀  ATRÁS", "accent": Color(0.32, 0.44, 0.56), "w": 106.0, "home": false},
		{"name": "CtrlNavHome", "label": "◉  INICIO", "accent": Color(0.20, 0.72, 0.96), "w": 124.0, "home": true},
		{"name": "CtrlNavApps", "label": "▢  APPS", "accent": Color(0.32, 0.44, 0.56), "w": 106.0, "home": false},
	]
	for spec in nav_specs:
		bar_hbox.add_child(_make_non_functional_keycap(spec["name"], spec["label"], spec["w"], spec["accent"], spec["home"]))

	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(24, 1)
	sp2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_hbox.add_child(sp2)

	# Controles básicos derecha (Red / Cámara / Bloqueo / Ajustes - puramente gráficos)
	var right_specs := [
		{"name": "CtrlQuickNet", "label": "RED", "accent": Color(0.28, 0.34, 0.42), "w": 68.0},
		{"name": "CtrlQuickCam", "label": "FOTO", "accent": Color(0.28, 0.34, 0.42), "w": 68.0},
		{"name": "CtrlQuickLock", "label": "BLOQ", "accent": Color(0.45, 0.36, 0.22), "w": 72.0},
		{"name": "CtrlQuickSetup", "label": "AJUSTES", "accent": Color(0.28, 0.34, 0.42), "w": 84.0},
	]
	for spec in right_specs:
		bar_hbox.add_child(_make_non_functional_keycap(spec["name"], spec["label"], spec["w"], spec["accent"], false))

func _make_non_functional_keycap(node_name: String, text_label: String, width_px: float, border_col: Color, is_home: bool) -> PanelContainer:
	var cap := PanelContainer.new()
	cap.name = node_name
	cap.custom_minimum_size = Vector2(width_px, 34.0)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.focus_mode = Control.FOCUS_NONE

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.085, 0.10, 0.125, 1.0) if not is_home else Color(0.075, 0.12, 0.165, 1.0)
	sb.border_color = border_col
	sb.set_border_width_all(2 if is_home else 1)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(0, 2)
	cap.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.text = text_label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11 if is_home else 10)
	lbl.add_theme_color_override("font_color", Color(0.62, 0.88, 1.0, 0.92) if is_home else Color(0.72, 0.78, 0.86, 0.85))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.add_child(lbl)
	return cap

func _add_bezel_hw_key(parent: Control, node_name: String, rect: Rect2, bg: Color, border: Color) -> void:
	var key := Panel.new()
	key.name = node_name
	key.position = rect.position
	key.size = rect.size
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key.focus_mode = Control.FOCUS_NONE
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	key.add_theme_stylebox_override("panel", sb)
	parent.add_child(key)

func _add_round_lens(parent: Control, node_name: String, pos: Vector2, diameter: int, bg: Color, border: Color) -> void:
	var dot := Panel.new()
	dot.name = node_name
	dot.position = pos
	dot.size = Vector2(diameter, diameter)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.focus_mode = Control.FOCUS_NONE
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(int(diameter * 0.5))
	dot.add_theme_stylebox_override("panel", sb)
	parent.add_child(dot)

func _add_silkscreen(parent: Control, txt: String, pos: Vector2, fsize: int, col: Color) -> void:
	var lbl := Label.new()
	lbl.text = txt
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", fsize)
	lbl.add_theme_color_override("font_color", col)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)
