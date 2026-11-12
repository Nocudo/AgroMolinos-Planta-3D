import * as THREE from 'three';

/**
 * WarehouseBuilder.js - Construcción procedural de la Nave Industrial AgroMolinos del Valle S.A.
 * Incluye:
 * - Piso de concreto epóxico pulido con demarcación RETIE amarilla y negra.
 * - Estructura de vigas de acero estructural en celosía y columnas I-beam.
 * - Vestidores y esclusa de seguridad con puerta corredera automática.
 * - Terminal interactivo de inducción y mesa de dotación de EPP.
 * - Señalización industrial de emergencia (ISO 7010) y extintores CO2/ABC.
 */
export class WarehouseBuilder {
  constructor(scene) {
    this.scene = scene;
    this.interactables = []; // Objetos con los que el raycast puede interactuar
    this.airlockDoorMesh = null;
  }

  build() {
    this.createMaterials();
    this.createBuildingShell();
    this.createStructuralBeams();
    this.createLockerRoomAndAirlock();
    this.createSafetyDemarcations();
    this.createSignageAndAccessories();
  }

  createMaterials() {
    // Piso epóxico gris claro industrial reflectivo
    this.matFloor = new THREE.MeshStandardMaterial({
      color: 0x3d444d,
      roughness: 0.35,
      metalness: 0.15
    });

    // Piso del vestidor (tonalidad ligeramente distinta)
    this.matLockerFloor = new THREE.MeshStandardMaterial({
      color: 0x2b313a,
      roughness: 0.45,
      metalness: 0.1
    });

    // Muros perimetrales de mampostería reforzada
    this.matWall = new THREE.MeshStandardMaterial({
      color: 0x7c8794,
      roughness: 0.85,
      metalness: 0.05
    });

    // Muro divisorio vestidores
    this.matLockerWall = new THREE.MeshStandardMaterial({
      color: 0x93a1b1,
      roughness: 0.7,
      metalness: 0.1
    });

    // Acero estructural para columnas y vigas
    this.matSteelBeam = new THREE.MeshStandardMaterial({
      color: 0x1e252d,
      roughness: 0.4,
      metalness: 0.8
    });

    // Demarcación de seguridad (amarillo tráfico RETIE / OSHA)
    this.matSafetyYellow = new THREE.MeshStandardMaterial({
      color: 0xf4b400,
      roughness: 0.5,
      metalness: 0.1
    });

    // Puerta de la esclusa (acero cepillado y cristal de seguridad)
    this.matAirlockDoor = new THREE.MeshStandardMaterial({
      color: 0x4285f4,
      roughness: 0.3,
      metalness: 0.7,
      transparent: true,
      opacity: 0.85
    });

    // Techo
    this.matCeiling = new THREE.MeshStandardMaterial({
      color: 0x252a31,
      roughness: 0.9,
      metalness: 0.2
    });
  }

  createBuildingShell() {
    const width = 26.0;   // Ancho eje X (-13 a +13)
    const length = 20.0;  // Profundidad eje Z (-10 a +10)
    const height = 7.5;   // Altura libre de planta

    // 1. Piso principal
    const floorGeo = new THREE.PlaneGeometry(width, length);
    const floor = new THREE.Mesh(floorGeo, this.matFloor);
    floor.rotation.x = -Math.PI / 2;
    floor.position.set(0, 0, 0);
    floor.receiveShadow = true;
    this.scene.add(floor);

    // 2. Techo con cerchas
    const ceilingGeo = new THREE.PlaneGeometry(width, length);
    const ceiling = new THREE.Mesh(ceilingGeo, this.matCeiling);
    ceiling.rotation.x = Math.PI / 2;
    ceiling.position.set(0, height, 0);
    this.scene.add(ceiling);

    // 3. Muro posterior (Z = -10)
    const wallBackGeo = new THREE.BoxGeometry(width, height, 0.3);
    const wallBack = new THREE.Mesh(wallBackGeo, this.matWall);
    wallBack.position.set(0, height / 2, -length / 2);
    wallBack.receiveShadow = true;
    this.scene.add(wallBack);

    // 4. Muro frontal (Z = +10)
    const wallFrontGeo = new THREE.BoxGeometry(width, height, 0.3);
    const wallFront = new THREE.Mesh(wallFrontGeo, this.matWall);
    wallFront.position.set(0, height / 2, length / 2);
    wallFront.receiveShadow = true;
    this.scene.add(wallFront);

    // 5. Muro derecho (X = +13)
    const wallRightGeo = new THREE.BoxGeometry(0.3, height, length);
    const wallRight = new THREE.Mesh(wallRightGeo, this.matWall);
    wallRight.position.set(width / 2, height / 2, 0);
    wallRight.receiveShadow = true;
    this.scene.add(wallRight);

    // 6. Muro izquierdo exterior (X = -13)
    const wallLeftGeo = new THREE.BoxGeometry(0.3, height, length);
    const wallLeft = new THREE.Mesh(wallLeftGeo, this.matWall);
    wallLeft.position.set(-width / 2, height / 2, 0);
    wallLeft.receiveShadow = true;
    this.scene.add(wallLeft);
  }

