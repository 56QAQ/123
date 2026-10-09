class_name ArenaPanel
extends Control
## 测试场的面板(画面右侧)：我方 / 敌方 / 测试 三页。只管界面，所有操作都转给 ArenaMode。
## 我方：点头像加进仓库(拖到格子上 = 直接上场)，选中的棋子改星级 / 武器 / 移除，羁绊开关、自动装专属武器。
## 敌方：点头像加怪(按方位出生；拖到战场上 = 放在那里)，每只怪的星级 / 强度点数，按战斗强度随机配一组，怪物强度总值。
## 测试：地图、战斗场数(1 场 = 播放；多场 = 无画面模拟后给结果)、强度阈值测试(进度和每档的结果)。

const W := 420.0

var am: ArenaMode
var cat: Catalog
var tab := "allies"
var add_star := 1
var foe_star := 1
var rand_kind := "fight"
var rand_iv := 24
var _box: ArkPanel
var _tab_btns: Dictionary = {}
var _body: VBoxContainer
var _scroll: ScrollContainer
var _unit_box: VBoxContainer = null
var _prog_label: Label = null
var _prog_bar: SegBar = null
var _sel := ""
var focus_probe := false               # 阈值测试刚做完：重建后滚到结果那里


func setup(p_am: ArenaMode) -> void:
	am = p_am
	cat = am.cat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UIKit.theme()
	_box = UIKit.ark_panel(12, "top", 14, Color(UIKit.BG.r, UIKit.BG.g, UIKit.BG.b, 0.94))
	_box.anchor_left = 1.0
	_box.anchor_right = 1.0
	_box.anchor_top = 0.0
	_box.anchor_bottom = 1.0
	_box.offset_left = -W - 14.0
	_box.offset_right = -14.0
	_box.offset_top = 14.0
	_box.offset_bottom = -150.0
	_box.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_box)
	var v := UIKit.vbox(8)
	_box.add_child(v)
	var head := UIKit.hbox(8)
	var sec: Control = UIKit.section(Loc.t("ui.arena_title"), "Balance Test Range")
	sec.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sec)
	var back: Button = UIKit.button(Loc.t("ui.arena_back"), "normal", Vector2(96, 30))
	back.add_theme_font_size_override("font_size", 13)
	back.pressed.connect(func() -> void: am.gr._show_title())
	head.add_child(back)
	v.add_child(head)
	var tabs := UIKit.hbox(4)
	for t: Array in [["allies", "ui.arena_tab_allies", "Allies"], ["enemies", "ui.arena_tab_enemies", "Enemies"], ["test", "ui.arena_tab_test", "Test"]]:
		var b: Button = UIKit.button("%s  %s" % [Loc.t(str(t[1])), str(t[2]).to_upper()], "normal", Vector2(130, 34))
		b.add_theme_font_size_override("font_size", 14)
		var tid: String = str(t[0])
		b.pressed.connect(func() -> void: select_tab(tid))
		tabs.add_child(b)
		_tab_btns[tid] = b
	v.add_child(tabs)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_scroll)
	_body = UIKit.vbox(10)
	_body.custom_minimum_size = Vector2(W - 36.0, 0)
	_scroll.add_child(_body)
	refresh()


func select_tab(t: String) -> void:
	tab = t
	_scroll.scroll_vertical = 0
	refresh()


## 整页重建(改了阵容 / 怪 / 设置时)
func refresh() -> void:
	if _body == null:
		return
	for t: String in _tab_btns.keys():
		var b: Button = _tab_btns[t]
		b.add_theme_color_override("font_color", UIKit.ACCENT if t == tab else UIKit.TEXT_DIM)
		var sb: StyleBoxFlat = UIKit.style(UIKit.BG_DEEP if t == tab else UIKit.BG_SOFT, 0, UIKit.ACCENT if t == tab else UIKit.BORDER, 1, 4)
		if t == tab:
			sb.border_width_bottom = 3
		b.add_theme_stylebox_override("normal", sb)
	for ch: Node in _body.get_children():
		_body.remove_child(ch)
		ch.queue_free()
	_unit_box = null
	_prog_label = null
	_prog_bar = null
	match tab:
		"allies":
			_build_allies()
		"enemies":
			_build_enemies()
		"test":
			_build_test()


