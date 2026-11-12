import * as THREE from 'three';
import { globalEventBus } from './core/EventBus.js';
import { SceneManager } from './core/SceneManager.js';
import { ControlsManager } from './core/ControlsManager.js';

import { InductionMotor } from './physics/InductionMotor.js';
import { VFDController } from './physics/VFDController.js';
import { ThermalModel } from './physics/ThermalModel.js';
import { MechanicalLoad } from './physics/MechanicalLoad.js';

import { IndustrialSafety } from './safety/IndustrialSafety.js';
import { OperatorPPEInventory } from './safety/OperatorPPEInventory.js';
import { SafetyZones } from './safety/SafetyZones.js';

import { WarehouseBuilder } from './world/WarehouseBuilder.js';
import { MotorMillAssembly } from './world/MotorMillAssembly.js';
import { CCMPanel } from './world/CCMPanel.js';
import { DustParticleCloud } from './world/DustParticleCloud.js';
import { PlantEquipmentBuilder } from './world/PlantEquipmentBuilder.js';
import { GLTFAssetManager } from './world/GLTFAssetManager.js';

import { SCADAInterface } from './ui/SCADAInterface.js';
import { AndonVisualizer } from './ui/AndonVisualizer.js';
import { FaultInjectorUI } from './ui/FaultInjectorUI.js';
import { IndustrialAudio } from './audio/IndustrialAudio.js';

/**
 * main.js - Punto de entrada principal del Simulador 3D de Planta Industrial (Molino de Granos).
 * Integra el bucle de renderizado WebGL a 60 FPS con el motor multifísico, seguridad RETIE/OSHA
 * y telemetría SCADA.
 */
class IndustrialPlantSimulationApp {
  constructor() {
    this.eventBus = globalEventBus;

    // 1. Núcleo gráfico 3D
    const container = document.getElementById('canvas-container');
    this.sceneManager = new SceneManager(container);

    // 2. Modelado de mundo 3D
    this.warehouse = new WarehouseBuilder(this.sceneManager.scene);
    this.warehouse.build();

    this.equipment = new PlantEquipmentBuilder(this.sceneManager.scene, this.eventBus);
    this.equipment.build();

    this.motorMill = new MotorMillAssembly(this.sceneManager.scene, this.eventBus);
    this.motorMill.build();

    this.ccmPanel = new CCMPanel(this.sceneManager.scene, this.eventBus);
    this.ccmPanel.build();

    this.dustParticles = new DustParticleCloud(this.sceneManager.scene);
    this.dustParticles.build();

    // 2.1 Carga asíncrona de modelos GLB industriales (Montacargas, estanterías, tolvas, cintas)
    this.gltfManager = new GLTFAssetManager(this.sceneManager.scene, this.eventBus);
    this.gltfManager.loadAllAssets();

    // 3. Controles y Raycast interactivo
    this.controls = new ControlsManager(this.sceneManager.camera, container, this.eventBus);
    const allInteractables = [
      ...this.warehouse.interactables,
      ...this.equipment.interactables,
      ...this.motorMill.interactables,
      ...this.ccmPanel.interactables
    ];
    this.controls.setInteractables(allInteractables);

    // 4. Modelos de física y accionamiento
    this.motor = new InductionMotor();
    this.vfd = new VFDController(this.eventBus);
    this.thermal = new ThermalModel(this.eventBus);
    this.mechLoad = new MechanicalLoad(this.eventBus);

    // 5. Seguridad industrial y EPP
    this.safety = new IndustrialSafety(this.eventBus);
    this.ppe = new OperatorPPEInventory(this.eventBus);
    this.safetyZones = new SafetyZones(this.eventBus);

    // 6. UI, SCADA y Baliza Andon
    this.scada = new SCADAInterface(this.eventBus);
    this.andon = new AndonVisualizer(this.eventBus, this.ccmPanel);
    this.faultInjector = new FaultInjectorUI(this.eventBus, this.safety, this.ppe, this.motor, this.thermal);

    // 7. Audio procedural Web Audio
    this.audio = new IndustrialAudio(this.eventBus);

    // Reloj de animación
    this.clock = new THREE.Clock();

    this.setupEventInteractions();
    this.startAnimationLoop();
  }

