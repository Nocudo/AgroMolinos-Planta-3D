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
var _dialogue_choices_row: HBoxContainer = null
var _dialogue_choice_entries: Array[Dictionary] = []
var _dialogue_choice_cb: Callable = Callable()
var _dialogue_keep_open: bool = false
var _dialogue_timer: float = 0.0
var briefing_overlay: ColorRect = null
var _briefing_title: Label = null
var _briefing_greeting: Label = null
var _briefing_sections_box: VBoxContainer = null
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
var _bottom_right_column: VBoxContainer = null
var _controls_tips_card: PanelContainer = null
var _bottom_right_dock: VBoxContainer = null
var _notification_stack: VBoxContainer = null
var _notification_entries: Array[Dictionary] = []
var _notification_seq: int = 0
var _last_safety_line_key: String = ""
var _last_tablet_warning_key: String = ""
var _last_tablet_warning_title: String = ""
var _location_banner: PanelContainer = null
var _location_label: Label = null
var _location_poll_timer: float = 0.0
var _location_player_ref: Node3D = null
var _last_location_name: String = ""

const MAX_STACKED_NOTIFICATIONS: int = 4
const NOTIFICATION_DURATION_S: float = 4.2
const NOTIFICATION_FADE_S: float = 0.45

func _ready() -> void:
	# Mantener HUD activo durante pausas de inducción para recibir el clic / tecla de cierre
	process_mode = Node.PROCESS_MODE_ALWAYS
	if get_parent() != null:
		get_parent().process_mode = Node.PROCESS_MODE_ALWAYS

	# Asegurar que todos los elementos visuales del HUD ignoren clics de mouse
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_mouse_filter_recursive(self)
	_setup_hotbar_and_avatar()
	_setup_fixed_crosshair()
	_setup_location_top_banner()
	_setup_controls_tips_card()
	_setup_notification_stack()
	_setup_safety_line_banner()
	_setup_tablet_notify_legend()
	_setup_dialogue_panel()
	_setup_skip_tutorial_hud_button()
	_setup_briefing_overlay()
	_setup_retie_course_modal()

	if toast_panel != null:
		toast_panel.visible = false
	var top_scada := get_node_or_null("TopScadaBar") as Control
	if top_scada != null:
		top_scada.visible = false
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
		# Selección rápida de preguntas en conversación con el Supervisor SST durante el recorrido (teclas 6, 7, 8, 9)
		if _dialogue_choices_row != null and _dialogue_choices_row.visible and not _dialogue_choice_entries.is_empty():
			var tablet_n := get_tree().root.find_child("TabletRoot", true, false) if is_inside_tree() else null
			var modal_open := (briefing_overlay != null and briefing_overlay.visible) or (tablet_n != null and bool(tablet_n.visible)) or (_course_modal != null and bool(_course_modal.visible))
			if not modal_open and not get_tree().paused:
				var kc := (event as InputEventKey).keycode
				var key_map := {KEY_6: 6, KEY_KP_6: 6, KEY_7: 7, KEY_KP_7: 7, KEY_8: 8, KEY_KP_8: 8, KEY_9: 9, KEY_KP_9: 9, KEY_0: 0, KEY_KP_0: 0}
				if key_map.has(kc):
					var chosen_num: int = int(key_map[kc])
					for ce in _dialogue_choice_entries:
						if int(ce.get("key_num", -1)) == chosen_num:
							if _dialogue_choice_cb.is_valid():
								_dialogue_choice_cb.call(str(ce.get("id", "")))
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
	_update_notification_stack(delta)
	_update_realtime_location(delta)
	if _dialogue_timer > 0.0:
		_dialogue_timer -= delta
		if _dialogue_timer <= 0.0 and _dialogue_panel != null and not _dialogue_keep_open:
			_dialogue_panel.visible = false
	if _tablet_notify_legend != null and _tablet_notify_legend.visible:
		_tablet_notify_pulse_t += delta * 5.0
		var alpha := 0.78 + 0.22 * sin(_tablet_notify_pulse_t)
		_tablet_notify_legend.modulate = Color(1.0, 1.0, 1.0, alpha)
	if _safety_line_banner != null and _safety_line_banner.visible:
		_safety_line_pulse_t += delta * 7.5
		var s_alpha := 0.80 + 0.20 * sin(_safety_line_pulse_t)
		_safety_line_banner.modulate = Color(1.0, 1.0, 1.0, s_alpha)

func _setup_location_top_banner() -> void:
	_location_banner = PanelContainer.new()
	_location_banner.name = "LocationTopBanner"
	_location_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_location_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_location_banner.anchor_left = 0.5
	_location_banner.anchor_right = 0.5
	_location_banner.anchor_top = 0.0
	_location_banner.anchor_bottom = 0.0
	_location_banner.offset_left = -140.0
	_location_banner.offset_right = 140.0
	_location_banner.offset_top = 10.0
	_location_banner.offset_bottom = 40.0
	_location_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.05, 0.09, 0.15, 0.88)
	st.border_color = Color(1.0, 0.80, 0.22, 0.88)
	st.set_border_width_all(1)
	st.set_corner_radius_all(8)
	st.content_margin_left = 18.0
	st.content_margin_right = 18.0
	st.content_margin_top = 5.0
	st.content_margin_bottom = 5.0
	_location_banner.add_theme_stylebox_override("panel", st)
	add_child(_location_banner)

	_location_label = Label.new()
	_location_label.name = "LocationBannerLabel"
	_location_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_location_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_location_label.add_theme_font_size_override("font_size", 13)
	_location_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.34, 1.0))
	_location_label.text = "Portería"
	_location_banner.add_child(_location_label)
	_last_location_name = "Portería"

