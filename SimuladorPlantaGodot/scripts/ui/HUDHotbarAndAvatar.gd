class_name HUDHotbarAndAvatar
extends Control

# ==============================================================================
# HOTBAR ESTILO MINECRAFT (5 SLOTS DE HERRAMIENTAS) + MODELO 3D DEL OPERARIO
# - Muestra las 5 herramientas con iconos vectoriales 2D nítidos y slot activo.
# - Al lado muestra el modelo 3D real descargado (trabajador_operario.glb) que
#   cambia de ropa en tiempo real al equipar o retirar el EPP en los lockers.
# - Rendimiento optimizado para iGPU (SubViewport aislado, sin sombras, throttle).
# ==============================================================================

const HumanGaitAnimatorScript = preload("res://scripts/interactive/HumanGaitAnimator.gd")
const OPERARIO_SCENE_PATH := "res://assets/models/trabajador_operario.glb"
const TEX_CIVIL_PATH := "res://assets/models/trabajador_operario_trabajador_operario_0.jpg"
const TEX_EPP_PATH := "res://assets/models/trabajador_logistica_trabajador_logistica_0.jpg"

const TOOL_SPECS: Array[Dictionary] = [
	{"id": 1, "short": "Manos", "full": "1 • Manos", "accent": Color(0.78, 0.88, 1.0, 1.0)},
	{"id": 2, "short": "Alicates", "full": "2 • Alicates", "accent": Color(1.0, 0.42, 0.34, 1.0)},
	{"id": 3, "short": "Llave 3/4\"", "full": "3 • Llave 3/4\"", "accent": Color(0.80, 0.86, 0.94, 1.0)},
	{"id": 4, "short": "Multímetro", "full": "4 • Multímetro", "accent": Color(1.0, 0.82, 0.22, 1.0)},
	{"id": 5, "short": "Kit LOTO", "full": "5 • Kit LOTO", "accent": Color(1.0, 0.26, 0.24, 1.0)}
]

var active_tool_id: int = 1
var epp_equipped: bool = false

var _lbl_tool_banner: Label = null
var _slot_views: Dictionary = {} # tool_id -> _ToolSlotIcon
var _avatar_card: PanelContainer = null
var _avatar_badge: PanelContainer = null
var _avatar_badge_lbl: Label = null
var _sub_vp: SubViewport = null
var _char_pivot: Node3D = null
var _char_model: Node3D = null
var _char_anim: AnimationPlayer = null
var _base_mat_cache: Dictionary = {} # instance_id -> Array[Material]

var _tex_civil: Texture2D = null
var _tex_epp: Texture2D = null
var _spin_timer: float = 0.0
var _idle_t: float = 0.0
var _render_accum: float = 0.0
var _base_yaw: float = PI + 0.28

func _ready() -> void:
	name = "HUDHotbarAndAvatar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -280.0
	offset_right = 280.0
	offset_top = -146.0
	offset_bottom = -12.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN

	if ResourceLoader.exists(TEX_CIVIL_PATH):
		_tex_civil = load(TEX_CIVIL_PATH) as Texture2D
	if ResourceLoader.exists(TEX_EPP_PATH):
		_tex_epp = load(TEX_EPP_PATH) as Texture2D

	_build_layout()
	set_active_tool(1, "1 • Manos")
	set_epp_equipped(false, false)

