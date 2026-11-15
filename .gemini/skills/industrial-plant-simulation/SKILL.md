---
name: industrial-plant-simulation
description: Specialized Serious Game & Simulation Engine for the 'Máquinas Eléctricas' final project (Planta Molino de Granos) in Godot 4.7. Enforces strict usage of downloaded 3D models only (strictly NO procedural/agent-created models; asks user to supply any missing model in 'Modelos descargados'), physical floor with collisions, industrial safety zonings (OSHA/RETIE), PBR realistic lighting & post-processing (SDFGI, SSAO, Volumetric Fog), interactive Tutorial Mode with gate spawn, RETIE PPE dressing, 5 Golden Rules of electrical safety, guided facility walkthrough, animated logistics trucks, end-to-end animated production chain (grain intake, 10HP milling, racking, dispatch exit), diegetic physical fault induction (cutting cables, manual grain overfeed, breaker box manipulation/brownouts without 2D UI buttons), 100% in-game native telemetry & AI dashboard on industrial tablet toggled with [TAB] (strictly NO external web pages/browsers needed), Cloud Edge AI analytics (MLP/SVM, RUL, Motor Health Index), energy optimization (VFD vs DOL, kWh/ton, CO2e reduction), CCTV mezzanine monitoring, academic safety scorecard (0.0 to 5.0), and an in-game industrial tablet receiving push alerts and guided maintenance procedures.
---

# Simulación de Planta Industrial: Molino de Granos & Máquinas Eléctricas (Godot 4.7 Serious Game)

Esta skill es la guía maestra de arquitectura, física electromecánica en GDScript 2.0, montaje espacial del modelo 3D descargado, suelo físico y colisiones, demarcación vial/zonificación de seguridad, iluminación fotorrealista PBR, **Modo Tutorial Interactivo (Spawn en portería, dotación EPP RETIE y 5 Reglas de Oro)**, **Cadena de Producción Secuencial Animada con Camiones de Carga**, **Optimización Energética (VFD vs DOL y Reducción de Huella de Carbono $\text{CO}_2\text{e}$)**, **Analítica IA (MLP 8-16-8-4, SVM RBF, MHI, RUL)**, **Telemetría 100% In-Game y Dashboard de IA en Tablet Industrial interactiva con la tecla [TAB] (Estrictamente SIN páginas web externas)**, **Terminal de Capacitación con Rúbrica Académica (0.0 a 5.0)**, interacción física diegética en 3D para el **Proyecto Final de Máquinas Eléctricas (Universidad de los Llanos - 2026-2)**:
**Sector Asignado: Planta Molino de Granos** con **Motor Trifásico de Inducción Jaula de Ardilla (10 HP, 460 V, IE3)** accionado por VFD, transformado en un **Juego Serio Interactivo en Primera/Tercera Persona** bajo el paradigma de **Transición de Industria 4.0 a Industria 5.0**.

---

## 1. Alineación Académica & Rúbrica del Curso (Ing. Lauren Genith Isaza)

El proyecto responde con rigurosidad a los tres cortes evaluativos y los requisitos de la guía:

```
                  ┌─────────────────────────────────────────────────────────┐
                  │    TRANSICIÓN INDUSTRIA 4.0 A INDUSTRIA 5.0             │
                  │   (Centrada en el humano, resiliente, sostenible)       │
                  └───────────────────────────┬─────────────────────────────┘
                                              │
              ┌───────────────────────────────┼──────────────────────────────┐
              ▼                               ▼                              ▼
     ┌──────────────────┐           ┌──────────────────┐           ┌──────────────────┐
     │     AVANCE 1     │           │     AVANCE 2     │           │  AVANCE 3/FINAL  │
     │ Caracterización  │           │   Mantenimiento  │           │   Optimización   │
     │ Motor AC 10 HP   │           │ Predictivo + IA  │           │ VFD, IoT & HMI   │
     │  RETIE / Kloss   │           │  Ruta RCM / LOTO │           │   Informe IEEE   │
     └──────────────────┘           └──────────────────┘           └──────────────────┘
```

1. **Avance 1 (Corte 1 - 20%)**:
   - Caracterización nominal y modelado dinámico del motor trifásico según normativa **RETIE** (Capítulo 2) y estándares **NEMA / IEC 60034-1**.
   - Parámetros del circuito equivalente por fase ($R_s, R_r', X_s, X_r', X_m$).
   - Simulación matemática continua: Tensión ($V_{LL}$), Corriente trifásica ($I_A, I_B, I_C$), Factor de Potencia ($\cos\phi$), Temperatura devanados/carcasa ($T^\circ\text{C}$), Vibración RMS según **ISO 10816-3**.
2. **Avance 2 (Corte 2 - 30%)**:
   - Ruta de Mantenimiento Preventivo y Predictivo con **Técnicas de Inteligencia Artificial**:
     - Clasificador Neuronal Multicapa (MLP $8 \to 16 \to 8 \to 4$) y Máquina de Soporte Vectorial (SVM con kernel RBF).
     - Vector de 8 características: $[I_{RMS}, IUF, THD, V_{RMS}, T, \frac{dT}{dt}, Vib_{RMS}, Vib_{peak}]$.
   - Clasificación en tiempo real de 4 estados: Normal, Sobrecalentamiento, Falla Eléctrica (monofasización) y Falla Mecánica (rodamientos).
   - Integración de gemelo digital con tablero de control, MATLAB App Designer y **Tablet Industrial de Campo**.
3. **Avance 3 & Informe Final (Corte 3 - 40% + 10% Sustentación)**:
   - Estrategia integral de optimización energética mediante **Variador de Frecuencia (VFD escalar V/f y DTC)** comparado con arranque directo (DOL).
   - Modelado de ahorro energético ($\text{kWh/ton}$) y mitigación de emisiones de gases de efecto invernadero ($\text{kg CO}_2\text{e}$ evitados).
   - Dashboard interactivo con KPIs de sostenibilidad: Consumo acumulado ($\text{kWh}$), Eficiencia energética ($\eta$), Índice de Salud del Motor (*Motor Health Index* - MHI de 0 a 100%).
   - Cumplimiento estricto del formato IEEE, estado del arte con 20 referencias bibliográficas indexadas (2019-2026), cálculos matemáticos y códigos fuente.

---

## 2. Parámetros Técnicos Nominales del Sistema (Única Fuente de Verdad)

