extends RefCounted
## 幻彩节点：闪耀色彩(【充能 9】：每造成一次物理 / 魔法伤害消耗 1 层——物理 → 蓝色颜料(魔法增幅，下一次伤害转成魔法)，
## 魔法 → 红色颜料(物理增幅，转成物理)；增幅 (200 + 2 × 法强 + x)%，和其它增伤同一个乘区)、
## 少女幻终(1 星起：充能用光 → 【吟唱 9】嘲讽 + 80% 减伤 + 每 0.25 秒对范围内所有其他人(不分敌我)的真实伤害；
## 吟唱结束对范围内所有其他人造成 触发数值 × 实际吟唱秒数 的真实伤害，然后强制阵亡)、颜料(触发器) + 专武幻彩镰刀。


func _run(b: Battle, sec: float) -> void:
	while b.time < sec and b.state != "ended":
		b.step()


func _trig(id: String) -> TriggerDef:
	for tr: TriggerDef in Fixture.catalog().get_unit("node_magi").triggers:
		if tr.id == id:
			return tr
	return null


func _hit(b: Battle, src: BUnit, dst: BUnit, amount: float, kind: String) -> float:
	var d: float = b.pipeline.fx.damage(src, dst, amount, kind, {"surface": "other"})
	b.pipeline.drain()
	return d


func _last_kind(b: Battle, src: BUnit) -> String:
	var k := ""
	for e: Dictionary in Fixture.events_of(b, "damage"):
		if e["src"] == src:
			k = str(e["kind"])
	return k


