extends RefCounted
## 导向节点：引雷(普攻带【吟唱 3】，发出在敌人之间弹跳 x 次的连锁闪电——每跳都是完整的普攻；不能连着弹同一个人)、
## 变天(2 星：红之章下雨 = 燃烧持续时间减半；紫之章晴天 = 寒气的攻速削减减半；白之章没有效果)、
## 电闪(弹跳结束时，目标 = 打到的所有敌人，攻击力 × y)；专武电磁学导论(【充能 2】【学习】【群攻 3】：麻痹)。


func _def() -> UnitDef:
	return Fixture.catalog().get_unit("node_psychic")


func _trig(id: String) -> TriggerDef:
	for tr: TriggerDef in _def().triggers:
		if tr.id == id:
			return tr
	return null


func _calm(v: BUnit) -> void:
	v.attack_cd = 1.0e9
	v.base.move_speed = 0.0
	v.base.crit_chance = 0.0
	v.mark_dirty()


func _run(b: Battle, sec: float) -> void:
	while b.time < sec - 0.0001 and b.state != "ended":
		b.step()


func _bounces(star: int) -> int:
	var cfg: Dictionary = _def().passive_by_id("node_psychic_call").effect_config
	return int(cfg["meta"]["na_chain"]["bounces_by_star"][str(star)])


## 连锁闪电一跳一跳地传(每跳 Battle.CHAIN_HOP_DT 秒)：出手以后等它传完
func _settle(b: Battle) -> void:
	_run(b, b.time + 1.2)


