import * as THREE from 'three';

/**
 * CCMPanel.js - Centro de Control de Motores (CCM 460 V AC).
 * Integra físicamente en la escena 3D:
 * 1. Gabinete metálico autosoportado RAL 7035 con barras y señalización RETIE Art. 13 de arco eléctrico.
 * 2. Seccionador principal de corte visible (Paso 1 LOTO).
 * 3. Aldaba con candado rojo de seguridad y tarjeta de peligro (Paso 2 LOTO).
 * 4. Puntos de prueba de tensión para voltímetro (Paso 3 LOTO).
 * 5. Botón tipo hongo de Parada de Emergencia (E-Stop IEC 60204-1) interactivo.
 * 6. Pulsadores de Marcha, Parada y Rearme.
 * 7. Torre de baliza Andon 3D de 4 niveles (Verde, Amarillo, Rojo, Azul).
 */
export class CCMPanel {
  constructor(scene, eventBus) {
    this.scene = scene;
    this.eventBus = eventBus;
    this.group = new THREE.Group();
    this.interactables = [];

    // Referencias a mallas interactivas y dinámicas
    this.disconnectHandle = null;
    this.padlockMesh = null;
    this.tagMesh = null;
    this.eStopButtonMesh = null;
    this.andonLights = {
      RED: null,
      AMBER: null,
      GREEN: null,
      BLUE: null
    };

    // Ubicación fija en planta (zona RETIE Art. 13)
    this.origin = new THREE.Vector3(-6.0, 0.0, -3.0);
  }

  build() {
    this.createMaterials();
    this.createCabinet();
    this.createDisconnectSwitchAndLOTO();
    this.createPushbuttonsAndEStop();
    this.createAnalogMeters();
    this.createAndonTower();

    this.group.position.copy(this.origin);
    this.scene.add(this.group);
  }

  createMaterials() {
    // Gabinete metálico gris claro industrial RAL 7035
    this.matCabinet = new THREE.MeshStandardMaterial({
      color: 0x90a4ae,
      roughness: 0.35,
      metalness: 0.6
    });

    // Manija del seccionador (rojo o negro industrial)
    this.matHandle = new THREE.MeshStandardMaterial({
      color: 0xd32f2f,
      roughness: 0.4,
      metalness: 0.5
    });

    // Candado LOTO (rojo brillante de seguridad)
    this.matPadlock = new THREE.MeshStandardMaterial({
      color: 0xff1744,
      roughness: 0.3,
      metalness: 0.7
    });

    // Tarjeta LOTO ("PELIGRO - NO OPERAR")
    this.matTag = new THREE.MeshStandardMaterial({
      color: 0xffffff,
      roughness: 0.6,
      metalness: 0.1
    });

    // Pulsador de emergencia (Hongo rojo)
    this.matEStop = new THREE.MeshStandardMaterial({
      color: 0xd50000,
      roughness: 0.3,
      metalness: 0.2
    });

    // Bisel amarillo de parada de emergencia
    this.matBezelYellow = new THREE.MeshStandardMaterial({
      color: 0xffd600,
      roughness: 0.5
    });

    // Pulsador de marcha (Verde)
    this.matBtnStart = new THREE.MeshStandardMaterial({
      color: 0x00c853,
      roughness: 0.3
    });

    // Pulsador de parada (Rojo)
    this.matBtnStop = new THREE.MeshStandardMaterial({
      color: 0xc62828,
      roughness: 0.3
    });

    // Pulsador de rearme (Azul)
    this.matBtnReset = new THREE.MeshStandardMaterial({
      color: 0x2979ff,
      roughness: 0.3
    });
  }

