extends RefCounted
## 狩胜节点：必胜(备战上场 → 武器库里多一面狩猎旗标；开战投掷武器打狩猎对象并位移过去；只以狩猎对象为目标)、
## 凯旋(2 星：击杀攒光荣，光荣 5 层免疫可驱散负面、8 层免死一次、10 层再获得层数 → 再投一次)、
## 我已得胜(击杀触发，触发数值 = z × 被击杀者星级，精英 ×2、首领 ×3)、专属武器赤焰战旗(累加的攻击 / 攻速强化，溅射 1/4 只给队友)。


func _run_until(b: Battle, sec: float) -> void:
	while b.time < sec and b.state != "ended":
		b.step()


func _no_crit(u: BUnit) -> void:
	u.base.crit_chance = 0.0
	u.mark_dirty()


func _glory(u: BUnit) -> int:
	return u.status_stacks("glory")


func _ratio(id: String, star: int) -> float:
	for tr: TriggerDef in Fixture.catalog().get_unit("node_gladiator").triggers:
		if tr.id == id:
			return tr.ratio_for(star)
	return 0.0


func test_unit_data(t: TestCtx) -> void:
	var d: UnitDef = Fixture.catalog().get_unit("node_gladiator")
	t.eq(d.cost, 3, "rarity 3")
	t.eq(d.faction_id, "red", "red")
	t.eq(d.profession_id, "security", "Security Department")
	t.eq(d.special_traits, ["blaze"] as Array[String], "special tag 如火")
	t.eq(d.weapon_classes, ["polearm", "sword", "heavy", "dual"] as Array[String], "polearm default; sword / heavy / dual allowed")
	t.eq(d.prep_items, ["hunt_flag"] as Array[String], "brings the Hunting Flag")
	t.near(d.base_stats.attack_power, 170.0, 0.01, "warrior template (3)")
	var e: EquipmentDef = Fixture.catalog().get_equipment("flame_banner")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["polearm", "red", 3, "node_gladiator"], "Crimson Flame Banner: polearm, red, rarity 3, hers")
	t.ok(e.abilities[0].has_keyword("crit") and e.abilities[0].keyword_value("splash", 1, 0) == 6, "【暴击】【溅射 6】")
	var f: EquipmentDef = Fixture.catalog().get_equipment("hunt_flag")
	t.eq(f.slot, "token", "the flag is a special item")
	t.ok(f.equip_problem(d) != "", "it can't be worn")
	t.ok(not Fixture.catalog().equipment_ids().has("hunt_flag"), "never dropped / crafted / sold")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_opening_throw_hits_the_quarry_and_closes_in(t: TestCtx) -> void:
	# 没有标记：大家都还没造成伤害 → 攻击力最高的敌人(一样高时离她最近的)当狩猎对象
	var b := Fixture.make([{"def": "node_gladiator", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 7)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(4, 9)}])
	var g: BUnit = b.units[0]
	var near: BUnit = b.units[1]
	_no_crit(g)
	b.start()
	_run_until(b, GC.START_DELAY + 0.1)
	t.eq(b.hunt_targets.get(g.team), near, "no mark, nobody has dealt damage, same attack: the nearest enemy")
	t.eq(Fixture.events_of(b, "throw_start").size(), 1, "she throws once at the start")
	_run_until(b, GC.START_DELAY + 1.6)
	var hits: Array[Dictionary] = []
	for e: Dictionary in Fixture.events_of(b, "damage"):
		if e["src"] == g and e["dst"] == near and str(e["ability"]) == "node_gladiator_throw":
			hits.append(e)
	t.eq(hits.size(), 1, "the throw lands")
	if not hits.is_empty():
		t.near(float(hits[0]["amount"]), g.get_stats().attack_power * _ratio("node_gladiator_throw", 1), 0.01, "attack × x physical")
	t.ok(g.pos.distance_to(near.pos) < g.radius + near.radius + 0.4, "then she is right next to it (%.2f m)" % g.pos.distance_to(near.pos))
	t.eq(Fixture.events_of(b, "weapon_return").size(), 1, "and has her weapon back")


