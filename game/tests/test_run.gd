extends RefCounted
## 局内经济/花名册/章节流程测试：买卖、合星、武器、拖动、地图节点、卡车耐久、晶球。


func _run(seed_value: int = 5) -> Run:
	return Run.create(Fixture.catalog(), seed_value)


func _bench_count(r: Run, def_id: String) -> int:
	var n := 0
	for u: Dictionary in r.roster.values():
		if u["def"] == def_id:
			n += 1
	return n


func test_new_run_starts_on_the_chapter_map(t: TestCtx) -> void:
	var r := _run()
	t.eq(r.roster.size(), 3, "three starting units (with the gifted Node Basic)")
	t.eq(r.inventory.size(), 2, "two starting weapons")
	t.eq(r.gold, int(r.chapter["start_gold"]), "starting gold from the chapter")
	t.eq(r.truck_hp, GC.TRUCK_MAX_HP, "full truck durability")
	t.eq(r.shop.size(), 5, "shop rolled")
	t.eq(r.board_units().size(), 3, "all three start deployed around the truck")
	t.eq(r.board_count(), 2, "Node Basic takes no deploy slot")
	t.eq(r.phase, "map", "a run starts on the map")
	t.eq(r.total_nodes(), 3, "chapter 0 has three map nodes")
	for u: Dictionary in r.board_units():
		t.ok(GC.is_deploy_cell(u["cell"]), "starting units stand in the deploy zone")


func test_buy_spends_gold_and_uses_the_bench(t: TestCtx) -> void:
	var r := _run()
	var g0: int = r.gold
	var res: Dictionary = r.buy(0)
	t.ok(res["ok"], "buy works")
	t.ok(r.gold < g0, "gold spent")
	t.eq(r.bench_units().size(), 1, "on the bench")
	t.ok(bool(r.shop[0]["sold"]), "offer marked sold")
	t.eq(r.buy(0)["reason"], "ui.err.sold", "cannot buy twice")


func test_cannot_buy_without_gold(t: TestCtx) -> void:
	var r := _run()
	r.gold = 0
	t.eq(r.buy(0)["reason"], "ui.err.no_gold", "no gold")
	t.eq(r.roll_shop(true)["reason"], "ui.err.no_gold", "no gold to refresh")


func test_three_copies_merge_into_two_star(t: TestCtx) -> void:
	var r := _run()
	r.gold = 99
	for i in range(3):
		r.shop[0] = {"def": "node_archer", "sold": false}
		# 场上已有一个一星射手，再买两个即合成
		if i == 2:
			break
		r.buy(0)
	t.eq(_bench_count(r, "node_archer"), 1, "merged into a single archer")
	for u: Dictionary in r.roster.values():
		if u["def"] == "node_archer":
			t.eq(int(u["star"]), 2, "two star")
			t.ok(u["cell"] != null, "the board copy is the one kept")


func test_sell_refunds_and_returns_equipment(t: TestCtx) -> void:
	var r := _run()
	var kn: String = ""
	for id: String in r.roster.keys():
		if r.roster[id]["def"] == "node_darkknight":
			kn = id
	r.inventory.append("sample_arcane_edge")
	t.ok(r.equip(kn, "sample_arcane_edge")["ok"], "equip")
	var inv0: int = r.inventory.size()
	var g0: int = r.gold
	t.ok(r.sell(kn)["ok"], "sell")
	t.ok(r.gold > g0, "gold refunded")
	t.eq(r.inventory.size(), inv0 + 1, "equipment returned to the inventory")


func test_equip_respects_color_and_weapon_class(t: TestCtx) -> void:
	var r := _run()
	var kn: String = ""
	for id: String in r.roster.keys():
		if r.roster[id]["def"] == "node_darkknight":
			kn = id
	r.inventory.append("order_sword")
	r.inventory.append("sample_arcane_edge")
	t.eq(r.equip(kn, "order_sword")["reason"], "ui.err.color_mismatch", "blue sword on a red unit")
	t.eq(r.equip(kn, "rapidfire_arbalest")["reason"], "ui.err.weapon_class", "the dark knight cannot use rifles")
	t.ok(r.equip(kn, "sample_arcane_edge")["ok"], "a black sword fits")
	t.eq(r.weapon_of(r.roster[kn]).id, "sample_arcane_edge", "now wielding the arcane edge")
	t.ok(r.unequip(kn)["ok"], "unequip")
	t.ok(r.inventory.has("sample_arcane_edge"), "back in the inventory")
	t.eq(r.weapon_of(r.roster[kn]).id, "basic_heavy", "falls back to its basic weapon")
	t.eq(r.unequip(kn)["reason"], "ui.err.base_weapon", "the basic weapon cannot be taken off")


