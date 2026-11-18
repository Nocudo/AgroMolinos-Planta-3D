class_name TabletSecondaryTabsBuilder
extends RefCounted

## Constructores modulares minimalistas para las pestañas 3..8 de la Tablet Industrial.

const TTheme = preload("res://scripts/ui/TabletThemeHelper.gd")
const TCatalog = preload("res://scripts/ui/TabletDataCatalog.gd")
const TCanvases = preload("res://scripts/ui/TabletAnalyticalCanvases.gd")

static func make_scroll_page(page_name: String) -> Dictionary:
	var scroll := ScrollContainer.new()
	scroll.name = page_name
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	scroll.add_child(vb)
	return {"root": scroll, "vbox": vb}

static func build_retie_tab() -> Dictionary:
	var pg := make_scroll_page("TabNormativaRETIE")
	var vb: VBoxContainer = pg["vbox"]

	var rules_card := PanelContainer.new()
	rules_card.add_theme_stylebox_override("panel", TTheme.make_panel_style(TTheme.BG_CARD, TTheme.BORDER_SUBTLE, 8, 12, 10))
	vb.add_child(rules_card)

	var r_vb := VBoxContainer.new()
	r_vb.add_theme_constant_override("separation", 6)
	rules_card.add_child(r_vb)
	r_vb.add_child(TTheme.make_label("5 Reglas de Oro RETIE", 13, TTheme.ACCENT_CYAN))

	var rule_badges: Array[Dictionary] = []
	for rule_data in [
		{"n": 1, "t": "1. Corte visible", "d": "Abrir breaker en CCM 460 V."},
		{"n": 2, "t": "2. Bloqueo LOTO", "d": "Asegurar con Kit LOTO."},
		{"n": 3, "t": "3. Ausencia de tensión", "d": "Verificar 0 V con multímetro."},
		{"n": 4, "t": "4. Puesta a tierra", "d": "Conectar tierra temporal."},
		{"n": 5, "t": "5. Señalización", "d": "Mantener perímetro despejado."}
	]:
		var row_card := PanelContainer.new()
		row_card.add_theme_stylebox_override("panel", TTheme.make_left_stripe_card(TTheme.ACCENT_CYAN))
		r_vb.add_child(row_card)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		row_card.add_child(hb)
		var txt_vb := VBoxContainer.new()
		txt_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		txt_vb.add_theme_constant_override("separation", 2)
		hb.add_child(txt_vb)
		txt_vb.add_child(TTheme.make_label(rule_data["t"], 11, TTheme.TEXT_WHITE))
		var dl := TTheme.make_label(rule_data["d"], 10, TTheme.TEXT_MUTED)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		txt_vb.add_child(dl)

		var pill := PanelContainer.new()
		pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pill.add_theme_stylebox_override("panel", TTheme.make_pill_style(Color(0.28, 0.18, 0.04, 0.9), TTheme.ACCENT_AMBER))
		hb.add_child(pill)
		var plbl := TTheme.make_label("Pendiente", 10, Color(1.0, 0.85, 0.45), HORIZONTAL_ALIGNMENT_CENTER)
		pill.add_child(plbl)
		rule_badges.append({"panel": pill, "label": plbl})

	var grid3 := HBoxContainer.new()
	grid3.add_theme_constant_override("separation", 10)
	vb.add_child(grid3)

	var epp_live_lbl := TTheme.make_label("EPP: 0 / 6", 11, TTheme.ACCENT_AMBER)
	for info in [
		{
			"title": "Motor 10 HP",
			"items": "7.46 kW · 460 V · 13.5 A\nClase F · 1750 RPM\nVibración <= 2.3 mm/s"
		},
		{
			"title": "Tablero CCM y VFD",
			"items": "Arranque suave VFD\nDespeje mínimo 1.0 m\nParada desde tablet"
		},
		{
			"title": "Protección EPP",
			"items": "6 prendas obligatorias\nRespetar líneas de seguridad"
		}
	]:
		var c := PanelContainer.new()
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.add_theme_stylebox_override("panel", TTheme.make_panel_style())
		grid3.add_child(c)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 4)
		c.add_child(cv)
		cv.add_child(TTheme.make_label(info["title"], 12, TTheme.ACCENT_CYAN))
		var body := TTheme.make_label(info["items"], 10, TTheme.TEXT_MUTED)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(body)
		if str(info["title"]).begins_with("Protección"):
			epp_live_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cv.add_child(epp_live_lbl)

	var tbl_card := PanelContainer.new()
	tbl_card.add_theme_stylebox_override("panel", TTheme.make_panel_style())
	vb.add_child(tbl_card)
	var tbl_vb := VBoxContainer.new()
	tbl_vb.add_theme_constant_override("separation", 5)
	tbl_card.add_child(tbl_vb)
	tbl_vb.add_child(TTheme.make_label("Riesgos Eléctricos RETIE", 12, TTheme.ACCENT_CYAN))
	for row in TCatalog.TABLE1_RETIE:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		tbl_vb.add_child(hb)
		var l1 := TTheme.make_label(row["factor"], 10, TTheme.ACCENT_AMBER)
		l1.custom_minimum_size.x = 160
		l1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var l2 := TTheme.make_label(row["cause"], 10, TTheme.TEXT_WHITE)
		l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var l3 := TTheme.make_label(row["control"], 10, Color(0.55, 0.95, 0.72))
		l3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l3.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hb.add_child(l1)
		hb.add_child(l2)
		hb.add_child(l3)

	return {"root": pg["root"], "rule_badges": rule_badges, "epp_live_lbl": epp_live_lbl}

