extends SceneTree

# ==============================================================================
# SUITE MAESTRA DE VERIFICACIÓN HEADLESS (10 CHECKPOINTS QA) - AGROMOLINOS DEL VALLE S.A.
# Valida los Bloques 1..8 de la Skill industrial-plant-simulation en Godot 4.7.2
# ==============================================================================

const InductionMotorKlossScript = preload("res://scripts/physics/InductionMotorKloss.gd")
const VFDDriveControllerScript = preload("res://scripts/physics/VFDDriveController.gd")
const EdgeAIEngineScript = preload("res://scripts/ai/EdgeAIEngine.gd")
const TutorialInductionManagerScript = preload("res://scripts/tutorial/TutorialInductionManager.gd")
const MezzanineCCTVControllerScript = preload("res://scripts/environment/MezzanineCCTVController.gd")
const SafetyEvaluationScorecardScript = preload("res://scripts/tutorial/SafetyEvaluationScorecard.gd")
const IndustrialSoundSynthesizerScript = preload("res://scripts/core/IndustrialSoundSynthesizer.gd")
const InteractiveDoorScript = preload("res://scripts/interactive/InteractiveDoor.gd")

var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run_all_checks")

func _assert_true(cond: bool, msg: String) -> bool:
	if not cond:
		push_error("[ASSERT FAIL] " + msg)
		return false
	return true

func _report_qa(idx: int, title: String, ok: bool, detail: String = "") -> void:
	if ok:
		passed += 1
		print("[QA %d/10 PASS] %s %s" % [idx, title, ("— " + detail) if not detail.is_empty() else ""])
	else:
		failed += 1
		printerr("[QA %d/10 FAIL] %s %s" % [idx, title, ("— " + detail) if not detail.is_empty() else ""])

func _step_motor(motor: Node, steps: int, dt: float = 0.02) -> void:
	for _i in range(steps):
		motor._physics_process(dt)

func _run_all_checks() -> void:
	print("=== INICIANDO VERIFICACIÓN QA HEADLESS (10 CHECKPOINTS) - AGROMOLINOS ===")
	_qa_1_scenes_and_eventbus()
	_qa_2_kloss_and_vfd()
	_qa_3_tutorial_epp_loto_stations()
	_qa_4_animated_production_logistics()
	_qa_5_five_diegetic_faults_and_repairs()
	_qa_6_native_edge_ai()
	_qa_7_in_game_tablet_and_oscilloscopes()
	_qa_8_cctv_and_safety_scorecard()
	_qa_9_strict_3d_asset_audit()
	await _qa_10_main_scene_integration()

	print("=== RESULTADO QA HEADLESS: %d PASARON | %d FALLARON ===" % [passed, failed])
	if passed == 10 and failed == 0:
		quit(0)
	else:
		quit(1)

func _qa_1_scenes_and_eventbus() -> void:
	var scene_paths: Array[String] = [
		"res://scenes/main.tscn",
		"res://scenes/environment/SafetyZonesAndLighting.tscn",
		"res://scenes/production/ProductionChainFlow.tscn",
		"res://scenes/infrastructure/FactoryEntranceAndLockers.tscn",
		"res://scenes/player/PlayerOperator.tscn",
		"res://scenes/equipment/MotorMillUnit.tscn",
		"res://scenes/equipment/PhysicalBreakerPanel.tscn",
		"res://scenes/equipment/PhysicalCableConductor.tscn",
		"res://scenes/equipment/PhysicalHopperFeeder.tscn",
		"res://scenes/equipment/InteractiveGrainBag.tscn",
		"res://scenes/ui/HUD.tscn",
		"res://scenes/ui/IndustrialTablet.tscn",
		"res://scenes/workers/WorkerElectrician.tscn",
		"res://scenes/workers/WorkerLogistics.tscn",
		"res://scenes/workers/WorkerPlantManager.tscn",
		"res://scenes/workers/WorkerSafetyAuditor.tscn"
	]
	var ok := true
	for sp in scene_paths:
		var res := ResourceLoader.load(sp)
		if not _assert_true(res is PackedScene, "Escena no cargó como PackedScene: " + sp):
			ok = false

	var bus := root.get_node_or_null("EventBus")
	ok = _assert_true(bus != null, "Autoload EventBus ausente") and ok
	if bus != null:
		var req_signals: Array[String] = [
			"telemetry_updated", "telemetry_vector_updated", "drive_mode_changed",
			"epp_state_changed", "golden_rule_step_completed", "golden_rules_completed",
			"tutorial_station_reached", "safety_zone_entered", "safety_zone_exited",
			"safety_violation_committed", "safety_bonus_awarded", "safety_score_updated",
			"fault_resolved", "production_metrics_updated", "cctv_camera_changed", "ai_alert_received"
		]
		for sig in req_signals:
			if not _assert_true(bus.has_signal(sig), "Falta señal en EventBus: " + sig):
				ok = false

	_report_qa(1, "Carga de 16 escenas .tscn y EventBus (16 señales)", ok)

func _qa_2_kloss_and_vfd() -> void:
	var motor = InductionMotorKlossScript.new()
	root.add_child(motor)
	motor.set_drive_mode("DOL")
	motor.mass_flow_kg_s = 0.8
	motor.start_motor()
	_step_motor(motor, 200, 0.02)

	var ok := true
	var rpm_60hz: float = motor.rotor_speed_rpm
	var p_60hz: float = motor.active_power_kw
	ok = _assert_true(rpm_60hz >= 1740.0 and rpm_60hz <= 1780.0,
		"RPM nominal fuera de [1740,1780]: %.2f" % rpm_60hz) and ok
	ok = _assert_true(motor.current_l1 >= 11.5 and motor.current_l1 <= 15.5,
		"Ia nominal fuera de [11.5,15.5]: %.2f" % motor.current_l1) and ok
	ok = _assert_true(is_equal_approx(motor.breakdown_torque_nm, 101.75),
		"Par máximo Kloss esperado ~101.75: %.2f" % motor.breakdown_torque_nm) and ok
	ok = _assert_true(is_equal_approx(motor.locked_rotor_current_lra, 81.0),
		"LRA esperado 81.0 A: %.2f" % motor.locked_rotor_current_lra) and ok

	motor.vfd_controller.set_auto_pid(false)
	motor.set_drive_mode("VFD")
	motor.set_vfd_target_frequency(42.0)
	motor.current_frequency = 42.0
	_step_motor(motor, 150, 0.02)
	var p_42hz: float = motor.active_power_kw
	ok = _assert_true(p_42hz < p_60hz * 0.65,
		"Ley afinidad cúbica a 42 Hz no redujo potencia (60Hz=%.2f kW, 42Hz=%.2f kW)" % [p_60hz, p_42hz]) and ok

	var vfd = VFDDriveControllerScript.new()
	var kpis: Dictionary = vfd.get_energy_kpi_dict()
	ok = _assert_true(is_equal_approx(float(kpis["vfd_baseline_kwh_ton"]), 7.52), "VFD específico debe ser 7.52 kWh/ton") and ok
	ok = _assert_true(is_equal_approx(float(kpis["dol_baseline_kwh_ton"]), 10.50), "DOL específico debe ser 10.50 kWh/ton") and ok
	ok = _assert_true(float(kpis["savings_pct"]) > 28.0, "Ahorro VFD vs DOL debe superar 28%%") and ok
	ok = _assert_true(is_equal_approx(float(kpis["upme_co2_factor"]), 0.164), "Factor UPME debe ser 0.164 kg CO2e/kWh") and ok

	var detail := "60Hz: %.1f RPM / %.2f kW -> 42Hz VFD: %.2f kW | VFD 7.52 vs DOL 10.50 kWh/t (%.1f%% ahorro)" % [
		rpm_60hz, p_60hz, p_42hz, float(kpis["savings_pct"])
	]
	vfd.free()
	motor.free()
	_report_qa(2, "Gemelo Kloss 10HP + VFD vs DOL y Ley Cúbica", ok, detail)

func _qa_3_tutorial_epp_loto_stations() -> void:
	var entrance_scene := ResourceLoader.load("res://scenes/infrastructure/FactoryEntranceAndLockers.tscn") as PackedScene
	var entrance := entrance_scene.instantiate()
	var tut = TutorialInductionManagerScript.new()
	root.add_child(tut)
	root.add_child(entrance)
	var locker := entrance.find_child("LockerEPPStation", true, false)

	var ok := true
	ok = _assert_true(tut.can_advance_past_lockers() == false, "Recorrido no debe permitir avanzar más allá de Vestidores sin EPP") and ok
	var blocked_st: Dictionary = tut.visit_station(3)
	ok = _assert_true(blocked_st.is_empty(), "visit_station(3) debe bloquearse antes de vestir EPP") and ok

	ok = _assert_true(locker != null, "No se encontró LockerEPPStation en FactoryEntranceAndLockers") and ok
	if locker != null:
		ok = _assert_true(locker.is_access_allowed() == false, "Esclusa debe iniciar bloqueada sin EPP") and ok
		locker.set_epp_equipped(true)
		ok = _assert_true(locker.is_access_allowed() == true, "Esclusa debe desbloquearse con 6/6 EPP") and ok
	ok = _assert_true(tut.can_advance_past_lockers() == true, "Tras equipar ropa EPP debe habilitarse el avance") and ok

	var guide_line := tut.find_child("TourFloorGuideLine", true, false) as MeshInstance3D
	ok = _assert_true(guide_line != null and guide_line.mesh is ImmediateMesh and guide_line.mesh.get_surface_count() > 0,
		"TourFloorGuideLine debe existir con ImmediateMesh en el suelo") and ok

	# Intentar Regla 2 antes que Regla 1 debe fallar
	var bad_step: Dictionary = tut.execute_loto_rule(2)
	ok = _assert_true(bool(bad_step.get("ok", true)) == false, "LOTO no debe permitir Regla 2 antes de Regla 1") and ok

	for r in range(1, 6):
		var res_r: Dictionary = tut.execute_loto_rule(r)
		if not _assert_true(bool(res_r.get("ok", false)), "Fallo en Regla LOTO %d" % r):
			ok = false
	ok = _assert_true(tut.is_loto_complete(), "LOTO debe quedar completo tras Reglas 1..5") and ok

	for sid in range(1, tut.STATIONS.size() + 1):
		tut.visit_station(sid)
	ok = _assert_true(is_equal_approx(tut.get_progress_pct(), 100.0) and tut.induction_certified,
		"Tutorial debe certificar %d/%d estaciones (%.1f%%, epp=%s, loto=%s)" % [tut.STATIONS.size(), tut.STATIONS.size(), tut.get_progress_pct(), str(tut.epp_completed), str(tut.is_loto_complete())]) and ok

	tut.free()
	entrance.free()
	_report_qa(3, "Tutorial RETIE: Portería, Guía, Ropa EPP (6/6), LOTO 5 Reglas, Guía Suelo y %d Estaciones" % TutorialInductionManagerScript.STATIONS.size(), ok)

func _qa_4_animated_production_logistics() -> void:
	var prod_scene := ResourceLoader.load("res://scenes/production/ProductionChainFlow.tscn") as PackedScene
	var prod := prod_scene.instantiate()
	root.add_child(prod)

	prod.set_motor_rpm(1750.0, 2.5)
	prod.step_production(0.5)
	var auger_angle_1: float = float(prod._auger_angle)
	prod.step_production(59.5)
	var m_run: Dictionary = prod.get_production_metrics()

	var ok := true
	ok = _assert_true(bool(m_run.get("is_production_active", false)) == true, "Producción debe estar activa con 1750 RPM") and ok
	ok = _assert_true(auger_angle_1 > 0.0, "Sinfín Helicoidal debe avanzar rotación en eje X longitudinal") and ok
	ok = _assert_true(float(m_run.get("total_grain_milled_kg", 0.0)) > 100.0, "Masa molida esperada > 100 kg") and ok
	ok = _assert_true(int(m_run.get("bags_50kg_produced", 0)) >= 2, "Debe producir al menos 2 sacos de 50 kg") and ok
	ok = _assert_true(not str(m_run.get("truck_cycle_phase", "")).is_empty(), "Fase logística de camión vacía") and ok

	prod.set_motor_rpm(0.0, 0.0)
	prod.step_production(1.0)
	var m_stop: Dictionary = prod.get_production_metrics()
	ok = _assert_true(bool(m_stop.get("is_production_active", true)) == false, "Producción debe detenerse con 0 RPM") and ok

	var detail := "%.1f kg molidos | %d sacos 50kg | fase camión: %s" % [
		float(m_run.get("total_grain_milled_kg", 0.0)), int(m_run.get("bags_50kg_produced", 0)), str(m_run.get("truck_cycle_phase", ""))
	]
	prod.free()
	_report_qa(4, "Cadena de Producción Animada (Sinfín Eje X y Logística Camiones)", ok, detail)

func _qa_5_five_diegetic_faults_and_repairs() -> void:
	var mill_scene := ResourceLoader.load("res://scenes/equipment/MotorMillUnit.tscn") as PackedScene
	var breaker_scene := ResourceLoader.load("res://scenes/equipment/PhysicalBreakerPanel.tscn") as PackedScene
	var mill := mill_scene.instantiate()
	var breaker := breaker_scene.instantiate()
	root.add_child(mill)
	root.add_child(breaker)

	var motor := mill.get_node("InductionMotor")
	var cable := mill.get_node("PhysicalCableConductor")
	var hopper := mill.get_node("PhysicalHopperFeeder")
	var vent := mill.get_node("VentilationCover")
	var bolt := mill.get_node("MechanicalBolt")

	motor.set_drive_mode("DOL")
	motor.start_motor()
	_step_motor(motor, 150, 0.02)

	var ok := true

	# 1. Corte L3 y empalme físico
	cable.cut_cable()
	_step_motor(motor, 25, 0.02)
	ok = _assert_true(is_equal_approx(motor.current_l3, 0.0) and motor.iuf_pct > 25.0,
		"Corte L3 no dejó Ic=0 / IUF>25%% (Ic=%.2f, IUF=%.1f%%)" % [motor.current_l3, motor.iuf_pct]) and ok
	cable.repair_cable()
	_step_motor(motor, 25, 0.02)
	ok = _assert_true(motor.current_l3 > 10.0 and motor.iuf_pct < 5.0,
		"Reparación L3 no restableció fase (Ic=%.2f, IUF=%.1f%%)" % [motor.current_l3, motor.iuf_pct]) and ok

	# 2. Sobrealimentación Tolva (2 bultos -> atasco) y desatasco
	hopper.throw_bag_into_hopper()
	hopper.throw_bag_into_hopper()
	_step_motor(motor, 120, 0.02)
	ok = _assert_true(motor.mass_flow_kg_s >= 3.0 and motor.rotor_speed_rpm < 50.0 and motor.current_l1 > 70.0,
		"Atasco tolva no frenó rotor (RPM=%.1f, Ia=%.1f)" % [motor.rotor_speed_rpm, motor.current_l1]) and ok
	hopper.clear_jam()
	_step_motor(motor, 200, 0.02)
	ok = _assert_true(motor.mass_flow_kg_s <= 1.0 and motor.rotor_speed_rpm > 1700.0,
		"Desatasco tolva no recuperó velocidad nominal (RPM=%.1f)" % motor.rotor_speed_rpm) and ok

	# 3. Breaker CCM 340 V sag y rearme 460 V
	breaker.toggle_breaker_l3()
	_step_motor(motor, 10, 0.02)
	ok = _assert_true(is_equal_approx(motor.current_voltage, 340.0), "Breaker abierto debe bajar tensión a 340 V (%.1f V)" % motor.current_voltage) and ok
	breaker.toggle_breaker_l3()
	_step_motor(motor, 10, 0.02)
	ok = _assert_true(is_equal_approx(motor.current_voltage, 460.0), "Breaker rearmado debe restaurar 460 V (%.1f V)" % motor.current_voltage) and ok

	# 4. Obstrucción ventilación trasera (Rth 0.068 -> 0.210) y despeje
	motor.winding_temp_c = 85.0
	_step_motor(motor, 5, 0.02)
	var dtemp_clean: float = motor.d_temp_dt_min
	vent.set_blocked(true)
	_step_motor(motor, 5, 0.02)
	var dtemp_blocked: float = motor.d_temp_dt_min
	ok = _assert_true(motor.is_cooling_blocked and dtemp_blocked > dtemp_clean,
		"Obstrucción ventilación debe incrementar tasa térmica dT/dt (clean=%.3f, blocked=%.3f)" % [dtemp_clean, dtemp_blocked]) and ok
	vent.set_blocked(false)
	_step_motor(motor, 5, 0.02)
	ok = _assert_true(not motor.is_cooling_blocked and motor.d_temp_dt_min < dtemp_blocked,
		"Retiro obstrucción debe normalizar disipación térmica") and ok

	# 5. Pernos de bancada flojos y apriete mecánico
	bolt.set_loosened(true)
	_step_motor(motor, 10, 0.02)
	ok = _assert_true(motor.vibration_rms_mm_s > 3.5, "Perno flojo debe disparar vibración > 3.5 mm/s (%.2f)" % motor.vibration_rms_mm_s) and ok
	bolt.set_loosened(false)
	_step_motor(motor, 10, 0.02)
	ok = _assert_true(motor.vibration_rms_mm_s < 1.8, "Apriete perno debe retornar a Zona A/B < 1.8 mm/s (%.2f)" % motor.vibration_rms_mm_s) and ok

	breaker.free()
	mill.free()
	_report_qa(5, "5 Fallas Diegéticas Físicas y Reparación en Campo", ok)

func _qa_6_native_edge_ai() -> void:
	var ai = EdgeAIEngineScript.new()

	var res_norm: Dictionary = ai.evaluate_telemetry_vector([13.5, 0.8, 2.2, 460.0, 74.0, 0.1, 1.1, 1.6])
	var res_heat: Dictionary = ai.evaluate_telemetry_vector([18.5, 1.5, 2.8, 460.0, 118.0, 3.2, 1.4, 2.0])
	var res_elec: Dictionary = ai.evaluate_telemetry_vector([16.2, 88.0, 9.2, 458.0, 76.0, 0.35, 4.75, 8.5])
	var res_mech: Dictionary = ai.evaluate_telemetry_vector([13.8, 1.0, 2.4, 460.0, 78.0, 0.2, 5.65, 14.1])

	var ok := true
	ok = _assert_true(res_norm.get("predicted_class", "") == "NORMAL" and float(res_norm.get("mhi", 0.0)) > 90.0,
		"Caso NORMAL mal clasificado: %s (MHI=%.1f)" % [str(res_norm.get("predicted_class", "")), float(res_norm.get("mhi", 0.0))]) and ok
	ok = _assert_true(res_heat.get("predicted_class", "") == "SOBRECALENTAMIENTO",
		"Caso SOBRECALENTAMIENTO mal clasificado: " + str(res_heat.get("predicted_class", ""))) and ok
	ok = _assert_true(res_elec.get("predicted_class", "") == "FALLA_ELECTRICA" and float(res_elec.get("mlp_confidence", 0.0)) > 95.0,
		"Caso FALLA_ELECTRICA mal clasificado o certeza <95%%: %s (%.1f%%)" % [str(res_elec.get("predicted_class", "")), float(res_elec.get("mlp_confidence", 0.0))]) and ok
	ok = _assert_true(res_mech.get("predicted_class", "") == "FALLA_MECANICA",
		"Caso FALLA_MECANICA mal clasificado: " + str(res_mech.get("predicted_class", ""))) and ok
	ok = _assert_true((res_elec.get("maintenance_steps", []) as Array).size() >= 3,
		"Payload RCM debe incluir checklist de mantenimiento") and ok

	var detail := "NORMAL(MHI=%.1f%%) | ELEC(%.1f%% MLP) | MECH(%.1f%%)" % [
		float(res_norm.get("mhi", 0.0)), float(res_elec.get("mlp_confidence", 0.0)), float(res_mech.get("mlp_confidence", 0.0))
	]
	ai.free()
	_report_qa(6, "Edge AI Nativo GDScript (MLP + SVM RBF + MHI + RUL + RCM)", ok, detail)

