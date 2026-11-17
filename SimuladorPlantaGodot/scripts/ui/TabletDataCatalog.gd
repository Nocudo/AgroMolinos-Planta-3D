class_name TabletDataCatalog
extends RefCounted

## Catálogo actualizado de las 15 máquinas en orden de proceso, CCM 460 V reubicado,
## cámaras 3D interactivas en vivo, operarios actuales, normativa RETIE Tabla 1 y matriz de riesgos.

const CAMERA_GROUPS_ORDER: Array[String] = ["G1", "G2", "G3", "G4", "G5", "WORKERS"]

const CAMERA_GROUP_TABS: Array[Dictionary] = [
	{"id": "G1", "txt": "Recepción (4)"},
	{"id": "G2", "txt": "Molienda (4)"},
	{"id": "G3", "txt": "Ciclón/Horno (4)"},
	{"id": "G4", "txt": "Aire & CCM (4)"},
	{"id": "G5", "txt": "Patio/Vista (4)"},
	{"id": "WORKERS", "txt": "Operarios (4)"}
]

const PLANT_MACHINES_SPEC: Array[Dictionary] = [
	# G1 · Recepción & Alimentación (01–04)
	{
		"id": "01_BANDA_DESCARGA",
		"glow_group": "banda_descarga",
		"title": "01 · Banda Descarga (Roja)",
		"subtitle": "Zona 8 · Descarga",
		"group": "G1",
		"target_node": "Group#510",
		"fallback_pos": Vector3(-30.54, 0.90, 51.32),
		"yaw_deg": 48.0,
		"front_yaw_deg": 90.0,
		"pitch_deg": 24.0,
		"dist": 4.8
	},
	{
		"id": "02_BANDA_INCLINADA",
		"glow_group": "banda_inclinada_tolva",
		"title": "02 · Banda Inclinada Tolva (Verde)",
		"subtitle": "Zona 8 · Elevador",
		"group": "G1",
		"target_node": "Node1472",
		"fallback_pos": Vector3(-27.98, 2.37, 48.87),
		"yaw_deg": 35.0,
		"front_yaw_deg": 90.0,
		"pitch_deg": 22.0,
		"dist": 5.6
	},
	{
		"id": "03_TOLVA_T301",
		"glow_group": "hopper",
		"title": "03 · Tolva Receptora T-301 (Gris)",
		"subtitle": "Estación 6 · Tolva T-301",
		"group": "G1",
		"target_node": "Node1583",
		"fallback_pos": Vector3(-26.11, 2.59, 46.60),
		"yaw_deg": 6.0,
		"front_yaw_deg": 0.0,
		"pitch_deg": 24.0,
		"dist": 4.4
	},
	{
		"id": "04_BANDA_TRITURADORA",
		"glow_group": "banda_trituradora",
		"title": "04 · Banda hacia Sinfín Trituradora (Verde)",
		"subtitle": "Zona 1 · Alimentación",
		"group": "G1",
		"target_node": "Node1365",
		"fallback_pos": Vector3(-22.75, 1.63, 45.00),
		"yaw_deg": 24.0,
		"front_yaw_deg": 0.0,
		"pitch_deg": 20.0,
		"dist": 4.6
	},
	# G2 · Trituración & Secado (05–08)
	{
		"id": "05_TORNILLO_TRITURADORA",
		"glow_group": "tornillo_trituradora",
		"title": "05 · Tornillo Sin Fin Trituradora (Verde)",
		"subtitle": "Zona 1 · Sinfín Entrada",
		"group": "G2",
		"target_node": "Group#149",
		"fallback_pos": Vector3(-24.06, 2.56, 42.29),
		"yaw_deg": -30.0,
		"front_yaw_deg": -90.0,
		"pitch_deg": 22.0,
		"dist": 4.2
	},
	{
		"id": "06_TRITURADORA_MOTOR",
		"glow_group": "motor",
		"title": "06 · Trituradora + Motor 10 HP (Gris/Rojo)",
		"subtitle": "Estación 5 · Motor 10 HP",
		"group": "G2",
		"target_node": "MotorMillUnit",
		"fallback_pos": Vector3(-25.81, 2.36, 42.60),
		"yaw_deg": -32.0,
		"front_yaw_deg": 0.0,
		"pitch_deg": 24.0,
		"dist": 4.9
	},
	{
		"id": "07_TORNILLO_SECADOR",
		"glow_group": "tornillo_secador",
		"title": "07 · Tornillo Sin Fin Secador (Verde)",
		"subtitle": "Zona 1 · Sinfín Secador",
		"group": "G2",
		"target_node": "Node2161",
		"fallback_pos": Vector3(-25.71, 2.56, 41.46),
		"yaw_deg": 18.0,
		"front_yaw_deg": 0.0,
		"pitch_deg": 20.0,
		"dist": 4.2
	},
	{
		"id": "08_SECADOR_ROTATORIO",
		"glow_group": "secador_rotatorio",
		"title": "08 · Secador Rotatorio (Gris Rugoso)",
		"subtitle": "Zona 1 · Secador",
		"group": "G2",
		"target_node": "Group#54",
		"fallback_pos": Vector3(-25.68, 2.92, 36.93),
		"yaw_deg": -28.0,
		"front_yaw_deg": 0.0,
		"pitch_deg": 20.0,
		"dist": 6.4
	},
	# G3 · Ciclones & Térmico (09–12)
	{
		"id": "09_CICLON_SEPARADOR",
		"glow_group": "ciclon_separador",
		"title": "09 · Ciclón Separador (Gris Liso)",
		"subtitle": "Estación 7 · Ciclón",
		"group": "G3",
		"target_node": "Group#501",
		"fallback_pos": Vector3(-25.59, 6.20, 33.38),
		"yaw_deg": 28.0,
		"front_yaw_deg": 0.0,
		"pitch_deg": 18.0,
		"dist": 8.6
	},
	{
		"id": "10_CICLONES_ATEX",
		"glow_group": "cyclone",
		"title": "10 · Ciclones Clasificadores (Amarillos)",
		"subtitle": "Estación 7 · ATEX 22",
		"group": "G3",
		"target_node": "Group#14",
		"fallback_pos": Vector3(-25.98, 3.14, 29.15),
		"yaw_deg": 24.0,
		"front_yaw_deg": 0.0,
		"pitch_deg": 14.0,
		"dist": 5.2
	},
	{
		"id": "11_UNIDAD_EXTRACCION",
		"glow_group": "unidad_extraccion",
		"title": "11 · Unidad de Extracción (Pared)",
		"subtitle": "Nave Oeste · Extracción",
		"group": "G3",
		"target_node": "Node1313",
		"fallback_pos": Vector3(-39.85, 1.56, 36.34),
		"yaw_deg": 28.0,
		"front_yaw_deg": 0.0,
		"pitch_deg": 18.0,
		"dist": 3.5
	},
	{
		"id": "12_HORNO_TERMICO",
		"glow_group": "horno",
		"title": "12 · Horno Térmico (Ladrillos)",
		"subtitle": "Bahía Oeste · Horno",
		"group": "G3",
		"target_node": "Node1503",
		"fallback_pos": Vector3(-35.94, 3.39, 34.35),
		"yaw_deg": -32.0,
		"front_yaw_deg": 0.0,
		"pitch_deg": 20.0,
		"dist": 5.5
	},
	# G4 · Aire & CCM Reubicado (13–15 + CCM)
	{
		"id": "13_SOPLADOR",
		"glow_group": "soplador",
		"title": "13 · Soplador (Azul/Morado)",
		"subtitle": "Bahía Oeste · Soplador",
		"group": "G4",
		"target_node": "Node1495",
		"fallback_pos": Vector3(-35.54, 1.79, 38.59),
		"yaw_deg": 36.0,
		"front_yaw_deg": 90.0,
		"pitch_deg": 20.0,
		"dist": 4.6
	},
	{
		"id": "14_INTERCAMBIADOR",
		"glow_group": "intercambiador_calor",
		"title": "14 · Intercambiador de Calor (Caracol)",
		"subtitle": "Bahía Oeste · Intercambiador",
		"group": "G4",
		"target_node": "Node1172",
		"fallback_pos": Vector3(-33.50, 1.76, 31.01),
		"yaw_deg": -102.0,
		"front_yaw_deg": -90.0,
		"pitch_deg": 10.0,
		"dist": 3.0
	},
	{
		"id": "15_DUCTOS_AIRE",
		"glow_group": "ductos_aire",
		"title": "15 · Ductos de Aire Neumáticos",
		"subtitle": "Red Aérea · Transporte",
		"group": "G4",
		"target_node": "Node1356",
		"fallback_pos": Vector3(-32.46, 5.81, 34.80),
		"yaw_deg": -95.0,
		"front_yaw_deg": -90.0,
		"pitch_deg": -6.0,
		"dist": 7.5
	},
	{
		"id": "CCM460_VFD",
		"glow_group": "breaker",
		"title": "CCM · Tablero Eléctrico 460 V & VFD",
		"subtitle": "Estación 4 · CCM 460 V",
		"group": "G4",
		"target_node": "PhysicalBreakerPanel",
		"fallback_pos": Vector3(-20.48, 1.52, 38.50),
		"yaw_deg": -18.0,
		"front_yaw_deg": 0.0,
		"pitch_deg": 16.0,
		"dist": 1.75
	},
	# G5 · Logística & Vistas Generales de Planta
	{
		"id": "CAMION_DESPACHO",
		"glow_group": "truck",
		"title": "Camión Carga / Despacho (Bahía)",
		"subtitle": "Zona 6 · Despacho",
		"group": "G5",
		"target_node": "NCDOT International Box Truck",
		"fallback_pos": Vector3(-38.37, 1.91, 51.31),
		"yaw_deg": 38.0,
		"front_yaw_deg": 0.0,
		"pitch_deg": 22.0,
		"dist": 11.4
	},
	{
		"id": "ALMACEN_SUPERSACO",
		"glow_group": "bag",
		"title": "Almacén Racks & Super Sacos 50 kg",
		"subtitle": "Estación 8 · Almacén",
		"group": "G5",
		"target_node": "super saco",
		"fallback_pos": Vector3(-26.07, 1.74, 26.50),
		"yaw_deg": 24.0,
		"front_yaw_deg": 0.0,
		"pitch_deg": 18.0,
		"dist": 4.2
	},
	{
		"id": "PANORAMICA_NAVE",
		"glow_group": "",
		"title": "Panorámica Pasillo Central (Nave)",
		"subtitle": "Pasillo Central",
		"group": "G5",
		"target_node": "",
		"fallback_pos": Vector3(-21.5, 2.2, 36.5),
		"yaw_deg": -72.0,
		"front_yaw_deg": -90.0,
		"pitch_deg": 16.0,
		"dist": 12.0
	},
	{
		"id": "ZONA8_EXTERIOR",
		"glow_group": "banda_descarga",
		"title": "Bahía Recepción & Zona 8 Exterior",
		"subtitle": "Zona 8 Exterior",
		"group": "G5",
		"target_node": "",
		"fallback_pos": Vector3(-29.85, 1.35, 51.20),
		"yaw_deg": 45.0,
		"front_yaw_deg": 90.0,
		"pitch_deg": 24.0,
		"dist": 7.8
	}
]

