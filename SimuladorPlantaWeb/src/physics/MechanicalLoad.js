/**
 * MechanicalLoad.js - Modelo de carga mecánica del Molino de Martillos Agroindustrial.
 * Calcula el par resistente opuesto al eje del motor en función de la tasa de alimentación de granos,
 * la velocidad de giro de los martillos y la acumulación de producto molido.
 */
export class MechanicalLoad {
  constructor(eventBus) {
    this.eventBus = eventBus;

    // Tasa de alimentación de cereal (0% a 100%)
    this.feedRatePercent = 65.0; // 65% carga nominal de trabajo
    this.hopperCapacityKg = 500.0;
    this.hopperCurrentLevelKg = 380.0;
    this.flourProducedKg = 0.0;

    // Coeficientes mecánicos del molino
    this.T_idle = 6.5;         // Par resistente en vacío (Nm - fricción y aire de martillos)
    this.T_nominal_load = 34.0; // Par resistente a carga nominal al 100% de tolva (Nm)

    // Estado instantáneo
    this.currentTorque = 6.5;
    this.isClogged = false;
  }

  /**
   * Modifica la tasa de alimentación de la compuerta dosificadora.
   * @param {number} percent - Porcentaje de 0 a 100.
   */
  setFeedRate(percent) {
    this.feedRatePercent = Math.max(0.0, Math.min(100.0, percent));
  }

  /**
   * Actualiza el par mecánico opuesto al motor y el flujo másico procesado.
   * @param {number} dt - Paso de tiempo en segundos.
   * @param {number} Nr - Velocidad instantánea del motor en RPM.
   * @returns {number} Par resistente instantáneo en Nm.
   */
  update(dt, Nr) {
    if (Nr < 10.0) {
      this.currentTorque = 2.0; // Fricción estática residual
      return this.currentTorque;
    }

    const speedRatio = Math.min(1.2, Nr / 1750.0);

    // Par resistente = Par en vacío cuadrático con la velocidad + componente proporcional al grano
    const idleTorque = this.T_idle * Math.pow(speedRatio, 1.5);
    const grindingTorque = (this.feedRatePercent / 100.0) * this.T_nominal_load * speedRatio;

    this.currentTorque = idleTorque + grindingTorque;

    // Procesamiento de granos si hay velocidad de molienda efectiva (> 600 RPM)
    if (Nr > 600.0 && this.hopperCurrentLevelKg > 0.0) {
      // Tasa de molienda nominal: ~0.45 kg/s a 1750 RPM con 100% compuerta
      const millingRateKgPerSec = 0.45 * (this.feedRatePercent / 100.0) * (Nr / 1750.0);
      const deltaKg = Math.min(this.hopperCurrentLevelKg, millingRateKgPerSec * dt);

      this.hopperCurrentLevelKg -= deltaKg;
      this.flourProducedKg += deltaKg;

      // Si se agota el silo, se autoregula
      if (this.hopperCurrentLevelKg <= 0.0) {
        this.hopperCurrentLevelKg = 0.0;
        this.feedRatePercent = 0.0;
        if (this.eventBus) {
          this.eventBus.emit('ui:toast', {
            type: 'info',
            title: 'Tolva Vacía',
            message: 'Se ha procesado todo el lote de grano. El molino opera en vacío.'
          });
        }
      }
    }

    return this.currentTorque;
  }

  /**
   * Rellena la tolva de grano con una cantidad especificada.
   * @param {number} kg 
   */
  refillHopper(kg = 350.0) {
    this.hopperCurrentLevelKg = Math.min(this.hopperCapacityKg, this.hopperCurrentLevelKg + kg);
    this.feedRatePercent = 65.0;
  }
}
export default MechanicalLoad;
