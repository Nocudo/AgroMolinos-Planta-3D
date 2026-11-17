class_name TabletOscilloscopeChart
extends Control

## Gráfica temporal estilizada estilo Lab 3 SCADA (área degradada, malla sutil,
## curvas suavizadas + barras armónicas 1X/2X/120Hz) conservando API buf_a/b/c.

@export_enum("CURRENTS", "TEMPERATURE", "VIBRATION", "GENERIC") var chart_mode: String = "CURRENTS"
@export var chart_title: String = "Oscilograma"
@export var max_samples: int = 80

var unit_label: String = ""
var channel_legend: String = ""
var warn_line: float = -999.0
var trip_line: float = -999.0
var y_min_custom: float = -999.0
var y_max_custom: float = -999.0
var col_series_a: Color = Color(0.22, 0.74, 0.97, 1.0) # Cyan
var col_series_b: Color = Color(0.96, 0.62, 0.04, 0.95) # Amber
var col_series_c: Color = Color(0.94, 0.35, 0.42, 0.95) # Red

var buf_a: Array[float] = []
var buf_b: Array[float] = []
var buf_c: Array[float] = []

var harm_1x: float = 0.8
var harm_2x: float = 0.25
var harm_120hz: float = 0.1

func push_generic(val_a: float, val_b: float = -999.0, val_c: float = -999.0) -> void:
	buf_a.append(val_a)
	if val_b > -900.0 or not buf_b.is_empty():
		buf_b.append(val_b if val_b > -900.0 else 0.0)
	if val_c > -900.0 or not buf_c.is_empty():
		buf_c.append(val_c if val_c > -900.0 else 0.0)
	_trim_buffers()
	queue_redraw()

func push_currents(ia: float, ib: float, ic: float) -> void:
	buf_a.append(ia)
	buf_b.append(ib)
	buf_c.append(ic)
	_trim_buffers()
	queue_redraw()

func push_temperature(temp_c: float) -> void:
	buf_a.append(temp_c)
	_trim_buffers()
	queue_redraw()

func push_vibration(vib_rms: float, is_120hz_fault: bool = false, is_mech_fault: bool = false) -> void:
	buf_a.append(vib_rms)
	if is_mech_fault:
		harm_1x = vib_rms * 0.72
		harm_2x = vib_rms * 0.54
		harm_120hz = vib_rms * 0.12
	elif is_120hz_fault:
		harm_1x = vib_rms * 0.22
		harm_2x = vib_rms * 0.18
		harm_120hz = vib_rms * 0.85
	else:
		harm_1x = vib_rms * 0.65
		harm_2x = vib_rms * 0.20
		harm_120hz = vib_rms * 0.08
	_trim_buffers()
	queue_redraw()

func clear_buffers() -> void:
	buf_a.clear()
	buf_b.clear()
	buf_c.clear()
	queue_redraw()

