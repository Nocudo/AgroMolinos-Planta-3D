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
		"title": "⚠ ZONA 6 · BAHÍA CARGA",
		"msg": "Maniobra de camiones. Mantén distancia."
	},
	"Zone8_IntakeConveyor_OSHA": {
		"title": "⚠ ZONA 8 · BANDAS EXTERIORES",
		"msg": "Perímetro tolva. Usa selección remota."
	}
}

const ZONE_DESCRIPTIONS: Dictionary = {
	"Zone1_Milling_OSHA": "Zona 1: Molienda 10 HP",
	"Zone2_CCM460V_RETIE": "Zona 2: Tablero CCM 460 V",
	"Zone3_ReceptionHopper_ISO": "Zona 3: Recepción y Tolva",
	"Zone4_PedestrianWalkway_OSHA": "Zona 4: Pasillo Central",
	"Zone5_WarehouseRacks": "Zona 5: Almacén Sacos",
	"Zone6_DispatchBay": "Zona 6: Bahía Despacho",
	"Zone7_ATEX_DustZone": "Zona 7: Atmósfera ATEX 22",
	"Zone8_IntakeConveyor_OSHA": "Zona 8: Bandas Exteriores"
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

func _create_door_node(parent_root: Node3D, world_center: Vector3, label_prefix: String) -> InteractiveDoorScript:
	var door: InteractiveDoorScript = InteractiveDoorScript.new()
	door.name = "Door_%s" % parent_root.name.validate_node_name()
	door.door_label = label_prefix
	parent_root.add_child(door)
	door.global_position = world_center
	door.global_basis = Basis.IDENTITY
	return door

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

	var leaf_panel := _find_largest_mesh(leaf_node)
	if leaf_panel == null:
		return
	var f_aabb := _get_world_aabb(frame_node)
	var l_aabb := _get_world_aabb(leaf_panel)
	var f_center := f_aabb.get_center()
	var l_center := l_aabb.get_center()

	var hinge_pos := Vector3(f_center.x, f_aabb.position.y, f_center.z)
	var v_close := Vector2.ZERO
	if f_aabb.size.x > f_aabb.size.z:
		hinge_pos.x = clampf(l_center.x, f_aabb.position.x + 0.02, f_aabb.end.x - 0.02)
		v_close = Vector2(signf(f_center.x - hinge_pos.x), 0.0)
	else:
		hinge_pos.z = clampf(l_center.z, f_aabb.position.z + 0.02, f_aabb.end.z - 0.02)
		v_close = Vector2(0.0, signf(f_center.z - hinge_pos.z))

	var u_glb := Vector2(l_center.x - hinge_pos.x, l_center.z - hinge_pos.z)
	var closed_angle := _signed_angle_xz(u_glb, v_close)
	var open_angle := 0.0

	var door: InteractiveDoorScript = _create_door_node(root, f_center, "Puerta")
	var pivot := Node3D.new()
	pivot.name = "HingePivot"
	door.add_child(pivot)
	pivot.global_position = hinge_pos
	pivot.global_basis = Basis.IDENTITY
	leaf_node.reparent(pivot, true)

	pivot.rotation.y = closed_angle
	var closed_aabb := _get_world_aabb(leaf_panel)
	door.configure_hinged_single("Puerta", pivot, closed_angle, open_angle, closed_aabb.get_center(), closed_aabb.size)

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

	var frame_node: Node3D = tall_kids[0]
	var leaf_node: Node3D = tall_kids[1]
	if _collect_meshes(tall_kids[0]).size() > _collect_meshes(tall_kids[1]).size():
		leaf_node = tall_kids[0]
		frame_node = tall_kids[1]

	var leaf_panel := _find_largest_mesh(leaf_node)
	if leaf_panel == null:
		return
	var f_aabb := _get_world_aabb(frame_node)
	var l_aabb := _get_world_aabb(leaf_panel)
	var f_center := f_aabb.get_center()
	var l_center := l_aabb.get_center()

	var hinge_pos := Vector3(f_center.x, f_aabb.position.y, f_center.z)
	if not hinge_pts.is_empty():
		var avg := Vector3.ZERO
		for pt in hinge_pts:
			avg += pt
		avg /= float(hinge_pts.size())
		hinge_pos.x = avg.x
		hinge_pos.z = avg.z

	var v_close := (
		Vector2(signf(f_center.x - hinge_pos.x), 0.0)
		if f_aabb.size.x > f_aabb.size.z
		else Vector2(0.0, signf(f_center.z - hinge_pos.z))
	)
	var delta_c := Vector2(l_center.x - hinge_pos.x, l_center.z - hinge_pos.z)
	var u_glb := (
		Vector2(signf(delta_c.x), 0.0)
		if absf(delta_c.x) >= absf(delta_c.y)
		else Vector2(0.0, signf(delta_c.y))
	)
	var closed_angle := _signed_angle_xz(u_glb, v_close)
	var open_angle := 0.0

	var door: InteractiveDoorScript = _create_door_node(root, f_center, "Puerta de Seguridad")
	var pivot := Node3D.new()
	pivot.name = "HingePivot"
	door.add_child(pivot)
	pivot.global_position = hinge_pos
	pivot.global_basis = Basis.IDENTITY
	leaf_node.reparent(pivot, true)

	pivot.rotation.y = closed_angle
	var blocker_size := Vector3(
		maxf(f_aabb.size.x, 0.16),
		maxf(f_aabb.size.y, 1.95),
		maxf(f_aabb.size.z, 0.16)
	)
	door.configure_hinged_single("Puerta de Seguridad", pivot, closed_angle, open_angle, f_center, blocker_size)

func _build_double_security_door(root: Node3D) -> void:
	var container := _unwrap_container(root)
	var kids: Array[Node3D] = []
	for ch in container.get_children():
		var n3d := ch as Node3D
		if n3d != null and not _collect_meshes(n3d).is_empty():
			kids.append(n3d)
	if kids.size() < 3:
		return

	# Smallest mesh-count full-span node is the frame
	kids.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return _collect_meshes(a).size() < _collect_meshes(b).size()
	)
	var frame_node := kids[0]
	var leaf_a := kids[1]
	var leaf_b := kids[2]

	var f_aabb := _get_world_aabb(frame_node)
	var f_center := f_aabb.get_center()
	var span_x := f_aabb.size.x > f_aabb.size.z

	# Discover outward swing normal from whichever leaf starts ajar in the GLB
	var panel_a := _find_largest_mesh(leaf_a)
	var panel_b := _find_largest_mesh(leaf_b)
	if panel_a == null or panel_b == null:
		return
	var ca := _get_world_aabb(panel_a).get_center()
	var cb := _get_world_aabb(panel_b).get_center()
	var outward_dir := Vector2(0.0, 1.0) if span_x else Vector2(1.0, 0.0)
	if span_x:
		var da := ca.z - f_center.z
		var db := cb.z - f_center.z
		var best := da if absf(da) > absf(db) else db
		if absf(best) > 0.04:
			outward_dir = Vector2(0.0, signf(best))
	else:
		var da := ca.x - f_center.x
		var db := cb.x - f_center.x
		var best := da if absf(da) > absf(db) else db
		if absf(best) > 0.04:
			outward_dir = Vector2(signf(best), 0.0)

	var door: InteractiveDoorScript = _create_door_node(root, f_center, "Puerta Doble")
	var data_a := _setup_double_leaf(door, "PivotA", leaf_a, panel_a, f_aabb, span_x, outward_dir)
	var data_b := _setup_double_leaf(door, "PivotB", leaf_b, panel_b, f_aabb, span_x, outward_dir)
	door.configure_hinged_double(
		"Puerta Doble de Seguridad",
		data_a["pivot"], data_a["closed"], data_a["open"], data_a["center"], data_a["size"],
		data_b["pivot"], data_b["closed"], data_b["open"], data_b["center"], data_b["size"],
		f_center, Vector3(maxf(f_aabb.size.x, 0.3), f_aabb.size.y, maxf(f_aabb.size.z, 0.3))
	)

