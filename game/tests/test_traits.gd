extends RefCounted
## 颜色羁绊(第二版)：三基色 → 混合色 → 黑白的计数，红(攻击力 / 普攻伤害)、蓝(法强 / 计时加速)、绿(攻速 / 额外叠层)、
## 紫(每隔几秒蓄能，下一次普攻附带魔法伤害)、黄(每次普攻 / 技能伤害叠攻击力)、青(每隔几秒叠攻速法强，4 档再给别的叠加增益 +1 层)；
## 以及新的升级曲线(最高 8 级、5 级起商店出 4 费)。


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


func _team(ids: Array, enemy: String = "test_dummy") -> Battle:
	var specs: Array = []
	for i in range(ids.size()):
		specs.append({"def": ids[i], "pos": Vector2(-3.0 + 1.5 * float(i), -5.0)})
	specs.append({"def": enemy, "team": 1, "pos": Vector2(0, 5)})
	var b := Battle.new(Fixture.catalog(), 7)
	var list: Array = []
	for s: Dictionary in specs:
		list.append({"def": s["def"], "team": s.get("team", 0), "star": 1, "pos": s["pos"], "weapon": ""})
	b.setup({"units": list, "map": {"truck": false}, "cfg": {"potion_variance": false}})
	return b


func _tier(b: Battle, tid: String) -> int:
	for r: Dictionary in b.trait_reports.get(GC.TEAM_PLAYER, []):
		if (r["trait"] as TraitDef).id == tid:
			return int(r["tier"])
	return 0


func test_six_traits_follow_the_three_tier_counting(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	for c: String in ["red", "blue", "green", "purple", "yellow", "cyan"]:
		t.ok(cat.traits.has("faction_" + c), "faction_%s exists" % c)
	t.eq((cat.traits["faction_red"] as TraitDef).thresholds, [2, 4, 6] as Array[int], "primaries: 2 / 4 / 6")
	t.eq((cat.traits["faction_purple"] as TraitDef).thresholds, [2, 4] as Array[int], "mixed: 2 / 4")
	# 速射(红) + 改修(紫) + 灭罪(黄) + 求知(蓝)：红 3(红紫黄)、蓝 2(蓝紫)、绿 1(黄)、紫 1、黄 1
	var defs: Array = []
	for id: String in ["node_archer", "node_tinker", "node_absolver", "node_student"]:
		defs.append(cat.get_unit(id))
	var by := {}
	for r: Dictionary in TraitRuntime.compute(cat, defs):
		by[(r["trait"] as TraitDef).id] = r
	t.eq([int(by["faction_red"]["count"]), int(by["faction_blue"]["count"]), int(by["faction_green"]["count"]),
		int(by["faction_purple"]["count"]), int(by["faction_yellow"]["count"])], [3, 2, 1, 1, 1], "red counts purple + yellow, blue counts purple, green counts yellow")
	t.ok(not by.has("faction_cyan"), "nobody counts toward cyan")
	t.eq((by["faction_red"]["beneficiary_idx"] as Array).size(), 3, "everyone counted benefits (the purple node gets Red and Blue)")


func test_red_attack_and_normal_attack_damage(t: TestCtx) -> void:
	var b := _team(["node_archer", "node_darkknight"])
	b.start()
	var a: BUnit = b.units[0]
	t.eq(_tier(b, "faction_red"), 2, "red 2")
	t.near(a.get_stats().attack_power, a.def.base_stats.attack_power * 1.08, 0.01, "+8% attack")
	t.near(a.get_stats().na_damage_pct, 0.10, 0.0001, "+10% normal-attack damage")


func test_blue_haste_speeds_up_timers_and_cooldowns(t: TestCtx) -> void:
	var b := _team(["node_shielder", "node_student"])
	b.start()
	t.eq(_tier(b, "faction_blue"), 2, "blue 2")
	t.near(b.units[1].get_stats().haste, 0.05, 0.0001, "+5% haste")
	t.near(b.units[1].get_stats().ability_power, 8.0, 0.01, "+8 AP")
	# 计时加速 ×2：每 5 秒的墨刃 2.5 秒一次，逆光的 8 秒冷却变成 4 秒
	var b2 := Fixture.make([{"def": "node_knight_errant", "pos": Vector2(0, -1), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.2)}])
	var k: BUnit = b2.units[0]
	b2.start()
	k.base.haste = 1.0
	k.mark_dirty()
	var evs: Array[Dictionary] = _run(b2, GC.START_DELAY + 5.3)
	var ink := 0
	for e: Dictionary in _of(evs, "damage"):
		if str(e.get("ability", "")) == "node_ke_ink":
			ink += 1
	t.eq(ink, 2, "an every-5-s effect fires every 2.5 s at +100% haste")
	var ab: AbilityDef = null
	for pa: AbilityDef in k.def.passives:
		if pa.id == "node_ke_backlight":
			ab = pa
	k.ability_charges[ab.id] = 1
	b2.pipeline._commit(k, ab)
	t.near(float(k.ability_cd[ab.id]) - b2.time, 4.0, 0.001, "an 8 s cooldown takes 4 s")


