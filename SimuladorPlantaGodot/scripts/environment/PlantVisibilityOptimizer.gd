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

const DIST_MICRO: float = 140.0
const DIST_SMALL: float = 200.0
const DIST_MEDIUM: float = 280.0

var _admin_nodes: Array[Node3D] = []
var _nave_nodes: Array[Node3D] = []
var _aux_room_nodes: Array[Node3D] = []
var _nave_lights: Array[Light3D] = []
var _sun_light: DirectionalLight3D = null
var _sun_shadow_orig: bool = true
var _exterior_trucks: Array[Node3D] = []
var _lod_mesh_items: Array[Dictionary] = []

var _current_sector: String = "INIT"
var _timer: float = 0.0
var _camera_ref: Camera3D = null
var _cctv_override_active: bool = false
var _locker_mesh_opaque_mat: StandardMaterial3D = null
var _materials_optimized: bool = false

const _GLOW_PROTECTED_ROOTS: Array[String] = [
	"Group#510", "Node1472", "Node1583", "Node1365", "Group#149",
	"Node1246", "Node2150", "Node2161", "Group#54", "Group#10",
	"Group#501", "Group#689", "Group#14", "Node1179", "Node1313",
	"Node1503", "Node1495", "Node1172", "Node1356", "Node1169",
	"Watson Zone Slot Lockers 20-Pack", "Watson Zone Slot Lockers 20-Pack_1",
	"super saco", "Node1348", "Pallet 60 sacos",
	"PhysicalBreakerPanel", "MotorMillUnit"
]

var _static_batch_nodes_admin: Array[Node3D] = []
var _static_batch_nodes_nave: Array[Node3D] = []
var _static_batch_nodes_aux: Array[Node3D] = []

func _ready() -> void:
	call_deferred("_setup_optimizer")

func _setup_optimizer() -> void:
	var scene_root := get_parent()
	if scene_root == null:
		return
	
	_optimize_plant_materials_and_lockers(scene_root)
	_fix_coplanar_zfighting_and_duplicates(scene_root)
	_apply_lod_and_shadow_bands(scene_root)
	_batch_static_plant_architecture(scene_root)
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
		work.resize(256, 128, Image.INTERPOLATE_BILINEAR)
		var out_img := Image.create(256, 128, false, Image.FORMAT_RGB8)
		for y in range(128):
			for x in range(256):
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

func _merge_static_meshes_under(
	root_node: Node3D,
	sources: Array[MeshInstance3D],
	merged_name: String,
	mat: Material,
	cast_shadow_mode: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
) -> MeshInstance3D:
	if root_node == null or sources.size() < 2:
		return null
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
		return null
	var merged_mesh := st.commit()
	if merged_mesh == null:
		return null
	var merged_mi := MeshInstance3D.new()
	merged_mi.name = merged_name
	merged_mi.mesh = merged_mesh
	if mat != null:
		merged_mi.set_surface_override_material(0, mat)
	merged_mi.cast_shadow = cast_shadow_mode
	root_node.add_child(merged_mi)
	for mi in sources:
		if mi != null and is_instance_valid(mi):
			mi.visible = false
			mi.set_meta("merged_into_batch", true)
			var g_sh := mi.get_node_or_null("GlowOutlineShell") as MeshInstance3D
			if g_sh != null:
				g_sh.visible = false
	return merged_mi

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

	# 3. Fusionar sub-mallas estáticas repetitivas de cada bloque de lockers (tiradores Pulls + paneles de malla
	#    + divisiones internas + gabinetes exteriores -> 4 draw calls y 1 GlowOutlineShell por bloque, preservando StaticBody3D)
	for lroot in locker_roots:
		var pulls_list: Array[MeshInstance3D] = []
		var fence_list: Array[MeshInstance3D] = []
		var inner_list: Array[MeshInstance3D] = []
		var cab_list: Array[MeshInstance3D] = []
		var pulls_mat: Material = null
		var fence_mat: Material = null
		var inner_mat: Material = null
		var cab_mat: Material = null
		for ch in lroot.find_children("*", "MeshInstance3D", true, false):
			var mi := ch as MeshInstance3D
			if mi == null or not is_instance_valid(mi) or mi.mesh == null or mi.name == "GlowOutlineShell":
				continue
			if str(mi.name).begins_with("MergedLocker") or str(mi.name) == "LockerCabinetsBatch":
				continue
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var m0 := mi.get_active_material(0)
			var m0_l := m0.resource_name.to_lower() if m0 != null else ""
			var p_nm := str(mi.get_parent().name) if mi.get_parent() != null else ""
			if "ZoSideHandle" in p_nm or str(mi.name) == "Geom3D_ZoSideHandle" or "pulls" in m0_l:
				pulls_list.append(mi)
				if pulls_mat == null: pulls_mat = m0
			elif "lockerdiamondmesh" in m0_l or "fencing" in m0_l or "diamond_mesh" in m0_l:
				fence_list.append(mi)
				if fence_mat == null: fence_mat = m0
			elif str(mi.name).begins_with("Geom3D_3_WZSLOT"):
				cab_list.append(mi)
				if cab_mat == null: cab_mat = m0
			elif str(mi.name) == "Geom3D" and "verde" in m0_l:
				inner_list.append(mi)
				if inner_mat == null: inner_mat = m0
		_merge_static_meshes_under(lroot, pulls_list, "MergedLockerPulls", pulls_mat)
		_merge_static_meshes_under(lroot, fence_list, "MergedLockerMeshPanels", fence_mat)
		_merge_static_meshes_under(lroot, inner_list, "MergedLockerInnerDividers", inner_mat)
		_merge_static_meshes_under(lroot, cab_list, "LockerCabinetsBatch", cab_mat)

