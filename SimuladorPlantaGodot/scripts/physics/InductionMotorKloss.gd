class_name InductionMotorKloss
extends Node

# ==============================================================================
# MODELO ELECTROMECÁNICO DINÁMICO DE MOTOR DE INDUCCIÓN JAULA DE ARDILLA 10 HP
# Implementa: Fórmula de Kloss, Control Escalar V/f + PID, Térmica Joule y Físicas
# Única Fuente de Verdad: InductionMachineDTCData.m & SKILL.md Sección 2
# ==============================================================================

# Parámetros Nominales de Placa IE3 / NEMA Premium
const VFDDriveControllerScript = preload("res://scripts/physics/VFDDriveController.gd")

@export var rated_power_hp: float = 10.0           # 10.0 HP
@export var rated_power_kw: float = 7.457          # 7.457 kW
@export var rated_voltage_ll: float = 460.0        # 460.0 V AC
@export var rated_frequency_hz: float = 60.0       # 60.0 Hz
@export var poles: int = 4                         # 4 Polos (p = 2) -> Ns = 1800 RPM
@export var rated_rpm: float = 1750.0              # 1750 RPM nominal
@export var rated_torque_nm: float = 40.7          # 40.7 N·m
@export var breakdown_torque_nm: float = 101.75    # Tmax Kloss = 2.5 * Tn
@export var critical_slip: float = 0.15            # smax = 0.15
@export var rated_current_fla: float = 13.5        # 13.5 A RMS
@export var locked_rotor_current_lra: float = 81.0 # 81.0 A RMS (6x FLA)
@export var no_load_current: float = 4.5           # 4.5 A magnetizante
@export var total_inertia: float = 0.35            # J = 0.35 kg·m² (Motor 0.045 + Molino 0.305)
@export var viscous_friction_b: float = 0.012      # B = 0.012 N·m·s/rad
@export var stator_resistance_rs: float = 0.435    # Rs = 0.435 Ohm a 75 °C
@export var rotor_resistance_rr: float = 0.816     # Rr' = 0.816 Ohm
@export var leakage_inductance_mh: float = 2.0     # Lls = Llr' = 2.0 mH
@export var magnetizing_inductance_mh: float = 69.3# Lm = 69.3 mH
@export var nominal_efficiency_pct: float = 91.7   # 91.7 % IE3

# Estados Dinámicos en Tiempo Real
var current_voltage: float = 460.0
var current_frequency: float = 60.0
var target_frequency: float = 60.0
var rotor_speed_rpm: float = 0.0
var rotor_speed_rad_s: float = 0.0
var electrical_torque_nm: float = 0.0
var load_torque_nm: float = 0.0
var slip: float = 1.0

# Corrientes trifásicas individuales y variables eléctricas
var current_l1: float = 0.0
var current_l2: float = 0.0
var current_l3: float = 0.0
var current_rms: float = 0.0
var iuf_pct: float = 0.0
var thd_pct: float = 3.2
var power_factor: float = 0.85
var active_power_kw: float = 0.0
var efficiency_pct: float = 91.7

# Modelo Térmico (Constantes exactas SKILL.md / PLAN_EJECUCION_ARGON)
var ambient_temp_c: float = 28.0
var winding_temp_c: float = 28.0
var casing_temp_c: float = 28.0
var thermal_capacitance: float = 185.0     # Cth = 185.0 J/°C
var r_th_nominal: float = 0.068            # Rth ventilador sano (°C/W)
var r_th_fan_blocked: float = 0.210        # Rth rejilla obstruida (°C/W)
var d_temp_dt: float = 0.0                 # Gradiente °C/s
var d_temp_dt_min: float = 0.0             # Gradiente °C/min (vector IA)
var is_cooling_blocked: bool = false

# Modelo de Vibraciones (ISO 10816-3)
var vibration_rms_mm_s: float = 0.0
var vibration_peak_mm_s: float = 0.0
var is_bolts_loosened: bool = false

# Estados de Falla Física Diegética
var is_running: bool = false
var is_e_stop_engaged: bool = false
var is_loto_isolated: bool = false
var is_phase_l3_cut: bool = false
var is_mechanical_jammed: bool = false
var mass_flow_kg_s: float = 0.8            # Flujo másico tolva de cereal

