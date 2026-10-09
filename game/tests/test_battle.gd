extends RefCounted
## 战斗层测试：自由移动 AI 的不变量、确定性、关键词行为。


func _team(defs: Array, team: int, base_col: int) -> Array:
	var r: Array = []
	var row := 0
	for d: Variant in defs:
		var cell := Vector2i(base_col + (row / 5), 3 + row % 5)
		r.append({"def": str(d), "team": team, "star": 1, "cell": cell, "equipment": []})
		row += 1
	return r


func _run(player: Array, enemy: Array, seed_value: int = 11) -> Battle:
	var b := Battle.new(Fixture.catalog(), seed_value)
	var list: Array = []
	list.append_array(_team(player, 0, 5))
	list.append_array(_team(enemy, 1, 12))
	b.setup({"units": list})
	b.run_to_end()
	return b


func test_battle_terminates_with_a_winner(t: TestCtx) -> void:
	var b := _run(["node_archer", "node_darkknight", "node_nurse"], ["node_shielder", "node_berserker", "node_magi"])
	t.eq(b.state, "ended", "battle ended")
	t.ok(b.winner >= 0 and b.winner <= 2, "winner set")
	t.ok(b.time <= GC.START_DELAY + GC.BATTLE_MAX_SECONDS + 0.5, "within the time cap (%.1f s)" % b.time)


func test_units_stay_inside_arena_and_finite(t: TestCtx) -> void:
	var b := Battle.new(Fixture.catalog(), 5)
	var list: Array = []
	list.append_array(_team(["node_archer", "node_darkknight", "node_dancer", "node_nurse"], 0, 5))
	list.append_array(_team(["node_berserker", "node_vine", "node_magi", "node_bounty"], 1, 12))
	b.setup({"units": list})
	b.start()
	var bad := 0
	var overlap_bad := 0
	for step in range(int(45.0 / GC.SIM_DT)):
		b.step()
		b.events.clear()
		var alive: Array[BUnit] = b.alive_units()
		for u: BUnit in alive:
			if not (is_finite(u.pos.x) and is_finite(u.pos.y)):
				bad += 1
			if absf(u.pos.x) > GC.map_half().x + 0.01 or absf(u.pos.y) > GC.map_half().y + 0.01 or not b.map.circle_free(u.pos, u.radius * 0.8):
				bad += 1
		if step % 8 == 0:
			for i in range(alive.size()):
				for j in range(i + 1, alive.size()):
					var d: float = alive[i].pos.distance_to(alive[j].pos)
					if d < (alive[i].radius + alive[j].radius) * 0.75:
						overlap_bad += 1
		if b.state == "ended":
			break
	t.eq(bad, 0, "positions finite, inside the map and never inside obstacles/the truck")
	t.ok(overlap_bad < 12, "bodies do not stay overlapped (%d samples)" % overlap_bad)


func test_battle_is_deterministic(t: TestCtx) -> void:
	var a := _run(["node_archer", "node_darkknight", "node_nurse"], ["node_shielder", "node_berserker", "node_magi"], 99)
	var c := _run(["node_archer", "node_darkknight", "node_nurse"], ["node_shielder", "node_berserker", "node_magi"], 99)
	t.eq(a.winner, c.winner, "same winner")
	t.near(a.time, c.time, 0.0001, "same duration")
	var da := 0.0
	var dc := 0.0
	for u: BUnit in a.units:
		da += u.st_damage
	for u2: BUnit in c.units:
		dc += u2.st_damage
	t.near(da, dc, 0.001, "same total damage")


func test_melee_closes_distance_and_hits(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_darkknight", "pos": Vector2(-5, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(4, 0)}])
	b.start()
	var t_first_hit := -1.0
	for step in range(int(15.0 / GC.SIM_DT)):
		b.step()
		for e: Dictionary in b.events:
			if e.get("t") == "damage" and e.get("surface") == "normal_attack" and t_first_hit < 0.0:
				t_first_hit = b.time
		b.events.clear()
		if t_first_hit > 0.0:
			break
	t.ok(t_first_hit > 0.0, "melee unit reached the dummy and hit it")
	t.ok(t_first_hit < 8.0, "in a sensible time (%.1f s)" % t_first_hit)


func test_ranged_unit_kites_melee_threat(t: TestCtx) -> void:
	# 弓手站在场中，近战敌人从近处冲来：弓手应该拉开距离，而不是原地被贴脸
	var b := Fixture.make([{"def": "node_archer", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.7, 0)}])
	b.start()
	b.units[1].attack_cd = 9.0     # 让近战暂时不出手，观察走位
	b.units[0].attack_cd = 3.0
	var d0: float = b.units[0].pos.distance_to(b.units[1].pos)
	var max_d := 0.0
	for step in range(int(3.5 / GC.SIM_DT)):
		b.step()
		b.events.clear()
		b.units[1].attack_cd = 9.0
		if b.state == "running":
			max_d = maxf(max_d, b.units[0].pos.distance_to(b.units[1].pos))
	t.ok(max_d > d0 + 0.8, "archer backed off (start %.2f m, max %.2f m)" % [d0, max_d])