func _is_glow_protected_node(node: Node) -> bool:
	var cur := node
	while cur != null:
		var nm := str(cur.name)
		if _GLOW_PROTECTED_ROOTS.has(nm) or nm.begins_with("Watson Zone Slot Lockers"):
			return true
		if nm == "PlantaCompletaSketchUp" or nm == "MainPlantScene":
			break
		cur = cur.get_parent()
	return false

func _fix_coplanar_zfighting_and_duplicates(scene_root: Node) -> void:
	var plant := scene_root.find_child("PlantaCompletaSketchUp", true, false) as Node3D
	if plant == null:
		return

	# 1. Estratificar capas exteriores coplanares en Y=0.0000 (elimina >3,700 m² de Z-fighting entre pasto, grava y vías)
	for ch in plant.find_children("*", "MeshInstance3D", true, false):
		var mi := ch as MeshInstance3D
		if mi == null or not is_instance_valid(mi) or mi.mesh == null:
			continue
		if mi.get_meta("merged_into_batch", false) or mi.name == "GlowOutlineShell":
			continue
		var m0 := mi.get_active_material(0)
		var mname := m0.resource_name if m0 != null else ""
		var mname_l := mname.to_lower()
		var nm := str(mi.name)

		# Optimizar vidrios translúcidos para evitar Z-fighting con marcos y hojas opacas coplanares
		if m0 is StandardMaterial3D and ("translucent_glass" in mname_l or "glass" in mname_l):
			var gsm := m0 as StandardMaterial3D
			if gsm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				gsm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
				gsm.render_priority = 3

		if nm == "Geom3D312":
			mi.global_position.y -= 0.014 # Pasto base exterior
		elif nm == "Geom3D318":
			mi.global_position.y -= 0.007 # Pasto interior
		elif nm == "Geom3D311":
			mi.global_position.y += 0.002 # Patio de grava Norte sobre el pasto
		elif nm == "Geom3D315" or "adoquin" in mname_l:
			mi.global_position.y += 0.010 # Vías pavimentadas y baldosa sobre grava/pasto
		elif nm == "Geom3D_346":
			mi.global_position.z += 0.006 # Separar par vertical coplanar exacto d=0.000
		elif nm == "Geom3D_356":
			mi.global_position.x += 0.006 # Separar par vertical coplanar d=0.007

	# 2. Eliminar mallas estáticas exactamente superpuestas (duplicados de SketchUp y respaldos opacos coplanares tras vidrio)
	var buckets: Dictionary = {}
	var glass_items: Array[Dictionary] = []
	var untextured_panes: Array[Dictionary] = []

	for ch in plant.find_children("*", "MeshInstance3D", true, false):
		var mi := ch as MeshInstance3D
		if mi == null or not is_instance_valid(mi) or mi.mesh == null or not mi.visible:
			continue
		if mi.name == "GlowOutlineShell" or mi.mesh is ImmediateMesh or mi.get_meta("merged_into_batch", false):
			continue
		if _is_dynamic_or_truck_node(mi):
			continue
		var is_glow_prot := _is_glow_protected_node(mi)
		# En lockers (3_WZSLOT201578R_*) sí depurar cuerpos verdes duplicados idénticos; proteger el resto de máquinas glow
		var is_locker_dup_candidate := str(mi.get_parent().name).begins_with("3_WZSLOT")
		if is_glow_prot and not is_locker_dup_candidate:
			continue
		var box := _calc_node_aabb(mi)
		if box.size.length() < 0.12:
			continue
		var c := box.get_center()
		var m0 := mi.get_active_material(0)
		var mname := m0.resource_name if m0 != null else ""
		var mname_l := mname.to_lower()
		var info := {"mi": mi, "c": c, "sz": box.size, "mat": mname}

		if "translucent_glass" in mname_l:
			glass_items.append(info)
		elif mname == "" and str(mi.name).begins_with("3DGeom-"):
			untextured_panes.append(info)

		var bk := "%s|%d|%d|%d" % [mname, int(round(c.x * 16.0)), int(round(c.y * 16.0)), int(round(c.z * 16.0))]
		if buckets.has(bk):
			var prev: Dictionary = buckets[bk]
			if c.distance_to(prev["c"] as Vector3) < 0.022 and (box.size - (prev["sz"] as Vector3)).length() < 0.030:
				mi.visible = false
				mi.set_meta("dedup_hidden", true)
				continue
		buckets[bk] = info

	# Ocultar hojas opacas sin textura exactamente superpuestas (0.4 mm) a paneles Translucent_Glass_Aqua en ventanas Grupo#35
	for up in untextured_panes:
		var up_mi := up["mi"] as MeshInstance3D
		if not up_mi.visible:
			continue
		var uc: Vector3 = up["c"]
		var usz: Vector3 = up["sz"]
		for gp in glass_items:
			if uc.distance_to(gp["c"] as Vector3) < 0.015 and (usz - (gp["sz"] as Vector3)).length() < 0.025:
				up_mi.visible = false
				up_mi.set_meta("dedup_hidden", true)
				break

