class_name HumanGaitAnimator
extends RefCounted

# ==============================================================================
# SINTETIZADOR DE ANIMACIÓN BIOMECÁNICA NATURAL PARA PERSONAJES RIGGED (CC3 / GLB)
# Reemplaza walk, run, idle, inspect, interact y operate_panel en memoria con
# hombros relajados, brazos pegados naturalmente al torso, codos anatómicos y
# micro-movimientos naturales de respiración, cabeza y equilibrio.
# ==============================================================================

const STEPS_PER_CYCLE: int = 16

const TRACKED_BONES := [
	"CC_Base_Hip_02_scaleCompensation",
	"CC_Base_Pelvis_03",
	"CC_Base_Spine01_012",
	"CC_Base_Spine02_013",
	"CC_Base_Head_015",
	"CC_Base_L_Thigh_00",
	"CC_Base_R_Thigh_07",
	"CC_Base_L_Calf_04",
	"CC_Base_R_Calf_08",
	"CC_Base_L_Foot_05",
	"CC_Base_R_Foot_09",
	"CC_Base_L_Clavicle_016",
	"CC_Base_R_Clavicle_035",
	"CC_Base_L_Upperarm_017",
	"CC_Base_R_Upperarm_036",
	"CC_Base_L_Forearm_018",
	"CC_Base_R_Forearm_037",
	"CC_Base_L_Hand_019",
	"CC_Base_R_Hand_038",
]

static func upgrade_animations(anim_player: AnimationPlayer, root_visual: Node3D) -> void:
	if anim_player == null or root_visual == null:
		return
	var skeleton := root_visual.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null:
		return

	if anim_player.has_animation_library(""):
		var orig_lib := anim_player.get_animation_library("")
		var dup_lib := orig_lib.duplicate(true) as AnimationLibrary
		if dup_lib != null:
			anim_player.remove_animation_library("")
			anim_player.add_animation_library("", dup_lib)
	else:
		return

	var lib := anim_player.get_animation_library("")
	var skel_path := _find_skeleton_rel_path(anim_player, skeleton)
	if skel_path.is_empty():
		return

	lib.add_animation("walk", _build_gait_animation(skeleton, skel_path, 1.02, false))
	lib.add_animation("run", _build_gait_animation(skeleton, skel_path, 0.68, true))
	lib.add_animation("idle", _build_stance_animation(skeleton, skel_path, "idle"))
	lib.add_animation("inspect", _build_stance_animation(skeleton, skel_path, "inspect"))
	lib.add_animation("interact", _build_stance_animation(skeleton, skel_path, "interact"))
	lib.add_animation("operate_panel", _build_stance_animation(skeleton, skel_path, "operate_panel"))
	lib.add_animation("signal_truck", _build_stance_animation(skeleton, skel_path, "signal_truck"))
	lib.add_animation("drive_seated", _build_stance_animation(skeleton, skel_path, "drive_seated"))

static func _prepare_skeleton_tracks(skeleton: Skeleton3D, skel_path: String, anim: Animation) -> Dictionary:
	var rest_map := {}
	var track_idx := {}
	for bname in TRACKED_BONES:
		var bi := skeleton.find_bone(bname)
		if bi < 0:
			continue
		rest_map[bname] = skeleton.get_bone_rest(bi)
		var t_path := NodePath(skel_path + ":" + bname)
		var t_type := Animation.TYPE_POSITION_3D if bname == "CC_Base_Hip_02_scaleCompensation" else Animation.TYPE_ROTATION_3D
		var tr := anim.add_track(t_type)
		anim.track_set_path(tr, t_path)
		anim.track_set_interpolation_type(tr, Animation.INTERPOLATION_LINEAR)
		track_idx[bname] = tr
	return {"rest": rest_map, "tracks": track_idx}

static func _insert_rot(anim: Animation, rest_map: Dictionary, track_idx: Dictionary, bone: String, t: float, rel_q: Quaternion) -> void:
	if not track_idx.has(bone):
		return
	var rq := Quaternion(rest_map[bone].basis)
	anim.rotation_track_insert_key(track_idx[bone], t, rq * rel_q)