func resolve_plant_location(p: Vector3) -> String:
	if p.x >= 45.0 and p.z >= 25.0 and p.z <= 46.0:
		return "Portería"
	if p.x >= 21.5 and p.x <= 30.8 and p.z >= 29.0 and p.z <= 38.5:
		return "Sala de Reuniones"
	if p.x >= 11.5 and p.x <= 44.5 and p.z >= 20.5 and p.z <= 51.5:
		return "Oficinas Administrativas"
	if p.x >= -18.0 and p.x <= -12.6 and p.z >= 44.6 and p.z <= 50.2:
		return "Vestidores EPP"
	if p.x >= -21.8 and p.x <= -19.2 and p.z >= 37.0 and p.z <= 40.0:
		return "Tablero CCM 460 V"
	if p.x >= -22.2 and p.x <= -19.4 and p.z >= 41.2 and p.z <= 44.0:
		return "Esclusa Norte"
	if p.x >= -19.65 and p.x <= -17.70 and p.z >= 23.5 and p.z <= 49.4:
		return "Pasillo Peatonal"
	if p.x >= -29.2 and p.x <= -22.5 and p.z >= 44.6 and p.z <= 49.4:
		return "Tolva de Recepción"
	if p.x >= -30.8 and p.x <= -20.5 and p.z >= 35.2 and p.z <= 44.6:
		return "Zona de Molienda 10 HP"
	if p.x >= -30.8 and p.x <= -20.5 and p.z >= 29.2 and p.z <= 35.2:
		return "Ciclones y Secado ATEX"
	if p.x >= -30.8 and p.x <= -20.5 and p.z >= 23.5 and p.z <= 29.2:
		return "Almacén de Sacos"
	if p.x >= -31.2 and p.x <= -18.0 and p.z >= 20.5 and p.z <= 23.5:
		return "Rampa Sur"
	if p.x >= -31.2 and p.x <= -18.0 and p.z >= 23.5 and p.z <= 49.5:
		return "Nave de Producción"
	if p.x >= -41.2 and p.x <= -31.2 and p.z >= 27.5 and p.z <= 40.5:
		return "Zona de Aire y Térmica"
	if p.x >= -33.0 and p.x <= -26.8 and p.z >= 49.2 and p.z <= 54.0:
		return "Bandas de Descarga"
	if p.x >= -42.5 and p.x <= -33.0 and p.z >= 49.5 and p.z <= 56.5:
		return "Bahía de Despacho"
	if p.x >= -26.8 and p.x <= -11.0 and p.z >= 49.5 and p.z <= 55.2:
		return "Bahía Norte"
	if p.z >= 52.0:
		return "Patio Norte"
	return "Patio Exterior"

func _update_realtime_location(delta: float) -> void:
	_location_poll_timer += delta
	if _location_poll_timer < 0.18:
		return
	_location_poll_timer = 0.0
	if not is_inside_tree() or _location_label == null:
		return
	if _location_player_ref == null or not is_instance_valid(_location_player_ref):
		_location_player_ref = get_tree().root.find_child("PlayerOperator", true, false) as Node3D
	if _location_player_ref == null:
		return
	var loc := resolve_plant_location(_location_player_ref.global_position)
	if loc != _last_location_name:
		_last_location_name = loc
		_location_label.text = loc

func get_current_location_label() -> String:
	return _location_label.text if _location_label != null else ""

func _setup_controls_tips_card() -> void:
	# Columna maestra abajo-derecha: agrupa alertas/notificaciones arriba y tarjeta de Controles abajo para hacer físicamente imposible cualquier solape
	_bottom_right_column = VBoxContainer.new()
	_bottom_right_column.name = "BottomRightColumn"
	_bottom_right_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom_right_column.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_bottom_right_column.anchor_left = 1.0
	_bottom_right_column.anchor_right = 1.0
	_bottom_right_column.anchor_top = 1.0
	_bottom_right_column.anchor_bottom = 1.0
	_bottom_right_column.offset_left = -304.0
	_bottom_right_column.offset_right = -14.0
	_bottom_right_column.offset_top = -540.0
	_bottom_right_column.offset_bottom = -12.0
	_bottom_right_column.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_bottom_right_column.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bottom_right_column.alignment = BoxContainer.ALIGNMENT_END
	_bottom_right_column.add_theme_constant_override("separation", 8)
	add_child(_bottom_right_column)

	_controls_tips_card = PanelContainer.new()
	_controls_tips_card.name = "ControlsTipsCard"
	_controls_tips_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls_tips_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.04, 0.07, 0.12, 0.64)
	st.border_color = Color(0.24, 0.42, 0.58, 0.40)
	st.set_border_width_all(1)
	st.set_corner_radius_all(7)
	st.content_margin_left = 10.0
	st.content_margin_right = 10.0
	st.content_margin_top = 6.0
	st.content_margin_bottom = 6.0
	_controls_tips_card.add_theme_stylebox_override("panel", st)
	_bottom_right_column.add_child(_controls_tips_card)

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 2)
	_controls_tips_card.add_child(vb)

	var hdr := Label.new()
	hdr.name = "ControlsTipsHeader"
	hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hdr.text = "Controles"
	hdr.add_theme_font_size_override("font_size", 10)
	hdr.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0, 0.92))
	vb.add_child(hdr)

	var rtl := RichTextLabel.new()
	rtl.name = "ControlsTipsBody"
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.add_theme_font_size_override("normal_font_size", 10)
	rtl.add_theme_font_size_override("bold_font_size", 10)
	rtl.add_theme_color_override("default_color", Color(0.84, 0.90, 0.96, 0.88))
	rtl.text = (
		"[color=#7ee8c0][b]WASD[/b][/color] Mover  |  [color=#7ee8c0][b]Shift[/b][/color] Correr  |  [color=#7ee8c0][b]Espacio[/b][/color] Saltar\n"
		+ "[color=#7ee8c0][b]E / Clic[/b][/color] Interactuar  |  [color=#7ee8c0][b]1-5 / Rueda[/b][/color] Herramientas\n"
		+ "[color=#7ee8c0][b]TAB[/b][/color] Tablet  |  [color=#7ee8c0][b]F11[/b][/color] Pantalla"
	)
	vb.add_child(rtl)

