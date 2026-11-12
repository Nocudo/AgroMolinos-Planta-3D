import * as THREE from 'three';

/**
 * DustParticleCloud.js - Simulación de nube de partículas de polvo de cereal (ATEX / NFPA 61).
 * Modela la dispersión de partículas finas combustibles generadas por el molino de martillos,
 * su acumulación cuando el extractor ciclónico está apagado y su aspiración hacia el ducto exterior.
 */
export class DustParticleCloud {
  constructor(scene) {
    this.scene = scene;
    this.particleCount = 1200;
    this.particles = null;
    this.positions = null;
    this.velocities = [];

    // Foco de generación en el molino de martillos
    this.millOrigin = new THREE.Vector3(2.0, 1.2, 0.0);
    this.cycloneDuctPos = new THREE.Vector3(2.8, 2.5, 0.8);
  }

  build() {
    const geometry = new THREE.BufferGeometry();
    this.positions = new Float32Array(this.particleCount * 3);

    for (let i = 0; i < this.particleCount; i++) {
      this.resetParticle(i, true);
    }

    geometry.setAttribute('position', new THREE.BufferAttribute(this.positions, 3));

    // Material de partículas de polvo de maíz (amarillo pálido / harina)
    this.material = new THREE.PointsMaterial({
      color: 0xffe082,
      size: 0.06,
      transparent: true,
      opacity: 0.35,
      blending: THREE.NormalBlending,
      depthWrite: false
    });

    this.particles = new THREE.Points(geometry, this.material);
    this.scene.add(this.particles);
  }

  resetParticle(index, initialRandom = false) {
    const i3 = index * 3;
    // Dispersión aleatoria alrededor de la tolva y cámara del molino
    const spread = initialRandom ? 2.5 : 0.6;
    this.positions[i3] = this.millOrigin.x + (Math.random() - 0.5) * spread;
    this.positions[i3 + 1] = this.millOrigin.y + (Math.random() - 0.5) * spread * 0.5;
    this.positions[i3 + 2] = this.millOrigin.z + (Math.random() - 0.5) * spread;

    this.velocities[index] = {
      x: (Math.random() - 0.5) * 0.15,
      y: 0.05 + Math.random() * 0.25, // Flotación convectiva ascendente
      z: (Math.random() - 0.5) * 0.15
    };
  }

  /**
   * Actualiza el sistema de partículas de polvo en cada frame.
   * @param {number} dt 
   * @param {number} millRPM 
   * @param {number} dustConcentration 
   * @param {boolean} cycloneActive 
   */
  update(dt, millRPM, dustConcentration, cycloneActive) {
    if (!this.particles) return;

    // Ajusta la opacidad según la concentración medida (g/m^3)
    const normalizedDensity = Math.min(0.85, Math.max(0.1, dustConcentration / 40.0));
    this.material.opacity = normalizedDensity;

    // Si el molino está en reposo y no hay concentración, ocultar
    if (millRPM < 50.0 && dustConcentration < 5.0) {
      this.material.opacity = 0.05;
    }

    const pos = this.positions;

    for (let i = 0; i < this.particleCount; i++) {
      const i3 = i * 3;
      const vel = this.velocities[i];

      if (cycloneActive) {
        // Aspiración hacia la boca del ducto ciclónico
        const dx = this.cycloneDuctPos.x - pos[i3];
        const dy = this.cycloneDuctPos.y - pos[i3 + 1];
        const dz = this.cycloneDuctPos.z - pos[i3 + 2];
        const dist = Math.sqrt(dx * dx + dy * dy + dz * dz);

        if (dist < 0.2) {
          this.resetParticle(i);
          continue;
        }

        // Fuerza de succión proporcional a 1/dist
        const pull = 1.2 * dt;
        pos[i3] += (dx / dist) * pull;
        pos[i3 + 1] += (dy / dist) * pull;
        pos[i3 + 2] += (dz / dist) * pull;
      } else {
        // Dispersión turbulenta y flotación en nave
        pos[i3] += vel.x * dt;
        pos[i3 + 1] += vel.y * dt;
        pos[i3 + 2] += vel.z * dt;

        // Si sube mucho o se aleja demasiado, reciclar cerca del molino
        if (pos[i3 + 1] > 5.5 || Math.abs(pos[i3] - this.millOrigin.x) > 3.0) {
          this.resetParticle(i);
        }
      }
    }

    this.particles.geometry.attributes.position.needsUpdate = true;
  }
}
export default DustParticleCloud;
