extends Node

# ==============================================================================
# EVENT BUS - AGROMOLINOS DEL VALLE S.A.
# Desacoplamiento de eventos físicos, electromecánicos, UI y Nube IoT en Godot 4.7
# ==============================================================================

# Telemetría continua del gemelo digital electromecánico
signal telemetry_updated(
	rpm: float,
	cur_a: float,
	cur_b: float,
	cur_c: float,
	volt: float,
	freq: float,
	temp: float,
	vib: float,
	p_kw: float,
	pf: float,
	flow: float
)

# Inducción y despeje de fallas físicas
signal fault_injected(fault_type: String, active: bool)
signal conductor_cut_event(phase_id: String)
signal conductor_repaired_event(phase_id: String)
signal hopper_overfed(kg_s: float)
signal breaker_changed(breaker_id: String, active: bool)
signal bolt_loosened(bolt_id: String, loosened: bool)
signal ventilation_blocked(blocked: bool)

# Seguridad industrial y parada
signal emergency_stop_triggered(source: String)
signal emergency_stop_reset()
signal loto_applied(applied: bool)

# Notificaciones y Tablet
signal ai_alert_received(alert_data: Dictionary)
signal notification_posted(title: String, message: String, severity: String)
signal tool_changed(tool_id: int, tool_name: String)
signal prompt_updated(prompt_text: String)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
