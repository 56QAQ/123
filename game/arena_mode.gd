class_name ArenaMode
extends Node
## 测试场(标题画面「测试场」进入；平衡测试用的工具，发布版里也有)：
## 1. 自己排布我方阵容：任意棋子 / 星级 / 武器，点头像加进仓库或直接拖到格子上；羁绊可以开关。
## 2. 自己排布各星级的怪物：点头像加入(按方位出生)或拖到战场上任意空地，敌方面板显示每只怪和总共的强度点数；也能按某个战斗强度随机配一组。
## 3. 设定战斗场数：1 场 = 正常播放战斗(之后是结算 / 战报)；多场 = 无画面地模拟，打完给出胜率、平均时长、各单位的平均输出 / 承伤。
## 4. 强度阈值测试：拿玩家摆的阵容从低往高打随机配怪(IntensityProbe，和 tools/intensity_bench.gd 同一套口径)，给出最高通过的战斗强度。
## 用一个"测试场 Run"(sandbox)接进 GameRoot 的备战流程：拖拽 / 详情卡 / 仓库 / 羁绊 / 战斗画面 / 战报都和正式游戏是同一套。
## 多场模拟和阈值测试在主线程里分帧跑(每帧最多 BUDGET_US 微秒)，界面不卡。

const CHAPTER := "ch1_red"
const BUDGET_US := 22000
const REGIONS: Array[String] = ["n", "nw", "ne", "w", "e", "n", "nw", "ne"]

var gr: GameRoot
var cat: Catalog
var run: Run
var panel: ArenaPanel
var traits_on := true
var auto_weapon := true            # 加进来的棋子默认拿专属武器
var map_kind := "terrain"          # terrain = 红之章的地形 / flat = 空地
var map_seed := 1
var battle_count := 1
var busy := ""                     # "" / "sims" / "probe"
var sims := {}                     # 多场模拟的统计
var sim_result := {}
var probe: IntensityProbe = null
var probe_opts := {"keep_cells": false}
var _battle: Battle = null         # 正在无画面模拟的那一场
var _job := {}
var enemy_drag := {}
var _sel := "?"


func open(p_gr: GameRoot) -> void:
	gr = p_gr
	cat = gr.cat
	run = Run.create(cat, 0, CHAPTER)
	run.sandbox = true
	run.roster.clear()
	run.inventory.clear()
	run.phase = "prepare"
	var nd: Dictionary = run.gnode(run.pos)
	nd["type"] = "fight"
	nd["encounter"] = {"units": [], "map": {}, "pool": "weak", "intensity": 0}
	_rebuild_layout()
	panel = ArenaPanel.new()
	panel.setup(self)
	gr.ui_layer.add_child(panel)
	gr.ui_layer.move_child(panel, gr.hud.get_index() + 1)


## 换语言之后：面板整个重建(停在原来那一页)
func rebuild_panel() -> void:
	if panel == null:
		return
	var t: String = panel.tab
	var sel: String = panel._sel
	panel.queue_free()
	panel = ArenaPanel.new()
	panel.setup(self)
	panel.tab = t
	panel._sel = sel
	gr.ui_layer.add_child(panel)
	gr.ui_layer.move_child(panel, gr.hud.get_index() + 1)


func close() -> void:
	busy = ""
	_battle = null
	if is_instance_valid(panel):
		panel.queue_free()
	panel = null


# ---------------------------------------------------------------- 战场
func enemies() -> Array:
	return run.wave_def().get("units", [])


func _map_cfg() -> Dictionary:
	var mcfg: Dictionary = ((run.chapter.get("battle_map", {}) as Dictionary).get("fight", {}) as Dictionary).duplicate()
	if map_kind == "flat":
		mcfg = {"low": 0, "high": 0, "burning": 0, "embers": 0}
	mcfg["theme"] = str(run.chapter.get("theme", "red"))
	return mcfg


func _rebuild_layout() -> void:
	var enc: Dictionary = run.wave_def()
	enc["map"] = _map_cfg()
	run.visits = map_seed
	run.gnode(run.pos)["layout"] = run._make_layout(enc)
	# 摆在新障碍物上的怪：回到按方位出生
	var m: BattleMap = run.current_map()
	for e: Array in enemies():
		var opt: Dictionary = e[4]
		if opt.has("pos") and m.blocks_move(GC.world_to_cell(opt["pos"])):
			opt.erase("pos")


func set_map(kind: String, reroll: bool = false) -> void:
	if busy != "":
		return
	map_kind = kind
	if reroll:
		map_seed += 1
	_rebuild_layout()
	run._fix_board_cells()
	gr.world.show_battlefield(run.current_layout(), map_seed)
	gr._sync_prep(true)
	gr._sync_enemy_preview()
	_refresh()


