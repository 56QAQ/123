class_name TipContent
extends RefCounted
## 提示/信息卡的内容构建：单位详情卡、武器提示、羁绊提示、关键词提示。全部是可读的"人话"。
## 版式(战术终端风格)：头像 + 中文名 + 英文名标注 + 斜切标签；各小节是"▌中文 + 英文标注"的标题条。

const CARD_W := 380.0

## 小节标题的英文标注
const SECTION_EN := {
	"ui.card.stats": "Attributes", "ui.card.passives": "Passive", "ui.card.equipment": "Weapon",
	"ui.card.triggers": "Trigger / Payload", "ui.card.payload": "Payload", "ui.card.mods": "Modifiers", "ui.card.fits": "Fits",
}


static func _section(key: String) -> Control:
	return UIKit.section(Loc.t(key), str(SECTION_EN.get(key, "")))


# ---------------------------------------------------------------- 单位卡
## unit: 若在战斗中传入 BUnit(读取实时数值)；否则用 def/star/weapon_id("" = 基础武器)临时构造
static func unit_card(cat: Catalog, def: UnitDef, star: int, weapon_id: String, live: BUnit = null, team: int = 0, perm: Dictionary = {}) -> Control:
	var bu: BUnit = live
	if bu == null:
		bu = BUnit.new()
		bu.setup(def, team, star, "preview")
		bu.perm_flat = perm.duplicate()
		bu.set_weapon(cat.resolve_weapon(def, weapon_id))
		bu.mark_dirty()
		bu.recompute()
		bu.hp = bu.get_stats().max_health
	var st: StatBlock = bu.get_stats()
	var root := UIKit.vbox(7)
	root.custom_minimum_size = Vector2(CARD_W, 0)
	# ---- 头部：头像 | 中文名 + 英文名 + 标签 + 星级 | 费用
	var top := UIKit.hbox(12)
	if UIKit.portraits.has(def.id):
		top.add_child(UIKit.portrait(def.id, Vector2(96, 74), def.faction_id))
	var title := UIKit.vbox(3)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head := UIKit.hbox(8)
	var name_l: Label = UIKit.label(Loc.t("unit.%s.name" % def.id), 22, UIKit.TEXT, true)
	head.add_child(name_l)
	head.add_child(UIKit.spacer(0, 0, true))
	var cost := UIKit.hbox(3)
	cost.add_child(UIKit.glyph("coin", Color.WHITE, 15.0))
	cost.add_child(UIKit.num(str(def.cost), 20, UIKit.GOLD))
	head.add_child(cost)
	title.add_child(head)
	title.add_child(UIKit.caption(Loc.t_in("en", "unit.%s.name" % def.id), 10, UIKit.ACCENT))
	var tags := UIKit.hbox(6)
	tags.add_child(UIKit.tag(Loc.t("color." + def.faction_id), GC.faction_color(def.faction_id)))
	tags.add_child(UIKit.tag(Loc.t("profession." + def.profession_id), UIKit.TEXT_DIM))
	tags.add_child(UIKit.tag(Loc.t("role." + def.role), UIKit.TEXT_DIM))
	for spt: String in def.special_traits:
		tags.add_child(UIKit.tag(Loc.t("special." + spt), Color("#ff7a3a")))       # 特殊标签(如火：以后的第三种羁绊标签)
	title.add_child(tags)
	title.add_child(UIKit.pips(star, UIKit.GOLD, 12.0))
	top.add_child(title)
	root.add_child(top)
	var flavor: Label = UIKit.label(Loc.t("unit.%s.desc" % def.id), 12, UIKit.TEXT_DIM)
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor.custom_minimum_size = Vector2(CARD_W - 8, 0)
	root.add_child(flavor)
	# ---- 数值：三列的"名称 数值"小格
	root.add_child(_section("ui.card.stats"))
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 3)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rows: Array = [
		["max_health", Describe.fmt(round(bu.hp)) + "/" + Describe.fmt(round(st.max_health)) if live != null else Describe.fmt(round(st.max_health))],
		["attack_power", Describe.fmt(round(st.attack_power))],
		["ability_power", Describe.fmt(round(st.ability_power))],
		["defense", Describe.fmt(round(st.defense))],
		["magic_resistance", Describe.fmt(round(st.magic_resistance))],
		["move_speed", Describe.fmt(st.move_speed)],
		["attack_range", Describe.fmt(st.attack_range)],
		["crit_chance", Describe.stat_value("crit_chance", st.crit_chance)],
		["attack_speed_multiplier", "x%s" % Describe.fmt(1.0 / st.attack_base_interval_seconds * st.attack_speed_multiplier)],
	]
	var extra: Array = ["physical_lifesteal", "damage_dealt_flat", "damage_taken_flat", "healing_done_pct", "health_regen_per_second"]
	for e: String in extra:
		if absf(st.get_stat(e)) > 0.0001:
			rows.append([e, Describe.stat_value(e, st.get_stat(e))])
	for r: Array in rows:
		var k: Label = UIKit.label(Loc.t("stat_short." + str(r[0])), 12, UIKit.TEXT_DIM)
		k.custom_minimum_size = Vector2(38, 0)
		grid.add_child(k)
		var vl: Label = UIKit.num(str(r[1]), 16, UIKit.TEXT)
		vl.custom_minimum_size = Vector2(66, 0)
		grid.add_child(vl)
	root.add_child(grid)
	# ---- 被动
	if not def.passives.is_empty() or def.normal_attack != null or Loc.has_key("unit.%s.note" % def.id):
		root.add_child(_section("ui.card.passives"))
		if Loc.has_key("unit.%s.note" % def.id):
			root.add_child(_text_line(Loc.t("unit.%s.note" % def.id), CARD_W))
		if def.normal_attack != null:
			root.add_child(_text_line(Loc.t("unit.%s.normal" % def.id), CARD_W))
		for a: AbilityDef in def.passives:
			var key := "unit.%s.passive.%s" % [def.id, a.id]
			if Loc.has_key(key):
				var line := UIKit.hbox(4)
				var txt0: String = Describe.star_text(Loc.t(key), star)
				if a.unlock_star > 1:
					# 星级解锁的被动：标出几星解锁；还没到星级时整行调暗
					var tag: String = "[color=%s]%s[/color] " % [UIKit.hx(UIKit.ACCENT), Loc.t("ui.card.unlock_star", ["★".repeat(a.unlock_star)])]
					txt0 = tag + txt0
					if star < a.unlock_star:
						txt0 = "[color=#7d8598]%s[/color]" % txt0
				# 另一个形态的被动 2(变奏节点)：整行调暗
				if a.effect_config.has("card_form") and str(a.effect_config["card_form"]) != def.form:
					txt0 = "[color=#7d8598]%s[/color]" % txt0
				line.add_child(UIKit.rich(txt0, 13, CARD_W - 8))
				root.add_child(line)
	# ---- 武器：大类(射程/普攻模组) + 可用大类
	root.add_child(_section("ui.card.equipment"))
	root.add_child(weapon_row(bu.weapon, def, star))
	# ---- 触发器(武器效果的触发面)
	var payload_triggers: Array[TriggerDef] = []
	for t: TriggerDef in def.triggers:
		if t.tags.has("equipment_payload"):
			payload_triggers.append(t)
	if not payload_triggers.is_empty():
		root.add_child(_section("ui.card.triggers"))
		var active: Array[EquipmentDef] = bu.active_payload_equipment()
		for t2: TriggerDef in payload_triggers:
			var tkey: String = "unit.%s.trigger.%s" % [def.id, t2.id]
			var s: String = Describe.star_text(Loc.t(tkey), star) if Loc.has_key(tkey) else Describe.trigger_sentence(t2, star)
			root.add_child(UIKit.rich("[color=%s]◆[/color] " % UIKit.hx(UIKit.ACCENT) + s, 13, CARD_W - 8))
			if not t2.fit.is_empty():
				root.add_child(trigger_fit_tags(t2))
			if active.is_empty():
				root.add_child(UIKit.rich("[color=#7d8598]    %s[/color]" % Loc.t("ui.card.no_equipment"), 12, CARD_W - 8))
			else:
				for e2: EquipmentDef in active:
					for a2: AbilityDef in e2.abilities:
						var txt: String = "    → [b]%s[/b]：%s" % [Loc.t("equipment.%s.name" % str(def.weapon_names.get(e2.id, e2.id))), Describe.ability_effect_text(a2, star)]
						var pv: float = Describe.preview_value(bu, t2)
						if not is_nan(pv) and a2.ability_class != "chip":
							var amount: float = a2.fixed_value if a2.ability_class == "bullet" else pv * a2.value_multiplier
							if a2.effect_type != "none" and not a2.effect_config.has("ally_effect"):
								txt += "  [color=#7dff9a](≈ %s)[/color]" % Describe.fmt(amount)
						root.add_child(UIKit.rich(txt, 12, CARD_W - 8))
	return root


