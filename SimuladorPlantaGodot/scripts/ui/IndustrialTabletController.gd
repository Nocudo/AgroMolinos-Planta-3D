class_name IndustrialTabletController
extends Control

# ==============================================================================
# CONTROLADOR DE LA TABLET INDUSTRIAL DE CAMPO (GEMELO DIGITAL HMI)
# ==============================================================================

@onready var pnl_banner: PanelContainer = $Frame/VBox/BannerPanel
@onready var lbl_alert_title: Label = $Frame/VBox/BannerPanel/HBox/Title
@onready var lbl_confidence: Label = $Frame/VBox/BannerPanel/HBox/Confidence
@onready var lbl_root_cause: Label = $Frame/VBox/Details/ValRootCause
@onready var lbl_prognosis: Label = $Frame/VBox/Details/ValPrognosis
@onready var lbl_prescription: Label = $Frame/VBox/Details/ValPrescription
@onready var mhi_progress_bar: ProgressBar = $Frame/VBox/MhiBox/ProgressBar
@onready var lbl_mhi_value: Label = $Frame/VBox/MhiBox/HBox/MhiValue
@onready var checklist_container: VBoxContainer = $Frame/VBox/ChecklistScroll/ChecklistVBox
@onready var audio_alert: AudioStreamPlayer = $AudioAlert
@onready var btn_close: Button = $Frame/VBox/Header/BtnClose

func _ready() -> void:
	visible = false
	if btn_close != null:
		btn_close.pressed.connect(_close_tablet)
	
	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.ai_alert_received.connect(_on_ai_alert_received)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_tablet"):
		toggle_tablet()
		get_viewport().set_input_as_handled()

func toggle_tablet() -> void:
	visible = not visible
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _close_tablet() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_ai_alert_received(alert_data: Dictionary) -> void:
	if alert_data.is_empty(): return

	var severity = alert_data.get("severity", "NORMAL")
	if severity == "CRITICAL" or severity == "WARNING":
		if audio_alert != null and not audio_alert.playing:
			audio_alert.play()

	if lbl_alert_title != null:
		lbl_alert_title.text = alert_data.get("title", "SISTEMA OPERATIVO CONFORME")
	
	if lbl_confidence != null:
		var conf = alert_data.get("confidence", 95.0)
		lbl_confidence.text = "Certeza IA: %.1f %%" % conf

	if lbl_root_cause != null:
		lbl_root_cause.text = alert_data.get("root_cause", "Operación nominal balanceada.")
	
	if lbl_prognosis != null:
		lbl_prognosis.text = alert_data.get("prognosis", "Condición estable.")
	
	if lbl_prescription != null:
		lbl_prescription.text = alert_data.get("prescription", "Inspección de rutina.")

	var mhi = alert_data.get("mhi", 95.0)
	if mhi_progress_bar != null:
		mhi_progress_bar.value = mhi
	if lbl_mhi_value != null:
		lbl_mhi_value.text = "%.1f %%" % mhi

	# Color del Banner
	if pnl_banner != null:
		if severity == "CRITICAL":
			pnl_banner.self_modulate = Color(1.0, 0.2, 0.2, 1.0)
		elif severity == "WARNING":
			pnl_banner.self_modulate = Color(1.0, 0.65, 0.1, 1.0)
		else:
			pnl_banner.self_modulate = Color(0.1, 0.8, 0.4, 1.0)

	# Actualizar Checklist RCM
	if checklist_container != null:
		for c in checklist_container.get_children():
			c.queue_free()
		
		var steps = alert_data.get("maintenance_steps", [])
		for step in steps:
			var cb = CheckBox.new()
			cb.text = step
			cb.custom_minimum_size.y = 28
			checklist_container.add_child(cb)