# ---------------------------------------------------------------- 小部件
func _toggle_row(items: Array, current: Variant, cb: Callable, w: float = 64.0) -> HBoxContainer:
	var row := UIKit.hbox(4)
	for it: Array in items:
		var on: bool = it[0] == current
		var b: Button = UIKit.button(str(it[1]), "normal", Vector2(w, 30))
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_color_override("font_color", UIKit.ACCENT if on else UIKit.TEXT_DIM)
		var sb: StyleBoxFlat = UIKit.style(UIKit.BG_DEEP if on else UIKit.BG_SOFT, 0, UIKit.ACCENT if on else UIKit.BORDER, 1, 4)
		if on:
			sb.border_width_bottom = 3
		b.add_theme_stylebox_override("normal", sb)
		var val: Variant = it[0]
		b.pressed.connect(func() -> void: cb.call(val))
		row.add_child(b)
	return row


func _labeled(text: String, ctl: Control) -> HBoxContainer:
	var h := UIKit.hbox(8)
	var l: Label = UIKit.label(text, 13, UIKit.TEXT_DIM)
	l.custom_minimum_size = Vector2(96, 0)
	h.add_child(l)
	h.add_child(ctl)
	return h


func _stars(n: int) -> String:
	return "★".repeat(n)


func _small_btn(text: String, cb: Callable, w: float = 34.0) -> Button:
	var b: Button = UIKit.button(text, "normal", Vector2(w, 26))
	b.add_theme_font_size_override("font_size", 13)
	b.pressed.connect(cb)
	return b


func _hint(key: String) -> Label:
	var l: Label = UIKit.label(Loc.t(key), 12, UIKit.TEXT_MUTE)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(W - 40.0, 0)
	return l


# ---------------------------------------------------------------- 我方
func _build_allies() -> void:
	_body.add_child(_labeled(Loc.t("ui.arena_star_add"), _toggle_row([[1, "★1"], [2, "★2"], [3, "★3"]], add_star, func(s: Variant) -> void:
		add_star = int(s)
		refresh())))
	var opts := UIKit.hbox(8)
	var aw := CheckBox.new()
	aw.text = Loc.t("ui.arena_auto_weapon")
	aw.button_pressed = am.auto_weapon
	aw.toggled.connect(func(on: bool) -> void: am.auto_weapon = on)
	opts.add_child(aw)
	var tr := CheckBox.new()
	tr.text = Loc.t("ui.arena_traits")
	tr.button_pressed = am.traits_on
	tr.toggled.connect(func(on: bool) -> void: am.set_traits(on))
	opts.add_child(tr)
	_body.add_child(opts)
	_body.add_child(_hint("ui.arena_hint_allies"))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	var ids: Array = cat.shop_unit_ids().duplicate()
	ids.sort_custom(func(a: String, b: String) -> bool:
		var da: UnitDef = cat.get_unit(a)
		var db: UnitDef = cat.get_unit(b)
		return da.cost < db.cost if da.cost != db.cost else a < b)
	for id: String in ids:
		grid.add_child(_unit_tile(id))
	_body.add_child(grid)
	_unit_box = UIKit.vbox(6)
	_body.add_child(_unit_box)
	_fill_unit_box()
	var clr: Button = UIKit.button(Loc.t("ui.arena_clear_allies"), "normal", Vector2(140, 30))
	clr.add_theme_font_size_override("font_size", 13)
	clr.pressed.connect(func() -> void: am.clear_units())
	_body.add_child(clr)


