class_name IndustrialSoundSynthesizer
extends RefCounted

# ==============================================================================
# SINTETIZADOR PROCEDURAL DE AUDIO INDUSTRIAL (16-BIT PCM AudioStreamWAV)
# Genera en memoria todos los efectos de sonido espaciales y de interfaz sin
# depender de archivos binarios .wav/.ogg externos.
# ==============================================================================

const MIX_RATE: int = 22050
static var _cache: Dictionary = {}

static func clear_cache() -> void:
	_cache.clear()

static func _build_wav(samples: PackedFloat32Array, loop: bool = false, target_peak: float = 0.88) -> AudioStreamWAV:
	var n: int = samples.size()
	var peak: float = 0.0
	for i in range(n):
		var a: float = absf(samples[i])
		if a > peak:
			peak = a
	var norm_gain: float = (target_peak / peak) if peak > 0.001 else 1.0

	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var s: float = clampf(samples[i] * norm_gain, -0.98, 0.98)
		var pcm: int = int(roundf(s * 32767.0))
		bytes.encode_s16(i * 2, pcm)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = n
	else:
		wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return wav

static func _get_or_build(_key: String, builder: Callable) -> AudioStreamWAV:
	return builder.call() as AudioStreamWAV

static func _make_crossfaded_loop_noise(n: int, seed_val: int, smoothing: float) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var overlap: int = mini(512, n / 4)
	var raw := PackedFloat32Array()
	raw.resize(n + overlap)
	var lp: float = 0.0
	for i in range(n + overlap):
		var white: float = rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, white, smoothing)
		raw[i] = white - lp * 0.65

	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		out[i] = raw[i]
	for i in range(overlap):
		var alpha: float = float(i) / float(overlap)
		out[i] = lerpf(raw[n + i], raw[i], alpha)
	return out

static func create_motor_hum_loop() -> AudioStreamWAV:
	return _get_or_build("motor_hum", func() -> AudioStreamWAV:
		var duration: float = 1.0
		var n: int = int(roundf(duration * float(MIX_RATE)))
		var samples := PackedFloat32Array()
		samples.resize(n)
		var mill_noise := _make_crossfaded_loop_noise(n, 46010, 0.28)
		for i in range(n):
			var t: float = float(i) / float(MIX_RATE)
			# Armónicos electromagnéticos 60 Hz y rotación 1800 RPM (30 Hz) - ciclos exactos en 1.0 s
			var f60: float = sin(TAU * 60.0 * t) * 0.34
			var f120: float = sin(TAU * 120.0 * t) * 0.22
			var f180: float = sin(TAU * 180.0 * t) * 0.14
			var f240: float = sin(TAU * 240.0 * t) * 0.08
			var slot: float = sin(TAU * 870.0 * t) * 0.035
			# Pulso de martillos y molienda de cereal a 30 Hz
			var hammer_env: float = 0.6 + 0.4 * sin(TAU * 30.0 * t)
			var mill_grit: float = mill_noise[i] * 0.20 * hammer_env
			samples[i] = (f60 + f120 + f180 + f240 + slot + mill_grit) * 0.72
		return _build_wav(samples, true, 0.72)
	)

static func create_electric_arc_sound() -> AudioStreamWAV:
	return _get_or_build("electric_arc", func() -> AudioStreamWAV:
		var duration: float = 0.55
		var n: int = int(roundf(duration * float(MIX_RATE)))
		var samples := PackedFloat32Array()
		samples.resize(n)
		var rng := RandomNumberGenerator.new()
		rng.seed = 46060
		var prev: float = 0.0
		for i in range(n):
			var t: float = float(i) / float(MIX_RATE)
			var attack: float = clampf(t / 0.004, 0.0, 1.0)
			var decay: float = exp(-4.8 * t)
			var tail_fade: float = clampf((duration - t) / 0.04, 0.0, 1.0)
			var gate: float = 1.0 if rng.randf() > 0.28 else 0.25
			var white: float = rng.randf_range(-1.0, 1.0)
			var crackle: float = (white - prev * 0.5) * gate
			prev = white
			var buzz: float = clampf(sin(TAU * 120.0 * t) * 2.2, -1.0, 1.0) * 0.45
			var pop: float = (0.7 * rng.randf_range(-1.0, 1.0)) if (t < 0.05) else 0.0
			samples[i] = (crackle * 0.58 + buzz + pop) * attack * decay * tail_fade
		return _build_wav(samples, false)
	)

