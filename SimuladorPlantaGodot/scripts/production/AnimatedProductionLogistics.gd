class_name AnimatedProductionLogistics
extends Node3D

# ==============================================================================
# CADENA DE PRODUCCIÓN ANIMADA, LOGÍSTICA DE CAMIONES, SONIDOS Y OPERARIOS
# Bloque 4 - Anima los modelos reales descargados en planta_completa.glb y
# operarios GLB (conductores en cabina + señaleros en bahías Sur y Oeste).
# CERO primitivas 3D procedurales (CSG / BoxMesh / CylinderMesh).
# ==============================================================================

const SoundSynth = preload("res://scripts/core/IndustrialSoundSynthesizer.gd")
const HumanGaitAnimatorScript = preload("res://scripts/interactive/HumanGaitAnimator.gd")
const WorkerLogisticsScene = preload("res://scenes/workers/WorkerLogistics.tscn")
const DriverGLBScene = preload("res://assets/models/trabajador_operario.glb")
const InteractiveDoorScript = preload("res://scripts/interactive/InteractiveDoor.gd")

@export var min_active_rpm: float = 100.0
@export var bag_weight_kg: float = 50.0
@export var bags_per_pallet: int = 20

@onready var intake_follow: PathFollow3D = $IntakeTruckPath/IntakeFollow
@onready var dispatch_follow: PathFollow3D = $DispatchTruckPath/DispatchFollow
@onready var conveyor_follow: PathFollow3D = $BagConveyorPath/ConveyorFollow
@onready var grain_particles: GPUParticles3D = $GrainUnloadParticles

# Referencias a mallas reales descargadas de planta_completa.glb
var truck_intake_node: Node3D = null
var truck_dispatch_node: Node3D = null
var truck_parked_2_node: Node3D = null
var truck_staging_node: Node3D = null
var auger_node: Node3D = null
var elevator_node: Node3D = null
var pallet_node: Node3D = null
var mill_coupling_node: Node3D = null

var _auger_base_pos: Vector3 = Vector3.ZERO
var _auger_angle: float = 0.0

# Estado operativo sincronizado con el motor de 10 HP
var current_rpm: float = 0.0
var current_flow_kg_s: float = 0.8
var is_production_active: bool = false

# Ciclo logístico coordinado a velocidad reglamentaria de patio <= 10 km/h (300 s por rotación; camiones desfasados 50 %)
const TRUCK_CYCLE_DURATION: float = 300.0
const MAX_REGULATORY_PATIO_SPEED_KMH: float = 10.0
const MAX_REGULATORY_REVERSE_SPEED_KMH: float = 5.0
var truck_cycle_time: float = 0.0
var truck_cycle_phase: String = "WEIGHING"
var truck_tilt_angle_deg: float = 0.0
var dispatch_cycle_time: float = 0.0

# Contadores de producción
var total_grain_milled_kg: float = 0.0
var bags_50kg_produced: int = 0
var pallets_completed: int = 0
var _metrics_emit_timer: float = 0.0

# Rigs cinemáticos articulados, operarios y portón
var _south_rig: Dictionary = {}
var _bay2_rig: Dictionary = {}
var _staging_rig: Dictionary = {}
var _west_rig: Dictionary = {}
var _staging_mover: Node3D = null
var _south_spotter = null
var _west_spotter = null
var _logistics_loader = null
var _main_gate = null
var _exit_gate = null
var _roll_up_dock_door = null
var _gate_opened_by_trucks: bool = false
var _exit_gate_opened_by_trucks: bool = false
var _rollup_opened_by_loader: bool = false
var _player_ref: Node3D = null
var _idle_pulse_t: float = 0.0

# Control cinemático de cargue manual de sacos por operarios (solo con camión parqueado en la puerta enrollable derecha)
var _carried_bag_logistics: Node3D = null
var _carried_bag_dock: Node3D = null
var _bag_load_timer: float = 0.0
var _bay2_truck_parked_for_loading: bool = false
var _logistics_carry_pos: Vector3 = Vector3(-20.2, 0.794, 26.6)
var _logistics_returning_home: bool = false

const _LOGISTICS_HOME_POS := Vector3(-20.2, 0.794, 26.6)
const _DOCK_SOUTH_HOME_POS := Vector3(-16.4, 0.794, 24.75)
const _LOGISTICS_CARRY_WAYPOINTS: Array[Vector3] = [
	Vector3(-23.8, 0.794, 27.8),
	Vector3(-21.2, 0.794, 26.0),
	Vector3(-17.8, 0.794, 25.90),
	Vector3(-16.3, 0.794, 25.90),
	Vector3(-15.65, 0.794, 25.90)
]

# Rutas 100 % sobre carreteras pavimentadas (ADOQUIN/baldosa, cero pasto) y reversa recta al muelle de la PUERTA DERECHA (Door_Roll-Up Door - Industrial_1)
# Salida por vía Norte -> Portón Noreste (55.03, 9.58) -> Bulevar Este (X=71) -> Portón Principal (56.08, 38.04) -> Vía Sur -> Curva Oeste -> Reversa recta al muelle derecho
const SOUTH_DOCK_POS := Vector3(-2.85, 0.0, 23.82)
const SOUTH_EXIT_ROUTE: Array[Vector3] = [
	Vector3(-2.85, 0.0, 23.82),
	Vector3(10.5, 0.0, 22.0),
	Vector3(20.0, 0.0, 18.2),
	Vector3(30.0, 0.0, 15.8),
	Vector3(40.0, 0.0, 13.2),
	Vector3(48.0, 0.0, 11.2),
	Vector3(55.03, 0.0, 9.58),
	Vector3(62.5, 0.0, 9.5),
	Vector3(68.2, 0.0, 11.2),
	Vector3(70.2, 0.0, 16.5)
]
const SOUTH_TRANSIT_ROUTE: Array[Vector3] = [
	Vector3(70.2, 0.0, 16.5),
	Vector3(70.8, 0.0, 24.5),
	Vector3(70.5, 0.0, 32.5),
	Vector3(68.5, 0.0, 36.4),
	Vector3(63.5, 0.0, 37.4),
	Vector3(56.08, 0.0, 38.04)
]
const SOUTH_ENTER_ROUTE: Array[Vector3] = [
	Vector3(56.08, 0.0, 38.04),
	Vector3(51.8, 0.0, 40.2),
	Vector3(47.8, 0.0, 46.0),
	Vector3(43.6, 0.0, 52.0),
	Vector3(39.0, 0.0, 54.4),
	Vector3(34.8, 0.0, 55.0),
	Vector3(29.5, 0.0, 57.2),
	Vector3(20.0, 0.0, 58.4),
	Vector3(5.0, 0.0, 58.4),
	Vector3(-15.0, 0.0, 57.8),
	Vector3(-35.0, 0.0, 57.4),
	Vector3(-44.0, 0.0, 56.2),
	Vector3(-49.2, 0.0, 53.2),
	Vector3(-52.4, 0.0, 47.5),
	Vector3(-53.2, 0.0, 41.0),
	Vector3(-52.4, 0.0, 34.0),
	Vector3(-50.6, 0.0, 27.0),
	Vector3(-48.4, 0.0, 21.0),
	Vector3(-44.8, 0.0, 16.0),
	Vector3(-39.0, 0.0, 12.6),
	Vector3(-31.0, 0.0, 12.0),
	Vector3(-22.0, 0.0, 13.6),
	Vector3(-12.0, 0.0, 16.2),
	Vector3(-2.0, 0.0, 18.6),
	Vector3(6.5, 0.0, 20.8),
	Vector3(11.8, 0.0, 22.0),
	Vector3(14.8, 0.0, 21.95)
]
const SOUTH_REVERSE_ROUTE: Array[Vector3] = [
	Vector3(14.8, 0.0, 21.95),
	Vector3(6.0, 0.0, 22.88),
	Vector3(-2.85, 0.0, 23.82)
]

# Segundo tractocamión articulado turnándose desfasado en la misma PUERTA DERECHA de carga (cero colisión, >25 m separación)
const BAY2_DOCK_POS := Vector3(-2.85, 0.0, 23.82)
const BAY2_EXIT_ROUTE: Array[Vector3] = [
	Vector3(-2.85, 0.0, 23.82),
	Vector3(10.5, 0.0, 22.0),
	Vector3(20.0, 0.0, 18.2),
	Vector3(30.0, 0.0, 15.8),
	Vector3(40.0, 0.0, 13.2),
	Vector3(48.0, 0.0, 11.2),
	Vector3(55.03, 0.0, 9.58),
	Vector3(62.5, 0.0, 9.5),
	Vector3(68.2, 0.0, 11.2),
	Vector3(70.2, 0.0, 16.5)
]
const BAY2_ENTER_ROUTE: Array[Vector3] = [
	Vector3(56.08, 0.0, 38.04),
	Vector3(51.8, 0.0, 40.2),
	Vector3(47.8, 0.0, 46.0),
	Vector3(43.6, 0.0, 52.0),
	Vector3(39.0, 0.0, 54.4),
	Vector3(34.8, 0.0, 55.0),
	Vector3(29.5, 0.0, 57.2),
	Vector3(20.0, 0.0, 58.4),
	Vector3(5.0, 0.0, 58.4),
	Vector3(-15.0, 0.0, 57.8),
	Vector3(-35.0, 0.0, 57.4),
	Vector3(-44.0, 0.0, 56.2),
	Vector3(-49.2, 0.0, 53.2),
	Vector3(-52.4, 0.0, 47.5),
	Vector3(-53.2, 0.0, 41.0),
	Vector3(-52.4, 0.0, 34.0),
	Vector3(-50.6, 0.0, 27.0),
	Vector3(-48.4, 0.0, 21.0),
	Vector3(-44.8, 0.0, 16.0),
	Vector3(-39.0, 0.0, 12.6),
	Vector3(-31.0, 0.0, 12.0),
	Vector3(-22.0, 0.0, 13.6),
	Vector3(-12.0, 0.0, 16.2),
	Vector3(-2.0, 0.0, 18.6),
	Vector3(6.5, 0.0, 20.8),
	Vector3(11.8, 0.0, 22.0),
	Vector3(14.8, 0.0, 21.95)
]
const BAY2_REVERSE_ROUTE: Array[Vector3] = [
	Vector3(14.8, 0.0, 21.95),
	Vector3(6.0, 0.0, 22.88),
	Vector3(-2.85, 0.0, 23.82)
]

# Circuito cerrado holgado 100 % dentro del patio de grava Norte (cero pasto)
const STAGING_YARD_LOOP: Array[Vector3] = [
	Vector3(-33.3, 0.0, -11.4),
	Vector3(-22.0, 0.0, -13.0),
	Vector3(-21.0, 0.0, -21.0),
	Vector3(-30.5, 0.0, -23.0),
	Vector3(-38.5, 0.0, -18.5),
	Vector3(-38.5, 0.0, -11.5)
]

const WEST_DOCK_POS := Vector3(-38.43, 0.0, 51.31)
const WEST_EXIT_ROUTE: Array[Vector3] = [
	Vector3(-38.43, 0.0, 51.31),
	Vector3(-47.5, 0.0, 51.0),
	Vector3(-52.2, 0.0, 47.0),
	Vector3(-53.2, 0.0, 41.0),
	Vector3(-52.2, 0.0, 34.0),
	Vector3(-50.2, 0.0, 27.0),
	Vector3(-47.8, 0.0, 21.5),
	Vector3(-44.5, 0.0, 16.8),
	Vector3(-39.0, 0.0, 13.5),
	Vector3(-31.0, 0.0, 12.8),
	Vector3(-22.0, 0.0, 14.5),
	Vector3(-12.0, 0.0, 17.2),
	Vector3(0.0, 0.0, 19.2),
	Vector3(14.0, 0.0, 19.2),
	Vector3(26.0, 0.0, 16.8),
	Vector3(38.0, 0.0, 13.8),
	Vector3(48.0, 0.0, 11.2),
	Vector3(55.03, 0.0, 9.58),
	Vector3(62.5, 0.0, 9.5),
	Vector3(68.2, 0.0, 11.2),
	Vector3(70.2, 0.0, 16.5)
]
const WEST_TRANSIT_ROUTE: Array[Vector3] = [
	Vector3(70.2, 0.0, 16.5),
	Vector3(70.8, 0.0, 24.5),
	Vector3(70.5, 0.0, 32.5),
	Vector3(68.5, 0.0, 36.4),
	Vector3(63.5, 0.0, 37.4),
	Vector3(56.08, 0.0, 38.04)
]
const WEST_ENTER_ROUTE: Array[Vector3] = [
	Vector3(56.08, 0.0, 38.04),
	Vector3(51.8, 0.0, 40.2),
	Vector3(47.8, 0.0, 46.0),
	Vector3(43.6, 0.0, 52.0),
	Vector3(39.0, 0.0, 54.4),
	Vector3(34.8, 0.0, 55.0),
	Vector3(29.5, 0.0, 57.2),
	Vector3(20.0, 0.0, 58.4),
	Vector3(5.0, 0.0, 58.4),
	Vector3(-15.0, 0.0, 57.8),
	Vector3(-35.0, 0.0, 57.4),
	Vector3(-44.0, 0.0, 56.2),
	Vector3(-48.5, 0.0, 53.6),
	Vector3(-49.2, 0.0, 51.31)
]
const WEST_REVERSE_ROUTE: Array[Vector3] = [
	Vector3(-49.2, 0.0, 51.31),
	Vector3(-38.43, 0.0, 51.31)
]

func _ready() -> void:
	_bind_downloaded_models()

	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("telemetry_updated"):
		if not bus.telemetry_updated.is_connected(_on_telemetry_updated):
			bus.telemetry_updated.connect(_on_telemetry_updated)

func _exit_tree() -> void:
	for rig in [_south_rig, _bay2_rig, _staging_rig, _west_rig]:
		if rig.is_empty():
			continue
		for k in ["diesel_aud", "reverse_aud", "sfx_aud"]:
			var sp := rig.get(k) as AudioStreamPlayer3D
			if sp != null and is_instance_valid(sp):
				sp.stop()
				sp.stream = null

