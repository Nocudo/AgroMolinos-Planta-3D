import * as THREE from 'three';

/**
 * WarehouseBuilder.js - Arquitectura Completa de la Nave Industrial y Fábrica
 * Planta AgroMolinos del Valle S.A. (Dimensiones: 48m x 30m x 10.5m de altura).
 * 
 * Áreas Arquitectónicas Integradas:
 * 1. Nave Principal de Procesamiento con cerchas metálicas trianguladas y columnas IPN.
 * 2. Puente Grúa Superior de 10 Toneladas (Overhead Crane) con carro de izaje y gancho.
 * 3. Pasarelas Elevadas (Catwalks / Mezzanines) a Y = 4.2m con barandillas OSHA y escaleras.
 * 4. Sala de Control SCADA Central acristalada con consolas y pantallas de monitoreo.
 * 5. Subestación Eléctrica con transformador de potencia 13.2kV/460V y encerramiento RETIE.
 * 6. Vestidores de Operarios con mesa de dotación de EPP, terminal interactivo y esclusa corredera.
 * 7. Piso epóxico reflectivo con demarcación vial de montacargas, pasos peatonales y zonas de seguridad.
 */
export class WarehouseBuilder {
  constructor(scene) {
    this.scene = scene;
    this.interactables = [];
    this.airlockDoorMesh = null;
    this.pulsingLEDs = [];

    // Dimensiones maestras de la planta
    this.width = 48.0;   // Eje X (-24m a +24m)
    this.length = 30.0;  // Eje Z (-15m a +15m)
    this.height = 10.5;  // Altura libre de cumbrera
  }

  build() {
    this.createMaterials();
    this.createBuildingShell();
    this.createStructuralTrussesAndColumns();
    this.createOverheadCrane();
    this.createCatwalksAndStairs();
    this.createSCADAControlRoom();
    this.createElectricalSubstation();
    this.createLockerRoomAndAirlock();
    this.createFlooringDemarcations();
  }

  createMaterials() {
    // 1. Piso epóxico gris reflectivo de alta resistencia
    this.matFloor = new THREE.MeshStandardMaterial({
      color: 0x333b44,
      roughness: 0.28,
      metalness: 0.2
    });

    // 2. Corredor peatonal verde industrial
    this.matWalkwayGreen = new THREE.MeshStandardMaterial({
      color: 0x2e7d32,
      roughness: 0.4,
      metalness: 0.1
    });

    // 3. Muros perimetrales tipo sandwich con aislamiento térmico
    this.matWallPanels = new THREE.MeshStandardMaterial({
      color: 0x78909c,
      roughness: 0.8,
      metalness: 0.15
    });

    // 4. Mampostería zócalo inferior
    this.matCurb = new THREE.MeshStandardMaterial({
      color: 0x37474f,
      roughness: 0.9,
      metalness: 0.05
    });

    // 5. Acero estructural oscuro para vigas y cerchas
    this.matSteelStructure = new THREE.MeshStandardMaterial({
      color: 0x1e2631,
      roughness: 0.45,
      metalness: 0.75
    });

    // 6. Amarillo seguridad OSHA / RETIE (para puente grúa y barandillas)
    this.matSafetyYellow = new THREE.MeshStandardMaterial({
      color: 0xffb300,
      roughness: 0.35,
      metalness: 0.3
    });

    // 7. Rejilla metálica de pasarelas (Galvanized Grating)
    this.matGrating = new THREE.MeshStandardMaterial({
      color: 0x78909c,
      roughness: 0.5,
      metalness: 0.8
    });

    // 8. Vidrio de seguridad para la sala de control
    this.matGlass = new THREE.MeshPhysicalMaterial({
      color: 0x81d4fa,
      transparent: true,
      opacity: 0.35,
      roughness: 0.1,
      metalness: 0.9,
      transmission: 0.8,
      ior: 1.5
    });

    // 9. Puerta de la esclusa
    this.matAirlockDoor = new THREE.MeshStandardMaterial({
      color: 0x1976d2,
      roughness: 0.3,
      metalness: 0.6,
      transparent: true,
      opacity: 0.9
    });

    // 10. Pantallas emissivas de monitores SCADA
    this.matScreenEmissive = new THREE.MeshStandardMaterial({
      color: 0x00e5ff,
      emissive: 0x00e5ff,
      emissiveIntensity: 0.8,
      roughness: 0.2
    });

    // 11. Techo industrial con claraboyas
    this.matRoof = new THREE.MeshStandardMaterial({
      color: 0x21272f,
      roughness: 0.85,
      metalness: 0.3
    });
  }

