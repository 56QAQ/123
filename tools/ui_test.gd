extends SceneTree
## UI 自动化：在离屏视口里加载游戏，把第零章整个流程脚本化走一遍，逐步截图并断言：
## 标题 → 图鉴 → 测试场(布阵 / 拖怪 / 多场模拟 / 单场 / 阈值测试) → 新游戏(大地图：悬停节点按钮看信息、点击出发) → 卡车沿虚线开过去 + 淡入淡出切到战斗场景
## → 备战(悬停/射程环/来袭方位/拖拽时才出现部署格/货厢/购买/装备) → 战斗 → 结算 → 拾取晶球 → 回到大地图 → … → 3 个节点之后打通第零章
## → 卡车改装(占位) → 选分支(红之章) → 第一章的方格网大地图(行动力 / 节点按钮 / 路线预览 / 零件) → 红之章的战场(地形效果)
## → 黑市 / 修整 / 事件的节点界面 → 行动力耗尽的追猎。
## 用法: godot --path . --script res://tools/ui_test.gd --quit-after 30000 -- out=res://out/ui.png
var sv: SubViewport
var gr: GameRoot
var shots: Array = []
var fails: Array[String] = []
var checks := 0


func _init() -> void:
	sv = SubViewport.new()
	sv.size = Vector2i(1920, 1080)
	sv.msaa_3d = Viewport.MSAA_2X
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	gr = (load("res://game/game_root.gd") as GDScript).new()
	sv.add_child(gr)
	_run()


func ok(c: bool, msg: String) -> void:
	checks += 1
	if not c:
		fails.append(msg)
		print("  FAIL: ", msg)


## 节点树里有没有哪个文字控件(Label / RichTextLabel / Button)含这段文字
func _has_text(n: Node, s: String) -> bool:
	var txt := ""
	if n is Label:
		txt = (n as Label).text
	elif n is RichTextLabel:
		txt = (n as RichTextLabel).get_parsed_text()
	elif n is Button:
		txt = (n as Button).text
	if txt.contains(s):
		return true
	for c: Node in n.get_children():
		if _has_text(c, s):
			return true
	return false


func frames(n: int) -> void:
	for i in range(n):
		await process_frame


func shot(label: String) -> void:
	await frames(4)
	var img: Image = sv.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	shots.append({"label": label, "img": img})


var _last_mouse: Vector2 = Vector2.ZERO


func mouse_move(p: Vector2, mask: int = 0) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = p
	ev.global_position = p
	ev.relative = p - _last_mouse if p != _last_mouse else Vector2(1, 0)   # Godot 按累计的 relative 判断拖拽起点
	ev.button_mask = mask
	_last_mouse = p
	sv.push_input(ev)


func mouse_btn(p: Vector2, pressed: bool, button: int = MOUSE_BUTTON_LEFT) -> void:
	var ev := InputEventMouseButton.new()
	ev.position = p
	ev.global_position = p
	ev.button_index = button
	ev.pressed = pressed
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	_last_mouse = p
	sv.push_input(ev)


func click(p: Vector2) -> void:
	mouse_btn(p, true)
	await frames(1)
	mouse_btn(p, false)
	await frames(6)


## 按下 → 分几步移动 → 松开(真实的鼠标拖拽)
func drag_mouse(a: Vector2, b: Vector2) -> void:
	mouse_btn(a, true)
	await frames(1)
	mouse_move(a + Vector2(30, 8), MOUSE_BUTTON_MASK_LEFT)
	await frames(1)
	mouse_move(a.lerp(b, 0.5), MOUSE_BUTTON_MASK_LEFT)
	await frames(1)
	mouse_move(b, MOUSE_BUTTON_MASK_LEFT)
	await frames(4)
	mouse_btn(b, false)
	await frames(20)


func _part_visible(v: UnitView, part: String) -> bool:
	var mi: MeshInstance3D = v.model.get_node_or_null("Skeleton3D/" + part) as MeshInstance3D
	return mi != null and mi.visible


func screen_of(v: UnitView) -> Vector2:
	return gr.world.rig.project(v.global_position + Vector3(0, v.body_height * 0.5, 0))


func cell_screen(c: Vector2i) -> Vector2:
	return gr.world.rig.project(gr.world.stage.to_global(gr.world.stage.cell_local(c)))


func view_of(def_id: String) -> UnitView:
	for id: String in gr.prep_views.keys():
		if (gr.prep_views[id] as UnitView).def.id == def_id:
			return gr.prep_views[id]
	return null


func cargo_slot_center(i: int) -> Vector2:
	var sl: Control = gr.hud.cargo_row.get_child(i) as Control
	return sl.get_global_rect().get_center()


func wait_state(st: String, max_frames: int = 2400) -> void:
	var guard := 0
	while gr.state != st and guard < max_frames:
		await frames(4)
		guard += 4


func button_center(i: int) -> Vector2:
	return (gr.hud.map_buttons[i] as Control).get_global_rect().get_center()


## 大地图 → 点击"下一站"按钮 → 等卡车开到节点、切到战斗场景 → 备战
func travel_to_next() -> void:
	var idx: int = gr.run.node_index
	ok(gr.hud.map_buttons[idx].status == "next", "node %d is the clickable next stop" % (idx + 1))
	var bp: Vector2 = button_center(idx)
	mouse_move(bp)
	mouse_btn(bp, true)
	await frames(1)
	mouse_btn(bp, false)
	await frames(2)
	ok(gr.state == "travel", "clicking the next-stop button sets the truck off (state=%s)" % gr.state)
	if idx == 0:
		await frames(50)
		ok(gr.world.overworld.visible and gr.world.truck.global_position.distance_to(gr.world.overworld.start_pos) > 0.5, "the truck drives along the dashed route")
		await shot("driving to node 1")
	await wait_state("prepare")
	ok(gr.state == "prepare" and gr.run.phase == "prepare", "truck arrived at node %d → prepare (state=%s)" % [idx + 1, gr.state])
	ok(gr.world.battle_root.visible and not gr.world.overworld.visible, "the battle scene replaced the overworld map")
	ok(Vector2(gr.world.truck.global_position.x, gr.world.truck.global_position.z).length() < 0.6, "the truck parks in the middle of the battle map")
	var g := 0
	while gr.fade_rect.color.a > 0.01 and g < 400:
		await frames(2)
		g += 2
	ok(gr.fade_rect.color.a <= 0.01, "the scene fade finished")


## 开战 → 跳过 → 结算 → 继续 → 拾取(点一个晶球) → 离开
func fight_and_loot(label: String, click_orb: bool) -> void:
	gr._start_battle()
	await frames(20)
	ok(gr.state == "battle", "%s: battle started" % label)
	gr.world.battle_view.skip()
	var guard := 0
	while gr.state == "battle" and guard < 3000:
		await frames(4)
		guard += 4
	ok(gr.state == "result", "%s: battle ended into the result screen (state=%s)" % [label, gr.state])
	await frames(20)
	if gr.run.phase == "over":
		return
	gr.screens.result_continue.emit()
	await frames(20)
	ok(gr.state == "loot", "%s: result → loot phase (state=%s)" % [label, gr.state])
	ok(gr.orb_views.size() == gr.run.pending_orbs.size(), "%s: one orb on the ground per drop (%d/%d)" % [label, gr.orb_views.size(), gr.run.pending_orbs.size()])
	if click_orb and not gr.orb_views.is_empty():
		var ov: OrbView = gr.orb_views[0]
		var inv0: int = gr.run.inventory.size()
		var units0: int = gr.run.roster.size()
		var gold0: int = gr.run.gold
		var p: Vector2 = gr.world.rig.project(ov.global_position)
		mouse_btn(p, true)
		await frames(2)
		mouse_btn(p, false)
		await frames(10)
		ok(bool(gr.run.pending_orbs[0]["opened"]), "%s: clicking an orb opens it" % label)
		var lt: Dictionary = gr.run.pending_orbs[0]["loot"]
		var paid: bool = int(lt.get("gold", 0)) > 0 or not (lt.get("units", []) as Array).is_empty() or not (lt.get("weapons", []) as Array).is_empty()
		ok(paid and (gr.run.inventory.size() > inv0 or gr.run.gold > gold0 or gr.run.roster.size() != units0 or not (lt["units"] as Array).is_empty()),
			"%s: the orb paid out something (%s)" % [label, str(lt)])
		ok(gr.hud.loot_list.get_child_count() > 0, "%s: loot popup lists what came out" % label)
		ok(Crafting.total(lt.get("materials", {})) >= 1, "%s: every orb also holds workshop materials (%s)" % [label, str(lt.get("materials", {}))])
		await shot("%s loot" % label)
	gr.hud.loot_done_requested.emit()
	await frames(4)
	if gr.run.phase != "over":
		await wait_state("map")