  setupEventInteractions() {
    // Comandos de VFD desde SCADA o panel
    this.eventBus.on('vfd:command', (data) => {
      if (data.action === 'start') {
        if (this.safety.eStopEngaged) {
          this.eventBus.emit('ui:toast', { type: 'error', title: 'Arranque Denegado', message: 'E-Stop activado.' });
          return;
        }
        if (this.safety.millInspectionDoorOpen) {
          this.eventBus.emit('ui:toast', { type: 'error', title: 'Interlock Abierto', message: 'La compuerta del molino está abierta.' });
          return;
        }
        if (this.safety.lotoState.step1_circuitOpened) {
          this.eventBus.emit('ui:toast', { type: 'error', title: 'CCM Sin Energía', message: 'El seccionador principal está abierto (LOTO).' });
          return;
        }
        this.vfd.start();
      } else if (data.action === 'stop') {
        this.vfd.stop();
      } else if (data.action === 'eStop') {
        this.vfd.emergencyStop(data.reason || 'E-Stop');
      }
    });

    this.eventBus.on('vfd:setFrequency', (freq) => {
      this.vfd.setTargetFrequency(freq);
    });

    this.eventBus.on('mill:setFeedRate', (rate) => {
      this.mechLoad.setFeedRate(rate);
    });

    this.eventBus.on('safety:triggerEStop', (data) => {
      this.safety.triggerEStop(data.source);
    });

    this.eventBus.on('safety:reset', () => {
      const okSafety = this.safety.resetSafetyCircuit();
      if (okSafety) {
        this.vfd.resetFault();
      }
    });

    this.eventBus.on('safety:toggleCyclone', () => {
      this.safety.toggleDustCyclone();
    });

    // Disparo por sobrecarga térmica
    this.eventBus.on('thermal:overload', (data) => {
      this.vfd.emergencyStop(`Disparo por Relé Térmico: Temperatura devanado ${data.temperature.toFixed(1)} °C >= ${data.threshold} °C`);
    });

    // Interacción mediante raycast en 3D
    this.eventBus.on('interaction:execute', (data) => {
      this.handleObjectInteraction(data);
    });

    // Sincronización del estado de la esclusa con las colisiones
    this.eventBus.on('safety:airlock', (data) => {
      this.controls.setAirlockState(data.open);
    });
  }

  handleObjectInteraction(data) {
    if (!data) return;

    switch (data.type) {
      case 'ppe_item':
        this.ppe.togglePPE(data.itemKey);
        this.faultInjector.updatePpeCheckboxes();
        break;

      case 'safety_induction_terminal':
        this.ppe.completeInduction();
        break;

      case 'airlock_door':
        this.ppe.tryPassAirlock();
        break;

      case 'grain_hopper':
        this.mechLoad.refillHopper();
        this.eventBus.emit('ui:toast', {
          type: 'success',
          title: 'Tolva Recargada',
          message: 'Se cargaron 350 kg de grano de maíz. Alimentación al 65%.'
        });
        break;

      case 'mill_door_interlock':
        const isOpen = this.safety.toggleMillDoor(this.motor.Nr);
        this.motorMill.setDoorOpenVisual(isOpen);
        break;

      case 'loto_disconnect':
        this.safety.toggleLotoStep(1, this.motor.appliedVoltageLL);
        this.ccmPanel.setDisconnectState(this.safety.lotoState.step1_circuitOpened);
        if (this.safety.lotoState.step1_circuitOpened) {
          this.vfd.stop();
        }
        break;

      case 'loto_padlock':
        this.safety.toggleLotoStep(2);
        this.ccmPanel.setPadlockVisible(this.safety.lotoState.step2_padlockApplied);
        break;

      case 'loto_voltage_check':
        this.safety.toggleLotoStep(3, this.safety.lotoState.step1_circuitOpened ? 0.0 : this.vfd.outputVoltage);
        break;

      case 'e_stop_button':
        if (this.safety.eStopEngaged) {
          this.safety.releaseEStop();
          this.ccmPanel.setEStopPosition(false);
        } else {
          this.safety.triggerEStop('Pulsador Hongo CCM');
          this.ccmPanel.setEStopPosition(true);
        }
        break;

      case 'vfd_start':
        this.eventBus.emit('vfd:command', { action: 'start' });
        break;

      case 'vfd_stop':
        this.eventBus.emit('vfd:command', { action: 'stop' });
        break;

      case 'safety_reset':
        this.eventBus.emit('safety:reset');
        break;
    }
  }