const PLANT_WORKERS_SPEC: Array[Dictionary] = [
	{
		"id": "WorkerSafetyAuditor",
		"name": "Supervisor SST (Guía RETIE)",
		"role": "Inspector Seguridad RETIE / OSHA",
		"model_path": "res://assets/models/trabajador_sst.glb",
		"station": "Guía Dinámico (Estaciones 1–12)",
		"rh": "O+",
		"clearance": "Certificado RETIE / SG-SST Nivel III"
	},
	{
		"id": "WorkerElectrician",
		"name": "Técnico Electromecánico",
		"role": "Operación Tablero CCM 460V & VFD",
		"model_path": "res://assets/models/trabajador_mantenimiento.glb",
		"station": "Estación 4 — CCM 460 V (Junto a Maquinaria)",
		"rh": "A+",
		"clearance": "Matrícula CONTE / LOTO Categoría 2"
	},
	{
		"id": "WorkerPlantManager",
		"name": "Jefe de Planta / Ing. Control",
		"role": "Supervisión Tren 15 Máquinas & Edge AI",
		"model_path": "res://assets/models/trabajador_jefe_planta.glb",
		"station": "Pasillo Central Nave — Estación 5",
		"rh": "B+",
		"clearance": "COPNIA / SCADA & Eficiencia IE3"
	},
	{
		"id": "WorkerLogistics",
		"name": "Operario Almacén y Logística",
		"role": "Recepción Zona 8, Sacos 50 kg & Camiones",
		"model_path": "res://assets/models/trabajador_logistica.glb",
		"station": "Estación 8 — Almacén & Despacho",
		"rh": "O-",
		"clearance": "Certificado Carga Segura & ATEX"
	}
]

