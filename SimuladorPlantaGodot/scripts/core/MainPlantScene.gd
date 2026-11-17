class_name MainPlantScene
extends Node3D

# ==============================================================================
# ESCENA MAESTRA DE LA PLANTA AGROMOLINOS DEL VALLE S.A.
# ==============================================================================

const SoundSynth = preload("res://scripts/core/IndustrialSoundSynthesizer.gd")
const GlowControllerScript = preload("res://scripts/interactive/InteractableGlowController.gd")
const VisibilityOptimizerScript = preload("res://scripts/environment/PlantVisibilityOptimizer.gd")
const PauseMenuControllerScript = preload("res://scripts/ui/PauseMenuController.gd")

@onready var motor_mill: Node3D = $MotorMillUnit
@onready var plant_lights: Node3D = $PlantLights

var _base_light_energies: Dictionary = {}
var motor_audio_3d: AudioStreamPlayer3D = null
var ambience_player: AudioStreamPlayer = null
var sfx_player: AudioStreamPlayer = null
var sfx_players: Array[AudioStreamPlayer] = []
var _sfx_rr_idx: int = 0

func _ready() -> void:
	# Activar modo pantalla completa en sesión interactiva (evitar en --headless)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	if motor_mill != null:
		var motor = motor_mill.get_node_or_null("InductionMotor")
		if motor != null:
			var sm = get_node_or_null("/root/SimulationManager")
			if sm != null and sm.has_method("register_motor"):
				sm.register_motor(motor)

	_setup_plant_audio()
	_cache_light_energies()
	if get_node_or_null("InteractableGlowController") == null:
		var glow_ctrl := GlowControllerScript.new()
		glow_ctrl.name = "InteractableGlowController"
		add_child(glow_ctrl)

	if get_node_or_null("PlantVisibilityOptimizer") == null:
		var vis_opt := VisibilityOptimizerScript.new()
		vis_opt.name = "PlantVisibilityOptimizer"
		add_child(vis_opt)

	if get_node_or_null("PauseMenuController") == null:
		var pause_menu := PauseMenuControllerScript.new()
		pause_menu.name = "PauseMenuController"
		add_child(pause_menu)

	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.breaker_changed.connect(_on_breaker_changed)
		if bus.has_signal("telemetry_updated") and not bus.telemetry_updated.is_connected(_on_telemetry_updated):
			bus.telemetry_updated.connect(_on_telemetry_updated)
		if bus.has_signal("epp_state_changed") and not bus.epp_state_changed.is_connected(_on_epp_state_changed):
			bus.epp_state_changed.connect(_on_epp_state_changed)
		if bus.has_signal("bolt_loosened") and not bus.bolt_loosened.is_connected(_on_bolt_loosened):
			bus.bolt_loosened.connect(_on_bolt_loosened)
		if bus.has_signal("conductor_repaired_event") and not bus.conductor_repaired_event.is_connected(_on_conductor_repaired):
			bus.conductor_repaired_event.connect(_on_conductor_repaired)
		if bus.has_signal("ventilation_blocked") and not bus.ventilation_blocked.is_connected(_on_ventilation_blocked):
			bus.ventilation_blocked.connect(_on_ventilation_blocked)
		if bus.has_signal("tutorial_station_reached") and not bus.tutorial_station_reached.is_connected(_on_tutorial_station_reached):
			bus.tutorial_station_reached.connect(_on_tutorial_station_reached)
		if bus.has_signal("golden_rule_step_completed") and not bus.golden_rule_step_completed.is_connected(_on_golden_rule_step_completed):
			bus.golden_rule_step_completed.connect(_on_golden_rule_step_completed)
		if bus.has_signal("safety_violation_committed") and not bus.safety_violation_committed.is_connected(_on_safety_violation_committed):
			bus.safety_violation_committed.connect(_on_safety_violation_committed)
		if bus.has_signal("safety_line_crossed") and not bus.safety_line_crossed.is_connected(_on_safety_line_crossed):
			bus.safety_line_crossed.connect(_on_safety_line_crossed)
		if bus.has_signal("emergency_stop_triggered") and not bus.emergency_stop_triggered.is_connected(_on_emergency_stop_triggered):
			bus.emergency_stop_triggered.connect(_on_emergency_stop_triggered)
		if bus.has_signal("induction_briefing_closed") and not bus.induction_briefing_closed.is_connected(_on_briefing_closed_sfx):
			bus.induction_briefing_closed.connect(_on_briefing_closed_sfx)

