extends "res://tools/anim_defs.gd"
## 战斗用动画：在 anim_defs 的基础上，按"武器大类"替换持武器的手臂姿态，并新增 攻击/死亡/胜利。
## 每个武器大类有一套 idle_* / run_* / attack_*(普攻模组，所有棋子通用)。
## 攻击动画的时长 = 该大类的基础攻击间隔，"出手时刻" = windup —— 两者都必须与 GC.WEAPON_CLASSES 一致
## (逻辑在出手时刻结算伤害/发射投射物；test_weapons.gd 会检查时长)：
##   sword 20f/0.26  polearm 24f/0.30  heavy 36f/0.52  dual 15f/0.18  bow 25f/0.34
##   crossbow 18f/0.20  pistols 13f/0.12  rifle 39f/0.50  focus 27f/0.36
## 武器朝向约定(与 tools/model_weapons.gd 一致)：近战武器局部 +Y = 刃；枪械/法器局部 -Y = 枪口(前)，+Z = 上。

var cur_kit: String = "bow"
var cur_guard: bool = false
var cur_tower: bool = false             # 副手是大盾(架盾节点)：cur_guard 同时为 true

const F := 1.0 / 30.0


func table() -> Dictionary:
	var t: Dictionary = super.table()
	# 弓用基础的 idle / walk / run：烘焙前也要把套件设回弓(男性款 *_m 是最后才烘的，不设的话会沿用上一个动作留下的套件)
	for nm: String in ["idle", "walk", "run"]:
		t[nm]["fn"] = Callable(self, nm + "_bow")
	for k: String in ["sword", "guard", "tower", "polearm", "heavy", "dual", "crossbow", "pistols", "pistols_tower", "rifle", "focus", "unarmed",
			"polearm_guard", "focus_guard"]:
		t["idle_" + k] = {"dur": 3.2, "loop": true, "fn": Callable(self, "idle_" + k)}
		t["run_" + k] = {"dur": 20.0 * F, "loop": true, "fn": Callable(self, "run_" + k)}
	# 持盾单手长枪 / 法器(副手是盾时：长枪、法器也只用右手拿，左臂照样挂盾——和剑盾同一套)
	t["attack_polearm_guard"] = {"dur": 24.0 * F, "loop": false, "fn": Callable(self, "attack_polearm_guard")}
	t["attack_polearm_guard_pierce"] = {"dur": 24.0 * F, "loop": false, "fn": Callable(self, "attack_polearm_guard_pierce")}
	t["attack_focus_guard"] = {"dur": 27.0 * F, "loop": false, "fn": Callable(self, "attack_focus_guard")}
	t["attack_bow"] = {"dur": 25.0 * F, "loop": false, "fn": Callable(self, "attack_bow")}
	t["draw_bow"] = {"dur": 12.0 * F, "loop": false, "fn": Callable(self, "draw_bow")}
	t["draw_bow_hold"] = {"dur": 30.0 * F, "loop": true, "fn": Callable(self, "draw_bow_hold")}
	t["release_bow"] = {"dur": 15.0 * F, "loop": false, "fn": Callable(self, "release_bow")}
	t["aim_bow"] = {"dur": 60.0 * F, "loop": true, "fn": Callable(self, "aim_bow")}
	t["attack_sword"] = {"dur": 20.0 * F, "loop": false, "fn": Callable(self, "attack_sword")}
	t["attack_guard"] = {"dur": 20.0 * F, "loop": false, "fn": Callable(self, "attack_guard")}
	t["attack_tower"] = {"dur": 20.0 * F, "loop": false, "fn": Callable(self, "attack_tower")}
	t["attack_pistols_tower"] = {"dur": 13.0 * F, "loop": false, "fn": Callable(self, "attack_pistols_tower")}
	t["turtle"] = {"dur": 36.0 * F, "loop": true, "fn": Callable(self, "turtle")}
	t["attack_polearm"] = {"dur": 24.0 * F, "loop": false, "fn": Callable(self, "attack_polearm")}
	t["attack_polearm_pierce"] = {"dur": 24.0 * F, "loop": false, "fn": Callable(self, "attack_polearm_pierce")}
	t["attack_heavy"] = {"dur": 36.0 * F, "loop": false, "fn": Callable(self, "attack_heavy")}
	t["attack_heavy_whirl"] = {"dur": 48.0 * F, "loop": false, "fn": Callable(self, "attack_heavy_whirl")}
	t["attack_dual"] = {"dur": 15.0 * F, "loop": false, "fn": Callable(self, "attack_dual")}
	# 技能：冲锋(狼狩)与落地旋斩(双刀 / 大剑各一套；UnitView 按武器大类的 skill_anims 选)
	t["dash_dual"] = {"dur": 15.0 * F, "loop": false, "fn": Callable(self, "dash_dual")}
	t["spin_dual"] = {"dur": 15.0 * F, "loop": false, "fn": Callable(self, "spin_dual")}
	t["dash_heavy"] = {"dur": 15.0 * F, "loop": false, "fn": Callable(self, "dash_heavy")}
	t["spin_heavy"] = {"dur": 18.0 * F, "loop": false, "fn": Callable(self, "spin_heavy")}
	# 技能：投掷武器(狩胜节点·必胜；四个近战大类各一套，出手 0.34s)与投掷后的飞扑
	for wk: String in ["polearm", "sword", "heavy", "dual"]:
		t["throw_" + wk] = {"dur": 21.0 * F, "loop": false, "fn": Callable(self, "throw_" + wk)}
	t["leap"] = {"dur": 15.0 * F, "loop": false, "fn": Callable(self, "leap")}
	# 摸鱼(空白节点)：战斗里蹲着打瞌睡
	t["idle_slack"] = {"dur": 3.2, "loop": true, "fn": Callable(self, "idle_slack")}
	# 换弹(开枪最快之人：手弩 / 双枪也要换弹)
	t["reload_crossbow"] = {"dur": 45.0 * F, "loop": false, "fn": Callable(self, "reload_crossbow")}
	t["reload_pistols"] = {"dur": 45.0 * F, "loop": false, "fn": Callable(self, "reload_pistols")}
	t["attack_crossbow"] = {"dur": 18.0 * F, "loop": false, "fn": Callable(self, "attack_crossbow")}
	t["attack_pistols"] = {"dur": 13.0 * F, "loop": false, "fn": Callable(self, "attack_pistols")}
	t["attack_rifle"] = {"dur": 20.0 * F, "loop": false, "fn": Callable(self, "attack_rifle")}
	t["aim_rifle"] = {"dur": 30.0 * F, "loop": true, "fn": Callable(self, "aim_rifle")}
	t["reload_rifle"] = {"dur": 78.0 * F, "loop": false, "fn": Callable(self, "reload_rifle")}
	t["attack_focus"] = {"dur": 27.0 * F, "loop": false, "fn": Callable(self, "attack_focus")}
	# 灾星节点：法杖待机、两种"召唤流星"的普攻(时长 / 出手时刻和法器、双手长大类一致)
	t["idle_staff"] = {"dur": 3.2, "loop": true, "fn": Callable(self, "idle_staff")}
	t["attack_witch_polearm"] = {"dur": 24.0 * F, "loop": false, "fn": Callable(self, "attack_witch_polearm")}
	t["attack_witch_focus"] = {"dur": 27.0 * F, "loop": false, "fn": Callable(self, "attack_witch_focus")}
	t["death"] = {"dur": 1.4, "loop": false, "fn": Callable(self, "death")}
	return t


# =============================================================== 关键帧采样
## keys: [[t, value, easing], ...]；easing: "s"(smooth,默认) "i"(先慢后快) "o"(先快后慢) "l"(线性)
static func _ease(mode: String, u: float) -> float:
	u = clampf(u, 0.0, 1.0)
	match mode:
		"i":
			return u * u * u
		"o":
			return 1.0 - pow(1.0 - u, 3.0)
		"l":
			return u
		_:
			return u * u * (3.0 - 2.0 * u)


static func kf_v(keys: Array, t: float) -> Vector3:
	if t <= float(keys[0][0]):
		return keys[0][1]
	for i in range(1, keys.size()):
		var t1: float = keys[i][0]
		if t <= t1:
			var t0: float = keys[i - 1][0]
			var mode: String = keys[i][2] if keys[i].size() > 2 else "s"
			return (keys[i - 1][1] as Vector3).lerp(keys[i][1], _ease(mode, (t - t0) / maxf(t1 - t0, 1e-6)))
	return keys[keys.size() - 1][1]


static func kf_f(keys: Array, t: float) -> float:
	if t <= float(keys[0][0]):
		return float(keys[0][1])
	for i in range(1, keys.size()):
		var t1: float = keys[i][0]
		if t <= t1:
			var t0: float = keys[i - 1][0]
			var mode: String = keys[i][2] if keys[i].size() > 2 else "s"
			return lerpf(float(keys[i - 1][1]), float(keys[i][1]), _ease(mode, (t - t0) / maxf(t1 - t0, 1e-6)))
	return float(keys[keys.size() - 1][1])


## 朝向关键帧：[[t, Quaternion, easing], ...]，相邻两帧之间 slerp(武器绕自身轴的滚转不会因为插值方向向量而翻面)
static func kf_q(keys: Array, t: float) -> Quaternion:
	if t <= float(keys[0][0]):
		return keys[0][1]
	for i in range(1, keys.size()):
		var t1: float = keys[i][0]
		if t <= t1:
			var t0: float = keys[i - 1][0]
			var mode: String = keys[i][2] if keys[i].size() > 2 else "s"
			return (keys[i - 1][1] as Quaternion).slerp(keys[i][1], _ease(mode, (t - t0) / maxf(t1 - t0, 1e-6)))
	return keys[keys.size() - 1][1]


# =============================================================== 待机 / 奔跑(按武器大类)
func _set_kit(k: String, guard: bool = false, tower: bool = false) -> void:
	cur_kit = k
	cur_guard = guard or tower
	cur_tower = tower


func idle_bow(t: float, p) -> void:
	_set_kit("bow")
	idle(t, p)


func walk_bow(t: float, p) -> void:
	_set_kit("bow")
	walk(t, p)


func run_bow(t: float, p) -> void:
	_set_kit("bow")
	run(t, p)


func idle_sword(t: float, p) -> void:
	_set_kit("sword")
	idle(t, p)


func idle_tower(t: float, p) -> void:
	_set_kit("sword", true, true)
	idle(t, p)


func run_tower(t: float, p) -> void:
	_set_kit("sword", true, true)
	run(t, p)


func idle_pistols_tower(t: float, p) -> void:
	_set_kit("pistols", true, true)
	idle(t, p)


func run_pistols_tower(t: float, p) -> void:
	_set_kit("pistols", true, true)
	run(t, p)


func idle_guard(t: float, p) -> void:
	_set_kit("sword", true)
	idle(t, p)


func idle_polearm(t: float, p) -> void:
	_set_kit("polearm")
	idle(t, p)


func idle_heavy(t: float, p) -> void:
	_set_kit("heavy")
	idle(t, p)


func idle_dual(t: float, p) -> void:
	_set_kit("dual")
	idle(t, p)


func idle_crossbow(t: float, p) -> void:
	_set_kit("crossbow")
	idle(t, p)


func idle_pistols(t: float, p) -> void:
	_set_kit("pistols")
	idle(t, p)


func idle_rifle(t: float, p) -> void:
	_set_kit("rifle")
	idle(t, p)


func idle_focus(t: float, p) -> void:
	_set_kit("focus")
	idle(t, p)


func idle_unarmed(t: float, p) -> void:
	_set_kit("unarmed")
	idle(t, p)


## 持盾单手长枪 / 单手法器：套件 polearm_1h / focus_1h + guard(左臂挂盾 = _left_guard)
func idle_polearm_guard(t: float, p) -> void:
	_set_kit("polearm_1h", true)
	idle(t, p)


func run_polearm_guard(t: float, p) -> void:
	_set_kit("polearm_1h", true)
	run(t, p)


func idle_focus_guard(t: float, p) -> void:
	_set_kit("focus_1h", true)
	idle(t, p)


func run_focus_guard(t: float, p) -> void:
	_set_kit("focus_1h", true)
	run(t, p)


func run_sword(t: float, p) -> void:
	_set_kit("sword")
	run(t, p)


func run_guard(t: float, p) -> void:
	_set_kit("sword", true)
	run(t, p)


func run_polearm(t: float, p) -> void:
	_set_kit("polearm")
	run(t, p)


func run_heavy(t: float, p) -> void:
	_set_kit("heavy")
	run(t, p)


func run_dual(t: float, p) -> void:
	_set_kit("dual")
	run(t, p)


func run_crossbow(t: float, p) -> void:
	_set_kit("crossbow")
	run(t, p)


func run_pistols(t: float, p) -> void:
	_set_kit("pistols")
	run(t, p)


func run_rifle(t: float, p) -> void:
	_set_kit("rifle")
	run(t, p)


func run_focus(t: float, p) -> void:
	_set_kit("focus")
	run(t, p)


func run_unarmed(t: float, p) -> void:
	_set_kit("unarmed")
	run(t, p)


# =============================================================== 持械工具
## 近战武器朝向：局部 +Y(刃) → axis，局部 +Z(刃宽) → side
static func wrot(axis: Vector3, side: Vector3) -> Quaternion:
	var y := axis.normalized()
	var x := y.cross(side).normalized()
	var z := x.cross(y)
	return Quaternion(Basis(x, y, z))


## 枪械/法器朝向：局部 -Y(枪口) → aim，局部 +Z → up
static func grot(aim: Vector3, up: Vector3) -> Quaternion:
	return wrot(-aim, up)


## 左右镜像一个世界朝向(x → -x)
static func mirror_q(q: Quaternion) -> Quaternion:
	var b := Basis(q)
	var m := Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))
	return Quaternion((m * b * m).orthonormalized())


static func mx(v: Vector3) -> Vector3:
	return Vector3(-v.x, v.y, v.z)


## 左手持(左手那把)武器：grip 为握点世界位置，rot 为武器世界朝向
func hold_left(p, grip: Vector3, rot: Quaternion, pole: Vector3) -> void:
	var w: Vector3 = grip - rot * BOW_GRIP_OFF
	p.ik2("UpperArm_L", "LowerArm_L", "Hand_L", w, pole)
	p.set_grot("Hand_L", rot)


func fist_l(p, curl: float) -> void:
	p.r("Fingers_L", -curl, 0, 0)
	p.r("Thumb_L", -curl * 0.35, 0, 0)


# =============================================================== 手臂与躯干的碰撞(防穿模)
## 躯干体积(静止坐标，体素)：照 model_body 的雕刻取几何体 —— 腰(Spine)/胸(Chest)的椭圆柱、两个罩杯的椭球、骨盆椭圆柱
## 返回把一个半径 r 的球推出躯干所需的最小位移(静止坐标)，不相交时为零
const TORSO_MARGIN := 0.4


static func _cyl_push(q: Vector3, y0: float, y1: float, rx0: float, rz0: float, rx1: float, rz1: float, r: float) -> Vector3:
	if q.y < y0 - 0.5 or q.y > y1 + 0.5:
		return Vector3.ZERO
	var t: float = clampf((q.y - y0) / (y1 - y0), 0.0, 1.0)
	var ax: float = lerpf(rx0, rx1, t) + r
	var az: float = lerpf(rz0, rz1, t) + r
	var e: float = (q.x / ax) * (q.x / ax) + (q.z / az) * (q.z / az)
	if e >= 1.0:
		return Vector3.ZERO
	var sq: float = sqrt(maxf(e, 1e-4))
	return Vector3(q.x, 0.0, q.z) * (1.0 / sq - 1.0) if sq > 0.01 else Vector3(0.0, 0.0, az)


static func _ell_push(q: Vector3, c: Vector3, rad: Vector3, r: float) -> Vector3:
	var d: Vector3 = q - c
	var a: Vector3 = rad + Vector3.ONE * r
	var e: float = (d.x / a.x) * (d.x / a.x) + (d.y / a.y) * (d.y / a.y) + (d.z / a.z) * (d.z / a.z)
	if e >= 1.0:
		return Vector3.ZERO
	var sq: float = sqrt(maxf(e, 1e-4))
	return d * (1.0 / sq - 1.0) if sq > 0.01 else Vector3(0.0, 0.0, a.z)


## part = "Chest"/"Spine"/"Hips"：只检查长在这块骨头上的几何
static func _torso_push(q: Vector3, r: float, part: String) -> Vector3:
	r += TORSO_MARGIN
	var best := Vector3.ZERO
	var cands: Array = []
	match part:
		"Chest":
			cands.append(_cyl_push(q, 57.5, 68.5, 7.6, 5.0, 8.7, 4.6, r))
			cands.append(_ell_push(q, Vector3(3.9, 62.6, 3.9), Vector3(4.2, 3.7, 3.7), r))
			cands.append(_ell_push(q, Vector3(-3.9, 62.6, 3.9), Vector3(4.2, 3.7, 3.7), r))
		"Spine":
			cands.append(_cyl_push(q, 50.5, 57.5, 6.2, 4.6, 7.4, 5.0, r))
		"Hips":
			cands.append(_cyl_push(q, 41.5, 50.5, 10.2, 5.2, 10.2, 5.2, r))
		"Head":                                   # 大头(含头发外壳)：方头方脑的 superquadric 用略大的椭球近似
			cands.append(_ell_push(q, Vector3(0.0, 85.4, -1.6), Vector3(15.0, 11.5, 13.2), r))
	for c: Vector3 in cands:
		if c.length() > best.length():
			best = c
	return best


## 世界坐标的一个球与躯干的穿透：按高度在胸/腰/骨盆各自的骨骼坐标系里检查；返回世界坐标的推出位移
func _world_push(p, q: Vector3, r: float) -> Vector3:
	var best := Vector3.ZERO
	for bn: String in ["Chest", "Spine", "Hips", "Head"]:
		var i: int = rig.ids[bn]
		var local: Vector3 = p.gx[i].affine_inverse() * q + rig.pos[i]
		var push: Vector3 = p.gx[i].basis * _torso_push(local, r, bn)
		if push.length() > best.length():
			best = push
	return best


## 一只手臂(side = "L"/"R")陷进躯干的最深处：{depth, where, push(世界坐标)}；
## 另外分开给出 elbow(上臂 + 前臂近肘段，要靠摆肘解决)与 wrist(前臂近腕段 + 手，要靠挪手解决)各自最深的推出量
func arm_penetration(p, side: String) -> Dictionary:
	var S: Vector3 = p.gpos_n("UpperArm_" + side)
	var E: Vector3 = p.gpos_n("LowerArm_" + side)
	var W: Vector3 = p.gpos_n("Hand_" + side)
	var F: Vector3 = p.gpos_n("Fingers_" + side)
	var samples: Array = []
	for t: float in [0.55, 0.75, 1.0]:          # 肩头本来就贴着胸廓，从上臂中段开始算
		samples.append([S.lerp(E, t), 2.4, "upper"])
	for t2: float in [0.25, 0.5]:
		samples.append([E.lerp(W, t2), 2.8, "fore"])
	for t3: float in [0.75, 1.0]:
		samples.append([E.lerp(W, t3), 2.8, "wrist"])
	samples.append([W.lerp(F, 0.5), 2.2, "hand"])
	var best := {"depth": 0.0, "where": "", "push": Vector3.ZERO, "elbow": Vector3.ZERO, "wrist": Vector3.ZERO}
	for sm: Array in samples:
		var push: Vector3 = _world_push(p, sm[0], sm[1])
		var key: String = "wrist" if (sm[2] == "wrist" or sm[2] == "hand") else "elbow"
		if push.length() > (best[key] as Vector3).length():
			best[key] = push
		if push.length() > float(best["depth"]):
			best["depth"] = push.length()
			best["where"] = sm[2]
			best["push"] = push
	return best