static func build_workers_tab(on_register_cb: Callable, on_clear_cb: Callable) -> Dictionary:
	var hbox := HBoxContainer.new()
	hbox.name = "TabOperarios"
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 12)

	var left_card := PanelContainer.new()
	left_card.custom_minimum_size.x = 410
	left_card.add_theme_stylebox_override("panel", TTheme.make_panel_style())
	hbox.add_child(left_card)

	var l_vb := VBoxContainer.new()
	l_vb.add_theme_constant_override("separation", 8)
	left_card.add_child(l_vb)

	l_vb.add_child(TTheme.make_label("Registro de Turno", 13, TTheme.ACCENT_CYAN))

	var player_box := PanelContainer.new()
	player_box.add_theme_stylebox_override("panel", TTheme.make_left_stripe_card(TTheme.ACCENT_EMERALD))
	l_vb.add_child(player_box)
	var player_lbl := TTheme.make_label("Estación 1 · EPP pendiente · Nota 5.0", 11, TTheme.TEXT_WHITE)
	player_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	player_box.add_child(player_lbl)

	var inp_name := LineEdit.new()
	inp_name.placeholder_text = "Nombres"
	_style_line_edit(inp_name)
	var inp_last := LineEdit.new()
	inp_last.placeholder_text = "Apellidos"
	_style_line_edit(inp_last)

	var row_meta := HBoxContainer.new()
	row_meta.add_theme_constant_override("separation", 8)
	var inp_age := LineEdit.new()
	inp_age.placeholder_text = "Edad"
	inp_age.custom_minimum_size.x = 95
	_style_line_edit(inp_age)
	var opt_rh := OptionButton.new()
	opt_rh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for rh in ["O+", "O-", "A+", "A-", "B+", "B-", "AB+", "AB-"]:
		opt_rh.add_item("RH " + rh)
	_style_option_btn(opt_rh)
	row_meta.add_child(inp_age)
	row_meta.add_child(opt_rh)

	var opt_role := OptionButton.new()
	for r in ["Operario de Planta", "Técnico Electromecánico", "Supervisor SST", "Ingeniero de Control"]:
		opt_role.add_item(r)
	_style_option_btn(opt_role)

	l_vb.add_child(inp_name)
	l_vb.add_child(inp_last)
	l_vb.add_child(row_meta)
	l_vb.add_child(opt_role)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	l_vb.add_child(btn_row)
	var btn_reg := Button.new()
	btn_reg.text = "Registrar"
	TTheme.apply_btn_colors(btn_reg, TTheme.ACCENT_BLUE, TTheme.ACCENT_CYAN)
	btn_reg.pressed.connect(func(): on_register_cb.call(inp_name.text, inp_last.text, inp_age.text, opt_rh.get_item_text(opt_rh.selected), opt_role.get_item_text(opt_role.selected)); inp_name.text = ""; inp_last.text = ""; inp_age.text = "")
	var btn_clear := Button.new()
	btn_clear.text = "Limpiar"
	TTheme.apply_btn_colors(btn_clear, Color(0.55, 0.25, 0.04), TTheme.ACCENT_AMBER)
	btn_clear.pressed.connect(on_clear_cb)
	btn_row.add_child(btn_reg)
	btn_row.add_child(btn_clear)

	var right_card := PanelContainer.new()
	right_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_card.add_theme_stylebox_override("panel", TTheme.make_panel_style())
	hbox.add_child(right_card)

	var r_vb := VBoxContainer.new()
	r_vb.add_theme_constant_override("separation", 6)
	right_card.add_child(r_vb)

	r_vb.add_child(TTheme.make_label("Personal en Planta", 13, TTheme.ACCENT_CYAN))

	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	r_vb.add_child(sc)

	var list_vb := VBoxContainer.new()
	list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vb.add_theme_constant_override("separation", 6)
	sc.add_child(list_vb)

	var worker_cards: Dictionary = {}
	for w in TCatalog.PLANT_WORKERS_SPEC:
		var wc := PanelContainer.new()
		wc.add_theme_stylebox_override("panel", TTheme.make_panel_style(TTheme.BG_SUBCARD, TTheme.BORDER_SUBTLE, 6, 10, 7))
		list_vb.add_child(wc)
		var wvb := VBoxContainer.new()
		wvb.add_theme_constant_override("separation", 2)
		wc.add_child(wvb)
		var top_w := HBoxContainer.new()
		wvb.add_child(top_w)
		var n_lbl := TTheme.make_label("%s · %s" % [w["name"], w["role"]], 11, TTheme.TEXT_WHITE)
		n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n_lbl.clip_text = true
		top_w.add_child(n_lbl)
		top_w.add_child(TTheme.make_label("RH %s" % w["rh"], 10, TTheme.ACCENT_EMERALD))

		var loc_lbl := TTheme.make_label(w["station"], 10, TTheme.TEXT_MUTED)
		loc_lbl.clip_text = true
		wvb.add_child(loc_lbl)
		worker_cards[w["id"]] = loc_lbl

	r_vb.add_child(TTheme.make_label("Personal Adicional", 11, TTheme.ACCENT_CYAN))
	var custom_list := VBoxContainer.new()
	custom_list.add_theme_constant_override("separation", 4)
	r_vb.add_child(custom_list)
	var empty_lbl := TTheme.make_label("Sin registros adicionales.", 10, TTheme.TEXT_MUTED)
	custom_list.add_child(empty_lbl)

	return {"root": hbox, "player_lbl": player_lbl, "worker_cards": worker_cards, "custom_list": custom_list}

