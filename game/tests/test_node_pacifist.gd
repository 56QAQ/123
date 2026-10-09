extends RefCounted
## 共歌节点：温柔地(开局 10 秒所有单位受到的伤害最终降低 ★50/75/87.5%，不分敌我)、美妙地(【永恒】【叠加 20】替代普攻：给所有其他人各叠一层沉醉——
## 每层伤害减免 -x、伤害增幅 +x'，不可驱散、跨战斗持续)、善良地(每 5 秒，所有持有沉醉的目标，触发数值 y × 目标的沉醉层数)；
## 专武沉沦之梦(攻速；冷却 4 秒【群攻 10】【双模】队友伤害增幅效能 / 敌人伤害减免效能 + 每 n 点 1%)；新属性 伤害增幅效能 / 伤害减免效能。


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
	return Fixture.catalog().get_unit("node_pacifist")


func _st(stat: String, star: int) -> float:
	return float(_def().passive_by_id("node_pacifist_song").effect_config["status"]["stats_by_star"][stat]["flat"][str(star)])


func _calm(v: BUnit) -> void:
	v.attack_cd = 1.0e9
	v.base.move_speed = 0.0
	v.base.crit_chance = 0.0
	v.mark_dirty()


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = _def()
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model], [4, "red", "welfare", "tank", "sword", "pacifist"],
		"rarity 4, red, Welfare, tank, one-hand melee, pacifist model")
	t.eq(d.weapon_classes, ["sword", "heavy", "polearm"] as Array[String], "can equip heavy and two-handed long")
	t.near(d.base_stats.max_health, 2000.0, 0.01, "rarity-4 tank template")
	t.ok(d.normal_attack != null and d.normal_attack.effect_type == "none", "her normal attack itself does nothing (the song replaces it)")
	var song: AbilityDef = d.passive_by_id("node_pacifist_song")
	t.ok(song.has_keyword("eternal") and song.keyword_value("stacking", 1) == 20, "Beautifully 【Eternal】【Stacking 20】")
	var e: EquipmentDef = cat.get_equipment("sinking_dream")
	t.eq([e.class_id, e.color_id, e.cost, e.owner, e.model], ["sword", "red", 4, "node_pacifist", "mic"], "Sinking Dream: one-hand melee, red, rarity 4, hers")
	var ab: AbilityDef = e.abilities[0]
	t.eq([ab.ability_class, ab.keyword_value("multi_attack", 1), ab.cooldown], ["amulet", 10, 4.0], "4 s cooldown 【Multi-Attack 10】【Dual Mode】")
	t.ok(float(e.pct_mods.get("attack_speed_multiplier", 0.0)) > 0.0, "attack speed")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_gently_cuts_all_damage_for_ten_seconds(t: TestCtx) -> void:
	for star: int in [1, 3]:
		var b := Fixture.make([{"def": "node_pacifist", "pos": Vector2(0, -3), "star": star}, {"def": "test_dummy", "pos": Vector2(3, -3)},
			{"def": "test_dummy", "team": 1, "pos": Vector2(0, 8)}])
		var p: BUnit = b.units[0]
		var ally: BUnit = b.units[1]
		var foe: BUnit = b.units[2]
		_calm(p)
		b.start()
		_run(b, GC.START_DELAY + 1.0)
		var k: float = float(_def().passive_by_id("node_pacifist_gentle").effect_config["reduce_by_star"][str(star)])
		t.near(b.pipeline.fx.damage(foe, ally, 100.0, "true", {}), 100.0 * (1.0 - k), 0.01, "★%d ally takes %d%% less" % [star, int(round(k * 100.0))])
		t.near(b.pipeline.fx.damage(ally, foe, 100.0, "true", {}), 100.0 * (1.0 - k), 0.01, "★%d enemy too (friend or foe)" % star)
		_run(b, GC.START_DELAY + 10.1)
		t.near(b.pipeline.fx.damage(foe, ally, 100.0, "true", {}), 100.0, 0.01, "★%d after 10 s: back to normal" % star)