# Controlador VFD vs DOL integrado
var vfd_controller = null
var vfd_accel_rate: float = 12.0           # Hz/s
var is_soft_ramping: bool = false
var telemetry_emit_timer: float = 0.0

# Perturbaciones acumuladas de las 15 máquinas de la línea de proceso
var ext_load_torque_delta_nm: float = 0.0
var ext_temp_offset_c: float = 0.0
var ext_vib_delta_mm_s: float = 0.0
var ext_flow_scale: float = 1.0
var ext_aux_power_kw: float = 0.0

func _ready() -> void:
	winding_temp_c = ambient_temp_c
	casing_temp_c = ambient_temp_c
	if vfd_controller == null:
		vfd_controller = get_node_or_null("VFDDriveController")
	if vfd_controller == null:
		vfd_controller = VFDDriveControllerScript.new()
		vfd_controller.name = "VFDDriveController"
		add_child(vfd_controller)

	if is_inside_tree():
		var bus = get_node_or_null("/root/EventBus")
		if bus != null:
			if not bus.conductor_cut_event.is_connected(_on_conductor_cut):
				bus.conductor_cut_event.connect(_on_conductor_cut)
			if not bus.conductor_repaired_event.is_connected(_on_conductor_repaired):
				bus.conductor_repaired_event.connect(_on_conductor_repaired)
			if not bus.hopper_overfed.is_connected(_on_hopper_overfed):
				bus.hopper_overfed.connect(_on_hopper_overfed)
			if not bus.breaker_changed.is_connected(_on_breaker_changed):
				bus.breaker_changed.connect(_on_breaker_changed)
			if not bus.bolt_loosened.is_connected(_on_bolt_loosened):
				bus.bolt_loosened.connect(_on_bolt_loosened)
			if not bus.ventilation_blocked.is_connected(_on_ventilation_blocked):
				bus.ventilation_blocked.connect(_on_ventilation_blocked)
			if not bus.emergency_stop_triggered.is_connected(_on_e_stop_triggered):
				bus.emergency_stop_triggered.connect(_on_e_stop_triggered)
			if not bus.emergency_stop_reset.is_connected(_on_e_stop_reset):
				bus.emergency_stop_reset.connect(_on_e_stop_reset)

func start_motor() -> void:
	if not is_e_stop_engaged and not is_loto_isolated and current_voltage > 50.0:
		is_running = true
		is_soft_ramping = false
		if vfd_controller != null and vfd_controller.drive_mode == "DOL":
			current_frequency = 60.0
			target_frequency = 60.0

func start_soft_ramp(target_hz: float = 60.0, ramp_hz_s: float = 6.0) -> void:
	if is_e_stop_engaged or is_loto_isolated or current_voltage <= 50.0:
		return
	is_running = true
	is_soft_ramping = true
	current_frequency = 0.5
	rotor_speed_rad_s = 0.0
	rotor_speed_rpm = 0.0
	vfd_accel_rate = ramp_hz_s
	target_frequency = clampf(target_hz, 0.0, 75.0)
	if vfd_controller != null:
		vfd_controller.set_drive_mode("VFD")

func stop_motor() -> void:
	is_running = false
	is_soft_ramping = false

func set_vfd_target_frequency(hz: float) -> void:
	target_frequency = clampf(hz, 0.0, 75.0)
	if vfd_controller != null:
		vfd_controller.manual_target_hz = target_frequency

func set_drive_mode(mode: String) -> void:
	if vfd_controller != null:
		vfd_controller.set_drive_mode(mode)
		if mode.to_upper() == "DOL":
			target_frequency = 60.0
			current_frequency = 60.0
			is_soft_ramping = false
		else:
			target_frequency = vfd_controller.compute_optimal_frequency(mass_flow_kg_s)

func set_mass_flow(kg_s: float) -> void:
	_on_hopper_overfed(kg_s)

func set_process_fault_effects(load_delta_nm: float, temp_offset_c: float, vib_delta_mm_s: float, flow_scale: float, aux_power_kw: float) -> void:
	ext_load_torque_delta_nm = clampf(load_delta_nm, 0.0, 180.0)
	ext_temp_offset_c = clampf(temp_offset_c, 0.0, 95.0)
	ext_vib_delta_mm_s = clampf(vib_delta_mm_s, 0.0, 12.0)
	ext_flow_scale = clampf(flow_scale, 0.05, 1.0)
	ext_aux_power_kw = clampf(aux_power_kw, 0.0, 15.0)

