class_name Screens
extends Control
## 全屏/居中覆盖界面(战术终端风格)：标题、暂停、作战结算(伤害榜、卡车耐久损失、掉落晶球数)、游戏结束(章节完成 / 卡车损毁)。
## 方格网章节(第一章起)的节点界面：修整(二选一)、事件(占位)、黑市 / 零件铺；章节结束：卡车改装(占位)、选择下一章的分支。
## 结算和游戏结束用一条横贯屏幕的深色条带承载大标题(中文大字 + 英文标注)，下面是数据块和行动按钮。

signal new_game
signal resume
signal restart
signal to_title
signal quit_game
signal arena                             # 测试场(原来的「模型展示」按钮)
signal codex
signal lang_toggle
signal result_continue
signal retry_run
signal rest_repair
signal rest_upgrade(roster_id: String)
signal event_continue
signal event_choose(i: int)
signal nshop_buy(index: int)
signal nshop_refresh
signal nshop_sell(index: int)
signal nshop_leave
signal mod_picked(id: String)
signal branch_picked(id: String)

var cat: Catalog
var portraits: Dictionary = {}
var dim: ColorRect
var box: Control
var current: String = ""


func _ready() -> void:
	UIKit.ensure()
	theme = UIKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	visible = false


func _clear() -> void:
	if box != null:
		box.queue_free()
		box = null


func hide_all() -> void:
	_clear()
	current = ""
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _open(name: String, dim_alpha: float, block: bool = true) -> Control:
	_clear()
	theme = UIKit.theme()
	current = name
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP if block else Control.MOUSE_FILTER_IGNORE
	var o: Color = UIKit.OVERLAY
	dim.color = Color(o.r, o.g, o.b, dim_alpha)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	box = root
	return root


func _center(parent: Control, content: Control, pad: int = 22, min_w: float = 0.0) -> Control:
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p: ArkPanel = UIKit.ark_panel(pad, "top", 14, UIKit.BG_DEEP)
	p.corners = true
	p.custom_minimum_size = Vector2(min_w, 0)
	p.add_child(content)
	cc.add_child(p)
	parent.add_child(cc)
	return cc


## 终端菜单项：编号 + 中文大字 + 英文标注；悬停时左侧亮起强调色条
func _menu_entry(idx: int, cn: String, en: String, primary: bool, sig: Signal, w: float = 380.0) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(w, 62)
	var accent: Color = UIKit.ACTION if primary else UIKit.ACCENT
	var n := StyleBoxFlat.new()
	n.bg_color = Color(UIKit.BG_DEEP.r, UIKit.BG_DEEP.g, UIKit.BG_DEEP.b, 0.62)
	n.border_color = accent if primary else UIKit.BORDER
	n.border_width_left = 4 if primary else 1
	n.border_width_bottom = 1
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(UIKit.BG.r, UIKit.BG.g, UIKit.BG.b, 0.95)
	h.border_color = accent
	h.border_width_left = 6
	for sb: StyleBoxFlat in [n, h]:
		sb.content_margin_left = 16
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	var row := UIKit.hbox(14)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 18
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_child(UIKit.num("%02d" % idx, 16, UIKit.TEXT_MUTE))
	var v := UIKit.vbox(-2)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(UIKit.label(cn, 22, UIKit.ACTION if primary else UIKit.TEXT, true))
	v.add_child(UIKit.caption(en, 10, UIKit.TEXT_DIM))
	row.add_child(v)
	b.add_child(row)
	b.pressed.connect(func() -> void: sig.emit())
	return b


func _band(parent: Control, top: float, bottom: float, color: Color) -> Control:
	var band := ColorRect.new()
	band.set_anchors_preset(Control.PRESET_TOP_WIDE)
	band.offset_top = top
	band.offset_bottom = bottom
	band.color = Color(UIKit.BG_DEEP.r, UIKit.BG_DEEP.g, UIKit.BG_DEEP.b, 0.9)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(band)
	for y: float in [0.0, bottom - top - 3.0]:
		var ln := ColorRect.new()
		ln.set_anchors_preset(Control.PRESET_TOP_WIDE)
		ln.offset_top = y
		ln.offset_bottom = y + 3.0
		ln.color = color
		ln.mouse_filter = Control.MOUSE_FILTER_IGNORE
		band.add_child(ln)
	var st := Stripes.new()
	st.color = Color(color.r, color.g, color.b, 0.35)
	st.step = 12.0
	st.width = 5.0
	st.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	st.offset_left = -360
	st.offset_right = -60
	st.offset_top = 26
	st.offset_bottom = -26
	band.add_child(st)
	return band