func _measure_world_aabb(node: Node3D) -> AABB:
	var has := false
	var box := AABB()
	if node == null:
		return box
	for ch in node.find_children("*", "MeshInstance3D", true, false):
		var mi := ch as MeshInstance3D
		if mi.mesh == null:
			continue
		var lb := mi.mesh.get_aabb()
		var xf := mi.global_transform
		for i in range(8):
			var wp := xf * Vector3(
				lb.position.x + (lb.size.x if (i & 1) != 0 else 0.0),
				lb.position.y + (lb.size.y if (i & 2) != 0 else 0.0),
				lb.position.z + (lb.size.z if (i & 4) != 0 else 0.0)
			)
			if not has:
				box = AABB(wp, Vector3.ZERO)
				has = true
			else:
				box = box.expand(wp)
	return box

func _measure_exact_world_min_y(node: Node3D) -> float:
	var min_y := INF
	if node == null:
		return 0.0
	for ch in node.find_children("*", "MeshInstance3D", true, false):
		var mi := ch as MeshInstance3D
		if mi.mesh == null:
			continue
		var xf := mi.global_transform
		for s in range(mi.mesh.get_surface_count()):
			var arr := mi.mesh.surface_get_arrays(s)
			if arr.size() <= Mesh.ARRAY_VERTEX:
				continue
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			for v in verts:
				var wy := (xf * v).y
				if wy < min_y:
					min_y = wy
	return 0.0 if min_y == INF else min_y

func _bind_downloaded_models() -> void:
	var scene_root := get_parent()
	if scene_root == null:
		return

	_player_ref = scene_root.find_child("PlayerOperator", true, false) as Node3D

	var plant_model := scene_root.find_child("PlantaCompletaSketchUp", true, false) as Node3D
	if plant_model != null:
		truck_dispatch_node = plant_model.find_child("NCDOT International Box Truck", true, false) as Node3D
		truck_intake_node = plant_model.find_child("Node1575", true, false) as Node3D
		truck_parked_2_node = plant_model.find_child("Node1577", true, false) as Node3D
		truck_staging_node = plant_model.find_child("Node1579", true, false) as Node3D
		if truck_dispatch_node != null and truck_dispatch_node.get_parent() != null:
			var t_parent := truck_dispatch_node.get_parent()
			for tc in t_parent.get_children():
				var t3d := tc as Node3D
				if t3d == null or t3d == truck_dispatch_node:
					continue
				var tb := _measure_world_aabb(t3d)
				var c := tb.get_center()
				if truck_intake_node == null and c.z < 26.5 and c.x < 10.0:
					truck_intake_node = t3d
				elif truck_parked_2_node == null and c.z >= 26.5 and c.z < 35.0:
					truck_parked_2_node = t3d
				elif truck_staging_node == null and c.x < -40.0 and c.z > 35.0:
					truck_staging_node = t3d
		auger_node = plant_model.find_child("Helicoidal", true, false) as Node3D
		elevator_node = plant_model.find_child("Bunkerdoseerelevator", true, false) as Node3D
		pallet_node = plant_model.find_child("Pallet 60 sacos", true, false) as Node3D
		_screw_trit_shaft = _find_sub_node(plant_model, "Group#149", "Geom3D275")
		_screw_secador_shaft = _find_sub_node(plant_model, "Node2161", "Geom3D1808")
		_tolva_grain_node = _find_sub_node(plant_model, "Node1583", "Geom3D1462")
		if _tolva_grain_node != null:
			_tolva_grain_base_y = _tolva_grain_node.position.y
		_super_saco_node = plant_model.find_child("super saco", true, false) as Node3D
		if _super_saco_node != null:
			_super_saco_base_scale = _super_saco_node.scale
		_setup_product_flow(plant_model)

		if auger_node != null:
			_auger_base_pos = auger_node.position

		_main_gate = plant_model.find_child("Door_Porton Automatico Parcela", true, false)
		_exit_gate = plant_model.find_child("Door_Porton Automatico Parcela_1", true, false)
		_roll_up_dock_door = plant_model.find_child("Door_Roll-Up Door - Industrial_1", true, false)

	var mill_unit := scene_root.find_child("MotorMillUnit", true, false) as Node3D
	if mill_unit != null:
		mill_coupling_node = mill_unit.get_node_or_null("CouplingGuard") as Node3D

	if truck_staging_node != null:
		_staging_rig = _build_semi_from_glbs(
			truck_staging_node, null, "TruckStagingMover", STAGING_YARD_LOOP[0],
			STAGING_YARD_LOOP, [], [], [], true
		)
		_staging_mover = _staging_rig.get("mover") as Node3D

	if truck_parked_2_node != null:
		_bay2_rig = _build_semi_from_glbs(
			truck_parked_2_node, null, "TruckBay2Mover", BAY2_DOCK_POS,
			BAY2_EXIT_ROUTE, SOUTH_TRANSIT_ROUTE, BAY2_ENTER_ROUTE, BAY2_REVERSE_ROUTE, false
		)

	if truck_intake_node != null:
		_south_rig = _build_semi_from_glbs(
			truck_intake_node, null, "TruckIntakeMover", SOUTH_DOCK_POS,
			SOUTH_EXIT_ROUTE, SOUTH_TRANSIT_ROUTE, SOUTH_ENTER_ROUTE, SOUTH_REVERSE_ROUTE, false
		)

	if truck_dispatch_node != null:
		var box_w := _measure_world_aabb(truck_dispatch_node)
		var dock_pivot_w := Vector3(box_w.get_center().x, 0.0, box_w.get_center().z)
		var fwd_w := Vector3(-1.0, 0.0, 0.0)
		var cab_interior := truck_dispatch_node.find_child("Node1547", true, false) as Node3D
		if cab_interior == null:
			cab_interior = truck_dispatch_node.find_child("Node1630", true, false) as Node3D
		var driver_world_w := dock_pivot_w + Vector3(-4.05, 0.85, -0.45)
		if cab_interior != null:
			var cb := _measure_world_aabb(cab_interior)
			driver_world_w = Vector3(cb.get_center().x + 0.12, cb.position.y - 0.08, cb.position.z + 0.56)
		_west_rig = _create_truck_rig(
			truck_dispatch_node, "TruckDispatchMover", dock_pivot_w, fwd_w,
			Vector3(2.8, 3.9, 11.8), driver_world_w, null, Vector3.ZERO,
			WEST_DOCK_POS, WEST_EXIT_ROUTE, WEST_TRANSIT_ROUTE, WEST_ENTER_ROUTE, WEST_REVERSE_ROUTE,
			atan2(0.3594, 6.763), 0.006
		)

	if scene_root.name == "MainPlantScene":
		_spawn_dock_operators(scene_root)

func _build_semi_from_glbs(
	semi_root: Node3D,
	explicit_trl: Node3D,
	mover_name: String,
	dock_pos: Vector3,
	exit_or_loop_route: Array[Vector3],
	transit_route: Array[Vector3],
	enter_route: Array[Vector3],
	reverse_route: Array[Vector3],
	is_closed_loop: bool
) -> Dictionary:
	if semi_root == null:
		return {}

	var cab_n: Node3D = null
	var trl_n: Node3D = explicit_trl
	for ch in semi_root.get_children():
		if not (ch is Node3D):
			continue
		var c3 := ch as Node3D
		if cab_n == null and str(c3.name).begins_with("Component#30"):
			cab_n = c3
		elif trl_n == null and c3 != cab_n:
			trl_n = c3
	if cab_n == null:
		cab_n = semi_root.find_child("Component#30*", true, false) as Node3D
	if cab_n == null:
		return {}

	var fw_node := cab_n.find_child("Component#71*", true, false) as Node3D
	var steer_node := cab_n.find_child("Component#13*", true, false) as Node3D
	var rear_bogie := trl_n.find_child("Component#25*", true, false) as Node3D if trl_n != null else null

	var fw_box := _measure_world_aabb(fw_node if fw_node != null else cab_n)
	var fw_world := Vector3(fw_box.get_center().x, 0.0, fw_box.get_center().z)

	var steer_box := _measure_world_aabb(steer_node if steer_node != null else cab_n)
	var fwd_cab := Vector3(steer_box.get_center().x - fw_world.x, 0.0, steer_box.get_center().z - fw_world.z)
	if fwd_cab.length_squared() < 0.05:
		fwd_cab = Vector3(0.9903, 0.0, -0.1386)
	fwd_cab = fwd_cab.normalized()

	var trl_axle_world := fw_world - fwd_cab * 11.0
	var fwd_trl := fwd_cab
	if rear_bogie != null:
		var rb_box := _measure_world_aabb(rear_bogie)
		trl_axle_world = Vector3(rb_box.get_center().x, 0.0, rb_box.get_center().z)
		var dv := Vector3(fw_world.x - trl_axle_world.x, 0.0, fw_world.z - trl_axle_world.z)
		if dv.length_squared() > 0.25:
			fwd_trl = dv.normalized()
	elif trl_n != null:
		var tb := _measure_world_aabb(trl_n)
		trl_axle_world = Vector3(tb.get_center().x, 0.0, tb.get_center().z) - fwd_cab * 4.5

	var kingpin_to_axle: float = clampf(Vector2(fw_world.x - trl_axle_world.x, fw_world.z - trl_axle_world.z).length(), 8.0, 14.0)
	var cab_yaw := atan2(-fwd_cab.x, -fwd_cab.z)
	var trl_yaw := atan2(-fwd_trl.x, -fwd_trl.z)
	var initial_rel_yaw := wrapf(trl_yaw - cab_yaw, -PI, PI)

	var cab_box := _measure_world_aabb(cab_n)
	var right_cab := fwd_cab.cross(Vector3.UP).normalized()
	var driver_world := Vector3(
		cab_box.get_center().x + fwd_cab.x * 0.45 - right_cab.x * 0.35,
		cab_box.position.y + 1.05,
		cab_box.get_center().z + fwd_cab.z * 0.45 - right_cab.z * 0.35
	)

	return _create_articulated_semi_rig(
		semi_root, cab_n, trl_n, mover_name,
		fw_world, fwd_cab, trl_axle_world, kingpin_to_axle, initial_rel_yaw,
		dock_pos, driver_world,
		exit_or_loop_route, transit_route, enter_route, reverse_route,
		is_closed_loop, 0.006
	)

