extends RefCounted
## 巧运节点：妙手(每次普攻 x% 摸到 1 金币)、真骰(2 星：高稀有度事件更常见；事件里有明确好坏的随机结果重投取好；战斗里自己的概率掷两次取好)、
## 鸿运，大概吧(妙手摸到金币时，目标自身，1/1/2)；专武匕首与金币(【基本】【学习】【永恒】：钱袋——每 2 秒按学习计数的收敛曲线翻倍 / 清空(5% → 25% / 25% → 5%)，战后兑现)。


func _def() -> UnitDef:
	return Fixture.catalog().get_unit("node_rogue")


func _calm(v: BUnit) -> void:
	v.attack_cd = 1.0e9
	v.base.move_speed = 0.0
	v.mark_dirty()


func _run(b: Battle, sec: float) -> void:
	while b.time < sec - 0.0001 and b.state != "ended":
		b.step()


func _x(star: int) -> float:
	return float(_def().passive_by_id("node_rogue_pickpocket").effect_config["chance_by_star"][str(star)])


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = _def()
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model], [2, "white", "information", "assassin", "dual", "rogue"],
		"rarity 2, white, Information, assassin, dual melee, rogue model")
	t.eq(d.weapon_classes, ["dual", "pistols"] as Array[String], "can equip dual ranged")
	t.eq(d.passive_by_id("node_rogue_dice").unlock_star, 2, "Loaded Dice unlocks at 2 stars")
	var e: EquipmentDef = cat.get_equipment("coin_dagger")
	t.eq([e.class_id, e.color_id, e.cost, e.owner, e.model], ["dual", "white", 2, "node_rogue", "coin"], "Dagger & Coin: dual melee, white, 2, his")
	var ab: AbilityDef = e.abilities[0]
	t.ok(ab.has_keyword("basic") and ab.has_keyword("learning") and ab.has_keyword("eternal"), "【Basic】【Learning】【Eternal】")
	t.ok(float(e.pct_mods.get("attack_speed_multiplier", 0.0)) > 0.0, "attack speed")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_pickpocket_rate_and_loaded_dice(t: TestCtx) -> void:
	for star: int in [1, 2]:
		var b := Fixture.make([{"def": "node_rogue", "pos": Vector2(0, -0.5), "star": star}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.5)}])
		var r: BUnit = b.units[0]
		b.start()
		_calm(r)
		_run(b, GC.START_DELAY + 0.05)
		var n := 3000
		for i in range(n):
			b.pipeline.processed_in_step = 0                   # 一帧里连打几千下：别被事件风暴保护截掉
			b.units[1].hp = b.units[1].get_stats().max_health  # 木桩别被打死
			b.pipeline.normal_attack(r, b.units[1], true)       # 副本：不追击，一次一下
		var rate: float = float(b.gold_gain[0]) / float(n)
		var p: float = _x(star)
		var want: float = p if star == 1 else 1.0 - (1.0 - p) * (1.0 - p)
		t.near(rate, want, 0.012, "★%d: %.1f%% gold per hit (want %.1f%%%s))" % [star, rate * 100.0, want * 100.0, ", loaded dice" if star == 2 else ""])