func test_basic_weapon_is_replaced_and_never_enters_the_inventory(t: TestCtx) -> void:
	var r := _run()
	var ar: String = ""
	for id: String in r.roster.keys():
		if r.roster[id]["def"] == "node_archer":
			ar = id
	t.eq(r.weapon_of(r.roster[ar]).id, "basic_rifle", "the archer starts with the flintlock rifle")
	var inv0: Array = r.inventory.duplicate()
	t.ok(r.equip(ar, "rapidfire_arbalest")["ok"], "equip a real rifle")
	t.ok(not r.inventory.has("basic_rifle"), "the replaced basic weapon is not given to the player")
	t.eq(r.inventory.size(), inv0.size() - 1, "only the equipped weapon left the inventory")
	# 换另一把：旧的回背包，基础武器依旧不出现
	r.inventory.append("amplifier_crossbow")
	t.ok(r.equip(ar, "amplifier_crossbow")["ok"], "swap to another allowed class")
	t.ok(r.inventory.has("rapidfire_arbalest"), "the previous weapon returned")
	t.ok(not r.inventory.has("basic_rifle"), "still no basic weapon in the inventory")
	# 卖掉只拿着基础武器的棋子，背包不变
	r.unequip(ar)
	var inv1: int = r.inventory.size()
	r.sell(ar)
	t.eq(r.inventory.size(), inv1, "selling a piece with its basic weapon returns nothing")
	for id2: String in r.catalog.equipment_ids():
		t.ok(not r.catalog.get_equipment(id2).basic, "basic weapons are not obtainable (%s)" % id2)


func test_move_swaps_and_respects_board_capacity(t: TestCtx) -> void:
	var r := _run()
	var ids: Array = r.roster.keys()
	var a: String = ids[0]
	var b: String = ids[1]
	var ca: Vector2i = r.roster[a]["cell"]
	var cb: Vector2i = r.roster[b]["cell"]
	t.ok(r.move_unit(a, {"cell": cb})["ok"], "move onto an occupied cell swaps")
	t.eq(r.roster[a]["cell"], cb, "a took b's cell")
	t.eq(r.roster[b]["cell"], ca, "b took a's cell")
	t.eq(r.move_unit(a, {"cell": Vector2i(6, 0)})["reason"], "ui.err.bad_cell", "cannot deploy on the enemy half")
	# 满员时不能再上场
	r.gold = 99
	r.shop[0] = {"def": "node_nurse", "sold": false}
	r.buy(0)
	r.shop[1] = {"def": "node_magi", "sold": false}
	r.buy(1)
	r.shop[2] = {"def": "node_bounty", "sold": false}
	r.buy(2)
	var bench: Array[Dictionary] = r.bench_units()
	for u: Dictionary in bench:
		r.move_unit(u["id"], {"cell": Vector2i(0, r.board_units().size())})
	t.ok(r.board_units().size() <= r.board_capacity(), "never above the level cap")


func test_battle_setup_truck_in_the_middle_enemies_around(t: TestCtx) -> void:
	var r := _run()
	var dirs: Dictionary = {}
	for ni in range(r.total_nodes()):
		r.node_index = ni
		var m: BattleMap = r.current_map()
		var s: Dictionary = r.build_battle_setup()
		t.ok(s.has("map"), "the battle uses the node's map")
		for e: Dictionary in s["units"]:
			if int(e["team"]) == 0:
				t.ok(GC.is_deploy_cell(e["cell"]), "player unit inside the deploy zone")
				continue
			var p: Vector2 = e["pos"]
			var c: Vector2i = GC.world_to_cell(p)
			t.ok(not GC.DEPLOY_RECT.grow(1).has_point(c), "enemy spawns away from our deploy zone (%s)" % str(c))
			t.ok(m.in_bounds(c) and not m.blocks_move(c), "enemy spawns on a free cell (%s)" % str(c))
			dirs[int(round(fposmod(atan2(p.x, -p.y), TAU) / (PI * 0.25))) % 8] = true
	t.ok(dirs.size() >= 4, "enemies come from several directions (%d of 8)" % dirs.size())
	r.node_index = 0


