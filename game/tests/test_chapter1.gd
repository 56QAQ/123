extends RefCounted
## 第一章·红之章：方格网地图(黑流树海式的行动力移动)、节点类型、追猎、修整、商店、零件、换章。


func _run1(seed_value: int = 11) -> Run:
	var r := Run.create(Fixture.catalog(), seed_value)
	r.enter_chapter("ch1_red", false)
	return r


func _win(r: Run, seed_value: int = 1) -> void:
	var b := Battle.new(Fixture.catalog(), seed_value)
	b.setup(r.build_battle_setup())
	b.winner = GC.TEAM_PLAYER
	r.begin_battle()
	r.finish_battle(b)
	r.finish_loot()


func _lose(r: Run, seed_value: int = 1) -> void:
	var b := Battle.new(Fixture.catalog(), seed_value)
	b.setup(r.build_battle_setup())
	b.winner = GC.TEAM_ENEMY
	b.truck_damage = 4
	r.begin_battle()
	r.finish_battle(b)
	r.finish_loot()


## 卡车能去的、离得最近的未完成节点
func _nearest_open(r: Run, types: Array = []) -> String:
	var reach: Dictionary = r.reachable()
	var best := ""
	for k: String in reach.keys():
		if k == r.pos or r.passable(k):
			continue
		if not types.is_empty() and not types.has(str(r.gnode(k)["type"])):
			continue
		if best == "" or int(reach[k]) < int(reach[best]):
			best = k
	return best


