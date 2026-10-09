extends RefCounted
## 星旅节点：渡星而来(在仓库里也算羁绊；开战时场上没有她就从仓库坠落到敌人最密集的地方——装着非基础武器的 > 星级高的 > 最先进仓库的；
## 落地护盾 = 范围内敌人数 × x × (100 + 法强)%，范围内敌人各受一半)、外神之貌(嘲讽范围内的敌人、每秒扒一个可驱散的增益；
## 本应阵亡时再撑 y 秒，不能被治疗也不能被击杀，结束必死)、真实形态(锁血期间每 0.5/0.4/0.25 秒触发) + 专武某已不知名的星星的旗帜(流失当前生命)。


func _run(b: Battle, sec: float) -> void:
	while b.time < sec and b.state != "ended":
		b.step()


func _hp(u: BUnit, hp: float, mr: float = 0.0) -> void:
	u.base.max_health = hp
	u.base.magic_resistance = mr
	u.mark_dirty()
	u.get_stats()
	u.hp = hp


func _trig(id: String) -> TriggerDef:
	for tr: TriggerDef in Fixture.catalog().get_unit("node_astronaut").triggers:
		if tr.id == id:
			return tr
	return null


func _ab(id: String) -> AbilityDef:
	return Fixture.catalog().get_unit("node_astronaut").passive_by_id(id)


## 一个从仓库坠落的星旅节点 + 若干敌人(木桩)；落点按真实算法(和 Run 的预计落点一样)
func _drop_battle(foes: Array[Vector2], star: int = 1, weapon: String = "", extra: Array = []) -> Battle:
	var specs: Array = [{"def": "test_hitter", "pos": Vector2(0, -6)}]
	for fp: Vector2 in foes:
		specs.append({"def": "test_dummy", "team": 1, "pos": fp})
	specs.append_array(extra)
	var b := Fixture.make(specs)
	var d: UnitDef = Fixture.catalog().get_unit("node_astronaut")
	var land: Vector2 = Targeting.densest_point(foes, d.passive_splash_radius(star), b.map, d.radius)
	var u: BUnit = b.spawn_unit(d, 0, star, land, false)
	if weapon != "":
		u.set_weapon(Fixture.catalog().resolve_weapon(d, weapon))
	u.mark_dirty()
	u.hp = u.get_stats().max_health
	u.meta["dropping"] = true
	u.phase = "drop"
	return b


func _astro(b: Battle) -> BUnit:
	for u: BUnit in b.units:
		if u.def.id == "node_astronaut":
			return u
	return null


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = cat.get_unit("node_astronaut")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role], [4, "blue", "maintenance", "tank"], "rarity 4, blue, Maintenance, tank")
	t.eq(d.weapon_classes, ["polearm", "heavy"] as Array[String], "two-handed polearm default; two-handed heavy allowed")
	t.ok(d.bench_traits and d.bench_drop, "counts traits from storage; drops from storage")
	t.near(d.passive_splash_radius(1), 2.0 * GC.SPLASH_M_PER_POINT, 0.001, "Splash 2 = %.1f m" % (2.0 * GC.SPLASH_M_PER_POINT))
	var e: EquipmentDef = cat.get_equipment("forgotten_star_flag")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["polearm", "blue", 4, "node_astronaut"], "the flag: polearm, blue, rarity 4, hers")
	var a: AbilityDef = e.abilities[0]
	t.eq([a.ability_class, a.keyword_value("multi_attack", 1, 0), a.keyword_value("amplify", 1, 0)], ["bullet", 99, 2], "Fixed, Multi Attack 99, Amplify 2")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_storage_counts_for_traits_and_who_drops(t: TestCtx) -> void:
	var r := Run.create(Fixture.catalog(), 5)
	r.travel()
	var n0: int = r.trait_defs().size()
	var a1: Dictionary = r.add_unit("node_astronaut", 1, null, r.free_bench_slot())
	t.eq(r.trait_defs().size(), n0 + 1, "an astronaut in storage counts toward traits")
	r.add_unit("node_archer", 1, null, r.free_bench_slot())
	t.eq(r.trait_defs().size(), n0 + 1, "other pieces in storage don't")
	t.eq(r.starfall_unit().get("id", ""), a1["id"], "the one in storage drops")
	var a2: Dictionary = r.add_unit("node_astronaut", 2, null, r.free_bench_slot())
	t.eq(r.starfall_unit().get("id", ""), a2["id"], "two of them: the higher star drops")
	var a3: Dictionary = r.add_unit("node_astronaut", 1, null, r.free_bench_slot())
	a3["weapon"] = "forgotten_star_flag"
	t.eq(r.starfall_unit().get("id", ""), a3["id"], "…but one holding a real weapon goes first")
	a3["weapon"] = ""
	a2["star"] = 1
	t.eq(r.starfall_unit().get("id", ""), a1["id"], "all equal: the one that entered storage first")
	var sf: Dictionary = r.starfall_preview()
	var setup: Dictionary = r.build_battle_setup()
	var drops: Array = (setup["units"] as Array).filter(func(x: Dictionary) -> bool: return bool(x.get("drop", false)))
	t.eq(drops.size(), 1, "only one drops")
	t.ok(not drops.is_empty() and (drops[0]["pos"] as Vector2).distance_to(sf["pos"]) < 0.001, "it lands on the predicted spot shown while preparing")
	# 场上已经有星旅节点：谁都不坠落
	var cell := Vector2i(-1, -1)
	for c: Vector2i in GC.deploy_cells():
		if cell.x < 0 and r.unit_at_cell(c).is_empty() and r.can_deploy_at(a2, c):
			cell = c
	r.level = 9
	t.ok(r.move_unit(str(a2["id"]), {"cell": cell})["ok"], "deploy one")
	t.ok(r.starfall_unit().is_empty(), "one already on the field: nobody drops")


