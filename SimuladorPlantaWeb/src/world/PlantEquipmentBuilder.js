import * as THREE from 'three';

/**
 * PlantEquipmentBuilder.js - Constructor de Maquinaria Pesada e Infraestructura Industrial:
 * 1. Batería de Silos de Almacenamiento de Cereal (2 silos gigantes de 9.5m con escaleras de caracol).
 * 2. Elevador Vertical de Cangilones (Bucket Elevator de 12.5m).
 * 3. Cinta Transportadora de Grano inclinada hacia la tolva del molino de 10 HP.
 * 4. Batería de Ciclones de Aspiración y Filtro de Mangas ATEX / NFPA 68.
 * 5. Red Aérea de Tuberías de Proceso (ASME A13.1) con bridas, manómetros y válvulas de volante.
 * 6. Estación de Ducha y Lavaojos de Emergencia (ANSI Z358.1) y Extintores Rodantes de 50 kg.
 * 7. Almacén de Paletización con sacos de harina apilados y tambores de lubricante industrial.
 */
export class PlantEquipmentBuilder {
  constructor(scene, eventBus) {
    this.scene = scene;
    this.eventBus = eventBus;
    this.group = new THREE.Group();
    this.interactables = [];
    this.animatedBelts = [];
  }

  build() {
    this.createMaterials();
    this.createGrainSilos();
    this.createBucketElevator();
    this.createInclinedConveyor();
    this.createAtexCycloneAndBaghouse();
    this.createPipingNetwork();
    this.createFinishedGoodsPallets();
    this.createSafetyShowersAndExtinguishers();

    this.scene.add(this.group);
  }

  createMaterials() {
    // Acero galvanizado corrugado para silos
    this.matGalvanized = new THREE.MeshStandardMaterial({
      color: 0xb0bec5,
      roughness: 0.35,
      metalness: 0.85
    });

    // Acero estructural para soportes y patas
    this.matSteelLegs = new THREE.MeshStandardMaterial({
      color: 0x263238,
      roughness: 0.5,
      metalness: 0.7
    });

    // Tolvas cónicas de descarga (Gris oscuro)
    this.matHopperCone = new THREE.MeshStandardMaterial({
      color: 0x455a64,
      roughness: 0.45,
      metalness: 0.6
    });

    // Cinta de caucho vulcanizado negra
    this.matRubberBelt = new THREE.MeshStandardMaterial({
      color: 0x1a1a1a,
      roughness: 0.9,
      metalness: 0.1
    });

    // Grano de maíz dorado
    this.matCorn = new THREE.MeshStandardMaterial({
      color: 0xfbc02d,
      roughness: 0.8
    });

    // Tuberías de proceso según código de colores ASME A13.1:
    this.matPipeAtexYellow = new THREE.MeshStandardMaterial({ color: 0xfdd835, roughness: 0.35, metalness: 0.4 }); // Polvo ATEX
    this.matPipeAirBlue = new THREE.MeshStandardMaterial({ color: 0x0288d1, roughness: 0.35, metalness: 0.4 });    // Aire comprimido
    this.matPipeWaterGreen = new THREE.MeshStandardMaterial({ color: 0x388e3c, roughness: 0.35, metalness: 0.4 }); // Agua
    this.matPipeFireRed = new THREE.MeshStandardMaterial({ color: 0xd32f2f, roughness: 0.35, metalness: 0.4 });    // Red contraincendios

    // Válvulas manuales (volante rojo)
    this.matValveWheel = new THREE.MeshStandardMaterial({ color: 0xc62828, roughness: 0.3, metalness: 0.6 });

    // Ducha de emergencia (Verde seguridad)
    this.matSafetyGreen = new THREE.MeshStandardMaterial({ color: 0x00c853, roughness: 0.4 });

    // Sacos de harina blancos
    this.matFlourSack = new THREE.MeshStandardMaterial({ color: 0xf5f5f5, roughness: 0.9 });

    // Madera para palets
    this.matWoodPallet = new THREE.MeshStandardMaterial({ color: 0x8d6e63, roughness: 0.8 });

    // Tambor de aceite ISO VG 46 (Azul petroquímico)
    this.matOilDrum = new THREE.MeshStandardMaterial({ color: 0x0d47a1, roughness: 0.3, metalness: 0.7 });
  }

