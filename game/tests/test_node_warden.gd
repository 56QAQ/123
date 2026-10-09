extends RefCounted
## 守林节点：护林狂怒(狮子 → 巨蜘蛛 → 巨蟾蜍 → 基础形态，每次本应阵亡时换下一个；变身时攻击模组与武器无关：狮子按生命值算、带追击，
## 巨蜘蛛叠中毒，巨蟾蜍加护甲魔抗并缠住目标)、荒野意志(切换形态时 1 点生命 + 护盾，包括开局)、原初血脉(切换形态时含开局，最大生命 × z × (100 + 法强)%)；
## 专武翠绿之林(【充能 2】【学习】：每 n1 点 (4 − 学习)% 攻速、每 n2 点 学习% 最大生命回复)。


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
	return Fixture.catalog().get_unit("node_warden")


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


func _kill_hit(b: Battle, v: BUnit, foe: BUnit) -> void:
	v.shield = 0.0
	b.pipeline.fx.damage(foe, v, v.hp + 5000.0, "true", {})


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = _def()
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model], [4, "green", "research", "caster", "polearm", "warden"],
		"rarity 4, green, Research, caster, two-handed long, warden model (renamed from shaman)")
	t.eq(d.weapon_classes, ["polearm", "sword", "focus"] as Array[String], "can equip one-hand melee and focus")
	var e: EquipmentDef = cat.get_equipment("verdant_grove")
	t.eq([e.class_id, e.color_id, e.cost, e.owner, e.model], ["polearm", "green", 4, "node_warden", "verdant"], "Verdant Grove: two-handed long, green, rarity 4, hers")
	var ab: AbilityDef = e.abilities[0]
	t.ok(ab.has_keyword("learning") and ab.keyword_value("charged", 1) == 2 and ab.cooldown == 12.0, "12 s cooldown 【Charged 2】【Learning】")
	t.ok(float(e.flat_mods.get("max_health", 0.0)) > 0.0 and float(e.flat_mods.get("ability_power", 0.0)) > 0.0, "max health + ability power")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_lion_form_attacks_with_health_and_pursuit(t: TestCtx) -> void:
	for star: int in [1, 3]:
		var b := Fixture.make([{"def": "node_warden", "pos": Vector2(0, -0.5), "star": star, "weapon": "basic_focus"},
			{"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.5)}])
		var w: BUnit = b.units[0]
		var foe: BUnit = b.units[1]
		b.start()
		_calm(w)
		_run(b, GC.START_DELAY + 0.1)
		t.eq(Pipeline.warden_form(w), "lion", "★%d enters battle as a lion" % star)
		t.ok(not w.is_ranged(), "★%d melee claws even with a focus in hand" % star)
		t.eq(Pipeline.kw_value(w, w.na_payload(), "pursuit"), int(_def().passive_by_id("node_warden_fury").effect_config["forms"]["lion"]["pursuit_by_star"][str(star)]),
			"★%d 【Pursuit】 by star" % star)
		b.poll_events()
		b.pipeline.normal_attack(w, foe)
		var dmg: Array[Dictionary] = Fixture.events_of(b, "damage", "normal_attack")
		t.near(float(dmg[-1]["amount"]), w.get_stats().max_health * 0.06, 0.5, "★%d claw = 6%% of max health (%.0f), physical" % [star, w.get_stats().max_health * 0.06])
		t.eq(dmg[-1]["kind"], "physical", "physical (not the focus's magic)")


func test_deaths_walk_through_the_forms(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_warden", "pos": Vector2(0, -3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 8)}])
	var w: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	b.start()
	_calm(w)
	_run(b, GC.START_DELAY + 0.1)
	var def0: float = w.get_stats().defense
	var want_sh: float = w.get_stats().max_health * float(_trig("node_warden_will").ratio_for(1)) * (1.0 + w.get_stats().ability_power / 100.0)
	t.near(w.shield, want_sh, 1.0, "the opening lion gets the Will of the Wild shield too (%.0f)" % want_sh)
	_kill_hit(b, w, foe)
	t.ok(w.alive, "1st death: still standing")
	t.eq(Pipeline.warden_form(w), "spider", "→ giant spider")
	t.near(w.hp, 1.0, 0.01, "with 1 health")
	t.near(w.shield, want_sh, 1.0, "and a max health × y × (100 + AP)%% shield (%.0f)" % want_sh)
	_kill_hit(b, w, foe)
	t.eq(Pipeline.warden_form(w), "toad", "2nd death → giant toad")
	var dr: float = float(_def().passive_by_id("node_warden_fury").effect_config["forms"]["toad"]["stats_by_star"]["defense"]["flat"]["1"])
	t.near(w.get_stats().defense, def0 + dr, 0.01, "toad: +%d armor" % int(dr))
	_kill_hit(b, w, foe)
	t.ok(w.alive and Pipeline.warden_form(w) == "base", "3rd death → base form")
	t.ok(w.is_ranged() == bool(GC.weapon_class(w.weapon_class()).get("ranged", false)), "base form: the weapon's own attack again")
	t.near(w.get_stats().defense, def0, 0.01, "toad armor gone")
	_kill_hit(b, w, foe)
	t.ok(not w.alive, "4th death is real")


func test_spider_poisons(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_warden", "pos": Vector2(0, -0.5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.6)}])
	var w: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	b.start()
	_calm(w)
	_run(b, GC.START_DELAY + 0.1)
	_kill_hit(b, w, foe)
	t.eq(Pipeline.warden_form(w), "spider", "spider")
	b.pipeline.normal_attack(w, foe)
	b.pipeline.normal_attack(w, foe)
	t.eq(foe.status_count("poison"), 2, "each hit adds its own Poison")
	var per: float = _trig("node_warden_venom").flat_for(1) * (1.0 + w.get_stats().ability_power / 100.0)
	var st: BStatus = foe.status_instances("poison")[0]
	t.near(float(st.dot["amount"]), per, 0.01, "%.1f magic per second (x × (100 + AP)%%)" % per)
	t.ok(st.has_flag("dispellable") and st.has_flag("debuff"), "dispellable debuff")
	var evs: Array[Dictionary] = _run(b, b.time + 2.05)
	var ticks: Array[Dictionary] = _of(evs, "damage").filter(func(e: Dictionary) -> bool: return e["dst"] == foe and e["surface"] == "status")
	t.eq(ticks.size(), 4, "2 poisons × 2 ticks in 2 s")


func test_toad_binds_and_lets_go(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_warden", "pos": Vector2(0, -0.5)}, {"def": "test_hitter", "team": 1, "pos": Vector2(0, 0.7)}])
	var w: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	b.start()
	_calm(w)
	_calm(foe)
	_run(b, GC.START_DELAY + 0.1)
	_kill_hit(b, w, foe)
	_kill_hit(b, w, foe)
	t.eq(Pipeline.warden_form(w), "toad", "toad")
	b.pipeline.normal_attack(w, foe)
	t.ok(foe.status_count("toad_bind") > 0 and w.status_count("toad_bind") > 0, "tongue: both bound (like the Ember of Lust)")
	t.ok(foe.has_flag("rooted") and foe.forced_target == w, "the enemy is rooted and has to target her")
	_kill_hit(b, w, foe)
	t.eq(Pipeline.warden_form(w), "base", "→ base form")
	t.eq(foe.status_count("toad_bind") + w.status_count("toad_bind"), 0, "leaving toad form lets go")
	t.ok(foe.forced_target != w, "no longer forced onto her")


func test_primal_blood_and_verdant_grove(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_warden", "pos": Vector2(0, -3), "weapon": "verdant_grove"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 8)}])
	var w: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	b.start()
	_calm(w)
	_run(b, GC.START_DELAY + 0.1)
	var st: StatBlock = w.get_stats()
	var v0: float = st.max_health * _trig("node_warden_blood").ratio_for(1) * (1.0 + st.ability_power / 100.0)
	var ab: AbilityDef = Fixture.catalog().get_equipment("verdant_grove").abilities[0]
	var n1: float = float(ab.effect_config["n1"])
	var n2: float = float(ab.effect_config["n2"])
	var hs: BStatus = w.get_status("verdant_haste")
	t.ok(hs != null, "opening shift (lion) triggers Primal Blood → Verdant Grove")
	t.near(float(hs.pct_per_stack.get("attack_speed_multiplier", 0.0)), 4.0 * v0 / n1 / 100.0, 0.0005, "learning 0: +4%% AS per %d (%.1f%%)" % [int(n1), 4.0 * v0 / n1])
	t.eq(int(w.learning.get(ab.id, 0)), 1, "learning count +1")
	w.hp = 200.0
	_kill_hit(b, w, foe)
	var v1: float = w.get_stats().max_health * _trig("node_warden_blood").ratio_for(1) * (1.0 + w.get_stats().ability_power / 100.0)
	t.near(float(w.get_status("verdant_haste").pct_per_stack["attack_speed_multiplier"]), (4.0 * v0 / n1 + 3.0 * v1 / n1) / 100.0, 0.0005,
		"learning 1: +3% per n1 more (adds up)")
	var heal_want: float = w.get_stats().max_health * 1.0 * v1 / n2 / 100.0 * (1.0 + w.get_stats().healing_done_pct)
	t.ok(w.hp > 1.0 + heal_want * 0.9, "and restores 1%% max health per %d (%.0f)" % [int(n2), heal_want])


func test_form_animations_match_the_attack_timing(t: TestCtx) -> void:
	var lib: AnimationLibrary = load("res://assets/archer_anims.res") as AnimationLibrary
	var forms: Dictionary = _def().passive_by_id("node_warden_fury").effect_config["forms"]
	for f: String in ["lion", "spider", "toad"]:
		for kind: String in ["idle", "run"]:
			var nm: String = "%s_warden_%s" % [kind, f]
			t.ok(lib.has_animation(nm) and lib.get_animation(nm).loop_mode == Animation.LOOP_LINEAR, nm + " loops")
		var an: String = "attack_warden_" + f
		var wf: Dictionary = forms[f]["wclass_form"]
		t.ok(lib.has_animation(an), an + " baked")
		if lib.has_animation(an):
			t.near(lib.get_animation(an).length, float(wf["interval"]), 0.02, "%s lasts one attack interval (%.2f s)" % [an, float(wf["interval"])])
	for nm: String in ["shift_warden", "fidget_warden", "victory_warden"]:
		t.ok(lib.has_animation(nm), nm + " baked")
