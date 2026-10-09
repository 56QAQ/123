extends RefCounted
## 重构版灾星节点：初星的魔女(召唤护星节点；不能移动；打任何队友射程里的敌人、无视掩体；普攻是天降火流星、按法强算；
## 模版攻击力 1:1 转法强)、魔女的火与冰(2 星：能装红色、不能装[双模]；红色武器 → 每个[溅射]/[群攻]命中目标 +最终伤害，友方算 2；
## 蓝色武器 → [叠加]额外叠层)、魔女的笑与泪(每 5 秒，以人最多的召唤物队友为中心 6 米内所有人；没有召唤物 ÷3)、
## 专属武器流星爆魔杖(【充能 2】从 0 开始、【群攻 12】【溅射 3】，流星落地才结算)。


func _run_until(b: Battle, sec: float) -> void:
	while b.time < sec and b.state != "ended":
		b.step()


func _of(b: Battle, id: String, team: int = 0) -> BUnit:
	for u: BUnit in b.units:
		if u.def.id == id and u.team == team and u.alive:
			return u
	return null


func test_template_attack_becomes_ability_power_and_she_cannot_move(t: TestCtx) -> void:
	for star: int in [1, 3]:
		var b := Fixture.make([{"def": "node_witch", "pos": Vector2.ZERO, "star": star}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}])
		var w: BUnit = b.units[0]
		t.near(w.get_stats().attack_power, 0.0, 0.001, "%d★: attack 0" % star)
		t.near(w.get_stats().ability_power, 70.0 * GC.star_mult(star), 0.01, "%d★: template attack 70 → ability power (scaled by star)" % star)
		b.start()
		_run_until(b, 6.0)
		t.ok(w.pos.distance_to(Vector2.ZERO) < 0.01, "%d★: never moves" % star)
		t.ok(_of(b, "node_warrior") != null, "summons Node Warrior")


func test_strikes_anything_in_a_teammates_reach_through_walls(t: TestCtx) -> void:
	# 她在后面，队友(打手)贴着敌人；两人之间隔一堵高墙
	var layout := {"truck": false, "obstacles": [{"x": 7, "y": 5, "w": 5, "h": 1, "kind": "high"}]}
	var b := Fixture.make([{"def": "node_witch", "pos": Vector2(0, -5), "weapon": "basic_focus"},
		{"def": "test_hitter", "pos": Vector2(0, 3.0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 4.0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(8, -6)}], 7, layout)
	var w: BUnit = b.units[0]
	var far: BUnit = b.units[3]
	b.start()
	_run_until(b, GC.START_DELAY + 4.0)
	var hits := 0
	var far_hits := 0
	for e: Dictionary in Fixture.events_of(b, "damage", "normal_attack"):
		if e["src"] == w:
			if e["dst"] == far:
				far_hits += 1
			else:
				hits += 1
	t.ok(hits > 0, "hits the enemy standing in her teammate's reach, 9 m away behind a wall (%d)" % hits)
	t.eq(far_hits, 0, "ignores an enemy nobody on her team can reach")
	t.ok(not Fixture.events_of(b, "meteor_na").is_empty(), "each normal attack is a falling meteor")


func test_normal_attacks_scale_with_ability_power_and_polearm_hits_two(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_witch", "pos": Vector2.ZERO, "weapon": "basic_focus"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}])
	var w: BUnit = b.units[0]
	w.base.crit_chance = 0.0
	w.mark_dirty()
	b.deliver_normal_attack(w, b.units[1], false, {})
	t.ok(Fixture.events_of(b, "damage", "normal_attack").is_empty(), "nothing yet — the meteor is still falling")
	b.advance_pending(0.5)
	var d: Array[Dictionary] = Fixture.events_of(b, "damage", "normal_attack")
	t.eq(d.size(), 1, "the meteor lands")
	t.near(float(d[0]["amount"]), w.get_stats().ability_power, 0.05, "damage = ability power × 1 (0-MR dummy)")
	var b2 := Fixture.make([{"def": "node_witch", "pos": Vector2.ZERO, "weapon": "basic_polearm"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.5, 3.2)},
		{"def": "test_hitter", "pos": Vector2(0, 2)}])
	b2.start()
	_run_until(b2, GC.START_DELAY + 3.0)
	var seen: Dictionary = {}
	for e: Dictionary in Fixture.events_of(b2, "damage", "normal_attack"):
		if e["src"] == b2.units[0]:
			seen[e["dst"]] = true
	t.eq(seen.size(), 2, "polearm: every attack is 【群攻 2】")


func test_meteor_staff_first_cast_at_10_s_centered_on_the_warrior(t: TestCtx) -> void:
	var specs: Array = [{"def": "node_witch", "pos": Vector2(0, -6), "star": 2, "weapon": "meteor_staff"}]
	for i in range(4):
		specs.append({"def": "test_dummy", "team": 1, "pos": Vector2(-1.2 + 0.8 * i, 2.5)})
	var b := Fixture.make(specs)
	var w: BUnit = b.units[0]
	b.start()
	var wr: BUnit = _of(b, "node_warrior")
	wr.pos = Vector2(0, 1.5)
	wr.base.move_speed = 0.0
	wr.mark_dirty()
	_run_until(b, 9.9)
	t.ok(Fixture.events_of(b, "meteor_cast").is_empty(), "no charge before 8 s, the 5 s trigger fizzles")
	_run_until(b, 10.2)
	var casts: Array[Dictionary] = Fixture.events_of(b, "meteor_cast")
	t.eq(casts.size(), 1, "first meteor volley at 10 s")
	t.eq((casts[0]["points"] as Array).size(), 5, "targets: the warrior + 4 enemies within 6 m (not herself)")
	t.near((casts[0]["points"] as Array)[0].distance_to(wr.pos), 0.0, 0.3, "the summoned teammate first")
	# 一颗接一颗错开落地(每颗各自结算)，不是全部一同落地
	var dl: Array = casts[0].get("delays", [])
	t.eq(dl.size(), 5, "one delay per meteor")
	var lands: Array = []
	for pe: Dictionary in b.pending_exec:
		lands.append(float(pe["at"]))
	lands.sort()
	t.eq(lands.size(), 5, "five meteors resolve separately")
	t.ok(lands.size() == 5 and lands[4] - lands[0] > 0.5 and lands[1] - lands[0] > 0.05, "…landing one after another (spread %.2f s)" % (float(lands[-1]) - float(lands[0]) if not lands.is_empty() else 0.0))
	var n0: int = Fixture.events_of(b, "damage", "equipment").size()
	_run_until(b, 10.2 + 0.8)
	var hit_self := false
	var hit_warrior := false
	for e: Dictionary in Fixture.events_of(b, "damage", "equipment"):
		hit_self = hit_self or e["dst"] == w
		hit_warrior = hit_warrior or e["dst"] == wr
	t.ok(Fixture.events_of(b, "damage", "equipment").size() > n0, "meteors land 0.7 s later")
	t.ok(hit_warrior and not hit_self, "the warrior is hit (sacrificed), she isn't")


func test_without_a_summon_the_value_drops_to_a_third(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_witch", "pos": Vector2(0, -6), "star": 2, "weapon": "meteor_staff"},
		{"def": "test_hitter", "pos": Vector2(0, 1.5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 2.5)}])
	var w: BUnit = b.units[0]
	var tr: TriggerDef = null
	for x: TriggerDef in w.def.triggers:
		if x.id == "node_witch_smile":
			tr = x
	var ev: Dictionary = b.pipeline.make_event("OnBattleFrame", w, null, 0.0, ["battle_frame"], {})
	var tg: Array[BUnit] = Targeting.resolve(b, ev, tr, w.weapon.abilities[0], w)
	t.eq(tg[0], b.units[1], "no summon: the busiest non-summon teammate is the center")
	t.near(b.pipeline.trigger_value(tr, ev, w, null), w.get_stats().ability_power * tr.ratio_for(2) / 3.0, 0.01, "value ÷3 (法强 × x)")


