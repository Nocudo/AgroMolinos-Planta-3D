class_name HUDController
extends Control

const RetieCourseModalScript = preload("res://scripts/ui/RetieCourseModal.gd")
const HUDHotbarAndAvatarScript = preload("res://scripts/ui/HUDHotbarAndAvatar.gd")

# ==============================================================================
# HUD INDUSTRIAL MINIMALISTA EN GODOT 4.7
# Diseño ultra-limpio con baja densidad de texto, cápsula flotante y retícula sutil
# ==============================================================================

@onready var reticle_dot: ColorRect = $Reticle/Dot
@onready var prompt_label: Label = $PromptLabel
@onready var lbl_active_tool: Label = $BottomBar/LblActiveTool
@onready var toast_panel: PanelContainer = $ToastPanel
@onready var toast_title: Label = $ToastPanel/VBox/Title
@onready var toast_msg: Label = $ToastPanel/VBox/Message

# Cápsula de Telemetría Superior
@onready var lbl_scada_rpm: Label = $TopScadaBar/HBox/ValRpm
@onready var lbl_scada_currents: Label = $TopScadaBar/HBox/ValCurrents
@onready var lbl_scada_volt: Label = $TopScadaBar/HBox/ValVolt
@onready var lbl_scada_temp: Label = $TopScadaBar/HBox/ValTemp
@onready var lbl_scada_vib: Label = $TopScadaBar/HBox/ValVib
@onready var lbl_scada_mhi: Label = $TopScadaBar/HBox/ValMhi

var toast_timer: float = 0.0
var _dialogue_panel: PanelContainer = null
var _dialogue_speaker: Label = null
var _dialogue_body: Label = null
var _dialogue_timer: float = 0.0
var briefing_overlay: ColorRect = null
var _briefing_title: Label = null
var _briefing_greeting: Label = null
var _btn_close_briefing: Button = null
var _btn_course_sst: Button = null
var _btn_skip_briefing: Button = null
var _btn_skip_hud: Button = null
var _course_modal = null
var _briefing_resume_tour: bool = true
var _briefing_opened_ms: int = 0
var _tablet_notify_legend: PanelContainer = null
var _tablet_notify_badge: PanelContainer = null
var _tablet_notify_badge_lbl: Label = null
var _tablet_notify_title: Label = null
var _tablet_notify_detail: Label = null
var _tablet_notify_pulse_t: float = 0.0
var _tablet_notify_is_crit: bool = false
var _safety_line_banner: PanelContainer = null
var _safety_line_title: Label = null
var _safety_line_detail: Label = null
var _safety_line_pulse_t: float = 0.0
var _hotbar_avatar = null

func _ready() -> void:
	# Mantener HUD activo durante pausas de inducción para recibir el clic / tecla de cierre
	process_mode = Node.PROCESS_MODE_ALWAYS
	if get_parent() != null:
		get_parent().process_mode = Node.PROCESS_MODE_ALWAYS

	# Asegurar que todos los elementos visuales del HUD ignoren clics de mouse
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_mouse_filter_recursive(self)
	_setup_hotbar_and_avatar()
	_setup_dialogue_panel()
	_setup_tablet_notify_legend()
	_setup_safety_line_banner()
	_setup_skip_tutorial_hud_button()
	_setup_briefing_overlay()
	_setup_retie_course_modal()

	if toast_panel != null:
		toast_panel.visible = false
	if prompt_label != null:
		prompt_label.text = ""
		prompt_label.visible = false
		prompt_label.add_theme_font_size_override("font_size", 20)
		prompt_label.add_theme_constant_override("outline_size", 4)
		prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))

	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.tool_changed.connect(_on_tool_changed)
		bus.telemetry_updated.connect(_on_telemetry_updated)
		bus.notification_posted.connect(_on_notification_posted)
		if bus.has_signal("prompt_updated"):
			bus.prompt_updated.connect(_on_prompt_updated)
		if bus.has_signal("ai_alert_received"):
			bus.ai_alert_received.connect(_on_ai_alert_received)
		if bus.has_signal("safety_score_updated"):
			bus.safety_score_updated.connect(_on_safety_score_updated)
		if bus.has_signal("induction_briefing_requested"):
			bus.induction_briefing_requested.connect(show_briefing_panel)
		if bus.has_signal("epp_state_changed"):
			bus.epp_state_changed.connect(_on_epp_state_changed)
		if bus.has_signal("tablet_warning_received"):
			bus.tablet_warning_received.connect(_on_tablet_warning_received)
		if bus.has_signal("tablet_notifications_cleared"):
			bus.tablet_notifications_cleared.connect(_on_tablet_notifications_cleared)
		if bus.has_signal("safety_line_crossed") and not bus.safety_line_crossed.is_connected(_on_safety_line_crossed):
			bus.safety_line_crossed.connect(_on_safety_line_crossed)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode == KEY_F9:
			_on_skip_tutorial_pressed()
			if get_viewport() != null:
				get_viewport().set_input_as_handled()
			return
	if briefing_overlay == null or not briefing_overlay.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var elapsed_ms := Time.get_ticks_msec() - _briefing_opened_ms
		if elapsed_ms < 250 and DisplayServer.get_name() != "headless":
			return
		var ek := event as InputEventKey
		if ek.keycode == KEY_C and _briefing_resume_tour:
			close_briefing_panel_with_choice(true)
			if get_viewport() != null:
				get_viewport().set_input_as_handled()
		elif ek.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
			close_briefing_panel()
			if get_viewport() != null:
				get_viewport().set_input_as_handled()

