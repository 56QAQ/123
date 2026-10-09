extends RefCounted
## 战斗地图：断壁残垣(矮挡移动 / 高还挡视线与弹道)、工坊卡车(不可选中的掩体)、寻路、敌人涌入卡车扣耐久、地图生成。


func _wall_map(kind: String, rect: Rect2i, truck: bool = false) -> Dictionary:
	return {"truck": truck, "obstacles": [{"x": rect.position.x, "y": rect.position.y, "w": rect.size.x, "h": rect.size.y, "kind": kind, "style": "wall_a"}]}


func test_low_and_high_obstacles_differ_only_in_line_of_sight(t: TestCtx) -> void:
	var low := BattleMap.from_layout(_wall_map("low", Rect2i(12, 6, 1, 8)))
	var high := BattleMap.from_layout(_wall_map("high", Rect2i(12, 6, 1, 8)))
	var a := Vector2(-3, 0)
	var c := Vector2(3, 0)
	t.ok(low.has_los(a, c, GC.TEAM_PLAYER), "a low wall does not block line of sight")
	t.ok(not high.has_los(a, c, GC.TEAM_PLAYER), "a high wall blocks line of sight")
	t.ok(not low.path_clear(a, c, 0.4) and not high.path_clear(a, c, 0.4), "both block movement")
	var path: PackedVector2Array = low.find_path(a, c)
	t.ok(path.size() >= 2, "a path around the wall exists")
	for p: Vector2 in path:
		t.ok(not low.blocks_move(GC.world_to_cell(p)), "path waypoint on a free cell")


func test_truck_is_cover_with_a_mod_hook(t: TestCtx) -> void:
	var m := BattleMap.empty()
	var west := Vector2(-4, 0)
	var east := Vector2(4, 0)
	t.ok(m.blocks_move(GC.TRUCK_RECT.position), "the truck occupies its cells")
	t.ok(not m.has_los(west, east, GC.TEAM_PLAYER) and not m.has_los(west, east, GC.TEAM_ENEMY), "by default the truck blocks both sides' ranged attacks")
	m.truck_blocks_ally_los = false
	t.ok(m.has_los(west, east, GC.TEAM_PLAYER), "mod hook: allies can shoot past the truck")
	t.ok(not m.has_los(west, east, GC.TEAM_ENEMY), "…while it still shields against enemies")
	t.ok(not m.path_clear(west, east, 0.4), "the truck always blocks movement")


func test_units_walk_around_walls(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_darkknight", "pos": Vector2(-4, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(4, 0)}],
		7, _wall_map("low", Rect2i(12, 5, 1, 10)))
	b.start()
	var hit_t := -1.0
	var inside := 0
	for i in range(int(20.0 / GC.SIM_DT)):
		b.step()
		for e: Dictionary in b.events:
			if e.get("t") == "damage" and e.get("surface") == "normal_attack" and hit_t < 0.0:
				hit_t = b.time
		b.events.clear()
		if not b.map.circle_free(b.units[0].pos, b.units[0].radius * 0.8):
			inside += 1
		if hit_t > 0.0:
			break
	t.ok(hit_t > 0.0, "the melee unit found its way around the wall and hit (%.1f s)" % hit_t)
	t.eq(inside, 0, "it never walked through the wall")


