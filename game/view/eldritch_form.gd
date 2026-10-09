class_name EldritchForm
extends Node3D
## 星旅节点·外神之貌(锁血 = 真实形态)的克苏鲁式特效。她本人由 BattleView 放大(UnitView.set_size)、身体化成星空(着色器 void_k)；这里画她脚下和周围的东西：
##   · 虚空之池：脚下一汪往里旋的深紫黑虚空(里面有星星、边缘一圈发光的紫边和一圈转动的符文)，半径 = pool
##   · 触手：池边伸出七条巨大的紫色触手(根部深紫、尖端品红发光、内侧一排粉色吸盘)，一直在扭动、往外仰；
##     真实形态每触发一次(lash)，离那个敌人最近的一条甩过去抽它
##   · 眼睛：她头顶后方浮着一圈眼睛(黄绿色的竖瞳、粉白眼白、会眨)，池子里也睁着几只，瞳孔都盯着最近的敌人
##   · 往上飘的暗紫雾 + 星点
## collapse()：触手缩回池子、眼睛闭上、池子往里塌成一个点、一闪，然后自己删掉。世界坐标，每帧跟着她(follow)。

const TENTACLE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, shadows_disabled, fog_disabled;
uniform float len = 2.0;
uniform float width = 0.2;
uniform float rise = 0.0;
uniform float phase = 0.0;
uniform float speed = 1.0;
uniform vec2 out_dir = vec2(1.0, 0.0);
uniform vec2 lash_dir = vec2(1.0, 0.0);
uniform float lash = 0.0;
varying float hh;
varying float ar;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() {
	float h = VERTEX.y;
	hh = h;
	ar = UV.x;
	float L = len * rise;
	float t = TIME * speed + phase;
	vec2 side = vec2(-out_dir.y, out_dir.x);
	// S 形扭动：沿触手传过去的一道波(根部不动、越往尖摆得越大) + 整条往外仰
	float wave = sin(t * 1.6 - h * 5.5) * 0.22 * h * L;
	vec2 bend = side * wave + vec2(sin(t + h * 2.6), cos(t * 0.83 + h * 2.1)) * 0.12 * h * h * L;
	bend += out_dir * (0.42 + 0.12 * sin(t * 0.7)) * h * h * L * (1.0 - lash);
	bend += lash_dir * lash * pow(h, 1.6) * L * 0.95;
	float y = h * L * (1.0 - 0.6 * lash * h) * (0.85 + 0.15 * sin(t * 1.3)) * (1.0 - 0.25 * h * (1.0 - lash));
	vec2 rad = VERTEX.xz * width * (1.0 - 0.92 * pow(h, 0.8)) * (1.0 + 0.1 * sin(h * 30.0 - TIME * 4.0 + phase));
	VERTEX = vec3(rad.x + bend.x, y, rad.y + bend.y);
}
void fragment() {
	vec3 base = vec3(0.025, 0.004, 0.06);
	vec3 tip = vec3(0.3, 0.05, 0.42);
	vec3 c = mix(base, tip, smoothstep(0.15, 1.0, hh));
	// 内侧一排吸盘(UV.x 0.5 附近)：粉色的圆圈，越往尖越小
	float side = 1.0 - smoothstep(0.08, 0.16, abs(ar - 0.5));
	vec2 sp = vec2((ar - 0.5) * 6.0, fract(hh * 16.0) - 0.5);
	float sucker = (1.0 - smoothstep(0.22, 0.32, length(sp))) * side * step(0.06, hh) * step(hh, 0.9);
	float ringk = smoothstep(0.18, 0.24, length(sp)) * (1.0 - smoothstep(0.26, 0.32, length(sp))) * side;
	c = mix(c, vec3(0.55, 0.22, 0.38), sucker * 0.85);
	c = mix(c, vec3(0.15, 0.02, 0.15), ringk * 0.7);
	// 皮肤上的星点(和她身上一样的星空)
	vec2 cell = floor(vec2(ar * 24.0, hh * 60.0));
	float hs = hash(cell);
	// 假光照(从左上方来)：湿亮的高光 + 背光面暗下去，才看得出是圆滚滚的肉
	vec3 nv = normalize(NORMAL);
	vec3 L = normalize(vec3(-0.4, 0.8, 0.45));
	c *= 0.55 + 0.75 * clamp(dot(nv, L), 0.0, 1.0);
	c += vec3(0.75, 0.6, 0.85) * pow(clamp(dot(reflect(-L, nv), VIEW), 0.0, 1.0), 20.0) * 0.6;
	c += vec3(0.9, 0.8, 1.0) * step(0.97, hs) * (0.5 + 0.5 * sin(TIME * 3.0 + hs * 30.0)) * 1.2;
	float fr = pow(1.0 - abs(dot(nv, VIEW)), 2.5);
	c += vec3(0.45, 0.1, 0.65) * fr * 0.7;
	c += vec3(0.75, 0.25, 0.95) * smoothstep(0.88, 1.0, hh) * 0.6;
	ALBEDO = c;
}
"""
const POOL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform float open = 1.0;
uniform float seed = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) {
	return noise(p) * 0.55 + noise(p * 2.1 + 3.7) * 0.3 + noise(p * 4.3 - 1.3) * 0.15;
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float edge = open * (0.84 + 0.08 * (noise(vec2(a * 2.5 + TIME * 0.4, seed)) - 0.5) * 2.0 + 0.05 * sin(a * 7.0 + TIME * 1.3));
	if (r > edge) {
		discard;
	}
	// 往里旋的虚空：角度随半径和时间扭
	float sw = a + (1.0 - r) * 4.0 + TIME * 0.45;
	vec2 q = vec2(cos(sw), sin(sw)) * r;
	float n = fbm(q * 3.2 + seed);
	float rimk = smoothstep(edge - 0.16, edge - 0.01, r);
	vec3 c = mix(vec3(0.006, 0.0, 0.02), vec3(0.17, 0.03, 0.32), smoothstep(0.35, 0.85, n) * (0.4 + 0.6 * r / max(edge, 0.01)));
	vec2 sq = q * 22.0 + seed;
	float hs = hash(floor(sq));
	float star = step(0.93, hs) * (1.0 - smoothstep(0.08, 0.3, length(fract(sq) - 0.5))) * (0.45 + 0.55 * sin(TIME * 3.0 + hs * 30.0));
	c += vec3(0.85, 0.78, 1.0) * star * 1.6;
	// 一圈转动的符文：边缘内侧的一条带子，分成 28 格，每格一个由几笔组成的小符号
	float band = smoothstep(0.0, 0.02, r - (edge - 0.26)) * (1.0 - smoothstep(0.0, 0.02, r - (edge - 0.17)));
	float ga = (a + TIME * 0.25) / 6.2831853 * 28.0;
	float gi = floor(ga);
	float gx = fract(ga);
	float gy = (r - (edge - 0.26)) / 0.09;
	float g1 = hash(vec2(gi, 1.0));
	float g2 = hash(vec2(gi, 2.0));
	float stroke = step(abs(gx - 0.5), 0.07) * step(g1, 0.7) + step(abs(gy - (0.3 + 0.4 * g2)), 0.08) * step(abs(gx - 0.5), 0.3)
		+ step(abs(gx - gy * (0.5 + g1)), 0.07) * step(0.4, g2);
	c = mix(c, vec3(0.55, 0.25, 0.85), clamp(stroke, 0.0, 1.0) * band * 0.85);
	c = mix(c, vec3(0.42, 0.08, 0.62), rimk * 0.85);
	ALBEDO = c;
	ALPHA = 0.95;
}
"""
const EYE_SHADER := """
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled, fog_disabled;
uniform float lid = 1.0;
varying vec3 ln;
void vertex() {
	ln = normalize(VERTEX);
}
void fragment() {
	float d = dot(ln, vec3(0.0, 0.0, 1.0));
	vec3 c = vec3(0.95, 0.82, 0.86);
	c = mix(c, vec3(0.75, 0.15, 0.25), smoothstep(0.1, -0.5, d) * 0.6);
	float vein = smoothstep(0.92, 1.0, sin(atan(ln.y, ln.x) * 9.0 + ln.z * 6.0) * 0.5 + 0.5) * step(d, 0.55);
	c = mix(c, vec3(0.8, 0.1, 0.18), vein * 0.5);
	float iris = smoothstep(0.62, 0.66, d);
	vec3 ic = mix(vec3(0.55, 0.75, 0.05), vec3(1.0, 0.92, 0.25), smoothstep(0.66, 0.95, d));
	c = mix(c, ic * 1.6, iris);
	float pupil = (1.0 - smoothstep(0.05, 0.09, abs(ln.x))) * smoothstep(0.7, 0.74, d);
	c = mix(c, vec3(0.02, 0.0, 0.03), pupil);
	// 眼睑：上下合拢(lid = 张开的程度)
	if (abs(ln.y) > lid * 0.98 + 0.02 && d > -0.2) {
		c = vec3(0.12, 0.02, 0.22);
	}
	ALBEDO = c;
}
"""