func test_quarry_tie_break_prefers_the_strongest_attacker(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_gladiator", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 4)},
		{"def": "test_hitter", "team": 1, "pos": Vector2(3, 10)}])
	b.units[2].base.attack_power = 300.0
	b.units[2].mark_dirty()
	b.start()
	_run_until(b, GC.START_DELAY + 0.1)
	t.eq(b.hunt_targets.get(GC.TEAM_PLAYER), b.units[2], "nobody has dealt damage yet → the highest-attack enemy, even if farther")


func test_hunting_flag_mark_picks_the_quarry(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_gladiator", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 7)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(4, 9)}])
	var marked: BUnit = b.units[2]
	marked.meta["hunt_marked_by"] = GC.TEAM_PLAYER
	b.start()
	_run_until(b, GC.START_DELAY + 1.6)
	t.eq(b.hunt_targets.get(GC.TEAM_PLAYER), marked, "the flagged enemy is the quarry")
	t.eq(b.units[0].target, marked, "and her target")
	t.ok(b.units[0].pos.distance_to(marked.pos) < 1.4, "she closed in on it")


func test_throw_counts_as_normal_attack_damage(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_gladiator", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 7)}])
	var g: BUnit = b.units[0]
	_no_crit(g)
	b.start()
	b.pipeline.fx.apply_status(null, b.units[1], {"status_id": "na_red", "stats": {"na_damage_taken_flat": {"flat": 50.0}}})
	_run_until(b, GC.START_DELAY + 1.6)
	var dmg := 0.0
	for e: Dictionary in Fixture.events_of(b, "damage"):
		if str(e["ability"]) == "node_gladiator_throw":
			dmg = float(e["amount"])
	t.near(dmg, g.get_stats().attack_power * _ratio("node_gladiator_throw", 1) - 50.0, 0.01, "flat normal-attack reduction applies to the throw")


func test_she_only_targets_the_quarry_then_the_top_damage_dealer(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_gladiator", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 5)},
		{"def": "test_hitter", "team": 1, "pos": Vector2(-2, 6)}, {"def": "test_dummy", "team": 1, "pos": Vector2(2, 6)}])
	var g: BUnit = b.units[0]
	var q: BUnit = b.units[1]
	b.start()
	_run_until(b, GC.START_DELAY + 1.0)
	t.eq(b.hunt_targets.get(g.team), q, "quarry = nearest at the start (same attack)")
	b.pipeline.fx.taunt(b.units[2], 0.0, 5.0)
	_run_until(b, b.time + 0.5)
	t.eq(g.target, q, "taunt doesn't pull her off the quarry")
	b.units[3].st_damage = 500.0
	b.units[2].st_damage = 200.0
	b.pipeline.fx.damage(null, q, 1.0e7, "true")
	_run_until(b, b.time + 0.3)
	t.eq(g.target, b.units[3], "quarry gone → the enemy that dealt the most damage")
	t.eq(b.hunt_targets.get(g.team), b.units[3], "becomes the new quarry")


func test_triumph_glory_stacks_by_star_and_quarry(t: TestCtx) -> void:
	for star: int in [1, 2, 3]:
		var b := Fixture.make([{"def": "node_gladiator", "pos": Vector2(0, 0), "star": star}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 2)},
			{"def": "test_dummy", "team": 1, "pos": Vector2(2, 9)}, {"def": "test_dummy", "team": 1, "pos": Vector2(-2, 9)}])
		var g: BUnit = b.units[0]
		b.start()
		_run_until(b, GC.START_DELAY + 0.05)
		var q: BUnit = b.hunt_targets.get(g.team)
		var other: BUnit = b.units[2] if q != b.units[2] else b.units[3]
		b.pipeline.fx.damage(g, other, 1.0e7, "true")
		var want1: int = [0, 1, 2][star - 1]
		t.eq(_glory(g), want1, "%d★: a normal kill → %d Glory" % [star, want1])
		b.pipeline.fx.damage(g, q, 1.0e7, "true")
		var want2: int = want1 + [0, 3, 6][star - 1]
		t.eq(_glory(g), want2, "%d★: killing the quarry → +%d" % [star, [0, 3, 6][star - 1]])


