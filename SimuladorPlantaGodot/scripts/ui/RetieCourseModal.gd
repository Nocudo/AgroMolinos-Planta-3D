class_name RetieCourseModal
extends ColorRect

## Modal interactivo en la Sala de Reuniones para el Curso Rápido SST (RETIE):
## Etapa 1 -> 3 fichas de información clara sobre EPP, 5 Reglas de Oro y Molienda 10 HP.
## Etapa 2 -> Quiz simple de 3 preguntas de opción múltiple con validación inmediata.

signal course_finished(passed: bool, score: int, total: int)

const INFO_SLIDES: Array[Dictionary] = [
	{
		"badge": "MÓDULO 1 DE 3  •  RETIE ARTÍCULO 20 & OSHA 1910",
		"title": "1. Equipo de Protección Personal (EPP) Obligatorio",
		"body": "Antes de cruzar la Esclusa Norte e ingresar a la nave de molienda (460 V AC / > 85 dBA), todo operario debe equipar en los lockers de Vestidores las 6 prendas certificadas:\n\n"
		+ "• [b]Casco dieléctrico Tipo I Clase E (20,000 V)[/b] y [b]Gafas ANSI Z87.1[/b]\n"
		+ "• [b]Protección auditiva NRR 27 dB[/b] (ruido continuo de martillos > 85 dBA)\n"
		+ "• [b]Guantes aislantes Clase 0 (1,000 V)[/b] y [b]Botas dieléctricas (18 kV)[/b]\n"
		+ "• [b]Overol ignífugo Arc Flash Categoría 2 (8 cal/cm²)[/b]"
	},
	{
		"badge": "MÓDULO 2 DE 3  •  TABLERO CCM 460 V & LOTO",
		"title": "2. Las 5 Reglas de Oro de Seguridad Eléctrica",
		"body": "Para intervenir el motor de 10 HP, borneras o el Variador de Frecuencia (VFD) en el Tablero CCM 460 V sin riesgo de electrocución ni arco eléctrico, aplica siempre:\n\n"
		+ "1. [b]Corte visible[/b]: abrir seccionador y breaker principal L1/L2/L3.\n"
		+ "2. [b]Bloqueo y etiquetado (LOTO)[/b]: asegurar con [color=#ffd15c][b][5] Kit LOTO[/b][/color].\n"
		+ "3. [b]Verificar ausencia de tensión[/b]: comprobar 0 V con [color=#ffd15c][b][4] Multímetro[/b][/color].\n"
		+ "4. [b]Puesta a tierra temporal y cortocircuito[/b].\n"
		+ "5. [b]Señalizar área roja[/b] (despeje mínimo 1.0 m frente al tablero)."
	},
	{
		"badge": "MÓDULO 3 DE 3  •  MOLINO M-101, ATEX & TELEMETRÍA [TAB]",
		"title": "3. Operación Segura, Polvo Combustible ATEX y Fallas",
		"body": "• [b]Fallas físicas en campo[/b]: nunca repares conductores cortados (L3), pernos flojos ni tolva atascada T-301 con el motor energizado; pulsa [color=#ff7575][b][X] E-Stop[/b][/color] o abre el breaker primero.\n"
		+ "• [b]Zona ATEX 22 (NFPA 61)[/b]: los ciclones generan polvo combustible de cereal; evita chispas y mantén la ventilación despejada.\n"
		+ "• [b]Tablet Industrial [TAB][/b]: supervisa corrientes, temperatura Clase F, vibración ISO 10816-3, diagnóstico Edge IA (MLP/SVM), cámaras CCTV y ahorro energético VFD vs DOL."
	}
]