func _setup_notification_stack() -> void:
	# Contenedor único encima de la tarjeta de Controles dentro de BottomRightColumn (imposible superposición en cualquier resolución)
	_bottom_right_dock = VBoxContainer.new()
	_bottom_right_dock.name = "BottomRightAlertsDock"
	_bottom_right_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom_right_dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bottom_right_dock.alignment = BoxContainer.ALIGNMENT_END
	_bottom_right_dock.add_theme_constant_override("separation", 6)
	if _bottom_right_column != null:
		_bottom_right_column.add_child(_bottom_right_dock)
		_bottom_right_column.move_child(_bottom_right_dock, 0)
	else:
		add_child(_bottom_right_dock)

	_notification_stack = VBoxContainer.new()
	_notification_stack.name = "NotificationStack"
	_notification_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notification_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_notification_stack.alignment = BoxContainer.ALIGNMENT_END
	_notification_stack.add_theme_constant_override("separation", 6)
	_bottom_right_dock.add_child(_notification_stack)

func _sanitize_plain_text(raw: String) -> String:
	var s := raw.strip_edges()
	# Eliminar símbolos/emojis decorativos para mantener notificaciones 100% texto limpio
	var stripped := ""
	for i in range(s.length()):
		var ch := s[i]
		var code := s.unicode_at(i)
		# Conservar ASCII imprimible y caracteres latinos acentuados / signos de puntuación españoles (¿¡°·•–—)
		if (code >= 32 and code <= 126) or (code >= 160 and code <= 255) or code in [0x2013, 0x2014]:
			stripped += ch
		elif code == 0x2022 or code == 0x00B7:
			stripped += "-"
	while "  " in stripped:
		stripped = stripped.replace("  ", " ")
	return stripped.strip_edges()

func _sanitize_multiline_text(raw: String) -> String:
	var lines := raw.replace("\r\n", "\n").replace("\r", "\n").split("\n")
	var out: Array[String] = []
	for ln in lines:
		var s := ln.strip_edges()
		if s == "":
			out.append("")
			continue
		var stripped := ""
		for i in range(s.length()):
			var ch := s[i]
			var code := s.unicode_at(i)
			if (code >= 32 and code <= 126) or (code >= 160 and code <= 255) or code in [0x2013, 0x2014, 0x2022]:
				stripped += ch
		while "  " in stripped:
			stripped = stripped.replace("  ", " ")
		out.append(stripped.strip_edges())
	return "\n".join(out).strip_edges()

func _normalize_alert_key(raw: String) -> String:
	var s := _sanitize_plain_text(raw).to_lower()
	for rep in ["-", "_", ":", ".", ",", ";", "!", "?", "(", ")", "[", "]", "/"]:
		s = s.replace(rep, " ")
	s = s.replace("á", "a").replace("é", "e").replace("í", "i").replace("ó", "o").replace("ú", "u").replace("ñ", "n")
	while "  " in s:
		s = s.replace("  ", " ")
	return s.strip_edges()

func _compact_text(txt: String, max_len: int) -> String:
	var clean := _sanitize_plain_text(txt)
	if clean.length() <= max_len:
		return clean
	return clean.substr(0, max_len - 3).strip_edges() + "..."

func get_notification_seq() -> int:
	return _notification_seq

func _has_visible_alert_with_key(norm_key: String) -> bool:
	if norm_key == "":
		return false
	if _safety_line_banner != null and _safety_line_banner.visible and _last_safety_line_key == norm_key:
		return true
	for entry in _notification_entries:
		if str(entry.get("norm_key", "")) == norm_key:
			return true
	return false

func _refresh_tablet_legend_redundancy() -> void:
	if _tablet_notify_detail == null or _tablet_notify_legend == null or not _tablet_notify_legend.visible:
		return
	var is_duplicated := _has_visible_alert_with_key(_last_tablet_warning_key)
	_tablet_notify_detail.text = _last_tablet_warning_title
	_tablet_notify_detail.visible = (not is_duplicated) and (_last_tablet_warning_title != "")
	_tablet_notify_legend.reset_size()
	if _bottom_right_dock != null:
		_bottom_right_dock.queue_sort()
	if _bottom_right_column != null:
		_bottom_right_column.queue_sort()

