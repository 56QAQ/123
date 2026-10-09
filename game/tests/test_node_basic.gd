extends RefCounted
## 空白节点：摸鱼(战斗中不普攻、不移动；上场不占上阵人数)、拖后腿(每上阵一个，所有队友伤害增幅 / 伤害减免各 -10% × 空白节点数)、
## 能活下来就算成功(战斗结束时还活着才触发，触发数值 1/2/4)、专属武器打工小帮手(制造触发数值个白色晶球；隐藏的蓝 / 金 / 彩色概率)、开局送一份。


func _run_until(b: Battle, sec: float) -> void:
	while b.time < sec and b.state != "ended":
		b.step()


func test_unit_data(t: TestCtx) -> void:
	var d: UnitDef = Fixture.catalog().get_unit("node_basic")
	t.eq(d.cost, 0, "rarity 0")
	t.ok(not d.available_in_shop and not Fixture.catalog().shop_unit_ids().has("node_basic"), "never in the shop")
	t.eq(d.faction_id, "white", "white")
	t.eq(d.profession_id, "none", "no department")
	t.eq(d.weapon_classes, ["sword", "heavy", "dual", "rifle", "pistols", "crossbow", "focus"] as Array[String], "sword default; no polearm / bow")
	t.ok(d.free_deploy, "takes no deploy slot")
	t.near(d.base_stats.max_health, 380.0, 0.01, "caster template")
	var e: EquipmentDef = Fixture.catalog().get_equipment("work_helper")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["sword", "white", 1, "node_basic"], "Little Work Helper: sword, white, rarity 1, hers")
	t.ok(e.flat_mods.is_empty() and e.pct_mods.is_empty(), "no stat bonuses")
	t.ok(not Fixture.catalog().equipment_ids().has("work_helper"), "not in random sources (orbs / black market / workshop)")
	t.ok(e.can_equip_to(d) and not e.can_equip_to(Fixture.catalog().get_unit("node_archer")), "only white pieces can equip it")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_slacking_no_attack_no_move(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_basic", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.9)}])
	var nb: BUnit = b.units[0]
	b.start()
	_run_until(b, 6.0)
	t.near(nb.pos.distance_to(Vector2.ZERO), 0.0, 0.05, "never moves")
	t.eq(Fixture.events_of(b, "attack_start").size(), 0, "never attacks, even with an enemy right next to it")
	t.ok(nb.has_flag("slacker"), "slacking")


func test_dead_weight_scales_with_the_number_of_blank_nodes(t: TestCtx) -> void:
	for n: int in [1, 2, 3, 4]:
		var specs: Array = [{"def": "test_dummy", "pos": Vector2(0, -3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}]
		for i in range(n):
			specs.append({"def": "node_basic", "pos": Vector2(-3.0 + 1.5 * float(i), -5.0)})
		var b := Fixture.make(specs)
		b.start()
		var ally: BUnit = b.units[0]
		var foe: BUnit = b.units[1]
		var want: float = -0.1 * float(n * n)
		t.near(ally.get_stats().damage_dealt_pct, want, 0.0001, "%d blank node(s): teammates' damage bonus %d%%" % [n, int(want * 100)])
		t.near(ally.get_stats().damage_taken_pct, want, 0.0001, "%d blank node(s): teammates' damage reduction %d%%" % [n, int(want * 100)])
		t.near(foe.get_stats().damage_dealt_pct, 0.0, 0.0001, "enemies are not affected")
		t.near(b.units[2].get_stats().damage_taken_pct, -0.1 * float(n * (n - 1)), 0.0001, "a blank node gets the other blank nodes' share")
		if n == 1:
			var hp0: float = ally.hp
			b.pipeline.fx.damage(foe, ally, 100.0, "physical")
			t.near(hp0 - ally.hp, 110.0, 0.01, "1 blank node: a 100 hit lands for 110")
			t.eq(b.pipeline.fx.dispel(null, ally, "debuff", 5), 0, "Dead Weight can't be dispelled")
		if n == 4:
			var hp1: float = foe.hp
			b.pipeline.fx.damage(ally, foe, 100.0, "physical")
			t.near(hp1 - foe.hp, 0.0, 0.01, "4 blank nodes: teammates deal no damage at all (-160%)")


func test_surviving_makes_white_orbs_by_star(t: TestCtx) -> void:
	for star: int in [1, 2, 3]:
		var b := Fixture.make([{"def": "node_basic", "pos": Vector2(0, 0), "star": star, "weapon": "work_helper"},
			{"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}], 11)
		b.start()
		b.step()
		b._finish(GC.TEAM_PLAYER)
		var made := 0
		for d: Dictionary in b.drops:
			if str(d.get("made_by", "")) == "node_basic":
				made += 1
		t.eq(made, [1, 2, 4][star - 1], "%d★ survives → %d orb(s)" % [star, [1, 2, 4][star - 1]])
	# 倒下了就没有
	var b2 := Fixture.make([{"def": "node_basic", "pos": Vector2(0, 0), "weapon": "work_helper"}, {"def": "test_dummy", "pos": Vector2(2, 0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}])
	b2.start()
	b2.step()
	b2.pipeline.fx.damage(b2.units[2], b2.units[0], 1.0e6, "true")
	b2._finish(GC.TEAM_PLAYER)
	t.eq(b2.drops.size(), 0, "fallen → no orb")
	# 没拿小帮手：触发器没有配对，什么都不做
	var b3 := Fixture.make([{"def": "node_basic", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}])
	b3.start()
	b3.step()
	b3._finish(GC.TEAM_PLAYER)
	t.eq(b3.drops.size(), 0, "basic sword → nothing")


func test_hidden_orb_upgrade_odds(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_basic", "pos": Vector2(0, 0), "weapon": "work_helper"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}], 5)
	b.start()
	var cfg: Dictionary = Fixture.catalog().get_equipment("work_helper").abilities[0].effect_config
	b.pipeline.fx.create_orbs(b.units[0], b.units[0], 40000.0, cfg)
	var cnt := {"white": 0, "blue": 0, "gold": 0, "rainbow": 0}
	for d: Dictionary in b.drops:
		cnt[str(d["tier"])] = int(cnt.get(str(d["tier"]), 0)) + 1
	t.near(float(cnt["blue"]) / 40000.0, 0.05, 0.006, "≈5%% blue (%d)" % int(cnt["blue"]))
	t.near(float(cnt["gold"]) / 40000.0, 0.01, 0.003, "≈1%% gold (%d)" % int(cnt["gold"]))
	t.ok(int(cnt["rainbow"]) <= 60, "rainbow is very rare (%d of 40000, expected ≈20)" % int(cnt["rainbow"]))
	t.ok(Fixture.catalog().loot.get("orbs", {}).has("rainbow"), "rainbow orbs have a loot table")
	t.ok(not Loc.t("equipment.work_helper.desc").contains("%"), "the odds are not in the description")


func test_run_start_gift_and_free_slot(t: TestCtx) -> void:
	var r := Run.create(Fixture.catalog(), 5)
	var nb: Dictionary = {}
	for u: Dictionary in r.roster.values():
		if u["def"] == "node_basic":
			nb = u
	t.ok(not nb.is_empty(), "a Node Basic at the start")
	t.eq(nb.get("cell"), Vector2i(12, 11), "standing right behind the truck")
	t.eq(str(nb.get("weapon", "")), "work_helper", "holding the Little Work Helper")
	t.eq(r.board_count(), 2, "it takes no deploy slot (2 of 3 used)")
	r.add_unit("node_shielder", 1, null, r.free_bench_slot())
	var sid: String = str(r.bench_units()[0]["id"])
	t.ok(r.move_unit(sid, {"cell": Vector2i(12, 8)})["ok"], "a third piece still fits at level 3")
	r.add_unit("node_peasant", 1, null, r.free_bench_slot())
	var pid: String = str(r.bench_units()[0]["id"])
	t.eq(r.move_unit(pid, {"cell": Vector2i(9, 8)})["reason"], "ui.err.board_full", "a fourth doesn't")
	r.move_unit(str(nb["id"]), {"bench": 3})
	t.ok(r.move_unit(str(nb["id"]), {"cell": Vector2i(13, 11)})["ok"], "but Node Basic can always go back on a full board")
	t.eq(r.sell_value(nb), 0, "sells for 0 gold")
	nb["star"] = 2
	t.eq(r.sell_value(nb), 0, "never negative")