# ---------------------------------------------------------------- 标题
func show_title() -> void:
	var root: Control = _open("title", 0.0, false)
	var grad := TextureRect.new()
	var gt := GradientTexture2D.new()
	var g := Gradient.new()
	var o: Color = UIKit.OVERLAY
	g.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	g.colors = PackedColorArray([Color(o.r, o.g, o.b, 0.9), Color(o.r, o.g, o.b, 0.72), Color(o.r, o.g, o.b, 0.0)])
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	grad.texture = gt
	grad.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	grad.offset_right = 960
	grad.stretch_mode = TextureRect.STRETCH_SCALE
	grad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(grad)
	# 左侧的细竖线与刻度(终端装饰)
	var rule := ColorRect.new()
	rule.color = Color(UIKit.ACCENT.r, UIKit.ACCENT.g, UIKit.ACCENT.b, 0.6)
	rule.position = Vector2(92, 150)
	rule.size = Vector2(2, 760)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(rule)
	for k in range(9):
		var tick := ColorRect.new()
		tick.color = Color(UIKit.ACCENT.r, UIKit.ACCENT.g, UIKit.ACCENT.b, 0.6)
		tick.position = Vector2(86, 150.0 + float(k) * 95.0)
		tick.size = Vector2(8 if k % 2 == 0 else 5, 2)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(tick)
	var col := UIKit.vbox(8)
	col.position = Vector2(130, 170)
	root.add_child(col)
	col.add_child(UIKit.caption("Hyperdimensional Workshop", 15, UIKit.ACCENT))
	var t: Label = UIKit.label(Loc.t("ui.title"), 84 if Loc.lang == "zh" else 56, UIKit.TEXT, true)
	col.add_child(t)
	var tag_row := UIKit.hbox(10)
	var st := Stripes.new()
	st.color = UIKit.ACTION
	st.custom_minimum_size = Vector2(110, 12)
	st.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag_row.add_child(st)
	tag_row.add_child(UIKit.caption("Workshop master terminal · Prototype", 11, UIKit.TEXT_DIM))
	col.add_child(tag_row)
	col.add_child(UIKit.label(Loc.t("ui.subtitle"), 18, UIKit.TEXT_SOFT))
	col.add_child(UIKit.spacer(0, 34))
	col.add_child(_menu_entry(1, Loc.t("ui.new_game"), "Start", true, new_game))
	col.add_child(_menu_entry(2, Loc.t("ui.codex.title"), "Codex", false, codex))
	col.add_child(_menu_entry(3, Loc.t("ui.arena"), "Test range", false, arena))
	col.add_child(_menu_entry(4, Loc.t("ui.language"), "Language", false, lang_toggle))
	col.add_child(_menu_entry(5, Loc.t("ui.quit"), "Exit", false, quit_game))
	col.add_child(UIKit.spacer(0, 26))
	col.add_child(UIKit.rich(Loc.t("ui.title_hint"), 13, 560))
	var foot: Label = UIKit.caption("Build 0.4 · Episode 00 · %s" % Loc.t_in("en", "chapter.ch0.short"), 10, UIKit.TEXT_MUTE)
	foot.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	foot.offset_left = 130
	foot.offset_top = -44
	root.add_child(foot)


# ---------------------------------------------------------------- 暂停
func show_pause() -> void:
	var root: Control = _open("pause", 0.62)
	var v := UIKit.vbox(8)
	v.add_child(UIKit.caption("Terminal · Paused", 12, UIKit.ACCENT))
	v.add_child(UIKit.label(Loc.t("ui.paused"), 32, UIKit.TEXT, true))
	v.add_child(UIKit.spacer(0, 6))
	var specs: Array = [["ui.resume", "Resume", true, resume], ["ui.codex.title", "Codex", false, codex], ["ui.restart", "Restart", false, restart], ["ui.language", "Language", false, lang_toggle],
		["ui.to_title", "Title", false, to_title], ["ui.quit", "Exit", false, quit_game]]
	for i in range(specs.size()):
		var sp: Array = specs[i]
		v.add_child(_menu_entry(i + 1, Loc.t(str(sp[0])), str(sp[1]), bool(sp[2]), sp[3], 400.0))
	v.add_child(UIKit.spacer(0, 6))
	v.add_child(UIKit.rich(Loc.t("ui.controls_hint"), 12, 400))
	_center(root, v, 24, 440)


# ---------------------------------------------------------------- 结算
## 详细战报面板的选择(队伍 / 指标 / 选中的单位)：切语言等重新打开结算界面时保留；换了一场战斗就重置
var _rep_for: BattleReport = null
var _rep_state: Array = [GC.TEAM_PLAYER, "dealt", ""]


