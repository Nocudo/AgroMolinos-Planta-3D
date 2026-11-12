import * as THREE from 'three';

/**
 * MotorMillAssembly.js - Ensamble Mecatrónico 3D:
 * 1. Motor Trifásico de Inducción Jaula de Ardilla (10 HP, 460 V, 4 polos).
 *    - Carcasa aletada para disipación térmica forzada.
 *    - Caja de bornes NEMA con señalización de riesgo eléctrico RETIE.
 *    - Eje móvil y ventilador centrífugo giratorio.
 * 2. Acople flexible de manguito elastomérico.
 * 3. Molino de martillos industrial con tolva de alimentación cónica, compuerta de inspección con enclavamiento (Interlock)
 *    y tornillo sinfín de descarga.
 */
export class MotorMillAssembly {
  constructor(scene, eventBus) {
    this.scene = scene;
    this.eventBus = eventBus;
    this.group = new THREE.Group();
    this.interactables = [];

    // Partes móviles rotatorias
    this.rotatingParts = [];
    this.millDoorHatch = null;
    this.hopperMesh = null;
    this.isDoorOpen = false;

    // Centro del ensamble en planta
    this.origin = new THREE.Vector3(2.0, 0.0, 0.0);
  }

  build() {
    this.createMaterials();
    this.createBaseplate();
    this.createInductionMotor10HP();
    this.createFlexibleCoupling();
    this.createHammerMill();
    this.group.position.copy(this.origin);
    this.scene.add(this.group);
  }

  createMaterials() {
    // Carcasa del motor (azul industrial Siemens/ABB RAL 5012)
    this.matMotorBody = new THREE.MeshStandardMaterial({
      color: 0x1565c0,
      roughness: 0.35,
      metalness: 0.55
    });

    // Aletas de refrigeración y tapas de rodamientos
    this.matMotorFins = new THREE.MeshStandardMaterial({
      color: 0x0d47a1,
      roughness: 0.45,
      metalness: 0.4
    });

    // Acero pulido para ejes y acople
    this.matSteelShaft = new THREE.MeshStandardMaterial({
      color: 0xcfd8dc,
      roughness: 0.2,
      metalness: 0.9
    });

    // Tolva y molino de martillos (verde industrial o gris maquinaria pesada)
    this.matMillBody = new THREE.MeshStandardMaterial({
      color: 0x37474f,
      roughness: 0.5,
      metalness: 0.6
    });

    // Tolva de alimentación
    this.matHopper = new THREE.MeshStandardMaterial({
      color: 0x546e7a,
      roughness: 0.4,
      metalness: 0.5
    });

    // Compuerta de inspección (con franjas de precaución)
    this.matHatchDoor = new THREE.MeshStandardMaterial({
      color: 0xffb300,
      roughness: 0.4,
      metalness: 0.3
    });

    // Cereal / Grano de maíz en la tolva
    this.matGrain = new THREE.MeshStandardMaterial({
      color: 0xfbc02d,
      roughness: 0.8,
      metalness: 0.05
    });

    // Placa de características técnicas de acero inoxidable
    this.matNameplate = new THREE.MeshStandardMaterial({
      color: 0xe0e0e0,
      roughness: 0.25,
      metalness: 0.85
    });
  }

  createBaseplate() {
    // Bancada de acero soldada sobre tacos de aislamiento elastoméricos
    const baseGeo = new THREE.BoxGeometry(3.6, 0.15, 1.2);
    const matBase = new THREE.MeshStandardMaterial({ color: 0x263238, roughness: 0.6, metalness: 0.4 });
    const baseMesh = new THREE.Mesh(baseGeo, matBase);
    baseMesh.position.set(0.6, 0.075, 0);
    baseMesh.receiveShadow = true;
    baseMesh.castShadow = true;
    this.group.add(baseMesh);

    // 4 tacos de goma antivibratoria
    const padGeo = new THREE.CylinderGeometry(0.08, 0.08, 0.05, 16);
    const matRubber = new THREE.MeshStandardMaterial({ color: 0x111111, roughness: 0.9 });
    for (const [px, pz] of [[-0.9, -0.45], [-0.9, 0.45], [2.1, -0.45], [2.1, 0.45]]) {
      const pad = new THREE.Mesh(padGeo, matRubber);
      pad.position.set(px, 0.025, pz);
      this.group.add(pad);
    }
  }

