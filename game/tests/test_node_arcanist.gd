extends RefCounted
## 奇兴节点：自无数个世界之中(【增幅 2/3/4】每 x 秒掷 2d10 + 增幅 + 阵亡队友数 → 【无数世界】)、自久远的过去而来(2 星：石化开局，80% 减伤，
## 阵亡 ≥ 存活时苏醒并获得 时间 × y 法强和攻击力)、触发器(每 5 秒，当前目标周围 2 米的敌人，z × 攻击力 × (100 + 法强)%)；
## 专武乱数(【群攻 3】：每个目标 1d20 → 0.05 × 点数 × n × 触发数值，1~5 物理 / 6~15 魔法 / 16~20 真实；阵亡 ≥ 存活必定 20)。


func _def() -> UnitDef:
	return Fixture.catalog().get_unit("node_arcanist")


func _trig(id: String) -> TriggerDef:
	for tr: TriggerDef in _def().triggers:
		if tr.id == id:
			return tr
	return null


func _calm(v: BUnit) -> void:
	v.attack_cd = 1.0e9
	v.base.move_speed = 0.0
	v.base.crit_chance = 0.0
	v.mark_dirty()


func _run(b: Battle, sec: float) -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	while b.time < sec - 0.0001 and b.state != "ended":
		b.step()
		all.append_array(b.poll_events())
	return all


static func _of(evs: Array[Dictionary], type: String) -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for e: Dictionary in evs:
		if e.get("t") == type:
			r.append(e)
	return r


func _roll(b: Battle, a: BUnit, dice: Array) -> Array[Dictionary]:
	var ab: AbilityDef = _def().passive_by_id("node_arcanist_worlds")
	var cfg: Dictionary = ab.effect_config.duplicate(true)
	cfg["force_dice"] = dice
	b.poll_events()
	b.pipeline._world_dice(a, 0.0, ab, {"cfg": cfg})
	return b.poll_events()


