extends RefCounted
## 重构版架盾节点：护盾充能(开战 50×增幅、每秒 10×增幅)、鼠鼠缩头(2 星：没盾就缩、不动不打、+防御、充能翻倍，
## 护盾 > 100 且满 5 秒才出来)、盾，我的盾！(破盾触发，自身优先 + 周围敌人)、专属武器两用电击器。


func _make(star: int, weapon: String = "", foes: Array = []) -> Battle:
	var specs: Array = [{"def": "node_shielder", "pos": Vector2.ZERO, "star": star, "weapon": weapon}]
	for p: Vector2 in foes:
		specs.append({"def": "test_dummy", "team": 1, "pos": p})
	if foes.is_empty():
		specs.append({"def": "test_dummy", "team": 1, "pos": Vector2(0, 30)})
	return Fixture.make(specs)


func _run(b: Battle, secs: float) -> void:
	for i in range(int(round(secs / GC.SIM_DT))):
		b.step()


func test_shield_charge_starts_with_fifty_per_amplify_then_ten_per_second(t: TestCtx) -> void:
	for star: int in [1, 2, 3]:
		var b := _make(star)
		var u: BUnit = b.units[0]
		b.start()
		t.near(u.shield, 50.0 * star, 0.01, "%d★: starts with 50 × amplify %d" % [star, star])
		_run(b, 1.02)
		t.near(u.shield, 50.0 * star + 10.0 * star, 0.01, "%d★: +10 × amplify after one second" % star)


func test_turtle_needs_two_stars_and_holds_until_the_shield_is_back(t: TestCtx) -> void:
	var b1 := _make(1, "", [Vector2(0, 3)])
	b1.start()
	b1.units[0].shield = 0.0
	_run(b1, 0.3)
	t.eq(b1.units[0].status_stacks("turtle"), 0, "1★: passive 2 is locked")
	var b := _make(2, "", [Vector2(0, 3)])
	var u: BUnit = b.units[0]
	b.start()
	var def0: float = u.get_stats().defense
	u.shield = 0.0
	_run(b, 0.3)
	t.eq(u.status_stacks("turtle"), 1, "2★: no shield → ducks behind the shield")
	t.near(u.get_stats().defense, def0 + 20.0, 0.01, "base defense +20 at 2★")
	var p0: Vector2 = u.pos
	var sh0: float = u.shield
	_run(b, 1.0)
	t.ok(u.pos.distance_to(p0) < 0.01, "does not move while turtling")
	t.eq(Fixture.events_of(b, "attack_start").size(), 0, "no normal attacks while turtling")
	t.near(u.shield - sh0, 40.0, 0.01, "shield charge doubled (2 × 10 × amplify 2)")
	# 护盾超过 100 也要满 5 秒才出来
	var entered: float = b.time - 1.3
	var left_at := -1.0
	for i in range(int(8.0 / GC.SIM_DT)):
		b.step()
		if u.status_stacks("turtle") == 0:
			left_at = b.time
			break
	t.ok(left_at > 0.0, "comes back out once the shield is over 100")
	t.ok(left_at - entered >= 4.95, "stays at least 5 s (%.2f s)" % (left_at - entered))
	t.ok(u.shield > 100.0, "shield is above 100 when leaving (%.0f)" % u.shield)


func test_my_shield_hits_self_first_then_nearby_enemies_with_the_stunner(t: TestCtx) -> void:
	var b := _make(1, "dual_use_stunner", [Vector2(0, 1.2), Vector2(1.2, 0), Vector2(0, -1.3), Vector2(0, 8)])
	var u: BUnit = b.units[0]
	u.shield = 10.0
	b.pipeline.fx.damage(b.units[1], u, 30.0, "true")
	var shields: Array[Dictionary] = []
	for e: Dictionary in Fixture.events_of(b, "shield", "equipment"):
		shields.append(e)
	t.eq(shields.size(), 1, "one shield from the stunner")
	if not shields.is_empty():
		t.ok(shields[0]["dst"] == u, "the shield goes to herself")
		t.near(float(shields[0]["amount"]), 25.0 * 1.2 * 1.2, 0.01, "25 × amplify 1 × 120%, +20% shield received")
	var hit: Array[Dictionary] = Fixture.events_of(b, "damage", "equipment")
	t.eq(hit.size(), 2, "[multi_attack 3] = herself + the 2 nearest enemies")
	if not hit.is_empty():
		t.near(float(hit[0]["amount"]), 25.0 * 1.5, 0.01, "enemies take 150% of the trigger value")
		t.eq(str(hit[0]["kind"]), "magic", "stun damage is magic")
	for e2: Dictionary in hit:
		t.ok(e2["dst"] != b.units[4], "the far enemy is out of the ring")
	# 冷却 5 秒：马上再破一次盾不会再触发
	u.shield = 5.0
	b.pipeline.fx.damage(b.units[1], u, 20.0, "true")
	t.eq(Fixture.events_of(b, "damage", "equipment").size(), 2, "5 s cooldown")
	# 基础武器：触发器照样响，但没有载荷 → 什么都不发生
	var b2 := _make(1, "", [Vector2(0, 1.2)])
	b2.units[0].shield = 10.0
	b2.pipeline.fx.damage(b2.units[1], b2.units[0], 30.0, "true")
	t.eq(Fixture.events_of(b2, "damage", "equipment").size(), 0, "no weapon effect with the basic sword")


func test_dual_use_stunner_is_a_contact_range_pistol(t: TestCtx) -> void:
	var b := _make(1, "dual_use_stunner", [Vector2(0, 0.95)])
	var u: BUnit = b.units[0]
	t.near(u.get_stats().range_meters(), 0.0, 0.0001, "attack range drops to zero")
	t.eq(u.style(), "melee", "walks up and fights in contact instead of kiting")
	t.near(u.get_stats().shield_received_pct, 0.2, 0.0001, "+20% shield received")
	t.ok(BattleAI.in_reach(u, b.units[1], u.pos.distance_to(b.units[1].pos), 0.0), "an enemy in contact is in reach")
	t.ok(not BattleAI.in_reach(u, b.units[1], 2.0, 0.0), "an enemy 2 m away is not")
	b.start()
	_run(b, 3.0)
	t.ok(not Fixture.events_of(b, "damage", "normal_attack").is_empty(), "she actually hits the enemy in contact")


func test_star_numbers_show_only_the_current_star(t: TestCtx) -> void:
	var s2: String = Describe.star_text("以 {★50/100/150} 点护盾【增幅 1/2/3】", 2)
	t.ok(s2.contains("★[/color]100") and not s2.contains("150"), "only the 2★ value, marked with a star: %s" % s2)
	t.ok(s2.contains("【增幅 [color=") and s2.contains("★[/color]2】"), "keyword values by star keep the keyword bracket: %s" % s2)