func _set_mouse_filter_recursive(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_recursive(child)

func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0 and toast_panel != null:
			toast_panel.visible = false
	if _dialogue_timer > 0.0:
		_dialogue_timer -= delta
		if _dialogue_timer <= 0.0 and _dialogue_panel != null:
			_dialogue_panel.visible = false
	if _tablet_notify_legend != null and _tablet_notify_legend.visible:
		_tablet_notify_pulse_t += delta * 5.0
		var alpha := 0.78 + 0.22 * sin(_tablet_notify_pulse_t)
		_tablet_notify_legend.modulate = Color(1.0, 1.0, 1.0, alpha)
	if _safety_line_banner != null and _safety_line_banner.visible:
		_safety_line_pulse_t += delta * 7.5
		var s_alpha := 0.80 + 0.20 * sin(_safety_line_pulse_t)
		_safety_line_banner.modulate = Color(1.0, 1.0, 1.0, s_alpha)

func _setup_hotbar_and_avatar() -> void:
	var legacy_bar := get_node_or_null("BottomBar") as Control
	if legacy_bar != null:
		legacy_bar.visible = false
	_hotbar_avatar = HUDHotbarAndAvatarScript.new()
	add_child(_hotbar_avatar)
	call_deferred("_sync_hotbar_initial_state")

func _sync_hotbar_initial_state() -> void:
	if _hotbar_avatar == null or not is_inside_tree():
		return
	var locker := get_tree().root.find_child("LockerEPPStation", true, false)
	if locker != null and "epp_equipped" in locker:
		_hotbar_avatar.set_epp_equipped(bool(locker.epp_equipped), false)
	var player := get_tree().root.find_child("PlayerOperator", true, false)
	if player != null and "active_tool_id" in player:
		var tid: int = int(player.active_tool_id)
		var t_map: Dictionary = player.get("tool_names") if player.get("tool_names") is Dictionary else {}
		_hotbar_avatar.set_active_tool(tid, String(t_map.get(tid, "")))

func _on_epp_state_changed(all_equipped: bool, _items: Dictionary) -> void:
	if _hotbar_avatar != null and _hotbar_avatar.has_method("set_epp_equipped"):
		_hotbar_avatar.set_epp_equipped(all_equipped, true)
	if all_equipped:
		show_npc_dialogue(
			"SUPERVISOR SST",
			"EPP equipado (lockers). Avanza a Esclusa Norte.",
			3.5
		)
	elif _dialogue_panel != null:
		_dialogue_panel.visible = false

func show_npc_dialogue(speaker: String, dialogue_text: String, duration: float = 9.0) -> void:
	if _dialogue_panel == null:
		return
	if _dialogue_speaker != null:
		_dialogue_speaker.text = speaker
	if _dialogue_body != null:
		_dialogue_body.text = dialogue_text
	_dialogue_panel.visible = true
	_dialogue_timer = duration

func _setup_dialogue_panel() -> void:
	_dialogue_panel = PanelContainer.new()
	_dialogue_panel.name = "DialoguePanel"
	_dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_panel.visible = false
	_dialogue_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_dialogue_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_dialogue_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_dialogue_panel.offset_left = 28.0
	_dialogue_panel.offset_right = -28.0
	_dialogue_panel.offset_bottom = -154.0
	_dialogue_panel.offset_top = -230.0
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.05, 0.09, 0.15, 0.90)
	st.border_color = Color(1.0, 0.80, 0.22, 0.92)
	st.set_border_width_all(2)
	st.set_corner_radius_all(10)
	st.set_content_margin_all(12)
	_dialogue_panel.add_theme_stylebox_override("panel", st)
	add_child(_dialogue_panel)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	_dialogue_panel.add_child(vbox)

	_dialogue_speaker = Label.new()
	_dialogue_speaker.name = "DialogueSpeaker"
	_dialogue_speaker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_speaker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dialogue_speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dialogue_speaker.add_theme_font_size_override("font_size", 13)
	_dialogue_speaker.add_theme_color_override("font_color", Color(1.0, 0.85, 0.28, 1.0))
	vbox.add_child(_dialogue_speaker)

	_dialogue_body = Label.new()
	_dialogue_body.name = "DialogueBody"
	_dialogue_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dialogue_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dialogue_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_body.add_theme_font_size_override("font_size", 15)
	_dialogue_body.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0, 1.0))
	vbox.add_child(_dialogue_body)