## 特殊物品(不能佩戴，例如狩猎旗标)：名字 + "特殊物品"标签 + 说明 + 用法
static func _token_tip(e: EquipmentDef) -> Control:
	var root := UIKit.vbox(6)
	root.custom_minimum_size = Vector2(340, 0)
	var head := UIKit.hbox(10)
	head.add_child(weapon_slot_widget(e))
	var hv := UIKit.vbox(2)
	hv.add_child(UIKit.label(Loc.t("equipment.%s.name" % e.id), 19, UIKit.TEXT, true))
	hv.add_child(UIKit.caption(Loc.t_in("en", "equipment.%s.name" % e.id), 10, UIKit.ACCENT))
	hv.add_child(UIKit.tag(Loc.t("ui.card.token"), Color("#ff7a3a")))
	head.add_child(hv)
	root.add_child(head)
	root.add_child(UIKit.rich("[color=#c8d3e8]%s[/color]" % Loc.t("equipment.%s.desc" % e.id), 13, 320))
	if e.token == "hunt_mark":
		root.add_child(UIKit.rich("[color=%s]%s[/color]" % [UIKit.hx(UIKit.ACCENT), Loc.t("ui.tip.drag_flag")], 12, 320))
	return root


static func _text_line(t: String, w: float) -> Control:
	return UIKit.rich(t, 13, w - 8)


