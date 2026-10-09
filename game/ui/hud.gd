class_name HUD
extends Control
## 局内 HUD(超次元工坊 · 战术终端风格)。没有侧边栏：
##   左上：作战信息块(关卡编号 "0-1" + 章节名 + 阶段 + 卡车耐久分段条)
##   上方正中：羁绊芯片；战斗中下面再挂一块双方存活数
##   右上：资源(金币、等级/经验、语言、菜单)；战斗中换成计时 + 倍速 + 暂停 + 跳过
##   下方(备战/拾取)：仓库条(不限数量，横向滚动) + 指挥台(武器库 / 招募 / 升级 + 开始作战)
##   大地图：只有浮在节点上的关卡牌按钮 + 左下角的章节标题字
##   方格网大地图(第一章起)：路口上的节点小方块(GridNodeButton) + 上方正中的行动力面板 + 下方正中的零件栏
## 单位详情是点击后跟随单位的卡片；悬停的提示用小卡片跟随鼠标。配色来自 UIKit(章节主题)，换主题时 rebuild()。

signal buy_requested(index: int)
signal reroll_requested
signal lock_requested
signal xp_requested
signal start_requested
signal speed_changed(s: float)
signal pause_toggled
signal skip_requested
signal menu_requested
signal lang_toggled
signal unequip_requested(roster_id: String, slot: int)
signal sell_requested(roster_id: String)
signal item_hovered(equip_id: String)     # QoL：悬停武器 → 高亮能/不能装备的棋子
signal shop_hovered(def_id: String)       # QoL：悬停招募卡 → 高亮已拥有的同名棋子
signal trait_hovered(trait_id: String)    # QoL：悬停羁绊 → 高亮成员
signal marks_cleared
signal go_requested                      # 地图：出发去下一个节点(点击"下一站"关卡牌)
signal map_hovered(index: int, on: bool)   # 地图：悬停某个关卡牌
signal loot_done_requested               # 拾取战利品：继续前进
signal cargo_dropped(slot: int, data: Dictionary)
signal dock_dropped(data: Dictionary)
signal storage_clicked(roster_id: String)  # 点击仓库里的节点 → 打开详情卡
signal grid_clicked(key: String)           # 方格网大地图：点击一个节点(前往 / 零件目标)
signal grid_hovered(key: String, on: bool)
signal part_clicked(index: int)            # 零件栏：点击一个零件
signal workshop_requested                  # 打开车间(装备制造)
signal truck_rotate_requested              # 备战：旋转卡车(开局改装允许时)

var cat: Catalog
var run: Run
var portraits: Dictionary = {}
var mode: String = "prepare"           # map / travel / prepare / battle / result / loot / none
var battle_defs: Array = []

# ---- 左上：作战信息
var stage_box: ArkPanel
var code_label: Label
var round_label: Label
var type_tag_box: HBoxContainer
var stage_caption: Label
var phase_label: Label
var truck_bar: SegBar
var mods_row: HBoxContainer                # 已选的卡车改装(颜色标签，悬停看说明)
var _mods_shown: String = ""
var truck_label: Label
var truck_num: Label
# ---- 上方：羁绊 / 战斗计数
var trait_box: HBoxContainer
var counts_box: ArkPanel
var arena_box: ArkPanel = null          # 事件战场的机制：备战时在左边空地上写规则，战斗中是上方正中的倒计时(没有 = null)
var _arena_shown: String = "?"
var _hazard_label: Label = null
var _hazard_num: Label = null
var enemy_count: Label
var ally_count: Label
# ---- 右上：资源 / 战斗控制
var econ_box: HBoxContainer
var workshop_btn: Button
var mat_labels: Dictionary = {}            # 材料 -> 库存数字
var gold_label: Label
var level_label: Label
var level_num: Label
var xp_bar: SegBar
var battle_box: HBoxContainer
var timer_label: Label
var speed_btns: Array[Button] = []        # 战斗中右上角的倍速按钮
var prep_speed_btns: Array[Button] = []   # 备战时指挥栏里的倍速按钮(选好的倍速开战时直接生效)
var speed_now: float = 1.0
const SPEEDS: Array[float] = [0.25, 0.5, 1.0, 2.0, 4.0]
var pause_btn: Button
# ---- 下方：仓库 + 指挥台
var dock: DropPanel
var cargo: ArkPanel
var cargo_scroll: ScrollContainer
var cargo_row: HBoxContainer
var cargo_title: Label
var cargo_count: Label
var inv_grid: GridContainer
var shop_row: HBoxContainer
var odds_strip: HBoxContainer                # 制造面板标题旁：当前等级各费用的概率(悬停看整张表)
var flags_row: HBoxContainer                 # 事件留下的诅咒 / 祝福(Run.flags)：红 / 绿标签，悬停看说明
var _flags_shown: String = ""
var reroll_btn: Button
var lock_btn: Button
var xp_btn: Button
var start_btn: Button
var truck_btn: Button                      # 旋转卡车(只在卡车能动的改装下显示)
var sell_overlay: Label
var interest_label: Label
# ---- 大地图
var map_layer: Control
var map_buttons: Array[MapNodeButton] = []
var episode_box: VBoxContainer
# ---- 方格网大地图
var grid_buttons: Dictionary = {}          # 格点 key -> GridNodeButton
var ap_panel: ArkPanel
var ap_num: Label
var ap_max_label: Label
var ap_pips: HBoxContainer
var ap_info: Label
var parts_panel: ArkPanel
var parts_row: HBoxContainer
var part_mode: int = -1                    # 正在给第几个零件选目标(-1 = 没有)
# ---- 拾取
var loot_bar: ArkPanel
var loot_list: VBoxContainer
# ---- 战斗信息流
var feed_box: VBoxContainer
# ---- 悬浮
var tip: ArkPanel
var tip_holder: Control
var card: ArkPanel
var card_holder: Control
var toast: ArkPanel
var toast_label: Label
var banner: Control
var banner_label: Label
var banner_caption: Label
var _banner_tw: Tween
var _toast_tween: Tween
var _tip_owner: Object = null
var tip_pinned: bool = false            # 点击装备后提示固定住：不跟鼠标、悬停别的东西不替换，点空白处 / Esc / 再点一次关闭
var kw_tip: ArkPanel                    # 关键词详情(指着固定提示/详情卡里的蓝字时出现)
var trait_reports: Array = []
var _dnd_sell: bool = false             # 正在把仓库里的节点拖到指挥台上(显示出售价)

## 横幅文字的英文标注
const BANNER_EN := {"ui.battle_go": "Operation Start", "ui.raid": "Truck Under Raid"}


func _ready() -> void:
	UIKit.ensure()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_all()
	set_speed_active(speed_now)
	set_mode("prepare")


func _build_all() -> void:
	theme = UIKit.theme()
	_build_map_layer()
	_build_top()
	_build_dock()
	_build_cargo()
	_build_loot_bar()
	_build_battle()
	_build_overlays()


## 换章节配色后整体重建(保留当前模式与数据)
func rebuild() -> void:
	for ch: Node in get_children():
		remove_child(ch)
		ch.queue_free()
	map_buttons.clear()
	grid_buttons.clear()
	speed_btns.clear()
	prep_speed_btns.clear()
	_tip_owner = null
	tip_pinned = false
	_build_all()
	set_speed_active(speed_now)
	set_mode(mode)


# =============================================================== 构建：上方
func _build_top() -> void:
	# ---- 左上：作战信息块
	stage_box = UIKit.ark_panel(10, "left", 14)
	stage_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stage_box.position = Vector2(16, 14)
	stage_box.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(stage_box)
	var row := UIKit.hbox(12)
	stage_box.add_child(row)
	var badge: PanelContainer = UIKit.code_badge("0-1", 32, Vector2(84, 62))
	code_label = badge.get_child(0) as Label
	row.add_child(badge)
	var info := UIKit.vbox(3)
	var r1 := UIKit.hbox(8)
	round_label = UIKit.label("", 19, UIKit.TEXT, true)
	r1.add_child(round_label)
	type_tag_box = UIKit.hbox(0)
	r1.add_child(type_tag_box)
	info.add_child(r1)
	var r2 := UIKit.hbox(8)
	stage_caption = UIKit.caption("", 10, UIKit.ACCENT)
	r2.add_child(stage_caption)
	phase_label = UIKit.label("", 12, UIKit.TEXT_DIM)
	r2.add_child(phase_label)
	info.add_child(r2)
	var r3 := UIKit.hbox(7)
	r3.add_child(UIKit.glyph("truck", UIKit.TEXT_SOFT, 20.0))
	truck_label = UIKit.label(Loc.t("ui.truck"), 12, UIKit.TEXT_DIM)
	r3.add_child(truck_label)
	truck_bar = UIKit.seg_bar(10, 150, 8, UIKit.GOOD)
	truck_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r3.add_child(truck_bar)
	truck_num = UIKit.num("", 15, UIKit.TEXT)
	r3.add_child(truck_num)
	info.add_child(r3)
	mods_row = UIKit.hbox(4)
	_mods_shown = ""                        # 面板重建(切换语言)后标签要重新生成
	info.add_child(mods_row)
	flags_row = UIKit.hbox(4)
	_flags_shown = ""
	info.add_child(flags_row)
	row.add_child(info)
	# ---- 上方正中：羁绊芯片
	trait_box = UIKit.hbox(8)
	trait_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	trait_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	trait_box.offset_top = 22
	add_child(trait_box)
	# ---- 右上：资源
	econ_box = UIKit.hbox(8)
	econ_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	econ_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	econ_box.offset_right = -16
	econ_box.offset_top = 14
	add_child(econ_box)
	var gold := UIKit.ark_panel(8, "", 0)
	gold.mouse_filter = Control.MOUSE_FILTER_STOP
	var gh := UIKit.hbox(6)
	gh.add_child(UIKit.glyph("coin", Color.WHITE, 24.0))
	var gv := UIKit.vbox(-2)
	gold_label = UIKit.num("0", 26, UIKit.GOLD)
	gv.add_child(gold_label)
	gv.add_child(UIKit.caption("Gold", 9))
	gh.add_child(gv)
	gold.add_child(gh)
	econ_box.add_child(gold)
	var lv := UIKit.ark_panel(8, "", 0)
	lv.mouse_filter = Control.MOUSE_FILTER_STOP
	var lvv := UIKit.vbox(3)
	var lh := UIKit.hbox(6)
	lh.add_child(UIKit.caption("LV", 11, UIKit.ACCENT))
	level_num = UIKit.num("1", 24, UIKit.TEXT)
	lh.add_child(level_num)
	level_label = UIKit.label("", 12, UIKit.TEXT_DIM)
	level_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lh.add_child(level_label)
	lvv.add_child(lh)
	xp_bar = UIKit.seg_bar(8, 120, 4, UIKit.ACCENT)
	lvv.add_child(xp_bar)
	lv.add_child(lvv)
	econ_box.add_child(lv)
	econ_box.add_child(_build_workshop_button())
	var lang: Button = UIKit.button("中/EN", "normal", Vector2(64, 50))
	lang.pressed.connect(func() -> void: lang_toggled.emit())
	econ_box.add_child(lang)
	var menu: Button = UIKit.button("≡", "normal", Vector2(56, 50))
	menu.add_theme_font_size_override("font_size", 22)
	menu.pressed.connect(func() -> void: menu_requested.emit())
	UIKit.add_key_hint(menu, "ESC")
	econ_box.add_child(menu)


