extends RefCounted
## 动画定义：每个动画是 fn(t, pose)，只写"主动作"；头发/流苏/裙甲的二次摆动由烘焙器统一模拟。
## 约定：角色朝 +Z；瞄准/射击方向 = +Z；右手持弓(-X 侧)，左手拉弦。
const Lib = preload("res://tools/anim_lib.gd")

var rig

# 静止姿态下的关键点(体素坐标)
const ANKLE_Y := 7.5
const BOW_GRIP_OFF := Vector3(0, -3, 2.5)        # 弓握点相对右手腕(手骨)的偏移
const NOCK_REST := Vector3(0, 0, -13.3)          # 弓坐标系中弦静止时的搭箭点
const ARROW_OFF := Vector3(2.5, 2.0, 0.3)        # 箭尾骨骼相对搭箭点(弓坐标系)的偏移
const PINCH := Vector3(1.0, -4.0, 1.5)           # 左手 Fingers 骨相对 Hand 骨的偏移(手骨系)
# 持弓待机：握点(胸腔局部，静止坐标)与弓的朝向(欧拉角，度)；archer_pose 的 raise = 0 也回到这里。
# 弓梢略前倾、弓面往外转一点(正面看得见弓臂的弧，不像拄着一根棍)，下弓梢离地
const BOW_REST_GRIP := Vector3(-16.5, 51.5, 5.5)
const BOW_REST_ROT := Vector3(12.0, -30.0, -6.0)
const BOW_RUN_GRIP := Vector3(-15.5, 52.0, 5.0)       # 跑步时提弓
const BOW_RUN_ROT := Vector3(38.0, -12.0, -8.0)
# 连射的"预备"(archer_pose 的 low = 1)：Q 版手短，弦上的搭箭点离握把 13 体素，侧身后拉弦手根本够不着搭好箭的弦(会横穿胸口)——
# 所以预备时箭不在弦上：弓压低斜握在身前右下(弓梢前倾、下弓臂往外撇)，拉弦手捏着下一支箭垂在左胯旁(= 取箭的位置)；
# 出手时弓举起来、手把箭带到弦上再拉。握点是相对"举弓未伸臂时的握点"(右肩 + (0,3,9))的世界偏移(侧身后 +Z 仍是目标方向)
const BOW_READY_GRIP := Vector3(2.0, -17.0, -2.0)
const BOW_NOCK_LIFT := 5.0                       # 搭箭(弓臂还没伸直)时弓举高一点：弦上的搭箭点在肩膀上方，拉弦手别陷进胸口；拉开后回到肩上 3 体素的箭线
const BOW_READY_ROT := Vector3(24.0, 0.0, 18.0)
const BOW_READY_LEAN := 3.0                      # 预备时上身略前倾(度)
const BOW_READY_POLE := Vector3(-1.0, -0.3, -0.5)      # 预备时持弓肘往外后
const BOW_READY_POLE_L := Vector3(0.8, -0.3, -0.7)     # 拉弦手垂在胯旁时肘往外后
const BOW_PLUCK_POLE_MID := Vector3(-0.52, -0.8, -0.3)  # 拉弦手横过胸前上弦 / 放箭后下去取箭的途中：肘往下后(这时"肩→手"是身体的左右方向，肘只能在下 / 后 / 上里转)
const BOW_DROP_VIA := Vector3(14.5, 47.0, -6.5)         # 放箭后拉弦手甩下来途经的腰后外侧(骨盆局部，静止坐标)
const BOW_DROP_POLE := Vector3(0.1, 0.1, -1.0)          # 那一路上肘一直朝外后(侧身后世界的 -Z ≈ 身体左外侧)
const BOW_PLUCK_AT := Vector3(13.5, 45.0, 3.0)         # 取箭 / 预备时捏着箭的手(静止坐标，跟骨盆走：左胯前侧)
const BOW_NOCK_VIA := Vector3(-1.0, 63.0, 15.0)          # 上弦途中手经过的上胸正前方(胸腔局部，静止坐标)
const BOW_HAND_ARROW := Vector3(0.3, -0.8, 0.5)        # 捏在手里的箭：箭头朝前下、略往外(世界方向，侧身后 +X = 身前)，别戳到腿

var last_release_arrow: Vector3 = Vector3.ZERO   # archer_pose 输出：箭尾世界位置
var last_bow_g: Quaternion = Quaternion.IDENTITY


## 男性款姿态开关(anim_chars 把每个 idle/run 再烘一份 *_m 时打开)：站得更开、没有扭胯、肩膀往后、手离身体远一点、跑得更"冲"
var male := false


func _init(p_rig) -> void:
	rig = p_rig


## 男性款系数(0 或 1)，用来在女性款的数值上叠加差值
func mk() -> float:
	return 1.0 if male else 0.0