func _create_articulated_semi_rig(
	semi_root: Node3D,
	cab_node: Node3D,
	trailer_node: Node3D,
	mover_name: String,
	kingpin_world: Vector3,
	cab_fwd: Vector3,
	trailer_axle_world: Vector3,
	kingpin_to_axle_m: float,
	initial_rel_yaw: float,
	dock_pos: Vector3,
	driver_world_pos: Vector3,
	exit_or_loop_route: Array[Vector3],
	transit_route: Array[Vector3],
	enter_route: Array[Vector3],
	reverse_route: Array[Vector3],
	is_closed_loop: bool,
	ground_seat_y: float = 0.006
) -> Dictionary:
	# 1. Cuerpo principal AnimatableBody3D anclado exactamente en la quinta rueda del tractocamión
	var mover := AnimatableBody3D.new()
	mover.name = mover_name
	mover.collision_layer = 1
	mover.collision_mask = 0
	mover.sync_to_physics = false
	add_child(mover)
	mover.global_position = kingpin_world
	mover.look_at(kingpin_world + cab_fwd, Vector3.UP)

	var cab_cs := CollisionShape3D.new()
	var cab_hull := BoxShape3D.new()
	cab_hull.size = Vector3(2.8, 3.85, 8.8)
	cab_cs.shape = cab_hull
	cab_cs.position = Vector3(0.0, 2.0, -3.0)
	mover.add_child(cab_cs)

	var visual_pivot := Node3D.new()
	visual_pivot.name = "ChassisVisual"
	mover.add_child(visual_pivot)
	visual_pivot.global_transform = mover.global_transform

	var level_pivot := Node3D.new()
	level_pivot.name = "GroundLevelPivot"
	visual_pivot.add_child(level_pivot)
	level_pivot.transform = Transform3D.IDENTITY

	# 2. Subárbol del Tractocamión (cabina + 3 ejes de tracción/dirección sobre pavimento)
	# 2. Quinta Rueda / Kingpin Pivot y Subárboles de Tractocamión + Semirremolque bajo level_pivot ANTES de nivelar al piso
	cab_node.reparent(level_pivot, true)
	var articulation_pivot: Node3D = null
	if trailer_node != null:
		articulation_pivot = Node3D.new()
		articulation_pivot.name = "TrailerArticulationPivot"
		level_pivot.add_child(articulation_pivot)
		articulation_pivot.position = Vector3.ZERO
		articulation_pivot.rotation = Vector3.ZERO
		trailer_node.reparent(articulation_pivot, true)

	var min_y_cab: float = _measure_exact_world_min_y(cab_node)
	var min_y_trl: float = _measure_exact_world_min_y(trailer_node) if trailer_node != null else min_y_cab
	var ground_dy: float = ground_seat_y - minf(min_y_cab, min_y_trl)
	level_pivot.position.y += ground_dy

	# Envolver ejes del tractocamión (Component#13 dirección, Component#8 tracción) en pivotes compensados
	var wheel_pivots: Array[Dictionary] = []
	var tractor_target_basis := mover.global_transform.basis
	_register_semi_wheel_axles(cab_node, tractor_target_basis, wheel_pivots, false, 0.55)

	# 3. Hidráulica de descarga, eje tándem del semirremolque y colisionador físico articulado
	var tilt_pivot: Node3D = null
	var trailer_hull_body: AnimatableBody3D = null
	if trailer_node != null:
		# Eje tándem trasero del remolque (se mantiene siempre asentado en el suelo, jamás se levanta al inclinar caja)
		var bogie := trailer_node.find_child("Component#25*", true, false) as Node3D
		var rear_pivot_local := Vector3(0.0, 1.45, kingpin_to_axle_m)
		if bogie != null:
			var bogie_center := _measure_world_aabb(bogie).get_center()
			rear_pivot_local = articulation_pivot.to_local(Vector3(bogie_center.x, bogie_center.y + 0.72, bogie_center.z))
			var trl_yaw_abs := atan2(-(kingpin_world.x - trailer_axle_world.x), -(kingpin_world.z - trailer_axle_world.z))
			var trl_basis := Basis(Vector3.UP, trl_yaw_abs)
			_register_semi_wheel_axles(bogie, trl_basis, wheel_pivots, false, 0.55)

		# Hidráulica solo sobre el furgón superior / bastidor (no levanta las llantas traseras)
		tilt_pivot = Node3D.new()
		tilt_pivot.name = "HydraulicTiltPivot"
		articulation_pivot.add_child(tilt_pivot)
		tilt_pivot.position = rear_pivot_local
		tilt_pivot.rotation = Vector3(0.0, initial_rel_yaw, 0.0)
		var cargo_parts: Array[Node3D] = []
		for ch in trailer_node.get_children():
			if ch is Node3D and ch != bogie:
				cargo_parts.append(ch as Node3D)
		for cp in cargo_parts:
			cp.reparent(tilt_pivot, true)

		# Colisionador físico propio del remolque articulado que sigue su ángulo real de quinta rueda
		trailer_hull_body = AnimatableBody3D.new()
		trailer_hull_body.name = mover_name + "TrailerHull"
		trailer_hull_body.collision_layer = 1
		trailer_hull_body.collision_mask = 0
		trailer_hull_body.sync_to_physics = false
		articulation_pivot.add_child(trailer_hull_body)
		trailer_hull_body.position = Vector3.ZERO
		trailer_hull_body.rotation = Vector3(0.0, initial_rel_yaw, 0.0)
		var trl_cs := CollisionShape3D.new()
		var trl_hull := BoxShape3D.new()
		trl_hull.size = Vector3(2.8, 3.85, 13.4)
		trl_cs.shape = trl_hull
		trl_cs.position = Vector3(0.0, 2.05, kingpin_to_axle_m * 0.50)
		trailer_hull_body.add_child(trl_cs)

	var driver_local := mover.to_local(driver_world_pos)
	driver_local.y += ground_dy
	var driver_node := _spawn_cab_driver(mover, driver_local)

	var diesel_aud := _make_truck_audio(mover, "DieselAudio3D", SoundSynth.create_truck_diesel_loop(), -6.5, 13.0, 82.0)
	var reverse_aud := _make_truck_audio(mover, "ReverseBeepAudio3D", SoundSynth.create_truck_reverse_beep_loop(), -3.0, 12.0, 75.0)
	var sfx_aud := _make_truck_audio(mover, "BrakeHornAudio3D", SoundSynth.create_truck_air_brake_sound(), -2.0, 12.0, 85.0)
	if DisplayServer.get_name() != "headless" and diesel_aud.stream != null:
		diesel_aud.play()

	var base_yaw := atan2(-cab_fwd.x, -cab_fwd.z)
	var pre_exit := _precompute_route(exit_or_loop_route, is_closed_loop)
	var pre_transit := _precompute_route(transit_route, false) if not transit_route.is_empty() else {}
	var pre_enter := _precompute_route(enter_route, false) if not enter_route.is_empty() else {}
	var pre_rev := _precompute_route(reverse_route, false) if not reverse_route.is_empty() else {}

	return {
		"is_semi": true,
		"is_closed_loop": is_closed_loop,
		"mover": mover,
		"visual": visual_pivot,
		"level_pivot": level_pivot,
		"articulation_pivot": articulation_pivot,
		"tilt_pivot": tilt_pivot,
		"trailer_hull_body": trailer_hull_body,
		"wheel_pivots": wheel_pivots,
		"driver": driver_node,
		"diesel_aud": diesel_aud,
		"reverse_aud": reverse_aud,
		"sfx_aud": sfx_aud,
		"dock_pos": dock_pos,
		"dock_yaw": base_yaw,
		"cur_yaw": base_yaw,
		"trailer_yaw": wrapf(base_yaw + initial_rel_yaw, -PI, PI),
		"initial_rel_yaw": initial_rel_yaw,
		"kingpin_to_axle_m": kingpin_to_axle_m,
		"trailer_axle_xz": Vector2(trailer_axle_world.x, trailer_axle_world.z),
		"hitch_init": true,
		"wheel_spin_rad": 0.0,
		"steer_angle_rad": 0.0,
		"cur_speed_ms": 0.0,
		"body_pitch_rad": 0.0,
		"body_roll_rad": 0.0,
		"phase": "WEIGHING" if not is_closed_loop else "YARD_MANEUVER",
		"prev_phase": "",
		"prev_u": -1.0,
		"exit_route": pre_exit,
		"transit_route": pre_transit,
		"enter_route": pre_enter,
		"reverse_route": pre_rev,
		"pos": kingpin_world,
		"horn_played": false
	}

func _register_semi_wheel_axles(root_node: Node3D, align_basis: Basis, target: Array[Dictionary], is_steer: bool, wheel_r: float) -> void:
	if root_node == null:
		return
	var axle_nodes: Array[Node3D] = []
	for ch in root_node.find_children("*", "Node3D", true, false):
		var c3 := ch as Node3D
		var nm := str(c3.name)
		if nm.begins_with("Component#13") or nm.begins_with("Component#8"):
			# Ignorar componentes no-rueda (#84 escape, #85 cofre, #86 faro) verificando alto real de neumático ~1.10 m
			if nm.begins_with("Component#84") or nm.begins_with("Component#85") or nm.begins_with("Component#86"):
				continue
			var bx := _measure_world_aabb(c3)
			if absf(bx.size.y - 1.104) <= 0.14 and bx.get_center().y >= 0.35 and bx.get_center().y <= 0.85:
				axle_nodes.append(c3)
	for ax in axle_nodes:
		_wrap_wheel_node_in_clean_pivots(ax, align_basis, is_steer, wheel_r, target)

func _wrap_wheel_node_in_clean_pivots(
	wn: Node3D,
	align_basis: Basis,
	with_steer: bool,
	wheel_r: float,
	target: Array[Dictionary]
) -> void:
	if wn == null or wn.get_parent() == null:
		return
	var host := wn.get_parent() as Node3D
	var w_center := _measure_world_aabb(wn).get_center()
	# Nodo compensador estático: anula escala 0.0254 y rotación -90° heredada de SketchUp (nunca se sobreescribe)
	var align_piv := Node3D.new()
	align_piv.name = "WheelAlign_" + wn.name
	host.add_child(align_piv)
	align_piv.global_position = w_center
	align_piv.global_basis = align_basis.orthonormalized()

	var steer_piv: Node3D = null
	var spin_parent: Node3D = align_piv
	if with_steer:
		steer_piv = Node3D.new()
		steer_piv.name = "WheelSteer_" + wn.name
		align_piv.add_child(steer_piv)
		steer_piv.transform = Transform3D.IDENTITY
		spin_parent = steer_piv

	var spin_piv := Node3D.new()
	spin_piv.name = "WheelSpin_" + wn.name
	spin_parent.add_child(spin_piv)
	spin_piv.transform = Transform3D.IDENTITY
	wn.reparent(spin_piv, true)

	target.append({
		"spin_pivot": spin_piv,
		"steer_pivot": steer_piv,
		"radius": wheel_r,
		"is_steer": with_steer
	})

func _create_truck_rig(
	truck_node: Node3D,
	mover_name: String,
	initial_pivot: Vector3,
	initial_fwd: Vector3,
	hull_size: Vector3,
	driver_world_pos: Vector3,
	trailer_node: Node3D,
	trailer_rear_pivot_world: Vector3,
	dock_pos: Vector3,
	exit_route: Array[Vector3],
	transit_route: Array[Vector3],
	enter_route: Array[Vector3],
	reverse_route: Array[Vector3],
	level_pitch_rad: float = 0.0,
	ground_seat_y: float = 0.002
) -> Dictionary:
	var mover := AnimatableBody3D.new()
	mover.name = mover_name
	mover.collision_layer = 1
	mover.collision_mask = 0
	mover.sync_to_physics = false
	add_child(mover)
	mover.global_position = initial_pivot
	mover.look_at(initial_pivot + initial_fwd, Vector3.UP)

	var hull_cs := CollisionShape3D.new()
	var hull_box := BoxShape3D.new()
	hull_box.size = hull_size
	hull_cs.shape = hull_box
	hull_cs.position = Vector3(0.0, hull_size.y * 0.5 + 0.15, 0.0)
	mover.add_child(hull_cs)

	var visual_pivot := Node3D.new()
	visual_pivot.name = "ChassisVisual"
	mover.add_child(visual_pivot)
	visual_pivot.global_transform = mover.global_transform

	# Nivela inclinación heredada del modelo GLB y apoya todas las ruedas al ras del pavimento
	var level_pivot := Node3D.new()
	level_pivot.name = "GroundLevelPivot"
	visual_pivot.add_child(level_pivot)
	level_pivot.transform = Transform3D.IDENTITY
	truck_node.reparent(level_pivot, true)
	if absf(level_pitch_rad) > 0.0001:
		level_pivot.rotation.x = level_pitch_rad
	var ground_dy: float = ground_seat_y - _measure_exact_world_min_y(level_pivot)
	level_pivot.position.y += ground_dy

	var tilt_pivot: Node3D = null
	if trailer_node != null and trailer_node.get_parent() != null:
		tilt_pivot = Node3D.new()
		tilt_pivot.name = "HydraulicTiltPivot"
		level_pivot.add_child(tilt_pivot)
		tilt_pivot.global_position = trailer_rear_pivot_world + Vector3(0.0, ground_dy, 0.0)
		tilt_pivot.global_basis = level_pivot.global_basis
		trailer_node.reparent(tilt_pivot, true)

	# Registrar ruedas del furgón NCDOT (Node1541 / Node1544 direccionales; Node1538 / Node1550 traseras)
	var wheel_pivots: Array[Dictionary] = []
	var truck_basis := mover.global_transform.basis.orthonormalized()
	for w_spec in [
		{"name": "Node1541", "steer": true},
		{"name": "Node1544", "steer": true},
		{"name": "Node1538", "steer": false},
		{"name": "Node1550", "steer": false}
	]:
		var wn := truck_node.find_child(str(w_spec["name"]), true, false) as Node3D
		_wrap_wheel_node_in_clean_pivots(wn, truck_basis, bool(w_spec["steer"]), 0.51, wheel_pivots)

	# Operario conductor sentado en cabina (modelo GLB descargado, cero primitivas)
	var driver_local := mover.to_local(driver_world_pos)
	driver_local.y += ground_dy - driver_local.z * sin(level_pitch_rad)
	var driver_node := _spawn_cab_driver(mover, driver_local)

	# Audio espacial 3D del camión (diésel + alarma de reversa + frenos neumáticos / bocina)
	var diesel_aud := _make_truck_audio(mover, "DieselAudio3D", SoundSynth.create_truck_diesel_loop(), -6.5, 13.0, 82.0)
	var reverse_aud := _make_truck_audio(mover, "ReverseBeepAudio3D", SoundSynth.create_truck_reverse_beep_loop(), -3.0, 12.0, 75.0)
	var sfx_aud := _make_truck_audio(mover, "BrakeHornAudio3D", SoundSynth.create_truck_air_brake_sound(), -2.0, 12.0, 85.0)

	if DisplayServer.get_name() != "headless" and diesel_aud.stream != null:
		diesel_aud.play()

	var base_yaw := atan2(-initial_fwd.x, -initial_fwd.z)
	return {
		"is_semi": false,
		"is_closed_loop": false,
		"mover": mover,
		"visual": visual_pivot,
		"level_pivot": level_pivot,
		"articulation_pivot": null,
		"tilt_pivot": tilt_pivot,
		"trailer_hull_body": null,
		"wheel_pivots": wheel_pivots,
		"driver": driver_node,
		"diesel_aud": diesel_aud,
		"reverse_aud": reverse_aud,
		"sfx_aud": sfx_aud,
		"dock_pos": dock_pos,
		"dock_yaw": base_yaw,
		"cur_yaw": base_yaw,
		"trailer_yaw": base_yaw,
		"initial_rel_yaw": 0.0,
		"kingpin_to_axle_m": 0.0,
		"trailer_axle_xz": Vector2.ZERO,
		"hitch_init": true,
		"wheel_spin_rad": 0.0,
		"steer_angle_rad": 0.0,
		"cur_speed_ms": 0.0,
		"body_pitch_rad": 0.0,
		"body_roll_rad": 0.0,
		"phase": "WEIGHING",
		"prev_phase": "",
		"prev_u": -1.0,
		"exit_route": _precompute_route(exit_route, false),
		"transit_route": _precompute_route(transit_route, false),
		"enter_route": _precompute_route(enter_route, false),
		"reverse_route": _precompute_route(reverse_route, false),
		"pos": dock_pos,
		"horn_played": false
	}

func _spawn_cab_driver(parent_mover: Node3D, local_seat_pos: Vector3) -> Node3D:
	if DriverGLBScene == null:
		return null
	var drv := DriverGLBScene.instantiate() as Node3D
	if drv == null:
		return null
	drv.name = "TruckCabDriver"
	drv.scale = Vector3(0.84, 0.84, 0.84)
	parent_mover.add_child(drv)
	drv.position = local_seat_pos
	# En trab_operario.glb el frente es +Z; al rotar PI queda mirando hacia -Z (parabrisas)
	drv.rotation = Vector3(0.0, PI, 0.0)
	var ap := drv.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap != null:
		HumanGaitAnimatorScript.upgrade_animations(ap, drv)
		if ap.has_animation("drive_seated"):
			ap.play("drive_seated")
			ap.get_animation("drive_seated").loop_mode = Animation.LOOP_LINEAR
			ap.advance(0.02)
	return drv

func _spawn_dock_operators(scene_root: Node) -> void:
	if WorkerLogisticsScene == null:
		return
	var staff_parent := scene_root.find_child("PlantStaff", true, false)
	var host := staff_parent if staff_parent != null else scene_root

	if host.find_child("WorkerDockSouth", false, false) == null:
		var ws := WorkerLogisticsScene.instantiate()
		ws.name = "WorkerDockSouth"
		ws.worker_role_name = "Operario de Carga"
		ws.worker_dialogue = "Aquí en la puerta enrollable derecha coordinamos el acople del tractocamión y cargamos los sacos de 50 kg."
		ws.primary_animation = "inspect"
		ws.secondary_animation = "idle"
		ws.external_animation_control = true
		host.add_child(ws)
		ws.global_position = _DOCK_SOUTH_HOME_POS

	if host.find_child("WorkerDockWest", false, false) == null:
		var ww := WorkerLogisticsScene.instantiate()
		ww.name = "WorkerDockWest"
		ww.worker_role_name = "Operario Señalero"
		ww.worker_dialogue = "Supervisión de maniobra en reversa y despacho de carga desde plataforma peatonal elevada."
		ww.primary_animation = "inspect"
		ww.secondary_animation = "idle"
		ww.external_animation_control = true
		host.add_child(ww)
		ww.global_position = Vector3(-22.5, 0.60, 52.3)

	_south_spotter = host.find_child("WorkerDockSouth", false, false)
	_west_spotter = host.find_child("WorkerDockWest", false, false)
	_logistics_loader = host.find_child("WorkerLogistics", false, false)
	if _logistics_loader != null and is_instance_valid(_logistics_loader):
		_logistics_carry_pos = (_logistics_loader as Node3D).global_position