func test_green_attack_speed_and_extra_stacks(t: TestCtx) -> void:
	var b := _team(["node_peasant", "node_taoist", "node_cowboy", "node_samurai"])
	b.start()
	t.eq(_tier(b, "faction_green"), 4, "green 4")
	var u: BUnit = b.units[3]
	t.near(u.get_stats().attack_speed_multiplier, u.def.base_stats.attack_speed_multiplier * 1.2, 0.0001, "+20% attack speed")
	t.near(u.get_stats().extra_stacks, 1.0, 0.0001, "【Stacking】 statuses applied gain +1 stack")
	var st: BStatus = b.pipeline.fx.apply_status(u, u, {"status_id": "t_stack", "max_stacks": 5, "flags": ["buff"]})
	t.eq(st.stacks, 2, "(applying one gives two)")


func test_purple_charges_the_next_normal_attack(t: TestCtx) -> void:
	var b := _team(["node_tinker", "node_magi"])
	b.start()
	t.eq([_tier(b, "faction_purple"), _tier(b, "faction_red"), _tier(b, "faction_blue")], [2, 2, 2], "two purple nodes: Purple 2, Red 2 and Blue 2")
	var tk: BUnit = b.units[0]
	tk.attack_cd = 1.0e9
	_run(b, GC.START_DELAY + 5.1)
	t.ok(tk.statuses.has("purple_charge"), "charged after 5 s")
	var st: StatBlock = tk.get_stats()
	var want: float = (st.attack_power + st.ability_power) * 0.5
	var foe: BUnit = b.units[2]
	b.poll_events()
	b.pipeline.normal_attack(tk, foe)
	var got := 0.0
	for e: Dictionary in _of(b.poll_events(), "damage"):
		if str(e.get("ability", "")) == "purple_faction_strike":
			got += float(e["amount"])
			t.eq(e["kind"], "magic", "magic damage")
	t.near(got, want, 0.5, "the next normal attack adds (attack + AP) × 50%")
	t.ok(not tk.statuses.has("purple_charge"), "and uses the charge up")