  createBuildingShell() {
    // 1. Piso principal
    const floorGeo = new THREE.PlaneGeometry(this.width, this.length);
    const floor = new THREE.Mesh(floorGeo, this.matFloor);
    floor.rotation.x = -Math.PI / 2;
    floor.position.set(0, 0, 0);
    floor.receiveShadow = true;
    this.scene.add(floor);

    // 2. Techo a dos aguas con lucernarios centrales
    const roofGeo = new THREE.PlaneGeometry(this.width, this.length);
    const roof = new THREE.Mesh(roofGeo, this.matRoof);
    roof.rotation.x = Math.PI / 2;
    roof.position.set(0, this.height, 0);
    this.scene.add(roof);

    // 3. Muro posterior (Z = -15m)
    const wallBackGeo = new THREE.BoxGeometry(this.width, this.height, 0.4);
    const wallBack = new THREE.Mesh(wallBackGeo, this.matWallPanels);
    wallBack.position.set(0, this.height / 2, -this.length / 2);
    wallBack.receiveShadow = true;
    this.scene.add(wallBack);

    // 4. Muro frontal (Z = +15m)
    const wallFrontGeo = new THREE.BoxGeometry(this.width, this.height, 0.4);
    const wallFront = new THREE.Mesh(wallFrontGeo, this.matWallPanels);
    wallFront.position.set(0, this.height / 2, this.length / 2);
    wallFront.receiveShadow = true;
    this.scene.add(wallFront);

    // 5. Muro lateral derecho (X = +24m)
    const wallRightGeo = new THREE.BoxGeometry(0.4, this.height, this.length);
    const wallRight = new THREE.Mesh(wallRightGeo, this.matWallPanels);
    wallRight.position.set(this.width / 2, this.height / 2, 0);
    wallRight.receiveShadow = true;
    this.scene.add(wallRight);

    // 6. Muro lateral izquierdo exterior (X = -24m)
    const wallLeftGeo = new THREE.BoxGeometry(0.4, this.height, this.length);
    const wallLeft = new THREE.Mesh(wallLeftGeo, this.matWallPanels);
    wallLeft.position.set(-this.width / 2, this.height / 2, 0);
    wallLeft.receiveShadow = true;
    this.scene.add(wallLeft);
  }

  createStructuralTrussesAndColumns() {
    const colGeo = new THREE.BoxGeometry(0.6, this.height, 0.6);

    // Filas de columnas en los costados exteriores
    for (let x = -20.0; x <= 20.0; x += 10.0) {
      for (const z of [-14.7, 14.7]) {
        const col = new THREE.Mesh(colGeo, this.matSteelStructure);
        col.position.set(x, this.height / 2, z);
        col.castShadow = true;
        col.receiveShadow = true;
        this.scene.add(col);
      }

      // Cercha superior triangulada en cada vano transversal
      this.createPrattTruss(x, this.height - 0.8, this.length - 1.2);
    }

    // Vigas de carril para el puente grúa (Crane Runway Beams) a Y = 8.2m
    const railBeamGeo = new THREE.BoxGeometry(this.width - 2.0, 0.45, 0.3);
    for (const z of [-10.5, 10.5]) {
      const railBeam = new THREE.Mesh(railBeamGeo, this.matSteelStructure);
      railBeam.position.set(0, 8.2, z);
      railBeam.castShadow = true;
      this.scene.add(railBeam);

      // Carril de acero superior
      const railGeo = new THREE.BoxGeometry(this.width - 2.0, 0.08, 0.08);
      const rail = new THREE.Mesh(railGeo, new THREE.MeshStandardMaterial({ color: 0xb0bec5, metalness: 0.9 }));
      rail.position.set(0, 8.46, z);
      this.scene.add(rail);
    }
  }

