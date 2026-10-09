extends RefCounted
## 车间：三种材料、按配比/用量的产出概率、制造、分解、晶球附带的材料。

const ALL_W := ["sword", "heavy", "polearm", "dual", "bow", "crossbow", "rifle", "pistols", "focus"]


func _run() -> Run:
	var r: Run = Run.create(Fixture.catalog(), 4242)
	r.materials = {"red": 40, "green": 40, "blue": 40}
	return r


func _mats(r: int, g: int, b: int) -> Dictionary:
	return {"red": r, "green": g, "blue": b}


func _sum(d: Dictionary) -> float:
	var s := 0.0
	for k: Variant in d.keys():
		s += float(d[k])
	return s


func _best(d: Dictionary) -> String:
	var best := ""
	for k: Variant in d.keys():
		if best == "" or float(d[k]) > float(d[best]):
			best = str(k)
	return best


func test_start_materials_and_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var r: Run = Run.create(cat, 7)
	t.eq(r.materials, {"red": 2, "green": 2, "blue": 2}, "a new run starts with 2 of each material")
	t.eq(Crafting.MATS, ["red", "green", "blue"], "three materials, internal names red / green / blue")
	t.eq(cat.validate_all().filter(func(e: String) -> bool: return e.begins_with("workshop")), [], "workshop data validates")
	var kinds: Array = Crafting.kinds(cat)
	t.eq(str(kinds[0]["id"]), "weapon", "weapons are the first equipment kind")
	t.ok((kinds[0]["categories"] as Array).size() >= 3, "at least three weapon categories to choose from")
	t.ok(kinds.size() >= 2 and bool(kinds[1].get("locked", false)), "a locked placeholder kind keeps the interface for other gear")
	t.eq(Crafting.candidates(cat, "gear", ["sword"]).size(), 0, "a locked kind has nothing to make")


