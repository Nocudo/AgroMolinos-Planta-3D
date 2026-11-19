class_name PlantSpatialBuilder
extends Node3D

# ==============================================================================
# CONSTRUCTOR ESPACIAL DE PLANTA: SUELO FÍSICO, COLISIONES TRIMESH & ZONAS RETIE
# Bloque 1 - Proyecto Final Máquinas Eléctricas (AgroMolinos del Valle S.A.)
# ==============================================================================

const InteractiveDoorScript = preload("res://scripts/interactive/InteractiveDoor.gd")

@export var max_plant_colliders: int = 850
@export var min_mesh_size_for_collision: float = 1.4

var generated_colliders_count: int = 0
var active_zones: Dictionary = {}
var _hazard_zone_bounds: Dictionary = {}
var _hazard_alert_cooldown_ms: Dictionary = {}
var _player_ref: Node3D = null
var _last_crossed_active: bool = false
var _last_crossed_zone_id: String = ""

const HAZARD_LINE_ZONES: Dictionary = {
	"Zone1_Milling_OSHA": {
		"title": "⚠ ZONA 1 · PELIGRO MECÁNICO",
		"msg": "Perímetro molienda 10 HP. Retrocede a pasillo."
	},
	"Zone2_CCM460V_RETIE": {
		"title": "⚡ ZONA 2 · RIESGO 460 V",
		"msg": "Despeje 1 m RETIE. Aplica LOTO."
	},
	"Zone6_DispatchBay": {
		"title": "⚠ ZONA 6 · BAHÍA DESCARGA",
		"msg": "Maniobra de camiones. Mantén distancia."
	},
	"Zone8_IntakeConveyor_OSHA": {
		"title": "⚠ ZONA DE DESCARGA Y CAMIÓN",
		"msg": "Perímetro de camión y bandas de descarga. Mantén distancia."
	},
	"Zone9_AirThermal_OSHA": {
		"title": "⚠ ZONA 9 · AIRE & TÉRMICA",
		"msg": "Horno, soplador y extracción. Mantén distancia."
	}
}

const ZONE_DESCRIPTIONS: Dictionary = {
	"Zone1_Milling_OSHA": "Zona 1: Molienda 10 HP",
	"Zone2_CCM460V_RETIE": "Zona 2: Tablero CCM 460 V",
	"Zone3_ReceptionHopper_ISO": "Zona 3: Recepción y Tolva",
	"Zone4_PedestrianWalkway_OSHA": "Zona 4: Pasillo Central",
	"Zone5_WarehouseRacks": "Zona 5: Almacén Sacos",
	"Zone6_DispatchBay": "Zona 6: Bahía Descarga",
	"Zone7_ATEX_DustZone": "Zona 7: Atmósfera ATEX 22",
	"Zone8_IntakeConveyor_OSHA": "Zona de Descarga: Camión y Bandas",
	"Zone9_AirThermal_OSHA": "Zona 9: Aire y Térmica"
}

const SKIP_COLLISION_KEYWORDS: Array[String] = [
	"roll-up door", "puertas", "puerta", "porton", "auto door", "1m gear rack",
	"concreto rampa", "groundcover_gravel", "grama",
	"activity 4", "ske4b", "hseat", "futsi", "plychai", "winglass",
	"ncdot", "node1506", "node1575", "node1577", "node1579", "node1658", "node1660", "node1662"
]

func _ready() -> void:
	_setup_physical_floor()
	_apply_industrial_floor_safety_shaders()
	_connect_safety_zones()

	# Buscar el modelo importado de la planta en la escena padre para puertas y colisiones
	var parent_node := get_parent()
	if parent_node != null:
		var plant_model := parent_node.find_child("PlantaCompletaSketchUp", true, false) as Node3D
		if plant_model != null:
			_remove_static_human_models(plant_model)
			_setup_interactive_doors(plant_model)
			generate_plant_collisions(plant_model)

func _setup_physical_floor() -> void:
	var floor_body := get_node_or_null("SueloFisicoPBR") as StaticBody3D
	if floor_body == null:
		return

	# Material físico antideslizante OSHA (fricción = 0.85)
	if floor_body.physics_material_override == null:
		var phys_mat := PhysicsMaterial.new()
		phys_mat.friction = 0.85
		phys_mat.rough = true
		floor_body.physics_material_override = phys_mat

	# Configurar exterior simple de pradera verde (Llanos), vía de acceso asfaltada
	# y colinas suaves en el horizonte alrededor de la parcela sin tocar primitivas prohibidas.
	var floor_mesh := floor_body.get_node_or_null("FloorMesh") as MeshInstance3D
	if floor_mesh != null:
		floor_mesh.position.y = 0.46
		if floor_mesh.mesh is PlaneMesh:
			var plane_mesh := (floor_mesh.mesh as PlaneMesh).duplicate() as PlaneMesh
			plane_mesh.size = Vector2(2200.0, 2200.0)
			plane_mesh.subdivide_width = 160
			plane_mesh.subdivide_depth = 160
			floor_mesh.mesh = plane_mesh
			floor_mesh.material_override = _create_simple_exterior_material()

func _create_simple_exterior_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode cull_back;

varying vec3 v_world_pos;

