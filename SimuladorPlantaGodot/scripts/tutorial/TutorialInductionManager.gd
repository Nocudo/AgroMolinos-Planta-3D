class_name TutorialInductionManager
extends Node3D

# ==============================================================================
# GESTOR DEL MODO TUTORIAL / RECORRIDO RETIE (PORTERÍA, GUÍA, ROPA EPP, LOTO,
# 12 ESTACIONES Y LÍNEA VISUAL DE RECORRIDO EN SUELO)
# ==============================================================================

const LotoControllerScript = preload("res://scripts/tutorial/LotoGoldenRulesController.gd")

const SoundSynth = preload("res://scripts/core/IndustrialSoundSynthesizer.gd")

const CCM_STATION_ID: int = 10

const STATIONS: Array[Dictionary] = [
	{"id": 1, "title": "Estación 1: Portería", "pos": Vector3(52.0, 0.02, 34.0), "desc": "Inicio del recorrido en Portería."},
	{"id": 2, "title": "Estación 2: Vestidores EPP", "pos": Vector3(-15.9, 0.79, 47.88), "desc": "Equipa tu EPP en los lockers."},
	{"id": 3, "title": "Estación 3: Zona de Carga y Banda de Descarga", "pos": Vector3(-25.6, 0.59, 51.2), "desc": "Recepción de camión y Banda 01 de descarga."},
	{"id": 4, "title": "Estación 4: Banda Inclinada hacia Tolva", "pos": Vector3(-24.6, 0.59, 50.2), "desc": "Banda 02 elevadora hacia la tolva receptora."},
	{"id": 5, "title": "Estación 5: Tolva de Recepción T-301", "pos": Vector3(-18.69, 0.79, 46.6), "desc": "Tolva 03 dosificadora de grano crudo."},
	{"id": 6, "title": "Estación 6: Banda hacia Sinfín Trituradora", "pos": Vector3(-18.69, 0.79, 44.8), "desc": "Banda 04 transportadora desde la tolva."},
	{"id": 7, "title": "Estación 7: Tornillo Sin Fin Trituradora", "pos": Vector3(-18.69, 0.79, 43.1), "desc": "Tornillo 05 alimentador helicoidal de la trituradora."},
	{"id": 8, "title": "Estación 8: Trituradora y Motor 10 HP", "pos": Vector3(-18.69, 0.79, 41.8), "desc": "Motor 06 de inducción trifásico 10 HP, 460 V."},
	{"id": 9, "title": "Estación 9: Tornillo Sin Fin al Secador", "pos": Vector3(-18.69, 0.79, 40.3), "desc": "Tornillo 07 de transferencia al secador rotatorio."},
	{"id": 10, "title": "Estación 10: Tablero CCM 460 V", "pos": Vector3(-18.69, 0.79, 38.5), "desc": "Centro de Control de Motores, VFD y 5 Reglas LOTO."},
	{"id": 11, "title": "Estación 11: Secador Rotatorio", "pos": Vector3(-18.69, 0.79, 36.6), "desc": "Secador 08 térmico para control de humedad."},
	{"id": 12, "title": "Estación 12: Ciclón Separador", "pos": Vector3(-18.69, 0.79, 33.4), "desc": "Ciclón 09 separador neumático de sólidos."},
	{"id": 13, "title": "Estación 13: Ciclones Clasificadores", "pos": Vector3(-18.69, 0.79, 29.4), "desc": "Ciclones clasificadores y control de polvo ATEX 22."},
	{"id": 14, "title": "Estación 14: Almacén de Sacos 50 kg", "pos": Vector3(-18.69, 0.79, 26.5), "desc": "Empaque, estiba en pallets y despacho."},
	{"id": 15, "title": "Estación 15: Intercambiador de Calor", "pos": Vector3(-36.5, 0.02, 22.2), "desc": "Equipo 14 exterior de transferencia térmica."},
	{"id": 16, "title": "Estación 16: Horno Térmico", "pos": Vector3(-44.2, 0.02, 34.3), "desc": "Horno 12 exterior de aire caliente."},
	{"id": 17, "title": "Estación 17: Unidad de Extracción", "pos": Vector3(-44.2, 0.02, 36.4), "desc": "Unidad 11 exterior de succión y ventilación."},
	{"id": 18, "title": "Estación 18: Soplador", "pos": Vector3(-44.2, 0.02, 38.8), "desc": "Soplador 13 de impulsión neumática."},
	{"id": 19, "title": "Estación 19: Ductos de Aire y Cierre", "pos": Vector3(-43.2, 0.02, 40.8), "desc": "Red 15 de ductos de aire y cierre exterior del recorrido."}
]

# Ruta segura verificada: 0 muros, 0 cruces de líneas de seguridad (Zone1/2/6/8/9), 0 choques con camiones
const TOUR_ROUTE_POINTS: Array[Vector3] = [
	Vector3(52.0, 0.04, 34.0),    # 0: Estación 1 - Portería
	Vector3(48.0, 0.04, 34.0),    # 1: Salida garita Portería por sendero peatonal
	Vector3(44.8, 0.22, 39.2),    # 2: Incorporación exterior a acera bloque administrativo
	Vector3(37.2, 0.22, 43.2),    # 3: Acera concreto Este edificio administrativo (Y=0.20)
	Vector3(34.5, 0.22, 48.5),    # 4: Acera exterior esquina Noreste edificio administrativo
	Vector3(32.0, 0.22, 52.0),    # 5: Inicio acera Norte edificio administrativo (Y=0.20)
	Vector3(24.0, 0.22, 52.25),   # 6: Acera Norte frente Sala de Reuniones (lejos de vía camiones Z=58.3)
	Vector3(14.0, 0.22, 52.5),    # 7: Acera Norte frente oficinas administrativas
	Vector3(2.0, 0.04, 53.4),     # 8: Sendero Oeste hacia plataforma exterior Bahía Norte
	Vector3(-11.4, 0.04, 53.75),  # 9: Pie exterior Este de rampa Bahía Norte
	Vector3(-14.0, 0.34, 53.75),  # 10: Ascenso rampa exterior Norte
	Vector3(-16.6, 0.63, 53.55),  # 11: Cima de rampa exterior Bahía Norte
	Vector3(-15.5, 0.63, 50.6),   # 12: Plataforma exterior Bahía Norte hacia Vestidores
	Vector3(-13.9, 0.63, 49.85),  # 13: Frente exterior centrado a Puerta Norte Vestidores
	Vector3(-13.9, 0.83, 49.45),  # 14: Umbral losa acceso Vestidores (Y=0.79)
	Vector3(-13.9, 0.83, 47.55),  # 15: Centro exacto del vano puerta Vestidores
	Vector3(-14.85, 0.83, 47.58), # 16: Estación 2 - Vestidores EPP (lockers)
	Vector3(-13.9, 0.83, 47.55),  # 17: Salida de Vestidores por centro de vano
	Vector3(-13.9, 0.83, 49.45),  # 18: Umbral losa salida Vestidores
	Vector3(-13.9, 0.63, 49.85),  # 19: Plataforma exterior Norte
	Vector3(-18.69, 0.63, 50.5),  # 20: Paso seguro hacia Zona de Carga (Y=0.59, fuera de Zone8)
	Vector3(-25.6, 0.63, 51.2),   # 21: Estación 3 - Zona de Carga: 01 Banda de Descarga y Camión
	Vector3(-24.6, 0.63, 50.2),   # 22: Estación 4 - Zona de Carga: 02 Banda Inclinada hacia Tolva
	Vector3(-18.69, 0.63, 49.85), # 23: Regreso por plataforma segura frente a Puerta Doble Norte
	Vector3(-18.69, 0.83, 49.45), # 24: Umbral Puerta Doble Norte hacia pasillo peatonal verde
	Vector3(-18.69, 0.83, 46.6),  # 25: Estación 5 - 03 Tolva de Recepción T-301
	Vector3(-18.69, 0.83, 44.8),  # 26: Estación 6 - 04 Banda hacia Sinfín Trituradora
	Vector3(-18.69, 0.83, 43.1),  # 27: Estación 7 - 05 Tornillo Sin Fin Trituradora
	Vector3(-18.69, 0.83, 41.8),  # 28: Estación 8 - 06 Trituradora y Motor 10 HP
	Vector3(-18.69, 0.83, 40.3),  # 29: Estación 9 - 07 Tornillo Sin Fin al Secador
	Vector3(-18.69, 0.83, 38.5),  # 30: Estación 10 - CCM Tablero Eléctrico 460 V
	Vector3(-18.69, 0.83, 36.6),  # 31: Estación 11 - 08 Secador Rotatorio
	Vector3(-18.69, 0.83, 33.4),  # 32: Estación 12 - 09 Ciclón Separador
	Vector3(-18.69, 0.83, 29.4),  # 33: Estación 13 - 10 Ciclones Clasificadores (ATEX)
	Vector3(-18.69, 0.83, 26.5),  # 34: Estación 14 - Almacén de Sacos 50 kg
	Vector3(-18.69, 0.83, 22.2),  # 35: Salida Portón Sur hacia Rampa Sur
	Vector3(-20.3, 0.83, 22.2),   # 36: Cima Rampa Sur
	Vector3(-28.5, 0.04, 22.2),   # 37: Pie Rampa Sur
	Vector3(-36.5, 0.04, 22.2),   # 38: Estación 15 - 14 Intercambiador de Calor (vista abierta Sur)
	Vector3(-42.2, 0.04, 22.2),   # 39: Esquina exterior Sur-Oeste segura (fuera de Zone9 y lejos de camiones)
	Vector3(-44.2, 0.04, 28.0),   # 40: Corredor exterior Oeste con vista despejada sobre murete
	Vector3(-44.2, 0.04, 34.3),   # 41: Estación 16 - 12 Horno Térmico
	Vector3(-44.2, 0.04, 36.4),   # 42: Estación 17 - 11 Unidad de Extracción
	Vector3(-44.2, 0.04, 38.8),   # 43: Estación 18 - 13 Soplador
	Vector3(-43.2, 0.04, 40.8)    # 44: Estación 19 - 15 Ductos de Aire y Cierre Exterior
]