func test_song_enthralls_everyone_else(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_pacifist", "pos": Vector2(0, -0.6)}, {"def": "test_hitter", "pos": Vector2(3, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.6)}, {"def": "test_dummy", "team": 1, "pos": Vector2(6, 8)}])
	var p: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var far: BUnit = b.units[3]
	_calm(p)
	_calm(ally)
	var dr0: float = ally.get_stats().damage_taken_pct
	var amp0: float = ally.get_stats().damage_dealt_pct
	b.pipeline.normal_attack(p, foe)
	t.eq(Fixture.events_of(b, "damage").size(), 0, "her normal attack deals no damage")
	for u: BUnit in [ally, foe, far]:
		t.eq(u.status_stacks("intox"), 1, "%s: 1 stack of Enthralled (friend or foe, near or far)" % u.def.id)
	t.eq(p.status_stacks("intox"), 0, "not herself")
	t.near(ally.get_stats().damage_taken_pct - dr0, _st("damage_taken_pct", 1), 0.0001, "damage reduction -%d%% per stack" % int(round(-_st("damage_taken_pct", 1) * 100.0)))
	t.ok(_st("damage_taken_pct", 1) < 0.0, "(stored as negative damage reduction)")
	t.near(ally.get_stats().damage_dealt_pct - amp0, _st("damage_dealt_pct", 1), 0.0001, "damage amplification +%d%% per stack" % int(round(_st("damage_dealt_pct", 1) * 100.0)))
	var st: BStatus = foe.get_status("intox")
	t.ok(st.eternal and st.flags.has("no_dispel"), "eternal, can't be dispelled")
	for i in range(30):
		b.pipeline.normal_attack(p, foe)
	t.eq(foe.status_stacks("intox"), 20, "【Stacking 20】")


func test_efficacy_stats_scale_amp_and_reduction(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1)}])
	var a: BUnit = b.units[0]
	var d: BUnit = b.units[1]
	b.pipeline.fx.apply_status(a, a, {"status_id": "amp", "flags": ["buff"], "stats": {"damage_dealt_pct": {"flat": 0.4}, "amp_efficacy": {"flat": 0.5}}})
	t.near(b.pipeline.fx.damage(a, d, 100.0, "true", {}), 100.0 * (1.0 + 0.4 * 1.5), 0.01, "+40% amp × (1 + 50% efficacy) = +60%")
	b.pipeline.fx.apply_status(a, d, {"status_id": "neg_dr", "flags": ["debuff"], "stats": {"damage_taken_pct": {"flat": -0.2}, "dr_efficacy": {"flat": 0.5}}})
	t.near(b.pipeline.fx.damage(a, d, 100.0, "physical", {}), 100.0 * 1.6 * 1.3, 0.01, "-20% damage reduction × 1.5 efficacy = takes 30% more")


func test_kindly_and_sinking_dream(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_pacifist", "pos": Vector2(0, -3), "weapon": "sinking_dream"}, {"def": "test_hitter", "pos": Vector2(3, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 8)}, {"def": "test_dummy", "team": 1, "pos": Vector2(4, 8)}])
	var p: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var bare: BUnit = b.units[3]
	_calm(p)
	_calm(ally)
	b.start()
	_run(b, GC.START_DELAY + 0.5)
	var cfg: Dictionary = _def().passive_by_id("node_pacifist_song").effect_config["status"].duplicate(true)
	cfg["max_stacks"] = 20
	cfg["add_stacks"] = 6
	b.pipeline.fx.apply_status(p, ally, cfg)
	cfg["add_stacks"] = 10
	b.pipeline.fx.apply_status(p, foe, cfg)
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 5.3)
	var y: float = 0.0
	for tr: TriggerDef in _def().triggers:
		if tr.id == "node_pacifist_kind":
			y = tr.ratio_for(1)
	var n: float = 0.01 / float(Fixture.catalog().get_equipment("sinking_dream").abilities[0].effect_config["ally_effect"]["cfg"]["amount_flat_stats"]["amp_efficacy"])
	t.near(ally.get_stats().amp_efficacy, 6.0 * y / n / 100.0, 0.0001, "teammate (6 stacks): damage amp efficacy + %.0f%%" % (6.0 * y / n))
	t.near(foe.get_stats().dr_efficacy, 10.0 * y / n / 100.0, 0.0001, "enemy (10 stacks): damage reduction efficacy + %.0f%% (per-target trigger value)" % (10.0 * y / n))
	t.near(bare.get_stats().dr_efficacy, 0.0, 0.0001, "no Enthralled: not a target")
	t.ok(ally.get_status("dream_amp") != null and ally.get_status("dream_amp").expires_at > b.time, "a timed status (refreshed every 5 s)")