Los valores derivan del archivo maestro del proyecto (`InductionMachineDTCData.m`) y placa de características NEMA Premium / IE3:

| Parámetro Electromecánico | Símbolo | Valor Nominal | Unidad | Observaciones Normativas |
| :--- | :---: | :---: | :---: | :--- |
| **Potencia Mecánica Nominal** | $P_n$ | **10.0 (7457.0)** | $\text{HP (W)}$ | Potencia en el eje a plena carga |
| **Tensión Nominal Línea-Línea** | $V_n$ | **460.0** | $\text{V AC}$ | Conexión Estrella ($Y$), $60\text{ Hz}$ trifásico |
| **Frecuencia Eléctrica Nominal** | $f_n$ | **60.0** | $\text{Hz}$ | Red industrial colombiana (RETIE) |
| **Pares de Polos / Polos** | $p / P$ | **2 / 4** | - | $N_s = \frac{120 \cdot 60}{4} = 1800\text{ RPM}$ |
| **Velocidad Nominal de Rotor** | $N_r$ | **1750.0** | $\text{RPM}$ | Deslizamiento nominal $s_n \approx 2.78\%$ |
| **Corriente Nominal de Línea** | $I_{FLA}$ | **13.5** | $\text{A RMS}$ | Corriente nominal a $460\text{ V}$ plena carga |
| **Corriente de Magnetización** | $I_{0}$ | **4.5** | $\text{A RMS}$ | Corriente de vacío con $\cos\phi_0 \approx 0.20$ |
| **Corriente de Rotor Bloqueado** | $I_{LRA}$ | **81.0** | $\text{A RMS}$ | $6 \times I_{FLA}$ (arranque directo DOL) |
| **Par Nominal Mecánico** | $T_n$ | **40.7** | $\text{N}\cdot\text{m}$ | $T_n = \frac{9550 \cdot 7.457}{1750} \approx 40.7\text{ Nm}$ |
| **Par Máximo de Vuelco** | $T_{max}$ | **101.75** | $\text{N}\cdot\text{m}$ | $2.5 \times T_n$ a deslizamiento crítico $s_{max} = 0.15$ |
| **Factor de Potencia Nominal** | $\cos\phi$ | **0.85** | - | A plena carga nominal |
| **Eficiencia Nominal** | $\eta$ | **91.7** | $\%$ | Clase IE3 / NEMA Premium Efficiency |
| **Resistencia de Estator** | $R_s$ | **0.435** | $\Omega$ | Medida a $75^\circ\text{C}$ (Resistencia de fase) |
| **Resistencia de Rotor referida** | $R_r'$ | **0.816** | $\Omega$ | Parámetro de circuito equivalente |
| **Inductancia de Dispersión** | $L_{ls}, L_{lr}'$| **2.0** | $\text{mH}$ | Reactancias $X_s = X_r' \approx 0.754\ \Omega$ |
| **Inductancia Magnetizante** | $L_m$ | **69.3** | $\text{mH}$ | Reactancia de entrehierro $X_m \approx 26.12\ \Omega$ |
| **Inercia Total Acoplada** | $J_{total}$ | **0.35** | $\text{kg}\cdot\text{m}^2$| Rotor motor $0.045$ + Molino martillos $0.305$ |
| **Clase de Aislamiento Térmico** | - | **Clase F ($155^\circ\text{C}$)** | - | Elevación térmica diseño Clase B ($\Delta T \le 80\text{ K}$) |

---

## 3. Política Estricta de Activos 3D: Únicamente Modelos Descargados de Internet

> [!WARNING]
> **REGLA MANDATORIA DE MODELADO 3D (PROHIBIDA LA CREACIÓN PROCEDURAL / ARTIFICIAL)**:
> 1. **ÚNICAMENTE utilizar modelos 3D descargados de internet** (almacenados en la carpeta local `Modelos descargados/` o vinculados en `SimuladorPlantaGodot/assets/models/`).
> 2. **ESTÁ ESTRICTAMENTE PROHIBIDO QUE EL AGENTE CREE O GENERE MODELOS 3D PROCEDURALES**:
>    - Queda prohibido ensamblar primitivas improvisadas (`CSGBox3D`, `CSGCylinder3D`, `BoxMesh`, `CylinderMesh` o geometrías compuestas por código para representar máquinas, camiones, personajes, tableros o herramientas), ya que carecen de la fidelidad estética y realismo que exige el usuario.
> 3. **PROTOCOLO DE ACCIÓN SI FALTA UN MODELO O NO SE ENCUENTRA EN EL PROYECTO**:
>    - Si para cualquier requerimiento de la planta (por ejemplo: un modelo específico de camión, montacargas, herramienta de mano, pieza de EPP, mobiliario o maquinaria) el modelo no se encuentra disponible en `Modelos descargados/` y no es posible conseguirlo:
>      * **EL AGENTE NO DEBE CREARLO NI USAR SUSTITUTOS PROCEDURALES**.
>      * **EL AGENTE DEBE DETENERSE Y PEDÍRSELO EXPLÍCITAMENTE AL USUARIO**: Especificar el nombre del activo requerido, su función en la simulación y los formatos compatibles recomendados (`.glb`, `.gltf`, `.skp`, `.fbx`, `.obj`).
>      * **EL USUARIO LO DESCARGARÁ DE INTERNET Y LO COLOCARÁ EN LA CARPETA `Modelos descargados/`**.
>      * Una vez el usuario confirme la adición en `Modelos descargados/`, el agente procederá a enlazarlo, optimizarlo y configurarlo en la escena de Godot 4.7.

### 3.1 Modelo Maestro de la Planta Ya Descargado
- Archivo fuente ya ubicado en el proyecto: `Modelos descargados/planta_completa.glb` y vinculado en `SimuladorPlantaGodot/assets/models/planta_completa.glb` (derivado de `planta_completa.skp`).
- No requiere descargas adicionales para la nave principal, silos ni estructuras primarias.

