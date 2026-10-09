extends "res://tools/chars/_ember.gd"
## 愤怒的余烬(Ember Wrath)：魁梧的熔岩人形——高高的尖兜帽、帽尖往前弯成一只角，兜帽下面是空洞的黑脸和一只发光的眼；
## 带尖刺的肩甲，胸口一颗发光的星形熔核，浑身熔岩裂纹；腰上一圈破烂的棕色缠腰布；三趾利爪的脚；右手托着一大团火(法器，武器不显示)。
## 身份(俯视的战斗镜头里认它)：猩红的烈火、白热的芯，裂纹密；手里一大团红火 + 兜帽尖角(角尖在烧)。
## 挂骨照人形骨骼(和通用身体同一套关节)，动作用法器的待机/跑/施法(男性款站姿)。

const MALE := true
const IDENTITY := {"rim": "#ff2a36", "rim_k": 0.2, "pulse": 0.7}


func build() -> void:
	ember_init("wrath")
	var bf := Callable(self, "basalt")
	g.sym = false
	# ---------------------------------------------------------------- 躯干
	g.use("Hips")
	g.sq(0.0, 45.0, 0.0, 11.0, 6.0, 7.0, bf, 2.6)
	g.use("Spine")
	g.ytaper(50, 57, 0.0, 0.0, 9.0, 6.6, 0.0, 0.5, 11.0, 7.4, bf, 2.4)
	g.use("Chest")
	g.ytaper(58, 70, 0.0, 0.5, 12.0, 8.0, 0.0, 0.0, 13.5, 7.6, bf, 2.6)
	# 胸前的熔核(星形)：中心一团最亮，往外八个方向的光芒
	hot_sq(0.0, 64.0, 7.6, 3.2, 3.2, 1.6, 2.0)
	var sg: int = g.cur_glow
	for k in range(8):
		var a: float = float(k) * TAU / 8.0
		var ln: float = 8.0 if k % 2 == 0 else 5.0
		for s in range(3, int(ln)):
			var px: int = int(round(cos(a) * float(s)))
			var py: int = int(round(sin(a) * float(s)))
			g.cur_glow = 130 - s * 10
			g.put(px, 64 + py, 7 + (1 if s < 4 else 0), L2 if s < 5 else L1)
	g.cur_glow = sg
	g.use("Neck")
	g.ytaper(69, 74, 0.0, -1.0, 4.5, 4.0, 0.0, -1.0, 4.0, 3.6, bf, 2.4)
	# ---------------------------------------------------------------- 肩甲 + 手臂 + 腿(左右对称)
	g.sym = true
	g.use("Shoulder_L")
	g.sq(13.0, 69.0, 0.0, 6.5, 4.5, 6.8, bf, 2.2)
	g.seg(Vector3(12.0, 72.0, 2.0), Vector3(15.0, 80.0, 4.0), 1.8, 0.5, bf)
	g.seg(Vector3(16.0, 70.0, -3.0), Vector3(21.0, 76.0, -6.0), 1.7, 0.5, bf)
	g.seg(Vector3(9.0, 73.0, -4.0), Vector3(10.0, 81.0, -8.0), 1.5, 0.5, bf)
	g.use("UpperArm_L")
	g.ytaper(56, 66, 14.0, 0.5, 5.0, 5.0, 11.4, 0.5, 5.6, 5.6, bf, 2.6)
	g.use("LowerArm_L")
	g.ytaper(47, 56, 16.8, 0.5, 5.0, 4.8, 14.0, 0.5, 5.4, 5.3, bf, 2.6)
	g.seg(Vector3(18.0, 53.0, -1.0), Vector3(22.0, 55.0, -3.0), 1.3, 0.4, bf)        # 手肘外侧的骨刺
	g.use("Hand_L")
	g.sq(17.4, 44.0, 1.0, 4.6, 4.0, 4.2, bf, 2.4)
	g.use("Fingers_L")
	for f in range(3):
		var fz: float = -1.0 + float(f) * 2.2
		g.seg(Vector3(17.5, 41.0, fz + 1.0), Vector3(18.6, 35.0, fz + 2.5), 1.3, 0.6, bf)
	g.use("Thumb_L")
	g.seg(Vector3(14.5, 44.0, 3.0), Vector3(13.5, 40.0, 5.0), 1.2, 0.6, bf)
	g.use("Thigh_L")
	g.ytaper(28, 46, 6.2, 0.5, 5.2, 5.6, 6.0, 0.5, 6.2, 6.4, bf, 2.6)
	g.seg(Vector3(7.0, 29.0, 5.0), Vector3(8.0, 31.0, 9.0), 1.5, 0.5, bf)           # 膝前骨刺
	g.use("Shin_L")
	g.ytaper(9, 27, 6.0, 0.5, 4.4, 4.6, 6.4, 0.5, 5.2, 5.4, bf, 2.6)
	g.use("Foot_L")
	g.box(2, 0, -4, 10, 7, 6, bf)
	g.use("Toe_L")
	for tz in range(3):
		var tx: float = 3.0 + float(tz) * 3.0
		g.seg(Vector3(tx, 2.0, 6.0), Vector3(tx + 0.3, 0.5, 12.0), 1.6, 0.6, bf)
	g.sym = false
	# ---------------------------------------------------------------- 兜帽 + 往前弯的角 + 一只眼
	g.use("Head")
	g.sq(0.0, 82.0, 0.0, 8.6, 9.6, 8.6, bf, 2.3)
	g.seg(Vector3(0.0, 88.0, -2.0), Vector3(-1.0, 95.0, -3.0), 6.0, 4.2, bf)
	g.seg(Vector3(-1.0, 95.0, -3.0), Vector3(-3.0, 101.0, 0.0), 4.2, 2.8, bf)
	g.seg(Vector3(-3.0, 101.0, 0.0), Vector3(-5.0, 103.0, 5.0), 2.8, 1.6, bf)
	g.seg(Vector3(-5.0, 103.0, 5.0), Vector3(-6.0, 101.0, 9.0), 1.6, 0.6, bf)
	# 角尖在烧：最后一截发红发亮，尖上一小簇火苗(俯视看得见的一个亮点)
	var sg3: int = g.cur_glow
	g.cur_glow = 110
	g.seg(Vector3(-5.4, 102.2, 6.6), Vector3(-6.0, 101.0, 9.0), 1.1, 0.6, L2)
	g.cur_glow = sg3
	flame(-6.0, 101.0, 9.2, 2.4, 8.0, 5)
	# 兜帽两侧往下垂的边
	g.seg(Vector3(7.0, 80.0, 2.0), Vector3(9.5, 72.0, 1.0), 2.4, 1.6, bf)
	g.seg(Vector3(-7.0, 80.0, 2.0), Vector3(-9.5, 72.0, 1.0), 2.4, 1.6, bf)
	# 脸：兜帽前面挖空，里面是炭黑
	var smm: int = g.mode
	g.mode = VGrid.CLEAR
	g.sq(0.0, 80.5, 8.5, 6.0, 6.0, 3.6, 0, 2.2)
	g.mode = smm
	g.sq(0.0, 80.5, 3.5, 6.0, 6.2, 3.0, CH, 2.2)
	# 一只发光的眼(在脸的左边)，下面一道往下流的光
	hot_sq(2.6, 82.5, 6.4, 1.8, 1.4, 1.2, 2.0)
	g.cur_glow = 80
	g.box(2, 79, 6, 2, 81, 6, L1)
	g.cur_glow = 0
	# ---------------------------------------------------------------- 缠腰布(棕色，下摆参差)
	var cloth := Callable(self, "_cloth")
	g.use("Hips")
	g.ytaper(40, 48, 0.0, 0.0, 12.0, 7.8, 0.0, 0.0, 11.6, 7.6, cloth, 2.6)
	for side: float in [1.0, -1.0]:
		for x in range(-7, 8):
			var bottom: int = 14 + int(h01(x, 7, int(side)) * 9.0) + (4 if absi(x) > 4 else 0)
			for y in range(bottom, 41):
				for dz in range(0, 2):
					g.put(x, y, int(side * (8.0 + float(dz))) - (1 if side < 0.0 else 0), cloth.call(x, y, 0))
	# 腰带正中一颗发光的扣
	hot_sq(0.0, 44.0, 8.6, 1.8, 1.8, 1.0, 1.5)
	# ---------------------------------------------------------------- 右手里的一大团火(挂 Hand_R；俯视镜头里一眼看得见的红火、白热的芯)
	# 法器的握法(anim_combat.grot)：手的局部 +Z 朝上、-Y 朝前 → 火沿静止姿势的 +Z 方向烧，待机 / 跑 / 施法时火苗就朝上。
	# ADD：只填空格子，不抢手 / 前臂的体素
	g.use("Hand_R")
	var sm2: int = g.mode
	g.mode = VGrid.ADD
	_flame_z(-16.5, 44.0, 4.0, 7.2, 30.0, 3)
	_flame_z(-14.0, 46.5, 8.0, 3.2, 20.0, 7)
	# 往上飘的火星
	var sg2: int = g.cur_glow
	for sp: Vector3i in [Vector3i(-15, 46, 36), Vector3i(-19, 43, 33), Vector3i(-13, 42, 38), Vector3i(-18, 48, 40), Vector3i(-22, 46, 29)]:
		g.cur_glow = 130
		g.put(sp.x, sp.y, sp.z, L2 if sp.z % 2 == 0 else L3)
	g.cur_glow = sg2
	g.mode = sm2
	# ---------------------------------------------------------------- 熔岩裂纹(布料上很少)
	cracks(-26, 0, -14, 26, 106, 14, 6.5, 0.85, 0.55, 11, 0.66)


