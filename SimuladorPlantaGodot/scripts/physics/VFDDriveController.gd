class_name VFDDriveController
extends Node

# ==============================================================================
# CONTROLADOR DE VARIADOR DE FRECUENCIA (VFD V/f + PID) VS ARRANQUE DIRECTO (DOL)
# Optimización Energética & Sostenibilidad Industria 5.0 (Sección 11 SKILL.md)
# ==============================================================================

@export_enum("VFD", "DOL") var drive_mode: String = "VFD"
@export var auto_pid_enabled: bool = true
@export var manual_target_hz: float = 60.0
@export var vfd_soft_ramp_hz_s: float = 6.0   # Rampa de 10 s (0 -> 60 Hz)
@export var dol_ramp_hz_s: float = 180.0      # Arranque directo DOL instantáneo

# KPIs de Eficiencia y Sostenibilidad (UPME Colombia)
const SPECIFIC_ENERGY_DOL_KWH_TON: float = 10.50
const SPECIFIC_ENERGY_VFD_KWH_TON: float = 7.52
const CO2_EMISSION_FACTOR_UPME: float = 0.164 # kg CO2e / kWh (SIN Colombia)
const ANNUAL_TONS_BASELINE: float = 1000.0

var current_target_hz: float = 60.0
var current_specific_kwh_ton: float = SPECIFIC_ENERGY_VFD_KWH_TON
var accumulated_kwh_vfd: float = 0.0
var accumulated_kwh_dol_baseline: float = 0.0
var energy_saved_kwh: float = 0.0
var co2_avoided_kg: float = 0.0
var projected_annual_kwh_saved: float = 2980.0
var projected_annual_co2_kg: float = 488.72
var savings_pct: float = 28.38

func _ready() -> void:
	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("drive_mode_changed"):
		bus.drive_mode_changed.emit(drive_mode, auto_pid_enabled)

func set_drive_mode(mode: String) -> void:
	var upper_mode := mode.to_upper()
	if upper_mode != "VFD" and upper_mode != "DOL":
		return
	drive_mode = upper_mode
	if drive_mode == "DOL":
		current_target_hz = 60.0
		current_specific_kwh_ton = SPECIFIC_ENERGY_DOL_KWH_TON
		savings_pct = 0.0
	else:
		savings_pct = ((SPECIFIC_ENERGY_DOL_KWH_TON - SPECIFIC_ENERGY_VFD_KWH_TON) / SPECIFIC_ENERGY_DOL_KWH_TON) * 100.0
	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		if bus.has_signal("drive_mode_changed"):
			bus.drive_mode_changed.emit(drive_mode, auto_pid_enabled)
		if bus.has_signal("notification_posted"):
			var msg := "Accionamiento VFD V/f + PID activo (Ahorro ~28.4% kWh/ton)." if drive_mode == "VFD" else "Arranque Directo DOL a 60 Hz fijos (Pico 81 A, sin modulación)."
			bus.notification_posted.emit("MODO DE ACCIONAMIENTO: " + drive_mode, msg, "info" if drive_mode == "VFD" else "warning")

func toggle_drive_mode() -> String:
	set_drive_mode("DOL" if drive_mode == "VFD" else "VFD")
	return drive_mode

func set_auto_pid(enabled: bool) -> void:
	auto_pid_enabled = enabled
	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("drive_mode_changed"):
		bus.drive_mode_changed.emit(drive_mode, auto_pid_enabled)

func compute_optimal_frequency(mass_flow_kg_s: float) -> float:
	if drive_mode == "DOL":
		current_target_hz = 60.0
		return 60.0
	if not auto_pid_enabled:
		current_target_hz = clampf(manual_target_hz, 20.0, 60.0)
		return current_target_hz
	# Lazo PID de demanda según flujo másico de tolva:
	# Baja carga (<= 0.35 kg/s) -> 42.0 Hz (1260 RPM) por ley de afinidad cúbica
	# Carga nominal (>= 0.80 kg/s) -> 60.0 Hz (1750 RPM)
	if mass_flow_kg_s <= 0.35:
		current_target_hz = 42.0
	elif mass_flow_kg_s >= 0.80:
		current_target_hz = 60.0
	else:
		var t: float = (mass_flow_kg_s - 0.35) / (0.80 - 0.35)
		current_target_hz = lerpf(42.0, 60.0, t)
	return current_target_hz