func table() -> Dictionary:
	return {
		"idle": {"dur": 3.2, "loop": true, "fn": Callable(self, "idle")},
		"walk": {"dur": 1.0, "loop": true, "fn": Callable(self, "walk")},
		"run": {"dur": 20.0 / 30.0, "loop": true, "fn": Callable(self, "run")},
		"aim": {"dur": 2.4, "loop": true, "fn": Callable(self, "aim_hold")},
		"shoot": {"dur": 3.5, "loop": false, "fn": Callable(self, "shoot")},
		"jump": {"dur": 1.3, "loop": false, "fn": Callable(self, "jump")},
		"showcase": {"dur": 4.0, "loop": true, "fn": Callable(self, "showcase")},
		"apose": {"dur": 2.0, "loop": true, "fn": Callable(self, "apose")},
	}


# =============================================================== 通用小工具
## 把"静止空间里的点"绑定到某骨骼上，返回它在当前姿态的世界位置
func follow(p, bone: String, rest_pt: Vector3) -> Vector3:
	p.fk()
	var i: int = rig.ids[bone]
	return p.gx[i] * (rest_pt - rig.pos[i])


func set_lids(p, k: float) -> void:
	for s in ["L", "R"]:
		var nm: String = "Eyelid_" + s
		p.scale_(nm, Vector3(1, maxf(k, 0.001), 1))
		p.move(nm, Vector3(0, 0, 3.2 if k > 0.02 else 0.0))


func blink_k(t: float, t0: float) -> float:
	var d := t - t0
	if d < 0.0 or d > 0.22:
		return 0.0
	if d < 0.06:
		return d / 0.06
	if d < 0.11:
		return 1.0
	return 1.0 - (d - 0.11) / 0.11


## 双腿 IK：膝盖朝向 = 脚的朝向
func legs(p, lpos: Vector3, rpos: Vector3, lrot: Quaternion, rrot: Quaternion, ltoe: float = 0.0, rtoe: float = 0.0) -> void:
	var fl: Vector3 = lrot * Vector3(0, 0, 1)
	var fr: Vector3 = rrot * Vector3(0, 0, 1)
	fl.y = 0.0
	fr.y = 0.0
	p.ik2("Thigh_L", "Shin_L", "Foot_L", lpos, fl.normalized() + Vector3(0.05, 0, 0))
	p.set_grot("Foot_L", lrot)
	p.r("Toe_L", ltoe)
	p.ik2("Thigh_R", "Shin_R", "Foot_R", rpos, fr.normalized() + Vector3(-0.05, 0, 0))
	p.set_grot("Foot_R", rrot)
	p.r("Toe_R", rtoe)


## 右手持弓：grip 为握点世界位置，bow_rot 为弓的世界朝向
func hold_bow(p, grip: Vector3, bow_rot: Quaternion, pole: Vector3) -> void:
	var w: Vector3 = grip - bow_rot * BOW_GRIP_OFF
	p.ik2("UpperArm_R", "LowerArm_R", "Hand_R", w, pole)
	p.set_grot("Hand_R", bow_rot)


func fist_r(p, curl: float) -> void:
	p.r("Fingers_R", -curl, 0, 0)
	p.r("Thumb_R", -curl * 0.35, 0, 0)


func left_relaxed(p, target: Vector3, rot: Quaternion, curl: float = 14.0) -> void:
	p.ik2("UpperArm_L", "LowerArm_L", "Hand_L", target, Vector3(0.6, -0.2, -1.0))
	p.set_grot("Hand_L", rot)
	p.r("Fingers_L", -curl, 0, -22.0)
	p.r("Thumb_L", -10.0, 0, 0)


# =============================================================== IDLE (3.2s)
func idle(t: float, p) -> void:
	var T := 3.2
	var th := TAU * t / T
	var s1 := sin(th)
	var s2 := sin(2.0 * th)
	p.reset()
	# ---- 骨盆/脊柱：呼吸 + 重心转移
	var m := mk()
	p.move("Hips", Vector3(0.9 * s1 * (1.0 - 0.75 * m), -1.7 + 0.3 * s2, 0.0))
	p.r("Hips", 0.0, 2.5 * s1 * (1.0 - 0.5 * m), 1.6 * s1 * (1.0 - 0.8 * m))
	p.r("Spine", -0.8 * s2 - 0.8, -1.5 * s1, -1.0 * s1)
	p.r("Chest", -1.6 * (0.5 + 0.5 * sin(th - 1.2)) + 0.6 - 1.8 * m, -1.5 * s1, -0.8 * s1)
	p.r("Neck", 1.0 * s1, 0.0, 0.0)
	p.r("Shoulder_L", 0, 4.0 * m, 1.4 * sin(th - 1.2) - 1.5 * m)
	p.r("Shoulder_R", 0, -4.0 * m, -1.4 * sin(th - 1.2) + 1.5 * m)
	p.r("Head", 1.5 * s2 + 1.0, 5.0 * sin(th + 0.4) * (1.0 - 0.4 * m), 2.2 * sin(th + 1.0) * (1.0 - 0.6 * m))
	# ---- 脚(固定在地面)；男性款站得更开、脚尖更外八
	legs(p, Vector3(6.5 + 2.6 * m, ANKLE_Y, -0.5), Vector3(-6.5 - 2.6 * m, ANKLE_Y, -0.5), Lib.E(0, 6.0 + 7.0 * m, 0), Lib.E(0, -6.0 - 7.0 * m, 0))
	_arms_idle(p, s1, th)
	# ---- 配饰：光环漂浮、齿轮缓转、眨眼
	p.move("Halo", Vector3(0, 0.9 * sin(2.0 * th), 0))
	p.r("Halo", 2.0 * sin(th), 0.0, 2.5 * sin(2.0 * th + 0.7))
	p.r("Bow_Gear", 360.0 * t / T, 0, 0)
	set_lids(p, blink_k(t, 2.05))