## 双手持同一把武器：设计上右手在 grip、左手在武器局部 +Y 方向 s 处(s<0 = 往剑柄尾)。
## 小短手 + 大胸廓，照设计直接解 IK 常常够不着或横穿胸口，所以按"两点约束"迭代松弛(position-based)：
##   · 手腕/手陷进躯干 → 那只手的握点沿推出方向(总带点向前)挪；右手挪 = 整把武器平移，左手挪 = 武器绕右手转
##   · 左手够不着 → 左握点往左肩方向拉(武器绕右手转向左肩)，实在不行再把两手间距收到 s_min
##   · 上臂/肘陷进去 → 肘往推出方向摆(改 IK 的 pole)
##   · 左手要伸到胸前偏右时左肩前探
## 每步修正量都随穿透深度连续变化(不穿就是零)，所以动画帧与帧之间不会跳。
const TWO_HAND_REACH := 18.6


func two_hand(p, grip: Vector3, rot: Quaternion, s: float, pole_r: Vector3, pole_l: Vector3, s_min: float = 4.0) -> void:
	var si: int = rig.ids["Shoulder_L"]
	var sh_rot: Quaternion = p.rot[si]
	var ax0: Vector3 = rot * Vector3.UP
	var sg: float = signf(s)
	var span: float = absf(s)
	var R: Vector3 = grip
	var L: Vector3 = grip + ax0 * s
	var pl: Vector3 = pole_l.normalized()
	var pr: Vector3 = pole_r.normalized()
	var q: Quaternion = rot
	for it in 18:
		q = Quaternion(ax0, ((L - R) * sg).normalized()) * rot
		p.rot[si] = sh_rot
		p.dirty = true
		hold_bow(p, R, q, pr)
		fist_r(p, 80.0)
		_protract_l(p, L)
		hold_left(p, L, q, pl)
		fist_l(p, 80.0)
		p.fk()
		var cl: Dictionary = arm_penetration(p, "L")
		var cr: Dictionary = arm_penetration(p, "R")
		var over_l: float = (L - q * BOW_GRIP_OFF - p.gpos_n("UpperArm_L")).length() - TWO_HAND_REACH
		var over_r: float = (R - q * BOW_GRIP_OFF - p.gpos_n("UpperArm_R")).length() - TWO_HAND_REACH
		if float(cl["depth"]) + float(cr["depth"]) < 0.03 and over_l < 0.03 and over_r < 0.03:
			break
		var fwd: Vector3 = p.gx[rig.ids["Chest"]].basis.z.normalized()
		var dR: Vector3 = _fwd_push(cr["wrist"], fwd) * 0.8 + (cr["elbow"] as Vector3) * (0.3 + 0.4 * _straightness(p, "R"))
		if over_r > 0.0:
			dR += (p.gpos_n("UpperArm_R") - (R - q * BOW_GRIP_OFF)).normalized() * over_r * 0.8
		R += dR
		L += dR
		# 上臂/肘的穿透光摆肘常常不够(肘的可选位置整圈都贴着胸)，也分一部分给手；手臂越直分得越多
		var dL: Vector3 = _fwd_push(cl["wrist"], fwd) * 0.8 + (cl["elbow"] as Vector3) * (0.3 + 0.4 * _straightness(p, "L"))
		var dT := Vector3.ZERO
		if over_l > 0.0:
			var pull: Vector3 = (p.gpos_n("UpperArm_L") - (L - q * BOW_GRIP_OFF)).normalized() * over_l * 0.8
			dL += pull * 0.6
			dT += pull * 0.4           # 光转不够就整把往左肩那边平移一点
			if it >= 8:
				span = maxf(s_min, span - over_l * 0.5)
		R += dT
		L += dL + dT
		L = R + (L - R).normalized() * span
		pl = (pl + (cl["elbow"] as Vector3) * 0.3).normalized()
		pr = (pr + (cr["elbow"] as Vector3) * 0.3).normalized()


## 手臂伸直程度：0 = 肘弯 60° 以上，1 = 完全伸直
func _straightness(p, side: String) -> float:
	var S: Vector3 = p.gpos_n("UpperArm_" + side)
	var E: Vector3 = p.gpos_n("LowerArm_" + side)
	var W: Vector3 = p.gpos_n("Hand_" + side)
	var c: float = (E - S).normalized().dot((W - E).normalized())
	return clampf((c - 0.5) / 0.5, 0.0, 1.0)


## 推出方向总带一点"向前"：双手握持时手在身前，往后推只会越推越进
static func _fwd_push(push: Vector3, fwd: Vector3) -> Vector3:
	var m: float = push.length()
	if m < 1e-4:
		return Vector3.ZERO
	var d: Vector3 = push / m
	if d.dot(fwd) < 0.0:
		d -= fwd * d.dot(fwd)
	return (d + fwd * 0.6).normalized() * m


## 左手目标在胸前偏右时，左肩(锁骨)往前转，最多 24°
func _protract_l(p, target: Vector3) -> void:
	var ci: int = rig.ids["Chest"]
	p.fk()
	var loc: Vector3 = p.gx[ci].affine_inverse() * target + rig.pos[ci]
	var k: float = clampf((10.0 - loc.x) / 18.0, 0.0, 1.0) * clampf((loc.z - 1.0) / 8.0, 0.0, 1.0)
	if k > 0.0:
		p.radd("Shoulder_L", 0.0, -24.0 * k, 0.0)


## 右手自然下垂(空手)
func right_relaxed(p, target: Vector3, rot: Quaternion, curl: float = 14.0) -> void:
	p.ik2("UpperArm_R", "LowerArm_R", "Hand_R", target, Vector3(-0.6, -0.2, -1.0))
	p.set_grot("Hand_R", rot)
	p.r("Fingers_R", -curl, 0, 22.0)
	p.r("Thumb_R", -10.0, 0, 0)


func _left_idle(p, s1: float) -> void:
	relax_l(p, s1)


# ---- 各大类"待机持械"关键量(攻击动画首尾帧也回到这里，保证衔接)
## 双手长/重武器：Q 版小短手够不到身体另一侧，两只手只能都握在胸腹正前方一小块地方；
## 武器的朝向靠整个躯干扭转来摆(站姿)，所以这里的握点/轴都是"胸腔局部"的，世界里的朝向 = 再转 *_YAW 度
const POLE_GRIP := Vector3(-4.5, 52.0, 9.0)
const POLE_AXIS := Vector3(0.8, 0.32, 0.5)          # 胸腔局部指向左前上；侧身 -45° 后在世界里指正前方、略上挑
const POLE_SPAN := 10.0
const POLE_YAW := -45.0                             # 左肩向前的侧身枪架
const POLE_LEAD := 3.0                              # 左脚在前
const HEAVY_GRIP := Vector3(-3.0, 55.5, 11.5)
const HEAVY_AXIS := Vector3(-0.6, -0.45, 0.68)      # 胸腔局部指右前下；右肩向前 35° 后剑尖在世界里指正前下方
const HEAVY_SPAN := -6.0
const HEAVY_YAW := 35.0
const HEAVY_LEAD := -3.0                            # 右脚在前
const DUAL_GRIP := Vector3(-13.0, 48.5, 8.5)
const DUAL_AXIS := Vector3(-0.15, 0.55, 1.0)
const XBOW_GRIP := Vector3(-14.5, 48.0, 7.5)
const XBOW_AIM := Vector3(0.05, -0.55, 1.0)
const PIST_GRIP := Vector3(-14.0, 48.0, 7.5)
const PIST_AIM := Vector3(-0.08, -0.6, 1.0)
const RIFLE_GRIP := Vector3(-10.0, 49.0, 9.0)
const RIFLE_AIM := Vector3(0.75, 0.62, 0.25)
const RIFLE_UP := Vector3(-0.3, 0.2, 1.0)
const FOCUS_GRIP := Vector3(-9.5, 51.5, 11.0)
const FOCUS_AIM := Vector3(0.35, -0.15, 1.0)
## 持盾单手长枪(polearm_1h)：右手在右胯前握住枪的重心(枪尾夹在小臂下、伸到右后方，不穿过身体)，枪尖朝前上 ~30°、略往里收；
## 盾侧(左肩)稍稍朝前、左脚在前半步。轴是胸腔局部方向
const SPEAR1_GRIP := Vector3(-14.0, 48.5, 8.5)
const SPEAR1_AXIS := Vector3(0.06, 0.52, 0.85)
const SPEAR1_YAW := -10.0
const SPEAR1_LEAD := 2.0
## 持盾单手法器(focus_1h)：法器托在右胯前、比无盾时更靠右(盾护着左前方，球别被盾挡住)
const FOCUS1_GRIP := Vector3(-12.0, 51.5, 10.5)
const FOCUS1_AIM := Vector3(0.25, -0.15, 1.0)
const SHIELD_GUARD := Vector3(7.5, 53.0, 10.5)      # _left_guard 的左手位置(胸腔局部)


## 刃宽方向取"轴在 YZ 平面内转 90°"：挥舞(竖直平面内)时刃口始终朝挥动方向，轴竖直时也不退化
static func _side_yz(axis: Vector3) -> Vector3:
	var s: Vector3 = Vector3.RIGHT.cross(axis.normalized())
	return s if s.length() > 0.05 else Vector3.UP


func _pole_rot(axis: Vector3) -> Quaternion:
	return wrot(axis, _side_yz(axis))


func _heavy_rot(axis: Vector3) -> Quaternion:
	return wrot(axis, _side_yz(axis))


func _dual_rot(axis: Vector3) -> Quaternion:
	return wrot(axis, Vector3(-1.0, 0.3, 0.0))


## 胸腔当前的世界朝向(胸腔局部的武器朝向 × 它 = 世界朝向)
func _chest_q(p) -> Quaternion:
	p.fk()
	return Quaternion(p.gx[rig.ids["Chest"]].basis.orthonormalized())


## axis 是胸腔局部方向(见上面常量的说明)，换成世界方向再定武器朝向
func _chest_dir(p, v: Vector3) -> Vector3:
	p.fk()
	return (p.gx[rig.ids["Chest"]].basis * v).normalized()


func _hold_pole(p, grip_local: Vector3, axis: Vector3, span: float = POLE_SPAN) -> void:
	two_hand(p, follow(p, "Chest", grip_local), _pole_rot(_chest_dir(p, axis)), span, Vector3(-1.0, -0.5, -0.3), Vector3(1.0, -0.5, -0.2))


## frame = 整个人绕竖轴转过的角度(旋斩原地转圈)：剑的"侧向"参考与两肘的 IK pole 都跟着转，否则转到背面时会翻。
## side ≠ 0 时用固定的侧向参考(剑往身后大幅收时 _heavy_rot 的侧向会翻面)
func _hold_heavy(p, grip_local: Vector3, axis: Vector3, span: float = HEAVY_SPAN, frame: Quaternion = Quaternion.IDENTITY,
		side: Vector3 = Vector3.ZERO) -> void:
	var la: Vector3 = frame.inverse() * _chest_dir(p, axis)
	var rot: Quaternion = frame * (_heavy_rot(la) if side == Vector3.ZERO else wrot(la, side))
	two_hand(p, follow(p, "Chest", grip_local), rot, span, frame * Vector3(-1.0, -0.5, -0.2), frame * Vector3(1.0, -0.5, -0.1), 4.0)


## 持械站姿(待机用)：骨盆/腰/胸一起扭 yaw 度(正 = 右肩向前)，脚重新踩成前后步(lead > 0 左脚在前)，头转回来看正前方
func _stance(p, yaw: float, lead: float) -> void:
	p.radd("Hips", 0.0, yaw * 0.35, 0.0)
	p.radd("Spine", 0.0, yaw * 0.30, 0.0)
	p.radd("Chest", 0.0, yaw * 0.35, 0.0)
	p.radd("Head", 0.0, -yaw * 0.8, 0.0)
	_stance_feet(p, 6.5 + 2.2 * mk(), lead)


## 跑动时只扭上身(腿在跑)
func _run_twist(p, yaw: float) -> void:
	p.radd("Spine", 0.0, yaw * 0.45, 0.0)
	p.radd("Chest", 0.0, yaw * 0.55, 0.0)
	p.radd("Head", 0.0, -yaw * 0.8, 0.0)


func _hold_rifle(p, grip_local: Vector3, aim: Vector3, up: Vector3, s: float = -13.0) -> void:
	two_hand(p, follow(p, "Chest", grip_local), grot(aim, up), s, Vector3(-1.0, -0.5, -0.3), Vector3(0.8, -0.8, 0.0))


func _ready_pose(p, kit: String, s1: float) -> void:
	var b: Vector3 = Vector3(0.0, 0.4 * s1, 0.0)
	match kit:
		"polearm":
			_stance(p, POLE_YAW, POLE_LEAD)
			_hold_pole(p, POLE_GRIP + b, POLE_AXIS)
		"heavy":
			_stance(p, HEAVY_YAW, HEAVY_LEAD)
			_hold_heavy(p, HEAVY_GRIP + b, HEAVY_AXIS)
		"dual":
			var r0: Quaternion = _dual_rot(DUAL_AXIS)
			hold_bow(p, follow(p, "Chest", DUAL_GRIP + b), r0, Vector3(-1.0, -0.4, -0.5))
			fist_r(p, 80.0)
			hold_left(p, follow(p, "Chest", mx(DUAL_GRIP) + b), mirror_q(r0), Vector3(1.0, -0.4, -0.5))
			fist_l(p, 80.0)
		"crossbow":
			hold_bow(p, follow(p, "Chest", XBOW_GRIP + b), grot(XBOW_AIM, Vector3(0.0, 1.0, 0.4)), Vector3(-1.0, -0.4, -0.6))
			fist_r(p, 80.0)
			_left_idle(p, s1)
		"pistols":
			var q0: Quaternion = grot(PIST_AIM, Vector3(0.0, 1.0, 0.45))
			hold_bow(p, follow(p, "Chest", PIST_GRIP + b), q0, Vector3(-1.0, -0.4, -0.6))
			fist_r(p, 80.0)
			if cur_tower:
				_left_tower(p, s1, false)
			else:
				hold_left(p, follow(p, "Chest", mx(PIST_GRIP) + b), mirror_q(q0), Vector3(1.0, -0.4, -0.6))
				fist_l(p, 80.0)
		"rifle":
			_hold_rifle(p, RIFLE_GRIP + b, RIFLE_AIM, RIFLE_UP)
		"focus":
			hold_bow(p, follow(p, "Chest", FOCUS_GRIP + b * 1.2), grot(FOCUS_AIM, Vector3(0.0, 1.0, 0.15)), Vector3(-1.0, -0.5, -0.4))
			fist_r(p, 70.0)
			_left_idle(p, s1)
		"unarmed":
			var m := mk()
			right_relaxed(p, follow(p, "Chest", Vector3(-15.2 - 2.6 * m, 49.0 + 0.3 * s1 + 0.5 * m, 1.6 + 1.8 * m)),
				Lib.E(-6.0 + 2.0 * m, 8.0 - 5.0 * m, -10.0 - 2.0 * s1 + 7.0 * m), 14.0 - 3.0 * s1 + 22.0 * m)
			_left_idle(p, s1)


func _arms_idle(p, s1: float, th: float) -> void:
	match cur_kit:
		"sword":
			var rot: Quaternion = Lib.E(34.0 + 1.5 * s1, 0.0, 10.0)
			var grip: Vector3 = follow(p, "Chest", Vector3(-14.5, 47.0 + 0.4 * s1, 9.0))
			hold_bow(p, grip, rot, Vector3(-1.0, -0.25, -0.35))
			fist_r(p, 70.0)
		"polearm_1h":
			_stance(p, SPEAR1_YAW, SPEAR1_LEAD)
			_hold_spear1(p, SPEAR1_GRIP + Vector3(0.0, 0.4 * s1, 0.0), SPEAR1_AXIS)
		"focus_1h":
			hold_bow(p, follow(p, "Chest", FOCUS1_GRIP + Vector3(0.0, 0.5 * s1, 0.0)), _chest_q(p) * grot(FOCUS1_AIM, Vector3(0.0, 1.0, 0.15)), Vector3(-1.0, -0.5, -0.4))
			fist_r(p, 70.0)
		"bow":
			super._arms_idle(p, s1, th)
			return
		"staff":
			# 法杖(灾星节点拿双手长武器)：右手竖握在身侧，杖尾点地；左手自然垂着
			hold_bow(p, follow(p, "Chest", STAFF_GRIP + Vector3(0.0, 0.4 * s1, 0.0)), _chest_q(p) * wrot(STAFF_AXIS, Vector3(0, 0, 1)), Vector3(-1.0, -0.3, -0.4))
			fist_r(p, 82.0)
			_left_idle(p, s1)
			return
		_:
			_ready_pose(p, cur_kit, s1)
			return
	if cur_tower:
		_left_tower(p, s1, false)
	elif cur_guard:
		_left_guard(p, s1)
	else:
		_left_idle(p, s1)