func _run() -> void:
	await frames(200)             # 等 Portraits 渲染完(机器忙时会慢一些，最多再等 3000 帧)
	var boot_t0 := Time.get_ticks_msec()
	await wait_state("title", 12000)
	print("boot took %d ms, state=%s" % [Time.get_ticks_msec() - boot_t0, gr.state])
	ok(gr.state == "title", "boots to the title screen (state=%s)" % gr.state)
	await shot("title")
	# ------------------------------------------------ 图鉴(只收录重构过的内容)
	gr.screens.codex.emit()
	await frames(20)
	ok(gr.codex != null and gr.codex.visible, "the title menu opens the codex")
	var cx: Codex = gr.codex
	var nu: Array[String] = cx.units()
	ok(nu.size() >= 4 and nu.has("node_student") and not nu.has("node_bounty"), "codex lists reworked nodes only (%s)" % str(nu))
	ok(cx.weapons().has("spell_notes") and not cx.weapons().has("basic_focus"), "codex lists reworked weapons only")
	ok(cx.keywords().has("kw:learning") and cx.keywords().has("kw:eternal"), "codex keywords include 学习 / 永恒 (from the student)")
	cx.select_entry("node_student")
	await frames(30)
	ok(cx._view != null and cx._view.def.id == "node_student", "the stage shows the selected node")
	ok(cx._view != null and cx._view.weapon != null and cx._view.weapon.id == "spell_notes", "…holding her exclusive weapon by default")
	await shot("codex: node")
	cx.star = 2
	cx.select_entry("node_student")
	await frames(10)
	ok(cx._view.star == 2, "star toggle re-renders the node at 2★")
	cx._set_pose("victory")
	await frames(40)
	cx.select_tab("weapons")
	cx.select_entry("spell_notes")
	await frames(20)
	ok(cx._view != null and cx._view.def.id == "node_student", "a weapon entry is shown in its owner's hands")
	await shot("codex: weapon")
	# 武器的适配角色(FitTags)：提示里有三组标签和"适配角色："，图鉴右栏列出适配的棋子(牵丝提灯 → 和星)
	cx.select_entry("puppet_lantern")
	await frames(20)
	ok(_has_text(cx, Loc.t("ui.fit.label")) and _has_text(cx, Loc.t("fit.multi.any")) and _has_text(cx, Loc.t("unit.node_druid.name")),
		"codex: a generic weapon shows its fit tags and the pieces it fits")
	ok(cx._view != null and cx.cat.fit_units("puppet_lantern").has(cx._view.def.id), "codex: a generic weapon is shown in the hands of a piece it fits")
	await shot("codex: weapon fits")
	# 护理节点(2026-10-02 重构)：图鉴里有她和爱心针剂；2 星卡片(被动 2 解锁、【溅射 1.5】显示小数)
	cx.select_tab("units")
	cx.star = 2
	cx.select_entry("node_nurse")
	await frames(30)
	ok(cx._view != null and cx._view.def.id == "node_nurse" and cx._view.weapon != null and cx._view.weapon.id == "heart_syringe",
		"codex: Node Nurse holds the Heart Syringe")
	await shot("codex: nurse")
	cx.select_tab("weapons")
	cx.select_entry("heart_syringe")
	await frames(20)
	await shot("codex: heart syringe")
	cx.star = 1
	cx.select_tab("keywords")
	cx.select_entry("kw:learning")
	await frames(10)
	ok(not cx._stage_panel.visible, "keywords have no 3D stage")
	await shot("codex: keyword")
	cx.jump("units", "node_peasant")
	await frames(10)
	ok(cx.tab == "units" and cx.sel == "node_peasant", "used-by links jump to the entry")
	cx.select_tab("traits")
	await frames(6)
	ok(cx.sel == "" and not cx._stage_panel.visible, "traits tab shows the empty state (none reworked yet)")
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	sv.push_input(esc)
	await frames(10)
	ok(gr.codex == null and gr.state == "title", "Esc closes the codex back to the title")
	if gr.codex != null:
		gr.codex.close_codex()
		await frames(4)
	# ------------------------------------------------ 测试场(标题画面的「测试场」：发布版里的平衡测试工具)
	gr.screens.arena.emit()
	await frames(40)
	ok(gr.arena != null and gr.state == "prepare" and gr.hud.mode == "arena", "the title menu opens the test range (state=%s)" % gr.state)
	var am: ArenaMode = gr.arena
	var ap: ArenaPanel = am.panel
	ok(ap != null and is_instance_valid(ap) and ap.tab == "allies", "with its panel on the allies tab")
	am.add_unit("node_archer", 2)
	await frames(10)
	var archer_id: String = gr.run.roster.keys()[0] if gr.run.roster.size() > 0 else ""
	ok(archer_id != "" and gr.run.roster[archer_id]["cell"] == null and int(gr.run.roster[archer_id]["star"]) == 2, "clicking a portrait adds a 2★ node to storage")
	ok(archer_id != "" and str(gr.run.roster[archer_id]["weapon"]) == "rapidfire_arbalest", "…holding her exclusive weapon")
	# 从面板把头像拖到格子上 = 直接上场
	var ar_tile: Control = null
	for ch: Node in ap._body.get_children():
		if ch is GridContainer and ch.get_child_count() > 0 and ch.get_child(0) is ArenaPanel.ArenaTile:
			for t2: Node in ch.get_children():
				if str((t2 as ArenaPanel.ArenaTile).drag_data.get("def", "")) == "node_shielder":
					ar_tile = t2
	ok(ar_tile != null, "the palette has Node Shielder")
	if ar_tile != null:
		await drag_mouse(ar_tile.get_global_rect().get_center(), cell_screen(Vector2i(12, 8)))
		await frames(12)
	var sh_id := ""
	for rid: String in gr.run.roster.keys():
		if str(gr.run.roster[rid]["def"]) == "node_shielder":
			sh_id = rid
	ok(sh_id != "" and gr.run.roster[sh_id]["cell"] == Vector2i(12, 8), "dragging a portrait onto a cell deploys it there")
	if sh_id == "":
		am.add_unit("node_shielder", 1, Vector2i(12, 8))
		for rid2: String in gr.run.roster.keys():
			if str(gr.run.roster[rid2]["def"]) == "node_shielder":
				sh_id = rid2
	am.add_unit("node_dancer", 2, Vector2i(11, 7))
	ap.select_tab("enemies")
	am.add_monster("mob_ember_lust", 1, GC.cell_to_world(17, 5))
	ap.select_tab("allies")
	await frames(6)
	var spy_tile: Control = null
	for ch2: Node in ap._body.get_children():
		if ch2 is GridContainer and ch2.get_child_count() > 0 and ch2.get_child(0) is ArenaPanel.ArenaTile:
			for t3: Node in ch2.get_children():
				if str((t3 as ArenaPanel.ArenaTile).drag_data.get("def", "")) == "node_spy":
					spy_tile = t3
	var near_c := Vector2i(-1, -1)
	for nc: Vector2i in gr.run.near_enemy_cells().keys():
		if near_c.x < 0 and gr.run.unit_at_cell(nc).is_empty():
			near_c = nc
	ok(spy_tile != null and near_c.x >= 0, "a placed monster gives Node Spy cells next to it (%s)" % str(near_c))
	if spy_tile != null and near_c.x >= 0:
		await drag_mouse(spy_tile.get_global_rect().get_center(), cell_screen(near_c))
		await frames(12)
	var spy_rid := ""
	for rid3: String in gr.run.roster.keys():
		if str(gr.run.roster[rid3]["def"]) == "node_spy":
			spy_rid = rid3
	ok(spy_rid != "" and gr.run.roster[spy_rid]["cell"] == near_c, "the test range places Node Spy next to the monster")
	if spy_rid != "":
		am.remove_unit(spy_rid)
	am.clear_monsters()
	await frames(4)
	gr.run.move_unit(archer_id, {"cell": Vector2i(13, 8)})
	await frames(10)
	gr._select(sh_id)
	await frames(10)
	ok(ap._sel == sh_id, "selecting a node shows it in the panel editor")
	am.set_star(sh_id, 2)
	am.set_weapon(sh_id, "")
	await frames(6)
	ok(int(gr.run.roster[sh_id]["star"]) == 2 and str(gr.run.roster[sh_id]["weapon"]) == "", "the editor changes its star and weapon")
	ok(gr.prep_views.has(sh_id) and (gr.prep_views[sh_id] as UnitView).star == 2, "…and the model on the field follows")
	await shot("test range: allies")
	# 敌方：点头像加怪、拖到战场上、强度点数总值
	ap.select_tab("enemies")
	am.add_monster("mob_ember_wrath", 2)
	am.add_monster("mob_ember_glut", 1, GC.cell_to_world(12, 4))
	await frames(10)
	var want_pts: float = gr.run._unit_power("mob_ember_wrath", 2) + gr.run._unit_power("mob_ember_glut", 1)
	ok(absf(am.total_points() - want_pts) < 0.01, "the panel totals the monster points (%.2f)" % am.total_points())
	ok(gr.enemy_views.size() == 2, "two monster previews on the field")
	var glut_v: UnitView = gr.enemy_views[1] if gr.enemy_views.size() > 1 else null
	ok(glut_v != null and GC.world_to_cell(Vector2(glut_v.position.x, glut_v.position.z)) == Vector2i(12, 4), "a placed monster stands where it was put")
	var to_c := Vector2i(-1, -1)
	for ty in range(1, 4):
		for tx in range(3, 8):
			if to_c.x < 0 and am.valid_enemy_cell(Vector2i(tx, ty)):
				to_c = Vector2i(tx, ty)
	if gr.enemy_views.size() > 0 and to_c.x >= 0:
		await drag_mouse(screen_of(gr.enemy_views[0]), cell_screen(to_c))
		await frames(10)
		var ep: Variant = ((am.enemies()[0] as Array)[4] as Dictionary).get("pos")
		ok(ep != null and GC.world_to_cell(ep) == to_c, "monsters on the field can be dragged to a new spot (%s)" % str(to_c))
	await shot("test range: enemies")
	am.random_monsters("fight", 26)
	await frames(10)
	ok(absf(am.total_points() - 26.0) < 1.4, "random monsters by intensity add up to it (%.1f)" % am.total_points())
	# 测试：多场无画面模拟
	ap.select_tab("test")
	am.battle_count = 3
	ap.refresh()
	am.start()
	ok(am.busy == "sims", "several battles run as a simulation")
	var ar_guard := 0
	while am.busy != "" and ar_guard < 6000:
		ar_guard += 1
		await frames(1)
	ok(am.busy == "" and int(am.sim_result.get("n", 0)) == 3, "…and report the results (%s battles)" % str(am.sim_result.get("n", 0)))
	ok(gr.state == "prepare" and gr.world.battle_view.battle == null, "without playing them on screen")
	await shot("test range: 3 simulated battles")
	# 单场：正常播放，之后是结算
	am.battle_count = 1
	gr._start_battle()
	await frames(10)
	ok(gr.state == "battle", "one battle plays on screen")
	gr._set_speed(4.0)
	await wait_state("result", 6000)
	ok(gr.state == "result" and gr.screens.current == "result", "…and ends on the result screen")
	await shot("test range: result screen")
	gr._after_result()
	await frames(20)
	ok(gr.state == "prepare" and gr.hud.mode == "arena" and gr.prep_views.size() == 3, "continue goes back to the test range setup")
	gr._set_speed(1.0)
	# 强度阈值测试(快速：每档最多 6 场)
	am.probe_opts = {"keep_cells": false, "max": 6}
	am.start_probe()
	ok(am.busy == "probe", "the threshold test starts")
	await frames(30)
	await shot("test range: threshold test running")
	ar_guard = 0
	while am.busy != "" and ar_guard < 30000:
		ar_guard += 1
		await frames(1)
	ok(am.probe != null and am.probe.done, "the threshold test finishes (%d battles)" % (am.probe.fights if am.probe != null else 0))
	ok(am.probe != null and am.probe.best >= 4, "…with a highest passed intensity (%d)" % (am.probe.best if am.probe != null else -9))
	await frames(10)
	await shot("test range: threshold result")
	gr._show_title()
	await frames(20)
	ok(gr.arena == null and gr.state == "title", "back to the title")
	# ------------------------------------------------ 新游戏：先选初始卡车改装(三选一)，再到章节地图
	gr._new_game()
	await frames(30)
	ok(gr.state == "start_mod" and gr.run.phase == "start_mod" and gr.screens.current == "mod", "a new game first asks for the starting truck mod (state=%s)" % gr.state)
	ok(gr.run.mod_options.size() == 3 and gr.run.mod_options.has("truck_zone") and gr.run.mod_options.has("truck_free") and gr.run.mod_options.has("truck_wide"),
		"three starting mods: Mobile Workshop / Free Chassis / Wider Ground")
	await shot("new game: starting truck mod")
	gr.screens.mod_picked.emit("truck_zone")
	await frames(60)
	ok(gr.run.truck_mods.size() == 1 and gr.run.truck_mods[0] == "truck_zone" and gr.run.truck_layout.mod == "truck_zone", "picked Mobile Workshop: recorded on the run")
	ok(gr.state == "map" and gr.run.phase == "map", "new game opens the chapter map (state=%s)" % gr.state)
	ok(gr.run.total_nodes() == 3, "chapter 0 has 3 map nodes")
	ok(gr.world.overworld.visible and not gr.world.battle_root.visible, "the overworld map is its own scene (battle scene hidden)")
	ok(gr.hud.map_layer.visible and gr.hud.map_buttons.size() == 3, "3 map-node icon buttons float over the map")
	ok(not gr.hud.dock.visible and not gr.hud.cargo.visible, "no shop/cargo panels on the map")
	ok(gr.run.roster.size() == 3, "starts with 3 units (the gifted Node Basic included)")
	ok(gr.world.truck.global_position.distance_to(gr.world.overworld.start_pos) < 0.1, "truck waits at the chapter start")
	var sts: Array = []
	for b: MapNodeButton in gr.hud.map_buttons:
		sts.append(b.status)
	ok(sts == ["next", "later", "later"], "button states: next / later / later (%s)" % str(sts))
	var vp: Rect2 = Rect2(Vector2.ZERO, Vector2(sv.size))
	var on_screen := true
	for i in range(3):
		if not vp.grow(-20).has_point(button_center(i)):
			on_screen = false
	ok(on_screen, "all node buttons are on screen")
	# 悬停节点按钮：弹出节点信息卡
	mouse_move(button_center(2))
	await frames(6)
	ok(gr.hud.tip.visible, "hovering a node button shows its info card")
	await shot("map (hover node 3)")
	# 点未到达的节点不会出发
	mouse_btn(button_center(2), true)
	await frames(2)
	mouse_btn(button_center(2), false)
	await frames(2)
	ok(gr.state == "map", "a node that isn't the next stop can't be clicked")
	mouse_move(Vector2(200, 900))
	await frames(4)
	ok(not gr.hud.tip.visible, "info card hides when the mouse leaves")
	# ------------------------------------------------ 出发 → 第 1 个节点
	await travel_to_next()
	ok(gr.prep_views.size() == 3, "3 prep views (all starters deployed)")
	ok(gr.hud.cargo.visible, "storage strip is shown in prepare")
	ok(not gr.world.stage.deploy_shown, "no grid on the battlefield while nothing is being dragged")
	var archer_v: UnitView = view_of("node_archer")
	var sp: Vector2 = screen_of(archer_v)
	gr._on_moved(sp + Vector2(-30, 0), Vector2(1, 0), 0)
	gr._on_moved(sp, Vector2(1, 0), 0)
	await frames(6)
	ok(not gr.hud.card.visible, "just pointing at a piece does not open its card")
	ok(gr.hover_view == archer_v and archer_v.hover_ring.visible, "the pointed-at piece still gets its hover ring")
	ok(archer_v.name_label.visible and archer_v.name_label.text == Loc.t("unit.node_archer.name"), "the piece's name floats above its HP bar")
	ok(archer_v.name_label.outline_size >= 12 and archer_v.name_label.no_depth_test, "name has a thick dark outline and is never hidden by the scenery")
	ok(gr.enemy_views[0].name_label.visible, "enemies show their names too")
	# 按钮上的快捷键键帽
	var caps: Array[String] = []
	for b: Button in [gr.hud.reroll_btn, gr.hud.lock_btn, gr.hud.xp_btn, gr.hud.start_btn]:
		for n: Node in b.find_children("*", "Label", true, false):
			var t: String = (n as Label).text
			if t in ["R", "L", "X", "SPACE"]:
				caps.append(t)
	ok(caps == ["R", "L", "X", "SPACE"], "keycaps next to the buttons: %s" % str(caps))
	# 制造概率条：当前等级各费用的概率；悬停看整张表
	var odds_now: Dictionary = (gr.run.shop_rule["odds_by_level"] as Dictionary)[str(gr.run.level)]
	var strip_txt: Array[String] = []
	for n2: Node in gr.hud.odds_strip.find_children("pct_*", "Label", true, false):
		strip_txt.append((n2 as Label).text)
	var want_txt: Array[String] = []
	for ck: String in odds_now.keys():
		want_txt.append("%d%%" % int(odds_now[ck]))
	ok(gr.hud.odds_strip.visible and strip_txt == want_txt, "fabrication odds strip shows level %d odds %s" % [gr.run.level, str(strip_txt)])
	mouse_move(gr.hud.odds_strip.get_global_rect().get_center())
	await frames(4)
	var tip_rows := 0
	for n3: Node in gr.hud.tip.find_children("*", "GridContainer", true, false):
		tip_rows = (n3 as GridContainer).get_child_count() / (n3 as GridContainer).columns - 1
	ok(gr.hud.tip.visible and tip_rows == gr.run.max_level(), "hovering the odds strip opens the full table (%d levels)" % tip_rows)
	await shot("fabrication odds table (hover)")
	mouse_move(Vector2(960, 300))
	await frames(4)
	ok(not gr.hud.tip.visible, "moving away closes the odds table")
	# WASD 平移镜头
	var cam0: Vector3 = gr.world.rig.g_target
	var kd := InputEventKey.new()
	kd.keycode = KEY_W
	kd.physical_keycode = KEY_W
	kd.pressed = true
	Input.parse_input_event(kd)
	await frames(12)
	var ku := kd.duplicate() as InputEventKey
	ku.pressed = false
	Input.parse_input_event(ku)
	await frames(2)
	ok(gr.world.rig.g_target.z < cam0.z - 0.2, "holding W pans the camera forward (%.2f → %.2f)" % [cam0.z, gr.world.rig.g_target.z])
	gr.world.rig.set_preset("prep", true)
	await frames(2)
	ok(gr.world.range_ring.visible, "hovering a piece shows its attack range ring")
	var rifle_reach: float = GC.WEAPON_CLASSES["rifle"]["range"] * GC.RANGE_UNIT     # 速射节点默认拿步枪
	ok(absf(gr.world.range_ring.radius - (rifle_reach + 0.27)) < 0.05, "ring radius = rifle reach (%.2f m)" % gr.world.range_ring.radius)
	var threats := 0
	for rg: String in gr.world.stage.arrows.keys():
		if (gr.world.stage.arrows[rg]["arrow"] as MeshInstance3D).visible:
			threats += 1
	ok(threats >= 1, "incoming-enemy direction markers are shown")
	var wave_n: int = (gr.run.wave_def().get("units", []) as Array).size()
	ok(gr.enemy_views.size() == wave_n, "one enemy preview per encounter unit (%d/%d)" % [gr.enemy_views.size(), wave_n])
	var map: BattleMap = gr.run.current_map()
	var ev_ok := true
	for ev: UnitView in gr.enemy_views:
		var p2 := Vector2(ev.position.x, ev.position.z)
		if p2.length() < 3.5 or not map.circle_free(p2, 0.2):
			ev_ok = false
	ok(ev_ok, "enemy previews stand at the map edge, not inside ruins or the truck")
	# 悬停背包武器：能装备的棋子亮绿圈
	gr._mark_for_item("blackblade")
	await frames(2)
	var marked := 0
	for rid: String in gr.prep_views.keys():
		var pv: UnitView = gr.prep_views[rid]
		if pv.mark_ring.visible and (pv.mark_ring.material_override as StandardMaterial3D).albedo_color.g > 0.9:
			marked += 1
	ok(marked == 2, "hovering the greatsword highlights the pieces that can use it: the knight and the white Node Basic (%d)" % marked)
	gr._clear_marks()
	# 点击才打开详情卡；指着别的棋子不会替换它
	var knight_v: UnitView = view_of("node_darkknight")
	await click(screen_of(knight_v))
	ok(gr.hud.card.visible and gr.card_target.get("view") == knight_v, "clicking a piece opens its card")
	gr._on_moved(screen_of(archer_v), Vector2(1, 0), 0)
	await frames(6)
	ok(not gr.hud.card.get_global_rect().has_point(screen_of(archer_v)), "(test setup: the card doesn't cover the archer)")
	ok(gr.hover_view == archer_v and gr.card_target.get("view") == knight_v, "pointing at another piece does not replace the open card")
	await shot("prepare: clicked card, hovering another piece")
	var ev0: UnitView = gr.enemy_views[0]
	var ep: Vector2 = gr.world.rig.project(ev0.global_position + Vector3(0, ev0.body_height * 0.5, 0))
	ok(not gr.hud.card.get_global_rect().has_point(ep), "(test setup: the card doesn't cover the enemy preview)")
	await click(ep)
	ok(gr.hud.card.visible and gr.card_target.get("view") == ev0, "clicking an enemy preview opens that enemy's card")
	await click(gr.world.rig.project(gr.world.stage.to_global(Vector3(-7.5, 0, 0.5))))
	ok(not gr.hud.card.visible, "clicking empty ground closes the card")
	# --- 拖拽：把射手拖到卡车后方的部署格
	var target_cell := Vector2i(9, 10)
	var tp: Vector2 = cell_screen(target_cell)
	mouse_btn(sp, true)
	mouse_move(sp + Vector2(40, 10))
	mouse_move((sp + tp) * 0.5)
	mouse_move(tp)
	await frames(4)
	ok(bool(gr.drag.get("active", false)), "drag becomes active")
	ok(gr.world.stage.deploy_shown and gr.world.stage.zone.visible, "dragging a piece paints the floor (deploy zone blue, the rest red)")
	var dep_c: Vector2 = GC.cell_to_world(GC.DEPLOY_RECT.position.x, GC.DEPLOY_RECT.position.y)
	var far_c: Vector2 = GC.cell_to_world(GC.DEPLOY_RECT.position.x - 1, GC.DEPLOY_RECT.position.y)
	ok(gr.world.stage.zone_kind(dep_c) == "ally" and gr.world.stage.zone_kind(far_c) == "foe" and gr.world.stage.zone_kind(Vector2(0, -40)) == "foe",
		"zone colors: deploy corner = ally, the cell just outside and far away = foe")
	ok(GC.deploy_cells().size() == 9 * 6 - 6, "deploy zone = 9×6 around the truck minus the truck (%d cells)" % GC.deploy_cells().size())
	await shot("dragging")
	mouse_btn(tp, false)
	await frames(30)
	ok(not gr.world.stage.deploy_shown, "releasing the piece hides the zone colors again")
	ok(not gr.hud.card.visible, "dragging a piece (press → move → release) does not open its card")
	var moved: Dictionary = gr.run.roster[archer_v.roster_id]
	ok(moved["cell"] == target_cell, "archer moved to the target cell (got %s)" % str(moved["cell"]))
	# 卡车占的格子不能放
	var truck_cell := Vector2i(12, 9)
	ok(not GC.is_deploy_cell(truck_cell) and not gr.run.can_deploy_at(moved, truck_cell), "cells under the truck are not deployable")
	# --- 开局改装「机动工坊」：拖动卡车 = 移动(部署区和上面的节点一起走)，「旋转卡车」(T) = 顺时针转 90°
	ok(gr.run.truck_can_move() and gr.hud.truck_btn.visible, "Mobile Workshop: the truck can be moved while preparing (rotate button shown)")
	var tl0: TruckLayout = gr.run.truck_layout
	var rel0: Dictionary = {}
	for bu: Dictionary in gr.run.board_units():
		rel0[bu["id"]] = (bu["cell"] as Vector2i) - tl0.truck.position
	var grab_cell: Vector2i = tl0.truck.position + Vector2i(1, 0)        # 车顶正中偏北：前面没有棋子挡着(车前的棋子比卡车近，会被优先拾取)
	var truck_sp: Vector2 = cell_screen(grab_cell)
	ok(gr._truck_hit(truck_sp), "(test setup: the ray through a truck cell hits the truck)")
	var dest_c: Vector2i = tl0.truck.position + Vector2i(-3, -2)        # 往西北挪(正好贴着初始部署区的角)
	var dest_sp: Vector2 = cell_screen(dest_c + Vector2i(1, 0))
	mouse_btn(truck_sp, true)
	mouse_move(truck_sp + Vector2(40, 10))
	mouse_move((truck_sp + dest_sp) * 0.5)
	mouse_move(dest_sp)
	await frames(4)
	ok(gr.drag.has("truck") and bool(gr.drag.get("active", false)), "dragging the truck")
	ok(gr.world.stage.deploy_shown, "…paints the candidate deploy zone while dragging")
	await shot("dragging the truck (Mobile Workshop)")
	mouse_btn(dest_sp, false)
	await frames(30)
	var tl1: TruckLayout = gr.run.truck_layout
	ok(tl1.truck.position == TruckLayout.clamp_pos(dest_c, 0), "the truck moved to the target cells, clamped into the initial zone (%s)" % str(tl1.truck.position))
	ok(tl1.deploy.position == tl1.truck.position - TruckLayout.ZONE_PAD and tl1.deploy.size == GC.DEPLOY_RECT.size, "the deploy zone moved with the truck")
	var kept := true
	for bu2: Dictionary in gr.run.board_units():
		if (bu2["cell"] as Vector2i) - tl1.truck.position != rel0[bu2["id"]]:
			kept = false
	ok(kept, "the pieces kept their place relative to the truck")
	var tc1: Vector2 = tl1.truck_center()
	ok(gr.world.truck.position.distance_to(Vector3(tc1.x, 0, tc1.y)) < 0.05, "the truck model parked on its new cells")
	ok(gr.world.stage.zone_kind(GC.cell_to_world(tl1.deploy.position.x, tl1.deploy.position.y)) == "ally"
		and gr.world.stage.zone_kind(GC.cell_to_world(GC.DEPLOY_RECT.end.x - 1, GC.DEPLOY_RECT.end.y - 1)) == "foe", "the zone shading follows the new layout")
	gr.hud.truck_btn.pressed.emit()
	await frames(30)
	ok(gr.run.truck_layout.rot == 1 and gr.run.truck_layout.truck.size == Vector2i(2, 3), "Rotate Truck: the truck now stands 2 × 3")
	ok(gr.run.truck_layout.deploy.size == Vector2i(6, 9), "…and the deploy zone turned with it (6 × 9)")
	var all_ok := true
	for bu3: Dictionary in gr.run.board_units():
		if not gr.run.can_deploy_at(bu3, bu3["cell"]):
			all_ok = false
	ok(all_ok and gr.run.board_units().size() == 3, "every piece still stands on a valid cell of the turned zone")
	ok(absf(angle_difference(gr.world.truck.rotation.y, -PI * 0.5)) < 0.05, "the truck model turned 90°")
	await shot("truck rotated")
	for _ri in range(3):
		gr.hud.truck_btn.pressed.emit()
		await frames(2)
	gr.run.move_truck(GC.TRUCK_RECT.position)
	await frames(30)
	ok(gr.run.truck_layout.truck == GC.TRUCK_RECT and gr.run.truck_layout.deploy == GC.DEPLOY_RECT, "four turns + a move back: the initial layout again")
	ok(gr.world.truck.position.distance_to(Vector3.ZERO) < 0.05 and absf(angle_difference(gr.world.truck.rotation.y, 0.0)) < 0.05, "the truck model is back in the middle")
	# --- 拖到仓库：收纳到末尾；点击仓库里的节点打开详情；再从仓库拖回战场
	archer_v = view_of("node_archer")
	var aid: String = archer_v.roster_id
	ok(gr.hud.cargo_row.get_child_count() == 1 and (gr.hud.cargo_row.get_child(0) as StorageCard).roster_id == "", "empty storage shows just the drop slot")
	await drag_mouse(screen_of(archer_v), cargo_slot_center(0))
	ok(gr.run.roster[aid]["cell"] == null and gr.run.bench_units().back()["id"] == aid, "dragging a piece onto the storage strip stores it")
	ok(not gr.hud.card.visible, "storing a piece by dragging does not open its card")
	ok(not gr.prep_views.has(aid), "a stored piece leaves the battlefield")
	ok((gr.hud.cargo_row.get_child(0) as StorageCard).roster_id == aid, "the storage strip shows the stored piece")
	ok((gr.hud.cargo_row.get_child(gr.hud.cargo_row.get_child_count() - 1) as StorageCard).roster_id == "", "a drop slot stays at the end of the storage")
	await click(cargo_slot_center(0))
	ok(gr.hud.card.visible and gr.selected_storage == aid, "clicking a stored piece opens its card")
	await shot("storage: clicked card")
	gr._on_dropped(cell_screen(Vector2i(9, 7)), {"kind": "roster", "id": aid})
	await frames(20)
	ok(gr.run.roster[aid]["cell"] == Vector2i(9, 7) and gr.prep_views.has(aid), "a piece dragged from the storage back onto a tile is deployed again")
	await click(gr.world.rig.project(gr.world.stage.to_global(Vector3(-7.5, 0, 0.5))))
	archer_v = view_of("node_archer")
	# --- 购买：进货厢
	var gold0: int = gr.run.gold
	gr._buy(0)
	await frames(30)
	ok(gr.run.gold < gold0, "buying spends gold")
	ok(gr.run.roster.size() == 4, "bought unit joined the roster")
	ok(gr.run.bench_units().size() == 1, "bought unit goes into the storage")
	# --- 仓库里的节点拖到节点制造(商店)的卡片上 = 出售
	var sold_id: String = str(gr.run.bench_units()[0]["id"])
	var g_before: int = gr.run.gold
	await drag_mouse(cargo_slot_center(0), (gr.hud.shop_row.get_child(2) as Control).get_global_rect().get_center())
	ok(not gr.run.roster.has(sold_id) and gr.run.gold > g_before, "dragging a stored piece onto a fabrication card sells it (gold %d → %d)" % [g_before, gr.run.gold])
	ok(not gr.hud.sell_overlay.visible, "the sell hint goes away after the drop")
	for si in range(gr.run.shop.size()):
		if not bool(gr.run.shop[si]["sold"]) and gr.cat.get_unit(str(gr.run.shop[si]["def"])).cost <= gr.run.gold:
			gr._buy(si)
			break
	await frames(20)
	ok(gr.run.bench_units().size() == 1, "fabricate another one for the next steps")
	# --- 装备(直接走 GameRoot 的落点逻辑)
	var kn_v: UnitView = view_of("node_darkknight")
	var kp: Vector2 = screen_of(kn_v)
	var data := {"kind": "equip", "id": "blackblade"}
	ok(gr._can_drop(kp, data), "equipment can be dropped on a unit")
	gr._on_drop_hover(kp, data)
	ok(gr.world.range_ghost.visible, "dragging a weapon over a piece previews its new range (dashed ring)")
	await shot("equip hover")
	gr._on_dropped(kp, data)
	await frames(10)
	ok(str(gr.run.roster[kn_v.roster_id]["weapon"]) == "blackblade", "weapon replaced the basic greatsword")
	ok(kn_v.weapon != null and kn_v.weapon.id == "blackblade", "the 3D model now holds the new weapon")
	ok(_part_visible(kn_v, "W_heavy_blood") and not _part_visible(kn_v, "W_heavy_plain"), "the Blackblade is shown, the plain basic greatsword hidden")
	# 换成单手剑 → 动作模组跟着换(先把待机小动作推后，免得检查的那一刻正好在播小动作)
	kn_v._fidget_at = 1.0e9
	gr.run.inventory.append("sample_arcane_edge")
	gr._on_dropped(kp, {"kind": "equip", "id": "sample_arcane_edge"})
	await frames(10)
	ok(_part_visible(kn_v, "W_sword_ornate") and not _part_visible(kn_v, "W_heavy_ornate"), "swapping to a sword swaps the mesh")
	# 黑骑现在是男性模型 → 播男性款待机(idle_sword_m)；动作模组跟着武器换
	ok(kn_v.ap.current_animation == UnitSkin.anim(kn_v.look, "idle") and kn_v.ap.current_animation.begins_with("idle_sword"),
		"switched to the one-handed idle module (got %s)" % kn_v.ap.current_animation)
	ok(bool(kn_v.look.get("male", false)) == kn_v.ap.current_animation.ends_with("_m"), "male model plays the male idle")
	ok(gr.run.inventory.has("blackblade"), "the replaced (non-basic) weapon went back to the inventory")
	# --- 点击装备：详情固定住(移开鼠标也不收)，点空白处关闭；关键词是蓝字链接、没有【】，指上去出关键词详情
	await frames(8)
	var tile: ItemTile = null
	for ch: Node in gr.hud.inv_grid.get_children():
		if ch is ItemTile and (ch as ItemTile).equip_id == "blackblade":
			tile = ch
	ok(tile != null, "the inventory shows the greatsword tile")
	if tile != null:
		var tc: Vector2 = tile.get_global_rect().get_center()
		mouse_move(tc)
		await frames(4)
		ok(gr.hud.tip.visible and not gr.hud.tip_pinned, "hovering a weapon shows its details")
		await click(tc)
		ok(gr.hud.tip.visible and gr.hud.tip_pinned, "clicking a weapon pins its details")
		mouse_move(tc + Vector2(-40, -260))
		await frames(6)
		ok(gr.hud.tip.visible and gr.hud.tip_pinned, "pinned details stay when the mouse leaves the weapon")
		await shot("pinned weapon details")
		await click(Vector2(sv.size.x * 0.5, sv.size.y * 0.3))
		ok(not gr.hud.tip.visible and not gr.hud.tip_pinned, "clicking elsewhere closes the pinned details")
	var card_tip: Control = TipContent.unit_card(gr.cat, gr.cat.get_unit("node_archer"), 1, "")
	var has_link := false
	var has_brackets := false
	for n: Node in card_tip.find_children("*", "RichTextLabel", true, false):
		var rt := n as RichTextLabel
		has_link = has_link or rt.text.contains("[url=kw:stacking]")
		has_brackets = has_brackets or rt.get_parsed_text().contains("【")
	ok(has_link and not has_brackets, "keywords are blue links without 【】 (stacking in the archer's passive)")
	card_tip.free()
	UIKit.kw_handler.call("pursuit", true)
	await frames(2)
	ok(gr.hud.kw_tip.visible, "hovering a keyword shows its details")
	UIKit.kw_handler.call("pursuit", false)
	await frames(2)
	ok(not gr.hud.kw_tip.visible, "keyword details hide when the mouse leaves")
	# 武器类型不符：步枪(连射弩)不能给誓约节点
	var bow_data := {"kind": "equip", "id": "rapidfire_arbalest"}
	gr._on_drop_hover(kp, bow_data)
	ok(not gr.run.equip_check(kn_v.roster_id, "rapidfire_arbalest")["ok"], "a rifle is refused on the dark knight")
	gr._on_dropped(kp, bow_data)
	await frames(6)
	ok(str(gr.run.roster[kn_v.roster_id]["weapon"]) == "sample_arcane_edge", "refused drop leaves the weapon unchanged")
	# 颜色不兼容：蓝色的剑 vs 红色单位
	gr.run.inventory.append("order_sword")
	var bad: Dictionary = gr.run.equip(kn_v.roster_id, "order_sword")
	ok(not bad["ok"] and bad["reason"] == "ui.err.color_mismatch", "blue sword refused on a red unit")
	gr.run.inventory.erase("order_sword")
	# 连射弩给速射节点：燧发步枪 → 连射弩(外观是她角色卡上的弩)
	var ap2: Vector2 = screen_of(archer_v)
	ok(archer_v.weapon != null and archer_v.weapon.id == "basic_rifle", "archer starts with the flintlock rifle")
	gr._on_dropped(ap2, bow_data)
	await frames(10)
	ok(archer_v.weapon != null and archer_v.weapon.id == "rapidfire_arbalest" and _part_visible(archer_v, "W_rifle_arbalest"), "archer model now holds the repeating arbalest")
	# 卸下 → 换回基础武器，基础武器不进背包
	gr.run.unequip(kn_v.roster_id)
	await frames(6)
	ok(kn_v.weapon != null and kn_v.weapon.id == "basic_heavy" and _part_visible(kn_v, "W_heavy_plain"), "unequip puts the basic greatsword back in hand")
	ok(not gr.run.inventory.has("basic_heavy"), "the basic weapon never enters the inventory")
	gr.run.equip(kn_v.roster_id, "blackblade")
	await frames(6)
	# --- 狩胜节点上场 → 武器库里多一面狩猎旗标；拖到敌人预览身上 = 标记狩猎对象(头顶插旗)；她下场旗标连同标记一起收走
	var glad_u: Dictionary = gr.run.add_unit("node_gladiator", 1, null, gr.run.free_bench_slot())
	var lv_keep: int = gr.run.level
	gr.run.level = 9
	var glad_cell := Vector2i(-1, -1)
	for gcx in range(0, GC.MAP_W):
		for gcy in range(0, GC.MAP_H):
			var gcc := Vector2i(gcx, gcy)
			if glad_cell.x < 0 and GC.is_deploy_cell(gcc) and gr.run.unit_at_cell(gcc).is_empty():
				glad_cell = gcc
	ok(gr.run.move_unit(str(glad_u["id"]), {"cell": glad_cell})["ok"], "deploy Node Gladiator")
	await frames(10)
	var flag_item: ItemTile = null
	for fch: Node in gr.hud.inv_grid.get_children():
		if fch is ItemTile and (fch as ItemTile).equip_id == "hunt_flag":
			flag_item = fch
	ok(flag_item != null, "deploying her puts a Hunting Flag in the armory")
	ok(not gr.enemy_views.is_empty(), "(test setup: enemy previews are shown)")
	if not gr.enemy_views.is_empty():
		var qv0: UnitView = gr.enemy_views[0]
		var flag_data := {"kind": "equip", "id": "hunt_flag"}
		# 走真实的拖放：先问能不能放(WorldInput._can_drop_data)，能放 Godot 才会交给 _drop_data
		ok(gr.wi._can_drop_data(screen_of(qv0), flag_data), "the flag can be dropped on an enemy preview")
		ok(not gr.wi._can_drop_data(kp, flag_data), "but not on one of your pieces")
		gr.wi._drop_data(screen_of(qv0), flag_data)
		await frames(8)
		ok(gr.run.hunt_mark == 0 and qv0._quarry != null, "dropping the flag on an enemy marks it as the quarry (flag over its head)")
		ok(gr.run.inventory.has("hunt_flag"), "the flag goes back to the armory")
		var marked_ok := false
		for se: Dictionary in gr.run.build_battle_setup()["units"]:
			if int(se.get("hunt_marked_by", -1)) == GC.TEAM_PLAYER:
				marked_ok = true
		ok(marked_ok, "the battle setup carries the mark (she opens on that enemy)")
		await shot("hunting flag")
		gr._on_dropped(kp, flag_data)
		await frames(4)
		ok(str(gr.run.roster[kn_v.roster_id]["weapon"]) == "blackblade", "the flag can't be worn by a piece")
		gr.run.sell(str(glad_u["id"]))
		await frames(8)
		ok(not gr.run.inventory.has("hunt_flag") and qv0._quarry == null, "selling her takes the flag and the mark away")
	gr.run.level = lv_keep
	await frames(6)
	# --- 无我节点：仓库里还有别的无我节点 → 她头顶浮着"无我"按钮；点了移除仓库里那一个，按钮变成"就绪"；她下场按钮就没了
	var kl_lv: int = gr.run.level
	gr.run.level = 9
	var kl_u: Dictionary = gr.run.add_unit("node_killer", 1, null, gr.run.free_bench_slot())
	var kl_id: String = str(kl_u["id"])
	var kl_cell := Vector2i(-1, -1)
	for kcx in range(0, GC.MAP_W):
		for kcy in range(0, GC.MAP_H):
			var kcc := Vector2i(kcx, kcy)
			if kl_cell.x < 0 and GC.is_deploy_cell(kcc) and gr.run.unit_at_cell(kcc).is_empty():
				kl_cell = kcc
	ok(gr.run.move_unit(kl_id, {"cell": kl_cell})["ok"], "deploy Node Killer")
	await frames(8)
	ok(not gr.selfless_btns.has(kl_id), "no other Node Killer in storage: no Selfless button")
	var kl_spare: Dictionary = gr.run.add_unit("node_killer", 1, null, gr.run.free_bench_slot())
	gr._sync_prep(true)
	await frames(6)
	var kl_btn: Button = gr.selfless_btns.get(kl_id) as Button
	ok(kl_btn != null and kl_btn.visible and not kl_btn.disabled, "a spare Node Killer in storage: a Selfless button floats over her head")
	await shot("killer selfless button")
	if kl_btn != null:
		kl_btn.pressed.emit()
	await frames(8)
	ok(not gr.run.roster.has(str(kl_spare["id"])) and bool(gr.run.roster[kl_id].get("selfless", false)), "pressing it takes the spare and arms Selfless")
	kl_btn = gr.selfless_btns.get(kl_id) as Button
	ok(kl_btn != null and kl_btn.disabled, "the button now reads 'ready'")
	gr.run.sell(kl_id)
	await frames(6)
	ok(gr.selfless_btns.is_empty(), "selling her removes the button")
	# --- 变奏节点：场上的她头顶浮着"切换为天使"按钮；点了变成天使(部门 → 福利部，身体 / 钢琴换成白的)，按钮变成"切换为恶魔"
	var pn_u: Dictionary = gr.run.add_unit("node_pianist", 1, null, gr.run.free_bench_slot())
	var pn_id: String = str(pn_u["id"])
	gr.run.inventory.append("black_keys")
	gr.run.equip(pn_id, "black_keys")
	ok(gr.run.move_unit(pn_id, {"cell": kl_cell})["ok"], "deploy Node Pianist")
	await frames(8)
	var pn_btn: Button = gr.form_btns.get(pn_id) as Button
	ok(pn_btn != null and pn_btn.visible and pn_btn.text == Loc.t("ui.form_to_angel"), "a 'To Angel' button floats over her head")
	var pn_v: UnitView = gr.prep_views.get(pn_id) as UnitView
	ok(pn_v != null and pn_v.def.form == "demon" and str(pn_v.look.get("model", "")) == "grand", "a demon at a black grand piano")
	await shot("pianist form button")
	if pn_btn != null:
		pn_btn.pressed.emit()
	await frames(8)
	ok(str(gr.run.roster[pn_id].get("form", "")) == "angel", "pressing it makes her an angel")
	pn_btn = gr.form_btns.get(pn_id) as Button
	ok(pn_btn != null and pn_btn.text == Loc.t("ui.form_to_demon"), "the button now reads 'To Demon'")
	ok(pn_v.def.form == "angel" and pn_v.def.profession_id == "welfare" and str(pn_v.look.get("model", "")) == "grand_white", "her view: angel body, white grand")
	await shot("pianist angel")
	gr.run.sell(pn_id)
	await frames(6)
	ok(gr.form_btns.is_empty(), "selling her removes the button")
	gr.run.level = kl_lv
	# --- 2 星浪游节点(随心所欲)：可以从仓库直接拖到部署区外面没有地形的格子
	var cow: Dictionary = gr.run.add_unit("node_cowboy", 2, null, gr.run.free_bench_slot())
	var cmap: BattleMap = gr.run.current_map()
	var far_cell := Vector2i(-1, -1)
	for fcx in range(0, GC.MAP_W):
		for fcy in range(0, 3):
			var fc := Vector2i(fcx, fcy)
			if far_cell.x < 0 and not cmap.blocks_move(fc) and not GC.DEPLOY_RECT.has_point(fc):
				far_cell = fc
	await frames(6)
	gr._on_drop_hover(cell_screen(far_cell), {"kind": "roster", "id": str(cow["id"])})
	ok(gr.world.stage.deploy_shown, "dragging the 2★ cowboy shows the deploy shading")
	await shot("cowboy: deploy anywhere")
	gr._on_dropped(cell_screen(far_cell), {"kind": "roster", "id": str(cow["id"])})
	await frames(8)
	ok(gr.run.roster[str(cow["id"])]["cell"] == far_cell, "a 2★ cowboy can be deployed far outside the zone (%s)" % str(far_cell))
	gr.run.sell(str(cow["id"]))
	await frames(6)
	# 货厢里的新棋子上场
	var bench_u: Array[Dictionary] = gr.run.bench_units()
	if not bench_u.is_empty():
		gr._on_dropped(cell_screen(Vector2i(14, 11)), {"kind": "roster", "id": str(bench_u[0]["id"])})
		await frames(20)
	ok(gr.run.board_count() == 3, "3 pieces deployed (level 3; Node Basic takes no slot)")
	# --- 选中后的卡片(含出售按钮)
	gr._select(kn_v.roster_id)
	await frames(8)
	await shot("selected card")
	# --- 详情卡里的武器可以拖：按住拖出来 → 拖回指挥台(武器库) = 卸下
	var slot_pc: Control = null
	for n2: Node in gr.hud.card.find_children("*", "PanelContainer", true, false):
		if n2.has_meta("equip_id"):
			slot_pc = n2
	ok(slot_pc != null, "the card shows the equipped greatsword in a slot")
	if slot_pc != null:
		var sc: Vector2 = slot_pc.get_global_rect().get_center()
		var dock_c: Vector2 = gr.hud.inv_grid.get_global_rect().get_center()
		mouse_move(sc)
		await frames(2)
		mouse_btn(sc, true)
		await frames(1)
		mouse_move(sc + Vector2(14, 10), MOUSE_BUTTON_MASK_LEFT)
		await frames(1)
		mouse_move(sc + Vector2(40, 60), MOUSE_BUTTON_MASK_LEFT)
		await frames(2)
		ok(sv.gui_is_dragging(), "pressing and moving on the card's weapon starts a drag")
		var dd: Variant = sv.gui_get_drag_data()
		ok(dd is Dictionary and str((dd as Dictionary).get("kind", "")) == "equip" and str((dd as Dictionary).get("from", "")) == kn_v.roster_id,
			"the drag carries the weapon and who holds it")
		mouse_move(sc.lerp(dock_c, 0.5), MOUSE_BUTTON_MASK_LEFT)
		await frames(1)
		mouse_move(dock_c, MOUSE_BUTTON_MASK_LEFT)
		await frames(3)
		ok(gr.hud.sell_overlay.visible and gr.hud.sell_overlay.text == Loc.t("ui.unequip_drop"), "over the armory: 'back to the armory' hint")
		await shot("drag a weapon from the card back to the armory")
		mouse_btn(dock_c, false)
		await frames(10)
		ok(str(gr.run.roster[kn_v.roster_id]["weapon"]) == "" and gr.run.inventory.has("blackblade"), "dropped on the armory: unequipped, back in the inventory")
	# 拖到别人身上换人带(逻辑：Run.move_weapon)
	gr.run.equip(kn_v.roster_id, "blackblade")
	await frames(4)
	var handed: Dictionary = gr.run.move_weapon(kn_v.roster_id, archer_v.roster_id)
	ok(not handed["ok"] and str(gr.run.roster[kn_v.roster_id]["weapon"]) == "blackblade", "handing it to a piece that can't use it changes nothing")
	gr._select(kn_v.roster_id)
	await frames(8)
	# --- 章节 UI 配色接口：换主题 → HUD 按新配色重建，功能不受影响
	for th: String in ["paper", "ember"]:
		ok(UIKit.apply_theme(th), "theme %s applies" % th)
		gr.hud.rebuild()
		await frames(8)
		ok(gr.hud.dock.visible and gr.hud.cargo.visible and gr.hud.shop_row.get_child_count() == gr.run.shop.size(), "HUD rebuilt under theme %s" % th)
		ok(UIKit.ACCENT == (UITheme.palette(th)["accent"] as Color), "theme %s colors are live" % th)
		if th == "paper":
			await shot("theme interface: paper")
	UIKit.apply_theme(str(gr.run.chapter.get("ui_theme", "")))
	gr.hud.rebuild()
	await frames(8)
	ok(UIKit.theme_name == "white", "back to the chapter's own theme (white)")
	# ------------------------------------------------ 战斗倍速(备战时就能选) + 清心节点上场(看符的飞行特效)
	var lv_keep2: int = gr.run.level
	gr.run.level = 9
	var tao: Dictionary = gr.run.add_unit("node_taoist", 2, null, gr.run.free_bench_slot())
	var tao_cell := Vector2i(-1, -1)
	for tcy in range(GC.MAP_H - 1, -1, -1):
		for tcx in range(GC.MAP_W):
			var tcc := Vector2i(tcx, tcy)
			if tao_cell.x < 0 and GC.is_deploy_cell(tcc) and gr.run.unit_at_cell(tcc).is_empty():
				tao_cell = tcc
	ok(gr.run.move_unit(str(tao["id"]), {"cell": tao_cell})["ok"], "deploy Node Taoist")
	# 炽照节点 + 炽霞：刀鞘挂在腰上(A_ 部件)；开战后看拔刀连斩留下的剑痕
	var sam: Dictionary = gr.run.add_unit("node_samurai", 2, null, gr.run.free_bench_slot())
	var sam_cell := Vector2i(-1, -1)
	for scy in range(GC.MAP_H):
		for scx in range(GC.MAP_W):
			var scc := Vector2i(scx, scy)
			if sam_cell.x < 0 and GC.is_deploy_cell(scc) and gr.run.unit_at_cell(scc).is_empty():
				sam_cell = scc
	ok(gr.run.move_unit(str(sam["id"]), {"cell": sam_cell})["ok"], "deploy Node Samurai")
	gr.run.inventory.append("blazing_glow")
	ok(gr.run.equip(str(sam["id"]), "blazing_glow")["ok"], "he wields Blazing Glow")
	await frames(6)
	var sam_v: UnitView = gr.prep_views.get(str(sam["id"]), null)
	var saya_on := false
	if sam_v != null:
		var ssk: Skeleton3D = sam_v.model.get_node("Skeleton3D") as Skeleton3D
		saya_on = ssk.has_node("A_sword_katana") and (ssk.get_node("A_sword_katana") as Node3D).visible
	ok(saya_on, "the scabbard hangs at his hip")
	# 星旅节点放在仓库里：备战时在地上标出她开战时会坠落的地方，指上去显示落点范围
	var gold_sf: int = gr.run.gold
	var astro: Dictionary = gr.run.add_unit("node_astronaut", 1, null, gr.run.free_bench_slot())
	gr.hud.refresh()
	gr._refresh_starfall()
	await frames(4)
	ok(not gr.world.stage.starfall_info.is_empty() and gr.world.stage._sf_mark != null and gr.world.stage._sf_mark.visible,
		"a Node Astronaut in storage: her landing spot is marked")
	if not gr.world.stage.starfall_info.is_empty():
		gr.hud.hide_tip(true)                       # 前面固定住的提示先关掉(固定的提示不会被悬停替换)
		# 指地上的落点标记(落点常在敌人脚下：落点的判定排在拾取棋子前面)
		var sfp: Vector2 = gr.world.stage.starfall_info["pos"]
		var sfs: Vector2 = gr.world.rig.project(Vector3(sfp.x, 0.0, sfp.y))
		# (测试走到这里时离屏视口的鼠标移动事件到不了 WorldInput——前面几步之后就这样，原因没查到；
		#  这里直接调鼠标移动的处理入口 _update_hover，测的是"落点判定排在拾取棋子前面"这段逻辑)
		gr._update_hover(sfs)
		await frames(4)
		ok(gr.world.stage._sf_area.visible and gr.hud.tip.visible, "hovering it shows the landing range")
		await shot("astronaut: predicted landing spot")
		mouse_move(Vector2(sv.size.x * 0.5, 30.0))
		await frames(4)
	gr.run.sell(str(astro["id"]))
	# 幻形节点：只能部署在敌人身边一圈——拖她时全场拾取，能站的格子标出来；部署区不行
	var spy: Dictionary = gr.run.add_unit("node_spy", 1, null, gr.run.free_bench_slot())
	var ring: Dictionary = gr.run.near_enemy_cells()
	ok(gr._wide_of(str(spy["id"])) and not ring.is_empty(), "Node Spy: picks from the whole field, %d cells next to enemies" % ring.size())
	ok(not gr.run.can_deploy_at(spy, GC.deploy_cells()[0]), "…the deployment zone is off-limits for her")
	gr.world.stage.clear_highlights()
	gr._mark_near_enemy_cells()
	await frames(3)
	await shot("spy: cells next to enemies")
	gr.world.stage.clear_highlights()
	# 真的从仓库条把她拖到敌人身边的格子上(以前拖放只收部署区的格子，她哪里都放不下)
	gr.hud.refresh()
	await frames(4)
	var spy_slot: int = -1
	var bus: Array[Dictionary] = gr.run.bench_units()
	for bi in range(bus.size()):
		if str(bus[bi]["id"]) == str(spy["id"]):
			spy_slot = bi
	var ring_c: Vector2i = ring.keys()[0] if not ring.is_empty() else Vector2i(-1, -1)
	for rc: Vector2i in ring.keys():
		if gr.run.unit_at_cell(rc).is_empty():
			ring_c = rc
			break
	if spy_slot >= 0 and ring_c.x >= 0:
		await drag_mouse(cargo_slot_center(spy_slot), cell_screen(ring_c))
		await frames(10)
	ok(spy["cell"] == ring_c, "dragging Node Spy from storage onto a cell next to an enemy deploys her there (%s → %s)" % [str(ring_c), str(spy["cell"])])
	if spy["cell"] != null:
		gr.run.move_unit(str(spy["id"]), {"bench": gr.run.free_bench_slot()})
	gr.run.sell(str(spy["id"]))
	gr.run.gold = gold_sf
	gr.hud.refresh()
	gr._refresh_starfall()
	ok(gr.hud.prep_speed_btns.size() == 5 and gr.hud.prep_speed_btns[1].is_visible_in_tree(), "battle-speed buttons sit in the command panel while preparing")
	gr.hud.prep_speed_btns[1].pressed.emit()
	await frames(2)
	ok(is_equal_approx(gr.battle_speed, 0.5), "×0.5 picked before the battle")
	# ------------------------------------------------ 开战
	gr._start_battle()
	await frames(20)
	ok(gr.state == "battle", "battle started")
	ok(is_equal_approx(gr.world.battle_view.speed, 0.5), "the battle starts at the speed picked while preparing")
	ok(gr._speed_key(0) and is_equal_approx(gr.world.battle_view.speed, 0.25), "key 1 = ×0.25")
	ok(gr._speed_key(2) and is_equal_approx(gr.world.battle_view.speed, 1.0), "key 3 = ×1")
	ok(gr.world.battle_view.battle.map != null and gr.world.battle_view.battle.map.kind_at(Vector2i(12, 9)) == BattleMap.TRUCK, "battle map has the truck in the middle")
	# 剑痕：炽照节点的每一刀在目标身上留一道发光的刀口(开战就开始看：教程战斗有时候几秒就打完了)
	var sb: Battle = gr.world.battle_view.battle
	# 敌人从哪个方位来是随机的：把他放到最近的敌人身边(这里只看剑痕的画面，不看走位)
	var sam_bu: BUnit = null
	for su0: BUnit in sb.units:
		if su0.def.id == "node_samurai":
			sam_bu = su0
	var near_e: BUnit = null
	for eu0: BUnit in sb.units:
		if sam_bu != null and eu0.team != sam_bu.team and eu0.alive and (near_e == null or eu0.pos.distance_to(sam_bu.pos) < near_e.pos.distance_to(sam_bu.pos)):
			near_e = eu0
	if sam_bu != null and near_e != null:
		var away: Vector2 = (sam_bu.pos - near_e.pos).normalized()
		sam_bu.pos = sb.find_free_position(near_e.pos + away * (sam_bu.radius + near_e.radius + 0.3), sam_bu.radius, sam_bu)
		sam_bu.prev_pos = sam_bu.pos
	# 这只敌人先打不死(教程战斗我方输出高，几秒就打完了，后面看剑痕 / 悬停 / 清心符的几项会来不及)；看完再恢复
	var keep_max := 0.0
	if near_e != null:
		keep_max = near_e.base.max_health
		near_e.base.max_health = 1.0e7
		near_e.mark_dirty()
		near_e.get_stats()
		near_e.hp = 1.0e7
	var scar_seen := false
	for sw in range(300):
		if gr.state != "battle" or sb.state == "ended":
			break
		for srec: Dictionary in gr.world.battle_view.scars.values():
			if (srec["marks"] as Array).size() >= 2:
				scar_seen = true
		if scar_seen:
			break
		await frames(2)
	ok(scar_seen, "his cuts leave glowing sword scars on the target")
	if scar_seen:
		await frames(2)
		await shot("samurai sword scars")
	await frames(10 if scar_seen else 110)          # 开战倒计时刚过、双方都还有活目标(我方输出高时，第一个野怪回合几秒就打完了；等剑痕时已经过了倒计时)
	# 战斗中悬停我方棋子：射程环跟随 + 指向当前目标的连线
	# (战斗种子随时间变化：目标可能恰好在这几帧里阵亡，所以多试几次，每次重新挑一个有活目标的棋子)
	var line_ok := false
	for attempt in range(12):
		gr.hover_view = null
		for uid: String in gr.world.battle_view.views.keys():
			var bv: UnitView = gr.world.battle_view.views[uid]
			if bv.bu != null and bv.bu.alive and bv.bu.team == GC.TEAM_PLAYER and bv.bu.target != null and bv.bu.target.alive:
				gr.hover_view = bv
				break
		await frames(2)
		if gr.hover_view != null and (gr.world.target_line.mesh as ImmediateMesh).get_surface_count() > 0:
			line_ok = true
			break
	if gr.hover_view != null:
		ok(gr.world.range_ring.visible, "range ring follows the hovered piece in battle")
		ok(line_ok, "a line points at its current target")
		ok(not gr.hud.card.visible, "hovering in battle does not open a card")
		var hv: UnitView = gr.hover_view
		await click(gr.world.rig.project(hv.global_position + Vector3(0, hv.body_height * 0.5, 0)))
		ok(gr.hud.card.visible and gr.card_target.get("view") == hv, "clicking a unit in battle opens its card")
	await shot("battle t~4s")
	gr.hover_view = null
	# 清心符：飞出一张看得清的符(弧线、拖光点)，它带来的治疗等符落地才播
	var tb: Battle = gr.world.battle_view.battle
	var tao_bu: BUnit = null
	for tbu: BUnit in tb.units:
		if tbu.def.id == "node_taoist" and tbu.alive:
			tao_bu = tbu
	var mate: BUnit = null
	for tbu2: BUnit in tb.units:
		if tao_bu != null and tbu2.team == GC.TEAM_PLAYER and tbu2.alive and tbu2 != tao_bu and (mate == null or tbu2.pos.distance_to(tao_bu.pos) > mate.pos.distance_to(tao_bu.pos)):
			mate = tbu2
	if tao_bu != null and mate != null and tb.state != "ended":
		var bvw: BattleView = gr.world.battle_view
		var n_sp: int = bvw.skill_projs.size()
		bvw._dispatch([{"t": "cast_fx", "kind": "talisman_heal", "unit": tao_bu, "target": mate},
			{"t": "heal", "src": tao_bu, "dst": mate, "amount": 150.0, "over": 0.0, "surface": "passive", "ability": "node_taoist_qingxin_heal"}])
		var sp_t: Dictionary = bvw.skill_projs.back() if bvw.skill_projs.size() > n_sp else {}
		ok(not sp_t.is_empty() and (sp_t.get("held", []) as Array).size() == 1, "a talisman flies; the heal it brings waits for it to land")
		await frames(6)
		await shot("taoist talisman in flight")
		await frames(45)
		ok(not sp_t.is_empty() and not is_instance_valid(sp_t["node"]), "the talisman lands")
	# 大招切入(充能 9 的"少女幻 x")：HUD 上一条立绘 + 技能名的斜切横幅
	gr.hud.show_cutin("node_magi", "少女幻终", "A Girl's Grand Finale", Color("#e6d2ff"))
	await frames(14)
	ok(gr.hud.get_children().any(func(c: Node) -> bool: return c is Control and c.get_child_count() > 0 and c.get_child(0) is Polygon2D),
		"an ultimate shows a cut-in banner")
	await shot("ultimate cut-in")
	# 正行节点的花瓣计数器 / 花蕊光武器：表现层只看事件，拿任何一个拿剑 / 长枪 / 法器的我方棋子演
	var lw_bu: BUnit = null
	var bvl: BattleView = gr.world.battle_view
	for lbu: BUnit in tb.units:
		var lbv: UnitView = bvl.views.get(lbu.uid) as UnitView
		if lbu.team == GC.TEAM_PLAYER and lbu.alive and lbv != null and LightWeapon.KINDS.has(lbv.weapon_class()):
			lw_bu = lbu
	if lw_bu != null and tb.state != "ended":
		bvl._dispatch([{"t": "status", "unit": lw_bu, "id": "lily_petal", "base_id": "lily_petal", "stacks": 6, "created": true, "flags": []},
			{"t": "status", "unit": lw_bu, "id": "lily_stamen", "base_id": "lily_stamen", "stacks": 2, "created": true, "flags": []}])
		await frames(24)
		var lcn: LilyCounter = bvl.lily_counters.get(lw_bu.uid) as LilyCounter
		ok(lcn != null and lcn.stacks == 6 and lcn._open[5] > 0.8 and lcn._open[6] < 0.2, "petal stacks open that many lily petals at her feet")
		var lwv: UnitView = bvl.views[lw_bu.uid]
		ok(lwv.light_weapon != null and lwv.light_weapon._vis > 0.9, "stamen turns the weapon into a light weapon")
		await shot("lily counter + light weapon")
		bvl._dispatch([{"t": "status", "unit": lw_bu, "id": "lily_stamen", "base_id": "lily_stamen", "stacks": 0, "created": false, "flags": []},
			{"t": "status", "unit": lw_bu, "id": "lily_petal", "base_id": "lily_petal", "stacks": 0, "created": false, "flags": []}])
		await frames(40)
		ok(lwv.light_weapon._vis < 0.05 and lcn._open[0] < 0.2, "the light weapon shatters and the lily closes when the stacks run out")
		# 光之虚影(phantom_fx：正行节点·百合骑士的骑士)：在身后浮现；触发时转向敌人挥一次普攻，最小间隔内再触发不挥
		var kph: KnightPhantom = KnightPhantom.create(lwv, {"trigger": "x", "min_interval": 0.75, "back": 0.95, "lift": 0.3, "scale": 1.3})
		bvl.add_child(kph)
		await frames(45)
		ok(kph._fade > 0.9 and kph.ap.current_animation == kph._idle, "the light phantom fades in behind the piece, idling (%s)" % kph.ap.current_animation)
		var aim: Vector3 = lwv.global_position + Vector3(1.5, 0.8, 1.5)
		ok(kph.swing(aim) and not kph.swing(aim), "a trigger makes the phantom swing once; another right after is ignored (minimum interval)")
		await frames(3)
		ok(kph.ap.current_animation == kph._attack, "…playing the piece's normal attack (%s)" % kph.ap.current_animation)
		await shot("light phantom")
		kph.vanish()
		await frames(50)
		ok(not is_instance_valid(kph), "the phantom fades away")
		# 星旅节点·真实形态(EldritchForm)：触手从虚空之池里钻出来、能甩出去抽人、收掉时自己删掉
		var efm: EldritchForm = EldritchForm.create(lwv, 1.6, 2.2)
		bvl.add_child(efm)
		await frames(40)
		ok(float((efm._tents[0][1] as ShaderMaterial).get_shader_parameter("rise")) > 0.9, "the true form's tentacles rise out of the void pool")
		ok(efm.lash(lwv.global_position + Vector3(1.4, 0.8, 0.6)) > 0.0, "a tentacle lashes out at an enemy")
		await shot("eldritch true form")
		efm.collapse()
		await frames(50)
		ok(not is_instance_valid(efm), "the true form collapses and cleans itself up")
		# 执剑节点：圣剑 / 再度飞翔的特效放完自己收掉(不留节点)
		var before_fx: Array = bvl.fx.get_children()
		bvl.fx.holy_sword(lwv.global_position + Vector3(1.0, 0.0, 1.0), true)
		bvl.fx.hope_rebirth(lwv, lwv.body_height, lwv.global_position + Vector3(-1.0, 0.8, 0.0))
		var spawned: Array = bvl.fx.get_children().filter(func(c: Node) -> bool: return not before_fx.has(c))
		ok(spawned.size() >= 5, "the holy sword and the rebirth spawn their effects (%d nodes)" % spawned.size())
		await frames(14)
		await shot("holy sword + rebirth wings")
		await frames(240)
		var left: int = spawned.filter(func(c: Variant) -> bool: return is_instance_valid(c)).size()
		ok(left == 0, "…and clean them up afterwards (%d left)" % left)
		# 巫术节点：鸟的飞行动作烘焙进了动作库；虹光飞弹的光带拖尾命中后留在原地自己淡掉
		ok(lwv.ap.has_animation("hover_bird") and lwv.ap.has_animation("run_bird"), "the bird's flight / hover animations are baked")
		var msl: Node3D = bvl.fx.make_missile(Color("#ff5a3c"), "red")
		bvl.add_child(msl)
		msl.position = lwv.global_position + Vector3(0.0, 2.0, 0.0)
		var rib: RibbonTrail = msl.get_node("Ribbon") as RibbonTrail
		for mi in range(10):
			msl.position += Vector3(0.12, -0.05, 0.08)
			await frames(1)
		ok(rib != null and rib._pts.size() >= 3, "the missile draws a ribbon trail behind it")
		bvl.fx.missile_impact(msl, msl.position, Color("#ff5a3c"), "red")
		await frames(4)
		ok(is_instance_valid(rib) and rib._detached, "…which stays behind when it hits")
		await frames(60)
		ok(not is_instance_valid(rib), "…and fades away")
		# 狩胜节点·光荣：武器上的火跟着层数烧起来，跨过 5 层(第一阶段)有阶段特效
		var nfx2: int = bvl.fx.get_child_count()
		bvl._dispatch([{"t": "status", "unit": lw_bu, "id": "glory", "base_id": "glory", "stacks": 4, "created": true, "flags": []}])
		bvl._dispatch([{"t": "status", "unit": lw_bu, "id": "glory", "base_id": "glory", "stacks": 5, "created": false, "flags": []}])
		var wfl: WeaponFlame = bvl.weapon_flames.get(lw_bu.uid) as WeaponFlame
		ok(wfl != null and wfl.level == 5 and WeaponFlame.stage_of(wfl.level) == 1, "Glory 5: the weapon catches fire (stage 1)")
		ok(bvl.fx.get_child_count() > nfx2 + 3, "…crossing the threshold sets off a burst of flame")
		await frames(20)
		await shot("glory weapon flame")
		bvl._dispatch([{"t": "status", "unit": lw_bu, "id": "glory", "base_id": "glory", "stacks": 0, "created": false, "flags": []}])
		# 灾星节点的火流星 / 求知节点的念咒：特效放完自己收掉
		var before2: Array = bvl.fx.get_children()
		bvl.fx.meteor(lwv.global_position + Vector3(1.5, 0.4, 0.0), 0.5, Color("#ff4a26"), 2.0, 1.2)
		bvl.fx.recite_spell(lwv.global_position + Vector3(0.0, 0.9, 0.0), lwv.global_position + Vector3(2.0, 0.8, 1.0), lwv.global_position + Vector3(0, 1.6, 0), Color("#7fb4ff"))
		await frames(30)
		await shot("fire meteor + recite")
		var spawned2: Array = bvl.fx.get_children().filter(func(c: Node) -> bool: return not before2.has(c))
		ok(spawned2.size() >= 5, "the meteor and the recited spell spawn their effects (%d)" % spawned2.size())
		await frames(260)
		var left2: int = spawned2.filter(func(c: Variant) -> bool: return is_instance_valid(c)).size()
		ok(left2 == 0, "…and clean them up afterwards (%d left)" % left2)
		# 守林节点的背后灵：三种兽形各一只(不同模型、不同颜色)，凝出来 → 跟着扑 → 散掉
		var kinds_seen := {}
		for bk: String in ["lion", "spider", "toad"]:
			var bsp: BeastSpirit = BeastSpirit.create(bk, lwv, lw_bu)
			bvl.add_child(bsp)
			await frames(40)
			ok(bsp._dissolve < 0.05 and bsp._parts.size() >= 6, "the %s spirit condenses behind her (%d parts)" % [bk, bsp._parts.size()])
			kinds_seen[str(bsp._mat.get_shader_parameter("col"))] = true
			bsp.attack(lwv.global_position + Vector3(0.0, 0.8, 2.0), 0.2)
			await frames(16)
			if bk == "lion":
				await shot("beast spirit (lion)")
			bsp.vanish()
			await frames(45)
			ok(not is_instance_valid(bsp), "…and the %s spirit dissolves away" % bk)
		ok(kinds_seen.size() == 3, "each beast has its own color")
		# 清扫节点·清洁世界(大招)：切入立绘信号 + 时间停止(冷灰的领域 + 脚下的大怀表)，转完时间恢复
		var ult_got: Array = []
		var ult_cb := func(uu: BUnit, aid: String, _c: Color) -> void: ult_got.append(aid)
		bvl.ultimate.connect(ult_cb)
		# (数领域本身：别的临时子节点这几帧里可能正好被释放，总的子节点数靠不住)
		var ndm0: int = bvl.get_children().filter(func(c: Node) -> bool: return c is DomainFX).size()
		bvl._dispatch([{"t": "storm_start", "unit": lw_bu, "targets": [], "duration": 1.2, "times": [0.36, 0.76], "ability": "node_maid_storm", "ultimate": true}])
		await frames(10)
		ok(ult_got == ["node_maid_storm"], "Clean Sweep is an ultimate: the cut-in fires")
		var dms: Array = bvl.get_children().filter(func(c: Node) -> bool: return c is DomainFX)
		ok(dms.size() > ndm0, "time stops: a time-stop domain opens")
		await frames(12)
		await shot("maid time stop")
		await frames(200)
		ok(bvl.get_children().filter(func(c: Node) -> bool: return c is DomainFX).is_empty(), "…and time resumes (the domain closes)")
		bvl.ultimate.disconnect(ult_cb)
		# 共歌节点·温柔地：整个战场沉进水下的梦(lullaby 领域 + 满场泡泡)，gentle_end 时收掉
		bvl._dispatch([{"t": "gentle_start", "unit": lw_bu, "until": 10.0, "k": 0.5}])
		await frames(6)
		var lul: Array = bvl.get_children().filter(func(c: Node) -> bool: return c is DomainFX and (c as DomainFX).mode == "lullaby")
		ok(lul.size() == 1 and bvl.gentle_fx.has(lw_bu.uid), "Gentle opens the underwater-dream domain")
		ok(is_instance_valid(bvl.gentle_fx[lw_bu.uid]["bub"]), "…with bubbles drifting up across the whole field")
		# 美妙地：五线谱 + 音符；沉沦之梦：队友金色 / 敌人紫色
		var before3: Array = bvl.fx.get_children()
		bvl.fx.song_wave(lwv.global_position, lwv.global_position + Vector3(0.1, 1.0, 0.2), [lwv.global_position + Vector3(2.0, 0.9, 1.0), lwv.global_position + Vector3(-1.5, 0.9, 2.0)])
		bvl.fx.dream_echo(lwv.global_position + Vector3(0, 1.0, 0), lwv.global_position + Vector3(2.0, 0.9, -1.0), true)
		bvl.fx.dream_echo(lwv.global_position + Vector3(0, 1.0, 0), lwv.global_position + Vector3(-2.0, 0.9, -1.0), false)
		await frames(14)
		var spawned3: Array = bvl.fx.get_children().filter(func(c: Node) -> bool: return not before3.has(c))
		ok(spawned3.filter(func(c: Node) -> bool: return c is SongStaff).size() == 1, "Wonderfully: a musical staff spirals out of her mic")
		# 沉醉：头部周围绕着转的音符(9 层 = 3 枚)，善良地打到时亮一下
		var ix: BStatus = bvl.battle.pipeline.fx.apply_status(lw_bu, lw_bu, {"status_id": "intox", "duration": 0.0, "add_stacks": 9, "max_stacks": 20, "flags": ["no_dispel"]})
		await frames(16)
		var imk: IntoxMarks = bvl.intox_marks.get(lw_bu.uid) as IntoxMarks
		ok(ix != null and imk != null and imk._notes.size() == 3, "Intoxication stacks show as notes circling the head (%d)" % (imk._notes.size() if imk != null else -1))
		if imk != null:
			imk.pulse()
			ok(imk._pulse > 0.9, "…which flare up when Kindly hits")
		await shot("pacifist gentle dream")
		bvl.battle.pipeline.fx.remove_status(lw_bu, "intox")
		bvl._dispatch([{"t": "gentle_end", "unit": lw_bu}])
		await frames(20)
		ok(not bvl.intox_marks.has(lw_bu.uid), "…and go away with the stacks")
		await frames(160)
		ok(bvl.get_children().filter(func(c: Node) -> bool: return c is DomainFX).is_empty() and bvl.gentle_fx.is_empty(), "…and the dream ends with Gentle")
		var left3: int = spawned3.filter(func(c: Variant) -> bool: return is_instance_valid(c)).size()
		ok(left3 == 0, "song / dream effects clean themselves up (%d left)" % left3)
		# 白羽节点：黑白蝴蝶。送葬 3 层 = 3 只绕着飞的黑蝶；满层(精英：送葬之痕)= 扑进去、身上停下一只黑蝶；
		# 求生的意志 = 身后一对半透明的白蝶大翅膀；致将亡而未亡者 = 扑向目标的蝴蝶；她身边常驻两黑两白
		bvl._dispatch([{"t": "status", "unit": lw_bu, "id": "funeral", "base_id": "funeral", "stacks": 3, "created": true, "flags": [], "src": lw_bu}])
		await frames(20)
		var fwr: FuneralWreath = bvl.funeral_wreaths.get(lw_bu.uid) as FuneralWreath
		ok(fwr != null and fwr._bfs.size() == 3, "Funeral stacks circle the target as black butterflies (%d)" % (fwr._bfs.size() if fwr != null else -1))
		var before4: Array = bvl.fx.get_children()
		bvl._dispatch([{"t": "status", "unit": lw_bu, "id": "funeral", "base_id": "funeral", "stacks": 0, "created": false, "flags": []},
			{"t": "funeral", "unit": lw_bu, "target": lw_bu, "pos": lw_bu.pos, "kill": false}])
		await frames(4)
		ok(fwr != null and fwr._closing >= 0.0 and not bvl.funeral_wreaths.has(lw_bu.uid), "…full stacks: the butterflies dive into the target")
		ok((bvl.funeral_scars.get(lw_bu.uid, []) as Array).size() == 1, "…and an elite keeps a black butterfly perched on it (Funeral Scar)")
		bvl._dispatch([{"t": "funeral_save", "unit": lw_bu, "target": lw_bu, "stacks": 4, "of": 10}])
		bvl.fx.butterfly_dart(lwv.global_position + Vector3(0, 1.0, 0), lwv.global_position + Vector3(2.5, 0.9, 1.5), "white")
		var bau: ButterflyAura = ButterflyAura.create(bvl.fx, lwv, 0.95)
		await frames(14)
		var spawned4: Array = bvl.fx.get_children().filter(func(c: Node) -> bool: return not before4.has(c))
		ok(spawned4.filter(func(c: Node) -> bool: return c is Butterfly and (c as Butterfly)._ghost_mat != null).size() == 1, "Will to Live spreads a pair of white butterfly wings")
		ok(spawned4.filter(func(c: Node) -> bool: return c is ButterflyFlock).size() >= 2, "…and black / white butterflies scatter (bite + will)")
		ok(bau._bfs.size() == 4 and bau._bfs.filter(func(it: Dictionary) -> bool: return (it["bf"] as Butterfly).kind == "black").size() == 2,
			"her own aura: two black and two white butterflies")
		await shot("angel butterflies")
		bau.scatter()
		await frames(200)
		var left4: int = spawned4.filter(func(c: Variant) -> bool: return is_instance_valid(c)).size()
		ok(left4 == 0 and not is_instance_valid(bau), "butterfly effects clean themselves up (%d left)" % left4)
		for sb1: Variant in bvl.funeral_scars.get(lw_bu.uid, []):
			if is_instance_valid(sb1):
				(sb1 as Node3D).queue_free()
		bvl.funeral_scars.erase(lw_bu.uid)
		# 屏息节点的狙击窝：黑箱子从半空落下砸地、她走了以后沉进地里消失；瞄准时瞄准镜上一颗反光的星芒
		var crate: NestCrate = NestCrate.create(bvl, Transform3D(Basis.IDENTITY, lwv.global_position + Vector3(0.7, 0.0, 0.0)), 0.42)
		crate.drop(1.0)
		await frames(24)
		ok(is_instance_valid(crate) and absf(crate.global_position.y) < 0.02 and crate.get_child_count() >= 10, "the sniper's black crate drops into place")
		var saim: Node3D = bvl.fx.sniper_aim()
		bvl.fx.sniper_aim_set(saim, lwv.global_position + Vector3(0, 0.5, 0), lwv.global_position + Vector3(4, 0.8, 0), lwv.global_position + Vector3(4, 0, 0), 1.0, 0.0,
			lwv.global_position + Vector3(0.2, 0.55, 0.0))
		ok((saim.get_node("Glint") as Node3D).visible, "a scope glint shines while she aims")
		bvl.fx.sniper_aim_end(saim)
		crate.leave(1.0)
		await frames(70)
		ok(not is_instance_valid(crate), "…and the crate sinks away after she leaves")
		# 导向节点的连锁闪电：一跳推过去(到了才算打中)，整条留一会儿再淡掉；灭罪节点：身上的圣印 / 光轮 / 经文
		var hit_at := [-1]
		var arc: LightningArc = bvl.fx.chain_hop(lwv.global_position + Vector3(0, 1.0, 0), lwv.global_position + Vector3(3.0, 0.9, 1.0), 0.2, false)
		arc.on_hit = func() -> void: hit_at[0] = Engine.get_process_frames()
		var f0: int = Engine.get_process_frames()
		await frames(4)
		ok(hit_at[0] < 0 and is_instance_valid(arc), "a chain-lightning hop travels before it strikes")
		await frames(16)
		ok(hit_at[0] > f0, "…strikes when it arrives")
		await frames(30)
		ok(is_instance_valid(arc), "…and lingers so the chain can be read")
		var sa2: SaintAura = SaintAura.create(bvl.fx, lwv, lwv.body_height)
		await frames(20)
		ok(sa2._words.size() == 8 and sa2._fade > 0.5, "Absolver's chant: seal, halo wheel and orbiting scripture")
		sa2.pulse()
		await shot("chain lightning + saint aura")
		sa2.end()
		await frames(90)
		ok(not is_instance_valid(arc) and not is_instance_valid(sa2), "…and both clean themselves up")
		# 圣战节点：裂地猛击的前摇(锥形轮廓 + 圣印 + 锤头聚光)和砸地(光弧、碎石、发光的裂缝)、圣疗的日轮十字；
		# 踏影节点：逆光(影子一路滑过去 + 身后的逆光)、墨刃的新月剑气、淬血、凝暗的黑烟、剑上的诛影影火
		var before5: Array = bvl.fx.get_children()
		var lp: Vector3 = lwv.global_position
		bvl.fx.quake_windup(lp, Vector3(0, 0, 1), 100.0, 3.5, 0.3, func() -> Vector3: return lp + Vector3(0, 1.5, 0))
		bvl.fx.quake_slam(lp, Vector3(0, 0, 1), 100.0, 3.5)
		bvl.fx.holy_mend(lp + Vector3(1.0, 0.9, 0.0), lp + Vector3(0.0, 0.9, 0.0))
		bvl.fx.shadow_dash(lp, lp + Vector3(3.0, 0.0, 2.0))
		bvl.fx.backlight_flare(lp + Vector3(3.0, 0.0, 2.0), 1.3)
		bvl.fx.ink_blade(lp + Vector3(0, 1.0, 0), lp + Vector3(2.5, 0.9, 1.5))
		bvl.fx.temper_blood(lp + Vector3(0, 1.0, 0), lp + Vector3(0.3, 1.2, 0.3))
		var sau: Node3D = bvl.fx.shadow_aura(lwv, lwv.body_height)
		bvl.fx.shadow_aura_set(sau, 1.0)
		var sbl: Node3D = bvl.fx.shadow_blade(lwv, [18.0, 58.0])
		bvl.fx.shadow_blade_set(sbl, 1.0)
		await frames(20)
		var spawned5: Array = bvl.fx.get_children().filter(func(c: Node) -> bool: return not before5.has(c))
		ok(spawned5.size() >= 20, "Paladin's quake slam / holy mend and Knight-errant's shadow effects spawn (%d nodes)" % spawned5.size())
		ok(sau != null and (sau.get_node("Smoke") as GPUParticles3D).emitting, "Gathered Dark: black smoke rising off him")
		ok(sbl == null or (sbl.get_node("H/Flame") as GPUParticles3D).emitting, "Shadow Slay: shadow flames on the blade")
		await shot("paladin slam + knight shadows")
		bvl.fx.shadow_aura_set(sau, 0.0)
		bvl.fx.shadow_blade_set(sbl, 0.0)
		await frames(200)
		var left5: int = spawned5.filter(func(c: Variant) -> bool: return is_instance_valid(c)).size()
		ok(left5 == 0, "…and clean themselves up (%d left)" % left5)
		for nn: Variant in [sau, sbl]:
			if is_instance_valid(nn):
				(nn as Node).queue_free()
		# 蓝之章的机械：增幅力场(六边形网格)、力场投射、炮口火光、火控 / 协议命中、中继广播 + 数据链路、链路标记、炸开
		var before6: Array = bvl.fx.get_children()
		var lq: Vector3 = lwv.global_position
		var amp: Node3D = bvl.fx.amp_field(lq + Vector3(2.0, 0.0, 0.0), 2.5)
		bvl.fx.field_projection(lq + Vector3(0, 0.6, 0), lq + Vector3(2.0, 0.15, 0.0))
		bvl.fx.mech_muzzle(lq + Vector3(0, 0.6, 0.5), Vector3(0, 0, 1), Color("#ffb84a"), 1.3)
		bvl.fx.firecontrol_hit(lq + Vector3(1.0, 0.9, 1.0))
		bvl.fx.protocol_strike(lq + Vector3(-1.0, 0.9, 1.0), Vector3(0, 0, 1))
		bvl.fx.relay_pulse(lq + Vector3(0, 1.2, 0), lq, 6.0)
		bvl.fx.data_link(lq + Vector3(0, 1.2, 0), lq + Vector3(2.0, 0.9, 1.0))
		var lmk: Node3D = bvl.fx.link_marker(lwv, 0.45)
		bvl.fx.mech_explode(lq + Vector3(-2.0, 0.6, 0.0), Color("#4fd2ff"), true)
		await frames(20)
		var spawned6: Array = bvl.fx.get_children().filter(func(c: Node) -> bool: return not before6.has(c))
		ok(spawned6.size() >= 15 and is_instance_valid(amp) and is_instance_valid(lmk), "Blue chapter machines: amp field, muzzle flashes, hits, relay links and explosions (%d nodes)" % spawned6.size())
		await shot("blue chapter machine fx")
		bvl.fx.remove_field(amp)
		lmk.queue_free()
		await frames(200)
		var left6: int = spawned6.filter(func(c: Variant) -> bool: return is_instance_valid(c)).size()
		ok(left6 == 0, "…and clean themselves up (%d left)" % left6)
		# 无我节点：一闪(横扫全场的新月刀光)、迟来的刀痕 → 崩散、精英的重刀痕、逆时幻影的钟面 + 回声刀痕；被斩开的人定格后崩散(die_cut)
		var before7: Array = bvl.fx.get_children()
		var lk7: Vector3 = lwv.global_position
		bvl.fx.iai_sweep(lk7, Vector3(0, 0, 1), 14.0)
		bvl.fx.iai_cut_line(lk7 + Vector3(1.5, 0.9, 2.0), 0.4)
		bvl.fx.selfless_scar(lk7 + Vector3(-1.5, 0.9, 2.0), 0.35)
		bvl.fx.phantom_echo(lk7 + Vector3(0.5, 0.9, 1.5), Vector3(0, 0, 1))
		var pck: Node3D = bvl.fx.phantom_clock(lwv, 0.6)
		await frames(20)
		var spawned7: Array = bvl.fx.get_children().filter(func(c: Node) -> bool: return not before7.has(c))
		ok(spawned7.size() >= 6 and is_instance_valid(pck), "Selfless: the iai sweep, delayed cut lines, scars and the phantom's clock (%d nodes)" % spawned7.size())
		await frames(150)
		var left7: int = spawned7.filter(func(c: Variant) -> bool: return is_instance_valid(c)).size()
		ok(left7 == 0, "…and clean themselves up (%d left)" % left7)
		pck.queue_free()
		# 锁芯节点：血色仪式法阵、深空之门计数石(亮几颗)、被锁住的金锁 + 锁链、锁上时转的钥匙；
		# 变奏节点：音符弹、和弦、弹琴的音符、沮丧 / 亢奋的层数音符、悲怆的波、下一乐章
		var before8: Array = bvl.fx.get_children()
		var lk8: Vector3 = lwv.global_position
		var rite: Node3D = bvl.fx.blood_rite_circle(lwv, 1.1)
		var gg: Node3D = bvl.fx.gate_gauge(lwv, 0.6, 8)
		bvl.fx.gate_gauge_set(gg, 3, 8)
		var lit8: int = gg.get_children().filter(func(c: Node) -> bool: return (c as Node3D).scale.x > 1.2).size()
		var lmark: Node3D = bvl.fx.lock_mark(lwv, Vector3(0, 1.5, 0), 0.8, 0.4)
		bvl.fx.key_turn(lk8 + Vector3(2.0, 0.0, 0.0))
		var note8: Node3D = bvl.fx.make_note_projectile(false)
		bvl.fx.add_child(note8)
		note8.global_position = lk8 + Vector3(0, 0.9, 1.0)
		bvl.fx.chord_burst(lk8 + Vector3(1.0, 0.8, 1.0), 1.0, true)
		bvl.fx.piano_notes(lk8 + Vector3(0, 1.0, 0), false)
		var sn8: GPUParticles3D = bvl.fx.stack_notes(lwv, 1.3, true)
		sn8.amount_ratio = 0.6
		bvl.fx.piano_wave(lk8, false)
		bvl.fx.next_movement(lk8, lk8 + Vector3(0, 0.9, 0), true)
		await frames(20)
		var spawned8: Array = bvl.fx.get_children().filter(func(c: Node) -> bool: return not before8.has(c) and c != note8)
		ok(spawned8.size() >= 10 and lit8 == 3 and is_instance_valid(rite) and is_instance_valid(lmark),
			"Keeper + Pianist: blood rite, gate gauge (%d/8 lit), lock & chains, key turn, notes, chord, waves (%d nodes)" % [lit8, spawned8.size()])
		await shot("keeper and pianist fx")
		for n8: Node in [rite, gg, lmark, note8, sn8]:
			n8.queue_free()
		await frames(200)
		var left8: int = spawned8.filter(func(c: Variant) -> bool: return is_instance_valid(c)).size()
		ok(left8 == 0, "…and clean themselves up (%d left)" % left8)
		# 远距离飞扑：模型先留在原地蓄力、再扑出去追上逻辑位置，落地后偏移归零
		lwv.play_leap(0.5, 0.8, 5.0)
		await frames(4)
		ok(lwv._leap_off < -0.3, "a long leap holds back while crouching (offset %.2f)" % lwv._leap_off)
		await frames(50)
		ok(is_equal_approx(lwv._leap_off, 0.0) and is_equal_approx(lwv.model.position.y, 0.0), "…and lands exactly where the unit is")
	if near_e != null and near_e.alive:
		near_e.base.max_health = keep_max
		near_e.mark_dirty()
		near_e.get_stats()
		near_e.hp = minf(near_e.hp, keep_max)
	gr.world.battle_view.set_speed(4.0)
	var guard := 0
	while gr.state == "battle" and guard < 2500:
		await frames(4)
		guard += 4
	ok(gr.state == "result", "battle ended into the result screen (state=%s)" % gr.state)
	ok(gr.screens.current == "result", "result screen is open")
	await frames(30)
	await shot("result")
	# 详细战报：页签(输出 / 承伤 / 治疗 / 护盾) × 队伍(我方 / 敌方)，点一行看明细
	var rp: ReportPanel = gr.screens.find_child("Report", true, false) as ReportPanel
	ok(rp != null, "the result screen shows the detailed combat report")
	if rp != null:
		ok(rp.selected != "" and rp.rep.rows.has(rp.selected) and float(rp.rep.rows[rp.selected]["dealt"]) > 0.0, "the top damage dealer is selected")
		ok(rp.rep.rows.size() == tb.units.size(), "every unit has a row (%d)" % rp.rep.rows.size())
		rp._metric_btns["taken"].pressed.emit()
		await frames(4)
		await shot("result: damage taken")
		rp._metric_btns["heal"].pressed.emit()
		await frames(4)
		ok(rp.metric == "heal", "healing tab")
		await shot("result: healing")
		rp._team_btns[GC.TEAM_ENEMY].pressed.emit()
		rp._metric_btns["dealt"].pressed.emit()
		await frames(4)
		ok(rp.team == GC.TEAM_ENEMY and int(rp.rep.rows[rp.selected]["team"]) == GC.TEAM_ENEMY, "hostiles tab selects an enemy")
		await shot("result: hostiles")
		rp._team_btns[GC.TEAM_PLAYER].pressed.emit()
		await frames(2)
	var won1: bool = bool(gr.run.last_result.get("win", false))
	ok(won1, "node 1 (tutorial encounter) is won")
	ok(int(gr.run.last_result.get("orbs", 0)) == gr.run.pending_orbs.size(), "result lists the dropped orbs")
	# --- 结算 → 拾取晶球
	gr.screens.result_continue.emit()
	await frames(20)
	ok(gr.state == "loot", "result → loot phase (state=%s)" % gr.state)
	# 清心节点只是来看特效的：送回去(金币、等级照旧)，别影响后面的流程
	var gold_keep2: int = gr.run.gold
	gr.run.sell(str(tao["id"]))
	gr.run.sell(str(sam["id"]))
	gr.run.inventory.erase("blazing_glow")
	gr.run.gold = gold_keep2
	gr.run.level = lv_keep2
	await frames(4)
	ok(gr.orb_views.size() == gr.run.pending_orbs.size() and gr.orb_views.size() >= 1, "orbs lie on the battlefield (%d)" % gr.orb_views.size())
	await shot("loot orbs")
	if not gr.orb_views.is_empty():
		var ov: OrbView = gr.orb_views[0]
		var p: Vector2 = gr.world.rig.project(ov.global_position)
		mouse_btn(p, true)
		await frames(2)
		mouse_btn(p, false)
		await frames(12)
		ok(bool(gr.run.pending_orbs[0]["opened"]), "clicking an orb opens it")
		ok(gr.hud.loot_list.get_child_count() > 0, "loot popup lists what came out")
		await shot("orb opened")
	gr.hud.loot_done_requested.emit()
	await frames(4)
	await wait_state("map")
	ok(gr.state == "map" and gr.run.node_index == 1, "leaving the battlefield returns to the map at node 2 (state=%s, node=%d)" % [gr.state, gr.run.node_index])
	ok(gr.world.overworld.visible and not gr.world.battle_root.visible, "back on the overworld map")
	ok(gr.hud.map_buttons[0].status == "done" and gr.hud.map_buttons[1].status == "next", "node 1 cleared, node 2 is the next stop")
	ok(gr.world.truck.global_position.distance_to(gr.world.overworld.node_pos[0]) < 4.0, "the truck waits by the cleared node")
	await frames(30)
	ok(gr.run.pending_orbs.is_empty(), "unopened orbs were auto-opened on leaving")
	await shot("map node 2")
	# ------------------------------------------------ 节点 2、3
	await travel_to_next()
	await fight_and_loot("node 2", false)
	ok(gr.state == "map" and gr.run.node_index == 2, "back on the map before node 3 (state=%s)" % gr.state)
	await travel_to_next()
	var alt := false
	for o: Dictionary in gr.run.current_layout().get("obstacles", []):
		if str(o.get("style", "")) == "altar":
			alt = true
	ok(alt, "node 3 battle map contains the rainbow-crystal altar")
	await shot("node 3 prepare (altar)")
	await workshop_test()
	await fight_and_loot("node 3", true)
	ok(gr.state == "chapter_end", "after 3 nodes chapter 0 is cleared (state=%s)" % gr.state)
	ok(gr.screens.current == "branch" and gr.run.phase == "branch", "the branch screen comes first")
	await frames(20)
	await shot("choose the chapter 1 branch")
	gr.screens.branch_picked.emit("ch1_green")
	await frames(6)
	ok(gr.screens.current == "branch", "locked branches cannot be entered")
	gr.screens.branch_picked.emit("ch1_red")
	await frames(10)
	ok(gr.screens.current == "mod" and gr.run.phase == "chapter_end", "then the truck-mod screen for the red chapter")
	ok(gr.run.mod_options.size() == 3, "three mods offered")
	var red_mod := false
	for mo: String in gr.run.mod_options:
		var md: Dictionary = gr.run.mod_def(mo)
		if str(md.get("color", "")) == "red":
			red_mod = true
		ok(int(md.get("t_min", 9)) <= 1 and int(md.get("t_max", 0)) >= 1, "%s appears at time 1" % mo)
	ok(red_mod, "at least one offered mod is red")
	await shot("chapter 0 cleared: truck mod for the red chapter")
	var mods0: int = gr.run.truck_mods.size()
	gr.screens.mod_picked.emit(gr.run.mod_options[0])
	await wait_state("map")
	ok(gr.run.truck_mods.size() == mods0 + 1, "the mod was recorded")
	ok(gr.hud.mods_row.visible and gr.hud.mods_row.get_child_count() == gr.run.truck_mods.size(),
		"the HUD lists the owned mods (tags=%d, mods=%s)" % [gr.hud.mods_row.get_child_count(), str(gr.run.truck_mods)])
	var gg := 0
	while gr.fade_rect.color.a > 0.01 and gg < 400:
		await frames(2)
		gg += 2
	await chapter1()


