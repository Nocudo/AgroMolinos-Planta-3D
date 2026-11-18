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

const RISK_SCENARIOS_MATRIX: Dictionary = {
	"MOTOR": {
		"MONOFASIZACION": {
			"causes": "• Apertura o corte físico del conductor de fase L3 en la bornera del motor 10 HP.\n• Contacto sulfatado o flojo en el contactor principal K1 sin bloqueo LOTO.\n• Disparo asimétrico de fusible de potencia en una sola línea trifásica.",
			"consequences": "• Corriente en fases L1 y L2 sube ~1.73x sobre la nominal (13.4 A), generando par pulsante.\n• Calentamiento rápido en el devanado estatórico y pérdida de velocidad bajo carga de grano.\n• Riesgo de quemadura del bobinado clase F y disparo de protección por desbalance.",
			"mitigation": "• Parar el molino desde la tablet y ejecutar las 5 Reglas de Oro LOTO en el CCM.\n• Verificar ausencia de tensión (0 V) con multímetro CAT III antes de empalmar L3.\n• Activar relé diferencial de secuencia negativa y revisar torque de bornes."
		},
		"SOBRECARGA": {
			"causes": "• Ingreso brusco de grano superior a 4.0 kg/s que excede el par máximo de Kloss (Tmax).\n• Objetos metálicos o piedras atrapadas entre los martillos y la criba de la trituradora.\n• Arranque directo (DOL) con la cámara de molienda llena de cereal compactado.",
			"consequences": "• Deslizamiento crítico hasta rotor bloqueado con corriente de hasta 5–6 veces la nominal.\n• Disparo del relé térmico o límite de corriente del VFD y detención total de la molienda.\n• Fatiga torsional en el eje, chaveta y acople elástico del motor 10 HP.",
			"mitigation": "• Operar en modo VFD con rampa de aceleración suave y límite de par al 125%.\n• Vaciar la cámara y despejar la compuerta con llave 3/4\" antes de reanudar.\n• Mantener trampas magnéticas limpias y monitorear el MHI en Edge AI."
		},
		"SUBTENSION": {
			"causes": "• Caída de tensión en barraje de 460 V a 340 V por apertura de breaker L3 o red débil.\n• Arranque simultáneo de equipos pesados en DOL sin compensación reactiva.\n• Caída excesiva en el alimentador por conexiones flojas en el motor.",
			"consequences": "• El par electromagnético cae proporcionalmente al cuadrado del voltaje (V²), perdiendo ~45% de torque.\n• Aumento de corriente para sostener la carga mecánica y sobrecalentamiento del rotor.\n• Disparo por subtensión en el bus DC del variador de frecuencia (VFD).",
			"mitigation": "• Monitorear el oscilograma de tensión trifásica en la tablet y rearmar breaker L3 bajo LOTO.\n• Priorizar arranque por VFD frente a DOL para evitar huecos de tensión.\n• Ajustar relé de mínima tensión (27) con corte automático bajo 414 V (−10%)."
		},
		"VENTILACION": {
			"causes": "• Obstrucción de la rejilla trasera del ventilador TEFC con cascarilla y polvo de cereal.\n• Operación prolongada a baja frecuencia en VFD (< 25 Hz) reduciendo el caudal de aire propio.\n• Acumulación de suciedad aislante sobre las aletas de disipación de la carcasa.",
			"consequences": "• Temperatura de devanados por encima de 105 °C reduciendo a la mitad la vida útil del aislamiento por cada +10 °C.\n• Degradación prematura de la grasa en rodamientos 6306 y aumento de fricción.\n• Caída del índice MHI y parada térmica forzada del molino.",
			"mitigation": "• Detener la máquina, bloquear con LOTO y retirar la obstrucción de la rejilla trasera.\n• Soplar aletas de refrigeración en rutina semanal y verificar flujo de aire.\n• Limitar frecuencia mínima del VFD o instalar ventilación forzada independiente."
		},
		"VIBRACION": {
			"causes": "• Pernos de anclaje flojos en la bancada del motor 10 HP o desalineación angular del eje.\n• Desbalanceo dinámico en los martillos de la trituradora por desgaste desigual.\n• Holgura o picadura en rodamientos de carga del lado acople.",
			"consequences": "• Vibración RMS superior a 7.1 mm/s (Zona D ISO 10816), generando fractura de pernos y fatiga en chumaceras.\n• Ruido estructural intenso y riesgo de rotura del acople en giro a 1750 RPM.\n• Deterioro acelerado de la vida remanente (RUL) detectado por el clasificador SVM.",
			"mitigation": "• Detener el motor, aplicar LOTO y reapretar pernos de bancada con llave 3/4\".\n• Verificar alineación láser eje-molino y balancear el juego de martillos.\n• Respetar el perímetro amarillo/negro (Zona 1) mientras gira la trituradora."
		},
		"ARCO_ATEX": {
			"causes": "• Corte o desconexión bajo carga del cableado 460 V junto a nube de polvo fino de molienda.\n• Carcasa del motor mal aterrizada generando chispa por falla a tierra o descarga estática.\n• Intervención directa en bornes del motor sin desenergizar ni despejar polvo combustible.",
			"consequences": "• Arco eléctrico de alta energía con quemaduras graves (IEC 60479-1) y daño severo en caja de conexiones.\n• Ignición inmediata del polvo de grano suspendido en zona clasificada ATEX 22.\n• Sanción máxima RETIE en rúbrica y parada de emergencia de toda la nave.",
			"mitigation": "• Aplicar estrictamente las 5 Reglas de Oro LOTO y usar EPP dieléctrico/ignífugo completo.\n• Garantizar motor con grado de protección IP55/Ex tc y continuidad de puesta a tierra.\n• Mantener extracción de polvo encendida y nunca cruzar la línea roja/amarilla energizada."
		}
	},
	"BANDAS": {
		"MONOFASIZACION": {
			"causes": "• Pérdida de fase en el guardamotor del motorreductor de las bandas 01/02/04 o sinfines 05/07.\n• Cable de alimentación mordido por vibración en la bandeja portacables de la banda inclinada.\n• Falla en un polo del arrancador magnético del tornillo helicoidal.",
			"consequences": "• El motorreductor intenta arrancar con zumbido fuerte y sin torque, sobrecalentando el estator.\n• Detención súbita de la banda o del sinfín con acumulación en cadena del cereal aguas arriba.\n• Riesgo de incendio en el bobinado del reductor si el guardamotor no dispara a tiempo.",
			"mitigation": "• Instalar guardamotores térmicos sensibles a falta de fase en cada banda y sinfín.\n• Enclavamiento en cascada: si un sinfín para, se detienen automáticamente las bandas previas.\n• Revisar borneras y canaletas bajo LOTO antes de restablecer el arranque."
		},
		"SOBRECARGA": {
			"causes": "• Sobrealimentación de cereal húmedo que compacta el paso del tornillo sinfín 05/07.\n• Banda transportadora desalineada rozando contra la estructura metálica lateral.\n• Descarga excesiva del camión sobre la banda 01 superando su capacidad nominal en kg/s.",
			"consequences": "• Patinamiento de la banda sobre el tambor motriz, calentamiento por fricción y rotura del empalme.\n• Torsión o fractura del eje helicoidal del sinfín y atasco total del ducto de alimentación.\n• Disparos por sobrecorriente en el tablero y derrame de grano en zona de carga.",
			"mitigation": "• Regular la dosificación desde tolva y mantener tensores y rodillos de retorno centrados.\n• Instalar sensores de velocidad cero (cero giro) en poleas conducidas y sinfines.\n• Nunca introducir manos ni herramientas en bandas o sinfines en movimiento (Zona 8/1)."
		},
		"SUBTENSION": {
			"causes": "• Hueco de tensión en el CCM 460 V compartido con el arranque del molino principal.\n• Caída de voltaje en tendidos largos hacia las bandas exteriores de zona de carga (01 y 02).\n• Mala conexión del neutro/tierra en el circuito de control de 24/120 V de los arrancadores.",
			"consequences": "• Pérdida de velocidad lineal en las bandas generando desbalance de caudal hacia la trituradora.\n• Desenganche intermitente (chattering) de contactores auxiliares quemando sus bobinas.\n• Paros intempestivos con material acumulado sobre la banda inclinada 02.",
			"mitigation": "• Verificar calibre adecuado en alimentadores exteriores y reapretar bornes en CCM.\n• Secuenciar arranques escalonados desde la tablet (primero extracción, luego sinfines y bandas).\n• Mantener la tensión de línea estable en 460 V ±5% antes de habilitar carga."
		},
		"VENTILACION": {
			"causes": "• Fricción sostenida de rodillos trabados o cojinetes secos contra la lona de la banda.\n• Reductor de velocidad del sinfín sin aceite o cubierto por costra gruesa de harina.\n• Exposición solar directa y polvo acumulado en el motorreductor exterior de la banda 01.",
			"consequences": "• Calentamiento de la polea motriz > 90 °C con riesgo de combustión de la banda de caucho.\n• Degradación del lubricante del reductor, desgaste de engranajes helicoidales y agarrotamiento.\n• Fuente de superficie caliente capaz de encender polvo depositado en carcasas de sinfines.",
			"mitigation": "• Engrasar chumaceras periódicamente y reemplazar rodillos que presenten rozamiento o ruido.\n• Limpiar polvo acumulado en motores reductores y verificar nivel de aceite térmico.\n• Realizar termografía en poleas motrices y cajas reductoras durante operación continua."
		},
		"VIBRACION": {
			"causes": "• Tornillo helicoidal descentrado golpeando contra la camisa cilíndrica metálica.\n• Rodillos tensores ovalados, chumaceras flojas o acumulación asimétrica de grano pegado.\n• Base estructural de la banda inclinada 02 con tornillería aflojada por tránsito de camiones.",
			"consequences": "• Desgaste rápido de las aletas del sinfín, ruido metálico y generación de chispas mecánicas.\n• Descarrilamiento de la banda transportadora y fatiga en soportes y pasarelas.\n• Contaminación del cereal con limalla metálica y paro no programado de alimentación.",
			"mitigation": "• Apretar bases y chumaceras con llave 3/4\" bajo LOTO y verificar concentricidad del eje.\n• Instalar raspadores de limpieza en poleas para evitar acumulación excéntrica.\n• Mantener guardas mecánicas cerradas y respetar la línea amarilla de Zona 1 y Zona 8."
		},
		"ARCO_ATEX": {
			"causes": "• Electricidad estática acumulada por fricción de banda no antiestática en atmósfera polvorienta.\n• Chispas mecánicas por roce metal-metal del tornillo sinfín contra la carcasa llena de harina.\n• Manipulación de sensores o cables de parada de emergencia con polvo combustible en suspensión.",
			"consequences": "• Descarga electrostática o chispa de fricción que enciende la nube de polvo dentro del ducto.\n• Propagación de frente de llama a lo largo del sinfín hacia la tolva y la trituradora.\n• Riesgo de lesiones por proyección y daño estructural en toda la línea de transporte.",
			"mitigation": "• Utilizar bandas antiestáticas certificadas (ISO 284) y equipotencializar toda la estructura a tierra.\n• Mantener tapas herméticas en sinfines y sensores de desalineamiento con corte automático.\n• Operar controles a distancia y no invadir el perímetro exterior de Zona 8."
		}
	},
	"TOLVA": {
		"MONOFASIZACION": {
			"causes": "• Falla de una fase en el vibrador electromecánico o actuador de compuerta de la tolva T-301.\n• Cable de fuerza dañado en el tablero local de dosificación de recepción.\n• Fusible abierto en la alimentación trifásica del descargador de fondo.",
			"consequences": "• El vibrador pierde amplitud de descarga permitiendo la formación de puentes (bóvedas) de grano.\n• Flujo intermitente hacia la banda 04 alternando vacíos con avalanchas repentinas.\n• Sobrecalentamiento del motor vibrador y disparo de protecciones locales.",
			"mitigation": "• Verificar balance de corriente en los actuadores de la tolva y revisar fusibles bajo LOTO.\n• Comprobar el estado del flujo en el monitoreo IoT (nivel % y caudal kg/s) en tiempo real.\n• Mantener mantenimiento preventivo en borneras selladas contra polvo IP65."
		},
		"SOBRECARGA": {
			"causes": "• Apertura manual excesiva de la compuerta (> 120%) elevando el caudal sobre 4.0 kg/s.\n• Volcado simultáneo de sacos y banda inclinada 02 superando el 95% de nivel de la tolva.\n• Grano húmedo o aglomerado que obstruye la garganta inferior de descarga.",
			"consequences": "• Desbordamiento de cereal por el borde superior y atascamiento severo del cuello de salida.\n• Nube densa de polvo fino de grano elevando drásticamente el riesgo ATEX en recepción.\n• Sobrecarga inmediata en la banda 04 y en el motor 10 HP de la trituradora.",
			"mitigation": "• Mantener la apertura de compuerta calibrada al 80% (~0.80 kg/s) para régimen nominal.\n• Activar alarma de nivel alto (> 85%) y corte automático de banda inclinada a > 95%.\n• Despejar atascos únicamente con equipo detenido y usando llave 3/4\" desde zona segura."
		},
		"SUBTENSION": {
			"causes": "• Caída de tensión en el CCM 460 V afectando actuadores motorizados y sensores de nivel.\n• Fuente auxiliar de 24 V DC sin respaldo ante microcortes de la red de planta.\n• Interferencia de caída de tensión durante arranques pesados en DOL.",
			"consequences": "• Lecturas erróneas en las celdas de carga (peso kg) y sensores capacitivos de nivel.\n• Compuerta motorizada queda bloqueada a mitad de carrera causando sub o sobredosificación.\n• Pérdida temporal de telemetría de tolva hacia la tablet SCADA.",
			"mitigation": "• Alimentar instrumentación de nivel y peso con fuente regulada y respaldo UPS.\n• Estabilizar tensión de barraje en 460 V rearmando breakers bajo protocolo LOTO.\n• Calibrar apertura manual de respaldo en posición segura (80%) ante falla de control."
		},
		"VENTILACION": {
			"causes": "• Acumulación prolongada de grano con alta humedad (> 15%) retenido en esquinas muertas de la tolva.\n• Falta de aspiración localizada en la boca superior de descarga de la banda inclinada.\n• Condensación interna por contraste térmico entre patio exterior y nave cerrada.",
			"consequences": "• Fermentación y autocalentamiento biológico del grano almacenado con riesgo de brasa latente.\n• Emisión de gases y polvo fino que deterioran la calidad del aire respirable del operario.\n• Aglomeración pegajosa del producto que incrementa la fricción y atascos aguas abajo.",
			"mitigation": "• Garantizar rotación FIFO del cereal y vaciado completo de la tolva al final de turno.\n• Mantener activa la campana de extracción y usar mascarilla N95/P100 en Zona 3.\n• Controlar humedad del grano en recepción antes de descargarlo a la tolva T-301."
		},
		"VIBRACION": {
			"causes": "• Pernos de soporte del vibrador de tolva flojos o fatiga en los amortiguadores de caucho.\n• Golpes repetitivos con mazos sobre las paredes metálicas para destrabar puentes de grano.\n• Transmisión de vibración estructural desde la trituradora adyacente sin juntas flexibles.",
			"consequences": "• Fisuras por fatiga en las soldaduras de la tolva cónica y pérdida de estanqueidad al polvo.\n• Descalibración permanente de las celdas de carga de peso de la tolva.\n• Fuga continua de polvo combustible hacia el pasillo y equipos eléctricos vecinos.",
			"mitigation": "• Revisar par de apriete en soportes antivibratorios e instalar mangas flexibles de desacople.\n• Prohibir golpear la tolva manualmente; usar descompactadores neumáticos/vibradores calibrados.\n• Inspeccionar soldaduras y sellos perimetrales durante paradas programadas."
		},
		"ARCO_ATEX": {
			"causes": "• Caída libre de gran volumen de cereal seco generando fuerte carga electrostática por fricción.\n• Falta de conexión equipotencial entre la tolva metálica, compuerta y manga de descarga.\n• Uso de herramientas no antichispa o lámparas no clasificadas al inspeccionar la boca de tolva.",
			"consequences": "• Ignición de la atmósfera explosiva de polvo de cereal (Zona ATEX 20 interna / 22 externa).\n• Deflagración hacia el interior de la nave de recepción con onda de sobrepresión.\n• Lesiones térmicas al personal cercano y daño crítico a bandas y estructura.",
			"mitigation": "• Aterrizar eléctricamente tolva, compuerta y rejilla superior a la malla de tierra (< 10 Ω).\n• Emplear sensores certificados Ex ia/Ex tc y herramientas antichispa en intervenciones.\n• Evitar sobrealimentación (> 4.0 kg/s) que dispara nubes densas de polvo combustible."
		}
	},
	"TERMICO": {
		"MONOFASIZACION": {
			"causes": "• Pérdida de fase en el motor del soplador de aire (13), unidad de extracción (11) o secador rotatorio (08).\n• Daño térmico en cables expuestos a radiación cerca del horno de ladrillos (12).\n• Falla en un contacto del arrancador de los equipos del patio exterior oeste.",
			"consequences": "• Detención súbita del soplador o del tambor rotatorio dejando cereal inmóvil frente a aire caliente.\n• Acumulación de calor sin evacuación dentro del horno, intercambiador y ductos aéreos.\n• Riesgo elevado de carbonización o ignición del grano dentro del secador rotatorio.",
			"mitigation": "• Usar cableado resistente a alta temperatura (silicona/XLPE) lejos de paredes del horno.\n• Enclavamiento de seguridad: si el soplador o secador pierde fase, cortar calor de inmediato.\n• Aplicar LOTO y verificar equilibrio de fases antes de reactivar el lazo térmico."
		},
		"SOBRECARGA": {
			"causes": "• Exceso de grano húmedo retenido dentro del tambor del secador rotatorio (08).\n• Obstrucción parcial de ductos de aire (15) o aletas del intercambiador (14) con cascarilla.\n• Demanda excesiva de presión estática sobre el soplador industrial (13).",
			"consequences": "• Sobrecorriente en el accionamiento del tambor rotatorio y pérdida de eficiencia de secado.\n• Retroceso de gases calientes hacia el horno térmico y aumento de presión en ductos.\n• Humedad fuera de especificación en el producto final y riesgo de atasco en ciclones.",
			"mitigation": "• Limpiar registros de inspección de ductos (15) e intercambiador (14) periódicamente.\n• Regular el caudal de alimentación al secador acorde al porcentaje de humedad inicial.\n• Vigilar presión diferencial y temperatura del aire en la tablet SCADA."
		},
		"SUBTENSION": {
			"causes": "• Bajón de tensión a 340 V en el circuito principal afectando soplador, extractor y tambor secador.\n• Caída de voltaje en acometida exterior hacia el patio oeste de equipos térmicos.\n• Fluctuaciones en el control electrónico de compuertas de aire caliente.",
			"consequences": "• Reducción de RPM del soplador y caída drástica del flujo convectivo de aire de secado.\n• Sobrecalentamiento localizado en la cámara del horno e intercambiador de calor.\n• Inestabilidad en los lazos de control de temperatura y disparo de alarmas térmicas.",
			"mitigation": "• Mantener tensión nominal de 460 V estable desde el CCM y verificar apriete en borneras exteriores.\n• Configurar purga automática de aire frío cuando la tensión caiga por debajo del 90%.\n• Supervisar temperatura de salida del secador antes de restablecer alimentación de grano."
		},
		"VENTILACION": {
			"causes": "• Falla de tiro en la unidad de extracción (11) o compuerta de aire de dilución cerrada.\n• Aislamiento refractario agrietado en el horno térmico de ladrillos (12) irradiando calor exterior.\n• Incrustaciones en el intercambiador de calor (14) reduciendo la transferencia térmica controlada.",
			"consequences": "• Temperaturas superiores a 140 °C en ductos y secador con riesgo de incendio de polvo fino.\n• Estrés térmico y peligro de quemaduras por contacto en superficies calientes de Zona 9.\n• Deformación térmica de ductos metálicos y daño en sellos rotativos del secador.",
			"mitigation": "• Mantener sensores de sobretemperatura con corte automático y purga de aire fresco.\n• Respetar el perímetro de seguridad de Zona 9 y mantener aislamiento/señalización térmica.\n• Inspeccionar mampostería del horno, juntas de expansión y caudal de la unidad de extracción."
		},
		"VIBRACION": {
			"causes": "• Rodetes del soplador (13) o del extractor (11) desbalanceados por adherencia de polvo/ceniza.\n• Desgaste irregular en los aros de rodadura o rodillos de apoyo del secador rotatorio (08).\n• Soportes y tirantes flojos en la red aérea de ductos de aire (15).",
			"consequences": "• Fatiga en ejes del soplador, daño en rodamientos y ruido aerodinámico severo.\n• Desacople o fractura de bridas en ductos aéreos con fuga de aire caliente a presión.\n• Desalineación axial del tambor del secador con desgaste acelerado de coronas.",
			"mitigation": "• Limpiar y balancear dinámicamente los rodetes del soplador y extractor en parada LOTO.\n• Ajustar alineación de rodillos soporte del tambor y verificar anclajes de ductos aéreos.\n• Monitorear tendencia de vibración en Edge AI para detectar desequilibrio incipiente."
		},
		"ARCO_ATEX": {
			"causes": "• Arrastre de pavesas o partículas incandescentes desde el horno (12) hacia los ductos y el secador.\n• Mezcla de aire caliente con alta concentración de polvo fino seco dentro de ductos (15).\n• Falla eléctrica en la unidad de extracción adosada al muro sin protección contra polvo.",
			"consequences": "• Incendio interno en ductos de aire y propagación rápida hacia los ciclones separadores.\n• Explosión secundaria por remoción de polvo depositado en la nave principal.\n• Parada crítica de seguridad, daño severo al sistema térmico y riesgo vital.",
			"mitigation": "• Mantener en buen estado el intercambiador de calor (calentamiento indirecto libre de chispas).\n• Instalar detectores de chispa/temperatura en ductos y compuertas cortafuego.\n• Conservar limpieza estricta libre de depósitos de polvo alrededor de Zona 9."
		}
	},
	"ATEX": {
		"MONOFASIZACION": {
			"causes": "• Pérdida de fase en el motor del ventilador extractor acoplado a los ciclones clasificadores (09/10).\n• Desconexión accidental en la línea de fuerza de la válvula rotativa inferior de descarga.\n• Falla en contactor o fusible de protección del sistema de aspiración neumática.",
			"consequences": "• Pérdida inmediata de succión ciclónica: el polvo fino deja de separarse y escapa a la nave.\n• Taponamiento del cono inferior al detenerse la válvula rotativa de descarga.\n• Aumento rápido de concentración de polvo combustible en el ambiente de Zona 7.",
			"mitigation": "• Proteger ventilador y válvula rotativa con relés de secuencia/falta de fase.\n• Enclavar la molienda con la extracción: si los ciclones pierden aspiración, detener la tolva.\n• Restablecer fase únicamente tras LOTO y verificación de atmósfera libre de nube de polvo."
		},
		"SOBRECARGA": {
			"causes": "• Caudal excesivo de harina fina proveniente de sobrealimentación en tolva (> 4.0 kg/s).\n• Obstrucción del cono de descarga o saturación del filtro de mangas posterior al ciclón.\n• Condensación de humedad formando torta de harina adherida a las paredes internas.",
			"consequences": "• Pérdida de eficiencia centrífuga con emisión masiva de polvo fino hacia la nave de producción.\n• Aumento de contrapresión neumática sobrecargando el soplador y reduciendo el secado.\n• Acumulación crítica de material combustible en zonas clasificadas ATEX 22.",
			"mitigation": "• Controlar la tasa de alimentación nominal (0.80 kg/s) y revisar periódicamente descargas cónicas.\n• Monitorear caída de presión diferencial en los ciclones (09 y 10) desde la tablet.\n• Programar limpieza interna en seco con aspiración certificada Ex, nunca soplado con aire comprimido."
		},
		"SUBTENSION": {
			"causes": "• Caída de voltaje a 340 V en el barraje principal reduciendo la velocidad de los extractores.\n• Perturbación eléctrica que reinicia los sensores de presión diferencial y detectores de polvo.\n• Conexiones sulfatadas en el tablero auxiliar de la zona de clasificación.",
			"consequences": "• Caída de la velocidad tangencial de entrada al ciclón por debajo del umbral de separación.\n• Retorno de partículas finas al ambiente laboral reduciendo visibilidad y seguridad respiratoria.\n• Pérdida temporal de monitoreo automático de atmósfera explosiva ATEX.",
			"mitigation": "• Mantener tensión regulada en 460 V y respaldar detectores de polvo/presión con UPS.\n• Reestablecer breaker L3 bajo LOTO antes de reiniciar el transporte neumático.\n• Verificar caudal de aspiración estable antes de reabrir la descarga de molienda."
		},
		"VENTILACION": {
			"causes": "• Recirculación insuficiente de aire en la nave de ciclones y extracción exterior bloqueada.\n• Ingreso de producto sobrecalentado (> 85 °C) desde el secador rotatorio al cono del ciclón.\n• Acumulación de capas gruesas de polvo (> 5 mm) sobre motores y luminarias de Zona 7.",
			"consequences": "• Reducción de la temperatura mínima de ignición en capa (MIT) del polvo de cereal.\n• Combustión latente (smoldering) silenciosa dentro del cono del ciclón clasificador.\n• Degradación de la calidad del aire y exposición respiratoria del personal.",
			"mitigation": "• Mantener ventilación general y extracción localizada operando continuamente antes y después del turno.\n• Controlar temperatura de entrada al ciclón y eliminar toda acumulación de polvo en superficies.\n• Exigir uso de respirador N95/P100 y gafas selladas al transitar cerca de Zona 7."
		},
		"VIBRACION": {
			"causes": "• Golpe de ariete neumático por pulsaciones de aire y descargas irregulares en el ciclón.\n• Anclajes metálicos flojos en la torre soporte del ciclón separador (09) de 6 m de altura.\n• Desbalanceo del rotor de la válvula rotativa inferior o del ventilador extractor.",
			"consequences": "• Aflojamiento de bridas y empaques generando fugas continuas de polvo fino a presión.\n• Roce mecánico en las paletas de la válvula rotativa capaz de generar chispas de fricción.\n• Fatiga estructural en ductos elevados y soportes de los ciclones gemelos (10).",
			"mitigation": "• Inspeccionar apriete de bridas, sellos de neopreno y pernos de torre soporte bajo LOTO.\n• Revisar holgura radial de la válvula rotativa para evitar contacto metal-metal.\n• Utilizar juntas flexibles conductivas entre ductos y cuerpos ciclónicos."
		},
		"ARCO_ATEX": {
			"causes": "• Descarga electrostática por movimiento ciclónico de polvo seco en cuerpos sin puente equipotencial.\n• Chispa eléctrica de luminarias, teléfonos o maniobras sin clasificación Ex en Zona ATEX 22.\n• Ingreso de brasa o partícula metálica caliente arrastrada desde la trituradora o secador.",
			"consequences": "• Explosión primaria dentro del ciclón seguida de deflagración secundaria en la nave.\n• Sobrepresión destructiva, proyección de fragmentos y quemaduras graves al personal.\n• Destrucción del sistema de clasificación y parada total por emergencia industrial.",
			"mitigation": "• Verificar continuidad de puesta a tierra y puentes equipotenciales en todas las bridas (< 10 Ω).\n• Instalar paneles de alivio de explosión (discos de ruptura) orientados hacia zona exterior segura.\n• Prohibir fuentes de ignición, soldadura en caliente y cruce de líneas de seguridad en Zona 7."
		}
	},
	"CCM": {
		"MONOFASIZACION": {
			"causes": "• Corte de fase en bornera de salida, fusible fundido o contacto quemado en seccionador de 460 V.\n• Manipulación indebida de conductores L1-L2-L3 con alicates sin ejecutar bloqueo LOTO.\n• Disparo monopolar por aflojamiento mecánico en las barras de cobre del CCM.",
			"consequences": "• Desbalance crítico de corrientes aguas abajo y sobrecalentamiento de barras y contactores.\n• Riesgo inminente de contacto eléctrico directo a 460 V (zona AC-4 de IEC 60479-1).\n• Sanción RETIE grave y parada forzada de toda la línea productiva.",
			"mitigation": "• Ejecutar estrictamente las 5 Reglas de Oro LOTO: abrir, bloquear, verificar 0 V, aterrizar y señalizar.\n• Usar exclusivamente multímetro CAT III 600 V y EPP dieléctrico certificado.\n• Reemplazar fusibles tripolares en juego completo y verificar par de apriete en barras."
		},
		"SOBRECARGA": {
			"causes": "• Arranque simultáneo de múltiples motores en DOL superando la capacidad térmica del barraje.\n• Ajuste incorrecto del relé de sobrecarga por encima de la corriente nominal de placa.\n• Sobrecorriente sostenida por atasco de molienda no despejado a tiempo.",
			"consequences": "• Calentamiento excesivo de barras, cables THHN y disparos repetitivos del breaker totalizador.\n• Envejecimiento acelerado de aislamientos y riesgo de cortocircuito fase-fase dentro del gabinete.\n• Daño en la etapa de potencia IGBT del variador de frecuencia (VFD).",
			"mitigation": "• Operar el molino en modo VFD para reducir corriente de arranque de 6x In a ~1.2x In.\n• Coordinar curvas de disparo (selectividad) entre breaker principal, VFD y guardamotores.\n• Realizar inspección termográfica periódica de barras, contactores y borneras."
		},
		"SUBTENSION": {
			"causes": "• Apertura manual o disparo del Breaker L3 reduciendo la tensión efectiva a 340 V.\n• Fallo en el transformador de alimentación de planta o caída en la acometida de media tensión.\n• Terminales flojos en el seccionador principal provocando caída resistiva bajo carga.",
			"consequences": "• Disparo por subtensión del bus DC del VFD y caída de bobinas de contactores auxiliares.\n• Pérdida de torque en toda la planta y reinicios abruptos que estresan equipos mecánicos.\n• Alarma crítica inmediata en la tablet SCADA y detención del proceso.",
			"mitigation": "• Abrir el gabinete solo con EPP completo, verificar tensión con multímetro CAT III y aplicar LOTO.\n• Rearmar el Breaker L3 únicamente tras confirmar ausencia de fallas aguas abajo.\n• Mantener relé supervisor de tensión (bajo/sobrevoltaje y secuencia de fase) activo."
		},
		"VENTILACION": {
			"causes": "• Filtros de ventilación del gabinete CCM obstruidos por polvo fino de harina.\n• Falla del ventilador interno de refrigeración del variador de frecuencia (VFD).\n• Puerta del tablero dejada abierta permitiendo ingreso de polvo conductor/combustible.",
			"consequences": "• Temperatura interna > 55 °C disparando protección térmica del VFD y descalibrando bimetálicos.\n• Acortamiento severo de la vida útil de condensadores electrolíticos y tarjetas PLC/IoT.\n• Riesgo de cortocircuito por seguimiento superficial (tracking) sobre aisladores sucios.",
			"mitigation": "• Mantener cerrada y sellada la puerta del CCM (grado IP54 mínimo) durante operación.\n• Limpiar filtros de aire del tablero semanalmente y verificar giro del ventilador del VFD.\n• Monitorear temperatura interna del gabinete y del disipador del variador en la tablet."
		},
		"VIBRACION": {
			"causes": "• Vibración transmitida por la losa desde la trituradora 10 HP ubicada en zona contigua.\n• Golpes frecuentes al cerrar bruscamente la puerta o accionar palancas de seccionadores.\n• Rieles DIN o bloques de borneras mal fijados dentro del gabinete metálico.",
			"consequences": "• Aflojamiento progresivo de tornillos en bornes de potencia generando puntos calientes.\n• Falsos contactos en señales de parada de emergencia, PLC y sensores de telemetría.\n• Riesgo de arco incipiente por conductor suelto dentro del compartimento de 460 V.",
			"mitigation": "• Efectuar reapriete periódico con torquímetro aislado en bornes de potencia bajo LOTO.\n• Utilizar borneras con resorte antivibración en circuitos de control e instrumentación.\n• Mantener despeje frontal de 1 m (Zona 2 RETIE) libre de golpes o almacenamiento."
		},
		"ARCO_ATEX": {
			"causes": "• Maniobra de breakers o contacto accidental con herramienta metálica dentro del CCM energizado a 460 V.\n• Cortocircuito entre fases por ingreso de polvo o humedad en el barraje principal.\n• Ignorar la línea roja de Zona 2 RETIE e intervenir sin candado/tarjeta LOTO ni EPP ignífugo.",
			"consequences": "• Relámpago de arco eléctrico (arc flash > 40 cal/cm² posible), onda explosiva y radiación UV/térmica.\n• Electrocución letal o quemaduras de tercer grado y destrucción del gabinete CCM.\n• Máxima penalización en rúbrica RETIE y activación obligatoria de parada de emergencia.",
			"mitigation": "• Cumplir las 5 Reglas de Oro LOTO, usar guantes dieléctricos, careta antiflash y ropa ignífuga.\n• Operar paradas y cambios VFD/DOL de forma remota desde la Tablet Industrial.\n• Respetar estrictamente el despeje de 1.0 m (Zona 2 roja) frente al tablero 460 V."
		}
	},
	"LOGISTICA": {
		"MONOFASIZACION": {
			"causes": "• Pérdida de fase en el motor eléctrico de los portones enrollables industriales de la bahía.\n• Falla en una línea del tablero auxiliar de alumbrado y niveladores de muelle.\n• Cable de fuerza aplastado por maniobra de estibadores cerca de la puerta derecha.",
			"consequences": "• Portón enrollable trabado a media altura bloqueando el despacho o la ruta de evacuación.\n• Calentamiento del motor tubular del portón y disparo del circuito de bahía.\n• Paralización de carga manual de sacos de 50 kg y congestión de tractocamiones.",
			"mitigation": "• Revisar protecciones del accionamiento de portones y canalizar cables en altura protegida.\n• Usar cadena manual de emergencia solo con el seccionador del portón bloqueado en LOTO.\n• Verificar funcionamiento suave de portones al inicio de cada turno."
		},
		"SOBRECARGA": {
			"causes": "• Apilamiento de sacos de 50 kg por encima de la altura segura en pallets o estanterías.\n• Sobreesfuerzo biomecánico de operarios cargando sacos sin pausas ni ayuda mecánica.\n• Exceso de peso sobre la plataforma de muelle o carga desbalanceada en el semirremolque.",
			"consequences": "• Desplome de arrumes de sacos sobre el pasillo peatonal o sobre el personal de almacén.\n• Lesiones osteomusculares lumbares, rotura de sacos y pérdida de producto terminado.\n• Inestabilidad del tráiler en maniobra de salida por centro de gravedad desplazado.",
			"mitigation": "• Limitar estiba a máximo 6–8 niveles trabados en pallet y respetar pasillos demarcados.\n• Aplicar técnica ergonómica de levantamiento, rotación de operarios y uso de estibadores.\n• Distribuir simétricamente la carga dentro del contenedor antes de autorizar salida."
		},
		"SUBTENSION": {
			"causes": "• Caída de tensión en circuitos de iluminación de bahía de carga y almacén de sacos.\n• Microcortes eléctricos que apagan semáforos de muelle, balizas y cámaras CCTV de patio.\n• Sobrecarga en tomas auxiliares usadas para selladoras/cosedoras de sacos.",
			"consequences": "• Visibilidad deficiente durante el acoplamiento en reversa de tractocamiones.\n• Falla en sellado térmico de sacos generando fugas de harina en el almacén.\n• Pérdida temporal de señalización luminosa entre señalero y conductor.",
			"mitigation": "• Mantener luminarias LED industriales con respaldo de emergencia en bahías y muelles.\n• Separar circuitos de fuerza de molienda respecto a alumbrado y selladoras de almacén.\n• Suspender maniobras de acople vehicular si falla la iluminación o señalización."
		},
		"VENTILACION": {
			"causes": "• Acumulación de gases de escape diésel (CO/NOx) de tractocamiones con motor encendido en muelle.\n• Baja renovación de aire y alta temperatura ambiente en el almacén cerrado de sacos.\n• Polvo fino levantado al apilar o romper sacos de harina cerca de la puerta derecha.",
			"consequences": "• Intoxicación leve, fatiga o irritación ocular/respiratoria en operarios de carga y logística.\n• Aumento de humedad relativa que apelmaza el producto almacenado en sacos.\n• Visibilidad reducida en el área de transición entre almacén y bahía vehicular.",
			"mitigation": "• Exigir apagar el motor del tractocamión inmediatamente al acoplar y colocar cuñas.\n• Mantener ventilación cruzada y extractores activos durante jornadas de despacho.\n• Usar mascarilla contra material particulado y limpiar derrames con aspiradora industrial."
		},
		"VIBRACION": {
			"causes": "• Tránsito continuo de tractocamiones pesados sobre la losa de acceso y golpes contra topes de muelle.\n• Ruedas desgastadas en estibadores manuales circulando sobre juntas de concreto deterioradas.\n• Impacto de carga al arrojar sacos de 50 kg bruscamente sobre pallets.",
			"consequences": "• Desplazamiento gradual de pilas de sacos vecinas con riesgo de caída repentina.\n• Fisuración del borde del muelle y deterioro de guías de los portones enrollables.\n• Fatiga en las manos y espalda del operario que manipula equipos de transporte interno.",
			"mitigation": "• Instalar topes de caucho absorbentes de impacto en la bahía derecha y controlar velocidad (< 10 km/h).\n• Mantener losas, rampas y ruedas de estibadores en óptimo estado mecánico.\n• Colocar los sacos de forma controlada sin soltarlos en caída libre sobre la estiba."
		},
		"ARCO_ATEX": {
			"causes": "• Invasión de Zona 6 (bahía de carga) durante maniobra de reversa del camión sin señalero.\n• Derrame y nube de harina por rotura de sacos junto a gases calientes o chispas de escape vehicular.\n• Contacto de vehículo o montacargas contra canalizaciones eléctricas de la puerta enrollable.",
			"consequences": "• Atropellamiento o atrapamiento entre semirremolque y muelle de concreto (riesgo fatal OSHA).\n• Ignición de nube de polvo de harina por tubo de escape caliente o cortocircuito en portón.\n• Daño grave a la infraestructura de despacho y sanción crítica en seguridad industrial.",
			"mitigation": "• Nunca cruzar la línea amarilla de Zona 6 con camiones en maniobra; coordinar siempre con el señalero.\n• Colocar cuñas en las ruedas antes de iniciar cargue manual y barrer derrames de inmediato.\n• Proteger tableros y ductos eléctricos del muelle con bolardos metálicos amarillos."
		}
	}
}

static func get_risk_scenario(machine_id: String, factor_id: String) -> Dictionary:
	if RISK_SCENARIOS_MATRIX.has(machine_id):
		var m_dict: Dictionary = RISK_SCENARIOS_MATRIX[machine_id]
		if m_dict.has(factor_id):
			var sc: Dictionary = m_dict[factor_id]
			return {
				"causes": str(sc.get("causes", "")),
				"consequences": str(sc.get("consequences", "")),
				"mitigation": str(sc.get("mitigation", ""))
			}
	return {
		"causes": "• Condición operativa anómala en el equipo seleccionado.",
		"consequences": "• Riesgo operativo y detención preventiva del proceso.",
		"mitigation": "• Detener el equipo, aplicar LOTO y verificar condiciones seguras."
	}