func _unit_tile(id: String) -> Control:
	var d: UnitDef = cat.get_unit(id)
	var t := ArenaTile.new()
	t.drag_data = {"kind": "arena_unit", "def": id, "star": add_star}
	t.tooltip_text = "%s · %d" % [Loc.t("unit.%s.name" % id), d.cost]
	var v := UIKit.vbox(1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(UIKit.portrait(id, Vector2(72, 50), d.faction_id))
	var n: Label = UIKit.label(Loc.t("unit.%s.name" % id).trim_suffix("节点"), 11, UIKit.TEXT_SOFT)
	n.clip_text = true
	n.custom_minimum_size = Vector2(72, 0)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(n)
	t.add_child(v)
	t.clicked.connect(func() -> void: am.add_unit(id, add_star))
	return t


## 选中的棋子(场上的或仓库里的)：星级 / 武器 / 移除
func show_unit(rid: String) -> void:
	_sel = rid
	if _unit_box != null:
		_fill_unit_box()


func _fill_unit_box() -> void:
	for ch: Node in _unit_box.get_children():
		_unit_box.remove_child(ch)
		ch.queue_free()
	_unit_box.add_child(UIKit.section(Loc.t("ui.arena_selected"), "Selected"))
	var run: Run = am.run
	if _sel == "" or not run.roster.has(_sel):
		_unit_box.add_child(_hint("ui.arena_pick_hint"))
		return
	var u: Dictionary = run.roster[_sel]
	var d: UnitDef = run.unit_def(u)
	var h := UIKit.hbox(8)
	h.add_child(UIKit.portrait(d.id, Vector2(64, 44), d.faction_id))
	var nv := UIKit.vbox(0)
	nv.add_child(UIKit.label(Loc.t("unit.%s.name" % d.id), 15, UIKit.TEXT, true))
	nv.add_child(UIKit.caption(Loc.t("ui.arena_on_board") if u["cell"] != null else Loc.t("ui.cargo"), 10, UIKit.ACCENT))
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(nv)
	h.add_child(_small_btn(Loc.t("ui.arena_remove"), func() -> void: am.remove_unit(_sel), 60.0))
	_unit_box.add_child(h)
	_unit_box.add_child(_toggle_row([[1, "★1"], [2, "★2"], [3, "★3"]], int(u["star"]), func(s: Variant) -> void:
		am.set_star(_sel, int(s))
		_fill_unit_box()))
	_unit_box.add_child(UIKit.label(Loc.t("ui.arena_weapon") + "：" + (Loc.t("equipment.%s.name" % str(u["weapon"])) if str(u["weapon"]) != "" else Loc.t("ui.arena_basic")),
		13, UIKit.TEXT_SOFT))
	var wg := GridContainer.new()
	wg.columns = 6
	wg.add_theme_constant_override("h_separation", 4)
	wg.add_theme_constant_override("v_separation", 4)
	for eid: String in am.weapons_for(u):
		if eid == "":
			var bb: Button = _small_btn(Loc.t("ui.arena_basic"), func() -> void:
				am.set_weapon(_sel, "")
				_fill_unit_box(), 60.0)
			bb.custom_minimum_size = Vector2(60, 60)
			bb.add_theme_color_override("font_color", UIKit.ACCENT if str(u["weapon"]) == "" else UIKit.TEXT_DIM)
			wg.add_child(bb)
			continue
		var it := ItemTile.new()
		it.setup(cat, eid)
		if eid == str(u["weapon"]):
			it.modulate = Color(1.2, 1.2, 0.8)
		it.hover_in.connect(func() -> void: am.gr.hud.show_tip(TipContent.equipment_tip(cat, eid, d), it))
		it.hover_out.connect(func() -> void: am.gr.hud.hide_tip())
		it.clicked.connect(func() -> void:
			am.set_weapon(_sel, eid)
			_fill_unit_box())
		wg.add_child(it)
	_unit_box.add_child(wg)


# ---------------------------------------------------------------- 敌方
func _build_enemies() -> void:
	_body.add_child(_labeled(Loc.t("ui.arena_star_add"), _toggle_row([[1, "★1"], [2, "★2"], [3, "★3"]], foe_star, func(s: Variant) -> void:
		foe_star = int(s)
		refresh())))
	_body.add_child(_hint("ui.arena_hint_enemies"))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	var mons: Dictionary = am.run.chapter.get("monsters", {})
	var ids: Array = mons.keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ha: bool = bool((mons[a] as Dictionary).get("head", false))
		var hb: bool = bool((mons[b] as Dictionary).get("head", false))
		return (not ha and hb) or (ha == hb and float(mons[a]["power"]) < float(mons[b]["power"])))
	for id: String in ids:
		grid.add_child(_monster_tile(id))
	_body.add_child(grid)
	# 按战斗强度随机配一组
	_body.add_child(UIKit.section(Loc.t("ui.arena_random"), "Random by intensity"))
	_body.add_child(_toggle_row([["fight", Loc.t("ui.arena_kind_fight")], ["elite", Loc.t("ui.arena_kind_elite")], ["boss", Loc.t("ui.arena_kind_boss")]],
		rand_kind, func(k: Variant) -> void:
			rand_kind = str(k)
			refresh(), 80.0))
	var rr := UIKit.hbox(6)
	var sp := SpinBox.new()
	sp.min_value = 1
	sp.max_value = 300
	sp.value = rand_iv
	sp.custom_minimum_size = Vector2(110, 30)
	sp.value_changed.connect(func(val: float) -> void: rand_iv = int(val))
	rr.add_child(UIKit.label(Loc.t("ui.intensity"), 13, UIKit.TEXT_DIM))
	rr.add_child(sp)
	var gen: Button = UIKit.button(Loc.t("ui.arena_generate"), "primary", Vector2(90, 30))
	gen.add_theme_font_size_override("font_size", 13)
	gen.pressed.connect(func() -> void: am.random_monsters(rand_kind, rand_iv))
	rr.add_child(gen)
	_body.add_child(rr)
	# 现在的怪 + 总值
	var tot := UIKit.hbox(10)
	var tl := UIKit.vbox(-2)
	tl.add_child(UIKit.label(Loc.t("ui.arena_total"), 15, UIKit.TEXT, true))
	tl.add_child(UIKit.caption("Total monster points = intensity", 9, UIKit.ACCENT))
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tot.add_child(tl)
	tot.add_child(UIKit.num(Describe.fmt(snappedf(am.total_points(), 0.1)), 30, UIKit.GOLD))
	_body.add_child(tot)
	var units: Array = am.enemies()
	for i in range(units.size()):
		_body.add_child(_enemy_row(i, units[i]))
	if not units.is_empty():
		var clr: Button = UIKit.button(Loc.t("ui.arena_clear_enemies"), "normal", Vector2(140, 30))
		clr.add_theme_font_size_override("font_size", 13)
		clr.pressed.connect(func() -> void: am.clear_monsters())
		_body.add_child(clr)