func _na_hits(b: Battle, src: BUnit) -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for e: Dictionary in Fixture.events_of(b, "damage", "normal_attack"):
		if e["src"] == src:
			r.append(e)
	return r


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = _def()
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model], [3, "yellow", "research", "caster", "focus", "psychic"],
		"rarity 3, yellow, Research, caster, focus, psychic model")
	t.eq(d.weapon_classes, ["focus", "rifle", "crossbow", "pistols"] as Array[String], "can equip two-handed / one-handed / dual ranged")
	t.eq(d.passive_by_id("node_psychic_weather").unlock_star, 2, "Change the Weather unlocks at 2 stars")
	var e: EquipmentDef = cat.get_equipment("emag_intro")
	t.eq([e.class_id, e.color_id, e.cost, e.owner, e.model], ["focus", "yellow", 3, "node_psychic", "electro"], "Introduction to Electromagnetism: focus, yellow, 3, hers")
	var ab: AbilityDef = e.abilities[0]
	t.ok(ab.cooldown == 3.0 and ab.keyword_value("charged", 1) == 2 and ab.has_keyword("learning") and ab.keyword_value("multi_attack", 1) == 3,
		"3 s cooldown 【Charged 2】【Learning】【Multi 3】")
	t.ok(float(e.flat_mods.get("attack_power", 0.0)) > 0.0 and float(e.flat_mods.get("na_damage_pct", 0.0)) > 0.0, "attack + normal attack damage")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_normal_attack_is_chanted(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_psychic", "pos": Vector2(0, -2)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1)}])
	var w: BUnit = b.units[0]
	b.start()
	_run(b, GC.START_DELAY + 0.05)
	var na: AbilityDef = w.na_payload()
	t.eq(Pipeline.kw_value(w, na, "chant", 0), 3, "【Chant 3】 on her normal attack")
	t.ok(na.has_keyword("splash"), "the focus's own 【Splash 1】 stays")
	var drew := -1.0
	var fired := -1.0
	var hit: Array[Dictionary] = []
	while b.time < GC.START_DELAY + 6.0:
		b.step()
		for ev: Dictionary in b.poll_events():
			if ev["t"] == "damage" and ev["src"] == w and ev["surface"] == "normal_attack":
				hit.append(ev)
			if ev["t"] == "draw_start" and ev["unit"] == w and drew < 0.0:
				drew = b.time
				t.near(float(ev["duration"]), 3.0, 0.001, "chants up to 3 s")
			if ev["t"] == "chain_lightning" and ev["unit"] == w and fired < 0.0:
				fired = b.time
		if fired > 0.0:
			break
	t.ok(drew > 0.0 and fired > 0.0, "chant, then chain lightning")
	t.near(fired - drew, 3.0, 0.06, "released after the full 3 s")
	var raw: float = w.get_stats().attack_power * 1.0 * 2.0 * (1.0 + w.get_stats().na_damage_pct)
	t.near(float(hit[0]["amount"]), raw, raw * 0.02, "full chant = ×2 (%.0f magic)" % raw)
	t.eq(b.projectiles.size(), 0, "no projectile: the lightning lands at once")


func test_chain_bounces_between_enemies(t: TestCtx) -> void:
	for star: int in [1, 3]:
		var b := Fixture.make([{"def": "node_psychic", "pos": Vector2(0, -3), "star": star},
			{"def": "test_dummy", "team": 1, "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.2, 0)},
			{"def": "test_dummy", "team": 1, "pos": Vector2(-1.2, 0)}])
		var w: BUnit = b.units[0]
		b.start()
		_calm(w)
		_run(b, GC.START_DELAY + 0.05)
		b.events.clear()
		b.deliver_normal_attack(w, b.units[1], false, {"chant_scale": 1.0, "no_splash": true})
		_settle(b)
		var hits: Array[Dictionary] = _na_hits(b, w)
		t.eq(hits.size(), _bounces(star) + 1, "★%d: first hit + %d bounces" % [star, _bounces(star)])
		var ok := true
		for i in range(1, hits.size()):
			if hits[i]["dst"] == hits[i - 1]["dst"]:
				ok = false
		t.ok(ok, "★%d: never the same target twice in a row" % star)
		var uniq := {}
		for h: Dictionary in hits:
			uniq[h["dst"]] = true
		t.eq(uniq.size(), mini(3, hits.size()), "★%d: spreads to enemies it hasn't hit before going back" % star)
		t.eq(hits[0]["dst"], b.units[1], "starts on the attack target")


func test_chain_with_two_and_one_enemies(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_psychic", "pos": Vector2(0, -3), "star": 3},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.5, 0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(14, 9)}])
	var w: BUnit = b.units[0]
	b.start()
	_calm(w)
	_run(b, GC.START_DELAY + 0.05)
	b.events.clear()
	b.deliver_normal_attack(w, b.units[1], false, {"chant_scale": 1.0, "no_splash": true})
	_settle(b)
	var seq: Array = _na_hits(b, w).map(func(e: Dictionary) -> BUnit: return e["dst"])
	var want: Array = []
	for i in range(_bounces(3) + 1):
		want.append(b.units[1] if i % 2 == 0 else b.units[2])
	t.eq(seq, want, "two in range: A → B → A → B … (%d hits; the far one never)" % want.size())
	b.events.clear()
	b.deliver_normal_attack(w, b.units[3], false, {"chant_scale": 1.0, "no_splash": true})
	_settle(b)
	t.eq(_na_hits(b, w).size(), 1, "nobody within bounce range: just the one hit")


func test_flash_triggers_on_all_hit_enemies(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_psychic", "pos": Vector2(0, -3), "weapon": "emag_intro"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.2, 0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(-1.2, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.2)}])
	var w: BUnit = b.units[0]
	b.start()
	_calm(w)
	_run(b, GC.START_DELAY + 0.05)
	var ab: AbilityDef = Fixture.catalog().get_equipment("emag_intro").abilities[0]
	var amount: float = w.get_stats().attack_power * _trig("node_psychic_flash").ratio_for(1)
	var n: float = float(ab.effect_config["n"])
	b.deliver_normal_attack(w, b.units[1], false, {"chant_scale": 1.0, "no_splash": true})
	_settle(b)
	var par: Array = b.units.filter(func(u: BUnit) -> bool: return u.team == 1 and u.get_status("paralysis") != null)
	t.eq(par.size(), 3, "【Multi 3】: 3 of the hit enemies get Paralysis")
	var p0: float = amount / n / 100.0
	var st: BStatus = (par[0] as BUnit).get_status("paralysis")
	t.near(float(st.meta["paralyze"]), p0, 0.0001, "learning 0: (1 + 0)%% per %d (%.1f%%)" % [int(n), p0 * 100.0])
	t.near(float(st.flat_per_stack["damage_taken_amp"]), p0, 0.0001, "takes that much more damage")
	t.ok(st.has_flag("dispellable") and st.has_flag("debuff"), "dispellable debuff")
	t.eq(int(w.learning.get(ab.id, 0)), 1, "learning +1")
	b.deliver_normal_attack(w, b.units[1], false, {"chant_scale": 1.0, "no_splash": true})
	_settle(b)
	t.near(float(b.units[1].get_status("paralysis").meta["paralyze"]), 2.0 * p0, 0.0001, "learning 1: (1 + 1)% per n")
	t.eq(b.units[1].status_count("paralysis"), 1, "doesn't stack")
	# 取较高者：给它一个很高的麻痹，再上一次低的
	b.units[1].get_status("paralysis").meta["paralyze"] = 0.9
	w.learning[ab.id] = 0
	w.ability_cd.erase(ab.id)
	w.ability_charges[ab.id] = 2
	b.deliver_normal_attack(w, b.units[1], false, {"chant_scale": 1.0, "no_splash": true})
	_settle(b)
	t.near(float(b.units[1].get_status("paralysis").meta["paralyze"]), 0.9, 0.0001, "reapplying keeps the higher value")


func test_paralysis_interrupts_and_amplifies(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2(0, -0.5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.5)}])
	var h: BUnit = b.units[0]
	var d: BUnit = b.units[1]
	b.start()
	h.base.attack_base_interval_seconds = 0.8
	h.mark_dirty()
	_run(b, GC.START_DELAY + 0.05)
	b.pipeline.fx.apply_status(d, h, {"status_id": "paralysis", "duration": 30.0, "max_stacks": 1, "flags": ["debuff", "dispellable", "paralysis"],
		"stats": {"damage_taken_amp": {"flat": 0.5}}, "meta": {"paralyze": 1.0}})
	b.events.clear()
	_run(b, b.time + 4.0)
	t.eq(_na_hits(b, h).size(), 0, "100% paralysis: every attack is interrupted at the end of its wind-up")
	t.ok(Fixture.events_of(b, "paralyzed").size() >= 2, "shown as 'paralyzed'")
	b.pipeline.fx.end_status(h, "paralysis")
	b.events.clear()
	_run(b, b.time + 2.0)
	t.ok(_na_hits(b, h).size() > 0, "attacks again once it's gone")
	var base_hit: float = float(_na_hits(b, h)[0]["amount"])
	b.pipeline.fx.apply_status(h, d, {"status_id": "paralysis", "duration": 30.0, "max_stacks": 1, "flags": ["debuff", "dispellable", "paralysis"],
		"stats": {"damage_taken_amp": {"flat": 0.25}}, "meta": {"paralyze": 0.0}})
	b.events.clear()
	b.pipeline.normal_attack(h, d)
	t.near(float(_na_hits(b, h)[0]["amount"]), base_hit * 1.25, 1.0, "paralyzed target takes +25%")


func test_weather_by_chapter(t: TestCtx) -> void:
	for c: Array in [["white", ""], ["red", "rain"], ["purple", "sunny"], ["blue", "fog"]]:
		var b := Fixture.make([{"def": "node_psychic", "pos": Vector2(0, -3), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}],
			7, {"truck": false}, {"chapter_color": c[0]})
		b.start()
		_run(b, GC.START_DELAY + 0.05)
		t.eq(b.weather, c[1], "★2 in the %s chapter → weather '%s'" % [c[0], c[1]])
	var b1 := Fixture.make([{"def": "node_psychic", "pos": Vector2(0, -3), "star": 1}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}],
		7, {"truck": false}, {"chapter_color": "red"})
	b1.start()
	_run(b1, GC.START_DELAY + 0.05)
	t.eq(b1.weather, "", "★1: not unlocked yet")


func test_rain_halves_burning_and_sun_halves_chill(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_psychic", "pos": Vector2(0, -3), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}],
		7, {"truck": false}, {"chapter_color": "red"})
	var d: BUnit = b.units[1]
	b.start()
	_run(b, GC.START_DELAY + 0.05)
	var burn := {"status_id": "burning", "duration": 8.0, "max_stacks": 1, "independent": true, "flags": ["debuff", "burning", "dispellable"],
		"dot": {"kind": "magic", "amount": 10.0, "interval": 1.0}}
	var st: BStatus = b.pipeline.fx.apply_status(null, d, burn)
	t.near(st.expires_at - b.time, 4.0, 0.001, "rain: 8 s of Burning lasts 4 s")
	var w: BUnit = b.units[0]
	b.pipeline.fx.apply_status(null, w, burn.duplicate(true))
	t.near(w.status_instances("burning")[0].expires_at - b.time, 4.0, 0.001, "for everyone, allies too")
	var b2 := Fixture.make([{"def": "node_psychic", "pos": Vector2(0, -3), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}],
		7, {"truck": false}, {"chapter_color": "purple"})
	var d2: BUnit = b2.units[1]
	b2.start()
	_run(b2, GC.START_DELAY + 0.05)
	var as0: float = d2.get_stats().attack_speed_multiplier
	b2.pipeline.fx.apply_chill(null, d2, 10.0)
	t.near(d2.get_stats().attack_speed_multiplier, as0 - GC.CHILL_AS * 0.5, 0.0001, "clear skies: each Chill slows only half as much")
	for i in range(int(GC.FREEZE_OVER / GC.CHILL_AS)):
		b2.pipeline.fx.apply_chill(null, d2, 10.0)
	t.ok(d2.has_flag("stun") or d2.status_count("frozen") > 0, "freezing still counts Chill at its full amount")


## 2026-10-08：蓝之章起雾——敌我双方拿远程武器(法器除外)的普攻有一定概率被闪避；近战、法器不受影响
func test_fog_dodges_ranged_non_focus_attacks(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_psychic", "pos": Vector2(0, -3), "star": 2}, {"def": "node_archer", "pos": Vector2(2, -3)},
		{"def": "test_hitter", "pos": Vector2(-2, -3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)},
		{"def": "node_archer", "team": 1, "pos": Vector2(3, 4)}, {"def": "test_dummy", "pos": Vector2(-3, -4)}],
		7, {"truck": false}, {"chapter_color": "blue"})
	b.start()
	_run(b, GC.START_DELAY + 0.05)
	t.eq(b.weather, "fog", "blue chapter: fog")
	var p: float = float(b.weather_params.get("dodge", 0.0))
	t.ok(p > 0.0, "fog has a dodge chance (%.0f%%)" % (p * 100.0))
	for u: BUnit in b.units:
		u.attack_cd = 1.0e9
		u.base.crit_chance = 0.0
		u.mark_dirty()
	var cases: Array = [[b.units[1], b.units[3], p, "our archer's shots"], [b.units[4], b.units[5], p, "the enemy archer's shots too"],
		[b.units[0], b.units[3], 0.0, "a focus isn't affected"], [b.units[2], b.units[3], 0.0, "melee isn't affected"]]
	for c: Array in cases:
		var att: BUnit = c[0]
		var dfn: BUnit = c[1]
		var dodged := 0
		var n := 1500
		for i in range(n):
			b.poll_events()
			b.pipeline.normal_attack(att, dfn)
			for e: Dictionary in b.poll_events():
				if e.get("t") == "dodge" and e.get("unit") == dfn:
					dodged += 1
			dfn.hp = dfn.get_stats().max_health
		t.near(float(dodged) / n, float(c[2]), 0.035, "%s: %.0f%% dodged" % [c[3], float(c[2]) * 100.0])