```
┌────────────────────────────────────────────────────────────────────────┐
│               ESCENA GODOT 4.7: SimuladorPlantaGodot/scenes/main.tscn   │
├────────────────────────────────────────────────────────────────────────┤
│ [Node3D] PlantaIndustrial                                              │
│  ├── [WorldEnvironment] (SDFGI, SSAO, SSR, Volumetric Fog, ACES)       │
│  ├── [DirectionalLight3D] Sol Industrial (Sombras suaves PCF)          │
│  ├── [Node3D] LucesIndustriales (Campanas LED High-Bay 5000K)          │
│  ├── [StaticBody3D] SueloFisicoPBR                                     │
│  │    ├── [CollisionShape3D] (BoxShape3D / WorldBoundaryShape3D)       │
│  │    └── [MeshInstance3D] Concreto Epóxico con Normal Map             │
│  ├── [Node3D] DemarcacionZonas (OSHA / RETIE / ATEX Decals)            │
│  ├── [Node3D] ModeloPlanta (Instancia de planta_completa.glb)          │
│  │    └── Colisiones automáticas trimesh / convexas en maquinaria      │
│  ├── [Node3D] FlujoProduccion (Camiones, Tolvas, Cintas, Ensacadora)   │
│  ├── [Node3D] CentroMonitoreoCCTV (Mezzanine con 4 SubViewports)       │
│  ├── [CharacterBody3D] OperatorPlayer (Spawn en Portería / 1ra y 3ra)  │
│  └── [CanvasLayer] UI, HUD, Tablet Industrial & Terminal Inducción     │
└────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Creación del Suelo Físico con Colisiones Reales
El suelo no debe ser un plano visual flotante (`PlaneMesh`), sino un cuerpo físico colisionable:
1. **Nodo `StaticBody3D` (`SueloFisicoPBR`)**:
   - `CollisionShape3D` con `BoxShape3D` de $600 \times 1.0 \times 600\text{ m}$ posicionado en $Y = -0.5\text{ m}$ (superficie superior en $Y = 0.0\text{ m}$).
   - Evita de manera infalible que el jugador, vehículos o sacos rígidos caigan al vacío.
   - Propiedades de física: `physics_material_override` con fricción $0.85$ (concreto industrial seco antideslizante según OSHA).
2. **Material PBR del Suelo (`StandardMaterial3D` / `ORMMaterial3D`)**:
   - `albedo_color`: Gris concreto industrial `#3c4043` o verde epóxico industrial `#283a2d`.
   - `roughness`: $0.65$ con rugosidad superficial (micro-relieve reflectante de luminarias).
   - `normal_enabled`: Verdadero, con textura de grano de concreto y juntas de dilatación cada 6 metros.
   - `uv1_scale`: `Vector3(80, 80, 1)` para evitar estiramiento y dar detalle fotorrealista a corta distancia.

### 3.3 Generación Automatizada de Colisiones en el Modelo Importado
Para que las paredes, estructuras, pasarelas elevadas, tolvas y silos tengan colisión física sólida:
- En Godot 4.7, el modelo `planta_completa.glb` puede configurarse en el **Import Dock**:
  - Activar *Physics Body Type*: `Static` con *Physics Shape*: `Decompose Convex` para maquinarias complejas y `Trimesh` para muros y pisos estructurales.
- O mediante script procedural en tiempo de arranque (`_ready()`):
  ```gdscript
  func generate_plant_collisions(plant_node: Node3D) -> void:
      for child in plant_node.find_children("*", "MeshInstance3D", true, false):
          var mesh_inst := child as MeshInstance3D
          if mesh_inst.get_child_count() == 0:
              mesh_inst.create_trimesh_collision()
  ```

---

## 4. Demarcación Vial & Zonificación de Seguridad (OSHA 1910.144 / RETIE / NFPA)

El piso de la nave cuenta con demarcaciones visuales claras mediante mallas planas superpuestas ($Y = +0.01\text{ m}$) o nodos `Decal` proyectados sobre el suelo:
1. **Zona 1: Molienda y Fuerza Motriz (Amarillo / Negro - OSHA 1910.144)**:
   - Franjas diagonales a 45° alternadas en amarillo tráfico (`#fbc02d`) y negro mate (`#212121`) delimitando el molino de martillos `M-101`, la transmisión de correas y el motor de 10 HP. Señal de "Uso Obligatorio de Protección Auditiva y Visual".
2. **Zona 2: Tablero CCM 460 V (Rojo Peligro Eléctrico - RETIE Art. 20 / NFPA 70E)**:
   - Recuadro rojo perimetral (`#d32f2f`) en el suelo con leyenda: *"PELIGRO 460 V - MANTENER DESPEJADO 1.0 METRO"*. Ningún objeto, bulto o herramienta puede permanecer dentro de esta zona.
3. **Zona 3: Recepción y Tolva de Alimentación (Azul Seguridad - ISO 7010)**:
   - Líneas de delimitación en azul cobalto (`#1976d2`). Zona de descarga de sacos de cereal y compuerta guillotina `T-301`.
4. **Zona 4: Pasillo Peatonal Central (Verde Tráfico Seguro)**:
   - Calzada peatonal continua de $2.4\text{ m}$ de ancho pintada en verde industrial (`#2e7d32`), flanqueada por dos líneas blancas de $10\text{ cm}$. Conecta la esclusa norte, vestidores, CCM, molienda y oficinas del mezzanine.
5. **Zona 5: Almacén de Racks y Sacos (Blanco Tráfico)**:
   - Demarcación en líneas blancas continuas (`#ffffff`) que definen las bahías de estanterías industriales, slots de pallets y radio de giro de montacargas.
6. **Zona 6: Bahía de Despacho y Portones (Amarillo Tráfico)**:
   - Franjas amarillas con símbolos viales de montacargas cruzando y zona de maniobra de camión exterior `Portón #2`.
7. **Zona 7: Atmósfera Explosiva ATEX (Naranja / NFPA 61 / ATEX Zona 22)**:
   - Perímetro circular o poligonal con borde naranja reflectante (`#f57c00`) rotulado: *"ZONA ATEX: RIESGO DE POLVO COMBUSTIBLE - PROHIBIDO FUMAR O GENERAR CHISPAS"*.

---

## 5. Iluminación Fotorrealista y Atmósfera Industrial (Forward Plus)

