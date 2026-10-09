extends RefCounted
## 浪游节点：开枪最快之人(普攻间隔固定、不吃攻速；弹匣 = 叠加 6、换弹 1.5 秒；1 米外 25% 打空)、
## 随心所欲(2 星：备战时可以部署到全场没有地形的格子)、装弹器(换弹时触发)、专属武器转瞬即逝(射程 1 米内；大口径子弹：6 发必暴 + 基础伤害加成，用完后不暴击、伤害 ×0.7)。


func _run_until(b: Battle, sec: float) -> void:
	while b.time < sec and b.state != "ended":
		b.step()


func _no_crit(u: BUnit) -> void:
	u.base.crit_chance = 0.0
	u.mark_dirty()


func test_unit_data(t: TestCtx) -> void:
	var d: UnitDef = Fixture.catalog().get_unit("node_cowboy")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role], [2, "green", "information", "assassin"], "rarity 2, green, Information, assassin")
	t.eq(d.special_traits, ["clan"] as Array[String], "special tag 宗族")
	t.eq(d.weapon_classes, ["crossbow", "pistols"] as Array[String], "one-handed ranged default; dual ranged allowed")
	t.eq(d.deploy_anywhere_star, 2, "deploys anywhere from 2★")
	var e: EquipmentDef = Fixture.catalog().get_equipment("fleeting_revolver")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["crossbow", "black", 2, "node_cowboy"], "Fleeting: one-handed ranged, black, rarity 2, his")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_fixed_interval_ammo_and_reload(t: TestCtx) -> void:
	for star: int in [1, 3]:
		var b := Fixture.make([{"def": "node_cowboy", "pos": Vector2(0, 0), "star": star}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.9)}])
		var c: BUnit = b.units[0]
		b.start()
		c.base.attack_speed_multiplier = 3.0           # 攻速不影响
		c.mark_dirty()
		_run_until(b, GC.START_DELAY + 4.0)
		# 数 4 秒里出手了几次、换了几次弹
		var shots := Fixture.events_of(b, "attack_start").size()
		var rl := Fixture.events_of(b, "reload_start").size()
		var iv: float = [0.166, 0.133, 0.1][star - 1]
		var cycle: float = 6.0 * iv + 1.5
		var want_shots: int = int(floor(4.0 / cycle)) * 6 + mini(6, int((4.0 - floor(4.0 / cycle) * cycle) / iv) + 1)
		t.ok(absi(shots - want_shots) <= 2, "%d★: ~%d shots in 4 s (got %d; interval %.3f, 6 rounds, 1.5 s reload)" % [star, want_shots, shots, iv])
		t.ok(rl >= 1, "%d★: reloads" % star)
		var am: BStatus = b.pipeline.ammo(c)
		t.ok(am != null and am.max_stacks == 6, "magazine = Stacking 6")


func test_far_shots_miss_a_quarter(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_cowboy", "pos": Vector2(0, 0), "star": 3}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 3.5)}], 21)
	var c: BUnit = b.units[0]
	b.start()
	c.base.move_speed = 0.0
	c.mark_dirty()
	_run_until(b, GC.START_DELAY + 70.0)
	var rel := 0
	var miss := 0
	for e: Dictionary in Fixture.events_of(b, "attack_release"):
		if e["unit"] == c:
			rel += 1
			if bool(e.get("missed", false)):
				miss += 1
	t.ok(rel > 150, "plenty of shots (%d)" % rel)
	t.near(float(miss) / float(maxi(1, rel)), 0.25, 0.07, "≈25%% of far shots miss (%d / %d)" % [miss, rel])
	var dmg := 0
	for e2: Dictionary in Fixture.events_of(b, "damage"):
		if e2["src"] == c:
			dmg += 1
	t.ok(absi(dmg - (rel - miss)) <= 2, "missed shots deal nothing (%d hits)" % dmg)
	# 贴身(1 米内)从不打空
	var b2 := Fixture.make([{"def": "node_cowboy", "pos": Vector2(0, 0), "star": 3}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.9)}], 21)
	b2.start()
	_run_until(b2, GC.START_DELAY + 10.0)
	var m2 := 0
	for e3: Dictionary in Fixture.events_of(b2, "attack_release"):
		if bool(e3.get("missed", false)):
			m2 += 1
	t.eq(m2, 0, "point blank: never misses")