func _setup_tablet_notify_legend() -> void:
	_tablet_notify_legend = PanelContainer.new()
	_tablet_notify_legend.name = "TabletNotifyLegend"
	_tablet_notify_legend.visible = false
	_tablet_notify_legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tablet_notify_legend.anchors_preset = Control.PRESET_CENTER_TOP
	_tablet_notify_legend.anchor_left = 0.5
	_tablet_notify_legend.anchor_right = 0.5
	_tablet_notify_legend.anchor_top = 0.0
	_tablet_notify_legend.anchor_bottom = 0.0
	_tablet_notify_legend.offset_left = -200.0
	_tablet_notify_legend.offset_right = 200.0
	_tablet_notify_legend.offset_top = 42.0
	_tablet_notify_legend.offset_bottom = 86.0
	_tablet_notify_legend.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_tablet_notify_legend)

	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 8)
	_tablet_notify_legend.add_child(hb)

	_tablet_notify_badge = PanelContainer.new()
	_tablet_notify_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tablet_notify_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(_tablet_notify_badge)

	_tablet_notify_badge_lbl = Label.new()
	_tablet_notify_badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tablet_notify_badge_lbl.text = "▲ TABLET"
	_tablet_notify_badge_lbl.add_theme_font_size_override("font_size", 11)
	_tablet_notify_badge.add_child(_tablet_notify_badge_lbl)

	var txt_vb := VBoxContainer.new()
	txt_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	txt_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt_vb.add_theme_constant_override("separation", 1)
	hb.add_child(txt_vb)

	_tablet_notify_title = Label.new()
	_tablet_notify_title.name = "TabletLegendTitle"
	_tablet_notify_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tablet_notify_title.text = "NOTIFICACIÓN NUEVA · [TAB]"
	_tablet_notify_title.add_theme_font_size_override("font_size", 11)
	_tablet_notify_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.30, 1.0))
	txt_vb.add_child(_tablet_notify_title)

	_tablet_notify_detail = Label.new()
	_tablet_notify_detail.name = "TabletLegendDetail"
	_tablet_notify_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tablet_notify_detail.text = ""
	_tablet_notify_detail.clip_text = true
	_tablet_notify_detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_tablet_notify_detail.add_theme_font_size_override("font_size", 10)
	_tablet_notify_detail.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0, 1.0))
	txt_vb.add_child(_tablet_notify_detail)
	_apply_tablet_legend_style(false)

