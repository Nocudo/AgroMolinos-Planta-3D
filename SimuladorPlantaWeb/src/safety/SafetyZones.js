/**
 * SafetyZones.js - Monitoreo de zonas de proximidad y distancias de seguridad.
 * Implementa:
 * - RETIE Art. 13: Frontera de aproximación de arco eléctrico para tableros a 460 V AC.
 * - ISO 13857: Distancias de seguridad respecto a órganos mecánicos móviles (eje, poleas, martillos).
 * - NFPA 61 / ATEX: Zonas clasificadas con riesgo de nube de polvo de cereal.
 */
export class SafetyZones {
  constructor(eventBus) {
    this.eventBus = eventBus;

    // Coordenadas fijas de los equipos en la escena 3D
    this.zones = [
      {
        id: 'ccm_arc_flash',
        name: 'Zona CCM Tablero Eléctrico 460 V (RETIE Art. 13)',
        pos: { x: -6.0, y: 0.0, z: -3.0 },
        radius: 1.4,
        rule: 'RETIE Art. 13 / NFPA 70E',
        warningCooldown: 0.0
      },
      {
        id: 'mill_mechanical_hazard',
        name: 'Zona Mecánica Molino & Eje 10 HP (ISO 13857)',
        pos: { x: 2.0, y: 0.0, z: 0.0 },
        radius: 1.6,
        rule: 'ISO 13857 / OSHA 1910.212',
        warningCooldown: 0.0
      },
      {
        id: 'atex_dust_zone',
        name: 'Zona ATEX Polvo en Suspensión (NFPA 61)',
        pos: { x: 2.0, y: 0.0, z: -1.0 },
        radius: 2.5,
        rule: 'NFPA 61 / ATEX Zona 21',
        warningCooldown: 0.0
      }
    ];

    this.activeZoneId = null;
  }

  /**
   * Evalúa la posición del operario respecto a las zonas de peligro normativo.
   * @param {number} dt 
   * @param {{x: number, y: number, z: number}} playerPos 
   * @param {object} ppeInventory 
   * @param {object} safetySystem 
   * @param {number} motorRPM 
   * @param {number} busVoltage 
   */
  update(dt, playerPos, ppeInventory, safetySystem, motorRPM, busVoltage) {
    for (const zone of this.zones) {
      zone.warningCooldown = Math.max(0.0, zone.warningCooldown - dt);

      const dx = playerPos.x - zone.pos.x;
      const dz = playerPos.z - zone.pos.z;
      const dist = Math.sqrt(dx * dx + dz * dz);

      if (dist <= zone.radius) {
        this.activeZoneId = zone.id;

        // Comprobación de riesgos específicos en la zona
        if (zone.id === 'ccm_arc_flash' && zone.warningCooldown <= 0.0) {
          // Si el tablero está energizado (> 100V) y el operario no tiene guantes o overol
          const isEnergized = busVoltage > 50.0 && !safetySystem.lotoState.isFullyLockedOut;
          if (isEnergized && (!ppeInventory.ppe.gloves || !ppeInventory.ppe.suit)) {
            zone.warningCooldown = 5.0; // Avisar cada 5 segundos
            this.emitViolation(
              zone.rule,
              `Frontera de arco eléctrico cruzada en CCM (460 V). Se requiere overol ignífugo y guantes dieléctricos de clase adecuada.`
            );
          }
        }

        if (zone.id === 'mill_mechanical_hazard' && zone.warningCooldown <= 0.0) {
          // Si el motor está girando y el operario se acerca demasiado o no tiene gafas/casco
          if (motorRPM > 50.0 && (!ppeInventory.ppe.glasses || !ppeInventory.ppe.helmet || !ppeInventory.ppe.earmuffs)) {
            zone.warningCooldown = 5.0;
            this.emitViolation(
              zone.rule,
              `Aproximación peligrosa a maquinaria en movimiento (${motorRPM.toFixed(0)} RPM). Se requiere casco, gafas y protección auditiva continua.`
            );
          }
        }

        if (zone.id === 'atex_dust_zone' && zone.warningCooldown <= 0.0) {
          if (safetySystem.dustConcentration_g_m3 >= safetySystem.dustExplosiveThreshold) {
            zone.warningCooldown = 4.0;
            this.emitViolation(
              zone.rule,
              `Operario dentro de nube de polvo de cereal con riesgo de deflagración (${safetySystem.dustConcentration_g_m3.toFixed(1)} g/m³). Encender extractor ciclónico de inmediato.`
            );
          }
        }
        return zone;
      }
    }

    this.activeZoneId = null;
    return null;
  }

  emitViolation(rule, desc) {
    if (this.eventBus) {
      this.eventBus.emit('safety:violation', { rule, desc });
      this.eventBus.emit('ui:toast', {
        type: 'danger',
        title: `Violación de Seguridad: ${rule}`,
        message: desc
      });
    }
  }
}
export default SafetyZones;