## 右上角的车间入口：三种材料的库存(像素图标 + 数字) + "车间"，点一下打开车间(C)
func _build_workshop_button() -> Button:
	workshop_btn = Button.new()
	workshop_btn.focus_mode = Control.FOCUS_NONE
	workshop_btn.custom_minimum_size = Vector2(0, 50)
	var n: StyleBoxFlat = UIKit.style(UIKit.BG, 0, UIKit.BORDER, 1, 8)
	n.shadow_size = 0
	n.border_width_left = 3
	n.border_color = UIKit.ACCENT
	var h: StyleBoxFlat = n.duplicate() as StyleBoxFlat
	h.bg_color = UIKit.BG_SOFT
	h.border_width_bottom = 2
	var d: StyleBoxFlat = n.duplicate() as StyleBoxFlat
	d.border_color = UIKit.BORDER
	workshop_btn.add_theme_stylebox_override("normal", n)
	workshop_btn.add_theme_stylebox_override("hover", h)
	workshop_btn.add_theme_stylebox_override("pressed", h)
	workshop_btn.add_theme_stylebox_override("disabled", d)
	var row := UIKit.hbox(8)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 10
	row.offset_right = -10
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tv := UIKit.vbox(-2)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.add_child(UIKit.label(Loc.t("ui.workshop.open"), 16, UIKit.TEXT, true))
	tv.add_child(UIKit.caption("Workshop", 9, UIKit.ACCENT))
	row.add_child(tv)
	mat_labels.clear()
	for m: String in Crafting.MATS:
		var mh := UIKit.hbox(2)
		var ic: Control = UIKit.material_icon(m, 26.0)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mh.add_child(ic)
		var nl: Label = UIKit.num("0", 20, UIKit.TEXT)
		nl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mh.add_child(nl)
		mat_labels[m] = nl
		row.add_child(mh)
	for ch: Node in row.get_children():
		_ignore_mouse(ch)
	workshop_btn.add_child(row)
	row.minimum_size_changed.connect(func() -> void: workshop_btn.custom_minimum_size.x = row.get_combined_minimum_size().x + 20.0)
	workshop_btn.custom_minimum_size.x = 250
	workshop_btn.tooltip_text = "%s
%s" % [Loc.t("ui.workshop.materials"), Loc.t("ui.workshop.open_hint")]
	workshop_btn.pressed.connect(func() -> void: workshop_requested.emit())
	UIKit.add_key_hint(workshop_btn, "C")
	return workshop_btn


func _ignore_mouse(n: Node) -> void:
	if n is Control:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for ch: Node in n.get_children():
		_ignore_mouse(ch)


# =============================================================== 构建：战斗
func _build_battle() -> void:
	battle_box = UIKit.hbox(6)
	battle_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	battle_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	battle_box.offset_right = -16
	battle_box.offset_top = 14
	add_child(battle_box)
	var tp := UIKit.ark_panel(8, "", 0)
	var tv := UIKit.vbox(-2)
	timer_label = UIKit.num("00:00", 26, UIKit.TEXT)
	tv.add_child(timer_label)
	tv.add_child(UIKit.caption("Time", 9))
	tp.add_child(tv)
	battle_box.add_child(tp)
	for s: float in SPEEDS:
		var b: Button = UIKit.button(speed_text(s), "normal", Vector2(56 if s >= 1.0 else 68, 52))
		b.add_theme_font_override("font", UIKit.font_num)
		b.add_theme_font_size_override("font_size", 20 if s >= 1.0 else 17)
		b.pressed.connect(func() -> void:
			speed_changed.emit(s)
			set_speed_active(s))
		UIKit.add_key_hint(b, str(speed_btns.size() + 1))
		battle_box.add_child(b)
		speed_btns.append(b)
	pause_btn = UIKit.button("❚❚", "normal", Vector2(56, 52))
	pause_btn.pressed.connect(func() -> void: pause_toggled.emit())
	UIKit.add_key_hint(pause_btn, "SPACE")
	battle_box.add_child(pause_btn)
	var skip: Button = UIKit.button(Loc.t("ui.skip"), "normal", Vector2(76, 52))
	skip.pressed.connect(func() -> void: skip_requested.emit())
	battle_box.add_child(skip)
	var menu: Button = UIKit.button("≡", "normal", Vector2(56, 52))
	menu.add_theme_font_size_override("font_size", 22)
	menu.pressed.connect(func() -> void: menu_requested.emit())
	UIKit.add_key_hint(menu, "ESC")
	battle_box.add_child(menu)
	# 双方存活数(上方正中，羁绊下面)
	counts_box = UIKit.ark_panel(8, "", 0)
	counts_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	counts_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	counts_box.offset_top = 70
	add_child(counts_box)
	var ch := UIKit.hbox(10)
	ch.add_child(UIKit.glyph("skull", UIKit.ENEMY, 18.0))
	ch.add_child(UIKit.label(Loc.t("ui.enemy"), 13, UIKit.TEXT_DIM))
	enemy_count = UIKit.num("0/0", 22, UIKit.ENEMY)
	ch.add_child(enemy_count)
	var sep := UIKit.vline(1.5)
	sep.custom_minimum_size = Vector2(1, 22)
	ch.add_child(sep)
	ch.add_child(UIKit.glyph("heart", UIKit.PLAYER, 16.0))
	ch.add_child(UIKit.label(Loc.t("ui.ally"), 13, UIKit.TEXT_DIM))
	ally_count = UIKit.num("0/0", 22, UIKit.PLAYER)
	ch.add_child(ally_count)
	counts_box.add_child(ch)
	# 事件战场的机制：面板在 _refresh_arena 里按需要现做
	arena_box = null
	_arena_shown = "?"
	# 信息流(左下)
	feed_box = UIKit.vbox(3)
	feed_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	feed_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	feed_box.offset_left = 16
	feed_box.offset_bottom = -16
	feed_box.custom_minimum_size = Vector2(460, 0)
	add_child(feed_box)


# =============================================================== 构建：指挥台(武器库 / 招募 / 升级 + 开始作战)
func _build_dock() -> void:
	dock = DropPanel.new()
	dock.add_theme_stylebox_override("panel", _dock_style(false))
	# 仓库里的节点拖到指挥台(包括节点制造的卡片上) = 出售：悬停时整块指挥台显示出售价
	dock.can_drop_cb = func(data: Variant) -> bool:
		if not (data is Dictionary):
			return false
		var dd: Dictionary = data
		# 详情卡里拖出来的武器拖回指挥台(武器库) = 卸下
		if str(dd.get("kind", "")) == "equip" and dd.has("from"):
			_dnd_sell = true
			set_sell_hint(true, 0, Loc.t("ui.unequip_drop"), false)
			return true
		if str(dd.get("kind", "")) != "roster":
			return false
		var rid: String = str(dd.get("id", ""))
		if run != null and run.roster.has(rid):
			_dnd_sell = true
			set_sell_hint(true, run.sell_value(run.roster[rid]))
		return true
	dock.drop_cb = func(data: Variant) -> void:
		_dnd_sell = false
		set_sell_hint(false)
		dock_dropped.emit(data as Dictionary)
	dock.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dock.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dock.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dock.offset_bottom = -12
	dock.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dock)
	var row := UIKit.hbox(14)
	dock.add_child(row)
	# ---- 武器库
	var inv := UIKit.vbox(6)
	inv.custom_minimum_size = Vector2(268, 0)
	inv.add_child(UIKit.section(Loc.t("ui.inventory"), "Armory"))
	inv.add_child(UIKit.label(Loc.t("ui.drag_to_equip"), 11, UIKit.TEXT_MUTE))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(268, 132)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inv_grid = GridContainer.new()
	inv_grid.columns = 4
	inv_grid.add_theme_constant_override("h_separation", 6)
	inv_grid.add_theme_constant_override("v_separation", 6)
	sc.add_child(inv_grid)
	inv.add_child(sc)
	row.add_child(inv)
	row.add_child(UIKit.vline())
	# ---- 招募
	var shop := UIKit.vbox(6)
	var sh := UIKit.hbox(8)
	var sec: Control = UIKit.section(Loc.t("ui.shop"), "Fabrication")
	sec.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.add_child(sec)
	odds_strip = UIKit.hbox(14)
	odds_strip.mouse_filter = Control.MOUSE_FILTER_PASS      # 要收到悬停，但拖着节点经过时拖放仍穿透给指挥台
	odds_strip.mouse_entered.connect(func() -> void: show_tip(_odds_tip(), odds_strip))
	odds_strip.mouse_exited.connect(func() -> void:
		if _tip_owner == odds_strip:
			hide_tip())
	sh.add_child(odds_strip)
	reroll_btn = UIKit.button("", "normal", Vector2(104, 30))
	reroll_btn.add_theme_font_size_override("font_size", 14)
	reroll_btn.pressed.connect(func() -> void: reroll_requested.emit())
	sh.add_child(_with_key(reroll_btn, "R"))
	lock_btn = UIKit.button("", "normal", Vector2(70, 30))
	lock_btn.add_theme_font_size_override("font_size", 14)
	lock_btn.pressed.connect(func() -> void: lock_requested.emit())
	sh.add_child(_with_key(lock_btn, "L"))
	shop.add_child(sh)
	shop_row = UIKit.hbox(8)
	shop.add_child(shop_row)
	row.add_child(shop)
	row.add_child(UIKit.vline())
	# ---- 指挥：收入提示 / 升级 / 开始作战
	var act := UIKit.vbox(8)
	act.custom_minimum_size = Vector2(250, 0)
	act.add_child(UIKit.section(Loc.t("ui.command"), "Command"))
	interest_label = UIKit.label("", 12, UIKit.TEXT_DIM)
	act.add_child(interest_label)
	xp_btn = UIKit.button("", "normal", Vector2(250, 40))
	xp_btn.add_theme_font_size_override("font_size", 14)
	xp_btn.pressed.connect(func() -> void: xp_requested.emit())
	act.add_child(_with_key(xp_btn, "X"))
	truck_btn = UIKit.button(Loc.t("ui.truck_rotate"), "normal", Vector2(250, 30))
	truck_btn.add_theme_font_size_override("font_size", 14)
	truck_btn.tooltip_text = Loc.t("ui.truck_rotate_tip")
	truck_btn.pressed.connect(func() -> void: truck_rotate_requested.emit())
	truck_btn.visible = false
	act.add_child(_with_key(truck_btn, "T"))
	act.add_child(UIKit.spacer(0, 0, true))
	# 战斗倍速：备战时就能选好(开战时直接生效，以后每场沿用)
	var spd := UIKit.hbox(3)
	var sl := UIKit.vbox(-3)
	sl.custom_minimum_size = Vector2(36, 0)
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sl.add_child(UIKit.label(Loc.t("ui.speed_label"), 12, UIKit.TEXT_DIM, true))
	sl.add_child(UIKit.caption("Speed", 8))
	spd.add_child(sl)
	for s2: float in SPEEDS:
		var pb: Button = UIKit.button(speed_text(s2), "normal", Vector2(40 if s2 >= 1.0 else 46, 28))
		pb.add_theme_font_override("font", UIKit.font_num)
		pb.add_theme_font_size_override("font_size", 14 if s2 >= 1.0 else 12)
		pb.tooltip_text = Loc.t("ui.speed_tip")
		pb.pressed.connect(func() -> void:
			speed_changed.emit(s2)
			set_speed_active(s2))
		spd.add_child(pb)
		prep_speed_btns.append(pb)
	act.add_child(spd)
	start_btn = UIKit.action_button(Loc.t("ui.start_battle"), "Start Operation", Vector2(250, 70))
	start_btn.pressed.connect(func() -> void:
		if mode == "loot":
			loot_done_requested.emit()
		else:
			start_requested.emit())
	start_btn.mouse_filter = Control.MOUSE_FILTER_PASS
	UIKit.add_key_hint(start_btn, "SPACE", "tl")
	act.add_child(start_btn)
	row.add_child(act)
	# 出售提示层
	sell_overlay = UIKit.label("", 28, Color.WHITE, true)
	sell_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	sell_overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sell_overlay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sell_overlay.visible = false
	dock.add_child(sell_overlay)


