extends "res://tools/chars/_droid.gd"
## MR-05 维修无人机(Repair Drone)：悬浮的四旋翼维修无人机——施法者，站在后排每 2 秒给生命最低的友方机器修一下。2026-10-15 第一版：
##   机身(挂 Root：悬浮起伏、前倾、侧倾都是它)：离地 0.8~1.0 米，扁圆的机身——上面白色的整流罩、下半深藏青、腹底石墨色，
##     罩顶一个洋红的"+"维修标记(俯视一眼认出是"奶")；正面一只大镜头(深藏青的镜筒 + 深色镜片 + 洋红的光圈 + 白芯)；
##     左右两侧深藏青的侧板上各一道洋红的灯；背后一根短天线(顶上一粒洋红灯)；
##     四根斜伸出去的旋翼臂(深藏青 + 白色盖板)，末端白色的电机舱、底下一点洋红的推力光，上面一片扁圆的旋翼盘
##     (石墨色的转影 + 两片白桨 + 深色的桨毂)，外面套一圈深藏青的护圈(一根撑杆连到电机舱)。
##   机腹吊着一条三节的维修臂(每节一整块刚体，挂一根有位置轨道的骨头，动作里按"绕关节转"反算，见 anim_chars.gd 的 DRONE_*；
##     这几根骨头的位置和身体不对应，别拿通用动作去播)：
##     肩座(机腹一圈深藏青的座 + 深色的关节球)→ 上臂(白，挂 Hips)→ 肘(深色球)→ 前臂(深藏青 + 白护套，挂 Halo)→ 腕(深色球)
##     → 焊枪头(挂 Chest：白色的枪身 + 深色的枪嘴 + 两根短夹爪，喷口一点洋红光，静止时朝前下方)。
##     喷口(出手 / 修复光束的起点)= Chest 骨上的 (0, 47.3, 15.4)(模型静止坐标，体素：ARM_W + 焊枪朝向 × 7.2)。
## 身份色：洋红(#ff5fd2)——镜头光圈、维修标记、喷口、推力光、天线、侧灯。全部刚体。游戏里 scale 1.0。
## 坐标同角色(1 体素 = 1.25 cm)：脚底 y = 0，朝 +Z，左手侧 +X。

const IDENTITY := {"rim": "#ff5fd2", "rim_k": 0.1, "pulse": 0.0}

const BODY_Y := 72.0                          # 机身中心高度
const ARM_M := Vector3(0.0, 65.5, 2.5)        # 维修臂的肩座
const ARM_E := Vector3(0.0, 57.0, 4.0)        # 肘
const ARM_W := Vector3(0.0, 50.5, 9.0)        # 腕
const TORCH_DIR := Vector3(0.0, -0.45, 0.89)  # 焊枪朝向(静止时：前下方)
const ROTOR := 17.0                           # 旋翼毂离机身中心(x、z 各 17)
const ROTOR_Y := 79                           # 旋翼盘所在的那一层


func build() -> void:
	droid_init("#ff5fd2", "#252f48")
	_body()
	for sx: float in [1.0, -1.0]:
		for sz: float in [1.0, -1.0]:
			_rotor(sx, sz)
	_arm()
	_rigid()


func _hull(x: int, y: int, z: int) -> int:
	return plate(x, y, z) if y >= 72 else navy(x, y, z)


func _body() -> void:
	var pf := Callable(self, "plate")
	var nf := Callable(self, "navy")
	var jf := Callable(self, "joint")
	g.sym = false
	g.use("Root")
	# 机身：扁圆，上白下藏青；腹底石墨色；顶上一个白色的整流罩
	g.sq(0.0, BODY_Y, 0.0, 10.5, 5.5, 11.5, Callable(self, "_hull"), 2.6)
	g.sq(0.0, 67.0, 0.5, 7.0, 2.2, 8.0, jf, 2.4)
	g.sq(0.0, 77.0, -1.0, 7.5, 3.0, 8.0, pf, 2.4)
	g.ytaper(71, 71, 0.0, 0.0, 10.9, 11.9, 0.0, 0.0, 10.9, 11.9, nf, 2.6)
	# 罩顶的维修标记："+"(洋红，微微发光)
	glow_box(-1, 80, -7, 0, 80, 3, 45)
	glow_box(-5, 80, -3, 4, 80, -1, 45)
	# 正面的大镜头：镜筒 + 深色镜片 + 洋红光圈 + 白芯
	g.sq(0.0, 71.0, 10.0, 5.4, 5.4, 2.8, nf, 2.6)
	g.sq(0.0, 71.0, 12.4, 4.2, 4.2, 1.0, D0, 2.0)
	glow_ring(Vector3(0.0, 71.0, 13.0), Vector3(0, 0, 1), 3.0, 1.2, 80)
	glow_sq(0.0, 71.0, 13.2, 1.1, 1.1, 0.6, 70)
	glow_sq(0.7, 71.7, 13.5, 0.6, 0.6, 0.5, 95, N1)
	# 背后的天线
	g.seg(Vector3(3.5, 76.0, -7.5), Vector3(5.0, 87.0, -10.0), 0.7, 0.5, jf)
	glow_sq(5.0, 88.0, -10.0, 1.1, 1.1, 1.1, 85)
	# 维修臂的肩座：机腹一圈深藏青的座
	g.sq(ARM_M.x, ARM_M.y + 0.8, ARM_M.z, 3.8, 1.4, 3.8, nf, 2.2)
	g.sym = true
	g.use("Root")
	# 左右的深藏青侧板 + 一道洋红的灯
	g.box(9, 68, -6, 10, 72, 6, nf)
	glow_box(11, 70, -4, 11, 70, 4, 55)
	g.sym = false


