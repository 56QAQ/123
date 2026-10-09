extends RefCounted
## 灭罪节点：她是唯一的光(【吟唱 99】永远吟唱，光束降临在敌方最强的单位脚下、慢慢追向敌方伤害最高的单位，
## 每 0.25 秒灼中心的主目标 + 不分敌我的溅射，没有主目标也溅射；被打断光束消失、能动了重新开始)、
## 她将照亮长夜(2 星：每 0.5 秒 +3% 倍率与溅射范围，击杀 +2 秒，被打断重置)、她必尽灭邪恶(光束每 0.25 秒触发，目标 = 溅射范围里的敌人)、
## 专武光之心(当前生命低于 12 × 触发数值就斩杀，不触发它的阵亡时效果)。


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


## 光束的伤害事件(main = 打主目标的，splash = 溅射出去的)
static func _beam_hits(evs: Array[Dictionary], splash: bool) -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for e: Dictionary in _of(evs, "damage"):
		if str(e.get("ability", "")) == "node_absolver_light" and bool(e.get("splash", false)) == splash:
			r.append(e)
	return r


func _x(star: int) -> float:
	var tr: TriggerDef = null
	for tt: TriggerDef in Fixture.catalog().get_unit("node_absolver").triggers:
		if tt.id == "node_absolver_light_frame":
			tr = tt
	return tr.ratio_for(star)


func _beam(u: BUnit) -> Dictionary:
	return u.meta.get("light_beam", {})


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = cat.get_unit("node_absolver")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model], [3, "yellow", "legislation", "caster", "focus", "absolver"],
		"rarity 3, yellow, Legislation, caster, focus, absolver model")
	t.eq(d.weapon_classes, ["focus"] as Array[String], "can't switch to another weapon class")
	t.ok(GC.PROFESSIONS.has("legislation"), "Legislation is a department")
	var e: EquipmentDef = cat.get_equipment("light_heart")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["focus", "yellow", 3, "node_absolver"], "Heart of Light: focus, yellow, rarity 3, hers")
	t.eq([float(e.flat_mods.get("attack_power", 0.0)), float(e.flat_mods.get("ability_power", 0.0))], [15.0, 40.0], "+15 attack, +40 ability power")
	t.ok(e.abilities[0].has_keyword("basic") and Pipeline.kw_value(null, e.abilities[0], "multi_attack") == 6, "【Basic】【Multi-Attack 6】")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_beam_lands_on_the_strongest_and_chases_the_top_damage_dealer(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_absolver", "pos": Vector2(0, -5)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(3, 4)}, {"def": "test_rarity5", "team": 1, "pos": Vector2(-3, 4)}])
	var a: BUnit = b.units[0]
	var dummy: BUnit = b.units[1]
	var big: BUnit = b.units[2]
	b.start()
	t.eq(a.phase, "chant", "chanting from the start")
	t.eq(Pipeline.kw_value(a, a.chant_ability, "chant"), 99, "【Chant 99】")
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 0.1)
	t.eq(_of(evs, "light_beam_start").size(), 1, "the beam comes down once the fight starts")
	t.ok((_beam(a)["pos"] as Vector2).distance_to(big.pos) < 0.01, "right where the strongest enemy (rarity 5) stands")
	# 木桩打出了伤害 → 光束改为锁定它，慢慢挪过去(1 米 / 秒)
	b.pipeline.fx.damage(dummy, a, 30.0, "physical", {"surface": "other"})
	b.pipeline.drain()
	var p0: Vector2 = _beam(a)["pos"]
	_run(b, b.time + 1.0)
	var p1: Vector2 = _beam(a)["pos"]
	t.eq(_beam(a)["lock"], dummy, "locks onto the enemy that has dealt the most damage")
	t.near(p1.distance_to(p0), 1.0, 0.06, "moves slowly: ~1 m in 1 s")
	t.ok(p1.x > p0.x, "toward it")
	t.eq(a.phase, "chant", "still chanting")


