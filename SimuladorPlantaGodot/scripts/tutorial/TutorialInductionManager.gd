class_name TutorialInductionManager
extends Node3D

# ==============================================================================
# GESTOR DEL MODO TUTORIAL / RECORRIDO RETIE (PORTERÍA, GUÍA, ROPA EPP, LOTO,
# 12 ESTACIONES Y LÍNEA VISUAL DE RECORRIDO EN SUELO)
# ==============================================================================

const LotoControllerScript = preload("res://scripts/tutorial/LotoGoldenRulesController.gd")

const SoundSynth = preload("res://scripts/core/IndustrialSoundSynthesizer.gd")

const STATIONS: Array[Dictionary] = [
	{"id": 1, "title": "Estación 1: Portería", "pos": Vector3(52.0, 0.02, 34.0), "desc": "Inspector SST. Abre Tablet con [TAB] y avanza a Vestidores."},
	{"id": 2, "title": "Estación 2: Vestidores EPP", "pos": Vector3(-15.9, 0.79, 47.88), "desc": "Ropa EPP en lockers. Presiona [E] para vestirte."},
	{"id": 3, "title": "Estación 3: Esclusa Norte", "pos": Vector3(-18.69, 0.79, 42.5), "desc": "Acceso al pasillo central."},
	{"id": 4, "title": "Estación 4: CCM 460 V", "pos": Vector3(-18.69, 0.79, 38.5), "desc": "5 Reglas LOTO y barraje 460 V."},
	{"id": 5, "title": "Estación 5: Motor 10 HP", "pos": Vector3(-21.0, 0.79, 42.2), "desc": "Motor 10 HP, 460 V e ISO 10816."},
	{"id": 6, "title": "Estación 6: Tolva y Secador", "pos": Vector3(-21.2, 0.79, 46.2), "desc": "Tolva T-301, bandas y secador."},
	{"id": 7, "title": "Estación 7: Ciclón y ATEX", "pos": Vector3(-18.69, 0.79, 33.5), "desc": "Extracción y polvo combustible."},
	{"id": 8, "title": "Estación 8: Almacén Sacos", "pos": Vector3(-18.69, 0.79, 26.8), "desc": "Estiba y logística interna."},
	{"id": 9, "title": "Estación 9: Pasillo Central", "pos": Vector3(-18.69, 0.79, 35.5), "desc": "Circulación peatonal principal."},
	{"id": 10, "title": "Estación 10: Rampa Sur", "pos": Vector3(-18.69, 0.79, 22.2), "desc": "Rampa y portón Sur."},
	{"id": 11, "title": "Estación 11: Bahía Despacho", "pos": Vector3(-35.5, 0.02, 53.5), "desc": "Bahía de carga exterior."},
	{"id": 12, "title": "Estación 12: SCADA y Cierre", "pos": Vector3(-18.69, 0.79, 40.5), "desc": "Supervisión [TAB] y certificación final."}
]

