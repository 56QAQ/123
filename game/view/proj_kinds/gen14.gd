extends RefCounted
## 通用武器 · gen14 的投射物(ProjRegistry 登记；接口见 game/view/proj_registry.gd)。没有新投射物就保持 KINDS 为空。

const KINDS: Array[String] = []
## 近战武器的刀光(外观名 -> {base, tip, life, energy, alpha, color}，刃根 / 刃尖是武器骨局部 +Y 的体素)；WeaponTrail 会查这里。
## 矛只画杖头那一段，单手剑 / 双手剑画整条刃
const TRAILS := {
	# 翠鳞鞭剑：一节节鳞刃 7..60，翠绿
	"g14_jadescale": {"base": 10.0, "tip": 59.0, "life": 0.17, "energy": 1.35, "alpha": 0.8, "color": Color("#7dffb0")},
	# 蓝徽骑士剑：银刃 8..58，冰蓝
	"g14_bluecrest": {"base": 11.0, "tip": 57.0, "life": 0.15, "energy": 1.3, "alpha": 0.78, "color": Color("#9fd0ff")},
	# 斗牛士剑：细长刺剑 9..63，猩红
	"g14_matador": {"base": 14.0, "tip": 62.0, "life": 0.14, "energy": 1.3, "alpha": 0.78, "color": Color("#ff6a5a")},
	# 苔衣巨剑：石刃 12..76，苔绿
	"g14_mossmantle": {"base": 16.0, "tip": 74.0, "life": 0.26, "energy": 1.5, "alpha": 0.9, "color": Color("#9be07a")},
	# 沉锚巨剑：锚杆上半 + 锚冠 / 锚爪 40..77，海蓝
	"g14_anchor": {"base": 40.0, "tip": 76.0, "life": 0.26, "energy": 1.55, "alpha": 0.9, "color": Color("#6fb6ff")},
	# 鮟鱇灯杖：杖头的弯钩 + 灯 70..96，幽蓝
	"g14_angler": {"base": 72.0, "tip": 95.0, "life": 0.15, "energy": 1.3, "alpha": 0.78, "color": Color("#8fe8ff")},
}


static func make(_fx: Fx, _kind: String, _heal: bool, _color: Color) -> Node3D:
	return Node3D.new()


static func fly(_node: Node3D, _kind: String, _frac: float, _t: float, _seed: float) -> Vector3:
	return Vector3.ZERO


static func release(_fx: Fx, _kind: String, _at: Vector3, _dir: Vector3) -> void:
	pass


static func hit(_fx: Fx, _kind: String, _at: Vector3, _dir: Vector3) -> void:
	pass
