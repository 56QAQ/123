extends RefCounted
## 踏影节点：逆光(冷却 8 秒【充能 1】【叠加 3】：当前目标不是远程敌人 → 瞬移到威胁最高的远程敌人背后、索敌它、+1 层凝暗；
## 凝暗 = 除非已经是最后的合法目标否则敌人选不中他，每层背后攻击 +x% 增幅)、墨刃(2 星：每 5 秒魔法伤害)、
## 淬血(发动逆光时付生命、触发数值 = 流失的生命；没有武器效果就不触发、不掉血)、专武青影(诛影：普攻 / 技能伤害附带魔法持续伤害)。


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


func _cfg(key: String, star: int) -> float:
	var d: UnitDef = Fixture.catalog().get_unit("node_knight_errant")
	for pa: AbilityDef in d.passives:
		if pa.id == "node_ke_backlight" and key == "x":
			return float((((pa.effect_config["veil"] as Dictionary)["stats_by_star"] as Dictionary)["backstab_amp"] as Dictionary)["flat"][str(star)])
		if pa.id == "node_ke_temper" and key == "z":
			return float((pa.effect_config["ratio_by_star"] as Dictionary)[str(star)])
	for tr: TriggerDef in d.triggers:
		if tr.id == "node_ke_ink" and key == "y":
			return tr.ratio_for(star)
	return 0.0


func _still(u: BUnit) -> void:
	u.base.move_speed = 0.0
	u.mark_dirty()


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = cat.get_unit("node_knight_errant")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model], [3, "cyan", "information", "assassin", "sword", "knight_errant"],
		"rarity 3, cyan, Information, assassin, one-handed melee, knight_errant model")
	t.eq(d.weapon_classes, ["sword", "dual"] as Array[String], "can equip dual-wield melee")
	var e: EquipmentDef = cat.get_equipment("cyan_shadow")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["sword", "cyan", 3, "node_knight_errant"], "Cyan Shadow: one-handed melee, cyan, rarity 3, his")
	t.eq([float(e.flat_mods.get("attack_power", 0.0)), float(e.flat_mods.get("ability_power", 0.0))], [20.0, 30.0], "+20 attack, +30 AP")
	var ab: AbilityDef = e.abilities[0]
	t.eq([ab.cooldown, Pipeline.kw_value(null, ab, "charged"), Pipeline.kw_value(null, ab, "stacking")], [8.0, 1, 3], "8 s cooldown 【Charged 1】【Stacking 3】")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_backlight_teleports_behind_a_ranged_enemy(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_knight_errant", "pos": Vector2(0, -5)}, {"def": "test_hitter", "team": 1, "pos": Vector2(0, -2)},
		{"def": "node_archer", "team": 1, "pos": Vector2(3, 5)}])
	var k: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	var archer: BUnit = b.units[2]
	b.start()
	_still(foe)
	_still(archer)
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 0.3)
	var ss: Array[Dictionary] = _of(evs, "shadow_step")
	t.eq(ss.size(), 1, "starts with 1 charge: teleports at once (his target isn't ranged)")
	t.ok(not ss.is_empty() and ss[0]["target"] == archer, "to the ranged enemy")
	t.ok(Pipeline.is_behind(k, archer) and k.pos.distance_to(archer.pos) < 1.2, "right behind it")
	t.eq(k.target, archer, "and targets it")
	t.eq(k.status_stacks("shadow_veil"), 1, "+1 Gathered Dark")
	var st: BStatus = k.get_status("shadow_veil")
	t.ok(st != null and st.has_flag("dispellable"), "dispellable")
	t.near(k.get_stats().backstab_amp, _cfg("x", 1), 0.0001, "1★: +%d%% damage on attacks from behind per stack" % int(_cfg("x", 1) * 100.0))
	# 冷却 8 秒：目标换成近战也不会马上再瞬移
	k.target = foe
	var evs2: Array[Dictionary] = _run(b, GC.START_DELAY + 5.0)
	t.eq(_of(evs2, "shadow_step").size(), 0, "no charge left: no second teleport before the cooldown")


func test_gathered_dark_hides_him_unless_he_is_the_last_target(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_knight_errant", "pos": Vector2(0, 0)}, {"def": "test_dummy", "pos": Vector2(3, -2)},
		{"def": "test_hitter", "team": 1, "pos": Vector2(0, 1.3)}])
	var k: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	b.start()
	_still(k)
	_still(foe)
	b.pipeline.fx.apply_status(k, k, {"status_id": "shadow_veil", "max_stacks": 3, "flags": ["buff", "dispellable", "shadowed"]})
	foe.target = k
	_run(b, GC.START_DELAY + 1.0)
	t.ok(foe.target != k, "enemies can't target him while someone else is there")
	t.ok(b.ai.shadow_hidden(foe, k), "(hidden)")
	ally.hp = 0.0
	b.pipeline.fx.try_kill(ally, null)
	b.pipeline.drain()
	_run(b, b.time + 1.0)
	t.ok(not b.ai.shadow_hidden(foe, k), "the last legal target left: he can be targeted")
	t.eq(foe.target, k, "and is")