  createPrattTruss(xPos, yPos, spanZ) {
    const trussGroup = new THREE.Group();
    trussGroup.position.set(xPos, yPos, 0);

    const halfSpan = spanZ / 2;
    const trussHeight = 1.6;

    // Cuerda superior e inferior
    const chordGeo = new THREE.BoxGeometry(0.25, 0.15, spanZ);
    const bottomChord = new THREE.Mesh(chordGeo, this.matSteelStructure);
    bottomChord.position.set(0, -trussHeight / 2, 0);
    trussGroup.add(bottomChord);

    const topChord = new THREE.Mesh(chordGeo, this.matSteelStructure);
    topChord.position.set(0, trussHeight / 2, 0);
    trussGroup.add(topChord);

    // Montantes verticales y diagonales
    const numPanels = 10;
    const panelWidth = spanZ / numPanels;
    const postGeo = new THREE.BoxGeometry(0.12, trussHeight, 0.12);

    for (let i = 0; i <= numPanels; i++) {
      const z = -halfSpan + i * panelWidth;
      const post = new THREE.Mesh(postGeo, this.matSteelStructure);
      post.position.set(0, 0, z);
      trussGroup.add(post);

      // Diagonal
      if (i < numPanels) {
        const diagLen = Math.sqrt(panelWidth * panelWidth + trussHeight * trussHeight);
        const diagGeo = new THREE.BoxGeometry(0.1, diagLen, 0.1);
        const diag = new THREE.Mesh(diagGeo, this.matSteelStructure);
        const angle = Math.atan2(trussHeight, panelWidth) * (i % 2 === 0 ? 1 : -1);
        diag.rotation.x = angle;
        diag.position.set(0, 0, z + panelWidth / 2);
        trussGroup.add(diag);
      }
    }

    this.scene.add(trussGroup);
  }

  createOverheadCrane() {
    // Puente Grúa de 10 Toneladas que cruza la nave transversalmente
    const craneGroup = new THREE.Group();
    craneGroup.position.set(2.0, 8.5, 0); // Posicionado sobre la zona de maquinaria

    // Dos vigas cajón en paralelo
    const girderGeo = new THREE.BoxGeometry(0.5, 0.8, 21.0);
    const girder1 = new THREE.Mesh(girderGeo, this.matSafetyYellow);
    girder1.position.set(-0.6, 0, 0);
    girder1.castShadow = true;
    craneGroup.add(girder1);

    const girder2 = new THREE.Mesh(girderGeo, this.matSafetyYellow);
    girder2.position.set(0.6, 0, 0);
    girder2.castShadow = true;
    craneGroup.add(girder2);

    // Carro de polipasto móvil (Hoist Trolley)
    const trolleyGeo = new THREE.BoxGeometry(1.4, 0.6, 1.4);
    const matTrolley = new THREE.MeshStandardMaterial({ color: 0x263238, metalness: 0.8 });
    const trolley = new THREE.Mesh(trolleyGeo, matTrolley);
    trolley.position.set(0, 0.5, 0);
    trolley.castShadow = true;
    craneGroup.add(trolley);

    // Tambor de cable y cables de izaje
    const cableGeo = new THREE.CylinderGeometry(0.015, 0.015, 3.5, 8);
    const matCable = new THREE.MeshStandardMaterial({ color: 0x90a4ae, metalness: 0.95 });
    for (const [cx, cz] of [[-0.3, -0.3], [0.3, -0.3], [-0.3, 0.3], [0.3, 0.3]]) {
      const cable = new THREE.Mesh(cableGeo, matCable);
      cable.position.set(cx, -1.2, cz);
      craneGroup.add(cable);
    }

    // Gancho de izaje de 5T (Hook & Block)
    const blockGeo = new THREE.BoxGeometry(0.8, 0.5, 0.8);
    const block = new THREE.Mesh(blockGeo, this.matSafetyYellow);
    block.position.set(0, -3.0, 0);
    craneGroup.add(block);

    const hookGeo = new THREE.TorusGeometry(0.25, 0.06, 12, 24, Math.PI * 1.4);
    const matHook = new THREE.MeshStandardMaterial({ color: 0x212121, metalness: 0.9 });
    const hook = new THREE.Mesh(hookGeo, matHook);
    hook.rotation.z = Math.PI / 2;
    hook.position.set(0, -3.4, 0);
    craneGroup.add(hook);

    this.scene.add(craneGroup);
  }