static func build_risks_tab() -> Dictionary:
	var outer := PanelContainer.new()
	outer.name = "TabRiesgos"
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_stylebox_override("panel", TTheme.make_panel_style())

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	outer.add_child(vb)

	vb.add_child(TTheme.make_label("Escenarios de Riesgo", 13, TTheme.ACCENT_CYAN))

	var sel_row := HBoxContainer.new()
	sel_row.add_theme_constant_override("separation", 14)
	vb.add_child(sel_row)

	var col_m := VBoxContainer.new()
	col_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_m.add_theme_constant_override("separation", 4)
	col_m.add_child(TTheme.make_label("Equipo", 11, TTheme.TEXT_MUTED))
	var opt_m := OptionButton.new()
	_style_option_btn(opt_m)
	for m in TCatalog.RISK_MACHINES:
		opt_m.add_item(m["label"])
	col_m.add_child(opt_m)
	sel_row.add_child(col_m)

	var col_f := VBoxContainer.new()
	col_f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_f.add_theme_constant_override("separation", 4)
	col_f.add_child(TTheme.make_label("Factor de riesgo", 11, TTheme.TEXT_MUTED))
	var opt_f := OptionButton.new()
	_style_option_btn(opt_f)
	for f in TCatalog.RISK_FACTORS:
		opt_f.add_item(f["label"])
	col_f.add_child(opt_f)
	sel_row.add_child(col_f)

	var scenario_card := PanelContainer.new()
	scenario_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scenario_card.add_theme_stylebox_override("panel", TTheme.make_panel_style(TTheme.BG_SUBCARD, TTheme.BORDER_SUBTLE, 8, 12, 12))
	vb.add_child(scenario_card)

	var svb := VBoxContainer.new()
	svb.add_theme_constant_override("separation", 10)
	scenario_card.add_child(svb)

	var lbl_head := TTheme.make_label("", 14, TTheme.TEXT_WHITE)
	lbl_head.clip_text = true
	svb.add_child(lbl_head)

	var cols3 := HBoxContainer.new()
	cols3.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols3.add_theme_constant_override("separation", 12)
	svb.add_child(cols3)

	var lbl_c1 := _make_risk_col(cols3, "Causas", TTheme.ACCENT_AMBER)
	var lbl_c2 := _make_risk_col(cols3, "Consecuencias", TTheme.ACCENT_RED)
	var lbl_c3 := _make_risk_col(cols3, "Prevención", TTheme.ACCENT_EMERALD)

	var refresh_cb := func(_idx: int = 0):
		var m_spec: Dictionary = TCatalog.RISK_MACHINES[opt_m.selected]
		var f_spec: Dictionary = TCatalog.RISK_FACTORS[opt_f.selected]
		var sc: Dictionary = TCatalog.get_risk_scenario(m_spec["id"], f_spec["id"])
		lbl_head.text = "%s · %s" % [m_spec["label"], f_spec["label"]]
		lbl_c1.text = sc["causes"]
		lbl_c2.text = sc["consequences"]
		lbl_c3.text = sc["mitigation"]

	opt_m.item_selected.connect(refresh_cb)
	opt_f.item_selected.connect(refresh_cb)
	refresh_cb.call(0)
	return {"root": outer}

