class_name LilyCounter
extends Node3D
## 正行节点·正色百合(花瓣)的层数计数器：她脚下一朵三圈、每圈 4 瓣的百合，12 瓣 = 【叠加 12】。
##   · 每多一层花瓣就开出一瓣，从里往外：第 1~4 层 = 内圈(金白、立得最直)，5~8 = 中圈(粉)，9~12 = 外圈(玫红、平铺)；
##     还没开的那几瓣只是一圈淡淡的花瓣轮廓(看得出还差几层)
##   · 开满一圈(4 层：生命上限、8 层：双抗——阈值加成生效)那一圈亮一下，地上推开一道金色的光环
##   · 开满 12 瓣：整朵花发光、缓缓呼吸，花下面一圈柔和的金光(可以再绽了)
##   · 被消耗(再绽之花每秒收 4 瓣)：从外往里，那几瓣合拢、化成光飞进她胸口
##   · 获得【花】之后，花外面一直围着一圈细细的金色花环
## 世界坐标(不跟着她转身)，每帧跟到她脚下；花自己慢慢转
const WHORLS: Array = [
	{"r0": 0.2, "len": 0.36, "wid": 0.2, "tilt": 46.0, "off": 0.0, "base": Color("#fff6d0"), "tip": Color("#ffc23a")},
	{"r0": 0.24, "len": 0.48, "wid": 0.25, "tilt": 28.0, "off": 30.0, "base": Color("#ffe6f0"), "tip": Color("#ff74aa")},
	{"r0": 0.28, "len": 0.6, "wid": 0.3, "tilt": 14.0, "off": 60.0, "base": Color("#ffd2e4"), "tip": Color("#e23a78")},
]
const PER := 4
const GOLD := Color("#ffd46a")

