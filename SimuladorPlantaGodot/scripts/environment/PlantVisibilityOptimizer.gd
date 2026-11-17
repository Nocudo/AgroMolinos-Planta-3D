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
var _cctv_override_active: bool = false
var _locker_mesh_opaque_mat: StandardMaterial3D = null
var _materials_optimized: bool = false

func _ready() -> void:
	call_deferred("_setup_optimizer")

func _setup_optimizer() -> void:
	var scene_root := get_parent()
	if scene_root == null:
		return
	
	_optimize_plant_materials_and_lockers(scene_root)
	_apply_lod_and_shadow_bands(scene_root)
	_collect_sectors(scene_root)
	if _cctv_override_active:
		_apply_cctv_override_visible()
	else:
		_update_sector_visibility(true)

func _build_locker_opaque_mesh_material(src_mat: StandardMaterial3D) -> StandardMaterial3D:
	if _locker_mesh_opaque_mat != null:
		return _locker_mesh_opaque_mat
	var mat := StandardMaterial3D.new()
	mat.resource_name = "LockerDiamondMeshOpaqueOpt"
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.metallic = 0.28
	mat.roughness = 0.56
	# Escala UV equilibrada: malla metálica industrial nítida sin moiré ni thrashing de caché (vs 91x982 original)
	mat.uv1_scale = Vector3(0.28, 0.28, 1.0)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	var bg_col := Color(0.09, 0.27, 0.11, 1.0)
	var wire_tint := Color(0.26, 0.58, 0.28, 1.0)
	var src_tex: Texture2D = src_mat.albedo_texture if src_mat != null else null
	var src_img: Image = src_tex.get_image() if src_tex != null else null
	if src_img != null and not src_img.is_empty():
		var work := src_img.duplicate() as Image
		if work.is_compressed():
			work.decompress()
		work.convert(Image.FORMAT_RGBA8)
		work.resize(128, 64, Image.INTERPOLATE_BILINEAR)
		var out_img := Image.create(128, 64, false, Image.FORMAT_RGB8)
		for y in range(64):
			for x in range(128):
				var px: Color = work.get_pixel(x, y)
				var a: float = clampf(px.a, 0.0, 1.0)
				var lum: float = clampf((px.r + px.g + px.b) / 3.0 * 1.40 + 0.24, 0.25, 1.0)
				var fg := Color(wire_tint.r * lum, wire_tint.g * lum, wire_tint.b * lum, 1.0)
				var blended := bg_col.lerp(fg, a)
				out_img.set_pixel(x, y, Color(blended.r, blended.g, blended.b, 1.0))
		out_img.generate_mipmaps()
		mat.albedo_texture = ImageTexture.create_from_image(out_img)
		mat.albedo_color = Color.WHITE
	else:
		mat.albedo_color = Color(0.14, 0.36, 0.15, 1.0)

	_locker_mesh_opaque_mat = mat
	return _locker_mesh_opaque_mat

func _merge_static_meshes_under(root_node: Node3D, sources: Array[MeshInstance3D], merged_name: String, mat: Material) -> void:
	if root_node == null or sources.size() < 2:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inv_root: Transform3D = root_node.global_transform.affine_inverse()
	var added_any := false
	for mi in sources:
		if mi == null or not is_instance_valid(mi) or mi.mesh == null:
			continue
		var rel_xf: Transform3D = inv_root * mi.global_transform
		var normal_basis: Basis = rel_xf.basis.inverse().transposed()
		for s in range(mi.mesh.get_surface_count()):
			var arr := mi.mesh.surface_get_arrays(s)
			if arr.is_empty():
				continue
			var verts := arr[Mesh.ARRAY_VERTEX] as PackedVector3Array
			if verts == null or verts.is_empty():
				continue
			var norms := arr[Mesh.ARRAY_NORMAL] as PackedVector3Array if arr[Mesh.ARRAY_NORMAL] is PackedVector3Array else PackedVector3Array()
			var uvs := arr[Mesh.ARRAY_TEX_UV] as PackedVector2Array if arr[Mesh.ARRAY_TEX_UV] is PackedVector2Array else PackedVector2Array()
			var idxs := arr[Mesh.ARRAY_INDEX] as PackedInt32Array if arr[Mesh.ARRAY_INDEX] is PackedInt32Array else PackedInt32Array()
			var has_n: bool = norms.size() == verts.size()
			var has_uv: bool = uvs.size() == verts.size()
			if not idxs.is_empty():
				for idx in idxs:
					if has_n:
						st.set_normal((normal_basis * norms[idx]).normalized())
					if has_uv:
						st.set_uv(uvs[idx])
					st.add_vertex(rel_xf * verts[idx])
					added_any = true
			else:
				for vi in range(verts.size()):
					if has_n:
						st.set_normal((normal_basis * norms[vi]).normalized())
					if has_uv:
						st.set_uv(uvs[vi])
					st.add_vertex(rel_xf * verts[vi])
					added_any = true
	if not added_any:
		return
	var merged_mesh := st.commit()
	if merged_mesh == null:
		return
	var merged_mi := MeshInstance3D.new()
	merged_mi.name = merged_name
	merged_mi.mesh = merged_mesh
	if mat != null:
		merged_mi.set_surface_override_material(0, mat)
	merged_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root_node.add_child(merged_mi)
	for mi in sources:
		if mi != null and is_instance_valid(mi):
			mi.visible = false
			mi.set_meta("merged_into_batch", true)
			var g_sh := mi.get_node_or_null("GlowOutlineShell") as MeshInstance3D
			if g_sh != null:
				g_sh.visible = false