  startAnimationLoop() {
    this.sceneManager.renderer.setAnimationLoop(() => {
      const dt = Math.min(this.clock.getDelta(), 0.05);
      const timeTotal = this.clock.getElapsedTime();

      // 1. Carga mecánica del molino
      const T_load = this.mechLoad.update(dt, this.motor.Nr);

      // 2. Control del variador de frecuencia
      // Si el seccionador principal LOTO está abierto, no hay voltaje de barras
      const isBusEnergized = !this.safety.lotoState.step1_circuitOpened;
      if (!isBusEnergized && this.vfd.state !== 'STOPPED') {
        this.vfd.stop();
      }
      this.vfd.update(dt, this.motor.currentRMS, this.motor.powerActiveKW);

      // 3. Ecuaciones electromagnéticas de Kloss del motor
      const appliedV = isBusEnergized ? this.vfd.outputVoltage : 0.0;
      const appliedF = isBusEnergized ? this.vfd.outputFrequency : 0.0;
      this.motor.update(dt, appliedV, appliedF, T_load);

      // 4. Modelo térmico diferencial y vibración ISO 10816-3
      this.thermal.update(
        dt,
        this.motor.currentRMS,
        this.motor.Nr,
        this.motor.appliedVoltageLL,
        this.motor.appliedFrequency,
        this.motor.faultPhaseLossL3,
        this.motor.faultMechanicalJam
      );

      // 5. Modelo de polvo ATEX y partículas
      this.safety.updateDustConcentration(dt, this.motor.Nr, this.mechLoad.feedRatePercent);
      this.dustParticles.update(
        dt,
        this.motor.Nr,
        this.safety.dustConcentration_g_m3,
        this.safety.dustExtractionCycloneActive
      );

      // 6. Monitoreo de zonas de proximidad normativas
      const playerPos = this.controls.getPlayerPosition();
      this.safetyZones.update(
        dt,
        playerPos,
        this.ppe,
        this.safety,
        this.motor.Nr,
        this.motor.appliedVoltageLL
      );

      // 7. Actualización de componentes 3D mecánicos
      this.motorMill.update(dt, this.motor.angle, this.thermal.vibrationRMS);
      this.warehouse.updateAirlockAnimation(this.ppe.airlockDoorOpen, dt);

      // 8. Luces de emergencia estroboscópicas y baliza Andon
      const isEmergencyActive = this.safety.eStopEngaged || this.vfd.state === 'TRIPPED';
      this.sceneManager.updateEmergencyStrobe(isEmergencyActive, timeTotal);

      // Estado consolidado de la planta
      const plantState = {
        vfdState: this.vfd.state,
        vfdFrequency: this.vfd.outputFrequency,
        vfdVoltage: this.vfd.outputVoltage,
        motorRPM: this.motor.Nr,
        currentRMS: this.motor.currentRMS,
        currentL1: this.motor.currentL1,
        currentL2: this.motor.currentL2,
        currentL3: this.motor.currentL3,
        powerActiveKW: this.motor.powerActiveKW,
        powerFactor: this.motor.powerFactor,
        totalEnergyKWh: this.vfd.totalEnergyKWh,
        torqueElec: this.motor.T_elec,
        torqueLoad: this.motor.T_load,
        windingTemp: this.thermal.windingTemperature,
        bearingTemp: this.thermal.bearingTemperature,
        vibrationRMS: this.thermal.vibrationRMS,
        vibrationZone: this.thermal.vibrationZone,
        hopperKg: this.mechLoad.hopperCurrentLevelKg,
        flourProducedKg: this.mechLoad.flourProducedKg,
        dustConcentration: this.safety.dustConcentration_g_m3,
        isLotoActive: this.safety.lotoState.isFullyLockedOut,
        isEStopEngaged: this.safety.eStopEngaged
      };

      // 9. Actualización de interfaces de usuario
      this.andon.evaluateState(plantState);
      this.scada.updateTelemetry(plantState);

      // 10. Actualización de audio procedural
      this.audio.update(
        this.motor.Nr,
        this.vfd.outputFrequency,
        this.motor.currentRMS,
        this.motor.faultPhaseLossL3,
        this.mechLoad.feedRatePercent
      );

      // 11. Controles y renderizado final de la escena
      this.controls.update(dt);
      this.sceneManager.render();
    });
  }
}

// Iniciar aplicación al cargar el DOM
window.addEventListener('DOMContentLoaded', () => {
  new IndustrialPlantSimulationApp();
});
