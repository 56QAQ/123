extends RefCounted
## 屏息节点：瞄准眉心(【吟唱 10】普攻前最多再瞄 10 秒、每秒 +x% 攻击力；打得死 / 被近战敌人够得着就提前开枪)、
## 集中呼吸(身边没敌人每秒 +y% 暴击率，溢出转 2 倍暴击伤害，被近战敌人够得着重置)、一石二鸟(击杀溢出的伤害打离被击杀者最近的敌人)、
## 专武黑色战场(弹匣【叠加 1】、普攻倍率 2.8、射程 +99、物理穿透 +30；【基本】【暴击】触发数值 × 50% 物理伤害)。


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


func _x(star: int) -> float:
	for pa: AbilityDef in Fixture.catalog().get_unit("node_sniper").passives:
		if pa.id == "node_sniper_aim":
			return float((pa.effect_config["aim_pct_by_star"] as Dictionary)[str(star)])
	return 0.0


func _calm(v: BUnit) -> void:
	v.attack_cd = 1.0e9
	v.base.move_speed = 0.0
	v.mark_dirty()


func _no_crit(v: BUnit) -> void:
	v.base.crit_chance = 0.0
	v.mark_dirty()


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = cat.get_unit("node_sniper")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model], [4, "yellow", "engineering", "archer", "rifle", "sniper"],
		"rarity 4, yellow, Engineering, archer, two-handed ranged, sniper model")
	t.eq(d.weapon_classes, ["rifle", "crossbow", "bow"] as Array[String], "can equip one-handed ranged and draw-string ranged")
	t.ok(d.base_stats.attack_power > 180.0, "higher base attack than the rarity-4 archer template (180): %d" % int(d.base_stats.attack_power))
	var e: EquipmentDef = cat.get_equipment("black_battlefield")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["rifle", "black", 4, "node_sniper"], "Black Battlefield: rifle, black, rarity 4, hers")
	t.eq([float(e.flat_mods.get("attack_range", 0.0)), float(e.flat_mods.get("physical_flat_penetration", 0.0))], [99.0, 30.0], "+99 range, +30 armor penetration")
	t.near(float(e.wclass()["na_mult"]), 2.8, 0.0001, "heavy normal attacks (×2.8; rifles ×1.6)")
	t.eq(int((e.wclass()["na_keywords"] as Dictionary)["stacking"]), 1, "magazine 【Stacking 1】 instead of 5")
	t.ok(e.abilities[0].has_keyword("basic") and e.abilities[0].has_keyword("crit"), "【Basic】【Crit】")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_aim_adds_chant_and_attack_per_second(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_sniper", "pos": Vector2(0, -4)}, {"def": "node_sniper", "pos": Vector2(2, -4), "weapon": "", "star": 2},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 5)}])
	var s1: BUnit = b.units[0]
	var s2: BUnit = b.units[1]
	t.eq(Pipeline.kw_value(s1, s1.na_payload(), "chant"), 10, "rifle: normal attacks gain 【Chant 10】")
	t.near(Pipeline.na_draw_scale(s1, 2.0, 10.0), 1.0 + 2.0 * _x(1), 0.0001, "1★: 2 s aimed = +%d%% attack" % int(2.0 * _x(1) * 100.0))
	t.near(Pipeline.na_draw_scale(s2, 10.0, 10.0), 1.0 + 10.0 * _x(2), 0.0001, "2★: fully aimed (10 s) = +%d%%" % int(10.0 * _x(2) * 100.0))
	# 弓：照常先拉弓(1 秒拉满 ×2)，之后再瞄
	s1.weapon = Fixture.catalog().get_equipment("basic_bow")
	s1.mark_dirty()
	t.eq(Pipeline.kw_value(s1, s1.na_payload(), "chant"), 11, "bow: 1 s draw + 10 s aim")
	t.near(Pipeline.na_draw_scale(s1, 1.0, 11.0), 2.0, 0.0001, "the draw still doubles at 1 s")
	t.near(Pipeline.na_draw_scale(s1, 3.0, 11.0), 2.0 * (1.0 + 2.0 * _x(1)), 0.0001, "then +x% per extra second on top")


func test_aims_until_the_shot_kills_or_ten_seconds(t: TestCtx) -> void:
	# 木桩就在身边(2 米)：集中呼吸不涨，暴击率保持 0，估算 = 实际伤害
	var b := Fixture.make([{"def": "node_sniper", "pos": Vector2(0, -1)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1)}])
	var s: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	b.start()
	s.base.move_speed = 0.0
	_no_crit(s)
	foe.hp = 900.0
	var per: float = s.get_stats().attack_power * 1.6
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 9.0)
	var rel: Array[Dictionary] = _of(evs, "attack_release")
	t.eq(rel.size(), 1, "one shot")
	var sc: float = float(rel[0]["chant_scale"]) if not rel.is_empty() else 0.0
	t.ok(sc * per >= 900.0 and (sc - 0.03) * per < 900.0, "keeps aiming until the shot kills (×%.2f × %.0f ≥ 900)" % [sc, per])
	t.ok(not foe.alive, "and it does")
	# 打不死的目标：瞄满 10 秒
	var b2 := Fixture.make([{"def": "node_sniper", "pos": Vector2(0, -2.5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 2.5)}])
	b2.start()
	b2.units[0].base.move_speed = 0.0
	b2.units[0].mark_dirty()
	var evs2: Array[Dictionary] = _run(b2, GC.START_DELAY + 12.0)
	var rel2: Array[Dictionary] = _of(evs2, "attack_release")
	t.ok(not rel2.is_empty() and absf(float(rel2[0]["chant_scale"]) - (1.0 + 10.0 * _x(1))) < 0.02, "can't kill it: aims the full 10 s (×%.1f)" % (1.0 + 10.0 * _x(1)))


