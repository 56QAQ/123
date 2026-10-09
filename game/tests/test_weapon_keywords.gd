extends RefCounted
## 各武器大类自带的普攻关键词：走和其它关键词同一条管线(Pipeline.kw_value)，关键词数值变了效果跟着变。


func _run_until(b: Battle, stop: Callable, max_seconds: float = 12.0) -> void:
	for i in range(int(max_seconds / GC.SIM_DT)):
		b.step()
		if stop.call():
			return


func _no_crit(u: BUnit) -> void:
	u.base.crit_chance = 0.0
	u.mark_dirty()


func test_bow_draws_before_release_and_doubles_damage(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2.ZERO, "weapon": "basic_bow"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}])
	_no_crit(b.units[0])
	b.start()
	_run_until(b, func() -> bool: return not Fixture.events_of(b, "damage", "normal_attack").is_empty())
	var t_start: float = float(Fixture.events_of(b, "attack_start")[0]["time"])
	var t_rel: float = float(Fixture.events_of(b, "attack_release")[0]["time"])
	var wc: Dictionary = GC.WEAPON_CLASSES["bow"]
	t.ok(not Fixture.events_of(b, "draw_start").is_empty(), "[chant] on the bow's normal attack draws before release")
	t.near(t_rel - t_start, float(wc["windup"]) + 1.0, 0.05, "released after windup + a full 1 s draw")
	var d: Array[Dictionary] = Fixture.events_of(b, "damage", "normal_attack")
	t.near(float(d[0]["amount"]), 100.0 * float(wc["na_mult"]) * 2.0, 0.5, "full draw doubles the damage")


func test_pistols_and_dual_blades_pursue_with_the_other_hand(t: TestCtx) -> void:
	for wc: String in ["pistols", "dual"]:
		var b := Fixture.make([{"def": "test_hitter", "pos": Vector2.ZERO, "weapon": "basic_" + wc},
			{"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.9)}])
		_no_crit(b.units[0])
		b.pipeline.normal_attack(b.units[0], b.units[1], false, {"released_at": b.time})
		b.advance_pending(1.0)
		var d: Array[Dictionary] = Fixture.events_of(b, "damage", "normal_attack")
		t.eq(d.size(), 2, "%s: [pursuit 1] adds a second normal attack" % wc)
		t.eq(Fixture.events_of(b, "attack_copy").size(), 1, "%s: one copy" % wc)
		if d.size() == 2:
			t.ok(float(d[1]["time"]) >= float(d[0]["time"]) + 0.05, "%s: the other hand comes a moment later" % wc)


func test_rifle_ammo_is_the_stacking_status_and_reloads(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2.ZERO, "weapon": "basic_rifle"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}])
	var u: BUnit = b.units[0]
	var cap: int = int(GC.WEAPON_CLASSES["rifle"]["na_keywords"]["stacking"])
	t.eq(b.pipeline.ammo(u).stacks, cap, "starts with a full magazine = [stacking N]")
	b.start()
	_run_until(b, func() -> bool: return not Fixture.events_of(b, "reload_start").is_empty(), 20.0)
	t.eq(Fixture.events_of(b, "attack_release").size(), cap, "fires N shots before reloading")
	t.eq(b.pipeline.ammo(u).stacks, 0, "empty when the reload starts")
	_run_until(b, func() -> bool: return not Fixture.events_of(b, "reload_end").is_empty(), 10.0)
	t.eq(b.pipeline.ammo(u).stacks, cap, "reload refills the magazine")


func test_heavy_whirls_into_several_enemies_and_chops_a_single_one(t: TestCtx) -> void:
	var specs: Array = [{"def": "test_hitter", "pos": Vector2.ZERO, "weapon": "basic_heavy"}]
	for p: Vector2 in [Vector2(0, 1.0), Vector2(0.9, 0.5), Vector2(-0.9, 0.5), Vector2(0, -1.0)]:
		specs.append({"def": "test_dummy", "team": 1, "pos": p})
	var b := Fixture.make(specs)
	b.start()
	_run_until(b, func() -> bool: return not Fixture.events_of(b, "damage", "normal_attack").is_empty())
	var st: Array[Dictionary] = Fixture.events_of(b, "attack_start")
	t.ok(not st.is_empty() and str(st[0]["variant"]) == "multi", "2+ enemies in range → whirl")
	var hit := {}
	for e: Dictionary in Fixture.events_of(b, "damage", "normal_attack"):
		hit[e["dst"]] = true
	t.eq(hit.size(), 3, "[multi_attack 3] hits 3 of the 4 enemies")
	var b2 := Fixture.make([{"def": "test_hitter", "pos": Vector2.ZERO, "weapon": "basic_heavy"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.0)}])
	b2.start()
	_run_until(b2, func() -> bool: return not Fixture.events_of(b2, "damage", "normal_attack").is_empty())
	var st2: Array[Dictionary] = Fixture.events_of(b2, "attack_start")
	t.ok(not st2.is_empty() and str(st2[0]["variant"]) == "", "a single enemy gets the normal chop")


