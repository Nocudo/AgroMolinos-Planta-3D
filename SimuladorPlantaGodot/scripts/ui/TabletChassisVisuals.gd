extends Control
class_name TabletChassisVisuals

## Marco minimalista limpio para la Tablet Industrial AgroMolinos
## sin botones ficticios ni adornos decorativos, con candado estricto de tamaño invariante.

const CHASSIS_SIZE := Vector2(1228.0, 748.0)
const SCREEN_SIZE := Vector2(1180.0, 700.0)

var _frame: PanelContainer = null
var _outer_shell: Panel = null
var _inner_bezel: Panel = null
var _enforcing_size: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	clip_contents = false

	_frame = get_parent().get_node_or_null("Frame") as PanelContainer
	_build_clean_chassis()
	_lock_frame_descendants()
	enforce_invariant_size()

	if not resized.is_connected(enforce_invariant_size):
		resized.connect(enforce_invariant_size)
	if _frame != null:
		if not _frame.resized.is_connected(enforce_invariant_size):
			_frame.resized.connect(enforce_invariant_size)
		if not _frame.sort_children.is_connected(enforce_invariant_size):
			_frame.sort_children.connect(enforce_invariant_size)
	var parent_ctrl := get_parent() as Control
	if parent_ctrl != null and not parent_ctrl.visibility_changed.is_connected(enforce_invariant_size):
		parent_ctrl.visibility_changed.connect(enforce_invariant_size)
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(enforce_invariant_size):
		vp.size_changed.connect(enforce_invariant_size)

func enforce_invariant_size() -> void:
	if _enforcing_size:
		return
	_enforcing_size = true

	# Marco exterior simétrico y limpio (1228 x 748, bisel uniforme de 24 px)
	custom_minimum_size = CHASSIS_SIZE
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -CHASSIS_SIZE.x * 0.5
	offset_top = -CHASSIS_SIZE.y * 0.5
	offset_right = CHASSIS_SIZE.x * 0.5
	offset_bottom = CHASSIS_SIZE.y * 0.5
	size = CHASSIS_SIZE
	scale = Vector2.ONE

	# Panel interior de pantalla SCADA (1180 x 700) centrado exactamente
	if _frame != null and is_instance_valid(_frame):
		_frame.custom_minimum_size = SCREEN_SIZE
		_frame.clip_contents = true
		_frame.anchor_left = 0.5
		_frame.anchor_top = 0.5
		_frame.anchor_right = 0.5
		_frame.anchor_bottom = 0.5
		_frame.offset_left = -SCREEN_SIZE.x * 0.5
		_frame.offset_top = -SCREEN_SIZE.y * 0.5
		_frame.offset_right = SCREEN_SIZE.x * 0.5
		_frame.offset_bottom = SCREEN_SIZE.y * 0.5
		_frame.size = SCREEN_SIZE
		_frame.scale = Vector2.ONE

	_enforcing_size = false

func _lock_frame_descendants() -> void:
	if _frame == null:
		return
	_frame.clip_contents = true
	var vbox := _frame.get_node_or_null("VBox") as Control
	if vbox != null:
		vbox.clip_contents = true
	var chk_vbox := _frame.find_child("ChecklistVBox", true, false)
	if chk_vbox != null and not chk_vbox.child_entered_tree.is_connected(_on_checklist_item_added):
		chk_vbox.child_entered_tree.connect(_on_checklist_item_added)

func _on_checklist_item_added(node: Node) -> void:
	if node is Button:
		var btn := node as Button
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size.x = 0.0
	call_deferred("enforce_invariant_size")

func _build_clean_chassis() -> void:
	# Carcasa exterior minimalista anodizada oscuro con sombra ambiental suave
	_outer_shell = Panel.new()
	_outer_shell.name = "CleanOuterShell"
	_outer_shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	_outer_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outer_shell.focus_mode = Control.FOCUS_NONE

	var outer_sb := StyleBoxFlat.new()
	outer_sb.bg_color = Color(0.078, 0.098, 0.132, 1.0)
	outer_sb.border_color = Color(0.24, 0.31, 0.42, 0.78)
	outer_sb.set_border_width_all(1)
	outer_sb.set_corner_radius_all(22)
	outer_sb.anti_aliasing = true
	outer_sb.anti_aliasing_size = 1.25
	outer_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.62)
	outer_sb.shadow_size = 26
	outer_sb.shadow_offset = Vector2(0, 10)
	_outer_shell.add_theme_stylebox_override("panel", outer_sb)
	add_child(_outer_shell)

	# Bisel interior de vidrio negro mate rodeando la pantalla
	_inner_bezel = Panel.new()
	_inner_bezel.name = "CleanGlassBezel"
	_inner_bezel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_inner_bezel.offset_left = 6.0
	_inner_bezel.offset_top = 6.0
	_inner_bezel.offset_right = -6.0
	_inner_bezel.offset_bottom = -6.0
	_inner_bezel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inner_bezel.focus_mode = Control.FOCUS_NONE

	var inner_sb := StyleBoxFlat.new()
	inner_sb.bg_color = Color(0.018, 0.025, 0.039, 1.0)
	inner_sb.border_color = Color(0.14, 0.19, 0.28, 0.55)
	inner_sb.set_border_width_all(1)
	inner_sb.set_corner_radius_all(16)
	inner_sb.anti_aliasing = true
	inner_sb.anti_aliasing_size = 1.0
	_inner_bezel.add_theme_stylebox_override("panel", inner_sb)
	add_child(_inner_bezel)
