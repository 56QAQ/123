extends RefCounted
## 卡车改装：数据契约、改装池的三选一规则(时间窗 / 颜色保底 / 稀有度权重 / 不重复)、章节过渡流程，以及第一批 12 个改装的效果都走管线。


func _cat() -> Catalog:
	return Fixture.catalog()


func _run_with(mods: Array) -> Run:
	var r := Run.create(_cat(), 5)
	for m: Variant in mods:
		r.truck_mods.append(str(m))
	return r


func test_mod_data_contract(t: TestCtx) -> void:
	var cat: Catalog = _cat()
	t.eq(cat.mods.size(), 15, "three opening mods + the first batch of twelve")
	t.eq(cat._validate_mods().size(), 0, "mods validate: %s" % str(cat._validate_mods()))
	var start := 0
	for id: String in cat.mods.keys():
		var m: Dictionary = cat.mods[id]
		if int(m["t_min"]) == 0:
			start += 1
			t.ok(str(m["color"]) == "white" and int(m["rarity"]) == 1 and int(m["t_max"]) == 0 and m.has("layout"), "%s: opening mod = white, rarity 1, time 0..0" % id)
		else:
			t.ok(int(m["t_min"]) == 1 and int(m["t_max"]) == 4, "%s: first batch appears from time 1 to 4" % id)
	t.eq(start, 3, "three opening mods")
	var colors: Dictionary = {}
	for id2: String in ["powder_boost", "weapon_calibration", "light_armor", "hardened_alloy", "arcane_basics", "anti_resist"]:
		t.eq(int(cat.mods[id2]["rarity"]), 1, "%s is rarity 1" % id2)
	for id3: String in ["sharp_arms", "arcane_growth", "time_management", "pearl_field", "potent_dose", "cast_guard"]:
		t.eq(int(cat.mods[id3]["rarity"]), 2, "%s is rarity 2" % id3)
		colors[str(cat.mods[id3]["color"])] = true
	t.ok(colors.has("purple") and colors.has("cyan") and colors.has("yellow"), "the rarity-2 batch covers the mixed colors too")


func test_opening_roll_offers_exactly_the_three_layout_mods(t: TestCtx) -> void:
	var r := Run.create(_cat(), 11, "ch0", true)
	t.eq(r.phase, "start_mod", "a real run begins with the opening choice")
	t.eq(r.mod_options.size(), 3, "three options")
	for id: String in ["truck_zone", "truck_free", "truck_wide"]:
		t.ok(r.mod_options.has(id), "%s is offered" % id)


func test_roll_respects_time_window_color_and_ownership(t: TestCtx) -> void:
	var r := Run.create(_cat(), 3)
	for color: String in ["red", "blue", "green", "purple", "yellow", "cyan"]:
		var seen_color := 0
		for s in range(1, 41):
			r.seed_value = s
			var opts: Array[String] = r.roll_mod_options(1, color)
			t.eq(opts.size(), 3, "three options (seed %d)" % s)
			var has := false
			var uniq: Dictionary = {}
			for id: String in opts:
				uniq[id] = true
				var m: Dictionary = r.mod_def(id)
				t.ok(int(m["t_min"]) <= 1 and int(m["t_max"]) >= 1, "%s is in the time window at t=1" % id)
				if str(m["color"]) == color:
					has = true
			t.eq(uniq.size(), 3, "no duplicates")
			if has:
				seen_color += 1
		t.eq(seen_color, 40, "%s: every roll before a %s chapter contains a %s mod" % [color, color, color])
	r.seed_value = 3
	t.eq(r.roll_mod_options(5, "red").size(), 0, "nothing appears after time 4 yet")
	t.eq(r.roll_mod_options(0, "red").size(), 3, "at time 0 only the three layout mods exist (red can't be guaranteed: the pool has none)")
	r.truck_mods.append("powder_boost")
	r.truck_mods.append("weapon_calibration")
	r.truck_mods.append("sharp_arms")
	for s2 in range(1, 21):
		r.seed_value = s2
		var opts2: Array[String] = r.roll_mod_options(1, "red")
		t.ok(not opts2.has("powder_boost") and not opts2.has("weapon_calibration") and not opts2.has("sharp_arms"), "owned mods are never offered again (seed %d)" % s2)
		t.eq(opts2.size(), 3, "still three (nine red-batch mods left)")
	t.ok(r.roll_mod_options(1, "red").is_empty() == false, "(sanity)")