static func _insert_arm_pose(
	anim: Animation,
	rest_map: Dictionary,
	track_idx: Dictionary,
	t: float,
	is_left: bool,
	clav_drop_deg: float,
	arm_drop_deg: float,
	arm_swing_deg: float,
	arm_inward_deg: float,
	elbow_bend_deg: float,
	wrist_pitch_deg: float
) -> void:
	var side_sign := -1.0 if is_left else 1.0
	var clav_bone := "CC_Base_L_Clavicle_016" if is_left else "CC_Base_R_Clavicle_035"
	var arm_bone := "CC_Base_L_Upperarm_017" if is_left else "CC_Base_R_Upperarm_036"
	var fore_bone := "CC_Base_L_Forearm_018" if is_left else "CC_Base_R_Forearm_037"
	var hand_bone := "CC_Base_L_Hand_019" if is_left else "CC_Base_R_Hand_038"

	_insert_rot(anim, rest_map, track_idx, clav_bone, t, Quaternion(Vector3.BACK, side_sign * deg_to_rad(clav_drop_deg)))

	# 1) Giro axial del húmero sobre su propio eje (Vector3.UP local antes de caer) para acercar antebrazos al pecho al doblar codo;
	# 2) Bajar brazo junto al torso (Vector3.BACK); 3) Balanceo sagital frontal/trasero (+Z/-Z) sin cruzarse
	var q_twist := Quaternion(Vector3.UP, -side_sign * deg_to_rad(arm_inward_deg))
	var q_drop := Quaternion(Vector3.BACK, side_sign * deg_to_rad(arm_drop_deg))
	var q_swing := Quaternion(Vector3.UP, side_sign * deg_to_rad(arm_swing_deg))
	_insert_rot(anim, rest_map, track_idx, arm_bone, t, q_swing * q_drop * q_twist)

	# Flexión natural del codo hacia adelante y leve pronación de muñeca hacia el cuerpo
	_insert_rot(anim, rest_map, track_idx, fore_bone, t, Quaternion(Vector3.RIGHT, deg_to_rad(elbow_bend_deg)))
	_insert_rot(anim, rest_map, track_idx, hand_bone, t, Quaternion(Vector3.BACK, -side_sign * deg_to_rad(wrist_pitch_deg)))