  createGrainSilos() {
    // 2 Grandes Silos Cilíndricos en X = 17.0m, Z = -6.0m y Z = +4.5m
    const siloZPositions = [-6.0, 4.5];

    siloZPositions.forEach((zPos, idx) => {
      const siloGroup = new THREE.Group();
      siloGroup.position.set(17.0, 0, zPos);

      const radius = 2.6;
      const cylHeight = 5.8;

      // 1. Cuerpo cilíndrico del silo a Y = 4.5m a 10.3m
      const cylGeo = new THREE.CylinderGeometry(radius, radius, cylHeight, 32);
      const cylinder = new THREE.Mesh(cylGeo, this.matGalvanized);
      cylinder.position.set(0, 5.8, 0);
      cylinder.castShadow = true;
      cylinder.receiveShadow = true;
      siloGroup.add(cylinder);

      // Anillos de refuerzo estructural circunferenciales (Stiffener rings)
      const ringGeo = new THREE.TorusGeometry(radius + 0.04, 0.035, 8, 32);
      for (let ry = 3.5; ry <= 8.2; ry += 1.1) {
        const ring = new THREE.Mesh(ringGeo, this.matSteelLegs);
        ring.rotation.x = Math.PI / 2;
        ring.position.set(0, ry, 0);
        siloGroup.add(ring);
      }

      // 2. Techo cónico superior con compuerta de inspección
      const roofGeo = new THREE.ConeGeometry(radius + 0.15, 1.6, 32);
      const roof = new THREE.Mesh(roofGeo, this.matGalvanized);
      roof.position.set(0, 5.8 + cylHeight / 2 + 0.8, 0);
      roof.castShadow = true;
      siloGroup.add(roof);

      // 3. Tolva cónica inferior de descarga
      const hopperGeo = new THREE.ConeGeometry(radius, 2.4, 32);
      const hopper = new THREE.Mesh(hopperGeo, this.matHopperCone);
      hopper.rotation.x = Math.PI; // Cono invertido
      hopper.position.set(0, 1.8, 0);
      hopper.castShadow = true;
      siloGroup.add(hopper);

      // Válvula rotativa de descarga inferior
      const valveGeo = new THREE.CylinderGeometry(0.25, 0.25, 0.5, 16);
      const valve = new THREE.Mesh(valveGeo, this.matSteelLegs);
      valve.position.set(0, 0.45, 0);
      siloGroup.add(valve);

      // 4. Columnas de soporte de acero tubular (6 patas perimetrales)
      const legGeo = new THREE.CylinderGeometry(0.12, 0.12, 3.2, 16);
      for (let i = 0; i < 6; i++) {
        const angle = (i / 6) * Math.PI * 2;
        const lx = Math.cos(angle) * (radius - 0.2);
        const lz = Math.sin(angle) * (radius - 0.2);
        const leg = new THREE.Mesh(legGeo, this.matSteelLegs);
        leg.position.set(lx, 1.6, lz);
        leg.castShadow = true;
        siloGroup.add(leg);
      }

      // Escalera de caracol de acceso en el Silo 1
      if (idx === 0) {
        this.createSpiralStairs(siloGroup, radius + 0.2, 8.8);
      }

      this.group.add(siloGroup);
    });
  }