# Ruta exterior Portería -> Vestidores por acera peatonal del bloque administrativo (sin cruzar calzada de camiones)
const TOUR_ROUTE_POINTS: Array[Vector3] = [
	Vector3(52.0, 0.04, 34.0),   # 0: Estación 1 - Portería
	Vector3(48.0, 0.04, 34.0),   # 1: Salida garita Portería por sendero peatonal
	Vector3(44.8, 0.22, 39.2),   # 2: Incorporación exterior a acera bloque administrativo
	Vector3(37.2, 0.22, 43.2),   # 3: Acera concreto Este edificio administrativo (Y=0.20)
	Vector3(34.5, 0.22, 48.5),   # 4: Acera exterior esquina Noreste edificio administrativo
	Vector3(32.0, 0.22, 52.0),   # 5: Inicio acera Norte edificio administrativo (Y=0.20)
	Vector3(24.0, 0.22, 52.25),  # 6: Acera Norte frente Sala de Reuniones (tras franja verde, lejos de Z=58.3)
	Vector3(14.0, 0.22, 52.5),   # 7: Acera Norte frente oficinas administrativas
	Vector3(2.0, 0.04, 53.4),    # 8: Sendero Oeste hacia plataforma exterior Bahía Norte (separado de vía camiones)
	Vector3(-11.4, 0.04, 53.75), # 9: Pie exterior Este de rampa Bahía Norte
	Vector3(-14.0, 0.34, 53.75), # 10: Ascenso rampa exterior Norte (tramo medio exterior)
	Vector3(-16.6, 0.63, 53.55), # 11: Cima de rampa exterior por encima de bordillo Bahía Norte
	Vector3(-15.5, 0.63, 50.6),  # 12: Plataforma exterior Bahía Norte hacia Vestidores
	Vector3(-13.9, 0.63, 49.85), # 13: Frente exterior centrado a Puerta Norte Vestidores (X=-13.91)
	Vector3(-13.9, 0.83, 49.45), # 14: Umbral losa acceso Vestidores (Y=0.79)
	Vector3(-13.9, 0.83, 47.55), # 15: Centro exacto del vano puerta Vestidores (Z=47.25..47.75)
	Vector3(-14.85, 0.83, 47.58), # 16: Estación 2 - Guía SST junto a los lockers EPP (acceso 100% exterior)
	Vector3(-13.9, 0.83, 47.55), # 17: Salida de Vestidores por centro de vano
	Vector3(-13.9, 0.83, 49.45), # 18: Umbral losa salida Vestidores (Y=0.79)
	Vector3(-13.9, 0.63, 49.85), # 19: Exterior Puerta Norte Vestidores
	Vector3(-18.69, 0.63, 49.85), # 20: Paso centrado frente a Puerta Doble Norte
	Vector3(-18.69, 0.83, 49.45), # 21: Umbral ingreso centrado Puerta Doble Norte
	Vector3(-18.69, 0.83, 42.5),  # 22: Estación 3 - Pasillo Central / Esclusa Norte Nave
	Vector3(-18.69, 0.83, 38.5),  # 23: Estación 4 - Tablero CCM 460V (junto a máquinas)
	Vector3(-21.0, 0.83, 42.2),   # 24: Estación 5 - Trituradora + Motor 10 HP
	Vector3(-21.0, 0.83, 44.5),   # 25: Paso lateral por banda verde hacia Tolva
	Vector3(-21.2, 0.83, 46.2),   # 26: Estación 6 - Tolva T-301 y Bandas
	Vector3(-18.69, 0.83, 41.0),  # 27: Incorporación al pasillo central
	Vector3(-18.69, 0.83, 33.5),  # 28: Estación 7 - Zona ATEX / Ciclón
	Vector3(-18.69, 0.83, 26.8),  # 29: Estación 8 - Almacén Super Sacos
	Vector3(-18.69, 0.83, 31.0),  # 30: Tránsito pasillo central desde Estación 8
	Vector3(-18.69, 0.83, 35.5),  # 31: Estación 9 - Pasillo Peatonal Central Nave
	Vector3(-18.69, 0.83, 26.8),  # 32: Descenso por pasillo central hacia Rampa Sur
	Vector3(-18.69, 0.83, 22.2),  # 33: Estación 10 - Rampa Sur y Acceso Nave
	Vector3(-20.3, 0.83, 22.2),   # 34: Borde superior Rampa descenso
	Vector3(-28.5, 0.04, 22.2),   # 35: Borde inferior Rampa descenso
	Vector3(-30.5, 0.04, 22.2),   # 36: Pie Oeste de Rampa
	Vector3(-30.5, 0.04, 18.0),   # 37: Paseo exterior Oeste
	Vector3(-46.0, 0.04, 18.0),   # 38: Esquina exterior Suroeste despejada
	Vector3(-46.0, 0.04, 53.5),   # 39: Avenida Oeste rodeando camión de despacho
	Vector3(-35.5, 0.04, 53.5),   # 40: Estación 11 - Bahía Exterior Camión Despacho
	Vector3(-46.0, 0.04, 53.5),   # 41: Retorno por Avenida Oeste exterior
	Vector3(-46.0, 0.04, 18.0),   # 42: Esquina exterior Suroeste despejada
	Vector3(-30.5, 0.04, 18.0),   # 43: Paseo exterior Sur
	Vector3(-30.5, 0.04, 22.2),   # 44: Pie Oeste de Rampa Sur
	Vector3(-28.5, 0.04, 22.2),   # 45: Acceso suave Rampa Sur
	Vector3(-20.3, 0.83, 22.2),   # 46: Cima de Rampa Sur hacia nave
	Vector3(-18.69, 0.83, 22.2),  # 47: Troncal central acceso Sur
	Vector3(-18.69, 0.83, 40.5)   # 48: Estación 12 - Centro SCADA y Certificación
]

# Locución institucional exterior hacia Vestidores
const EXTERIOR_NARRATION_SEGMENTS: Array[Dictionary] = [
	{
		"min_progress": 0.0,
		"min_elapsed": 0.0,
		"speaker": "AGROMOLINOS · (1/5)",
		"text": "Planta AgroMolinos: molienda de grano y ensacado."
	},
	{
		"min_progress": 0.18,
		"min_elapsed": 6.5,
		"speaker": "AGROMOLINOS · (2/5)",
		"text": "Motor M-101: 10 HP, 460 V, 1750 RPM IE3."
	},
	{
		"min_progress": 0.40,
		"min_elapsed": 13.5,
		"speaker": "AGROMOLINOS · (3/5)",
		"text": "Control DTC y monitoreo de temperatura y vibración."
	},
	{
		"min_progress": 0.64,
		"min_elapsed": 20.5,
		"speaker": "AGROMOLINOS · (4/5)",
		"text": "Mantenimiento predictivo IA en tablet [TAB]."
	},
	{
		"min_progress": 0.84,
		"min_elapsed": 27.5,
		"speaker": "AGROMOLINOS · (5/5)",
		"text": "VFD: -28% kWh/ton. Equipa EPP en lockers."
	}
]

