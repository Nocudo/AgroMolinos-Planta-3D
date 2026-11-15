class_name InductionMotorKloss
extends Node

# ==============================================================================
# MODELO ELECTROMECÁNICO DINÁMICO DE MOTOR DE INDUCCIÓN JAULA DE ARDILLA 10 HP
# Implementa: Fórmula de Kloss, Control Escalar V/f, Térmica Joule y Físicas
# Proyecto Final Máquinas Eléctricas - Universidad de los Llanos (2026-2)
# ==============================================================================

# Parámetros Nominales de Placa IE3
@export var rated_power_hp: float = 10.0         # 10 HP
@export var rated_power_kw: float = 7.457        # 7.457 kW
@export var rated_voltage_ll: float = 460.0      # 460 V AC
@export var rated_frequency_hz: float = 60.0     # 60 Hz
@export var poles: int = 4                       # 4 Polos -> Ns = 1800 RPM
@export var rated_rpm: float = 1750.0            # 1750 RPM a plena carga
@export var rated_torque_nm: float = 40.7        # 40.7 N·m
@export var breakdown_torque_nm: float = 101.75  # Tmax Kloss = 2.5 * Tnom
@export var critical_slip: float = 0.15          # scr = 0.15
@export var rated_current_fla: float = 13.5      # 13.5 A
@export var locked_rotor_current_lra: float = 81.0 # 81.0 A (6x FLA)
@export var no_load_current: float = 4.5         # 4.5 A magnetizante
@export var total_inertia: float = 0.35          # J = 0.35 kg·m² (Motor + Molino)

# Estados Dinámicos en Tiempo Real
var current_voltage: float = 460.0
var current_frequency: float = 60.0
var target_frequency: float = 60.0
var rotor_speed_rpm: float = 0.0
var rotor_speed_rad_s: float = 0.0
var electrical_torque_nm: float = 0.0
var load_torque_nm: float = 0.0
var slip: float = 1.0

# Corrientes trifásicas individuales
var current_l1: float = 0.0
var current_l2: float = 0.0
var current_l3: float = 0.0
var power_factor: float = 0.85
var active_power_kw: float = 0.0

# Modelo Térmico
var ambient_temp_c: float = 25.0
var winding_temp_c: float = 25.0
var thermal_capacitance: float = 2200.0   # J/°C
var cooling_coefficient: float = 14.5     # W/°C forzada nominal
var is_cooling_blocked: bool = false

# Modelo de Vibraciones (ISO 10816-3)
var vibration_rms_mm_s: float = 0.0
var is_bolts_loosened: bool = false

# Estados de Falla Física Diegética
var is_running: bool = false
var is_e_stop_engaged: bool = false
var is_phase_l3_cut: bool = false
var is_mechanical_jammed: bool = false
var mass_flow_kg_s: float = 0.8  # Tolva de cereal

# VFD Rampa de Aceleración / Desaceleración
var vfd_accel_rate: float = 12.0 # Hz/s

func _ready() -> void:
	winding_temp_c = ambient_temp_c
	if is_inside_tree():
		var bus = get_node_or_null("/root/EventBus")
		if bus != null:
			bus.conductor_cut_event.connect(_on_conductor_cut)
			bus.conductor_repaired_event.connect(_on_conductor_repaired)
			bus.hopper_overfed.connect(_on_hopper_overfed)
			bus.breaker_changed.connect(_on_breaker_changed)
			bus.bolt_loosened.connect(_on_bolt_loosened)
			bus.ventilation_blocked.connect(_on_ventilation_blocked)
			bus.emergency_stop_triggered.connect(_on_e_stop_triggered)
			bus.emergency_stop_reset.connect(_on_e_stop_reset)

func start_motor() -> void:
	if not is_e_stop_engaged and current_voltage > 50.0:
		is_running = true

func stop_motor() -> void:
	is_running = false

func set_vfd_target_frequency(hz: float) -> void:
	target_frequency = clampf(hz, 0.0, 75.0)

