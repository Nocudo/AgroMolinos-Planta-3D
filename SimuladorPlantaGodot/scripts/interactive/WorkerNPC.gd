class_name WorkerNPC
extends CharacterBody3D

# ==============================================================================
# NPC DE TRABAJADOR INDUSTRIAL DE LA PLANTA (MOLINO DE GRANOS 10 HP)
# Animaciones autónomas, marcha natural y guía interactiva de recorrido RETIE/OSHA
# ==============================================================================

const HumanGaitAnimatorScript = preload("res://scripts/interactive/HumanGaitAnimator.gd")
const InteractiveDoorScript = preload("res://scripts/interactive/InteractiveDoor.gd")

@export var worker_role_name: String = "Trabajador Industrial"
@export var worker_dialogue: String = "Operando en planta según normatividad RETIE y OSHA."
@export var primary_animation: String = "idle"
@export var secondary_animation: String = "inspect"
@export var animation_switch_time: float = 6.0
@export var is_tour_guide: bool = false
@export var external_animation_control: bool = false
@export var guide_walk_speed: float = 3.8
@export var max_step_height: float = 0.32
@export var min_step_height: float = 0.02

@onready var anim_player: AnimationPlayer = find_child("AnimationPlayer", true, false)
@onready var label_role: Label3D = $RoleLabel3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var timer: float = 0.0
var current_anim: String = ""

# Navegación de guía de recorrido y bloqueo hasta llegar y explicar
var guide_waypoints: Array[Vector3] = []
var guide_target_pos: Vector3 = Vector3.ZERO
var guide_has_target: bool = false
var has_arrived_and_explained: bool = false
var is_explaining: bool = false
var _explain_timer: float = 0.0
var _interact_anim_timer: float = 0.0
var _guide_stuck_timer: float = 0.0
var _stuck_anchor_xz: Vector2 = Vector2.ZERO
var _guide_recovery_count: int = 0
var player_ref: Node3D = null
var _dock_look_target: Vector3 = Vector3.ZERO

func set_work_state(anim_name: String, look_target: Vector3, live_dialogue: String = "") -> void:
	external_animation_control = true
	_dock_look_target = look_target
	if not live_dialogue.is_empty():
		worker_dialogue = live_dialogue
	if _interact_anim_timer <= 0.0:
		_play_locomotion_anim(anim_name, 0.25)

func _compact_role_label(full_role: String) -> String:
	var raw := full_role.strip_edges()
	if raw.contains("Supervisor SST"):
		return "Supervisor SST"
	if raw.contains("Electromecánico"):
		return "Electromecánico"
	if raw.contains("Muelle Sur"):
		return "Muelle Sur"
	if raw.contains("Bahía Oeste"):
		return "Bahía Oeste"
	if raw.contains("Almacén"):
		return "Almacén"
	if raw.contains("Jefe de Planta"):
		return "Jefe de Planta"
	var cut := raw.split(" / ")[0].split(" — ")[0].split(" (")[0].strip_edges()
	return cut.substr(0, 18)

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("workers")
	floor_snap_length = 0.50
	safe_margin = 0.02
	floor_stop_on_slope = true
	floor_max_angle = deg_to_rad(50.0)
	if label_role != null:
		label_role.text = _compact_role_label(worker_role_name)
		label_role.pixel_size = 0.0013
		label_role.font_size = 16
		label_role.outline_size = 2
		label_role.position.y = 1.95
		label_role.modulate.a = 0.88

	if anim_player != null:
		HumanGaitAnimatorScript.upgrade_animations(anim_player, self)
		current_anim = primary_animation
		if anim_player.has_animation(current_anim):
			anim_player.play(current_anim)
			anim_player.get_animation(current_anim).loop_mode = Animation.LOOP_LINEAR
			anim_player.advance(0.02)

	if is_inside_tree():
		player_ref = get_tree().root.find_child("PlayerOperator", true, false) as Node3D