func test_forecast_is_a_distribution_over_the_chosen_categories(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var cats := ["dual", "focus", "polearm"]
	var f: Dictionary = Crafting.forecast(cat, "weapon", cats, _mats(4, 2, 1))
	t.near(_sum(f["colors"]), 1.0, 0.0001, "color odds sum to 1")
	t.near(_sum(f["costs"]), 1.0, 0.0001, "rarity odds sum to 1")
	var ps := 0.0
	for it: Array in f["items"]:
		ps += float(it[1])
		t.ok(cats.has(cat.get_equipment(str(it[0])).class_id), "%s is in a chosen category" % str(it[0]))
		t.ok(not str(it[0]).begins_with("sample_") and not cat.get_equipment(str(it[0])).basic, "no basic / sample weapons")
	t.near(ps, 1.0, 0.0001, "item odds sum to 1")


func test_the_mix_decides_the_color_smoothly(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	# 颜色权重本身(不看有没有这种颜色的武器)：纯色 → 该色；两两等量 → 二次色；三者等量 → 黑(无色)或二次色
	t.eq(_best(Crafting.color_weights(cat, _mats(9, 0, 0))), "red", "pure phlogiston → red")
	t.eq(_best(Crafting.color_weights(cat, _mats(0, 9, 0))), "green", "pure organics → green")
	t.eq(_best(Crafting.color_weights(cat, _mats(0, 0, 9))), "blue", "pure negentropy → blue")
	t.eq(_best(Crafting.color_weights(cat, _mats(5, 5, 0))), "yellow", "red + green → yellow")
	t.eq(_best(Crafting.color_weights(cat, _mats(5, 0, 5))), "purple", "red + blue → purple")
	t.eq(_best(Crafting.color_weights(cat, _mats(0, 5, 5))), "cyan", "green + blue → cyan")
	var bal: Dictionary = Crafting.color_weights(cat, _mats(4, 4, 4))
	t.ok(float(bal["black"]) > float(bal["red"]) * 5.0, "an even mix makes colorless (black) gear likely, a single color unlikely")
	# 平滑：把 1 份燃素换成有机物，红色的概率只变一点点；一路换过去单调下降
	var all_cats: Array = ALL_W
	var prev := 2.0
	var max_jump := 0.0
	for g in range(0, 13):
		var f: Dictionary = Crafting.forecast(cat, "weapon", all_cats, _mats(24 - g, g, 0))
		var pr: float = float((f["colors"] as Dictionary).get("red", 0.0))
		t.ok(pr <= prev + 1e-6, "red odds fall as phlogiston is swapped for organics (%d → %.3f)" % [g, pr])
		if prev <= 1.0:
			max_jump = maxf(max_jump, prev - pr)
		prev = pr
	t.ok(max_jump < 0.15, "…and never jump by more than 15 points for one swapped unit (max %.3f)" % max_jump)
	var pure: Dictionary = Crafting.forecast(cat, "weapon", all_cats, _mats(12, 0, 0))
	t.ok(float((pure["colors"] as Dictionary)["red"]) > 0.6, "pure phlogiston with every category: mostly red (%.2f)" % float((pure["colors"] as Dictionary)["red"]))


func test_the_amount_decides_the_rarity(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var prev := 0.0
	for n: int in [3, 6, 10, 14, 18, 24, 30]:
		var f: Dictionary = Crafting.forecast(cat, "weapon", ALL_W, _mats(n - 2 * (n / 3), n / 3, n / 3))
		var ev := 0.0
		for k: Variant in (f["costs"] as Dictionary).keys():
			ev += float(k) * float(f["costs"][k])
		t.ok(ev >= prev - 1e-6, "more materials → pricier on average (N=%d → %.2f)" % [n, ev])
		prev = ev
	var low: Dictionary = Crafting.forecast(cat, "weapon", ALL_W, _mats(1, 1, 1))
	# (预测按"颜色 × 费用"的格子分权重：每多一种颜色 / 费用组合的装备，便宜那档的占比就会被稀释一点；新心音节点的黄色 2 费弓之后约 69.5%，
	#  2026-10-07 又多了蓝 3(大锤)、绿 4(翠绿之林)、白 2(匕首与金币)几格之后约 64.8%；2026-10-09 通用武器铺满 162 格的计划里紫 2 那一格出现后约 59.6%。
	#  稀释有上限：每个费用最多 8 种颜色(6 彩 + 黑白)的格子，现在 2 / 3 费已经齐了、4 费只差白色——往已有的格子里加武器不再稀释。)
	t.ok(float((low["costs"] as Dictionary).get(1, 0.0)) > 0.55, "3 materials: mostly cost 1 (%.3f)" % float((low["costs"] as Dictionary).get(1, 0.0)))
	var high: Dictionary = Crafting.forecast(cat, "weapon", ALL_W, _mats(6, 5, 6))
	t.ok(float((high["costs"] as Dictionary).get(3, 0.0)) > 0.5, "17 materials: mostly cost 3")
	t.ok(float((high["costs"] as Dictionary).get(1, 0.0)) < 0.02, "…and almost never cost 1")


func test_craft_checks_the_inputs(t: TestCtx) -> void:
	var r: Run = _run()
	t.eq(str(r.craft("weapon", ["sword", "heavy"], _mats(3, 0, 0))["reason"]), "ui.err.craft_categories", "at least three categories")
	t.eq(str(r.craft("weapon", ["sword", "heavy", "dual"], _mats(1, 1, 0))["reason"]), "ui.err.craft_too_few", "at least 3 materials")
	t.eq(str(r.craft("weapon", ["sword", "heavy", "dual"], _mats(41, 0, 0))["reason"]), "ui.err.craft_materials", "can't spend materials you don't have")
	t.eq(str(r.craft("weapon", ["sword", "heavy", "dual"], _mats(20, 11, 0))["reason"]), "ui.err.craft_too_many", "at most 30 at once")
	t.eq(str(r.craft("gear", ["sword", "heavy", "dual"], _mats(3, 0, 0))["reason"]), "ui.err.craft_locked", "other gear isn't open yet")
	r.phase = "battle"
	t.eq(str(r.craft("weapon", ["sword", "heavy", "dual"], _mats(3, 0, 0))["reason"]), "ui.err.not_now", "not during a battle")


func test_craft_spends_materials_and_fills_the_armory(t: TestCtx) -> void:
	var r: Run = _run()
	var inv0: int = r.inventory.size()
	var cats := ["dual", "focus", "polearm"]
	var res: Dictionary = r.craft("weapon", cats, _mats(5, 2, 1))
	t.ok(bool(res["ok"]), "crafted")
	t.eq(r.materials, {"red": 35, "green": 38, "blue": 39}, "materials spent")
	t.eq(r.inventory.size(), inv0 + 1, "one more weapon in the armory")
	t.eq(r.inventory.back(), str(res["id"]), "…the crafted one")
	t.ok(cats.has(r.catalog.get_equipment(str(res["id"])).class_id), "from a chosen category")
	t.eq(r.crafted, 1, "craft counter")
	t.eq((r.craft_last["cats"] as Dictionary)["weapon"], cats, "the workshop remembers the categories")
	# 统计：纯燃素 + 有红色武器的门类 → 大多是红色
	var red := 0
	var n := 0
	for i in range(60):
		r.materials = {"red": 40, "green": 40, "blue": 40}
		var res2: Dictionary = r.craft("weapon", ["dual", "focus", "heavy"], _mats(9, 0, 0))
		n += 1
		if r.catalog.get_equipment(str(res2["id"])).color_id == "red":
			red += 1
	t.ok(red >= 35, "pure phlogiston: mostly red weapons (%d / %d)" % [red, n])


func test_salvage_turns_weapons_into_materials(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	t.eq(Crafting.salvage_yield(cat, "frenzy_daggers"), _mats(2, 0, 0), "red cost 1 → 2 phlogiston")
	t.eq(Crafting.salvage_yield(cat, "order_sword"), _mats(0, 0, 4), "blue cost 2 → 4 negentropy")
	t.eq(Crafting.salvage_yield(cat, "calibration_rifle"), _mats(4, 0, 3), "purple cost 3 → 7 split red / blue")
	t.eq(Crafting.salvage_yield(cat, "energy_halberd"), _mats(0, 4, 3), "cyan cost 3 → split green / blue")
	var blk: Dictionary = Crafting.salvage_yield(cat, "amplifier_crossbow")
	t.eq(Crafting.total(blk), 4, "black cost 2 → 4 in total")
	t.ok(int(blk["red"]) >= 1 and int(blk["green"]) >= 1 and int(blk["blue"]) >= 1, "…spread over all three")
	var r: Run = _run()
	r.inventory.append("fireball_tome")
	var res: Dictionary = r.salvage("fireball_tome")
	t.ok(bool(res["ok"]), "salvaged")
	t.eq(res["gain"], _mats(7, 0, 0), "red cost 3 → 7 phlogiston")
	t.eq(int(r.materials["red"]), 47, "added to the stock")
	t.ok(not r.inventory.has("fireball_tome"), "gone from the armory")
	t.eq(str(r.salvage("fireball_tome")["reason"]), "ui.err.salvage_missing", "can't salvage what you don't have")


func test_orbs_carry_materials(t: TestCtx) -> void:
	var r: Run = Run.create(Fixture.catalog(), 99)
	r.materials = Crafting.empty_mats()
	r.pending_orbs = [{"tier": "white", "pos": Vector2.ZERO, "opened": false, "loot": {}},
		{"tier": "blue", "pos": Vector2.ZERO, "opened": false, "loot": {}},
		{"tier": "gold", "pos": Vector2.ZERO, "opened": false, "loot": {}}]
	var got := 0
	for i in range(3):
		var loot: Dictionary = r.open_orb(i)
		var n: int = Crafting.total(loot["materials"])
		t.eq(n, [1, 2, 3][i], "%s orb: %d material(s)" % [["white", "blue", "gold"][i], [1, 2, 3][i]])
		got += n
	t.eq(r.material_total(), got, "they go straight into the stock")
	# 红之章：燃素多一些
	var r2: Run = Run.create(Fixture.catalog(), 5, "ch1_red")
	var cnt: Dictionary = Crafting.empty_mats()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i2 in range(300):
		var m: Dictionary = Crafting.roll_orb_materials(r2.catalog, "gold", r2.chapter.get("material_weights", {}), rng)
		for k: String in Crafting.MATS:
			cnt[k] = int(cnt[k]) + int(m[k])
	t.ok(int(cnt["red"]) > int(cnt["green"]) + 100 and int(cnt["red"]) > int(cnt["blue"]) + 100, "the red chapter's orbs hold more phlogiston (%s)" % str(cnt))