## res: Run.finish_battle 的返回；summary: Battle.summary()；report: Battle.report(详细战报；没有就退回旧的伤害榜)
func show_result(res: Dictionary, summary: Array, run: Run, battle_time: float, report: BattleReport = null) -> void:
	var root: Control = _open("result", 0.66)
	var win: bool = bool(res.get("win", false))
	var col: Color = UIKit.GOLD if win else UIKit.BAD
	_band(root, 120, 318, col)
	var head := UIKit.hbox(24)
	head.position = Vector2(200, 146)
	root.add_child(head)
	var ch_n: String = HUD.chapter_number(run.chapter_id)
	var code: String = "%s-%d" % [ch_n, int(res.get("node", 0)) + 1] if not run.is_grid() else "%s-%02d" % [ch_n, run.steps]
	var arena: bool = bool(res.get("arena", false))           # 测试场的单场战斗：没有晶球 / 金币，换成双方存活
	if arena:
		code = "TR"
	head.add_child(UIKit.code_badge(code, 44 if not run.is_grid() or arena else 34, Vector2(128, 104)))
	var hv := UIKit.vbox(0)
	hv.add_child(UIKit.caption("Operation complete" if win else "Operation failed", 16, col))
	hv.add_child(UIKit.label(Loc.t("ui.victory") if win else Loc.t("ui.defeat"), 70, col, true))
	var sub := UIKit.hbox(14)
	sub.add_child(UIKit.label(Loc.t("ui.arena_title") if arena else Loc.t("chapter.%s.name" % run.chapter_id), 16, UIKit.TEXT_SOFT, true))
	sub.add_child(UIKit.caption("Time", 11))
	sub.add_child(UIKit.num("%02d:%02d" % [int(battle_time) / 60, int(battle_time) % 60], 20, UIKit.TEXT))
	hv.add_child(sub)
	head.add_child(hv)
	# 数据块 + 伤害榜
	var body := UIKit.vbox(14)
	body.set_anchors_preset(Control.PRESET_CENTER_TOP)
	body.grow_horizontal = Control.GROW_DIRECTION_BOTH
	body.offset_top = 344
	root.add_child(body)
	var stats := UIKit.hbox(12)
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_child(_stat_tile("truck", UIKit.BAD if int(res.get("truck_damage", 0)) > 0 else UIKit.TEXT_DIM, Loc.t("ui.truck"), "Truck",
		"-%d" % int(res.get("truck_damage", 0)) if int(res.get("truck_damage", 0)) > 0 else "0"))
	if arena:
		stats.add_child(_stat_tile("heart", UIKit.ACCENT, Loc.t("ui.arena_avg_alive"), "Allies left", str(int(res.get("alive", 0)))))
		stats.add_child(_stat_tile("skull", UIKit.ENEMY, Loc.t("ui.arena_avg_foes"), "Enemies left", str(int(res.get("foes", 0)))))
	else:
		stats.add_child(_stat_tile("gem", UIKit.GOLD, Loc.t("ui.map_orbs"), "Orbs", "×%d" % int(res.get("orbs", 0))))
		stats.add_child(_stat_tile("coin", UIKit.GOLD, Loc.t("ui.gold_word"), "Gold", "+%d" % int(res.get("gold_units", 0))))
	body.add_child(stats)
	# 诅咒的武器(杀)：学习计数累计满了——降星 / 被移除
	for cv0: Variant in res.get("curses", []):
		var cd: Dictionary = cv0
		var who: String = Loc.t("unit.%s.name" % str(cd.get("def", "")))
		var wpn: String = Loc.t("equipment.%s.name" % str(cd.get("weapon", "")))
		var line: String = Loc.t("ui.curse_star") % [wpn, who, int(cd.get("star", 1))] if int(cd.get("star", 0)) > 0 			else Loc.t("ui.curse_gone") % [wpn, who, wpn]
		var cl: Label = UIKit.label(line, 16, UIKit.BAD, true)
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.add_child(cl)
	var chart: ArkPanel = UIKit.ark_panel(14, "top", 14, UIKit.BG_DEEP)
	if report != null:
		if report != _rep_for:
			_rep_for = report
			_rep_state = [GC.TEAM_PLAYER, "dealt", ""]
		var rp := ReportPanel.new()
		rp.name = "Report"
		rp.setup(cat, report, int(_rep_state[0]), str(_rep_state[1]), str(_rep_state[2]))
		rp.state_changed.connect(func(tm: int, m: String, sel: String) -> void: _rep_state = [tm, m, sel])
		chart.add_child(rp)
	else:
		var cv := UIKit.vbox(8)
		cv.add_child(UIKit.section(Loc.t("ui.result_stats"), "Combat record"))
		cv.add_child(_damage_chart(summary))
		chart.add_child(cv)
	body.add_child(chart)
	var b: Button = UIKit.action_button(Loc.t("ui.continue"), "Continue", Vector2(280, 76))
	b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	b.offset_left = -340
	b.offset_top = -120
	b.offset_right = -60
	b.offset_bottom = -44
	b.pressed.connect(func() -> void: result_continue.emit())
	UIKit.add_key_hint(b, "SPACE", "tl")
	root.add_child(b)