  createSpiralStairs(siloGroup, radius, maxHeight) {
    const stepCount = 36;
    const stepRise = maxHeight / stepCount;
    const stepGeo = new THREE.BoxGeometry(0.75, 0.04, 0.24);

    for (let i = 0; i < stepCount; i++) {
      const angle = (i / stepCount) * Math.PI * 2.5;
      const x = Math.cos(angle) * radius;
      const z = Math.sin(angle) * radius;
      const y = i * stepRise + 0.8;

      const step = new THREE.Mesh(stepGeo, this.matGalvanized);
      step.position.set(x, y, z);
      step.rotation.y = -angle;
      step.castShadow = true;
      siloGroup.add(step);
    }
  }

  createBucketElevator() {
    // Elevador vertical de cangilones en X = 13.0m, Z = -1.0m (Altura 12.0m)
    const elevGroup = new THREE.Group();
    elevGroup.position.set(13.0, 0, -1.0);

    // Fuste rectangular de doble ramal galvanizado
    const trunkGeo = new THREE.BoxGeometry(0.8, 11.5, 1.4);
    const trunk = new THREE.Mesh(trunkGeo, this.matGalvanized);
    trunk.position.set(0, 5.75, 0);
    trunk.castShadow = true;
    elevGroup.add(trunk);

    // Cabezal superior motriz (Head section) con motorreductor
    const headGeo = new THREE.BoxGeometry(1.2, 1.4, 1.8);
    const matHead = new THREE.MeshStandardMaterial({ color: 0x1565c0, roughness: 0.4 });
    const head = new THREE.Mesh(headGeo, matHead);
    head.position.set(0, 11.8, 0);
    elevGroup.add(head);

    // Ductos de descarga hacia los dos silos
    const chuteGeo = new THREE.CylinderGeometry(0.14, 0.14, 4.2, 16);
    const chute1 = new THREE.Mesh(chuteGeo, this.matPipeAtexYellow);
    chute1.position.set(2.0, 10.5, -2.4);
    chute1.rotation.set(0.6, 0, -0.4);
    elevGroup.add(chute1);

    const chute2 = new THREE.Mesh(chuteGeo, this.matPipeAtexYellow);
    chute2.position.set(2.0, 10.5, 2.6);
    chute2.rotation.set(-0.6, 0, -0.4);
    elevGroup.add(chute2);

    this.group.add(elevGroup);
  }

  createInclinedConveyor() {
    // Cinta transportadora que alimenta desde los silos hacia la tolva del molino en X = 2.4m, Y = 2.1m, Z = 0m
    const convGroup = new THREE.Group();
    convGroup.position.set(9.5, 1.8, -0.2);
    convGroup.rotation.z = 0.12; // Inclinación suave ascendente hacia el molino

    // Estructura en celosía de 11 metros
    const trussGeo = new THREE.BoxGeometry(11.0, 0.4, 0.9);
    const truss = new THREE.Mesh(trussGeo, this.matSteelLegs);
    truss.castShadow = true;
    convGroup.add(truss);

    // Banda de caucho negra móvil
    const beltGeo = new THREE.BoxGeometry(10.8, 0.05, 0.7);
    const belt = new THREE.Mesh(beltGeo, this.matRubberBelt);
    belt.position.set(0, 0.22, 0);
    convGroup.add(belt);

    // Capa de cereal triturado en tránsito
    const grainStreamGeo = new THREE.BoxGeometry(10.5, 0.04, 0.5);
    const grainStream = new THREE.Mesh(grainStreamGeo, this.matCorn);
    grainStream.position.set(0, 0.25, 0);
    convGroup.add(grainStream);

    // Tolva de recepción / embudo hacia el molino en el extremo
    const dropChuteGeo = new THREE.CylinderGeometry(0.2, 0.14, 1.0, 16);
    const dropChute = new THREE.Mesh(dropChuteGeo, this.matHopperCone);
    dropChute.position.set(-5.4, -0.4, 0);
    convGroup.add(dropChute);

    this.group.add(convGroup);
  }