func _arms_run(p, s: float, th: float) -> void:
	var bob: Vector3 = Vector3(0.0, 1.0 * sin(2.0 * th), 0.0)
	match cur_kit:
		"sword":
			var rot: Quaternion = Lib.E(58.0 - 7.0 * s, 0.0, 8.0)
			var grip: Vector3 = follow(p, "Chest", Vector3(-14.0, 47.0, 9.0 - 3.5 * s) + bob)
			hold_bow(p, grip, rot, Vector3(-1.0, -0.25, -0.35))
			fist_r(p, 75.0)
		"polearm":
			_run_twist(p, -30.0)
			_hold_pole(p, POLE_GRIP + Vector3(0.0, 1.0, -0.5 - 1.0 * s) + bob, Vector3(0.8, 0.22, 0.55))
			return
		"heavy":
			# 单手把大剑扛在右肩上跑，左臂自由摆动(双手扛肩的话左手得横穿胸口)
			hold_bow(p, follow(p, "Chest", Vector3(-11.0, 60.0, 7.5) + bob), _heavy_rot(_chest_dir(p, Vector3(-0.45, 0.75 + 0.04 * s, -0.75))), Vector3(-1.0, -0.8, -0.3))
			fist_r(p, 80.0)
		"dual":
			var r0: Quaternion = _dual_rot(Vector3(-0.1, 0.2, 1.0))
			hold_bow(p, follow(p, "Chest", Vector3(-13.0, 50.0, 6.0 - 5.0 * s) + bob), r0, Vector3(-1.0, -0.4, -0.5))
			fist_r(p, 80.0)
			hold_left(p, follow(p, "Chest", Vector3(13.0, 50.0, 6.0 + 5.0 * s) + bob), mirror_q(r0), Vector3(1.0, -0.4, -0.5))
			fist_l(p, 80.0)
			return
		"crossbow":
			hold_bow(p, follow(p, "Chest", Vector3(-14.0, 50.0, 7.0 - 3.0 * s) + bob), grot(Vector3(0.05, -0.35, 1.0), Vector3(0.0, 1.0, 0.4)), Vector3(-1.0, -0.4, -0.6))
			fist_r(p, 80.0)
		"pistols":
			var q0: Quaternion = grot(Vector3(-0.05, -0.3, 1.0), Vector3(0.0, 1.0, 0.4))
			hold_bow(p, follow(p, "Chest", Vector3(-13.5, 50.0, 7.0 - 4.0 * s) + bob), q0, Vector3(-1.0, -0.4, -0.6))
			fist_r(p, 80.0)
			if cur_tower:
				_left_tower(p, 0.5 * sin(2.0 * th), true)
				return
			hold_left(p, follow(p, "Chest", Vector3(13.5, 50.0, 7.0 + 4.0 * s) + bob), mirror_q(q0), Vector3(1.0, -0.4, -0.6))
			fist_l(p, 80.0)
			return
		"rifle":
			_hold_rifle(p, RIFLE_GRIP + Vector3(0.0, 1.0, 0.0) + bob, RIFLE_AIM, RIFLE_UP)
			return
		"focus":
			hold_bow(p, follow(p, "Chest", Vector3(-11.0, 52.0, 9.0 - 2.5 * s) + bob), grot(Vector3(0.3, -0.1, 1.0), Vector3(0.0, 1.0, 0.15)), Vector3(-1.0, -0.5, -0.4))
			fist_r(p, 70.0)
		"polearm_1h":
			# 跑：枪压低一点(冲锋的架势)、夹在右肋下，枪尾伸到右后方(离迈到后面的腿远远的)
			_run_twist(p, -8.0)
			_hold_spear1(p, Vector3(-14.0, 50.0, 8.5 - 2.0 * s) + bob, Vector3(0.08, 0.4, 0.91))
		"focus_1h":
			hold_bow(p, follow(p, "Chest", Vector3(-12.5, 52.0, 9.0 - 2.5 * s) + bob), _chest_q(p) * grot(Vector3(0.25, -0.1, 1.0), Vector3(0.0, 1.0, 0.15)), Vector3(-1.0, -0.5, -0.4))
			fist_r(p, 70.0)
		"unarmed":
			var mr := mk()
			p.r("UpperArm_R", -(28.0 + 8.0 * mr) * s - 3.0, 0, -9.0 - 3.0 * mr)
			p.r("LowerArm_R", -(48.0 + 16.0 * (0.5 + 0.5 * s)) - 10.0 * mr, 0, 0)
			p.r("Hand_R", -8.0, 0, 0)
			p.r("Fingers_R", -50.0 - 30.0 * mr, 0, 18.0)
			p.r("Thumb_R", -10.0, 0, 0)
		_:
			super._arms_run(p, s, th)
			return
	if cur_tower:
		_left_tower(p, 0.5 * sin(2.0 * th), true)
	elif cur_guard:
		_left_guard(p, 0.5 * sin(2.0 * th))
	else:
		var ml := mk()
		p.r("UpperArm_L", (28.0 + 8.0 * ml) * s - 3.0, 0, 9.0 + 3.0 * ml)
		p.r("LowerArm_L", -(48.0 + 16.0 * (0.5 - 0.5 * s)) - 10.0 * ml, 0, 0)
		p.r("Hand_L", -8.0, 0, 0)
		p.r("Fingers_L", -50.0 - 30.0 * ml, 0, -18.0)
		p.r("Thumb_L", -10.0, 0, 0)


## 左臂持盾格挡：手举到胸前偏左，盾面朝前
## 左手持大盾(架盾节点)：盾面朝前立在身体左前方，从小腿挡到下巴；跑步时抬高、往前一点(别让迈出去的脚踢到盾底)
## push 0..1 = 往前顶(攻击时的盾推)。盾的网格按"静止时的左手"雕刻，手的朝向跟着胸腔走
const TOWER_HAND := Vector3(8.5, 51.5, 11.5)


func _left_tower(p, wobble: float, running: bool, push: float = 0.0) -> void:
	var tgt: Vector3 = TOWER_HAND + Vector3(0.0, 0.4 * wobble, 0.0)
	if running:
		tgt += Vector3(0.5, 7.0, 2.5)
	tgt += Vector3(-0.5, 0.5, 3.5) * push
	p.ik2("UpperArm_L", "LowerArm_L", "Hand_L", follow(p, "Chest", tgt), Vector3(0.9, -0.4, -0.4))
	p.set_grot("Hand_L", _chest_q(p) * Lib.E(0.0, -6.0, 0.0))
	p.r("Fingers_L", -75.0, 0, 0)
	p.r("Thumb_L", -40.0, 0, 0)


func _left_guard(p, wobble: float) -> void:
	var tgt: Vector3 = follow(p, "Chest", Vector3(7.5, 53.0 + 0.4 * wobble, 10.5))
	p.ik2("UpperArm_L", "LowerArm_L", "Hand_L", tgt, Vector3(0.7, -0.5, -0.6))
	p.set_grot("Hand_L", Lib.E(0.0, -12.0, 0.0))
	p.r("Fingers_L", -70.0, 0, 0)
	p.r("Thumb_L", -40.0, 0, 0)


# =============================================================== 攻击：通用小工具
## 躯干扭转：yaw 度(正=右肩向前)，lean 前倾度(正=前倾)
func _twist(p, yaw: float, lean: float, hip_push: float = 0.0, hips_drop: float = 0.0, head_k: float = 0.5) -> void:
	p.move("Hips", Vector3(0.0, -1.7 - hips_drop, hip_push))
	p.r("Hips", lean * 0.4, yaw * 0.35, 0.0)
	p.r("Spine", lean * 0.3, yaw * 0.30, 0.0)
	p.r("Chest", lean * 0.3, yaw * 0.35, 0.0)
	p.r("Head", -lean * 0.4, -yaw * head_k, 0.0)


## 两只脚分别给前后位置(z，正=往前)、抬脚高度与脚尖朝向(度)：用来做上步、退步、蹬地
func _feet(p, spread: float, lz: float, llift: float, rz: float, rlift: float, lyaw: float = 6.0, ryaw: float = -6.0) -> void:
	legs(p, Vector3(spread, ANKLE_Y + llift, -0.5 + lz), Vector3(-spread, ANKLE_Y + rlift, -0.5 + rz), Lib.E(0, lyaw, 0), Lib.E(0, ryaw, 0))


## 前后站的上步：lead0 = 待机时的前后差(>0 左脚在前)，lead = 此刻前脚的位置；后脚不动，前脚抬起 lift
func _stance_step(p, spread: float, lead0: float, lead: float, lift: float) -> void:
	if lead0 >= 0.0:
		_feet(p, spread, lead, lift, -lead0, 0.0)
	else:
		_feet(p, spread, lead0, 0.0, -lead, lift)


## t 在 [t0, t1] 内走一个 0 → h → 0 的正弦拱(抬脚、跳起)
static func _arc(t: float, t0: float, t1: float, h: float) -> float:
	if t <= t0 or t >= t1:
		return 0.0
	return h * sin(PI * (t - t0) / (t1 - t0))


func _stance_feet(p, spread: float = 6.5, fwd: float = 0.0) -> void:
	legs(p, Vector3(spread, ANKLE_Y, -0.5 + fwd), Vector3(-spread, ANKLE_Y, -0.5 - fwd), Lib.E(0, 6.0, 0), Lib.E(0, -6.0, 0))


# =============================================================== 攻击：弓 (25f = 0.83s，出手 0.34s)
## 连射的一个循环从"预备"开始、回到"预备"结束(身体一直侧着、脚不动，不会每一箭都转回正面再转过去)：
##   预备(弓斜压在身前右下，拉弦手捏着下一支箭垂在左胯旁) → 0~0.20s 举弓对准，拉弦手 0~0.12s 把箭带上弦，0.05~0.29s 拉到下颌
##   → 一瞬瞄准 → 0.34s 放箭 → 残心(拉弦手顺着下颌甩开) → 0.12s 起弓放低回预备，拉弦手同时下到左胯旁抽出下一支箭 → 预备
## 第一箭从待机进来、最后一箭回待机靠 UnitView 的交叉淡化；两箭之间有空当时播 aim_bow(预备姿势的循环，GC 的 hold_anim)
## 普攻带 [吟唱] 时出手前改接：draw_bow(再往后拉到耳边，越拉越慢) → draw_bow_hold(拉住不动、持续用力的颤抖，循环)
##   → release_bow(放箭后的后半段，比普通放箭更猛)。draw_bow 的末帧 = draw_bow_hold 的首帧(颤抖用同一条周期信号)
const BOW_REL := 0.34
const BOW_DRAW_IN := 12.0 * F        # draw_bow 时长
const BOW_HOLD := 30.0 * F           # draw_bow_hold 循环周期(颤抖信号的周期)
const BOW_AFTER := 15.0 * F          # 放箭后到收弓结束 = 攻击间隔 - 出手时刻
const BOW_READY_ST := 0.6            # 预备时上身侧过去的程度(瞄准时 = 1)：开一点，拉弦手才能从身前把箭带上弦；拉弦时上身再转成全侧身
const BOW_AIM_HOLD := 60.0 * F       # aim_bow 循环周期


## 预备姿势(弓压低，箭捏在拉弦手里)：breath = 呼吸相位(弧度)，k = 呼吸幅度；breath = 0 时就是攻击动画的首尾帧
func _bow_ready(p, breath: float, k: float) -> void:
	archer_pose(p, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0,
		{"stance": BOW_READY_ST, "feet": 1.0, "low": 1.0, "pluck": 1.0, "arrow_hand": 1.0,
		"shake_bow": Vector3(0.0, 0.35 * sin(breath), 0.25 * (1.0 - cos(breath))) * k})
	p.radd("Chest", -0.6 * (1.0 - cos(breath)) * k, 0.0, 0.0)


func attack_bow(t: float, p) -> void:
	p.reset()
	if t >= BOW_REL:
		_bow_released(p, t - BOW_REL, 0.0, t * 30.0)
		return
	var lift: float = Lib.smooth(t / 0.2)
	var nock: float = 1.0 - Lib.smooth(t / 0.12)                     # 箭从胯旁带上弦
	var pull: float = Lib.smoother((t - 0.05) / 0.24)
	# 拉到位后的一瞬：弓手往前送一点点、呼吸停住
	archer_pose(p, 1.0, pull, pull, 0.0, t * 30.0, 0.0, 0.0, 1.0, Lib.smooth(pull * 1.15),
		{"stance": lerpf(BOW_READY_ST, 1.0, Lib.smooth((t - 0.04) / 0.22)), "feet": 1.0, "low": 1.0 - lift, "pluck": nock, "arrow_hand": nock,
		"strain": 0.25 * Lib.smooth((t - 0.22) / 0.1)})
	set_lids(p, 0.0)


## 两箭之间端着弓(预备姿势的循环)：弓随呼吸轻轻起伏
func aim_bow(t: float, p) -> void:
	p.reset()
	_bow_ready(p, TAU * t / BOW_AIM_HOLD, 1.0)
	set_lids(p, blink_k(t, 1.3))


## 吟唱拉弓：满弦 → 再往后拉到耳边(越拉越慢，最后几乎停住)；颤抖从零慢慢长到 hold 的幅度
func draw_bow(t: float, p) -> void:
	p.reset()
	var u: float = Lib.smooth(t / BOW_DRAW_IN)
	var slow: float = 1.0 - pow(1.0 - clampf(t / BOW_DRAW_IN, 0.0, 1.0), 2.2)       # 起步快一点、越拉越沉
	_bow_straining(p, t - BOW_DRAW_IN, lerpf(0.0, 1.0, slow), u)
	set_lids(p, 0.35 * u)


## 拉住不动：持续用力的颤抖(循环)
func draw_bow_hold(t: float, p) -> void:
	p.reset()
	_bow_straining(p, t, 1.0, 1.0)
	set_lids(p, 0.35)


## 吟唱放箭(15f = 0.5s)：拉得深 → 放得猛：拉弦手甩得更远、弓身前倾更多、上身回弹
func release_bow(t: float, p) -> void:
	p.reset()
	_bow_released(p, t, 1.0, t * 30.0)


## 用力颤抖：1 秒周期内整数个周期的正弦叠加(循环无缝)。快的细颤(8~15 次/秒，幅度很小，主要体现在弓身滚转上)
## + 慢的较劲(2~3 次/秒：拉弦手一进一退、弓手一沉一顶)。返回 [弓手位移, 拉弦手位移, 弓身滚转(度), 弓身俯仰(度), 上身晃动(度)]
static func _strain_shake(t: float) -> Array:
	var w: float = TAU * t / BOW_HOLD
	var env: float = 0.75 + 0.25 * sin(w + 0.6)                   # 一口气里用力有起伏
	var fast_a := Vector3(0.16 * sin(9.0 * w) + 0.08 * sin(13.0 * w + 1.1), 0.18 * sin(11.0 * w + 0.4) + 0.07 * sin(7.0 * w + 2.0), 0.0)
	var fast_b := Vector3(0.1 * sin(10.0 * w + 2.2), 0.18 * sin(8.0 * w + 0.9) + 0.08 * sin(14.0 * w), 0.12 * sin(12.0 * w + 1.7))
	var slow_a := Vector3(0.25 * sin(2.0 * w + 0.3), 0.3 * sin(3.0 * w + 1.9), 0.0)
	var slow_b := Vector3(0.0, 0.3 * sin(2.0 * w + 1.0), 0.45 * sin(3.0 * w + 0.5))
	var roll: float = (1.5 * sin(9.0 * w + 0.3) + 0.7 * sin(15.0 * w + 2.4)) * env + 0.8 * sin(2.0 * w + 2.2)
	var pitch: float = 0.6 * sin(11.0 * w + 1.4) * env + 0.5 * sin(3.0 * w)
	var body: float = (0.35 * sin(10.0 * w + 1.0) + 0.2 * sin(6.0 * w)) * env
	return [fast_a * env + slow_a, fast_b * env + slow_b, roll, pitch, body]


## 拉到耳边并拉住：deep = 往后拉的程度，k = 颤抖/用力的强度；tc = 颤抖信号的时刻(draw_bow 末帧对齐 hold 的 0 时刻)
func _bow_straining(p, tc: float, deep: float, k: float) -> void:
	var sh: Array = _strain_shake(tc)
	var creep: float = 0.03 * sin(TAU * tc / BOW_HOLD + 2.0) * k        # 力气一松一紧，弦跟着进退一点
	archer_pose(p, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0,
		{"deep": deep + creep, "strain": 0.25 + 0.75 * k, "shake_bow": (sh[0] as Vector3) * k, "shake_hand": (sh[1] as Vector3) * k,
		"cant": float(sh[2]) * k, "pitch": float(sh[3]) * k})
	# 上身整体跟着抖一点(两只手都挂在胸腔上，整体刚性转动不会破坏拉弦的几何关系)
	p.radd("Chest", float(sh[4]) * k, 0.4 * float(sh[4]) * k, 0.0)
	p.r("Bow_Gear", 0, 0, 0)


## 放箭之后：rt = 放箭后的秒数，deep = 放箭前拉得多深(0 普通满弦 / 1 吟唱拉满)
## 时间线：残心(拉弦手甩开、弓身前倾回弹)→ 0.12~0.38s 弓放低回预备，0.09~0.24s 拉弦手下到左胯旁，0.22s 抽出下一支箭
##   → 预备(= 攻击动画首帧 / aim_bow 首帧)
func _bow_released(p, rt: float, deep: float, tt: float) -> void:
	var k: float = 1.0 + 0.6 * deep                                  # 拉得越深，放得越猛
	var draw: float = maxf(0.0, 1.0 - rt / 0.035)                    # 弦一帧弹回
	var hand: float = 1.0                                            # 拉弦手从甩开的位置直接下去取箭(pluck)，不回弦上
	var hand_back: float = (6.0 + 5.0 * deep) * (1.0 - exp(-rt * 30.0)) * (1.0 - 0.5 * Lib.smooth((rt - 0.15) / 0.3))
	var down: float = Lib.smooth((rt - 0.12) / 0.26)                 # 残心之后弓放低回预备
	var recoil: float = k * exp(-rt * 7.0) * cos(rt * 26.0) * (1.0 - down)
	var flick: float = (1.0 - exp(-rt * 24.0)) * exp(-rt * 5.0)       # 弓身在手里往前倾(弓顶前倒)再回正
	var splay: float = Lib.smooth(rt / 0.05) * (1.0 - Lib.smooth((rt - 0.22) / 0.2))
	var strain: float = deep * exp(-rt * 10.0) * (1.0 - down)
	var pluck: float = Lib.smooth((rt - 0.09) / 0.15)
	var vis: float = Lib.smooth((rt - 0.2) / 0.05)                   # 手到胯旁时抽出箭
	archer_pose(p, 1.0, draw, hand, hand_back, tt, 0.0, recoil, vis, 1.0 - down,
		{"deep": deep, "strain": strain, "pitch": 11.0 * k * flick * (1.0 - down), "splay": splay, "back_up": 0.35,
		"stance": lerpf(1.0, BOW_READY_ST, down), "feet": 1.0, "low": down, "pluck": pluck, "arrow_hand": 1.0, "via": BOW_DROP_VIA})
	# 弓臂/弦：释放瞬间反弹并衰减振动
	var v: float = exp(-rt * 9.0) * sin(rt * 34.0) * k
	p.radd("Bow_U1", 3.0 * v, 0, 0)
	p.radd("Bow_U2", 7.0 * v, 0, 0)
	p.radd("Bow_D1", -3.0 * v, 0, 0)
	p.radd("Bow_D2", -7.0 * v, 0, 0)
	p.madd("Bow_Nock", Vector3(0, 0, 3.0 * k * exp(-rt * 10.0) * sin(rt * 55.0)))
	set_lids(p, 0.0)


# =============================================================== 攻击：剑 (20f = 0.67s，出手 0.26s)
## 斜劈：蓄力(剑举到右肩后上方、身体后拧、重心后坐、空手前指瞄准) → 顶点一顿 → 左脚上步、转腰送肩、
## 剑从右上斜劈到左前下(出手，刃口始终领着挥动方向) → 定住两帧 → 顺势带到左胯(随挥) → 收回待机。空手在劈下时猛收到腰侧(反向发力)
## 持盾版：盾一直护在身前，蓄力时往前顶、劈下时再压出去
const SWORD_IDLE_GRIP := Vector3(-14.5, 47.0, 9.0)
const SWORD_IDLE_ROT := Vector3(34.0, 0.0, 10.0)
const SWORD_PLANE_N := Vector3(0.68, -0.46, -0.55)       # 斜劈的挥动平面法线(胸腔局部)：右上后 → 左前下


func attack_sword(t: float, p) -> void:
	_sword_attack(t, p, false)


func attack_guard(t: float, p) -> void:
	_sword_attack(t, p, true)


