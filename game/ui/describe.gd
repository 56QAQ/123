class_name Describe
extends RefCounted
## 把数据翻译成人话(BBCode)：触发器 → "每第 N 次…时，对…触发武器效果，触发数值 = …"，武器效果 → "造成 触发数值×4 魔法伤害"，
## 武器大类 → "射程 4 · 普攻 ×1 物理 · 间隔 0.83 秒"。
## 单位卡、装备提示、羁绊提示、战斗信息流都用它，保证界面文字与实际结算同源。

const KW_COLOR := "#5cb8ff"          # 关键词蓝(UIKit.bb 换成当前主题的 KEYWORD 色)
const VAL_COLOR := "#9be8ff"
const CLASS_HEX := {
	"bullet": "#f3c14f", "blade": "#e8505a", "amulet": "#4f86f0", "potion": "#4fc76b", "chip": "#a860ea", "tome": "#38d5ea",
}


static func fmt(x: float) -> String:
	if absf(x - roundf(x)) < 0.0001:
		return str(int(roundf(x)))
	var s: String = "%.2f" % x
	while s.ends_with("0"):
		s = s.substr(0, s.length() - 1)
	if s.ends_with("."):
		s = s.substr(0, s.length() - 1)
	return s


static func c(text: String, hex: String) -> String:
	return "[color=%s]%s[/color]" % [hex, text]


## 关键词：蓝字(不加【】)，包成 [url=kw:<id>] 链接，UIKit.rich 让它悬停时显示关键词详情
static func kw(k: String, v: float = 0.0) -> String:
	var name: String = Loc.t("keyword." + k)
	var t: String = name if v <= 0.0 else "%s %s" % [name, fmt(v)]
	return kw_link(k, t)


const STAR_COLOR := "#ffd23a"


## 手写文案里随星级变化的数值：{★a/b/c} → ★ + 当前星级的值；【关键词 a/b/c】→ 【关键词 ★当前值】(之后照常变成关键词链接)
static func star_text(text: String, star: int) -> String:
	var i: int = clampi(star, 1, 3) - 1
	var re := RegEx.new()
	re.compile("\\{★([^}]*)\\}")
	var out: String = text
	for m: RegExMatch in re.search_all(text):
		var parts: PackedStringArray = m.get_string(1).split("/")
		var v: String = parts[mini(i, parts.size() - 1)]
		out = out.replace(m.get_string(0), "[color=%s]★[/color]%s" % [STAR_COLOR, v])
	var re2 := RegEx.new()
	re2.compile("【([^】\\d]+?) ?(\\d+(?:/\\d+)+)】")
	for m2: RegExMatch in re2.search_all(out):
		var p2: PackedStringArray = m2.get_string(2).split("/")
		out = out.replace(m2.get_string(0), "【%s [color=%s]★[/color]%s】" % [m2.get_string(1).strip_edges(), STAR_COLOR, p2[mini(i, p2.size() - 1)]])
	return out


static func kw_link(k: String, text: String) -> String:
	return "[url=kw:%s][color=%s]%s[/color][/url]" % [k, KW_COLOR, text]


static var _kw_names: Array = []          # [[本地化名, id], ...]，长名在前
static var _kw_lang: String = ""


## 手写文本(单位被动描述等)里的【关键词 数值】→ 关键词链接；认不出是哪个关键词的只去掉括号、染蓝
static func link_keywords(text: String) -> String:
	if not text.contains("【"):
		return text
	if _kw_lang != Loc.lang or _kw_names.is_empty():
		_kw_lang = Loc.lang
		_kw_names.clear()
		for k: String in GC.KEYWORDS + GC.SYSTEM_KEYWORDS:
			_kw_names.append([Loc.t("keyword." + k), k])
		_kw_names.sort_custom(func(a: Array, b: Array) -> bool: return str(a[0]).length() > str(b[0]).length())
	var out := ""
	var i := 0
	while i < text.length():
		var a: int = text.find("【", i)
		if a < 0:
			out += text.substr(i)
			break
		var b: int = text.find("】", a)
		if b < 0:
			out += text.substr(i)
			break
		out += text.substr(i, a - i)
		# 去掉括号后紧贴前文(技能名、上一个关键词)会连成一串 → 前面空一格；标点后面不用
		if _needs_gap(out):
			out += " "
		var inner: String = text.substr(a + 1, b - a - 1)
		var id := ""
		for pair: Array in _kw_names:
			if inner.to_lower().begins_with(str(pair[0]).to_lower()):
				id = str(pair[1])
				break
		out += kw_link(id, inner) if id != "" else "[color=%s]%s[/color]" % [KW_COLOR, inner]
		i = b + 1
	return out


