class_name IndustrialTabletController
extends Control

## Controlador principal de la Tablet Industrial SCADA estilo Lab 3 (8 pestañas,
## tamaño invariante 1228x748 chasis / 1180x700 pantalla) conectado al gemelo
## digital AgroMolinos 10 HP, cámaras 3D interactivas, telemetría de 15 máquinas + CCM y RETIE.

const SoundSynth = preload("res://scripts/core/IndustrialSoundSynthesizer.gd")
const TTheme = preload("res://scripts/ui/TabletThemeHelper.gd")
const TCatalog = preload("res://scripts/ui/TabletDataCatalog.gd")
const TOscChart = preload("res://scripts/ui/TabletOscilloscopeChart.gd")
const TCard3D = preload("res://scripts/ui/Tablet3DViewportCard.gd")
const TSecTabs = preload("res://scripts/ui/TabletSecondaryTabsBuilder.gd")

const TAB_NAMES: Array[String] = [
	"Monitoreo IoT", "Cámaras", "RETIE", "Operarios",
	"Riesgos", "Fisiología IEC", "Hardware & IA", "Rúbrica", "Historial"
]

const MACHINE_CHART_CONFIGS: Dictionary = {
	"banda_descarga": {
		"group": "G1", "title": "01 · Banda de Descarga",
		"chart_title": "Velocidad y caudal",
		"unit": "kg/s", "legend": "Vel · Caudal", "warn": 1.25, "trip": 1.80,
		"col_a": Color(0.22, 0.74, 0.97, 1.0), "col_b": Color(0.96, 0.62, 0.04, 0.95),
		"kpis": [
			{"key": "spd", "title": "VELOCIDAD", "val": "100 %", "badge": "Normal"},
			{"key": "flow", "title": "CAUDAL", "val": "0.80 kg/s", "badge": "Normal"},
			{"key": "cur", "title": "CORRIENTE", "val": "4.5 A", "badge": "Normal"},
			{"key": "st", "title": "ESTADO", "val": "OK", "badge": "Normal"}
		]
	},
	"banda_inclinada_tolva": {
		"group": "G1", "title": "02 · Banda Inclinada",
		"chart_title": "Corriente y caudal",
		"unit": "A", "legend": "Ia · Caudal", "warn": 7.5, "trip": 9.5,
		"col_a": Color(0.22, 0.74, 0.97, 1.0), "col_b": Color(0.96, 0.62, 0.04, 0.95),
		"kpis": [
			{"key": "cur", "title": "CORRIENTE", "val": "5.2 A", "badge": "Normal"},
			{"key": "flow", "title": "CAUDAL", "val": "0.80 kg/s", "badge": "Normal"},
			{"key": "spd", "title": "VELOCIDAD", "val": "100 %", "badge": "Normal"},
			{"key": "st", "title": "ESTADO", "val": "OK", "badge": "Normal"}
		]
	},
	"hopper": {
		"group": "G1", "title": "03 · Tolva Receptora",
		"chart_title": "Nivel y flujo",
		"unit": "%", "legend": "Nivel · Flujo", "warn": 85.0, "trip": 95.0,
		"col_a": Color(0.22, 0.74, 0.97, 1.0), "col_b": Color(0.96, 0.62, 0.04, 0.95),
		"kpis": [
			{"key": "level", "title": "NIVEL", "val": "65.0 %", "badge": "Normal"},
			{"key": "flow", "title": "DESCARGA", "val": "0.80 kg/s", "badge": "Normal"},
			{"key": "weight", "title": "PESO", "val": "3250 kg", "badge": "Normal"},
			{"key": "st", "title": "ESTADO", "val": "OK", "badge": "Normal"}
		]
	},
	"banda_trituradora": {
		"group": "G1", "title": "04 · Banda Trituradora",
		"chart_title": "Velocidad y carga",
		"unit": "%", "legend": "Vel · Carga", "warn": 90.0, "trip": 98.0,
		"col_a": Color(0.22, 0.74, 0.97, 1.0), "col_b": Color(0.96, 0.62, 0.04, 0.95),
		"kpis": [
			{"key": "spd", "title": "DOSIFICACIÓN", "val": "85.0 %", "badge": "VFD"},
			{"key": "flow", "title": "CAUDAL", "val": "0.80 kg/s", "badge": "Normal"},
			{"key": "cur", "title": "CORRIENTE", "val": "3.8 A", "badge": "Normal"},
			{"key": "st", "title": "ESTADO", "val": "OK", "badge": "Normal"}
		]
	},
	"tornillo_trituradora": {
		"group": "G2", "title": "05 · Tornillo Trituradora",
		"chart_title": "Giro y corriente",
		"unit": "RPM", "legend": "RPM · Ia", "warn": 9.5, "trip": 14.0,
		"col_a": Color(0.22, 0.74, 0.97, 1.0), "col_b": Color(0.96, 0.62, 0.04, 0.95),
		"kpis": [
			{"key": "rpm", "title": "VELOCIDAD", "val": "125 RPM", "badge": "Normal"},
			{"key": "cur", "title": "CORRIENTE", "val": "6.4 A", "badge": "Normal"},
			{"key": "trq", "title": "TORQUE", "val": "48.0 N·m", "badge": "Normal"},
			{"key": "st", "title": "ESTADO", "val": "OK", "badge": "Normal"}
		]
	},
	"tornillo_secador": {
		"group": "G2", "title": "07 · Tornillo Secador",
		"chart_title": "Giro y caudal",
		"unit": "RPM", "legend": "RPM · Caudal", "warn": 8.5, "trip": 12.0,
		"col_a": Color(0.22, 0.74, 0.97, 1.0), "col_b": Color(0.96, 0.62, 0.04, 0.95),
		"kpis": [
			{"key": "rpm", "title": "VELOCIDAD", "val": "95 RPM", "badge": "Normal"},
			{"key": "flow", "title": "CAUDAL", "val": "0.78 kg/s", "badge": "Normal"},
			{"key": "cur", "title": "CORRIENTE", "val": "4.8 A", "badge": "Normal"},
			{"key": "st", "title": "ESTADO", "val": "OK", "badge": "Normal"}
		]
	},
	"secador_rotatorio": {
		"group": "G2", "title": "08 · Secador Rotatorio",
		"chart_title": "Temperatura y humedad",
		"unit": "°C", "legend": "Temp · Hum", "warn": 90.0, "trip": 105.0,
		"col_a": Color(0.96, 0.48, 0.26, 1.0), "col_b": Color(0.22, 0.74, 0.97, 0.95),
		"kpis": [
			{"key": "temp", "title": "TEMPERATURA", "val": "72.0 °C", "badge": "Normal"},
			{"key": "hum", "title": "HUMEDAD", "val": "12.5 %", "badge": "OK"},
			{"key": "rpm", "title": "GIRO", "val": "18.5 RPM", "badge": "Normal"},
			{"key": "st", "title": "ESTADO", "val": "OK", "badge": "Normal"}
		]
	},
	"ciclon_separador": {
		"group": "G3", "title": "09 · Ciclón Separador",
		"chart_title": "Presión y eficiencia",
		"unit": "kPa", "legend": "ΔP · Efic", "warn": 2.6, "trip": 3.8,
		"col_a": Color(0.22, 0.74, 0.97, 1.0), "col_b": Color(0.06, 0.73, 0.51, 0.95),
		"kpis": [
			{"key": "dp", "title": "PRESIÓN ΔP", "val": "1.45 kPa", "badge": "Normal"},
			{"key": "eff", "title": "EFICIENCIA", "val": "98.5 %", "badge": "Normal"},
			{"key": "flow", "title": "CAUDAL", "val": "38.0 m³/m", "badge": "Normal"},
			{"key": "st", "title": "ESTADO", "val": "OK", "badge": "Normal"}
		]
	},
	"cyclone": {
		"group": "G3", "title": "10 · Ciclones Clasificadores",
		"chart_title": "Nivel ATEX y presión",
		"unit": "%", "legend": "LEL · Pres", "warn": 25.0, "trip": 50.0,
		"col_a": Color(0.96, 0.62, 0.04, 1.0), "col_b": Color(0.22, 0.74, 0.97, 0.95),
		"kpis": [
			{"key": "atex", "title": "ATEX", "val": "8.5 % LEL", "badge": "Zona 22"},
			{"key": "pres", "title": "PRESIÓN", "val": "1.20 kPa", "badge": "Normal"},
			{"key": "flow", "title": "CAUDAL", "val": "0.78 kg/s", "badge": "Normal"},
			{"key": "st", "title": "ESTADO", "val": "OK", "badge": "Normal"}
		]
	},
	"unidad_extraccion": {
		"group": "G3", "title": "11 · Unidad de Extracción",
		"chart_title": "Extracción y vacío",
		"unit": "m³/m", "legend": "Caudal · Vacío", "warn": 3.2, "trip": 4.5,
		"col_a": Color(0.22, 0.74, 0.97, 1.0), "col_b": Color(0.96, 0.62, 0.04, 0.95),
		"kpis": [
			{"key": "flow", "title": "CAUDAL", "val": "42.0 m³/m", "badge": "Normal"},
			{"key": "vac", "title": "VACÍO", "val": "2.35 kPa", "badge": "Normal"},
			{"key": "cur", "title": "CORRIENTE", "val": "7.2 A", "badge": "Normal"},
			{"key": "st", "title": "ESTADO", "val": "OK", "badge": "Normal"}
		]
	},
	"horno": {
		"group": "G3", "title": "12 · Horno Térmico",
		"chart_title": "Temperatura y potencia",
		"unit": "°C", "legend": "Temp · kW", "warn": 210.0, "trip": 240.0,
		"col_a": Color(0.94, 0.27, 0.27, 1.0), "col_b": Color(0.96, 0.62, 0.04, 0.95),
		"kpis": [
			{"key": "temp", "title": "CÁMARA", "val": "185.0 °C", "badge": "Normal"},
			{"key": "pwr", "title": "POTENCIA", "val": "24.0 kW", "badge": "Normal"},
			{"key": "air", "title": "AIRE", "val": "92.0 °C", "badge": "Normal"},
			{"key": "st", "title": "ESTADO", "val": "OK", "badge": "Normal"}
		]
	},
	"soplador": {
		"group": "G4", "title": "13 · Soplador",
		"chart_title": "Presión y vibración",
		"unit": "kPa", "legend": "Pres · Vib", "warn": 3.0, "trip": 4.5,
		"col_a": Color(0.22, 0.74, 0.97, 1.0), "col_b": Color(0.06, 0.73, 0.51, 0.95),
		"kpis": [
			{"key": "pres", "title": "PRESIÓN", "val": "6.40 kPa", "badge": "Normal"},
			{"key": "vib", "title": "VIBRACIÓN", "val": "1.10 mm/s", "badge": "Normal"},
			{"key": "cur", "title": "CORRIENTE", "val": "8.5 A", "badge": "Normal"},
			{"key": "st", "title": "ESTADO", "val": "OK", "badge": "Normal"}
		]
	},
	"intercambiador_calor": {
		"group": "G4", "title": "14 · Intercambiador de Calor",
		"chart_title": "Entrada y salida térmica",
		"unit": "°C", "legend": "Entrada · Salida", "warn": 65.0, "trip": 85.0,
		"col_a": Color(0.94, 0.27, 0.27, 1.0), "col_b": Color(0.22, 0.74, 0.97, 0.95),
		"kpis": [
			{"key": "tin", "title": "ENTRADA", "val": "85.0 °C", "badge": "Normal"},
			{"key": "tout", "title": "SALIDA", "val": "42.0 °C", "badge": "Normal"},
			{"key": "eff", "title": "EFICIENCIA", "val": "82.0 %", "badge": "Normal"},
			{"key": "st", "title": "ESTADO", "val": "OK", "badge": "Normal"}
		]
	},
	"ductos_aire": {
		"group": "G4", "title": "15 · Ductos de Aire",
		"chart_title": "Presión y caudal",
		"unit": "kPa", "legend": "Pres · Caudal", "warn": 2.8, "trip": 1.5,
		"col_a": Color(0.22, 0.74, 0.97, 1.0), "col_b": Color(0.06, 0.73, 0.51, 0.95),
		"kpis": [
			{"key": "pres", "title": "PRESIÓN", "val": "5.80 kPa", "badge": "Normal"},
			{"key": "vel", "title": "VELOCIDAD", "val": "22.5 m/s", "badge": "Normal"},
			{"key": "leak", "title": "SELLADO", "val": "100 %", "badge": "OK"},
			{"key": "st", "title": "ESTADO", "val": "OK", "badge": "Normal"}
		]
	}
}