func get_ramp_rate_hz_s() -> float:
	return vfd_soft_ramp_hz_s if drive_mode == "VFD" else dol_ramp_hz_s

func update_energy_metrics(delta: float, active_power_kw: float, mass_flow_kg_s: float, is_running: bool, current_freq_hz: float) -> Dictionary:
	if is_running and active_power_kw > 0.01:
		var dt_hours: float = delta / 3600.0
		var tons_per_hour: float = maxf(mass_flow_kg_s * 3.6, 0.25)
		var measured_kwh_ton: float = active_power_kw / tons_per_hour

		if drive_mode == "VFD":
			# Consumo específico real ponderado hacia la curva optimizada VFD (7.52 kWh/ton)
			var freq_ratio: float = clampf(current_freq_hz / 60.0, 0.5, 1.0)
			var affinity_factor: float = pow(freq_ratio, 3.0)
			current_specific_kwh_ton = clampf(lerpf(SPECIFIC_ENERGY_VFD_KWH_TON, measured_kwh_ton, 0.25) * (0.75 + 0.25 * affinity_factor), 4.5, SPECIFIC_ENERGY_DOL_KWH_TON)
			accumulated_kwh_vfd += active_power_kw * dt_hours
			# Línea base DOL equivalente para el mismo tonelaje procesado
			var dol_equiv_kw: float = active_power_kw * (SPECIFIC_ENERGY_DOL_KWH_TON / maxf(current_specific_kwh_ton, 1.0))
			accumulated_kwh_dol_baseline += dol_equiv_kw * dt_hours
			savings_pct = ((SPECIFIC_ENERGY_DOL_KWH_TON - current_specific_kwh_ton) / SPECIFIC_ENERGY_DOL_KWH_TON) * 100.0
		else:
			current_specific_kwh_ton = maxf(SPECIFIC_ENERGY_DOL_KWH_TON, measured_kwh_ton * 0.95)
			accumulated_kwh_vfd += active_power_kw * dt_hours
			accumulated_kwh_dol_baseline += active_power_kw * dt_hours
			savings_pct = 0.0

		energy_saved_kwh = maxf(0.0, accumulated_kwh_dol_baseline - accumulated_kwh_vfd)
		co2_avoided_kg = energy_saved_kwh * CO2_EMISSION_FACTOR_UPME
		var delta_spec: float = maxf(0.0, SPECIFIC_ENERGY_DOL_KWH_TON - current_specific_kwh_ton)
		projected_annual_kwh_saved = ANNUAL_TONS_BASELINE * delta_spec
		projected_annual_co2_kg = projected_annual_kwh_saved * CO2_EMISSION_FACTOR_UPME

	return get_energy_kpi_dict()

func get_energy_kpi_dict() -> Dictionary:
	return {
		"drive_mode": drive_mode,
		"auto_pid": auto_pid_enabled,
		"target_hz": current_target_hz,
		"specific_kwh_ton": current_specific_kwh_ton,
		"dol_baseline_kwh_ton": SPECIFIC_ENERGY_DOL_KWH_TON,
		"vfd_nominal_kwh_ton": SPECIFIC_ENERGY_VFD_KWH_TON,
		"vfd_baseline_kwh_ton": SPECIFIC_ENERGY_VFD_KWH_TON,
		"upme_co2_factor": CO2_EMISSION_FACTOR_UPME,
		"savings_pct": savings_pct,
		"accumulated_kwh": accumulated_kwh_vfd,
		"energy_saved_kwh": energy_saved_kwh,
		"co2_avoided_kg": co2_avoided_kg,
		"projected_annual_kwh_saved": projected_annual_kwh_saved,
		"projected_annual_co2_kg": projected_annual_co2_kg
	}