func test_beam_burns_the_center_and_splashes_friend_and_foe(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_absolver", "pos": Vector2(0, -5)}, {"def": "test_dummy", "pos": Vector2(1.5, 4)},
		{"def": "test_rarity5", "team": 1, "pos": Vector2(0, 4)}, {"def": "test_dummy", "team": 1, "pos": Vector2(-1.5, 4)}])
	var a: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var big: BUnit = b.units[2]
	var foe: BUnit = b.units[3]
	b.start()
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 0.32)
	var per: float = _x(1) * a.get_stats().attack_power
	var main: Array[Dictionary] = _beam_hits(evs, false)
	t.eq(main.size(), 1, "one burn so far (0.25 s after it lands)")
	t.eq(main[0]["dst"], big, "on the main target at the center")
	t.near(float(main[0]["amount"]), per, 0.01, "%.0f%% × attack × (100 + AP)%% = %.2f magic" % [_x(1) * 100.0, per])
	t.eq(main[0]["kind"], "magic", "magic damage")
	var sp: Array[Dictionary] = _beam_hits(evs, true)
	var hit: Dictionary = {}
	for e: Dictionary in sp:
		hit[e["dst"]] = float(e["amount"])
	t.near(float(hit.get(foe, 0.0)), per * 0.5, 0.01, "splash on the enemy beside it: 50%")
	t.near(float(hit.get(ally, 0.0)), per * 0.5, 0.01, "and on her own ally (friend or foe)")
	t.ok(not hit.has(a), "she's far away")
	# 主目标离开中心：照常溅射
	big.pos = Vector2(6, -6)
	var evs2: Array[Dictionary] = _run(b, b.time + 0.25)
	t.eq(_beam_hits(evs2, false).size(), 0, "no main target at the center now")
	t.eq(_beam_hits(evs2, true).size(), 2, "but it still splashes the two dummies")
	t.eq(_of(evs2, "splash").size(), 1, "one splash per burn")


