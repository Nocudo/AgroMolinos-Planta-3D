/**
 * SCADAInterface.js - Panel de Telemetría e Instrumentación HMI / SCADA en DOM.
 * Despliega en tiempo real:
 * - Amperímetros trifásicos IL1, IL2, IL3 y Voltímetro 460 V
 * - Tacómetro digital de RPM y Frecuencímetro VFD con slider
 * - Par electromagnético (Nm), Potencia (kW), Factor de potencia (cos phi) y kWh
 * - Termómetro de devanado y rodamientos (°C)
 * - Vibrómetro RMS (mm/s) clasificado por Zonas ISO 10816-3 (A/B, C, D)
 * - Nivel de tolva de cereal y concentración de polvo ATEX (g/m³)
 */
export class SCADAInterface {
  constructor(eventBus) {
    this.eventBus = eventBus;
    this.domElements = {};
    this.initDOMReferences();
    this.setupControlListeners();
    this.setupToastNotifications();
  }

  initDOMReferences() {
    this.domElements = {
      // Indicadores eléctricos
      vfdStatusBadge: document.getElementById('scada-vfd-status'),
      vfdFreqDisplay: document.getElementById('val-vfd-freq'),
      vfdFreqSlider: document.getElementById('slider-vfd-freq'),
      vfdVoltageDisplay: document.getElementById('val-vfd-volt'),
      motorRpmDisplay: document.getElementById('val-motor-rpm'),
      currentL1Display: document.getElementById('val-current-l1'),
      currentL2Display: document.getElementById('val-current-l2'),
      currentL3Display: document.getElementById('val-current-l3'),
      powerActiveDisplay: document.getElementById('val-power-kw'),
      powerFactorDisplay: document.getElementById('val-power-factor'),
      energyKwhDisplay: document.getElementById('val-energy-kwh'),
      torqueElecDisplay: document.getElementById('val-torque-elec'),
      torqueLoadDisplay: document.getElementById('val-torque-load'),

      // Barras de corriente visuales
      barL1: document.getElementById('bar-current-l1'),
      barL2: document.getElementById('bar-current-l2'),
      barL3: document.getElementById('bar-current-l3'),

      // Variables térmicas y mecánicas
      tempWindingDisplay: document.getElementById('val-temp-winding'),
      tempBearingDisplay: document.getElementById('val-temp-bearing'),
      vibrationDisplay: document.getElementById('val-vibration-rms'),
      vibrationBadge: document.getElementById('badge-vibration-zone'),
      hopperLevelDisplay: document.getElementById('val-hopper-level'),
      dustConcentrationDisplay: document.getElementById('val-dust-conc'),
      flourProducedDisplay: document.getElementById('val-flour-kg'),

      // Controles SCADA
      btnStart: document.getElementById('btn-scada-start'),
      btnStop: document.getElementById('btn-scada-stop'),
      btnEStop: document.getElementById('btn-scada-estop'),
      btnReset: document.getElementById('btn-scada-reset'),
      sliderFeed: document.getElementById('slider-feed-rate'),
      valFeedRate: document.getElementById('val-feed-rate'),
      btnCyclone: document.getElementById('btn-toggle-cyclone'),

      // Retícula de interacción
      reticleTooltip: document.getElementById('hud-interaction-tooltip'),
      toastContainer: document.getElementById('hud-toast-container')
    };
  }

  setupControlListeners() {
    // Botón Start
    if (this.domElements.btnStart) {
      this.domElements.btnStart.addEventListener('click', () => {
        this.eventBus.emit('vfd:command', { action: 'start' });
      });
    }

    // Botón Stop
    if (this.domElements.btnStop) {
      this.domElements.btnStop.addEventListener('click', () => {
        this.eventBus.emit('vfd:command', { action: 'stop' });
      });
    }

    // Botón E-Stop
    if (this.domElements.btnEStop) {
      this.domElements.btnEStop.addEventListener('click', () => {
        this.eventBus.emit('safety:triggerEStop', { source: 'SCADA Web' });
      });
    }

    // Botón Reset
    if (this.domElements.btnReset) {
      this.domElements.btnReset.addEventListener('click', () => {
        this.eventBus.emit('safety:reset');
      });
    }

    // Slider de frecuencia consigna
    if (this.domElements.vfdFreqSlider) {
      this.domElements.vfdFreqSlider.addEventListener('input', (e) => {
        const val = parseFloat(e.target.value);
        this.eventBus.emit('vfd:setFrequency', val);
      });
    }

    // Slider de tasa de alimentación de granos
    if (this.domElements.sliderFeed) {
      this.domElements.sliderFeed.addEventListener('input', (e) => {
        const val = parseFloat(e.target.value);
        if (this.domElements.valFeedRate) this.domElements.valFeedRate.textContent = `${val.toFixed(0)}%`;
        this.eventBus.emit('mill:setFeedRate', val);
      });
    }

    // Botón de extractor ciclónico ATEX
    if (this.domElements.btnCyclone) {
      this.domElements.btnCyclone.addEventListener('click', () => {
        this.eventBus.emit('safety:toggleCyclone');
      });
    }

    // Escucha de tooltip de interacción del raycast
    this.eventBus.on('interaction:hover', (data) => {
      if (this.domElements.reticleTooltip) {
        if (data && data.name) {
          this.domElements.reticleTooltip.textContent = `[E] ${data.name}`;
          this.domElements.reticleTooltip.classList.add('visible');
        } else {
          this.domElements.reticleTooltip.classList.remove('visible');
        }
      }
    });
  }

