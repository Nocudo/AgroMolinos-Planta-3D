# 🏭 AgroMolinos del Valle S.A. — Simulador 3D de Planta Industrial & Diagnóstico Inteligente de Máquinas Eléctricas

🔗 **Repositorio Oficial en GitHub:** [https://github.com/Nocudo/AgroMolinos-Planta-3D](https://github.com/Nocudo/AgroMolinos-Planta-3D)

**Universidad de los Llanos — Facultad de Ciencias Básicas e Ingeniería**  
**Programa:** Ingeniería Electrónica  
**Asignatura:** Máquinas Eléctricas (2026-2)  
**Docente Titular:** Ing. Lauren Genith Isaza  
**Integrantes:**
- H. García (161004621)
- M. Rodríguez (161004834)
- S. Bustamante (161005037)

---

## 📋 Descripción General del Proyecto

Plataforma integral de modelado electromecánico, mantenimiento predictivo basado en Inteligencia Artificial, optimización energética con Variador de Frecuencia (VFD) y **Juego Serio Interactivo en 3D (*Serious Game* en Godot Engine 4.7 con Vulkan 1.3 Forward+)** para la **Planta Molino de Granos** de la empresa **AgroMolinos del Valle S.A.**, desarrollada bajo el paradigma de **Transición de Industria 4.0 a Industria 5.0** (centrada en el humano, resiliente y sostenible).

### Alineación con los Cortes Evaluativos del Curso

1. **Avance 1 (Corte 1 — 20%): Caracterización y Modelado Electromecánico**
   - Caracterización técnica del motor trifásico de inducción jaula de ardilla ($10\text{ HP}, 460\text{ V}, 60\text{ Hz}$, diseño NEMA B / Clase IE3) conforme al **RETIE** (Capítulo 2) y estándares **NEMA MG-1 / IEC 60034-1**.
   - Modelado dinámico en MATLAB/Simulink (`InductionMachineDTC.slx`) con Control Directo de Par (DTC) y análisis de transitorios eléctricos, térmicos y mecánicos.
2. **Avance 2 (Corte 2 — 30%): Mantenimiento Predictivo (RCM) e Inteligencia Artificial**
   - Generación de dataset sintético-experimental con vector de 8 características: $[I_{RMS}, IUF, THD, V_{RMS}, T_w, \frac{dT}{dt}, Vib_{RMS}, Vib_{peak}]$.
   - Entrenamiento y validación de clasificadores de diagnóstico: **Red Neuronal Multicapa (MLP $8 \to 16 \to 8 \to 4$)** con **$99.17\%$ de exactitud** y **Máquina de Soporte Vectorial (SVM con kernel RBF)** con **$98.75\%$ de exactitud**.
   - Clasificación automática de 4 estados: *Normal*, *Sobrecalentamiento*, *Falla Eléctrica (monofasización/desbalance)* y *Falla Mecánica (rodamientos/desalineación)*.
3. **Avance 3 & Proyecto Final (Corte 3 — 40% + 10% Sustentación): Simulador 3D Interactivo, Optimización Energética e Informe IEEE**
   - **Serious Game en Godot 4.7 (Vulkan 1.3 Forward+)** sobre el modelo 3D de la planta industrial (`planta_completa.glb`), con físicas electromecánicas de Kloss en tiempo real, recorrido normativo RETIE de 19 estaciones, cadena de producción y logística animada e inducción diegética de fallas físicas en el mundo 3D (sin botones de falla en UI).
   - **Telemetría 100% In-Game en Tablet Industrial Minimalista (`[TAB]`):** Dashboard SCADA nativo de 8 pestañas integrado dentro del juego (sin páginas web externas, sin botones ficticios ni botón «Salir»), con oscilogramas en tiempo real, cámaras 3D en vivo, inferencia Edge AI, *Motor Health Index* (MHI), *Remaining Useful Life* (RUL), parada de máquinas exclusiva y rúbrica RETIE.
   - **Optimización Energética y Sostenibilidad:** Comparativa entre Arranque Directo (DOL) y Variador de Frecuencia (VFD escalar V/f con lazo PID), logrando un **ahorro energético del $28.38\%$** ($7.52\text{ kWh/ton}$ frente a $10.50\text{ kWh/ton}$) y mitigando **$488.7\text{ kg CO}_2\text{e/año}$** (factor UPME Colombia $0.164\text{ kg CO}_2\text{e/kWh}$).

---

## ⚡ Parámetros Técnicos Nominales del Motor Crítico (M-101)

| Parámetro Electromecánico | Símbolo | Valor Nominal | Unidad | Observaciones Normativas |
| :--- | :---: | :---: | :---: | :--- |
| **Potencia Mecánica Nominal** | $P_n$ | **10.0 (7457.0)** | $\text{HP (W)}$ | Potencia en el eje a plena carga |
| **Tensión Nominal Línea-Línea** | $V_n$ | **460.0** | $\text{V AC}$ | Conexión Estrella ($Y$), trifásico |
| **Frecuencia Eléctrica Nominal** | $f_n$ | **60.0** | $\text{Hz}$ | Red industrial colombiana (RETIE) |
| **Pares de Polos / Polos** | $p / P$ | **2 / 4** | — | Velocidad sincrónica $N_s = 1800\text{ RPM}$ |
| **Velocidad Nominal del Rotor** | $N_r$ | **1750.0** | $\text{RPM}$ | Deslizamiento nominal $s_n \approx 2.78\%$ |
| **Corriente Nominal de Línea** | $I_{FLA}$ | **13.5** | $\text{A RMS}$ | A plena carga nominal ($460\text{ V}$) |
| **Corriente de Rotor Bloqueado** | $I_{LRA}$ | **81.0** | $\text{A RMS}$ | $6 \times I_{FLA}$ en arranque directo (DOL) |
| **Par Nominal Mecánico** | $T_n$ | **40.7** | $\text{N}\cdot\text{m}$ | A $1750\text{ RPM}$ |
| **Par Máximo de Vuelco (Kloss)** | $T_{max}$ | **101.75** | $\text{N}\cdot\text{m}$ | $2.5 \times T_n$ a deslizamiento crítico $s_{max} = 0.15$ |
| **Factor de Potencia Nominal** | $\cos\phi$ | **0.85** | — | Inductivo a plena carga |
| **Eficiencia Energética** | $\eta$ | **91.7** | $\%$ | Clase IE3 / NEMA Premium Efficiency |
| **Parámetros del Circuito Equivalente** | $R_s, R_r'$ | **0.435 / 0.816** | $\Omega$ | Resistencias de estator y rotor referido |
| **Inductancias Equivalentes** | $L_{ls}, L_m$ | **2.0 / 69.3** | $\text{mH}$ | Dispersión ($L_{ls}=L_{lr}'$) y magnetizante ($L_m$) |
| **Inercia Total Acoplada** | $J_{total}$ | **0.35** | $\text{kg}\cdot\text{m}^2$ | Rotor motor ($0.045$) + Molino de martillos ($0.305$) |
| **Clase de Aislamiento Térmico** | — | **Clase F ($155^\circ\text{C}$)** | — | Alarma preventiva a $85^\circ\text{C}$, disparo a $105^\circ\text{C}$ |

---

## 🎮 Características del Serious Game en Godot 4.7 (`SimuladorPlantaGodot/`)

### 1. Motor Gráfico Vulkan 1.3, Texturas de Baja Resolución y Optimización de Rendimiento
- **Renderizado Nativo Vulkan 1.3 Forward+:** Configurado con profundidad Reverse-Z de 32 bits, `CameraFPS` calibrada (`near = 0.14 m`, `far = 260 m`) y eliminación integral de *Z-fighting* coplanar y mallas duplicadas.
- **Activos 3D Descargados con 37 Texturas Procedurales de Baja Resolución:** Todos los modelos 3D descargados (`planta_completa.glb`, `panel_control.glb` y los 6 `trabajador_*.glb`) conservan su geometría original intacta, mientras que el **100% de las texturas pesadas originales** fueron eliminadas y reemplazadas por **37 texturas procedurales limpias de baja resolución** (`64×64` para arquitectura/equipos y `128×128` horneadas desde geometría 3D para uniformes de operarios, `152.3 KB` totales) con compresión VRAM **Basis Universal** (reducción $>97\%$ a $99.9\%$ en peso de texturas incrustadas).
- **Optimización Espacial y Puertas Alineadas por PCA:** `PlantVisibilityOptimizer.gd` aplica *batching* espacial en celdas de $16\text{ m}$ por bandas LOD, oclusión exterior Este/Oeste y *culling* vehicular a distancia; `PlantSpatialBuilder.gd` genera 470 colisionadores sólidos y alinea milimétricamente las **28 puertas interactivas** (23 batientes/dobles alineadas al plano exacto del marco por PCA + portones enrollables y corredizos).
- **Demarcación Vial y Seguridad (OSHA / RETIE / ATEX):** Delimitación en piso de la zona de molienda (amarillo/negro), perímetro de riesgo eléctrico de $1.0\text{ m}$ frente al tablero CCM $460\text{ V}$ (rojo RETIE Art. 20 / NFPA 70E), pasillos peatonales seguros (verde), recepción (azul), almacén (blanco) y zona de polvo combustible (NFPA 61 / ATEX Zona 22).

### 2. Modo Tutorial Interactivo y Recorrido Seguro de 19 Estaciones (RETIE & 5 Reglas de Oro)
- **Inicio en Portería y Diálogo Directo con el Supervisor SST:** El operario inicia en primera persona en la Portería exterior. Los menús informativos (bienvenida inicial e ingreso al **Curso SST / Quiz RETIE**) no se abren automáticamente al llegar a una zona, sino **únicamente cuando el jugador interactúa directamente con el Supervisor SST (`E` / Clic)**, incluyendo la historia de la empresa antes de ingresar a planta.
- **Vestidores y Enclavamiento de EPP (6/6):** Paso obligatorio por los lockers para equipar las 6 prendas reglamentarias (casco dieléctrico Clase E, gafas ANSI Z87.1, protectores auditivos, guantes dieléctricos Clase 0, botas dieléctricas $18\text{ kV}$ y traje ignífugo), con actualización en vivo del avatar 3D del HUD (`SIN EPP` ↔ `EPP 6/6 OK`).
- **Ejecución Guiada de las 5 Reglas de Oro (LOTO):** En el tablero CCM $460\text{ V}$, el jugador ejecuta en orden estricto: (1) Corte visible, (2) Bloqueo y tarjeteo LOTO, (3) Verificación de ausencia de tensión con multímetro CAT III, (4) Puesta a tierra y en cortocircuito, y (5) Señalización y delimitación.
- **Recorrido Guiado Seguro por 19 Estaciones:** Línea guía en suelo sin cruces por muros ni líneas de peligro que recorre máquina por máquina desde Portería y Vestidores hasta la zona de carga, molienda, secado, ciclones, almacén y equipos exteriores (intercambiador, horno térmico, extracción, soplador y ductos de aire), resaltando con brillo azul parpadeante la máquina explicada.

### 3. Cadena de Producción Animada y Logística Vehicular Natural
- **Camiones Articulados en Vías Pavimentadas:** Rutas estrictamente sobre adoquín/baldosa atravesando los dos portones automáticos corredizos, con giro natural de tractocamión articulado (sin separación del semirremolque respecto a la quinta rueda) y parqueo exacto frente a la puerta amarilla izquierda de despacho.
- **Cargue Manual de Sacos por Operarios Animados:** Los operarios de logística y muelle toman y cargan manualmente los sacos de $50\text{ kg}$ hacia el camión estacionado en la puerta izquierda usando caminata biomecánica (`carry_walk`), **únicamente cuando el camión está físicamente parqueado** (sin sacos flotantes ni *glow* artificial en camiones o bolsas).
- **Flujo Electromecánico Sincronizado:** El tornillo sinfín, el flujo de grano/harina y la tasa de producción responden en tiempo real a las RPM del motor trifásico de $10\text{ HP}$.

### 4. Inducción Diegética de Fallas Físicas en el Mundo 3D (Cero Botones de Falla en UI)
Todas las averías se inducen y reparan mediante acciones físicas directas sobre los equipos 3D:
1. **Corte Físico de Cables con Alicates (Pérdida de Fase L3 / Monofasización):** Al cortar la fase L3 del alimentador, $I_C$ cae a $0\text{ A}$, $I_A$ e $I_B$ se elevan por $\sqrt{3}$ ($\approx 23.4\text{ A}$), se dispara arco eléctrico y la vibración a $120\text{ Hz}$ escala a Zona D ($> 4.5\text{ mm/s}$ ISO 10816-3).
2. **Sobrealimentación Manual en Tolva (Atasco y Rotor Bloqueado):** Arrojar múltiples bultos de $50\text{ kg}$ a la tolva eleva el par por encima de $T_{max} = 101.75\text{ N}\cdot\text{m}$, frena el rotor a $0\text{ RPM}$ y eleva la corriente a $I_{LRA} = 81.0\text{ A}$.
3. **Manipulación de Breakers en Tablero CCM 460 V (Bajones de Tensión):** Provoca caída de tensión a $340\text{ V}$, reduciendo cuadráticamente el par ($T_e \propto V^2$).
4. **Obstrucción de Ventilación y Soltura de Pernos de Bancada:** Eleva $R_{th}$ ($0.068 \to 0.210^\circ\text{C/W}$) para sobrecalentamiento progresivo y genera vibración mecánica armónica 1X/2X RPM corregible con la llave `3/4"`.

### 5. HUD Limpio y Tablet Industrial Minimalista 100% In-Game (`[TAB]`)
> **Sin páginas web externas:** Todo el monitoreo SCADA, cámaras 3D y diagnóstico Edge AI operan nativamente dentro del juego.

- **HUD Minimalista:** Mira central blanca fija (`+`) con borde negro fino de $1\text{ px}$ que nunca cambia de color, barra inferior con avatar 3D reactivo al EPP y 5 ranuras de herramientas, subtítulos naturales de operarios sin sufijos redundantes de ubicación y sin botón flotante de «Saltar tutorial».
- **Tablet Industrial Limpia (`1228×748` chasis / `1180×700` pantalla):** Diseño minimalista sin botones físicos ficticios ni botón «Salir» (se abre y cierra directamente con **`[TAB]`** o **`[ESC]`**), con botón exclusivo de **Parar / Reanudar Máquinas** y **8 pestañas funcionales**:
  1. **Monitoreo IoT:** Telemetría True-RMS y gráficas en vivo de las 15 máquinas + CCM, modo VFD/DOL, control de audio y alertas push sonoras.
  2. **Cámaras:** Visores 3D interactivos en vivo de planta (15 máquinas + CCM + vistas generales) y los 4 operarios.
  3. **RETIE:** Seguimiento en vivo de las 5 Reglas de Oro LOTO, estado EPP y matriz de riesgos eléctricos.
  4. **Operarios:** Estado del turno y registro manual de personal en planta.
  5. **Riesgos:** Evaluación de riesgos eléctricos, mecánicos, térmicos y ATEX.
  6. **Fisiología IEC:** Curvas de efectos fisiológicos de la corriente eléctrica (IEC 60479-1).
  7. **Hardware & IA:** Diagnóstico Edge AI nativo (MLP & SVM RBF), **MHI**, **RUL**, causa raíz, pronóstico y checklist interactivo RCM.
  8. **Rúbrica:** Calificación académica RETIE (`0.0` a `5.0`), historial de infracciones/bonificaciones y avance de las 19 estaciones.

---

## 📂 Estructura del Repositorio

```text
├── .agent/skills/industrial-plant-simulation/
│   └── SKILL.md                        # Especificación técnica maestra de la skill del proyecto
├── .gemini/skills/industrial-plant-simulation/
│   └── SKILL.md                        # Réplica sincronizada de la skill para el entorno Gemini
├── Avance 1/                           # Entregable Corte 1: Caracterización RETIE y modelo DTC en Simulink
│   ├── Informe/                        # Informe IEEE en LaTeX y curvas operacionales
│   └── simulaciones/                   # Modelo InductionMachineDTC.slx y parámetros del motor
├── Avance 2/                           # Entregable Corte 2: Mantenimiento Predictivo RCM e IA
│   ├── abrir_panel.m                   # Lanzador del panel de diagnóstico en MATLAB App Designer
│   ├── Informe/IA/                     # Entrenamiento de MLP, SVM RBF y generador de dataset
│   └── Informe/simulaciones/           # Modelos de inyección de fallas en Simulink
├── Modelos descargados/                # Fuentes 3D originales (.skp)
├── SimuladorPlantaGodot/               # PROYECTO MAESTRO DEL SERIOUS GAME EN GODOT 4.7 (VULKAN 1.3)
│   ├── assets/models/                  # 8 modelos .glb optimizados (sin texturas antiguas, Basis Universal)
│   ├── assets/textures_lowres/         # 37 texturas procedurales 64x64 / 128x128 (152.3 KB total)
│   ├── scenes/                         # Escenas modulares (.tscn): environment, equipment, infrastructure, player, production, ui, workers
│   ├── scripts/                        # Módulos GDScript 2.0: ai, core, environment, interactive, physics, production, tests, tutorial, ui
│   └── project.godot                   # Configuración de Godot 4.7 Forward+ (Vulkan 1.3) e Input Map
├── requirements.txt                    # Dependencias Python y requisitos del entorno
├── INSTALAR_DEPENDENCIAS.bat           # Instalador 1-clic (Godot 4.7, Git, Python, requirements.txt y caché Godot)
├── INICIAR_SIMULADOR_GODOT.bat         # Lanzador 1-clic del simulador interactivo
├── ABRIR_EDITOR_GODOT.bat              # Lanzador 1-clic del editor de Godot 4.7
├── PLAN_EJECUCION_ARGON.md             # Plan maestro en 8 bloques y estado de certificación QA 10/10
├── PROYECTO FINAL_MAQUINAS 20262.pdf   # Guía oficial y rúbrica de evaluación de la asignatura
└── README.md                           # Documentación general del proyecto
```

---

## 🛠️ Instalación Rápida (1 Clic en Windows)

1. **Clona el repositorio:**
   ```bash
   git clone https://github.com/Nocudo/AgroMolinos-Planta-3D.git
   cd AgroMolinos-Planta-3D
   ```
2. **Instala todo automáticamente:** Haz doble clic en **`INSTALAR_DEPENDENCIAS.bat`**.
   - Verifica e instala **Git**, **Godot Engine 4.7** y **Python 3.12** mediante WinGet si faltan en el equipo.
   - Instala todos los paquetes listados en **`requirements.txt`** (`numpy`, `pillow`, `trimesh`, `scipy`, `matplotlib`, `pandas`, `scikit-learn`).
   - Pre-importa automáticamente la caché de modelos y texturas de `SimuladorPlantaGodot/`.
3. *(Opcional — solo paquetes Python por consola):*
   ```bash
   python -m pip install --upgrade pip
   python -m pip install -r requirements.txt
   ```

---

## 🚀 Ejecución Rápida y Controles en el Juego

### Lanzadores de 1 Clic (Windows)
- **Instalar Dependencias y Entorno:** Doble clic en `INSTALAR_DEPENDENCIAS.bat`.
- **Jugar a la Simulación Interactiva:** Doble clic en `INICIAR_SIMULADOR_GODOT.bat`.
- **Editar Escenas en Godot 4.7:** Doble clic en `ABRIR_EDITOR_GODOT.bat`.

### Controles del Operario en el Juego
| Tecla / Acción | Función en la Simulación |
| :---: | :--- |
| **`W`, `A`, `S`, `D`** | Desplazamiento en primera persona por la planta industrial |
| **`Shift`** | Caminata rápida / Sprint |
| **`Espacio`** | Saltar |
| **`Mouse`** | Vista en primera persona con mira central blanca fija |
| **`E` / Clic Izquierdo** | Interactuar (hablar con el Supervisor SST y operarios, abrir puertas, equipar EPP, manipular breakers, cargar sacos, usar herramientas) |
| **`1` – `5` / Rueda del Mouse** | Seleccionar herramienta (`1`: Manos, `2`: Alicates dieléctricos, `3`: Llave 3/4", `4`: Multímetro CAT III, `5`: Kit LOTO) |
| **`[TAB]` o `T`** | Abrir / cerrar la **Tablet Industrial SCADA** (incluye botón exclusivo **Parar / Reanudar Máquinas**) |
| **`ESC`** | Cerrar la Tablet/modales activos o abrir el **Menú de Pausa y Audio** |
| **`F11`** | Alternar pantalla completa / ventana |

---

## 🧪 Verificación Autónoma QA Headless (`10/10 PASS`)

Para certificar escenas, física de Kloss, VFD vs DOL, tutorial RETIE/LOTO, logística animada, las 5 fallas físicas, Edge AI (MLP/SVM), Tablet SCADA, CCTV/Rúbrica y política de activos 3D desde consola:

```powershell
godot --headless --audio-driver Dummy --path SimuladorPlantaGodot --script res://scripts/tests/headless_verify.gd
```

Resultado esperado: `=== RESULTADO QA HEADLESS: 10 PASARON | 0 FALLARON ===` con código de salida `0`.

---

## 👥 Guía Rápida de Colaboración con Git

Repositorio oficial: **`https://github.com/Nocudo/AgroMolinos-Planta-3D`**

```bash
# 1. Clonar el repositorio oficial
git clone https://github.com/Nocudo/AgroMolinos-Planta-3D.git
cd AgroMolinos-Planta-3D

# 2. Actualizar cambios desde la rama principal
git pull origin main

# 3. Guardar cambios locales y subir a GitHub
git add .
git commit -m "feat: descripción de la mejora implementada"
git push origin main
```