static var _tent_shader: Shader = null
static var _pool_shader: Shader = null
static var _eye_shader: Shader = null
static var _tent_mesh: ArrayMesh = null

var follow: Node3D = null
var pool: float = 1.6
var height: float = 2.2                   # 她放大后的身高(眼睛浮在这附近)
var _pool_mat: ShaderMaterial
var _tents: Array = []                    # [MeshInstance3D, ShaderMaterial, 基准长度, 方位角]
var _eyes: Array = []                     # [Node3D, ShaderMaterial, 下次眨眼, 浮在空中?]
var _lash: Dictionary = {}                # 第几条触手 -> [开始时刻, 目标点]
var _clock: float = 0.0
var _open: float = 0.0
var _closing: bool = false
var _close_t: float = 0.0
var look_at_pos: Vector3 = Vector3.ZERO    # 眼睛盯着哪里(BattleView 每帧给最近的敌人)
var has_look: bool = false
var _mist: GPUParticles3D = null


static func create(p_follow: Node3D, p_pool: float, p_height: float) -> EldritchForm:
	var ef := EldritchForm.new()
	ef.follow = p_follow
	ef.pool = p_pool
	ef.height = p_height
	return ef


func _ready() -> void:
	top_level = true
	if _tent_shader == null:
		_tent_shader = Shader.new()
		_tent_shader.code = TENTACLE_SHADER
		_pool_shader = Shader.new()
		_pool_shader.code = POOL_SHADER
		_eye_shader = Shader.new()
		_eye_shader.code = EYE_SHADER
	if follow != null and is_instance_valid(follow):
		global_position = follow.global_position
	# 虚空之池
	var pm := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(pool * 2.0, pool * 2.0)
	pm.mesh = plane
	_pool_mat = ShaderMaterial.new()
	_pool_mat.shader = _pool_shader
	_pool_mat.set_shader_parameter("seed", randf() * 20.0)
	_pool_mat.set_shader_parameter("open", 0.0)
	_pool_mat.render_priority = -1
	pm.material_override = _pool_mat
	pm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pm.position = Vector3(0.0, 0.035, 0.0)
	add_child(pm)
	# 触手：池边一圈(长短不一，后面的更长)
	var n := 8
	for i in range(n):
		var a: float = TAU * (float(i) + randf_range(-0.2, 0.2)) / float(n)
		var rr: float = pool * randf_range(0.62, 0.8)
		var m := MeshInstance3D.new()
		m.mesh = _tentacle_mesh()
		var mat := ShaderMaterial.new()
		mat.shader = _tent_shader
		var L: float = randf_range(2.0, 2.9) * clampf(pool / 1.6, 0.8, 1.3)
		mat.set_shader_parameter("len", L)
		mat.set_shader_parameter("width", randf_range(0.13, 0.18))
		mat.set_shader_parameter("phase", randf() * TAU)
		mat.set_shader_parameter("speed", randf_range(0.8, 1.4))
		mat.set_shader_parameter("out_dir", Vector2(cos(a), sin(a)))
		mat.set_shader_parameter("rise", 0.0)
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.extra_cull_margin = 4.0
		m.position = Vector3(cos(a) * rr, 0.0, sin(a) * rr)
		add_child(m)
		_tents.append([m, mat, L, a])
	# 眼睛：头顶后方浮一圈 5 只(大小不一)，池子里睁 3 只
	var em := SphereMesh.new()
	em.radius = 0.5
	em.height = 1.0
	em.radial_segments = 16
	em.rings = 10
	for j in range(8):
		var floating: bool = j < 5
		var e := MeshInstance3D.new()
		e.mesh = em
		var emat := ShaderMaterial.new()
		emat.shader = _eye_shader
		emat.set_shader_parameter("lid", 0.0)
		e.material_override = emat
		e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var holder := Node3D.new()
		add_child(holder)
		holder.add_child(e)
		var sz: float
		var fa: float = 0.0
		if floating:
			fa = lerpf(-1.15, 1.15, float(j) / 4.0)
			sz = [0.22, 0.3, 0.42, 0.3, 0.22][j]
		else:
			var pa: float = TAU * float(j - 5) / 3.0 + 0.6
			holder.position = Vector3(cos(pa) * pool * 0.42, 0.02, sin(pa) * pool * 0.42)
			sz = 0.34
		e.scale = Vector3.ONE * sz
		_eyes.append([holder, emat, randf_range(0.5, 2.0), floating, fa])
	# 往上飘的暗紫雾 + 星点
	_mist = SoftFX.particles(26, 1.6, SoftFX.ramp([Color(0.25, 0.05, 0.4, 0.0), Color(0.22, 0.04, 0.38, 0.55), Color(0.08, 0.0, 0.15, 0.0)], [0.0, 0.3, 1.0]), 0.5, false)
	var mp: ParticleProcessMaterial = _mist.process_material
	mp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mp.emission_ring_axis = Vector3.UP
	mp.emission_ring_radius = pool * 0.9
	mp.emission_ring_inner_radius = pool * 0.2
	mp.emission_ring_height = 0.05
	mp.direction = Vector3(0, 1, 0)
	mp.spread = 15.0
	mp.initial_velocity_min = 0.3
	mp.initial_velocity_max = 0.8
	mp.gravity = Vector3(0, 0.3, 0)
	(_mist.material_override as StandardMaterial3D).disable_fog = true
	_mist.emitting = true
	add_child(_mist)