func _dock_style(selling: bool) -> StyleBoxFlat:
	var s: StyleBoxFlat = UIKit.style(Color(UIKit.BAD.r * 0.35, UIKit.BAD.g * 0.3, UIKit.BAD.b * 0.3, 0.95) if selling else UIKit.BG, 14,
		UIKit.BAD if selling else UIKit.BORDER, 2 if selling else 1, 12)
	s.border_width_top = 2
	s.border_color = UIKit.BAD if selling else UIKit.ACCENT
	return s


## 仓库条：卡车货厢里暂不出战的节点(不限数量，横向滚动)；在指挥台上方
func _build_cargo() -> void:
	cargo = UIKit.ark_panel(6, "left", 0, Color(UIKit.BG.r, UIKit.BG.g, UIKit.BG.b, 0.82))
	cargo.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	cargo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	cargo.grow_vertical = Control.GROW_DIRECTION_BEGIN
	cargo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(cargo)
	var row := UIKit.hbox(10)
	cargo.add_child(row)
	var t := UIKit.vbox(0)
	t.custom_minimum_size = Vector2(74, 0)
	var th := UIKit.hbox(6)
	th.add_child(UIKit.glyph("truck", UIKit.ACCENT, 22.0))
	cargo_count = UIKit.num("0", 22, UIKit.TEXT)
	th.add_child(cargo_count)
	t.add_child(th)
	cargo_title = UIKit.label(Loc.t("ui.cargo"), 16, UIKit.TEXT, true)
	t.add_child(cargo_title)
	t.add_child(UIKit.caption("Storage", 9, UIKit.ACCENT))
	row.add_child(t)
	cargo_scroll = ScrollContainer.new()
	cargo_scroll.custom_minimum_size = Vector2(400, StorageCard.H + 4)
	cargo_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cargo_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cargo_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	row.add_child(cargo_scroll)
	cargo_row = UIKit.hbox(6)
	cargo_scroll.add_child(cargo_row)


# =============================================================== 构建：大地图 / 拾取 / 悬浮
## 大地图：没有面板，只有浮在地图节点上的关卡牌 + 左下角的章节标题字
func _build_map_layer() -> void:
	map_layer = Control.new()
	map_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map_layer)
	var plate: ArkPanel = UIKit.ark_panel(14, "left", 14, UIKit.BG_DEEP)
	plate.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	plate.grow_vertical = Control.GROW_DIRECTION_BEGIN
	plate.offset_left = 24
	plate.offset_bottom = -24
	map_layer.add_child(plate)
	episode_box = UIKit.vbox(0)
	plate.add_child(episode_box)
	# 行动力面板(上方正中)
	ap_panel = UIKit.ark_panel(10, "top", 12, UIKit.BG_DEEP)
	ap_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	ap_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ap_panel.offset_top = 16
	ap_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	map_layer.add_child(ap_panel)
	var ah := UIKit.hbox(14)
	ap_panel.add_child(ah)
	ah.add_child(UIKit.glyph("fuel", UIKit.ACTION, 30.0))
	var av := UIKit.vbox(0)
	av.add_child(UIKit.caption(Loc.t("ui.ap_en"), 10, UIKit.ACCENT))
	av.add_child(UIKit.label(Loc.t("ui.ap"), 16, UIKit.TEXT, true))
	ah.add_child(av)
	var anh := UIKit.hbox(2)
	ap_num = UIKit.num("0", 40, UIKit.ACTION)
	anh.add_child(ap_num)
	ap_max_label = UIKit.num("/0", 20, UIKit.TEXT_DIM)
	ap_max_label.size_flags_vertical = Control.SIZE_SHRINK_END
	anh.add_child(ap_max_label)
	ah.add_child(anh)
	var av2 := UIKit.vbox(4)
	av2.alignment = BoxContainer.ALIGNMENT_CENTER
	ap_pips = UIKit.hbox(3)
	av2.add_child(ap_pips)
	ap_info = UIKit.label("", 12, UIKit.TEXT_DIM)
	av2.add_child(ap_info)
	ah.add_child(av2)
	# 零件栏(下方正中)
	parts_panel = UIKit.ark_panel(8, "left", 10, UIKit.BG_DEEP)
	parts_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	parts_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	parts_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	parts_panel.offset_bottom = -24
	parts_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	map_layer.add_child(parts_panel)
	var ph := UIKit.hbox(10)
	parts_panel.add_child(ph)
	var pv := UIKit.vbox(0)
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	pv.add_child(UIKit.caption(Loc.t("ui.parts_en"), 10, UIKit.ACCENT))
	pv.add_child(UIKit.label(Loc.t("ui.parts"), 15, UIKit.TEXT, true))
	ph.add_child(pv)
	ph.add_child(UIKit.vline(0.6))
	parts_row = UIKit.hbox(6)
	ph.add_child(parts_row)


func _refresh_episode() -> void:
	for ch: Node in episode_box.get_children():
		ch.queue_free()
	var n: String = chapter_number(run.chapter_id)
	var h := UIKit.hbox(14)
	h.add_child(UIKit.num(n.pad_zeros(2), 54, UIKit.ACCENT))
	var v := UIKit.vbox(0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(UIKit.caption("Episode %s" % n.pad_zeros(2), 11, UIKit.ACCENT))
	v.add_child(UIKit.label(Loc.t("chapter.%s.short" % run.chapter_id), 30, UIKit.TEXT, true))
	v.add_child(UIKit.caption(Loc.t_in("en", "chapter.%s.short" % run.chapter_id), 10, UIKit.TEXT_DIM))
	h.add_child(v)
	episode_box.add_child(h)


func _build_loot_bar() -> void:
	loot_bar = UIKit.ark_panel(10, "left", 0)
	loot_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	loot_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	loot_bar.offset_top = 96
	add_child(loot_bar)
	var h := UIKit.hbox(10)
	h.add_child(UIKit.glyph("gem", UIKit.GOLD, 22.0))
	h.add_child(UIKit.label(Loc.t("ui.loot_title"), 18, UIKit.TEXT, true))
	var cap: Label = UIKit.caption("Claim the orbs", 10, UIKit.ACCENT)
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(cap)
	loot_bar.add_child(h)
	_ignore_mouse(loot_bar)                 # 横幅只是提示：地图北沿的晶球(战场变大后更靠上)在它底下也要点得到
	loot_list = UIKit.vbox(4)
	loot_list.set_anchors_preset(Control.PRESET_CENTER_TOP)
	loot_list.grow_horizontal = Control.GROW_DIRECTION_BOTH
	loot_list.offset_top = 152
	add_child(loot_list)


func _build_overlays() -> void:
	toast = UIKit.ark_panel(10, "left", 0, UIKit.BG_DEEP)
	toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast.offset_top = 96
	toast.visible = false
	toast_label = UIKit.label("", 16, UIKit.TEXT, true)
	toast.add_child(toast_label)
	add_child(toast)
	_ignore_mouse(toast)
	card_holder = Control.new()
	card_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_holder)
	card = UIKit.ark_panel(14, "top", 14, UIKit.BG_DEEP)
	card.corners = true
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.visible = false
	card_holder.add_child(card)
	tip_holder = Control.new()
	tip_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tip_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tip_holder)
	tip = UIKit.ark_panel(11, "top", 0, UIKit.BG_DEEP)
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.visible = false
	tip_holder.add_child(tip)
	kw_tip = UIKit.ark_panel(10, "top", 0, UIKit.BG_DEEP)
	kw_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kw_tip.visible = false
	tip_holder.add_child(kw_tip)
	UIKit.kw_handler = _on_kw_hover      # 方法回调(不用 lambda)：静态变量里存 lambda，退出时脚本销毁会留下孤儿 lambda 导致崩溃
	# 横幅：横贯屏幕的深色条带 + 大字 + 英文标注
	banner = Control.new()
	banner.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	banner.anchor_right = 1.0
	banner.offset_top = -70
	banner.offset_bottom = 70
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.visible = false
	add_child(banner)
	var bg := ColorRect.new()
	bg.color = Color(UIKit.BG_DEEP.r, UIKit.BG_DEEP.g, UIKit.BG_DEEP.b, 0.82)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(bg)
	for top_edge: bool in [true, false]:
		var ln := ColorRect.new()
		ln.color = UIKit.ACCENT
		ln.set_anchors_preset(Control.PRESET_TOP_WIDE if top_edge else Control.PRESET_BOTTOM_WIDE)
		if top_edge:
			ln.offset_bottom = 2
		else:
			ln.offset_top = -2
		ln.mouse_filter = Control.MOUSE_FILTER_IGNORE
		banner.add_child(ln)
	var bv := UIKit.vbox(0)
	bv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bv.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_label = UIKit.label("", 56, UIKit.TEXT, true)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(banner_label)
	banner_caption = UIKit.caption("", 14, UIKit.ACCENT)
	banner_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(banner_caption)
	banner.add_child(bv)
	# 横幅/吐司在卡片与提示下面，不挡住正在看的信息
	move_child(banner, toast.get_index() + 1)


# =============================================================== 模式
func set_mode(m: String) -> void:
	mode = m
	var manage: bool = m == "prepare" or m == "loot"
	dock.visible = manage
	cargo.visible = manage or m == "arena"            # 测试场：只有仓库条(没有商店 / 武器库 / 升级)，右边是测试场面板
	map_layer.visible = m == "map"
	loot_bar.visible = m == "loot"
	battle_box.visible = m == "battle"
	counts_box.visible = m == "battle"
	feed_box.visible = m == "battle"
	econ_box.visible = m != "battle" and m != "none" and m != "arena" and not (run != null and run.sandbox)
	stage_box.visible = m != "none"
	trait_box.visible = m == "prepare" or m == "battle" or m == "loot" or m == "arena"
	if m == "loot":
		UIKit.set_action_text(start_btn, Loc.t("ui.loot_continue"), "Drive On")
	else:
		UIKit.set_action_text(start_btn, Loc.t("ui.start_battle"), "Start Operation")
	hide_card()
	hide_tip()
	refresh()
	# 仓库条贴在指挥台上方，宽度与指挥台一致
	if cargo.visible:
		await get_tree().process_frame
		if is_instance_valid(cargo) and is_instance_valid(dock):
			if mode == "arena":
				cargo.custom_minimum_size.x = 1000.0
				cargo.offset_bottom = -12.0
			else:
				cargo.custom_minimum_size.x = dock.size.x
				cargo.offset_bottom = -(dock.size.y + 20.0)