func _sword_attack(t: float, p, guard: bool) -> void:
	p.reset()
	# ---- 身体：蓄力后拧 → 上步转腰劈下 → 顿住 → 随挥 → 收
	var yaw: float = kf_f([[0.0, 0.0], [0.12, -30.0, "o"], [0.16, -34.0], [0.21, -8.0, "i"], [0.26, 30.0, "i"], [0.30, 33.0, "o"], [0.40, 38.0, "o"], [0.52, 12.0], [0.667, 0.0]], t)
	var lean: float = kf_f([[0.0, 0.0], [0.12, -7.0, "o"], [0.16, -8.0], [0.21, 2.0, "i"], [0.26, 14.0, "i"], [0.30, 15.0], [0.40, 12.0], [0.52, 4.0], [0.667, 0.0]], t)
	var push: float = kf_f([[0.0, 0.0], [0.12, -2.5, "o"], [0.16, -2.8], [0.21, 0.5, "i"], [0.26, 4.5, "i"], [0.30, 5.0], [0.40, 4.5], [0.54, 1.0], [0.667, 0.0]], t)
	var drop: float = kf_f([[0.0, 0.0], [0.12, 1.5, "o"], [0.16, 1.8], [0.21, 0.8], [0.26, 3.8, "i"], [0.31, 4.2, "o"], [0.40, 3.5], [0.54, 0.8], [0.667, 0.0]], t)
	_twist(p, yaw, lean, push, drop, 0.85)
	p.radd("Head", kf_f([[0.0, 0.0], [0.24, 0.0], [0.28, 6.0, "o"], [0.45, 2.0], [0.667, 0.0]], t), 0, 0)     # 劈下时点一下头(发力)
	# ---- 脚：左脚在劈下时往前踏一步(抬脚成弧线)，收势时退回；右脚后蹬
	var lz: float = kf_f([[0.0, 0.0], [0.12, -1.0], [0.16, -1.0], [0.25, 5.5, "o"], [0.44, 5.5], [0.60, 0.0]], t)
	var rz: float = kf_f([[0.0, 0.0], [0.16, 0.0], [0.26, -1.5, "o"], [0.46, -1.5], [0.62, 0.0]], t)
	_feet(p, 6.5, lz, _arc(t, 0.16, 0.25, 2.8) + _arc(t, 0.46, 0.60, 1.4), rz, 0.0, 6.0 + 10.0 * Lib.smooth(lz / 5.5), -6.0 - 8.0 * Lib.smooth(-rz / 1.5))
	# ---- 剑：握点(胸腔局部，都在右肩的够得着范围内)与剑身方向
	var gv: Vector3 = kf_v([[0.0, SWORD_IDLE_GRIP], [0.06, Vector3(-19.5, 58.0, 4.0)], [0.12, Vector3(-11.5, 73.0, -3.0), "o"], [0.16, Vector3(-11.0, 74.0, -4.0)],
		[0.19, Vector3(-12.0, 79.0, 5.0), "i"], [0.21, Vector3(-8.0, 66.0, 12.0)], [0.26, Vector3(-4.0, 52.0, 15.5), "i"], [0.30, Vector3(-3.0, 51.0, 15.0), "o"],
		[0.40, Vector3(0.0, 50.0, 10.5), "o"], [0.52, Vector3(-9.0, 48.5, 11.0)], [0.667, SWORD_IDLE_GRIP]], t)
	var av: Vector3 = kf_v([[0.0, Vector3(-0.14, 0.82, 0.56)], [0.06, Vector3(-0.55, 0.8, 0.2)], [0.12, Vector3(-0.2, 0.6, -0.78), "o"], [0.16, Vector3(-0.15, 0.5, -0.85)],
		[0.19, Vector3(-0.05, 0.95, 0.3), "i"], [0.21, Vector3(0.1, 0.62, 0.78)], [0.26, Vector3(0.5, -0.25, 0.83), "i"], [0.30, Vector3(0.58, -0.32, 0.75), "o"],
		[0.40, Vector3(0.85, -0.42, 0.3), "o"], [0.52, Vector3(0.3, 0.35, 0.88)], [0.667, Vector3(-0.14, 0.82, 0.56)]], t)
	var engage: float = kf_f([[0.0, 0.0], [0.10, 1.0], [0.52, 1.0], [0.667, 0.0]], t)
	var a_w: Vector3 = _chest_dir(p, av)
	var q_swing: Quaternion = wrot(a_w, _chest_dir(p, SWORD_PLANE_N).cross(a_w))
	var q_idle: Quaternion = Lib.E(SWORD_IDLE_ROT.x, SWORD_IDLE_ROT.y, SWORD_IDLE_ROT.z)
	hold_bow(p, follow(p, "Chest", gv), q_idle.slerp(q_swing, engage), Vector3(-1.0, -0.2, -0.5))
	fist_r(p, 82.0)
	if guard:
		# 盾：蓄力时往前顶着护住身体，劈下时压出去，之后回到护身位
		var sh: float = kf_f([[0.0, 0.0], [0.12, 0.6, "o"], [0.21, 0.4], [0.27, 1.0, "i"], [0.40, 0.7], [0.667, 0.0]], t)
		var tgt: Vector3 = follow(p, "Chest", Vector3(7.5, 53.0, 10.5).lerp(Vector3(6.0, 55.0, 15.0), sh))
		p.ik2("UpperArm_L", "LowerArm_L", "Hand_L", tgt, Vector3(0.7, -0.5, -0.6))
		p.set_grot("Hand_L", Lib.E(0.0, -12.0 + 8.0 * sh, 0.0))
		p.r("Fingers_L", -70.0, 0, 0)
		p.r("Thumb_L", -40.0, 0, 0)
	else:
		# 空手：蓄力时前伸指向目标(掌心朝前)，劈下时猛收到腰侧握拳
		var reach: float = kf_f([[0.0, 0.0], [0.12, 1.0, "o"], [0.17, 1.0], [0.26, 0.0, "i"], [0.667, 0.0]], t)
		var pull: float = kf_f([[0.0, 0.0], [0.17, 0.0], [0.27, 1.0, "i"], [0.42, 0.8], [0.62, 0.0]], t)
		var rest: Vector3 = Vector3(15.2, 49.0, 1.6)
		var lt: Vector3 = rest.lerp(Vector3(12.5, 60.0, 15.5), reach).lerp(Vector3(13.0, 49.0, -3.5), pull)
		p.ik2("UpperArm_L", "LowerArm_L", "Hand_L", follow(p, "Chest", lt), Vector3(0.7, -0.6, -0.4))
		p.set_grot("Hand_L", Lib.E(-6.0, -8.0, 10.0).slerp(Lib.E(-80.0, 20.0, 0.0), reach))
		p.r("Fingers_L", lerpf(lerpf(-14.0, -6.0, reach), -75.0, pull), 0, -12.0)
		p.r("Thumb_L", lerpf(-10.0, -45.0, pull), 0, 0)
	set_lids(p, 0.0)


# =============================================================== 攻击：大盾 + 单手剑 (20f = 0.67s，出手 0.26s)
## 大盾挡在身前，剑没法斜劈(会砍穿盾面)：剑收到右腰后侧蓄力 → 盾往前一顶、剑从盾的右缘刺出去(出手) → 收回
func attack_tower(t: float, p) -> void:
	p.reset()
	_twist(p, kf_f([[0.0, 0.0], [0.14, -16.0, "o"], [0.20, -18.0], [0.26, 14.0, "i"], [0.36, 16.0], [0.667, 0.0]], t),
		kf_f([[0.0, 0.0], [0.14, -3.0], [0.26, 9.0, "i"], [0.40, 8.0], [0.667, 0.0]], t),
		kf_f([[0.0, 0.0], [0.14, -1.5], [0.26, 3.5, "i"], [0.40, 3.0], [0.667, 0.0]], t),
		kf_f([[0.0, 0.0], [0.14, 1.5], [0.26, 2.5, "i"], [0.667, 0.0]], t), 0.8)
	var lz: float = kf_f([[0.0, 0.0], [0.18, 0.0], [0.25, 3.5, "o"], [0.44, 3.5], [0.60, 0.0]], t)
	_feet(p, 6.5, lz, _arc(t, 0.18, 0.25, 2.0) + _arc(t, 0.46, 0.60, 1.0), -0.5, 0.0, 6.0 + 6.0 * Lib.smooth(lz / 3.5), -6.0)
	var grip: Vector3 = kf_v([[0.0, SWORD_IDLE_GRIP], [0.14, Vector3(-15.5, 51.0, -1.5), "o"], [0.20, Vector3(-15.5, 51.5, -2.5)],
		[0.26, Vector3(-13.0, 56.0, 19.5), "i"], [0.36, Vector3(-13.0, 56.0, 19.0), "o"], [0.667, SWORD_IDLE_GRIP]], t)
	var cq: Quaternion = _chest_q(p)
	var q_idle: Quaternion = Lib.E(SWORD_IDLE_ROT.x, SWORD_IDLE_ROT.y, SWORD_IDLE_ROT.z)
	var q_back: Quaternion = cq * wrot(Vector3(-0.15, 0.25, 1.0), Vector3(-1.0, 0.0, 0.0))
	var q_thrust: Quaternion = cq * wrot(Vector3(0.08, 0.05, 1.0), Vector3(-1.0, 0.0, 0.0))
	var q: Quaternion = kf_q([[0.0, q_idle], [0.14, q_back, "o"], [0.20, q_back], [0.26, q_thrust, "i"], [0.36, q_thrust], [0.667, q_idle]], t)
	hold_bow(p, follow(p, "Chest", grip), q, Vector3(-1.0, -0.3, -0.4))
	fist_r(p, 82.0)
	_left_tower(p, 0.0, false, kf_f([[0.0, 0.0], [0.14, 0.3], [0.26, 1.0, "i"], [0.40, 0.8], [0.667, 0.0]], t))
	set_lids(p, 0.0)


# =============================================================== 攻击：大盾 + 手枪 (13f = 0.433s，出手 0.12s，追击副本 0.22s)
## 只拿右手一把枪(左手是盾)：从盾的右缘把枪伸出去连开两枪(第二枪 = [追击1] 的副本)，盾纹丝不动
func attack_pistols_tower(t: float, p) -> void:
	p.reset()
	var dur := 13.0 * F
	var raise: float = kf_f([[0.0, 0.0], [0.09, 1.0, "o"], [0.30, 1.0], [dur, 0.0]], t)
	var k1: float = kf_f([[0.0, 0.0], [0.12, 0.0], [0.145, 1.0, "o"], [0.21, 0.1]], t)
	var k2: float = kf_f([[0.0, 0.0], [0.22, 0.0], [0.245, 1.0, "o"], [0.34, 0.0]], t)
	var kick: float = k1 + k2
	_twist(p, 8.0 * raise - 4.0 * kick, 3.0 * raise - 2.0 * kick, -0.8 * kick, 1.5 * raise, 0.9)
	_feet(p, 7.0, 1.0 * raise, 0.0, -0.5 * raise, 0.0, 6.0 + 4.0 * raise, -6.0 - 6.0 * raise)
	var g: Vector3 = PIST_GRIP.lerp(Vector3(-12.5, 59.0, 17.0), raise) + Vector3(0.0, 2.0, -3.0) * kick
	var aim: Vector3 = PIST_AIM.lerp(Vector3(0.05, 0.0, 1.0), raise) + Vector3(0.0, 0.4, 0.0) * kick
	var up: Vector3 = Vector3(0.0, 1.0, 0.45).lerp(Vector3(0.3, 1.0, 0.0), raise)
	hold_bow(p, follow(p, "Chest", g), _chest_q(p) * grot(aim, up), Vector3(-1.0, -0.6, -0.2))
	fist_r(p, 82.0)
	_left_tower(p, 0.0, false, 0.25 * raise)
	set_lids(p, 0.0)


# =============================================================== 缩头(鼠鼠缩头！，循环 36f = 1.2s)
## 大盾往地上一杵、整个人蹲到盾后面：膝盖顶着盾背、上身前倾缩成一团，只剩一对鼠耳和眼睛从盾沿上冒出来；
## 一直在小幅发抖，闭着眼，中间偷偷睁眼往外瞄一下。右手的武器抱在胸前
func turtle(t: float, p) -> void:
	p.reset()
	var T := 36.0 * F
	var w: float = TAU * t / T
	var shiver: float = 0.35 * sin(w * 9.0) + 0.2 * sin(w * 14.0 + 1.3)          # 发抖(整数圈，循环无缝)
	var breath: float = sin(w)
	p.move("Hips", Vector3(0.25 * shiver, -16.0 + 0.4 * breath, -4.0))
	p.r("Hips", 12.0, 0.0, 0.0)
	p.r("Spine", 5.0 + 0.8 * breath, 0.0, 0.6 * shiver)
	p.r("Chest", 3.0, 0.0, 0.0)
	var peek: float = Lib.smooth((t - 0.55) / 0.12) * (1.0 - Lib.smooth((t - 0.86) / 0.12))
	# 头缩着、下巴抵在盾沿后面；偷看时抬起一点、左右瞄
	p.r("Head", 7.0 - 9.0 * peek + 1.0 * shiver, 8.0 * peek * sin(w * 2.0), 0.0)
	legs(p, Vector3(7.0, ANKLE_Y, 1.5), Vector3(-7.0, ANKLE_Y, -0.5), Lib.E(0, 14.0, 0), Lib.E(0, -14.0, 0))
	# 盾：杵在身前地上(盾底贴地)，盾面朝前；左手握在上面那条握带
	var cq: Quaternion = Quaternion.IDENTITY
	var hand := Vector3(3.5 + 0.2 * shiver, 44.5, 13.5)
	p.ik2("UpperArm_L", "LowerArm_L", "Hand_L", hand, Vector3(0.9, -0.3, -0.5))
	p.set_grot("Hand_L", cq)
	p.r("Fingers_L", -80.0, 0, 0)
	p.r("Thumb_L", -45.0, 0, 0)
	# 右手把武器抱在胸前(剑竖着、枪口朝上都说得过去)
	hold_bow(p, follow(p, "Chest", Vector3(-6.0, 53.0 + 0.3 * shiver, 8.0)), _chest_q(p) * Lib.E(-12.0, 0.0, 18.0), Vector3(-1.0, -0.5, -0.4))
	fist_r(p, 85.0)
	set_lids(p, 1.0 - peek)


# =============================================================== 攻击：长枪 (24f = 0.8s，出手 0.30s)
## 单体 = 抡枪下劈：踮脚挺身把枪尖挑到头顶后上方(蓄力) → 顶点一停 → 沉身踏步、枪尖划一个大弧劈到正前下方(出手)
## → 枪尖在落点弹一下 → 收回侧身枪架。和贯穿的突刺同样时长
func attack_polearm(t: float, p) -> void:
	p.reset()
	var grip: Vector3 = kf_v([[0.00, POLE_GRIP], [0.13, Vector3(-6.0, 60.0, 5.0), "o"], [0.19, Vector3(-6.0, 61.5, 4.0)],
		[0.25, Vector3(-4.5, 57.0, 10.0), "i"], [0.30, Vector3(-3.5, 51.0, 11.5), "i"], [0.36, Vector3(-3.5, 50.0, 11.0), "o"],
		[0.50, Vector3(-4.0, 51.0, 10.0)], [0.80, POLE_GRIP]], t)
	var axis: Vector3 = kf_v([[0.00, POLE_AXIS], [0.13, Vector3(0.35, 0.9, -0.25), "o"], [0.19, Vector3(0.3, 0.9, -0.32)],
		[0.25, Vector3(0.62, 0.6, 0.5), "i"], [0.30, Vector3(0.72, -0.2, 0.66), "i"], [0.33, Vector3(0.72, -0.1, 0.68), "o"],
		[0.38, Vector3(0.72, -0.18, 0.67)], [0.50, Vector3(0.75, 0.05, 0.62)], [0.80, POLE_AXIS]], t)
	var span: float = kf_f([[0.0, POLE_SPAN], [0.13, 9.0], [0.30, 11.0, "i"], [0.5, 10.5], [0.8, POLE_SPAN]], t)
	_twist(p, kf_f([[0.0, POLE_YAW], [0.13, -52.0, "o"], [0.19, -54.0], [0.30, -32.0, "i"], [0.40, -32.0], [0.8, POLE_YAW]], t),
		kf_f([[0.0, 0.0], [0.13, -8.0, "o"], [0.19, -9.0], [0.30, 15.0, "i"], [0.40, 13.0], [0.60, 4.0], [0.8, 0.0]], t),
		kf_f([[0.0, 0.0], [0.13, -2.0], [0.19, -2.2], [0.30, 3.5, "i"], [0.45, 3.0], [0.8, 0.0]], t),
		kf_f([[0.0, 0.0], [0.13, -1.8, "o"], [0.19, -2.0], [0.30, 4.5, "i"], [0.36, 5.0, "o"], [0.50, 3.0], [0.8, 0.0]], t), 0.85)
	# 左脚(前脚)随劈落往前踏，重重落地；右脚跟着蹬一下
	var lead: float = kf_f([[0.0, POLE_LEAD], [0.19, POLE_LEAD], [0.29, 7.5, "o"], [0.50, 7.5], [0.70, POLE_LEAD]], t)
	_stance_step(p, 6.5, POLE_LEAD, lead, _arc(t, 0.19, 0.29, 2.6) + _arc(t, 0.52, 0.68, 1.2))
	_hold_pole(p, grip, axis, span)
	set_lids(p, 0.0)


# =============================================================== 攻击：长枪·贯穿 (24f = 0.8s，出手 0.30s)
## [群攻2] 的群攻招式(目标身后同一直线上还有敌人时)：后手把枪收到腰间、身体侧得更厉害、重心后坐(蓄力)
## → 一停 → 前脚大步踏出、后手推枪、两手沿枪杆并拢，整个人扑出去突刺(出手) → 刺到底停住 → 抽枪退步
func attack_polearm_pierce(t: float, p) -> void:
	p.reset()
	var grip: Vector3 = kf_v([[0.00, POLE_GRIP], [0.15, Vector3(-7.0, 50.0, 1.5), "o"], [0.20, Vector3(-7.0, 49.5, 0.5)],
		[0.30, Vector3(-3.0, 54.5, 13.0), "i"], [0.40, Vector3(-3.0, 54.5, 13.5), "o"], [0.56, Vector3(-4.0, 52.5, 9.5)], [0.80, POLE_GRIP]], t)
	var axis: Vector3 = kf_v([[0.00, POLE_AXIS], [0.15, Vector3(0.88, 0.22, 0.42), "o"], [0.20, Vector3(0.88, 0.2, 0.43)],
		[0.30, Vector3(0.68, 0.36, 0.64), "i"], [0.40, Vector3(0.68, 0.36, 0.64)], [0.56, Vector3(0.76, 0.3, 0.56)], [0.80, POLE_AXIS]], t)     # 前倾 16° 会把胸腔局部的轴往下带，这里抬高补回来
	var span: float = kf_f([[0.0, POLE_SPAN], [0.15, 12.5, "o"], [0.20, 12.5], [0.30, 6.5, "i"], [0.40, 6.5], [0.60, 9.0], [0.8, POLE_SPAN]], t)
	_twist(p, kf_f([[0.0, POLE_YAW], [0.15, -62.0, "o"], [0.20, -64.0], [0.30, -30.0, "i"], [0.40, -30.0], [0.8, POLE_YAW]], t),
		kf_f([[0.0, 0.0], [0.15, -5.0, "o"], [0.20, -6.0], [0.30, 16.0, "i"], [0.40, 16.0], [0.60, 5.0], [0.8, 0.0]], t),
		kf_f([[0.0, 0.0], [0.15, -3.5, "o"], [0.20, -3.8], [0.30, 7.0, "i"], [0.40, 7.5], [0.60, 2.5], [0.8, 0.0]], t),
		kf_f([[0.0, 0.0], [0.15, 2.5, "o"], [0.20, 2.8], [0.30, 4.0, "i"], [0.40, 4.0], [0.8, 0.0]], t), 0.85)
	var lead: float = kf_f([[0.0, POLE_LEAD], [0.15, 1.5], [0.20, 1.5], [0.29, 10.0, "o"], [0.46, 10.0], [0.68, POLE_LEAD]], t)
	_stance_step(p, 6.5, POLE_LEAD, lead, _arc(t, 0.20, 0.29, 3.0) + _arc(t, 0.48, 0.66, 1.5))
	_hold_pole(p, grip, axis, span)
	set_lids(p, 0.0)