  createCatwalksAndStairs() {
    // Pasarela elevada longitudinal a Y = 4.2m
    const catwalkGroup = new THREE.Group();
    catwalkGroup.position.set(2.0, 4.2, -12.5);

    // Piso de rejilla de 24m de longitud x 1.5m de ancho
    const floorGeo = new THREE.BoxGeometry(24.0, 0.08, 1.5);
    const catwalkFloor = new THREE.Mesh(floorGeo, this.matGrating);
    catwalkFloor.receiveShadow = true;
    catwalkGroup.add(catwalkFloor);

    // Barandilla de seguridad amarilla OSHA (altura 1.1m)
    this.createRailing(catwalkGroup, 24.0, 0.75, 1.1);

    // Escalera de acceso industrial desde el suelo (X = -10.0, Z = -12.5)
    this.createIndustrialStaircase(catwalkGroup, -10.0, -4.2, 0.0, 4.2);

    this.scene.add(catwalkGroup);
  }

  createRailing(parentGroup, length, zOffset, height) {
    const postCount = Math.floor(length / 2.0);
    const postGeo = new THREE.CylinderGeometry(0.025, 0.025, height, 8);
    const railGeo = new THREE.CylinderGeometry(0.02, 0.02, length, 8);

    // Postes verticales
    for (let i = 0; i <= postCount; i++) {
      const x = -length / 2 + (i * length) / postCount;
      const post = new THREE.Mesh(postGeo, this.matSafetyYellow);
      post.position.set(x, height / 2, zOffset);
      parentGroup.add(post);
    }

    // Pasamanos superior (Top rail)
    const topRail = new THREE.Mesh(railGeo, this.matSafetyYellow);
    topRail.rotation.z = Math.PI / 2;
    topRail.position.set(0, height, zOffset);
    parentGroup.add(topRail);

    // Pasamanos intermedio (Mid rail)
    const midRail = new THREE.Mesh(railGeo, this.matSafetyYellow);
    midRail.rotation.z = Math.PI / 2;
    midRail.position.set(0, height / 2, zOffset);
    parentGroup.add(midRail);

    // Rodapié / Kickplate inferior (10 cm)
    const toeBoardGeo = new THREE.BoxGeometry(length, 0.1, 0.02);
    const toeBoard = new THREE.Mesh(toeBoardGeo, this.matSafetyYellow);
    toeBoard.position.set(0, 0.05, zOffset);
    parentGroup.add(toeBoard);
  }

  createIndustrialStaircase(parentGroup, xPos, startY, startZ, totalHeight) {
    const stepCount = 18;
    const stepRise = totalHeight / stepCount;
    const stepRun = 0.28;
    const stairWidth = 1.2;

    const stairGroup = new THREE.Group();
    stairGroup.position.set(xPos, startY, startZ);

    const stepGeo = new THREE.BoxGeometry(stairWidth, 0.04, stepRun);
    for (let i = 0; i < stepCount; i++) {
      const step = new THREE.Mesh(stepGeo, this.matGrating);
      step.position.set(0, i * stepRise + stepRise / 2, (stepCount - i) * stepRun);
      step.castShadow = true;
      stairGroup.add(step);
    }

    parentGroup.add(stairGroup);
  }