func _setup_double_leaf(
	door,
	pivot_name: String,
	leaf_node: Node3D,
	leaf_panel: MeshInstance3D,
	f_aabb: AABB,
	span_x: bool,
	outward_dir: Vector2
) -> Dictionary:
	var f_center := f_aabb.get_center()
	var l_center := _get_world_aabb(leaf_panel).get_center()
	var hinge_pos := Vector3(f_center.x, f_aabb.position.y, f_center.z)
	if span_x:
		var near_min := absf(l_center.x - f_aabb.position.x) < absf(l_center.x - f_aabb.end.x)
		hinge_pos.x = (f_aabb.position.x + 0.04) if near_min else (f_aabb.end.x - 0.04)
	else:
		var near_min := absf(l_center.z - f_aabb.position.z) < absf(l_center.z - f_aabb.end.z)
		hinge_pos.z = (f_aabb.position.z + 0.04) if near_min else (f_aabb.end.z - 0.04)

	var u_glb := Vector2(l_center.x - hinge_pos.x, l_center.z - hinge_pos.z)
	var v_close := (
		Vector2(signf(f_center.x - hinge_pos.x), 0.0)
		if span_x
		else Vector2(0.0, signf(f_center.z - hinge_pos.z))
	)
	var closed_angle := _signed_angle_xz(u_glb, v_close)
	var raw_open := _signed_angle_xz(u_glb, outward_dir)
	var arc := wrapf(raw_open - closed_angle, -PI, PI)
	var open_angle := closed_angle + arc

	var pivot := Node3D.new()
	pivot.name = pivot_name
	door.add_child(pivot)
	pivot.global_position = hinge_pos
	pivot.global_basis = Basis.IDENTITY
	leaf_node.reparent(pivot, true)

	pivot.rotation.y = closed_angle
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

		mesh_inst.create_trimesh_collision()
		generated_colliders_count += 1

	return generated_colliders_count

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
		var parent_n := get_parent()
		if parent_n != null:
			_player_ref = parent_n.find_child("PlayerOperator", true, false) as Node3D
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
			var hz: Dictionary = HAZARD_LINE_ZONES[zone_id]
			var title: String = str(hz["title"])
			var msg: String = str(hz["msg"])
			var now_ms: int = Time.get_ticks_msec()
			var last_ms: int = int(_hazard_alert_cooldown_ms.get(zone_id, -999999))
			if now_ms - last_ms >= 2200:
				_hazard_alert_cooldown_ms[zone_id] = now_ms
				if bus != null and bus.has_signal("notification_posted"):
					bus.notification_posted.emit(title, msg, "error")
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
render_mode cull_back, blend_mix, depth_draw_opaque;
uniform vec3 stripe_color : source_color = vec3(0.98, 0.78, 0.08);
uniform vec3 base_tint : source_color = vec3(0.95, 0.72, 0.08);
uniform vec2 zone_size = vec2(8.0, 6.0);
uniform float border_width = 0.28;
uniform float stripe_freq = 4.2;
uniform float inner_alpha = 0.24;
uniform float fault_pulse = 0.0;
uniform vec3 laser_color : source_color = vec3(1.0, 0.09, 0.07);

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
render_mode cull_back, blend_mix, depth_draw_opaque;
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
		"Zone1_Milling_OSHA": {"type": "hazard", "size": Vector2(9.3, 23.5), "stripe": Color(0.98, 0.78, 0.06), "tint": Color(0.96, 0.72, 0.10), "bw": 0.30, "alpha": 0.12},
		"Zone2_CCM460V_RETIE": {"type": "hazard", "size": Vector2(1.7, 2.6), "stripe": Color(0.98, 0.18, 0.15), "tint": Color(0.88, 0.15, 0.15), "bw": 0.22, "alpha": 0.30},
		"Zone6_DispatchBay": {"type": "hazard", "size": Vector2(8.2, 5.2), "stripe": Color(0.98, 0.78, 0.06), "tint": Color(0.92, 0.72, 0.15), "bw": 0.34, "alpha": 0.24},
		"Zone8_IntakeConveyor_OSHA": {"type": "hazard", "size": Vector2(5.8, 4.3), "stripe": Color(0.98, 0.78, 0.06), "tint": Color(0.95, 0.72, 0.10), "bw": 0.28, "alpha": 0.18},
		"Zone4_PedestrianWalkway_OSHA": {"type": "walkway", "size": Vector2(1.75, 24.5), "lane": Color(0.10, 0.56, 0.24), "line": Color(0.98, 0.86, 0.20), "corridor": 1.0}
	}

	for child in zones_root.get_children():
		var decal := child.get_node_or_null("FloorDecal") as MeshInstance3D
		if decal == null:
			continue
		if not zone_cfg.has(child.name):
			decal.visible = false
			continue
		decal.visible = true
		var cfg: Dictionary = zone_cfg[child.name]
		var sm := ShaderMaterial.new()
		if cfg["type"] == "hazard":
			sm.shader = sh_hazard
			sm.set_shader_parameter("zone_size", cfg["size"])
			sm.set_shader_parameter("stripe_color", cfg["stripe"])
			sm.set_shader_parameter("base_tint", cfg["tint"])
			sm.set_shader_parameter("border_width", float(cfg["bw"]))
			sm.set_shader_parameter("inner_alpha", float(cfg["alpha"]))
		else:
			sm.shader = sh_walkway
			sm.set_shader_parameter("zone_size", cfg["size"])
			sm.set_shader_parameter("lane_color", cfg["lane"])
			sm.set_shader_parameter("line_color", cfg["line"])
			sm.set_shader_parameter("is_corridor", float(cfg["corridor"]))
		decal.material_override = sm