# Referencias conservadas para QA / compatibilidad con scripts del proyecto
var chart_currents = null
var chart_temperature = null
var chart_vibration = null
var machine_charts: Dictionary = {}
var _machine_cards: Dictionary = {}
var _machine_card_groups: Dictionary = {}
var _machine_card_tiles: Dictionary = {}
var _filter_btns: Dictionary = {}
var _active_filter: String = "ALL"
var btn_close: Button = null
var btn_emergency_stop: Button = null
var btn_drive_mode: Button = null
var lbl_academic_score: Label = null
var lbl_cctv_status: Label = null
var lbl_alert_title: Label = null
var lbl_root_cause: Label = null
var lbl_prognosis: Label = null
var lbl_prescription: Label = null
var mhi_progress_bar: ProgressBar = null
var lbl_mhi_value: Label = null
var lbl_rul_value: Label = null
var checklist_container: VBoxContainer = null

@onready var audio_alert: AudioStreamPlayer = $AudioAlert
@onready var _main_vbox: VBoxContainer = $Frame/VBox

var _header_status_panel: PanelContainer = null
var _header_status_lbl: Label = null
var _tab_buttons: Array[Button] = []
var _tab_pages: Array[Control] = []
var _active_tab_idx: int = 0
var _active_3d_group: String = "G1"
var _audio_muted: bool = false
var _last_severity: String = "NORMAL"
var _last_telemetry: Dictionary = {}
var _last_alert: Dictionary = {}
var _last_prod: Dictionary = {}
var _live_sync_accum: float = 0.0
var _custom_workers: Array[Dictionary] = []
var _has_unread_warning: bool = false
var _unread_warning_count: int = 0
var _unread_warning_keys: Dictionary = {}
var _active_warning_data: Dictionary = {}
var _last_warning_key: String = ""
var _last_warning_ms: int = -10000
var _last_critical_notif_ms: int = -10000
var _hazard_tablet_cooldown_ms: Dictionary = {}
var _last_chime_ms: int = -10000

# Handles UI internos Tab 1 (Monitoreo IoT)
var _iot_relay_lbl: Label = null
var _iot_btn_audio: Button = null
var _iot_alert_lbl: Label = null
var _warning_banner_card: PanelContainer = null
var _warning_banner_pill: PanelContainer = null
var _warning_banner_pill_lbl: Label = null
var _warning_banner_title: Label = null
var _warning_banner_body: Label = null
var _tiles: Dictionary = {}
var _machine_tiles: Dictionary = {}
var _blackbox_lbl: RichTextLabel = null

# Handles UI internos Tab 2 (Cámaras 3D Interactivas)
var _grp_3d_btns: Dictionary = {}
var _containers_3d: Dictionary = {}
var _cards_by_3d_group: Dictionary = {}
var _cards_3d_workers: Array = []

# Handles UI secundarios Tabs 3..9
var _retie_handles: Dictionary = {}
var _workers_handles: Dictionary = {}
var _hw_ai_handles: Dictionary = {}
var _cctv_handles: Dictionary = {}
var _notif_hist_handles: Dictionary = {}
var _notification_history: Array[Dictionary] = []
var _notif_hist_filter: String = "ALL"
var _last_history_key: String = ""
var _last_history_ms: int = -10000
const MAX_NOTIFICATION_HISTORY: int = 250

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if audio_alert != null:
		audio_alert.process_mode = Node.PROCESS_MODE_ALWAYS
		if audio_alert.stream == null:
			audio_alert.stream = SoundSynth.create_tablet_push_warning_sound()
		audio_alert.volume_db = 0.0

	_build_lab3_scada_ui()
	_connect_event_bus()
	_initialize_3d_viewports()
	_append_blackbox("INFO", "Sistema SCADA AgroMolinos inicializado (10 Hz Edge AI + Kloss 10 HP).")
	_select_tab(0)
	_sync_tablet_invariant_size()

func _build_lab3_scada_ui() -> void:
	if _main_vbox == null:
		return
	for ch in _main_vbox.get_children():
		ch.queue_free()

	_build_header_bar()
	_build_tab_bar()

	var content_host := Control.new()
	content_host.name = "TabContentHost"
	content_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_host.clip_contents = true
	_main_vbox.add_child(content_host)

	var p1 := _build_tab1_iot()
	var p2 := _build_tab2_3d()
	_retie_handles = TSecTabs.build_retie_tab()
	_workers_handles = TSecTabs.build_workers_tab(_on_register_worker, _on_clear_custom_workers)
	var r_handles := TSecTabs.build_risks_tab()
	var f_handles := TSecTabs.build_physiology_tab()
	_hw_ai_handles = TSecTabs.build_hardware_ai_tab()
	_cctv_handles = TSecTabs.build_cctv_rubric_tab(_select_cctv_camera)
	_notif_hist_handles = TSecTabs.build_notifications_history_tab(_on_notif_history_filter_selected, _on_clear_notif_history)

	_bind_shared_handles()

	_tab_pages = [
		p1, p2, _retie_handles["root"], _workers_handles["root"],
		r_handles["root"], f_handles["root"], _hw_ai_handles["root"], _cctv_handles["root"],
		_notif_hist_handles["root"]
	]
	for page in _tab_pages:
		page.visible = false
		content_host.add_child(page)
	_rebuild_notification_history_ui()

func _build_header_bar() -> void:
	var hdr := HBoxContainer.new()
	hdr.name = "Lab3Header"
	hdr.add_theme_constant_override("separation", 12)
	_main_vbox.add_child(hdr)

	var title_hb := HBoxContainer.new()
	title_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hb.add_theme_constant_override("separation", 10)
	hdr.add_child(title_hb)

	var main_t := TTheme.make_label("AGROMOLINOS", 16, Color.WHITE)
	main_t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_hb.add_child(main_t)

	var sub_t := TTheme.make_label("SCADA", 11, TTheme.TEXT_MUTED)
	sub_t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_hb.add_child(sub_t)

	_header_status_panel = PanelContainer.new()
	_header_status_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_header_status_panel.add_theme_stylebox_override("panel", TTheme.make_pill_style(Color(0.04, 0.25, 0.16, 0.95), TTheme.ACCENT_EMERALD))
	hdr.add_child(_header_status_panel)
	_header_status_lbl = TTheme.make_label("Normal", 10, Color(0.55, 0.98, 0.78))
	_header_status_panel.add_child(_header_status_lbl)

	var score_pill := PanelContainer.new()
	score_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	score_pill.add_theme_stylebox_override("panel", TTheme.make_pill_style(TTheme.BG_SUBCARD, TTheme.BORDER_SUBTLE))
	hdr.add_child(score_pill)
	lbl_academic_score = TTheme.make_label("RETIE 5.0/5.0", 11, TTheme.ACCENT_EMERALD)
	score_pill.add_child(lbl_academic_score)

	btn_emergency_stop = Button.new()
	btn_emergency_stop.name = "BtnEmergencyStop"
	btn_emergency_stop.text = "Parar Máquinas"
	btn_emergency_stop.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_emergency_stop.add_theme_font_size_override("font_size", 11)
	TTheme.apply_btn_colors(btn_emergency_stop, Color(0.55, 0.10, 0.12), TTheme.ACCENT_RED)
	btn_emergency_stop.pressed.connect(_on_emergency_stop_pressed)
	hdr.add_child(btn_emergency_stop)

	btn_close = null

func _build_tab_bar() -> void:
	var bar_wrap := PanelContainer.new()
	bar_wrap.add_theme_stylebox_override("panel", TTheme.make_panel_style(Color(0.045, 0.068, 0.112, 0.96), TTheme.BORDER_SUBTLE, 8, 5, 4, 1))
	_main_vbox.add_child(bar_wrap)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 4)
	bar_wrap.add_child(bar)

	_tab_buttons.clear()
	for i in range(TAB_NAMES.size()):
		var b := Button.new()
		b.text = TAB_NAMES[i]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 11)
		b.pressed.connect(_select_tab.bind(i))
		bar.add_child(b)
		_tab_buttons.append(b)