# =============================================================== 手臂钩子：默认是"持弓"姿态；剑/盾/杖套件在子类里覆盖
func _arms_idle(p, s1: float, th: float) -> void:
	var m := mk()
	var bow_rot := Lib.E(BOW_REST_ROT.x + 1.0 * s1, BOW_REST_ROT.y, BOW_REST_ROT.z)
	var grip := follow(p, "Chest", BOW_REST_GRIP + Vector3(-1.2 * m, 0.4 * s1, 0.8 * m))
	hold_bow(p, grip, bow_rot, Vector3(-0.5, -0.3, -1.0))
	fist_r(p, 75.0)
	relax_l(p, s1)


## 左手自然下垂(待机)；男性款手离身体远一点、手腕不翘、半握拳
func relax_l(p, s1: float) -> void:
	var m := mk()
	left_relaxed(p, follow(p, "Chest", Vector3(15.2 + 2.6 * m, 49.0 + 0.3 * s1 + 0.5 * m, 1.6 + 1.8 * m)),
		Lib.E(-6.0 + 2.0 * m, -8.0 + 5.0 * m, 10.0 + 2.0 * s1 - 7.0 * m), 14.0 - 3.0 * s1 + 22.0 * m)


func _arms_run(p, s: float, th: float) -> void:
	var m := mk()
	p.r("UpperArm_L", (28.0 + 8.0 * m) * s - 3.0, 0, 9.0 + 3.0 * m)
	p.r("LowerArm_L", -(48.0 + 16.0 * (0.5 - 0.5 * s)) - 10.0 * m, 0, 0)
	p.r("Hand_L", -8.0, 0, 0)
	p.r("Fingers_L", -50.0 - 30.0 * m, 0, -18.0)
	p.r("Thumb_L", -10.0, 0, 0)
	# 弓梢朝前上、横着提在身侧(竖着拿的话下弓梢会扫到迈出去的腿)，下弓臂往外撇
	var bow_rot := Lib.E(BOW_RUN_ROT.x + 6.0 * s, BOW_RUN_ROT.y, BOW_RUN_ROT.z)
	var grip := follow(p, "Chest", BOW_RUN_GRIP + Vector3(-1.0 * m, 1.0 * sin(2.0 * th), -4.0 * s))
	hold_bow(p, grip, bow_rot, Vector3(-0.6, -0.2, -1.0))
	fist_r(p, 78.0)


# =============================================================== WALK (1.0s)
## 脚的轨迹：phi 0..1；返回 [dz, lift, pitch(度,正=脚尖下压)]
func foot_track(phi: float, stride: float, lift: float, stance: float) -> Array:
	var dz := 0.0
	var ly := 0.0
	var pitch := 0.0
	if phi < stance:
		var s := phi / stance
		dz = lerpf(stride, -stride, s)
		pitch = -16.0 * pow(1.0 - clampf(s / 0.22, 0.0, 1.0), 2.0) + 34.0 * Lib.smooth((s - 0.62) / 0.38)
	else:
		var s2 := (phi - stance) / (1.0 - stance)
		dz = lerpf(-stride, stride, Lib.smoother(s2))
		ly = lift * pow(sin(PI * s2), 0.85)
		pitch = lerpf(34.0, -16.0, Lib.smooth(s2 * 1.25))
	return [dz, ly, pitch]


func foot_target(side: float, ft: Array, half_w: float) -> Vector3:
	var pit := sin(deg_to_rad(maxf(float(ft[2]), 0.0)))
	return Vector3(side * half_w, ANKLE_Y + float(ft[1]) + 3.4 * pit, float(ft[0]) - 0.5 - 1.6 * pit)