func set_loto_isolated(isolated: bool) -> void:
	is_loto_isolated = isolated
	if isolated:
		current_voltage = 0.0
		is_running = false
	else:
		current_voltage = rated_voltage_ll

func _physics_process(delta: float) -> void:
	_update_vfd_ramp(delta)
	_calculate_electromechanical_dynamics(delta)
	_calculate_thermal_dynamics(delta)
	_calculate_vibration_dynamics()

	var energy_kpis: Dictionary = {}
	if vfd_controller != null:
		energy_kpis = vfd_controller.update_energy_metrics(delta, active_power_kw, mass_flow_kg_s, is_running, current_frequency)

	_broadcast_telemetry(delta, energy_kpis)

func _update_vfd_ramp(delta: float) -> void:
	var ramp_rate: float = vfd_accel_rate
	if vfd_controller != null:
		if vfd_controller.drive_mode == "DOL":
			target_frequency = 60.0
			ramp_rate = vfd_controller.dol_ramp_hz_s
		elif vfd_controller.auto_pid_enabled and not is_soft_ramping:
			target_frequency = vfd_controller.compute_optimal_frequency(mass_flow_kg_s)
		elif is_soft_ramping:
			ramp_rate = vfd_controller.vfd_soft_ramp_hz_s

	if is_running and not is_e_stop_engaged and not is_loto_isolated and current_voltage > 50.0:
		if current_frequency < target_frequency:
			current_frequency = minf(target_frequency, current_frequency + ramp_rate * delta)
		elif current_frequency > target_frequency:
			current_frequency = maxf(target_frequency, current_frequency - ramp_rate * delta)
		if is_soft_ramping and absf(current_frequency - target_frequency) < 0.05:
			is_soft_ramping = false
	else:
		current_frequency = maxf(0.0, current_frequency - ramp_rate * 2.0 * delta)
		if current_frequency <= 0.5:
			is_running = false

