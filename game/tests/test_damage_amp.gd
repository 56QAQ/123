extends RefCounted
## 伤害增幅乘区：通用增伤 + 物理 / 魔法 / 真实 + 普攻 / 技能 / 持续 六种细分增幅 + 针对目标的增伤(猎人笔记) + 停顿增伤(完美时计)
## 都是同一个乘区——一次伤害吃到几种就先加起来、再乘一次；魔女的火与冰(最终伤害)另算。


func _b() -> Battle:
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}])
	b.start()
	return b


func _amp(b: Battle, stats: Dictionary) -> void:
	var u: BUnit = b.units[0]
	var sts := {}
	for k: String in stats.keys():
		sts[k] = {"flat": float(stats[k])}
	b.pipeline.fx.apply_status(u, u, {"status_id": "amp_%d" % b.next_status_serial(), "flags": ["buff"], "duration": 30.0, "stats": sts}, {})


func _hit(b: Battle, kind: String, cat: String) -> float:
	var o := {"surface": "other"}
	match cat:
		"normal_attack":
			o = {"surface": "normal_attack"}
		"dot":
			o = {"surface": "status"}
	return b.pipeline.fx.damage(b.units[0], b.units[1], 100.0, kind, o)


func test_each_subtype_only_boosts_its_own(t: TestCtx) -> void:
	var cases := [["physical_damage_pct", "physical", "skill"], ["magic_damage_pct", "magic", "skill"], ["true_damage_pct", "true", "skill"],
		["na_damage_pct", "physical", "normal_attack"], ["skill_damage_pct", "physical", "skill"], ["dot_damage_pct", "magic", "dot"]]
	for c: Array in cases:
		var b := _b()
		_amp(b, {str(c[0]): 0.5})
		t.near(_hit(b, str(c[1]), str(c[2])), 150.0, 0.01, "%s boosts %s / %s damage" % [c[0], c[1], c[2]])
		var other_kind: String = "magic" if str(c[1]) != "magic" else "physical"
		var other_cat: String = "skill" if str(c[2]) != "skill" else "normal_attack"
		if str(c[0]).begins_with("physical") or str(c[0]).begins_with("magic") or str(c[0]).begins_with("true"):
			t.near(_hit(b, other_kind, str(c[2])), 100.0, 0.01, "…not %s damage" % other_kind)
		else:
			t.near(_hit(b, str(c[1]), other_cat), 100.0, 0.01, "…not %s damage" % other_cat)


func test_same_zone_adds_up(t: TestCtx) -> void:
	var b := _b()
	_amp(b, {"physical_damage_pct": 0.5, "na_damage_pct": 0.3, "damage_dealt_pct": 0.2})
	t.near(_hit(b, "physical", "normal_attack"), 200.0, 0.01, "+50% physical, +30% normal attack, +20% damage: 100 × (1 + 1.0), not × 1.5 × 1.3 × 1.2")
	# 针对目标的增伤(猎人笔记)也在同一个乘区
	var b2 := _b()
	_amp(b2, {"damage_dealt_pct": 0.5})
	b2.pipeline.fx.apply_status(b2.units[0], b2.units[0], {"status_id": "notes", "flags": ["buff"], "duration": 30.0, "stats": {},
		"meta": {"vs_target": b2.units[1].uid, "amp": 0.5}}, {})
	t.near(_hit(b2, "physical", "skill"), 200.0, 0.01, "Hunter's Notes +50% and +50% damage add up (× 2.0, not × 2.25)")
	# 负的也一样加在里面(拖后腿)
	var b3 := _b()
	_amp(b3, {"physical_damage_pct": 0.6, "damage_dealt_pct": -0.2})
	t.near(_hit(b3, "physical", "skill"), 140.0, 0.01, "+60% physical and -20% damage: × 1.4")