Godot 4.7 con el renderizador **Forward Plus** ofrece capacidades gráficas de vanguardia:
- **Tone Mapping**: `tonemap_mode = TonemapMode.ACES` o `TonemapMode.FILMIC` con exposición $1.0$ y balance de blancos neutralizado.
- **Global Illumination**: `sdfgi_enabled = true` (*Signed Distance Field Global Illumination*) para calcular el rebote indirecto de la luz natural sobre vigas de acero y tolvas galvanizadas.
- **Screen-Space Ambient Occlusion (SSAO)**: `ssao_enabled = true`, radio $1.2\text{ m}$, intensidad $1.8$ para sombras de contacto profundas en patas de máquinas y sacos.
- **Screen-Space Reflections (SSR)**: `ssr_enabled = true` para reflejos especulares suaves sobre el piso epóxico pulido.
- **Glow / Bloom**: `glow_enabled = true`, intensidad $0.4$, umbral $0.95$ para halo realista en campanas LED, balizas Andon y arcos eléctricos.
- **Niebla Volumétrica (*Volumetric Fog*)**: `volumetric_fog_enabled = true`, densidad $0.008\text{ m}^{-1}$, color `#c8d0d8` simulando la atmósfera suspendida de un molino de harina y proyectando haces de luz (*god rays*).
- **Luminarias High-Bay**: Matriz de campanas LED industriales de $5000\text{ K}$ blanco neutro suspendidas a $8\text{ m}$ con sombras suaves y atenuación cuadrática inversa.

---

## 6. Ajustes de Realismo Visual y Acústico (PBR & Polish)

- **Materiales PBR**: Hierro fundido rugoso en carcasa del motor, chapa pintada con desconchones en tolvas, acero pulido torneado en ejes rotatorios y tela de arpillera rugosa en sacos de grano.
- **Decals de Desgaste**: Huellas de montacargas frenando en intersecciones, manchas de lubricante ISO VG 220 en chumaceras y señalética de extintores Solkaflam/CO2.
- **Diseño Sonoro Espacial 3D (`AudioStreamPlayer3D`)**: Zumbido eléctrico de 60 Hz en el CCM, silbido PWM del VFD a 4 kHz, golpeteo del molino a 1750 RPM, flujo de aire en ciclones y reverberación de nave metálica.

---

## 7. Modo Tutorial Interactivo: Spawn en Portería, Dotación EPP y 5 Reglas de Oro RETIE

> [!IMPORTANT]
> **FLUJO PEDAGÓGICO OBLIGATORIO DEL JUGADOR**:
> Al iniciar el modo tutorial o nueva partida, el personaje **hace spawn en el exterior, en la entrada principal de la empresa (garita de acceso / portería)**.
> No puede acceder a la maquinaria en funcionamiento ni intervenir circuitos sin antes cumplir los protocolos de seguridad industrial de la norma **RETIE (Capítulo 2, Art. 20)** y **OSHA 1910**.

### 7.1 Spawn en la Entrada de la Empresa (Portería Norte / Garita)
- **Ubicación de Spawn**: Coordenadas exteriores `Vector3(-14.0, 0.2, -22.0)` frente a la garita de vigilancia y portón de control de acceso.
- **Interacción Inicial**:
  - El guardia de seguridad o terminal de inducción entrega el carné de contratista y la **Tablet Industrial de Campo**.
  - Mensaje en pantalla: *"Bienvenido a AgroMolinos del Valle S.A. Según el Reglamento Técnico de Instalaciones Eléctricas (RETIE), está prohibido ingresar a las áreas de molienda y tableros sin el Equipo de Protección Personal (EPP) certificado. Diríjase al Cuarto de Vestidores (Estación 1)."*

### 7.2 Estación de Vestidores & Equipamiento de EPP (RETIE Art. 20 / OSHA 1910)
El jugador ingresa al recinto de casilleros y mesa de dotación. Debe interactuar con cada elemento para equiparlo en su personaje 3D:
1. **Casco Dieléctrico Tipo I Clase E (20.000 V)**: Protección contra impactos craneales y contacto accidental de alta tensión.
2. **Gafas de Seguridad con Protección Lateral UV (ANSI Z87.1)**: Protección contra proyección de partículas y arcos eléctricos menores.
3. **Protector Auditivo Tipo Copa (NRR 27 dB)**: Requerido por nivel sonoro $> 85\text{ dBA}$ en el área de molienda de martillos.
4. **Guantes Dieléctricos Clase 0 (1000 V AC) con Guantelete de Cuero**: Para maniobra segura en el tablero CCM 460 V.
5. **Botas de Seguridad Dieléctricas con Puntera de Composite (ASTM F2413 / RETIE)**: Resistencia a 18 kV sin partes metálicas conductivas.
6. **Ropa de Trabajo de Algodón Ignífugo (Arc Flash NFPA 70E Categoría 2 - $8\text{ cal/cm}^2$)**: Protección contra quemaduras por fogonazo térmico.
- **Enclavamiento de Zona**: Si el jugador intenta cruzar la esclusa hacia la planta sin EPP completo, suena un zumbador de advertencia y se bloquea el paso con notificación de infracción.

### 7.3 Ejecución Interactiva de las 5 Reglas de Oro de Seguridad Eléctrica (RETIE)
En el cuadrante del tablero CCM 460 V, el tutorial guía al jugador paso a paso para intervenir la máquina sin tensión:
1. **Regla 1: Corte Visible**: Girar la maneta del seccionador principal bajo carga para abrir los contactos con aislamiento visual de cuchillas.
2. **Regla 2: Enclavamiento y Bloqueo Físico (LOTO)**: Tomar el candado de seguridad rojo de la aldaba múltiple, bloquear la maneta en posición OFF y colocar la tarjeta de advertencia *"PELIGRO - NO OPERAR - PERSONAL TRABAJANDO"*.
3. **Regla 3: Verificación de Ausencia de Tensión**: Tomar las puntas de prueba del multímetro digital calibrado y medir entre fases ($L1-L2, L2-L3, L3-L1$) y fases a tierra ($L-PE$). Verificar lectura de $0.0\text{ V}$.
4. **Regla 4: Puesta a Tierra y en Cortocircuito**: Colocar la pértiga con grapas de puesta a tierra portátil en los bornes del motor para drenar cargas residuales o corrientes inducidas.
5. **Regla 5: Señalización y Delimitación**: Desplegar cinta de advertencia retráctil y conos de peligro delimitando el área de trabajo a $1.0\text{ m}$.