func test_lucky_rolls(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_rogue", "pos": Vector2(0, -3), "star": 2}, {"def": "node_rogue", "pos": Vector2(2, -3), "star": 1},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	b.start()
	_run(b, GC.START_DELAY + 0.05)
	var lucky: BUnit = b.units[0]
	var plain: BUnit = b.units[1]
	t.ok(lucky.has_flag("lucky") and not plain.has_flag("lucky"), "★2 rolls with loaded dice, ★1 doesn't")
	var good := 0
	var bad := 0
	var good0 := 0
	for i in range(4000):
		if b.roll_good(lucky) < 0.3:
			good += 1
		if b.roll_bad(lucky) < 0.3:
			bad += 1
		if b.roll_good(plain) < 0.3:
			good0 += 1
	t.near(good / 4000.0, 0.51, 0.025, "good 30% odds become 51% (crits, dodges, gold…)")
	t.near(bad / 4000.0, 0.09, 0.02, "bad 30% odds become 9% (being interrupted, missing…)")
	t.near(good0 / 4000.0, 0.30, 0.025, "without the dice: 30%")


func test_fortune_fills_the_purse(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_rogue", "pos": Vector2(0, -0.5), "weapon": "coin_dagger"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.5)}])
	var r: BUnit = b.units[0]
	b.start()
	_calm(r)
	_run(b, GC.START_DELAY + 0.05)
	var ab_id: String = Fixture.catalog().get_equipment("coin_dagger").abilities[0].id
	b.pipeline.emit("OnGoldGain", r, r, 1.0, ["gold_gain"], {"source": "node_rogue_pickpocket", "amount": 1})
	var st: BStatus = r.get_status("money_bag")
	t.ok(st != null and int(st.meta["coins"]) == 0, "first gold: gets a Coin Purse (empty)")
	t.ok(st.has_flag("no_dispel"), "can't be dispelled")
	b.pipeline.emit("OnGoldGain", r, r, 1.0, ["gold_gain"], {"source": "node_rogue_pickpocket", "amount": 1})
	b.pipeline.emit("OnGoldGain", r, r, 1.0, ["gold_gain"], {"source": "node_rogue_pickpocket", "amount": 1})
	t.eq(int(r.get_status("money_bag").meta["coins"]), 2, "then +1 per gold at ★1")
	t.eq(int(r.learning.get(ab_id, 0)), 3, "learning +1 each time")
	b.pipeline.emit("OnGoldGain", r, r, 1.0, ["gold_gain"], {"source": "something_else", "amount": 1})
	t.eq(int(r.get_status("money_bag").meta["coins"]), 2, "only Sleight of Hand's gold counts")


func test_purse_odds(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_rogue", "pos": Vector2(0, -3), "weapon": "coin_dagger"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var r: BUnit = b.units[0]
	b.start()
	_calm(r)
	_run(b, GC.START_DELAY + 0.05)
	var ab_id: String = Fixture.catalog().get_equipment("coin_dagger").abilities[0].id
	b.pipeline.emit("OnGoldGain", r, r, 1.0, ["gold_gain"], {"source": "node_rogue_pickpocket", "amount": 1})
	var st: BStatus = r.get_status("money_bag")
	var bag: Dictionary = Fixture.catalog().get_equipment("coin_dagger").abilities[0].effect_config["bag"]
	var tick_cfg: Dictionary = bag["pairs"][0]["ability"]["effect_config"]
	var tick_o: Dictionary = {"cfg": tick_cfg}
	for learn: int in [0, 10, 30]:
		r.learning[ab_id] = learn
		var dbl := 0
		var clr := 0
		for i in range(4000):
			st.meta["coins"] = 10
			b.pipeline._money_bag_tick(r, tick_o)
			if int(st.meta["coins"]) == 20:
				dbl += 1
			elif int(st.meta["coins"]) == 0:
				clr += 1
		var odds: Vector2 = Pipeline.bag_odds(tick_cfg, learn)
		t.near(dbl / 4000.0, odds.x, 0.02, "learning %d: doubles %.1f%%" % [learn, odds.x * 100.0])
		t.near(clr / 4000.0, odds.y, 0.02, "learning %d: empties %.1f%%" % [learn, odds.y * 100.0])
	# 收敛：学习 0 → 5% / 25%，学习 10 → 各 15%，再多也只是无限接近 25% / 5%
	t.near(Pipeline.bag_odds(tick_cfg, 0).x, 0.05, 0.0001, "starts at 5% double")
	t.near(Pipeline.bag_odds(tick_cfg, 0).y, 0.25, 0.0001, "and 25% empty")
	t.near(Pipeline.bag_odds(tick_cfg, 10).x, 0.15, 0.0001, "10 learned: 15% double")
	t.near(Pipeline.bag_odds(tick_cfg, 10).y, 0.15, 0.0001, "and 15% empty")
	var big: Vector2 = Pipeline.bag_odds(tick_cfg, 100000)
	t.ok(big.x < 0.25 and big.x > 0.249 and big.y > 0.05 and big.y < 0.051, "it levels off at 25% / 5% and never passes them")
	var mono := true
	for l: int in range(2, 200):
		var c0: Vector2 = Pipeline.bag_odds(tick_cfg, l - 2)
		var c1: Vector2 = Pipeline.bag_odds(tick_cfg, l - 1)
		var c2: Vector2 = Pipeline.bag_odds(tick_cfg, l)
		mono = mono and c2.x > c1.x and c2.y < c1.y and (c2.x - c1.x) < (c1.x - c0.x)
	t.ok(mono, "each extra learning helps a little less than the one before")


func test_purse_cashes_out_and_learning_carries_over(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var ab_id: String = cat.get_equipment("coin_dagger").abilities[0].id
	var b := Battle.new(cat, 3)
	b.setup({"units": [{"def": "node_rogue", "team": 0, "pos": Vector2(0, -3), "weapon": "coin_dagger", "roster_id": "r7", "learning": {ab_id: 6}},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}], "map": {"truck": false}, "cfg": {}})
	var r: BUnit = b.units[0]
	t.eq(int(r.learning.get(ab_id, 0)), 6, "last battle's learning count comes back")
	b.start()
	_calm(r)
	_run(b, GC.START_DELAY + 0.05)
	b.pipeline.emit("OnGoldGain", r, r, 1.0, ["gold_gain"], {"source": "node_rogue_pickpocket", "amount": 1})
	r.get_status("money_bag").meta["coins"] = 9
	r.hp = 0.0
	b.pipeline.fx.try_kill(r, null)
	var g0: int = int(b.gold_gain[0])
	b.units[1].hp = 0.0
	b._finish(1)
	t.eq(int(b.gold_gain[0]) - g0, 9, "battle over (even after he fell): the purse pays out 9 gold")
	t.ok(r.get_status("money_bag") == null, "and is gone")
	t.eq(int((b.learning_out.get("r7", {}) as Dictionary).get(ab_id, -1)), 7, "learning count written back for the next battle")


func test_loaded_dice_in_events(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var run := Run.create(cat, 5)
	t.eq(run.luck_cfg(), {}, "no rogue: no luck")
	var u: Dictionary = run.add_unit("node_rogue", 1, null, 0)
	t.eq(run.luck_cfg(), {}, "★1 rogue: not yet")
	u["star"] = 2
	t.ok(not run.luck_cfg().is_empty(), "★2 rogue anywhere in the roster: Loaded Dice")
	var ev: Dictionary = cat.events["entropy_well"]
	var drink: Dictionary = {}
	for o: Dictionary in ev["options"]:
		if o["id"] == "drink":
			drink = o
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var boon := 0
	var boon0 := 0
	for i in range(3000):
		if str(Events.roll_outcome(drink, rng, 0, true)["id"]) == "drink_boon":
			boon += 1
		if str(Events.roll_outcome(drink, rng, 0, false)["id"]) == "drink_boon":
			boon0 += 1
	t.near(boon0 / 3000.0, 0.70, 0.03, "plain: 70% boon")
	t.near(boon / 3000.0, 0.91, 0.03, "loaded dice: reroll once, keep the better → 91%")
	var r3: Dictionary = {"rarity": 3}
	t.near(Events.rarity_weight(cat, r3, run.luck_cfg()) / Events.rarity_weight(cat, r3), 2.0, 0.001, "rarity-3 events twice as likely to be drawn")