func _monster_tile(id: String) -> Control:
	var d: UnitDef = cat.get_unit(id)
	var t := ArenaTile.new()
	t.drag_data = {"kind": "arena_monster", "def": id, "star": foe_star}
	t.tooltip_text = Loc.t("unit.%s.name" % id)
	var v := UIKit.vbox(1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(UIKit.portrait(id, Vector2(72, 50), d.faction_id))
	var n: Label = UIKit.label(Loc.t("ui.arena_points", [Describe.fmt(snappedf(am.run._unit_power(id, foe_star), 0.1))]), 11, UIKit.GOLD)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(n)
	t.add_child(v)
	t.clicked.connect(func() -> void: am.add_monster(id, foe_star))
	return t


func _enemy_row(i: int, e: Array) -> Control:
	var opt: Dictionary = e[4]
	var h := UIKit.hbox(6)
	var d: UnitDef = cat.get_unit(str(e[0]))
	h.add_child(UIKit.portrait(d.id, Vector2(46, 32), d.faction_id))
	var nv := UIKit.vbox(-2)
	nv.add_child(UIKit.label("%s %s" % [Loc.t("unit.%s.name" % d.id), _stars(int(e[1]))], 13, UIKit.TEXT, true))
	var extra := ""
	if absf(float(opt.get("hp_mult", 1.0)) - 1.0) > 0.001:
		extra = "  ×%s" % Describe.fmt(snappedf(float(opt["hp_mult"]), 0.01))
	nv.add_child(UIKit.caption(Loc.t("ui.arena_points", [Describe.fmt(snappedf(am.monster_points(e), 0.1))]) + extra, 10, UIKit.GOLD))
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(nv)
	h.add_child(_small_btn("★−", func() -> void: am.monster_star(i, int(e[1]) - 1)))
	h.add_child(_small_btn("★+", func() -> void: am.monster_star(i, int(e[1]) + 1)))
	h.add_child(_small_btn("×", func() -> void: am.remove_monster(i)))
	return h


# ---------------------------------------------------------------- 测试
func _build_test() -> void:
	_body.add_child(_labeled(Loc.t("ui.arena_map"), _toggle_row([["terrain", Loc.t("ui.arena_map_terrain")], ["flat", Loc.t("ui.arena_map_flat")]],
		am.map_kind, func(k: Variant) -> void: am.set_map(str(k)), 100.0)))
	var rr: Button = UIKit.button(Loc.t("ui.arena_map_reroll"), "normal", Vector2(110, 30))
	rr.add_theme_font_size_override("font_size", 13)
	rr.pressed.connect(func() -> void: am.set_map(am.map_kind, true))
	_body.add_child(_labeled("", rr))
	var tr := CheckBox.new()
	tr.text = Loc.t("ui.arena_traits")
	tr.button_pressed = am.traits_on
	tr.toggled.connect(func(on: bool) -> void: am.set_traits(on))
	_body.add_child(tr)
	# ---- 战斗场数
	_body.add_child(UIKit.section(Loc.t("ui.arena_count"), "Battles"))
	var cr := UIKit.hbox(6)
	cr.add_child(_toggle_row([[1, "1"], [10, "10"], [30, "30"], [100, "100"]], am.battle_count, func(n: Variant) -> void:
		am.battle_count = int(n)
		refresh(), 52.0))
	var sp := SpinBox.new()
	sp.min_value = 1
	sp.max_value = 1000
	sp.value = am.battle_count
	sp.custom_minimum_size = Vector2(100, 30)
	sp.value_changed.connect(func(val: float) -> void:
		am.battle_count = int(val)
		call_deferred("refresh"))
	cr.add_child(sp)
	_body.add_child(cr)
	_body.add_child(_hint("ui.arena_sim_hint"))
	var go: Button
	if am.battle_count <= 1:
		go = UIKit.action_button(Loc.t("ui.arena_start_one"), "Fight", Vector2(W - 40.0, 60))
	else:
		go = UIKit.action_button(Loc.t("ui.arena_start_many", [am.battle_count]), "Simulate", Vector2(W - 40.0, 60))
	go.disabled = am.busy != ""
	go.pressed.connect(func() -> void: am.start())
	UIKit.add_key_hint(go, "SPACE", "tl")
	_body.add_child(go)
	# ---- 进度 / 结果
	if am.busy != "":
		_body.add_child(UIKit.section(Loc.t("ui.arena_running_title"), "Running"))
		_prog_label = UIKit.label("", 14, UIKit.TEXT)
		_body.add_child(_prog_label)
		_prog_bar = UIKit.seg_bar(24, W - 40.0, 10.0, UIKit.ACCENT)
		_body.add_child(_prog_bar)
		_body.add_child(_small_btn(Loc.t("ui.arena_stop"), func() -> void: am.stop(), 90.0))
		show_progress()
	if not am.sim_result.is_empty():
		_build_sim_result()
	# ---- 强度阈值测试
	var ph: Control = UIKit.section(Loc.t("ui.arena_probe"), "Intensity threshold")
	_body.add_child(ph)
	if focus_probe:
		focus_probe = false
		_scroll_to.call_deferred(ph)
	_body.add_child(_hint("ui.arena_probe_hint"))
	_body.add_child(_toggle_row([[false, Loc.t("ui.arena_probe_auto")], [true, Loc.t("ui.arena_probe_mine")]], bool(am.probe_opts.get("keep_cells", false)),
		func(k: Variant) -> void:
			am.probe_opts["keep_cells"] = bool(k)
			refresh(), 130.0))
	_body.add_child(_toggle_row([[40, Loc.t("ui.arena_probe_fast")], [120, Loc.t("ui.arena_probe_full")]], int(am.probe_opts.get("max", 120)),
		func(k: Variant) -> void:
			am.probe_opts["max"] = int(k)
			refresh(), 190.0))
	var pb: Button = UIKit.button(Loc.t("ui.arena_probe_start"), "primary", Vector2(W - 40.0, 40))
	pb.disabled = am.busy != ""
	pb.pressed.connect(func() -> void: am.start_probe())
	_body.add_child(pb)
	if am.probe != null:
		_build_probe_result()


func _build_sim_result() -> void:
	var r: Dictionary = am.sim_result
	_body.add_child(UIKit.section(Loc.t("ui.arena_result"), "Results · %d battles" % int(r["n"])))
	var wr := UIKit.hbox(12)
	var pct: float = 100.0 * float(r["w"]) / float(r["n"])
	var ci: Vector2 = r["ci"]
	var big := UIKit.vbox(-2)
	big.add_child(UIKit.label(Loc.t("ui.arena_winrate"), 13, UIKit.TEXT_DIM))
	big.add_child(UIKit.num("%d%%" % int(round(pct)), 34, UIKit.GOOD if pct >= 70.0 else (UIKit.GOLD if pct >= 40.0 else UIKit.BAD)))
	wr.add_child(big)
	var sv := UIKit.vbox(2)
	sv.add_child(UIKit.label("%d / %d" % [int(r["w"]), int(r["n"])], 14, UIKit.TEXT))
	sv.add_child(UIKit.label(Loc.t("ui.arena_ci", [int(ci.x * 100.0), int(ci.y * 100.0)]), 12, UIKit.TEXT_DIM))
	wr.add_child(sv)
	_body.add_child(wr)
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 12)
	for it: Array in [["ui.arena_avg_time", "%ss" % Describe.fmt(snappedf(float(r["time"]), 0.1))], ["ui.arena_avg_truck", Describe.fmt(snappedf(float(r["truck"]), 0.1))],
			["ui.arena_avg_alive", Describe.fmt(snappedf(float(r["alive"]), 0.1))], ["ui.arena_avg_foes", Describe.fmt(snappedf(float(r["foes"]), 0.1))]]:
		var c := UIKit.vbox(-2)
		c.add_child(UIKit.label(Loc.t(str(it[0])), 11, UIKit.TEXT_DIM))
		c.add_child(UIKit.num(str(it[1]), 18, UIKit.TEXT))
		g.add_child(c)
	_body.add_child(g)
	_body.add_child(UIKit.label(Loc.t("ui.arena_dmg_head"), 12, UIKit.TEXT_DIM))
	for row: Dictionary in r["rows"]:
		var h := UIKit.hbox(6)
		var team: int = int(row["team"])
		h.add_child(UIKit.label("●", 12, UIKit.ACCENT if team == GC.TEAM_PLAYER else UIKit.ENEMY))
		var nm: String = "%s %s" % [Loc.t("unit.%s.name" % str(row["def"])), _stars(int(row["star"]))]
		if absf(float(row["per_battle"]) - 1.0) > 0.01:
			nm += " ×%s" % Describe.fmt(snappedf(float(row["per_battle"]), 0.1))
		var nl: Label = UIKit.label(nm, 12, UIKit.TEXT_SOFT)
		nl.clip_text = true
		nl.custom_minimum_size = Vector2(160, 0)
		h.add_child(nl)
		h.add_child(UIKit.num("%d / %d / %d" % [int(row["damage"]), int(row["taken"]), int(row["heal"])], 13, UIKit.TEXT))
		_body.add_child(h)