func test_densest_spot(t: TestCtx) -> void:
	var pts: Array[Vector2] = [Vector2(-3, 3), Vector2(-2.4, 3.4), Vector2(-2.8, 2.6), Vector2(4, 3), Vector2(5.5, 4)]
	var p: Vector2 = Targeting.densest_point(pts, 2.4, null)
	var cnt := 0
	for q: Vector2 in pts:
		if q.distance_to(p) <= 2.4 + 0.42:
			cnt += 1
	t.ok(cnt == 3 and p.x < 0.0, "lands on the tight cluster of three (%s)" % str(p))


func test_starfall_landing(t: TestCtx) -> void:
	var foes: Array[Vector2] = [Vector2(-1, 3), Vector2(0, 3.6), Vector2(1, 3), Vector2(7, 5)]
	var b := _drop_battle(foes, 2, "forgotten_star_flag")
	var a: BUnit = _astro(b)
	b.start()
	_run(b, GC.START_DELAY - 0.2)
	t.ok(not b.enemies_of(b.units[1]).has(a), "still in the sky during the countdown: can't be targeted")
	t.eq(a.phase, "drop", "…and doesn't act")
	_run(b, GC.START_DELAY + 0.05)
	t.ok(not bool(a.meta.get("dropping", false)) and b.enemies_of(b.units[1]).has(a), "lands when the battle starts")
	var x: float = _trig("node_astronaut_starfall").ratio_for(2)
	var v: float = 3.0 * x * (1.0 + a.get_stats().ability_power / 100.0)
	t.near(a.shield, v * (1.0 + a.get_stats().shield_received_pct), 1.0, "shield = 3 enemies × %d × (100 + AP)%% × shields received" % int(x))
	var hits: Array[Dictionary] = []
	for e: Dictionary in Fixture.events_of(b, "damage"):
		if e["src"] == a and str(e.get("ability", "")) == "node_astronaut_starfall":
			hits.append(e)
	t.eq(hits.size(), 3, "the three in range are hit; the far one isn't")
	t.ok(not hits.is_empty() and absf(float(hits[0]["amount"]) - v * 0.5) < 1.0 and bool(hits[0]["splash"]), "each takes half of it (splash, no main target)")


func test_taunt_aura_and_strip(t: TestCtx) -> void:
	var foes: Array[Vector2] = [Vector2(-0.8, 3), Vector2(0.8, 3), Vector2(6, 6)]
	var b := _drop_battle(foes)
	var a: BUnit = _astro(b)
	b.start()
	for u: BUnit in b.units:
		if u.team == 1:
			_hp(u, 1.0e6)
	var near: BUnit = b.units[1]
	b.pipeline.fx.apply_status(near, near, {"status_id": "test_buff_a", "flags": ["buff", "dispellable"], "duration": 30.0}, {})
	b.pipeline.fx.apply_status(near, near, {"status_id": "test_buff_b", "flags": ["buff", "dispellable"], "duration": 30.0}, {})
	b.pipeline.fx.apply_status(near, near, {"status_id": "test_debuff", "flags": ["debuff", "dispellable"], "duration": 30.0}, {})
	_run(b, GC.START_DELAY + 0.4)
	t.ok(near.forced_target == a and b.units[2].forced_target == a, "enemies in range are taunted")
	t.ok(b.units[3].forced_target != a, "the one out of range isn't")
	_run(b, GC.START_DELAY + 1.2)
	t.eq([near.statuses.has("test_buff_a") or near.statuses.has("test_buff_b"), near.statuses.has("test_debuff")], [true, true], "1 s: one buff gone, the debuff stays")
	_run(b, GC.START_DELAY + 2.2)
	t.ok(not near.statuses.has("test_buff_a") and not near.statuses.has("test_buff_b"), "2 s: both buffs gone")


func test_outer_god_death_delay(t: TestCtx) -> void:
	for star: int in [1, 3]:
		var b := _drop_battle([Vector2(0, 3)], star)
		var a: BUnit = _astro(b)
		b.start()
		_hp(b.units[1], 1.0e6)
		_run(b, GC.START_DELAY + 0.5)
		a.shield = 0.0
		b.pipeline.fx.damage(null, a, 1.0e7, "true", {"surface": "other"})
		var y: float = float((_ab("node_astronaut_undying").effect_config["duration_by_star"] as Dictionary)[str(star)])
		t.ok(a.alive and a.hp >= 1.0 and a.has_flag("undying"), "%d★: would die → lives on" % star)
		var t0: float = b.time
		b.pipeline.fx.heal(a, a, 500.0, {"surface": "passive"})
		t.near(a.hp, 1.0, 0.001, "can't be healed")
		b.pipeline.fx.damage(null, a, 1.0e7, "true", {"surface": "other"})
		t.ok(a.alive, "can't be killed")
		_run(b, t0 + y - 0.1)
		t.ok(a.alive, "still standing just before %.0f s" % y)
		_run(b, t0 + y + 0.1)
		t.ok(not a.alive, "dies for certain after %.0f s" % y)


