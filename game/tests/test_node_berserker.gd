extends RefCounted
## 重构版狂猎节点：狼狩(可用时自动冲锋到最密的地方、落地斩[群攻3][暴击]；每场一次；攻击范围 +20%、10% 物理吸血)、
## 血战(2 星：击杀重置狼狩与再来一次；冲锋落地后嘲讽)、再来一次(濒死时触发，结算完才看血够不够)、
## 专属武器狼双刃(冷却 15 秒，[暴击][群攻3]，血量低于 10% 时伤害 ×3)。


func _steps_until(b: Battle, type: String, n: int = 1, cap: int = 600) -> void:
	var guard := 0
	while Fixture.events_of(b, type).size() < n and guard < cap:
		b.step()
		guard += 1


func _dash_count(b: Battle) -> int:
	return Fixture.events_of(b, "dash_start").size()


func test_wolf_hunt_dashes_to_the_densest_spot(t: TestCtx) -> void:
	var specs: Array = [{"def": "node_berserker", "pos": Vector2.ZERO, "star": 1},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0.0, 2.5)}]
	var cluster := Vector2(5.0, 1.0)
	for i in range(4):
		specs.append({"def": "test_dummy", "team": 1, "pos": cluster + Vector2(0.45 * float(i % 2), 0.45 * float(i / 2))})
	var b := Fixture.make(specs)
	var u: BUnit = b.units[0]
	b.start()
	for i2 in range(int(GC.START_DELAY / GC.SIM_DT) - 2):
		b.step()
	t.eq(_dash_count(b), 0, "doesn't dash during the countdown")
	_steps_until(b, "dash_strike")
	t.eq(_dash_count(b), 1, "dashes as soon as the battle runs")
	t.ok(u.pos.distance_to(cluster + Vector2(0.22, 0.22)) < 1.3, "lands in the 4-enemy cluster, not by the lone dummy (%s)" % str(u.pos))
	var hits: Array[Dictionary] = []
	for e: Dictionary in Fixture.events_of(b, "damage", "passive"):
		if e["src"] == u:
			hits.append(e)
	t.eq(hits.size(), 3, "[multi_attack 3]: 3 enemies hit")
	var atk: float = u.get_stats().attack_power
	for h: Dictionary in hits:
		var want: float = atk * 4.0 * (u.get_stats().crit_damage if bool(h["crit"]) else 1.0)
		t.near(float(h["amount"]), want, 0.5, "1★: attack × 4 physical (0-def dummy)")
	t.eq(Fixture.events_of(b, "dash_start")[0]["unit"], u, "dash event")
	t.ok(u.phase != "dash", "the dash is over")


func test_hunt_is_once_per_battle_at_1_star_and_kills_reset_it_from_2_stars(t: TestCtx) -> void:
	for star: int in [1, 2]:
		var specs: Array = [{"def": "node_berserker", "pos": Vector2.ZERO, "star": star}]
		for i in range(3):
			specs.append({"def": "test_dummy", "team": 1, "pos": Vector2(3.0 + 0.5 * float(i), 0.0)})
		var b := Fixture.make(specs)
		var u: BUnit = b.units[0]
		b.start()
		_steps_until(b, "dash_strike")
		for i2 in range(80):
			b.step()
		t.eq(_dash_count(b), 1, "%d★: one dash, then it's used up" % star)
		b.pipeline.fx.damage(u, b.units[1], 1.0e7, "true")
		for i3 in range(40):
			b.step()
		t.eq(_dash_count(b), 1 if star == 1 else 2, "%d★: a kill %s" % [star, "does nothing" if star == 1 else "resets Wolf Hunt → dashes again"])


func test_blood_fury_taunts_around_after_the_dash_from_2_stars(t: TestCtx) -> void:
	for star: int in [1, 2]:
		var specs: Array = [{"def": "node_berserker", "pos": Vector2.ZERO, "star": star},
			{"def": "test_hitter", "team": 1, "pos": Vector2(3.0, 0.0)}, {"def": "test_hitter", "team": 1, "pos": Vector2(3.4, 0.6)}]
		var b := Fixture.make(specs)
		var u: BUnit = b.units[0]
		b.start()
		_steps_until(b, "dash_strike")
		b.step()
		var taunted: int = 0
		for k in [1, 2]:
			if b.units[k].forced_target == u:
				taunted += 1
		t.eq(taunted, 0 if star == 1 else 2, "%d★: %s" % [star, "no taunt" if star == 1 else "every enemy around is taunted"])


