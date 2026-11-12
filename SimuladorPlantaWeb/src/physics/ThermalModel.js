/**
 * ThermalModel.js - Modelo térmico y de vibración dinámica para el motor de 10 HP.
 * Modela la ecuación diferencial de 1er orden de calentamiento estatórico y rodamientos,
 * así como la severidad de vibración RMS clasificada según norma ISO 10816-3 (Máquinas Clase II).
 */
export class ThermalModel {
  constructor(eventBus) {
    this.eventBus = eventBus;

    // Parámetros térmicos de placa
    this.ambientTemperature = 25.0; // °C (temperatura ambiente en planta)
    this.windingTemperature = 25.0; // °C (temperatura devanado estatórico)
    this.bearingTemperature = 25.0; // °C (temperatura de rodamientos DE/NDE)
    this.housingTemperature = 25.0; // °C (temperatura superficial de carcasa)

    // Parámetros de capacidad y disipación térmica calibrados
    this.C_thermal = 350.0;    // Capacidad calorífica térmica equivalente (J/°C)
    this.k_cool_base = 6.8;    // Coeficiente de transferencia convectiva a velocidad nominal (W/°C)
    this.Rs = 0.62;            // Resistencia estatórica por fase (Ohms)
    this.P_iron_nom = 210.0;   // Pérdidas en el hierro a 460V/60Hz (W)

    // Umbrales térmicos según aislamiento Clase F / RETIE
    this.tempWarningThreshold = 85.0;  // Alarma amarilla preventiva (°C)
    this.tempTripThreshold = 105.0;     // Disparo térmico de protección (°C)
    this.isOverheated = false;

    // Vibración según norma ISO 10816-3 (Clase II: motores medianos)
    this.vibrationRMS = 0.6; // mm/s
    this.vibrationZone = 'A/B'; // 'A/B' | 'C' | 'D'

    // Banderas de fallas
    this.faultFanFailure = false;
    this.faultBearingDegradation = false;
  }

  /**
   * Integra la elevación de temperatura y calcula la vibración en función del estado de operación.
   * @param {number} dt - Paso de tiempo en segundos.
   * @param {number} currentRMS - Corriente del motor (A).
   * @param {number} Nr - Velocidad del rotor (RPM).
   * @param {number} voltageLL - Voltaje de línea (V).
   * @param {number} frequency - Frecuencia aplicada (Hz).
   * @param {boolean} faultPhaseLoss - Falla de fase activa.
   * @param {boolean} faultJam - Falla de sobrecarga o atasco.
   */
  update(dt, currentRMS, Nr, voltageLL, frequency, faultPhaseLoss, faultJam) {
    // 1. Cálculo de pérdidas Joule (cobre) P_cu = 3 * I^2 * Rs
    const P_cu = 3.0 * Math.pow(currentRMS, 2) * this.Rs;

    // 2. Pérdidas en el núcleo (hierro) P_fe escaladas con V y f
    let P_fe = 0.0;
    if (voltageLL > 10.0 && frequency > 1.0) {
      P_fe = this.P_iron_nom * Math.pow(voltageLL / 460.0, 2) * Math.pow(frequency / 60.0, 1.2);
    }

    // Pérdidas mecánicas básicas
    const P_mech = 40.0 * Math.pow(Nr / 1750.0, 2);
    const P_loss_total = P_cu + P_fe + P_mech;

    // 3. Coeficiente de enfriamiento convectivo dependiente del ventilador en el eje
    // Si falla el ventilador, la convección forzada se anula y queda convección natural mínima (15%)
    let fanRatio = Nr / 1800.0;
    if (this.faultFanFailure) {
      fanRatio = 0.0;
    }
    const k_cool = this.k_cool_base * (0.18 + 0.82 * Math.max(0.0, Math.min(1.2, fanRatio)));

    // 4. Ecuación diferencial térmica: C_th * dT/dt = P_loss - k_cool * (T - Tamb)
    const heatDissipated = k_cool * (this.windingTemperature - this.ambientTemperature);
    const dT = ((P_loss_total - heatDissipated) / this.C_thermal) * dt;
    this.windingTemperature = Math.max(this.ambientTemperature, this.windingTemperature + dT);

    // Temperatura de carcasa y rodamientos acoplada
    this.housingTemperature = this.ambientTemperature + 0.65 * (this.windingTemperature - this.ambientTemperature);
    let bearingFrictionHeat = 0.0;
    if (this.faultBearingDegradation && Nr > 100.0) {
      bearingFrictionHeat = 35.0 * (Nr / 1750.0); // Fricción seca en pistas de rodadura
    }
    this.bearingTemperature = this.ambientTemperature + 0.45 * (this.windingTemperature - this.ambientTemperature) + bearingFrictionHeat;

    // Verificación de disparo térmico
    if (this.windingTemperature >= this.tempTripThreshold && !this.isOverheated) {
      this.isOverheated = true;
      if (this.eventBus) {
        this.eventBus.emit('thermal:overload', {
          temperature: this.windingTemperature,
          threshold: this.tempTripThreshold
        });
      }
    } else if (this.windingTemperature < this.tempTripThreshold - 10.0 && this.isOverheated) {
      this.isOverheated = false; // Histéresis de rearme térmico
    }

    // 5. Dinámica de vibración (ISO 10816-3 para Máquinas Clase II)
    // Base nominal por balanceo residual (~0.6 - 1.2 mm/s a 1750 RPM)
    let vib = 0.4;
    if (Nr > 50.0) {
      vib += 0.8 * (Nr / 1750.0);
    }

    // Influencia de fallas en la vibración:
    if (faultPhaseLoss && Nr > 50.0) {
      vib += 2.8; // Pulsación electromagnética de par a 120 Hz
    }
    if (faultJam && Nr > 50.0) {
      vib += 1.4; // Fricción y golpeteo violento
    }
    if (this.faultBearingDegradation && Nr > 50.0) {
      vib += 3.5; // Picaduras en pista exterior / jaula rota (BPFO)
    }

    // Ruido estocástico industrial (+-0.15 mm/s)
    if (Nr > 50.0) {
      vib += (Math.random() - 0.5) * 0.3;
    }

    this.vibrationRMS = Math.max(0.1, vib);

    // Clasificación ISO 10816-3:
    // Zona A/B: < 2.3 mm/s (Satisfactoria / Buena)
    // Zona C: 2.3 - 4.5 mm/s (Alerta - Monitoreo requerido)
    // Zona D: >= 4.5 mm/s (Peligro crítico - Parada inmediata recomendada)
    if (this.vibrationRMS < 2.3) {
      this.vibrationZone = 'A/B';
    } else if (this.vibrationRMS < 4.5) {
      this.vibrationZone = 'C';
    } else {
      this.vibrationZone = 'D';
    }
  }
}
export default ThermalModel;
