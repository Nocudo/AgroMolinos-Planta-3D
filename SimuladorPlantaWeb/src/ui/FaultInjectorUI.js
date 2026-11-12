/**
 * FaultInjectorUI.js - Tablet Industrial de Control de Riesgos e Inyección de Fallas [Tab].
 * Permite al profesor/estudiante:
 * 1. Inducir 4 fallas electromecánicas críticas:
 *    - Atasco mecánico / sobrecarga severa en martillos
 *    - Pérdida de una fase de alimentación (L3)
 *    - Degradación y falla de rodamientos (Zona D ISO 10816-3)
 *    - Falla del ventilador de refrigeración forzada en eje
 * 2. Gestionar la dotación de EPP reglamentario y la inducción de seguridad.
 * 3. Ejecutar y validar las 5 Reglas de Oro LOTO paso a paso.
 * 4. Consultar el marco normativo RETIE / ISO / OSHA / NFPA.
 */
export class FaultInjectorUI {
  constructor(eventBus, safetySystem, ppeInventory, motor, thermal) {
    this.eventBus = eventBus;
    this.safetySystem = safetySystem;
    this.ppeInventory = ppeInventory;
    this.motor = motor;
    this.thermal = thermal;

    this.isOpen = false;
    this.modal = document.getElementById('risk-tablet-modal');
    this.btnOpen = document.getElementById('btn-open-tablet');
    this.btnClose = document.getElementById('btn-close-tablet');

    this.setupListeners();
    this.setupTabNavigation();
    this.setupFaultToggles();
    this.setupPPEToggles();
  }

  setupListeners() {
    // Tecla [Tab] para abrir/cerrar la tablet
    window.addEventListener('keydown', (e) => {
      if (e.code === 'Tab') {
        e.preventDefault(); // Evitar cambiar el foco del navegador
        this.toggleTablet();
      }
    });

    if (this.btnOpen) {
      this.btnOpen.addEventListener('click', () => this.toggleTablet(true));
    }

    if (this.btnClose) {
      this.btnClose.addEventListener('click', () => this.toggleTablet(false));
    }
  }

  toggleTablet(forceState = null) {
    this.isOpen = (forceState !== null) ? forceState : !this.isOpen;

    if (this.modal) {
      if (this.isOpen) {
        this.modal.classList.add('active');
        document.exitPointerLock(); // Liberar cursor para operar la tablet
        this.updatePpeCheckboxes();
      } else {
        this.modal.classList.remove('active');
      }
    }
  }

  setupTabNavigation() {
    const tabButtons = document.querySelectorAll('.tablet-tab-btn');
    const tabPanes = document.querySelectorAll('.tablet-tab-pane');

    tabButtons.forEach(btn => {
      btn.addEventListener('click', () => {
        const targetTab = btn.getAttribute('data-tab');

        tabButtons.forEach(b => b.classList.remove('active'));
        tabPanes.forEach(p => p.classList.remove('active'));

        btn.classList.add('active');
        const activePane = document.getElementById(`tab-pane-${targetTab}`);
        if (activePane) activePane.classList.add('active');
      });
    });
  }

  setupFaultToggles() {
    // Switch 1: Atasco mecánico
    const swJam = document.getElementById('sw-fault-jam');
    if (swJam) {
      swJam.addEventListener('change', (e) => {
        this.motor.faultMechanicalJam = e.target.checked;
        this.emitFaultChange('Atasco Mecánico en Molino', e.target.checked);
      });
    }

    // Switch 2: Pérdida de Fase L3
    const swPhase = document.getElementById('sw-fault-phase');
    if (swPhase) {
      swPhase.addEventListener('change', (e) => {
        this.motor.faultPhaseLossL3 = e.target.checked;
        this.emitFaultChange('Pérdida de Fase L3 (Monofásico)', e.target.checked);
      });
    }

    // Switch 3: Falla de Rodamientos
    const swBearing = document.getElementById('sw-fault-bearing');
    if (swBearing) {
      swBearing.addEventListener('change', (e) => {
        this.motor.faultBearingDegradation = e.target.checked;
        this.thermal.faultBearingDegradation = e.target.checked;
        this.emitFaultChange('Degradación de Rodamientos (ISO 10816-3 Zona D)', e.target.checked);
      });
    }

    // Switch 4: Falla de Ventilación
    const swFan = document.getElementById('sw-fault-fan');
    if (swFan) {
      swFan.addEventListener('change', (e) => {
        this.thermal.faultFanFailure = e.target.checked;
        this.emitFaultChange('Falla de Ventilación Forzada', e.target.checked);
      });
    }

    // Botón para restablecer todas las fallas
    const btnResetAll = document.getElementById('btn-reset-faults');
    if (btnResetAll) {
      btnResetAll.addEventListener('click', () => {
        if (swJam) swJam.checked = false;
        if (swPhase) swPhase.checked = false;
        if (swBearing) swBearing.checked = false;
        if (swFan) swFan.checked = false;

        this.motor.faultMechanicalJam = false;
        this.motor.faultPhaseLossL3 = false;
        this.motor.faultBearingDegradation = false;
        this.thermal.faultBearingDegradation = false;
        this.thermal.faultFanFailure = false;

        this.eventBus.emit('ui:toast', {
          type: 'success',
          title: 'Fallas Restablecidas',
          message: 'Condición nominal de motor y planta restaurada.'
        });
      });
    }
  }

  setupPPEToggles() {
    const ppeCheckboxes = document.querySelectorAll('.ppe-checkbox');
    ppeCheckboxes.forEach(cb => {
      cb.addEventListener('change', () => {
        const itemKey = cb.getAttribute('data-item');
        this.ppeInventory.togglePPE(itemKey);
      });
    });

    // Botón Equipar Todo
    const btnEquipAll = document.getElementById('btn-equip-all-ppe');
    if (btnEquipAll) {
      btnEquipAll.addEventListener('click', () => {
        this.ppeInventory.equipAll();
        this.updatePpeCheckboxes();
      });
    }

    // Botón Inducción
    const btnInduction = document.getElementById('btn-pass-induction');
    if (btnInduction) {
      btnInduction.addEventListener('click', () => {
        this.ppeInventory.completeInduction();
      });
    }

    // Botón Franquear Esclusa
    const btnAirlock = document.getElementById('btn-pass-airlock');
    if (btnAirlock) {
      btnAirlock.addEventListener('click', () => {
        this.ppeInventory.tryPassAirlock();
      });
    }
  }

  updatePpeCheckboxes() {
    for (const [key, val] of Object.entries(this.ppeInventory.ppe)) {
      const cb = document.querySelector(`.ppe-checkbox[data-item="${key}"]`);
      if (cb) cb.checked = val;
    }
  }

  emitFaultChange(faultName, isActive) {
    if (this.eventBus) {
      this.eventBus.emit('fault:injected', { name: faultName, active: isActive });
      this.eventBus.emit('ui:toast', {
        type: isActive ? 'warning' : 'info',
        title: isActive ? 'Falla Inyectada' : 'Falla Desactivada',
        message: `${faultName} ha sido ${isActive ? 'activada' : 'desactivada'}.`
      });
    }
  }
}
export default FaultInjectorUI;