func test_polearm_pierces_the_enemy_behind_its_target(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2.ZERO, "weapon": "basic_polearm"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.2)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0.1, 2.0)}])
	b.start()
	_run_until(b, func() -> bool: return not Fixture.events_of(b, "damage", "normal_attack").is_empty())
	var st: Array[Dictionary] = Fixture.events_of(b, "attack_start")
	t.ok(not st.is_empty() and str(st[0]["variant"]) == "multi", "an enemy lined up behind the target → piercing thrust")
	var hit := {}
	for e: Dictionary in Fixture.events_of(b, "damage", "normal_attack"):
		hit[e["dst"]] = true
	t.eq(hit.size(), 2, "[multi_attack 2] pierces both")
	var b2 := Fixture.make([{"def": "test_hitter", "pos": Vector2.ZERO, "weapon": "basic_polearm"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.2)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.4, 1.2)}])
	b2.start()
	_run_until(b2, func() -> bool: return not Fixture.events_of(b2, "damage", "normal_attack").is_empty())
	var st2: Array[Dictionary] = Fixture.events_of(b2, "attack_start")
	t.ok(not st2.is_empty() and str(st2[0]["variant"]) == "", "an enemy off to the side is not pierced")


func test_focus_splash_aims_for_the_best_payoff(t: TestCtx) -> void:
	# 敌 A 旁边站着一个我方单位、敌 B 旁边没有：打 A = 1 + 0.5(B) - 0.75(友军)，打 B = 1 + 0.5(A) → 选 B
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2.ZERO, "weapon": "basic_focus"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 3.0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0.8, 3.0)},
		{"def": "test_dummy", "team": 0, "pos": Vector2(-0.9, 3.0)}])
	var u: BUnit = b.units[0]
	var na: AbilityDef = u.na_payload()
	var aim: Dictionary = Targeting.best_splash_aim(b, u, na, 4.0)
	t.ok(aim.get("target") == b.units[2], "aims at the enemy whose splash spares the ally")
	t.near(float(aim.get("score", 0.0)), 1.5, 0.001, "payoff = direct 1 + one splashed enemy 0.5")
	t.near(Pipeline.splash_radius(u, na), float(Pipeline.kw_value(u, na, "splash", 1)) * GC.SPLASH_M_PER_POINT, 0.0001,
		"splash radius comes from the keyword value")
	# 打地板：没有直接目标，落点周围的单位都吃 50%
	var b2 := Fixture.make([{"def": "test_hitter", "pos": Vector2.ZERO, "weapon": "basic_focus"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(-0.5, 3.0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0.5, 3.0)}])
	_no_crit(b2.units[0])
	b2.pipeline.normal_attack(b2.units[0], null, false, {"aim_point": Vector2(0, 3.0)})
	var d: Array[Dictionary] = Fixture.events_of(b2, "damage", "normal_attack")
	t.eq(d.size(), 2, "a ground shot splashes both enemies")
	if not d.is_empty():
		t.near(float(d[0]["amount"]), 50.0, 0.5, "splash = 50% of attack")