## 倍速的按钮文字：×0.25 / ×0.5 / ×1 / ×2 / ×4
static func speed_text(s: float) -> String:
	return "×" + Describe.fmt(s)


func set_speed_active(s: float) -> void:
	speed_now = s
	for btns: Array[Button] in [speed_btns, prep_speed_btns]:
		for i in range(btns.size()):
			var on: bool = is_equal_approx(SPEEDS[i], s)
			btns[i].add_theme_color_override("font_color", UIKit.ACCENT if on else UIKit.TEXT_DIM)
			var sb: StyleBoxFlat = UIKit.style(UIKit.BG_DEEP if on else UIKit.BG_SOFT, 0, UIKit.ACCENT if on else UIKit.BORDER, 1, 4 if btns == prep_speed_btns else 8)
			sb.shadow_size = 0
			if on:
				sb.border_width_bottom = 3
			btns[i].add_theme_stylebox_override("normal", sb)


func set_paused_ui(p: bool) -> void:
	pause_btn.text = "▶" if p else "❚❚"


# =============================================================== 刷新
func refresh() -> void:
	if run == null or cat == null:
		return
	var ch_n: String = chapter_number(run.chapter_id)
	var ni: int = mini(run.node_index + 1, run.total_nodes())
	code_label.text = "%s-%d" % [ch_n, ni] if not run.is_grid() else "%s-%02d" % [ch_n, run.steps]
	round_label.text = Loc.t("chapter.%s.short" % run.chapter_id)
	for c: Node in type_tag_box.get_children():
		c.queue_free()
	var nd: Dictionary = run.current_node()
	var tkey: String = run.battle_kind() if run.is_grid() and (run.hunt_active or run.phase == "prepare" or run.phase == "battle") else str(nd.get("type", "reward"))
	type_tag_box.add_child(UIKit.tag(Loc.t("ui.node_type." + tkey), UIKit.ENEMY if tkey == "hunt" or tkey == "boss" else UIKit.ACCENT, tkey == "hunt"))
	if run.is_grid():
		stage_caption.text = ("Chapter %s · Step %02d · AP %d/%d" % [ch_n, run.steps, run.ap, run.ap_max]).to_upper()
	else:
		stage_caption.text = ("Chapter %s · Node %02d/%02d" % [ch_n, ni, run.total_nodes()]).to_upper()
	phase_label.text = Loc.t("ui.phase." + ("battle" if mode == "battle" else run.phase))
	truck_label.text = Loc.t("ui.truck")
	truck_num.text = "%d/%d" % [run.truck_hp, run.truck_max]
	truck_bar.max_value = float(run.truck_max)
	truck_bar.value = float(run.truck_hp)
	var frac: float = float(run.truck_hp) / maxf(1.0, float(run.truck_max))
	truck_bar.fill = UIKit.GOOD if frac > 0.5 else (UIKit.GOLD if frac > 0.25 else UIKit.BAD)
	_refresh_mods()
	_refresh_flags()
	gold_label.text = str(run.gold)
	for m: String in mat_labels.keys():
		(mat_labels[m] as Label).text = str(int(run.materials.get(m, 0)))
	if workshop_btn != null:
		workshop_btn.disabled = not (mode == "map" or mode == "prepare" or mode == "loot")
	level_num.text = str(run.level)
	level_label.text = Loc.t("ui.deploy_cap", [run.board_count(), run.board_capacity()])
	var need: int = run.next_level_xp()
	xp_bar.max_value = maxf(1.0, float(need))
	xp_bar.value = float(run.xp) if need > 0 else xp_bar.max_value
	_refresh_traits()
	_refresh_arena()
	if mode == "prepare" or mode == "loot":
		_refresh_dock()
		_refresh_cargo()
	if mode == "arena":
		_refresh_cargo()
	if run.sandbox:                                     # 测试场(布阵 / 战斗 / 结算)：左上角写测试场，不写章节进度
		code_label.text = "TR"
		round_label.text = Loc.t("ui.arena_title")
		for c2: Node in type_tag_box.get_children():
			c2.queue_free()
		type_tag_box.add_child(UIKit.tag(Loc.t("ui.arena"), UIKit.ACCENT, false))
		stage_caption.text = "TEST RANGE · %s" % Loc.t_in("en", "chapter.%s.short" % run.chapter_id).to_upper()
		phase_label.text = Loc.t("ui.phase.battle") if mode == "battle" else Loc.t("ui.arena_phase")
	if mode == "map":
		_refresh_map_buttons()
		_refresh_episode()
		_refresh_ap()


## 章节编号的显示：ch0 → 0，ch1_red → 1-A(蓝/绿 = B/C)
static func chapter_number(cid: String) -> String:
	var core: String = cid.trim_prefix("ch")
	var parts: PackedStringArray = core.split("_")
	if parts.size() > 1:
		return "%s-%s" % [parts[0], {"red": "A", "blue": "B", "green": "C", "purple": "A", "yellow": "B", "cyan": "C"}.get(parts[1], parts[1].to_upper())]
	return core


## 已选的卡车改装：卡车耐久下面一排按改装颜色着色的小标签，悬停看名字 + 说明
func _refresh_mods() -> void:
	var key: String = ",".join(run.truck_mods) + "|" + Loc.lang
	if key == _mods_shown:
		return
	_mods_shown = key
	for c: Node in mods_row.get_children():
		mods_row.remove_child(c)
		c.queue_free()
	for id: String in run.truck_mods:
		var d: Dictionary = cat.mods.get(id, {})
		var tg: PanelContainer = UIKit.tag(Loc.t("mod.%s.name" % id), GC.faction_color(str(d.get("color", "white"))), false, 10)
		tg.mouse_filter = Control.MOUSE_FILTER_STOP
		tg.tooltip_text = "%s(%s)\n%s" % [Loc.t("mod.%s.name" % id), Loc.t("ui.mod_rarity", [int(d.get("rarity", 1))]), plain_text(Loc.t("mod.%s.desc" % id))]
		mods_row.add_child(tg)
	mods_row.visible = not run.truck_mods.is_empty()


## 事件留下的局内状态：诅咒红、祝福绿；悬停看数值说明
func _refresh_flags() -> void:
	var key: String = Loc.lang
	var ids: Array = run.flags.keys()
	ids.sort()
	for id0: Variant in ids:
		key += "|%s=%s" % [str(id0), str(run.flags[id0])]
	if key == _flags_shown:
		return
	_flags_shown = key
	for c: Node in flags_row.get_children():
		flags_row.remove_child(c)
		c.queue_free()
	for id: Variant in ids:
		var v: int = int(round(run.flag_value(str(id))))
		var good: bool = Events.is_gain({"type": "flag", "id": str(id), "value": v})
		var tg: PanelContainer = UIKit.tag(Loc.t("ui.flag.%s.name" % str(id)), UIKit.GOOD if good else UIKit.BAD, false, 10)
		tg.mouse_filter = Control.MOUSE_FILTER_STOP
		tg.tooltip_text = "%s\n%s" % [Loc.t("ui.flag.%s.name" % str(id)), Loc.t("ui.flag.%s.desc" % str(id), [absi(v)])]
		flags_row.add_child(tg)
	flags_row.visible = not ids.is_empty()


## 去掉 BBCode 标记(提示框用纯文本)
static func plain_text(s: String) -> String:
	var re := RegEx.new()
	re.compile("\\[/?[a-zA-Z_]+[^\\]]*\\]")
	return re.sub(s, "", true)


## 事件战斗的专属战场：备战时在画面左边写出这场的战场机制(名字 + 规则)，战斗中换成上方正中的一个倒计时
func _refresh_arena() -> void:
	var aid := ""
	if (mode == "prepare" and run.phase == "prepare") or mode == "battle":
		aid = str(run.current_layout().get("arena", ""))
	var key: String = "%s|%s|%s" % [aid, mode, Loc.lang]
	if key == _arena_shown:
		return
	_arena_shown = key
	if arena_box != null and is_instance_valid(arena_box):
		arena_box.queue_free()
	arena_box = null
	_hazard_label = null
	_hazard_num = null
	if aid == "":
		return
	arena_box = UIKit.ark_panel(8, "left", 10, Color(UIKit.BG_DEEP.r, UIKit.BG_DEEP.g, UIKit.BG_DEEP.b, 0.92), UIKit.BAD)
	add_child(arena_box)
	if mode == "prepare":
		var v := UIKit.vbox(6)
		var h := UIKit.hbox(8)
		h.add_child(UIKit.tag(Loc.t("ui.arena.rule"), UIKit.BAD, true))
		h.add_child(UIKit.label(Loc.t("arena.%s.name" % aid), 15, UIKit.TEXT, true))
		var cap: Label = UIKit.caption(Loc.t_in("en", "arena.%s.name" % aid).to_upper(), 10, UIKit.BAD)
		cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(cap)
		v.add_child(h)
		v.add_child(UIKit.rich("[color=%s]%s[/color]" % [UIKit.hx(UIKit.TEXT_SOFT), Loc.t("arena.%s.rule" % aid)], 14, 372.0))
		arena_box.add_child(v)
		# 备战：规则写在画面左边(战场西侧的空地上)，不挡北边的敌人
		arena_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
		arena_box.position = Vector2(16, 306)
	else:
		var h2 := UIKit.hbox(10)
		h2.add_child(UIKit.glyph("n_event", UIKit.BAD, 18.0))
		_hazard_label = UIKit.label("", 14, UIKit.TEXT, true)
		h2.add_child(_hazard_label)
		_hazard_num = UIKit.num("", 22, UIKit.GOLD)
		_hazard_num.custom_minimum_size = Vector2(30, 0)
		h2.add_child(_hazard_num)
		arena_box.add_child(h2)
		arena_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
		arena_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
		arena_box.position.y = 116


## 战斗中每帧：战场机制离下一次发动还有几秒(Battle.hazard_info)；快到了 / 正在发动 = 红字
func update_hazards(info: Array) -> void:
	if _hazard_num == null or not is_instance_valid(_hazard_num) or info.is_empty():
		return
	var hz: Dictionary = info[0]
	var running: bool = str(hz["phase"]) == "run"
	var soon: bool = running or str(hz["phase"]) == "warn"
	_hazard_label.text = Loc.t("hazard.%s.%s" % [str(hz["id"]), "now" if running else "label"])
	_hazard_num.text = "" if running else "%d" % int(ceil(float(hz["eta"])))
	_hazard_num.add_theme_color_override("font_color", UIKit.BAD if soon else UIKit.GOLD)
	_hazard_label.add_theme_color_override("font_color", UIKit.BAD if soon else UIKit.TEXT)


