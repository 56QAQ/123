extends RefCounted
## 第一章·红之章的普通怪物：大罪的余烬(愤怒 / 怠惰 / 色欲 / 暴食)，新的【燃烧】，以及按战斗强度配怪。


func _step(b: Battle, seconds: float) -> void:
	for i in range(int(round(seconds / GC.SIM_DT))):
		b.step()


func _burns(u: BUnit) -> int:
	return u.status_count("burning")


## 只跑状态/触发器，不让单位自己走动打架(木桩没有武器；怪物被缴械)
func _freeze(b: Battle) -> void:
	for u: BUnit in b.units:
		u.attack_cd = 1.0e9


func test_burning_is_independent_and_ticks_25_per_second(t: TestCtx) -> void:
	var b: Battle = Fixture.make([{"def": "test_dummy", "team": 0, "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(4, 0)}])
	b.start()
	var u: BUnit = b.units[0]
	var cfg: Dictionary = (Fixture.catalog().get_unit("mob_ember_wrath").passives[0] as AbilityDef).effect_config.duplicate(true)
	cfg["duration"] = 3.0
	b.pipeline.fx.apply_status(b.units[1], u, cfg)
	b.pipeline.fx.apply_status(b.units[1], u, cfg)
	t.eq(_burns(u), 2, "every application is a separate Burning")
	var st: BStatus = u.status_instances("burning")[0]
	t.ok(st.has_flag("debuff") and st.has_flag("dispellable"), "debuff, dispellable")
	var hp0: float = u.hp
	_step(b, 3.05)
	t.near(hp0 - u.hp, 2.0 * 3.0 * 25.0, 0.5, "two 3 s burnings = 6 ticks × 25 magic damage (0 MR)")
	t.eq(_burns(u), 0, "both burned out")


func test_wrath_spreads_and_releases(t: TestCtx) -> void:
	var b: Battle = Fixture.make([{"def": "mob_ember_wrath", "team": 1, "star": 2, "pos": Vector2(0, 0)},
		{"def": "test_dummy", "team": 0, "pos": Vector2(-3, 2)}, {"def": "test_dummy", "team": 0, "pos": Vector2(3, 2)}])
	b.start()
	_freeze(b)
	_step(b, 3.05)
	var burning := 0
	for u: BUnit in [b.units[1], b.units[2]]:
		burning += _burns(u)
		for st: BStatus in u.status_instances("burning"):
			t.near(st.expires_at - b.time, 7.0 - 0.05, 0.06, "a 7 s burning")
	t.eq(burning, 1, "after 3 s exactly one enemy is set burning")
	_step(b, 1.8)
	# 5 秒：解放引爆在烧的那个(剩 ~5 秒)
	var lit: BUnit = b.units[1] if _burns(b.units[1]) > 0 else b.units[2]
	var hp0: float = lit.hp
	var remain: float = lit.status_instances("burning")[0].expires_at - b.time - 0.2
	_step(b, 0.25)
	var x: float = float(Fixture.catalog().get_unit("mob_ember_wrath").triggers[1].flat_by_star[2])
	t.eq(_burns(lit), 0, "release ends the detonated burning")
	t.near(hp0 - lit.hp, 25.0 * remain * x, 30.0, "release = 25 × remaining seconds × %.0f%% (lost %.0f)" % [x * 100.0, hp0 - lit.hp])
	# 6 秒：延烧挑的是"身上没有燃烧"的敌人
	_step(b, 1.0)
	var other: BUnit = b.units[2] if lit == b.units[1] else b.units[1]
	t.ok(_burns(other) == 1 or _burns(lit) == 1, "the next spread goes to someone not burning")


func test_wrath_release_needs_two_stars(t: TestCtx) -> void:
	var b: Battle = Fixture.make([{"def": "mob_ember_wrath", "team": 1, "star": 1, "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 0, "pos": Vector2(-3, 2)}])
	b.start()
	_freeze(b)
	_step(b, 5.3)
	t.eq(_burns(b.units[1]), 1, "1-star: the 3 s burning is still there at 5 s (no release)")


func test_sloth_warms_up_and_swallows_burning(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var b: Battle = Fixture.make([{"def": "mob_ember_sloth", "team": 1, "star": 2, "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 0, "pos": Vector2(2, 0)}])
	b.start()
	var s: BUnit = b.units[0]
	var d: BUnit = b.units[1]
	t.near(s.get_stats().attack_speed_multiplier, 0.4, 0.001, "starts at -60% attack speed")
	b.pipeline.normal_attack(s, d)
	b.pipeline.normal_attack(s, d)
	t.eq(s.status_stacks("sloth_preheat"), 2, "each normal attack: +1 Preheat")
	t.near(s.get_stats().attack_speed_multiplier, 0.4 + 2.0 * 0.15, 0.001, "2-star: +15% per stack")
	var burn: Dictionary = (cat.get_unit("mob_ember_wrath").passives[0] as AbilityDef).effect_config.duplicate(true)
	for i in range(3):
		b.pipeline.fx.apply_status(null, d, burn)
	t.ok(b.ai._fit_bonus(s, d) > 0.0, "the burning enemy is preferred as a target")
	b.pipeline.normal_attack(s, d)
	t.eq(_burns(d), 0, "Kindle swallows every Burning on the target")
	t.eq(s.status_stacks("sloth_preheat"), 6, "+1 for the attack and +3 for the swallowed burnings")
	for i2 in range(3):
		b.pipeline.fx.apply_status(null, d, burn)
	b.pipeline.normal_attack(s, d)
	t.eq(s.status_stacks("sloth_preheat"), 8, "capped at 8 (Stacking 8)")
	for i3 in range(2):
		b.pipeline.fx.apply_status(null, d, burn)
	b.pipeline.normal_attack(s, d)
	t.eq(_burns(d), 2, "once Preheat is full it stops swallowing")
	t.eq(b.ai._fit_bonus(s, d), 0.0, "and stops hunting burning targets")
	var b1: Battle = Fixture.make([{"def": "mob_ember_sloth", "team": 1, "star": 1, "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 0, "pos": Vector2(2, 0)}])
	b1.start()
	b1.pipeline.fx.apply_status(null, b1.units[1], burn)
	b1.pipeline.normal_attack(b1.units[0], b1.units[1])
	t.eq(_burns(b1.units[1]), 1, "1-star: no Kindle")


func test_lust_entangles_and_both_burn(t: TestCtx) -> void:
	var b: Battle = Fixture.make([{"def": "mob_ember_lust", "team": 1, "star": 1, "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 0, "pos": Vector2(0.9, 0)}])
	b.start()
	var l: BUnit = b.units[0]
	var d: BUnit = b.units[1]
	b.pipeline.normal_attack(l, d)
	for u: BUnit in [l, d]:
		t.eq(u.status_count("lust_bind"), 1, "%s is entangled" % u.def.id)
		t.ok(u.has_flag("rooted") and u.has_flag("no_dispel"), "rooted, can't be dispelled")
	t.ok(l.forced_target == d and d.forced_target == l, "they must target each other")
	_freeze(b)
	_step(b, 2.0)
	t.ok(_burns(d) >= 1 and _burns(l) >= 1, "both gain Burning every second")
	var p0: Vector2 = d.pos
	d.vel = Vector2(3, 0)
	_step(b, 0.5)
	t.ok(d.pos.distance_to(p0) < 0.3, "the entangled can't walk away")
	d.hp = 1.0
	b.pipeline.fx.damage(null, d, 100.0, "true")
	_step(b, 0.1)
	t.eq(l.status_count("lust_bind"), 0, "partner fell: the entanglement ends")
	t.ok(not l.has_flag("rooted"), "free to move again")


func test_lust_regrowth_turns_burning_into_healing(t: TestCtx) -> void:
	var b: Battle = Fixture.make([{"def": "mob_ember_lust", "team": 1, "star": 2, "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 0, "pos": Vector2(6, 0)}])
	b.start()
	_freeze(b)
	var l: BUnit = b.units[0]
	l.hp = l.get_stats().max_health * 0.5
	var burn: Dictionary = (Fixture.catalog().get_unit("mob_ember_wrath").passives[0] as AbilityDef).effect_config.duplicate(true)
	burn["duration"] = 2.0
	b.pipeline.fx.apply_status(null, l, burn)
	var hp0: float = l.hp
	_step(b, 2.05)
	var mr: float = l.get_stats().magic_resistance
	t.near(l.hp - hp0, 2.0 * 25.0 * 100.0 / (100.0 + mr) * 2.0, 2.0, "2-star: two burning ticks heal 2× the damage they would deal")


func test_glut_oil_and_collapse(t: TestCtx) -> void:
	var b: Battle = Fixture.make([{"def": "mob_ember_glut", "team": 1, "star": 2, "pos": Vector2(0, 0)},
		{"def": "test_hitter", "team": 0, "pos": Vector2(1.0, 0)}, {"def": "test_dummy", "team": 0, "pos": Vector2(-2.0, 0)},
		{"def": "test_dummy", "team": 0, "pos": Vector2(-8.0, 0)}])
	b.start()
	_freeze(b)
	var g: BUnit = b.units[0]
	var hp0: float = g.hp
	for i in range(3):
		b.pipeline.normal_attack(b.units[1], g)
	var mx: float = g.get_stats().max_health
	var self_dmg: float = hp0 - g.hp
	t.ok(self_dmg > mx * 0.05 * 100.0 / (100.0 + g.get_stats().magic_resistance) * 0.9, "every 3rd hit taken: 5%% max health magic damage to itself (%.0f)" % self_dmg)
	t.ok(_burns(g) >= 1 and _burns(b.units[2]) >= 1, "the oil sets itself and those nearby burning")
	t.eq(_burns(b.units[3]), 0, "far away: untouched")
	var st: BStatus = b.units[2].status_instances("burning")[0]
	t.near(st.expires_at - b.time, 8.0, 0.05, "an 8 s burning")
	# 崩解：压到 33% 以下 → 吟唱 2 秒 → 每秒喷一次，直到倒下
	g.hp = mx * 0.34
	b.pipeline.fx.damage(null, g, mx * 0.02, "true")
	t.eq(g.phase, "chant", "below 33%: starts chanting")
	_step(b, 2.1 + maxf(0.0, GC.START_DELAY - b.time))     # (测试在开战倒计时里就触发了：吟唱从真正开打才开始计时)
	t.eq(g.status_count("glut_meltdown"), 1, "after 2 s: collapsing")
	var alive_t := 0.0
	while g.alive and alive_t < 20.0:
		_step(b, 0.25)
		alive_t += 0.25
	t.ok(not g.alive, "it keeps spewing oil on itself until it falls (%.1f s)" % alive_t)


func test_strong_fights_only_in_the_second_half(t: TestCtx) -> void:
	# 强怪 = 后半程的普通作战在浮动之上再加几级强度(开局定好)；前半程一个都没有
	var strong := 0
	var late := 0
	for sd: int in [3, 5, 8, 13, 21, 34]:
		var r := Run.create(Fixture.catalog(), sd)
		r.enter_chapter("ch1_red", false)
		var sc: Dictionary = r.chapter["intensity"]["strong"]
		var boss_depth: int = int(r.gnode(str(r.gmap["boss"]))["depth"])
		for k: String in (r.gmap["nodes"] as Dictionary).keys():
			var nd: Dictionary = r.gnode(k)
			var bump: int = int(nd.get("strong_bump", 0))
			var second: bool = float(int(nd["depth"])) > float(boss_depth) * float(sc["from"])
			if str(nd["type"]) == "fight" and second:
				late += 1
			if bump > 0:
				strong += 1
				t.ok(str(nd["type"]) == "fight" and second, "strong fights only in the second half (depth %d of %d)" % [int(nd["depth"]), boss_depth])
				t.ok(bump >= int(sc["bump"][0]) and bump <= int(sc["bump"][1]), "bumped by %d" % bump)
				t.ok(r.node_strong(k), "flagged as strong")
				var lin: float = r._depth_value(int(nd["depth"]))
				t.ok(float(r.node_intensity(k)) > lin * 0.9, "on top of the usual jitter")
	t.ok(strong > 0 and strong < late, "some (not all) second-half fights are strong (%d of %d)" % [strong, late])


func test_battle_intensity_and_encounters(t: TestCtx) -> void:
	var r := Run.create(Fixture.catalog(), 51)
	r.enter_chapter("ch1_red", false)
	var ic: Dictionary = r.chapter["intensity"]
	var last := -1
	for d in range(1, 12):
		var v: int = r._depth_intensity(d)
		t.ok(v >= last and v <= int(ic["max"]), "intensity rises with distance from the start (depth %d → %d)" % [d, v])
		last = v
	t.eq(r._depth_intensity(1), int(ic["base"]), "starts at the base intensity")
	# 战斗强度是绝对刻度：配出来的怪(含生命攻击倍率)总点数正好 = 强度，没有弱怪池 / 强怪池的台阶
	for inten: int in [6, 10, 13, 15, 17, 18, 19, 22, 26, 28, 34, 40]:
		for k in range(6):
			var enc: Dictionary = r._make_encounter("fight", inten)
			for e: Array in enc["units"]:
				t.ok(int(e[1]) <= r._max_star(inten), "star within the cap at %d" % inten)
				t.ok(str(e[0]).begins_with("mob_ember_"), "ordinary fights field the embers")
			t.near(r.encounter_power(enc), float(inten), 0.05 * float(inten), "monster points (with the stat multiplier) = intensity %d" % inten)
			t.eq(str(enc["pool"]), "weak", "a plain fight is a normal one")
	var st: Dictionary = r._make_encounter("fight", 22, true)
	t.eq(str(st["pool"]), "strong", "a strong fight is flagged…")
	var blue := false
	for e2: Array in st["units"]:
		blue = blue or str((e2[4] as Dictionary).get("orb", "")) == "blue"
	t.ok(blue, "…and drops a blue orb")
	t.near(r.encounter_power(st), 22.0, 1.1, "but it is built exactly like a normal fight of that intensity")
	for kind: String in ["elite", "boss", "hunt"]:
		for iv2: int in [16, 24, 32]:
			var ek: Dictionary = r._make_encounter(kind, iv2) if kind == "elite" else r._make_encounter(kind)
			var want: float = float(iv2) if kind == "elite" else float(ic[kind])
			t.near(r.encounter_power(ek), want, 0.05 * want, "%s fights spend the same points as their intensity (%.0f)" % [kind, want])
	var el: Dictionary = r._make_encounter("elite", 20)
	t.ok(str(el["units"][0][0]).begins_with("elite_"), "elite fights lead with an elite")
	var bs: Dictionary = r._make_encounter("boss")
	t.ok(str(bs["units"][0][0]).begins_with("boss_") and bool((bs["units"][0][4] as Dictionary).get("boss", false)), "the boss leads its fight")
	# 节点上：离起点越远强度越高，再加 ±10% 的随机浮动(开局定好，不是纯线性)；强怪在浮动之上再加几级
	var off_line := 0
	var fights := 0
	for k2: String in (r.gmap["nodes"] as Dictionary).keys():
		var nd: Dictionary = r.gnode(k2)
		if str(nd["type"]) == "fight":
			fights += 1
			var lin: float = r._depth_value(int(nd["depth"]))
			var iv: int = r.node_intensity(k2) - int(nd.get("strong_bump", 0))
			t.ok(absf(float(iv) - lin) <= lin * 0.1 + 0.51, "fight node intensity within ±10%% of the linear value (%d vs %.1f)" % [iv, lin])
			t.eq(r.node_intensity(k2) - int(nd.get("strong_bump", 0)), iv, "…and stable when asked again")
			if iv != r._depth_intensity(int(nd["depth"])):
				off_line += 1
	t.ok(off_line >= 2, "the jitter moves some nodes off the straight line (%d of %d)" % [off_line, fights])