func walk(t: float, p) -> void:
	var T := 1.0
	var ph := fposmod(t / T, 1.0)
	var th := TAU * ph
	p.reset()
	var fl: Array = foot_track(ph, 10.0, 6.5, 0.6)
	var fr: Array = foot_track(fposmod(ph + 0.5, 1.0), 10.0, 6.5, 0.6)
	var bob := 1.3 * cos(2.0 * TAU * (ph - 0.3))
	p.move("Hips", Vector3(1.5 * sin(th), -3.0 + bob, 0.0))
	p.r("Hips", 1.5 * sin(2.0 * th + 0.3) + 2.0, -6.5 * cos(th), 2.6 * sin(th))
	p.r("Spine", 1.0, 3.5 * cos(th), -1.6 * sin(th))
	p.r("Chest", 2.0 * sin(2.0 * th + 0.3), 4.5 * cos(th), -1.2 * sin(th))
	p.r("Head", 2.0 - 1.5 * sin(2.0 * th + 0.3), -3.0 * cos(th), 2.0 * sin(th))
	legs(p, foot_target(1.0, fl, 6.2), foot_target(-1.0, fr, 6.2), Lib.E(fl[2], 4.0, 0), Lib.E(fr[2], -4.0, 0),
		-0.7 * maxf(float(fl[2]), 0.0), -0.7 * maxf(float(fr[2]), 0.0))
	var s := cos(th)
	p.r("UpperArm_L", 20.0 * s - 4.0, 0, 6.0)
	p.r("LowerArm_L", -(16.0 + 12.0 * (0.5 - 0.5 * s)), 0, 0)
	p.r("Hand_L", -6.0, 0, 0)
	p.r("Fingers_L", -14.0, 0, -22.0)
	p.r("Thumb_L", -10.0, 0, 0)
	var bow_rot := Lib.E(-8.0 + 4.0 * s, 0.0, -3.5)
	var grip := follow(p, "Chest", Vector3(-16.0, 51.0 + 0.6 * sin(2.0 * th), 5.0 - 2.0 * s))
	hold_bow(p, grip, bow_rot, Vector3(-0.5, -0.3, -1.0))
	fist_r(p, 75.0)
	p.move("Halo", Vector3(0, 0.6 * sin(2.0 * th - 0.8), 0))
	p.r("Halo", 3.0 * sin(2.0 * th), 0.0, 3.0 * sin(th))
	p.r("Bow_Gear", 360.0 * t / T, 0, 0)
	set_lids(p, blink_k(t, 0.62))


# =============================================================== RUN (20 帧 = 0.667s)
func run(t: float, p) -> void:
	var T := 20.0 / 30.0
	var ph := fposmod(t / T, 1.0)
	var th := TAU * ph
	p.reset()
	var fl: Array = foot_track(ph, 15.0, 13.0, 0.38)
	var fr: Array = foot_track(fposmod(ph + 0.5, 1.0), 15.0, 13.0, 0.38)
	var bob := 3.2 * absf(sin(th))
	var m := mk()
	# 男性款：胯几乎不左右扭、上身前冲更多、肩膀转得更大、脚距更宽
	p.move("Hips", Vector3(1.2 * sin(th) * (1.0 - 0.6 * m), -7.0 + bob, 1.5))
	p.r("Hips", 9.0 + 2.0 * sin(2.0 * th) + 2.0 * m, -9.0 * cos(th), 3.2 * sin(th) * (1.0 - 0.6 * m))
	p.r("Spine", 3.0 + 1.5 * m, 5.0 * cos(th), -2.0 * sin(th) * (1.0 - 0.5 * m))
	p.r("Chest", 3.0 + 1.5 * sin(2.0 * th + 0.4) + 1.5 * m, (6.5 + 2.5 * m) * cos(th), -1.5 * sin(th))
	p.r("Head", -9.0 - 2.0 * sin(2.0 * th) - 3.0 * m, -4.0 * cos(th), 2.0 * sin(th) * (1.0 - 0.6 * m))
	legs(p, foot_target(1.0, fl, 6.0 + 1.2 * m), foot_target(-1.0, fr, 6.0 + 1.2 * m), Lib.E(fl[2], 3.0 + 5.0 * m, 0), Lib.E(fr[2], -3.0 - 5.0 * m, 0),
		-0.6 * maxf(float(fl[2]), 0.0), -0.6 * maxf(float(fr[2]), 0.0))
	_arms_run(p, cos(th), th)
	p.move("Halo", Vector3(0, 1.0 * sin(2.0 * th - 0.8), 0))
	p.r("Halo", 5.0 * sin(2.0 * th), 0.0, 4.0 * sin(th))
	p.r("Bow_Gear", 360.0 * t / T, 0, 0)
	set_lids(p, 0.0)