func _push_stacked_notification(title: String, message: String, severity: String) -> void:
	if _notification_stack == null:
		return
	var clean_title := _compact_text(title, 36)
	var clean_msg := _compact_text(message, 68)
	if clean_title == "" and clean_msg == "":
		return
	var norm_key := _normalize_alert_key(clean_title)
	var norm_msg := _normalize_alert_key(clean_msg)

	# Evitar duplicar una alerta de línea de seguridad que ya está fija en la parte inferior derecha
	if _safety_line_banner != null and _safety_line_banner.visible and norm_key != "" and norm_key == _last_safety_line_key:
		_refresh_tablet_legend_redundancy()
		return

	# Deduplicar si la misma notificación (por título normalizado o mensaje idéntico) ya está activa
	for idx in range(_notification_entries.size()):
		var entry: Dictionary = _notification_entries[idx]
		var same_title := (norm_key != "" and str(entry.get("norm_key", "")) == norm_key)
		var same_msg := (norm_msg != "" and str(entry.get("norm_msg", "")) == norm_msg)
		if same_title or same_msg:
			var card_e := entry["card"] as PanelContainer
			var msg_lbl := entry["msg_lbl"] as Label
			if card_e != null and is_instance_valid(card_e):
				if msg_lbl != null:
					msg_lbl.text = clean_msg
					msg_lbl.visible = (clean_msg != "")
				card_e.modulate = Color.WHITE
				entry["ttl"] = NOTIFICATION_DURATION_S
				entry["norm_msg"] = norm_msg
				_notification_stack.move_child(card_e, _notification_stack.get_child_count() - 1)
				_notification_entries.remove_at(idx)
				_notification_entries.append(entry)
				_refresh_tablet_legend_redundancy()
				return

	# Limitar pila para evitar saturación visual (retirar la más antigua arriba)
	while _notification_entries.size() >= MAX_STACKED_NOTIFICATIONS:
		var oldest: Dictionary = _notification_entries.pop_front()
		var old_card := oldest.get("card") as Node
		if old_card != null and is_instance_valid(old_card):
			old_card.queue_free()

	var accent := Color(0.26, 0.78, 0.96, 0.95)
	var bg := Color(0.05, 0.08, 0.13, 0.82)
	var sev_l := severity.to_lower()
	if sev_l == "error" or sev_l == "critical":
		accent = Color(0.95, 0.30, 0.28, 0.98)
		bg = Color(0.14, 0.05, 0.06, 0.88)
	elif sev_l == "warning":
		accent = Color(0.98, 0.74, 0.18, 0.96)
		bg = Color(0.12, 0.09, 0.04, 0.86)

	var card := PanelContainer.new()
	card.name = "NotifCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_width_left = 3
	st.border_width_top = 1
	st.border_width_right = 1
	st.border_width_bottom = 1
	st.border_color = accent
	st.set_corner_radius_all(6)
	st.content_margin_left = 9.0
	st.content_margin_right = 9.0
	st.content_margin_top = 5.0
	st.content_margin_bottom = 5.0
	card.add_theme_stylebox_override("panel", st)

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 1)
	card.add_child(vb)

	var t_lbl := Label.new()
	t_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t_lbl.text = clean_title
	t_lbl.clip_text = true
	t_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t_lbl.add_theme_font_size_override("font_size", 11)
	t_lbl.add_theme_color_override("font_color", accent)
	vb.add_child(t_lbl)

	var m_lbl := Label.new()
	m_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m_lbl.text = clean_msg
	m_lbl.visible = (clean_msg != "")
	m_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	m_lbl.add_theme_font_size_override("font_size", 10)
	m_lbl.add_theme_color_override("font_color", Color(0.90, 0.94, 0.98, 0.94))
	vb.add_child(m_lbl)

	# Añadir al final del VBoxContainer con alignment=END coloca siempre la más actual abajo
	_notification_stack.add_child(card)
	_notification_entries.append({
		"key": clean_title,
		"norm_key": norm_key,
		"norm_msg": norm_msg,
		"card": card,
		"msg_lbl": m_lbl,
		"ttl": NOTIFICATION_DURATION_S
	})
	_refresh_tablet_legend_redundancy()

func _update_notification_stack(delta: float) -> void:
	if _notification_entries.is_empty():
		return
	var removed_any := false
	var i := _notification_entries.size() - 1
	while i >= 0:
		var entry: Dictionary = _notification_entries[i]
		var card := entry.get("card") as PanelContainer
		if card == null or not is_instance_valid(card):
			_notification_entries.remove_at(i)
			removed_any = true
			i -= 1
			continue
		var ttl: float = float(entry.get("ttl", 0.0)) - delta
		entry["ttl"] = ttl
		if ttl <= 0.0:
			card.queue_free()
			_notification_entries.remove_at(i)
			removed_any = true
		elif ttl < NOTIFICATION_FADE_S:
			card.modulate = Color(1.0, 1.0, 1.0, clampf(ttl / NOTIFICATION_FADE_S, 0.0, 1.0))
		i -= 1
	if removed_any:
		_refresh_tablet_legend_redundancy()

func get_active_notification_count() -> int:
	return _notification_entries.size()

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
			"Carlos Mendoza (Supervisor SST):",
			"Perfecto, ya quedaste bien equipado con tu protección. Ahora vamos a la zona de carga para empezar el recorrido máquina por máquina.",
			5.0
		)
	elif _dialogue_panel != null and not _dialogue_keep_open:
		_dialogue_panel.visible = false

func show_npc_dialogue(speaker: String, dialogue_text: String, duration: float = 7.5) -> void:
	if _dialogue_panel == null:
		return
	var clean_spk := _sanitize_plain_text(speaker)
	if clean_spk != "" and not clean_spk.ends_with(":"):
		clean_spk += ":"
	if _dialogue_speaker != null:
		_dialogue_speaker.text = clean_spk
	if _dialogue_body != null:
		_dialogue_body.text = _sanitize_plain_text(dialogue_text)
	_dialogue_panel.visible = true
	_dialogue_timer = duration

func set_dialogue_choices(options: Array, active_id: String, asked_ids: Array, callback: Callable) -> void:
	if _dialogue_choices_row == null:
		return
	_dialogue_choice_entries.clear()
	_dialogue_choice_cb = callback
	for ch in _dialogue_choices_row.get_children():
		_dialogue_choices_row.remove_child(ch)
		ch.queue_free()
	if options.is_empty():
		_dialogue_choices_row.visible = false
		_dialogue_keep_open = false
		return
	_dialogue_keep_open = true
	_dialogue_choices_row.visible = true
	for opt_v in options:
		var opt: Dictionary = opt_v
		var tid: String = str(opt.get("id", ""))
		var knum: int = int(opt.get("key_num", 0))
		var lbl_txt: String = str(opt.get("label", tid))
		var is_active: bool = (tid == active_id)
		var is_asked: bool = asked_ids.has(tid)
		_dialogue_choice_entries.append({"id": tid, "key_num": knum})

		var btn := Button.new()
		btn.name = "Choice_" + tid
		btn.text = "%d  %s" % [knum, lbl_txt]
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 11)
		var is_continue: bool = (tid == "__continue__")
		var bg := Color(0.08, 0.42, 0.28, 0.96) if is_continue else (Color(0.08, 0.34, 0.44, 0.94) if is_active else (Color(0.07, 0.11, 0.16, 0.72) if is_asked else Color(0.08, 0.14, 0.22, 0.90)))
		var bd := Color(0.28, 0.92, 0.65, 0.98) if is_continue else (Color(0.32, 0.90, 1.0, 0.98) if is_active else (Color(0.32, 0.42, 0.52, 0.55) if is_asked else Color(0.45, 0.78, 0.95, 0.78)))
		var fg := Color(1.0, 1.0, 1.0, 1.0) if (is_continue or is_active) else (Color(0.62, 0.70, 0.78, 0.85) if is_asked else Color(0.92, 0.96, 1.0, 0.96))
		var st := StyleBoxFlat.new()
		st.bg_color = bg
		st.border_color = bd
		st.set_border_width_all(1)
		st.set_corner_radius_all(5)
		st.content_margin_left = 10.0
		st.content_margin_right = 10.0
		st.content_margin_top = 3.0
		st.content_margin_bottom = 3.0
		btn.add_theme_stylebox_override("normal", st)
		btn.add_theme_stylebox_override("hover", st)
		btn.add_theme_color_override("font_color", fg)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.pressed.connect(func():
			if _dialogue_choice_cb.is_valid():
				_dialogue_choice_cb.call(tid)
		)
		_dialogue_choices_row.add_child(btn)
	if _dialogue_panel != null:
		_dialogue_panel.visible = true