func _setup(star: int = 1) -> Battle:
	return Fixture.make([{"def": "node_arcanist", "pos": Vector2(0, -4), "star": star}, {"def": "test_hitter", "pos": Vector2(2, -4)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(-2, 4)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(2, 6)}])


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = _def()
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model], [3, "purple", "research", "caster", "focus", "arcanist"],
		"rarity 3, purple (2026-10-09: was blue), Research, caster, focus, arcanist model")
	t.eq(d.weapon_classes, ["focus", "polearm"] as Array[String], "can equip a two-handed long weapon")
	t.ok(d.passive_by_id("node_arcanist_worlds").has_keyword("worlds"), "the rules live in the 【Countless Worlds】 keyword")
	t.eq(d.passive_by_id("node_arcanist_petrify").unlock_star, 2, "From the Distant Past unlocks at 2 stars")
	var e: EquipmentDef = cat.get_equipment("chaos_dice")
	t.eq([e.class_id, e.color_id, e.cost, e.owner, e.model], ["polearm", "purple", 3, "node_arcanist", "dice"], "Randomness: polearm, purple, 3, hers")
	t.ok(e.abilities[0].cooldown == 4.0 and e.abilities[0].keyword_value("multi_attack", 1) == 3, "4 s cooldown 【Multi 3】")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_dice_total_and_parity(t: TestCtx) -> void:
	var b := _setup()
	var a: BUnit = b.units[0]
	b.start()
	_calm(a)
	_run(b, GC.START_DELAY + 0.05)
	var amp: int = Pipeline.kw_value(a, _def().passive_by_id("node_arcanist_worlds"), "amplify", 0)
	t.eq(amp, 2, "★1: 【Amplify 2】")
	var foes: Array = b.units.filter(func(u: BUnit) -> bool: return u.team == 1)
	var before: Array = foes.map(func(u: BUnit) -> Vector2: return u.pos)
	# 3 + 4 + 2 = 9：奇数 → 敌人换位；< 10 → 小额魔法伤害
	var evs: Array[Dictionary] = _roll(b, a, [3, 4])
	var dr: Dictionary = _of(evs, "dice_roll")[0]
	t.eq(int(dr["total"]), 9, "total = 3 + 4 + Amplify 2 (+ 0 fallen)")
	var after: Array = foes.map(func(u: BUnit) -> Vector2: return u.pos)
	var same_set := true
	for p: Variant in after:
		if not before.has(p):
			same_set = false
	t.ok(same_set and after != before, "odd: the enemies swap places among themselves")
	var dm: Array = _of(evs, "damage").filter(func(e: Dictionary) -> bool: return e["src"] == a)
	t.eq(dm.size(), 3, "every enemy is hit")
	t.eq(dm[0]["kind"], "magic", "under 10: magic")
	var st: StatBlock = a.get_stats()
	var low: float = float(_def().passive_by_id("node_arcanist_worlds").effect_config["tiers"]["low"])
	t.near(float(dm[0]["amount"]), low * (st.attack_power + st.ability_power), 1.0, "small: %.1f × (attack + AP)" % low)
	# 6 + 6 + 2 = 14：偶数 → 每个敌人身上同一个随机通用负面状态；≥ 10 → 物理(视为普攻伤害)
	evs = _roll(b, a, [6, 6])
	var deb := 0
	for f: BUnit in foes:
		for sid: String in ["burning", "chill", "poison", "paralysis"]:
			if f.status_count(sid) > 0 or f.get_status(sid) != null:
				deb += 1
	t.ok(deb >= 3, "even: every enemy gets a random common debuff")
	dm = _of(evs, "damage").filter(func(e: Dictionary) -> bool: return e["src"] == a and e.get("surface", "") != "status")
	t.eq(dm[0]["kind"], "physical", "10 or more: physical")
	# 10 + 9 + 2 = 21 → 真实
	evs = _roll(b, a, [10, 9])
	dm = _of(evs, "damage").filter(func(e: Dictionary) -> bool: return e["src"] == a and e.get("surface", "") != "status")
	t.eq(dm[0]["kind"], "true", "20 or more: true damage")


func test_snake_eyes_is_chaos(t: TestCtx) -> void:
	var b := _setup()
	var a: BUnit = b.units[0]
	b.start()
	_calm(a)
	_run(b, GC.START_DELAY + 0.05)
	var evs: Array[Dictionary] = _roll(b, a, [1, 1])
	t.ok(bool(_of(evs, "dice_roll")[0]["chaos"]), "two ones: chaos")
	var hit: Dictionary = {}
	for e: Dictionary in _of(evs, "damage"):
		if e["src"] == a and e.get("surface", "") != "status":
			hit[e["dst"]] = true
	t.ok(hit.has(a) and hit.has(b.units[1]) and hit.has(b.units[2]), "everyone takes the damage, friend or foe — herself too")
	t.ok(not _of(evs, "shuffle").is_empty(), "and everyone swaps places")


func test_dead_allies_add_to_the_roll(t: TestCtx) -> void:
	var b := _setup()
	var a: BUnit = b.units[0]
	b.start()
	_calm(a)
	_run(b, GC.START_DELAY + 0.05)
	b.units[1].hp = 0.0
	b.pipeline.fx.try_kill(b.units[1], null)
	var dr: Dictionary = _of(_roll(b, a, [2, 2]), "dice_roll")[0]
	t.eq(int(dr["total"]), 2 + 2 + 2 + 1, "one fallen ally: +1")