## 一条触手的网格：沿 +Y 长 1、截面半径 1(着色器里再按 width 缩、往尖收)，UV.x = 绕一圈 0..1，VERTEX.y = 沿触手 0..1
static func _tentacle_mesh() -> ArrayMesh:
	if _tent_mesh != null:
		return _tent_mesh
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var segs: int = 22
	var sides: int = 10
	for i in range(segs + 1):
		var h: float = float(i) / float(segs)
		for j in range(sides + 1):
			var a: float = TAU * float(j) / float(sides)
			var d := Vector3(cos(a), 0.0, sin(a))
			verts.append(Vector3(d.x, h, d.z))
			norms.append(d)
			uvs.append(Vector2(float(j) / float(sides), h))
	for i in range(segs):
		for j in range(sides):
			var a0: int = i * (sides + 1) + j
			var b0: int = a0 + sides + 1
			idx.append_array([a0, b0, a0 + 1, a0 + 1, b0, b0 + 1])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	_tent_mesh = ArrayMesh.new()
	_tent_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return _tent_mesh


## 真实形态触发一次：离 at 最近(方位)的那条触手甩过去抽它；返回抽到的时刻(秒，从现在起)
func lash(at: Vector3) -> float:
	if _closing or _tents.is_empty():
		return 0.0
	var me: Vector3 = global_position
	var best := -1
	var bd := 1.0e9
	for i in range(_tents.size()):
		if _lash.has(i):
			continue
		var base: Vector3 = me + (_tents[i][0] as MeshInstance3D).position
		var d: float = Vector2(at.x - base.x, at.z - base.z).length()
		if d < bd:
			bd = d
			best = i
	if best < 0:
		return 0.0
	_lash[best] = [_clock, at]
	return 0.12