func _batch_static_plant_architecture(scene_root: Node) -> void:
	_static_batch_nodes_admin.clear()
	_static_batch_nodes_nave.clear()
	_static_batch_nodes_aux.clear()
	var plant := scene_root.find_child("PlantaCompletaSketchUp", true, false) as Node3D
	if plant == null:
		return
	var batch_host := plant.get_node_or_null("StaticBatches") as Node3D
	if batch_host != null:
		return
	batch_host = Node3D.new()
	batch_host.name = "StaticBatches"
	plant.add_child(batch_host)

	var groups: Dictionary = {}
	for ch in plant.find_children("*", "MeshInstance3D", true, false):
		var mi := ch as MeshInstance3D
		if mi == null or not is_instance_valid(mi) or mi.mesh == null or not mi.visible:
			continue
		if mi.name == "GlowOutlineShell" or mi.mesh is ImmediateMesh:
			continue
		if mi.get_meta("merged_into_batch", false) or mi.get_meta("dedup_hidden", false):
			continue
		if str(mi.name).begins_with("MergedLocker") or str(mi.name) == "LockerCabinetsBatch" or str(mi.name).begins_with("StaticBatch_"):
			continue
		if _is_dynamic_or_truck_node(mi) or _is_glow_protected_node(mi):
			continue
		if mi.mesh.get_surface_count() != 1:
			continue
		var mat := mi.get_active_material(0)
		if not (mat is StandardMaterial3D):
			continue
		var sm := mat as StandardMaterial3D
		if sm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			continue

		var box := _calc_node_aabb(mi)
		var c := box.get_center()
		var d := box.size.length()
		# Solo agrupar mallas estáticas pequeñas/medianas en celdas compactas de 16 m para preservar frustum culling + LOD
		if d > 10.0:
			continue
		var sector := "EXTERIOR"
		if c.x > 12.0 and d < 55.0:
			sector = "ADMIN"
		elif c.x < -18.2 and c.z > 18.0 and c.z < 52.0 and d < 35.0:
			sector = "NAVE"
		elif box.position.x >= -13.4 and box.end.x <= 12.0 and c.z > 24.0 and c.z < 50.5 and d < 25.0:
			sector = "AUX"

		var cell_x := int(floor(c.x / 16.0))
		var cell_z := int(floor(c.z / 16.0))
		var lod_band := 3
		if d < LOD_MICRO_DIAG:
			lod_band = 0
		elif d < LOD_SMALL_DIAG:
			lod_band = 1
		elif d < LOD_MEDIUM_DIAG:
			lod_band = 2
		var sh_key := 1 if mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF else 0
		var gkey := "%s|%d|%d|%d|%d|%d" % [sector, cell_x, cell_z, lod_band, sm.get_instance_id(), sh_key]
		if not groups.has(gkey):
			groups[gkey] = {"sector": sector, "lod": lod_band, "mat": sm, "shadow": mi.cast_shadow, "list": [] as Array[MeshInstance3D]}
		(groups[gkey]["list"] as Array[MeshInstance3D]).append(mi)

	var batch_idx := 0
	for gkey in groups.keys():
		var g: Dictionary = groups[gkey]
		var src_list: Array[MeshInstance3D] = g["list"]
		if src_list.size() < 4:
			continue
		batch_idx += 1
		var sector_tag: String = str(g["sector"])
		var b_mi := _merge_static_meshes_under(
			batch_host,
			src_list,
			"StaticBatch_%s_%03d" % [sector_tag, batch_idx],
			g["mat"] as Material,
			g["shadow"] as GeometryInstance3D.ShadowCastingSetting
		)
		if b_mi != null:
			var lb: int = int(g["lod"])
			if lb == 0:
				b_mi.visibility_range_end = DIST_MICRO
				b_mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			elif lb == 1:
				b_mi.visibility_range_end = DIST_SMALL
				b_mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			elif lb == 2:
				b_mi.visibility_range_end = DIST_MEDIUM
				b_mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			else:
				b_mi.visibility_range_end = 0.0
				b_mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
			if sector_tag == "ADMIN":
				_static_batch_nodes_admin.append(b_mi)
			elif sector_tag == "NAVE":
				_static_batch_nodes_nave.append(b_mi)
			elif sector_tag == "AUX":
				_static_batch_nodes_aux.append(b_mi)

	# Purgar del array LOD las mallas recién fusionadas para ahorrar iteración CPU en _process
	var pruned_lod: Array[Dictionary] = []
	for item in _lod_mesh_items:
		var lmi := item["node"] as MeshInstance3D
		if lmi != null and is_instance_valid(lmi) and not lmi.get_meta("merged_into_batch", false) and not lmi.get_meta("dedup_hidden", false):
			pruned_lod.append(item)
	_lod_mesh_items = pruned_lod

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
			if mi.get_meta("merged_into_batch", false) or mi.get_meta("dedup_hidden", false):
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
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
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
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				_lod_mesh_items.append({
					"node": mi, "pos": world_center, "max_d2": DIST_SMALL * DIST_SMALL,
					"orig_range": DIST_SMALL, "orig_fade": GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				})
			elif world_diag < LOD_MEDIUM_DIAG:
				# Tolvas intermedias, ciclones, carcasas de maquinaria interior
				mi.visibility_range_end = DIST_MEDIUM
				mi.visibility_range_end_margin = 8.0
				mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
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
	_aux_room_nodes.clear()
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
			var nm_s := str(n3d.name)
			
			# Sector Administrativo: bloque de oficinas, salas, cubículos (X > 12.0)
			if c.x > 12.0 and d < 55.0:
				_admin_nodes.append(n3d)
			# Sector Nave de Producción: maquinaria, tolvas, molinos al oeste del muro de vestidores (X < -18.2, Z en [18, 52])
			elif c.x < -18.2 and c.z > 18.0 and c.z < 52.0 and d < 35.0 and not nm_s.begins_with("Watson Zone Slot Lockers"):
				_nave_nodes.append(n3d)
			# Cuartos auxiliares/baños/lockers secundarios al Este del muro macizo de Vestidores (X >= -13.4, X <= 12.0)
			elif aabb.position.x >= -13.4 and aabb.end.x <= 12.0 and c.z > 24.0 and c.z < 50.5 and d < 28.0 and nm_s != "Watson Zone Slot Lockers 20-Pack" and nm_s != "Watson Zone Slot Lockers 20-Pack_1":
				_aux_room_nodes.append(n3d)
	
	var mill_unit := scene_root.find_child("MotorMillUnit", true, false) as Node3D
	if mill_unit != null:
		_nave_nodes.append(mill_unit)
	for ab in _static_batch_nodes_admin:
		if is_instance_valid(ab) and not _admin_nodes.has(ab):
			_admin_nodes.append(ab)
	for nb in _static_batch_nodes_nave:
		if is_instance_valid(nb) and not _nave_nodes.has(nb):
			_nave_nodes.append(nb)
	for axb in _static_batch_nodes_aux:
		if is_instance_valid(axb) and not _aux_room_nodes.has(axb):
			_aux_room_nodes.append(axb)

	# Registrar luces de nave y sol para ahorrar sombreado/sombras al estar en cuarto cerrado de Vestidores
	_nave_lights.clear()
	_sun_light = scene_root.find_child("SunLight", true, false) as DirectionalLight3D
	if _sun_light != null:
		_sun_shadow_orig = _sun_light.shadow_enabled
	for ln in ["HighBay_5000K_1", "HighBay_5000K_2", "HighBay_5000K_3", "HighBay_5000K_4", "HighBay_Spot_Milling", "LightCenter", "LightWest", "LightEast"]:
		var lt := scene_root.find_child(ln, true, false) as Light3D
		if lt != null and not _nave_lights.has(lt):
			_nave_lights.append(lt)

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
	_set_nodes_visible(_aux_room_nodes, true)
	_set_nodes_visible(_exterior_trucks, true)
	_set_vestidores_light_mode(false)
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
		var should_be_vis: bool = (d2 <= max_d2)
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
	if p.x >= -16.95 and p.x <= -12.6 and p.z >= 44.8 and p.z <= 48.95:
		# Vestidores cerrados (estrictamente dentro del cuarto de lockers sin invadir pasillo ni patio)
		new_sector = "VESTIDORES"
	elif p.x <= -13.5 and p.z >= 18.0 and p.z <= 52.0:
		new_sector = "NAVE_PRODUCCION"
	elif p.x >= 13.5 and p.x <= 41.5 and p.z >= 21.0 and p.z <= 50.5:
		new_sector = "SECTOR_ADMIN"
	elif p.x > 8.0:
		new_sector = "EXTERIOR_EAST"
	elif p.x < -8.0:
		new_sector = "EXTERIOR_WEST"
	else:
		new_sector = "EXTERIOR"
		
	if new_sector == _current_sector and not force:
		# Actualizar culling de camiones por distancia
		_update_trucks_visibility(p)
		return
		
	_current_sector = new_sector
	
	match _current_sector:
		"VESTIDORES":
			# Vestidores tiene puerta/ventanas hacia la nave y patio: nunca desaparecer maquinaria ni luces
			_set_nodes_visible(_admin_nodes, false)
			_set_nodes_visible(_nave_nodes, true)
			_set_nodes_visible(_aux_room_nodes, true)
			_set_vestidores_light_mode(false)
		"NAVE_PRODUCCION":
			# Ocultar oficinas administrativas lejanas; mantener maquinaria y cuartos adyacentes con ventanas visibles
			_set_nodes_visible(_admin_nodes, false)
			_set_nodes_visible(_nave_nodes, true)
			_set_nodes_visible(_aux_room_nodes, true)
			_set_vestidores_light_mode(false)
		"SECTOR_ADMIN":
			# Dentro de oficinas administrativas cerradas: ocultar maquinaria pesada de la nave
			_set_nodes_visible(_admin_nodes, true)
			_set_nodes_visible(_nave_nodes, false)
			_set_nodes_visible(_aux_room_nodes, false)
			_set_vestidores_light_mode(false)
		"EXTERIOR_EAST":
			# En exteriores mantener visibles tolvas/bandas exteriores y maquinaria sin pop-in al caminar por los patios
			_set_nodes_visible(_admin_nodes, true)
			_set_nodes_visible(_nave_nodes, true)
			_set_nodes_visible(_aux_room_nodes, true)
			_set_vestidores_light_mode(false)
		"EXTERIOR_WEST":
			_set_nodes_visible(_admin_nodes, false)
			_set_nodes_visible(_nave_nodes, true)
			_set_nodes_visible(_aux_room_nodes, true)
			_set_vestidores_light_mode(false)
		_:
			# Patio central: todo visible sin pop-in
			_set_nodes_visible(_admin_nodes, true)
			_set_nodes_visible(_nave_nodes, true)
			_set_nodes_visible(_aux_room_nodes, true)
			_set_vestidores_light_mode(false)
			
	_update_trucks_visibility(p)

func _set_vestidores_light_mode(in_vestidores: bool) -> void:
	for lt in _nave_lights:
		if lt != null and is_instance_valid(lt) and lt.visible == in_vestidores:
			lt.visible = not in_vestidores
	if _sun_light != null and is_instance_valid(_sun_light):
		var want_sh: bool = false if in_vestidores else _sun_shadow_orig
		if _sun_light.shadow_enabled != want_sh:
			_sun_light.shadow_enabled = want_sh

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
		if _current_sector == "SECTOR_ADMIN":
			want_vis = (cam_pos.distance_to(trk.global_position) <= 65.0)
		else:
			# Mantener visibles los camiones desde vestidores/ventanas/patios sin desapariciones
			want_vis = (cam_pos.distance_to(trk.global_position) <= 180.0)
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