func _refresh_traits() -> void:
	for ch: Node in trait_box.get_children():
		ch.queue_free()
	var defs: Array = []
	if mode == "battle" and battle_defs.size() > 0:
		defs = battle_defs
	else:
		defs = run.trait_defs()
	trait_reports = TraitRuntime.compute(cat, defs)
	var shown := 0
	for entry: Dictionary in trait_reports:
		var t: TraitDef = entry["trait"]
		var tier: int = int(entry["tier"])
		var fc: Color = GC.faction_color(t.member_filter)
		var chip := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(fc.r * 0.3, fc.g * 0.3, fc.b * 0.3, 0.92) if tier > 0 else Color(UIKit.BG.r, UIKit.BG.g, UIKit.BG.b, 0.8)
		sb.border_color = fc if tier > 0 else UIKit.BORDER
		sb.set_border_width_all(1)
		sb.border_width_left = 4
		sb.skew = Vector2(0.18, 0)
		sb.content_margin_left = 10
		sb.content_margin_right = 12
		sb.content_margin_top = 3
		sb.content_margin_bottom = 3
		chip.add_theme_stylebox_override("panel", sb)
		var h := UIKit.hbox(6)
		h.add_child(UIKit.faction_dot(t.member_filter, 16.0))
		# 激活的芯片底色总是深的阵营色 → 字用固定的浅色
		h.add_child(UIKit.label(Loc.t("trait.%s.name" % t.id), 14, Color("#f2f3f5") if tier > 0 else UIKit.TEXT_DIM, true))
		var nxt: int = int(entry["next"])
		var cnt: String = "%d/%d" % [int(entry["count"]), nxt] if nxt > 0 else "%d" % int(entry["count"])
		h.add_child(UIKit.num(cnt, 17, UIKit.GOLD if tier > 0 else UIKit.TEXT_DIM))
		chip.add_child(h)
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		chip.mouse_entered.connect(func() -> void:
			show_tip(TipContent.trait_tip(cat, entry), chip)
			trait_hovered.emit(t.id))
		chip.mouse_exited.connect(func() -> void:
			hide_tip()
			marks_cleared.emit())
		trait_box.add_child(chip)
		shown += 1
	if shown == 0:
		trait_box.add_child(UIKit.outlined(UIKit.label(Loc.t("ui.no_traits"), 13, UIKit.TEXT_SOFT), 4))


func _refresh_dock() -> void:
	# ---- 武器库
	for ch: Node in inv_grid.get_children():
		ch.queue_free()
	for i in range(run.inventory.size()):
		inv_grid.add_child(_make_item_tile(run.inventory[i]))
	if run.inventory.is_empty():
		inv_grid.add_child(UIKit.label(Loc.t("ui.inventory_empty"), 12, UIKit.TEXT_MUTE))
	# ---- 招募
	for ch2: Node in shop_row.get_children():
		ch2.queue_free()
	for i2 in range(run.shop.size()):
		shop_row.add_child(_make_shop_card(i2))
	_refresh_odds()
	var cost: int = int(run.shop_rule.get("refresh_cost", 2))
	reroll_btn.text = Loc.t("ui.reroll", [cost])
	reroll_btn.disabled = run.gold < cost
	lock_btn.text = Loc.t("ui.locked") if run.shop_locked else Loc.t("ui.lock")
	lock_btn.add_theme_color_override("font_color", UIKit.ACCENT if run.shop_locked else UIKit.TEXT)
	var xp_cost: int = int(run.shop_rule.get("buy_xp_cost", 4))
	xp_btn.text = Loc.t("ui.buy_xp", [xp_cost, int(run.shop_rule.get("xp_per_purchase", 4))])
	xp_btn.disabled = run.gold < xp_cost or run.level >= run.max_level()
	interest_label.text = Loc.t("ui.income_hint", [int(run.current_node().get("income", 0)), run.interest()])
	start_btn.disabled = run.board_units().is_empty() and mode == "prepare"
	truck_btn.visible = mode == "prepare" and run.truck_can_move()
	truck_btn.text = Loc.t("ui.truck_rotate")
	truck_btn.tooltip_text = Loc.t("ui.truck_rotate_tip")


func _make_item_tile(id: String) -> Control:
	var t := ItemTile.new()
	t.setup(cat, id)
	t.mouse_filter = Control.MOUSE_FILTER_PASS
	t.hover_in.connect(func() -> void:
		if get_viewport().gui_is_dragging():
			return              # 正拖着东西经过武器库：不弹详情(会挡住落点)
		show_tip(with_hint(TipContent.equipment_tip(cat, id), "ui.tip.click_pin"), t)
		item_hovered.emit(id))
	t.hover_out.connect(func() -> void:
		hide_tip()
		marks_cleared.emit())
	t.clicked.connect(func() -> void: toggle_pin(TipContent.equipment_tip(cat, id), t))
	return t


func _make_shop_card(index: int) -> Control:
	var offer: Dictionary = run.shop[index]
	var card_ctl := ShopCard.new()
	card_ctl.setup(cat, index, str(offer["def"]), bool(offer["sold"]), portraits.get(str(offer["def"]), null), run.gold)
	card_ctl.mouse_filter = Control.MOUSE_FILTER_PASS      # 拖着节点经过卡片时，拖放穿透给指挥台(= 出售)
	card_ctl.clicked.connect(func(i: int) -> void: buy_requested.emit(i))
	card_ctl.hover_in.connect(func() -> void:
		var d: UnitDef = cat.get_unit(str(offer["def"]))
		show_tip(TipContent.unit_card(cat, d, 1, ""), card_ctl)
		shop_hovered.emit(d.id))
	card_ctl.hover_out.connect(func() -> void:
		hide_tip()
		marks_cleared.emit())
	return card_ctl


# =============================================================== 制造概率
## 当前等级各费用出现的概率(整数百分比，费用升序；0 的不列)
func _odds_row(level: int) -> Array:
	var odds: Dictionary = (run.shop_rule.get("odds_by_level", {}) as Dictionary).get(str(level), {"1": 100})
	var out: Array = []
	var costs: Array = odds.keys()
	costs.sort_custom(func(a: String, b: String) -> bool: return int(a) < int(b))
	for c: String in costs:
		if float(odds[c]) > 0.0:
			out.append([int(c), int(round(float(odds[c])))])
	return out


## 费用档的颜色(1 费灰、2 费绿、3 费主题色、4 费金，和卡片上的金币数字一致)
static func cost_color(cost: int) -> Color:
	match cost:
		1:
			return UIKit.TEXT_SOFT
		2:
			return UIKit.GOOD
		3:
			return UIKit.ACCENT
		_:
			return UIKit.GOLD


func _refresh_odds() -> void:
	for ch: Node in odds_strip.get_children():
		odds_strip.remove_child(ch)
		ch.queue_free()
	for e: Array in _odds_row(run.level):
		var cell := UIKit.hbox(2)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var col: Color = cost_color(int(e[0]))
		var g: Control = UIKit.glyph("coin", col, 11.0)
		g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cell.add_child(g)
		cell.add_child(UIKit.num(str(e[0]), 14, col))
		cell.add_child(UIKit.spacer(5))
		var pct: Label = UIKit.num("%d%%" % int(e[1]), 14, UIKit.TEXT)
		pct.name = "pct_%d" % int(e[0])
		cell.add_child(pct)
		odds_strip.add_child(cell)


## 悬停概率条：整张表(等级 × 费用)，当前等级高亮
func _odds_tip() -> Control:
	var box := UIKit.vbox(6)
	box.add_child(UIKit.section(Loc.t("ui.odds_title"), "Shop odds"))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 3)
	grid.add_child(UIKit.caption(Loc.t("ui.odds_level"), 10, UIKit.TEXT_DIM))
	for c in range(1, 5):
		var h := UIKit.hbox(2)
		h.add_child(UIKit.glyph("coin", cost_color(c), 11.0))
		h.add_child(UIKit.num(str(c), 14, cost_color(c)))
		grid.add_child(h)
	for lv in range(1, run.max_level() + 1):
		var now: bool = lv == run.level
		var lvh := UIKit.hbox(4)
		lvh.add_child(UIKit.num(str(lv), 14, UIKit.ACCENT if now else UIKit.TEXT_DIM))
		if now:
			lvh.add_child(UIKit.caption(Loc.t("ui.odds_now"), 9, UIKit.ACCENT))
		grid.add_child(lvh)
		var row: Dictionary = {}
		for e: Array in _odds_row(lv):
			row[int(e[0])] = int(e[1])
		for c2 in range(1, 5):
			var v: int = int(row.get(c2, 0))
			var l: Label = UIKit.num("%d%%" % v if v > 0 else "–", 14, (UIKit.TEXT if now else UIKit.TEXT_SOFT) if v > 0 else UIKit.TEXT_MUTE)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			l.custom_minimum_size = Vector2(40, 0)
			grid.add_child(l)
	box.add_child(grid)
	box.add_child(UIKit.label(Loc.t("ui.odds_hint"), 11, UIKit.TEXT_MUTE))
	return box


# =============================================================== 仓库
func _refresh_cargo() -> void:
	for ch: Node in cargo_row.get_children():
		cargo_row.remove_child(ch)
		ch.queue_free()
	var stored: Array[Dictionary] = run.bench_units()
	for u: Dictionary in stored:
		var sl := StorageCard.new()
		sl.setup(cat, int(u["bench"]), u, run.weapon_of(u))
		sl.dropped.connect(func(slot: int, data: Dictionary) -> void: cargo_dropped.emit(slot, data))
		sl.clicked.connect(func(rid: String) -> void: storage_clicked.emit(rid))
		cargo_row.add_child(sl)
	# 末尾：拖到这里收纳
	var drop := StorageCard.new()
	drop.setup(cat, run.free_bench_slot(), {}, null)
	drop.dropped.connect(func(slot: int, data: Dictionary) -> void: cargo_dropped.emit(slot, data))
	cargo_row.add_child(drop)
	cargo_title.text = Loc.t("ui.cargo")
	cargo_count.text = str(stored.size())


func cargo_rect() -> Rect2:
	return cargo.get_global_rect() if cargo.visible else Rect2()


## 屏幕坐标下的仓库卡下标；在仓库条里但不在某张卡上返回 -1；不在仓库条返回 -2
func cargo_slot_at(pos: Vector2) -> int:
	if not cargo.visible or not cargo.get_global_rect().has_point(pos):
		return -2
	for ch: Node in cargo_row.get_children():
		var sl: StorageCard = ch as StorageCard
		if sl != null and sl.roster_id != "" and sl.get_global_rect().has_point(pos):
			return sl.slot
	return -1


## 仓库里某个节点的卡片(屏幕矩形)，详情卡定位用
func storage_card_rect(roster_id: String) -> Rect2:
	for ch: Node in cargo_row.get_children():
		var sl: StorageCard = ch as StorageCard
		if sl != null and sl.roster_id == roster_id:
			return sl.get_global_rect()
	return Rect2()