  createSCADAControlRoom() {
    // Sala de control central elevada en X = -18m, Z = 9m (8m ancho x 9m fondo x 4.0m alto)
    const roomGroup = new THREE.Group();
    roomGroup.position.set(-18.5, 0, 9.0);

    // Piso elevado de la sala
    const floorGeo = new THREE.BoxGeometry(9.0, 0.4, 10.0);
    const matControlFloor = new THREE.MeshStandardMaterial({ color: 0x1f2630, roughness: 0.3 });
    const floor = new THREE.Mesh(floorGeo, matControlFloor);
    floor.position.set(0, 0.2, 0);
    roomGroup.add(floor);

    // Muro frontal acristalado panorámico con vista a la nave de producción (Z = -5.0)
    const glassGeo = new THREE.PlaneGeometry(8.5, 3.2);
    const glassWindow = new THREE.Mesh(glassGeo, this.matGlass);
    glassWindow.position.set(0, 2.0, -5.0);
    roomGroup.add(glassWindow);

    // Marcos de aluminio para el ventanal
    const frameGeo = new THREE.BoxGeometry(8.6, 0.1, 0.1);
    const frameTop = new THREE.Mesh(frameGeo, this.matSteelStructure);
    frameTop.position.set(0, 3.6, -5.0);
    roomGroup.add(frameTop);

    // Consola de control en herradura / escritorio
    const consoleGeo = new THREE.BoxGeometry(4.5, 0.9, 1.4);
    const matDesk = new THREE.MeshStandardMaterial({ color: 0x37474f, roughness: 0.5 });
    const desk = new THREE.Mesh(consoleGeo, matDesk);
    desk.position.set(0, 0.85, -3.2);
    roomGroup.add(desk);

    // Pantallas SCADA emisivas sobre el escritorio
    const screenGeo = new THREE.PlaneGeometry(0.9, 0.55);
    for (const sx of [-1.5, -0.5, 0.5, 1.5]) {
      const screen = new THREE.Mesh(screenGeo, this.matScreenEmissive);
      screen.position.set(sx, 1.6, -3.15);
      roomGroup.add(screen);
    }

    // Racks de servidores con LEDs en la pared posterior
    const rackGeo = new THREE.BoxGeometry(1.0, 2.4, 0.8);
    const matRack = new THREE.MeshStandardMaterial({ color: 0x101419, metalness: 0.9, roughness: 0.2 });
    for (const rx of [-2.5, -1.2, 0.1]) {
      const rack = new THREE.Mesh(rackGeo, matRack);
      rack.position.set(rx, 1.6, 3.8);
      roomGroup.add(rack);

      // Fila de LEDs frontales
      const ledGeo = new THREE.SphereGeometry(0.02, 8, 8);
      const matLed = new THREE.MeshStandardMaterial({ color: 0x00e676, emissive: 0x00e676, emissiveIntensity: 1.5 });
      for (let ly = 1.0; ly < 2.2; ly += 0.25) {
        const led = new THREE.Mesh(ledGeo, matLed);
        led.position.set(rx, ly, 3.39);
        roomGroup.add(led);
      }
    }

    this.scene.add(roomGroup);
  }