func test_interrupt_ends_the_beam_and_she_starts_again(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_absolver", "pos": Vector2(0, -5)}, {"def": "test_rarity5", "team": 1, "pos": Vector2(-2, 4)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(3, 4)}])
	var a: BUnit = b.units[0]
	var big: BUnit = b.units[1]
	b.start()
	_run(b, GC.START_DELAY + 0.6)
	t.ok(not _beam(a).is_empty(), "beam up")
	b.pipeline.fx.apply_status(big, a, {"status_id": "stun", "duration": 1.0, "flags": ["debuff", "stun"]})
	var evs: Array[Dictionary] = _run(b, b.time + 0.1)
	t.eq(_of(evs, "light_beam_end").size(), 1, "the beam goes out when she's interrupted")
	t.ok(_beam(a).is_empty(), "gone")
	var evs2: Array[Dictionary] = _run(b, b.time + 1.6)
	t.eq(a.phase, "chant", "chanting again once she can act")
	var st: Array[Dictionary] = _of(evs2, "light_beam_start")
	t.eq(st.size(), 1, "and the beam comes down again")
	t.ok(not st.is_empty() and (st[0]["pos"] as Vector2).distance_to(big.pos) < 0.01, "on the strongest enemy again")


func test_lighting_the_long_night_ramps_and_resets(t: TestCtx) -> void:
	for star: int in [1, 2]:
		var b := Fixture.make([{"def": "node_absolver", "pos": Vector2(0, -5), "star": star}, {"def": "test_rarity5", "team": 1, "pos": Vector2(0, 4)},
			{"def": "test_dummy", "team": 1, "pos": Vector2(4, 4)}, {"def": "test_dummy", "pos": Vector2(-4, 3)}])
		var a: BUnit = b.units[0]
		var big: BUnit = b.units[1]
		var foe: BUnit = b.units[2]
		var ally: BUnit = b.units[3]
		b.start()
		_run(b, GC.START_DELAY + 0.1)
		var born: float = float(_beam(a)["born"])
		var base_rad: float = float(_beam(a)["base_rad"])
		t.near(base_rad, 2.4, 0.001, "【Splash 2】 = 2.4 m")
		# 每次结算用的是结算那一刻的倍率
		var ok := true
		var checked := 0
		while b.time < born + 3.05:
			var m0: float = b.pipeline.light_beam_mult(a)
			var evs: Array[Dictionary] = _step(b)
			for e: Dictionary in _beam_hits(evs, false):
				checked += 1
				if absf(float(e["amount"]) - _x(star) * a.get_stats().attack_power * m0) > 0.01:
					ok = false
		t.ok(ok and checked >= 10, "%d★: every burn uses the multiplier of that moment (%d burns)" % [star, checked])
		var mult: float = float(_beam(a)["mult"])
		if star == 1:
			t.near(mult, 1.0, 0.0001, "1★: no ramp (unlocks at 2★)")
			continue
		t.near(mult, 1.0 + 0.03 * 6.0, 0.0001, "2★: 3 s chanted = 6 × 3%")
		t.near(float(_beam(a)["rad"]), base_rad * mult, 0.0001, "splash range grows with it")
		# 击杀敌人：直接 +2 秒(4 层)；溅死队友不算
		var evs2: Array[Dictionary] = []
		b.pipeline.fx.damage(a, foe, 1.0e7, "true", {"surface": "passive"})
		b.pipeline.drain()
		evs2.append_array(b.poll_events())
		t.eq(_of(evs2, "light_boost").size(), 1, "a kill lights the night")
		t.eq(int(_beam(a)["bonus"]), 4, "+2 s worth (4 steps)")
		b.pipeline.fx.damage(a, ally, 1.0e7, "true", {"surface": "passive"})
		b.pipeline.drain()
		t.eq(int(_beam(a)["bonus"]), 4, "killing an ally doesn't count")
		_run(b, b.time + 0.3)
		t.near(float(_beam(a)["mult"]), 1.0 + 0.03 * float(int(_beam(a)["steps"]) + 4), 0.0001, "kill bonus stacks on the time ramp")
		# 被打断：重置
		b.pipeline.fx.apply_status(big, a, {"status_id": "stun", "duration": 0.5, "flags": ["debuff", "stun"]})
		_run(b, b.time + 1.4)
		t.ok(not _beam(a).is_empty(), "new beam after the stun")
		t.ok(float(_beam(a)["mult"]) < 1.04 and int(_beam(a)["bonus"]) == 0, "the ramp starts over (×%.2f)" % float(_beam(a)["mult"]))


func test_purge_targets_the_beam_area_and_heart_of_light_executes(t: TestCtx) -> void:
	var specs: Array = [{"def": "node_absolver", "pos": Vector2(0, -5), "weapon": "light_heart"}, {"def": "node_bard", "team": 1, "pos": Vector2(0, 4), "star": 2},
		{"def": "test_dummy", "team": 1, "pos": Vector2(1.2, 4)}, {"def": "test_dummy", "team": 1, "pos": Vector2(-5.5, 4)}]
	var b := Fixture.make(specs)
	var a: BUnit = b.units[0]
	var bard: BUnit = b.units[1]
	var near: BUnit = b.units[2]
	var far: BUnit = b.units[3]
	b.start()
	var st: StatBlock = a.get_stats()
	var value: float = 0.1 * st.attack_power * (1.0 + st.ability_power / 100.0)
	var n: float = float(a.weapon.abilities[0].effect_config["n"])
	t.near(n, 12.0, 0.0001, "n = 12")
	bard.hp = 60.0
	near.hp = 400.0
	far.hp = 50.0
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 0.32)
	var abs_ev: Array[Dictionary] = _of(evs, "absolve")
	t.eq(abs_ev.size(), 1, "one execution")
	t.ok(not abs_ev.is_empty() and abs_ev[0]["target"] == bard, "the low-health enemy in the beam (below 12 × %.1f = %.0f)" % [value, value * n])
	t.ok(not bard.alive, "executed")
	t.eq(int(bard.trig_acts.get("node_bard_echo", 0)), 0, "her on-death passive (Endless Echo) never fires")
	t.ok(near.alive and near.hp > value * n, "above the line: spared")
	t.ok(far.alive, "outside the beam's splash range: not a target")
	# 对照：普通打死的心音节点会触发不绝的回响
	var b2 := Fixture.make([{"def": "test_hitter", "pos": Vector2(0, -5)}, {"def": "node_bard", "team": 1, "pos": Vector2(0, 4), "star": 2}])
	b2.start()
	b2.pipeline.fx.damage(b2.units[0], b2.units[1], 1.0e7, "true", {"surface": "other"})
	b2.pipeline.drain()
	t.eq(int(b2.units[1].trig_acts.get("node_bard_echo", 0)), 1, "(a normal death does trigger it)")


func test_purge_obeys_multi_attack(t: TestCtx) -> void:
	var specs: Array = [{"def": "node_absolver", "pos": Vector2(0, -5), "weapon": "light_heart"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 4)}]
	for i in range(7):
		var ang: float = TAU * float(i) / 7.0
		specs.append({"def": "test_dummy", "team": 1, "pos": Vector2(0, 4) + Vector2(cos(ang), sin(ang)) * 1.3})
	var b := Fixture.make(specs)
	var a: BUnit = b.units[0]
	b.start()
	for i in range(1, b.units.size()):
		b.units[i].hp = 60.0
	_run(b, GC.START_DELAY + 0.1)
	var evs: Array[Dictionary] = _run(b, b.time + 0.25)
	t.eq(_of(evs, "absolve").size(), 6, "【Multi-Attack 6】: six executed in one go")
	var evs2: Array[Dictionary] = _run(b, b.time + 0.25)
	t.eq(_of(evs2, "absolve").size(), 2, "the other two on the next trigger")
	t.eq(a.phase, "chant", "she never stops chanting")