  createCabinet() {
    // Gabinete autosoportado: 0.9m ancho x 2.1m alto x 0.55m fondo
    const cabGeo = new THREE.BoxGeometry(0.95, 2.1, 0.55);
    const cabinet = new THREE.Mesh(cabGeo, this.matCabinet);
    cabinet.position.set(0, 1.05, 0);
    cabinet.castShadow = true;
    cabinet.receiveShadow = true;
    this.group.add(cabinet);

    // Zócalo de fijación al suelo
    const plinthGeo = new THREE.BoxGeometry(1.0, 0.1, 0.6);
    const matPlinth = new THREE.MeshStandardMaterial({ color: 0x263238, roughness: 0.7 });
    const plinth = new THREE.Mesh(plinthGeo, matPlinth);
    plinth.position.set(0, 0.05, 0);
    this.group.add(plinth);

    // Rótulo superior "CCM-01 - PLANTA MOLINO 460V"
    const labelGeo = new THREE.PlaneGeometry(0.8, 0.12);
    const matLabel = new THREE.MeshBasicMaterial({ color: 0x111111 });
    const label = new THREE.Mesh(labelGeo, matLabel);
    label.position.set(0, 1.95, 0.28);
    this.group.add(label);

    // Símbolo de advertencia RETIE Art. 13 de Arco Eléctrico
    const warningPlateGeo = new THREE.PlaneGeometry(0.22, 0.22);
    const matWarning = new THREE.MeshBasicMaterial({ color: 0xffab00 });
    const warningPlate = new THREE.Mesh(warningPlateGeo, matWarning);
    warningPlate.position.set(0.3, 1.5, 0.28);
    this.group.add(warningPlate);
  }

  createDisconnectSwitchAndLOTO() {
    // Seccionador bajo carga en la puerta (Paso 1 LOTO)
    const switchBaseGeo = new THREE.BoxGeometry(0.14, 0.14, 0.05);
    const matBase = new THREE.MeshStandardMaterial({ color: 0x37474f });
    const switchBase = new THREE.Mesh(switchBaseGeo, matBase);
    switchBase.position.set(-0.25, 1.45, 0.29);
    this.group.add(switchBase);

    // Manija rotativa (0 grados = Cerrado/Energizado, 90 grados = Abierto/LOTO)
    const handleGeo = new THREE.BoxGeometry(0.04, 0.16, 0.06);
    this.disconnectHandle = new THREE.Mesh(handleGeo, this.matHandle);
    this.disconnectHandle.position.set(-0.25, 1.45, 0.34);
    this.disconnectHandle.castShadow = true;
    this.disconnectHandle.userData = {
      type: 'loto_disconnect',
      name: 'Seccionador Principal 460 V (Regla de Oro #1: Corte Visible)',
      action: 'toggleLotoStep1'
    };
    this.group.add(this.disconnectHandle);
    this.interactables.push(this.disconnectHandle);

    // Candado rojo de seguridad LOTO (Paso 2 LOTO)
    const padlockBodyGeo = new THREE.BoxGeometry(0.06, 0.07, 0.03);
    const padlockShackleGeo = new THREE.TorusGeometry(0.025, 0.008, 8, 16, Math.PI);
    this.padlockMesh = new THREE.Group();
    const pBody = new THREE.Mesh(padlockBodyGeo, this.matPadlock);
    const pShackle = new THREE.Mesh(padlockShackleGeo, new THREE.MeshStandardMaterial({ color: 0xcccccc, metalness: 0.9 }));
    pShackle.rotation.z = Math.PI;
    pShackle.position.set(0, 0.045, 0);
    this.padlockMesh.add(pBody);
    this.padlockMesh.add(pShackle);
    this.padlockMesh.position.set(-0.35, 1.45, 0.35);
    this.padlockMesh.visible = false; // Solo visible cuando se aplica LOTO
    this.padlockMesh.userData = {
      type: 'loto_padlock',
      name: 'Candado de Bloqueo LOTO (Regla de Oro #2: Enclavamiento)',
      action: 'toggleLotoStep2'
    };
    this.group.add(this.padlockMesh);
    this.interactables.push(this.padlockMesh);

    // Tarjeta LOTO ("PELIGRO NO OPERAR")
    const tagGeo = new THREE.PlaneGeometry(0.07, 0.12);
    this.tagMesh = new THREE.Mesh(tagGeo, this.matTag);
    this.tagMesh.position.set(-0.35, 1.34, 0.36);
    this.tagMesh.visible = false;
    this.group.add(this.tagMesh);
  }