  createElectricalSubstation() {
    // Subestación eléctrica exterior / Patio de transformadores en X = -18.5m, Z = -10.0m
    const subGroup = new THREE.Group();
    subGroup.position.set(-18.5, 0, -9.5);

    // Base de hormigón reforzado para el transformador
    const padGeo = new THREE.BoxGeometry(5.0, 0.35, 6.0);
    const matPad = new THREE.MeshStandardMaterial({ color: 0x546e7a, roughness: 0.9 });
    const pad = new THREE.Mesh(padGeo, matPad);
    pad.position.set(0, 0.175, 0);
    subGroup.add(pad);

    // Transformador trifásico en baño de aceite 13.2 kV / 460 V
    const trafoGroup = new THREE.Group();
    trafoGroup.position.set(0, 0.35, 0);

    // Cuba principal del transformador (Gris subestación RAL 7035)
    const tankGeo = new THREE.BoxGeometry(2.4, 2.2, 1.8);
    const matTrafo = new THREE.MeshStandardMaterial({ color: 0x78909c, metalness: 0.6, roughness: 0.4 });
    const tank = new THREE.Mesh(tankGeo, matTrafo);
    tank.position.set(0, 1.1, 0);
    tank.castShadow = true;
    trafoGroup.add(tank);

    // Aletas radiadoras de refrigeración en ambos costados
    const finBankGeo = new THREE.BoxGeometry(0.2, 1.8, 1.5);
    const finBank1 = new THREE.Mesh(finBankGeo, matTrafo);
    finBank1.position.set(-1.3, 1.1, 0);
    trafoGroup.add(finBank1);
    const finBank2 = new THREE.Mesh(finBankGeo, matTrafo);
    finBank2.position.set(1.3, 1.1, 0);
    trafoGroup.add(finBank2);

    // Tanque de expansión / conservador cilíndrico superior
    const conservatorGeo = new THREE.CylinderGeometry(0.3, 0.3, 2.0, 16);
    const conservator = new THREE.Mesh(conservatorGeo, matTrafo);
    conservator.rotation.z = Math.PI / 2;
    conservator.position.set(0, 2.45, -0.4);
    trafoGroup.add(conservator);

    // Aisladores de porcelana (Bushings) de alta tensión en la tapa
    const bushingGeo = new THREE.CylinderGeometry(0.06, 0.12, 0.7, 12);
    const matPorcelain = new THREE.MeshStandardMaterial({ color: 0x5d4037, roughness: 0.1, metalness: 0.2 });
    for (const bx of [-0.6, 0.0, 0.6]) {
      const bushing = new THREE.Mesh(bushingGeo, matPorcelain);
      bushing.position.set(bx, 2.55, 0.4);
      trafoGroup.add(bushing);
    }

    subGroup.add(trafoGroup);

    // Malla perimetral de seguridad (Chain-link Fence) con aviso RETIE
    const fenceGeo = new THREE.BoxGeometry(5.2, 2.2, 6.2);
    const matFence = new THREE.MeshStandardMaterial({
      color: 0x90a4ae,
      wireframe: true,
      roughness: 0.3
    });
    const fence = new THREE.Mesh(fenceGeo, matFence);
    fence.position.set(0, 1.1, 0);
    subGroup.add(fence);

    // Rótulo RETIE "PELIGRO 13.2 kV / 460 V"
    const signGeo = new THREE.PlaneGeometry(0.8, 0.45);
    const matSign = new THREE.MeshBasicMaterial({ color: 0xffd600 });
    const sign = new THREE.Mesh(signGeo, matSign);
    sign.position.set(0, 1.5, 3.11);
    subGroup.add(sign);

    this.scene.add(subGroup);
  }

