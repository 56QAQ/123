extends RefCounted
## 通用武器 · gen9 的投射物(ProjRegistry 登记；接口见 game/view/proj_registry.gd)。没有新投射物就保持 KINDS 为空。

const KINDS: Array[String] = []
## 近战武器的刀光(外观名 → {base, tip, life, energy, alpha, color}，刃根 / 刃尖是武器骨局部 +Y 的体素)；WeaponTrail 会查这里。
## 矛只画枪头那一段(同大类默认 60..88)，双手剑画整条刃(同大类默认 16..78)
const TRAILS := {
	# 凝潮长枪：冰刃 65..92
	"g9_rimetide": {"base": 62.0, "tip": 91.0, "life": 0.15, "energy": 1.3, "alpha": 0.78, "color": Color("#9feeff")},
	# 曦光长枪：枪刃 63..94(日轮在 61..83，不画)
	"g9_dawnlight": {"base": 64.0, "tip": 93.0, "life": 0.15, "energy": 1.35, "alpha": 0.8, "color": Color("#ffd970")},
	# 星轨长枪：枪刃 64..93
	"g9_starorbit": {"base": 63.0, "tip": 92.0, "life": 0.15, "energy": 1.3, "alpha": 0.78, "color": Color("#c49aff")},
	# 荆棘巨剑：刃 9..75
	"g9_thorn": {"base": 16.0, "tip": 72.0, "life": 0.26, "energy": 1.5, "alpha": 0.9, "color": Color("#8cdc5a")},
	# 凯旋巨剑：刃 10..76
	"g9_laurel": {"base": 16.0, "tip": 74.0, "life": 0.26, "energy": 1.55, "alpha": 0.92, "color": Color("#ff5a5a")},
	# 涌泉巨剑：刃 10..77
	"g9_wellspring": {"base": 16.0, "tip": 75.0, "life": 0.26, "energy": 1.5, "alpha": 0.9, "color": Color("#7ff0ff")},
}


static func make(_fx: Fx, _kind: String, _heal: bool, _color: Color) -> Node3D:
	return Node3D.new()


static func fly(_node: Node3D, _kind: String, _frac: float, _t: float, _seed: float) -> Vector3:
	return Vector3.ZERO


static func release(_fx: Fx, _kind: String, _at: Vector3, _dir: Vector3) -> void:
	pass


static func hit(_fx: Fx, _kind: String, _at: Vector3, _dir: Vector3) -> void:
	pass