  setupToastNotifications() {
    this.eventBus.on('ui:toast', (data) => {
      this.showToast(data.title, data.message, data.type || 'info');
    });
  }

  showToast(title, message, type = 'info') {
    if (!this.domElements.toastContainer) return;

    const toast = document.createElement('div');
    toast.className = `scada-toast toast-${type}`;
    toast.innerHTML = `
      <div class="toast-header">
        <span class="toast-indicator"></span>
        <strong>${title}</strong>
      </div>
      <div class="toast-body">${message}</div>
    `;

    this.domElements.toastContainer.appendChild(toast);

    // Auto-remover tras 4.5 segundos
    setTimeout(() => {
      toast.classList.add('fade-out');
      setTimeout(() => toast.remove(), 400);
    }, 4500);
  }

  /**
   * Actualiza los valores en tiempo real del panel HMI.
   * @param {object} state - Estado completo consolidado del simulador.
   */
  updateTelemetry(state) {
    const el = this.domElements;

    if (el.vfdStatusBadge) {
      el.vfdStatusBadge.textContent = state.vfdState;
      el.vfdStatusBadge.className = `status-pill status-${state.vfdState.toLowerCase()}`;
    }

    if (el.vfdFreqDisplay) el.vfdFreqDisplay.textContent = state.vfdFrequency.toFixed(1);
    if (el.vfdVoltageDisplay) el.vfdVoltageDisplay.textContent = state.vfdVoltage.toFixed(0);
    if (el.motorRpmDisplay) el.motorRpmDisplay.textContent = state.motorRPM.toFixed(0);

    // Corrientes y barras
    if (el.currentL1Display) el.currentL1Display.textContent = state.currentL1.toFixed(1);
    if (el.currentL2Display) el.currentL2Display.textContent = state.currentL2.toFixed(1);
    if (el.currentL3Display) el.currentL3Display.textContent = state.currentL3.toFixed(1);

    const maxScaleCurrent = 30.0;
    if (el.barL1) el.barL1.style.width = `${Math.min(100, (state.currentL1 / maxScaleCurrent) * 100)}%`;
    if (el.barL2) el.barL2.style.width = `${Math.min(100, (state.currentL2 / maxScaleCurrent) * 100)}%`;
    if (el.barL3) el.barL3.style.width = `${Math.min(100, (state.currentL3 / maxScaleCurrent) * 100)}%`;

    // Potencia y par
    if (el.powerActiveDisplay) el.powerActiveDisplay.textContent = state.powerActiveKW.toFixed(2);
    if (el.powerFactorDisplay) el.powerFactorDisplay.textContent = state.powerFactor.toFixed(2);
    if (el.energyKwhDisplay) el.energyKwhDisplay.textContent = state.totalEnergyKWh.toFixed(3);
    if (el.torqueElecDisplay) el.torqueElecDisplay.textContent = state.torqueElec.toFixed(1);
    if (el.torqueLoadDisplay) el.torqueLoadDisplay.textContent = state.torqueLoad.toFixed(1);

    // Térmica y vibraciones
    if (el.tempWindingDisplay) {
      el.tempWindingDisplay.textContent = state.windingTemp.toFixed(1);
      el.tempWindingDisplay.style.color = state.windingTemp >= 85 ? (state.windingTemp >= 105 ? '#ff1744' : '#ffab00') : '#00e676';
    }
    if (el.tempBearingDisplay) el.tempBearingDisplay.textContent = state.bearingTemp.toFixed(1);

    if (el.vibrationDisplay) el.vibrationDisplay.textContent = state.vibrationRMS.toFixed(2);
    if (el.vibrationBadge) {
      el.vibrationBadge.textContent = `Zona ${state.vibrationZone}`;
      el.vibrationBadge.className = `zone-badge zone-${state.vibrationZone.replace('/', '-').toLowerCase()}`;
    }

    // Tolva y polvo ATEX
    if (el.hopperLevelDisplay) el.hopperLevelDisplay.textContent = state.hopperKg.toFixed(0);
    if (el.dustConcentrationDisplay) {
      el.dustConcentrationDisplay.textContent = state.dustConcentration.toFixed(1);
      el.dustConcentrationDisplay.style.color = state.dustConcentration >= 30.0 ? '#ff1744' : '#00e676';
    }
    if (el.flourProducedDisplay) el.flourProducedDisplay.textContent = state.flourProducedKg.toFixed(1);
  }
}
export default SCADAInterface;
