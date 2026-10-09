class_name GameRoot
extends Node
## 游戏根节点：把 Run(局内状态)、3D 世界、HUD、各界面、拖拽交互与流程串起来。
## 状态：boot → title → map ⇄ travel → prepare → battle → result → loot → (map | over)
##   map     章节地图：卡车停在上一站，点「出发」开往下一个地图节点
##   travel  卡车沿路行驶(镜头跟随)
##   prepare 在节点战场备战：节点摆在卡车四周的格子上，仓库(不限数量)在界面底部
##   battle  战斗；我方全灭后敌人涌入卡车扣耐久
##   result  战斗结算面板
##   loot    点击晶球领取战利品，然后「继续前进」
##   node    方格网章节的非战斗节点(修整 / 事件 / 黑市 / 零件铺)：大地图当背景，中间是节点界面
##   chapter_end  打通一章：选卡车改装(占位) → 选下一章的分支
##   over    通关(游戏结束) / 卡车损毁
## 方格网章节(第一章起)：大地图上点能去的节点 → 卡车沿路开过去(扣行动力) → 按节点类型进入战斗 / 节点界面；
## 行动力用完 → 追猎(就地开战)。

var cat: Catalog
var run: Run
var world: GameWorld
var hud: HUD
var screens: Screens
var wi: WorldInput
var portraits: Portraits
var ui_layer: CanvasLayer

var state: String = "boot"
var prep_views: Dictionary = {}          # roster_id -> UnitView(只有部署在格子上的节点才有 3D 视图；仓库里的在界面里)
var enemy_views: Array[UnitView] = []
var menu_views: Array[UnitView] = []
var orb_views: Array[OrbView] = []
var hover_view: UnitView = null
var selected_id: String = ""
var selected_view: UnitView = null       # 点击选中的棋子(我方/敌方/战斗中都可以)：只有它会打开详情卡片
var selected_storage: String = ""        # 点击选中的仓库里的节点(roster id)
var drag: Dictionary = {}
var selfless_btns: Dictionary = {}        # 无我(无我节点)：备战时浮在她头顶的按钮 roster_id -> Button(Run.selfless_buttons)
var form_btns: Dictionary = {}            # 表里之间(变奏节点)：备战时浮在她头顶的切换形态按钮 roster_id -> Button(Run.form_buttons)
var card_target: Dictionary = {}
var _rmb: bool = false
var _mmb: bool = false
var _battle_time: float = 0.0
var _count_timer: float = 0.0
var _loading: Label
var fade_rect: ColorRect                  # 场景切换(大地图 ⇄ 战斗场景)时的白色淡入淡出
var _paused_menu: bool = false
var _last_pos: Vector2 = Vector2.ZERO
var _last_summary: Array = []
var _last_report: BattleReport = null     # 上一场的详细战报(结算界面)
var cli: Dictionary = {}
var battle_speed: float = 1.0            # QoL：记住上一场选的倍速
var codex: Codex = null                  # 图鉴(标题 / 暂停菜单里打开，盖在最上层)
var workshop: WorkshopScreen = null      # 车间(装备制造)：大地图 / 备战 / 拾取战利品时打开(C)
var arena: ArenaMode = null              # 测试场(标题画面进入)：备战流程接一个 sandbox Run，见 game/arena_mode.gd

## 标题画面的背景：祭坛在卡车后方(北侧)，两侧几根石柱与残墙
const TITLE_LAYOUT := {"obstacles": [
	{"x": 11, "y": 4, "w": 3, "h": 2, "kind": "high", "style": "altar"},
	{"x": 7, "y": 5, "w": 1, "h": 1, "kind": "high", "style": "column_a"},
	{"x": 17, "y": 5, "w": 1, "h": 1, "kind": "high", "style": "column_b"},
	{"x": 4, "y": 7, "w": 2, "h": 1, "kind": "high", "style": "wall_a"},
	{"x": 19, "y": 8, "w": 1, "h": 1, "kind": "high", "style": "statue"},
	{"x": 16, "y": 4, "w": 3, "h": 1, "kind": "low", "style": "column_fallen"},
]}


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s: String = a.trim_prefix("--")
		var kv: PackedStringArray = s.split("=", true, 1)
		cli[kv[0]] = kv[1] if kv.size() == 2 else "1"
	cat = Catalog.load_all()
	UIKit.ensure()
	ThemeDB.fallback_font = UIKit.font_body
	var errs: Array[String] = cat.validate_all()
	for e: String in errs:
		push_warning("content: " + e)
	if cli.has("lang"):
		Loc.set_lang(str(cli["lang"]))
	world = GameWorld.new()
	world.name = "World"
	add_child(world)
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UI"
	add_child(ui_layer)
	wi = WorldInput.new()
	ui_layer.add_child(wi)
	wi.moved.connect(_on_moved)
	wi.pressed.connect(_on_pressed)
	wi.released.connect(_on_released)
	wi.wheel.connect(_on_wheel)
	wi.drop_hover.connect(_on_drop_hover)
	wi.dropped.connect(_on_dropped)
	wi.can_drop_cb = Callable(self, "_can_drop")
	hud = HUD.new()
	hud.cat = cat
	ui_layer.add_child(hud)
	screens = Screens.new()
	screens.cat = cat
	ui_layer.add_child(screens)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(UIKit.FADE.r, UIKit.FADE.g, UIKit.FADE.b, 0.0)
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(fade_rect)
	_connect_ui()
	if cli.has("probe_wrap"):
		_probe_wrap()
	hud.set_mode("none")
	_loading = UIKit.label(Loc.t("ui.loading"), 22, UIKit.TEXT, true)
	_loading.set_anchors_preset(Control.PRESET_CENTER)
	ui_layer.add_child(_loading)
	portraits = Portraits.new()
	add_child(portraits)
	await portraits.render_all(cat)
	hud.portraits = portraits.textures
	screens.portraits = portraits.textures
	_loading.queue_free()
	world.battle_view.feed.connect(_on_feed)
	world.battle_view.ended.connect(_on_battle_ended)
	world.battle_view.banner.connect(_on_banner)
	world.battle_view.ultimate.connect(_on_ultimate)
	world.battle_view.orb_dropped.connect(_on_orb_dropped)
	world.battle_view.truck_hit.connect(func(dmg: int) -> void:
		world.truck.hit()
		hud.flash_truck(dmg))
	world.truck.arrived.connect(_on_truck_arrived)
	world.battle_view.ember_out.connect(func(id: int) -> void: world.battlefield.put_out_ember(id, world.battle_view.fx))
	world.battle_view.ember_lit.connect(func(id: int) -> void: world.battlefield.relight_ember(id, world.battle_view.fx))
	world.battle_view.ember_add.connect(func(id: int, e: Dictionary) -> void: world.battlefield.add_ember(id, e, world.battle_view.fx))
	world.battle_view.hazard.connect(func(e: Dictionary) -> void: world.battlefield.on_hazard(e))
	world.battle_view.synced.connect(func(alpha: float) -> void: world.battlefield.sync_battle(world.battle_view.battle, alpha))
	_apply_cli()


func _connect_ui() -> void:
	hud.buy_requested.connect(_buy)
	hud.reroll_requested.connect(func() -> void: _toast_result(run.roll_shop(true)))
	hud.lock_requested.connect(func() -> void: run.toggle_lock())
	hud.xp_requested.connect(func() -> void: _toast_result(run.buy_xp()))
	hud.start_requested.connect(_start_battle)
	hud.go_requested.connect(_go_next)
	hud.storage_clicked.connect(_select_storage)
	hud.grid_clicked.connect(_on_grid_clicked)
	hud.grid_hovered.connect(_on_grid_hovered)
	hud.part_clicked.connect(_on_part_clicked)
	hud.workshop_requested.connect(open_workshop)
	hud.truck_rotate_requested.connect(_rotate_truck)
	screens.rest_repair.connect(func() -> void: _node_action(run.rest_repair()))
	screens.rest_upgrade.connect(func(rid: String) -> void: _node_action(run.rest_upgrade(rid)))
	screens.event_continue.connect(func() -> void: _node_action(run.event_continue()))
	screens.event_choose.connect(func(i: int) -> void: _node_action(run.event_choose(i)))
	screens.nshop_buy.connect(func(i: int) -> void: _node_action(run.node_shop_buy(i)))
	screens.nshop_refresh.connect(func() -> void: _node_action(run.node_shop_refresh()))
	screens.nshop_sell.connect(func(i: int) -> void: _node_action(run.node_shop_sell_part(i)))
	screens.nshop_leave.connect(func() -> void: _node_action(run.leave_node()))
	screens.mod_picked.connect(_on_mod_picked)
	screens.branch_picked.connect(_on_branch_picked)
	hud.map_hovered.connect(func(i: int, on: bool) -> void: world.overworld.set_hover(i if on else -1))
	hud.loot_done_requested.connect(_continue_after_loot)
	hud.speed_changed.connect(_set_speed)
	hud.item_hovered.connect(func(id: String) -> void: _mark_for_item(id))
	hud.shop_hovered.connect(func(def_id: String) -> void: _mark_copies(def_id))
	hud.trait_hovered.connect(func(tid: String) -> void: _mark_trait(tid))
	hud.marks_cleared.connect(_clear_marks)
	hud.cargo_dropped.connect(_on_cargo_dropped)
	hud.dock_dropped.connect(_on_dock_dropped)
	hud.pause_toggled.connect(_toggle_battle_pause)
	hud.skip_requested.connect(func() -> void: world.battle_view.skip())
	hud.menu_requested.connect(_open_pause)
	hud.lang_toggled.connect(_toggle_lang)
	screens.new_game.connect(_new_game)
	screens.resume.connect(_close_pause)
	screens.restart.connect(func() -> void:
		_close_pause()
		_new_game())
	screens.to_title.connect(_show_title)
	screens.quit_game.connect(func() -> void: get_tree().quit())
	screens.arena.connect(_open_arena)
	screens.codex.connect(open_codex)
	screens.lang_toggle.connect(_toggle_lang)
	screens.result_continue.connect(_after_result)
	screens.retry_run.connect(_new_game)


# =============================================================== 启动 / 命令行(测试用)
## --state=map|prepare|battle  直接进入对应阶段(prepare/battle 会跳过卡车行驶与场景切换动画)；--intensity=N 指定第一场作战的战斗强度
func _apply_cli() -> void:
	# 命令行直接开局时跳过"初始改装"三选一：--mod=truck_zone|truck_free|truck_wide(默认 truck_zone)
	var auto_mod: String = str(cli.get("mod", "truck_zone"))
	match str(cli.get("state", "")):
		"map":
			_new_game(auto_mod)
		"prepare":
			_new_game(auto_mod)
			_cli_first_node()
		"battle":
			_new_game(auto_mod)
			_cli_first_node()
			await get_tree().process_frame
			_start_battle()
		"event":
			# --state=event --event=<事件 id>(方格网章节)：直接打开这个事件(截图用)
			_new_game(auto_mod)
			await get_tree().process_frame
			run.phase = "event"
			run.event_state = {"id": str(cli.get("event", "burning_fountain")), "node": run.pos, "option": -1, "outcome": ""}
			if cli.has("option"):
				run.event_choose(int(cli["option"]))
			if cli.has("event_fight"):
				# --event_fight=1：直接进这个事件的那场战斗(截图用)：第一个带 battle 效果的结果
				var eopts: Array = run.event_def().get("options", [])
				for oi in range(eopts.size()):
					for oc: Dictionary in (eopts[oi] as Dictionary).get("outcomes", []):
						for ef: Dictionary in oc.get("effects", []):
							if str(ef.get("type", "")) == "battle" and not run.event_state.has("battle"):
								run.event_state["option"] = oi
								run.event_state["outcome"] = str(oc.get("id", ""))
								run.event_state["battle"] = ef
				run.event_continue()
				await _goto_battlefield(true)
				if cli.has("battle_time"):
					await get_tree().process_frame
					_start_battle()
			else:
				_open_node_screen()
		_:
			_show_title()
	if cli.has("workshop"):
		# --workshop=craft|salvage：打开车间(截图用)
		await get_tree().process_frame
		open_workshop()
		if workshop != null and str(cli["workshop"]) == "salvage":
			workshop.select_tab("salvage")
	if cli.has("cam"):
		# --cam=x,z,pitch,dist,yaw：截图用的镜头(世界坐标)；--cam=boss,pitch,dist,yaw：对着首领节点(方格网章节)
		var cp: PackedStringArray = str(cli["cam"]).split(",")
		await get_tree().process_frame
		if cp[0] == "boss" and run.is_grid():
			var bpos: Vector3 = world.overworld.city.node_pos.get(str(run.gmap["boss"]), Vector3.ZERO)
			world.rig.set_view(bpos, float(cp[3]) if cp.size() > 3 else 0.0, float(cp[1]), float(cp[2]), true)
		else:
			world.rig.set_view(Vector3(float(cp[0]), 0.0, float(cp[1])), float(cp[4]) if cp.size() > 4 else 0.0, float(cp[2]), float(cp[3]), true)
	if cli.has("shot"):
		# 冒烟测试的窗口可能被 tools/quiet_window.sh 缩成 1×1(不弹窗)：改成按设计分辨率渲染再缩放上屏，截图跟窗口大小无关
		var win: Window = get_tree().root
		if win.size.x < 640:
			win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
			win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP   # 1×1 的窗口是正方形：expand 会把画面撑成 1920×1920
			win.content_scale_size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
				int(ProjectSettings.get_setting("display/window/size/viewport_height")))
		var frames: int = int(cli.get("frames", "60"))
		for i in range(frames):
			await get_tree().process_frame
		if cli.has("battle_time") and world.battle_view.battle != null:
			var tgt: float = float(cli["battle_time"])
			while world.battle_view.battle != null and world.battle_view.battle.time < tgt and world.battle_view.battle.state != "ended":
				await get_tree().process_frame
		for i2 in range(6):
			await get_tree().process_frame
		var img: Image = get_viewport().get_texture().get_image()
		img.save_png(str(cli["shot"]))
		get_tree().quit()