func clear_dialogue_choices() -> void:
	_dialogue_keep_open = false
	_dialogue_choice_entries.clear()
	_dialogue_choice_cb = Callable()
	if _dialogue_choices_row != null:
		_dialogue_choices_row.visible = false
		for ch in _dialogue_choices_row.get_children():
			_dialogue_choices_row.remove_child(ch)
			ch.queue_free()
	if _dialogue_panel != null:
		_dialogue_panel.visible = false

func reset_dialogue_ui() -> void:
	clear_dialogue_choices()
	_dialogue_timer = 0.0
	if _dialogue_speaker != null:
		_dialogue_speaker.text = ""
	if _dialogue_body != null:
		_dialogue_body.text = ""
	if briefing_overlay != null and briefing_overlay.visible:
		briefing_overlay.visible = false
	if _course_modal != null and is_instance_valid(_course_modal) and _course_modal.visible:
		_course_modal.visible = false

func _setup_dialogue_panel() -> void:
	_dialogue_panel = PanelContainer.new()
	_dialogue_panel.name = "DialoguePanel"
	_dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_panel.visible = false
	_dialogue_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_dialogue_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_dialogue_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_dialogue_panel.offset_left = 410.0
	_dialogue_panel.offset_right = -410.0
	_dialogue_panel.offset_bottom = -152.0
	_dialogue_panel.offset_top = -214.0
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.04, 0.07, 0.12, 0.86)
	st.border_color = Color(0.28, 0.55, 0.78, 0.65)
	st.set_border_width_all(1)
	st.set_corner_radius_all(8)
	st.content_margin_left = 14.0
	st.content_margin_right = 14.0
	st.content_margin_top = 8.0
	st.content_margin_bottom = 8.0
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
	_dialogue_speaker.add_theme_font_size_override("font_size", 12)
	_dialogue_speaker.add_theme_color_override("font_color", Color(0.98, 0.84, 0.36, 1.0))
	vbox.add_child(_dialogue_speaker)

	_dialogue_body = Label.new()
	_dialogue_body.name = "DialogueBody"
	_dialogue_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dialogue_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dialogue_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_body.add_theme_font_size_override("font_size", 14)
	_dialogue_body.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 1.0))
	vbox.add_child(_dialogue_body)

	_dialogue_choices_row = HBoxContainer.new()
	_dialogue_choices_row.name = "DialogueChoicesRow"
	_dialogue_choices_row.visible = false
	_dialogue_choices_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_choices_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_dialogue_choices_row.add_theme_constant_override("separation", 8)
	vbox.add_child(_dialogue_choices_row)

func _setup_tablet_notify_legend() -> void:
	_tablet_notify_legend = PanelContainer.new()
	_tablet_notify_legend.name = "TabletNotifyLegend"
	_tablet_notify_legend.visible = false
	_tablet_notify_legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tablet_notify_legend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _bottom_right_dock != null:
		_bottom_right_dock.add_child(_tablet_notify_legend)
	else:
		add_child(_tablet_notify_legend)

	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 6)
	_tablet_notify_legend.add_child(hb)

	_tablet_notify_badge = PanelContainer.new()
	_tablet_notify_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tablet_notify_badge.visible = false
	_tablet_notify_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(_tablet_notify_badge)

	_tablet_notify_badge_lbl = Label.new()
	_tablet_notify_badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tablet_notify_badge_lbl.text = ""
	_tablet_notify_badge_lbl.add_theme_font_size_override("font_size", 10)
	_tablet_notify_badge.add_child(_tablet_notify_badge_lbl)

	var txt_vb := VBoxContainer.new()
	txt_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	txt_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt_vb.add_theme_constant_override("separation", 1)
	hb.add_child(txt_vb)

	_tablet_notify_title = Label.new()
	_tablet_notify_title.name = "TabletLegendTitle"
	_tablet_notify_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tablet_notify_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_tablet_notify_title.text = "Nueva alerta en tablet"
	_tablet_notify_title.add_theme_font_size_override("font_size", 11)
	_tablet_notify_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.30, 1.0))
	txt_vb.add_child(_tablet_notify_title)

	_tablet_notify_detail = Label.new()
	_tablet_notify_detail.name = "TabletLegendDetail"
	_tablet_notify_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tablet_notify_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_tablet_notify_detail.text = ""
	_tablet_notify_detail.clip_text = true
	_tablet_notify_detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_tablet_notify_detail.add_theme_font_size_override("font_size", 10)
	_tablet_notify_detail.add_theme_color_override("font_color", Color(0.92, 0.95, 0.99, 0.95))
	txt_vb.add_child(_tablet_notify_detail)
	_apply_tablet_legend_style(false)

