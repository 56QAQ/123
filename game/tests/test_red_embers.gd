extends RefCounted
## 红之章的新敌人(2026-10-04)：嫉妒的余烬(维持射线、索敌我方伤害最高的单位、持续点燃)、贪婪的余烬(吞掉燃烧 → 金焰群攻)、
## 精英 忧郁的余烬(不攻击、嘲讽、有队友时减伤)、傲慢的余烬(召唤小怪 + 给友方加增益)、
## 首领 龙的余烬(在场时余烬不灭、燃烧改为移除生命上限、自己免疫燃烧；点燃格子 + 余烬扩散；纯单体战斗)。


func _step(b: Battle, seconds: float) -> Array[Dictionary]:
	var evs: Array[Dictionary] = []
	for i in range(int(round(seconds / GC.SIM_DT))):
		b.step()
		evs.append_array(b.poll_events())
	return evs


static func _of(evs: Array[Dictionary], type: String) -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for e: Dictionary in evs:
		if e.get("t") == type:
			r.append(e)
	return r


func _dmg_from(evs: Array[Dictionary], src: BUnit, dst: BUnit = null) -> float:
	var s := 0.0
	for e: Dictionary in _of(evs, "damage"):
		if e.get("src") == src and (dst == null or e["dst"] == dst):
			s += float(e["amount"])
	return s


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	for id: String in ["mob_ember_envy", "mob_ember_greed", "elite_ember_melancholy", "elite_ember_pride", "boss_ember_dragon"]:
		var d: UnitDef = cat.get_unit(id)
		t.ok(d != null and not d.available_in_shop, "%s exists, not in the shop" % id)
	t.eq(cat.get_unit("mob_ember_envy").target_priority, "top_damage", "Envy aims at the top damage dealer")
	t.eq(cat.get_unit("boss_ember_dragon").base_weapon_class, "polearm", "the Dragon wields a polearm")
	t.eq(cat.get_unit("boss_ember_dragon").weapon_look, "ember_glaive", "…her own molten glaive")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


# ---------------------------------------------------------------- 嫉妒的余烬
func test_envy_beams_the_top_damage_dealer(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "mob_ember_envy", "team": 1, "pos": Vector2(0, 2.0), "star": 2},
		{"def": "test_dummy", "pos": Vector2(-1.2, 0)}, {"def": "test_dummy", "pos": Vector2(2.4, -0.4)}])
	var en: BUnit = b.units[0]
	var near: BUnit = b.units[1]
	var star: BUnit = b.units[2]
	b.report._row(star)["dealt"] = 900.0                     # 这个人本场打了最多的伤害
	en.base.move_speed = 0.0
	en.mark_dirty()
	b.start()
	var evs: Array[Dictionary] = _step(b, GC.START_DELAY + 3.0)
	t.eq(en.target, star, "Envy locks onto the top damage dealer, not the nearest")
	t.near(_dmg_from(evs, en, near), 0.0, 0.01, "the nearer one is ignored")
	var hits := 0
	for e: Dictionary in _of(evs, "damage"):
		if e.get("src") == en and e["dst"] == star and str(e.get("surface", "")) == "normal_attack":
			hits += 1
	t.ok(hits >= 5 and hits <= 7, "a sustained beam: a hit every 0.5 s (%d in ~3 s)" % hits)
	t.ok(_of(evs, "projectile").is_empty() and _of(evs, "projectile_end").is_empty(), "no projectile: the beam lands instantly")
	t.ok(star.status_count("burning") >= 1, "the beam keeps it burning (%d)" % star.status_count("burning"))
	t.eq(star.status_stacks("envy_spite"), 6, "2★ Spite stacks up to 6")
	t.near(star.get_stats().damage_dealt_pct, -0.18, 0.001, "-3% damage dealt per stack")
	# 换人：另一个人打出了更多伤害
	b.report._row(near)["dealt"] = 5000.0
	_step(b, 1.0)
	t.eq(en.target, near, "when someone else out-damages them, the beam switches")


