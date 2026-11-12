---
name: industrial-plant-simulation
description: Specialized simulation skill for the 'Máquinas Eléctricas' final project (Planta Molino de Granos). Covers Three.js WebGL industrial plant architecture, 10HP 460V induction motor physics, VFD control, real-time SCADA/HMI telemetry, safety protocols (E-Stop, LOTO, interlocks, ATEX grain dust), alarm annunciators, and fault injection with zero compilation.
---

# Simulación de Planta Industrial: Molino de Granos & Máquinas Eléctricas (Three.js WebGL)

Esta skill contiene la arquitectura integral, modelos matemáticos en JavaScript/Three.js, protocolos de seguridad industrial y guías de implementación en **Three.js (WebGL / ES Modules sin compilación)** para el **Proyecto Final de Máquinas Eléctricas (Universidad de los Llanos)**:
**Sector Asignado: Planta Molino de Granos** con **Motor Trifásico de Inducción Jaula de Ardilla (10 HP, 460 V)** accionado por VFD.

---

## 1. Especificaciones de la Planta y Motor (RETIE / NEMA / IEC)

### 1.1 Parámetros Nominales del Motor de Inducción
- **Potencia Nominal ($P_{nom}$)**: $10\text{ HP} \approx 7.457\text{ kW}$
- **Tensión Nominal ($V_{LL}$)**: $460\text{ V AC}$ trifásico, $60\text{ Hz}$
- **Velocidad Sincrónica ($N_s$)**: $1800\text{ RPM}$ ($p = 4$ polos)
- **Velocidad Nominal a Plena Carga ($N_r$)**: $1750\text{ RPM}$ ($\text{deslizamiento nominal } s_{nom} \approx 2.78\%$)
- **Corriente Nominal a Plena Carga ($I_{FLA}$)**: $\approx 13.5\text{ A}$ por fase
- **Corriente de Arranque Directo (LRA)**: $6 \times I_{FLA} \approx 81\text{ A}$ (mitigada mediante VFD con rampa suave)
- **Factor de Potencia ($\cos\phi$)**: $0.85$ a plena carga
- **Eficiencia Nominal ($\eta$)**: $91.7\%$ (Clase Premium Efficiency / IE3)
- **Aislamiento**: Clase F ($155^\circ\text{C}$ límite), con elevación térmica clase B ($80^\circ\text{K}$)

---

## 2. Arquitectura de Simulación en Three.js (Zero-Compilation Web App)

```
SimuladorPlantaWeb/
├── index.html                    # Contenedor Canvas 3D + HUD / SCADA superpuesto en HTML5
├── css/
│   └── scada-style.css           # Estilos industriales oscuros, medidores analógicos/digitales y HUD
├── src/
│   ├── core/
│   │   ├── SceneManager.js       # WebGLRenderer, Scene, PerspectiveCamera, iluminación PBR, sombras
│   │   ├── ControlsManager.js    # Modo Operario (PointerLock WASD) y Modo Inspector (OrbitControls)
│   │   └── EventBus.js           # Publicador/Suscriptor desacoplado para telemetría, seguridad y alarmas
│   ├── physics/
│   │   ├── InductionMotor.js     # Ecuaciones dinámicas (Kloss, par, deslizamiento, corriente, factor de potencia)
│   │   ├── ThermalModel.js       # Ecuación diferencial térmica de 1er orden (calentamiento vs refrigeración)
│   │   ├── VFDController.js      # Control escalar V/f, rampa Hz, frenado regenerativo, consumo kWh
│   │   └── MechanicalLoad.js     # Carga resistente del molino de martillos y tasa de alimentación de grano
│   ├── world/
│   │   ├── WarehouseBuilder.js   # Nave industrial, pisos de concreto epóxico, demarcaciones amarillas RETIE
│   │   ├── MotorMillAssembly.js  # Motor 10 HP con eje y ventilador giratorio, molino, tolva y sinfín
│   │   ├── CCMPanel.js           # Tablero eléctrico CCM, seccionador de cuchillas, candado LOTO interactivo
│   │   └── DustParticleCloud.js  # Partículas WebGL para polvo de grano combustible en suspensión (ATEX)
│   ├── safety/
│   │   └── IndustrialSafety.js   # E-Stop Cat 0 (IEC 60204-1), LOTO 5 Reglas de Oro, Interlocks de compuerta
│   ├── ui/
│   │   ├── SCADAInterface.js     # Instrumentación HMI (amperímetros trifásicos, tacómetro, termómetro, vibrómetro)
│   │   ├── AndonVisualizer.js    # Baliza Andon 3D y 2D (Verde, Amarillo, Rojo, Azul) según norma ISA 18.2
│   │   └── FaultInjectorUI.js    # Panel interactivo para inducir fallas pedagógicas
│   └── audio/
│       └── IndustrialAudio.js    # Síntesis procedural con Web Audio API (zumbido 60Hz, inversor PWM, sirena)
```

---

