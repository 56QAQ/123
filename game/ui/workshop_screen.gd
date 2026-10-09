class_name WorkshopScreen
extends Control
## 车间(装备制造)：盖在大地图 / 备战界面上的整页界面，代码构建，颜色全走 UIKit 语义色。两个分页：
##  · 制造：01 装备种类(武器；其余种类"尚未开放"，留接口) → 02 门类(至少 3 种) → 03 投入三种材料(配比三角图) → 04 产出预测(颜色 / 稀有度 / 可能的产物) → 制造
##  · 分解：武器库里的武器拆成材料
## 规则在 Crafting(纯逻辑)，动作直接调 Run.craft / Run.salvage(Run.changed 会通知 HUD 刷新)。

signal closed

const COL_W := [560.0, 560.0, 620.0]

var cat: Catalog
var run: Run
var tab: String = "craft"
var kind: String = "weapon"
var cats: Array = []
var mats: Dictionary = {"red": 0, "green": 0, "blue": 0}
var salvage_sel: String = ""

var _tab_buttons: Dictionary = {}
var _body: Control
var _stock_box: HBoxContainer
var _toast: Label
var _toast_tw: Tween
var _result: Control = null
# 制造页里需要局部刷新的控件
var _cat_buttons: Dictionary = {}
var _cat_hint: Label
var _mat_nums: Dictionary = {}
var _mat_owned: Dictionary = {}
var _total_num: Label
var _tri: MixTriangle
var _forecast_box: VBoxContainer
var _craft_btn: Button
var _craft_why: Label


func setup(p_cat: Catalog, p_run: Run) -> void:
	cat = p_cat
	run = p_run
	var last: Dictionary = run.craft_last
	kind = str(last.get("kind", "weapon"))
	var per: Dictionary = last.get("cats", {})
	if per.has(kind):
		cats = (per[kind] as Array).duplicate()
	else:
		cats = team_categories()
	mats = (last.get("mats", {}) as Dictionary).duplicate()
	if mats.is_empty():
		mats = Crafting.empty_mats()
		# 第一次打开：每种各放一点(不超过持有)，至少凑够下限
		for m: String in Crafting.MATS:
			mats[m] = mini(int(run.materials.get(m, 0)), 2)
	_clamp_mats()


func _ready() -> void:
	UIKit.ensure()
	theme = UIKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var o: Color = UIKit.OVERLAY
	bg.color = Color(o.r, o.g, o.b, 0.93)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_build_header()
	_body = Control.new()
	_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_body.offset_left = 64
	_body.offset_top = 214
	_body.offset_right = -64
	_body.offset_bottom = -40
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)
	_toast = UIKit.label("", 18, UIKit.TEXT, true)
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.offset_top = -86
	_toast.offset_bottom = -56
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	UIKit.outlined(_toast, 6)
	add_child(_toast)
	select_tab(tab)


