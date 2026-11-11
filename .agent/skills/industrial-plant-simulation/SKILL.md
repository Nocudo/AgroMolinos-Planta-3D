---
name: industrial-plant-simulation
description: Specialized simulation skill for the 'Máquinas Eléctricas' final project (Planta Molino de Granos). Covers 3D Unity industrial plant architecture, 10HP 460V induction motor physics, VFD control, real-time SCADA/HMI telemetry, safety protocols (E-Stop, LOTO, interlocks, ATEX grain dust), alarm annunciators, and fault injection.
---

# Simulación de Planta Industrial: Molino de Granos & Máquinas Eléctricas

Esta skill contiene la arquitectura integral, modelos matemáticos en C#, protocolos de seguridad industrial y guías de implementación en **Unity 6 / Unity LTS** para el **Proyecto Final de Máquinas Eléctricas (Universidad de los Llanos)**:
**Sector Asignado: Planta Molino de Granos** con **Motor Trifásico de Inducción Jaula de Ardilla (10 HP, 460 V)**.

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

## 2. Arquitectura de Simulación en Unity

```
Assets/_Project/
├── Scripts/
│   ├── Machines/
│   │   ├── InductionMotorPhysics.cs      # Modelo matemático dinámico (par, deslizamiento, corriente, temperatura)
│   │   ├── VFDInverterController.cs      # Control escalar V/f, rampa Hz, cálculo de consumo kWh
│   │   └── MillMechanicalLoad.cs         # Modelo de carga del molino (fricción + carga de molienda proporcional)
│   ├── Safety/
│   │   ├── EmergencyStopSystem.cs        # Parada de emergencia Categoría 0/1 (IEC 60204-1, ISO 13850)
│   │   ├── LOTOMachineLock.cs            # Procedimiento de bloqueo y etiquetado (candado, tarjeta, 5 reglas de oro)
│   │   ├── SafetyInterlockGate.cs        # Microswitch en compuerta de trituración / tolva
│   │   └── CombustibleDustHazard.cs      # Riesgo ATEX / NFPA 61 por polvo combustible en suspensión
│   ├── Instrumentation/
│   │   ├── AlarmAnnunciatorISA.cs        # Gestión de alarmas con baliza Andon (Verde, Amarillo, Rojo, Azul) y sirena
│   │   ├── SCADATelemetryPanel.cs        # Instrumentación HMI (amperímetros, tacómetro, termómetro, vibrómetro)
│   │   └── FaultInjector.cs              # Inyector de fallas para pruebas pedagógicas y de robustez
│   └── Interaction/
│       ├── OperatorInteraction.cs        # Raycast interactivo para botones, palancas, candados y compuertas
│       └── MachineGizmoVisualizer.cs     # Gizmos de rotación de eje, vibración y humo de advertencia
```

---

## 3. Modelo Matemático en C# (Física del Motor y Térmica)

### 3.1 Curva Par-Velocidad y Deslizamiento (Ecuación de Kloss simplificada)
$$s = \frac{N_s - N}{N_s}$$
$$T_{elec} \approx \frac{2 T_{max}}{\frac{s}{s_{max}} + \frac{s_{max}}{s}}$$
Donde $s_{max} \approx 0.15$ y $T_{max} \approx 2.5 \times T_{nom}$.

### 3.2 Dinámica Térmica (Ecuación Diferencial Térmica de 1er Orden)
Las pérdidas totales $P_{loss} = P_{Cu} + P_{Fe} + P_{mec}$ calientan la masa estatórica:
$$\frac{dT}{dt} = \frac{P_{loss}(I) - k_{cool}(N) \cdot (T - T_{amb})}{C_{th}}$$
- $P_{Cu} = 3 \cdot I^2 \cdot R_s$ (pérdidas en el cobre proporcionales al cuadrado de la corriente)
- $k_{cool}(N)$: Capacidad de enfriamiento del ventilador acoplado al eje (disminuye fuertemente si el motor opera a bajas RPM con alto par, justificando el uso de ventilación forzada en VFD).
- Límite de advertencia: $85^\circ\text{C}$; Límite crítico de disparo por relé térmico: $105^\circ\text{C}$.

### 3.3 Dinámica de Vibración (Norma ISO 10816-3 para Máquinas Clase II)
- **Zona A/B (Buena / Aceptable)**: $V_{RMS} < 2.3\text{ mm/s}$ (Operación normal)
- **Zona C (Alerta)**: $2.3\text{ mm/s} \le V_{RMS} < 4.5\text{ mm/s}$ (Desalineación o soltura mecánica incipiente)
- **Zona D (Peligro / Parada)**: $V_{RMS} \ge 4.5\text{ mm/s}$ (Riesgo inminente de destrucción de rodamientos)

---

## 4. Medidas de Seguridad Industrial & Protocolos de Planta