func set_cargo_hint(active: bool) -> void:
	cargo.accent = UIKit.ACTION if active else UIKit.ACCENT
	cargo.modulate = Color(1.15, 1.15, 1.25) if active else Color.WHITE
	cargo.queue_redraw()


## QoL：给仓库里的节点标色(fn(roster 字典) -> Color；无效 Callable = 清除)
func mark_cargo(fn: Callable) -> void:
	for ch: Node in cargo_row.get_children():
		var sl: StorageCard = ch as StorageCard
		if sl == null:
			continue
		if not fn.is_valid() or sl.roster_id == "" or run == null or not run.roster.has(sl.roster_id):
			sl.set_mark(Color(0, 0, 0, 0))
		else:
			sl.set_mark(fn.call(run.roster[sl.roster_id]))


# =============================================================== 方格网大地图
## 行动力面板 + 零件栏(只在方格网章节出现)
func _refresh_ap() -> void:
	var grid: bool = run != null and run.is_grid()
	ap_panel.visible = grid
	parts_panel.visible = grid
	if not grid:
		return
	ap_num.text = str(run.ap)
	ap_num.add_theme_color_override("font_color", UIKit.ACTION if run.ap > 2 else UIKit.BAD)
	ap_max_label.text = "/%d" % run.ap_max
	for ch: Node in ap_pips.get_children():
		ch.queue_free()
	for i in range(maxi(run.ap_max, run.ap)):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(9, 14)
		pip.color = UIKit.ACTION if i < run.ap else Color(UIKit.TEXT_MUTE.r, UIKit.TEXT_MUTE.g, UIKit.TEXT_MUTE.b, 0.5)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ap_pips.add_child(pip)
	var reach: Dictionary = run.reachable()
	var boss: String = str(run.gmap.get("boss", ""))
	var info: String = Loc.t("ui.steps", [run.steps])
	if reach.has(boss):
		info += "  ·  " + Loc.t("ui.ap_boss_dist", [int(reach[boss])])
	ap_info.text = info
	for ch2: Node in parts_row.get_children():
		ch2.queue_free()
	if run.parts.is_empty():
		parts_row.add_child(UIKit.label(Loc.t("ui.parts_empty"), 13, UIKit.TEXT_MUTE))
	for i2 in range(run.parts.size()):
		parts_row.add_child(_part_chip(i2))


func _part_chip(i: int) -> Control:
	var pid: String = run.parts[i]
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(132, 46)
	var on: bool = part_mode == i
	var sb: StyleBoxFlat = UIKit.style(UIKit.BG if not on else UIKit.BG_SOFT, 0, UIKit.ACTION if on else UIKit.BORDER, 2 if on else 1, 6)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", UIKit.style(UIKit.BG_SOFT, 0, UIKit.ACCENT, 1, 6))
	b.add_theme_stylebox_override("pressed", sb)
	var row := UIKit.hbox(6)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(UIKit.glyph("p_" + pid, UIKit.ACTION, 26.0))
	var nm := UIKit.label(Loc.t("part.%s.name" % pid), 13, UIKit.TEXT, true)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(nm)
	b.add_child(row)
	b.pressed.connect(func() -> void: part_clicked.emit(i))
	b.mouse_entered.connect(func() -> void: show_tip(_part_tip(pid), b))
	b.mouse_exited.connect(func() -> void:
		if _tip_owner == b:
			hide_tip())
	return b


func _part_tip(pid: String) -> Control:
	var v := UIKit.vbox(6)
	v.custom_minimum_size = Vector2(280, 0)
	var head := UIKit.hbox(8)
	head.add_child(UIKit.glyph("p_" + pid, UIKit.ACTION, 30.0))
	head.add_child(UIKit.label(Loc.t("part.%s.name" % pid), 17, UIKit.TEXT, true))
	v.add_child(head)
	v.add_child(UIKit.rich("[color=%s]%s[/color]" % [UIKit.hx(UIKit.TEXT_SOFT), Loc.t("part.%s.desc" % pid)], 13, 280))
	return v


func _refresh_grid_buttons() -> void:
	for b0: MapNodeButton in map_buttons:
		b0.queue_free()
	map_buttons.clear()
	var nodes: Dictionary = run.gmap.get("nodes", {})
	var reach: Dictionary = run.reachable() if run.phase == "map" else {}
	var targets: Array[String] = []
	if part_mode >= 0:
		targets = run.part_targets(part_mode)
	for k: String in nodes.keys():
		if not grid_buttons.has(k):
			var b := GridNodeButton.new()
			map_layer.add_child(b)
			map_layer.move_child(b, 0)
			b.hover_changed.connect(_on_grid_hover)
			b.clicked.connect(func(kk: String) -> void:
				hide_tip()
				grid_clicked.emit(kk))
			grid_buttons[k] = b
		var nd: Dictionary = nodes[k]
		var st: String = str(nd["state"])
		var t: String = str(nd["type"]) if st != "hidden" else "unknown"
		var col: Color = CityOverworld.TYPE_COLORS.get(t, Color.WHITE)
		var cost: int = int(reach.get(k, -1)) if k != run.pos else 0
		var lbl: String = Loc.t("ui.node_type_short." + t) if t != "unknown" else ""
		if st == "done" and t != "shop_black" and t != "shop_parts" and t != "start":
			lbl = ""
		var gb: GridNodeButton = grid_buttons[k]
		gb.targeted = targets.has(k)
		gb.setup(k, t, st, col, lbl, cost, cost >= 0 and cost <= run.ap, k == run.pos, t == "boss")


func place_grid_button(k: String, p: Vector2) -> void:
	if grid_buttons.has(k):
		var b: GridNodeButton = grid_buttons[k]
		b.position = p - b.size * 0.5


func _on_grid_hover(k: String, on: bool) -> void:
	grid_hovered.emit(k, on)
	if on:
		show_tip(_grid_node_tip(k), grid_buttons[k])
	elif _tip_owner == grid_buttons.get(k, null):
		hide_tip()


## 战斗强度一行：数字 + 普通 / 强怪(精英、首领只显示数字)。强怪 = 后半程的普通作战在浮动之上再加了几级强度
func _intensity_row(k: String, t: String) -> Control:
	var inten: int = run.node_intensity(k)
	var row := UIKit.hbox(8)
	row.add_child(UIKit.label(Loc.t("ui.intensity"), 13, UIKit.TEXT_DIM))
	var strong: bool = run.node_strong(k)
	var col: Color = UIKit.GOOD if (t == "fight" and not strong) else (UIKit.GOLD if t == "fight" else UIKit.BAD)
	row.add_child(UIKit.num(str(inten), 20, col))
	if t == "fight":
		row.add_child(UIKit.tag(Loc.t("ui.danger_strong") if strong else Loc.t("ui.danger_weak"), col, false, 11))
	return row


## 方格网节点的信息卡：类型 / 状态 / 说明 / 去那里要花的行动力 / 战斗强度(普通还是强怪)
func _grid_node_tip(k: String) -> Control:
	var nd: Dictionary = run.gnode(k)
	var st: String = str(nd.get("state", "hidden"))
	var t: String = str(nd.get("type", "fight"))
	var v := UIKit.vbox(7)
	v.custom_minimum_size = Vector2(300, 0)
	var head := UIKit.hbox(10)
	var shown: String = t if st != "hidden" else "unknown"
	head.add_child(UIKit.glyph("n_" + shown, CityOverworld.TYPE_COLORS.get(shown, Color.WHITE), 34.0))
	var hv := UIKit.vbox(2)
	if st == "hidden":
		hv.add_child(UIKit.label(Loc.t("ui.map_unknown"), 18, UIKit.TEXT, true))
	elif st == "done" and t != "shop_black" and t != "shop_parts":
		hv.add_child(UIKit.label(Loc.t("ui.map_cleared"), 18, UIKit.TEXT, true))
	else:
		hv.add_child(UIKit.label(Loc.t("ui.node_type." + t), 18, UIKit.TEXT, true))
	hv.add_child(UIKit.caption(Loc.t_in("en", "ui.node_type." + shown) if st != "hidden" else "Unobserved", 10, UIKit.ACCENT))
	head.add_child(hv)
	v.add_child(head)
	var desc: String
	if st == "hidden":
		desc = Loc.t("ui.map_unknown.desc")
	elif st == "done" and t != "shop_black" and t != "shop_parts":
		desc = Loc.t("ui.map_cleared.desc")
	else:
		desc = Loc.t("ui.node_type.%s.desc" % t)
	v.add_child(UIKit.rich("[color=%s]%s[/color]" % [UIKit.hx(UIKit.TEXT_SOFT), desc], 13, 300))
	var reach: Dictionary = run.reachable()
	if k == run.pos:
		v.add_child(UIKit.tag(Loc.t("ui.ap_here"), UIKit.ACCENT, true, 12))
		if t == "boss" and st != "done":
			v.add_child(UIKit.tag(Loc.t("ui.map_retry"), UIKit.ACTION, true, 13))
		elif t == "shop_black" or t == "shop_parts":
			v.add_child(UIKit.tag(Loc.t("ui.map_reenter"), UIKit.ACTION, true, 13))
	elif reach.has(k):
		var cost: int = int(reach[k])
		var row := UIKit.hbox(8)
		row.add_child(UIKit.glyph("fuel", UIKit.ACTION, 18.0))
		row.add_child(UIKit.label(Loc.t("ui.ap_cost", [cost]), 14, UIKit.ACTION if cost <= run.ap else UIKit.BAD, true))
		v.add_child(row)
		if st != "hidden" and st != "done" and (t == "fight" or t == "elite" or t == "boss"):
			v.add_child(_intensity_row(k, t))
		if cost > run.ap:
			v.add_child(UIKit.tag(Loc.t("ui.ap_short", [cost]), UIKit.BAD, true, 12))
		elif cost == run.ap and t != "boss":
			v.add_child(UIKit.label(Loc.t("ui.hunt_hint"), 12, UIKit.BAD))
		else:
			v.add_child(UIKit.tag(Loc.t("ui.map_go"), UIKit.ACTION, true, 13))
	else:
		v.add_child(UIKit.label(Loc.t("ui.err.unreachable"), 12, UIKit.TEXT_DIM))
	return v


# =============================================================== 大地图关卡牌
func _refresh_map_buttons() -> void:
	if run == null:
		return
	if run.is_grid():
		_refresh_grid_buttons()
		return
	for gk: String in grid_buttons.keys():
		(grid_buttons[gk] as Node).queue_free()
	grid_buttons.clear()
	var nodes: Array = run.map_nodes()
	while map_buttons.size() < nodes.size():
		var b := MapNodeButton.new()
		map_layer.add_child(b)
		b.hover_changed.connect(_on_map_hover)
		b.clicked.connect(func(_i: int) -> void:
			hide_tip()
			go_requested.emit())
		map_buttons.append(b)
	while map_buttons.size() > nodes.size():
		map_buttons.pop_back().queue_free()
	var ch_n: String = run.chapter_id.trim_prefix("ch")
	for i in range(nodes.size()):
		var st: String = "done" if i < run.node_index else ("next" if i == run.node_index else "later")
		var final: bool = i == nodes.size() - 1
		var ntype: String = str((nodes[i] as Dictionary).get("type", "reward"))
		var tier: String = _best_orb(nodes[i] as Dictionary)
		map_buttons[i].setup(i, st, "crystal" if final else "gem", Color("#f4f6ff") if final else OrbView.COLORS.get(tier, Color.WHITE),
			"%s-%d" % [ch_n, i + 1], Loc.t("ui.node_type_short." + ntype), "Final" if final else ntype)