func _make_truck_audio(parent: Node3D, node_name: String, wav: AudioStreamWAV, vol_db: float, unit_sz: float, max_dist: float) -> AudioStreamPlayer3D:
	var sp := AudioStreamPlayer3D.new()
	sp.name = node_name
	sp.stream = wav
	sp.volume_db = vol_db
	sp.unit_size = unit_sz
	sp.max_distance = max_dist
	sp.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	parent.add_child(sp)
	return sp

func _catmull_rom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * (
		(2.0 * p1)
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)

func _precompute_route(pts: Array[Vector3], closed_loop: bool = false) -> Dictionary:
	if pts.size() < 2:
		return {"pts": pts, "cum": [0.0], "total": 0.001, "closed": closed_loop}
	var smooth_pts: Array[Vector3] = []
	var n := pts.size()
	var segs := n if closed_loop else (n - 1)
	var steps_per_seg := 10
	for i in range(segs):
		var p0: Vector3
		var p1: Vector3
		var p2: Vector3
		var p3: Vector3
		if closed_loop:
			p0 = pts[(i - 1 + n) % n]
			p1 = pts[i % n]
			p2 = pts[(i + 1) % n]
			p3 = pts[(i + 2) % n]
		else:
			p1 = pts[i]
			p2 = pts[i + 1]
			p0 = pts[i - 1] if i > 0 else (p1 - (p2 - p1))
			p3 = pts[i + 2] if (i + 2) < n else (p2 + (p2 - p1))
		for st in range(steps_per_seg):
			var t := float(st) / float(steps_per_seg)
			smooth_pts.append(_catmull_rom(p0, p1, p2, p3, t))
	smooth_pts.append(pts[0] if closed_loop else pts[n - 1])

	var cum: Array[float] = [0.0]
	var total: float = 0.0
	for i in range(1, smooth_pts.size()):
		total += smooth_pts[i - 1].distance_to(smooth_pts[i])
		cum.append(total)
	return {"pts": smooth_pts, "cum": cum, "total": maxf(total, 0.001), "closed": closed_loop}

func _sample_route(route: Dictionary, s_raw: float, reverse_face: bool) -> Dictionary:
	var pts: Array = route.get("pts", [])
	var cum: Array = route.get("cum", [])
	if pts.size() < 2:
		return {"pos": Vector3.ZERO, "dir": Vector3.FORWARD}
	var total: float = float(route["total"])
	var closed: bool = bool(route.get("closed", false))
	var s := fposmod(s_raw, 1.0) if closed else clampf(s_raw, 0.0, 1.0)
	var d := s * total
	var pos := _sample_dist_point(pts, cum, d)

	var look_f := 2.4
	var look_b := 1.4
	var p_ahead: Vector3
	var p_behind: Vector3
	if closed:
		p_ahead = _sample_dist_point(pts, cum, fposmod(d + look_f, total))
		p_behind = _sample_dist_point(pts, cum, fposmod(d - look_b + total, total))
	else:
		p_ahead = _sample_dist_point(pts, cum, minf(total, d + look_f))
		p_behind = _sample_dist_point(pts, cum, maxf(0.0, d - look_b))
	var tangent := Vector3(p_ahead.x - p_behind.x, 0.0, p_ahead.z - p_behind.z)
	if tangent.length_squared() < 0.0001:
		tangent = Vector3(1.0, 0.0, 0.0)
	var nose_dir := (-tangent if reverse_face else tangent).normalized()
	return {"pos": pos, "dir": nose_dir}

func _sample_dist_point(pts: Array, cum: Array, target_d: float) -> Vector3:
	for i in range(cum.size() - 1):
		var d0 := float(cum[i])
		var d1 := float(cum[i + 1])
		if target_d <= d1 or i == cum.size() - 2:
			var t := clampf((target_d - d0) / maxf(d1 - d0, 0.001), 0.0, 1.0)
			return (pts[i] as Vector3).lerp(pts[i + 1] as Vector3, t)
	return pts.back()

func _on_telemetry_updated(
	rpm: float, _ca: float, _cb: float, _cc: float, _v: float, _f: float,
	_temp: float, _vib: float, _p_kw: float, _pf: float, flow: float
) -> void:
	set_motor_rpm(rpm, flow)

func set_motor_rpm(rpm: float, flow_kg_s: float = 0.8) -> void:
	current_rpm = rpm
	current_flow_kg_s = maxf(0.0, flow_kg_s)
	is_production_active = (current_rpm > min_active_rpm)

func _process(delta: float) -> void:
	step_production(delta)

var _product_flow_initialized: bool = false
var _product_phase_progress: float = 0.0
var _line_flow_efficiency: float = 1.0
var _screw_trit_shaft: Node3D = null
var _screw_secador_shaft: Node3D = null
var _tolva_grain_node: Node3D = null
var _tolva_grain_base_y: float = 0.0
var _super_saco_node: Node3D = null
var _super_saco_base_scale: Vector3 = Vector3.ONE
var _glow_ctrl_ref: Node = null
var _product_routes: Array[Dictionary] = []
var _product_emitters: Array[Dictionary] = []
var _product_stage_rates: Dictionary = {}
var _bags_pallet_stack_nodes: Array[Node3D] = []

func step_production(delta: float) -> void:
	is_production_active = (current_rpm > min_active_rpm)
	_step_product_flow(delta)

	# 1. Rotación física del acoplamiento del molino y sinfín proporcional a omega_m
	if is_production_active:
		var omega_rad_s: float = (current_rpm * TAU) / 60.0
		if mill_coupling_node != null:
			mill_coupling_node.rotate_x(omega_rad_s * delta * 0.25)
		var trit_rate: float = float(_product_stage_rates.get("tornillo_trituradora", 1.0))
		if _screw_trit_shaft != null and is_instance_valid(_screw_trit_shaft):
			_screw_trit_shaft.rotate_x(omega_rad_s * delta * 0.35 * trit_rate)
		var sec_rate: float = float(_product_stage_rates.get("tornillo_secador", 1.0))
		if _screw_secador_shaft != null and is_instance_valid(_screw_secador_shaft):
			_screw_secador_shaft.rotate_x(omega_rad_s * delta * 0.35 * sec_rate)
		_auger_angle = fmod(_auger_angle + omega_rad_s * delta * 0.35, TAU)
		if auger_node != null:
			var rot_basis := Basis(Vector3.RIGHT, _auger_angle)
			var pivot := Vector3(_auger_base_pos.x, 5.31496, 5.31496)
			var offset_from_pivot := Vector3(0.0, -5.31496, -5.31496)
			auger_node.transform = Transform3D(rot_basis, pivot + rot_basis * offset_from_pivot)

		# 2. Acumulación de molienda, ensacado de 50 kg y paletizado
		total_grain_milled_kg += current_flow_kg_s * delta
		bags_50kg_produced = int(floor(total_grain_milled_kg / bag_weight_kg))
		pallets_completed = int(floor(float(bags_50kg_produced) / float(bags_per_pallet)))
	else:
		if grain_particles != null:
			grain_particles.emitting = false

	# 3. Ciclo completo articulado para los 3 tractocamiones grandes, furgón y cargue manual por operarios
	_update_truck_logistics(delta)

	_metrics_emit_timer += delta
	if _metrics_emit_timer >= 0.2:
		_metrics_emit_timer = 0.0
		var bus = get_node_or_null("/root/EventBus")
		if bus != null and bus.has_signal("production_metrics_updated"):
			bus.production_metrics_updated.emit(get_production_metrics())

func _update_truck_logistics(delta: float) -> void:
	_idle_pulse_t += delta
	var speed_scale: float = 1.0 if is_production_active else 0.78
	truck_cycle_time = fmod(truck_cycle_time + delta * speed_scale, TRUCK_CYCLE_DURATION)

	# Desfases matemáticamente optimizados (>20 m de separación mínima centro-a-centro en todo el ciclo de 300 s)
	var u_south: float = truck_cycle_time / TRUCK_CYCLE_DURATION
	var u_bay2: float = fmod(u_south + 0.38, 1.0)
	dispatch_cycle_time = fmod(u_south + 0.06, 1.0)
	var u_west: float = dispatch_cycle_time
	var u_staging: float = fmod(u_south * 5.0, 1.0)

	var south_loading_now := u_south < 0.145
	var bay2_loading_now := u_bay2 < 0.145
	var south_spotter = null if (south_loading_now or bay2_loading_now) else (_south_spotter if u_south >= 0.88 else null)
	var south_state := _update_single_truck_rig(_south_rig, u_south, delta, true, south_spotter, "Muelle de Carga Derecho", false)
	truck_cycle_phase = south_state["phase"]
	truck_tilt_angle_deg = south_state["tilt_deg"]

	var bay2_spotter = null if (south_loading_now or bay2_loading_now or south_spotter != null) else _south_spotter
	var bay2_state := _update_single_truck_rig(_bay2_rig, u_bay2, delta, false, bay2_spotter, "Muelle de Carga Derecho", false)
	_update_single_truck_rig(_staging_rig, u_staging, delta, false, null, "Patio Norte", false)
	_update_single_truck_rig(_west_rig, u_west, delta, false, _west_spotter, "Bahía Oeste (Est. 11)", true)

	_step_operator_bag_loading(delta, u_south, str(south_state.get("phase", "")), u_bay2, str(bay2_state.get("phase", "")))

	if intake_follow != null:
		intake_follow.progress_ratio = fmod(u_south, 1.0)
	if dispatch_follow != null:
		dispatch_follow.progress_ratio = fmod(u_west, 1.0)

	_update_main_gate_proximity()

func _smooth_u(t: float) -> float:
	var c := clampf(t, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)

# Perfil de desplazamiento S suave (aceleración cosenoidal continua sin saltos en velocidad ni posición)
func _trapezoid_u(t: float, accel_frac: float = 0.12) -> float:
	var c := clampf(t, 0.0, 1.0)
	var r := clampf(accel_frac, 0.02, 0.45)
	var inv_cruise := 1.0 / (1.0 - r)
	if c < r:
		return (0.5 * c - (r / (2.0 * PI)) * sin(PI * c / r)) * inv_cruise
	if c > 1.0 - r:
		var rem := 1.0 - c
		return 1.0 - (0.5 * rem - (r / (2.0 * PI)) * sin(PI * rem / r)) * inv_cruise
	return (c - 0.5 * r) * inv_cruise

