extends RefCounted
## 清心节点：清心符(每 5/4/3 秒治疗一个队友并清除至多 3 个可驱散负面；负面多的优先，其次当前生命低的)、
## 弱体符(2 星：每 4/4/3 秒打当前物理输出最高的敌人并叠【弱体】)、道法自然(发动被动时触发，目标 = 被动的目标)、
## 专属武器如律所令(治疗 +20%、增伤 +10%；按阵营与定位挂六种【律令】之一)。


func _run_until(b: Battle, sec: float) -> void:
	while b.time < sec and b.state != "ended":
		b.step()


func _burn(b: Battle, u: BUnit, n: int) -> void:
	for i in range(n):
		b.pipeline.fx.apply_status(null, u, {"status_id": "burning", "independent": true, "duration": 30.0, "flags": ["debuff", "dispellable"]})


func test_unit_data(t: TestCtx) -> void:
	var d: UnitDef = Fixture.catalog().get_unit("node_taoist")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role], [1, "green", "welfare", "caster"], "rarity 1, green, Welfare, caster")
	t.eq(d.weapon_classes, ["focus", "rifle", "pistols", "crossbow"] as Array[String], "focus default; two-handed / dual / one-handed ranged")
	t.eq(d.model, "taoist", "her own model")
	var e: EquipmentDef = Fixture.catalog().get_equipment("talisman_edict")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["focus", "green", 1, "node_taoist"], "Edict Talisman: focus, green, rarity 1, hers")
	t.near(float(e.flat_mods.get("healing_done_pct", 0.0)), 0.2, 0.0001, "+20% healing")
	t.near(float(e.flat_mods.get("damage_dealt_pct", 0.0)), 0.1, 0.0001, "+10% damage")
	var a: AbilityDef = e.abilities[0]
	t.ok(a.ability_class == "bullet" and (a.effect_config.get("extra_rules", []) as Array).has("amulet"), "【固定值】【双模】")
	t.ok(a.has_keyword("basic") and a.keyword_value("stacking", 1, 0) == 3, "【基本】【叠加 3】")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")
	t.eq(Fixture.catalog().get_unit("node_basic").model, "basic", "Node Basic now uses the basic body from its card")


func test_qingxin_prefers_the_most_debuffed_then_the_lowest_health(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_taoist", "pos": Vector2(0, -6)}, {"def": "test_dummy", "pos": Vector2(-2, 0)},
		{"def": "test_dummy", "pos": Vector2(2, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 12)}])
	var tao: BUnit = b.units[0]
	var low: BUnit = b.units[1]
	var cursed: BUnit = b.units[2]
	b.start()
	low.hp = 20000.0
	cursed.hp = 90000.0
	_burn(b, cursed, 4)
	_run_until(b, 4.9)
	t.eq(cursed.status_count("burning"), 4, "nothing before 5 s")
	var hp0: float = cursed.hp
	_run_until(b, 5.05)
	t.eq(cursed.status_count("burning"), 1, "5 s: the most-debuffed teammate loses up to 3 negative effects")
	t.near(cursed.hp - hp0, 150.0, 0.5, "…after being healed for 150")
	var hl: float = low.hp
	_run_until(b, 10.05)
	t.eq(cursed.status_count("burning"), 0, "10 s: still the one with negative effects")
	_run_until(b, 15.05)
	t.near(low.hp - hl, 150.0, 0.5, "15 s: nobody has negative effects → the lowest health")
	t.ok(not Fixture.events_of(b, "cast_fx").is_empty(), "a talisman flies for the view")


func test_qingxin_interval_and_heal_by_star(t: TestCtx) -> void:
	for star: int in [1, 2, 3]:
		var b := Fixture.make([{"def": "node_taoist", "pos": Vector2(0, -6), "star": star}, {"def": "test_dummy", "pos": Vector2(0, 0)},
			{"def": "test_dummy", "team": 1, "pos": Vector2(0, 12)}])
		b.start()
		b.units[1].hp = 10000.0
		_run_until(b, 15.05)
		var heals := 0
		var amt := 0.0
		for e: Dictionary in Fixture.events_of(b, "heal"):
			if e["src"] == b.units[0] and e["dst"] == b.units[1]:
				heals += 1
				amt = float(e["amount"])
		t.eq(heals, [3, 3, 5][star - 1], "%d★: every %d s" % [star, [5, 4, 3][star - 1]])
		t.near(amt, [150.0, 220.0, 320.0][star - 1], 0.5, "%d★: heals %d" % [star, int([150.0, 220.0, 320.0][star - 1])])