# =============================================================== 弓术核心姿态
## raise 0..1  举弓/侧身程度
## draw  0..1  弦(搭箭点)的拉开程度
## hand  0..1  左手勾在弦上的程度(释放后逐渐放松)
## hand_back  释放后左手向后甩的距离
## arrow_vis  箭的可见度(0=隐藏)
## ex(可选)：deep 0..1 在满弦上再往后拉到耳边的程度(吟唱蓄力) · strain 0..1 身体用力(沉胯、挺胸、歪头)
##           shake_bow / shake_hand 弓手 / 拉弦手的颤抖位移(世界，体素) · pitch / cant 弓身前倾 / 侧滚(度)
##           splay 0..1 放箭后拉弦手张开 · back_up 放箭后拉弦手甩开时往上抬的比例
##           stance 0..1 上身侧过去的程度(默认 = raise) · feet 0..1 脚踩成侧身步的程度(默认 = stance；连射时脚一直不动)
##           low 0..1 "预备"：弓压低到腹前、弓梢前倾、箭搭在弦上斜指前下方，拉弦手勾着弦垂在腹前(连射的两箭之间)
##           pluck 0..1 拉弦手下去胯旁取箭 · arrow_hand 0..1 箭在拉弦手里(取箭后带回弦上的途中；0 = 搭在弦上)
func archer_pose(p, raise: float, draw: float, hand: float, hand_back: float, tt: float, tremble: float, recoil: float, arrow_vis: float, ext: float = -1.0,
		ex: Dictionary = {}) -> void:
	var st: float = float(ex.get("stance", raise))
	var ft: float = float(ex.get("feet", st))
	var low: float = float(ex.get("low", 0.0))
	var yaw := 66.0 * st
	var deep: float = float(ex.get("deep", 0.0))
	var strain: float = float(ex.get("strain", 0.0))
	p.move("Hips", Vector3(0.0, -1.7 - 3.4 * ft - 1.6 * strain, -1.5 * ft - recoil * 1.5 - 0.8 * strain))
	p.r("Hips", 0.0, yaw * 0.42, 0.0)
	p.r("Spine", -1.5 * strain, yaw * 0.28, 0.0)
	p.r("Chest", -2.0 * draw * raise + recoil * 4.0 - 3.5 * strain + BOW_READY_LEAN * low, yaw * 0.30, 0.0)
	p.r("Neck", 0.0, -yaw * 0.30, 0.0)
	# ---- 站姿：双脚沿 Z 轴一前一后(右脚在前，脚尖朝 +X)
	var fw := 9.0 * ft
	var lrot: Quaternion = Lib.E(0, lerpf(6.0, 84.0, ft), 0)
	var rrot: Quaternion = Lib.E(0, lerpf(-6.0, 80.0, ft), 0)
	legs(p, Vector3(lerpf(6.5, 1.5, ft), ANKLE_Y, lerpf(-0.5, -fw, ft)), Vector3(lerpf(-6.5, -1.5, ft), ANKLE_Y, lerpf(-0.5, fw, ft)), lrot, rrot)
	# ---- 头：世界朝向对准 +Z，歪头贴弦；预备时略低头看前方地面
	p.set_grot("Head", Lib.E(2.0 * st + 2.0 * strain + 5.0 * low, 0.0, -5.0 * draw * raise - 3.0 * strain + 1.2 * sin(tt) * tremble))
	# ---- 右臂：持弓前伸
	p.fk()
	var sh_r: Vector3 = p.gpos_n("UpperArm_R")
	# 弓臂随拉弦逐渐伸直(搭箭时弓离身体近，左手才够得到弦)
	if ext < 0.0:
		ext = Lib.smooth(draw * 1.15)
	var aim_grip := sh_r + Vector3(0.0, 3.0 + BOW_NOCK_LIFT * (1.0 - ext), lerpf(9.0, 20.6, ext)) + BOW_READY_GRIP * low
	var idle_grip := follow(p, "Chest", BOW_REST_GRIP)
	var wob := Vector3(0.25 * sin(tt), 0.2 * sin(tt * 0.5 + 1.0), 0.0) * tremble
	var grip: Vector3 = idle_grip.lerp(aim_grip + wob + Vector3(0.0, 0.6 * strain, 0.8 * strain), Lib.smooth(raise)) + (ex.get("shake_bow", Vector3.ZERO) as Vector3)
	var rest_rot: Quaternion = Lib.E(BOW_REST_ROT.x, BOW_REST_ROT.y, BOW_REST_ROT.z)
	var aim_rot: Quaternion = Lib.E(BOW_READY_ROT.x * low, BOW_READY_ROT.y * low, -3.0 + (BOW_READY_ROT.z + 3.0) * low)
	var bow_rot: Quaternion = Lib.E(float(ex.get("pitch", 0.0)), 0.0, float(ex.get("cant", 0.0))) * rest_rot.slerp(aim_rot, raise)
	hold_bow(p, grip, bow_rot, Vector3(-1.0, 0.7, -0.6).lerp(BOW_READY_POLE, low))
	fist_r(p, 78.0)
	# ---- 弓弦搭箭点
	var bow_o: Vector3 = p.gpos_n("Bow")
	var bow_g: Quaternion = p.grot_n("Bow")
	var nock_rest_w: Vector3 = bow_o + bow_g * NOCK_REST
	# 锚点：与箭线同高同 x，落在下颌下方
	var head_p: Vector3 = p.gpos_n("Head")
	var anchor := Vector3(grip.x, grip.y, head_p.z + 3.0) + Vector3(-0.8 * deep, 1.4 * deep, -4.2 * deep) + (ex.get("shake_hand", Vector3.ZERO) as Vector3)
	var nock_w: Vector3 = nock_rest_w.lerp(anchor, draw)
	p.move("Bow_Nock", bow_g.inverse() * (nock_w - bow_o) - NOCK_REST)
	# ---- 左手：先靠近弦，再勾弦拉开
	var hq: Quaternion = Lib.basis_zy(Vector3(1, 0, 0), Vector3(0, 0, -1))
	var pinch_w: Vector3 = hq * PINCH
	var wl_idle := follow(p, "Chest", Vector3(15.2, 48.5, 1.6))
	var wl_ready: Vector3 = nock_rest_w - pinch_w
	var wl_anchor: Vector3 = anchor - pinch_w + Vector3(0.0, hand_back * float(ex.get("back_up", 0.0)), -hand_back)
	var pre := Lib.smooth(raise * 1.25)
	var wl: Vector3 = wl_idle.lerp(wl_ready, pre)
	wl = wl.lerp(wl_anchor, hand)
	# 取箭：手垂到左胯旁(箭从那里抽出来)，再带回弦上
	var pluck: float = float(ex.get("pluck", 0.0))
	var via: bool = ex.has("via")
	if pluck > 0.0:
		# 胯旁 ↔ 弦之间走直线会穿过身体，所以走一条经过 via 的二次贝塞尔曲线(pluck = 0.5 时正好在 via)：
		#   上弦(默认)：经过上胸正前方 —— 先把箭举到胸前，再送到右肩上方的弦上
		#   放箭后(via = 腰后外侧)：手在左肩后上方，肩膀正好挡在"锚点 → 胯旁"的直线上 —— 先往下甩到腰后外侧(像去背后箭袋抽箭)，再顺着胯外侧带到身前
		var tgt: Vector3 = follow(p, "Hips", BOW_PLUCK_AT) - pinch_w
		var wv: Vector3 = (follow(p, "Hips", ex["via"]) if via else follow(p, "Chest", BOW_NOCK_VIA)) - pinch_w
		var c: Vector3 = 2.0 * wv - 0.5 * (wl + tgt)
		wl = wl * ((1.0 - pluck) * (1.0 - pluck)) + c * (2.0 * pluck * (1.0 - pluck)) + tgt * (pluck * pluck)
	var pole_l: Vector3 = Vector3(0.1, 0.5, -1.0).lerp(Vector3(0.0, 1.0, -0.55), deep)      # 拉到耳边时拉弦肘抬高
	if ex.has("pluck"):
		# 连射(手在胯旁 ↔ 弦之间来回)：肘的朝向跟着手的进度走一条连续的路，起点 = 拉弦的肘(上后)、终点 = 胯旁(外后下)；
		# 直接在两个 pole 之间按权重插值的话，手一换方向"肩→手"的轴扫过 pole，肘会一帧整个翻过去。
		# 上弦途中手横过胸前("肩→手"是身体的左右方向)，肘只能往下后；放箭后手从肩后甩下来，肘一直朝外
		var kp: float = clampf(pluck, 0.0, 1.0)
		var pm: Vector3 = (BOW_DROP_POLE if via else BOW_PLUCK_POLE_MID).normalized()
		pole_l = pm.slerp(pole_l.normalized(), 1.0 - 2.0 * kp) if kp < 0.5 else pm.slerp(BOW_READY_POLE_L.normalized(), 2.0 * kp - 1.0)
	p.ik2("UpperArm_L", "LowerArm_L", "Hand_L", wl, pole_l)
	var hand_rest_q: Quaternion = Lib.E(-6.0, -8.0, 10.0)
	p.set_grot("Hand_L", hand_rest_q.slerp(hq, pre).slerp(hand_rest_q, pluck * 0.6))
	var splay: float = float(ex.get("splay", 0.0))
	p.r("Fingers_L", lerpf(lerpf(-14.0, -80.0, pre), -6.0, splay), 0, lerpf(-22.0, 0.0, pre) - 10.0 * splay)
	p.r("Thumb_L", lerpf(lerpf(-10.0, -50.0, pre), 10.0, splay), 0, 0)
	# ---- 弓臂弯曲(随弦拉开；拉到耳边时弯得更狠)
	var bend: float = draw * (1.0 + 0.55 * deep)
	p.r("Bow_U1", -3.0 * bend, 0, 0)
	p.r("Bow_U2", -7.0 * bend, 0, 0)
	p.r("Bow_D1", 3.0 * bend, 0, 0)
	p.r("Bow_D2", 7.0 * bend, 0, 0)
	# ---- 箭
	var arrow_w: Vector3 = nock_w + bow_g * ARROW_OFF
	var arrow_q: Quaternion = bow_g
	var a_hand: float = float(ex.get("arrow_hand", 0.0))
	if a_hand > 0.0:
		p.fk()
		arrow_q = bow_g.slerp(Lib.basis_zy(BOW_HAND_ARROW, Vector3(0.0, 1.0, 0.0).lerp(Vector3(-1.0, 0.0, 0.0), 0.5)), a_hand)
		arrow_w = arrow_w.lerp(p.gpos_n("Hand_L") + pinch_w + arrow_q * ARROW_OFF, a_hand)
	last_release_arrow = anchor + bow_g * ARROW_OFF
	last_bow_g = bow_g
	if arrow_vis > 0.001:
		p.set_gpos_via_off("Arrow", arrow_w)
		p.rq("Arrow", arrow_q)
		p.scale_("Arrow", Vector3.ONE * arrow_vis)
	else:
		p.scale_("Arrow", Vector3.ONE * 0.001)
	p.move("Halo", Vector3(0, 0.6 * sin(tt * 0.5), 0))
	p.r("Halo", 2.0, 0.0, 2.0 * sin(tt * 0.5))