static func _make_risk_col(parent: HBoxContainer, title_txt: String, col: Color) -> Label:
	var c := PanelContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.add_theme_stylebox_override("panel", TTheme.make_left_stripe_card(col, TTheme.BG_CARD))
	parent.add_child(c)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	c.add_child(vb)
	vb.add_child(TTheme.make_label(title_txt, 13, col))
	var body := TTheme.make_label("", 12, Color(0.88, 0.92, 0.97))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_constant_override("line_spacing", 5)
	vb.add_child(body)
	return body

static func build_physiology_tab() -> Dictionary:
	var outer := PanelContainer.new()
	outer.name = "TabFisiologia"
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_stylebox_override("panel", TTheme.make_panel_style())

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	outer.add_child(vb)

	vb.add_child(TTheme.make_label("Fisiología Eléctrica IEC 60479-1", 13, TTheme.ACCENT_CYAN))

	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 14)
	vb.add_child(cols)

	var left_vb := VBoxContainer.new()
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vb.add_theme_constant_override("separation", 6)
	cols.add_child(left_vb)

	var lbl_ma := TTheme.make_label("Corriente: 25.0 mA", 11, TTheme.TEXT_WHITE)
	var sld_ma := HSlider.new()
	sld_ma.min_value = 0.2; sld_ma.max_value = 500.0; sld_ma.step = 0.2; sld_ma.value = 25.0
	var lbl_ms := TTheme.make_label("Exposición: 500 ms", 11, TTheme.TEXT_WHITE)
	var sld_ms := HSlider.new()
	sld_ms.min_value = 10.0; sld_ms.max_value = 5000.0; sld_ms.step = 10.0; sld_ms.value = 500.0

	left_vb.add_child(lbl_ma)
	left_vb.add_child(sld_ma)
	left_vb.add_child(lbl_ms)
	left_vb.add_child(sld_ms)

	var pre_row := HBoxContainer.new()
	pre_row.add_theme_constant_override("separation", 6)
	left_vb.add_child(pre_row)
	for pr in [
		{"txt": "0.3 mA", "ma": 0.3, "ms": 800.0, "bg": Color(0.06, 0.45, 0.28)},
		{"txt": "5 mA", "ma": 5.0, "ms": 600.0, "bg": Color(0.08, 0.32, 0.58)},
		{"txt": "25 mA", "ma": 25.0, "ms": 500.0, "bg": Color(0.55, 0.32, 0.04)},
		{"txt": "120 mA", "ma": 120.0, "ms": 500.0, "bg": Color(0.62, 0.14, 0.14)},
		{"txt": "460 V", "ma": 460.0, "ms": 200.0, "bg": Color(0.45, 0.08, 0.22)}
	]:
		var b := Button.new()
		b.text = pr["txt"]
		b.add_theme_font_size_override("font_size", 10)
		TTheme.apply_btn_colors(b, pr["bg"], TTheme.BORDER_SUBTLE)
		b.pressed.connect(func(): sld_ma.value = pr["ma"]; sld_ms.value = pr["ms"])
		pre_row.add_child(b)

	var diag_card := PanelContainer.new()
	diag_card.add_theme_stylebox_override("panel", TTheme.make_left_stripe_card(TTheme.ACCENT_AMBER))
	left_vb.add_child(diag_card)
	var diag_vb := VBoxContainer.new()
	diag_vb.add_theme_constant_override("separation", 4)
	diag_card.add_child(diag_vb)
	var lbl_zone := TTheme.make_label("AC-3: Tetanización muscular", 12, TTheme.ACCENT_AMBER)
	var lbl_desc := TTheme.make_label("", 10, TTheme.TEXT_WHITE)
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var lbl_joule := TTheme.make_label("", 10, TTheme.ACCENT_CYAN)
	diag_vb.add_child(lbl_zone)
	diag_vb.add_child(lbl_desc)
	diag_vb.add_child(lbl_joule)

	var eff_cards: Array[PanelContainer] = []
	var eff_labels: Array[Label] = []
	var eff_pcts: Array[Label] = []
	for eff_name in ["Percepción", "Tetanización", "Paro respiratorio", "Fibrilación", "Quemadura"]:
		var ec := PanelContainer.new()
		ec.name = "EffCard_" + eff_name.replace(" ", "_")
		ec.add_theme_stylebox_override("panel", TTheme.make_panel_style(TTheme.BG_SUBCARD, TTheme.BORDER_SUBTLE, 5, 8, 5))
		left_vb.add_child(ec)
		var ehb := HBoxContainer.new()
		ehb.add_theme_constant_override("separation", 8)
		ec.add_child(ehb)
		var el := TTheme.make_label(eff_name, 10, TTheme.TEXT_WHITE)
		el.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ehb.add_child(el)
		var ep := TTheme.make_label("0%", 10, TTheme.ACCENT_EMERALD)
		ep.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ehb.add_child(ep)
		eff_cards.append(ec)
		eff_labels.append(el)
		eff_pcts.append(ep)

	var apply_eff_style := func(idx: int, title_prefix: String, state_txt: String, prob: float):
		var p := clampf(prob, 0.0, 1.0)
		var accent: Color
		var bg: Color
		if p < 0.10:
			accent = Color(0.10, 0.78, 0.52, 1.0)
			bg = Color(0.04, 0.14, 0.10, 0.92)
		elif p < 0.35:
			accent = Color(0.22, 0.74, 0.97, 1.0)
			bg = Color(0.05, 0.12, 0.19, 0.92)
		elif p < 0.60:
			accent = Color(0.96, 0.72, 0.14, 1.0)
			bg = Color(0.18, 0.13, 0.04, 0.92)
		elif p < 0.80:
			accent = Color(0.98, 0.46, 0.12, 1.0)
			bg = Color(0.20, 0.09, 0.04, 0.94)
		else:
			accent = Color(0.95, 0.25, 0.25, 1.0)
			bg = Color(0.22, 0.05, 0.06, 0.95)
		var st := StyleBoxFlat.new()
		st.bg_color = bg
		st.border_color = Color(accent.r, accent.g, accent.b, 0.85)
		st.border_width_left = 3
		st.border_width_top = 1
		st.border_width_right = 1
		st.border_width_bottom = 1
		st.set_corner_radius_all(5)
		st.content_margin_left = 8.0
		st.content_margin_right = 8.0
		st.content_margin_top = 4.0
		st.content_margin_bottom = 4.0
		eff_cards[idx].add_theme_stylebox_override("panel", st)
		eff_labels[idx].text = "%s: %s" % [title_prefix, state_txt]
		eff_labels[idx].add_theme_color_override("font_color", Color(0.94, 0.97, 1.0, 1.0))
		eff_pcts[idx].text = "%d%%" % int(round(p * 100.0))
		eff_pcts[idx].add_theme_color_override("font_color", accent)

	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 8)
	cols.add_child(right_vb)

	var chart := TCanvases.IEC60479ChartCanvas.new()
	chart.custom_minimum_size = Vector2(0, 290)
	chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_child(chart)

	var ztbl := PanelContainer.new()
	ztbl.add_theme_stylebox_override("panel", TTheme.make_panel_style(TTheme.BG_SUBCARD, TTheme.BORDER_SUBTLE, 6, 10, 8))
	right_vb.add_child(ztbl)
	var zvb := VBoxContainer.new()
	zvb.add_theme_constant_override("separation", 3)
	ztbl.add_child(zvb)
	zvb.add_child(TTheme.make_label("Zonas IEC 60479-1", 11, TTheme.ACCENT_CYAN))
	for zt in [
		"AC-1 · < 0.5 mA · Imperceptible",
		"AC-2 · 0.5 a 10 mA · Percepción leve",
		"AC-3 · 10 a 40 mA · Contracción muscular",
		"AC-4 · > 40 mA · Fibrilación ventricular"
	]:
		var l := TTheme.make_label(zt, 10, TTheme.TEXT_MUTED)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		zvb.add_child(l)

	var update_iec := func(_val: float = 0.0):
		var ma: float = float(sld_ma.value)
		var ms: float = float(sld_ms.value)
		lbl_ma.text = "Corriente: %.1f mA" % ma
		lbl_ms.text = "Exposición: %.0f ms" % ms
		chart.set_operating_point(ma, ms)
		var e_j: float = pow(ma / 1000.0, 2.0) * 1000.0 * (ms / 1000.0)
		lbl_joule.text = "Energía: %.4f J" % e_j

		if ma < 0.5:
			lbl_zone.text = "AC-1 · Imperceptible"
			lbl_zone.add_theme_color_override("font_color", TTheme.ACCENT_EMERALD)
			lbl_desc.text = "Por debajo del umbral de percepción."
			diag_card.add_theme_stylebox_override("panel", TTheme.make_left_stripe_card(TTheme.ACCENT_EMERALD))
		elif ma <= 10.0:
			lbl_zone.text = "AC-2 · Sin daño"
			lbl_zone.add_theme_color_override("font_color", TTheme.ACCENT_CYAN)
			lbl_desc.text = "Percepción leve; aún puede soltar el punto energizado."
			diag_card.add_theme_stylebox_override("panel", TTheme.make_left_stripe_card(TTheme.ACCENT_CYAN))
		elif ma <= 40.0 or (ms < 120.0 and ma < 80.0):
			lbl_zone.text = "AC-3 · Tetanización"
			lbl_zone.add_theme_color_override("font_color", TTheme.ACCENT_AMBER)
			lbl_desc.text = "Contracción muscular sostenida y opresión torácica."
			diag_card.add_theme_stylebox_override("panel", TTheme.make_left_stripe_card(TTheme.ACCENT_AMBER))
		else:
			lbl_zone.text = "AC-4 · Peligro letal"
			lbl_zone.add_theme_color_override("font_color", TTheme.ACCENT_RED)
			lbl_desc.text = "Riesgo inmediato de fibrilación ventricular."
			diag_card.add_theme_stylebox_override("panel", TTheme.make_left_stripe_card(TTheme.ACCENT_RED))

		# Probabilidades continuas según umbrales fisiológicos IEC 60479-1
		var p_perc := 0.0
		if ma >= 0.5:
			p_perc = clampf(0.25 + 0.75 * ((ma - 0.5) / 9.5), 0.25, 1.0)
		var txt_perc := "Nula" if p_perc < 0.10 else ("Leve" if p_perc < 0.50 else ("Activa" if p_perc < 0.85 else "Intensa"))

		var p_tet := 0.0
		if ma >= 5.0:
			var t_factor := clampf(ms / 250.0, 0.35, 1.0)
			p_tet = clampf(((ma - 5.0) / 22.0) * t_factor, 0.08, 1.0)
		var txt_tet := "Ausente" if p_tet < 0.10 else ("Leve" if p_tet < 0.35 else ("Moderada" if p_tet < 0.65 else "Severa"))

		var p_resp := 0.0
		if ma >= 12.0 and ms >= 80.0:
			var r_time := clampf((ms - 80.0) / 420.0, 0.15, 1.0)
			p_resp = clampf(((ma - 12.0) / 38.0) * r_time, 0.06, 1.0)
		var txt_resp := "Muy bajo" if p_resp < 0.10 else ("Bajo" if p_resp < 0.35 else ("Moderado" if p_resp < 0.60 else ("Alto" if p_resp < 0.80 else "Crítico")))

		var c1_ma := 40.0 + 460.0 * exp(-ms / 180.0)
		var p_fib := 0.0
		if ma >= c1_ma * 0.75:
			p_fib = clampf((ma - c1_ma * 0.75) / (c1_ma * 1.15), 0.05, 0.99)
		var txt_fib := "No alcanzada" if p_fib < 0.10 else ("Umbral c1" if p_fib < 0.35 else ("Probable c2" if p_fib < 0.65 else "Muy probable c3"))

		var p_burn := 0.0
		if e_j >= 0.05:
			p_burn = clampf(log(1.0 + e_j * 3.0) / log(1.0 + 18.0), 0.08, 1.0)
		var txt_burn := "Leve o nula" if p_burn < 0.10 else ("Leve" if p_burn < 0.35 else ("Moderada" if p_burn < 0.65 else "Grave"))

		apply_eff_style.call(0, "Percepción", txt_perc, p_perc)
		apply_eff_style.call(1, "Tetanización", txt_tet, p_tet)
		apply_eff_style.call(2, "Paro respiratorio", txt_resp, p_resp)
		apply_eff_style.call(3, "Fibrilación", txt_fib, p_fib)
		apply_eff_style.call(4, "Quemadura", txt_burn, p_burn)

	sld_ma.value_changed.connect(update_iec)
	sld_ms.value_changed.connect(update_iec)
	update_iec.call(0.0)
	return {"root": outer}

