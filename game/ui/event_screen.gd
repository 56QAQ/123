class_name EventScreen
extends Control
## 事件界面(《杀戮尖塔》式)：左边一大块是这个事件的实际场景(EventStage，3D 体素场景 + 火焰粒子，镜头慢慢摆)，
## 下沿压着事件标题；右边是正文和选项。选项按钮上写着效果(损失红字、收益绿字)，条件不满足时灰掉并写明需要什么、现在差多少。
## 选了之后选项换成结果：结果文字 + 实际得到了什么 + 「继续」(遇到战斗是「迎战」)。
## 逻辑都在 Run(event_choose / event_continue)；这里只发信号。

signal choose(i: int)
signal proceed

var run: Run
var cat: Catalog
var event_id: String = ""
var stage: EventStage
var _right: VBoxContainer
var _opt_buttons: Array[Button] = []


func setup(p_run: Run) -> void:
	run = p_run
	cat = run.catalog
	event_id = str(run.event_state.get("id", ""))


func _ready() -> void:
	UIKit.ensure()
	theme = UIKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ev: Dictionary = run.event_def()
	var col: Color = CityOverworld.TYPE_COLORS.get("event", UIKit.ACCENT)
	# ---- 左上角：标签 + 稀有度
	var head := UIKit.hbox(12)
	head.position = Vector2(64, 34)
	add_child(head)
	head.add_child(UIKit.glyph("n_event", col, 34.0))
	var hv := UIKit.vbox(-2)
	hv.add_child(UIKit.label(Loc.t("ui.node_type.event"), 22, UIKit.TEXT, true))
	hv.add_child(UIKit.caption("Event · " + Loc.t_in("en", "ui.event.header"), 10, col))
	head.add_child(hv)
	head.add_child(UIKit.spacer(16, 0))
	var rv := UIKit.vbox(2)
	rv.add_child(UIKit.caption(Loc.t("ui.event.rarity") + " · Rarity", 10, UIKit.TEXT_DIM))
	rv.add_child(UIKit.pips(int(ev.get("rarity", 1)), UIKit.GOLD, 12.0))
	head.add_child(rv)
	# ---- 左：场景
	var frame: ArkPanel = UIKit.ark_panel(0, "top", 14, UIKit.BG_DEEP, col)
	frame.corners = true
	frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	frame.position = Vector2(64, 100)
	frame.custom_minimum_size = Vector2(1040, 800)
	frame.clip_contents = true
	add_child(frame)
	# PanelContainer 会把子节点撑满：场景和标题条放进一个普通 Control 里，各自用锚点摆
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(1040, 800)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(holder)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(svc)
	stage = EventStage.new()
	stage.setup(str(ev.get("scene", "quiet")), Vector2i(1040, 800), cat, ev.get("props", []), ev.get("cam", {}), str(run.chapter.get("theme", "red")))
	svc.add_child(stage)
	# 标题压在画面下沿：一条渐暗的底 + 大字
	var band := ColorRect.new()
	band.color = Color(0, 0, 0, 0.55)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	band.offset_top = -124
	holder.add_child(band)
	var tv := UIKit.vbox(-4)
	tv.position = Vector2(34, 22)
	band.add_child(tv)
	tv.add_child(UIKit.caption(Loc.t_in("en", "event.%s.title" % event_id).to_upper(), 13, col))
	var tl: Label = UIKit.label(Loc.t("event.%s.title" % event_id), 48, UIKit.TEXT, true)
	UIKit.outlined(tl, 8)
	tv.add_child(tl)
	# ---- 右：正文 + 选项 / 结果
	var rp: ArkPanel = UIKit.ark_panel(26, "top", 14, Color(UIKit.BG_DEEP.r, UIKit.BG_DEEP.g, UIKit.BG_DEEP.b, 0.94), col)
	rp.corners = true
	rp.set_anchors_preset(Control.PRESET_TOP_LEFT)
	rp.position = Vector2(1128, 100)
	rp.custom_minimum_size = Vector2(728, 800)
	add_child(rp)
	_right = UIKit.vbox(14)
	rp.add_child(_right)
	refresh()


