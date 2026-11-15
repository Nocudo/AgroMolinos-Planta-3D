class_name HUDController
extends Control

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

func _ready() -> void:
	# Asegurar que todos los elementos visuales del HUD ignoren clics de mouse
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_mouse_filter_recursive(self)

	if toast_panel != null:
		toast_panel.visible = false
	if prompt_label != null:
		prompt_label.text = ""
		prompt_label.visible = false

	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.tool_changed.connect(_on_tool_changed)
		bus.telemetry_updated.connect(_on_telemetry_updated)
		bus.notification_posted.connect(_on_notification_posted)
		if bus.has_signal("prompt_updated"):
			bus.prompt_updated.connect(_on_prompt_updated)

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

func _on_prompt_updated(txt: String) -> void:
	if prompt_label != null:
		prompt_label.text = txt
		prompt_label.visible = (txt != "")

func _on_tool_changed(_tool_id: int, tool_name: String) -> void:
	if lbl_active_tool != null:
		lbl_active_tool.text = tool_name

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