## 命令行：直接开到第一个战斗节点(线性章节 = 下一站；方格网章节 = 最近的一场作战)
func _cli_first_node() -> void:
	if not run.is_grid():
		_go_next(true)
		return
	var reach: Dictionary = run.reachable()
	var best := ""
	for k: String in reach.keys():
		var t: String = str(run.gnode(k).get("type", ""))
		if k != run.pos and (t == "fight" or t == "elite") and (best == "" or int(reach[k]) < int(reach[best])):
			best = k
	if best == "":
		for k2: String in reach.keys():
			if k2 != run.pos:
				best = k2
				break
	run.gnode(best)["type"] = "fight" if str(run.gnode(best)["type"]) not in ["fight", "elite"] else str(run.gnode(best)["type"])
	if cli.has("intensity") or cli.has("enc"):
		# --intensity=N：这一场普通作战按指定的战斗强度配怪(截图 / 调试用)；再加 --elite=1 = 精英战；
		# --enc=boss|hunt|elite：按首领 / 追猎 / 精英战配怪(没给强度就用章节的首领 / 追猎强度)
		var ek: String = str(cli.get("enc", "elite" if cli.has("elite") else "fight"))
		run.gnode(best)["type"] = "elite" if ek == "elite" else "fight"
		run.gnode(best)["encounter"] = run._make_encounter(ek, int(cli.get("intensity", "-1")))
		if cli.has("head"):
			# --head=<单位 id>：把领头的那只(精英 / 首领)换成指定的单位(截图用)
			(run.gnode(best)["encounter"]["units"][0] as Array)[0] = str(cli["head"])
	_go_to(best, true)


## 冒烟测试用：中文长句能否在汉字之间换行(导出包需要打进文本服务器的断行数据，否则只能在空格处换行)
func _probe_wrap() -> void:
	var r := RichTextLabel.new()
	r.fit_content = true
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.custom_minimum_size = Vector2(330, 0)
	r.size = Vector2(330, 10)
	r.add_theme_font_size_override("normal_font_size", 16)
	r.text = "◆ 每第 3 次普通攻击命中时，对当前攻击目标触发装备载荷(触发数值 = 20)"
	ui_layer.add_child(r)
	for i in range(3):
		await get_tree().process_frame
	var line_of: int = r.get_character_line(r.get_parsed_text().find("次"))
	print("WRAP_PROBE %s (line of 次 = %d, lines = %d)" % ["ok" if line_of == 0 else "BAD", line_of, r.get_line_count()])
	r.queue_free()


# =============================================================== 标题 / 新游戏
func _show_title() -> void:
	_close_pause()
	_close_arena()
	state = "title"
	_apply_ui_theme(UITheme.DEFAULT)
	_clear_prep_views()
	_clear_menu_views()
	_clear_orbs()
	world.battle_view.clear()
	hud.set_mode("none")
	screens.hide_all()
	screens.show_title()
	# 标题画面：工坊卡车停在白色遗迹里(远处是彩虹水晶祭坛)，几个节点站在车旁
	_clear_enemy_views()
	fade_rect.color.a = 0.0
	world.show_battlefield(TITLE_LAYOUT, 1)
	world.stage.show_deploy(false, true)
	world.stage.set_threats({})
	world.stage.set_starfall({})
	var base := Vector3.ZERO
	world.truck.rotation.y = -0.35
	world.rig.set_preset("menu")
	var lineup: Array = [["node_archer", Vector3(0.6, 0, 1.9), -0.55, "rapidfire_arbalest"], ["node_darkknight", Vector3(2.4, 0, 1.2), -0.5, ""],
		["node_nurse", Vector3(-1.1, 0, 2.2), -0.6, ""], ["node_magi", Vector3(1.6, 0, 2.9), -0.5, "prism_scythe"],
		["node_shielder", Vector3(3.4, 0, 0.1), -0.45, ""], ["node_sniper", Vector3(-2.5, 0, 1.5), -0.6, "black_battlefield"],
		["node_dancer", Vector3(4.0, 0, 2.2), -0.7, ""], ["node_berserker", Vector3(-0.4, 0, 3.4), -0.45, "wolf_blades"]]
	for e: Array in lineup:
		var v := UnitView.new()
		world.battle_root.add_child(v)
		var md: UnitDef = cat.get_unit(str(e[0]))
		v.setup(md, 3 if str(e[0]) == "node_archer" else 1, 0, false, cat.resolve_weapon(md, str(e[3])))
		v.position = base + (e[1] as Vector3)
		v.rotation.y = float(e[2])
		v.set_bar_visible(false)
		v.set_team_ring_visible(false)
		menu_views.append(v)


func _clear_menu_views() -> void:
	for v: UnitView in menu_views:
		v.queue_free()
	menu_views.clear()


## 新游戏：出发前先给卡车选一项初始改装(三选一，screens.show_mod_pick)；auto_mod 不为空(命令行 / 测试)就直接选好进地图
func _new_game(auto_mod: String = "") -> void:
	if workshop != null:
		workshop.queue_free()
		workshop = null
	_close_pause()
	_close_arena()
	_clear_menu_views()
	_clear_prep_views()
	_clear_orbs()
	world.battle_view.clear()
	screens.hide_all()
	_truck_hinted = false
	run = Run.create(cat, int(cli.get("seed", "0")), str(cli.get("chapter", "ch0")), true)
	run.changed.connect(_on_run_changed)
	hud.run = run
	_apply_ui_theme(str(run.chapter.get("ui_theme", "")))
	world.build_chapter(run)
	if auto_mod != "":
		run.pick_mod(auto_mod)
	_enter_map(true)
	if run.phase == "start_mod":
		state = "start_mod"
		hud.set_mode("none")
		screens.show_mod_pick(run, true)
		return
	_banner_chapter()


func _banner_chapter() -> void:
	hud.show_banner(Loc.t("chapter.%s.name" % run.chapter_id), UIKit.GOLD,
		"Episode %s · %s" % [run.chapter_id.trim_prefix("ch").pad_zeros(2), Loc.t_in("en", "chapter.%s.short" % run.chapter_id)])


## 测试场：标题画面的「测试场」进来，sandbox Run 接进备战流程(拖拽 / 详情卡 / 仓库 / 羁绊 / 战斗 / 战报都是同一套)
func _open_arena() -> void:
	_close_pause()
	_close_arena()
	_clear_menu_views()
	_clear_prep_views()
	_clear_enemy_views()
	_clear_orbs()
	world.battle_view.clear()
	screens.hide_all()
	arena = ArenaMode.new()
	arena.name = "Arena"
	add_child(arena)
	arena.open(self)
	run = arena.run
	run.changed.connect(_on_run_changed)
	hud.run = run
	_apply_ui_theme(str(run.chapter.get("ui_theme", "")))
	world.show_battlefield(run.current_layout(), arena.map_seed)
	world.truck.rotation.y = 0.0
	state = "prepare"
	world.stage.show_deploy(false, true)
	hud.set_mode("arena")
	world.rig.set_preset("prep", true)
	_sync_prep(true)
	_sync_enemy_preview()
	hud.trait_box.modulate.a = 1.0
	hud.show_banner(Loc.t("ui.arena_title"), UIKit.ACCENT, "Balance Test Range")


func _close_arena() -> void:
	if arena == null:
		return
	arena.close()
	arena.queue_free()
	arena = null
	hud.trait_box.modulate.a = 1.0


## 章节 UI 配色接口：进入章节时按章节数据里的 ui_theme 换配色，HUD 整体重建
func _apply_ui_theme(name: String) -> void:
	if UIKit.apply_theme(name):
		hud.rebuild()
	fade_rect.color = Color(UIKit.FADE.r, UIKit.FADE.g, UIKit.FADE.b, fade_rect.color.a)


func _on_run_changed(_reason: String) -> void:
	if _reason == "truck" and state == "prepare":
		world.apply_truck(run.current_layout())
		_sync_enemy_preview()
	if arena != null and arena.panel != null:
		arena.panel.show_unit(arena.panel._sel)
	if state == "prepare" or state == "loot" or state == "map":
		hud.hide_tip()
		hud.refresh()
		if state != "map":
			_sync_prep(false)
			_refresh_quarry_marks()
		_refresh_card()
	else:
		hud.refresh()


# =============================================================== 地图 / 行驶 / 场景切换
## 大地图(战斗外)：俯瞰路线，地图节点是可以悬停/点击的图标按钮
func _enter_map(instant: bool = false) -> void:
	state = "map"
	_clear_prep_views()
	_clear_enemy_views()
	world.battle_view.clear()
	world.stage.set_threats({})
	world.stage.set_starfall({})
	world.stage.show_deploy(false, true)
	world.show_map(run)
	world.map_view(instant)
	hud.clear_loot()
	hud.set_mode("map")
	_place_map_buttons()


## 场景切换用的白色淡入淡出
func _fade(to_alpha: float, dur: float) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(fade_rect, "color:a", to_alpha, dur)
	await tw.finished


## 出发：卡车沿虚线开往下一个地图节点——这段行驶就是载入战斗场景的过程(instant：跳过动画，测试/命令行用)
func _go_next(instant: bool = false) -> void:
	if run == null or run.phase != "map" or state != "map" or run.is_grid():
		return
	state = "travel"
	hud.set_mode("travel")
	world.overworld.set_hover(-1)
	if instant:
		_arrive(true)
		return
	var dest: Vector3 = world.overworld.node_pos[run.node_index]
	var from: Vector3 = world.truck.position
	var pts := PackedVector3Array([from, dest])
	world.truck.drive(pts, clampf(from.distance_to(dest) / 7.5, 1.4, 2.6), dest)


func _on_truck_arrived() -> void:
	if state != "travel":
		return
	if run.is_grid():
		return              # 方格网章节：开车的过场由 _drive_grid 自己控制
	await _fade(1.0, 0.3)
	_arrive(false)
	await _fade(0.0, 0.5)


# =============================================================== 方格网章节(第一章起)
## 点击大地图上的节点：零件选目标模式下是用零件；否则开车过去(行动力由 Run 扣)
func _on_grid_clicked(key: String) -> void:
	if state != "map" or run == null or run.phase != "map":
		return
	if hud.part_mode >= 0:
		var i: int = hud.part_mode
		hud.part_mode = -1
		var from0: String = run.pos
		var res0: Dictionary = run.use_part(i, key)
		if not res0["ok"]:
			_toast_result(res0)
			hud.refresh()
			return
		_drive_grid(from0, [key], true)
		return
	_go_to(key)


func _go_to(key: String, instant: bool = false) -> void:
	if state != "map" or run.phase != "map":
		return
	var from: String = run.pos
	var path: Array[String] = run.path_to(key)
	var res: Dictionary = run.move_to(key)
	if not res["ok"]:
		_toast_result(res)
		return
	if instant:
		state = "travel"
		_arrive_grid(true)
		return
	_drive_grid(from, path, false)