func _stat_tile(icon: String, color: Color, cn: String, en: String, value: String) -> Control:
	var p: ArkPanel = UIKit.ark_panel(10, "left", 0, UIKit.BG_DEEP, color)
	p.custom_minimum_size = Vector2(220, 0)
	var h := UIKit.hbox(10)
	h.add_child(UIKit.glyph(icon, color, 28.0))
	var v := UIKit.vbox(-2)
	v.add_child(UIKit.label(cn, 13, UIKit.TEXT_DIM, true))
	v.add_child(UIKit.caption(en, 9))
	h.add_child(v)
	h.add_child(UIKit.spacer(0, 0, true))
	h.add_child(UIKit.num(value, 30, color))
	p.add_child(h)
	return p


func _damage_chart(summary: Array) -> Control:
	var cols := UIKit.hbox(26)
	for team: int in [GC.TEAM_PLAYER, GC.TEAM_ENEMY]:
		var list: Array = []
		for s: Dictionary in summary:
			if int(s["team"]) == team:
				list.append(s)
		list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["damage"]) + float(a["heal"]) > float(b["damage"]) + float(b["heal"]))
		var mx := 1.0
		for s2: Dictionary in list:
			mx = maxf(mx, float(s2["damage"]) + float(s2["heal"]))
		var col := UIKit.vbox(5)
		col.custom_minimum_size = Vector2(420, 0)
		var tc: Color = UIKit.PLAYER if team == GC.TEAM_PLAYER else UIKit.ENEMY
		var th := UIKit.hbox(8)
		th.add_child(UIKit.label(Loc.t("ui.ally") if team == GC.TEAM_PLAYER else Loc.t("ui.enemy"), 14, tc, true))
		th.add_child(UIKit.caption("Allies" if team == GC.TEAM_PLAYER else "Hostiles", 10, tc))
		col.add_child(th)
		for s3: Dictionary in list.slice(0, 7):
			col.add_child(_damage_row(s3, mx, team))
		cols.add_child(col)
	return cols


func _damage_row(s: Dictionary, mx: float, team: int) -> Control:
	var d: UnitDef = cat.get_unit(str(s["def"]))
	var alive: bool = bool(s["alive"])
	var row := UIKit.hbox(8)
	var pic: Control = UIKit.portrait(d.id, Vector2(40, 30), d.faction_id)
	if not alive:
		pic.modulate = Color(1, 1, 1, 0.45)
	row.add_child(pic)
	var nv := UIKit.vbox(-2)
	var nm: Label = UIKit.label(Loc.t("unit.%s.name" % d.id), 13, UIKit.TEXT if alive else UIKit.TEXT_DIM, true)
	nm.custom_minimum_size = Vector2(112, 0)
	nm.clip_text = true
	nv.add_child(nm)
	nv.add_child(UIKit.pips(int(s["star"]), UIKit.GOLD, 8.0))
	row.add_child(nv)
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(150, 16)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dmg: float = float(s["damage"])
	var heal: float = float(s["heal"])
	var tc: Color = UIKit.PLAYER if team == GC.TEAM_PLAYER else UIKit.ENEMY
	var back: Color = UIKit.BORDER
	var good: Color = UIKit.GOOD
	bar.draw.connect(func() -> void:
		bar.draw_rect(Rect2(0, 4, 150, 8), back)
		var w1: float = 150.0 * dmg / mx
		var w2: float = 150.0 * heal / mx
		bar.draw_rect(Rect2(0, 4, w1, 8), tc)
		bar.draw_rect(Rect2(w1, 4, w2, 8), good))
	row.add_child(bar)
	var txt: String = Describe.fmt(round(dmg))
	if heal > 0.5:
		txt += " / +" + Describe.fmt(round(heal))
	row.add_child(UIKit.num(txt, 15, UIKit.TEXT_SOFT))
	if not alive:
		row.add_child(UIKit.glyph("skull", Color(1, 1, 1, 0.35), 13.0))
	return row