static func build_hardware_ai_tab() -> Dictionary:
	var vb := VBoxContainer.new()
	vb.name = "TabHardwareIA"
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 8)

	var top_cols := HBoxContainer.new()
	top_cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_cols.add_theme_constant_override("separation", 10)
	vb.add_child(top_cols)

	var hw_card := PanelContainer.new()
	hw_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hw_card.add_theme_stylebox_override("panel", TTheme.make_panel_style())
	top_cols.add_child(hw_card)
	var hw_vb := VBoxContainer.new()
	hw_vb.add_theme_constant_override("separation", 4)
	hw_card.add_child(hw_vb)
	hw_vb.add_child(TTheme.make_label("Arquitectura IA", 12, TTheme.ACCENT_CYAN))
	var hw_txt := TTheme.make_label(
		"Entradas: corriente, IUF, THD, tensión, temperatura y vibración.\n"
		+ "Red MLP: 8-16-8-4 · 99.2% exactitud.\n"
		+ "SVM RBF: 98.8% exactitud.\n"
		+ "Cobertura: 15 máquinas y tablero CCM 460 V.",
		10, Color(0.84, 0.89, 0.96)
	)
	hw_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hw_vb.add_child(hw_txt)

	var ai_card := PanelContainer.new()
	ai_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ai_card.add_theme_stylebox_override("panel", TTheme.make_panel_style())
	top_cols.add_child(ai_card)
	var ai_vb := VBoxContainer.new()
	ai_vb.add_theme_constant_override("separation", 4)
	ai_card.add_child(ai_vb)

	var ai_hdr := HBoxContainer.new()
	ai_vb.add_child(ai_hdr)
	var ai_t := TTheme.make_label("Diagnóstico en Vivo", 12, TTheme.ACCENT_CYAN)
	ai_t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl_conf := TTheme.make_label("MLP 99.1% · SVM 98.7%", 10, TTheme.ACCENT_EMERALD)
	ai_hdr.add_child(ai_t)
	ai_hdr.add_child(lbl_conf)

	var val_rc := TTheme.make_label("Causa: Operación normal.", 10, TTheme.TEXT_WHITE)
	val_rc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var val_pr := TTheme.make_label("Pronóstico: Condición estable.", 10, TTheme.TEXT_MUTED)
	val_pr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var val_px := TTheme.make_label("Acción: Mantener inspección preventiva.", 10, Color(0.75, 0.92, 1.0))
	val_px.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ai_vb.add_child(val_rc)
	ai_vb.add_child(val_pr)
	ai_vb.add_child(val_px)

	var mhi_row := HBoxContainer.new()
	ai_vb.add_child(mhi_row)
	var mhi_lbl := TTheme.make_label("MHI: 98.5 %", 11, TTheme.ACCENT_EMERALD)
	mhi_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rul_lbl := TTheme.make_label("RUL: 24000 h", 11, TTheme.ACCENT_CYAN)
	mhi_row.add_child(mhi_lbl)
	mhi_row.add_child(rul_lbl)

	var mhi_bar := ProgressBar.new()
	mhi_bar.custom_minimum_size.y = 14
	mhi_bar.value = 98.5
	mhi_bar.show_percentage = false
	mhi_bar.add_theme_stylebox_override("background", TTheme.make_panel_style(Color(0.08, 0.12, 0.20), TTheme.BORDER_SUBTLE, 5, 0, 0, 1))
	mhi_bar.add_theme_stylebox_override("fill", TTheme.make_panel_style(TTheme.ACCENT_EMERALD, TTheme.ACCENT_EMERALD, 5, 0, 0, 0))
	ai_vb.add_child(mhi_bar)

	ai_vb.add_child(TTheme.make_label("Checklist RCM", 10, TTheme.ACCENT_AMBER))
	var chk_scroll := ScrollContainer.new()
	chk_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chk_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	ai_vb.add_child(chk_scroll)
	var chk_vb := VBoxContainer.new()
	chk_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chk_vb.add_theme_constant_override("separation", 3)
	chk_scroll.add_child(chk_vb)

	var sch_card := PanelContainer.new()
	sch_card.custom_minimum_size.y = 172
	sch_card.add_theme_stylebox_override("panel", TTheme.make_panel_style(TTheme.BG_CARD, TTheme.BORDER_SUBTLE, 8, 6, 6))
	vb.add_child(sch_card)
	var sch_canvas := TCanvases.HardwareArchitectureCanvas.new()
	sch_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	sch_card.add_child(sch_canvas)

	return {
		"root": vb, "lbl_conf": lbl_conf,
		"val_rc": val_rc, "val_pr": val_pr, "val_px": val_px,
		"mhi_lbl": mhi_lbl, "rul_lbl": rul_lbl, "mhi_bar": mhi_bar,
		"chk_vb": chk_vb
	}

