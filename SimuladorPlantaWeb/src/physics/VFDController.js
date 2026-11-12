/**
 * VFDController.js - Variador de Frecuencia (VFD) con control escalar V/f constante.
 * Incluye rampas de aceleración/deceleración, compensación IR de baja frecuencia (torque boost),
 * protecciones de sobrecorriente instantánea, rearme y acumulador de energía en kWh.
 */
export class VFDController {
  constructor(eventBus) {
    this.eventBus = eventBus;

    // Parámetros de diseño
    this.V_nom = 460.0; // Tensión nominal (V)
    this.f_nom = 60.0;  // Frecuencia base (Hz)
    this.v_f_ratio = this.V_nom / this.f_nom; // 7.667 V/Hz
    this.boostVoltage = 25.0; // Boost a baja velocidad para vencer resistencia de estator

    // Configuración de rampas
    this.accelTime = 6.0;  // Segundos de 0 a 60 Hz
    this.decelTime = 8.0;  // Segundos de 60 a 0 Hz
    this.accelRate = this.f_nom / this.accelTime; // ~10 Hz/s
    this.decelRate = this.f_nom / this.decelTime; // ~7.5 Hz/s

    // Estados operativos: 'STOPPED' | 'RAMP_UP' | 'STEADY' | 'RAMP_DOWN' | 'TRIPPED'
    this.state = 'STOPPED';
    this.tripReason = null;

    // Variables de control
    this.targetFrequency = 60.0; // Frecuencia consigna (Hz)
    this.outputFrequency = 0.0;  // Frecuencia instantánea entregada (Hz)
    this.outputVoltage = 0.0;    // Tensión instantánea eficaz entregada (V)
    this.runCommand = false;     // Orden de marcha desde panel

    // Protecciones
    this.maxOvercurrentThreshold = 30.0; // Amperes instantáneos (~220% FLA)
    this.overcurrentTimer = 0.0;

    // Métricas
    this.totalEnergyKWh = 0.0;
  }

  /**
   * Ordena encender el motor siguiendo la rampa de aceleración.
   */
  start() {
    if (this.state === 'TRIPPED') {
      if (this.eventBus) {
        this.eventBus.emit('ui:toast', {
          type: 'error',
          title: 'VFD Bloqueado',
          message: `El variador está en fallo (${this.tripReason}). Debe rearmarse antes de arrancar.`
        });
      }
      return false;
    }
    this.runCommand = true;
    return true;
  }

  /**
   * Ordena parada operacional siguiendo la rampa de deceleración controlada.
   */
  stop() {
    this.runCommand = false;
  }

  /**
   * Parada inmediata de emergencia (desconexión instantánea de pulsos PWM).
   * @param {string} reason 
   */
  emergencyStop(reason = 'E-Stop Activado') {
    this.runCommand = false;
    this.outputFrequency = 0.0;
    this.outputVoltage = 0.0;
    this.state = 'TRIPPED';
    this.tripReason = reason;

    if (this.eventBus) {
      this.eventBus.emit('vfd:tripped', { reason: this.tripReason });
      this.eventBus.emit('ui:toast', {
        type: 'danger',
        title: 'DISPARO DE EMERGENCIA',
        message: `VFD deshabilitado: ${reason}`
      });
    }
  }

  /**
   * Intenta rearmar el VFD si las condiciones de seguridad lo permiten.
   */
  resetFault() {
    if (this.state === 'TRIPPED') {
      this.state = 'STOPPED';
      this.tripReason = null;
      this.overcurrentTimer = 0.0;
      if (this.eventBus) {
        this.eventBus.emit('ui:toast', {
          type: 'info',
          title: 'VFD Rearmado',
          message: 'Condición de fallo restablecida. Listo para operar.'
        });
      }
      return true;
    }
    return false;
  }

  /**
   * Establece una nueva frecuencia consigna entre 0 y 60 Hz.
   * @param {number} freq 
   */
  setTargetFrequency(freq) {
    this.targetFrequency = Math.max(0.0, Math.min(60.0, freq));
  }

  /**
   * Actualiza el lazo de control del VFD.
   * @param {number} dt - Paso de tiempo en segundos.
   * @param {number} motorCurrentRMS - Corriente actual medida del motor (A).
   * @param {number} motorPowerKW - Potencia activa medida (kW).
   */
  update(dt, motorCurrentRMS, motorPowerKW) {
    // Verificación de protección por sobrecorriente
    if (this.state !== 'TRIPPED' && motorCurrentRMS > this.maxOvercurrentThreshold) {
      this.overcurrentTimer += dt;
      if (this.overcurrentTimer > 0.4) { // Tolerancia de 400ms a picos
        this.emergencyStop(`Disparo por Sobrecorriente (${motorCurrentRMS.toFixed(1)} A > ${this.maxOvercurrentThreshold} A)`);
        return;
      }
    } else {
      this.overcurrentTimer = Math.max(0, this.overcurrentTimer - dt);
    }

    if (this.state === 'TRIPPED') {
      this.outputFrequency = 0.0;
      this.outputVoltage = 0.0;
      return;
    }

    // Lógica de rampa
    const currentTarget = this.runCommand ? this.targetFrequency : 0.0;

    if (this.outputFrequency < currentTarget) {
      // Acelerando
      this.state = 'RAMP_UP';
      this.outputFrequency = Math.min(currentTarget, this.outputFrequency + this.accelRate * dt);
    } else if (this.outputFrequency > currentTarget) {
      // Frenando
      this.state = 'RAMP_DOWN';
      this.outputFrequency = Math.max(currentTarget, this.outputFrequency - this.decelRate * dt);
    } else {
      // En régimen
      this.state = (this.outputFrequency > 0.1) ? 'STEADY' : 'STOPPED';
    }

    // Cálculo de voltaje escalar V/f con boost
    if (this.outputFrequency > 0.1) {
      // V = V_boost + ratio * f
      const calculatedV = this.boostVoltage * (1.0 - (this.outputFrequency / this.f_nom)) + (this.v_f_ratio * this.outputFrequency);
      this.outputVoltage = Math.min(this.V_nom, calculatedV);
    } else {
      this.outputVoltage = 0.0;
    }

    // Acumulador de energía en kWh (P * dt / 3600)
    if (motorPowerKW > 0) {
      this.totalEnergyKWh += (motorPowerKW * dt) / 3600.0;
    }
  }
}
export default VFDController;