func test_rarity_weights_make_rarity_2_rarer(t: TestCtx) -> void:
	var r := Run.create(_cat(), 7)
	var r1 := 0
	var r2 := 0
	for s in range(1, 301):
		r.seed_value = s
		for id: String in r.roll_mod_options(1, ""):
			if int(r.mod_def(id)["rarity"]) == 2:
				r2 += 1
			else:
				r1 += 1
	# 池子里稀有度 1 和 2 各 6 个，权重 7 : 3 → 稀有度 1 大约占 70%(三选一不放回，略有偏差)
	var share: float = float(r2) / float(r1 + r2)
	t.ok(share > 0.2 and share < 0.42, "rarity-2 mods are the minority of what's offered (%.0f%%)" % (share * 100.0))


func test_chapter_transition_branch_then_mod(t: TestCtx) -> void:
	var r := Run.create(_cat(), 41)
	var guard := 0
	while r.phase != "branch" and guard < 10:
		guard += 1
		r.travel()
		var b := Battle.new(_cat(), 50 + guard)
		b.setup(r.build_battle_setup())
		b.winner = GC.TEAM_PLAYER
		r.begin_battle()
		r.finish_battle(b)
		r.finish_loot()
	t.eq(r.phase, "branch", "chapter 0 cleared → choose a branch first")
	t.eq(r.pick_mod("powder_boost")["reason"], "ui.err.not_now", "no mod before the branch")
	t.ok(bool(r.choose_branch("ch1_red")["ok"]), "red chapter")
	t.eq(r.phase, "chapter_end", "…then the mod choice")
	t.eq(r.pending_chapter, "ch1_red", "the chapter waits")
	t.eq(r.chapter_id, "ch0", "not entered yet")
	t.eq(r.mod_options.size(), 3, "three mods")
	t.eq(r.pick_mod("truck_zone")["reason"], "ui.err.bad_target", "only the offered ones")
	var pick: String = r.mod_options[0]
	t.ok(bool(r.pick_mod(pick)["ok"]), "pick")
	t.eq(r.chapter_id, "ch1_red", "now in the red chapter")
	t.eq(r.phase, "map", "on its map")
	t.ok(r.truck_mods.has(pick), "recorded")
	var setup: Dictionary = r.build_battle_setup()
	t.ok((setup["cfg"]["mods"] as Array).has(pick), "battles carry the owned mods")


# ---------------------------------------------------------------- 效果
func _dummy_fight(mods: Array, specs: Array, seed_value: int = 7) -> Battle:
	return Fixture.make(specs, seed_value, {"truck": false}, {"mods": mods})