func _trim_buffers() -> void:
	while buf_a.size() > max_samples:
		buf_a.pop_front()
	while buf_b.size() > max_samples:
		buf_b.pop_front()
	while buf_c.size() > max_samples:
		buf_c.pop_front()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 30.0 or h < 30.0:
		return

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.043, 0.067, 0.118, 1.0), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.118, 0.173, 0.275, 1.0), false, 1.0)

	var plot_rect := Rect2(42.0, 24.0, w - 54.0, h - 38.0)
	if chart_mode == "VIBRATION":
		plot_rect.size.x = maxf(60.0, (w - 64.0) * 0.64)

	for i in range(0, 5):
		var gy: float = plot_rect.position.y + (plot_rect.size.y * float(i) / 4.0)
		draw_line(Vector2(plot_rect.position.x, gy), Vector2(plot_rect.end.x, gy), Color(0.16, 0.23, 0.35, 0.55), 1.0)
	for i in range(0, 6):
		var gx: float = plot_rect.position.x + (plot_rect.size.x * float(i) / 5.0)
		draw_line(Vector2(gx, plot_rect.position.y), Vector2(gx, plot_rect.end.y), Color(0.16, 0.23, 0.35, 0.38), 1.0)

	var font: Font = ThemeDB.fallback_font
	if font != null:
		draw_string(font, Vector2(10.0, 16.0), chart_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.76, 0.88, 0.98, 0.96))

	if chart_mode == "CURRENTS":
		var peak_val: float = 28.0
		for v in buf_a: peak_val = maxf(peak_val, v * 1.15)
		for v in buf_b: peak_val = maxf(peak_val, v * 1.15)
		for v in buf_c: peak_val = maxf(peak_val, v * 1.15)
		_draw_y_ticks(font, plot_rect, 0.0, peak_val, "A")
		var y_fla: float = _map_y(13.5, 0.0, peak_val, plot_rect)
		draw_line(Vector2(plot_rect.position.x, y_fla), Vector2(plot_rect.end.x, y_fla), Color(0.06, 0.73, 0.51, 0.55), 1.0)
		_draw_filled_series(buf_a, 0.0, peak_val, plot_rect, Color(0.22, 0.74, 0.97, 1.0), Color(0.22, 0.74, 0.97, 0.14))
		_draw_series(buf_b, 0.0, peak_val, plot_rect, Color(0.96, 0.62, 0.04, 0.95))
		_draw_series(buf_c, 0.0, peak_val, plot_rect, Color(0.94, 0.35, 0.42, 0.95))
		if font != null:
			draw_string(font, Vector2(0.0, 16.0), "L1(Cyan) L2(Ámbar) L3(Rojo)", HORIZONTAL_ALIGNMENT_RIGHT, w - 10.0, 10, Color(0.75, 0.85, 0.95, 0.9))

	elif chart_mode == "TEMPERATURE":
		var t_min: float = 20.0
		var t_max: float = 160.0
		_draw_y_ticks(font, plot_rect, t_min, t_max, "°C")
		draw_line(Vector2(plot_rect.position.x, _map_y(85.0, t_min, t_max, plot_rect)), Vector2(plot_rect.end.x, _map_y(85.0, t_min, t_max, plot_rect)), Color(0.96, 0.62, 0.04, 0.65), 1.0)
		draw_line(Vector2(plot_rect.position.x, _map_y(105.0, t_min, t_max, plot_rect)), Vector2(plot_rect.end.x, _map_y(105.0, t_min, t_max, plot_rect)), Color(0.94, 0.27, 0.27, 0.75), 1.0)
		_draw_filled_series(buf_a, t_min, t_max, plot_rect, Color(0.96, 0.48, 0.26, 1.0), Color(0.96, 0.48, 0.26, 0.16))
		if font != null:
			draw_string(font, Vector2(0.0, 16.0), "85°C Alerta · 105°C Disparo", HORIZONTAL_ALIGNMENT_RIGHT, w - 10.0, 10, Color(0.96, 0.72, 0.35, 0.95))

	elif chart_mode == "VIBRATION":
		var v_max: float = 8.0
		for v in buf_a: v_max = maxf(v_max, v * 1.15)
		_draw_y_ticks(font, plot_rect, 0.0, v_max, "")
		draw_line(Vector2(plot_rect.position.x, _map_y(2.3, 0.0, v_max, plot_rect)), Vector2(plot_rect.end.x, _map_y(2.3, 0.0, v_max, plot_rect)), Color(0.96, 0.62, 0.04, 0.6), 1.0)
		draw_line(Vector2(plot_rect.position.x, _map_y(4.5, 0.0, v_max, plot_rect)), Vector2(plot_rect.end.x, _map_y(4.5, 0.0, v_max, plot_rect)), Color(0.94, 0.27, 0.27, 0.75), 1.0)
		_draw_filled_series(buf_a, 0.0, v_max, plot_rect, Color(0.06, 0.73, 0.51, 1.0), Color(0.06, 0.73, 0.51, 0.16))
		_draw_harmonic_bars(plot_rect, w, font)

	else:
		var y_min: float = y_min_custom if y_min_custom > -900.0 else 0.0
		var y_max: float = y_max_custom if y_max_custom > -900.0 else 1.0
		if y_max_custom <= -900.0:
			for v in buf_a: y_max = maxf(y_max, v * 1.15)
			for v in buf_b: y_max = maxf(y_max, v * 1.15)
			for v in buf_c: y_max = maxf(y_max, v * 1.15)
			if y_max <= y_min:
				y_max = y_min + 1.0
		_draw_y_ticks(font, plot_rect, y_min, y_max, unit_label)
		if warn_line > -900.0 and warn_line >= y_min and warn_line <= y_max:
			var wy: float = _map_y(warn_line, y_min, y_max, plot_rect)
			draw_line(Vector2(plot_rect.position.x, wy), Vector2(plot_rect.end.x, wy), Color(0.96, 0.62, 0.04, 0.65), 1.0)
		if trip_line > -900.0 and trip_line >= y_min and trip_line <= y_max:
			var ty: float = _map_y(trip_line, y_min, y_max, plot_rect)
			draw_line(Vector2(plot_rect.position.x, ty), Vector2(plot_rect.end.x, ty), Color(0.94, 0.27, 0.27, 0.75), 1.0)
		var fill_a := Color(col_series_a.r, col_series_a.g, col_series_a.b, 0.14)
		_draw_filled_series(buf_a, y_min, y_max, plot_rect, col_series_a, fill_a)
		if not buf_b.is_empty():
			_draw_series(buf_b, y_min, y_max, plot_rect, col_series_b)
		if not buf_c.is_empty():
			_draw_series(buf_c, y_min, y_max, plot_rect, col_series_c)
		if font != null and channel_legend != "":
			draw_string(font, Vector2(0.0, 16.0), channel_legend, HORIZONTAL_ALIGNMENT_RIGHT, w - 10.0, 10, Color(0.75, 0.85, 0.95, 0.9))