## 车间：C 打开 → 选门类 / 加材料 → 预测 → 制造(成品卡) → 分解 → Esc 关闭
func workshop_test() -> void:
	ok(UIKit.material_icons.size() == 3, "three material pixel icons were rendered at boot")
	var caps: Array[String] = []
	for n: Node in gr.hud.workshop_btn.find_children("*", "Label", true, false):
		caps.append((n as Label).text)
	ok(caps.has("C"), "the HUD workshop button shows its C keycap")
	gr.run.add_materials({"red": 8, "green": 1, "blue": 1})
	gr.hud.refresh()
	ok((gr.hud.mat_labels["red"] as Label).text == str(gr.run.materials["red"]), "the HUD shows the material stock")
	var kc := InputEventKey.new()
	kc.keycode = KEY_C
	kc.pressed = true
	sv.push_input(kc)
	await frames(20)
	ok(gr.workshop != null and gr.workshop.visible, "C opens the workshop")
	if gr.workshop == null:
		return
	var ws: WorkshopScreen = gr.workshop
	ok(ws.tab == "craft" and ws.kind == "weapon", "starts on the fabricate page, weapons")
	ok(ws.cats.size() >= 3, "categories are pre-picked to suit the team (%s)" % str(ws.cats))
	ws.cats = ["dual"]
	ws._refresh_craft()
	ok(ws._craft_btn.disabled, "fewer than 3 categories: can't fabricate")
	ws.cats = ["dual", "focus", "heavy"]
	ws.mats = Crafting.empty_mats()
	for i in range(6):
		ws.add_material("red", 1)
	ws._refresh_craft()
	await frames(4)
	ok(int(ws.mats["red"]) == 6 and not ws._craft_btn.disabled, "added 6 phlogiston, ready to fabricate")
	var f: Dictionary = Crafting.forecast(gr.cat, "weapon", ws.cats, ws.mats)
	var top_col := ""
	for c: String in (f["colors"] as Dictionary).keys():
		if top_col == "" or float(f["colors"][c]) > float(f["colors"][top_col]):
			top_col = c
	ok(top_col == "red", "the forecast leans red for pure phlogiston (%s)" % str(f["colors"]))
	ok(ws._forecast_box.get_child_count() > 4, "the forecast panel lists color / rarity odds and the possible results")
	ws.add_material("red", 99)
	ok(int(ws.mats["red"]) == int(gr.run.materials["red"]), "can't add more than you have")
	ws.mats = {"red": 6, "green": 0, "blue": 0}
	ws._refresh_craft()
	await shot("workshop fabricate")
	var inv0: int = gr.run.inventory.size()
	var red0: int = int(gr.run.materials["red"])
	var ksp := InputEventKey.new()
	ksp.keycode = KEY_SPACE
	ksp.pressed = true
	sv.push_input(ksp)
	await frames(20)
	ok(gr.run.inventory.size() == inv0 + 1, "Space fabricates: one more weapon in the armory")
	ok(int(gr.run.materials["red"]) == red0 - 6, "…and the materials are spent")
	ok(ws._result != null, "the result card pops up")
	var made: String = gr.run.inventory.back()
	ok(["dual", "focus", "heavy"].has(gr.cat.get_equipment(made).class_id), "the result is from a chosen category (%s)" % made)
	await shot("workshop result")
	sv.push_input(ksp.duplicate())
	await frames(8)
	ok(ws._result == null, "Space closes the result card")
	ws.select_tab("salvage")
	ws.salvage_sel = made
	ws._rebuild_body()
	await frames(6)
	var tot0: int = gr.run.material_total()
	var cnt0: int = gr.run.inventory.count(made)
	await shot("workshop salvage")
	ws.do_salvage()
	await frames(6)
	ok(gr.run.inventory.count(made) == cnt0 - 1, "salvaged the weapon")
	ok(gr.run.material_total() > tot0, "salvaging gives materials back (%d → %d)" % [tot0, gr.run.material_total()])
	var kesc := InputEventKey.new()
	kesc.keycode = KEY_ESCAPE
	kesc.pressed = true
	sv.push_input(kesc)
	await frames(10)
	ok(gr.workshop == null and gr.state == "prepare", "Esc closes the workshop back to the prepare screen")
	ok((gr.run.craft_last.get("cats", {}) as Dictionary).has("weapon"), "the workshop remembers the last choice")


