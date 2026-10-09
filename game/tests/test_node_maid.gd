extends RefCounted
## 清扫节点：完美时计(100% 暴击；飞刀先停在半空，停着的每秒 +x 伤害，瞄着同一个敌人的加起来够打死它才一起飞过去；目标死了就消失，她倒下就掉地上)、
## 清洁世界(双持近战改成远程飞刀，射程 = 双持远程；开局及每 10 秒对射程内至多 3 个敌人各 2 次普攻)、女仆护身术(被近战敌人近身)
## + 专武闪烁刀刃(冷却 20 秒【充能 2】开战 1 层：瞬移到刚好打得到的地方、盯着她的敌人重新索敌、每 100 触发数值 1 次普攻)。


func _run(b: Battle, sec: float) -> void:
	while b.time < sec and b.state != "ended":
		b.step()


## 改木桩的生命 / 护甲(先标脏重算，再把当前生命设满——不然以后重算时会按比例把生命缩掉)
func _hp(u: BUnit, hp: float, df: float = 0.0) -> void:
	u.base.max_health = hp
	u.base.defense = df
	u.mark_dirty()
	u.get_stats()
	u.hp = hp


func _held(b: Battle, t: BUnit = null) -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for p: Dictionary in b.projectiles:
		if p.has("hold") and str(p["hold"]["phase"]) != "in" and (t == null or p["target"] == t):
			r.append(p)
	return r


func _x(star: int) -> float:
	var a: AbilityDef = Fixture.catalog().get_unit("node_maid").passive_by_id("node_maid_clock")
	return float((a.effect_config["meta_by_star"]["time_stop_pct"] as Dictionary)[str(star)])


func _dmg_from(b: Battle, u: BUnit, dst: BUnit = null) -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for e: Dictionary in Fixture.events_of(b, "damage"):
		if e["src"] == u and (dst == null or e["dst"] == dst):
			r.append(e)
	return r


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = cat.get_unit("node_maid")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role], [4, "red", "engineering", "archer"], "rarity 4, red, Engineering, archer")
	t.eq(d.weapon_classes, ["dual", "pistols"] as Array[String], "dual melee default; dual ranged allowed")
	t.near(d.base_stats.crit_chance, 1.0, 0.0001, "Perfect Timepiece: 100% crit")
	var wc: Dictionary = d.wclass_for("dual")
	t.ok(bool(wc["ranged"]), "Clean Sweep: dual melee becomes ranged")
	t.near(float(wc["range"]), float(GC.weapon_class("pistols")["range"]), 0.0001, "… with the dual-ranged range")
	t.eq(str(wc["projectile"]), "knife", "… throwing knives")
	t.ok(d.ranged_with(cat.get_equipment("basic_dual")), "counts as ranged for the AI / events")
	var e: EquipmentDef = cat.get_equipment("blink_blade")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["dual", "red", 4, "node_maid"], "Blink Blade: dual melee, red, rarity 4, hers")
	var ab: AbilityDef = e.abilities[0]
	t.eq([ab.cooldown, ab.keyword_value("charged", 1, 0), int(ab.cfg("initial_charges", 0))], [20.0, 2, 1], "20 s cooldown, Charged 2, 1 charge at the start")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_knives_hover_until_lethal(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_maid", "pos": Vector2(0, -2), "weapon": "basic_dual"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.2)}])
	var m: BUnit = b.units[0]
	var dm: BUnit = b.units[1]
	b.start()
	_hp(dm, 2600.0)
	_run(b, GC.START_DELAY + 2.0)
	t.ok(_held(b).size() >= 4, "knives pile up in mid-air (%d)" % _held(b).size())
	t.near(dm.hp, 2600.0, 0.01, "nothing has landed yet")
	t.eq(_dmg_from(b, m).size(), 0, "no damage before the knives are released")
	_run(b, GC.START_DELAY + 20.0)
	t.ok(not dm.alive, "released and killed it")
	var rel: Array[Dictionary] = Fixture.events_of(b, "held_release")
	t.ok(not rel.is_empty() and int(rel[0]["count"]) >= 4, "they all went together (%s)" % (str(rel[0]["count"]) if not rel.is_empty() else "-"))
	var first_hit := 1.0e9
	var crits := true
	for d: Dictionary in _dmg_from(b, m, dm):
		first_hit = minf(first_hit, float(d["time"]))
		crits = crits and bool(d["crit"])
	t.ok(not rel.is_empty() and first_hit >= float(rel[0]["time"]) - 0.0001, "the first hit lands after the release")
	t.ok(crits, "every knife crits (100% crit chance)")


func test_hover_damage_grows_per_second(t: TestCtx) -> void:
	for star: int in [1, 3]:
		var b := Fixture.make([{"def": "node_maid", "pos": Vector2(0, -2), "star": star}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.2)}])
		b.start()
		_hp(b.units[1], 1.0e7)
		_run(b, GC.START_DELAY + 1.5)
		var hs: Array[Dictionary] = _held(b)
		var p: Dictionary = {}
		for h: Dictionary in hs:
			if str(h["hold"]["phase"]) == "hover":
				p = h
				break
		t.ok(not p.is_empty(), "%d★: a knife is hovering" % star)
		if p.is_empty():
			continue
		var t0: float = float(p["hold"]["t_hover"])
		_run(b, b.time + 2.0)
		t.near(b.held_scale(p), 1.0 + _x(star) * (b.time - t0), 0.0001, "%d★: +%d%% damage per second hovering" % [star, int(round(_x(star) * 100.0))])


