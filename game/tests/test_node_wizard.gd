extends RefCounted
## 巫术节点：虹光飞弹(一直吟唱 5 秒 → 1 + ⌊增幅 × 实际吟唱秒数⌋ 发飞弹，颜色 红 / 蓝 / 绿 / 白，全场随机目标，飞一会儿才命中；
## 被打断也按已吟唱秒数施放)、黑羽使魔(集齐 6 种标记召一只鸟，最多 5 只)、使魔之喙(鸟普攻命中触发装备)、
## 鸟(攻击力 + 召唤者法强 × r；天空视野：每只鸟给所有队友 1 层，最多 3 层，普攻 / 技能伤害 +z)、专武虹光花(被动增幅 +1；随机三种伤害 × 3 下)。


func _run(b: Battle, sec: float) -> void:
	while b.time < sec and b.state != "ended":
		b.step()


func _immortal(b: Battle) -> void:
	for u: BUnit in b.units:
		if u.team == 1:
			u.base.max_health = 1.0e8
			u.mark_dirty()
			u.hp = 1.0e8


func _missiles(b: Battle) -> Array[Dictionary]:
	return Fixture.events_of(b, "missile")


func test_unit_data(t: TestCtx) -> void:
	var d: UnitDef = Fixture.catalog().get_unit("node_wizard")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role], [4, "blue", "research", "caster"], "rarity 4, blue, Research, caster")
	t.eq(d.weapon_classes, ["focus", "polearm"] as Array[String], "focus default; two-handed polearm allowed")
	var bd: UnitDef = Fixture.catalog().get_unit("node_bird")
	t.eq([bd.cost, bd.faction_id, bd.profession_id, bd.role, bd.base_weapon_class], [1, "black", "information", "assassin", "dual"], "bird: rarity 1, black, Information, assassin, dual melee")
	t.ok(not bd.available_in_shop and bd.summon_only, "the bird is summon-only")
	var e: EquipmentDef = Fixture.catalog().get_equipment("rainbow_flower")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["focus", "blue", 4, "node_wizard"], "Prism Bloom: focus, blue, rarity 4, his")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_always_chanting_and_missile_count(t: TestCtx) -> void:
	# 1★ 增幅 2，吟唱满 5 秒：1 + 2×5 = 11 发；施放完立刻开始下一轮
	var b := Fixture.make([{"def": "node_wizard", "pos": Vector2(0, -3), "star": 1}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}])
	var w: BUnit = b.units[0]
	b.start()
	_immortal(b)
	_run(b, GC.START_DELAY + 4.9)
	t.eq(w.phase, "chant", "chanting from the start of the fight")
	t.eq(_missiles(b).size(), 0, "nothing fired before the chant completes")
	_run(b, GC.START_DELAY + 5.1)
	t.eq(_missiles(b).size(), 11, "a full 5 s chant at Amplify 2: 1 + 2 × 5 = 11 missiles")
	t.eq(w.phase, "chant", "and the next chant starts right away (chant = cooldown)")
	t.eq(Fixture.events_of(b, "attack_start").filter(func(x: Dictionary) -> bool: return x["unit"] == w).size(), 0, "no time to normal-attack")
	# 带虹光花：被动增幅 +1 → 1 + 3×5 = 16 发
	var b2 := Fixture.make([{"def": "node_wizard", "pos": Vector2(0, -3), "star": 1, "weapon": "rainbow_flower"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}])
	b2.start()
	_immortal(b2)
	_run(b2, GC.START_DELAY + 5.1)
	t.eq(_missiles(b2).size(), 16, "Prism Bloom: Amplify +1 → 16 missiles")