func test_loader_and_big_caliber_rounds(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_cowboy", "pos": Vector2(0, 0), "weapon": "fleeting_revolver"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.85)}], 3)
	var c: BUnit = b.units[0]
	_no_crit(c)
	b.start()
	t.near(c.get_stats().range_meters(), 0.98, 0.01, "Fleeting: range just under 1 m in his hands")
	_run_until(b, GC.START_DELAY + 1.0)
	t.eq(c.status_stacks("big_caliber"), 0, "no rounds before the first reload")
	while c.status_stacks("big_caliber") == 0 and b.time < 8.0:
		b.step()
	t.eq(c.status_stacks("big_caliber"), 1, "first reload → Big-Caliber Rounds")
	var n0: int = Fixture.events_of(b, "damage").size()
	_run_until(b, b.time + 1.2)
	var st: StatBlock = c.get_stats()
	var y: float = 0.15
	var na: float = st.attack_power * 0.7
	var bonus: float = st.attack_power * y * 1.0
	var big: Array[Dictionary] = []
	for e: Dictionary in Fixture.events_of(b, "damage").slice(n0):
		if e["src"] == c:
			big.append(e)
	t.ok(big.size() >= 6, "a full magazine after the reload (%d)" % big.size())
	if big.size() >= 6:
		var all_crit := true
		for i in range(6):
			all_crit = all_crit and bool(big[i]["crit"])
		t.ok(all_crit, "the next 6 shots all crit (crit chance 0)")
		t.near(float(big[0]["amount"]), (na + bonus) * st.crit_damage, 0.5, "base damage + attack × y, then × crit damage")
	# 次数用完、还没换弹：把状态的次数清零再打一发
	var emp: Dictionary = c.get_status("big_caliber").meta["empower"]
	emp["left"] = 0
	c.base.crit_chance = 1.0
	c.mark_dirty()
	b.events.clear()
	b.pipeline.normal_attack(c, b.units[1])
	var after: Array[Dictionary] = Fixture.events_of(b, "damage")
	t.ok(not after.is_empty() and not bool(after[0]["crit"]), "used up: never crits (even at 100% crit chance)")
	if not after.is_empty():
		t.near(float(after[0]["amount"]), na * 0.7, 0.5, "and deals 30% less")
	# 再次获得：重置次数
	b.pipeline.refill_ammo(c)
	t.eq(int(c.get_status("big_caliber").meta["empower"]["left"]), 6, "gaining it again resets the 6 guaranteed crits")
	t.ok(not c.get_status("big_caliber").has_flag("dispellable"), "can't be dispelled")


func test_deploy_anywhere_from_two_stars(t: TestCtx) -> void:
	var r := Run.create(Fixture.catalog(), 5)
	r.phase = "map"
	r.travel()
	t.eq(r.phase, "prepare", "preparing")
	var m: BattleMap = r.current_map()
	var far := Vector2i(-1, -1)
	var blocked := Vector2i(-1, -1)
	for cx in range(GC.MAP_W):
		for cy in range(GC.MAP_H):
			var c := Vector2i(cx, cy)
			if GC.DEPLOY_RECT.has_point(c):
				continue
			if far.x < 0 and not m.blocks_move(c) and cy <= 2:
				far = c
			if blocked.x < 0 and m.blocks_move(c):
				blocked = c
	t.ok(far.x >= 0 and blocked.x >= 0, "(test setup: a free far cell and a terrain cell)")
	r.level = 9
	var u1: Dictionary = r.add_unit("node_cowboy", 1, null, r.free_bench_slot())
	t.eq(r.move_unit(str(u1["id"]), {"cell": far})["reason"], "ui.err.bad_cell", "1★: only the deploy zone")
	u1["star"] = 2
	t.ok(r.move_unit(str(u1["id"]), {"cell": far})["ok"], "2★: anywhere on the battlefield")
	t.eq(r.move_unit(str(u1["id"]), {"cell": blocked})["reason"], "ui.err.bad_cell", "but not on terrain")
	t.eq(r.move_unit(str(u1["id"]), {"cell": Vector2i(12, 9)})["reason"], "ui.err.bad_cell", "nor on the truck")
	var setup: Dictionary = r.build_battle_setup()
	var found := false
	for e: Dictionary in setup["units"]:
		if e.get("roster_id", "") == u1["id"]:
			found = e["cell"] == far
	t.ok(found, "the battle starts him there")
	# 这一场能站、下一场那里有地形：进入备战时挪回部署区
	u1["cell"] = blocked
	r._fix_board_cells()
	t.ok(u1["cell"] != null and GC.is_deploy_cell(u1["cell"]), "a cell that became invalid is moved back into the deploy zone")


func test_shoots_whoever_he_was_placed_next_to(t: TestCtx) -> void:
	# 随心所欲的用法：把他放到想切的目标旁边——开场就打那个人(而不是刺客模版的"最脆的后排")，打死前不换人
	var b := Fixture.make([{"def": "node_cowboy", "pos": Vector2(0, 0), "star": 2, "weapon": "fleeting_revolver"},
		{"def": "node_shielder", "team": 1, "pos": Vector2(0, 0.9), "star": 1},
		{"def": "node_archer", "team": 1, "pos": Vector2(2.5, 3.0), "star": 1},
		{"def": "node_student", "team": 1, "pos": Vector2(-2.5, 3.0), "star": 1}], 9)
	var c: BUnit = b.units[0]
	var tank: BUnit = b.units[1]
	b.start()
	_run_until(b, GC.START_DELAY + 0.3)
	t.eq(c.target, tank, "opens on the enemy next to him (the tank), not the squishiest one")
	var switched := false
	while tank.alive and b.time < GC.START_DELAY + 25.0 and b.state != "ended":
		b.step()
		if tank.alive and c.target != tank and c.target != null:
			switched = true
	t.ok(not switched, "keeps shooting it until it falls")
	var hits := 0
	for e: Dictionary in Fixture.events_of(b, "damage"):
		if e["src"] == c and e["dst"] == tank and float(e["time"]) < GC.START_DELAY + 1.6:
			hits += 1
	t.ok(hits >= 6, "a whole magazine into it right away (%d hits in the first 1.6 s)" % hits)