func _build_layout() -> void:
	var root_hbox := HBoxContainer.new()
	root_hbox.name = "HotbarDockHBox"
	root_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	root_hbox.add_theme_constant_override("separation", 12)
	root_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_hbox)

	# 1. Tarjeta 3D del Personaje (al lado izquierdo de la hotbar, estilo papel-doll de Minecraft)
	_build_avatar_card(root_hbox)

	# 2. Hotbar estilo Minecraft (5 slots + título herramienta activa encima)
	var hotbar_vb := VBoxContainer.new()
	hotbar_vb.name = "HotbarColumn"
	hotbar_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hotbar_vb.size_flags_vertical = Control.SIZE_SHRINK_END
	hotbar_vb.alignment = BoxContainer.ALIGNMENT_END
	hotbar_vb.add_theme_constant_override("separation", 5)
	root_hbox.add_child(hotbar_vb)

	var banner_panel := PanelContainer.new()
	banner_panel.name = "ActiveToolBanner"
	banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var b_st := StyleBoxFlat.new()
	b_st.bg_color = Color(0.05, 0.08, 0.13, 0.80)
	b_st.border_color = Color(1.0, 0.84, 0.28, 0.72)
	b_st.set_border_width_all(1)
	b_st.set_corner_radius_all(5)
	b_st.content_margin_left = 12.0
	b_st.content_margin_right = 12.0
	b_st.content_margin_top = 2.0
	b_st.content_margin_bottom = 2.0
	banner_panel.add_theme_stylebox_override("panel", b_st)
	hotbar_vb.add_child(banner_panel)

	_lbl_tool_banner = Label.new()
	_lbl_tool_banner.name = "LblHotbarActiveTool"
	_lbl_tool_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_tool_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_tool_banner.add_theme_font_size_override("font_size", 12)
	_lbl_tool_banner.add_theme_color_override("font_color", Color(1.0, 0.90, 0.42, 1.0))
	_lbl_tool_banner.text = "1 • Manos"
	banner_panel.add_child(_lbl_tool_banner)

	# Bandeja Minecraft exterior
	var tray := PanelContainer.new()
	tray.name = "MinecraftHotbarTray"
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tray_st := StyleBoxFlat.new()
	tray_st.bg_color = Color(0.04, 0.06, 0.10, 0.88)
	tray_st.border_color = Color(0.32, 0.44, 0.58, 0.85)
	tray_st.set_border_width_all(2)
	tray_st.set_corner_radius_all(6)
	tray_st.content_margin_left = 6.0
	tray_st.content_margin_right = 6.0
	tray_st.content_margin_top = 6.0
	tray_st.content_margin_bottom = 6.0
	tray.add_theme_stylebox_override("panel", tray_st)
	hotbar_vb.add_child(tray)

	var slots_hb := HBoxContainer.new()
	slots_hb.name = "SlotsHBox"
	slots_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slots_hb.add_theme_constant_override("separation", 5)
	tray.add_child(slots_hb)

	for spec in TOOL_SPECS:
		var tid: int = int(spec["id"])
		var slot := _ToolSlotIcon.new()
		slot.name = "HotbarSlot_%d" % tid
		slot.tool_id = tid
		slot.short_label = String(spec["short"])
		slot.accent_color = spec["accent"] as Color
		slot.custom_minimum_size = Vector2(68.0, 68.0)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slots_hb.add_child(slot)
		_slot_views[tid] = slot

func _build_avatar_card(parent_box: Container) -> void:
	_avatar_card = PanelContainer.new()
	_avatar_card.name = "CharacterEppAvatarCard"
	_avatar_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar_card.size_flags_vertical = Control.SIZE_SHRINK_END
	_avatar_card.custom_minimum_size = Vector2(106.0, 128.0)
	parent_box.add_child(_avatar_card)

	var card_vb := VBoxContainer.new()
	card_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_vb.add_theme_constant_override("separation", 3)
	_avatar_card.add_child(card_vb)

	var vp_holder := SubViewportContainer.new()
	vp_holder.name = "AvatarViewportContainer"
	vp_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp_holder.stretch = true
	vp_holder.custom_minimum_size = Vector2(94.0, 96.0)
	vp_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vp_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_vb.add_child(vp_holder)

	_sub_vp = SubViewport.new()
	_sub_vp.name = "AvatarSubViewport"
	_sub_vp.size = Vector2i(188, 192)
	_sub_vp.transparent_bg = true
	_sub_vp.own_world_3d = true
	_sub_vp.msaa_3d = Viewport.MSAA_DISABLED
	_sub_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED if DisplayServer.get_name() == "headless" else SubViewport.UPDATE_ONCE
	vp_holder.add_child(_sub_vp)

	_setup_avatar_3d_scene()

	_avatar_badge = PanelContainer.new()
	_avatar_badge.name = "EppStatusBadge"
	_avatar_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_vb.add_child(_avatar_badge)

	_avatar_badge_lbl = Label.new()
	_avatar_badge_lbl.name = "LblEppStatus"
	_avatar_badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar_badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_avatar_badge_lbl.add_theme_font_size_override("font_size", 10)
	_avatar_badge_lbl.text = "SIN EPP"
	_avatar_badge.add_child(_avatar_badge_lbl)