### 7.4 Recorrido Pedagógico Guiado por Instalaciones (12 Estaciones de Inspección)
Un sistema de guiado con flechas proyectadas en el piso verde conduce al jugador por las 12 estaciones de la planta:
- **Estación 1: Vestidores & Dotación EPP**: Área limpia de preparación técnica.
- **Estación 2: Mezzanine & Oficinas de Ingeniería**: Supervisión de planta, servidores SCADA y gemelo digital.
- **Estación 3: Esclusa Norte & Troncal Principal**: Sistema de presurización positiva para evitar ingreso de partículas.
- **Estación 4: Tablero CCM 460 V**: Disyuntores, contactores, relé térmico y Variador de Frecuencia VFD de 10 HP.
- **Estación 5: Núcleo de Molienda 10 HP**: Molino de martillos M-101, acople de correas y sensor de vibración ISO 10816-3.
- **Estación 6: Báscula de Recepción & Tolva Subterránea**: Plataforma de pesaje de camiones de cereal entrante.
- **Estación 7: Almacén de Racks Industriales**: Estiba de sacos de harina terminados y pasillos de montacargas.
- **Estación 8: Muelle de Despacho & Bahía de Ensacado**: Zona de empaque automatizado en sacos de 50 kg.
- **Estación 9: Portón Exterior #2**: Patio de maniobras y salida vehicular hacia la vía perimetral.
- **Estación 10: Subestación Eléctrica 13.2 kV / 460 V**: Transformador reductor tipo pedestal con cerramiento RETIE.
- **Estación 11: Batería de Silos Graneleros Exteriores**: Almacenamiento primario a granel con aireación forzada.
- **Estación 12: Retorno a Troncal Central**: Conclusión de la inducción técnica con certificación en la Tablet.

---

## 8. Cadena de Producción Secuencial y Camiones Animados (Ciclo Completo End-to-End)

El juego cuenta con un ciclo de producción continuo y dinámico completamente animado, simulando el flujo de materia prima desde su arribo en camiones hasta el despacho del producto procesado:

### 8.1 Animación de Camiones de Carga (Logística Vehicular con Modelos Descargados)
- **Nodos `Path3D` y `PathFollow3D`**: Rutas de navegación con curvas Bézier suaves que guían los vehículos industriales dentro del recinto:
  1. **Camión Granelero de Descarga**:
     - Entra por la portería exterior norte (`Portón #1`), avanza a $15\text{ km/h}$ y se estaciona sobre la plataforma de la báscula de pesaje.
     - Detiene la marcha, emite sonido de freno neumático (`AirBrake.wav`) y activa la animación del pistón hidráulico que eleva el volquete a $45^\circ$.
     - La compuerta trasera se abre y descarga un flujo continuo de cereal dorado mediante partículas `GPUParticles3D` hacia la rejilla de la tolva subterránea.
     - Finalizada la descarga, el volquete desciende, el camión enciende luces de marcha atrás y se retira por el circuito perimetral sur.
  2. **Camión de Reparto y Despacho**:
     - Estacionado en la bahía de carga con las compuertas traseras abiertas.
     - Recibe los pallets cargados con sacos de cereal triturado trasladados por el montacargas.
     - Al completar la carga (10 pallets de 20 sacos = 200 sacos de 50 kg), el chofer cierra las puertas con animación, enciende el motor diésel y sale por el `Portón #2` hacia la vía pública.

### 8.2 Etapas Productivas Integradas
- **Etapa 1 (Recepción)**: Descarga en tolva `T-301` con elevador de cangilones y tornillo sinfín ($0.8\text{ kg/s}$).
- **Etapa 2 (Molienda)**: Trituración en molino de martillos `M-101` a 1750 RPM con criba de 3 mm y extracción ciclónica neumática.
- **Etapa 3 (Ensacado y Paletizado)**: Ensacadora automática `D-401` en sacos de 50 kg, cosido y paletizado en estibas de 20 sacos en Racks A-01/A-02.
- **Etapa 4 (Carga y Expedición)**: Carga en camión de despacho en muelle y cálculo de $\text{kWh/ton}$.

---

## 9. Sistema de Fallas Físicas Diegéticas (Cero Botones de Interfaz)

> [!IMPORTANT]
> **REGLA DE DISEÑO CARDINAL**: Queda estrictamente prohibido utilizar botones 2D, sliders en pantalla o menús emergentes tipo "trampa" para inducir o reparar fallas.
> Toda perturbación del sistema debe ocurrir mediante **acciones físicas corporizadas del operario en el mundo 3D**, usando sus manos, herramientas de dotación, interacción mecánica directa o manipulación del entorno.

### 9.1 Falla 1: Corte Físico de Conductores de Energía (Pérdida de Fase L3 / Desbalance)
- **Acción Física del Jugador**: El jugador toma los alicates dieléctricos de 1000 V de su cinturón de herramientas (tecla `1`), se aproxima a la caja de bornes del motor 10 HP y corta el conductor rotulado `Fase L3 (Azul)` con la tecla `E`.
- **Efectos Físicos y Eléctricos**: Disparo de arco eléctrico (`GPUParticles3D`), chispas de cobre incandescentes y fogonazo lumínico `OmniLight3D` estroboscópico. Sonido de estallido de alta tensión.
- **Respuesta Electromecánica**: $I_{L3} = 0.0\text{ A}$. Las fases $L1$ y $L2$ saltan a $\sqrt{3} \times I_{FLA} \approx 23.4\text{ A}$ ($173\%$ de sobrecorriente). Campo magnético inverso pulsante a $120\text{ Hz}$ con salto de vibración RMS a $> 4.8\text{ mm/s}$ (Zona D de ISO 10816-3). Calentamiento acelerado ($+1.2^\circ\text{C/s}$) hacia disparo térmico.

### 9.2 Falla 2: Sobrealimentación de Grano & Atasco Mecánico (Exceso de Material)
- **Acción Física del Jugador**: El operario arroja bultos de grano de $50\text{ kg}$ (`RigidBody3D`) masivamente en la tolva o gira la manivela de la compuerta guillotina al $150\%$.
- **Efectos Electromecánicos**: El flujo másico $\dot{m}$ escala a $> 4.0\text{ kg/s}$. El par resistente $T_L$ escala a $115\text{ N}\cdot\text{m}$, superando el par máximo de vuelco de Kloss ($T_{max} = 101.75\text{ N}\cdot\text{m}$). El rotor colapsa a $0\text{ RPM}$ (rotor bloqueado). La corriente trifásica salta a $I_{LRA} \approx 81.0\text{ A}$ ($600\%$). Fricción de correas con humo visible y dispersión de nube de polvo combustible (activando sensor óptico ATEX $> 30\text{ g/m}^3$).

