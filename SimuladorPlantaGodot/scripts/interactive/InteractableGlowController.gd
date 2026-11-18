class_name InteractableGlowController
extends Node

# ==============================================================================
# SISTEMA DE RESALTADO 3D PROGRESIVO + X-RAY POST-TUTORIAL + SEMÁFORO DE ESTADOS
# - Durante el tutorial: resalta únicamente el equipo de la zona presentada.
# - Al finalizar/saltar el tutorial: resalta todas las máquinas y permite ver
#   el contorno X-Ray a través de las paredes detrás de muros/tabiques.
# - Estados: BLANCO (nominal), AMARILLO (advertencia), ROJO (detenida/crítica).
# Compatible con Godot 4.7 GL Compatibility y mallas SketchUp / Sketchfab (.glb).
# ==============================================================================

enum GlowState { HIDDEN = -1, WHITE = 0, YELLOW = 1, RED = 2, GREEN = 3, RED_HOVER = 4, BLUE_PULSE = 5 }

const STATE_NAMES: Dictionary = {
	GlowState.HIDDEN: "HIDDEN",
	GlowState.WHITE: "WHITE",
	GlowState.YELLOW: "YELLOW",
	GlowState.RED: "RED",
	GlowState.GREEN: "GREEN",
	GlowState.RED_HOVER: "RED_HOVER",
	GlowState.BLUE_PULSE: "BLUE_PULSE"
}

const TOOL_NAMES: Dictionary = {
	1: "1 • Manos",
	2: "2 • Alicates",
	3: "3 • Llave 3/4\"",
	4: "4 • Multímetro",
	5: "5 • Kit LOTO"
}

const TOOL_CLEAN_NAMES: Dictionary = {
	1: "Manos",
	2: "Alicates",
	3: "Llave 3/4\"",
	4: "Multímetro",
	5: "Kit LOTO"
}

# Orden exacto del flujo de proceso (desde llegada del camión de carga hasta ductos de aire)
const ORDERED_15_MACHINES: Array[String] = [
	"banda_descarga",
	"banda_inclinada_tolva",
	"hopper",
	"banda_trituradora",
	"tornillo_trituradora",
	"motor",
	"tornillo_secador",
	"secador_rotatorio",
	"ciclon_separador",
	"cyclone",
	"unidad_extraccion",
	"horno",
	"soplador",
	"intercambiador_calor",
	"ductos_aire"
]

const MACHINE_GROUPS: Array[String] = [
	"banda_descarga",
	"banda_inclinada_tolva",
	"hopper",
	"banda_trituradora",
	"tornillo_trituradora",
	"motor",
	"tornillo_secador",
	"secador_rotatorio",
	"ciclon_separador",
	"cyclone",
	"unidad_extraccion",
	"horno",
	"soplador",
	"intercambiador_calor",
	"ductos_aire",
	"breaker"
]

const MACHINE_DISPLAY_NAMES: Dictionary = {
	"banda_descarga": "01 · Banda de Descarga",
	"banda_inclinada_tolva": "02 · Banda Inclinada",
	"hopper": "03 · Tolva de Recepción",
	"banda_trituradora": "04 · Banda Trituradora",
	"tornillo_trituradora": "05 · Tornillo Trituradora",
	"motor": "06 · Trituradora y Motor 10 HP",
	"tornillo_secador": "07 · Tornillo al Secador",
	"secador_rotatorio": "08 · Secador Rotatorio",
	"ciclon_separador": "09 · Ciclón Separador",
	"cyclone": "10 · Ciclones Clasificadores",
	"unidad_extraccion": "11 · Unidad de Extracción",
	"horno": "12 · Horno Térmico",
	"soplador": "13 · Soplador",
	"intercambiador_calor": "14 · Intercambiador de Calor",
	"ductos_aire": "15 · Ductos de Aire",
	"breaker": "CCM · Tablero Eléctrico 460 V"
}

const ALL_GROUPS: Array[String] = [
	"banda_descarga",
	"banda_inclinada_tolva",
	"hopper",
	"banda_trituradora",
	"tornillo_trituradora",
	"motor",
	"tornillo_secador",
	"secador_rotatorio",
	"ciclon_separador",
	"cyclone",
	"unidad_extraccion",
	"horno",
	"soplador",
	"intercambiador_calor",
	"ductos_aire",
	"locker",
	"breaker"
]

# Mapeo único máquina -> nodos reales del GLB (sin traslapes)
const GLB_GROUP_NODES: Dictionary = {
	"banda_descarga": ["Group#510"],
	"banda_inclinada_tolva": ["Node1472"],
	"hopper": ["Node1583"],
	"banda_trituradora": ["Node1365"],
	"tornillo_trituradora": ["Group#149"],
	"motor": ["Node1246", "Node2150"],
	"tornillo_secador": ["Node2161"],
	"secador_rotatorio": ["Group#54", "Group#10"],
	"ciclon_separador": ["Group#501", "Group#689"],
	"cyclone": ["Group#14", "Node1179"],
	"unidad_extraccion": ["Node1313"],
	"horno": ["Node1503"],
	"soplador": ["Node1495"],
	"intercambiador_calor": ["Node1172"],
	"ductos_aire": ["Node1356", "Node1169"],
	"locker": ["Watson Zone Slot Lockers 20-Pack", "Watson Zone Slot Lockers 20-Pack_1"]
}

# Especificación uniforme de fallas y herramientas requeridas para las máquinas del tren de proceso
const PROCESS_FAULT_SPECS: Dictionary = {
	"banda_descarga": {
		"induce_tool": 3, "repair_tool": 3, "code": "FALLA_BANDA_DESCARGA",
		"induce_desc": "Destensar rodillo y atascar descarga", "repair_desc": "Tensar y alinear rodillo",
		"fault_title": "Atasco en banda de descarga", "fault_msg": "Rodillo tensor destensado en descarga de camión. Flujo reducido 35%.",
		"repair_title": "Banda de descarga normalizada", "repair_msg": "Rodillo alineado y tensión restablecida.",
		"load": 6.5, "temp": 2.0, "vib": 0.9, "flow_scale": 0.65, "aux_kw": 0.4
	},
	"banda_inclinada_tolva": {
		"induce_tool": 2, "repair_tool": 5, "code": "FALLA_BANDA_INCLINADA_TOLVA",
		"induce_desc": "Cortar lazo de control elevador", "repair_desc": "Empalmar sensor y rearmar",
		"fault_title": "Falla en banda inclinada", "fault_msg": "Corte de alimentación en banda elevadora. Caudal reducido 50%.",
		"repair_title": "Banda inclinada restablecida", "repair_msg": "Lazo de seguridad rearmado bajo RETIE.",
		"load": 5.0, "temp": 2.0, "vib": 1.1, "flow_scale": 0.50, "aux_kw": 0.5
	},
	"banda_trituradora": {
		"induce_tool": 2, "repair_tool": 5, "code": "FALLA_BANDA_TRITURADORA",
		"induce_desc": "Cortar alimentación de banda transportadora", "repair_desc": "Restablecer banda transportadora",
		"fault_title": "Banda hacia trituradora detenida", "fault_msg": "Interrupción en banda hacia tornillo de trituradora.",
		"repair_title": "Banda hacia trituradora operativa", "repair_msg": "Transferencia de grano normalizada.",
		"load": 9.0, "temp": 3.0, "vib": 1.4, "flow_scale": 0.25, "aux_kw": 0.6
	},
	"tornillo_trituradora": {
		"induce_tool": 3, "repair_tool": 3, "code": "FALLA_TORNILLO_TRITURADORA",
		"induce_desc": "Aflojar chumacera helicoidal", "repair_desc": "Apretar chumacera con llave 3/4\"",
		"fault_title": "Desajuste en tornillo trituradora", "fault_msg": "Chumacera floja y rozamiento helicoidal. Vibración +3.2 mm/s.",
		"repair_title": "Tornillo trituradora alineado", "repair_msg": "Chumacera ajustada y vibración normalizada.",
		"load": 14.0, "temp": 4.0, "vib": 3.2, "flow_scale": 0.70, "aux_kw": 0.5
	},
	"tornillo_secador": {
		"induce_tool": 3, "repair_tool": 3, "code": "FALLA_TORNILLO_SECADOR",
		"induce_desc": "Desacoplar brida y obstruir sinfín", "repair_desc": "Reacoplar brida y despejar",
		"fault_title": "Obstrucción en tornillo al secador", "fault_msg": "Contrapresión en descarga de trituradora. Par +22 N·m.",
		"repair_title": "Tornillo al secador despejado", "repair_msg": "Descarga continua hacia secador restaurada.",
		"load": 22.0, "temp": 7.0, "vib": 1.8, "flow_scale": 0.45, "aux_kw": 0.7
	},
	"secador_rotatorio": {
		"induce_tool": 4, "repair_tool": 5, "code": "FALLA_SECADOR_ROTATORIO",
		"induce_desc": "Inducir deriva térmica en tambor", "repair_desc": "Resetear control LOTO y purgar",
		"fault_title": "Sobretemperatura en secador rotatorio", "fault_msg": "Desbalance térmico y falla de lazo en tambor. +26 °C.",
		"repair_title": "Secador rotatorio estabilizado", "repair_msg": "Lazo térmico calibrado y cámara purgada.",
		"load": 6.0, "temp": 26.0, "vib": 1.6, "flow_scale": 0.80, "aux_kw": 1.8
	},
	"ciclon_separador": {
		"induce_tool": 3, "repair_tool": 3, "code": "FALLA_CICLON_SEPARADOR",
		"induce_desc": "Trabar válvula rotativa inferior", "repair_desc": "Desbloquear válvula rotativa",
		"fault_title": "Bloqueo en ciclón separador", "fault_msg": "Válvula rotativa trabada con acumulación de harina.",
		"repair_title": "Ciclón separador desbloqueado", "repair_msg": "Descarga neumática de sólidos normalizada.",
		"load": 9.5, "temp": 6.0, "vib": 1.2, "flow_scale": 0.60, "aux_kw": 0.6
	},
	"cyclone": {
		"induce_tool": 2, "repair_tool": 5, "code": "SOBREPRESION_CICLON_ATEX",
		"induce_desc": "Cortar lazo presostato ATEX 22", "repair_desc": "Restablecer lazo ATEX con Kit LOTO",
		"fault_title": "Falla ATEX en ciclones clasificadores", "fault_msg": "Corte de presostato diferencial y nube crítica de polvo.",
		"repair_title": "Ciclones clasificadores normalizados", "repair_msg": "Presión diferencial y contención ATEX restauradas.",
		"load": 5.0, "temp": 10.0, "vib": 1.5, "flow_scale": 0.55, "aux_kw": 0.8
	},
	"unidad_extraccion": {
		"induce_tool": 2, "repair_tool": 5, "code": "FALLA_UNIDAD_EXTRACCION",
		"induce_desc": "Cortar alimentación de extractor", "repair_desc": "Empalmar y rearmar extractor",
		"fault_title": "Falla en unidad de extracción", "fault_msg": "Pérdida de succión en extractor. Carga térmica +18 °C.",
		"repair_title": "Unidad de extracción operativa", "repair_msg": "Caudal de extracción y ventilación recuperados.",
		"load": 3.0, "temp": 18.0, "vib": 1.0, "flow_scale": 0.85, "aux_kw": 0.9
	},
	"horno": {
		"induce_tool": 4, "repair_tool": 5, "code": "FALLA_HORNO_TERMICO",
		"induce_desc": "Simular falla de termopar", "repair_desc": "Resetear enclavamiento térmico",
		"fault_title": "Sobretemperatura en horno térmico", "fault_msg": "Deriva de termopar en cámara de combustión. +35 °C.",
		"repair_title": "Horno térmico normalizado", "repair_msg": "Enclavamiento de quemador restablecido bajo LOTO.",
		"load": 2.0, "temp": 35.0, "vib": 0.6, "flow_scale": 0.90, "aux_kw": 2.4
	},
	"soplador": {
		"induce_tool": 3, "repair_tool": 3, "code": "FALLA_SOPLADOR",
		"induce_desc": "Aflojar brida de succión", "repair_desc": "Apretar brida con llave 3/4\"",
		"fault_title": "Vibración y fuga en soplador", "fault_msg": "Brida floja en impulsión. Vibración +2.4 mm/s.",
		"repair_title": "Soplador sellado y alineado", "repair_msg": "Caudal hacia intercambiador y horno normalizado.",
		"load": 4.0, "temp": 12.0, "vib": 2.4, "flow_scale": 0.80, "aux_kw": 1.0
	},
	"intercambiador_calor": {
		"induce_tool": 4, "repair_tool": 3, "code": "FALLA_INTERCAMBIADOR_CALOR",
		"induce_desc": "Forzar cierre de compuerta térmica", "repair_desc": "Abrir circuito con llave 3/4\"",
		"fault_title": "Falla en intercambiador de calor", "fault_msg": "Baja transferencia térmica en circuito. Retorno +20 °C.",
		"repair_title": "Intercambiador de calor operativo", "repair_msg": "Circuito térmico restablecido.",
		"load": 3.0, "temp": 20.0, "vib": 0.8, "flow_scale": 0.85, "aux_kw": 1.1
	},
	"ductos_aire": {
		"induce_tool": 3, "repair_tool": 5, "code": "FALLA_DUCTOS_AIRE",
		"induce_desc": "Aflojar abrazadera de ducto", "repair_desc": "Sellar junta y presurizar LOTO",
		"fault_title": "Fuga de presión en ductos de aire", "fault_msg": "Junta floja en línea neumática. Presión reducida 40%.",
		"repair_title": "Ductos de aire presurizados", "repair_msg": "Junta sellada y presión nominal recuperada.",
		"load": 4.0, "temp": 9.0, "vib": 1.1, "flow_scale": 0.65, "aux_kw": 0.5
	}
}

