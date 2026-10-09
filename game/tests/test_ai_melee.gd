extends RefCounted
## 近战 AI：前面有队友挡着时绕到目标身边的空位(近战 a → 近战 b → 敌人排成一条线，a 不再一直把 b 往旁边挤)；
## 色欲的余烬的触手：缠住的两边被挤开、有一方打不到对方时，把两边往一起拉。


func _run(b: Battle, sec: float) -> void:
	while b.time < sec and b.state != "ended":
		b.step()


func _immortal(u: BUnit) -> void:
	u.base.max_health = 1.0e8
	u.mark_dirty()
	u.get_stats()
	u.hp = 1.0e8


func test_melee_goes_around_an_ally_in_line(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_samurai", "pos": Vector2(0, -1.0)}, {"def": "node_samurai", "pos": Vector2(0, 1.6)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 2.8)}])
	var back: BUnit = b.units[0]
	var front: BUnit = b.units[1]
	b.start()
	_immortal(b.units[2])
	_run(b, GC.START_DELAY + 0.5)
	var front0: Vector2 = front.pos
	var hit_at := -1.0
	while b.time < GC.START_DELAY + 4.0 and hit_at < 0.0:
		b.step()
		for e: Dictionary in Fixture.events_of(b, "damage"):
			if e["src"] == back:
				hit_at = b.time
	t.ok(hit_at > 0.0 and hit_at < GC.START_DELAY + 3.0, "the one behind walks around and hits (%.1f s)" % (hit_at - GC.START_DELAY))
	t.ok(front.pos.distance_to(front0) < 0.6, "the one in front isn't shoved aside (%.2f m)" % front.pos.distance_to(front0))


func test_lust_tentacle_pulls_the_pair_back_together(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_samurai", "pos": Vector2(0, 0)}, {"def": "mob_ember_lust", "team": 1, "pos": Vector2(0, 1.0)}])
	var s: BUnit = b.units[0]
	var lust: BUnit = b.units[1]
	b.start()
	_immortal(s)
	_immortal(lust)
	var ab: AbilityDef = null
	for pa: AbilityDef in lust.def.passives:
		if pa.effect_type == "entangle":
			ab = pa
	b.pipeline._entangle(lust, s, ab)
	t.ok(s.has_flag("rooted") and lust.has_flag("rooted"), "entangled: both rooted")
	# 被挤开到 3 米外：两边都打不到对方
	s.pos = Vector2(-1.5, 0)
	lust.pos = Vector2(1.5, 0)
	_run(b, GC.START_DELAY + 3.0)
	var d: float = s.pos.distance_to(lust.pos)
	t.ok(BattleAI.in_reach(s, lust, d, s.get_stats().range_meters()) and BattleAI.in_reach(lust, s, d, lust.get_stats().range_meters()),
		"pulled back until both can hit each other (%.2f m)" % d)
	t.ok(d >= BattleAI.touch_reach(s, lust) - 0.2, "…but not into each other")
