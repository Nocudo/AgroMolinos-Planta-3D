class_name TabletDataCatalog
extends RefCounted

## Catálogo de equipos, cámaras 3D, personal, normativa RETIE y escenarios de riesgo.

const CAMERA_GROUPS_ORDER: Array[String] = ["G1", "G2", "G3", "G4", "G5", "WORKERS"]

const CAMERA_GROUP_TABS: Array[Dictionary] = [
	{"id": "G1", "txt": "Recepción"},
	{"id": "G2", "txt": "Molienda"},
	{"id": "G3", "txt": "Ciclones"},
	{"id": "G4", "txt": "Aire y CCM"},
	{"id": "G5", "txt": "Patio"},
	{"id": "WORKERS", "txt": "Operarios"}
]

const PLANT_MACHINES_SPEC: Array[Dictionary] = [
	# G1 · Recepción
	{
		"id": "01_BANDA_DESCARGA",
		"glow_group": "banda_descarga",
		"title": "01 · Banda de Descarga",
		"subtitle": "Zona de Carga",
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
		"title": "02 · Banda Inclinada",
		"subtitle": "Zona de Carga",
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
		"title": "03 · Tolva Receptora",
		"subtitle": "Recepción",
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
		"title": "04 · Banda Trituradora",
		"subtitle": "Alimentación",
		"group": "G1",
		"target_node": "Node1365",
		"fallback_pos": Vector3(-22.75, 1.63, 45.00),
		"yaw_deg": 24.0,
		"front_yaw_deg": 0.0,
		"pitch_deg": 20.0,
		"dist": 4.6
	},
	# G2 · Molienda y Secado
	{
		"id": "05_TORNILLO_TRITURADORA",
		"glow_group": "tornillo_trituradora",
		"title": "05 · Tornillo Trituradora",
		"subtitle": "Molienda",
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
		"title": "06 · Trituradora y Motor 10 HP",
		"subtitle": "Molienda",
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
		"title": "07 · Tornillo Secador",
		"subtitle": "Secado",
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
		"title": "08 · Secador Rotatorio",
		"subtitle": "Secado",
		"group": "G2",
		"target_node": "Group#54",
		"fallback_pos": Vector3(-25.68, 2.92, 36.93),
		"yaw_deg": -28.0,
		"front_yaw_deg": 0.0,
		"pitch_deg": 20.0,
		"dist": 6.4
	},
	# G3 · Ciclones y Horno
	{
		"id": "09_CICLON_SEPARADOR",
		"glow_group": "ciclon_separador",
		"title": "09 · Ciclón Separador",
		"subtitle": "Ciclones",
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
		"title": "10 · Ciclones Clasificadores",
		"subtitle": "Zona ATEX",
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
		"title": "11 · Unidad de Extracción",
		"subtitle": "Exterior Oeste",
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
		"title": "12 · Horno Térmico",
		"subtitle": "Exterior Oeste",
		"group": "G3",
		"target_node": "Node1503",
		"fallback_pos": Vector3(-35.94, 3.39, 34.35),
		"yaw_deg": -32.0,
		"front_yaw_deg": 0.0,
		"pitch_deg": 20.0,
		"dist": 5.5
	},
	# G4 · Aire y CCM
	{
		"id": "13_SOPLADOR",
		"glow_group": "soplador",
		"title": "13 · Soplador",
		"subtitle": "Exterior Oeste",
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
		"title": "14 · Intercambiador de Calor",
		"subtitle": "Exterior Oeste",
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
		"title": "15 · Ductos de Aire",
		"subtitle": "Red Aérea",
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
		"title": "CCM · Tablero 460 V",
		"subtitle": "Control Eléctrico",
		"group": "G4",
		"target_node": "PhysicalBreakerPanel",
		"fallback_pos": Vector3(-20.48, 1.52, 38.50),
		"yaw_deg": -18.0,
		"front_yaw_deg": 0.0,
		"pitch_deg": 16.0,
		"dist": 1.75
	},
	# G5 · Patio y Vistas Generales
	{
		"id": "CAMION_DESPACHO",
		"glow_group": "truck",
		"title": "Camión de Carga",
		"subtitle": "Bahía Norte",
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
		"title": "Almacén de Sacos",
		"subtitle": "Almacén",
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
		"title": "Pasillo Central",
		"subtitle": "Vista General",
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
		"title": "Zona de Carga Exterior",
		"subtitle": "Vista General",
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
		"name": "Carlos Mendoza",
		"role": "Supervisor SST",
		"model_path": "res://assets/models/trabajador_sst.glb",
		"station": "Recorrido de planta",
		"rh": "O+",
		"clearance": "RETIE / SG-SST"
	},
	{
		"id": "WorkerElectrician",
		"name": "Andrés Rojas",
		"role": "Técnico Electromecánico",
		"model_path": "res://assets/models/trabajador_mantenimiento.glb",
		"station": "Tablero CCM 460 V",
		"rh": "A+",
		"clearance": "CONTE / LOTO"
	},
	{
		"id": "WorkerPlantManager",
		"name": "Ing. Diana Morales",
		"role": "Jefe de Planta",
		"model_path": "res://assets/models/trabajador_jefe_planta.glb",
		"station": "Nave de producción",
		"rh": "B+",
		"clearance": "COPNIA / SCADA"
	},
	{
		"id": "WorkerLogistics",
		"name": "Luis Herrera",
		"role": "Operario de Logística",
		"model_path": "res://assets/models/trabajador_logistica.glb",
		"station": "Almacén y despacho",
		"rh": "O-",
		"clearance": "Carga y ATEX"
	}
]