  createInductionMotor10HP() {
    const motorGroup = new THREE.Group();
    motorGroup.position.set(-0.6, 0.45, 0); // Eje a altura Y = 0.45 m

    // 1. Cuerpo cilíndrico del estator
    const statorGeo = new THREE.CylinderGeometry(0.24, 0.24, 0.52, 24);
    const stator = new THREE.Mesh(statorGeo, this.matMotorBody);
    stator.rotation.z = Math.PI / 2; // Orientado a lo largo del eje X
    stator.castShadow = true;
    stator.receiveShadow = true;
    motorGroup.add(stator);

    // 2. Aletas de refrigeración longitudinales (20 aletas alrededor del perímetro)
    const finGeo = new THREE.BoxGeometry(0.5, 0.04, 0.012);
    for (let i = 0; i < 20; i++) {
      const angle = (i / 20) * Math.PI * 2;
      const fin = new THREE.Mesh(finGeo, this.matMotorFins);
      const radius = 0.24;
      fin.position.set(0, Math.cos(angle) * (radius + 0.02), Math.sin(angle) * (radius + 0.02));
      fin.rotation.x = -angle;
      stator.add(fin);
    }

    // 3. Tapa porta-rodamientos lado acople (DE)
    const capDEGeo = new THREE.CylinderGeometry(0.23, 0.24, 0.08, 24);
    const capDE = new THREE.Mesh(capDEGeo, this.matMotorFins);
    capDE.rotation.z = Math.PI / 2;
    capDE.position.set(0.3, 0, 0);
    motorGroup.add(capDE);

    // 4. Cubierta del ventilador lado opuesto (NDE)
    const cowlGeo = new THREE.CylinderGeometry(0.23, 0.23, 0.14, 24);
    const cowl = new THREE.Mesh(cowlGeo, this.matMotorFins);
    cowl.rotation.z = Math.PI / 2;
    cowl.position.set(-0.33, 0, 0);
    motorGroup.add(cowl);

    // 5. Caja de conexiones NEMA (caja de bornes en la parte superior)
    const jBoxGeo = new THREE.BoxGeometry(0.22, 0.16, 0.18);
    const jBox = new THREE.Mesh(jBoxGeo, this.matMotorBody);
    jBox.position.set(0, 0.29, 0.05);
    jBox.castShadow = true;
    motorGroup.add(jBox);

    // Placa de características RETIE / NEMA
    const nameplateGeo = new THREE.PlaneGeometry(0.18, 0.1);
    const nameplate = new THREE.Mesh(nameplateGeo, this.matNameplate);
    nameplate.position.set(0, 0.05, 0.245);
    motorGroup.add(nameplate);

    // 6. Eje giratorio del motor (conectado a partes rotatorias)
    const shaftGeo = new THREE.CylinderGeometry(0.022, 0.022, 0.32, 16);
    const shaft = new THREE.Mesh(shaftGeo, this.matSteelShaft);
    shaft.rotation.z = Math.PI / 2;
    shaft.position.set(0.42, 0, 0);
    shaft.castShadow = true;
    motorGroup.add(shaft);
    this.rotatingParts.push(shaft);

    // 7. Aspas del ventilador interno NDE (gira con el eje)
    const fanGeo = new THREE.CylinderGeometry(0.19, 0.19, 0.04, 8);
    const matFan = new THREE.MeshStandardMaterial({ color: 0x455a64 });
    const fanMesh = new THREE.Mesh(fanGeo, matFan);
    fanMesh.rotation.z = Math.PI / 2;
    fanMesh.position.set(-0.3, 0, 0);
    motorGroup.add(fanMesh);
    this.rotatingParts.push(fanMesh);

    // Pies de montaje atornillados a la base
    const footGeo = new THREE.BoxGeometry(0.12, 0.18, 0.55);
    const foot1 = new THREE.Mesh(footGeo, this.matMotorFins);
    foot1.position.set(-0.15, -0.16, 0);
    motorGroup.add(foot1);
    const foot2 = new THREE.Mesh(footGeo, this.matMotorFins);
    foot2.position.set(0.15, -0.16, 0);
    motorGroup.add(foot2);

    this.group.add(motorGroup);
  }

  createFlexibleCoupling() {
    // Acoplamiento elástico entre motor y molino (X = 0.05 a 0.25)
    const couplingGroup = new THREE.Group();
    couplingGroup.position.set(0.15, 0.45, 0);

    const flangeGeo = new THREE.CylinderGeometry(0.075, 0.075, 0.16, 16);
    const flange = new THREE.Mesh(flangeGeo, this.matSteelShaft);
    flange.rotation.z = Math.PI / 2;
    flange.castShadow = true;
    couplingGroup.add(flange);
    this.rotatingParts.push(flange);

    // Guarda de protección de acople (según OSHA / ISO 13857)
    const guardGeo = new THREE.CylinderGeometry(0.12, 0.12, 0.26, 16, 1, true, 0, Math.PI);
    const matGuard = new THREE.MeshStandardMaterial({ color: 0xfbc02d, roughness: 0.5 });
    const guard = new THREE.Mesh(guardGeo, matGuard);
    guard.rotation.z = Math.PI / 2;
    guard.position.set(0, 0.02, 0);
    couplingGroup.add(guard);

    this.group.add(couplingGroup);
  }