static func create_breaker_clunk_sound() -> AudioStreamWAV:
	return _get_or_build("breaker_clunk", func() -> AudioStreamWAV:
		var duration: float = 0.18
		var n: int = int(roundf(duration * float(MIX_RATE)))
		var samples := PackedFloat32Array()
		samples.resize(n)
		var rng := RandomNumberGenerator.new()
		rng.seed = 340460
		var phase_thud: float = 0.0
		for i in range(n):
			var t: float = float(i) / float(MIX_RATE)
			var freq: float = lerpf(135.0, 48.0, clampf(t / 0.04, 0.0, 1.0))
			phase_thud += TAU * freq / float(MIX_RATE)
			var thud: float = sin(phase_thud) * exp(-28.0 * t) * 0.72
			var click: float = 0.0
			if t >= 0.018:
				var dt: float = t - 0.018
				click = (sin(TAU * 1120.0 * dt) * 0.45 + rng.randf_range(-0.35, 0.35)) * exp(-65.0 * dt)
			var fade: float = clampf((duration - t) / 0.02, 0.0, 1.0)
			samples[i] = (thud + click) * fade
		return _build_wav(samples, false)
	)

static func create_hopper_grain_loop() -> AudioStreamWAV:
	return _get_or_build("hopper_grain", func() -> AudioStreamWAV:
		var duration: float = 0.8
		var n: int = int(roundf(duration * float(MIX_RATE)))
		var samples := PackedFloat32Array()
		samples.resize(n)
		var grain_noise := _make_crossfaded_loop_noise(n, 50501, 0.52)
		for i in range(n):
			var t: float = float(i) / float(MIX_RATE)
			# 5 ciclos exactos en 0.8 s (6.25 Hz) para el giro del helicoidal y cascada de grano
			var auger_mod: float = 0.65 + 0.35 * sin(TAU * 6.25 * t)
			var cascade_low: float = sin(TAU * 45.0 * t) * 0.08
			samples[i] = (grain_noise[i] * 0.34 * auger_mod + cascade_low)
		return _build_wav(samples, true, 0.72)
	)

static func create_footstep_sound() -> AudioStreamWAV:
	return _get_or_build("footstep", func() -> AudioStreamWAV:
		var duration: float = 0.16
		var n: int = int(roundf(duration * float(MIX_RATE)))
		var samples := PackedFloat32Array()
		samples.resize(n)
		var rng := RandomNumberGenerator.new()
		rng.seed = 18080
		var phase: float = 0.0
		var lp_noise: float = 0.0
		var prev_noise: float = 0.0
		for i in range(n):
			var t: float = float(i) / float(MIX_RATE)
			var f: float = lerpf(175.0, 62.0, clampf(t / 0.055, 0.0, 1.0))
			phase += TAU * f / float(MIX_RATE)
			var heel: float = sin(phase) * exp(-26.0 * t) * 0.55
			var white: float = rng.randf_range(-1.0, 1.0)
			lp_noise = lerpf(lp_noise, white, 0.45)
			var mid_grit: float = (lp_noise - prev_noise * 0.55) * exp(-28.0 * t) * 0.55
			prev_noise = lp_noise
			var click: float = sin(TAU * 980.0 * t) * exp(-70.0 * t) * 0.25
			var attack: float = clampf(t / 0.003, 0.0, 1.0)
			var tail: float = clampf((duration - t) / 0.02, 0.0, 1.0)
			samples[i] = (heel + mid_grit + click) * attack * tail
		return _build_wav(samples, false, 0.90)
	)

static func create_epp_equip_sound() -> AudioStreamWAV:
	return _get_or_build("epp_equip", func() -> AudioStreamWAV:
		var duration: float = 0.36
		var n: int = int(roundf(duration * float(MIX_RATE)))
		var samples := PackedFloat32Array()
		samples.resize(n)
		var rng := RandomNumberGenerator.new()
		rng.seed = 60060
		for i in range(n):
			var t: float = float(i) / float(MIX_RATE)
			var s: float = 0.0
			if t < 0.13:
				# Ajuste de correa/cremallera
				var env_z: float = sin(PI * t / 0.13)
				s += rng.randf_range(-0.22, 0.22) * env_z * (0.5 + 0.5 * sin(TAU * 42.0 * t))
			if t >= 0.08 and t < 0.22:
				var dt1: float = t - 0.08
				var env1: float = clampf(dt1 / 0.01, 0.0, 1.0) * exp(-14.0 * dt1)
				s += sin(TAU * 587.33 * dt1) * 0.34 * env1
			if t >= 0.19:
				var dt2: float = t - 0.19
				var env2: float = clampf(dt2 / 0.01, 0.0, 1.0) * exp(-13.0 * dt2)
				s += (sin(TAU * 880.0 * dt2) + 0.25 * sin(TAU * 1760.0 * dt2)) * 0.30 * env2
			samples[i] = s * clampf((duration - t) / 0.02, 0.0, 1.0)
		return _build_wav(samples, false)
	)