func _qa_7_in_game_tablet_and_oscilloscopes() -> void:
	var tab_scene := ResourceLoader.load("res://scenes/ui/IndustrialTablet.tscn") as PackedScene
	var tablet_layer := tab_scene.instantiate()
	root.add_child(tablet_layer)
	var tablet := tablet_layer.get_node("TabletRoot")

	var ok := true
	ok = _assert_true(tablet != null and tablet.visible == false, "TabletRoot debe iniciar oculto") and ok
	if tablet != null:
		tablet.toggle_tablet()
		ok = _assert_true(tablet.visible == true, "toggle_tablet() debe mostrar tablet") and ok

		tablet._on_telemetry_vector_updated({
			"rpm": 1743.8, "current_a": 13.5, "current_b": 13.5, "current_c": 13.6,
			"voltage": 460.0, "freq_hz": 60.0, "power_factor": 0.85, "iuf_pct": 0.7,
			"thd_pct": 2.4, "torque_nm": 41.0, "power_kw": 8.78, "temp_c": 75.0,
			"d_temp_dt_min": 0.1, "vibration_rms": 1.1, "is_phase_l3_cut": false, "is_bolts_loosened": false,
			"energy": {"drive_mode": "VFD", "specific_kwh_ton": 7.52, "dol_baseline_kwh_ton": 10.50, "savings_pct": 28.4, "co2_avoided_kg": 1.2, "projected_annual_co2_kg": 488.7}
		})
		tablet._on_ai_alert_received({
			"severity": "NORMAL", "title": "SISTEMA OPERATIVO CONFORME",
			"mlp_confidence": 99.6, "svm_confidence": 99.1, "mhi": 98.4, "rul_hours": 24000.0,
			"root_cause": "Motor balanced", "prognosis": "Nominal", "prescription": "Rutina",
			"maintenance_steps": ["Paso 1", "Paso 2"]
		})

		ok = _assert_true(tablet.chart_currents != null and tablet.chart_currents.buf_a.size() > 0, "ChartCurrents sin muestras") and ok
		ok = _assert_true(tablet.chart_temperature != null and tablet.chart_temperature.buf_a.size() > 0, "ChartTemperature sin muestras") and ok
		ok = _assert_true(tablet.chart_vibration != null and tablet.chart_vibration.buf_a.size() > 0, "ChartVibration sin muestras") and ok

		var chassis := tablet.get_node_or_null("TabletChassis") as Control
		var frame := tablet.get_node_or_null("Frame") as PanelContainer
		ok = _assert_true(chassis != null and frame != null, "Falta TabletChassis o Frame") and ok
		if chassis != null and frame != null:
			var shell_node := chassis.get_node_or_null("CleanOuterShell") as Panel
			ok = _assert_true(shell_node != null, "Carcasa limpia de tablet (CleanOuterShell) no generada") and ok
			ok = _assert_true(chassis.get_node_or_null("DecorativeHardwareUI") == null, "No deben existir botones ficticios decorativos en TabletChassis") and ok
			ok = _assert_true(tablet.find_child("BtnClose", true, false) == null and tablet.btn_close == null, "No debe existir botón 'Salir' (BtnClose) en la tablet") and ok
			var sz_ch_before := chassis.size
			var sz_fr_before := frame.size
			tablet._on_telemetry_vector_updated({
				"rpm": 1492.4, "current_a": 48.2, "current_b": 49.1, "current_c": 0.0,
				"voltage": 452.0, "freq_hz": 60.0, "power_factor": 0.62, "iuf_pct": 98.4,
				"thd_pct": 14.8, "torque_nm": 92.5, "power_kw": 12.9, "temp_c": 134.8,
				"d_temp_dt_min": 8.4, "vibration_rms": 11.2, "is_phase_l3_cut": true, "is_bolts_loosened": true,
				"energy": {"drive_mode": "DOL", "specific_kwh_ton": 10.50, "dol_baseline_kwh_ton": 10.50, "savings_pct": 0.0, "co2_avoided_kg": 124.5678, "projected_annual_co2_kg": 0.0}
			})
			tablet._on_ai_alert_received({
				"severity": "CRITICAL",
				"title": "FALLA CRÍTICA MULTIFACTORIAL CON CADENA EXTREMADAMENTE LARGA PARA VALIDAR INMUTABILIDAD DE TAMAÑO",
				"mlp_confidence": 99.8, "svm_confidence": 99.4, "mhi": 18.2, "rul_hours": 12.0,
				"root_cause": "Apertura franca L3 con desbalance severo y sobrecarga prolongada de molino 10HP con texto largo.",
				"prognosis": "Riesgo inminente de falla de aislamiento bajo arranque directo DOL si no se interviene.",
				"prescription": "Accionar E-STOP de inmediato, ejecutar procedimiento LOTO siguiendo 5 Reglas de Oro RETIE.",
				"maintenance_steps": ["1. Desenergizar CCM", "2. Aplicar candado LOTO", "3. Verificar ausencia tensión", "4. Puesta a tierra", "5. Señalizar", "6. Reajustar pernos"]
			})
			var min_fr := frame.get_combined_minimum_size()
			ok = _assert_true(min_fr.x <= 1180.0 and min_fr.y <= 700.0, "Frame minimum size excede 1180x700 tras alerta larga: " + str(min_fr)) and ok
			ok = _assert_true(chassis.size == sz_ch_before and chassis.size == Vector2(1228, 748), "Tamaño de TabletChassis cambió: " + str(chassis.size)) and ok
			ok = _assert_true(frame.size == sz_fr_before and frame.size == Vector2(1180, 700), "Tamaño de Frame cambió: " + str(frame.size)) and ok

			# Validar las 9 pestañas rectificadas (incluyendo pestaña 8 "Historial" de todas las notificaciones)
			ok = _assert_true(tablet._tab_pages.size() == 9 and tablet.TAB_NAMES[1] == "Cámaras" and tablet.TAB_NAMES[8] == "Historial" and not tablet.TAB_NAMES.has("Cámaras CCTV"),
				"Tablet debe tener 9 pestañas incluyendo 'Cámaras' e 'Historial' sin sección separada de Cámaras CCTV (%s)" % str(tablet.TAB_NAMES)) and ok
			ok = _assert_true(tablet._machine_tiles.size() == 16 and tablet._cards_3d_workers.size() == 4,
				"Telemetría IoT debe enlazar 15 máquinas + CCM (%d) y 4 operarios 3D (%d)" % [tablet._machine_tiles.size(), tablet._cards_3d_workers.size()]) and ok
			for tab_i in range(9):
				tablet._select_tab(tab_i)
				ok = _assert_true(chassis.size == Vector2(1228, 748) and frame.size == Vector2(1180, 700), "Cambio de tamaño en pestaña %d" % tab_i) and ok
			tablet._select_tab(7)
			var rub_root := tablet._cctv_handles.get("root", null) as Node
			ok = _assert_true(rub_root != null and rub_root.name == "TabRubricaAcademica",
				"Pestaña 7 debe ser TabRubricaAcademica sin panel CCTV duplicado") and ok
			# Validar pestaña 8: Historial de todas las notificaciones (info, éxito, alerta, crítica + filtros + limpiar)
			tablet._select_tab(8)
			tablet._on_clear_notif_history()
			tablet._on_bus_notification_posted("EPP equipado", "Protección completa.", "info")
			tablet._on_bus_notification_posted("Curso aprobado", "Quiz RETIE 5/5.", "success")
			tablet._on_bus_notification_posted("Detén las máquinas primero", "Pulsa Parar Máquinas.", "warning")
			tablet._on_bus_notification_posted("Falla en ciclón", "Presión anormal.", "error")
			var h_list := tablet._notif_hist_handles.get("list_vb", null) as VBoxContainer
			var h_all_cnt := h_list.get_child_count() if h_list != null else 0
			tablet._on_notif_history_filter_selected("CRITICAL")
			var h_crit_cnt := h_list.get_child_count() if h_list != null else 0
			tablet._on_notif_history_filter_selected("ALL")
			ok = _assert_true(
				tablet.get_notification_history_count() == 4 and h_all_cnt == 4 and h_crit_cnt == 1,
				"Pestaña Historial debe registrar todas las notificaciones y filtrar por severidad (total=%d, all=%d, crit=%d)" % [tablet.get_notification_history_count(), h_all_cnt, h_crit_cnt]
			) and ok
			tablet._select_tab(1)
			var total_cam_cards := 0
			for grp in tablet.TCatalog.CAMERA_GROUPS_ORDER:
				tablet._select_3d_group(grp)
				total_cam_cards += (tablet._cards_by_3d_group.get(grp, []) as Array).size()
				ok = _assert_true(chassis.size == Vector2(1228, 748) and frame.size == Vector2(1180, 700), "Tamaño invariante en grupo Cámaras 3D %s" % grp) and ok
			ok = _assert_true(total_cam_cards == 24, "Pestaña Cámaras debe incluir 20 cámaras de planta (15 máquinas + CCM + vistas) + 4 operarios (%d)" % total_cam_cards) and ok
			tablet._select_tab(3)
			tablet._on_register_worker("Carlos", "Ruiz", "28", "Grupo RH: O+", "Operario de Planta")
			ok = _assert_true(tablet._custom_workers.size() == 1, "Registro manual de operario debe agregarse al turno") and ok
			tablet._select_tab(0)

		tablet.toggle_tablet()
		ok = _assert_true(tablet.visible == false, "Segundo toggle_tablet() debe ocultar tablet") and ok
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	tablet_layer.free()
	_report_qa(7, "Tablet Industrial [TAB] In-Game y 3 Oscilogramas Nativos", ok)

func _qa_8_cctv_and_safety_scorecard() -> void:
	var cctv = MezzanineCCTVControllerScript.new()
	root.add_child(cctv)
	var cams: Array[Dictionary] = cctv.get_cameras_info()
	cctv.select_camera("CAM_02_CCM460V")

	var ok := true
	ok = _assert_true(cams.size() == 4, "CCTV debe tener 4 cámaras (tiene %d)" % cams.size()) and ok
	ok = _assert_true(cctv.get_active_camera_id() == "CAM_02_CCM460V", "CCTV no cambió a CAM_02_CCM460V") and ok

	var scorecard = SafetyEvaluationScorecardScript.new()
	root.add_child(scorecard)
	ok = _assert_true(is_equal_approx(scorecard.score, 5.0), "Score inicial debe ser 5.0") and ok
	scorecard.record_violation("CORTE_SIN_LOTO") # -3.0 -> 2.0
	ok = _assert_true(is_equal_approx(scorecard.score, 2.0), "Score tras CORTE_SIN_LOTO (-3.0) debe ser 2.0: %.2f" % scorecard.score) and ok
	scorecard.record_bonus("LOTO_5_REGLAS") # +1.0 -> 3.0
	ok = _assert_true(is_equal_approx(scorecard.score, 3.0), "Score tras LOTO_5_REGLAS (+1.0) debe ser 3.0: %.2f" % scorecard.score) and ok

	var test_path := "user://qa_test_retie.json"
	var exported := scorecard.export_report_json(test_path)
	ok = _assert_true(exported == test_path and FileAccess.file_exists(test_path), "Fallo exportando JSON RETIE") and ok
	if FileAccess.file_exists(test_path):
		var raw_txt := FileAccess.get_file_as_string(test_path)
		var parsed = JSON.parse_string(raw_txt)
		ok = _assert_true(parsed is Dictionary and is_equal_approx(float(parsed.get("final_score", -1.0)), 3.0), "JSON RETIE inválido") and ok
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))

	cctv.free()
	scorecard.free()
	_report_qa(8, "CCTV Mezzanine (4 Cámaras) y Rúbrica RETIE (0.0-5.0 + JSON)", ok)

func _qa_9_strict_3d_asset_audit() -> void:
	var all_scenes: Array[String] = [
		"res://scenes/main.tscn",
		"res://scenes/environment/SafetyZonesAndLighting.tscn",
		"res://scenes/production/ProductionChainFlow.tscn",
		"res://scenes/infrastructure/FactoryEntranceAndLockers.tscn",
		"res://scenes/player/PlayerOperator.tscn",
		"res://scenes/equipment/MotorMillUnit.tscn",
		"res://scenes/equipment/PhysicalBreakerPanel.tscn",
		"res://scenes/equipment/PhysicalCableConductor.tscn",
		"res://scenes/equipment/PhysicalHopperFeeder.tscn",
		"res://scenes/equipment/InteractiveGrainBag.tscn",
		"res://scenes/ui/HUD.tscn",
		"res://scenes/ui/IndustrialTablet.tscn",
		"res://scenes/workers/WorkerElectrician.tscn",
		"res://scenes/workers/WorkerLogistics.tscn",
		"res://scenes/workers/WorkerPlantManager.tscn",
		"res://scenes/workers/WorkerSafetyAuditor.tscn"
	]
	var banned_meshes: Array[String] = [
		"CSG", "BoxMesh", "CylinderMesh", "CapsuleMesh", "SphereMesh", "TorusMesh", "PrismMesh"
	]

	var ok := true
	for sp in all_scenes:
		var txt := FileAccess.get_file_as_string(sp)
		for banned in banned_meshes:
			if txt.contains(banned):
				ok = _assert_true(false, "%s contiene primitiva 3D residual prohibida: %s" % [sp, banned])

	ok = _assert_true(ResourceLoader.exists("res://assets/models/planta_completa.glb"), "Falta modelo descargado planta_completa.glb") and ok
	ok = _assert_true(ResourceLoader.exists("res://assets/models/trabajador_operario.glb"), "Falta modelo descargado trabajador_operario.glb") and ok

	_report_qa(9, "Auditoría Estricta de Política 3D en las 16 escenas (Cero Primitivas)", ok)