static func build_cctv_rubric_tab(_on_cam_cb: Callable) -> Dictionary:
	var hbox := HBoxContainer.new()
	hbox.name = "TabRubricaAcademica"
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 12)

	var rub_card := PanelContainer.new()
	rub_card.name = "RubricLeftCard"
	rub_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rub_card.add_theme_stylebox_override("panel", TTheme.make_panel_style())
	hbox.add_child(rub_card)
	var rvb := VBoxContainer.new()
	rvb.add_theme_constant_override("separation", 8)
	rub_card.add_child(rvb)

	var r_hdr := HBoxContainer.new()
	rvb.add_child(r_hdr)
	var rt := TTheme.make_label("Rúbrica RETIE", 14, TTheme.ACCENT_CYAN)
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var score_lbl := TTheme.make_label("5.0 / 5.0", 16, TTheme.ACCENT_EMERALD)
	r_hdr.add_child(rt)
	r_hdr.add_child(score_lbl)

	var crit_panel := PanelContainer.new()
	crit_panel.add_theme_stylebox_override("panel", TTheme.make_panel_style(TTheme.BG_SUBCARD, TTheme.BORDER_SUBTLE, 6, 10, 8))
	rvb.add_child(crit_panel)
	var crit_vb := VBoxContainer.new()
	crit_vb.add_theme_constant_override("separation", 3)
	crit_panel.add_child(crit_vb)
	crit_vb.add_child(TTheme.make_label("Ponderación", 11, TTheme.ACCENT_AMBER))
	for cline in [
		"Base: 5.0 · Bono curso SST: +0.5",
		"5 Reglas LOTO en CCM: +1.0",
		"Sin LOTO: -3.0 · Invasión CCM: -1.5",
		"Sin EPP: -0.8 a -1.0"
	]:
		var cl := TTheme.make_label(cline, 10, TTheme.TEXT_WHITE)
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		crit_vb.add_child(cl)

	rvb.add_child(TTheme.make_label("Historial", 11, TTheme.ACCENT_CYAN))
	var hist_scroll := ScrollContainer.new()
	hist_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hist_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	rvb.add_child(hist_scroll)
	var hist_vb := VBoxContainer.new()
	hist_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hist_vb.add_theme_constant_override("separation", 4)
	hist_scroll.add_child(hist_vb)
	hist_vb.add_child(TTheme.make_label("Sin infracciones registradas.", 10, TTheme.ACCENT_EMERALD))

	var st_card := PanelContainer.new()
	st_card.name = "RubricStationsCard"
	st_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	st_card.add_theme_stylebox_override("panel", TTheme.make_panel_style())
	hbox.add_child(st_card)
	var svb := VBoxContainer.new()
	svb.add_theme_constant_override("separation", 8)
	st_card.add_child(svb)

	svb.add_child(TTheme.make_label("Estaciones", 13, TTheme.ACCENT_CYAN))
	var st_grid := GridContainer.new()
	st_grid.columns = 3
	st_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	st_grid.add_theme_constant_override("h_separation", 6)
	st_grid.add_theme_constant_override("v_separation", 4)
	svb.add_child(st_grid)

	var station_labels: Array[Label] = []
	for i in range(1, 20):
		var st_p := PanelContainer.new()
		st_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		st_p.size_flags_vertical = Control.SIZE_EXPAND_FILL
		st_p.add_theme_stylebox_override("panel", TTheme.make_panel_style(TTheme.BG_SUBCARD, TTheme.BORDER_SUBTLE, 5, 8, 4))
		st_grid.add_child(st_p)
		var sl := TTheme.make_label("E%d" % i, 10, TTheme.TEXT_MUTED)
		sl.clip_text = true
		st_p.add_child(sl)
		station_labels.append(sl)

	return {
		"root": hbox,
		"score_lbl": score_lbl, "hist_vb": hist_vb, "station_labels": station_labels
	}

static func _style_line_edit(le: LineEdit) -> void:
	le.add_theme_stylebox_override("normal", TTheme.make_panel_style(TTheme.BG_INPUT, TTheme.BORDER_SUBTLE, 6, 8, 5))
	le.add_theme_stylebox_override("focus", TTheme.make_panel_style(TTheme.BG_INPUT, TTheme.ACCENT_CYAN, 6, 8, 5))
	le.add_theme_color_override("font_color", TTheme.TEXT_WHITE)

static func _style_option_btn(ob: OptionButton) -> void:
	TTheme.apply_btn_colors(ob, TTheme.BG_INPUT, TTheme.BORDER_SUBTLE, TTheme.TEXT_WHITE)
