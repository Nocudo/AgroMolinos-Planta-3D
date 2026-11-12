/**
 * InductionMotor.js - Modelo electromagnético del motor trifásico de inducción jaula de ardilla (10 HP, 460 V).
 * Implementa la ecuación de par de Kloss, cálculo de deslizamiento, corrientes de fase L1, L2, L3,
 * factor de potencia, potencia activa/reactiva y ecuación de movimiento rotacional (J * dw/dt = Te - Tl).
 */
export class InductionMotor {
  constructor(options = {}) {
    // Parámetros de placa (Nameplate specs)
    this.P_nom_hp = 10.0;
    this.P_nom_watts = 7457.0; // 10 HP
    this.V_nom_LL = 460.0;     // Voltaje línea a línea nominal (V)
    this.f_nom = 60.0;         // Frecuencia nominal (Hz)
    this.poles = 4;            // Polos magnéticos
    this.N_nom = 1750.0;       // RPM nominales a plena carga
    this.I_FLA = 13.5;         // Corriente nominal a plena carga (Amperes)
    this.cosPhi_nom = 0.85;    // Factor de potencia a plena carga
    this.eta_nom = 0.917;      // Eficiencia nominal IE3 (91.7%)

    // Parámetros derivados
    this.N_sync_base = (120.0 * this.f_nom) / this.poles; // 1800 RPM
    this.omega_sync_base = (2.0 * Math.PI * this.N_sync_base) / 60.0; // 188.49 rad/s
    this.omega_nom = (2.0 * Math.PI * this.N_nom) / 60.0; // 183.26 rad/s
    this.T_nom = this.P_nom_watts / this.omega_nom; // ~40.69 Nm

    // Parámetros de Kloss
    this.s_nom = (this.N_sync_base - this.N_nom) / this.N_sync_base; // ~0.0278
    this.s_max = 0.15; // Deslizamiento de par máximo (Breakdown slip)
    this.T_max_ratio = 2.4;
    this.T_max = this.T_max_ratio * this.T_nom; // ~97.66 Nm

    // Dinámica mecánica del rotor
    this.J = 0.085; // Momento de inercia equivalente motor + molino (kg*m^2)
    this.B_friction = 0.012; // Coeficiente de fricción viscosa mecánica (Nm*s/rad)

    // Variables de estado dinámico
    this.omega_m = 0.0; // Velocidad mecánica en rad/s
    this.Nr = 0.0;      // Velocidad mecánica en RPM
    this.angle = 0.0;   // Posición angular del eje (radianes para animación 3D)

    // Variables eléctricas
    this.appliedVoltageLL = 0.0;
    this.appliedFrequency = 0.0;
    this.slip = 0.0;
    this.T_elec = 0.0;
    this.T_load = 0.0;
    this.currentRMS = 0.0;
    this.currentL1 = 0.0;
    this.currentL2 = 0.0;
    this.currentL3 = 0.0;
    this.powerActiveKW = 0.0;
    this.powerReactiveKVAR = 0.0;
    this.powerFactor = 0.85;

    // Banderas de fallas inducidas
    this.faultPhaseLossL3 = false;
    this.faultMechanicalJam = false;
    this.faultBearingDegradation = false;
  }