func aim_hold(t: float, p) -> void:
	var T := 2.4
	var th := TAU * t / T
	p.reset()
	archer_pose(p, 1.0, 1.0, 1.0, 0.0, th * 2.0, 1.0, 0.0, 1.0, 1.0)
	p.radd("Chest", 0.5 * sin(th), 0, 0)
	p.r("Bow_Gear", 360.0 * t / T, 0, 0)
	set_lids(p, blink_k(t, 1.5))


# =============================================================== SHOOT (3.2s，不循环)
## 0.00-0.70 举弓 / 0.60-1.45 搭箭拉满 / 1.45-2.00 屏息 / 2.00 释放 / 2.30-3.25 收势
func shoot(t: float, p) -> void:
	p.reset()
	var TR := 2.0                                   # 释放时刻
	var raise := Lib.smooth(t / 0.7)
	var pull := Lib.smoother((t - 0.6) / 0.85)      # 拉弦进度(0..1)，1.45s 拉满
	var draw := pull
	var hand := pull
	var hand_back := 0.0
	var recoil := 0.0
	var vis := 1.0 if t > 0.55 else 0.0
	var trem := 0.6 * Lib.smooth((t - 1.35) / 0.55)
	var rt := t - TR
	if t >= TR:
		draw = maxf(0.0, 1.0 - rt / 0.045)
		recoil = exp(-rt * 6.0) * cos(rt * 26.0)
		vis = 0.0
		trem = 0.0
		hand_back = 7.0 * (1.0 - exp(-rt * 30.0)) * exp(-rt * 4.5)
		hand = exp(-maxf(rt - 0.1, 0.0) * 5.0)
		raise = 1.0 - Lib.smooth((t - 2.3) / 0.95)
	archer_pose(p, raise, draw, hand, hand_back, t * 40.0, trem, recoil, vis, Lib.smooth(pull * 1.15))
	if t >= TR:
		# 弓臂/弦：释放瞬间反弹并衰减振动
		var k := exp(-rt * 7.0) * sin(rt * 32.0)
		p.radd("Bow_U1", 3.0 * k, 0, 0)
		p.radd("Bow_U2", 7.0 * k, 0, 0)
		p.radd("Bow_D1", -3.0 * k, 0, 0)
		p.radd("Bow_D2", -7.0 * k, 0, 0)
		p.madd("Bow_Nock", Vector3(0, 0, 3.0 * exp(-rt * 9.0) * sin(rt * 55.0)))
		# 飞出的箭：沿 +Z 直线飞行
		if rt < 0.6:
			var tmp = Lib.Pose.new(rig)
			archer_pose(tmp, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0)
			var start: Vector3 = last_release_arrow
			p.set_gpos_via_off("Arrow", start + Vector3(0, 0, rt * 700.0))
			p.rq("Arrow", Quaternion.IDENTITY)
			p.scale_("Arrow", Vector3.ONE)
	set_lids(p, blink_k(t, 2.95))
	p.r("Bow_Gear", 200.0 * t, 0, 0)


