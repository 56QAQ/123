extends RefCounted
## 重构版求知节点：学力增长中(【永恒】战后永久法术强度 = 1 + 武器本场学习计数 × 1/1/2，倒下也算，合星取最高)、
## 知识轰炸(2 星：普攻转法术伤害、每点法术强度增伤)、把咒语念出来！(每 3 秒，触发数值 = x × (100 + 法术强度)%)、
## 专属武器咒语笔记(冷却 3 秒正好对齐触发器不被卡掉；【学习】；先给自己一个独立的【乱念的咒语】再造成伤害)。


func _make(star: int, weapon: String = "spell_notes", perm: Dictionary = {}) -> Battle:
	return Fixture.make([{"def": "node_student", "pos": Vector2.ZERO, "star": star, "weapon": weapon, "perm": perm},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 2.5)}])


func _recite(u: BUnit) -> TriggerDef:
	for tr: TriggerDef in u.def.triggers:
		if tr.id == "node_student_recite":
			return tr
	return null


func _casts(b: Battle) -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for e: Dictionary in Fixture.events_of(b, "damage"):
		if str(e.get("ability", "")) == "spell_notes_recite":
			r.append(e)
	return r


func _step_seconds(b: Battle, s: float) -> void:
	for i in range(int(round(s / GC.SIM_DT))):
		b.step()


func test_recite_every_3_s_is_never_blocked_by_the_3_s_cooldown(t: TestCtx) -> void:
	var b := _make(1)
	var u: BUnit = b.units[0]
	b.start()
	_step_seconds(b, GC.START_DELAY + 60.0)
	var expected: int = b.frames / 12
	t.eq(_casts(b).size(), expected, "one cast per 3 s trigger (%d frames)" % b.frames)
	t.eq(int(u.learning.get("spell_notes_recite", 0)), expected, "【学习】: one learning count per activation")


func test_trigger_value_is_x_times_100_plus_ability_power_pct(t: TestCtx) -> void:
	var b := _make(1, "spell_notes", {"ability_power": 12})
	var u: BUnit = b.units[0]
	t.near(u.get_stats().ability_power, 32.0, 0.001, "20 from the notes + 12 from Still Studying")
	var tr: TriggerDef = _recite(u)
	var x: float = tr.flat_for(1)
	t.near(b.pipeline.trigger_value(tr, {}, u, null), x * 1.32, 0.01, "x × (100 + 32)%")
	b.start()
	while _casts(b).is_empty() and b.time < 10.0:
		b.step()
	var c: Dictionary = _casts(b)[0]
	var y: float = Fixture.catalog().get_equipment("spell_notes").abilities[0].value_multiplier
	# 状态先于伤害：抽到"伤害增幅"时这一下就吃到
	var amp: float = 1.0 + u.get_stats().damage_dealt_pct
	t.eq(str(c["kind"]), "magic", "magic damage")
	t.near(float(c["amount"]), x * 1.32 * y * amp, 0.05, "damage = trigger value × y (0-MR dummy)")


func test_garbled_incantation_copies_are_independent(t: TestCtx) -> void:
	var b := _make(1)
	var u: BUnit = b.units[0]
	b.start()
	while _casts(b).size() < 2 and b.time < 20.0:
		b.step()
	var gs: Array[BStatus] = []
	for sid: String in u.statuses.keys():
		var st: BStatus = u.statuses[sid]
		if str(st.meta.get("base_id", "")) == "garbled_spell":
			gs.append(st)
	t.eq(gs.size(), 2, "two casts → two separate Garbled Incantations")
	gs.sort_custom(func(p: BStatus, q: BStatus) -> bool: return p.expires_at < q.expires_at)
	t.near(gs[1].expires_at - gs[0].expires_at, 3.0, 0.03, "each keeps its own 6 s timer (not refreshed)")
	t.ok(gs[0].has_flag("dispellable") and gs[0].has_flag("buff"), "a dispellable buff")
	var opts: Array = Fixture.catalog().get_equipment("spell_notes").abilities[0].effect_config["pre_effects"][0]["options"]
	for i in range(2):
		for o: Dictionary in opts:
			if str(o["tag"]) == str(gs[i].meta.get("variant", "")):
				t.near(float(gs[i].meta["variant_value"]), float(o["base"]) + float(o["per_learning"]) * float(i + 1), 0.0001,
					"strength follows the learning count at that cast (%d)" % (i + 1))
	# 同一种效果重复获得也不合并
	var cfg := {"status_id": "garbled_spell", "duration": 6.0, "independent": true, "stats": {"ability_power": {"flat": 5.0}}}
	var ap0: float = u.get_stats().ability_power
	b.pipeline.fx.apply_status(u, u, cfg)
	b.pipeline.fx.apply_status(u, u, cfg)
	t.near(u.get_stats().ability_power - ap0, 10.0, 0.001, "two identical copies both count, one stack each")
	_step_seconds(b, 6.1)
	for sid2: String in u.statuses.keys():
		t.ok(str((u.statuses[sid2] as BStatus).meta.get("base_id", "")) != "garbled_spell" or (u.statuses[sid2] as BStatus).expires_at > b.time,
			"expired copies are gone")


