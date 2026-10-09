extends RefCounted
## 通用武器 · gen10 的投射物(ProjRegistry 登记；接口见 game/view/proj_registry.gd)。没有新投射物就保持 KINDS 为空。

const KINDS: Array[String] = []
## 近战武器的刀光(外观名 → {base, tip, life, energy, alpha, color}，刃根 / 刃尖是武器骨局部 +Y 的体素)；WeaponTrail 会查这里
const TRAILS := {
	# 青藤剑：木刃 6~54(刃尖顶着叶芽)，嫩绿
	"g10_vine": {"base": 14.0, "tip": 54.0, "life": 0.15, "energy": 1.3, "alpha": 0.78, "color": Color("#a6e070")},
	# 刻时剑：分针形的细剑身 10~58，冷蓝
	"g10_chrono": {"base": 16.0, "tip": 57.0, "life": 0.15, "energy": 1.3, "alpha": 0.78, "color": Color("#86d2ff")},
	# 血宴长剑：阔刃 8~56，血红
	"g10_feast": {"base": 14.0, "tip": 55.0, "life": 0.16, "energy": 1.35, "alpha": 0.82, "color": Color("#ff5560")},
	# 流水双刃：起伏的刃 5~27，水青
	"g10_current": {"base": 8.0, "tip": 26.0, "life": 0.14, "energy": 1.2, "alpha": 0.74, "color": Color("#8ff0f6")},
	# 蛇牙双刃：獠牙 7~28，越往尖越往刀背弯，取到 25；毒绿
	"g10_viper": {"base": 9.0, "tip": 25.0, "life": 0.13, "energy": 1.25, "alpha": 0.76, "color": Color("#a6ff6a")},
}


static func make(_fx: Fx, _kind: String, _heal: bool, _color: Color) -> Node3D:
	return Node3D.new()


static func fly(_node: Node3D, _kind: String, _frac: float, _t: float, _seed: float) -> Vector3:
	return Vector3.ZERO


static func release(_fx: Fx, _kind: String, _at: Vector3, _dir: Vector3) -> void:
	pass


static func hit(_fx: Fx, _kind: String, _at: Vector3, _dir: Vector3) -> void:
	pass
