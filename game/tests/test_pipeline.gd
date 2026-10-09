extends RefCounted
## 触发管线契约测试 + 源项目的四个验收样例("奇葩交叉装备")。

const A0 := Vector2(0, 0)
const D0 := Vector2(2, 0)


func _hit(b: Battle, atk: BUnit, def: BUnit, n: int) -> void:
	for i in range(n):
		b.pipeline.normal_attack(atk, def)


func test_unit_trigger_without_equipment_does_nothing(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "sample_archer", "pos": A0}, {"def": "test_dummy", "team": 1, "pos": D0}])
	_hit(b, b.units[0], b.units[1], 6)
	t.eq(Fixture.events_of(b, "damage", "equipment").size(), 0, "no equipment payload without equipment")
	t.eq(Fixture.events_of(b, "trigger").size(), 0, "trigger without payload produces no trigger feed")


func test_archer_arcane_edge_is_400pct_attack_magic(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "sample_archer", "pos": A0, "equipment": ["sample_arcane_edge"]},
		{"def": "test_dummy", "team": 1, "pos": D0}])
	# 前 5 次普攻：追击副本在第 4 次命中时补 1 次，因此第 6 次"命中事件"会更早出现；统计所有装备伤害
	_hit(b, b.units[0], b.units[1], 8)
	var dmg: Array[Dictionary] = Fixture.events_of(b, "damage", "equipment")
	t.ok(dmg.size() >= 1, "equipment fired")
	t.near(float(dmg[0]["amount"]), 400.0, 0.01, "arcane edge = 4x trigger value(100) magic damage, target mres 0")
	t.eq(dmg[0]["kind"], "magic", "damage kind")


func test_archer_splash_potion_heals_enemy_and_splashes(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "sample_archer", "pos": A0, "equipment": ["sample_splash_potion"]},
		{"def": "test_dummy", "team": 1, "pos": D0, "hp_ratio": 0.5},
		{"def": "test_dummy", "team": 1, "pos": D0 + Vector2(1.0, 0.0), "hp_ratio": 0.5}])
	_hit(b, b.units[0], b.units[1], 8)
	var heals: Array[Dictionary] = Fixture.events_of(b, "heal", "equipment")
	t.ok(heals.size() >= 2, "potion healed target and splash victim")
	t.eq(heals[0]["dst"], b.units[1], "primary heal lands on the ENEMY (odd cross-equip)")
	t.near(float(heals[0]["amount"]), 50.0, 0.01, "50% of trigger value 100")
	var neighbour_heal: Dictionary = {}
	var archer_heal: Dictionary = {}
	for h: Dictionary in heals:
		if h["dst"] == b.units[2] and neighbour_heal.is_empty():
			neighbour_heal = h
		if h["dst"] == b.units[0] and archer_heal.is_empty():
			archer_heal = h
	t.ok(not neighbour_heal.is_empty(), "splash reaches the neighbour")
	t.near(float(neighbour_heal.get("amount", -1.0)), 25.0, 0.01, "splash = half")
	t.ok(not archer_heal.is_empty(), "splash ignores teams: the archer standing in the radius is healed too")


func test_darkknight_splash_potion_heals_self(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "sample_darkknight", "pos": A0, "equipment": ["sample_splash_potion"], "hp_ratio": 0.5},
		{"def": "test_hitter", "team": 1, "pos": D0}])
	_hit(b, b.units[1], b.units[0], 3)
	var heals: Array[Dictionary] = Fixture.events_of(b, "heal", "equipment")
	t.ok(heals.size() >= 1, "equipment heal on 3rd hit taken")
	t.eq(heals[0]["dst"], b.units[0], "heals himself")
	# 第 2 次受击叠 +10 防御 → 第 3 次受击触发值 = (100+10)*0.5 = 55，魔药 50% → 27.5
	t.near(float(heals[0]["amount"]), 27.5, 0.01, "0.5*(defense 110)*0.5")


