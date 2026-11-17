class_name MezzanineCCTVController
extends Node3D

# ==============================================================================
# CONTROLADOR CCTV DESDE MEZZANINE Y CÁMARAS ESTRATÉGICAS DE PLANTA
# Bloque 8 - Proyecto Final Máquinas Eléctricas (AgroMolinos del Valle S.A.)
# ==============================================================================

const CAMERAS_SPEC: Array[Dictionary] = [
	{
		"id": "CAM_01_MOLIENDA",
		"name": "Cámara 01 — Trituradora y Motor 10 HP IE3",
		"position": Vector3(-19.5, 5.2, 41.2),
		"look_at": Vector3(-25.81, 1.8, 42.6),
		"fov": 62.0
	},
	{
		"id": "CAM_02_CCM460V",
		"name": "Cámara 02 — Tablero Eléctrico CCM 460 V (Junto a Maquinaria)",
		"position": Vector3(-17.8, 3.9, 41.2),
		"look_at": Vector3(-20.48, 1.52, 38.5),
		"fov": 60.0
	},
	{
		"id": "CAM_03_BASCULA",
		"name": "Cámara 03 — Tolva T-301, Bandas y Descarga Exterior",
		"position": Vector3(-21.5, 5.0, 48.0),
		"look_at": Vector3(-26.1, 1.9, 46.6),
		"fov": 62.0
	},
	{
		"id": "CAM_04_DESPACHO",
		"name": "Cámara 04 — Zona 8 Descarga & Bahía Despacho",
		"position": Vector3(-31.0, 5.2, 46.5),
		"look_at": Vector3(-34.0, 1.4, 51.3),
		"fov": 68.0
	}
]

var active_camera_id: String = "CAM_01_MOLIENDA"
var camera_nodes: Dictionary = {}
var cctv_viewport: SubViewport = null
var cctv_camera_rig: Camera3D = null
var mezzanine_monitor_position: Vector3 = Vector3(-20.5, 4.5, 36.0)

func _ready() -> void:
	_setup_cctv_cameras()
	select_camera(active_camera_id)

func _setup_cctv_cameras() -> void:
	if cctv_viewport == null:
		cctv_viewport = get_node_or_null("CCTVSubViewport") as SubViewport
	if cctv_viewport == null:
		cctv_viewport = SubViewport.new()
		cctv_viewport.name = "CCTVSubViewport"
		cctv_viewport.size = Vector2i(320, 180)
		cctv_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child(cctv_viewport)

	if cctv_camera_rig == null and is_inside_tree():
		var world_3d := get_viewport().world_3d if get_viewport() != null else null
		if world_3d != null:
			cctv_viewport.world_3d = world_3d

	if cctv_camera_rig == null:
		cctv_camera_rig = cctv_viewport.get_node_or_null("CCTVPipCamera") as Camera3D
	if cctv_camera_rig == null:
		cctv_camera_rig = Camera3D.new()
		cctv_camera_rig.name = "CCTVPipCamera"
		cctv_camera_rig.current = true
		cctv_viewport.add_child(cctv_camera_rig)

	for spec in CAMERAS_SPEC:
		var cid: String = spec["id"]
		var marker := get_node_or_null(cid) as Camera3D
		if marker == null:
			marker = Camera3D.new()
			marker.name = cid
			marker.fov = float(spec["fov"])
			marker.current = false
			add_child(marker)
			marker.position = spec["position"]
			if marker.is_inside_tree():
				var look_target: Vector3 = spec["look_at"]
				if not marker.global_position.is_equal_approx(look_target):
					marker.look_at(look_target, Vector3.UP)
		camera_nodes[cid] = {
			"spec": spec,
			"node": marker
		}

func select_camera(cam_id: String) -> Dictionary:
	if not camera_nodes.has(cam_id):
		if CAMERAS_SPEC.size() > 0:
			cam_id = CAMERAS_SPEC[0]["id"]
		else:
			return {}

	active_camera_id = cam_id
	var entry: Dictionary = camera_nodes[cam_id]
	var spec: Dictionary = entry["spec"]

	if cctv_camera_rig != null:
		cctv_camera_rig.fov = float(spec["fov"])
		cctv_camera_rig.global_position = spec["position"]
		if cctv_camera_rig.is_inside_tree():
			var look_target: Vector3 = spec["look_at"]
			if not cctv_camera_rig.global_position.is_equal_approx(look_target):
				cctv_camera_rig.look_at(look_target, Vector3.UP)

	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("cctv_camera_changed"):
		bus.cctv_camera_changed.emit(cam_id, str(spec["name"]))

	return spec.duplicate(true)

func cycle_next_camera() -> Dictionary:
	var idx: int = 0
	for i in range(CAMERAS_SPEC.size()):
		if CAMERAS_SPEC[i]["id"] == active_camera_id:
			idx = (i + 1) % CAMERAS_SPEC.size()
			break
	return select_camera(CAMERAS_SPEC[idx]["id"])

func get_active_camera_id() -> String:
	return active_camera_id

func get_active_camera_info() -> Dictionary:
	for spec in CAMERAS_SPEC:
		if spec["id"] == active_camera_id:
			return spec.duplicate(true)
	return {}

func get_cameras_info() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for spec in CAMERAS_SPEC:
		result.append(spec.duplicate(true))
	return result

func get_viewport_texture() -> ViewportTexture:
	if cctv_viewport != null:
		cctv_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
		return cctv_viewport.get_texture()
	return null