func _apply_tablet_legend_style(is_crit: bool) -> void:
	if _tablet_notify_legend == null:
		return
	var accent := Color(0.95, 0.30, 0.28, 0.98) if is_crit else Color(0.98, 0.72, 0.16, 0.96)
	var bg := Color(0.15, 0.04, 0.05, 0.90) if is_crit else Color(0.12, 0.09, 0.03, 0.88)
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_width_left = 3
	st.border_width_top = 1
	st.border_width_right = 1
	st.border_width_bottom = 1
	st.border_color = accent
	st.set_corner_radius_all(6)
	st.content_margin_left = 9.0
	st.content_margin_right = 9.0
	st.content_margin_top = 5.0
	st.content_margin_bottom = 5.0
	_tablet_notify_legend.add_theme_stylebox_override("panel", st)

	var bst := StyleBoxFlat.new()
	bst.bg_color = Color(0.45, 0.08, 0.08, 1.0) if is_crit else Color(0.38, 0.22, 0.03, 1.0)
	bst.border_color = accent
	bst.set_border_width_all(1)
	bst.set_corner_radius_all(5)
	bst.content_margin_left = 6.0
	bst.content_margin_right = 6.0
	bst.content_margin_top = 2.0
	bst.content_margin_bottom = 2.0
	_tablet_notify_badge.add_theme_stylebox_override("panel", bst)
	_tablet_notify_badge_lbl.add_theme_color_override("font_color", accent)
	_tablet_notify_title.add_theme_color_override("font_color", accent)

func _on_tablet_warning_received(warning_data: Dictionary) -> void:
	if _tablet_notify_legend == null:
		return
	var sev := str(warning_data.get("severity", "WARNING"))
	_tablet_notify_is_crit = (sev == "CRITICAL")
	_apply_tablet_legend_style(_tablet_notify_is_crit)
	var unread := maxi(1, int(warning_data.get("unread_count", 1)))
	_tablet_notify_title.text = "Nueva alerta en tablet" if unread <= 1 else "%d alertas en tablet" % unread
	_last_tablet_warning_title = _compact_text(str(warning_data.get("title", "")), 40)
	_last_tablet_warning_key = _normalize_alert_key(_last_tablet_warning_title)
	_tablet_notify_pulse_t = 0.0
	_tablet_notify_legend.modulate = Color.WHITE
	_tablet_notify_legend.visible = true
	_refresh_tablet_legend_redundancy()

func _on_tablet_notifications_cleared() -> void:
	_last_tablet_warning_key = ""
	_last_tablet_warning_title = ""
	if _tablet_notify_legend != null:
		_tablet_notify_legend.visible = false

func _setup_safety_line_banner() -> void:
	_safety_line_banner = PanelContainer.new()
	_safety_line_banner.name = "SafetyLineAlertBanner"
	_safety_line_banner.visible = false
	_safety_line_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safety_line_banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.20, 0.04, 0.04, 0.92)
	st.border_width_left = 3
	st.border_width_top = 1
	st.border_width_right = 1
	st.border_width_bottom = 1
	st.border_color = Color(1.0, 0.22, 0.18, 1.0)
	st.set_corner_radius_all(6)
	st.content_margin_left = 9.0
	st.content_margin_right = 9.0
	st.content_margin_top = 5.0
	st.content_margin_bottom = 5.0
	_safety_line_banner.add_theme_stylebox_override("panel", st)
	if _bottom_right_dock != null:
		_bottom_right_dock.add_child(_safety_line_banner)
	else:
		add_child(_safety_line_banner)

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 1)
	_safety_line_banner.add_child(vb)

	_safety_line_title = Label.new()
	_safety_line_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safety_line_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_safety_line_title.clip_text = true
	_safety_line_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_safety_line_title.add_theme_font_size_override("font_size", 11)
	_safety_line_title.add_theme_color_override("font_color", Color(1.0, 0.36, 0.32, 1.0))
	_safety_line_title.text = "LINEA DE SEGURIDAD"
	vb.add_child(_safety_line_title)

	_safety_line_detail = Label.new()
	_safety_line_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safety_line_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_safety_line_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_safety_line_detail.add_theme_font_size_override("font_size", 10)
	_safety_line_detail.add_theme_color_override("font_color", Color(1.0, 0.94, 0.90, 0.96))
	_safety_line_detail.text = "Retrocede a zona segura."
	vb.add_child(_safety_line_detail)

func _on_safety_line_crossed(active: bool, _zone_id: String, title: String, message: String) -> void:
	if _safety_line_banner == null:
		return
	_safety_line_banner.visible = active
	if active:
		var clean_t := _compact_text(title, 38)
		var clean_m := _compact_text(message, 84)
		_last_safety_line_key = _normalize_alert_key(clean_t)
		if _safety_line_title != null and clean_t != "":
			_safety_line_title.text = clean_t
		if _safety_line_detail != null and clean_m != "":
			_safety_line_detail.text = clean_m
		# Retirar cualquier tarjeta redundante en NotificationStack con el mismo título de zona
		var idx := _notification_entries.size() - 1
		while idx >= 0:
			var entry: Dictionary = _notification_entries[idx]
			if str(entry.get("norm_key", "")) == _last_safety_line_key:
				var old_c := entry.get("card") as Node
				if old_c != null and is_instance_valid(old_c):
					old_c.queue_free()
				_notification_entries.remove_at(idx)
			idx -= 1
		_safety_line_pulse_t = 0.0
		_safety_line_banner.modulate = Color.WHITE
	else:
		_last_safety_line_key = ""
	_refresh_tablet_legend_redundancy()

func is_safety_line_alert_visible() -> bool:
	return _safety_line_banner != null and _safety_line_banner.visible

func _setup_fixed_crosshair() -> void:
	var reticle := get_node_or_null("Reticle") as Control
	if reticle == null:
		return
	if reticle_dot != null:
		reticle_dot.visible = false
	var old_cross := reticle.get_node_or_null("CrosshairFixed")
	if old_cross != null:
		old_cross.queue_free()

	var cross := Control.new()
	cross.name = "CrosshairFixed"
	cross.custom_minimum_size = Vector2(18, 18)
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reticle.add_child(cross)

	# Borde fino negro (1 px) alrededor de toda la cruz blanca sin cortar la intersección central
	var parts: Array[Dictionary] = [
		{"name": "OutlineH", "pos": Vector2(1, 7), "sz": Vector2(16, 4), "col": Color(0.0, 0.0, 0.0, 0.92)},
		{"name": "OutlineV", "pos": Vector2(7, 1), "sz": Vector2(4, 16), "col": Color(0.0, 0.0, 0.0, 0.92)},
		{"name": "BarH",     "pos": Vector2(2, 8), "sz": Vector2(14, 2), "col": Color(1.0, 1.0, 1.0, 1.0)},
		{"name": "BarV",     "pos": Vector2(8, 2), "sz": Vector2(2, 14), "col": Color(1.0, 1.0, 1.0, 1.0)},
	]
	for p in parts:
		var r := ColorRect.new()
		r.name = str(p["name"])
		r.position = p["pos"] as Vector2
		r.size = p["sz"] as Vector2
		r.color = p["col"] as Color
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cross.add_child(r)

