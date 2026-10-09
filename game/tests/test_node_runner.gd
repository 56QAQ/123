extends RefCounted
## 迅游节点：闪电跑者(穿过地形和其他人；每 1 秒移动速度 +攻击力 × x%，累加)、飞身踢(一直跑、以最远的敌人为目标，碰到就踢：
## 攻击力 × (100 + 法强)% × (路程 / d0)^pow 的物理普攻伤害，踢完折返；只剩一个敌人 / 太近 → 先去卡车借力)、
## 别粘我鞋底上(触发器：飞身踢命中，数值同这一脚) + 专武闪电手套(移速 +20%；触发数值 × 80% 魔法伤害 + 击退 触发数值 × 0.004 米)。


func _run(b: Battle, sec: float) -> void:
	while b.time < sec and b.state != "ended":
		b.step()


func _foe(u: BUnit, hp: float = 1.0e7) -> void:
	u.base.max_health = hp
	u.base.defense = 0.0
	u.base.magic_resistance = 0.0
	u.mark_dirty()
	u.get_stats()
	u.hp = hp


func _no_crit(u: BUnit) -> void:
	u.base.crit_chance = 0.0
	u.mark_dirty()


func _x(star: int) -> float:
	for tr: TriggerDef in Fixture.catalog().get_unit("node_runner").triggers:
		if tr.id == "node_runner_speed":
			return tr.ratio_for(star)
	return 0.0


## 走一步，返回这一步新产生的事件(b.events 不清的话会一直累积)
func _step(b: Battle) -> Array[Dictionary]:
	b.step()
	return b.poll_events()