  /**
   * Actualiza el modelo electromagnético y mecánico un paso de tiempo dt.
   * @param {number} dt - Intervalo de tiempo en segundos (típicamente ~0.016s para 60fps).
   * @param {number} voltageLL - Voltaje eficaz línea a línea suministrado por el VFD (V).
   * @param {number} frequency - Frecuencia eléctrica suministrada por el VFD (Hz).
   * @param {number} externalLoadTorque - Par resistente opuesto por el molino de martillos (Nm).
   */
  update(dt, voltageLL, frequency, externalLoadTorque) {
    this.appliedVoltageLL = Math.max(0, voltageLL);
    this.appliedFrequency = Math.max(0, frequency);
    this.T_load = externalLoadTorque;

    if (this.faultMechanicalJam) {
      // Atasco mecánico: carga resistente se dispara al doble del par máximo
      this.T_load += this.T_max * 1.8;
    }

    // Si no hay frecuencia o voltaje suficiente, el motor no genera par electromagnético
    if (this.appliedFrequency < 0.5 || this.appliedVoltageLL < 5.0) {
      this.T_elec = 0.0;
      this.slip = 1.0;
      this.currentRMS = 0.0;
      this.currentL1 = 0.0;
      this.currentL2 = 0.0;
      this.currentL3 = 0.0;
      this.powerActiveKW = 0.0;
      this.powerReactiveKVAR = 0.0;

      // Desaceleración por fricción y carga resistente
      const totalOpposingTorque = this.B_friction * this.omega_m + (this.omega_m > 0 ? this.T_load : 0);
      const dOmega = (-totalOpposingTorque / this.J) * dt;
      this.omega_m = Math.max(0, this.omega_m + dOmega);
      this.Nr = (this.omega_m * 60.0) / (2.0 * Math.PI);
      this.angle = (this.angle + this.omega_m * dt) % (2.0 * Math.PI);
      return;
    }

    // Velocidad sincrónica instantánea dependiente de la frecuencia del VFD
    const N_sync = (120.0 * this.appliedFrequency) / this.poles;
    const omega_sync = (2.0 * Math.PI * N_sync) / 60.0;

    // Deslizamiento s = (omega_sync - omega_m) / omega_sync
    if (omega_sync > 0.001) {
      this.slip = (omega_sync - this.omega_m) / omega_sync;
    } else {
      this.slip = 1.0;
    }

    // Relación de tensión respecto a la nominal para escalar el par
    const v_ratio = Math.min(1.2, this.appliedVoltageLL / this.V_nom_LL);

    // Ecuación de Kloss para el par electromagnético
    // Te = [2 * Tmax / (s/smax + smax/s)] * (V / Vnom)^2
    let s_effective = this.slip;
    if (Math.abs(s_effective) < 0.0001) {
      s_effective = (s_effective >= 0 ? 0.0001 : -0.0001);
    }

    const klossDenominator = (s_effective / this.s_max) + (this.s_max / s_effective);
    this.T_elec = ((2.0 * this.T_max) / klossDenominator) * Math.pow(v_ratio, 2);

    // Si hay pérdida de fase en L3, el par medio cae aproximadamente a la mitad y pulsa
    if (this.faultPhaseLossL3) {
      this.T_elec *= 0.45;
    }

    // Dinámica del rotor: J * d(omega_m)/dt = Te - Tl - B * omega_m
    const netTorque = this.T_elec - this.T_load - (this.B_friction * this.omega_m);
    const dOmega = (netTorque / this.J) * dt;
    this.omega_m = Math.max(0, this.omega_m + dOmega);
    this.Nr = (this.omega_m * 60.0) / (2.0 * Math.PI);
    this.angle = (this.angle + this.omega_m * dt) % (2.0 * Math.PI);

    // Cálculo de corrientes eficaces
    // Componente de magnetización (en cuadratura, ~35% de FLA a V nominal)
    const I_mag = 4.7 * (this.appliedVoltageLL / this.V_nom_LL);
    // Componente de carga activa
    const loadRatio = Math.max(0, Math.min(2.5, this.T_elec / this.T_nom));
    const I_active = this.I_FLA * loadRatio * (this.appliedFrequency / this.f_nom);
    
    // Corriente total equivalente RMS por fase
    this.currentRMS = Math.sqrt(Math.pow(I_mag, 2) + Math.pow(I_active, 2));

    // Factor de potencia
    if (this.currentRMS > 0.1) {
      this.powerFactor = Math.min(0.92, Math.max(0.15, I_active / this.currentRMS));
    } else {
      this.powerFactor = 0.2;
    }

    // Asignación de corrientes trifásicas considerando posibles fallas
    if (this.faultPhaseLossL3) {
      this.currentL1 = this.currentRMS * 1.65; // Sobrecarga severa en fases sanas
      this.currentL2 = this.currentRMS * 1.65;
      this.currentL3 = 0.0; // Fase abierta
    } else {
      // Simulación de leve desbalance natural industrial (< 2%)
      this.currentL1 = this.currentRMS;
      this.currentL2 = this.currentRMS * 0.99;
      this.currentL3 = this.currentRMS * 1.01;
    }

    // Potencia activa y reactiva trifásica
    // P = sqrt(3) * V_LL * I_RMS * cos(phi)
    this.powerActiveKW = (Math.sqrt(3.0) * this.appliedVoltageLL * this.currentRMS * this.powerFactor) / 1000.0;
    const sinPhi = Math.sqrt(Math.max(0, 1.0 - Math.pow(this.powerFactor, 2)));
    this.powerReactiveKVAR = (Math.sqrt(3.0) * this.appliedVoltageLL * this.currentRMS * sinPhi) / 1000.0;
  }
}
export default InductionMotor;