func _build_tab1_iot() -> Control:
	var vb := VBoxContainer.new()
	vb.name = "TabMonitoreoIoT"
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 8)

	# Barra de control superior estilo Lab 3
	var ctrl_bar := PanelContainer.new()
	ctrl_bar.add_theme_stylebox_override("panel", TTheme.make_panel_style(TTheme.BG_CARD, TTheme.BORDER_SUBTLE, 6, 10, 6))
	vb.add_child(ctrl_bar)
	var cb_hb := HBoxContainer.new()
	cb_hb.add_theme_constant_override("separation", 10)
	ctrl_bar.add_child(cb_hb)

	_iot_relay_lbl = TTheme.make_label("CCM: Cerrado · VFD", 11, TTheme.ACCENT_EMERALD)
	cb_hb.add_child(_iot_relay_lbl)

	_iot_alert_lbl = TTheme.make_label("Estado normal", 11, TTheme.TEXT_MUTED)
	_iot_alert_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_iot_alert_lbl.clip_text = true
	_iot_alert_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_alert_title = _iot_alert_lbl
	cb_hb.add_child(_iot_alert_lbl)

	btn_drive_mode = Button.new()
	btn_drive_mode.name = "BtnDriveMode"
	btn_drive_mode.text = "Modo: VFD"
	btn_drive_mode.add_theme_font_size_override("font_size", 11)
	TTheme.apply_btn_colors(btn_drive_mode, TTheme.ACCENT_BLUE, TTheme.ACCENT_CYAN)
	btn_drive_mode.pressed.connect(_on_toggle_drive_mode_pressed)
	cb_hb.add_child(btn_drive_mode)

	_iot_btn_audio = Button.new()
	_iot_btn_audio.text = "Audio: ON"
	_iot_btn_audio.add_theme_font_size_override("font_size", 11)
	TTheme.apply_btn_colors(_iot_btn_audio, Color(0.06, 0.35, 0.26), TTheme.ACCENT_EMERALD)
	_iot_btn_audio.pressed.connect(_toggle_audio_mute)
	cb_hb.add_child(_iot_btn_audio)

	# Banner de alerta activa
	_warning_banner_card = PanelContainer.new()
	_warning_banner_card.name = "ActiveWarningBanner"
	_warning_banner_card.visible = false
	_warning_banner_card.clip_contents = true
	_warning_banner_card.add_theme_stylebox_override("panel", TTheme.make_left_stripe_card(TTheme.ACCENT_AMBER, Color(0.14, 0.09, 0.03, 0.96)))
	vb.add_child(_warning_banner_card)

	var wb_hb := HBoxContainer.new()
	wb_hb.add_theme_constant_override("separation", 10)
	_warning_banner_card.add_child(wb_hb)

	var wb_txt := VBoxContainer.new()
	wb_txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wb_txt.add_theme_constant_override("separation", 2)
	wb_hb.add_child(wb_txt)
	_warning_banner_title = TTheme.make_label("Alerta", 12, Color.WHITE)
	_warning_banner_title.clip_text = true
	_warning_banner_body = TTheme.make_label("", 10, Color(0.95, 0.92, 0.85))
	_warning_banner_body.clip_text = true
	wb_txt.add_child(_warning_banner_title)
	wb_txt.add_child(_warning_banner_body)

	var btn_rcm := Button.new()
	btn_rcm.text = "Ver RCM"
	btn_rcm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_rcm.add_theme_font_size_override("font_size", 10)
	TTheme.apply_btn_colors(btn_rcm, TTheme.ACCENT_BLUE, TTheme.ACCENT_CYAN)
	btn_rcm.pressed.connect(func(): _select_tab(6))
	wb_hb.add_child(btn_rcm)

	var btn_dismiss := Button.new()
	btn_dismiss.text = "Cerrar"
	btn_dismiss.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_dismiss.add_theme_font_size_override("font_size", 10)
	TTheme.apply_btn_colors(btn_dismiss, TTheme.BG_SUBCARD, TTheme.BORDER_SUBTLE)
	btn_dismiss.pressed.connect(func():
		_warning_banner_card.visible = false
		if _last_severity == "NORMAL":
			TTheme.set_badge_state(_header_status_panel, _header_status_lbl, "Normal", "NORMAL")
		_sync_tablet_invariant_size()
	)
	wb_hb.add_child(btn_dismiss)

	# Filtro de zonas
	var filter_bar := PanelContainer.new()
	filter_bar.add_theme_stylebox_override("panel", TTheme.make_panel_style(Color(0.04, 0.06, 0.10, 0.95), TTheme.BORDER_SUBTLE, 4, 8, 4, 1))
	vb.add_child(filter_bar)
	var fb_hb := HBoxContainer.new()
	fb_hb.add_theme_constant_override("separation", 6)
	filter_bar.add_child(fb_hb)

	_filter_btns.clear()
	var filter_specs := [
		{"id": "ALL", "txt": "Todas"},
		{"id": "G1", "txt": "Recepción"},
		{"id": "G2", "txt": "Molienda"},
		{"id": "G3", "txt": "Ciclones"},
		{"id": "G4", "txt": "Aire y CCM"}
	]
	for fs in filter_specs:
		var fid: String = fs["id"]
		var fb := Button.new()
		fb.text = fs["txt"]
		fb.add_theme_font_size_override("font_size", 10)
		fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fb.pressed.connect(_set_active_zone_filter.bind(fid))
		fb_hb.add_child(fb)
		_filter_btns[fid] = fb

	# Scroll Vertical con las 16 Máquinas en Orden de Proceso + Blackbox
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	vb.add_child(scroll)

	var cards_vb := VBoxContainer.new()
	cards_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_vb.add_theme_constant_override("separation", 8)
	scroll.add_child(cards_vb)

	_machine_cards.clear()
	_machine_card_groups.clear()
	_machine_card_tiles.clear()
	machine_charts.clear()

	# --- G1: RECEPCIÓN & ALIMENTACIÓN (01 a 04) ---
	cards_vb.add_child(_make_machine_card("banda_descarga", MACHINE_CHART_CONFIGS["banda_descarga"]))
	cards_vb.add_child(_make_machine_card("banda_inclinada_tolva", MACHINE_CHART_CONFIGS["banda_inclinada_tolva"]))
	cards_vb.add_child(_make_machine_card("hopper", MACHINE_CHART_CONFIGS["hopper"]))
	cards_vb.add_child(_make_machine_card("banda_trituradora", MACHINE_CHART_CONFIGS["banda_trituradora"]))

	# --- G2: MOLIENDA & SECADO (05 a 08) ---
	cards_vb.add_child(_make_machine_card("tornillo_trituradora", MACHINE_CHART_CONFIGS["tornillo_trituradora"]))

	# Card 06: Trituradora + Motor 10 HP (Preservado para QA)
	chart_currents = TOscChart.new()
	chart_currents.name = "ChartCurrents"
	chart_currents.chart_mode = "CURRENTS"
	chart_currents.chart_title = "Corrientes Ia · Ib · Ic"
	chart_currents.custom_minimum_size = Vector2(0, 165)
	var card_motor := _make_asset_card(
		"06 · Trituradora y Motor 10 HP",
		[
			{"key": "currents", "title": "CORRIENTES", "val": "13.5 / 13.5 / 13.5", "badge": "IUF 0.7%"},
			{"key": "voltage", "title": "TENSIÓN", "val": "460 V · 60 Hz", "badge": "cos φ 0.85"},
			{"key": "temp", "title": "TEMPERATURA", "val": "58.0 °C", "badge": "Normal"},
			{"key": "vib", "title": "VIBRACIÓN", "val": "1.15 mm/s", "badge": "OK"}
		],
		chart_currents
	)
	_machine_cards["motor"] = card_motor
	_machine_card_groups["motor"] = "G2"
	cards_vb.add_child(card_motor)

	cards_vb.add_child(_make_machine_card("tornillo_secador", MACHINE_CHART_CONFIGS["tornillo_secador"]))
	cards_vb.add_child(_make_machine_card("secador_rotatorio", MACHINE_CHART_CONFIGS["secador_rotatorio"]))

	# --- G3: CICLONES & HORNO (09 a 12) ---
	cards_vb.add_child(_make_machine_card("ciclon_separador", MACHINE_CHART_CONFIGS["ciclon_separador"]))
	cards_vb.add_child(_make_machine_card("cyclone", MACHINE_CHART_CONFIGS["cyclone"]))
	cards_vb.add_child(_make_machine_card("unidad_extraccion", MACHINE_CHART_CONFIGS["unidad_extraccion"]))
	cards_vb.add_child(_make_machine_card("horno", MACHINE_CHART_CONFIGS["horno"]))

	# --- G4: AIRE & CCM (13 a 15 + CCM) ---
	cards_vb.add_child(_make_machine_card("soplador", MACHINE_CHART_CONFIGS["soplador"]))
	cards_vb.add_child(_make_machine_card("intercambiador_calor", MACHINE_CHART_CONFIGS["intercambiador_calor"]))
	cards_vb.add_child(_make_machine_card("ductos_aire", MACHINE_CHART_CONFIGS["ductos_aire"]))

	# CCM 460 V & Edge AI (Preservado para QA)
	var dual_charts := HBoxContainer.new()
	dual_charts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dual_charts.add_theme_constant_override("separation", 8)
	chart_temperature = TOscChart.new()
	chart_temperature.name = "ChartTemperature"
	chart_temperature.chart_mode = "TEMPERATURE"
	chart_temperature.chart_title = "Temperatura"
	chart_temperature.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chart_temperature.custom_minimum_size = Vector2(0, 165)
	chart_vibration = TOscChart.new()
	chart_vibration.name = "ChartVibration"
	chart_vibration.chart_mode = "VIBRATION"
	chart_vibration.chart_title = "Vibración ISO"
	chart_vibration.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chart_vibration.custom_minimum_size = Vector2(0, 165)
	dual_charts.add_child(chart_temperature)
	dual_charts.add_child(chart_vibration)

	var card_ccm := _make_asset_card(
		"CCM 460 V y Variador VFD",
		[
			{"key": "mhi", "title": "SALUD MHI", "val": "98.5 %", "badge": "RUL 24000 h"},
			{"key": "rpm_torque", "title": "VELOCIDAD", "val": "1750 RPM", "badge": "40.7 N·m · 7.5 kW"},
			{"key": "energy", "title": "ENERGÍA", "val": "7.52 kWh/t", "badge": "-28.4% vs DOL"},
			{"key": "co2", "title": "EMISIONES", "val": "3.2 %", "badge": "0.0 kg evitado"}
		],
		dual_charts
	)
	_machine_cards["breaker"] = card_ccm
	_machine_card_groups["breaker"] = "G4"
	cards_vb.add_child(card_ccm)

	# Registro y producción
	var bb_panel := PanelContainer.new()
	bb_panel.custom_minimum_size.y = 165
	bb_panel.add_theme_stylebox_override("panel", TTheme.make_panel_style(TTheme.BG_PLOT, TTheme.BORDER_SUBTLE, 6, 8, 6))
	var bb_vb := VBoxContainer.new()
	bb_vb.add_theme_constant_override("separation", 3)
	bb_panel.add_child(bb_vb)
	bb_vb.add_child(TTheme.make_label("Registro", 10, TTheme.ACCENT_CYAN))
	_blackbox_lbl = RichTextLabel.new()
	_blackbox_lbl.bbcode_enabled = true
	_blackbox_lbl.scroll_following = true
	_blackbox_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_blackbox_lbl.add_theme_font_size_override("normal_font_size", 10)
	bb_vb.add_child(_blackbox_lbl)

	var card_prod := _make_asset_card(
		"Producción y Logística",
		[
			{"key": "flow", "title": "FLUJO", "val": "0.80 kg/s", "badge": "Normal"},
			{"key": "prod", "title": "PRODUCCIÓN", "val": "0 kg", "badge": "0 sacos"},
			{"key": "truck", "title": "LOGÍSTICA", "val": "Espera", "badge": "0 pallets"},
			{"key": "conf", "title": "PRECISIÓN IA", "val": "99.1 %", "badge": "MLP / SVM"}
		],
		bb_panel
	)
	_machine_cards["cadena_prod"] = card_prod
	_machine_card_groups["cadena_prod"] = "G1"
	cards_vb.add_child(card_prod)

	var card_summary := _build_all_machines_telemetry_card()
	_machine_cards["telemetry_summary"] = card_summary
	_machine_card_groups["telemetry_summary"] = "ALL"
	cards_vb.add_child(card_summary)

	_set_active_zone_filter("ALL")
	return vb

func _build_all_machines_telemetry_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "AllMachinesTelemetryCard"
	card.add_theme_stylebox_override("panel", TTheme.make_panel_style(TTheme.BG_CARD, TTheme.BORDER_SUBTLE, 8, 10, 8))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)
	vb.add_child(TTheme.make_label("Resumen de Equipos", 12, TTheme.ACCENT_CYAN))

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	vb.add_child(grid)

	_machine_tiles.clear()
	for spec in TCatalog.PLANT_MACHINES_SPEC:
		var gk := str(spec.get("glow_group", ""))
		if gk == "" or gk == "truck" or gk == "bag" or _machine_tiles.has(gk):
			continue
		var tile := TTheme.create_kpi_tile(str(spec["title"]), "Nominal", "OK")
		_machine_tiles[gk] = tile
		grid.add_child(tile["panel"])
	return card

func _make_asset_card(title_txt: String, kpi_specs: Array, right_ctrl: Control) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", TTheme.make_panel_style(TTheme.BG_CARD, TTheme.BORDER_SUBTLE, 8, 10, 8))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)

	vb.add_child(TTheme.make_label(title_txt, 12, TTheme.ACCENT_CYAN))

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	vb.add_child(body)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.custom_minimum_size.x = 400
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)

	for sp in kpi_specs:
		var tile := TTheme.create_kpi_tile(sp["title"], sp["val"], sp["badge"])
		_tiles[sp["key"]] = tile
		grid.add_child(tile["panel"])

	right_ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right_ctrl)
	return card

func _set_active_zone_filter(fid: String) -> void:
	_active_filter = fid
	for k in _filter_btns.keys():
		var btn: Button = _filter_btns[k]
		if k == fid:
			TTheme.apply_btn_colors(btn, TTheme.ACCENT_BLUE, TTheme.ACCENT_CYAN)
		else:
			TTheme.apply_btn_colors(btn, TTheme.BG_CARD, TTheme.BORDER_SUBTLE)
	for m_key in _machine_cards.keys():
		var card: Control = _machine_cards[m_key]
		var grp: String = _machine_card_groups.get(m_key, "")
		if fid == "ALL" or grp == fid or grp == "ALL":
			card.visible = true
		else:
			card.visible = false
	_sync_tablet_invariant_size()