func _calculate_electromechanical_dynamics(delta: float) -> void:
	var sync_speed_rpm: float = (120.0 * current_frequency) / float(poles) if current_frequency > 0.1 else 0.0

	# Control Escalar V/f con compensación IR a baja frecuencia
	var v_applied: float = 0.0
	if current_frequency > 0.2 and current_voltage > 20.0:
		var freq_ratio: float = minf(1.0, current_frequency / rated_frequency_hz)
		var ir_boost: float = 18.0 * clampf(1.0 - (current_frequency / 15.0), 0.0, 1.0)
		v_applied = minf(current_voltage, current_voltage * freq_ratio + ir_boost)

	if sync_speed_rpm > 1.0:
		slip = (sync_speed_rpm - rotor_speed_rpm) / sync_speed_rpm
	else:
		slip = 1.0

	# Par resistente de la carga: fricción + flujo másico de cereal + perturbaciones de línea
	var speed_ratio: float = rotor_speed_rpm / rated_rpm
	var t_fric: float = 1.31
	var k_grain: float = 46.5
	load_torque_nm = t_fric + (k_grain * (mass_flow_kg_s * ext_flow_scale) * maxf(0.25, speed_ratio)) + ext_load_torque_delta_nm
	if is_mechanical_jammed:
		load_torque_nm += 120.0 # Sobrecarga masiva > Tmax (101.75 N·m)

	# Fórmula de Kloss: Te = Tmax * ((V/460)/(f/60))^2 * 2 / (s/smax + smax/s)
	electrical_torque_nm = 0.0
	if is_running and sync_speed_rpm > 5.0 and v_applied > 15.0:
		var v_pu: float = current_voltage / rated_voltage_ll
		var f_pu: float = maxf(0.15, current_frequency / rated_frequency_hz)
		var vf_scale: float = v_pu if (vfd_controller != null and vfd_controller.drive_mode == "VFD") else (v_pu / f_pu)
		var slip_clamped: float = clampf(absf(slip), 0.0005, 1.0)
		var kloss_den: float = (slip_clamped / critical_slip) + (critical_slip / slip_clamped)
		var t_kloss_base: float = (2.0 * breakdown_torque_nm) / kloss_den
		electrical_torque_nm = t_kloss_base * (vf_scale * vf_scale)
		if slip < 0.0:
			electrical_torque_nm = -electrical_torque_nm

		if is_phase_l3_cut:
			electrical_torque_nm *= 0.40 # Pérdida de par medio por monofasización

	# Ecuación de movimiento rotacional Newton-Euler: J * d(omega)/dt = Te - TL - B*omega
	var total_resisting: float = load_torque_nm + viscous_friction_b * rotor_speed_rad_s
	var net_torque: float = electrical_torque_nm - total_resisting
	if not is_running or current_voltage <= 50.0:
		net_torque = -total_resisting * 1.5

	var alpha: float = net_torque / total_inertia
	rotor_speed_rad_s = maxf(0.0, rotor_speed_rad_s + alpha * delta)
	rotor_speed_rpm = (rotor_speed_rad_s * 60.0) / TAU

	# Cálculo de Corrientes Trifásicas y Factor de Potencia
	var is_vfd_mode: bool = (vfd_controller != null and vfd_controller.drive_mode == "VFD")
	if is_running and v_applied > 15.0 and current_voltage > 50.0:
		var torque_ratio: float = clampf(absf(electrical_torque_nm) / rated_torque_nm, 0.0, 3.5)
		var base_irms: float = no_load_current + (rated_current_fla - no_load_current) * torque_ratio

		# En rotor bloqueado o arranque DOL
		if slip > 0.85 or (not is_vfd_mode and rotor_speed_rpm < 300.0):
			if is_vfd_mode and not is_mechanical_jammed:
				# Limitador electrónico VFD: arranque suave <= 1.3 * FLA (~17.5 A)
				base_irms = minf(rated_current_fla * 1.3, locked_rotor_current_lra * 0.21)
			else:
				base_irms = locked_rotor_current_lra * (current_voltage / rated_voltage_ll)

		# Compensación de corriente por caída de tensión en barraje (brownout 340 V)
		if current_voltage < rated_voltage_ll - 10.0 and not (slip > 0.85):
			base_irms *= (rated_voltage_ll / maxf(current_voltage, 100.0))

		if is_phase_l3_cut:
			# Monofasización: L3 = 0, L1 y L2 suben a sqrt(3) * I_carga (>= 23.4 A nominal)
			var demand_irms: float = maxf(base_irms, rated_current_fla * clampf(load_torque_nm / rated_torque_nm, 0.7, 1.5))
			current_l3 = 0.0
			current_l1 = demand_irms * 1.732
			current_l2 = demand_irms * 1.732
			power_factor = 0.72
			thd_pct = 13.5 + randf_range(-0.4, 0.4)
		else:
			current_l1 = base_irms * (1.0 + randf_range(-0.01, 0.01))
			current_l2 = base_irms * (1.0 + randf_range(-0.01, 0.01))
			current_l3 = base_irms * (1.0 + randf_range(-0.01, 0.01))
			power_factor = 0.85 if torque_ratio > 0.55 else 0.58
			if current_voltage < 414.0:
				thd_pct = 9.2 + randf_range(-0.3, 0.3)
			elif is_vfd_mode:
				thd_pct = 3.8 + randf_range(-0.2, 0.2)
			else:
				thd_pct = 2.6 + randf_range(-0.2, 0.2)
	else:
		current_l1 = 0.0
		current_l2 = 0.0
		current_l3 = 0.0
		power_factor = 0.85
		thd_pct = 0.0

	current_rms = (current_l1 + current_l2 + current_l3) / 3.0
	if current_rms > 0.1:
		var max_dev: float = maxf(absf(current_l1 - current_rms), maxf(absf(current_l2 - current_rms), absf(current_l3 - current_rms)))
		iuf_pct = (max_dev / current_rms) * 100.0
	else:
		iuf_pct = 0.0

	# Potencia Activa y Eficiencia (con ley de afinidad cúbica en baja frecuencia VFD)
	var freq_ratio_p: float = clampf(current_frequency / rated_frequency_hz, 0.1, 1.25)
	if is_running and current_rms > 0.1:
		var p_mech_kw: float = (electrical_torque_nm * rotor_speed_rad_s) / 1000.0
		efficiency_pct = nominal_efficiency_pct if (slip < 0.15 and not is_phase_l3_cut) else 65.0
		var p_elec_kw: float = (sqrt(3.0) * v_applied * current_rms * power_factor) / 1000.0
		if is_vfd_mode and current_frequency <= 46.0 and mass_flow_kg_s <= 0.45 and not is_mechanical_jammed:
			# Ley de afinidad cúbica en VFD a baja carga (~2.55 kW a 42 Hz)
			active_power_kw = rated_power_kw * pow(freq_ratio_p, 3.0) + ext_aux_power_kw
		else:
			active_power_kw = maxf(p_elec_kw, p_mech_kw / (efficiency_pct / 100.0)) + ext_aux_power_kw
	else:
		active_power_kw = ext_aux_power_kw * 0.25
		efficiency_pct = 0.0