## 由 GameRoot 调用：把第 i 个关卡牌放到屏幕坐标 p(牌子中心)
func place_map_button(i: int, p: Vector2) -> void:
	if i < map_buttons.size():
		var b: MapNodeButton = map_buttons[i]
		b.position = p - b.size * 0.5


func _on_map_hover(i: int, on: bool) -> void:
	map_hovered.emit(i, on)
	if on:
		show_tip(_map_node_tip(i), map_buttons[i])
	elif _tip_owner == map_buttons[i]:
		hide_tip()


static func _best_orb(nd: Dictionary) -> String:
	var best := "white"
	for e: Variant in (nd.get("encounter", {}) as Dictionary).get("units", []):
		var opt: Dictionary = (e as Array)[4] if (e as Array).size() > 4 else {}
		var t: String = str(opt.get("orb", ""))
		if t == "gold" or (t == "blue" and best == "white"):
			best = t
	return best


## 关卡信息卡：编号/类型/状态、遭遇(头像 × 数量)、晶球掉落、到达收入、终点提示
func _map_node_tip(i: int) -> Control:
	var nodes: Array = run.map_nodes()
	var nd: Dictionary = nodes[i]
	var ntype: String = str(nd.get("type", "reward"))
	var v := UIKit.vbox(7)
	v.custom_minimum_size = Vector2(320, 0)
	var head := UIKit.hbox(10)
	head.add_child(UIKit.code_badge("%s-%d" % [run.chapter_id.trim_prefix("ch"), i + 1], 24, Vector2(64, 46)))
	var hv := UIKit.vbox(2)
	hv.add_child(UIKit.label(Loc.t("ui.node_type." + ntype), 18, UIKit.TEXT, true))
	var done: bool = i < run.node_index
	var here: bool = i == run.node_index
	var st: String = Loc.t("ui.map_done") if done else (Loc.t("ui.map_here") if here else Loc.t("ui.map_later"))
	hv.add_child(UIKit.tag(st, UIKit.ACCENT if here else UIKit.TEXT_DIM, here))
	head.add_child(hv)
	v.add_child(head)
	v.add_child(UIKit.rich("[color=#b8c0d0]%s[/color]" % Loc.t("ui.node_type.%s.desc" % ntype), 13, 320))
	# 遭遇：按单位合并，头像 × 数量(首领标出来)
	var counts: Dictionary = {}
	var order: Array[String] = []
	var orbs: Dictionary = {}
	for e: Variant in (nd.get("encounter", {}) as Dictionary).get("units", []):
		var ea: Array = e
		var key: String = str(ea[0])
		var opt: Dictionary = ea[4] if ea.size() > 4 else {}
		if bool(opt.get("boss", false)):
			key += "|boss"
		if not counts.has(key):
			order.append(key)
		counts[key] = int(counts.get(key, 0)) + 1
		if opt.has("orb"):
			orbs[str(opt["orb"])] = int(orbs.get(str(opt["orb"]), 0)) + 1
	v.add_child(UIKit.section(Loc.t("ui.map_enemies"), "Hostiles", UIKit.ENEMY))
	for key2: String in order:
		var parts: PackedStringArray = key2.split("|")
		var row := UIKit.hbox(8)
		row.add_child(UIKit.portrait(parts[0], Vector2(46, 34), cat.get_unit(parts[0]).faction_id if cat.get_unit(parts[0]) != null else ""))
		row.add_child(UIKit.label(Loc.t("unit.%s.name" % parts[0]), 14, UIKit.TEXT))
		if parts.size() > 1:
			row.add_child(UIKit.tag(Loc.t("ui.map_boss"), UIKit.ENEMY, true, 11))
		row.add_child(UIKit.spacer(0, 0, true))
		row.add_child(UIKit.num("×%d" % int(counts[key2]), 18, UIKit.TEXT_SOFT))
		v.add_child(row)
	if not orbs.is_empty():
		v.add_child(UIKit.section(Loc.t("ui.map_orbs"), "Drops", UIKit.GOLD))
		var orow := UIKit.hbox(14)
		for tier: String in ["gold", "blue", "white"]:
			if orbs.has(tier):
				var oh := UIKit.hbox(4)
				oh.add_child(UIKit.glyph("gem", OrbView.COLORS[tier], 18.0))
				oh.add_child(UIKit.num("×%d" % int(orbs[tier]), 18, UIKit.TEXT))
				orow.add_child(oh)
		v.add_child(orow)
	var inc: int = int(nd.get("income", 0))
	if inc > 0 and not done:
		v.add_child(UIKit.label(Loc.t("ui.map_income", [inc]), 13, UIKit.GOLD))
	if i == nodes.size() - 1:
		v.add_child(UIKit.label(Loc.t("ui.map_final"), 13, Color("#c8b4ff"), true))
	if here:
		v.add_child(UIKit.tag(Loc.t("ui.map_click"), UIKit.ACTION, true, 13))
	return v


# =============================================================== 拾取
## 一个晶球开出的东西：弹出一条条"获得"提示(带图标)
func show_loot(loot: Dictionary) -> void:
	if loot.is_empty():
		return
	var tier: String = str(loot.get("tier", "white"))
	var col: Color = OrbView.COLORS.get(tier, Color.WHITE)
	var rows: Array = []
	if int(loot.get("gold", 0)) > 0:
		rows.append(_loot_row(UIKit.glyph("coin", Color.WHITE, 26.0), Loc.t("ui.loot_gold", [int(loot["gold"])]), "Gold", UIKit.GOLD))
	for uid: Variant in loot.get("units", []):
		var d: UnitDef = cat.get_unit(str(uid))
		rows.append(_loot_row(UIKit.portrait(str(uid), Vector2(46, 34), d.faction_id if d != null else ""),
			Loc.t("ui.loot_unit", [Loc.t("unit.%s.name" % str(uid))]), "Node", UIKit.TEXT))
	for wid: Variant in loot.get("weapons", []):
		rows.append(_loot_row(UIKit.equipment_icon(cat.get_equipment(str(wid)), 38.0),
			Loc.t("ui.loot_weapon", [Loc.t("equipment.%s.name" % str(wid))]), "Weapon", UIKit.TEXT))
	var mg: Dictionary = loot.get("materials", {})
	if Crafting.total(mg) > 0:
		var icons := UIKit.hbox(0)
		var parts: Array[String] = []
		for m: String in Crafting.MATS:
			for i in range(int(mg.get(m, 0))):
				icons.add_child(UIKit.material_icon(m, 26.0))
			if int(mg.get(m, 0)) > 0:
				parts.append("%s ×%d" % [Loc.t("material.%s.name" % m), int(mg[m])])
		rows.append(_loot_row(icons, Loc.t("ui.loot_material", [" · ".join(parts)]), "Material", UIKit.TEXT))
	for r: Control in rows:
		var pc: ArkPanel = UIKit.ark_panel(8, "left", 0, UIKit.BG_DEEP, col)
		pc.add_child(r)
		loot_list.add_child(pc)
		pc.modulate.a = 0.0
		var tw: Tween = create_tween()
		tw.tween_property(pc, "modulate:a", 1.0, 0.18)
		tw.tween_interval(3.2)
		tw.tween_property(pc, "modulate:a", 0.0, 0.5)
		tw.tween_callback(pc.queue_free)
	while loot_list.get_child_count() > 7:
		var old: Node = loot_list.get_child(0)
		loot_list.remove_child(old)
		old.queue_free()


func _loot_row(icon: Control, text: String, en: String, color: Color) -> Control:
	var h := UIKit.hbox(10)
	h.add_child(icon)
	var v := UIKit.vbox(0)
	v.add_child(UIKit.caption(en + " get", 9, UIKit.ACCENT))
	v.add_child(UIKit.label(text, 16, color, true))
	h.add_child(v)
	return h


func clear_loot() -> void:
	for ch: Node in loot_list.get_children():
		ch.queue_free()


## 卡车被冲撞：耐久条闪红
func flash_truck(_dmg: int) -> void:
	var tw: Tween = create_tween()
	truck_bar.modulate = Color(1.6, 0.5, 0.5)
	tw.tween_property(truck_bar, "modulate", Color.WHITE, 0.5)


# =============================================================== 提示 / 卡片 / 吐司 / 横幅
## 悬停提示(固定住的提示不会被悬停替换)
func show_tip(content: Control, owner: Object = null) -> void:
	if tip_pinned:
		content.queue_free()
		return
	_fill_tip(content, owner)
	_place_tip()


## 悬停移开时收起(固定住的不收)；force = 连固定的一起关(换模式、开局等)
func hide_tip(force: bool = false) -> void:
	if tip_pinned and not force:
		return
	tip_pinned = false
	tip.visible = false
	_tip_owner = null
	hide_kw_tip()


## 固定提示：停在当前位置，鼠标可以移进去指蓝色关键词；底部一行灰字说明怎么关
func pin_tip(content: Control, owner: Object = null) -> void:
	tip_pinned = false
	_fill_tip(with_hint(content, "ui.tip.pinned"), owner)
	_place_tip()
	tip_pinned = true
	_set_links_active(tip, true)


## 同一个东西再点一次 = 取消固定
func toggle_pin(content: Control, owner: Object) -> void:
	if tip_pinned and _tip_owner == owner:
		content.queue_free()
		hide_tip(true)
		return
	pin_tip(content, owner)


func _fill_tip(content: Control, owner: Object) -> void:
	for ch: Node in tip.get_children():
		ch.queue_free()
	tip.add_child(content)
	tip.visible = true
	tip.reset_size()
	_tip_owner = owner
	# 跟着鼠标走的提示里的关键词指不到，也不能挡鼠标(否则会抢走悬停)
	_set_links_active(tip, false)


func _set_links_active(root: Node, on: bool) -> void:
	for n: Node in root.find_children("*", "RichTextLabel", true, false):
		if n.has_meta("kw_links"):
			(n as Control).mouse_filter = Control.MOUSE_FILTER_PASS if on else Control.MOUSE_FILTER_IGNORE


## 在提示内容下面加一行灰色小字说明
func with_hint(content: Control, key: String) -> Control:
	var box := UIKit.vbox(6)
	box.add_child(content)
	box.add_child(UIKit.label(Loc.t(key), 11, UIKit.TEXT_MUTE))
	return box


func _on_kw_hover(k: String, on: bool) -> void:
	if on:
		show_kw_tip(k)
	else:
		hide_kw_tip()


func _exit_tree() -> void:
	if UIKit.kw_handler.is_valid() and UIKit.kw_handler.get_object() == self:
		UIKit.kw_handler = Callable()