# ---------------------------------------------------------------- 我方
func add_unit(def_id: String, star: int, cell: Variant = null) -> void:
	if busy != "":
		return
	var u: Dictionary = run.sandbox_add(def_id, star)
	if auto_weapon:
		var ex: String = exclusive_of(def_id)
		if ex != "" and bool(run.equip_check(u["id"], ex)["ok"]):
			run.sandbox_set_weapon(u["id"], ex)
	if cell != null:
		gr._toast_result(run.move_unit(u["id"], {"cell": cell}))


func exclusive_of(def_id: String) -> String:
	for eid: String in cat.equipment.keys():
		if (cat.equipment[eid] as EquipmentDef).owner == def_id:
			return eid
	return ""


## 能拿的武器(重构过的，按这个棋子 / 星级能不能装筛)；"" = 基础武器
func weapons_for(u: Dictionary) -> Array[String]:
	var r: Array[String] = [""]
	var ids: Array = cat.equipment.keys()
	ids.sort()
	for eid: String in ids:
		var e: EquipmentDef = cat.equipment[eid]
		if e.basic or e.slot != "weapon" or not e.reworked:
			continue
		if e.equip_problem(run.unit_def(u), int(u["star"])) == "":
			r.append(eid)
	return r


func set_star(rid: String, star: int) -> void:
	if busy == "":
		run.sandbox_set_star(rid, star)


func set_weapon(rid: String, eid: String) -> void:
	if busy == "":
		gr._toast_result(run.sandbox_set_weapon(rid, eid))


func remove_unit(rid: String) -> void:
	if busy != "":
		return
	gr.selected_id = ""
	gr.selected_storage = ""
	gr.hud.hide_card()
	run.sandbox_remove(rid)


func clear_units() -> void:
	if busy != "":
		return
	gr.selected_id = ""
	gr.selected_storage = ""
	gr.hud.hide_card()
	run.roster.clear()
	run._changed("sandbox")


func set_traits(on: bool) -> void:
	traits_on = on
	gr.hud.trait_box.modulate.a = 1.0 if on else 0.35
	_refresh()


# ---------------------------------------------------------------- 敌方
func _opt_for(id: String) -> Dictionary:
	var md: Dictionary = (run.chapter.get("monsters", {}) as Dictionary).get(id, {})
	if not bool(md.get("head", false)):
		return {}
	return {"boss": true} if id == str((run.chapter.get("boss", {}) as Dictionary).get("unit", "")) else {"elite": true}


func add_monster(id: String, star: int, pos: Variant = null) -> void:
	if busy != "":
		return
	var units: Array = enemies()
	var opt: Dictionary = _opt_for(id)
	if pos != null:
		opt["pos"] = pos
	units.append([id, clampi(star, 1, GC.MAX_STAR), REGIONS[units.size() % REGIONS.size()], "", opt])
	_enemies_changed()


func monster_star(i: int, star: int) -> void:
	if busy == "" and i >= 0 and i < enemies().size():
		(enemies()[i] as Array)[1] = clampi(star, 1, GC.MAX_STAR)
		_enemies_changed()


func remove_monster(i: int) -> void:
	if busy == "" and i >= 0 and i < enemies().size():
		enemies().remove_at(i)
		_enemies_changed()


func clear_monsters() -> void:
	if busy == "":
		enemies().clear()
		_enemies_changed()


## 按战斗强度随机配一组(和游戏里同一套配怪：总点数正好 = 强度)
func random_monsters(kind: String, iv: int) -> void:
	if busy != "":
		return
	run.rng.seed = int(Time.get_ticks_usec() % 1000003)
	var enc: Dictionary = run._make_encounter(kind, maxi(1, iv))
	var units: Array = enemies()
	units.clear()
	for e: Array in enc["units"]:
		(e[4] as Dictionary).erase("orb")
		units.append(e)
	_enemies_changed()


func monster_points(e: Array) -> float:
	return run._unit_power(str(e[0]), int(e[1]), float((e[4] as Dictionary).get("hp_mult", 1.0)))


func total_points() -> float:
	return run.encounter_power(run.wave_def())


## 怪能不能放在这里(世界坐标)：战场里、不在部署区 / 卡车 / 地形上
func valid_enemy_cell(c: Vector2i) -> bool:
	var m: BattleMap = run.current_map()
	return m.in_bounds(c) and not m.deploy_rect.has_point(c) and not m.blocks_move(c) and run.unit_at_cell(c).is_empty()


func _enemies_changed() -> void:
	run._fix_board_cells()                  # 怪挪走了：站在不能站的格子上的棋子(千变万化)换到能站的地方
	gr._sync_enemy_preview()
	gr._sync_prep(false)
	_refresh()


