class_name CloudIoTBridge
extends Node

# ==============================================================================
# PUENTE IOT EN LA NUBE - TRANSMISIÓN DE TELEMETRÍA Y RECEPCIÓN DE ANALÍTICA IA
# Conecta el gemelo digital en Godot con el servidor Python FastAPI en localhost:8000
# ==============================================================================

@export var cloud_url: String = "http://127.0.0.1:8000/api/v1/telemetry"
@export var dispatch_frequency_hz: float = 2.0

var http_request: HTTPRequest
var timer: Timer
var latest_packet: Dictionary = {}
var is_request_in_flight: bool = false

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

	timer = Timer.new()
	timer.wait_time = 1.0 / dispatch_frequency_hz
	timer.timeout.connect(_send_telemetry_to_cloud)
	add_child(timer)
	timer.start()

	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.telemetry_updated.connect(_on_telemetry_updated)

func _on_telemetry_updated(
	rpm: float,
	cur_a: float,
	cur_b: float,
	cur_c: float,
	volt: float,
	freq: float,
	temp: float,
	vib: float,
	p_kw: float,
	pf: float,
	flow: float
) -> void:
	latest_packet = {
		"timestamp": Time.get_unix_time_from_system(),
		"asset_id": "M-101-HAMMERMILL",
		"rpm": rpm,
		"current_a": cur_a,
		"current_b": cur_b,
		"current_c": cur_c,
		"voltage": volt,
		"freq_hz": freq,
		"temp_c": temp,
		"vibration_rms": vib,
		"power_kw": p_kw,
		"power_factor": pf,
		"flow_kg_s": flow
	}

func _send_telemetry_to_cloud() -> void:
	if is_request_in_flight or latest_packet.is_empty():
		return

	is_request_in_flight = true
	var json_body = JSON.stringify(latest_packet)
	var headers = PackedStringArray(["Content-Type: application/json"])
	var err = http_request.request(cloud_url, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		is_request_in_flight = false

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	is_request_in_flight = false
	if response_code == 200:
		var response_str = body.get_string_from_utf8()
		var parsed = JSON.parse_string(response_str)
		if parsed is Dictionary and parsed.has("ai_alert"):
			var bus = get_node_or_null("/root/EventBus")
			if bus != null:
				bus.ai_alert_received.emit(parsed["ai_alert"])
