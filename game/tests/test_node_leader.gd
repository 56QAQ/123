extends RefCounted
## 真望节点：引导之矢(9 层金矢：减伤；普攻锁定充能不满的队友 → 回 1 层充能 + 黄金的指引("敌我不分" → "仅限敌人"))、
## 少女真心(2 星【觉醒：我方共 ≥ 27 层充能】每场限一次：全灭时复活所有具有充能的友方，被动充能补满，每点充能上限回 10% 生命)、
## 勇气(自己阵亡) + 专武至远的弓弦(拉满弦的普攻 +2 个目标；【充能 9】刷新触发目标"每场战斗限一次"的技能)；唯一(场上不能有两个)。


func _step(b: Battle) -> Array[Dictionary]:
	b.step()
	return b.poll_events()


static func _of(evs: Array[Dictionary], type: String) -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for e: Dictionary in evs:
		if e.get("t") == type:
			r.append(e)
	return r


func _run(b: Battle, sec: float) -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	while b.time < sec and b.state != "ended":
		all.append_array(_step(b))
	return all


func _tough(u: BUnit) -> void:
	u.base.max_health = 1.0e6
	u.mark_dirty()
	u.get_stats()
	u.hp = 1.0e6


func _x(star: int) -> float:
	for pa: AbilityDef in Fixture.catalog().get_unit("node_leader").passives:
		if pa.id == "node_leader_arrows":
			return float(((pa.effect_config["stats_by_star"] as Dictionary)["damage_taken_pct"] as Dictionary)["flat"][str(star)])
	return 0.0


func _kill(b: Battle, u: BUnit) -> void:
	u.meta["_doomed"] = true
	u.hp = 0.0
	b.pipeline.fx.try_kill(u, null)


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = cat.get_unit("node_leader")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.unique], [2, "cyan", "engineering", "archer", "bow", true],
		"rarity 2, cyan, Engineering, archer, bow, unique")
	t.eq(d.weapon_classes, ["bow", "rifle", "pistols", "crossbow"] as Array[String], "bow, two-handed / dual / one-handed ranged")
	var e: EquipmentDef = cat.get_equipment("farthest_string")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["bow", "cyan", 5, "node_leader"], "Farthest String: bow, cyan, rarity 5, hers")
	t.near(float(e.flat_mods.get("full_draw_extra_targets", 0.0)), 2.0, 0.001, "fully drawn: +2 targets")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_only_one_on_the_board(t: TestCtx) -> void:
	var r := Run.create(Fixture.catalog(), 5)
	r.phase = "map"
	r.travel()
	var cells: Array = GC.deploy_cells()
	var a: Dictionary = r.add_unit("node_leader", 1, null, r.free_bench_slot())
	var b2: Dictionary = r.add_unit("node_leader", 1, null, r.free_bench_slot())
	t.ok(bool(r.move_unit(str(a["id"]), {"cell": cells[0]})["ok"]), "the first one goes on the board")
	var res: Dictionary = r.move_unit(str(b2["id"]), {"cell": cells[1]})
	t.ok(not bool(res["ok"]) and str(res.get("error", res.get("reason", ""))).contains("unique"), "the second one is refused: \"that node is unique\" (%s)" % str(res))