func test_attacks_from_behind_get_the_amp(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_knight_errant", "pos": Vector2(0, -1)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0)}])
	var k: BUnit = b.units[0]
	var d: BUnit = b.units[1]
	b.start()
	b.pipeline.fx.apply_status(k, k, {"status_id": "shadow_veil", "max_stacks": 3, "add_stacks": 2, "flags": ["buff", "dispellable", "shadowed"],
		"stats": {"backstab_amp": {"flat": 0.25}}})
	d.facing = PI                                     # 背对着他(面朝 -Z，他在 -Z 那边 = 前面)
	var h0: float = d.hp
	b.pipeline.fx.damage(k, d, 100.0, "true", {"surface": "normal_attack"})
	var front: float = h0 - d.hp
	d.facing = 0.0                                    # 面朝 +Z：他在背后
	var h1: float = d.hp
	b.pipeline.fx.damage(k, d, 100.0, "true", {"surface": "normal_attack"})
	t.near((h1 - d.hp) / front, 1.0 + 0.25 * float(k.status_stacks("shadow_veil")), 0.001,
		"from behind: +25%% per stack (%d stacks)" % k.status_stacks("shadow_veil"))
	var h2: float = d.hp
	b.pipeline.fx.damage(k, d, 100.0, "true", {"surface": "status", "cfg": {"damage_category": "dot"}})
	t.near(h2 - d.hp, front, 0.001, "damage over time doesn't count")


func test_ink_blade_every_five_seconds(t: TestCtx) -> void:
	for star: int in [1, 2]:
		var b := Fixture.make([{"def": "node_knight_errant", "pos": Vector2(0, -1), "star": star}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.2)}])
		var k: BUnit = b.units[0]
		b.start()
		var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 5.3)
		var ink: Array[Dictionary] = []
		for e: Dictionary in _of(evs, "damage"):
			if str(e.get("ability", "")) == "node_ke_ink":
				ink.append(e)
		if star == 1:
			t.eq(ink.size(), 0, "1★: no Ink Blade yet")
			continue
		t.eq(ink.size(), 1, "2★: once in 5 s")
		var st: StatBlock = k.get_stats()
		t.ok(not ink.is_empty() and str(ink[0]["kind"]) == "magic", "magic damage")
		t.ok(not ink.is_empty() and absf(float(ink[0]["amount"]) - _cfg("y", 2) * st.attack_power * (1.0 + st.ability_power / 100.0)) < 1.0,
			"%d%% × attack × (100 + AP)%%" % int(_cfg("y", 2) * 100.0))


func test_blood_temper_pays_health_for_cyan_shadow(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_knight_errant", "pos": Vector2(0, -5), "weapon": "cyan_shadow"}, {"def": "test_hitter", "team": 1, "pos": Vector2(0, -2)},
		{"def": "node_archer", "team": 1, "pos": Vector2(3, 5)}])
	var k: BUnit = b.units[0]
	var archer: BUnit = b.units[2]
	b.start()
	_still(b.units[1])
	_still(archer)
	archer.base.max_health = 100000.0
	archer.mark_dirty()
	archer.hp = 100000.0
	var st0: StatBlock = k.get_stats()
	var cost: float = _cfg("z", 1) * st0.attack_power * (1.0 + st0.ability_power / 100.0)
	var hp0: float = k.hp
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 0.3)
	t.eq(_of(evs, "shadow_step").size(), 1, "Backlight")
	var sc: Array[Dictionary] = _of(evs, "self_cost")
	t.ok(not sc.is_empty() and absf(float(sc[0]["amount"]) - cost) < 0.5, "Blood Temper: loses %d health (true DoT on himself)" % int(cost))
	t.near(hp0 - k.hp, cost, 0.5, "(health)")
	var sl: BStatus = k.get_status("shadow_slay")
	t.ok(sl != null and sl.stacks == 1, "Cyan Shadow: 1 stack of Shadow Slay")
	t.near(float(sl.meta.get("total", 0.0)) if sl != null else 0.0, cost * 0.25, 0.5, "worth trigger value (= health lost) × 25%")
	var evs2: Array[Dictionary] = _run(b, b.time + 2.0)
	var rot := 0.0
	for e: Dictionary in _of(evs2, "damage"):
		if e["dst"] == archer and str(e.get("ability", "")).begins_with("shadow_rot"):
			rot += float(e["amount"])
	t.ok(rot > 0.0, "his hits carry magic damage over time (%d so far)" % int(rot))
	# 基础武器(没有效果)：不触发、不掉血
	var b2 := Fixture.make([{"def": "node_knight_errant", "pos": Vector2(0, -5)}, {"def": "test_hitter", "team": 1, "pos": Vector2(0, -2)},
		{"def": "node_archer", "team": 1, "pos": Vector2(3, 5)}])
	var k2: BUnit = b2.units[0]
	b2.start()
	var hp2: float = k2.hp
	var evs3: Array[Dictionary] = _run(b2, GC.START_DELAY + 0.3)
	t.eq(_of(evs3, "shadow_step").size(), 1, "basic weapon: still teleports")
	t.eq(_of(evs3, "self_cost").size(), 0, "but Blood Temper doesn't trigger")
	t.near(k2.hp, hp2, 0.01, "and costs no health")


func test_blood_temper_never_kills_him(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_knight_errant", "pos": Vector2(0, -5), "weapon": "cyan_shadow"}, {"def": "test_hitter", "team": 1, "pos": Vector2(0, -2)},
		{"def": "node_archer", "team": 1, "pos": Vector2(3, 5)}])
	var k: BUnit = b.units[0]
	b.start()
	k.hp = 40.0
	_run(b, GC.START_DELAY + 0.3)
	t.ok(k.alive and k.hp >= 0.99 and k.hp < 2.0, "left on 1 health (%.1f)" % k.hp)