func test_stat_mods_pick_their_beneficiaries(t: TestCtx) -> void:
	var specs := [{"def": "node_archer", "pos": Vector2(-3, 0)}, {"def": "node_darkknight", "pos": Vector2(-3, 2)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(3, 0)}]
	var b0: Battle = _dummy_fight([], specs)
	var b: Battle = _dummy_fight(["powder_boost", "weapon_calibration", "light_armor", "hardened_alloy", "arcane_basics", "anti_resist"], specs)
	var ar: BUnit = b.units[0]
	var kn: BUnit = b.units[1]
	var en: BUnit = b.units[2]
	var cat: Catalog = _cat()
	var a: float = float(cat.mods["weapon_calibration"]["stats"]["flat"]["crit_chance"])
	var bb: float = float(cat.mods["light_armor"]["stats"]["pct"]["attack_speed_multiplier"])
	var c: float = float(cat.mods["hardened_alloy"]["stats"]["flat"]["final_dmg_reduction"])
	var d: float = float(cat.mods["arcane_basics"]["stats"]["flat"]["ability_power"])
	var e: float = float(cat.mods["anti_resist"]["stats"]["flat"]["magic_resistance"])
	t.ok(a > 0.0 and bb > 0.0 and c > 0.0 and d > 0.0 and e < 0.0, "(the rarity-1 numbers a~e are filled in: %.2f / %.2f / %.2f / %.0f / %.0f)" % [a, bb, c, d, e])
	t.ok(ar.is_ranged() and not kn.is_ranged(), "(test setup: an archer and a knight)")
	t.near(ar.get_stats().na_damage_pct - b0.units[0].get_stats().na_damage_pct, 0.25, 0.001, "Extra Powder: the ranged node gets +25% normal-attack damage")
	t.near(kn.get_stats().na_damage_pct, b0.units[1].get_stats().na_damage_pct, 0.001, "…the melee node does not")
	t.near(ar.get_stats().crit_chance - b0.units[0].get_stats().crit_chance, a, 0.001, "Weapon Calibration: +a crit chance for the ranged node")
	t.near(ar.get_stats().crit_damage - b0.units[0].get_stats().crit_damage, a, 0.001, "…and +a crit damage")
	t.near(kn.get_stats().attack_speed_multiplier / b0.units[1].get_stats().attack_speed_multiplier, 1.0 + bb, 0.001, "Lightened Armor: the melee node attacks b% faster")
	t.near(ar.get_stats().attack_speed_multiplier, b0.units[0].get_stats().attack_speed_multiplier, 0.001, "…the ranged node does not")
	t.near(kn.get_stats().final_dmg_reduction, c, 0.001, "Hardened Alloy: c final reduction for the melee node")
	t.near(ar.get_stats().final_dmg_reduction, 0.0, 0.001, "…not for the ranged node")
	t.near(ar.get_stats().ability_power - b0.units[0].get_stats().ability_power, d, 0.001, "Arcane Fundamentals: +d AP for everyone")
	t.near(kn.get_stats().ability_power - b0.units[1].get_stats().ability_power, d, 0.001, "…including the melee node")
	t.near(en.get_stats().magic_resistance - b0.units[2].get_stats().magic_resistance, e, 0.001, "Anti-Resistance Jamming: enemies lose e magic resistance")
	t.near(en.get_stats().ability_power, b0.units[2].get_stats().ability_power, 0.001, "…and enemies get none of our buffs")
	# 减伤真的生效：同样一下打在骑士身上
	var b2: Battle = _dummy_fight(["hardened_alloy"], [{"def": "test_hitter", "team": 1, "pos": Vector2(0, 0)}, {"def": "node_darkknight", "pos": Vector2(1, 0)}])
	var b3: Battle = _dummy_fight([], [{"def": "test_hitter", "team": 1, "pos": Vector2(0, 0)}, {"def": "node_darkknight", "pos": Vector2(1, 0)}])
	var d2: float = b2.pipeline.fx.damage(b2.units[0], b2.units[1], 300.0, "physical", {"surface": "normal_attack", "can_crit": false})
	var d3: float = b3.pipeline.fx.damage(b3.units[0], b3.units[1], 300.0, "physical", {"surface": "normal_attack", "can_crit": false})
	t.near(d2 / d3, 1.0 - c, 0.01, "…a hit on the knight is reduced by c")