const QUIZ_QUESTIONS: Array[Dictionary] = [
	{
		"q": "1. Según el RETIE Art. 20, ¿qué debes hacer ANTES de entrar a la zona de molienda de 460 V?",
		"options": [
			"A) Vestir la ropa ignífuga y las 6 prendas EPP en Vestidores",
			"B) Entrar directo sin casco para caminar más rápido",
			"C) Encender el motor antes de revisar el tablero"
		],
		"correct": 0
	},
	{
		"q": "2. Al aplicar las 5 Reglas de Oro sobre el Tablero CCM de 460 V, antes de tocar cables debes:",
		"options": [
			"A) Abrir las ventanas de la oficina administrativa",
			"B) Aplicar bloqueo LOTO y verificar 0 V con el Multímetro",
			"C) Mojar la bornera para reducir la temperatura"
		],
		"correct": 1
	},
	{
		"q": "3. Si llega una alerta crítica a la Tablet [TAB] (falla de fase L3 o sobrecalentamiento), ¿cuál es la acción correcta?",
		"options": [
			"A) Ignorar el sonido y arrojar más maíz a la tolva",
			"B) Quitar la alarma sin revisar la máquina",
			"C) Detener/desenergizar con E-Stop o Breaker, aplicar LOTO y reparar"
		],
		"correct": 2
	}
]

var _mode: String = "INFO" # "INFO" | "QUIZ" | "RESULT"
var _slide_idx: int = 0
var _answers: Array[int] = [-1, -1, -1]
var _quiz_submitted: bool = false

var _lbl_badge: Label = null
var _lbl_title: Label = null
var _rtl_info: RichTextLabel = null
var _info_box: VBoxContainer = null
var _quiz_box: VBoxContainer = null
var _quiz_cards: Array[Dictionary] = []
var _lbl_quiz_feedback: Label = null
var _cc: CenterContainer = null
var _btn_prev: Button = null
var _btn_primary: Button = null
var _btn_close_only: Button = null

func _ready() -> void:
	name = "RetieCourseModal"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.02, 0.04, 0.08, 0.78)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			close_modal(false)
			if get_viewport() != null:
				get_viewport().set_input_as_handled()

func _build_ui() -> void:
	_cc = CenterContainer.new()
	_cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cc.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_cc)

	var card := PanelContainer.new()
	card.name = "RetieCourseCard"
	card.custom_minimum_size = Vector2(860, 0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.05, 0.08, 0.14, 0.96)
	st.border_color = Color(0.18, 0.85, 0.62, 0.92)
	st.set_border_width_all(2)
	st.set_corner_radius_all(12)
	st.set_content_margin_all(22)
	card.add_theme_stylebox_override("panel", st)
	_cc.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	card.add_child(vb)

	_lbl_badge = Label.new()
	_lbl_badge.add_theme_font_size_override("font_size", 11)
	_lbl_badge.add_theme_color_override("font_color", Color(0.28, 0.92, 0.68))
	vb.add_child(_lbl_badge)

	_lbl_title = Label.new()
	_lbl_title.add_theme_font_size_override("font_size", 21)
	_lbl_title.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	vb.add_child(_lbl_title)

	# Contenedor Etapa 1: Información SST RETIE
	_info_box = VBoxContainer.new()
	_info_box.add_theme_constant_override("separation", 10)
	vb.add_child(_info_box)

	var info_panel := PanelContainer.new()
	var ip_st := StyleBoxFlat.new()
	ip_st.bg_color = Color(0.03, 0.06, 0.10, 0.88)
	ip_st.border_color = Color(0.20, 0.42, 0.60, 0.55)
	ip_st.set_border_width_all(1)
	ip_st.set_corner_radius_all(8)
	ip_st.set_content_margin_all(16)
	info_panel.add_theme_stylebox_override("panel", ip_st)
	_info_box.add_child(info_panel)

	_rtl_info = RichTextLabel.new()
	_rtl_info.bbcode_enabled = true
	_rtl_info.fit_content = true
	_rtl_info.scroll_active = false
	_rtl_info.custom_minimum_size = Vector2(780, 175)
	_rtl_info.add_theme_font_size_override("normal_font_size", 14)
	_rtl_info.add_theme_font_size_override("bold_font_size", 14)
	info_panel.add_child(_rtl_info)

	# Contenedor Etapa 2: Quiz Muy Simple (3 preguntas)
	_quiz_box = VBoxContainer.new()
	_quiz_box.visible = false
	_quiz_box.add_theme_constant_override("separation", 10)
	vb.add_child(_quiz_box)

	_quiz_cards.clear()
	for qi in range(QUIZ_QUESTIONS.size()):
		var qdata: Dictionary = QUIZ_QUESTIONS[qi]
		var qp := PanelContainer.new()
		qp.add_theme_stylebox_override("panel", ip_st.duplicate())
		_quiz_box.add_child(qp)

		var qvb := VBoxContainer.new()
		qvb.add_theme_constant_override("separation", 5)
		qp.add_child(qvb)

		var qlbl := Label.new()
		qlbl.text = qdata["q"]
		qlbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		qlbl.add_theme_font_size_override("font_size", 13)
		qlbl.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
		qvb.add_child(qlbl)

		var opt_btns: Array[Button] = []
		var opts: Array = qdata["options"]
		for oi in range(opts.size()):
			var b := Button.new()
			b.text = opts[oi]
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_font_size_override("font_size", 12)
			b.pressed.connect(_on_select_answer.bind(qi, oi))
			qvb.add_child(b)
			opt_btns.append(b)
		_quiz_cards.append({"btns": opt_btns, "panel": qp})

	_lbl_quiz_feedback = Label.new()
	_lbl_quiz_feedback.visible = false
	_lbl_quiz_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_quiz_feedback.add_theme_font_size_override("font_size", 13)
	_quiz_box.add_child(_lbl_quiz_feedback)

	# Pie de navegación
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	vb.add_child(foot)

	_btn_close_only = _make_btn("Posponer [ESC]", Color(0.18, 0.22, 0.28), Color(0.45, 0.55, 0.65), func(): close_modal(false))
	foot.add_child(_btn_close_only)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(spacer)

	_btn_prev = _make_btn("← Anterior", Color(0.10, 0.18, 0.28), Color(0.32, 0.56, 0.78), _on_prev_pressed)
	foot.add_child(_btn_prev)

	_btn_primary = _make_btn("Siguiente →", Color(0.08, 0.45, 0.34), Color(0.25, 0.95, 0.65), _on_primary_pressed)
	_btn_primary.custom_minimum_size = Vector2(280, 40)
	foot.add_child(_btn_primary)