  createLockerRoomAndAirlock() {
    // Zona de vestidores delimitada en X = -18.5m, Z = 0m
    const lockerGroup = new THREE.Group();
    lockerGroup.position.set(-18.5, 0, 0);

    // Muros divisorios de los vestidores
    const wallGeo = new THREE.BoxGeometry(0.25, 4.0, 6.5);
    const matDiv = new THREE.MeshStandardMaterial({ color: 0xb0bec5, roughness: 0.6 });
    const wall = new THREE.Mesh(wallGeo, matDiv);
    wall.position.set(4.5, 2.0, 0);
    lockerGroup.add(wall);

    // Muro frontal con vano de esclusa
    const wallFrontGeo = new THREE.BoxGeometry(9.0, 4.0, 0.25);
    const wallFront = new THREE.Mesh(wallFrontGeo, matDiv);
    wallFront.position.set(0, 2.0, -3.25);
    lockerGroup.add(wallFront);

    // Hoja móvil corredera de la esclusa
    const doorLeafGeo = new THREE.BoxGeometry(1.9, 2.8, 0.08);
    this.airlockDoorMesh = new THREE.Mesh(doorLeafGeo, this.matAirlockDoor);
    this.airlockDoorMesh.position.set(2.5, 1.4, -3.25);
    this.airlockDoorMesh.castShadow = true;
    this.airlockDoorMesh.userData = {
      type: 'airlock_door',
      name: 'Esclusa de Seguridad a Nave de Producción',
      action: 'tryPassAirlock'
    };
    lockerGroup.add(this.airlockDoorMesh);
    this.interactables.push(this.airlockDoorMesh);

    // Terminal de inducción RETIE / LOTO
    const termGeo = new THREE.BoxGeometry(0.25, 0.8, 0.6);
    const matTerm = new THREE.MeshStandardMaterial({ color: 0x1565c0, metalness: 0.5 });
    const terminal = new THREE.Mesh(termGeo, matTerm);
    terminal.position.set(-4.2, 1.5, 0);
    terminal.userData = {
      type: 'safety_induction_terminal',
      name: 'Terminal de Inducción de Seguridad RETIE / LOTO',
      action: 'completeInduction'
    };
    lockerGroup.add(terminal);
    this.interactables.push(terminal);

    // Mesa de dotación de EPP
    const tableTopGeo = new THREE.BoxGeometry(2.4, 0.1, 0.8);
    const tableTop = new THREE.Mesh(tableTopGeo, this.matCurb);
    tableTop.position.set(-1.0, 0.9, 2.0);
    lockerGroup.add(tableTop);

    // Casco amarillo dieléctrico interactivo
    const helmetGeo = new THREE.SphereGeometry(0.16, 16, 16, 0, Math.PI * 2, 0, Math.PI / 2);
    const matHelmet = new THREE.MeshStandardMaterial({ color: 0xffd600, roughness: 0.3 });
    const helmetMesh = new THREE.Mesh(helmetGeo, matHelmet);
    helmetMesh.position.set(-1.8, 0.95, 2.0);
    helmetMesh.userData = { type: 'ppe_item', itemKey: 'helmet', name: 'Casco Dieléctrico Tipo I Clase E (RETIE Art. 20)' };
    lockerGroup.add(helmetMesh);
    this.interactables.push(helmetMesh);

    // Gafas de seguridad
    const glassesGeo = new THREE.BoxGeometry(0.18, 0.06, 0.12);
    const matGlasses = new THREE.MeshStandardMaterial({ color: 0x00e5ff, transparent: true, opacity: 0.8 });
    const glassesMesh = new THREE.Mesh(glassesGeo, matGlasses);
    glassesMesh.position.set(-1.3, 0.98, 2.0);
    glassesMesh.userData = { type: 'ppe_item', itemKey: 'glasses', name: 'Gafas de Seguridad ANSI Z87.1' };
    lockerGroup.add(glassesMesh);
    this.interactables.push(glassesMesh);

    // Copas auditivas
    const earmuffsGeo = new THREE.TorusGeometry(0.1, 0.04, 12, 16, Math.PI);
    const matEarmuffs = new THREE.MeshStandardMaterial({ color: 0xff1744 });
    const earmuffsMesh = new THREE.Mesh(earmuffsGeo, matEarmuffs);
    earmuffsMesh.rotation.x = Math.PI / 2;
    earmuffsMesh.position.set(-0.9, 0.98, 2.0);
    earmuffsMesh.userData = { type: 'ppe_item', itemKey: 'earmuffs', name: 'Copas Auditivas NRR 27 dB (OSHA 1910)' };
    lockerGroup.add(earmuffsMesh);
    this.interactables.push(earmuffsMesh);

    // Botas dieléctricas
    const bootsGeo = new THREE.BoxGeometry(0.25, 0.22, 0.35);
    const matBoots = new THREE.MeshStandardMaterial({ color: 0x212121, roughness: 0.7 });
    const bootsMesh = new THREE.Mesh(bootsGeo, matBoots);
    bootsMesh.position.set(-1.0, 0.11, 1.2);
    bootsMesh.userData = { type: 'ppe_item', itemKey: 'boots', name: 'Botas Dieléctricas ASTM F2413' };
    lockerGroup.add(bootsMesh);
    this.interactables.push(bootsMesh);

    // Guantes dieléctricos Clase 00
    const glovesGeo = new THREE.BoxGeometry(0.18, 0.04, 0.22);
    const matGloves = new THREE.MeshStandardMaterial({ color: 0xbf360c, roughness: 0.6 });
    const glovesMesh = new THREE.Mesh(glovesGeo, matGloves);
    glovesMesh.position.set(-0.5, 0.98, 2.0);
    glovesMesh.userData = { type: 'ppe_item', itemKey: 'gloves', name: 'Guantes Dieléctricos Clase 00 (RETIE / NFPA 70E)' };
    lockerGroup.add(glovesMesh);
    this.interactables.push(glovesMesh);

    // Overol ignífugo
    const suitGeo = new THREE.BoxGeometry(0.4, 0.9, 0.15);
    const matSuit = new THREE.MeshStandardMaterial({ color: 0x0d47a1, roughness: 0.8 });
    const suitMesh = new THREE.Mesh(suitGeo, matSuit);
    suitMesh.position.set(0.1, 1.4, 2.3);
    suitMesh.userData = { type: 'ppe_item', itemKey: 'suit', name: 'Overol Antiestático e Ignífugo (NFPA 70E)' };
    lockerGroup.add(suitMesh);
    this.interactables.push(suitMesh);

    this.scene.add(lockerGroup);
  }

