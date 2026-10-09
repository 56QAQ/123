extends RefCounted
## 白羽节点：致向死的渴望(【叠加 30】每第二发普攻——双枪 = 追击那发——改打射程里生命 < 97% 的队友，回复其 3% 最大生命；所有普攻叠送葬；
## 叠满 30：普通怪物和棋子立刻死亡且不触发阵亡效果，否则失去 x% 生命上限并消耗送葬)、致求生的意志(2 星：持有送葬的友军受致命伤害不阵亡，
## 每 y 点伤害再叠一层)、致将亡而未亡者(每 5 秒连续触发 4 次，目标 = 送葬最多的敌人，触发数值 10)；专武飞蝶(【基本】发动普攻，至多造成触发数值的伤害)。


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
	while b.time < sec - 0.0001 and b.state != "ended":
		all.append_array(_step(b))
	return all


func _def() -> UnitDef:
	return Fixture.catalog().get_unit("node_angel")


func _x(star: int) -> float:
	return float(_def().passive_by_id("node_angel_funeral").effect_config["loss_by_star"][str(star)])


func _z() -> int:
	return _def().passive_by_id("node_angel_funeral").keyword_value("stacking", 1)


func _calm(v: BUnit) -> void:
	v.attack_cd = 1.0e9
	v.base.move_speed = 0.0
	v.base.crit_chance = 0.0
	v.mark_dirty()


func _stack(b: Battle, src: BUnit, t: BUnit, n: int) -> void:
	var cfg: Dictionary = (_def().passive_by_id("node_angel_funeral").effect_config["status"] as Dictionary).duplicate(true)
	cfg["max_stacks"] = _z()
	cfg["add_stacks"] = n
	b.pipeline.fx.apply_status(src, t, cfg)


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = _def()
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model], [3, "cyan", "welfare", "archer", "pistols", "angel"],
		"rarity 3, cyan, Welfare, archer, dual ranged, angel model")
	t.eq(d.weapon_classes, ["pistols", "crossbow", "rifle"] as Array[String], "can equip one-hand and two-hand ranged")
	var z: int = d.passive_by_id("node_angel_funeral").keyword_value("stacking", 1)
	t.ok(z >= 5 and z <= 40, "【Stacking z】 (%d)" % z)
	t.eq(d.passive_by_id("node_angel_will").unlock_star, 2, "To the Will to Live unlocks at 2★")
	var e: EquipmentDef = cat.get_equipment("butterfly")
	t.eq([e.class_id, e.color_id, e.cost, e.owner, e.model], ["pistols", "cyan", 3, "node_angel", "butterfly"], "Butterfly: dual ranged, cyan, rarity 3, hers")
	t.ok(e.abilities[0].has_keyword("basic") and float(e.pct_mods.get("attack_speed_multiplier", 0.0)) > 0.0, "【Basic】 + attack speed")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_pistol_pursuit_shot_heals_a_hurt_ally(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_angel", "pos": Vector2(0, -2)}, {"def": "node_shielder", "pos": Vector2(1.2, -1.5), "hp_ratio": 0.5},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.4)}])
	var a: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	_calm(ally)
	b.start()
	ally.hp = ally.get_stats().max_health * 0.5          # (Battle.start 会把生命重置满)
	_run(b, GC.START_DELAY + 0.2)
	var hp0: float = ally.hp
	a.attack_cd = 0.0
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 1.0)
	var heals: Array[Dictionary] = _of(evs, "heal").filter(func(e: Dictionary) -> bool: return e["dst"] == ally and e["src"] == a)
	t.ok(heals.size() >= 1, "the pursuit shot heals the hurt ally (%d heals)" % heals.size())
	t.near(float(heals[0]["amount"]), ally.get_stats().max_health * 0.03, 0.5, "for 3% of its max health")
	t.ok(ally.hp > hp0, "ally healed")
	t.ok(ally.status_stacks("funeral") >= 1, "and the healing shot adds Funeral too")
	t.ok(foe.status_stacks("funeral") >= 1, "the first shot hits the enemy and adds Funeral")
	var dmg_ally: Array[Dictionary] = _of(evs, "damage").filter(func(e: Dictionary) -> bool: return e["dst"] == ally)
	t.eq(dmg_ally.size(), 0, "no damage to the ally")