# ---------------------------------------------------------------- 拖动怪物(GameRoot 的鼠标回调先问这里)
func on_pressed(pos: Vector2) -> bool:
	if busy != "":
		return true
	var v: UnitView = gr._pick_view(pos, true)
	if v != null and gr.enemy_views.has(v):
		enemy_drag = {"i": gr.enemy_views.find(v), "view": v, "press": pos, "active": false}
		return true
	return false


func on_moved(pos: Vector2) -> bool:
	if enemy_drag.is_empty():
		return false
	if not bool(enemy_drag["active"]) and pos.distance_to(enemy_drag["press"]) > 9.0:
		enemy_drag["active"] = true
		gr._select_view(null)
	if bool(enemy_drag["active"]):
		var pk: Dictionary = gr._pick_ground(pos)
		gr.world.stage.clear_highlights()
		if pk.has("point"):
			var pt: Vector3 = pk["point"]
			(enemy_drag["view"] as UnitView).position = Vector3(pt.x, 0.5, pt.z)
			var c: Vector2i = GC.world_to_cell(Vector2(pt.x, pt.z))
			gr.world.stage.highlight_cell(c, Color(0.4, 1.0, 0.55, 0.45) if valid_enemy_cell(c) else Color(1.0, 0.35, 0.35, 0.45))
	return true


func on_released(pos: Vector2) -> bool:
	if enemy_drag.is_empty():
		return false
	var d: Dictionary = enemy_drag
	enemy_drag = {}
	gr.world.stage.clear_highlights()
	if not bool(d["active"]):
		gr._select_view(d["view"])            # 点击 = 看这只怪的详情卡
		return true
	var pk: Dictionary = gr._pick_ground(pos)
	var i: int = int(d["i"])
	if pk.has("point") and i < enemies().size():
		var pt: Vector3 = pk["point"]
		var c: Vector2i = GC.world_to_cell(Vector2(pt.x, pt.z))
		if valid_enemy_cell(c) and run.unit_at_cell(c).is_empty():
			((enemies()[i] as Array)[4] as Dictionary)["pos"] = GC.cell_to_world(c.x, c.y)
		else:
			gr.hud.toast_msg(Loc.t("ui.err.bad_cell"))
	_enemies_changed()
	return true


# ---------------------------------------------------------------- 开打
func setup_now() -> Dictionary:
	var s: Dictionary = run.build_battle_setup()
	if not traits_on:
		(s["cfg"] as Dictionary)["traits"] = false
	return s


func _ready_check() -> bool:
	if run.board_units().is_empty():
		gr.hud.toast_msg(Loc.t("ui.err.empty_board"))
		return false
	if enemies().is_empty():
		gr.hud.toast_msg(Loc.t("ui.arena_no_enemy"))
		return false
	return true


## 开始(界面按钮 / 空格)：1 场 = 正常播放；多场 = 无画面模拟
func start() -> void:
	if busy != "" or not _ready_check():
		return
	if battle_count <= 1:
		run.phase = "battle"
		gr._launch_battle(setup_now(), int(Time.get_ticks_usec() % 100000))
		return
	sims = {"n": battle_count, "i": 0, "w": 0, "time": 0.0, "truck": 0, "alive": 0, "foes": 0, "units": {}, "setup": setup_now()}
	sim_result = {}
	busy = "sims"
	gr.hud.hide_card()
	_refresh()


## 单场战斗打完：结算界面(和正式游戏同一个，标成测试场)
func on_visual_battle_ended(b: Battle) -> void:
	var alive := 0
	var foes := 0
	for s: Dictionary in b.summary():
		if bool(s["alive"]):
			if int(s["team"]) == GC.TEAM_PLAYER:
				alive += 1
			else:
				foes += 1
	var res := {"win": b.winner == GC.TEAM_PLAYER, "arena": true, "truck_damage": b.truck_damage, "alive": alive, "foes": foes}
	run.last_result = res
	gr._show_battle_result(b, res)


## 结算界面之后：回到布阵
func back_to_board() -> void:
	gr.screens.hide_all()
	gr.world.battle_view.clear()
	gr._clear_orbs()
	run.phase = "prepare"
	gr.state = "prepare"
	for id: String in gr.prep_views.keys():
		(gr.prep_views[id] as UnitView).visible = true
	gr.hud.set_mode("arena")
	gr.world.rig.set_preset("prep")
	gr.world.stage.show_deploy(false, true)
	gr._sync_prep(false)
	gr._sync_enemy_preview()
	_refresh()