## 武器一栏：图标格(非基础武器可点击卸下) + 名称/大类 + 普攻模组 + 可用大类
static func weapon_row(w: EquipmentDef, def: UnitDef, star: int) -> Control:
	var row := UIKit.hbox(8)
	row.add_child(weapon_slot_widget(w))
	var info := UIKit.vbox(1)
	var title := UIKit.hbox(6)
	var nm: String = Loc.t("equipment.%s.name" % str(def.weapon_names.get(w.id, w.id))) if w != null else Loc.t("wclass.unarmed.name")
	title.add_child(UIKit.label(nm, 16, UIKit.TEXT, true))
	if w != null:
		title.add_child(UIKit.rich(Describe.weapon_class_text(w.class_id), 12, 120))
	info.add_child(title)
	var line: String = Describe.weapon_line(w.class_id if w != null else "", w, def)
	if w != null and w.basic:
		line = "[color=#8f96a3]%s · [/color]%s" % [Loc.t("ui.card.weapon_basic"), line]
	info.add_child(UIKit.rich("[color=#c8d3e8]%s[/color]" % line, 12, CARD_W - 70))
	info.add_child(UIKit.rich("[color=#7d8598]%s[/color]" % Describe.allowed_text(def), 11, CARD_W - 70))
	row.add_child(info)
	return row


## 武器格：已装备的(非基础)武器可点击卸下(由外部连接 gui_input)；基础武器只显示
static func weapon_slot_widget(eq: EquipmentDef) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(58, 58)
	var col: Color = UIKit.weapon_color(eq)
	var sb: StyleBoxFlat = UIKit.style(UIKit.BG_DEEP, 0, UIKit.BORDER, 1, 3)
	sb.shadow_size = 0
	sb.border_color = col if (eq != null and not eq.basic) else UIKit.LINE_STRONG
	sb.border_width_left = 3
	p.add_theme_stylebox_override("panel", sb)
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(cc)
	cc.add_child(UIKit.equipment_icon(eq, 50.0))
	if eq != null and not eq.basic:
		p.set_meta("equip_id", eq.id)
	p.set_meta("slot", 0)
	return p