static func _of(evs: Array[Dictionary], type: String) -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for e: Dictionary in evs:
		if e.get("t") == type:
			r.append(e)
	return r


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = cat.get_unit("node_runner")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class], [4, "purple", "information", "assassin", "dual"],
		"rarity 4, purple, Information, assassin, dual melee")
	t.eq(d.weapon_classes, ["dual", "sword"] as Array[String], "can also use one-handed melee")
	t.ok(d.special_traits.has("clan"), "special trait: Clan")
	t.ok(d.normal_attack != null and d.normal_attack.has_keyword("crit") and not d.normal_attack.has_keyword("pursuit"), "the normal attack is one kick that can crit")
	var e: EquipmentDef = cat.get_equipment("lightning_gloves")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["dual", "purple", 4, "node_runner"], "Lightning Gloves: dual, purple, rarity 4, his")
	t.near(float(e.pct_mods.get("move_speed", 0.0)), 0.2, 0.001, "+20% move speed")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_phasing_ignores_units_and_terrain(t: TestCtx) -> void:
	# 高障碍占 (9, 7) 这一格 = 世界坐标 x ∈ [-0.5, 0.5]、y ∈ [0, 1]
	var b := Fixture.make([{"def": "node_runner", "pos": Vector2(0.0, 0.5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(4.0, 3.0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(-6.0, -4.0)}],
		7, {"truck": false, "obstacles": [{"x": 9, "y": 7, "w": 1, "h": 1, "kind": "high"}]})
	var r: BUnit = b.units[0]
	b.start()
	b.step()
	t.ok(r.has_flag("phasing"), "Lightning Runner: phasing from the start")
	r.pos = Vector2(0.0, 0.5)
	b.resolve_collisions()
	t.near(r.pos.distance_to(Vector2(0.0, 0.5)), 0.0, 0.001, "not pushed out of the obstacle")
	r.pos = Vector2(4.05, 3.0)
	b.resolve_collisions()
	t.near(r.pos.distance_to(Vector2(4.05, 3.0)), 0.0, 0.001, "…nor out of another unit")
	t.near(b.units[1].pos.distance_to(Vector2(4.0, 3.0)), 0.0, 0.001, "…and that unit isn't pushed either")


func test_speed_ramp(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_runner", "pos": Vector2(0, -3), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 5)}])
	var r: BUnit = b.units[0]
	b.start()
	_run(b, GC.START_DELAY + 1.0)
	var st0: BStatus = r.get_status("lightning_runner")
	var p0: float = float(st0.pct_per_stack.get("move_speed", 0.0)) if st0 != null else 0.0
	_run(b, GC.START_DELAY + 3.0)
	var st1: BStatus = r.get_status("lightning_runner")
	t.ok(st1 != null and not st1.has_flag("dispellable"), "one status that keeps growing")
	var p1: float = float(st1.pct_per_stack.get("move_speed", 0.0)) if st1 != null else 0.0
	t.near(p1 - p0, 2.0 * r.get_stats().attack_power * _x(2), 0.0001, "+attack × x% move speed every second")


func test_flying_kick_scales_with_distance(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_runner", "pos": Vector2(-6, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(5, 0)}])
	var r: BUnit = b.units[0]
	b.start()
	_no_crit(r)
	_foe(b.units[1])
	var kicks: Array[Dictionary] = []
	var dmg: Array[Dictionary] = []
	while b.time < GC.START_DELAY + 6.0 and kicks.is_empty():
		var evs: Array[Dictionary] = _step(b)
		kicks.append_array(_of(evs, "runner_kick"))
		for e: Dictionary in _of(evs, "damage"):
			if e["src"] == r and str(e.get("surface", "")) == "normal_attack":
				dmg.append(e)
	t.eq(kicks.size(), 1, "runs over and kicks")
	if kicks.is_empty() or dmg.is_empty():
		return
	var run: float = float(kicks[0]["dist"])
	t.near(run, 11.0 - r.radius - b.units[1].radius, 0.6, "distance = how far he ran (%.2f m)" % run)
	var st: StatBlock = r.get_stats()
	var d0: float = float(Pipeline.status_meta(r, "kick_d0"))
	var pw: float = float(Pipeline.status_meta(r, "kick_pow"))
	var want: float = st.attack_power * (1.0 + st.ability_power / 100.0) * pow(run / d0, pw)
	t.near(float(dmg[0]["amount"]), want, want * 0.01, "attack × (100 + AP)% × (distance / %.0f m)^%.1f" % [d0, pw])
	t.eq(str(dmg[0]["kind"]), "physical", "physical normal-attack damage")
	# 越远越赚：同样的距离差，远处加得更多
	t.ok(Pipeline.kick_mult(r, 12.0) - Pipeline.kick_mult(r, 9.0) > Pipeline.kick_mult(r, 6.0) - Pipeline.kick_mult(r, 3.0), "nonlinear: farther runs gain more per meter")


func test_farthest_target_and_doubling_back(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_runner", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(-3, 0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(7, 0)}])
	var r: BUnit = b.units[0]
	b.start()
	_foe(b.units[1])
	_foe(b.units[2])
	var kicks: Array[Dictionary] = []
	while b.time < GC.START_DELAY + 8.0 and kicks.size() < 2:
		kicks.append_array(_of(_step(b), "runner_kick"))
	t.ok(kicks.size() >= 2, "kicks twice")
	if kicks.size() >= 2:
		t.ok(kicks[0]["target"] == b.units[2], "first the farthest enemy")
		t.ok(kicks[1]["target"] == b.units[1], "then doubles back to the (now) farthest one")
		t.ok(float(kicks[1]["dist"]) > 8.0, "…a long run (%.1f m)" % float(kicks[1]["dist"]))


func test_single_enemy_springs_off_the_truck(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_runner", "pos": Vector2(-0.5, -3.5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.0, -5.5)}], 7, {"truck": true})
	var r: BUnit = b.units[0]
	b.start()
	_foe(b.units[1])
	var kicks: Array[Dictionary] = []
	var springs: Array[Dictionary] = []
	while b.time < GC.START_DELAY + 8.0 and kicks.size() < 2:
		var evs: Array[Dictionary] = _step(b)
		kicks.append_array(_of(evs, "runner_kick"))
		springs.append_array(_of(evs, "runner_spring"))
	t.ok(kicks.size() >= 2, "keeps kicking the only enemy")
	t.ok(not springs.is_empty() and bool(springs[0]["truck"]), "springs off the truck in between")
	if kicks.size() >= 2:
		t.ok(float(kicks[1]["dist"]) >= float(Pipeline.status_meta(r, "min_run")) - 0.3, "…so the second kick has a real run-up (%.1f m)" % float(kicks[1]["dist"]))


func test_passes_through_a_wall_of_units(t: TestCtx) -> void:
	var specs: Array = [{"def": "node_runner", "pos": Vector2(0, -4)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 5)}]
	for i in range(5):
		specs.append({"def": "test_dummy", "team": 0, "pos": Vector2(float(i) * 0.9 - 1.8, 0.0)})
	var b := Fixture.make(specs)
	var r: BUnit = b.units[0]
	b.start()
	_foe(b.units[1])
	var max_dx := 0.0
	var kicks: Array[Dictionary] = []
	while b.time < GC.START_DELAY + 5.0 and kicks.is_empty():
		var evs: Array[Dictionary] = _step(b)
		max_dx = maxf(max_dx, absf(r.pos.x))
		kicks.append_array(_of(evs, "runner_kick"))
	t.ok(not kicks.is_empty(), "reaches the target behind a line of allies")
	t.ok(max_dx < 0.2, "straight through them, no detour (max sideways %.2f m)" % max_dx)


func test_gloves_knock_back(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_runner", "pos": Vector2(-6, 0), "weapon": "lightning_gloves"}, {"def": "test_dummy", "team": 1, "pos": Vector2(4, 0)}])
	var r: BUnit = b.units[0]
	b.start()
	_no_crit(r)
	_foe(b.units[1])
	var kicks: Array[Dictionary] = []
	var kb: Array[Dictionary] = []
	var jolt: Array[Dictionary] = []
	while b.time < GC.START_DELAY + 6.0 and kicks.is_empty():
		var evs: Array[Dictionary] = _step(b)
		kicks.append_array(_of(evs, "runner_kick"))
		kb.append_array(_of(evs, "knockback"))
		for e: Dictionary in _of(evs, "damage"):
			if str(e.get("ability", "")) == "lightning_gloves_jolt":
				jolt.append(e)
	t.eq(jolt.size(), 1, "the gloves fire on the kick")
	t.eq(kb.size(), 1, "…and knock the target back")
	if kicks.is_empty() or jolt.is_empty() or kb.is_empty():
		return
	var st: StatBlock = r.get_stats()
	var v: float = st.attack_power * float(kicks[0]["mult"])
	t.near(float(jolt[0]["amount"]), v * 0.8, v * 0.01, "trigger value × 80% magic damage")
	t.eq(str(jolt[0]["kind"]), "magic", "magic")
	var moved: float = (kb[0]["from"] as Vector2).distance_to(kb[0]["to"])
	t.near(moved, minf(3.0, v * 0.004), 0.12, "knocked back trigger value × 0.004 m (%.2f m)" % moved)
	t.ok(((kb[0]["to"] as Vector2) - (kb[0]["from"] as Vector2)).x > 0.0, "away from him")
	_run(b, b.time + 0.4)
	t.near(b.units[1].pos.distance_to(kb[0]["to"]), 0.0, 0.05, "the slide finishes where it should")
