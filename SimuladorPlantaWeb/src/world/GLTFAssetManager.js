import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

/**
 * GLTFAssetManager.js - Gestor de carga e integración de modelos 3D industriales externos (.glb).
 * Carga de forma asíncrona modelos de alta fidelidad:
 * - Montacargas industrial (Forklift) con mástil y horquillas
 * - Estanterías industriales de paletización pesada (Warehouse Shelves)
 * - Cinta transportadora de banda (Conveyor Belt)
 * - Máquinas complementarias y conos de tráfico
 * Aplica sombras PBR automáticas, ajuste de escala y posicionamiento en zonas designadas.
 */
export class GLTFAssetManager {
  constructor(scene, eventBus) {
    this.scene = scene;
    this.eventBus = eventBus;
    this.loader = new GLTFLoader();
    this.loadedModels = new Map();
  }

  /**
   * Carga e integra los modelos GLB descargados en la escena.
   */
  async loadAllAssets() {
    const assetsToLoad = [
      {
        id: 'forklift',
        path: './assets/models/forklift.glb',
        instances: [
          { pos: [-12.0, 0.0, -8.0], rot: [0, Math.PI / 3, 0], scale: 1.6 }
        ]
      },
      {
        id: 'warehouse_shelf',
        path: './assets/models/warehouse_shelf.glb',
        instances: [
          { pos: [-6.0, 0.0, -11.5], rot: [0, 0, 0], scale: 1.8 },
          { pos: [-2.0, 0.0, -11.5], rot: [0, 0, 0], scale: 1.8 },
          { pos: [2.0, 0.0, -11.5], rot: [0, 0, 0], scale: 1.8 }
        ]
      },
      {
        id: 'conveyor_belt',
        path: './assets/models/conveyor_belt.glb',
        instances: [
          { pos: [8.5, 0.0, -2.5], rot: [0, Math.PI / 2, 0], scale: 1.2 }
        ]
      },
      {
        id: 'traffic_cone',
        path: './assets/models/traffic_cone.glb',
        instances: [
          { pos: [-10.5, 0.0, -7.0], rot: [0, 0, 0], scale: 0.8 },
          { pos: [-13.5, 0.0, -7.0], rot: [0, 0, 0], scale: 0.8 },
          { pos: [-12.0, 0.0, -5.5], rot: [0, 0, 0], scale: 0.8 }
        ]
      },
      {
        id: 'machine',
        path: './assets/models/machine.glb',
        instances: [
          { pos: [6.0, 0.0, 8.0], rot: [0, Math.PI, 0], scale: 1.0 }
        ]
      },
      {
        id: 'industrial_table',
        path: './assets/models/industrial_table.glb',
        instances: [
          { pos: [-16.0, 1.0, 7.5], rot: [0, Math.PI / 2, 0], scale: 1.0 } // En sala de control
        ]
      }
    ];

    for (const item of assetsToLoad) {
      try {
        await this.loadAssetItem(item);
      } catch (err) {
        console.warn(`[GLTFAssetManager] No se pudo cargar ${item.id} (se utilizará geometría procedural):`, err);
      }
    }
  }

  loadAssetItem(item) {
    return new Promise((resolve, reject) => {
      this.loader.load(
        item.path,
        (gltf) => {
          const baseModel = gltf.scene;

          // Configurar sombras PBR y materiales
          baseModel.traverse((child) => {
            if (child.isMesh) {
              child.castShadow = true;
              child.receiveShadow = true;
              if (child.material) {
                child.material.roughness = Math.min(0.9, child.material.roughness || 0.5);
                child.material.envMapIntensity = 1.0;
              }
            }
          });

          // Instanciar en cada posición requerida
          item.instances.forEach((inst, idx) => {
            const instanceMesh = (idx === 0) ? baseModel : baseModel.clone(true);
            instanceMesh.position.set(inst.pos[0], inst.pos[1], inst.pos[2]);
            instanceMesh.rotation.set(inst.rot[0], inst.rot[1], inst.rot[2]);
            const s = inst.scale || 1.0;
            instanceMesh.scale.set(s, s, s);

            this.scene.add(instanceMesh);
          });

          this.loadedModels.set(item.id, baseModel);
          resolve(baseModel);
        },
        undefined,
        (error) => {
          reject(error);
        }
      );
    });
  }
}
export default GLTFAssetManager;
