extends RefCounted
## 正行节点：正色百合(五个来源叠【花瓣】，每层治疗量加成、4 层生命上限、8 层护甲魔抗)、再绽之花(花瓣满层吟唱 3 秒，每秒 4 层花瓣 → 1 层【花蕊】，
## 累计消耗 12 层 → 【花】= 满层花瓣加成)、花蕊(普攻最终伤害 × (1 + 治疗量加成)；普攻变成 120° / 4.5 米的锥形光刃，最多【群攻 9】个，
## 原普攻的 y 倍，再把伤害量智能分配成治疗)、百合骑士的骑士(敌人进 3 米 / 待满 2 秒；攻击力 × 治疗量加成 × z)、
## 专武正花(攻速 / 伤害减免；冷却 1 秒【充能 3】触发数值 × 150% 魔法普攻伤害 + 回复触发数值 × 100%)。


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


func _def() -> UnitDef:
	return Fixture.catalog().get_unit("node_noble")


func _pa(id: String) -> AbilityDef:
	return _def().passive_by_id(id)


func _trig(id: String) -> TriggerDef:
	for tr: TriggerDef in _def().triggers:
		if tr.id == id:
			return tr
	return null


func _x(star: int) -> float:
	return float(_pa("node_noble_lily").effect_config["stats_by_star"]["healing_done_pct"]["flat"][str(star)])


func _at(th: String, stat: String, star: int) -> float:
	return float(_pa("node_noble_lily").effect_config["stats_at_by_star"][th][stat]["flat"][str(star)])


func _y(star: int) -> float:
	return float(_pa("node_noble_rebloom").effect_config["stamen"]["meta_by_star"]["cone_scale"][str(star)])


## 她站着不动、不出手(只测被动 / 触发器)
func _calm(v: BUnit) -> void:
	v.attack_cd = 1.0e9
	v.base.move_speed = 0.0
	v.base.crit_chance = 0.0
	v.mark_dirty()


func _petals(b: Battle, u: BUnit, n: int) -> void:
	var cfg: Dictionary = _pa("node_noble_lily").effect_config.duplicate(true)
	cfg["add_stacks"] = n
	cfg["max_stacks"] = 12
	b.pipeline.fx.apply_status(u, u, cfg)