const CORE_SHADER_CODE := """shader_type spatial;
render_mode %s, unshaded, depth_draw_never;

uniform vec3 outline_color : source_color = vec3(0.96, 0.99, 1.0);
uniform float intensity = 1.60;
uniform float width_ratio = 0.0020;
uniform float min_width = 0.012;
uniform float max_width = 0.048;
uniform float pulse_speed = 0.0;
uniform float pulse_min = 0.70;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float cam_dist = length(CAMERA_POSITION_WORLD - world_pos);
	float w_thick = clamp(cam_dist * width_ratio, min_width, max_width);
	float n_len = length(NORMAL);
	if (n_len > 0.0001) {
		float m_scale = max(length(MODEL_MATRIX[0].xyz), 0.0001);
		VERTEX += (NORMAL / n_len) * (w_thick / m_scale);
	}
}

void fragment() {
	float pulse = (pulse_speed > 0.05) ? mix(pulse_min, 1.0, 0.5 + 0.5 * sin(TIME * pulse_speed)) : 1.0;
	ALBEDO = outline_color * (intensity * pulse);
}
"""

const HALO_SHADER_CODE := """shader_type spatial;
render_mode %s, blend_add, unshaded, depth_draw_never;

uniform vec3 outline_color : source_color = vec3(1.0, 0.015, 0.015);
uniform float intensity = 3.40;
uniform float width_ratio = 0.0082;
uniform float min_width = 0.041;
uniform float max_width = 0.180;
uniform float pulse_speed = 0.0;
uniform float falloff_pow = 1.35;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float cam_dist = length(CAMERA_POSITION_WORLD - world_pos);
	float w_thick = clamp(cam_dist * width_ratio, min_width, max_width);
	float n_len = length(NORMAL);
	if (n_len > 0.0001) {
		float m_scale = max(length(MODEL_MATRIX[0].xyz), 0.0001);
		VERTEX += (NORMAL / n_len) * (w_thick / m_scale);
	}
}

void fragment() {
	float ndv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float fade = pow(ndv, falloff_pow);
	float pulse = (pulse_speed > 0.05) ? (0.80 + 0.20 * sin(TIME * pulse_speed)) : 1.0;
	float a = clamp(fade * pulse, 0.0, 1.0);
	ALBEDO = outline_color * (intensity * a);
	ALPHA = a;
}
"""

const XRAY_SHADER_CODE := """shader_type spatial;
render_mode %s, unshaded, depth_test_disabled, depth_draw_never, blend_mix;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec3 xray_color : source_color = vec3(0.96, 0.99, 1.0);
uniform float intensity = 2.25;
uniform float pulse_speed = 0.0;

void fragment() {
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, d * 2.0 - 1.0, 1.0);
	float scene_z = -(upos.xyz / upos.w).z;
	float frag_z = -VERTEX.z;
	float behind = smoothstep(0.18, 0.42, frag_z - scene_z);
	if (behind <= 0.01) {
		discard;
	}
	float ndv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float rim = pow(1.0 - ndv, 1.90);
	float pulse = (pulse_speed > 0.05) ? (0.82 + 0.18 * sin(TIME * pulse_speed)) : 1.0;
	ALBEDO = xray_color * intensity * (0.12 + 0.95 * rim) * pulse;
	ALPHA = behind * clamp(0.03 + 0.85 * rim, 0.0, 0.78) * pulse;
}
"""

# _mats[state][mirrored_int][xray_int] -> ShaderMaterial
var _mats: Dictionary = {}

var _outline_mesh_cache: Dictionary = {} # instance_id -> Mesh
var _shells_by_group: Dictionary = {}
var _meshes_by_group: Dictionary = {}
var _mesh_to_group: Dictionary = {} # mesh instance_id -> group_key
var _group_aabbs: Dictionary = {}
var _group_exclude_rids: Dictionary = {}

var _hovered_machine_group: String = ""
var _hovered_target_node: Node = null
var _process_faults: Dictionary = {} # machine_key -> bool (todas las máquinas de PROCESS_FAULT_SPECS)

var _sparks_by_group: Dictionary = {} # group_key -> GPUParticles3D

var _motor_node: Node = null
var _cable_node: Node = null
var _bolt_node: Node = null
var _vent_node: Node = null
var _hopper_node: Node = null
var _breaker_node: Node = null
var _locker_node: Node = null
var _tutorial_node: Node = null
var _tablet_root: Node = null

var _ai_severity: String = "NORMAL"
var _ai_class: String = "NORMAL"
var _ai_mhi: float = 98.0
var _group_warnings: Dictionary = {}

var _sync_timer: float = 0.0
var _occlusion_timer: float = 0.0
var _post_tutorial_active: bool = false
var _last_states: Dictionary = {}
var _last_occluded: Dictionary = {}
var _last_cam_pos: Vector3 = Vector3(99999, 99999, 99999)
var _crossed_hazard_zone_id: String = ""

func _ready() -> void:
	for g in ALL_GROUPS:
		_shells_by_group[g] = []
		_meshes_by_group[g] = []
		_last_states[g] = -99
		_last_occluded[g] = false
		_group_warnings[g] = false
	for pk in PROCESS_FAULT_SPECS.keys():
		_process_faults[pk] = false
	_build_outline_materials()
	call_deferred("_discover_and_apply")

var _machine_labels_root: Node3D = null
var _machine_labels_by_group: Dictionary = {}

const MACHINE_AISLE_LABEL_SPECS: Dictionary = {
	"banda_descarga": {"text": "01 · BANDA DE DESCARGA", "face": "+z", "y_pref": 1.56, "lat_pref": -30.54, "pixel_size": 0.0028, "offset": 0.18},
	"banda_inclinada_tolva": {"text": "02 · BANDA INCLINADA\nHACIA TOLVA", "face": "+z", "y_pref": 2.95, "lat_pref": -27.98, "pixel_size": 0.0023, "offset": 0.26},
	"hopper": {"text": "03 · TOLVA DE RECEPCIÓN", "face": "+x", "y_pref": 2.90, "lat_pref": 46.60, "pixel_size": 0.0028, "offset": 0.18},
	"banda_trituradora": {"text": "04 · BANDA A SINFÍN\nTRITURADORA", "face": "+x", "y_pref": 1.55, "y_offset": 0.65, "lat_pref": 45.25, "pixel_size": 0.0017, "offset": 0.65},
	"tornillo_trituradora": {"text": "05 · TORNILLO SIN FIN\nTRITURADORA", "face": "+x", "y_pref": 1.85, "lat_pref": 42.10, "pixel_size": 0.0017, "offset": 0.90},
	"motor": {"text": "06 · TRITURADORA\nMOTOR 10 HP", "face": "+x", "y_pref": 3.75, "lat_pref": 43.65, "pixel_size": 0.0020, "offset": 0.62},
	"tornillo_secador": {"text": "07 · TORNILLO SIN FIN\nAL SECADOR", "face": "+x", "y_pref": 3.45, "lat_pref": 40.25, "pixel_size": 0.0019, "offset": 0.40},
	"breaker": {"text": "CCM · TABLERO\n460 V / VFD", "face": "+x", "y_pref": 2.10, "y_offset": 0.38, "lat_pref": 38.50, "pixel_size": 0.0016, "offset": 0.14},
	"secador_rotatorio": {"text": "08 · SECADOR ROTATORIO", "face": "+x", "y_pref": 3.92, "lat_pref": 36.25, "pixel_size": 0.0031, "offset": 0.22},
	"ciclon_separador": {"text": "09 · CICLÓN SEPARADOR", "face": "+x", "y_pref": 6.20, "lat_pref": 33.45, "pixel_size": 0.0026, "offset": 0.85},
	"cyclone": {"text": "10 · CICLONES\nCLASIFICADORES", "face": "+x", "y_pref": 3.65, "lat_pref": 29.15, "pixel_size": 0.0023, "offset": 0.38},
	"unidad_extraccion": {"text": "11 · UNIDAD DE\nEXTRACCIÓN", "face": "-x", "y_pref": 1.48, "lat_pref": 36.34, "pixel_size": 0.0019, "offset": 0.22},
	"horno": {"text": "12 · HORNO TÉRMICO", "face": "-x", "y_pref": 3.55, "y_offset": 0.12, "lat_pref": 34.35, "pixel_size": 0.0026, "offset": 0.24},
	"soplador": {"text": "13 · SOPLADOR", "face": "-x", "y_pref": 2.60, "y_offset": 0.52, "lat_pref": 38.85, "pixel_size": 0.0024, "offset": 0.24},
	"intercambiador_calor": {"text": "14 · INTERCAMBIADOR\nDE CALOR", "face": "-x", "y_pref": 2.35, "y_offset": 0.25, "lat_pref": 31.00, "pixel_size": 0.0024, "offset": 0.24},
	"ductos_aire": {"text": "15 · DUCTOS DE AIRE", "face": "-x", "y_pref": 4.05, "lat_pref": 31.30, "pixel_size": 0.0028, "offset": 0.24}
}

func _exit_tree() -> void:
	_outline_mesh_cache.clear()
	_mesh_to_group.clear()
	_hovered_target_node = null
	_hovered_machine_group = ""
	for k in _shells_by_group.keys():
		(_shells_by_group[k] as Array).clear()
	for k in _meshes_by_group.keys():
		(_meshes_by_group[k] as Array).clear()
	_group_exclude_rids.clear()
	_sparks_by_group.clear()
	_process_faults.clear()
	_machine_labels_by_group.clear()
	_machine_labels_root = null

