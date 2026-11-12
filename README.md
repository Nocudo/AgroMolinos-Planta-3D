# AgroMolinos del Valle S.A. — Simulador 3D de Planta Industrial & Diagnóstico de Máquinas Eléctricas

**Universidad de los Llanos — Facultad de Ciencias Básicas e Ingeniería**  
**Curso:** Máquinas Eléctricas (2026-2)  
**Docente Titular:** Ing. Lauren Genith Isaza  
**Integrantes:**
- H. García (161004621)
- M. Rodríguez (161004834)
- S. Bustamante (161005037)

---

## 🏭 Descripción General del Proyecto

Plataforma integral de accionamiento electromecánico, monitoreo predictivo de fallas con Inteligencia Artificial y simulación interactiva 3D en tiempo real (WebGL / Three.js) para la **Planta Molino de Granos** de la empresa **AgroMolinos del Valle S.A.**.

### Especificaciones Técnicas del Accionamiento Crítico
- **Máquina Eléctrica:** Motor Trifásico de Inducción Jaula de Ardilla (Clase IE3 Premium Efficiency)
- **Potencia Nominal:** $10\text{ HP} \approx 7.457\text{ kW}$
- **Tensión / Frecuencia:** $460\text{ V AC}$, trifásico, $60\text{ Hz}$
- **Velocidad Nominal:** $1750\text{ RPM}$ ($p = 4$ polos, velocidad sincrónica $1800\text{ RPM}$)
- **Corriente Nominal a Plena Carga ($I_{FLA}$):** $\approx 13.5\text{ A}$ por fase
- **Sistema de Control:** Variador de Frecuencia (VFD) con control escalar V/f constante y rampas de aceleración/deceleración
- **Normativa de Seguridad y Mantenimiento:** RETIE (Art. 13 y 20), ISO 13857, NFPA 70E, NFPA 61 / ATEX, ISO 10816-1/3 (Vibraciones), OSHA 1910.147 / 5 Reglas de Oro (LOTO).

---

## 📂 Estructura del Repositorio

```
├── Avance 1/                       # Caracterización técnica del motor y modelo DTC en Simulink
│   ├── Informe/                    # Artículo en formato IEEE (LaTeX) y gráficas operacionales
│   └── simulaciones/               # InductionMachineDTC.slx y scripts de sintonía PI
├── Avance 2/                       # IA de diagnóstico predictivo y panel interactivo en App Designer
│   ├── abrir_panel.m               # Script maestro de lanzamiento del panel MATLAB
│   ├── Informe/IA/                 # Red neuronal (MLP), SVM RBF y dataset de fallas
│   └── Informe/simulaciones/       # Modelos DTC actualizados y telemetría de fallas
├── SimuladorPlantaWeb/              # Simulador 3D Web interactivo (Three.js / WebGL sin compilación)
│   ├── index.html                  # Contenedor Canvas 3D + HUD / SCADA superpuesto en HTML5
│   ├── css/
│   │   └── scada-style.css         # Estilos SCADA industriales oscuros y tablet de riesgos
│   └── src/
│       ├── core/                   # EventBus, SceneManager PBR, ControlsManager (WASD + Orbital)
│       ├── physics/                # InductionMotor (Kloss), VFDController, ThermalModel, MechanicalLoad
│       ├── safety/                 # IndustrialSafety (E-Stop, LOTO 5 Reglas), OperatorPPEInventory, SafetyZones
│       ├── world/                  # WarehouseBuilder, MotorMillAssembly, CCMPanel, DustParticleCloud
│       ├── ui/                     # SCADAInterface, AndonVisualizer (ISA 18.2), FaultInjectorUI
│       ├── audio/                  # IndustrialAudio (Síntesis procedural con Web Audio API)
│       └── main.js                 # Bucle principal de animación a 60 FPS
├── INICIAR_SIMULADOR.bat           # Lanzador automático con 1 solo click para Windows
├── INICIAR_SIMULADOR.ps1           # Lanzador para PowerShell
├── PLAN_SIMULADOR_PLANTA_3D_THREEJS.md # Plan maestro y mapa modular del simulador Three.js
└── .gitignore                      # Reglas de exclusión para entornos Web, MATLAB y LaTeX
```

---

## 🌐 Cómo Ejecutar el Simulador 3D (`SimuladorPlantaWeb/`)

El simulador está diseñado bajo la filosofía **Zero-Compilation**: no requiere instalar Unity Hub, Node.js ni paquetes pesados. Funciona directamente en cualquier navegador moderno:

### 🚀 Opción 1: Lanzador de 1 Click (Recomendado)
- Simplemente haz doble clic sobre el archivo **`INICIAR_SIMULADOR.bat`** en la carpeta principal.
- El script iniciará el servidor multihilo optimizado y **abrirá automáticamente tu navegador web** en `http://localhost:8085`.

### 💻 Opción 2: Desde la Terminal (PowerShell / CMD)
```bash
# Ejecutar el servidor multihilo con apertura automática de navegador
cd SimuladorPlantaWeb
python serve.py
```
O con el servidor básico de Python:
```bash
cd SimuladorPlantaWeb
python -m http.server 8000
# Abrir en el navegador: http://localhost:8000
```

### Controles de Navegación e Interacción:
- **WASD / Flechas:** Caminar por la nave industrial y vestidores.
- **Mouse:** Orientar la vista en primera persona (o arrastrar con click izquierdo).
- **[E] o Click Izquierdo:** Interactuar con el equipo al que apuntas (seccionador, pulsadores, EPP, compuertas).
- **[Tab]:** Abrir / Cerrar la Tablet Industrial de Seguridad y Control de Riesgos.
- **[Shift]:** Correr / Desplazamiento acelerado.
- **[C]:** Alternar entre Modo Operario (Primera Persona) y Modo Inspector (Cámara Orbital 360°).

---

## 🦺 Características de Seguridad y Físicas Implementadas

1. **Física del Motor 10 HP:** Ecuación de par-deslizamiento de Kloss, corrientes trifásicas ($I_{L1}, I_{L2}, I_{L3}$), factor de potencia y balance de potencias activa/reactiva.
2. **Modelo Térmico de 1er Orden:** Calentamiento estatórico diferencial $\frac{dT}{dt}$ con convección forzada dependiente de las RPM del ventilador y disparo por relé térmico ($> 105^\circ\text{C}$).
3. **Severidad de Vibración (ISO 10816-3):** Diagnóstico en tiempo real por zonas (Zona A/B óptima, Zona C alerta, Zona D parada destructiva).
4. **Protocolo LOTO (5 Reglas de Oro):**
   - 1. Corte visible en seccionador CCM.
   - 2. Enclavamiento físico con candado rojo y tarjeta de peligro.
   - 3. Verificación de ausencia de tensión (0.0 V).
   - 4. Puesta a tierra y cortocircuito.
   - 5. Señalización de zona segura con baliza Andon Azul.
5. **Esclusa y Dotación EPP (RETIE Art. 20):** Casco dieléctrico clase E, gafas ANSI Z87.1, copas auditivas NRR 27 dB, botas dieléctricas ASTM F2413, guantes clase 00 y overol ignífugo NFPA 70E.
6. **Riesgo ATEX / NFPA 61:** Simulación de nube de polvo de cereal en suspensión con sensor óptico de densidad ($g/m^3$) y extractor centrífugo ciclónico.
7. **Audio Procedural (Web Audio API):** Zumbido 60 Hz armónico, silbido PWM de 4 kHz del inversor y sirena de emergencia ISA 18.2 generados en tiempo real.
