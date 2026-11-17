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

# Nuevas señales de integración integral (Bloques 1-8)
signal telemetry_vector_updated(telemetry_dict: Dictionary)
signal drive_mode_changed(mode_name: String, auto_pid: bool)
signal epp_state_changed(all_equipped: bool, items: Dictionary)
signal golden_rule_step_completed(step_index: int, rule_name: String)
signal golden_rules_completed()
signal tutorial_station_reached(station_index: int, station_title: String)
signal tutorial_completed()
signal plant_production_started()
signal safety_zone_entered(zone_id: String, zone_name: String)
signal safety_zone_exited(zone_id: String)
signal safety_line_crossed(active: bool, zone_id: String, title: String, message: String)
signal safety_violation_committed(code: String, description: String, penalty: float)
signal safety_bonus_awarded(code: String, description: String, bonus: float)
signal safety_score_updated(current_score: float, history: Array)
signal fault_resolved(fault_code: String)
signal production_metrics_updated(metrics: Dictionary)
signal cctv_camera_changed(cam_id: String, cam_name: String)
signal induction_briefing_requested(title: String, greeting: String, resume_tour_on_close: bool)
signal induction_briefing_closed(resume_tour_on_close: bool)
signal sst_course_mode_selected(start_course: bool)
signal sst_course_modal_requested()
signal sst_course_completed_event(passed: bool, score: int, total: int)
signal tablet_warning_received(warning_data: Dictionary)
signal tablet_notifications_cleared()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