func _make_hull_material(_mirrored: bool, col: Color, core_i: float, _halo_i: float, core_w: float, _halo_w: float, pulse: float, with_xray: bool, xray_i: float, pulse_min: float = 0.70) -> ShaderMaterial:
	# En Godot 4 (incluyendo GL Compatibility), el motor invierte automáticamente el culling de caras
	# para mallas con determinante negativo; usar siempre cull_front evita pintar las caras frontales.
	var hull_cull := "cull_front"
	var core_sh := Shader.new()
	core_sh.code = CORE_SHADER_CODE % hull_cull
	var core_mat := ShaderMaterial.new()
	core_mat.shader = core_sh
	core_mat.render_priority = 1
	core_mat.set_shader_parameter("outline_color", col)
	core_mat.set_shader_parameter("intensity", core_i)
	core_mat.set_shader_parameter("width_ratio", core_w)
	core_mat.set_shader_parameter("min_width", maxf(0.022, core_w * 3.8))
	core_mat.set_shader_parameter("max_width", maxf(0.095, core_w * 17.5))
	core_mat.set_shader_parameter("pulse_speed", pulse)
	core_mat.set_shader_parameter("pulse_min", pulse_min)

	if with_xray:
		var xray_cull := "cull_back"
		var xray_sh := Shader.new()
		xray_sh.code = XRAY_SHADER_CODE % xray_cull
		var xray_mat := ShaderMaterial.new()
		xray_sh.resource_local_to_scene = false
		xray_mat.shader = xray_sh
		xray_mat.render_priority = 1
		xray_mat.set_shader_parameter("xray_color", col)
		xray_mat.set_shader_parameter("intensity", xray_i)
		xray_mat.set_shader_parameter("pulse_speed", pulse)
		core_mat.next_pass = xray_mat

	return core_mat

func _build_outline_materials() -> void:
	var cfgs := {
		GlowState.WHITE: {
			"col": Color(0.96, 0.99, 1.0, 1.0),
			"core_i": 1.35, "halo_i": 1.15,
			"core_w": 0.0062, "halo_w": 0.0095,
			"pulse": 0.0, "xray_i": 1.35
		},
		GlowState.YELLOW: {
			"col": Color(1.0, 0.72, 0.02, 1.0),
			"core_i": 1.65, "halo_i": 1.45,
			"core_w": 0.0070, "halo_w": 0.0110,
			"pulse": 3.8, "xray_i": 1.85
		},
		GlowState.RED: {
			"col": Color(1.0, 0.05, 0.05, 1.0),
			"core_i": 1.85, "halo_i": 1.65,
			"core_w": 0.0078, "halo_w": 0.0120,
			"pulse": 6.5, "xray_i": 2.05
		},
		GlowState.GREEN: {
			"col": Color(0.12, 1.0, 0.38, 1.0),
			"core_i": 1.75, "halo_i": 1.55,
			"core_w": 0.0074, "halo_w": 0.0115,
			"pulse": 3.2, "xray_i": 1.95
		},
		GlowState.RED_HOVER: {
			"col": Color(1.0, 0.44, 0.40, 1.0),
			"core_i": 2.10, "halo_i": 1.95,
			"core_w": 0.0085, "halo_w": 0.0135,
			"pulse": 7.5, "xray_i": 2.25
		},
		GlowState.BLUE_PULSE: {
			"col": Color(0.14, 0.66, 1.0, 1.0),
			"core_i": 2.05, "halo_i": 1.80,
			"core_w": 0.0078, "halo_w": 0.0120,
			"pulse": 5.2, "pulse_min": 0.10, "xray_i": 1.95
		}
	}
	_mats.clear()
	for st in cfgs.keys():
		var c: Dictionary = cfgs[st]
		var p_min: float = float(c.get("pulse_min", 0.70))
		_mats[st] = {
			0: {
				0: _make_hull_material(false, c["col"], c["core_i"], c["halo_i"], c["core_w"], c["halo_w"], c["pulse"], false, c["xray_i"], p_min),
				1: _make_hull_material(false, c["col"], c["core_i"], c["halo_i"], c["core_w"], c["halo_w"], c["pulse"], true, c["xray_i"], p_min)
			},
			1: {
				0: _make_hull_material(true, c["col"], c["core_i"], c["halo_i"], c["core_w"], c["halo_w"], c["pulse"], false, c["xray_i"], p_min),
				1: _make_hull_material(true, c["col"], c["core_i"], c["halo_i"], c["core_w"], c["halo_w"], c["pulse"], true, c["xray_i"], p_min)
			}
		}

func _discover_and_apply() -> void:
	var scene_root := get_parent()
	if scene_root == null:
		return

	_motor_node = scene_root.find_child("InductionMotor", true, false)
	_cable_node = scene_root.find_child("PhysicalCableConductor", true, false)
	_bolt_node = scene_root.find_child("MechanicalBolt", true, false)
	_vent_node = scene_root.find_child("VentilationCover", true, false)
	_hopper_node = scene_root.find_child("PhysicalHopperFeeder", true, false)
	_breaker_node = scene_root.find_child("PhysicalBreakerPanel", true, false)
	_locker_node = scene_root.find_child("LockerEPPStation", true, false)
	_tutorial_node = scene_root.find_child("TutorialInductionManager", true, false)
	_tablet_root = scene_root.find_child("TabletRoot", true, false)

	_collect_targets(scene_root)
	_setup_fault_sparks(scene_root)
	_setup_machine_aisle_labels(scene_root)
	_connect_events()
	refresh_highlights(true)

func _collect_targets(scene_root: Node) -> void:
	for g in ALL_GROUPS:
		(_meshes_by_group[g] as Array).clear()

	var plant := scene_root.find_child("PlantaCompletaSketchUp", true, false)
	if plant != null:
		for g_name in GLB_GROUP_NODES.keys():
			var grp_arr: Array[MeshInstance3D] = []
			_append_meshes_for_names(plant, GLB_GROUP_NODES[g_name] as Array, grp_arr)
			_meshes_by_group[g_name] = grp_arr

	# Todos los camiones sin glow visual
	_meshes_by_group["truck"] = []

	var motor_meshes: Array[MeshInstance3D] = _meshes_by_group["motor"] as Array[MeshInstance3D]
	var mill_unit := scene_root.find_child("MotorMillUnit", true, false)
	if mill_unit != null:
		_append_subtree_meshes(mill_unit, motor_meshes, ["PhysicalHopperFeeder", "DustParticles", "SparkParticles", "FaultSparksMotor"])

	var hopper_meshes: Array[MeshInstance3D] = _meshes_by_group["hopper"] as Array[MeshInstance3D]
	if _hopper_node != null:
		_append_subtree_meshes(_hopper_node, hopper_meshes, ["DustParticles", "FaultSparksHopper"])

	var breaker_meshes: Array[MeshInstance3D] = []
	if _breaker_node != null:
		_append_subtree_meshes(_breaker_node, breaker_meshes, ["FaultSparksBreaker"])
	_meshes_by_group["breaker"] = breaker_meshes

	var locker_meshes: Array[MeshInstance3D] = _meshes_by_group["locker"] as Array[MeshInstance3D]
	if _locker_node != null:
		_append_subtree_meshes(_locker_node, locker_meshes, [])

	# Sacos y bolsas sin contorno glow por solicitud del usuario
	_meshes_by_group["bag"] = []

	_mesh_to_group.clear()
	for g in ALL_GROUPS:
		for m_item in (_meshes_by_group[g] as Array):
			if m_item is MeshInstance3D:
				_mesh_to_group[(m_item as MeshInstance3D).get_instance_id()] = g
		_ensure_shells_for_group(g, _meshes_by_group[g])
		_cache_group_bounds_and_rids(g, _meshes_by_group[g])

func _cache_group_bounds_and_rids(group_key: String, meshes: Array) -> void:
	var has := false
	var box := AABB()
	var rids: Array[RID] = []
	for item in meshes:
		var mi := item as MeshInstance3D
		if mi == null or not is_instance_valid(mi) or mi.mesh == null:
			continue
		var lb := mi.mesh.get_aabb()
		var xf := mi.global_transform
		for i in range(8):
			var wp := xf * Vector3(
				lb.position.x + (lb.size.x if (i & 1) != 0 else 0.0),
				lb.position.y + (lb.size.y if (i & 2) != 0 else 0.0),
				lb.position.z + (lb.size.z if (i & 4) != 0 else 0.0)
			)
			if not has:
				box = AABB(wp, Vector3.ZERO)
				has = true
			else:
				box = box.expand(wp)
		_collect_self_rids(mi, rids)
	if group_key == "breaker" and _breaker_node != null:
		_collect_self_rids(_breaker_node, rids)
	elif group_key == "motor":
		var mu := get_parent().find_child("MotorMillUnit", true, false) if get_parent() else null
		if mu != null:
			_collect_self_rids(mu, rids)
	elif group_key == "locker" and _locker_node != null:
		_collect_self_rids(_locker_node, rids)
	elif group_key == "hopper" and _hopper_node != null:
		_collect_self_rids(_hopper_node, rids)
	elif group_key == "truck" and get_parent() != null:
		var mover := get_parent().find_child("TruckDispatchMover", true, false)
		if mover != null:
			_collect_self_rids(mover, rids)
	if has:
		_group_aabbs[group_key] = box
	_group_exclude_rids[group_key] = rids

func _collect_self_rids(node: Node, rids: Array[RID]) -> void:
	if node == null:
		return
	if node is CollisionObject3D:
		var r := (node as CollisionObject3D).get_rid()
		if not rids.has(r):
			rids.append(r)
	for ch in node.get_children():
		_collect_self_rids(ch, rids)

func _setup_machine_aisle_labels(scene_root: Node) -> void:
	if _machine_labels_root != null and is_instance_valid(_machine_labels_root):
		_machine_labels_root.queue_free()
	_machine_labels_by_group.clear()

	_machine_labels_root = Node3D.new()
	_machine_labels_root.name = "MachineAisleLabels"
	scene_root.add_child(_machine_labels_root)

	for group_key in MACHINE_AISLE_LABEL_SPECS.keys():
		var spec: Dictionary = MACHINE_AISLE_LABEL_SPECS[group_key]
		if not _group_aabbs.has(group_key):
			continue
		var box: AABB = _group_aabbs[group_key]
		var face: String = str(spec.get("face", "+x"))
		var y_pref: float = clampf(float(spec.get("y_pref", box.get_center().y)), box.position.y + 0.30, box.end.y - 0.15)
		var lat_def: float = box.get_center().z if (face == "+x" or face == "-x") else box.get_center().x
		var lat_pref: float = float(spec.get("lat_pref", lat_def))
		var offset: float = float(spec.get("offset", 0.08))
		var y_offset: float = float(spec.get("y_offset", 0.0))
		var anchor_pt: Vector3 = _find_aisle_surface_point(group_key, face, y_pref, lat_pref, box)

		var lbl := Label3D.new()
		lbl.name = "AisleLabel_" + group_key
		lbl.text = str(spec.get("text", MACHINE_DISPLAY_NAMES.get(group_key, group_key.to_upper())))
		lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lbl.double_sided = false
		lbl.shaded = false
		lbl.no_depth_test = true
		lbl.font_size = int(spec.get("font_size", 84))
		lbl.pixel_size = float(spec.get("pixel_size", 0.0026))
		lbl.outline_size = maxi(16, int(round(float(lbl.font_size) * 0.22)))
		lbl.modulate = Color(1.15, 1.15, 1.15, 1.0)
		lbl.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.render_priority = 25
		lbl.outline_render_priority = 24
		lbl.alpha_cut = Label3D.ALPHA_CUT_DISABLED
		lbl.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		lbl.add_to_group("machine_aisle_label")
		lbl.set_meta("machine_group", group_key)
		lbl.set_meta("aisle_face", face)
		_machine_labels_root.add_child(lbl)

		var face_cfg: Dictionary = {
			"+x": {"norm": Vector3(1, 0, 0), "rot": Vector3(0.0, PI * 0.5, 0.0)},
			"-x": {"norm": Vector3(-1, 0, 0), "rot": Vector3(0.0, -PI * 0.5, 0.0)},
			"+z": {"norm": Vector3(0, 0, 1), "rot": Vector3.ZERO},
			"-z": {"norm": Vector3(0, 0, -1), "rot": Vector3(0.0, PI, 0.0)}
		}
		var cfg: Dictionary = face_cfg.get(face, face_cfg["+x"])
		var norm_dir: Vector3 = cfg["norm"]
		lbl.global_position = anchor_pt + norm_dir * offset + Vector3(0.0, y_offset, 0.0)
		lbl.rotation = cfg["rot"]

		_machine_labels_by_group[group_key] = lbl

