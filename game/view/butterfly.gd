class_name Butterfly
extends Node3D
## 白羽节点的视觉原语：一只体素蝴蝶。黑蝶 = 送葬 / 死亡，白蝶 = 救赎 / 求生。
## 身体(细长的深色条)+ 左右两片翅膀(上翅 + 下翅画在一张像素图里)，翅膀绕身体轴扇动；1 体素 = 1.25 cm(和棋子同一个刻度)，
## size 1 = 翼展 20 cm。黑蝶 = 黑翅 + 白斑 + 一圈白的外缘(暗地上也看得清)；白蝶 = 白翅 + 淡蓝斑 + 一圈深色外缘(白地上也看得清)。
## 局部 +Z = 头的方向，翅膀平铺在局部 XZ 平面；face(dir) 让它朝飞行方向。
## ghost = 半透明发光的一只(求生的意志那对大翅膀)，alpha 用 set_alpha 调

const VOX := 0.0125
## 右翅(x 从身体往外 0..7，行从头到尾)：E = 外缘(只描远离身体的那一圈，小尺寸下翅面的颜色才占主导)，B = 翅面，S = 斑点
const WING := [
	"..EEEEE.",
	".EBBBBBE",
	"EBBBBSSE",
	"BBBBBSBE",
	"BBBBBBE.",
	"BBBBBE..",
	"BBSBBE..",
	"BBBBBE..",
	".BBBE...",
	"..BE....",
]
const COLS := {
	"black": {"B": Color("#120f18"), "E": Color("#f4f2ff"), "S": Color("#f4f2ff"), "body": Color("#0d0b12")},
	"white": {"B": Color("#f8f6ff"), "E": Color("#262033"), "S": Color("#6fb0ff"), "body": Color("#262033")},
}
static var _wing_mesh: Dictionary = {}
static var _body_mesh: Dictionary = {}
static var _mats: Dictionary = {}

var kind := "black"
var flap_hz := 7.0             # 每秒扇几下(30 帧的画面里别超过 ~10，不然闪)
var flap_lo := -0.35           # 翅膀最低(弧度，0 = 平展)
var flap_hi := 1.15            # 翅膀最高
var manual := false            # true：不自己扇，由 set_wing 摆
var time_scale := 1.0
var _t := 0.0
var _wl: MeshInstance3D
var _wr: MeshInstance3D
var _ghost_mat: StandardMaterial3D = null


static func make(p_kind: String, size: float = 1.0, ghost: bool = false) -> Butterfly:
	var b := Butterfly.new()
	b.kind = p_kind if COLS.has(p_kind) else "black"
	b._t = randf() * 10.0
	b.flap_hz = randf_range(6.0, 8.0)
	var mat: StandardMaterial3D = _mat(b.kind)
	if ghost:
		b._ghost_mat = mat.duplicate() as StandardMaterial3D
		b._ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		b._ghost_mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		b._ghost_mat.emission_enabled = true
		b._ghost_mat.emission = Color("#dfe9ff") if b.kind == "white" else Color("#2a2140")
		b._ghost_mat.emission_energy_multiplier = 0.8
		b._ghost_mat.no_depth_test = false
		b._ghost_mat.render_priority = 4
		mat = b._ghost_mat
	var body := MeshInstance3D.new()
	body.mesh = _body(b.kind)
	body.material_override = mat
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.add_child(body)
	b._wr = MeshInstance3D.new()
	b._wr.mesh = _wing(b.kind)
	b._wr.material_override = mat
	b._wr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.add_child(b._wr)
	b._wl = MeshInstance3D.new()
	b._wl.mesh = b._wr.mesh
	b._wl.material_override = mat
	b._wl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.add_child(b._wl)
	b.scale = Vector3.ONE * size
	b._apply(0.4)
	return b


static func _mat(k: String) -> StandardMaterial3D:
	if _mats.has(k):
		return _mats[k]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_fog = true
	_mats[k] = m
	return m


static func _cube(st: SurfaceTool, o: Vector3, sz: Vector3, c: Color) -> void:
	var p := [o, o + Vector3(sz.x, 0, 0), o + Vector3(sz.x, sz.y, 0), o + Vector3(0, sz.y, 0),
		o + Vector3(0, 0, sz.z), o + Vector3(sz.x, 0, sz.z), o + Vector3(sz.x, sz.y, sz.z), o + Vector3(0, sz.y, sz.z)]
	st.set_color(c)
	for f: Array in [[0, 1, 2, 3], [5, 4, 7, 6], [4, 0, 3, 7], [1, 5, 6, 2], [3, 2, 6, 7], [4, 5, 1, 0]]:
		for i: int in [0, 1, 2, 0, 2, 3]:
			st.add_vertex(p[f[i]])


static func _wing(k: String) -> ArrayMesh:
	if _wing_mesh.has(k):
		return _wing_mesh[k]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols: Dictionary = COLS[k]
	var rows: int = WING.size()
	for r in range(rows):
		var line: String = WING[r]
		for c in range(line.length()):
			var ch: String = line[c]
			if ch == ".":
				continue
			var o := Vector3(float(c) * VOX + VOX * 0.5, -VOX * 0.5, (float(rows) * 0.5 - float(r) - 1.0) * VOX + VOX * 0.5)
			_cube(st, o, Vector3(VOX, VOX, VOX), cols[ch])
	var m: ArrayMesh = st.commit()
	_wing_mesh[k] = m
	return m


static func _body(k: String) -> ArrayMesh:
	if _body_mesh.has(k):
		return _body_mesh[k]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c: Color = COLS[k]["body"]
	_cube(st, Vector3(-VOX * 0.5, -VOX * 0.5, -VOX * 3.0), Vector3(VOX, VOX, VOX * 8.0), c)
	# 两根触角
	_cube(st, Vector3(-VOX * 1.5, -VOX * 0.25, VOX * 5.0), Vector3(VOX * 0.5, VOX * 0.5, VOX * 2.5), c)
	_cube(st, Vector3(VOX * 1.0, -VOX * 0.25, VOX * 5.0), Vector3(VOX * 0.5, VOX * 0.5, VOX * 2.5), c)
	var m: ArrayMesh = st.commit()
	_body_mesh[k] = m
	return m


func _process(delta: float) -> void:
	if manual:
		return
	_t += delta * time_scale
	_apply(lerpf(flap_lo, flap_hi, 0.5 + 0.5 * sin(_t * TAU * flap_hz)))


func _apply(a: float) -> void:
	_wr.rotation = Vector3(0.0, 0.0, a)
	_wl.rotation = Vector3(0.0, 0.0, -a)
	_wl.scale = Vector3(-1.0, 1.0, 1.0)


## 手动摆翅膀(manual = true 时)：a = 弧度，0 = 平展
func set_wing(a: float) -> void:
	_apply(a)


## 朝飞行方向(头 = 局部 +Z)；身子跟着上下飞的方向微微抬头 / 低头
func face(dir: Vector3) -> void:
	if dir.length() < 1e-4:
		return
	var d: Vector3 = dir.normalized()
	if absf(d.y) > 0.98:
		d = (d + Vector3(0.01, 0.0, 0.01)).normalized()
	basis = Basis.looking_at(d, Vector3.UP, true).scaled(scale)


func set_alpha(a: float) -> void:
	if _ghost_mat != null:
		_ghost_mat.albedo_color = Color(1, 1, 1, clampf(a, 0.0, 1.0))