  createStructuralBeams() {
    const colHeight = 7.5;
    const colPositions = [
      [-12.7, -9.7], [-12.7, 0], [-12.7, 9.7],
      [-5.0, -9.7], [-5.0, 9.7],
      [5.0, -9.7], [5.0, 9.7],
      [12.7, -9.7], [12.7, 0], [12.7, 9.7]
    ];

    const colGeo = new THREE.BoxGeometry(0.4, colHeight, 0.4);
    for (const [x, z] of colPositions) {
      const col = new THREE.Mesh(colGeo, this.matSteelBeam);
      col.position.set(x, colHeight / 2, z);
      col.castShadow = true;
      col.receiveShadow = true;
      this.scene.add(col);
    }

    // Vigas maestras transversales en el techo (X)
    const beamTransGeo = new THREE.BoxGeometry(26.0, 0.45, 0.3);
    for (const z of [-9.7, 0, 9.7]) {
      const beam = new THREE.Mesh(beamTransGeo, this.matSteelBeam);
      beam.position.set(0, 7.3, z);
      this.scene.add(beam);
    }
  }

  createLockerRoomAndAirlock() {
    // Zona de vestidores delimitada en la esquina izquierda:
    // X entre -13.0 y -8.0, Z entre 2.0 y 9.8.
    // Muro divisorio en X = -8.0
    const wallDivZGeo = new THREE.BoxGeometry(0.2, 4.0, 5.5);
    const wallDivZ = new THREE.Mesh(wallDivZGeo, this.matLockerWall);
    wallDivZ.position.set(-8.0, 2.0, 6.75); // Desde Z = 4.0 hasta Z = 9.5
    wallDivZ.castShadow = true;
    this.scene.add(wallDivZ);

    // Muro divisorio en Z = 3.5 con vano para la esclusa
    const wallDivXGeo = new THREE.BoxGeometry(3.0, 4.0, 0.2);
    const wallDivX = new THREE.Mesh(wallDivXGeo, this.matLockerWall);
    wallDivX.position.set(-11.5, 2.0, 3.5);
    this.scene.add(wallDivX);

    // Marco superior de la esclusa (sobre la puerta corredera)
    const doorLintelGeo = new THREE.BoxGeometry(2.0, 1.2, 0.2);
    const doorLintel = new THREE.Mesh(doorLintelGeo, this.matLockerWall);
    doorLintel.position.set(-9.0, 3.4, 3.5);
    this.scene.add(doorLintel);

    // Hoja móvil corredera de la esclusa de seguridad
    const doorLeafGeo = new THREE.BoxGeometry(1.9, 2.8, 0.08);
    this.airlockDoorMesh = new THREE.Mesh(doorLeafGeo, this.matAirlockDoor);
    this.airlockDoorMesh.position.set(-9.0, 1.4, 3.5);
    this.airlockDoorMesh.castShadow = true;
    this.airlockDoorMesh.userData = {
      type: 'airlock_door',
      name: 'Esclusa de Seguridad a Nave de Producción',
      action: 'tryPassAirlock'
    };
    this.scene.add(this.airlockDoorMesh);
    this.interactables.push(this.airlockDoorMesh);

    // Terminal interactivo de inducción en la pared del vestidor (X = -12.8, Z = 6.0)
    const terminalBaseGeo = new THREE.BoxGeometry(0.25, 0.8, 0.6);
    const matTerminal = new THREE.MeshStandardMaterial({ color: 0x1a73e8, metalness: 0.5, roughness: 0.3 });
    const terminal = new THREE.Mesh(terminalBaseGeo, matTerminal);
    terminal.position.set(-12.8, 1.5, 6.0);

    // Pantalla brillante del terminal
    const screenGeo = new THREE.PlaneGeometry(0.5, 0.65);
    const matScreen = new THREE.MeshBasicMaterial({ color: 0x64b5f6 });
    const screen = new THREE.Mesh(screenGeo, matScreen);
    screen.rotation.y = Math.PI / 2;
    screen.position.set(-12.65, 1.5, 6.0);
    terminal.add(screen);

    terminal.userData = {
      type: 'safety_induction_terminal',
      name: 'Terminal de Inducción de Seguridad RETIE / LOTO',
      action: 'completeInduction'
    };
    this.scene.add(terminal);
    this.interactables.push(terminal);

    // Mesa / Estante de EPP en el vestidor (X = -10.5, Z = 7.5)
    const tableTopGeo = new THREE.BoxGeometry(2.4, 0.1, 0.8);
    const matTable = new THREE.MeshStandardMaterial({ color: 0x4e5d6c, roughness: 0.6 });
    const tableTop = new THREE.Mesh(tableTopGeo, matTable);
    tableTop.position.set(-10.5, 0.9, 7.5);
    tableTop.castShadow = true;
    this.scene.add(tableTop);

    // Patas de la mesa
    const legGeo = new THREE.CylinderGeometry(0.04, 0.04, 0.9);
    for (const [lx, lz] of [[-1.1, -0.3], [-1.1, 0.3], [1.1, -0.3], [1.1, 0.3]]) {
      const leg = new THREE.Mesh(legGeo, this.matSteelBeam);
      leg.position.set(-10.5 + lx, 0.45, 7.5 + lz);
      this.scene.add(leg);
    }

    // Casco amarillo dieléctrico interactivo sobre la mesa
    const helmetGeo = new THREE.SphereGeometry(0.16, 16, 16, 0, Math.PI * 2, 0, Math.PI / 2);
    const matHelmet = new THREE.MeshStandardMaterial({ color: 0xffd600, roughness: 0.3 });
    const helmetMesh = new THREE.Mesh(helmetGeo, matHelmet);
    helmetMesh.position.set(-11.3, 0.95, 7.5);
    helmetMesh.castShadow = true;
    helmetMesh.userData = { type: 'ppe_item', itemKey: 'helmet', name: 'Casco Dieléctrico Tipo I Clase E (RETIE Art. 20)' };
    this.scene.add(helmetMesh);
    this.interactables.push(helmetMesh);

    // Gafas de seguridad sobre la mesa
    const glassesGeo = new THREE.BoxGeometry(0.18, 0.06, 0.12);
    const matGlasses = new THREE.MeshStandardMaterial({ color: 0x00e5ff, transparent: true, opacity: 0.8 });
    const glassesMesh = new THREE.Mesh(glassesGeo, matGlasses);
    glassesMesh.position.set(-10.8, 0.98, 7.5);
    glassesMesh.userData = { type: 'ppe_item', itemKey: 'glasses', name: 'Gafas de Seguridad ANSI Z87.1' };
    this.scene.add(glassesMesh);
    this.interactables.push(glassesMesh);

    // Copas auditivas
    const earmuffsGeo = new THREE.TorusGeometry(0.1, 0.04, 12, 16, Math.PI);
    const matEarmuffs = new THREE.MeshStandardMaterial({ color: 0xff1744 });
    const earmuffsMesh = new THREE.Mesh(earmuffsGeo, matEarmuffs);
    earmuffsMesh.rotation.x = Math.PI / 2;
    earmuffsMesh.position.set(-10.4, 0.98, 7.5);
    earmuffsMesh.userData = { type: 'ppe_item', itemKey: 'earmuffs', name: 'Copas Auditivas NRR 27 dB (OSHA 1910)' };
    this.scene.add(earmuffsMesh);
    this.interactables.push(earmuffsMesh);

    // Botas dieléctricas junto a la mesa en el suelo
    const bootsGeo = new THREE.BoxGeometry(0.25, 0.22, 0.35);
    const matBoots = new THREE.MeshStandardMaterial({ color: 0x212121, roughness: 0.7 });
    const bootsMesh = new THREE.Mesh(bootsGeo, matBoots);
    bootsMesh.position.set(-10.5, 0.11, 6.7);
    bootsMesh.userData = { type: 'ppe_item', itemKey: 'boots', name: 'Botas Dieléctricas ASTM F2413' };
    this.scene.add(bootsMesh);
    this.interactables.push(bootsMesh);

    // Guantes dieléctricos Clase 00 sobre la mesa
    const glovesGeo = new THREE.BoxGeometry(0.18, 0.04, 0.22);
    const matGloves = new THREE.MeshStandardMaterial({ color: 0xbf360c, roughness: 0.6 });
    const glovesMesh = new THREE.Mesh(glovesGeo, matGloves);
    glovesMesh.position.set(-10.0, 0.98, 7.5);
    glovesMesh.userData = { type: 'ppe_item', itemKey: 'gloves', name: 'Guantes Dieléctricos Clase 00 (RETIE / NFPA 70E)' };
    this.scene.add(glovesMesh);
    this.interactables.push(glovesMesh);

    // Overol ignífugo colgado en perchero
    const suitGeo = new THREE.BoxGeometry(0.4, 0.9, 0.15);
    const matSuit = new THREE.MeshStandardMaterial({ color: 0x0d47a1, roughness: 0.8 });
    const suitMesh = new THREE.Mesh(suitGeo, matSuit);
    suitMesh.position.set(-9.4, 1.4, 7.8);
    suitMesh.userData = { type: 'ppe_item', itemKey: 'suit', name: 'Overol Antiestático e Ignífugo (NFPA 70E)' };
    this.scene.add(suitMesh);
    this.interactables.push(suitMesh);
  }

