class_name PlantVisibilityOptimizer
extends Node3D

# ==============================================================================
# OPTIMIZADOR DE VISIBILIDAD, LOD Y CULLING POR SECTORES - AGROMOLINOS
# Elimina caídas de FPS aplicando:
# 1. Bandas de distancia LOD (visibility_range_end) en mallas según diagonal AABB.
# 2. Desactivación de sombras directas en micro/pequeños elementos interiores.
# 3. Oclusión espacial por sectores (Nave de Producción vs Bloque Administrativo).
# 4. Culling de camiones exteriores lejanos cuando se está en interiores.
# ==============================================================================

const LOD_MICRO_DIAG: float = 0.45
const LOD_SMALL_DIAG: float = 1.40
const LOD_MEDIUM_DIAG: float = 3.80

const DIST_MICRO: float = 20.0
const DIST_SMALL: float = 38.0
const DIST_MEDIUM: float = 62.0

var _admin_nodes: Array[Node3D] = []
var _nave_nodes: Array[Node3D] = []
var _exterior_trucks: Array[Node3D] = []
var _lod_mesh_items: Array[Dictionary] = []

var _current_sector: String = "INIT"
var _timer: float = 0.0
var _camera_ref: Camera3D = null

func _ready() -> void:
	call_deferred("_setup_optimizer")

func _setup_optimizer() -> void:
	var scene_root := get_parent()
	if scene_root == null:
		return
	
	_apply_lod_and_shadow_bands(scene_root)
	_collect_sectors(scene_root)
	_update_sector_visibility(true)

func _is_dynamic_or_truck_node(node: Node) -> bool:
	var cur := node
	while cur != null:
		var nm: String = str(cur.name)
		if "Truck" in nm or "NCDOT" in nm or nm.begins_with("Door_"):
			return true
		if nm in [
			"Node1575", "Node1577", "Node1579",
			"ProductionChainFlow", "ProductFlowVisuals",
			"Helicoidal", "Bunkerdoseerelevator", "Pallet 60 sacos", "super saco"
		]:
			return true
		if cur is InteractiveDoor:
			return true
		if nm == "PlantaCompletaSketchUp" or nm == "MainPlantScene":
			break
		cur = cur.get_parent()
	return false

