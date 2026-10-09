class_name WeaponTrail
extends MeshInstance3D
## 刀光：武器骨(刃根 → 刃尖)扫过的轨迹画成一条渐隐的光带。
## 只在攻击动画的"发力 ~ 随挥"时间窗(WINDOWS)里取样，蓄力、收势不画；取样点之间用 Catmull-Rom 细分，
## 一两帧扫过大角度的快速挥砍也画成圆弧而不是折线。世界坐标(top_level)，不跟着棋子节点转。
## 游戏里每帧 _process 自己取样；审片工具(离线逐帧 seek)用 bake_at(t) 按动画时间回放取样。

## 各攻击动画里画刀光的时间窗(动画时间，秒)
const WINDOWS := {
	"attack_heavy": [0.36, 0.74], "attack_heavy_whirl": [0.50, 1.24],
	"attack_sword": [0.16, 0.42], "attack_guard": [0.16, 0.42],
	"attack_polearm": [0.19, 0.40], "attack_polearm_pierce": [0.21, 0.36],
	"attack_dual": [0.08, 0.36],
	"spin_dual": [0.04, 0.34], "spin_heavy": [0.05, 0.42],
	"attack_iaido": [0.21, 0.72],
	"attack_cone_noble_sword": [0.15, 0.40], "attack_cone_noble_polearm": [0.19, 0.46],
}
## 个别攻击动画的刀光换一套参数(武器在这一下变了样)：正行节点·花蕊的横扫 = 光剑 / 光枪的全长(LightWeapon.KINDS)，金色、留久一点
const ANIM_STYLES := {
	"attack_cone_noble_sword": {"base": 30.0, "tip": 325.0, "life": 0.2, "energy": 1.45, "alpha": 0.75, "color": Color("#ffd46a")},
	"attack_cone_noble_polearm": {"base": 70.0, "tip": 320.0, "life": 0.22, "energy": 1.45, "alpha": 0.75, "color": Color("#ffd46a")},
}
## 各武器大类的刀光：刃根/刃尖(武器骨局部 +Y，体素)、宽度感、存活时间、亮度
const STYLES := {
	"heavy": {"base": 16.0, "tip": 78.0, "life": 0.26, "energy": 1.5, "alpha": 0.92},
	"sword": {"base": 18.0, "tip": 58.0, "life": 0.15, "energy": 1.3, "alpha": 0.8},
	"polearm": {"base": 60.0, "tip": 88.0, "life": 0.14, "energy": 1.3, "alpha": 0.8},
	"dual": {"base": 8.0, "tip": 27.0, "life": 0.12, "energy": 1.2, "alpha": 0.75},
}
## 专属外观的刃长和默认款不一样时覆盖(武器外观 → 刀光参数)
const MODEL_STYLES := {
	"wolf": {"base": 10.0, "tip": 44.0, "life": 0.15, "energy": 1.3, "alpha": 0.82},
	# 炽霞(太刀)：刀身 8~57；连斩很快，刀光留久一点才连成一片弧
	"katana": {"base": 24.0, "tip": 57.0, "life": 0.12, "energy": 1.35, "alpha": 0.72, "color": Color("#ffc874")},
	# 希望(执剑节点)：剑身 14~63，比普通单手剑长
	"hope": {"base": 16.0, "tip": 63.0, "life": 0.15, "energy": 1.3, "alpha": 0.8},
	# 沉沦之梦(共歌节点的麦克风)：只有网罩那一小段(5~18)，淡粉色
	"mic": {"base": 5.0, "tip": 18.0, "life": 0.12, "energy": 1.1, "alpha": 0.6, "color": Color("#ffb8d8")},
	# 翠绿之林(守林节点的长杖)：杖头木环 + 绿宝珠在 62~89，嫩绿色
	"verdant": {"base": 62.0, "tip": 89.0, "life": 0.14, "energy": 1.2, "alpha": 0.7, "color": Color("#9fe07a")},
	# 号令短剑(通用武器)：剑身 7~52，比普通单手剑短
	"rally": {"base": 14.0, "tip": 52.0, "life": 0.14, "energy": 1.3, "alpha": 0.78},
	# 蚀月(通用武器的弯月刀)：刀身 7~58，越往刀尖越往刀背弯，刀光只取到 52
	"moon": {"base": 14.0, "tip": 52.0, "life": 0.15, "energy": 1.3, "alpha": 0.8, "color": Color("#c9a8ff")},
	# 第二批通用武器：猩红獠牙(牙尖往刀背弯，取到 30)、回响刃(剑身 7~54)；殉魂幡(法器)、锐眼步枪不画刀光
	"fang": {"base": 8.0, "tip": 30.0, "life": 0.14, "energy": 1.3, "alpha": 0.8, "color": Color("#ff6a6a")},
	"echo": {"base": 14.0, "tip": 54.0, "life": 0.15, "energy": 1.3, "alpha": 0.78, "color": Color("#6fe8ff")},
	# 通用武器 gen7(近战)：彩绸双刃(刃 5~27)、雾隐双刃(5~28)、鎏金军刀(7~57，刀尖往刀背弯，取到 53)、裁誓仪剑(6~57)、雷鸣巨剑(9~76)、蚀骨巨剑(10~76，钩尖取到 72)
	"g7_ribbon": {"base": 8.0, "tip": 26.0, "life": 0.13, "energy": 1.25, "alpha": 0.78, "color": Color("#ffd256")},
	"g7_mistveil": {"base": 8.0, "tip": 27.0, "life": 0.14, "energy": 1.2, "alpha": 0.7, "color": Color("#9feef2")},
	"g7_gilded": {"base": 14.0, "tip": 53.0, "life": 0.15, "energy": 1.35, "alpha": 0.8, "color": Color("#ffd970")},
	"g7_verdict": {"base": 16.0, "tip": 56.0, "life": 0.15, "energy": 1.3, "alpha": 0.78, "color": Color("#c49aff")},
	"g7_thunder": {"base": 16.0, "tip": 74.0, "life": 0.26, "energy": 1.6, "alpha": 0.92, "color": Color("#ffe45c")},
	"g7_blight": {"base": 16.0, "tip": 72.0, "life": 0.26, "energy": 1.5, "alpha": 0.9, "color": Color("#8cff5a")},
}
const VOX := 0.0125
const SUB := 5                         # 相邻两个取样点之间细分几段

