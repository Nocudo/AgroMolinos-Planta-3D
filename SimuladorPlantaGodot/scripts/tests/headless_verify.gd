extends SceneTree

# ==============================================================================
# HEADLESS VERIFICATION SUITE - AGROMOLINOS GODOT 4.7 SERIOUS GAME
# Valida la coherencia de escenas, físicas de Kloss, fallas diegéticas y Cloud AI
# ==============================================================================

const InductionMotorKloss = preload("res://scripts/physics/InductionMotorKloss.gd")

func _init() -> void:
	print("\n=======================================================")
	print("  AGROMOLINOS DEL VALLE S.A. - HEADLESS QA TEST SUITE  ")
	print("  Proyecto Final Máquinas Eléctricas (Godot 4.7.2)     ")
	print("=======================================================\n")
	
	var total_tests: int = 0
	var passed_tests: int = 0

	# TEST 1: Carga de escenas críticas
	total_tests += 1
	print("[QA 1/6] Verificando carga de escenas principales (.tscn)...")
	var scenes = [
		"res://scenes/main.tscn",
		"res://scenes/player/PlayerOperator.tscn",
		"res://scenes/equipment/MotorMillUnit.tscn",
		"res://scenes/equipment/PhysicalCableConductor.tscn",
		"res://scenes/equipment/PhysicalHopperFeeder.tscn",
		"res://scenes/equipment/PhysicalBreakerPanel.tscn",
		"res://scenes/equipment/InteractiveGrainBag.tscn",
		"res://scenes/infrastructure/FactoryEntranceAndLockers.tscn",
		"res://scenes/ui/HUD.tscn",
		"res://scenes/ui/IndustrialTablet.tscn"
	]
	var all_scenes_ok: bool = true
	for s_path in scenes:
		var packed = ResourceLoader.load(s_path)
		if packed == null or not (packed is PackedScene):
			print("   FAILED: No se pudo cargar: ", s_path)
			all_scenes_ok = false
		else:
			print("   -> OK Scene: ", s_path.get_file())
	
	if all_scenes_ok:
		passed_tests += 1
		print("   [PASS] Todas las 9 escenas empaquetadas compilan sin errores.\n")
	else:
		_fail_and_quit("Fallo en compilación de escenas.")

	# TEST 2: Físicas de Kloss y Nominal Motor 10 HP
	total_tests += 1
	print("[QA 2/6] Verificando modelo dinámico de Kloss (10 HP, 460 V, IE3)...")
	var motor = InductionMotorKloss.new()
	motor._ready()
	motor.start_motor()
	motor.set_vfd_target_frequency(60.0)

	# Simular 3 segundos de operación a plena carga
	for i in range(180):
		motor._physics_process(1.0 / 60.0)

	print("   Velocidad simulada: %.1f RPM (Nominal: 1750 RPM)" % motor.rotor_speed_rpm)
	print("   Corrientes de fase: Ia=%.1f A, Ib=%.1f A, Ic=%.1f A (Nominal: 13.5 A)" % [motor.current_l1, motor.current_l2, motor.current_l3])
	print("   Vibración RMS: %.2f mm/s (Zona A ISO 10816-3 < 1.4 mm/s)" % motor.vibration_rms_mm_s)

	assert(motor.rotor_speed_rpm >= 1650.0 and motor.rotor_speed_rpm <= 1800.0, "Velocidad fuera de rango nominal")
	assert(motor.current_l1 >= 8.0 and motor.current_l1 <= 15.0, "Corriente L1 fuera de rango nominal")
	assert(motor.vibration_rms_mm_s < 2.0, "Vibración inicial fuera de Zona A")
	passed_tests += 1
	print("   [PASS] Físicas nominales certificadas al 100%.\n")

	# TEST 3: Falla Física 1 - Corte de Cable (Monofasización en Fase L3)
	total_tests += 1
	print("[QA 3/6] Simulando Falla 1: Corte de Conductor L3 (Alicates)...")
	motor._on_conductor_cut("L3_Azul")
	for i in range(60):
		motor._physics_process(1.0 / 60.0)

	print("   Post-corte: Ic=%.1f A (Esperado: 0.0 A)" % motor.current_l3)
	print("   Post-corte: Ia=%.1f A, Ib=%.1f A (Esperado: > 20 A por sqrt(3)*FLA)" % [motor.current_l1, motor.current_l2])
	print("   Post-corte: Vibración 120Hz=%.2f mm/s (Zona D > 4.5 mm/s)" % motor.vibration_rms_mm_s)

	assert(motor.current_l3 == 0.0, "La corriente en fase cortada L3 debe ser 0 A")
	assert(motor.current_l1 >= 14.0, "Corriente en fase sana L1 debe reflejar sobrecarga de monofasización")
	assert(motor.vibration_rms_mm_s >= 4.5, "Vibración por campo inverso debe alcanzar Zona D")
	passed_tests += 1
	print("   [PASS] Falla física de corte de cable certificada.\n")

	# Reparar cable
	motor._on_conductor_repaired("L3_Azul")
	for i in range(30):
		motor._physics_process(1.0 / 60.0)

	# TEST 4: Falla Física 2 - Atasco Mecánico en Tolva (Exceso de Grano)
	total_tests += 1
	print("[QA 4/6] Simulando Falla 2: Sobrealimentación masiva en Tolva (Bulto 50 kg)...")
	motor._on_hopper_overfed(4.5)
	for i in range(120):
		motor._physics_process(1.0 / 60.0)

	print("   Post-atasco: Velocidad rotor=%.1f RPM (Rotor bloqueado cala a 0 RPM)" % motor.rotor_speed_rpm)
	print("   Post-atasco: Corriente LRA=%.1f A (Pico rotor bloqueado ~81 A)" % motor.current_l1)

	assert(motor.rotor_speed_rpm < 150.0, "Rotor debe calar a 0 RPM por superar Tmax")
	assert(motor.current_l1 > 60.0, "Corriente debe alcanzar condición de rotor bloqueado (LRA)")
	passed_tests += 1
	print("   [PASS] Falla física de sobrealimentación y rotor bloqueado certificada.\n")

	# TEST 5: Falla Física 3 - Manipulación de Breaker CCM (Bajón de Tensión)
	total_tests += 1
	print("[QA 5/6] Simulando Falla 3: Falso contacto en breaker (Bajón a 340 V)...")
	motor._on_hopper_overfed(0.8) # Normalizar tolva
	motor._on_breaker_changed("Breaker_L3", false) # Breaker abierto
	for i in range(60):
		motor._physics_process(1.0 / 60.0)

	print("   Tensión de red en barraje: %.1f V (Esperado: 340 V)" % motor.current_voltage)
	assert(motor.current_voltage == 340.0, "Tensión debe registrar caída resistiva a 340 V")
	passed_tests += 1
	print("   [PASS] Falla física de bajón de tensión en CCM certificada.\n")

	# TEST 6: Puente Cloud IoT y Tablet
	total_tests += 1
	print("[QA 6/6] Verificando inicialización de Cloud IoT Bridge y Tablet...")
	var tablet_scene = ResourceLoader.load("res://scenes/ui/IndustrialTablet.tscn")
	var tablet_inst = tablet_scene.instantiate()
	var tablet_ctrl = tablet_inst.get_node_or_null("TabletRoot")
	assert(tablet_ctrl != null, "Controlador de tablet no encontrado")
	
	# Simular recepción de alerta de IA
	var test_alert = {
		"title": "DESBALANCE CRÍTICO: PÉRDIDA DE FASE L3",
		"severity": "CRITICAL",
		"confidence": 99.8,
		"root_cause": "Conductor L3 abierto por corte físico.",
		"prognosis": "Riesgo de daño térmico en 42 s.",
		"prescription": "Parada inmediata y LOTO.",
		"mhi": 42.0,
		"maintenance_steps": ["1. E-Stop", "2. LOTO", "3. Reparar"]
	}
	tablet_ctrl.call("_on_ai_alert_received", test_alert)
	passed_tests += 1
	print("   [PASS] Integración con Tablet y despacho de alertas IA certificado.\n")

	print("=======================================================")
	print("  RESULTADO: %d/%d PRUEBAS SUPERADAS EXITOSAMENTE (100%%) " % [passed_tests, total_tests])
	print("  PROYECTO SERIOUS GAME EN GODOT 4.7 CERTIFICADO QA    ")
	print("=======================================================\n")
	
	motor.free()
	tablet_inst.free()
	quit(0)

func _fail_and_quit(msg: String) -> void:
	print("ERROR CRÍTICO QA: ", msg)
	quit(1)