# ---------------------------------------------------------------- 头部：标题 / 材料库存 / 关闭 / 分页
func _build_header() -> void:
	var head := UIKit.vbox(2)
	head.position = Vector2(64, 36)
	add_child(head)
	head.add_child(UIKit.caption("Workshop · Hyperdimensional Workshop", 13, UIKit.ACCENT))
	var row := UIKit.hbox(18)
	row.add_child(UIKit.label(Loc.t("ui.workshop.title"), 46, UIKit.TEXT, true))
	var st := Stripes.new()
	st.color = UIKit.ACTION
	st.custom_minimum_size = Vector2(90, 12)
	st.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(st)
	var sub: Label = UIKit.label(Loc.t("ui.workshop.subtitle"), 15, UIKit.TEXT_DIM)
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(sub)
	head.add_child(row)
	var close: Button = UIKit.button(Loc.t("ui.codex.close"), "normal", Vector2(150, 44))
	close.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close.offset_left = -214
	close.offset_right = -64
	close.offset_top = 48
	close.offset_bottom = 92
	close.pressed.connect(close_screen)
	add_child(close)
	UIKit.add_key_hint(close, "Esc")
	# 材料库存(右上，关闭按钮左边)
	_stock_box = UIKit.hbox(8)
	_stock_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_stock_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_stock_box.offset_right = -236
	_stock_box.offset_top = 40
	add_child(_stock_box)
	_refresh_stock()
	var tabs := UIKit.hbox(6)
	tabs.position = Vector2(64, 138)
	add_child(tabs)
	for tdef: Array in [["craft", "ui.workshop.tab_craft", "FABRICATE"], ["salvage", "ui.workshop.tab_salvage", "SALVAGE"]]:
		var tid: String = tdef[0]
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(196, 58)
		b.pressed.connect(select_tab.bind(tid))
		var v := UIKit.vbox(-2)
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 16
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(UIKit.label(Loc.t(str(tdef[1])), 19, UIKit.TEXT, true))
		v.add_child(UIKit.caption(str(tdef[2]), 10, UIKit.TEXT_DIM))
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for ch: Node in v.get_children():
			(ch as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		tabs.add_child(b)
		_tab_buttons[tid] = b


func _refresh_stock() -> void:
	for ch: Node in _stock_box.get_children():
		ch.queue_free()
	for m: String in Crafting.MATS:
		var p: ArkPanel = UIKit.ark_panel(6, "left", 0, UIKit.BG_DEEP, UIKit.material_color(m))
		p.tooltip_text = "%s\n%s" % [Loc.t("material.%s.name" % m), Loc.t("material.%s.desc" % m)]
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		var h := UIKit.hbox(6)
		h.add_child(UIKit.material_icon(m, 48.0))
		var v := UIKit.vbox(-2)
		v.add_child(UIKit.num(str(int(run.materials.get(m, 0))), 24, UIKit.TEXT))
		v.add_child(UIKit.caption(Loc.t("material.%s.name" % m), 10, UIKit.material_color(m)))
		h.add_child(v)
		p.add_child(h)
		_stock_box.add_child(p)


func select_tab(tid: String) -> void:
	tab = tid
	for k: String in _tab_buttons.keys():
		var on: bool = k == tid
		var b: Button = _tab_buttons[k]
		var sb: StyleBoxFlat = UIKit.style(UIKit.BG if on else UIKit.BG_DEEP, 0, UIKit.ACCENT if on else UIKit.BORDER, 1, 8)
		sb.shadow_size = 0
		if on:
			sb.border_width_bottom = 3
		for st: String in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(st, sb)
	_rebuild_body()


func _rebuild_body() -> void:
	for ch: Node in _body.get_children():
		ch.queue_free()
	_cat_buttons.clear()
	_mat_nums.clear()
	_mat_owned.clear()
	if tab == "craft":
		_build_craft()
		_refresh_craft()
	else:
		_build_salvage()


func _panel(w: float, accent: Color = Color(-1, 0, 0)) -> ArkPanel:
	var p: ArkPanel = UIKit.ark_panel(18, "top", 14, UIKit.BG_DEEP, accent)
	p.corners = true
	p.custom_minimum_size = Vector2(w, 0)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return p


func _step_title(n: int, cn: String, en: String) -> Control:
	var h := UIKit.hbox(10)
	h.add_child(UIKit.num("%02d" % n, 26, UIKit.ACCENT))
	var sec: Control = UIKit.section(cn, en)
	sec.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sec.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(sec)
	return h


# ================================================================ 制造
func _build_craft() -> void:
	var row := UIKit.hbox(16)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_body.add_child(row)
	# ---- 01 装备种类 + 02 门类
	var c1: ArkPanel = _panel(COL_W[0])
	var v1 := UIKit.vbox(12)
	c1.add_child(v1)
	v1.add_child(_step_title(1, Loc.t("ui.workshop.step_kind"), "Type"))
	var kr := UIKit.hbox(8)
	for k: Dictionary in Crafting.kinds(cat):
		var kid: String = str(k.get("id", ""))
		var locked: bool = bool(k.get("locked", false))
		var kb: Button = UIKit.button(Loc.t("ui.workshop.kind." + kid) + ("  · " + Loc.t("ui.workshop.locked") if locked else ""),
			"accent" if kid == kind else "normal", Vector2(250, 48))
		kb.disabled = locked
		kb.pressed.connect(func() -> void:
			kind = kid
			var per: Dictionary = run.craft_last.get("cats", {})
			cats = (per[kid] as Array).duplicate() if per.has(kid) else team_categories()
			_rebuild_body())
		kr.add_child(kb)
	v1.add_child(kr)
	v1.add_child(UIKit.spacer(0, 6))
	v1.add_child(_step_title(2, Loc.t("ui.workshop.step_cats"), "Categories"))
	var hr := UIKit.hbox(8)
	_cat_hint = UIKit.label("", 13, UIKit.TEXT_DIM)
	_cat_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hr.add_child(_cat_hint)
	for q: Array in [["ui.workshop.team", "team"], ["ui.workshop.all", "all"], ["ui.workshop.none", "none"]]:
		var qb: Button = UIKit.button(Loc.t(str(q[0])), "normal", Vector2(84, 32))
		qb.add_theme_font_size_override("font_size", 13)
		var what: String = q[1]
		qb.pressed.connect(func() -> void:
			match what:
				"team":
					cats = team_categories()
				"all":
					cats = (Crafting.kind_cfg(cat, kind).get("categories", []) as Array).duplicate()
				"none":
					cats = []
			_refresh_craft())
		hr.add_child(qb)
	v1.add_child(hr)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for cid: Variant in Crafting.kind_cfg(cat, kind).get("categories", []):
		var cb: Button = _category_button(str(cid))
		grid.add_child(cb)
		_cat_buttons[str(cid)] = cb
	v1.add_child(grid)
	# 规则说明
	v1.add_child(UIKit.spacer(0, 8))
	v1.add_child(UIKit.section(Loc.t("ui.workshop.rules"), "Rules", UIKit.TEXT_DIM))
	var rules: RichTextLabel = UIKit.rich("[color=%s]%s[/color]" % [UIKit.hx(UIKit.TEXT_SOFT), Loc.t("ui.workshop.rules_text", [Crafting.min_categories(cat, kind)])], 13, COL_W[0] - 40.0)
	v1.add_child(rules)
	row.add_child(c1)
	# ---- 03 投入材料 + 配比三角
	var c2: ArkPanel = _panel(COL_W[1])
	var v2 := UIKit.vbox(10)
	c2.add_child(v2)
	v2.add_child(_step_title(3, Loc.t("ui.workshop.step_mats"), "Materials"))
	for m: String in Crafting.MATS:
		v2.add_child(_material_row(m))
	var tr := UIKit.hbox(10)
	tr.add_child(UIKit.label(Loc.t("ui.workshop.total"), 16, UIKit.TEXT_SOFT, true))
	_total_num = UIKit.num("0", 28, UIKit.TEXT)
	tr.add_child(_total_num)
	var lim: Label = UIKit.label(Loc.t("ui.workshop.total_hint", [int(Crafting.cfg(cat).get("min_total", 3)), int(Crafting.cfg(cat).get("max_total", 30))]), 12, UIKit.TEXT_MUTE)
	lim.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lim.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tr.add_child(lim)
	v2.add_child(tr)
	v2.add_child(UIKit.section(Loc.t("ui.workshop.mix"), "Mix", UIKit.TEXT_DIM))
	var tri_row := Control.new()
	tri_row.custom_minimum_size = Vector2(0, 290)
	tri_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tri = MixTriangle.new()
	_tri.cat = cat
	_tri.custom_minimum_size = Vector2.ZERO
	_tri.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tri.offset_left = 90
	_tri.offset_right = -90
	_tri.offset_top = 10
	tri_row.add_child(_tri)
	# 三个角上的材料图标
	for i in range(3):
		var ic: Control = UIKit.material_icon(Crafting.MATS[i], 26.0)
		ic.set_meta("corner", i)
		tri_row.add_child(ic)
	tri_row.resized.connect(_place_corner_icons.bind(tri_row))
	v2.add_child(tri_row)
	var mh: Label = UIKit.label(Loc.t("ui.workshop.mix_hint"), 12, UIKit.TEXT_MUTE)
	mh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mh.custom_minimum_size = Vector2(COL_W[1] - 40.0, 0)
	v2.add_child(mh)
	row.add_child(c2)
	# ---- 04 产出预测 + 制造
	var c3: ArkPanel = _panel(COL_W[2], UIKit.ACTION)
	var v3 := UIKit.vbox(10)
	c3.add_child(v3)
	v3.add_child(_step_title(4, Loc.t("ui.workshop.step_forecast"), "Forecast"))
	_forecast_box = UIKit.vbox(8)
	_forecast_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v3.add_child(_forecast_box)
	_craft_why = UIKit.label("", 13, UIKit.BAD)
	_craft_why.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v3.add_child(_craft_why)
	var br := UIKit.hbox(0)
	br.add_child(UIKit.spacer(0, 0, true))
	_craft_btn = UIKit.action_button(Loc.t("ui.workshop.craft"), "Fabricate", Vector2(300, 74))
	_craft_btn.pressed.connect(do_craft)
	UIKit.add_key_hint(_craft_btn, "SPACE", "tl")
	br.add_child(_craft_btn)
	v3.add_child(br)
	row.add_child(c3)


func _place_corner_icons(holder: Control) -> void:
	if _tri == null:
		return
	await get_tree().process_frame
	if not is_instance_valid(_tri) or not is_instance_valid(holder):
		return
	var cs: Array[Vector2] = _tri.corners()
	var offs: Array[Vector2] = [Vector2(-13, -30), Vector2(-36, -20), Vector2(10, -20)]
	for ch: Node in holder.get_children():
		if ch.has_meta("corner"):
			var i: int = int(ch.get_meta("corner"))
			(ch as Control).position = _tri.position + cs[i] + offs[i]


func _category_button(cid: String) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(166, 72)
	var h := UIKit.hbox(8)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10
	h.offset_right = -8
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g: Glyph = UIKit.weapon_glyph(cid, UIKit.TEXT_SOFT, 34.0)
	g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(g)
	var v := UIKit.vbox(-1)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(UIKit.label(Loc.t("wclass.%s.name" % cid), 17, UIKit.TEXT, true))
	v.add_child(UIKit.label(Loc.t("ui.workshop.cat_count", [Crafting.candidates(cat, kind, [cid]).size()]), 11, UIKit.TEXT_MUTE))
	h.add_child(v)
	for ch: Node in v.get_children():
		(ch as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	b.pressed.connect(func() -> void:
		if cats.has(cid):
			cats.erase(cid)
		else:
			cats.append(cid)
		_refresh_craft())
	return b


func _material_row(m: String) -> Control:
	var p: ArkPanel = UIKit.ark_panel(8, "left", 0, UIKit.BG, UIKit.material_color(m))
	var h := UIKit.hbox(10)
	p.add_child(h)
	h.add_child(UIKit.material_icon(m, 48.0))
	var v := UIKit.vbox(-1)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UIKit.label(Loc.t("material.%s.name" % m), 18, UIKit.TEXT, true))
	v.add_child(UIKit.caption(Loc.t_in("en", "material.%s.name" % m), 9, UIKit.material_color(m)))
	var own: Label = UIKit.label("", 12, UIKit.TEXT_DIM)
	v.add_child(own)
	_mat_owned[m] = own
	h.add_child(v)
	p.tooltip_text = Loc.t("material.%s.desc" % m)
	for d: int in [-5, -1]:
		h.add_child(_step_button(m, d))
	var n: Label = UIKit.num("0", 30, UIKit.TEXT)
	n.custom_minimum_size = Vector2(52, 0)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(n)
	_mat_nums[m] = n
	for d2: int in [1, 5]:
		h.add_child(_step_button(m, d2))
	# 滚轮也能加减
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			var bi: int = (ev as InputEventMouseButton).button_index
			if bi == MOUSE_BUTTON_WHEEL_UP:
				add_material(m, 1)
			elif bi == MOUSE_BUTTON_WHEEL_DOWN:
				add_material(m, -1))
	return p


