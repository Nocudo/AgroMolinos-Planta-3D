class_name LockerEPPStation
extends Node3D

# ==============================================================================
# ESTACIÓN DE VESTIDOR Y DOTACIÓN DE EPP REGLAMENTARIA (RETIE / OSHA 1910)
# Filtro obligatorio de seguridad previo al ingreso a la nave de molienda 460 V
# ==============================================================================

@export var epp_equipped: bool = false

@onready var indicator_light: OmniLight3D = $IndicatorLight
@onready var interactable_area: Area3D = $InteractableArea
@onready var interlock_barrier: StaticBody3D = get_node_or_null("../../AccessInterlockBarrier") as StaticBody3D
@onready var interlock_col: CollisionShape3D = get_node_or_null("../../AccessInterlockBarrier/CollisionShape3D") as CollisionShape3D
@onready var interlock_area: Area3D = get_node_or_null("../../AccessInterlockArea") as Area3D
@onready var interlock_light: OmniLight3D = get_node_or_null("../../AccessInterlockBarrier/InterlockLight") as OmniLight3D

var epp_items: Dictionary = {
	"casco_dielectrico": false,      # Casco Tipo I Clase E (20,000 V)
	"gafas_ansi": false,             # Gafas ANSI Z87.1
	"proteccion_auditiva": false,    # Protector auditivo NRR 27 dB
	"guantes_dielectricos": false,   # Guantes Clase 0 (1000 V)
	"botas_dielectricas": false,     # Botas ASTM F2413 (18 kV)
	"ropa_ignifuga": false           # Ropa Arc Flash Cat 2 (8 cal/cm²)
}

var _violation_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("interactable")
	if interactable_area != null:
		interactable_area.add_to_group("interactable")
	if interlock_area != null and not interlock_area.body_entered.is_connected(_on_interlock_area_entered):
		interlock_area.body_entered.connect(_on_interlock_area_entered)
	_sync_items(epp_equipped)
	_update_indicator()

func _process(delta: float) -> void:
	if _violation_cooldown > 0.0:
		_violation_cooldown -= delta

func interact(_tool_id: int) -> String:
	set_epp_equipped(not epp_equipped)
	var bus = get_node_or_null("/root/EventBus")
	if epp_equipped:
		if bus != null:
			bus.notification_posted.emit(
				"EPP equipado",
				"Protección completa. Acceso a planta habilitado.",
				"info"
			)
		return "EPP equipado. Acceso habilitado."
	else:
		if bus != null:
			bus.notification_posted.emit(
				"EPP retirado",
				"Acceso a planta bloqueado por seguridad.",
				"warning"
			)
		return "EPP guardado en el casillero."

func set_epp_equipped(equipped: bool) -> void:
	epp_equipped = equipped
	_sync_items(equipped)
	_update_indicator()
	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("epp_state_changed"):
		bus.epp_state_changed.emit(epp_equipped, epp_items.duplicate())

func equip_single_item(item_key: String) -> bool:
	if not epp_items.has(item_key):
		return false
	epp_items[item_key] = true
	var all_on := true
	for k in epp_items.keys():
		if not epp_items[k]:
			all_on = false
			break
	epp_equipped = all_on
	_update_indicator()
	var bus = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("epp_state_changed"):
		bus.epp_state_changed.emit(epp_equipped, epp_items.duplicate())
	return epp_equipped

func is_access_allowed() -> bool:
	return epp_equipped

func _sync_items(state: bool) -> void:
	for k in epp_items.keys():
		epp_items[k] = state

func _update_indicator() -> void:
	if indicator_light != null:
		indicator_light.light_color = Color(0.2, 1.0, 0.4, 1.0) if epp_equipped else Color(1.0, 0.8, 0.2, 1.0)
	if interlock_col != null:
		interlock_col.set_deferred("disabled", true)
	if interlock_light != null:
		interlock_light.light_color = Color(0.15, 0.95, 0.35, 1.0) if epp_equipped else Color(1.0, 0.15, 0.15, 1.0)

func _on_interlock_area_entered(body: Node3D) -> void:
	if not (body is CharacterBody3D) or body.name != "PlayerOperator":
		return
	if epp_equipped:
		return
	if is_inside_tree():
		var tut := get_tree().root.find_child("TutorialInductionManager", true, false)
		if tut != null and tut.has_method("evaluate_no_epp_plant_intrusion"):
			tut.evaluate_no_epp_plant_intrusion(body.global_position)
			return
	if _violation_cooldown <= 0.0:
		_violation_cooldown = 4.0
		var bus = get_node_or_null("/root/EventBus")
		if bus != null:
			if bus.has_signal("notification_posted"):
				bus.notification_posted.emit(
					"Acceso sin EPP prohibido",
					"Equipa tu EPP en vestidores antes de entrar.",
					"error"
				)
			if bus.has_signal("safety_violation_committed"):
				bus.safety_violation_committed.emit(
					"INGRESO_SIN_EPP",
					"Intento de ingreso a la zona de molienda sin EPP.",
					0.8
				)