  createAtexCycloneAndBaghouse() {
    // Sistema Ciclónico de Aspiración y Filtro de Mangas en X = 7.5m, Z = 7.5m
    const atexGroup = new THREE.Group();
    atexGroup.position.set(7.5, 0, 7.5);

    // 1. Ciclón separador de alta eficiencia
    const cycloneGroup = new THREE.Group();
    cycloneGroup.position.set(0, 0, 0);

    // Cilindro superior con entrada tangencial
    const cyTopGeo = new THREE.CylinderGeometry(1.2, 1.2, 2.2, 24);
    const cyTop = new THREE.Mesh(cyTopGeo, this.matPipeAtexYellow);
    cyTop.position.set(0, 4.0, 0);
    cycloneGroup.add(cyTop);

    // Cono invertido inferior
    const cyConeGeo = new THREE.ConeGeometry(1.2, 2.4, 24);
    const cyCone = new THREE.Mesh(cyConeGeo, this.matPipeAtexYellow);
    cyCone.rotation.x = Math.PI;
    cyCone.position.set(0, 1.8, 0);
    cycloneGroup.add(cyCone);

    // Esclusa rotativa inferior
    const airlockGeo = new THREE.BoxGeometry(0.6, 0.5, 0.6);
    const airlock = new THREE.Mesh(airlockGeo, this.matSteelLegs);
    airlock.position.set(0, 0.4, 0);
    cycloneGroup.add(airlock);

    // Patas de soporte del ciclón
    const legGeo = new THREE.CylinderGeometry(0.08, 0.08, 3.2, 12);
    for (const [lx, lz] of [[-0.9, -0.9], [0.9, -0.9], [-0.9, 0.9], [0.9, 0.9]]) {
      const leg = new THREE.Mesh(legGeo, this.matSteelLegs);
      leg.position.set(lx, 1.6, lz);
      cycloneGroup.add(leg);
    }
    atexGroup.add(cycloneGroup);

    // 2. Filtro de Mangas (Baghouse Dust Collector)
    const baghouseGeo = new THREE.BoxGeometry(2.4, 4.2, 2.0);
    const matBaghouse = new THREE.MeshStandardMaterial({ color: 0x546e7a, metalness: 0.6, roughness: 0.4 });
    const baghouse = new THREE.Mesh(baghouseGeo, matBaghouse);
    baghouse.position.set(3.2, 2.8, 0);
    baghouse.castShadow = true;
    atexGroup.add(baghouse);

    // Paneles de venteo de explosión (Explosion Relief Vents NFPA 68) en la parte superior
    const ventPanelGeo = new THREE.PlaneGeometry(0.8, 1.2);
    const matVent = new THREE.MeshBasicMaterial({ color: 0xff1744 });
    const ventPanel = new THREE.Mesh(ventPanelGeo, matVent);
    ventPanel.rotation.x = -Math.PI / 2;
    ventPanel.position.set(3.2, 4.91, 0);
    atexGroup.add(ventPanel);

    // Ventilador centrífugo extractor acoplado
    const fanGeo = new THREE.CylinderGeometry(0.7, 0.7, 0.8, 16);
    const fan = new THREE.Mesh(fanGeo, this.matSteelLegs);
    fan.rotation.z = Math.PI / 2;
    fan.position.set(5.0, 1.2, 0);
    atexGroup.add(fan);

    // Chimenea vertical de descarga a través del techo
    const stackGeo = new THREE.CylinderGeometry(0.3, 0.3, 6.0, 16);
    const stack = new THREE.Mesh(stackGeo, this.matGalvanized);
    stack.position.set(5.0, 5.0, 0);
    atexGroup.add(stack);

    this.group.add(atexGroup);
  }

