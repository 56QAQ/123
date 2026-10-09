extends RefCounted
## 通用武器 · gen12 的投射物(ProjRegistry 登记；接口见 game/view/proj_registry.gd)。没有新投射物就保持 KINDS 为空。

const KINDS: Array[String] = []
## 近战武器的刀光(外观名 → {base, tip, life, energy, alpha, color}，刃根 / 刃尖是武器骨局部 +Y 的体素)；WeaponTrail 会查这里。
## 矛只画枪头那一段，单手剑 / 双手剑画整条刃
const TRAILS := {
	# 鲸歌长枪：枪刃 72..95(鲸尾 66..79 不画)，海蓝
	"g12_whalesong": {"base": 73.0, "tip": 94.0, "life": 0.15, "energy": 1.3, "alpha": 0.78, "color": Color("#7fb6ff")},
	# 翠竹长枪：青玉枪刃 64..93，翠青
	"g12_jadebamboo": {"base": 65.0, "tip": 92.0, "life": 0.15, "energy": 1.3, "alpha": 0.78, "color": Color("#8ff0d2")},
	# 金雀细剑：细剑身 13..60(金雀在 2..12，不画)，金黄
	"g12_goldfinch": {"base": 16.0, "tip": 59.0, "life": 0.14, "energy": 1.3, "alpha": 0.78, "color": Color("#ffe27a")},
	# 紫藤长剑：剑身 6..57，淡紫
	"g12_wisteria": {"base": 12.0, "tip": 56.0, "life": 0.15, "energy": 1.3, "alpha": 0.8, "color": Color("#c9a6ff")},
	# 梦魇巨剑：波浪刃 10..76，夜紫
	"g12_nightmare": {"base": 16.0, "tip": 74.0, "life": 0.26, "energy": 1.5, "alpha": 0.9, "color": Color("#a45cff")},
	# 金钟巨剑：宽金刃 13..78，金
	"g12_goldbell": {"base": 18.0, "tip": 76.0, "life": 0.26, "energy": 1.55, "alpha": 0.92, "color": Color("#ffd35a")},
}


static func make(_fx: Fx, _kind: String, _heal: bool, _color: Color) -> Node3D:
	return Node3D.new()


static func fly(_node: Node3D, _kind: String, _frac: float, _t: float, _seed: float) -> Vector3:
	return Vector3.ZERO


static func release(_fx: Fx, _kind: String, _at: Vector3, _dir: Vector3) -> void:
	pass


static func hit(_fx: Fx, _kind: String, _at: Vector3, _dir: Vector3) -> void:
	pass