func test_interrupted_chant_fires_partially(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_wizard", "pos": Vector2(0, -3), "star": 1}, {"def": "test_hitter", "team": 1, "pos": Vector2(0, 3)}])
	var w: BUnit = b.units[0]
	b.start()
	_immortal(b)
	_run(b, GC.START_DELAY + 2.3)
	b.pipeline.fx.apply_status(b.units[1], w, {"status_id": "test_stun", "duration": 0.5, "flags": ["stun"]}, {})
	t.eq(_missiles(b).size(), 5, "interrupted after 2.3 s: 1 + ⌊2 × 2.3⌋ = 5 missiles")
	_run(b, b.time + 1.8)
	t.eq(w.phase, "chant", "chanting again shortly after the stun ends")


## 会飞的单位走直线：中间隔着一堵墙也不绕(普通单位要绕)
func test_flying_units_fly_over_walls(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_bird", "pos": Vector2(0, -3)}, {"def": "test_hitter", "pos": Vector2(0.2, -3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}], 3)
	var bird: BUnit = b.units[0]
	var walker: BUnit = b.units[1]
	var c0: Vector2i = GC.world_to_cell(Vector2.ZERO)
	b.map.add_obstacle(Rect2i(c0.x - 3, c0.y, 7, 1), BattleMap.HIGH, "rubble")
	b.pipeline.fx.apply_status(bird, bird, {"status_id": "bird_flight", "duration": 0.0, "flags": ["hidden", "no_dispel", "phasing", "flying"]})
	t.ok(bird.has_flag("flying"), "flying flag")
	var ai := BattleAI.new(b)
	var v: Vector2 = ai._steer(bird, Vector2(0, 3), 2.0)
	t.near(v.normalized().dot(Vector2(0, 1)), 1.0, 0.001, "a flying unit heads straight for its goal, over the wall")
	var vw: Vector2 = ai._steer(walker, Vector2(0.2, 3), 2.0)
	t.ok(vw.normalized().dot(Vector2(0, 1)) < 0.98, "…while a walking unit goes around it")


func test_missile_colors(t: TestCtx) -> void:
	# 打很多轮：四种颜色都出现；绿色打队友(治疗)，红色是物理 + 燃烧(8 秒)，白色是真实伤害，蓝色 = 白色伤害 × 1.2(换成法术)
	var b := Fixture.make([{"def": "node_wizard", "pos": Vector2(0, -3), "star": 1}, {"def": "test_hitter", "pos": Vector2(2, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}], 5)
	var w: BUnit = b.units[0]
	b.start()
	_immortal(b)
	_run(b, GC.START_DELAY + 16.5)
	var cols := {}
	var green_ok := true
	for e: Dictionary in _missiles(b):
		cols[str(e["color"])] = true
		if str(e["color"]) == "green":
			green_ok = green_ok and (e["target"] as BUnit).team == w.team
	t.eq(cols.size(), 4, "all four colors show up (%s)" % str(cols.keys()))
	t.ok(green_ok, "green missiles aim at teammates")
	var kinds := {}
	var amt := {}
	var first_bird := 1.0e9
	for sm: Dictionary in Fixture.events_of(b, "summon"):
		first_bird = minf(first_bird, float(sm["time"]))
	for d: Dictionary in Fixture.events_of(b, "damage"):
		if d["src"] == w and str(d.get("ability", "")) == "node_wizard_missiles":
			kinds[str(d["kind"])] = true
			if float(d["time"]) < first_bird and not amt.has(str(d["kind"])):
				amt[str(d["kind"])] = float(d["amount"])        # (鸟出来之前：还没有天空视野的固定加成)
	t.eq(kinds.keys().size(), 3, "physical (red), magic (blue) and true (white) damage")
	t.near(amt.get("magic", 0.0), amt.get("true", 0.0) * 1.2, 0.5, "blue = 1.2 × (the dummy has no resistances)")
	var burned := false
	for st: BStatus in b.units[2].status_instances("burning"):
		burned = burned or absf(st.expires_at - b.time) <= 8.01
	t.ok(burned, "red missiles leave an 8 s Burning")
	var heals := 0
	for h: Dictionary in Fixture.events_of(b, "heal"):
		if h["src"] == w and str(h.get("ability", "")) == "node_wizard_missiles":
			heals += 1
	t.ok(heals > 0, "green missiles heal (%d)" % heals)


func test_familiars_and_sky_sight(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_wizard", "pos": Vector2(0, -3), "star": 2, "weapon": "rainbow_flower"}, {"def": "test_hitter", "pos": Vector2(3, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}], 7)
	var w: BUnit = b.units[0]
	var mate: BUnit = b.units[1]
	b.start()
	_immortal(b)
	_run(b, GC.START_DELAY + 7.5)
	var birds: Array[BUnit] = []
	for u: BUnit in b.units:
		if u.alive and u.is_summon and u.def.id == "node_bird":
			birds.append(u)
	t.ok(birds.size() >= 1, "six kinds of marks → a bird (%d)" % birds.size())
	if not birds.is_empty():
		var bird: BUnit = birds[0]
		t.near(bird.get_stats().attack_power, bird.base.attack_power + w.get_stats().ability_power * 0.1, 0.6, "bird attack + 10% of his ability power")
		# 隐藏属性：会飞——和迅游节点一样无视碰撞体积(phasing)，飞过障碍物(flying)
		t.ok(bird.has_flag("phasing") and bird.has_flag("flying"), "the bird flies: ignores collision like Node Runner, and flies over obstacles")
		t.ok(not bird.get_status("bird_flight").has_flag("dispellable"), "…a hidden, undispellable trait")
	_run(b, GC.START_DELAY + 60.0)
	var n2 := 0
	for u2: BUnit in b.units:
		if u2.alive and u2.is_summon and u2.def.id == "node_bird":
			n2 += 1
	t.eq(n2, 5, "at most 5 birds")
	var sky := 0
	for sk: String in mate.statuses.keys():
		if sk.begins_with("sky_vision"):
			sky += 1
	t.eq(sky, 3, "Sky Sight: one stack per bird, at most 3")
	var bird_eye: AbilityDef = Fixture.catalog().get_unit("node_bird").passive_by_id("node_bird_eye")
	var z2: float = float(bird_eye.effect_config["stats_by_star"]["na_skill_flat_damage"]["flat"]["2"])
	t.near(mate.get_stats().na_skill_flat_damage, 3.0 * z2, 0.01, "2★: +z per stack on normal-attack / skill damage")
	var st: BStatus = mate.get_status(mate.statuses.keys().filter(func(k: String) -> bool: return k.begins_with("sky_vision"))[0])
	t.ok(not st.has_flag("dispellable"), "can't be dispelled")
	# 使魔之喙：鸟普攻命中 → 虹光花(追击 2 = 一次 3 下)
	var sparks: int = Fixture.events_of(b, "rainbow_spark").size()
	t.ok(sparks > 0 and sparks % 3 == 0, "Familiar's Beak → Prism Bloom, 3 hits each time (%d)" % sparks)