# =============================================================== JUMP (1.3s，不循环)
## 0-0.25 下蹲蓄力 / 0.25-0.33 蹬地 / 0.33-0.85 滞空 / 0.85-1.05 落地缓冲 / 至 1.3 起身
func jump(t: float, p) -> void:
	p.reset()
	var crouch := Lib.smooth(t / 0.25) - Lib.smooth((t - 0.25) / 0.08)
	var air := Lib.smooth((t - 0.25) / 0.1) - Lib.smooth((t - 0.78) / 0.09)          # 腿：起跳收起，落地前伸直
	var arms := Lib.smooth((t - 0.25) / 0.2) - Lib.smooth((t - 0.8) / 0.2)           # 手臂：慢起慢落
	var land := Lib.smooth((t - 0.84) / 0.06) - Lib.smooth((t - 1.0) / 0.3)
	var h := 0.0
	if t > 0.3 and t < 0.87:
		var u := (t - 0.3) / 0.57
		h = 4.0 * u * (1.0 - u) * 30.0
	p.move("Root", Vector3(0, h, 0))
	p.move("Hips", Vector3(0, -12.0 * crouch - 9.0 * land, -3.0 * crouch - 2.0 * land))
	p.r("Hips", 22.0 * crouch + 14.0 * land - 8.0 * air, 0, 0)
	p.r("Spine", 8.0 * crouch + 6.0 * land, 0, 0)
	p.r("Chest", 6.0 * crouch - 4.0 * air, 0, 0)
	p.r("Head", -14.0 * crouch - 6.0 * land + 6.0 * air, 0, 0)
	# 脚(世界坐标)：蓄力/落地踩地，滞空时收腿(屈膝，脚略后)
	var lp := Vector3(6.5, ANKLE_Y + h + 11.0 * air, -0.5 - 6.0 * air)
	var rp := Vector3(-6.5, ANKLE_Y + h + 9.0 * air, -0.5 + 5.0 * air)
	var pitch := 22.0 * crouch + 6.0 * air
	legs(p, lp, rp, Lib.E(pitch, 6, 0), Lib.E(pitch, -6, 0))
	# 手臂：蓄力后摆，空中张开上举
	p.r("UpperArm_L", 30.0 * crouch - 60.0 * arms, 0, 10.0 + 55.0 * arms)
	p.r("LowerArm_L", -25.0 * crouch - 20.0 * arms, 0, 0)
	p.r("Fingers_L", -20.0, 0, -20.0)
	var bow_rot := Lib.E(-10.0 - 20.0 * arms, 0.0, -3.5)
	var grip := follow(p, "Chest", Vector3(-16.0 - 8.0 * arms, 50.0 + 6.0 * arms, 4.5))
	hold_bow(p, grip, bow_rot, Vector3(-0.5, -0.3, -1.0))
	fist_r(p, 75.0)
	p.move("Halo", Vector3(0, 2.0 * air, 0))
	p.r("Bow_Gear", 200.0 * t, 0, 0)
	set_lids(p, 0.0)