# ---------------------------------------------------------------- 装备提示
static func equipment_tip(cat: Catalog, id: String, for_def: UnitDef = null) -> Control:
	var e: EquipmentDef = cat.get_equipment(id)
	if e != null and e.slot == "token":
		return _token_tip(e)
	var root := UIKit.vbox(6)
	root.custom_minimum_size = Vector2(340, 0)
	var head := UIKit.hbox(10)
	head.add_child(weapon_slot_widget(e))
	var hv := UIKit.vbox(2)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hn := UIKit.hbox(6)
	hn.add_child(UIKit.label(Loc.t("equipment.%s.name" % id), 19, UIKit.TEXT, true))
	hn.add_child(UIKit.spacer(0, 0, true))
	hn.add_child(UIKit.pips(e.cost, UIKit.GOLD, 10.0))
	hv.add_child(hn)
	hv.add_child(UIKit.caption(Loc.t_in("en", "equipment.%s.name" % id), 10, UIKit.ACCENT))
	var sub := UIKit.hbox(6)
	sub.add_child(UIKit.tag(Loc.t("color." + e.color_id), GC.faction_color(e.color_id)))
	sub.add_child(UIKit.tag(Loc.t("wclass.%s.name" % e.class_id), UIKit.TEXT_DIM))
	hv.add_child(sub)
	head.add_child(hv)
	root.add_child(head)
	root.add_child(UIKit.rich("[color=#c8d3e8]%s[/color]" % Describe.weapon_line(e.class_id, e), 12, 320))
	root.add_child(UIKit.rich("[color=#9aa3b5]%s[/color]" % Loc.t("wclass.%s.desc" % e.class_id), 12, 320))
	if not e.abilities.is_empty():
		root.add_child(_section("ui.card.payload"))
		root.add_child(UIKit.rich(Describe.equipment_text(e), 13, 320))
	var mods: String = Describe.equipment_mods(e)
	if mods != "":
		root.add_child(_section("ui.card.mods"))
		root.add_child(UIKit.rich("[color=#c8d3e8]%s[/color]" % mods, 12, 320))
	root.add_child(UIKit.rich("[color=#7d8598]%s[/color]" % Loc.t("equip_compat.%s" % e.color_id), 12, 320))
	if not e.basic and not e.abilities.is_empty():
		root.add_child(_section("ui.card.fits"))
		root.add_child(weapon_fit_tags(e))
		root.add_child(UIKit.rich(fit_units_text(cat, e, for_def), 12, 320))
	if for_def != null:
		var why: String = e.equip_problem(for_def)
		root.add_child(UIKit.label(Loc.t("ui.fits") if why == "" else Loc.t(why), 13, UIKit.GOOD if why == "" else UIKit.BAD, true))
		if why == "ui.err.weapon_class":
			root.add_child(UIKit.rich("[color=#9aa3b5]%s[/color]" % Describe.allowed_text(for_def), 12, 320))
	root.add_child(UIKit.rich("[color=#6d7588]%s[/color]" % Loc.t("ui.tip.payload_note"), 11, 320))
	return root


# ---------------------------------------------------------------- 适配标签(FitTags)
## 武器触发器的三组内置标签(对敌人 / 对队友 / 需要双模 · 对多个目标 / 对单个目标 · 高频 / 低频)，一行小标签
static func trigger_fit_tags(t: TriggerDef) -> Control:
	var row := UIKit.hbox(4)
	row.add_child(UIKit.spacer(14, 0))
	row.add_child(UIKit.tag(Loc.t("fit.tside." + str(t.fit.get("side", ""))), UIKit.KEYWORD, false, 10))
	row.add_child(UIKit.tag(Loc.t("fit.count." + str(t.fit.get("count", ""))), UIKit.TEXT_DIM, false, 10))
	row.add_child(UIKit.tag(Loc.t("fit.freq." + str(t.fit.get("freq", ""))), UIKit.TEXT_DIM, false, 10))
	return row


