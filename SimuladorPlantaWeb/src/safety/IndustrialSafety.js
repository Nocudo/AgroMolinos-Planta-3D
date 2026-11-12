/**
 * IndustrialSafety.js - Sistema Central de Seguridad Industrial.
 * Implementa:
 * 1. Parada de Emergencia (E-Stop, Cat 0 IEC 60204-1 / ISO 13850) con rearme manual por rotación.
 * 2. Protocolo LOTO de las 5 Reglas de Oro (RETIE Art. 20, NFPA 70E, OSHA 1910.147).
 * 3. Enclavamiento de compuerta de inspección de tolva (Interlock microswitch).
 * 4. Control de atmósfera combustible de polvo de grano ATEX / NFPA 61.
 */
export class IndustrialSafety {
  constructor(eventBus) {
    this.eventBus = eventBus;

    // 1. Estado E-Stop
    this.eStopEngaged = false; // ¿Está pulsado el hongo rojo?
    this.eStopResetRequired = false;

    // 2. Estado LOTO (5 Reglas de Oro)
    this.lotoState = {
      step1_circuitOpened: false,    // Corte visible del seccionador CCM
      step2_padlockApplied: false,   // Candado de seguridad bloqueando la manija
      step2_tagApplied: false,       // Tarjeta de señalización LOTO colocada
      step3_voltageVerifiedZero: false, // Verificación con voltímetro de 0V
      step4_groundConnected: false,  // Puesta a tierra de seguridad conectada
      step5_zoneDemarcated: false,   // Señalización de zona delimitada
      isFullyLockedOut: false        // Modo mantenimiento seguro activo
    };

    // 3. Enclavamiento de compuerta (Interlock)
    this.millInspectionDoorOpen = false;

    // 4. ATEX / Polvo de granos
    this.dustExtractionCycloneActive = true;
    this.dustConcentration_g_m3 = 4.5; // Concentración base normal (< 10 g/m^3)
    this.dustExplosiveThreshold = 30.0; // Límite inferior de explosividad (MEC) NFPA 61
  }

  /**
   * Pulsa el botón tipo hongo de Parada de Emergencia.
   */
  triggerEStop(source = 'Pulsador Local') {
    this.eStopEngaged = true;
    this.eStopResetRequired = true;

    if (this.eventBus) {
      this.eventBus.emit('safety:eStop', { engaged: true, source });
      this.eventBus.emit('vfd:command', { action: 'eStop', reason: `Parada de Emergencia accionada desde ${source}` });
      this.eventBus.emit('andon:state', 'RED');
      this.eventBus.emit('ui:toast', {
        type: 'danger',
        title: '¡E-STOP ACTIVADO!',
        message: `Parada inmediata de categoría 0 ejecutada desde ${source}. Desenergización instantánea.`
      });
    }
  }

  /**
   * Gira el botón tipo hongo para desenclavarlo mecánicamente.
   */
  releaseEStop() {
    if (!this.eStopEngaged) return false;
    this.eStopEngaged = false;
    // Requiere rearme explícito
    if (this.eventBus) {
      this.eventBus.emit('safety:eStop', { engaged: false, pendingReset: true });
      this.eventBus.emit('ui:toast', {
        type: 'warning',
        title: 'E-Stop Desenclavado',
        message: 'Hongo liberado. Pulse el botón de REARME en el CCM para restablecer el circuito de seguridad.'
      });
    }
    return true;
  }

  /**
   * Pulsa el botón de rearme del circuito de seguridad.
   */
  resetSafetyCircuit() {
    if (this.eStopEngaged) {
      if (this.eventBus) {
        this.eventBus.emit('ui:toast', {
          type: 'error',
          title: 'Rearme Denegado',
          message: 'No se puede rearmar: el hongo de Parada de Emergencia sigue presionado.'
        });
      }
      return false;
    }
    this.eStopResetRequired = false;
    if (this.eventBus) {
      this.eventBus.emit('safety:resetComplete');
      this.eventBus.emit('andon:state', 'YELLOW');
      this.eventBus.emit('ui:toast', {
        type: 'success',
        title: 'Seguridad Restablecida',
        message: 'Circuito de seguridad rearmado. VFD listo para recibir consigna.'
      });
    }
    return true;
  }

  /**
   * Conmuta la compuerta de inspección del molino (Interlock).
   * @param {number} currentRPM - Velocidad del motor al intentar abrir.
   */
  toggleMillDoor(currentRPM) {
    this.millInspectionDoorOpen = !this.millInspectionDoorOpen;

    if (this.millInspectionDoorOpen) {
      if (currentRPM > 15.0) {
        // Violación crítica de seguridad: apertura de compuerta con martillos en movimiento
        this.triggerEStop('Interlock de Tolva / Molino');
        if (this.eventBus) {
          this.eventBus.emit('safety:violation', {
            rule: 'ISO 13857 / IEC 60204-1',
            desc: 'Apertura de resguardo móvil con rotor en movimiento (> 15 RPM). Disparo automático por enclavamiento.'
          });
        }
      } else {
        if (this.eventBus) {
          this.eventBus.emit('ui:toast', {
            type: 'info',
            title: 'Compuerta Molino Abierta',
            message: 'Compuerta de inspección abierta en reposo. El motor queda bloqueado para arranque.'
          });
        }
      }
    } else {
      if (this.eventBus) {
        this.eventBus.emit('ui:toast', {
          type: 'info',
          title: 'Compuerta Cerrada',
          message: 'Interlock cerrado correctamente.'
        });
      }
    }
    return this.millInspectionDoorOpen;
  }