  createPipingNetwork() {
    // Red aérea de tuberías industriales (ASME A13.1) suspendidas a Y = 6.2m
    const pipeGroup = new THREE.Group();
    pipeGroup.position.set(0, 6.2, 0);

    // Tubería Amarilla ATEX (conducción de polvo desde el molino al ciclón)
    const atexPipeGeo = new THREE.CylinderGeometry(0.12, 0.12, 16.0, 16);
    const atexPipe = new THREE.Mesh(atexPipeGeo, this.matPipeAtexYellow);
    atexPipe.rotation.x = Math.PI / 2;
    atexPipe.position.set(4.5, 0, 3.0);
    pipeGroup.add(atexPipe);

    // Tubería Azul (Aire comprimido 6 bar) a lo largo de toda la nave (X: -20m a +20m)
    const airPipeGeo = new THREE.CylinderGeometry(0.06, 0.06, 40.0, 16);
    const airPipe = new THREE.Mesh(airPipeGeo, this.matPipeAirBlue);
    airPipe.rotation.z = Math.PI / 2;
    airPipe.position.set(0, 0.3, -4.5);
    pipeGroup.add(airPipe);

    // Tubería Roja (Red Contraincendios con rociadores)
    const firePipeGeo = new THREE.CylinderGeometry(0.08, 0.08, 40.0, 16);
    const firePipe = new THREE.Mesh(firePipeGeo, this.matPipeFireRed);
    firePipe.rotation.z = Math.PI / 2;
    firePipe.position.set(0, 0.6, 4.5);
    pipeGroup.add(firePipe);

    // Rociadores automáticos (Sprinklers) cada 6 metros
    const sprinklerGeo = new THREE.ConeGeometry(0.05, 0.1, 8);
    for (let x = -18.0; x <= 18.0; x += 6.0) {
      const sprinkler = new THREE.Mesh(sprinklerGeo, this.matValveWheel);
      sprinkler.position.set(x, 0.52, 4.5);
      pipeGroup.add(sprinkler);
    }

    // Válvulas manuales de volante en tuberías
    this.createValve(pipeGroup, -5.0, 0.3, -4.5, this.matValveWheel);
    this.createValve(pipeGroup, 10.0, 0.3, -4.5, this.matValveWheel);

    this.group.add(pipeGroup);
  }

  createValve(parentGroup, x, y, z, matWheel) {
    const valveGroup = new THREE.Group();
    valveGroup.position.set(x, y, z);

    // Cuerpo de válvula
    const bodyGeo = new THREE.SphereGeometry(0.12, 12, 12);
    const body = new THREE.Mesh(bodyGeo, this.matSteelLegs);
    valveGroup.add(body);

    // Vástago y volante circular
    const stemGeo = new THREE.CylinderGeometry(0.02, 0.02, 0.25, 8);
    const stem = new THREE.Mesh(stemGeo, this.matSteelLegs);
    stem.position.set(0, 0.15, 0);
    valveGroup.add(stem);

    const wheelGeo = new THREE.TorusGeometry(0.12, 0.025, 8, 16);
    const wheel = new THREE.Mesh(wheelGeo, matWheel);
    wheel.rotation.x = Math.PI / 2;
    wheel.position.set(0, 0.28, 0);
    valveGroup.add(wheel);

    parentGroup.add(valveGroup);
  }

