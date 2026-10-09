extends RefCounted
## 通用武器 · gen14 的投射物(ProjRegistry 登记；接口见 game/view/proj_registry.gd)。没有新投射物就保持 KINDS 为空。

const KINDS: Array[String] = []
## 近战武器的刀光(外观名 -> {base, tip, life, energy, alpha, color}，刃根 / 刃尖是武器骨局部 +Y 的体素)；WeaponTrail 会查这里
const TRAILS := {}


static func make(_fx: Fx, _kind: String, _heal: bool, _color: Color) -> Node3D:
	return Node3D.new()


static func fly(_node: Node3D, _kind: String, _frac: float, _t: float, _seed: float) -> Vector3:
	return Vector3.ZERO


static func release(_fx: Fx, _kind: String, _at: Vector3, _dir: Vector3) -> void:
	pass


static func hit(_fx: Fx, _kind: String, _at: Vector3, _dir: Vector3) -> void:
	pass
