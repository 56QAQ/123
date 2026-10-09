class_name ProjRegistry
extends RefCounted
## 通用武器的分批投射物(2026-10-09：三批一组并行派给不同的子代理——各写各的 game/view/proj_kinds/<批>.gd，不用动 fx.gd / battle_view.gd)。
## 武器数据写 projectile = 这里登记的种类，Fx.make_projectile / BattleView 的飞行、出手、命中都先问这里。每个文件：
##   const KINDS: Array[String] = [...]
##   static func make(fx: Fx, kind: String, heal: bool, color: Color) -> Node3D        —— 弹体(子节点可以起名，fly 里转它们)
##   static func fly(node: Node3D, kind: String, frac: float, t: float, seed: float) -> Vector3
##       —— 这一帧相对直线的偏移：x = 往右偏(米)、y = 抬高(米)、z = 往前多走(米)；frac = 飞了几成(0~1)，t = 战斗时间，seed = 这一发的编号
##   static func release(fx: Fx, kind: String, at: Vector3, dir: Vector3) -> void     —— 出手的小特效(在出手的那只手上；登记过的种类不画枪口火光)
##   static func hit(fx: Fx, kind: String, at: Vector3, dir: Vector3) -> void         —— 命中的小特效
##   const TRAILS := {外观名: {base, tip, life, energy, alpha, color}}(可选)               —— 近战武器的刀光长度(WeaponTrail 先查 MODEL_STYLES 再查这里)
const SCRIPTS: Array = [preload("res://game/view/proj_kinds/gen5.gd"), preload("res://game/view/proj_kinds/gen6.gd"), preload("res://game/view/proj_kinds/gen7.gd"),
	preload("res://game/view/proj_kinds/gen8.gd"), preload("res://game/view/proj_kinds/gen9.gd"), preload("res://game/view/proj_kinds/gen10.gd"),
	preload("res://game/view/proj_kinds/gen11.gd"), preload("res://game/view/proj_kinds/gen12.gd"), preload("res://game/view/proj_kinds/gen13.gd"),
	preload("res://game/view/proj_kinds/gen14.gd"), preload("res://game/view/proj_kinds/gen15.gd"), preload("res://game/view/proj_kinds/gen16.gd")]


static func _of(kind: String) -> Variant:
	for s: Variant in SCRIPTS:
		if (s.KINDS as Array).has(kind):
			return s
	return null


static func has(kind: String) -> bool:
	return kind != "" and _of(kind) != null


static func make(fx: Fx, kind: String, heal: bool, color: Color) -> Node3D:
	return _of(kind).make(fx, kind, heal, color)


static func fly(node: Node3D, kind: String, frac: float, t: float, seed: float) -> Vector3:
	return _of(kind).fly(node, kind, frac, t, seed)


static func release(fx: Fx, kind: String, at: Vector3, dir: Vector3) -> void:
	_of(kind).release(fx, kind, at, dir)


static func hit(fx: Fx, kind: String, at: Vector3, dir: Vector3) -> void:
	_of(kind).hit(fx, kind, at, dir)


## 分批文件里登记的刀光样式(外观名 → 参数)；没有 = 空字典
static func trail(model: String) -> Dictionary:
	if model == "":
		return {}
	for s: Variant in SCRIPTS:
		var m: Dictionary = (s as GDScript).get_script_constant_map()
		if m.has("TRAILS") and (m["TRAILS"] as Dictionary).has(model):
			return m["TRAILS"][model]
	return {}