func test_hunt_gives_range_and_lifesteal(t: TestCtx) -> void:
	var b0 := Fixture.make([{"def": "node_berserker", "pos": Vector2.ZERO}, {"def": "test_dummy", "team": 1, "pos": Vector2(8, 0)}])
	var r0: float = b0.units[0].get_stats().attack_range
	b0.start()
	t.near(b0.units[0].get_stats().attack_range, r0 * 1.2, 0.001, "attack range +20%")
	t.near(b0.units[0].get_stats().physical_lifesteal, 0.10, 0.0001, "10% physical lifesteal")
	var b1 := Fixture.make([{"def": "node_berserker", "pos": Vector2.ZERO, "weapon": "wolf_blades"}, {"def": "test_dummy", "team": 1, "pos": Vector2(8, 0)}])
	b1.start()
	t.near(b1.units[0].get_stats().physical_lifesteal, 0.20, 0.0001, "+10% more from Wolf Fangs")


func _once_more_battle(weapon: String) -> Battle:
	var specs: Array = [{"def": "node_berserker", "pos": Vector2.ZERO, "star": 1, "weapon": weapon}]
	for i in range(3):
		specs.append({"def": "test_dummy", "team": 1, "pos": Vector2(1.2, -0.8 + 0.8 * float(i))})
	return Fixture.make(specs)


func test_one_more_time_holds_off_death_until_resolved(t: TestCtx) -> void:
	var b := _once_more_battle("wolf_blades")
	var u: BUnit = b.units[0]
	b.start()
	_steps_until(b, "dash_strike")
	var n0: int = Fixture.events_of(b, "damage", "equipment").size()
	u.hp = 50.0
	b.pipeline.fx.damage(b.units[1], u, 120.0, "true")
	t.ok(u.alive, "survives: the lifesteal from the triggered hit brings him back above 0 (hp %.0f)" % u.hp)
	var ds: Array[Dictionary] = Fixture.events_of(b, "damage", "equipment")
	t.eq(ds.size() - n0, 3, "Wolf Fangs hit 3 enemies around him")
	var atk: float = u.get_stats().attack_power
	var total := 0.0
	for i in range(n0, ds.size()):
		var d: Dictionary = ds[i]
		total += float(d["amount"])
		var want: float = atk * 3.5 * 2.0 * 3.0 * (u.get_stats().crit_damage if bool(d["crit"]) else 1.0)
		t.near(float(d["amount"]), want, 1.0, "attack × 3.5 × 2 × 3 (below 10% health) per target")
	t.near(u.hp, -70.0 + total * 0.20, 1.0, "hp = -70 + 20% lifesteal of everything dealt")
	# 每场一次：再濒死就真的倒下(1 星没有击杀重置)
	u.hp = 10.0
	b.pipeline.fx.damage(b.units[1], u, 50.0, "true")
	t.ok(not u.alive, "the second time he falls")


func test_one_more_time_needs_a_weapon_effect(t: TestCtx) -> void:
	var b := _once_more_battle("")
	var u: BUnit = b.units[0]
	b.start()
	_steps_until(b, "dash_strike")
	u.hp = 50.0
	b.pipeline.fx.damage(b.units[1], u, 120.0, "true")
	t.ok(not u.alive, "basic weapon: the trigger has nothing to pair with → he falls")


func test_wolf_fangs_stats(t: TestCtx) -> void:
	var e: EquipmentDef = Fixture.catalog().get_equipment("wolf_blades")
	t.eq(e.class_id, "dual", "twin blades")
	t.eq(e.color_id, "red", "red")
	t.eq(e.cost, 2, "rarity 2")
	t.near(float(e.flat_mods.get("crit_chance", 0.0)), 0.10, 0.0001, "+10% crit")
	t.near(float(e.flat_mods.get("physical_lifesteal", 0.0)), 0.10, 0.0001, "+10% physical lifesteal")
	t.near(e.abilities[0].cooldown, 15.0, 0.001, "15 s cooldown")
	t.ok(e.abilities[0].has_keyword("crit") and e.abilities[0].keyword_value("multi_attack", 1, 0) == 3, "【暴击】【群攻 3】")
	var d: UnitDef = Fixture.catalog().get_unit("node_berserker")
	t.eq(d.cost, 2, "rarity 2")
	t.eq(d.base_weapon_class, "dual", "default: twin blades")
	t.eq(d.weapon_classes, ["dual", "heavy"] as Array[String], "can also use two-handed heavy weapons")