### 9.3 Falla 3: Manipulación de Breakers en Tablero CCM (Bajones de Tensión & Desbalances)
- **Acción Física del Jugador**: El jugador abre el gabinete metálico del CCM 460 V e interactúa con las palancas de los disyuntores termomagnéticos.
- **Efectos Eléctricos**: Falsear o abrir parcialmente un breaker genera una caída de tensión resistiva (*voltage sag*): $V_{LL}$ desciende de $460\text{ V} \rightarrow 340\text{ V}$. Pérdida del $45.4\%$ del par útil ($T_e \propto V^2$). Para mantener potencia, la corriente aumenta compensatoriamente, disparando relés y provocando parpadeo (*flicker*) en las luminarias de la nave.

### 9.4 Falla 4: Obstrucción Física de la Ventilación Forzada
- **Acción Física**: El jugador arroja un saco vacío de arpillera o trapo sobre la rejilla posterior del ventilador del motor.
- **Efecto**: Decaimiento del coeficiente de enfriamiento de $K_{cool} = 15.0 \to 2.2\text{ W/}^\circ\text{C}$. El motor alcanza los $120^\circ\text{C}$ en 90 segundos a carga nominal.

### 9.5 Falla 5: Desajuste Mecánico de Pernos de Bancada (Desalineación y Rodamientos)
- **Acción Física**: El operario usa una llave fija de 3/4" en los 4 pernos de anclaje de la base del motor o el tensor de la polea.
- **Efecto**: Desalineación angular y excentricidad elevan la vibración armónica (1X y 2X RPM) a $5.6\text{ mm/s}$ (Zona D - Destructiva) con chirrido de rodamientos SKF.

---

## 10. Nube IoT, Inteligencia Artificial & Matriz RCM de Mantenimiento

El simulador procesa y emite telemetría continua (10 Hz) conectando la física del motor con los modelos de analítica e IA (ejecutados de forma nativa en GDScript o mediante microservicio local de fondo), visualizando **todo el dashboard y gemelo digital de forma 100% nativa e inmersiva dentro del juego en la Tablet Industrial diegética (sin necesidad de abrir navegadores web externos)**:

### 10.1 Vector de 8 Características de Telemetría (Dataset Maestro)
Alineado con el generador del Avance 2 (`generate_dataset.m`):
$$\mathbf{x} = \begin{bmatrix} I_{RMS} & IUF & THD & V_{RMS} & T_{winding} & \frac{dT}{dt} & Vib_{RMS} & Vib_{peak} \end{bmatrix}^T$$
Donde $IUF = \frac{\max(|I_i - I_{avg}|)}{I_{avg}} \times 100\%$ es el Factor de Desbalance de Corriente y $THD$ es la Distorsión Armónica Total.

### 10.2 Modelos de Clasificación de IA Entrenados (Avance 2)
1. **Red Neuronal Artificial (MLP 8 $\to$ 16 $\to$ 8 $\to$ 4)**:
   - Capa de entrada: 8 neuronas normalizadas por Z-Score ($\mu, \sigma$).
   - Capas ocultas: Densa 16 (ReLU) con Dropout 0.1, Densa 8 (ReLU).
   - Capa de salida: Densa 4 con activación Softmax para distribución de probabilidad categórica.
   - Rendimiento: **Accuracy 99.17%**, Cross-Entropy Loss $< 0.045$.
2. **Máquina de Soporte Vectorial (SVM Multiclase One-vs-One)**:
   - Kernel RBF: $K(\mathbf{x}, \mathbf{x}') = \exp(-\gamma \|\mathbf{x} - \mathbf{x}'\|^2)$ con $\gamma = 0.125, C = 10.0$.
   - Rendimiento: **Accuracy 98.75%**.

### 10.3 Matriz de Ruta de Mantenimiento Predictivo / RCM (Formato Oficial Guía)

| Componente Crítico | Modo de Falla Identificado por IA | Variable Predictiva Monitoreada | Instrumento de Medición | Criterio de Aceptación / Umbral | Acción Correctiva Prescrita (Ruta de Mantenimiento) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Devanado Estatórico** | Pérdida de Fase / Monofasización | $IUF$, Corriente por fase ($I_A, I_B, I_C$) | Pinza amperimétrica True-RMS / Sensor IoT Hall | $IUF < 5\%$, $I_{desbalance} < 1.5\text{ A}$ | Detener con E-Stop Cat 0. Aplicar LOTO. Verificar apriete de bornes y fusibles en CCM-01. Reemplazar tramo de conductor según RETIE. |
| **Aislamiento Térmico** | Sobrecalentamiento / Falla ventilación | Temperatura $T_{w}$, gradiente $\frac{dT}{dt}$ | Termocupla PT100 / Cámara termográfica | $T_w \le 105^\circ\text{C}$ (Límite relé), $\Delta T \le 80\text{ K}$ | Inspeccionar rejilla de ventilador. Limpiar aletas de refrigeración de polvo de cereal. Reducir carga de molienda con VFD a 45 Hz. |
| **Rodamientos SKF 6308** | Desgaste de pista / Soltura mecánica | Vibración $Vib_{RMS}$, $Vib_{peak}$ | Acelerómetro piezoeléctrico triaxial | $Vib_{RMS} < 2.3\text{ mm/s}$ (Zona A/B ISO 10816-3) | Si $Vib \ge 2.3\text{ mm/s}$ (Zona C): relubricar con grasa de litio para alta temperatura. Si $Vib > 4.5\text{ mm/s}$ (Zona D): programar cambio de rodamientos. |
| **Transmisión de Poleas** | Desalineación angular / Tensión floja | Frecuencia de vibración a 1X y 2X RPM | Tacómetro láser / Estroboscopio digital | Desalineación angular $< 0.2^\circ$, deflexión de correa 12 mm | Reajustar pernos de bancada con torquímetro. Calibrar alineación láser de poleas y tensar correas trapezoidales sección B. |
| **Tablero CCM 460 V** | Falso contacto / Bajón de tensión | Tensión eficaz $V_{LL}$, caída $\Delta V$ | Multímetro digital calibrado CAT III | $460\text{ V} \pm 5\%$ ($437 - 483\text{ V AC}$) | Si $V_{LL} < 414\text{ V}$ ($-10\%$): comprobar barrajes principales, torque de tornillería y estado de contactos de contactor de potencia. |

### 10.4 Tablet Industrial In-Game (Tecla [TAB] — Telemetría Nativa 100% en el Juego Sin Páginas Web)