func test_true_form_pulses_and_the_flag(t: TestCtx) -> void:
	for star: int in [1, 2, 3]:
		var foes: Array[Vector2] = [Vector2(-0.8, 3), Vector2(0.8, 3), Vector2(0, 3.8)]
		var b := _drop_battle(foes, star, "forgotten_star_flag")
		var a: BUnit = _astro(b)
		b.start()
		for u: BUnit in b.units:
			if u.team == 1:
				_hp(u, 10000.0)
		_run(b, GC.START_DELAY + 0.3)
		a.shield = 0.0
		b.pipeline.fx.damage(null, a, 1.0e7, "true", {"surface": "other"})
		var hp0: float = b.units[1].hp                 # 第一次脉冲在下一步结算(状态先于行动)
		_run(b, b.time + 6.0)
		var pulses: int = Fixture.events_of(b, "status_pulse").size()
		var cfg: Dictionary = _ab("node_astronaut_undying").effect_config
		var y: float = float(cfg["duration_by_star"][str(star)])
		var iv: float = float(cfg["pulse_by_star"][str(star)])
		t.eq(pulses, int(ceil(y / iv - 0.001)), "%d★: True Form every %.2f s for %.0f s" % [star, iv, y])
		var first: Dictionary = {}
		for e: Dictionary in Fixture.events_of(b, "damage"):
			if e["src"] == a and e["dst"] == b.units[1] and str(e.get("ability", "")) == "forgotten_star_flag_fade":
				first = e
				break
		# 3 个敌人 × 50 × (100 + 60)% = 240 → 每 100 点 1% × 增幅 2 = 4.8%，高过固定值 2% × 2 = 4%
		var v: float = 3.0 * _trig("node_astronaut_true_form").ratio_for(star) * (1.0 + a.get_stats().ability_power / 100.0)
		var pct: float = maxf(2.0 * 2.0, 1.0 * v / 100.0 * 2.0)
		t.ok(not first.is_empty() and absf(float(first["amount"]) - hp0 * pct / 100.0) < 1.0 and bool(first["hp_loss"]),
			"%d★: loses %.1f%% of current health (3 enemies in range: the per-100 side wins)" % [star, pct])
	# 只有 2 个敌人：固定值那边(2% × 2)更高
	var b2 := _drop_battle([Vector2(-0.6, 3), Vector2(0.6, 3)], 1, "forgotten_star_flag")
	var a2: BUnit = _astro(b2)
	b2.start()
	for u2: BUnit in b2.units:
		if u2.team == 1:
			_hp(u2, 10000.0)
	_run(b2, GC.START_DELAY + 0.3)
	a2.shield = 0.0
	b2.pipeline.fx.damage(null, a2, 1.0e7, "true", {"surface": "other"})
	var hp2: float = b2.units[1].hp
	_run(b2, b2.time + 0.1)
	var f2: Array[Dictionary] = Fixture.events_of(b2, "damage").filter(func(x: Dictionary) -> bool: return x["src"] == a2 and x["dst"] == b2.units[1] and str(x.get("ability", "")) == "forgotten_star_flag_fade")
	t.ok(not f2.is_empty() and absf(float(f2[0]["amount"]) - hp2 * 0.04) < 1.0, "2 enemies in range: the fixed side (2%% × 2 = 4%%) wins")


func test_texts_match_data(t: TestCtx) -> void:
	var x: TriggerDef = _trig("node_astronaut_starfall")
	var sx := "{★%d/%d/%d}" % [int(x.ratio_for(1)), int(x.ratio_for(2)), int(x.ratio_for(3))]
	var cfg: Dictionary = _ab("node_astronaut_undying").effect_config
	var sy := "{★%s/%s/%s}" % [Describe.fmt(float(cfg["duration_by_star"]["1"])), Describe.fmt(float(cfg["duration_by_star"]["2"])), Describe.fmt(float(cfg["duration_by_star"]["3"]))]
	for lang: String in ["zh", "en"]:
		t.ok(Loc.t_in(lang, "unit.node_astronaut.passive.node_astronaut_starfall").contains(sx), "%s: starfall x %s" % [lang, sx])
		t.ok(Loc.t_in(lang, "unit.node_astronaut.passive.node_astronaut_aura").contains(sy), "%s: lives on %s s" % [lang, sy])
		t.ok(Loc.t_in(lang, "unit.node_astronaut.trigger.node_astronaut_true_form").contains("%d[/color]" % int(_trig("node_astronaut_true_form").ratio_for(1))), "%s: z" % lang)
