class_name TraitRuntime
extends RefCounted
## 羁绊(颜色系统)计算：
##  · 阵营人数 = 该队"不同单位 id"的数量(重复棋子不重复计数)，混色单位同时计入其贡献的所有阵营
##  · 每一个贡献该阵营的棋子(包括重复副本)都是受益者
##  · 档位效果 = 属性加成 + "触发器+能力"配对(tag trait_payload)，战斗开始时挂到受益单位上

## defs: Array[UnitDef]（一个队伍）。返回 [{trait, count, tier, next, members:[unit_ids], beneficiary_idx:[i...]}]，仅含 count>0 的羁绊
static func compute(cat: Catalog, defs: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var trait_ids: Array = cat.traits.keys()
	trait_ids.sort()
	for tid: String in trait_ids:
		var t: TraitDef = cat.traits[tid]
		var uniq: Dictionary = {}
		var benef: Array[int] = []
		for i in range(defs.size()):
			var d: UnitDef = defs[i] as UnitDef
			if d == null or d.summon_only:
				continue
			if _is_member(t, d):
				uniq[d.id] = true
				benef.append(i)
		if uniq.is_empty():
			continue
		var count: int = uniq.size()
		out.append({"trait": t, "count": count, "tier": t.active_tier(count), "next": t.next_threshold(count),
			"members": uniq.keys(), "beneficiary_idx": benef})
	return out


static func _is_member(t: TraitDef, d: UnitDef) -> bool:
	match t.category:
		"faction":
			return GC.faction_contributions(d.faction_id).has(t.member_filter)
		"profession":
			return d.profession_id == t.member_filter
		_:
			return d.special_traits.has(t.member_filter)


## 战斗开始：把档位效果落到单位上。返回各队报告供 UI 使用
static func apply_to_team(b: Battle, team: int) -> Array[Dictionary]:
	var members: Array[BUnit] = []
	var defs: Array = []
	for u: BUnit in b.units:
		if u.team == team and not u.is_summon:
			members.append(u)
			defs.append(u.def)
	var report: Array[Dictionary] = compute(b.catalog, defs)
	for r: Dictionary in report:
		var t: TraitDef = r["trait"]
		var tier: int = int(r["tier"])
		if tier <= 0:
			continue
		var td: Dictionary = t.tiers.get(tier, {})
		for idx: int in r["beneficiary_idx"]:
			var u: BUnit = members[idx]
			apply_tier_to_unit(u, t, tier)
	return report


static func apply_tier_to_unit(u: BUnit, t: TraitDef, tier: int) -> void:
	var td: Dictionary = t.tiers.get(tier, {})
	if td.is_empty():
		return
	var stats: Dictionary = td.get("stats", {})
	if stats.has("flat"):
		u.trait_flat[t.id] = (stats["flat"] as Dictionary).duplicate()
	if stats.has("pct"):
		u.trait_pct[t.id] = (stats["pct"] as Dictionary).duplicate()
	for pair: Dictionary in td.get("pairs", []):
		u.runtime_triggers.append(pair["trigger"])
		u.runtime_abilities.append(pair["ability"])
	u.mark_dirty()