func _find_aisle_surface_point(group_key: String, face: String, y_pref: float, lat_pref: float, box: AABB) -> Vector3:
	var meshes: Array = _meshes_by_group.get(group_key, [])
	var offsets := [
		Vector2(0.0, 0.0),
		Vector2(0.0, -0.22), Vector2(0.0, 0.22),
		Vector2(-0.22, 0.0), Vector2(0.22, 0.0),
		Vector2(0.0, -0.50), Vector2(0.0, 0.50),
		Vector2(-0.45, -0.35), Vector2(0.45, 0.35)
	]
	for off in offsets:
		var qy: float = clampf(y_pref + off.x, box.position.y + 0.15, box.end.y - 0.10)
		var qlat: float = lat_pref + off.y
		var ray_orig: Vector3
		var ray_dir: Vector3
		match face:
			"+z":
				qlat = clampf(qlat, box.position.x + 0.10, box.end.x - 0.10)
				ray_orig = Vector3(qlat, qy, box.end.z + 1.0)
				ray_dir = Vector3(0.0, 0.0, -1.0)
			"-z":
				qlat = clampf(qlat, box.position.x + 0.10, box.end.x - 0.10)
				ray_orig = Vector3(qlat, qy, box.position.z - 1.0)
				ray_dir = Vector3(0.0, 0.0, 1.0)
			"-x":
				qlat = clampf(qlat, box.position.z + 0.10, box.end.z - 0.10)
				ray_orig = Vector3(box.position.x - 1.0, qy, qlat)
				ray_dir = Vector3(1.0, 0.0, 0.0)
			_:
				qlat = clampf(qlat, box.position.z + 0.10, box.end.z - 0.10)
				ray_orig = Vector3(box.end.x + 1.0, qy, qlat)
				ray_dir = Vector3(-1.0, 0.0, 0.0)

		var best_hit := Vector3.ZERO
		var best_dist: float = 1e9
		var found := false
		for item in meshes:
			var mi := item as MeshInstance3D
			if mi == null or not is_instance_valid(mi) or mi.mesh == null:
				continue
			var xf: Transform3D = mi.global_transform
			for s in range(mi.mesh.get_surface_count()):
				var arrays := mi.mesh.surface_get_arrays(s)
				if arrays.is_empty():
					continue
				var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				if verts.is_empty():
					continue
				var idx_var = arrays[Mesh.ARRAY_INDEX]
				var has_idx: bool = idx_var != null and (idx_var as PackedInt32Array).size() >= 3
				var idxs: PackedInt32Array = idx_var if has_idx else PackedInt32Array()
				var tri_total: int = idxs.size() if has_idx else verts.size()
				var t := 0
				while t + 2 < tri_total:
					var i0: int = idxs[t] if has_idx else t
					var i1: int = idxs[t + 1] if has_idx else t + 1
					var i2: int = idxs[t + 2] if has_idx else t + 2
					var hit = Geometry3D.ray_intersects_triangle(ray_orig, ray_dir, xf * verts[i0], xf * verts[i1], xf * verts[i2])
					if hit is Vector3:
						var hp := hit as Vector3
						var d := ray_orig.distance_to(hp)
						if d < best_dist:
							best_dist = d
							best_hit = hp
							found = true
					t += 3
		if found:
			return best_hit

	var cx := clampf(lat_pref, box.position.x + 0.15, box.end.x - 0.15)
	var cz := clampf(lat_pref, box.position.z + 0.15, box.end.z - 0.15)
	match face:
		"+z": return Vector3(cx, y_pref, box.end.z)
		"-z": return Vector3(cx, y_pref, box.position.z)
		"-x": return Vector3(box.position.x, y_pref, cz)
		_: return Vector3(box.end.x, y_pref, cz)

func _append_meshes_for_names(root_n: Node, names: Array, target: Array[MeshInstance3D]) -> void:
	for nm_v in names:
		var nm := str(nm_v)
		var node := root_n.find_child(nm, true, false)
		if node != null:
			_append_subtree_meshes(node, target, [])

func _append_subtree_meshes(root_n: Node, target: Array[MeshInstance3D], skip_names: Array[String]) -> void:
	if root_n == null or not is_instance_valid(root_n):
		return
	if skip_names.has(root_n.name) or root_n.name == "GlowOutlineShell":
		return
	if root_n is MeshInstance3D:
		var mi := root_n as MeshInstance3D
		if mi.mesh != null and not (mi.mesh is ImmediateMesh) and not target.has(mi):
			target.append(mi)
	for ch in root_n.get_children():
		_append_subtree_meshes(ch, target, skip_names)

func _get_or_build_outline_mesh(src_mesh: Mesh) -> Mesh:
	if src_mesh == null:
		return null
	var mid := src_mesh.get_instance_id()
	if _outline_mesh_cache.has(mid):
		return _outline_mesh_cache[mid]

	var total_verts: int = 0
	for s in range(src_mesh.get_surface_count()):
		var arr := src_mesh.surface_get_arrays(s)
		if not arr.is_empty() and arr[Mesh.ARRAY_VERTEX] is PackedVector3Array:
			total_verts += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()

	if total_verts == 0 or total_verts > 120000:
		_outline_mesh_cache[mid] = src_mesh
		return src_mesh

	var aabb_center: Vector3 = src_mesh.get_aabb().get_center()
	var all_verts := PackedVector3Array()
	var raw_tris: Array[Vector3i] = []

	for s in range(src_mesh.get_surface_count()):
		var arr := src_mesh.surface_get_arrays(s)
		if arr.is_empty():
			continue
		var verts := arr[Mesh.ARRAY_VERTEX] as PackedVector3Array
		if verts == null or verts.is_empty():
			continue
		var idx_arr := arr[Mesh.ARRAY_INDEX] as PackedInt32Array if arr[Mesh.ARRAY_INDEX] is PackedInt32Array else PackedInt32Array()
		var base_v := all_verts.size()
		all_verts.append_array(verts)

		if idx_arr != null and not idx_arr.is_empty():
			var t := 0
			while t + 2 < idx_arr.size():
				raw_tris.append(Vector3i(base_v + idx_arr[t], base_v + idx_arr[t + 1], base_v + idx_arr[t + 2]))
				t += 3
		else:
			var t := 0
			while t + 2 < verts.size():
				raw_tris.append(Vector3i(base_v + t, base_v + t + 1, base_v + t + 2))
				t += 3

	if all_verts.is_empty() or raw_tris.is_empty():
		_outline_mesh_cache[mid] = src_mesh
		return src_mesh

	# 1. Eliminar caras duplicadas de doble cara (SketchUp exporta par CW + CCW en la misma posición)
	#    conservando únicamente la cara cuya normal geométrica apunta hacia afuera del centroide.
	var best_tri_by_key: Dictionary = {}
	var best_score_by_key: Dictionary = {}
	var tri_order: Array[String] = []
	for tri in raw_tris:
		var v0 := all_verts[tri.x]
		var v1 := all_verts[tri.y]
		var v2 := all_verts[tri.z]
		var gn := (v2 - v0).cross(v1 - v0)
		var gn_len2 := gn.length_squared()
		if gn_len2 < 1e-12:
			continue
		var q0 := _quantize_pos_coarse(v0)
		var q1 := _quantize_pos_coarse(v1)
		var q2 := _quantize_pos_coarse(v2)
		var key := _sorted_tri_key(q0, q1, q2)
		var tri_c := (v0 + v1 + v2) / 3.0
		var score: float = gn.normalized().dot(tri_c - aabb_center)
		if not best_tri_by_key.has(key):
			best_tri_by_key[key] = tri
			best_score_by_key[key] = score
			tri_order.append(key)
		elif score > float(best_score_by_key[key]):
			best_tri_by_key[key] = tri
			best_score_by_key[key] = score

	# 2. Verificar volumen signado local (en Godot front-face es CW => (v2-v0)x(v1-v0) apunta hacia afuera)
	var kept_tris: Array[Vector3i] = []
	var loc_vol: float = 0.0
	for key in tri_order:
		var tri: Vector3i = best_tri_by_key[key]
		kept_tris.append(tri)
		var v0 := all_verts[tri.x] - aabb_center
		var v1 := all_verts[tri.y] - aabb_center
		var v2 := all_verts[tri.z] - aabb_center
		loc_vol += v0.dot((v2 - v0).cross(v1 - v0)) / 6.0

	var flip_winding: bool = loc_vol < -1e-4

	# 3. Construir índices consistentes y normales suaves 100% geométricas ponderadas por ángulo
	var all_indices := PackedInt32Array()
	all_indices.resize(kept_tris.size() * 3)
	var accum_norms: Dictionary = {}
	var out_i := 0
	for tri in kept_tris:
		var i0 := tri.x
		var i1 := tri.z if flip_winding else tri.y
		var i2 := tri.y if flip_winding else tri.z
		all_indices[out_i] = i0
		all_indices[out_i + 1] = i1
		all_indices[out_i + 2] = i2
		out_i += 3

		var v0 := all_verts[i0]
		var v1 := all_verts[i1]
		var v2 := all_verts[i2]
		var fn := (v2 - v0).cross(v1 - v0)
		var fn_len := fn.length()
		if fn_len <= 1e-9:
			continue
		fn /= fn_len
		var e01 := (v1 - v0).normalized()
		var e02 := (v2 - v0).normalized()
		var e12 := (v2 - v1).normalized()
		var w0 := acos(clampf(e01.dot(e02), -1.0, 1.0))
		var w1 := acos(clampf((-e01).dot(e12), -1.0, 1.0))
		var w2 := acos(clampf((-e02).dot(-e12), -1.0, 1.0))
		_accum_qnorm(accum_norms, v0, fn * maxf(w0, 0.01))
		_accum_qnorm(accum_norms, v1, fn * maxf(w1, 0.01))
		_accum_qnorm(accum_norms, v2, fn * maxf(w2, 0.01))

	if all_indices.is_empty():
		_outline_mesh_cache[mid] = src_mesh
		return src_mesh

	var smooth_norms := PackedVector3Array()
	smooth_norms.resize(all_verts.size())
	for k in range(all_verts.size()):
		var qk := _quantize_pos(all_verts[k])
		var n: Vector3 = accum_norms.get(qk, Vector3.ZERO)
		if n.length_squared() > 0.000001:
			smooth_norms[k] = n.normalized()
		else:
			var fallback := all_verts[k] - aabb_center
			smooth_norms[k] = fallback.normalized() if fallback.length_squared() > 1e-6 else Vector3.UP

	var merged := ArrayMesh.new()
	var out_arr: Array = []
	out_arr.resize(Mesh.ARRAY_MAX)
	out_arr[Mesh.ARRAY_VERTEX] = all_verts
	out_arr[Mesh.ARRAY_NORMAL] = smooth_norms
	out_arr[Mesh.ARRAY_INDEX] = all_indices
	merged.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out_arr)
	_outline_mesh_cache[mid] = merged
	return merged

func _quantize_pos(v: Vector3) -> Vector3i:
	return Vector3i(roundi(v.x * 5000.0), roundi(v.y * 5000.0), roundi(v.z * 5000.0))

func _quantize_pos_coarse(v: Vector3) -> Vector3i:
	return Vector3i(roundi(v.x * 1000.0), roundi(v.y * 1000.0), roundi(v.z * 1000.0))