func _update_single_truck_rig(rig: Dictionary, u: float, delta: float, is_intake: bool, spotter, bay_label: String, is_west_box: bool = false) -> Dictionary:
	var phase := "WEIGHING"
	var tilt_deg := 0.0
	var target_pos: Vector3 = rig.get("dock_pos", Vector3.ZERO)
	var target_yaw: float = float(rig.get("dock_yaw", 0.0))
	var engine_pitch: float = 0.86
	var engine_vol: float = -7.0
	var spotter_anim := "inspect"
	var spotter_msg := ""
	var active_route: Dictionary = {}
	var route_s: float = 0.0
	var reverse_mode: bool = false
	var is_moving: bool = false
	var steer_bias_rad: float = 0.0

	# Ventanas proporcionales a la longitud real de cada tramo para velocidad crucero uniforme (~7 km/h)
	# sin adelantamientos ni cruces entre camiones en toda la vía perimetral
	var u_weigh_end: float = 0.08 if is_west_box else 0.06
	var u_dock_end: float = 0.22 if is_west_box else 0.16
	var u_exit_end: float = 0.52 if is_west_box else 0.31
	var u_transit_end: float = 0.60 if is_west_box else 0.40
	var u_enter_end: float = 0.86 if is_west_box else 0.90
	var u_rev_end: float = 0.94 if is_west_box else 1.00

	if bool(rig.get("is_closed_loop", false)):
		phase = "YARD_MANEUVER"
		active_route = rig.get("exit_route", {})
		route_s = fposmod(u, 1.0)
		is_moving = true
		if not active_route.is_empty():
			var sm := _sample_route(active_route, route_s, false)
			target_pos = sm["pos"]
			target_yaw = atan2(-sm["dir"].x, -sm["dir"].z)
		engine_pitch = 0.96 + 0.04 * sin(u * TAU)
		engine_vol = -5.0
	elif u < u_weigh_end or u >= u_rev_end:
		phase = "WEIGHING"
		engine_pitch = 0.86
		engine_vol = -7.5
		spotter_anim = "inspect"
		spotter_msg = "Aquí estamos pesando el camión en la báscula antes de autorizar la carga."
	elif u < u_dock_end:
		phase = "TILTING_UNLOAD"
		var local_p := (u - u_weigh_end) / maxf(u_dock_end - u_weigh_end, 0.001)
		# El semirremolque contenedor permanece siempre acoplado a la quinta rueda (nunca se levanta ni se separa)
		tilt_deg = 0.0
		engine_pitch = 0.92 if is_intake else 0.88
		engine_vol = -5.5 if is_intake else -7.0
		spotter_anim = "interact" if sin(local_p * PI * 2.0) > 0.0 else "inspect"
		spotter_msg = "Estamos descargando el grano hacia la tolva, mantén distancia en la bahía." if is_intake else "Estamos subiendo las estibas de sacos de 50 kilos al camión de despacho."
	elif u < u_exit_end:
		phase = "EXITING_STATION"
		route_s = _trapezoid_u((u - u_dock_end) / maxf(u_exit_end - u_dock_end, 0.001), 0.10 if is_west_box else 0.12)
		active_route = rig.get("exit_route", {})
		is_moving = true
		if not active_route.is_empty():
			var sample := _sample_route(active_route, route_s, false)
			target_pos = sample["pos"]
			target_yaw = atan2(-sample["dir"].x, -sample["dir"].z)
		engine_pitch = 1.00 + 0.09 * sin(route_s * PI)
		engine_vol = -2.5
		spotter_anim = "idle"
		spotter_msg = "El camión ya terminó aquí y va saliendo despacio rumbo a la portería."
	elif u < u_transit_end:
		phase = "EXTERIOR_TRANSIT"
		route_s = _trapezoid_u((u - u_exit_end) / maxf(u_transit_end - u_exit_end, 0.001), 0.10)
		active_route = rig.get("transit_route", {})
		is_moving = true
		if not active_route.is_empty():
			var sample := _sample_route(active_route, route_s, false)
			target_pos = sample["pos"]
			target_yaw = atan2(-sample["dir"].x, -sample["dir"].z)
		engine_pitch = 1.04
		engine_vol = -3.5
		spotter_anim = "idle"
		spotter_msg = "El conductor está dando la vuelta afuera para volver a entrar con calma."
	elif u < u_enter_end:
		phase = "ENTERING_APPROACH"
		route_s = _trapezoid_u((u - u_transit_end) / maxf(u_enter_end - u_transit_end, 0.001), 0.10 if is_west_box else 0.08)
		active_route = rig.get("enter_route", {})
		is_moving = true
		if not active_route.is_empty():
			var sample := _sample_route(active_route, route_s, false)
			target_pos = sample["pos"]
			target_yaw = atan2(-sample["dir"].x, -sample["dir"].z)
		engine_pitch = 1.04 - 0.06 * route_s
		engine_vol = -2.5
		spotter_anim = "inspect"
		spotter_msg = "Viene entrando un camión por la calzada; quédate en la zona peatonal."
	else:
		phase = "REVERSING_TO_DOCK"
		route_s = _trapezoid_u((u - u_enter_end) / maxf(u_rev_end - u_enter_end, 0.001), 0.14)
		active_route = rig.get("reverse_route", {})
		reverse_mode = true
		is_moving = true
		if not active_route.is_empty():
			var sample := _sample_route(active_route, route_s, true)
			target_pos = sample["pos"]
			target_yaw = atan2(-sample["dir"].x, -sample["dir"].z)
			# Maniobra de reversa natural alineada al muelle (sin contragiro artificial exagerado)
			if bool(rig.get("is_semi", false)):
				steer_bias_rad = sin(route_s * PI) * deg_to_rad(3.0)
				target_yaw += steer_bias_rad
		engine_pitch = 0.95
		engine_vol = -4.0
		spotter_anim = "signal_truck"
		spotter_msg = "%s: ¡Atención! Maniobra lenta en reversa (<5 km/h) con alarma activa." % bay_label

	if is_intake and grain_particles != null:
		grain_particles.emitting = (phase == "TILTING_UNLOAD" and is_production_active)

	if rig.is_empty():
		return {"phase": phase, "tilt_deg": tilt_deg}

	var mover := rig["mover"] as Node3D
	var visual := rig["visual"] as Node3D
	var tilt_pivot := rig["tilt_pivot"] as Node3D

	var prev_pos: Vector3 = rig.get("pos", target_pos)
	var prev_yaw: float = float(rig["cur_yaw"])
	var prev_u: float = float(rig.get("prev_u", -1.0))
	var du := absf(u - prev_u) if prev_u >= 0.0 else 0.0
	if du > 0.5:
		du = 1.0 - du
	var is_jump := (prev_u < 0.0) or (du > 0.04) or (delta > 0.25)
	rig["prev_u"] = u

	var yaw_rate_blend := 3.8 * delta
	var cur_yaw := target_yaw if is_jump else lerp_angle(prev_yaw, target_yaw, clampf(yaw_rate_blend, 0.0, 1.0))
	var yaw_vel := 0.0 if (delta <= 0.0001 or is_jump) else wrapf(cur_yaw - prev_yaw, -PI, PI) / delta
	var lin_dist := Vector2(target_pos.x - prev_pos.x, target_pos.z - prev_pos.z).length()
	var signed_speed := (0.0 if delta <= 0.0001 or is_jump else (lin_dist / delta) * (-1.0 if reverse_mode else 1.0)) if is_moving else 0.0
	var prev_spd: float = float(rig.get("cur_speed_ms", 0.0))
	var lin_accel := 0.0 if (delta <= 0.0001 or is_jump) else clampf((signed_speed - prev_spd) / delta, -3.0, 3.0)
	rig["cur_speed_ms"] = signed_speed
	rig["cur_yaw"] = cur_yaw
	rig["pos"] = target_pos
	rig["phase"] = phase

	if mover != null and is_instance_valid(mover):
		mover.global_position = target_pos
		mover.rotation = Vector3(0.0, cur_yaw, 0.0)

	# Física de articulación de quinta rueda (kingpin -> eje trasero del semirremolque)
	if bool(rig.get("is_semi", false)):
		_step_articulated_semi_hitch(rig, target_pos, cur_yaw, active_route, route_s, reverse_mode, is_moving, is_jump, delta)

	# Suspensión realista (cabeceo en frenada/arranque, balanceo en curva y ralentí diésel sutil)
	if visual != null and is_instance_valid(visual):
		var target_pitch := clampf(-lin_accel * 0.011, -deg_to_rad(1.3), deg_to_rad(1.3))
		var target_roll := clampf(-yaw_vel * absf(signed_speed) * 0.022, -deg_to_rad(1.8), deg_to_rad(1.8))
		var blend_s := 1.0 if is_jump else clampf(delta * 5.5, 0.0, 1.0)
		var cur_p := lerpf(float(rig.get("body_pitch_rad", 0.0)), target_pitch, blend_s)
		var cur_r := lerpf(float(rig.get("body_roll_rad", 0.0)), target_roll, blend_s)
		rig["body_pitch_rad"] = cur_p
		rig["body_roll_rad"] = cur_r
		var vib_amp := 0.0022 if is_moving else 0.0014
		visual.position.y = sin(_idle_pulse_t * 28.0) * vib_amp
		visual.rotation.x = cur_p
		visual.rotation.z = cur_r

	if tilt_pivot != null and is_instance_valid(tilt_pivot):
		# Mantener la caja del semirremolque nivelada y acoplada firmemente sobre la quinta rueda
		tilt_pivot.rotation.x = 0.0

	# Giro realista de ruedas proporcional a distancia recorrida y dirección de ruedas delanteras
	var steer_target := clampf(yaw_vel * 0.55 * (-1.0 if reverse_mode else 1.0), -deg_to_rad(25.0), deg_to_rad(25.0))
	var cur_steer := lerpf(float(rig.get("steer_angle_rad", 0.0)), steer_target, 1.0 if is_jump else clampf(delta * 6.5, 0.0, 1.0))
	rig["steer_angle_rad"] = cur_steer
	var wheel_spin: float = float(rig.get("wheel_spin_rad", 0.0))
	if is_moving and not is_jump:
		wheel_spin = fmod(wheel_spin - signed_speed * delta / 0.54, TAU)
		rig["wheel_spin_rad"] = wheel_spin
	for wp_dict in (rig.get("wheel_pivots", []) as Array):
		var sp := wp_dict.get("spin_pivot") as Node3D
		if sp != null and is_instance_valid(sp):
			var r_eff: float = float(wp_dict.get("radius", 0.54))
			sp.rotation.x = wheel_spin * (0.54 / maxf(r_eff, 0.1))
		var st := wp_dict.get("steer_pivot") as Node3D
		if st != null and is_instance_valid(st):
			st.rotation.y = cur_steer

	# Audio espacial 3D del camión
	_sync_rig_audio(rig, phase, engine_pitch, engine_vol, u)

	# Operario señalero en estación mirando al camión y haciendo señas reales
	if spotter != null and is_instance_valid(spotter) and spotter.has_method("set_work_state"):
		spotter.set_work_state(spotter_anim, target_pos, spotter_msg)

	return {"phase": phase, "tilt_deg": tilt_deg}

func _step_articulated_semi_hitch(
	rig: Dictionary,
	kp_world_pos: Vector3,
	cab_yaw: float,
	active_route: Dictionary,
	route_s: float,
	reverse_mode: bool,
	is_moving: bool,
	is_jump: bool,
	delta: float
) -> void:
	var art_piv := rig.get("articulation_pivot") as Node3D
	if art_piv == null or not is_instance_valid(art_piv):
		return
	var axle_dist: float = float(rig.get("kingpin_to_axle_m", 11.0))
	var kp_xz := Vector2(kp_world_pos.x, kp_world_pos.z)
	var init_rel: float = float(rig.get("initial_rel_yaw", 0.0))
	var trl_yaw: float = float(rig.get("trailer_yaw", cab_yaw))

	if is_jump:
		# Tras salto discontinuo de tiempo, inferir orientación del remolque siguiendo la curvatura de la ruta
		if not active_route.is_empty():
			var total_len: float = float(active_route.get("total", 1.0))
			var back_ds := clampf(axle_dist / maxf(total_len, 1.0), 0.01, 0.35)
			var sample_back: Dictionary
			if bool(active_route.get("closed", false)):
				sample_back = _sample_route(active_route, fposmod(route_s - back_ds + 1.0, 1.0), reverse_mode)
			elif reverse_mode:
				sample_back = _sample_route(active_route, minf(1.0, route_s + back_ds), reverse_mode)
			else:
				sample_back = _sample_route(active_route, maxf(0.0, route_s - back_ds), reverse_mode)
			var p_back := sample_back["pos"] as Vector3
			var d_vec := Vector2(kp_xz.x - p_back.x, kp_xz.y - p_back.z)
			if d_vec.length_squared() > 0.25:
				trl_yaw = atan2(-d_vec.x, -d_vec.y)
			else:
				trl_yaw = cab_yaw
		else:
			trl_yaw = wrapf(cab_yaw + (init_rel if not is_moving else 0.0), -PI, PI)
		var rel_jump := clampf(wrapf(trl_yaw - cab_yaw, -PI, PI), -deg_to_rad(50.0), deg_to_rad(50.0))
		trl_yaw = cab_yaw + rel_jump
		var u0 := Vector2(-sin(trl_yaw), -cos(trl_yaw))
		rig["trailer_axle_xz"] = kp_xz - u0 * axle_dist
	elif reverse_mode:
		# En reversa: el semirremolque se endereza con fluidez hacia el eje del muelle
		var dock_y := float(rig.get("dock_yaw", cab_yaw))
		var back_blend := _smooth_u(clampf((route_s - 0.05) / 0.85, 0.0, 1.0))
		trl_yaw = lerp_angle(trl_yaw, dock_y, maxf(back_blend * 0.22, clampf(delta * 2.0, 0.0, 1.0)))
		var rel_r := clampf(wrapf(trl_yaw - cab_yaw, -PI, PI), -deg_to_rad(24.0), deg_to_rad(24.0))
		trl_yaw = cab_yaw + rel_r
		var ur := Vector2(-sin(trl_yaw), -cos(trl_yaw))
		rig["trailer_axle_xz"] = kp_xz - ur * axle_dist
	elif is_moving:
		# Avance cinemático no holonómico suavizado: el remolque sigue la quinta rueda de forma natural
		var prev_axle: Vector2 = rig.get("trailer_axle_xz", kp_xz - Vector2(-sin(trl_yaw), -cos(trl_yaw)) * axle_dist)
		var pull_vec := kp_xz - prev_axle
		if pull_vec.length_squared() > 0.0001:
			var u_pull := pull_vec.normalized()
			var desired_trl_yaw := atan2(-u_pull.x, -u_pull.y)
			var smooth_trl_yaw := lerp_angle(trl_yaw, desired_trl_yaw, clampf(delta * 5.0, 0.0, 1.0))
			var rel_fwd := clampf(wrapf(smooth_trl_yaw - cab_yaw, -PI, PI), -deg_to_rad(42.0), deg_to_rad(42.0))
			trl_yaw = cab_yaw + rel_fwd
			var u_clamped := Vector2(-sin(trl_yaw), -cos(trl_yaw))
			rig["trailer_axle_xz"] = kp_xz - u_clamped * axle_dist
	else:
		# En bahía / báscula: mantener ejes bloqueados con alineación limpia
		trl_yaw = lerp_angle(trl_yaw, cab_yaw, clampf(delta * 3.0, 0.0, 1.0))
		var u_idle := Vector2(-sin(trl_yaw), -cos(trl_yaw))
		rig["trailer_axle_xz"] = kp_xz - u_idle * axle_dist

	rig["trailer_yaw"] = trl_yaw
	var rel_final := clampf(wrapf(trl_yaw - cab_yaw, -PI, PI), -deg_to_rad(44.0), deg_to_rad(44.0))
	art_piv.rotation.y = rel_final - init_rel

	var tilt_p := rig.get("tilt_pivot") as Node3D
	if tilt_p != null and is_instance_valid(tilt_p):
		tilt_p.rotation.y = init_rel
	var trl_hull := rig.get("trailer_hull_body") as Node3D
	if trl_hull != null and is_instance_valid(trl_hull):
		trl_hull.rotation.y = init_rel

func _sync_rig_audio(rig: Dictionary, phase: String, engine_pitch: float, engine_vol: float, u: float) -> void:
	var is_headless := DisplayServer.get_name() == "headless"
	var diesel := rig.get("diesel_aud") as AudioStreamPlayer3D
	if diesel != null and is_instance_valid(diesel):
		diesel.pitch_scale = engine_pitch
		diesel.volume_db = engine_vol
		if not is_headless and diesel.stream != null and not diesel.playing:
			diesel.play()

	var rev := rig.get("reverse_aud") as AudioStreamPlayer3D
	if rev != null and is_instance_valid(rev):
		var need_beep := (phase == "REVERSING_TO_DOCK")
		if not is_headless and rev.stream != null:
			if need_beep and not rev.playing:
				rev.play()
			elif not need_beep and rev.playing:
				rev.stop()

	var prev_p := str(rig.get("prev_phase", ""))
	if prev_p != "" and prev_p != phase:
		rig["horn_played"] = false
		var sfx := rig.get("sfx_aud") as AudioStreamPlayer3D
		if sfx != null and is_instance_valid(sfx) and not is_headless:
			if phase == "WEIGHING" or phase == "EXITING_STATION":
				sfx.stream = SoundSynth.create_truck_air_brake_sound()
				sfx.pitch_scale = randf_range(0.95, 1.06)
				sfx.play()
	rig["prev_phase"] = phase

	# Corto toque de bocina neumática justo al iniciar la marcha hacia la salida
	if phase == "EXITING_STATION" and u > 0.175 and not bool(rig.get("horn_played", false)):
		rig["horn_played"] = true
		var sfx := rig.get("sfx_aud") as AudioStreamPlayer3D
		if sfx != null and is_instance_valid(sfx) and not is_headless:
			sfx.stream = SoundSynth.create_truck_horn_sound()
			sfx.pitch_scale = 1.0 if rig == _south_rig else 1.12
			sfx.play()