func _setup_avatar_3d_scene() -> void:
	if _sub_vp == null:
		return

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.08, 0.13, 0.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.82, 0.88, 0.96, 1.0)
	env.ambient_light_energy = 0.72
	var we := WorldEnvironment.new()
	we.environment = env
	_sub_vp.add_child(we)

	var key_light := DirectionalLight3D.new()
	key_light.light_energy = 1.15
	key_light.shadow_enabled = false
	key_light.rotation_degrees = Vector3(-28.0, 26.0, 0.0)
	_sub_vp.add_child(key_light)

	var rim_light := DirectionalLight3D.new()
	rim_light.light_color = Color(0.65, 0.85, 1.0, 1.0)
	rim_light.light_energy = 0.55
	rim_light.shadow_enabled = false
	rim_light.rotation_degrees = Vector3(-12.0, -145.0, 0.0)
	_sub_vp.add_child(rim_light)

	_char_pivot = Node3D.new()
	_char_pivot.name = "AvatarPivot"
	_char_pivot.rotation.y = _base_yaw
	_sub_vp.add_child(_char_pivot)

	if ResourceLoader.exists(OPERARIO_SCENE_PATH):
		var packed := load(OPERARIO_SCENE_PATH) as PackedScene
		if packed != null:
			_char_model = packed.instantiate() as Node3D
			if _char_model != null:
				_char_pivot.add_child(_char_model)
				_normalize_and_cache_avatar_model()

	var cam := Camera3D.new()
	cam.name = "AvatarCamera"
	cam.fov = 33.0
	cam.position = Vector3(0.0, 0.94, 3.05)
	cam.current = true
	_sub_vp.add_child(cam)
	cam.look_at(Vector3(0.0, 0.88, 0.0), Vector3.UP)

func _normalize_and_cache_avatar_model() -> void:
	if _char_model == null:
		return
	_char_anim = _char_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _char_anim != null:
		HumanGaitAnimatorScript.upgrade_animations(_char_anim, _char_model)
		if _char_anim.has_animation("idle"):
			_char_anim.play("idle")
			_char_anim.advance(0.15)

	# Medir AABB real del personaje para encuadrarlo de pies a cabeza (altura = 1.75 m)
	var has_b := false
	var box := AABB()
	_base_mat_cache.clear()
	for ch in _char_model.find_children("*", "MeshInstance3D", true, false):
		var mi := ch as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mb := mi.global_transform * mi.mesh.get_aabb()
		if not has_b:
			box = mb
			has_b = true
		else:
			box = box.merge(mb)
		var mats: Array[Material] = []
		for s in range(mi.mesh.get_surface_count()):
			var m := mi.get_active_material(s)
			mats.append(m.duplicate() if m != null else null)
		_base_mat_cache[mi.get_instance_id()] = mats

	if has_b and box.size.y > 0.05:
		var scale_f := 1.72 / box.size.y
		_char_model.scale = Vector3.ONE * scale_f
		var c := box.get_center()
		_char_model.position = Vector3(-c.x * scale_f, -box.position.y * scale_f, -c.z * scale_f)

func set_active_tool(tool_id: int, tool_name: String = "") -> void:
	active_tool_id = clampi(tool_id, 1, 5)
	for tid in _slot_views.keys():
		var sv := _slot_views[tid] as _ToolSlotIcon
		if sv != null:
			sv.is_selected = (int(tid) == active_tool_id)
			sv.queue_redraw()
	if _lbl_tool_banner != null:
		if tool_name != "":
			_lbl_tool_banner.text = tool_name
		else:
			for spec in TOOL_SPECS:
				if int(spec["id"]) == active_tool_id:
					_lbl_tool_banner.text = String(spec["full"])
					break