func _sorted_tri_key(a: Vector3i, b: Vector3i, c: Vector3i) -> String:
	var p0 := a
	var p1 := b
	var p2 := c
	if p1 < p0:
		var tmp := p0; p0 = p1; p1 = tmp
	if p2 < p1:
		var tmp := p1; p1 = p2; p2 = tmp
	if p1 < p0:
		var tmp := p0; p0 = p1; p1 = tmp
	return "%d,%d,%d|%d,%d,%d|%d,%d,%d" % [p0.x, p0.y, p0.z, p1.x, p1.y, p1.z, p2.x, p2.y, p2.z]

func _accum_qnorm(dict: Dictionary, v: Vector3, n: Vector3) -> void:
	var qk := _quantize_pos(v)
	dict[qk] = (dict.get(qk, Vector3.ZERO) as Vector3) + n

func _ensure_shells_for_group(group_key: String, meshes: Array) -> void:
	var list: Array = _shells_by_group[group_key]
	list.clear()
	for item in meshes:
		var mi := item as MeshInstance3D
		if mi == null or not is_instance_valid(mi) or mi.mesh == null:
			continue
		if group_key == "locker":
			# Contorno únicamente en los gabinetes externos principales (14 mallas en lugar de 114):
			# evita ruido interno, elimina ~100 draw calls y mantiene el borde nítido alrededor de los lockers.
			if mi.get_meta("merged_into_batch", false) or str(mi.name).begins_with("MergedLocker"):
				continue
			if not str(mi.name).begins_with("Geom3D_3_WZSLOT"):
				continue
		var shell := mi.get_node_or_null("GlowOutlineShell") as MeshInstance3D
		if shell == null:
			shell = MeshInstance3D.new()
			shell.name = "GlowOutlineShell"
			shell.mesh = _get_or_build_outline_mesh(mi.mesh)
			shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			shell.visibility_range_end = 36.0
			shell.visibility_range_end_margin = 4.0
			shell.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			mi.add_child(shell)
		var mirrored := mi.global_transform.basis.determinant() < 0.0
		list.append({"shell": shell, "mirrored": mirrored})

func register_breaker_meshes() -> void:
	if _breaker_node == null or not is_instance_valid(_breaker_node):
		var sr := get_parent()
		if sr != null:
			_breaker_node = sr.find_child("PhysicalBreakerPanel", true, false)
	if _breaker_node != null:
		var b_meshes: Array[MeshInstance3D] = []
		_append_subtree_meshes(_breaker_node, b_meshes, ["FaultSparksBreaker"])
		_meshes_by_group["breaker"] = b_meshes
		for m_item in b_meshes:
			_mesh_to_group[m_item.get_instance_id()] = "breaker"
		_ensure_shells_for_group("breaker", b_meshes)
		_cache_group_bounds_and_rids("breaker", b_meshes)
		refresh_highlights(true)

func _setup_fault_sparks(scene_root: Node) -> void:
	_sparks_by_group.clear()
	var legacy_names := {
		"motor": "FaultSparksMotor",
		"hopper": "FaultSparksHopper",
		"breaker": "FaultSparksBreaker",
		"cyclone": "FaultSparksCyclone"
	}
	var legacy_pos := {
		"motor": Vector3(-25.81, 2.09, 42.60),
		"hopper": Vector3(-26.11, 2.59, 46.60),
		"breaker": Vector3(-20.48, 1.52, 38.50),
		"cyclone": Vector3(-25.98, 3.14, 29.15)
	}
	for g in MACHINE_GROUPS:
		var spark_name := str(legacy_names.get(g, "FaultSparks_" + g))
		var pos: Vector3 = legacy_pos.get(g, Vector3(-25.0, 2.0, 38.0))
		var ext := Vector3(1.1, 1.1, 1.1)
		if _group_aabbs.has(g):
			var box: AABB = _group_aabbs[g]
			pos = box.get_center()
			ext = Vector3(
				clampf(box.size.x * 0.35, 0.35, 1.6),
				clampf(box.size.y * 0.35, 0.35, 1.5),
				clampf(box.size.z * 0.35, 0.35, 1.6)
			)
		_sparks_by_group[g] = _create_fault_spark_emitter(scene_root, spark_name, pos, ext)

func _create_fault_spark_emitter(parent_n: Node, node_name: String, pos: Vector3, extents: Vector3) -> GPUParticles3D:
	var existing := parent_n.get_node_or_null(node_name) as GPUParticles3D
	if existing != null:
		return existing
	var p := GPUParticles3D.new()
	p.name = node_name
	p.position = pos
	p.amount = 22
	p.lifetime = 1.15
	p.emitting = false

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = extents
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 35.0
	pm.initial_velocity_min = 0.25
	pm.initial_velocity_max = 0.75
	pm.gravity = Vector3(0.0, 0.35, 0.0)
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	p.process_material = pm

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color(1.0, 0.25, 0.16, 1.0)
	var qm := QuadMesh.new()
	qm.size = Vector2(0.055, 0.055)
	qm.material = mat
	p.draw_pass_1 = qm
	parent_n.add_child(p)
	return p

func _connect_events() -> void:
	var bus = get_node_or_null("/root/EventBus")
	if bus == null:
		return
	var cb := Callable(self, "_on_event_refresh")
	for sig_name in [
		"fault_injected", "conductor_repaired_event", "bolt_loosened", "ventilation_blocked",
		"epp_state_changed", "sst_course_mode_selected", "sst_course_completed_event",
		"tutorial_station_reached", "golden_rules_completed", "induction_briefing_closed"
	]:
		if bus.has_signal(sig_name) and not bus.is_connected(sig_name, cb):
			bus.connect(sig_name, cb)

	if bus.has_signal("ai_alert_received") and not bus.is_connected("ai_alert_received", _on_ai_alert):
		bus.connect("ai_alert_received", _on_ai_alert)
	if bus.has_signal("notification_posted") and not bus.is_connected("notification_posted", _on_notification_posted):
		bus.connect("notification_posted", _on_notification_posted)
	if bus.has_signal("fault_resolved") and not bus.is_connected("fault_resolved", _on_fault_resolved):
		bus.connect("fault_resolved", _on_fault_resolved)
	if bus.has_signal("emergency_stop_triggered") and not bus.is_connected("emergency_stop_triggered", _on_estop_changed):
		bus.connect("emergency_stop_triggered", _on_estop_changed)
	if bus.has_signal("emergency_stop_reset") and not bus.is_connected("emergency_stop_reset", _on_estop_reset):
		bus.connect("emergency_stop_reset", _on_estop_reset)
	if bus.has_signal("breaker_changed") and not bus.is_connected("breaker_changed", _on_breaker_changed):
		bus.connect("breaker_changed", _on_breaker_changed)
	if bus.has_signal("hopper_overfed") and not bus.is_connected("hopper_overfed", _on_hopper_overfed):
		bus.connect("hopper_overfed", _on_hopper_overfed)
	if bus.has_signal("safety_line_crossed") and not bus.is_connected("safety_line_crossed", _on_safety_line_crossed):
		bus.connect("safety_line_crossed", _on_safety_line_crossed)

func _on_event_refresh(_a = null, _b = null, _c = null) -> void:
	refresh_highlights(false)

func _on_ai_alert(alert_data: Dictionary) -> void:
	_ai_severity = str(alert_data.get("severity", "NORMAL")).to_upper()
	_ai_class = str(alert_data.get("predicted_class", "NORMAL")).to_upper()
	_ai_mhi = float(alert_data.get("mhi", 98.0))
	refresh_highlights(false)

func _on_notification_posted(title: String, message: String, severity: String) -> void:
	var sev := severity.to_lower()
	var txt := (title + " " + message).to_upper()
	if sev == "warning":
		if "TOLVA" in txt or "CAUDAL" in txt or "SINFÍN" in txt or "CEREAL" in txt:
			_group_warnings["hopper"] = true
		elif "CCM" in txt or "LOTO" in txt or "BREAKER" in txt or "TENSIÓN" in txt:
			_group_warnings["breaker"] = true
		elif "ATEX" in txt or "POLVO" in txt or "CICLÓN" in txt:
			_group_warnings["cyclone"] = true
		elif "EPP" in txt or "LOCKER" in txt or "VESTIDOR" in txt:
			_group_warnings["locker"] = true
		elif "CAMIÓN" in txt or "DESPACHO" in txt:
			_group_warnings["truck"] = true
		elif "SACO" in txt or "ALMACÉN" in txt:
			_group_warnings["bag"] = true
		elif "MOTOR" in txt or "TÉRMICA" in txt or "VENTILA" in txt or "VIBRA" in txt or "SOBRECARGA" in txt:
			_group_warnings["motor"] = true
	refresh_highlights(false)

func _on_fault_resolved(fault_code: String) -> void:
	var c := fault_code.to_upper()
	if "TOLVA" in c:
		_group_warnings["hopper"] = false
	elif "CCM" in c or "TENSION" in c:
		_group_warnings["breaker"] = false
	else:
		_group_warnings["motor"] = false
	for pk in PROCESS_FAULT_SPECS.keys():
		if str((PROCESS_FAULT_SPECS[pk] as Dictionary).get("code", "")).to_upper() == c:
			_process_faults[pk] = false
			_group_warnings[pk] = false
	_sync_process_effects_to_motor()
	refresh_highlights(false)

func _on_estop_changed(_src: String) -> void:
	refresh_highlights(false)

func _on_estop_reset() -> void:
	_group_warnings.clear()
	for g in ALL_GROUPS:
		_group_warnings[g] = false
	refresh_highlights(false)

func _on_breaker_changed(_id: String, active: bool) -> void:
	if active:
		_group_warnings["breaker"] = false
	refresh_highlights(false)

func _on_hopper_overfed(kg_s: float) -> void:
	if kg_s <= 1.05:
		_group_warnings["hopper"] = false
		_group_warnings["cyclone"] = false
	refresh_highlights(false)

func _on_safety_line_crossed(active: bool, zone_id: String, _title: String, _message: String) -> void:
	_crossed_hazard_zone_id = zone_id if active else ""
	refresh_highlights(true)

func _process(delta: float) -> void:
	_sync_timer += delta
	_occlusion_timer += delta
	if _sync_timer >= 0.25 or _occlusion_timer >= 0.25:
		_occlusion_timer = 0.0
		_sync_timer = 0.0
		refresh_highlights(false)

func _prop_bool(obj: Object, prop: String) -> bool:
	if obj == null or not is_instance_valid(obj):
		return false
	var v = obj.get(prop)
	return v is bool and v

func _prop_float(obj: Object, prop: String, fallback: float = 0.0) -> float:
	if obj == null or not is_instance_valid(obj):
		return fallback
	var v = obj.get(prop)
	return float(v) if (v is float or v is int) else fallback

func is_motor_fault_active() -> bool:
	return _compute_equipment_state("motor") == GlowState.RED

func is_hopper_fault_active() -> bool:
	return _compute_equipment_state("hopper") == GlowState.RED

func is_breaker_fault_active() -> bool:
	return _compute_equipment_state("breaker") == GlowState.RED

func _is_motor_stopped_or_isolated() -> bool:
	if _motor_node == null:
		return false
	if _prop_bool(_motor_node, "is_e_stop_engaged") or _prop_bool(_motor_node, "is_loto_isolated"):
		return true
	if not _prop_bool(_motor_node, "is_running"):
		if not _post_tutorial_active:
			return false
		return true
	return false