func _make_machine_card(m_key: String, spec: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "Card_" + m_key
	card.add_theme_stylebox_override("panel", TTheme.make_panel_style(TTheme.BG_CARD, TTheme.BORDER_SUBTLE, 8, 10, 8))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)

	var tlbl := TTheme.make_label(spec.get("title", m_key), 12, TTheme.ACCENT_CYAN)
	tlbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(tlbl)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	vb.add_child(body)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.custom_minimum_size.x = 380
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	body.add_child(grid)

	var m_tiles := {}
	for sp in spec.get("kpis", []):
		var tile := TTheme.create_kpi_tile(sp["title"], sp["val"], sp["badge"])
		m_tiles[sp["key"]] = tile
		grid.add_child(tile["panel"])
	_machine_card_tiles[m_key] = m_tiles

	var osc := TOscChart.new()
	osc.name = "Chart_" + m_key
	osc.chart_mode = "GENERIC"
	osc.chart_title = spec.get("chart_title", "Oscilograma")
	osc.unit_label = spec.get("unit", "")
	osc.channel_legend = spec.get("legend", "")
	osc.warn_line = spec.get("warn", 0.0)
	osc.trip_line = spec.get("trip", 0.0)
	osc.col_series_a = spec.get("col_a", Color(0.22, 0.74, 0.97, 1.0))
	osc.col_series_b = spec.get("col_b", Color(0.06, 0.73, 0.51, 0.95))
	osc.custom_minimum_size = Vector2(0, 165)
	osc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(osc)

	machine_charts[m_key] = osc
	_machine_cards[m_key] = card
	_machine_card_groups[m_key] = spec.get("group", "")
	return card

func _build_tab2_3d() -> Control:
	var vb := VBoxContainer.new()
	vb.name = "TabCamaras"
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 8)

	var top_bar := PanelContainer.new()
	top_bar.add_theme_stylebox_override("panel", TTheme.make_panel_style(TTheme.BG_CARD, TTheme.BORDER_SUBTLE, 6, 10, 6))
	vb.add_child(top_bar)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	top_bar.add_child(hb)

	_grp_3d_btns.clear()
	_containers_3d.clear()
	_cards_by_3d_group.clear()
	_cards_3d_workers.clear()

	for g in TCatalog.CAMERA_GROUP_TABS:
		var gid := str(g["id"])
		var btn := Button.new()
		btn.text = str(g["txt"])
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_select_3d_group.bind(gid))
		hb.add_child(btn)
		_grp_3d_btns[gid] = btn

	var stage := Control.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(stage)

	for gid in TCatalog.CAMERA_GROUPS_ORDER:
		var grid := GridContainer.new()
		grid.set_anchors_preset(Control.PRESET_FULL_RECT)
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 8)
		stage.add_child(grid)
		_containers_3d[gid] = grid
		_cards_by_3d_group[gid] = []

	for m_spec in TCatalog.PLANT_MACHINES_SPEC:
		var gid := str(m_spec.get("group", "G1"))
		if not _containers_3d.has(gid):
			continue
		var card := TCard3D.new()
		card.setup(m_spec, false)
		(_containers_3d[gid] as GridContainer).add_child(card)
		(_cards_by_3d_group[gid] as Array).append(card)

	for w_spec in TCatalog.PLANT_WORKERS_SPEC:
		var card := TCard3D.new()
		card.setup(w_spec, true)
		(_containers_3d["WORKERS"] as GridContainer).add_child(card)
		(_cards_by_3d_group["WORKERS"] as Array).append(card)
		_cards_3d_workers.append(card)

	_select_3d_group("G1")
	return vb

func _bind_shared_handles() -> void:
	if not _hw_ai_handles.is_empty():
		lbl_root_cause = _hw_ai_handles["val_rc"]
		lbl_prognosis = _hw_ai_handles["val_pr"]
		lbl_prescription = _hw_ai_handles["val_px"]
		mhi_progress_bar = _hw_ai_handles["mhi_bar"]
		lbl_mhi_value = _hw_ai_handles["mhi_lbl"]
		lbl_rul_value = _hw_ai_handles["rul_lbl"]
		checklist_container = _hw_ai_handles["chk_vb"]
	if not _cctv_handles.is_empty():
		lbl_cctv_status = _cctv_handles.get("lbl_cam", null)

func _initialize_3d_viewports() -> void:
	var root_n := get_tree().root if is_inside_tree() else null
	for gid in _cards_by_3d_group.keys():
		for card in (_cards_by_3d_group[gid] as Array):
			card.initialize_world(root_n)

func _connect_event_bus() -> void:
	var bus = get_node_or_null("/root/EventBus")
	if bus == null:
		return
	if not bus.ai_alert_received.is_connected(_on_ai_alert_received):
		bus.ai_alert_received.connect(_on_ai_alert_received)
	if bus.has_signal("telemetry_vector_updated") and not bus.telemetry_vector_updated.is_connected(_on_telemetry_vector_updated):
		bus.telemetry_vector_updated.connect(_on_telemetry_vector_updated)
	if bus.has_signal("safety_score_updated") and not bus.safety_score_updated.is_connected(_on_safety_score_updated):
		bus.safety_score_updated.connect(_on_safety_score_updated)
	if bus.has_signal("production_metrics_updated") and not bus.production_metrics_updated.is_connected(_on_production_metrics_updated):
		bus.production_metrics_updated.connect(_on_production_metrics_updated)
	if bus.has_signal("cctv_camera_changed") and not bus.cctv_camera_changed.is_connected(_on_cctv_camera_changed):
		bus.cctv_camera_changed.connect(_on_cctv_camera_changed)
	if bus.has_signal("epp_state_changed") and not bus.epp_state_changed.is_connected(_on_epp_state_changed):
		bus.epp_state_changed.connect(_on_epp_state_changed)
	if bus.has_signal("golden_rule_step_completed") and not bus.golden_rule_step_completed.is_connected(_on_golden_step):
		bus.golden_rule_step_completed.connect(_on_golden_step)
	if bus.has_signal("notification_posted") and not bus.notification_posted.is_connected(_on_bus_notification_posted):
		bus.notification_posted.connect(_on_bus_notification_posted)
	if bus.has_signal("safety_line_crossed") and not bus.safety_line_crossed.is_connected(_on_safety_line_crossed_warning):
		bus.safety_line_crossed.connect(_on_safety_line_crossed_warning)
	if bus.has_signal("safety_violation_committed") and not bus.safety_violation_committed.is_connected(_on_safety_violation_warning):
		bus.safety_violation_committed.connect(_on_safety_violation_warning)
	if bus.has_signal("emergency_stop_triggered") and not bus.emergency_stop_triggered.is_connected(_on_emergency_stop_triggered):
		bus.emergency_stop_triggered.connect(_on_emergency_stop_triggered)
	if bus.has_signal("emergency_stop_reset") and not bus.emergency_stop_reset.is_connected(_on_emergency_stop_reset):
		bus.emergency_stop_reset.connect(_on_emergency_stop_reset)

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			if ke.keycode == KEY_ESCAPE:
				_close_tablet()
				get_viewport().set_input_as_handled()
				return
			if ke.keycode == KEY_TAB:
				toggle_tablet()
				get_viewport().set_input_as_handled()
				return
	var focus_owner := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if focus_owner is LineEdit:
		return
	if event.is_action_pressed("toggle_tablet"):
		toggle_tablet()
		get_viewport().set_input_as_handled()

func toggle_tablet() -> void:
	visible = not visible
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if _has_unread_warning:
			_has_unread_warning = false
			_unread_warning_count = 0
			_unread_warning_keys.clear()
			_select_tab(0)
		var bus = get_node_or_null("/root/EventBus")
		if bus != null and bus.has_signal("tablet_notifications_cleared"):
			bus.tablet_notifications_cleared.emit()
		if not _last_telemetry.is_empty():
			_update_telemetry_ui(_last_telemetry)
		if not _last_prod.is_empty():
			_set_tile("prod", "%.0f kg" % float(_last_prod.get("total_grain_milled_kg", 0.0)), "%d sacos 50 kg" % int(_last_prod.get("bags_50kg_produced", 0)), "NORMAL")
			_set_tile("truck", str(_last_prod.get("truck_cycle_phase", "ESPERA")), "%d pallets" % int(_last_prod.get("pallets_completed", 0)), "NORMAL")
		_sync_live_plant_context()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_update_active_3d_rendering()
	_sync_tablet_invariant_size()

func _close_tablet() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_update_active_3d_rendering()

func _select_tab(idx: int) -> void:
	_active_tab_idx = clampi(idx, 0, _tab_pages.size() - 1)
	for i in range(_tab_pages.size()):
		_tab_pages[i].visible = (i == _active_tab_idx)
		if i < _tab_buttons.size():
			TTheme.apply_tab_style(_tab_buttons[i], i == _active_tab_idx)
	_update_active_3d_rendering()
	_sync_live_plant_context()
	_sync_tablet_invariant_size()

func _select_3d_group(group_id: String) -> void:
	_active_3d_group = group_id
	for gid in _containers_3d.keys():
		(_containers_3d[gid] as Control).visible = (gid == group_id)
	for gid in _grp_3d_btns.keys():
		var b: Button = _grp_3d_btns[gid]
		var active: bool = (gid == group_id)
		TTheme.apply_btn_colors(b, TTheme.ACCENT_BLUE if active else TTheme.BG_SUBCARD, TTheme.ACCENT_CYAN if active else TTheme.BORDER_SUBTLE)
	_update_active_3d_rendering()

func _update_active_3d_rendering() -> void:
	var on_cam_tab := visible and (_active_tab_idx == 1)
	for gid in _cards_by_3d_group.keys():
		var active_grp: bool = on_cam_tab and (_active_3d_group == str(gid))
		for c in (_cards_by_3d_group[gid] as Array):
			c.set_rendering_active(active_grp)
	if is_inside_tree() and get_tree() != null:
		var vis_opt := get_tree().root.find_child("PlantVisibilityOptimizer", true, false)
		if vis_opt != null and vis_opt.has_method("set_cctv_full_visibility"):
			var need_world_vis := on_cam_tab and (_active_3d_group != "WORKERS")
			vis_opt.set_cctv_full_visibility(need_world_vis)

func _process(delta: float) -> void:
	if not visible:
		return
	_live_sync_accum += delta
	if _live_sync_accum >= 0.35:
		_live_sync_accum = 0.0
		_sync_live_plant_context()

func _on_toggle_drive_mode_pressed() -> void:
	var sm = get_node_or_null("/root/SimulationManager")
	if sm != null and sm.has_method("toggle_drive_mode"):
		var new_mode: String = sm.toggle_drive_mode()
		if btn_drive_mode != null:
			btn_drive_mode.text = "Modo: %s" % new_mode
		_append_blackbox("INFO", "Modo de accionamiento cambiado a %s." % new_mode)

func _on_emergency_stop_pressed() -> void:
	var sm = get_node_or_null("/root/SimulationManager")
	if sm != null and sm.has_method("toggle_emergency_stop"):
		var engaged: bool = sm.toggle_emergency_stop("TABLET_SCADA")
		_sync_emergency_stop_ui(engaged)
		if engaged:
			_append_blackbox("CRITICAL", "Parada de emergencia accionada desde la Tablet Industrial.")
		else:
			_append_blackbox("OK", "Parada rearmada desde la Tablet Industrial. Máquinas reanudadas.")

func _on_emergency_stop_triggered(_source: String) -> void:
	_sync_emergency_stop_ui(true)

func _on_emergency_stop_reset() -> void:
	_sync_emergency_stop_ui(false)

func _sync_emergency_stop_ui(engaged: bool) -> void:
	if btn_emergency_stop != null:
		if engaged:
			btn_emergency_stop.text = "Reanudar Máquinas"
			TTheme.apply_btn_colors(btn_emergency_stop, Color(0.06, 0.38, 0.24), TTheme.ACCENT_EMERALD)
		else:
			btn_emergency_stop.text = "Parar Máquinas"
			TTheme.apply_btn_colors(btn_emergency_stop, Color(0.55, 0.10, 0.12), TTheme.ACCENT_RED)
	if _iot_relay_lbl != null and engaged:
		_iot_relay_lbl.text = "CCM: Abierto"
		_iot_relay_lbl.add_theme_color_override("font_color", TTheme.ACCENT_RED)
	if _header_status_panel != null and _header_status_lbl != null:
		if engaged:
			TTheme.set_badge_state(_header_status_panel, _header_status_lbl, "Parada", "CRITICAL")
		elif _last_severity == "NORMAL":
			TTheme.set_badge_state(_header_status_panel, _header_status_lbl, "Normal", "NORMAL")

