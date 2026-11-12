/**
 * OperatorPPEInventory.js - Gestión de Elementos de Protección Personal (EPP) y Acceso a Planta.
 * Cumplimiento con RETIE Art. 20, OSHA 1910.132, ANSI Z87.1, ASTM F2413 y NFPA 70E.
 * Valida la dotación reglamentaria antes de franquear la esclusa de seguridad hacia la nave de producción.
 */
export class OperatorPPEInventory {
  constructor(eventBus) {
    this.eventBus = eventBus;

    // Estado de los 6 EPPs reglamentarios
    this.ppe = {
      helmet: false,   // Casco Dieléctrico Tipo I Clase E (RETIE Art. 20)
      glasses: false,  // Gafas de Seguridad Anti-Impacto (ANSI Z87.1)
      earmuffs: false, // Copas Auditivas NRR 27 dB (OSHA 1910.95)
      boots: false,    // Calzado de Seguridad Dieléctrico (ASTM F2413)
      gloves: false,   // Guantes Dieléctricos Clase 00 con protección mecánica
      suit: false      // Overol Antiestático e Ignífugo (NFPA 70E)
    };

    // Estado de inducción reglamentaria
    this.hasCompletedInduction = false;

    // Estado de la esclusa
    this.airlockDoorOpen = false;
  }

  /**
   * Equipa o desequipa un ítem de protección.
   * @param {string} itemKey - 'helmet' | 'glasses' | 'earmuffs' | 'boots' | 'gloves' | 'suit'
   */
  togglePPE(itemKey) {
    if (this.ppe.hasOwnProperty(itemKey)) {
      this.ppe[itemKey] = !this.ppe[itemKey];

      const itemNames = {
        helmet: 'Casco Dieléctrico Clase E',
        glasses: 'Gafas de Seguridad ANSI Z87.1',
        earmuffs: 'Copas Auditivas NRR 27 dB',
        boots: 'Botas Dieléctricas ASTM F2413',
        gloves: 'Guantes Dieléctricos Clase 00',
        suit: 'Overol Antiestático NFPA 70E'
      };

      const isEquipped = this.ppe[itemKey];
      if (this.eventBus) {
        this.eventBus.emit('safety:ppe', { item: itemKey, equipped: isEquipped, inventory: this.ppe });
        this.eventBus.emit('ui:toast', {
          type: isEquipped ? 'success' : 'warning',
          title: isEquipped ? 'EPP Equipado' : 'EPP Removido',
          message: `${itemNames[itemKey]} ${isEquipped ? 'colocado correctamente.' : 'retirado.'}`
        });
      }
      return isEquipped;
    }
    return false;
  }

  /**
   * Equipa todos los EPPs de golpe (función rápida para acelerar pruebas pedagógicas).
   */
  equipAll() {
    for (const key of Object.keys(this.ppe)) {
      this.ppe[key] = true;
    }
    this.hasCompletedInduction = true;
    if (this.eventBus) {
      this.eventBus.emit('safety:ppe', { item: 'all', equipped: true, inventory: this.ppe });
      this.eventBus.emit('ui:toast', {
        type: 'success',
        title: 'Dotación Completa EPP',
        message: 'Todos los EPP normativos equipados e inducción aprobada.'
      });
    }
  }

  /**
   * Completa la inducción de seguridad.
   */
  completeInduction() {
    this.hasCompletedInduction = true;
    if (this.eventBus) {
      this.eventBus.emit('safety:induction', { completed: true });
      this.eventBus.emit('ui:toast', {
        type: 'success',
        title: 'Inducción Aprobada',
        message: 'Inducción de riesgos de planta, RETIE y LOTO certificada en el terminal.'
      });
    }
  }

  /**
   * Verifica si el operario cuenta con el 100% del EPP reglamentario.
   */
  isFullyEquipped() {
    return Object.values(this.ppe).every(val => val === true);
  }

  /**
   * Lista los EPPs faltantes para advertencia al operario.
   */
  getMissingPPE() {
    const itemNames = {
      helmet: 'Casco Dieléctrico Clase E (RETIE Art. 20)',
      glasses: 'Gafas de Seguridad (ANSI Z87.1)',
      earmuffs: 'Protección Auditiva (OSHA)',
      boots: 'Botas Dieléctricas (ASTM F2413)',
      gloves: 'Guantes Dieléctricos Clase 00',
      suit: 'Overol Ignífugo (NFPA 70E)'
    };
    const missing = [];
    for (const [key, val] of Object.entries(this.ppe)) {
      if (!val) missing.push(itemNames[key]);
    }
    return missing;
  }

  /**
   * Intenta franquear la esclusa de seguridad hacia la nave de producción.
   */
  tryPassAirlock() {
    if (!this.hasCompletedInduction) {
      if (this.eventBus) {
        this.eventBus.emit('ui:toast', {
          type: 'danger',
          title: 'Acceso Denegado por Esclusa',
          message: 'Debe realizar la inducción en el terminal antes de ingresar al área de máquinas.'
        });
        this.eventBus.emit('safety:violation', {
          rule: 'Seguridad Operacional',
          desc: 'Intento de ingreso a planta sin inducción previa de riesgos.'
        });
      }
      return false;
    }

    if (!this.isFullyEquipped()) {
      const missingList = this.getMissingPPE().join(', ');
      if (this.eventBus) {
        this.eventBus.emit('ui:toast', {
          type: 'danger',
          title: 'Infracción RETIE Art. 20 / EPP Incompleto',
          message: `Faltan los siguientes elementos: ${missingList}`
        });
        this.eventBus.emit('safety:violation', {
          rule: 'RETIE Art. 20 / OSHA 1910',
          desc: `Acceso restringido: El operario no porta su dotación reglamentaria (${missingList}).`
        });
      }
      return false;
    }

    this.airlockDoorOpen = !this.airlockDoorOpen;
    if (this.eventBus) {
      this.eventBus.emit('safety:airlock', { open: this.airlockDoorOpen });
      this.eventBus.emit('ui:toast', {
        type: 'success',
        title: 'Esclusa Autorizada',
        message: this.airlockDoorOpen ? 'Validación biométrica exitosa. Puerta de esclusa abierta.' : 'Esclusa cerrada.'
      });
    }
    return true;
  }
}
export default OperatorPPEInventory;