## 选了选项之后只刷新右边(场景不重建)
func refresh() -> void:
	for ch: Node in _right.get_children():
		ch.queue_free()
	_opt_buttons.clear()
	var body: String = Loc.t("event.%s.body" % event_id).replace("\n", "\n\n")
	_right.add_child(UIKit.rich("[color=%s]%s[/color]" % [UIKit.hx(UIKit.TEXT_SOFT), body], 17, 676.0))
	_right.add_child(UIKit.spacer(0, 4))
	var ev: Dictionary = run.event_def()
	var opts: Array = ev.get("options", [])
	var chosen: int = int(run.event_state.get("option", -1))
	if chosen < 0:
		for i in range(opts.size()):
			var b: Button = _option_button(i, opts[i])
			_right.add_child(b)
			_opt_buttons.append(b)
		return
	# ---- 结果(场景也可以跟着变：电车开走)
	if stage != null:
		stage.on_outcome(str(run.event_state.get("outcome", "")))
	_right.add_child(UIKit.label("▶ " + Loc.t("event.%s.opt.%s" % [event_id, str((opts[chosen] as Dictionary).get("id", ""))]), 15, UIKit.TEXT_DIM, true))
	_right.add_child(UIKit.section(Loc.t("ui.event.result"), "Outcome"))
	var oid: String = str(run.event_state.get("outcome", ""))
	var res_txt: String = Loc.t("event.%s.res.%s" % [event_id, oid]).replace("\n", "\n\n")
	_right.add_child(UIKit.rich("[color=%s]%s[/color]" % [UIKit.hx(UIKit.TEXT), res_txt], 17, 676.0))
	var effs: Array = []
	var copt: Dictionary = opts[chosen]
	for oc: Dictionary in Events.option_outcomes(copt, maxi(0, Events.picked(run, str(copt.get("id", ""))) - 1)):
		if str(oc.get("id", "")) == oid:
			effs = oc.get("effects", [])
	var gains: Array = run.event_state.get("gains", [])
	if not effs.is_empty() or not gains.is_empty():
		_right.add_child(_gains_row(effs, gains))
	_right.add_child(UIKit.spacer(0, 0, true))
	var battle: bool = run.event_state.has("battle")
	var again: bool = bool(run.event_state.get("repeat", false)) and not battle
	var br := UIKit.hbox(0)
	br.add_child(UIKit.spacer(0, 0, true))
	var cb: Button = UIKit.action_button(Loc.t("ui.event.fight") if battle else (Loc.t("ui.event.back") if again else Loc.t("ui.event.continue")),
		"Fight" if battle else ("Back" if again else "Continue"), Vector2(260, 72), "danger" if battle else "primary")
	cb.pressed.connect(func() -> void: proceed.emit())
	UIKit.add_key_hint(cb, "SPACE", "tl")
	br.add_child(cb)
	_right.add_child(br)


