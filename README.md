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

Plataforma integral de modelado electromecánico, mantenimiento predictivo basado en Inteligencia Artificial, optimización energética con Variador de Frecuencia (VFD) y **Juego Serio Interactivo en 3D (*Serious Game* en Godot Engine 4.7)** para la **Planta Molino de Granos** de la empresa **AgroMolinos del Valle S.A.**, desarrollada bajo el paradigma de **Transición de Industria 4.0 a Industria 5.0** (centrada en el humano, resiliente y sostenible).

### Alineación con los Cortes Evaluativos del Curso

1. **Avance 1 (Corte 1 — 20%): Caracterización y Modelado Electromecánico**
   - Caracterización técnica del motor trifásico de inducción jaula de ardilla ($10\text{ HP}, 460\text{ V}, 60\text{ Hz}$, diseño NEMA B / Clase IE3) conforme al **RETIE** (Capítulo 2) y estándares **NEMA MG-1 / IEC 60034-1**.
   - Modelado dinámico en MATLAB/Simulink (`InductionMachineDTC.slx`) con Control Directo de Par (DTC) y análisis de transitorios eléctricos, térmicos y mecánicos.
2. **Avance 2 (Corte 2 — 30%): Mantenimiento Predictivo (RCM) e Inteligencia Artificial**
   - Generación de dataset sintético-experimental con vector de 8 características: $[I_{RMS}, IUF, THD, V_{RMS}, T_w, \frac{dT}{dt}, Vib_{RMS}, Vib_{peak}]$.
   - Entrenamiento y validación de clasificadores de diagnóstico: **Red Neuronal Multicapa (MLP $8 \to 16 \to 8 \to 4$)** con **$99.17\%$ de exactitud** y **Máquina de Soporte Vectorial (SVM con kernel RBF)** con **$98.75\%$ de exactitud**.
   - Clasificación automática de 4 estados: *Normal*, *Sobrecalentamiento*, *Falla Eléctrica (monofasización/desbalance)* y *Falla Mecánica (rodamientos/desalineación)*.
3. **Avance 3 & Proyecto Final (Corte 3 — 40% + 10% Sustentación): Simulador 3D Interactivo, Optimización Energética e Informe IEEE**
   - **Serious Game en Godot 4.7** sobre el modelo 3D de la planta industrial (`planta_completa.glb`), con físicas electromecánicas de Kloss en tiempo real, modo tutorial normativo RETIE, cadena de producción animada e inducción diegética de fallas físicas en el mundo 3D (sin botones de interfaz).
   - **Telemetría 100% In-Game en Tablet Industrial (`[TAB]`):** Dashboard completo integrado dentro del juego (sin páginas web externas) con oscilogramas en tiempo real, inferencia de IA, *Motor Health Index* (MHI), *Remaining Useful Life* (RUL) y ruta de mantenimiento RCM interactiva.
   - **Optimización Energética y Sostenibilidad:** Comparativa entre Arranque Directo (DOL) y Variador de Frecuencia (VFD escalar V/f con lazo PID), logrando un **ahorro energético del $28.38\%$** ($7.52\text{ kWh/ton}$ frente a $10.5\text{ kWh/ton}$) y mitigando **$488.7\text{ kg CO}_2\text{e/año}$** (factor UPME Colombia).

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

### 1. Entorno Industrial 3D, Suelo Físico, Zonificación e Iluminación PBR
- **Modelos 3D Descargados de Alta Fidelidad:** Integración directa del complejo industrial (`planta_completa.glb`, derivado de SketchUp) usando estrictamente activos 3D descargados en `Modelos descargados/`.
- **Suelo Físico y Colisiones Sólidas:** Piso industrial (`StaticBody3D` con `BoxShape3D` y acabado PBR de concreto epóxico) y colisiones trimesh/convexas en toda la maquinaria, silos, pasarelas y tableros.
- **Demarcación Vial y Seguridad (OSHA / RETIE / ATEX):** Delimitación en piso de la zona de molienda (amarillo/negro), perímetro de riesgo eléctrico de $1.0\text{ m}$ frente al tablero CCM $460\text{ V}$ (rojo RETIE Art. 20 / NFPA 70E), pasillos peatonales de $2.4\text{ m}$ (verde), área de recepción/báscula (azul), almacén de producto terminado (blanco) y atmósfera de polvo combustible (NFPA 61 / ATEX).
- **Iluminación Fotorrealista:** Configurado con `WorldEnvironment` (Tonemapping ACES, SDFGI, SSAO, SSR y *Volumetric Fog*) y matriz de campanas LED High-Bay de $5000\text{ K}$.