## 武器的三组内置标签(对敌人 / 对队友 / 提供双模 · 有无【群攻】 · 有无【基本】)，一行小标签
static func weapon_fit_tags(e: EquipmentDef) -> Control:
	var wt: Dictionary = FitTags.weapon_tags(e)
	var row := UIKit.hbox(4)
	row.add_child(UIKit.tag(Loc.t("fit.wside." + str(wt["side"])), UIKit.KEYWORD, false, 11))
	var mk: String = "any" if bool(wt.get("any_target", false)) else ("yes" if bool(wt["multi"]) else "no")
	row.add_child(UIKit.tag(Loc.t("fit.multi." + mk), UIKit.TEXT_DIM, false, 11))
	row.add_child(UIKit.tag(Loc.t("fit.basic." + ("yes" if bool(wt["basic"]) else "no")), UIKit.TEXT_DIM, false, 11))
	return row


## "适配角色：A、B、C"(正在看的那只棋子高亮)
static func fit_units_text(cat: Catalog, e: EquipmentDef, for_def: UnitDef = null) -> String:
	var ids: Array[String] = cat.fit_units(e.id)
	if ids.is_empty():
		return "[color=%s]%s%s[/color]" % [UIKit.hx(UIKit.TEXT_MUTE), Loc.t("ui.fit.label"), Loc.t("ui.fit.none")]
	var names: Array[String] = []
	for uid: String in ids:
		var nm: String = Loc.t("unit.%s.name" % uid)
		if for_def != null and for_def.id == uid:
			nm = "[b][color=%s]%s[/color][/b]" % [UIKit.hx(UIKit.GOOD), nm]
		names.append(nm)
	return "[color=%s]%s[/color][color=%s]%s[/color]" % [UIKit.hx(UIKit.TEXT_DIM), Loc.t("ui.fit.label"), UIKit.hx(UIKit.TEXT), Loc.t("ui.fit.sep").join(names)]


# ---------------------------------------------------------------- 羁绊提示
static func trait_tip(cat: Catalog, entry: Dictionary) -> Control:
	var t: TraitDef = entry["trait"]
	var count: int = int(entry["count"])
	var active: int = int(entry["tier"])
	var root := UIKit.vbox(6)
	root.custom_minimum_size = Vector2(340, 0)
	var head := UIKit.hbox(8)
	head.add_child(UIKit.faction_dot(t.member_filter, 20.0))
	var hv := UIKit.vbox(0)
	hv.add_child(UIKit.label(Loc.t("trait.%s.name" % t.id), 19, UIKit.TEXT, true))
	hv.add_child(UIKit.caption(Loc.t_in("en", "trait.%s.name" % t.id), 10, GC.faction_color(t.member_filter)))
	head.add_child(hv)
	head.add_child(UIKit.spacer(0, 0, true))
	head.add_child(UIKit.num("%d" % count, 26, UIKit.GOLD))
	root.add_child(head)
	root.add_child(UIKit.rich("[color=#9aa3b5]%s[/color]" % Loc.t("trait.%s.desc" % t.id), 12, 330))
	var members: Array = entry.get("members", [])
	if not members.is_empty():
		var names: Array[String] = []
		for m: Variant in members:
			names.append(Loc.t("unit.%s.name" % str(m)))
		root.add_child(UIKit.label(Loc.t("ui.trait.members") + ": " + ", ".join(names), 12, UIKit.TEXT_DIM))
	for th: int in t.thresholds:
		var on: bool = th == active
		var reached: bool = count >= th
		var col: String = "#ffd875" if on else ("#c8d3e8" if reached else "#6f778a")
		var line: String = "[color=%s][b]%d[/b]  %s[/color]" % [col, th, Loc.t("trait.%s.tier.%d" % [t.id, th])]
		var td: Dictionary = t.tiers.get(th, {})
		var ss: String = Describe.tier_stats(td)
		if ss != "":
			line += "\n[color=%s]    %s[/color]" % ["#9be8ff" if on else "#5f6a80", ss]
		root.add_child(UIKit.rich(line, 12, 330))
	return root


# ---------------------------------------------------------------- 关键词提示
static func keyword_tip(k: String) -> Control:
	var root := UIKit.vbox(4)
	root.custom_minimum_size = Vector2(260, 0)
	root.add_child(UIKit.label(Loc.t("keyword." + k), 16, UIKit.KEYWORD, true))
	root.add_child(UIKit.rich(Loc.t("keyword_desc." + k), 13, 250))
	return root
