import * as THREE from 'three';
import { PointerLockControls } from 'three/addons/controls/PointerLockControls.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

/**
 * ControlsManager.js - Manejo de controles y navegación de cámara:
 * 1. Modo Operario (PointerLockControls en 1ra persona con WASD, colisiones y raycast central).
 * 2. Modo Inspector (OrbitControls para vista libre y paneo de 360 grados).
 * 3. Detección de interacción con tecla [E] o click.
 */
export class ControlsManager {
  constructor(camera, domElement, eventBus) {
    this.camera = camera;
    this.domElement = domElement;
    this.eventBus = eventBus;

    // Modo actual: 'OPERATOR' | 'INSPECTOR'
    this.mode = 'OPERATOR';

    // Controles
    this.pointerLock = new PointerLockControls(this.camera, document.body);
    this.orbit = new OrbitControls(this.camera, this.domElement);
    this.orbit.enabled = false;
    this.orbit.target.set(0, 1.0, 0);
    this.orbit.maxPolarAngle = Math.PI / 2 - 0.05; // No atravesar el suelo

    // Teclas de movimiento
    this.moveForward = false;
    this.moveBackward = false;
    this.moveLeft = false;
    this.moveRight = false;
    this.isSprinting = false;

    this.velocity = new THREE.Vector3();
    this.direction = new THREE.Vector3();

    // Raycast para interacción en primera persona
    this.raycaster = new THREE.Raycaster();
    this.raycaster.far = 2.6; // Distancia máxima de alcance de la mano (m)
    this.centerScreen = new THREE.Vector2(0, 0);
    this.currentHoveredObject = null;
    this.interactablesList = [];

    // Estado de la esclusa para colisión de paso
    this.isAirlockOpen = false;

    this.setupEventListeners();
  }

  setInteractables(list) {
    this.interactablesList = list;
  }

  setAirlockState(isOpen) {
    this.isAirlockOpen = isOpen;
  }

  setupEventListeners() {
    // Bloqueo de puntero al hacer click en pantalla
    const blocker = document.getElementById('instructions-overlay');
    if (blocker) {
      blocker.addEventListener('click', () => {
        blocker.style.display = 'none'; // Ocultar inmediatamente al hacer click
        if (this.mode === 'OPERATOR') {
          try {
            const promise = this.pointerLock.lock();
            if (promise && promise.catch) {
              promise.catch((err) => {
                console.warn('[ControlsManager] PointerLock no disponible en este entorno, operando en modo navegación directa:', err);
              });
            }
          } catch (err) {
            console.warn('[ControlsManager] PointerLock falló:', err);
          }
        }
      });
    }

    this.pointerLock.addEventListener('lock', () => {
      if (blocker) blocker.style.display = 'none';
    });

    this.pointerLock.addEventListener('unlock', () => {
      // No re-bloquear la pantalla si la tablet está abierta o en modo inspector
      const tabletModal = document.getElementById('risk-tablet-modal');
      const isTabletOpen = tabletModal && tabletModal.classList.contains('active');
      if (blocker && this.mode === 'OPERATOR' && !isTabletOpen) {
        // En lugar de tapar todo, dejamos la pantalla libre y permitimos volver a bloquear al clickear el canvas
      }
    });

    // Soporte de arrastre con ratón (Fallback para entornos sin PointerLock nativo)
    this.isDraggingMouse = false;
    this.prevMouseX = 0;
    this.prevMouseY = 0;
    this.pitch = 0;
    this.yaw = 0;

    window.addEventListener('mousedown', (e) => {
      if (this.mode === 'OPERATOR' && !this.pointerLock.isLocked) {
        const tabletModal = document.getElementById('risk-tablet-modal');
        const isTabletOpen = tabletModal && tabletModal.classList.contains('active');
        if (!isTabletOpen) {
          this.isDraggingMouse = true;
          this.prevMouseX = e.clientX;
          this.prevMouseY = e.clientY;
        }
      }
    });

    window.addEventListener('mouseup', () => {
      this.isDraggingMouse = false;
    });

    window.addEventListener('mousemove', (e) => {
      if (this.mode === 'OPERATOR' && !this.pointerLock.isLocked && this.isDraggingMouse) {
        const dx = e.clientX - this.prevMouseX;
        const dy = e.clientY - this.prevMouseY;
        this.prevMouseX = e.clientX;
        this.prevMouseY = e.clientY;

        this.yaw -= dx * 0.003;
        this.pitch = Math.max(-1.4, Math.min(1.4, this.pitch - dy * 0.003));

        this.camera.rotation.set(0, 0, 0);
        this.camera.rotation.order = 'YXZ';
        this.camera.rotation.y = this.yaw;
        this.camera.rotation.x = this.pitch;
      }
    });

    // Teclado
    window.addEventListener('keydown', (e) => this.onKeyDown(e));
    window.addEventListener('keyup', (e) => this.onKeyUp(e));

    // Click del ratón para interactuar si está bloqueado
    window.addEventListener('mousedown', (e) => {
      if (e.button === 0 && this.pointerLock.isLocked) {
        this.triggerInteraction();
      }
    });
  }

  onKeyDown(event) {
    switch (event.code) {
      case 'KeyW':
      case 'ArrowUp':
        this.moveForward = true;
        break;
      case 'KeyS':
      case 'ArrowDown':
        this.moveBackward = true;
        break;
      case 'KeyA':
      case 'ArrowLeft':
        this.moveLeft = true;
        break;
      case 'KeyD':
      case 'ArrowRight':
        this.moveRight = true;
        break;
      case 'ShiftLeft':
      case 'ShiftRight':
        this.isSprinting = true;
        break;
      case 'KeyE':
        this.triggerInteraction();
        break;
      case 'KeyC':
        this.toggleCameraMode();
        break;
    }
  }