# Conversación natural con el Supervisor SST durante el recorrido (solo subtítulos, sin voz)
const SST_COMPANY_TOPICS: Array[Dictionary] = [
	{
		"id": "historia",
		"key_num": 6,
		"label": "Historia",
		"question": "¿Cómo empezó la historia de Agromolinos del Valle?",
		"beats": [
			"Nacimos hace más de quince años como un pequeño molino familiar fundado por productores locales de grano.",
			"Con el tiempo fuimos modernizando la planta con automatización, variadores de frecuencia y monitoreo predictivo, sin perder la cercanía con el campo."
		]
	},
	{
		"id": "actividad",
		"key_num": 7,
		"label": "Qué hacen",
		"question": "¿Qué hacen exactamente aquí en la planta?",
		"beats": [
			"Recibimos grano de fincas de la región, lo limpiamos, secamos y molemos en nuestra línea de 10 HP para obtener harinas y concentrados.",
			"Después clasificamos el material en los ciclones, lo empacamos en sacos de 50 kilos y lo despachamos directo a distribuidores."
		]
	},
	{
		"id": "mision",
		"key_num": 8,
		"label": "Misión",
		"question": "¿Cuál es la misión de la empresa?",
		"beats": [
			"Nuestra misión es transformar el grano regional en productos confiables mediante procesos seguros, eficientes y sostenibles.",
			"Buscamos generar valor para los agricultores y clientes, cuidando siempre la integridad de cada persona que trabaja aquí."
		]
	},
	{
		"id": "vision",
		"key_num": 9,
		"label": "Visión",
		"question": "¿Cuál es la visión de Agromolinos del Valle?",
		"beats": [
			"Queremos consolidarnos como la planta molinera referente en eficiencia energética e industria 4.0 de toda la región.",
			"La meta es seguir reduciendo el consumo eléctrico por tonelada y llevar nuestra operación inteligente a nuevos mercados."
		]
	}
]

const SST_SPEAKER_HEADER: String = "Carlos Mendoza (Supervisor SST):"

const STATION_NATURAL_SPEECH: Dictionary = {
	1: "Bienvenido a la portería. Cuando estés listo vamos avanzando hacia la planta.",
	2: "Ya estamos en los vestidores. Tu ropa y el equipo de protección están en los lockers verdes de enfrente.",
	3: "Empezamos aquí en la zona de carga. Los camiones descargan el grano sobre esta banda roja de entrada sin que crucemos la línea amarilla.",
	4: "Justo al lado está la banda verde inclinada. Ella sube todo el grano recibido hacia el interior de la nave rumbo a la tolva.",
	5: "Ya adentro, siempre por el pasillo peatonal verde, te muestro la tolva de recepción. Aquí se acumula y se dosifica el grano antes de moler.",
	6: "Esta banda transportadora verde toma el grano de la tolva y lo lleva de forma pareja hacia la entrada de la trituradora.",
	7: "Aquí tenemos el tornillo sin fin de alimentación, encargado de empujar el cereal de manera continua hacia la cámara de molienda.",
	8: "Este es el corazón de la planta: la trituradora con su motor trifásico de 10 caballos a 460 voltios. Siempre vigilamos su corriente, temperatura y vibración.",
	9: "Al salir molido, este segundo tornillo sin fin traslada el producto directamente hacia la entrada del secador rotatorio.",
	10: "Frente a ti está el tablero eléctrico CCM de 460 voltios y el variador de frecuencia. Recuerda nunca cruzar la línea roja ni tocarlo sin aplicar las cinco reglas de oro y LOTO.",
	11: "Aquí opera el secador rotatorio. Hace girar el grano con aire caliente para bajar la humedad y dejarlo en el punto exacto.",
	12: "Este es el ciclón separador principal. Aprovecha la fuerza centrífuga para separar el producto más grueso de las partículas finas.",
	13: "Estos dos ciclones amarillos clasifican el polvo fino de cereal. Como el polvo es combustible en zona ATEX, mantenemos siempre una buena ventilación.",
	14: "Aquí en el almacén vamos empacando el grano ya procesado en sacos de 50 kilos, listos para estibar y despachar.",
	15: "Ya salimos por la rampa sur al patio exterior, bien lejos de los camiones y fuera de la zona amarilla. Enfrente ves el intercambiador de calor que recupera energía térmica.",
	16: "A continuación está el horno térmico de ladrillos, que genera el flujo de aire caliente necesario para todo el proceso de secado.",
	17: "Esta es la unidad de extracción adosada a la pared, encargada de mantener la succión constante y evacuar el polvo fino hacia el exterior.",
	18: "Aquí tienes el soplador industrial. Impulsa el caudal de aire a presión que conecta el horno, el intercambiador y el secador.",
	19: "Por último, arriba ves la red de ductos de aire que enlaza todo el sistema térmico con la nave. Con esto terminamos el recorrido y ya puedes explorar o usar la tablet."
}

# Líneas de apertura de la conversación de historia en Portería (antes de entrar a la empresa)
const EXTERIOR_NARRATION_SEGMENTS: Array[Dictionary] = [
	{
		"min_progress": 0.0,
		"min_elapsed": 0.0,
		"speaker": "Carlos Mendoza (Supervisor SST):",
		"text": "Bienvenido a Agromolinos del Valle. Antes de entrar a la empresa, puedes preguntarme por nuestra historia, qué hacemos, nuestra misión o nuestra visión. Cuando quieras ingresar, elige Entrar a la empresa o presiona 0."
	}
]