## 开车的过场：镜头拉近到卡车 → 沿路开出去一小段 → 黑屏 → 在目的地亮起来(街道是弯的，不用一路开到)。
## 路程为空 = 原地再进；跳跃类零件没有路，就朝目标方向开一小段
func _drive_grid(from: String, path: Array, jump: bool) -> void:
	state = "travel"
	hud.set_mode("travel")
	var city: CityOverworld = world.overworld.city
	city.show_path("", [], Color.WHITE)
	if path.is_empty() or city == null:
		_arrive_grid(false)
		return
	var pts := PackedVector3Array()
	if jump:
		var a: Vector3 = city.node_pos[from]
		pts = PackedVector3Array([a, a.lerp(city.node_pos[path[0]], 0.3)])
	else:
		pts = city.drive_points(from, str(path[0]), 0.55)
	world.truck.position = pts[0]
	world.truck.drive(pts, 2.4, pts[pts.size() - 1])
	await get_tree().create_timer(1.6).timeout
	await _fade(1.0, 0.45)
	world.truck.stop_drive()
	world.truck.position = city.node_pos.get(run.pos, pts[pts.size() - 1])
	_arrive_grid(false, true)


## 到了：按 Run 进入的阶段切换画面。dark = 已经黑屏(开车过场之后)：在目的地附近亮起来
func _arrive_grid(instant: bool, dark: bool = false) -> void:
	var city: CityOverworld = world.overworld.city
	match run.phase:
		"prepare":
			await _goto_battlefield(instant)
		"rest", "event", "shop":
			_open_node_screen()
			if dark and city != null:
				world.rig.set_view(city.node_pos.get(run.pos, Vector3.ZERO) + Vector3(0, 0.5, 4.0), 0.0, 50.0, 62.0, true)
				await _fade(0.0, 0.5)
		_:
			if dark and city != null:
				world.show_map(run)
				world.rig.set_view(city.node_pos.get(run.pos, Vector3.ZERO) + Vector3(0, 0.5, 4.0), 0.0, 50.0, 62.0, true)
				_fade(0.0, 0.5)
			_enter_map(instant)


## 进战场(普通 / 精英 / 首领 / 追猎)
func _goto_battlefield(instant: bool) -> void:
	state = "travel"
	hud.set_mode("travel")
	screens.hide_all()
	if not instant:
		await _fade(1.0, 0.3)
	world.show_battlefield(run.current_layout(), run.seed_value * 13 + run.visits)
	_enter_prepare(instant)
	if run.hunt_active:
		hud.show_banner(Loc.t("ui.hunt_banner"), UIKit.BAD, "The Hunt")
		hud.toast_msg(Loc.t("ui.hunt_hint"))
	elif run.battle_kind() == "boss":
		hud.show_banner(Loc.t("ui.node_type.boss"), UIKit.BAD, "Boss")
	elif run.battle_kind() == "event":
		hud.show_banner(Loc.t("event.%s.title" % str(run.event_state.get("id", ""))), UIKit.BAD, Loc.t_in("en", "ui.event.battle_banner"))
	if not instant:
		await _fade(0.0, 0.5)


## 非战斗节点：大地图当背景，中间是节点界面
func _open_node_screen() -> void:
	state = "node"
	hud.set_mode("none")
	hud.hide_card()
	world.show_map(run)
	match run.phase:
		"rest":
			screens.show_rest(run)
		"event":
			screens.show_event(run)
		"shop":
			screens.show_node_shop(run, cat)


## 节点界面里的操作：还在店里就刷新界面；离开了就回地图(或者行动力用完 → 追猎)
func _node_action(res: Dictionary) -> void:
	if state != "node":
		return
	if not res["ok"]:
		_toast_result(res)
	match run.phase:
		"shop", "rest", "event":
			_open_node_screen()
		"prepare":
			await _goto_battlefield(false)
		"over":
			screens.hide_all()
			_show_gameover()
		_:
			screens.hide_all()
			_enter_map(false)


func _on_grid_hovered(key: String, on: bool) -> void:
	var city: CityOverworld = world.overworld.city
	if city == null or state != "map":
		return
	if not on or key == run.pos:
		city.show_path("", [], Color.WHITE)
		return
	var p: Array[String] = run.path_to(key)
	var ok: bool = not p.is_empty() and p.size() <= run.ap
	city.show_path(run.pos, p, Color(1.0, 0.78, 0.25, 0.95) if ok else Color(1.0, 0.3, 0.25, 0.8))


## 零件栏：加行动力 / 观测直接用；移动类进入选目标模式(再点一次取消)
func _on_part_clicked(i: int) -> void:
	if state != "map" or run.phase != "map" or i >= run.parts.size():
		return
	var kind: String = str(run.part_def(run.parts[i]).get("kind", ""))
	if kind == "move":
		hud.part_mode = -1 if hud.part_mode == i else i
		if hud.part_mode >= 0:
			hud.toast_msg(Loc.t("ui.part_pick"))
		hud.refresh()
		return
	hud.part_mode = -1
	_toast_result(run.use_part(i))
	world.overworld.city.refresh(run)
	hud.refresh()


## 打通一章：卡车改装(占位) → 下一章的分支 / 通关
## 章节打通：先选下一章的分支，再按那一章的颜色三选一卡车改装(Run.roll_mod_options)，然后开进新章
func _show_chapter_end() -> void:
	state = "chapter_end"
	hud.set_mode("none")
	hud.hide_card()
	if run.phase == "branch":
		screens.show_branch(run)
	elif run.phase == "chapter_end":
		screens.show_mod_pick(run)
	else:
		_show_gameover()


func _on_mod_picked(id: String) -> void:
	if state == "start_mod":
		var sres: Dictionary = run.pick_mod(id)
		if not bool(sres["ok"]):
			_toast_result(sres)
			return
		screens.hide_all()
		_enter_map(true)
		_banner_chapter()
		return
	if state != "chapter_end":
		return
	var res: Dictionary = run.pick_mod(id)
	if not bool(res["ok"]):
		_toast_result(res)
		return
	if run.phase == "over":
		screens.hide_all()
		_show_gameover()
		return
	_travel_to_new_chapter()


func _on_branch_picked(id: String) -> void:
	if state != "chapter_end":
		return
	var res: Dictionary = run.choose_branch(id)
	if not res["ok"]:
		_toast_result(res)
		return
	if run.phase == "chapter_end":
		screens.show_mod_pick(run)
		return
	_travel_to_new_chapter()


## 开进新的一章：白屏淡出 → 搭新章的大地图 → 淡入 + 章名横幅
func _travel_to_new_chapter() -> void:
	screens.hide_all()
	state = "travel"
	await _fade(1.0, 0.35)
	_clear_orbs()
	world.battle_view.clear()
	_apply_ui_theme(str(run.chapter.get("ui_theme", "")))
	world.build_chapter(run)
	_enter_map(true)
	await _fade(0.0, 0.6)
	hud.show_banner(Loc.t("chapter.%s.name" % run.chapter_id), UIKit.ACCENT,
		"Episode %s · %s" % [HUD.chapter_number(run.chapter_id), Loc.t_in("en", "chapter.%s.short" % run.chapter_id)])


## 抵达：结算到达收入/商店刷新，搭建这个地图节点的战斗场景(卡车停在正中央)，进入备战
func _arrive(instant: bool) -> void:
	run.travel()
	world.show_battlefield(run.current_layout(), run.seed_value * 13 + run.node_index)
	_enter_prepare(instant)


func _enter_prepare(instant: bool = true) -> void:
	state = "prepare"
	world.stage.show_deploy(false, true)
	hud.set_mode("prepare")
	if instant:
		world.rig.set_preset("prep", true)
	else:
		# 镜头从高处落到备战视角；卡车落地扬起一圈尘土，节点们从货厢里现身
		var p: Dictionary = CamRig.PRESETS["prep"]
		world.rig.set_view(p["target"], 0.0, 72.0, float(p["dist"]) * 1.35, true)
		world.rig.set_preset("prep")
		world.battle_view.fx.ring(Vector3.ZERO, 3.2, Color(0.9, 0.88, 0.84, 0.9), 0.6)
		world.battle_view.fx.burst(Vector3(0, 0.3, 0), Color(0.95, 0.94, 0.9), 22, 3.0, 0.9)
	_sync_prep(instant)
	_sync_enemy_preview()
	if run.node_index == 0 and not run.is_grid():
		hud.toast_msg(Loc.t("ui.tutorial"), true)
	elif run.truck_can_move() and not _truck_hinted:
		_truck_hinted = true
		hud.toast_msg(Loc.t("ui.truck_hint"), true)


## 地图节点按钮跟着 3D 位置走(镜头移动/缩放时)
func _place_map_buttons() -> void:
	if world.overworld.city != null:
		for k: String in world.overworld.city.node_pos.keys():
			# 按钮像地图钉一样浮在路口上方(路口地面上有一圈同色的标记，卡车停在标记里)
			var wp: Vector3 = world.overworld.city.node_pos[k] + Vector3(0, 9.0, 0)
			hud.place_grid_button(k, world.rig.project(wp))
		return
	if world.overworld.node_pos.is_empty():
		return
	for i in range(world.overworld.node_pos.size()):
		var wp: Vector3 = world.overworld.node_pos[i] + Vector3(0, 0.4, 0)
		hud.place_map_button(i, world.rig.project(wp) - Vector2(0, 6))


# =============================================================== 备战期视图同步
func _clear_prep_views() -> void:
	for id: String in prep_views.keys():
		(prep_views[id] as UnitView).queue_free()
	prep_views.clear()
	_clear_selfless_buttons()
	hover_view = null
	selected_id = ""
	selected_view = null
	drag = {}
	card_target = {}
	hud.hide_card()
	world.stage.clear_highlights()
	world.range_ring.visible = false


func _clear_enemy_views() -> void:
	for v: UnitView in enemy_views:
		v.queue_free()
	enemy_views.clear()