func _compute_equipment_state(group_key: String) -> int:
	var motor_stopped := _is_motor_stopped_or_isolated()
	var motor_temp := _prop_float(_motor_node, "winding_temp_c", 28.0)
	var motor_vib := _prop_float(_motor_node, "vibration_rms_mm_s", 0.0)
	var motor_volt := _prop_float(_motor_node, "current_voltage", 460.0)
	var motor_irms := _prop_float(_motor_node, "current_rms", 0.0)
	var hopper_jam := _prop_bool(_hopper_node, "is_jammed") or _prop_float(_hopper_node, "manual_gate_opening_pct", 80.0) > 120.0
	var hopper_gate := _prop_float(_hopper_node, "manual_gate_opening_pct", 80.0)
	var hopper_flow := _prop_float(_hopper_node, "current_feed_rate", 0.8)

	match group_key:
		"motor":
			if motor_stopped:
				return GlowState.RED
			if _prop_bool(_cable_node, "is_cut") or _prop_bool(_motor_node, "is_phase_l3_cut") or _prop_bool(_motor_node, "is_mechanical_jammed"):
				return GlowState.RED
			if motor_temp >= 100.0 or motor_vib >= 4.5 or (motor_volt > 0.0 and motor_volt < 400.0):
				return GlowState.RED
			if _ai_severity == "CRITICAL" and _ai_class != "SOBRECALENTAMIENTO":
				return GlowState.RED
			if _prop_bool(_bolt_node, "is_loosened") or _prop_bool(_motor_node, "is_bolts_loosened"):
				return GlowState.RED if motor_vib >= 3.5 else GlowState.YELLOW
			if _prop_bool(_vent_node, "is_blocked") or _prop_bool(_motor_node, "is_cooling_blocked"):
				return GlowState.RED if motor_temp >= 100.0 else GlowState.YELLOW
			if motor_temp >= 68.0 or motor_vib >= 2.3 or (motor_volt >= 400.0 and motor_volt < 438.0):
				return GlowState.YELLOW
			if _ai_severity == "WARNING" or _ai_mhi < 85.0 or bool(_group_warnings.get("motor", false)):
				return GlowState.YELLOW
			return GlowState.WHITE

		"hopper":
			if hopper_jam or _prop_bool(_motor_node, "is_mechanical_jammed") or motor_stopped:
				return GlowState.RED
			if hopper_gate > 95.0 or hopper_flow > 1.05 or bool(_group_warnings.get("hopper", false)):
				return GlowState.YELLOW
			return GlowState.WHITE

		"breaker":
			if _breaker_node != null:
				var bs = _breaker_node.get("breaker_state")
				if (bs is int and int(bs) != 0) or not _prop_bool(_breaker_node, "l3_active"):
					return GlowState.RED
			if _prop_bool(_motor_node, "is_e_stop_engaged") or _prop_bool(_motor_node, "is_loto_isolated"):
				return GlowState.RED
			if motor_volt < 400.0:
				return GlowState.RED
			var motor_steady := _prop_float(_motor_node, "rotor_speed_rpm", 0.0) >= 1350.0
			if motor_volt < 438.0 or (motor_steady and motor_irms > 19.5) or bool(_group_warnings.get("breaker", false)):
				return GlowState.YELLOW
			return GlowState.WHITE

		"cyclone":
			if bool(_process_faults.get("cyclone", false)) or motor_stopped:
				return GlowState.RED
			if hopper_gate > 95.0 or hopper_flow > 1.05 or motor_temp >= 75.0 or bool(_group_warnings.get("cyclone", false)):
				return GlowState.YELLOW
			return GlowState.WHITE

		"locker":
			if _is_epp_active():
				return GlowState.HIDDEN
			if _post_tutorial_active and _locker_node != null and not _prop_bool(_locker_node, "epp_equipped"):
				return GlowState.YELLOW
			if bool(_group_warnings.get("locker", false)):
				return GlowState.YELLOW
			return GlowState.WHITE

		"bag":
			return GlowState.HIDDEN

		"truck":
			return GlowState.HIDDEN

		_:
			if PROCESS_FAULT_SPECS.has(group_key):
				if bool(_process_faults.get(group_key, false)) or motor_stopped:
					return GlowState.RED
				if hopper_jam or bool(_group_warnings.get(group_key, false)):
					return GlowState.YELLOW
				return GlowState.WHITE

	return GlowState.WHITE

func _is_epp_active() -> bool:
	if _locker_node != null and is_instance_valid(_locker_node):
		if _prop_bool(_locker_node, "epp_equipped"):
			return true
	if _tutorial_node != null and is_instance_valid(_tutorial_node):
		if _prop_bool(_tutorial_node, "epp_completed"):
			return true
	return false

func _is_post_tutorial() -> bool:
	if _tutorial_node != null and is_instance_valid(_tutorial_node) and _tutorial_node.has_method("is_tutorial_glow_unlocked"):
		return bool(_tutorial_node.is_tutorial_glow_unlocked())
	return true

func _get_visible_groups() -> Array[String]:
	var groups: Array[String] = []
	if _tutorial_node != null and is_instance_valid(_tutorial_node) and _tutorial_node.has_method("get_active_tutorial_glow_groups"):
		groups = _tutorial_node.get_active_tutorial_glow_groups()
	else:
		groups = ALL_GROUPS.duplicate()
	if _is_epp_active() and groups.has("locker"):
		groups.erase("locker")
	return groups

func _is_group_occluded_by_wall(cam: Camera3D, space: PhysicsDirectSpaceState3D, group_key: String) -> bool:
	if cam == null or space == null:
		return false
	if group_key == "truck":
		_cache_group_bounds_and_rids("truck", _meshes_by_group.get("truck", []))
	if not _group_aabbs.has(group_key):
		return false

	var box: AABB = _group_aabbs[group_key]
	var c := box.get_center()
	var origin := cam.global_position
	var dist_c := origin.distance_to(c)
	if dist_c > 65.0 or cam.is_position_behind(c):
		return false
	var ext := box.size * 0.34
	var samples: Array[Vector3] = [
		c,
		Vector3(c.x - ext.x, c.y + ext.y * 0.25, c.z),
		Vector3(c.x + ext.x, c.y + ext.y * 0.25, c.z),
		Vector3(c.x, c.y + ext.y * 0.45, c.z - ext.z),
		Vector3(c.x, c.y + ext.y * 0.45, c.z + ext.z)
	]

	var exclude: Array[RID] = []
	# Excluir colisionadores de todas las máquinas y equipos internos de la planta
	# para que los rayos de oclusión solo detecten muros/paredes estructurales reales
	for gk in ALL_GROUPS:
		for r in (_group_exclude_rids.get(gk, []) as Array):
			if not exclude.has(r):
				exclude.append(r)

	var sr := get_parent()
	if sr != null:
		var plat_node := sr.find_child("Geom3D715", true, false)
		if plat_node != null:
			_collect_self_rids(plat_node, exclude)

	var player := sr.find_child("PlayerOperator", true, false) if sr else null
	if player is CollisionObject3D:
		exclude.append((player as CollisionObject3D).get_rid())
	if is_inside_tree():
		for wk in get_tree().get_nodes_in_group("workers"):
			if wk is CollisionObject3D:
				exclude.append((wk as CollisionObject3D).get_rid())

	var blocked_hits := 0
	var safe_box := box.grow(0.60)
	for pt in samples:
		var dist_to_pt := origin.distance_to(pt)
		if dist_to_pt <= 0.8:
			continue
		var q := PhysicsRayQueryParameters3D.create(origin, pt, 1, exclude)
		var hit: Dictionary = space.intersect_ray(q)
		if not hit.is_empty():
			var hpos: Vector3 = hit["position"]
			if not safe_box.has_point(hpos):
				var hit_dist := origin.distance_to(hpos)
				if hit_dist < dist_to_pt - maxf(0.85, ext.length() * 0.45):
					blocked_hits += 1

	return blocked_hits >= 3

func set_hovered_machine_group(group_key: String, target_node: Node = null) -> void:
	var normalized := group_key if (_is_post_tutorial() and MACHINE_GROUPS.has(group_key)) else ""
	_hovered_target_node = target_node if normalized != "" else null
	if _hovered_machine_group != normalized:
		_hovered_machine_group = normalized
		refresh_highlights(false)

func get_hovered_machine_group() -> String:
	return _hovered_machine_group

func has_active_green_selection() -> bool:
	if not _is_post_tutorial() or _hovered_machine_group == "":
		return false
	var st: int = int(_last_states.get(_hovered_machine_group, GlowState.HIDDEN))
	return st == GlowState.GREEN or st == GlowState.RED_HOVER

func update_hover_from_camera(cam: Camera3D, screen_pos: Vector2, max_dist: float = 30.0, player_rid: RID = RID()) -> String:
	if not _is_post_tutorial():
		set_hovered_machine_group("")
		return ""
	if cam == null or not is_inside_tree() or get_parent() == null:
		set_hovered_machine_group("")
		return ""
	var p_node := get_parent() as Node3D
	if p_node == null or p_node.get_world_3d() == null:
		set_hovered_machine_group("")
		return ""

	var ray_origin := cam.project_ray_origin(screen_pos)
	var ray_dir := cam.project_ray_normal(screen_pos)
	if ray_dir.length_squared() < 0.0001:
		set_hovered_machine_group("")
		return ""
	ray_dir = ray_dir.normalized()

	var exclude: Array[RID] = []
	if player_rid.is_valid():
		exclude.append(player_rid)
	var space := p_node.get_world_3d().direct_space_state

	# 1. Rayo sólido únicamente contra cuerpos físicos (muros, equipos StaticBody, operarios/puertas).
	# Nunca permite que Area3D de zonas en el suelo bloqueen el puntero del mouse.
	if is_inside_tree():
		for wk in get_tree().get_nodes_in_group("workers"):
			if wk is CollisionObject3D:
				exclude.append((wk as CollisionObject3D).get_rid())
	var q_body := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_dir * max_dist, 3, exclude)
	q_body.collide_with_areas = false
	q_body.collide_with_bodies = true
	var hit := space.intersect_ray(q_body)

	var max_unoccluded_dist := max_dist
	var col_group := ""
	var col_target: Node = null
	var col_dist := max_dist + 1.0
	if not hit.is_empty():
		var hit_dist := ray_origin.distance_to(hit["position"])
		max_unoccluded_dist = hit_dist
		var col := hit.get("collider") as Node
		if col != null:
			if hit_dist <= 3.0 and _is_non_machine_priority_interactable(col):
				set_hovered_machine_group("")
				return ""
			var matched := _find_machine_group_and_node_for_collider(col)
			if str(matched.get("group", "")) != "":
				col_group = str(matched["group"])
				col_target = matched.get("target") as Node
				col_dist = hit_dist

	# 2. Rayo complementario contra Areas de interacción de equipos (Perno, Rejilla, Cable, CCM) ignorando zonas de piso
	var area_exclude := exclude.duplicate()
	var area_limit := ray_origin + ray_dir * minf(max_dist, max_unoccluded_dist + 0.05)
	for _it in range(12):
		var q_area := PhysicsRayQueryParameters3D.create(ray_origin, area_limit, 3, area_exclude)
		q_area.collide_with_areas = true
		q_area.collide_with_bodies = false
		var ahit := space.intersect_ray(q_area)
		if ahit.is_empty():
			break
		var acol := ahit.get("collider") as Node
		var adist := ray_origin.distance_to(ahit["position"])
		if acol != null:
			if adist <= 3.0 and _is_non_machine_priority_interactable(acol):
				set_hovered_machine_group("")
				return ""
			var amatched := _find_machine_group_and_node_for_collider(acol)
			if str(amatched.get("group", "")) != "":
				if adist < col_dist + 0.05:
					col_group = str(amatched["group"])
					col_target = amatched.get("target") as Node
					col_dist = adist
				break
			area_exclude.append(ahit["rid"])
		else:
			break

	var visible_groups := _get_visible_groups()
	var seg_end := ray_origin + ray_dir * minf(max_dist, max_unoccluded_dist + 0.35)
	var aabb_group := ""
	var aabb_target: Node = null
	var aabb_dist := max_dist + 1.0

	for g in MACHINE_GROUPS:
		if not visible_groups.has(g):
			continue
		if _group_aabbs.has(g):
			var grp_box: AABB = (_group_aabbs[g] as AABB).grow(0.18)
			if grp_box.intersects_segment(ray_origin, seg_end) == null:
				continue
		for item in (_meshes_by_group.get(g, []) as Array):
			var mi := item as MeshInstance3D
			if mi == null or not is_instance_valid(mi) or mi.mesh == null or not mi.is_visible_in_tree():
				continue
			var wbox: AABB = (mi.global_transform * mi.mesh.get_aabb()).grow(0.07)
			var pt = wbox.intersects_segment(ray_origin, seg_end)
			if pt is Vector3:
				var d := ray_origin.distance_to(pt as Vector3)
				if d < aabb_dist:
					aabb_dist = d
					aabb_group = g
					aabb_target = mi

	var chosen_group := ""
	var chosen_node: Node = null
	if col_group != "" and visible_groups.has(col_group) and col_dist <= aabb_dist + 0.35:
		chosen_group = col_group
		chosen_node = col_target
	elif aabb_group != "":
		chosen_group = aabb_group
		chosen_node = aabb_target

	set_hovered_machine_group(chosen_group, chosen_node)
	return chosen_group