  /**
   * Ejecución o conmutación de pasos del procedimiento LOTO.
   * @param {number} stepNumber (1 a 5)
   * @param {number} currentVoltage - Tensión medida para el paso 3.
   */
  toggleLotoStep(stepNumber, currentVoltage = 0.0) {
    switch (stepNumber) {
      case 1: // Corte visible (Seccionador principal en CCM)
        this.lotoState.step1_circuitOpened = !this.lotoState.step1_circuitOpened;
        if (!this.lotoState.step1_circuitOpened) {
          // Si cierra el seccionador, debe quitar candados y tierras antes
          this.lotoState.step2_padlockApplied = false;
          this.lotoState.step2_tagApplied = false;
          this.lotoState.step4_groundConnected = false;
          this.lotoState.isFullyLockedOut = false;
        }
        break;

      case 2: // Enclavamiento y etiquetado (Candado rojo y tarjeta)
        if (!this.lotoState.step1_circuitOpened) {
          this.emitToast('Peligro LOTO', 'No puede colocar candado sin antes abrir el seccionador (Regla de Oro #1).', 'error');
          return false;
        }
        this.lotoState.step2_padlockApplied = !this.lotoState.step2_padlockApplied;
        this.lotoState.step2_tagApplied = this.lotoState.step2_padlockApplied;
        break;

      case 3: // Verificación de ausencia de tensión
        if (!this.lotoState.step1_circuitOpened) {
          this.emitToast('Tensión Presente', `Peligro de electrocución: Hay ${currentVoltage.toFixed(0)} V en barras.`, 'danger');
          this.lotoState.step3_voltageVerifiedZero = false;
          return false;
        }
        this.lotoState.step3_voltageVerifiedZero = (currentVoltage < 5.0);
        this.emitToast('Verificación de Tensión', 'Comprobación de 0.0 V AC en barras. Ausencia de tensión certificada.', 'success');
        break;

      case 4: // Puesta a tierra y en cortocircuito
        if (!this.lotoState.step3_voltageVerifiedZero) {
          this.emitToast('Peligro de Arco', 'Debe verificar ausencia de tensión antes de instalar puestas a tierra temporales (Regla de Oro #3).', 'error');
          return false;
        }
        this.lotoState.step4_groundConnected = !this.lotoState.step4_groundConnected;
        break;

      case 5: // Delimitación y señalización de zona de trabajo
        if (!this.lotoState.step4_groundConnected) {
          this.emitToast('Paso Requerido', 'Complete la puesta a tierra antes de demarcar la zona de trabajo.', 'warning');
          return false;
        }
        this.lotoState.step5_zoneDemarcated = !this.lotoState.step5_zoneDemarcated;
        break;
    }

    // Evaluación del modo seguro total LOTO
    this.lotoState.isFullyLockedOut = (
      this.lotoState.step1_circuitOpened &&
      this.lotoState.step2_padlockApplied &&
      this.lotoState.step3_voltageVerifiedZero &&
      this.lotoState.step4_groundConnected &&
      this.lotoState.step5_zoneDemarcated
    );

    if (this.lotoState.isFullyLockedOut) {
      if (this.eventBus) {
        this.eventBus.emit('andon:state', 'BLUE');
        this.emitToast('LOTO COMPLETADO', 'Modo de Mantenimiento Eléctrico Seguro Activo (Baliza Azul encendida).', 'success');
      }
    }

    if (this.eventBus) {
      this.eventBus.emit('safety:loto', this.lotoState);
    }
    return true;
  }

  /**
   * Conmuta el extractor ciclónico de polvo de cereal.
   */
  toggleDustCyclone() {
    this.dustExtractionCycloneActive = !this.dustExtractionCycloneActive;
    this.emitToast(
      'Extractor Ciclónico',
      this.dustExtractionCycloneActive ? 'Sistema de aspiración de polvo ATEX activado.' : 'Extractor apagado. Cuidado con polvo en suspensión.',
      this.dustExtractionCycloneActive ? 'info' : 'warning'
    );
    return this.dustExtractionCycloneActive;
  }

  /**
   * Actualiza la concentración de polvo en función del trabajo del molino y el ciclón.
   * @param {number} dt 
   * @param {number} Nr - RPM del molino.
   * @param {number} feedRate - Tasa de alimentación.
   */
  updateDustConcentration(dt, Nr, feedRate) {
    if (Nr > 300.0 && feedRate > 5.0) {
      // Generación de polvo por molienda
      const generationRate = 2.5 * (feedRate / 100.0) * (Nr / 1750.0);
      this.dustConcentration_g_m3 += generationRate * dt;
    }

    // Disipación o extracción
    if (this.dustExtractionCycloneActive) {
      // El ciclón extrae rápidamente hacia la base de 4.0 g/m^3
      const exhaustRate = 4.0;
      this.dustConcentration_g_m3 = Math.max(3.5, this.dustConcentration_g_m3 - exhaustRate * dt);
    } else {
      // Decantación natural lenta
      this.dustConcentration_g_m3 = Math.max(3.5, this.dustConcentration_g_m3 - 0.2 * dt);
    }

    // Alerta de atmósfera explosiva si supera el MEC
    if (this.dustConcentration_g_m3 >= this.dustExplosiveThreshold) {
      if (this.eventBus && Math.random() < 0.05) { // Evita spam constante
        this.eventBus.emit('ui:toast', {
          type: 'danger',
          title: '¡ALERTA ATEX / NFPA 61!',
          message: `Concentración de polvo de grano crítica (${this.dustConcentration_g_m3.toFixed(1)} g/m³ >= ${this.dustExplosiveThreshold} g/m³). Peligro inminente de explosión de polvo.`
        });
      }
    }
  }

  emitToast(title, message, type = 'info') {
    if (this.eventBus) {
      this.eventBus.emit('ui:toast', { type, title, message });
    }
  }
}
export default IndustrialSafety;
