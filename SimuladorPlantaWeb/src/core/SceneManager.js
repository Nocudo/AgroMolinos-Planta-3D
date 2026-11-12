import * as THREE from 'three';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';

/**
 * SceneManager.js - Gestor de Renderizado PBR y Post-Processing Cinematográfico en Three.js.
 * Configura:
 * - WebGLRenderer de alta fidelidad con sombras suaves PCF y ACESFilmic tone mapping.
 * - EffectComposer con UnrealBloomPass para brillo atmosférico en balizas Andon, pantallas SCADA y LEDs.
 * - Iluminación PBR distribuida (10 luminarias High-Bay suspendidas, proyectores focales en maquinaria,
 *   subestación y luz de emergencia estroboscópica).
 */
export class SceneManager {
  constructor(canvasContainer) {
    this.container = canvasContainer;
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x0f1318);
    this.scene.fog = new THREE.FogExp2(0x0f1318, 0.015);

    // Dimensiones de pantalla
    const width = window.innerWidth;
    const height = window.innerHeight;

    // Cámara de perspectiva (Posición inicial en vestidores)
    this.camera = new THREE.PerspectiveCamera(65, width / height, 0.1, 200.0);
    this.camera.position.set(-18.5, 1.7, 0.0);

    // Renderer WebGL
    this.renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
    this.renderer.setSize(width, height);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.15;
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;

    this.container.appendChild(this.renderer.domElement);

    // Luces
    this.emergencyLight = null;
    this.setupLighting();

    // Post-Processing con EffectComposer y UnrealBloomPass
    this.composer = null;
    this.setupPostProcessing(width, height);

    this.setupResizeHandler();
  }

  setupLighting() {
    // 1. Luz ambiental uniforme
    const ambLight = new THREE.AmbientLight(0xdbe4ed, 0.55);
    this.scene.add(ambLight);

    // 2. Luz direccional cenital principal (Simula luz solar a través de claraboyas industriales)
    const mainSun = new THREE.DirectionalLight(0xfff6ea, 1.4);
    mainSun.position.set(10.0, 15.0, 8.0);
    mainSun.castShadow = true;
    mainSun.shadow.mapSize.width = 2048;
    mainSun.shadow.mapSize.height = 2048;
    mainSun.shadow.camera.near = 0.5;
    mainSun.shadow.camera.far = 45.0;
    mainSun.shadow.camera.left = -25;
    mainSun.shadow.camera.right = 25;
    mainSun.shadow.camera.top = 20;
    mainSun.shadow.camera.bottom = -20;
    mainSun.shadow.bias = -0.0004;
    this.scene.add(mainSun);

    // 3. Batería de Luminarias Industriales High-Bay LED suspendidas a Y = 9.2m
    const highBayPositions = [
      [-12.0, -8.0], [-12.0, 0.0], [-12.0, 8.0],
      [0.0, -8.0],   [0.0, 0.0],   [0.0, 8.0],
      [12.0, -8.0],  [12.0, 0.0],  [12.0, 8.0]
    ];

    const fixtureGeo = new THREE.CylinderGeometry(0.35, 0.5, 0.3, 16);
    const matFixture = new THREE.MeshStandardMaterial({ color: 0x263238, metalness: 0.8 });
    const matBulb = new THREE.MeshBasicMaterial({ color: 0xffffff });
    const bulbGeo = new THREE.SphereGeometry(0.18, 12, 12);

    highBayPositions.forEach(([hx, hz]) => {
      // Campana industrial física 3D
      const fixture = new THREE.Mesh(fixtureGeo, matFixture);
      fixture.position.set(hx, 9.4, hz);
      this.scene.add(fixture);

      const bulb = new THREE.Mesh(bulbGeo, matBulb);
      bulb.position.set(hx, 9.25, hz);
      this.scene.add(bulb);

      // Foco puntual de cada luminaria
      const bayLight = new THREE.PointLight(0xfffaed, 0.8, 18.0, 1.2);
      bayLight.position.set(hx, 9.1, hz);
      this.scene.add(bayLight);
    });

    // 4. Proyector focal sobre el Molino y Motor 10 HP
    const spotMill = new THREE.SpotLight(0xfff5e6, 2.5, 18.0, Math.PI / 4, 0.4, 1);
    spotMill.position.set(2.0, 7.5, 0.0);
    spotMill.target.position.set(2.0, 0.5, 0.0);
    spotMill.castShadow = true;
    this.scene.add(spotMill);
    this.scene.add(spotMill.target);

    // 5. Proyector focal sobre el Tablero CCM
    const spotCCM = new THREE.SpotLight(0xe1f5fe, 2.0, 14.0, Math.PI / 5, 0.3, 1);
    spotCCM.position.set(-6.0, 6.0, -1.0);
    spotCCM.target.position.set(-6.0, 1.2, -3.0);
    spotCCM.castShadow = true;
    this.scene.add(spotCCM);
    this.scene.add(spotCCM.target);

    // 6. Proyector focal sobre los Silos
    const spotSilos = new THREE.SpotLight(0xffe082, 1.8, 20.0, Math.PI / 3, 0.5, 1);
    spotSilos.position.set(17.0, 8.5, 0.0);
    spotSilos.target.position.set(17.0, 4.0, 0.0);
    this.scene.add(spotSilos);
    this.scene.add(spotSilos.target);

    // 7. Luz interior de la Sala de Control SCADA
    const controlLight = new THREE.PointLight(0x80d8ff, 1.4, 14.0);
    controlLight.position.set(-18.5, 3.2, 9.0);
    this.scene.add(controlLight);

    // 8. Luz cálida de vestidores
    const lockerLight = new THREE.PointLight(0xffe0b2, 1.2, 12.0);
    lockerLight.position.set(-18.5, 3.2, 0.0);
    this.scene.add(lockerLight);

    // 9. Luz estroboscópica roja de emergencia (Se activa con E-Stop)
    this.emergencyLight = new THREE.PointLight(0xff1744, 0.0, 25.0);
    this.emergencyLight.position.set(-6.0, 3.0, -3.0);
    this.scene.add(this.emergencyLight);
  }

  setupPostProcessing(width, height) {
    try {
      const renderPass = new RenderPass(this.scene, this.camera);

      // UnrealBloomPass: efecto de halo brillante en balizas y monitores
      const bloomPass = new UnrealBloomPass(
        new THREE.Vector2(width, height),
        0.35,  // bloom strength (elegante y pulido)
        0.3,   // radius
        0.82   // threshold (solo brillan elementos intensos/emisivos)
      );

      const outputPass = new OutputPass();

      this.composer = new EffectComposer(this.renderer);
      this.composer.addPass(renderPass);
      this.composer.addPass(bloomPass);
      this.composer.addPass(outputPass);
    } catch (e) {
      console.warn('[SceneManager] Post-processing no disponible, usando renderer estándar:', e);
      this.composer = null;
    }
  }

  setupResizeHandler() {
    window.addEventListener('resize', () => {
      const w = window.innerWidth;
      const h = window.innerHeight;
      this.camera.aspect = w / h;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(w, h);
      if (this.composer) {
        this.composer.setSize(w, h);
      }
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
      const flash = Math.sin(timeSec * Math.PI * 4) > 0 ? 3.5 : 0.0;
      this.emergencyLight.intensity = flash;
    } else {
      this.emergencyLight.intensity = 0.0;
    }
  }

  render() {
    if (this.composer) {
      this.composer.render();
    } else {
      this.renderer.render(this.scene, this.camera);
    }
  }
}
export default SceneManager;