# ---------------------------------------------------------------- 贪婪的余烬
func test_greed_devours_burning_and_bursts(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "mob_ember_greed", "team": 1, "pos": Vector2(0, 2.5), "star": 2},
		{"def": "test_dummy", "pos": Vector2(0, 0)}, {"def": "test_dummy", "pos": Vector2(1.2, -0.6)}, {"def": "test_dummy", "pos": Vector2(-8, -6)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(-1.5, 2.5)}])
	var gr: BUnit = b.units[0]
	b.start()
	gr.attack_cd = 1.0e9                                      # 先不让她普攻
	var burn: Dictionary = (Fixture.catalog().get_unit("mob_ember_wrath").passives[0] as AbilityDef).effect_config.duplicate(true)
	for i in range(3):
		b.pipeline.fx.apply_status(null, b.units[1], burn)
	b.pipeline.fx.apply_status(null, b.units[2], burn)
	b.pipeline.fx.apply_status(null, b.units[3], burn)          # 太远：吞不到
	b.pipeline.fx.apply_status(null, b.units[4], burn)          # 她自己的队友身上的也吞
	_step(b, GC.START_DELAY + 2.1)
	t.eq(b.units[1].status_count("burning") + b.units[2].status_count("burning") + b.units[4].status_count("burning"), 0,
		"every Burning within 4.5 m is swallowed (friend or foe)")
	t.eq(b.units[3].status_count("burning"), 1, "the far one keeps burning")
	t.eq(gr.status_stacks("greed_hoard"), 5, "1 Greed per Burning swallowed")
	# 金焰：下一次普攻命中，层数 × 攻击 × 60% 打目标和它周围的队友，然后贪婪清空
	var atk: float = gr.get_stats().attack_power
	var hp1: float = b.units[1].hp
	var hp2: float = b.units[2].hp
	var hp_far: float = b.units[3].hp
	var hp_ally: float = b.units[4].hp
	gr.attack_cd = 0.0
	gr.target = b.units[1]
	var evs: Array[Dictionary] = []
	while gr.status_stacks("greed_hoard") > 0 and b.time < GC.START_DELAY + 6.0:
		evs.append_array(_step(b, GC.SIM_DT))
	evs.append_array(_step(b, 0.05))
	var burst := 5.0 * atk * 0.45
	t.ok(hp1 - b.units[1].hp >= burst - 1.0, "the target takes the Gilded Flame (%.0f ≥ %.0f)" % [hp1 - b.units[1].hp, burst])
	t.near(hp2 - b.units[2].hp, burst, burst * 0.15 + 30.0, "its neighbour takes it in full too (%.0f vs %.0f)" % [hp2 - b.units[2].hp, burst])
	t.ok(hp_far - b.units[3].hp < burst * 0.5, "the far one isn't caught (%.0f)" % (hp_far - b.units[3].hp))
	t.eq(gr.status_stacks("greed_hoard"), 0, "Greed spent")
	t.near(b.units[4].hp, hp_ally, 0.01, "her own ally isn't hit")
	t.ok(b.units[1].status_count("burning") >= 1 and b.units[2].status_count("burning") >= 1, "2★ Squander: everyone caught burns again")


# ---------------------------------------------------------------- 忧郁的余烬
func test_melancholy_never_attacks_taunts_and_hides_behind_allies(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "elite_ember_melancholy", "team": 1, "pos": Vector2(0, 1.2), "star": 2},
		{"def": "test_hitter", "pos": Vector2(0, 0)}, {"def": "mob_ember_wrath", "team": 1, "pos": Vector2(6, 5)},
		{"def": "test_hitter", "pos": Vector2(-1.2, -0.6)}])
	var mel: BUnit = b.units[0]
	var h: BUnit = b.units[1]
	b.units[3].target = b.units[2]
	b.start()
	b.units[2].attack_cd = 1.0e9
	var evs: Array[Dictionary] = _step(b, GC.START_DELAY + 3.0)
	t.near(_dmg_from(evs, mel), 0.0, 0.01, "she never attacks")
	t.eq(h.target, mel, "the hitter next to her is taunted onto her")
	t.eq(b.units[3].target, mel, "…and so is the one who wanted the Wrath")
	t.eq(mel.status_stacks("melancholy_drown"), 1, "Drowned in Sorrow while an ally lives")
	t.near(mel.get_stats().damage_taken_pct, 0.5, 0.001, "-50% damage taken")
	t.ok(h.status_count("melancholy_gloom") >= 1, "2★ Rain of Tears slows them")
	t.near(h.get_stats().attack_speed_multiplier, 1.0 - 0.25, 0.001, "-25% attack speed")
	b.units[2].meta["_doomed"] = true
	b.units[2].hp = 0.0
	b.pipeline.fx.try_kill(b.units[2], null)
	_step(b, 1.0)
	t.eq(mel.status_stacks("melancholy_drown"), 0, "alone: no more damage reduction")