func test_first_node_is_winnable_with_the_starting_team(t: TestCtx) -> void:
	var wins := 0
	for s in range(6):
		var r := _run(100 + s)
		r.travel()
		for id: String in r.roster.keys():
			if r.roster[id]["def"] == "node_archer":
				r.equip(id, "rapidfire_arbalest")
			elif r.roster[id]["def"] == "node_darkknight":
				r.equip(id, "blackblade")
		# 和真实开局一样：再买一个 1 费节点上场(等级 3 可上场 3 人)
		r.shop[0] = {"def": "node_archer", "sold": false}
		r.buy(0)
		for u: Dictionary in r.bench_units():
			r.move_unit(u["id"], {"cell": Vector2i(9, 8)})
		var b := Battle.new(Fixture.catalog(), 300 + s)
		b.setup(r.build_battle_setup())
		b.run_to_end()
		if b.winner == GC.TEAM_PLAYER:
			wins += 1
	t.ok(wins >= 5, "the starting team should beat the first reward node almost always (%d/6)" % wins)


func test_chapter_flow_map_to_nodes_to_game_over(t: TestCtx) -> void:
	var r := _run(9)
	t.eq(r.travel()["ok"], true, "leave the map for node 1")
	t.eq(r.phase, "prepare", "arrive and prepare")
	var visited := 0
	var guard := 0
	while r.phase != "over" and r.phase != "branch" and guard < 10:
		guard += 1
		if r.phase == "map":
			var g0: int = r.gold
			var shop0: String = JSON.stringify(r.shop)
			r.travel()
			t.ok(r.gold >= g0, "arrival income paid")
			t.ok(JSON.stringify(r.shop) != shop0 or r.shop_locked, "the shop refreshes for free at each node")
		var b := Battle.new(Fixture.catalog(), 50 + guard)
		b.setup(r.build_battle_setup())
		b.winner = GC.TEAM_PLAYER
		b.drops.append({"tier": "white", "pos": Vector2.ZERO})
		r.begin_battle()
		r.finish_battle(b)
		t.eq(r.phase, "loot", "after a battle: collect the orbs")
		t.eq(r.pending_orbs.size(), 1, "one orb waiting")
		var loot: Dictionary = r.open_orb(0)
		t.ok(not loot.is_empty(), "opening an orb yields loot")
		r.finish_loot()
		visited += 1
	t.eq(visited, 3, "three nodes in a straight line")
	t.eq(r.phase, "branch", "after the third node the chapter is cleared (pick a branch of chapter 1, then a truck mod)")


func test_defeat_damages_the_truck_but_the_journey_continues(t: TestCtx) -> void:
	var r := _run()
	r.travel()
	var b := Battle.new(Fixture.catalog(), 1)
	b.setup(r.build_battle_setup())
	b.winner = GC.TEAM_ENEMY
	b.truck_damage = 6
	r.begin_battle()
	var res: Dictionary = r.finish_battle(b)
	t.eq(int(res["truck_damage"]), 6 + int(r.chapter["truck_damage_base"]), "truck damage = invaders + chapter base")
	t.eq(r.truck_hp, GC.TRUCK_MAX_HP - int(res["truck_damage"]), "durability reduced")
	t.eq(r.phase, "loot", "orbs from the enemies we did kill are still collected")
	r.finish_loot()
	t.eq(r.phase, "map", "and the truck drives on")


func test_truck_destroyed_ends_the_run(t: TestCtx) -> void:
	var r := _run()
	r.travel()
	r.truck_hp = 3
	var b := Battle.new(Fixture.catalog(), 1)
	b.setup(r.build_battle_setup())
	b.winner = GC.TEAM_ENEMY
	b.truck_damage = 10
	r.begin_battle()
	r.finish_battle(b)
	t.eq(r.phase, "over", "run over")
	t.ok(not r.won_run, "not a win")