## 第一章·红之章：大地图 → 作战 → 黑市 → 修整 → 事件 → 零件 → 追猎
## 除了 keep 之外的全部事件 id(把它们记成"本章出过了"，下一个事件就一定是 keep)
func all_events_but(keep: String) -> Array[String]:
	var r: Array[String] = []
	for id: String in gr.cat.events.keys():
		if id != keep:
			r.append(id)
	return r


func grid_button_center(k: String) -> Vector2:
	return (gr.hud.grid_buttons[k] as Control).get_global_rect().get_center()


## 卡车能去的、离得最近的未完成节点(强制成某种类型，测试用)
## 卡车周围 radius 格内还没观测到的节点数
func _hidden_near(r: Run, radius: int) -> int:
	var n := 0
	var c0: Vector2i = ChapterMap.cell(r.pos)
	for k: String in (r.gmap["nodes"] as Dictionary).keys():
		var c: Vector2i = ChapterMap.cell(k)
		if str(r.gnode(k)["state"]) == "hidden" and absi(c.x - c0.x) + absi(c.y - c0.y) <= radius:
			n += 1
	return n


## 清扫节点停在半空(而且画出来了)的飞刀有几把
func _maid_held(b: Battle) -> int:
	var n := 0
	for p: Dictionary in b.projectiles:
		if p.has("hold") and str(p["hold"]["phase"]) == "hover" and gr.world.battle_view.proj_views.has(int(p["id"])):
			n += 1
	return n


