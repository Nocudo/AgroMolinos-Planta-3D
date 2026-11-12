/**
 * AndonVisualizer.js - Visualizador de Baliza Andon según norma ISA 18.2.
 * Estados:
 * - VERDE: Operación normal nominal.
 * - AMARILLO: Advertencia / Sobrecarga / Transición de rampa.
 * - ROJO: Disparo crítico por falla, violación de seguridad o E-Stop accionado.
 * - AZUL: Modo seguro de mantenimiento LOTO (Desenergizado y bloqueado).
 */
export class AndonVisualizer {
  constructor(eventBus, ccmPanel) {
    this.eventBus = eventBus;
    this.ccmPanel = ccmPanel;
    this.currentState = 'YELLOW'; // Inicia en amarillo (parado/espera)

    this.andonPill = document.getElementById('scada-andon-badge');
    this.setupListeners();
  }

  setupListeners() {
    this.eventBus.on('andon:state', (newState) => {
      this.setState(newState);
    });
  }

  setState(newState) {
    this.currentState = newState;

    // Actualizar torre física 3D en el tablero CCM
    if (this.ccmPanel) {
      this.ccmPanel.setAndonState(newState);
    }

    // Actualizar indicador 2D en pantalla
    if (this.andonPill) {
      const stateLabels = {
        GREEN: 'OPERACIÓN NORMAL',
        YELLOW: 'ALERTA / ESPERA',
        RED: 'PARADA / FALLA CRÍTICA',
        BLUE: 'MANTENIMIENTO LOTO'
      };

      this.andonPill.textContent = stateLabels[newState] || newState;
      this.andonPill.className = `andon-pill andon-${newState.toLowerCase()}`;
    }
  }

  /**
   * Evalúa automáticamente el estado Andon a partir de las variables de planta.
   * @param {object} state 
   */
  evaluateState(state) {
    if (state.isLotoActive) {
      if (this.currentState !== 'BLUE') this.setState('BLUE');
      return;
    }

    if (state.isEStopEngaged || state.vfdState === 'TRIPPED' || state.windingTemp >= 105.0) {
      if (this.currentState !== 'RED') this.setState('RED');
      return;
    }

    if (state.windingTemp >= 85.0 || state.vibrationZone !== 'A/B' || state.dustConcentration >= 30.0 || state.vfdState === 'RAMP_UP' || state.vfdState === 'RAMP_DOWN') {
      if (this.currentState !== 'YELLOW') this.setState('YELLOW');
      return;
    }

    if (state.vfdState === 'STEADY' && state.motorRPM > 1000.0) {
      if (this.currentState !== 'GREEN') this.setState('GREEN');
      return;
    }

    // Por defecto en reposo normal
    if (this.currentState !== 'YELLOW') this.setState('YELLOW');
  }
}
export default AndonVisualizer;