### 4.1 Parada de Emergencia (E-Stop)
- **Botón tipo Hongo (Mushroom Pushbutton)** con enclavamiento mecánico giratorio para desbloqueo.
- **Cable de tracción (Pull-rope switch)** a lo largo del transportador de tornillo sinfín / elevador de grano.
- **Categoría de Parada 0 (IEC 60204-1)**: Desconexión eléctrica instantánea de potencia mediante contactor de seguridad principal.
- **Acción en Unity**: Detiene la rampa del VFD, activa el freno electrodinámico/mecánico, enciende baliza roja parpadeante y activa sirena de alarma continua.

### 4.2 Procedimiento LOTO (Lockout / Tagout - Bloqueo y Etiquetado)
1. **Paso 1: Notificación y Paro Operacional** - Detener el molino desde el HMI.
2. **Paso 2: Aislamiento Eléctrico** - Bajar el interruptor termomagnético / seccionador en el tablero CCM.
3. **Paso 3: Bloqueo Físico** - Colocar el candado rojo de seguridad con pasador múltiple.
4. **Paso 4: Etiquetado** - Fijar la tarjeta LOTO con fecha, responsable y advertencia de "NO OPERAR".
5. **Paso 5: Descarga y Verificación de Energía Cero (5 Reglas de Oro)** - Intentar el arranque en la botonera local para comprobar que el circuito carece de energía residual.

### 4.3 Enclavamiento de Seguridad en Compuertas (Interlocks)
- Sensor magnético codificado en la tapa superior de los martillos del molino.
- Si la compuerta se abre con $N > 0\text{ RPM}$, se dispara una **violación de seguridad**:
  - Parada de emergencia forzada.
  - Alarma de peligro al operador por riesgo de atrapamiento o proyección de partículas.

### 4.4 Riesgo de Atmósfera Explosiva por Polvo de Granos (ATEX / NFPA 61)
- El polvo de trigo/maíz suspendido en concentraciones $> 30\text{ g/m}^3$ es altamente inflamable.
- Simulación de:
  - Sensor óptico de densidad de polvo en el recinto del molino.
  - Sistema de extracción y mangas de desempolvado (Cyclone / Baghouse filter).
  - Alerta por falla de extracción: si la densidad supera el umbral sin ventilación forzada $\rightarrow$ alerta de riesgo de explosión.

---

## 5. Panel SCADA / HMI en Unity

El panel de control interactivo incluye:
1. **Instrumentación de Medición**:
   - Voltímetro trifásico ($460\text{ V}$).
   - Amperímetro RMS por fase ($I_A, I_B, I_C$).
   - Frecuencímetro VFD ($0 - 60\text{ Hz}$).
   - Tacómetro digital ($0 - 1800\text{ RPM}$).
   - Termómetro de devanados y rodamientos ($^\circ\text{C}$).
   - Vibrómetro RMS ($\text{mm/s}$).
   - Medidor de Potencia Activa ($P$ en $\text{kW}$) y Acumulador de Energía ($E$ en $\text{kWh}$).
   - Indicador de Factor de Potencia ($\cos\phi$).
2. **Mandos de Control**:
   - Pulsador de Marcha (Start - Verde).
   - Pulsador de Paro (Stop - Negro).
   - Selector de Frecuencia / Potenciómetro VFD ($0$ a $60\text{ Hz}$).
   - Control de Alimentación de Grano (Tasa de alimentación $0\%$ a $120\%$ para provocar sobrecarga controlada).
   - Pulsador de Reset de Fallas (Azul).
3. **Torre de Luces Andon**:
   - **Verde fijo**: Operación normal nominal.
   - **Amarillo parpadeante**: Alerta preventiva (temperatura $> 85^\circ\text{C}$ o sobrecarga leve).
   - **Rojo parpadeante**: Falla crítica, disparo por sobrecorriente o E-Stop accionado.
   - **Azul fijo**: Modo LOTO activado (equipo fuera de servicio seguro).

---

## 6. Módulo Pedagógico de Inyección de Fallas

Permite simular escenarios reales de avería para evaluación del estudiante:
1. **Atasco Mecánico / Sobrecarga**: Incrementa la carga del molino al $150\%$, disparando la corriente a $20\text{ A}$, elevando la temperatura y probando la protección térmica de sobrecarga ($I^2t$).
2. **Pérdida de Fase (Single-Phasing)**: Desconecta la Fase L3; las fases L1 y L2 absorben $\sqrt{3}$ veces la corriente, con oscilación de torque a $120\text{ Hz}$ y disparo por desbalance.
3. **Desgaste / Falla de Rodamiento**: Multiplica la vibración RMS por $3\times$, entrando en Zona D de la ISO 10816-3.
4. **Falla de Ventilación**: Desactiva el enfriamiento forzado para observar embalamiento térmico por encima de $110^\circ\text{C}$.
5. **Violación de Seguridad (Apertura de Compuerta sin LOTO)**: Demuestra el riesgo de accidente laboral y la activación del interlock de seguridad.