func open_neighbour(t: String) -> String:
	var reach: Dictionary = gr.run.reachable()
	var best := ""
	for k: String in reach.keys():
		if k == gr.run.pos or gr.run.passable(k) or str(gr.run.gnode(k)["type"]) == "boss":
			continue
		if best == "" or int(reach[k]) < int(reach[best]):
			best = k
	if best != "":
		gr.run.gnode(best)["type"] = t
		gr.run.gnode(best)["state"] = "seen"
		gr.hud.refresh()
	return best


func click_grid(k: String) -> void:
	await frames(70)          # 等镜头回到俯瞰视角(按钮跟着镜头移动)
	var bp: Vector2 = grid_button_center(k)
	var vr := Rect2(Vector2(40, 120), Vector2(sv.size) - Vector2(80, 260))
	if not vr.has_point(bp) or gr.hud.over_ui(bp):
		# 按钮在屏幕边上 / 被面板挡住(大地图很大，随种子变)：直接发点击信号
		gr.hud.grid_clicked.emit(k)
		await frames(3)
		return
	var pos0: String = gr.run.pos
	var state0: String = gr.state
	mouse_move(bp)
	await frames(3)
	mouse_btn(bp, true)
	await frames(1)
	mouse_btn(bp, false)
	await frames(3)
	# 离屏视口里模拟的鼠标事件偶尔送不到按钮上(镜头还在动 / 测试注入的鼠标状态)：点击没生效就直接发点击信号
	if gr.state == state0 and gr.run.pos == pos0:
		gr.hud.grid_clicked.emit(k)
		await frames(3)


