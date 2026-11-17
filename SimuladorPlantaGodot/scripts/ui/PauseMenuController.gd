class_name PauseMenuController
extends CanvasLayer

# ==============================================================================
# MENÚ DE PAUSA Y CONFIGURACIÓN INDUSTRIAL (ESC) - AGROMOLINOS DEL VALLE S.A.
# Opciones: Reanudar, Reiniciar, Cargar punto anterior, Configuración de volumen
# y guía rápida de teclas con estética minimalista industrial en Godot 4.7
# ==============================================================================

var _is_open: bool = false
var _backdrop: ColorRect = null
var _pause_panel: PanelContainer = null

var _slider_master: HSlider = null
var _lbl_master_pct: Label = null
var _slider_sfx: HSlider = null
var _lbl_sfx_pct: Label = null
var _slider_amb: HSlider = null
var _lbl_amb_pct: Label = null

var _btn_resume: Button = null
var _btn_load_prev: Button = null
var _btn_restart: Button = null
var _btn_quit: Button = null

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_ensure_audio_buses()
	_build_ui()

func _ensure_audio_buses() -> void:
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx == -1:
		AudioServer.add_bus()
		sfx_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_idx, "SFX")
		AudioServer.set_bus_send(sfx_idx, "Master")

	var amb_idx := AudioServer.get_bus_index("Ambience")
	if amb_idx == -1:
		AudioServer.add_bus()
		amb_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(amb_idx, "Ambience")
		AudioServer.set_bus_send(amb_idx, "Master")