func test_sharp_arms_raises_normal_attack_values_by_a_third(t: TestCtx) -> void:
	var specs := [{"def": "node_darkknight", "pos": Vector2(-1, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1, 0)}]
	var plain: Battle = _dummy_fight([], specs)
	var sharp: Battle = _dummy_fight(["sharp_arms"], specs)
	t.near(sharp.units[0].get_stats().na_mult_pct, 1.0 / 3.0, 0.001, "Honed Arms: na_mult_pct = 1/3")
	var e_plain: float = plain.pipeline.estimate_na(plain.units[0], plain.units[1])
	var e_sharp: float = sharp.pipeline.estimate_na(sharp.units[0], sharp.units[1])
	t.near(e_sharp / e_plain, 4.0 / 3.0, 0.01, "normal-attack estimate ×4/3")
	for bb: Battle in [plain, sharp]:
		bb.start()
		bb.advance_pending(GC.START_DELAY)
		for i in range(int(6.0 / GC.SIM_DT)):
			bb.step()
			if bb.units[1].st_taken > 0.0:
				break
	var first_plain: float = plain.units[1].st_taken
	var first_sharp: float = sharp.units[1].st_taken
	t.ok(first_plain > 0.0 and first_sharp > 0.0, "(both knights landed a hit)")
	t.near(first_sharp / first_plain, 4.0 / 3.0, 0.03, "the real hit is ×4/3 too (%.0f vs %.0f)" % [first_sharp, first_plain])
	t.near(sharp.units[1].get_stats().na_mult_pct, 0.0, 0.001, "enemies don't get it")


func test_time_management_adds_stacks_to_passives_and_payloads_not_magazines(t: TestCtx) -> void:
	var cat: Catalog = _cat()
	var b: Battle = _dummy_fight(["time_management"], [{"def": "node_archer", "pos": Vector2(-1, 0), "weapon": "rapidfire_arbalest"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(2, 0)}])
	var ar: BUnit = b.units[0]
	var rapid: AbilityDef = null
	for a: AbilityDef in ar.def.passives:
		if a.has_keyword("stacking"):
			rapid = a
	t.ok(rapid != null, "(test setup: the archer's Rapid Fire passive is [Stacking 3])")
	if rapid != null:
		var base: int = rapid.keyword_value("stacking", ar.star, 0)
		t.eq(Pipeline.kw_value(ar, rapid, "stacking", 0), base + maxi(1, int(floor(float(base) * 0.25))), "passive [Stacking %d] → +25% rounded down, at least +1" % base)
	var na: AbilityDef = ar.na_payload()
	t.eq(Pipeline.kw_value(ar, na, "stacking", 1), 5, "the rifle magazine (weapon-class [Stacking 5]) is not a passive or payload: unchanged")
	var b0: Battle = _dummy_fight([], [{"def": "node_archer", "pos": Vector2(-1, 0), "weapon": "rapidfire_arbalest"}, {"def": "test_dummy", "team": 1, "pos": Vector2(2, 0)}])
	var big := 0
	for e: EquipmentDef in cat.equipment.values():
		for pa: AbilityDef in e.abilities:
			if pa.has_keyword("stacking") and pa.keyword_value("stacking", 1, 0) >= 8:
				big = pa.keyword_value("stacking", 1, 0)
				t.eq(Pipeline.kw_value(ar, pa, "stacking", 0), big + int(floor(float(big) * 0.25)), "a payload [Stacking %d] → +%d" % [big, int(floor(float(big) * 0.25))])
				t.eq(Pipeline.kw_value(b0.units[0], pa, "stacking", 0), big, "…and without the mod it is unchanged")
				break
		if big > 0:
			break