static func create_wrench_ratchet_sound() -> AudioStreamWAV:
	return _get_or_build("wrench_ratchet", func() -> AudioStreamWAV:
		var duration: float = 0.22
		var n: int = int(roundf(duration * float(MIX_RATE)))
		var samples := PackedFloat32Array()
		samples.resize(n)
		for i in range(n):
			var t: float = float(i) / float(MIX_RATE)
			var s: float = 0.0
			var env1: float = exp(-52.0 * t)
			s += (sin(TAU * 1420.0 * t) * 0.38 + sin(TAU * 2280.0 * t) * 0.24) * env1
			if t >= 0.085:
				var dt: float = t - 0.085
				var env2: float = exp(-56.0 * dt)
				s += (sin(TAU * 1580.0 * dt) * 0.38 + sin(TAU * 2520.0 * dt) * 0.24) * env2
			samples[i] = s * clampf((duration - t) / 0.015, 0.0, 1.0)
		return _build_wav(samples, false)
	)

static func create_scada_alert_sound() -> AudioStreamWAV:
	return _get_or_build("scada_alert", func() -> AudioStreamWAV:
		var duration: float = 0.42
		var n: int = int(roundf(duration * float(MIX_RATE)))
		var samples := PackedFloat32Array()
		samples.resize(n)
		for i in range(n):
			var t: float = float(i) / float(MIX_RATE)
			var s: float = 0.0
			if t < 0.16:
				var env1: float = clampf(t / 0.008, 0.0, 1.0) * clampf((0.16 - t) / 0.012, 0.0, 1.0)
				s = (sin(TAU * 880.0 * t) + 0.3 * sin(TAU * 1760.0 * t)) * 0.34 * env1
			elif t >= 0.20 and t < 0.39:
				var dt: float = t - 0.20
				var env2: float = clampf(dt / 0.008, 0.0, 1.0) * clampf((0.39 - t) / 0.015, 0.0, 1.0)
				s = (sin(TAU * 1318.5 * dt) + 0.3 * sin(TAU * 2637.0 * dt)) * 0.34 * env2
			samples[i] = s
		return _build_wav(samples, false)
	)

static func create_station_chime_sound() -> AudioStreamWAV:
	return _get_or_build("station_chime", func() -> AudioStreamWAV:
		var duration: float = 0.32
		var n: int = int(roundf(duration * float(MIX_RATE)))
		var samples := PackedFloat32Array()
		samples.resize(n)
		for i in range(n):
			var t: float = float(i) / float(MIX_RATE)
			var s: float = 0.0
			var env1: float = clampf(t / 0.008, 0.0, 1.0) * exp(-12.0 * t)
			s += (sin(TAU * 523.25 * t) + 0.2 * sin(TAU * 1046.5 * t)) * 0.32 * env1
			if t >= 0.11:
				var dt: float = t - 0.11
				var env2: float = clampf(dt / 0.008, 0.0, 1.0) * exp(-11.0 * dt)
				s += (sin(TAU * 659.25 * dt) + 0.2 * sin(TAU * 1318.5 * dt)) * 0.34 * env2
			samples[i] = s * clampf((duration - t) / 0.02, 0.0, 1.0)
		return _build_wav(samples, false)
	)

static func create_plant_ambience_loop() -> AudioStreamWAV:
	return _get_or_build("plant_ambience", func() -> AudioStreamWAV:
		var duration: float = 2.0
		var n: int = int(roundf(duration * float(MIX_RATE)))
		var samples := PackedFloat32Array()
		samples.resize(n)
		var rng := RandomNumberGenerator.new()
		rng.seed = 9001
		var overlap: int = 1024
		var raw := PackedFloat32Array()
		raw.resize(n + overlap)
		var brown: float = 0.0
		for i in range(n + overlap):
			brown = clampf(brown * 0.965 + rng.randf_range(-0.08, 0.08), -0.45, 0.45)
			raw[i] = brown
		for i in range(n):
			var t: float = float(i) / float(MIX_RATE)
			var air: float = raw[i]
			if i < overlap:
				var alpha: float = float(i) / float(overlap)
				air = lerpf(raw[n + i], raw[i], alpha)
			var trafo: float = sin(TAU * 60.0 * t) * 0.055 + sin(TAU * 120.0 * t) * 0.025
			samples[i] = air * 0.35 + trafo
		return _build_wav(samples, true, 0.72)
	)