const PORTERIA_CONTINUE_CHOICE: Dictionary = {
	"id": "__continue__",
	"key_num": 0,
	"label": "Entrar a la empresa"
}

const STATION_TO_ROUTE_IDX: Dictionary = {
	1: 0, 2: 16, 3: 21, 4: 22, 5: 25, 6: 26, 7: 27, 8: 28, 9: 29, 10: 30,
	11: 31, 12: 32, 13: 33, 14: 34, 15: 38, 16: 41, 17: 42, 18: 43, 19: 44
}

# Equipos destacados en cada estación durante la presentación del tutorial (una máquina por estación en glow azul parpadeante)
const STATION_GLOW_GROUPS: Dictionary = {
	1: [],
	2: ["locker"],
	3: ["banda_descarga"],
	4: ["banda_inclinada_tolva"],
	5: ["hopper"],
	6: ["banda_trituradora"],
	7: ["tornillo_trituradora"],
	8: ["motor"],
	9: ["tornillo_secador"],
	10: ["breaker"],
	11: ["secador_rotatorio"],
	12: ["ciclon_separador"],
	13: ["cyclone"],
	14: [],
	15: ["intercambiador_calor"],
	16: ["horno"],
	17: ["unidad_extraccion"],
	18: ["soplador"],
	19: ["ductos_aire"]
}
const ALL_EQUIPMENT_GLOW_GROUPS: Array[String] = [
	"banda_descarga", "banda_inclinada_tolva", "hopper", "banda_trituradora",
	"tornillo_trituradora", "motor", "tornillo_secador", "secador_rotatorio",
	"ciclon_separador", "cyclone", "unidad_extraccion", "horno",
	"soplador", "intercambiador_calor", "ductos_aire",
	"locker", "breaker"
]

const MEETING_ROOM_POS: Vector3 = Vector3(27.0, 0.41, 32.9)
const MEETING_COURSE_DESK_POS: Vector3 = Vector3(25.95, 1.08, 34.0)
const MEETING_COURSE_ROUTE: Array[Vector3] = [
	Vector3(48.0, 0.04, 34.0),
	Vector3(44.5, 0.04, 34.0),
	Vector3(43.0, 0.41, 34.0),
	Vector3(40.0, 0.41, 34.5),
	Vector3(39.5, 0.41, 34.5),
	Vector3(33.5, 0.41, 32.5),
	Vector3(29.5, 0.41, 33.5),
	Vector3(27.0, 0.41, 32.9)
]

var loto_controller = null
var epp_completed: bool = false
var visited_stations: Dictionary = {}
var current_station_idx: int = 1
var target_station_id: int = 2
var induction_certified: bool = false
var station_radius_m: float = 3.0

var _player_ref: Node3D = null
var _guide_worker: Node = null
var _welcome_shown: bool = false
var is_briefing_active: bool = false
var briefing_completed: bool = false
var _epp_reminder_cooldown: float = 0.0
var sst_course_chosen: bool = false
var sst_course_active: bool = false
var sst_course_completed: bool = false
var porteria_story_active: bool = false
var porteria_story_completed: bool = false
var _course_modal_auto_opened: bool = false
var _course_desk_node = null
var _guide_line_mesh_inst: MeshInstance3D = null
var _guide_imm_mesh: ImmediateMesh = null
var _line_refresh_timer: float = 0.0
var _line_settled: bool = false
var _prompted_station_id: int = -1
var tutorial_skipped: bool = false
var _narration_active: bool = false
var _narration_idx: int = -1
var _narration_elapsed: float = 0.0
var _narration_chime_player: AudioStreamPlayer = null
var _tts_voice_id: String = ""
var _conv_active_topic_id: String = ""
var _conv_beat_queue: Array[Dictionary] = []
var _conv_beat_timer: float = 0.0
var _conv_asked_topics: Array[String] = []
var _tour_machines_started: bool = false

func _ready() -> void:
	loto_controller = get_node_or_null("LotoGoldenRulesController")
	if loto_controller == null:
		loto_controller = LotoControllerScript.new()
		loto_controller.name = "LotoGoldenRulesController"
		add_child(loto_controller)

	_setup_floor_guide_line()

	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		if bus.has_signal("epp_state_changed") and not bus.epp_state_changed.is_connected(_on_epp_state_changed):
			bus.epp_state_changed.connect(_on_epp_state_changed)
		if bus.has_signal("golden_rules_completed") and not bus.golden_rules_completed.is_connected(_on_golden_rules_completed):
			bus.golden_rules_completed.connect(_on_golden_rules_completed)
		if bus.has_signal("sst_course_mode_selected") and not bus.sst_course_mode_selected.is_connected(_on_sst_course_mode_selected):
			bus.sst_course_mode_selected.connect(_on_sst_course_mode_selected)
		if bus.has_signal("sst_course_completed_event") and not bus.sst_course_completed_event.is_connected(_on_sst_course_completed_event):
			bus.sst_course_completed_event.connect(_on_sst_course_completed_event)

	_setup_course_desk_marker()

	if is_inside_tree():
		_player_ref = get_tree().root.find_child("PlayerOperator", true, false) as Node3D
		_guide_worker = get_tree().root.find_child("WorkerSafetyAuditor", true, false)
		call_deferred("_post_welcome_message")

func _setup_floor_guide_line() -> void:
	_guide_line_mesh_inst = get_node_or_null("TourFloorGuideLine") as MeshInstance3D
	if _guide_line_mesh_inst == null:
		_guide_line_mesh_inst = MeshInstance3D.new()
		_guide_line_mesh_inst.name = "TourFloorGuideLine"
		_guide_imm_mesh = ImmediateMesh.new()
		_guide_line_mesh_inst.mesh = _guide_imm_mesh
		_guide_line_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_guide_line_mesh_inst.material_override = mat
		add_child(_guide_line_mesh_inst)
	else:
		_guide_imm_mesh = _guide_line_mesh_inst.mesh as ImmediateMesh
		if _guide_imm_mesh == null:
			_guide_imm_mesh = ImmediateMesh.new()
			_guide_line_mesh_inst.mesh = _guide_imm_mesh
	_rebuild_floor_guide_line()

func _post_welcome_message() -> void:
	if _welcome_shown:
		return
	_welcome_shown = true
	visit_station(1)
	is_briefing_active = true
	_rebuild_floor_guide_line()
	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		if bus.has_signal("induction_briefing_closed") and not bus.induction_briefing_closed.is_connected(_on_briefing_closed):
			bus.induction_briefing_closed.connect(_on_briefing_closed)
		if bus.has_signal("induction_briefing_requested"):
			bus.induction_briefing_requested.emit(
				"Bienvenido a Agromolinos del Valle",
				"¿Deseas realizar el curso SST?",
				true
			)
		elif bus.has_signal("notification_posted"):
			bus.notification_posted.emit(
				"PORTERÍA",
				"Sigue al Inspector SST a Vestidores.",
				"info"
			)

func _setup_course_desk_marker() -> void:
	_course_desk_node = get_node_or_null("CourseDeskInteractable")
	if _course_desk_node == null:
		_course_desk_node = CourseDeskInteractable.new()
		_course_desk_node.name = "CourseDeskInteractable"
		add_child(_course_desk_node)
	_course_desk_node.position = MEETING_COURSE_DESK_POS
	_set_course_desk_active(false)

func _set_course_desk_active(active: bool) -> void:
	if _course_desk_node == null or not is_instance_valid(_course_desk_node):
		return
	if _course_desk_node.has_method("set_active"):
		_course_desk_node.set_active(active)
	else:
		_course_desk_node.visible = active

func _on_sst_course_mode_selected(start_course: bool) -> void:
	sst_course_chosen = start_course
	sst_course_active = false
	_course_modal_auto_opened = false
	_notify_glow_controller()

