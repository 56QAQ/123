class_name ReportNames
extends RefCounted
## 战报里"来源"的显示名(界面层)：BattleReport 只存 (单位, surface, ability, equip)，这里查文本。
## 返回 {name, kind, unknown}；kind = na / passive / weapon / trait / status / terrain / regen / other(界面上的小标签)。
## 新技能查不到名字时会落到"其他"——跑 tools/report_probe.gd 能列出所有查不到的来源。

## 没有自己文本键的特殊来源 → 借用的文本键
const SPECIAL := {"glory_magic": "status.glory", "glory_save": "status.glory", "burn_to_heal": "status.lust_regrowth"}
const TERRAIN := ["burning_ruin", "ember", "tram", "fire_arc"]


static func source(cat: Catalog, def_id: String, surface: String, ability: String, equip: String) -> Dictionary:
	var ab: String = ability.get_slice("#", 0)
	if surface == "normal_attack":
		return _r(Loc.t("ui.report.src_na"), "na")
	if equip != "" and Loc.has_key("equipment.%s.name" % equip):
		return _r(Loc.t("equipment.%s.name" % equip), "weapon")
	if Loc.has_key("ui.report.src." + ab):
		return _r(Loc.t("ui.report.src." + ab), "passive")
	if ab.begins_with("terrain_"):
		for k: String in TERRAIN:
			if ab.begins_with("terrain_" + k):
				return _r(Loc.t("ui.report.terrain_" + k), "terrain")
	if surface == "lifesteal":
		return _r(Loc.t("ui.report.src_lifesteal"), "regen")
	if surface == "trait":
		var tid: String = _trait_of(cat, ab)
		if tid != "":
			return _r(Loc.t("trait.%s.name" % tid), "trait")
	if SPECIAL.has(ab):
		return _r(Loc.t(str(SPECIAL[ab])), "passive")
	if surface == "status" and Loc.has_key("status." + ab):
		return _r(Loc.t("status." + ab), "status")
	var pn: String = passive_name(cat, def_id, ab)
	if pn != "":
		return _r(pn, "passive")
	if Loc.has_key("status." + ab):
		return _r(Loc.t("status." + ab), "status" if surface == "status" else "regen")
	return {"name": Loc.t("ui.report.src_other"), "kind": "other", "unknown": true}


static func _r(n: String, kind: String) -> Dictionary:
	return {"name": n, "kind": kind, "unknown": false}


## 被动的名字：单位卡上那条被动文本开头的粗体名。同一条被动拆成好几个能力(清心符 = 治疗 + 驱散)时，
## 只有第一个能力有文本键——按能力 id 的公共前缀找回那一条(前缀要比单位 id 长，免得认错到别的被动)
static func passive_name(cat: Catalog, def_id: String, ab: String) -> String:
	var d: UnitDef = cat.get_unit(def_id) if def_id != "" else null
	if d == null:
		return ""
	var key: String = "unit.%s.passive.%s" % [def_id, ab]
	if Loc.has_key(key):
		return _bold(Loc.t(key))
	var segs: PackedStringArray = ab.split("_")
	var need: int = def_id.split("_").size() + 1
	var best := ""
	var best_n := 0
	for pa: AbilityDef in d.passives:
		var k2: String = "unit.%s.passive.%s" % [def_id, pa.id]
		if not Loc.has_key(k2):
			continue
		var ps: PackedStringArray = pa.id.split("_")
		var n := 0
		while n < mini(ps.size(), segs.size()) and ps[n] == segs[n]:
			n += 1
		if n >= need and n > best_n:
			best_n = n
			best = _bold(Loc.t(k2))
	return best


static func _bold(t: String) -> String:
	var i: int = t.find("[b]")
	var j: int = t.find("[/b]")
	if i >= 0 and j > i:
		return t.substr(i + 3, j - i - 3)
	return t.get_slice("：", 0).get_slice(":", 0).left(16)


## 羁绊能力属于哪个羁绊
static func _trait_of(cat: Catalog, ab: String) -> String:
	for tid: String in cat.traits.keys():
		var t: TraitDef = cat.traits[tid]
		for th: int in t.tiers.keys():
			for p: Dictionary in (t.tiers[th] as Dictionary).get("pairs", []):
				var a: AbilityDef = p["ability"]
				if a != null and a.id == ab:
					return tid
	return ""


## 单位的显示名(施加者为空 = 环境：地形 / 战场机制)
static func unit_name(def_id: String) -> String:
	return Loc.t("unit.%s.name" % def_id) if def_id != "" else Loc.t("ui.report.env")
