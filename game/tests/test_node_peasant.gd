extends RefCounted
## 重构版耕植节点：吃苦耐劳(承受普攻 +1 层，只减普攻伤害)、韧性(2 星：每层单独回血)、收获时刻(首次低于 50%)、
## 专属武器丰收(冷却 20 秒，在脚下开出稻田：站在上面的任何单位每次回复 + 0.1 × 触发数值)。


func _make(star: int, weapon: String = "") -> Battle:
	return Fixture.make([{"def": "node_peasant", "pos": Vector2.ZERO, "star": star, "weapon": weapon},
		{"def": "test_hitter", "team": 1, "pos": Vector2(0, 1.2)}])


func test_hard_work_stacks_on_normal_attacks_and_only_blunts_normal_attacks(t: TestCtx) -> void:
	var b := _make(1)
	var u: BUnit = b.units[0]
	var hitter: BUnit = b.units[1]
	hitter.base.attack_power = 200.0
	hitter.base.crit_chance = 0.0
	hitter.mark_dirty()
	for i in range(7):
		b.pipeline.normal_attack(hitter, u)
	t.eq(u.status_stacks("hardwork"), 5, "capped by [stacking 5]")
	var st: BStatus = u.get_status("hardwork")
	t.ok(st.has_flag("dispellable"), "can be dispelled")
	t.near(st.expires_at - b.time, 2.0, 0.001, "lasts 2 s, refreshed on every hit")
	t.near(u.get_stats().na_damage_taken_flat, 5.0 * 15.0, 0.001, "1★: 5 stacks × 15 flat normal attack reduction")
	# 普攻被减免，别的伤害不减
	var hp0: float = u.hp
	b.pipeline.normal_attack(hitter, u)
	var na_taken: float = hp0 - u.hp
	var raw: float = 200.0 * 100.0 / (100.0 + u.get_stats().defense)
	t.near(na_taken, raw - 75.0, 0.5, "normal attack damage minus 75")
	var hp1: float = u.hp
	b.pipeline.fx.damage(hitter, u, 200.0, "physical", {"surface": "equipment"})
	t.near(hp1 - u.hp, raw, 0.5, "non-normal-attack damage is not reduced")


func test_toughness_heals_each_stack_separately_from_two_stars(t: TestCtx) -> void:
	var b1 := _make(1)
	for i in range(5):
		b1.pipeline.normal_attack(b1.units[1], b1.units[0])
	t.ok(b1.units[0].get_status("hardwork").hot.is_empty(), "1★: passive 2 locked, no healing")
	var b := _make(2)
	var u: BUnit = b.units[0]
	b.start()
	for i2 in range(5):
		b.pipeline.normal_attack(b.units[1], u)
	var hot: Dictionary = u.get_status("hardwork").hot
	t.near(float(hot.get("pct", 0.0)), 0.001, 0.00001, "2★: 0.1% max health per stack per second")
	t.near(float(hot.get("interval", 0.0)), 0.75, 0.0001, "each stack heals every 0.75 s")
	u.hp = 500.0
	var heals0: int = Fixture.events_of(b, "heal").size()
	for i3 in range(int(0.8 / GC.SIM_DT)):
		b.step()
	t.eq(Fixture.events_of(b, "heal").size() - heals0, 5, "one separate heal per stack")


func test_harvest_time_fires_once_below_half_and_opens_a_paddy(t: TestCtx) -> void:
	var b := _make(1, "harvest_rake")
	var u: BUnit = b.units[0]
	b.start()
	var mh: float = u.get_stats().max_health
	b.pipeline.fx.damage(b.units[1], u, mh * 0.3, "true")
	t.eq(b.fields.size(), 0, "not yet: still above 50%")
	b.pipeline.fx.damage(b.units[1], u, mh * 0.3, "true")
	t.eq(b.fields.size(), 1, "health first drops below 50% → a paddy under her")
	var f: Dictionary = b.fields[0]
	t.near(float(f["heal_bonus"]), 0.1 * 0.2 * mh, 0.01, "each heal on it +10% of the trigger value (20% max health)")
	t.near(float(f["radius"]), 1.2, 0.0001, "radius 1.2 m")
	t.near(float(f["until"]) - b.time, 8.0, 0.001, "lasts 8 s")
	b.pipeline.fx.damage(b.units[1], u, 10.0, "true")
	t.eq(b.fields.size(), 1, "only the first time")
	# 稻田不分敌我：站在上面的敌人回血也吃加成；不在上面的不吃
	var e: BUnit = b.units[1]
	e.hp = 100.0
	var r: Dictionary = b.pipeline.fx.heal(e, e, 10.0, {"raw": true})
	t.near(float(r["requested"]), 10.0 + 0.1 * 0.2 * mh, 0.01, "an enemy standing on it gets the bonus too")
	e.pos = Vector2(0, 5)
	var r2: Dictionary = b.pipeline.fx.heal(e, e, 10.0, {"raw": true})
	t.near(float(r2["requested"]), 10.0, 0.01, "off the field: no bonus")
	e.hp = e.get_stats().max_health     # 别让她把 100 血的敌人打死(战斗结束后地形就不再计时)
	for i in range(int(8.2 / GC.SIM_DT)):
		b.step()
	t.eq(b.fields.size(), 0, "the paddy dries up after 8 s")


func test_bountiful_harvest_stats(t: TestCtx) -> void:
	var b0 := _make(1)
	var b1 := _make(1, "harvest_rake")
	t.near(b1.units[0].get_stats().max_health - b0.units[0].get_stats().max_health, 100.0, 0.01, "+100 max health")
	t.near(b1.units[0].get_stats().defense - b0.units[0].get_stats().defense, 20.0, 0.01, "+20 defense")
	var e: EquipmentDef = Fixture.catalog().get_equipment("harvest_rake")
	t.eq(e.class_id, "polearm", "two-handed long weapon")
	t.eq(e.color_id, "green", "green")
	t.near(e.abilities[0].cooldown, 20.0, 0.001, "20 s cooldown")