func _draw_y_ticks(font: Font, rect: Rect2, min_v: float, max_v: float, unit: String) -> void:
	if font == null:
		return
	for step in range(3):
		var frac: float = float(step) / 2.0
		var v: float = lerpf(max_v, min_v, frac)
		var y: float = rect.position.y + rect.size.y * frac + 4.0
		draw_string(font, Vector2(4.0, y), "%.0f%s" % [v, unit], HORIZONTAL_ALIGNMENT_LEFT, 36.0, 9, Color(0.58, 0.64, 0.72, 0.85))

func _draw_harmonic_bars(plot_rect: Rect2, w: float, font: Font) -> void:
	var bar_zone_x: float = plot_rect.end.x + 12.0
	var bar_zone_w: float = maxf(40.0, w - bar_zone_x - 10.0)
	var labels := ["1X", "2X", "120Hz"]
	var vals := [harm_1x, harm_2x, harm_120hz]
	var cols := [Color(0.22, 0.74, 0.97, 0.95), Color(0.96, 0.62, 0.04, 0.95), Color(0.94, 0.27, 0.27, 0.95)]
	var bw: float = (bar_zone_w - 16.0) / 3.0
	var bar_max_h: float = plot_rect.size.y - 12.0
	for i in range(3):
		var bh: float = clampf((vals[i] / 5.0) * bar_max_h, 3.0, bar_max_h)
		var bx: float = bar_zone_x + float(i) * (bw + 6.0)
		var by: float = plot_rect.end.y - bh
		draw_rect(Rect2(bx, by, bw, bh), cols[i], true)
		if font != null:
			draw_string(font, Vector2(bx, plot_rect.end.y + 11.0), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.75, 0.85, 0.95, 0.9))

func _map_y(val: float, min_v: float, max_v: float, rect: Rect2) -> float:
	var norm: float = clampf((val - min_v) / maxf(0.001, max_v - min_v), 0.0, 1.0)
	return rect.end.y - norm * rect.size.y

func _draw_filled_series(series: Array[float], min_v: float, max_v: float, rect: Rect2, line_col: Color, fill_col: Color) -> void:
	if series.size() < 2:
		return
	var pts := PackedVector2Array()
	var poly := PackedVector2Array()
	var count: int = series.size()
	for i in range(count):
		var px: float = rect.position.x + (float(i) / float(max(1, max_samples - 1))) * rect.size.x
		var py: float = _map_y(series[i], min_v, max_v, rect)
		pts.append(Vector2(px, py))
		poly.append(Vector2(px, py))
	poly.append(Vector2(pts[pts.size() - 1].x, rect.end.y))
	poly.append(Vector2(pts[0].x, rect.end.y))
	draw_colored_polygon(poly, fill_col)
	draw_polyline(pts, line_col, 2.0, true)

func _draw_series(series: Array[float], min_v: float, max_v: float, rect: Rect2, col: Color) -> void:
	if series.size() < 2:
		return
	var pts := PackedVector2Array()
	var count: int = series.size()
	for i in range(count):
		var px: float = rect.position.x + (float(i) / float(max(1, max_samples - 1))) * rect.size.x
		var py: float = _map_y(series[i], min_v, max_v, rect)
		pts.append(Vector2(px, py))
	draw_polyline(pts, col, 2.0, true)