func _apply_lod_and_shadow_bands(scene_root: Node) -> void:
	_lod_mesh_items.clear()
	var target_parents: Array[String] = [
		"PlantaCompletaSketchUp",
		"FactoryEntranceAndLockers",
		"PlantLights"
	]
	
	for parent_name in target_parents:
		var parent_node := scene_root.find_child(parent_name, true, false)
		if parent_node == null:
			continue
		
		for ch in parent_node.find_children("*", "MeshInstance3D", true, false):
			var mi := ch as MeshInstance3D
			if mi == null or not is_instance_valid(mi) or mi.mesh == null:
				continue
			if mi.name == "GlowOutlineShell" or mi.mesh is ImmediateMesh:
				continue
			
			var aabb := mi.mesh.get_aabb()
			var scale_mag := mi.global_transform.basis.get_scale().abs().length() / sqrt(3.0)
			var world_diag := aabb.size.length() * scale_mag

			# Nunca aplicar culling estático por posición inicial a camiones o nodos móviles/animados
			if _is_dynamic_or_truck_node(mi):
				mi.visibility_range_end = 0.0
				mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
				mi.visible = true
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if world_diag < LOD_SMALL_DIAG else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				continue

			var world_center := mi.global_transform * aabb.get_center()
			
			if world_diag < LOD_MICRO_DIAG:
				# Tornillería, accesorios, pernos, bridas menores
				mi.visibility_range_end = DIST_MICRO
				mi.visibility_range_end_margin = 3.0
				mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				_lod_mesh_items.append({"node": mi, "pos": world_center, "max_d2": DIST_MICRO * DIST_MICRO})
			elif world_diag < LOD_SMALL_DIAG:
				# Tramos de ducto, peldaños, barandillas, pequeños motores
				mi.visibility_range_end = DIST_SMALL
				mi.visibility_range_end_margin = 5.0
				mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				_lod_mesh_items.append({"node": mi, "pos": world_center, "max_d2": DIST_SMALL * DIST_SMALL})
			elif world_diag < LOD_MEDIUM_DIAG:
				# Tolvas intermedias, ciclones, carcasas de maquinaria interior
				mi.visibility_range_end = DIST_MEDIUM
				mi.visibility_range_end_margin = 8.0
				mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				_lod_mesh_items.append({"node": mi, "pos": world_center, "max_d2": DIST_MEDIUM * DIST_MEDIUM})
			else:
				# Estructuras maestras, muros exteriores, techos, losas de piso y silos
				mi.visibility_range_end = 0.0
				mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func _collect_sectors(scene_root: Node) -> void:
	_admin_nodes.clear()
	_nave_nodes.clear()
	_exterior_trucks.clear()
	
	var plant := scene_root.find_child("PlantaCompletaSketchUp", true, false)
	var plant_node = plant.get_node_or_null("Node") if plant != null else null
	if plant_node != null:
		for ch in plant_node.get_children():
			if not (ch is Node3D):
				continue
			var n3d := ch as Node3D
			if _is_dynamic_or_truck_node(n3d):
				continue
			var aabb: AABB = _calc_node_aabb(n3d)
			if aabb.size.length() <= 0.01:
				continue
			var c := aabb.get_center()
			var d := aabb.size.length()
			
			# Sector Administrativo: bloque de oficinas, salas, cubículos (X > 12.0)
			if c.x > 12.0 and d < 55.0:
				_admin_nodes.append(n3d)
			# Sector Nave de Producción: maquinaria, tolvas, molinos (X < -13.0, Z en [18, 52])
			elif c.x < -13.0 and c.z > 18.0 and c.z < 52.0 and d < 35.0:
				_nave_nodes.append(n3d)
	
	var mill_unit := scene_root.find_child("MotorMillUnit", true, false) as Node3D
	if mill_unit != null:
		_nave_nodes.append(mill_unit)

	# Solo registrar los nodos raíz de cada camión para ocultamiento atómico (nunca por partes)
	for mover_name in ["TruckIntakeMover", "TruckDispatchMover", "TruckBay2Mover", "TruckStagingMover"]:
		var trk := scene_root.find_child(mover_name, true, false) as Node3D
		if trk != null and not _exterior_trucks.has(trk):
			_exterior_trucks.append(trk)
			for m_ch in trk.find_children("*", "MeshInstance3D", true, false):
				var tmi := m_ch as MeshInstance3D
				if tmi != null and tmi.name != "GlowOutlineShell":
					tmi.visible = true
					tmi.visibility_range_end = 0.0
					tmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED

func _calc_node_aabb(n: Node) -> AABB:
	var has := false
	var b := AABB()
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		return (n as MeshInstance3D).global_transform * (n as MeshInstance3D).mesh.get_aabb()
	for ch in n.find_children("*", "MeshInstance3D", true, false):
		var mi := ch as MeshInstance3D
		if mi.mesh == null:
			continue
		var mb := mi.global_transform * mi.mesh.get_aabb()
		if not has:
			b = mb
			has = true
		else:
			b = b.merge(mb)
	return b

func _process(delta: float) -> void:
	_timer += delta
	if _timer < 0.20:
		return
	_timer = 0.0
	var cam := _get_active_camera()
	_update_sector_visibility(false, cam)
	_update_mesh_distance_culling(cam)