func test_petrified_until_half_the_team_falls(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_arcanist", "pos": Vector2(0, -4), "star": 2}, {"def": "test_hitter", "pos": Vector2(2, -4)},
		{"def": "test_hitter", "pos": Vector2(-2, -4)}, {"def": "test_hitter", "pos": Vector2(3, -5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var a: BUnit = b.units[0]
	b.start()
	_calm(a)
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 7.0)
	t.ok(a.get_status("petrified") != null and a.is_stunned(), "★2: starts petrified (a stun)")
	t.ok(a.get_stats().damage_taken_pct >= 0.799, "with 80% damage reduction")
	t.eq(_of(evs, "dice_roll").size(), 0, "a statue doesn't roll")
	b.units[1].hp = 0.0
	b.pipeline.fx.try_kill(b.units[1], null)
	t.ok(a.get_status("petrified") != null, "1 fallen vs 3 standing: still stone")
	var ap0: float = a.get_stats().ability_power
	var atk0: float = a.get_stats().attack_power
	b.units[2].hp = 0.0
	b.pipeline.fx.try_kill(b.units[2], null)
	t.ok(a.get_status("petrified") == null, "2 fallen vs 2 standing: she wakes")
	var y: float = float(_def().passive_by_id("node_arcanist_wake").effect_config["per_sec_by_star"]["2"])
	var gain: float = y * (b.time - GC.START_DELAY)
	t.near(a.get_stats().ability_power - ap0, gain, 0.5, "+ time × %.0f ability power (%.0f)" % [y, gain])
	t.near(a.get_stats().attack_power - atk0, gain, 0.5, "and attack")


func test_trigger_hits_around_the_target(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_arcanist", "pos": Vector2(0, -2), "weapon": "chaos_dice"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 1)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.2, 1.5)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 8)}])
	var a: BUnit = b.units[0]
	b.start()
	_calm(a)
	a.target = b.units[1]
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 5.3)
	var hit: Dictionary = {}
	for e: Dictionary in _of(evs, "d20"):
		hit[e["target"]] = int(e["roll"])
	t.ok(hit.has(b.units[1]) and hit.has(b.units[2]) and not hit.has(b.units[3]), "every 5 s: Randomness rolls on the enemies within 2 m of her target")
	var z: float = _trig("node_arcanist_strike").ratio_for(1)
	var v: float = a.get_stats().attack_power * z * (1.0 + a.get_stats().ability_power / 100.0)
	# 被动 1 可能同一时刻也打了一下：取紧跟在 d20 之后的那次伤害
	var d20: Array[Dictionary] = []
	var rolled: bool = false
	for e: Dictionary in evs:
		if e.get("t", "") == "d20" and e["target"] == b.units[1]:
			rolled = true
		elif rolled and e.get("t", "") == "damage" and e["src"] == a and e["dst"] == b.units[1]:
			d20.append(e)
			break
	var n: float = float(Fixture.catalog().get_equipment("chaos_dice").abilities[0].effect_config["n"])
	var r: int = int(hit[b.units[1]])
	var want_kind: String = "physical" if r <= 5 else ("magic" if r <= 15 else "true")
	t.eq(d20[0]["kind"], want_kind, "d20 %d → %s" % [r, want_kind])
	t.ok(d20[0]["amount"] > 0.0, "deals 0.05 × %d × %.0f × %.0f (before resistances)" % [r, n, v])


func test_randomness_rolls_twenty_when_the_team_is_down(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_arcanist", "pos": Vector2(0, -2), "weapon": "chaos_dice"}, {"def": "test_hitter", "pos": Vector2(3, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 1)}])
	var a: BUnit = b.units[0]
	b.start()
	_calm(a)
	b.units[1].hp = 0.0
	b.pipeline.fx.try_kill(b.units[1], null)
	b.poll_events()
	var ab: AbilityDef = Fixture.catalog().get_equipment("chaos_dice").abilities[0]
	b.pipeline._dice_damage(a, b.units[2], 100.0, ab, {"surface": "equipment", "ability_id": ab.id, "cfg": ab.effect_config})
	var ev: Array[Dictionary] = _of(b.poll_events(), "d20")
	t.eq(int(ev[0]["roll"]), 20, "1 fallen ≥ 1 standing: always 20")
	t.eq(ev[0]["kind"], "true", "→ true damage")