func test_pursuit_copy_leaves_with_the_knife(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_maid", "pos": Vector2(0, -2)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.2)}])
	b.start()
	_hp(b.units[1], 1.0e7)
	_run(b, GC.START_DELAY + 3.0)
	var firsts: Array = []
	var copies: Array = []
	for e: Dictionary in Fixture.events_of(b, "projectile"):
		if bool(e["proj"]["is_copy"]):
			copies.append(float(e["time"]))
		else:
			firsts.append(float(e["time"]))
	t.ok(copies.size() >= 4 and copies.size() == firsts.size(), "the other hand throws too (%d / %d)" % [copies.size(), firsts.size()])
	t.near(float(copies[0]) - float(firsts[0]), float(GC.weapon_class("dual")["copy_delay"]), 0.03, "… right after the first knife, not when it lands")


func test_knives_vanish_or_drop(t: TestCtx) -> void:
	# 目标被别人打死：瞄着它的飞刀消失(不造成伤害)
	var b := Fixture.make([{"def": "node_maid", "pos": Vector2(0, -2)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.2)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(3.5, 6)}])
	var m: BUnit = b.units[0]
	b.start()
	_hp(b.units[1], 1.0e6)
	_run(b, GC.START_DELAY + 2.0)
	t.ok(_held(b, b.units[1]).size() >= 3, "knives aimed at it are waiting")
	b.pipeline.fx.damage(null, b.units[1], 1.0e7, "true", {"surface": "other"})
	b.step()
	t.eq(_held(b, b.units[1]).size(), 0, "its target died: the knives aimed at it are gone")
	t.eq(_dmg_from(b, m, b.units[1]).size(), 0, "… without dealing anything")
	# 她倒下：停着的飞刀掉在地上
	var b2 := Fixture.make([{"def": "node_maid", "pos": Vector2(0, -2)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.2)}])
	b2.start()
	_hp(b2.units[1], 1.0e6)
	_run(b2, GC.START_DELAY + 2.0)
	var n: int = _held(b2).size()
	b2.pipeline.fx.damage(null, b2.units[0], 1.0e7, "true", {"surface": "other"})
	b2.step()
	var dropped := 0
	for e: Dictionary in Fixture.events_of(b2, "projectile_end"):
		if bool(e.get("dropped", false)):
			dropped += 1
	t.ok(n > 0 and dropped == n and _held(b2).is_empty(), "she fell: the %d hovering knives drop" % n)