func test_no_hurt_ally_all_shots_hit_enemies(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_angel", "pos": Vector2(0, -2)}, {"def": "node_shielder", "pos": Vector2(1.2, -1.5)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.4)}])
	var a: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	_calm(ally)
	b.start()
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 1.5)
	t.eq(ally.status_stacks("funeral"), 0, "full-health ally: never targeted")
	var na: int = _of(evs, "damage").filter(func(e: Dictionary) -> bool: return e["dst"] == foe and e["surface"] == "normal_attack").size()
	t.eq(foe.status_stacks("funeral"), na, "every shot (main + pursuit) on the enemy adds a stack (%d)" % na)


func test_crossbow_every_second_attack_goes_to_an_ally(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_angel", "pos": Vector2(0, -2), "weapon": "basic_crossbow"}, {"def": "node_shielder", "pos": Vector2(1.2, -1.5), "hp_ratio": 0.3},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.5)}])
	var a: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	_calm(ally)
	b.start()
	ally.hp = ally.get_stats().max_health * 0.3
	_run(b, GC.START_DELAY + 4.0)
	var to_foe: int = foe.status_stacks("funeral")
	var to_ally: int = ally.status_stacks("funeral")
	t.ok(to_foe >= 2 and absi(to_foe - to_ally) <= 1, "alternates: %d on the enemy, %d on the ally" % [to_foe, to_ally])


func test_full_funeral_kills_monsters_and_nodes_without_death_effects(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_angel", "pos": Vector2(0, -3)}, {"def": "node_shielder", "pos": Vector2(2, -3)},
		{"def": "mob_guardian", "team": 1, "pos": Vector2(0, 8)}, {"def": "mob_guardian", "team": 1, "pos": Vector2(3, 8)}])
	var a: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var mob: BUnit = b.units[2]
	var elite: BUnit = b.units[3]
	elite.meta["elite"] = true
	_calm(a)
	_calm(ally)
	b.start()
	_run(b, GC.START_DELAY + 0.1)
	var pa: AbilityDef = _def().passive_by_id("node_angel_funeral")
	_stack(b, a, mob, _z() - 1)
	var ev: Dictionary = b.pipeline.make_event("OnNormalAttackHit", a, mob, 0.0, ["normal_attack"], {})
	b.pipeline._funeral_mark(a, mob, pa, {"cfg": pa.effect_config})
	var evs: Array[Dictionary] = b.poll_events()
	t.ok(not mob.alive, "a common monster at 30 stacks dies at once")
	t.ok(bool(mob.meta.get("no_death_fx", false)), "without its on-death effects")
	_stack(b, a, ally, _z() - 1)
	b.pipeline._funeral_mark(a, ally, pa, {"cfg": pa.effect_config})
	t.ok(not ally.alive, "so does a node — even her own teammate")
	var mh0: float = elite.get_stats().max_health
	_stack(b, a, elite, _z() - 1)
	b.pipeline._funeral_mark(a, elite, pa, {"cfg": pa.effect_config})
	t.ok(elite.alive, "an elite survives")
	t.near(mh0 - elite.get_stats().max_health, mh0 * _x(1), 1.0, "losing %d%% max health" % int(round(_x(1) * 100.0)))
	t.eq(elite.status_stacks("funeral"), 0, "Funeral spent")
	t.ok(elite.status_stacks("funeral_scar") > 0, "recorded on Funeral Scar")


