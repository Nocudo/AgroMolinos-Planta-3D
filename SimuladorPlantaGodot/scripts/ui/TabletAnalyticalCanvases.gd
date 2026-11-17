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
		if w < 100.0 or h < 60.0:
			return
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.055, 0.095, 1.0), true)

		var font := ThemeDB.fallback_font
		var mid := w * 0.50
		var box_left := Rect2(8.0, 6.0, mid - 14.0, h - 12.0)
		var box_right := Rect2(mid + 6.0, 6.0, mid - 14.0, h - 12.0)
		draw_rect(box_left, Color(0.05, 0.09, 0.16, 0.85), true)
		draw_rect(box_left, Color(0.14, 0.42, 0.72, 0.8), false, 1.2)
		draw_rect(box_right, Color(0.09, 0.05, 0.08, 0.75), true)
		draw_rect(box_right, Color(0.68, 0.22, 0.26, 0.8), false, 1.2)

		if font != null:
			draw_string(font, Vector2(box_left.position.x + 10, 22), "ETAPA CONTROL & EDGE AI (3.3 V / 5 V DC · CloudIoTBridge)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.22, 0.74, 0.97))
			draw_string(font, Vector2(box_right.position.x + 10, 22), "ETAPA POTENCIA TRIFÁSICA (460 V AC · MOLINO M-101 10 HP)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.95, 0.42, 0.42))

		var sx: float = clampf(box_left.size.x / 540.0, 0.72, 1.15)
		# Cajas izquierda: Sensores -> Nodo IoT/ESP32 -> Actuador/IA
		_draw_block(box_left.position.x + 12 * sx, 34, 152 * sx, 32, Color(0.96, 0.62, 0.04), "Pinza Hall I_A/B/C · V_LL", font)
		_draw_block(box_left.position.x + 12 * sx, 72, 152 * sx, 32, Color(0.94, 0.35, 0.35), "Termocupla PT100 Tw/Tc", font)
		_draw_block(box_left.position.x + 12 * sx, 110, 152 * sx, 32, Color(0.22, 0.74, 0.97), "Vib. Triaxial + RPM", font)
		_draw_block(box_left.position.x + 196 * sx, 42, 152 * sx, 92, Color(0.22, 0.74, 0.97), "ESP32 / Edge AI\nMLP 8-16-8-4 + SVM\nBridge 10Hz / 2Hz", font)
		_draw_block(box_left.position.x + 380 * sx, 42, 142 * sx, 42, Color(0.06, 0.73, 0.51), "Relé Disparo / VFD", font)
		_draw_block(box_left.position.x + 380 * sx, 92, 142 * sx, 42, Color(0.94, 0.27, 0.27), "E-STOP Cat 0 + LOTO", font)

		for y_c in [50.0, 88.0, 126.0]:
			draw_line(Vector2(box_left.position.x + 164 * sx, y_c), Vector2(box_left.position.x + 196 * sx, y_c), Color(0.55, 0.75, 0.95), 1.5)
		draw_line(Vector2(box_left.position.x + 348 * sx, 63), Vector2(box_left.position.x + 380 * sx, 63), Color(0.06, 0.73, 0.51), 1.5)
		draw_line(Vector2(box_left.position.x + 348 * sx, 113), Vector2(box_left.position.x + 380 * sx, 113), Color(0.94, 0.27, 0.27), 1.5)

		# Cajas derecha: Red 460V -> CCM Breakers -> VFD/DOL -> Motor 10HP -> PE < 10 Ohm
		_draw_block(box_right.position.x + 14 * sx, 40, 136 * sx, 38, Color(0.96, 0.62, 0.04), "Red 460 V · 60 Hz", font)
		_draw_block(box_right.position.x + 178 * sx, 40, 142 * sx, 38, Color(0.58, 0.64, 0.72), "CCM Breakers L1-L3", font)
		_draw_block(box_right.position.x + 348 * sx, 40, 174 * sx, 38, Color(0.06, 0.73, 0.51), "Variador VFD / DOL", font)
		draw_line(Vector2(box_right.position.x + 150 * sx, 59), Vector2(box_right.position.x + 178 * sx, 59), Color(0.94, 0.35, 0.35), 2.0)
		draw_line(Vector2(box_right.position.x + 320 * sx, 59), Vector2(box_right.position.x + 348 * sx, 59), Color(0.94, 0.35, 0.35), 2.0)

		_draw_block(box_right.position.x + 185 * sx, 100, 195 * sx, 44, Color(0.22, 0.74, 0.97), "MOTOR IE3 10 HP · M-101\n1750 RPM · Tierra PE < 10 Ω", font)
		draw_line(Vector2(box_right.position.x + 435 * sx, 78), Vector2(box_right.position.x + 435 * sx, 122), Color(0.94, 0.35, 0.35), 2.0)
		draw_line(Vector2(box_right.position.x + 435 * sx, 122), Vector2(box_right.position.x + 380 * sx, 122), Color(0.94, 0.35, 0.35), 2.0)
		var wire_pts := PackedVector2Array([
			Vector2(box_left.position.x + 451 * sx, 42.0),
			Vector2(box_left.position.x + 451 * sx, 29.0),
			Vector2(box_right.position.x + 435 * sx, 29.0),
			Vector2(box_right.position.x + 435 * sx, 40.0)
		])
		draw_polyline(wire_pts, Color(0.06, 0.73, 0.51, 0.85), 1.5, true)

	func _draw_block(x: float, y: float, bw: float, bh: float, border: Color, txt: String, font: Font) -> void:
		draw_rect(Rect2(x, y, bw, bh), Color(0.075, 0.114, 0.196, 1.0), true)
		draw_rect(Rect2(x, y, bw, bh), border, false, 1.5)
		if font == null:
			return
		var lines := txt.split("\n")
		for idx in range(lines.size()):
			var ly := y + 15.0 + float(idx) * 14.0
			draw_string(font, Vector2(x + 8.0, ly), lines[idx], HORIZONTAL_ALIGNMENT_LEFT, bw - 14.0, 10, Color(0.92, 0.95, 0.99))