func test_darkknight_arcane_edge_hurts_himself(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "sample_darkknight", "pos": A0, "equipment": ["sample_arcane_edge"]},
		{"def": "test_hitter", "team": 1, "pos": D0}])
	_hit(b, b.units[1], b.units[0], 3)
	var dmg: Array[Dictionary] = Fixture.events_of(b, "damage", "equipment")
	t.eq(dmg.size(), 1, "one equipment damage instance")
	t.eq(dmg[0]["dst"], b.units[0], "he damages himself")
	# 原始伤害 = 4 * 55 = 220 = 2x defense(110)；魔抗 40 → 220*100/140
	t.near(float(dmg[0]["amount"]), 220.0 * 100.0 / 140.0, 0.05, "2x defense magic damage after mitigation")


func test_stacking_caps(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "sample_darkknight", "pos": A0}, {"def": "test_hitter", "team": 1, "pos": D0}])
	_hit(b, b.units[1], b.units[0], 20)
	t.eq(b.units[0].status_stacks("sample_darkknight_defense"), 3, "[stacking 3] caps at 3")


func test_equipment_color_compat(t: TestCtx) -> void:
	# 单色装 → 本色 + 白；紫装 → 紫红蓝白；黄装 → 黄红绿白；青装 → 青蓝绿白；黑装万用
	t.ok(GC.equipment_fits_faction("red", "red"), "red on red")
	t.ok(GC.equipment_fits_faction("red", "white"), "red on white")
	t.ok(not GC.equipment_fits_faction("red", "blue"), "red not on blue")
	t.ok(GC.equipment_fits_faction("purple", "red") and GC.equipment_fits_faction("purple", "blue"), "purple on red/blue")
	t.ok(not GC.equipment_fits_faction("purple", "green"), "purple not on green")
	t.ok(GC.equipment_fits_faction("yellow", "green") and GC.equipment_fits_faction("yellow", "red"), "yellow on green/red")
	t.ok(GC.equipment_fits_faction("cyan", "blue") and GC.equipment_fits_faction("cyan", "green"), "cyan on blue/green")
	t.ok(GC.equipment_fits_faction("black", "purple") and GC.equipment_fits_faction("black", "yellow"), "black on anything")
	t.ok(not GC.equipment_fits_faction("white", "red"), "white only on white")


func test_trait_counting_uses_mixed_color_contributions(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var purple := UnitDef.from_dict({"id": "t_purple", "faction_id": "purple", "base_weapon_class": "sword", "base_stats": {"max_health": 10}})
	var yellow := UnitDef.from_dict({"id": "t_yellow", "faction_id": "yellow", "base_weapon_class": "sword", "base_stats": {"max_health": 10}})
	var black := UnitDef.from_dict({"id": "t_black", "faction_id": "black", "base_weapon_class": "sword", "base_stats": {"max_health": 10}})
	var rep: Array[Dictionary] = TraitRuntime.compute(cat, [purple, yellow, black])
	var by: Dictionary = {}
	for r: Dictionary in rep:
		by[(r["trait"] as TraitDef).id] = r
	# 红：紫+黄+黑 都贡献 → 3 个不同单位；蓝：紫+黑 → 2；绿：黄+黑 → 2；黄：黄+黑 → 2
	t.eq(int(by["faction_red"]["count"]), 3, "red counts purple+yellow+black")
	t.eq(int(by["faction_blue"]["count"]), 2, "blue counts purple+black")
	t.eq(int(by["faction_green"]["count"]), 2, "green counts yellow+black")
	t.eq(int(by["faction_yellow"]["count"]), 2, "yellow counts yellow+black")
	# 重复单位不重复计数，但每个副本都是受益者
	var a1 := cat.get_unit("node_archer")
	var rep2: Array[Dictionary] = TraitRuntime.compute(cat, [a1, a1, a1])
	t.eq(int(rep2[0]["count"]), 1, "duplicates count once")
	t.eq((rep2[0]["beneficiary_idx"] as Array).size(), 3, "all copies benefit")


func test_content_contract_validation(t: TestCtx) -> void:
	var cat: Catalog = Catalog.load_all()
	var errs: Array[String] = cat.validate_all()
	# 只检查"契约"类错误(本地化键缺失另有测试)
	var contract: Array[String] = []
	for e: String in errs:
		if not e.contains("loc key"):
			contract.append(e)
	t.eq(contract.size(), 0, "content contract errors: %s" % str(contract))
