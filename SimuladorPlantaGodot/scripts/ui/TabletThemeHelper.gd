class_name TabletThemeHelper
extends RefCounted

## Paleta Dark SCADA y fábrica compartida de estilos visuales idénticos al Lab 3.

const BG_SCREEN := Color(0.035, 0.051, 0.086, 1.0)     # #090d16
const BG_CARD := Color(0.059, 0.090, 0.165, 1.0)       # #0f172a
const BG_SUBCARD := Color(0.075, 0.114, 0.196, 1.0)    # #131d32
const BG_PLOT := Color(0.043, 0.067, 0.118, 1.0)       # #0b111e
const BG_INPUT := Color(0.050, 0.078, 0.145, 1.0)
const BORDER_SUBTLE := Color(0.118, 0.173, 0.275, 1.0) # #1e2c46
const BORDER_ACTIVE := Color(0.220, 0.741, 0.973, 1.0) # #38bdf8

const TEXT_WHITE := Color(0.945, 0.961, 0.980, 1.0)    # #f1f5f9
const TEXT_MUTED := Color(0.580, 0.639, 0.722, 1.0)    # #94a3b8
const ACCENT_CYAN := Color(0.220, 0.741, 0.973, 1.0)   # #38bdf8
const ACCENT_EMERALD := Color(0.063, 0.725, 0.506, 1.0)# #10b981
const ACCENT_AMBER := Color(0.961, 0.620, 0.043, 1.0)  # #f59e0b
const ACCENT_RED := Color(0.937, 0.267, 0.267, 1.0)    # #ef4444
const ACCENT_BLUE := Color(0.145, 0.388, 0.922, 1.0)   # #2563eb

static func make_panel_style(
	bg: Color = BG_CARD,
	border: Color = BORDER_SUBTLE,
	radius: int = 8,
	pad_x: int = 12,
	pad_y: int = 10,
	border_w: int = 1
) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y
	return sb

static func make_left_stripe_card(stripe_col: Color, bg: Color = BG_SUBCARD) -> StyleBoxFlat:
	var sb := make_panel_style(bg, BORDER_SUBTLE, 6, 12, 8, 1)
	sb.border_width_left = 4
	sb.border_color = stripe_col
	return sb

static func make_pill_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(12)
	sb.anti_aliasing = true
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	return sb

static func make_button_style(bg: Color, border: Color, radius: int = 6, pad_x: int = 10, pad_y: int = 5) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y
	return sb

static func apply_btn_colors(btn: Button, normal_bg: Color, border: Color, txt_col: Color = TEXT_WHITE) -> void:
	btn.add_theme_stylebox_override("normal", make_button_style(normal_bg, border))
	btn.add_theme_stylebox_override("hover", make_button_style(normal_bg.lightened(0.10), border.lightened(0.15)))
	btn.add_theme_stylebox_override("pressed", make_button_style(normal_bg.darkened(0.12), border))
	btn.add_theme_stylebox_override("focus", make_button_style(normal_bg, border))
	btn.add_theme_color_override("font_color", txt_col)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", txt_col)

static func apply_tab_style(btn: Button, active: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.16, 0.28, 0.95) if active else Color(0.0, 0.0, 0.0, 0.0)
	sb.border_color = ACCENT_CYAN if active else Color(0, 0, 0, 0)
	sb.border_width_bottom = 2 if active else 0
	sb.set_corner_radius_all(6)
	sb.anti_aliasing = true
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	btn.add_theme_stylebox_override("normal", sb)
	var hover := sb.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.11, 0.19, 0.32, 0.80)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", sb)
	btn.add_theme_color_override("font_color", Color.WHITE if active else TEXT_MUTED)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)

static func make_label(text_str: String, fsize: int = 12, col: Color = TEXT_WHITE, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var lbl := Label.new()
	lbl.text = text_str
	lbl.add_theme_font_size_override("font_size", fsize)
	lbl.add_theme_color_override("font_color", col)
	lbl.horizontal_alignment = align
	return lbl

static func create_kpi_tile(title_str: String, init_val: String, init_badge: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", make_panel_style(BG_SUBCARD, BORDER_SUBTLE, 6, 10, 8, 1))

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 3)
	panel.add_child(vb)

	var lbl_title := make_label(title_str, 10, TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	lbl_title.clip_text = true
	vb.add_child(lbl_title)

	var lbl_val := make_label(init_val, 18, ACCENT_CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	lbl_val.clip_text = true
	vb.add_child(lbl_val)

	var badge_wrap := PanelContainer.new()
	badge_wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge_wrap.add_theme_stylebox_override("panel", make_pill_style(Color(0.04, 0.25, 0.16, 0.9), ACCENT_EMERALD))
	vb.add_child(badge_wrap)

	var lbl_badge := make_label(init_badge, 10, Color(0.55, 0.98, 0.78), HORIZONTAL_ALIGNMENT_CENTER)
	lbl_badge.clip_text = false
	badge_wrap.add_child(lbl_badge)

	return {"panel": panel, "value": lbl_val, "badge": lbl_badge, "badge_panel": badge_wrap}

static func set_badge_state(badge_panel: PanelContainer, badge_lbl: Label, txt: String, level: String) -> void:
	if badge_lbl != null:
		badge_lbl.text = txt
	var bg := Color(0.04, 0.25, 0.16, 0.9)
	var bd := ACCENT_EMERALD
	var fg := Color(0.55, 0.98, 0.78)
	if level == "WARNING":
		bg = Color(0.32, 0.20, 0.03, 0.92)
		bd = ACCENT_AMBER
		fg = Color(1.0, 0.85, 0.45)
	elif level == "CRITICAL":
		bg = Color(0.35, 0.07, 0.08, 0.95)
		bd = ACCENT_RED
		fg = Color(1.0, 0.65, 0.65)
	if badge_panel != null:
		badge_panel.add_theme_stylebox_override("panel", make_pill_style(bg, bd))
	if badge_lbl != null:
		badge_lbl.add_theme_color_override("font_color", fg)