  createPushbuttonsAndEStop() {
    // 1. Botón de Parada de Emergencia (Hongo rojo) en X = 0.25, Y = 1.15
    const bezelGeo = new THREE.CylinderGeometry(0.07, 0.07, 0.02, 24);
    const bezel = new THREE.Mesh(bezelGeo, this.matBezelYellow);
    bezel.rotation.x = Math.PI / 2;
    bezel.position.set(0.25, 1.15, 0.285);
    this.group.add(bezel);

    const mushroomGeo = new THREE.CylinderGeometry(0.05, 0.04, 0.045, 24);
    this.eStopButtonMesh = new THREE.Mesh(mushroomGeo, this.matEStop);
    this.eStopButtonMesh.rotation.x = Math.PI / 2;
    this.eStopButtonMesh.position.set(0.25, 1.15, 0.31);
    this.eStopButtonMesh.castShadow = true;
    this.eStopButtonMesh.userData = {
      type: 'e_stop_button',
      name: 'Pulsador de Parada de Emergencia (IEC 60204-1 / ISO 13850)',
      action: 'toggleEStop'
    };
    this.group.add(this.eStopButtonMesh);
    this.interactables.push(this.eStopButtonMesh);

    // 2. Pulsador de Marcha (Verde) en X = -0.15, Y = 1.15
    const btnGeo = new THREE.CylinderGeometry(0.03, 0.03, 0.025, 16);
    const btnStart = new THREE.Mesh(btnGeo, this.matBtnStart);
    btnStart.rotation.x = Math.PI / 2;
    btnStart.position.set(-0.15, 1.15, 0.29);
    btnStart.userData = {
      type: 'vfd_start',
      name: 'Pulsador de Marcha Motor 10 HP (I)',
      action: 'vfdStart'
    };
    this.group.add(btnStart);
    this.interactables.push(btnStart);

    // 3. Pulsador de Parada (Rojo) en X = -0.05, Y = 1.15
    const btnStop = new THREE.Mesh(btnGeo, this.matBtnStop);
    btnStop.rotation.x = Math.PI / 2;
    btnStop.position.set(-0.05, 1.15, 0.29);
    btnStop.userData = {
      type: 'vfd_stop',
      name: 'Pulsador de Parada Operacional Motor 10 HP (O)',
      action: 'vfdStop'
    };
    this.group.add(btnStop);
    this.interactables.push(btnStop);

    // 4. Pulsador de Rearme de Seguridad (Azul) en X = 0.08, Y = 1.15
    const btnReset = new THREE.Mesh(btnGeo, this.matBtnReset);
    btnReset.rotation.x = Math.PI / 2;
    btnReset.position.set(0.08, 1.15, 0.29);
    btnReset.userData = {
      type: 'safety_reset',
      name: 'Pulsador de Rearme de Circuito de Seguridad (Reset)',
      action: 'safetyReset'
    };
    this.group.add(btnReset);
    this.interactables.push(btnReset);
  }

