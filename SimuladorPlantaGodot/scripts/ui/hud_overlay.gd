extends Control

@onready var label_fps: Label = %LabelFPS
@onready var label_pos: Label = %LabelPos
@onready var label_speed: Label = %LabelSpeed
@onready var camera: Camera3D = $"../../FreeLookCamera"
@onready var panel_help: PanelContainer = %PanelHelp

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if label_fps:
		label_fps.text = "FPS: %d" % Engine.get_frames_per_second()
	if label_pos and camera:
		label_pos.text = "Posición Cámara: (%.1f, %.1f, %.1f)" % [camera.position.x, camera.position.y, camera.position.z]
	if label_speed and camera:
		label_speed.text = "Velocidad Base: %.0f m/s (Shift: Sprint x3)" % camera.default_speed

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_H:
			if panel_help:
				panel_help.visible = not panel_help.visible

func _on_btn_reset_pressed() -> void:
	if camera:
		camera.reset_view()

func _on_btn_help_pressed() -> void:
	if panel_help:
		panel_help.visible = not panel_help.visible
