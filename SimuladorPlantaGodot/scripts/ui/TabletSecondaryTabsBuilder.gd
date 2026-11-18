class_name TabletSecondaryTabsBuilder
extends RefCounted

## Constructores modulares para las pestañas 3..8 estilo Lab 3 dentro de la Tablet AgroMolinos.

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
	r_vb.add_child(TTheme.make_label("Las 5 Reglas de Oro de Seguridad Eléctrica (RETIE Art. 18 — Estado LOTO en Vivo)", 13, TTheme.ACCENT_CYAN))
	r_vb.add_child(TTheme.make_label("Secuencia obligatoria antes de intervenir conductores de 460 V o el gabinete CCM de AgroMolinos:", 11, TTheme.TEXT_MUTED))

	var rule_badges: Array[Dictionary] = []
	for rule_data in [
		{"n": 1, "t": "1. Corte visible", "d": "Apertura breaker en CCM 460 V."},
		{"n": 2, "t": "2. Bloqueo LOTO", "d": "Candado y tarjeta con Kit LOTO [5]."},
		{"n": 3, "t": "3. Tensión cero (0.0 V)", "d": "Medición con Multímetro [4]."},
		{"n": 4, "t": "4. Puesta a tierra", "d": "Pértiga a tierra temporal."},
		{"n": 5, "t": "5. Delimitación (1.0 m)", "d": "Despeje seguro y selección remota."}
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
		var plbl := TTheme.make_label("PENDIENTE", 10, Color(1.0, 0.85, 0.45), HORIZONTAL_ALIGNMENT_CENTER)
		pill.add_child(plbl)
		rule_badges.append({"panel": pill, "label": plbl})

	# 3 tarjetas inferiores como ui_info.png
	var grid3 := HBoxContainer.new()
	grid3.add_theme_constant_override("separation", 10)
	vb.add_child(grid3)

	var epp_live_lbl := TTheme.make_label("Estado EPP en campo: 0 / 6 prendas equipadas.", 11, TTheme.ACCENT_AMBER)
	for info in [
		{
			"title": "06 · Motor 10 HP",
			"items": "• 7.46 kW · 460 V · 13.5 A (81 A LRA)\n• Clase F PT100 · 1750 RPM\n• ISO 10816: <= 2.3 mm/s (Zona A/B)"
		},
		{
			"title": "CCM 460 V & VFD",
			"items": "• VFD: 81 A -> 18 A (-28% kWh/t)\n• Despeje 1.0 m (Zona 2 RETIE)\n• Pasillo central alineado"
		},
		{
			"title": "Dotación EPP & Perímetros",
			"items": "• 6 prendas EPP en lockers\n• Alertas al cruzar perímetros\n• Selección remota [E] hasta 30 m"
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
		if str(info["title"]).begins_with("Dotación"):
			epp_live_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cv.add_child(epp_live_lbl)

	# Tabla 1 RETIE aplicada
	var tbl_card := PanelContainer.new()
	tbl_card.add_theme_stylebox_override("panel", TTheme.make_panel_style())
	vb.add_child(tbl_card)
	var tbl_vb := VBoxContainer.new()
	tbl_vb.add_theme_constant_override("separation", 5)
	tbl_card.add_child(tbl_vb)
	tbl_vb.add_child(TTheme.make_label("Tabla 1 RETIE: Principales Factores de Riesgo Eléctrico en la Planta", 12, TTheme.ACCENT_CYAN))
	for row in TCatalog.TABLE1_RETIE:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		tbl_vb.add_child(hb)
		var l1 := TTheme.make_label(row["factor"], 10, TTheme.ACCENT_AMBER)
		l1.custom_minimum_size.x = 185
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

	# Izquierda: Estado Jugador en Vivo + Formulario Registro SG-SST
	var left_card := PanelContainer.new()
	left_card.custom_minimum_size.x = 435
	left_card.add_theme_stylebox_override("panel", TTheme.make_panel_style())
	hbox.add_child(left_card)

	var l_vb := VBoxContainer.new()
	l_vb.add_theme_constant_override("separation", 6)
	left_card.add_child(l_vb)

	l_vb.add_child(TTheme.make_label("Ingreso y Estado de Operario SG-SST", 13, TTheme.ACCENT_CYAN))
	l_vb.add_child(TTheme.make_label("Trazabilidad del usuario activo y registro adicional de turno conforme al SG-SST:", 10, TTheme.TEXT_MUTED))

	var player_box := PanelContainer.new()
	player_box.add_theme_stylebox_override("panel", TTheme.make_left_stripe_card(TTheme.ACCENT_EMERALD))
	l_vb.add_child(player_box)
	var player_lbl := TTheme.make_label("Operario Activo (1ra Persona): Estación 1 | EPP 0/6 | Nota 5.0", 11, TTheme.TEXT_WHITE)
	player_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	player_box.add_child(player_lbl)

	var inp_name := LineEdit.new()
	inp_name.placeholder_text = "Nombres (Ej. Miguel Ángel)"
	_style_line_edit(inp_name)
	var inp_last := LineEdit.new()
	inp_last.placeholder_text = "Apellidos (Ej. Rodríguez)"
	_style_line_edit(inp_last)

	var row_meta := HBoxContainer.new()
	row_meta.add_theme_constant_override("separation", 8)
	var inp_age := LineEdit.new()
	inp_age.placeholder_text = "Edad (24)"
	inp_age.custom_minimum_size.x = 95
	_style_line_edit(inp_age)
	var opt_rh := OptionButton.new()
	opt_rh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for rh in ["O+", "O-", "A+", "A-", "B+", "B-", "AB+", "AB-"]:
		opt_rh.add_item("Grupo RH: " + rh)
	_style_option_btn(opt_rh)
	row_meta.add_child(inp_age)
	row_meta.add_child(opt_rh)

	var opt_role := OptionButton.new()
	for r in ["Operario de Planta (Molienda 10 HP)", "Técnico Electromecánico (CCM 460V)", "Supervisor SST (RETIE / OSHA)", "Ingeniero de Control SCADA"]:
		opt_role.add_item(r)
	_style_option_btn(opt_role)

	l_vb.add_child(TTheme.make_label("Nombres:", 11, TTheme.TEXT_MUTED))
	l_vb.add_child(inp_name)
	l_vb.add_child(TTheme.make_label("Apellidos:", 11, TTheme.TEXT_MUTED))
	l_vb.add_child(inp_last)
	l_vb.add_child(TTheme.make_label("Edad y Tipo de Sangre:", 11, TTheme.TEXT_MUTED))
	l_vb.add_child(row_meta)
	l_vb.add_child(TTheme.make_label("Rol / Perfil Autorizado:", 11, TTheme.TEXT_MUTED))
	l_vb.add_child(opt_role)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	l_vb.add_child(btn_row)
	var btn_reg := Button.new()
	btn_reg.text = "Registrar Turno"
	TTheme.apply_btn_colors(btn_reg, TTheme.ACCENT_BLUE, TTheme.ACCENT_CYAN)
	btn_reg.pressed.connect(func(): on_register_cb.call(inp_name.text, inp_last.text, inp_age.text, opt_rh.get_item_text(opt_rh.selected), opt_role.get_item_text(opt_role.selected)); inp_name.text = ""; inp_last.text = ""; inp_age.text = "")
	var btn_clear := Button.new()
	btn_clear.text = "Vaciar Adicionales"
	TTheme.apply_btn_colors(btn_clear, Color(0.55, 0.25, 0.04), TTheme.ACCENT_AMBER)
	btn_clear.pressed.connect(on_clear_cb)
	btn_row.add_child(btn_reg)
	btn_row.add_child(btn_clear)

	# Derecha: Operarios Actuales en Planta + Turno Registrado
	var right_card := PanelContainer.new()
	right_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_card.add_theme_stylebox_override("panel", TTheme.make_panel_style())
	hbox.add_child(right_card)

	var r_vb := VBoxContainer.new()
	r_vb.add_theme_constant_override("separation", 6)
	right_card.add_child(r_vb)

	var r_hdr := HBoxContainer.new()
	r_vb.add_child(r_hdr)
	var rt := TTheme.make_label("Operarios Actualmente Activos en Planta (PlantStaff en Vivo)", 13, TTheme.ACCENT_CYAN)
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r_hdr.add_child(rt)
	var pill_live := PanelContainer.new()
	pill_live.add_theme_stylebox_override("panel", TTheme.make_pill_style(Color(0.04, 0.25, 0.16, 0.9), TTheme.ACCENT_EMERALD))
	pill_live.add_child(TTheme.make_label("Sincronizado 3D", 10, Color(0.55, 0.98, 0.78)))
	r_hdr.add_child(pill_live)

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
		var n_lbl := TTheme.make_label("%s — %s" % [w["name"], w["role"]], 11, TTheme.TEXT_WHITE)
		n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n_lbl.clip_text = true
		top_w.add_child(n_lbl)
		top_w.add_child(TTheme.make_label("RH %s · %s" % [w["rh"], w["clearance"]], 10, TTheme.ACCENT_EMERALD))

		var loc_lbl := TTheme.make_label("%s | Posición 3D: pendiente" % w["station"], 10, TTheme.TEXT_MUTED)
		loc_lbl.clip_text = true
		wvb.add_child(loc_lbl)
		worker_cards[w["id"]] = loc_lbl

	r_vb.add_child(TTheme.make_label("Personal Adicional Registrado en Turno:", 11, TTheme.ACCENT_CYAN))
	var custom_list := VBoxContainer.new()
	custom_list.add_theme_constant_override("separation", 4)
	r_vb.add_child(custom_list)
	var empty_lbl := TTheme.make_label("Sin registros manuales adicionales en este turno.", 10, TTheme.TEXT_MUTED)
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

	vb.add_child(TTheme.make_label("Análisis Combinatorio de Escenarios de Riesgo — AgroMolinos 10 HP", 13, TTheme.ACCENT_CYAN))
	vb.add_child(TTheme.make_label("Seleccione una máquina o sistema actual de la planta y un factor de riesgo para analizar causas, consecuencias y medidas RETIE/RCM:", 11, TTheme.TEXT_MUTED))

	var sel_row := HBoxContainer.new()
	sel_row.add_theme_constant_override("separation", 14)
	vb.add_child(sel_row)

	var col_m := VBoxContainer.new()
	col_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_m.add_theme_constant_override("separation", 4)
	col_m.add_child(TTheme.make_label("1. Máquina / Sistema de la Planta:", 11, TTheme.TEXT_WHITE))
	var opt_m := OptionButton.new()
	_style_option_btn(opt_m)
	for m in TCatalog.RISK_MACHINES:
		opt_m.add_item(m["label"])
	col_m.add_child(opt_m)
	sel_row.add_child(col_m)

	var col_f := VBoxContainer.new()
	col_f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_f.add_child(TTheme.make_label("2. Factor de Riesgo Eléctrico / Mecánico:", 11, TTheme.TEXT_WHITE))
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

	var pill_row := HBoxContainer.new()
	pill_row.add_theme_constant_override("separation", 8)
	svb.add_child(pill_row)
	var pill_m := PanelContainer.new()
	pill_m.add_theme_stylebox_override("panel", TTheme.make_pill_style(Color(0.08, 0.25, 0.45), TTheme.ACCENT_CYAN))
	var lbl_pm := TTheme.make_label("", 10, Color.WHITE)
	pill_m.add_child(lbl_pm)
	var pill_f := PanelContainer.new()
	pill_f.add_theme_stylebox_override("panel", TTheme.make_pill_style(Color(0.45, 0.24, 0.04), TTheme.ACCENT_AMBER))
	var lbl_pf := TTheme.make_label("", 10, Color(1.0, 0.85, 0.45))
	pill_f.add_child(lbl_pf)
	pill_row.add_child(pill_m)
	pill_row.add_child(pill_f)

	var lbl_head := TTheme.make_label("", 14, TTheme.TEXT_WHITE)
	lbl_head.clip_text = true
	svb.add_child(lbl_head)

	var cols3 := HBoxContainer.new()
	cols3.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols3.add_theme_constant_override("separation", 12)
	svb.add_child(cols3)

	var lbl_c1 := _make_risk_col(cols3, "Causas Identificadas", TTheme.ACCENT_AMBER)
	var lbl_c2 := _make_risk_col(cols3, "Consecuencias Operativas y Humanas", TTheme.ACCENT_RED)
	var lbl_c3 := _make_risk_col(cols3, "Medidas de Prevención y Mitigación", TTheme.ACCENT_EMERALD)

	var refresh_cb := func(_idx: int = 0):
		var m_spec: Dictionary = TCatalog.RISK_MACHINES[opt_m.selected]
		var f_spec: Dictionary = TCatalog.RISK_FACTORS[opt_f.selected]
		var sc: Dictionary = TCatalog.get_risk_scenario(m_spec["id"], f_spec["id"])
		lbl_pm.text = m_spec["label"]
		lbl_pf.text = "Riesgo: " + f_spec["id"]
		lbl_head.text = f_spec["label"]
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
	vb.add_theme_constant_override("separation", 8)
	c.add_child(vb)
	vb.add_child(TTheme.make_label(title_txt, 12, col))
	var body := TTheme.make_label("", 11, Color(0.86, 0.90, 0.96))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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

	vb.add_child(TTheme.make_label("Efectos Fisiológicos de la Corriente Eléctrica (Norma IEC 60479-1 · Planta 460 V)", 13, TTheme.ACCENT_CYAN))

	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 14)
	vb.add_child(cols)

	# Columna Izquierda: Sliders + Presets + Diagnóstico Joule
	var left_vb := VBoxContainer.new()
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vb.add_theme_constant_override("separation", 6)
	cols.add_child(left_vb)

	var lbl_ma := TTheme.make_label("Intensidad de Corriente Corporal: 25.0 mA", 11, TTheme.TEXT_WHITE)
	var sld_ma := HSlider.new()
	sld_ma.min_value = 0.2; sld_ma.max_value = 500.0; sld_ma.step = 0.2; sld_ma.value = 25.0
	var lbl_ms := TTheme.make_label("Tiempo de Exposición al Choque: 500 ms (0.50 s)", 11, TTheme.TEXT_WHITE)
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
		{"txt": "Z1 · 0.3 mA", "ma": 0.3, "ms": 800.0, "bg": Color(0.06, 0.45, 0.28)},
		{"txt": "Z2 · 5 mA", "ma": 5.0, "ms": 600.0, "bg": Color(0.08, 0.32, 0.58)},
		{"txt": "Z3 · 25 mA", "ma": 25.0, "ms": 500.0, "bg": Color(0.55, 0.32, 0.04)},
		{"txt": "Z4 · 120 mA", "ma": 120.0, "ms": 500.0, "bg": Color(0.62, 0.14, 0.14)},
		{"txt": "460V (1kΩ)", "ma": 460.0, "ms": 200.0, "bg": Color(0.45, 0.08, 0.22)}
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
	var lbl_zone := TTheme.make_label("ZONA AC-3: Tetanización Muscular y Dificultad Respiratoria", 12, TTheme.ACCENT_AMBER)
	var lbl_desc := TTheme.make_label("", 10, TTheme.TEXT_WHITE)
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var lbl_joule := TTheme.make_label("", 10, TTheme.ACCENT_CYAN)
	diag_vb.add_child(lbl_zone)
	diag_vb.add_child(lbl_desc)
	diag_vb.add_child(lbl_joule)

	left_vb.add_child(TTheme.make_label("Indicadores de Efectos Fisiológicos en el Cuerpo:", 11, TTheme.ACCENT_CYAN))
	var eff_labels: Array[Label] = []
	for eff_name in ["1. Percepción Eléctrica", "2. Contracción / Tetanización", "3. Paro Respiratorio", "4. Fibrilación Ventricular", "5. Quemaduras Internas / Arco"]:
		var ec := PanelContainer.new()
		ec.add_theme_stylebox_override("panel", TTheme.make_panel_style(TTheme.BG_SUBCARD, TTheme.BORDER_SUBTLE, 5, 8, 5))
		left_vb.add_child(ec)
		var el := TTheme.make_label(eff_name + ": Activo", 10, TTheme.TEXT_WHITE)
		ec.add_child(el)
		eff_labels.append(el)

	# Columna Derecha: Gráfica Log-Log + Tabla Zonas
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
	zvb.add_child(TTheme.make_label("Resumen Zonas IEC 60479-1 (R_cuerpo = 1000 Ω)", 11, TTheme.ACCENT_CYAN))
	for zt in [
		"• AC-1 (< 0.5 mA): Imperceptible.",
		"• AC-2 (0.5 – 10 mA): Cosquilleo sin daño.",
		"• AC-3 (10 – 40 mA): Tetanización muscular.",
		"• AC-4 (> 40 mA): Fibrilación ventricular y paro."
	]:
		var l := TTheme.make_label(zt, 10, TTheme.TEXT_MUTED)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		zvb.add_child(l)

	var update_iec := func(_val: float = 0.0):
		var ma: float = float(sld_ma.value)
		var ms: float = float(sld_ms.value)
		lbl_ma.text = "Intensidad de Corriente Corporal: %.1f mA" % ma
		lbl_ms.text = "Tiempo de Exposición al Choque: %.0f ms (%.2f s)" % [ms, ms / 1000.0]
		chart.set_operating_point(ma, ms)
		var e_j: float = pow(ma / 1000.0, 2.0) * 1000.0 * (ms / 1000.0)
		lbl_joule.text = "Energía disipada en el cuerpo: E = I²·R·t ≈ %.4f J" % e_j

		if ma < 0.5:
			lbl_zone.text = "ZONA AC-1: Imperceptible"
			lbl_zone.add_theme_color_override("font_color", TTheme.ACCENT_EMERALD)
			lbl_desc.text = "Corriente por debajo del umbral de percepción (0.5 mA)."
			diag_card.add_theme_stylebox_override("panel", TTheme.make_left_stripe_card(TTheme.ACCENT_EMERALD))
		elif ma <= 10.0:
			lbl_zone.text = "ZONA AC-2: Percepción Sin Peligro"
			lbl_zone.add_theme_color_override("font_color", TTheme.ACCENT_CYAN)
			lbl_desc.text = "Percepción táctil leve. El operario aún puede soltar el punto energizado."
			diag_card.add_theme_stylebox_override("panel", TTheme.make_left_stripe_card(TTheme.ACCENT_CYAN))
		elif ma <= 40.0 or (ms < 120.0 and ma < 80.0):
			lbl_zone.text = "ZONA AC-3: Tetanización Muscular"
			lbl_zone.add_theme_color_override("font_color", TTheme.ACCENT_AMBER)
			lbl_desc.text = "Contracción muscular sostenida y opresión torácica reversible si cesa rápido."
			diag_card.add_theme_stylebox_override("panel", TTheme.make_left_stripe_card(TTheme.ACCENT_AMBER))
		else:
			lbl_zone.text = "ZONA AC-4: Peligro Crítico de Fibrilación Ventricular"
			lbl_zone.add_theme_color_override("font_color", TTheme.ACCENT_RED)
			lbl_desc.text = "Supera curva c1/c2. Riesgo letal inmediato si no actúan protecciones LOTO / 30 mA."
			diag_card.add_theme_stylebox_override("panel", TTheme.make_left_stripe_card(TTheme.ACCENT_RED))

		eff_labels[0].text = "1. Percepción Eléctrica: %s" % ("Umbral superado" if ma >= 0.5 else "Imperceptible")
		eff_labels[1].text = "2. Tetanización Muscular: %s" % ("Severa (no puede soltar)" if ma >= 10.0 else "Ausente")
		eff_labels[2].text = "3. Dificultad / Paro Respiratorio: %s" % ("Riesgo alto" if ma >= 25.0 and ms >= 300.0 else "Bajo")
		eff_labels[3].text = "4. Fibrilación Ventricular: %s" % ("PROBABLE (> curva c1)" if ma >= 45.0 and ms >= 180.0 else "No alcanzada")
		eff_labels[4].text = "5. Quemadura Térmica: %s" % ("Grave por energía Joule" if e_j > 5.0 else "Leve / nula")

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

	# Izquierda: Hardware & Edge AI Info
	var hw_card := PanelContainer.new()
	hw_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hw_card.add_theme_stylebox_override("panel", TTheme.make_panel_style())
	top_cols.add_child(hw_card)
	var hw_vb := VBoxContainer.new()
	hw_vb.add_theme_constant_override("separation", 4)
	hw_card.add_child(hw_vb)
	hw_vb.add_child(TTheme.make_label("Arquitectura Hardware & Edge AI", 12, TTheme.ACCENT_CYAN))
	var hw_txt := TTheme.make_label(
		"• Vector Z-Score (8 entradas): [I_RMS, IUF, THD, V_RMS, Tw, dT/dt, Vib, Vib_pk].\n"
		+ "• Red Neuronal MLP: 8->16->8->4 (99.2% exactitud).\n"
		+ "• Clasificador SVM RBF: γ=0.125, C=10 (98.8% exactitud).\n"
		+ "• Monitoreo: 15 máquinas en tren + CCM 460 V.\n"
		+ "• Actuación: VFD DTC, relé CCM y selección remota <= 30 m.",
		10, Color(0.84, 0.89, 0.96)
	)
	hw_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hw_vb.add_child(hw_txt)

	# Derecha: Edge AI en vivo + MHI + RUL + Checklist RCM interactivo
	var ai_card := PanelContainer.new()
	ai_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ai_card.add_theme_stylebox_override("panel", TTheme.make_panel_style())
	top_cols.add_child(ai_card)
	var ai_vb := VBoxContainer.new()
	ai_vb.add_theme_constant_override("separation", 4)
	ai_card.add_child(ai_vb)

	var ai_hdr := HBoxContainer.new()
	ai_vb.add_child(ai_hdr)
	var ai_t := TTheme.make_label("Diagnóstico Edge AI & Ruta RCM en Vivo", 12, TTheme.ACCENT_CYAN)
	ai_t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl_conf := TTheme.make_label("Certeza: 99.1% MLP | 98.7% SVM", 10, TTheme.ACCENT_EMERALD)
	ai_hdr.add_child(ai_t)
	ai_hdr.add_child(lbl_conf)

	var val_rc := TTheme.make_label("Causa Raíz: Operación nominal balanceada 460V/60Hz.", 10, TTheme.TEXT_WHITE)
	val_rc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var val_pr := TTheme.make_label("Pronóstico: Condición nominal estable (RUL 24,000 h).", 10, TTheme.TEXT_MUTED)
	val_pr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var val_px := TTheme.make_label("Prescripción RCM: Mantener inspección preventiva mensual.", 10, Color(0.75, 0.92, 1.0))
	val_px.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ai_vb.add_child(val_rc)
	ai_vb.add_child(val_pr)
	ai_vb.add_child(val_px)

	var mhi_row := HBoxContainer.new()
	ai_vb.add_child(mhi_row)
	var mhi_lbl := TTheme.make_label("MHI (Motor Health Index): 98.5 %", 11, TTheme.ACCENT_EMERALD)
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

	ai_vb.add_child(TTheme.make_label("Checklist RCM / Procedimiento Correctivo Interactivo:", 10, TTheme.ACCENT_AMBER))
	var chk_scroll := ScrollContainer.new()
	chk_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chk_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	ai_vb.add_child(chk_scroll)
	var chk_vb := VBoxContainer.new()
	chk_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chk_vb.add_theme_constant_override("separation", 3)
	chk_scroll.add_child(chk_vb)

	# Esquema Eléctrico/Electrónico Inferior
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

	# Izquierda: Nota Académica RETIE (0.0 - 5.0), Criterios e Historial de Infracciones/Bonos
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
	var rt := TTheme.make_label("Rúbrica Académica RETIE (0.0 – 5.0)", 14, TTheme.ACCENT_CYAN)
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
	crit_vb.add_child(TTheme.make_label("Criterios de Ponderación RETIE / OSHA", 11, TTheme.ACCENT_AMBER))
	for cline in [
		"• Base: 5.0 pts | Bono Curso SST: +0.5 pt",
		"• 5 Reglas LOTO en CCM 460 V: +1.0 pt",
		"• Sin LOTO: -3.0 pts | Invasión CCM 1m: -1.5 pts",
		"• Sin EPP: -0.8 a -1.0 pts | Operación segura a distancia"
	]:
		var cl := TTheme.make_label(cline, 10, TTheme.TEXT_WHITE)
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		crit_vb.add_child(cl)

	rvb.add_child(TTheme.make_label("Auditoría (Infracciones y Bonificaciones):", 11, TTheme.ACCENT_CYAN))
	var hist_scroll := ScrollContainer.new()
	hist_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hist_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	rvb.add_child(hist_scroll)
	var hist_vb := VBoxContainer.new()
	hist_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hist_vb.add_theme_constant_override("separation", 4)
	hist_scroll.add_child(hist_vb)
	hist_vb.add_child(TTheme.make_label("Sin infracciones registradas. Cumplimiento RETIE óptimo.", 10, TTheme.ACCENT_EMERALD))

	# Derecha: Avance de las 12 Estaciones de Planta
	var st_card := PanelContainer.new()
	st_card.name = "RubricStationsCard"
	st_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	st_card.add_theme_stylebox_override("panel", TTheme.make_panel_style())
	hbox.add_child(st_card)
	var svb := VBoxContainer.new()
	svb.add_theme_constant_override("separation", 8)
	st_card.add_child(svb)

	svb.add_child(TTheme.make_label("Avance de Estaciones de Planta (1 – 19)", 13, TTheme.ACCENT_CYAN))
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
		var sl := TTheme.make_label("E%d · Pendiente" % i, 10, TTheme.TEXT_MUTED)
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