func _build_probe_result() -> void:
	var p: IntensityProbe = am.probe
	if p.done:
		var h := UIKit.hbox(12)
		var bv := UIKit.vbox(-2)
		bv.add_child(UIKit.label(Loc.t("ui.arena_probe_best"), 13, UIKit.TEXT_DIM))
		var shown: String = str(p.best) if p.best >= 0 else "<%d" % p.lo
		if p.best >= p.hi:
			shown = "≥%d" % p.best
		bv.add_child(UIKit.num(shown, 40, UIKit.GOLD))
		h.add_child(bv)
		var nf: int = p.next_fail()
		var sv := UIKit.vbox(2)
		if nf >= 0:
			sv.add_child(UIKit.label(Loc.t("ui.arena_probe_next_fail", [nf]), 12, UIKit.TEXT_DIM))
		sv.add_child(UIKit.label(Loc.t("ui.arena_probe_fights", [p.fights]), 12, UIKit.TEXT_DIM))
		h.add_child(sv)
		_body.add_child(h)
	var ks: Array = p.cache.keys()
	ks.sort()
	for k: int in ks:
		var c: Dictionary = p.cache[k]
		var ci: Vector2 = IntensityProbe.wilson(int(c["w"]), int(c["n"]))
		var col: Color = UIKit.GOOD if bool(c["pass"]) else UIKit.BAD
		var row := UIKit.hbox(8)
		var il: Label = UIKit.num("%d" % k, 15, UIKit.TEXT)
		il.custom_minimum_size = Vector2(36, 0)
		row.add_child(il)
		row.add_child(UIKit.label("%d/%d  %d%%" % [int(c["w"]), int(c["n"]), int(100.0 * float(c["w"]) / float(c["n"]))], 12, UIKit.TEXT_SOFT))
		row.add_child(UIKit.label("[%d%%~%d%%]" % [int(ci.x * 100.0), int(ci.y * 100.0)], 11, UIKit.TEXT_MUTE))
		var verdict: String = Loc.t("ui.arena_pass") if bool(c["pass"]) else Loc.t("ui.arena_fail")
		if bool(c["edge"]):
			verdict += "(" + Loc.t("ui.arena_edge") + ")"
		row.add_child(UIKit.tag(verdict, col, false, 11))
		row.add_child(UIKit.label(Loc.t("ui.arena_deploy_" + str(c["dep"])), 11, UIKit.TEXT_DIM))
		_body.add_child(row)