func test_glory_adds_magic_to_physical_normal_attacks(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_gladiator", "pos": Vector2(0, 0), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.0)}])
	var g: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	_no_crit(g)
	b.start()
	b.pipeline.fx.apply_status(g, g, {"status_id": "glory", "add_stacks": 4, "max_stacks": 10, "stats": {"na_bonus_magic_pct": {"flat": 0.1}}})
	b.events.clear()
	b.pipeline.normal_attack(g, foe)
	var phys := 0.0
	var mag := 0.0
	for e: Dictionary in Fixture.events_of(b, "damage"):
		if e["src"] == g and e["dst"] == foe:
			if str(e["kind"]) == "physical":
				phys += float(e["amount"])
			elif str(e["ability"]) == "glory_magic":
				mag += float(e["amount"])
	t.ok(phys > 0.0, "the normal attack hits")
	t.near(mag, phys * 0.4, 0.01, "4 stacks → +40% of it as magic (0-resist dummy)")


func test_glory_thresholds_immunity_and_death_save(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_gladiator", "pos": Vector2(0, 0), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}])
	var g: BUnit = b.units[0]
	b.start()
	var gcfg: Dictionary = {}
	for pa: AbilityDef in g.def.passives:
		if pa.id == "node_gladiator_glory":
			gcfg = pa.effect_config.duplicate(true)
	gcfg["max_stacks"] = 10
	gcfg["add_stacks"] = 4
	b.pipeline.fx.apply_status(g, g, gcfg)
	var burn := {"status_id": "burning", "independent": true, "duration": 5.0, "flags": ["debuff", "dispellable"]}
	t.ok(b.pipeline.fx.apply_status(null, g, burn) != null, "4 stacks: still takes debuffs")
	gcfg["add_stacks"] = 1
	b.pipeline.fx.apply_status(g, g, gcfg)
	t.ok(b.pipeline.fx.apply_status(null, g, burn) == null, "5 stacks: immune to dispellable debuffs")
	t.ok(b.pipeline.fx.apply_status(null, g, {"status_id": "curse_t", "duration": 5.0, "flags": ["debuff"]}) != null, "non-dispellable ones still land")
	gcfg["add_stacks"] = 3
	b.pipeline.fx.apply_status(g, g, gcfg)
	t.eq(_glory(g), 8, "8 stacks")
	b.pipeline.fx.damage(b.units[1], g, 1.0e7, "true")
	t.ok(g.alive, "8 stacks: survives a lethal hit")
	t.eq(_glory(g), 7, "…losing one stack")
	t.near(g.hp, g.get_stats().max_health * 0.25, 0.5, "…and back at 25% health")
	b.pipeline.fx.damage(b.units[1], g, 1.0e7, "true")
	t.ok(not g.alive, "7 stacks: no more saves")


func test_glory_overflow_at_ten_throws_again(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_gladiator", "pos": Vector2(0, 0), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 2)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(1, 14)}])
	var g: BUnit = b.units[0]
	b.start()
	_run_until(b, GC.START_DELAY + 1.5)
	var gcfg: Dictionary = {}
	for pa: AbilityDef in g.def.passives:
		if pa.id == "node_gladiator_glory":
			gcfg = pa.effect_config.duplicate(true)
	gcfg["max_stacks"] = 10
	gcfg["add_stacks"] = 10
	b.pipeline.fx.apply_status(g, g, gcfg)
	var n0: int = Fixture.events_of(b, "throw_start").size()
	var q: BUnit = b.hunt_targets.get(g.team)
	b.pipeline.fx.damage(g, q, 1.0e7, "true")
	_run_until(b, b.time + 0.1)
	t.eq(Fixture.events_of(b, "throw_start").size(), n0 + 1, "10 stacks + more → hurls the weapon at the next quarry")
	_run_until(b, b.time + 2.0)
	t.ok(g.pos.distance_to(b.units[2].pos) < 1.4, "across the field (unlimited range)")


func test_triumph_and_flame_banner_buff(t: TestCtx) -> void:
	# 2 星的精英被 1 星的她击杀：触发数值 = 10 × 2 × 2 = 40 → +40% 攻击力与攻速；身边的队友 +10%，敌人不受影响
	var b := Fixture.make([{"def": "node_gladiator", "pos": Vector2(0, 0), "weapon": "flame_banner"}, {"def": "test_dummy", "pos": Vector2(2, 0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 2), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(-2, 1)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(-2, 3)}])
	var g: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var elite: BUnit = b.units[2]
	var foe: BUnit = b.units[3]
	_no_crit(g)
	b.start()
	elite.meta["elite"] = true
	var a0: float = g.get_stats().attack_power
	var s0: float = g.get_stats().attack_speed_multiplier
	var aa0: float = ally.get_stats().attack_power
	var fa0: float = foe.get_stats().attack_power
	b.pipeline.fx.damage(g, elite, 1.0e7, "true")
	var v: float = _ratio("node_gladiator_triumph", 1) * 2.0 * 2.0
	t.near(g.get_stats().attack_power / a0, 1.0 + v * 0.01, 0.001, "attack +%d%%" % int(v))
	t.near(g.get_stats().attack_speed_multiplier / s0, 1.0 + v * 0.01, 0.001, "attack speed +%d%%" % int(v))
	t.near(ally.get_stats().attack_power / aa0, 1.0 + v * 0.01 * 0.25, 0.001, "teammate in the splash: a quarter")
	t.near(foe.get_stats().attack_power, fa0, 0.001, "enemies are never buffed")
	# 冷却 5 秒后再击杀：累加
	_run_until(b, b.time + 5.2)
	b.pipeline.fx.damage(g, b.units[4], 1.0e7, "true")
	t.near(g.get_stats().attack_power / a0, 1.0 + v * 0.01 + _ratio("node_gladiator_triumph", 1) * 0.01, 0.001, "a second kill adds on top (permanent)")


func test_run_flag_follows_the_gladiator_on_the_board(t: TestCtx) -> void:
	var r := Run.create(Fixture.catalog(), 5)
	t.ok(not r.inventory.has("hunt_flag"), "no flag at first")
	var a: Dictionary = r.add_unit("node_gladiator", 1, null, 0)
	var b2: Dictionary = r.add_unit("node_gladiator", 1, null, 1)
	r.level = 9
	t.ok(r.move_unit(str(a["id"]), {"cell": Vector2i(11, 7)})["ok"], "deploy one")
	t.eq(r.inventory.count("hunt_flag"), 1, "deployed → a flag in the armory")
	r.move_unit(str(b2["id"]), {"cell": Vector2i(13, 7)})
	t.eq(r.inventory.count("hunt_flag"), 1, "two of them still share one flag")
	t.eq(r.equip(str(a["id"]), "hunt_flag")["reason"], "ui.err.not_wearable", "the flag can't be worn")
	t.eq(r.salvage("hunt_flag")["reason"], "ui.err.not_wearable", "nor salvaged")
	r.phase = "map"
	r.travel()
	t.eq(r.phase, "prepare", "preparing for node 1")
	t.ok(r.set_hunt_mark(0)["ok"], "mark the first enemy")
	t.ok(r.inventory.has("hunt_flag"), "the flag returns to the armory")
	var setup: Dictionary = r.build_battle_setup()
	var marked := 0
	for e: Dictionary in setup["units"]:
		if e.has("hunt_marked_by"):
			marked += 1
			t.eq(int(e["hunt_marked_by"]), GC.TEAM_PLAYER, "marked by the player's side")
	t.eq(marked, 1, "exactly one marked enemy in the battle setup")
	r.move_unit(str(a["id"]), {"bench": 5})
	r.move_unit(str(b2["id"]), {"bench": 6})
	t.ok(not r.inventory.has("hunt_flag"), "both off the board → the flag is gone")
	t.eq(r.hunt_mark, -1, "and so is the mark")