func test_fires_at_once_when_a_melee_enemy_can_reach_her(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_sniper", "pos": Vector2(0, 0)}, {"def": "test_hitter", "team": 1, "pos": Vector2(0, 1.4)}])
	var s: BUnit = b.units[0]
	b.start()
	s.base.move_speed = 0.0
	s.mark_dirty()
	t.ok(b.melee_threat(s), "the polearm can reach her")
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 2.0)
	var rel: Array[Dictionary] = _of(evs, "attack_release")
	t.ok(not rel.is_empty() and float(rel[0]["chant_scale"]) < 1.05, "no time to aim: fires right away")


func test_focused_breathing_builds_crit_and_overflows_into_crit_damage(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_sniper", "pos": Vector2(0, -6), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var s: BUnit = b.units[0]
	b.start()
	_calm(s)
	_run(b, GC.START_DELAY + 3.1)
	t.eq(s.status_stacks("focus_breath"), 3, "+1 stack per second with no enemy near")
	t.near(s.get_stats().crit_chance, 0.05 + 3.0 * 0.08, 0.0001, "2★: +8% crit chance each")
	_run(b, GC.START_DELAY + 15.1)
	t.near(s.get_stats().crit_chance, 1.0, 0.0001, "capped at 100%")
	var over: float = 0.05 + 15.0 * 0.08 - 1.0
	t.near(s.get_stats().crit_damage, 1.5 + 2.0 * over, 0.0001, "the overflow (%.0f%%) becomes twice as much crit damage" % (over * 100.0))
	# 有敌人在身边(远程的、够不着她)：不涨也不清
	var n0: int = s.status_stacks("focus_breath")
	var near: BUnit = b.units[1]
	near.pos = s.pos + Vector2(0, 1.5)
	_run(b, b.time + 2.0)
	t.eq(s.status_stacks("focus_breath"), n0, "an enemy beside her (that can't attack her): no more stacks, but no reset")
	# 近战敌人够得着她：整个清掉
	var b2 := Fixture.make([{"def": "node_sniper", "pos": Vector2(0, -6), "star": 2}, {"def": "test_hitter", "team": 1, "pos": Vector2(0, 6)}])
	var s2: BUnit = b2.units[0]
	var hit: BUnit = b2.units[1]
	b2.start()
	_calm(s2)
	hit.base.move_speed = 0.0
	hit.mark_dirty()
	_run(b2, GC.START_DELAY + 4.1)
	t.ok(s2.status_stacks("focus_breath") >= 4, "building up (%d)" % s2.status_stacks("focus_breath"))
	hit.pos = s2.pos + Vector2(0, 1.5)
	var evs: Array[Dictionary] = _run(b2, b2.time + 0.3)
	t.eq(s2.status_stacks("focus_breath"), 0, "a melee enemy in reach: reset")
	t.eq(_of(evs, "status_reset").size(), 1, "(breath broken)")


func test_two_birds_carries_the_overkill_to_the_nearest_enemy(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_sniper", "pos": Vector2(0, -6), "weapon": "black_battlefield"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 4)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.5, 4)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(-5, 4)}, {"def": "test_dummy", "pos": Vector2(3, -6)}])
	var s: BUnit = b.units[0]
	var a: BUnit = b.units[1]
	var near: BUnit = b.units[2]
	var far: BUnit = b.units[3]
	var ally: BUnit = b.units[4]
	b.start()
	_calm(s)
	_no_crit(s)
	a.hp = 300.0
	b.pipeline.fx.damage(s, a, 1000.0, "physical", {"surface": "normal_attack"})
	b.pipeline.drain()
	var evs: Array[Dictionary] = b.poll_events()
	var over: float = 1000.0 - 300.0
	var got: float = 0.0
	for e: Dictionary in _of(evs, "damage"):
		if e["dst"] == near and str(e.get("surface", "")) == "equipment":
			got += float(e["amount"])
	t.ok(not a.alive, "killed")
	t.near(got, over * 0.5, 0.5, "the enemy nearest the kill takes overkill (%d) × 50%% = %d" % [int(over), int(over * 0.5)])
	t.ok(far.hp >= far.get_stats().max_health - 0.01, "nobody else")
	var rc: Array[Dictionary] = _of(evs, "cast_fx")
	t.ok(not rc.is_empty() and str(rc[0]["kind"]) == "ricochet" and (rc[0]["from"] as Vector2).distance_to(a.pos) < 0.01, "the bullet bounces off the fallen enemy")
	# 打死队友不算
	var hp0: float = near.hp
	b.pipeline.fx.damage(s, ally, 1.0e6, "true", {"surface": "other"})
	b.pipeline.drain()
	t.near(near.hp, hp0, 0.01, "killing an ally doesn't trigger it")


func test_black_battlefield_reloads_every_shot(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_sniper", "pos": Vector2(0, -6), "weapon": "black_battlefield"}, {"def": "test_hitter", "team": 1, "pos": Vector2(0, 6)}])
	var s: BUnit = b.units[0]
	b.start()
	s.base.move_speed = 0.0
	s.mark_dirty()
	t.eq(Pipeline.kw_value(s, s.na_payload(), "stacking"), 1, "magazine of 1")
	t.ok(s.get_stats().range_meters() > 100.0, "range +99 (%.0f m)" % s.get_stats().range_meters())
	var na_tr: TriggerDef = null
	for tr: TriggerDef in s.all_triggers():
		if tr.id == "__normal_attack":
			na_tr = tr
	t.near(na_tr.ratio_for(1), 2.8, 0.0001, "normal attack = attack × 2.8")
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 12.5)
	t.ok(_of(evs, "attack_release").size() >= 1 and _of(evs, "reload_start").size() >= 1, "reloads right after the shot")
	t.ok(_of(evs, "reload_start").size() >= _of(evs, "attack_release").size(), "after every shot (%d shots, %d reloads)" % [_of(evs, "attack_release").size(), _of(evs, "reload_start").size()])