static func _build_stance_animation(skeleton: Skeleton3D, skel_path: String, mode: String) -> Animation:
	var anim := Animation.new()
	var duration := 3.2 if mode == "idle" else (1.2 if mode == "interact" else (1.4 if mode == "signal_truck" else (2.0 if mode == "drive_seated" else 2.8)))
	anim.length = duration
	anim.loop_mode = Animation.LOOP_LINEAR if mode != "interact" else Animation.LOOP_NONE
	var setup := _prepare_skeleton_tracks(skeleton, skel_path, anim)
	var rest_map: Dictionary = setup["rest"]
	var track_idx: Dictionary = setup["tracks"]

	var key_steps := 16
	for step in range(key_steps + 1):
		var u := float(step) / float(key_steps)
		var t := u * duration
		var ph := u * TAU
		var s1 := sin(ph)
		var c1 := cos(ph)
		var s2 := sin(ph * 2.0)

		if track_idx.has("CC_Base_Hip_02_scaleCompensation"):
			var base_p: Vector3 = rest_map["CC_Base_Hip_02_scaleCompensation"].origin
			var shift_x := s1 * 0.8 if mode == "idle" else s1 * 0.35
			var shift_z := -36.0 if mode == "drive_seated" else (s2 * 0.18)
			anim.position_track_insert_key(track_idx["CC_Base_Hip_02_scaleCompensation"], t, base_p + Vector3(shift_x, 0.0, shift_z))

		var pelvis_yaw := s1 * 1.8 if mode == "idle" else (0.0 if mode == "drive_seated" else s1 * 1.0)
		_insert_rot(anim, rest_map, track_idx, "CC_Base_Pelvis_03", t, Quaternion(Vector3.UP, deg_to_rad(pelvis_yaw)))

		if mode == "drive_seated":
			_insert_rot(anim, rest_map, track_idx, "CC_Base_L_Thigh_00", t, Quaternion(Vector3.RIGHT, deg_to_rad(78.0)))
			_insert_rot(anim, rest_map, track_idx, "CC_Base_R_Thigh_07", t, Quaternion(Vector3.RIGHT, deg_to_rad(78.0)))
			_insert_rot(anim, rest_map, track_idx, "CC_Base_L_Calf_04", t, Quaternion(Vector3.RIGHT, -deg_to_rad(82.0)))
			_insert_rot(anim, rest_map, track_idx, "CC_Base_R_Calf_08", t, Quaternion(Vector3.RIGHT, -deg_to_rad(82.0)))
			_insert_rot(anim, rest_map, track_idx, "CC_Base_L_Foot_05", t, Quaternion(Vector3.RIGHT, deg_to_rad(6.0)))
			_insert_rot(anim, rest_map, track_idx, "CC_Base_R_Foot_09", t, Quaternion(Vector3.RIGHT, deg_to_rad(6.0)))
		else:
			# Piernas asentadas con micro-flexión relajada en rodillas (cero T-pose ni zancada rígida)
			var l_knee := 4.0 + s1 * 1.5
			var r_knee := 4.0 - s1 * 1.5
			_insert_rot(anim, rest_map, track_idx, "CC_Base_L_Thigh_00", t, Quaternion(Vector3.RIGHT, deg_to_rad(2.0 + s1 * 0.8)))
			_insert_rot(anim, rest_map, track_idx, "CC_Base_R_Thigh_07", t, Quaternion(Vector3.RIGHT, deg_to_rad(2.0 - s1 * 0.8)))
			_insert_rot(anim, rest_map, track_idx, "CC_Base_L_Calf_04", t, Quaternion(Vector3.RIGHT, -deg_to_rad(l_knee)))
			_insert_rot(anim, rest_map, track_idx, "CC_Base_R_Calf_08", t, Quaternion(Vector3.RIGHT, -deg_to_rad(r_knee)))
			_insert_rot(anim, rest_map, track_idx, "CC_Base_L_Foot_05", t, Quaternion(Vector3.RIGHT, deg_to_rad(l_knee * 0.45)))
			_insert_rot(anim, rest_map, track_idx, "CC_Base_R_Foot_09", t, Quaternion(Vector3.RIGHT, deg_to_rad(r_knee * 0.45)))

		var spine_pitch := 1.0 + s2 * 0.7
		var spine_yaw := s1 * 1.2
		var upper_pitch := 0.8 + s2 * 0.6
		var head_pitch := -1.5 + s2 * 1.0
		var head_yaw := s1 * 6.5

		# Parámetros de brazos en reposo natural junto al cuerpo (clavícula -6°, brazo -79° -> net -85°)
		var clav := 6.0
		var l_drop := 79.0
		var r_drop := 79.0
		var l_sw := 3.0 + s1 * 1.5
		var r_sw := 3.0 - s1 * 1.5
		var l_in := 5.0
		var r_in := 5.0
		var l_elb := 14.0 + s2 * 1.5
		var r_elb := 14.0 + s2 * 1.5
		var l_wri := 6.0
		var r_wri := 6.0

		if mode == "inspect":
			spine_pitch = 3.5 + s2 * 0.5
			spine_yaw = s1 * 2.5
			head_pitch = 7.0 + sin(ph) * 4.0
			head_yaw = s1 * 9.0
			# Mano derecha sosteniendo lectura frente al pecho; izquierda descansando junto a cadera
			r_drop = 77.0
			r_sw = 18.0 + sin(ph) * 2.0
			r_in = 32.0
			r_elb = 78.0 + sin(ph) * 3.0
			r_wri = 14.0
			l_drop = 79.0
			l_sw = 4.0
			l_in = 6.0
			l_elb = 20.0
		elif mode == "operate_panel":
			spine_pitch = 4.5 + s2 * 0.4
			head_pitch = 5.0 + s1 * 2.5
			head_yaw = s1 * 5.0
			l_drop = 77.0
			r_drop = 77.0
			l_sw = 24.0 + s1 * 3.0
			r_sw = 24.0 - s1 * 3.5
			l_in = 22.0
			r_in = 22.0
			l_elb = 70.0 + s2 * 4.0
			r_elb = 72.0 + cos(ph) * 5.0
			l_wri = 10.0
			r_wri = 10.0
		elif mode == "signal_truck":
			spine_pitch = 2.0 + s2 * 1.2
			spine_yaw = s1 * 3.0
			head_pitch = -2.0 + s1 * 2.5
			head_yaw = s1 * 6.0
			clav = 5.0
			l_drop = 70.0
			r_drop = 70.0
			l_sw = 84.0 + s1 * 24.0
			r_sw = 84.0 - s1 * 24.0
			l_in = 14.0
			r_in = 14.0
			l_elb = 68.0 + c1 * 22.0
			r_elb = 68.0 - c1 * 22.0
			l_wri = 4.0
			r_wri = 4.0
		elif mode == "drive_seated":
			spine_pitch = 4.0 + s2 * 0.6
			head_yaw = s1 * 7.5
			clav = 6.0
			l_drop = 74.0
			r_drop = 74.0
			l_sw = 42.0 + s1 * 4.0
			r_sw = 42.0 - s1 * 4.0
			l_in = 20.0
			r_in = 20.0
			l_elb = 58.0
			r_elb = 58.0
			l_wri = 8.0
			r_wri = 8.0
		elif mode == "interact":
			var arc := sin(u * PI)
			spine_pitch = 2.0 + arc * 1.5
			head_pitch = arc * 5.0
			head_yaw = sin(u * TAU) * 3.5
			# Gesto amigable explicando con la mano derecha hacia adelante/pecho y mano izquierda relajada
			r_drop = 77.0
			r_sw = 16.0 + arc * 12.0
			r_in = 28.0
			r_elb = 56.0 + arc * 16.0
			r_wri = 12.0
			l_drop = 79.0
			l_sw = 6.0 + arc * 3.0
			l_in = 10.0
			l_elb = 26.0 + arc * 8.0
			l_wri = 8.0

		_insert_rot(anim, rest_map, track_idx, "CC_Base_Spine01_012", t, Quaternion(Vector3.RIGHT, deg_to_rad(spine_pitch)) * Quaternion(Vector3.UP, deg_to_rad(spine_yaw)))
		_insert_rot(anim, rest_map, track_idx, "CC_Base_Spine02_013", t, Quaternion(Vector3.RIGHT, deg_to_rad(upper_pitch)))
		_insert_rot(anim, rest_map, track_idx, "CC_Base_Head_015", t, Quaternion(Vector3.RIGHT, deg_to_rad(head_pitch)) * Quaternion(Vector3.UP, deg_to_rad(head_yaw)))

		_insert_arm_pose(anim, rest_map, track_idx, t, true, clav, l_drop, l_sw, l_in, l_elb, l_wri)
		_insert_arm_pose(anim, rest_map, track_idx, t, false, clav, r_drop, r_sw, r_in, r_elb, r_wri)
	return anim

