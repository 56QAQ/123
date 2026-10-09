class_name TraitDef
extends RefCounted
## 羁绊(阵营/职业/特殊)：按成员人数分档，每档给出 属性加成 + 若干"触发器+能力"配对。
## 配对会在战斗开始时挂到每个受益单位上，走与单位/装备同一条触发管线(tag = trait_payload)。

var id: String = ""
var category: String = "faction"       # faction / profession / special
var member_filter: String = ""         # 阵营/职业 id
var thresholds: Array[int] = []
var tiers: Dictionary = {}             # threshold -> {stats:{flat:{},pct:{}}, pairs:[{trigger,ability}], text_key}
var permanent_growth: Dictionary = {}  # threshold -> {stat: amount}  (eternal：战后永久成长)


static func from_dict(d: Dictionary) -> TraitDef:
	var t := TraitDef.new()
	t.id = str(d.get("id", ""))
	t.category = str(d.get("trait_category", d.get("category", "faction")))
	t.member_filter = str(d.get("member_trait_filter", d.get("member_filter", "")))
	for th: Variant in d.get("thresholds", []):
		t.thresholds.append(int(th))
	var raw: Variant = d.get("tiers", {})
	if raw is Dictionary:
		for k: Variant in (raw as Dictionary).keys():
			var td: Dictionary = (raw as Dictionary)[k]
			var tier := {"stats": (td.get("stats", {}) as Dictionary).duplicate(true), "pairs": []}
			for p: Variant in td.get("pairs", []):
				if p is Dictionary:
					(tier["pairs"] as Array).append({
						"trigger": TriggerDef.from_dict((p as Dictionary).get("trigger", {})),
						"ability": AbilityDef.from_dict((p as Dictionary).get("ability", {})),
					})
			tier["growth"] = (td.get("growth", {}) as Dictionary).duplicate(true)
			t.tiers[int(k)] = tier
	return t


## 返回 <= count 的最高档，0 = 未激活
func active_tier(count: int) -> int:
	var best := 0
	for th: int in thresholds:
		if count >= th and th > best:
			best = th
	return best


func next_threshold(count: int) -> int:
	for th: int in thresholds:
		if th > count:
			return th
	return 0


func validate() -> Array[String]:
	var errs: Array[String] = []
	if id == "":
		errs.append("trait id is required")
	for th: int in thresholds:
		if not tiers.has(th):
			errs.append("trait %s: threshold %d has no tier data" % [id, th])
	for th2: Variant in tiers.keys():
		for pair: Dictionary in (tiers[th2] as Dictionary)["pairs"]:
			var trig: TriggerDef = pair["trigger"]
			var ab: AbilityDef = pair["ability"]
			errs.append_array(trig.validate())
			errs.append_array(ab.validate())
			if not trig.tags.has("trait_payload"):
				errs.append("trait %s: trigger %s must carry the trait_payload tag" % [id, trig.id])
			if not trig.can_pair(ab):
				errs.append("trait %s: trigger %s cannot pair with ability %s" % [id, trig.id, ab.id])
	return errs