### 2. Modo Tutorial Interactivo (RETIE & 5 Reglas de Oro)
- **Spawn en Portería Exterior:** El operario inicia en la entrada principal de la empresa, donde recibe inducción de seguridad y su **Tablet Industrial**.
- **Vestidores y Enclavamiento de EPP:** Paso obligatorio por los casilleros para equiparse con el Equipo de Protección Personal reglamentario (casco dieléctrico Clase E, gafas ANSI Z87.1, protectores auditivos NRR $28\text{ dB}$, botas dieléctricas $18\text{ kV}$ y guantes dieléctricos Clase 0). La puerta de acceso a planta permanece bloqueada hasta completar el EPP.
- **Ejecución Guiada de las 5 Reglas de Oro (LOTO):** En el tablero CCM $460\text{ V}$, el jugador ejecuta en orden estricto: (1) Corte efectivo de tensión, (2) Bloqueo con candado y tarjeteo LOTO, (3) Verificación de ausencia de tensión con multímetro CAT III, (4) Puesta a tierra y en cortocircuito, y (5) Delimitación de la zona de trabajo.
- **Recorrido Guiado por 12 Estaciones:** Visita explicativa desde la subestación y báscula de camiones hasta los silos, sala del motor de $10\text{ HP}$, zona de ensacado y muelle de despacho.

### 3. Cadena de Producción y Logística Animada
- **Ingreso de Materia Prima:** Camión tolva animado ingresando a la báscula y descargando cereal con sistema de partículas (`GPUParticles3D`).
- **Transporte y Procesamiento:** Elevador de cangilones y tornillo sinfín alimentando el molino de martillos accionado a $1750\text{ RPM}$ por el motor trifásico de $10\text{ HP}$.
- **Ensacado, Almacenaje y Salida:** Llenado automático de bultos de $50\text{ kg}$ en cinta transportadora, estibado en estanterías y carga en camión de despacho saliendo por el portón sur.

### 4. Inducción Diegética de Fallas Físicas en el Mundo 3D (Cero Botones en Interfaz)
Todas las fallas se provocan mediante interacciones físicas directas del operario sobre los equipos 3D:
1. **Corte Físico de Cables con Alicates (Pérdida de Fase L3 / Monofasización):** Al cortar la fase L3 del alimentador, la corriente $I_C$ cae a $0\text{ A}$, las fases L1 y L2 se elevan por $\sqrt{3}$ ($\approx 23.4\text{ A}$), se genera chisporroteo de arco eléctrico y la vibración pulsante a $120\text{ Hz}$ escala a Zona D ($> 4.5\text{ mm/s}$ según ISO 10816-3).
2. **Sobrealimentación Manual en Tolva (Atasco Mecánico y Rotor Bloqueado):** Al cargar y arrojar físicamente múltiples bultos de grano de $50\text{ kg}$ dentro de la tolva sin pausa, el par resistente supera el par máximo de vuelco ($101.75\text{ N}\cdot\text{m}$), el motor cala a $0\text{ RPM}$ y la corriente se dispara a $I_{LRA} = 81.0\text{ A}$, acelerando el calentamiento $\frac{dT}{dt}$.
3. **Manipulación de Breakers en el Tablero CCM (Bajones de Tensión / *Voltage Sags*):** Al mover las palancas de seccionadores o inducir falso contacto en barraje, la tensión cae a $340\text{ V}$, reduciendo cuadráticamente el par electromagnético ($T_e \propto V^2$) y causando parpadeo en las luminarias de la nave.
4. **Obstrucción de Rejilla de Ventilación y Desajuste de Pernos de Bancada:** Elevación de la resistencia térmica $R_{th}$ (embalamiento térmico $> 105^\circ\text{C}$) y aparición de armónicos de vibración 1X/2X RPM por soltura mecánica.

### 5. Telemetría 100% In-Game en Tablet Industrial (Tecla `[TAB]`)
> **Sin páginas web externas:** Todo el monitoreo y diagnóstico ocurre nativamente dentro del juego.