func _physics_process(delta: float) -> void:
	_update_vfd_ramp(delta)
	_calculate_electromechanical_dynamics(delta)
	_calculate_thermal_dynamics(delta)
	_calculate_vibration_dynamics()
	_broadcast_telemetry()

func _update_vfd_ramp(delta: float) -> void:
	if is_running and not is_e_stop_engaged:
		if current_frequency < target_frequency:
			current_frequency = minf(target_frequency, current_frequency + vfd_accel_rate * delta)
		elif current_frequency > target_frequency:
			current_frequency = maxf(target_frequency, current_frequency - vfd_accel_rate * delta)
	else:
		current_frequency = maxf(0.0, current_frequency - vfd_accel_rate * 2.0 * delta)
		if current_frequency <= 0.5:
			is_running = false

func _calculate_electromechanical_dynamics(delta: float) -> void:
	# Velocidad síncrona según frecuencia VFD
	var sync_speed_rpm: float = (120.0 * current_frequency) / float(poles) if current_frequency > 0.1 else 0.0
	var sync_speed_rad_s: float = (sync_speed_rpm * TAU) / 60.0

	# Control Escalar V/f
	var v_applied: float = 0.0
	if current_frequency > 0.5:
		v_applied = current_voltage * minf(1.0, current_frequency / rated_frequency_hz)
	
	# Deslizamiento
	if sync_speed_rpm > 1.0:
		slip = (sync_speed_rpm - rotor_speed_rpm) / sync_speed_rpm
	else:
		slip = 1.0

	# Par resistente de la carga (Molino de Martillos + Flujo másico)
	# TL = T_fric + k_grain * flow * omega
	var t_fric: float = 4.5 # Fricción mecánica de rodamientos y aire
	var k_grain: float = 18.0
	load_torque_nm = t_fric + (k_grain * mass_flow_kg_s * (rotor_speed_rpm / rated_rpm))
	if is_mechanical_jammed:
		load_torque_nm += 120.0 # Sobrecarga masiva que excede Tmax

	# Par Electromagnético según Fórmula de Kloss
	electrical_torque_nm = 0.0
	if is_running and sync_speed_rpm > 5.0 and v_applied > 20.0:
		var v_ratio: float = v_applied / rated_voltage_ll
		var slip_clamped: float = clampf(slip, 0.0001, 1.0)
		var kloss_denominator: float = (slip_clamped / critical_slip) + (critical_slip / slip_clamped)
		var t_kloss_base: float = (2.0 * breakdown_torque_nm) / kloss_denominator
		electrical_torque_nm = t_kloss_base * (v_ratio * v_ratio)

		# Si hay corte de fase (monofasización), par medio cae ~60% y añade pulsación
		if is_phase_l3_cut:
			electrical_torque_nm *= 0.40

	# Ecuación Dinámica de Movimiento: J * d(omega)/dt = Te - TL
	var net_torque: float = electrical_torque_nm - load_torque_nm
	if not is_running:
		net_torque = -load_torque_nm * 1.5 # Freno por fricción

	var alpha: float = net_torque / total_inertia
	rotor_speed_rad_s = maxf(0.0, rotor_speed_rad_s + alpha * delta)
	rotor_speed_rpm = (rotor_speed_rad_s * 60.0) / TAU

	# Corrientes Trifásicas
	if is_running and v_applied > 20.0:
		var torque_ratio: float = clampf(absf(electrical_torque_nm) / rated_torque_nm, 0.0, 3.5)
		var base_irms: float = no_load_current + (rated_current_fla - no_load_current) * torque_ratio
		
		# En condición de rotor bloqueado
		if slip > 0.85:
			base_irms = locked_rotor_current_lra * (v_applied / rated_voltage_ll)

		# Ajuste por caída de tensión de red
		base_irms *= (rated_voltage_ll / maxf(v_applied, 50.0))

		if is_phase_l3_cut:
			# Monofasización: L3 = 0, L1 y L2 suben a sqrt(3) * Irms
			current_l3 = 0.0
			current_l1 = base_irms * 1.732
			current_l2 = base_irms * 1.732
			power_factor = 0.72
		else:
			current_l1 = base_irms * (1.0 + randf_range(-0.02, 0.02))
			current_l2 = base_irms * (1.0 + randf_range(-0.02, 0.02))
			current_l3 = base_irms * (1.0 + randf_range(-0.02, 0.02))
			power_factor = 0.85 if torque_ratio > 0.6 else 0.45
	else:
		current_l1 = 0.0
		current_l2 = 0.0
		current_l3 = 0.0
		power_factor = 0.85

	# Potencia Activa trifásica P = sqrt(3) * V * I * cos(phi)
	var irms_avg: float = (current_l1 + current_l2 + current_l3) / 3.0
	active_power_kw = (sqrt(3.0) * v_applied * irms_avg * power_factor) / 1000.0