  createHammerMill() {
    const millGroup = new THREE.Group();
    millGroup.position.set(1.4, 0.0, 0);

    // 1. Cámara de trituración cilíndrica del molino de martillos
    const chamberGeo = new THREE.CylinderGeometry(0.55, 0.55, 0.7, 24);
    const chamber = new THREE.Mesh(chamberGeo, this.matMillBody);
    chamber.rotation.z = Math.PI / 2;
    chamber.position.set(0.35, 0.7, 0);
    chamber.castShadow = true;
    chamber.receiveShadow = true;
    millGroup.add(chamber);

    // 2. Rotor interno de martillos giratorio
    const rotorHubGeo = new THREE.CylinderGeometry(0.045, 0.045, 0.65, 16);
    const rotorHub = new THREE.Mesh(rotorHubGeo, this.matSteelShaft);
    rotorHub.rotation.z = Math.PI / 2;
    rotorHub.position.set(0.35, 0.7, 0);
    millGroup.add(rotorHub);
    this.rotatingParts.push(rotorHub);

    // 3. Tolva de alimentación superior piramidal
    const hopperGeo = new THREE.ConeGeometry(0.65, 0.9, 4);
    this.hopperMesh = new THREE.Mesh(hopperGeo, this.matHopper);
    this.hopperMesh.rotation.y = Math.PI / 4;
    this.hopperMesh.position.set(0.35, 1.65, 0);
    this.hopperMesh.castShadow = true;
    this.hopperMesh.userData = {
      type: 'grain_hopper',
      name: 'Tolva de Alimentación de Cereal (500 kg)',
      action: 'refillHopper'
    };
    millGroup.add(this.hopperMesh);
    this.interactables.push(this.hopperMesh);

    // Grano visible en el tope de la tolva
    const grainGeo = new THREE.CylinderGeometry(0.4, 0.1, 0.15, 16);
    const grain = new THREE.Mesh(grainGeo, this.matGrain);
    grain.position.set(0.35, 2.05, 0);
    millGroup.add(grain);

    // 4. Compuerta de inspección frontal (Interlock de seguridad con microswitch)
    const hatchGeo = new THREE.BoxGeometry(0.3, 0.35, 0.04);
    this.millDoorHatch = new THREE.Mesh(hatchGeo, this.matHatchDoor);
    this.millDoorHatch.position.set(0.35, 0.7, 0.56);
    this.millDoorHatch.castShadow = true;
    this.millDoorHatch.userData = {
      type: 'mill_door_interlock',
      name: 'Compuerta de Inspección con Microswitch Interlock (ISO 13857)',
      action: 'toggleMillDoor'
    };
    millGroup.add(this.millDoorHatch);
    this.interactables.push(this.millDoorHatch);

    // 5. Conducto inferior de descarga y tornillo sinfín
    const dischargeGeo = new THREE.CylinderGeometry(0.18, 0.18, 1.2, 16);
    const discharge = new THREE.Mesh(dischargeGeo, this.matMillBody);
    discharge.position.set(0.35, 0.15, 0);
    discharge.rotation.z = Math.PI / 2;
    millGroup.add(discharge);

    // 6. Ducto de aspiración de polvo hacia el ciclón ATEX (superior lateral)
    const ductGeo = new THREE.CylinderGeometry(0.1, 0.1, 2.2, 16);
    const duct = new THREE.Mesh(ductGeo, this.matSteelShaft);
    duct.position.set(0.8, 1.8, 0.8);
    duct.rotation.x = Math.PI / 4;
    millGroup.add(duct);

    this.group.add(millGroup);
  }

  /**
   * Actualiza la rotación de los componentes mecánicos y la apertura de la compuerta.
   * @param {number} dt 
   * @param {number} angleRad - Ángulo instantáneo del rotor.
   * @param {number} vibrationRMS - Nivel de vibración para inducir jitter.
   */
  update(dt, angleRad, vibrationRMS = 0.6) {
    // 1. Rotación de ejes y partes rotatorias
    for (const part of this.rotatingParts) {
      part.rotation.x = angleRad;
    }

    // 2. Micro-vibración en la bancada si hay severidad ISO 10816-3 elevada
    if (vibrationRMS > 2.3) {
      const jitterAmp = Math.min(0.006, (vibrationRMS / 10.0) * 0.005);
      this.group.position.x = this.origin.x + (Math.random() - 0.5) * jitterAmp;
      this.group.position.y = this.origin.y + Math.abs(Math.random() - 0.5) * jitterAmp;
    } else {
      this.group.position.copy(this.origin);
    }
  }

  /**
   * Conmuta la posición visual de la compuerta de inspección.
   * @param {boolean} isOpen 
   */
  setDoorOpenVisual(isOpen) {
    this.isDoorOpen = isOpen;
    if (this.millDoorHatch) {
      this.millDoorHatch.position.z = isOpen ? 0.78 : 0.56;
      this.millDoorHatch.rotation.y = isOpen ? 0.6 : 0.0;
    }
  }
}
export default MotorMillAssembly;