func _step_button(m: String, d: int) -> Button:
	var b: Button = UIKit.button(("+%d" if d > 0 else "%d") % d if absi(d) > 1 else ("+" if d > 0 else "−"), "normal", Vector2(44 if absi(d) > 1 else 40, 40))
	b.add_theme_font_size_override("font_size", 15 if absi(d) > 1 else 20)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func() -> void: add_material(m, d))
	return b


func add_material(m: String, d: int) -> void:
	var mx: int = int(Crafting.cfg(cat).get("max_total", 30))
	var cur: int = int(mats.get(m, 0))
	var nv: int = clampi(cur + d, 0, int(run.materials.get(m, 0)))
	nv = mini(nv, cur + maxi(0, mx - Crafting.total(mats)))
	mats[m] = maxi(0, nv)
	_refresh_craft()


func _clamp_mats() -> void:
	for m: String in Crafting.MATS:
		mats[m] = clampi(int(mats.get(m, 0)), 0, int(run.materials.get(m, 0)))
	var mx: int = int(Crafting.cfg(cat).get("max_total", 30))
	while Crafting.total(mats) > mx:
		var big: String = "red"
		for m2: String in Crafting.MATS:
			if int(mats[m2]) > int(mats[big]):
				big = m2
		mats[big] = int(mats[big]) - 1