func _toggle_audio_mute() -> void:
	_audio_muted = not _audio_muted
	if _iot_btn_audio != null:
		_iot_btn_audio.text = "Audio: OFF" if _audio_muted else "Audio: ON"
		var bg := Color(0.28, 0.16, 0.05) if _audio_muted else Color(0.06, 0.35, 0.26)
		TTheme.apply_btn_colors(_iot_btn_audio, bg, TTheme.ACCENT_AMBER if _audio_muted else TTheme.ACCENT_EMERALD)

func _select_cctv_camera(cam_id: String) -> void:
	var cctv = get_tree().root.find_child("MezzanineCCTVController", true, false) if is_inside_tree() else null
	if cctv != null and cctv.has_method("select_camera"):
		cctv.select_camera(cam_id)
	else:
		_on_cctv_camera_changed(cam_id, cam_id)

func _on_cctv_camera_changed(cam_id: String, cam_name: String) -> void:
	if lbl_cctv_status != null:
		lbl_cctv_status.text = "%s · %s" % [cam_id, cam_name]

func _on_safety_score_updated(current_score: float, history: Array) -> void:
	if lbl_academic_score != null:
		lbl_academic_score.text = "RETIE %.1f/5.0" % current_score
		var col := TTheme.ACCENT_EMERALD if current_score >= 4.0 else (TTheme.ACCENT_AMBER if current_score >= 3.0 else TTheme.ACCENT_RED)
		lbl_academic_score.add_theme_color_override("font_color", col)
	if not _cctv_handles.is_empty():
		var sl: Label = _cctv_handles["score_lbl"]
		sl.text = "%.1f / 5.0" % current_score
		sl.add_theme_color_override("font_color", TTheme.ACCENT_EMERALD if current_score >= 4.0 else TTheme.ACCENT_AMBER)
		var hvb: VBoxContainer = _cctv_handles["hist_vb"]
		for ch in hvb.get_children():
			ch.queue_free()
		if history.is_empty():
			hvb.add_child(TTheme.make_label("Sin infracciones registradas.", 10, TTheme.ACCENT_EMERALD))
		else:
			for entry in history.slice(maxi(0, history.size() - 6), history.size()):
				var is_v := str(entry.get("type", "")) == "VIOLATION"
				var msg := "%+.1f · %s" % [float(entry.get("delta", 0.0)), str(entry.get("description", ""))]
				var l := TTheme.make_label(msg, 10, TTheme.ACCENT_RED if is_v else TTheme.ACCENT_EMERALD)
				l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				hvb.add_child(l)

func _on_production_metrics_updated(metrics: Dictionary) -> void:
	_last_prod = metrics
	if not visible:
		return
	_set_tile("prod", "%.0f kg" % float(metrics.get("total_grain_milled_kg", 0.0)), "%d sacos 50 kg" % int(metrics.get("bags_50kg_produced", 0)), "NORMAL")
	_set_tile("truck", str(metrics.get("truck_cycle_phase", "ESPERA")), "%d pallets" % int(metrics.get("pallets_completed", 0)), "NORMAL")
	_sync_machine_telemetry_tiles()
	_sync_3d_card_huds()

func _on_epp_state_changed(all_eq: bool, items: Dictionary) -> void:
	if not _retie_handles.is_empty():
		var eq_cnt := 0
		for k in items.keys():
			if bool(items[k]):
				eq_cnt += 1
		var lbl: Label = _retie_handles["epp_live_lbl"]
		lbl.text = "EPP: %d / 6 · %s" % [eq_cnt, "Completo" if all_eq else "Pendiente"]
		lbl.add_theme_color_override("font_color", TTheme.ACCENT_EMERALD if all_eq else TTheme.ACCENT_AMBER)

func _on_golden_step(step_idx: int, rule_name: String) -> void:
	_append_blackbox("OK", "RETIE Regla %d completada: %s" % [step_idx, rule_name])
	_sync_live_plant_context()

func _on_telemetry_vector_updated(t: Dictionary) -> void:
	if t.is_empty():
		return
	_last_telemetry = t

	var ia := float(t.get("current_a", 0.0))
	var ib := float(t.get("current_b", 0.0))
	var ic := float(t.get("current_c", 0.0))
	var temp_c := float(t.get("temp_c", 28.0))
	var vib := float(t.get("vibration_rms", 0.0))

	# Actualización continua de gráficos para conservar historial temporal
	if chart_currents != null:
		chart_currents.push_currents(ia, ib, ic)
	if chart_temperature != null:
		chart_temperature.push_temperature(temp_c)
	if chart_vibration != null:
		chart_vibration.push_vibration(vib, bool(t.get("is_phase_l3_cut", false)), bool(t.get("is_bolts_loosened", false)))

	# OPTIMIZACIÓN: Si la tablet está cerrada, no formatear texto UI ni recorrer nodos 3D (ahorro 4.4 ms por tick)
	if not visible:
		return

	_update_telemetry_ui(t)

func _update_telemetry_ui(t: Dictionary) -> void:
	var ia := float(t.get("current_a", 0.0))
	var ib := float(t.get("current_b", 0.0))
	var ic := float(t.get("current_c", 0.0))
	var volt := float(t.get("voltage", 460.0))
	var freq := float(t.get("freq_hz", 60.0))
	var pf := float(t.get("power_factor", 0.85))
	var iuf := float(t.get("iuf_pct", 0.0))
	var thd := float(t.get("thd_pct", 0.0))
	var rpm := float(t.get("rpm", 0.0))
	var torque := float(t.get("torque_nm", 0.0))
	var p_kw := float(t.get("power_kw", 0.0))
	var temp_c := float(t.get("temp_c", 28.0))
	var d_temp := float(t.get("d_temp_dt_min", 0.0))
	var vib := float(t.get("vibration_rms", 0.0))
	var flow := float(t.get("flow_kg_s", 0.8))

	_set_tile("currents", "%.1f / %.1f / %.1f" % [ia, ib, ic], "IUF %.1f%% · %s" % [iuf, "Crítico" if iuf > 20 else "Nominal"], "CRITICAL" if iuf > 20 else ("WARNING" if iuf > 5 else "NORMAL"))
	_set_tile("voltage", "%.0f V · %.0f Hz" % [volt, freq], "cos φ %.2f" % pf, "CRITICAL" if volt < 400.0 else ("WARNING" if volt < 425.0 else "NORMAL"))
	_set_tile("temp", "%.1f °C" % temp_c, "%+.1f °C/m · Clase F" % d_temp, "CRITICAL" if temp_c >= 105.0 else ("WARNING" if temp_c >= 85.0 else "NORMAL"))
	var iso_lvl := "CRITICAL" if vib > 4.5 else ("WARNING" if vib > 2.3 else "NORMAL")
	var iso_txt := "Zona D Crítica" if vib > 4.5 else ("Zona C Alerta" if vib > 2.3 else "Zona A/B OK")
	_set_tile("vib", "%.2f mm/s" % vib, iso_txt, iso_lvl)
	_set_tile("rpm_torque", "%.0f RPM" % rpm, "%.1f N·m · %.2f kW" % [torque, p_kw], "NORMAL")
	_set_tile("flow", "%.2f kg/s" % flow, "Atasco > 3.0" if flow > 3.0 else "Flujo Nominal", "CRITICAL" if flow > 3.0 else "NORMAL")

	var energy: Dictionary = t.get("energy", {})
	var d_mode := str(energy.get("drive_mode", "VFD"))
	if btn_drive_mode != null:
		btn_drive_mode.text = "Modo: %s" % d_mode
	if _iot_relay_lbl != null:
		var sm_tel = get_node_or_null("/root/SimulationManager")
		var e_stopped: bool = sm_tel != null and sm_tel.has_method("is_emergency_stop_engaged") and sm_tel.is_emergency_stop_engaged()
		if e_stopped:
			_iot_relay_lbl.text = "CCM: Abierto"
			_iot_relay_lbl.add_theme_color_override("font_color", TTheme.ACCENT_RED)
		else:
			_iot_relay_lbl.text = "CCM: Cerrado · %s %.0f Hz" % [d_mode, freq]
			_iot_relay_lbl.add_theme_color_override("font_color", TTheme.ACCENT_EMERALD)
	if not energy.is_empty():
		var kwh_t := float(energy.get("specific_kwh_ton", 7.52))
		var sav := float(energy.get("savings_pct", 28.4))
		var co2 := float(energy.get("co2_avoided_kg", 0.0))
		_set_tile("energy", "%.2f kWh/t" % kwh_t, "%.1f%% ahorro vs DOL" % sav, "NORMAL" if d_mode == "VFD" else "WARNING")
		_set_tile("co2", "%.1f%% THD" % thd, "%.2f kg CO2e evitado" % co2, "WARNING" if thd > 8.0 else "NORMAL")

	_update_all_machine_charts_and_kpis(t)
	_sync_machine_telemetry_tiles()
	_sync_3d_card_huds()
	_sync_tablet_invariant_size()