func _calculate_thermal_dynamics(delta: float) -> void:
	# Pérdidas Joule en estator P = (Ia² + Ib² + Ic²) * Rs + P_iron
	var p_joule: float = (current_l1 * current_l1 + current_l2 * current_l2 + current_l3 * current_l3) * stator_resistance_rs
	var p_rotor: float = (current_rms * current_rms * 1.5) * rotor_resistance_rr if is_running else 0.0
	var p_iron: float = 180.0 if (is_running and current_voltage > 50.0) else 0.0
	var p_ext_heat: float = ext_temp_offset_c * 14.0
	var total_losses_w: float = p_joule + p_rotor * 0.5 + p_iron + p_ext_heat

	# Resistencia térmica Rth según estado de ventilación y velocidad del rotor
	var speed_ratio: float = clampf(rotor_speed_rpm / rated_rpm, 0.15, 1.0)
	var r_th_eff: float = r_th_fan_blocked if is_cooling_blocked else (r_th_nominal / (0.35 + 0.65 * speed_ratio))
	var heat_dissipated_w: float = (winding_temp_c - ambient_temp_c) / r_th_eff

	d_temp_dt = (total_losses_w - heat_dissipated_w) / thermal_capacitance
	d_temp_dt_min = clampf(d_temp_dt * 60.0, -5.0, 15.0)
	winding_temp_c = clampf(winding_temp_c + d_temp_dt * delta, ambient_temp_c, 180.0)
	casing_temp_c = lerpf(ambient_temp_c + ext_temp_offset_c * 0.35, winding_temp_c, 0.78)

func _calculate_vibration_dynamics() -> void:
	if not is_running or rotor_speed_rpm < 50.0:
		if is_mechanical_jammed and is_running and current_rms > 20.0:
			vibration_rms_mm_s = 2.85 + randf_range(-0.1, 0.1)
			vibration_peak_mm_s = vibration_rms_mm_s * 1.75
		else:
			vibration_rms_mm_s = 0.0
			vibration_peak_mm_s = 0.0
		return

	# Vibración base según ISO 10816-3 (Zona A: < 1.4 mm/s)
	var speed_factor: float = rotor_speed_rpm / rated_rpm
	var base_vib: float = 1.10 * speed_factor
	var crest_factor: float = 1.45

	if is_phase_l3_cut:
		base_vib += 3.75 # Pulsación magnética 120 Hz -> Zona D (> 4.5 mm/s)
		crest_factor = 1.80

	if is_bolts_loosened:
		base_vib += 4.55 # Soltura mecánica / excentricidad 1X & 2X -> Zona D (> 5.5 mm/s)
		crest_factor = 2.50

	if is_mechanical_jammed:
		base_vib += 2.30
		crest_factor = 1.85

	if ext_vib_delta_mm_s > 0.01:
		base_vib += ext_vib_delta_mm_s
		crest_factor = maxf(crest_factor, 1.78)

	vibration_rms_mm_s = maxf(0.0, base_vib + randf_range(-0.05, 0.05))
	vibration_peak_mm_s = vibration_rms_mm_s * crest_factor

