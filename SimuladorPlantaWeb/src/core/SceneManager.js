import * as THREE from 'three';

/**
 * SceneManager.js - Gestor central del motor gráfico Three.js (WebGL PBR).
 * Configura:
 * - WebGLRenderer de alta fidelidad (PBR, sombras PCF suaves, ACESFilmic tone mapping, sRGB).
 * - PerspectiveCamera para visualización industrial en primera persona u orbital.
 * - Iluminación PBR distribuida (Ambiental, luces cenitales de nave industrial, proyectores focales
 *   y luz estroboscópica roja de emergencia).
 */
export class SceneManager {
  constructor(canvasContainer) {
    this.container = canvasContainer;
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x13171d);
    this.scene.fog = new THREE.FogExp2(0x13171d, 0.022);

    // Dimensiones
    const width = window.innerWidth;
    const height = window.innerHeight;

    // Cámara de perspectiva
    this.camera = new THREE.PerspectiveCamera(65, width / height, 0.1, 150.0);
    this.camera.position.set(-10.5, 1.7, 7.0); // Inicio en vestidores

    // Renderer WebGL
    this.renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
    this.renderer.setSize(width, height);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.1;
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;

    this.container.appendChild(this.renderer.domElement);

    // Luces
    this.emergencyLight = null;
    this.setupLighting();
    this.setupResizeHandler();
  }

  setupLighting() {
    // 1. Luz ambiental uniforme
    const ambLight = new THREE.AmbientLight(0xdde5ed, 0.45);
    this.scene.add(ambLight);

    // 2. Luz cenital principal (Luminarias industriales LED de nave)
    const mainLight = new THREE.DirectionalLight(0xfff5e6, 1.3);
    mainLight.position.set(5.0, 10.0, 4.0);
    mainLight.castShadow = true;
    mainLight.shadow.mapSize.width = 2048;
    mainLight.shadow.mapSize.height = 2048;
    mainLight.shadow.camera.near = 0.5;
    mainLight.shadow.camera.far = 30.0;
    mainLight.shadow.camera.left = -15;
    mainLight.shadow.camera.right = 15;
    mainLight.shadow.camera.top = 15;
    mainLight.shadow.camera.bottom = -15;
    mainLight.shadow.bias = -0.0005;
    this.scene.add(mainLight);

    // 3. Proyector focal sobre el Molino y Motor 10 HP
    const spotMill = new THREE.SpotLight(0xfff0db, 2.0, 15.0, Math.PI / 4, 0.4, 1);
    spotMill.position.set(2.0, 6.5, 0.0);
    spotMill.target.position.set(2.0, 0.5, 0.0);
    spotMill.castShadow = true;
    this.scene.add(spotMill);
    this.scene.add(spotMill.target);

    // 4. Proyector focal sobre el Tablero CCM
    const spotCCM = new THREE.SpotLight(0xe1f5fe, 1.8, 12.0, Math.PI / 5, 0.3, 1);
    spotCCM.position.set(-6.0, 5.5, -1.0);
    spotCCM.target.position.set(-6.0, 1.2, -3.0);
    spotCCM.castShadow = true;
    this.scene.add(spotCCM);
    this.scene.add(spotCCM.target);

    // 5. Luz cálida de vestidores
    const lockerLight = new THREE.PointLight(0xffe0b2, 1.0, 10.0);
    lockerLight.position.set(-10.5, 3.5, 6.5);
    this.scene.add(lockerLight);

    // 6. Luz estroboscópica roja de emergencia
    this.emergencyLight = new THREE.PointLight(0xff1744, 0.0, 20.0);
    this.emergencyLight.position.set(-6.0, 2.6, -3.0);
    this.scene.add(this.emergencyLight);
  }

  setupResizeHandler() {
    window.addEventListener('resize', () => {
      const w = window.innerWidth;
      const h = window.innerHeight;
      this.camera.aspect = w / h;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(w, h);
    });
  }

  /**
   * Actualiza el destello de la luz estroboscópica de emergencia.
   * @param {boolean} isEmergencyActive 
   * @param {number} timeSec 
   */
  updateEmergencyStrobe(isEmergencyActive, timeSec) {
    if (!this.emergencyLight) return;
    if (isEmergencyActive) {
      // Parpadeo a 2 Hz (0.5 s por ciclo)
      const flash = Math.sin(timeSec * Math.PI * 4) > 0 ? 3.0 : 0.0;
      this.emergencyLight.intensity = flash;
    } else {
      this.emergencyLight.intensity = 0.0;
    }
  }

  render() {
    this.renderer.render(this.scene, this.camera);
  }
}
export default SceneManager;