  createFlooringDemarcations() {
    // Corredor peatonal verde pintado en el piso (desde vestidores hasta la maquinaria)
    const walkwayGeo = new THREE.PlaneGeometry(28.0, 2.0);
    const walkway = new THREE.Mesh(walkwayGeo, this.matWalkwayGreen);
    walkway.rotation.x = -Math.PI / 2;
    walkway.position.set(-2.0, 0.003, -3.25);
    this.scene.add(walkway);

    // Demarcación circular RETIE en CCM (X = -6.0, Z = -3.0)
    const ccmDemarcationGeo = new THREE.RingGeometry(1.2, 1.4, 32);
    const ccmDemarcation = new THREE.Mesh(ccmDemarcationGeo, this.matSafetyYellow);
    ccmDemarcation.rotation.x = -Math.PI / 2;
    ccmDemarcation.position.set(-6.0, 0.005, -3.0);
    this.scene.add(ccmDemarcation);

    // Demarcación circular ISO 13857 en Molino y Motor 10 HP (X = 2.0, Z = 0.0)
    const millDemarcationGeo = new THREE.RingGeometry(2.1, 2.3, 32);
    const millDemarcation = new THREE.Mesh(millDemarcationGeo, this.matSafetyYellow);
    millDemarcation.rotation.x = -Math.PI / 2;
    millDemarcation.position.set(2.0, 0.005, 0.0);
    this.scene.add(millDemarcation);
  }

  updateAirlockAnimation(isOpen, dt) {
    if (!this.airlockDoorMesh) return;
    const targetX = isOpen ? 4.2 : 2.5;
    this.airlockDoorMesh.position.x += (targetX - this.airlockDoorMesh.position.x) * Math.min(1.0, 5.0 * dt);
  }
}
export default WarehouseBuilder;
