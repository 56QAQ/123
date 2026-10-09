extends RefCounted
## 改修节点：即时改装(每 2 秒一层【适应改造】：每层暴击率 + x × (100 + 法强)%；叠满后再叠 = 立刻连开两枪、消耗子弹；
## 换弹时按预计伤害挑物理 / 魔法)、成品完工(2 星：叠满过一次之后的弹匣都是真实伤害，同时吃物理和魔法的加成 / 吸血)、
## 应急道具(生命 ≤ 50%，最小间隔 3 秒，失去一层适应改造) + 专武驱动加农(物理 / 魔法伤害增幅；紧急维护：两种吸血 + 获得时回血)。


func _run(b: Battle, sec: float) -> void:
	while b.time < sec and b.state != "ended":
		b.step()


func _foe(u: BUnit, hp: float, df: float, mr: float) -> void:
	u.base.max_health = hp
	u.base.defense = df
	u.base.magic_resistance = mr
	u.mark_dirty()
	u.get_stats()
	u.hp = hp


func _x(star: int) -> float:
	for tr: TriggerDef in Fixture.catalog().get_unit("node_tinker").triggers:
		if tr.id == "node_tinker_retrofit":
			return tr.flat_for(star)
	return 0.0


func _dmg(b: Battle, src: BUnit) -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for e: Dictionary in Fixture.events_of(b, "damage"):
		if e["src"] == src:
			r.append(e)
	return r


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = cat.get_unit("node_tinker")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role], [2, "purple", "engineering", "archer"], "rarity 2, purple, Engineering, archer")
	t.eq(d.weapon_classes, ["rifle"] as Array[String], "two-handed ranged only")
	var e: EquipmentDef = cat.get_equipment("drive_cannon")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["rifle", "purple", 3, "node_tinker"], "Drive Cannon: rifle, purple, rarity 3, his")
	t.ok(e.flat_mods.has("physical_damage_pct") and e.flat_mods.has("magic_damage_pct"), "physical and magic damage amplification")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_retrofit_stacks_and_overflow_shots(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_tinker", "pos": Vector2(0, -3), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 2.5)}])
	var tk: BUnit = b.units[0]
	b.start()
	_foe(b.units[1], 1.0e7, 0.0, 0.0)
	_run(b, GC.START_DELAY + 2.05)
	t.eq(tk.status_stacks("adaptive_retrofit"), 1, "2 s: one stack")
	var st: BStatus = tk.get_status("adaptive_retrofit")
	t.ok(st != null and not st.has_flag("dispellable") and st.expires_at < 0.0, "can't be dispelled, lasts forever")
	_run(b, GC.START_DELAY + 6.05)
	t.eq(tk.status_stacks("adaptive_retrofit"), 3, "6 s: capped at 3")
	var base_cc: float = b.catalog.get_unit("node_tinker").base_stats.crit_chance
	t.near(tk.get_stats().crit_chance, base_cc + 3.0 * _x(2), 0.001, "+%d%% crit per stack" % int(round(_x(2) * 100.0)))
	# 第 4 次叠加：连开两枪(消耗子弹)
	while tk.phase == "reload" or Pipeline.ammo_source(tk) == null and b.pipeline.ammo(tk).stacks < 2:
		b.step()
	var am0: int = b.pipeline.ammo(tk).stacks
	var shots0: int = Fixture.events_of(b, "bonus_shot").size()
	var t_next: float = GC.START_DELAY + 8.05
	_run(b, t_next)
	var shots: int = Fixture.events_of(b, "bonus_shot").size() - shots0
	t.ok(shots == 2 or (shots < 2 and am0 < 2), "over the cap: two shots on the spot (%d)" % shots)
	t.eq(tk.status_stacks("adaptive_retrofit"), 3, "…and the stacks stay at 3")


func test_adaptive_magazine(t: TestCtx) -> void:
	for want: String in ["magic", "physical"]:
		var b := Fixture.make([{"def": "node_tinker", "pos": Vector2(0, -3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 2.5)}])
		var tk: BUnit = b.units[0]
		b.start()
		if want == "magic":
			_foe(b.units[1], 1.0e7, 150.0, 0.0)        # 护甲高、魔抗低 → 魔法
		else:
			_foe(b.units[1], 1.0e7, 0.0, 150.0)        # 魔抗高 → 物理
		_run(b, GC.START_DELAY + 1.0)
		t.ok(_dmg(b, tk).all(func(x: Dictionary) -> bool: return str(x["kind"]) == "physical"), "the first magazine is the rifle's own (physical)")
		var mags: Array[Dictionary] = []
		while b.time < GC.START_DELAY + 12.0 and mags.is_empty():
			b.step()
			mags = Fixture.events_of(b, "magazine")
		t.ok(not mags.is_empty() and str(mags[0]["kind"]) == want, "after a reload: %s rounds against %s" % [want, "armor" if want == "magic" else "magic resist"])
		var n0: int = _dmg(b, tk).size()
		_run(b, b.time + 2.0)
		var later: Array[Dictionary] = _dmg(b, tk).slice(n0)
		t.ok(not later.is_empty() and later.all(func(x: Dictionary) -> bool: return str(x["kind"]) == want), "…and the shots deal %s damage" % want)


func test_finished_product_true_damage_with_both_bonuses(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_tinker", "pos": Vector2(0, -3), "star": 2, "weapon": "drive_cannon"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 2.5)}])
	var tk: BUnit = b.units[0]
	b.start()
	_foe(b.units[1], 1.0e7, 300.0, 300.0)
	_run(b, GC.START_DELAY + 6.2)
	t.ok(tk.status_stacks("finished_product") > 0, "2★: Finished Product once the stacks reach 3")
	while b.time < GC.START_DELAY + 20.0 and Fixture.events_of(b, "magazine").filter(func(x: Dictionary) -> bool: return str(x["kind"]) == "true").is_empty():
		b.step()
	var n0: int = _dmg(b, tk).size()
	_run(b, b.time + 1.5)
	var tr: Array[Dictionary] = _dmg(b, tk).slice(n0).filter(func(x: Dictionary) -> bool: return str(x["kind"]) == "true" and not bool(x["crit"]))
	t.ok(not tr.is_empty(), "next magazine: true damage (ignores 300 armor / magic resist)")
	if not tr.is_empty():
		var st: StatBlock = tk.get_stats()
		var raw: float = st.attack_power * float(tk.wclass()["na_mult"])
		t.near(float(tr[0]["amount"]), raw * (1.0 + st.physical_damage_pct + st.magic_damage_pct), 1.0, "both +20% physical and +20% magic amplification apply")
	# 层数掉到 3 以下也不失效
	tk.get_status("adaptive_retrofit").stacks = 1
	tk.mark_dirty()
	t.ok(tk.status_stacks("finished_product") > 0, "dropping below 3 stacks doesn't undo it")
	# 1 星没有
	var b1 := Fixture.make([{"def": "node_tinker", "pos": Vector2(0, -3), "star": 1}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 2.5)}])
	b1.start()
	_run(b1, GC.START_DELAY + 7.0)
	t.eq(b1.units[0].status_stacks("finished_product"), 0, "1★: not unlocked")