## 一个选项：编号 + 选项文字 + 效果(损失红 / 收益绿) + 条件(不满足时红字，满足时写出是谁)
func _option_button(i: int, opt: Dictionary) -> Button:
	var chk: Dictionary = run.event_option_check(i)
	var ok: bool = bool(chk["ok"])
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(676, 0)
	var accent: Color = UIKit.ACCENT if ok else UIKit.BORDER
	var n: StyleBoxFlat = UIKit.style(Color(UIKit.BG.r, UIKit.BG.g, UIKit.BG.b, 0.9), 0, accent, 1, 12)
	n.border_width_left = 4
	n.shadow_size = 0
	var h: StyleBoxFlat = n.duplicate() as StyleBoxFlat
	h.bg_color = UIKit.BG_SOFT
	h.border_width_left = 7
	var d: StyleBoxFlat = n.duplicate() as StyleBoxFlat
	d.bg_color = Color(UIKit.BG_DEEP.r, UIKit.BG_DEEP.g, UIKit.BG_DEEP.b, 0.7)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("disabled", d)
	b.disabled = not ok
	var row := UIKit.hbox(14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(UIKit.num("%02d" % (i + 1), 22, UIKit.ACCENT if ok else UIKit.TEXT_MUTE))
	var v := UIKit.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var oid: String = str(opt.get("id", ""))
	var lh := UIKit.hbox(10)
	lh.add_child(UIKit.label(Loc.t("event.%s.opt.%s" % [event_id, oid]), 19, UIKit.TEXT if ok else UIKit.TEXT_MUTE, true))
	if opt.has("repeat"):
		var mx: int = int((opt["repeat"] as Dictionary).get("max", 0))
		var done: int = Events.picked(run, oid)
		if done < mx:
			var rc: Label = UIKit.caption(Loc.t("ui.event.repeat_n", [done + 1, mx]), 11, UIKit.ACCENT if ok else UIKit.TEXT_MUTE)
			rc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			lh.add_child(rc)
	v.add_child(lh)
	v.add_child(UIKit.rich(_option_hint(opt, ok), 14, 590.0))
	for rq: Dictionary in chk["reqs"]:
		v.add_child(UIKit.rich(_req_text(rq), 13, 590.0))
	row.add_child(v)
	if not ok:
		var lk: Glyph = UIKit.glyph("lock", UIKit.TEXT_MUTE, 22.0)
		lk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(lk)
	# 按钮高度跟着内容走：用一个边距容器包着
	var mc := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, 14 if side == "left" or side == "right" else 10)
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mc.add_child(row)
	b.add_child(mc)
	_ignore(mc)
	mc.minimum_size_changed.connect(func() -> void: b.custom_minimum_size.y = mc.get_combined_minimum_size().y)
	b.custom_minimum_size.y = 84.0
	var ii: int = i
	b.pressed.connect(func() -> void: choose.emit(ii))
	return b