# =============================================================== SHOWCASE (4.0s 循环)：示例卡同款展示姿势
## 右臂向体侧平伸持弓(弓面朝向观众，弦朝身体)，左臂自然下垂
func showcase(t: float, p) -> void:
	var T := 4.0
	var th := TAU * t / T
	var s1 := sin(th)
	p.reset()
	p.move("Hips", Vector3(0.6 * s1, -2.2 + 0.25 * sin(2.0 * th), 0.0))
	p.r("Hips", 0.0, -8.0 + 1.5 * s1, 1.8 * s1)
	p.r("Spine", 0.0, -5.0, -1.2 * s1)
	p.r("Chest", -1.0 + 0.8 * sin(th - 1.0), -8.0, 0.0)
	p.r("Head", 1.0, 16.0 + 2.0 * s1, 3.0 - 1.5 * s1)
	legs(p, Vector3(7.0, ANKLE_Y, 3.5), Vector3(-6.0, ANKLE_Y, -3.5), Lib.E(0, 14, 0), Lib.E(0, -10, 0))
	var bow_rot: Quaternion = Lib.E(0.0, -90.0, 0.0) * Lib.E(0.0, 0.0, -6.0 + 2.0 * s1)
	p.fk()
	var sh_r: Vector3 = p.gpos_n("UpperArm_R")
	var grip := sh_r + Vector3(-18.0, -5.0 + 0.8 * s1, 8.0)
	hold_bow(p, grip, bow_rot, Vector3(-0.2, -0.6, -1.0))
	fist_r(p, 78.0)
	left_relaxed(p, follow(p, "Chest", Vector3(16.0, 49.0 + 0.3 * s1, 1.0)), Lib.E(-4.0, -6.0, 12.0), 10.0)
	p.move("Halo", Vector3(0, 1.0 * sin(2.0 * th), 0))
	p.r("Halo", 2.5, 0.0, 3.0 * sin(th))
	p.r("Bow_Gear", 360.0 * t / T, 0, 0)
	set_lids(p, blink_k(t, 2.6))


# =============================================================== APOSE：转面图用静止 A 字站姿(弓收起)，头发/流苏仍有轻微飘动
func apose(t: float, p) -> void:
	var th := TAU * t / 2.0
	p.reset()
	p.move("Hips", Vector3(0, -0.8, 0))
	p.r("Chest", -0.6 * sin(th), 0, 0)
	p.r("Head", 0.6 * sin(th), 0, 0)
	legs(p, Vector3(5.8, ANKLE_Y, -0.5), Vector3(-5.8, ANKLE_Y, -0.5), Lib.E(0, 3.0, 0), Lib.E(0, -3.0, 0))
	p.move("Halo", Vector3(0, 0.7 * sin(th), 0))
	p.scale_("Bow", Vector3.ONE * 0.001)
	set_lids(p, 0.0)