func test_pursuit_repeats_normal_attack(t: TestCtx) -> void:
	# sample_archer：第 4 次普攻命中触发[追击1]：额外一次普攻副本
	var b := Fixture.make([{"def": "sample_archer", "pos": Vector2.ZERO}, {"def": "test_dummy", "team": 1, "pos": Vector2(2, 0)}])
	for i in range(4):
		b.pipeline.normal_attack(b.units[0], b.units[1])
	b.advance_pending(1.0)                 # 副本是一次真的普攻：弓会再射一支箭，落地才结算
	var copies: int = Fixture.events_of(b, "attack_copy").size()
	t.eq(copies, 1, "exactly one pursuit copy on the 4th hit")
	var dmg_events: int = Fixture.events_of(b, "damage", "normal_attack").size()
	t.eq(dmg_events, 5, "4 real attacks + 1 copy")


func test_multi_attack_and_splash_limits(t: TestCtx) -> void:
	# 狂猎节点的狼狩：[群攻3]，落地时身旁 5 个敌人只会被砍到 3 个
	var specs: Array = [{"def": "node_berserker", "pos": Vector2.ZERO}]
	for i in range(5):
		specs.append({"def": "test_dummy", "team": 1, "pos": Vector2(4.0 + 0.3 * float(i % 2), -0.9 + 0.45 * float(i))})
	var b := Fixture.make(specs)
	b.start()
	var guard := 0
	while Fixture.events_of(b, "dash_strike").is_empty() and guard < 400:
		b.step()
		guard += 1
	var seen: Dictionary = {}
	for e: Dictionary in Fixture.events_of(b, "damage", "passive"):
		seen[e["dst"]] = true
	t.eq(seen.size(), 3, "[multi_attack 3] limits the dash strike to 3 targets")


func test_crit_uses_crit_stats(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2.ZERO}, {"def": "test_dummy", "team": 1, "pos": Vector2(1, 0)}])
	b.units[0].base.crit_chance = 1.0
	b.units[0].base.crit_damage = 2.0
	b.units[0].mark_dirty()
	b.pipeline.normal_attack(b.units[0], b.units[1])
	var d: Array[Dictionary] = Fixture.events_of(b, "damage", "normal_attack")
	t.eq(d.size(), 1, "one normal attack damage")
	t.ok(bool(d[0]["crit"]), "crit flagged")
	t.near(float(d[0]["amount"]), 200.0, 0.01, "100 attack x 2.0 crit damage vs 0 defense")


func test_awakening_gates_ability_until_task_done(t: TestCtx) -> void:
	# 守誓节点：[觉醒:队友被击杀]之前"誓血仇"不生效；队友被击杀后才生效
	var b := Fixture.make([{"def": "node_darkknight", "pos": Vector2.ZERO}, {"def": "test_dummy", "pos": Vector2(0, 2)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(1.2, 0)}])
	var kn: BUnit = b.units[0]
	var hp0: float = kn.hp
	b.pipeline.normal_attack(kn, b.units[2])
	t.near(kn.hp, hp0, 0.001, "blood oath inactive before awakening")
	b.units[1].hp = 0.0
	b.pipeline.fx.try_kill(b.units[1], b.units[2])      # 队友阵亡
	t.ok(bool(kn.awakened.get("node_darkknight_vendetta", false)), "awakened after an ally died")
	b.pipeline.normal_attack(kn, b.units[2])
	t.ok(kn.hp < hp0, "Blood Vendetta now drains 10%% max health (hp %.1f -> %.1f)" % [hp0, kn.hp])


func test_summon_at_battle_start(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_dancer", "pos": Vector2(-3, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(4, 0)}])
	b.start()
	var found := false
	for u: BUnit in b.units:
		if u.def.id == "node_warrior" and u.is_summon and u.team == 0:
			found = true
	t.ok(found, "First-Star Idol summons Node Warrior at battle start")
	# 只召唤一次(已有护星节点时条件不满足)
	var count := 0
	for u2: BUnit in b.units:
		if u2.def.id == "node_warrior":
			count += 1
	t.eq(count, 1, "exactly one warrior")


func test_chant_delays_and_releases(t: TestCtx) -> void:
	# 巫术节点：开战就开始吟唱【吟唱 5】的虹光飞弹
	var b := Fixture.make([{"def": "node_wizard", "pos": Vector2(-2, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.0, 0)}])
	b.start()
	var chant_started := -1.0
	var released := -1.0
	for step in range(int(20.0 / GC.SIM_DT)):
		b.step()
		for e: Dictionary in b.events:
			if e.get("t") == "chant_start" and chant_started < 0.0:
				chant_started = b.time
			if e.get("t") == "chant_release" and released < 0.0:
				released = b.time
		b.events.clear()
		if released > 0.0:
			break
	t.ok(chant_started > 0.0 and released > chant_started, "chant started then released")
	# 开战时机(倒计时里)开始的吟唱从真正开打才计时
	t.near(released - maxf(chant_started, GC.START_DELAY), 5.0, 0.1, "[chant 5] lasts about 5 seconds")


## (羁绊的测试在 test_traits.gd)


func test_units_start_facing_the_nearest_enemy(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_archer", "pos": Vector2.ZERO}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, -5)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(4, 4)}])
	b.start()
	var a: BUnit = b.units[0]
	var want: float = GC.facing_to(a.pos, Vector2(0, -5))
	t.near(angle_difference(a.facing, want), 0.0, 0.01, "player piece faces the nearest enemy (north)")
	var e: BUnit = b.units[2]
	t.near(angle_difference(e.facing, GC.facing_to(e.pos, a.pos)), 0.0, 0.01, "enemy faces the nearest player piece")