# ---------------------------------------------------------------- 傲慢的余烬
func test_pride_summons_and_buffs(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "elite_ember_pride", "team": 1, "pos": Vector2(0, 5), "star": 2},
		{"def": "test_dummy", "pos": Vector2(0, -6)}])
	var pr: BUnit = b.units[0]
	b.start()
	pr.attack_cd = 1.0e9
	pr.base.move_speed = 0.0
	pr.mark_dirty()
	_step(b, 0.1)
	var mine := func() -> Array:
		var r: Array = []
		for u: BUnit in b.units:
			if u.alive and u.is_summon and u.summoner() == pr:
				r.append(u)
		return r
	t.eq((mine.call() as Array).size(), 1, "one minion at the start of battle")
	var m0: BUnit = (mine.call() as Array)[0]
	t.ok(m0.def.id.begins_with("mob_ember_"), "an Ember minion (%s)" % m0.def.id)
	t.eq(m0.star, 2, "inherits her star level")
	_step(b, GC.START_DELAY + 4.1)
	t.eq(m0.status_stacks("pride_favor"), 1, "Edict of Pride: the minion gets Pride's Favor")
	t.eq(pr.status_stacks("pride_favor"), 0, "…she doesn't")
	t.eq(m0.status_stacks("pride_grace"), 1, "2★ Court of Stars")
	_step(b, 30.0)
	t.eq((mine.call() as Array).size(), 3, "every 8 s another, at most 3 at a time")


# ---------------------------------------------------------------- 龙的余烬
func _dragon_battle(embers: Array) -> Battle:
	var layout := {"truck": false, "obstacles": [], "embers": embers}
	return Fixture.make([{"def": "boss_ember_dragon", "team": 1, "pos": Vector2(8, 6)},
		{"def": "test_dummy", "pos": GC.cell_to_world(2, 2)}, {"def": "test_dummy", "team": 1, "pos": Vector2(8, -6)}], 3, layout)


func test_dragon_keeps_embers_lit_and_burning_withers(t: TestCtx) -> void:
	var b := _dragon_battle([{"x": 6, "y": 6, "w": 1, "h": 1, "style": "ember_s"}])
	var dr: BUnit = b.units[0]
	var u: BUnit = b.units[1]
	b.start()
	dr.attack_cd = 1.0e9
	dr.base.move_speed = 0.0
	dr.mark_dirty()
	_step(b, GC.START_DELAY + 0.1)
	t.ok(dr.has_flag("ember_keeper") and dr.has_flag("burn_wither") and dr.has_flag("burn_immune"), "Dragon's Ember")
	u.pos = GC.cell_to_world(6, 6)
	_step(b, 0.1)
	t.eq(u.status_count("burning"), 1, "stepping on the embers still burns")
	t.ok(bool(b.map.embers[0]["lit"]), "but the embers don't go out")
	var mh0: float = u.get_stats().max_health
	var hp0: float = u.hp
	_step(b, 2.0)
	t.eq(u.status_count("burning"), 1, "standing on it: still one Burning")
	_step(b, 0.6)
	t.eq(u.status_count("burning"), 2, "after 2.5 s on the same tile it burns again")
	var lost: float = mh0 - u.get_stats().max_health
	t.ok(lost >= 25.0 * 2.0 - 0.1, "burning removes max health (%.0f)" % lost)
	t.near(hp0 - u.hp, lost, 0.5, "…along with that much health")
	t.ok(u.get_status("ember_wither") != null, "Dragonfire Scar")
	var cfg: Dictionary = (Fixture.catalog().get_unit("mob_ember_wrath").passives[0] as AbilityDef).effect_config.duplicate(true)
	b.pipeline.fx.apply_status(u, dr, cfg)
	t.eq(dr.status_count("burning"), 0, "she's immune to Burning")
	# 她倒下以后：恢复正常(踩上去会熄，燃烧照常是法术伤害)
	dr.meta["_doomed"] = true
	dr.hp = 0.0
	b.pipeline.fx.try_kill(dr, null)
	var mh1: float = u.get_stats().max_health
	var evs: Array[Dictionary] = _step(b, 1.05)
	t.near(u.get_stats().max_health, mh1, 0.01, "no more withering once she's gone")
	var dot := 0.0
	for e: Dictionary in _of(evs, "damage"):
		if e["dst"] == u and str(e.get("surface", "")) == "status":
			dot += float(e["amount"])
	t.ok(dot > 0.0, "Burning deals magic damage again")
	u.pos = GC.cell_to_world(2, 2)
	_step(b, 0.1)
	u.pos = GC.cell_to_world(6, 6)
	_step(b, 0.1)
	t.ok(not bool(b.map.embers[0]["lit"]), "and stepping on the embers puts them out")