  createAnalogMeters() {
    // Voltímetro y amperímetro analógicos en la parte superior del tablero
    const meterBaseGeo = new THREE.BoxGeometry(0.16, 0.16, 0.03);
    const matMeter = new THREE.MeshStandardMaterial({ color: 0x212121 });

    // Voltímetro 460V
    const voltMeter = new THREE.Mesh(meterBaseGeo, matMeter);
    voltMeter.position.set(-0.2, 1.72, 0.29);
    voltMeter.userData = {
      type: 'loto_voltage_check',
      name: 'Voltímetro de Barras (Regla de Oro #3: Ausencia de Tensión)',
      action: 'verifyVoltageZero'
    };
    this.group.add(voltMeter);
    this.interactables.push(voltMeter);

    // Carátula blanca del voltímetro
    const dialGeo = new THREE.PlaneGeometry(0.13, 0.13);
    const matDial = new THREE.MeshBasicMaterial({ color: 0xf5f5f5 });
    const dial = new THREE.Mesh(dialGeo, matDial);
    dial.position.set(-0.2, 1.72, 0.31);
    this.group.add(dial);

    // Amperímetro
    const ampMeter = new THREE.Mesh(meterBaseGeo, matMeter);
    ampMeter.position.set(0.05, 1.72, 0.29);
    this.group.add(ampMeter);
    const dialAmp = new THREE.Mesh(dialGeo, matDial);
    dialAmp.position.set(0.05, 1.72, 0.31);
    this.group.add(dialAmp);
  }

  createAndonTower() {
    // Torre de baliza Andon sobre el CCM en Y = 2.1m a 2.5m
    const mastGeo = new THREE.CylinderGeometry(0.025, 0.025, 0.15, 16);
    const matMast = new THREE.MeshStandardMaterial({ color: 0x37474f, metalness: 0.8 });
    const mast = new THREE.Mesh(mastGeo, matMast);
    mast.position.set(0, 2.18, 0);
    this.group.add(mast);

    const colors = [
      { key: 'RED', hex: 0xff1744, y: 2.45, name: 'Rojo (Falla / E-Stop)' },
      { key: 'AMBER', hex: 0xffab00, y: 2.37, name: 'Amarillo (Alerta / Sobrecarga)' },
      { key: 'GREEN', hex: 0x00e676, y: 2.29, name: 'Verde (Marcha Nominal)' },
      { key: 'BLUE', hex: 0x2979ff, y: 2.21, name: 'Azul (LOTO Mantenimiento Seguro)' }
    ];

    const lensGeo = new THREE.CylinderGeometry(0.045, 0.045, 0.07, 16);

    for (const c of colors) {
      const matLens = new THREE.MeshStandardMaterial({
        color: c.hex,
        emissive: c.hex,
        emissiveIntensity: 0.1, // Atenuado cuando está apagado
        roughness: 0.2,
        metalness: 0.1,
        transparent: true,
        opacity: 0.85
      });
      const lens = new THREE.Mesh(lensGeo, matLens);
      lens.position.set(0, c.y, 0);
      this.group.add(lens);
      this.andonLights[c.key] = lens;
    }
  }

  /**
   * Actualiza el estado visual de la baliza Andon según la norma ISA 18.2.
   * @param {string} state - 'GREEN' | 'YELLOW' | 'RED' | 'BLUE'
   */
  setAndonState(state) {
    for (const [key, mesh] of Object.entries(this.andonLights)) {
      if (!mesh) continue;
      const isActive = (key === state);
      mesh.material.emissiveIntensity = isActive ? 1.4 : 0.08;
    }
  }

  /**
   * Actualiza la posición física de la manija del seccionador.
   * @param {boolean} isOpen 
   */
  setDisconnectState(isOpen) {
    if (this.disconnectHandle) {
      this.disconnectHandle.rotation.z = isOpen ? Math.PI / 2 : 0;
    }
  }

  /**
   * Conmuta la visibilidad del candado y tarjeta LOTO.
   * @param {boolean} isLocked 
   */
  setPadlockVisible(isLocked) {
    if (this.padlockMesh) this.padlockMesh.visible = isLocked;
    if (this.tagMesh) this.tagMesh.visible = isLocked;
  }

  /**
   * Conmuta la posición física del botón de emergencia (hundido cuando activo).
   * @param {boolean} isEngaged 
   */
  setEStopPosition(isEngaged) {
    if (this.eStopButtonMesh) {
      this.eStopButtonMesh.position.z = isEngaged ? 0.29 : 0.31;
    }
  }
}
export default CCMPanel;