func _ignore(n: Node) -> void:
	for ch: Node in n.get_children():
		if ch is Control:
			(ch as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore(ch)


## 选项的效果说明：一个结果 = 列出效果；几个结果 = 每个写概率；可重复的选项按这是第几次选；hidden = 只写「？？？」
func _option_hint(opt: Dictionary, ok: bool) -> String:
	if bool(opt.get("hidden", false)):
		return "[color=%s]%s[/color]" % [UIKit.hx(UIKit.GOLD if ok else UIKit.TEXT_MUTE), Loc.t("ui.event.hidden")]
	var outs: Array = Events.option_outcomes(opt, Events.picked(run, str(opt.get("id", ""))))
	var total := 0.0
	for o: Dictionary in outs:
		total += float(o.get("w", 1))
	var parts: Array[String] = []
	for o2: Dictionary in outs:
		var t: String = effects_text(o2.get("effects", []), ok)
		if outs.size() > 1:
			t = Loc.t("ui.event.eff_chance", [int(round(100.0 * float(o2.get("w", 1)) / maxf(0.001, total))), t])
		parts.append(t)
	return ("  [color=%s]/[/color]  " % UIKit.hx(UIKit.TEXT_MUTE)).join(parts)


func effects_text(effs: Array, ok: bool = true) -> String:
	var bad: String = UIKit.hx(UIKit.BAD if ok else UIKit.TEXT_MUTE)
	var good: String = UIKit.hx(UIKit.GOOD if ok else UIKit.TEXT_MUTE)
	var warn: String = UIKit.hx(UIKit.GOLD if ok else UIKit.TEXT_MUTE)
	var r: Array[String] = []
	for e: Dictionary in effs:
		match str(e.get("type", "")):
			"truck_damage":
				r.append("[color=%s]%s[/color]" % [bad, Loc.t("ui.event.eff_truck", [int(e.get("amount", 0))])])
			"truck_heal":
				if float(e.get("pct", 0.0)) >= 1.0:
					r.append("[color=%s]%s[/color]" % [good, Loc.t("ui.event.eff_truck_full")])
				else:
					r.append("[color=%s]%s[/color]" % [good, Loc.t("ui.event.eff_truck_heal", [int(e.get("amount", 0)) + int(round(float(run.truck_max) * float(e.get("pct", 0.0))))])])
			"truck_max":
				var tm: int = int(e.get("amount", 0))
				r.append("[color=%s]%s[/color]" % [good if tm >= 0 else bad, Loc.t("ui.event.eff_truck_max" if tm >= 0 else "ui.event.eff_truck_max_lose", [absi(tm)])])
			"materials":
				if str(e.get("half", "")) == "most":
					r.append("[color=%s]%s[/color]" % [bad, Loc.t("ui.event.eff_mat_half")])
				for m: String in Crafting.MATS:
					if int(e.get(m, 0)) > 0:
						r.append("[color=%s]%s[/color]" % [good, Loc.t("ui.event.eff_mat", [Loc.t("material.%s.name" % m), int(e[m])])])
					elif int(e.get(m, 0)) < 0:
						r.append("[color=%s]%s[/color]" % [bad, Loc.t("ui.event.eff_mat_lose", [Loc.t("material.%s.name" % m), -int(e[m])])])
			"gold":
				var gn: int = int(e.get("amount", 0))
				r.append("[color=%s]%s[/color]" % [warn if gn >= 0 else bad, Loc.t("ui.event.eff_gold" if gn >= 0 else "ui.event.eff_gold_lose", [absi(gn)])])
			"unit":
				var ut: String = Loc.t("ui.event.eff_unit_named", [Loc.t("unit.%s.name" % str(e["id"]))]) if e.has("id") else Loc.t("ui.event.eff_unit", [int(e.get("cost", 1))])
				r.append("[color=%s]%s[/color]" % [good, ut])
			"weapon":
				var wt: String = Loc.t("ui.event.eff_weapon_named", [Loc.t("equipment.%s.name" % str(e["id"]))]) if e.has("id") else Loc.t("ui.event.eff_weapon", [int(e.get("max_cost", 3))])
				r.append("[color=%s]%s[/color]" % [good, wt])
			"orb":
				var on: String = Loc.t("ui.event.orb_" + str(e.get("tier", "white")))
				var oc: int = int(e.get("count", 1))
				r.append("[color=%s]%s[/color]" % [good, on if oc == 1 else Loc.t("ui.event.orb_n", [on, oc])])
			"perm":
				var pct: int = int(round(float((e.get("stats", {}) as Dictionary).get("damage_dealt_pct", 0.0)) * 100.0))
				r.append("[color=%s]%s[/color]" % [good, Loc.t("ui.event.eff_perm", [Loc.t("ui.event.who_" + str(e.get("who", "random"))), pct])])
			"star_up":
				r.append("[color=%s]%s[/color]" % [good, Loc.t("ui.event.eff_star_up", [int(e.get("max_cost", 3))])])
			"lose_unit":
				r.append("[color=%s]%s[/color]" % [bad, Loc.t("ui.event.eff_lose_unit", [Loc.t("ui.event.who_" + str(e.get("who", "random")))])])
			"lose_weapon":
				r.append("[color=%s]%s[/color]" % [bad, Loc.t("ui.event.eff_lose_weapon")])
			"lose_part":
				r.append("[color=%s]%s[/color]" % [bad, Loc.t("ui.event.eff_lose_part")])
			"part":
				r.append("[color=%s]%s[/color]" % [good, Loc.t("ui.event.eff_part_named", [Loc.t("part.%s.name" % str(e["id"]))]) if e.has("id") and str(e["id"]) != "random" else Loc.t("ui.event.eff_part")])
			"flag":
				var fid: String = str(e.get("id", ""))
				r.append("[color=%s]%s[/color]" % [good if Events.is_gain(e) else bad, Loc.t("ui.flag.%s.gain" % fid, [absi(int(e.get("value", 0)))])])
			"xp":
				r.append("[color=%s]%s[/color]" % [good, Loc.t("ui.event.eff_xp", [int(e.get("amount", 0))])])
			"ap":
				var n: int = int(e.get("amount", 0))
				r.append("[color=%s]%s[/color]" % [good if n >= 0 else bad, Loc.t("ui.event.eff_ap" if n >= 0 else "ui.event.eff_ap_lose", [absi(n)])])
			"reveal":
				r.append("[color=%s]%s[/color]" % [good, Loc.t("ui.event.eff_reveal", [int(e.get("radius", 2))])])
			"battle":
				# 同一种晶球掉几个就写"×N"
				var orbs: Array[String] = []
				var counts: Dictionary = {}
				for ob: Variant in e.get("orbs", []):
					counts[str(ob)] = int(counts.get(str(ob), 0)) + 1
				for tier: String in counts.keys():
					var nm: String = Loc.t("ui.event.orb_" + tier)
					orbs.append(nm if int(counts[tier]) == 1 else Loc.t("ui.event.orb_n", [nm, int(counts[tier])]))
				r.append("[color=%s]%s[/color]" % [bad, Loc.t("ui.event.eff_battle", ["、".join(orbs) if Loc.lang == "zh" else ", ".join(orbs)])])
	if r.is_empty():
		return "[color=%s]%s[/color]" % [UIKit.hx(UIKit.TEXT_DIM), Loc.t("ui.event.eff_none")]
	return ("，" if Loc.lang == "zh" else ", ").join(r)


func _req_text(rq: Dictionary) -> String:
	var ok: bool = bool(rq.get("ok", false))
	var c: String = UIKit.hx(UIKit.TEXT_DIM if ok else UIKit.BAD)
	var t := ""
	match str(rq.get("type", "")):
		"ranged_attack_at_least":
			t = Loc.t("ui.event.req_ranged", [int(rq.get("value", 0))])
			if rq.has("who"):
				var nm: String = Loc.t("unit.%s.name" % str(rq["who"]))
				t += "  " + (("✓ " + Loc.t("ui.event.req_ranged_met", [nm, int(rq.get("who_value", 0))])) if ok else Loc.t("ui.event.req_ranged_best", [nm, int(rq.get("who_value", 0))]))
			else:
				t += "  " + Loc.t("ui.event.req_ranged_none")
		"truck_hp_above":
			t = Loc.t("ui.event.req_truck", [int(rq.get("value", 0))])
		"repeat_done":
			t = Loc.t("ui.event.repeat_done", [int(rq.get("value", 0))])
		"closed":
			t = Loc.t("ui.event.closed")
		"gold_at_least":
			t = Loc.t("ui.event.req_gold", [int(rq.get("value", 0))])
		"materials_at_least":
			var col: String = str(rq.get("who", ""))
			t = Loc.t("ui.event.req_mat", [Loc.t("material.%s.name" % col), int(rq.get("value", 0))]) if col != "" else Loc.t("ui.event.req_mat_all", [int(rq.get("value", 0))])
		"level_at_least":
			t = Loc.t("ui.event.req_level", [int(rq.get("value", 0))])
		"ap_at_least":
			t = Loc.t("ui.event.req_ap", [int(rq.get("value", 0))])
		"roster_at_least":
			t = Loc.t("ui.event.req_roster", [int(rq.get("value", 0))])
		"has_weapon":
			t = Loc.t("ui.event.req_weapon")
		"has_part":
			t = Loc.t("ui.event.req_part")
		"picked_at_least":
			t = Loc.t("ui.event.req_picked", [Loc.t("event.%s.opt.%s" % [event_id, str(rq.get("who", ""))]), int(rq.get("value", 0))])
		"picked_below":
			t = Loc.t("ui.event.req_picked_below", [Loc.t("event.%s.opt.%s" % [event_id, str(rq.get("who", ""))]), int(rq.get("value", 0))])
	if ok and t != "" and str(rq.get("type", "")) != "ranged_attack_at_least":
		t = "✓ " + t
	elif not ok and rq.has("who_value") and str(rq.get("type", "")) != "ranged_attack_at_least" and str(rq.get("type", "")) != "picked_at_least" and str(rq.get("type", "")) != "picked_below":
		t += "  " + Loc.t("ui.event.req_now", [int(rq.get("who_value", 0))])
	return "[color=%s]%s[/color]" % [c, t]


## 结果：实际得到 / 失去了什么(材料带像素图标)；随机给的东西(节点 / 武器 / 晶球里开出来的 / 永久加成给了谁)按 gains 写出名字
func _gains_row(effs: Array, gains: Array = []) -> Control:
	var box := UIKit.vbox(4)
	var h := UIKit.hbox(10)
	for e: Dictionary in effs:
		if str(e.get("type", "")) == "materials":
			for m: String in Crafting.MATS:
				if int(e.get(m, 0)) > 0:
					h.add_child(UIKit.material_icon(m, 26.0))
	var t: RichTextLabel = UIKit.rich(effects_text(effs), 16, 600.0)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(t)
	box.add_child(h)
	var lines: Array[String] = []
	for g: Dictionary in gains:
		lines.append(gain_text(g))
	if not lines.is_empty():
		box.add_child(UIKit.rich("[color=%s]%s[/color]" % [UIKit.hx(UIKit.TEXT_SOFT), "\n".join(lines)], 14, 640.0))
	return box


## 一条实际结果的文字(gains 里的一项)
func gain_text(g: Dictionary) -> String:
	match str(g.get("type", "")):
		"unit":
			return Loc.t("ui.event.got_unit", [Loc.t("unit.%s.name" % str(g["id"]))])
		"weapon":
			return Loc.t("ui.event.got_weapon", [Loc.t("equipment.%s.name" % str(g["id"]))])
		"orb":
			var loot: Dictionary = g.get("loot", {})
			var parts: Array[String] = []
			if int(loot.get("gold", 0)) > 0:
				parts.append(Loc.t("ui.event.eff_gold", [int(loot["gold"])]))
			for uid: Variant in loot.get("units", []):
				parts.append(Loc.t("unit.%s.name" % str(uid)))
			for wid: Variant in loot.get("weapons", []):
				parts.append(Loc.t("equipment.%s.name" % str(wid)))
			var sep: String = "、" if Loc.lang == "zh" else ", "
			return Loc.t("ui.event.got_orb", [Loc.t("ui.event.orb_" + str(g.get("tier", "white"))), sep.join(parts) if not parts.is_empty() else Loc.t("ui.event.eff_none")])
		"perm":
			return Loc.t("ui.event.got_perm", [Loc.t("unit.%s.name" % str(g["id"])), int(round(float((g.get("stats", {}) as Dictionary).get("damage_dealt_pct", 0.0)) * 100.0))])
		"star_up":
			return Loc.t("ui.event.got_star_up", [Loc.t("unit.%s.name" % str(g["id"]))])
		"lose_unit":
			return Loc.t("ui.event.lost_unit", [Loc.t("unit.%s.name" % str(g["id"]))])
		"lose_weapon":
			return Loc.t("ui.event.lost_weapon", [Loc.t("equipment.%s.name" % str(g["id"]))])
		"lose_part":
			return Loc.t("ui.event.lost_part", [Loc.t("part.%s.name" % str(g["id"]))])
		"part":
			return Loc.t("ui.event.got_part", [Loc.t("part.%s.name" % str(g["id"]))])
		"materials_lost":
			var ls: Array[String] = []
			for m: String in (g.get("lost", {}) as Dictionary).keys():
				ls.append(Loc.t("ui.event.eff_mat_lose", [Loc.t("material.%s.name" % m), int(g["lost"][m])]))
			return ("，" if Loc.lang == "zh" else ", ").join(ls)
		"flag":
			var fid: String = str(g.get("id", ""))
			return "%s：%s" % [Loc.t("ui.flag.%s.name" % fid), Loc.t("ui.flag.%s.desc" % fid, [absi(int(g.get("value", 0)))])]
	return ""