> [!IMPORTANT]
> **TELEMETRÍA 100% INTEGRADA EN EL JUEGO (ESTRICTAMENTE CERO PÁGINAS WEB EXTERNAS)**:
> 1. **Cero Dependencia de Navegadores Web**: Queda terminantemente prohibido exigir al usuario abrir un navegador web o consultar páginas HTML externas para visualizar la telemetría, gráficas o diagnóstico del juego.
> 2. **Despliegue Inmersivo con la Tecla `[TAB]`**:
>    - Al presionar la tecla **`[TAB]`**, el operario saca/guarda en pantalla la **Tablet Industrial Diegética de Campo** (`IndustrialTabletController.gd`).
>    - Al desplegarse la tablet, el juego libera el cursor (`Input.MOUSE_MODE_VISIBLE`) para permitir navegación interactiva por pestañas, análisis de oscilogramas y chequeo de listas de mantenimiento.
>    - Al pulsar `[TAB]` nuevamente o presionar el botón "Cerrar", la tablet se guarda y el cursor retorna a captura de primera persona (`Input.MOUSE_MODE_CAPTURED`).
> 3. **Dashboard SCADA / Gemelo Digital con IA Integrado en la Tablet**:
>    La tablet cuenta con un panel frontal estructurado mediante nodos nativos de Godot (`Control`, `PanelContainer`, `SubViewport` y rutinas `_draw()` para strip charts vectoriales dinámicos), similar al dashboard de simulaciones con IA:
>    - **Módulo 1: Telemetría Electromecánica True-RMS**:
>      * Tensiómetro digital: $V_{LL}$ nominal $460.0\text{ V}$, frecuencia $60.0\text{ Hz}$, factor de potencia $\cos\phi = 0.85$.
>      * Amperímetro trifásico de barras dinámicas: Corrientes de línea $I_A, I_B, I_C$ con indicador numérico de desbalance $IUF$ (alerta amarilla si $IUF > 5\%$, alarma crítica roja si $IUF > 20\%$).
>      * Tacómetro y Par Electromecánico: Velocidad de rotor $N_r$ ($1750\text{ RPM}$), Par motor $T_e$ ($40.7\text{ Nm}$ nominal, vuelco $101.75\text{ Nm}$), potencia activa $P_{in}$ ($7.46\text{ kW}$).
>      * Monitoreo Térmico: Temperatura de devanado $T_w$ y carcasa $T_c$ con gradiente dinámico $\frac{dT}{dt}$ (alarma a $> 105^\circ\text{C}$).
>      * Vibración RMS y Pico: Nivel global en $\text{mm/s}$ con semáforo ISO 10816-3 (Verde Zona A/B $\le 2.3$, Amarillo Zona C $\le 4.5$, Rojo Zona D $> 4.5\text{ mm/s}$).
>    - **Módulo 2: Gráficas de Tendencia en Tiempo Real (Strip Charts Nativos en Godot)**:
>      * **Oscilograma Trifásico $I(t)$**: Señal temporal de $I_A, I_B, I_C$ en ventana rodante de 10 segundos. Permite visualizar instantáneamente el corte de fase física (caída de $I_{L3}$ a cero y elevación de $I_{L1}, I_{L2}$ a $23.4\text{ A}$) o la sobrecorriente de rotor bloqueado ($81.0\text{ A}$).
>      * **Curva Térmica $T(t)$**: Respuesta exponencial de calentamiento según constante de tiempo $\tau_{th}$.
>      * **Espectro Dinámico de Vibración**: Barras armónicas a 1X y 2X RPM mostrando la aparición de soltura o desalineación mecánica.
>    - **Módulo 3: Motor de Diagnóstico Edge AI (MLP 8-16-8-4 & SVM RBF)**:
>      * Estado clasificado en tiempo real:
>        * 🟢 `NORMAL (OPERACIÓN NOMINAL BALANCEADA)`
>        * 🟡 `SOBRECALENTAMIENTO (SOBRECARGA MECÁNICA / DEFICIENCIA TÉRMICA)`
>        * 🔴 `FALLA ELÉCTRICA CRÍTICA (PÉRDIDA DE FASE / DESBALANCE GRAVE)`
>        * 🔴 `FALLA MECÁNICA (SOLTURA DE BANCADA / EXCENTRICIDAD)`
>      * Porcentaje de certeza / confianza del modelo (ej. `Certeza IA: 99.2 % (MLP) | 98.8 % (SVM)`).
>      * **Motor Health Index (MHI)**: Barra de salud continua de $0\%$ a $100\%$ con gradiente de color (Verde $> 85\%$, Amarillo $60-85\%$, Rojo $< 60\%$).
>      * **Vida Útil Remanente (RUL)**: Estimación de horas de servicio operativas remanentes calculadas por el modelo de degradación.
>    - **Módulo 4: Alertas Push & Checklist RCM / RETIE Interactivo**:
>      * Notificación push sonora (`AudioStreamPlayer`) y banner parpadeante ante fallas inducidas.
>      * Desglose explicable de la causa raíz (*Root Cause*) y prognosis de falla (*Prognosis*).
>      * Lista de verificación interactiva (`CheckList` con casillas interactivas) donde el operario va chequeando el protocolo de seguridad y mantenimiento paso a paso a medida que resuelve la falla física en el mundo 3D.
>    - **Módulo 5: Indicadores de Optimización Energética (VFD vs DOL)**:
>      * Estado de accionamiento: DOL ($60\text{ Hz}$ fijo) vs VFD (frecuencia variable modulada por PID).
>      * Consumo específico en $\text{kWh / tonelada}$ de grano molido.
>      * Contador de mitigación ambiental: $\text{kg CO}_2\text{e}$ evitados en tiempo real.

---

## 11. Optimización Energética & Sostenibilidad Industria 5.0 (Avance 3 & Final)