func _build_ui() -> void:
	var root_ctrl := Control.new()
	root_ctrl.name = "PauseMenuRoot"
	root_ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_ctrl)

	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.02, 0.04, 0.08, 0.78)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root_ctrl.add_child(_backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	root_ctrl.add_child(center)

	_pause_panel = PanelContainer.new()
	_pause_panel.custom_minimum_size = Vector2(760, 480)
	_pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel_st := StyleBoxFlat.new()
	panel_st.bg_color = Color(0.05, 0.08, 0.13, 0.96)
	panel_st.border_color = Color(0.20, 0.65, 0.90, 0.88)
	panel_st.set_border_width_all(2)
	panel_st.set_corner_radius_all(8)
	panel_st.content_margin_left = 26.0
	panel_st.content_margin_top = 22.0
	panel_st.content_margin_right = 26.0
	panel_st.content_margin_bottom = 22.0
	_pause_panel.add_theme_stylebox_override("panel", panel_st)
	center.add_child(_pause_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 16)
	_pause_panel.add_child(main_vbox)

	# --- Encabezado Minimalista ---
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 2)

	var title_lbl := Label.new()
	title_lbl.text = "PAUSA · AGROMOLINOS"
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(0.25, 0.85, 1.0, 1.0))
	header.add_child(title_lbl)

	var subtitle_lbl := Label.new()
	subtitle_lbl.text = "Menú de Configuración y Control"
	subtitle_lbl.add_theme_font_size_override("font_size", 12)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85, 0.85))
	header.add_child(subtitle_lbl)

	main_vbox.add_child(header)

	var sep1 := HSeparator.new()
	sep1.add_theme_constant_override("separation", 1)
	main_vbox.add_child(sep1)

	# --- Cuerpo en Dos Columnas ---
	var body_hbox := HBoxContainer.new()
	body_hbox.add_theme_constant_override("separation", 28)
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(body_hbox)

	# --- Columna Izquierda: Acciones ---
	var col_actions := VBoxContainer.new()
	col_actions.custom_minimum_size = Vector2(280, 0)
	col_actions.add_theme_constant_override("separation", 10)
	body_hbox.add_child(col_actions)

	var act_title := Label.new()
	act_title.text = "ACCIONES"
	act_title.add_theme_font_size_override("font_size", 12)
	act_title.add_theme_color_override("font_color", Color(0.40, 0.75, 0.95, 0.90))
	col_actions.add_child(act_title)

	_btn_resume = _create_action_button("▶ REANUDAR [ESC]", Color(0.12, 0.28, 0.45, 0.95), Color(0.22, 0.78, 0.95, 0.90))
	_btn_resume.pressed.connect(close_pause_menu)
	col_actions.add_child(_btn_resume)

	_btn_load_prev = _create_action_button("⏮ CARGAR PUNTO ANTERIOR", Color(0.08, 0.16, 0.24, 0.90), Color(0.35, 0.60, 0.80, 0.80))
	_btn_load_prev.pressed.connect(_on_load_previous_checkpoint_pressed)
	col_actions.add_child(_btn_load_prev)

	_btn_restart = _create_action_button("↺ REINICIAR SIMULACIÓN", Color(0.24, 0.16, 0.05, 0.90), Color(0.95, 0.68, 0.20, 0.85))
	_btn_restart.pressed.connect(restart_simulation)
	col_actions.add_child(_btn_restart)

	var act_spacer := Control.new()
	act_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col_actions.add_child(act_spacer)

	_btn_quit = _create_action_button("⏻ SALIR", Color(0.25, 0.08, 0.08, 0.90), Color(0.90, 0.35, 0.35, 0.80))
	_btn_quit.pressed.connect(quit_game)
	col_actions.add_child(_btn_quit)

	var sep_v := VSeparator.new()
	body_hbox.add_child(sep_v)

	# --- Columna Derecha: Configuración de Volumen y Teclas ---
	var col_settings := VBoxContainer.new()
	col_settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_settings.add_theme_constant_override("separation", 10)
	body_hbox.add_child(col_settings)

	var vol_title := Label.new()
	vol_title.text = "VOLUMEN"
	vol_title.add_theme_font_size_override("font_size", 12)
	vol_title.add_theme_color_override("font_color", Color(0.40, 0.75, 0.95, 0.90))
	col_settings.add_child(vol_title)

	# Slider Master
	var row_m := _create_slider_row("General (Master)")
	_slider_master = row_m["slider"]
	_lbl_master_pct = row_m["lbl_pct"]
	_slider_master.value = _get_bus_linear_volume("Master")
	_update_slider_label(_lbl_master_pct, _slider_master.value)
	_slider_master.value_changed.connect(_on_master_volume_changed)
	col_settings.add_child(row_m["container"])

	# Slider SFX / Máquinas
	var row_s := _create_slider_row("Efectos / Máquinas")
	_slider_sfx = row_s["slider"]
	_lbl_sfx_pct = row_s["lbl_pct"]
	_slider_sfx.value = _get_bus_linear_volume("SFX")
	_update_slider_label(_lbl_sfx_pct, _slider_sfx.value)
	_slider_sfx.value_changed.connect(_on_sfx_volume_changed)
	col_settings.add_child(row_s["container"])

	# Slider Ambiente
	var row_a := _create_slider_row("Ambiente de Planta")
	_slider_amb = row_a["slider"]
	_lbl_amb_pct = row_a["lbl_pct"]
	_slider_amb.value = _get_bus_linear_volume("Ambience")
	_update_slider_label(_lbl_amb_pct, _slider_amb.value)
	_slider_amb.value_changed.connect(_on_ambience_volume_changed)
	col_settings.add_child(row_a["container"])

	var sep_c := HSeparator.new()
	sep_c.add_theme_constant_override("separation", 1)
	col_settings.add_child(sep_c)

	# Guía rápida de teclas (ETC)
	var keys_title := Label.new()
	keys_title.text = "CONTROLES RÁPIDOS"
	keys_title.add_theme_font_size_override("font_size", 12)
	keys_title.add_theme_color_override("font_color", Color(0.40, 0.75, 0.95, 0.90))
	col_settings.add_child(keys_title)

	var grid_keys := GridContainer.new()
	grid_keys.columns = 2
	grid_keys.add_theme_constant_override("h_separation", 16)
	grid_keys.add_theme_constant_override("v_separation", 4)
	col_settings.add_child(grid_keys)

	var key_items: Array[Dictionary] = [
		{"k": "[WASD]", "d": "Moverse"},
		{"k": "[SHIFT]", "d": "Correr"},
		{"k": "[ESPACIO]", "d": "Saltar"},
		{"k": "[E]", "d": "Interactuar / Reparar"},
		{"k": "[TAB]", "d": "Tablet Industrial"},
		{"k": "[1 - 5]", "d": "Herramientas"},
		{"k": "[X]", "d": "Parada E-Stop"},
		{"k": "[F11]", "d": "Pantalla Completa"}
	]

	for item in key_items:
		var lbl_k := Label.new()
		lbl_k.text = str(item["k"])
		lbl_k.add_theme_font_size_override("font_size", 11)
		lbl_k.add_theme_color_override("font_color", Color(0.95, 0.85, 0.40, 0.95))
		grid_keys.add_child(lbl_k)

		var lbl_d := Label.new()
		lbl_d.text = str(item["d"])
		lbl_d.add_theme_font_size_override("font_size", 11)
		lbl_d.add_theme_color_override("font_color", Color(0.70, 0.80, 0.88, 0.85))
		grid_keys.add_child(lbl_d)