## 按阵容推荐门类(规则在 Run.craft_team_categories)
func team_categories() -> Array:
	return run.craft_team_categories(kind)


func _refresh_craft() -> void:
	if _cat_hint == null or not is_instance_valid(_cat_hint):
		return
	var need: int = Crafting.min_categories(cat, kind)
	_cat_hint.text = Loc.t("ui.workshop.cats_hint", [need, cats.size()])
	_cat_hint.add_theme_color_override("font_color", UIKit.TEXT_DIM if cats.size() >= need else UIKit.BAD)
	for cid: String in _cat_buttons.keys():
		var b: Button = _cat_buttons[cid]
		var on: bool = cats.has(cid)
		b.set_pressed_no_signal(on)
		var sb: StyleBoxFlat = UIKit.style(UIKit.BG if on else UIKit.BG_SOFT, 0, UIKit.ACCENT if on else UIKit.BORDER, 2 if on else 1, 8)
		sb.shadow_size = 0
		if on:
			sb.border_width_left = 4
		var hv: StyleBoxFlat = sb.duplicate() as StyleBoxFlat
		hv.border_color = UIKit.ACCENT
		for st: String in ["normal", "pressed"]:
			b.add_theme_stylebox_override(st, sb)
		b.add_theme_stylebox_override("hover", hv)
		b.add_theme_stylebox_override("hover_pressed", hv)
		b.modulate = Color(1, 1, 1, 1.0 if on else 0.72)
	for m: String in Crafting.MATS:
		(_mat_nums[m] as Label).text = str(int(mats.get(m, 0)))
		(_mat_owned[m] as Label).text = Loc.t("ui.workshop.owned", [int(run.materials.get(m, 0))])
	var n: int = Crafting.total(mats)
	_total_num.text = str(n)
	# 配比三角
	var avail: Dictionary = {}
	for id: String in Crafting.candidates(cat, kind, cats):
		avail[cat.get_equipment(id).color_id] = true
	_tri.avail = avail
	_tri.has_mix = n > 0
	_tri.mix = Crafting.ratio(mats)
	_tri.queue_redraw()
	_refresh_forecast()
	var why: String = Crafting.problem(cat, kind, cats, mats, run.materials)
	_craft_btn.disabled = why != ""
	_craft_why.text = Loc.t(why) if why != "" else ""