func test_fire_red_weapon_adds_final_damage_per_aoe_target(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_witch", "pos": Vector2(0, -8), "star": 2, "weapon": "meteor_staff"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(20, 20)}])
	var w: BUnit = b.units[0]
	b.start()
	t.near(w.get_stats().aoe_hit_amp_pct, 0.08, 0.0001, "2★ with a red weapon: +8% per target")
	var ab: AbilityDef = w.weapon.abilities[0]
	var ctx := {"unit": w, "entry": {"ability": ab, "surface": "equipment", "equip": w.weapon}, "targets": [b.units[1]] as Array[BUnit],
		"ev": {"meta": {}}, "aim_point": null}
	t.near(b.pipeline._aoe_mult(w, ab, ctx), 1.08, 0.0001, "one enemy hit via 【群攻】 → ×1.08")
	var ally := b.spawn_unit(Fixture.catalog().get_unit("test_dummy"), 0, 1, Vector2(1, 0), false)
	t.near(b.pipeline._aoe_mult(w, ab, ctx), 1.08 + 0.16, 0.0001, "+ an ally splashed → counts as 2")
	var b1 := Fixture.make([{"def": "node_witch", "pos": Vector2.ZERO, "star": 1, "weapon": "basic_focus"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}])
	b1.start()
	t.near(b1.units[0].get_stats().aoe_hit_amp_pct, 0.0, 0.0001, "1★: locked")


func test_equip_rules_from_two_stars(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = cat.get_unit("node_witch")
	var staff: EquipmentDef = cat.get_equipment("meteor_staff")
	var halberd: EquipmentDef = cat.get_equipment("energy_halberd")
	t.eq(staff.equip_problem(d, 1), "ui.err.color_mismatch", "1★: a red weapon doesn't fit a blue unit")
	t.eq(staff.equip_problem(d, 2), "", "2★: red weapons are allowed")
	t.eq(halberd.equip_problem(d, 1), "", "1★: a 【双模】 cyan polearm is fine")
	t.eq(halberd.equip_problem(d, 2), "ui.err.forbidden_rule", "2★: 【双模】 is forbidden")
	# 合星升到 2 星：拿着的[双模]武器自动回背包
	var r := Run.create(cat, 5)
	var ids: Array[String] = []
	for i in range(3):
		ids.append(str(r.add_unit("node_witch", 1, null, i)["id"]))
	r.roster[ids[0]]["weapon"] = "energy_halberd"
	r._merge_all()
	for u: Dictionary in r.roster.values():
		if u["def"] == "node_witch":
			t.eq(int(u["star"]), 2, "2★")
			t.eq(str(u["weapon"]), "", "the 【双模】 weapon was taken off")
	t.ok(r.inventory.has("energy_halberd"), "…and went back to the inventory")


func test_ice_blue_weapon_adds_extra_stacks(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_witch", "pos": Vector2.ZERO, "star": 3, "weapon": "basic_focus"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}])
	var w: BUnit = b.units[0]
	w.base.extra_stacks = 2.0                 # 等同于 3 星 + 蓝色武器
	w.mark_dirty()
	b.pipeline.fx.apply_status(w, b.units[1], {"status_id": "probe", "max_stacks": 5, "stat_id": "defense", "flat": -1.0})
	t.eq(b.units[1].status_stacks("probe"), 3, "1 + 2 extra stacks")