func test_yellow_edge_stacks_on_hits(t: TestCtx) -> void:
	var b := _team(["node_commando", "node_sniper"])
	b.start()
	t.eq(_tier(b, "faction_yellow"), 2, "yellow 2")
	var c: BUnit = b.units[0]
	var foe: BUnit = b.units[2]
	# (两只黄色也让红色羁绊到 2 档：攻击力 +8%，和金锐的百分比加在一起)
	for i in range(3):
		b.pipeline.fx.damage(c, foe, 10.0, "physical", {"surface": "normal_attack"})
	b.pipeline.drain()
	t.eq(c.status_stacks("yellow_edge"), 3, "one stack per hit")
	t.near(c.get_stats().attack_power, c.base.attack_power * (1.0 + 0.08 + 0.015 * float(c.status_stacks("yellow_edge"))), 0.05,
		"+1.5% attack each (same pct pool as Red's +8%)")
	b.pipeline.fx.damage(c, foe, 10.0, "magic", {"surface": "status", "cfg": {"damage_category": "dot"}})
	b.pipeline.drain()
	t.eq(c.status_stacks("yellow_edge"), 3, "damage over time doesn't count")
	for i in range(20):
		b.pipeline.fx.damage(c, foe, 10.0, "physical", {"surface": "normal_attack"})
	b.pipeline.drain()
	t.eq(c.status_stacks("yellow_edge"), 8, "up to 8 stacks")


func test_cyan_tide_and_surge(t: TestCtx) -> void:
	var b := _team(["node_leader", "node_perfume", "node_knight_errant", "node_vampire"])
	b.start()
	t.eq([_tier(b, "faction_cyan"), _tier(b, "faction_blue"), _tier(b, "faction_green")], [4, 4, 4], "four cyan nodes: Cyan 4, Blue 4 and Green 4")
	var v: BUnit = b.units[3]
	for u: BUnit in b.units:
		u.attack_cd = 1.0e9
	var bst: BStatus = b.pipeline.fx.apply_status(v, v, {"status_id": "t_buff", "max_stacks": 9, "flags": ["buff"]})
	var n0: int = bst.stacks
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 4.4)
	t.ok(v.status_stacks("cyan_tide") >= 2, "a Tide stack every 2 s (faster with Blue's haste): %d" % v.status_stacks("cyan_tide"))
	var surged := false
	for e: Dictionary in _of(evs, "tide_surge"):
		if e["unit"] == v:
			surged = true
	t.ok(surged and v.status_stacks("t_buff") > n0, "every 4 s (faster with haste): his other stacking buffs gain a stack (%d → %d)" % [n0, v.status_stacks("t_buff")])


func test_level_curve_reaches_eight_and_sells_four_costs(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var r := Run.create(cat, 11)
	t.eq(r.max_level(), 8, "max level 8")
	var odds: Dictionary = (r.shop_rule["odds_by_level"] as Dictionary)
	t.ok(not (odds["4"] as Dictionary).has("4") and (odds["5"] as Dictionary).has("4"), "4-costs show up from level 5")
	t.eq(int((odds["5"] as Dictionary)["4"]), 1, "4-costs start at 1% at level 5")
	for lv in range(1, 9):
		var row: Dictionary = odds[str(lv)]
		var sum := 0.0
		for k: String in row.keys():
			sum += float(row[k])
		t.ok(absf(sum - 100.0) < 0.001, "level %d odds sum to 100" % lv)
		if lv > 1:
			var prev: Dictionary = odds[str(lv - 1)]
			t.ok(float(row.get("1", 0)) <= float(prev.get("1", 0)), "level %d: 1-cost odds never go up" % lv)
			t.ok(float(row.get("4", 0)) >= float(prev.get("4", 0)), "level %d: 4-cost odds never go down" % lv)
	r.level = 5
	var four5 := 0
	for i5 in range(400):
		r.roll_shop(false)
		for o5: Dictionary in r.shop:
			if cat.get_unit(str(o5["def"])).cost == 4:
				four5 += 1
	t.ok(four5 >= 5 and four5 <= 50, "level 5: about 1%% of 2000 slots are 4-costs (%d)" % four5)
	r.level = 8
	var four := 0
	for i in range(60):
		r.roll_shop(false)
		for o: Dictionary in r.shop:
			if cat.get_unit(str(o["def"])).cost == 4:
				four += 1
	t.ok(four > 40, "level 8 shops offer 4-cost nodes (%d in 300 slots)" % four)
	t.eq(int((r.shop_rule["sell_refund_by_cost"] as Dictionary)["4"]), 4, "4-costs sell back for 4")