static func _find_skeleton_rel_path(anim_player: AnimationPlayer, skeleton: Skeleton3D) -> String:
	var root_node := anim_player.get_node_or_null(anim_player.root_node)
	if root_node == null:
		root_node = anim_player.get_parent()
	if root_node == null:
		return ""
	return str(root_node.get_path_to(skeleton))

static func _build_gait_animation(skeleton: Skeleton3D, skel_path: String, duration: float, is_run: bool) -> Animation:
	var anim := Animation.new()
	anim.length = duration
	anim.loop_mode = Animation.LOOP_LINEAR

	var hip_amp: float = 2.4 if is_run else 1.2
	var thigh_fwd: float = 33.0 if is_run else 21.0
	var thigh_back: float = 25.0 if is_run else 15.0
	var knee_swing: float = 56.0 if is_run else 35.0
	var knee_stance: float = 10.0 if is_run else 4.0
	var arm_swing: float = 32.0 if is_run else 17.0
	var elbow_base: float = 48.0 if is_run else 16.0
	var spine_lean: float = 7.5 if is_run else 2.2

	var setup := _prepare_skeleton_tracks(skeleton, skel_path, anim)
	var rest_map: Dictionary = setup["rest"]
	var track_idx: Dictionary = setup["tracks"]

	for step in range(STEPS_PER_CYCLE + 1):
		var u: float = float(step) / float(STEPS_PER_CYCLE)
		var t: float = u * duration
		var phase: float = u * TAU

		if track_idx.has("CC_Base_Hip_02_scaleCompensation"):
			var base_p: Vector3 = rest_map["CC_Base_Hip_02_scaleCompensation"].origin
			var hip_pos := Vector3(
				base_p.x + sin(phase) * 0.7,
				base_p.y,
				base_p.z - 0.8 + cos(phase * 2.0) * hip_amp
			)
			anim.position_track_insert_key(track_idx["CC_Base_Hip_02_scaleCompensation"], t, hip_pos)

		_insert_rot(anim, rest_map, track_idx, "CC_Base_Pelvis_03", t, Quaternion(Vector3.FORWARD, deg_to_rad(sin(phase) * 3.2)))
		_insert_rot(anim, rest_map, track_idx, "CC_Base_Spine01_012", t, Quaternion(Vector3.RIGHT, deg_to_rad(spine_lean)) * Quaternion(Vector3.UP, deg_to_rad(-sin(phase) * 2.8)))
		_insert_rot(anim, rest_map, track_idx, "CC_Base_Spine02_013", t, Quaternion(Vector3.UP, deg_to_rad(-sin(phase) * 2.2)))
		_insert_rot(anim, rest_map, track_idx, "CC_Base_Head_015", t, Quaternion(Vector3.RIGHT, deg_to_rad(-spine_lean * 0.6)) * Quaternion(Vector3.UP, deg_to_rad(sin(phase) * 2.0)))

		var sin_l: float = sin(phase)
		var sin_r: float = sin(phase + PI)

		var l_thigh_deg: float = thigh_fwd * sin_l if sin_l >= 0.0 else thigh_back * sin_l
		var r_thigh_deg: float = thigh_fwd * sin_r if sin_r >= 0.0 else thigh_back * sin_r

		var l_swing_factor: float = maxf(0.0, sin(phase - 1.1))
		var r_swing_factor: float = maxf(0.0, sin(phase + PI - 1.1))
		var l_knee_deg: float = lerpf(knee_stance, knee_swing, l_swing_factor)
		var r_knee_deg: float = lerpf(knee_stance, knee_swing, r_swing_factor)

		var l_foot_deg: float = sin(phase - 0.5) * 9.0 - l_knee_deg * 0.25
		var r_foot_deg: float = sin(phase + PI - 0.5) * 9.0 - r_knee_deg * 0.25

		_insert_rot(anim, rest_map, track_idx, "CC_Base_L_Thigh_00", t, Quaternion(Vector3.RIGHT, deg_to_rad(l_thigh_deg)))
		_insert_rot(anim, rest_map, track_idx, "CC_Base_R_Thigh_07", t, Quaternion(Vector3.RIGHT, deg_to_rad(r_thigh_deg)))
		_insert_rot(anim, rest_map, track_idx, "CC_Base_L_Calf_04", t, Quaternion(Vector3.RIGHT, -deg_to_rad(l_knee_deg)))
		_insert_rot(anim, rest_map, track_idx, "CC_Base_R_Calf_08", t, Quaternion(Vector3.RIGHT, -deg_to_rad(r_knee_deg)))
		_insert_rot(anim, rest_map, track_idx, "CC_Base_L_Foot_05", t, Quaternion(Vector3.RIGHT, deg_to_rad(l_foot_deg)))
		_insert_rot(anim, rest_map, track_idx, "CC_Base_R_Foot_09", t, Quaternion(Vector3.RIGHT, deg_to_rad(r_foot_deg)))

		# Brazos pegados naturalmente a los costados (net ~ -84°) balanceando en contrafase
		var l_elb_deg := elbow_base + maxf(0.0, sin_r) * 12.0
		var r_elb_deg := elbow_base + maxf(0.0, sin_l) * 12.0
		_insert_arm_pose(anim, rest_map, track_idx, t, true, 6.0, 78.5, sin_r * arm_swing, 6.0, l_elb_deg, 6.0)
		_insert_arm_pose(anim, rest_map, track_idx, t, false, 6.0, 78.5, sin_l * arm_swing, 6.0, r_elb_deg, 6.0)

	return anim