func _make_btn(txt: String, bg: Color, border: Color, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(130, 38)
	b.add_theme_font_size_override("font_size", 13)
	_style_btn(b, bg, border)
	b.pressed.connect(cb)
	return b

func _style_btn(b: Button, bg: Color, border: Color) -> void:
	for state_name in ["normal", "hover", "pressed", "focus"]:
		var st := StyleBoxFlat.new()
		st.bg_color = bg.lightened(0.08) if state_name == "hover" else bg
		st.border_color = border
		st.set_border_width_all(1)
		st.set_corner_radius_all(7)
		st.content_margin_left = 10
		st.content_margin_right = 10
		st.content_margin_top = 6
		st.content_margin_bottom = 6
		b.add_theme_stylebox_override(state_name, st)

func open_course() -> void:
	_mode = "INFO"
	_slide_idx = 0
	_answers = [-1, -1, -1]
	_quiz_submitted = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _cc != null:
		_cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_refresh_view()
	visible = true
	if is_inside_tree():
		get_tree().paused = true
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_modal(completed: bool, score: int = 0) -> void:
	visible = false
	if is_inside_tree():
		get_tree().paused = false
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if completed:
		course_finished.emit(true, score, QUIZ_QUESTIONS.size())

func _on_prev_pressed() -> void:
	if _mode == "QUIZ" and not _quiz_submitted:
		_mode = "INFO"
		_slide_idx = INFO_SLIDES.size() - 1
	elif _mode == "INFO" and _slide_idx > 0:
		_slide_idx -= 1
	_refresh_view()

func _on_primary_pressed() -> void:
	if _mode == "INFO":
		if _slide_idx < INFO_SLIDES.size() - 1:
			_slide_idx += 1
			_refresh_view()
		else:
			_mode = "QUIZ"
			_quiz_submitted = false
			_refresh_view()
	elif _mode == "QUIZ":
		if not _quiz_submitted:
			_submit_quiz()
		else:
			var sc := _count_correct()
			if sc >= 2:
				close_modal(true, sc)
			else:
				_answers = [-1, -1, -1]
				_quiz_submitted = false
				_refresh_view()

func _on_select_answer(q_idx: int, opt_idx: int) -> void:
	if _quiz_submitted:
		return
	_answers[q_idx] = opt_idx
	_refresh_quiz_styles()

func _count_correct() -> int:
	var c := 0
	for i in range(QUIZ_QUESTIONS.size()):
		if _answers[i] == int(QUIZ_QUESTIONS[i]["correct"]):
			c += 1
	return c

func _submit_quiz() -> void:
	for a in _answers:
		if a < 0:
			_lbl_quiz_feedback.visible = true
			_lbl_quiz_feedback.text = "Por favor selecciona una respuesta en las 3 preguntas antes de validar."
			_lbl_quiz_feedback.add_theme_color_override("font_color", Color(1.0, 0.78, 0.25))
			return
	_quiz_submitted = true
	_refresh_view()

func _refresh_view() -> void:
	var is_info := (_mode == "INFO")
	_info_box.visible = is_info
	_quiz_box.visible = not is_info
	if is_info:
		var sl: Dictionary = INFO_SLIDES[_slide_idx]
		_lbl_badge.text = sl["badge"]
		_lbl_title.text = sl["title"]
		_rtl_info.text = sl["body"]
		_btn_prev.visible = (_slide_idx > 0)
		_btn_primary.text = "▸ Ir al Quiz Simple (3 Preguntas)" if _slide_idx == INFO_SLIDES.size() - 1 else "Siguiente (%d/%d) →" % [_slide_idx + 2, INFO_SLIDES.size()]
		_style_btn(_btn_primary, Color(0.08, 0.45, 0.34), Color(0.25, 0.95, 0.65))
	else:
		_lbl_badge.text = "EVALUACIÓN RÁPIDA DE INDUCCIÓN  •  SALA DE REUNIONES RETIE"
		_lbl_title.text = "Quiz Simple SST — Normatividad RETIE (3 Preguntas)"
		_btn_prev.visible = not _quiz_submitted
		_refresh_quiz_styles()
		if _quiz_submitted:
			var sc := _count_correct()
			var passed := (sc >= 2)
			_lbl_quiz_feedback.visible = true
			if passed:
				_lbl_quiz_feedback.text = "✓ ¡Curso SST RETIE Aprobado (%d/3)! Bono de +0.5 pt otorgado. Ya puedes ir a Vestidores." % sc
				_lbl_quiz_feedback.add_theme_color_override("font_color", Color(0.28, 0.95, 0.65))
				_btn_primary.text = "▶ Continuar a Vestidores EPP (Est. 2)"
				_style_btn(_btn_primary, Color(0.08, 0.48, 0.35), Color(0.28, 0.95, 0.68))
			else:
				_lbl_quiz_feedback.text = "! Obtuviste %d/3. Necesitas mínimo 2/3 respuestas correctas para certificarte." % sc
				_lbl_quiz_feedback.add_theme_color_override("font_color", Color(1.0, 0.65, 0.25))
				_btn_primary.text = "↻ Reintentar Quiz Simple"
				_style_btn(_btn_primary, Color(0.45, 0.26, 0.05), Color(0.95, 0.72, 0.22))
		else:
			_lbl_quiz_feedback.visible = false
			_btn_primary.text = "✓ Validar Respuestas del Quiz"
			_style_btn(_btn_primary, Color(0.08, 0.38, 0.56), Color(0.28, 0.80, 1.0))

func _refresh_quiz_styles() -> void:
	for qi in range(_quiz_cards.size()):
		var btns: Array = _quiz_cards[qi]["btns"]
		var chosen := _answers[qi]
		var corr := int(QUIZ_QUESTIONS[qi]["correct"])
		for oi in range(btns.size()):
			var b := btns[oi] as Button
			if _quiz_submitted:
				if oi == corr:
					_style_btn(b, Color(0.08, 0.38, 0.22), Color(0.25, 0.95, 0.62))
				elif oi == chosen and chosen != corr:
					_style_btn(b, Color(0.42, 0.10, 0.10), Color(0.95, 0.32, 0.32))
				else:
					_style_btn(b, Color(0.06, 0.09, 0.14), Color(0.20, 0.28, 0.38))
			else:
				var sel := (oi == chosen)
				_style_btn(b, Color(0.10, 0.32, 0.52) if sel else Color(0.06, 0.09, 0.14), Color(0.28, 0.80, 1.0) if sel else Color(0.22, 0.32, 0.44))
