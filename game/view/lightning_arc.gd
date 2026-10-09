class_name LightningArc
extends Node3D
## 一道看得清的闪电(导向节点的连锁闪电、雷电溅射)：a → b 一条折线 + 几根小分叉，画成面向镜头的三层光带
## (外层琥珀色的宽光晕 → 金色 → 白热的芯；都是普通混合，白地上也看得见)。
## travel > 0：闪电头从 a 往 b 推过去(头上一团电光)，到了才算打中(on_hit)；之后整条留在原地 linger 秒，
## 每隔一会儿重新抖一下折线(电弧在跳)、亮度忽明忽暗，最后 0.4 秒变细淡掉。
## pulse()：整条再亮一下(整条链传完时)

const AMBER := Color("#e07800")
const GOLD := Color("#ffc824")
const HOT := Color("#fffbe6")

var fx: Fx
var a := Vector3.ZERO
var b := Vector3.ZERO
var travel := 0.0
var linger := 0.9
var width := 0.08
var kinks := 7
var on_hit: Callable = Callable()
var cols: Array = [AMBER, GOLD, HOT]   # 外层光晕 / 中间 / 芯(踏影节点的影子用墨黑 / 青 / 浅青)
var _t := 0.0
var _pts: Array[Vector3] = []
var _forks: Array = []              # [[from_idx, end_point], ...]
var _jit_t := 0.0
var _hit := false
var _pulse := 0.0
var _im: ImmediateMesh
var _head: MeshInstance3D


static func create(p_fx: Fx, p_a: Vector3, p_b: Vector3, p_travel: float, p_linger: float, p_width: float, p_kinks: int = 7) -> LightningArc:
	var l := LightningArc.new()
	l.fx = p_fx
	l.a = p_a
	l.b = p_b
	l.travel = p_travel
	l.linger = p_linger
	l.width = p_width
	l.kinks = p_kinks
	l.top_level = true
	var mi := MeshInstance3D.new()
	l._im = ImmediateMesh.new()
	mi.mesh = l._im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.disable_fog = true
	mat.render_priority = 6
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 16.0
	l.add_child(mi)
	l._head = MeshInstance3D.new()
	l._head.mesh = SoftFX.quad()
	l._head.material_override = SoftFX.sprite_mat(GOLD, 3.0)
	l._head.scale = Vector3.ONE * 0.45
	l._head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	l._head.top_level = true
	l.add_child(l._head)
	p_fx.add_child(l)
	l.global_transform = Transform3D.IDENTITY
	l._jitter()
	if p_travel <= 0.0:
		l._head.visible = false
		l._arrive()
	else:
		l._head.global_position = p_a
	return l


func pulse() -> void:
	_pulse = 1.0


## 重新抖一下折线和分叉
func _jitter() -> void:
	var dist: float = a.distance_to(b)
	var dir: Vector3 = (b - a) / maxf(dist, 0.001)
	var side: Vector3 = dir.cross(Vector3.UP)
	side = side.normalized() if side.length() > 0.1 else Vector3.RIGHT
	var up: Vector3 = side.cross(dir).normalized()
	_pts.clear()
	_pts.append(a)
	for i in range(1, kinks):
		var k: float = float(i) / float(kinks)
		var amp: float = minf(0.32, dist * 0.085) * sin(k * PI)
		_pts.append(a.lerp(b, k) + side * randf_range(-1.0, 1.0) * amp + up * randf_range(-1.0, 1.0) * amp * 0.75)
	_pts.append(b)
	_forks.clear()
	for i in range(1, _pts.size() - 1):
		if randf() < 0.4:
			var fe: Vector3 = _pts[i] + (dir * randf_range(0.05, 0.3) + side * randf_range(-0.6, 0.6) + up * randf_range(-0.3, 0.4)).normalized() * randf_range(0.18, 0.42)
			_forks.append([i, fe])


func _arrive() -> void:
	if _hit:
		return
	_hit = true
	_head.visible = false
	_pulse = 1.0
	if on_hit.is_valid():
		on_hit.call()


func _process(delta: float) -> void:
	var s: float = maxf(0.2, fx.speed_scale) if fx != null else 1.0
	var dt: float = delta * s
	_t += dt
	_pulse = maxf(0.0, _pulse - dt * 3.0)
	# 闪电头推到哪儿了(0..1)
	var reach: float = 1.0 if travel <= 0.0 else clampf(_t / travel, 0.0, 1.0)
	if not _hit and reach >= 1.0:
		_arrive()
	var since: float = _t - (travel if travel > 0.0 else 0.0)
	if _hit and since > linger:
		queue_free()
		return
	_jit_t += dt
	if _jit_t > (0.045 if not _hit else 0.07):
		_jit_t = 0.0
		_jitter()
	# 亮度：打中那一下最亮，留着的时候忽明忽暗，最后 0.4 秒淡掉、变细
	var fade: float = 1.0 if not _hit else (1.0 - smoothstep(linger - 0.4, linger, since))
	var flick: float = 1.0 if not _hit else (0.72 + 0.28 * randf())
	var k: float = clampf(fade * flick + 0.5 * _pulse, 0.0, 1.4)
	var w: float = width * (0.55 + 0.45 * fade) * (1.0 + 0.5 * _pulse)
	# 只画到闪电头那里
	var n: int = _pts.size() - 1
	var upto: float = reach * float(n)
	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() != null else null
	_im.clear_surfaces()
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var head_p: Vector3 = a
	for i in range(n):
		if float(i) >= upto:
			break
		var p0: Vector3 = _pts[i]
		var p1: Vector3 = _pts[i + 1]
		if float(i + 1) > upto:
			p1 = p0.lerp(p1, upto - float(i))
		head_p = p1
		_seg(p0, p1, w, k, cam)
	for f: Array in _forks:
		if float(int(f[0])) < upto - 0.5:
			_seg(_pts[int(f[0])], f[1], w * 0.5, k * 0.8, cam)
	_im.surface_end()
	if not _hit:
		_head.global_position = head_p
		_head.scale = Vector3.ONE * (0.35 + 0.15 * randf())


## 一段三层光带(面向镜头)
func _seg(p0: Vector3, p1: Vector3, w: float, k: float, cam: Camera3D) -> void:
	var d: Vector3 = p1 - p0
	if d.length() < 0.001:
		return
	var vd: Vector3 = ((cam.global_position - (p0 + p1) * 0.5).normalized()) if cam != null else Vector3.UP
	var sd: Vector3 = d.cross(vd)
	sd = sd.normalized() if sd.length() > 1e-4 else Vector3.UP
	for layer: Array in [[cols[0], 2.6, 0.32], [cols[1], 1.5, 0.75], [cols[2], 0.45, 1.0]]:
		var c: Color = layer[0]
		var hw: float = w * float(layer[1]) * 0.5
		var al: float = clampf(float(layer[2]) * k, 0.0, 1.0)
		var col := Color(c.r, c.g, c.b, al)
		var o: Vector3 = sd * hw
		var v0: Vector3 = p0 - o
		var v1: Vector3 = p0 + o
		var v2: Vector3 = p1 + o
		var v3: Vector3 = p1 - o
		for v: Vector3 in [v0, v1, v2, v0, v2, v3]:
			_im.surface_set_color(col)
			_im.surface_add_vertex(v)