var skel: Skeleton3D
var ap: AnimationPlayer
var bone: int = -1
var style: Dictionary = {}
var color: Color = Color.WHITE
var base_style: Dictionary = {}
var base_color: Color = Color.WHITE
var offline: bool = false              # 审片工具用 bake_at 手动取样，不走 _process
var _pts: Array = []                   # [[刃根, 刃尖, 取样时刻]]
var _clock: float = 0.0
var _im: ImmediateMesh
var _mat: StandardMaterial3D


static func create(p_skel: Skeleton3D, p_ap: AnimationPlayer, bone_name: String, wclass: String, p_color: Color, wmodel: String = "") -> WeaponTrail:
	if not STYLES.has(wclass) or p_skel == null:
		return null
	var tr := WeaponTrail.new()
	tr.skel = p_skel
	tr.ap = p_ap
	tr.bone = p_skel.find_bone(bone_name)
	var st: Dictionary = MODEL_STYLES.get(wmodel, {})
	if st.is_empty():
		st = ProjRegistry.trail(wmodel)      # 通用武器分批文件(game/view/proj_kinds/<批>.gd 的 TRAILS)
	tr.style = st if not st.is_empty() else STYLES[wclass]
	tr.color = tr.style.get("color", p_color)
	tr.base_style = tr.style
	tr.base_color = tr.color
	return tr if tr.bone >= 0 else null


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_im = ImmediateMesh.new()
	mesh = _im
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.vertex_color_is_srgb = true           # 颜色按 sRGB 给(否则当成线性色会发白、不饱和)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# 战场地面很亮，叠加光在白地上看不见：用普通混合 + 超过 1 的颜色(开了泛光会发一点光)
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.no_depth_test = false
	material_override = _mat


func _process(delta: float) -> void:
	if offline or skel == null or not is_instance_valid(skel):
		return
	_clock += delta
	if _in_window(ap.current_animation, ap.current_animation_position) and ap.is_playing():
		_use_style(ap.current_animation)
		_sample(_clock)
	var life: float = float(style["life"])
	while not _pts.is_empty() and _clock - float(_pts[0][2]) > life:
		_pts.pop_front()
	_rebuild(_clock)