  createFinishedGoodsPallets() {
    // Zona de almacenamiento de producto terminado en X = -6.0m a +2.0m, Z = -11.0m
    const warehouseGroup = new THREE.Group();
    warehouseGroup.position.set(-2.0, 0, -10.0);

    // Filas de palets de madera con sacos de harina apilados
    const palletGeo = new THREE.BoxGeometry(1.2, 0.14, 1.0);
    const sackGeo = new THREE.BoxGeometry(0.45, 0.2, 0.3);

    for (let px = -4.0; px <= 4.0; px += 2.0) {
      for (let pz = -1.5; pz <= 1.5; pz += 1.5) {
        // Palet de base
        const pallet = new THREE.Mesh(palletGeo, this.matWoodPallet);
        pallet.position.set(px, 0.07, pz);
        pallet.castShadow = true;
        warehouseGroup.add(pallet);

        // Sacos apilados en 3 capas
        for (let layer = 0; layer < 3; layer++) {
          const sy = 0.22 + layer * 0.2;
          for (const sx of [-0.25, 0.25]) {
            for (const sz of [-0.2, 0.2]) {
              const sack = new THREE.Mesh(sackGeo, this.matFlourSack);
              sack.position.set(px + sx, sy, pz + sz);
              sack.castShadow = true;
              warehouseGroup.add(sack);
            }
          }
        }
      }
    }

    // Estación de tambores de lubricante industrial ISO VG 46 en bandeja antiderrame
    const bundGeo = new THREE.BoxGeometry(1.4, 0.15, 1.4);
    const bund = new THREE.Mesh(bundGeo, this.matSafetyYellow);
    bund.position.set(6.5, 0.075, -10.0);
    warehouseGroup.add(bund);

    const drumGeo = new THREE.CylinderGeometry(0.28, 0.28, 0.9, 16);
    for (const [dx, dz] of [[-0.35, -0.35], [0.35, -0.35], [-0.35, 0.35], [0.35, 0.35]]) {
      const drum = new THREE.Mesh(drumGeo, this.matOilDrum);
      drum.position.set(6.5 + dx, 0.55, -10.0 + dz);
      drum.castShadow = true;
      warehouseGroup.add(drum);
    }

    this.group.add(warehouseGroup);
  }

  createSafetyShowersAndExtinguishers() {
    // 1. Estación combinada de ducha y lavaojos de emergencia (ANSI Z358.1) en X = -10.0m, Z = -3.5m
    const showerGroup = new THREE.Group();
    showerGroup.position.set(-10.0, 0, -3.5);

    // Tubería vertical verde
    const pipeGeo = new THREE.CylinderGeometry(0.04, 0.04, 2.4, 12);
    const pipe = new THREE.Mesh(pipeGeo, this.matSafetyGreen);
    pipe.position.set(0, 1.2, 0);
    showerGroup.add(pipe);

    // Campana de ducha superior
    const headGeo = new THREE.ConeGeometry(0.2, 0.15, 16);
    const head = new THREE.Mesh(headGeo, this.matSafetyYellow);
    head.rotation.x = Math.PI;
    head.position.set(0, 2.35, 0.3);
    showerGroup.add(head);

    // Cuenco de lavaojos inferior a Y = 1.0m
    const bowlGeo = new THREE.CylinderGeometry(0.2, 0.12, 0.15, 16);
    const bowl = new THREE.Mesh(bowlGeo, this.matSafetyYellow);
    bowl.position.set(0, 1.0, 0.25);
    showerGroup.add(bowl);

    this.group.add(showerGroup);

    // 2. Extintor rodante de 50 kg PQS (Polvo Químico Seco) con ruedas en X = 0.0m, Z = -3.5m
    const extGroup = new THREE.Group();
    extGroup.position.set(0.0, 0, -3.5);

    const cylGeo = new THREE.CylinderGeometry(0.22, 0.22, 1.1, 16);
    const matExt = new THREE.MeshStandardMaterial({ color: 0xd32f2f, metalness: 0.5 });
    const cyl = new THREE.Mesh(cylGeo, matExt);
    cyl.position.set(0, 0.65, 0);
    cyl.castShadow = true;
    extGroup.add(cyl);

    // Ruedas de goma
    const wheelGeo = new THREE.CylinderGeometry(0.18, 0.18, 0.06, 16);
    const matWheel = new THREE.MeshStandardMaterial({ color: 0x111111 });
    const w1 = new THREE.Mesh(wheelGeo, matWheel);
    w1.rotation.z = Math.PI / 2;
    w1.position.set(-0.26, 0.18, -0.1);
    extGroup.add(w1);

    const w2 = new THREE.Mesh(wheelGeo, matWheel);
    w2.rotation.z = Math.PI / 2;
    w2.position.set(0.26, 0.18, -0.1);
    extGroup.add(w2);

    this.group.add(extGroup);
  }
}
export default PlantEquipmentBuilder;
