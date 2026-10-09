extends RefCounted
## 变奏节点：表里之间(战斗外切换恶魔 / 天使形态——部门、被动 2、形态加成不同；每场一次阵亡时回满并换形态)、
## 被动 2(魔) 悲怆(开局及每 3 秒所有敌人 +1 层【沮丧】，敌人阵亡 +2 层；每层持续魔法伤害、攻速与计时器变慢)、
## 被动 2(天) 热情(所有友军【亢奋】：每层持续治疗、攻速与计时器变快)、触发器 下一乐章(想加层但已经叠满 → 对自己触发)；
## 专武黑键 / 白键(【永恒】【叠加 20】：本场没阵亡过的友军 → 立刻击杀，并给 每 n 点触发数值 1 层【渐强】，跨战斗保留)。


func _def() -> UnitDef:
	return Fixture.catalog().get_unit("node_pianist")


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


func _ap_k(u: BUnit) -> float:
	return 1.0 + maxf(0.0, u.get_stats().ability_power) / 100.0


func test_unit_data_and_forms(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = _def()
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model, d.form], [4, "cyan", "research", "caster", "focus", "pianist", "demon"],
		"rarity 4, cyan, starts as a Research demon, caster, focus, pianist model")
	t.eq(d.weapon_classes, ["focus"] as Array[String], "can't equip anything else")
	var ang: UnitDef = d.form_def("angel")
	t.eq([ang.id, ang.form, ang.profession_id, ang.model], ["node_pianist", "angel", "welfare", "pianist_angel"], "angel form: Welfare, angel body")
	t.ok(ang.triggers == d.triggers and ang.form_def("demon") == d, "same triggers; switching back gives the same def")
	t.eq([str(d.weapon_models.get("black_keys", "")), str(ang.weapon_models.get("black_keys", "")), str(ang.weapon_names.get("black_keys", ""))],
		["grand", "grand_white", "white_keys"], "her own piano is a grand (black / white) and is called White Keys as an angel")
	var e: EquipmentDef = cat.get_equipment("black_keys")
	t.eq([e.class_id, e.color_id, e.cost, e.owner, e.model], ["focus", "cyan", 4, "node_pianist", "piano"], "Black Keys: focus, cyan, 4, hers, a small piano for others")
	t.ok(e.abilities[0].cooldown == 5.0 and e.abilities[0].keyword_value("stacking", 1) == 20 and e.abilities[0].has_keyword("eternal"),
		"5 s cooldown 【Eternal】【Stacking 20】")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_form_button_in_run(t: TestCtx) -> void:
	var r := Run.create(Fixture.catalog(), 9)
	r.travel()
	var u: Dictionary = r.add_unit("node_pianist", 1, null, r.free_bench_slot())
	var first: String = str(r.board_units()[0]["id"])
	var spot: Vector2i = r.roster[first]["cell"]
	r.sell(first)
	r.move_unit(str(u["id"]), {"cell": spot})
	var rid: String = str(u["id"])
	t.eq(r.form_buttons(), {rid: "demon"}, "on the board: a button, she's a demon")
	var profs := func() -> Array:
		var out: Array = []
		for d: UnitDef in r.trait_defs():
			if d.id == "node_pianist":
				out.append(d.profession_id)
		return out
	t.eq(profs.call(), ["research"], "counts toward Research")
	t.ok(r.toggle_form(rid)["ok"], "press it")
	t.eq(r.form_buttons(), {rid: "angel"}, "now an angel")
	t.eq(profs.call(), ["welfare"], "counts toward Welfare instead")
	var mine: Array = (r.build_battle_setup()["units"] as Array).filter(func(e: Dictionary) -> bool: return str(e.get("roster_id", "")) == rid)
	t.eq(str(mine[0]["form"]), "angel", "the next battle's setup carries the form")
	r.toggle_form(rid)
	t.eq(r.form_buttons(), {rid: "demon"}, "and back")