# =============================================================== 持盾单手长枪 / 单手法器(正行节点这类副手是盾的棋子)
## 副手是盾时长枪、法器都不双手握：右手单手持，左臂一直挂着盾(待机/跑步 = _left_guard，攻击里用 _shield_arm 推盾、收盾)。
## 单手长枪握在枪的重心附近(模型原点)：枪尾露出 ~0.5 米，所以枪身始终大致朝胸腔正前方、夹在右肋下，
## 枪尾从右臂下伸到右后方——横扫、突刺的方向主要靠转身(扭腰 + 上步)带，不靠手腕甩(甩的话枪尾会扫过后背)。

## 单手持枪：grip 胸腔局部握点，axis 胸腔局部枪尖方向；或 world_axis 直接给世界方向(攻击里用，转身时枪尖仍对准目标)
func _hold_spear1(p, grip: Vector3, axis: Vector3, pole: Vector3 = Vector3(-1.0, -0.3, -0.45), world: bool = false) -> void:
	var a: Vector3 = axis.normalized() if world else _chest_dir(p, axis)
	hold_bow(p, follow(p, "Chest", grip), _pole_rot(a), pole)
	fist_r(p, 84.0)


## 攻击里的盾臂：at = 左手(胸腔局部)；yaw = 盾面朝向(度，相对世界正前方，与 _left_guard 的 -12° 同口径)；
## chest_k = 盾面跟着胸腔转的程度(0 = 一直对着正前方的目标；收盾贴身时跟着身体转)
func _shield_arm(p, at: Vector3, yaw: float = -12.0, chest_k: float = 0.0, pole: Vector3 = Vector3(0.7, -0.5, -0.6)) -> void:
	p.ik2("UpperArm_L", "LowerArm_L", "Hand_L", follow(p, "Chest", at), pole)
	var q: Quaternion = Lib.E(0.0, yaw, 0.0)
	if chest_k > 0.0:
		q = q.slerp(_chest_q(p) * Lib.E(0.0, yaw, 0.0), chest_k)
	p.set_grot("Hand_L", q)
	p.r("Fingers_L", -70.0, 0, 0)
	p.r("Thumb_L", -40.0, 0, 0)


# =============================================================== 攻击：持盾单手长枪 (24f = 0.8s，出手 0.30s)
## 盾在前、枪在右的突刺：把枪往后收到右腰、枪身放平夹在肋下，右肩往后拧、重心后坐，盾往前顶着护住身体(蓄力)
## → 一停 → 左脚上步、右肩送出去，右臂把枪平平刺出(0.30s 刺到底，枪尖略往下压对着目标) → 停一下 → 收回待机架势
func attack_polearm_guard(t: float, p) -> void:
	_spear1_thrust(t, p, false)


## [群攻2] 的贯穿版：蓄力收得更深、身体侧得更厉害，出手时大步弓步扑出去、上身压低，手臂完全伸直把枪送到最远(刺穿一串)
func attack_polearm_guard_pierce(t: float, p) -> void:
	_spear1_thrust(t, p, true)


func _spear1_thrust(t: float, p, deep: bool) -> void:
	p.reset()
	var k: float = 1.0 if deep else 0.0
	var yaw: float = kf_f([[0.0, SPEAR1_YAW], [0.15, -30.0 - 12.0 * k, "o"], [0.20, -32.0 - 13.0 * k], [0.30, 22.0 + 4.0 * k, "i"], [0.40, 24.0 + 4.0 * k, "o"],
		[0.56, 10.0], [0.80, SPEAR1_YAW]], t)
	var lean: float = kf_f([[0.0, 0.0], [0.15, -5.0, "o"], [0.20, -6.0], [0.30, 11.0 + 7.0 * k, "i"], [0.40, 12.0 + 7.0 * k], [0.58, 4.0], [0.80, 0.0]], t)
	var push: float = kf_f([[0.0, 0.0], [0.15, -2.5 - 1.0 * k, "o"], [0.20, -2.8 - 1.0 * k], [0.30, 4.5 + 3.0 * k, "i"], [0.42, 4.8 + 3.0 * k], [0.60, 1.5], [0.80, 0.0]], t)
	var drop: float = kf_f([[0.0, 0.0], [0.15, 1.5 + 1.5 * k, "o"], [0.20, 1.8 + 1.5 * k], [0.30, 3.5 + 2.5 * k, "i"], [0.42, 3.8 + 2.5 * k], [0.62, 1.0], [0.80, 0.0]], t)
	_twist(p, yaw, lean, push, drop, 0.85)
	# 左脚(前脚)随突刺往前踏，右脚蹬一下；收势时退回
	var lead: float = kf_f([[0.0, SPEAR1_LEAD], [0.20, SPEAR1_LEAD], [0.29, 7.0 + 4.0 * k, "o"], [0.48, 7.0 + 4.0 * k], [0.68, SPEAR1_LEAD]], t)
	_stance_step(p, 6.5, SPEAR1_LEAD, lead, _arc(t, 0.20, 0.29, 2.6 + 0.6 * k) + _arc(t, 0.50, 0.66, 1.2))
	# 右手握点(胸腔局部)：收到右腰后侧 → 刺到身前 → 回
	var g_back: Vector3 = Vector3(-15.5, 52.5, -1.0) + Vector3(0.0, 0.0, -1.5) * k
	var g_hit: Vector3 = Vector3(-9.5, 57.0, 15.0) + Vector3(1.0, 1.0, 1.5) * k
	var grip: Vector3 = kf_v([[0.0, SPEAR1_GRIP], [0.15, g_back, "o"], [0.20, g_back + Vector3(0.0, 0.3, -0.5)], [0.30, g_hit, "i"],
		[0.40, g_hit + Vector3(0.0, -0.3, -0.5), "o"], [0.56, Vector3(-12.5, 52.0, 11.0)], [0.80, SPEAR1_GRIP]], t)
	# 枪尖方向：待机(胸腔局部) → 攻击段用世界方向(放平、对准正前方，刺到底时略往下压) → 回待机
	var a_idle: Vector3 = _chest_dir(p, SPEAR1_AXIS)
	var a_att: Vector3 = kf_v([[0.0, Vector3(0.0, 0.45, 1.0)], [0.15, Vector3(-0.06, 0.16, 1.0), "o"], [0.20, Vector3(-0.06, 0.18, 1.0)],
		[0.30, Vector3(0.0, -0.07, 1.0), "i"], [0.40, Vector3(0.0, -0.04, 1.0)], [0.56, Vector3(0.0, 0.3, 1.0)], [0.80, Vector3(0.0, 0.45, 1.0)]], t).normalized()
	var engage: float = kf_f([[0.0, 0.0], [0.12, 1.0], [0.54, 1.0], [0.78, 0.0]], t)
	var a: Vector3 = a_idle.lerp(a_att, engage).normalized()
	var pole: Vector3 = kf_v([[0.0, Vector3(-1.0, -0.3, -0.45)], [0.15, Vector3(-0.8, -0.2, -0.7)], [0.30, Vector3(-0.8, -0.6, -0.1), "i"], [0.56, Vector3(-1.0, -0.4, -0.4)],
		[0.80, Vector3(-1.0, -0.3, -0.45)]], t)
	_hold_spear1(p, grip, a, pole, true)
	# 盾：蓄力时往前顶、出手时压在身前(右肩送出去时左肩往后，盾跟着收一点)，然后回到护身位
	var sh: float = kf_f([[0.0, 0.0], [0.15, 1.0, "o"], [0.22, 0.9], [0.30, 0.5, "i"], [0.44, 0.4], [0.80, 0.0]], t)
	_shield_arm(p, SHIELD_GUARD.lerp(Vector3(6.0, 55.0, 14.0), sh), -12.0 + 6.0 * sh)
	set_lids(p, 0.0)


# =============================================================== 攻击：持盾单手法器 (27f = 0.9s，出手 0.36s)
## 盾护在身前压低身子(架盾)，右手把法器收到右肩旁聚能 → 一停 → 左脚上步，右手从盾的右缘把法器推出去(0.36s 放出光球)
## → 被反冲往回顶一下(法器上跳、肩膀后缩) → 收回
func attack_focus_guard(t: float, p) -> void:
	p.reset()
	var gather: float = kf_f([[0.0, 0.0], [0.20, 1.0, "o"], [0.28, 1.0], [0.36, 0.0, "i"]], t)
	var push: float = kf_f([[0.0, 0.0], [0.28, 0.0], [0.36, 1.0, "i"], [0.52, 0.9, "o"], [0.90, 0.0]], t)
	var kick: float = _arc(t, 0.36, 0.54, 1.0)
	_twist(p, -14.0 * gather + 14.0 * push - 3.0 * kick, 4.0 * gather + 10.0 * push - 4.0 * kick, -0.5 * gather + 3.0 * push - 1.5 * kick,
		2.5 * gather + 2.0 * push, 0.85)
	p.radd("Head", 4.0 * gather - 3.0 * push - 3.0 * kick, 0.0, 0.0)
	_feet(p, 6.5, 1.0 + 3.0 * push, _arc(t, 0.28, 0.36, 1.6), -0.5 - 0.5 * push, 0.0, 6.0 + 6.0 * push, -6.0)
	var gc := Vector3(-14.0, 59.0, 4.0)               # 收在右肩前下方
	var gp := Vector3(-7.5, 60.5, 20.0)               # 从盾的右缘推出去(手臂伸直)
	var gv: Vector3 = FOCUS1_GRIP.lerp(gc, gather).lerp(gp, push) + Vector3(0.0, 1.2, -2.5) * kick
	var aim: Vector3 = FOCUS1_AIM.lerp(Vector3(0.1, 0.35, 1.0), gather).lerp(Vector3(0.04, 0.06, 1.0), push) + Vector3(0.0, 0.35, 0.0) * kick
	var up: Vector3 = Vector3(0.0, 1.0, 0.15).lerp(Vector3(0.2, 1.0, -0.2), gather).lerp(Vector3(0.0, 1.0, 0.1), push)
	var cq: Quaternion = _chest_q(p)
	hold_bow(p, follow(p, "Chest", gv), cq * grot(aim, up), Vector3(-1.0, -0.5, -0.4).lerp(Vector3(-0.8, -0.6, 0.0), push))
	fist_r(p, 70.0)
	# 盾：聚能时往前顶着护住身子，推出时稳在身前，反冲时跟着晃一下
	var sh: float = kf_f([[0.0, 0.0], [0.20, 1.0, "o"], [0.36, 0.8], [0.60, 0.6], [0.90, 0.0]], t)
	_shield_arm(p, SHIELD_GUARD.lerp(Vector3(5.5, 55.0, 14.5), sh) + Vector3(0.0, 0.6, -1.0) * kick, -12.0 + 8.0 * sh)
	set_lids(p, 0.0)


# =============================================================== 攻击：大剑 (36f = 1.2s，出手 0.52s)
## 转身大斜斩。重剑的力量来自整个身体的旋转，发力距离要长(刀光扫过约 250°)：
##   蓄力 0.06~0.34：左手松开往前指着目标，右手把剑抡起扛到右肩后上方(剑尖朝后上)；右脚往后撤一步、上身往右后拧近 90°、重心压在后脚
##   悬停 0.34~0.44：再拧一点、剑尖再往后沉一点(张力)
##   发力 0.44~0.52：身体整个拧回来(约 90°)、左脚踏实、沉胯前冲，右臂抡直，剑从身后经右上方劈到正前下方(出手)；左手在劈下时抓回剑柄一起压
##   随挥 0.52~0.66：剑被惯性带着继续往左下扫，上身压得更低
##   收势 0.66~1.20：吃力地把剑提回来，两手合握回到右脚在前的低架
## Q 版短手 + 胸前体积，两手合握时剑的朝向完全由左手能放在哪里决定(two_hand 会绕右手转剑)，大弧线做不出来；
## 所以抡剑这一段是右手单手(朝向完全可控、手臂能伸直)，两手合握的待机姿势与它之间按骨骼逐节 slerp 过渡
const HEAVY_SWING_N := Vector3(0.88, 0.47, 0.0)         # 挥砍平面法线(世界)：刃口朝向 = 法线 × 剑身
const ARM_BONES := ["Shoulder_L", "UpperArm_L", "LowerArm_L", "Hand_L", "Fingers_L", "Thumb_L",
	"Shoulder_R", "UpperArm_R", "LowerArm_R", "Hand_R", "Fingers_R", "Thumb_R"]


func attack_heavy(t: float, p) -> void:
	p.reset()
	var yaw: float = kf_f([[0.0, HEAVY_YAW], [0.06, HEAVY_YAW - 4.0], [0.34, -48.0, "o"], [0.44, -55.0], [0.52, 34.0, "i"],
		[0.60, 48.0, "o"], [0.74, 46.0], [1.0, 40.0], [1.2, HEAVY_YAW]], t)
	var lean: float = kf_f([[0.0, 0.0], [0.06, 2.0], [0.34, -8.0, "o"], [0.44, -9.0], [0.52, 16.0, "i"], [0.62, 24.0, "o"], [0.76, 21.0],
		[1.0, 8.0], [1.2, 0.0]], t)
	var push: float = kf_f([[0.0, 0.0], [0.34, -3.5, "o"], [0.44, -3.8], [0.52, 5.5, "i"], [0.62, 6.5, "o"], [0.80, 5.5], [1.2, 0.0]], t)
	var drop: float = kf_f([[0.0, 0.0], [0.06, 1.5], [0.34, 1.0], [0.44, -0.5], [0.52, 6.5, "i"], [0.62, 8.0, "o"], [0.80, 7.0], [1.05, 2.0], [1.2, 0.0]], t)
	_twist(p, yaw, lean, push, drop, 0.75)
	# 脚：右脚后撤(蓄力) → 左脚往前踏(发力) → 收势时右脚上步、左脚退回
	var rz: float = kf_f([[0.0, 2.5], [0.08, 2.5], [0.30, -5.0, "o"], [0.84, -5.0], [1.04, 2.5, "s"]], t)
	var lz: float = kf_f([[0.0, -3.5], [0.40, -3.5], [0.50, 3.5, "o"], [0.96, 3.5], [1.14, -3.5, "s"]], t)
	var rl: float = _arc(t, 0.08, 0.30, 2.2) + _arc(t, 0.84, 1.04, 2.2)
	var ll: float = _arc(t, 0.40, 0.50, 2.6) + _arc(t, 0.96, 1.14, 1.4)
	_feet(p, 7.0, lz + 0.5, ll, rz + 0.5, rl, 6.0 + 18.0 * Lib.smooth((lz + 3.5) / 7.0), -6.0 - 30.0 * Lib.smooth((2.5 - rz) / 7.5))
	var two: float = kf_f([[0.0, 1.0], [0.08, 0.0, "s"], [0.92, 0.0], [1.12, 1.0, "s"]], t)       # 两手合握的程度
	var base: Array[Quaternion] = p.rot.duplicate()
	var rot_one: Array[Quaternion] = base
	if two < 1.0:
		_heavy_one_hand(p, t)
		rot_one = p.rot.duplicate()
	if two > 0.0:
		p.rot = base.duplicate()
		var b: Vector3 = Vector3(0.0, 1.0, 0.0) * _arc(t, 0.60, 0.74, 1.0)
		_hold_heavy(p, HEAVY_GRIP + b, HEAVY_AXIS)
		if two < 1.0:
			for nm: String in ARM_BONES:
				var i: int = rig.ids[nm]
				p.rot[i] = rot_one[i].slerp(p.rot[i], two)
			p.dirty = true
	set_lids(p, 0.0)


## 单手抡剑那一段：右手握点(胸腔局部) + 剑身方向(世界)；左手松开前指 → 劈下时抓回剑柄
func _heavy_one_hand(p, t: float) -> void:
	var grip: Vector3 = kf_v([[0.00, HEAVY_GRIP], [0.18, Vector3(-15.0, 60.0, 6.0)], [0.34, Vector3(-12.5, 68.0, 1.5), "o"],
		[0.44, Vector3(-12.0, 69.0, 0.0)], [0.48, Vector3(-10.0, 72.0, 11.0), "i"], [0.52, Vector3(-5.0, 53.0, 16.0), "i"],
		[0.60, Vector3(-2.5, 49.0, 12.5), "o"], [0.76, Vector3(-3.0, 49.5, 12.5)], [0.94, Vector3(-3.0, 54.0, 12.0)], [1.2, HEAVY_GRIP]], t)
	var aw: Vector3 = kf_v([[0.00, Vector3(-0.2, -0.35, 0.9)], [0.18, Vector3(-0.85, 0.5, 0.15)], [0.34, Vector3(-0.35, 0.6, -0.72), "o"],
		[0.44, Vector3(-0.3, 0.5, -0.81)], [0.48, Vector3(-0.42, 0.86, 0.3), "i"], [0.52, Vector3(0.05, -0.45, 0.9), "i"],
		[0.60, Vector3(0.72, -0.6, 0.35), "o"], [0.76, Vector3(0.7, -0.62, 0.36)], [0.94, Vector3(0.0, -0.45, 0.9)], [1.2, Vector3(0.0, -0.45, 0.9)]], t).normalized()
	var engage: float = kf_f([[0.0, 0.0], [0.12, 1.0], [0.84, 1.0], [1.12, 0.0]], t)
	var q: Quaternion = _heavy_rot(_chest_dir(p, HEAVY_AXIS)).slerp(wrot(aw, HEAVY_SWING_N.cross(aw)), engage)
	var cq: Quaternion = _chest_q(p)
	var g: Vector3 = follow(p, "Chest", grip)
	hold_bow(p, g, q, cq * Vector3(-1.0, -0.4, -0.25))
	fist_r(p, 85.0)
	# 左手：松开 → 往前指着目标(掌心朝前，平衡) → 劈下时抓回剑柄(护手下方一拳处) → 随挥时按在柄上
	p.fk()
	var hilt: Vector3 = g - (q * Vector3.UP) * 6.0
	var point: Vector3 = follow(p, "Chest", Vector3(13.0, 60.0, 16.0))
	var rest: Vector3 = follow(p, "Chest", Vector3(15.2, 49.0, 1.6))
	# 开头和收势时左手在剑柄上(与两手合握的待机姿势一致，逐节过渡时手臂不会穿过身体)
	var aim_k: float = kf_f([[0.0, 0.0], [0.06, 0.0], [0.22, 1.0, "o"], [0.44, 1.0], [0.50, 0.0, "i"]], t)
	var grab: float = kf_f([[0.0, 1.0], [0.12, 0.0, "s"], [0.48, 0.0], [0.53, 1.0, "i"], [1.2, 1.0]], t)
	var lt: Vector3 = rest.lerp(point, aim_k).lerp(hilt, grab)
	var lq: Quaternion = (cq * Lib.E(-80.0, 20.0, 0.0)).slerp(q * Quaternion(Vector3.UP, PI), grab)
	lq = Lib.E(-6.0, -8.0, 10.0).slerp(lq, maxf(aim_k, grab))
	_protract_l(p, lt)
	hold_left(p, lt, lq, cq * Vector3(1.0, -0.25, 0.1))       # 左肘往外撑，别贴着胸口
	fist_l(p, lerpf(lerpf(14.0, 8.0, aim_k), 82.0, grab))