float hash2(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash2(i);
	float b = hash2(i + vec2(1.0, 0.0));
	float c = hash2(i + vec2(0.0, 1.0));
	float d = hash2(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float hill_height(vec2 xz) {
	float d_x = max(0.0, abs(xz.x) - 135.0);
	float d_z = max(0.0, abs(xz.y) - 135.0);
	float d_parcel = length(vec2(d_x, d_z));
	float hill_mask = smoothstep(20.0, 420.0, d_parcel);
	// Llanura suavemente ondulada con corredor vial amplio sin trincheras ni taludes abruptos
	float road_ns_clear = smoothstep(24.0, 145.0, abs(xz.x - 82.5));
	float macro_hills = (sin(xz.x * 0.0055 + 0.6) * cos(xz.y * 0.0050 - 0.3) * 0.5 + 0.5) * 18.0
		+ vnoise(xz * 0.0048 + vec2(3.1, 7.4)) * 14.0;
	return macro_hills * hill_mask * road_ns_clear;
}

void vertex() {
	vec3 wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h0 = hill_height(wpos.xz);
	VERTEX.y += h0;
	float hx = hill_height(wpos.xz + vec2(12.0, 0.0));
	float hz = hill_height(wpos.xz + vec2(0.0, 12.0));
	NORMAL = normalize(vec3(h0 - hx, 12.0, h0 - hz));
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 xz = v_world_pos.xz;
	float n_macro = vnoise(xz * 0.024);
	float n_med = vnoise(xz * 0.14);
	float n_detail = vnoise(xz * 0.62);
	float n_micro = vnoise(xz * 2.8);

	// 1. Pradera verde sabana natural con variación multi-escala
	vec3 grass_deep = vec3(0.22, 0.37, 0.16);
	vec3 grass_warm = vec3(0.34, 0.48, 0.21);
	vec3 grass_dry = vec3(0.41, 0.40, 0.24);
	vec3 col = mix(grass_deep, grass_warm, n_macro * 0.65 + n_med * 0.35);
	col = mix(col, grass_dry, smoothstep(0.58, 0.90, n_detail) * 0.28);
	col *= 0.90 + n_micro * 0.15;
	float rough = 0.94;

	// 2. Collar suave de grava y pasto de transición bordeando la parcela
	float box_dist = max(abs(xz.x) - 75.5, abs(xz.y) - 75.5);
	float gravel_band = smoothstep(-1.5, 0.0, box_dist) * (1.0 - smoothstep(2.0, 5.5, box_dist));
	vec3 gravel_col = vec3(0.42, 0.41, 0.38) * (0.88 + n_micro * 0.20);
	col = mix(col, gravel_col, gravel_band * 0.72);

	// 3. Base epóxica/concreto limpia bajo la nave y patios interiores
	if (abs(xz.x) < 46.0 && xz.y > 12.0 && xz.y < 54.0) {
		col = vec3(0.24, 0.25, 0.26) * (0.94 + n_micro * 0.10);
		rough = 0.72;
	}

	// 4. Carretera N-S exterior en X=82.5 con acceso directo a Portería (Z=38, X=56..82.5)
	float dist_ns = abs(xz.x - 82.5);
	float in_ew = smoothstep(55.0, 56.5, xz.x) * (1.0 - smoothstep(81.5, 83.0, xz.x));
	float dist_ew = mix(100.0, abs(xz.y - 38.0), in_ew);
	float road_dist = min(dist_ns, dist_ew);

	float shoulder_mask = 1.0 - smoothstep(4.6, 6.4, road_dist);
	col = mix(col, gravel_col, shoulder_mask);

	float asphalt_mask = 1.0 - smoothstep(4.2, 4.6, road_dist);
	vec3 asphalt_col = vec3(0.16, 0.17, 0.19) * (0.90 + n_micro * 0.16);
	col = mix(col, asphalt_col, asphalt_mask);
	rough = mix(rough, 0.84, asphalt_mask);

	// Líneas viales (borde blanco y eje amarillo discontinuo)
	float edge_line = smoothstep(3.82, 3.92, road_dist) * (1.0 - smoothstep(4.02, 4.12, road_dist));
	float dash_ns = step(0.45, fract(xz.y * 0.16)) * (1.0 - smoothstep(0.10, 0.18, dist_ns));
	float dash_ew = step(0.45, fract(xz.x * 0.16)) * (1.0 - smoothstep(0.10, 0.18, dist_ew)) * in_ew;
	float center_dash = max(dash_ns, dash_ew) * step(5.0, max(abs(xz.x - 82.5), abs(xz.y - 38.0)));
	col = mix(col, vec3(0.82, 0.84, 0.86), edge_line * asphalt_mask * 0.85);
	col = mix(col, vec3(0.86, 0.68, 0.15), center_dash * 0.90);

	ALBEDO = col;
	ROUGHNESS = rough;
	METALLIC = 0.0;
	SPECULAR = 0.12;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	return mat

func _setup_interactive_doors(plant_node: Node3D) -> void:
	if plant_node == null:
		return
	var candidates := plant_node.find_children("*", "Node3D", true, false)
	var claimed_roots: Array[Node] = []
	for child in candidates:
		var root := child as Node3D
		if root == null or _has_claimed_ancestor(root, claimed_roots):
			continue
		var lname := root.name.to_lower()
		if "xref" in lname:
			continue
		var is_puertas := lname.begins_with("puertas")
		var is_double_sec := lname.begins_with("puerta doble")
		var is_single_sec := lname.begins_with("puerta de seguridad")
		var is_rollup := lname.begins_with("roll-up door")
		var is_porton := lname.begins_with("porton automatico parcela")
		if not (is_puertas or is_double_sec or is_single_sec or is_rollup or is_porton):
			continue
		if _collect_meshes(root).is_empty():
			continue
		claimed_roots.append(root)
		if is_puertas:
			_build_puertas_door(root)
		elif is_double_sec:
			_build_double_security_door(root)
		elif is_single_sec:
			_build_single_security_door(root)
		elif is_rollup:
			_build_roll_up_door(root)
		elif is_porton:
			_build_sliding_gate_door(root)

func _has_claimed_ancestor(node: Node, claimed_roots: Array[Node]) -> bool:
	var curr := node.get_parent()
	while curr != null:
		if curr in claimed_roots:
			return true
		curr = curr.get_parent()
	return false

func _unwrap_container(root: Node3D) -> Node3D:
	var curr: Node3D = root
	for _depth in range(4):
		var n3d_kids: Array[Node3D] = []
		for ch in curr.get_children():
			if ch is Node3D:
				n3d_kids.append(ch as Node3D)
		if n3d_kids.size() == 1 and not (n3d_kids[0] is MeshInstance3D):
			curr = n3d_kids[0]
		else:
			break
	return curr

func _collect_meshes(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		out.append(node as MeshInstance3D)
	for ch in node.get_children():
		out.append_array(_collect_meshes(ch))
	return out

func _get_world_aabb(node: Node3D) -> AABB:
	var meshes := _collect_meshes(node)
	if meshes.is_empty():
		return AABB(node.global_position, Vector3.ZERO)
	var has_bounds := false
	var world_box := AABB()
	for mi in meshes:
		if mi.mesh == null:
			continue
		var local_box := mi.mesh.get_aabb()
		var xf := mi.global_transform
		for corner_idx in range(8):
			var p := Vector3(
				local_box.position.x + (local_box.size.x if (corner_idx & 1) != 0 else 0.0),
				local_box.position.y + (local_box.size.y if (corner_idx & 2) != 0 else 0.0),
				local_box.position.z + (local_box.size.z if (corner_idx & 4) != 0 else 0.0)
			)
			var wp := xf * p
			if not has_bounds:
				world_box = AABB(wp, Vector3.ZERO)
				has_bounds = true
			else:
				world_box = world_box.expand(wp)
	return world_box if has_bounds else AABB(node.global_position, Vector3.ZERO)

func _find_largest_mesh(node: Node3D) -> MeshInstance3D:
	var best: MeshInstance3D = null
	var best_vol: float = -1.0
	for mi in _collect_meshes(node):
		var box := _get_world_aabb(mi)
		var vol := box.size.x * box.size.y * box.size.z
		if vol > best_vol:
			best_vol = vol
			best = mi
	return best

func _signed_angle_xz(from_xz: Vector2, to_xz: Vector2) -> float:
	if from_xz.length_squared() < 1e-8 or to_xz.length_squared() < 1e-8:
		return 0.0
	var u := from_xz.normalized()
	var v := to_xz.normalized()
	return atan2(u.y * v.x - u.x * v.y, u.dot(v))

func _dist_point_to_seg_2d(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 1e-8:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)

func _extract_panel_xz_geometry(mi: MeshInstance3D) -> Dictionary:
	var pts: Array[Vector2] = []
	var mean := Vector2.ZERO
	var min_y := INF
	var max_y := -INF
	if mi != null and mi.mesh != null:
		var xf := mi.global_transform
		for s in range(mi.mesh.get_surface_count()):
			var arr := mi.mesh.surface_get_arrays(s)
			if arr.size() <= Mesh.ARRAY_VERTEX:
				continue
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			for v in verts:
				var w := xf * v
				var p2 := Vector2(w.x, w.z)
				pts.append(p2)
				mean += p2
				min_y = minf(min_y, w.y)
				max_y = maxf(max_y, w.y)
	if pts.is_empty():
		var b := _get_world_aabb(mi) if mi != null else AABB()
		var c := Vector2(b.get_center().x, b.get_center().z)
		var dir_fb := Vector2(1.0, 0.0) if b.size.x >= b.size.z else Vector2(0.0, 1.0)
		var half_l := maxf(b.size.x, b.size.z) * 0.5
		return {
			"valid": false, "end0": c - dir_fb * half_l, "end1": c + dir_fb * half_l,
			"center": c, "dir": dir_fb, "len": half_l * 2.0, "thk": minf(b.size.x, b.size.z),
			"min_y": b.position.y, "max_y": b.end.y
		}
	mean /= float(pts.size())
	var cxx := 0.0
	var czz := 0.0
	var cxz := 0.0
	for p in pts:
		var d := p - mean
		cxx += d.x * d.x
		czz += d.y * d.y
		cxz += d.x * d.y
	var theta := 0.5 * atan2(2.0 * cxz, cxx - czz)
	var dir := Vector2(cos(theta), sin(theta))
	var perp := Vector2(-dir.y, dir.x)
	var min_u := INF
	var max_u := -INF
	var min_v := INF
	var max_v := -INF
	for p in pts:
		var d := p - mean
		var u := d.dot(dir)
		var v := d.dot(perp)
		min_u = minf(min_u, u)
		max_u = maxf(max_u, u)
		min_v = minf(min_v, v)
		max_v = maxf(max_v, v)
	var mid_v := 0.5 * (min_v + max_v)
	var e0 := mean + dir * min_u + perp * mid_v
	var e1 := mean + dir * max_u + perp * mid_v
	return {
		"valid": true,
		"end0": e0,
		"end1": e1,
		"center": 0.5 * (e0 + e1),
		"dir": dir,
		"len": max_u - min_u,
		"thk": max_v - min_v,
		"min_y": min_y,
		"max_y": max_y
	}

func _create_door_node(parent_root: Node3D, world_center: Vector3, label_prefix: String) -> InteractiveDoorScript:
	var door: InteractiveDoorScript = InteractiveDoorScript.new()
	door.name = "Door_%s" % parent_root.name.validate_node_name()
	door.door_label = label_prefix
	parent_root.add_child(door)
	door.global_position = world_center
	door.global_basis = Basis.IDENTITY
	return door

func _build_aligned_single_hinged_door(
	root: Node3D,
	frame_node: Node3D,
	leaf_node: Node3D,
	label_prefix: String,
	explicit_hinge_2d: Vector2,
	has_explicit_hinge: bool
) -> void:
	var frame_panel := _find_largest_mesh(frame_node)
	var leaf_panel := _find_largest_mesh(leaf_node)
	if frame_panel == null or leaf_panel == null:
		return

	var f_geo := _extract_panel_xz_geometry(frame_panel)
	var l_geo := _extract_panel_xz_geometry(leaf_panel)
	var f_e0: Vector2 = f_geo["end0"]
	var f_e1: Vector2 = f_geo["end1"]
	var f_center_2d: Vector2 = f_geo["center"]
	var l_e0: Vector2 = l_geo["end0"]
	var l_e1: Vector2 = l_geo["end1"]

	# Identificar el extremo real de bisagra en la hoja (el más cercano a las bisagras o al marco)
	var d0 := l_e0.distance_to(explicit_hinge_2d) if has_explicit_hinge else _dist_point_to_seg_2d(l_e0, f_e0, f_e1)
	var d1 := l_e1.distance_to(explicit_hinge_2d) if has_explicit_hinge else _dist_point_to_seg_2d(l_e1, f_e0, f_e1)
	var leaf_hinge_2d: Vector2 = l_e0 if d0 <= d1 else l_e1
	var leaf_free_2d: Vector2 = l_e1 if d0 <= d1 else l_e0

	# Identificar la jamba de bisagra del marco y el vector exacto de cierre paralelo al plano real del marco
	var frame_hinge_2d: Vector2 = f_e0 if leaf_hinge_2d.distance_to(f_e0) <= leaf_hinge_2d.distance_to(f_e1) else f_e1
	var frame_latch_2d: Vector2 = f_e1 if frame_hinge_2d == f_e0 else f_e0

	var u_leaf := (leaf_free_2d - leaf_hinge_2d).normalized()
	var v_close := (frame_latch_2d - frame_hinge_2d).normalized()
	var closed_angle := _signed_angle_xz(u_leaf, v_close)
	var swing_sign := -signf(closed_angle) if absf(closed_angle) > deg_to_rad(10.0) else 1.0
	var open_angle := closed_angle + swing_sign * deg_to_rad(90.0)

	var f_center_3d := Vector3(f_center_2d.x, 0.5 * (float(f_geo["min_y"]) + float(f_geo["max_y"])), f_center_2d.y)
	var hinge_pos_3d := Vector3(leaf_hinge_2d.x, float(f_geo["min_y"]), leaf_hinge_2d.y)

	var door: InteractiveDoorScript = _create_door_node(root, f_center_3d, label_prefix)
	var pivot := Node3D.new()
	pivot.name = "HingePivot"
	door.add_child(pivot)
	pivot.global_position = hinge_pos_3d
	pivot.global_basis = Basis.IDENTITY
	leaf_node.reparent(pivot, true)

	# Cerrar exactamente paralelo al marco y ajustar el asiento del pivote para centrado milimétrico en la jamba
	pivot.rotation.y = closed_angle
	var closed_geo := _extract_panel_xz_geometry(leaf_panel)
	var shift_2d: Vector2 = f_center_2d - (closed_geo["center"] as Vector2)
	pivot.global_position += Vector3(shift_2d.x, 0.0, shift_2d.y)

	# Sellar cualquier holgura excesiva del CAD entre marco y hoja (p. ej. puertas de seguridad 0.99 m en vano 1.17 m)
	var inner_frame_len := maxf(float(f_geo["len"]) - 0.06, 0.4)
	var cur_leaf_len := maxf(float(closed_geo["len"]), 0.1)
	if inner_frame_len > cur_leaf_len + 0.03:
		var fit_ratio := clampf(inner_frame_len / cur_leaf_len, 1.0, 1.28)
		var fit_node := Node3D.new()
		fit_node.name = "LeafWidthFit"
		pivot.add_child(fit_node)
		var span_dir_3d := Vector3(v_close.x, 0.0, v_close.y).normalized()
		var perp_3d := Vector3(-v_close.y, 0.0, v_close.x).normalized()
		fit_node.global_transform = Transform3D(Basis(span_dir_3d, Vector3.UP, perp_3d), Vector3(f_center_2d.x, float(f_geo["min_y"]), f_center_2d.y))
		leaf_node.reparent(fit_node, true)
		fit_node.scale = Vector3(fit_ratio, 1.0, 1.0)
		var post_geo := _extract_panel_xz_geometry(leaf_panel)
		var post_shift: Vector2 = f_center_2d - (post_geo["center"] as Vector2)
		pivot.global_position += Vector3(post_shift.x, 0.0, post_shift.y)

	var f_aabb := _get_world_aabb(frame_panel)
	var blocker_size := Vector3(
		maxf(f_aabb.size.x, 0.16),
		maxf(float(f_geo["max_y"]) - float(f_geo["min_y"]), 1.95),
		maxf(f_aabb.size.z, 0.16)
	)
	door.configure_hinged_single(label_prefix, pivot, closed_angle, open_angle, f_center_3d, blocker_size)

func _build_puertas_door(root: Node3D) -> void:
	var container := _unwrap_container(root)
	var kids: Array[Node3D] = []
	for ch in container.get_children():
		if ch is Node3D and not _collect_meshes(ch).is_empty():
			kids.append(ch as Node3D)
	if kids.size() < 2:
		return

	var leaf_node: Node3D = kids[0]
	var frame_node: Node3D = kids[1]
	if _collect_meshes(kids[1]).size() > _collect_meshes(kids[0]).size():
		leaf_node = kids[1]
		frame_node = kids[0]

	_build_aligned_single_hinged_door(root, frame_node, leaf_node, "Puerta", Vector2.ZERO, false)

func _build_single_security_door(root: Node3D) -> void:
	var container := _unwrap_container(root)
	var hinge_pts: Array[Vector3] = []
	var tall_kids: Array[Node3D] = []
	for ch in container.get_children():
		var n3d := ch as Node3D
		if n3d == null or _collect_meshes(n3d).is_empty():
			continue
		var box := _get_world_aabb(n3d)
		if box.size.y < 0.45:
			hinge_pts.append(box.get_center())
		else:
			tall_kids.append(n3d)
	if tall_kids.size() < 2:
		return

	# En puertas de seguridad, el marco siempre tiene mayor altura total (≈ +5 cm) que la hoja
	var frame_node: Node3D = tall_kids[0]
	var leaf_node: Node3D = tall_kids[1]
	var h0 := _get_world_aabb(tall_kids[0]).size.y
	var h1 := _get_world_aabb(tall_kids[1]).size.y
	if h1 > h0 + 0.01:
		frame_node = tall_kids[1]
		leaf_node = tall_kids[0]

	var has_hinge := not hinge_pts.is_empty()
	var hinge_2d := Vector2.ZERO
	if has_hinge:
		var avg := Vector3.ZERO
		for pt in hinge_pts:
			avg += pt
		avg /= float(hinge_pts.size())
		hinge_2d = Vector2(avg.x, avg.z)

	_build_aligned_single_hinged_door(root, frame_node, leaf_node, "Puerta de Seguridad", hinge_2d, has_hinge)

func _build_double_security_door(root: Node3D) -> void:
	var container := _unwrap_container(root)
	var kids: Array[Node3D] = []
	for ch in container.get_children():
		var n3d := ch as Node3D
		if n3d != null and not _collect_meshes(n3d).is_empty():
			kids.append(n3d)
	if kids.size() < 3:
		return

	# El nodo de menos mallas (y mayor altura total) es el marco
	kids.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return _collect_meshes(a).size() < _collect_meshes(b).size()
	)
	var frame_node := kids[0]
	var leaf_a := kids[1]
	var leaf_b := kids[2]

	var frame_panel := _find_largest_mesh(frame_node)
	var panel_a := _find_largest_mesh(leaf_a)
	var panel_b := _find_largest_mesh(leaf_b)
	if frame_panel == null or panel_a == null or panel_b == null:
		return

	var f_geo := _extract_panel_xz_geometry(frame_panel)
	var f_dir: Vector2 = f_geo["dir"]
	var f_perp := Vector2(-f_dir.y, f_dir.x)
	var f_center_2d: Vector2 = f_geo["center"]
	var f_center := Vector3(f_center_2d.x, 0.5 * (float(f_geo["min_y"]) + float(f_geo["max_y"])), f_center_2d.y)
	var f_aabb := _get_world_aabb(frame_panel)

	var la_geo := _extract_panel_xz_geometry(panel_a)
	var lb_geo := _extract_panel_xz_geometry(panel_b)
	var da := ((la_geo["center"] as Vector2) - f_center_2d).dot(f_perp)
	var db := ((lb_geo["center"] as Vector2) - f_center_2d).dot(f_perp)
	var best_out := da if absf(da) > absf(db) else db
	var outward_dir := f_perp * (signf(best_out) if absf(best_out) > 0.03 else 1.0)

	var door: InteractiveDoorScript = _create_door_node(root, f_center, "Puerta Doble")
	var data_a := _setup_double_leaf(door, "PivotA", leaf_a, panel_a, f_geo, outward_dir)
	var data_b := _setup_double_leaf(door, "PivotB", leaf_b, panel_b, f_geo, outward_dir)
	door.configure_hinged_double(
		"Puerta Doble de Seguridad",
		data_a["pivot"], data_a["closed"], data_a["open"], data_a["center"], data_a["size"],
		data_b["pivot"], data_b["closed"], data_b["open"], data_b["center"], data_b["size"],
		f_center, Vector3(maxf(f_aabb.size.x, 0.3), float(f_geo["max_y"]) - float(f_geo["min_y"]), maxf(f_aabb.size.z, 0.3))
	)

func _setup_double_leaf(
	door,
	pivot_name: String,
	leaf_node: Node3D,
	leaf_panel: MeshInstance3D,
	f_geo: Dictionary,
	outward_dir: Vector2
) -> Dictionary:
	var f_e0: Vector2 = f_geo["end0"]
	var f_e1: Vector2 = f_geo["end1"]
	var f_center_2d: Vector2 = f_geo["center"]
	var l_geo := _extract_panel_xz_geometry(leaf_panel)
	var l_e0: Vector2 = l_geo["end0"]
	var l_e1: Vector2 = l_geo["end1"]
	var l_c: Vector2 = l_geo["center"]

	var frame_hinge_2d: Vector2 = f_e0 if l_c.distance_to(f_e0) <= l_c.distance_to(f_e1) else f_e1
	var leaf_hinge_2d: Vector2 = l_e0 if l_e0.distance_to(frame_hinge_2d) <= l_e1.distance_to(frame_hinge_2d) else l_e1
	var leaf_free_2d: Vector2 = l_e1 if leaf_hinge_2d == l_e0 else l_e0

	var u_leaf := (leaf_free_2d - leaf_hinge_2d).normalized()
	var v_close := (f_center_2d - frame_hinge_2d).normalized()
	var closed_angle := _signed_angle_xz(u_leaf, v_close)
	var raw_open := _signed_angle_xz(u_leaf, outward_dir)
	var arc := wrapf(raw_open - closed_angle, -PI, PI)
	var open_angle := closed_angle + arc

	var pivot := Node3D.new()
	pivot.name = pivot_name
	door.add_child(pivot)
	pivot.global_position = Vector3(leaf_hinge_2d.x, float(f_geo["min_y"]), leaf_hinge_2d.y)
	pivot.global_basis = Basis.IDENTITY
	leaf_node.reparent(pivot, true)

	pivot.rotation.y = closed_angle
	var closed_geo := _extract_panel_xz_geometry(leaf_panel)
	var half_clear_len := maxf(float(f_geo["len"]) * 0.5 - 0.035, 0.4)
	var cur_len := maxf(float(closed_geo["len"]), 0.1)
	var target_center_2d: Vector2 = f_center_2d - v_close * (half_clear_len * 0.5 + 0.003)
	var shift_2d: Vector2 = target_center_2d - (closed_geo["center"] as Vector2)
	pivot.global_position += Vector3(shift_2d.x, 0.0, shift_2d.y)
	if half_clear_len > cur_len + 0.025:
		var fit_ratio := clampf(half_clear_len / cur_len, 1.0, 1.25)
		var fit_node := Node3D.new()
		fit_node.name = "LeafWidthFit"
		pivot.add_child(fit_node)
		var span_dir_3d := Vector3(v_close.x, 0.0, v_close.y).normalized()
		var perp_3d := Vector3(-v_close.y, 0.0, v_close.x).normalized()
		fit_node.global_transform = Transform3D(Basis(span_dir_3d, Vector3.UP, perp_3d), Vector3(target_center_2d.x, float(f_geo["min_y"]), target_center_2d.y))
		leaf_node.reparent(fit_node, true)
		fit_node.scale = Vector3(fit_ratio, 1.0, 1.0)
		var post_geo := _extract_panel_xz_geometry(leaf_panel)
		var post_shift: Vector2 = target_center_2d - (post_geo["center"] as Vector2)
		pivot.global_position += Vector3(post_shift.x, 0.0, post_shift.y)

	var closed_aabb := _get_world_aabb(leaf_panel)
	return {
		"pivot": pivot,
		"closed": closed_angle,
		"open": open_angle,
		"center": closed_aabb.get_center(),
		"size": closed_aabb.size,
	}

func _build_roll_up_door(root: Node3D) -> void:
	var curtain_node: Node3D = null
	var full_box := _get_world_aabb(root)
	var best_score := 1e9
	for ch in root.get_children():
		var n3d := ch as Node3D
		if n3d == null:
			continue
		var meshes := _collect_meshes(n3d)
		if meshes.is_empty():
			continue
		var box := _get_world_aabb(n3d)
		if box.size.y < 1.8:
			continue
		var footprint := box.size.x * box.size.z + float(meshes.size()) * 0.25
		if footprint < best_score:
			best_score = footprint
			curtain_node = n3d
	if curtain_node == null:
		return

	var c_box := _get_world_aabb(curtain_node)
	var top_anchor := Vector3(c_box.get_center().x, c_box.end.y, c_box.get_center().z)
	var switch_pos := Vector3(
		full_box.position.x + (0.25 if full_box.size.x > full_box.size.z else full_box.size.x * 0.5),
		full_box.position.y + 1.25,
		full_box.get_center().z if full_box.size.x > full_box.size.z else full_box.position.z + 0.25
	)
	var door: InteractiveDoorScript = _create_door_node(root, c_box.get_center(), "Cortina Metálica")
	var pivot := Node3D.new()
	pivot.name = "CurtainPivot"
	door.add_child(pivot)
	pivot.global_position = top_anchor
	pivot.global_basis = Basis.IDENTITY
	curtain_node.reparent(pivot, true)
	door.configure_roll_up("Cortina Metálica", pivot, c_box.get_center(), c_box.size, switch_pos)

func _build_sliding_gate_door(root: Node3D) -> void:
	var full_box := _get_world_aabb(root)
	var gate_center := full_box.get_center()
	var motor_pos := Vector3(full_box.get_center().x, full_box.position.y + 1.25, full_box.end.z - 0.35)
	var moving_children: Array[Node3D] = []
	for ch in root.get_children():
		var n3d := ch as Node3D
		if n3d == null or _collect_meshes(n3d).is_empty():
			continue
		var cn := n3d.name.to_lower()
		if "motor" in cn or "auto door" in cn or "roller" in cn:
			if "motor" in cn or "auto door" in cn:
				motor_pos = _get_world_aabb(n3d).get_center() + Vector3(0.0, 0.75, 0.0)
			continue
		moving_children.append(n3d)
	if moving_children.is_empty():
		return

	var door: InteractiveDoorScript = _create_door_node(root, gate_center, "Portón Vehicular")
	var pivot := Node3D.new()
	pivot.name = "SlidePivot"
	door.add_child(pivot)
	pivot.global_position = gate_center
	pivot.global_basis = Basis.IDENTITY
	for mch in moving_children:
		mch.reparent(pivot, true)

	var slide_dist := clampf(full_box.size.z * 0.86, 5.5, 7.6)
	door.configure_sliding_z("Portón Vehicular", pivot, Vector3(0.0, 0.0, slide_dist), gate_center, full_box.size, motor_pos)

func generate_plant_collisions(plant_node: Node3D) -> int:
	generated_colliders_count = 0
	if plant_node == null:
		return 0

	var door_pts: Array[Vector3] = []
	if is_inside_tree():
		for dn in get_tree().get_nodes_in_group("interactive_doors"):
			if dn is Node3D:
				door_pts.append((dn as Node3D).global_position)

	var meshes := plant_node.find_children("*", "MeshInstance3D", true, false)
	for child in meshes:
		if generated_colliders_count >= max_plant_colliders:
			break
		var mesh_inst := child as MeshInstance3D
		if mesh_inst == null or mesh_inst.mesh == null:
			continue
		if _has_static_body_child(mesh_inst):
			continue

		var world_aabb: AABB = mesh_inst.global_transform * mesh_inst.mesh.get_aabb()

		# Acera/andén inclinado Oeste (Groundcover_Gravel en X<-40, Z>15): losas BoxShape3D escalonadas suaves (0 trimesh)
		if world_aabb.position.x <= -42.0 and world_aabb.end.z >= 35.0 and world_aabb.end.y <= 0.60 and world_aabb.size.z >= 15.0:
			var is_west_gravel := false
			for s_i in range(mesh_inst.mesh.get_surface_count()):
				var sm_g := mesh_inst.mesh.surface_get_material(s_i)
				if sm_g != null and "groundcover_gravel" in sm_g.resource_name.to_lower():
					is_west_gravel = true
					break
			if is_west_gravel:
				if _add_ground_box_colliders(mesh_inst) > 0:
					generated_colliders_count += 1
				continue

		var longest: float = world_aabb.get_longest_axis_size()
		if longest < min_mesh_size_for_collision:
			continue
		if world_aabb.position.y > 3.2:
			continue
		if world_aabb.size.x > 34.0 and world_aabb.size.z > 24.0 and world_aabb.size.y > 4.0:
			continue
		if world_aabb.size.y < 0.08 and world_aabb.position.y < 1.5:
			continue
		if world_aabb.end.y <= 0.85 and (world_aabb.size.x >= 10.0 or world_aabb.size.z >= 10.0):
			continue

		if _should_skip_collision_by_name(mesh_inst):
			continue

		# Mallas arquitectónicas compuestas (cuartos, vanos de puertas, escaleras/marcos altos): descomponer en cubos BoxShape3D por tramo real
		var touches_door := false
		var door_test_box := world_aabb.grow(0.45)
		for dp in door_pts:
			if door_test_box.has_point(dp):
				touches_door = true
				break
		var is_compound_shell := (
			touches_door
			or (world_aabb.size.x >= 2.2 and world_aabb.size.z >= 2.2)
			or (world_aabb.size.y >= 2.6 and maxf(world_aabb.size.x, world_aabb.size.z) >= 2.6)
		)
		if is_compound_shell:
			if _add_decomposed_wall_box_colliders(mesh_inst, door_pts) > 0:
				generated_colliders_count += 1
		else:
			_add_single_box_collider(mesh_inst, world_aabb)
			generated_colliders_count += 1

	return generated_colliders_count

func _add_single_box_collider(mesh_inst: MeshInstance3D, world_aabb: AABB) -> void:
	var sb := StaticBody3D.new()
	sb.name = "BoxColliderBody"
	sb.top_level = true
	sb.collision_layer = 1
	sb.collision_mask = 1
	mesh_inst.add_child(sb)
	sb.global_transform = Transform3D(Basis.IDENTITY, world_aabb.get_center())

	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(
		maxf(world_aabb.size.x, 0.08),
		maxf(world_aabb.size.y, 0.08),
		maxf(world_aabb.size.z, 0.08)
	)
	cs.shape = box
	sb.add_child(cs)

func _add_ground_box_colliders(mesh_inst: MeshInstance3D) -> int:
	var m := mesh_inst.mesh
	if m == null:
		return 0
	var xf := mesh_inst.global_transform
	var cell_sz := 1.6
	var cells: Dictionary = {} # Vector2i -> Vector3(min_x, max_y, min_z) / Dictionary
	for s in range(m.get_surface_count()):
		var arr := m.surface_get_arrays(s)
		if arr.size() <= Mesh.ARRAY_VERTEX:
			continue
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for v in verts:
			var wp := xf * v
			if wp.y < -0.15 or wp.y > 0.70:
				continue
			var key := Vector2i(int(floor(wp.x / cell_sz)), int(floor(wp.z / cell_sz)))
			if not cells.has(key):
				cells[key] = wp.y
			elif wp.y > float(cells[key]):
				cells[key] = wp.y
	if cells.is_empty():
		return 0
	var sb := StaticBody3D.new()
	sb.name = "BoxGroundBody"
	sb.top_level = true
	sb.collision_layer = 1
	sb.collision_mask = 1
	mesh_inst.add_child(sb)
	sb.global_transform = Transform3D.IDENTITY
	var count := 0
	for k in cells.keys():
		var ci: Vector2i = k
		var top_y: float = float(cells[k])
		var thick := 0.22
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(cell_sz + 0.08, thick, cell_sz + 0.08)
		cs.shape = box
		cs.position = Vector3((float(ci.x) + 0.5) * cell_sz, top_y - thick * 0.5, (float(ci.y) + 0.5) * cell_sz)
		sb.add_child(cs)
		count += 1
	return count

func _add_decomposed_wall_box_colliders(mesh_inst: MeshInstance3D, door_pts: Array[Vector3]) -> int:
	var m := mesh_inst.mesh
	if m == null:
		return 0
	var xf := mesh_inst.global_transform
	var plane_step := 0.30
	var bin_step := 0.25
	var x_planes: Dictionary = {} # px_key -> { z_bin -> {min_x, max_x, min_y, max_y, min_z, max_z} }
	var z_planes: Dictionary = {} # pz_key -> { x_bin -> {min_x, max_x, min_y, max_y, min_z, max_z} }
	var diag_cells: Dictionary = {} # Vector2i -> AABB

	for s in range(m.get_surface_count()):
		var arr := m.surface_get_arrays(s)
		if arr.size() <= Mesh.ARRAY_VERTEX:
			continue
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx_arr: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr.size() > Mesh.ARRAY_INDEX and arr[Mesh.ARRAY_INDEX] is PackedInt32Array else PackedInt32Array()
		var tri_count := (idx_arr.size() / 3) if idx_arr.size() >= 3 else (verts.size() / 3)
		for t in range(tri_count):
			var i0 := idx_arr[t * 3] if idx_arr.size() >= 3 else (t * 3)
			var i1 := idx_arr[t * 3 + 1] if idx_arr.size() >= 3 else (t * 3 + 1)
			var i2 := idx_arr[t * 3 + 2] if idx_arr.size() >= 3 else (t * 3 + 2)
			if i0 >= verts.size() or i1 >= verts.size() or i2 >= verts.size():
				continue
			var v0 := xf * verts[i0]
			var v1 := xf * verts[i1]
			var v2 := xf * verts[i2]
			var min_y := minf(v0.y, minf(v1.y, v2.y))
			var max_y := maxf(v0.y, maxf(v1.y, v2.y))
			# Solo muros que interceptan la banda caminable del cuerpo (evita dinteles sobre puertas y techos)
			if max_y <= 0.30 or min_y >= 1.92:
				continue
			var n := (v1 - v0).cross(v2 - v0)
			var n_len := n.length()
			# Omitir triángulos minúsculos de barandas/tubos (< 0.10 m²) para evitar muros invisibles sobre escaleras abiertas
			if n_len < 0.20:
				continue
			n /= n_len
			if absf(n.y) >= 0.45:
				continue

			var min_x := minf(v0.x, minf(v1.x, v2.x))
			var max_x := maxf(v0.x, maxf(v1.x, v2.x))
			var min_z := minf(v0.z, minf(v1.z, v2.z))
			var max_z := maxf(v0.z, maxf(v1.z, v2.z))
			var cy_lo := maxf(min_y, 0.0)
			var cy_hi := minf(max_y, 2.25)

			if absf(n.x) >= 0.70:
				var px_key := int(round(((v0.x + v1.x + v2.x) / 3.0) / plane_step))
				if not x_planes.has(px_key):
					x_planes[px_key] = {}
				var z_dict: Dictionary = x_planes[px_key]
				var zb0 := int(floor(min_z / bin_step))
				var zb1 := int(floor(max_z / bin_step))
				for zb in range(zb0, zb1 + 1):
					var cz := (float(zb) + 0.5) * bin_step
					var seg_z0 := maxf(min_z, float(zb) * bin_step)
					var seg_z1 := minf(max_z, float(zb + 1) * bin_step)
					if seg_z1 < seg_z0:
						seg_z0 = cz - bin_step * 0.5
						seg_z1 = cz + bin_step * 0.5
					_accum_bin(z_dict, zb, min_x, max_x, cy_lo, cy_hi, seg_z0, seg_z1)
			elif absf(n.z) >= 0.70:
				var pz_key := int(round(((v0.z + v1.z + v2.z) / 3.0) / plane_step))
				if not z_planes.has(pz_key):
					z_planes[pz_key] = {}
				var x_dict: Dictionary = z_planes[pz_key]
				var xb0 := int(floor(min_x / bin_step))
				var xb1 := int(floor(max_x / bin_step))
				for xb in range(xb0, xb1 + 1):
					var cx := (float(xb) + 0.5) * bin_step
					var seg_x0 := maxf(min_x, float(xb) * bin_step)
					var seg_x1 := minf(max_x, float(xb + 1) * bin_step)
					if seg_x1 < seg_x0:
						seg_x0 = cx - bin_step * 0.5
						seg_x1 = cx + bin_step * 0.5
					_accum_bin(x_dict, xb, seg_x0, seg_x1, cy_lo, cy_hi, min_z, max_z)
			else:
				var cx_d := (v0.x + v1.x + v2.x) / 3.0
				var cz_d := (v0.z + v1.z + v2.z) / 3.0
				var dk := Vector2i(int(floor(cx_d / 0.55)), int(floor(cz_d / 0.55)))
				var tb := AABB(Vector3(min_x, cy_lo, min_z), Vector3(maxf(max_x - min_x, 0.12), maxf(cy_hi - cy_lo, 0.35), maxf(max_z - min_z, 0.12)))
				if not diag_cells.has(dk):
					diag_cells[dk] = tb
				else:
					diag_cells[dk] = (diag_cells[dk] as AABB).merge(tb)

	var boxes: Array[AABB] = []
	for px_key in x_planes.keys():
		_merge_plane_bins(x_planes[px_key], door_pts, true, boxes)
	for pz_key in z_planes.keys():
		_merge_plane_bins(z_planes[pz_key], door_pts, false, boxes)
	for dk in diag_cells.keys():
		var db: AABB = diag_cells[dk]
		if not _box_blocks_doorway(db, door_pts):
			boxes.append(db)

	if boxes.is_empty():
		return 0

	var sb := StaticBody3D.new()
	sb.name = "BoxWallBody"
	sb.top_level = true
	sb.collision_layer = 1
	sb.collision_mask = 1
	mesh_inst.add_child(sb)
	sb.global_transform = Transform3D.IDENTITY

	for b in boxes:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(
			maxf(b.size.x, 0.14),
			maxf(b.size.y, 0.40),
			maxf(b.size.z, 0.14)
		)
		cs.shape = shape
		cs.position = b.get_center()
		sb.add_child(cs)
	return boxes.size()

func _accum_bin(dict: Dictionary, bin_id: int, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float) -> void:
	if not dict.has(bin_id):
		dict[bin_id] = [x0, x1, y0, y1, z0, z1]
	else:
		var a: Array = dict[bin_id]
		if x0 < float(a[0]): a[0] = x0
		if x1 > float(a[1]): a[1] = x1
		if y0 < float(a[2]): a[2] = y0
		if y1 > float(a[3]): a[3] = y1
		if z0 < float(a[4]): a[4] = z0
		if z1 > float(a[5]): a[5] = z1

func _box_blocks_doorway(box: AABB, door_pts: Array[Vector3]) -> bool:
	var c := box.get_center()
	for dp in door_pts:
		if absf(c.y - dp.y) <= 1.8 and Vector2(c.x - dp.x, c.z - dp.z).length() <= 0.56:
			return true
	return false

func _merge_plane_bins(bin_dict: Dictionary, door_pts: Array[Vector3], is_x_wall: bool, out_boxes: Array[AABB]) -> void:
	var keys: Array = bin_dict.keys()
	keys.sort()
	var active := false
	var prev_k := -999999
	var cur: Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

	for k_v in keys:
		var k := int(k_v)
		var a: Array = bin_dict[k]
		var cx := 0.5 * (float(a[0]) + float(a[1]))
		var cy := 0.5 * (float(a[2]) + float(a[3]))
		var cz := 0.5 * (float(a[4]) + float(a[5]))
		# Despejar cualquier bin que invada el centro libre de una puerta interactiva
		var near_door := false
		for dp in door_pts:
			if absf(cy - dp.y) <= 1.8 and Vector2(cx - dp.x, cz - dp.z).length() <= 0.56:
				near_door = true
				break
		if near_door:
			if active:
				_flush_merged_wall_box(cur, is_x_wall, out_boxes)
				active = false
			continue

		if not active:
			cur = a.duplicate()
			active = true
		elif k <= prev_k + 1:
			if float(a[0]) < float(cur[0]): cur[0] = a[0]
			if float(a[1]) > float(cur[1]): cur[1] = a[1]
			if float(a[2]) < float(cur[2]): cur[2] = a[2]
			if float(a[3]) > float(cur[3]): cur[3] = a[3]
			if float(a[4]) < float(cur[4]): cur[4] = a[4]
			if float(a[5]) > float(cur[5]): cur[5] = a[5]
		else:
			_flush_merged_wall_box(cur, is_x_wall, out_boxes)
			cur = a.duplicate()
		prev_k = k

	if active:
		_flush_merged_wall_box(cur, is_x_wall, out_boxes)

func _flush_merged_wall_box(cur: Array, is_x_wall: bool, out_boxes: Array[AABB]) -> void:
	var x0 := float(cur[0]); var x1 := float(cur[1])
	var y0 := float(cur[2]); var y1 := float(cur[3])
	var z0 := float(cur[4]); var z1 := float(cur[5])
	var along_len := (z1 - z0) if is_x_wall else (x1 - x0)
	# Ignorar jambas/cantos diminutos (< 18 cm) en los bordes de vanos para no estrechar puertas ni arcos interiores
	if along_len < 0.18:
		return
	var sx := clampf(x1 - x0, 0.12, 0.40) if is_x_wall else along_len
	var sy := maxf(y1 - y0, 0.55)
	var sz := along_len if is_x_wall else clampf(z1 - z0, 0.12, 0.40)
	var center := Vector3(0.5 * (x0 + x1), 0.5 * (y0 + y1), 0.5 * (z0 + z1))
	out_boxes.append(AABB(center - Vector3(sx, sy, sz) * 0.5, Vector3(sx, sy, sz)))

func _should_skip_collision_by_name(mesh_inst: MeshInstance3D) -> bool:
	var curr: Node = mesh_inst
	while curr != null:
		var lower_name := curr.name.to_lower()
		for kw in SKIP_COLLISION_KEYWORDS:
			if kw in lower_name:
				return true
		if curr.name == "PlantaCompletaSketchUp":
			break
		curr = curr.get_parent()
	if mesh_inst.mesh != null:
		for s in range(mesh_inst.mesh.get_surface_count()):
			var mat := mesh_inst.mesh.surface_get_material(s)
			if mat != null:
				var mname := mat.resource_name.to_lower()
				for kw in SKIP_COLLISION_KEYWORDS:
					if kw in mname:
						return true
	return false

func _has_static_body_child(node: Node) -> bool:
	for c in node.get_children():
		if c is StaticBody3D:
			return true
	return false

func _connect_safety_zones() -> void:
	var zones_root := get_node_or_null("DemarcacionZonas")
	if zones_root == null:
		return
	_hazard_zone_bounds.clear()

	for child in zones_root.get_children():
		if child is Area3D:
			var area := child as Area3D
			var zone_id: String = area.name
			area.monitoring = true
			area.monitorable = true
			if HAZARD_LINE_ZONES.has(zone_id):
				var cs := area.get_node_or_null("CollisionShape3D") as CollisionShape3D
				if cs != null and cs.shape is BoxShape3D:
					var half_ext: Vector3 = (cs.shape as BoxShape3D).size * 0.5
					var center: Vector3 = area.global_position
					_hazard_zone_bounds[zone_id] = {"center": center, "half": half_ext}
			if not area.body_entered.is_connected(_on_zone_body_entered.bind(zone_id)):
				area.body_entered.connect(_on_zone_body_entered.bind(zone_id))
			if not area.body_exited.is_connected(_on_zone_body_exited.bind(zone_id)):
				area.body_exited.connect(_on_zone_body_exited.bind(zone_id))

func _physics_process(_delta: float) -> void:
	if not is_inside_tree() or (get_tree() != null and get_tree().paused):
		return
	if _player_ref == null or not is_instance_valid(_player_ref):
		var cur_scene := get_tree().current_scene if get_tree() != null else null
		if cur_scene != null:
			_player_ref = cur_scene.get_node_or_null("PlayerOperator") as Node3D
		if _player_ref == null and get_parent() != null and get_parent().get_parent() != null:
			_player_ref = get_parent().get_parent().get_node_or_null("PlayerOperator") as Node3D
		if _player_ref == null and get_tree() != null and get_tree().root != null:
			_player_ref = get_tree().root.find_child("PlayerOperator", true, false) as Node3D
	if _player_ref != null and is_instance_valid(_player_ref):
		evaluate_player_hazard_lines(_player_ref.global_position)

func evaluate_player_hazard_lines(player_pos: Vector3) -> String:
	var entered_id := ""
	for zid_v in HAZARD_LINE_ZONES.keys():
		var zid := str(zid_v)
		var b_info: Dictionary = _hazard_zone_bounds.get(zid, {})
		if b_info.is_empty():
			continue
		var c: Vector3 = b_info["center"] as Vector3
		var h: Vector3 = b_info["half"] as Vector3
		var inside_xz := absf(player_pos.x - c.x) <= h.x and absf(player_pos.z - c.z) <= h.z
		var inside_y := player_pos.y >= (c.y - 0.5) and player_pos.y <= (c.y + h.y * 2.0 + 0.5)
		var is_inside := inside_xz and inside_y
		_set_zone_presence(zid, is_inside)
		if is_inside and entered_id == "":
			entered_id = zid
	return entered_id

func _set_zone_presence(zone_id: String, is_inside: bool) -> void:
	var was_inside := bool(active_zones.get(zone_id, false))
	if was_inside == is_inside:
		return
	var bus = get_node_or_null("/root/EventBus")
	if is_inside:
		active_zones[zone_id] = true
		var zone_name: String = ZONE_DESCRIPTIONS.get(zone_id, zone_id)
		if bus != null and bus.has_signal("safety_zone_entered"):
			bus.safety_zone_entered.emit(zone_id, zone_name)
		if HAZARD_LINE_ZONES.has(zone_id):
			# Emitir únicamente safety_line_crossed para evitar triple notificación duplicada en HUD/Tablet
			_sync_safety_line_crossed_signal(bus)
	else:
		active_zones.erase(zone_id)
		if bus != null and bus.has_signal("safety_zone_exited"):
			bus.safety_zone_exited.emit(zone_id)
		if HAZARD_LINE_ZONES.has(zone_id):
			_sync_safety_line_crossed_signal(bus)

func _sync_safety_line_crossed_signal(bus) -> void:
	var active_hz := ""
	for zid_v in HAZARD_LINE_ZONES.keys():
		var zid := str(zid_v)
		if bool(active_zones.get(zid, false)):
			active_hz = zid
			break
	var next_active := (active_hz != "")
	if next_active == _last_crossed_active and active_hz == _last_crossed_zone_id:
		return
	_last_crossed_active = next_active
	_last_crossed_zone_id = active_hz
	if bus != null and bus.has_signal("safety_line_crossed"):
		if next_active:
			var hz: Dictionary = HAZARD_LINE_ZONES[active_hz]
			bus.safety_line_crossed.emit(true, active_hz, str(hz["title"]), str(hz["msg"]))
		else:
			bus.safety_line_crossed.emit(false, "", "", "")

func _on_zone_body_entered(body: Node3D, zone_id: String) -> void:
	if not (body is CharacterBody3D) or body.name != "PlayerOperator":
		return
	_set_zone_presence(zone_id, true)

func _on_zone_body_exited(body: Node3D, zone_id: String) -> void:
	if not (body is CharacterBody3D) or body.name != "PlayerOperator":
		return
	_set_zone_presence(zone_id, false)

func is_player_in_zone(zone_id: String) -> bool:
	return bool(active_zones.get(zone_id, false))

func is_player_past_safety_lines() -> bool:
	for zid_v in HAZARD_LINE_ZONES.keys():
		if bool(active_zones.get(str(zid_v), false)):
			return true
	return false

func _remove_static_human_models(plant_model: Node3D) -> void:
	# Elimina modelos sobrantes/humanos estáticos de SketchUp verificando materiales o nombre explícito
	# (sin tocar Node1440..1443 cuando corresponden a rodillos reales del molino Node1365 en la planta modificada).
	const HUMAN_MAT_KW := ["fig03", "fig33", "ske4b", "hseat", "linda", "derrick", "christina", "bryce", "sophie", "activity 4"]
	var to_remove: Array[Node] = []
	var comp33 := plant_model.find_child("Component#33", true, false)
	if comp33 != null and is_instance_valid(comp33):
		to_remove.append(comp33)
	for ch in plant_model.find_children("*", "MeshInstance3D", true, false):
		var mi := ch as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var is_human := false
		for s in range(mi.mesh.get_surface_count()):
			var mat := mi.mesh.surface_get_material(s)
			if mat == null:
				continue
			var mn := mat.resource_name.to_lower()
			for kw in HUMAN_MAT_KW:
				if kw in mn:
					is_human = true
					break
			if is_human:
				break
		if is_human:
			to_remove.append(mi)
	for n in to_remove:
		if not is_instance_valid(n):
			continue
		if n is Node3D:
			(n as Node3D).visible = false
		for sb in n.find_children("*", "CollisionObject3D", true, false):
			if sb is CollisionObject3D:
				(sb as CollisionObject3D).collision_layer = 0
				(sb as CollisionObject3D).collision_mask = 0
		if n.get_parent() != null:
			n.get_parent().remove_child(n)
		n.queue_free()

func _apply_industrial_floor_safety_shaders() -> void:
	var zones_root := get_node_or_null("DemarcacionZonas")
	if zones_root == null:
		return

	var sh_hazard := Shader.new()
	sh_hazard.code = """shader_type spatial;
render_mode cull_back, blend_mix, depth_draw_never;
uniform vec3 stripe_color : source_color = vec3(0.98, 0.78, 0.08);
uniform vec3 base_tint : source_color = vec3(0.95, 0.72, 0.08);
uniform vec2 zone_size = vec2(8.0, 6.0);
uniform float border_width = 0.28;
uniform float stripe_freq = 4.2;
uniform float inner_alpha = 0.24;
uniform float fault_pulse = 0.0;
uniform vec3 laser_color : source_color = vec3(1.0, 0.09, 0.07);
uniform float conform_north_pad = 0.0;

void vertex() {
	if (conform_north_pad > 0.5) {
		vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		if (wp.x >= -40.50 && wp.x <= -26.75 && wp.z >= 48.80 && wp.z <= 53.25) {
			VERTEX.y += 0.095;
		}
	}
}

void fragment() {
	vec2 p = UV * zone_size;
	float d_edge = min(min(p.x, zone_size.x - p.x), min(p.y, zone_size.y - p.y));
	float is_border = step(d_edge, border_width);
	float inner_line = smoothstep(border_width + 0.03, border_width + 0.06, d_edge) * (1.0 - smoothstep(border_width + 0.09, border_width + 0.12, d_edge));
	float laser_line = smoothstep(border_width + 0.10, border_width + 0.14, d_edge) * (1.0 - smoothstep(border_width + 0.18, border_width + 0.22, d_edge));
	float diag = fract((p.x + p.y) * stripe_freq);
	float stripe = step(0.50, diag);
	vec3 hazard_col = mix(vec3(0.06, 0.06, 0.07), stripe_color, stripe);
	float is_fault = step(0.5, fault_pulse);
	float pulse = is_fault * (0.78 + 0.22 * sin(TIME * 6.0));
	vec3 col = mix(base_tint, hazard_col, max(is_border, inner_line * 0.75));
	col = mix(col, laser_color, laser_line * is_fault);
	ALBEDO = col;
	EMISSION = col * (0.28 * is_border) + laser_color * (2.6 * laser_line * pulse);
	ALPHA = mix(inner_alpha, 0.96, clamp(is_border + inner_line + laser_line * is_fault, 0.0, 1.0));
}
"""

	var sh_walkway := Shader.new()
	sh_walkway.code = """shader_type spatial;
render_mode cull_back, blend_mix, depth_draw_never;
uniform vec3 lane_color : source_color = vec3(0.11, 0.52, 0.22);
uniform vec3 line_color : source_color = vec3(0.98, 0.84, 0.18);
uniform vec2 zone_size = vec2(1.9, 22.0);
uniform float is_corridor = 1.0;

void fragment() {
	vec2 p = UV * zone_size;
	float dx = min(p.x, zone_size.x - p.x);
	float dz = min(p.y, zone_size.y - p.y);
	float d_edge = min(dx, dz);
	float outer_line = (is_corridor > 0.5) ? step(dx, 0.12) : step(d_edge, 0.14);
	float double_line = (is_corridor > 0.5) ? (step(0.18, dx) * step(dx, 0.24)) : 0.0;
	float center_dash = (is_corridor > 0.5) ? (step(abs(p.x - zone_size.x * 0.5), 0.045) * step(0.45, fract(p.y * 0.75))) : 0.0;
	vec3 line_col = mix(vec3(0.95, 0.97, 0.98), line_color, step(0.5, outer_line));
	float mask = clamp(outer_line + double_line * 0.85 + center_dash * 0.7, 0.0, 1.0);
	ALBEDO = mix(lane_color, line_col, mask);
	EMISSION = mix(lane_color * 0.12, line_col * 0.22, mask);
	ALPHA = mix(0.42, 0.94, mask);
}
"""

	var zone_cfg: Dictionary = {
		"Zone1_Milling_OSHA": {"type": "hazard", "size": Vector2(9.3, 23.5), "stripe": Color(0.98, 0.78, 0.06), "tint": Color(0.96, 0.72, 0.10), "bw": 0.30, "alpha": 0.12, "y": 0.016, "rp": 1},
		"Zone2_CCM460V_RETIE": {"type": "hazard", "size": Vector2(1.7, 2.6), "stripe": Color(0.98, 0.18, 0.15), "tint": Color(0.88, 0.15, 0.15), "bw": 0.22, "alpha": 0.30, "y": 0.024, "rp": 3},
		"Zone8_IntakeConveyor_OSHA": {"type": "hazard", "size": Vector2(18.4, 5.6), "stripe": Color(0.98, 0.78, 0.06), "tint": Color(0.95, 0.72, 0.10), "bw": 0.34, "alpha": 0.16, "y": 0.024, "rp": 2, "conform_north_pad": 1.0},
		"Zone9_AirThermal_OSHA": {"type": "hazard", "size": Vector2(9.2, 10.0), "stripe": Color(0.98, 0.76, 0.06), "tint": Color(0.96, 0.56, 0.08), "bw": 0.28, "alpha": 0.16, "y": 0.026, "rp": 2},
		"Zone4_PedestrianWalkway_OSHA": {"type": "walkway", "size": Vector2(1.75, 24.5), "lane": Color(0.10, 0.56, 0.24), "line": Color(0.98, 0.86, 0.20), "corridor": 1.0, "y": 0.020, "rp": 2}
	}

	for child in zones_root.get_children():
		var decal := child.get_node_or_null("FloorDecal") as MeshInstance3D
		if decal == null:
			continue
		if not zone_cfg.has(child.name):
			decal.visible = false
			continue
		decal.visible = true
		decal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var cfg: Dictionary = zone_cfg[child.name]
		decal.position.y = float(cfg["y"])
		var sm := ShaderMaterial.new()
		sm.render_priority = int(cfg["rp"])
		if cfg["type"] == "hazard":
			sm.shader = sh_hazard
			sm.set_shader_parameter("zone_size", cfg["size"])
			sm.set_shader_parameter("stripe_color", cfg["stripe"])
			sm.set_shader_parameter("base_tint", cfg["tint"])
			sm.set_shader_parameter("border_width", float(cfg["bw"]))
			sm.set_shader_parameter("inner_alpha", float(cfg["alpha"]))
			sm.set_shader_parameter("conform_north_pad", float(cfg.get("conform_north_pad", 0.0)))
		else:
			sm.shader = sh_walkway
			sm.set_shader_parameter("zone_size", cfg["size"])
			sm.set_shader_parameter("lane_color", cfg["lane"])
			sm.set_shader_parameter("line_color", cfg["line"])
			sm.set_shader_parameter("is_corridor", float(cfg["corridor"]))
		decal.material_override = sm