func test_orb_loot_guarantee(t: TestCtx) -> void:
	# 保底：本章还剩的晶球不够时，强制开出武器
	var r := _run(3)
	r.node_index = r.total_nodes() - 1
	r.pending_orbs = [{"tier": "white", "pos": Vector2.ZERO, "opened": false, "loot": {}},
		{"tier": "white", "pos": Vector2.ZERO, "opened": false, "loot": {}}]
	r.loot_counts = {"weapon": 0, "unit": 1}
	var inv0: int = r.inventory.size()
	r.open_orb(0)
	r.open_orb(1)
	t.eq(r.inventory.size(), inv0 + 2, "two guaranteed weapons from the last two orbs")
	# 统计：大量开白色晶球，结果分布接近掉落表
	var r2 := _run(4)
	r2.node_index = r2.total_nodes() - 1
	r2.loot_counts = {"weapon": 99, "unit": 99}
	var kinds := {"gold": 0, "unit": 0, "weapon": 0}
	for i in range(400):
		r2.pending_orbs = [{"tier": "white", "pos": Vector2.ZERO, "opened": false, "loot": {}}]
		r2.roster.clear()
		var l: Dictionary = r2.open_orb(0)
		if not (l["weapons"] as Array).is_empty():
			kinds["weapon"] += 1
		elif not (l["units"] as Array).is_empty():
			kinds["unit"] += 1
		else:
			kinds["gold"] += 1
	t.ok(kinds["gold"] > 170 and kinds["gold"] < 270, "white orbs: ~55%% gold (%d/400)" % kinds["gold"])
	t.ok(kinds["unit"] > 80 and kinds["unit"] < 160, "white orbs: ~30%% nodes (%d/400)" % kinds["unit"])
	t.ok(kinds["weapon"] > 30 and kinds["weapon"] < 95, "white orbs: ~15%% weapons (%d/400)" % kinds["weapon"])


func test_storage_has_no_capacity_limit(t: TestCtx) -> void:
	var r := Run.create(Fixture.catalog(), 5)
	r.travel()
	r.gold = 999
	var bought := 0
	for k in range(8):
		for i in range(r.shop.size()):
			if not bool(r.shop[i]["sold"]) and bool(r.buy(i)["ok"]):
				bought += 1
		r.roll_shop(true)
	t.ok(bought >= 30, "bought many units (%d)" % bought)
	var bench: Array[Dictionary] = r.bench_units()
	t.ok(bench.size() > 9, "storage holds more than the old 9 cargo slots (%d)" % bench.size())
	for i in range(bench.size()):
		t.eq(int(bench[i]["bench"]), i, "storage order stays compact")
	# 场上的棋子收进仓库：排到最后
	var on_board: Dictionary = r.board_units()[0]
	t.ok(bool(r.move_unit(str(on_board["id"]), {"bench": r.free_bench_slot()})["ok"]), "store a deployed piece")
	t.eq(r.bench_units().back()["id"], on_board["id"], "stored piece goes to the end of the storage")


func test_chapter_ui_theme_exists(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	for id: String in cat.chapters.keys():
		var th: String = str((cat.chapters[id] as Dictionary).get("ui_theme", ""))
		t.ok(th != "" and UITheme.has(th), "chapter %s names a known UI theme (%s)" % [id, th])


func test_move_weapon_hands_it_to_another_piece(t: TestCtx) -> void:
	var r := _run(21)
	var ids: Array = r.roster.keys()
	var knight: String = ""
	for id: String in ids:
		if str(r.roster[id]["def"]) == "node_darkknight":
			knight = id
	var other: Dictionary = r.add_unit("node_darkknight", 1, null, r.free_bench_slot())
	r.inventory.append("sample_arcane_edge")
	t.ok(bool(r.equip(knight, "blackblade")["ok"]), "equip the greatsword")
	t.ok(bool(r.equip(str(other["id"]), "sample_arcane_edge")["ok"]), "the other knight holds a sword")
	var res: Dictionary = r.move_weapon(knight, str(other["id"]))
	t.ok(bool(res["ok"]), "hand the greatsword over")
	t.eq(str(r.roster[knight]["weapon"]), "", "the giver is back on the basic weapon")
	t.eq(str(r.roster[str(other["id"])]["weapon"]), "blackblade", "the receiver now holds it")
	t.ok(r.inventory.has("sample_arcane_edge"), "the receiver's old weapon went to the inventory")
	t.ok(not r.inventory.has("blackblade"), "the moved weapon is not duplicated into the inventory")
	# 用不了 → 什么都不变
	var archer: String = ""
	for id2: String in r.roster.keys():
		if str(r.roster[id2]["def"]) == "node_archer":
			archer = id2
	var res2: Dictionary = r.move_weapon(str(other["id"]), archer)
	t.ok(not res2["ok"], "an archer can't take a greatsword")
	t.eq(str(r.roster[str(other["id"])]["weapon"]), "blackblade", "refused: nothing changed")