func _refresh_forecast() -> void:
	for ch: Node in _forecast_box.get_children():
		ch.queue_free()
	var f: Dictionary = Crafting.forecast(cat, kind, cats, mats)
	var items: Array = f["items"]
	if items.is_empty():
		var e: Label = UIKit.label(Loc.t("ui.workshop.empty_forecast"), 14, UIKit.TEXT_MUTE)
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		e.custom_minimum_size = Vector2(COL_W[2] - 40.0, 0)
		_forecast_box.add_child(e)
		return
	# 颜色
	_forecast_box.add_child(UIKit.section(Loc.t("ui.workshop.color_odds"), "Color", UIKit.TEXT_DIM))
	var colors: Array = (f["colors"] as Dictionary).keys()
	colors.sort_custom(func(a: Variant, b: Variant) -> bool: return float(f["colors"][a]) > float(f["colors"][b]))
	for col: Variant in colors:
		var p: float = float(f["colors"][col])
		if p < 0.005:
			continue
		var cc: Color = GC.faction_color(str(col))
		_forecast_box.add_child(_odds_row(UIKit.faction_dot(str(col), 14.0), Loc.t("color." + str(col)), p, cc.lightened(0.15) if str(col) != "black" else cc.lightened(0.4)))
	# 稀有度
	_forecast_box.add_child(UIKit.section(Loc.t("ui.workshop.rarity_odds"), "Rarity", UIKit.TEXT_DIM))
	var costs: Array = (f["costs"] as Dictionary).keys()
	costs.sort()
	for k: Variant in costs:
		var p2: float = float(f["costs"][k])
		if p2 < 0.005:
			continue
		var pips: HBoxContainer = UIKit.pips(int(k), UIKit.GOLD, 9.0)
		pips.custom_minimum_size = Vector2(56, 0)
		_forecast_box.add_child(_odds_row(pips, Loc.t("ui.workshop.cost_n", [int(k)]), p2, UIKit.GOLD))
	# 可能的产物
	_forecast_box.add_child(UIKit.section(Loc.t("ui.workshop.items"), "Possible results", UIKit.TEXT_DIM))
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var shown := 0
	for it: Array in items:
		if shown >= 12:
			break
		shown += 1
		grid.add_child(_item_cell(str(it[0]), float(it[1])))
	_forecast_box.add_child(grid)
	if items.size() > shown:
		_forecast_box.add_child(UIKit.label(Loc.t("ui.workshop.items_more", [items.size() - shown]), 12, UIKit.TEXT_MUTE))