func _sample_polyline_3d(pts: Array[Vector3], s_norm: float) -> Dictionary:
	if pts.is_empty():
		return {"pos": Vector3.ZERO, "look": Vector3.FORWARD}
	if pts.size() == 1:
		return {"pos": pts[0], "look": pts[0] + Vector3.FORWARD}
	var seg_lens: Array[float] = []
	var total := 0.0
	for i in range(pts.size() - 1):
		var l := pts[i].distance_to(pts[i + 1])
		seg_lens.append(l)
		total += l
	if total <= 0.001:
		return {"pos": pts[0], "look": pts[pts.size() - 1]}
	var target_d := clampf(s_norm, 0.0, 1.0) * total
	var acc := 0.0
	for i in range(seg_lens.size()):
		var l := seg_lens[i]
		if target_d <= acc + l or i == seg_lens.size() - 1:
			var lt := clampf((target_d - acc) / maxf(l, 0.001), 0.0, 1.0)
			var pos := pts[i].lerp(pts[i + 1], lt)
			var dir := (pts[i + 1] - pts[i]).normalized()
			return {"pos": pos, "look": pos + dir * 1.5}
		acc += l
	return {"pos": pts[pts.size() - 1], "look": pts[pts.size() - 1] + Vector3.RIGHT}

func _place_carried_bag(bag: Node3D, worker: Node3D, push_forward: float = 0.0, lift_y: float = 0.0) -> void:
	if bag == null or not is_instance_valid(bag) or worker == null or not is_instance_valid(worker):
		return
	var yaw := worker.rotation.y
	var fwd := Vector3(-sin(yaw), 0.0, -cos(yaw)).normalized()
	bag.global_position = worker.global_position + fwd * (0.36 + push_forward) + Vector3(0.0, 0.76 + lift_y, 0.0)
	bag.rotation = Vector3(0.0, yaw, 0.0)

func _step_operator_bag_loading(delta: float, u_south: float, south_phase: String, u_bay2: float, bay2_phase: String) -> void:
	if _logistics_loader == null or not is_instance_valid(_logistics_loader):
		var sr := get_parent()
		if sr != null:
			_logistics_loader = sr.find_child("WorkerLogistics", true, false)
	if _south_spotter == null or not is_instance_valid(_south_spotter):
		var sr2 := get_parent()
		if sr2 != null:
			_south_spotter = sr2.find_child("WorkerDockSouth", true, false)

	var south_docked := false
	if not _south_rig.is_empty():
		var s_pos: Vector3 = _south_rig.get("pos", Vector3(999.0, 0.0, 999.0))
		south_docked = Vector2(s_pos.x - SOUTH_DOCK_POS.x, s_pos.z - SOUTH_DOCK_POS.z).length() <= 3.5 and (south_phase == "WEIGHING" or south_phase == "TILTING_UNLOAD") and u_south < 0.145

	var bay2_docked := false
	if not _bay2_rig.is_empty():
		var b2_pos: Vector3 = _bay2_rig.get("pos", Vector3(999.0, 0.0, 999.0))
		bay2_docked = Vector2(b2_pos.x - BAY2_DOCK_POS.x, b2_pos.z - BAY2_DOCK_POS.z).length() <= 3.5 and (bay2_phase == "WEIGHING" or bay2_phase == "TILTING_UNLOAD") and u_bay2 < 0.145

	var can_load_now: bool = south_docked or bay2_docked
	_bay2_truck_parked_for_loading = can_load_now

	# Culata del semirremolque acoplado al ras del muelle de la puerta enrollable derecha (X=-15.0, Z=25.45)
	var trailer_rear_target := Vector3(-14.95, 1.18, 25.45)

	if not can_load_now:
		_bag_load_timer = 0.0
		if _carried_bag_logistics != null and is_instance_valid(_carried_bag_logistics):
			_carried_bag_logistics.visible = false
		if _carried_bag_dock != null and is_instance_valid(_carried_bag_dock):
			_carried_bag_dock.visible = false

		# Retornar a WorkerLogistics de forma segura al interior del almacén
		if _logistics_loader != null and is_instance_valid(_logistics_loader):
			var wlog := _logistics_loader as Node3D
			var d_home := wlog.global_position.distance_to(_LOGISTICS_HOME_POS)
			if d_home > 0.18:
				_logistics_returning_home = true
				var step_p := wlog.global_position.move_toward(_LOGISTICS_HOME_POS, clampf(delta * 3.8, 0.05, 2.5))
				step_p.y = 0.794
				if _logistics_loader.has_method("set_carry_pose"):
					_logistics_loader.set_carry_pose(
						step_p, _LOGISTICS_HOME_POS, "walk",
						"Camión saliendo del muelle derecho; regresando al almacén hasta el próximo arribo."
					)
			else:
				_logistics_returning_home = false
				if _logistics_loader.has_method("set_carry_pose"):
					_logistics_loader.set_carry_pose(
						_LOGISTICS_HOME_POS, Vector3(-15.65, 0.794, 25.45), "inspect",
						"Sin camión parqueado en la puerta derecha; esperando arribo para iniciar el cargue."
					)

		# Mantener a WorkerDockSouth junto a la puerta enrollable derecha
		if _south_spotter != null and is_instance_valid(_south_spotter):
			var wdock := _south_spotter as Node3D
			if wdock.global_position.distance_to(_DOCK_SOUTH_HOME_POS) > 0.12:
				wdock.global_position = _DOCK_SOUTH_HOME_POS

		# Cerrar cortina enrollable automáticamente cuando los operarios están adentro
		if _roll_up_dock_door != null and is_instance_valid(_roll_up_dock_door) and _rollup_opened_by_loader:
			var loader_inside := (_logistics_loader == null) or ((_logistics_loader as Node3D).global_position.x <= -16.2)
			if loader_inside:
				_rollup_opened_by_loader = false
				if _roll_up_dock_door.has_method("close_door"):
					_roll_up_dock_door.close_door(false)
		return

	# Camión parqueado en la puerta enrollable derecha: abrir cortina y activar cargue manual directo al remolque
	if _roll_up_dock_door != null and is_instance_valid(_roll_up_dock_door) and not bool(_roll_up_dock_door.is_open):
		_rollup_opened_by_loader = true
		if _roll_up_dock_door.has_method("open_door"):
			_roll_up_dock_door.open_door(false)

	_bag_load_timer += delta

	# 1) WorkerLogistics: recoge sacos en almacén/ciclones y sale recto por la puerta enrollable derecha (carril Z=25.75)
	if _logistics_loader != null and is_instance_valid(_logistics_loader) and _logistics_loader.has_method("set_carry_pose"):
		var cycle_l := 12.0
		var tl := fmod(_bag_load_timer, cycle_l)
		var l_pos := _LOGISTICS_CARRY_WAYPOINTS[0]
		var l_look := Vector3(-25.05, 0.82, 28.8)
		var l_anim := "interact"
		var l_has_bag := false
		var l_push := 0.0
		var l_lift := 0.0

		if tl < 0.85:
			l_pos = _LOGISTICS_CARRY_WAYPOINTS[0]
			l_look = Vector3(-25.05, 0.82, 28.8)
			l_anim = "interact"
			l_has_bag = (tl >= 0.45)
		elif tl < 6.45:
			var s_go := (tl - 0.85) / 5.6
			var sm := _sample_polyline_3d(_LOGISTICS_CARRY_WAYPOINTS, s_go)
			l_pos = sm["pos"] as Vector3
			l_look = sm["look"] as Vector3
			l_anim = "carry_walk"
			l_has_bag = true
		elif tl < 7.55:
			var p_drop := (tl - 6.45) / 1.1
			l_pos = _LOGISTICS_CARRY_WAYPOINTS[_LOGISTICS_CARRY_WAYPOINTS.size() - 1]
			l_look = Vector3(trailer_rear_target.x, trailer_rear_target.y, 25.55)
			l_anim = "interact"
			l_has_bag = (p_drop < 0.78)
			l_push = p_drop * 0.85
			l_lift = sin(p_drop * PI) * 0.28
		else:
			var s_ret := 1.0 - ((tl - 7.55) / 4.45)
			var sm_r := _sample_polyline_3d(_LOGISTICS_CARRY_WAYPOINTS, s_ret)
			l_pos = sm_r["pos"] as Vector3
			var prev_s := clampf(s_ret - 0.06, 0.0, 1.0)
			l_look = (_sample_polyline_3d(_LOGISTICS_CARRY_WAYPOINTS, prev_s)["pos"] as Vector3)
			l_anim = "walk"
			l_has_bag = false

		_logistics_loader.set_carry_pose(
			l_pos, l_look, l_anim,
			"Cargando los sacos desde el almacén hacia el camión parqueado en la puerta derecha."
		)
		if _carried_bag_logistics != null and is_instance_valid(_carried_bag_logistics):
			_carried_bag_logistics.visible = l_has_bag
			if l_has_bag:
				_place_carried_bag(_carried_bag_logistics, _logistics_loader as Node3D, l_push, l_lift)

	# 2) WorkerDockSouth: toma los sacos estibados junto a la puerta derecha y los carga directo al remolque sin salir de la losa (X <= -15.70)
	if _south_spotter != null and is_instance_valid(_south_spotter) and _south_spotter.has_method("set_carry_pose"):
		var cycle_d := 7.0
		var td := fmod(_bag_load_timer, cycle_d)
		var p_pick := Vector3(-16.4, 0.794, 24.75)
		var p_edge := Vector3(-15.75, 0.794, 24.85)
		var d_pos := p_pick
		var d_look := Vector3(-17.1, 0.794, 24.55)
		var d_anim := "interact"
		var d_has_bag := false
		var d_push := 0.0
		var d_lift := 0.0

		if td < 0.9:
			d_pos = p_pick
			d_look = Vector3(-17.1, 0.794, 24.55)
			d_anim = "interact"
			d_has_bag = (td >= 0.45)
		elif td < 3.2:
			var u_go := (td - 0.9) / 2.3
			d_pos = p_pick.lerp(p_edge, u_go)
			d_look = p_edge + Vector3(1.0, 0.0, 0.15)
			d_anim = "carry_walk"
			d_has_bag = true
		elif td < 4.4:
			var u_drop := (td - 3.2) / 1.2
			d_pos = p_edge
			d_look = Vector3(trailer_rear_target.x, trailer_rear_target.y, 25.10)
			d_anim = "interact"
			d_has_bag = (u_drop < 0.78)
			d_push = u_drop * 0.68
			d_lift = sin(u_drop * PI) * 0.24
		else:
			var u_ret := (td - 4.4) / 2.6
			d_pos = p_edge.lerp(p_pick, u_ret)
			d_look = p_pick
			d_anim = "walk"
			d_has_bag = false

		_south_spotter.set_carry_pose(
			d_pos, d_look, d_anim,
			"Cargando sacos de 50 kg por la puerta enrollable derecha directo al tractocamión."
		)
		if _carried_bag_dock != null and is_instance_valid(_carried_bag_dock):
			_carried_bag_dock.visible = d_has_bag
			if d_has_bag:
				_place_carried_bag(_carried_bag_dock, _south_spotter as Node3D, d_push, d_lift)

func _update_main_gate_proximity() -> void:
	_gate_opened_by_trucks = _sync_single_gate_proximity(_main_gate, _gate_opened_by_trucks)
	_exit_gate_opened_by_trucks = _sync_single_gate_proximity(_exit_gate, _exit_gate_opened_by_trucks)

func _sync_single_gate_proximity(gate_node, was_opened_by_trucks: bool) -> bool:
	if gate_node == null or not is_instance_valid(gate_node):
		return was_opened_by_trucks
	var gate_pos: Vector3 = (gate_node as Node3D).global_position
	var truck_near := false
	for rig in [_south_rig, _bay2_rig, _west_rig]:
		if rig.is_empty():
			continue
		var p: Vector3 = rig["pos"]
		if Vector2(p.x, p.z).distance_to(Vector2(gate_pos.x, gate_pos.z)) <= 24.0:
			truck_near = true
			break

	var player_near := false
	if _player_ref != null and is_instance_valid(_player_ref):
		player_near = Vector2(_player_ref.global_position.x, _player_ref.global_position.z).distance_to(Vector2(gate_pos.x, gate_pos.z)) <= 10.0

	var play_sfx := DisplayServer.get_name() != "headless"
	if truck_near:
		if not gate_node.is_open:
			was_opened_by_trucks = true
			gate_node.open_door(play_sfx)
	elif was_opened_by_trucks and not player_near:
		var any_close := false
		for rig in [_south_rig, _bay2_rig, _west_rig]:
			if rig.is_empty():
				continue
			var p: Vector3 = rig["pos"]
			if Vector2(p.x, p.z).distance_to(Vector2(gate_pos.x, gate_pos.z)) <= 26.0:
				any_close = true
				break
		if not any_close:
			was_opened_by_trucks = false
			gate_node.close_door(play_sfx)
	return was_opened_by_trucks

func _find_sub_node(root_n: Node, parent_key: String, child_key: String) -> Node3D:
	if root_n == null:
		return null
	var p := root_n.find_child(parent_key, true, false)
	if p == null:
		return null
	return p.find_child(child_key, true, false) as Node3D

func _world_xf_relative(n: Node3D, stop_ancestor: Node) -> Transform3D:
	var xf := n.transform
	var p := n.get_parent()
	while p != null and p != stop_ancestor:
		if p is Node3D:
			xf = (p as Node3D).transform * xf
		p = p.get_parent()
	return xf