func _optimize_plant_materials_and_lockers(scene_root: Node) -> void:
	if _materials_optimized:
		return
	var plant := scene_root.find_child("PlantaCompletaSketchUp", true, false)
	if plant == null:
		return
	_materials_optimized = true

	var visited_mats: Dictionary = {}
	var locker_roots: Array[Node3D] = []
	for ch in plant.find_children("*", "MeshInstance3D", true, false):
		var mi := ch as MeshInstance3D
		if mi == null or not is_instance_valid(mi) or mi.mesh == null:
			continue
		if mi.name == "GlowOutlineShell" or mi.mesh is ImmediateMesh:
			continue

		var is_locker_mesh := false
		var cur: Node = mi
		while cur != null and cur != plant:
			if str(cur.name).begins_with("Watson Zone Slot Lockers"):
				is_locker_mesh = true
				if cur is Node3D and not locker_roots.has(cur):
					locker_roots.append(cur as Node3D)
				break
			cur = cur.get_parent()

		var surf_cnt := mi.mesh.get_surface_count()
		for s in range(surf_cnt):
			var mat := mi.get_active_material(s)
			if not (mat is StandardMaterial3D):
				continue
			var sm := mat as StandardMaterial3D
			var mname_l := sm.resource_name.to_lower()

			# 1. En lockers: sustituir la malla de alambre ALPHA_SCISSOR (91x982 tiling + 14 capas sobrepuestas)
			#    por un material opaco POT 128x64 con mipmaps que habilita Early-Z y elimina el drop de FPS
			if is_locker_mesh and ("fencing" in mname_l or "diamond_mesh" in mname_l):
				mi.set_surface_override_material(s, _build_locker_opaque_mesh_material(sm))
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				continue

			# 2. En toda la planta: SketchUp exporta 146 materiales sólidos con alphaMode=MASK (1.24M triángulos)
			#    que inhabilitan Early-Z en GPU integrada. Convertimos a opaco real todos los que no son rejilla/malla.
			var mid := sm.get_instance_id()
			if not visited_mats.has(mid):
				visited_mats[mid] = true
				if sm.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR or sm.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_HASH:
					var keep_cutout := (sm.albedo_texture != null) and ("fencing" in mname_l or "diamond_mesh" in mname_l or "mesh_blue" in mname_l)
					if not keep_cutout and sm.albedo_color.a >= 0.99:
						sm.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED

	# 3. Fusionar sub-mallas estáticas repetitivas de cada bloque de lockers (115 tiradores Pulls + 23 paneles de malla
	#    + 23 divisiones internas -> 3 draw calls por bloque, preservando colisionadores StaticBody3D y gabinetes externos para glow)
	for lroot in locker_roots:
		var pulls_list: Array[MeshInstance3D] = []
		var fence_list: Array[MeshInstance3D] = []
		var inner_list: Array[MeshInstance3D] = []
		var pulls_mat: Material = null
		var fence_mat: Material = null
		var inner_mat: Material = null
		for ch in lroot.find_children("*", "MeshInstance3D", true, false):
			var mi := ch as MeshInstance3D
			if mi == null or not is_instance_valid(mi) or mi.mesh == null or mi.name == "GlowOutlineShell":
				continue
			if str(mi.name).begins_with("MergedLocker"):
				continue
			var m0 := mi.get_active_material(0)
			var m0_l := m0.resource_name.to_lower() if m0 != null else ""
			var p_nm := str(mi.get_parent().name) if mi.get_parent() != null else ""
			if "ZoSideHandle" in p_nm or str(mi.name) == "Geom3D_ZoSideHandle" or "pulls" in m0_l:
				pulls_list.append(mi)
				if pulls_mat == null: pulls_mat = m0
			elif "lockerdiamondmesh" in m0_l or "fencing" in m0_l or "diamond_mesh" in m0_l:
				fence_list.append(mi)
				if fence_mat == null: fence_mat = m0
			elif str(mi.name) == "Geom3D" and "verde" in m0_l:
				inner_list.append(mi)
				if inner_mat == null: inner_mat = m0
		_merge_static_meshes_under(lroot, pulls_list, "MergedLockerPulls", pulls_mat)
		_merge_static_meshes_under(lroot, fence_list, "MergedLockerMeshPanels", fence_mat)
		_merge_static_meshes_under(lroot, inner_list, "MergedLockerInnerDividers", inner_mat)

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
			if mi.get_meta("merged_into_batch", false):
				mi.visible = false
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
				_lod_mesh_items.append({
					"node": mi, "pos": world_center, "max_d2": DIST_MICRO * DIST_MICRO,
					"orig_range": DIST_MICRO, "orig_fade": GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				})
			elif world_diag < LOD_SMALL_DIAG:
				# Tramos de ducto, peldaños, barandillas, pequeños motores
				mi.visibility_range_end = DIST_SMALL
				mi.visibility_range_end_margin = 5.0
				mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				_lod_mesh_items.append({
					"node": mi, "pos": world_center, "max_d2": DIST_SMALL * DIST_SMALL,
					"orig_range": DIST_SMALL, "orig_fade": GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				})
			elif world_diag < LOD_MEDIUM_DIAG:
				# Tolvas intermedias, ciclones, carcasas de maquinaria interior
				mi.visibility_range_end = DIST_MEDIUM
				mi.visibility_range_end_margin = 8.0
				mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				_lod_mesh_items.append({
					"node": mi, "pos": world_center, "max_d2": DIST_MEDIUM * DIST_MEDIUM,
					"orig_range": DIST_MEDIUM, "orig_fade": GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				})
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
			# Sector Nave de Producción: maquinaria, tolvas, molinos al oeste del muro de vestidores (X < -18.2, Z en [18, 52])
			elif c.x < -18.2 and c.z > 18.0 and c.z < 52.0 and d < 35.0 and not str(n3d.name).begins_with("Watson Zone Slot Lockers"):
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

