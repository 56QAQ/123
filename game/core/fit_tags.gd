class_name FitTags
extends RefCounted
## 武器的适配角色(用户 2026-10-09)：棋子的武器触发器和武器各有三组内置标签，三组都对上 = 这把武器适配这只棋子。
##   触发器(单位数据 trigger.fit_tags，./run_fitprobe.sh 实测 → tools/fit_tags.py → author_data.py 写进去)：
##     side  对敌人 enemy / 对队友 ally(含自己) / 需要双模 both(敌我都会打到)
##     count 对多个目标 multi / 对单个目标 single
##     freq  高频 high / 低频 low / 战斗里不响 never(实测一场都没触发过：幻形的触发器在战斗结束时——什么武器都不适配)
##   武器(由能力推出来，weapon_tags；数据里写了 fit_tags 就照数据)：
##     side  对敌人 enemy / 对队友 ally / 提供双模 dual(护符的敌我分支、按目标阵营换效果的、不看触发目标的)
##     multi 有【群攻】(或"所有目标") / 无；any_target = 效果全都不看触发目标(强化召唤物、回充能、钱袋……)：目标数也无所谓
##     basic 有【基本】(不吃冷却：每次触发都生效) / 无
##   对应：side —— 提供双模的武器哪种触发器都行；对敌人 / 对队友的武器只配同一边的触发器；"需要双模"的触发器只配提供双模的武器。
##         count —— 有【群攻】配对多个目标、无【群攻】配对单个目标(一一对应)；不看触发目标的武器两种都行。
##         freq —— 高频触发器要【基本】(冷却会吃掉大半次触发)；低频触发器有没有【基本】都行(冷却几乎卡不到它)。
##   (2026-10-09 定规则时拿专武校准：用户给自己棋子设计的专武是"适配"的标准答案。按上面的规则 45 把专武里 39 把适配主人；
##    频率一一对应只有 29 把——低频触发器配【基本】的专武很多(屏息 / 守誓 / 心连 / 巧运 / 浪游 / 迅游 / 星旅 / 和星)。)
## 适配角色 = 进商店的棋子里，有一个武器触发器三组都对上、并且这把武器装得上(颜色 / 大类 / 装备规则，2 星和 3 星都要装得上)的。
## 测强度和标签不一致时，武器数据可以写 fit_add / fit_remove(棋子 id 列表)修正：测出来合手但标签没算上的加进去、标签算上但测出来 +0 的去掉。
## 有好几个武器触发器的棋子(舞星：一个给队友、一个给敌人)，每个触发器都会扣同一把武器——单边的武器只要有一个触发器在另一边就会用反
## (伤害打到队友 / 增益给了敌人)，所以要求每个触发器的敌我都对得上(side_ok)，三组全对上的有一个就行。
## 另外有些效果离不开棋子自己的机制(三组标签看不出来)：强化召唤物的要有召唤物(【召唤】)，回充能 / 按充能算的要有【充能】被动(武器的前提 needs)。

const SIDES: Array[String] = ["enemy", "ally", "both"]
const WEAPON_SIDES: Array[String] = ["enemy", "ally", "dual"]

## 效果作用在触发目标身上时是对哪一边(stat_status 看状态的 buff / debuff 标记；没列的 = 对敌人)。
## dual = 按目标阵营换效果(算"提供双模")；any = 不看触发目标(作用在携带者 / 召唤物 / 地面上)：哪边、几个目标都行
const EFFECT_SIDE := {
	"heal": "ally", "shield": "ally", "black_keys": "ally", "oath_bestow": "ally", "refresh_once": "ally", "empower_shots": "ally",
	"verdant_grove": "ally", "edict": "dual", "charge_scaled_damage": "dual",
	"charge_refill": "any", "summon_aura": "any", "money_bag": "any", "grant_reward": "any", "create_field": "any", "create_orbs": "any",
	"shadow_slay": "any",
}


const EFFECT_NEEDS := {"summon_aura": "summon", "charge_refill": "charged", "charge_scaled_damage": "charged"}


## 武器效果离不开的棋子机制(summon / charged)
static func needs(e: EquipmentDef) -> Array[String]:
	var r: Array[String] = []
	for a: AbilityDef in e.abilities:
		var n: String = str(EFFECT_NEEDS.get(a.effect_type, ""))
		for ex: Variant in a.effect_config.get("extra_effects", []):
			if ex is Dictionary and EFFECT_NEEDS.has(str((ex as Dictionary).get("effect_type", ""))):
				n = str(EFFECT_NEEDS[str((ex as Dictionary)["effect_type"])])
		if n != "" and not r.has(n):
			r.append(n)
	return r


