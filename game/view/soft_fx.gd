class_name SoftFX
extends RefCounted
## 柔和的特效积木(火光 / 火焰团 / 烟 / 焦痕)：体素方块的碎屑之外，再叠一层边缘柔和的光，特效才不显得"一堆硬方块"。
##   sprite_mat(color, energy, additive)   面向镜头的径向渐变光片(单个节点用；BILLBOARD_ENABLED)
##   particle_mat(additive)                 同上，但给粒子用(BILLBOARD_PARTICLES，颜色走粒子的 color_ramp)
##   quad(size)                             光片 / 粒子的网格
##   ramp(colors, offsets)                  粒子颜色随寿命的渐变
##   scorch_mat(hot)                        贴地的焦痕：中间暗、外圈一道发光的余烬边，fade 往下淡
##   splat_mat()                            贴地的血迹(血嗜节点)：不规则的一滩 + 外面的小血点，grow 摊开、fade 淡掉
## 叠加混合(additive)在暗的红之章地面上很好看，在白色地面上会看不见 —— 只给火系(红之章)的特效用。

static var _tex: GradientTexture2D = null
static var _quad: QuadMesh = null
static var _scorch_shader: Shader = null

const SCORCH := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 hot : source_color = vec4(1.0, 0.45, 0.12, 1.0);
uniform float fade = 1.0;
uniform float glow = 1.0;
uniform float seed = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float n = noise(p * 4.0 + seed) * 0.35 + noise(p * 11.0 - seed) * 0.15;
	float r = length(p) + n * 0.35;
	if (r > 1.0) {
		discard;
	}
	float dark = (1.0 - smoothstep(0.35, 1.0, r)) * 0.7;
	float edge = smoothstep(0.09, 0.0, abs(r - 0.72)) * step(0.5, noise(p * 7.0 + seed * 2.0));
	float speck = step(0.83, noise(p * 18.0 + seed)) * (1.0 - smoothstep(0.2, 0.8, r));
	float h = clamp(edge + speck * 0.8, 0.0, 1.0) * glow;
	ALBEDO = mix(vec3(0.03, 0.02, 0.02), hot.rgb * 1.5, h);
	ALPHA = max(dark, h) * fade;
}
"""


## 血迹(血嗜节点)：一滩不规则的血(边缘一圈深色、中间湿亮)，外面撒几颗小血点；grow = 摊开的程度(0..1)，fade 往下淡
const SPLAT := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 col : source_color = vec4(0.2, 0.0, 0.02, 1.0);
uniform vec4 wet : source_color = vec4(0.5, 0.02, 0.06, 1.0);
uniform float fade = 1.0;
uniform float grow = 1.0;
uniform float drops = 1.0;
uniform float seed = 0.0;
uniform vec3 sheen = vec3(0.55, 0.12, 0.12);     // 湿润的反光(血 = 暗红；墨 = 青)
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float l = length(p);
	float g = max(grow, 0.001);
	vec2 d = p / max(l, 0.0001);
	float edge = (0.56 + noise(d * 2.2 + seed) * 0.3 + noise(p * 5.0 - seed) * 0.12) * g;
	float blob = 1.0 - smoothstep(edge - 0.03, edge, l);
	vec2 q = p * 8.0 + seed * 3.0;
	vec2 cell = floor(q);
	float h = hash(cell);
	vec2 off = vec2(hash(cell + 3.1), hash(cell + 7.7)) - 0.5;
	float dd = length(fract(q) - 0.5 - off * 0.45);
	float sat = step(0.7, h) * (1.0 - smoothstep(0.1 + 0.12 * h, 0.16 + 0.12 * h, dd));
	sat *= step(edge * 0.92, l) * (1.0 - smoothstep(min(1.0, g * 1.3) - 0.05, min(1.0, g * 1.3), l)) * drops;
	float a = max(blob, sat);
	if (a < 0.02) {
		discard;
	}
	float rim = smoothstep(edge - 0.2, edge - 0.01, l);
	vec3 c = mix(wet.rgb, col.rgb, 0.35 + 0.65 * rim);
	c += sheen * pow(noise(p * 3.5 + seed * 2.0), 4.0) * (1.0 - rim) * 1.6;
	ALBEDO = c;
	ALPHA = a * fade * 0.92;
}
"""
static var _splat_shader: Shader = null