func _create_normalized_glb_carrier(src_mi: MeshInstance3D, stop_ancestor: Node, target_size: Vector3, carrier_name: String, mat_override: Material = null) -> Node3D:
	if src_mi == null or src_mi.mesh == null:
		return null
	var wrapper := Node3D.new()
	wrapper.name = carrier_name
	var child := MeshInstance3D.new()
	child.mesh = src_mi.mesh
	if mat_override != null:
		child.material_override = mat_override
	elif src_mi.mesh.get_surface_count() > 0:
		var m0 := src_mi.mesh.surface_get_material(0)
		if m0 != null:
			child.material_override = m0

	var xf := _world_xf_relative(src_mi, stop_ancestor)
	var xf_no_trans := Transform3D(xf.basis, Vector3.ZERO)
	var mn := Vector3(1e9, 1e9, 1e9)
	var mx := Vector3(-1e9, -1e9, -1e9)
	var arr := src_mi.mesh.surface_get_arrays(0)
	if arr.size() > Mesh.ARRAY_VERTEX and arr[Mesh.ARRAY_VERTEX] is PackedVector3Array:
		for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			var w: Vector3 = xf_no_trans * v
			mn = mn.min(w)
			mx = mx.max(w)
	else:
		var ab := src_mi.get_aabb()
		for ix in range(2):
			for iy in range(2):
				for iz in range(2):
					var w: Vector3 = xf_no_trans * (ab.position + Vector3(ab.size.x * ix, ab.size.y * iy, ab.size.z * iz))
					mn = mn.min(w)
					mx = mx.max(w)

	var sz := (mx - mn).max(Vector3(0.001, 0.001, 0.001))
	var sc := Vector3(target_size.x / sz.x, target_size.y / sz.y, target_size.z / sz.z)
	var center_offset := Vector3((mn.x + mx.x) * 0.5 * sc.x, mn.y * sc.y, (mn.z + mx.z) * 0.5 * sc.z)
	child.transform = Transform3D(Basis.from_scale(sc) * xf.basis, -center_offset)
	wrapper.add_child(child)
	return wrapper

func _setup_product_flow(plant_model: Node) -> void:
	if _product_flow_initialized or plant_model == null:
		return
	var host := get_node_or_null("ProductFlowVisuals") as Node3D
	if host != null:
		host.queue_free()
	host = Node3D.new()
	host.name = "ProductFlowVisuals"
	add_child(host)

	var scene_root := plant_model.get_parent()
	if scene_root != null:
		scene_root = scene_root.get_parent()
	var stop_anc := scene_root if scene_root != null else plant_model

	var grain_src := _find_sub_node(plant_model, "Node1583", "Geom3D1462") as MeshInstance3D
	var sack_src := _find_sub_node(plant_model, "super saco", "Geom3D203") as MeshInstance3D
	if grain_src == null or sack_src == null:
		return

	var raw_kernel_tex := _create_product_particle_texture(false, Color(1.0, 0.84, 0.28, 1.0), Color(0.84, 0.56, 0.12, 1.0))
	var grist_tex := _create_product_particle_texture(false, Color(1.0, 0.91, 0.52, 1.0), Color(0.90, 0.72, 0.28, 1.0))
	var flour_tex := _create_product_particle_texture(true, Color(1.0, 0.98, 0.90, 1.0), Color(0.96, 0.90, 0.76, 1.0))

	# Reubicar partículas de descarga en camión -> banda roja Group#510 y alinear BagConveyorPath a Zona 5
	if grain_particles != null and is_instance_valid(grain_particles):
		grain_particles.global_position = Vector3(-32.18, 2.24, 51.31)
		var g_pm := ParticleProcessMaterial.new()
		g_pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		g_pm.emission_box_extents = Vector3(0.20, 0.08, 0.36)
		g_pm.direction = Vector3(0.55, -1.0, 0.0)
		g_pm.spread = 20.0
		g_pm.initial_velocity_min = 1.6
		g_pm.initial_velocity_max = 2.6
		g_pm.gravity = Vector3(0.0, -8.5, 0.0)
		g_pm.scale_min = 0.75
		g_pm.scale_max = 1.25
		g_pm.color = Color(1.0, 0.86, 0.32, 1.0)
		grain_particles.process_material = g_pm
		grain_particles.amount = 140
		grain_particles.lifetime = 0.36
		grain_particles.visibility_aabb = AABB(Vector3(-6.0, -4.0, -6.0), Vector3(12.0, 8.0, 12.0))
		if grain_particles.draw_pass_1 is QuadMesh:
			var qm := (grain_particles.draw_pass_1 as QuadMesh).duplicate() as QuadMesh
			qm.size = Vector2(0.085, 0.085)
			var qmat := StandardMaterial3D.new()
			qmat.albedo_texture = raw_kernel_tex
			qmat.albedo_color = Color(1.0, 0.95, 0.82, 1.0)
			qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			qmat.alpha_scissor_threshold = 0.35
			qmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
			qmat.emission_enabled = true
			qmat.emission = Color(0.95, 0.72, 0.20)
			qmat.emission_energy_multiplier = 0.32
			qm.material = qmat
			grain_particles.draw_pass_1 = qm

	# Sacos portados por operarios hacia el camión parqueado en la puerta izquierda (nunca se mueven solos)
	_carried_bag_logistics = _create_normalized_glb_carrier(sack_src, stop_anc, Vector3(0.46, 0.56, 0.38), "MovingBag50kg")
	if _carried_bag_logistics != null:
		host.add_child(_carried_bag_logistics)
		_carried_bag_logistics.visible = false

	_carried_bag_dock = _create_normalized_glb_carrier(sack_src, stop_anc, Vector3(0.46, 0.56, 0.38), "DockCarriedBag50kg")
	if _carried_bag_dock != null:
		host.add_child(_carried_bag_dock)
		_carried_bag_dock.visible = false

	# Sacos estáticos junto a la puerta enrollable derecha esperando cargue manual al tractocamión
	for bay_spec in [
		{"name": "YellowBay_Saco_0", "pos": Vector3(-16.80, 0.80, 24.30), "yaw": 0.08},
		{"name": "YellowBay_Saco_1", "pos": Vector3(-16.80, 0.80, 26.55), "yaw": -0.06}
	]:
		var bay_bag := _create_normalized_glb_carrier(sack_src, stop_anc, Vector3(0.62, 0.72, 0.62), str(bay_spec["name"]))
		if bay_bag != null:
			host.add_child(bay_bag)
			bay_bag.global_position = bay_spec["pos"] as Vector3
			bay_bag.rotation.y = float(bay_spec["yaw"])

	# Super Sacos estacionarios llenándose bajo ambos ciclones (Group#14 Este + Node1179 Oeste) y estiba en Zona 5
	for fill_spec in [
		{"name": "WestCycloneFillSaco", "pos": Vector3(-26.88, 0.82, 29.15), "yaw": 0.15},
		{"name": "EastCycloneFillSaco", "pos": Vector3(-25.05, 0.82, 29.15), "yaw": -0.10}
	]:
		var fill_bag := _create_normalized_glb_carrier(sack_src, stop_anc, Vector3(0.76, 0.88, 0.76), str(fill_spec["name"]))
		if fill_bag != null:
			host.add_child(fill_bag)
			fill_bag.global_position = fill_spec["pos"] as Vector3
			fill_bag.rotation.y = float(fill_spec["yaw"])

	_bags_pallet_stack_nodes.clear()
	var stack_offsets: Array[Vector3] = [
		Vector3(-27.05, 0.82, 27.60),
		Vector3(-27.05, 0.82, 26.35)
	]
	for si in range(stack_offsets.size()):
		var sb := _create_normalized_glb_carrier(sack_src, stop_anc, Vector3(0.76, 0.88, 0.76), "Zone5_Saco_%d" % si)
		if sb != null:
			host.add_child(sb)
			sb.global_position = stack_offsets[si]
			sb.rotation.y = 0.12 * float(si)
			sb.visible = (si == 0)
			_bags_pallet_stack_nodes.append(sb)

	# Registro lógico de las 7 etapas sobre el tren de máquinas (vinculado a fallas e RPM)
	var route_specs: Array[Dictionary] = [
		{"id": "banda_descarga", "speed": 0.42, "fault_keys": ["banda_descarga"]},
		{"id": "banda_inclinada_tolva", "speed": 0.36, "fault_keys": ["banda_inclinada_tolva", "hopper"]},
		{"id": "banda_trituradora", "speed": 0.40, "fault_keys": ["banda_trituradora", "hopper"]},
		{"id": "tornillo_trituradora", "speed": 0.44, "fault_keys": ["tornillo_trituradora", "motor"]},
		{"id": "tornillo_secador", "speed": 0.42, "fault_keys": ["tornillo_secador", "motor"]},
		{"id": "secador_rotatorio", "speed": 0.25, "fault_keys": ["secador_rotatorio", "horno", "motor"]},
		{"id": "cyclone", "speed": 0.16, "fault_keys": ["cyclone", "ciclon_separador", "soplador", "ductos_aire", "motor"]}
	]
	_product_routes.clear()
	for spec in route_specs:
		_product_routes.append({
			"id": str(spec["id"]),
			"speed": float(spec["speed"]),
			"fault_keys": spec["fault_keys"],
			"phase": 0.0
		})

	# Flujos continuos sobre bandas/tornillos/secador (gravity=0) + cascadas de transferencia calibradas al milímetro
	var emitter_specs: Array[Dictionary] = [
		# --- Flujos continuos tangenciales a lo largo de bandas, sinfines y secador ---
		{"name": "StreamRedHopperSurface", "pos": Vector3(-31.75, 1.56, 51.31), "box": Vector3(0.10, 0.04, 0.24), "dir": Vector3(1.0, -0.08, 0.0), "spread": 2.0, "vel": Vector2(1.25, 1.35), "grav": Vector3.ZERO, "life": 1.45, "amt": 55, "size": 0.084, "tex": raw_kernel_tex, "flour": false, "col": Color(1.0, 0.86, 0.30, 1.0), "fault_keys": ["banda_descarga"]},
		{"name": "StreamRedBeltDischarge", "pos": Vector3(-29.40, 0.65, 51.31), "box": Vector3(0.05, 0.02, 0.15), "dir": Vector3(1.0, -0.02, -0.06), "spread": 2.0, "vel": Vector2(1.40, 1.50), "grav": Vector3.ZERO, "life": 0.56, "amt": 35, "size": 0.080, "tex": raw_kernel_tex, "flour": false, "col": Color(1.0, 0.86, 0.30, 1.0), "fault_keys": ["banda_descarga"]},
		{"name": "StreamInclinedBelt", "pos": Vector3(-28.18, 0.40, 50.96), "box": Vector3(0.20, 0.03, 0.04), "dir": Vector3(0.0, 0.756, -0.655), "spread": 1.5, "vel": Vector2(1.80, 1.90), "grav": Vector3.ZERO, "life": 2.85, "amt": 75, "size": 0.086, "tex": raw_kernel_tex, "flour": false, "col": Color(1.0, 0.86, 0.30, 1.0), "fault_keys": ["banda_inclinada_tolva", "hopper"]},
		{"name": "StreamBeltTrituradora", "pos": Vector3(-23.15, 2.34, 46.40), "box": Vector3(0.18, 0.025, 0.04), "dir": Vector3(0.0, 0.0, -1.0), "spread": 1.5, "vel": Vector2(1.52, 1.60), "grav": Vector3.ZERO, "life": 1.85, "amt": 65, "size": 0.082, "tex": raw_kernel_tex, "flour": false, "col": Color(1.0, 0.86, 0.30, 1.0), "fault_keys": ["banda_trituradora", "hopper"]},
		{"name": "StreamScrewTrituradora", "pos": Vector3(-23.45, 1.28, 42.29), "box": Vector3(0.04, 0.04, 0.08), "dir": Vector3(-0.59, 0.807, 0.0), "spread": 2.0, "vel": Vector2(1.62, 1.70), "grav": Vector3.ZERO, "life": 1.88, "amt": 48, "size": 0.078, "tex": raw_kernel_tex, "flour": false, "col": Color(1.0, 0.86, 0.30, 1.0), "fault_keys": ["tornillo_trituradora", "motor"]},
		{"name": "StreamScrewSecador", "pos": Vector3(-25.71, 1.32, 42.24), "box": Vector3(0.08, 0.04, 0.04), "dir": Vector3(0.0, 0.782, -0.623), "spread": 2.0, "vel": Vector2(1.70, 1.80), "grav": Vector3.ZERO, "life": 1.86, "amt": 48, "size": 0.074, "tex": grist_tex, "flour": false, "col": Color(1.0, 0.92, 0.56, 1.0), "fault_keys": ["tornillo_secador", "motor"]},
		{"name": "StreamDryerDrum", "pos": Vector3(-25.68, 3.84, 39.85), "box": Vector3(0.28, 0.20, 0.08), "dir": Vector3(0.0, -0.01, -1.0), "spread": 6.0, "vel": Vector2(1.55, 1.68), "grav": Vector3.ZERO, "life": 3.65, "amt": 60, "size": 0.086, "tex": grist_tex, "flour": false, "col": Color(1.0, 0.92, 0.56, 1.0), "fault_keys": ["secador_rotatorio", "horno", "motor"]},
		# --- Cascadas verticales de caída entre máquinas y descarga en ciclones ---
		{"name": "CascadeTruckToRedBelt", "pos": Vector3(-31.82, 2.02, 51.31), "box": Vector3(0.12, 0.04, 0.20), "dir": Vector3(0.35, -1.0, 0.0), "spread": 10.0, "vel": Vector2(1.1, 1.6), "grav": Vector3(0.0, -7.5, 0.0), "life": 0.34, "amt": 32, "size": 0.080, "tex": raw_kernel_tex, "flour": false, "col": Color(1.0, 0.86, 0.30, 1.0), "fault_keys": ["banda_descarga"]},
		{"name": "CascadeRedBeltToInclined", "pos": Vector3(-28.48, 0.66, 51.18), "box": Vector3(0.06, 0.03, 0.10), "dir": Vector3(0.32, -1.0, -0.2), "spread": 8.0, "vel": Vector2(0.9, 1.4), "grav": Vector3(0.0, -7.5, 0.0), "life": 0.25, "amt": 28, "size": 0.078, "tex": raw_kernel_tex, "flour": false, "col": Color(1.0, 0.86, 0.30, 1.0), "fault_keys": ["banda_descarga", "banda_inclinada_tolva"]},
		{"name": "CascadeInclinedToTolva", "pos": Vector3(-28.18, 4.58, 46.65), "box": Vector3(0.14, 0.04, 0.08), "dir": Vector3(0.35, -1.0, -0.35), "spread": 14.0, "vel": Vector2(1.1, 1.7), "grav": Vector3(0.0, -7.5, 0.0), "life": 0.42, "amt": 32, "size": 0.084, "tex": raw_kernel_tex, "flour": false, "col": Color(1.0, 0.86, 0.30, 1.0), "fault_keys": ["banda_inclinada_tolva", "hopper"]},
		{"name": "CascadeTolvaToBelt", "pos": Vector3(-23.38, 2.74, 46.28), "box": Vector3(0.08, 0.03, 0.10), "dir": Vector3(0.28, -1.0, 0.0), "spread": 8.0, "vel": Vector2(0.8, 1.3), "grav": Vector3(0.0, -7.5, 0.0), "life": 0.23, "amt": 30, "size": 0.078, "tex": raw_kernel_tex, "flour": false, "col": Color(1.0, 0.86, 0.30, 1.0), "fault_keys": ["hopper", "banda_trituradora"]},
		{"name": "CascadeBeltToScrew1", "pos": Vector3(-23.15, 2.25, 43.22), "box": Vector3(0.10, 0.03, 0.06), "dir": Vector3(0.0, -1.0, -0.42), "spread": 7.0, "vel": Vector2(1.0, 1.5), "grav": Vector3(0.0, -7.5, 0.0), "life": 0.33, "amt": 32, "size": 0.078, "tex": raw_kernel_tex, "flour": false, "col": Color(1.0, 0.86, 0.30, 1.0), "fault_keys": ["banda_trituradora", "tornillo_trituradora"]},
		{"name": "CascadeScrew1ToMill", "pos": Vector3(-25.68, 4.02, 42.29), "box": Vector3(0.06, 0.03, 0.08), "dir": Vector3(-0.35, -1.0, 0.0), "spread": 8.0, "vel": Vector2(0.9, 1.4), "grav": Vector3(0.0, -7.5, 0.0), "life": 0.28, "amt": 28, "size": 0.076, "tex": raw_kernel_tex, "flour": false, "col": Color(1.0, 0.86, 0.30, 1.0), "fault_keys": ["tornillo_trituradora", "motor"]},
		{"name": "CascadeMillToScrew2", "pos": Vector3(-25.71, 1.60, 42.32), "box": Vector3(0.08, 0.03, 0.08), "dir": Vector3(0.0, -1.0, 0.12), "spread": 10.0, "vel": Vector2(0.8, 1.3), "grav": Vector3(0.0, -7.5, 0.0), "life": 0.26, "amt": 28, "size": 0.074, "tex": grist_tex, "flour": false, "col": Color(1.0, 0.92, 0.56, 1.0), "fault_keys": ["motor", "tornillo_secador"]},
		{"name": "CascadeScrew2ToDryer", "pos": Vector3(-25.71, 4.10, 40.02), "box": Vector3(0.08, 0.04, 0.05), "dir": Vector3(0.0, -0.55, -0.85), "spread": 12.0, "vel": Vector2(1.1, 1.6), "grav": Vector3(0.0, -5.5, 0.0), "life": 0.36, "amt": 30, "size": 0.076, "tex": grist_tex, "flour": false, "col": Color(1.0, 0.92, 0.56, 1.0), "fault_keys": ["tornillo_secador", "secador_rotatorio", "horno"]},
		{"name": "CascadeDryerToSep", "pos": Vector3(-25.68, 3.45, 33.48), "box": Vector3(0.12, 0.08, 0.05), "dir": Vector3(0.0, -0.40, -1.0), "spread": 16.0, "vel": Vector2(1.3, 1.9), "grav": Vector3(0.0, -3.5, 0.0), "life": 0.36, "amt": 35, "size": 0.088, "tex": flour_tex, "flour": true, "col": Color(1.0, 0.97, 0.88, 0.92), "fault_keys": ["secador_rotatorio", "ciclon_separador", "soplador"]},
		{"name": "CascadeCycloneEastFlour", "pos": Vector3(-25.05, 2.32, 29.15), "box": Vector3(0.07, 0.02, 0.07), "dir": Vector3(0.0, -1.0, 0.0), "spread": 10.0, "vel": Vector2(1.3, 1.9), "grav": Vector3(0.0, -4.0, 0.0), "life": 0.34, "amt": 45, "size": 0.105, "tex": flour_tex, "flour": true, "col": Color(1.0, 0.98, 0.90, 0.95), "fault_keys": ["cyclone", "ciclon_separador", "soplador", "ductos_aire"]},
		{"name": "CascadeCycloneWestFlour", "pos": Vector3(-26.88, 2.32, 29.15), "box": Vector3(0.07, 0.02, 0.07), "dir": Vector3(0.0, -1.0, 0.0), "spread": 10.0, "vel": Vector2(1.3, 1.9), "grav": Vector3(0.0, -4.0, 0.0), "life": 0.34, "amt": 45, "size": 0.105, "tex": flour_tex, "flour": true, "col": Color(1.0, 0.98, 0.90, 0.95), "fault_keys": ["cyclone", "ciclon_separador", "soplador", "ductos_aire"]}
	]

	_product_emitters.clear()
	for cs in emitter_specs:
		var gp := GPUParticles3D.new()
		gp.name = str(cs["name"])
		gp.amount = int(cs["amt"])
		gp.lifetime = float(cs["life"])
		gp.visibility_aabb = AABB(Vector3(-8.0, -6.0, -8.0), Vector3(16.0, 12.0, 16.0))
		gp.emitting = false
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = cs["box"] as Vector3
		pm.direction = cs["dir"] as Vector3
		pm.spread = float(cs["spread"])
		var vr: Vector2 = cs["vel"] as Vector2
		pm.initial_velocity_min = vr.x
		pm.initial_velocity_max = vr.y
		pm.gravity = cs["grav"] as Vector3
		pm.scale_min = 0.72
		pm.scale_max = 1.22
		var col: Color = cs["col"] as Color
		pm.color = col
		gp.process_material = pm

		var qm := QuadMesh.new()
		var psz: float = float(cs["size"])
		qm.size = Vector2(psz, psz)
		var qmat := StandardMaterial3D.new()
		qmat.albedo_texture = cs["tex"] as Texture2D
		qmat.albedo_color = col
		var is_flour := bool(cs["flour"])
		if is_flour:
			qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		else:
			qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			qmat.alpha_scissor_threshold = 0.35
		qmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		qmat.emission_enabled = true
		qmat.emission = Color(col.r, col.g, col.b)
		qmat.emission_energy_multiplier = 0.28 if is_flour else 0.34
		qmat.roughness = 0.78
		qm.material = qmat
		gp.draw_pass_1 = qm

		host.add_child(gp)
		gp.global_position = cs["pos"] as Vector3
		_product_emitters.append({
			"node": gp,
			"fault_keys": cs["fault_keys"]
		})

	_product_flow_initialized = true

