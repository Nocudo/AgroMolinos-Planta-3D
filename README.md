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

Plataforma integral de accionamiento electromecánico, monitoreo predictivo de fallas con Inteligencia Artificial y simulación interactiva en 3D (Serious Game en Unity) para la **Planta Molino de Granos** de la empresa **AgroMolinos del Valle S.A.**.

### Especificaciones Técnicas del Accionamiento Crítico
- **Máquina Eléctrica:** Motor Trifásico de Inducción Jaula de Ardilla (Clase IE3 Premium Efficiency)
- **Potencia Nominal:** $10\text{ HP} \approx 7.457\text{ kW}$
- **Tensión / Frecuencia:** $460\text{ V AC}$, trifásico, $60\text{ Hz}$
- **Velocidad Nominal:** $1750\text{ RPM}$ ($p = 4$ polos, velocidad sincrónica $1800\text{ RPM}$)
- **Corriente Nominal a Plena Carga ($I_{FLA}$):** $\approx 13.5\text{ A}$ por fase
- **Sistema de Control:** Variador de Frecuencia (VFD) con Control Directo de Par (DTC) y rampa suave
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
├── SimuladorPlanta3D/              # Proyecto de Unity (Serious Game 3D con URP)
│   ├── Assets/_Project/            # Scripts (.asmdef), Scenes, Prefabs, Materials y UI
│   ├── Packages/manifest.json      # Configuración de dependencias URP e Input System
│   └── ProjectSettings/            # Configuración de versión y motor de físicas
├── PLAN_SIMULADOR_PLANTA_3D_UNITY.md # Plan maestro modular de 10 bloques de desarrollo
└── .gitignore                      # Reglas de exclusión para Unity, MATLAB y LaTeX
```

---

## 🎮 Simulador 3D en Unity (`SimuladorPlanta3D/`)

El simulador pone al usuario en el rol de un **operario industrial** dentro de la planta de molienda:
1. **Fase de Inducción y Vestidor:** Obligación de equipar el EPP adecuado (casco clase E, gafas policarbonato, copas auditivas NRR > 25 dB, botas dieléctricas y guantes) antes de que la esclusa permita acceder a la nave.
2. **Respeto de Distancias y Zonas Críticas:** Alertas automáticas ante proximidad excesiva al CCM bajo carga (RETIE / Arc Flash) o a piezas móviles (ISO 13857).
3. **Procedimiento LOTO:** Ejecución secuencial de las 5 Reglas de Oro para intervención segura.
4. **Panel Dual de Simulación de Riesgos:** Inyección de riesgos de planta (atasco en tolva, pérdida de fase L3, vibración severa en rodamientos, fallo térmico y riesgo de explosión por polvo ATEX) e infracciones del operario.
5. **Señalización Industrial:** Baliza Andon 3D de 4 estados, sirenas espaciales y panel de alarmas según norma ISA 18.2.

---

## 👥 Guía Rápida de Colaboración (Git)

```bash
# 1. Clonar el repositorio
git clone <URL_DEL_REPOSITORIO>
cd "Proyecto final"

# 2. Crear una rama de trabajo para tu tarea
git checkout -b feature/bloque-X-nombre

# 3. Guardar cambios y subir
git add .
git commit -m "feat: implementado Bloque X"
git push origin feature/bloque-X-nombre
```