func test_potent_dose_adds_one_stack_every_three_seconds(t: TestCtx) -> void:
	var b: Battle = _dummy_fight(["potent_dose"], [{"def": "node_archer", "pos": Vector2(-3, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(3, 0)}])
	var ar: BUnit = b.units[0]
	b.start()
	t.ok(ar.statuses.has("potent_dose"), "at the start of battle the node holds a Potent Dose mark")
	var fx: Effects = b.pipeline.fx
	var st: BStatus = fx.apply_status(ar, ar, {"status_id": "test_stack", "duration": 0.0, "max_stacks": 10, "flags": ["buff"]})
	t.eq(st.stacks, 2, "the next [Stacking] application adds an extra stack")
	t.ok(not ar.statuses.has("potent_dose"), "…and spends the mark")
	var st2: BStatus = fx.apply_status(ar, ar, {"status_id": "test_stack", "duration": 0.0, "max_stacks": 10, "flags": ["buff"]})
	t.eq(st2.stacks, 3, "the one after that is normal again")
	var one: BStatus = fx.apply_status(ar, ar, {"status_id": "single", "duration": 0.0, "max_stacks": 1, "flags": ["buff"]})
	t.eq(one.stacks, 1, "non-stacking statuses are not affected")
	b.advance_pending(GC.START_DELAY)
	var got_at := -1.0
	for i in range(int(4.0 / GC.SIM_DT)):
		b.step()
		if ar.statuses.has("potent_dose"):
			got_at = b.time
			break
	t.ok(got_at > 0.0 and got_at - GC.START_DELAY <= 3.2, "a new mark arrives within 3 s of fighting (%.2f)" % (got_at - GC.START_DELAY))
	var en: BUnit = b.units[1]
	t.ok(not en.statuses.has("potent_dose"), "enemies get no mark")


func test_pearl_field_lets_everything_crit(t: TestCtx) -> void:
	var specs := [{"def": "test_hitter", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1, 0)}]
	var b: Battle = _dummy_fight(["pearl_field"], specs)
	var src: BUnit = b.units[0]
	var dst: BUnit = b.units[1]
	src.trait_flat["test"] = {"crit_chance": 1.0}      # 必定暴击
	src.mark_dirty()
	var cd: float = src.get_stats().crit_damage
	t.ok(src.get_stats().crit_chance >= 1.0 and cd > 1.0, "(test setup: 100% crit, crit damage ×%.2f)" % cd)
	var fx: Effects = b.pipeline.fx
	var skill: float = fx.damage(src, dst, 100.0, "true", {"surface": "passive", "can_crit": false, "ability_id": "x"})
	t.near(skill, 100.0 * cd, 0.5, "a skill that could not crit now crits (100 → %.0f)" % (100.0 * cd))
	var na: float = fx.damage(src, dst, 100.0, "true", {"surface": "normal_attack", "can_crit": true, "ability_id": "x"})
	t.near(na, 100.0 * cd * cd, 0.5, "damage that already crits crits a second time (100 → %.0f → %.0f)" % [100.0 * cd, 100.0 * cd * cd])
	var dot: float = fx.damage(src, dst, 100.0, "true", {"surface": "status", "can_crit": false, "status_base": "burning", "category": "dot", "ability_id": "burning"})
	t.near(dot, 100.0, 0.5, "periodic damage never crits")
	var b0: Battle = _dummy_fight([], specs)
	b0.units[0].trait_flat["test"] = {"crit_chance": 1.0}
	b0.units[0].mark_dirty()
	t.near(b0.pipeline.fx.damage(b0.units[0], b0.units[1], 100.0, "true", {"surface": "passive", "can_crit": false}), 100.0, 0.5, "without the mod the skill does not crit")
	var be: Battle = _dummy_fight(["pearl_field"], [{"def": "test_hitter", "team": 1, "pos": Vector2(0, 0)}, {"def": "test_dummy", "pos": Vector2(1, 0)}])
	be.units[0].trait_flat["test"] = {"crit_chance": 1.0}
	be.units[0].mark_dirty()
	t.near(be.pipeline.fx.damage(be.units[0], be.units[1], 100.0, "true", {"surface": "passive", "can_crit": false}), 100.0, 0.5, "enemies' skills still can't crit")