func _physics_process(delta: float) -> void:
	if _interact_anim_timer > 0.0:
		_interact_anim_timer = maxf(0.0, _interact_anim_timer - delta)
	if is_explaining:
		_explain_timer -= delta
		if _explain_timer <= 0.0:
			is_explaining = false
			has_arrived_and_explained = true

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if external_animation_control:
		velocity.x = 0.0
		velocity.z = 0.0
		if _dock_look_target != Vector3.ZERO:
			_face_point(_dock_look_target, delta * 5.5)
	elif is_tour_guide and guide_has_target:
		_process_tour_guide_movement(delta)
		_try_auto_step(delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if is_tour_guide and player_ref != null and is_instance_valid(player_ref):
			_face_point(player_ref.global_position, delta * 4.5)
		if is_tour_guide and _interact_anim_timer <= 0.0 and current_anim == "interact":
			_play_locomotion_anim(primary_animation, 0.25)

	move_and_slide()

func _open_doors_ahead(to_next: Vector3) -> void:
	if not is_inside_tree():
		return
	var dir_xz := Vector2(to_next.x, to_next.z)
	var look_ahead := (
		Vector2(global_position.x, global_position.z)
		+ (dir_xz.normalized() * 1.3 if dir_xz.length_squared() > 0.04 else Vector2.ZERO)
	)
	var self_xz := Vector2(global_position.x, global_position.z)
	for node in get_tree().get_nodes_in_group("interactive_doors"):
		var door := node as InteractiveDoorScript
		if door == null or door.is_open:
			continue
		var door_xz := Vector2(door.global_position.x, door.global_position.z)
		if self_xz.distance_to(door_xz) <= 2.6 or look_ahead.distance_to(door_xz) <= 2.0:
			door.open_door(true)

func _try_auto_step(delta: float) -> bool:
	var horiz_vel := Vector3(velocity.x, 0.0, velocity.z)
	var h_speed := horiz_vel.length()
	if h_speed < 0.15:
		return false

	var horiz_dir := horiz_vel.normalized()
	var fwd_dist := clampf(h_speed * delta * 2.5, 0.18, 0.34)
	var step_vec := horiz_dir * fwd_dist
	var fwd_col := KinematicCollision3D.new()
	if not test_move(global_transform, step_vec, fwd_col):
		return false
	if fwd_col.get_normal().y >= 0.94:
		return false

	var up_vec := Vector3(0.0, max_step_height, 0.0)
	if test_move(global_transform, up_vec):
		return false
	var lifted_xf := global_transform.translated(up_vec)
	if test_move(lifted_xf, step_vec):
		return false

	var params := PhysicsTestMotionParameters3D.new()
	params.from = lifted_xf.translated(step_vec)
	params.motion = Vector3(0.0, -max_step_height, 0.0)
	var result := PhysicsTestMotionResult3D.new()
	if PhysicsServer3D.body_test_motion(get_rid(), params, result):
		# Exigir superficie superior horizontal (>= 0.80) para nunca trepar muros o alféizares
		if result.get_collision_normal().y >= 0.80:
			var step_h: float = max_step_height + result.get_travel().y
			if step_h >= min_step_height and step_h <= max_step_height:
				var lift: float = step_h + 0.02
				if test_move(global_transform, Vector3(0.0, lift + 0.04, 0.0)):
					return false
				var nudge: Vector3 = horiz_dir * minf(fwd_dist * 0.35, 0.10)
				if not test_move(global_transform.translated(Vector3(0.0, lift, 0.0)), nudge):
					global_position += Vector3(nudge.x, lift, nudge.z)
				else:
					global_position.y += lift
				if velocity.y < 0.0:
					velocity.y = 0.0
				return true
	return false

func _process_tour_guide_movement(delta: float) -> void:
	if player_ref == null and is_inside_tree():
		player_ref = get_tree().root.find_child("PlayerOperator", true, false) as Node3D

	var dist_to_player: float = 0.0
	if player_ref != null and is_instance_valid(player_ref):
		var p_flat := Vector2(player_ref.global_position.x, player_ref.global_position.z)
		var g_flat := Vector2(global_position.x, global_position.z)
		dist_to_player = g_flat.distance_to(p_flat)

	# Esperar al visitante si se aleja más de 7.5 m para guiarlo visualmente
	if player_ref != null and dist_to_player > 7.5:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		_stuck_anchor_xz = Vector2(global_position.x, global_position.z)
		_guide_stuck_timer = 0.0
		_face_point(player_ref.global_position, delta * 5.0)
		_play_locomotion_anim("idle", 0.25)
		return

	var next_wp: Vector3 = guide_target_pos
	if guide_waypoints.size() > 0:
		next_wp = guide_waypoints[0]

	var to_next := Vector3(next_wp.x - global_position.x, 0.0, next_wp.z - global_position.z)
	_open_doors_ahead(to_next)
	var dist_wp := to_next.length()
	var arrive_radius := 0.22 if guide_waypoints.size() > 0 else 0.42
	if dist_wp <= arrive_radius:
		_stuck_anchor_xz = Vector2(global_position.x, global_position.z)
		_guide_stuck_timer = 0.0
		if guide_waypoints.size() > 0:
			guide_waypoints.remove_at(0)
			if guide_waypoints.is_empty():
				var dist_final := Vector2(guide_target_pos.x - global_position.x, guide_target_pos.z - global_position.z).length()
				if dist_final <= 0.42:
					_begin_arrival_explanation()
		else:
			_begin_arrival_explanation()

	if not guide_has_target:
		velocity.x = 0.0
		velocity.z = 0.0
		_guide_stuck_timer = 0.0
		if player_ref != null:
			_face_point(player_ref.global_position, delta * 5.0)
		if _interact_anim_timer <= 0.0:
			_play_locomotion_anim("idle", 0.25)
		return

	var target_now: Vector3 = guide_waypoints[0] if guide_waypoints.size() > 0 else guide_target_pos
	var dir_vec := Vector3(target_now.x - global_position.x, 0.0, target_now.z - global_position.z)
	var remain := dir_vec.length()
	if remain > 0.05:
		var dir := dir_vec / remain
		var move_speed := minf(guide_walk_speed, 1.35) if (guide_waypoints.size() > 0 and remain < 0.50) else guide_walk_speed
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		_update_guide_stuck_recovery(delta, target_now, dir)
		_face_point(target_now, delta * 7.0)
		_play_locomotion_anim("walk", 0.2)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		_guide_stuck_timer = 0.0
		_play_locomotion_anim("idle", 0.25)

func _update_guide_stuck_recovery(delta: float, target_now: Vector3, dir: Vector3) -> void:
	var cur_xz := Vector2(global_position.x, global_position.z)
	if cur_xz.distance_to(_stuck_anchor_xz) >= 0.26:
		_stuck_anchor_xz = cur_xz
		_guide_stuck_timer = 0.0
		return

	_guide_stuck_timer += delta
	if _guide_stuck_timer < 1.35 or not is_inside_tree():
		return

	_guide_stuck_timer = 0.0
	var side := Vector3(-dir.z, 0.0, dir.x)
	var candidates: Array[Vector3] = [
		global_position + dir * 0.60,
		global_position + side * 0.45 + dir * 0.40,
		global_position - side * 0.45 + dir * 0.40,
		global_position + side * 0.55,
		global_position - side * 0.55,
	]
	for cand in candidates:
		var safe := _find_unobstructed_floor_point(cand)
		if safe != Vector3.INF:
			global_position = safe
			velocity = Vector3.ZERO
			_stuck_anchor_xz = Vector2(safe.x, safe.z)
			_guide_recovery_count += 1
			return

func _find_unobstructed_floor_point(probe: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	if space == null:
		return Vector3.INF
	var rq := PhysicsRayQueryParameters3D.create(
		Vector3(probe.x, probe.y + 1.6, probe.z),
		Vector3(probe.x, -1.0, probe.z),
		1,
		[get_rid()]
	)
	var hit := space.intersect_ray(rq)
	if hit.is_empty():
		return Vector3.INF
	var floor_y := float(hit["position"].y)
	# Nunca atravesar paredes: verificar línea de vista horizontal despejada al punto candidato
	var los_from := Vector3(global_position.x, maxf(global_position.y, floor_y) + 1.0, global_position.z)
	var los_to := Vector3(probe.x, floor_y + 1.0, probe.z)
	if los_from.distance_to(los_to) > 0.08:
		var los_q := PhysicsRayQueryParameters3D.create(los_from, los_to, 1, [get_rid()])
		if not space.intersect_ray(los_q).is_empty():
			return Vector3.INF
	var test_xf := Transform3D(Basis.IDENTITY, Vector3(probe.x, floor_y + 0.06, probe.z))
	if not test_move(test_xf, Vector3(0.0, 0.02, 0.0)):
		return Vector3(probe.x, floor_y + 0.02, probe.z)
	return Vector3.INF

func set_guide_route(waypoints: Array[Vector3], final_target: Vector3) -> void:
	is_tour_guide = true
	guide_waypoints = waypoints.duplicate()
	guide_target_pos = final_target
	guide_has_target = true
	has_arrived_and_explained = false
	is_explaining = false
	_explain_timer = 0.0
	_interact_anim_timer = 0.0
	_guide_stuck_timer = 0.0
	_stuck_anchor_xz = Vector2(global_position.x, global_position.z)

func set_guide_target(pos: Vector3) -> void:
	set_guide_route([pos], pos)

func can_interact() -> bool:
	if not is_tour_guide:
		return true
	return not guide_has_target and not is_explaining and has_arrived_and_explained

func _begin_arrival_explanation() -> void:
	guide_has_target = false
	is_explaining = true
	_explain_timer = 1.0
	has_arrived_and_explained = false
	if anim_player != null and anim_player.has_animation("interact"):
		_interact_anim_timer = 1.1
		current_anim = "interact"
		anim_player.play("interact", 0.2)
		var ia := anim_player.get_animation("interact")
		if ia != null:
			ia.loop_mode = Animation.LOOP_NONE
	var msg := worker_dialogue
	var title := worker_role_name.to_upper()
	if is_inside_tree():
		var tut = get_tree().root.find_child("TutorialInductionManager", true, false)
		var hud = get_tree().root.find_child("HUDController", true, false)
		if tut != null and bool(tut.get("sst_course_active")) and not bool(tut.get("sst_course_completed")):
			title = "SALA DE REUNIONES — CURSO RÁPIDO SST (RETIE)"
			msg = "Bienvenido a la Sala de Reuniones. Revisa los 3 módulos RETIE y completa el quiz simple (+0.5 pt). Puedes abrirlo con [E]."
			if hud != null and hud.has_method("show_npc_dialogue"):
				hud.show_npc_dialogue(title, msg, 12.0)
		elif tut != null and "STATIONS" in tut and "target_station_id" in tut:
			var sid := int(tut.target_station_id)
			var sts: Array = tut.STATIONS
			if sid >= 1 and sid <= sts.size():
				title = str(sts[sid - 1].get("title", title)).to_upper()
				msg = str(sts[sid - 1].get("desc", msg))
			if sid == 2 and not bool(tut.get("epp_completed")):
				if hud != null and hud.has_method("show_npc_dialogue"):
					hud.show_npc_dialogue(
						"SUPERVISOR SST — VESTIDORES EPP RETIE",
						"Aquí tienes tu ropa ignífuga y las 6 prendas EPP dentro de los lockers verdes de enfrente. Acércate directamente a los lockers y presiona [E] mirando hacia ellos para equiparte.",
						12.0
					)
			elif sid >= 3 and bool(tut.get("epp_completed")):
				if hud != null and hud.has_method("show_npc_dialogue"):
					var step_cue := "Presiona [E] para avanzar a la Estación %d/12." % (sid + 1) if sid < sts.size() else "Presiona [E] para finalizar el recorrido RETIE (12/12)."
					hud.show_npc_dialogue(title, "%s\n%s" % [msg, step_cue], 14.0)
	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("notification_posted"):
		bus.notification_posted.emit(title, msg, "info")

func _face_point(target_pos: Vector3, weight: float) -> void:
	var dx := target_pos.x - global_position.x
	var dz := target_pos.z - global_position.z
	if dx * dx + dz * dz < 0.001:
		return
	var target_yaw := atan2(-dx, -dz)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(weight, 0.0, 1.0))

func _play_locomotion_anim(anim_name: String, blend_t: float) -> void:
	if anim_player == null or not anim_player.has_animation(anim_name):
		return
	if current_anim != anim_name:
		current_anim = anim_name
		anim_player.play(anim_name, blend_t)
		var a := anim_player.get_animation(anim_name)
		if a != null and (anim_name == "idle" or anim_name == "walk" or anim_name == "run" or anim_name == "signal_truck"):
			a.loop_mode = Animation.LOOP_LINEAR
		if blend_t <= 0.05:
			anim_player.advance(0.02)

func _process(delta: float) -> void:
	if external_animation_control or (is_tour_guide and (guide_has_target or is_explaining)) or _interact_anim_timer > 0.0:
		return
	timer += delta
	if timer >= animation_switch_time:
		timer = 0.0
		_toggle_idle_animation()

func _toggle_idle_animation() -> void:
	if anim_player == null:
		return
	if current_anim == primary_animation:
		current_anim = secondary_animation
	else:
		current_anim = primary_animation

	if anim_player.has_animation(current_anim):
		anim_player.play(current_anim, 0.5)
		anim_player.get_animation(current_anim).loop_mode = Animation.LOOP_LINEAR

func get_interact_prompt() -> String:
	if not is_tour_guide:
		return "[E] Hablar con " + worker_role_name
	var tut = get_tree().root.find_child("TutorialInductionManager", true, false) if is_inside_tree() else null
	if tut != null and bool(tut.get("sst_course_active")) and not bool(tut.get("sst_course_completed")):
		return "[E] Iniciar Curso Rápido SST (RETIE)"
	if tut != null and int(tut.get("target_station_id")) == 2 and not bool(tut.get("epp_completed")):
		return "[E] Hablar con Supervisor SST (Ver indicación de lockers)"
	if tut != null and tut.has_method("is_ready_for_interact_advance") and bool(tut.is_ready_for_interact_advance()):
		return String(tut.get_interact_advance_prompt())
	return "[E] Pausa: Controles y Guía SST"

func interact(_tool_id: int = 1) -> String:
	if not can_interact():
		return ""

	if anim_player != null and anim_player.has_animation("interact"):
		_interact_anim_timer = 1.1
		current_anim = "interact"
		anim_player.play("interact", 0.2)
		var ia := anim_player.get_animation("interact")
		if ia != null:
			ia.loop_mode = Animation.LOOP_NONE

	var bus = get_node_or_null("/root/EventBus")
	var tut = get_tree().root.find_child("TutorialInductionManager", true, false) if is_inside_tree() else null
	if is_tour_guide and tut != null and bool(tut.get("sst_course_active")) and not bool(tut.get("sst_course_completed")):
		if Vector2(global_position.x - 27.0, global_position.z - 34.0).length() <= 6.0:
			if bus != null and bus.has_signal("sst_course_modal_requested"):
				bus.sst_course_modal_requested.emit()
			return "Iniciando Curso Rápido SST (RETIE) en Sala de Reuniones."
	if is_tour_guide and tut != null and tut.has_method("is_ready_for_interact_advance") and bool(tut.is_ready_for_interact_advance()):
		return String(tut.try_advance_station_by_interact())
	if is_tour_guide and tut != null and int(tut.get("target_station_id")) == 2 and not bool(tut.get("epp_completed")):
		var locker_msg := "Tu ropa ignífuga y las 6 prendas EPP están dentro de los lockers verdes de enfrente. Apunta a los lockers y presiona [E] para equiparte."
		var hud = get_tree().root.find_child("HUDController", true, false)
		if hud != null and hud.has_method("show_npc_dialogue"):
			hud.show_npc_dialogue("SUPERVISOR SST — VESTIDORES EPP RETIE", locker_msg, 12.0)
		if bus != null and bus.has_signal("induction_briefing_requested"):
			bus.induction_briefing_requested.emit("VESTIDORES EPP — INDUMENTARIA EN LOS LOCKERS", locker_msg, false)
		return locker_msg

	if is_tour_guide and bus != null and bus.has_signal("induction_briefing_requested"):
		var pending_start := (tut != null and not bool(tut.briefing_completed))
		var title := "BIENVENIDA EN PORTERÍA — INSPECTOR SST" if pending_start else "PAUSA DEL INSPECTOR SST — CONTROLES Y MECÁNICAS"
		bus.induction_briefing_requested.emit(title, worker_dialogue, pending_start)
		return worker_dialogue

	var hud_node = get_tree().root.find_child("HUDController", true, false) if is_inside_tree() else null
	if hud_node != null and hud_node.has_method("show_npc_dialogue"):
		hud_node.show_npc_dialogue(worker_role_name.to_upper(), worker_dialogue, 6.5)

	if bus != null and bus.has_signal("notification_posted"):
		bus.notification_posted.emit(worker_role_name.to_upper(), worker_dialogue, "info")

	return worker_dialogue