func _scroll_to(c: Control) -> void:
	await get_tree().process_frame
	if is_instance_valid(c) and is_instance_valid(_scroll):
		_scroll.scroll_vertical = int(c.position.y)


## 每帧：进度条和进度文字(不重建整页)
func show_progress() -> void:
	if _prog_label == null or not is_instance_valid(_prog_label):
		return
	if am.busy == "sims":
		_prog_label.text = Loc.t("ui.arena_running", [int(am.sims.get("i", 0)), int(am.sims.get("n", 0)), int(am.sims.get("w", 0))])
		_prog_bar.max_value = float(maxi(1, int(am.sims.get("n", 1))))
		_prog_bar.value = float(am.sims.get("i", 0))
	elif am.busy == "probe" and am.probe != null:
		var pr: Dictionary = am.probe.progress()
		_prog_label.text = Loc.t("ui.arena_probe_now", [int(pr["iv"]), int(pr["w"]), int(pr["n"]), Loc.t("ui.arena_deploy_" + str(pr["deploy"]))])
		_prog_bar.max_value = float(am.probe.max_n)
		_prog_bar.value = float(pr["n"])


## 面板里的头像格：点击 = 加入；拖出去 = 放到战场上(drag_data 交给 GameRoot 的拖放)
class ArenaTile:
	extends PanelContainer
	signal clicked
	var drag_data: Dictionary = {}
	var _press := Vector2(-1, -1)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		var sb: StyleBoxFlat = UIKit.style(UIKit.BG_DEEP, 0, UIKit.BORDER, 1, 2)
		sb.shadow_size = 0
		add_theme_stylebox_override("panel", sb)
		var hot: StyleBoxFlat = sb.duplicate()
		hot.border_color = UIKit.ACCENT
		mouse_entered.connect(func() -> void: add_theme_stylebox_override("panel", hot))
		mouse_exited.connect(func() -> void: add_theme_stylebox_override("panel", sb))

	func _gui_input(ev: InputEvent) -> void:
		var mb := ev as InputEventMouseButton
		if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_press = mb.position
		elif _press.x >= 0.0 and mb.position.distance_to(_press) < 6.0:
			_press = Vector2(-1, -1)
			clicked.emit()

	func _get_drag_data(_pos: Vector2) -> Variant:
		_press = Vector2(-1, -1)
		var prev := PanelContainer.new()
		prev.add_theme_stylebox_override("panel", UIKit.style(UIKit.BG_DEEP, 0, UIKit.ACTION, 2, 2))
		prev.add_child(UIKit.portrait(str(drag_data.get("def", "")), Vector2(80, 56)))
		set_drag_preview(prev)
		return drag_data