func _calculate_thermal_dynamics(delta: float) -> void:
	# Pérdidas Joule en estator P = 3 * I^2 * R
	var r_stator: float = 0.42 # Ohmios por fase
	var p_joule: float = (current_l1 * current_l1 + current_l2 * current_l2 + current_l3 * current_l3) * r_stator
	var p_iron: float = 180.0 if is_running else 0.0
	var total_losses_w: float = p_joule + p_iron

	# Coeficiente de convección (disipación)
	var speed_ratio: float = rotor_speed_rpm / rated_rpm
	var h_effective: float = cooling_coefficient * (0.2 + 0.8 * speed_ratio)
	if is_cooling_blocked:
		h_effective *= 0.15 # 85% de reducción por trapo/obstrucción

	var heat_dissipated: float = h_effective * (winding_temp_c - ambient_temp_c)
	var dtemp: float = ((total_losses_w - heat_dissipated) / thermal_capacitance) * delta
	winding_temp_c = clampf(winding_temp_c + dtemp, ambient_temp_c, 180.0)

func _calculate_vibration_dynamics() -> void:
	if not is_running or rotor_speed_rpm < 100.0:
		vibration_rms_mm_s = 0.0
		return

	# Vibración base según ISO 10816-3 (Zona A: < 1.4 mm/s)
	var speed_factor: float = rotor_speed_rpm / rated_rpm
	var base_vib: float = 1.15 * speed_factor

	# Componente de campo inverso por monofasización (120 Hz)
	if is_phase_l3_cut:
		base_vib += 3.7 # Salto a Zona D (> 4.5 mm/s)

	# Componente por desbalance/pernos flojos (1X / 2X)
	if is_bolts_loosened:
		base_vib += 4.5 # Salto a Zona D

	# Componente por sobrecarga mecánica / rotor bloqueado
	if is_mechanical_jammed:
		base_vib += 2.2

	vibration_rms_mm_s = base_vib + randf_range(-0.08, 0.08)

func _broadcast_telemetry() -> void:
	if not is_inside_tree():
		return
	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
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
			mass_flow_kg_s
		)

# Eventos de perturbación física
func _on_conductor_cut(phase_id: String) -> void:
	if phase_id == "L3_Azul" or phase_id == "L3":
		is_phase_l3_cut = true

func _on_conductor_repaired(phase_id: String) -> void:
	if phase_id == "L3_Azul" or phase_id == "L3":
		is_phase_l3_cut = false

func _on_hopper_overfed(kg_s: float) -> void:
	mass_flow_kg_s = kg_s
	is_mechanical_jammed = (kg_s > 3.0)

func _on_breaker_changed(breaker_id: String, active: bool) -> void:
	if not active:
		# Falso contacto o apertura parcial: bajón de tensión a 340 V
		current_voltage = 340.0
	else:
		current_voltage = 460.0

func _on_bolt_loosened(bolt_id: String, loosened: bool) -> void:
	is_bolts_loosened = loosened

func _on_ventilation_blocked(blocked: bool) -> void:
	is_cooling_blocked = blocked

func _on_e_stop_triggered(_source: String) -> void:
	is_e_stop_engaged = true
	is_running = false

func _on_e_stop_reset() -> void:
	is_e_stop_engaged = false