const _NO_GAP_AFTER := " 
	，。：；、（(:;,.!?！？…—“\"'「"


## out 的最后一个可见字符(跳过结尾的 BBCode 标签)是不是普通文字
static func _needs_gap(out: String) -> bool:
	var s: String = out
	while s.ends_with("]"):
		var k: int = s.rfind("[")
		if k < 0:
			break
		s = s.substr(0, k)
	return s != "" and not _NO_GAP_AFTER.contains(s[s.length() - 1])


static func value_bb(t: String) -> String:
	return "[color=%s]%s[/color]" % [VAL_COLOR, t]


# ---------------------------------------------------------------- 触发器
static func timing_text(trig: TriggerDef, star: int) -> String:
	var n: int = trig.threshold_for(star)
	var base: String = Loc.t("timing." + trig.timing)
	if trig.timing == "OnBattleFrame":
		var secs: float = float(n) * GC.FRAME_SECONDS
		return Loc.t("desc.every_seconds", [fmt(secs)])
	if n > 1:
		return Loc.t("desc.every_n", [n]) + base
	return base


static func target_text(trig: TriggerDef) -> String:
	var rule: String = trig.target_rule
	var base: String = Loc.t("target." + rule)
	if rule == "nearby_units" or rule == "nearby_event_target_units":
		base = Loc.t("target.nearby_" + trig.team_filter)
	elif rule == "all_enemies" or rule == "all_allies":
		base = Loc.t("target." + rule)
	return base


static func value_text(trig: TriggerDef, star: int) -> String:
	var r: float = trig.ratio_for(star)
	var f: float = trig.flat_for(star)
	var t: String
	match trig.base_value_mode:
		"fixed":
			t = fmt(f)
		"ability_keyword_value":
			t = Loc.t("value.ability_keyword_value", [Loc.t("keyword." + trig.base_value_keyword), fmt(r)])
		_:
			t = Loc.t("value." + trig.base_value_mode, [fmt(r)])
			if f != 0.0 and trig.base_value_mode != "fixed":
				t += " + %s" % fmt(f)
	return value_bb(t)


## 装备触发器的完整句子。has_equipment=false 时附带"需要装备才会生效"提示
static func trigger_sentence(trig: TriggerDef, star: int) -> String:
	var payload: String = Loc.t("desc.payload_equipment") if trig.tags.has("equipment_payload") else Loc.t("desc.payload_effect")
	return Loc.t("desc.trigger_sentence", [timing_text(trig, star), target_text(trig), payload, value_text(trig, star)])


# ---------------------------------------------------------------- 装备载荷 / 能力
static func effect_phrase(effect_type: String, amount_text: String) -> String:
	return Loc.t("effect." + effect_type, [amount_text])


static func ability_effect_text(a: AbilityDef, star: int = 1) -> String:
	var amount: String
	if a.ability_class == "bullet":
		amount = value_bb(fmt(a.fixed_value))
	else:
		amount = value_bb(Loc.t("desc.trigger_value_x", [fmt(a.value_multiplier)]))
	var parts: Array[String] = []
	# 前置效果(先给自己一个状态，再造成效果)
	var pre: String = ""
	for pe: Variant in a.effect_config.get("pre_effects", []):
		pre += Loc.t("desc.pre_status", [Loc.t("status." + str((pe as Dictionary).get("status_id", "")))])
	if a.effect_config.has("ally_effect") or a.effect_config.has("enemy_effect"):
		var ae: Dictionary = a.effect_config.get("ally_effect", {})
		var ee: Dictionary = a.effect_config.get("enemy_effect", {})
		if not ae.is_empty():
			parts.append(Loc.t("desc.on_ally", [effect_phrase(str(ae["effect_type"]), value_bb(Loc.t("desc.trigger_value_x", [fmt(float(ae.get("value_multiplier", 1.0)))])))]))
		if not ee.is_empty():
			parts.append(Loc.t("desc.on_enemy", [effect_phrase(str(ee["effect_type"]), value_bb(Loc.t("desc.trigger_value_x", [fmt(float(ee.get("value_multiplier", 1.0)))])))]))
	elif a.ability_class == "chip":
		var cfg: Dictionary = a.effect_config
		if cfg.has("value_from_target_max_health_pct"):
			parts.append(Loc.t("desc.chip_maxhp", [fmt(float(cfg["value_from_target_max_health_pct"]) * 100.0)]))
		if cfg.has("value_multiplier"):
			parts.append(Loc.t("desc.chip_mult", [fmt(float(cfg["value_multiplier"]))]))
	else:
		parts.append(effect_phrase(a.effect_type, amount))
	for ex: Variant in a.effect_config.get("extra_effects", []):
		var e: Dictionary = ex
		var who: String = Loc.t("target." + str(e.get("target", "target")))
		var amt2: String = value_bb(fmt(float(e.get("fixed_value", 0.0))))
		if str(e.get("effect_type", "")) == "stat_status":
			amt2 = value_bb(Loc.t("desc.status_haste"))
		parts.append(Loc.t("desc.extra", [who, effect_phrase(str(e.get("effect_type", "none")), amt2)]))
	var text: String = pre + ("；".join(parts) if Loc.lang == "zh" else "; ".join(parts))
	if a.effect_config.has("scale_by_missing_health"):
		text += " " + Loc.t("desc.scale_missing", [fmt(float(a.effect_config["scale_by_missing_health"]) * 100.0)])
	if bool(a.effect_config.get("overheal_to_shield", false)):
		text += Loc.t("desc.overheal_shield", [fmt(float(a.effect_config.get("shield_cap_pct", 1.0)) * 100.0)])
	if a.effect_config.has("mult_if_source_hp_below"):
		var hb: Dictionary = a.effect_config["mult_if_source_hp_below"]
		var pct: String = fmt(float(hb.get("ratio", 0.1)) * 100.0)
		var mul: String = value_bb(fmt(float(hb.get("mult", 1.0))))
		text += Loc.t("desc.low_hp_mult", [pct, mul] if Loc.lang == "zh" else [mul, pct])
	if bool(a.effect_config.get("as_normal_attack", false)):
		text += Loc.t("desc.as_normal_attack")
	# 冷却(带【基本】的不受冷却限制)
	if a.cooldown > 0.0 and not a.has_keyword("basic"):
		text = Loc.t("desc.cooldown", [fmt(a.cooldown)]) + text
	return text


static func keyword_tags(a: AbilityDef, star: int = 1) -> String:
	var out: Array[String] = []
	for k: String in a.keywords:
		if k == "basic" or k == "normal_attack":
			continue
		out.append(kw(k, a.keyword_value_f(k, star, 0.0)))
	return " ".join(out)


static func equipment_text(e: EquipmentDef) -> String:
	var lines: Array[String] = []
	for a: AbilityDef in e.abilities:
		var line: String = rule_tag(a.ability_class)
		for xr: Variant in a.effect_config.get("extra_rules", []):
			line += rule_tag(str(xr))
		line += " " + ability_effect_text(a)
		var tags: String = keyword_tags(a)
		if tags != "":
			line += "  " + tags
		lines.append(line)
	return "\n".join(lines)


## 载荷结算规则的小标签，如〔固定值〕
static func rule_tag(cls: String) -> String:
	return "[color=%s]〔%s〕[/color]" % [CLASS_HEX.get(cls, "#ffffff"), Loc.t("class." + cls)]


static func class_rule(cls: String) -> String:
	return Loc.t("classrule." + cls)


## 武器大类名(带颜色)
static func weapon_class_text(cls: String) -> String:
	if cls == "":
		return "[color=#8f96a3][b]%s[/b][/color]" % Loc.t("wclass.unarmed.name")
	return "[color=#ffe0a8][b]%s[/b][/color]" % Loc.t("wclass.%s.name" % cls)


## 武器大类的普攻模组：射程 · 普攻倍率与伤害类型 · 基础攻击间隔
## e(可选)：这把武器改了射程(如"攻击范围归零")时显示改过的射程
static func weapon_line(cls: String, e: EquipmentDef = null, def: UnitDef = null) -> String:
	var wc: Dictionary = GC.weapon_class(cls)
	if wc.is_empty():
		return Loc.t("ui.card.unarmed")
	if def != null and def.wclass_overrides.has(cls):
		# 这个棋子自己的普攻节奏(炽照节点的拔刀连斩：间隔 1 秒、一刀 ×0.8)
		wc = wc.duplicate()
		wc.merge(def.wclass_overrides[cls], true)
	var rng: float = float(wc["range"])
	if e != null:
		rng = (rng + float(e.flat_mods.get("attack_range", 0.0))) * (1.0 + float(e.pct_mods.get("attack_range", 0.0)))
	var dk: String = Loc.t("dmgkind." + str(wc["dmg"]))
	if def != null and def.na_scaling == "ability_power":
		dk = Loc.t("dmgkind.magic") + Loc.t("ui.card.by_ap")       # 普攻按法强算(灾星节点)
	var line: String = Loc.t("ui.card.weapon_line", [fmt(maxf(0.0, rng)), fmt(float(wc["na_mult"])), dk,
		fmt(snappedf(float(wc["interval"]), 0.01))])
	var tags: Array[String] = []
	var nk: Dictionary = wc.get("na_keywords", {})
	for k: String in nk:
		tags.append(kw(k, int(nk[k])))
	if not tags.is_empty():
		line += "  " + " ".join(tags)
	return line


## 单位可用的武器大类
static func allowed_text(def: UnitDef) -> String:
	if def.weapon_classes.is_empty():
		return Loc.t("ui.card.allowed_any")
	var names: Array[String] = []
	for c2: String in def.weapon_classes:
		names.append(Loc.t("wclass.%s.name" % c2))
	return Loc.t("ui.card.allowed", [" / ".join(names)])


static func stat_value(id: String, v: float) -> String:
	match id:
		"crit_chance", "damage_dealt_pct", "damage_taken_pct", "healing_done_pct", "healing_received_pct", \
		"physical_percent_penetration", "magic_percent_penetration", "physical_lifesteal", "spell_lifesteal", "omnivamp":
			return "%d%%" % int(round(v * 100.0))
		"crit_damage":
			return "x%s" % fmt(v)
		"attack_base_interval_seconds":
			return "%ss" % fmt(v)
		"attack_speed_multiplier":
			return "x%s" % fmt(v)
		"health_regen_per_second":
			return "%s/s" % fmt(v)
		_:
			return fmt(v)


## 装备属性加成一行行文字
static func equipment_mods(e: EquipmentDef) -> String:
	var parts: Array[String] = []
	for k: String in e.flat_mods.keys():
		var v: float = float(e.flat_mods[k])
		parts.append("%s %s%s" % [Loc.t("stat." + k), "+" if v >= 0.0 else "", stat_value(k, v)])
	for k2: String in e.pct_mods.keys():
		var v2: float = float(e.pct_mods[k2])
		parts.append("%s +%d%%" % [Loc.t("stat." + k2), int(round(v2 * 100.0))])
	return "  ".join(parts)


static func tier_stats(td: Dictionary) -> String:
	var parts: Array[String] = []
	var stats: Dictionary = td.get("stats", {})
	for k: String in (stats.get("flat", {}) as Dictionary).keys():
		var v: float = float((stats["flat"] as Dictionary)[k])
		parts.append("%s %s%s" % [Loc.t("stat." + k), "+" if v >= 0.0 else "", stat_value(k, v)])
	for k2: String in (stats.get("pct", {}) as Dictionary).keys():
		parts.append("%s +%d%%" % [Loc.t("stat." + k2), int(round(float((stats["pct"] as Dictionary)[k2]) * 100.0))])
	return "  ".join(parts)


## 单位当前数值下，某触发器"触发值"的预览(只支持不依赖事件的模式，其余返回空串)
static func preview_value(unit: BUnit, trig: TriggerDef) -> float:
	var st: StatBlock = unit.get_stats()
	var r: float = trig.ratio_for(unit.star)
	var f: float = trig.flat_for(unit.star)
	match trig.base_value_mode:
		"fixed":
			return f
		"attack_ratio":
			return st.attack_power * r + f
		"ability_power_ratio":
			return st.ability_power * r + f
		"attack_times_ability_power_pct":
			return st.attack_power * (1.0 + st.ability_power / 100.0) * r + f
		"flat_times_ability_power_pct":
			return f * (1.0 + st.ability_power / 100.0)
		"defense_ratio":
			return st.defense * r + f
		"max_health_ratio":
			return st.max_health * r + f
		_:
			return NAN