func _finish_battle(b: Battle) -> void:
	var guard := 0
	while b.state != "ended" and guard < 20000:
		b.step()
		guard += 1


func test_still_studying_grows_ability_power_after_the_battle_even_if_she_fell(t: TestCtx) -> void:
	for star: int in [1, 3]:
		var b := _make(star)
		var u: BUnit = b.units[0]
		b.start()
		_step_seconds(b, GC.START_DELAY + 10.0)
		var learned: int = int(u.learning.get("spell_notes_recite", 0))
		t.ok(learned >= 3, "learned %d times in 10 s" % learned)
		b.pipeline.fx.damage(b.units[1], u, 1.0e6, "true")
		t.ok(not u.alive, "she fell")
		_finish_battle(b)
		var key: String = u.roster_id if u.roster_id != "" else u.uid
		var g: float = float((b.growth.get(key, {}) as Dictionary).get("ability_power", 0.0))
		var mult: int = 2 if star == 3 else 1
		t.near(g, 1.0 + learned * mult, 0.001, "%d★: 1 + %d learning × %d" % [star, learned, mult])
	var b2 := _make(1, "basic_focus")
	b2.start()
	_step_seconds(b2, GC.START_DELAY + 7.0)
	b2.units[1].hp = 0.0
	b2.pipeline.fx.damage(b2.units[0], b2.units[1], 1.0e6, "true")
	_finish_battle(b2)
	var k2: String = b2.units[0].roster_id if b2.units[0].roster_id != "" else b2.units[0].uid
	t.near(float((b2.growth.get(k2, {}) as Dictionary).get("ability_power", 0.0)), 1.0, 0.001, "a weapon without learning still gives the minimum 1")


func test_star_up_keeps_the_highest_growth_of_the_three(t: TestCtx) -> void:
	var r := Run.create(Fixture.catalog(), 5)
	var aps := [5.0, 12.0, 8.0]
	for i in range(3):
		var e: Dictionary = r.add_unit("node_student", 1, null, i)
		e["perm"] = {"ability_power": aps[i]}
	r._merge_all()
	var n := 0
	for u: Dictionary in r.roster.values():
		if u["def"] == "node_student":
			n += 1
			t.eq(int(u["star"]), 2, "merged to 2★")
			t.near(float((u["perm"] as Dictionary).get("ability_power", 0.0)), 12.0, 0.001, "keeps the highest (12)")
	t.eq(n, 1, "one student left")


func test_knowledge_bombardment_from_two_stars(t: TestCtx) -> void:
	var b1 := _make(1)
	b1.start()
	t.ok(not b1.units[0].has_flag("na_magic"), "1★: passive 2 locked")
	var b := _make(2)
	var u: BUnit = b.units[0]
	b.start()
	t.ok(u.has_flag("na_magic"), "2★: normal attacks deal magic damage")
	u.base.crit_chance = 0.0
	u.mark_dirty()
	var st: StatBlock = u.get_stats()
	t.near(st.na_damage_per_ap_pct, 0.01, 0.00001, "2★: +1% per ability power")
	var n0: int = Fixture.events_of(b, "damage", "normal_attack").size()
	b.pipeline.normal_attack(u, b.units[1])
	var d: Array[Dictionary] = Fixture.events_of(b, "damage", "normal_attack")
	t.eq(d.size() - n0, 1, "one hit")
	t.eq(str(d[-1]["kind"]), "magic", "magic")
	t.near(float(d[-1]["amount"]), st.attack_power * (1.0 + 0.01 * st.ability_power), 0.05, "attack × (1 + 1% × ability power)")


func test_spell_notes_stats(t: TestCtx) -> void:
	var e: EquipmentDef = Fixture.catalog().get_equipment("spell_notes")
	t.eq(e.class_id, "focus", "focus")
	t.eq(e.color_id, "blue", "blue")
	t.near(float(e.flat_mods.get("ability_power", 0.0)), 20.0, 0.001, "+20 ability power")
	t.near(e.abilities[0].cooldown, 3.0, 0.0001, "3 s cooldown")
	t.ok(e.abilities[0].has_keyword("learning"), "【学习】")
	var ud: UnitDef = Fixture.catalog().get_unit("node_student")
	t.eq(ud.base_weapon_class, "focus", "default weapon: focus")
	t.eq(ud.weapon_classes, ["focus", "rifle"] as Array[String], "focus, and two-handed ranged (2026-10-09)")
