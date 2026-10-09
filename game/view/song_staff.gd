class_name SongStaff
extends Node3D
## 美妙地(共歌节点每次唱歌)：从麦克风里旋出来一条五线谱——五条细光线排成一条带子，绕着她盘旋一圈多、
## 边转边往外扩、往下绕到腰间(螺旋)，几枚音符骑在谱线上跟着跑；头先伸出去(0.5 秒)、尾巴随后收掉，整条 1 秒左右。
## 五条线的间距朝"外 + 上"错开：俯视的镜头下也看得出是一条五线谱；线有深度测试，转到她身后时被她挡住(立体感)。

const LINES := 5
const SEG := 40
const LIFE := 0.9
const GAP := 0.055
const WIDTH := 0.016

var fx: Fx
var center := Vector3.ZERO           # 她脚下
var start := Vector3.ZERO            # 麦克风
var color := Color("#ff5aa6")
var turn := 1.0                       # 旋转方向(±1)
var a0 := 0.0
var _t := 0.0
var _im: ImmediateMesh
var _notes: Array[MeshInstance3D] = []


static func create(p_fx: Fx, p_center: Vector3, p_start: Vector3, p_color: Color, note_col: Color) -> SongStaff:
	var s := SongStaff.new()
	s.fx = p_fx
	s.center = p_center
	s.start = p_start
	s.color = p_color
	s.turn = 1.0 if randf() < 0.5 else -1.0
	var off: Vector3 = p_start - p_center
	s.a0 = atan2(off.z, off.x) if Vector2(off.x, off.z).length() > 0.05 else randf() * TAU
	s.top_level = true
	var mi := MeshInstance3D.new()
	s._im = ImmediateMesh.new()
	mi.mesh = s._im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.render_priority = 5
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 8.0
	s.add_child(mi)
	for i in range(4):
		var nm := MeshInstance3D.new()
		nm.mesh = p_fx.note2_mesh() if i % 2 == 1 else p_fx.note_mesh()
		nm.material_override = p_fx._icon_mat(note_col if i % 2 == 0 else p_color.lightened(0.25), 2.6)
		nm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		nm.scale = Vector3.ZERO
		s.add_child(nm)
		s._notes.append(nm)
	p_fx.add_child(s)
	return s


## 谱带中心线上 u(0..1)处的点：从麦克风出发，绕着她转 1.1 圈，半径 0.35 → 1.15 m，高度从麦克风往下落到腰间(俯视镜头下高处的东西会"飘"到身后的人头上)
func _at(u: float) -> Vector3:
	var a: float = a0 + turn * u * TAU * 1.1
	var r: float = lerpf(0.35, 1.15, u)
	var y: float = lerpf(start.y, center.y + 0.55, u) + 0.07 * sin(u * 9.0 + _t * 6.0)
	var p := center + Vector3(cos(a) * r, y - center.y, sin(a) * r)
	# 开头一小段从麦克风本身长出来
	return start.lerp(p, smoothstep(0.0, 0.12, u))


func _process(delta: float) -> void:
	var s: float = maxf(0.2, fx.speed_scale) if fx != null else 1.0
	_t += delta * s
	var k: float = _t / LIFE
	if k >= 1.0:
		queue_free()
		return
	var head: float = 1.0 - pow(1.0 - clampf(k / 0.5, 0.0, 1.0), 2.0)
	var tail: float = pow(clampf((k - 0.32) / 0.68, 0.0, 1.0), 1.6)
	var fade: float = 1.0 - smoothstep(0.75, 1.0, k)
	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() != null else null
	_im.clear_surfaces()
	if head - tail > 0.01:
		_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		var pts: Array[Vector3] = []
		for j in range(SEG + 1):
			pts.append(_at(lerpf(tail, head, float(j) / float(SEG))))
		for li in range(LINES):
			var lo: float = (float(li) - 2.0) * GAP
			var prev_l := Vector3.ZERO
			var prev_r := Vector3.ZERO
			var prev_c := Color()
			for j in range(SEG + 1):
				var p: Vector3 = pts[j]
				var tan: Vector3 = (pts[mini(j + 1, SEG)] - pts[maxi(j - 1, 0)]).normalized()
				var radial := Vector3(p.x - center.x, 0.0, p.z - center.z)
				radial = radial.normalized() if radial.length() > 0.01 else Vector3.RIGHT
				var lift: Vector3 = (radial * 0.55 + Vector3.UP * 0.85).normalized()
				var q: Vector3 = p + lift * lo
				var vd: Vector3 = (cam.global_position - q).normalized() if cam != null else Vector3.UP
				var wdir: Vector3 = tan.cross(vd)
				wdir = wdir.normalized() * WIDTH if wdir.length() > 1e-4 else Vector3.UP * WIDTH
				var u: float = float(j) / float(SEG)
				# 两端淡出(尾巴软、头部有一点亮)
				var a: float = fade * smoothstep(0.0, 0.18, u) * (0.75 + 0.25 * smoothstep(0.8, 1.0, u))
				var c := Color(color.r, color.g, color.b, a)
				var l: Vector3 = q - wdir
				var r: Vector3 = q + wdir
				if j > 0:
					_tri(prev_l, prev_r, r, prev_c, prev_c, c)
					_tri(prev_l, r, l, prev_c, c, c)
				prev_l = l
				prev_r = r
				prev_c = c
		_im.surface_end()
	# 骑在谱线上的音符：从头部往后排开，各占一条线
	for i in range(_notes.size()):
		var nm: MeshInstance3D = _notes[i]
		var u: float = head - 0.05 - 0.17 * float(i)
		if u <= tail + 0.02 or u <= 0.08:
			nm.scale = nm.scale.lerp(Vector3.ZERO, clampf(delta * s * 12.0, 0.0, 1.0))
			continue
		var p2: Vector3 = _at(u)
		var radial2 := Vector3(p2.x - center.x, 0.0, p2.z - center.z).normalized()
		nm.global_position = p2 + (radial2 * 0.55 + Vector3.UP * 0.85).normalized() * GAP * float(i % 3 - 1) * 1.5 + Vector3(0, 0.07, 0)
		nm.scale = nm.scale.lerp(Vector3.ONE * (1.7 if i % 2 == 0 else 1.5) * fade, clampf(delta * s * 14.0, 0.0, 1.0))


func _tri(a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	_im.surface_set_color(ca)
	_im.surface_add_vertex(a)
	_im.surface_set_color(cb)
	_im.surface_add_vertex(b)
	_im.surface_set_color(cc)
	_im.surface_add_vertex(c)