Alineado con el Objetivo 1 del Tercer Corte y los Objetivos de Desarrollo Sostenible (ODS 7, 9 y 12):

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│               ESTRATEGIA DE OPTIMIZACIÓN ENERGÉTICA (VFD VS DOL)                  │
├─────────────────┬──────────────────┬──────────────────┬───────────────────────────┤
│ ARRANQUE DOL    │ VARIADOR VFD     │ CONTROL PID      │ IMPACTO AMBIENTAL         │
│ I_arranque = 81A│ Rampa suave 10 s │ Regula RPM según │ Reducción de 28.4% kWh    │
│ P_in = 8.42 kW  │ I_arranque < 20 A│ flujo de grano   │ Mitigación de             │
│ Cos phi = 0.85  │ Modula V/f       │ Ahorro a 42 Hz   │ 4.12 Ton CO2e/año         │
└─────────────────┴──────────────────┴──────────────────┴───────────────────────────┘
```

1. **Comparativa Energética: Arranque Directo (DOL) vs Variador VFD**:
   - **Arranque Directo (DOL)**: Pico de corriente de $81\text{ A}$ ($6 \times I_{FLA}$), provocando caídas de tensión en barraje, desgaste térmico en devanados y penalización por demanda máxima de potencia activa. Operación a 60 Hz fijos sin importar si la tolva está al 30% o al 100% de capacidad.
   - **Variador de Frecuencia (VFD escalar V/f con compensación $IR$)**:
     - Rampa suave de aceleración de $10\text{ s}$ limitando la corriente de arranque a $I_{arranque} \le 1.3 \times I_{FLA} \approx 17.5\text{ A}$.
     - Regulación de velocidad según demanda: Si el flujo másico baja a $0.3\text{ kg/s}$, el lazo PID reduce la frecuencia a $42\text{ Hz}$ ($1260\text{ RPM}$).
     - Debido a la ley de afinidad en cargas centrífugas de ventilación y molienda:
       $$\frac{P_2}{P_1} = \left(\frac{f_2}{f_1}\right)^3 \implies P_{42Hz} = 7.457 \cdot \left(\frac{42}{60}\right)^3 \approx 2.55\text{ kW}$$
       Permitiendo una reducción del consumo de potencia del **$65.8\%$** en periodos de baja carga.
2. **Cálculo de Consumo Específico & Reducción de Huella de Carbono**:
   - Consumo específico DOL: $10.5\text{ kWh / tonelada molida}$.
   - Consumo específico optimizado con VFD: $7.52\text{ kWh / tonelada molida}$ (**$28.38\%$ de ahorro neto**).
   - En una producción de $1000\text{ toneladas/año}$:
     $$\text{Ahorro Anual} = 1000 \cdot (10.5 - 7.52) = 2980\text{ kWh/año}$$
   - **Emisiones Evitadas de $\text{CO}_2$** (Factor de emisión del Sistema Interconectado Nacional de Colombia - UPME: $0.164\text{ kg CO}_2\text{e / kWh}$):
     $$\text{Emisiones Evitadas} = 2980\text{ kWh} \times 0.164\text{ kg CO}_2\text{e/kWh} \approx 488.7\text{ kg CO}_2\text{e/año}$$

---

## 12. Monitoreo CCTV en Mezzanine, Terminal de Capacitación & Rúbrica Académica

### 12.1 Centro de Control CCTV en Mezzanine
En la sala de control de la planta alta (Mezzanine), se implementa un banco de 4 monitores industriales CRT/LCD alimentados por `SubViewport` y cámaras estáticas en tiempo real:
- **Monitor 1**: Cámara cenital de la Zona de Molienda `M-101` y motor 10 HP.
- **Monitor 2**: Cámara frontal del Tablero CCM 460 V `CCM-01`.
- **Monitor 3**: Cámara exterior de la Báscula de Pesaje y camión tolva `B-201`.
- **Monitor 4**: Cámara del Muelle de Ensacado y Despacho `D-401`.

### 12.2 Terminal de Capacitación e Inducción con Rúbrica Académica (`0.0` a `5.0`)
El juego incluye un evaluador continuo (`SafetyEvaluationLog.gd`) que asigna una calificación técnica al usuario:
- **Puntuación Base**: $5.0 / 5.0$.
- **Penalizaciones por Actos Inseguros**:
  - Ingresar a la planta sin casco dieléctrico: $-0.8\text{ pt}$.
  - Ingresar sin calzado dieléctrico con punta de composite: $-1.0\text{ pt}$.
  - No usar protección auditiva en zona de molienda ($> 85\text{ dBA}$): $-0.6\text{ pt}$.
  - Invadir el perímetro de 1.0 m del CCM sin guantes dieléctricos 1000 V: $-1.5\text{ pt}$.
  - Abrir la compuerta de inspección del molino con el motor girando ($N_r > 0$): $-2.5\text{ pt}$ (Infracción Crítica).
  - Cortar cables o intervenir bornes sin ejecutar LOTO (5 Reglas de Oro): $-3.0\text{ pt}$.
- **Bonificaciones por Buenas Prácticas**:
  - Completar las 5 Reglas de Oro en orden estricto: $+1.0\text{ pt}$.
  - Identificar la falla diagnóstica en la Tablet y resolver la causa raíz: $+1.0\text{ pt}$.
- **Exportación Académica**: El terminal genera un archivo `Reporte_Estudiante_RETIE.json` con fecha, nombre, infracciones cometidas, tiempo de respuesta y nota final para evaluación docente.

---

## 13. Verificación Autónoma Headless (CLI)

Para validar el juego interactivo, físicas, lógica del tutorial, producción animada y modelos de IA sin entorno gráfico:
```powershell
godot --headless --path SimuladorPlantaGodot --script scripts/tests/headless_verify.gd
```
Este comando valida:
1. Parseo estricto y cero errores de tipado estático en **GDScript 2.0**.
2. Dinámica del modelo de Kloss ($T_{max} = 101.75\text{ N}\cdot\text{m}$, $I_{nom} = 13.5\text{ A}$, $I_{LRA} = 81\text{ A}$).
3. Ejecución secuencial de estados del `TutorialInductionManager` y enclavamiento de EPP.
4. Ciclo cinemático de camiones y flujo de producción en `AnimatedProductionLogistics` usando únicamente mallas descargadas.
5. Desbalance por corte de cable ($I_{L1} > 22\text{ A}$, $I_{L3} = 0\text{ A}$).
6. Conexión y serialización de tramas JSON del `CloudIoTBridge`.
7. Despliegue de la Tablet Industrial con la tecla [TAB], renderizado del Dashboard in-game con oscilogramas nativos, y recepción del diagnóstico IA sin requerir páginas web externas.
8. Validación de las fórmulas de optimización energética ($\text{kWh/ton}$) y evaluación académica.
9. Cumplimiento de la regla de no-creación procedural de modelos 3D.
10. Código de salida `0` automático para aprobación de QA.