func _on_prompt_updated(txt: String) -> void:
	var low := txt.to_lower()
	var is_fault := "reparar falla" in low or "[falla]" in low or "para reparar" in low or "detén las máquinas" in low
	var is_green_sel := (txt != "" and not is_fault)
	# La cruz central es siempre blanca con borde fino negro y nunca cambia de color
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
	_notification_seq += 1
	if toast_panel != null:
		toast_panel.visible = false
	if toast_title != null:
		toast_title.text = _compact_text(title, 36)
	if toast_msg != null:
		toast_msg.text = _compact_text(message, 68)
	_push_stacked_notification(title, message, severity)

func is_briefing_visible() -> bool:
	return briefing_overlay != null and briefing_overlay.visible

func show_briefing_panel(title: String, greeting: String, resume_tour_on_close: bool = true) -> void:
	if briefing_overlay == null:
		return
	_briefing_resume_tour = resume_tour_on_close
	_briefing_opened_ms = Time.get_ticks_msec()
	var is_long_info := (not resume_tour_on_close) and greeting.length() > 140
	var b_card := briefing_overlay.find_child("BriefingCard", true, false) as PanelContainer
	if b_card != null:
		b_card.custom_minimum_size = Vector2(680, 0) if is_long_info else Vector2(460, 0)
	if _briefing_title != null:
		_briefing_title.text = (
			"Bienvenido a Agromolinos del Valle"
			if resume_tour_on_close
			else _sanitize_plain_text(title)
		)
	var clean_multi := _sanitize_multiline_text(greeting)
	if _briefing_greeting != null:
		_briefing_greeting.text = (
			"¿Deseas realizar el curso SST?"
			if resume_tour_on_close
			else clean_multi
		)
		_briefing_greeting.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if is_long_info else HORIZONTAL_ALIGNMENT_CENTER
		_briefing_greeting.add_theme_font_size_override("font_size", 14 if is_long_info else 15)
		_briefing_greeting.add_theme_constant_override("line_spacing", 5 if is_long_info else 3)
	var built_sections := false
	if _briefing_sections_box != null:
		for ch in _briefing_sections_box.get_children():
			ch.queue_free()
		if is_long_info and clean_multi.contains("\n"):
			built_sections = _populate_briefing_sections(clean_multi)
		_briefing_sections_box.visible = built_sections
	if _briefing_greeting != null:
		_briefing_greeting.visible = not built_sections
	if _btn_course_sst != null:
		_btn_course_sst.visible = resume_tour_on_close
		_btn_course_sst.text = "Sí"
	if _btn_close_briefing != null:
		_btn_close_briefing.text = "No" if resume_tour_on_close else ("Comenzar operación" if is_long_info else "Continuar")
	if _btn_skip_briefing != null:
		_btn_skip_briefing.visible = resume_tour_on_close
		_btn_skip_briefing.text = "Saltar tutorial"
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
	card.custom_minimum_size = Vector2(460, 0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", _build_briefing_panel_style())
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	_briefing_title = Label.new()
	_briefing_title.name = "BriefingTitle"
	_briefing_title.text = "Bienvenido a Agromolinos del Valle"
	_briefing_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_briefing_title.add_theme_font_size_override("font_size", 21)
	_briefing_title.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 1.0))
	vbox.add_child(_briefing_title)

	_briefing_greeting = Label.new()
	_briefing_greeting.name = "BriefingGreeting"
	_briefing_greeting.text = "¿Deseas realizar el curso SST?"
	_briefing_greeting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_briefing_greeting.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_briefing_greeting.add_theme_font_size_override("font_size", 15)
	_briefing_greeting.add_theme_color_override("font_color", Color(0.84, 0.90, 0.96, 1.0))
	vbox.add_child(_briefing_greeting)

	_briefing_sections_box = VBoxContainer.new()
	_briefing_sections_box.name = "BriefingSectionsBox"
	_briefing_sections_box.visible = false
	_briefing_sections_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_briefing_sections_box.add_theme_constant_override("separation", 10)
	vbox.add_child(_briefing_sections_box)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(footer)

	_btn_course_sst = Button.new()
	_btn_course_sst.name = "BtnCourseSST"
	_btn_course_sst.text = "Sí"
	_btn_course_sst.custom_minimum_size = Vector2(115, 38)
	_btn_course_sst.mouse_filter = Control.MOUSE_FILTER_STOP
	_btn_course_sst.add_theme_font_size_override("font_size", 13)
	_btn_course_sst.add_theme_stylebox_override("normal", _build_briefing_button_style(Color(0.06, 0.34, 0.44, 1.0), Color(0.24, 0.88, 0.98, 1.0)))
	_btn_course_sst.add_theme_stylebox_override("hover", _build_briefing_button_style(Color(0.10, 0.46, 0.58, 1.0), Color(0.45, 0.96, 1.0, 1.0)))
	_btn_course_sst.add_theme_stylebox_override("focus", _build_briefing_button_style(Color(0.08, 0.40, 0.52, 1.0), Color(0.45, 0.96, 1.0, 1.0)))
	_btn_course_sst.pressed.connect(func(): close_briefing_panel_with_choice(true))
	footer.add_child(_btn_course_sst)

	_btn_close_briefing = Button.new()
	_btn_close_briefing.name = "BtnStartTour"
	_btn_close_briefing.text = "No"
	_btn_close_briefing.custom_minimum_size = Vector2(115, 38)
	_btn_close_briefing.mouse_filter = Control.MOUSE_FILTER_STOP
	_btn_close_briefing.add_theme_font_size_override("font_size", 13)
	_btn_close_briefing.add_theme_stylebox_override("normal", _build_briefing_button_style(Color(0.08, 0.45, 0.34, 1.0), Color(0.25, 0.95, 0.65, 1.0)))
	_btn_close_briefing.add_theme_stylebox_override("hover", _build_briefing_button_style(Color(0.12, 0.58, 0.42, 1.0), Color(0.45, 1.0, 0.75, 1.0)))
	_btn_close_briefing.add_theme_stylebox_override("focus", _build_briefing_button_style(Color(0.10, 0.52, 0.38, 1.0), Color(0.45, 1.0, 0.75, 1.0)))
	_btn_close_briefing.pressed.connect(close_briefing_panel)
	footer.add_child(_btn_close_briefing)

	_btn_skip_briefing = Button.new()
	_btn_skip_briefing.name = "BtnSkipTutorial"
	_btn_skip_briefing.text = "Saltar tutorial"
	_btn_skip_briefing.custom_minimum_size = Vector2(145, 38)
	_btn_skip_briefing.mouse_filter = Control.MOUSE_FILTER_STOP
	_btn_skip_briefing.add_theme_font_size_override("font_size", 12)
	_btn_skip_briefing.add_theme_stylebox_override("normal", _build_briefing_button_style(Color(0.32, 0.20, 0.06, 1.0), Color(0.98, 0.72, 0.22, 1.0)))
	_btn_skip_briefing.add_theme_stylebox_override("hover", _build_briefing_button_style(Color(0.45, 0.28, 0.08, 1.0), Color(1.0, 0.84, 0.38, 1.0)))
	_btn_skip_briefing.add_theme_stylebox_override("focus", _build_briefing_button_style(Color(0.40, 0.24, 0.07, 1.0), Color(1.0, 0.84, 0.38, 1.0)))
	_btn_skip_briefing.pressed.connect(_on_skip_tutorial_pressed)
	footer.add_child(_btn_skip_briefing)

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