func _update_all_machine_charts_and_kpis(t: Dictionary) -> void:
	if machine_charts.is_empty():
		return
	var glow_n := _get_glow_node()
	var rpm := float(t.get("rpm", 1750.0))
	var flow := float(t.get("flow_kg_s", 0.80))
	var temp_c := float(t.get("temp_c", 58.0))
	var vib := float(t.get("vibration_rms", 1.15))
	var rpm_ratio := clampf(rpm / 1750.0, 0.0, 1.3)

	for m_key in machine_charts.keys():
		var osc: TOscChart = machine_charts[m_key]
		var tiles: Dictionary = _machine_card_tiles.get(m_key, {})
		var st := _evaluate_equipment_status(m_key, m_key, glow_n)
		var sev := str(st.get("sev", "NORMAL"))
		var is_fault := (sev == "CRITICAL")
		var is_warn := (sev == "WARNING")
		var st_sub := "Falla" if is_fault else ("Alerta" if is_warn else "En línea")

		match m_key:
			"banda_descarga":
				var spd := 100.0 * rpm_ratio * (0.0 if is_fault else 1.0)
				var q := flow * (spd / 100.0)
				var ia := 4.5 * (spd / 100.0) * (1.8 if is_warn else 1.0)
				osc.push_generic(q, spd)
				_set_m_tile(tiles, "spd", "%.0f %%" % spd, "Normal" if spd > 20 else "Detenido", sev)
				_set_m_tile(tiles, "flow", "%.2f kg/s" % q, "Caudal", sev)
				_set_m_tile(tiles, "cur", "%.1f A" % ia, "Motor", sev)
				_set_m_tile(tiles, "st", str(st.get("badge", "OK")), st_sub, sev)

			"banda_inclinada_tolva":
				var spd := 100.0 * rpm_ratio * (0.0 if is_fault else 1.0)
				var q := flow * (spd / 100.0)
				var ia := 5.2 * (spd / 100.0) * (2.1 if is_fault else (1.5 if is_warn else 1.0))
				osc.push_generic(ia, q)
				_set_m_tile(tiles, "cur", "%.1f A" % ia, "Sobrecarga" if is_warn else "Normal", sev)
				_set_m_tile(tiles, "flow", "%.2f kg/s" % q, "Caudal", sev)
				_set_m_tile(tiles, "spd", "%.0f %%" % spd, "Velocidad", sev)
				_set_m_tile(tiles, "st", str(st.get("badge", "OK")), st_sub, sev)

			"hopper":
				var lvl := clampf(35.0 + flow * 35.0, 5.0, 98.0) * (1.15 if is_warn else 1.0)
				var w_kg := (lvl / 100.0) * 5000.0
				osc.push_generic(lvl, flow)
				_set_m_tile(tiles, "level", "%.1f %%" % lvl, "Nivel", sev)
				_set_m_tile(tiles, "flow", "%.2f kg/s" % flow, "Compuerta", sev)
				_set_m_tile(tiles, "weight", "%.0f kg" % w_kg, "Carga", sev)
				_set_m_tile(tiles, "st", str(st.get("badge", "OK")), st_sub, sev)

			"banda_trituradora":
				var spd := 85.0 * rpm_ratio * (0.0 if is_fault else 1.0)
				var load := clampf(flow * 105.0, 10.0, 99.0)
				var ia := 3.8 * (spd / 85.0)
				osc.push_generic(spd, load)
				_set_m_tile(tiles, "spd", "%.0f %%" % spd, "VFD", sev)
				_set_m_tile(tiles, "flow", "%.2f kg/s" % flow, "Caudal", sev)
				_set_m_tile(tiles, "cur", "%.1f A" % ia, "Motor", sev)
				_set_m_tile(tiles, "st", str(st.get("badge", "OK")), st_sub, sev)

			"tornillo_trituradora":
				var s_rpm := 125.0 * rpm_ratio * (0.0 if is_fault else 1.0)
				var ia := 6.4 * (s_rpm / 125.0) * (2.2 if is_fault else (1.4 if is_warn else 1.0))
				var trq := 48.0 * (ia / 6.4)
				osc.push_generic(s_rpm, ia)
				_set_m_tile(tiles, "rpm", "%.0f RPM" % s_rpm, "Giro", sev)
				_set_m_tile(tiles, "cur", "%.1f A" % ia, "Carga", sev)
				_set_m_tile(tiles, "trq", "%.1f N·m" % trq, "Par", sev)
				_set_m_tile(tiles, "st", str(st.get("badge", "OK")), st_sub, sev)

			"tornillo_secador":
				var s_rpm := 95.0 * rpm_ratio * (0.0 if is_fault else 1.0)
				var q := flow * 0.95 * (s_rpm / 95.0)
				var ia := 4.8 * (s_rpm / 95.0)
				osc.push_generic(s_rpm, q)
				_set_m_tile(tiles, "rpm", "%.0f RPM" % s_rpm, "Giro", sev)
				_set_m_tile(tiles, "flow", "%.2f kg/s" % q, "Caudal", sev)
				_set_m_tile(tiles, "cur", "%.1f A" % ia, "Motor", sev)
				_set_m_tile(tiles, "st", str(st.get("badge", "OK")), st_sub, sev)

			"secador_rotatorio":
				var dry_t := temp_c + 14.0 + (32.0 if is_fault else 0.0)
				var hum := clampf(18.5 - (dry_t / 8.5), 9.0, 24.0)
				var drum_rpm := 18.5 * rpm_ratio
				osc.push_generic(dry_t, hum)
				_set_m_tile(tiles, "temp", "%.1f °C" % dry_t, "Tambor", sev)
				_set_m_tile(tiles, "hum", "%.1f %%" % hum, "Seco" if hum < 14.0 else "Húmedo", sev)
				_set_m_tile(tiles, "rpm", "%.1f RPM" % drum_rpm, "Giro", sev)
				_set_m_tile(tiles, "st", str(st.get("badge", "OK")), st_sub, sev)

			"ciclon_separador":
				var dp := 1.45 * rpm_ratio * (2.6 if is_fault else 1.0)
				var eff := clampf(98.5 - (dp - 1.45) * 8.0, 60.0, 99.5)
				var q_air := 38.0 * rpm_ratio
				osc.push_generic(dp, eff)
				_set_m_tile(tiles, "dp", "%.2f kPa" % dp, "Presión", sev)
				_set_m_tile(tiles, "eff", "%.1f %%" % eff, "Captura", sev)
				_set_m_tile(tiles, "flow", "%.1f m³/m" % q_air, "Aire", sev)
				_set_m_tile(tiles, "st", str(st.get("badge", "OK")), st_sub, sev)

			"cyclone":
				var lel := 8.5 * (3.8 if is_fault else (1.8 if is_warn else 1.0))
				var pres := 1.20 * rpm_ratio
				var flow_f := flow * 0.98
				osc.push_generic(lel, pres)
				_set_m_tile(tiles, "atex", "%.1f %% LEL" % lel, "ATEX 22", sev)
				_set_m_tile(tiles, "pres", "%.2f kPa" % pres, "Presión", sev)
				_set_m_tile(tiles, "flow", "%.2f kg/s" % flow_f, "Caudal", sev)
				_set_m_tile(tiles, "st", str(st.get("badge", "OK")), st_sub, sev)

			"unidad_extraccion":
				var q_ext := 42.0 * rpm_ratio * (0.25 if is_fault else 1.0)
				var vac := 2.35 * rpm_ratio * (0.3 if is_fault else 1.0)
				var ia := 7.2 * rpm_ratio * (1.7 if is_fault else 1.0)
				osc.push_generic(q_ext, vac)
				_set_m_tile(tiles, "flow", "%.1f m³/m" % q_ext, "Caudal", sev)
				_set_m_tile(tiles, "vac", "%.2f kPa" % vac, "Succión", sev)
				_set_m_tile(tiles, "cur", "%.1f A" % ia, "Motor", sev)
				_set_m_tile(tiles, "st", str(st.get("badge", "OK")), st_sub, sev)

			"horno":
				var h_temp := 185.0 + (temp_c - 58.0) * 0.5 + (45.0 if is_fault else 0.0)
				var pwr := 24.0 * (h_temp / 185.0)
				var t_air := 92.0 + (h_temp - 185.0) * 0.35
				osc.push_generic(h_temp, pwr)
				_set_m_tile(tiles, "temp", "%.1f °C" % h_temp, "Cámara", sev)
				_set_m_tile(tiles, "pwr", "%.1f kW" % pwr, "Potencia", sev)
				_set_m_tile(tiles, "air", "%.1f °C" % t_air, "Salida", sev)
				_set_m_tile(tiles, "st", str(st.get("badge", "OK")), st_sub, sev)

			"soplador":
				var pres := 6.40 * rpm_ratio * (0.15 if is_fault else 1.0)
				var v_s := vib * (2.8 if is_fault else 1.0)
				var ia := 8.5 * rpm_ratio * (1.9 if is_fault else 1.0)
				osc.push_generic(pres, v_s)
				_set_m_tile(tiles, "pres", "%.2f kPa" % pres, "Presión", sev)
				_set_m_tile(tiles, "vib", "%.2f mm/s" % v_s, "Vibración", sev)
				_set_m_tile(tiles, "cur", "%.1f A" % ia, "Motor", sev)
				_set_m_tile(tiles, "st", str(st.get("badge", "OK")), st_sub, sev)

			"intercambiador_calor":
				var t_in := 85.0 + (temp_c - 58.0) * 0.4
				var t_out := 42.0 + (temp_c - 58.0) * 0.2 + (28.0 if is_fault else 0.0)
				var eff := clampf(82.0 - (t_out - 42.0) * 1.5, 45.0, 95.0)
				osc.push_generic(t_in, t_out)
				_set_m_tile(tiles, "tin", "%.1f °C" % t_in, "Entrada", sev)
				_set_m_tile(tiles, "tout", "%.1f °C" % t_out, "Salida", sev)
				_set_m_tile(tiles, "eff", "%.1f %%" % eff, "Eficiencia", sev)
				_set_m_tile(tiles, "st", str(st.get("badge", "OK")), st_sub, sev)

			"ductos_aire":
				var pres := 5.80 * rpm_ratio * (0.25 if is_fault else 1.0)
				var vel := 22.5 * rpm_ratio
				var leak := 100.0 if not is_fault else 45.0
				osc.push_generic(pres, vel)
				_set_m_tile(tiles, "pres", "%.2f kPa" % pres, "Presión", sev)
				_set_m_tile(tiles, "vel", "%.1f m/s" % vel, "Flujo", sev)
				_set_m_tile(tiles, "leak", "%.0f %%" % leak, "Sellado" if leak > 80 else "Fuga", sev)
				_set_m_tile(tiles, "st", str(st.get("badge", "OK")), st_sub, sev)

func _set_m_tile(tiles: Dictionary, k: String, val_txt: String, badge_txt: String, sev: String) -> void:
	if not tiles.has(k):
		return
	var tile: Dictionary = tiles[k]
	(tile["value"] as Label).text = val_txt
	TTheme.set_badge_state(tile["badge_panel"], tile["badge"], badge_txt, sev)

func _on_ai_alert_received(alert_data: Dictionary) -> void:
	if alert_data.is_empty():
		return
	_last_alert = alert_data
	var severity := str(alert_data.get("severity", "NORMAL"))
	var title_txt := str(alert_data.get("title", "Operación normal"))
	if (severity == "CRITICAL" or severity == "WARNING") and severity != _last_severity:
		var detail_str := "%s | %s" % [str(alert_data.get("root_cause", "")), str(alert_data.get("prescription", ""))]
		_push_tablet_warning(title_txt, detail_str, severity)
	elif severity == "NORMAL" and _last_severity != "NORMAL":
		_append_blackbox("OK", "Condición de planta restablecida a operación normal.")
		if _warning_banner_card != null:
			_warning_banner_card.visible = false
	_last_severity = severity

	var keep_manual_warning := (severity == "NORMAL" and _warning_banner_card != null and _warning_banner_card.visible)
	if not keep_manual_warning:
		if _iot_alert_lbl != null:
			_iot_alert_lbl.text = _clamp_str(title_txt, 68)
			_iot_alert_lbl.tooltip_text = title_txt
			var col := TTheme.ACCENT_RED if severity == "CRITICAL" else (TTheme.ACCENT_AMBER if severity == "WARNING" else TTheme.ACCENT_EMERALD)
			_iot_alert_lbl.add_theme_color_override("font_color", col)

		var st_txt := "Normal"
		if severity == "WARNING":
			st_txt = "Alerta"
		elif severity == "CRITICAL":
			st_txt = "Falla crítica"
		TTheme.set_badge_state(_header_status_panel, _header_status_lbl, st_txt, severity)

	var mlp_c := float(alert_data.get("mlp_confidence", alert_data.get("confidence", 99.1)))
	var svm_c := float(alert_data.get("svm_confidence", 98.7))
	_set_tile("conf", "%.1f %%" % mlp_c, "SVM %.1f%%" % svm_c, severity)

	var mhi := float(alert_data.get("mhi", 95.0))
	var rul_h := float(alert_data.get("rul_hours", 24000.0))
	_set_tile("mhi", "%.1f %%" % mhi, "RUL %.0f h" % rul_h, "CRITICAL" if mhi < 60.0 else ("WARNING" if mhi < 85.0 else "NORMAL"))

	if not _hw_ai_handles.is_empty():
		(_hw_ai_handles["lbl_conf"] as Label).text = "MLP %.1f%% · SVM %.1f%%" % [mlp_c, svm_c]
		lbl_root_cause.text = "Causa: " + _clamp_str(str(alert_data.get("root_cause", "")), 140)
		lbl_prognosis.text = "Pronóstico: " + _clamp_str(str(alert_data.get("prognosis", "")), 140)
		lbl_prescription.text = "Acción: " + _clamp_str(str(alert_data.get("prescription", "")), 140)
		mhi_progress_bar.value = mhi
		lbl_mhi_value.text = "MHI: %.1f %%" % mhi
		lbl_rul_value.text = "RUL: %.0f h" % rul_h

	if checklist_container != null:
		for c in checklist_container.get_children():
			c.queue_free()
		for step in alert_data.get("maintenance_steps", []):
			var cb := CheckBox.new()
			cb.text = str(step)
			cb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cb.add_theme_font_size_override("font_size", 10)
			cb.add_theme_color_override("font_color", TTheme.TEXT_WHITE)
			checklist_container.add_child(cb)
	_sync_tablet_invariant_size()