func get_feature_vector() -> Array[float]:
	# Vector de 8 características exacto de Avance 2 (train_classifiers.m):
	# [Irms, IUF, THD, Vrms, Temp, dTemp_dt_min, VibRMS, VibPeak]
	return [
		current_rms,
		iuf_pct,
		thd_pct,
		current_voltage,
		winding_temp_c,
		d_temp_dt_min,
		vibration_rms_mm_s,
		vibration_peak_mm_s
	]

func get_telemetry_dictionary(energy_kpis: Dictionary = {}) -> Dictionary:
	var kpis := energy_kpis
	if kpis.is_empty() and vfd_controller != null:
		kpis = vfd_controller.get_energy_kpi_dict()
	return {
		"timestamp": Time.get_unix_time_from_system(),
		"asset_id": "M-101-HAMMERMILL",
		"rpm": rotor_speed_rpm,
		"slip": slip,
		"torque_nm": electrical_torque_nm,
		"load_torque_nm": load_torque_nm,
		"current_a": current_l1,
		"current_b": current_l2,
		"current_c": current_l3,
		"i_rms": current_rms,
		"iuf_pct": iuf_pct,
		"thd_pct": thd_pct,
		"voltage": current_voltage,
		"freq_hz": current_frequency,
		"temp_c": winding_temp_c,
		"casing_temp_c": casing_temp_c,
		"d_temp_dt": d_temp_dt,
		"d_temp_dt_min": d_temp_dt_min,
		"vibration_rms": vibration_rms_mm_s,
		"vibration_peak": vibration_peak_mm_s,
		"power_kw": active_power_kw,
		"power_factor": power_factor,
		"efficiency_pct": efficiency_pct,
		"flow_kg_s": mass_flow_kg_s * ext_flow_scale,
		"is_running": is_running,
		"is_phase_l3_cut": is_phase_l3_cut,
		"is_mechanical_jammed": is_mechanical_jammed,
		"is_bolts_loosened": is_bolts_loosened,
		"is_cooling_blocked": is_cooling_blocked,
		"feature_vector": get_feature_vector(),
		"energy": kpis
	}

func _broadcast_telemetry(delta: float, energy_kpis: Dictionary) -> void:
	if not is_inside_tree():
		return
	var bus = get_node_or_null("/root/EventBus")
	if bus == null:
		return
	bus.telemetry_updated.emit(
		rotor_speed_rpm,
		current_l1,
		current_l2,
		current_l3,
		current_voltage,
		current_frequency,
		winding_temp_c,
		vibration_rms_mm_s,
		active_power_kw,
		power_factor,
		mass_flow_kg_s * ext_flow_scale
	)
	telemetry_emit_timer += delta
	if telemetry_emit_timer >= 0.1: # 10 Hz para motor de IA y tablet
		telemetry_emit_timer = 0.0
		if bus.has_signal("telemetry_vector_updated"):
			bus.telemetry_vector_updated.emit(get_telemetry_dictionary(energy_kpis))

# Eventos de perturbación física diegética
func _on_conductor_cut(phase_id: String) -> void:
	if phase_id == "L3_Azul" or phase_id == "L3":
		is_phase_l3_cut = true

func _on_conductor_repaired(phase_id: String) -> void:
	if phase_id == "L3_Azul" or phase_id == "L3":
		is_phase_l3_cut = false

func _on_hopper_overfed(kg_s: float) -> void:
	mass_flow_kg_s = maxf(0.0, kg_s)
	is_mechanical_jammed = (kg_s > 3.0)
	if vfd_controller != null and vfd_controller.drive_mode == "VFD" and vfd_controller.auto_pid_enabled:
		target_frequency = vfd_controller.compute_optimal_frequency(mass_flow_kg_s)

func _on_breaker_changed(_breaker_id: String, active: bool) -> void:
	if not active:
		current_voltage = 340.0
	else:
		if not is_loto_isolated:
			current_voltage = rated_voltage_ll

func _on_bolt_loosened(_bolt_id: String, loosened: bool) -> void:
	is_bolts_loosened = loosened

func _on_ventilation_blocked(blocked: bool) -> void:
	is_cooling_blocked = blocked

func _on_e_stop_triggered(_source: String) -> void:
	is_e_stop_engaged = true
	is_running = false

func _on_e_stop_reset() -> void:
	is_e_stop_engaged = false