func test_dual_lifesteal_on_true_rounds(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_tinker", "pos": Vector2(0, -3), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 2.5)}])
	var tk: BUnit = b.units[0]
	b.start()
	_foe(b.units[1], 1.0e7, 0.0, 0.0)
	tk.meta["na_kind"] = "true"
	tk.meta["na_dual"] = true
	b.pipeline.fx.apply_status(tk, tk, {"status_id": "test_ls", "flags": ["buff"], "duration": 30.0,
		"stats": {"physical_lifesteal": {"flat": 0.2}, "spell_lifesteal": {"flat": 0.1}}}, {})
	tk.hp = 100.0
	var d0: float = tk.st_damage
	_run(b, GC.START_DELAY + 1.0)
	var dealt: float = tk.st_damage - d0
	t.ok(dealt > 0.0, "shot something")
	t.near(tk.hp - 100.0, dealt * 0.3, 1.0, "true rounds draw both physical (20%) and spell (10%) lifesteal")


func test_emergency_kit_and_drive_cannon(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_tinker", "pos": Vector2(0, -3), "star": 1, "weapon": "drive_cannon"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 2.5)}])
	var tk: BUnit = b.units[0]
	b.start()
	_foe(b.units[1], 1.0e7, 0.0, 0.0)
	_run(b, GC.START_DELAY + 4.1)
	t.eq(tk.status_stacks("adaptive_retrofit"), 2, "two stacks")
	var mx: float = tk.get_stats().max_health
	b.pipeline.fx.damage(b.units[1], tk, mx * 0.6, "true", {"surface": "other"})
	b.step()
	t.eq(tk.status_stacks("adaptive_retrofit"), 1, "below 50%: lose a stack")
	t.ok(tk.status_stacks("emergency_maintenance") > 0, "Drive Cannon: Emergency Maintenance")
	var st: StatBlock = tk.get_stats()
	t.near(st.physical_lifesteal, 0.25, 0.001, "25% physical lifesteal")
	t.near(st.spell_lifesteal, 0.25, 0.001, "25% spell lifesteal")
	var heals: Array[Dictionary] = Fixture.events_of(b, "heal").filter(func(x: Dictionary) -> bool: return x["dst"] == tk and str(x.get("ability", "")) == "drive_cannon_maintenance")
	var want: float = 200.0 * (1.0 + st.ability_power / 100.0) * 0.5
	t.ok(not heals.is_empty() and absf(float(heals[0]["amount"]) - want) < 1.0, "heals trigger value (200%% × (100 + AP)) × 50%% = %d" % int(want))
	# 3 秒内再掉血：不再触发
	b.pipeline.fx.damage(b.units[1], tk, 1.0, "true", {"surface": "other"})
	b.step()
	t.eq(tk.status_stacks("adaptive_retrofit"), 1, "at most once every 3 s")
	# 没有层数：不触发
	var b2 := Fixture.make([{"def": "node_tinker", "pos": Vector2(0, -3), "weapon": "drive_cannon"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 2.5)}])
	var tk2: BUnit = b2.units[0]
	b2.start()
	_foe(b2.units[1], 1.0e7, 0.0, 0.0)
	_run(b2, GC.START_DELAY + 0.5)
	b2.pipeline.fx.damage(b2.units[1], tk2, tk2.get_stats().max_health * 0.6, "true", {"surface": "other"})
	b2.step()
	t.eq(tk2.status_stacks("emergency_maintenance"), 0, "no Adaptive Retrofit stack: no trigger")


func test_kind_amplification(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}])
	var h: BUnit = b.units[0]
	b.start()
	b.pipeline.fx.apply_status(h, h, {"status_id": "amp", "flags": ["buff"], "duration": 30.0, "stats": {"physical_damage_pct": {"flat": 0.5}}}, {})
	var p: float = b.pipeline.fx.damage(h, b.units[1], 100.0, "physical", {"surface": "other"})
	var m: float = b.pipeline.fx.damage(h, b.units[1], 100.0, "magic", {"surface": "other"})
	t.eq([int(round(p)), int(round(m))], [150, 100], "physical amplification only boosts physical damage")


func test_texts_match_data(t: TestCtx) -> void:
	var sx := "{★%d%%/%d%%/%d%%}" % [int(round(_x(1) * 100.0)), int(round(_x(2) * 100.0)), int(round(_x(3) * 100.0))]
	for lang: String in ["zh", "en"]:
		t.ok(Loc.t_in(lang, "unit.node_tinker.passive.node_tinker_retrofit").contains(sx), "%s: retrofit x %s" % [lang, sx])
	var y: TriggerDef = null
	for tr: TriggerDef in Fixture.catalog().get_unit("node_tinker").triggers:
		if tr.id == "node_tinker_emergency":
			y = tr
	var sy := "{★%d%%/%d%%/%d%%}" % [int(y.flat_for(1)), int(y.flat_for(2)), int(y.flat_for(3))]
	t.ok(Loc.t_in("zh", "unit.node_tinker.trigger.node_tinker_emergency").contains(sy), "emergency y %s" % sy)