func _sync_live_plant_context() -> void:
	if not is_inside_tree():
		return
	var sm_sync = get_node_or_null("/root/SimulationManager")
	if sm_sync != null and sm_sync.has_method("is_emergency_stop_engaged"):
		_sync_emergency_stop_ui(sm_sync.is_emergency_stop_engaged())
	var r := get_tree().root

	# Sincronizar Operario jugador & PlantStaff reales en Tab 4 y Visores 3D
	if not _workers_handles.is_empty():
		var tour := r.find_child("TutorialInductionManager", true, false)
		var player := r.find_child("PlayerOperator", true, false)
		var scorecard := r.find_child("SafetyEvaluationScorecard", true, false)
		var p_lbl: Label = _workers_handles["player_lbl"]
		var st_idx: int = int(tour.get("current_station_idx")) if tour != null else 1
		var st_total: int = tour.STATIONS.size() if (tour != null and "STATIONS" in tour) else 19
		var epp_ok: bool = bool(tour.get("epp_completed")) if tour != null else false
		var sc_val: float = float(scorecard.get("score")) if scorecard != null else 5.0
		var tool_name: String = str(player.get("current_tool_name")) if (player != null and player.get("current_tool_name") != null) else "Manos / Herramienta"
		p_lbl.text = "Estación %d/%d · EPP %s · Nota %.1f" % [st_idx, st_total, "OK" if epp_ok else "Pendiente", sc_val]

		var w_cards: Dictionary = _workers_handles["worker_cards"]
		for spec in TCatalog.PLANT_WORKERS_SPEC:
			var wid: String = spec["id"]
			var wn := r.find_child(wid, true, false) as Node3D
			var lbl := w_cards.get(wid) as Label
			if lbl != null:
				lbl.text = str(spec["station"])

	# Sincronizar 5 Reglas de Oro en Tab 3 (mostrar insignia únicamente cuando la regla esté aplicada, sin etiqueta "Pendiente")
	if not _retie_handles.is_empty():
		var tour := r.find_child("TutorialInductionManager", true, false)
		if tour != null and tour.get("loto_controller") != null:
			var st_arr: Array = tour.loto_controller.get_rules_status()
			var badges: Array = _retie_handles["rule_badges"]
			for i in range(mini(st_arr.size(), badges.size())):
				var done := bool(st_arr[i].get("done", false))
				var bp := badges[i]["panel"] as Control
				if bp != null:
					bp.visible = done
				if done:
					TTheme.set_badge_state(badges[i]["panel"], badges[i]["label"], "Aplicada", "NORMAL")

	# Sincronizar estaciones del recorrido en Tab 8
	if not _cctv_handles.is_empty():
		var tour := r.find_child("TutorialInductionManager", true, false)
		if tour != null:
			var visited: Dictionary = tour.get("visited_stations") if tour.get("visited_stations") != null else {}
			var curr_id: int = int(tour.get("target_station_id")) if tour.get("target_station_id") != null else 2
			var sls: Array = _cctv_handles["station_labels"]
			var st_tot: int = tour.STATIONS.size() if "STATIONS" in tour else sls.size()
			for i in range(mini(st_tot, sls.size())):
				var sid := i + 1
				var l: Label = sls[i]
				if visited.has(sid):
					l.text = "E%d · OK" % sid
					l.add_theme_color_override("font_color", TTheme.ACCENT_EMERALD)
				elif sid == curr_id:
					l.text = "E%d · Actual" % sid
					l.add_theme_color_override("font_color", TTheme.ACCENT_CYAN)
				else:
					l.text = "E%d" % sid
					l.add_theme_color_override("font_color", TTheme.TEXT_MUTED)
	_sync_machine_telemetry_tiles()
	_sync_3d_card_huds()

var _cached_glow_node: Node = null
var _cached_worker_nodes: Dictionary = {}

func _get_glow_node() -> Node:
	if not is_instance_valid(_cached_glow_node):
		if not is_inside_tree() or get_tree() == null:
			return null
		_cached_glow_node = get_tree().root.find_child("InteractableGlowController", true, false)
	return _cached_glow_node

func _evaluate_equipment_status(glow_grp: String, card_id: String, glow_n: Node) -> Dictionary:
	var ia := float(_last_telemetry.get("current_a", 13.5))
	var volt := float(_last_telemetry.get("voltage", 460.0))
	var freq := float(_last_telemetry.get("freq_hz", 60.0))
	var rpm := float(_last_telemetry.get("rpm", 1750.0))
	var temp := float(_last_telemetry.get("temp_c", 58.0))
	var vib := float(_last_telemetry.get("vibration_rms", 1.15))
	var flow := float(_last_telemetry.get("flow_kg_s", 0.80))
	var eff := float(_last_prod.get("line_flow_efficiency", 1.0)) * 100.0
	var kg := float(_last_prod.get("total_grain_milled_kg", 0.0))
	var bags := int(_last_prod.get("bags_50kg_produced", 0))
	var global_sev := str(_last_alert.get("severity", "NORMAL"))

	var fault_active := false
	var st_str := "WHITE"
	if glow_n != null and glow_grp != "":
		if glow_n.has_method("is_machine_fault_active"):
			fault_active = bool(glow_n.is_machine_fault_active(glow_grp))
		if glow_n.has_method("get_group_state"):
			st_str = str(glow_n.get_group_state(glow_grp))

	var sev := "CRITICAL" if (fault_active or st_str == "RED" or st_str == "RED_HOVER") else ("WARNING" if st_str == "YELLOW" else "NORMAL")
	var badge := "Falla" if sev == "CRITICAL" else ("Alerta" if sev == "WARNING" else "Normal")

	match glow_grp:
		"motor":
			var m_sev := sev if sev != "NORMAL" else global_sev
			var m_badge := "Detenido" if rpm < 15.0 else ("Falla" if m_sev == "CRITICAL" else ("Alerta" if m_sev == "WARNING" else "Normal"))
			return {"val": "%.0f RPM · %.1f °C" % [rpm, temp], "badge": m_badge, "sev": m_sev,
				"hud": PackedStringArray(["%.0f RPM · %.1f A" % [rpm, ia], "%.1f °C · %.2f mm/s" % [temp, vib], m_badge])}
		"breaker":
			var b_crit := fault_active or volt < 400.0
			var b_sev := "CRITICAL" if b_crit else ("WARNING" if volt < 438.0 else "NORMAL")
			var b_badge := "Bajón" if b_crit else ("Alerta" if b_sev == "WARNING" else "Normal")
			return {"val": "%.0f V · %.0f Hz" % [volt, freq], "badge": b_badge, "sev": b_sev,
				"hud": PackedStringArray(["%.1f V · %.1f Hz" % [volt, freq], "Breakers: %s" % ("Falla" if b_crit else "Cerrados"), "CCM 460 V"])}
		"hopper":
			var h_crit := fault_active or flow > 3.0
			var h_sev := "CRITICAL" if h_crit else ("WARNING" if (flow > 1.15 or sev == "WARNING") else "NORMAL")
			var h_badge := "Atasco" if h_crit else ("Alto" if h_sev == "WARNING" else "Normal")
			return {"val": "%.2f kg/s" % flow, "badge": h_badge, "sev": h_sev,
				"hud": PackedStringArray(["Flujo: %.2f kg/s" % flow, "Línea: %.0f %%" % eff, h_badge])}
		"cyclone", "ciclon_separador", "unidad_extraccion":
			var a_badge := "Falla" if sev == "CRITICAL" else ("Alerta" if sev == "WARNING" else "OK")
			return {"val": "Polvo %s" % ("crítico" if sev == "CRITICAL" else "normal"), "badge": a_badge, "sev": sev,
				"hud": PackedStringArray(["ATEX 22", a_badge])}
		"horno", "secador_rotatorio", "intercambiador_calor":
			var t_val := temp + (26.0 if fault_active else 0.0)
			return {"val": "%.1f °C · %.0f%%" % [t_val, eff], "badge": badge, "sev": sev,
				"hud": PackedStringArray(["%.1f °C" % t_val, "Flujo: %.0f %%" % eff, badge])}
		"soplador", "ductos_aire":
			var s_vib := vib + (2.4 if fault_active else 0.0)
			return {"val": "%.2f mm/s · %.0f%%" % [s_vib, eff], "badge": badge, "sev": sev,
				"hud": PackedStringArray(["Caudal: %.0f %%" % eff, "%.2f mm/s" % s_vib, badge])}
		"banda_descarga", "banda_inclinada_tolva", "banda_trituradora", "tornillo_trituradora", "tornillo_secador":
			var belt_spd := (rpm / 1750.0) * 100.0 * (0.0 if fault_active else 1.0)
			return {"val": "%.0f%% · %.2f kg/s" % [belt_spd, flow], "badge": badge, "sev": sev,
				"hud": PackedStringArray(["Velocidad: %.0f%%" % belt_spd, "Caudal: %.2f kg/s" % flow, badge])}
		"truck":
			return {"val": "%s · %d u" % [str(_last_prod.get("truck_cycle_phase", "Espera")), bags], "badge": "Activo", "sev": "NORMAL",
				"hud": PackedStringArray(["Fase: %s" % str(_last_prod.get("truck_cycle_phase", "Espera")), "Molido: %.0f kg" % kg, "Sacos: %d" % bags])}
		"bag":
			return {"val": "%d sacos" % bags, "badge": "Normal", "sev": "NORMAL",
				"hud": PackedStringArray(["Pallets: %d" % int(_last_prod.get("pallets_completed", 0)), "Sacos: %d" % bags])}
		_:
			return {"val": "%.0f%% línea" % eff, "badge": "En vivo", "sev": global_sev,
				"hud": PackedStringArray(["Línea: %.0f%% · %.0f kg" % [eff, kg], global_sev])}

func _sync_machine_telemetry_tiles() -> void:
	if not visible or _machine_tiles.is_empty():
		return
	var glow_n := _get_glow_node()
	for gk_v in _machine_tiles.keys():
		var gk := str(gk_v)
		var st := _evaluate_equipment_status(gk, gk, glow_n)
		var tile: Dictionary = _machine_tiles[gk]
		(tile["value"] as Label).text = str(st["val"])
		TTheme.set_badge_state(tile["badge_panel"], tile["badge"], str(st["badge"]), str(st["sev"]))

func _sync_3d_card_huds() -> void:
	if not visible:
		return
	var glow_n := _get_glow_node()
	for gid in _cards_by_3d_group.keys():
		if gid == "WORKERS":
			continue
		for c in (_cards_by_3d_group[gid] as Array):
			var st := _evaluate_equipment_status(c.glow_group, c.card_id, glow_n)
			c.set_hud_status(st["hud"], str(st["badge"]), str(st["sev"]))

	var root_n := get_tree().root if is_inside_tree() else null
	for c in _cards_3d_workers:
		var wn: Node3D = _cached_worker_nodes.get(c.card_id, null) as Node3D
		if not is_instance_valid(wn) and root_n != null:
			wn = root_n.find_child(c.card_id, true, false) as Node3D
			if wn != null:
				_cached_worker_nodes[c.card_id] = wn
		if wn != null:
			c.set_hud_status(PackedStringArray(["X %.1f · Z %.1f" % [wn.global_position.x, wn.global_position.z], "EPP completo"]), "Activo", "NORMAL")
		else:
			c.set_hud_status(PackedStringArray(["EPP completo"]), "Activo", "NORMAL")

func _on_register_worker(n: String, l: String, age: String, rh: String, role: String) -> void:
	if n.strip_edges().is_empty() or _workers_handles.is_empty():
		return
	_custom_workers.append({"name": (n + " " + l).strip_edges(), "age": age if age != "" else "25", "rh": rh.replace("Grupo RH: ", ""), "role": role})
	_refresh_custom_workers_ui()

func _on_clear_custom_workers() -> void:
	_custom_workers.clear()
	_refresh_custom_workers_ui()

func _refresh_custom_workers_ui() -> void:
	if _workers_handles.is_empty():
		return
	var cl: VBoxContainer = _workers_handles["custom_list"]
	for ch in cl.get_children():
		ch.queue_free()
	if _custom_workers.is_empty():
		cl.add_child(TTheme.make_label("Sin registros adicionales.", 10, TTheme.TEXT_MUTED))
		return
	for w in _custom_workers:
		cl.add_child(TTheme.make_label("%s · %s años · %s · %s" % [w["name"], w["age"], w["rh"], w["role"]], 10, TTheme.ACCENT_EMERALD))

func _set_tile(key: String, val_txt: String, badge_txt: String, severity: String) -> void:
	if not _tiles.has(key):
		return
	var tile: Dictionary = _tiles[key]
	(tile["value"] as Label).text = val_txt
	TTheme.set_badge_state(tile["badge_panel"], tile["badge"], badge_txt, severity)