func test_enthralled_carries_over_between_battles(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_pacifist", "pos": Vector2(0, -0.6)}, {"def": "test_hitter", "pos": Vector2(3, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.6)}])
	var p: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	ally.roster_id = "r_ally"
	for i in range(5):
		b.pipeline.normal_attack(p, b.units[2])
	b._finish(GC.TEAM_PLAYER)
	var saved: Array = b.eternal_out.get("r_ally", [])
	t.eq(saved.size(), 1, "the teammate's Enthralled is written out")
	t.eq(int((saved[0] as Dictionary)["stacks"]), 5, "with its 5 stacks")
	var b2 := Battle.new(Fixture.catalog(), 3)
	b2.setup({"units": [{"def": "test_hitter", "team": 0, "pos": Vector2(0, 0), "eternal": saved}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 5)}],
		"map": {"truck": false}, "cfg": {}})
	var a2: BUnit = b2.units[0]
	t.eq(a2.status_stacks("intox"), 5, "next battle: back on with 5 stacks")
	t.near(a2.get_stats().damage_dealt_pct, 5.0 * _st("damage_dealt_pct", 1), 0.0001, "and its stats")
	var m: Array = Run.merge_eternal([{"id": "intox", "stacks": 3}], [{"id": "intox", "stacks": 7}, {"id": "x", "stacks": 1}])
	t.eq(m.size(), 2, "star-up merge keeps every eternal status")
	for es: Dictionary in m:
		if es["id"] == "intox":
			t.eq(int(es["stacks"]), 7, "the bigger stack wins")


func test_enthralled_round_trip_through_the_run(t: TestCtx) -> void:
	# 花名册 → 战斗配置 → 战斗结束写回 → 下一场配置：沉醉一路带过去
	var r := Run.create(Fixture.catalog(), 5)
	r.travel()
	var board: Array[Dictionary] = r.board_units()
	t.ok(not board.is_empty(), "there is a deployed unit")
	var rid: String = str(board[0]["id"])
	var b := Battle.new(Fixture.catalog(), 1)
	b.setup(r.build_battle_setup())
	var mine: BUnit = null
	for u: BUnit in b.units:
		if u.roster_id == rid:
			mine = u
	var cfg: Dictionary = _def().passive_by_id("node_pacifist_song").effect_config["status"].duplicate(true)
	cfg["max_stacks"] = 20
	cfg["add_stacks"] = 4
	cfg["eternal"] = true
	b.pipeline.fx.apply_status(mine, mine, cfg)
	b.winner = GC.TEAM_PLAYER
	b._finish(GC.TEAM_PLAYER)
	r.begin_battle()
	r.finish_battle(b)
	t.eq((r.roster[rid].get("eternal", []) as Array).size(), 1, "written back to the roster")
	var setup: Dictionary = r.build_battle_setup()
	var carried := 0
	for ue: Dictionary in setup["units"]:
		if str(ue.get("roster_id", "")) == rid:
			for es: Dictionary in ue.get("eternal", []):
				carried = int(es["stacks"])
	t.eq(carried, 4, "and handed to the next battle")


func test_texts_match_data(t: TestCtx) -> void:
	var pc := func(d: Dictionary, neg: bool) -> String:
		var f := func(v: float) -> String:
			return Describe.fmt(absf(v) * 100.0) + "%"
		return "{★%s/%s/%s}" % [f.call(float(d["1"])), f.call(float(d["2"])), f.call(float(d["3"]))]
	var song: Dictionary = _def().passive_by_id("node_pacifist_song").effect_config["status"]["stats_by_star"]
	var sdr: String = pc.call(song["damage_taken_pct"]["flat"], true)
	var samp: String = pc.call(song["damage_dealt_pct"]["flat"], false)
	var sk: String = pc.call(_def().passive_by_id("node_pacifist_gentle").effect_config["reduce_by_star"], false)
	var y: TriggerDef = null
	for tr: TriggerDef in _def().triggers:
		if tr.id == "node_pacifist_kind":
			y = tr
	var sy := "{★%s/%s/%s}" % [Describe.fmt(y.ratio_for(1)), Describe.fmt(y.ratio_for(2)), Describe.fmt(y.ratio_for(3))]
	for lang: String in ["zh", "en"]:
		t.ok(Loc.t_in(lang, "unit.node_pacifist.passive.node_pacifist_gentle").contains(sk), "%s: gently %s" % [lang, sk])
		var s2: String = Loc.t_in(lang, "unit.node_pacifist.passive.node_pacifist_song")
		t.ok(s2.contains(sdr) and s2.contains(samp), "%s: enthralled %s / %s" % [lang, sdr, samp])
		t.ok(Loc.t_in(lang, "unit.node_pacifist.trigger.node_pacifist_kind").contains(sy), "%s: kindly %s" % [lang, sy])