func _is_non_machine_priority_interactable(node: Node) -> bool:
	var curr := node
	for _depth in range(6):
		if curr == null:
			break
		if curr is WorkerNPC or curr is InteractiveDoor or curr is InteractiveGrainBag or "epp_equipped" in curr:
			return true
		curr = curr.get_parent()
	return false

func _find_machine_group_and_node_for_collider(col: Node) -> Dictionary:
	var curr := col
	for _depth in range(8):
		if curr == null:
			break
		if curr == _breaker_node or curr is PhysicalBreakerPanel:
			return {"group": "breaker", "target": curr}
		if curr == _hopper_node or curr is PhysicalHopperFeeder:
			return {"group": "hopper", "target": curr}
		if curr == _cable_node or curr is PhysicalCableConductor or curr is MechanicalBolt or curr is VentilationCover or curr.name == "MotorMillUnit":
			return {"group": "motor", "target": curr}
		if curr is MeshInstance3D and _mesh_to_group.has(curr.get_instance_id()):
			var gk := str(_mesh_to_group[curr.get_instance_id()])
			if MACHINE_GROUPS.has(gk):
				return {"group": gk, "target": curr}
		curr = curr.get_parent()
	return {}

func _sync_process_effects_to_motor() -> void:
	if _motor_node == null or not is_instance_valid(_motor_node) or not _motor_node.has_method("set_process_fault_effects"):
		return
	var load_d: float = 0.0
	var temp_d: float = 0.0
	var vib_d: float = 0.0
	var flow_s: float = 1.0
	var aux_kw: float = 0.0
	for pk in PROCESS_FAULT_SPECS.keys():
		if not bool(_process_faults.get(pk, false)):
			continue
		var sp: Dictionary = PROCESS_FAULT_SPECS[pk]
		load_d += float(sp.get("load", 0.0))
		temp_d += float(sp.get("temp", 0.0))
		vib_d += float(sp.get("vib", 0.0))
		flow_s *= float(sp.get("flow_scale", 1.0))
		aux_kw += float(sp.get("aux_kw", 0.0))
	_motor_node.set_process_fault_effects(load_d, temp_d, vib_d, maxf(flow_s, 0.15), aux_kw)

func is_machine_fault_active(group_key: String) -> bool:
	return _is_machine_fault_active(group_key)

func _is_machine_fault_active(group_key: String) -> bool:
	match group_key:
		"motor":
			return _prop_bool(_cable_node, "is_cut") or _prop_bool(_vent_node, "is_blocked") or _prop_bool(_bolt_node, "is_loosened") or _prop_bool(_motor_node, "is_mechanical_jammed")
		"hopper":
			return _prop_bool(_hopper_node, "is_jammed") or _prop_float(_hopper_node, "manual_gate_opening_pct", 80.0) > 120.0
		"breaker":
			return _breaker_node != null and (not _prop_bool(_breaker_node, "l3_active") or int(_breaker_node.get("breaker_state")) != 0)
	if PROCESS_FAULT_SPECS.has(group_key):
		return bool(_process_faults.get(group_key, false))
	return false

func get_required_tool_for_action(group_key: String, for_repair: bool) -> int:
	match group_key:
		"motor":
			if _hovered_target_node is VentilationCover:
				return 2
			if _hovered_target_node is MechanicalBolt:
				return 3
			if for_repair:
				if _cable_node != null and _prop_bool(_cable_node, "is_cut"):
					return 5
				if _bolt_node != null and _prop_bool(_bolt_node, "is_loosened"):
					return 3
				if _vent_node != null and _prop_bool(_vent_node, "is_blocked"):
					return 2
				return 5
			return 2
		"hopper":
			return 3
		"breaker":
			return 5 if for_repair else 2
	if PROCESS_FAULT_SPECS.has(group_key):
		var sp: Dictionary = PROCESS_FAULT_SPECS[group_key]
		return int(sp["repair_tool"] if for_repair else sp["induce_tool"])
	return 3

func _build_interaction_plan(group_key: String, tool_id: int) -> Dictionary:
	var label := str(MACHINE_DISPLAY_NAMES.get(group_key, group_key))
	if group_key == "motor":
		if _hovered_target_node is VentilationCover:
			var blk := _prop_bool(_vent_node, "is_blocked")
			return {
				"allowed": [2], "pref": 2, "label": "Rejilla Ventilación Motor 10 HP",
				"desc": "Despejar rejilla" if blk else "Obstruir rejilla térmica",
				"fault": blk
			}
		if _hovered_target_node is MechanicalBolt:
			var lsn := _prop_bool(_bolt_node, "is_loosened")
			return {
				"allowed": [3], "pref": 3, "label": "Perno Bancada Motor 10 HP",
				"desc": "Apretar perno 3/4\"" if lsn else "Aflojar perno (vibración)",
				"fault": lsn
			}
		if _is_machine_fault_active("motor"):
			var req_r := get_required_tool_for_action("motor", true)
			return {
				"allowed": [req_r], "pref": req_r, "label": label,
				"desc": "Reparar / Despejar falla en Motor 10 HP",
				"fault": true
			}
		return {
			"allowed": [2, 3], "pref": (3 if tool_id == 3 else 2), "label": label,
			"desc": "Aflojar perno bancada" if tool_id == 3 else "Cortar fase L3",
			"fault": false
		}
	if group_key == "hopper":
		var hf := _is_machine_fault_active("hopper")
		return {
			"allowed": [3], "pref": 3, "label": label,
			"desc": "Desatascar Tolva (80%)" if hf else "Forzar compuerta 160% (Sobrecarga)",
			"fault": hf
		}
	if group_key == "breaker":
		var bf := _is_machine_fault_active("breaker")
		if bf:
			return {
				"allowed": [3, 5], "pref": 5, "label": label,
				"desc": "Retirar LOTO y rearmar Breaker 460 V",
				"fault": true
			}
		return {
			"allowed": [2, 3], "pref": (3 if tool_id == 3 else 2), "label": label,
			"desc": "Disparar Breaker L3 (Bajón 340 V)",
			"fault": false
		}
	if PROCESS_FAULT_SPECS.has(group_key):
		var sp: Dictionary = PROCESS_FAULT_SPECS[group_key]
		var pf := bool(_process_faults.get(group_key, false))
		var req := int(sp["repair_tool"] if pf else sp["induce_tool"])
		return {
			"allowed": [req], "pref": req, "label": label,
			"desc": str(sp["repair_desc"] if pf else sp["induce_desc"]),
			"fault": pf
		}
	return {"allowed": [3], "pref": 3, "label": label, "desc": "Intervenir equipo", "fault": false}

func get_hover_selection_prompt(tool_id: int) -> String:
	if not _is_post_tutorial() or _hovered_machine_group == "":
		return ""
	var plan := _build_interaction_plan(_hovered_machine_group, tool_id)
	var pref: int = int(plan["pref"])
	var is_fault := bool(plan["fault"])
	var tool_name := str(TOOL_CLEAN_NAMES.get(pref, "Herramienta"))
	if is_fault:
		var sm := get_node_or_null("/root/SimulationManager")
		if sm != null and sm.has_method("are_machines_stopped") and not bool(sm.are_machines_stopped()):
			return "Detén las máquinas (TAB) para reparar · %s" % tool_name
		return "Reparar falla · %s" % tool_name
	return "Inducir falla · %s" % tool_name

func induce_fault_for_hovered_machine(tool_id: int = 1) -> String:
	if not _is_post_tutorial() or _hovered_machine_group == "":
		return ""
	var plan := _build_interaction_plan(_hovered_machine_group, tool_id)
	var is_repair_action := bool(plan["fault"])
	if _hovered_machine_group == "motor":
		if _hovered_target_node is VentilationCover and _vent_node != null and _prop_bool(_vent_node, "is_blocked"):
			is_repair_action = true
		elif _hovered_target_node is MechanicalBolt and _bolt_node != null and _prop_bool(_bolt_node, "is_loosened"):
			is_repair_action = true
	if is_repair_action:
		var sm := get_node_or_null("/root/SimulationManager")
		if sm != null and sm.has_method("are_machines_stopped") and not bool(sm.are_machines_stopped()):
			return String(sm.notify_repair_blocked_machines_running(str(plan["label"])))
	var allowed: Array = plan["allowed"]
	if not allowed.has(tool_id):
		var pref: int = int(plan["pref"])
		return "Usa %s para %s." % [
			str(TOOL_CLEAN_NAMES.get(pref, "otra herramienta")), str(plan["desc"]).to_lower()
		]

	var msg := ""
	match _hovered_machine_group:
		"motor":
			if _hovered_target_node is VentilationCover and _vent_node != null and _vent_node.has_method("set_blocked"):
				var next_blk := not _prop_bool(_vent_node, "is_blocked")
				_vent_node.set_blocked(next_blk)
				msg = "Falla térmica inducida con Alicates: rejilla obstruida." if next_blk else "Obstrucción de ventilación retirada con Alicates."
			elif _hovered_target_node is MechanicalBolt and _bolt_node != null and _bolt_node.has_method("set_loosened"):
				var next_l := not _prop_bool(_bolt_node, "is_loosened")
				_bolt_node.set_loosened(next_l)
				msg = "Falla mecánica inducida con Llave 3/4\": perno aflojado." if next_l else "Perno apretado a torque nominal con Llave 3/4\"."
			elif _is_machine_fault_active("motor"):
				_group_warnings["motor"] = false
				if _cable_node != null and _prop_bool(_cable_node, "is_cut"):
					_cable_node.repair_cable()
				elif _bolt_node != null and _prop_bool(_bolt_node, "is_loosened"):
					_bolt_node.set_loosened(false)
				elif _vent_node != null and _prop_bool(_vent_node, "is_blocked"):
					_vent_node.set_blocked(false)
				msg = "Falla despejada en Trituradora + Motor 10 HP."
			elif tool_id == 3 and _bolt_node != null:
				_bolt_node.set_loosened(true)
				msg = "Falla mecánica inducida en Trituradora / Motor 10 HP: perno aflojado con Llave 3/4\"."
			elif _cable_node != null and _cable_node.has_method("cut_cable"):
				_cable_node.cut_cable()
				msg = "Falla eléctrica inducida en Motor 10 HP: corte físico Fase L3 con Alicates."
		"hopper":
			if _hopper_node != null:
				if _is_machine_fault_active("hopper"):
					_group_warnings["hopper"] = false
					_hopper_node.clear_jam()
					msg = "03 · Tolva desatascada y normalizada al 80% con Llave 3/4\"."
				else:
					_hopper_node.set_gate_opening(160.0)
					msg = "Falla inducida en 03 · Tolva: compuerta forzada al 160% con Llave 3/4\" (4.5 kg/s)."
		"breaker":
			if _breaker_node != null:
				if _is_machine_fault_active("breaker"):
					_group_warnings["breaker"] = false
					if not _prop_bool(_breaker_node, "is_door_open") and _breaker_node.has_method("toggle_door"):
						_breaker_node.toggle_door()
					if _breaker_node.has_method("set_main_disconnect_isolated") and int(_breaker_node.get("breaker_state")) == 2:
						_breaker_node.set_main_disconnect_isolated(false)
					elif _breaker_node.has_method("toggle_breaker_l3"):
						_breaker_node.toggle_breaker_l3()
					msg = "Tablero CCM 460 V rearmado a tensión nominal."
				else:
					if not _prop_bool(_breaker_node, "is_door_open") and _breaker_node.has_method("toggle_door"):
						_breaker_node.toggle_door()
					if _breaker_node.has_method("toggle_breaker_l3"):
						_breaker_node.toggle_breaker_l3()
					msg = "Falla eléctrica inducida en Tablero CCM: apertura de Breaker L3 (bajón 340 V)."
		_:
			if PROCESS_FAULT_SPECS.has(_hovered_machine_group):
				var sp: Dictionary = PROCESS_FAULT_SPECS[_hovered_machine_group]
				var next_fault := not bool(_process_faults.get(_hovered_machine_group, false))
				_process_faults[_hovered_machine_group] = next_fault
				_group_warnings[_hovered_machine_group] = next_fault
				_sync_process_effects_to_motor()
				var bus = get_node_or_null("/root/EventBus")
				var fcode := str(sp["code"])
				if bus != null:
					if next_fault:
						if bus.has_signal("fault_injected"):
							bus.fault_injected.emit(fcode, true)
						if bus.has_signal("notification_posted"):
							bus.notification_posted.emit(str(sp["fault_title"]), str(sp["fault_msg"]), "error")
					else:
						if bus.has_signal("fault_resolved"):
							bus.fault_resolved.emit(fcode)
						if bus.has_signal("notification_posted"):
							bus.notification_posted.emit(str(sp["repair_title"]), str(sp["repair_msg"]), "info")
				msg = str(sp["fault_msg"] if next_fault else sp["repair_msg"])

	refresh_highlights(true)
	return msg