func test_golden_arrows(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_leader", "pos": Vector2(-1.0, -4.0), "star": 2}, {"def": "node_magi", "pos": Vector2(1.0, -4.0), "star": 2},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 5)}])
	var ld: BUnit = b.units[0]
	var mg: BUnit = b.units[1]
	b.start()
	mg.base.move_speed = 0.0                                    # 幻彩节点钉在原地(别跑去打木桩、自己用掉充能)
	mg.mark_dirty()
	_run(b, 0.1)
	t.eq(ld.status_stacks("golden_arrow"), 9, "9 Golden Arrows")
	var ga: BStatus = ld.get_status("golden_arrow")
	t.ok(ga != null and not ga.has_flag("dispellable") and ga.expires_at < 0.0, "can't be dispelled, lasts forever")
	t.near(ld.get_stats().damage_taken_pct, 9.0 * _x(2), 0.001, "%.0f%% damage reduction per stack" % (_x(2) * 100.0))
	mg.ability_charges["node_magi_colors"] = 5
	var evs: Array[Dictionary] = []
	var arrows: Array[Dictionary] = []
	while b.time < GC.START_DELAY + 4.0 and arrows.is_empty():
		var ev: Array[Dictionary] = _step(b)
		evs.append_array(ev)
		arrows.append_array(_of(ev, "golden_arrow"))
	t.eq(arrows.size(), 1, "her normal attack goes to the ally whose charges aren't full")
	t.eq(int(mg.ability_charges.get("node_magi_colors", 0)), 6, "+1 charge")
	t.eq(mg.status_stacks("golden_guidance"), 1, "+1 Golden Guidance")
	t.ok(mg.has_flag("enemies_only"), "friend-or-foe becomes enemies-only")
	t.eq(ld.status_stacks("golden_arrow"), 8, "one arrow spent")
	var hurt := false
	for e: Dictionary in _of(evs, "damage"):
		if e["src"] == ld and e["dst"] == mg:
			hurt = true
	t.ok(not hurt, "the arrow doesn't hurt the ally")
	# 队友充能满了 → 照常打敌人
	mg.ability_charges["node_magi_colors"] = 9
	var hit_enemy := false
	b.units[2].pos = Vector2(-1.0, 1.0)
	for e2: Dictionary in _of(_run(b, b.time + 6.0), "damage"):
		if e2["src"] == ld and e2["dst"] == b.units[2]:
			hit_enemy = true
	t.ok(hit_enemy, "with nobody to refill she shoots the enemy")
	t.eq(ld.status_stacks("golden_arrow"), 8, "…and keeps her arrows")


func test_guidance_makes_finales_enemies_only(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_magi", "pos": Vector2(0, 0), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.5)},
		{"def": "test_dummy", "pos": Vector2(1.5, 0)}])
	var mg: BUnit = b.units[0]
	b.start()
	_tough(b.units[1])
	_tough(b.units[2])
	b.pipeline.fx.apply_status(mg, mg, {"status_id": "golden_guidance", "flags": ["buff", "no_dispel", "enemies_only"], "max_stacks": 9}, {})
	_run(b, GC.START_DELAY + 0.05)
	for i in range(9):
		b.pipeline.fx.damage(mg, b.units[1], 10.0, "physical", {"surface": "other"})
		b.pipeline.drain()
	var hp_ally: float = b.units[2].hp
	var fin: Array[Dictionary] = []
	while b.time < GC.START_DELAY + 10.0 and mg.alive:
		fin.append_array(_of(_step(b), "magi_finale"))
	t.eq(fin.size(), 1, "the Grand Finale goes off")
	t.near(b.units[2].hp, hp_ally, 0.01, "Golden Guidance: the ally in range takes nothing (ticks or finale)")
	t.ok(b.units[1].hp < 1.0e6 - 1000.0, "the enemy still does")


func test_true_heart_revives_once(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_leader", "pos": Vector2(-3, -4), "star": 2}, {"def": "node_magi", "pos": Vector2(-1, -4), "star": 2},
		{"def": "node_spy", "pos": Vector2(1, -4), "star": 2}, {"def": "node_medium", "pos": Vector2(3, -4), "star": 2},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var ld: BUnit = b.units[0]
	b.start()
	_tough(b.units[4])
	_run(b, GC.START_DELAY + 0.1)
	t.ok(bool(ld.awakened.get("node_leader_heart", false)), "awakened: 27 charges on our side")
	b.units[1].ability_charges["node_magi_colors"] = 2
	for i in range(4):
		_kill(b, b.units[i])
	var evs: Array[Dictionary] = _run(b, b.time + 0.1)
	var rv: Array[Dictionary] = _of(evs, "team_revive")
	t.eq(rv.size(), 1, "all fallen → True Heart")
	t.ok(b.state != "ended", "the battle goes on")
	t.ok(not ld.alive, "she has no charges herself: stays down")
	for k in range(1, 4):
		var u: BUnit = b.units[k]
		t.ok(u.alive, "%s revived" % u.def.id)
		t.near(u.hp, u.get_stats().max_health * 0.9, 1.0, "…at 9 × 10%% = 90%% health")
	t.eq(int(b.units[1].ability_charges.get("node_magi_colors", 0)), 9, "passive charges full again")
	for k2 in range(1, 4):
		_kill(b, b.units[k2])
	_run(b, b.time + 0.2)
	t.ok(b.state == "raid" or b.state == "ended", "once per battle: the next wipe ends it (%s)" % b.state)


func test_farthest_string_refreshes(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_leader", "pos": Vector2(-3, -4), "star": 2, "weapon": "farthest_string"}, {"def": "node_magi", "pos": Vector2(-1, -4), "star": 2},
		{"def": "node_spy", "pos": Vector2(1, -4), "star": 2}, {"def": "node_medium", "pos": Vector2(3, -4), "star": 2},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var ld: BUnit = b.units[0]
	b.start()
	_tough(b.units[4])
	_run(b, GC.START_DELAY + 0.1)
	var revives := 0
	for round_i in range(12):
		for i in range(4):
			if b.units[i].alive:
				_kill(b, b.units[i])
		revives += _of(_run(b, b.time + 0.1), "team_revive").size()
		if b.state != "running":
			break
	t.eq(revives, 9, "9 charges, the first spent while True Heart was still unused → 9 revives in all")
	t.ok(b.state != "running", "then the battle is lost (%s)" % b.state)
	t.eq(int(ld.ability_charges.get("farthest_string_renew", -1)), 0, "all charges used")
