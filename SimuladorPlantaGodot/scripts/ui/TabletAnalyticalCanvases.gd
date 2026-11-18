class_name TabletAnalyticalCanvases
extends RefCounted

## Lienzos científicos vectoriales nativos estilo Lab 3 para Fisiología IEC 60479-1
## y Diagrama de Arquitectura Hardware / Potencia 460V de AgroMolinos.

class IEC60479ChartCanvas extends Control:
	var current_ma: float = 25.0
	var duration_ms: float = 500.0

	func set_operating_point(ma: float, ms: float) -> void:
		current_ma = clampf(ma, 0.1, 1000.0)
		duration_ms = clampf(ms, 10.0, 5000.0)
		queue_redraw()

	func _map_log_x(ma: float, rect: Rect2) -> float:
		var lmin := log(0.1) / log(10.0)
		var lmax := log(1000.0) / log(10.0)
		var lv := log(clampf(ma, 0.1, 1000.0)) / log(10.0)
		return rect.position.x + ((lv - lmin) / (lmax - lmin)) * rect.size.x

	func _map_log_y(ms: float, rect: Rect2) -> float:
		var lmin := log(10.0) / log(10.0)
		var lmax := log(5000.0) / log(10.0)
		var lv := log(clampf(ms, 10.0, 5000.0)) / log(10.0)
		return rect.end.y - ((lv - lmin) / (lmax - lmin)) * rect.size.y

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w < 40.0 or h < 40.0:
			return
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.043, 0.067, 0.118, 1.0), true)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.118, 0.173, 0.275, 1.0), false, 1.0)

		var rect := Rect2(54.0, 26.0, w - 72.0, h - 58.0)
		var font := ThemeDB.fallback_font
		for tick_ma in [0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0]:
			var gx := _map_log_x(tick_ma, rect)
			draw_line(Vector2(gx, rect.position.y), Vector2(gx, rect.end.y), Color(0.16, 0.23, 0.35, 0.45), 1.0)
			if font != null:
				var tick_str := str(tick_ma) if tick_ma < 1.0 else str(int(tick_ma))
				draw_string(font, Vector2(gx - 12.0, rect.end.y + 13.0), tick_str, HORIZONTAL_ALIGNMENT_LEFT, 36.0, 9, Color(0.58, 0.64, 0.72))
		for tick_ms in [10.0, 50.0, 100.0, 500.0, 1000.0, 2000.0, 5000.0]:
			var gy := _map_log_y(tick_ms, rect)
			draw_line(Vector2(rect.position.x, gy), Vector2(rect.end.x, gy), Color(0.16, 0.23, 0.35, 0.45), 1.0)
			if font != null:
				draw_string(font, Vector2(6.0, gy + 4.0), "%dms" % int(tick_ms), HORIZONTAL_ALIGNMENT_LEFT, 44.0, 9, Color(0.58, 0.64, 0.72))

		# Curva a (0.5 mA percepción)
		draw_line(Vector2(_map_log_x(0.5, rect), rect.position.y), Vector2(_map_log_x(0.5, rect), rect.end.y), Color(0.06, 0.73, 0.51, 0.9), 2.0)

		# Curvas normalizadas IEC 60479-1: b (soltar), c1 (inicio fibrilación), c2 (50% fibrilación)
		_draw_iec_curve(rect, [[10.0, 5000.0], [10.0, 1000.0], [15.0, 500.0], [30.0, 200.0], [50.0, 100.0], [100.0, 30.0], [160.0, 10.0]], Color(0.96, 0.62, 0.04, 0.95))
		_draw_iec_curve(rect, [[34.0, 5000.0], [38.0, 1000.0], [50.0, 500.0], [100.0, 300.0], [200.0, 150.0], [380.0, 40.0], [450.0, 10.0]], Color(0.94, 0.27, 0.27, 0.95))
		_draw_iec_curve(rect, [[46.0, 5000.0], [52.0, 1000.0], [80.0, 500.0], [200.0, 250.0], [450.0, 120.0], [720.0, 20.0], [820.0, 10.0]], Color(0.85, 0.20, 0.45, 0.85))

		# Punto operativo (I, t)
		var px := _map_log_x(current_ma, rect)
		var py := _map_log_y(duration_ms, rect)
		draw_circle(Vector2(px, py), 8.0, Color(0.22, 0.74, 0.97, 0.28))
		draw_circle(Vector2(px, py), 5.0, Color(0.22, 0.74, 0.97, 1.0))
		draw_arc(Vector2(px, py), 5.5, 0.0, TAU, 20, Color.WHITE, 1.5, true)

		if font != null:
			draw_string(font, Vector2(rect.position.x, 16.0), "Curva Tiempo-Corriente IEC 60479-1 (Escala Logarítmica)   —   a(Verde)  b(Ámbar)  c1(Rojo)  c2(Fibrilación)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.82, 0.90, 0.98))
			draw_string(font, Vector2(rect.position.x + rect.size.x * 0.32, h - 3.0), "Corriente Corporal I (mA)", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.62, 0.72, 0.82))

	func _draw_iec_curve(rect: Rect2, pts_data: Array, col: Color) -> void:
		var pts := PackedVector2Array()
		for p in pts_data:
			pts.append(Vector2(_map_log_x(float(p[0]), rect), _map_log_y(float(p[1]), rect)))
		draw_polyline(pts, col, 2.0, true)