func _apply_tablet_legend_style(is_crit: bool) -> void:
	if _tablet_notify_legend == null:
		return
	var accent := Color(0.95, 0.28, 0.28, 1.0) if is_crit else Color(0.98, 0.68, 0.12, 1.0)
	var bg := Color(0.16, 0.04, 0.05, 0.94) if is_crit else Color(0.12, 0.08, 0.03, 0.94)
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = accent
	st.set_border_width_all(2)
	st.set_corner_radius_all(8)
	st.content_margin_left = 12.0
	st.content_margin_right = 12.0
	st.content_margin_top = 5.0
	st.content_margin_bottom = 5.0
	_tablet_notify_legend.add_theme_stylebox_override("panel", st)

	var bst := StyleBoxFlat.new()
	bst.bg_color = Color(0.45, 0.08, 0.08, 1.0) if is_crit else Color(0.38, 0.22, 0.03, 1.0)
	bst.border_color = accent
	bst.set_border_width_all(1)
	bst.set_corner_radius_all(6)
	bst.content_margin_left = 8.0
	bst.content_margin_right = 8.0
	bst.content_margin_top = 3.0
	bst.content_margin_bottom = 3.0
	_tablet_notify_badge.add_theme_stylebox_override("panel", bst)
	_tablet_notify_badge_lbl.add_theme_color_override("font_color", accent)
	_tablet_notify_title.add_theme_color_override("font_color", accent)

func _on_tablet_warning_received(warning_data: Dictionary) -> void:
	if _tablet_notify_legend == null:
		return
	var sev := str(warning_data.get("severity", "WARNING"))
	_tablet_notify_is_crit = (sev == "CRITICAL")
	_apply_tablet_legend_style(_tablet_notify_is_crit)
	var unread := int(warning_data.get("unread_count", 1))
	_tablet_notify_badge_lbl.text = "■ (%d)" % unread if _tablet_notify_is_crit else "▲ (%d)" % unread
	_tablet_notify_title.text = "NOTIFICACIÓN NUEVA (%d) · [TAB]" % unread
	_tablet_notify_detail.text = str(warning_data.get("title", "Alerta"))
	_tablet_notify_pulse_t = 0.0
	_tablet_notify_legend.modulate = Color.WHITE
	_tablet_notify_legend.visible = true

func _on_tablet_notifications_cleared() -> void:
	if _tablet_notify_legend != null:
		_tablet_notify_legend.visible = false

func _setup_safety_line_banner() -> void:
	_safety_line_banner = PanelContainer.new()
	_safety_line_banner.name = "SafetyLineAlertBanner"
	_safety_line_banner.visible = false
	_safety_line_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safety_line_banner.anchors_preset = Control.PRESET_CENTER_TOP
	_safety_line_banner.anchor_left = 0.5
	_safety_line_banner.anchor_right = 0.5
	_safety_line_banner.anchor_top = 0.0
	_safety_line_banner.anchor_bottom = 0.0
	_safety_line_banner.offset_left = -210.0
	_safety_line_banner.offset_right = 210.0
	_safety_line_banner.offset_top = 92.0
	_safety_line_banner.offset_bottom = 132.0
	_safety_line_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_safety_line_banner.grow_vertical = Control.GROW_DIRECTION_END
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.28, 0.03, 0.03, 0.94)
	st.border_color = Color(1.0, 0.16, 0.14, 1.0)
	st.set_border_width_all(2)
	st.set_corner_radius_all(8)
	st.content_margin_left = 12.0
	st.content_margin_right = 12.0
	st.content_margin_top = 4.0
	st.content_margin_bottom = 4.0
	_safety_line_banner.add_theme_stylebox_override("panel", st)
	add_child(_safety_line_banner)

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 2)
	_safety_line_banner.add_child(vb)

	_safety_line_title = Label.new()
	_safety_line_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safety_line_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_safety_line_title.add_theme_font_size_override("font_size", 11)
	_safety_line_title.add_theme_color_override("font_color", Color(1.0, 0.35, 0.30, 1.0))
	_safety_line_title.text = "⚠ LÍNEA DE SEGURIDAD"
	vb.add_child(_safety_line_title)

	_safety_line_detail = Label.new()
	_safety_line_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safety_line_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_safety_line_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_safety_line_detail.custom_minimum_size = Vector2(400.0, 0.0)
	_safety_line_detail.add_theme_font_size_override("font_size", 10)
	_safety_line_detail.add_theme_color_override("font_color", Color(1.0, 0.94, 0.88, 1.0))
	_safety_line_detail.text = "Retrocede a zona segura."
	vb.add_child(_safety_line_detail)

