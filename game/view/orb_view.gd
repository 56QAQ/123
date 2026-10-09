class_name OrbView
extends Node3D
## 晶球：被击杀的敌人掉落，悬浮在地上缓缓旋转；点一下"爆开"并交出战利品。
## 白 / 蓝 / 金三档(金色的更大更亮)，外加极少见的彩色(打工小帮手 0.05%：整颗球流转彩虹色，最大最亮)。白色场景里要一眼能看到：珍珠色球体带彩虹色边缘光，
## 地上一圈深色光环 + 一道淡淡的光柱。

const COLORS := {"white": Color("#f2f6ff"), "blue": Color("#6fb4ff"), "gold": Color("#ffd35a"), "rainbow": Color("#ff8af0")}
## 地面光环/光柱用的颜色(比球体深，才能在白色大理石上看清)
const MARK_COLORS := {"white": Color("#6f82b8"), "blue": Color("#2f7fe0"), "gold": Color("#d99a10"), "rainbow": Color("#b040e0")}

const CORE_SHADER := """
shader_type spatial;
render_mode specular_schlick_ggx;
uniform vec4 base : source_color;
uniform float iridescent = 0.0;
uniform float glow = 1.0;
void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	vec3 rainbow = 0.5 + 0.5 * cos(6.2831 * (vec3(0.0, 0.33, 0.67) + f * 1.3 + TIME * 0.25));
	vec3 rim = mix(base.rgb, rainbow, iridescent);
	ALBEDO = mix(base.rgb, rim * 0.8, f * 0.6);
	EMISSION = base.rgb * 0.35 * glow + rim * f * 1.6 * glow;
	ROUGHNESS = 0.15;
	METALLIC = 0.1;
}
"""

const RING_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 color : source_color;
void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float r = length(q);
	float band = smoothstep(0.62, 0.72, r) * (1.0 - smoothstep(0.86, 0.98, r));
	float fill = (1.0 - smoothstep(0.0, 0.7, r)) * 0.25;
	ALBEDO = color.rgb;
	ALPHA = (band * 0.85 + fill) * color.a;
}
"""

const BEAM_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 color : source_color;
void fragment() {
	float up = UV.y;                       // 0 = 顶, 1 = 底
	float edge = 1.0 - abs(dot(NORMAL, VIEW));
	ALBEDO = color.rgb;
	ALPHA = color.a * up * up * (1.0 - edge * 0.7);
}
"""

var tier: String = "white"
var index: int = -1                     # 对应 Run.pending_orbs 的下标
var opened: bool = false
var _core: MeshInstance3D
var _halo: MeshInstance3D
var _ring: MeshInstance3D
var _beam: MeshInstance3D
var _t: float = 0.0
var _base_y: float = 0.55


func setup(p_tier: String, p_index: int) -> void:
	tier = p_tier
	index = p_index
	var col: Color = COLORS.get(tier, COLORS["white"])
	var size: float = {"white": 0.26, "blue": 0.3, "gold": 0.36, "rainbow": 0.42}.get(tier, 0.26)
	_core = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = size
	sm.height = size * 2.0
	sm.radial_segments = 10
	sm.rings = 5
	_core.mesh = sm
	var m := ShaderMaterial.new()
	m.shader = _shader("core", CORE_SHADER)
	m.set_shader_parameter("base", col)
	m.set_shader_parameter("iridescent", 1.0 if tier == "white" or tier == "rainbow" else 0.35)
	m.set_shader_parameter("glow", 1.0 if tier == "white" else (2.0 if tier == "rainbow" else 1.4))
	_core.material_override = m
	add_child(_core)
	_halo = MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = size * 1.6
	hm.height = size * 3.2
	hm.radial_segments = 10
	hm.rings = 5
	_halo.mesh = hm
	var h := StandardMaterial3D.new()
	h.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	h.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	h.albedo_color = Color(col.r, col.g, col.b, 0.22)
	_halo.material_override = h
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_halo)
	var mc: Color = MARK_COLORS.get(tier, MARK_COLORS["white"])
	_ring = MeshInstance3D.new()
	var rq := QuadMesh.new()
	rq.size = Vector2.ONE * (size * 4.4)
	rq.orientation = PlaneMesh.FACE_Y
	_ring.mesh = rq
	var rm := ShaderMaterial.new()
	rm.shader = _shader("ring", RING_SHADER)
	rm.set_shader_parameter("color", Color(mc.r, mc.g, mc.b, 0.9))
	_ring.material_override = rm
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	_beam = MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = size * 0.55
	bc.bottom_radius = size * 0.75
	bc.height = 3.2
	bc.radial_segments = 12
	bc.cap_top = false
	bc.cap_bottom = false
	_beam.mesh = bc
	var bm := ShaderMaterial.new()
	bm.shader = _shader("beam", BEAM_SHADER)
	bm.set_shader_parameter("color", Color(mc.r, mc.g, mc.b, 0.32))
	_beam.material_override = bm
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beam)
	_pin_ground()
	# 掉落时从高处弹下来
	position.y = 1.6
	var tw: Tween = create_tween()
	tw.tween_property(self, "position:y", _base_y, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## 点击拾取用：屏幕射线是否击中(世界坐标)
func hit_by_ray(o: Vector3, d: Vector3) -> bool:
	if opened:
		return false
	var c: Vector3 = global_position
	var oc: Vector3 = o - c
	var b: float = oc.dot(d)
	var cc: float = oc.dot(oc) - 0.55 * 0.55
	return b * b - cc >= 0.0


static var _shaders: Dictionary = {}


static func _shader(key: String, code: String) -> Shader:
	if not _shaders.has(key):
		var sh := Shader.new()
		sh.code = code
		_shaders[key] = sh
	return _shaders[key]


## 光环/光柱贴地，不跟着球上下浮动、旋转
func _pin_ground() -> void:
	if _ring == null:
		return
	_ring.position = Vector3(0, -position.y + 0.03, 0)
	_beam.position = Vector3(0, -position.y + 1.6, 0)


func burst() -> void:
	opened = true
	_ring.visible = false
	_beam.visible = false
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector3.ONE * 1.8, 0.18)
	tw.tween_property(_halo.material_override, "albedo_color:a", 0.0, 0.25)
	tw.chain().tween_property(self, "scale", Vector3.ONE * 0.01, 0.12)
	tw.chain().tween_callback(queue_free)


func _process(dt: float) -> void:
	_t += dt
	if opened:
		return
	_core.rotation.y = _t * 1.4
	if position.y <= _base_y + 0.001 or _t > 0.6:
		position.y = _base_y + 0.08 * sin(_t * 2.6)
	_halo.scale = Vector3.ONE * (1.0 + 0.1 * sin(_t * 4.0))
	_pin_ground()
	_ring.scale = Vector3.ONE * (1.0 + 0.06 * sin(_t * 3.0))