const PETAL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_opaque, shadows_disabled, fog_disabled;
uniform vec4 base_col : source_color = vec4(1.0);
uniform vec4 tip_col : source_color = vec4(1.0, 0.7, 0.8, 1.0);
uniform float open = 1.0;
uniform float lit = 0.0;
uniform float fade = 1.0;
void fragment() {
	float t = UV.x;
	float v = abs(UV.y);
	vec3 c = mix(base_col.rgb, tip_col.rgb, smoothstep(0.0, 0.85, t));
	float vein = 1.0 - smoothstep(0.0, 0.12, v);
	float rim = smoothstep(0.7, 0.97, v) + smoothstep(0.9, 1.0, t);
	c = mix(c, vec3(1.0, 0.96, 0.82), vein * (1.0 - t) * 0.6);
	c = mix(c, tip_col.rgb * 0.62, clamp(rim, 0.0, 1.0) * 0.55 * open);
	c = mix(c, vec3(1.0, 0.95, 0.72), lit * 0.5);
	float ghost = (0.08 + 0.5 * clamp(rim, 0.0, 1.0)) * 0.6;
	ALBEDO = mix(vec3(1.0, 0.88, 0.5), c, open) * (1.0 + lit * 0.6);
	ALPHA = clamp(mix(ghost, 0.96, open), 0.0, 1.0) * fade;
}
"""

static var _shader: Shader = null
static var _mesh: ArrayMesh = null

var follow: Node3D = null                 # 跟着谁(她的 UnitView)
var chest_h: float = 1.0                  # 飞进胸口的高度
var cap: int = 12
var stacks: int = 0
var _bloom: bool = false
var _open: Array[float] = []              # 每瓣现在张开的程度(0 = 影子 → 1 = 开好；会稍微冲过头再回来)
var _vel: Array[float] = []
var _lit: Array[float] = []               # 每瓣的亮光(阈值 / 满开时)
var _pivots: Array[Node3D] = []
var _mats: Array[ShaderMaterial] = []
var _petals: Array[MeshInstance3D] = []
var _glow: MeshInstance3D = null          # 满开时花下面的金光
var _glow_mat: StandardMaterial3D = null
var _wreath: MeshInstance3D = null        # 【花】的金色花环
var _wreath_mat: StandardMaterial3D = null
var _pulses: Array = []                   # [MeshInstance3D, StandardMaterial3D, 已过时间, 半径]
var _spin: Node3D = null
var _t: float = 0.0


## 一片花瓣(给别的特效用：花开的大百合)：base / tip = 花瓣根 / 尖的颜色，网格沿 +Z
static func make_petal(base: Color, tip: Color) -> MeshInstance3D:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = PETAL_SHADER
	var m := MeshInstance3D.new()
	m.mesh = petal_mesh()
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("base_col", base)
	mat.set_shader_parameter("tip_col", tip)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


static func petal_mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	# 一片百合花瓣：沿 +Z 长 1、宽 1(两头尖、六成处最宽)，两边往上翘(像个浅勺)，花瓣尖往上卷；UV.x = 沿花瓣 0..1，UV.y = 横跨 -1..1
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var nl: int = 10
	var nw: int = 6
	for i in range(nl + 1):
		var t: float = float(i) / float(nl)
		var w: float = 0.5 * pow(sin(PI * clampf(pow(t, 0.75), 0.0, 1.0)), 0.9)
		for j in range(nw + 1):
			var v: float = float(j) / float(nw) * 2.0 - 1.0
			var x: float = v * w
			var y: float = 0.22 * v * v * w + 0.18 * t * t * t
			verts.append(Vector3(x, y, t))
			uvs.append(Vector2(t, v))
	for i in range(nl):
		for j in range(nw):
			var a: int = i * (nw + 1) + j
			var b: int = a + nw + 1
			idx.append_array([a, b, a + 1, a + 1, b, b + 1])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	_mesh = ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return _mesh


func _ready() -> void:
	top_level = true
	if _shader == null:
		_shader = Shader.new()
		_shader.code = PETAL_SHADER
	_spin = Node3D.new()
	add_child(_spin)
	# 满开时的金光(平躺在地上的一片柔光)
	_glow = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2.0, 2.0)
	_glow.mesh = pm
	_glow_mat = StandardMaterial3D.new()
	_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow_mat.albedo_texture = SoftFX._texture()
	_glow_mat.albedo_color = Color(GOLD.r * 1.2, GOLD.g * 1.2, GOLD.b * 1.1, 0.0)
	_glow_mat.disable_fog = true
	_glow_mat.render_priority = -1
	_glow.material_override = _glow_mat
	_glow.position = Vector3(0.0, 0.02, 0.0)
	_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_glow)
	for i in range(cap):
		var w: Dictionary = WHORLS[mini(i / PER, WHORLS.size() - 1)]
		var piv := Node3D.new()
		var a: float = deg_to_rad(float(w["off"]) + 90.0 * float(i % PER))
		piv.rotation.y = a
		_spin.add_child(piv)
		var hinge := Node3D.new()
		hinge.name = "Hinge"
		hinge.position = Vector3(0.0, 0.035 + 0.01 * float(i / PER), float(w["r0"]))
		piv.add_child(hinge)
		var m := MeshInstance3D.new()
		m.mesh = petal_mesh()
		var mat := ShaderMaterial.new()
		mat.shader = _shader
		mat.set_shader_parameter("base_col", w["base"])
		mat.set_shader_parameter("tip_col", w["tip"])
		mat.set_shader_parameter("open", 0.0)
		mat.render_priority = 2 - i / PER
		m.material_override = mat
		m.scale = Vector3(float(w["wid"]), float(w["len"]), float(w["len"]))
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hinge.add_child(m)
		_pivots.append(piv)
		_mats.append(mat)
		_petals.append(m)
		_open.append(0.0)
		_vel.append(0.0)
		_lit.append(0.0)
	_apply_pose()


## 花瓣层数变了：多了的那几瓣开出来(跨过 4 / 8 / 12 时那一圈亮一下 + 光环)，少了的那几瓣飞进胸口
func set_stacks(n: int) -> void:
	n = clampi(n, 0, cap)
	if n == stacks:
		return
	if n < stacks:
		for i in range(n, stacks):
			_fly_in(i)
			_open[i] = 0.0
			_vel[i] = 0.0
	else:
		for i in range(stacks, n):
			_open[i] = maxf(_open[i], 0.05)
			_vel[i] = 9.0
		for th in range(PER, cap + 1, PER):
			if stacks < th and n >= th:
				for j in range(th - PER, th):
					_lit[j] = 1.0
				_pulse(float(WHORLS[mini(th / PER - 1, WHORLS.size() - 1)]["r0"]) + float(WHORLS[mini(th / PER - 1, WHORLS.size() - 1)]["len"]) + 0.1)
	stacks = n


func set_bloom(on: bool) -> void:
	if on and not _bloom:
		_pulse(1.2)
	_bloom = on


func _process(delta: float) -> void:
	_t += delta
	if follow != null and is_instance_valid(follow):
		global_position = follow.global_position
	_spin.rotation.y += delta * 0.12
	var full: bool = stacks >= cap
	for i in range(cap):
		var target: float = 1.0 if i < stacks else 0.0
		# 弹簧：开的时候稍微冲过头再回来(像花一下子绽开)
		var f: float = (target - _open[i]) * 160.0 - _vel[i] * 16.0
		_vel[i] += f * delta
		_open[i] = clampf(_open[i] + _vel[i] * delta, 0.0, 1.25)
		_lit[i] = maxf(0.0, _lit[i] - delta * 1.6)
		var breathe: float = (0.22 + 0.18 * sin(_t * 2.6 - float(i) * 0.5)) if full else 0.0
		_mats[i].set_shader_parameter("open", clampf(_open[i], 0.0, 1.0))
		_mats[i].set_shader_parameter("lit", maxf(_lit[i], breathe))
	var ga: float = (0.38 + 0.12 * sin(_t * 2.6)) if full else 0.0
	_glow_mat.albedo_color.a = lerpf(_glow_mat.albedo_color.a, ga, 1.0 - exp(-delta * 5.0))
	_glow.visible = _glow_mat.albedo_color.a > 0.01
	if _bloom and _wreath == null:
		_make_wreath()
	if _wreath != null:
		_wreath_mat.albedo_color.a = 0.55 + 0.2 * sin(_t * 1.7)
		_wreath.rotation.y -= delta * 0.3
	for k in range(_pulses.size() - 1, -1, -1):
		var pl: Array = _pulses[k]
		pl[2] = float(pl[2]) + delta
		var u: float = float(pl[2]) / 0.6
		var pm: MeshInstance3D = pl[0]
		if u >= 1.0:
			pm.queue_free()
			_pulses.remove_at(k)
			continue
		var r: float = lerpf(0.4, float(pl[3]), 1.0 - pow(1.0 - u, 2.0))
		pm.scale = Vector3(r, 1.0, r)
		(pl[1] as StandardMaterial3D).albedo_color.a = 0.85 * (1.0 - u)
	_apply_pose()


## 每瓣的姿势：影子 = 平躺、小一点；开 = 按这一圈的角度立起来(冲过头时再立高一点)
func _apply_pose() -> void:
	for i in range(_pivots.size()):
		var w: Dictionary = WHORLS[mini(i / PER, WHORLS.size() - 1)]
		var o: float = _open[i]
		var hinge: Node3D = _pivots[i].get_node("Hinge")
		hinge.rotation.x = -deg_to_rad(lerpf(3.0, float(w["tilt"]), clampf(o, 0.0, 1.0)) + 20.0 * maxf(0.0, o - 1.0) / 0.25)
		var sc: float = lerpf(0.82, 1.0, clampf(o, 0.0, 1.0))
		hinge.scale = Vector3.ONE * sc


## 一圈金色的光环往外推开
func _pulse(radius: float) -> void:
	var m := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.93
	tm.outer_radius = 1.0
	tm.rings = 48
	tm.ring_segments = 4
	m.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(GOLD.r * 1.3, GOLD.g * 1.3, GOLD.b * 1.2, 0.85)
	mat.disable_fog = true
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position = Vector3(0.0, 0.05, 0.0)
	m.scale = Vector3(0.4, 1.0, 0.4)
	add_child(m)
	_pulses.append([m, mat, 0.0, radius])


func _make_wreath() -> void:
	_wreath = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.86
	tm.outer_radius = 0.9
	tm.rings = 64
	tm.ring_segments = 4
	_wreath.mesh = tm
	_wreath_mat = StandardMaterial3D.new()
	_wreath_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_wreath_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_wreath_mat.albedo_color = Color(GOLD.r * 1.25, GOLD.g * 1.25, GOLD.b * 1.1, 0.6)
	_wreath_mat.disable_fog = true
	_wreath.material_override = _wreath_mat
	_wreath.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_wreath.position = Vector3(0.0, 0.03, 0.0)
	add_child(_wreath)
	# 花环上一圈金色的小花蕾
	var bm := SphereMesh.new()
	bm.radius = 0.035
	bm.height = 0.09
	bm.radial_segments = 8
	bm.rings = 4
	for i in range(8):
		var b := MeshInstance3D.new()
		b.mesh = bm
		b.material_override = _wreath_mat
		var a: float = TAU * float(i) / 8.0
		b.position = Vector3(cos(a) * 0.88, 0.03, sin(a) * 0.88)
		_wreath.add_child(b)


## 被收走的那一瓣：复制一片，合拢着飞进她胸口，越飞越小、越来越亮
func _fly_in(i: int) -> void:
	if i < 0 or i >= _petals.size() or _open[i] < 0.3:
		return
	var src: MeshInstance3D = _petals[i]
	var m := MeshInstance3D.new()
	m.mesh = src.mesh
	var mat: ShaderMaterial = _mats[i].duplicate()
	mat.set_shader_parameter("open", 1.0)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	m.top_level = true
	var x0: Transform3D = src.global_transform
	m.global_transform = x0
	var tw: Tween = m.create_tween()
	var delay: float = 0.04 * float(i % PER)
	tw.tween_interval(delay)
	tw.tween_method(func(k: float) -> void:
		if not is_instance_valid(m):
			return
		var dest: Vector3 = global_position + Vector3(0.0, chest_h, 0.0)
		var mid: Vector3 = (x0.origin + dest) * 0.5 + Vector3(0.0, 0.25, 0.0)
		var p: Vector3 = x0.origin.lerp(mid, k).lerp(mid.lerp(dest, k), k)
		m.global_transform = Transform3D(x0.basis.orthonormalized().rotated(Vector3.UP, k * 4.0).scaled(x0.basis.get_scale() * (1.0 - 0.8 * k)), p)
		mat.set_shader_parameter("lit", k), 0.0, 1.0, 0.32)
	tw.tween_callback(m.queue_free)
