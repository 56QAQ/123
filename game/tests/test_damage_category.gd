extends RefCounted
## 伤害分类：每一下伤害都在 普攻(normal_attack) / 技能(skill) / 持续(dot) 里选一个，伤害事件和事件标签都带着
## (普攻 = normal_attack，技能 = skill_damage，持续 = dot_damage)。重燃被普攻伤害和技能伤害触发，持续伤害不触发。


func _run(b: Battle, sec: float) -> void:
	while b.time < sec and b.state != "ended":
		b.step()


func _cats(b: Battle, src: BUnit) -> Dictionary:
	var out := {}
	for e: Dictionary in Fixture.events_of(b, "damage"):
		if e["src"] == src:
			var k: String = str(e.get("ability", ""))
			if not out.has(k):
				out[k] = str(e.get("category", ""))
	return out


func test_every_hit_has_one_category(t: TestCtx) -> void:
	# 狂猎节点：冲锋落地斩(被动) = 技能；普攻 = 普攻
	var b := Fixture.make([{"def": "node_berserker", "pos": Vector2(0, 0), "star": 1}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 4.0)}])
	b.start()
	_run(b, GC.START_DELAY + 4.0)
	var c: Dictionary = _cats(b, b.units[0])
	t.eq(c.get("node_berserker_hunt", ""), "skill", "Wolf Hunt's dash strike is skill damage")
	t.eq(c.get("__na_dual", ""), "normal_attack", "his normal attacks are normal-attack damage")
	# 清心节点 2 星：弱体符 = 技能
	var b2 := Fixture.make([{"def": "node_taoist", "pos": Vector2(0, 0), "star": 2}, {"def": "test_hitter", "team": 1, "pos": Vector2(0, 3.0)}])
	b2.start()
	_run(b2, GC.START_DELAY + 5.0)
	t.eq(_cats(b2, b2.units[0]).get("node_taoist_weak_dmg", ""), "skill", "the weakening talisman is skill damage")
	# 和星节点 2 星：监护人的光箭 = 技能
	var b3 := Fixture.make([{"def": "node_druid", "pos": Vector2(0, 0), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 3.0)}])
	b3.start()
	_run(b3, GC.START_DELAY + 6.0)
	t.eq(_cats(b3, b3.units[0]).get("node_druid_arrow", ""), "skill", "the Guardian's light arrow is skill damage")
	# 爱心针剂(视为普攻伤害) = 普攻
	var b4 := Fixture.make([{"def": "node_nurse", "pos": Vector2(0, 0), "weapon": "heart_syringe"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 3.0)}])
	b4.start()
	_run(b4, GC.START_DELAY + 6.0)
	t.eq(_cats(b4, b4.units[0]).get("heart_syringe_dose", ""), "normal_attack", "an effect that counts as normal-attack damage is normal-attack damage")
	# 燃烧(状态的持续伤害) = 持续
	var b5 := Fixture.make([{"def": "test_hitter", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.9)}])
	b5.start()
	b5.pipeline.fx.apply_status(b5.units[0], b5.units[1], {"status_id": "burning", "duration": 3.0, "independent": true, "flags": ["debuff", "burning"],
		"dot": {"kind": "magic", "amount": 20.0, "interval": 1.0}}, {})
	_run(b5, b5.time + 2.5)
	var dot_ok := false
	for e: Dictionary in Fixture.events_of(b5, "damage"):
		if str(e.get("surface", "")) == "status":
			dot_ok = str(e.get("category", "")) == "dot"
	t.ok(dot_ok, "burning ticks are damage over time")
	# 没有任何伤害事件缺分类
	var missing := 0
	for bb: Battle in [b, b2, b3, b4, b5]:
		for e2: Dictionary in Fixture.events_of(bb, "damage"):
			if not Effects.DAMAGE_CATEGORIES.has(str(e2.get("category", ""))):
				missing += 1
	t.eq(missing, 0, "no damage without a category")


func test_rekindle_on_skill_damage_not_dot(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_samurai", "pos": Vector2(0, 0), "star": 2}, {"def": "test_hitter", "team": 1, "pos": Vector2(6.0, 6.0)}])
	var s: BUnit = b.units[0]
	var h: BUnit = b.units[1]
	b.start()
	var cfg := {"status_id": "rekindle", "flags": ["buff", "dispellable"], "max_stacks": 10, "add_stacks": 10, "stats": {}}
	b.pipeline.fx.apply_status(s, s, cfg, {})
	s.hp = s.get_stats().max_health - 1000.0
	# 持续伤害：不消耗
	b.pipeline.fx.damage(h, s, 50.0, "magic", {"surface": "status", "ability_id": "burning"})
	b.step()
	t.eq(s.status_stacks("rekindle"), 10, "damage over time doesn't use up Rekindle")
	# 技能伤害：消耗并回血
	var hp0: float = s.hp
	b.pipeline.fx.damage(h, s, 50.0, "magic", {"surface": "passive", "ability_id": "some_skill"})
	b.step()
	t.eq(s.status_stacks("rekindle"), 0, "skill damage uses up Rekindle")
	t.ok(s.hp > hp0, "and heals him (%.0f → %.0f)" % [hp0, s.hp])