func set_epp_equipped(equipped: bool, play_spin: bool = true) -> void:
	var changed := (epp_equipped != equipped)
	epp_equipped = equipped

	# Actualizar estilo de tarjeta e insignia EPP
	if _avatar_card != null:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.05, 0.11, 0.09, 0.88) if equipped else Color(0.11, 0.06, 0.06, 0.88)
		st.border_color = Color(0.18, 0.94, 0.50, 0.95) if equipped else Color(0.95, 0.36, 0.24, 0.90)
		st.set_border_width_all(2)
		st.set_corner_radius_all(7)
		st.content_margin_left = 5.0
		st.content_margin_right = 5.0
		st.content_margin_top = 4.0
		st.content_margin_bottom = 4.0
		_avatar_card.add_theme_stylebox_override("panel", st)

	if _avatar_badge != null:
		var bst := StyleBoxFlat.new()
		bst.bg_color = Color(0.08, 0.42, 0.22, 0.95) if equipped else Color(0.45, 0.12, 0.10, 0.95)
		bst.set_corner_radius_all(4)
		bst.content_margin_left = 4.0
		bst.content_margin_right = 4.0
		bst.content_margin_top = 1.0
		bst.content_margin_bottom = 1.0
		_avatar_badge.add_theme_stylebox_override("panel", bst)

	if _avatar_badge_lbl != null:
		_avatar_badge_lbl.text = "EPP 6/6 OK" if equipped else "SIN EPP"
		_avatar_badge_lbl.add_theme_color_override(
			"font_color",
			Color(0.55, 1.0, 0.72, 1.0) if equipped else Color(1.0, 0.72, 0.62, 1.0)
		)

	_apply_avatar_outfit_material(equipped)
	if play_spin and changed:
		_spin_timer = 0.75
	_request_avatar_redraw()

func _apply_avatar_outfit_material(equipped: bool) -> void:
	if _char_model == null:
		return
	for ch in _char_model.find_children("*", "MeshInstance3D", true, false):
		var mi := ch as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var cached: Array = _base_mat_cache.get(mi.get_instance_id(), [])
		for s in range(mi.mesh.get_surface_count()):
			var base_m: Material = cached[s] if s < cached.size() else mi.mesh.surface_get_material(s)
			var std: StandardMaterial3D = null
			if base_m is StandardMaterial3D:
				std = (base_m as StandardMaterial3D).duplicate() as StandardMaterial3D
			else:
				std = StandardMaterial3D.new()
			if equipped:
				# Traje ignífugo naranja alta visibilidad RETIE + casco dieléctrico azul
				if _tex_epp != null:
					std.albedo_texture = _tex_epp
					std.albedo_color = Color(1.05, 1.02, 0.98, 1.0)
				else:
					std.albedo_color = Color(1.0, 0.68, 0.25, 1.0)
				std.roughness = 0.52
			else:
				# Ropa base de calle/taller sin EPP reglamentario
				if _tex_civil != null:
					std.albedo_texture = _tex_civil
				std.albedo_color = Color(0.76, 0.80, 0.88, 1.0)
				std.roughness = 0.75
			mi.set_surface_override_material(s, std)

func _request_avatar_redraw() -> void:
	if _sub_vp != null and DisplayServer.get_name() != "headless":
		_sub_vp.render_target_update_mode = SubViewport.UPDATE_ONCE

func _process(delta: float) -> void:
	if DisplayServer.get_name() == "headless" or _char_pivot == null:
		return
	_idle_t += delta
	if _spin_timer > 0.0:
		_spin_timer = maxf(0.0, _spin_timer - delta)
		var prog := 1.0 - (_spin_timer / 0.75)
		var eased := 1.0 - pow(1.0 - prog, 3.0)
		_char_pivot.rotation.y = _base_yaw + eased * TAU
		_request_avatar_redraw()
		return

	# Balanceo sutil estilo papel-doll a ~8 Hz para 0% impacto en FPS
	_render_accum += delta
	if _render_accum >= 0.125:
		_render_accum = 0.0
		_char_pivot.rotation.y = _base_yaw + sin(_idle_t * 1.4) * 0.14
		_request_avatar_redraw()