func _on_safety_line_crossed(active: bool, _zone_id: String, title: String, message: String) -> void:
	if _safety_line_banner == null:
		return
	_safety_line_banner.visible = active
	if active:
		if _safety_line_title != null and title != "":
			_safety_line_title.text = title
		if _safety_line_detail != null and message != "":
			_safety_line_detail.text = message
		_safety_line_pulse_t = 0.0
		_safety_line_banner.modulate = Color.WHITE

func is_safety_line_alert_visible() -> bool:
	return _safety_line_banner != null and _safety_line_banner.visible

func _on_prompt_updated(txt: String) -> void:
	var is_fault := "[FALLA]" in txt or "reparar falla" in txt
	var is_green_sel := ("Modo Selección" in txt or "[E]" in txt or "[Req:" in txt or "inducir falla" in txt) and not is_fault
	if reticle_dot != null:
		if is_fault:
			reticle_dot.color = Color(1.0, 0.45, 0.42, 1.0)
			reticle_dot.custom_minimum_size = Vector2(6, 6)
		elif is_green_sel:
			reticle_dot.color = Color(0.18, 1.0, 0.42, 1.0)
			reticle_dot.custom_minimum_size = Vector2(6, 6)
		else:
			reticle_dot.color = Color(1.0, 1.0, 1.0, 0.45)
			reticle_dot.custom_minimum_size = Vector2(3, 3)
	if prompt_label != null:
		prompt_label.text = txt
		prompt_label.visible = (txt != "")
		var col := Color(1.0, 0.50, 0.48, 1.0) if is_fault else (Color(0.32, 1.0, 0.52, 1.0) if is_green_sel else Color(1.0, 0.92, 0.4, 0.95))
		prompt_label.add_theme_color_override("font_color", col)

func _on_tool_changed(tool_id: int, tool_name: String) -> void:
	if lbl_active_tool != null:
		lbl_active_tool.text = tool_name
	if _hotbar_avatar != null and _hotbar_avatar.has_method("set_active_tool"):
		_hotbar_avatar.set_active_tool(tool_id, tool_name)

func _on_telemetry_updated(
	rpm: float,
	cur_a: float,
	cur_b: float,
	cur_c: float,
	volt: float,
	_freq: float,
	temp: float,
	vib: float,
	_p_kw: float,
	_pf: float,
	_flow: float
) -> void:
	if lbl_scada_rpm != null:
		lbl_scada_rpm.text = "%d RPM" % int(rpm)
	if lbl_scada_currents != null:
		var max_i = maxf(cur_a, maxf(cur_b, cur_c))
		lbl_scada_currents.text = "%.1f A" % max_i
	if lbl_scada_volt != null:
		lbl_scada_volt.text = "%.0f V" % volt
	if lbl_scada_temp != null:
		lbl_scada_temp.text = "%.0f °C" % temp
	if lbl_scada_vib != null:
		lbl_scada_vib.text = "%.1f mm/s" % vib

func _on_ai_alert_received(alert_data: Dictionary) -> void:
	if lbl_scada_mhi != null and alert_data.has("mhi"):
		var mhi: float = float(alert_data["mhi"])
		lbl_scada_mhi.text = "MHI %d%%" % int(round(mhi))
		if mhi > 85.0:
			lbl_scada_mhi.modulate = Color(0.25, 0.95, 0.5, 1.0)
		elif mhi >= 60.0:
			lbl_scada_mhi.modulate = Color(1.0, 0.8, 0.2, 1.0)
		else:
			lbl_scada_mhi.modulate = Color(1.0, 0.25, 0.25, 1.0)

func _on_safety_score_updated(current_score: float, _history: Array) -> void:
	if lbl_active_tool != null and not lbl_active_tool.text.contains("RETIE"):
		pass # Se muestra la nota en la Tablet [TAB] y toast de seguridad

func _on_notification_posted(title: String, message: String, severity: String) -> void:
	if toast_panel == null: return
	toast_title.text = title
	toast_msg.text = message

	if severity == "error":
		toast_panel.self_modulate = Color(1.0, 0.25, 0.25, 0.95)
	elif severity == "warning":
		toast_panel.self_modulate = Color(1.0, 0.75, 0.2, 0.95)
	else:
		toast_panel.self_modulate = Color(0.2, 0.75, 1.0, 0.95)

	toast_panel.visible = true
	toast_timer = 3.0