static func create_door_latch_sound() -> AudioStreamWAV:
	return _get_or_build("door_latch", func() -> AudioStreamWAV:
		var dur: float = 0.40
		var n: int = int(dur * MIX_RATE)
		var samples := PackedFloat32Array()
		samples.resize(n)
		var rng := RandomNumberGenerator.new()
		rng.seed = 4091
		var lp: float = 0.0
		for i in range(n):
			var t: float = float(i) / float(MIX_RATE)
			var click: float = (sin(TAU * 1650.0 * t) * 0.45 + sin(TAU * 620.0 * t) * 0.50) * exp(-t * 36.0)
			var thud: float = sin(TAU * 155.0 * exp(-t * 3.5) * t) * exp(-t * 16.0) * 0.55
			lp = lp * 0.82 + rng.randf_range(-0.28, 0.28)
			var whoosh: float = lp * sin(PI * clampf(t / dur, 0.0, 1.0)) * 0.60
			samples[i] = (click + thud + whoosh) * clampf((dur - t) / 0.03, 0.0, 1.0)
		return _build_wav(samples, false, 0.90)
	)

static func create_gate_motor_sound() -> AudioStreamWAV:
	return _get_or_build("gate_motor", func() -> AudioStreamWAV:
		var dur: float = 0.90
		var n: int = int(dur * MIX_RATE)
		var samples := PackedFloat32Array()
		samples.resize(n)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7731
		var bp: float = 0.0
		for i in range(n):
			var t: float = float(i) / float(MIX_RATE)
			var env: float = minf(t / 0.08, 1.0) * minf((dur - t) / 0.14, 1.0)
			var f_drive: float = 110.0 + 26.0 * clampf(t / 0.25, 0.0, 1.0)
			var hum: float = sin(TAU * f_drive * t) * 0.35 + sin(TAU * (f_drive * 2.0) * t) * 0.22 + sin(TAU * (f_drive * 3.0) * t) * 0.12
			var gear_pulse: float = 0.5 + 0.5 * sin(TAU * 28.0 * t)
			bp = bp * 0.72 + rng.randf_range(-0.30, 0.30) * gear_pulse
			samples[i] = (hum + bp * 0.65) * maxf(env, 0.0)
		return _build_wav(samples, false, 0.90)
	)

static func create_tablet_push_warning_sound() -> AudioStreamWAV:
	return _get_or_build("tablet_push_warning", func() -> AudioStreamWAV:
		# Sonido característico de notificación push de tablet industrial (tríada ascendente + pulso doble de aviso)
		var duration: float = 0.56
		var n: int = int(roundf(duration * float(MIX_RATE)))
		var samples := PackedFloat32Array()
		samples.resize(n)
		for i in range(n):
			var t: float = float(i) / float(MIX_RATE)
			var s: float = 0.0
			if t < 0.14:
				var dt0: float = t
				var env0: float = clampf(dt0 / 0.006, 0.0, 1.0) * exp(-14.0 * dt0)
				s += (sin(TAU * 784.0 * dt0) * 0.45 + sin(TAU * 1568.0 * dt0) * 0.18) * env0
			if t >= 0.10 and t < 0.28:
				var dt1: float = t - 0.10
				var env1: float = clampf(dt1 / 0.006, 0.0, 1.0) * exp(-12.0 * dt1)
				s += (sin(TAU * 1046.5 * dt1) * 0.48 + sin(TAU * 2093.0 * dt1) * 0.20) * env1
			if t >= 0.25 and t < 0.52:
				var dt2: float = t - 0.25
				var env2: float = clampf(dt2 / 0.008, 0.0, 1.0) * exp(-8.5 * dt2)
				s += (sin(TAU * 1318.5 * dt2) * 0.52 + sin(TAU * 659.25 * dt2) * 0.22) * env2
			samples[i] = s * clampf((duration - t) / 0.025, 0.0, 1.0)
		return _build_wav(samples, false, 0.92)
	)