## 收掉：触手缩回去、眼睛闭上、池子塌成一个点
func collapse() -> void:
	if _closing:
		return
	_closing = true
	_close_t = _clock
	if _mist != null:
		_mist.emitting = false


func _process(delta: float) -> void:
	_clock += delta
	if follow != null and is_instance_valid(follow):
		global_position = global_position.lerp(follow.global_position, 1.0 - exp(-delta * 12.0))
	var ck: float = clampf((_clock - _close_t) / 0.45, 0.0, 1.0) if _closing else 0.0
	_open = minf(1.0, _open + delta / 0.35) if not _closing else 1.0 - ck
	_pool_mat.set_shader_parameter("open", pow(_open, 0.6) if not _closing else 1.0 - ck * ck)
	if _closing and ck >= 1.0:
		queue_free()
		return
	for i in range(_tents.size()):
		var t: Array = _tents[i]
		var mat: ShaderMaterial = t[1]
		var m: MeshInstance3D = t[0]
		# 依次从池子里钻出来(一条比一条晚一点)
		var rise: float = clampf((_clock - 0.06 * float(i)) / 0.4, 0.0, 1.0)
		rise = 1.0 - pow(1.0 - rise, 3.0)
		if _closing:
			rise = minf(rise, 1.0 - clampf(ck * 1.6 - 0.05 * float(i), 0.0, 1.0))
		mat.set_shader_parameter("rise", rise)
		var lk := 0.0
		var L: float = float(t[2])
		if _lash.has(i):
			var ls: Array = _lash[i]
			var u: float = _clock - float(ls[0])
			lk = clampf(u / 0.12, 0.0, 1.0) if u < 0.12 else clampf(1.0 - (u - 0.2) / 0.3, 0.0, 1.0)
			lk = lk * lk * (3.0 - 2.0 * lk)
			var tgt: Vector3 = ls[1]
			var base: Vector3 = global_position + m.position
			var dv := Vector2(tgt.x - base.x, tgt.z - base.z)
			if dv.length() > 0.01:
				mat.set_shader_parameter("lash_dir", dv.normalized())
			L = lerpf(L, maxf(L, dv.length() * 1.08), lk)
			if u > 0.5:
				_lash.erase(i)
		mat.set_shader_parameter("lash", lk)
		mat.set_shader_parameter("len", L)
	# 眼睛：睁开、偶尔眨一下、瞳孔盯着最近的敌人(没有就看前面)；浮着的轻轻上下飘
	for j in range(_eyes.size()):
		var e: Array = _eyes[j]
		var holder: Node3D = e[0]
		var emat: ShaderMaterial = e[1]
		var lid: float = clampf((_clock - 0.25 - 0.05 * float(j)) / 0.25, 0.0, 1.0)
		if _clock > float(e[2]):
			var bu: float = _clock - float(e[2])
			lid = minf(lid, absf(bu - 0.09) / 0.09)
			if bu > 0.18:
				e[2] = _clock + randf_range(1.2, 3.0)
		if _closing:
			lid = minf(lid, 1.0 - ck * 2.0)
		emat.set_shader_parameter("lid", clampf(lid, 0.0, 1.0))
		var fwd := Vector3(0.0, 0.0, 1.0) if follow == null or not is_instance_valid(follow) else Vector3(sin(follow.rotation.y), 0.0, cos(follow.rotation.y))
		if bool(e[3]):
			# 浮着的眼睛：在她头顶后方排成一道弧(跟着她转身)，轻轻上下飘
			var fa: float = float(e[4])
			var right := Vector3(fwd.z, 0.0, -fwd.x)
			holder.position = right * sin(fa) * 0.95 - fwd * (cos(fa) * 0.55 + 0.3) + Vector3(0.0, height * (0.92 + 0.12 * cos(fa * 1.5)) + 0.12 + 0.05 * sin(_clock * 1.6 + float(j)), 0.0)
		var gp: Vector3 = holder.global_position
		var want: Vector3 = look_at_pos if has_look else gp + fwd
		# 浮着的眼睛主要朝着镜头(俯视镜头里看得见瞳孔)，再往敌人那边斜一点
		var cam: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
		if bool(e[3]) and cam != null:
			var tc: Vector3 = (cam.global_position - gp).normalized()
			var tt: Vector3 = (want - gp).normalized() if (want - gp).length() > 0.01 else fwd
			want = gp + (tc * 0.65 + tt * 0.35).normalized()
		if not bool(e[3]):
			want = gp + (want - gp).normalized() * 0.3 + Vector3(0.0, 1.0, 0.0)     # 池子里的眼睛：往上看，瞳孔偏向敌人
		if (want - gp).length() > 0.01 and absf((want - gp).normalized().dot(Vector3.UP)) < 0.999:
			holder.look_at(want, Vector3.UP)
			holder.rotate_object_local(Vector3.UP, PI)          # look_at 让 -Z 朝目标；眼睛的瞳孔在 +Z