class HardwareArchitectureCanvas extends Control:
	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w < 120.0 or h < 90.0:
			return
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.055, 0.095, 1.0), true)

		var font := ThemeDB.fallback_font
		var pad_x := 8.0
		var gap_mid := 18.0
		var panel_w := (w - pad_x * 2.0 - gap_mid) * 0.5
		var box_left := Rect2(pad_x, 6.0, panel_w, h - 12.0)
		var box_right := Rect2(pad_x + panel_w + gap_mid, 6.0, panel_w, h - 12.0)

		draw_rect(box_left, Color(0.05, 0.09, 0.16, 0.88), true)
		draw_rect(box_left, Color(0.14, 0.42, 0.72, 0.85), false, 1.4)
		draw_rect(box_right, Color(0.09, 0.05, 0.08, 0.82), true)
		draw_rect(box_right, Color(0.68, 0.22, 0.26, 0.85), false, 1.4)

		# Encabezados con separación amplia del área de bloques (nunca cruzados por líneas)
		var header_h := 28.0
		draw_line(
			Vector2(box_left.position.x + 8.0, box_left.position.y + header_h),
			Vector2(box_left.end.x - 8.0, box_left.position.y + header_h),
			Color(0.14, 0.42, 0.72, 0.35), 1.0
		)
		draw_line(
			Vector2(box_right.position.x + 8.0, box_right.position.y + header_h),
			Vector2(box_right.end.x - 8.0, box_right.position.y + header_h),
			Color(0.68, 0.22, 0.26, 0.35), 1.0
		)
		if font != null:
			draw_string(font, Vector2(box_left.position.x + 12.0, box_left.position.y + 19.0), "ETAPA CONTROL & EDGE AI (3.3 V / 5 V DC · CloudIoTBridge)", HORIZONTAL_ALIGNMENT_LEFT, panel_w - 20.0, 11, Color(0.28, 0.78, 1.0))
			draw_string(font, Vector2(box_right.position.x + 12.0, box_right.position.y + 19.0), "ETAPA POTENCIA TRIFÁSICA (460 V AC · MOLINO M-101 10 HP)", HORIZONTAL_ALIGNMENT_LEFT, panel_w - 20.0, 11, Color(0.98, 0.44, 0.44))

		# Área útil interior verticalmente proporcional
		var top_y := box_left.position.y + header_h + 14.0
		var bot_y := box_left.end.y - 14.0
		var avail_h := maxf(110.0, bot_y - top_y)
		var inner_pad := 14.0
		var col_gap := 24.0
		var inner_w := panel_w - inner_pad * 2.0
		var col_w := (inner_w - col_gap * 2.0) / 3.0

		# ---------------- PANEL IZQUIERDO: SENSORES -> ESP32/IA -> ACTUADORES ----------------
		var lx1 := box_left.position.x + inner_pad
		var lx2 := lx1 + col_w + col_gap
		var lx3 := lx2 + col_w + col_gap

		var sensor_gap := 12.0
		var sensor_h := (avail_h - sensor_gap * 2.0) / 3.0
		var sy0 := top_y
		var sy1 := sy0 + sensor_h + sensor_gap
		var sy2 := sy1 + sensor_h + sensor_gap

		_draw_block(lx1, sy0, col_w, sensor_h, Color(0.96, 0.62, 0.04), "Pinza Hall\nI_A/B/C · V_LL", font)
		_draw_block(lx1, sy1, col_w, sensor_h, Color(0.94, 0.35, 0.35), "Termocupla PT100\nTw / Tc", font)
		_draw_block(lx1, sy2, col_w, sensor_h, Color(0.22, 0.74, 0.97), "Vib. Triaxial\n+ Tacómetro RPM", font)

		var core_h := avail_h * 0.78
		var core_y := top_y + (avail_h - core_h) * 0.5
		_draw_block(lx2, core_y, col_w, core_h, Color(0.22, 0.74, 0.97), "ESP32 / Edge AI\nMLP 8-16-8-4\nSVM RBF\nBridge 10Hz / 2Hz", font)

		var act_gap := 16.0
		var act_h := (avail_h - act_gap) * 0.44
		var ay0 := top_y + (avail_h - (act_h * 2.0 + act_gap)) * 0.5
		var ay1 := ay0 + act_h + act_gap
		_draw_block(lx3, ay0, col_w, act_h, Color(0.06, 0.73, 0.51), "Relé Disparo\nControl VFD", font)
		_draw_block(lx3, ay1, col_w, act_h, Color(0.94, 0.27, 0.27), "E-STOP Cat 0\n+ Bloqueo LOTO", font)

		# Conexiones limpias Sensores -> ESP32 -> Actuadores
		for s_mid_y in [sy0 + sensor_h * 0.5, sy1 + sensor_h * 0.5, sy2 + sensor_h * 0.5]:
			_draw_arrow(Vector2(lx1 + col_w, s_mid_y), Vector2(lx2, clampf(s_mid_y, core_y + 10.0, core_y + core_h - 10.0)), Color(0.55, 0.78, 0.98), 1.6)
		_draw_arrow(Vector2(lx2 + col_w, ay0 + act_h * 0.5), Vector2(lx3, ay0 + act_h * 0.5), Color(0.06, 0.78, 0.55), 1.8)
		_draw_arrow(Vector2(lx2 + col_w, ay1 + act_h * 0.5), Vector2(lx3, ay1 + act_h * 0.5), Color(0.95, 0.32, 0.32), 1.8)

		# ---------------- PANEL DERECHO: RED 460V -> CCM -> VFD/DOL -> MOTOR ----------------
		var rx1 := box_right.position.x + inner_pad
		var rx2 := rx1 + col_w + col_gap
		var rx3 := rx2 + col_w + col_gap

		var row_gap := 24.0
		var row1_h := (avail_h - row_gap) * 0.46
		var row2_h := (avail_h - row_gap) * 0.48
		var ry1 := top_y + 4.0
		var ry2 := ry1 + row1_h + row_gap

		_draw_block(rx1, ry1, col_w, row1_h, Color(0.96, 0.62, 0.04), "Red Trifásica\n460 V · 60 Hz", font)
		_draw_block(rx2, ry1, col_w, row1_h, Color(0.62, 0.70, 0.80), "CCM Breakers\nL1 · L2 · L3", font)
		_draw_block(rx3, ry1, col_w, row1_h, Color(0.06, 0.73, 0.51), "Variador VFD\n/ Arranque DOL", font)

		var r1_mid := ry1 + row1_h * 0.5
		_draw_arrow(Vector2(rx1 + col_w, r1_mid), Vector2(rx2, r1_mid), Color(0.95, 0.42, 0.35), 2.0)
		_draw_arrow(Vector2(rx2 + col_w, r1_mid), Vector2(rx3, r1_mid), Color(0.95, 0.42, 0.35), 2.0)

		var motor_w := col_w * 1.62
		var motor_x := rx2 - col_w * 0.16
		_draw_block(motor_x, ry2, motor_w, row2_h, Color(0.22, 0.74, 0.97), "MOTOR IE3 10 HP · M-101\n1750 RPM · Molino de Granos", font)
		_draw_block(rx1, ry2, col_w * 0.76, row2_h, Color(0.10, 0.78, 0.52), "Tierra PE\n< 10 Ω RETIE", font)

		# Potencia VFD/DOL -> Motor (baja por la derecha y entra limpio al costado derecho del motor)
		var r2_mid := ry2 + row2_h * 0.5
		var vfd_cx := rx3 + col_w * 0.5
		draw_line(Vector2(vfd_cx, ry1 + row1_h), Vector2(vfd_cx, r2_mid), Color(0.95, 0.42, 0.35), 2.0)
		_draw_arrow(Vector2(vfd_cx, r2_mid), Vector2(motor_x + motor_w, r2_mid), Color(0.95, 0.42, 0.35), 2.0)
		# Puesta a tierra Motor -> Tierra PE
		draw_line(Vector2(motor_x, r2_mid), Vector2(rx1 + col_w * 0.76, r2_mid), Color(0.10, 0.78, 0.52), 1.8)

		# Puente de señal verde Control VFD -> Variador VFD (por corredor intermedio limpio sin cruzar ningún título ni caja)
		var bridge_y := ry1 + row1_h + row_gap * 0.5
		var p_start := Vector2(lx3 + col_w, ay0 + act_h * 0.5)
		var mid_x := box_left.end.x + gap_mid * 0.5
		var vfd_in_x := rx3 + col_w * 0.25
		var wire_pts := PackedVector2Array([
			p_start,
			Vector2(mid_x, p_start.y),
			Vector2(mid_x, bridge_y),
			Vector2(vfd_in_x, bridge_y),
			Vector2(vfd_in_x, ry1 + row1_h + 2.0)
		])
		draw_polyline(wire_pts, Color(0.06, 0.80, 0.55, 0.92), 1.8, true)
		_draw_arrow(Vector2(vfd_in_x, bridge_y), Vector2(vfd_in_x, ry1 + row1_h), Color(0.06, 0.80, 0.55, 0.95), 1.8)

	func _draw_arrow(p0: Vector2, p1: Vector2, col: Color, width: float) -> void:
		draw_line(p0, p1, col, width, true)
		var d := (p1 - p0)
		if d.length() < 4.0:
			return
		var u := d.normalized()
		var n := Vector2(-u.y, u.x)
		var tip := p1
		var head := PackedVector2Array([tip, tip - u * 6.5 + n * 3.4, tip - u * 6.5 - n * 3.4])
		draw_colored_polygon(head, col)

	func _draw_block(x: float, y: float, bw: float, bh: float, border: Color, txt: String, font: Font) -> void:
		draw_rect(Rect2(x, y, bw, bh), Color(0.075, 0.114, 0.196, 1.0), true)
		draw_rect(Rect2(x, y, bw, bh), border, false, 1.5)
		if font == null:
			return
		var lines := txt.split("\n")
		var line_h := 13.5
		var total_h := float(lines.size()) * line_h
		var start_y := y + (bh - total_h) * 0.5 + 10.5
		for idx in range(lines.size()):
			var ly := start_y + float(idx) * line_h
			var col := Color(0.95, 0.97, 1.0) if idx == 0 else Color(0.76, 0.84, 0.94)
			draw_string(font, Vector2(x + 8.0, ly), lines[idx], HORIZONTAL_ALIGNMENT_LEFT, bw - 14.0, 10, col)