# =============================================================== 攻击：大剑·旋斩 (48f = 1.6s，出手 0.95s)
## [群攻3] 的群攻招式(射程内 2 个以上敌人时)：沉胯、剑拖到右后方(蓄力，重心压在右脚) → 右臂把剑平平甩出去、
## 低身原地转一整圈(越转越快，出手在剑扫回正前方时)，左臂往反方向张开配重 → 转过头一点、被剑的惯性带着慢下来 → 两手合握收回低架。
## 和大剑劈斩一样，抡剑这一段是右手单手(剑能伸到一臂之外、刃平着扫)，两手合握的待机姿势逐节 slerp 过渡
func attack_heavy_whirl(t: float, p) -> void:
	p.reset()
	var spin: float = kf_f([[0.0, 0.0], [0.34, 16.0, "o"], [0.46, 18.0], [1.00, -372.0, "s"], [1.22, -382.0, "o"], [1.45, -360.0], [1.6, -360.0]], t)
	var low: float = kf_f([[0.0, 0.0], [0.34, 1.0, "o"], [1.22, 1.0], [1.6, 0.0]], t)
	_twist(p, kf_f([[0.0, HEAVY_YAW], [0.34, -34.0, "o"], [0.46, -38.0], [0.62, 10.0], [1.2, 12.0], [1.6, HEAVY_YAW]], t),
		kf_f([[0.0, 0.0], [0.34, 5.0], [0.62, 10.0], [1.2, 9.0], [1.6, 0.0]], t), 0.0, 5.5 * low, 0.8)
	# 转圈时身体往外侧倾(离心)
	p.radd("Hips", 0.0, 0.0, kf_f([[0.0, 0.0], [0.5, 0.0], [0.8, -7.0], [1.05, -7.0], [1.3, 0.0]], t))
	# 原地转：脚跟着身体一起转(Root 转，脚的目标也按同一个角度转)，转的时候小碎步
	p.r("Root", 0.0, spin, 0.0)
	var qs := Quaternion(Vector3.UP, deg_to_rad(spin))
	var lead: float = kf_f([[0.0, HEAVY_LEAD], [0.34, -5.0], [0.52, -1.0], [1.3, -1.0], [1.6, HEAVY_LEAD]], t)
	var hop_l: float = _arc(t, 0.52, 0.68, 2.0) + _arc(t, 0.80, 0.94, 2.0)
	var hop_r: float = _arc(t, 0.66, 0.82, 2.0) + _arc(t, 0.94, 1.10, 1.6)
	legs(p, qs * Vector3(7.5, ANKLE_Y + hop_l, -0.5 + lead), qs * Vector3(-7.5, ANKLE_Y + hop_r, -0.5 - lead), Lib.E(0, spin + 6.0, 0), Lib.E(0, spin - 6.0, 0))
	var two: float = kf_f([[0.0, 1.0], [0.10, 0.0, "s"], [1.26, 0.0], [1.50, 1.0, "s"]], t)
	var base: Array[Quaternion] = p.rot.duplicate()
	var rot_one: Array[Quaternion] = base
	if two < 1.0:
		_whirl_one_hand(p, t)
		rot_one = p.rot.duplicate()
	if two > 0.0:
		p.rot = base.duplicate()
		_hold_heavy(p, HEAVY_GRIP, HEAVY_AXIS, HEAVY_SPAN, qs, Vector3.RIGHT.cross(HEAVY_AXIS.normalized()))
		if two < 1.0:
			for nm: String in ARM_BONES:
				var i: int = rig.ids[nm]
				p.rot[i] = rot_one[i].slerp(p.rot[i], two)
			p.dirty = true
	set_lids(p, 0.0)


## 旋斩的单手段：握点、剑身方向都在胸腔局部(跟着身体转)；刃口朝转动方向
func _whirl_one_hand(p, t: float) -> void:
	var ext: float = kf_f([[0.0, 0.0], [0.34, 0.2], [0.56, 1.0, "i"], [1.20, 1.0], [1.40, 0.3]], t)
	var wind: float = kf_f([[0.0, 0.0], [0.34, 1.0, "o"], [0.46, 1.0], [0.58, 0.0]], t)
	var grip: Vector3 = HEAVY_GRIP.lerp(Vector3(-14.0, 57.5, 16.5), ext) + Vector3(-4.0, 1.0, -9.0) * wind
	var axis: Vector3 = Vector3(-0.3, -0.45, 0.84).lerp(Vector3(-0.78, -0.08, 0.62), ext).lerp(Vector3(-0.35, -0.12, -0.93), wind).normalized()
	var cq: Quaternion = _chest_q(p)
	var a_w: Vector3 = (cq * axis).normalized()
	# 转动方向(绕 -Y)下剑身上一点的速度方向 = 刃口朝向
	var side_w: Vector3 = Vector3.DOWN.cross(a_w)
	var engage: float = kf_f([[0.0, 0.0], [0.16, 1.0], [1.26, 1.0], [1.50, 0.0]], t)
	var q: Quaternion = _heavy_rot(a_w).slerp(wrot(a_w, side_w if side_w.length() > 0.2 else cq * Vector3.FORWARD), engage)
	var g: Vector3 = follow(p, "Chest", grip)
	hold_bow(p, g, q, cq * Vector3(-1.0, -0.4, -0.25))
	fist_r(p, 85.0)
	# 左手：往左后方张开配重(掌心朝下)
	p.fk()
	var out: Vector3 = follow(p, "Chest", Vector3(18.0, 60.0, -5.0))
	# 单手段里左手一直张在外面；松开剑柄、回到剑柄都交给两手合握的逐节过渡(关节空间插值，手臂绕外侧走，不会穿过身体)
	hold_left(p, out, cq * Lib.E(0.0, -20.0, 70.0), cq * Vector3(1.0, -0.25, 0.1))
	fist_l(p, 10.0)


# =============================================================== 攻击：双匕 (15f = 0.5s，右手出手 0.18s，左手 0.28s)
## 压低身子、右刃举到右上方、左刃收在腰侧(蓄力) → 小跳一步、转腰右刃斜斩(出手) → 身体拧回来、左刃直刺(= [追击1] 的副本)
## → 两刃停一下 → 收回。刃的朝向用四元数关键帧(刃口领着挥动方向)
func attack_dual(t: float, p) -> void:
	p.reset()
	var q_r0: Quaternion = _dual_rot(DUAL_AXIS)
	var q_l0: Quaternion = mirror_q(q_r0)
	_twist(p, kf_f([[0.0, 0.0], [0.08, -24.0, "o"], [0.18, 26.0, "i"], [0.28, -14.0, "i"], [0.36, -12.0], [0.5, 0.0]], t),
		kf_f([[0.0, 0.0], [0.08, 2.0], [0.18, 10.0, "i"], [0.28, 12.0], [0.38, 8.0], [0.5, 0.0]], t),
		kf_f([[0.0, 0.0], [0.08, -1.0], [0.18, 3.5, "i"], [0.28, 4.5], [0.40, 3.0], [0.5, 0.0]], t),
		kf_f([[0.0, 0.0], [0.08, 3.0, "o"], [0.18, 2.5], [0.28, 3.5, "i"], [0.40, 2.5], [0.5, 0.0]], t), 0.85)
	# 小跳一步：两脚在 0.07~0.16 离地，往前落 2.5
	var fz: float = kf_f([[0.0, 0.0], [0.08, 0.0], [0.16, 2.5, "o"], [0.40, 2.5], [0.5, 0.0]], t)
	var hop: float = _arc(t, 0.07, 0.16, 1.8)
	_feet(p, 7.0, fz + 1.0 * Lib.smooth(t / 0.16) * (1.0 - Lib.smooth((t - 0.34) / 0.16)), hop, fz - 1.0, hop * 0.7)
	# 右刃：举到右上 → 斜斩到左前 → 随势带到左胯 → 收
	var gr: Vector3 = kf_v([[0.00, DUAL_GRIP], [0.08, Vector3(-15.0, 64.0, 7.0)], [0.18, Vector3(-5.0, 52.0, 15.0), "i"],
		[0.28, Vector3(-1.0, 50.0, 11.0), "o"], [0.38, Vector3(-4.0, 49.5, 11.0)], [0.50, DUAL_GRIP]], t)
	var qr: Quaternion = kf_q([[0.00, q_r0], [0.08, wrot(Vector3(-0.45, 0.85, 0.28), Vector3(-0.9, 0.3, 0.3))],     # 刃口先别翻(和待机同侧)，斩下去的那两帧里再转过来
		[0.18, wrot(Vector3(0.8, -0.1, 0.55), Vector3(0.3, -0.8, -0.5)), "i"], [0.28, wrot(Vector3(0.85, -0.35, 0.2), Vector3(0.2, -0.3, -0.93)), "o"],
		[0.38, wrot(Vector3(0.6, 0.2, 0.75), Vector3(0.1, -0.95, 0.2))], [0.50, q_r0]], t)
	# 左刃：收在腰侧 → 直刺 → 停 → 收
	var gl: Vector3 = kf_v([[0.00, mx(DUAL_GRIP)], [0.08, Vector3(12.0, 47.0, 2.0), "o"], [0.18, Vector3(12.5, 48.0, 0.5)],
		[0.28, Vector3(7.0, 54.0, 17.0), "i"], [0.36, Vector3(7.0, 54.0, 17.5)], [0.50, mx(DUAL_GRIP)]], t)
	var ql: Quaternion = kf_q([[0.00, q_l0], [0.08, wrot(Vector3(0.1, 0.25, 1.0), Vector3(1.0, 0.3, 0.0)), "o"], [0.18, wrot(Vector3(0.05, 0.3, 1.0), Vector3(1.0, 0.3, 0.0))],
		[0.28, wrot(Vector3(-0.05, 0.12, 1.0), Vector3(1.0, 0.2, 0.0)), "i"], [0.36, wrot(Vector3(-0.05, 0.12, 1.0), Vector3(1.0, 0.2, 0.0))], [0.50, q_l0]], t)
	var cq: Quaternion = _chest_q(p)
	hold_bow(p, follow(p, "Chest", gr), cq * qr, Vector3(-1.0, -0.3, -0.5))
	fist_r(p, 82.0)
	hold_left(p, follow(p, "Chest", gl), cq * ql, Vector3(1.0, -0.4, -0.5))
	fist_l(p, 82.0)
	set_lids(p, 0.0)


# =============================================================== 技能：冲锋 / 落地旋斩
## 冲锋(15f，实际冲锋 0.12~0.5 s，落地就切旋斩)：一蹬地扑出去——重心压得很低、上身往前扑，前腿弓、后腿蹬直，
## 两把刀往身后甩开、刃尖朝后下拖在身后(像狼扑过去)；0.07 s 内进入姿势然后保持，身体带一点高频抖动(速度感，残影由表现层画)
func dash_dual(t: float, p) -> void:
	p.reset()
	var k: float = kf_f([[0.0, 0.0], [0.07, 1.0, "o"]], t)
	var jit: float = sin(t * 70.0) * 0.8 * k
	_twist(p, -6.0 * k, 36.0 * k + jit, 5.0 * k, 9.0 * k, 0.9)
	p.radd("Head", -14.0 * k, 0.0, 0.0)                     # 抬头盯着前面
	legs(p, Vector3(6.0, ANKLE_Y + 1.5 * k, -0.5 + 10.0 * k), Vector3(-6.0, ANKLE_Y + 4.0 * k, -0.5 - 11.0 * k),
		Lib.E(0, 6.0, 0), Lib.E(-30.0 * k, -12.0, 0), 0.0, -20.0 * k)
	var cq: Quaternion = _chest_q(p)
	var r0: Quaternion = _dual_rot(DUAL_AXIS)
	var gr: Vector3 = DUAL_GRIP.lerp(Vector3(-15.5, 45.0, -7.5), k)
	var qr: Quaternion = r0.slerp(wrot(Vector3(-0.35, -0.3, -1.0), Vector3(-0.3, 1.0, 0.0)), k)
	hold_bow(p, follow(p, "Chest", gr), cq * qr, Vector3(-1.0, -0.2, -0.7))
	fist_r(p, 84.0)
	var gl: Vector3 = mx(DUAL_GRIP).lerp(Vector3(15.5, 45.0, -7.5), k)
	var ql: Quaternion = mirror_q(r0).slerp(wrot(Vector3(0.35, -0.3, -1.0), Vector3(0.3, 1.0, 0.0)), k)
	hold_left(p, follow(p, "Chest", gl), cq * ql, Vector3(1.0, -0.2, -0.7))
	fist_l(p, 84.0)
	set_lids(p, 0.0)


## 落地旋斩(15f)：落地一压 → 两臂向两侧张开、刀身放平，原地顺时针转一整圈(刃口领着转向)，离心往外倾 → 收回待机架势
func spin_dual(t: float, p) -> void:
	p.reset()
	var spin: float = kf_f([[0.0, 0.0], [0.05, 22.0, "o"], [0.31, -360.0, "o"], [0.5, -360.0]], t)
	var open: float = kf_f([[0.0, 0.0], [0.1, 1.0, "s"], [0.31, 1.0], [0.47, 0.0]], t)
	var low: float = kf_f([[0.0, 1.0], [0.05, 1.3, "o"], [0.31, 1.0], [0.5, 0.0]], t)
	p.r("Root", 0.0, spin, 0.0)
	var qs := Quaternion(Vector3.UP, deg_to_rad(spin))
	_twist(p, 0.0, 9.0 * low, 0.0, 4.5 * low, 0.6)
	p.radd("Hips", 0.0, 0.0, -6.0 * open * low)
	var hop: float = _arc(t, 0.12, 0.26, 1.4)
	legs(p, qs * Vector3(8.0, ANKLE_Y + hop, 0.5), qs * Vector3(-8.0, ANKLE_Y, -1.2), Lib.E(0, spin + 10.0, 0), Lib.E(0, spin - 10.0, 0))
	var cq: Quaternion = _chest_q(p)
	var r0: Quaternion = _dual_rot(DUAL_AXIS)
	# 顺时针转(绕 -Y)：右刀往后扫、左刀往前扫，刃口(+Z)朝各自的扫动方向
	var gr: Vector3 = DUAL_GRIP.lerp(Vector3(-21.0, 58.0, 4.0), open)
	var qr: Quaternion = r0.slerp(wrot(Vector3(-1.0, -0.08, 0.15), Vector3(0.0, 0.1, -1.0)), open)
	hold_bow(p, follow(p, "Chest", gr), cq * qr, Vector3(-0.6, -0.8, -0.2))
	fist_r(p, 84.0)
	var gl: Vector3 = mx(DUAL_GRIP).lerp(Vector3(21.0, 58.0, 4.0), open)
	var ql: Quaternion = mirror_q(r0).slerp(wrot(Vector3(1.0, -0.08, 0.15), Vector3(0.0, 0.1, 1.0)), open)
	hold_left(p, follow(p, "Chest", gl), cq * ql, Vector3(0.6, -0.8, -0.2))
	fist_l(p, 84.0)
	set_lids(p, 0.0)


## 大剑冲锋：两手握剑、剑身斜拖在右后下方(剑尖快擦着地)，压低身子往前扑
func dash_heavy(t: float, p) -> void:
	p.reset()
	var k: float = kf_f([[0.0, 0.0], [0.07, 1.0, "o"]], t)
	_stance(p, HEAVY_YAW * (1.0 - k) + 20.0 * k, HEAVY_LEAD)
	_twist(p, 20.0 * k, 22.0 * k + sin(t * 70.0) * 0.8 * k, 3.0 * k, 6.0 * k, 0.9)
	_feet(p, 6.0, 7.0 * k, 1.0 * k, -8.0 * k, 2.5 * k, 6.0, -12.0)
	_hold_heavy(p, HEAVY_GRIP.lerp(Vector3(-5.0, 52.0, 8.0), k), HEAVY_AXIS.lerp(Vector3(-0.55, -0.6, -0.35), k).normalized())
	set_lids(p, 0.0)


## 大剑落地旋斩：直接用旋斩(attack_heavy_whirl)转圈的那一段，压缩到 0.6 s
func spin_heavy(t: float, p) -> void:
	attack_heavy_whirl(lerpf(0.40, 1.60, clampf(t / (18.0 * F), 0.0, 1.0)), p)


# =============================================================== 攻击：手弩 (18f = 0.6s，出手 0.20s)
## 侧身一甩把手弩举平到眼前(头压低贴着瞄) → 一瞬瞄准 → 击发：手腕上跳、肩膀被顶回、上身后仰 → 稳住瞄准一下 → 放下
## 空手往身后展开平衡
func attack_crossbow(t: float, p) -> void:
	p.reset()
	var dur := 18.0 * F
	var raise: float = kf_f([[0.0, 0.0], [0.13, 1.0, "o"], [0.42, 1.0], [dur, 0.0]], t)
	var kick: float = kf_f([[0.0, 0.0], [0.20, 0.0], [0.23, 1.0, "o"], [0.36, 0.0], [dur, 0.0]], t)
	_twist(p, 16.0 * raise - 5.0 * kick, 3.0 * raise - 5.0 * kick, -1.5 * kick, 1.0 * raise, 0.9)
	p.radd("Head", 4.0 * raise - 6.0 * kick, 0.0, -5.0 * raise)                 # 歪头贴着瞄，击发时一闪
	_feet(p, 7.0, 2.5 * raise, 0.0, -1.0 * raise, 0.0, 6.0 + 16.0 * raise, -6.0 - 20.0 * raise)
	var g_aim := Vector3(-8.0, 63.0, 18.0)
	var gv: Vector3 = XBOW_GRIP.lerp(g_aim, raise) + Vector3(0.0, 2.5, -3.5) * kick
	var aim: Vector3 = XBOW_AIM.lerp(Vector3(0.02, 0.0, 1.0), raise) + Vector3(0.0, 0.38, 0.0) * kick
	var up: Vector3 = Vector3(0.0, 1.0, 0.4).lerp(Vector3(0.0, 1.0, 0.0), raise)
	hold_bow(p, follow(p, "Chest", gv), grot(aim, up), Vector3(-1.0, -0.6, -0.2))
	fist_r(p, 82.0)
	# 空手：往左后方展开(平衡)
	var lt: Vector3 = Vector3(15.2, 49.0, 1.6).lerp(Vector3(17.0, 56.0, -6.0), raise)
	p.ik2("UpperArm_L", "LowerArm_L", "Hand_L", follow(p, "Chest", lt), Vector3(0.6, -0.4, -0.8))
	p.set_grot("Hand_L", Lib.E(-6.0, -8.0, 10.0).slerp(Lib.E(10.0, -30.0, 40.0), raise))
	p.r("Fingers_L", lerpf(-14.0, -30.0, raise), 0, -22.0)
	p.r("Thumb_L", -10.0, 0, 0)
	set_lids(p, 0.0)


# =============================================================== 攻击：双枪 (13f = 0.433s，右枪 0.12s，左枪 0.22s)
## 压低重心、两枪同时举平(枪身往里斜一点) → 右枪击发(右肩被顶回、上身往右拧) → 左枪击发(= [追击1]，身体往左拧)
## → 两枪放下。每一枪都有手腕上跳 + 肩膀后坐
func attack_pistols(t: float, p) -> void:
	p.reset()
	var dur := 13.0 * F
	var raise: float = kf_f([[0.0, 0.0], [0.09, 1.0, "o"], [0.30, 1.0], [dur, 0.0]], t)
	var kr: float = kf_f([[0.0, 0.0], [0.12, 0.0], [0.145, 1.0, "o"], [0.25, 0.0]], t)
	var kl: float = kf_f([[0.0, 0.0], [0.22, 0.0], [0.245, 1.0, "o"], [0.35, 0.0]], t)
	_twist(p, -7.0 * kr + 7.0 * kl, 4.0 * raise - 3.0 * (kr + kl), -1.0 * (kr + kl), 2.0 * raise, 0.9)
	p.radd("Head", -3.0 * (kr + kl), 0.0, 0.0)
	_feet(p, 7.5, 1.5 * raise, 0.0, -1.0 * raise, 0.0, 6.0 + 8.0 * raise, -6.0 - 8.0 * raise)
	var gr: Vector3 = PIST_GRIP.lerp(Vector3(-7.5, 62.0, 18.0), raise) + Vector3(0.0, 2.2, -3.2) * kr
	var gl: Vector3 = mx(PIST_GRIP).lerp(Vector3(7.5, 62.0, 18.0), raise) + Vector3(0.0, 2.2, -3.2) * kl
	var ar: Vector3 = PIST_AIM.lerp(Vector3(0.04, 0.0, 1.0), raise) + Vector3(0.0, 0.42, 0.0) * kr
	var al: Vector3 = mx(PIST_AIM).lerp(Vector3(-0.04, 0.0, 1.0), raise) + Vector3(0.0, 0.42, 0.0) * kl
	var ur: Vector3 = Vector3(0.0, 1.0, 0.45).lerp(Vector3(0.35, 1.0, 0.0), raise)
	var ul: Vector3 = Vector3(0.0, 1.0, 0.45).lerp(Vector3(-0.35, 1.0, 0.0), raise)
	var cq: Quaternion = _chest_q(p)
	hold_bow(p, follow(p, "Chest", gr), cq * grot(ar, ur), Vector3(-1.0, -0.6, -0.2))
	fist_r(p, 82.0)
	hold_left(p, follow(p, "Chest", gl), cq * mirror_q(grot(mx(al), mx(ul))), Vector3(1.0, -0.6, -0.2))
	fist_l(p, 82.0)
	set_lids(p, 0.0)