# ---------------------------------------------------------------- 游戏结束
## 游戏结束：章节全部通过(第一章尚未制作) / 卡车损毁
func show_gameover(won: bool, run: Run) -> void:
	var root: Control = _open("gameover", 0.7)
	var col: Color = UIKit.GOLD if won else UIKit.BAD
	_band(root, 300, 560, col)
	var chapter_name: String = Loc.t("chapter.%s.name" % run.chapter_id)
	var v := UIKit.vbox(6)
	v.position = Vector2(200, 326)
	root.add_child(v)
	v.add_child(UIKit.caption("Episode clear" if won else "Truck destroyed", 16, col))
	v.add_child(UIKit.label(Loc.t("ui.game_over"), 84, UIKit.TEXT, true))
	v.add_child(UIKit.label(Loc.t("ui.chapter_clear", [chapter_name]) if won else Loc.t("ui.truck_destroyed"), 22, col, true))
	v.add_child(UIKit.label(Loc.t("ui.run_summary2", [chapter_name, run.truck_hp, run.truck_max]), 15, UIKit.TEXT_DIM))
	if won:
		v.add_child(UIKit.rich("[color=#9aa3b5]%s[/color]" % (Loc.t("ui.over_next_layer") if run.chapters_cleared.size() > 1 else Loc.t("ui.chapter_clear_hint")), 14, 700))
	var btns := UIKit.hbox(14)
	btns.set_anchors_preset(Control.PRESET_CENTER_TOP)
	btns.grow_horizontal = Control.GROW_DIRECTION_BOTH
	btns.offset_top = 600
	var b1: Button = UIKit.action_button(Loc.t("ui.new_game"), "New run", Vector2(300, 76))
	b1.pressed.connect(func() -> void: retry_run.emit())
	btns.add_child(b1)
	var b2: Button = UIKit.action_button(Loc.t("ui.to_title"), "Title", Vector2(240, 76), "normal")
	b2.pressed.connect(func() -> void: to_title.emit())
	btns.add_child(b2)
	root.add_child(btns)


# ================================================================ 方格网章节的节点界面
## 一张可以点的选项卡：图标 + 中文标题 + 英文标注 + 说明(+ 额外内容)；enabled = false 时变暗不能点。
## 卡片高度跟着内容走(PanelContainer)；icon = "" 时不画标题行(额外内容自带标题，如武器信息)
func _choice_card(icon: String, color: Color, cn: String, en: String, desc: String, enabled: bool, cb: Callable, extra: Control = null, w: float = 360.0) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(w, 200)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var n: StyleBoxFlat = UIKit.style(Color(UIKit.BG_DEEP.r, UIKit.BG_DEEP.g, UIKit.BG_DEEP.b, 0.94), 0, color if enabled else UIKit.BORDER, 1, 16)
	n.border_width_top = 4
	var hv: StyleBoxFlat = n.duplicate() as StyleBoxFlat
	hv.bg_color = UIKit.BG
	hv.border_width_left = 2
	hv.border_width_right = 2
	hv.border_width_bottom = 2
	card.add_theme_stylebox_override("panel", n)
	var v := UIKit.vbox(8)
	if icon != "":
		var head := UIKit.hbox(12)
		head.add_child(UIKit.glyph(icon, color if enabled else UIKit.TEXT_MUTE, 44.0))
		var tv := UIKit.vbox(0)
		tv.add_child(UIKit.label(cn, 24, UIKit.TEXT if enabled else UIKit.TEXT_MUTE, true))
		tv.add_child(UIKit.caption(en, 10, color if enabled else UIKit.TEXT_MUTE))
		head.add_child(tv)
		v.add_child(head)
	if desc != "":
		v.add_child(UIKit.rich("[color=%s]%s[/color]" % [UIKit.hx(UIKit.TEXT_SOFT if enabled else UIKit.TEXT_MUTE), desc], 14, w - 36.0))
	if extra != null:
		v.add_child(extra)
	_mouse_ignore(v)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)
	if not enabled:
		card.modulate = Color(1, 1, 1, 0.6)
		return card
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.mouse_entered.connect(func() -> void: card.add_theme_stylebox_override("panel", hv))
	card.mouse_exited.connect(func() -> void: card.add_theme_stylebox_override("panel", n))
	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			card.accept_event()
			cb.call())
	return card