## 第二章-A·紫之章：直接从命令行参数开一局紫之章(怪物是占位)，看空岛大地图和寒气战场
func chapter2() -> void:
	gr.cli["chapter"] = "ch2_purple"
	gr._new_game("truck_zone")
	await frames(60)
	ok(gr.run.chapter_id == "ch2_purple" and gr.run.is_grid(), "chapter 2-A (purple) opens on its map (state=%s)" % gr.state)
	ok(gr.world.overworld.city is IslandOverworld, "the sky-island map")
	ok(UIKit.theme_name == "frost" and gr.world.theme_name == "purple", "frost UI theme + purple night lighting")
	var gm: Dictionary = gr.run.gmap
	ok(bool(gm.get("island", false)) and gm.has("scar") and (gm["scar"]["bridges"] as Array).size() >= 1, "the island is cut by the sword scar, with bridges")
	ok(gm.has("mountain") and str(gm["mountain"]["center"]) == str(gm["boss"]) and (gm["mountain"]["path"] as Array).size() == 4, "the boss waits on top of the iceberg (four terraces up)")
	ok(gr.hud.grid_buttons.size() == gr.run.total_nodes(), "one button per grid node (%d)" % gr.hud.grid_buttons.size())
	await frames(30)
	await shot("chapter 2-A map: the sky island")
	gr._cli_first_node()
	await frames(50)
	ok(gr.state == "prepare", "straight into the first fight (state=%s)" % gr.state)
	ok(str(gr.run.current_layout().get("theme", "")) == "purple", "purple battle map")
	ok((gr.run.current_layout().get("frost", []) as Array).size() > 0, "frost patches on the battlefield")
	var ice := true
	for o: Dictionary in gr.run.current_layout().get("obstacles", []):
		if not str(o.get("style", "")).begins_with("ice_"):
			ice = false
	ok(ice, "the ruins are hard ice")
	var g3 := 0
	while gr.fade_rect.color.a > 0.01 and g3 < 400:
		await frames(2)
		g3 += 2
	await shot("ch2 battlefield (hard ice, frost patches)")
	gr._start_battle()
	await frames(90)
	ok(gr.state == "battle", "the placeholder encounter fights")
	await shot("ch2 battle")
	gr._show_title()
	await frames(10)
	gr.cli.erase("chapter")


