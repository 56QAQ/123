extends RefCounted
## 无我节点：逆时幻影(【追击 x】【召唤】：普攻连续攻击；她普攻时幻影也普攻一次——以她的普攻计算；幻影被消灭后在下一次普攻之后再召唤)、
## 无我(备战按钮：移除仓库里一个无我节点 → 下一场开战移除普通敌人、精英 / 首领失去 y% 生命上限)；
## 专武杀(【觉醒：场上仅剩一个敌人】【永恒】【学习】【固定值】：召唤物移除 / 其他人削 n1% 生命上限；学习计数累计到 n2 → 降一星 / 一星移除)。


func _def() -> UnitDef:
	return Fixture.catalog().get_unit("node_killer")


func _calm(v: BUnit) -> void:
	v.attack_cd = 1.0e9
	v.base.move_speed = 0.0
	v.base.crit_chance = 0.0
	v.mark_dirty()


func _run(b: Battle, sec: float) -> void:
	while b.time < sec - 0.0001 and b.state != "ended":
		b.step()


func _phantoms(b: Battle, k: BUnit) -> Array:
	return b.units.filter(func(u: BUnit) -> bool: return u.alive and u.meta.get("phantom_of") == k)


func _hits_on(b: Battle, src: BUnit, dst: BUnit) -> int:
	var n := 0
	for e: Dictionary in Fixture.events_of(b, "damage", "normal_attack"):
		if e["src"] == src and e["dst"] == dst:
			n += 1
	return n


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = _def()
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model], [4, "green", "security", "warrior", "heavy", "killer"],
		"rarity 4, green, Security, warrior, two-handed heavy, killer model")
	t.eq(d.weapon_classes, ["heavy", "sword"] as Array[String], "can equip one-hand melee")
	var e: EquipmentDef = cat.get_equipment("kill_blade")
	t.eq([e.class_id, e.color_id, e.cost, e.owner, e.model], ["heavy", "black", 4, "node_killer", "odachi"], "Kill: heavy, black, 4, hers, ōdachi")
	var ab: AbilityDef = e.abilities[0]
	t.ok(ab.ability_class == "bullet" and ab.has_keyword("awakening") and ab.has_keyword("eternal") and ab.has_keyword("learning")
		and ab.keyword_value("multi_attack", 1) == 9, "【Basic】【Awakening】【Eternal】【Learning】【Fixed】【Multi 9】")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_pursuit_and_phantom(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_killer", "pos": Vector2(0, -0.6)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.6)}])
	var k: BUnit = b.units[0]
	var d: BUnit = b.units[1]
	b.start()
	_calm(k)
	_run(b, GC.START_DELAY + 0.05)
	t.eq(Pipeline.kw_value(k, k.na_payload(), "pursuit", 0), 1, "★1: 【Pursuit 1】 on her normal attack")
	b.events.clear()
	b.deliver_normal_attack(k, d, false, {})
	t.eq(_phantoms(b, k).size(), 1, "first attack: a phantom appears next to her target")
	var ph: BUnit = _phantoms(b, k)[0]
	t.ok(ph.is_summon and ph.get_stats().max_health <= 1.01 and ph.pos.distance_to(d.pos) < 2.0, "summoned, 1 health, beside the target")
	_run(b, b.time + 0.5)
	var base_hits: int = _hits_on(b, k, d)
	b.events.clear()
	b.deliver_normal_attack(k, d, false, {})
	_run(b, b.time + 0.5)
	t.eq(_hits_on(b, k, d), base_hits + 1, "with the phantom out, each attack lands one more hit — counted as hers")
	t.eq(Fixture.events_of(b, "phantom_strike").size(), 1, "the phantom swings")
	ph.hp = 0.0
	b.pipeline.fx.try_kill(ph, d)
	t.eq(_phantoms(b, k).size(), 0, "phantom destroyed")
	b.deliver_normal_attack(k, d, false, {})
	t.eq(_phantoms(b, k).size(), 1, "it comes back after her next attack")


func test_kill_awakens_with_one_enemy_left(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_killer", "pos": Vector2(0, -0.6), "weapon": "kill_blade"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.6)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(4, 6)}])
	var k: BUnit = b.units[0]
	var d: BUnit = b.units[1]
	b.start()
	_calm(k)
	_run(b, GC.START_DELAY + 0.05)
	var mh0: float = d.get_stats().max_health
	b.pipeline.normal_attack(k, d, true)
	t.near(d.get_stats().max_health, mh0, 0.01, "two enemies left: Kill is still asleep")
	b.units[2].hp = 0.0
	b.pipeline.fx.try_kill(b.units[2], k)
	b.pipeline.normal_attack(k, d, true)
	var pct: float = float(Fixture.catalog().get_equipment("kill_blade").abilities[0].effect_config["pct"])
	t.near(d.get_stats().max_health, mh0 * (1.0 - pct), 1.0, "only one enemy left: each hit removes %d%% of its max health" % int(pct * 100.0))
	var ab_id: String = Fixture.catalog().get_equipment("kill_blade").abilities[0].id
	t.eq(int(k.learning.get(ab_id, 0)), 1, "learning +1")


func test_kill_removes_summons(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_killer", "pos": Vector2(0, -0.6), "weapon": "kill_blade"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.6)}])
	var k: BUnit = b.units[0]
	b.start()
	_calm(k)
	_run(b, GC.START_DELAY + 0.05)
	var s: BUnit = b.spawn_unit(Fixture.catalog().get_unit("test_dummy"), 1, 1, Vector2(1, 0.6), true)
	b.units[1].hp = 0.0
	b.pipeline.fx.try_kill(b.units[1], k)
	b.pipeline.normal_attack(k, s, true)
	t.ok(not s.alive, "the last enemy is a summon: removed outright")


func test_selfless_battle_start(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var b := Battle.new(cat, 5)
	b.setup({"units": [{"def": "node_killer", "team": 0, "pos": Vector2(0, -3), "star": 2, "selfless": true},
		{"def": "test_dummy", "team": 1, "pos": Vector2(-2, 5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(2, 5)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 6), "elite": true}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 8), "boss": true}],
		"map": {"truck": false}, "cfg": {}})
	var elite: BUnit = b.units[3]
	var boss: BUnit = b.units[4]
	var mh_e: float = elite.get_stats().max_health
	var mh_b: float = boss.get_stats().max_health
	b.start()
	_run(b, GC.START_DELAY + 0.05)
	t.ok(not b.units[1].alive and not b.units[2].alive, "Selfless: every normal enemy is gone at the start")
	var y: float = float(_def().passive_by_id("node_killer_selfless").effect_config["cut_by_star"]["2"])
	t.near(elite.get_stats().max_health, mh_e * (1.0 - y), 1.0, "★2: the elite loses %d%% max health" % int(y * 100.0))
	t.near(boss.get_stats().max_health, mh_b * (1.0 - y), 1.0, "and so does the boss")
	t.eq(Fixture.events_of(b, "selfless_draw").size(), 1, "she draws her blade")


func test_selfless_button_in_run(t: TestCtx) -> void:
	var r := Run.create(Fixture.catalog(), 9)
	r.travel()
	t.eq(r.phase, "prepare", "preparing")
	var on_board: Dictionary = r.add_unit("node_killer", 2, null, r.free_bench_slot())
	var first: String = str(r.board_units()[0]["id"])
	var spot: Vector2i = r.roster[first]["cell"]
	r.sell(first)                                  # 腾出一个场上的位置
	r.move_unit(str(on_board["id"]), {"cell": spot})
	var rid: String = str(on_board["id"])
	t.ok(r.roster[rid]["cell"] != null, "she is on the board")
	t.eq(r.selfless_buttons(), {}, "no other Node Killer in storage: no button")
	var low: Dictionary = r.add_unit("node_killer", 1, null, r.free_bench_slot())
	var high: Dictionary = r.add_unit("node_killer", 2, null, r.free_bench_slot())
	t.eq(r.selfless_buttons(), {rid: false}, "another one in storage: the button shows")
	t.ok(r.selfless(rid)["ok"], "press it")
	t.ok(not r.roster.has(str(low["id"])) and r.roster.has(str(high["id"])), "the lowest-star one in storage is removed")
	t.eq(r.selfless_buttons(), {rid: true}, "button now reads 'ready'")
	t.eq(str(r.selfless(rid)["reason"]), "ui.err.selfless_ready", "can't stack it")
	var mine: Array = (r.build_battle_setup()["units"] as Array).filter(func(e: Dictionary) -> bool: return str(e.get("roster_id", "")) == rid)
	t.ok(not mine.is_empty() and bool(mine[0]["selfless"]), "the next battle's setup carries it")


func test_kill_curse_drops_stars(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var r := Run.create(cat, 9)
	var u: Dictionary = r.add_unit("node_killer", 2, null, r.free_bench_slot())
	u["weapon"] = "kill_blade"
	var ab: AbilityDef = cat.get_equipment("kill_blade").abilities[0]
	var at: int = int(ab.effect_config["curse_at"])
	u["learning"] = {ab.id: at + 3}
	var cs: Array = r._settle_curses()
	t.eq(int(u["star"]), 1, "learning reached %d: she permanently loses a star" % at)
	t.eq(int(u["learning"][ab.id]), 3, "the count carries the rest over")
	u["learning"][ab.id] = at
	r._settle_curses()
	t.ok(not r.roster.has(str(u["id"])), "at 1 star: she is removed")
	t.ok(r.inventory.has("kill_blade"), "and Kill goes back to the armory")


func test_sheathed_and_drawn_animations(t: TestCtx) -> void:
	var lib: AnimationLibrary = load("res://assets/archer_anims.res") as AnimationLibrary
	var wc: Dictionary = GC.weapon_class("heavy")
	for nm: String in ["attack_killer_sheathed", "attack_killer_drawn"]:
		t.ok(lib.has_animation(nm) and absf(lib.get_animation(nm).length - float(wc["interval"])) < 0.02, nm + ": one heavy attack long")
	for nm2: String in ["whirl_killer_sheathed", "whirl_killer_drawn"]:
		t.ok(lib.has_animation(nm2) and absf(lib.get_animation(nm2).length - float((wc["multi"] as Dictionary)["interval"])) < 0.02, nm2 + ": one whirl long")
	for nm3: String in ["draw_killer", "fidget_killer", "victory_killer"]:
		t.ok(lib.has_animation(nm3), nm3 + " baked")
	var look: Dictionary = UnitSkin.look_for(_def(), Fixture.catalog().get_equipment("kill_blade"))
	t.eq(UnitSkin.anim(look, "attack"), "attack_killer_sheathed", "with Kill: she swings the scabbard")
	UnitSkin.set_weapon_model(look, _def(), "odachi_drawn")
	t.eq(UnitSkin.anim(look, "attack"), "attack_killer_drawn", "drawn: the real cut")
	var look2: Dictionary = UnitSkin.look_for(_def(), Fixture.catalog().get_equipment("basic_heavy"))
	t.eq(UnitSkin.anim(look2, "attack"), "attack_heavy", "any other heavy weapon: the normal heavy swing")