func _start_sst_course_walk() -> void:
	sst_course_active = true
	sst_course_completed = false
	_course_modal_auto_opened = false
	_set_course_desk_active(true)
	if _guide_worker != null and is_instance_valid(_guide_worker) and _guide_worker.has_method("set_guide_route"):
		var wps: Array[Vector3] = []
		for p in MEETING_COURSE_ROUTE:
			wps.append(p)
		_guide_worker.set_guide_route(wps, MEETING_ROOM_POS)
	_rebuild_floor_guide_line()

func _on_sst_course_completed_event(passed: bool, score: int, total: int) -> void:
	if not passed or sst_course_completed:
		return
	sst_course_completed = true
	sst_course_active = false
	_set_course_desk_active(false)
	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		if bus.has_signal("safety_bonus_awarded"):
			bus.safety_bonus_awarded.emit(
				"CURSO_RAPIDO_RETIE",
				"Curso SST y quiz aprobados: %d/%d." % [score, total],
				0.5
			)
		if bus.has_signal("notification_posted"):
			bus.notification_posted.emit(
				"Curso SST aprobado",
				"Sigue al supervisor hacia vestidores.",
				"success"
			)

	current_station_idx = 1
	target_station_id = 2
	if _guide_worker != null and is_instance_valid(_guide_worker) and _guide_worker.has_method("set_guide_route"):
		var wps: Array[Vector3] = []
		for idx in range(MEETING_COURSE_ROUTE.size() - 2, -1, -1):
			wps.append(MEETING_COURSE_ROUTE[idx])
		var vest_r_idx: int = int(STATION_TO_ROUTE_IDX.get(2, 16))
		for idx in range(2, vest_r_idx + 1):
			wps.append(TOUR_ROUTE_POINTS[idx])
		_guide_worker.set_guide_route(wps, TOUR_ROUTE_POINTS[vest_r_idx])
	var hud = get_tree().root.find_child("HUDController", true, false) if is_inside_tree() else null
	if hud != null and hud.has_method("show_npc_dialogue"):
		hud.show_npc_dialogue(
			SST_SPEAKER_HEADER,
			"Excelente trabajo en el curso. Ahora acompáñame a los vestidores para ponerte tu equipo de protección y empezar el recorrido por las máquinas desde la zona de carga.",
			7.0
		)
	_rebuild_floor_guide_line()

func _start_porteria_story() -> void:
	porteria_story_active = true
	porteria_story_completed = false
	_conv_asked_topics.clear()
	if _guide_worker != null and is_instance_valid(_guide_worker):
		_guide_worker.set("guide_has_target", false)
		_guide_worker.set("is_explaining", false)
		_guide_worker.set("has_arrived_and_explained", true)
	_start_exterior_narration()
	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("notification_posted"):
		bus.notification_posted.emit(
			"Portería",
			"Conoce la empresa o entra cuando estés listo.",
			"info"
		)
	_notify_glow_controller()

func finish_porteria_story_and_enter() -> void:
	if not porteria_story_active and porteria_story_completed:
		return
	porteria_story_active = false
	porteria_story_completed = true
	_stop_exterior_narration()
	var bus = get_node_or_null("/root/EventBus")
	var hud = get_tree().root.find_child("HUDController", true, false) if is_inside_tree() else null
	if sst_course_chosen and not sst_course_completed:
		_start_sst_course_walk()
		if hud != null and hud.has_method("show_npc_dialogue"):
			hud.show_npc_dialogue(
				SST_SPEAKER_HEADER,
				"Perfecto, acompáñame. Entremos a la empresa abriendo las puertas hacia la sala de reuniones para hacer el curso SST.",
				6.5
			)
		if bus != null and bus.has_signal("notification_posted"):
			bus.notification_posted.emit(
				"Curso SST",
				"Sigue al supervisor a la sala de reuniones.",
				"info"
			)
	else:
		_advance_tour_target(2)
		if hud != null and hud.has_method("show_npc_dialogue"):
			hud.show_npc_dialogue(
				SST_SPEAKER_HEADER,
				"Perfecto, acompáñame hacia los vestidores para ponerte tu equipo de protección y empezar el recorrido por las máquinas.",
				6.5
			)
		if bus != null and bus.has_signal("notification_posted"):
			bus.notification_posted.emit(
				"Recorrido guiado",
				"Sigue al supervisor hacia vestidores.",
				"info"
			)
	_notify_glow_controller()

func _on_briefing_closed(resume_tour_on_close: bool) -> void:
	is_briefing_active = false
	if resume_tour_on_close and not briefing_completed:
		briefing_completed = true
		_start_porteria_story()
	_notify_glow_controller()

func complete_initial_briefing() -> void:
	_on_briefing_closed(true)

func _process(delta: float) -> void:
	if _epp_reminder_cooldown > 0.0:
		_epp_reminder_cooldown -= delta

	if _player_ref == null or not is_instance_valid(_player_ref):
		return

	_update_exterior_narration(delta)

	if not _line_settled:
		_line_refresh_timer += delta
		if _line_refresh_timer >= 0.25:
			_line_settled = true
			_rebuild_floor_guide_line()

	var p_pos: Vector3 = _player_ref.global_position
	if sst_course_active and not sst_course_completed:
		var flat_m := Vector2(p_pos.x - MEETING_ROOM_POS.x, p_pos.z - MEETING_ROOM_POS.z).length()
		var dy_m := absf(p_pos.y - MEETING_ROOM_POS.y)
		var g_arrived := (
			_guide_worker == null
			or not is_instance_valid(_guide_worker)
			or (
				not bool(_guide_worker.get("guide_has_target"))
				and Vector2(_guide_worker.global_position.x - MEETING_ROOM_POS.x, _guide_worker.global_position.z - MEETING_ROOM_POS.z).length() <= 2.6
			)
		)
		if not _course_modal_auto_opened and g_arrived and flat_m <= 2.5 and dy_m <= 0.45:
			_course_modal_auto_opened = true
			var bus_m = get_node_or_null("/root/EventBus")
			if bus_m != null and bus_m.has_signal("sst_course_modal_requested"):
				bus_m.sst_course_modal_requested.emit()
		return

	if target_station_id >= 1 and target_station_id <= STATIONS.size():
		var st: Dictionary = STATIONS[target_station_id - 1]
		if not visited_stations.get(target_station_id, false):
			var st_pos: Vector3 = st["pos"]
			var guide_arrived: bool = (
				_guide_worker == null
				or not is_instance_valid(_guide_worker)
				or (
					not bool(_guide_worker.get("guide_has_target"))
					and not bool(_guide_worker.get("is_explaining"))
					and Vector2(_guide_worker.global_position.x - st_pos.x, _guide_worker.global_position.z - st_pos.z).length() <= 2.4
				)
			)
			var flat_dist := Vector2(p_pos.x - st_pos.x, p_pos.z - st_pos.z).length()
			var dy := absf(p_pos.y - st_pos.y)
			var req_radius := 2.0 if target_station_id == 2 else 3.1
			if guide_arrived and flat_dist <= req_radius and dy <= 0.45:
				if target_station_id >= 3 and not epp_completed:
					if _epp_reminder_cooldown <= 0.0:
						_epp_reminder_cooldown = 5.0
						var bus = get_node_or_null("/root/EventBus")
						if bus != null and bus.has_signal("notification_posted"):
							bus.notification_posted.emit(
								"EPP obligatorio",
								"Equipa tu protección en vestidores.",
								"warning"
							)
				elif target_station_id == 2:
					visit_station(2)
				elif _prompted_station_id != target_station_id:
					# En estaciones 3..12 exigir [E] del jugador para pasar a la siguiente estación
					_prompted_station_id = target_station_id
					var hud = get_tree().root.find_child("HUDController", true, false)
					if hud != null and hud.has_method("show_npc_dialogue"):
						var action_hint := "Cuando quieras, presiona E para seguir." if target_station_id < STATIONS.size() else "Presiona E para cerrar el recorrido."
						hud.show_npc_dialogue(SST_SPEAKER_HEADER, "%s %s" % [get_station_natural_speech(target_station_id), action_hint], 10.0)