const STATION_TO_ROUTE_IDX: Dictionary = {
	1: 0, 2: 16, 3: 22, 4: 23, 5: 24, 6: 26,
	7: 28, 8: 29, 9: 31, 10: 33, 11: 40, 12: 48
}

# Equipos destacados en cada estación durante la presentación del tutorial
const STATION_GLOW_GROUPS: Dictionary = {
	1: [],
	2: ["locker"],
	3: [],
	4: ["breaker"],
	5: ["motor"],
	6: ["hopper", "banda_descarga", "banda_inclinada_tolva", "banda_trituradora", "tornillo_trituradora", "tornillo_secador", "secador_rotatorio"],
	7: ["ciclon_separador", "cyclone", "unidad_extraccion", "horno", "soplador", "intercambiador_calor", "ductos_aire"],
	8: ["bag"],
	9: [],
	10: [],
	11: ["truck"],
	12: []
}
const ALL_EQUIPMENT_GLOW_GROUPS: Array[String] = [
	"banda_descarga", "banda_inclinada_tolva", "hopper", "banda_trituradora",
	"tornillo_trituradora", "motor", "tornillo_secador", "secador_rotatorio",
	"ciclon_separador", "cyclone", "unidad_extraccion", "horno",
	"soplador", "intercambiador_calor", "ductos_aire",
	"locker", "breaker", "bag", "truck"
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
				"INDUCCIÓN RETIE · PORTERÍA",
				"Bienvenido a AgroMolinos. Elige: Curso SST (+0.5 pt) o recorrido a Vestidores.",
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
	sst_course_active = start_course
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
				"Curso rápido SST (RETIE) y quiz aprobados en Sala de Reuniones (%d/%d)." % [score, total],
				0.5
			)
		if bus.has_signal("notification_posted"):
			bus.notification_posted.emit(
				"CURSO SST (+0.5 PT)",
				"Quiz aprobado (%d/%d). Sigue al Inspector a Vestidores." % [score, total],
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
	_start_exterior_narration()
	_rebuild_floor_guide_line()

func _on_briefing_closed(resume_tour_on_close: bool) -> void:
	is_briefing_active = false
	if resume_tour_on_close and not briefing_completed:
		briefing_completed = true
		var bus = get_node_or_null("/root/EventBus")
		if sst_course_chosen and not sst_course_completed:
			_start_sst_course_walk()
			if bus != null and bus.has_signal("notification_posted"):
				bus.notification_posted.emit(
					"CURSO SST",
					"Sigue al Inspector. Presiona [E] en la mesa.",
					"info"
				)
		else:
			_advance_tour_target(2)
			_start_exterior_narration()
			if bus != null and bus.has_signal("notification_posted"):
				bus.notification_posted.emit(
					"RECORRIDO GUIADO",
					"Sigue al Inspector hacia Vestidores.",
					"info"
				)
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
								"EPP OBLIGATORIO",
								"Equipa ropa EPP en Vestidores (Estación 2).",
								"warning"
							)
				elif target_station_id == 2:
					visit_station(2)
				elif _prompted_station_id != target_station_id:
					# En estaciones 3..12 exigir [E] del jugador para pasar a la siguiente estación
					_prompted_station_id = target_station_id
					var hud = get_tree().root.find_child("HUDController", true, false)
					if hud != null and hud.has_method("show_npc_dialogue"):
						var action_hint := "[E] Avanzar (%d/12)" % (target_station_id + 1) if target_station_id < STATIONS.size() else "[E] Certificar (12/12)"
						hud.show_npc_dialogue(st["title"].to_upper(), "%s · %s" % [st["desc"], action_hint], 10.0)

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
	if is_ready_for_meeting_course():
		return "[E] Curso SST (RETIE)"
	if not is_ready_for_interact_advance():
		return ""
	if target_station_id < STATIONS.size():
		return "[E] Estación %d/12" % (target_station_id + 1)
	return "[E] Certificar Recorrido (12/12)"

func try_advance_station_by_interact() -> String:
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
		var reply := "Avanzando hacia %s." % next_st["title"]
		if hud != null and hud.has_method("show_npc_dialogue"):
			hud.show_npc_dialogue("SUPERVISOR SST", "Avanza hacia %s." % next_st["title"], 3.5)
		return reply
	_check_tour_completion()
	var finish_msg := "Recorrido completado (12/12). Máquinas encendidas. Consulta Tablet [TAB]."
	if hud != null and hud.has_method("show_npc_dialogue"):
		hud.show_npc_dialogue("CERTIFICACIÓN (12/12)", finish_msg, 5.0)
	return finish_msg

