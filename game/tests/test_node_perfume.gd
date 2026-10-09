extends RefCounted
## 调香节点：飘香(【叠加 3】在场时友方【再生】效能 ×3；每 x 秒给全体友军 1 个再生)、恒古(2 星：在场时全体友军维持 1 个再生)、
## 焚花(每 8 秒，触发数值 = 本场为友方施加的治疗量，目标 = 全体敌人)、专武旧香炉(每 150 点叠 1 层浸染；浸染被普攻打到时回复攻击者 + 伤害持有者)。


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
	while b.time < sec and b.state != "ended":
		all.append_array(_step(b))
	return all


func _kill(b: Battle, u: BUnit) -> void:
	u.meta["_doomed"] = true
	u.hp = 0.0
	b.pipeline.fx.try_kill(u, null)


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = cat.get_unit("node_perfume")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model], [2, "cyan", "welfare", "caster", "focus", "perfumer"],
		"rarity 2, cyan, Welfare, caster, focus, perfumer model")
	t.eq(d.weapon_classes, ["focus", "sword"] as Array[String], "can equip foci and one-handed melee")
	var e: EquipmentDef = cat.get_equipment("old_censer")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["focus", "cyan", 2, "node_perfume"], "Old Censer: focus, cyan, rarity 2, hers")
	t.near(float(e.flat_mods.get("healing_done_pct", 0.0)), 0.15, 0.001, "+15% healing")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_scent_regen_every_few_seconds_and_triples(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_perfume", "pos": Vector2(0, -5)}, {"def": "test_hitter", "pos": Vector2(1.5, -5)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var pf: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	b.start()
	pf.attack_cd = 1.0e9
	_run(b, GC.START_DELAY + 0.1)
	t.eq(ally.status_count("regen"), 1, "at the start of battle: 1 Regeneration on every ally")
	t.eq(pf.status_count("regen"), 1, "…herself included")
	_run(b, GC.START_DELAY + 5.5)
	t.eq(ally.status_count("regen"), 1, "the first one is still there (10 s)")
	_run(b, GC.START_DELAY + 6.1)
	t.eq(ally.status_count("regen"), 2, "1★: every 6 s another, stacking up")
	var newest := 0.0
	for rs: BStatus in ally.status_instances("regen"):
		newest = maxf(newest, rs.expires_at - b.time)
	t.near(newest, 9.8, 0.4, "lasting 10 s")
	ally.hp = 50000.0
	var hp0: float = ally.hp
	_run(b, b.time + 1.0)
	t.near(ally.hp - hp0, 2.0 * GC.REGEN_HPS * 3.0, 1.5, "Wafting Scent: 2 Regenerations, each 3× as effective while she's here (%.0f/s)" % (ally.hp - hp0))
	_kill(b, pf)
	var hp1: float = ally.hp
	_run(b, b.time + 1.0)
	t.near(ally.hp - hp1, 2.0 * GC.REGEN_HPS, 1.5, "once she's gone it's back to normal")


func test_everlasting_keeps_one_regen_up(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_perfume", "pos": Vector2(0, -5), "star": 2}, {"def": "test_hitter", "pos": Vector2(1.5, -5)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var pf: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	b.start()
	pf.attack_cd = 1.0e9
	_run(b, GC.START_DELAY + 2.0)
	t.eq(ally.status_count("regen"), 2, "2★ Everlasting keeps 1 Regeneration on every ally (+ the one from Wafting Scent at the start)")
	t.ok(ally.get_status("regen_eternal") != null, "the Everlasting one")
	_run(b, GC.START_DELAY + 6.1)
	t.eq(ally.status_count("regen"), 3, "Wafting Scent every 4 s at 2★ (10 s each, stacking) + Everlasting")
	_kill(b, pf)
	_run(b, b.time + 1.0)
	t.ok(ally.get_status("regen_eternal") == null, "she falls: Everlasting fades")


func test_burning_blossoms_uses_the_healing_done(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_perfume", "pos": Vector2(0, -5), "weapon": "old_censer"}, {"def": "test_hitter", "pos": Vector2(1.5, -5)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}, {"def": "test_dummy", "team": 1, "pos": Vector2(2, 6)}])
	var pf: BUnit = b.units[0]
	b.start()
	pf.attack_cd = 1.0e9
	b.report._row(pf)["heal"] = 620.0                           # 本场已经为友方回复了 620
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 8.1)
	var trig: Array[Dictionary] = []
	for e: Dictionary in _of(evs, "trigger"):
		if e.get("unit") == pf and str(e.get("trigger", "")) == "node_perfume_burn":
			trig.append(e)
	for k in [2, 3]:
		t.eq(b.units[k].status_stacks("infusion"), 4, "Burning Blossoms: 620+ healing → ⌊value / 150⌋ = 4 Infusion on enemy %d" % k)
	t.ok(b.units[2].get_status("infusion").has_flag("debuff") and b.units[2].get_status("infusion").has_flag("dispellable"), "a dispellable debuff")


func test_infusion_heals_the_attacker_and_hurts_the_holder(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_perfume", "pos": Vector2(0, -6), "weapon": "old_censer"}, {"def": "test_hitter", "pos": Vector2(0, 0.6)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.8)}])
	var pf: BUnit = b.units[0]
	var hitter: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	b.start()
	pf.attack_cd = 1.0e9
	hitter.attack_cd = 1.0e9
	_run(b, GC.START_DELAY + 0.1)
	b.pipeline.fx.apply_status(pf, foe, {"status_id": "infusion", "duration": 8.0, "flags": ["debuff", "dispellable"], "add_stacks": 3, "max_stacks": 6,
		"meta": {"pop": 40.0}, "pairs": (Fixture.catalog().get_equipment("old_censer").abilities[0].effect_config["status"] as Dictionary)["pairs"]})
	hitter.hp = 50000.0
	var hp_h: float = hitter.hp
	var hp_f: float = foe.hp
	hitter.attack_cd = 0.0
	hitter.target = foe
	var evs: Array[Dictionary] = []
	while b.time < GC.START_DELAY + 3.0 and _of(evs, "infusion_pop").is_empty():
		evs.append_array(_step(b))
	t.eq(_of(evs, "infusion_pop").size(), 1, "a normal attack pops one Infusion")
	t.eq(foe.status_stacks("infusion"), 2, "2 left")
	var healed := 0.0
	for h: Dictionary in _of(evs, "heal"):
		if h["dst"] == hitter and str(h.get("ability", "")) == "infusion":
			healed += float(h["amount"])
	t.near(healed, 40.0 * 1.15, 0.5, "the attacker is healed for 40 (× her +15% healing)")
	var popped := 0.0
	for d: Dictionary in _of(evs, "damage"):
		if d["dst"] == foe and str(d.get("ability", "")) == "infusion":
			popped += float(d["amount"])
	t.near(popped, 40.0, 0.5, "the holder takes 40 magic damage (0 MR)")
	t.ok(hp_f - foe.hp > 40.0, "on top of the attack itself")


func test_regen_from_others_is_tripled_too(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_perfume", "pos": Vector2(0, -5)}, {"def": "test_hitter", "pos": Vector2(1.5, -5)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var ally: BUnit = b.units[1]
	b.start()
	b.units[0].attack_cd = 1.0e9
	_run(b, GC.START_DELAY + 5.0)
	for sid: String in ally.statuses.keys():
		if sid.begins_with("regen"):
			b.pipeline.fx.end_status(ally, sid)                 # 先拿掉飘香给的
	b.pipeline.fx.apply_regen(ally, ally, 3.0)                  # 别人(比如心音节点)给的再生
	ally.hp = 50000.0
	var hp0: float = ally.hp
	_run(b, b.time + 0.5)
	t.near(ally.hp - hp0, GC.REGEN_HPS * 3.0 * 0.5, 1.0, "any Regeneration on her allies is tripled")