func _populate_briefing_sections(clean_multi: String) -> bool:
	if _briefing_sections_box == null:
		return false
	var sections: Array[Dictionary] = []
	var cur_sec: Dictionary = {}
	for raw_ln in clean_multi.split("\n"):
		var ln := raw_ln.strip_edges()
		if ln == "":
			continue
		if ln.ends_with(":") and ln.length() <= 36 and ln == ln.to_upper():
			if not cur_sec.is_empty():
				sections.append(cur_sec)
			cur_sec = {"title": ln.trim_suffix(":"), "items": []}
		else:
			if cur_sec.is_empty():
				cur_sec = {"title": "", "items": []}
			(cur_sec["items"] as Array).append(ln)
	if not cur_sec.is_empty():
		sections.append(cur_sec)
	if sections.size() < 2:
		return false

	var accents: Array[Color] = [
		Color(0.24, 0.80, 0.98, 1.0),
		Color(0.98, 0.74, 0.22, 1.0),
		Color(0.20, 0.86, 0.58, 1.0)
	]
	for s_idx in range(sections.size()):
		var sec: Dictionary = sections[s_idx]
		var col: Color = accents[s_idx % accents.size()]
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.03, 0.06, 0.11, 0.90)
		st.border_color = Color(col.r, col.g, col.b, 0.62)
		st.border_width_left = 3
		st.border_width_top = 1
		st.border_width_right = 1
		st.border_width_bottom = 1
		st.set_corner_radius_all(7)
		st.content_margin_left = 14.0
		st.content_margin_right = 14.0
		st.content_margin_top = 10.0
		st.content_margin_bottom = 10.0
		card.add_theme_stylebox_override("panel", st)
		_briefing_sections_box.add_child(card)

		var svb := VBoxContainer.new()
		svb.add_theme_constant_override("separation", 6)
		card.add_child(svb)

		var stitle := str(sec.get("title", ""))
		if stitle != "":
			var hl := Label.new()
			hl.text = stitle
			hl.add_theme_font_size_override("font_size", 12)
			hl.add_theme_color_override("font_color", col)
			svb.add_child(hl)

		for it in (sec.get("items", []) as Array):
			var il := Label.new()
			il.text = str(it)
			il.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			il.add_theme_font_size_override("font_size", 13)
			il.add_theme_constant_override("line_spacing", 3)
			il.add_theme_color_override("font_color", Color(0.89, 0.93, 0.98, 1.0))
			svb.add_child(il)
	return true

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
	_btn_skip_hud.text = "Saltar tutorial"
	_btn_skip_hud.mouse_filter = Control.MOUSE_FILTER_STOP
	_btn_skip_hud.anchor_left = 0.0
	_btn_skip_hud.anchor_right = 0.0
	_btn_skip_hud.anchor_top = 0.0
	_btn_skip_hud.anchor_bottom = 0.0
	_btn_skip_hud.offset_left = 14.0
	_btn_skip_hud.offset_right = 156.0
	_btn_skip_hud.offset_top = 10.0
	_btn_skip_hud.offset_bottom = 40.0
	_btn_skip_hud.add_theme_font_size_override("font_size", 12)
	_btn_skip_hud.add_theme_stylebox_override("normal", _build_briefing_button_style(Color(0.24, 0.16, 0.05, 0.88), Color(0.98, 0.72, 0.22, 0.92)))
	_btn_skip_hud.add_theme_stylebox_override("hover", _build_briefing_button_style(Color(0.38, 0.24, 0.07, 0.96), Color(1.0, 0.85, 0.35, 1.0)))
	_btn_skip_hud.pressed.connect(_on_skip_tutorial_pressed)
	_btn_skip_hud.visible = false
	add_child(_btn_skip_hud)

func refresh_skip_button_visibility() -> void:
	if _btn_skip_hud != null:
		_btn_skip_hud.visible = false

func _on_skip_tutorial_pressed() -> void:
	if not is_inside_tree():
		return
	var tut := get_tree().root.find_child("TutorialInductionManager", true, false)
	if tut != null and tut.has_method("skip_tutorial_to_final_station"):
		tut.skip_tutorial_to_final_station()
	refresh_skip_button_visibility()