## 一组旋翼(挂 Root)：sx / sz = 往哪个对角伸出去
func _rotor(sx: float, sz: float) -> void:
	var pf := Callable(self, "plate")
	var nf := Callable(self, "navy")
	var jf := Callable(self, "joint")
	g.sym = false
	g.use("Root")
	var hub := Vector3(sx * ROTOR, 75.5, sz * ROTOR)
	var root := Vector3(sx * 6.5, 72.5, sz * 6.5)
	# 旋翼臂：深藏青 + 顶上一条白盖板
	g.seg(root, hub, 2.1, 1.6, nf)
	g.seg(root.lerp(hub, 0.3) + Vector3(0.0, 1.3, 0.0), root.lerp(hub, 0.8) + Vector3(0.0, 1.0, 0.0), 1.4, 1.2, pf)
	# 电机舱 + 底下的推力光
	g.sq(hub.x, hub.y, hub.z, 2.9, 2.7, 2.9, pf, 2.2)
	g.sq(hub.x, hub.y - 1.6, hub.z, 2.6, 1.0, 2.6, nf, 2.4)
	glow_sq(hub.x, hub.y - 2.9, hub.z, 1.7, 0.6, 1.7, 55)
	g.seg(hub, hub + Vector3(0.0, 3.5, 0.0), 0.9, 0.9, jf)
	# 旋翼盘：一层，石墨色的转影 + 两片白桨 + 深色桨毂
	var ang: float = 0.6 if sx * sz > 0.0 else -0.6
	var bd := Vector2(cos(ang), sin(ang))
	for z in range(int(hub.z) - 9, int(hub.z) + 10):
		for x in range(int(hub.x) - 9, int(hub.x) + 10):
			var q := Vector2(float(x) + 0.5 - hub.x, float(z) + 0.5 - hub.z)
			var r: float = q.length()
			if r > 7.8:
				continue
			var c: int = D1
			if r < 1.6:
				c = D0
			elif absf(q.x * bd.y - q.y * bd.x) < 1.1:
				c = P2 if r < 7.0 else P1
			elif r > 6.9:
				c = M0
			g.put(x, ROTOR_Y, z, c)
	# 护圈 + 一根撑杆
	g.ring(Vector3(hub.x, float(ROTOR_Y) + 0.5, hub.z), Vector3.UP, 9.0, 1.8, nf)
	var out := Vector3(sx, 0.0, sz).normalized()
	g.seg(hub + out * 2.0, Vector3(hub.x, float(ROTOR_Y), hub.z) + out * 8.6, 0.8, 0.8, nf)


## 维修臂：上臂(Hips)→ 前臂(Halo)→ 焊枪头(Chest)
func _arm() -> void:
	var pf := Callable(self, "plate")
	var nf := Callable(self, "navy")
	var jf := Callable(self, "joint")
	g.sym = false
	# 上臂：肩关节球 + 白色的臂 + 肘关节球
	g.use("Hips")
	g.sq(ARM_M.x, ARM_M.y, ARM_M.z, 2.8, 2.8, 2.8, jf, 2.0)
	g.seg(ARM_M, ARM_E, 2.0, 1.8, pf)
	g.seg(ARM_M.lerp(ARM_E, 0.55), ARM_M.lerp(ARM_E, 0.7), 2.2, 2.1, nf)
	# 前臂：深藏青 + 白护套 + 腕关节球
	g.use("Halo")
	g.sq(ARM_E.x, ARM_E.y, ARM_E.z, 2.3, 2.3, 2.3, jf, 2.0)
	g.seg(ARM_E, ARM_W, 1.7, 1.5, nf)
	g.seg(ARM_E.lerp(ARM_W, 0.25), ARM_E.lerp(ARM_W, 0.6), 2.1, 2.0, pf)
	g.sq(ARM_W.x, ARM_W.y, ARM_W.z, 1.9, 1.9, 1.9, jf, 2.0)
	# 焊枪头：白色枪身 + 深色枪嘴 + 两根短夹爪 + 喷口的洋红光
	g.use("Chest")
	var td: Vector3 = TORCH_DIR.normalized()
	var side := Vector3(1.0, 0.0, 0.0)
	g.seg(ARM_W + td * 1.0, ARM_W + td * 4.2, 2.4, 2.2, pf)
	g.seg(ARM_W + td * 2.4, ARM_W + td * 3.0, 2.6, 2.6, nf)
	g.seg(ARM_W + td * 4.2, ARM_W + td * 6.8, 1.5, 1.0, D0)
	for s: float in [1.0, -1.0]:
		g.seg(ARM_W + td * 3.5 + side * s * 2.0, ARM_W + td * 6.5 + side * s * 2.4, 0.7, 0.5, jf)
	var tip: Vector3 = ARM_W + td * 7.2
	glow_sq(tip.x, tip.y, tip.z, 1.1, 1.1, 1.1, 90)
	glow_sq(tip.x, tip.y - 0.2, tip.z + 0.4, 0.5, 0.5, 0.5, 100, N1)


## 所有体素只跟一根骨头走(刚体)
func _rigid() -> void:
	for z in range(-40, 40):
		for y in range(30, 100):
			for x in range(-40, 40):
				if g.solid(x, y, z):
					g.set_weights(x, y, z, [[int(g.get_bone(x, y, z)), 1.0]])