func _setup_plant_audio() -> void:
	motor_audio_3d = AudioStreamPlayer3D.new()
	motor_audio_3d.name = "MotorHumAudio3D"
	motor_audio_3d.bus = "SFX"
	motor_audio_3d.stream = SoundSynth.create_motor_hum_loop()
	motor_audio_3d.unit_size = 14.0
	motor_audio_3d.max_distance = 70.0
	motor_audio_3d.volume_db = -1.0
	if motor_mill != null:
		motor_mill.add_child(motor_audio_3d)
	else:
		add_child(motor_audio_3d)
	motor_audio_3d.play()

	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "PlantAmbienceAudio"
	ambience_player.bus = "Ambience"
	ambience_player.process_mode = Node.PROCESS_MODE_ALWAYS
	ambience_player.stream = SoundSynth.create_plant_ambience_loop()
	ambience_player.volume_db = -14.5
	add_child(ambience_player)
	ambience_player.play()

	for i in range(3):
		var sp := AudioStreamPlayer.new()
		sp.name = "PlantEventSFXAudio" if i == 0 else "PlantEventSFXAudio_%d" % i
		sp.bus = "SFX"
		sp.process_mode = Node.PROCESS_MODE_ALWAYS
		sp.volume_db = -3.5
		add_child(sp)
		sfx_players.append(sp)
	sfx_player = sfx_players[0]

func _exit_tree() -> void:
	if motor_audio_3d != null:
		motor_audio_3d.stop()
		motor_audio_3d.stream = null
	if ambience_player != null:
		ambience_player.stop()
		ambience_player.stream = null
	for sp in sfx_players:
		if is_instance_valid(sp):
			sp.stop()
			sp.stream = null
	sfx_player = null

func _play_event_sfx(wav: AudioStreamWAV) -> void:
	if sfx_players.is_empty() or wav == null:
		return
	var chosen: AudioStreamPlayer = null
	for sp in sfx_players:
		if not sp.playing:
			chosen = sp
			break
	if chosen == null:
		chosen = sfx_players[_sfx_rr_idx % sfx_players.size()]
		_sfx_rr_idx += 1
	chosen.stream = wav
	chosen.play()

func _on_briefing_closed_sfx(_resume_tour: bool) -> void:
	_play_event_sfx(SoundSynth.create_station_chime_sound())

func _on_telemetry_updated(rpm: float, cur_a: float, _cur_b: float, _cur_c: float, _volt: float, _freq: float, _temp: float, vib: float, _p_kw: float, _pf: float, _flow: float) -> void:
	if motor_audio_3d == null:
		return
	if rpm < 15.0:
		motor_audio_3d.volume_db = -45.0
	else:
		motor_audio_3d.pitch_scale = clampf(0.45 + 0.55 * (rpm / 1750.0), 0.35, 1.35)
		motor_audio_3d.volume_db = clampf(-2.5 + (cur_a - 12.0) * 0.14 + (vib - 1.5) * 0.35, -5.0, 4.0)

func _on_epp_state_changed(_all_equipped: bool, _items: Dictionary) -> void:
	_play_event_sfx(SoundSynth.create_epp_equip_sound())

func _on_bolt_loosened(_bolt_id: String, _loosened: bool) -> void:
	_play_event_sfx(SoundSynth.create_wrench_ratchet_sound())

func _on_conductor_repaired(_phase_id: String) -> void:
	_play_event_sfx(SoundSynth.create_wrench_ratchet_sound())

func _on_ventilation_blocked(_blocked: bool) -> void:
	_play_event_sfx(SoundSynth.create_wrench_ratchet_sound())

func _on_tutorial_station_reached(_station_index: int, _station_title: String) -> void:
	_play_event_sfx(SoundSynth.create_station_chime_sound())

func _on_golden_rule_step_completed(_step_index: int, _rule_name: String) -> void:
	_play_event_sfx(SoundSynth.create_station_chime_sound())

func _on_safety_violation_committed(_code: String, _description: String, _penalty: float) -> void:
	_play_event_sfx(SoundSynth.create_scada_alert_sound())

func _on_safety_line_crossed(active: bool, _zone_id: String, _title: String, _message: String) -> void:
	if active:
		_play_event_sfx(SoundSynth.create_scada_alert_sound())

func _on_emergency_stop_triggered(_source: String) -> void:
	_play_event_sfx(SoundSynth.create_scada_alert_sound())

func _cache_light_energies() -> void:
	_base_light_energies.clear()
	for group_root in _get_light_containers():
		for light in group_root.get_children():
			if light is Light3D:
				_base_light_energies[light.get_instance_id()] = light.light_energy

func _get_light_containers() -> Array[Node]:
	var containers: Array[Node] = []
	if plant_lights != null:
		containers.append(plant_lights)
	var industrial_lights := find_child("LucesIndustriales", true, false)
	if industrial_lights != null and not containers.has(industrial_lights):
		containers.append(industrial_lights)
	return containers

func _on_breaker_changed(_breaker_id: String, active: bool) -> void:
	var containers := _get_light_containers()
	if containers.is_empty():
		return

	# Flicker / bajón de intensidad en luminarias CCM y High-Bay 5000K
	var factor: float = 1.0 if active else 0.55
	for group_root in containers:
		for light in group_root.get_children():
			if light is Light3D:
				var base_e: float = float(_base_light_energies.get(light.get_instance_id(), light.light_energy))
				var t = create_tween()
				t.tween_property(light, "light_energy", base_e * 0.2, 0.08)
				t.tween_property(light, "light_energy", base_e * factor, 0.15)