func test_dragon_ignites_and_spreads(t: TestCtx) -> void:
	var b := _dragon_battle([{"x": 12, "y": 8, "w": 1, "h": 1, "style": "ember_s"}])
	var dr: BUnit = b.units[0]
	var u: BUnit = b.units[1]
	b.start()
	dr.attack_cd = 1.0e9
	dr.base.move_speed = 0.0
	dr.mark_dirty()
	var evs: Array[Dictionary] = _step(b, GC.START_DELAY + 5.1)
	t.ok(not _of(evs, "ember_add").is_empty(), "new ember tiles appear (view event)")
	var under: int = b.map.lit_ember_at(u.pos, u.radius)
	t.ok(under >= 0, "Wildfire: an ember is ignited under the enemy")
	t.ok(u.status_count("burning") >= 1, "…and sets it burning")
	t.ok(not _of(evs, "ember_spread").is_empty(), "lit embers spread")
	var n0: int = b.map.lit_ember_cells()
	_step(b, 60.0)
	t.ok(b.map.lit_ember_cells() > n0, "the fire keeps spreading (%d → %d)" % [n0, b.map.lit_ember_cells()])
	t.ok(b.map.lit_ember_cells() <= 60, "but never past 60 cells (%d)" % b.map.lit_ember_cells())
	for e: Dictionary in b.map.embers:
		var c: Vector2i = (e["rect"] as Rect2i).position
		t.ok(b.map.ember_cell_ok(c), "never on an obstacle")


func test_dragon_glaive_burns(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "boss_ember_dragon", "team": 1, "pos": Vector2(0, 1.2)}, {"def": "test_dummy", "pos": Vector2(0, 0)}])
	var dr: BUnit = b.units[0]
	b.start()
	var evs: Array[Dictionary] = _step(b, GC.START_DELAY + 2.0)
	t.ok(_dmg_from(evs, dr, b.units[1]) > 0.0, "she strikes")
	t.ok(b.units[1].status_count("burning") >= 1, "Dragonflame Glaive burns what it hits")


func test_boss_and_hunt_are_solo_dragon(t: TestCtx) -> void:
	var r := Run.create(Fixture.catalog(), 61)
	r.enter_chapter("ch1_red", false)
	var bs: Dictionary = r._make_encounter("boss")
	t.eq((bs["units"] as Array).size(), 1, "the boss fight is the Dragon alone")
	t.eq(str(bs["units"][0][0]), "boss_ember_dragon", "Ember of the Dragon")
	t.ok(bool((bs["units"][0][4] as Dictionary).get("boss", false)), "flagged as the boss")
	var hu: Dictionary = r._make_encounter("hunt")
	t.eq((hu["units"] as Array).size(), 1, "the hunt is the Dragon alone too")
	t.eq(int(hu["units"][0][1]), 2, "an empowered (2★) Dragon")