func _update_mesh_distance_culling(cam: Camera3D) -> void:
	if cam == null:
		return
	var cam_pos := cam.global_position
	for item in _lod_mesh_items:
		var mi := item["node"] as MeshInstance3D
		if mi == null or not is_instance_valid(mi):
			continue
		var p_node := mi.get_parent() as Node3D
		if p_node != null and not p_node.visible:
			continue
		var m_pos: Vector3 = item["pos"]
		var d2: float = cam_pos.distance_squared_to(m_pos)
		var max_d2: float = float(item["max_d2"])
		var should_be_vis: bool = true
		if d2 > max_d2:
			should_be_vis = false
		elif d2 > 49.0 and cam.is_position_behind(m_pos):
			should_be_vis = false
		if mi.visible != should_be_vis:
			mi.visible = should_be_vis

func _update_sector_visibility(force: bool, cam: Camera3D = null) -> void:
	if cam == null:
		cam = _get_active_camera()
	if cam == null:
		return
	
	var p := cam.global_position
	var new_sector := "EXTERIOR"
	
	# Delimitación geométrica de sectores de la planta
	if p.x <= -13.5 and p.z >= 18.0 and p.z <= 52.0:
		new_sector = "NAVE_PRODUCCION"
	elif p.x >= 12.0 and p.z >= 20.0 and p.z <= 52.0:
		new_sector = "SECTOR_ADMIN"
	else:
		new_sector = "EXTERIOR"
		
	if new_sector == _current_sector and not force:
		# Actualizar culling de camiones por distancia
		_update_trucks_visibility(p)
		return
		
	_current_sector = new_sector
	
	match _current_sector:
		"NAVE_PRODUCCION":
			# Ocultar oficinas administrativas (tras muros macizos a >30m)
			_set_nodes_visible(_admin_nodes, false)
			_set_nodes_visible(_nave_nodes, true)
		"SECTOR_ADMIN":
			# Ocultar maquinaria de la nave de molienda
			_set_nodes_visible(_admin_nodes, true)
			_set_nodes_visible(_nave_nodes, false)
		_:
			# Exterior / Sendero / Puertas abiertas: ambos activos con LOD por distancia
			_set_nodes_visible(_admin_nodes, true)
			_set_nodes_visible(_nave_nodes, true)
			
	_update_trucks_visibility(p)

func _update_trucks_visibility(cam_pos: Vector3) -> void:
	if _exterior_trucks.is_empty():
		var sr := get_parent()
		if sr != null:
			for mover_name in ["TruckIntakeMover", "TruckDispatchMover", "TruckBay2Mover", "TruckStagingMover"]:
				var trk_n := sr.find_child(mover_name, true, false) as Node3D
				if trk_n != null and not _exterior_trucks.has(trk_n):
					_exterior_trucks.append(trk_n)
	for trk in _exterior_trucks:
		if trk == null or not is_instance_valid(trk):
			continue
		var want_vis: bool = true
		if _current_sector == "NAVE_PRODUCCION" or _current_sector == "SECTOR_ADMIN":
			want_vis = (cam_pos.distance_to(trk.global_position) <= 48.0)
		if trk.visible != want_vis:
			trk.visible = want_vis

func _set_nodes_visible(nodes: Array[Node3D], vis: bool) -> void:
	for n in nodes:
		if n != null and is_instance_valid(n) and n.visible != vis:
			n.visible = vis

func _get_active_camera() -> Camera3D:
	if _camera_ref != null and is_instance_valid(_camera_ref) and _camera_ref.current:
		return _camera_ref
	if get_viewport() != null:
		_camera_ref = get_viewport().get_camera_3d()
		if _camera_ref != null:
			return _camera_ref
	var scene_root := get_parent()
	if scene_root != null:
		var player := scene_root.find_child("PlayerOperator", true, false)
		if player != null:
			var cam = player.find_child("CameraFPS", true, false) as Camera3D
			if cam == null:
				cam = player.find_child("Camera3D", true, false) as Camera3D
			if cam != null:
				_camera_ref = cam
				return _camera_ref
	return null
