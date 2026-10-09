extends RefCounted
## 幻形节点：千变万化(【充能 9】；只能部署在敌人身边一圈；被敌人索敌 → 消耗 1 层给它【误导】：4 秒内强制索敌自己的队友，精英 / 首领免疫自相残杀但照样换目标)、
## 少女幻嘘(1 星起：充能用光 → 【吟唱 9】范围里所有人维持误导，结束时范围里所有人【眩晕】吟唱秒数 × x%，然后强制阵亡)、
## 【眩晕】(打断吟唱、"每 x 秒"的触发器暂停、精英 / 首领时长减半)、小小收获(战斗结束还活着：已用充能 × 1/1/2) + 专武万语千言(充能 +2；金币 + 经验)。


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


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = cat.get_unit("node_spy")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class], [3, "white", "information", "assassin", "dual"],
		"rarity 3, white, Information, assassin, dual melee")
	t.eq(d.weapon_classes, ["dual", "pistols", "crossbow", "sword"] as Array[String], "can also use dual ranged, one-handed ranged and one-handed melee")
	t.ok(d.deploy_near_enemies, "deploys only around enemies")
	var e: EquipmentDef = cat.get_equipment("myriad_words")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["dual", "white", 3, "node_spy"], "Myriad Words: dual, white, rarity 3, hers")
	t.near(float(e.flat_mods.get("passive_charges_bonus", 0.0)), 2.0, 0.001, "+2 charges")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_deploys_only_around_enemies(t: TestCtx) -> void:
	var r := Run.create(Fixture.catalog(), 5)
	r.phase = "map"
	r.travel()
	t.eq(r.phase, "prepare", "in prepare")
	var spy: Dictionary = r.add_unit("node_spy", 1, null, r.free_bench_slot())
	var ring: Dictionary = r.near_enemy_cells()
	t.ok(not ring.is_empty(), "there are cells around the enemies (%d)" % ring.size())
	var wave: Array = r.wave_def().get("units", [])
	var enemy_cells := {}
	for p: Vector2 in r.catalog.wave_positions(wave, r.current_map()):
		enemy_cells[GC.world_to_cell(p)] = true
	var ok_all := true
	for c: Vector2i in ring.keys():
		var near := false
		for ec: Vector2i in enemy_cells.keys():
			if absi(ec.x - c.x) <= 1 and absi(ec.y - c.y) <= 1:
				near = true
		ok_all = ok_all and near and not enemy_cells.has(c)
	t.ok(ok_all, "every allowed cell touches an enemy and none is an enemy's own cell")
	t.ok(not r.can_deploy_at(spy, GC.deploy_cells()[0]), "the normal deployment zone is not allowed")
	t.ok(r.can_deploy_at(spy, ring.keys()[0]), "a cell next to an enemy is")
	t.ok(bool(r.move_unit(str(spy["id"]), {"cell": ring.keys()[0]})["ok"]), "…and she can be moved there")
	var other: Dictionary = r.add_unit("node_archer", 1, null, r.free_bench_slot())
	t.ok(not r.can_deploy_at(other, ring.keys()[0]) or GC.is_deploy_cell(ring.keys()[0]), "other pieces still use the deployment zone")


func test_targeting_her_misleads(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_spy", "pos": Vector2(0, 0)}, {"def": "node_peasant", "team": 1, "pos": Vector2(0, 1.2)},
		{"def": "node_peasant", "team": 1, "pos": Vector2(0, 3.0)}])
	var spy: BUnit = b.units[0]
	var a: BUnit = b.units[1]
	var c: BUnit = b.units[2]
	b.start()
	for u: BUnit in b.units:
		_tough(u)
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 0.3)
	t.ok(a.misled_status() != null, "the enemy that targeted her is Misled")
	var st: BStatus = a.misled_status()
	t.ok(st != null and st.has_flag("dispellable") and st.has_flag("debuff") and st.max_stacks == 1, "dispellable debuff, doesn't stack")
	t.ok(a.target == c, "…and now targets its own ally")
	t.eq(int(spy.ability_charges.get("node_spy_shift", 9)), 7, "one charge per enemy that targeted her (2 enemies)")
	evs.append_array(_run(b, GC.START_DELAY + 3.0))
	var ff := 0.0
	for e: Dictionary in _of(evs, "damage"):
		if e["src"] == a and e["dst"] == c:
			ff += float(e["amount"])
	t.ok(ff > 0.0, "friendly fire (%d damage to its ally)" % int(ff))
	_run(b, GC.START_DELAY + 4.6)
	t.ok(a.misled_status() == null, "lasts 4 s")


func test_elites_resist_friendly_fire(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_spy", "pos": Vector2(0, 0)}, {"def": "node_peasant", "team": 1, "pos": Vector2(0, 1.2)},
		{"def": "node_peasant", "team": 1, "pos": Vector2(0, 3.0)}, {"def": "node_archer", "team": 0, "pos": Vector2(3.0, -2.0)}])
	b.units[1].meta["elite"] = true
	b.start()
	for u: BUnit in b.units:
		_tough(u)
	_run(b, GC.START_DELAY + 0.5)
	var el: BUnit = b.units[1]
	t.ok(el.misled_status() != null, "the elite is Misled too")
	t.ok(el.target != null and el.target.team != el.team, "…but doesn't turn on its allies")
	t.ok(el.target != b.units[0], "…and picks someone other than her")


