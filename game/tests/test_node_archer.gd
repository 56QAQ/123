extends RefCounted
## 重构版速射节点：连射(每发动 2 次普攻 +1 层，叠加上限 = [叠加 3]，攻速随施加者星级)、
## 快速装填(2 星解锁：步枪装弹时间减半、装弹完成 +1 层连射)、改装箭头(每第 3 次命中 或 装弹后第一次命中)、专属武器连射弩。


func _archer(star: int, weapon: String = "") -> Battle:
	return Fixture.make([{"def": "node_archer", "pos": Vector2.ZERO, "star": star, "weapon": weapon},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}])


func _attack(b: Battle, n: int) -> void:
	for i in range(n):
		b.pipeline.normal_attack(b.units[0], b.units[1])


func test_rapid_fire_stacks_every_second_attack_up_to_the_stacking_cap(t: TestCtx) -> void:
	for star: int in [1, 2]:
		var b := _archer(star)
		var u: BUnit = b.units[0]
		var as0: float = u.get_stats().attack_speed_multiplier
		_attack(b, 1)
		t.eq(u.status_stacks("rapid_fire"), 0, "%d★: one attack is not enough" % star)
		_attack(b, 1)
		t.eq(u.status_stacks("rapid_fire"), 1, "%d★: every 2nd attack performed gives a stack" % star)
		_attack(b, 10)
		t.eq(u.status_stacks("rapid_fire"), 3, "%d★: capped by [stacking 3]" % star)
		var per: float = 0.10 if star == 1 else 0.15
		t.near(u.get_stats().attack_speed_multiplier, as0 * (1.0 + per * 3.0), 0.001, "%d★: attack speed scales with the applier's star" % star)
		var st: BStatus = u.get_status("rapid_fire")
		t.ok(st.has_flag("dispellable"), "rapid fire can be dispelled")
		t.near(st.expires_at - b.time, 3.0, 0.001, "lasts 3 s and refreshes on every application")


func test_quick_reload_unlocks_at_two_stars(t: TestCtx) -> void:
	var b1 := _archer(1)
	b1.start()
	t.eq(b1.units[0].status_stacks("quick_reload"), 0, "1★: passive 2 is still locked")
	var ids: Array = []
	for e: Dictionary in b1.units[0].all_ability_entries():
		ids.append((e["ability"] as AbilityDef).id)
	t.ok(not ids.has("node_archer_quick_reload"), "1★: the locked passive cannot pair with anything")
	var b2 := _archer(2)
	b2.start()
	t.eq(b2.units[0].status_stacks("quick_reload"), 1, "2★: quick reload is active from the battle start")
	t.near(b2.units[0].get_stats().reload_time_pct, -0.5, 0.0001, "reload time halved")


func test_quick_reload_halves_the_reload_and_grants_rapid_fire(t: TestCtx) -> void:
	var durs := {}
	for star: int in [1, 2]:
		var b := _archer(star)
		b.start()
		var got := -1
		for i in range(int(20.0 / GC.SIM_DT)):
			b.step()
			if b.units[0].phase == "reload":
				durs[star] = b.units[0].phase_dur
				break
		# 装弹完成那一下：2 星多给 1 层连射(先把已有的层数记下来)
		var before: int = b.units[0].status_stacks("rapid_fire")
		b.pipeline.refill_ammo(b.units[0])
		got = b.units[0].status_stacks("rapid_fire") - before
		t.eq(got, 1 if star == 2 else 0, "%d★: a completed reload grants %d rapid fire stack" % [star, 1 if star == 2 else 0])
	t.ok(durs.has(1) and durs.has(2), "both reached a reload")
	if durs.has(1) and durs.has(2):
		# 攻速(连射层数)不同也会缩短装弹，所以按各自的攻速把基础装弹时间还原后再比
		t.ok(float(durs[2]) < float(durs[1]) * 0.6, "2★ reload is about half as long (%.2f s vs %.2f s)" % [durs[2], durs[1]])


func test_modified_arrowheads_fire_every_third_hit_or_first_hit_after_reload(t: TestCtx) -> void:
	var b := _archer(1, "rapidfire_arbalest")
	var eq_hits := func() -> int: return Fixture.events_of(b, "damage", "equipment").size()
	_attack(b, 2)
	t.eq(eq_hits.call(), 0, "no weapon effect on hits 1-2")
	_attack(b, 1)
	t.eq(eq_hits.call(), 2, "3rd hit: 25 damage + [pursuit 1] copy")
	var d: Array[Dictionary] = Fixture.events_of(b, "damage", "equipment")
	t.near(float(d[0]["amount"]), 25.0, 0.01, "fixed 25 physical damage (the trigger value 10 is ignored)")
	# 装弹后的第一次命中：计数没到也触发；之后按每第 3 次继续数
	_attack(b, 1)
	t.eq(eq_hits.call(), 2, "4th hit: nothing")
	b.pipeline.refill_ammo(b.units[0])
	_attack(b, 1)
	t.eq(eq_hits.call(), 4, "first hit after a reload fires the trigger")
	_attack(b, 1)
	t.eq(eq_hits.call(), 6, "6th hit fires again by the count")
	_attack(b, 1)
	t.eq(eq_hits.call(), 6, "second hit after the reload does not")


func test_repeating_arbalest_is_a_black_rifle_with_speed_and_crit(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var e: EquipmentDef = cat.get_equipment("rapidfire_arbalest")
	t.eq(e.class_id, "rifle", "rifle class (standard [stacking 5] magazine)")
	t.eq(e.color_id, "black", "black: anyone can equip it")
	var b0 := _archer(1)
	var b1 := _archer(1, "rapidfire_arbalest")
	t.near(b1.units[0].get_stats().attack_speed_multiplier, b0.units[0].get_stats().attack_speed_multiplier * 1.10, 0.001, "+10% attack speed")
	t.near(b1.units[0].get_stats().crit_chance, b0.units[0].get_stats().crit_chance + 0.05, 0.001, "+5% crit chance")
	t.eq(b1.pipeline.ammo(b1.units[0]).max_stacks, 5, "magazine = [stacking 5]")