# =============================================================== 攻击：步枪 (20f = 0.67s，出手 0.10s，循环)
## 连射：一直抵肩瞄准，每一轮 = 击发 → 后坐(肩膀被顶回、枪口上跳、上身后仰) → 枪口压回来略低一点 → 回稳；
## 首尾同一个瞄准姿势，连射期间同一个动作接着循环，不回待机
const RIFLE_AIM_GRIP := Vector3(-7.5, 62.0, 9.0)


func _rifle_aimed(p, recoil: float, sway: float) -> void:
	_twist(p, -24.0 - 4.0 * recoil, 2.0 - 6.0 * recoil, -2.0 * recoil, 1.0, 0.9)
	p.radd("Head", -4.0 * maxf(recoil, 0.0), 0.0, 0.0)
	_stance_feet(p, 7.0, 2.5)
	_hold_rifle(p, RIFLE_AIM_GRIP + Vector3(0.0, 2.2 * recoil + 0.3 * sway, -3.5 * recoil), Vector3(0.0, 0.22 * recoil, 1.0), Vector3(0.0, 1.0, 0.0), -14.0)


func attack_rifle(t: float, p) -> void:
	p.reset()
	_rifle_aimed(p, kf_f([[0.0, 0.0], [0.10, 0.0], [0.13, 1.0, "o"], [0.30, 0.12], [0.42, -0.1], [0.56, 0.0], [20.0 * F, 0.0]], t), 0.0)
	set_lids(p, 0.0)


## 连射间隙：端着枪瞄准(呼吸轻晃)
func aim_rifle(t: float, p) -> void:
	p.reset()
	_rifle_aimed(p, 0.0, sin(TAU * t / (30.0 * F)))
	set_lids(p, blink_k(t, 0.6))


## 装弹 (78f = 2.6s)，从瞄准姿势开始、回到瞄准姿势结束(装完马上接着打)：
## 枪从肩上放下、枪身往右滚让弹匣口朝左、低头看枪 → 左手抓住旧弹匣往下一拔、往外甩掉(手张开) → 去左腰摸新弹匣
## → 拿上来对准插进去、往上一拍(枪被拍得一跳) → 左手去护木左上方的拉机柄、猛地往回一拉一放 → 重新抵肩瞄准、抬头
func reload_rifle(t: float, p) -> void:
	p.reset()
	var lower: float = kf_f([[0.0, 0.0], [0.30, 1.0, "o"], [2.10, 1.0], [2.45, 0.0, "s"]], t)
	var look: float = kf_f([[0.0, 0.0], [0.30, 1.0], [0.80, 1.0], [1.00, 0.6], [1.15, 1.0], [2.05, 1.0], [2.40, 0.0]], t)
	var slap: float = _arc(t, 1.62, 1.74, 1.0)
	var rack: float = _arc(t, 1.98, 2.08, 1.0)
	_twist(p, -24.0 * (1.0 - lower) + 6.0 * lower - 4.0 * rack, 2.0 + 6.0 * lower * kf_f([[0.0, 0.0], [0.8, 0.0], [1.0, 1.0], [1.2, 0.3], [2.6, 0.0]], t) + 2.0 * lower,
		-1.0 * rack, 1.0 + 1.5 * lower, 0.9)
	p.radd("Head", 18.0 * look, -8.0 * look, 0.0)
	_stance_feet(p, 7.0, 2.5 - 1.0 * lower)
	# 枪：右手单手托着，枪身端在胸前、往右滚(弹匣口朝左)
	var gv: Vector3 = RIFLE_AIM_GRIP.lerp(Vector3(-7.0, 50.5, 14.0), lower) + Vector3(0.0, 1.5, 0.0) * slap + Vector3(0.0, 0.0, -1.0) * rack
	var aim: Vector3 = Vector3(0.0, 0.0, 1.0).lerp(Vector3(0.45, 0.28, 0.85), lower) + Vector3(0.0, 0.12, 0.0) * slap
	var up: Vector3 = Vector3(0.0, 1.0, 0.0).lerp(Vector3(-0.7, 0.7, -0.1), lower)
	# 瞄准时枪的朝向是世界方向(与 _rifle_aimed 一致)，放下后跟着胸腔走
	var cq: Quaternion = _chest_q(p)
	var q: Quaternion = Quaternion.IDENTITY.slerp(cq, lower) * grot(aim, up)
	var g: Vector3 = follow(p, "Chest", gv)
	hold_bow(p, g, q, Vector3(-1.0, -0.5, -0.3))
	fist_r(p, 80.0)
	# 左手：在枪的坐标系里取几个点(护木 / 弹匣口 / 枪栓)，腰包在胸腔局部
	var fwd: Vector3 = (q * Vector3(0.0, -1.0, 0.0)).normalized()
	var upw: Vector3 = (q * Vector3(0.0, 0.0, 1.0)).normalized()
	var fore: Vector3 = g + fwd * 14.0
	var well: Vector3 = g + fwd * 6.5 - upw * 3.5
	var pulled: Vector3 = well - upw * 7.0
	var fling: Vector3 = follow(p, "Chest", Vector3(19.0, 50.0, 10.0))
	var pouch: Vector3 = follow(p, "Chest", Vector3(11.5, 45.5, 8.5))
	var sidew: Vector3 = (q * Vector3(1.0, 0.0, 0.0)).normalized()        # 枪的左侧(拉机柄在护木左上方，左手不用横穿胸口)
	var handle: Vector3 = g + fwd * 11.5 + upw * 2.0 + sidew * 2.5
	var hand: Vector3 = kf_v([[0.0, fore], [0.30, fore], [0.45, well, "o"], [0.60, pulled, "o"], [0.76, fling, "o"], [1.00, pouch],
		[1.12, pouch], [1.38, well - upw * 3.0, "o"], [1.52, well, "i"], [1.62, well - upw * 1.5], [1.68, well, "i"], [1.80, well - upw * 2.0],
		[1.95, handle, "o"], [2.03, handle - fwd * 3.4, "i"], [2.12, handle - fwd * 2.6], [2.35, fore, "o"], [2.6, fore]], t)
	var q_fore: Quaternion = q
	var q_open: Quaternion = q * Quaternion(Vector3(0.0, 1.0, 0.0), 0.6)
	var hq: Quaternion = kf_q([[0.0, q_fore], [0.30, q_fore], [0.45, q_open], [0.76, cq * Lib.E(-20.0, -40.0, 60.0)], [1.00, cq * Lib.E(-60.0, 0.0, 20.0)],
		[1.38, q_open], [1.80, q_open], [1.95, q], [2.35, q_fore]], t)
	_protract_l(p, hand)
	hold_left(p, hand, hq, Vector3(1.0, -0.45, -0.2))       # 左肘往外撑，别压到胸前
	# 甩掉旧弹匣时手张开，其余时候握着
	var open: float = kf_f([[0.0, 0.0], [0.70, 0.0], [0.78, 1.0, "o"], [0.95, 1.0], [1.05, 0.0]], t)
	fist_l(p, lerpf(80.0, 10.0, open))
	set_lids(p, 0.0)


# =============================================================== 攻击：法器 (27f = 0.9s，出手 0.36s)
## 聚能：把法器收到胸前、左手合拢罩在上面、低头压身(蓄力) → 起身 → 右手把法器推出去、左手掌心朝前一起推(出手)，左脚上步
## → 停一下(被反冲往回顶一点) → 收回
func attack_focus(t: float, p) -> void:
	p.reset()
	var gather: float = kf_f([[0.0, 0.0], [0.20, 1.0, "o"], [0.27, 1.0], [0.34, 0.0, "i"]], t)
	var push: float = kf_f([[0.0, 0.0], [0.27, 0.0], [0.36, 1.0, "i"], [0.50, 0.9, "o"], [0.90, 0.0]], t)
	var kick: float = _arc(t, 0.36, 0.52, 1.0)
	_twist(p, kf_f([[0.0, 0.0], [0.20, -12.0, "o"], [0.36, 10.0, "i"], [0.50, 8.0], [0.9, 0.0]], t),
		-4.0 * gather + 11.0 * push - 3.0 * kick, 3.0 * push - 1.0 * kick, 2.5 * gather - 1.0 * push + 1.5 * push * (1.0 - kick), 0.8)
	p.radd("Head", 10.0 * gather - 4.0 * push, 0.0, 0.0)
	_feet(p, 6.5, 3.0 * push, _arc(t, 0.27, 0.36, 1.6), -0.5 * push, 0.0, 6.0 + 6.0 * push, -6.0)
	var gc := Vector3(-3.0, 57.0, 10.0)
	var gp := Vector3(-6.0, 60.5, 19.0)
	var gv: Vector3 = FOCUS_GRIP.lerp(gc, gather).lerp(gp, push) + Vector3(0.0, 0.5, -2.0) * kick
	var aim: Vector3 = FOCUS_AIM.lerp(Vector3(0.6, 0.5, 0.6), gather).lerp(Vector3(0.05, 0.08, 1.0), push)
	var up: Vector3 = Vector3(0.0, 1.0, 0.15).lerp(Vector3(-0.3, 0.6, -0.7), gather).lerp(Vector3(0.0, 1.0, 0.1), push)
	var cq: Quaternion = _chest_q(p)
	hold_bow(p, follow(p, "Chest", gv), cq * grot(aim, up), Vector3(-1.0, -0.5, -0.5))
	fist_r(p, 70.0)
	# 左手：垂着 → 罩在法器上方 → 掌心朝前推出
	var lt: Vector3 = Vector3(15.2, 49.0, 1.6).lerp(Vector3(4.0, 60.0, 10.0), gather).lerp(Vector3(6.0, 61.5, 17.5), push) + Vector3(0.0, 0.5, -2.0) * kick
	p.ik2("UpperArm_L", "LowerArm_L", "Hand_L", follow(p, "Chest", lt), Vector3(0.7, -0.5, -0.6))
	var hq: Quaternion = Lib.E(-6.0, -8.0, 10.0).slerp(cq * Lib.E(90.0, 20.0, -10.0), gather)
	hq = hq.slerp(cq * Lib.E(-80.0, 10.0, 0.0), push)
	p.set_grot("Hand_L", hq)
	p.r("Fingers_L", lerpf(-14.0, -40.0, gather) * (1.0 - push) - 4.0 * push, 0, -22.0 * (1.0 - push))
	p.r("Thumb_L", -10.0 + 20.0 * push, 0, 0)
	set_lids(p, 0.0)


# =============================================================== 灾星节点：召唤流星
const STAFF_GRIP := Vector3(-15.0, 48.5, 6.5)     # 右手竖握法杖(杖尾点在右脚前)
const STAFF_AXIS := Vector3(0.06, 1.0, 0.12)


## 竖握法杖的待机(双手长武器当法杖用的棋子：灾星节点、和星节点)
func idle_staff(t: float, p) -> void:
	_set_kit("staff")
	idle(t, p)


## 左手：垂着 → 举到头侧掌心朝天(召唤) → 往前推出掌心(落下)；k_up / k_push 是两段的权重
func _witch_left(p, cq: Quaternion, k_up: float, k_push: float) -> void:
	var lt: Vector3 = Vector3(15.2, 49.0, 1.6).lerp(Vector3(17.5, 73.0, 3.0), k_up).lerp(Vector3(7.5, 60.5, 17.5), k_push)
	p.ik2("UpperArm_L", "LowerArm_L", "Hand_L", follow(p, "Chest", lt), Vector3(0.8, -0.4, -0.5))
	var hq: Quaternion = Lib.E(-6.0, -8.0, 10.0).slerp(cq * Lib.E(-170.0, 10.0, -20.0), k_up)
	hq = hq.slerp(cq * Lib.E(-80.0, 10.0, 0.0), k_push)
	p.set_grot("Hand_L", hq)
	p.r("Fingers_L", lerpf(-14.0, -6.0, maxf(k_up, k_push)), 0, -22.0 * (1.0 - maxf(k_up, k_push)))
	p.r("Thumb_L", -10.0 + 18.0 * k_push, 0, 0)


## 法杖召唤流星(24f = 0.8s，出手 0.30s)：杖往天上一举、仰头、左手掌心朝天 → 杖头往前下一指、身子前倾、左手推出(流星落下) → 收回竖握
func attack_witch_polearm(t: float, p) -> void:
	p.reset()
	var dur := 24.0 * F
	var up: float = kf_f([[0.0, 0.0], [0.20, 1.0, "o"], [0.25, 1.0], [0.31, 0.0, "i"]], t)
	var push: float = kf_f([[0.0, 0.0], [0.24, 0.0], [0.31, 1.0, "i"], [0.48, 0.9, "o"], [dur, 0.0]], t)
	_twist(p, -6.0 * up + 6.0 * push, -7.0 * up + 10.0 * push, 2.0 * push, 1.5 * up, 0.8)
	p.radd("Head", -14.0 * up + 4.0 * push, 0.0, 0.0)
	_feet(p, 6.5, 2.5 * push, _arc(t, 0.24, 0.31, 1.4), -0.5 * push, 0.0, 6.0 + 5.0 * push, -6.0)
	var gq0: Quaternion = wrot(STAFF_AXIS, Vector3(0, 0, 1))
	var grip: Vector3 = kf_v([[0.0, STAFF_GRIP], [0.20, Vector3(-12.0, 66.0, 6.0), "o"], [0.25, Vector3(-12.0, 67.0, 5.0)],
		[0.31, Vector3(-7.0, 59.0, 15.5), "i"], [0.48, Vector3(-7.0, 58.5, 16.0)], [dur, STAFF_GRIP]], t)
	var q: Quaternion = kf_q([[0.0, gq0], [0.20, wrot(Vector3(0.12, 1.0, -0.12), Vector3(0, 0, 1)), "o"], [0.25, wrot(Vector3(0.12, 1.0, -0.18), Vector3(0, 0, 1))],
		[0.31, wrot(Vector3(0.05, 0.42, 1.0), Vector3(0, -1, 0.4)), "i"], [0.48, wrot(Vector3(0.05, 0.38, 1.0), Vector3(0, -1, 0.4))], [dur, gq0]], t)
	var cq: Quaternion = _chest_q(p)
	hold_bow(p, follow(p, "Chest", grip), cq * q, Vector3(-1.0, -0.4, -0.4))
	fist_r(p, 82.0)
	_witch_left(p, cq, up, push)
	set_lids(p, 0.0)


## 法器召唤流星(27f = 0.9s，出手 0.36s)：法器举过头顶、仰头、左手掌心朝天 → 两手一起往前下推出(流星落下) → 收回
func attack_witch_focus(t: float, p) -> void:
	p.reset()
	var dur := 27.0 * F
	var up: float = kf_f([[0.0, 0.0], [0.25, 1.0, "o"], [0.30, 1.0], [0.37, 0.0, "i"]], t)
	var push: float = kf_f([[0.0, 0.0], [0.30, 0.0], [0.37, 1.0, "i"], [0.55, 0.9, "o"], [dur, 0.0]], t)
	_twist(p, -6.0 * up + 8.0 * push, -7.0 * up + 11.0 * push, 2.5 * push, 1.5 * up, 0.8)
	p.radd("Head", -14.0 * up + 4.0 * push, 0.0, 0.0)
	_feet(p, 6.5, 3.0 * push, _arc(t, 0.30, 0.37, 1.6), -0.5 * push, 0.0, 6.0 + 6.0 * push, -6.0)
	var gv: Vector3 = kf_v([[0.0, FOCUS_GRIP], [0.25, Vector3(-12.0, 73.0, 5.0), "o"], [0.30, Vector3(-12.0, 74.0, 4.0)],
		[0.37, Vector3(-6.0, 60.5, 18.5), "i"], [0.55, Vector3(-6.0, 60.0, 19.0)], [dur, FOCUS_GRIP]], t)
	var aim: Vector3 = kf_v([[0.0, FOCUS_AIM], [0.25, Vector3(0.0, 0.25, 1.0), "o"], [0.37, Vector3(0.05, -0.1, 1.0), "i"], [dur, FOCUS_AIM]], t)
	var upv: Vector3 = kf_v([[0.0, Vector3(0.0, 1.0, 0.15)], [0.25, Vector3(0.0, 1.0, -0.3), "o"], [0.37, Vector3(0.0, 1.0, 0.1), "i"], [dur, Vector3(0.0, 1.0, 0.15)]], t)
	var cq: Quaternion = _chest_q(p)
	hold_bow(p, follow(p, "Chest", gv), cq * grot(aim, upv), Vector3(-1.0, -0.5, -0.5))
	fist_r(p, 70.0)
	_witch_left(p, cq, up, push)
	set_lids(p, 0.0)


# =============================================================== 技能：投掷(狩胜节点·必胜) (21f = 0.7s，出手 0.34s = 逻辑的前摇)
## 右手把武器举到右肩后上方：长矛 = 矛尖朝前的标枪握法(肘高高架起)，剑类 = 剑尖朝后上方、准备过头抡出；左手往前伸直指着目标；
## 身体往右后拧、重心压在后脚(蓄力) → 一停 → 左脚大步踏出、身体整个拧回来、右臂从肩后鞭甩出去(出手，武器离手 = 武器骨缩到 0)
## → 随挥：右手顺势落到左腰前、上身前压 → 收回站姿。双匕：左手那把同时往前一甩
const THROW_REL := 0.34


func throw_polearm(t: float, p) -> void:
	_throw(t, p, "javelin")


func throw_sword(t: float, p) -> void:
	_throw(t, p, "overhand")


func throw_heavy(t: float, p) -> void:
	_throw(t, p, "heavy")


func throw_dual(t: float, p) -> void:
	_throw(t, p, "dual")