func test_clean_sweep(t: TestCtx) -> void:
	# 三个敌人都在射程里：开局马上转圈，每人 2 次普攻(+ 另一只手)；之后 10 秒一次
	var b := Fixture.make([{"def": "node_maid", "pos": Vector2(0, -1.5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(-1.5, 1.2)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.6)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.5, 1.2)}])
	b.start()
	for i in [1, 2, 3]:
		_hp(b.units[i], 1.0e7)
	_run(b, GC.START_DELAY + 1.5)
	var st: Array[Dictionary] = Fixture.events_of(b, "storm_start")
	t.eq(st.size(), 1, "spins right away")
	if st.is_empty():
		return
	t.ok(float(st[0]["time"]) <= GC.START_DELAY + 0.3, "at the start of battle")
	t.eq((st[0]["targets"] as Array).size(), 3, "Multi Attack 3: all three")
	var per := {}
	for e: Dictionary in Fixture.events_of(b, "projectile"):
		var tm: float = float(e["time"])
		if tm >= float(st[0]["time"]) and tm <= float(st[0]["time"]) + 1.2 and not bool(e["proj"]["is_copy"]):
			var k: String = (e["proj"]["target"] as BUnit).uid
			per[k] = int(per.get(k, 0)) + 1
	t.eq(per.values(), [2, 2, 2], "two normal attacks at each")
	_run(b, GC.START_DELAY + 21.0)
	var st2: Array[Dictionary] = Fixture.events_of(b, "storm_start")
	t.eq(st2.size(), 3, "then every 10 s")
	t.ok(float(st2[1]["time"]) - float(st2[0]["time"]) >= 10.0 - 0.03, "cooldown 10 s")
	# 2026-10-07：不限射程——远处(射程外)的敌人开局也一起扔；被高墙挡住的不扔
	var b2 := Fixture.make([{"def": "node_maid", "pos": Vector2(0, -1.5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.6)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(7, 6)}, {"def": "test_dummy", "team": 1, "pos": Vector2(-6, 6)}])
	var cw: Vector2i = GC.world_to_cell(Vector2(-3.5, 2.5))
	b2.map.add_obstacle(Rect2i(cw.x - 1, cw.y - 1, 3, 3), BattleMap.HIGH, "wall")
	b2.start()
	for i2 in [1, 2, 3]:
		_hp(b2.units[i2], 1.0e7)
	_run(b2, GC.START_DELAY + 2.0)
	var s3: Array[Dictionary] = Fixture.events_of(b2, "storm_start")
	t.ok(s3.size() == 1 and float(s3[0]["time"]) <= GC.START_DELAY + 0.3, "spins at the start of battle (no waiting for enemies to come into range)")
	if not s3.is_empty():
		var tg3: Array = s3[0]["targets"]
		t.ok(tg3.has(b2.units[2]), "the far enemy out of range is targeted too")
		t.ok(not tg3.has(b2.units[3]), "…but not the one behind a high wall")
		t.ok(bool(s3[0].get("ultimate", false)), "treated as an ultimate (cut-in + time stop in the view)")


