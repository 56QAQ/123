extends RefCounted
## 重构版和星节点：初星的监护人(召唤护星节点；在场时全体友方初星系节点保持"初星之光"：最终减免，友军伤害 ×3 效能)、
## 监护人的智与力(2 星：治疗量加成 = 增幅 × 10%、暴击率 += 治疗量加成；每 5 秒光箭打血最少的敌人，再治疗血最少的队友)、
## 监护人的微笑(开局 + 每 3 秒，目标全体友方初星系节点)、专属武器硬质手杖(治疗 +30%；【基本】【群攻 4】治疗，溢出转护盾)。


func _run_until(b: Battle, sec: float) -> void:
	while b.time < sec and b.state != "ended":
		b.step()


func _of(b: Battle, id: String, team: int = 0) -> BUnit:
	for u: BUnit in b.units:
		if u.def.id == id and u.team == team and u.alive:
			return u
	return null


func test_first_star_light_covers_allied_first_star_nodes_while_he_lives(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_druid", "pos": Vector2(-1, 0), "star": 2}, {"def": "node_dancer", "pos": Vector2(1, 0), "star": 1},
		{"def": "test_hitter", "pos": Vector2(0, -2)}, {"def": "node_dancer", "team": 1, "pos": Vector2(0, 9)}])
	b.start()
	b.step()
	var dr: BUnit = b.units[0]
	var wr: BUnit = _of(b, "node_warrior")
	t.eq(wr.star, 3, "shared summon: 2★ + 1★")
	for u: BUnit in [dr, b.units[1], wr]:
		t.near(u.get_stats().final_dmg_reduction, 0.25, 0.0001, "%s has First-Star Light (2★: 25%%)" % u.def.id)
	t.near(b.units[2].get_stats().final_dmg_reduction, 0.0, 0.0001, "a non-First-Star ally doesn't")
	t.near(b.units[3].get_stats().final_dmg_reduction, 0.0, 0.0001, "an enemy First-Star node doesn't")
	t.ok(not b.units[1].get_status("first_star_light").has_flag("dispellable"), "can't be dispelled")
	# 他倒下后，初星之光很快消失
	b.pipeline.fx.damage(b.units[3], dr, 1.0e7, "true")
	_run_until(b, b.time + 0.8)
	t.near(b.units[1].get_stats().final_dmg_reduction, 0.0, 0.0001, "gone once he falls")


func test_final_reduction_triples_against_friendly_damage(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_druid", "pos": Vector2(-1, 0), "star": 2}, {"def": "node_dancer", "pos": Vector2(1, 0), "star": 2},
		{"def": "test_hitter", "team": 1, "pos": Vector2(0, 9)}])
	b.start()
	b.step()
	var dc: BUnit = b.units[1]
	var hp0: float = dc.hp
	b.pipeline.fx.damage(b.units[2], dc, 100.0, "true")
	t.near(hp0 - dc.hp, 75.0, 0.01, "enemy damage: -25%")
	hp0 = dc.hp
	b.pipeline.fx.damage(b.units[0], dc, 100.0, "true")
	t.near(hp0 - dc.hp, 25.0, 0.01, "friendly damage: -75% (three times as effective)")


func test_wisdom_heal_bonus_and_crit_from_two_stars(t: TestCtx) -> void:
	var b1 := Fixture.make([{"def": "node_druid", "pos": Vector2.ZERO, "star": 1, "weapon": "sturdy_cane"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}])
	b1.start()
	t.near(b1.units[0].get_stats().healing_done_pct, 0.30, 0.0001, "1★: only the cane's +30%")
	var b := Fixture.make([{"def": "node_druid", "pos": Vector2.ZERO, "star": 3, "weapon": "sturdy_cane"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}])
	var c0: float = b.units[0].get_stats().crit_chance
	b.start()
	var st: StatBlock = b.units[0].get_stats()
	t.near(st.healing_done_pct, 0.30 + 0.40, 0.0001, "3★: +Amplify 4 × 10% healing bonus")
	t.near(st.crit_chance, c0 + st.healing_done_pct, 0.0001, "crit chance += healing bonus")