func set_cctv_full_visibility(active: bool) -> void:
	if _cctv_override_active == active:
		return
	_cctv_override_active = active
	if active:
		_apply_cctv_override_visible()
	else:
		for item in _lod_mesh_items:
			var mi := item["node"] as MeshInstance3D
			if mi == null or not is_instance_valid(mi):
				continue
			mi.visibility_range_end = float(item.get("orig_range", DIST_MEDIUM))
			mi.visibility_range_fade_mode = int(item.get("orig_fade", GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF)) as GeometryInstance3D.VisibilityRangeFadeMode
		_current_sector = "INIT"
		var cam := _get_active_camera()
		_update_sector_visibility(true, cam)
		_update_mesh_distance_culling(cam)

func _apply_cctv_override_visible() -> void:
	_current_sector = "CCTV_OVERRIDE"
	_set_nodes_visible(_admin_nodes, true)
	_set_nodes_visible(_nave_nodes, true)
	_set_nodes_visible(_exterior_trucks, true)
	for item in _lod_mesh_items:
		var mi := item["node"] as MeshInstance3D
		if mi == null or not is_instance_valid(mi):
			continue
		if not mi.visible:
			mi.visible = true
		if mi.visibility_range_end != 0.0:
			mi.visibility_range_end = 0.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED

func _process(delta: float) -> void:
	if _cctv_override_active:
		return
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
	if p.x >= -17.9 and p.x <= -13.0 and p.z >= 44.8 and p.z <= 50.2:
		# Vestidores cerrados (muros de concreto/azulejo separan tanto la nave como oficinas)
		new_sector = "VESTIDORES"
	elif p.x <= -13.5 and p.z >= 18.0 and p.z <= 52.0:
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
		"VESTIDORES":
			# Cuarto de lockers cerrado: ocultar tanto oficinas como nave pesada tras muros macizos
			_set_nodes_visible(_admin_nodes, false)
			_set_nodes_visible(_nave_nodes, false)
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
		if _current_sector == "NAVE_PRODUCCION" or _current_sector == "SECTOR_ADMIN" or _current_sector == "VESTIDORES":
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