func _no_crit(u: BUnit) -> void:
	u.base.crit_chance = 0.0
	u.mark_dirty()


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = cat.get_unit("node_magi")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class], [3, "purple", "security", "warrior", "heavy"],
		"rarity 3, purple, Security, warrior, two-handed heavy")
	t.eq(d.weapon_classes, ["heavy", "polearm"] as Array[String], "can also use two-handed long weapons")
	t.near(float((d.wclass_overrides["heavy"] as Dictionary)["interval"]), 2.4, 0.001, "attack interval 2.4 s")
	t.eq(str((d.anim_overrides["heavy"] as Dictionary)["attack"]), "attack_magi", "her own attack animation")
	var e: EquipmentDef = cat.get_equipment("prism_scythe")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["heavy", "purple", 3, "node_magi"], "Prism Scythe: heavy, purple, rarity 3, hers")
	t.ok(e.flat_mods.has("attack_power") and e.flat_mods.has("ability_power"), "attack and ability power")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_paint_alternates_converts_and_amplifies(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_magi", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var mg: BUnit = b.units[0]
	var dm: BUnit = b.units[1]
	b.start()
	_no_crit(mg)
	var ap: float = mg.get_stats().ability_power
	var amp: float = (200.0 + 2.0 * ap + 0.0) / 100.0
	t.near(_hit(b, mg, dm, 100.0, "physical"), 100.0, 0.01, "first hit: no paint yet")
	var p: BStatus = mg.get_status("paint")
	t.ok(p != null and str(p.meta.get("convert", "")) == "magic" and str(p.meta.get("color", "")) == "blue", "physical damage → blue paint")
	t.ok(p != null and not p.has_flag("dispellable") and p.max_stacks == 1, "one paint at a time, can't be dispelled")
	t.near(mg.get_stats().magic_damage_pct, amp, 0.001, "magic damage +(200 + 2 × AP)%")
	t.near(_hit(b, mg, dm, 100.0, "physical"), 100.0 * (1.0 + amp), 0.5, "next damage is turned into magic and amplified")
	t.eq(_last_kind(b, mg), "magic", "…as magic damage")
	var p2: BStatus = mg.get_status("paint")
	t.ok(p2 != null and str(p2.meta.get("convert", "")) == "physical" and str(p2.meta.get("color", "")) == "red", "magic damage → red paint")
	t.near(mg.get_stats().magic_damage_pct, 0.0, 0.001, "the blue paint was used up")
	t.eq(int(mg.ability_charges.get("node_magi_colors", 9)), 7, "two charges spent")
	# 和其它增伤同一个乘区：+50% 通用增伤加在一起
	b.pipeline.fx.apply_status(mg, mg, {"status_id": "amp_test", "flags": ["buff"], "duration": 30.0, "stats": {"damage_dealt_pct": {"flat": 0.5}}}, {})
	t.near(_hit(b, mg, dm, 100.0, "magic"), 100.0 * (1.0 + amp + 0.5), 0.5, "paint and other damage amps add up in one zone")
	b.pipeline.fx.end_status(mg, "amp_test")
	for i in range(6):
		_hit(b, mg, dm, 100.0, "physical")
	t.eq(int(mg.ability_charges.get("node_magi_colors", 9)), 0, "nine damage instances: charges are out")
	t.ok(mg.get_status("paint") != null, "the last paint is still there")
	_hit(b, mg, dm, 100.0, "physical")
	t.ok(mg.get_status("paint") == null, "used up, and no charges left: no new paint")
	t.near(_hit(b, mg, dm, 100.0, "physical"), 100.0, 0.01, "plain damage again")
	t.eq(mg.phase, "chant", "1 star: the Grand Finale too (unlocked from 1★)")


func test_grand_finale(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_magi", "pos": Vector2(0, 0), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.5)},
		{"def": "test_dummy", "team": 0, "pos": Vector2(1.6, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 8)}])
	var mg: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	var ally: BUnit = b.units[2]
	var far: BUnit = b.units[3]
	b.start()
	_no_crit(mg)
	t.near(b.pipeline.passive_splash_radius(mg), 5.0 * GC.SPLASH_M_PER_POINT, 0.001, "[splash 5]")
	_run(b, GC.START_DELAY + 0.05)
	for i in range(9):
		_hit(b, mg, foe, 10.0, "physical")
	t.eq(mg.phase, "chant", "charges out: starts chanting")
	var t0: float = b.time
	t.ok(mg.get_status("girl_finale") != null, "domain is up")
	t.near(mg.get_stats().damage_taken_pct, 0.8, 0.001, "80% damage reduction while chanting")
	var st: StatBlock = mg.get_stats()
	var k: float = st.attack_power * (1.0 + st.ability_power / 100.0)
	_run(b, t0 + 0.3)
	t.ok(foe.forced_target == mg, "enemies in range are taunted")
	t.ok(far.forced_target != mg, "…but not the ones outside")
	var hp_f: float = foe.hp
	var hp_a: float = ally.hp
	_run(b, t0 + 2.3)
	var y: float = _trig("node_magi_finale_tick").ratio_for(2)
	var per_tick: float = k * y
	t.near(hp_a - ally.hp, 8.0 * per_tick, per_tick * 1.01, "every 0.25 s: true damage to allies in range too")
	t.near(hp_f - foe.hp, 8.0 * per_tick, per_tick * 1.01, "…and to enemies")
	t.near(far.hp, far.get_stats().max_health, 0.01, "nothing outside the range")
	var fin: Array[Dictionary] = []
	var hp_f2: float = 0.0
	var hp_a2: float = 0.0
	while b.time < t0 + 9.5 and mg.alive:
		hp_f2 = foe.hp
		hp_a2 = ally.hp
		b.step()
		fin.append_array(Fixture.events_of(b, "magi_finale"))
	t.ok(not mg.alive and bool(mg.meta.get("finale_death", false)), "after the finale she dies")
	t.eq(fin.size(), 1, "one finale")
	if fin.size() == 1:
		t.near(float(fin[0]["chanted"]), 9.0, 0.06, "full 9 s chant")
		t.eq(int(fin[0]["count"]), 2, "hits everyone else in range (ally and enemy)")
	var big: float = k * _trig("node_magi_finale").ratio_for(2) * 9.0
	t.near(hp_f2 - foe.hp, big, big * 0.02 + per_tick * 2.0, "finale: trigger value × seconds chanted, true damage")
	t.near(hp_a2 - ally.hp, big, big * 0.02 + per_tick * 2.0, "…to allies as well")
	t.near(far.hp, far.get_stats().max_health, 0.01, "still nothing outside the range")


func test_paint_trigger_and_scythe(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_magi", "pos": Vector2(0, 0), "weapon": "prism_scythe"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.2)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0.9, 1.0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(-0.9, 1.0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0.0, 2.0)}])
	var mg: BUnit = b.units[0]
	b.start()
	_no_crit(mg)
	var st: StatBlock = mg.get_stats()
	t.near(st.attack_power, mg.base.attack_power + 30.0, 0.01, "Prism Scythe: +attack")
	t.near(st.ability_power, mg.base.ability_power + 30.0, 0.01, "…and +ability power")
	b.units[1].meta["dummy"] = true
	b.pipeline.normal_attack(mg, b.units[1])
	b.pipeline.drain()
	var reap: Array[Dictionary] = []
	for e: Dictionary in Fixture.events_of(b, "damage"):
		if str(e.get("ability", "")) == "prism_scythe_reap":
			reap.append(e)
	t.eq(reap.size(), 3, "[multi-attack 3]: three enemies around her")