const PLANT_CCTV_CAMERAS: Array[Dictionary] = [
	{
		"id": "CAM_01_MOLIENDA",
		"short": "CAM 01 · Trituradora",
		"zone": "Zona de Molienda",
		"group": "INTERIOR",
		"position": Vector3(-19.5, 5.0, 41.2),
		"look_at": Vector3(-25.81, 1.8, 42.60),
		"fov": 60.0
	},
	{
		"id": "CAM_02_CCM460V",
		"short": "CAM 02 · Tablero CCM",
		"zone": "Tablero CCM 460 V",
		"group": "INTERIOR",
		"position": Vector3(-17.8, 3.9, 41.2),
		"look_at": Vector3(-20.48, 1.52, 38.50),
		"fov": 58.0
	}
]

const RISK_MACHINES: Array[Dictionary] = [
	{"id": "MOTOR", "label": "Trituradora y Motor 10 HP"},
	{"id": "BANDAS", "label": "Bandas y Sinfines"},
	{"id": "TOLVA", "label": "Tolva Receptora"},
	{"id": "TERMICO", "label": "Área Térmica y Ductos"},
	{"id": "ATEX", "label": "Ciclones ATEX"},
	{"id": "CCM", "label": "Tablero CCM 460 V"},
	{"id": "LOGISTICA", "label": "Zona de Carga y Almacén"}
]

const RISK_FACTORS: Array[Dictionary] = [
	{"id": "MONOFASIZACION", "label": "Pérdida de fase L3"},
	{"id": "SOBRECARGA", "label": "Sobrecarga y atasco"},
	{"id": "SUBTENSION", "label": "Bajón de tensión"},
	{"id": "VENTILACION", "label": "Sobretemperatura"},
	{"id": "VIBRACION", "label": "Vibración excesiva"},
	{"id": "ARCO_ATEX", "label": "Arco eléctrico o polvo ATEX"}
]

const TABLE1_RETIE: Array[Dictionary] = [
	{"factor": "Arco eléctrico", "cause": "Maniobra en caliente sin LOTO.", "control": "EPP ignífugo y 5 Reglas LOTO."},
	{"factor": "Contacto eléctrico", "cause": "Falla de aislamiento o invasión del CCM.", "control": "Puesta a tierra y operación a distancia."},
	{"factor": "Sobrecarga", "cause": "Exceso de grano en tolva.", "control": "Control VFD y compuerta regulada."},
	{"factor": "Subtensión", "cause": "Disparo de fase L3 en breaker.", "control": "Ajuste de barrajes y monitoreo."},
	{"factor": "Polvo ATEX", "cause": "Acumulación de polvo en ciclones.", "control": "Extracción activa y distancia segura."}
]

const RISK_CAUSES_BY_FACTOR: Dictionary = {
	"MONOFASIZACION": "Corte o desconexión en fase L3 sin bloqueo LOTO.",
	"SOBRECARGA": "Exceso de grano en tolva o traba mecánica en el rotor.",
	"SUBTENSION": "Apertura del breaker L3 con caída de tensión a 340 V.",
	"VENTILACION": "Obstrucción en la rejilla del motor o deriva térmica.",
	"VIBRACION": "Pernos de bancada o chumaceras flojas.",
	"ARCO_ATEX": "Intervención bajo carga con polvo combustible o cruce de perímetro."
}

const RISK_CONSEQ_BY_FACTOR: Dictionary = {
	"MONOFASIZACION": "Sobrecorriente en fases sanas, par pulsante y riesgo eléctrico.",
	"SOBRECARGA": "Detención del rotor, corriente de bloqueo y paro de la línea.",
	"SUBTENSION": "Pérdida de par motor y disparo del variador VFD.",
	"VENTILACION": "Temperatura superior a 105 °C y daño al aislamiento.",
	"VIBRACION": "Desgaste acelerado de rodamientos y desalineación.",
	"ARCO_ATEX": "Arco eléctrico, riesgo de ignición y sanción RETIE."
}

const RISK_MITIG_BY_FACTOR: Dictionary = {
	"MONOFASIZACION": "Detener desde la tablet, aplicar LOTO y empalmar fase L3.",
	"SOBRECARGA": "Detener la línea y despejar la tolva con llave 3/4\".",
	"SUBTENSION": "Aplicar LOTO y rearmar el breaker en el tablero CCM.",
	"VENTILACION": "Detener el motor, despejar la rejilla y dejar enfriar.",
	"VIBRACION": "Detener la máquina y apretar pernos con llave 3/4\".",
	"ARCO_ATEX": "Respetar líneas de seguridad y mantener la extracción activa."
}

static func get_risk_scenario(machine_id: String, factor_id: String) -> Dictionary:
	var ctx: String = ""
	match machine_id:
		"MOTOR": ctx = "Motor 10 HP: "
		"BANDAS": ctx = "Bandas y sinfines: "
		"TOLVA": ctx = "Tolva: "
		"TERMICO": ctx = "Área térmica: "
		"ATEX": ctx = "Ciclones: "
		"CCM": ctx = "Tablero CCM: "
		_: ctx = "Logística: "
	return {
		"causes": ctx + str(RISK_CAUSES_BY_FACTOR.get(factor_id, "")),
		"consequences": str(RISK_CONSEQ_BY_FACTOR.get(factor_id, "")),
		"mitigation": str(RISK_MITIG_BY_FACTOR.get(factor_id, ""))
	}