func get_station_natural_speech(station_id: int) -> String:
	return str(STATION_NATURAL_SPEECH.get(station_id, "Seguimos recorriendo la planta con calma y precaución."))

func is_ready_for_interact_advance() -> bool:
	if is_briefing_active or not briefing_completed or not epp_completed:
		return false
	if target_station_id < 3 or target_station_id > STATIONS.size():
		return false
	if visited_stations.get(target_station_id, false):
		return false
	if _guide_worker != null and is_instance_valid(_guide_worker):
		if bool(_guide_worker.get("guide_has_target")) or bool(_guide_worker.get("is_explaining")):
			return false
	if _player_ref == null or not is_instance_valid(_player_ref):
		return false
	var st_pos: Vector3 = STATIONS[target_station_id - 1]["pos"]
	var p_pos: Vector3 = _player_ref.global_position
	var near_station := Vector2(p_pos.x - st_pos.x, p_pos.z - st_pos.z).length() <= 3.2 and absf(p_pos.y - st_pos.y) <= 0.55
	var near_guide := (
		_guide_worker != null
		and is_instance_valid(_guide_worker)
		and Vector2(p_pos.x - _guide_worker.global_position.x, p_pos.z - _guide_worker.global_position.z).length() <= 3.2
	)
	return near_station or near_guide

func is_ready_for_meeting_course() -> bool:
	if not sst_course_active or sst_course_completed:
		return false
	if _player_ref == null or not is_instance_valid(_player_ref):
		return false
	var p_pos: Vector3 = _player_ref.global_position
	return Vector2(p_pos.x - MEETING_ROOM_POS.x, p_pos.z - MEETING_ROOM_POS.z).length() <= 4.2 and absf(p_pos.y - MEETING_ROOM_POS.y) <= 0.55

func get_interact_advance_prompt() -> String:
	if porteria_story_active and not is_briefing_active:
		return "Entrar a la empresa"
	if is_ready_for_meeting_course():
		return "Abrir curso SST"
	if not is_ready_for_interact_advance():
		return ""
	if target_station_id < STATIONS.size():
		return "Siguiente estación"
	return "Finalizar recorrido"

func try_advance_station_by_interact() -> String:
	if porteria_story_active and not is_briefing_active:
		finish_porteria_story_and_enter()
		return "Ingresando a Agromolinos del Valle."
	if is_ready_for_meeting_course():
		var bus_m = get_node_or_null("/root/EventBus")
		if bus_m != null and bus_m.has_signal("sst_course_modal_requested"):
			bus_m.sst_course_modal_requested.emit()
		return "Abriendo Curso SST."
	if not is_ready_for_interact_advance():
		return ""
	var completed_id := target_station_id
	visit_station(completed_id)
	var hud = get_tree().root.find_child("HUDController", true, false) if is_inside_tree() else null
	if completed_id < STATIONS.size():
		var next_st: Dictionary = STATIONS[target_station_id - 1]
		var next_clean: String = str(next_st["title"]).split(": ")[-1]
		var reply := "Vamos hacia %s, sígueme." % next_clean
		if hud != null and hud.has_method("show_npc_dialogue"):
			hud.show_npc_dialogue(SST_SPEAKER_HEADER, reply, 4.5)
		return reply
	_check_tour_completion()
	var finish_msg := "Listo, terminamos el recorrido y las máquinas ya están operando. Puedes abrir la tablet cuando quieras."
	if hud != null and hud.has_method("show_npc_dialogue"):
		hud.show_npc_dialogue(SST_SPEAKER_HEADER, finish_msg, 6.5)
	return finish_msg

func _on_epp_state_changed(all_equipped: bool, _items: Dictionary) -> void:
	epp_completed = all_equipped
	if all_equipped:
		visit_station(2)
		_advance_tour_target(3)
	_notify_glow_controller()

func _on_golden_rules_completed() -> void:
	if epp_completed:
		visit_station(CCM_STATION_ID)

func can_advance_past_lockers() -> bool:
	return epp_completed

func execute_loto_rule(rule_num: int) -> Dictionary:
	if loto_controller == null:
		return {"ok": false, "message": "Controlador LOTO no inicializado."}
	return loto_controller.execute_rule(rule_num)

func is_loto_complete() -> bool:
	return loto_controller != null and loto_controller.is_loto_complete()

func visit_station(station_id: int) -> Dictionary:
	if station_id < 1 or station_id > STATIONS.size():
		return {}
	if station_id >= 3 and not epp_completed:
		return {}

	var st: Dictionary = STATIONS[station_id - 1]
	var first_time: bool = not visited_stations.get(station_id, false)
	visited_stations[station_id] = true
	current_station_idx = maxi(current_station_idx, station_id)

	if first_time:
		var bus = get_node_or_null("/root/EventBus")
		if bus != null:
			if bus.has_signal("tutorial_station_reached"):
				bus.tutorial_station_reached.emit(station_id, st["title"])
			if station_id > 1 and bus.has_signal("notification_posted"):
				bus.notification_posted.emit(st["title"], st["desc"], "info")

	if station_id == target_station_id:
		if station_id == 2 and not epp_completed:
			_rebuild_floor_guide_line()
			return st
		var next_id := _find_next_unvisited_station()
		if next_id > 0:
			_advance_tour_target(next_id)

	if visited_stations.size() >= STATIONS.size() and epp_completed and is_loto_complete() and not induction_certified:
		induction_certified = true
		var bus2 = get_node_or_null("/root/EventBus")
		if bus2 != null and bus2.has_signal("safety_bonus_awarded"):
			bus2.safety_bonus_awarded.emit("INDUCCION_12_ESTACIONES", "Recorrido completo de las 12 estaciones certificado.", 0.5)

	if station_id >= 2 and _narration_active:
		_stop_exterior_narration()

	_check_tour_completion()
	_rebuild_floor_guide_line()
	_notify_glow_controller()
	return st

func _find_next_unvisited_station() -> int:
	if not epp_completed and not visited_stations.get(2, false):
		return 2
	for st in STATIONS:
		var sid: int = st["id"]
		if not visited_stations.get(sid, false):
			return sid
	return -1

func _advance_tour_target(next_id: int) -> void:
	target_station_id = next_id
	if not epp_completed and next_id > 2:
		target_station_id = 2

	if _guide_worker != null and is_instance_valid(_guide_worker) and _guide_worker.has_method("set_guide_route"):
		var target_r_idx: int = int(STATION_TO_ROUTE_IDX.get(target_station_id, 16))
		var curr_r_idx: int = int(STATION_TO_ROUTE_IDX.get(current_station_idx, 0))
		var wps: Array[Vector3] = []
		if curr_r_idx <= target_r_idx:
			for idx in range(curr_r_idx + 1, target_r_idx + 1):
				wps.append(TOUR_ROUTE_POINTS[idx])
		else:
			for idx in range(curr_r_idx - 1, target_r_idx - 1, -1):
				wps.append(TOUR_ROUTE_POINTS[idx])
		var final_pt: Vector3 = TOUR_ROUTE_POINTS[target_r_idx]
		if wps.is_empty():
			wps.append(final_pt)
		_guide_worker.set_guide_route(wps, final_pt)

	_rebuild_floor_guide_line()
	_notify_glow_controller()