const PLANT_CCTV_CAMERAS: Array[Dictionary] = [
	{
		"id": "CAM_01_MOLIENDA",
		"short": "CAM 01 · Trituradora 10 HP",
		"zone": "Zona 1 — Trituradora M-101 & Motor IE3",
		"group": "INTERIOR",
		"position": Vector3(-19.5, 5.0, 41.2),
		"look_at": Vector3(-25.81, 1.8, 42.60),
		"fov": 60.0
	},
	{
		"id": "CAM_02_CCM460V",
		"short": "CAM 02 · Tablero CCM 460V",
		"zone": "Zona 2 — Gabinete CCM Junto a Maquinaria",
		"group": "INTERIOR",
		"position": Vector3(-17.8, 3.9, 41.2),
		"look_at": Vector3(-20.48, 1.52, 38.50),
		"fov": 58.0
	}
]

const RISK_MACHINES: Array[Dictionary] = [
	{"id": "MOTOR", "label": "06 · Trituradora + Motor 10 HP"},
	{"id": "BANDAS", "label": "01–07 · Bandas y Sinfines"},
	{"id": "TOLVA", "label": "03 · Tolva T-301"},
	{"id": "TERMICO", "label": "08–15 · Área Térmica y Ductos"},
	{"id": "ATEX", "label": "09–11 · Ciclones ATEX 22"},
	{"id": "CCM", "label": "CCM · Tablero 460 V & VFD"},
	{"id": "LOGISTICA", "label": "Zona 6/8 · Bahía y Almacén"}
]