func _on_epp_state_changed(all_equipped: bool, _items: Dictionary) -> void:
	epp_completed = all_equipped
	if all_equipped:
		visit_station(2)
		_advance_tour_target(3)
	_notify_glow_controller()

func _on_golden_rules_completed() -> void:
	if epp_completed:
		visit_station(4)

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
				bus.notification_posted.emit(st["title"].to_upper(), st["desc"], "info")

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
			"PUNTO ANTERIOR",
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
		"narration_active": _narration_active,
		"narration_segment": _narration_idx + 1
	}

func skip_tutorial_to_final_station() -> Dictionary:
	_stop_exterior_narration()
	tutorial_skipped = true
	is_briefing_active = false
	briefing_completed = true
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
		_player_ref.global_position = Vector3(final_pos.x, 0.85, final_pos.z)
		if "velocity" in _player_ref:
			_player_ref.velocity = Vector3.ZERO
	if _guide_worker != null and is_instance_valid(_guide_worker):
		_guide_worker.global_position = Vector3(final_pos.x, 0.83, final_pos.z - 1.5)
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
				"ESTACIÓN 12/12 · SCADA",
				"Tutorial saltado. EPP equipado. Pulsa [TAB] o [E] para certificar.",
				5.0
			)

	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		if bus.has_signal("tutorial_station_reached"):
			bus.tutorial_station_reached.emit(STATIONS.size(), final_st["title"])
		if bus.has_signal("notification_posted"):
			bus.notification_posted.emit(
				"ESTACIÓN 12/12",
				"EPP equipado. Sistemas en línea.",
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
	_select_spanish_tts_voice()
	_play_narration_segment(0)

func _stop_exterior_narration() -> void:
	_narration_active = false

func _select_spanish_tts_voice() -> void:
	_tts_voice_id = "" # Desactivado: evita bloqueos/deadlocks de Windows SAPI COM al llegar a Vestidores

func _compute_exterior_walk_progress() -> float:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return 0.0
	var p: Vector3 = _player_ref.global_position
	# Progreso monótono aproximado del recorrido exterior Noreste -> Norte -> Rampa Vestidores
	if p.z < 46.0 and p.x > 30.0:
		return clampf((p.z - 34.0) / 20.0 * 0.25, 0.0, 0.25)
	if p.z >= 46.0:
		return clampf(0.25 + ((48.0 - p.x) / 62.5) * 0.75, 0.25, 1.0)
	return clampf((48.0 - p.x) / 66.0, 0.0, 1.0)

func _update_exterior_narration(delta: float) -> void:
	if not _narration_active:
		return
	if tutorial_skipped or epp_completed or sst_course_active or target_station_id != 2:
		_stop_exterior_narration()
		return
	_narration_elapsed += delta
	var prog := _compute_exterior_walk_progress()
	var desired := _narration_idx
	for i in range(EXTERIOR_NARRATION_SEGMENTS.size()):
		var seg: Dictionary = EXTERIOR_NARRATION_SEGMENTS[i]
		if prog >= float(seg["min_progress"]) or _narration_elapsed >= float(seg["min_elapsed"]):
			desired = maxi(desired, i)
	if desired > _narration_idx:
		_play_narration_segment(desired)

func _play_narration_segment(idx: int) -> void:
	if idx < 0 or idx >= EXTERIOR_NARRATION_SEGMENTS.size():
		return
	_narration_idx = idx
	var seg: Dictionary = EXTERIOR_NARRATION_SEGMENTS[idx]
	var speaker: String = str(seg["speaker"])
	var text: String = str(seg["text"])
	var hud = get_tree().root.find_child("HUDController", true, false) if is_inside_tree() else null
	if hud != null and hud.has_method("show_npc_dialogue"):
		hud.show_npc_dialogue(speaker, text, 9.5)
	if _narration_chime_player == null and is_inside_tree():
		_narration_chime_player = AudioStreamPlayer.new()
		_narration_chime_player.name = "ExteriorNarrationChime"
		_narration_chime_player.volume_db = -10.0
		_narration_chime_player.stream = SoundSynth.create_station_chime_sound()
		add_child(_narration_chime_player)
	if _narration_chime_player != null and is_instance_valid(_narration_chime_player):
		_narration_chime_player.play()

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
		return "[E] Abrir Curso Rápido SST (RETIE)"

	func interact(_tool_id: int = 1) -> String:
		var bus = get_node_or_null("/root/EventBus")
		if bus != null and bus.has_signal("sst_course_modal_requested"):
			bus.sst_course_modal_requested.emit()
		return "Abriendo curso rápido SST (RETIE) en Sala de Reuniones."