## 破烂的棕色缠腰布：深浅两档 + 零星的焦黑
func _cloth(x: int, y: int, z: int) -> int:
	var r: float = h01(x >> 1, y >> 2, z)
	if r < 0.12:
		return B3
	return H("#5a3b2b") if r < 0.6 else (H("#6e4934") if r < 0.85 else H("#47301f"))


## 沿 +Z 烧的火(手里的火：法器握法下手的局部 +Z 朝上)：根部白热、往上猩红、分成几根扭动收尖的火舌(用 L0~L3 色阶)
func _flame_z(cx: float, cy: float, cz: float, r: float, h: float, seed_i: int = 0) -> void:
	var sg: int = g.cur_glow
	for z in range(int(cz), int(cz + h) + 1):
		var t: float = (float(z) - cz) / h
		for y in range(int(cy - r) - 2, int(cy + r) + 3):
			for x in range(int(cx - r) - 2, int(cx + r) + 3):
				var sway: float = sin(t * 5.0 + float(seed_i)) * r * 0.35 * t
				var dx: float = float(x) + 0.5 - cx - sway
				var dy: float = float(y) + 0.5 - cy
				var rad: float = r * (1.0 - t * t) * (0.6 + 0.4 * clampf(t * 3.0, 0.0, 1.0)) * (0.85 + 0.3 * h01(x, y + seed_i, z))
				var d: float = sqrt(dx * dx + dy * dy)
				if d > rad:
					continue
				var k: float = d / maxf(0.01, rad)
				# 上半截分成几根火舌(按绕轴的角度挖掉几道缝)
				if t > 0.4 and sin(atan2(dy, dx) * 3.0 + float(seed_i) + t * 4.0) < -0.35:
					continue
				# 颜色按高度走：贴着手心的根部白热，往上猩红，火舌尖暗红(看得见的表面也有白热的芯)
				var tt: float = t + (k - 0.7) * 0.35 + (h01(x, y, z + seed_i) - 0.5) * 0.25
				var col: int = L3 if tt < 0.32 else (L2 if tt < 0.58 else (L1 if tt < 0.88 else L0))
				g.cur_glow = 160 if col == L3 else (95 if col == L2 else (60 if col == L1 else 45))
				g.put(x, y, z, col)
	g.cur_glow = sg