func _rebuild_floor_guide_line() -> void:
	if _guide_imm_mesh == null:
		return
	_guide_imm_mesh.clear_surfaces()
	if _guide_line_mesh_inst != null:
		_guide_line_mesh_inst.visible = not tutorial_skipped and not induction_certified
	if tutorial_skipped or induction_certified:
		return

	# Sin línea azul en suelo: únicamente chevrons verdes del paso activo y aro ámbar en destino
	var active_color := Color(0.16, 0.94, 0.42, 0.88)
	var ring_color := Color(1.0, 0.84, 0.14, 0.95)
	var ray_ctx := _get_guide_ray_context()

	_guide_imm_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Segmento activo y flechas chevron siguiendo pasillos/exterior (sin trazo azul global en suelo)
	if sst_course_active and not sst_course_completed:
		var course_col := Color(0.20, 0.94, 0.45, 0.92)
		_append_ribbon_segment(TOUR_ROUTE_POINTS[0], MEETING_COURSE_ROUTE[0], 0.22, course_col, ray_ctx)
		_append_chevrons_on_segment(TOUR_ROUTE_POINTS[0], MEETING_COURSE_ROUTE[0], course_col, ray_ctx)
		for i in range(MEETING_COURSE_ROUTE.size() - 1):
			_append_ribbon_segment(MEETING_COURSE_ROUTE[i], MEETING_COURSE_ROUTE[i + 1], 0.22, course_col, ray_ctx)
			_append_chevrons_on_segment(MEETING_COURSE_ROUTE[i], MEETING_COURSE_ROUTE[i + 1], course_col, ray_ctx)
		var m_ring := MEETING_ROOM_POS
		m_ring.y = _sample_floor_y(m_ring, ray_ctx)
		_append_target_ring(m_ring, 0.82, 1.05, Color(0.28, 0.98, 0.78, 0.95), ray_ctx)
		_guide_imm_mesh.surface_end()
		return

	if sst_course_completed and target_station_id == 2 and not epp_completed:
		for i in range(MEETING_COURSE_ROUTE.size() - 1, 0, -1):
			_append_ribbon_segment(MEETING_COURSE_ROUTE[i], MEETING_COURSE_ROUTE[i - 1], 0.20, active_color, ray_ctx)
			_append_chevrons_on_segment(MEETING_COURSE_ROUTE[i], MEETING_COURSE_ROUTE[i - 1], active_color, ray_ctx)

	var target_r_idx: int = int(STATION_TO_ROUTE_IDX.get(target_station_id, 16))
	var curr_r_idx: int = int(STATION_TO_ROUTE_IDX.get(current_station_idx, 0))
	if curr_r_idx < target_r_idx:
		for i in range(curr_r_idx, mini(target_r_idx, TOUR_ROUTE_POINTS.size() - 1)):
			_append_ribbon_segment(TOUR_ROUTE_POINTS[i], TOUR_ROUTE_POINTS[i + 1], 0.20, active_color, ray_ctx)
			_append_chevrons_on_segment(TOUR_ROUTE_POINTS[i], TOUR_ROUTE_POINTS[i + 1], active_color, ray_ctx)
	elif curr_r_idx > target_r_idx:
		for i in range(curr_r_idx, maxi(target_r_idx, 0), -1):
			_append_ribbon_segment(TOUR_ROUTE_POINTS[i], TOUR_ROUTE_POINTS[i - 1], 0.20, active_color, ray_ctx)
			_append_chevrons_on_segment(TOUR_ROUTE_POINTS[i], TOUR_ROUTE_POINTS[i - 1], active_color, ray_ctx)

	# 3. Anillo luminoso en la estación destino actual (recortado si algún muro o equipo está cerca)
	if target_station_id >= 1 and target_station_id <= STATIONS.size():
		var t_pos: Vector3 = STATIONS[target_station_id - 1]["pos"]
		t_pos.y = _sample_floor_y(t_pos, ray_ctx)
		_append_target_ring(t_pos, 0.82, 1.05, ring_color, ray_ctx)

	_guide_imm_mesh.surface_end()

func _get_guide_ray_context() -> Dictionary:
	var space: PhysicsDirectSpaceState3D = (
		get_world_3d().direct_space_state
		if is_inside_tree() and get_world_3d() != null
		else null
	)
	var exclude: Array[RID] = []
	if space != null and is_inside_tree():
		if _player_ref is CollisionObject3D:
			exclude.append((_player_ref as CollisionObject3D).get_rid())
		for wk in get_tree().get_nodes_in_group("workers"):
			if wk is CollisionObject3D:
				exclude.append((wk as CollisionObject3D).get_rid())
	return {"space": space, "exclude": exclude}

func _sample_floor_y(pt: Vector3, ray_ctx: Dictionary) -> float:
	var space: PhysicsDirectSpaceState3D = ray_ctx.get("space", null)
	if space == null:
		return pt.y
	var exclude: Array[RID] = ray_ctx.get("exclude", [])
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(pt.x, pt.y + 0.55, pt.z),
		Vector3(pt.x, pt.y - 0.35, pt.z),
		1,
		exclude
	)
	var hit: Dictionary = space.intersect_ray(q)
	if not hit.is_empty() and float(hit["normal"].y) >= 0.70:
		return maxf(pt.y, float(hit["position"].y) + 0.045)
	return pt.y

func _append_ribbon_segment(p0: Vector3, p1: Vector3, half_w: float, col: Color, ray_ctx: Dictionary) -> void:
	var flat_dir := Vector3(p1.x - p0.x, 0.0, p1.z - p0.z)
	var flat_len := flat_dir.length()
	if flat_len < 0.05:
		return
	var fwd := flat_dir.normalized()
	var side := Vector3(-fwd.z, 0.0, fwd.x) * half_w
	var space: PhysicsDirectSpaceState3D = ray_ctx.get("space", null)
	var steps: int = clampi(int(ceil(flat_len / 0.75)), 1, 24) if space != null else 1

	var prev := p0
	prev.y = _sample_floor_y(prev, ray_ctx)
	for s in range(1, steps + 1):
		var curr: Vector3 = p0.lerp(p1, float(s) / float(steps))
		curr.y = _sample_floor_y(curr, ray_ctx)
		var v0 := prev - side
		var v1 := prev + side
		var v2 := curr + side
		var v3 := curr - side
		_add_tri(v0, v1, v2, col)
		_add_tri(v0, v2, v3, col)
		prev = curr

func _append_chevrons_on_segment(p0: Vector3, p1: Vector3, col: Color, ray_ctx: Dictionary) -> void:
	var vec := p1 - p0
	var flat_len := Vector2(vec.x, vec.z).length()
	if flat_len < 1.2:
		return
	var dir_3d := vec.normalized()
	var flat_fwd := Vector3(vec.x, 0.0, vec.z).normalized()
	var side := Vector3(-flat_fwd.z, 0.0, flat_fwd.x)
	var step: float = 2.4
	var d: float = 1.1
	while d < flat_len - 0.6:
		var c: Vector3 = p0 + dir_3d * d
		c.y = _sample_floor_y(c, ray_ctx) + 0.015
		var tip := c + flat_fwd * 0.46
		var left := c - flat_fwd * 0.20 - side * 0.32
		var right := c - flat_fwd * 0.20 + side * 0.32
		_add_tri(tip, right, left, col)
		d += step

