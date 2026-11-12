/**
 * EventBus.js - Bus de eventos desacoplado pub/sub para el Simulador 3D de Planta Industrial.
 * Facilita la comunicación reactiva entre el núcleo de física, sistema de seguridad,
 * telemetría SCADA, renderizado 3D y audio procedural.
 */
class EventBus {
  constructor() {
    this.listeners = new Map();
  }

  /**
   * Suscribe una función callback a un evento específico.
   * @param {string} event - Nombre del evento.
   * @param {Function} callback - Función que se ejecuta al emitir el evento.
   * @returns {Function} Función para cancelar la suscripción.
   */
  on(event, callback) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event).add(callback);
    return () => this.off(event, callback);
  }

  /**
   * Desuscribe una función callback de un evento.
   * @param {string} event 
   * @param {Function} callback 
   */
  off(event, callback) {
    if (this.listeners.has(event)) {
      this.listeners.get(event).delete(callback);
      if (this.listeners.get(event).size === 0) {
        this.listeners.delete(event);
      }
    }
  }

  /**
   * Emite un evento síncrono con los datos proporcionados a todos los suscriptores.
   * @param {string} event 
   * @param {*} data 
   */
  emit(event, data) {
    if (this.listeners.has(event)) {
      for (const callback of this.listeners.get(event)) {
        try {
          callback(data);
        } catch (err) {
          console.error(`[EventBus] Error en listener para '${event}':`, err);
        }
      }
    }
  }

  /**
   * Limpia todos los suscriptores.
   */
  clear() {
    this.listeners.clear();
  }
}

// Instancia singleton para toda la aplicación
export const globalEventBus = new EventBus();
export default EventBus;
