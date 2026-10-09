class_name EquipmentDef
extends RefCounted
## 装备 = 武器。武器大类(class_id，见 GC.WEAPON_CLASSES)决定射程/普攻倍率/普攻动画；
## 武器本身再提供 属性加成 + 不完整的效果载荷(abilities)。载荷必须由单位触发器扣动，武器自己不监听任何事件。
## basic=true 的是"基础武器"(木弓/铁剑…)：没有效果和属性，只提供本大类的射程/倍率/动画；
## 它不会进背包，只在棋子没有装备其他武器时自动装备上。

var id: String = ""
var cost: int = 1
var color_id: String = "black"
var class_id: String = "sword"       # 武器大类
var basic: bool = false
var flat_mods: Dictionary = {}       # stat -> flat
var pct_mods: Dictionary = {}        # stat -> percent (0.2 = +20%)
var abilities: Array[AbilityDef] = []
var reworked: bool = false            # 按新设计重构过(图鉴只收录这些)
var owner: String = ""                 # 专属武器的主人(单位 id；谁都能装，只是"她的")
var ranged_projectile: Dictionary = {}  # 近战武器加了射程后，目标在 min_dist 米外就改发投射物 {kind, speed, min_dist}(舞扇的魔力飞环)
var projectile: String = ""           # 远程武器自己的投射物外观(爱心针剂 = syringe_dart)；空 = 用武器大类的
var token: String = ""                # 特殊物品(slot = token)的用途："hunt_mark" = 拖到敌人身上标记狩猎对象(狩猎旗标)
var no_drop: bool = false             # 不进随机来源(晶球 / 黑市 / 车间制造)：只能从别处拿到(打工小帮手：开局送)
var model: String = ""               # 外观：plain(朴素) / ornate(华丽，按武器颜色着色)
var wclass_override: Dictionary = {}  # 这把武器改写所在大类的参数(黑色战场：普攻倍率更高、弹匣【叠加 1】)；空 = 照大类
var _wc: Dictionary = {}
var fit_add: Array[String] = []       # 适配角色的人工修正(测强度为准)：标签没算上但合手的棋子
var fit_remove: Array[String] = []    # …标签算上了但测出来不合手的棋子
var fit_override: Dictionary = {}     # 适配标签的人工覆盖 {side, multi, basic}(数据 fit_tags)；空 = 由能力推(FitTags.weapon_tags)
var slot: String = "weapon"          # 装备种类(车间按它分页)：现在只有武器；别的种类留接口，门类 = class_id。
                                     # "token" = 不可佩戴的特殊物品(狩猎旗标)：只在武器库里，不能装备、不掉落、不能制造 / 分解


static func from_dict(d: Dictionary) -> EquipmentDef:
	var e := EquipmentDef.new()
	e.id = str(d.get("id", ""))
	e.basic = bool(d.get("basic", false))
	e.cost = clampi(int(d.get("cost", 1)), 0 if e.basic else 1, 5)
	e.color_id = str(d.get("color_id", "black")).to_lower()
	e.class_id = str(d.get("weapon_class", d.get("class_id", "sword"))).to_lower()
	var fm: Variant = d.get("flat_stat_modifiers", {})
	if fm is Dictionary:
		for k: Variant in (fm as Dictionary).keys():
			e.flat_mods[str(k)] = float((fm as Dictionary)[k])
	var pm: Variant = d.get("percent_stat_modifiers", {})
	if pm is Dictionary:
		for k2: Variant in (pm as Dictionary).keys():
			e.pct_mods[str(k2)] = float((pm as Dictionary)[k2])
	for a: Variant in d.get("abilities", []):
		if a is Dictionary:
			e.abilities.append(AbilityDef.from_dict(a as Dictionary))
	e.model = str(d.get("model", "plain" if e.basic else "ornate"))
	e.reworked = bool(d.get("reworked", false))
	e.owner = str(d.get("owner", ""))
	e.ranged_projectile = (d.get("ranged_projectile", {}) as Dictionary).duplicate()
	e.projectile = str(d.get("projectile", ""))
	e.token = str(d.get("token", ""))
	e.no_drop = bool(d.get("no_drop", false))
	e.slot = str(d.get("slot", "weapon"))
	for fa: Variant in d.get("fit_add", []):
		e.fit_add.append(str(fa))
	for fr: Variant in d.get("fit_remove", []):
		e.fit_remove.append(str(fr))
	var fo: Variant = d.get("fit_tags", {})
	if fo is Dictionary:
		e.fit_override = (fo as Dictionary).duplicate()
	e.wclass_override = (d.get("wclass_override", {}) as Dictionary).duplicate(true)
	return e