func test_demon_grief(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_pianist", "pos": Vector2(0, -4)}, {"def": "test_dummy", "team": 1, "pos": Vector2(-2, 4)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(2, 4)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var p: BUnit = b.units[0]
	b.start()
	_calm(p)
	t.ok(p.get_status("form_demon") != null, "demon form bonus")
	t.near(p.get_stats().damage_dealt_pct, float(_def().passive_by_id("node_pianist_form").effect_config["forms"]["demon"]["stats_by_star"]["damage_dealt_pct"]["flat"]["1"]), 0.001,
		"+damage")
	for i in [1, 2, 3]:
		t.eq(b.units[i].status_stacks("despair"), 1, "every enemy starts with 1 Despair")
	_run(b, GC.START_DELAY + 3.05)
	t.eq(b.units[1].status_stacks("despair"), 2, "+1 every 3 s")
	var y: float = _trig("node_pianist_grief").flat_for(1)
	var hp0: float = b.units[2].hp
	_run(b, b.time + 1.0)
	t.near(hp0 - b.units[2].hp, 2.0 * y * _ap_k(p) * (1.0 + p.get_stats().damage_dealt_pct), 1.0,
		"each stack deals %.0f × (100 + AP)%% magic a second (her demon damage bonus counts)" % y)
	var asl: float = absf(float(_DES_AS()))
	t.near(b.units[1].get_stats().attack_speed_multiplier, 1.0 - 2.0 * asl, 0.001, "and slows attack speed by stacks × %.0f%%" % (asl * 100.0))
	t.near(b.units[1].get_stats().haste, -2.0 * asl, 0.001, "and its timers")
	b.units[3].hp = 0.0
	b.pipeline.fx.try_kill(b.units[3], null)
	t.eq(b.units[1].status_stacks("despair"), 4, "an enemy falls: every enemy +2 at once")
	for i in range(10):
		b.pipeline.emit("OnEnemyUnitDied", p, null, 0.0, ["enemy_unit_died"], {})
	t.eq(b.units[1].status_stacks("despair"), 9, "capped at 【Stacking 9】")
	t.eq(p.status_stacks("elation"), 0, "no Elation for a demon")


func _DES_AS() -> float:
	return float(_def().passive_by_id("node_pianist_grief").effect_config["status"]["stats_by_star"]["attack_speed_multiplier"]["flat"]["1"])


func test_angel_passion(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_pianist", "pos": Vector2(0, -4), "form": "angel"}, {"def": "test_hitter", "pos": Vector2(2, -4)},
		{"def": "test_hitter", "pos": Vector2(-2, -4)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var p: BUnit = b.units[0]
	b.start()
	_calm(p)
	t.eq([p.def.form, p.def.profession_id], ["angel", "welfare"], "the setup's form applies in battle")
	t.ok(p.get_status("form_angel") != null and p.get_status("form_demon") == null, "angel form bonus")
	for i in [0, 1, 2]:
		t.eq(b.units[i].status_stacks("elation"), 1, "every ally (her too) starts with 1 Elation")
	t.eq(b.units[3].status_stacks("despair"), 0, "no Despair for an angel")
	var h: BUnit = b.units[1]
	h.hp = 1000.0
	var y: float = _trig("node_pianist_passion").flat_for(1)
	var heal_k: float = 1.0 + p.get_stats().healing_done_pct
	_run(b, GC.START_DELAY + 1.0)
	t.ok(h.hp > 1000.0 + y * _ap_k(p) * heal_k * 0.9, "each stack heals %.0f × (100 + AP)%% a second (her healing bonus counts)" % y)
	var up: float = float(_def().passive_by_id("node_pianist_passion").effect_config["status"]["stats_by_star"]["attack_speed_multiplier"]["flat"]["1"])
	t.near(h.get_stats().attack_speed_multiplier, 1.0 + up, 0.001, "and speeds up attacks by %.1f%% a stack" % (up * 100.0))
	b.units[2].hp = 0.0
	b.pipeline.fx.try_kill(b.units[2], null)
	t.eq(h.status_stacks("elation"), 3, "an ally falls: every ally +2 at once")


func test_rebirth_switches_form_once(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_pianist", "pos": Vector2(0, -4)}, {"def": "test_hitter", "pos": Vector2(2, -4)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var p: BUnit = b.units[0]
	b.start()
	_calm(p)
	_run(b, GC.START_DELAY + 0.1)
	b.poll_events()
	b.pipeline.fx.damage(b.units[2], p, 1.0e6, "true", {"surface": "other"})
	var ev: Array[Dictionary] = _of(b.poll_events(), "pianist_flip")
	t.ok(p.alive and is_equal_approx(p.hp, p.get_stats().max_health), "first fall: back at full health")
	t.eq([p.def.form, ev.size()], ["angel", 1], "as an angel")
	t.ok(bool(p.meta.get("has_died", false)), "it still counts as having fallen this battle")
	t.ok(p.get_status("form_angel") != null and p.get_status("form_demon") == null, "the form bonus switches")
	_run(b, b.time + 3.1)
	t.ok(b.units[1].status_stacks("elation") >= 1, "and Passive 2 switches to Appassionata")
	b.pipeline.fx.damage(b.units[2], p, 1.0e6, "true", {"surface": "other"})
	t.ok(not p.alive, "only once per battle")


func test_next_movement_and_black_keys(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_pianist", "pos": Vector2(0, -4), "weapon": "black_keys", "roster_id": "p1"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var p: BUnit = b.units[0]
	b.start()
	_calm(p)
	_run(b, GC.START_DELAY + 0.1)
	var d: BUnit = b.units[1]
	var st: BStatus = d.get_status("despair")
	st.stacks = st.max_stacks
	b.poll_events()
	# 再加一层 → 已经叠满 → 下一乐章(触发数值 z × (100 + 法强)%)→ 黑键：她本场没阵亡过 → 击杀她 → 表里之间救回来、换形态；渐强 = 每 n 点 1 层
	b.pipeline.emit("OnEnemyUnitDied", p, null, 0.0, ["enemy_unit_died"], {})
	var evs: Array[Dictionary] = b.poll_events()
	var bk: Array[Dictionary] = _of(evs, "black_keys")
	t.eq(bk.size(), 1, "a capped stack → Next Movement → Black Keys")
	var z: float = _trig("node_pianist_next").flat_for(1)
	var n: float = float(Fixture.catalog().get_equipment("black_keys").abilities[0].effect_config["n"])
	var want: int = int(floor(z * _ap_k(p) / n))
	t.eq(p.status_stacks("crescendo"), want, "she gets %d Crescendo (%.0f × (100 + AP)%% / %.0f)" % [want, z, n])
	t.ok(p.alive and p.def.form == "angel", "she is killed and Between Front and Back brings her back as an angel")
	t.near(p.get_stats().haste, 0.03 * want, 0.001, "each Crescendo speeds her timers by 3%")
	# 冷却过了再来一次：她已经阵亡过了 → 什么都不做
	p.ability_cd.clear()
	b.pipeline.emit("OnStackCapped", p, d, 9.0, ["stack_capped"], {"status_id": "despair"})
	t.eq(_of(b.poll_events(), "black_keys").size(), 0, "she has fallen this battle: Black Keys does nothing")
	t.ok(p.alive, "and she lives")
	# 跨战斗：渐强是永恒状态
	b.pipeline.fx.damage(p, d, 1.0e9, "true", {"surface": "other"})
	_run(b, b.time + 0.5)
	t.eq(b.state, "ended", "battle over")
	var es: Array = b.eternal_out.get("p1", [])
	var kept: Array = es.filter(func(x: Dictionary) -> bool: return str(x["id"]) == "crescendo")
	t.ok(not kept.is_empty() and int(kept[0]["stacks"]) == want, "Crescendo is kept for the next battle")


func test_black_keys_kills_an_unfallen_ally(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_pianist", "pos": Vector2(0, -4), "weapon": "black_keys"}, {"def": "test_hitter", "pos": Vector2(2, -4)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var p: BUnit = b.units[0]
	b.start()
	_calm(p)
	var ab: AbilityDef = Fixture.catalog().get_equipment("black_keys").abilities[0]
	var h: BUnit = b.units[1]
	b.pipeline._black_keys(p, b.units[2], 600.0, ab, {"cfg": ab.effect_config})
	t.ok(b.units[2].alive, "enemies are left alone")
	b.pipeline._black_keys(p, h, 600.0, ab, {"cfg": ab.effect_config})
	t.ok(not h.alive, "an ally that hasn't fallen is killed outright")
	t.eq(h.status_stacks("crescendo"), 4, "after getting 600 / 150 = 4 Crescendo")


func test_negative_haste_slows_timers(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_pianist", "pos": Vector2(0, -4)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var p: BUnit = b.units[0]
	b.start()
	_calm(p)
	_run(b, GC.START_DELAY + 0.05)
	var d: BUnit = b.units[1]
	var st: BStatus = d.get_status("despair")
	st.stacks = 5
	d.mark_dirty()
	var hs: float = d.get_stats().haste
	t.ok(hs < 0.0, "Despair makes haste negative (%.2f)" % hs)
	# 一个每 4 帧的计时器：haste < 0 时一帧只走 1 + haste 格
	var tr := TriggerDef.from_dict({"id": "probe_tick", "timing": "OnBattleFrame", "event_count_threshold": 4, "tags": ["probe"], "target_rule": "self"})
	d.runtime_triggers.append(tr)
	for i in range(8):
		b.pipeline.emit("OnBattleFrame", d, null, 0.0, ["battle_frame"], {})
	t.near(float(d.counters.get("probe_tick", 0.0)), fmod(8.0 * (1.0 + hs), 4.0), 0.001, "8 frames move the timer %.1f steps instead of 8" % (8.0 * (1.0 + hs)))