func _create_product_particle_texture(is_flour: bool, inner_col: Color, outer_col: Color) -> ImageTexture:
	var sz := 32
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var c := (float(sz) - 1.0) * 0.5
	for y in range(sz):
		for x in range(sz):
			var dx := (float(x) - c) / c
			var dy := (float(y) - c) / c
			var rx := dx * (1.0 if is_flour else 0.92)
			var ry := dy * (1.0 if is_flour else 1.18)
			var r := sqrt(rx * rx + ry * ry)
			if is_flour:
				var a := clampf(pow(maxf(0.0, 1.0 - r), 1.35), 0.0, 1.0)
				var col := inner_col.lerp(outer_col, clampf(r, 0.0, 1.0))
				img.set_pixel(x, y, Color(col.r, col.g, col.b, a))
			else:
				var a := 1.0 if r <= 0.78 else clampf((0.96 - r) / 0.18, 0.0, 1.0)
				var col := inner_col.lerp(outer_col, clampf(r / 0.9, 0.0, 1.0))
				img.set_pixel(x, y, Color(col.r, col.g, col.b, a))
	return ImageTexture.create_from_image(img)

func _query_machine_rate(fault_keys: Array) -> float:
	if _glow_ctrl_ref == null or not is_instance_valid(_glow_ctrl_ref):
		if is_inside_tree() and get_tree().root != null:
			_glow_ctrl_ref = get_tree().root.find_child("InteractableGlowController", true, false)
	if _glow_ctrl_ref == null or not is_instance_valid(_glow_ctrl_ref):
		return 1.0
	var rate := 1.0
	for k_v in fault_keys:
		var key := str(k_v)
		if _glow_ctrl_ref.has_method("is_machine_fault_active") and bool(_glow_ctrl_ref.is_machine_fault_active(key)):
			match key:
				"banda_trituradora", "motor", "hopper", "banda_inclinada_tolva":
					rate = minf(rate, 0.0)
				"banda_descarga", "tornillo_secador", "cyclone", "ciclon_separador", "ductos_aire":
					rate = minf(rate, 0.25)
				_:
					rate = minf(rate, 0.50)
	return rate

func _step_product_flow(delta: float) -> void:
	var rpm_ratio := clampf(current_rpm / 1750.0, 0.0, 1.4) if is_production_active else 0.0
	var flow_mult := clampf(current_flow_kg_s / 0.8, 0.25, 1.5) if is_production_active else 0.0

	var sum_rates := 0.0
	var cnt_rates := 0
	var tracked_keys := ["banda_descarga", "banda_inclinada_tolva", "hopper", "banda_trituradora", "tornillo_trituradora", "motor", "tornillo_secador", "secador_rotatorio", "ciclon_separador", "cyclone"]
	for tk in tracked_keys:
		var r := _query_machine_rate([tk])
		_product_stage_rates[tk] = r
		sum_rates += r
		cnt_rates += 1
	_line_flow_efficiency = (sum_rates / float(max(1, cnt_rates))) * (1.0 if is_production_active else 0.0)

	if is_production_active:
		_product_phase_progress = fmod(_product_phase_progress + delta * 0.24 * rpm_ratio * maxf(0.15, _line_flow_efficiency), 1.0)

	# 1. Actualizar fase de avance por etapa del tren (sincronizada con RPM, caudal y fallas)
	for r_item in _product_routes:
		var s_rate := _query_machine_rate(r_item["fault_keys"] as Array)
		var eff_speed := float(r_item["speed"]) * rpm_ratio * (0.55 + 0.45 * flow_mult) * s_rate
		r_item["phase"] = fmod(float(r_item["phase"]) + delta * eff_speed, 1.0)

	# 2. Actualizar flujos granulares continuos y cascadas GPUParticles3D proporcionales a RPM y fallas
	var p_cam: Camera3D = get_viewport().get_camera_3d() if (is_inside_tree() and get_viewport() != null) else null
	for em_item in _product_emitters:
		var gp := em_item["node"] as GPUParticles3D
		if gp == null or not is_instance_valid(gp):
			continue
		var e_rate := _query_machine_rate(em_item["fault_keys"] as Array)
		var active_stream := is_production_active and e_rate > 0.04 and rpm_ratio > 0.05
		if p_cam != null:
			var d2: float = p_cam.global_position.distance_squared_to(gp.global_position)
			if d2 > 2304.0 or (d2 > 144.0 and p_cam.is_position_behind(gp.global_position)):
				gp.visible = false
				gp.emitting = false
				continue
		gp.visible = true
		gp.emitting = active_stream
		gp.speed_scale = maxf(0.18, rpm_ratio * (0.65 + 0.35 * flow_mult) * e_rate)
		gp.amount_ratio = clampf(0.35 + 0.55 * flow_mult * e_rate, 0.15, 1.0)

	# 3. Pulso volumétrico real en Tolva (Geom3D1462); Super Saco y estiba en Zona 5 permanecen fijos (sin moverse solos)
	if _tolva_grain_node != null and is_instance_valid(_tolva_grain_node):
		var hop_rate := float(_product_stage_rates.get("hopper", 1.0))
		var pulse := sin(_idle_pulse_t * 2.6) * 0.015 if is_production_active else 0.0
		_tolva_grain_node.position.y = _tolva_grain_base_y + pulse - (1.0 - hop_rate) * 0.08
	if _super_saco_node != null and is_instance_valid(_super_saco_node):
		_super_saco_node.scale = _super_saco_base_scale
	if not _bags_pallet_stack_nodes.is_empty():
		var visible_bags := clampi(1 + (bags_50kg_produced / 2), 1, _bags_pallet_stack_nodes.size()) if bags_50kg_produced > 0 else 1
		for bi in range(_bags_pallet_stack_nodes.size()):
			var bnode := _bags_pallet_stack_nodes[bi]
			if bnode != null and is_instance_valid(bnode):
				bnode.visible = (bi < visible_bags)

func _sample_route_3d(route: Dictionary, s_raw: float) -> Dictionary:
	var pts: Array = route["pts"]
	var cum: Array = route["cum"]
	var total: float = float(route["total"])
	var s := clampf(s_raw, 0.0, 1.0)
	var d := s * total
	var seg_idx := 0
	for i in range(cum.size() - 1):
		if d <= float(cum[i + 1]) or i == cum.size() - 2:
			seg_idx = i
			break
	var d0 := float(cum[seg_idx])
	var d1 := float(cum[seg_idx + 1])
	var local_t := clampf((d - d0) / maxf(d1 - d0, 0.001), 0.0, 1.0)
	var p0: Vector3 = pts[seg_idx]
	var p1: Vector3 = pts[seg_idx + 1]
	var dir := (p1 - p0).normalized()
	return {"pos": p0.lerp(p1, local_t), "dir": dir}

func get_production_metrics() -> Dictionary:
	return {
		"is_production_active": is_production_active,
		"current_rpm": current_rpm,
		"mass_flow_kg_s": current_flow_kg_s,
		"total_grain_milled_kg": total_grain_milled_kg,
		"bags_50kg_produced": bags_50kg_produced,
		"pallets_completed": pallets_completed,
		"truck_cycle_phase": truck_cycle_phase,
		"truck_tilt_deg": truck_tilt_angle_deg,
		"product_phase_progress": _product_phase_progress,
		"line_flow_efficiency": _line_flow_efficiency,
		"active_product_routes": _product_routes.size()
	}