func test_self_defense_blink(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_maid", "pos": Vector2(0, -2), "weapon": "blink_blade"}, {"def": "test_hitter", "team": 1, "pos": Vector2(0, 4)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(-3, 5)}])
	var m: BUnit = b.units[0]
	var h: BUnit = b.units[1]
	h.base.move_speed = 3.0
	h.mark_dirty()
	b.start()
	_hp(b.units[2], 1.0e7)
	var blink: Dictionary = {}
	var aimed_before := false
	while b.time < GC.START_DELAY + 8.0 and blink.is_empty():
		aimed_before = h.target == m
		b.step()
		for e: Dictionary in Fixture.events_of(b, "blink"):
			blink = e
	t.ok(not blink.is_empty(), "a melee enemy got in close: Maid's Self-Defense → Blink Blade")
	if blink.is_empty():
		return
	t.eq(blink["target"], h, "the trigger target is that enemy")
	var want: int = int(floor(m.get_stats().attack_power * m.get_stats().crit_damage / 100.0))
	t.eq(int(blink["count"]), want, "attack × crit damage = %d → %d normal attacks" % [int(m.get_stats().attack_power * m.get_stats().crit_damage), want])
	var d: float = m.pos.distance_to(h.pos)
	t.ok(BattleAI.in_reach(m, h, d, m.get_stats().range_meters()) and b.map.has_los(m.pos, h.pos, m.team), "lands where she can just hit it (%.2f m)" % d)
	t.ok(d > h.get_stats().range_meters() + m.radius + h.radius, "… out of its reach")
	t.ok(aimed_before and h.target != m, "the enemy that was after her has to pick a target again")
	t.eq(int(m.ability_charges.get("blink_blade_strike", -1)), 0, "1 charge at the start, now used")
	_run(b, b.time + 0.6)
	var thrown := 0
	for e2: Dictionary in Fixture.events_of(b, "projectile"):
		if float(e2["time"]) >= float(blink["time"]) - 0.0001 and not bool(e2["proj"]["is_copy"]) and e2["proj"]["target"] == h:
			thrown += 1
	t.ok(thrown >= want, "the normal attacks go out at once (%d)" % thrown)
	# 它又贴上来：没有充能了，不再瞬移
	_run(b, GC.START_DELAY + 12.0)
	t.eq(Fixture.events_of(b, "blink").size(), 1, "no charge left: no second blink within 20 s")


func test_blink_spot(t: TestCtx) -> void:
	# 远程：能打到触发目标、看得见、别站进另一个近战敌人的攻击范围
	var b := Fixture.make([{"def": "node_maid", "pos": Vector2(0, -1), "weapon": "blink_blade"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 2)},
		{"def": "test_hitter", "team": 1, "pos": Vector2(2.5, 2.5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(-3.0, 3.5)}])
	b.start()
	var m: BUnit = b.units[0]
	var tg: BUnit = b.units[1]
	var p: Vector2 = b.pipeline._blink_spot(m, tg)
	var reach: float = m.get_stats().range_meters()
	t.ok(BattleAI.in_reach(m, tg, p.distance_to(tg.pos), reach) and b.map.has_los(p, tg.pos, m.team), "reaches the trigger target")
	var hm: BUnit = b.units[2]
	t.ok(p.distance_to(hm.pos) > hm.get_stats().range_meters() + 1.0, "keeps clear of the other melee enemy (%.2f m)" % p.distance_to(hm.pos))
	t.ok(BattleAI.in_reach(m, b.units[3], p.distance_to(b.units[3].pos), reach), "and gets the third enemy in range too")
	# 近战拿着它(其他双持近战的棋子)：贴到够得着的地方
	var b2 := Fixture.make([{"def": "node_berserker", "pos": Vector2(0, -3), "weapon": "blink_blade"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}])
	b2.start()
	var bz: BUnit = b2.units[0]
	var p2: Vector2 = b2.pipeline._blink_spot(bz, b2.units[1])
	t.ok(BattleAI.in_reach(bz, b2.units[1], p2.distance_to(b2.units[1].pos), bz.get_stats().range_meters()) and p2.distance_to(b2.units[1].pos) < 1.2,
		"a melee wielder blinks right next to it (%.2f m)" % p2.distance_to(b2.units[1].pos))


## 文案里的星级数值要和数据一致(上一次交付后数值调过、文案没跟上 → 加了这条)
func test_texts_match_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var pc := func(d: Dictionary) -> String:
		return "{★%d%%/%d%%/%d%%}" % [int(round(float(d["1"]) * 100.0)), int(round(float(d["2"]) * 100.0)), int(round(float(d["3"]) * 100.0))]
	var maid: AbilityDef = cat.get_unit("node_maid").passive_by_id("node_maid_clock")
	t.ok(Loc.t_in("zh", "unit.node_maid.passive.node_maid_clock").contains(pc.call(maid.effect_config["meta_by_star"]["time_stop_pct"])), "Perfect Timepiece x")
	var wz: TriggerDef = null
	for tr: TriggerDef in cat.get_unit("node_wizard").triggers:
		if tr.id == "node_wizard_missiles":
			wz = tr
	var wx := "{★%d%%/%d%%/%d%%}" % [int(round(wz.ratio_for(1) * 100.0)), int(round(wz.ratio_for(2) * 100.0)), int(round(wz.ratio_for(3) * 100.0))]
	for lang: String in ["zh", "en"]:
		t.ok(Loc.t_in(lang, "unit.node_wizard.passive.node_wizard_missiles").contains(wx), "%s: Prismatic Missiles %s" % [lang, wx])
		var hn: AbilityDef = cat.get_unit("node_hunter").passive_by_id("node_hunter_notes")
		t.ok(Loc.t_in(lang, "unit.node_hunter.passive.node_hunter_notes").contains(pc.call(hn.effect_config["per_sec_by_star"])), "%s: Hunter's Notes" % lang)
		var eye: AbilityDef = cat.get_unit("node_bird").passive_by_id("node_bird_eye")
		var z: Dictionary = eye.effect_config["stats_by_star"]["na_skill_flat_damage"]["flat"]
		t.ok(Loc.t_in(lang, "unit.node_bird.passive.node_bird_eye").contains("{★%d/%d/%d}" % [int(z["1"]), int(z["2"]), int(z["3"])]), "%s: Sky Sight" % lang)
		var bond: TriggerDef = cat.get_unit("node_bird").triggers[0]
		t.ok(Loc.t_in(lang, "unit.node_bird.passive.node_bird_bond").contains("%d%%" % int(round(bond.ratio_for(1) * 100.0))), "%s: Fragile Familiar" % lang)
		var fl: AbilityDef = cat.get_equipment("rainbow_flower").abilities[0]
		t.ok(Loc.t_in(lang, "equipment.rainbow_flower.desc").contains("%d " % int(fl.fixed_value)), "%s: Prism Bloom n" % lang)