## 最近两次取样的刀(世界坐标)：{base, tip, prev_tip}；不在刀光时间窗里 / 取样太旧时返回空。
## BattleView 用它给拔刀术的斩光、剑痕定方向(挥动平面、刀走的方向、砍到的高度)，动作改了特效自己跟着对上
func swing(max_age: float = 0.12) -> Dictionary:
	if _pts.size() < 2 or _clock - float(_pts[-1][2]) > max_age:
		return {}
	return {"base": _pts[-1][0], "tip": _pts[-1][1], "prev_tip": _pts[-2][1]}


## 换成这个动画的刀光参数(没有专门的就用武器自己的)；换的时候旧的取样点作废
func _use_style(anim: String) -> void:
	var st: Dictionary = ANIM_STYLES.get(anim, base_style)
	if st != style:
		style = st
		color = st.get("color", base_color)
		_pts.clear()


func _in_window(anim: String, pos: float) -> bool:
	var w: Array = WINDOWS.get(anim, [])
	return not w.is_empty() and pos >= float(w[0]) and pos <= float(w[1])


func _blade() -> Array:
	var x: Transform3D = skel.global_transform * skel.get_bone_global_pose(bone)
	return [x * Vector3(0.0, float(style["base"]) * VOX, 0.0), x * Vector3(0.0, float(style["tip"]) * VOX, 0.0)]


func _sample(t: float) -> void:
	var bt: Array = _blade()
	if not _pts.is_empty() and ((_pts[-1][1] as Vector3).distance_to(bt[1]) < 0.004):
		_pts[-1][2] = t
		return
	_pts.append([bt[0], bt[1], t])


## 审片用：把动画 seek 到 t 之前的若干时刻重新取样(按动画时间)，再回到 t
func bake_at(anim: String, t: float) -> void:
	_use_style(anim)
	_pts.clear()
	var life: float = float(style["life"])
	var steps: int = 10
	for k in range(steps, -1, -1):
		var ts: float = t - life * float(k) / float(steps)
		if ts < 0.0 or not _in_window(anim, ts):
			continue
		ap.seek(ts, true)
		_pts.append(_blade() + [ts])
	ap.seek(t, true)
	_rebuild(t)


static func _cr(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u: float) -> Vector3:
	var u2 := u * u
	var u3 := u2 * u
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u3)


func _rebuild(now: float) -> void:
	_im.clear_surfaces()
	var n: int = _pts.size()
	if n < 2:
		return
	var life: float = float(style["life"])
	var a0: float = float(style["alpha"])
	var c: Color = color * float(style["energy"])
	var edge: Color = Color(1.0, 1.0, 1.0) * (float(style["energy"]) + 0.4)
	# 细分后的点：[刃根, 刃尖, 新旧 k(1 = 刚扫过)]
	var ring: Array = []
	for i in range(n - 1):
		var i0: int = maxi(i - 1, 0)
		var i3: int = mini(i + 2, n - 1)
		for s in range(SUB + (1 if i == n - 2 else 0)):
			var u: float = float(s) / float(SUB)
			var b: Vector3 = _cr(_pts[i0][0], _pts[i][0], _pts[i + 1][0], _pts[i3][0], u)
			var tp: Vector3 = _cr(_pts[i0][1], _pts[i][1], _pts[i + 1][1], _pts[i3][1], u)
			var age: float = now - lerpf(float(_pts[i][2]), float(_pts[i + 1][2]), u)
			var k: float = clampf(1.0 - age / life, 0.0, 1.0)
			ring.append([b, tp, pow(k, 1.3)])
	# 主光带：刃尖一侧浓、刃根一侧淡；越旧越淡、越窄(刃根往刃尖收)
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _mat)
	for r: Array in ring:
		var k2: float = r[2]
		_im.surface_set_color(Color(c.r, c.g, c.b, a0 * k2 * 0.15))
		_im.surface_add_vertex((r[1] as Vector3).lerp(r[0], 0.3 + 0.7 * k2))
		_im.surface_set_color(Color(c.r, c.g, c.b, a0 * k2))
		_im.surface_add_vertex(r[1])
	_im.surface_end()
	# 刃尖一线白光(浅色地面上也看得清轮廓)
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _mat)
	for r2: Array in ring:
		var k3: float = r2[2]
		_im.surface_set_color(Color(edge.r, edge.g, edge.b, 0.0))
		_im.surface_add_vertex((r2[1] as Vector3).lerp(r2[0], 0.14 * k3))
		_im.surface_set_color(Color(edge.r, edge.g, edge.b, minf(1.0, a0 * 1.2) * k3))
		_im.surface_add_vertex(r2[1])
	_im.surface_end()
