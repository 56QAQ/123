extends RefCounted
## 血嗜节点：血欲(每秒 2/2/3 层，【叠加 12】)→ 造成 / 承受非持续伤害时给对方叠失血(每层每 0.25 秒物理持续伤害，回复最终伤害量)、
## 血宴(全场每 150 点持续伤害一层：持续伤害增幅 + 固定减伤)、至亲的故事(血欲 12 层时消耗触发；武器冷却 / 吟唱中不触发)、
## 专武凝血(【吟唱 3】吟唱几秒打几下 + 崩裂：受到的每一跳持续伤害 +2)。


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


func _x(star: int) -> float:
	for pa: AbilityDef in Fixture.catalog().get_unit("node_vampire").passives:
		if pa.id == "node_vampire_bleed":
			return float((pa.effect_config["x_by_star"] as Dictionary)[str(star)])
	return 0.0


func _calm(v: BUnit) -> void:
	v.attack_cd = 1.0e9
	v.base.move_speed = 0.0
	v.mark_dirty()


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = cat.get_unit("node_vampire")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model], [4, "cyan", "security", "warrior", "heavy", "vampire"],
		"rarity 4, cyan, Security, warrior, two-handed heavy, vampire model")
	t.eq(d.weapon_classes, ["heavy", "sword", "polearm"] as Array[String], "can equip one-handed melee and polearms")
	t.ok(d.special_traits.has("clan"), "special trait: Clan")
	var e: EquipmentDef = cat.get_equipment("clotted_blood")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["heavy", "cyan", 4, "node_vampire"], "Clotted Blood: heavy, cyan, rarity 4, his")
	t.ok(float(e.flat_mods.get("dot_damage_pct", 0.0)) > 0.0 and float(e.flat_mods.get("physical_flat_penetration", 0.0)) > 0.0, "DoT amp + armor penetration")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_bloodlust_builds_up(t: TestCtx) -> void:
	for star: int in [1, 3]:
		var b := Fixture.make([{"def": "node_vampire", "pos": Vector2(0, -4), "star": star}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
		var v: BUnit = b.units[0]
		b.start()
		_calm(v)
		_run(b, GC.START_DELAY + 2.1)
		t.eq(v.status_stacks("bloodlust"), 4 if star == 1 else 6, "%d★: %d Bloodlust per second" % [star, 2 if star == 1 else 3])
		_run(b, GC.START_DELAY + 10.0)
		t.eq(v.status_stacks("bloodlust"), 12, "capped at 12 (basic weapon: nothing to spend it on)")
		t.ok(not v.get_status("bloodlust").has_flag("dispellable"), "can't be dispelled")


func test_dealing_damage_bleeds_the_target_and_heals_him(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_vampire", "pos": Vector2(0, 0), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.4)}])
	var v: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	b.start()
	_calm(v)
	_run(b, GC.START_DELAY + 2.1)
	var bl: int = v.status_stacks("bloodlust")
	b.pipeline.fx.damage(v, foe, 10.0, "physical", {"surface": "other"})
	b.pipeline.drain()
	t.eq(foe.status_stacks("bleed"), bl, "a non-DoT hit: 1 Bleeding per Bloodlust (%d)" % bl)
	var st: BStatus = foe.get_status("bleed")
	t.ok(st.has_flag("dispellable") and st.has_flag("debuff"), "dispellable debuff")
	t.near(st.expires_at - b.time, 10.0, 0.05, "10 s")
	v.hp = v.get_stats().max_health * 0.5
	var hp0: float = v.hp
	var foe0: float = foe.hp
	_run(b, b.time + 1.0)
	var dealt: float = foe0 - foe.hp
	t.near(dealt, float(bl) * _x(2) * 4.0, 1.0, "each stack: %.1f physical every 0.25 s (0 armor)" % _x(2))
	t.near(v.hp - hp0, dealt, 1.0, "and he heals for exactly what it dealt")
	t.eq(foe.status_stacks("bleed"), bl, "the DoT itself doesn't add more Bleeding")


func test_taking_damage_bleeds_the_attacker(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_vampire", "pos": Vector2(0, 0), "star": 2}, {"def": "test_hitter", "team": 1, "pos": Vector2(0, 1.4)}])
	var v: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	b.start()
	_calm(v)
	foe.attack_cd = 1.0e9
	_run(b, GC.START_DELAY + 3.1)
	b.pipeline.fx.damage(foe, v, 10.0, "physical", {"surface": "other"})
	b.pipeline.drain()
	t.eq(foe.status_stacks("bleed"), v.status_stacks("bloodlust"), "being hit (non-DoT): the attacker bleeds too")


func test_blood_feast_counts_every_dot(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_vampire", "pos": Vector2(0, -4), "star": 1}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)},
		{"def": "test_dummy", "pos": Vector2(3, -4)}])
	var v: BUnit = b.units[0]
	b.start()
	_calm(v)
	_run(b, GC.START_DELAY + 0.3)
	var burn: Dictionary = (Fixture.catalog().get_unit("mob_ember_wrath").passives[0] as AbilityDef).effect_config.duplicate(true)
	burn["duration"] = 7.0
	b.pipeline.fx.apply_status(null, b.units[2], burn)          # 别人(他的队友)身上的燃烧也算
	_run(b, b.time + 7.2)
	t.eq(v.status_stacks("blood_feast"), 1, "7 × 25 = 175 DoT on the field → 1 Blood Feast (per 150)")
	t.near(v.get_stats().dot_damage_pct, 0.04, 0.001, "+4% DoT per stack")
	t.near(v.get_stats().damage_taken_flat, 3.0, 0.001, "3 flat damage reduction per stack")


func test_tale_of_kin_waits_for_the_weapon_and_ruptures(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_vampire", "pos": Vector2(0, -2), "star": 2, "weapon": "clotted_blood"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 2)}, {"def": "test_dummy", "team": 1, "pos": Vector2(3, 3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(-8, 6)}])
	var v: BUnit = b.units[0]
	b.start()
	_calm(v)
	v.target = b.units[1]
	b.pipeline.fx.apply_status(v, v, {"status_id": "blood_feast", "duration": 0.0, "flags": ["buff", "no_dispel"], "add_stacks": 5, "max_stacks": 12,
		"stats": {"dot_damage_pct": {"flat": 0.04}, "damage_taken_flat": {"flat": 3.0}}})
	var evs: Array[Dictionary] = []
	while b.time < GC.START_DELAY + 10.0 and _of(evs, "kin_tale").is_empty():
		evs.append_array(_step(b))
	var kt: Array[Dictionary] = _of(evs, "kin_tale")
	t.eq(kt.size(), 1, "Bloodlust hits 12: Tale of Kin")
	t.ok(bool(kt[0]["chant"]) and bool(kt[0]["multi"]), "Clotted Blood chants and has Multi-Attack (the view raises the big orb and throws it)")
	t.eq(v.status_stacks("bloodlust"), 0, "12 Bloodlust spent")
	t.eq(v.phase, "chant", "Clotted Blood: chanting 3 s")
	var value: float = 5.0 * v.get_stats().attack_power
	var hp1: float = b.units[1].hp
	var hp2: float = b.units[2].hp
	var hp3: float = b.units[3].hp
	# 吟唱完把血球扔出去：武器效果等血球砸到地上(0.4 秒后)才结算
	evs = _run(b, b.time + 3.2)
	var tc: Array[Dictionary] = _of(evs, "throw_cast")
	t.eq(tc.size(), 1, "the chant ends: the orb is thrown")
	t.near(float(tc[0]["land"]) if not tc.is_empty() else 0.0, 0.4, 0.001, "…and lands 0.4 s later")
	var early := 0
	for d0: Dictionary in _of(evs, "damage"):
		if d0["src"] == v and str(d0.get("ability", "")) == "clotted_blood_rupture":
			early += 1
	t.eq(early, 0, "nothing is hit while the orb is in the air")
	t.near(b.units[1].hp, hp1, 0.01, "…the target still at full health")
	var evs2: Array[Dictionary] = _run(b, b.time + 0.3)
	evs.append_array(evs2)
	var tl: Array[Dictionary] = _of(evs2, "throw_land")
	t.eq(tl.size(), 1, "the orb hits the ground")
	t.ok(not tl.is_empty() and (tl[0]["targets"] as Array).has(b.units[1]) and (tl[0]["targets"] as Array).has(b.units[2]) and not (tl[0]["targets"] as Array).has(b.units[3]),
		"throw_land lists the ones actually hit (the view raises a blood pillar under each)")
	var hits := 0
	for d: Dictionary in _of(evs, "damage"):
		if d["src"] == v and d["dst"] == b.units[1] and str(d.get("ability", "")) == "clotted_blood_rupture":
			hits += 1
	t.eq(hits, 3, "3 s chanted → 3 hits")
	t.ok(hp1 - b.units[1].hp >= 3.0 * value * 0.12 - 1.0, "each = 5 Blood Feast × attack × 12%% (%.0f)" % (hp1 - b.units[1].hp))
	t.ok(hp2 > b.units[2].hp, "the enemy 3 m from the center is hit too")
	t.near(b.units[3].hp, hp3, 0.01, "the one 9 m from the center isn't")
	t.eq(b.units[1].status_stacks("blood_crack"), 3, "3 Fracture")
	t.near(b.units[1].get_stats().dot_taken_flat, 6.0, 0.001, "+2 DoT taken per stack")
	# 冷却中：血欲攒满也不触发、不消耗
	evs = _run(b, b.time + 6.0)
	t.eq(_of(evs, "kin_tale").size(), 0, "weapon still on its 7 s cooldown (from the release): no trigger")
	t.eq(v.status_stacks("bloodlust"), 12, "…and Bloodlust waits at 12")
	evs = _run(b, b.time + 1.2)
	t.eq(_of(evs, "kin_tale").size(), 1, "cooldown over: it triggers right away")


func test_fracture_adds_to_each_dot_tick(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "test_dummy", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 5)}])
	var u: BUnit = b.units[1]
	b.start()
	_run(b, GC.START_DELAY + 0.1)
	b.pipeline.fx.apply_status(null, u, {"status_id": "blood_crack", "duration": 10.0, "flags": ["debuff", "dispellable"], "add_stacks": 4, "max_stacks": 6,
		"stats": {"dot_taken_flat": {"flat": 2.0}}})
	var burn: Dictionary = (Fixture.catalog().get_unit("mob_ember_wrath").passives[0] as AbilityDef).effect_config.duplicate(true)
	burn["duration"] = 2.0
	b.pipeline.fx.apply_status(null, u, burn)
	var hp0: float = u.hp
	_run(b, b.time + 2.05)
	t.near(hp0 - u.hp, 2.0 * (25.0 + 8.0), 0.5, "each Burning tick 25 + 4 × 2")
