extends RefCounted
## 心音节点：纤心的乐奏(【吟唱 4】【双模】【演奏】：开战及每 4 秒演奏一段；效果在吟唱开始时施加并维持；结束时按吟唱秒数治疗 / 伤害演奏对象)、
## 演奏的七种效果(加攻 / 法强、燃烧、寒气 → 冻结、再生、击退 + 减速、减疗、削甲；同一种不连用)、不绝的回响(2 星：阵亡时维持的效果永久)、
## 艺术性批判(吟唱开始时，目标 = 演奏对象)、专武无声琴(双模增伤 / 易伤，吟唱时翻倍)。


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


func _k(star: int) -> float:
	return float(((Fixture.catalog().get_unit("node_bard").triggers[0]).flat_by_star as Dictionary).get(star, 20.0))


func _pc(key: String, star: int) -> float:
	var pa: AbilityDef = Fixture.catalog().get_unit("node_bard").passives[0]
	var v: Variant = (pa.effect_config["performance"] as Dictionary)[key]
	return float((v as Dictionary)[str(star)]) if v is Dictionary else float(v)


func _bard_fight(extra: Array, star: int = 2, weapon: String = "") -> Battle:
	var specs: Array = [{"def": "node_bard", "pos": Vector2(0, -5), "star": star, "weapon": weapon}]
	specs.append_array(extra)
	return Fixture.make(specs)


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = cat.get_unit("node_bard")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model], [2, "yellow", "welfare", "caster", "bow", "bard"],
		"rarity 2, yellow, Welfare, caster, bow, bard model")
	t.eq(d.weapon_classes, ["bow", "focus"] as Array[String], "can equip bows and foci")
	var e: EquipmentDef = cat.get_equipment("silent_lute")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["bow", "yellow", 2, "node_bard"], "Silent Lute: bow, yellow, rarity 2, hers")
	t.near(float(e.flat_mods.get("ability_power", 0.0)), 20.0, 0.001, "+20 ability power")
	t.ok(GC.KEYWORDS.has("performance") and Loc.has_key("keyword_desc.performance"), "the Performance keyword is explained in the glossary")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_first_piece_buffs_the_carry_and_heals_it_at_the_end(t: TestCtx) -> void:
	var b := _bard_fight([{"def": "test_hitter", "pos": Vector2(1.5, -5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var bard: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	b.start()
	ally.hp = ally.get_stats().max_health * 0.85
	var evs: Array[Dictionary] = _run(b, 0.2)
	t.eq(bard.phase, "chant", "she starts performing at the start of battle")
	var ps: Array[Dictionary] = _of(evs, "perform_start")
	t.eq(ps.size(), 1, "one piece")
	t.eq(str(ps[0]["opt"]), "might", "first piece: boost the ally with the highest attack")
	t.eq(ps[0]["target"], ally, "…the hitter")
	t.near(ally.get_stats().attack_power, 100.0 * (1.0 + _pc("atk_pct", 2)), 0.5, "attack +%d%% applied right away" % int(_pc("atk_pct", 2) * 100.0))
	var hp0: float = ally.hp
	var evs2: Array[Dictionary] = _run(b, GC.START_DELAY + 4.1)
	t.near(ally.get_stats().attack_power, 100.0, 0.5, "…and gone when the piece ends")
	var healed := 0.0
	for h: Dictionary in _of(evs2, "heal"):
		if h["src"] == bard and h["dst"] == ally:
			healed += float(h["amount"])
	t.near(healed, 4.0 * _k(2), 2.0, "end of piece: 4 s × k × (100 + 0 AP)%% = %.0f heal (got %.0f)" % [4.0 * _k(2), healed])
	t.ok(ally.hp > hp0, "the ally was healed")
	var ps2: Array[Dictionary] = _of(evs2, "perform_start")
	t.ok(not ps2.is_empty() and str(ps2[0]["opt"]) != "might", "the next piece is a different effect (%s)" % (str(ps2[0]["opt"]) if not ps2.is_empty() else "none"))


func test_chill_stacks_each_second_and_freezes(t: TestCtx) -> void:
	for star: int in [1, 2]:
		var b := _bard_fight([{"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}], star)
		var bard: BUnit = b.units[0]
		var foe: BUnit = b.units[1]
		b.report._row(foe)["dealt"] = 500.0
		b.start()
		var evs: Array[Dictionary] = _run(b, 0.2)
		t.eq(str(_of(evs, "perform_start")[0]["opt"]), "chill", "%d★ no ally to boost: chill the top damage dealer" % star)
		t.eq(foe.status_count("chill"), star, "%d Chill(s) right away" % star)
		var frozen_at := -1.0
		while b.time < GC.START_DELAY + 3.9 and frozen_at < 0.0:
			for e: Dictionary in _step(b):
				if e.get("t") == "freeze":
					frozen_at = b.time - GC.START_DELAY
		if star == 1:
			t.eq(frozen_at, -1.0, "1★: 4 × 10% = 40% doesn't exceed 40%: no freeze on its own")
			t.eq(foe.status_count("chill"), 4, "4 Chills after 3 s")
			t.near(foe.get_stats().attack_speed_multiplier, 1.0 - 4.0 * GC.CHILL_AS, 0.001, "-40% attack speed (Chill is a fixed 10% each)")
		else:
			t.ok(frozen_at > 2.5 and frozen_at < 3.5, "2★: starts with 2, the 5th Chill (50%%) freezes it (at %.2f s)" % frozen_at)
			t.ok(foe.has_flag("frozen") and foe.is_stunned(), "Frozen = stunned")
			t.eq(foe.status_count("chill"), 0, "the Chills are consumed")
			t.near(foe.get_status("frozen").expires_at - b.time, 5.0, 0.1, "5 s")


func test_freeze_halves_each_time_and_ignores_elite_resistance(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "test_dummy", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 5)}])
	b.start()
	var u: BUnit = b.units[1]
	u.meta["elite"] = true
	_run(b, GC.START_DELAY + 0.1)
	b.pipeline.fx.freeze(b.units[0], u, 5.0)
	t.near(u.get_status("frozen").expires_at - b.time, 5.0, 0.01, "first freeze 5 s, even on an elite (not halved like a stun)")
	b.pipeline.fx.freeze(b.units[0], u, 5.0)
	t.near(u.get_status("frozen").expires_at - b.time, 7.5, 0.01, "frozen again while frozen: +2.5 s (halved, added on)")
	b.pipeline.fx.end_status(u, "frozen")
	b.pipeline.fx.freeze(b.units[0], u, 5.0)
	t.near(u.get_status("frozen").expires_at - b.time, 1.25, 0.01, "third freeze: 1.25 s")


func test_regen_on_the_weakest_ally(t: TestCtx) -> void:
	var b := _bard_fight([{"def": "test_hitter", "pos": Vector2(1.5, -5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var bard: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	b.start()
	_run(b, GC.START_DELAY + 3.9)
	ally.hp = ally.get_stats().max_health * 0.3
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 4.2)
	t.eq(str(_of(evs, "perform_start")[0]["opt"]), "regen", "an ally at 30%: the next piece is regeneration")
	_run(b, GC.START_DELAY + 7.1)
	t.eq(ally.status_count("regen"), 6, "2★: 3 Regenerations at once, then one more each second (6 after 3 s)")
	var hp0: float = ally.hp
	_run(b, b.time + 0.5)
	t.near(ally.hp - hp0, 6.0 * GC.REGEN_HPS * 0.5, 2.0, "each heals a fixed %d per second" % int(GC.REGEN_HPS))


func test_repel_the_melee_on_our_backline(t: TestCtx) -> void:
	var b := _bard_fight([{"def": "test_hitter", "team": 1, "pos": Vector2(0, -4.0)}])
	var bard: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	foe.base.move_speed = 0.0
	foe.mark_dirty()
	b.start()
	var evs: Array[Dictionary] = _run(b, 0.2)
	var ps: Array[Dictionary] = _of(evs, "perform_start")
	t.eq(str(ps[0]["opt"]), "repel", "an enemy melee right next to her: knock it back")
	t.eq(_of(evs, "knockback").size(), 1, "knocked back")
	_run(b, 0.6)
	t.ok(foe.pos.distance_to(bard.pos) > 2.5, "pushed away from the backline (%.2f m)" % foe.pos.distance_to(bard.pos))
	t.eq(foe.status_stacks("bard_slow"), 1, "and kept slowed")


func test_interrupt_pays_out_by_seconds_chanted(t: TestCtx) -> void:
	var b := _bard_fight([{"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}], 1)
	var bard: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	b.report._row(foe)["dealt"] = 500.0
	b.start()
	_run(b, GC.START_DELAY + 2.1)
	t.eq(foe.status_count("chill"), 3, "chilling (3 so far)")
	var hp0: float = foe.hp
	var chanted: float = b.time - GC.START_DELAY
	b.pipeline.fx.apply_status(foe, bard, {"status_id": "stun", "duration": 1.0, "flags": ["debuff", "stun"]})
	var evs: Array[Dictionary] = _run(b, b.time + 0.1)
	t.eq(_of(evs, "interrupt").size(), 1, "interrupted")
	t.eq(foe.status_count("chill"), 0, "the sustained Chills end with the piece")
	t.near(hp0 - foe.hp, chanted * _k(1), 3.0, "paid out for the %.1f s chanted: %.0f magic damage (got %.0f)" % [chanted, chanted * _k(1), hp0 - foe.hp])
	var evs2: Array[Dictionary] = _run(b, b.time + 2.0)
	t.ok(not _of(evs2, "perform_start").is_empty(), "once she can act again she starts a new piece")


func test_endless_echo_makes_the_piece_permanent(t: TestCtx) -> void:
	var b := _bard_fight([{"def": "test_hitter", "pos": Vector2(1.5, -5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}], 2)
	var bard: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	b.report._row(foe)["dealt"] = 500.0
	bard.meta["perf_last"] = "might"
	b.start()
	_run(b, GC.START_DELAY + 1.1)
	t.eq(foe.status_count("chill"), 3, "chilling the enemy (2 at once + 1)")
	bard.meta["_doomed"] = true
	bard.hp = 0.0
	b.pipeline.fx.try_kill(bard, null)
	var evs: Array[Dictionary] = _run(b, b.time + 6.0)
	t.eq(_of(evs, "perform_echo").size(), 1, "Endless Echo")
	t.eq(foe.status_count("chill"), 3, "the Chills never wear off")
	t.ok(ally.status_stacks("bard_might_atk") > 0 and ally.get_status("bard_might_atk").expires_at < 0.0,
		"the piece had no attack boost: the carry gets a permanent one")


func test_critique_and_silent_lute_double_while_chanting(t: TestCtx) -> void:
	var b := _bard_fight([{"def": "test_hitter", "pos": Vector2(1.5, -5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}], 2, "silent_lute")
	var bard: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	b.start()
	_run(b, 0.2)
	t.eq(ally.status_stacks("lute_rapture"), 1, "Artistic Critique → Silent Lute on the piece's target (ally): Resonance")
	t.near(ally.get_stats().damage_dealt_pct, 0.12, 0.001, "she's chanting: 6% doubled to 12%")
	b.report._row(foe)["dealt"] = 500.0
	_run(b, GC.START_DELAY + 4.2)
	t.eq(foe.status_stacks("lute_dissonance"), 0, "6 s cooldown: not yet on the next piece")
	_run(b, GC.START_DELAY + 8.2)
	t.ok(foe.status_stacks("lute_dissonance") == 1 or ally.status_stacks("lute_rapture") == 1, "after the cooldown it lands on the next piece's target")
	if foe.status_stacks("lute_dissonance") == 1:
		t.near(foe.get_stats().damage_taken_pct, -0.12, 0.001, "on an enemy: -12% damage reduction")
	# 普通的弓手：拉满弦 = 吟唱
	bard.phase = "draw"
	t.ok(b.pipeline.is_chanting(bard), "drawing a bow counts as chanting")
	bard.phase = "idle"
	t.ok(b.pipeline.is_chanting(bard, {"ev_meta": {"chant_scale": 1.6}}), "so does a hit from a drawn shot")
	t.ok(not b.pipeline.is_chanting(bard, {"ev_meta": {"chant_scale": 1.0}}), "an undrawn one doesn't")


func test_critique_never_hurts_allies(t: TestCtx) -> void:
	var b := _bard_fight([{"def": "test_hitter", "pos": Vector2(1.5, -5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}], 2, "spell_notes")
	var ally: BUnit = b.units[1]
	b.start()
	var evs: Array[Dictionary] = _run(b, 0.3)
	t.eq(str(_of(evs, "perform_start")[0]["target"].def.id), "test_hitter", "the piece targets the ally")
	var hurt := 0.0
	for e: Dictionary in _of(evs, "damage"):
		if e["dst"] == ally:
			hurt += float(e["amount"])
	t.near(hurt, 0.0, 0.01, "a damage weapon on Artistic Critique doesn't hit the ally")