func wclass() -> Dictionary:
	if wclass_override.is_empty():
		return GC.weapon_class(class_id)
	if _wc.is_empty():
		_wc = GC.weapon_class(class_id).duplicate(true)
		_wc.merge(wclass_override, true)
	return _wc


func is_ranged() -> bool:
	return bool(wclass().get("ranged", false))


## 实际按远程用(站后排、风筝)：远程大类，而且射程没被改到近战长度——攻击范围归零的电击器按近战(和 BUnit.style() 一个口径；机器人摆位用)
func plays_ranged() -> bool:
	if not is_ranged():
		return false
	var r: float = (float(wclass().get("range", 0.0)) + float(flat_mods.get("attack_range", 0.0))) * (1.0 + float(pct_mods.get("attack_range", 0.0)))
	return r * GC.RANGE_UNIT >= 1.0


## 普通的武器(能装备、能掉落 / 制造 / 分解)：不是基础武器，也不是特殊物品
func is_gear() -> bool:
	return not basic and slot == "weapon"


## 能否装备给该单位：武器大类在单位允许范围内 + 颜色兼容。基础武器不能被拖来拖去。
func can_equip_to(unit: UnitDef, star: int = 1) -> bool:
	return equip_problem(unit, star) == ""


## 不能装备的原因(本地化键)；空串 = 可以
func equip_problem(unit: UnitDef, star: int = 1) -> String:
	if slot == "token":
		return "ui.err.not_wearable"
	if basic:
		return "ui.err.bad_target"
	if not unit.can_use_weapon_class(class_id):
		return "ui.err.weapon_class"
	# 棋子自己的装备规则(到星级后生效)：额外能装的颜色、不能装的结算规则(如灾星节点 2 星：能装红色、不能装[双模])
	var rules: Dictionary = unit.equip_rules
	var active: bool = not rules.is_empty() and star >= int(rules.get("unlock_star", 1))
	if active:
		for a: AbilityDef in abilities:
			if (rules.get("forbid_classes", []) as Array).has(a.ability_class):
				return "ui.err.forbidden_rule"
	if not GC.equipment_fits_faction(color_id, unit.faction_id):
		if not (active and (rules.get("extra_colors", []) as Array).has(color_id)):
			return "ui.err.color_mismatch"
	return ""


func validate() -> Array[String]:
	var errs: Array[String] = []
	if id == "":
		errs.append("equipment id is required")
	if not GC.FACTIONS.has(color_id):
		errs.append("equipment %s: unknown color %s" % [id, color_id])
	if slot == "weapon" and not GC.WEAPON_CLASSES.has(class_id):
		errs.append("equipment %s: unknown weapon class %s" % [id, class_id])
	if slot == "token":
		return errs
	if basic:
		if not abilities.is_empty() or not flat_mods.is_empty() or not pct_mods.is_empty():
			errs.append("equipment %s: a basic weapon only provides its class (no effects, no stats)" % id)
		return errs
	if abilities.is_empty():
		errs.append("equipment %s: needs at least one effect payload" % id)
	for a: AbilityDef in abilities:
		errs.append_array(a.validate())
		if not a.required_trigger_tags.has("equipment_payload"):
			errs.append("equipment %s: ability %s must require the equipment_payload trigger tag" % [id, a.id])
	return errs