func test_grid_map_shape(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var cfg: Dictionary = cat.chapters["ch1_red"]["grid"]
	for sd in [1, 2, 3, 4, 5, 6]:
		var m: Dictionary = ChapterMap.generate(cfg, sd)
		t.eq(JSON.stringify(m), JSON.stringify(ChapterMap.generate(cfg, sd)), "deterministic (seed %d)" % sd)
		var nodes: Dictionary = m["nodes"]
		t.ok(nodes.size() >= int(cfg["nodes"]) - 4 and nodes.size() <= int(cfg["w"]) * int(cfg["h"]), "node count %d" % nodes.size())
		var d: int = int(m["path_len"])
		t.ok(d >= int(cfg["min_path"]) and d <= int(cfg["max_path"]), "start → boss shortest path in range (%d)" % d)
		t.eq(int(m["ap"]), d + int(cfg["ap_spare"]), "AP = shortest path + spare")
		# 四向连通：每条边连的是上下左右相邻的格点
		for e: Array in m["edges"]:
			var a: Vector2i = ChapterMap.cell(e[0])
			var b: Vector2i = ChapterMap.cell(e[1])
			t.eq(absi(a.x - b.x) + absi(a.y - b.y), 1, "edges join 4-neighbours")
		# 连通：所有节点都能从起点走到
		var adj: Dictionary = ChapterMap.neighbors(m)
		var seen := {m["start"]: true}
		var q: Array = [m["start"]]
		while not q.is_empty():
			var c: String = q.pop_back()
			for n: String in adj[c]:
				if not seen.has(n):
					seen[n] = true
					q.append(n)
		t.eq(seen.size(), nodes.size(), "connected")
		# 稀疏：接近一棵树(边数只比节点数多一点)
		t.ok((m["edges"] as Array).size() <= nodes.size() + 6, "sparse (%d edges / %d nodes)" % [(m["edges"] as Array).size(), nodes.size()])
		var types := {}
		for k: String in nodes.keys():
			types[str(nodes[k]["type"])] = int(types.get(str(nodes[k]["type"]), 0)) + 1
		t.eq(int(types.get("boss", 0)), 1, "one boss")
		t.eq(int(types.get("start", 0)), 1, "one start")
		t.ok(int(types.get("elite", 0)) >= 2 and int(types.get("elite", 0)) <= 4, "2-4 elites")
		t.ok(int(types.get("shop_black", 0)) >= 1 and int(types.get("shop_parts", 0)) >= 1, "both shop kinds appear")
		t.ok(int(types.get("rest", 0)) >= 1, "at least one rest stop")
		# 首领前一格是修整
		var pre_rest := false
		for n2: String in adj[m["boss"]]:
			if str(nodes[n2]["type"]) == "rest":
				pre_rest = true
		t.ok(pre_rest, "a rest stop right before the boss")
		t.eq(str(nodes[m["boss"]]["state"]), "seen", "the boss is marked on the map from the start")


func test_moving_costs_ap_per_grid_point_and_cannot_pass_unfinished_nodes(t: TestCtx) -> void:
	var r := _run1()
	t.ok(r.is_grid(), "chapter 1 is a grid map")
	t.eq(r.ap, r.ap_max, "full AP")
	t.eq(r.pos, str(r.gmap["start"]), "starts at the start")
	var reach: Dictionary = r.reachable()
	# 开局只能去起点的邻居(邻居都没完成，不能穿过)
	for k: String in reach.keys():
		if k != r.pos:
			t.eq(int(reach[k]), 1, "only direct neighbours of the start are reachable (%s)" % k)
	var tgt: String = _nearest_open(r)
	var ap0: int = r.ap
	t.ok(bool(r.move_to(tgt)["ok"]), "move to a neighbour")
	t.eq(r.ap, ap0 - 1, "one grid point = 1 AP")
	t.eq(r.steps, 1, "steps counted")
	# 节点还没完成时，后面的节点不能穿过它到达(只能回头)
	if r.phase == "prepare":
		_win(r)
	elif r.phase == "rest":
		r.rest_repair()
	elif r.phase == "event":
		r.event_continue()
	elif r.phase == "shop":
		r.leave_node()
	t.eq(str(r.gnode(tgt)["state"]), "done", "the node is finished")
	t.eq(r.phase, "map", "back on the map")
	# 完成的节点可以穿行：回到起点要 1 点
	t.eq(r.move_cost(str(r.gmap["start"])), 1, "cleared nodes can be passed (1 AP back to the start)")
	# 隔着未完成节点的格点去不了
	var far: String = ""
	for k2: String in (r.gmap["nodes"] as Dictionary).keys():
		if r.move_cost(k2) < 0:
			far = k2
			break
	t.ok(far != "", "some nodes are behind unfinished ones")
	t.eq(r.move_to(far)["reason"], "ui.err.unreachable", "cannot drive through unfinished nodes")


func test_observation_reveals_only_the_frontier(t: TestCtx) -> void:
	var r := _run1(13)
	for k: String in (r.gmap["nodes"] as Dictionary).keys():
		var st: String = str(r.gnode(k)["state"])
		var c: Vector2i = ChapterMap.cell(k)
		var s0: Vector2i = ChapterMap.cell(str(r.gmap["start"]))
		if st == "seen" and k != str(r.gmap["boss"]):
			t.eq(absi(c.x - s0.x) + absi(c.y - s0.y), 1, "only the start's neighbours are observed at first (%s)" % k)
	t.eq(str(r.gnode(str(r.gmap["boss"]))["state"]), "seen", "boss visible")


func test_running_out_of_ap_triggers_the_hunt(t: TestCtx) -> void:
	var r := _run1(17)
	r.ap = 1
	var tgt: String = _nearest_open(r, ["fight"])
	if tgt == "":
		tgt = _nearest_open(r)
	r.move_to(tgt)
	if r.phase == "prepare":
		t.ok(not r.hunt_active, "the node itself is fought normally")
		_win(r)
	else:
		r.leave_node()
	t.eq(r.ap, 0, "AP spent")
	t.ok(r.hunt_active, "out of AP away from the boss: the hunt begins")
	t.eq(r.phase, "prepare", "straight into battle")
	var has_boss := false
	for e: Array in r.wave_def()["units"]:
		if e.size() > 4 and (e[4] as Dictionary).get("boss", false):
			has_boss = true
			t.eq(int(e[1]), 2, "the hunter is an empowered (2-star) boss")
	t.ok(has_boss, "the boss leads the hunt")
	# 输了：卡车受损，还得再打
	var hp0: int = r.truck_hp
	_lose(r)
	t.ok(r.truck_hp < hp0, "losing the hunt damages the truck")
	t.ok(r.hunt_active and r.phase == "prepare", "and the hunt goes on")
	_win(r)
	t.eq(r.phase, "branch", "winning the hunt clears the chapter (→ choose a branch of chapter 2)")
	t.eq(r.ap_penalty, 1, "next chapter starts with 1 less AP")


func test_boss_loss_lets_you_retry_and_boss_win_ends_the_chapter(t: TestCtx) -> void:
	var r := _run1(19)
	# 直接把卡车放到首领旁边(测试)：把首领的邻居都标成完成
	var boss: String = str(r.gmap["boss"])
	var adj: Dictionary = ChapterMap.neighbors(r.gmap)
	var nb: String = adj[boss][0]
	r.pos = nb
	r.gnode(nb)["state"] = "done"
	r.ap = 5
	t.ok(bool(r.move_to(boss)["ok"]), "drive into the boss")
	t.eq(r.phase, "prepare", "boss battle")
	t.eq(r.battle_kind(), "boss", "boss kind")
	_lose(r)
	t.eq(r.phase, "map", "lost: back on the map, parked at the boss")
	t.eq(r.pos, boss, "still at the boss")
	t.eq(r.move_cost(boss), 0, "re-challenging costs no AP")
	t.ok(bool(r.move_to(boss)["ok"]), "challenge again")
	_win(r)
	t.eq(r.phase, "branch", "boss down → choose a branch of chapter 2")
	t.ok(not r.next_branches().is_empty(), "chapter 2 branches are offered")


func test_difficulty_rises_with_distance(t: TestCtx) -> void:
	var r := _run1(23)
	var weak: Dictionary = r._make_encounter("fight", 10)
	t.eq(str(weak["pool"]), "weak", "a plain fight is a normal one")
	t.eq(str(r._make_encounter("fight", 20)["pool"]), "weak", "…at any intensity (no separate strong pool)")
	t.eq(str(r._make_encounter("fight", 20, true)["pool"]), "strong", "strong fights are flagged by the node")
	t.ok((r._make_encounter("fight", 30)["units"] as Array).size() >= (weak["units"] as Array).size(), "deeper fights field at least as many monsters")
	var stars := 0
	for i in range(20):
		for e: Array in r._make_encounter("fight", 24)["units"]:
			stars = maxi(stars, int(e[1]))
	t.eq(stars, 2, "deep into the chapter some fights field 2-star monsters")
	t.eq(str(r._make_encounter("elite", 20)["pool"]), "elite", "elite pool")
	var enc: Dictionary = r._make_encounter("fight", 14)
	t.eq(str(enc["map"]["theme"]), "red", "red battle maps")
	t.ok(int(enc["map"].get("burning", 0)) > 0 and int(enc["map"].get("embers", 0)) > 0, "with burning ruins and embers")


func test_rest_repairs_or_promotes(t: TestCtx) -> void:
	var r := _run1(29)
	r.phase = "rest"
	r.truck_hp = 50
	r.rest_repair()
	t.eq(r.truck_hp, 50 + int(round(r.truck_max * 0.3)), "repair 30% of the truck")
	t.eq(r.phase, "map", "and leave")
	r.phase = "rest"
	r.add_unit("node_witch", 1, null, r.free_bench_slot())     # 3 费：可以
	r.add_unit("node_dancer", 1, null, r.free_bench_slot())
	var cands: Array[Dictionary] = r.rest_upgrade_candidates()
	var ids: Array = []
	for u: Dictionary in cands:
		ids.append(str(u["def"]))
		t.ok(int(u["star"]) == 1 and r.cost_of_unit(u) <= 3, "candidates: 1-star, cost ≤ 3")
	t.ok(ids.has("node_witch"), "a 3-cost node can be promoted in chapter 1")
	var wid: String = ""
	for u2: Dictionary in cands:
		if str(u2["def"]) == "node_witch":
			wid = str(u2["id"])
	t.ok(bool(r.rest_upgrade(wid)["ok"]), "promote")
	t.eq(int(r.roster[wid]["star"]), 2, "now 2 stars")
	# 4 费以上不能
	var cat: Catalog = Fixture.catalog()
	for id: String in cat.shop_unit_ids():
		if cat.get_unit(id).cost >= 4:
			r.phase = "rest"
			var u3: Dictionary = r.add_unit(id, 1, null, r.free_bench_slot())
			var ok := false
			for c: Dictionary in r.rest_upgrade_candidates():
				if c["id"] == u3["id"]:
					ok = true
			t.ok(not ok, "%s (cost %d) is above the chapter cap" % [id, cat.get_unit(id).cost])
			break


func test_node_shops_sell_weapons_parts_and_refresh(t: TestCtx) -> void:
	var r := _run1(31)
	r.gold = 60
	r.pos = str(r.gmap["start"])
	r._ensure_node_shop(r.pos, "shop_black")
	r.phase = "shop"
	var st: Dictionary = r.node_shop()
	var kinds := {}
	for o: Dictionary in st["offers"]:
		kinds[str(o["kind"])] = true
	t.ok(kinds.has("weapon") and kinds.has("part") and kinds.has("repair"), "black market: weapons, parts, repairs")
	var inv0: int = r.inventory.size()
	for i in range((st["offers"] as Array).size()):
		if str(st["offers"][i]["kind"]) == "weapon":
			var g0: int = r.gold
			t.ok(bool(r.node_shop_buy(i)["ok"]), "buy a weapon")
			t.eq(r.gold, g0 - int(st["offers"][i]["price"]), "paid")
			t.eq(r.node_shop_buy(i)["reason"], "ui.err.sold", "sold out")
			break
	t.eq(r.inventory.size(), inv0 + 1, "weapon in the bag")
	var c0: int = r.node_shop_refresh_cost()
	t.eq(c0, 2, "first refresh costs 2")
	r.node_shop_refresh()
	t.eq(r.node_shop_refresh_cost(), 4, "then 4")
	r.node_shop_refresh()
	r.node_shop_refresh()
	t.eq(r.node_shop_refresh_cost(), -1, "at most 3 refreshes per visit")
	# 零件铺：买、卖
	var pk: String = str(r.gmap["boss"])
	r._ensure_node_shop(pk, "shop_parts")
	r.pos = pk
	var ps: Dictionary = r.node_shop()
	for o2: Dictionary in ps["offers"]:
		t.eq(str(o2["kind"]), "part", "parts dealer sells only parts")
	t.ok(bool(r.node_shop_buy(0)["ok"]), "buy a part")
	t.eq(r.parts.size(), 1, "in the parts box")
	var g1: int = r.gold
	t.ok(bool(r.node_shop_sell_part(0)["ok"]), "sell it back")
	t.ok(r.gold > g1, "for some gold")
	t.eq(r.parts.size(), 0, "gone")


func test_parts_move_and_add_ap(t: TestCtx) -> void:
	var r := _run1(37)
	r.parts = ["jerrycan", "offroad_tire", "scout_drone"]
	var ap0: int = r.ap
	t.ok(bool(r.use_part(0)["ok"]), "jerry can")
	t.eq(r.ap, ap0 + 2, "+2 AP")
	# 无人机：观测周围 2 格
	r.use_part(1)
	var c0: Vector2i = ChapterMap.cell(r.pos)
	for k: String in (r.gmap["nodes"] as Dictionary).keys():
		var c: Vector2i = ChapterMap.cell(k)
		if absi(c.x - c0.x) + absi(c.y - c0.y) <= 2:
			t.ok(str(r.gnode(k)["state"]) != "hidden", "drone reveals %s" % k)
	# 越野轮胎：直线 2 格内跳过去(可以越过未完成的节点)
	var targets: Array[String] = r.part_targets(0)
	t.ok(not targets.is_empty(), "tire has targets")
	for k2: String in targets:
		var c2: Vector2i = ChapterMap.cell(k2)
		t.ok((c2.x == c0.x) != (c2.y == c0.y) and absi(c2.x - c0.x) + absi(c2.y - c0.y) <= 2, "straight line within 2 (%s)" % k2)
	var jump: String = targets.back()
	var ap1: int = r.ap
	t.ok(bool(r.use_part(0, jump)["ok"]), "jump")
	t.eq(r.pos, jump, "the truck landed there")
	t.eq(r.ap, ap1 - 1, "1 AP")
	t.eq(r.parts.size(), 0, "all parts used")


func test_chapter0_leads_to_the_red_chapter(t: TestCtx) -> void:
	var r := Run.create(Fixture.catalog(), 41)
	var guard := 0
	while r.phase != "branch" and guard < 10:
		guard += 1
		r.travel()
		_win(r, guard)
	t.eq(r.phase, "branch", "chapter 0 → pick a branch")
	var br: Array = r.next_branches()
	t.eq(br.size(), 3, "three branches")
	t.eq(r.choose_branch("ch1_green")["reason"], "ui.err.locked", "green is not made yet")
	var gold0: int = r.gold
	var lvl0: int = r.level
	var units0: int = r.roster.size()
	t.ok(bool(r.choose_branch("ch1_red")["ok"]), "red chapter")
	t.eq(r.phase, "chapter_end", "…then pick a truck mod for it")
	t.eq(r.mod_options.size(), 3, "three mods to pick from")
	var red := false
	for mo: String in r.mod_options:
		if str(r.mod_def(mo).get("color", "")) == "red":
			red = true
	t.ok(red, "at least one of them is red (the red chapter's color)")
	t.ok(bool(r.pick_mod(r.mod_options[0])["ok"]), "pick one")
	t.eq(r.truck_mods.size(), 1, "the mod was recorded")
	t.eq(r.chapter_id, "ch1_red", "now in chapter 1-A")
	t.eq(r.phase, "map", "on the map")
	t.ok(r.is_grid(), "grid map")
	t.eq(r.gold, gold0, "gold carries over")
	t.eq(r.level, lvl0, "level carries over")
	t.eq(r.roster.size(), units0, "the team carries over")