func refresh_highlights(force: bool = false) -> void:
	_post_tutorial_active = _is_post_tutorial()
	if not _post_tutorial_active:
		_hovered_machine_group = ""
		_hovered_target_node = null
	var visible_groups := _get_visible_groups()

	var tablet_open := _tablet_root != null and is_instance_valid(_tablet_root) and bool(_tablet_root.visible)
	var allow_xray := _post_tutorial_active and not tablet_open
	var cam: Camera3D = get_viewport().get_camera_3d() if (allow_xray and is_inside_tree() and get_viewport() != null) else null
	var space: PhysicsDirectSpaceState3D = (
		get_parent().get_world_3d().direct_space_state
		if (cam != null and get_parent() is Node3D and (get_parent() as Node3D).get_world_3d() != null)
		else null
	)

	var base_states: Dictionary = {}
	var next_states: Dictionary = {}
	var next_occluded: Dictionary = {}
	var changed := force

	for g in ALL_GROUPS:
		var base_st: int = GlowState.HIDDEN
		if visible_groups.has(g):
			if not _post_tutorial_active and g != "locker":
				base_st = GlowState.BLUE_PULSE
			else:
				base_st = _compute_equipment_state(g)
		base_states[g] = base_st
		var disp_st := base_st
		if _post_tutorial_active and base_st != GlowState.HIDDEN and g == _hovered_machine_group:
			if base_st == GlowState.RED:
				disp_st = GlowState.RED_HOVER
			else:
				disp_st = GlowState.GREEN
		var occ: bool = false
		if disp_st != GlowState.HIDDEN and disp_st != GlowState.GREEN and disp_st != GlowState.RED_HOVER and allow_xray and cam != null and space != null:
			occ = _is_group_occluded_by_wall(cam, space, g)
		next_states[g] = disp_st
		next_occluded[g] = occ
		if int(_last_states.get(g, -99)) != disp_st or bool(_last_occluded.get(g, false)) != occ:
			changed = true

	var active_cam: Camera3D = get_viewport().get_camera_3d() if (is_inside_tree() and get_viewport() != null) else null
	if active_cam != null and active_cam.global_position.distance_squared_to(_last_cam_pos) > 4.0:
		changed = true
		_last_cam_pos = active_cam.global_position

	if not changed:
		return

	_last_states = next_states
	_last_occluded = next_occluded

	for g in ALL_GROUPS:
		_apply_group_shells(g, int(next_states[g]), bool(next_occluded[g]))

	for g in MACHINE_GROUPS:
		var sp := _sparks_by_group.get(g) as GPUParticles3D
		if sp != null and is_instance_valid(sp):
			sp.emitting = (int(base_states.get(g, GlowState.HIDDEN)) == GlowState.RED)

	var mach_st := GlowState.WHITE
	for m15 in ORDERED_15_MACHINES:
		var pst := int(base_states.get(m15, GlowState.WHITE))
		if pst == GlowState.RED:
			mach_st = GlowState.RED
			break
		elif pst == GlowState.YELLOW:
			mach_st = GlowState.YELLOW
	if _crossed_hazard_zone_id == "Zone1_Milling_OSHA":
		mach_st = GlowState.RED
	_sync_zone_floor_state("Zone1_Milling_OSHA", mach_st)
	var ccm_zone_st := GlowState.RED if _crossed_hazard_zone_id == "Zone2_CCM460V_RETIE" else int(base_states["breaker"])
	_sync_zone_floor_state("Zone2_CCM460V_RETIE", ccm_zone_st)
	_sync_zone_floor_state("Zone6_DispatchBay", GlowState.RED if _crossed_hazard_zone_id == "Zone6_DispatchBay" else GlowState.WHITE)
	var intake_st := GlowState.RED if (_crossed_hazard_zone_id == "Zone8_IntakeConveyor_OSHA" or int(base_states.get("banda_descarga", GlowState.WHITE)) == GlowState.RED or int(base_states.get("banda_inclinada_tolva", GlowState.WHITE)) == GlowState.RED) else GlowState.WHITE
	_sync_zone_floor_state("Zone8_IntakeConveyor_OSHA", intake_st)
	var atex_st := int(base_states["cyclone"])
	if int(base_states["ciclon_separador"]) == GlowState.RED:
		atex_st = GlowState.RED
	elif atex_st != GlowState.RED and int(base_states["ciclon_separador"]) == GlowState.YELLOW:
		atex_st = GlowState.YELLOW
	_sync_zone_floor_state("Zone7_ATEX_DustZone", atex_st)

func _apply_group_shells(group_key: String, state: int, is_occluded: bool) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d() if (is_inside_tree() and get_viewport() != null) else null
	for item in (_shells_by_group[group_key] as Array):
		var shell := item.get("shell") as MeshInstance3D
		if shell == null or not is_instance_valid(shell):
			continue
		if state == GlowState.HIDDEN:
			shell.visible = false
			shell.material_override = null
			continue
		if state == GlowState.WHITE and cam != null:
			var parent_mi := shell.get_parent() as MeshInstance3D
			var s_pos: Vector3 = parent_mi.global_transform * parent_mi.mesh.get_aabb().get_center() if (parent_mi != null and parent_mi.mesh != null) else shell.global_position
			var d2: float = cam.global_position.distance_squared_to(s_pos)
			if d2 > 676.0 or (d2 > 100.0 and cam.is_position_behind(s_pos)):
				shell.visible = false
				continue
		shell.visible = true
		shell.visibility_range_end = 80.0 if (state == GlowState.GREEN or state == GlowState.RED or state == GlowState.RED_HOVER or state == GlowState.YELLOW or state == GlowState.BLUE_PULSE) else 36.0
		var m_idx := 1 if bool(item.get("mirrored", false)) else 0
		var x_idx := 1 if is_occluded else 0
		shell.material_override = _mats[state][m_idx][x_idx]

	if _machine_labels_by_group.has(group_key):
		var lbl := _machine_labels_by_group[group_key] as Label3D
		if lbl != null and is_instance_valid(lbl):
			lbl.visible = (state != GlowState.HIDDEN)
			lbl.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
			match state:
				GlowState.BLUE_PULSE:
					lbl.modulate = Color(0.42, 0.86, 1.30, 1.0)
				GlowState.GREEN:
					lbl.modulate = Color(0.35, 1.25, 0.65, 1.0)
				GlowState.YELLOW:
					lbl.modulate = Color(1.25, 1.05, 0.30, 1.0)
				GlowState.RED:
					lbl.modulate = Color(1.25, 0.25, 0.25, 1.0)
				GlowState.RED_HOVER:
					lbl.modulate = Color(1.30, 0.65, 0.60, 1.0)
				_:
					lbl.modulate = Color(1.15, 1.15, 1.15, 1.0)

func _sync_zone_floor_state(zone_name: String, state: int) -> void:
	var sr := get_parent()
	if sr == null:
		return
	var z := sr.find_child(zone_name, true, false)
	if z != null:
		var decal := z.get_node_or_null("FloorDecal") as MeshInstance3D
		if decal != null and decal.material_override is ShaderMaterial:
			var sm := decal.material_override as ShaderMaterial
			if state == GlowState.RED:
				sm.set_shader_parameter("fault_pulse", 1.0)
				sm.set_shader_parameter("laser_color", Color(1.0, 0.05, 0.04))
			elif state == GlowState.YELLOW:
				sm.set_shader_parameter("fault_pulse", 1.0)
				sm.set_shader_parameter("laser_color", Color(1.0, 0.72, 0.02))
			else:
				sm.set_shader_parameter("fault_pulse", 0.0)

func get_group_state(group_key: String) -> String:
	var st: int = int(_last_states.get(group_key, GlowState.HIDDEN))
	return str(STATE_NAMES.get(st, "HIDDEN"))

func get_glow_summary() -> Dictionary:
	var states_str: Dictionary = {}
	var occ_copy: Dictionary = {}
	var active_vis: Array[String] = []
	var ordered_meshes: Dictionary = {}
	var ordered_faults: Dictionary = {}
	var all_15_bound := true
	for g in ALL_GROUPS:
		var st_name := get_group_state(g)
		states_str[g] = st_name
		occ_copy[g] = bool(_last_occluded.get(g, false))
		if st_name != "HIDDEN":
			active_vis.append(g)
	for m15 in ORDERED_15_MACHINES:
		var mc: int = (_meshes_by_group.get(m15, []) as Array).size()
		ordered_meshes[m15] = mc
		ordered_faults[m15] = _is_machine_fault_active(m15)
		if mc <= 0:
			all_15_bound = false

	return {
		"motor_meshes": (_meshes_by_group.get("motor", []) as Array).size(),
		"hopper_meshes": (_meshes_by_group.get("hopper", []) as Array).size(),
		"breaker_meshes": (_meshes_by_group.get("breaker", []) as Array).size(),
		"locker_meshes": (_meshes_by_group.get("locker", []) as Array).size(),
		"cyclone_meshes": (_meshes_by_group.get("cyclone", []) as Array).size(),
		"bag_meshes": (_meshes_by_group.get("bag", []) as Array).size(),
		"truck_meshes": (_meshes_by_group.get("truck", []) as Array).size(),
		"ordered_15_meshes": ordered_meshes,
		"ordered_15_faults": ordered_faults,
		"all_15_bound": all_15_bound,
		"motor_fault": is_motor_fault_active(),
		"hopper_fault": is_hopper_fault_active(),
		"breaker_fault": is_breaker_fault_active(),
		"post_tutorial": _post_tutorial_active,
		"xray_enabled": _post_tutorial_active,
		"hovered_machine": _hovered_machine_group,
		"active_spotlight_groups": active_vis,
		"group_states": states_str,
		"occluded_groups": occ_copy
	}