func _mouse_ignore(n: Node) -> void:
	for ch: Node in n.get_children():
		if ch is Control:
			(ch as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mouse_ignore(ch)


## 节点界面的大标题条
func _node_header(root: Control, color: Color, icon: String, cn: String, en: String, sub: String) -> void:
	_band(root, 70, 230, color)
	var head := UIKit.hbox(20)
	head.position = Vector2(200, 96)
	root.add_child(head)
	head.add_child(UIKit.glyph(icon, color, 86.0))
	var hv := UIKit.vbox(0)
	hv.add_child(UIKit.caption(en, 16, color))
	hv.add_child(UIKit.label(cn, 56, UIKit.TEXT, true))
	if sub != "":
		hv.add_child(UIKit.label(sub, 15, UIKit.TEXT_DIM))
	head.add_child(hv)


func _bottom_button(root: Control, cn: String, en: String, sig: Signal, kind: String = "primary") -> Button:
	var b: Button = UIKit.action_button(cn, en, Vector2(260, 72), kind)
	b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	b.offset_left = -320
	b.offset_top = -116
	b.offset_right = -60
	b.offset_bottom = -44
	b.pressed.connect(func() -> void: sig.emit())
	root.add_child(b)
	return b


func _gold_badge(root: Control, run: Run) -> void:
	var gp: ArkPanel = UIKit.ark_panel(8, "", 0)
	var gh := UIKit.hbox(6)
	gh.add_child(UIKit.glyph("coin", Color.WHITE, 26.0))
	var gv := UIKit.vbox(-2)
	gv.add_child(UIKit.num(str(run.gold), 30, UIKit.GOLD))
	gv.add_child(UIKit.caption("Gold", 9))
	gh.add_child(gv)
	gp.add_child(gh)
	gp.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	gp.offset_left = -200
	gp.offset_right = -60
	gp.offset_top = 112
	root.add_child(gp)


## 修整：二选一(维修卡车 / 把一个 1 星节点升到 2 星)
func show_rest(run: Run) -> void:
	var root: Control = _open("rest", 0.55)
	var col: Color = CityOverworld.TYPE_COLORS["rest"]
	_node_header(root, col, "n_rest", Loc.t("ui.rest_title"), "Rest stop · choose one", Loc.t("ui.node_type.rest.desc"))
	var row := UIKit.hbox(28)
	row.set_anchors_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	row.offset_top = 40
	root.add_child(row)
	var amt: int = run.rest_repair_amount()
	var tinfo := UIKit.hbox(8)
	tinfo.add_child(UIKit.glyph("truck", UIKit.TEXT_SOFT, 24.0))
	tinfo.add_child(UIKit.num("%d → %d / %d" % [run.truck_hp, mini(run.truck_max, run.truck_hp + amt), run.truck_max], 22, UIKit.GOOD))
	row.add_child(_choice_card("truck", UIKit.GOOD, Loc.t("ui.rest_repair"), "Repair", Loc.t("ui.rest_repair.desc", [amt]),
		run.truck_hp < run.truck_max, func() -> void: rest_repair.emit(), tinfo, 380.0))
	var cap: int = int((run.chapter.get("rest", {}) as Dictionary).get("upgrade_max_cost", 3))
	var cands: Array[Dictionary] = run.rest_upgrade_candidates()
	var up := UIKit.vbox(10)
	up.custom_minimum_size = Vector2(560, 0)
	var head := UIKit.hbox(12)
	head.add_child(UIKit.glyph("star", UIKit.GOLD, 44.0))
	var tv := UIKit.vbox(0)
	tv.add_child(UIKit.label(Loc.t("ui.rest_upgrade"), 24, UIKit.TEXT, true))
	tv.add_child(UIKit.caption("Promote", 10, UIKit.GOLD))
	head.add_child(tv)
	up.add_child(head)
	up.add_child(UIKit.rich("[color=%s]%s[/color]" % [UIKit.hx(UIKit.TEXT_SOFT), Loc.t("ui.rest_upgrade.desc", [cap])], 14, 540))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for u: Dictionary in cands.slice(0, 12):
		grid.add_child(_unit_pick(run, u))
	if cands.is_empty():
		up.add_child(UIKit.label(Loc.t("ui.rest_none"), 14, UIKit.TEXT_MUTE))
	up.add_child(grid)
	var upp: ArkPanel = UIKit.ark_panel(16, "top", 0, Color(UIKit.BG_DEEP.r, UIKit.BG_DEEP.g, UIKit.BG_DEEP.b, 0.94), UIKit.GOLD)
	upp.add_child(up)
	row.add_child(upp)


func _unit_pick(run: Run, u: Dictionary) -> Control:
	var def: UnitDef = run.unit_def(u)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(128, 104)
	b.add_theme_stylebox_override("normal", UIKit.style(UIKit.BG, 0, UIKit.BORDER, 1, 6))
	b.add_theme_stylebox_override("hover", UIKit.style(UIKit.BG_SOFT, 0, UIKit.GOLD, 2, 6))
	b.add_theme_stylebox_override("pressed", UIKit.style(UIKit.BG_SOFT, 0, UIKit.GOLD, 2, 6))
	var v := UIKit.vbox(2)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 6
	v.offset_top = 6
	v.offset_right = -6
	v.add_child(UIKit.portrait(def.id, Vector2(116, 64), def.faction_id))
	var nh := UIKit.hbox(4)
	nh.add_child(UIKit.num("%d" % def.cost, 13, UIKit.GOLD))
	nh.add_child(UIKit.label(Loc.t("unit.%s.name" % def.id), 12, UIKit.TEXT, true))
	v.add_child(nh)
	_mouse_ignore(v)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var rid: String = str(u["id"])
	b.pressed.connect(func() -> void: rest_upgrade.emit(rid))
	return b


## 事件(尚未制作)：一段占位文字 + 继续
## 事件：左边是事件的实际场景(3D)，右边正文 + 选项(EventScreen)。选了选项之后只刷新右边，场景不重建
func show_event(run: Run) -> void:
	if current == "event" and box != null and box.get_child_count() > 0:
		var cur: EventScreen = box.get_child(0) as EventScreen
		if cur != null and cur.event_id == str(run.event_state.get("id", "")):
			cur.refresh()
			return
	var root: Control = _open("event", 0.72)
	var es := EventScreen.new()
	es.setup(run)
	es.choose.connect(func(i: int) -> void: event_choose.emit(i))
	es.proceed.connect(func() -> void: event_continue.emit())
	root.add_child(es)


## 当前打开的事件界面(没有 = null)
func event_screen() -> EventScreen:
	if current != "event" or box == null or box.get_child_count() == 0:
		return null
	return box.get_child(0) as EventScreen


## 黑市 / 零件铺：货架(武器 / 零件 / 卡车维修)，刷新，零件铺还能回收零件
func show_node_shop(run: Run, cat: Catalog) -> void:
	var root: Control = _open("shop", 0.6)
	var st: Dictionary = run.node_shop()
	var t: String = str(st.get("type", "shop_black"))
	var col: Color = CityOverworld.TYPE_COLORS.get(t, UIKit.GOLD)
	_node_header(root, col, "n_" + t, Loc.t("ui.node_type." + t), Loc.t_in("en", "ui.node_type." + t), Loc.t("ui.node_type.%s.desc" % t))
	_gold_badge(root, run)
	var body := UIKit.vbox(16)
	body.set_anchors_preset(Control.PRESET_CENTER_TOP)
	body.grow_horizontal = Control.GROW_DIRECTION_BOTH
	body.offset_top = 262
	root.add_child(body)
	body.add_child(UIKit.section(Loc.t("ui.shop_weapons") if t == "shop_black" else Loc.t("ui.shop_parts_buy"), "For sale", col))
	var row := UIKit.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var offers: Array = st.get("offers", [])
	for i in range(offers.size()):
		row.add_child(_offer_card(run, cat, offers[i], i, col))
	body.add_child(row)
	if t == "shop_parts":
		body.add_child(UIKit.section(Loc.t("ui.shop_parts_sell"), "Sell", UIKit.GOLD))
		var srow := UIKit.hbox(10)
		srow.alignment = BoxContainer.ALIGNMENT_CENTER
		if run.parts.is_empty():
			srow.add_child(UIKit.label(Loc.t("ui.parts_empty"), 14, UIKit.TEXT_MUTE))
		for j in range(run.parts.size()):
			var pid: String = run.parts[j]
			var sb: Button = UIKit.button("%s  %s" % [Loc.t("part.%s.name" % pid), Loc.t("ui.part_sell", [run.part_sell_price(pid)])], "normal", Vector2(220, 46))
			var jj: int = j
			sb.pressed.connect(func() -> void: nshop_sell.emit(jj))
			srow.add_child(sb)
		body.add_child(srow)
	# 刷新 + 离开
	var rc: int = run.node_shop_refresh_cost()
	var rb: Button = UIKit.button(Loc.t("ui.refresh_n", [rc]) if rc >= 0 else Loc.t("ui.err.no_refresh"), "normal", Vector2(220, 56))
	rb.disabled = rc < 0 or run.gold < rc
	rb.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	rb.offset_left = 60
	rb.offset_top = -104
	rb.offset_right = 280
	rb.offset_bottom = -48
	rb.pressed.connect(func() -> void: nshop_refresh.emit())
	root.add_child(rb)
	var lb: Button = _bottom_button(root, Loc.t("ui.leave"), "Leave", nshop_leave, "normal")
	UIKit.add_key_hint(lb, "SPACE", "tl")


func _offer_card(run: Run, cat: Catalog, of: Dictionary, i: int, col: Color) -> Control:
	var sold: bool = bool(of["sold"])
	var price: int = int(of["price"])
	var kind: String = str(of["kind"])
	var extra := UIKit.vbox(6)
	var icon := "coin"
	var cn := ""
	var en := ""
	var desc := ""
	match kind:
		"weapon":
			var e: EquipmentDef = cat.get_equipment(str(of["id"]))
			icon = ""
			extra.add_child(TipContent.equipment_tip(cat, e.id))
		"part":
			icon = "p_" + str(of["id"])
			cn = Loc.t("part.%s.name" % str(of["id"]))
			en = "Truck part"
			desc = Loc.t("part.%s.desc" % str(of["id"]))
		"repair":
			icon = "truck"
			cn = Loc.t("ui.shop_repair", [int(of.get("amount", 15))])
			en = "Truck repair"
			desc = "%d → %d / %d" % [run.truck_hp, mini(run.truck_max, run.truck_hp + int(of.get("amount", 15))), run.truck_max]
	var ph := UIKit.hbox(6)
	ph.add_child(UIKit.glyph("coin", Color.WHITE, 22.0))
	ph.add_child(UIKit.num(Loc.t("ui.sold_out") if sold else str(price), 24, UIKit.TEXT_MUTE if sold else (UIKit.GOLD if run.gold >= price else UIKit.BAD)))
	extra.add_child(ph)
	var ii: int = i
	var usable: bool = not (kind == "repair" and run.truck_hp >= run.truck_max)
	var card: Control = _choice_card(icon, col, cn, en, desc, not sold and run.gold >= price and usable, func() -> void: nshop_buy.emit(ii), extra, 330.0 if kind == "weapon" else 250.0)
	return card


## 卡车改装(占位)：三选一，选了也没有效果
## 卡车改装三选一：start = true 是开局的初始改装(卡车摆法)；false 是进下一章前的改装(卡片按改装的颜色着色，标稀有度)
func show_mod_pick(run: Run, start: bool = false) -> void:
	var root: Control = _open("mod", 0.68)
	if start:
		_node_header(root, UIKit.ACCENT, "truck", Loc.t("ui.start_mod_title"), "Starting truck mod", Loc.t("ui.start_mod_hint"))
	else:
		var nx: String = run.pending_chapter
		var sub: String = Loc.t("ui.mod_hint")
		if nx != "" and Loc.has_key("chapter.%s.name" % nx):
			sub = "%s → %s" % [Loc.t("chapter.%s.name" % nx), sub]
		_node_header(root, UIKit.ACCENT, "truck", Loc.t("ui.mod_title"), "Truck mod", sub)
	var row := UIKit.hbox(24)
	row.set_anchors_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	row.offset_top = 40
	root.add_child(row)
	for m: String in run.mod_options:
		var mm: String = m
		var d: Dictionary = run.mod_def(m)
		var color: String = str(d.get("color", "white"))
		var rarity: int = int(d.get("rarity", 1))
		var col: Color = GC.faction_color(color)
		var en: String = "%s · %s" % [Loc.t_in("en", "color." + color).to_upper(), (Loc.t_in("en", "ui.mod_rarity") % [rarity]).to_upper()]
		var extra := UIKit.hbox(6)
		extra.add_child(UIKit.tag(Loc.t("color." + color), col, false, 11))
		extra.add_child(UIKit.tag(Loc.t("ui.mod_rarity", [rarity]) + " " + "★".repeat(rarity), UIKit.GOLD, false, 11))
		row.add_child(_choice_card("truck", col, Loc.t("mod.%s.name" % m), en, Loc.t("mod.%s.desc" % m), true,
			func() -> void: mod_picked.emit(mm), extra, 400.0))


## 选择下一章的分支(红 / 蓝 / 绿；没做的显示"尚未开放")
func show_branch(run: Run) -> void:
	var root: Control = _open("branch", 0.68)
	_node_header(root, UIKit.ACTION, "n_start", Loc.t("ui.branch_title"), "Choose your route", Loc.t("ui.branch_hint"))
	var row := UIKit.hbox(24)
	row.set_anchors_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	row.offset_top = 40
	root.add_child(row)
	var cols := {"red": Color("#e2362c"), "blue": Color("#3f7fe0"), "green": Color("#58a83c")}
	for b: Dictionary in run.next_branches():
		var id: String = str(b["id"])
		var avail: bool = bool(b.get("available", false))
		var bc: Color = cols.get(id.get_slice("_", 1), UIKit.ACCENT)
		var desc: String = Loc.t("chapter.%s.desc" % id) if Loc.has_key("chapter.%s.desc" % id) and avail else Loc.t("ui.branch_locked")
		var idd: String = id
		row.add_child(_choice_card("n_start" if avail else "lock", bc, Loc.t("chapter.%s.name" % id), Loc.t_in("en", "chapter.%s.short" % id).to_upper(),
			desc, avail, func() -> void: branch_picked.emit(idd), null, 360.0))
