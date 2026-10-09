extends RefCounted
## 地形效果(第一章·红之章)：燃烧废墟 / 余烬地块 / 死灰废墟，以及红之章的战斗地图生成。


func _dummy_battle(layout: Dictionary, pos: Vector2) -> Battle:
	var b: Battle = Fixture.make([{"def": "test_dummy", "team": 0, "pos": pos}, {"def": "test_dummy", "team": 1, "pos": Vector2(8, -6)}], 3, layout)
	b.start()
	b.advance_pending(0.0)
	return b


func _run_for(b: Battle, seconds: float) -> void:
	var n: int = int(seconds / GC.SIM_DT)
	for i in range(n):
		b.step()


func test_burning_ruin_sets_neighbours_burning(t: TestCtx) -> void:
	# 一块 2×1 的燃烧废墟，木桩站在它旁边的格子里：每秒被点上一个 2 秒的燃烧(每秒 25 点法术伤害，木桩 0 魔抗)
	var layout := {"truck": false, "obstacles": [{"x": 4, "y": 4, "w": 2, "h": 1, "kind": "low", "style": "burn_car", "terrain": "burning"}]}
	var next_to: Vector2 = GC.cell_to_world(4, 5)
	var b: Battle = _dummy_battle(layout, next_to)
	var u: BUnit = b.units[0]
	_run_for(b, GC.START_DELAY + 1.0)
	t.ok(u.status_count("burning") >= 1, "standing next to a burning ruin: Burning")
	var st: BStatus = u.status_instances("burning")[0]
	t.ok(st.source_id == "", "terrain burning has no source unit")
	t.ok(st.has_flag("dispellable"), "burning is dispellable")
	_run_for(b, 2.0)
	t.ok(u.status_count("burning") <= 2, "a fresh 2 s burning every second: at most 2 at a time (%d)" % u.status_count("burning"))
	var hp0: float = u.hp
	_run_for(b, 4.0)
	t.near(hp0 - u.hp, 4.0 * 2.0 * 25.0, 30.0, "while standing there: ~2 burnings × 25 per second (lost %.0f in 4 s)" % (hp0 - u.hp))
	# 两格以外：不受影响
	var b2: Battle = _dummy_battle(layout, GC.cell_to_world(4, 7))
	_run_for(b2, GC.START_DELAY + 1.5)
	t.eq(b2.units[0].status_count("burning"), 0, "two cells away: not burning")


func test_burning_wears_off_after_leaving(t: TestCtx) -> void:
	var layout := {"truck": false, "obstacles": [{"x": 4, "y": 4, "w": 1, "h": 1, "kind": "low", "style": "burn_debris", "terrain": "burning"}]}
	var b: Battle = _dummy_battle(layout, GC.cell_to_world(4, 5))
	var u: BUnit = b.units[0]
	_run_for(b, GC.START_DELAY + 1.0)
	t.ok(u.status_count("burning") >= 1, "burning")
	u.pos = GC.cell_to_world(10, 10)
	_run_for(b, 2.3)
	t.eq(u.status_count("burning"), 0, "2 s after stepping away the fire is out")


func test_ember_burns_once_then_goes_out(t: TestCtx) -> void:
	var layout := {"truck": false, "obstacles": [], "embers": [{"x": 6, "y": 6, "w": 2, "h": 2, "style": "ember_l"}]}
	var b: Battle = _dummy_battle(layout, GC.cell_to_world(2, 2))
	var u: BUnit = b.units[0]
	_run_for(b, GC.START_DELAY + 0.2)
	t.eq(u.status_count("burning"), 0, "not on the embers yet")
	t.ok(bool(b.map.embers[0]["lit"]), "ember is lit")
	u.pos = GC.cell_to_world(6, 6) + Vector2(0.5, 0.5)
	_run_for(b, 0.1)
	t.eq(u.status_count("burning"), 1, "stepping on embers: Burning")
	t.near(u.status_instances("burning")[0].expires_at - b.time, 5.0 - 0.075, 0.08, "a 5 s burning")
	t.ok(not bool(b.map.embers[0]["lit"]), "…and the ember patch goes out")
	var outs := 0
	for e: Dictionary in b.poll_events():
		if str(e["t"]) == "ember_out":
			outs += 1
	t.eq(outs, 1, "one ember_out event for the view")
	# 再踩一次不会重复点燃(熄灭了)；5 秒后燃烧结束
	u.pos = GC.cell_to_world(7, 7)
	_run_for(b, 5.3)
	t.eq(u.status_count("burning"), 0, "a spent ember patch does nothing")


func test_ash_ruins_only_block(t: TestCtx) -> void:
	var layout := {"truck": false, "obstacles": [{"x": 4, "y": 4, "w": 2, "h": 2, "kind": "high", "style": "ash_corner"}]}
	var b: Battle = _dummy_battle(layout, GC.cell_to_world(4, 6))
	_run_for(b, GC.START_DELAY + 1.5)
	t.eq(b.units[0].status_stacks("burning"), 0, "dead-ash ruins have no effect")
	t.ok(b.map.blocks_move(Vector2i(4, 4)) and b.map.blocks_los(Vector2i(5, 5), 0), "but they block movement and sight like any high ruin")
	t.ok(not b.map.has_terrain(), "a map without burning ruins or embers attaches no terrain triggers")
	t.eq(b.units[0].runtime_triggers.size(), 0, "no terrain triggers on units")


func test_red_maps_are_deterministic_connected_and_keep_the_deploy_zone_clear(t: TestCtx) -> void:
	var cfg := {"theme": "red", "low": 3, "high": 3, "burning": 3, "embers": 5, "regions": ["n", "e", "sw"]}
	var a: Dictionary = MapGen.generate(cfg, 77)
	var b2: Dictionary = MapGen.generate(cfg, 77)
	t.eq(JSON.stringify(a), JSON.stringify(b2), "same seed → same red map")
	var m: BattleMap = BattleMap.from_layout(a)
	t.eq(m.reachable_count(GC.DEPLOY_RECT.position), m.free_count(), "every free cell reachable")
	var burning := 0
	for o: Dictionary in m.obstacles:
		if str(o["terrain"]) == "burning":
			burning += 1
		t.ok(not (o["rect"] as Rect2i).intersects(GC.DEPLOY_RECT), "no ruin in the deploy zone")
	t.ok(burning >= 1, "burning ruins placed (%d)" % burning)
	t.ok(m.embers.size() >= 2, "ember patches placed (%d)" % m.embers.size())
	for e: Dictionary in m.embers:
		t.ok(not (e["rect"] as Rect2i).intersects(GC.DEPLOY_RECT), "no embers in the deploy zone")
		var er: Rect2i = e["rect"]
		for y in range(er.position.y, er.end.y):
			for x in range(er.position.x, er.end.x):
				t.ok(not m.blocks_move(Vector2i(x, y)), "embers lie on open ground")
	# 款式都有对应的模型
	for o2: Dictionary in m.obstacles:
		t.ok(ResourceLoader.exists("res://assets/world/%s.res" % str(o2["style"])), "model for %s" % str(o2["style"]))
	# 第零章的地图不受影响(白色主题没有地形效果)
	var w: BattleMap = BattleMap.from_layout(MapGen.generate({"low": 3, "high": 2, "regions": ["n"]}, 5))
	t.ok(not w.has_terrain(), "white-chapter maps have no terrain effects")