func _odds_row(icon: Control, name: String, p: float, color: Color) -> Control:
	var h := UIKit.hbox(8)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(icon)
	var l: Label = UIKit.label(name, 14, UIKit.TEXT_SOFT)
	l.custom_minimum_size = Vector2(64, 0)
	h.add_child(l)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = p
	bar.custom_minimum_size = Vector2(300, 12)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg: StyleBoxFlat = UIKit.style(UIKit.BG_SOFT, 0, UIKit.BORDER, 1, 0)
	bg.shadow_size = 0
	var fg: StyleBoxFlat = UIKit.style(color, 0, color, 0, 0)
	fg.shadow_size = 0
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	h.add_child(bar)
	var pct: Label = UIKit.num("%d%%" % int(round(p * 100.0)) if p >= 0.01 else "<1%", 16, UIKit.TEXT)
	pct.custom_minimum_size = Vector2(56, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(pct)
	return h


func _item_cell(id: String, p: float) -> Control:
	var e: EquipmentDef = cat.get_equipment(id)
	var p0: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = UIKit.style(UIKit.BG, 0, GC.faction_color(e.color_id), 1, 4)
	sb.shadow_size = 0
	sb.border_width_bottom = 3
	p0.add_theme_stylebox_override("panel", sb)
	p0.tooltip_text = "%s · %s · %s" % [Loc.t("equipment.%s.name" % id), Loc.t("color." + e.color_id), Loc.t("ui.workshop.cost_n", [e.cost])]
	p0.mouse_filter = Control.MOUSE_FILTER_STOP
	var v := UIKit.vbox(0)
	v.add_child(UIKit.equipment_icon(e, 72.0))
	var l: Label = UIKit.num("%d%%" % int(round(p * 100.0)) if p >= 0.01 else "<1%", 14, UIKit.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	p0.add_child(v)
	return p0


func do_craft() -> void:
	if tab != "craft" or _result != null:
		return
	var res: Dictionary = run.craft(kind, cats, mats)
	if not bool(res.get("ok", false)):
		show_toast(Loc.t(str(res.get("reason", "ui.err.not_now"))), false)
		return
	_clamp_mats()
	_refresh_stock()
	_refresh_craft()
	_show_result(str(res["id"]))


## 制造完成：成品卡片弹出来
func _show_result(id: String) -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var o: Color = UIKit.OVERLAY
	dim.color = Color(o.r, o.g, o.b, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	_result = dim
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(cc)
	var e: EquipmentDef = cat.get_equipment(id)
	var p: ArkPanel = UIKit.ark_panel(24, "top", 14, UIKit.BG_DEEP, GC.faction_color(e.color_id))
	p.corners = true
	var v := UIKit.vbox(12)
	p.add_child(v)
	v.add_child(UIKit.caption("Fabricated", 13, UIKit.ACCENT))
	v.add_child(UIKit.label(Loc.t("ui.workshop.result"), 30, UIKit.TEXT, true))
	v.add_child(TipContent.equipment_tip(cat, id))
	v.add_child(UIKit.label(Loc.t("ui.workshop.result_hint"), 14, UIKit.GOOD))
	var br := UIKit.hbox(0)
	br.add_child(UIKit.spacer(0, 0, true))
	var ok: Button = UIKit.action_button(Loc.t("ui.workshop.again"), "Continue", Vector2(240, 64))
	ok.pressed.connect(close_result)
	UIKit.add_key_hint(ok, "SPACE", "tl")
	br.add_child(ok)
	v.add_child(br)
	cc.add_child(p)
	p.pivot_offset = Vector2(200, 200)
	p.scale = Vector2(0.86, 0.86)
	p.modulate.a = 0.0
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(p, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "modulate:a", 1.0, 0.15)


func close_result() -> void:
	if _result != null:
		_result.queue_free()
		_result = null


## 空格：制造页 = 制造 / 结果卡 = 继续；分解页 = 分解选中的武器
func press_primary() -> void:
	if _result != null:
		close_result()
	elif tab == "craft":
		if _craft_btn != null and not _craft_btn.disabled:
			do_craft()
	elif salvage_sel != "":
		do_salvage()


# ================================================================ 分解
func _build_salvage() -> void:
	var row := UIKit.hbox(16)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_body.add_child(row)
	var left: ArkPanel = _panel(1000.0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UIKit.vbox(10)
	left.add_child(v)
	v.add_child(UIKit.section(Loc.t("ui.inventory"), "Armory"))
	v.add_child(UIKit.label(Loc.t("ui.workshop.salvage_hint"), 13, UIKit.TEXT_DIM))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(grid)
	v.add_child(sc)
	if not run.inventory.has(salvage_sel):
		salvage_sel = ""
	if run.inventory.is_empty():
		v.add_child(UIKit.label(Loc.t("ui.workshop.salvage_empty"), 16, UIKit.TEXT_MUTE))
	for i in range(run.inventory.size()):
		var se: EquipmentDef = cat.get_equipment(run.inventory[i])
		if se != null and not se.is_gear():
			continue                                   # 特殊物品(狩猎旗标)不能分解
		grid.add_child(_salvage_tile(run.inventory[i]))
	row.add_child(left)
	var right: ArkPanel = _panel(COL_W[2], UIKit.BAD)
	var rv := UIKit.vbox(12)
	right.add_child(rv)
	rv.add_child(UIKit.section(Loc.t("ui.workshop.tab_salvage"), "Salvage", UIKit.BAD))
	if salvage_sel == "":
		rv.add_child(UIKit.label(Loc.t("ui.workshop.salvage_pick"), 16, UIKit.TEXT_MUTE))
	else:
		rv.add_child(TipContent.equipment_tip(cat, salvage_sel))
		rv.add_child(UIKit.section(Loc.t("ui.workshop.salvage_gain"), "Yields", UIKit.TEXT_DIM))
		var gain: Dictionary = Crafting.salvage_yield(cat, salvage_sel)
		var gh := UIKit.hbox(16)
		for m: String in Crafting.MATS:
			if int(gain[m]) <= 0:
				continue
			var mh := UIKit.hbox(6)
			mh.add_child(UIKit.material_icon(m, 48.0))
			var mv := UIKit.vbox(-2)
			mv.add_child(UIKit.num("+%d" % int(gain[m]), 26, UIKit.GOOD))
			mv.add_child(UIKit.caption(Loc.t("material.%s.name" % m), 10, UIKit.material_color(m)))
			mh.add_child(mv)
			gh.add_child(mh)
		rv.add_child(gh)
		rv.add_child(UIKit.spacer(0, 0, true))
		var br := UIKit.hbox(0)
		br.add_child(UIKit.spacer(0, 0, true))
		var sb: Button = UIKit.action_button(Loc.t("ui.workshop.salvage_btn"), "Salvage", Vector2(260, 70), "danger")
		sb.pressed.connect(do_salvage)
		UIKit.add_key_hint(sb, "SPACE", "tl")
		br.add_child(sb)
		rv.add_child(br)
	row.add_child(right)


func _salvage_tile(id: String) -> Control:
	var e: EquipmentDef = cat.get_equipment(id)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(150, 132)
	var on: bool = id == salvage_sel
	var sb: StyleBoxFlat = UIKit.style(UIKit.BG if on else UIKit.BG_SOFT, 0, UIKit.BAD if on else GC.faction_color(e.color_id), 2 if on else 1, 6)
	sb.shadow_size = 0
	sb.border_width_bottom = 3
	var hv: StyleBoxFlat = sb.duplicate() as StyleBoxFlat
	hv.bg_color = UIKit.BG
	for st: String in ["normal", "pressed"]:
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_stylebox_override("hover", hv)
	var v := UIKit.vbox(2)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 6
	v.offset_right = -6
	v.offset_top = 4
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic: Control = UIKit.equipment_icon(e, 84.0)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var nl: Label = UIKit.label(Loc.t("equipment.%s.name" % id), 13, UIKit.TEXT, true)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.clip_text = true
	v.add_child(nl)
	var pr: HBoxContainer = UIKit.pips(e.cost, UIKit.GOLD, 8.0)
	pr.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(pr)
	for ch: Node in v.get_children():
		(ch as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	b.pressed.connect(func() -> void:
		salvage_sel = id
		_rebuild_body())
	return b


func do_salvage() -> void:
	if salvage_sel == "":
		return
	var res: Dictionary = run.salvage(salvage_sel)
	if not bool(res.get("ok", false)):
		show_toast(Loc.t(str(res.get("reason", "ui.err.not_now"))), false)
		return
	var parts: Array[String] = []
	for m: String in Crafting.MATS:
		if int(res["gain"][m]) > 0:
			parts.append("%s ×%d" % [Loc.t("material.%s.name" % m), int(res["gain"][m])])
	show_toast(Loc.t("ui.workshop.salvaged", [" · ".join(parts)]), true)
	if not run.inventory.has(salvage_sel):
		salvage_sel = ""
	_refresh_stock()
	_rebuild_body()


func show_toast(text: String, good: bool) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", UIKit.GOOD if good else UIKit.BAD)
	if _toast_tw != null:
		_toast_tw.kill()
	_toast.modulate.a = 1.0
	_toast_tw = create_tween()
	_toast_tw.tween_interval(1.6)
	_toast_tw.tween_property(_toast, "modulate:a", 0.0, 0.5)


func close_screen() -> void:
	run.remember_craft(kind, cats, mats)
	closed.emit()
	queue_free()