  createSafetyDemarcations() {
    // Franja de delimitación perimetral RETIE en el piso alrededor del CCM
    // En X = -6.0, Z = -3.0 (Dimensiones 3.0 x 2.2 m)
    const ccmDemarcationGeo = new THREE.RingGeometry(1.2, 1.4, 32);
    const ccmDemarcation = new THREE.Mesh(ccmDemarcationGeo, this.matSafetyYellow);
    ccmDemarcation.rotation.x = -Math.PI / 2;
    ccmDemarcation.position.set(-6.0, 0.005, -3.0);
    this.scene.add(ccmDemarcation);

    // Franja de delimitación alrededor del Molino y Motor 10 HP
    // En X = 2.0, Z = 0.0 (Radio de seguridad de 2.0 m)
    const millDemarcationGeo = new THREE.RingGeometry(2.1, 2.3, 32);
    const millDemarcation = new THREE.Mesh(millDemarcationGeo, this.matSafetyYellow);
    millDemarcation.rotation.x = -Math.PI / 2;
    millDemarcation.position.set(2.0, 0.005, 0.0);
    this.scene.add(millDemarcation);
  }

  createSignageAndAccessories() {
    // Señal de parada de emergencia y primeros auxilios en pared
    const signGeo = new THREE.PlaneGeometry(0.8, 0.5);
    const matSignExit = new THREE.MeshBasicMaterial({ color: 0x00c853 });
    const signExit = new THREE.Mesh(signGeo, matSignExit);
    signExit.position.set(0, 3.5, 9.8);
    signExit.rotation.y = Math.PI;
    this.scene.add(signExit);

    // Extintor CO2 en columna
    const extCylinderGeo = new THREE.CylinderGeometry(0.1, 0.1, 0.65);
    const matRed = new THREE.MeshStandardMaterial({ color: 0xd50000, roughness: 0.3 });
    const extinguisher = new THREE.Mesh(extCylinderGeo, matRed);
    extinguisher.position.set(-5.0, 1.2, -9.4);
    this.scene.add(extinguisher);
  }

  /**
   * Actualiza la animación de la puerta corredera de la esclusa.
   * @param {boolean} isOpen 
   * @param {number} dt 
   */
  updateAirlockAnimation(isOpen, dt) {
    if (!this.airlockDoorMesh) return;
    const targetX = isOpen ? -7.2 : -9.0;
    this.airlockDoorMesh.position.x += (targetX - this.airlockDoorMesh.position.x) * Math.min(1.0, 5.0 * dt);
  }
}
export default WarehouseBuilder;