func _stamen(b: Battle, u: BUnit, n: int) -> void:
	var cfg: Dictionary = (_pa("node_noble_rebloom").effect_config["stamen"] as Dictionary).duplicate(true)
	cfg["max_stacks"] = 3
	cfg["add_stacks"] = n
	b.pipeline.fx.apply_status(u, u, cfg)


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = _def()
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model, d.offhand], [4, "yellow", "maintenance", "tank", "sword", "noble", "lily"],
		"rarity 4, yellow, Maintenance, tank, one-hand melee, noble model, her lily shield")
	t.eq(d.weapon_classes, ["sword", "focus", "polearm"] as Array[String], "can equip a focus and a two-handed long weapon")
	t.near(d.base_stats.max_health, 2000.0, 0.01, "rarity-4 tank template")
	t.eq(_pa("node_noble_lily").keyword_value("stacking", 1), 12, "True-Colored Lily 【Stacking 12】")
	var rb: AbilityDef = _pa("node_noble_rebloom")
	t.eq([rb.keyword_value("multi_attack", 1), rb.keyword_value("chant", 1), rb.keyword_value("stacking", 1)], [9, 3, 3], "Bloom Anew 【Multi-Attack 9】【Chant 3】【Stacking 3】")
	var e: EquipmentDef = cat.get_equipment("true_flower")
	t.eq([e.class_id, e.color_id, e.cost, e.owner, e.model], ["polearm", "yellow", 4, "node_noble", "lily"], "True Flower: two-handed long, yellow, rarity 4, hers")
	t.ok(float(e.pct_mods.get("attack_speed_multiplier", 0.0)) > 0.0 and float(e.flat_mods.get("damage_taken_pct", 0.0)) > 0.0, "attack speed + damage reduction (damage_taken_pct > 0 = takes less)")
	var ab: AbilityDef = e.abilities[0]
	t.eq([ab.keyword_value("charged", 1), ab.cooldown], [3, 1.0], "1 s cooldown 【Charged 3】")
	t.ok(GC.WEAPON_CLASSES["polearm"].has("guard_anims") and GC.WEAPON_CLASSES["focus"].has("guard_anims"), "spear / focus have one-hand + shield sets")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_one_hand_spear_and_focus_keep_the_shield(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	for wid: String in ["basic_sword", "true_flower", "basic_focus"]:
		var look: Dictionary = UnitSkin.look_for(_def(), cat.get_equipment(wid))
		t.ok(bool(look["shield"]), "%s: shield stays in her other hand" % wid)
		t.eq(str(look["shield_kind"]), "lily", "%s: her lily shield" % wid)
	var sp: Dictionary = UnitSkin.look_for(_def(), cat.get_equipment("true_flower"))
	t.eq(UnitSkin.anim(sp, "idle"), "idle_polearm_guard", "spear held one-handed")
	t.eq(UnitSkin.anim(UnitSkin.look_for(_def(), cat.get_equipment("basic_focus")), "attack"), "attack_focus_guard", "focus one-handed")


func test_petal_stats_and_thresholds(t: TestCtx) -> void:
	for star: int in [1, 2, 3]:
		var b := Fixture.make([{"def": "node_noble", "pos": Vector2(0, -3), "star": star}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
		var n: BUnit = b.units[0]
		var hp0: float = n.get_stats().max_health
		var df0: float = n.get_stats().defense
		var mr0: float = n.get_stats().magic_resistance
		_petals(b, n, 3)
		t.near(n.get_stats().healing_done_pct, 3.0 * _x(star), 0.0001, "★%d 3 petals: +%d%% healing" % [star, int(round(300.0 * _x(star)))])
		t.near(n.get_stats().max_health, hp0, 0.01, "★%d no max health yet" % star)
		_petals(b, n, 1)
		t.near(n.get_stats().max_health, hp0 + _at("4", "max_health", star), 0.01, "★%d 4 petals: +%d max health" % [star, int(_at("4", "max_health", star))])
		t.near(n.get_stats().defense, df0, 0.01, "★%d no armor yet" % star)
		_petals(b, n, 4)
		t.near(n.get_stats().defense, df0 + _at("8", "defense", star), 0.01, "★%d 8 petals: +%d armor" % [star, int(_at("8", "defense", star))])
		t.near(n.get_stats().magic_resistance, mr0 + _at("8", "magic_resistance", star), 0.01, "and magic resistance")
		t.near(n.get_stats().healing_done_pct, 8.0 * _x(star), 0.0001, "healing keeps scaling per stack")
		t.eq(n.get_status("lily_petal").flags.has("no_dispel"), true, "can't be dispelled")
		_petals(b, n, 10)
		t.eq(n.status_stacks("lily_petal"), 12, "【Stacking 12】")


func test_petal_sources(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_noble", "pos": Vector2(0, -3)}, {"def": "test_hitter", "pos": Vector2(2, -3)},
		{"def": "test_hitter", "pos": Vector2(-2, -3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 8)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(3, 8)}])
	var n: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var ally2: BUnit = b.units[2]
	var foe: BUnit = b.units[3]
	_calm(n)
	_calm(ally)
	_calm(ally2)
	b.start()
	_run(b, GC.START_DELAY + 0.05)
	t.eq(n.status_stacks("lily_petal"), 0, "no petals at the start")
	_run(b, GC.START_DELAY + 3.05)
	t.eq(n.status_stacks("lily_petal"), 1, "1 petal every 3 s")
	# 队友造成击杀 +1(敌人)
	foe.hp = 0.0
	b.pipeline.fx.try_kill(foe, ally)
	t.eq(n.status_stacks("lily_petal"), 2, "a teammate's kill: +1")
	# 每 3 次普攻 +1
	for i in range(3):
		b.pipeline.normal_attack(n, b.units[4])
	t.eq(n.status_stacks("lily_petal"), 3, "every 3 normal attacks: +1")
	# 为队友提供治疗 +2(同一下分给几个人只算一次；治疗自己不算)
	ally.hp = 1000.0
	ally2.hp = 1000.0
	b.pipeline.fx.heal(n, ally, 100.0, {"surface": "passive"})
	b.pipeline.fx.heal(n, ally2, 100.0, {"surface": "passive"})
	t.eq(n.status_stacks("lily_petal"), 5, "healing teammates: +2 once per heal")
	n.hp = 100.0
	_run(b, b.time + 0.3)
	var before: int = n.status_stacks("lily_petal")
	b.pipeline.fx.heal(n, n, 100.0, {"surface": "passive"})
	t.eq(n.status_stacks("lily_petal"), before, "healing herself doesn't count")
	# 队友阵亡 +3
	ally2.hp = 0.0
	b.pipeline.fx.try_kill(ally2, b.units[4])
	t.eq(n.status_stacks("lily_petal"), before + 3, "a teammate falls: +3")


func test_rebloom_chant_turns_petals_into_stamens_and_blooms(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_noble", "pos": Vector2(0, -3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 8)}])
	var n: BUnit = b.units[0]
	_calm(n)
	b.start()
	_run(b, GC.START_DELAY + 0.3)
	_petals(b, n, 12)
	var evs: Array[Dictionary] = _run(b, b.time + 0.3)
	t.eq(n.phase, "chant", "12 petals: starts chanting Bloom Anew")
	t.eq(_of(evs, "chant_start").size(), 1, "chant event for the view")
	_run(b, b.time + 1.0)
	t.eq(n.status_stacks("lily_stamen"), 1, "after 1 s: 1 stamen")
	t.ok(n.status_stacks("lily_petal") <= 8, "4 petals spent (%d left)" % n.status_stacks("lily_petal"))
	t.eq(n.status_stacks("lily_bloom"), 0, "no bloom yet")
	_run(b, b.time + 2.1)
	t.eq(n.phase != "chant", true, "chant over after 3 s")
	t.eq(n.status_stacks("lily_stamen"), 3, "3 stamens (【Stacking 3】)")
	t.eq(int(n.meta.get("lily_consumed", 0)), 12, "12 petals spent in total")
	t.eq(n.status_stacks("lily_bloom"), 1, "→ Bloom")
	# 花 = 满层花瓣的加成，花瓣自己的加成不再另算
	var base_hp: float = n.base.max_health
	t.near(n.get_stats().healing_done_pct, 12.0 * _x(1), 0.0001, "Bloom: full-stack healing bonus (%d%%)" % int(round(1200.0 * _x(1))))
	t.near(n.get_stats().max_health, base_hp + _at("4", "max_health", 1), 0.01, "and the 4-stack max health")
	_petals(b, n, 5)
	t.near(n.get_stats().healing_done_pct, 12.0 * _x(1), 0.0001, "petals don't stack on top of Bloom")
	t.eq(n.get_status("lily_bloom").flags.has("no_dispel"), true, "Bloom can't be dispelled")


func test_interrupted_chant_keeps_its_progress(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_noble", "pos": Vector2(0, -3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 8)}])
	var n: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	_calm(n)
	b.start()
	_run(b, GC.START_DELAY + 0.3)
	_petals(b, n, 12)
	_run(b, b.time + 1.6)
	t.eq(n.status_stacks("lily_stamen"), 1, "1 s in: 1 stamen")
	b.pipeline.fx.apply_status(foe, n, {"status_id": "stun", "duration": 1.0, "flags": ["debuff", "stun"]})
	_run(b, b.time + 0.1)
	t.ok(n.phase != "chant", "a stun interrupts the chant")
	t.eq(int(n.meta.get("lily_consumed", 0)), 4, "what was spent stays spent")
	t.eq(n.status_stacks("lily_bloom"), 0, "not bloomed yet")
	_run(b, b.time + 1.2)
	_petals(b, n, 12)
	_run(b, b.time + 3.5)
	t.eq(n.status_stacks("lily_bloom"), 1, "the next chant finishes the 12 → Bloom")
	t.eq(n.status_stacks("lily_stamen"), 3, "stamens capped at 3")


func test_stamen_final_damage_bonus(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_noble", "pos": Vector2(0, -0.5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.5)}])
	var n: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	_calm(n)
	_petals(b, n, 8)
	var hb: float = n.get_stats().healing_done_pct
	var atk: float = n.get_stats().attack_power
	b.pipeline.normal_attack(n, foe)
	var d0: Array[Dictionary] = Fixture.events_of(b, "damage", "normal_attack")
	t.near(float(d0[-1]["amount"]), atk, 0.01, "without stamens: plain normal attack")
	_stamen(b, n, 1)
	b.pipeline.normal_attack(n, foe)
	var d1: Array[Dictionary] = Fixture.events_of(b, "damage", "normal_attack")
	t.near(float(d1[-1]["amount"]), atk * (1.0 + hb), 0.01, "with a stamen: × (1 + healing bonus %d%%) final damage" % int(round(hb * 100.0)))


func test_cone_of_light_hits_the_cone_and_heals_the_wounded(t: TestCtx) -> void:
	# 她在原点朝 +z：锥形里 4 个木桩(其中一个 4 米外)，身后一个、侧后方一个不在锥形里；两个受伤的队友
	var specs: Array = [{"def": "node_noble", "pos": Vector2(0, 0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.6, 1.4)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(-1.5, 1.6)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0.4, 4.0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, -2.0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(3.0, -0.6)},
		{"def": "node_shielder", "pos": Vector2(-4, -4), "hp_ratio": 0.3}, {"def": "node_shielder", "pos": Vector2(4, -4), "hp_ratio": 0.6}]
	var b := Fixture.make(specs)
	var n: BUnit = b.units[0]
	_calm(n)
	for i in range(7, 9):
		_calm(b.units[i])
	var cone: Dictionary = n.cone_cfg()
	t.ok(cone.is_empty(), "no stamen: no cone")
	_stamen(b, n, 3)
	cone = n.cone_cfg()
	t.near(float(cone["angle"]), 120.0, 0.01, "120° cone")
	t.near(float(cone["length"]), 4.5, 0.01, "4.5 m")
	var hit: Array[BUnit] = Targeting.cone_targets(b, n, Vector2(0, 1), cone)
	t.eq(hit.size(), 4, "4 dummies in the cone")
	t.ok(not hit.has(b.units[5]) and not hit.has(b.units[6]), "the ones behind / to the side are not")
	var hb: float = n.get_stats().healing_done_pct
	var per: float = n.get_stats().attack_power * _y(1) * (1.0 + hb)
	var a0: float = b.units[7].hp
	var a1: float = b.units[8].hp
	b.pipeline.normal_attack(n, b.units[1], false, {"attack_variant": "cone", "cone_dir": Vector2(0, 1), "na_scale": _y(1), "no_splash": true})
	var dmg: Dictionary = {}
	var total := 0.0
	for e: Dictionary in Fixture.events_of(b, "damage", "normal_attack"):
		dmg[e["dst"]] = float(e["amount"])
		total += float(e["amount"])
	t.eq(dmg.size(), 4, "hits everyone in the cone, nobody else")
	t.near(float(dmg.get(b.units[4], 0.0)), per, 0.01, "each takes %d%% of the normal attack" % int(_y(1) * 100.0))
	t.eq(n.status_stacks("lily_stamen"), 2, "spends 1 stamen")
	var healed: float = (b.units[7].hp - a0) + (b.units[8].hp - a1)
	t.near(healed, minf(total, b.units[7].get_stats().max_health * 0.7 + b.units[8].get_stats().max_health * 0.4), 1.0,
		"heals the wounded for the damage dealt (%.0f)" % total)
	t.near(b.units[7].hp_ratio(), b.units[8].hp_ratio(), 0.001, "smartly: tops up the lowest first, evening them out")
	# 打完 3 层就恢复正常普攻
	b.pipeline.normal_attack(n, b.units[1], false, {"attack_variant": "cone", "cone_dir": Vector2(0, 1), "na_scale": _y(1), "no_splash": true})
	b.pipeline.normal_attack(n, b.units[1], false, {"attack_variant": "cone", "cone_dir": Vector2(0, 1), "na_scale": _y(1), "no_splash": true})
	t.eq(n.status_stacks("lily_stamen"), 0, "3 stamens = 3 cones")
	t.ok(n.cone_cfg().is_empty(), "back to normal attacks")


func test_cone_limit_is_multi_attack_9(t: TestCtx) -> void:
	var specs: Array = [{"def": "node_noble", "pos": Vector2(0, 0)}]
	for i in range(12):
		var ang: float = deg_to_rad(-50.0 + 100.0 * float(i) / 11.0)
		specs.append({"def": "test_dummy", "team": 1, "pos": Vector2(sin(ang), cos(ang)) * (1.4 + 0.2 * float(i % 3))})
	var b := Fixture.make(specs)
	var n: BUnit = b.units[0]
	_calm(n)
	_stamen(b, n, 1)
	t.eq(Targeting.cone_limit(n), 9, "【Multi-Attack 9】")
	b.pipeline.normal_attack(n, b.units[1], false, {"attack_variant": "cone", "cone_dir": Vector2(0, 1), "na_scale": _y(1), "no_splash": true})
	t.eq(Fixture.events_of(b, "damage", "normal_attack").size(), 9, "12 in the cone, 9 hit")


func test_ai_swings_the_cone_with_a_stamen(t: TestCtx) -> void:
	for wid: String in ["", "true_flower", "basic_focus"]:
		var b := Fixture.make([{"def": "node_noble", "pos": Vector2(0, -1.0), "weapon": wid}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.6)},
			{"def": "test_dummy", "team": 1, "pos": Vector2(1.3, 0.9)}, {"def": "test_dummy", "team": 1, "pos": Vector2(-1.3, 1.1)}])
		var n: BUnit = b.units[0]
		b.start()
		_stamen(b, n, 1)
		var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 2.5)
		var sw: Array[Dictionary] = _of(evs, "cone_sweep")
		t.eq(sw.size(), 1, "%s: one cone swing (1 stamen)" % (wid if wid != "" else "sword"))
		var starts: Array[Dictionary] = _of(evs, "attack_start")
		var cone_anim := false
		for s: Dictionary in starts:
			if str(s.get("variant", "")) == "cone":
				cone_anim = str(s.get("anim", "")).begins_with("attack_cone_noble")
		t.ok(cone_anim, "%s: plays her light-blade sweep" % (wid if wid != "" else "sword"))
		if not sw.is_empty():
			t.eq((sw[0]["targets"] as Array).size(), 3, "all three dummies in the sweep")
		t.eq(n.status_stacks("lily_stamen"), 0, "stamen spent")


func test_knight_of_the_lily_knight(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_noble", "pos": Vector2(0, 0), "weapon": "true_flower"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 8)}])
	var n: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	_calm(n)
	b.start()
	_run(b, GC.START_DELAY + 0.1)
	_petals(b, n, 8)
	n.hp = 1000.0
	var evs: Array[Dictionary] = _run(b, b.time + 0.5)
	t.eq(Fixture.events_of(b, "damage", "equipment").size(), 0, "nobody within 3 m: nothing")
	foe.pos = Vector2(0, 3.0)
	evs = _run(b, b.time + 0.1)
	var hits: Array[Dictionary] = []
	for e: Dictionary in _of(evs, "damage"):
		if e["surface"] == "equipment":
			hits.append(e)
	t.eq(hits.size(), 1, "an enemy enters 3 m: triggers")
	var v: float = n.get_stats().attack_power * n.get_stats().healing_done_pct * _trig("node_noble_knight").ratio_for(1)
	t.near(float(hits[0]["amount"]), v * 1.5, 0.5, "attack × healing bonus × z = %.0f → True Flower: × 150%% magic" % v)
	t.eq(hits[0]["kind"], "magic", "magic damage")
	t.eq(hits[0]["category"], "normal_attack", "counts as normal-attack damage")
	var heals: Array[Dictionary] = []
	for h: Dictionary in _of(evs, "heal"):
		if h["dst"] == n and h["surface"] == "equipment":
			heals.append(h)
	t.eq(heals.size(), 1, "then heals her")
	var fl: AbilityDef = Fixture.catalog().get_equipment("true_flower").abilities[0]
	var n2: float = fl.value_multiplier * float(fl.effect_config["extra_effects"][0]["value_multiplier"])
	t.near(float(heals[0]["amount"]), v * n2 * (1.0 + n.get_stats().healing_done_pct), 0.5, "trigger value × %d%% (her healing bonus applies)" % int(round(n2 * 100.0)))
	evs = _run(b, b.time + 1.0)
	t.eq(_of(evs, "damage").filter(func(e: Dictionary) -> bool: return e["surface"] == "equipment").size(), 0, "still inside, < 2 s: nothing more")
	evs = _run(b, b.time + 1.0)
	t.eq(_of(evs, "damage").filter(func(e: Dictionary) -> bool: return e["surface"] == "equipment").size(), 1, "stayed 2 s: triggers again")
	foe.pos = Vector2(0, 8)
	_run(b, b.time + 0.2)
	foe.pos = Vector2(0, 2.5)
	evs = _run(b, b.time + 0.1)
	t.eq(_of(evs, "damage").filter(func(e: Dictionary) -> bool: return e["surface"] == "equipment").size(), 1, "left and came back: enters again")


func test_knight_value_is_zero_without_healing_bonus(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_noble", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 2)}])
	var n: BUnit = b.units[0]
	var tr: TriggerDef = _trig("node_noble_knight")
	var ev: Dictionary = b.pipeline.make_event("OnEnemyNear", n, b.units[1], 0.0, ["enemy_near"], {})
	t.near(b.pipeline.trigger_value(tr, ev, n, null), 0.0, 0.0001, "no healing bonus → trigger value 0 (as written: attack × healing bonus × z)")
	_petals(b, n, 12)
	t.near(b.pipeline.trigger_value(tr, ev, n, null), n.get_stats().attack_power * 12.0 * _x(1) * tr.ratio_for(1), 0.001, "12 petals: full value")


func test_true_flower_charges(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_noble", "pos": Vector2(0, 0), "weapon": "true_flower"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 8)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(1, 8)}, {"def": "test_dummy", "team": 1, "pos": Vector2(-1, 8)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(2, 8)}])
	var n: BUnit = b.units[0]
	_calm(n)
	b.start()
	_run(b, GC.START_DELAY + 0.1)
	_petals(b, n, 4)
	for i in range(1, 5):
		b.units[i].pos = Vector2(float(i) - 2.5, 2.0)
	var evs: Array[Dictionary] = _run(b, b.time + 0.1)
	t.eq(_of(evs, "damage").filter(func(e: Dictionary) -> bool: return e["surface"] == "equipment").size(), 3, "4 enemies at once: 【Charged 3】 = 3 hits")
	evs = _run(b, b.time + 1.0)
	t.ok(_of(evs, "damage").filter(func(e: Dictionary) -> bool: return e["surface"] == "equipment").size() <= 1, "then 1 per second")


func test_texts_match_data(t: TestCtx) -> void:
	var pct := func(f: Callable) -> String:
		return "{★%d%%/%d%%/%d%%}" % [int(round(float(f.call(1)) * 100.0)), int(round(float(f.call(2)) * 100.0)), int(round(float(f.call(3)) * 100.0))]
	var num := func(f: Callable) -> String:
		return "{★%d/%d/%d}" % [int(f.call(1)), int(f.call(2)), int(f.call(3))]
	var sx: String = pct.call(_x)
	var shp: String = num.call(func(s: int) -> float: return _at("4", "max_health", s))
	var sdr: String = num.call(func(s: int) -> float: return _at("8", "defense", s))
	var sy: String = pct.call(_y)
	var sz: String = pct.call(func(s: int) -> float: return _trig("node_noble_knight").ratio_for(s))
	var flower: AbilityDef = Fixture.catalog().get_equipment("true_flower").abilities[0]
	var n1 := "%d%%" % int(round(flower.value_multiplier * 100.0))
	var n2 := "%d%%" % int(round(flower.value_multiplier * float(flower.effect_config["extra_effects"][0]["value_multiplier"]) * 100.0))
	for lang: String in ["zh", "en"]:
		var p1: String = Loc.t_in(lang, "unit.node_noble.passive.node_noble_lily")
		t.ok(p1.contains(sx) and p1.contains(shp) and p1.contains(sdr), "%s: petals %s / %s / %s" % [lang, sx, shp, sdr])
		t.ok(Loc.t_in(lang, "unit.node_noble.passive.node_noble_rebloom").contains(sy), "%s: cone %s" % [lang, sy])
		t.ok(Loc.t_in(lang, "unit.node_noble.trigger.node_noble_knight").contains(sz), "%s: knight z %s" % [lang, sz])
		var wd: String = Loc.t_in(lang, "equipment.true_flower.desc")
		t.ok(wd.contains(n1) and wd.contains(n2), "%s: True Flower %s / %s" % [lang, n1, n2])