const RISK_FACTORS: Array[Dictionary] = [
	{"id": "MONOFASIZACION", "label": "Pérdida Fase L3 / Contacto 460 V"},
	{"id": "SOBRECARGA", "label": "Sobrecarga y Atasco (81 A)"},
	{"id": "SUBTENSION", "label": "Bajón Tensión CCM (340 V)"},
	{"id": "VENTILACION", "label": "Sobretemperatura (> 105 °C)"},
	{"id": "VIBRACION", "label": "Pernos Flojos / Vibración (Zona D)"},
	{"id": "ARCO_ATEX", "label": "Arco / Polvo ATEX 22 / Cruce Líneas"}
]

const TABLE1_RETIE: Array[Dictionary] = [
	{"factor": "Arcos Eléctricos", "cause": "Corte L3 o maniobra sin LOTO.", "control": "EPP 8 cal/cm² y 5 Reglas LOTO."},
	{"factor": "Contacto Eléctrico", "cause": "Zona 2 CCM o falla aislamiento.", "control": "Tierra PE < 10 Ω y selección remota."},
	{"factor": "Sobrecarga y Atasco", "cause": "Exceso tolva T-301 (81 A LRA).", "control": "Modulación VFD y compuerta."},
	{"factor": "Subtensión e IUF", "cause": "Disparo breaker L3 en CCM.", "control": "Torque barrajes y monitoreo IoT."},
	{"factor": "Polvo ATEX 22", "cause": "Nube cereal en ciclones.", "control": "Extracción activa y distancia."}
]

const RISK_CAUSES_BY_FACTOR: Dictionary = {
	"MONOFASIZACION": "Corte o desconexión en fase L3 sin bloqueo LOTO.",
	"SOBRECARGA": "Carga excesiva de grano (> 3.0 kg/s) o traba mecánica (par Kloss > 101.75 Nm).",
	"SUBTENSION": "Apertura breaker L3 en CCM (caída a 340 V).",
	"VENTILACION": "Obstrucción en rejilla motor o deriva térmica.",
	"VIBRACION": "Pernos de bancada o chumaceras flojas.",
	"ARCO_ATEX": "Corte bajo carga en polvo ATEX o cruce de líneas."
}

const RISK_CONSEQ_BY_FACTOR: Dictionary = {
	"MONOFASIZACION": "Ia=23.4 A (173% FLA), par pulsante 120 Hz y riesgo eléctrico.",
	"SOBRECARGA": "0 RPM, corriente rotor bloqueado (81 A) y paro de línea.",
	"SUBTENSION": "Pérdida 45% par (Te ∝ V²) y disparo VFD.",
	"VENTILACION": "Temperatura > 105 °C y degradación de aislamiento Clase F.",
	"VIBRACION": "Vibración > 4.5 mm/s (Zona D) y daño en rodamientos.",
	"ARCO_ATEX": "Arco eléctrico, riesgo ignición polvo y sanción RETIE."
}

const RISK_MITIG_BY_FACTOR: Dictionary = {
	"MONOFASIZACION": "5 Reglas LOTO RETIE, empalmar L3 con Kit LOTO [5].",
	"SOBRECARGA": "Selección remota (<= 30 m), normalizar tolva T-301 con Llave [3].",
	"SUBTENSION": "Rearmar breaker L3 en CCM con Kit LOTO [5].",
	"VENTILACION": "Limpiar rejilla con Manos [1] y enfriar equipo.",
	"VIBRACION": "Ajustar pernos con Llave 3/4\" [3] (Zona A/B <= 2.3 mm/s).",
	"ARCO_ATEX": "No cruzar líneas de peligro; operar a distancia desde pasillo."
}

static func get_risk_scenario(machine_id: String, factor_id: String) -> Dictionary:
	var ctx: String = ""
	match machine_id:
		"MOTOR": ctx = "06 · Motor 10 HP: "
		"BANDAS": ctx = "01–07 · Bandas/Sinfines: "
		"TOLVA": ctx = "03 · Tolva T-301: "
		"TERMICO": ctx = "08–15 · Área Térmica: "
		"ATEX": ctx = "09–11 · Ciclones ATEX: "
		"CCM": ctx = "CCM 460 V: "
		_: ctx = "Zona Logística: "
	return {
		"causes": ctx + str(RISK_CAUSES_BY_FACTOR.get(factor_id, "")),
		"consequences": str(RISK_CONSEQ_BY_FACTOR.get(factor_id, "")),
		"mitigation": str(RISK_MITIG_BY_FACTOR.get(factor_id, ""))
	}