## 棋子有没有某种机制：它的被动(或普攻能力)带这个关键词
static func unit_has(u: UnitDef, mech: String) -> bool:
	for a: AbilityDef in u.passives:
		if a.has_keyword(mech):
			return true
	return u.normal_attack != null and u.normal_attack.has_keyword(mech)


## 武器的三组标签 {side, multi, basic, any_target}
static func weapon_tags(e: EquipmentDef) -> Dictionary:
	if not e.fit_override.is_empty():
		var o: Dictionary = e.fit_override.duplicate()
		o["any_target"] = bool(o.get("any_target", false))
		return o
	var sides := {}
	var multi := false
	var basic := false
	for a: AbilityDef in e.abilities:
		sides[_ability_side(a)] = true
		if a.has_keyword("multi_attack") or bool(a.effect_config.get("all_targets", false)):
			multi = true
		if a.has_keyword("basic"):
			basic = true
	var any_target: bool = sides.size() == 1 and sides.has("any")
	var side := "enemy"
	if any_target or sides.has("dual") or (sides.has("enemy") and sides.has("ally")):
		side = "dual"
	elif sides.has("ally"):
		side = "ally"
	return {"side": side, "multi": multi and not any_target, "basic": basic, "any_target": any_target}


static func _ability_side(a: AbilityDef) -> String:
	if a.ability_class == "amulet" or a.effect_config.has("ally_effect") or a.effect_config.has("enemy_effect"):
		return "dual"
	var s: String = str(EFFECT_SIDE.get(a.effect_type, ""))
	if s != "":
		return s
	if a.effect_type == "stat_status":
		return "enemy" if (a.effect_config.get("flags", []) as Array).has("debuff") else "ally"
	return "enemy"


## 触发器的三组标签 {side, count, freq}；没有标签(还没量过)= 空字典
static func trigger_tags(t: TriggerDef) -> Dictionary:
	return t.fit


## 敌我对得上：提供双模的哪边都行；单边的只配同一边
static func side_ok(tt: Dictionary, wt: Dictionary) -> bool:
	var ws: String = str(wt["side"])
	return ws == "dual" or ws == str(tt.get("side", ""))


## 触发器 tt 和武器 wt 三组都对上
static func matches(tt: Dictionary, wt: Dictionary) -> bool:
	if tt.is_empty() or str(tt.get("freq", "")) == "never":
		return false
	var s_ok: bool = side_ok(tt, wt)
	var count_ok: bool = bool(wt.get("any_target", false)) or bool(wt["multi"]) == (str(tt["count"]) == "multi")
	var freq_ok: bool = bool(wt["basic"]) or str(tt["freq"]) == "low"
	return s_ok and count_ok and freq_ok


## 棋子的武器触发器(插槽)：tags 带 equipment_payload 的
static func payload_triggers(u: UnitDef) -> Array[TriggerDef]:
	var r: Array[TriggerDef] = []
	for t: TriggerDef in u.triggers:
		if t.tags.has("equipment_payload"):
			r.append(t)
	return r


## 这只棋子能不能装：2 星、3 星都装得上(棋子主要在这两个星级用；灾星 2 星起不能装【双模】、2 星起能装红色)
static func can_equip(e: EquipmentDef, u: UnitDef) -> bool:
	for star: int in [2, 3]:
		if e.equip_problem(u, star) != "":
			return false
	return true


## 武器适配的棋子 id(进商店的，按 id 排)
static func fit_units(cat: Catalog, e: EquipmentDef) -> Array[String]:
	var r: Array[String] = []
	if e == null or e.basic or e.abilities.is_empty() or e.slot == "token":
		return r
	var wt: Dictionary = weapon_tags(e)
	var need: Array[String] = needs(e)
	for uid: String in cat.shop_unit_ids():
		var u: UnitDef = cat.get_unit(uid)
		if not can_equip(e, u):
			continue
		var ok := true
		for n: String in need:
			if not unit_has(u, n):
				ok = false
		if not ok:
			continue
		var any_match := false
		var conflict := false
		for t: TriggerDef in payload_triggers(u):
			if matches(t.fit, wt):
				any_match = true
			if not t.fit.is_empty() and not side_ok(t.fit, wt):
				conflict = true
		if any_match and not conflict and not e.fit_remove.has(uid):
			r.append(uid)
	for ua: String in e.fit_add:
		if not r.has(ua) and cat.get_unit(ua) != null and can_equip(e, cat.get_unit(ua)):
			r.append(ua)
	r.sort()
	return r