func is_briefing_visible() -> bool:
	return briefing_overlay != null and briefing_overlay.visible

func show_briefing_panel(title: String, greeting: String, resume_tour_on_close: bool = true) -> void:
	if briefing_overlay == null:
		return
	_briefing_resume_tour = resume_tour_on_close
	_briefing_opened_ms = Time.get_ticks_msec()
	if _briefing_title != null:
		_briefing_title.text = title
	if _briefing_greeting != null:
		_briefing_greeting.text = greeting
	if _btn_course_sst != null:
		_btn_course_sst.visible = resume_tour_on_close
	if _btn_close_briefing != null:
		_btn_close_briefing.text = (
			"▶  Directo al Recorrido  [E / Espacio]"
			if resume_tour_on_close
			else "▶  Continuar Simulación  [E / Espacio]"
		)
	briefing_overlay.visible = true
	if resume_tour_on_close and _btn_course_sst != null:
		_btn_course_sst.grab_focus()
	elif _btn_close_briefing != null:
		_btn_close_briefing.grab_focus()
	if is_inside_tree():
		get_tree().paused = true
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_briefing_panel() -> void:
	close_briefing_panel_with_choice(false)

func close_briefing_panel_with_choice(start_sst_course: bool) -> void:
	if briefing_overlay == null or not briefing_overlay.visible:
		return
	briefing_overlay.visible = false
	if is_inside_tree():
		get_tree().paused = false
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		if _briefing_resume_tour and bus.has_signal("sst_course_mode_selected"):
			bus.sst_course_mode_selected.emit(start_sst_course)
		if bus.has_signal("induction_briefing_closed"):
			bus.induction_briefing_closed.emit(_briefing_resume_tour)

func _exit_tree() -> void:
	if briefing_overlay != null and briefing_overlay.visible and is_inside_tree():
		get_tree().paused = false

