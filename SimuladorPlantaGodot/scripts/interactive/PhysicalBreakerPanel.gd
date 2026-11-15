class_name PhysicalBreakerPanel
extends Node3D

# ==============================================================================
# GABINETE CCM 460 V: PALANCAS DE BREAKERS Y VOLTAGE SAGS FÍSICOS
# ==============================================================================

@onready var door_pivot: Node3D = $DoorPivot
@onready var lever_l1: Node3D = $BreakerL1/LeverPivot
@onready var lever_l2: Node3D = $BreakerL2/LeverPivot
@onready var lever_l3: Node3D = $BreakerL3/LeverPivot
@onready var audio_click: AudioStreamPlayer3D = $AudioClick
@onready var interactable_area: Area3D = $InteractableArea

var is_door_open: bool = false
var l1_active: bool = true
var l2_active: bool = true
var l3_active: bool = true

func _ready() -> void:
	if interactable_area != null:
		interactable_area.add_to_group("interactable")

func interact(_tool_id: int) -> String:
	if not is_door_open:
		toggle_door()
		return "Has abierto la puerta del gabinete CCM 460 V. Breakers accesibles en riel DIN."
	else:
		# Mover breaker L3 para provocar bajón de tensión / desbalance
		toggle_breaker_l3()
		if not l3_active:
			return "Has accionado la palanca del breaker L3 a posición OFF. ¡Bajón de tensión a 340 V inducido!"
		else:
			return "Has rearmado el breaker L3 a posición ON. Tensión nominal 460 V restablecida."

func toggle_door() -> void:
	is_door_open = not is_door_open
	if audio_click != null:
		audio_click.play()
	if door_pivot != null:
		var target_angle: float = deg_to_rad(105.0) if is_door_open else 0.0
		var t = create_tween()
		t.tween_property(door_pivot, "rotation:y", target_angle, 0.4).set_trans(Tween.TRANS_QUAD)

func toggle_breaker_l3() -> void:
	l3_active = not l3_active
	if audio_click != null:
		audio_click.play()
	_animate_lever(lever_l3, l3_active)
	
	var bus = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.breaker_changed.emit("Breaker_L3", l3_active)
		if not l3_active:
			bus.notification_posted.emit(
				"BAJÓN DE TENSIÓN EN GABINETE CCM",
				"Breaker L3 abierto/falseado. Tensión de red cae a 340 V con pérdida cuadrática de par.",
				"error"
			)
		else:
			bus.notification_posted.emit(
				"BREAKER CCM REARMADO",
				"Barraje trifásico restablecido a 460 V nominales.",
				"info"
			)

func _animate_lever(lever: Node3D, active: bool) -> void:
	if lever != null:
		var target_rot: float = 0.0 if active else deg_to_rad(-45.0)
		var t = create_tween()
		t.tween_property(lever, "rotation:x", target_rot, 0.15)