func test_ranged_needs_line_of_sight(t: TestCtx) -> void:
	# 弓手和木桩之间隔着一堵高墙：必须绕到看得见的位置才会射击
	var b := Fixture.make([{"def": "node_archer", "pos": Vector2(-2.5, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(2.5, 0)}],
		7, _wall_map("high", Rect2i(12, 7, 1, 6)))
	var archer: BUnit = b.units[0]
	t.ok(not b.ai.can_hit(archer, b.units[1]), "no line of sight at the start")
	b.start()
	var first_shot_pos := Vector2(1e9, 1e9)
	for i in range(int(15.0 / GC.SIM_DT)):
		b.step()
		for e: Dictionary in b.events:
			if e.get("t") == "attack_release" and e.get("unit") == archer and first_shot_pos.x > 1e8:
				first_shot_pos = archer.pos
		b.events.clear()
		if first_shot_pos.x < 1e8:
			break
	t.ok(first_shot_pos.x < 1e8, "the archer eventually shoots")
	t.ok(b.map.has_los(first_shot_pos, b.units[1].pos, GC.TEAM_PLAYER), "…only once it can see the target")


func test_projectiles_are_blocked_by_high_walls(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_archer", "pos": Vector2(-2.5, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(2.5, 0)}],
		7, _wall_map("high", Rect2i(12, 7, 1, 6)))
	b.start()
	b.spawn_projectile(b.units[0], b.units[1], "arrow", 16.0)
	var blocked := false
	for i in range(80):
		b.step()
		for e: Dictionary in b.events:
			if e.get("t") == "projectile_end" and bool(e.get("blocked", false)):
				blocked = true
		b.events.clear()
		if blocked:
			break
	t.ok(blocked, "an arrow fired into a high wall stops there")
	t.eq(b.units[1].st_taken, 0.0, "and deals no damage")


func test_enemies_raid_the_truck_after_our_team_falls(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "test_dummy", "pos": Vector2(-3.5, 2.5)},
		{"def": "node_darkknight", "team": 1, "pos": Vector2(5, -3), "star": 2}, {"def": "node_archer", "team": 1, "pos": Vector2(6, -4)}],
		7, {"truck": true})
	b.start()
	b.units[0].hp = 0.0
	b.pipeline.fx.try_kill(b.units[0], b.units[1])
	var raided := false
	var entered := 0
	for i in range(int(20.0 / GC.SIM_DT)):
		b.step()
		for e: Dictionary in b.events:
			if e.get("t") == "raid_start":
				raided = true
			if e.get("t") == "enter_truck":
				entered += 1
		b.events.clear()
		if b.state == "ended":
			break
	t.ok(raided, "enemies start raiding the truck")
	t.eq(b.state, "ended", "the battle ends")
	t.eq(b.winner, GC.TEAM_ENEMY, "as a defeat")
	t.eq(entered, 2, "both surviving enemies entered the truck")
	t.eq(b.truck_damage, int(GC.TRUCK_DAMAGE_BY_STAR[2]) + int(GC.TRUCK_DAMAGE_BY_STAR[1]), "truck damage = by star (2★ + 1★)")


func test_truck_is_never_a_target(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_archer", "pos": Vector2(-4, 3)}, {"def": "node_berserker", "team": 1, "pos": Vector2(4, -3)}], 3, {"truck": true})
	b.run_to_end()
	for u: BUnit in b.units:
		t.ok(u.def.id != "truck", "only real units exist in the battle")
	t.ok(b.state == "ended", "battle still resolves normally around the truck")


func test_killed_enemies_with_orbs_drop_them(t: TestCtx) -> void:
	var b := Battle.new(Fixture.catalog(), 5)
	b.setup({"units": [{"def": "node_darkknight", "team": 0, "cell": Vector2i(9, 7), "star": 3},
		{"def": "mob_sentinel", "team": 1, "pos": Vector2(0, -4.5), "orb": "white"},
		{"def": "mob_archer", "team": 1, "pos": Vector2(1.5, -4.5), "orb": "blue"}], "map": {"truck": true}})
	b.run_to_end()
	t.eq(b.winner, GC.TEAM_PLAYER, "a 3★ knight beats two minions")
	t.eq(b.drops.size(), 2, "each killed minion dropped its orb")
	var tiers: Array = []
	for d: Dictionary in b.drops:
		tiers.append(d["tier"])
	t.ok(tiers.has("white") and tiers.has("blue"), "orb tiers come from the encounter data")


func test_map_generation_is_deterministic_and_connected(t: TestCtx) -> void:
	var cfg := {"low": 5, "high": 4, "altar": true, "regions": ["n", "ne", "w"]}
	var a: Dictionary = MapGen.generate(cfg, 42)
	var c: Dictionary = MapGen.generate(cfg, 42)
	t.eq(JSON.stringify(a), JSON.stringify(c), "same seed, same map")
	var m := BattleMap.from_layout(a)
	var lows := 0
	var highs := 0
	var altar := false
	for o: Dictionary in m.obstacles:
		if int(o["kind"]) == BattleMap.LOW:
			lows += 1
		else:
			highs += 1
		if str(o["style"]) == "altar":
			altar = true
		t.ok(not (o["rect"] as Rect2i).intersects(GC.DEPLOY_RECT), "obstacles stay out of the deploy zone")
	t.ok(lows >= 3 and highs >= 3, "both kinds were placed (%d low, %d high)" % [lows, highs])
	t.ok(altar, "the end-point altar sits on the enemy side")
	t.eq(m.reachable_count(GC.DEPLOY_RECT.position), m.free_count(), "every free cell is reachable")
	var styles: Dictionary = {}
	for s in range(8):
		for o2: Dictionary in BattleMap.from_layout(MapGen.generate(cfg, s)).obstacles:
			styles[o2["style"]] = true
	t.ok(styles.size() >= 7, "several sizes/styles show up across maps (%d)" % styles.size())