func _append_target_ring(center: Vector3, r_in: float, r_out: float, col: Color, ray_ctx: Dictionary) -> void:
	# Anillo circular uniforme: calcula holgura radial mínima sin deformar el círculo en polígonos irregulares
	var probe_dirs: int = 16
	var space: PhysicsDirectSpaceState3D = ray_ctx.get("space", null)
	var exclude: Array[RID] = ray_ctx.get("exclude", [])
	var min_clear: float = r_out
	if space != null:
		var from_p := center + Vector3(0.0, 0.40, 0.0)
		for i in range(probe_dirs):
			var a: float = (float(i) / float(probe_dirs)) * TAU
			var dir := Vector3(cos(a), 0.0, sin(a))
			var q := PhysicsRayQueryParameters3D.create(from_p, from_p + dir * (r_out + 0.14), 1, exclude)
			var h: Dictionary = space.intersect_ray(q)
			if not h.is_empty() and h["normal"].y < 0.78:
				var hit_dist := from_p.distance_to(h["position"]) - 0.10
				min_clear = minf(min_clear, hit_dist)

	var safe_out: float = clampf(min_clear, 0.45, r_out)
	var ring_thick: float = clampf(r_out - r_in, 0.12, safe_out * 0.34)
	var safe_in: float = maxf(0.24, safe_out - ring_thick)
	var segs: int = 28
	for i in range(segs):
		var a0: float = (float(i) / float(segs)) * TAU
		var a1: float = (float(i + 1) / float(segs)) * TAU
		var p_in0 := center + Vector3(cos(a0) * safe_in, 0.0, sin(a0) * safe_in)
		var p_out0 := center + Vector3(cos(a0) * safe_out, 0.0, sin(a0) * safe_out)
		var p_out1 := center + Vector3(cos(a1) * safe_out, 0.0, sin(a1) * safe_out)
		var p_in1 := center + Vector3(cos(a1) * safe_in, 0.0, sin(a1) * safe_in)
		_add_tri(p_in0, p_out0, p_out1, col)
		_add_tri(p_in0, p_out1, p_in1, col)