func _create_action_button(text: String, bg_col: Color, border_col: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 36)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.add_theme_font_size_override("font_size", 12)

	var st_norm := StyleBoxFlat.new()
	st_norm.bg_color = bg_col
	st_norm.border_color = border_col
	st_norm.set_border_width_all(1)
	st_norm.set_corner_radius_all(6)
	st_norm.content_margin_left = 12.0
	st_norm.content_margin_right = 12.0
	btn.add_theme_stylebox_override("normal", st_norm)

	var st_hover := st_norm.duplicate() as StyleBoxFlat
	st_hover.bg_color = bg_col.lightened(0.18)
	st_hover.border_color = border_col.lightened(0.25)
	btn.add_theme_stylebox_override("hover", st_hover)

	var st_press := st_norm.duplicate() as StyleBoxFlat
	st_press.bg_color = bg_col.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", st_press)

	return btn

func _create_slider_row(label_text: String) -> Dictionary:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var top_h := HBoxContainer.new()
	var lbl_name := Label.new()
	lbl_name.text = label_text
	lbl_name.add_theme_font_size_override("font_size", 11)
	lbl_name.add_theme_color_override("font_color", Color(0.80, 0.88, 0.94, 0.90))
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_h.add_child(lbl_name)

	var lbl_val := Label.new()
	lbl_val.text = "100%"
	lbl_val.add_theme_font_size_override("font_size", 11)
	lbl_val.add_theme_color_override("font_color", Color(0.25, 0.85, 1.0, 0.95))
	top_h.add_child(lbl_val)
	vbox.add_child(top_h)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = 1.0
	slider.custom_minimum_size = Vector2(0, 18)
	slider.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(slider)

	return {"container": vbox, "slider": slider, "lbl_pct": lbl_val}

func _update_slider_label(lbl: Label, val: float) -> void:
	if lbl != null and is_instance_valid(lbl):
		lbl.text = "%d%%" % int(round(val * 100.0))

func _get_bus_linear_volume(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return 1.0
	if AudioServer.is_bus_mute(idx):
		return 0.0
	var db := AudioServer.get_bus_volume_db(idx)
	return clampf(db_to_linear(db), 0.0, 1.0)

func _set_bus_linear_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if linear <= 0.005:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.001)))

func _on_master_volume_changed(val: float) -> void:
	_update_slider_label(_lbl_master_pct, val)
	_set_bus_linear_volume("Master", val)

func _on_sfx_volume_changed(val: float) -> void:
	_update_slider_label(_lbl_sfx_pct, val)
	_set_bus_linear_volume("SFX", val)

func _on_ambience_volume_changed(val: float) -> void:
	_update_slider_label(_lbl_amb_pct, val)
	_set_bus_linear_volume("Ambience", val)

func toggle_pause() -> void:
	if _is_open:
		close_pause_menu()
	else:
		open_pause_menu()

func open_pause_menu() -> void:
	_is_open = true
	visible = true
	get_tree().paused = true
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Sincronizar sliders con los buses actuales
	if _slider_master != null:
		_slider_master.value = _get_bus_linear_volume("Master")
		_update_slider_label(_lbl_master_pct, _slider_master.value)
	if _slider_sfx != null:
		_slider_sfx.value = _get_bus_linear_volume("SFX")
		_update_slider_label(_lbl_sfx_pct, _slider_sfx.value)
	if _slider_amb != null:
		_slider_amb.value = _get_bus_linear_volume("Ambience")
		_update_slider_label(_lbl_amb_pct, _slider_amb.value)

func close_pause_menu() -> void:
	_is_open = false
	visible = false
	get_tree().paused = false
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func restart_simulation() -> void:
	close_pause_menu()
	get_tree().reload_current_scene()

func _on_load_previous_checkpoint_pressed() -> void:
	var tut := get_tree().root.find_child("TutorialInductionManager", true, false)
	if tut != null and tut.has_method("load_previous_checkpoint"):
		tut.load_previous_checkpoint()
	close_pause_menu()

func quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()

func is_pause_open() -> bool:
	return _is_open

func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		close_pause_menu()
		get_viewport().set_input_as_handled()