## 2026-10-07：连锁闪电一跳一跳地传过去(每跳 Battle.CHAIN_HOP_DT 秒)：第一跳当场打中，后面的到点才结算；
## 每一跳先发 chain_hop(表现层画飞过去的闪电)，传完才发整条的 chain_lightning；下一跳的目标先倒下了，链子就断在那里
func test_chain_travels_hop_by_hop(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_psychic", "pos": Vector2(0, -3), "star": 1},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.2, 0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(-1.2, 0)}])
	var w: BUnit = b.units[0]
	b.start()
	_calm(w)
	_run(b, GC.START_DELAY + 0.05)
	b.events.clear()
	b.deliver_normal_attack(w, b.units[1], false, {"chant_scale": 1.0, "no_splash": true})
	t.eq(_na_hits(b, w).size(), 1, "the first hit lands at once")
	t.eq(Fixture.events_of(b, "chain_hop").size(), 2, "hop 0 (from her hand) and the next hop are announced")
	t.eq(Fixture.events_of(b, "chain_lightning").size(), 0, "the whole chain isn't done yet")
	_run(b, b.time + Battle.CHAIN_HOP_DT + 0.02)
	t.eq(_na_hits(b, w).size(), 2, "the second hit lands one hop later")
	_settle(b)
	t.eq(_na_hits(b, w).size(), _bounces(1) + 1, "…and the rest one by one")
	t.eq(Fixture.events_of(b, "chain_lightning").size(), 1, "then the whole chain once")
	# 下一跳的目标先倒下了：链子断在那里
	b.events.clear()
	b.deliver_normal_attack(w, b.units[1], false, {"chant_scale": 1.0, "no_splash": true})
	var nxt: BUnit = (Fixture.events_of(b, "chain_hop")[1] as Dictionary)["to"]
	nxt.hp = 0.0
	nxt.alive = false
	_settle(b)
	t.eq(_na_hits(b, w).size(), 1, "the next target fell first: the chain stops there")
	t.eq(Fixture.events_of(b, "chain_lightning").size(), 1, "…and still ends cleanly")