func _add_tri(a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	_guide_imm_mesh.surface_set_color(col)
	_guide_imm_mesh.surface_add_vertex(a)
	_guide_imm_mesh.surface_set_color(col)
	_guide_imm_mesh.surface_add_vertex(b)
	_guide_imm_mesh.surface_set_color(col)
	_guide_imm_mesh.surface_add_vertex(c)

func is_tutorial_glow_unlocked() -> bool:
	return tutorial_skipped or induction_certified or bool(visited_stations.get(STATIONS.size(), false))

func is_tour_completed() -> bool:
	return is_tutorial_glow_unlocked()

func _check_tour_completion() -> void:
	if is_tour_completed() and not _tour_machines_started:
		_tour_machines_started = true
		_start_plant_machines_after_tour()

func _start_plant_machines_after_tour() -> void:
	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		if bus.has_signal("tutorial_completed"):
			bus.tutorial_completed.emit()
		if bus.has_signal("plant_production_started"):
			bus.plant_production_started.emit()
	var sm = get_node_or_null("/root/SimulationManager")
	if sm != null and sm.has_method("start_plant_machines"):
		sm.start_plant_machines()

func load_previous_checkpoint() -> Dictionary:
	if _player_ref == null or not is_instance_valid(_player_ref):
		if is_inside_tree():
			_player_ref = get_tree().root.find_child("PlayerOperator", true, false) as Node3D

	var prev_id := 1
	if target_station_id > 1:
		prev_id = target_station_id - 1
	elif current_station_idx > 1:
		prev_id = current_station_idx - 1

	var prev_st: Dictionary = STATIONS[clampi(prev_id - 1, 0, STATIONS.size() - 1)]
	var prev_pos: Vector3 = prev_st["pos"]

	if _player_ref != null and is_instance_valid(_player_ref):
		_player_ref.global_position = Vector3(prev_pos.x, prev_pos.y + 0.15, prev_pos.z)
		if "velocity" in _player_ref:
			_player_ref.velocity = Vector3.ZERO

	target_station_id = prev_id
	_prompted_station_id = -1
	_rebuild_floor_guide_line()
	_notify_glow_controller()

	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("notification_posted"):
		bus.notification_posted.emit(
			"Punto anterior",
			"%s" % prev_st["title"],
			"info"
		)
	return prev_st

func get_active_tutorial_glow_groups() -> Array[String]:
	var epp_active: bool = epp_completed
	if not epp_active and is_inside_tree():
		var lk := get_tree().root.find_child("LockerEPPStation", true, false)
		if lk != null and is_instance_valid(lk):
			var v = lk.get("epp_equipped")
			if v is bool and v:
				epp_active = true
	if is_tutorial_glow_unlocked():
		var groups := ALL_EQUIPMENT_GLOW_GROUPS.duplicate()
		if epp_active and groups.has("locker"):
			groups.erase("locker")
		return groups
	if is_briefing_active or not briefing_completed or sst_course_active:
		return []
	var out: Array[String] = []
	var raw = STATION_GLOW_GROUPS.get(target_station_id, [])
	if raw is Array:
		for g in raw:
			var s := str(g)
			if s == "locker" and epp_active:
				continue
			out.append(s)
	return out

func _notify_glow_controller() -> void:
	if not is_inside_tree():
		return
	var glow := get_tree().root.find_child("InteractableGlowController", true, false)
	if glow != null and glow.has_method("refresh_highlights"):
		glow.call_deferred("refresh_highlights", false)

func get_visited_count() -> int:
	return visited_stations.size()

func get_progress_pct() -> float:
	return (float(visited_stations.size()) / float(STATIONS.size())) * 100.0

func get_state_summary() -> Dictionary:
	return {
		"epp_completed": epp_completed,
		"loto_step": loto_controller.get_current_step() if loto_controller != null else 0,
		"loto_completed": is_loto_complete(),
		"stations_visited": visited_stations.size(),
		"total_stations": STATIONS.size(),
		"progress_pct": get_progress_pct(),
		"induction_certified": induction_certified,
		"tutorial_skipped": tutorial_skipped,
		"target_station_id": target_station_id,
		"sst_course_chosen": sst_course_chosen,
		"sst_course_active": sst_course_active,
		"sst_course_completed": sst_course_completed,
		"porteria_story_active": porteria_story_active,
		"porteria_story_completed": porteria_story_completed,
		"narration_active": _narration_active,
		"narration_segment": _narration_idx + 1
	}

func skip_tutorial_to_final_station() -> Dictionary:
	_stop_exterior_narration()
	tutorial_skipped = true
	is_briefing_active = false
	briefing_completed = true
	porteria_story_active = false
	porteria_story_completed = true
	sst_course_active = false
	_course_modal_auto_opened = true
	_prompted_station_id = -1
	_set_course_desk_active(false)

	var r_root := get_tree().root if is_inside_tree() else null
	if r_root != null:
		var locker := r_root.find_child("LockerEPPStation", true, false)
		if locker != null and locker.has_method("set_epp_equipped"):
			locker.set_epp_equipped(true)
	epp_completed = true

	for sid in range(1, STATIONS.size()):
		visited_stations[sid] = true
	current_station_idx = STATIONS.size()
	target_station_id = STATIONS.size()

	var final_st: Dictionary = STATIONS[STATIONS.size() - 1]
	var final_pos: Vector3 = TOUR_ROUTE_POINTS[TOUR_ROUTE_POINTS.size() - 1]
	if _player_ref != null and is_instance_valid(_player_ref):
		_player_ref.global_position = Vector3(final_pos.x, final_pos.y + 0.05, final_pos.z)
		if "velocity" in _player_ref:
			_player_ref.velocity = Vector3.ZERO
	if _guide_worker != null and is_instance_valid(_guide_worker):
		_guide_worker.global_position = Vector3(final_pos.x, final_pos.y + 0.02, final_pos.z - 1.5)
		_guide_worker.set("guide_has_target", false)
		_guide_worker.set("is_explaining", false)
		_guide_worker.set("has_arrived_and_explained", true)

	_rebuild_floor_guide_line()
	_notify_glow_controller()
	if r_root != null:
		var glow_n := r_root.find_child("InteractableGlowController", true, false)
		if glow_n != null and glow_n.has_method("set_hovered_machine_group"):
			glow_n.set_hovered_machine_group("")
			glow_n.refresh_highlights(true)

	var hud = r_root.find_child("HUDController", true, false) if r_root != null else null
	if hud != null:
		if hud.has_method("close_briefing_panel"):
			hud.close_briefing_panel()
		var c_modal = hud.get("_course_modal")
		if c_modal != null and is_instance_valid(c_modal) and c_modal.visible:
			c_modal.visible = false
			if is_inside_tree():
				get_tree().paused = false
		if hud.has_method("refresh_skip_button_visibility"):
			hud.refresh_skip_button_visibility()
		if hud.has_method("show_npc_dialogue"):
			hud.show_npc_dialogue(
				SST_SPEAKER_HEADER,
				"Listo, ya tienes tu equipo puesto y la planta está en marcha. Puedes recorrerla libremente o abrir la tablet para monitorear todo.",
				6.0
			)

	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		if bus.has_signal("tutorial_station_reached"):
			bus.tutorial_station_reached.emit(STATIONS.size(), final_st["title"])
		if bus.has_signal("notification_posted"):
			bus.notification_posted.emit(
				"Recorrido completado",
				"EPP equipado. Planta en marcha.",
				"success"
			)

	_check_tour_completion()
	return get_state_summary()

func _start_exterior_narration() -> void:
	if tutorial_skipped or epp_completed:
		return
	_narration_active = true
	_narration_idx = -1
	_narration_elapsed = 0.0
	_conv_active_topic_id = ""
	_conv_beat_queue.clear()
	_conv_beat_timer = 0.0
	_select_spanish_tts_voice()
	_play_narration_segment(0)
	_sync_conversation_choices_ui()

func _stop_exterior_narration() -> void:
	_narration_active = false
	_conv_active_topic_id = ""
	_conv_beat_queue.clear()
	_conv_beat_timer = 0.0
	var hud = get_tree().root.find_child("HUDController", true, false) if is_inside_tree() else null
	if hud != null and hud.has_method("clear_dialogue_choices"):
		hud.clear_dialogue_choices()

func _select_spanish_tts_voice() -> void:
	# Voz hablada desactivada: únicamente subtítulos en pantalla
	_tts_voice_id = ""

func _sync_conversation_choices_ui() -> void:
	if not is_inside_tree():
		return
	var hud = get_tree().root.find_child("HUDController", true, false)
	if hud == null or not hud.has_method("set_dialogue_choices"):
		return
	if not _narration_active or tutorial_skipped or epp_completed:
		if hud.has_method("clear_dialogue_choices"):
			hud.clear_dialogue_choices()
		return
	var opts: Array = []
	for t in SST_COMPANY_TOPICS:
		opts.append(t)
	opts.append(PORTERIA_CONTINUE_CHOICE)
	hud.set_dialogue_choices(
		opts,
		_conv_active_topic_id,
		_conv_asked_topics,
		Callable(self, "select_company_topic")
	)

func select_company_topic(topic_id: String) -> bool:
	if topic_id == "__continue__":
		if porteria_story_active or _narration_active:
			finish_porteria_story_and_enter()
			return true
		return false
	if not _narration_active or tutorial_skipped or epp_completed:
		return false
	var chosen: Dictionary = {}
	for t in SST_COMPANY_TOPICS:
		if str(t.get("id", "")) == topic_id:
			chosen = t
			break
	if chosen.is_empty():
		return false

	_conv_active_topic_id = topic_id
	if not _conv_asked_topics.has(topic_id):
		_conv_asked_topics.append(topic_id)

	_conv_beat_queue.clear()
	_conv_beat_queue.append({
		"speaker": "Tú:",
		"text": str(chosen.get("question", "")),
		"dur": 2.4
	})
	var beats: Array = chosen.get("beats", [])
	for b_txt in beats:
		_conv_beat_queue.append({
			"speaker": SST_SPEAKER_HEADER,
			"text": str(b_txt),
			"dur": 5.8
		})
	if _conv_asked_topics.size() >= SST_COMPANY_TOPICS.size():
		_conv_beat_queue.append({
			"speaker": SST_SPEAKER_HEADER,
			"text": "Ya conoces bien quiénes somos en Agromolinos del Valle. Cuando estés listo, elige Entrar a la empresa o presiona 0.",
			"dur": 5.0
		})
	_advance_conversation_beat()
	_sync_conversation_choices_ui()
	return true

func _advance_conversation_beat() -> void:
	if _conv_beat_queue.is_empty():
		_conv_active_topic_id = ""
		_conv_beat_timer = 0.0
		_sync_conversation_choices_ui()
		return
	var beat: Dictionary = _conv_beat_queue.pop_front()
	var dur: float = float(beat.get("dur", 5.5))
	_conv_beat_timer = dur
	var hud = get_tree().root.find_child("HUDController", true, false) if is_inside_tree() else null
	if hud != null and hud.has_method("show_npc_dialogue"):
		hud.show_npc_dialogue(str(beat.get("speaker", SST_SPEAKER_HEADER)), str(beat.get("text", "")), dur + 1.0)

func _compute_exterior_walk_progress() -> float:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return 0.0
	var p: Vector3 = _player_ref.global_position
	if p.z < 46.0 and p.x > 30.0:
		return clampf((p.z - 34.0) / 20.0 * 0.25, 0.0, 0.25)
	if p.z >= 46.0:
		return clampf(0.25 + ((48.0 - p.x) / 62.5) * 0.75, 0.25, 1.0)
	return clampf((48.0 - p.x) / 66.0, 0.0, 1.0)

func _update_exterior_narration(delta: float) -> void:
	if not _narration_active:
		return
	if tutorial_skipped or epp_completed or (not sst_course_active and target_station_id != 2):
		_stop_exterior_narration()
		return
	if sst_course_active and _course_modal_auto_opened:
		_stop_exterior_narration()
		return
	_narration_elapsed += delta
	if _conv_beat_timer > 0.0:
		_conv_beat_timer -= delta
		if _conv_beat_timer <= 0.0:
			_advance_conversation_beat()

func _play_narration_segment(idx: int) -> void:
	if idx < 0 or idx >= EXTERIOR_NARRATION_SEGMENTS.size():
		return
	_narration_idx = idx
	var seg: Dictionary = EXTERIOR_NARRATION_SEGMENTS[idx]
	var speaker: String = str(seg["speaker"])
	var text: String = str(seg["text"])
	var hud = get_tree().root.find_child("HUDController", true, false) if is_inside_tree() else null
	if hud != null and hud.has_method("show_npc_dialogue"):
		hud.show_npc_dialogue(speaker, text, 14.0)

func _exit_tree() -> void:
	if _narration_chime_player != null and is_instance_valid(_narration_chime_player):
		_narration_chime_player.stop()
		_narration_chime_player.stream = null

class CourseDeskInteractable extends StaticBody3D:
	var _shape: CollisionShape3D = null
	var _lbl: Label3D = null

	func _ready() -> void:
		add_to_group("interactable")
		collision_layer = 1
		collision_mask = 0
		_shape = CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.2, 0.48, 1.4)
		_shape.shape = box
		add_child(_shape)

		_lbl = Label3D.new()
		_lbl.text = "Curso SST"
		_lbl.position = Vector3(0.0, 0.22, 0.0)
		_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_lbl.font_size = 15
		_lbl.pixel_size = 0.0012
		_lbl.modulate = Color(0.28, 0.96, 0.78, 0.90)
		_lbl.outline_size = 2
		add_child(_lbl)

	func set_active(active: bool) -> void:
		visible = active
		collision_layer = 1 if active else 0
		if _shape != null:
			_shape.disabled = not active

	func get_interact_prompt() -> String:
		return "Abrir curso SST"

	func interact(_tool_id: int = 1) -> String:
		var bus = get_node_or_null("/root/EventBus")
		if bus != null and bus.has_signal("sst_course_modal_requested"):
			bus.sst_course_modal_requested.emit()
		return "Abriendo curso SST."