static func create_truck_diesel_loop() -> AudioStreamWAV:
	return _get_or_build("truck_diesel_loop", func() -> AudioStreamWAV:
		var duration: float = 1.0
		var n: int = int(roundf(duration * float(MIX_RATE)))
		var samples := PackedFloat32Array()
		samples.resize(n)
		var rumble_noise := _make_crossfaded_loop_noise(n, 88101, 0.72)
		var lp: float = 0.0
		for i in range(n):
			var t: float = float(i) / float(MIX_RATE)
			# Motor diésel pesado 6 cilindros (ralentí 600-840 RPM -> pulso 28 Hz / 56 Hz)
			var cyl_pulse: float = 0.65 + 0.35 * sin(TAU * 28.0 * t)
			var sub_bass: float = sin(TAU * 28.0 * t) * 0.40 + sin(TAU * 56.0 * t) * 0.28 + sin(TAU * 84.0 * t) * 0.16 + sin(TAU * 112.0 * t) * 0.08
			lp = lerpf(lp, rumble_noise[i], 0.16)
			var exhaust: float = lp * 0.42 * cyl_pulse
			samples[i] = sub_bass * 0.65 + exhaust
		return _build_wav(samples, true, 0.78)
	)

static func create_truck_reverse_beep_loop() -> AudioStreamWAV:
	return _get_or_build("truck_reverse_beep", func() -> AudioStreamWAV:
		# Alarma industrial de reversa (0.80 s período exacto -> pitido de 0.34 s a 1220 Hz)
		var duration: float = 0.80
		var n: int = int(roundf(duration * float(MIX_RATE)))
		var samples := PackedFloat32Array()
		samples.resize(n)
		for i in range(n):
			var t: float = float(i) / float(MIX_RATE)
			var s: float = 0.0
			if t < 0.34:
				var env: float = clampf(t / 0.012, 0.0, 1.0) * clampf((0.34 - t) / 0.018, 0.0, 1.0)
				var raw: float = sin(TAU * 1220.0 * t) * 0.65 + sin(TAU * 2440.0 * t) * 0.22 + sin(TAU * 3660.0 * t) * 0.10
				s = clampf(raw * 1.15, -0.95, 0.95) * env
			samples[i] = s * 0.75
		return _build_wav(samples, true, 0.85)
	)

static func create_truck_air_brake_sound() -> AudioStreamWAV:
	return _get_or_build("truck_air_brake", func() -> AudioStreamWAV:
		var duration: float = 0.52
		var n: int = int(roundf(duration * float(MIX_RATE)))
		var samples := PackedFloat32Array()
		samples.resize(n)
		var rng := RandomNumberGenerator.new()
		rng.seed = 46802
		var prev: float = 0.0
		for i in range(n):
			var t: float = float(i) / float(MIX_RATE)
			var attack: float = clampf(t / 0.008, 0.0, 1.0)
			var decay: float = exp(-6.2 * t)
			var white: float = rng.randf_range(-1.0, 1.0)
			var hiss: float = (white - prev * 0.42) * 0.85
			prev = white
			var valve_pop: float = sin(TAU * 145.0 * t) * exp(-42.0 * t) * 0.45
			var tail: float = clampf((duration - t) / 0.03, 0.0, 1.0)
			samples[i] = (hiss * attack * decay + valve_pop) * tail
		return _build_wav(samples, false, 0.88)
	)

static func create_truck_horn_sound() -> AudioStreamWAV:
	return _get_or_build("truck_air_horn", func() -> AudioStreamWAV:
		var duration: float = 0.56
		var n: int = int(roundf(duration * float(MIX_RATE)))
		var samples := PackedFloat32Array()
		samples.resize(n)
		for i in range(n):
			var t: float = float(i) / float(MIX_RATE)
			var env: float = clampf(t / 0.025, 0.0, 1.0) * clampf((duration - t) / 0.055, 0.0, 1.0)
			var d1: float = sin(TAU * 277.18 * t) * 0.42 + sin(TAU * 554.37 * t) * 0.18 + sin(TAU * 831.55 * t) * 0.10
			var d2: float = sin(TAU * 349.23 * t) * 0.40 + sin(TAU * 698.46 * t) * 0.16
			samples[i] = (d1 + d2) * env * 0.72
		return _build_wav(samples, false, 0.86)
	)