func test_weak_talisman_hits_the_top_physical_dealer(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_taoist", "pos": Vector2(0, -6), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(-2, 10)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(2, 10)}])
	var a: BUnit = b.units[1]
	var c: BUnit = b.units[2]
	b.start()
	c.st_dmg_by_kind["physical"] = 500.0
	a.st_dmg_by_kind["magic"] = 2000.0
	var atk0: float = c.get_stats().attack_power
	var as0: float = c.get_stats().attack_speed_multiplier
	_run_until(b, 4.05)
	t.eq(c.status_stacks("weak"), 1, "the top physical dealer (magic damage doesn't count) gets one Enfeebled")
	t.near(c.get_stats().attack_power, atk0 * 0.93, 0.01, "-7% attack")
	t.near(c.get_stats().attack_speed_multiplier, as0 * 0.93, 0.0001, "-7% attack speed")
	var hit := 0.0
	for e: Dictionary in Fixture.events_of(b, "damage"):
		if e["src"] == b.units[0] and e["dst"] == c and str(e["kind"]) == "magic":
			hit = float(e["amount"])
	t.near(hit, 60.0, 0.01, "2★: 60 magic damage")
	_run_until(b, 20.05)
	t.eq(c.status_stacks("weak"), 3, "stacks up to 3")
	var w: BStatus = c.get_status("weak")
	t.ok(w.has_flag("debuff") and w.has_flag("dispellable"), "negative, dispellable")
	var b1 := Fixture.make([{"def": "node_taoist", "pos": Vector2(0, -6)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 10)}])
	b1.start()
	_run_until(b1, 9.0)
	t.eq(b1.units[1].status_stacks("weak"), 0, "1★: locked")


func test_follow_the_way_and_the_edict(t: TestCtx) -> void:
	# 清心符打队友(坦克 → 最大生命)，弱体符打敌人(普通 → 攻击力)；道法自然把如律所令挂到同一个目标上
	var b := Fixture.make([{"def": "node_taoist", "pos": Vector2(0, -6), "star": 2, "weapon": "talisman_edict"},
		{"def": "node_shielder", "pos": Vector2(0, 0)}, {"def": "test_hitter", "team": 1, "pos": Vector2(0, 14)}])
	var tank: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	b.start()
	tank.base.move_speed = 0.0
	tank.mark_dirty()
	tank.hp = tank.get_stats().max_health * 0.5
	var max0: float = tank.get_stats().max_health
	var atk0: float = foe.get_stats().attack_power
	_run_until(b, 3.95)
	var hp1: float = tank.hp
	_run_until(b, 4.05)
	t.eq(foe.status_stacks("edict_atk_down"), 1, "4 s: Enfeebling Talisman on the enemy → Edict lowers its attack")
	t.near(foe.get_stats().attack_power, atk0 * (1.0 - 0.07 - 0.1), 0.01, "-7% (Enfeebled) - 10% (Edict)")
	t.ok(foe.get_status("edict_atk_down").has_flag("debuff"), "the lowering Edict is a negative effect")
	t.eq(tank.status_stacks("edict_hp_up"), 1, "4 s: Heart-Calming Talisman on the tank → Edict raises its max health")
	t.near(tank.get_stats().max_health, max0 * 1.1, 0.5, "+10% max health")
	t.near(tank.hp, (hp1 + 220.0 * 1.2) * 1.1, 1.0, "healed 264, then current health scales with the higher max (+10%)")
	var heals: Array[Dictionary] = []
	for e: Dictionary in Fixture.events_of(b, "heal"):
		if e["src"] == b.units[0] and str(e["ability"]) == "node_taoist_qingxin_heal":
			heals.append(e)
	t.ok(not heals.is_empty() and absf(float(heals[0]["amount"]) - 220.0 * 1.2) < 0.5, "+20% healing from the talisman (220 → 264)")
	# 靠法术强度输出的队友 → 法术强度
	var b2 := Fixture.make([{"def": "node_taoist", "pos": Vector2(0, -6), "weapon": "talisman_edict"}, {"def": "node_witch", "pos": Vector2(0, 0), "star": 1},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 14)}])
	b2.start()
	var w: BUnit = b2.units[1]
	w.hp = w.get_stats().max_health * 0.5
	var ap0: float = w.get_stats().ability_power
	_run_until(b2, 5.05)
	t.eq(w.status_stacks("edict_ap_up"), 1, "an ability-power ally gets Edict · Insight")
	t.near(w.get_stats().ability_power, ap0 * 1.1, 0.01, "+10% ability power")
	t.eq(Fixture.events_of(b2, "trigger").size() >= 1, true, "the weapon fired through the trigger")