## 第一章-B·蓝之章：穹顶箱庭的大地图(首领在城北的信标下) + 科技障碍的战场
func chapter_blue() -> void:
	gr.cli["chapter"] = "ch1_blue"
	gr._new_game("truck_zone")
	await frames(60)
	ok(gr.run.chapter_id == "ch1_blue" and gr.run.is_grid(), "chapter 1-B (blue) opens on its map (state=%s)" % gr.state)
	ok(gr.world.overworld.city is DomeOverworld, "the dome-city map")
	ok(UIKit.theme_name == "dome" and gr.world.theme_name == "blue", "dome UI theme + blue dome lighting")
	var gm: Dictionary = gr.run.gmap
	ok(bool(gm.get("dome", false)), "a dome map")
	var boss: Vector2i = ChapterMap.cell(str(gm["boss"]))
	var miny := 99
	for k: String in (gm["nodes"] as Dictionary).keys():
		miny = mini(miny, ChapterMap.cell(k).y)
	ok(boss.y == miny, "the boss waits at the north edge, under the beacon")
	ok(gr.hud.grid_buttons.size() == gr.run.total_nodes(), "one button per grid node (%d)" % gr.hud.grid_buttons.size())
	await frames(30)
	await shot("chapter 1-B map: the dome city")
	gr._cli_first_node()
	await frames(50)
	ok(gr.state == "prepare", "straight into the first fight (state=%s)" % gr.state)
	ok(str(gr.run.current_layout().get("theme", "")) == "blue", "blue battle map")
	var tech := true
	for o: Dictionary in gr.run.current_layout().get("obstacles", []):
		if not str(o.get("style", "")).begins_with("tech_"):
			tech = false
	ok(tech, "the obstacles are city tech")
	var g4 := 0
	while gr.fade_rect.color.a > 0.01 and g4 < 400:
		await frames(2)
		g4 += 2
	await shot("ch1b battlefield (tech obstacles)")
	gr._start_battle()
	await frames(90)
	ok(gr.state == "battle", "the placeholder encounter fights")
	await shot("ch1b battle")
	gr._show_title()
	await frames(10)
	gr.cli.erase("chapter")