func _append_blackbox(level: String, msg: String) -> void:
	if _blackbox_lbl == null:
		return
	var stamp := Time.get_time_string_from_system()
	var col := "#38bdf8"
	if level == "OK": col = "#10b981"
	elif level == "WARNING": col = "#f59e0b"
	elif level == "CRITICAL" or level == "ERROR": col = "#ef4444"
	_blackbox_lbl.append_text("[color=%s][%s] [%s] %s[/color]\n" % [col, stamp, level, msg])

func _sync_tablet_invariant_size() -> void:
	var chassis := get_node_or_null("TabletChassis")
	if chassis != null and chassis.has_method("enforce_invariant_size"):
		chassis.enforce_invariant_size()

func _clamp_str(raw: String, max_len: int) -> String:
	if raw.length() <= max_len:
		return raw
	return raw.substr(0, max_len - 3).strip_edges() + "..."

func _normalize_warning_key(raw: String) -> String:
	var s := raw.strip_edges().to_lower()
	for rep in ["⚠", "⚡", "🔴", "🟡", "·", "•", "-", "_", ":", ".", ",", ";", "!", "?", "(", ")", "[", "]", "/"]:
		s = s.replace(rep, " ")
	s = s.replace("á", "a").replace("é", "e").replace("í", "i").replace("ó", "o").replace("ú", "u").replace("ñ", "n")
	while "  " in s:
		s = s.replace("  ", " ")
	return s.strip_edges()

func _clean_history_text(raw: String) -> String:
	var s := raw.strip_edges()
	for sym in ["⚠", "⚡", "🔴", "🟡", "🟢", "🔵", "✅", "❌"]:
		s = s.replace(sym, "")
	while "  " in s:
		s = s.replace("  ", " ")
	return s.strip_edges()

func _record_notification_history(title_txt: String, detail_txt: String, severity_norm: String) -> void:
	var ct := _clean_history_text(title_txt)
	var cm := _clean_history_text(detail_txt)
	if ct == "" and cm == "":
		return
	var now_ms := Time.get_ticks_msec()
	var hkey := severity_norm + "|" + _normalize_warning_key(ct) + "|" + _normalize_warning_key(cm)
	if hkey == _last_history_key and (now_ms - _last_history_ms) < 1200:
		return
	_last_history_key = hkey
	_last_history_ms = now_ms

	_notification_history.push_front({
		"timestamp": Time.get_time_string_from_system(),
		"title": ct,
		"message": cm,
		"severity": severity_norm
	})
	while _notification_history.size() > MAX_NOTIFICATION_HISTORY:
		_notification_history.pop_back()
	_rebuild_notification_history_ui()

func _on_notif_history_filter_selected(filter_id: String) -> void:
	_notif_hist_filter = filter_id
	if not _notif_hist_handles.is_empty():
		var fbtns: Dictionary = _notif_hist_handles.get("filter_btns", {})
		for fid in fbtns.keys():
			var b := fbtns[fid] as Button
			if b != null:
				var active := (str(fid) == _notif_hist_filter)
				TTheme.apply_btn_colors(b, TTheme.ACCENT_BLUE if active else TTheme.BG_SUBCARD, TTheme.ACCENT_CYAN if active else TTheme.BORDER_SUBTLE)
	_rebuild_notification_history_ui()

func _on_clear_notif_history() -> void:
	_notification_history.clear()
	_rebuild_notification_history_ui()

func get_notification_history_count() -> int:
	return _notification_history.size()

func _rebuild_notification_history_ui() -> void:
	if _notif_hist_handles.is_empty():
		return
	var list_vb := _notif_hist_handles.get("list_vb", null) as VBoxContainer
	var kpis: Dictionary = _notif_hist_handles.get("kpi_labels", {})
	if list_vb == null:
		return

	var cnt_crit := 0
	var cnt_warn := 0
	var cnt_info_ok := 0
	for item in _notification_history:
		var sev := str(item.get("severity", "INFO"))
		if sev == "CRITICAL":
			cnt_crit += 1
		elif sev == "WARNING":
			cnt_warn += 1
		else:
			cnt_info_ok += 1

	if kpis.has("ALL"): (kpis["ALL"] as Label).text = str(_notification_history.size())
	if kpis.has("CRITICAL"): (kpis["CRITICAL"] as Label).text = str(cnt_crit)
	if kpis.has("WARNING"): (kpis["WARNING"] as Label).text = str(cnt_warn)
	if kpis.has("INFO_OK"): (kpis["INFO_OK"] as Label).text = str(cnt_info_ok)

	for ch in list_vb.get_children():
		list_vb.remove_child(ch)
		ch.queue_free()

	var shown := 0
	for item in _notification_history:
		var sev := str(item.get("severity", "INFO"))
		if _notif_hist_filter != "ALL" and sev != _notif_hist_filter:
			continue
		var accent := TTheme.ACCENT_CYAN
		var bg := Color(0.05, 0.09, 0.15, 0.92)
		var pill_txt := "INFO"
		if sev == "CRITICAL":
			accent = TTheme.ACCENT_RED
			bg = Color(0.16, 0.04, 0.05, 0.94)
			pill_txt = "CRÍTICA"
		elif sev == "WARNING":
			accent = TTheme.ACCENT_AMBER
			bg = Color(0.14, 0.09, 0.03, 0.92)
			pill_txt = "ALERTA"
		elif sev == "SUCCESS":
			accent = TTheme.ACCENT_EMERALD
			bg = Color(0.04, 0.14, 0.10, 0.92)
			pill_txt = "ÉXITO"

		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", TTheme.make_left_stripe_card(accent, bg))
		list_vb.add_child(card)

		var cvb := VBoxContainer.new()
		cvb.add_theme_constant_override("separation", 3)
		card.add_child(cvb)

		var chdr := HBoxContainer.new()
		chdr.add_theme_constant_override("separation", 8)
		cvb.add_child(chdr)

		var p_wrap := PanelContainer.new()
		p_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p_wrap.add_theme_stylebox_override("panel", TTheme.make_pill_style(Color(accent.r * 0.25, accent.g * 0.25, accent.b * 0.25, 0.95), accent))
		chdr.add_child(p_wrap)
		p_wrap.add_child(TTheme.make_label(pill_txt, 9, accent, HORIZONTAL_ALIGNMENT_CENTER))

		var tl := TTheme.make_label(str(item.get("title", "")), 11, Color(0.95, 0.97, 1.0))
		tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tl.clip_text = true
		tl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		chdr.add_child(tl)

		chdr.add_child(TTheme.make_label(str(item.get("timestamp", "")), 10, TTheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_RIGHT))

		var body_txt := str(item.get("message", ""))
		if body_txt != "":
			var ml := TTheme.make_label(body_txt, 10, Color(0.84, 0.89, 0.96))
			ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cvb.add_child(ml)

		shown += 1

	if shown == 0:
		var empty_lbl := TTheme.make_label("Sin notificaciones registradas en esta categoría.", 11, TTheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		list_vb.add_child(empty_lbl)

func _on_bus_notification_posted(title: String, message: String, severity: String) -> void:
	var sev_low := severity.to_lower()
	var norm_all := "INFO"
	if sev_low == "error" or sev_low == "critical":
		norm_all = "CRITICAL"
	elif sev_low == "warning":
		norm_all = "WARNING"
	elif sev_low == "success" or sev_low == "ok":
		norm_all = "SUCCESS"
	_record_notification_history(title, message, norm_all)

	if norm_all != "WARNING" and norm_all != "CRITICAL":
		return
	if norm_all == "CRITICAL":
		_last_critical_notif_ms = Time.get_ticks_msec()
	_push_tablet_warning(title, message, norm_all)

func _on_safety_line_crossed_warning(active: bool, zone_id: String, title: String, message: String) -> void:
	if not active:
		return
	var now_ms := Time.get_ticks_msec()
	var last_z := int(_hazard_tablet_cooldown_ms.get(zone_id, -999999))
	if (now_ms - last_z) < 3500:
		return
	_hazard_tablet_cooldown_ms[zone_id] = now_ms
	_record_notification_history(title, message, "CRITICAL")
	_push_tablet_warning(title, message, "CRITICAL")

func _on_safety_violation_warning(_code: String, description: String, penalty: float) -> void:
	var now_ms := Time.get_ticks_msec()
	# Si acaba de entrar una notificación CRITICAL por el mismo evento en el mismo instante, fusionar la sanción sin duplicar alerta
	if (now_ms - _last_critical_notif_ms) <= 800:
		_append_blackbox("CRITICAL", "Penalización RETIE (-%.1f) · %s" % [absf(penalty), _clamp_str(description, 100)])
		if _warning_banner_body != null and not _warning_banner_body.text.contains("RETIE"):
			_warning_banner_body.text = _clamp_str(_warning_banner_body.text + " (RETIE -%.1f)" % absf(penalty), 120)
		if not _notification_history.is_empty():
			var top_entry: Dictionary = _notification_history[0]
			var m_cur := str(top_entry.get("message", ""))
			if not m_cur.contains("RETIE"):
				top_entry["message"] = (m_cur + " (RETIE -%.1f)" % absf(penalty)).strip_edges()
				_rebuild_notification_history_ui()
		return
	var title_txt := "Infracción RETIE · -%.1f" % absf(penalty)
	_record_notification_history(title_txt, description, "CRITICAL")
	_push_tablet_warning(title_txt, description, "CRITICAL")

func _push_tablet_warning(title_txt: String, detail_txt: String, severity_norm: String) -> void:
	var now_ms := Time.get_ticks_msec()
	var nkey := severity_norm + "|" + _normalize_warning_key(title_txt)
	if nkey == _last_warning_key and (now_ms - _last_warning_ms) < 2500:
		return
	_last_warning_key = nkey
	_last_warning_ms = now_ms

	_append_blackbox(severity_norm, "%s · %s" % [title_txt, _clamp_str(detail_txt, 110)])

	if not _audio_muted and audio_alert != null:
		if audio_alert.stream == null:
			audio_alert.stream = SoundSynth.create_tablet_push_warning_sound()
		if (now_ms - _last_chime_ms) >= 900:
			_last_chime_ms = now_ms
			audio_alert.stop()
			audio_alert.play()

	var is_crit := (severity_norm == "CRITICAL")
	var accent := TTheme.ACCENT_RED if is_crit else TTheme.ACCENT_AMBER
	var bg := Color(0.18, 0.04, 0.05, 0.96) if is_crit else Color(0.14, 0.09, 0.03, 0.96)

	if _warning_banner_card != null:
		_warning_banner_card.add_theme_stylebox_override("panel", TTheme.make_left_stripe_card(accent, bg))
		if _warning_banner_title != null:
			_warning_banner_title.text = _clamp_str(title_txt, 82)
			_warning_banner_title.tooltip_text = title_txt
		if _warning_banner_body != null:
			_warning_banner_body.text = _clamp_str(detail_txt, 120)
			_warning_banner_body.tooltip_text = detail_txt
		_warning_banner_card.visible = true

	if _iot_alert_lbl != null:
		_iot_alert_lbl.text = _clamp_str(title_txt, 68)
		_iot_alert_lbl.add_theme_color_override("font_color", accent)

	var st_pill := "Falla crítica" if is_crit else "Alerta"
	TTheme.set_badge_state(_header_status_panel, _header_status_lbl, st_pill, severity_norm)

	if not visible:
		if not _unread_warning_keys.has(nkey):
			_unread_warning_keys[nkey] = true
			_unread_warning_count += 1
		_has_unread_warning = true

	_active_warning_data = {
		"title": title_txt,
		"detail": detail_txt,
		"severity": severity_norm,
		"timestamp": Time.get_time_string_from_system(),
		"unread_count": maxi(1, _unread_warning_count)
	}

	if not visible:
		var bus = get_node_or_null("/root/EventBus")
		if bus != null and bus.has_signal("tablet_warning_received"):
			bus.tablet_warning_received.emit(_active_warning_data)

	_sync_tablet_invariant_size()