func _setup_briefing_overlay() -> void:
	briefing_overlay = ColorRect.new()
	briefing_overlay.name = "BriefingOverlay"
	briefing_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	briefing_overlay.color = Color(0.02, 0.04, 0.07, 0.72)
	briefing_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	briefing_overlay.visible = false
	add_child(briefing_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	briefing_overlay.add_child(center)

	var card := PanelContainer.new()
	card.name = "BriefingCard"
	card.custom_minimum_size = Vector2(900, 0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", _build_briefing_panel_style())
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	var badge := Label.new()
	badge.text = "INDUCCIÓN RETIE · AGROMOLINOS 10 HP"
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(0.25, 0.92, 0.65, 1.0))
	vbox.add_child(badge)

	_briefing_title = Label.new()
	_briefing_title.name = "BriefingTitle"
	_briefing_title.add_theme_font_size_override("font_size", 20)
	_briefing_title.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
	vbox.add_child(_briefing_title)

	_briefing_greeting = Label.new()
	_briefing_greeting.name = "BriefingGreeting"
	_briefing_greeting.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_briefing_greeting.add_theme_font_size_override("font_size", 13)
	_briefing_greeting.add_theme_color_override("font_color", Color(0.84, 0.90, 0.96, 1.0))
	vbox.add_child(_briefing_greeting)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	vbox.add_child(cols)

	cols.add_child(_build_briefing_column(
		"CONTROLES",
		"[color=#48e5a8][b]WASD[/b][/color] Mover  •  [color=#48e5a8][b]Shift[/b][/color] Correr  •  [color=#48e5a8][b]Espacio[/b][/color] Saltar\n"
		+ "[color=#48e5a8][b]E / Clic[/b][/color] Interactuar, puertas y EPP\n"
		+ "[color=#48e5a8][b]1–5[/b][/color] Herramientas: Manos, Alicates, Llave, Multímetro, LOTO\n"
		+ "[color=#48e5a8][b]TAB[/b][/color] Tablet SCADA  •  [color=#48e5a8][b]X[/b][/color] E-Stop  •  [color=#48e5a8][b]F11[/b][/color] Pantalla"
	))
	cols.add_child(_build_briefing_column(
		"SEGURIDAD RETIE",
		"[color=#ffd15c][b]1. Vestidores:[/b][/color] Ropa y 6 EPP en lockers.\n"
		+ "[color=#ffd15c][b]2. Puertas:[/b][/color] Abre y cierra con [b][E][/b].\n"
		+ "[color=#ffd15c][b]3. 5 Reglas LOTO:[/b][/color] En CCM con [4] Multímetro y [5] LOTO.\n"
		+ "[color=#ffd15c][b]4. Fallas / Selección:[/b][/color] Rojo: falla activa. Verde: a distancia.\n"
		+ "[color=#ffd15c][b]5. Tablet [TAB]:[/b][/color] Telemetría, IA, cámaras y nota RETIE."
	))

	var hint := Label.new()
	hint.text = "Elige una opción:"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.70, 0.84, 0.94, 1.0))
	vbox.add_child(hint)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	footer.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(footer)

	_btn_skip_briefing = Button.new()
	_btn_skip_briefing.name = "BtnSkipTutorial"
	_btn_skip_briefing.text = "⏭  Saltar [F9]"
	_btn_skip_briefing.custom_minimum_size = Vector2(160, 38)
	_btn_skip_briefing.mouse_filter = Control.MOUSE_FILTER_STOP
	_btn_skip_briefing.add_theme_font_size_override("font_size", 12)
	_btn_skip_briefing.add_theme_stylebox_override("normal", _build_briefing_button_style(Color(0.32, 0.20, 0.06, 1.0), Color(0.98, 0.72, 0.22, 1.0)))
	_btn_skip_briefing.add_theme_stylebox_override("hover", _build_briefing_button_style(Color(0.45, 0.28, 0.08, 1.0), Color(1.0, 0.84, 0.38, 1.0)))
	_btn_skip_briefing.add_theme_stylebox_override("focus", _build_briefing_button_style(Color(0.40, 0.24, 0.07, 1.0), Color(1.0, 0.84, 0.38, 1.0)))
	_btn_skip_briefing.pressed.connect(_on_skip_tutorial_pressed)
	footer.add_child(_btn_skip_briefing)

	_btn_course_sst = Button.new()
	_btn_course_sst.name = "BtnCourseSST"
	_btn_course_sst.text = "★  Curso SST (+0.5 pt) [C]"
	_btn_course_sst.custom_minimum_size = Vector2(230, 38)
	_btn_course_sst.mouse_filter = Control.MOUSE_FILTER_STOP
	_btn_course_sst.add_theme_font_size_override("font_size", 12)
	_btn_course_sst.add_theme_stylebox_override("normal", _build_briefing_button_style(Color(0.06, 0.34, 0.44, 1.0), Color(0.24, 0.88, 0.98, 1.0)))
	_btn_course_sst.add_theme_stylebox_override("hover", _build_briefing_button_style(Color(0.10, 0.46, 0.58, 1.0), Color(0.45, 0.96, 1.0, 1.0)))
	_btn_course_sst.add_theme_stylebox_override("focus", _build_briefing_button_style(Color(0.08, 0.40, 0.52, 1.0), Color(0.45, 0.96, 1.0, 1.0)))
	_btn_course_sst.pressed.connect(func(): close_briefing_panel_with_choice(true))
	footer.add_child(_btn_course_sst)

	_btn_close_briefing = Button.new()
	_btn_close_briefing.name = "BtnStartTour"
	_btn_close_briefing.text = "[E] Iniciar Recorrido"
	_btn_close_briefing.custom_minimum_size = Vector2(210, 38)
	_btn_close_briefing.mouse_filter = Control.MOUSE_FILTER_STOP
	_btn_close_briefing.add_theme_font_size_override("font_size", 13)
	_btn_close_briefing.add_theme_stylebox_override("normal", _build_briefing_button_style(Color(0.08, 0.45, 0.34, 1.0), Color(0.25, 0.95, 0.65, 1.0)))
	_btn_close_briefing.add_theme_stylebox_override("hover", _build_briefing_button_style(Color(0.12, 0.58, 0.42, 1.0), Color(0.45, 1.0, 0.75, 1.0)))
	_btn_close_briefing.add_theme_stylebox_override("focus", _build_briefing_button_style(Color(0.10, 0.52, 0.38, 1.0), Color(0.45, 1.0, 0.75, 1.0)))
	_btn_close_briefing.pressed.connect(close_briefing_panel)
	footer.add_child(_btn_close_briefing)