func test_light_arrow_hits_the_weakest_enemy_and_heals_the_weakest_teammate(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_druid", "pos": Vector2.ZERO, "star": 2}, {"def": "test_hitter", "pos": Vector2(-2, 0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 8)}, {"def": "test_dummy", "team": 1, "pos": Vector2(2, 8)}])
	var weak: BUnit = b.units[3]
	b.start()
	weak.hp = 5000.0
	var ally: BUnit = b.units[1]
	ally.hp = 1000.0
	_run_until(b, 5.1)
	t.ok(not Fixture.events_of(b, "skill_projectile").is_empty(), "an arrow flies at 5 s")
	t.eq(Fixture.events_of(b, "skill_projectile")[0]["target"], weak, "at the enemy with the lowest health")
	var dmg: Array[Dictionary] = []
	_run_until(b, 5.8)
	for e: Dictionary in Fixture.events_of(b, "damage", "passive"):
		if e["src"] == b.units[0]:
			dmg.append(e)
	t.eq(dmg.size(), 1, "it lands once")
	var dealt: float = float(dmg[0]["amount"])
	var st: StatBlock = b.units[0].get_stats()
	var base: float = st.attack_power * (1.0 + st.ability_power / 100.0)
	t.near(dealt, base * (st.crit_damage if bool(dmg[0]["crit"]) else 1.0), 0.5, "attack × (100 + AP)% (0-def dummy)")
	t.ok(ally.hp >= 1000.0 + dealt - 0.5, "the hurt teammate is healed for the same amount")


func test_smile_heals_first_star_allies_and_overheal_becomes_shield(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_druid", "pos": Vector2.ZERO, "star": 1, "weapon": "sturdy_cane"}, {"def": "node_dancer", "pos": Vector2(1.5, 0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}])
	var dc: BUnit = b.units[1]
	b.start()
	var wr: BUnit = _of(b, "node_warrior")
	t.ok(wr.shield > 0.0 and dc.shield > 0.0, "the opening smile overheals full-health First-Star allies into shields")
	var sh0: float = dc.shield
	dc.hp = dc.get_stats().max_health * 0.5
	var h0: float = dc.hp
	_run_until(b, 3.05)
	var st: StatBlock = b.units[0].get_stats()
	var xr := 0.0
	for tr: TriggerDef in b.units[0].def.triggers:
		if tr.id == "node_druid_smile":
			xr = tr.ratio_for(1)
	var v: float = st.attack_power * (1.0 + st.ability_power / 100.0) * xr
	t.near(dc.hp - h0, v * (1.0 + st.healing_done_pct), 1.0, "every 3 s: heals value × 1 (+30%% healing bonus)")
	t.near(dc.shield, sh0, 0.01, "no overheal this time")


func test_sturdy_cane_stats(t: TestCtx) -> void:
	var e: EquipmentDef = Fixture.catalog().get_equipment("sturdy_cane")
	t.eq(e.class_id, "polearm", "two-handed long weapon")
	t.eq(e.color_id, "black", "black")
	t.eq(e.cost, 2, "rarity 2")
	t.near(float(e.flat_mods.get("healing_done_pct", 0.0)), 0.30, 0.0001, "+30% healing")
	t.ok(e.abilities[0].has_keyword("basic") and e.abilities[0].keyword_value("multi_attack", 1, 0) == 4, "【基本】【群攻 4】")
	var d: UnitDef = Fixture.catalog().get_unit("node_druid")
	t.eq(d.weapon_classes, ["polearm", "focus", "sword", "heavy", "bow"] as Array[String], "polearm default; focus / one-handed / heavy / bow allowed")
	t.ok(d.first_star and Fixture.catalog().get_unit("node_witch").first_star and Fixture.catalog().get_unit("node_warrior").first_star, "First-Star flags")