Al presionar la tecla **`[TAB]`**, el operario despliega o guarda en pantalla su **Tablet Industrial de Campo**, la cual presenta un dashboard similar al de las simulaciones con IA dividido en 5 módulos:
- **Módulo 1 — Telemetría Electromecánica True-RMS:** Lectura en vivo de $V_{LL}$, corrientes por fase ($I_A, I_B, I_C$), desbalance $IUF$, velocidad $N_r$, par $T_e$, potencia $P_{in}$, temperatura de devanados $T_w$ y vibración RMS/Pico con semáforo ISO 10816-3.
- **Módulo 2 — Oscilogramas y Gráficas en Tiempo Real (*Strip Charts* Nativos):** Curvas dinámicas de corrientes trifásicas $I(t)$, evolución térmica $T(t)$ y espectro de vibración.
- **Módulo 3 — Diagnóstico Edge AI (MLP & SVM):** Estado clasificado en tiempo real (*Normal*, *Sobrecalentamiento*, *Falla Eléctrica*, *Falla Mecánica*), porcentaje de certeza de la IA, barra del **Motor Health Index (MHI 0–100%)** y estimación de **Vida Útil Remanente (RUL)** en horas.
- **Módulo 4 — Alertas Push Sonoras & Checklist RCM / RETIE:** Notificación de causa raíz, pronóstico y lista de tareas interactiva (`CheckBox`) para verificar paso a paso la reparación segura en planta.
- **Módulo 5 — Eficiencia Energética y Sostenibilidad:** Comparativa DOL vs VFD en tiempo real, consumo específico ($\text{kWh/ton}$) y emisiones evitadas ($\text{kg CO}_2\text{e}$).

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
├── Modelos descargados/                # Activos 3D originales descargados (planta_completa.glb, .skp, trabajadores.glb)
├── SimuladorPlantaGodot/               # PROYECTO MAESTRO DEL SERIOUS GAME EN GODOT 4.7
│   ├── assets/models/                  # Modelo 3D de la planta importado con texturas PBR
│   ├── scenes/                         # Escenas modulares (.tscn): Planta, Operario, Motor, CCM, Cables, Tablet
│   ├── scripts/                        # Física de Kloss, fallas físicas diegéticas, Tablet in-game y pruebas
│   └── project.godot                   # Configuración de Godot 4.7 e Input Map (WASD, E, TAB, 1-5)
├── INICIAR_SIMULADOR_GODOT.bat         # Lanzador 1-clic del juego interactivo en pantalla completa
├── ABRIR_EDITOR_GODOT.bat              # Lanzador 1-clic para abrir el proyecto en el editor de Godot 4.7
├── PROYECTO FINAL_MAQUINAS 20262.pdf   # Guía oficial y rúbrica de evaluación de la asignatura
└── README.md                           # Documentación general del proyecto
```

---

## 🚀 Ejecución Rápida y Controles en el Juego

### Lanzadores de 1 Clic (Windows)
- **Jugar a la Simulación Interactiva:** Doble clic en `INICIAR_SIMULADOR_GODOT.bat`.
- **Editar Escenas en Godot 4.7:** Doble clic en `ABRIR_EDITOR_GODOT.bat`.

### Controles del Operario en el Juego
| Tecla / Acción | Función en la Simulación |
| :---: | :--- |
| **`W`, `A`, `S`, `D`** | Desplazamiento del operario por la planta industrial |
| **`Shift`** | Caminata rápida / Sprint |
| **`Espacio`** | Saltar |
| **`Mouse`** | Vista en primera/tercera persona |
| **`[TAB]` o `T`** | **Sacar / Guardar la Tablet Industrial (Dashboard de Telemetría e IA In-Game)** |
| **`E` / Clic Izquierdo** | Interactuar con equipos (equipar EPP, accionar breakers, recoger sacos de 50 kg, usar herramientas) |
| **`1` – `5`** | Seleccionar herramienta de trabajo (1: Mano, 2: Alicates dieléctricos, 3: Candado LOTO, 4: Multímetro CAT III, 5: Llave mecánica) |
| **`X`** | Accionar Parada de Emergencia (E-Stop Categoría 0) |
| **`C`** | Alternar cámara Primera Persona / Tercera Persona |

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