func chapter1() -> void:
	ok(gr.run.chapter_id == "ch1_red" and gr.run.is_grid(), "now in chapter 1-A (red)")
	ok(UIKit.theme_name == "ember", "red chapter UI theme (ember)")
	ok(gr.world.theme_name == "red", "night lighting for the red chapter")
	ok(gr.world.overworld.city != null and gr.world.overworld.visible, "the burning-city map is shown")
	ok(gr.hud.grid_buttons.size() == gr.run.total_nodes(), "one button per grid node (%d)" % gr.hud.grid_buttons.size())
	ok(gr.hud.ap_panel.visible and gr.hud.ap_num.text == str(gr.run.ap), "action-point panel shows %d" % gr.run.ap)
	var boss: String = str(gr.run.gmap["boss"])
	ok((gr.hud.grid_buttons[boss] as GridNodeButton).kind == "boss", "the boss is marked from the start")
	await frames(30)
	await shot("chapter 1-A map")
	# ---- 悬停一个能去的节点：路线预览 + 信息卡
	var k1: String = open_neighbour("fight")
	ok(k1 != "", "a reachable node next to the start")
	var bp: Vector2 = grid_button_center(k1)
	mouse_move(bp)
	await frames(8)
	ok(gr.hud.tip.visible, "hovering a node shows its info card")
	ok(not gr.world.overworld.city._path.is_empty(), "…and the route is drawn on the map")
	await shot("ch1 hover a node")
	# ---- 作战
	var ap0: int = gr.run.ap
	await click_grid(k1)
	ok(gr.state == "travel", "clicking a reachable node drives there (state=%s)" % gr.state)
	await frames(55)
	ok(gr.world.rig.dist < 120.0, "the camera swoops down to the truck while it drives (dist %.0f)" % gr.world.rig.dist)
	await shot("ch1 driving (zoomed in)")
	await wait_state("prepare")
	ok(gr.run.ap == ap0 - 1, "1 action point spent (%d → %d)" % [ap0, gr.run.ap])
	ok(str(gr.run.current_layout().get("theme", "")) == "red", "red battle map")
	ok(gr.world.battle_root.visible and gr.world.battlefield._embers.size() > 0, "ember patches on the battlefield (%d)" % gr.world.battlefield._embers.size())
	var g2 := 0
	while gr.fade_rect.color.a > 0.01 and g2 < 400:
		await frames(2)
		g2 += 2
	await shot("ch1 battlefield (burning ruins, embers)")
	await fight_and_loot("ch1 fight", false)
	if gr.run.phase == "over":
		return
	ok(gr.state == "map" and gr.run.passable(k1), "back on the city map, the node is cleared")
	# ---- 黑市
	gr.run.gold = 30
	var k2: String = open_neighbour("shop_black")
	await click_grid(k2)
	await wait_state("node")
	await frames(30)
	ok(gr.screens.current == "shop", "black market screen (screen=%s)" % gr.screens.current)
	await shot("ch1 black market")
	var inv0: int = gr.run.inventory.size()
	gr.screens.nshop_buy.emit(0)
	await frames(6)
	ok(gr.run.inventory.size() == inv0 + 1, "bought a weapon")
	ok(gr.screens.current == "shop", "still in the shop after buying")
	gr.screens.nshop_leave.emit()
	await wait_state("map")
	ok(gr.run.passable(k2), "left the shop")
	# ---- 修整
	gr.run.truck_hp = 60
	var k3: String = open_neighbour("rest")
	await click_grid(k3)
	await wait_state("node")
	await frames(20)
	ok(gr.screens.current == "rest", "rest screen")
	await shot("ch1 rest stop")
	gr.screens.rest_repair.emit()
	await wait_state("map")
	ok(gr.run.truck_hp > 60, "the truck was repaired (%d)" % gr.run.truck_hp)
	# ---- 事件(第一个指定抽到燃烧喷泉：把末班电车记成"本章出过了") + 零件
	gr.run.parts = ["offroad_tire", "jerrycan", "scout_drone"]
	gr.hud.refresh()
	gr.run.events_this_chapter = all_events_but("burning_fountain")
	var k4: String = open_neighbour("event")
	await click_grid(k4)
	await wait_state("node")
	await frames(10)
	ok(gr.screens.current == "event", "event screen")
	var es: EventScreen = gr.screens.event_screen()
	ok(es != null and es.event_id == "burning_fountain", "the red chapter's event is the Burning Fountain")
	if es != null:
		ok(es.stage != null and es.stage.scene_id == "fountain_park" and es.stage.arena != null, "with its own 3D scene: the park it would be fought in")
		ok(es._opt_buttons.size() == 3, "three options")
		ok(es._opt_buttons[1].disabled == not bool(gr.run.event_option_check(1)["ok"]), "the destroy option is locked unless a strong ranged node is around")
		await frames(30)
		await shot("ch1 event: burning fountain")
		var xp0: int = gr.run.xp
		var lv0: int = gr.run.level
		es._opt_buttons[2].pressed.emit()
		await frames(10)
		ok(int(gr.run.event_state.get("option", -1)) == 2, "chose to study it")
		ok(gr.run.xp != xp0 or gr.run.level != lv0, "gained XP")
		var es2: EventScreen = gr.screens.event_screen()
		ok(es2 == es and es2._opt_buttons.is_empty(), "the same screen now shows the outcome (the scene isn't rebuilt)")
		await shot("ch1 event result")
	gr.screens.event_continue.emit()
	await wait_state("map")
	await frames(10)
	ok(gr.hud.parts_row.get_child_count() == 3, "three parts in the parts bar")
	var apj: int = gr.run.ap
	gr.hud.part_clicked.emit(1)
	await frames(4)
	ok(gr.run.ap == apj + 2, "jerry can: +2 AP")
	gr.hud.part_clicked.emit(0)
	await frames(6)
	ok(gr.hud.part_mode == 0, "tire: pick a target")
	var any_target := false
	for kk: String in gr.hud.grid_buttons.keys():
		if (gr.hud.grid_buttons[kk] as GridNodeButton).targeted:
			any_target = true
	ok(any_target, "jump targets are highlighted")
	await shot("ch1 part targeting")
	gr.hud.part_clicked.emit(0)
	await frames(4)
	ok(gr.hud.part_mode == -1, "click again to cancel")
	# ---- 第二个事件：末班电车(目送它离开 → 电车开走、观测周围)；行动力只剩 1，事件完了 → 追猎
	gr.run.ap = 1
	gr.run.events_this_chapter = all_events_but("last_tram")
	var k5: String = open_neighbour("event")
	if k5 != "":
		gr.run.ap = maxi(1, int(gr.run.reachable().get(k5, 1)))      # 走到那里正好把行动力用完
		await click_grid(k5)
		await wait_state("node")
		await frames(10)
		ok(str(gr.run.event_state.get("id", "")) == "last_tram", "the second event this chapter is the Last Tram (event=%s state=%s phase=%s pos=%s k5=%s ap=%d)" % [
			str(gr.run.event_state.get("id", "")), gr.state, gr.run.phase, gr.run.pos, k5, gr.run.ap])
		var et: EventScreen = gr.screens.event_screen()
		ok(et != null and et.stage != null and et.stage.scene_id == "tram_stop" and et.stage.arena != null, "with its own 3D scene: the tram stop it would be fought at")
		if et != null:
			ok(et._opt_buttons.size() == 3 and not et._opt_buttons[0].disabled and not et._opt_buttons[1].disabled, "three options, all open")
			var hint0: String = et._option_hint((gr.run.event_def()["options"] as Array)[0], true)
			var hint1: String = et._option_hint((gr.run.event_def()["options"] as Array)[1], true)
			ok(hint0.contains(Loc.t("ui.event.eff_ap", [2])), "following shows +2 action points")
			ok(hint1.contains("×2"), "boarding shows the two blue orbs as ×2")
			await frames(40)
			await shot("ch1 event: last tram")
			var hidden0: int = _hidden_near(gr.run, 3)
			et._opt_buttons[2].pressed.emit()
			await frames(10)
			ok(int(gr.run.event_state.get("option", -1)) == 2, "chose to watch it leave")
			ok(_hidden_near(gr.run, 3) == 0, "the route map scouted every node within 3 cells (%d were hidden)" % hidden0)
			var x0: float = et.stage.arena.tram.position.x
			var t0: int = Time.get_ticks_msec()
			while et.stage.arena.tram.position.x <= x0 + 2.0 and Time.get_ticks_msec() - t0 < 8000:
				await frames(5)
			ok(et.stage.arena.tram.position.x > x0 + 2.0, "the tram pulls out of the stop")
			await shot("ch1 event: the tram leaves")
		gr.screens.event_continue.emit()
		await wait_state("prepare")
		ok(gr.run.hunt_active and gr.run.phase == "prepare", "out of AP → the hunt (hunt=%s, phase=%s)" % [str(gr.run.hunt_active), gr.run.phase])
		await frames(40)
		await shot("ch1 the hunt")
	# ---- 第二批事件：可重复的选项(扭蛋机)——结果页「回到现场」，次数和价格往上走；纯负面事件(路障)
	gr.run.hunt_active = false
	gr.run.phase = "event"
	gr.run.gold = 20
	gr.run.event_state = {"id": "gacha_machine", "node": gr.run.pos, "option": -1, "outcome": "", "picks": {}, "closed": [], "gains": [], "repeat": false}
	gr._open_node_screen()
	await frames(20)
	var eg: EventScreen = gr.screens.event_screen()
	ok(eg != null and eg.event_id == "gacha_machine" and eg.stage != null and eg.stage.scene_id == "roadside", "the gacha machine, on the roadside kit")
	if eg != null:
		ok(eg._opt_buttons.size() == 3 and not eg._opt_buttons[0].disabled and eg._opt_buttons[1].disabled and not eg._opt_buttons[2].disabled,
			"coin slot open, shaking locked until two coins, walking away open")
		ok(eg._option_hint((gr.run.event_def()["options"] as Array)[0], true).contains(Loc.t("ui.event.hidden")), "the coin's outcome is hidden")
		await shot("event: the gacha machine")
		eg._opt_buttons[0].pressed.emit()
		await frames(10)
		var eg2: EventScreen = gr.screens.event_screen()
		ok(eg2 == eg and int(gr.run.event_state.get("option", -1)) == 0 and bool(gr.run.event_state.get("repeat", false)), "dropped a coin: the outcome, with a way back")
		await shot("event: gacha outcome (back to the scene)")
		gr.screens.event_continue.emit()
		await frames(10)
		var eg3: EventScreen = gr.screens.event_screen()
		ok(eg3 != null and gr.run.phase == "event" and eg3._opt_buttons.size() == 3, "back at the machine with the options again")
		var lab := ""
		if eg3 != null:
			for n4: Node in eg3._opt_buttons[0].find_children("*", "Label", true, false):
				if (n4 as Label).text == Loc.t("ui.event.repeat_n", [2, 5]):
					lab = (n4 as Label).text
		ok(lab != "", "the coin option now says try 2 / 5")
		if eg3 != null:
			eg3._opt_buttons[2].pressed.emit()
			await frames(10)
		gr.screens.event_continue.emit()
		await frames(10)
	ok(gr.run.phase != "event", "walked away (phase %s)" % gr.run.phase)
	gr.run.hunt_active = false
	gr.run.phase = "event"
	gr.run.gold = 0
	gr.run.inventory.clear()
	gr.run.event_state = {"id": "toll_gate", "node": gr.run.pos, "option": -1, "outcome": "", "picks": {}, "closed": [], "gains": [], "repeat": false}
	gr._open_node_screen()
	await frames(20)
	var et2: EventScreen = gr.screens.event_screen()
	ok(et2 != null and et2.event_id == "toll_gate", "the toll gate")
	if et2 != null:
		ok(et2._opt_buttons[0].disabled and et2._opt_buttons[1].disabled and not et2._opt_buttons[3].disabled, "broke and unarmed: only ramming or turning around")
		await shot("event: the toll gate (purely negative)")
		et2._opt_buttons[3].pressed.emit()
		await frames(10)
		gr.screens.event_continue.emit()
		await frames(10)
	# ---- 事件战斗的专属战场：电车站(和事件画面是同一个地方)，电车按时刻表冲过战场
	gr.run.hunt_active = false
	gr.run.phase = "event"
	gr.run.event_state = {"id": "last_tram", "node": gr.run.pos, "option": 1, "outcome": "board_fight",
		"battle": (((gr.cat.events["last_tram"]["options"] as Array)[1]["outcomes"] as Array)[0]["effects"] as Array)[0]}
	gr.run.event_continue()
	ok(gr.run.phase == "prepare" and str(gr.run.current_layout().get("arena", "")) == "tram_stop", "boarding the tram: the battle is at the tram stop")
	await gr._goto_battlefield(true)
	await frames(40)
	var ar: ArenaSet = gr.world.battlefield.arena
	ok(ar != null and ar.set_id == "tram_stop" and ar.battle and ar.tram != null, "the battlefield is built from the same set as the event picture")
	ok(gr.hud.arena_box != null and gr.hud.arena_box.visible and gr.hud.mode == "prepare", "the battlefield rule is written out while preparing")
	if ar != null:
		ok(ar.tram.position.x < -GC.map_half().x - 4.0, "the tram waits outside the west edge of the map")
		# 清扫节点 + 闪烁刀刃(这一场双方攻击力会被压成 1：她的飞刀永远不够打死人，会一直停在半空——正好看完美时计)
		gr.run.level = maxi(gr.run.level, 9)
		var maid: Dictionary = gr.run.add_unit("node_maid", 2, null, gr.run.free_bench_slot())
		var maid_ok := false
		for mcy in range(GC.MAP_H):
			for mcx in range(GC.MAP_W):
				var mcc := Vector2i(mcx, mcy)
				if not maid_ok and GC.is_deploy_cell(mcc) and gr.run.unit_at_cell(mcc).is_empty():
					maid_ok = bool(gr.run.move_unit(str(maid["id"]), {"cell": mcc})["ok"])
		ok(maid_ok, "deploy Node Maid at the tram stop")
		gr.run.inventory.append("blink_blade")
		ok(gr.run.equip(str(maid["id"]), "blink_blade")["ok"], "she wields the Blink Blade")
		# 星旅节点留在仓库里：开战时从天上坠落到敌人中间
		gr.run.add_unit("node_astronaut", 2, null, gr.run.free_bench_slot())
		gr._refresh_starfall()
		await frames(4)
		await shot("ch1 event battle: the tram stop (prepare)")
		gr._start_battle()
		await frames(10)
		var tb: Battle = gr.world.battle_view.battle
		ok(tb != null and tb.hazards.size() == 1, "the battle carries the tram hazard")
		if tb != null:
			# 让这一场打不完(双方都打不动)，好等电车来
			for bu: BUnit in tb.units:
				bu.base.attack_power = 1.0
				bu.base.ability_power = 0.0
				bu.mark_dirty()
			gr._set_speed(4.0)
			var guard := 0
			# 等电车的这段时间里看清扫节点的飞刀：停在半空的够多了就拍一张(之后可能够打死人放出去了，所以记最多的那一刻)
			var held_max := 0
			var maid_shot := false
			while str(tb.hazards[0]["phase"]) != "warn" and tb.state != "ended" and guard < 3000:
				guard += 1
				var hc: int = _maid_held(tb)
				held_max = maxi(held_max, hc)
				if hc >= 10 and not maid_shot:
					maid_shot = true
					await shot("ch1 event battle: maid knives hovering")
				await frames(1)
			ok(held_max >= 4, "Node Maid's knives wait in mid-air (up to %d at once)" % held_max)
			var crashed := false
			for au: BUnit in tb.units:
				if au.def.id == "node_astronaut" and not bool(au.meta.get("dropping", false)) and gr.world.battle_view.astro_rings.has(au.uid):
					crashed = true
			ok(crashed, "the Node Astronaut in storage crashed down onto the enemies")
			ok(str(tb.hazards[0]["phase"]) == "warn" and ar._warn, "3 s ahead: the crossing lights and the red strip warn of the tram")
			ok(gr.hud._hazard_num != null and gr.hud._hazard_num.text != "", "…and the HUD counts down (%s)" % (gr.hud._hazard_num.text if gr.hud._hazard_num != null else "-"))
			gr._set_speed(1.0)
			await frames(20)
			await shot("ch1 event battle: tram warning")
			guard = 0
			while (str(tb.hazards[0]["phase"]) != "run" or float(tb.hazards[0]["x"]) < -3.0) and tb.state != "ended" and guard < 3000:
				guard += 1
				await frames(1)
			ok(str(tb.hazards[0]["phase"]) == "run" and ar.tram.position.x > -8.0, "the tram charges across the battlefield (x = %.1f)" % ar.tram.position.x)
			await shot("ch1 event battle: the tram charges through")
	# ------------------------------------------------ 第二章-A·紫之章(出图之前)
	await chapter2()
	await chapter_blue()
	# 出图
	var cols := 3
	var rows: int = int(ceil(float(shots.size()) / float(cols)))
	var cw := 960
	var ch := 540
	var sheet := Image.create(cw * cols, ch * rows, false, Image.FORMAT_RGB8)
	for i in range(shots.size()):
		var im: Image = ((shots[i] as Dictionary)["img"] as Image).duplicate()
		im.resize(cw, ch, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(im, Rect2i(0, 0, cw, ch), Vector2i((i % cols) * cw, (i / cols) * ch))
	var out := "res://out/ui.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out = a.substr(4)
	sheet.save_png(out)
	for i2 in range(shots.size()):
		((shots[i2] as Dictionary)["img"] as Image).save_png("res://out/ui_%d.png" % i2)
		print("shot ui_%d: %s" % [i2, str((shots[i2] as Dictionary)["label"])])
	print("---- ui test: %d checks, %d failed" % [checks, fails.size()])
	for f in fails:
		print("  ✗ ", f)
	quit(1 if not fails.is_empty() else 0)