func start_probe() -> void:
	if busy != "":
		return
	if run.board_units().is_empty():
		gr.hud.toast_msg(Loc.t("ui.err.empty_board"))
		return
	var team: Array = []
	for u: Dictionary in run.board_units():
		team.append({"def": u["def"], "star": int(u["star"]), "weapon": str(u["weapon"]), "cell": u["cell"]})
	for ub: Dictionary in run.bench_units():
		if run.unit_def(ub).bench_drop:                  # 仓库里的星旅节点照样会坠落
			team.append({"def": ub["def"], "star": int(ub["star"]), "weapon": str(ub["weapon"]), "cell": null})
	probe = IntensityProbe.new()
	probe.setup(cat, team, {"traits": traits_on, "keep_cells": bool(probe_opts.get("keep_cells", false)),
		"max": int(probe_opts.get("max", 120)), "seed": map_seed})
	busy = "probe"
	gr.hud.hide_card()
	_refresh()


func stop() -> void:
	if busy == "sims":
		_finish_sims()
	busy = ""
	_battle = null
	_refresh()


# ---------------------------------------------------------------- 分帧跑
func _process(_dt: float) -> void:
	if run == null:
		return
	var sel: String = gr.selected_id if gr.selected_id != "" else gr.selected_storage
	if sel != _sel:
		_sel = sel
		if panel != null:
			panel.show_unit(sel)
	if busy == "":
		return
	var t0: int = Time.get_ticks_usec()
	while Time.get_ticks_usec() - t0 < BUDGET_US and busy != "":
		if _battle == null and not _next_battle():
			break
		var steps := 0
		while _battle.state != "ended" and steps < 30:
			_battle.step()
			_battle.events.clear()
			steps += 1
		if _battle.state == "ended":
			_battle_done(_battle)
			_battle = null
	if panel != null:
		panel.show_progress()


func _next_battle() -> bool:
	if busy == "sims":
		if int(sims["i"]) >= int(sims["n"]):
			_finish_sims()
			busy = ""
			_refresh()
			return false
		_battle = Battle.new(cat, map_seed * 100003 + int(sims["i"]) * 7919 + 1)
		_battle.setup((sims["setup"] as Dictionary).duplicate(true))
		_battle.start()
		return true
	if busy == "probe":
		_job = probe.next_job()
		if _job.is_empty():
			busy = ""
			if panel != null:
				panel.focus_probe = true
			_refresh()
			return false
		_battle = probe.make_battle(_job)
		_battle.start()
		return true
	return false


func _battle_done(b: Battle) -> void:
	var win: bool = b.winner == GC.TEAM_PLAYER
	if busy == "probe":
		probe.report(win)
		return
	sims["i"] = int(sims["i"]) + 1
	if win:
		sims["w"] = int(sims["w"]) + 1
	sims["time"] = float(sims["time"]) + maxf(0.0, b.end_time - GC.START_DELAY)
	sims["truck"] = int(sims["truck"]) + b.truck_damage
	var per: Dictionary = sims["units"]
	for s: Dictionary in b.summary():
		if bool(s["alive"]):
			var key: String = "alive" if int(s["team"]) == GC.TEAM_PLAYER else "foes"
			sims[key] = int(sims[key]) + 1
		var k: String = "%d|%s|%d" % [int(s["team"]), str(s["def"]), int(s["star"])]
		if not per.has(k):
			per[k] = {"team": int(s["team"]), "def": str(s["def"]), "star": int(s["star"]), "damage": 0.0, "taken": 0.0, "heal": 0.0, "kills": 0, "count": 0}
		var p: Dictionary = per[k]
		p["damage"] = float(p["damage"]) + float(s["damage"])
		p["taken"] = float(p["taken"]) + float(s["taken"])
		p["heal"] = float(p["heal"]) + float(s["heal"]) + float(s["shield"])
		p["kills"] = int(p["kills"]) + int(s["kills"])
		p["count"] = int(p["count"]) + 1


func _finish_sims() -> void:
	var n: int = int(sims.get("i", 0))
	if n <= 0:
		sim_result = {}
		return
	var rows: Array = []
	for p: Dictionary in (sims["units"] as Dictionary).values():
		var r: Dictionary = p.duplicate()
		for key: String in ["damage", "taken", "heal"]:
			r[key] = float(p[key]) / float(n)
		r["kills"] = float(p["kills"]) / float(n)
		r["per_battle"] = float(p["count"]) / float(n)          # 每场平均几个(同名单位、召唤物)
		rows.append(r)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["team"]) < int(b["team"]) or (int(a["team"]) == int(b["team"]) and float(a["damage"]) > float(b["damage"])))
	sim_result = {"n": n, "w": int(sims["w"]), "time": float(sims["time"]) / float(n), "truck": float(sims["truck"]) / float(n),
		"alive": float(sims["alive"]) / float(n), "foes": float(sims["foes"]) / float(n), "rows": rows, "ci": IntensityProbe.wilson(int(sims["w"]), n)}


func _refresh() -> void:
	if panel != null:
		panel.refresh()