func _qa_10_main_scene_integration() -> void:
	var main_packed := ResourceLoader.load("res://scenes/main.tscn") as PackedScene
	var ok := main_packed != null
	var detail := ""
	if ok:
		var inst := main_packed.instantiate()
		root.add_child(inst)
		var req_nodes: Array[String] = [
			"SafetyZonesAndLighting",
			"ProductionChainFlow",
			"TutorialInductionManager",
			"MezzanineCCTVController",
			"SafetyEvaluationScorecard",
			"MotorMillUnit",
			"PhysicalBreakerPanel",
			"PlayerOperator",
			"HUD",
			"IndustrialTablet"
		]
		for nname in req_nodes:
			var found := inst.find_child(nname, true, false)
			if not _assert_true(found != null, "Nodo faltante en main.tscn: " + nname):
				ok = false

		var spatial := inst.find_child("SafetyZonesAndLighting", true, false)
		if spatial != null:
			var col_count: int = int(spatial.generated_colliders_count)
			ok = _assert_true(col_count >= 150,
				"Colisionadores cúbicos insuficientes en planta: %d (esperado >= 150)" % col_count) and ok
			var plant_root_col := inst.find_child("PlantaCompletaSketchUp", true, false)
			var box_shapes_cnt := 0
			var concave_shapes_cnt := 0
			if plant_root_col != null:
				for cs_n in plant_root_col.find_children("*", "CollisionShape3D", true, false):
					var cs := cs_n as CollisionShape3D
					if cs == null or cs.shape == null:
						continue
					if cs.shape is BoxShape3D:
						box_shapes_cnt += 1
					elif cs.shape is ConcavePolygonShape3D:
						concave_shapes_cnt += 1
			ok = _assert_true(concave_shapes_cnt == 0 and box_shapes_cnt >= 150,
				"Las hitboxes de planta deben ser cubos BoxShape3D sin trimesh complejos (boxes=%d, concave=%d)" % [box_shapes_cnt, concave_shapes_cnt]) and ok
			detail = "BoxColliders=%d (Concave=%d)" % [box_shapes_cnt, concave_shapes_cnt]

		var player := inst.find_child("PlayerOperator", true, false) as Node3D
		if player != null:
			ok = _assert_true(player.position.x > 45.0 and player.position.y >= 0.0 and player.position.y <= 0.5,
				"PlayerOperator debe hacer spawn en Portería exterior: %s" % str(player.position)) and ok
			ok = _assert_true(bool(player._is_head_removed) == true,
				"PlayerOperator debe ocultar/eliminar cabeza en 1ra persona") and ok
			ok = _assert_true(player.find_child("CameraTPS", true, false) == null,
				"Modo 3ra persona CameraTPS debe estar eliminado") and ok
			ok = _assert_true(player.has_method("_try_auto_step") and float(player.max_step_height) >= 0.80,
				"PlayerOperator debe tener auto-step habilitado (>= 0.80 m)") and ok
			var col_shape := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if col_shape != null and col_shape.shape is CapsuleShape3D:
				ok = _assert_true((col_shape.shape as CapsuleShape3D).radius <= 0.35,
					"PlayerOperator cápsula demasiado ancha para puertas interiores: %.2f" % (col_shape.shape as CapsuleShape3D).radius) and ok

		var ground_grass := inst.find_child("Geom3D345", true, false)
		if ground_grass != null:
			var has_ground_col := false
			for ch in ground_grass.get_children():
				if ch is StaticBody3D:
					has_ground_col = true
			ok = _assert_true(not has_ground_col,
				"Geom3D345 (suelo plano) no debe generar trimesh coplanar sobre SueloFisicoPBR") and ok
		ok = _assert_true(inst.find_child("RampLandingNave", true, false) != null,
			"Falta plataforma superior RampLandingNave en acceso sur") and ok

		var guide := inst.find_child("WorkerSafetyAuditor", true, false) as Node3D
		if guide != null:
			ok = _assert_true(guide.position.x > 45.0 and bool(guide.is_tour_guide),
				"WorkerSafetyAuditor debe recibir en Portería como guía (pos=%s, guide=%s)" % [str(guide.position), str(guide.is_tour_guide)]) and ok
			ok = _assert_true(guide.has_method("_try_auto_step"),
				"WorkerSafetyAuditor guía debe tener auto-step habilitado") and ok

		var nave_workers: Array[String] = ["WorkerElectrician", "WorkerLogistics", "WorkerPlantManager"]
		for op_name in nave_workers:
			var op := inst.find_child(op_name, true, false) as Node3D
			if op != null:
				var p: Vector3 = op.position
				var in_nave: bool = (p.x >= -26.0 and p.x <= -12.0) and (p.z >= 25.0 and p.z <= 46.0) and (p.y >= 0.75 and p.y <= 0.90)
				ok = _assert_true(in_nave,
					"%s fuera de Nave Industrial o suelo Y=0.79m: %s" % [op_name, str(p)]) and ok

		var guide_line := inst.find_child("TourFloorGuideLine", true, false)
		ok = _assert_true(guide_line != null, "Falta línea visual de recorrido TourFloorGuideLine") and ok
		var prod_flow := inst.find_child("ProductionChainFlow", true, false)
		ok = _assert_true(prod_flow != null and prod_flow.auger_node != null, "ProductionChainFlow debe enlazar el sinfín Helicoidal") and ok
		if prod_flow != null:
			var m_south := prod_flow.get_node_or_null("TruckIntakeMover")
			var m_west := prod_flow.get_node_or_null("TruckDispatchMover")
			ok = _assert_true(m_south != null and m_west != null, "Ambos camiones animados deben contar con nodos TruckIntakeMover y TruckDispatchMover") and ok
			if m_south != null and m_west != null:
				var d_s := m_south.get_node_or_null("TruckCabDriver")
				var d_w := m_west.get_node_or_null("TruckCabDriver")
				var aud_s := m_south.get_node_or_null("DieselAudio3D") as AudioStreamPlayer3D
				var rev_w := m_west.get_node_or_null("ReverseBeepAudio3D") as AudioStreamPlayer3D
				var sfx_s := m_south.get_node_or_null("BrakeHornAudio3D") as AudioStreamPlayer3D
				ok = _assert_true(d_s != null and d_w != null, "Cabinas de camiones deben tener operarios conductores TruckCabDriver") and ok
				ok = _assert_true(aud_s != null and aud_s.stream != null and rev_w != null and rev_w.stream != null and sfx_s != null and sfx_s.stream != null, "Camiones deben incluir streams 3D diésel, alarma reversa y frenos/bocina") and ok
			var spot_s := inst.find_child("WorkerDockSouth", true, false)
			var spot_w := inst.find_child("WorkerDockWest", true, false)
			ok = _assert_true(spot_s != null and spot_w != null, "Estaciones de camiones deben incluir operarios señaleros en tierra") and ok

		# Auditoría de Audio Industrial (Paso 5)
		ok = _assert_true(IndustrialSoundSynthesizerScript.create_motor_hum_loop().data.size() > 10000,
			"Stream PCM de motor 10 HP demasiado corto o vacío") and ok
		ok = _assert_true(IndustrialSoundSynthesizerScript.create_electric_arc_sound().data.size() > 2000,
			"Stream PCM de arco eléctrico 460V demasiado corto o vacío") and ok
		ok = _assert_true(IndustrialSoundSynthesizerScript.create_footstep_sound().data.size() > 1000,
			"Stream PCM de pasos demasiado corto o vacío") and ok
		ok = _assert_true(IndustrialSoundSynthesizerScript.create_truck_diesel_loop().data.size() > 10000 and IndustrialSoundSynthesizerScript.create_truck_reverse_beep_loop().data.size() > 10000 and IndustrialSoundSynthesizerScript.create_truck_air_brake_sound().data.size() > 4000 and IndustrialSoundSynthesizerScript.create_truck_horn_sound().data.size() > 4000,
			"Streams PCM de camiones (diésel, reversa, frenos y bocina) vacíos o cortos") and ok

		var click_aud := inst.get_node_or_null("PhysicalBreakerPanel/AudioClick") as AudioStreamPlayer3D
		var motor_aud := inst.get_node_or_null("MotorMillUnit/MotorHumAudio3D") as AudioStreamPlayer3D
		var arc_aud := inst.find_child("AudioArc", true, false) as AudioStreamPlayer3D
		var feed_aud := inst.find_child("AudioFeed", true, false) as AudioStreamPlayer3D
		var step_aud := inst.get_node_or_null("PlayerOperator/FootstepAudio") as AudioStreamPlayer3D
		var alert_aud := inst.get_node_or_null("IndustrialTablet/TabletRoot/AudioAlert") as AudioStreamPlayer
		ok = _assert_true(click_aud != null and click_aud.stream != null, "PhysicalBreakerPanel/AudioClick sin stream") and ok
		ok = _assert_true(motor_aud != null and motor_aud.stream != null, "MotorMillUnit/MotorHumAudio3D sin stream") and ok
		ok = _assert_true(arc_aud != null and arc_aud.stream != null, "PhysicalCableConductor/AudioArc sin stream") and ok
		ok = _assert_true(feed_aud != null and feed_aud.stream != null, "PhysicalHopperFeeder/AudioFeed sin stream") and ok
		ok = _assert_true(step_aud != null and step_aud.stream != null, "PlayerOperator/FootstepAudio sin stream") and ok
		ok = _assert_true(alert_aud != null and alert_aud.stream != null, "IndustrialTablet/TabletRoot/AudioAlert sin stream") and ok
		var push_wav: AudioStreamWAV = IndustrialSoundSynthesizerScript.create_tablet_push_warning_sound()
		ok = _assert_true(push_wav != null and push_wav.data.size() > 8000, "Stream PCM característico de warning en tablet vacío") and ok

		# Auditoría end-to-end de Warning -> Sonido Tablet -> Leyenda HUD [TAB] -> Apertura Tablet en Warning
		var bus_qa = inst.get_node_or_null("/root/EventBus")
		var tab_ctrl = inst.get_node_or_null("IndustrialTablet/TabletRoot")
		var hud_tab_ctrl = inst.get_node_or_null("HUD/HUDController")
		if bus_qa != null and tab_ctrl != null and hud_tab_ctrl != null:
			tab_ctrl._select_tab(3)
			bus_qa.notification_posted.emit("ADVERTENCIA TOLVA T-301", "Sobrealimentación detectada en compuerta manual.", "warning")
			ok = _assert_true(tab_ctrl._has_unread_warning == true, "Tablet debe marcar warning no leído cuando está cerrada") and ok
			ok = _assert_true(hud_tab_ctrl._tablet_notify_legend.visible == true, "HUD debe mostrar leyenda de notificación nueva") and ok
			ok = _assert_true(hud_tab_ctrl._tablet_notify_title.text.to_lower().contains("alerta en tablet") and not hud_tab_ctrl._tablet_notify_title.text.contains("[TAB]"), "Leyenda HUD debe indicar alerta en tablet limpia sin [TAB] (obtuvo: %s)" % hud_tab_ctrl._tablet_notify_title.text) and ok
			tab_ctrl.toggle_tablet()
			ok = _assert_true(tab_ctrl.visible == true and tab_ctrl._active_tab_idx == 0 and tab_ctrl._warning_banner_card.visible == true, "Abrir tablet debe llevar directo al warning en Monitoreo IoT") and ok
			ok = _assert_true(hud_tab_ctrl._tablet_notify_legend.visible == false, "Al abrir tablet la leyenda de notificación nueva debe ocultarse") and ok
			ok = _assert_true(tab_ctrl.get_node("TabletChassis").size == Vector2(1228, 748) and tab_ctrl.get_node("Frame").size == Vector2(1180, 700), "Tamaño de tablet debe mantenerse invariante con warning visible") and ok
			var btn_close_qa := tab_ctrl.find_child("BtnClose", true, false) as Button
			ok = _assert_true(btn_close_qa == null, "BtnClose ('Salir') debe estar eliminado de la tablet") and ok
			tab_ctrl.toggle_tablet()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var listener_3d := inst.get_node_or_null("PlayerOperator/Head/AudioListener3D") as AudioListener3D
		ok = _assert_true(listener_3d != null, "Falta AudioListener3D en PlayerOperator/Head") and ok
		var amb_aud := inst.get_node_or_null("PlantAmbienceAudio") as AudioStreamPlayer
		ok = _assert_true(amb_aud != null and amb_aud.process_mode == Node.PROCESS_MODE_ALWAYS and amb_aud.volume_db >= -16.0,
			"PlantAmbienceAudio debe permanecer activo con ganancia audible") and ok
		var step_wav: AudioStreamWAV = IndustrialSoundSynthesizerScript.create_footstep_sound()
		var step_peak: int = 0
		for j in range(0, mini(step_wav.data.size(), 6000), 2):
			step_peak = maxi(step_peak, absi(step_wav.data.decode_s16(j)))
		ok = _assert_true(step_peak >= 24000, "Audio PCM debe estar normalizado para ser audible (peak=%d)" % step_peak) and ok

		# Auditoría de Puertas y Portones Interactivos (Paso 9)
		ok = _assert_true(IndustrialSoundSynthesizerScript.create_door_latch_sound().data.size() > 1000,
			"Stream PCM de puerta demasiado corto o vacío") and ok
		ok = _assert_true(IndustrialSoundSynthesizerScript.create_gate_motor_sound().data.size() > 2000,
			"Stream PCM de portón motorizado demasiado corto o vacío") and ok

		var doors := get_nodes_in_group("interactive_doors")
		ok = _assert_true(doors.size() >= 25,
			"Puertas interactivas insuficientes en planta: %d (esperado >= 25)" % doors.size()) and ok
		var modes_seen: Dictionary = {}
		var checked_sample: bool = false
		for dn in doors:
			if not (dn is InteractiveDoorScript):
				ok = false
				continue
			var d := dn as InteractiveDoorScript
			modes_seen[int(d.door_mode)] = true
			if d.door_mode == InteractiveDoorScript.DoorMode.HINGED_SINGLE:
				var swing := absf(d.primary_closed_angle - d.primary_open_angle)
				ok = _assert_true(swing >= deg_to_rad(80.0),
					"Puerta batiente %s debe rotar ~90° (swing=%.1f°)" % [d.name, rad_to_deg(swing)]) and ok
			var door_aud := d.get_node_or_null("DoorAudio") as AudioStreamPlayer3D
			ok = _assert_true(door_aud != null and door_aud.stream != null,
				"Puerta %s sin DoorAudio stream" % d.name) and ok
			ok = _assert_true(d.is_door_blocking(),
				"Puerta %s debe bloquear el paso al iniciar cerrada" % d.name) and ok
			if not checked_sample and not d.is_open:
				checked_sample = true
				d.interact(1)
				ok = _assert_true(d.is_open and not d.is_door_blocking(),
					"Puerta %s no liberó colisionador al abrirse con interact()" % d.name) and ok
				d.interact(1)
				ok = _assert_true(not d.is_open, "Puerta %s no volvió a cerrar con interact()" % d.name) and ok
		for req_mode in [0, 1, 2, 3]:
			ok = _assert_true(modes_seen.has(req_mode),
				"Falta modo de puerta interactiva %d (single/double/rollup/slide)" % req_mode) and ok
		detail = "%s | Doors=%d" % [detail, doors.size()]

		# Auditoría Física de Líneas Guía (0 cruces por muros / losas)
		await physics_frame
		await physics_frame
		var inst3d := inst as Node3D
		var space: PhysicsDirectSpaceState3D = inst3d.get_world_3d().direct_space_state
		var guide_exclude: Array[RID] = []
		if player is CollisionObject3D:
			guide_exclude.append((player as CollisionObject3D).get_rid())
		for wk in get_nodes_in_group("workers"):
			if wk is CollisionObject3D:
				guide_exclude.append((wk as CollisionObject3D).get_rid())
		for dn in doors:
			for sb in dn.find_children("DoorLeafBlocker", "StaticBody3D", true, false):
				if sb is CollisionObject3D:
					guide_exclude.append((sb as CollisionObject3D).get_rid())
		var pts: Array = TutorialInductionManagerScript.TOUR_ROUTE_POINTS
		var guide_wall_hits := 0
		for idx in range(pts.size() - 1):
			var p0: Vector3 = pts[idx]
			var p1: Vector3 = pts[idx + 1]
			var flat := Vector3(p1.x - p0.x, 0.0, p1.z - p0.z)
			if flat.length() < 0.05:
				continue
			var side := Vector3(-flat.normalized().z, 0.0, flat.normalized().x)
			for lat in [-0.25, 0.0, 0.25]:
				var q := PhysicsRayQueryParameters3D.create(
					p0 + Vector3(0.0, 0.35, 0.0) + side * float(lat),
					p1 + Vector3(0.0, 0.35, 0.0) + side * float(lat),
					1,
					guide_exclude
				)
				var hit: Dictionary = space.intersect_ray(q)
				if not hit.is_empty() and float(hit["normal"].y) < 0.78:
					guide_wall_hits += 1
		ok = _assert_true(guide_wall_hits == 0,
			"La línea guía TourFloorGuideLine atraviesa muros/equipos (%d impactos)" % guide_wall_hits) and ok

		# Auditoría Física de MEETING_COURSE_ROUTE (0 impactos en paredes/marcos de puertas de oficinas)
		var m_pts: Array = TutorialInductionManagerScript.MEETING_COURSE_ROUTE
		var meeting_wall_hits := 0
		for idx in range(m_pts.size() - 1):
			var p0: Vector3 = m_pts[idx]
			var p1: Vector3 = m_pts[idx + 1]
			var flat := Vector3(p1.x - p0.x, 0.0, p1.z - p0.z)
			if flat.length() < 0.05:
				continue
			var side := Vector3(-flat.normalized().z, 0.0, flat.normalized().x)
			for lat in [-0.25, 0.0, 0.25]:
				var q := PhysicsRayQueryParameters3D.create(
					p0 + Vector3(0.0, 0.35, 0.0) + side * float(lat),
					p1 + Vector3(0.0, 0.35, 0.0) + side * float(lat),
					1,
					guide_exclude
				)
				var hit: Dictionary = space.intersect_ray(q)
				if not hit.is_empty() and float(hit["normal"].y) < 0.78:
					meeting_wall_hits += 1
		ok = _assert_true(meeting_wall_hits == 0,
			"La ruta MEETING_COURSE_ROUTE a oficinas atraviesa paredes/marcos (%d impactos)" % meeting_wall_hits) and ok

		# Auditoría Cero Cruces de Líneas de Seguridad (Zone1, Zone2, Zone6, Zone8, Zone9)
		var hazard_boxes: Array[Dictionary] = [
			{"name": "Zone1_Milling_OSHA", "x0": -30.65, "x1": -21.35, "z0": 25.10, "z1": 48.60},
			{"name": "Zone2_CCM460V_RETIE", "x0": -21.33, "x1": -19.63, "z0": 37.20, "z1": 39.80},
			{"name": "Zone6_DispatchBay", "x0": -41.10, "x1": -32.90, "z0": 50.20, "z1": 55.40},
			{"name": "Zone8_IntakeConveyor_OSHA", "x0": -32.75, "x1": -26.95, "z0": 49.05, "z1": 53.35},
			{"name": "Zone9_AirThermal_OSHA", "x0": -40.80, "x1": -31.60, "z0": 29.90, "z1": 39.90}
		]
		var hazard_crossings := 0
		for idx in range(pts.size() - 1):
			var p0: Vector3 = pts[idx]
			var p1: Vector3 = pts[idx + 1]
			for s in range(11):
				var sp: Vector3 = p0.lerp(p1, float(s) / 10.0)
				for hb in hazard_boxes:
					if sp.x > float(hb["x0"]) and sp.x < float(hb["x1"]) and sp.z > float(hb["z0"]) and sp.z < float(hb["z1"]):
						hazard_crossings += 1
		ok = _assert_true(hazard_crossings == 0,
			"TOUR_ROUTE_POINTS no debe cruzar ninguna línea/zona de seguridad (%d muestras)" % hazard_crossings) and ok

		# Auditoría Pausa de Inducción del Guía SST en Portería (Controles y Mecánicas)
		var tut_node := inst.find_child("TutorialInductionManager", true, false)
		var hud_ctrl := inst.find_child("HUDController", true, false)
		ok = _assert_true(tut_node != null and hud_ctrl != null and guide != null,
			"Faltan nodos TutorialInductionManager/HUDController/WorkerSafetyAuditor para validar pausa inicial") and ok
		if tut_node != null and hud_ctrl != null and guide != null:
			ok = _assert_true(not bool(tut_node.is_briefing_active) and not hud_ctrl.is_briefing_visible() and not self.paused,
				"El menú de bienvenida no debe abrirse solo al llegar; debe requerir hablar con el Supervisor SST") and ok
			ok = _assert_true(not bool(guide.guide_has_target) and guide.can_interact(),
				"El guía SST debe esperar listo en Portería para que el jugador hable con él") and ok
			# 1) Primero en Portería: hablar con el Supervisor SST inicia la historia de la empresa (antes de preguntar por el curso)
			guide.interact(1)
			ok = _assert_true(bool(tut_node.get("porteria_story_active")) and not bool(tut_node.is_briefing_active) and not hud_ctrl.is_briefing_visible() and not self.paused and not bool(guide.guide_has_target),
				"Hablar primero con el Supervisor SST en Portería debe iniciar la historia de la empresa antes de preguntar por el curso SST") and ok
			# 2) Luego de la historia: al continuar se abre la elección del Curso SST
			tut_node.finish_porteria_story_and_enter()
			ok = _assert_true(bool(tut_node.get("porteria_story_completed")) and not bool(tut_node.get("porteria_story_active")) and bool(tut_node.is_briefing_active) and hud_ctrl.is_briefing_visible() and self.paused,
				"Al continuar tras la historia en Portería debe abrirse la elección del Curso SST") and ok
			ok = _assert_true(hud_ctrl.find_child("BriefingCard", true, false) != null,
				"Falta BriefingCard con elección del Curso SST") and ok
			hud_ctrl.close_briefing_panel()
			ok = _assert_true(not hud_ctrl.is_briefing_visible() and not self.paused,
				"Cerrar elección del Curso SST debe reanudar simulación sin quedar pausado") and ok
			ok = _assert_true(not bool(tut_node.is_briefing_active) and bool(tut_node.briefing_completed) and bool(guide.guide_has_target),
				"Tras elegir recorrido directo después de la historia, el guía SST debe iniciar el ingreso hacia Vestidores") and ok

			# Auditoría Bloqueo de Interacción SST hasta llegar y explicar
			ok = _assert_true(not guide.can_interact(),
				"SST no debe permitir interacción mientras camina hacia la estación") and ok
			var blocked_reply: String = guide.interact(1)
			ok = _assert_true(blocked_reply == "" and not hud_ctrl.is_briefing_visible() and not self.paused,
				"Interactuar con SST antes de llegar no debe pausar ni buguear al guía") and ok
			guide._begin_arrival_explanation()
			ok = _assert_true(bool(guide.is_explaining) and not guide.can_interact(),
				"SST no debe permitir interacción mientras termina de explicar al llegar") and ok
			guide._physics_process(1.7)
			ok = _assert_true(not bool(guide.is_explaining) and bool(guide.has_arrived_and_explained) and guide.can_interact(),
				"SST debe habilitar interacción solo después de llegar y terminar su explicación") and ok
			guide.interact(1)
			ok = _assert_true(hud_ctrl.is_briefing_visible() and self.paused,
				"SST debe abrir pausa de controles tras llegar y explicar") and ok
			hud_ctrl.close_briefing_panel()

		# Auditoría Sistema Anti-Atasco (múltiples inputs sin desplazamiento -> TP cercano seguro)
		if player != null and player.has_method("update_stuck_detector"):
			var saved_pos: Vector3 = player.global_position
			# Ubicar al jugador aprisionado junto a la jamba/muro de Vestidores (-14.5, 0.79, 47.0)
			var wedged_pos := Vector3(-14.55, 0.79, 47.05)
			player.global_position = wedged_pos
			player.velocity = Vector3.ZERO
			player.update_stuck_detector(0.05, Vector2.ZERO, 0)
			# Primera llamada al reubicar puede resetear ancla; fijamos ancla explícita para simular múltiples inputs sin movimiento
			player._stuck_anchor_pos = wedged_pos
			var recovered := false
			for _k in range(8):
				if player.update_stuck_detector(0.10, Vector2(0.0, -1.0), 1):
					recovered = true
					break
			ok = _assert_true(recovered, "Anti-atasco debe activar teletransporte tras múltiples inputs sin movimiento") and ok
			var tp_dist: float = player.global_position.distance_to(wedged_pos)
			ok = _assert_true(tp_dist >= 0.35 and tp_dist <= 4.5,
				"Anti-atasco debe mover a lugar cercano seguro (dist=%.2f m)" % tp_dist) and ok
			ok = _assert_true(player._is_capsule_free_at(player.global_position),
				"Destino de teletransporte anti-atasco debe estar 100%% libre de colisión") and ok
			player.global_position = saved_pos
			player.velocity = Vector3.ZERO

		# Regresión SST Vestidores y recorrido secuencial 1..12 (cero atasco en muro y max_step_height seguro)
		if guide != null:
			ok = _assert_true(float(guide.max_step_height) <= 0.35,
				"WorkerSafetyAuditor max_step_height debe ser <= 0.35 para no trepar muros (actual=%.2f)" % float(guide.max_step_height)) and ok
			var prev_idx: int = -1
			for sid in range(1, TutorialInductionManagerScript.STATIONS.size() + 1):
				var cur_idx: int = int(TutorialInductionManagerScript.STATION_TO_ROUTE_IDX.get(sid, -1))
				ok = _assert_true(cur_idx > prev_idx, "STATION_TO_ROUTE_IDX[%d]=%d debe avanzar secuencialmente tras %d" % [sid, cur_idx, prev_idx]) and ok
				prev_idx = cur_idx
			var saved_g_pos: Vector3 = guide.global_position
			var route_pts: Array = TutorialInductionManagerScript.TOUR_ROUTE_POINTS
			var vest_idx: int = int(TutorialInductionManagerScript.STATION_TO_ROUTE_IDX.get(2, 19))
			var ramp_start_idx: int = maxi(0, vest_idx - 8)
			# Probar ascenso completo por la rampa visible de concreto Norte e ingreso a Vestidores sin atascos
			guide.global_position = route_pts[ramp_start_idx]
			var ramp_wps: Array[Vector3] = []
			for ri in range(ramp_start_idx + 1, vest_idx + 1):
				ramp_wps.append(route_pts[ri])
			guide.set_guide_route(ramp_wps, route_pts[vest_idx])
			guide.set("_guide_recovery_count", 0)
			for _s in range(650):
				if guide.guide_has_target:
					guide._process_tour_guide_movement(1.0 / 60.0)
					guide._try_auto_step(1.0 / 60.0)
					guide.move_and_slide()
					if player != null:
						player.global_position = guide.global_position + Vector3(-0.9, 0.0, 0.0)
				else:
					break
			var ext_vest_dist := Vector2(guide.global_position.x - route_pts[vest_idx].x, guide.global_position.z - route_pts[vest_idx].z).length()
			ok = _assert_true(ext_vest_dist <= 0.65 and not guide.guide_has_target and int(guide.get("_guide_recovery_count")) == 0,
				"SST debe subir Rampa Exterior Norte e ingresar a Vestidores sin atascos (dist=%.2f, y=%.2f, rec=%d)" % [ext_vest_dist, guide.global_position.y, int(guide.get("_guide_recovery_count"))]) and ok

			var door_start_idx: int = maxi(0, vest_idx - 4)
			guide.global_position = route_pts[door_start_idx]
			if player != null:
				player.global_position = route_pts[door_start_idx] + Vector3(0.0, 0.0, 1.0)
			var vest_wps: Array[Vector3] = []
			for vi in range(door_start_idx + 1, vest_idx + 1):
				vest_wps.append(route_pts[vi])
			guide.set_guide_route(vest_wps, route_pts[vest_idx])
			guide.set("_guide_recovery_count", 0)
			for _s in range(260):
				if guide.guide_has_target:
					guide._process_tour_guide_movement(1.0 / 60.0)
					guide._try_auto_step(1.0 / 60.0)
					guide.move_and_slide()
					if player != null:
						player.global_position = guide.global_position + Vector3(-0.9, 0.0, 0.0)
				else:
					break
			var vest_dist := Vector2(guide.global_position.x - route_pts[vest_idx].x, guide.global_position.z - route_pts[vest_idx].z).length()
			ok = _assert_true(vest_dist <= 0.65 and not guide.guide_has_target,
				"SST debe cruzar Puerta de seguridad_12 y llegar dentro de Vestidores (dist=%.2f, pos=%s)" % [vest_dist, str(guide.global_position)]) and ok
			ok = _assert_true(guide.global_position.y <= 0.90,
				"SST no debe trepar muros al entrar a Vestidores (y=%.2f)" % guide.global_position.y) and ok
			ok = _assert_true(int(guide.get("_guide_recovery_count")) == 0,
				"SST debe cruzar Vestidores sin activar recuperación anti-atasco (rec=%d)" % int(guide.get("_guide_recovery_count"))) and ok

			# Regresión: InteractableArea de equipos (lockers, CCM, cable, tolva, pernos, rejilla) debe resolver al nodo con interact()
			if player != null:
				for owner_name in ["LockerEPPStation", "PhysicalBreakerPanel", "PhysicalCableConductor", "PhysicalHopperFeeder", "MechanicalBolt", "VentilationCover"]:
					var owner_node := inst.find_child(owner_name, true, false)
					if owner_node != null:
						var area_node := owner_node.find_child("*Area*", true, false)
						if area_node != null:
							var resolved: Node = player._find_interactable(area_node)
							ok = _assert_true(resolved == owner_node and resolved.has_method("interact"),
								"Area de %s debe resolver al dueño con interact(), obtuvo %s" % [owner_name, resolved.name if resolved else "null"]) and ok
							var p_txt := String(player._get_minimal_prompt_for(resolved))
							ok = _assert_true(p_txt != "Interactuar" and p_txt != "" and not p_txt.contains("[E]"),
								"Prompt de %s debe ser específico y limpio sin [E] (%s)" % [owner_name, p_txt]) and ok

			# Verificar diálogo de Vestidores indicando lockers e interacción directa con LockerEPPStation
			if hud_ctrl != null:
				var dlg_panel := hud_ctrl.find_child("DialoguePanel", true, false) as Control
				var dlg_speaker := hud_ctrl.find_child("DialogueSpeaker", true, false) as Label
				var dlg_body := hud_ctrl.find_child("DialogueBody", true, false) as Label
				ok = _assert_true(dlg_panel != null and is_equal_approx(dlg_panel.anchor_left, 0.0) and is_equal_approx(dlg_panel.anchor_right, 1.0),
					"DialoguePanel debe extenderse a lo ancho de la pantalla en la zona inferior") and ok
				ok = _assert_true(dlg_speaker != null and dlg_speaker.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER,
					"DialogueSpeaker debe estar centrado horizontalmente") and ok
				ok = _assert_true(dlg_body != null and dlg_body.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and dlg_body.text.contains("lockers"),
					"Diálogo de llegada en Vestidores debe estar centrado e indicar que la ropa EPP está en los lockers") and ok
			var main_locker := inst.find_child("LockerEPPStation", true, false)
			if main_locker != null:
				main_locker.set_epp_equipped(false)
				main_locker.interact(1)
				ok = _assert_true(bool(main_locker.epp_equipped) == true,
					"Interactuar directamente con LockerEPPStation debe equipar ropa EPP") and ok
				main_locker.set_epp_equipped(false)

			# Regresión: posturas naturales sin A-pose (manos <= 0.25m de eje lateral) y avance por [E] en Estaciones 3..12
			var mgr := inst.find_child("WorkerPlantManager", true, false) as Node3D
			if mgr != null:
				var m_sk := mgr.find_child("Skeleton3D", true, false) as Skeleton3D
				var m_ap := mgr.find_child("AnimationPlayer", true, false) as AnimationPlayer
				if m_sk != null and m_ap != null:
					m_ap.play("inspect")
					m_ap.seek(0.25, true)
					var rh := mgr.to_local(m_sk.to_global(m_sk.get_bone_global_pose(m_sk.find_bone("CC_Base_R_Hand_038")).origin))
					var lh := mgr.to_local(m_sk.to_global(m_sk.get_bone_global_pose(m_sk.find_bone("CC_Base_L_Hand_019")).origin))
					ok = _assert_true(absf(rh.x) <= 0.26 and absf(lh.x) <= 0.26 and rh.z < -0.10,
						"WorkerPlantManager inspect debe mantener brazos recogidos frente al pecho (R=%s L=%s)" % [str(rh), str(lh)]) and ok

			if tut_node != null and main_locker != null and player != null:
				var st3_idx: int = int(TutorialInductionManagerScript.STATION_TO_ROUTE_IDX.get(3, 24))
				main_locker.set_epp_equipped(true)
				guide.global_position = route_pts[st3_idx]
				guide.guide_has_target = false
				guide.is_explaining = false
				guide.has_arrived_and_explained = true
				player.global_position = route_pts[st3_idx] + Vector3(0.0, 0.0, 1.2)
				tut_node._process(0.1)
				ok = _assert_true(int(tut_node.target_station_id) == 3 and not bool(tut_node.visited_stations.get(3, false)),
					"Estación 3 no debe avanzar automáticamente solo por proximidad sin pulsar [E]") and ok
				var g_adv_prompt := String(guide.get_interact_prompt())
				ok = _assert_true(bool(tut_node.is_ready_for_interact_advance()) and g_adv_prompt == "Siguiente estación" and not g_adv_prompt.contains("[E]"),
					"SST en Estación 3 debe ofrecer prompt limpio 'Siguiente estación' sin [E] (obtuvo: %s)" % g_adv_prompt) and ok
				var adv_out: String = guide.interact(1)
				ok = _assert_true(adv_out != "" and int(tut_node.target_station_id) == 4 and bool(tut_node.visited_stations.get(3, false)),
					"Pulsar [E] sobre SST en Estación 3 debe completar Estación 3 y avanzar a Estación 4") and ok

			guide.global_position = saved_g_pos
			guide.guide_has_target = false

		# Regresión: Todos los Label3D flotantes (zonas, trabajadores, puntos) deben usar billboard;
		# los carteles grandes pegados a cada máquina (machine_aisle_label) deben mirar fijos de frente al pasillo.
		var lbls := inst.find_children("*", "Label3D", true, false)
		var billboard_lbl_count := 0
		var aisle_lbl_count := 0
		for ln in lbls:
			if ln is Label3D:
				var l3d := ln as Label3D
				if l3d.is_in_group("machine_aisle_label"):
					aisle_lbl_count += 1
					ok = _assert_true(l3d.billboard == BaseMaterial3D.BILLBOARD_DISABLED,
						"Cartel de máquina '%s' debe quedar fijo de frente al pasillo (sin billboard)" % l3d.text) and ok
					ok = _assert_true(l3d.font_size >= 72 and l3d.pixel_size >= 0.0015 and float(l3d.font_size) * l3d.pixel_size >= 0.13,
						"Cartel de máquina '%s' debe ser grande y legible (font_size=%d, pixel_size=%.4f)" % [l3d.text, l3d.font_size, l3d.pixel_size]) and ok
					var fwd := l3d.global_transform.basis.z
					ok = _assert_true(absf(fwd.x) > 0.9 or absf(fwd.z) > 0.9,
						"Cartel de máquina '%s' debe orientarse hacia el pasillo (+X/-X/+Z/-Z), fwd=%s" % [l3d.text, str(fwd)]) and ok
					ok = _assert_true(not l3d.double_sided,
						"Cartel de máquina '%s' debe ser single-sided (double_sided=false) para no espejarse a través de muros" % l3d.text) and ok
					var m_grp := str(l3d.get_meta("machine_group", ""))
					if m_grp in ["unidad_extraccion", "horno", "soplador", "intercambiador_calor", "ductos_aire"]:
						ok = _assert_true(fwd.x < -0.9,
							"Cartel exterior Oeste '%s' debe mirar hacia -X para leerse desde el patio oeste (fwd=%s)" % [l3d.text, str(fwd)]) and ok
				else:
					billboard_lbl_count += 1
					ok = _assert_true(l3d.billboard != BaseMaterial3D.BILLBOARD_DISABLED,
						"Label3D '%s' (%s) debe tener billboard activo para mirar siempre al jugador" % [l3d.text, str(l3d.get_path())]) and ok
		ok = _assert_true(billboard_lbl_count >= 10, "Debe haber >= 10 etiquetas Label3D billboard en planta (%d)" % billboard_lbl_count) and ok
		ok = _assert_true(aisle_lbl_count == 16, "Debe haber 16 carteles grandes de máquinas + CCM orientados al pasillo (%d)" % aisle_lbl_count) and ok

		# Regresión: Movimiento completo de camiones entrada/salida, apertura portón, nivelación y velocidad reglamentaria
		if prod_flow != null:
			var m_south := prod_flow.get_node_or_null("TruckIntakeMover") as Node3D
			var m_west := prod_flow.get_node_or_null("TruckDispatchMover") as Node3D
			if m_south != null and m_west != null:
				var fy_ry_w := _measure_truck_wheel_front_rear_y(m_west)
				ok = _assert_true(absf(fy_ry_w.x) <= 0.03 and fy_ry_w.y >= 0.34 and fy_ry_w.y <= 0.41,
					"TruckDispatchMover estacionado en rampa Patio Norte debe apoyar eje delantero en patio y trasero sobre la rampa (frente=%.4f, atrás=%.4f)" % [fy_ry_w.x, fy_ry_w.y]) and ok
				var fy_ry_s := _measure_truck_wheel_front_rear_y(m_south)
				ok = _assert_true(absf(fy_ry_s.x) <= 0.03 and absf(fy_ry_s.y) <= 0.03,
					"TruckIntakeMover debe apoyar sus ruedas al pavimento (frente=%.4f, atrás=%.4f)" % [fy_ry_s.x, fy_ry_s.y]) and ok

				var p0_s: Vector3 = m_south.global_position
				prod_flow.truck_cycle_time = 0.40 * prod_flow.TRUCK_CYCLE_DURATION
				prod_flow.step_production(0.1)
				ok = _assert_true(m_south.global_position.distance_to(p0_s) > 10.0,
					"Camión Sur debe desplazarse por la ruta de entrada/salida de estación") and ok
				if prod_flow._main_gate != null:
					ok = _assert_true(bool(prod_flow._main_gate.is_open),
						"Portón principal debe abrirse automáticamente al aproximarse el camión") and ok

				var saved_rpm := float(prod_flow.current_rpm)
				var saved_flow := float(prod_flow.current_flow_kg_s)
				var saved_cycle := float(prod_flow.truck_cycle_time)
				var m_bay2 := prod_flow.get_node_or_null("TruckBay2Mover") as Node3D
				var m_staging := prod_flow.get_node_or_null("TruckStagingMover") as Node3D
				var fleet_movers: Array[Node3D] = [m_south, m_west]
				if m_bay2 != null:
					fleet_movers.append(m_bay2)
				if m_staging != null:
					fleet_movers.append(m_staging)
				prod_flow.set_motor_rpm(1750.0, 0.8)
				prod_flow.truck_cycle_time = 0.0
				prod_flow.step_production(0.01)
				var prev_s: Vector3 = m_south.global_position
				var prev_w: Vector3 = m_west.global_position
				var max_fwd_ms := 0.0
				var max_rev_ms := 0.0
				var min_pair_dist := 9999.0
				var dt_spd := 1.0
				var n_spd := int(prod_flow.TRUCK_CYCLE_DURATION / dt_spd)
				for _si in range(n_spd):
					var u_s := float(prod_flow.truck_cycle_time) / float(prod_flow.TRUCK_CYCLE_DURATION)
					var u_w := float(prod_flow.dispatch_cycle_time)
					prod_flow.step_production(dt_spd)
					var vs := Vector2(m_south.global_position.x - prev_s.x, m_south.global_position.z - prev_s.z).length() / dt_spd
					var vw := Vector2(m_west.global_position.x - prev_w.x, m_west.global_position.z - prev_w.z).length() / dt_spd
					if u_s >= 0.90:
						max_rev_ms = maxf(max_rev_ms, vs)
					elif u_s >= 0.16:
						max_fwd_ms = maxf(max_fwd_ms, vs)
					if u_w >= 0.86 and u_w < 0.94:
						max_rev_ms = maxf(max_rev_ms, vw)
					elif u_w >= 0.22 and u_w < 0.86:
						max_fwd_ms = maxf(max_fwd_ms, vw)
					for fi in range(fleet_movers.size()):
						for fj in range(fi + 1, fleet_movers.size()):
							var p_i: Vector3 = fleet_movers[fi].global_position
							var p_j: Vector3 = fleet_movers[fj].global_position
							var d_ij := Vector2(p_i.x - p_j.x, p_i.z - p_j.z).length()
							if d_ij < min_pair_dist:
								min_pair_dist = d_ij
					prev_s = m_south.global_position
					prev_w = m_west.global_position
				prod_flow.set_motor_rpm(saved_rpm, saved_flow)
				prod_flow.truck_cycle_time = saved_cycle
				prod_flow.step_production(0.01)
				ok = _assert_true(max_fwd_ms * 3.6 <= 10.0 and max_rev_ms * 3.6 <= 5.0,
					"Velocidad camiones debe cumplir límite reglamentario (max_fwd=%.2f km/h <= 10, max_rev=%.2f km/h <= 5)" % [max_fwd_ms * 3.6, max_rev_ms * 3.6]) and ok
				ok = _assert_true(min_pair_dist >= 18.0,
					"Separación mínima entre camiones en todo el ciclo de 300s debe evitar cruces/colisiones (min_dist=%.2fm >= 18.0m)" % min_pair_dist) and ok
				# Verificar articulación de quinta rueda y contacto en pavimento para los 3 tractocamiones
				var semi_names := ["TruckIntakeMover", "TruckBay2Mover", "TruckStagingMover"]
				var max_bend_deg := 0.0
				var max_art_delta_deg := 0.0
				for sname in semi_names:
					var sm := prod_flow.find_child(sname, true, false) as Node3D
					var has_piv := sm != null and sm.find_child("TrailerArticulationPivot", true, false) != null
					var has_hull := sm != null and sm.find_child("*TrailerHull", true, false) != null
					ok = _assert_true(has_piv and has_hull, "Tractocamión %s debe contar con pivote de quinta rueda y colisionador de remolque" % sname) and ok
					var sy := _measure_truck_wheel_front_rear_y(sm)
					ok = _assert_true(absf(sy.x) <= 0.03 and absf(sy.y) <= 0.03,
						"Ruedas de %s deben apoyar sobre pavimento (front_y=%.4f, rear_y=%.4f)" % [sname, sy.x, sy.y]) and ok
				prod_flow.set_motor_rpm(1750.0, 100.0)
				prod_flow.truck_cycle_time = 0.0
				for k in range(36):
					prod_flow.step_production(prod_flow.TRUCK_CYCLE_DURATION / 36.0)
					for sname in semi_names:
						var sm := prod_flow.find_child(sname, true, false) as Node3D
						if sm == null:
							continue
						var art := sm.find_child("TrailerArticulationPivot", true, false) as Node3D
						var hull := sm.find_child("*TrailerHull", true, false) as Node3D
						if art != null and hull != null:
							var phys_bend := absf(rad_to_deg(wrapf(art.rotation.y + hull.rotation.y, -PI, PI)))
							max_bend_deg = maxf(max_bend_deg, phys_bend)
							max_art_delta_deg = maxf(max_art_delta_deg, absf(rad_to_deg(art.rotation.y)))
				prod_flow.set_motor_rpm(saved_rpm, saved_flow)
				prod_flow.truck_cycle_time = saved_cycle
				prod_flow.step_production(0.01)
				ok = _assert_true(max_art_delta_deg > 8.0 and max_bend_deg <= 56.0,
					"Articulación de quinta rueda debe girar en curvas (>8°) y respetar límite mecánico (<=56°): delta=%.1f° phys=%.1f°" % [max_art_delta_deg, max_bend_deg]) and ok

		# Regresión: Ruta peatonal exterior por la acera no debe invadir la vía Norte de camiones (Z >= 56.5)
		var ext_pts: Array = TutorialInductionManagerScript.TOUR_ROUTE_POINTS
		for wp_i in range(2, 11):
			var wp_p: Vector3 = ext_pts[wp_i]
			ok = _assert_true(wp_p.z <= 55.0,
				"Tramo exterior [%d] (%s) debe ir por acera sin cruzar calzada Norte de camiones (Z >= 56.5)" % [wp_i, str(wp_p)]) and ok

		# Regresión: Eliminación progresiva de líneas guía ya recorridas conforme avanza el jugador
		if tut_node != null and player != null:
			var saved_p_trim: Vector3 = player.global_position
			var saved_curr_s: int = int(tut_node.current_station_idx)
			var saved_targ_s: int = int(tut_node.target_station_id)
			var saved_epp_s: bool = bool(tut_node.epp_completed)
			tut_node.epp_completed = false
			tut_node.current_station_idx = 1
			tut_node.target_station_id = 2
			tut_node.sst_course_active = false
			tut_node.sst_course_completed = false
			tut_node._reset_guide_line_progress()
			tut_node._rebuild_floor_guide_line()
			player.global_position = ext_pts[4]
			tut_node._update_guide_line_progress()
			ok = _assert_true(int(tut_node.get("_guide_prog_seg")) >= 3 and float(tut_node.get("_guide_last_trim_dist")) > 10.0,
				"TourFloorGuideLine debe recortar segmentos ya recorridos al avanzar (seg=%d, dist=%.2f)" % [int(tut_node.get("_guide_prog_seg")), float(tut_node.get("_guide_last_trim_dist"))]) and ok
			tut_node.epp_completed = saved_epp_s
			tut_node.current_station_idx = saved_curr_s
			tut_node.target_station_id = saved_targ_s
			tut_node._reset_guide_line_progress()
			tut_node._rebuild_floor_guide_line()
			player.global_position = saved_p_trim

		# Regresión: Elección inicial Curso Rápido SST RETIE -> Sala de Reuniones -> Información y Quiz Simple
		if hud_ctrl != null and tut_node != null and guide != null and player != null:
			var btn_course := hud_ctrl.find_child("BtnCourseSST", true, false) as Button
			var btn_direct := hud_ctrl.find_child("BtnStartTour", true, false) as Button
			ok = _assert_true(btn_course != null and btn_direct != null,
				"Briefing inicial en Portería debe mostrar elección entre Curso SST RETIE y Recorrido Directo") and ok

			tut_node.briefing_completed = false
			tut_node.porteria_story_active = false
			tut_node.porteria_story_completed = false
			tut_node.sst_course_chosen = false
			tut_node.sst_course_active = false
			tut_node.sst_course_completed = false
			tut_node.epp_completed = false
			var locker_c := inst.find_child("LockerEPPStation", true, false)
			if locker_c != null:
				locker_c.set_epp_equipped(false)
			# Primero historia en Portería -> elegir tema -> Continuar abre el panel del Curso SST
			tut_node.start_porteria_story()
			ok = _assert_true(bool(tut_node.get("porteria_story_active")) and not hud_ctrl.is_briefing_visible() and not bool(tut_node.get("sst_course_active")),
				"Primero debe ejecutarse la historia de la empresa en Portería antes de ofrecer el curso SST") and ok
			tut_node.select_company_topic("historia")
			tut_node.select_company_topic("__continue__")
			ok = _assert_true(bool(tut_node.get("porteria_story_completed")) and not bool(tut_node.get("porteria_story_active")) and hud_ctrl.is_briefing_visible() and btn_course.visible and btn_direct.visible,
				"Al elegir Continuar tras la historia debe abrirse la elección entre Curso SST RETIE y Recorrido Directo") and ok
			hud_ctrl.close_briefing_panel_with_choice(true)
			ok = _assert_true(bool(tut_node.get("sst_course_chosen")) and bool(tut_node.get("sst_course_active")) and bool(tut_node.briefing_completed),
				"Elegir Sí tras la historia debe iniciar inmediatamente el recorrido hacia Sala de Reuniones para el curso SST") and ok

			var desk := tut_node.find_child("CourseDeskInteractable", true, false)
			ok = _assert_true(desk != null and desk.has_method("interact"),
				"Mesa interactiva CourseDeskInteractable debe estar activa en Sala de Reuniones") and ok

			guide.global_position = Vector3(51.2, 0.04, 34.5)
			guide.velocity = Vector3.ZERO
			guide.set("_guide_recovery_count", 0)
			player.global_position = Vector3(52.2, 0.04, 34.5)
			player.velocity = Vector3.ZERO
			var m_route: Array = tut_node.MEETING_COURSE_ROUTE
			var m_wp_i: int = 0
			for _t in range(650):
				if guide.guide_has_target:
					var dt_step: float = 1.0 / 60.0
					guide._process_tour_guide_movement(dt_step)
					guide._try_auto_step(dt_step)
					guide.move_and_slide()
					if m_wp_i < m_route.size():
						var tgt_m: Vector3 = m_route[m_wp_i]
						var fl := Vector2(tgt_m.x - player.global_position.x, tgt_m.z - player.global_position.z)
						var stop_lim := 0.7 if m_wp_i < m_route.size() - 1 else 1.85
						if fl.length() <= stop_lim and m_wp_i < m_route.size() - 1:
							m_wp_i += 1
							tgt_m = m_route[m_wp_i]
							fl = Vector2(tgt_m.x - player.global_position.x, tgt_m.z - player.global_position.z)
						if fl.length() > stop_lim:
							var pd := Vector3(fl.x, 0.0, fl.y).normalized()
							player.velocity.x = pd.x * 3.7
							player.velocity.z = pd.z * 3.7
						else:
							player.velocity.x = 0.0
							player.velocity.z = 0.0
						if not player.is_on_floor():
							player.velocity.y -= 9.8 * dt_step
						if player.has_method("_try_step_up"):
							player._try_step_up(dt_step, Vector3(player.velocity.x, 0.0, player.velocity.z))
						player.move_and_slide()
				else:
					break
			var room_pos: Vector3 = tut_node.MEETING_ROOM_POS
			var room_dist := Vector2(guide.global_position.x - room_pos.x, guide.global_position.z - room_pos.z).length()
			ok = _assert_true(room_dist <= 0.75 and not guide.guide_has_target and int(guide.get("_guide_recovery_count")) == 0,
				"Inspector SST debe guiar sin atascos hasta Sala de Reuniones (dist=%.2f, recov=%d)" % [room_dist, int(guide.get("_guide_recovery_count"))]) and ok

			tut_node._course_modal_auto_opened = false
			player.global_position = room_pos + Vector3(0.2, 0.0, 0.8)
			tut_node._process(0.05)
			var c_modal = hud_ctrl.get("_course_modal")
			ok = _assert_true(c_modal != null and not bool(c_modal.visible),
				"Al llegar a la Sala de Reuniones NO debe abrirse RetieCourseModal automáticamente") and ok
			guide.interact(1)
			ok = _assert_true(c_modal != null and bool(c_modal.visible),
				"Al hablar con el Supervisor SST en Sala de Reuniones debe abrirse RetieCourseModal") and ok
			if c_modal != null:
				c_modal._on_primary_pressed() # módulo 2
				c_modal._on_primary_pressed() # módulo 3
				c_modal._on_primary_pressed() # quiz
				c_modal._on_select_answer(0, 0)
				c_modal._on_select_answer(1, 1)
				c_modal._on_select_answer(2, 2)
				c_modal._on_primary_pressed() # validar
				ok = _assert_true(c_modal._count_correct() == 3,
					"Quiz simple RETIE debe calificar correctamente 3/3") and ok
				c_modal._on_primary_pressed() # cerrar y completar
				ok = _assert_true(bool(tut_node.get("sst_course_completed")) and not bool(tut_node.get("sst_course_active")),
					"Al aprobar el quiz debe completarse el curso y retomar ruta a Vestidores") and ok

		# Regresión Nuevos Ajustes y Planta Modificada (Cero Humanos Estáticos, Sin Component#33/Node2456, Tablero limpio, Glow Rojo/Blanco/Amarillo, Ruta Exterior, Saltar Tutorial, Narrativa)
		var has_static_human := false
		var p_root := inst.find_child("PlantaCompletaSketchUp", true, false)
		if p_root != null:
			for ch_h in p_root.find_children("*", "MeshInstance3D", true, false):
				var mi_h := ch_h as MeshInstance3D
				if mi_h != null and mi_h.mesh != null:
					for s_h in range(mi_h.mesh.get_surface_count()):
						var mat_h := mi_h.mesh.surface_get_material(s_h)
						if mat_h != null:
							var mn_h := mat_h.resource_name.to_lower()
							if "fig03" in mn_h or "fig33" in mn_h or "ske4b" in mn_h or "hseat" in mn_h:
								has_static_human = true
		ok = _assert_true(not has_static_human,
			"Modelos humanos estáticos de SketchUp deben estar eliminados sin afectar rodillos del molino") and ok
		ok = _assert_true(inst.find_child("Component#33", true, false) == null and inst.find_child("Node2456", true, false) == null,
			"Modelos sobrantes eliminados en SketchUp (Component#33, Node2456) no deben existir") and ok
		ok = _assert_true(inst.find_child("TechoPlantaOriginal", true, false) != null,
			"Techo original de la planta (TechoPlantaOriginal) debe estar restaurado sin alterar máquinas") and ok
		var mill_unit_n := inst.find_child("MotorMillUnit", true, false) as Node3D
		ok = _assert_true(mill_unit_n != null and Vector2(mill_unit_n.global_position.x - (-25.81), mill_unit_n.global_position.z - 42.60).length() <= 0.65 and Vector2(mill_unit_n.global_position.x - (-22.75), mill_unit_n.global_position.z - 45.00).length() >= 2.0,
			"MotorMillUnit (Motor 10 HP) debe estar montado en la Trituradora (-25.81, 42.60) y NO en la banda Node1365 (actual=%s)" % [str(mill_unit_n.global_position) if mill_unit_n != null else "null"]) and ok
		var breaker_node := inst.find_child("PhysicalBreakerPanel", true, false) as Node3D
		var zone2_node := inst.find_child("Zone2_CCM460V_RETIE", true, false) as Node3D
		var zone4_node := inst.find_child("Zone4_PedestrianWalkway_OSHA", true, false) as Node3D
		var zone8_node := inst.find_child("Zone8_IntakeConveyor_OSHA", true, false) as Node3D
		var zone9_node := inst.find_child("Zone9_AirThermal_OSHA", true, false) as Node3D
		if breaker_node != null and zone2_node != null:
			ok = _assert_true(Vector2(breaker_node.global_position.x - zone2_node.global_position.x, breaker_node.global_position.z - zone2_node.global_position.z).length() <= 0.15,
				"PhysicalBreakerPanel debe quedar centrado en recuadro Zone2_CCM460V_RETIE (panel=%s, zone=%s)" % [str(breaker_node.global_position), str(zone2_node.global_position)]) and ok
			ok = _assert_true(breaker_node.global_position.x <= -19.8,
				"PhysicalBreakerPanel debe estar reubicado cerca de las máquinas fuera del pasillo central (pos=%s)" % str(breaker_node.global_position)) and ok
		ok = _assert_true(zone4_node != null and absf(zone4_node.global_position.x - (-18.69)) <= 0.10,
			"Zone4_PedestrianWalkway_OSHA debe quedar centrado con la puerta de entrada X=-18.69 (actual=%s)" % [str(zone4_node.global_position) if zone4_node else "null"]) and ok
		ok = _assert_true(zone8_node != null,
			"Falta perímetro de seguridad Zone8_IntakeConveyor_OSHA en bandas exteriores de descarga/tolva") and ok
		ok = _assert_true(zone9_node != null,
			"Falta perímetro de seguridad Zone9_AirThermal_OSHA en zona exterior de aire y térmica") and ok
		ok = _assert_true(breaker_node != null and breaker_node.find_child("DownloadedCabinetModel", true, false) != null and breaker_node.find_child("defaultMaterial3", true, false) == null,
			"PhysicalBreakerPanel debe cargar panel_control.glb sin tubos/cables residuales (defaultMaterial3)") and ok
		var glow_ctrl := inst.find_child("InteractableGlowController", true, false)
		ok = _assert_true(glow_ctrl != null, "Falta InteractableGlowController para resaltado rojo/blanco") and ok
		if glow_ctrl != null:
			glow_ctrl.refresh_highlights(true)
			var gs_norm: Dictionary = glow_ctrl.get_glow_summary()
			ok = _assert_true(int(gs_norm.get("motor_meshes", 0)) > 0 and int(gs_norm.get("hopper_meshes", 0)) > 0 and int(gs_norm.get("cyclone_meshes", 0)) > 0 and int(gs_norm.get("bag_meshes", 0)) == 0 and int(gs_norm.get("locker_meshes", 0)) > 0 and int(gs_norm.get("truck_meshes", 0)) == 0 and int(gs_norm.get("breaker_meshes", 0)) >= 4 and bool(gs_norm.get("all_15_bound", false)),
				"InteractableGlowController debe enlazar las 15 máquinas ordenadas sin glow en camiones ni sacos (%s)" % str(gs_norm.get("ordered_15_meshes", {}))) and ok
			ok = _assert_true(not bool(gs_norm.get("motor_fault", true)), "Motor sano no debe iniciar con resaltado rojo de falla") and ok
			if breaker_node != null and breaker_node.has_method("toggle_breaker_l3"):
				breaker_node.toggle_breaker_l3()
				glow_ctrl.refresh_highlights(true)
				ok = _assert_true(bool(glow_ctrl.get_glow_summary().get("breaker_fault", false)), "Apertura de Breaker L3 debe activar resaltado rojo de falla en panel_control.glb") and ok
				breaker_node.toggle_breaker_l3()
				glow_ctrl.refresh_highlights(true)
				ok = _assert_true(not bool(glow_ctrl.get_glow_summary().get("breaker_fault", true)), "Rearme de Breaker L3 debe retornar resaltado de panel_control.glb a blanco normal") and ok
			var main_cable := inst.find_child("PhysicalCableConductor", true, false)
			if main_cable != null:
				main_cable.cut_cable()
				glow_ctrl.refresh_highlights(true)
				ok = _assert_true(bool(glow_ctrl.get_glow_summary().get("motor_fault", false)), "Corte de cable L3 debe activar resaltado rojo de falla en motor") and ok
				main_cable.repair_cable()
				glow_ctrl.refresh_highlights(true)
				ok = _assert_true(not bool(glow_ctrl.get_glow_summary().get("motor_fault", true)), "Reparar L3 debe retornar resaltado a blanco normal") and ok
		if tut_node != null and hud_ctrl != null and player != null:
			# Verificar ruta Portería -> Vestidores (0..15) no cruza dentro de Nave de Molienda
			var r_ext: Array = tut_node.TOUR_ROUTE_POINTS
			var enters_nave := false
			for idx_e in range(0, 16):
				var rp: Vector3 = r_ext[idx_e]
				if rp.x >= -31.5 and rp.x <= -17.2 and rp.z >= 22.0 and rp.z <= 48.8:
					enters_nave = true
			ok = _assert_true(not enters_nave, "Ruta hacia Vestidores (0..15) no debe cruzar la Nave de Producción") and ok
			# Verificar que la ruta completa del recorrido (TOUR_ROUTE_POINTS) nunca cruza líneas de seguridad (Zone1/2/6/8/9)
			var tour_hazard_hits := 0
			var hz_rects: Array[Rect2] = []
			for hzn in ["Zone1_Milling_OSHA", "Zone2_CCM460V_RETIE", "Zone6_DispatchBay", "Zone8_IntakeConveyor_OSHA", "Zone9_AirThermal_OSHA"]:
				var hzn_node := inst.find_child(hzn, true, false) as Node3D
				if hzn_node != null:
					var hcol := hzn_node.find_child("CollisionShape3D", true, false) as CollisionShape3D
					if hcol != null and hcol.shape is BoxShape3D:
						var hsz: Vector3 = (hcol.shape as BoxShape3D).size
						hz_rects.append(Rect2(hzn_node.global_position.x - hsz.x * 0.5, hzn_node.global_position.z - hsz.z * 0.5, hsz.x, hsz.z))
			for seg_i in range(r_ext.size() - 1):
				var sp0: Vector3 = r_ext[seg_i]
				var sp1: Vector3 = r_ext[seg_i + 1]
				var n_sub := maxi(1, int(ceil(sp0.distance_to(sp1) / 0.25)))
				for sub_k in range(n_sub + 1):
					var smp := sp0.lerp(sp1, float(sub_k) / float(n_sub))
					var pt_xz := Vector2(smp.x, smp.z)
					for hr in hz_rects:
						if hr.has_point(pt_xz):
							tour_hazard_hits += 1
							break
			ok = _assert_true(tour_hazard_hits == 0,
				"La ruta guiada TOUR_ROUTE_POINTS no debe cruzar ninguna zona de seguridad OSHA/RETIE (cruces=%d)" % tour_hazard_hits) and ok

			# Verificar botón Saltar Tutorial + teletransporte a la estación final (Estación 19 exterior)
			var btn_skip := hud_ctrl.find_child("BtnSkipTutorial", true, false) as Button
			var btn_skip_hud := hud_ctrl.find_child("BtnSkipTutorialHUD", true, false) as Button
			ok = _assert_true(btn_skip != null and btn_skip_hud != null, "Deben existir botones visibles Saltar Tutorial en Briefing y HUD") and ok
			tut_node.tutorial_skipped = false
			tut_node.visited_stations.clear()
			tut_node.current_station_idx = 1
			tut_node.target_station_id = 2
			tut_node._start_exterior_narration()
			ok = _assert_true(bool(tut_node.get("_narration_active")) == true, "Locución exterior sincronizada debe activarse rumbo a Vestidores") and ok
			tut_node.skip_tutorial_to_final_station()
			var total_st_n: int = tut_node.STATIONS.size()
			var final_st_pos: Vector3 = tut_node.TOUR_ROUTE_POINTS[tut_node.TOUR_ROUTE_POINTS.size() - 1]
			ok = _assert_true(bool(tut_node.get("tutorial_skipped")) and int(tut_node.target_station_id) == total_st_n and bool(tut_node.epp_completed) and tut_node.visited_stations.size() >= total_st_n - 1,
				"Saltar Tutorial debe inicializar estado en Estación %d con EPP completo (%s)" % [total_st_n, str(tut_node.get_state_summary())]) and ok
			ok = _assert_true(Vector2(player.global_position.x - final_st_pos.x, player.global_position.z - final_st_pos.z).length() <= 1.0,
				"Saltar Tutorial debe teletransportar a Estación %d (%s), actual: %s" % [total_st_n, str(final_st_pos), str(player.global_position)]) and ok
			var gl_after := tut_node.find_child("TourFloorGuideLine", true, false) as MeshInstance3D
			ok = _assert_true(gl_after == null or not gl_after.visible, "Sin línea azul ni guía residual tras saltar tutorial") and ok

			# Regresión: Glow progresivo máquina por máquina (Zona de Carga -> Interior -> Exterior) en BLUE_PULSE no seleccionable -> Blanco post-tutorial + X-Ray
			if glow_ctrl != null:
				tut_node.tutorial_skipped = false
				tut_node.induction_certified = false
				tut_node.visited_stations.clear()
				tut_node.is_briefing_active = false
				tut_node.briefing_completed = true
				tut_node.sst_course_active = false

				# Estación 3: Zona de Carga (Banda de Descarga 01)
				tut_node.target_station_id = 3
				glow_ctrl.refresh_highlights(true)
				glow_ctrl.set_hovered_machine_group("banda_descarga")
				ok = _assert_true(
					glow_ctrl.get_group_state("banda_descarga") == "BLUE_PULSE"
					and glow_ctrl.get_group_state("motor") == "HIDDEN"
					and not glow_ctrl.has_active_green_selection(),
					"En Estación 3 (Zona de Carga) Banda 01 debe tener glow BLUE_PULSE no seleccionable"
				) and ok

				# Estación 10: Tablero CCM 460 V
				tut_node.target_station_id = 10
				glow_ctrl.refresh_highlights(true)
				var gs_s4: Dictionary = glow_ctrl.get_glow_summary()
				glow_ctrl.set_hovered_machine_group("breaker")
				ok = _assert_true(
					not bool(gs_s4.get("post_tutorial", true))
					and glow_ctrl.get_group_state("breaker") == "BLUE_PULSE"
					and glow_ctrl.get_group_state("motor") == "HIDDEN"
					and not glow_ctrl.has_active_green_selection()
					and glow_ctrl.get_hover_selection_prompt(2) == "",
					"En Estación 10 del tutorial solo Tablero CCM debe tener glow azul parpadeante (BLUE_PULSE) no seleccionable (%s)" % str(gs_s4.get("group_states"))
				) and ok

				# Estación 8: Motor 10 HP
				tut_node.target_station_id = 8
				glow_ctrl.refresh_highlights(true)
				glow_ctrl.set_hovered_machine_group("motor")
				ok = _assert_true(
					glow_ctrl.get_group_state("motor") == "BLUE_PULSE"
					and glow_ctrl.get_group_state("breaker") == "HIDDEN"
					and not glow_ctrl.has_active_green_selection(),
					"En Estación 8 del tutorial solo Motor 10 HP debe tener glow BLUE_PULSE sin volverse verde al apuntar"
				) and ok

				# Estación 19: Ductos de Aire (Exterior)
				tut_node.target_station_id = 19
				glow_ctrl.refresh_highlights(true)
				glow_ctrl.set_hovered_machine_group("ductos_aire")
				ok = _assert_true(
					glow_ctrl.get_group_state("ductos_aire") == "BLUE_PULSE"
					and glow_ctrl.get_group_state("motor") == "HIDDEN"
					and not glow_ctrl.has_active_green_selection(),
					"En Estación 19 (Exterior) solo Ductos de Aire debe tener glow BLUE_PULSE no seleccionable"
				) and ok

				# Estación 20: Cierre frente al Tablero Eléctrico CCM 460 V + entrega de labor/instrucciones al hablar con SST
				var last_sid: int = tut_node.STATIONS.size()
				var last_st: Dictionary = tut_node.STATIONS[last_sid - 1]
				var last_pos: Vector3 = last_st["pos"]
				ok = _assert_true(
					last_sid == 20 and Vector2(last_pos.x - (-18.69), last_pos.z - 38.5).length() <= 0.5,
					"La estación final (%d) debe cerrar frente al Tablero Eléctrico CCM (-18.69, 38.5), actual=%s" % [last_sid, str(last_pos)]
				) and ok
				tut_node.epp_completed = true
				tut_node.briefing_completed = true
				tut_node.is_briefing_active = false
				tut_node.target_station_id = last_sid
				tut_node.visited_stations.erase(last_sid)
				glow_ctrl.refresh_highlights(true)
				ok = _assert_true(
					glow_ctrl.get_group_state("breaker") == "BLUE_PULSE",
					"En Estación 20 (Cierre en Tablero Eléctrico) el Tablero CCM debe destacarse en BLUE_PULSE"
				) and ok
				guide.global_position = Vector3(-18.69, 0.83, 38.5)
				guide.guide_has_target = false
				guide.is_explaining = false
				guide.has_arrived_and_explained = true
				player.global_position = Vector3(-18.69, 0.85, 39.4)
				var close_reply: String = guide.interact(1)
				var b_greet_end := hud_ctrl.find_child("BriefingGreeting", true, false) as Label
				var b_secs_end := hud_ctrl.find_child("BriefingSectionsBox", true, false) as VBoxContainer
				ok = _assert_true(
					close_reply != ""
					and bool(tut_node.visited_stations.get(last_sid, false))
					and hud_ctrl.is_briefing_visible()
					and b_greet_end != null
					and b_greet_end.text.contains("TU LABOR")
					and b_greet_end.text.contains("QUÉ PUEDES HACER")
					and b_greet_end.text.contains("CÓMO HACERLO")
					and b_greet_end.text.contains("\n")
					and b_secs_end != null and b_secs_end.visible and b_secs_end.get_child_count() == 3,
					"Al cerrar el recorrido frente al tablero eléctrico, el SST debe explicar la labor en 3 tarjetas separadas con saltos de línea"
				) and ok
				hud_ctrl.close_briefing_panel()

				tut_node.skip_tutorial_to_final_station()
				# Posicionar jugador en pasillo central para auditar visibilidad cercana de los 5 grupos de shells WHITE
				player.global_position = Vector3(-18.69, 0.85, 40.5)
				glow_ctrl.refresh_highlights(true)
				var gs_post: Dictionary = glow_ctrl.get_glow_summary()
				ok = _assert_true(bool(gs_post.get("post_tutorial", false)) and bool(gs_post.get("xray_enabled", false)),
					"Tras finalizar/saltar tutorial debe activarse glow global y X-Ray a través de paredes") and ok
				for grp_k in glow_ctrl.ALL_GROUPS:
					var expected_st: String = "HIDDEN" if (grp_k == "locker" and tut_node.epp_completed) else "WHITE"
					ok = _assert_true(glow_ctrl.get_group_state(grp_k) == expected_st,
						"Tras tutorial completado, equipo '%s' debe tener estado '%s' (actual=%s)" % [grp_k, expected_st, glow_ctrl.get_group_state(grp_k)]) and ok

				# Verificación estricta de glow solo-borde en secador_rotatorio, unidad_extraccion, soplador, hopper y breaker
				# Godot invierte glFrontFace automáticamente en mallas con det < 0; usar cull_front garantiza bordes limpios sin rellenar caras frontales.
				for target_k in ["secador_rotatorio", "unidad_extraccion", "soplador", "hopper", "breaker"]:
					var target_shells: Array = glow_ctrl._shells_by_group.get(target_k, [])
					ok = _assert_true(target_shells.size() > 0, "No hay shells de glow en %s" % target_k) and ok
					for sh_entry in target_shells:
						var sh_inst: MeshInstance3D = sh_entry.get("shell")
						ok = _assert_true(sh_inst != null and is_instance_valid(sh_inst) and sh_inst.visible and sh_inst.material_override != null,
							"Shell de glow inactivo o invisible en %s (%s)" % [target_k, sh_inst.name if sh_inst else "null"]) and ok
						if sh_inst != null and sh_inst.material_override is ShaderMaterial:
							var sm_code: String = (sh_inst.material_override as ShaderMaterial).shader.code
							ok = _assert_true(sm_code.contains("cull_front"),
								"Shell en %s debe usar cull_front para dibujar solo contorno de bordes: %s" % [target_k, sm_code.substr(0, 45)]) and ok

				var locker_st_node := inst.find_child("LockerEPPStation", true, false)
				if locker_st_node != null and locker_st_node.has_method("set_epp_equipped"):
					locker_st_node.set_epp_equipped(false)
					tut_node.epp_completed = false
					glow_ctrl.refresh_highlights(true)
					ok = _assert_true(glow_ctrl.get_group_state("locker") != "HIDDEN",
						"Con EPP no activo, lockers deben tener glow activo (actual=%s)" % glow_ctrl.get_group_state("locker")) and ok
					locker_st_node.set_epp_equipped(true)
					tut_node.epp_completed = true
					glow_ctrl.refresh_highlights(true)
					ok = _assert_true(glow_ctrl.get_group_state("locker") == "HIDDEN",
						"Con EPP activo, lockers deben ocultar su glow (actual=%s)" % glow_ctrl.get_group_state("locker")) and ok

				var vent_n := inst.find_child("VentilationCover", true, false)
				var hopper_n := inst.find_child("PhysicalHopperFeeder", true, false)
				var motor_n := inst.find_child("InductionMotor", true, false)
				if vent_n != null and hopper_n != null:
					vent_n.set_blocked(true)
					hopper_n.throw_bag_into_hopper()
					glow_ctrl.refresh_highlights(true)
					ok = _assert_true(glow_ctrl.get_group_state("motor") == "YELLOW" and glow_ctrl.get_group_state("hopper") == "YELLOW",
						"Advertencias activas deben aplicar glow YELLOW en motor y tolva (m=%s h=%s)" % [glow_ctrl.get_group_state("motor"), glow_ctrl.get_group_state("hopper")]) and ok
					vent_n.set_blocked(false)
					hopper_n.clear_jam()
				if motor_n != null:
					motor_n.stop_motor()
					glow_ctrl.refresh_highlights(true)
					ok = _assert_true(glow_ctrl.get_group_state("motor") == "RED" and glow_ctrl.get_group_state("hopper") == "RED",
						"Máquina detenida debe activar glow RED en motor y tolva") and ok
					motor_n.start_motor()
					glow_ctrl.refresh_highlights(true)
					ok = _assert_true(glow_ctrl.get_group_state("motor") == "WHITE",
						"Al reanudar motor sin fallas debe regresar a glow WHITE") and ok

				var occ_cam := Camera3D.new()
				inst.add_child(occ_cam)
				occ_cam.current = true
				occ_cam.global_position = Vector3(-11.5, 2.3, 39.5)
				occ_cam.look_at(Vector3(-21.5, 1.6, 41.5), Vector3.UP)
				glow_ctrl.refresh_highlights(true)
				var occ_map: Dictionary = glow_ctrl.get_glow_summary().get("occluded_groups", {})
				ok = _assert_true(bool(occ_map.get("motor", false)) and bool(occ_map.get("breaker", false)),
					"Cámara tras muro este debe activar oclusión X-Ray para ver glow a través de paredes (%s)" % str(occ_map)) and ok
				occ_cam.queue_free()

				# Regresión: Señalar máquina con mouse -> glowing VERDE + tecla [E] exige herramienta correcta para inducir y reparar fallas en CCM y en las 15 máquinas ordenadas
				var hover_cam := Camera3D.new()
				inst.add_child(hover_cam)
				hover_cam.current = true
				hover_cam.global_position = Vector3(-18.69, 1.8, 38.5)
				hover_cam.look_at(Vector3(-20.48, 1.5, 38.5), Vector3.UP)
				var vp_size := root.get_visible_rect().size
				if vp_size.x <= 1.0:
					vp_size = Vector2(1280.0, 720.0)
				var hovered_grp := String(glow_ctrl.update_hover_from_camera(hover_cam, vp_size * 0.5, 12.0, player.get_rid()))
				ok = _assert_true(hovered_grp == "breaker" and glow_ctrl.get_group_state("breaker") == "GREEN" and glow_ctrl.has_active_green_selection(),
					"Apuntar con mouse al Tablero CCM debe activar glow VERDE (grp=%s, st=%s)" % [hovered_grp, glow_ctrl.get_group_state("breaker")]) and ok
				player._select_tool(1) # Manos NO deben inducir falla en CCM
				player._handle_interaction()
				ok = _assert_true(breaker_node != null and bool(breaker_node.l3_active) and not bool(glow_ctrl.is_breaker_fault_active()),
					"Pulsar [E] con Manos (1) en CCM NO debe inducir falla (exige herramienta)") and ok
				player._select_tool(2) # Alicates (2) sí inducen apertura L3
				player._handle_interaction()
				ok = _assert_true(breaker_node != null and not bool(breaker_node.l3_active) and bool(glow_ctrl.is_breaker_fault_active()),
					"Pulsar [E] con herramienta [2] Alicates en selección verde CCM debe inducir falla eléctrica 340 V") and ok
				glow_ctrl.set_hovered_machine_group("")
				ok = _assert_true(glow_ctrl.get_group_state("breaker") == "RED",
					"Al retirar el mouse tras inducir falla en CCM, su glow debe quedar RED (%s)" % glow_ctrl.get_group_state("breaker")) and ok
				var sm_loop := root.get_node_or_null("/root/SimulationManager")
				glow_ctrl.set_hovered_machine_group("breaker")
				player._select_tool(1) # Manos NO deben rearmar CCM
				player._handle_interaction()
				ok = _assert_true(not bool(breaker_node.l3_active), "Reparación CCM sin Kit LOTO/Llave debe ser rechazada") and ok
				player._select_tool(5) # Con máquinas en marcha, incluso con Kit LOTO se exige parar primero
				player._handle_interaction()
				ok = _assert_true(not bool(breaker_node.l3_active), "Rearmar CCM con máquinas encendidas debe bloquearse hasta detener las máquinas") and ok
				if sm_loop != null and sm_loop.has_method("set_emergency_stop"):
					sm_loop.set_emergency_stop(true, "QA_TEST")
				player._handle_interaction()
				if sm_loop != null and sm_loop.has_method("set_emergency_stop"):
					sm_loop.set_emergency_stop(false, "QA_TEST")
				glow_ctrl.set_hovered_machine_group("")
				ok = _assert_true(bool(breaker_node.l3_active) and glow_ctrl.get_group_state("breaker") == "WHITE",
					"Volver a pulsar [E] con Kit LOTO [5] sobre CCM fallado con máquinas detenidas debe rearmar a WHITE") and ok

				for test_grp in glow_ctrl.ORDERED_15_MACHINES:
					glow_ctrl.set_hovered_machine_group(test_grp)
					ok = _assert_true(glow_ctrl.get_group_state(test_grp) == "GREEN",
						"Modo selección verde debe activarse en '%s' (actual=%s)" % [test_grp, glow_ctrl.get_group_state(test_grp)]) and ok
					player._select_tool(1) # Herramienta incorrecta (Manos) no induce falla
					player._handle_interaction()
					glow_ctrl.set_hovered_machine_group("")
					ok = _assert_true(glow_ctrl.get_group_state(test_grp) == "WHITE" and not bool(glow_ctrl.is_machine_fault_active(test_grp)),
						"Pulsar [E] sin herramienta adecuada sobre '%s' no debe inducir falla (%s)" % [test_grp, glow_ctrl.get_group_state(test_grp)]) and ok
					glow_ctrl.set_hovered_machine_group(test_grp)
					var req_in := int(glow_ctrl.get_required_tool_for_action(test_grp, false))
					player._select_tool(req_in)
					player._handle_interaction()
					glow_ctrl.set_hovered_machine_group("")
					ok = _assert_true(glow_ctrl.get_group_state(test_grp) == "RED" and bool(glow_ctrl.is_machine_fault_active(test_grp)),
						"Pulsar [E] con herramienta %d sobre '%s' debe inducir falla y mostrar glow RED (%s)" % [req_in, test_grp, glow_ctrl.get_group_state(test_grp)]) and ok
					glow_ctrl.set_hovered_machine_group(test_grp)
					player._select_tool(1) # Herramienta incorrecta no repara falla
					player._handle_interaction()
					ok = _assert_true(bool(glow_ctrl.is_machine_fault_active(test_grp)),
						"Reparar '%s' sin herramienta adecuada debe ser rechazado" % test_grp) and ok
					var req_out := int(glow_ctrl.get_required_tool_for_action(test_grp, true))
					player._select_tool(req_out)
					player._handle_interaction() # En marcha debe bloquearse
					ok = _assert_true(bool(glow_ctrl.is_machine_fault_active(test_grp)),
						"Reparar '%s' con máquinas encendidas debe ser bloqueado" % test_grp) and ok
					if sm_loop != null and sm_loop.has_method("set_emergency_stop"):
						sm_loop.set_emergency_stop(true, "QA_TEST")
					player._handle_interaction() # Detenido sí debe reparar
					if sm_loop != null and sm_loop.has_method("set_emergency_stop"):
						sm_loop.set_emergency_stop(false, "QA_TEST")
					glow_ctrl.set_hovered_machine_group("")
					ok = _assert_true(glow_ctrl.get_group_state(test_grp) == "WHITE" and not bool(glow_ctrl.is_machine_fault_active(test_grp)),
						"Segundo [E] con herramienta %d sobre '%s' tras detener máquinas debe despejar falla a WHITE (%s)" % [req_out, test_grp, glow_ctrl.get_group_state(test_grp)]) and ok

				# Verificar que falla de secador/horno impacta térmicamente al modelo Kloss y regresa a 0 al repararse
				glow_ctrl.set_hovered_machine_group("horno")
				player._select_tool(int(glow_ctrl.get_required_tool_for_action("horno", false)))
				player._handle_interaction()
				ok = _assert_true(float(motor_n.ext_temp_offset_c) >= 30.0,
					"Falla en 12 · Horno debe propagar sobrecarga térmica al gemelo motor (dT=%.1f)" % float(motor_n.ext_temp_offset_c)) and ok
				player._select_tool(int(glow_ctrl.get_required_tool_for_action("horno", true)))
				if sm_loop != null and sm_loop.has_method("set_emergency_stop"):
					sm_loop.set_emergency_stop(true, "QA_TEST")
				player._handle_interaction()
				if sm_loop != null and sm_loop.has_method("set_emergency_stop"):
					sm_loop.set_emergency_stop(false, "QA_TEST")
				glow_ctrl.set_hovered_machine_group("")
				ok = _assert_true(is_equal_approx(float(motor_n.ext_temp_offset_c), 0.0),
					"Reparar 12 · Horno tras detener máquinas debe normalizar sobrecarga térmica externa (dT=%.1f)" % float(motor_n.ext_temp_offset_c)) and ok
				player._select_tool(1)

				# Verificar animación de producto a lo largo de la línea (18 emisores GPUParticles3D, sacos GLB reales y reacción a fallas/parada)
				if prod_flow != null and motor_n != null:
					var pvis_chk := prod_flow.get_node_or_null("ProductFlowVisuals")
					var emit_cnt := 0
					if pvis_chk != null:
						for c_em in pvis_chk.get_children():
							if c_em is GPUParticles3D:
								emit_cnt += 1
					ok = _assert_true(pvis_chk != null and emit_cnt >= 16 and prod_flow.find_child("MovingBag50kg", true, false) != null,
						"ProductFlowVisuals debe instanciar flujos granulares, cascadas y Super Sacos GLB reales (emit=%d)" % emit_cnt) and ok
					motor_n.is_running = true
					motor_n.current_frequency = 60.0
					motor_n.target_frequency = 60.0
					motor_n.rotor_speed_rpm = 1743.0
					prod_flow.set_motor_rpm(1743.0, 1.8)
					var prog0: float = float(prod_flow.get_production_metrics().get("product_phase_progress", 0.0))
					prod_flow.step_production(0.25)
					var prog1: float = float(prod_flow.get_production_metrics().get("product_phase_progress", 0.0))
					ok = _assert_true(prog1 != prog0 and float(prod_flow.get_production_metrics().get("line_flow_efficiency", 0.0)) >= 0.99,
						"Con motor a 1743 RPM el flujo de producto debe avanzar (p0=%.3f, p1=%.3f)" % [prog0, prog1]) and ok
					# Verificar que los sacos NO se cargan sin camión parqueado y SÍ los cargan los operarios al parquear en la puerta enrollable derecha
					var bag_log := prod_flow.find_child("MovingBag50kg", true, false) as Node3D
					var bag_dock := prod_flow.find_child("DockCarriedBag50kg", true, false) as Node3D
					var saved_ct: float = float(prod_flow.truck_cycle_time)
					prod_flow.truck_cycle_time = 0.30 * float(prod_flow.TRUCK_CYCLE_DURATION) # u_south=0.30 y u_bay2=0.68 -> ningún camión parqueado en puerta derecha
					prod_flow.step_production(0.25)
					ok = _assert_true(bag_log != null and not bag_log.visible and bag_dock != null and not bag_dock.visible,
						"Sin camión parqueado en la puerta derecha ningún operario debe cargar sacos") and ok
					prod_flow.truck_cycle_time = 0.03 * float(prod_flow.TRUCK_CYCLE_DURATION) # u_south=0.03 -> TruckIntakeMover parqueado en puerta derecha
					var max_dock_worker_x := -999.0
					var w_dock_s := inst.find_child("WorkerDockSouth", true, false) as Node3D
					var w_log_s := inst.find_child("WorkerLogistics", true, false) as Node3D
					for _bi in range(36):
						prod_flow.step_production(0.25)
						if w_dock_s != null:
							max_dock_worker_x = maxf(max_dock_worker_x, w_dock_s.global_position.x)
						if w_log_s != null:
							max_dock_worker_x = maxf(max_dock_worker_x, w_log_s.global_position.x)
					ok = _assert_true(bag_log != null and bag_dock != null and max_dock_worker_x <= -15.50,
						"Operarios de carga deben permanecer sobre la losa firme (X <= -15.50) sin flotar fuera del muelle (max_x=%.2f)" % max_dock_worker_x) and ok
					var m_south_dock := prod_flow.find_child("TruckIntakeMover", true, false) as Node3D
					var south_rear_x := 999.0
					if m_south_dock != null:
						var tr_box_s := m_south_dock.find_child("Geom3D_447", true, false) as MeshInstance3D
						if tr_box_s != null and tr_box_s.mesh != null:
							var tb := tr_box_s.mesh.get_aabb()
							for cx in [0, 1]:
								for cy in [0, 1]:
									for cz in [0, 1]:
										var tp := tr_box_s.global_transform * (tb.position + Vector3(tb.size.x * cx, tb.size.y * cy, tb.size.z * cz))
										south_rear_x = minf(south_rear_x, tp.x)
					ok = _assert_true(south_rear_x <= -14.80 and south_rear_x >= -15.55,
						"Tractocamión acoplado en zona de carga debe acercarse al ras del muelle (rear_x=%.2f en [-15.55..-14.80])" % south_rear_x) and ok
					prod_flow.truck_cycle_time = 0.03 * float(prod_flow.TRUCK_CYCLE_DURATION)
					prod_flow.set("_bag_load_timer", 2.0)
					prod_flow.step_production(0.1)
					ok = _assert_true(bag_log != null and bag_log.visible and bag_dock != null and bag_dock.visible,
						"Con tractocamión parqueado en puerta derecha los operarios deben cargar sacos al camión") and ok
					prod_flow.truck_cycle_time = 0.30 * float(prod_flow.TRUCK_CYCLE_DURATION) # Salida del primer camión (reinicia ciclo de carga)
					prod_flow.step_production(0.25)
					prod_flow.truck_cycle_time = 0.65 * float(prod_flow.TRUCK_CYCLE_DURATION) # u_bay2=0.03 -> TruckBay2Mover parqueado en puerta derecha
					for _bi2 in range(10):
						prod_flow.step_production(0.2)
					ok = _assert_true(bag_log != null and bag_log.visible and bag_dock != null and bag_dock.visible,
						"Con TruckBay2Mover parqueado en puerta derecha los operarios deben cargar sacos al camión") and ok
					prod_flow.truck_cycle_time = 0.11 * float(prod_flow.TRUCK_CYCLE_DURATION) # TILTING_UNLOAD en TruckIntakeMover
					prod_flow.step_production(0.1)
					var m_int := prod_flow.find_child("TruckIntakeMover", true, false) as Node3D
					var t_piv := m_int.find_child("HydraulicTiltPivot", true, false) as Node3D if m_int != null else null
					ok = _assert_true(t_piv != null and absf(t_piv.rotation.x) < 0.001,
						"El semirremolque jamás debe separarse ni inclinarse sobre la quinta rueda (rot_x=%.4f)" % (t_piv.rotation.x if t_piv != null else -1.0)) and ok
					prod_flow.truck_cycle_time = saved_ct
					prod_flow.step_production(0.05)
					var sample_stream := pvis_chk.get_node_or_null("StreamBeltTrituradora") as GPUParticles3D if pvis_chk != null else null
					ok = _assert_true(sample_stream != null and sample_stream.emitting,
						"Con línea sana y activa el flujo StreamBeltTrituradora debe emitir grano") and ok
					# Inducir falla en banda_trituradora debe detener su flujo y bajar eficiencia de línea
					var sm_rep := root.get_node_or_null("/root/SimulationManager")
					if sm_rep != null and sm_rep.has_method("start_plant_machines"):
						sm_rep.start_plant_machines()
					glow_ctrl.set_hovered_machine_group("banda_trituradora")
					player._select_tool(int(glow_ctrl.get_required_tool_for_action("banda_trituradora", false)))
					player._handle_interaction()
					prod_flow.step_production(0.05)
					var eff_fault: float = float(prod_flow.get_production_metrics().get("line_flow_efficiency", 1.0))
					ok = _assert_true(sample_stream != null and not sample_stream.emitting and eff_fault < 0.99,
						"Falla en banda_trituradora debe pausar su stream de grano y reducir eficiencia (eff=%.2f)" % eff_fault) and ok
					# Intentar reparar con máquinas encendidas debe bloquearse y mostrar aviso
					var prompt_running: String = String(glow_ctrl.get_hover_selection_prompt(int(glow_ctrl.get_required_tool_for_action("banda_trituradora", true))))
					player._select_tool(int(glow_ctrl.get_required_tool_for_action("banda_trituradora", true)))
					player._handle_interaction()
					ok = _assert_true(glow_ctrl.is_machine_fault_active("banda_trituradora") and prompt_running.to_lower().contains("detén las máquinas"),
						"Reparar banda_trituradora con máquinas encendidas debe bloquearse hasta detener las máquinas (prompt=%s)" % prompt_running) and ok
					# Detener máquinas desde SimulationManager (Parar Máquinas) habilita la reparación
					if sm_rep != null and sm_rep.has_method("set_emergency_stop"):
						sm_rep.set_emergency_stop(true, "QA_TEST")
					player._handle_interaction()
					ok = _assert_true(not glow_ctrl.is_machine_fault_active("banda_trituradora"),
						"Con máquinas detenidas la reparación de banda_trituradora debe completarse") and ok
					if sm_rep != null and sm_rep.has_method("set_emergency_stop"):
						sm_rep.set_emergency_stop(false, "QA_TEST")
					glow_ctrl.set_hovered_machine_group("")
					prod_flow.set_motor_rpm(0.0, 0.0)
					prod_flow.step_production(0.05)
					ok = _assert_true(sample_stream != null and not sample_stream.emitting and is_equal_approx(float(prod_flow.get_production_metrics().get("line_flow_efficiency", 1.0)), 0.0),
						"Al detener el motor a 0 RPM todos los flujos de producto deben detenerse") and ok
					player._select_tool(1)

				# Verificar selección a distancia (>18 m fuera de líneas de seguridad) y alerta al cruzar líneas de seguridad
				ok = _assert_true(player.MAX_SELECTION_DISTANCE_M >= 25.0,
					"PlayerOperator debe permitir selección remota >= 25 m (actual=%.1f)" % player.MAX_SELECTION_DISTANCE_M) and ok
				hover_cam.global_position = Vector3(-18.69, 1.7, 48.0)
				hover_cam.look_at(Vector3(-25.98, 3.14, 29.15), Vector3.UP)
				var far_grp := String(glow_ctrl.update_hover_from_camera(hover_cam, vp_size * 0.5, player.MAX_SELECTION_DISTANCE_M, player.get_rid()))
				ok = _assert_true(far_grp == "cyclone" and glow_ctrl.get_group_state(far_grp) == "GREEN" and glow_ctrl.has_active_green_selection(),
					"Apuntado remoto a ~20 m fuera de líneas de seguridad debe activar selección verde (grp=%s)" % far_grp) and ok
				if far_grp == "cyclone":
					var sm_cy := root.get_node_or_null("/root/SimulationManager")
					var cy_fault_msg := String(glow_ctrl.induce_fault_for_hovered_machine(2))
					ok = _assert_true(glow_ctrl.is_machine_fault_active("cyclone") and cy_fault_msg != "",
						"Modo selección remoto (~20 m) debe inducir falla en ciclón sin cruzar líneas de seguridad") and ok
					# Con máquinas encendidas NO debe permitir reparar el ciclón
					glow_ctrl.induce_fault_for_hovered_machine(5)
					ok = _assert_true(glow_ctrl.is_machine_fault_active("cyclone"),
						"Reparación remota de ciclón debe bloquearse mientras las máquinas estén encendidas") and ok
					# Detener máquinas -> reparar -> reanudar
					if sm_cy != null and sm_cy.has_method("set_emergency_stop"):
						sm_cy.set_emergency_stop(true, "QA_TEST")
					glow_ctrl.induce_fault_for_hovered_machine(5) # Restaurar con Kit LOTO tras parar máquinas
					ok = _assert_true(not glow_ctrl.is_machine_fault_active("cyclone"),
						"Reparación remota (~20 m) en modo selección debe normalizar el ciclón tras detener las máquinas") and ok
					if sm_cy != null and sm_cy.has_method("set_emergency_stop"):
						sm_cy.set_emergency_stop(false, "QA_TEST")
					# Regresión de reparación física directa (perno flojo bloqueado en marcha, permitido detenido)
					var bolt_qa := inst.find_child("MechanicalBolt", true, false)
					if bolt_qa != null and bolt_qa.has_method("interact"):
						bolt_qa.set_loosened(true)
						bolt_qa.interact(3)
						var blocked_direct := bool(bolt_qa.get("is_loosened"))
						if sm_cy != null and sm_cy.has_method("set_emergency_stop"):
							sm_cy.set_emergency_stop(true, "QA_TEST")
						bolt_qa.interact(3)
						var repaired_direct := not bool(bolt_qa.get("is_loosened"))
						if sm_cy != null and sm_cy.has_method("set_emergency_stop"):
							sm_cy.set_emergency_stop(false, "QA_TEST")
						ok = _assert_true(blocked_direct and repaired_direct,
							"Reparación física directa (perno) también debe exigir detener máquinas antes de reparar") and ok
				glow_ctrl.set_hovered_machine_group("")

				var spatial_b := inst.find_child("SafetyZonesAndLighting", true, false)
				ok = _assert_true(spatial_b != null and hud_ctrl != null, "Faltan SafetyZonesAndLighting o HUDController") and ok
				if spatial_b != null and hud_ctrl != null:
					spatial_b.evaluate_player_hazard_lines(Vector3(-18.69, 0.85, 38.0)) # Pasillo verde centrado en puerta
					ok = _assert_true(not bool(spatial_b.is_player_past_safety_lines()) and not bool(hud_ctrl.is_safety_line_alert_visible()),
						"En pasillo peatonal centrado no debe mostrarse alerta de línea de seguridad") and ok
					spatial_b.evaluate_player_hazard_lines(Vector3(-25.0, 0.85, 38.0)) # Cruzando Zona 1 amarilla/negra
					ok = _assert_true(bool(spatial_b.is_player_past_safety_lines()) and bool(hud_ctrl.is_safety_line_alert_visible()),
						"Al cruzar la línea de seguridad de Zona 1 debe saltar la alerta en el HUD") and ok
					spatial_b.evaluate_player_hazard_lines(Vector3(-29.85, 0.15, 51.2)) # Cruzando Zona 8 bandas exteriores
					ok = _assert_true(bool(spatial_b.is_player_past_safety_lines()) and bool(hud_ctrl.is_safety_line_alert_visible()),
						"Al cruzar la línea de seguridad de Zona 8 (banda descarga/inclinada exterior) debe saltar la alerta") and ok
					spatial_b.evaluate_player_hazard_lines(Vector3(-36.2, 0.85, 34.9)) # Cruzando Zona 9 aire & térmica
					ok = _assert_true(bool(spatial_b.is_player_past_safety_lines()) and bool(hud_ctrl.is_safety_line_alert_visible()),
						"Al cruzar la línea de seguridad de Zona 9 (aire/horno/soplador exterior) debe saltar la alerta") and ok
					spatial_b.evaluate_player_hazard_lines(Vector3(-39.5, 0.85, 28.5)) # En acceso seguro fuera de Zona 9
					ok = _assert_true(not bool(spatial_b.is_player_past_safety_lines()) and not bool(hud_ctrl.is_safety_line_alert_visible()),
						"En la zona libre de acceso exterior junto a Zona 9 la alerta debe despejarse") and ok
					spatial_b.evaluate_player_hazard_lines(Vector3(-18.69, 0.85, 38.0)) # Al salir vuelve a seguro
					ok = _assert_true(not bool(spatial_b.is_player_past_safety_lines()) and not bool(hud_ctrl.is_safety_line_alert_visible()),
						"Al retroceder fuera de la línea de seguridad la alerta debe despejarse") and ok

				hover_cam.queue_free()

				# Regresión: Visibilidad completa de máquinas al abrir pestaña Cámaras + rueda del mouse invertida y bloqueada en tablet
				var vis_opt := inst.find_child("PlantVisibilityOptimizer", true, false)
				var tablet_root := inst.find_child("TabletRoot", true, false)
				if vis_opt != null and tablet_root != null and player != null:
					var cam_fps := player.find_child("CameraFPS", true, false) as Camera3D
					if cam_fps != null:
						cam_fps.current = true
					var saved_ppos: Vector3 = player.global_position
					player.global_position = Vector3(25.0, 1.0, 35.0) # Sector administrativo lejos de la nave
					vis_opt._setup_optimizer()
					if mill_unit_n != null:
						ok = _assert_true(not mill_unit_n.visible,
							"Fuera de pestaña Cámaras en oficinas, MotorMillUnit debe estar oculto por culling de sector") and ok
					# Abrir tablet y entrar en pestaña Cámaras (tab 1, grupo G1)
					if not tablet_root.visible:
						tablet_root.toggle_tablet()
					tablet_root._select_tab(1)
					tablet_root._select_3d_group("G1")
					var all_lod_vis := true
					for l_item in vis_opt._lod_mesh_items:
						var l_mi := l_item["node"] as MeshInstance3D
						if l_mi != null and is_instance_valid(l_mi) and (not l_mi.visible or l_mi.visibility_range_end != 0.0):
							all_lod_vis = false
							break
					ok = _assert_true(bool(vis_opt._cctv_override_active) and (mill_unit_n == null or mill_unit_n.visible) and all_lod_vis,
						"Al abrir pestaña Cámaras de la tablet todas las máquinas y mallas LOD deben quedar visibles sin descargarse") and ok

					# Rueda del mouse NO debe cambiar herramienta mientras la tablet está abierta
					player._select_tool(2)
					var ev_down := InputEventMouseButton.new()
					ev_down.button_index = MOUSE_BUTTON_WHEEL_DOWN
					ev_down.pressed = true
					var ev_up := InputEventMouseButton.new()
					ev_up.button_index = MOUSE_BUTTON_WHEEL_UP
					ev_up.pressed = true
					player._input(ev_down)
					player._input(ev_up)
					ok = _assert_true(int(player.active_tool_id) == 2,
						"Rueda del mouse dentro de la tablet NO debe cambiar el ítem equipado (actual=%d)" % int(player.active_tool_id)) and ok

					# Cerrar tablet: restaurar culling de rendimiento y validar giro invertido de rueda en juego
					tablet_root._close_tablet()
					ok = _assert_true(not bool(vis_opt._cctv_override_active),
						"Al cerrar la tablet debe desactivarse el override de visibilidad de cámaras") and ok
					player._select_tool(1)
					player._input(ev_down)
					var after_down := int(player.active_tool_id)
					player._input(ev_up)
					var after_up := int(player.active_tool_id)
					player._input(ev_up)
					var after_up_wrap := int(player.active_tool_id)
					ok = _assert_true(after_down == 2 and after_up == 1 and after_up_wrap == 5,
						"Rueda invertida: abajo debe aumentar (1->%d) y arriba disminuir (%d->%d->%d)" % [after_down, after_down, after_up, after_up_wrap]) and ok
					player._select_tool(1)
					player.global_position = saved_ppos

					# Regresión: Optimización de textura/malla de lockers (opaca POT sin ALPHA_SCISSOR, batching de sub-mallas y <=16 GlowOutlineShells)
					var watson_opt := inst.find_child("Watson Zone Slot Lockers 20-Pack", true, false)
					if watson_opt != null:
						var has_merged_mesh := watson_opt.find_child("MergedLockerMeshPanels", true, false) != null
						var has_merged_pulls := watson_opt.find_child("MergedLockerPulls", true, false) != null
						var locker_alpha_scissor_cnt := 0
						var locker_shell_cnt := 0
						for l_ch in watson_opt.find_children("*", "MeshInstance3D", true, false):
							var l_mi := l_ch as MeshInstance3D
							if l_mi == null or l_mi.mesh == null or not l_mi.visible:
								continue
							if l_mi.name == "GlowOutlineShell":
								locker_shell_cnt += 1
								continue
							for ls in range(l_mi.mesh.get_surface_count()):
								var lm := l_mi.get_active_material(ls)
								if lm is StandardMaterial3D and (lm as StandardMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
									locker_alpha_scissor_cnt += 1
						ok = _assert_true(has_merged_mesh and has_merged_pulls and locker_alpha_scissor_cnt == 0 and locker_shell_cnt <= 8,
							"Lockers deben tener malla opaca sin ALPHA_SCISSOR (%d), sub-mallas fusionadas (%s/%s) y shells reducidos (%d<=8)" % [
								locker_alpha_scissor_cnt, str(has_merged_mesh), str(has_merged_pulls), locker_shell_cnt
							]) and ok

					# Regresión: Pantalla de inducción minimalista + tips de controles y pila de notificaciones abajo-derecha sin solapamientos
					if hud_ctrl != null:
						var tips_card := hud_ctrl.find_child("ControlsTipsCard", true, false) as Control
						var notif_stack := hud_ctrl.find_child("NotificationStack", true, false) as VBoxContainer
						var b_title := hud_ctrl.find_child("BriefingTitle", true, false) as Label
						var b_greet := hud_ctrl.find_child("BriefingGreeting", true, false) as Label
						var b_yes := hud_ctrl.find_child("BtnCourseSST", true, false) as Button
						var b_no := hud_ctrl.find_child("BtnStartTour", true, false) as Button
						var b_skip := hud_ctrl.find_child("BtnSkipTutorial", true, false) as Button
						var b_skip_h := hud_ctrl.find_child("BtnSkipTutorialHUD", true, false) as Button
						hud_ctrl.show_briefing_panel("Bienvenido a Agromolinos del Valle", "¿Deseas realizar el curso SST?", true)
						ok = _assert_true(
							b_title != null and b_title.text == "Bienvenido a Agromolinos del Valle"
							and b_greet != null and b_greet.text == "¿Deseas realizar el curso SST?"
							and b_yes != null and b_yes.text == "Sí"
							and b_no != null and b_no.text == "No"
							and b_skip != null and b_skip.text == "Saltar tutorial"
							and b_skip_h != null and b_skip_h.text == "Saltar tutorial",
							"Briefing debe mostrar título/pregunta/botones limpios sin emojis ni [F9]"
						) and ok
						hud_ctrl.close_briefing_panel()
						var ev_bus := root.get_node_or_null("/root/EventBus")
						if ev_bus != null and notif_stack != null:
							ev_bus.notification_posted.emit("⚠ Prueba A", "Mensaje A", "warning")
							ev_bus.notification_posted.emit("⚡ Prueba B", "Mensaje B", "error")
							var n_cnt := notif_stack.get_child_count()
							var last_card := notif_stack.get_child(n_cnt - 1) as Control if n_cnt >= 2 else null
							var last_lbl := last_card.find_children("*", "Label", true, false)[0] as Label if last_card != null else null
							ok = _assert_true(
								tips_card != null and n_cnt >= 2 and last_lbl != null and last_lbl.text == "Prueba B",
								"Pila de notificaciones debe apilar sin emojis dejando la más actual abajo (cnt=%d, last=%s)" % [n_cnt, last_lbl.text if last_lbl != null else ""]
							) and ok
							# Regresión: Deduplicación estricta + alertas de tablet y línea de seguridad ancladas abajo-derecha (nunca arriba-centro)
							var br_dock := hud_ctrl.find_child("BottomRightAlertsDock", true, false) as Control
							var tab_leg := hud_ctrl.find_child("TabletNotifyLegend", true, false) as Control
							var sl_ban := hud_ctrl.find_child("SafetyLineAlertBanner", true, false) as Control
							var cnt_before_dup := notif_stack.get_child_count()
							ev_bus.notification_posted.emit("⚠ prueba b!", "Mensaje B duplicado", "error")
							var cnt_after_dup := notif_stack.get_child_count()
							var unread_before_sv: int = int(tablet_root.get("_unread_warning_count")) if tablet_root != null else 0
							ev_bus.safety_violation_committed.emit("QA_DEDUP", "Infracción simultánea a alerta crítica", 1.0)
							var unread_after_sv: int = int(tablet_root.get("_unread_warning_count")) if tablet_root != null else 0
							if spatial_b != null:
								var cnt_before_sl := notif_stack.get_child_count()
								spatial_b.evaluate_player_hazard_lines(Vector3(-25.0, 0.85, 38.0))
								var cnt_after_sl := notif_stack.get_child_count()
								var detail_hidden := not bool(hud_ctrl.get("_tablet_notify_detail").visible) if hud_ctrl.get("_tablet_notify_detail") != null else false
								spatial_b.evaluate_player_hazard_lines(Vector3(-18.69, 0.85, 38.0))
								ok = _assert_true(
									cnt_after_sl == cnt_before_sl and detail_hidden,
									"Cruzar línea de seguridad no debe duplicar tarjeta en NotificationStack (%d==%d) ni repetir título en TabletNotifyLegend (detail_hidden=%s)" % [cnt_after_sl, cnt_before_sl, str(detail_hidden)]
								) and ok
							var br_col := hud_ctrl.find_child("BottomRightColumn", true, false) as Control
							ok = _assert_true(
								br_col != null and br_col.anchor_left == 1.0 and br_col.anchor_top == 1.0
								and br_dock != null and br_dock.get_parent() == br_col
								and tips_card != null and tips_card.get_parent() == br_col
								and br_dock.get_index() < tips_card.get_index()
								and tab_leg != null and tab_leg.get_parent() == br_dock
								and sl_ban != null and sl_ban.get_parent() == br_dock
								and cnt_after_dup == cnt_before_dup
								and unread_after_sv == unread_before_sv,
								"BottomRightAlertsDock y ControlsTipsCard deben apilarse dentro de BottomRightColumn sin superponerse ni duplicar alertas"
							) and ok
						# Regresión: Conversación interactiva con SST (Historia, Qué hacen, Misión, Visión) solo subtítulos sin voz
						if tut_node != null:
							var saved_skip := bool(tut_node.tutorial_skipped)
							var saved_epp := bool(tut_node.epp_completed)
							tut_node.tutorial_skipped = false
							tut_node.epp_completed = false
							tut_node.target_station_id = 2
							tut_node.porteria_story_active = true
							tut_node._start_exterior_narration()
							var choices_row := hud_ctrl.find_child("DialogueChoicesRow", true, false) as HBoxContainer
							ok = _assert_true(
								choices_row != null and choices_row.visible and choices_row.get_child_count() == 5 and str(tut_node.get("_tts_voice_id")) == "",
								"Conversación SST en Portería debe mostrar 5 opciones (Historia/Qué hacen/Misión/Visión + Entrar a la empresa) solo subtítulos sin voz"
							) and ok
							var asked_ok := bool(tut_node.select_company_topic("mision"))
							tut_node._advance_conversation_beat()
							var dlg_b := hud_ctrl.find_child("DialogueBody", true, false) as Label
							ok = _assert_true(
								asked_ok and dlg_b != null and dlg_b.text.to_lower().contains("misión"),
								"Elegir tema Misión debe mostrar respuesta conversacional en subtítulos (%s)" % (dlg_b.text if dlg_b != null else "")
							) and ok
							tut_node._stop_exterior_narration()
							tut_node.porteria_story_active = false
							tut_node.tutorial_skipped = saved_skip
							tut_node.epp_completed = saved_epp
						# Regresión: Indicador superior centrado de ubicación en tiempo real (solo ubicación)
						var loc_banner := hud_ctrl.find_child("LocationTopBanner", true, false) as Control
						ok = _assert_true(
							loc_banner != null and loc_banner.visible
							and hud_ctrl.resolve_plant_location(Vector3(52.0, 0.1, 34.0)) == "Portería"
							and hud_ctrl.resolve_plant_location(Vector3(27.0, 0.4, 33.0)) == "Sala de Reuniones"
							and hud_ctrl.resolve_plant_location(Vector3(-15.5, 0.8, 47.6)) == "Vestidores EPP"
							and hud_ctrl.resolve_plant_location(Vector3(-25.5, 0.8, 41.0)) == "Zona de Molienda 10 HP"
							and hud_ctrl.resolve_plant_location(Vector3(-36.0, 0.8, 35.0)) == "Zona de Aire y Térmica",
							"LocationTopBanner centrado arriba debe resolver ubicaciones en tiempo real de toda la planta"
						) and ok
						# Regresión: Subtítulos encima de la hotbar con formato '[Nombre] ([Cargo]):' en lenguaje natural sin fugarse a NotificationStack
						var w_elec := inst.find_child("WorkerElectrician", true, false)
						var w_sst := inst.find_child("WorkerSafetyAuditor", true, false)
						var dlg_p_sub := hud_ctrl.find_child("DialoguePanel", true, false) as Control
						var dlg_s_sub := hud_ctrl.find_child("DialogueSpeaker", true, false) as Label
						var notifs_before_w: int = hud_ctrl.get_active_notification_count()
						if w_elec != null and w_elec.has_method("interact"):
							w_elec.interact(1)
						var notifs_after_w: int = hud_ctrl.get_active_notification_count()
						ok = _assert_true(
							w_elec != null and w_sst != null
							and w_elec.get_subtitle_header() == "Andrés Rojas (Técnico Electromecánico):"
							and w_sst.get_subtitle_header() == "Carlos Mendoza (Supervisor SST):"
							and dlg_p_sub != null and dlg_p_sub.visible and dlg_p_sub.offset_bottom <= -150.0
							and dlg_s_sub != null and dlg_s_sub.text == "Andrés Rojas (Técnico Electromecánico):"
							and notifs_after_w == notifs_before_w,
							"Subtítulos de trabajadores deben mostrarse encima de la hotbar como '[Nombre] ([Cargo]):' sin duplicarse en NotificationStack"
						) and ok
						# Regresión: Sin tecla E-Stop ni [ESC] en RetieCourseModal; parada de máquinas únicamente desde Tablet Industrial
						var course_m: Variant = hud_ctrl.get("_course_modal")
						var course_close_btn := course_m.get("_btn_close_only") as Button if course_m != null else null
						var ctrl_tips_body := hud_ctrl.find_child("ControlsTipsBody", true, false) as RichTextLabel
						var tab_ctrl_es := inst.find_child("TabletRoot", true, false)
						var btn_estop := tab_ctrl_es.find_child("BtnEmergencyStop", true, false) as Button if tab_ctrl_es != null else null
						var sm_ref := root.get_node_or_null("/root/SimulationManager")
						var estop_toggled_ok := false
						if btn_estop != null and sm_ref != null and sm_ref.has_method("is_emergency_stop_engaged"):
							var was_es: bool = sm_ref.is_emergency_stop_engaged()
							tab_ctrl_es._on_emergency_stop_pressed()
							var after_es: bool = sm_ref.is_emergency_stop_engaged()
							tab_ctrl_es._on_emergency_stop_pressed()
							var restored_es: bool = sm_ref.is_emergency_stop_engaged()
							estop_toggled_ok = (after_es != was_es) and (restored_es == was_es)
						var quiz_header_ok := false
						if course_m != null:
							course_m.set("_mode", "QUIZ")
							course_m.call("_refresh_view")
							var q_badge := course_m.get("_lbl_badge") as Label
							var q_title := course_m.get("_lbl_title") as Label
							quiz_header_ok = (q_badge != null and not q_badge.visible and q_title != null and q_title.text == "QUIZ")
						ok = _assert_true(
							not InputMap.has_action("e_stop")
							and course_close_btn != null and course_close_btn.text == "Posponer"
							and quiz_header_ok
							and ctrl_tips_body != null and not ctrl_tips_body.text.contains("E-Stop")
							and btn_estop != null and estop_toggled_ok,
							"Parada de máquinas debe operarse desde BtnEmergencyStop en la Tablet (sin tecla e_stop, sin [ESC] y título QUIZ limpio)"
						) and ok

		# Regresión: Cargar punto anterior (load_previous_checkpoint) limpia diálogos/opciones, resincroniza guía y desmarca visited_stations sin trabar el avance
		if tut_node != null and hud_ctrl != null and guide != null and player != null:
			# Caso 1: Retroceder desde estación 5 -> estación 4 debe desmarcar visited_stations[4], acercar al guía y permitir avanzar con E
			tut_node.set("briefing_completed", true)
			tut_node.set("porteria_story_active", false)
			tut_node.set("porteria_story_completed", true)
			tut_node.set("sst_course_active", false)
			tut_node.set("epp_completed", true)
			tut_node.visited_stations = {1: true, 2: true, 3: true, 4: true}
			tut_node.set("current_station_idx", 4)
			tut_node.set("target_station_id", 5)
			tut_node.load_previous_checkpoint()
			var dist_g4 := Vector2(guide.global_position.x - player.global_position.x, guide.global_position.z - player.global_position.z).length()
			ok = _assert_true(
				int(tut_node.target_station_id) == 4
				and not bool(tut_node.visited_stations.get(4, false))
				and not bool(guide.guide_has_target)
				and guide.can_interact()
				and dist_g4 <= 2.5
				and bool(tut_node.is_ready_for_interact_advance())
				and not bool(hud_ctrl.get("_dialogue_keep_open")),
				"Retroceder a Estación 4 debe desmarcar visited_stations[4], resincronizar guía y habilitar avance con E (target=%d, dist=%.2f, ready=%s)" % [int(tut_node.target_station_id), dist_g4, str(tut_node.is_ready_for_interact_advance())]
			) and ok
			guide.interact(1)
			ok = _assert_true(
				int(tut_node.target_station_id) == 5 and bool(tut_node.visited_stations.get(4, false)),
				"Tras retroceder a Estación 4, hablar con el Supervisor SST debe avanzar limpiamente a Estación 5 (target=%d)" % int(tut_node.target_station_id)
			) and ok

			# Caso 2: Retroceder desde Estación 3 -> Estación 2 (Vestidores) y luego -> Estación 1 (Portería) limpia opciones y permite reiniciar bienvenida
			tut_node.set("target_station_id", 3)
			tut_node.load_previous_checkpoint()
			ok = _assert_true(
				int(tut_node.target_station_id) == 2 and not bool(tut_node.epp_completed) and not bool(tut_node.visited_stations.get(2, false)) and guide.can_interact(),
				"Retroceder a Vestidores (Estación 2) debe limpiar EPP/visited_stations[2] y dejar al guía listo"
			) and ok
			tut_node.load_previous_checkpoint()
			ok = _assert_true(
				int(tut_node.target_station_id) == 2
				and not bool(tut_node.briefing_completed)
				and not bool(tut_node.porteria_story_active)
				and not bool(tut_node.sst_course_active)
				and not bool(hud_ctrl.get("_dialogue_keep_open"))
				and player.global_position.x > 45.0
				and guide.global_position.x > 45.0
				and guide.can_interact(),
				"Retroceder a Portería (Estación 1) debe reiniciar diálogos, opciones y posición de jugador/guía sin quedar bugueado"
			) and ok
			guide.interact(1)
			ok = _assert_true(
				bool(tut_node.porteria_story_active) and not bool(tut_node.is_briefing_active) and not hud_ctrl.is_briefing_visible(),
				"Tras volver a Portería, hablar con el Supervisor SST debe reiniciar primero la historia de la empresa"
			) and ok
			tut_node.load_previous_checkpoint()
			ok = _assert_true(
				not bool(tut_node.porteria_story_active) and not bool(hud_ctrl.get("_dialogue_keep_open")) and not bool(tut_node.briefing_completed),
				"Retroceder durante la historia de Portería debe limpiar botones de opciones de diálogo y reiniciar Portería limpiamente"
			) and ok

			# Regresión: Ingresar a la planta sin EPP dispara advertencia, hace que el Supervisor SST llegue al jugador y le diga que no puede estar ahí
			var lk_nepp := inst.find_child("LockerEPPStation", true, false)
			if lk_nepp != null and lk_nepp.has_method("set_epp_equipped"):
				lk_nepp.set_epp_equipped(false)
			tut_node.set("epp_completed", false)
			var safe_zones_free: bool = (
				not bool(tut_node.is_position_in_restricted_plant(Vector3(-15.9, 0.79, 47.88)))
				and not bool(tut_node.is_position_in_restricted_plant(Vector3(52.0, 0.02, 34.0)))
				and not bool(tut_node.is_position_in_restricted_plant(Vector3(27.0, 0.41, 33.1)))
				and bool(tut_node.is_position_in_restricted_plant(Vector3(-18.69, 0.85, 45.0)))
				and bool(tut_node.is_position_in_restricted_plant(Vector3(-25.0, 0.85, 38.0)))
			)
			player.global_position = Vector3(-18.69, 0.85, 45.0)
			var intr_triggered: bool = bool(tut_node.evaluate_no_epp_plant_intrusion(player.global_position))
			var sst_intercepting: bool = bool(guide.get("sst_intercept_active"))
			# Simular pasos físicos para que Carlos Mendoza llegue cara a cara al jugador y entregue la advertencia
			for _st in range(180):
				guide._physics_process(0.05)
				if bool(guide.get("sst_intercept_arrived")):
					break
			var sst_dist_after: float = Vector2(guide.global_position.x - player.global_position.x, guide.global_position.z - player.global_position.z).length()
			var dlg_body_nepp := hud_ctrl.find_child("DialogueBody", true, false) as Label
			var dlg_txt_nepp: String = dlg_body_nepp.text.to_lower() if dlg_body_nepp != null else ""
			ok = _assert_true(
				safe_zones_free and intr_triggered and sst_intercepting
				and bool(guide.get("sst_intercept_arrived")) and sst_dist_after <= 2.3
				and dlg_txt_nepp.contains("no puedes estar") and dlg_txt_nepp.contains("vestidores"),
				"Entrar a planta sin EPP debe activar advertencia y traer al Supervisor SST frente al jugador (arrived=%s, dist=%.2f, dlg=%s)" % [str(guide.get("sst_intercept_arrived")), sst_dist_after, dlg_txt_nepp]
			) and ok
			# Al salir a vestidores debe despejarse limpiamente la interceptación
			player.global_position = Vector3(-15.9, 0.79, 47.88)
			tut_node.evaluate_no_epp_plant_intrusion(player.global_position)
			ok = _assert_true(
				not bool(tut_node.is_no_epp_intrusion_active()) and not bool(guide.get("sst_intercept_active")),
				"Salir de la planta hacia Vestidores debe limpiar la interceptación SST sin bloqueo"
			) and ok

			# Regresión: Escenarios de Riesgo en Tablet deben cambiar Causas, Consecuencias y Prevención al cambiar de máquina (42 escenarios únicos)
			var tab_cat := preload("res://scripts/ui/TabletDataCatalog.gd")
			var all_risks_unique := true
			var m_count: int = tab_cat.RISK_MACHINES.size()
			for f_spec in tab_cat.RISK_FACTORS:
				var fid := str(f_spec["id"])
				var seen_c := {}
				var seen_q := {}
				var seen_p := {}
				for m_spec in tab_cat.RISK_MACHINES:
					var sc: Dictionary = tab_cat.get_risk_scenario(str(m_spec["id"]), fid)
					seen_c[str(sc.get("causes", ""))] = true
					seen_q[str(sc.get("consequences", ""))] = true
					seen_p[str(sc.get("mitigation", ""))] = true
				if seen_c.size() != m_count or seen_q.size() != m_count or seen_p.size() != m_count:
					all_risks_unique = false
					break
			var tab_riesgos := inst.find_child("TabRiesgos", true, false)
			var ui_changes_on_machine := false
			if tab_riesgos != null:
				var opts := tab_riesgos.find_children("*", "OptionButton", true, false)
				if opts.size() >= 2:
					var opt_machine := opts[0] as OptionButton
					var opt_factor := opts[1] as OptionButton
					opt_factor.select(2)
					opt_factor.item_selected.emit(2)
					opt_machine.select(0)
					opt_machine.item_selected.emit(0)
					var lbls_0: Array[String] = []
					for l in tab_riesgos.find_children("*", "Label", true, false):
						lbls_0.append((l as Label).text)
					opt_machine.select(4) # Ciclones ATEX
					opt_machine.item_selected.emit(4)
					var lbls_4: Array[String] = []
					for l in tab_riesgos.find_children("*", "Label", true, false):
						lbls_4.append((l as Label).text)
					var diff_cnt := 0
					for li in range(mini(lbls_0.size(), lbls_4.size())):
						if lbls_0[li] != lbls_4[li]:
							diff_cnt += 1
					ui_changes_on_machine = (diff_cnt >= 4) # Encabezado + Causas + Consecuencias + Prevención
			ok = _assert_true(
				all_risks_unique and ui_changes_on_machine,
				"Al cambiar de máquina en TabRiesgos deben cambiar Causas, Consecuencias y Prevención con textos específicos por equipo"
			) and ok

			# Regresión: Tarjetas de efectos fisiológicos IEC 60479-1 deben cambiar de color según probabilidad
			var tab_fis := inst.find_child("TabFisiologia", true, false)
			var fis_colors_ok := false
			if tab_fis != null:
				var sliders := tab_fis.find_children("*", "HSlider", true, false)
				var card_fib := tab_fis.find_child("EffCard_Fibrilación", true, false) as PanelContainer
				var card_tet := tab_fis.find_child("EffCard_Tetanización", true, false) as PanelContainer
				if sliders.size() >= 2 and card_fib != null and card_tet != null:
					var s_ma := sliders[0] as HSlider
					var s_ms := sliders[1] as HSlider
					s_ma.value = 0.3
					s_ms.value = 800.0
					var st_low := card_fib.get_theme_stylebox("panel") as StyleBoxFlat
					var col_low := st_low.border_color if st_low != null else Color.BLACK
					s_ma.value = 25.0
					s_ms.value = 500.0
					var st_mid := card_tet.get_theme_stylebox("panel") as StyleBoxFlat
					var col_mid := st_mid.border_color if st_mid != null else Color.BLACK
					s_ma.value = 460.0
					s_ms.value = 500.0
					var st_hi := card_fib.get_theme_stylebox("panel") as StyleBoxFlat
					var col_hi := st_hi.border_color if st_hi != null else Color.BLACK
					fis_colors_ok = (col_low.g > col_low.r) and (col_hi.r > col_hi.g) and (col_low != col_hi) and (col_mid != col_low)
			ok = _assert_true(
				fis_colors_ok,
				"Tarjetas fisiológicas IEC 60479-1 deben cambiar dinámicamente de color verde -> cian/ámbar/naranja -> rojo según probabilidad"
			) and ok

			# Regresión: Jefe de Planta (Ing. Diana Morales) debe reportar estado actual de la planta y fallas activas en vivo
			var plant_mgr := inst.find_child("WorkerPlantManager", true, false)
			var sim_mgr := root.get_node_or_null("SimulationManager")
			var hud_m := inst.find_child("HUDController", true, false)
			var glow_m := inst.find_child("InteractableGlowController", true, false)
			var bolt_m := inst.find_child("MechanicalBolt", true, false)
			if plant_mgr != null and sim_mgr != null and hud_m != null:
				if sim_mgr.has_method("set_emergency_stop"):
					sim_mgr.set_emergency_stop(false, "QA_MGR_TEST")
				if sim_mgr.has_method("start_plant_machines"):
					sim_mgr.start_plant_machines()
				if bolt_m != null and bool(bolt_m.get("is_loosened")):
					bolt_m.set_loosened(false)
				if glow_m != null:
					var pf_clean = glow_m.get("_process_faults")
					if pf_clean is Dictionary:
						(pf_clean as Dictionary).clear()
				var rep_ok: String = String(plant_mgr.interact(1))
				var spk_lbl := hud_m.find_child("DialogueSpeaker", true, false) as Label
				var body_lbl := hud_m.find_child("DialogueBody", true, false) as Label
				ok = _assert_true(
					rep_ok.contains("en operación") and rep_ok.contains("Fallas activas: Ninguna") and spk_lbl != null and spk_lbl.text.contains("Diana Morales") and body_lbl != null and body_lbl.text.contains("\n"),
					"Jefe de Planta debe reportar operación nominal sin fallas en el panel de diálogo (%s)" % rep_ok
				) and ok

				# Inducir 2 fallas (perno mecánico + proceso ciclones) y verificar reporte en vivo
				if bolt_m != null:
					bolt_m.set_loosened(true)
				if glow_m != null:
					var pf_d = glow_m.get("_process_faults")
					if pf_d is Dictionary:
						(pf_d as Dictionary)["cyclone"] = true
				var rep_faults: String = String(plant_mgr.interact(1))
				ok = _assert_true(
					rep_faults.contains("Fallas activas (2):") and rep_faults.contains("Pernos flojos") and rep_faults.contains("10 · Ciclones Clasificadores") and rep_faults.contains("Detén primero las máquinas"),
					"Jefe de Planta debe enumerar las fallas activas reales y recordar detener máquinas antes de reparar (%s)" % rep_faults
				) and ok

				# Activar parada de emergencia y confirmar reporte de estado detenido listo para reparar
				if sim_mgr.has_method("set_emergency_stop"):
					sim_mgr.set_emergency_stop(true, "QA_MGR_TEST")
				var rep_estop: String = String(plant_mgr.interact(1))
				ok = _assert_true(
					rep_estop.contains("en parada de emergencia") and rep_estop.contains("Fallas activas (2):") and rep_estop.contains("puedes reparar de forma segura"),
					"Jefe de Planta debe reportar parada de emergencia y confirmar que ya es seguro reparar (%s)" % rep_estop
				) and ok

				# Restaurar estado limpio
				if bolt_m != null:
					bolt_m.set_loosened(false)
				if glow_m != null:
					var pf_r = glow_m.get("_process_faults")
					if pf_r is Dictionary:
						(pf_r as Dictionary).erase("cyclone")
				if sim_mgr.has_method("set_emergency_stop"):
					sim_mgr.set_emergency_stop(false, "QA_MGR_TEST")

		for ap in inst.find_children("*", "AudioStreamPlayer", true, false):
			if ap is AudioStreamPlayer:
				(ap as AudioStreamPlayer).stop()
				(ap as AudioStreamPlayer).stream = null
		for ap3 in inst.find_children("*", "AudioStreamPlayer3D", true, false):
			if ap3 is AudioStreamPlayer3D:
				(ap3 as AudioStreamPlayer3D).stop()
				(ap3 as AudioStreamPlayer3D).stream = null
		IndustrialSoundSynthesizerScript.clear_cache()
		inst.free()
	IndustrialSoundSynthesizerScript.clear_cache()
	_report_qa(10, "Integración Maestra Completa de scenes/main.tscn", ok, detail)

func _measure_truck_wheel_front_rear_y(mover: Node3D) -> Vector2:
	var min_front := INF
	var min_rear := INF
	if mover == null:
		return Vector2.ZERO
	var inv_xf := mover.global_transform.affine_inverse()
	for ch in mover.find_children("*", "MeshInstance3D", true, false):
		var mi := ch as MeshInstance3D
		if mi.mesh == null:
			continue
		var xf := mi.global_transform
		for s in range(mi.mesh.get_surface_count()):
			var arr := mi.mesh.surface_get_arrays(s)
			if arr.size() <= Mesh.ARRAY_VERTEX:
				continue
			for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var wp := xf * v
				var lp := inv_xf * wp
				# En el marco local del mover, -Z es el frente y +Z es la parte trasera
				if lp.z < -1.0 and wp.y < min_front:
					min_front = wp.y
				elif lp.z > 1.0 and wp.y < min_rear:
					min_rear = wp.y
	return Vector2(0.0 if min_front == INF else min_front, 0.0 if min_rear == INF else min_rear)