func test_scrolls_add_charges_and_harvest(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_spy", "pos": Vector2(0, -5), "weapon": "myriad_words"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var spy: BUnit = b.units[0]
	b.start()
	var ab: AbilityDef = null
	for pa: AbilityDef in spy.def.passives:
		if pa.id == "node_spy_shift":
			ab = pa
	t.eq(Pipeline.kw_value(spy, ab, "charged"), 11, "Myriad Words: 【Charged】 9 + 2")
	_run(b, GC.START_DELAY + 0.2)
	spy.ability_charges["node_spy_shift"] = 6                  # 用掉 5 层
	b.pipeline.fx.damage(spy, b.units[1], 1.0e7, "true", {"surface": "other"})
	_run(b, b.time + 0.2)
	t.eq(b.state, "ended", "battle over")
	t.eq(int(b.gold_gain[GC.TEAM_PLAYER]), 5, "A Little Harvest: 5 charges spent × 1 → 5 gold")
	t.eq(int(b.xp_gain[GC.TEAM_PLAYER]), 5, "…and 5 experience")
	# 倒下了就不触发
	var b2 := Fixture.make([{"def": "node_spy", "pos": Vector2(0, -5), "weapon": "myriad_words"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)},
		{"def": "test_dummy", "pos": Vector2(2, -5)}])
	b2.start()
	_run(b2, GC.START_DELAY + 0.2)
	b2.units[0].ability_charges["node_spy_shift"] = 6
	b2.pipeline.fx.damage(b2.units[1], b2.units[0], 1.0e7, "true", {"surface": "other"})
	b2.pipeline.fx.damage(b2.units[2], b2.units[1], 1.0e7, "true", {"surface": "other"})
	_run(b2, b2.time + 0.2)
	t.eq(int(b2.gold_gain[GC.TEAM_PLAYER]), 0, "no harvest if she has fallen")


func test_run_collects_experience(t: TestCtx) -> void:
	var r := Run.create(Fixture.catalog(), 5)
	r.phase = "map"
	r.travel()
	var xp0: int = r.xp
	var lv0: int = r.level
	var b := Fixture.make([{"def": "test_dummy", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 4)}])
	b.start()
	b.grant_xp(GC.TEAM_PLAYER, 3)
	b.winner = GC.TEAM_PLAYER
	r.phase = "battle"
	r.finish_battle(b)
	t.ok(r.xp != xp0 or r.level != lv0, "battle experience goes into the level bar")


func test_stun_rules(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_shielder", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(3, 6)}])
	var sh: BUnit = b.units[0]
	b.start()
	_run(b, GC.START_DELAY + 1.1)
	var stun := {"status_id": "stun", "flags": ["debuff", "dispellable", "stun"], "max_stacks": 1, "duration": 2.0}
	b.pipeline.fx.apply_status(b.units[1], sh, stun, {})
	var s0: float = sh.shield
	_run(b, b.time + 1.5)
	t.ok(sh.is_stunned() and sh.shield <= s0 + 0.01, "every-second triggers pause while stunned (shield charge stops)")
	_run(b, b.time + 1.0)
	t.ok(not sh.is_stunned(), "…and it wears off")
	_run(b, b.time + 1.2)
	t.ok(sh.shield > s0 + 1.0, "then the shield charge resumes")
	b.units[2].meta["boss"] = true
	b.pipeline.fx.apply_status(b.units[1], b.units[2], stun, {})
	var bs: BStatus = b.units[2].get_status("stun")
	t.near(bs.expires_at - b.time, 1.0, 0.03, "bosses recover twice as fast (2 s → 1 s)")


func test_grand_hush(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_spy", "pos": Vector2(0, 0), "star": 2}, {"def": "node_peasant", "team": 1, "pos": Vector2(0, 1.2)},
		{"def": "node_peasant", "team": 1, "pos": Vector2(1.5, 1.5)}, {"def": "node_archer", "team": 0, "pos": Vector2(-1.5, 0.0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}])
	var spy: BUnit = b.units[0]
	b.start()
	for u: BUnit in b.units:
		_tough(u)
	spy.ability_charges["node_spy_shift"] = 1                  # 只剩 1 层：开打时第一个选中她的敌人用掉它
	b.units[3].base.move_speed = 0.0                           # 队友会躲开领域(ally_danger)：钉在原地看范围规则
	b.units[3].mark_dirty()
	var evs: Array[Dictionary] = []
	var t0 := -1.0
	while b.time < GC.START_DELAY + 4.0 and t0 < 0.0:
		var ev: Array[Dictionary] = _step(b)
		evs.append_array(ev)
		if spy.phase == "chant":
			t0 = b.time
	t.ok(t0 > 0.0, "charges out: she starts chanting")
	_run(b, t0 + 1.0)
	t.ok(b.units[3].misled_status() != null, "everyone in range is Misled, her allies included")
	t.ok(b.units[4].misled_status() == null, "…but not outside")
	var hush: Array[Dictionary] = []
	while b.time < t0 + 9.5 and spy.alive:
		hush.append_array(_of(_step(b), "spy_hush"))
	t.eq(hush.size(), 1, "the Grand Hush")
	t.ok(not spy.alive and bool(spy.meta.get("hush_death", false)), "then she falls")
	var want: float = 9.0 * 0.30
	var p1: BStatus = b.units[1].get_status("stun")
	t.ok(p1 != null, "enemies in range are stunned")
	if p1 != null:
		t.near(p1.expires_at - b.time, want, 0.1, "for chanted × 30%% = %.1f s" % want)
	t.ok(b.units[3].is_stunned(), "…allies in range too")
	t.ok(not b.units[4].is_stunned(), "…nobody outside")