func show_kw_tip(k: String) -> void:
	for ch: Node in kw_tip.get_children():
		ch.queue_free()
	kw_tip.add_child(TipContent.keyword_tip(k))
	kw_tip.visible = true
	kw_tip.reset_size()
	var vp: Vector2 = get_viewport_rect().size
	var m: Vector2 = get_viewport().get_mouse_position()
	var pos: Vector2 = m + Vector2(16, 20)
	if pos.x + kw_tip.size.x > vp.x - 8:
		pos.x = m.x - kw_tip.size.x - 16
	if pos.y + kw_tip.size.y > vp.y - 8:
		pos.y = m.y - kw_tip.size.y - 12
	kw_tip.position = Vector2(maxf(8, pos.x), maxf(8, pos.y))


func hide_kw_tip() -> void:
	if kw_tip != null:
		kw_tip.visible = false


func _input(ev: InputEvent) -> void:
	# 固定的提示：点它以外的任何地方就关掉(不吃掉这次点击；点另一件装备会接着固定那件的)
	var mb := ev as InputEventMouseButton
	if tip_pinned and mb != null and mb.pressed and not tip.get_global_rect().has_point(mb.position):
		var own := _tip_owner as Control
		if own == null or not is_instance_valid(own) or not own.get_global_rect().has_point(mb.position):
			hide_tip(true)


func _place_tip() -> void:
	if not tip.visible or tip_pinned:
		return
	var vp: Vector2 = get_viewport_rect().size
	var pos: Vector2 = get_viewport().get_mouse_position() + Vector2(18, 18)
	var sz: Vector2 = tip.size
	if pos.x + sz.x > vp.x - 8:
		pos.x = get_viewport().get_mouse_position().x - sz.x - 18
	if pos.y + sz.y > vp.y - 8:
		pos.y = vp.y - sz.y - 8
	tip.position = Vector2(maxf(8, pos.x), maxf(8, pos.y))


func show_card(content: Control, anchor_screen: Vector2) -> void:
	for ch: Node in card.get_children():
		ch.queue_free()
	card.add_child(content)
	card.visible = true
	card.reset_size()
	var vp: Vector2 = get_viewport_rect().size
	var sz: Vector2 = card.size
	var pos := Vector2(anchor_screen.x + 60.0, anchor_screen.y - sz.y * 0.5)
	if pos.x + sz.x > vp.x - 10:
		pos.x = anchor_screen.x - sz.x - 60.0
	pos.y = clampf(pos.y, 90.0, vp.y - sz.y - (230.0 if mode == "prepare" else 16.0))
	pos.x = clampf(pos.x, 10.0, vp.x - sz.x - 10.0)
	card.position = pos


func hide_card() -> void:
	if card != null:
		card.visible = false


func card_rect() -> Rect2:
	return Rect2(card.position, card.size) if card.visible else Rect2()


func toast_msg(text: String, good: bool = false) -> void:
	toast_label.text = text
	toast.accent = UIKit.GOOD if good else UIKit.BAD
	toast.queue_redraw()
	toast.visible = true
	toast.modulate.a = 1.0
	toast.reset_size()
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8 if not good else 3.2)
	_toast_tween.tween_property(toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func() -> void: toast.visible = false)


## 大招切入(充能 9 的"少女幻 x")：屏幕上方三分之一处，一条斜切的深色条带从一侧冲进来——左边是她的立绘(阵营色边)，
## 右边是技能名(大字) + 英文名与"ULTIMATE"标注，上下各一道技能颜色的条；一道白光扫过，停一会儿再往另一侧滑出去。
## enemy = 敌方的大招：从右侧进来(颜色照旧)
func show_cutin(def_id: String, title: String, en: String, color: Color, enemy: bool = false) -> void:
	var W := 640.0
	var H := 132.0
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_TOP_LEFT if not enemy else Control.PRESET_TOP_RIGHT)
	root.size = Vector2(W, H)
	add_child(root)
	move_child(root, banner.get_index())
	var vp: Vector2 = get_viewport_rect().size
	var y0: float = vp.y * 0.26
	var x_in: float = 0.0 if not enemy else vp.x - W
	var x_from: float = -W - 40.0 if not enemy else vp.x + 40.0
	var x_out: float = 60.0 if not enemy else vp.x - W - 60.0
	root.position = Vector2(x_from, y0)
	var sl := 34.0                                  # 斜切的宽度
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W - sl, H), Vector2(0, H)]) if not enemy else 		PackedVector2Array([Vector2(sl, 0), Vector2(W, 0), Vector2(W, H), Vector2(0, H)])
	bg.color = Color(UIKit.BG_DEEP.r, UIKit.BG_DEEP.g, UIKit.BG_DEEP.b, 0.9)
	root.add_child(bg)
	for top: bool in [true, false]:
		var ln := Polygon2D.new()
		var yy: float = 0.0 if top else H - 4.0
		var dx0: float = (sl * yy / H) if not enemy else (sl * (1.0 - yy / H))
		var dx1: float = (sl * (yy + 4.0) / H) if not enemy else (sl * (1.0 - (yy + 4.0) / H))
		ln.polygon = PackedVector2Array([Vector2(0, yy), Vector2(W - dx0, yy), Vector2(W - dx1, yy + 4.0), Vector2(0, yy + 4.0)]) if not enemy else 			PackedVector2Array([Vector2(dx0, yy), Vector2(W, yy), Vector2(W, yy + 4.0), Vector2(dx1, yy + 4.0)])
		ln.color = color
		root.add_child(ln)
	# 立绘
	var pw := H - 16.0
	var pf := PanelContainer.new()
	var sb := UIKit.style(UIKit.BG, 0, color, 2, 0)
	pf.add_theme_stylebox_override("panel", sb)
	pf.clip_contents = true
	pf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pf.position = Vector2(18.0 if not enemy else W - pw - 18.0, 8.0)
	pf.size = Vector2(pw, pw)
	if UIKit.portraits.has(def_id):
		var tr := TextureRect.new()
		tr.texture = UIKit.portraits[def_id]
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.custom_minimum_size = Vector2(pw, pw)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pf.add_child(tr)
	root.add_child(pf)
	# 技能名 + 英文
	var tv := UIKit.vbox(0)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.position = Vector2(pw + 40.0 if not enemy else 50.0, 16.0)
	tv.size = Vector2(W - pw - 90.0, H - 32.0)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	var cap := UIKit.caption("ULTIMATE · CHARGE 9", 13, color)
	tv.add_child(cap)
	var nm := UIKit.label(title, 44, UIKit.TEXT, true)
	tv.add_child(nm)
	var enl := UIKit.caption(en.to_upper(), 13, UIKit.TEXT_DIM)
	tv.add_child(enl)
	root.add_child(tv)
	# 扫过的白光
	var shine := Polygon2D.new()
	shine.polygon = PackedVector2Array([Vector2(0, 0), Vector2(26, 0), Vector2(26 - sl, H), Vector2(-sl, H)])
	shine.color = Color(1, 1, 1, 0.55)
	shine.position = Vector2(-60, 0)
	root.add_child(shine)
	var tw := root.create_tween()
	tw.tween_property(root, "position:x", x_in, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(shine, "position:x", W + 60.0, 0.45).set_delay(0.12)
	tw.tween_interval(1.05)
	tw.tween_property(root, "position:x", x_out, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(root, "modulate:a", 0.0, 0.3)
	tw.tween_callback(root.queue_free)


## 横幅：横贯屏幕的深色条带展开 → 停留 → 淡出。en = 英文标注(可省略，按常用文本自动匹配)
func show_banner(text: String, color: Color = Color(-1, 0, 0), en: String = "") -> void:
	banner_label.text = text
	banner_label.add_theme_color_override("font_color", UIKit.TEXT if color.r < 0.0 else color)
	var cap: String = en
	if cap == "":
		for k: String in BANNER_EN.keys():
			if Loc.t(k) == text:
				cap = BANNER_EN[k]
	banner_caption.text = cap.to_upper()
	banner.visible = true
	banner.modulate.a = 1.0
	banner.pivot_offset = banner.size * 0.5
	banner.scale = Vector2(1.0, 0.05)
	if _banner_tw != null:
		_banner_tw.kill()
	_banner_tw = create_tween()
	_banner_tw.tween_property(banner, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_banner_tw.tween_interval(0.9)
	_banner_tw.tween_property(banner, "modulate:a", 0.0, 0.35)
	_banner_tw.tween_callback(func() -> void: banner.visible = false)


func set_sell_hint(active: bool, value: int = 0, text: String = "", danger: bool = true) -> void:
	sell_overlay.visible = active
	if active:
		sell_overlay.text = text if text != "" else Loc.t("ui.sell_for", [value])
	dock.add_theme_stylebox_override("panel", _dock_style(active and danger))
	for ch: Node in dock.get_children():
		if ch != sell_overlay:
			(ch as CanvasItem).modulate.a = 0.15 if active else 1.0


func dock_rect() -> Rect2:
	return dock.get_global_rect() if dock.visible else Rect2()


func over_ui(pos: Vector2) -> bool:
	for c: Control in [stage_box, econ_box, battle_box, dock, cargo, counts_box]:
		if c.visible and c.get_global_rect().has_point(pos):
			return true
	if card.visible and card.get_global_rect().has_point(pos):
		return true
	return false


# =============================================================== 信息流 / 战斗计数
func add_feed(bbcode: String) -> void:
	var row := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(UIKit.BG_DEEP.r, UIKit.BG_DEEP.g, UIKit.BG_DEEP.b, 0.72)
	sb.border_color = UIKit.ACCENT
	sb.border_width_left = 2
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	row.add_theme_stylebox_override("panel", sb)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.custom_minimum_size = Vector2(430, 0)
	l.add_theme_font_size_override("normal_font_size", 14)
	l.add_theme_font_size_override("bold_font_size", 14)
	l.add_theme_font_override("bold_font", UIKit.font_bold)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.text = UIKit.bb(bbcode)
	row.add_child(l)
	feed_box.add_child(row)
	while feed_box.get_child_count() > 6:
		var old_row: Node = feed_box.get_child(0)
		feed_box.remove_child(old_row)
		old_row.queue_free()
	var tw: Tween = create_tween()
	tw.tween_interval(6.0)
	tw.tween_property(row, "modulate:a", 0.0, 0.8)
	tw.tween_callback(row.queue_free)


func clear_feed() -> void:
	for ch: Node in feed_box.get_children():
		ch.queue_free()


func set_battle_counts(p_alive: int, p_total: int, e_alive: int, e_total: int, seconds: float) -> void:
	enemy_count.text = "%d/%d" % [e_alive, e_total]
	ally_count.text = "%d/%d" % [p_alive, p_total]
	timer_label.text = "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]


## 按钮右上角贴快捷键键帽；按钮本身不拦拖放(拖到这里 = 出售)
func _with_key(b: Button, key: String) -> Control:
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	UIKit.add_key_hint(b, key)
	return b


func _process(_dt: float) -> void:
	_place_tip()
	# 拖着仓库里的节点离开指挥台 / 松手：收起出售提示
	if _dnd_sell and (not get_viewport().gui_is_dragging() or not dock.get_global_rect().has_point(get_viewport().get_mouse_position())):
		_dnd_sell = false
		set_sell_hint(false)
