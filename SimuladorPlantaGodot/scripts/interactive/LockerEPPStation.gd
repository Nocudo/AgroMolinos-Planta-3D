class_name LockerEPPStation
extends Node3D

# ==============================================================================
# ESTACIÓN DE VESTIDOR Y DOTACIÓN DE EPP REGLAMENTARIA (RETIE / OSHA 1910)
# Filtro obligatorio de seguridad previo al ingreso a la nave de molienda 460 V
# ==============================================================================

@export var epp_equipped: bool = false

@onready var indicator_light: OmniLight3D = $IndicatorLight
@onready var interactable_area: Area3D = $InteractableArea

func _ready() -> void:
	if interactable_area != null:
		interactable_area.add_to_group("interactable")
	_update_indicator()

func interact(_tool_id: int) -> String:
	epp_equipped = not epp_equipped
	_update_indicator()

	var bus = get_node_or_null("/root/EventBus")
	if epp_equipped:
		if bus != null:
			bus.notification_posted.emit(
				"EPP REGLAMENTARIO EQUIPADO",
				"Protocolo RETIE/OSHA cumplido: Casco dieléctrico Clase E, gafas ANSI Z87.1, botas y protección auditiva. Ingreso autorizado a nave.",
				"info"
			)
		return "Has equipado la dotación completa de EPP. Acceso a nave de producción habilitado."
	else:
		if bus != null:
			bus.notification_posted.emit(
				"EPP RETIRADO",
				"Has guardado el EPP en el casillero. Advertencia: No ingresar a zona operativa sin protección.",
				"warning"
			)
		return "Has guardado tu equipo en el casillero."

func _update_indicator() -> void:
	if indicator_light != null:
		indicator_light.light_color = Color(0.2, 1.0, 0.4, 1.0) if epp_equipped else Color(1.0, 0.8, 0.2, 1.0)