# ==============================================================================
# SUB-CLASE INTERNA: SLOT INDIVIDUAL ESTILO MINECRAFT CON ICONO VECTORIAL NÍTIDO
# ==============================================================================
class _ToolSlotIcon:
	extends Control

	var tool_id: int = 1
	var short_label: String = ""
	var accent_color: Color = Color.WHITE
	var is_selected: bool = false

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var bg := Color(0.14, 0.20, 0.28, 0.95) if is_selected else Color(0.07, 0.10, 0.15, 0.84)
		var border := Color(1.0, 0.86, 0.30, 1.0) if is_selected else Color(0.28, 0.38, 0.50, 0.68)
		var bw := 3.0 if is_selected else 1.5

		# Fondo estilo slot Minecraft con bisel interior sutil
		draw_rect(r, bg, true)
		if is_selected:
			draw_rect(r.grow(-3.0), Color(1.0, 0.86, 0.30, 0.14), true)
		draw_rect(r.grow(-bw * 0.5), border, false, bw)

		# Número de tecla (esquina superior izquierda)
		var font := ThemeDB.fallback_font
		var num_col := Color(1.0, 0.92, 0.42, 1.0) if is_selected else Color(0.70, 0.78, 0.86, 0.85)
		draw_string(font, Vector2(6.0, 14.0), str(tool_id), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, num_col)

		# Etiqueta corta inferior
		var lbl_col := Color(1.0, 0.98, 0.92, 1.0) if is_selected else Color(0.72, 0.80, 0.88, 0.82)
		draw_string(font, Vector2(2.0, size.y - 5.0), short_label, HORIZONTAL_ALIGNMENT_CENTER, size.x - 4.0, 10, lbl_col)

		# Icono vectorial centrado
		var c := Vector2(size.x * 0.5, size.y * 0.47)
		var scale_i := 1.08 if is_selected else 0.94
		match tool_id:
			1: _draw_icon_hands(c, scale_i)
			2: _draw_icon_pliers(c, scale_i)
			3: _draw_icon_wrench(c, scale_i)
			4: _draw_icon_multimeter(c, scale_i)
			5: _draw_icon_loto(c, scale_i)

	func _draw_icon_hands(c: Vector2, sc: float) -> void:
		var skin := Color(0.92, 0.86, 0.78, 1.0) if is_selected else Color(0.76, 0.74, 0.72, 0.90)
		var rim := Color(0.18, 0.24, 0.32, 0.95)
		# Palma
		var palm := Rect2(c + Vector2(-9.0, -3.0) * sc, Vector2(18.0, 14.0) * sc)
		draw_rect(palm, skin, true)
		draw_rect(palm, rim, false, 1.3)
		# 4 dedos arriba
		for fi in range(4):
			var fx := (-7.5 + float(fi) * 4.6) * sc
			var fh := (11.0 if (fi == 1 or fi == 2) else 9.0) * sc
			var fr := Rect2(c + Vector2(fx, -3.0 * sc - fh), Vector2(3.4 * sc, fh + 1.0))
			draw_rect(fr, skin, true)
			draw_rect(fr, rim, false, 1.1)
		# Pulgar izquierdo
		draw_line(c + Vector2(-9.0, 4.0) * sc, c + Vector2(-14.0, -2.0) * sc, skin, 3.6 * sc, true)

	func _draw_icon_pliers(c: Vector2, sc: float) -> void:
		var grip := Color(0.95, 0.24, 0.20, 1.0) if is_selected else Color(0.80, 0.25, 0.22, 0.90)
		var steel := Color(0.82, 0.88, 0.95, 1.0)
		# Mangos aislados rojos (en V hacia abajo)
		draw_line(c + Vector2(-2.0, 1.0) * sc, c + Vector2(-11.0, 14.0) * sc, grip, 4.2 * sc, true)
		draw_line(c + Vector2(2.0, 1.0) * sc, c + Vector2(11.0, 14.0) * sc, grip, 4.2 * sc, true)
		# Mordazas de acero cruzadas hacia arriba
		draw_line(c + Vector2(-2.0, 1.0) * sc, c + Vector2(5.5, -13.0) * sc, steel, 3.4 * sc, true)
		draw_line(c + Vector2(2.0, 1.0) * sc, c + Vector2(-5.5, -13.0) * sc, steel, 3.4 * sc, true)
		# Pivote central
		draw_circle(c + Vector2(0.0, 0.0), 3.2 * sc, Color(0.28, 0.34, 0.42, 1.0))
		draw_circle(c + Vector2(0.0, 0.0), 1.6 * sc, steel)

	func _draw_icon_wrench(c: Vector2, sc: float) -> void:
		var steel := Color(0.86, 0.91, 0.97, 1.0) if is_selected else Color(0.72, 0.78, 0.86, 0.92)
		var dark := Color(0.16, 0.22, 0.30, 1.0)
		# Mango diagonal 45°
		draw_line(c + Vector2(-11.0, 11.0) * sc, c + Vector2(7.0, -7.0) * sc, steel, 5.4 * sc, true)
		# Cabeza abierta superior derecha (boca llave 3/4")
		draw_circle(c + Vector2(9.0, -9.0) * sc, 7.2 * sc, steel)
		draw_line(c + Vector2(9.0, -9.0) * sc, c + Vector2(14.5, -14.5) * sc, dark, 5.2 * sc, true)
		# Anillo inferior izquierdo
		draw_circle(c + Vector2(-11.5, 11.5) * sc, 4.6 * sc, steel)
		draw_circle(c + Vector2(-11.5, 11.5) * sc, 2.0 * sc, dark)

	func _draw_icon_multimeter(c: Vector2, sc: float) -> void:
		var body_col := Color(1.0, 0.78, 0.14, 1.0) if is_selected else Color(0.86, 0.66, 0.14, 0.92)
		var lcd_col := Color(0.70, 0.88, 0.76, 1.0)
		var dark := Color(0.12, 0.16, 0.22, 1.0)
		var body := Rect2(c + Vector2(-10.0, -14.0) * sc, Vector2(20.0, 27.0) * sc)
		draw_rect(body, body_col, true)
		draw_rect(body, dark, false, 1.5)
		# Pantalla LCD
		var lcd := Rect2(c + Vector2(-7.5, -11.5) * sc, Vector2(15.0, 8.0) * sc)
		draw_rect(lcd, lcd_col, true)
		draw_rect(lcd, dark, false, 1.0)
		# Dial rotatorio
		draw_circle(c + Vector2(0.0, 3.0) * sc, 5.2 * sc, dark)
		draw_line(c + Vector2(-2.5, 5.0) * sc, c + Vector2(3.0, 0.5) * sc, Color(1.0, 0.92, 0.45, 1.0), 1.8 * sc, true)
		# Bornes rojo y negro
		draw_circle(c + Vector2(-5.0, 10.5) * sc, 1.6 * sc, Color(0.95, 0.2, 0.18, 1.0))
		draw_circle(c + Vector2(5.0, 10.5) * sc, 1.6 * sc, dark)

	func _draw_icon_loto(c: Vector2, sc: float) -> void:
		var red := Color(0.96, 0.18, 0.16, 1.0) if is_selected else Color(0.82, 0.20, 0.18, 0.92)
		var steel := Color(0.85, 0.90, 0.96, 1.0)
		var gold := Color(1.0, 0.86, 0.22, 1.0)
		# Arco metálico del candado
		draw_arc(c + Vector2(0.0, -5.0) * sc, 6.8 * sc, PI, TAU, 16, steel, 2.8 * sc, true)
		draw_line(c + Vector2(-6.8, -5.0) * sc, c + Vector2(-6.8, 0.0) * sc, steel, 2.8 * sc, true)
		draw_line(c + Vector2(6.8, -5.0) * sc, c + Vector2(6.8, 0.0) * sc, steel, 2.8 * sc, true)
		# Cuerpo rojo del candado LOTO
		var body := Rect2(c + Vector2(-10.0, -1.0) * sc, Vector2(20.0, 15.0) * sc)
		draw_rect(body, red, true)
		draw_rect(body, Color(0.25, 0.04, 0.04, 1.0), false, 1.5)
		# Franja de advertencia amarilla + cerradura
		draw_rect(Rect2(c + Vector2(-8.0, 3.0) * sc, Vector2(16.0, 3.2) * sc), gold, true)
		draw_circle(c + Vector2(0.0, 9.5) * sc, 2.0 * sc, Color(0.12, 0.04, 0.04, 1.0))