static func splat_mat() -> ShaderMaterial:
	if _splat_shader == null:
		_splat_shader = Shader.new()
		_splat_shader.code = SPLAT
	var m := ShaderMaterial.new()
	m.shader = _splat_shader
	m.set_shader_parameter("seed", randf() * 50.0)
	m.render_priority = -1
	return m


static func _texture() -> GradientTexture2D:
	if _tex != null:
		return _tex
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.22), Color(1, 1, 1, 0)])
	_tex = GradientTexture2D.new()
	_tex.gradient = g
	_tex.fill = GradientTexture2D.FILL_RADIAL
	_tex.fill_from = Vector2(0.5, 0.5)
	_tex.fill_to = Vector2(1.0, 0.5)
	_tex.width = 64
	_tex.height = 64
	return _tex


static func quad(size: float = 1.0) -> QuadMesh:
	if is_equal_approx(size, 1.0):
		if _quad == null:
			_quad = QuadMesh.new()
		return _quad
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	return q


static func sprite_mat(color: Color, energy: float = 1.6, additive: bool = true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.albedo_texture = _texture()
	m.albedo_color = Color(color.r * energy, color.g * energy, color.b * energy, color.a)
	m.no_depth_test = false
	m.render_priority = 3
	return m


static func particle_mat(additive: bool = true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true             # 不开的话粒子的大小(scale_min/max、scale_curve)全被丢掉，每片都是 1 米的光片
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _texture()
	m.render_priority = 3
	return m


static func ramp(colors: Array, offsets: Array = []) -> GradientTexture1D:
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in range(colors.size()):
		offs.append(float(offsets[i]) if i < offsets.size() else float(i) / float(maxi(1, colors.size() - 1)))
		cols.append(colors[i])
	g.offsets = offs
	g.colors = cols
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


## 火焰色阶：白热 → 主色 → 暗 → 烟(透明)。energy > 1 = 在叠加混合下更亮
static func fire_ramp(c: Color, energy: float = 1.6, smoke: bool = true) -> GradientTexture1D:
	var hot := c.lerp(Color(1.0, 0.97, 0.85), 0.6)
	var e := energy
	var cols: Array = [Color(hot.r * e, hot.g * e, hot.b * e, 0.0), Color(hot.r * e, hot.g * e, hot.b * e, 0.95),
		Color(c.r * e, c.g * e, c.b * e, 0.8), Color(c.r * 0.5, c.g * 0.3, c.b * 0.3, 0.45)]
	var offs: Array = [0.0, 0.1, 0.42, 0.75]
	if smoke:
		cols.append(Color(0.08, 0.05, 0.05, 0.0))
		offs.append(1.0)
	else:
		cols.append(Color(c.r * 0.3, c.g * 0.2, c.b * 0.2, 0.0))
		offs.append(1.0)
	return ramp(cols, offs)


static func scorch_mat(hot: Color) -> ShaderMaterial:
	if _scorch_shader == null:
		_scorch_shader = Shader.new()
		_scorch_shader.code = SCORCH
	var m := ShaderMaterial.new()
	m.shader = _scorch_shader
	m.set_shader_parameter("hot", hot)
	m.set_shader_parameter("seed", randf() * 50.0)
	m.render_priority = -1
	return m


## 一团持续 / 一次性的柔光粒子(火焰团、烟、火星光晕)：方向、速度、寿命、大小都按参数
static func particles(amount: int, life: float, color_ramp: GradientTexture1D, size: float, additive: bool = true) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.color_ramp = color_ramp
	pm.scale_min = size * 0.7
	pm.scale_max = size * 1.3
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.45))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1.0, 0.75))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	pm.angle_min = 0.0
	pm.angle_max = 360.0
	p.process_material = pm
	p.draw_pass_1 = quad()
	p.material_override = particle_mat(additive)
	p.amount = amount
	p.lifetime = life
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-4, -2, -4), Vector3(8, 8, 8))
	return p
