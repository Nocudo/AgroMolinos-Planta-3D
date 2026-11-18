# 🤖 PLAN MAESTRO DE EJECUCIÓN POR BLOQUES — OPTIMIZADO PARA ORCHESTRATOR (ARGON)

**Proyecto:** Simulador 3D Interactivo (*Serious Game* en Godot 4.7) y Diagnóstico Inteligente — Planta Molino de Granos (Motor Trifásico 10 HP, 460 V, IE3)  
**Empresa Caso de Estudio:** AgroMolinos del Valle S.A.  
**Universidad de los Llanos** — Ingeniería Electrónica — Máquinas Eléctricas (2026-2)  
**Docente Titular:** Ing. Lauren Genith Isaza  
**Repositorio Oficial:** [https://github.com/Nocudo/AgroMolinos-Planta-3D](https://github.com/Nocudo/AgroMolinos-Planta-3D)  
**Estado Actual:** ✅ **Bloques 1–8 Completados + Optimizaciones Vulkan 1.3 Forward+, 37 Texturas Procedurales de Baja Resolución (`64×64`/`128×128`), Tablet Minimalista de 8 Pestañas, 19 Estaciones y QA Headless `10/10 PASS`**

---

## ✅ 0. Estado Consolidado de Implementación (Actualizado)

| Bloque / Módulo | Estado | Implementación Verificada en `SimuladorPlantaGodot/` |
| :--- | :---: | :--- |
| **Bloque 1 — Entorno 3D, Vulkan 1.3 y Texturas Low-Res** | ✅ | Renderizador **Vulkan 1.3 Forward+** (Reverse-Z 32-bit), 470 colisionadores sólidos, 28 puertas alineadas por PCA, 0 Z-fighting, batching espacial LOD (`PlantVisibilityOptimizer.gd`) y **37 texturas procedurales `64×64`/`128×128`** (`152.3 KB` total, Basis Universal VRAM, 0 texturas originales pesadas). |
| **Bloque 2 — Motor Kloss 10 HP + VFD vs DOL** | ✅ | `InductionMotorKloss.gd` + `VFDDriveController.gd` ($1750\text{ RPM}$, $I_{FLA}=13.5\text{ A}$, $I_{LRA}=81.0\text{ A}$, $T_{max}=101.75\text{ N}\cdot\text{m}$, $7.52$ vs $10.50\text{ kWh/ton}$, $28.4\%$ ahorro, $488.7\text{ kg CO}_2\text{e/año}$). |
| **Bloque 3 — Tutorial RETIE & 19 Estaciones** | ✅ | `TutorialInductionManager.gd`: spawn en Portería en 1ra persona, bienvenida y **Curso SST / Quiz RETIE** abiertos **solo al hablar con el Supervisor SST (`E`/Clic)**, enclavamiento EPP `6/6` con avatar 3D reactivo, 5 Reglas LOTO y recorrido seguro de **19 estaciones**. |
| **Bloque 4 — Producción y Logística Articulada** | ✅ | `AnimatedProductionLogistics.gd`: camiones articulados por vías pavimentadas con portones automáticos, giro natural y acople a puerta amarilla izquierda (sin desprendimiento de tráiler), cargue manual de sacos por operarios animados solo con camión parqueado y 0 glow. |
| **Bloque 5 — 5 Fallas Físicas Diegéticas** | ✅ | Corte L3 con alicates (`2`), atasco manual con sacos de $50\text{ kg}$ (`1`), breakers CCM (`460 V -> 340 V`), ventilación obstruida y pernos flojos con llave `3/4"` (`3`), multímetro (`4`) y Kit LOTO (`5`). |
| **Bloque 6 — Edge AI Nativo (MLP + SVM)** | ✅ | `EdgeAIEngine.gd`: inferencia nativa 10 Hz (`MLP 8-16-8-4`, `SVM RBF`), MHI, RUL y checklist RCM. |
| **Bloque 7 — Tablet SCADA Minimalista (`[TAB]`)** | ✅ | `IndustrialTabletController.gd` + `TabletChassisVisuals.gd`: marco limpio `1228×748` / pantalla `1180×700`, **sin botones ficticios ni botón «Salir»** (cierra con `TAB`/`ESC`), **8 pestañas** (`Monitoreo IoT`, `Cámaras`, `RETIE`, `Operarios`, `Riesgos`, `Fisiología IEC`, `Hardware & IA`, `Rúbrica`) y parada exclusiva `Parar / Reanudar Máquinas`. |
| **Bloque 8 — CCTV, Rúbrica RETIE y QA 10/10** | ✅ | `MezzanineCCTVController.gd`, `SafetyEvaluationScorecard.gd` (`0.0–5.0` + JSON) y `headless_verify.gd` (**10/10 PASS**, 0 errores). |
| **Instalación & Entorno** | ✅ | `requirements.txt` + `INSTALAR_DEPENDENCIAS.bat` (1 clic en Windows) + `INICIAR_SIMULADOR_GODOT.bat` + `ABRIR_EDITOR_GODOT.bat`. |

---

## 🛡️ 1. Directivas Globales e Inquebrantables para el Orchestrator (Argon)

Antes de despachar cualquier bloque o subagente, **Argon** debe hacer cumplir de forma estricta las siguientes **5 Reglas Cardinales**:

> [!CAUTION]
> **REGLA 1 — POLÍTICA ESTRICTA DE ACTIVOS 3D (CERO MODELOS PROCEDURALES):**
> 1. **ÚNICAMENTE utilizar modelos 3D descargados de internet** alojados en `Modelos descargados/` y vinculados en `SimuladorPlantaGodot/assets/models/`.
> 2. **PROHIBIDO** crear o ensamblar geometrías procedurales con primitivas (`CSGBox3D`, `CSGCylinder3D`, `BoxMesh`, `CylinderMesh`, `CapsuleMesh`, `SphereMesh`) para representar maquinaria, vehículos, camiones, trabajadores, herramientas o tableros.
> 3. **Protocolo de Detención por Activo Faltante:** Si al iniciar un bloque se requiere un modelo 3D que no existe en `Modelos descargados/` (por ejemplo: un camión volquete, un montacargas, una herramienta o un accesorio específico), **el agente NO debe improvisarlo con cajas/cilindros; debe detener ese ítem y pedirle explícitamente al usuario que descargue el modelo `.glb` y lo coloque en `Modelos descargados/`**.

> [!IMPORTANT]
> **REGLA 2 — FALLAS FÍSICAS 100% DIEGÉTICAS (CERO BOTONES DE FALLA EN UI 2D):**
> Queda prohibido crear botones 2D en pantalla del tipo *"Inyectar Falla"* o *"Provocar Sobrecarga"*. Todas las averías deben originarse por **interacciones físicas directas del operario en el entorno 3D**: cortar cables con alicates dieléctricos, arrojar bultos de $50\text{ kg}$ a la tolva, manipular palancas de breakers en el CCM, obstruir la rejilla de ventilación o aflojar pernos con llave mecánica.

> [!IMPORTANT]
> **REGLA 3 — TELEMETRÍA Y DASHBOARD IA 100% IN-GAME EN TABLET (`[TAB]`):**
> Queda prohibido depender de páginas web externas, servidores FastAPI externos o navegadores para ver la telemetría. Al presionar la tecla **`[TAB]`**, el operario saca/guarda en pantalla la **Tablet Industrial Diegética** (`IndustrialTablet.tscn` / `IndustrialTabletController.gd`), la cual renderiza nativamente en Godot los oscilogramas en tiempo real (*strip charts*), medidores True-RMS, diagnóstico IA (MLP/SVM), *Motor Health Index* (MHI), *Remaining Useful Life* (RUL), alertas sonoras y checklist RCM interactivo.

> [!NOTE]
> **REGLA 4 — FIDELIDAD MATEMÁTICA CON AVANCE 1 Y AVANCE 2:**
> Todos los cálculos físicos y de IA en GDScript deben usar exactamente los parámetros nominales y pesos/umbrales derivados de `Avance 1/` (`InductionMachineDTCData.m`) y `Avance 2/` (`generate_dataset.m`, `train_classifiers.m`).

> [!TIP]
> **REGLA 5 — PUERTA DE VERIFICACIÓN TDD HEADLESS POR BLOQUE:**
> Ningún bloque se considera completado hasta que `godot --headless --path SimuladorPlantaGodot --script res://scripts/tests/headless_verify.gd` compile todas las escenas `.tscn` y apruebe el $100\%$ de las aserciones con código de salida `0`.

---

## 📊 2. Contexto Técnico Consolidado de los Avances (Única Fuente de Verdad)

### 2.1 Parámetros Electromecánicos del Motor (Avance 1 — `InductionMachineDTCData.m`)
- **Identificación:** Motor Trifásico Jaula de Ardilla `M-101` (Accionamiento de Molino de Martillos).
- **Valores Nominales:** $P_n = 10\text{ HP} = 7457\text{ W}$, $V_{LL,n} = 460\text{ V AC}$, $f_n = 60\text{ Hz}$, $P = 4\text{ polos}$ ($p = 2$), $N_s = 1800\text{ RPM}$, $N_r = 1750\text{ RPM}$ ($s_n = 0.0278$), $I_{FLA} = 13.5\text{ A RMS}$, $I_0 = 4.5\text{ A RMS}$, $I_{LRA} = 81.0\text{ A RMS}$ ($6 \times I_{FLA}$), $T_n = 40.7\text{ N}\cdot\text{m}$, $T_{max} = 101.75\text{ N}\cdot\text{m}$ ($s_{max} = 0.15$), $\cos\phi_n = 0.85$, $\eta_n = 91.7\%$ (IE3), Aislamiento Clase F ($T_{max} = 155^\circ\text{C}$, alarma a $85^\circ\text{C}$, disparo relé térmico a $105^\circ\text{C}$).
- **Circuito Equivalente:** $R_s = 0.435\ \Omega$, $R_r' = 0.816\ \Omega$, $L_{ls} = L_{lr}' = 2.0\text{ mH}$ ($X_{ls} = X_{lr}' = 0.754\ \Omega$), $L_m = 69.3\text{ mH}$ ($X_m = 26.12\ \Omega$), $J_{total} = 0.35\text{ kg}\cdot\text{m}^2$, $B = 0.012\text{ N}\cdot\text{m}\cdot\text{s/rad}$.
- **Térmico:** $T_{amb} = 28.0^\circ\text{C}$, $C_{th} = 185.0\text{ J/}^\circ\text{C}$, $R_{th,nom} = 0.068^\circ\text{C/W}$ (ventilador sano), $R_{th,fan\_fail} = 0.210^\circ\text{C/W}$ (rejilla obstruida).

### 2.2 Vector de Características e Inteligencia Artificial (Avance 2 — `train_classifiers.m`)
- **Vector de Entrada (8 Variables):**
  $$\mathbf{x} = \begin{bmatrix} I_{RMS} & IUF & THD & V_{RMS} & T_{winding} & \frac{dT}{dt} & Vib_{RMS} & Vib_{peak} \end{bmatrix}^T$$
- **Clasificadores Integrados:**
  1. **MLP ($8 \to 16 \to 8 \to 4$):** Normalización Z-Score, capas ocultas ReLU, salida Softmax ($99.17\%$ accuracy).
  2. **SVM Multiclase RBF:** Kernel gaussiano $\gamma = 0.125, C = 10.0$ ($98.75\%$ accuracy).
- **Clases de Diagnóstico:**
  - `0: NORMAL` ($IUF < 5\%$, $T_w < 85^\circ\text{C}$, $Vib_{RMS} < 2.3\text{ mm/s}$ Zona A/B ISO 10816-3).
  - `1: SOBRECALENTAMIENTO` ($T_w \ge 85^\circ\text{C}$ o $\frac{dT}{dt} > 0.15^\circ\text{C/s}$ por sobrecarga de grano o ventilación obstruida).
  - `2: FALLA ELÉCTRICA (MONOFASIZACIÓN / DESBALANCE)` ($IUF \ge 15\%$ o caída de fase $I_C \to 0\text{ A}$ o $V_{LL} < 414\text{ V}$).
  - `3: FALLA MECÁNICA (RODAMIENTOS / DESALINEACIÓN)` ($Vib_{RMS} \ge 2.8\text{ mm/s}$ Zona C/D ISO 10816-3, armónicos 1X/2X RPM).

---

## 🗺️ 3. Topología de Orquestación Agéntica para Argon (Pipeline de 8 Bloques)

```
====================================================================================================
                      PIPELINE DE EJECUCIÓN AGÉNTICA PARA ARGON (8 BLOQUES)
====================================================================================================

  [FASE 1: CIMIENTOS ESPACIALES Y FÍSICOS] (Secuencial)
  ┌──────────────────────────────────────────────┐    ┌──────────────────────────────────────────────┐
  │ BLOQUE 1: Entorno 3D, Suelo Físico PBR,      │───►│ BLOQUE 2: Motor Electromecánico de Kloss     │
  │ Colisiones Trimesh, Zonas OSHA/RETIE y Luces │    │ (10 HP, 460V), VFD V/f + PID vs DOL y Térmico│
  └──────────────────────────────────────────────┘    └──────────────────────┬───────────────────────┘
                                                                             │
  [FASE 2: SIMULACIÓN INTERACTIVA Y DIEGÉTICA] (Paralelizable en 3 Subagentes de Argon)
         ┌───────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────┐
         ▼                                                                   ▼                                                                   ▼
  ┌─────────────────────────────────────────┐       ┌─────────────────────────────────────────┐       ┌─────────────────────────────────────────┐
  │ BLOQUE 3: Modo Tutorial RETIE,          │       │ BLOQUE 4: Cadena de Producción Animada  │       │ BLOQUE 5: Inducción Diegética de las    │
  │ Spawn en Portería, Vestidores EPP,      │       │ (Camión Recepción, Elevador, Molienda,  │       │ 5 Fallas Físicas en 3D (Corte Cable L3, │
  │ 5 Reglas de Oro LOTO y 12 Estaciones    │       │ Ensacado 50 kg, Racks y Despacho)       │       │ Sacos en Tolva, Breakers CCM, Pernos)   │
  └───────────────────┬─────────────────────┘       └───────────────────┬─────────────────────┘       └───────────────────┬─────────────────────┘
                      └─────────────────────────────────────────────────┼─────────────────────────────────────────────────┘
                                                                        │
  [FASE 3: GEMELO DIGITAL IN-GAME, TABLET [TAB] Y CERTIFICACIÓN QA] (Secuencial)
                                                                        ▼
                                            ┌───────────────────────────────────────────────────────┐
                                            │ BLOQUE 6: Motor Edge AI Nativo en GDScript            │
                                            │ (MLP 8-16-8-4, SVM RBF, MHI, RUL, RCM y KPIs CO2e)    │
                                            └───────────────────────────┬───────────────────────────┘
                                                                        ▼
                                            ┌───────────────────────────────────────────────────────┐
                                            │ BLOQUE 7: Dashboard 100% In-Game en Tablet [TAB]      │
                                            │ (Oscilogramas Strip Charts, Alertas Push y Checklist) │
                                            └───────────────────────────┬───────────────────────────┘
                                                                        ▼
                                            ┌───────────────────────────────────────────────────────┐
                                            │ BLOQUE 8: Monitoreo CCTV en Mezzanine, Rúbrica        │
                                            │ Académica (0.0-5.0) y Certificación Headless QA 100%  │
                                            └───────────────────────────────────────────────────────┘
```

---

## 🧱 4. Especificación Detallada de los Bloques para Argon

---

### 🔹 BLOQUE 1: Acomodación Espacial de la Planta 3D, Suelo Físico PBR, Colisiones, Zonificación OSHA/RETIE e Iluminación Realista

- **Modo de Orquestación:** Secuencial (Base de escena).
- **Contexto de Entrada Obligatorio:**
  - `.agent/skills/industrial-plant-simulation/SKILL.md` (Secciones 3, 4 y 5).
  - `SimuladorPlantaGodot/scenes/main.tscn` y `SimuladorPlantaGodot/scripts/core/MainPlantScene.gd`.
- **Auditoría de Modelos 3D:**
  - Verificar presencia de `Modelos descargados/planta_completa.glb` y `SimuladorPlantaGodot/assets/models/planta_completa.glb`.
- **Archivos Objetivo a Crear / Modificar:**
  - `SimuladorPlantaGodot/scripts/environment/PlantSpatialBuilder.gd`
  - `SimuladorPlantaGodot/scenes/environment/SafetyZonesAndLighting.tscn`
  - `SimuladorPlantaGodot/scenes/main.tscn`
- **Especificaciones de Implementación:**
  1. **Suelo Físico Industrial (`StaticBody3D`):** `CollisionShape3D` con `BoxShape3D` de $600 \times 1.0 \times 600\text{ m}$ en $Y = -0.5\text{ m}$ (superficie exacta en $Y = 0.0\text{ m}$), material físico con fricción $0.85$ y material PBR de concreto epóxico (`roughness = 0.65`, normal map habilitado).
  2. **Colisiones Automáticas en `planta_completa.glb`:** Recorrer recursivamente los nodos `MeshInstance3D` de la planta importada en `_ready()` y generar colisiones físicas sólidas (`create_trimesh_collision()` en estructuras/paredes/pasarelas y `create_convex_collision()` en maquinaria) en la capa de colisión 1.
  3. **Demarcación Vial y Zonificación Normativa en Piso:**
     - *Zona 1 (Molienda Crítica — Amarillo/Negro ANSI Z535):* Perímetro de $8\text{ m} \times 6\text{ m}$ alrededor del molino `M-101`.
     - *Zona 2 (Frente de Tablero CCM 460 V — Rojo RETIE Art. 20 / NFPA 70E):* Franja de seguridad de $1.0\text{ m}$ de despeje libre obligatorio con `Area3D` detectora de invasión sin EPP dieléctrico.
     - *Zona 3 (Pasillos Peatonales — Verde OSHA 1910.22):* Corredores seguros de $2.4\text{ m}$ de ancho desde la portería y vestidores hasta molienda y despacho.
     - *Zona 4 (Recepción/Báscula en Azul y Almacén en Blanco).*
     - *Zona 5 (Atmósfera ATEX Polvo Combustible — NFPA 61):* Volumen `Area3D` alrededor de la tolva y molino.
  4. **Iluminación Fotorrealista PBR:** Configurar `WorldEnvironment` con Tonemap ACES (`tonemap_mode = 3`), `ssao_enabled = true`, `ssr_enabled = true`, `glow_enabled = true`, `volumetric_fog_enabled = true` (`density = 0.008`), `DirectionalLight3D` con sombras PCF y matriz de campanas LED High-Bay $5000\text{ K}$ (`SpotLight3D` / `OmniLight3D`).
- **Criterio de Aceptación TDD Headless:**
  - `SueloFisicoPBR` existe como `StaticBody3D`, la planta genera colisiones sólidas sin errores y las zonas `Area3D` emiten señales de entrada/salida.
- **Prompt para Argon (Bloque 1):**
  > *"Ejecuta el Bloque 1 siguiendo `.agent/skills/industrial-plant-simulation/SKILL.md` (Secciones 3, 4 y 5). Implementa `PlantSpatialBuilder.gd` y `SafetyZonesAndLighting.tscn`, asegurando suelo físico `StaticBody3D`, colisiones trimesh automáticas en `planta_completa.glb`, demarcación de las 5 zonas OSHA/RETIE/ATEX e iluminación PBR con niebla volumétrica. Prohibido crear modelos 3D procedurales de maquinaria. Verifica con `headless_verify.gd`."*

---

### 🔹 BLOQUE 2: Perfeccionamiento del Motor Electromecánico de Kloss (10 HP, 460 V), Variador VFD (V/f + PID vs DOL) y Dinámica Térmica/Vibratoria

- **Modo de Orquestación:** Secuencial (Depende de Bloque 1).
- **Contexto de Entrada Obligatorio:**
  - `.agent/skills/industrial-plant-simulation/SKILL.md` (Secciones 2, 8 y 11).
  - `Avance 1/Informe/simulaciones/InductionMachineDTCData.m`.
  - `SimuladorPlantaGodot/scripts/physics/InductionMotorKloss.gd` y `SimuladorPlantaGodot/scripts/core/SimulationManager.gd`.
- **Archivos Objetivo a Crear / Modificar:**
  - `SimuladorPlantaGodot/scripts/physics/InductionMotorKloss.gd`
  - `SimuladorPlantaGodot/scripts/physics/VFDDriveController.gd`
  - `SimuladorPlantaGodot/scripts/core/SimulationManager.gd`
  - `SimuladorPlantaGodot/scripts/core/EventBus.gd`
- **Especificaciones de Implementación:**
  1. **Ecuación Exacta de Kloss y Escalamiento Cuadrático por Tensión y Frecuencia:**
     $$T_e(s, V_{LL}, f_{op}) = T_{max} \cdot \left(\frac{V_{LL} / 460.0}{f_{op} / 60.0}\right)^2 \cdot \frac{2}{\frac{s}{s_{max}} + \frac{s_{max}}{s}}$$
  2. **Dinámica Rotacional de Newton-Euler:**
     $$\frac{d\omega_m}{dt} = \frac{T_e - T_{load}(\dot{m}) - B\omega_m - T_{jam}}{J_{total}}$$
  3. **Comparativa Modos DOL vs VFD Escalar V/f con PID:**
     - En modo **DOL (Arranque Directo)**: $f_{op} = 60\text{ Hz}$ fija, pico de corriente de arranque $I_{LRA} = 81.0\text{ A}$, consumo específico base $10.5\text{ kWh/ton}$.
     - En modo **VFD (Variador de Frecuencia)**: Rampa suave de aceleración de $10\text{ s}$ ($I_{arranque} \le 17.5\text{ A}$), regulación automática de frecuencia ($35\text{ Hz}$ a $60\text{ Hz}$) según flujo másico $\dot{m}$ de grano en tolva, logrando consumo específico optimizado de $7.52\text{ kWh/ton}$ ($28.38\%$ de ahorro) y contabilizando en tiempo real los $\text{kg CO}_2\text{e}$ evitados ($0.164\text{ kg CO}_2\text{e/kWh}$).
  4. **Cálculo Completo del Vector de 8 Variables a 10 Hz:**
     Emitir por `EventBus` el diccionario/señal con $[I_{RMS}, IUF, THD, V_{RMS}, T_w, \frac{dT}{dt}, Vib_{RMS}, Vib_{peak}]$ además de $I_A, I_B, I_C$, $N_r$, $T_e$, $P_{kW}$, $\cos\phi$, $\eta$, $\text{kWh/ton}$ y $\text{kg CO}_2\text{e}$.
- **Criterio de Aceptación TDD Headless:**
  - En estado nominal a plena carga: $N_r \in [1740, 1780]\text{ RPM}$, $I_{RMS} \approx 13.5\text{ A}$ (a $40.7\text{ N}\cdot\text{m}$), $IUF < 2\%$, $Vib_{RMS} < 1.4\text{ mm/s}$ (Zona A). En modo VFD a baja carga ($42\text{ Hz}$), la potencia consumida disminuye según ley de afinidad.
- **Prompt para Argon (Bloque 2):**
  > *"Ejecuta el Bloque 2 siguiendo `.agent/skills/industrial-plant-simulation/SKILL.md` (Secciones 2, 8 y 11) y `InductionMachineDTCData.m`. Actualiza `InductionMotorKloss.gd`, `VFDDriveController.gd`, `SimulationManager.gd` y `EventBus.gd` para emitir el vector completo de 8 variables de IA y los KPIs energéticos DOL vs VFD ($\text{kWh/ton}$ y $\text{kg CO}_2\text{e}$). Certifica con `headless_verify.gd`."*

---

### 🔹 BLOQUE 3: Modo Tutorial Interactivo RETIE (Spawn en Portería, Vestidores EPP, 5 Reglas de Oro LOTO y Recorrido de 12 Estaciones con NPCs)

- **Modo de Orquestación:** Paralelizable en Fase 2 (Independiente de Bloques 4 y 5).
- **Contexto de Entrada Obligatorio:**
  - `.agent/skills/industrial-plant-simulation/SKILL.md` (Sección 6).
  - `SimuladorPlantaGodot/scenes/infrastructure/FactoryEntranceAndLockers.tscn`, `SimuladorPlantaGodot/scripts/interactive/LockerEPPStation.gd`, `SimuladorPlantaGodot/scripts/interactive/WorkerNPC.gd`.
- **Auditoría de Modelos 3D:**
  - Utilizar los modelos de trabajadores ya descargados en `Modelos descargados/` (`trabajador_jefe_planta.glb`, `trabajador_sst.glb`, `trabajador_mantenimiento.glb`, `trabajador_logistica.glb`, `trabajador_operario.glb`). Si se requiere algún modelo adicional de mobiliario o EPP que no esté en `Modelos descargados/`, detenerse y solicitarlo al usuario.
- **Archivos Objetivo a Crear / Modificar:**
  - `SimuladorPlantaGodot/scripts/tutorial/TutorialInductionManager.gd`
  - `SimuladorPlantaGodot/scripts/tutorial/LotoGoldenRulesController.gd`
  - `SimuladorPlantaGodot/scripts/interactive/LockerEPPStation.gd`
  - `SimuladorPlantaGodot/scenes/infrastructure/FactoryEntranceAndLockers.tscn`
- **Especificaciones de Implementación:**
  1. **Etapa 1 — Spawn en Portería Exterior:** El jugador (`PlayerOperator`) hace spawn en la entrada exterior de AgroMolinos del Valle S.A., donde el Inspector SST (`WorkerSafetyAuditor`) le da la bienvenida normada por el RETIE y le entrega la Tablet Industrial.
  2. **Etapa 2 — Vestidores y Enclavamiento de EPP (RETIE Art. 20 / OSHA 1910):** Interacción en los casilleros para equipar las 5 piezas obligatorias: (1) Casco dieléctrico Clase E, (2) Gafas ANSI Z87.1, (3) Protección auditiva NRR $28\text{ dB}$, (4) Guantes dieléctricos Clase 0 ($1000\text{ V}$) y (5) Botas dieléctricas $18\text{ kV}$. La esclusa/puerta hacia la nave de producción se desbloquea únicamente cuando las 5 prendas están equipadas.
  3. **Etapa 3 — Ejecución Secuencial de las 5 Reglas de Oro (LOTO) en el CCM 460 V:**
     - Regla 1: Abrir seccionador principal (corte visible).
     - Regla 2: Colocar candado y tarjeta LOTO (Herramienta `3`).
     - Regla 3: Medir ausencia de tensión ($0.0\text{ V}$) en L1-L2-L3 con multímetro CAT III (Herramienta `4`).
     - Regla 4: Instalar puesta a tierra temporal y en cortocircuito.
     - Regla 5: Delimitar zona protegida de trabajo.
  4. **Etapa 4 — Recorrido Guiado por las 12 Estaciones de la Planta:** Waypoints interactivos con explicación técnica en cada estación (Portería, Subestación 500 kVA, Báscula, CCM 460 V, Silos, Elevador, Molino 10 HP, Ciclón ATEX, Ensacado, Racks, Despacho y Mezzanine CCTV).
- **Criterio de Aceptación TDD Headless:**
  - `TutorialInductionManager` valida la máquina de estados: bloquea el acceso sin EPP completo, valida el orden estricto $1 \to 2 \to 3 \to 4 \to 5$ de las Reglas de Oro y registra el progreso de las 12 estaciones.
- **Prompt para Argon (Bloque 3):**
  > *"Ejecuta el Bloque 3 siguiendo `.agent/skills/industrial-plant-simulation/SKILL.md` (Sección 6). Implementa `TutorialInductionManager.gd` y `LotoGoldenRulesController.gd` con spawn en portería, vestidor EPP con enclavamiento de puerta, ejecución de las 5 Reglas de Oro en el CCM 460 V y recorrido guiado por las 12 estaciones usando los NPCs de `scenes/workers/`. Recuerda no crear modelos 3D procedurales."*

---

### 🔹 BLOQUE 4: Cadena de Producción Secuencial Animada y Logística de Camiones

- **Modo de Orquestación:** Paralelizable en Fase 2 (Independiente de Bloques 3 y 5).
- **Contexto de Entrada Obligatorio:**
  - `.agent/skills/industrial-plant-simulation/SKILL.md` (Sección 7).
  - `SimuladorPlantaGodot/scenes/main.tscn` y `SimuladorPlantaGodot/scenes/equipment/MotorMillUnit.tscn`.
- **Auditoría de Modelos 3D (Regla Estricta):**
  - Inspeccionar si dentro de `planta_completa.glb` ya existen los nodos de camiones, cintas transportadoras, tolvas y estanterías para animarlos directamente moviendo sus `Node3D` / `PathFollow3D`.
  - **Si se requiere un modelo independiente de camión o montacargas que no se encuentre dentro de `planta_completa.glb` ni en `Modelos descargados/`, DETENERSE y solicitarlo al usuario para que lo agregue a `Modelos descargados/` (prohibido crear camiones con cajas CSG).**
- **Archivos Objetivo a Crear / Modificar:**
  - `SimuladorPlantaGodot/scripts/production/AnimatedProductionLogistics.gd`
  - `SimuladorPlantaGodot/scenes/production/ProductionChainFlow.tscn`
- **Especificaciones de Implementación:**
  1. **Fase 1 (Recepción y Descarga):** Animación cinemática por `Path3D` / `Tween` de llegada a báscula, basculación y descarga de cereal con `GPUParticles3D`.
  2. **Fase 2 (Elevación y Alimentación a Tolva):** Flujo visual continuo hacia la tolva pulmón del molino `M-101` a razón nominal de $\dot{m} = 1.0\text{ kg/s}$.
  3. **Fase 3 (Molienda a 1750 RPM):** Rotación física del eje/polea proporcional a la velocidad real $\omega_m$ del motor de $10\text{ HP}$ (si el motor se detiene o cala por atasco, toda la línea aguas abajo se detiene de forma realista).
  4. **Fase 4, 5 y 6 (Ensacado de 50 kg, Almacenaje en Racks y Despacho):** Desplazamiento de sacos de $50\text{ kg}$ sobre la banda transportadora, acumulación en estibas y ciclo de salida en el muelle de despacho.
- **Criterio de Aceptación TDD Headless:**
  - `AnimatedProductionLogistics` sincroniza la tasa de producción con las RPM reales del motor (`rpm > 100` activa el flujo; `rpm == 0` detiene el flujo de salida).
- **Prompt para Argon (Bloque 4):**
  > *"Ejecuta el Bloque 4 siguiendo `.agent/skills/industrial-plant-simulation/SKILL.md` (Sección 7). Implementa `AnimatedProductionLogistics.gd` y `ProductionChainFlow.tscn` animando los nodos existentes en `planta_completa.glb` y partículas `GPUParticles3D` sincronizadas con las RPM reales del motor de 10 HP. Cumple estrictamente la prohibición de modelos 3D procedurales; si falta un modelo 3D externo en `Modelos descargados/`, solicítalo al usuario."*

---

### 🔹 BLOQUE 5: Inducción Diegética de las 5 Fallas Físicas en el Mundo 3D (Cero Botones en Interfaz)

- **Modo de Orquestación:** Paralelizable en Fase 2 (Se acopla con el motor del Bloque 2).
- **Contexto de Entrada Obligatorio:**
  - `.agent/skills/industrial-plant-simulation/SKILL.md` (Sección 9).
  - `SimuladorPlantaGodot/scripts/interactive/PhysicalCableConductor.gd`, `PhysicalHopperFeeder.gd`, `PhysicalBreakerPanel.gd`, `VentilationCover.gd`, `MechanicalBolt.gd`, `InteractiveGrainBag.gd`.
- **Archivos Objetivo a Crear / Modificar:**
  - `SimuladorPlantaGodot/scripts/interactive/PhysicalCableConductor.gd`
  - `SimuladorPlantaGodot/scripts/interactive/PhysicalHopperFeeder.gd`
  - `SimuladorPlantaGodot/scripts/interactive/PhysicalBreakerPanel.gd`
  - `SimuladorPlantaGodot/scripts/interactive/VentilationCover.gd`
  - `SimuladorPlantaGodot/scripts/interactive/MechanicalBolt.gd`
  - `SimuladorPlantaGodot/scripts/interactive/PlayerOperator.gd`
- **Especificaciones de Implementación:**
  1. **Falla Física 1 — Corte y Reparación de Conductores Trifásicos (L1, L2, L3):**
     - Con Alicates Dieléctricos (Tecla `2`), al interactuar sobre el cable de la Fase L3 se separa físicamente el conductor, dispara chispas `GPUParticles3D` de arco eléctrico, anula $I_C = 0.0\text{ A}$, eleva $I_A, I_B$ por $\sqrt{3}$ ($\approx 23.4\text{ A}$), sube el $IUF > 50\%$ y genera vibración de $120\text{ Hz}$ en Zona D ($> 4.5\text{ mm/s}$). Permite reparación física una vez aplicado LOTO.
  2. **Falla Física 2 — Sobrealimentación Manual de Sacos de 50 kg en Tolva:**
     - Con Mano (Tecla `1`), el operario recoge bultos físicos (`RigidBody3D` de $50\text{ kg}$) y los vierte dentro del `Area3D` de la boca de la tolva. Arrojar $2$ o más bultos seguidos eleva el par de carga por encima de $T_{max} = 101.75\text{ N}\cdot\text{m}$, bloqueando el rotor a $0\text{ RPM}$ con corriente $I_{LRA} \approx 81.0\text{ A}$. Permite desatascar físicamente la tolva.
  3. **Falla Física 3 — Manipulación de Breakers en el Tablero CCM 460 V:**
     - Interacción física sobre las palancas del CCM (`PhysicalBreakerPanel.gd`): posición *Normal ($460\text{ V}$)*, posición *Falso Contacto / Brownout ($340\text{ V}$, caída cuadrática de par al $54.6\%$ y parpadeo de luces de la nave)* y posición *Abierto ($0\text{ V}$, corte para Regla de Oro 1)*.
  4. **Falla Física 4 — Obstrucción de Rejilla de Ventilación (`VentilationCover.gd`):**
     - Acumulación física de tamo/polvo de cereal en la carcasa del motor que triplica $R_{th}$ de $0.068$ a $0.210^\circ\text{C/W}$, provocando sobrecalentamiento progresivo $> 95^\circ\text{C}$. Se limpia físicamente interactuando sobre la rejilla.
  5. **Falla Física 5 — Aflojamiento / Apriete de Pernos de Bancada (`MechanicalBolt.gd`):**
     - Con Llave Mecánica (Tecla `5`), aflojar los pernos de anclaje del motor introduce excentricidad y desalineación angular, disparando la vibración RMS a $5.6\text{ mm/s}$ (Zona D ISO 10816-3). Se corrige reapretando con la llave.
- **Criterio de Aceptación TDD Headless:**
  - Las 5 interacciones físicas modifican directamente el estado físico del motor y permiten tanto inducir la falla como repararla físicamente sin un solo botón 2D en el HUD.
- **Prompt para Argon (Bloque 5):**
  > *"Ejecuta el Bloque 5 siguiendo `.agent/skills/industrial-plant-simulation/SKILL.md` (Sección 9). Perfecciona los 5 scripts de interacción física diegética (`PhysicalCableConductor.gd`, `PhysicalHopperFeeder.gd`, `PhysicalBreakerPanel.gd`, `VentilationCover.gd`, `MechanicalBolt.gd`) incluyendo tanto la inducción física de la avería como su reparación física en 3D con herramientas. Certifica las 5 fallas en `headless_verify.gd`."*

---

### 🔹 BLOQUE 6: Motor de Inferencia Edge AI Nativo en GDScript (MLP 8-16-8-4, SVM RBF, MHI, RUL y Matriz RCM)

- **Modo de Orquestación:** Secuencial en Fase 3 (Conecta la física de los Bloques 2 y 5 con la Tablet del Bloque 7).
- **Contexto de Entrada Obligatorio:**
  - `.agent/skills/industrial-plant-simulation/SKILL.md` (Sección 10).
  - `Avance 2/Informe/IA/generate_dataset.m`, `train_classifiers.m` y `MotorFaultDiagnosticGUI.m`.
- **Archivos Objetivo a Crear / Modificar:**
  - `SimuladorPlantaGodot/scripts/ai/EdgeAIEngine.gd`
  - `SimuladorPlantaGodot/scripts/core/SimulationManager.gd`
- **Especificaciones de Implementación:**
  1. **Reemplazo Total de Dependencias Externas por Inferencia 100% Nativa In-Game (`EdgeAIEngine.gd`):**
     - Implementar en GDScript puro la evaluación a $10\text{ Hz}$ del vector $\mathbf{x} = [I_{RMS}, IUF, THD, V_{RMS}, T_w, \frac{dT}{dt}, Vib_{RMS}, Vib_{peak}]^T$.
     - **Inferencia MLP ($8 \to 16 \to 8 \to 4$) y SVM RBF:** Normalización Z-Score con las medias $\mu$ y desviaciones $\sigma$ del dataset de `Avance 2`, propagación hacia adelante con activación ReLU y Softmax para obtener las probabilidades exactas $[P_{normal}, P_{termica}, P_{electrica}, P_{mecanica}]$ y el grado de certeza ($\%$).
  2. **Cálculo en Tiempo Real de MHI (*Motor Health Index*) y RUL (*Remaining Useful Life*):**
     - $\text{MHI} \in [0\%, 100\%]$ ponderando desviación térmica, severidad vibratoria ISO 10816-3 y desbalance eléctrico $IUF$.
     - $\text{RUL}$ en horas operativas remanentes basado en la ley de Arrhenius (degradación térmica del aislamiento Clase F cada $+10^\circ\text{C}$) y fatiga de rodamientos SKF 6308 ($L_{10h}$).
  3. **Generador Automático de Prescripción RCM / RETIE:**
     - Emitir por `EventBus.ai_alert_received` el diccionario estructurado con: `severity` (`NORMAL`, `WARNING`, `CRITICAL`), `predicted_class`, `mlp_confidence`, `svm_confidence`, `mhi`, `rul_hours`, `root_cause`, `prognosis`, `prescription` y `maintenance_steps` (array de pasos verificables alineados con la Tabla 10.3 de `SKILL.md`).
- **Criterio de Aceptación TDD Headless:**
  - Ante operación nominal, `EdgeAIEngine` clasifica `NORMAL` con $\text{MHI} > 92\%$. Ante corte de L3 clasifica `FALLA ELÉCTRICA` con certeza $> 95\%$. Ante perno flojo clasifica `FALLA MECÁNICA`. Ante sobrealimentación/ventilación obstruida clasifica `SOBRECALENTAMIENTO`.
- **Prompt para Argon (Bloque 6):**
  > *"Ejecuta el Bloque 6 siguiendo `.agent/skills/industrial-plant-simulation/SKILL.md` (Sección 10) y los scripts de `Avance 2/Informe/IA/`. Crea `EdgeAIEngine.gd` en `SimuladorPlantaGodot/scripts/ai/` para ejecutar de forma 100% nativa dentro del juego la inferencia MLP 8-16-8-4 y SVM RBF, cálculo de MHI, RUL en horas y prescripción RCM sin depender de ningún servidor web externo."*

---

### 🔹 BLOQUE 7: Dashboard Interactivo 100% In-Game en Tablet Industrial (`[TAB]`) con Oscilogramas en Tiempo Real (*Strip Charts*)

- **Modo de Orquestación:** Secuencial en Fase 3 (Depende del Bloque 6).
- **Contexto de Entrada Obligatorio:**
  - `.agent/skills/industrial-plant-simulation/SKILL.md` (Sección 10.4).
  - `Avance 2/Informe/IA/MotorFaultDiagnosticGUI.m` y `Avance 2/Informe/imagenes/interfaz_app_designer.png`.
  - `SimuladorPlantaGodot/scenes/ui/IndustrialTablet.tscn` y `SimuladorPlantaGodot/scripts/ui/IndustrialTabletController.gd`.
- **Archivos Objetivo a Crear / Modificar:**
  - `SimuladorPlantaGodot/scripts/ui/TabletOscilloscopeChart.gd`
  - `SimuladorPlantaGodot/scripts/ui/IndustrialTabletController.gd`
  - `SimuladorPlantaGodot/scenes/ui/IndustrialTablet.tscn`
- **Especificaciones de Implementación:**
  1. **Despliegue con Tecla `[TAB]`:**
     - Al pulsar `[TAB]`, la Tablet Industrial se muestra/oculta en pantalla, alternando automáticamente `Input.MOUSE_MODE_VISIBLE` (para interactuar con pestañas y checkboxes) y `Input.MOUSE_MODE_CAPTURED` (para volver a controlar al operario).
  2. **Diseño de Alta Tecnología Similar al Dashboard de Simulaciones con IA (5 Módulos en Pantalla):**
     - **Módulo 1 (Medidores True-RMS):** Tarjetas e indicadores de barras para $V_{LL} (460\text{ V})$, $I_A, I_B, I_C$, desbalance $IUF (\%)$, $N_r (\text{RPM})$, par $T_e (\text{N}\cdot\text{m})$, potencia $P_{in} (\text{kW})$, $\cos\phi$, temperatura $T_w (^\circ\text{C})$ con gradiente $\frac{dT}{dt}$ y vibración $Vib_{RMS} (\text{mm/s})$ con semáforo ISO 10816-3 (Zona A/B verde, Zona C amarillo, Zona D rojo).
     - **Módulo 2 (Oscilogramas y Gráficas de Tendencia en Tiempo Real — `TabletOscilloscopeChart.gd`):** Nodos `Control` con renderizado vectorial nativo `_draw()` en ventana deslizante de $10\text{ s}$ a $60\text{ FPS}$ para:
       1. *Gráfica de Corrientes Trifásicas ($I_A, I_B, I_C$ vs $t$)* con trazos de colores diferenciados.
       2. *Gráfica de Temperatura de Devanados ($T_w$ vs $t$)* con líneas punteadas de umbral ($85^\circ\text{C}$ y $105^\circ\text{C}$).
       3. *Gráfica de Vibración RMS y Espectro Armónico (1X / 2X RPM)*.
     - **Módulo 3 (Panel de Diagnóstico Edge AI):** Estado clasificado en vivo con código de color, certeza del MLP ($\%$) y SVM ($\%$), barra de progreso del **Motor Health Index (MHI 0–100%)** y contador de **Vida Útil Remanente (RUL en horas)**.
     - **Módulo 4 (Alertas Push Sonoras & Checklist RCM / RETIE Interactivo):** Banner de alarma con `AudioStreamPlayer`, explicación de Causa Raíz, Pronóstico y lista de verificación con `CheckBox` interactivos que se marcan al ejecutar las correcciones físicas en planta.
     - **Módulo 5 (Optimización Energética VFD vs DOL):** Selector/indicador de modo VFD vs DOL, consumo específico instantáneo ($\text{kWh/ton}$) y contador de emisiones evitadas ($\text{kg CO}_2\text{e}$).
- **Criterio de Aceptación TDD Headless:**
  - `IndustrialTablet.tscn` instancia los 5 módulos y los nodos `TabletOscilloscopeChart`, actualiza buffers de datos sin errores al recibir señales de `EventBus` y conmuta su visibilidad con la acción `toggle_tablet` (`[TAB]`).
- **Prompt para Argon (Bloque 7):**
  > *"Ejecuta el Bloque 7 siguiendo `.agent/skills/industrial-plant-simulation/SKILL.md` (Sección 10.4). Construye `TabletOscilloscopeChart.gd` y actualiza `IndustrialTabletController.gd` e `IndustrialTablet.tscn` para que al presionar `[TAB]` se despliegue el dashboard completo dentro del juego (con gráficas en tiempo real de corriente, temperatura y vibración, diagnóstico MLP/SVM, MHI, RUL, checklist RCM y ahorro VFD/CO2e). Prohibido usar páginas web externas."*

---

### 🔹 BLOQUE 8: Centro de Monitoreo CCTV en Mezzanine, Rúbrica Académica Continua (0.0 a 5.0) y Certificación Headless QA Integral

- **Modo de Orquestación:** Secuencial Final (Integra y certifica los Bloques 1 al 7).
- **Contexto de Entrada Obligatorio:**
  - `.agent/skills/industrial-plant-simulation/SKILL.md` (Secciones 12 y 13).
  - `SimuladorPlantaGodot/scripts/tests/headless_verify.gd`.
- **Archivos Objetivo a Crear / Modificar:**
  - `SimuladorPlantaGodot/scripts/environment/MezzanineCCTVController.gd`
  - `SimuladorPlantaGodot/scripts/tutorial/SafetyEvaluationScorecard.gd`
  - `SimuladorPlantaGodot/scripts/tests/headless_verify.gd`
- **Especificaciones de Implementación:**
  1. **Centro de Control CCTV en Mezzanine:** Configurar 4 cámaras estáticas estratégicas en la planta (Molienda `M-101`, Tablero `CCM-01`, Báscula `B-201` y Despacho `D-401`) proyectadas en el panel de monitoreo y consultables desde la Tablet.
  2. **Rúbrica Académica Continua (`0.0` a `5.0` — `SafetyEvaluationScorecard.gd`):**
     - Calificación inicial de $5.0 / 5.0$, aplicando penalizaciones automáticas por actos inseguros (entrar sin casco $-0.8$, sin botas dieléctricas $-1.0$, sin protección auditiva $-0.6$, invadir $1.0\text{ m}$ del CCM sin guantes $1000\text{ V}$ $-1.5$, intervenir cables sin LOTO $-3.0$) y bonificaciones por completar las 5 Reglas de Oro y resolver fallas con la Tablet ($+1.0$).
     - Exportación automática del reporte `user://Reporte_Estudiante_RETIE.json` y visualización de la nota en el HUD y la Tablet.
  3. **Suite Maestra de Certificación Headless (`headless_verify.gd`):**
     - Ampliar la suite de pruebas para validar automáticamente los **10 puntos de control** de la Sección 13 de `SKILL.md` (compilación de todas las escenas, física Kloss, VFD vs DOL, tutorial EPP/LOTO, logística animada, las 5 fallas físicas y su reparación, inferencia IA MLP/SVM, oscilogramas de la Tablet con `[TAB]`, rúbrica académica y cero modelos procedurales prohibidos).
- **Criterio de Aceptación TDD Headless:**
  - Ejecución limpia de `godot --headless --path SimuladorPlantaGodot --script res://scripts/tests/headless_verify.gd` con **10/10 pruebas superadas (100% PASS)** y código de salida `0`.
- **Prompt para Argon (Bloque 8):**
  > *"Ejecuta el Bloque 8 siguiendo `.agent/skills/industrial-plant-simulation/SKILL.md` (Secciones 12 y 13). Implementa `MezzanineCCTVController.gd`, `SafetyEvaluationScorecard.gd` y actualiza `headless_verify.gd` para certificar los 10 puntos de control de extremo a extremo. Ejecuta el test headless hasta obtener 100% PASS con exit code 0 y purga cualquier archivo temporal."*

---

## 🚀 5. Instrucción Maestra de Disparo para Argon (Copy-Paste Prompt)

Cuando desees que **Argon (Orchestrator)** ejecute todo el proyecto de forma autónoma, utiliza la siguiente instrucción:

> **"Ejecuta el plan maestro `PLAN_EJECUCION_ARGON.md` bloque por bloque (Bloques 1 al 8), respetando estrictamente todas las directivas de `.agent/skills/industrial-plant-simulation/SKILL.md`: usa únicamente los modelos 3D descargados en `Modelos descargados/` (si falta alguno, detente y pídemelo; no crees modelos procedurales), implementa todas las fallas de manera física en 3D sin botones de interfaz, integra toda la telemetría y el dashboard con IA dentro de la Tablet del juego con la tecla `[TAB]` sin páginas web externas, y verifica cada bloque en modo headless hasta aprobar el 100% de las pruebas."**