## 3. Modelo Matemático en JavaScript (Física del Motor y Térmica)

### 3.1 Curva Par-Velocidad y Deslizamiento (Ecuación de Kloss)
```javascript
// Deslizamiento
const s = (Ns - Nr) / Ns;
// Par electromagnético según Kloss
const s_max = 0.15;
const T_max = 2.5 * T_nom;
const Telec = (2 * T_max) / ((s / s_max) + (s_max / s));
```

### 3.2 Dinámica Térmica en Tiempo Real (Euler hacia adelante)
```javascript
// Pérdidas Joule y ventilación dependiente de velocidad
const P_cu = 3 * Math.pow(currentRMS, 2) * Rs;
const P_loss = P_cu + P_iron + P_mech;
const k_cool = k_cool_base * (0.2 + 0.8 * (Nr / Ns)); // Enfriamiento forzado disminuye a bajas RPM
const dT = (P_loss - k_cool * (temperature - Tambient)) / C_thermal;
temperature += dT * dt;
```

### 3.3 Dinámica de Vibración (Norma ISO 10816-3 para Máquinas Clase II)
- **Zona A/B (Buena / Aceptable)**: $V_{RMS} < 2.3\text{ mm/s}$ (Operación normal)
- **Zona C (Alerta)**: $2.3\text{ mm/s} \le V_{RMS} < 4.5\text{ mm/s}$ (Desalineación / soltura incipiente)
- **Zona D (Peligro / Parada)**: $V_{RMS} \ge 4.5\text{ mm/s}$ (Falla grave de rodamiento o atasco)

---

## 4. Medidas de Seguridad Industrial & Protocolos de Planta

### 4.1 Parada de Emergencia (E-Stop - IEC 60204-1 / ISO 13850)
- Pulsador tipo hongo rojo con enclave mecánico y botón rotativo de rearme.
- Al presionarse: corte inmediato de modulación VFD, freno dinámico, activación de baliza roja parpadeante y sirena industrial.

### 4.2 Procedimiento LOTO (Lockout / Tagout - 5 Reglas de Oro)
1. **Paso 1: Paro operacional** desde el panel HMI.
2. **Paso 2: Corte visible / Aislamiento** bajando la palanca del seccionador en el CCM.
3. **Paso 3: Enclavamiento y bloqueo físico** colocando el candado de seguridad y tarjeta LOTO.
4. **Paso 4: Verificación de ausencia de tensión** comprobando 0 V en el voltímetro del tablero.
5. **Paso 5: Intento de arranque local** para verificar ausencia de energía residual.

### 4.3 Enclavamiento de Seguridad en Tolva / Molino (Interlock)
- Microswitch de seguridad en la compuerta de inspección de los martillos.
- Si se abre con $Nr > 0\text{ RPM}$, disparo instantáneo de paro por violación de seguridad y alarma crítica.

### 4.4 Riesgo de Atmósfera Explosiva por Polvo de Granos (ATEX / NFPA 61)
- Sistema de partículas con Three.js simulando la nube de polvo de cereal.
- Sensor óptico de densidad ($g/m^3$); si supera el umbral crítico ($> 30\text{ g/m}^3$) sin encender el ciclón extractor, genera alarma por riesgo de deflagración.

---

## 5. Panel SCADA / HMI Web

Instrumentos interactivos en DOM con actualización a 60 FPS:
- **Voltímetro Trifásico** ($460\text{ V}$).
- **Amperímetro Trifásico** con agujas/barras ($I_A, I_B, I_C$).
- **Frecuencímetro VFD** ($0 - 60\text{ Hz}$) con rampa ajustable.
- **Tacómetro Digital** ($0 - 1800\text{ RPM}$).
- **Termómetro de Devanados y Rodamientos** ($^\circ\text{C}$).
- **Vibrómetro RMS** ($\text{mm/s}$) clasificado por zonas ISO 10816-3.
- **Medidor de Energía y Potencia** ($P$ en $\text{kW}$, acumulador en $\text{kWh}$).
- **Torre de Baliza Andon**:
  - Verde: Operación normal nominal.
  - Amarillo: Alerta térmica o sobrecarga moderada.
  - Rojo: Disparo por falla crítica o E-Stop accionado.
  - Azul: Modo LOTO / Mantenimiento seguro.

---

## 6. Módulo de Inyección de Fallas Pedagógicas
- **Atasco Mecánico / Sobrecarga**: Incrementa la fricción y corriente ($> 20\text{ A}$), calentando los devanados.
- **Pérdida de Fase (L3)**: Corriente desbalanceada y vibración a 120 Hz.
- **Falla de Rodamiento**: Salto de vibración a Zona D ($> 5.0\text{ mm/s}$).
- **Falla de Ventilación**: Reducción drástica de $k_{cool}$ para inducir disparo por relé térmico ($> 105^\circ\text{C}$).
- **Apertura no autorizada de compuerta**: Salto de interlock con motor en movimiento.
