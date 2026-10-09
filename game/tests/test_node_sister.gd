extends RefCounted
## 心连节点：量产型号(【召唤】开战及每 x 秒召唤一个自身的复制；复制品没有量产型号、拿基础单手剑)、治疗祈愿(2 星，复制品也有：每 y 秒回复生命比例最低的友军
## + 清除一个剩余时间最长的负面状态)、奇迹(每阵亡 2 只心连节点，目标 = 一个已阵亡友方单位，非召唤物优先)；专武祝福之心(已阵亡 → n × 触发数值复活，否则回复)。


func _def() -> UnitDef:
	return Fixture.catalog().get_unit("node_sister")


func _trig(id: String) -> TriggerDef:
	for tr: TriggerDef in _def().triggers:
		if tr.id == id:
			return tr
	return null


func _calm(v: BUnit) -> void:
	v.attack_cd = 1.0e9
	v.base.move_speed = 0.0
	v.mark_dirty()


func _run(b: Battle, sec: float) -> void:
	while b.time < sec - 0.0001 and b.state != "ended":
		b.step()


func _copies(b: Battle) -> Array:
	return b.units.filter(func(u: BUnit) -> bool: return bool(u.meta.get("sister_copy", false)))


func _kill(b: Battle, u: BUnit) -> void:
	u.hp = 0.0
	u.shield = 0.0
	b.pipeline.fx.try_kill(u, null)


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = _def()
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model], [2, "blue", "welfare", "caster", "focus", "sister"],
		"rarity 2, blue, Welfare, caster, focus, sister model")
	t.eq(d.weapon_classes, ["focus", "sword"] as Array[String], "can equip a one-hand sword")
	t.eq(d.passive_by_id("node_sister_pray").unlock_star, 2, "Healing Prayer unlocks at 2 stars")
	var e: EquipmentDef = cat.get_equipment("blessing_heart")
	t.eq([e.class_id, e.color_id, e.cost, e.owner, e.model], ["focus", "blue", 2, "node_sister", "rosary"], "Heart of Blessing: focus, blue, 2, hers")
	t.ok(e.abilities[0].cooldown == 10.0 and float(e.flat_mods.get("ability_power", 0.0)) > 0.0, "10 s cooldown, ability power")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_mass_production(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_sister", "pos": Vector2(0, -4), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 8)}])
	var s: BUnit = b.units[0]
	b.start()
	_calm(s)
	_run(b, GC.START_DELAY + 0.05)
	var cp: Array = _copies(b)
	t.eq(cp.size(), 1, "one copy at the start of battle")
	var c: BUnit = cp[0]
	t.ok(c.is_summon and c.def.id == "node_sister" and c.star == 2, "a summoned Node Sister of the same star")
	t.eq(c.weapon.id, "basic_sword", "holding a basic one-hand sword")
	_run(b, GC.START_DELAY + 7.2)
	t.eq(_copies(b).size(), 2, "★2: another one 7 s later")
	_run(b, GC.START_DELAY + 14.2)
	t.eq(_copies(b).size(), 3, "and another 7 s after that — copies don't make copies")


func test_healing_prayer(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_sister", "pos": Vector2(0, -4), "star": 2}, {"def": "test_hitter", "pos": Vector2(3, -4)},
		{"def": "test_hitter", "pos": Vector2(-3, -4)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}])
	var s: BUnit = b.units[0]
	b.start()
	_calm(s)
	_calm(b.units[1])
	_calm(b.units[2])
	_run(b, GC.START_DELAY + 0.05)
	for c: BUnit in _copies(b):
		c.meta["no_pray_test"] = true
		_kill(b, c)                                    # 复制品先撤下(它们也会祈愿)
	var low: BUnit = b.units[2]
	b.units[1].hp = b.units[1].get_stats().max_health * 0.6
	low.hp = low.get_stats().max_health * 0.3
	var hp0: float = low.hp
	for spec: Array in [["slowed_a", 9.0], ["slowed_b", 20.0]]:
		b.pipeline.fx.apply_status(null, low, {"status_id": spec[0], "duration": spec[1], "max_stacks": 1, "flags": ["debuff", "dispellable"]})
	_run(b, b.time + 5.1)
	var want: float = _trig("node_sister_pray").flat_for(2) * (1.0 + s.get_stats().ability_power / 100.0) * (1.0 + s.get_stats().healing_done_pct)
	t.ok(low.hp - hp0 >= want - 1.0, "★2: the lowest-ratio ally is healed y × (100 + AP)%% (%.0f)" % want)
	t.ok(low.get_status("slowed_b") == null and low.get_status("slowed_a") != null, "and loses the debuff with the longest time left")


func test_miracle_revives_a_fallen_ally(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_sister", "pos": Vector2(0, -4), "weapon": "blessing_heart"}, {"def": "test_hitter", "pos": Vector2(3, -4)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}])
	var s: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	b.start()
	_calm(s)
	_calm(ally)
	_run(b, GC.START_DELAY + 0.05)
	_kill(b, ally)
	_run(b, GC.START_DELAY + 8.3)
	var cp: Array = _copies(b)
	t.eq(cp.size(), 2, "two copies by now")
	_kill(b, cp[0])
	t.ok(not ally.alive, "one Node Sister down: nothing yet")
	_kill(b, cp[1])
	t.ok(ally.alive, "two down: Miracle → Heart of Blessing revives the fallen ally (non-summons first)")
	var v: float = _trig("node_sister_miracle").flat_for(1) * (1.0 + s.get_stats().ability_power / 100.0)
	var n: float = float(Fixture.catalog().get_equipment("blessing_heart").abilities[0].effect_config["revive_mult"])
	t.near(ally.hp, minf(ally.get_stats().max_health, v * n * (1.0 + s.get_stats().healing_done_pct)), 2.0, "with n × trigger value health (%.0f)" % (v * n))


func test_miracle_brings_back_a_copy_when_no_one_else_fell(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_sister", "pos": Vector2(0, -4), "weapon": "blessing_heart"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}])
	var s: BUnit = b.units[0]
	b.start()
	_calm(s)
	_run(b, GC.START_DELAY + 8.3)
	var cp: Array = _copies(b)
	t.eq(cp.size(), 2, "two copies")
	_kill(b, cp[0])
	_kill(b, cp[1])
	t.ok((cp[1] as BUnit).alive and not (cp[0] as BUnit).alive, "only copies have fallen: the one that fell last is brought back")


func test_blessing_heals_the_living(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_sister", "pos": Vector2(0, -4), "weapon": "blessing_heart"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}])
	var s: BUnit = b.units[0]
	b.start()
	_calm(s)
	_run(b, GC.START_DELAY + 0.05)
	s.hp = 100.0
	var ab: AbilityDef = Fixture.catalog().get_equipment("blessing_heart").abilities[0]
	var tr := TriggerDef.from_dict({"id": "t_bless", "timing": "OnBattleFrame", "base_value_mode": "fixed", "base_value_flat": 200.0, "target_rule": "self",
		"team_filter": "ally", "tags": ["equipment_payload"]})
	s.runtime_triggers.append(tr)
	b.pipeline.emit("OnBattleFrame", s, null, 0.0, ["battle_frame"], {})
	t.near(s.hp, 100.0 + 200.0 * (1.0 + s.get_stats().healing_done_pct), 1.0, "living target: heals the trigger value")