  onKeyUp(event) {
    switch (event.code) {
      case 'KeyW':
      case 'ArrowUp':
        this.moveForward = false;
        break;
      case 'KeyS':
      case 'ArrowDown':
        this.moveBackward = false;
        break;
      case 'KeyA':
      case 'ArrowLeft':
        this.moveLeft = false;
        break;
      case 'KeyD':
      case 'ArrowRight':
        this.moveRight = false;
        break;
      case 'ShiftLeft':
      case 'ShiftRight':
        this.isSprinting = false;
        break;
    }
  }

  toggleCameraMode() {
    if (this.mode === 'OPERATOR') {
      this.mode = 'INSPECTOR';
      this.pointerLock.unlock();
      this.orbit.enabled = true;
      this.orbit.target.set(0, 1.2, 0);
      this.camera.position.set(0, 6.0, 10.0);
      this.camera.lookAt(0, 1.2, 0);
      if (this.eventBus) {
        this.eventBus.emit('ui:toast', {
          type: 'info',
          title: 'Modo Inspector (Orbital)',
          message: 'Cámara orbital activada. Use botón izquierdo para rotar y rueda para zoom.'
        });
      }
    } else {
      this.mode = 'OPERATOR';
      this.orbit.enabled = false;
      this.camera.position.set(-10.5, 1.7, 7.0);
      this.pointerLock.lock();
      if (this.eventBus) {
        this.eventBus.emit('ui:toast', {
          type: 'info',
          title: 'Modo Operario (1ra Persona)',
          message: 'Cámara en primera persona activada. WASD para caminar y [E] para interactuar.'
        });
      }
    }
  }

  triggerInteraction() {
    if (this.currentHoveredObject && this.currentHoveredObject.userData) {
      const data = this.currentHoveredObject.userData;
      if (this.eventBus) {
        this.eventBus.emit('interaction:execute', data);
      }
    }
  }

  /**
   * Actualiza la cinemática de movimiento y el raycaster en cada frame.
   * @param {number} dt 
   */
  update(dt) {
    if (this.mode === 'INSPECTOR') {
      this.orbit.update();
      return;
    }

    const tabletModal = document.getElementById('risk-tablet-modal');
    const isTabletOpen = tabletModal && tabletModal.classList.contains('active');
    if (isTabletOpen) return;

    // 1. Raycast central desde la vista de la cámara
    this.raycaster.setFromCamera(this.centerScreen, this.camera);
    const intersects = this.raycaster.intersectObjects(this.interactablesList, true);

    let foundInteractable = null;
    if (intersects.length > 0) {
      // Buscar el objeto o su ancestro con userData interactivo
      let obj = intersects[0].object;
      while (obj && !obj.userData?.name && obj.parent) {
        obj = obj.parent;
      }
      if (obj && obj.userData && obj.userData.name) {
        foundInteractable = obj;
      }
    }

    if (foundInteractable !== this.currentHoveredObject) {
      this.currentHoveredObject = foundInteractable;
      if (this.eventBus) {
        this.eventBus.emit('interaction:hover', this.currentHoveredObject ? this.currentHoveredObject.userData : null);
      }
    }

    // 2. Movimiento WASD en primera persona
    const speed = this.isSprinting ? 5.2 : 3.0; // m/s
    const damping = 10.0;

    this.velocity.x -= this.velocity.x * damping * dt;
    this.velocity.z -= this.velocity.z * damping * dt;

    this.direction.z = Number(this.moveForward) - Number(this.moveBackward);
    this.direction.x = Number(this.moveRight) - Number(this.moveLeft);
    this.direction.normalize();

    if (this.moveForward || this.moveBackward) {
      this.velocity.z -= this.direction.z * speed * 8.0 * dt;
    }
    if (this.moveLeft || this.moveRight) {
      this.velocity.x -= this.direction.x * speed * 8.0 * dt;
    }

    // Desplazamiento relativo a la orientación de la cámara
    if (this.pointerLock.isLocked) {
      this.pointerLock.moveRight(-this.velocity.x * dt);
      this.pointerLock.moveForward(-this.velocity.z * dt);
    } else {
      const forward = new THREE.Vector3();
      this.camera.getWorldDirection(forward);
      forward.y = 0;
      forward.normalize();
      const right = new THREE.Vector3().crossVectors(new THREE.Vector3(0, 1, 0), forward).negate();

      this.camera.position.addScaledVector(forward, -this.velocity.z * dt);
      this.camera.position.addScaledVector(right, -this.velocity.x * dt);
    }

    // 3. Colisiones y límites de la nave industrial
    const pos = this.camera.position;
    pos.y = 1.7; // Altura estándar de ojos del operario

    // Límites perimetrales del edificio
    pos.x = Math.max(-12.2, Math.min(12.2, pos.x));
    pos.z = Math.max(-9.2, Math.min(9.2, pos.z));

    // Muros de los vestidores:
    // Muro divisorio X = -8.0 para Z entre 3.5 y 9.5
    if (pos.z > 3.6 && pos.x > -8.2 && pos.x < -7.8) {
      pos.x = -8.2;
    }

    // Esclusa de paso en Z = 3.5 para X entre -10.0 y -8.0
    // Si la esclusa está cerrada, impide cruzar hacia la nave de producción (Z < 3.5)
    if (!this.isAirlockOpen) {
      if (pos.x < -7.9 && pos.z > 3.0 && pos.z < 3.7) {
        pos.z = 3.7; // Rebote hacia atrás en el vestidor
      }
    }
  }

  getPlayerPosition() {
    return this.camera.position;
  }
}
export default ControlsManager;