func test_will_to_live_two_star(t: TestCtx) -> void:
	for star: int in [1, 2]:
		var b := Fixture.make([{"def": "node_angel", "pos": Vector2(0, -3), "star": star}, {"def": "node_shielder", "pos": Vector2(2, -3)},
			{"def": "test_dummy", "team": 1, "pos": Vector2(0, 8)}])
		var a: BUnit = b.units[0]
		var ally: BUnit = b.units[1]
		var foe: BUnit = b.units[2]
		_calm(a)
		_calm(ally)
		b.start()
		_run(b, GC.START_DELAY + 0.1)
		_stack(b, a, ally, 2)
		ally.hp = 100.0
		b.pipeline.fx.damage(foe, ally, 700.0, "true", {})
		if star == 1:
			t.ok(not ally.alive, "1★: no Will to Live yet — lethal damage kills")
			continue
		var y: float = float(_def().passive_by_id("node_angel_will").effect_config["per_by_star"]["2"])
		t.ok(ally.alive and ally.hp >= 1.0, "2★: an ally with Funeral survives lethal damage")
		t.eq(ally.status_stacks("funeral"), 2 + int(floor(700.0 / y)), "+1 Funeral per %d damage" % int(y))
		var fresh: BUnit = b.units[0]
		# 没有送葬的队友照常倒下
		var b2 := Fixture.make([{"def": "node_angel", "pos": Vector2(0, -3), "star": 2}, {"def": "node_shielder", "pos": Vector2(2, -3)},
			{"def": "test_dummy", "team": 1, "pos": Vector2(0, 8)}])
		b2.start()
		b2.units[1].hp = 100.0
		b2.pipeline.fx.damage(b2.units[2], b2.units[1], 700.0, "true", {})
		t.ok(not b2.units[1].alive, "2★: an ally without Funeral dies normally")
		# 叠满：照规则倒下
		_stack(b, a, ally, _z() - ally.status_stacks("funeral") - 1)
		b.pipeline.fx.damage(foe, ally, 5000.0, "true", {})
		t.ok(not ally.alive, "2★: when the extra stacks fill Funeral, it falls")
		t.ok(bool(ally.meta.get("no_death_fx", false)), "…without its on-death effects")


func test_requiem_fires_butterfly_four_times(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_angel", "pos": Vector2(0, -3), "weapon": "butterfly"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 2)}, {"def": "test_dummy", "team": 1, "pos": Vector2(3, 6)}])
	var a: BUnit = b.units[0]
	var near: BUnit = b.units[1]
	var marked: BUnit = b.units[2]
	_calm(a)
	b.start()
	_run(b, GC.START_DELAY + 0.1)
	_stack(b, a, marked, 1)
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 6.5)
	var hits: Array[Dictionary] = _of(evs, "damage").filter(func(e: Dictionary) -> bool: return e["dst"] == marked and e["surface"] == "normal_attack")
	t.eq(hits.size(), 8, "4 triggers × (shot + pursuit) on the enemy with the most Funeral (no hurt ally)")
	var top := 0.0
	for h: Dictionary in hits:
		top = maxf(top, float(h["amount"]))
	t.ok(top <= 10.001, "each deals at most the trigger value (10): max %.1f" % top)
	t.eq(marked.status_stacks("funeral"), 1 + 8, "+8 Funeral")
	t.eq(near.status_stacks("funeral"), 0, "the nearer enemy without Funeral isn't picked")


func test_texts_match_data(t: TestCtx) -> void:
	var xs := "{★%d%%/%d%%/%d%%}" % [int(round(_x(1) * 100.0)), int(round(_x(2) * 100.0)), int(round(_x(3) * 100.0))]
	var yb: Dictionary = _def().passive_by_id("node_angel_will").effect_config["per_by_star"]
	var ys := "{★%d/%d/%d}" % [int(yb["1"]), int(yb["2"]), int(yb["3"])]
	var z: int = _def().passive_by_id("node_angel_funeral").keyword_value("stacking", 1)
	for lang: String in ["zh", "en"]:
		var p1: String = Loc.t_in(lang, "unit.node_angel.passive.node_angel_funeral")
		t.ok(p1.contains(xs) and p1.contains("%d" % z), "%s: funeral %s / %d" % [lang, xs, z])
		t.ok(Loc.t_in(lang, "unit.node_angel.passive.node_angel_will").contains(ys), "%s: will %s" % [lang, ys])
