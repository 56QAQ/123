class_name FeedFormat
extends RefCounted
## 战斗信息流的文字格式：让玩家看清 "哪个单位的哪个触发器 → 触发了哪把武器的效果 → 造成了什么效果"。


static func _name(u: BUnit) -> String:
	if u == null:
		return "?"
	var col: String = "#7fc8ff" if u.team == GC.TEAM_PLAYER else "#ff8a8a"
	return "[color=%s][b]%s[/b][/color]" % [col, Loc.t("unit.%s.name" % u.def.id)]


static func format(cat: Catalog, e: Dictionary) -> String:
	match str(e["kind"]):
		"trigger":
			var u: BUnit = e["unit"]
			var trig: TriggerDef = _find_trigger(u, str(e["trigger"]))
			var when := ""
			if trig != null:
				when = Describe.timing_text(trig, u.star)
			var eq: Array = e["equips"]
			var what := ""
			if not eq.is_empty():
				var ed: EquipmentDef = cat.get_equipment(str(eq[0]))
				what = "%s [b]%s[/b]" % [Describe.weapon_class_text(ed.class_id), Loc.t("equipment.%s.name" % ed.id)]
			elif (e["surfaces"] as Array).has("trait"):
				what = "[color=#9be8ff]%s[/color]" % Loc.t("fx.trait")
			return "%s  [color=#ffd875]◆[/color] [color=#c8d3e8]%s[/color] → %s" % [_name(u), when, what]
		"damage":
			var kind_key := "dmgkind." + str(e["dmg_kind"])
			var crit: String = " [color=#ffd23a]!![/color]" if bool(e.get("crit", false)) else ""
			return "[color=#7d8598]      → %s %s %s → %s[/color]%s" % [_amount(float(e["amount"])), Loc.t(kind_key), Loc.t("fx.damage_word"), _plain(e["dst"] as BUnit), crit]
		"heal":
			return "[color=#7d8598]      → [/color][color=#7dff9a]+%s[/color] [color=#7d8598]%s → %s[/color]" % [_amount(float(e["amount"])), Loc.t("fx.heal_word"), _plain(e["dst"] as BUnit)]
		"awakened":
			return "%s  [color=#ffd875]★ %s[/color]" % [_name(e["unit"] as BUnit), Loc.t("fx.awakened")]
		"death":
			return "%s  [color=#8a8fa0]%s[/color]" % [_name(e["unit"] as BUnit), Loc.t("fx.died")]
	return ""


static func _plain(u: BUnit) -> String:
	return Loc.t("unit.%s.name" % u.def.id) if u != null else "?"


static func _amount(x: float) -> String:
	return Describe.fmt(round(x))


static func _find_trigger(u: BUnit, id: String) -> TriggerDef:
	for t: TriggerDef in u.all_triggers():
		if t.id == id:
			return t
	return null