func _setup_retie_course_modal() -> void:
	if RetieCourseModalScript == null:
		return
	_course_modal = RetieCourseModalScript.new()
	_course_modal.z_index = 90
	_course_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_course_modal)
	if _course_modal.has_signal("course_finished"):
		_course_modal.course_finished.connect(_on_retie_course_finished)
	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("sst_course_modal_requested"):
		if not bus.sst_course_modal_requested.is_connected(_on_course_modal_requested):
			bus.sst_course_modal_requested.connect(_on_course_modal_requested)

func _on_course_modal_requested() -> void:
	if _course_modal != null and is_instance_valid(_course_modal):
		_course_modal.open_course()

func _on_retie_course_finished(passed: bool, score: int, total: int) -> void:
	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("sst_course_completed_event"):
		bus.sst_course_completed_event.emit(passed, score, total)

func _build_briefing_column(header_txt: String, body_bbcode: String) -> PanelContainer:
	var sub := PanelContainer.new()
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.mouse_filter = Control.MOUSE_FILTER_STOP
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.03, 0.06, 0.10, 0.85)
	st.border_color = Color(0.20, 0.42, 0.60, 0.55)
	st.set_border_width_all(1)
	st.set_corner_radius_all(8)
	st.set_content_margin_all(14)
	sub.add_theme_stylebox_override("panel", st)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	sub.add_child(box)

	var hdr := Label.new()
	hdr.text = header_txt
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", Color(0.40, 0.85, 1.0, 1.0))
	box.add_child(hdr)

	var rtl := RichTextLabel.new()
	rtl.name = "ColumnBody"
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.custom_minimum_size = Vector2(390, 0)
	rtl.add_theme_font_size_override("normal_font_size", 13)
	rtl.add_theme_font_size_override("bold_font_size", 13)
	rtl.text = body_bbcode
	box.add_child(rtl)
	return sub

func _build_briefing_panel_style() -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.05, 0.08, 0.14, 0.94)
	st.border_color = Color(0.22, 0.78, 0.95, 0.90)
	st.set_border_width_all(2)
	st.set_corner_radius_all(12)
	st.set_content_margin_all(22)
	return st

func _build_briefing_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border
	st.set_border_width_all(2)
	st.set_corner_radius_all(8)
	st.set_content_margin_all(8)
	return st

func _setup_skip_tutorial_hud_button() -> void:
	_btn_skip_hud = Button.new()
	_btn_skip_hud.name = "BtnSkipTutorialHUD"
	_btn_skip_hud.text = "⏭ Saltar Tutorial [F9]"
	_btn_skip_hud.mouse_filter = Control.MOUSE_FILTER_STOP
	_btn_skip_hud.anchor_left = 0.0
	_btn_skip_hud.anchor_right = 0.0
	_btn_skip_hud.anchor_top = 0.0
	_btn_skip_hud.anchor_bottom = 0.0
	_btn_skip_hud.offset_left = 14.0
	_btn_skip_hud.offset_right = 210.0
	_btn_skip_hud.offset_top = 10.0
	_btn_skip_hud.offset_bottom = 42.0
	_btn_skip_hud.add_theme_font_size_override("font_size", 12)
	_btn_skip_hud.add_theme_stylebox_override("normal", _build_briefing_button_style(Color(0.24, 0.16, 0.05, 0.88), Color(0.98, 0.72, 0.22, 0.92)))
	_btn_skip_hud.add_theme_stylebox_override("hover", _build_briefing_button_style(Color(0.38, 0.24, 0.07, 0.96), Color(1.0, 0.85, 0.35, 1.0)))
	_btn_skip_hud.pressed.connect(_on_skip_tutorial_pressed)
	add_child(_btn_skip_hud)

func refresh_skip_button_visibility() -> void:
	if _btn_skip_hud == null or not is_inside_tree():
		return
	var tut := get_tree().root.find_child("TutorialInductionManager", true, false)
	if tut != null:
		var done := bool(tut.get("tutorial_skipped")) or bool(tut.get("induction_certified"))
		_btn_skip_hud.visible = not done

func _on_skip_tutorial_pressed() -> void:
	if not is_inside_tree():
		return
	var tut := get_tree().root.find_child("TutorialInductionManager", true, false)
	if tut != null and tut.has_method("skip_tutorial_to_final_station"):
		tut.skip_tutorial_to_final_station()
	refresh_skip_button_visibility()