func _sync_prep(instant: bool) -> void:
	# 只有部署在格子上的节点有 3D 视图；收进仓库的节点在界面底部的仓库条里
	for id: String in prep_views.keys():
		if not run.roster.has(id) or run.roster[id]["cell"] == null:
			var gone: UnitView = prep_views[id]
			if run.roster.has(id) and not instant:
				world.battle_view.fx.burst(gone.position + Vector3(0, 0.6, 0), Color("#a8f6ff"), 10, 2.0, 0.8)
			gone.queue_free()
			prep_views.erase(id)
			if selected_id == id:
				selected_id = ""
			if hover_view == gone:
				hover_view = null
	for id2: String in run.roster.keys():
		var u: Dictionary = run.roster[id2]
		if u["cell"] == null:
			continue
		var v: UnitView = prep_views.get(id2, null)
		var target: Vector3 = world.stage.cell_local(u["cell"])
		if v == null:
			v = UnitView.new()
			world.units_layer.add_child(v)
			v.setup(run.unit_def(u), int(u["star"]), GC.TEAM_PLAYER, false, run.weapon_of(u))
			v.roster_id = id2
			prep_views[id2] = v
			v.position = target
			if not instant:
				v.set_dissolve(1.0)
				create_tween().tween_method(v.set_dissolve, 1.0, 0.0, 0.5)
				world.battle_view.fx.pillar(v.position, GC.faction_color(v.def.faction_id), 0.6)
		if v.star != int(u["star"]):
			var was: int = v.star
			v.set_star(int(u["star"]))
			if int(u["star"]) > was:
				world.battle_view.fx.ring(v.position, 1.6, UIKit.GOLD, 0.7)
				world.battle_view.fx.pillar(v.position, UIKit.GOLD, 0.8)
		# 换形态(变奏节点·表里之间)：身体 / 武器外观跟着形态换
		var fd: UnitDef = run.unit_def(u)
		if v.def != fd:
			v.set_def(fd)
			if not instant:
				world.battle_view.fx.pianist_flip(v.position + Vector3(0, 0.9, 0), fd.form == "angel")
		# 换武器：模型手里的武器与动作模组立刻跟着换
		var w: EquipmentDef = run.weapon_of(u)
		if v.weapon != w:
			v.set_weapon(w)
			if not instant:
				world.battle_view.fx.burst(v.position + Vector3(0, 0.8, 0), UIKit.weapon_color(w), 12, 2.2, 0.9)
		v.cell = u["cell"]
		v.bench_index = -1
		v.set_meta("weapon", str(u["weapon"]))
		_update_badges(v, u)
		if drag.is_empty() or drag.get("view") != v:
			var yaw: float = _facing_for(Vector2(target.x, target.z), true)
			if instant:
				v.position = target
				v.rotation.y = yaw
			else:
				var tw: Tween = create_tween().set_parallel(true)
				tw.tween_property(v, "position", target, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				tw.tween_property(v, "rotation:y", lerp_angle(v.rotation.y, yaw, 1.0), 0.16)
		v.set_selected(id2 == selected_id)
	_face_enemy_previews()
	_sync_selfless_buttons()
	_sync_form_buttons()


## 无我的按钮：场上的无我节点、仓库里还有别的同种棋子 → 头顶一个按钮(点了就 Run.selfless)；已经点过 → 按钮变成"就绪"(不能再点)
func _sync_selfless_buttons() -> void:
	var want: Dictionary = run.selfless_buttons() if run != null and state == "prepare" else {}
	for rid: String in selfless_btns.keys():
		if not want.has(rid) or not prep_views.has(rid):
			(selfless_btns[rid] as Button).queue_free()
			selfless_btns.erase(rid)
	for rid2: String in want.keys():
		if not prep_views.has(rid2):
			continue
		var ready: bool = bool(want[rid2])
		var btn: Button = selfless_btns.get(rid2) as Button
		if btn == null:
			btn = UIKit.button("", "danger", Vector2(0, 30))
			btn.add_theme_font_size_override("font_size", 14)
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			var rid_c: String = rid2
			btn.pressed.connect(func() -> void:
				var res: Dictionary = run.selfless(rid_c)
				if bool(res["ok"]):
					hud.toast_msg(Loc.t("ui.selfless_done"), true)
				else:
					_toast_result(res))
			hud.card_holder.add_child(btn)
			selfless_btns[rid2] = btn
		btn.text = Loc.t("ui.selfless_ready") if ready else Loc.t("ui.selfless_btn")
		btn.disabled = ready
		btn.tooltip_text = Loc.t("ui.selfless_tip")


func _clear_selfless_buttons() -> void:
	for rid: String in selfless_btns.keys():
		(selfless_btns[rid] as Button).queue_free()
	selfless_btns.clear()
	for rid2: String in form_btns.keys():
		(form_btns[rid2] as Button).queue_free()
	form_btns.clear()


## 表里之间的按钮：场上有形态的棋子 → 头顶一个按钮，写着"切换为天使 / 恶魔"(点了就 Run.toggle_form，羁绊与外观立刻跟着变)
func _sync_form_buttons() -> void:
	var want: Dictionary = run.form_buttons() if run != null and state == "prepare" else {}
	for rid: String in form_btns.keys():
		if not want.has(rid) or not prep_views.has(rid):
			(form_btns[rid] as Button).queue_free()
			form_btns.erase(rid)
	for rid2: String in want.keys():
		if not prep_views.has(rid2):
			continue
		var btn: Button = form_btns.get(rid2) as Button
		if btn == null:
			btn = UIKit.button("", "accent", Vector2(0, 30))
			btn.add_theme_font_size_override("font_size", 14)
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			var rid_c: String = rid2
			btn.pressed.connect(func() -> void:
				var res: Dictionary = run.toggle_form(rid_c)
				if not bool(res["ok"]):
					_toast_result(res))
			hud.card_holder.add_child(btn)
			form_btns[rid2] = btn
		var to: String = "demon" if str(want[rid2]) == "angel" else "angel"
		btn.text = Loc.t("ui.form_to_" + to)
		btn.tooltip_text = Loc.t("ui.form_tip")


func _place_selfless_buttons() -> void:
	for rid: String in selfless_btns.keys():
		var btn: Button = selfless_btns[rid]
		var v: UnitView = prep_views.get(rid) as UnitView
		if v == null or not is_instance_valid(v):
			btn.visible = false
			continue
		var sp: Vector2 = world.rig.project(v.global_position + Vector3(0, v.body_height + 0.95, 0))
		btn.position = sp - btn.size * 0.5
		btn.visible = drag.is_empty() and v.visible
	for rid2: String in form_btns.keys():
		var fb: Button = form_btns[rid2]
		var fv: UnitView = prep_views.get(rid2) as UnitView
		if fv == null or not is_instance_valid(fv):
			fb.visible = false
			continue
		var fsp: Vector2 = world.rig.project(fv.global_position + Vector3(0, fv.body_height + 0.95, 0))
		fb.position = fsp - fb.size * 0.5
		fb.visible = drag.is_empty() and fv.visible


## 朝向最近的对手：我方棋子看最近的敌人预览，敌人预览看最近的我方棋子(没有则看卡车)
func _facing_for(p: Vector2, player: bool) -> float:
	var best := Vector2.ZERO
	var bd := 1e18
	var pool: Array = enemy_views if player else prep_views.values()
	for o: UnitView in pool:
		var op := Vector2(o.position.x, o.position.z)
		var d: float = op.distance_squared_to(p)
		if d < bd:
			bd = d
			best = op
	if bd >= 1e17:
		return GC.facing_to(p, run.truck_layout.truck_center()) if not player else PI
	return GC.facing_to(p, best)


func _face_enemy_previews() -> void:
	for v: UnitView in enemy_views:
		var yaw: float = _facing_for(Vector2(v.position.x, v.position.z), false)
		create_tween().tween_property(v, "rotation:y", lerp_angle(v.rotation.y, yaw, 1.0), 0.2)


## 血条下的小色块：装备了带效果的武器 = 武器颜色；只有基础武器 = 暗色
func _update_badges(v: UnitView, u: Dictionary) -> void:
	var col := Color(1, 1, 1, 0.22)
	if str(u["weapon"]) != "":
		col = UIKit.weapon_color(run.weapon_of(u))
		col.a = 1.0
	v.bar.set_instance_shader_parameter("eq0", col)
	v.bar.set_instance_shader_parameter("eq1", Color(0, 0, 0, 0))
	v.bar.set_instance_shader_parameter("eq2", Color(0, 0, 0, 0))


func _sync_enemy_preview() -> void:
	_clear_enemy_views()
	if run == null:
		world.stage.set_threats({})
		world.stage.set_starfall({})
		return
	var wave: Array = run.wave_def().get("units", [])
	var spawn: Array[Vector2] = cat.wave_positions(wave, run.current_map())
	var threats: Dictionary = {}
	for i in range(wave.size()):
		var e: Array = wave[i]
		var d: UnitDef = cat.get_unit(str(e[0]))
		var v := UnitView.new()
		world.units_layer.add_child(v)
		var opt: Dictionary = e[4] if e.size() > 4 else {}
		var wid: String = Catalog.wave_weapon_id(e)
		v.setup(d, int(e[1]), GC.TEAM_ENEMY, bool(opt.get("boss", false)), cat.resolve_weapon(d, wid))
		var sp: Vector2 = opt.get("pos", spawn[i])
		v.position = Vector3(sp.x, 0.0, sp.y)
		v.rotation.y = GC.facing_to(sp, run.truck_layout.truck_center())
		v.set_meta("weapon", wid)
		v.set_meta("enemy_preview", true)
		enemy_views.append(v)
		var where: Variant = e[2]
		if where is String:
			threats[where] = int(threats.get(where, 0)) + 1
	world.stage.set_threats(threats)
	_face_enemy_previews()
	_refresh_quarry_marks()


## 星旅节点的预计落点(仓库里有、场上没有时)：备战时在地上标出来
func _refresh_starfall() -> void:
	world.stage.set_starfall(run.starfall_preview() if run != null and state == "prepare" else {})


## 狩猎旗标标记的敌人预览：头顶插旗、脚下红圈
func _refresh_quarry_marks() -> void:
	_refresh_starfall()
	for i in range(enemy_views.size()):
		var on: bool = run != null and run.phase == "prepare" and i == run.hunt_mark and run.has_token("hunt_mark")
		if is_instance_valid(enemy_views[i]):
			enemy_views[i].set_quarry(on)


# =============================================================== 购买 / 提示
func _toast_result(res: Dictionary) -> void:
	if not bool(res["ok"]):
		hud.toast_msg(Loc.t(str(res["reason"])))


func _buy(index: int) -> void:
	if state != "prepare" and state != "loot":
		return
	_toast_result(run.buy(index))


func _newest_roster_id() -> String:
	var best := ""
	var best_n := -1
	for id: String in run.roster.keys():
		var n: int = int(id.substr(1))
		if n > best_n:
			best_n = n
			best = id
	return best


# =============================================================== 拾取
func _ray(pos: Vector2) -> Array:
	return world.rig.ray(pos)


func _ray_hits_view(o: Vector3, d: Vector3, v: UnitView) -> float:
	var base: Vector3 = v.global_position
	var r: float = 0.58 * v.scale_mult
	var h: float = v.body_height + 0.1
	var ox: float = o.x - base.x
	var oz: float = o.z - base.z
	var a: float = d.x * d.x + d.z * d.z
	if a < 0.000001:
		return -1.0
	var b: float = 2.0 * (ox * d.x + oz * d.z)
	var c: float = ox * ox + oz * oz - r * r
	var disc: float = b * b - 4.0 * a * c
	if disc < 0.0:
		return -1.0
	var sq: float = sqrt(disc)
	var t1: float = (-b - sq) / (2.0 * a)
	var t2: float = (-b + sq) / (2.0 * a)
	# 有限圆柱：侧面区间 [t1,t2] 与高度区间取交集(镜头很陡时射线会从顶盖进入)
	var ylo: float = base.y - 0.05
	var yhi: float = base.y + h
	if absf(d.y) > 0.000001:
		var ta: float = (ylo - o.y) / d.y
		var tb: float = (yhi - o.y) / d.y
		t1 = maxf(t1, minf(ta, tb))
		t2 = minf(t2, maxf(ta, tb))
	elif o.y < ylo or o.y > yhi:
		return -1.0
	if t2 < t1 or t2 < 0.0:
		return -1.0
	return maxf(t1, 0.0)


func _pick_view(pos: Vector2, include_enemy: bool = true) -> UnitView:
	var r: Array = _ray(pos)
	var o: Vector3 = r[0]
	var d: Vector3 = r[1]
	var best: UnitView = null
	var best_t := 1e9
	var pool: Array = prep_views.values()
	if include_enemy:
		pool = pool + enemy_views
	if state == "battle" and world.battle_view.battle != null:
		pool = world.battle_view.views.values()
	for v: UnitView in pool:
		if v.dying or not v.visible:
			continue
		var t: float = _ray_hits_view(o, d, v)
		if t >= 0.0 and t < best_t:
			best_t = t
			best = v
	return best


func _pick_ground(pos: Vector2, wide: bool = false) -> Dictionary:
	var r: Array = _ray(pos)
	return world.stage.pick(r[0], r[1], wide)


## 拖着的这个棋子能不能部署到全场(随心所欲；千变万化 = 只能站敌人身边，也要在全场里挑)
func _wide_of(rid: String) -> bool:
	if run == null or not run.roster.has(rid):
		return false
	var u: Dictionary = run.roster[rid]
	return run.deploys_anywhere(u) or (run.phase == "prepare" and run.unit_def(u).deploy_near_enemies)


## 还没有花名册条目的棋子(商店卡 / 测试场的头像)拖到场上时要不要全场拾取：千变万化(只能站敌人身边)、随心所欲(星级够了)
func _wide_def(def_id: String, star: int) -> bool:
	var d: UnitDef = cat.get_unit(def_id)
	if run == null or d == null or run.phase != "prepare":
		return false
	return d.deploy_near_enemies or (d.deploy_anywhere_star > 0 and star >= d.deploy_anywhere_star)


func _near_enemy_def(d: Dictionary) -> bool:
	match str(d.get("kind", "")):
		"roster":
			return run.roster.has(str(d.get("id", ""))) and run.unit_def(run.roster[str(d["id"])]).deploy_near_enemies
		"shop", "arena_unit":
			var ud: UnitDef = cat.get_unit(str(d.get("def", "")))
			return ud != null and ud.deploy_near_enemies
	return false


## 拖着的东西(仓库卡 / 商店卡 / 测试场头像)放到场上时用不用全场拾取
func _wide_drag(d: Dictionary) -> bool:
	match str(d.get("kind", "")):
		"roster":
			return _wide_of(str(d.get("id", "")))
		"shop":
			return _wide_def(str(d.get("def", "")), 1)
		"arena_unit":
			return _wide_def(str(d.get("def", "")), int(d.get("star", 1)))
	return false


## 千变万化：敌人身边能站的格子标成淡紫
func _mark_near_enemy_cells() -> void:
	for c: Vector2i in run.near_enemy_cells().keys():
		world.stage.highlight_cell(c, Color(0.78, 0.6, 1.0, 0.35))


## 全场部署时：有地形占着的格子标红
func _mark_blocked_cells() -> void:
	var m: BattleMap = run.current_map()
	for cx in range(GC.MAP_W):
		for cy in range(GC.MAP_H):
			var c := Vector2i(cx, cy)
			if m.blocks_move(c) and not m.truck_rect.has_point(c):
				world.stage.highlight_cell(c, Color(1.0, 0.25, 0.2, 0.55))


# =============================================================== 卡车(开局改装 truck_zone / truck_free：备战时能拖动 / 旋转)
var _truck_hinted := false


## 屏幕上这一点是不是指着卡车(射线打到卡车的包围盒)
func _truck_hit(pos: Vector2) -> bool:
	return _truck_hit_t(pos) >= 0.0


## 射线打到卡车包围盒的距离；没打到 = -1(和 _ray_hits_view 比谁更近：卡车挡在前面的棋子点不到，站在车前的棋子优先)
func _truck_hit_t(pos: Vector2) -> float:
	if run == null:
		return -1.0
	var r: Array = _ray(pos)
	var tr: Rect2i = run.truck_layout.truck
	var a: Vector2 = GC.cell_to_world(tr.position.x, tr.position.y) - Vector2(0.5, 0.5) * GC.CELL
	var box := AABB(world.stage.global_position + Vector3(a.x, 0.0, a.y), Vector3(float(tr.size.x) * GC.CELL, 2.8, float(tr.size.y) * GC.CELL))
	var hit: Variant = box.intersects_ray(r[0], r[1])
	return -1.0 if hit == null else (hit as Vector3).distance_to(r[0] as Vector3)


## 拖着卡车：候选位置 = 鼠标指的格子 - 抓住时的格子偏移，夹进初始部署区；卡车和区域着色先按候选摆法画
func _update_truck_drag(pos: Vector2) -> void:
	var pk: Dictionary = _pick_ground(pos, true)
	if not pk.has("point"):
		return
	var gp: Vector3 = pk["point"]
	var want: Vector2i = GC.world_to_cell(Vector2(gp.x, gp.z)) - (drag["grab"] as Vector2i)
	var nl: TruckLayout = run.truck_layout.moved_to(want)
	drag["cell"] = nl.truck.position
	world.stage.show_deploy(true, false, false)
	world.stage.preview_layout(nl)
	world.stage.clear_highlights()
	world.stage.highlight_rect(nl.truck, Color(1.0, 0.85, 0.3, 0.5))
	world.truck.park(Vector3.ZERO, nl.write_into(run.current_layout()))


func _end_truck_drag(d: Dictionary) -> void:
	world.stage.clear_highlights()
	world.stage.show_deploy(false)
	if bool(d["active"]):
		_toast_result(run.move_truck(d["cell"]))
	_after_truck_change()


func _rotate_truck() -> void:
	if state != "prepare" or arena != null or _paused_menu or not drag.is_empty():
		return
	_toast_result(run.rotate_truck())
	_after_truck_change()


## 卡车摆法变了(或拖动取消)：卡车滑到当前摆法、区域着色换、棋子和敌人预览重新对位
func _after_truck_change() -> void:
	world.apply_truck(run.current_layout())
	_sync_prep(false)
	_sync_enemy_preview()
	hud.refresh()


# =============================================================== 鼠标
func _on_pressed(pos: Vector2, button: int) -> void:
	if _paused_menu:
		return
	if button == MOUSE_BUTTON_RIGHT:
		_rmb = true
		return
	if button == MOUSE_BUTTON_MIDDLE:
		_mmb = true
		return
	if button != MOUSE_BUTTON_LEFT:
		return
	_last_pos = pos
	if state == "loot":
		var r: Array = _ray(pos)
		for ov: OrbView in orb_views:
			if is_instance_valid(ov) and ov.hit_by_ray(r[0], r[1]):
				_open_orb(ov)
				return
	if arena != null and state == "prepare" and arena.on_pressed(pos):
		return
	if state == "prepare" or state == "loot":
		var v: UnitView = _pick_view(pos, false)
		# 按在卡车上(卡车能动的改装)：拖动 = 移动卡车(按格子吸附、只能停在初始部署区内)。卡车比身后的棋子近就算按在卡车上
		var tt: float = _truck_hit_t(pos) if state == "prepare" and arena == null and run.truck_can_move() else -1.0
		if tt >= 0.0:
			var near: UnitView = _pick_view(pos, true)
			var ray: Array = _ray(pos)
			if near != null and _ray_hits_view(ray[0], ray[1], near) < tt:
				tt = -1.0
		if tt >= 0.0:
			var gp: Vector3 = _pick_ground(pos, true).get("point", Vector3.ZERO)
			var gc: Vector2i = GC.world_to_cell(Vector2(gp.x, gp.z))
			drag = {"truck": true, "press": pos, "active": false, "grab": gc - run.truck_layout.truck.position, "cell": run.truck_layout.truck.position}
			_select_view(null)
		elif v != null and v.roster_id != "":
			# 先只记下按下的位置：松开时没拖动 = 点击(打开详情)；拖动了 = 移动棋子(不打开详情)
			drag = {"view": v, "id": v.roster_id, "press": pos, "active": false}
		else:
			_select_view(_pick_view(pos, true))
	elif state == "battle":
		_select_view(_pick_view(pos, true))


func _on_released(pos: Vector2, button: int) -> void:
	if button == MOUSE_BUTTON_RIGHT:
		_rmb = false
		return
	if button == MOUSE_BUTTON_MIDDLE:
		_mmb = false
		return
	if button == MOUSE_BUTTON_LEFT and arena != null and arena.on_released(pos):
		return
	if button != MOUSE_BUTTON_LEFT or drag.is_empty():
		return
	var d: Dictionary = drag
	drag = {}
	if d.has("truck"):
		_end_truck_drag(d)
		return
	if is_instance_valid(d["view"]):
		(d["view"] as UnitView).fidget_enabled = true
	world.stage.clear_highlights()
	world.stage.show_deploy(false)
	hud.set_sell_hint(false)
	world.range_ring.visible = false
	if not bool(d["active"]):
		_select(str(d["id"]))
		return
	var v: UnitView = d["view"]
	var id: String = str(d["id"])
	if not run.roster.has(id):
		return
	# 拖到仓库条：收纳到仓库末尾(不限数量)；拖到下方指挥台其它地方：出售；拖到格子：移动/交换
	if hud.cargo_rect().has_point(pos):
		_toast_result(run.move_unit(id, {"bench": run.free_bench_slot()}))
		_sync_prep(false)
		return
	if hud.dock_rect().has_point(pos):
		run.sell(id)
		return
	var pk: Dictionary = _pick_ground(pos, _wide_of(id))
	var res := {"ok": false, "reason": "ui.err.bad_cell"}
	if str(pk.get("type", "")) == "cell":
		res = run.move_unit(id, {"cell": pk["cell"]})
	if not bool(res["ok"]):
		_toast_result(res)
	_sync_prep(false)
	if prep_views.has(id):
		v.position.y = 0.0


func _on_moved(pos: Vector2, rel: Vector2, buttons: int) -> void:
	_last_pos = pos
	if _paused_menu:
		return
	if _rmb and (buttons & MOUSE_BUTTON_MASK_RIGHT) != 0:
		world.rig.orbit(rel.x, rel.y)
		return
	if _mmb and (buttons & MOUSE_BUTTON_MASK_MIDDLE) != 0:
		world.rig.pan(rel.x, rel.y)
		return
	if arena != null and arena.on_moved(pos):
		return
	if not drag.is_empty():
		if not bool(drag["active"]) and pos.distance_to(drag["press"]) > 9.0:
			drag["active"] = true
			_select_view(null)
			if not drag.has("truck"):
				var dv: UnitView = drag["view"]
				dv.fidget_enabled = false       # 拎起来时别跳舞，武器也马上拿回手里
				dv.stop_fidget()
		if bool(drag["active"]):
			if drag.has("truck"):
				_update_truck_drag(pos)
			else:
				_update_drag(pos)
		return
	_update_hover(pos)


func _on_wheel(_pos: Vector2, dir: int) -> void:
	if _paused_menu:
		return
	world.rig.zoom(1.0 + 0.08 * float(dir))


func _update_drag(pos: Vector2) -> void:
	var v: UnitView = drag["view"]
	var wide: bool = _wide_of(str(drag["id"]))
	var pk: Dictionary = _pick_ground(pos, wide)
	world.stage.clear_highlights()
	if wide and run.unit_def(run.roster[str(drag["id"])]).deploy_near_enemies:
		_mark_near_enemy_cells()
	elif wide:
		_mark_blocked_cells()
	if pk.has("point"):
		var pt: Vector3 = pk["point"]
		v.position = Vector3(pt.x, 0.5, pt.z)
	var id: String = str(drag["id"])
	var over_cargo: bool = hud.cargo_rect().has_point(pos)
	var sell_over: bool = hud.dock_rect().has_point(pos) and not over_cargo
	hud.set_sell_hint(sell_over, run.sell_value(run.roster[id]) if sell_over else 0)
	hud.set_cargo_hint(over_cargo)
	world.stage.show_deploy(true, false, wide)
	_show_range_for(v, Vector3(v.position.x, 0, v.position.z))
	if str(pk.get("type", "none")) == "cell":
		var cell: Vector2i = pk["cell"]
		var okc: bool = run.can_deploy_at(run.roster[id], cell)
		_show_range_for(v, world.stage.cell_local(cell))
		world.stage.highlight_cell(cell, Color(0.4, 1.0, 0.55, 0.45) if okc else Color(1.0, 0.35, 0.35, 0.5))


func _update_hover(pos: Vector2) -> void:
	var over_card: bool = hud.card.visible and hud.card.get_global_rect().has_point(pos)
	if over_card:
		return
	var v: UnitView = null
	if not hud.over_ui(pos) and _starfall_tip(pos):
		if hover_view != null and is_instance_valid(hover_view):
			hover_view.set_hovered(false)
		hover_view = null
		_update_range_ring()
		return
	if not hud.over_ui(pos):
		v = _pick_view(pos, true)
	if v != hover_view:
		if hover_view != null and is_instance_valid(hover_view):
			hover_view.set_hovered(false)
		hover_view = v
		if v != null:
			v.set_hovered(true)
	_update_range_ring()
	_update_terrain_tip(pos if v == null and not hud.over_ui(pos) else Vector2(-1, -1))


## 悬停战场上的地形(燃烧废墟 / 余烬地块 / 死灰废墟)：小卡片说明它的效果
var _tip_map: BattleMap = null
var _tip_map_key: String = ""


## 星旅节点的预计落点：指着落点上方的星形图标(或地上的标记)时显示落点范围 + 说明；返回是不是指着它
func _starfall_tip(pos: Vector2) -> bool:
	var on_icon := false
	if state == "prepare" and not world.stage.starfall_info.is_empty():
		on_icon = world.rig.project(world.stage.starfall_icon_pos()).distance_to(pos) <= 34.0
		if not on_icon:
			var sh: Dictionary = _pick_ground(pos)
			on_icon = sh.has("point") and world.stage.starfall_hit(sh["point"])
	world.stage.set_starfall_hover(on_icon)
	if not on_icon:
		return false
	var info: Dictionary = world.stage.starfall_info
	var inside := 0
	for ev: UnitView in enemy_views:
		if Vector2(ev.position.x, ev.position.z).distance_to(info["pos"]) <= float(info["radius"]) + 0.42:
			inside += 1
	var sv := UIKit.vbox(6)
	sv.custom_minimum_size = Vector2(320, 0)
	sv.add_child(UIKit.label(Loc.t("ui.starfall.title"), 17, UIKit.TEXT, true))
	sv.add_child(UIKit.caption(Loc.t_in("en", "ui.starfall.title"), 10, UIKit.ACCENT))
	sv.add_child(UIKit.rich("[color=%s]%s[/color]" % [UIKit.hx(UIKit.TEXT_SOFT), Loc.t("ui.starfall.desc", [inside])], 13, 320))
	hud.show_tip(sv, world.battlefield)
	return true


func _update_terrain_tip(pos: Vector2) -> void:
	var kind := ""
	if pos.x >= 0.0 and (state == "prepare" or state == "battle" or state == "loot") and run != null and run.is_grid():
		var m: BattleMap = null
		if state == "battle" and world.battle_view.battle != null:
			m = world.battle_view.battle.map
		else:
			var lk: String = str(run.current_layout().get("seed", "")) + run.pos
			if lk != _tip_map_key:
				_tip_map_key = lk
				_tip_map = run.current_map()
			m = _tip_map
		var hit: Dictionary = _pick_ground(pos)
		if m != null and hit.has("point"):
			var lp: Vector3 = hit["point"]
			var c: Vector2i = GC.world_to_cell(Vector2(lp.x, lp.z))
			var purple: bool = str(run.current_layout().get("theme", "")) == "purple"
			for o: Dictionary in m.obstacles:
				if (o["rect"] as Rect2i).has_point(c):
					kind = "burning" if str(o.get("terrain", "")) == "burning" else ("ice" if purple else "ash")
			for e: Dictionary in m.embers:
				if bool(e["lit"]) and (e["rect"] as Rect2i).has_point(c):
					kind = "ember"
			for f: Dictionary in m.frost:
				if (f["rect"] as Rect2i).has_point(c):
					kind = "frost"
	if kind == "":
		if hud._tip_owner == world.battlefield:
			hud.hide_tip()
		return
	var tv := UIKit.vbox(6)
	tv.custom_minimum_size = Vector2(300, 0)
	tv.add_child(UIKit.label(Loc.t("ui.terrain.%s" % kind), 17, UIKit.TEXT, true))
	tv.add_child(UIKit.caption(Loc.t_in("en", "ui.terrain.%s" % kind), 10, UIKit.ACCENT))
	tv.add_child(UIKit.rich("[color=%s]%s[/color]" % [UIKit.hx(UIKit.TEXT_SOFT), Loc.t("ui.terrain.%s.desc" % kind)], 13, 300))
	if kind == "burning" or kind == "ember":
		tv.add_child(UIKit.rich("[color=%s]%s[/color]" % [UIKit.hx(UIKit.GOLD), Loc.t("ui.burning_hint")], 12, 300))
	elif kind == "frost":
		tv.add_child(UIKit.rich("[color=%s]%s[/color]" % [UIKit.hx(UIKit.GOLD), Loc.t("ui.chill_hint")], 12, 300))
	hud.show_tip(tv, world.battlefield)


func _select(id: String) -> void:
	selected_id = id
	selected_storage = ""
	selected_view = prep_views.get(id, null)
	for rid: String in prep_views.keys():
		(prep_views[rid] as UnitView).set_selected(rid == id)
	_refresh_card()


## 点击选中任意单位(敌人预览、战斗中的单位)；null = 取消选中
func _select_view(v: UnitView) -> void:
	if v != null and v.roster_id != "" and prep_views.get(v.roster_id, null) == v:
		_select(v.roster_id)
		return
	selected_id = ""
	selected_storage = ""
	selected_view = v
	for rid: String in prep_views.keys():
		(prep_views[rid] as UnitView).set_selected(false)
	_refresh_card()


## 点击仓库里的节点：详情卡片出现在那张仓库卡旁边
func _select_storage(roster_id: String) -> void:
	if state != "prepare" and state != "loot":
		return
	_select_view(null)
	selected_storage = roster_id
	_refresh_card()


func _selected() -> UnitView:
	if selected_view != null and is_instance_valid(selected_view) and not selected_view.dying:
		return selected_view
	if selected_id != "" and prep_views.has(selected_id):
		return prep_views[selected_id]
	return null


# =============================================================== 攻击范围环(QoL)
## 某个视图(棋子)当前武器下的出手距离
func _reach_of_view(v: UnitView, weapon: EquipmentDef = null) -> float:
	if v.bu != null and weapon == null:
		return RangeRing.reach_of(v.bu.get_stats()) if v.bu.can_attack() else 0.0
	var bu := BUnit.new()
	bu.setup(v.def, v.star, v.team, "range")
	bu.set_weapon(weapon if weapon != null else v.weapon)
	if v.roster_id != "" and run != null and run.roster.has(v.roster_id):
		bu.perm_flat = (run.roster[v.roster_id]["perm"] as Dictionary).duplicate()
	bu.recompute()
	return RangeRing.reach_of(bu.get_stats()) if bu.can_attack() else 0.0


func _ring_color(v: UnitView) -> Color:
	return Color(0.35, 0.78, 1.0, 0.85) if v.team == GC.TEAM_PLAYER else Color(1.0, 0.45, 0.40, 0.85)


func _show_range_for(v: UnitView, at: Vector3) -> void:
	var r: float = _reach_of_view(v)
	if r <= 0.0:
		world.range_ring.visible = false
		return
	world.range_ring.show_at(at, r, _ring_color(v))


## 悬停(或选中)的棋子显示攻击范围；战斗中跟随棋子移动(战斗坐标)
func _update_range_ring() -> void:
	if state != "prepare" and state != "battle" and state != "loot":
		world.range_ring.visible = false
		return
	if not drag.is_empty() and bool(drag.get("active", false)):
		return
	var v: UnitView = hover_view if hover_view != null and is_instance_valid(hover_view) else _selected()
	if v == null or not is_instance_valid(v) or v.dying:
		world.range_ring.visible = false
		return
	_show_range_for(v, v.position)


# =============================================================== 单位卡
func _refresh_card() -> void:
	if state == "title" or state == "result" or state == "over" or state == "map" or state == "travel":
		hud.hide_card()
		return
	# 详情卡片只跟着"点击选中"的单位走；鼠标只是指着棋子不会打开/替换它
	if selected_storage != "":
		if not run.roster.has(selected_storage):
			selected_storage = ""
		elif run.roster[selected_storage]["cell"] != null and prep_views.has(selected_storage):
			# 已经从仓库上场：卡片改为跟着场上的棋子
			var rid: String = selected_storage
			_select(rid)
			return
		else:
			var su: Dictionary = run.roster[selected_storage]
			var sc: Control = TipContent.unit_card(cat, run.unit_def(su), int(su["star"]), str(su["weapon"]), null, GC.TEAM_PLAYER, su["perm"])
			_add_card_actions(sc, selected_storage)
			var r: Rect2 = hud.storage_card_rect(selected_storage)
			card_target = {"storage": selected_storage}
			hud.show_card(sc, r.get_center() - Vector2(0, 60) if r.size.x > 0.0 else hud.get_viewport_rect().size * 0.5)
			return
	var v: UnitView = _selected()
	if v == null or not is_instance_valid(v) or v.dying:
		hud.hide_card()
		card_target = {}
		return
	card_target = {"view": v}
	var content: Control
	var editable := false
	if state == "battle" and v.bu != null:
		content = TipContent.unit_card(cat, v.def, v.star, "", v.bu, v.team)
	elif v.roster_id != "" and run.roster.has(v.roster_id):
		var u: Dictionary = run.roster[v.roster_id]
		content = TipContent.unit_card(cat, v.def, int(u["star"]), str(u["weapon"]), null, GC.TEAM_PLAYER, u["perm"])
		editable = state == "prepare" or state == "loot"
	else:
		content = TipContent.unit_card(cat, v.def, v.star, str(v.get_meta("weapon", "")), null, GC.TEAM_ENEMY)
	if editable:
		_add_card_actions(content, v.roster_id)
	hud.show_card(content, world.rig.project(v.global_position + Vector3(0, v.body_height * 0.6, 0)))


## 我方节点的详情卡：武器格可点击卸下 + 出售按钮
func _add_card_actions(content: Control, rid: String) -> void:
	_wire_card_slots(content, rid)
	if arena != null:                                   # 测试场：没有出售，只有移除
		var rm := UIKit.button(Loc.t("ui.arena_remove"), "danger", Vector2(0, 34))
		rm.pressed.connect(func() -> void: arena.remove_unit(rid))
		content.add_child(rm)
		return
	var sell := UIKit.button(Loc.t("ui.sell_for", [run.sell_value(run.roster[rid])]), "danger", Vector2(0, 34))
	sell.pressed.connect(func() -> void:
		run.sell(rid))
	content.add_child(sell)
	content.add_child(UIKit.rich("[color=#6d7588]%s[/color]" % Loc.t("ui.card.hint_edit"), 11, 360))


func _wire_card_slots(content: Control, roster_id: String) -> void:
	for n: Node in content.find_children("*", "PanelContainer", true, false):
		if not n.has_meta("slot"):
			continue
		var pc: PanelContainer = n as PanelContainer
		if pc.has_meta("equip_id"):
			var eid: String = str(pc.get_meta("equip_id"))
			pc.mouse_filter = Control.MOUSE_FILTER_STOP
			pc.mouse_default_cursor_shape = Control.CURSOR_DRAG
			pc.mouse_entered.connect(func() -> void: hud.show_tip(hud.with_hint(TipContent.equipment_tip(cat, eid), "ui.tip.drag_weapon"), pc))
			pc.mouse_exited.connect(func() -> void: hud.hide_tip())
			# 左键点一下：固定这件武器的详情；按住拖：拖到别的棋子身上换人带 / 拖回指挥台(武器库)卸下；右键：卸下(换回基础武器)
			var press := {"at": Vector2(-1, -1)}
			pc.gui_input.connect(func(ev: InputEvent) -> void:
				var mb := ev as InputEventMouseButton
				if mb == null:
					return
				if mb.button_index == MOUSE_BUTTON_LEFT:
					if mb.pressed:
						press["at"] = mb.position
					elif (press["at"] as Vector2).x >= 0.0 and mb.position.distance_to(press["at"]) < 6.0:
						press["at"] = Vector2(-1, -1)
						hud.toggle_pin(TipContent.equipment_tip(cat, eid), pc)
				elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
					hud.hide_tip(true)
					run.unequip(roster_id))
			pc.set_drag_forwarding(func(_at: Vector2) -> Variant:
				if state != "prepare" and state != "loot":
					return null
				press["at"] = Vector2(-1, -1)
				hud.hide_tip(true)
				pc.set_drag_preview(ItemTile.drag_preview(cat, eid))
				return {"kind": "equip", "id": eid, "from": roster_id}, Callable(), Callable())


func _process(dt: float) -> void:
	# 卡片跟随单位
	if hud != null and hud.card.visible and card_target.has("view"):
		if not is_instance_valid(card_target["view"]) or (card_target["view"] as UnitView).dying:
			# 选中的单位阵亡/被移除：卡片跟着关掉
			card_target = {}
			selected_view = null
			hud.hide_card()
		else:
			var v: UnitView = card_target["view"]
			var sp: Vector2 = world.rig.project(v.global_position + Vector3(0, v.body_height * 0.6, 0))
			var vp: Vector2 = hud.get_viewport_rect().size
			var pos := Vector2(sp.x + 60.0, sp.y - hud.card.size.y * 0.5)
			if pos.x + hud.card.size.x > vp.x - 10:
				pos.x = sp.x - hud.card.size.x - 60.0
			pos.y = clampf(pos.y, 76.0, vp.y - hud.card.size.y - (300.0 if state == "prepare" else 16.0))
			pos.x = clampf(pos.x, 10.0, vp.x - hud.card.size.x - 10.0)
			hud.card.position = hud.card.position.lerp(pos, clampf(dt * 14.0, 0.0, 1.0))
	if state == "travel" and world.overworld.visible:
		# 镜头跟着卡车，慢慢压低、拉近(方格网章节从高空俯冲下来，拉得更近)
		if run != null and run.is_grid():
			world.rig.set_view(world.truck.position + Vector3(0, 0.5, 1.5), 0.0, 40.0, 26.0)
		else:
			world.rig.set_view(world.truck.position + Vector3(0, 0.5, 1.5), 0.0, 48.0, 30.0)
	if state == "map":
		_place_map_buttons()
	if state == "prepare" and (not selfless_btns.is_empty() or not form_btns.is_empty()):
		_place_selfless_buttons()
	# WASD：像中键拖动一样平移镜头
	if not _paused_menu and state != "boot" and state != "title" and state != "travel":
		var ax := 0.0
		var ay := 0.0
		if Input.is_physical_key_pressed(KEY_A):
			ax += 1.0
		if Input.is_physical_key_pressed(KEY_D):
			ax -= 1.0
		if Input.is_physical_key_pressed(KEY_W):
			ay += 1.0
		if Input.is_physical_key_pressed(KEY_S):
			ay -= 1.0
		if ax != 0.0 or ay != 0.0:
			world.rig.pan(ax * 340.0 * dt, ay * 340.0 * dt)
	if state == "battle" and world.battle_view.battle != null:
		var b: Battle = world.battle_view.battle
		if not b.hazards.is_empty():
			hud.update_hazards(b.hazard_info())
		_count_timer += dt
		if _count_timer > 0.2:
			_count_timer = 0.0
			var pa := 0
			var pt := 0
			var ea := 0
			var et := 0
			for u: BUnit in b.units:
				if u.team == GC.TEAM_PLAYER:
					pt += 1
					pa += 1 if u.alive else 0
				else:
					et += 1
					ea += 1 if u.alive else 0
			hud.set_battle_counts(pa, pt, ea, et, maxf(0.0, b.time - GC.START_DELAY))
		if hud.card.visible and card_target.has("view") and Engine.get_process_frames() % 20 == 0:
			_refresh_card()
		if (hover_view != null and is_instance_valid(hover_view)) or selected_view != null:
			_update_range_ring()
		# 悬停棋子：画出它当前锁定的目标
		var hv: UnitView = hover_view if hover_view != null and is_instance_valid(hover_view) else null
		var tgt: BUnit = hv.bu.target if hv != null and hv.bu != null and hv.bu.alive else null
		if tgt != null and tgt.alive:
			var tv: UnitView = world.battle_view.views.get(tgt.uid, null)
			world.show_target_line(hv.position, tv.position if tv != null else Vector3(tgt.pos.x, 0, tgt.pos.y), _ring_color(hv), true)
		else:
			world.show_target_line(Vector3.ZERO, Vector3.ZERO, Color.WHITE, false)


# =============================================================== 拖放(商店卡 / 武器 / 仓库里的节点 → 3D 场地)
func _can_drop(pos: Vector2, data: Variant) -> bool:
	if (state != "prepare" and state != "loot") or not (data is Dictionary):
		return false
	if arena != null and arena.busy != "":
		return false
	var d: Dictionary = data
	match str(d.get("kind", "")):
		"arena_unit":
			return arena != null and str(_pick_ground(pos, _wide_drag(d)).get("type", "")) == "cell"
		"arena_monster":
			var pkm: Dictionary = _pick_ground(pos)
			return arena != null and pkm.has("point") and arena.valid_enemy_cell(GC.world_to_cell(Vector2((pkm["point"] as Vector3).x, (pkm["point"] as Vector3).z)))
		"shop", "roster":
			# 千变万化 / 随心所欲的棋子：部署区以外的格子也收(能不能站交给 Run.move_unit 判断)
			var pk: Dictionary = _pick_ground(pos, _wide_drag(d))
			return str(pk.get("type", "")) == "cell"
		"equip":
			# 特殊物品(狩猎旗标)：放到敌人预览身上(不检查这个的话 Godot 根本不会把旗标交给 _on_dropped)
			var tk: EquipmentDef = cat.get_equipment(str(d.get("id", "")))
			if tk != null and tk.slot == "token":
				return state == "prepare" and enemy_views.has(_pick_view(pos, true))
			var v: UnitView = _pick_view(pos, false)
			return v != null and v.roster_id != ""
	return false


func _on_drop_hover(pos: Vector2, data: Variant) -> void:
	if (state != "prepare" and state != "loot") or not (data is Dictionary):
		return
	world.stage.clear_highlights()
	var d: Dictionary = data
	match str(d.get("kind", "")):
		"arena_unit":
			var wa: bool = _wide_drag(d)
			var pka: Dictionary = _pick_ground(pos, wa)
			world.stage.show_deploy(true, false, wa)
			if _near_enemy_def(d):
				_mark_near_enemy_cells()
			elif wa:
				_mark_blocked_cells()
			if str(pka.get("type", "")) == "cell":
				var oka: bool = not _near_enemy_def(d) or run.near_enemy_cells().has(pka["cell"])
				world.stage.highlight_cell(pka["cell"], Color(0.4, 1.0, 0.55, 0.45) if oka else Color(1.0, 0.35, 0.35, 0.45))
		"arena_monster":
			var pkm: Dictionary = _pick_ground(pos)
			if pkm.has("point") and arena != null:
				var mc: Vector2i = GC.world_to_cell(Vector2((pkm["point"] as Vector3).x, (pkm["point"] as Vector3).z))
				world.stage.highlight_cell(mc, Color(0.4, 1.0, 0.55, 0.45) if arena.valid_enemy_cell(mc) else Color(1.0, 0.35, 0.35, 0.45))
		"shop", "roster":
			var wide_r: bool = _wide_drag(d)
			var pk: Dictionary = _pick_ground(pos, wide_r)
			world.stage.show_deploy(true, false, wide_r)
			if _near_enemy_def(d):
				_mark_near_enemy_cells()
			elif wide_r:
				_mark_blocked_cells()
			if str(pk.get("type", "")) == "cell":
				var cell: Vector2i = pk["cell"]
				var moving_bench: bool = str(d.get("kind", "")) == "roster"
				var free_u: bool = moving_bench and run.roster.has(str(d["id"])) and run.unit_def(run.roster[str(d["id"])]).free_deploy
				var ok: bool = free_u or not run.unit_at_cell(cell).is_empty() or run.board_count() < run.board_capacity()
				world.stage.highlight_cell(cell, Color(0.4, 1.0, 0.55, 0.45) if ok else Color(1.0, 0.35, 0.35, 0.45))
				if moving_bench and run.roster.has(str(d["id"])):
					var u: Dictionary = run.roster[str(d["id"])]
					var tmp := UnitView.new()
					tmp.def = run.unit_def(u)
					tmp.star = int(u["star"])
					tmp.team = GC.TEAM_PLAYER
					tmp.weapon = run.weapon_of(u)
					world.range_ring.show_at(world.stage.cell_local(cell), _reach_of_view(tmp), _ring_color(tmp))
					tmp.free()
		"equip":
			hud.hide_card()
			# 特殊物品(狩猎旗标)：拖到敌人预览身上
			var tk: EquipmentDef = cat.get_equipment(str(d["id"]))
			if tk != null and tk.slot == "token":
				var ev: UnitView = _pick_view(pos, true)
				for v3: UnitView in enemy_views:
					v3.set_hovered(v3 == ev)
				if ev != null and enemy_views.has(ev):
					hud.show_tip(TipContent.equipment_tip(cat, str(d["id"])), null)
				else:
					hud.hide_tip()
				return
			var v: UnitView = _pick_view(pos, false)
			for rid: String in prep_views.keys():
				(prep_views[rid] as UnitView).set_hovered(prep_views[rid] == v)
			if v != null:
				var chk: Dictionary = run.equip_check(v.roster_id, str(d["id"]))
				var e: EquipmentDef = cat.get_equipment(str(d["id"]))
				hud.show_tip(TipContent.equipment_tip(cat, str(d["id"]), v.def), null)
				var hv: MeshInstance3D = v.hover_ring
				(hv.material_override as StandardMaterial3D).albedo_color = Color("#7dff9a") if bool(chk["ok"]) else Color("#ff6a6a")
				# 当前射程(实线) + 换上这把武器后的射程(虚线)
				_show_range_for(v, v.position)
				if bool(chk["ok"]):
					world.range_ghost.show_at(v.position, _reach_of_view(v, e), Color(0.55, 1.0, 0.62, 0.95), true)
				else:
					world.range_ghost.visible = false
			else:
				hud.hide_tip()
				world.range_ring.visible = false
				world.range_ghost.visible = false


func _on_dropped(pos: Vector2, data: Variant) -> void:
	_clear_drop_feedback()
	if (state != "prepare" and state != "loot") or not (data is Dictionary):
		return
	var d: Dictionary = data
	match str(d.get("kind", "")):
		"arena_unit":
			var pka: Dictionary = _pick_ground(pos, _wide_drag(d))
			if arena != null and str(pka.get("type", "")) == "cell":
				arena.add_unit(str(d["def"]), int(d["star"]), pka["cell"])
		"arena_monster":
			var pkm: Dictionary = _pick_ground(pos)
			if arena != null and pkm.has("point"):
				var mc: Vector2i = GC.world_to_cell(Vector2((pkm["point"] as Vector3).x, (pkm["point"] as Vector3).z))
				if arena.valid_enemy_cell(mc):
					arena.add_monster(str(d["def"]), int(d["star"]), GC.cell_to_world(mc.x, mc.y))
		"shop":
			var pk: Dictionary = _pick_ground(pos, _wide_drag(d))
			var res: Dictionary = run.buy(int(d["index"]))
			if not bool(res["ok"]):
				_toast_result(res)
				return
			var nid: String = _newest_roster_id()
			if nid != "" and run.roster.has(nid) and str(pk.get("type", "")) == "cell":
				_toast_result(run.move_unit(nid, {"cell": pk["cell"]}))
		"roster":
			var pk2: Dictionary = _pick_ground(pos, _wide_of(str(d.get("id", ""))))
			if str(pk2.get("type", "")) == "cell":
				_toast_result(run.move_unit(str(d["id"]), {"cell": pk2["cell"]}))
		"equip":
			var tk2: EquipmentDef = cat.get_equipment(str(d["id"]))
			if tk2 != null and tk2.slot == "token":
				var ev2: UnitView = _pick_view(pos, true)
				if ev2 == null or not enemy_views.has(ev2):
					hud.toast_msg(Loc.t("ui.err.flag_on_enemy"))
					return
				var mres: Dictionary = run.set_hunt_mark(enemy_views.find(ev2))
				_toast_result(mres)
				if bool(mres["ok"]):
					world.battle_view.fx.ring(ev2.position, 1.2, Color("#ff4a3a"), 0.5, 1.6)
					world.battle_view.fx.burst(ev2.position + Vector3(0, 1.6, 0), Color("#ff6a4a"), 12, 2.4, 0.9)
				return
			var v: UnitView = _pick_view(pos, false)
			if v == null:
				hud.toast_msg(Loc.t("ui.err.bad_target"))
				return
			var res2: Dictionary
			if d.has("from"):
				if str(d["from"]) == v.roster_id:
					return
				res2 = run.move_weapon(str(d["from"]), v.roster_id)
			else:
				res2 = run.equip(v.roster_id, str(d["id"]))
			_toast_result(res2)
			if bool(res2["ok"]):
				world.battle_view.fx.ring(v.position, 1.1, UIKit.GOLD, 0.5)
				world.battle_view.fx.burst(v.position + Vector3(0, 0.9, 0), UIKit.GOLD, 14, 2.6, 1.0)


## 仓库卡上的放置：仓库里的节点 → 调整顺序(拖到末尾的收纳位 = 排到最后)；武器 → 装备给这个节点；招募卡 → 购买
func _on_cargo_dropped(slot: int, data: Dictionary) -> void:
	if run == null:
		return
	match str(data.get("kind", "")):
		"roster":
			_toast_result(run.move_unit(str(data["id"]), {"bench": slot}))
		"equip":
			var u: Dictionary = run.unit_at_bench(slot)
			if u.is_empty():
				hud.toast_msg(Loc.t("ui.err.bad_target"))
			elif data.has("from"):
				if str(data["from"]) != str(u["id"]):
					_toast_result(run.move_weapon(str(data["from"]), str(u["id"])))
			else:
				_toast_result(run.equip(str(u["id"]), str(data["id"])))
		"shop":
			_toast_result(run.buy(int(data["index"])))


## 仓库里的节点拖到下方指挥台：出售
func _on_dock_dropped(data: Dictionary) -> void:
	if run != null and str(data.get("kind", "")) == "roster":
		_toast_result(run.sell(str(data["id"])))
	elif run != null and str(data.get("kind", "")) == "equip" and data.has("from"):
		_toast_result(run.unequip(str(data["from"])))


func _clear_drop_feedback() -> void:
	world.stage.clear_highlights()
	world.stage.show_deploy(false)
	world.range_ghost.visible = false
	world.range_ring.visible = false
	hud.hide_tip()
	for rid: String in prep_views.keys():
		var pv: UnitView = prep_views[rid]
		pv.set_hovered(false)
		(pv.hover_ring.material_override as StandardMaterial3D).albedo_color = Color("#ffe27a")
	for ev3: UnitView in enemy_views:
		if is_instance_valid(ev3):
			ev3.set_hovered(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if world != null:
			_clear_drop_feedback()


# =============================================================== 战斗
func _start_battle() -> void:
	if state != "prepare":
		return
	if arena != null:
		arena.start()
		return
	var chk: Dictionary = run.can_start_battle()
	if not bool(chk["ok"]):
		_toast_result(chk)
		return
	var setup: Dictionary = run.build_battle_setup()
	run.begin_battle()
	_launch_battle(setup, int(Time.get_ticks_usec() % 100000) + run.node_index * 7919)


## 开始播放一场战斗(正式战斗 / 测试场的单场战斗)
func _launch_battle(setup: Dictionary, seed_value: int) -> void:
	_clear_selfless_buttons()
	_clear_drop_feedback()
	drag = {}
	hover_view = null
	selected_id = ""
	selected_view = null
	hud.hide_card()
	state = "battle"
	for id: String in prep_views.keys():
		(prep_views[id] as UnitView).visible = false
	for v: UnitView in enemy_views:
		v.visible = false
	var defs: Array = []
	for u: Dictionary in setup["units"]:
		if int(u["team"]) == GC.TEAM_PLAYER:
			defs.append(cat.get_unit(str(u["def"])).form_def(str(u.get("form", ""))))
	hud.battle_defs = defs
	hud.set_mode("battle")
	hud.clear_feed()
	hud.set_speed_active(battle_speed)
	hud.set_paused_ui(false)
	world.rig.set_preset("battle")
	world.stage.set_threats({})
	world.stage.set_starfall({})
	world.stage.show_deploy(false, true)
	_clear_marks()
	_clear_orbs()
	_battle_time = 0.0
	world.battle_view.speed = battle_speed
	world.battle_view.start(setup, cat, seed_value)


## 战斗倍速(会被记住，下一场沿用)：战斗中立刻生效；备战时先选好，开战时生效
func _set_speed(sp: float) -> void:
	battle_speed = sp
	if state == "battle":
		world.battle_view.set_speed(sp)
	hud.set_speed_active(sp)


## 数字键 1~5 = ×0.25 / ×0.5 / ×1 / ×2 / ×4(战斗中、备战 / 拾取时都能按)
func _speed_key(i: int) -> bool:
	if (state == "battle" or state == "prepare" or state == "loot") and not _paused_menu and i < HUD.SPEEDS.size():
		_set_speed(HUD.SPEEDS[i])
		return true
	return false


func _toggle_battle_pause() -> void:
	if state != "battle":
		return
	var p: bool = not world.battle_view.paused
	world.battle_view.set_paused(p)
	hud.set_paused_ui(p)


## 大招切入：技能名取单位被动说明里 [b]…[/b] 的那一段(当前语言 + 英文)
func _on_ultimate(u: BUnit, ability_id: String, color: Color) -> void:
	var key: String = "unit.%s.passive.%s" % [u.def.id, ability_id]
	hud.show_cutin(u.def.id, _bold_name(Loc.t(key)), _bold_name(Loc.t_in("en", key)), color, u.team != GC.TEAM_PLAYER)


static func _bold_name(text: String) -> String:
	var i: int = text.find("[b]")
	var j: int = text.find("[/b]")
	return text.substr(i + 3, j - i - 3) if i >= 0 and j > i else text


func _on_banner(key: String) -> void:
	hud.show_banner(Loc.t(key), UIKit.TEXT if key != "ui.raid" else UIKit.BAD)


func _on_orb_dropped(tier: String, pos: Vector2) -> void:
	var ov := OrbView.new()
	world.stage.orbs_layer.add_child(ov)
	ov.position = Vector3(pos.x, 0.0, pos.y)
	ov.setup(tier, -1)
	orb_views.append(ov)


func _clear_orbs() -> void:
	for ov: OrbView in orb_views:
		if is_instance_valid(ov):
			ov.queue_free()
	orb_views.clear()


func _on_battle_ended(_winner: int) -> void:
	if state != "battle":
		return
	world.show_target_line(Vector3.ZERO, Vector3.ZERO, Color.WHITE, false)
	world.range_ring.visible = false
	hover_view = null
	selected_view = null
	var b: Battle = world.battle_view.battle
	if arena != null:
		arena.on_visual_battle_ended(b)
		return
	_show_battle_result(b, run.finish_battle(b))


## 结算面板(正式战斗 / 测试场)
func _show_battle_result(b: Battle, res: Dictionary) -> void:
	_last_summary = b.summary()
	_last_report = b.report
	_battle_time = maxf(0.0, b.end_time - GC.START_DELAY)
	state = "result"
	hud.set_mode("result")
	hud.hide_card()
	screens.show_result(res, _last_summary, run, _battle_time, _last_report)


## 结算面板之后：卡车损毁 → 结束；否则进入拾取战利品
func _after_result() -> void:
	if arena != null:
		arena.back_to_board()
		return
	screens.hide_all()
	if run.phase == "over":
		_show_gameover()
		return
	world.battle_view.clear()
	state = "loot"
	_clear_orbs()
	# 晶球：按 Run.pending_orbs 重新摆好(下标对应)，战斗里掉落时的视图位置相同
	for i in range(run.pending_orbs.size()):
		var o: Dictionary = run.pending_orbs[i]
		var ov := OrbView.new()
		world.stage.orbs_layer.add_child(ov)
		var p: Vector2 = o["pos"]
		ov.position = Vector3(p.x, 0.0, p.y)
		ov.setup(str(o["tier"]), i)
		orb_views.append(ov)
	for id: String in prep_views.keys():
		(prep_views[id] as UnitView).visible = true
	hud.set_mode("loot")
	world.rig.set_preset("prep")
	_sync_prep(false)


func _open_orb(ov: OrbView) -> void:
	if ov.opened or ov.index < 0:
		return
	var loot: Dictionary = run.open_orb(ov.index)
	ov.burst()
	var col: Color = OrbView.COLORS.get(ov.tier, Color.WHITE)
	world.battle_view.fx.burst(ov.position + Vector3(0, 0.5, 0), col, 26, 3.4, 1.2, 1.0, 0.9)
	world.battle_view.fx.ring(Vector3(ov.position.x, 0, ov.position.z), 1.3, col, 0.5)
	hud.show_loot(loot)


## 离开战场：剩下的晶球自动打开，然后回到地图(或章节结束)
func _continue_after_loot() -> void:
	if state != "loot":
		return
	for ov: OrbView in orb_views:
		if is_instance_valid(ov) and not ov.opened and ov.index >= 0:
			_open_orb(ov)
	run.finish_loot()
	_clear_orbs()
	if run.phase == "over":
		_show_gameover()
		return
	if run.phase == "branch" or run.phase == "chapter_end":
		_show_chapter_end()
		return
	if run.phase == "prepare":
		# 方格网章节：行动力用完 → 追猎；追猎打输了 → 再打一场
		world.battle_view.clear()
		await _goto_battlefield(false)
		return
	# 回到大地图(白色淡入淡出)
	state = "travel"
	hud.set_mode("travel")
	await _fade(1.0, 0.3)
	_enter_map(true)
	await _fade(0.0, 0.45)


func _show_gameover() -> void:
	state = "over"
	hud.clear_loot()
	hud.set_mode("none")
	hud.hide_card()
	screens.show_gameover(run.won_run, run)


func _on_feed(e: Dictionary) -> void:
	hud.add_feed(FeedFormat.format(cat, e))


# =============================================================== 棋子高亮(QoL)
## 悬停背包里的武器：能装备的棋子亮绿圈，不能装备的亮暗红圈(仓库里的在界面里标)
func _mark_for_item(id: String) -> void:
	if state != "prepare" and state != "loot":
		return
	for rid: String in prep_views.keys():
		var ok: bool = bool(run.equip_check(rid, id)["ok"])
		(prep_views[rid] as UnitView).set_mark(Color(0.45, 1.0, 0.6, 0.95) if ok else Color(1.0, 0.35, 0.35, 0.45))
	hud.mark_cargo(func(u: Dictionary) -> Color:
		return Color(0.45, 1.0, 0.6, 0.95) if bool(run.equip_check(str(u["id"]), id)["ok"]) else Color(1.0, 0.35, 0.35, 0.45))


## 悬停商店卡：已拥有的同名棋子亮金圈(凑三合星)
func _mark_copies(def_id: String) -> void:
	if state != "prepare" and state != "loot":
		return
	for rid: String in prep_views.keys():
		var v: UnitView = prep_views[rid]
		if v.def.id == def_id:
			v.set_mark(UIKit.GOLD)
	hud.mark_cargo(func(u: Dictionary) -> Color: return UIKit.GOLD if str(u["def"]) == def_id else Color(0, 0, 0, 0))


## 悬停羁绊：场上贡献该羁绊的棋子亮阵营色圈
func _mark_trait(tid: String) -> void:
	var t: TraitDef = cat.get_trait(tid)
	if t == null or (state != "prepare" and state != "loot"):
		return
	for rid: String in prep_views.keys():
		var v: UnitView = prep_views[rid]
		if GC.faction_contributions(v.def.faction_id).has(t.member_filter):
			v.set_mark(GC.faction_color(t.member_filter).lightened(0.2))


func _clear_marks() -> void:
	for rid: String in prep_views.keys():
		(prep_views[rid] as UnitView).clear_mark()
	if hud != null:
		hud.mark_cargo(Callable())


# =============================================================== 菜单 / 语言 / 快捷键
func _open_pause() -> void:
	if state == "title" or state == "boot" or _paused_menu:
		return
	_paused_menu = true
	if state == "battle":
		world.battle_view.set_paused(true)
	screens.show_pause()


func _close_pause() -> void:
	if not _paused_menu:
		return
	_paused_menu = false
	screens.hide_all()
	if state == "battle":
		world.battle_view.set_paused(false)
		hud.set_paused_ui(false)
	elif state == "result":
		screens.show_result(run.last_result, _last_summary, run, _battle_time, _last_report)


func _toggle_lang() -> void:
	Loc.toggle()
	for v: Node in get_tree().get_nodes_in_group("unit_views"):
		(v as UnitView).refresh_name()
	var cur: String = screens.current
	hud.set_mode(hud.mode)
	if arena != null:
		arena.rebuild_panel()
	_refresh_card()
	match cur:
		"title":
			screens.show_title()
		"mod":
			screens.show_mod_pick(run, state == "start_mod")
		"pause":
			screens.show_pause()
		"result":
			screens.show_result(run.last_result, _last_summary, run, _battle_time, _last_report)
		"gameover":
			screens.show_gameover(run.won_run, run)


## 图鉴：盖在所有界面上面(标题 / 暂停菜单还在下面)，关掉就回到原来的界面
func open_codex() -> void:
	if codex != null:
		return
	codex = Codex.new()
	codex.setup(cat)
	codex.closed.connect(func() -> void: codex = null)
	ui_layer.add_child(codex)


## 车间：盖在大地图 / 备战界面上；关掉时 HUD 刷新(材料、武器库)
func open_workshop() -> void:
	if workshop != null or _paused_menu or not (state == "map" or state == "prepare" or state == "loot"):
		return
	hud.hide_tip(true)
	hud.hide_card()
	workshop = WorkshopScreen.new()
	workshop.setup(cat, run)
	workshop.closed.connect(func() -> void:
		workshop = null
		hud.refresh())
	ui_layer.add_child(workshop)


func close_workshop() -> void:
	if workshop != null:
		workshop.close_screen()


func _input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	var k: InputEventKey = ev
	if state == "boot" or codex != null:
		return
	if workshop != null:
		match k.keycode:
			KEY_ESCAPE:
				if workshop._result != null:
					workshop.close_result()
				else:
					close_workshop()
			KEY_SPACE:
				workshop.press_primary()
		get_viewport().set_input_as_handled()
		return
	match k.keycode:
		KEY_C:
			if arena == null:
				open_workshop()
		KEY_ESCAPE:
			if hud.tip_pinned:
				hud.hide_tip(true)
			elif _paused_menu:
				_close_pause()
			elif state != "title":
				_open_pause()
		KEY_SPACE:
			if _paused_menu:
				return
			match state:
				"prepare":
					_start_battle()
				"battle":
					_toggle_battle_pause()
				"map":
					_go_next()
				"loot":
					_continue_after_loot()
				"node":
					if run.phase == "event":
						_node_action(run.event_continue())
					elif run.phase == "shop":
						_node_action(run.leave_node())
				"result":
					_after_result()
		KEY_R:
			if (state == "prepare" or state == "loot") and not _paused_menu and arena == null:
				_toast_result(run.roll_shop(true))
		KEY_L:
			if (state == "prepare" or state == "loot") and arena == null:
				run.toggle_lock()
		KEY_X:
			if (state == "prepare" or state == "loot") and arena == null:
				_toast_result(run.buy_xp())
		KEY_T:
			_rotate_truck()
		KEY_1:
			if not _speed_key(0) and state == "node" and run.phase == "event" and int(run.event_state.get("option", -1)) < 0:
				_node_action(run.event_choose(0))
		KEY_2:
			if not _speed_key(1) and state == "node" and run.phase == "event" and int(run.event_state.get("option", -1)) < 0:
				_node_action(run.event_choose(1))
		KEY_3:
			if not _speed_key(2) and state == "node" and run.phase == "event" and int(run.event_state.get("option", -1)) < 0:
				_node_action(run.event_choose(2))
		KEY_4:
			_speed_key(3)
		KEY_5:
			_speed_key(4)
		KEY_F:
			match state:
				"battle":
					world.rig.set_preset("battle")
				"title":
					world.rig.set_preset("menu")
				"map":
					world.map_view(false)
				_:
					world.rig.set_preset("prep")