func _throw(t: float, p, kind: String) -> void:
	p.reset()
	var dur := 21.0 * F
	var jav: bool = kind == "javelin"
	var heavy: bool = kind == "heavy"
	var draw: float = kf_f([[0.0, 0.0], [0.20, 1.0, "o"], [0.27, 1.0], [THROW_REL, 0.0, "i"]], t)
	var fling: float = kf_f([[0.0, 0.0], [0.27, 0.0], [THROW_REL, 1.0, "i"], [0.48, 1.0], [dur, 0.0]], t)
	var thru: float = kf_f([[0.0, 0.0], [THROW_REL, 0.0], [0.44, 1.0, "o"], [0.54, 1.0], [dur, 0.0]], t)
	var coil: float = 1.25 if heavy else 1.0
	_twist(p, (-48.0 * draw + 30.0 * fling) * coil, -9.0 * draw + 13.0 * fling + 6.0 * thru, -1.5 * draw + 3.0 * fling, 1.5 * draw + 2.5 * fling, 0.85)
	var lz: float = kf_f([[0.0, 0.0], [0.20, 1.5], [0.27, 1.5], [THROW_REL, 8.0, "o"], [0.56, 8.0], [dur, 0.0]], t)
	_feet(p, 7.0, lz, _arc(t, 0.27, THROW_REL + 0.02, 2.6), -1.5 * draw - 2.0 * fling, _arc(t, 0.38, 0.52, 1.4),
		6.0 + 10.0 * draw, -6.0 - 18.0 * draw + 12.0 * fling)
	# 右手(握武器)：胸腔局部的握点；武器的朝向是模型空间方向(+Z 朝前)，投出去的方向一直对着目标
	var g_rest := Vector3(-14.5, 49.0, 6.0)
	var g_back := Vector3(-13.5, 74.0, -6.0) if jav else Vector3(-11.0, 77.5, -4.0)
	var g_out := Vector3(-6.5, 71.0, 16.0)
	var g_low := Vector3(2.0, 54.0, 13.5)
	var grip: Vector3 = kf_v([[0.0, g_rest], [0.20, g_back, "o"], [0.27, g_back + Vector3(0.0, 0.8, -1.5)], [THROW_REL, g_out, "i"],
		[0.44, g_low, "o"], [0.54, g_low], [dur, g_rest]], t)
	var axis: Vector3
	if jav:
		axis = kf_v([[0.0, Vector3(0.1, 0.4, 1.0)], [0.20, Vector3(0.04, 0.14, 1.0), "o"], [0.27, Vector3(0.04, 0.12, 1.0)],
			[THROW_REL, Vector3(0.0, 0.04, 1.0), "i"], [0.44, Vector3(-0.1, -0.35, 1.0)], [dur, Vector3(0.1, 0.4, 1.0)]], t)
	else:
		axis = kf_v([[0.0, Vector3(0.0, 0.7, 0.7)], [0.20, Vector3(0.12, 0.55, -0.83), "o"], [0.27, Vector3(0.12, 0.3, -0.95)],
			[THROW_REL, Vector3(0.0, 0.65, 0.76), "i"], [0.44, Vector3(0.05, -0.6, 0.8)], [dur, Vector3(0.0, 0.7, 0.7)]], t)
	var pole: Vector3 = kf_v([[0.0, Vector3(-1.0, -0.5, -0.4)], [0.20, Vector3(-1.0, 0.35, -0.7), "o"], [THROW_REL, Vector3(-1.0, -0.1, 0.3), "i"],
		[0.44, Vector3(-0.6, -0.8, 0.2)], [dur, Vector3(-1.0, -0.5, -0.4)]], t)
	# 标枪握法：武器局部 +Z(刃宽 / 战旗的旗面方向)朝下，旗垂在矛杆下面；剑类：刃面竖着(局部 +Z 朝左)
	hold_bow(p, follow(p, "Chest", grip), wrot(axis, Vector3(0.0, -1.0, 0.0) if jav else Vector3(1.0, 0.0, 0.0)), pole)
	fist_r(p, 84.0 if t < THROW_REL else lerpf(10.0, 60.0, clampf((t - 0.5) / 0.2, 0.0, 1.0)))
	var cq: Quaternion = _chest_q(p)
	if kind == "dual":
		# 左手那把：跟着往前一甩
		var gl: Vector3 = kf_v([[0.0, Vector3(13.0, 49.5, 7.0)], [0.20, Vector3(9.0, 63.0, 15.0), "o"], [THROW_REL, Vector3(5.5, 63.5, 19.0), "i"],
			[0.46, Vector3(10.0, 55.0, 14.0)], [dur, Vector3(13.0, 49.5, 7.0)]], t)
		var al: Vector3 = kf_v([[0.0, Vector3(0.0, 0.6, 0.8)], [0.20, Vector3(-0.2, 0.75, 0.3)], [THROW_REL, Vector3(0.0, 0.25, 1.0), "i"],
			[0.46, Vector3(0.0, -0.4, 0.9)], [dur, Vector3(0.0, 0.6, 0.8)]], t)
		hold_left(p, follow(p, "Chest", gl), mirror_q(wrot(mx(al), Vector3(1.0, 0.0, 0.0))), Vector3(1.0, -0.4, -0.3))
		fist_l(p, 84.0 if t < THROW_REL else 20.0)
	else:
		# 左手：往前伸直指着目标(掌心朝下) → 出手时猛地拉回腰侧(反作用) → 垂下
		var lt: Vector3 = kf_v([[0.0, Vector3(15.2, 49.0, 1.6)], [0.20, Vector3(9.0, 66.5, 17.0), "o"], [0.27, Vector3(9.0, 67.0, 17.5)],
			[THROW_REL, Vector3(15.0, 53.0, 3.0), "i"], [0.46, Vector3(15.5, 51.0, -1.0)], [dur, Vector3(15.2, 49.0, 1.6)]], t)
		p.ik2("UpperArm_L", "LowerArm_L", "Hand_L", follow(p, "Chest", lt), _chest_dir(p, Vector3(0.8, -0.4, -0.5)))
		var hq: Quaternion = Lib.E(-6.0, -8.0, 10.0).slerp(cq * Lib.E(-95.0, 15.0, 0.0), draw * (1.0 - fling))
		p.set_grot("Hand_L", hq)
		p.r("Fingers_L", -6.0 - 30.0 * fling * (1.0 - thru), 0, -22.0 * (1.0 - draw))
		p.r("Thumb_L", -10.0, 0, 0)
	if t >= THROW_REL:
		p.scale_("Bow", Vector3.ONE * 0.001)
		p.scale_("Weapon_L", Vector3.ONE * 0.001)
	set_lids(p, 0.0)


# =============================================================== 技能：飞扑(投掷后追着武器扑过去)(15f = 0.5s)
## 表现层把这段按位移时长缩放，并按 UnitView.LEAP_PREP(0.18) / LEAP_LAND(0.85) 的节奏把人往回拉 / 往前推、加上腾空的弧线——
## 动作的几个阶段和那两个时刻对齐(u = 占整段的比例)：
##   0 ~ 0.18  蓄力：深蹲、身子压低前倾，两臂往后甩到底
##   0.18 ~ 0.26 蹬地：两腿一下蹬直、身子往前探成一条线，两臂往前抡
##   0.26 ~ 0.8  空中：身子几乎放平往前扑，右手往前伸去够武器、左手往后拉，腿收在身后；最后一段腿往前伸准备落地
##   0.85 砸地：重重落下深蹲(比蓄力还低)、左手撑地、右手一握接住武器、抬头 → 收势稍微起身
func leap(t: float, p) -> void:
	p.reset()
	var u: float = t / (15.0 * F)
	var crouch: float = kf_f([[0.0, 0.25], [0.15, 1.0, "o"], [0.22, 0.0, "i"], [0.8, 0.0], [0.86, 1.25, "o"], [1.0, 0.7]], u)
	var air: float = kf_f([[0.0, 0.0], [0.18, 0.0], [0.27, 1.0, "o"], [0.7, 1.0], [0.84, 0.0, "i"], [1.0, 0.0]], u)
	var ext: float = kf_f([[0.0, 0.0], [0.17, 0.0], [0.22, 1.0, "o"], [0.32, 0.0]], u)                 # 蹬地那一下全身蹬直
	var land: float = kf_f([[0.0, 0.0], [0.8, 0.0], [0.86, 1.0, "o"], [1.0, 0.75]], u)
	var wind: float = kf_f([[0.0, 0.2], [0.15, 1.0, "o"], [0.22, 0.0, "i"]], u)                      # 蓄力时两臂往后甩
	var prep_land: float = kf_f([[0.0, 0.0], [0.68, 0.0], [0.82, 1.0, "i"], [0.9, 0.0]], u)          # 落地前腿往前伸
	_twist(p, 0.0, 16.0 * crouch + 50.0 * air + 10.0 * ext + 26.0 * land, 2.5 * air - 1.5 * crouch, 7.0 * crouch + 8.0 * land - 2.0 * ext, 0.75)
	p.radd("Head", -14.0 * air - 10.0 * land, 0.0, 0.0)
	# 腿：蓄力 / 砸地时前后错开踩在地上(深蹲)，空中收在身后，落地前往前伸
	var lz: float = -0.5 + 2.5 * crouch + 4.5 * land - 6.0 * air + 9.0 * prep_land
	var rz: float = -0.5 - 3.5 * crouch - 4.0 * land - 9.0 * air + 4.0 * prep_land
	var ly: float = ANKLE_Y + 10.0 * air * (1.0 - prep_land) + 2.0 * ext
	var ry: float = ANKLE_Y + 13.0 * air * (1.0 - prep_land) + 3.0 * ext
	legs(p, Vector3(6.8, ly, lz), Vector3(-6.8, ry, rz), Lib.E(-25.0 * air, 10.0, 0.0), Lib.E(-35.0 * air, -10.0, 0.0), -15.0 * air, 10.0 * land)
	# 右手：往后甩 → 空中往前伸去够武器 → 落地低低地往前一握
	var rh: Vector3 = Vector3(-14.5, 49.0, 6.0)
	rh = rh.lerp(Vector3(-15.0, 47.0, -8.0), wind)
	rh = rh.lerp(Vector3(-7.0, 66.0, 18.0), maxf(air, ext * 0.7))
	rh = rh.lerp(Vector3(-9.0, 47.0, 17.0), land)
	p.ik2("UpperArm_R", "LowerArm_R", "Hand_R", follow(p, "Chest", rh), _chest_dir(p, Vector3(-0.8, -0.5, -0.4)))
	# 左手：往后甩 → 空中往后拉开 → 落地撑在身前的地上
	var lh: Vector3 = Vector3(15.2, 49.0, 1.6)
	lh = lh.lerp(Vector3(15.5, 47.0, -9.0), wind)
	lh = lh.lerp(Vector3(17.0, 56.0, -10.0), air)
	lh = lh.lerp(Vector3(12.0, 47.0, 10.0), land)
	p.ik2("UpperArm_L", "LowerArm_L", "Hand_L", follow(p, "Chest", lh), _chest_dir(p, Vector3(0.7, -0.4, -0.7)))
	p.r("Fingers_R", -lerpf(10.0, 88.0, clampf((u - 0.84) / 0.05, 0.0, 1.0)), 0, 0)
	p.r("Fingers_L", -14.0 + 10.0 * land, 0, -22.0)
	p.scale_("Bow", Vector3.ONE * 0.001)
	p.scale_("Weapon_L", Vector3.ONE * 0.001)
	p.scale_("Shield", Vector3.ONE * 0.001)
	set_lids(p, 0.0)


# =============================================================== 摸鱼(空白节点)(3.2s 循环)：蹲在原地，两手搭在膝盖上耷拉着，低头打瞌睡(闭眼)；
## 隔一会儿脑袋往下一栽、猛地抬起来，再慢慢垂下去。武器收起
func idle_slack(t: float, p) -> void:
	p.reset()
	var breathe: float = sin(TAU * t / 3.2)
	var nod: float = kf_f([[0.0, 0.0], [1.6, 0.0], [2.05, 1.0, "i"], [2.2, -0.6, "o"], [3.2, 0.0]], t)
	var drop := 14.0
	p.move("Hips", Vector3(0.0, -1.7 - drop + 0.4 * breathe, 2.5))
	p.r("Hips", 6.0, 0.0, 0.0)
	p.r("Spine", 4.0 + 1.0 * breathe, 0.0, 0.0)
	p.r("Chest", 3.0 + 1.0 * breathe, 0.0, 0.0)
	p.r("Neck", 4.0 + 4.0 * nod, 0.0, 0.0)
	p.r("Head", 10.0 + 12.0 * nod, 0.0, 5.0)
	legs(p, Vector3(7.5, ANKLE_Y, 1.5), Vector3(-7.5, ANKLE_Y, 1.5), Lib.E(0, 14, 0), Lib.E(0, -14, 0))
	for side: String in ["L", "R"]:
		var m: float = 1.0 if side == "L" else -1.0
		p.ik2("UpperArm_" + side, "LowerArm_" + side, "Hand_" + side, follow(p, "Chest", Vector3(7.0 * m, 44.0 + 0.5 * breathe, 14.0)),
			_chest_dir(p, Vector3(0.6 * m, -0.6, 0.2)))
		p.r("Fingers_" + side, -25.0, 0, -20.0 * m)
		p.r("Thumb_" + side, -10.0, 0, 0)
	p.scale_("Bow", Vector3.ONE * 0.001)
	p.scale_("Weapon_L", Vector3.ONE * 0.001)
	p.scale_("Shield", Vector3.ONE * 0.001)
	set_lids(p, 1.0)


# =============================================================== 换弹：手弩 / 双枪(45f = 1.5s；开枪最快之人的弹匣)
## 单手：枪口朝上竖到胸前、手腕一抖甩出转轮(左手托住)，左手往里按子弹(几下)，再一甩合上、放回瞄准前的握姿
func reload_crossbow(t: float, p) -> void:
	p.reset()
	var dur := 45.0 * F
	var up: float = kf_f([[0.0, 0.0], [0.18, 1.0, "o"], [1.25, 1.0], [dur, 0.0, "s"]], t)
	var flick: float = _arc(t, 0.16, 0.30, 1.0) + _arc(t, 1.18, 1.32, 1.0)
	var load: float = 0.5 + 0.5 * sin(TAU * (t - 0.35) / 0.22) if t > 0.35 and t < 1.15 else 0.0
	_twist(p, 8.0 * up, 4.0 * up, 0.0, 0.0, 0.9)
	p.radd("Head", 14.0 * up, -6.0 * up, 0.0)
	_stance_feet(p, 7.0, 1.0)
	var gv: Vector3 = XBOW_GRIP.lerp(Vector3(-5.5, 56.0, 12.5), up) + Vector3(0.0, 1.2, 0.0) * flick
	var aim: Vector3 = XBOW_AIM.lerp(Vector3(0.2, 1.0, 0.35), up)
	var cq: Quaternion = _chest_q(p)
	hold_bow(p, follow(p, "Chest", gv), cq * grot(aim, Vector3(0.0, -0.3, 1.0).lerp(Vector3(1.0, 0.0, 0.2), up)), Vector3(-1.0, -0.6, -0.2))
	fist_r(p, 82.0)
	var lt: Vector3 = Vector3(15.2, 49.0, 1.6).lerp(Vector3(0.5, 55.0 + 1.2 * load, 13.5), up)
	p.ik2("UpperArm_L", "LowerArm_L", "Hand_L", follow(p, "Chest", lt), _chest_dir(p, Vector3(0.8, -0.6, -0.3)))
	p.set_grot("Hand_L", Lib.E(-6.0, -8.0, 10.0).slerp(cq * Lib.E(60.0, -40.0, -20.0), up))
	p.r("Fingers_L", -20.0 - 30.0 * load, 0, -10.0)
	set_lids(p, 0.0)


## 双枪：两把枪口一起朝上竖起来、手腕一甩(退壳)，两手各往下一按(装弹)，再一甩放回
func reload_pistols(t: float, p) -> void:
	p.reset()
	var dur := 45.0 * F
	var up: float = kf_f([[0.0, 0.0], [0.18, 1.0, "o"], [1.25, 1.0], [dur, 0.0, "s"]], t)
	var flick: float = _arc(t, 0.16, 0.30, 1.0) + _arc(t, 1.18, 1.32, 1.0)
	var bob: float = 0.5 + 0.5 * sin(TAU * (t - 0.35) / 0.3) if t > 0.35 and t < 1.15 else 0.0
	_twist(p, 0.0, 5.0 * up, 0.0, 0.0, 0.9)
	p.radd("Head", 12.0 * up, 0.0, 0.0)
	_stance_feet(p, 7.5, 0.5)
	var cq: Quaternion = _chest_q(p)
	var gr: Vector3 = PIST_GRIP.lerp(Vector3(-8.5, 55.0 - 1.5 * bob, 11.0), up) + Vector3(0.0, 1.2, 0.0) * flick
	var gl: Vector3 = mx(PIST_GRIP).lerp(Vector3(8.5, 55.0 - 1.5 * (1.0 - bob), 11.0), up) + Vector3(0.0, 1.2, 0.0) * flick
	var ar: Vector3 = PIST_AIM.lerp(Vector3(-0.15, 1.0, 0.3), up)
	var al: Vector3 = mx(PIST_AIM).lerp(Vector3(0.15, 1.0, 0.3), up)
	var ur: Vector3 = Vector3(0.0, 1.0, 0.45).lerp(Vector3(0.6, 0.0, 1.0), up)
	var ul: Vector3 = Vector3(0.0, 1.0, 0.45).lerp(Vector3(-0.6, 0.0, 1.0), up)
	hold_bow(p, follow(p, "Chest", gr), cq * grot(ar, ur), Vector3(-1.0, -0.6, -0.2))
	fist_r(p, 82.0)
	hold_left(p, follow(p, "Chest", gl), cq * mirror_q(grot(mx(al), mx(ul))), Vector3(1.0, -0.6, -0.2))
	fist_l(p, 82.0)
	set_lids(p, 0.0)


# =============================================================== 死亡 (1.4s，不循环)
func death(t: float, p) -> void:
	p.reset()
	var jerk: float = Lib.smooth(t / 0.10) * (1.0 - Lib.smooth((t - 0.10) / 0.18))
	var f: float = Lib.smoother((t - 0.08) / 0.78)
	p.move("Hips", Vector3(0.0, -1.7 - 40.5 * f, 2.0 * jerk - 8.0 * f))
	p.r("Hips", -84.0 * f - 6.0 * jerk, 0.0, 0.0)
	p.r("Spine", -6.0 * f - 8.0 * jerk, 0.0, 0.0)
	p.r("Chest", -4.0 * f - 10.0 * jerk, 0.0, 0.0)
	p.r("Head", 14.0 * f - 12.0 * jerk, 8.0 * f, 6.0 * f)
	# 腿：膝盖弯，脚拖在身前
	p.r("Thigh_L", -8.0 * f + 20.0 * jerk, 0.0, 7.0 * f)
	p.r("Thigh_R", -26.0 * f + 20.0 * jerk, 0.0, -7.0 * f)
	p.r("Shin_L", 8.0 * f, 0.0, 0.0)
	p.r("Shin_R", 44.0 * f, 0.0, 0.0)
	p.r("Foot_L", 10.0 * f, 0.0, 0.0)
	p.r("Foot_R", -10.0 * f, 0.0, 0.0)
	# 臂：张开
	p.r("UpperArm_L", -30.0 * f - 12.0 * jerk, 0.0, 12.0 + 55.0 * f)
	p.r("UpperArm_R", -20.0 * f - 12.0 * jerk, 0.0, -12.0 - 62.0 * f)
	p.r("LowerArm_L", -18.0 * f, 0.0, 0.0)
	p.r("LowerArm_R", -34.0 * f, 0.0, 0.0)
	p.r("Fingers_L", -20.0 + 20.0 * f, 0.0, -20.0)
	p.r("Fingers_R", -30.0 * (1.0 - f), 0.0, 0.0)
	p.move("Halo", Vector3(0.0, 0.5 * sin(t * 6.0), -8.0 * f))
	p.scale_("Bow", Vector3.ONE)
	set_lids(p, Lib.smooth((t - 0.05) / 0.12))