func test_cast_guard_shares_half_of_chant_damage(t: TestCtx) -> void:
	var specs := [{"def": "test_dummy", "pos": Vector2(-2, 0)}, {"def": "test_dummy", "pos": Vector2(-2, 2)}, {"def": "test_dummy", "pos": Vector2(-2, -2)},
		{"def": "test_hitter", "team": 1, "pos": Vector2(2, 0)}]
	var b: Battle = _dummy_fight(["cast_guard"], specs)
	var caster: BUnit = b.units[0]
	var m1: BUnit = b.units[1]
	var m2: BUnit = b.units[2]
	var foe: BUnit = b.units[3]
	var fx: Effects = b.pipeline.fx
	var hp0: float = caster.hp
	var dealt: float = fx.damage(foe, caster, 400.0, "true", {"surface": "normal_attack", "can_crit": false})
	t.near(hp0 - caster.hp, 400.0, 0.5, "not chanting: takes it all")
	caster.phase = "chant"
	var hp1: float = caster.hp
	var h1: float = m1.hp
	var h2: float = m2.hp
	dealt = fx.damage(foe, caster, 400.0, "true", {"surface": "normal_attack", "can_crit": false})
	t.near(hp1 - caster.hp, 200.0, 0.5, "chanting: half of it")
	t.near(h1 - m1.hp, 100.0, 0.5, "…the rest split between the two other nodes")
	t.near(h2 - m2.hp, 100.0, 0.5, "…equally")
	caster.phase = "idle"
	var b0: Battle = _dummy_fight([], specs)
	b0.units[0].phase = "chant"
	var hb: float = b0.units[0].hp
	b0.pipeline.fx.damage(b0.units[3], b0.units[0], 400.0, "true", {"surface": "normal_attack", "can_crit": false})
	t.near(hb - b0.units[0].hp, 400.0, 0.5, "without the mod a chanting node takes everything")


func test_arcane_growth_gives_codices_learning(t: TestCtx) -> void:
	var cat: Catalog = _cat()
	var codex: EquipmentDef = cat.get_equipment("talisman_edict")
	t.ok(codex != null and codex.class_id == "focus", "(test setup: Edict Talisman is a focus weapon)")
	var has_learning := false
	for a: AbilityDef in codex.abilities:
		if a.has_keyword("learning") or a.ability_class == "tome":
			has_learning = true
	t.ok(not has_learning, "(…whose payload does not learn by itself)")
	# 2 星：弱体符(被动 2，每 4 秒)发动 → 道法自然(OnPassiveActivated 的装备触发器)扣动法典的载荷
	var specs := [{"def": "node_taoist", "star": 2, "pos": Vector2(-2, 0), "weapon": "talisman_edict"}, {"def": "test_dummy", "team": 1, "pos": Vector2(2, 0)}]
	var b: Battle = _dummy_fight(["arcane_growth"], specs)
	var u: BUnit = b.units[0]
	var pa: AbilityDef = codex.abilities[0]
	t.ok(Pipeline.learns(u, pa), "with Arcane Growth the codex payload learns")
	t.near(Pipeline.learn_bonus_per(u, pa), 0.10, 0.001, "+10% trigger value per learning count")
	var b0: Battle = _dummy_fight([], specs)
	t.ok(not Pipeline.learns(b0.units[0], pa), "without the mod it does not")
	b.start()
	b.advance_pending(GC.START_DELAY)
	for i in range(int(12.0 / GC.SIM_DT)):
		b.step()
		if int(u.learning.get(pa.id, 0)) >= 2:
			break
	t.ok(int(u.learning.get(pa.id, 0)) >= 1, "activations count as learning (%d)" % int(u.learning.get(pa.id, 0)))
	# 非法典(剑)的效果不受影响
	var sword: EquipmentDef = cat.get_equipment("blackblade")
	var bs: Battle = _dummy_fight(["arcane_growth"], [{"def": "node_darkknight", "pos": Vector2(-2, 0), "weapon": "blackblade"}, {"def": "test_dummy", "team": 1, "pos": Vector2(2, 0)}])
	t.ok(sword != null and not Pipeline.learns(bs.units[0], sword.abilities[0]), "a sword's payload is not a codex: no learning")
