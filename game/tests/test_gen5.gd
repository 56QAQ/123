extends RefCounted
## 通用武器 · gen5(手弩 6 把)：数据(格子 / 随机池 / 外观 / 投射物)、适配角色、每把的效果(探针触发器直接扣载荷，抄 test_generic_weapons.gd)。

## 分给 gen5 的格子：id -> [费用, 颜色]
const GRID := {
	"g5_rime_crossbow": [2, "purple"], "g5_gale_crossbow": [2, "cyan"], "g5_flare_launcher": [3, "red"],
	"g5_thunder_crossbow": [3, "yellow"], "g5_hive_crossbow": [4, "yellow"], "g5_thorn_crossbow": [4, "green"],
}
## 合手的棋子(设计时就是冲着它们做的；FitTags 也要算出来)
const CARRIERS := {
	"g5_rime_crossbow": ["node_archer", "node_nurse"], "g5_gale_crossbow": ["node_angel", "node_cowboy"],
	"g5_flare_launcher": ["node_archer", "node_nurse"], "g5_thunder_crossbow": ["node_archer", "node_commando"],
	"g5_hive_crossbow": ["node_nurse", "node_cowboy"], "g5_thorn_crossbow": ["node_cowboy", "node_taoist"],
}
## 不射弩箭的：自己的投射物(game/view/proj_kinds/gen5.gd)
const OWN_PROJ := {
	"g5_rime_crossbow": "g5_ice_shard", "g5_flare_launcher": "g5_flare", "g5_thunder_crossbow": "g5_spark_bolt",
	"g5_hive_crossbow": "g5_bee", "g5_thorn_crossbow": "g5_seed",
}
const Models = preload("res://tools/weapons/gen5_models.gd")


func _probe(v: float) -> TriggerDef:
	return TriggerDef.from_dict({"id": "probe_trigger", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
		"target_rule": "event_target", "team_filter": "any", "base_value_mode": "fixed", "base_value_flat": v})


## 用探针触发器扣一次(先清掉冷却)；返回这一次的事件
func _pull(b: Battle, u: BUnit, target: BUnit, v: float) -> Array[Dictionary]:
	u.ability_cd.clear()
	u.trig_cd.clear()
	return _pull_noclear(b, u, target, v)


## 不清冷却地扣一次(【基本】没有冷却：连扣都生效)
func _pull_noclear(b: Battle, u: BUnit, target: BUnit, v: float) -> Array[Dictionary]:
	b.poll_events()
	var ev: Dictionary = b.pipeline.make_event("OnBattleFrame", u, target, 0.0, ["battle_frame"], {})
	b.pipeline._fire(ev, _probe(v), u)
	b.pipeline.drain()
	return b.poll_events()


## 携带者(打手) + 一个队友木桩 + 一个敌人木桩(+ 可选：敌人身边 1 米的第二个敌人、它身边的一个队友)
func _setup(weapon: String, extra: Array = []) -> Battle:
	var specs: Array = [{"def": "test_hitter", "pos": Vector2(0, -3), "weapon": weapon}, {"def": "test_dummy", "pos": Vector2(2, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}]
	specs.append_array(extra)
	var b := Fixture.make(specs)
	b.start()
	for u: BUnit in b.units:
		u.attack_cd = 1.0e9
		u.base.crit_chance = 0.0
		u.mark_dirty()
	return b


func _eq(id: String) -> EquipmentDef:
	return Fixture.catalog().get_equipment(id)


static func _sum(evs: Array[Dictionary], type: String, dst: BUnit) -> float:
	var s := 0.0
	for e: Dictionary in evs:
		if e.get("t") == type and e.get("dst") == dst:
			s += float(e.get("amount", 0.0))
	return s


static func _kinds(evs: Array[Dictionary], dst: BUnit) -> Array:
	var r: Array = []
	for e: Dictionary in evs:
		if e.get("t") == "damage" and e.get("dst") == dst and not r.has(str(e["kind"])):
			r.append(str(e["kind"]))
	return r


# ---------------------------------------------------------------- 数据
func test_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var pool: Array[String] = cat.equipment_ids()
	var looks := {}
	for id: String in GRID.keys():
		var e: EquipmentDef = cat.get_equipment(id)
		t.ok(e != null, "%s exists" % id)
		if e == null:
			continue
		t.ok(e.owner == "" and e.reworked and not e.no_drop and pool.has(id), "%s: no owner, reworked, in the random pool" % id)
		t.eq([e.cost, e.color_id, e.class_id], [int(GRID[id][0]), str(GRID[id][1]), "crossbow"], "%s sits in its grid cell (cost / color / class)" % id)
		t.ok(e.model.begins_with("g5") and Models.PARTS.has("W_crossbow_" + e.model), "%s has its own model W_crossbow_%s" % [id, e.model])
		looks[e.model] = true
		if OWN_PROJ.has(id):
			t.eq(e.projectile, str(OWN_PROJ[id]), "%s shoots its own projectile" % id)
			t.ok(ProjRegistry.has(e.projectile), "%s: projectile %s is registered" % [id, e.projectile])
		else:
			t.ok(e.projectile == "" or e.projectile == "bolt", "%s shoots the class's bolt" % id)
		for a: AbilityDef in e.abilities:
			t.ok(a.required_trigger_tags.has("equipment_payload"), "%s: %s is an equipment payload" % [id, a.id])
	t.eq(looks.size(), GRID.size(), "every weapon has a different look")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_fit_units(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	for id: String in CARRIERS.keys():
		var fit: Array[String] = cat.fit_units(id)
		t.ok(fit.size() >= 2, "%s fits %d units (%s)" % [id, fit.size(), ",".join(fit)])
		for uid: String in CARRIERS[id]:
			t.ok(fit.has(uid), "%s fits %s" % [id, uid])


func test_carriers_can_equip(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	for wid: String in CARRIERS.keys():
		var e: EquipmentDef = cat.get_equipment(wid)
		for uid: String in CARRIERS[wid]:
			for star: int in [1, 2, 3]:
				t.eq(e.equip_problem(cat.get_unit(uid), star), "", "%s fits %s ★%d" % [wid, uid, star])


# ---------------------------------------------------------------- 霜棱手弩
func test_rime_crossbow(t: TestCtx) -> void:
	var b := _setup("g5_rime_crossbow")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("g5_rime_crossbow")
	var n: int = int(e.abilities[0].effect_config["repeat"])
	var r: float = e.abilities[1].value_multiplier
	var as0: float = foe.get_stats().attack_speed_multiplier
	var evs: Array[Dictionary] = _pull(b, u, foe, 100.0)
	t.eq(foe.status_count("chill"), n, "an enemy gains %d Chill" % n)
	t.near(foe.get_stats().attack_speed_multiplier, as0 - 0.1 * float(n), 0.001, "each Chill: -10% attack speed")
	t.near(_sum(evs, "damage", foe), 100.0 * r, 1.0, "the second part: trigger value × %.0f%% magic damage" % (r * 100.0))
	t.eq(_kinds(evs, foe), ["magic"], "magic")
	t.eq(foe.shield, 0.0, "no shield for enemies")
	_pull_noclear(b, u, foe, 100.0)
	_pull_noclear(b, u, foe, 100.0)
	t.ok(foe.get_status("frozen") != null, "more than 40% of Chill freezes it")
	evs = _pull(b, u, ally, 200.0)
	t.near(ally.shield, e.abilities[0].fixed_value + 200.0 * r, 1.0, "an ally gains %.0f + trigger value × %.0f%% shield" % [e.abilities[0].fixed_value, r * 100.0])
	t.eq(ally.status_count("chill"), 0, "and no Chill")
	t.eq(_sum(evs, "damage", ally), 0.0, "and isn't hurt")
	var s1: float = ally.shield
	_pull_noclear(b, u, ally, 200.0)
	t.near(ally.shield - s1, e.abilities[0].fixed_value, 1.0, "【Basic】 part again right away; the scaled part is on cooldown")


# ---------------------------------------------------------------- 青岚手弩
func test_gale_crossbow(t: TestCtx) -> void:
	var b := _setup("g5_gale_crossbow")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var cfg: Dictionary = _eq("g5_gale_crossbow").abilities[0].effect_config["extra_effects"][0]
	var per: float = float(cfg["stats"]["attack_speed_multiplier"]["flat"])
	var cap: int = int(cfg["max_stacks"])
	var as0: float = u.get_stats().attack_speed_multiplier
	var evs: Array[Dictionary] = _pull(b, u, foe, 100.0)
	t.eq(u.status_stacks("g5_gale"), 1, "the holder gains Gale, whoever the trigger target is (an enemy)")
	t.eq(foe.get_status("g5_gale"), null, "the enemy doesn't")
	t.eq(_sum(evs, "damage", foe), 0.0, "and isn't hurt")
	var sh: float = float(_eq("g5_gale_crossbow").abilities[0].effect_config["extra_effects"][1]["fixed_value"])
	t.near(u.shield, sh, 0.5, "the holder also gains a %.0f-point shield" % sh)
	t.eq(foe.shield, 0.0, "the enemy doesn't")
	_pull_noclear(b, u, ally, 100.0)
	t.eq(u.status_stacks("g5_gale"), 2, "an ally as the target: still the holder")
	t.eq(ally.shield, 0.0, "no shield for the ally either")
	t.eq(ally.get_status("g5_gale"), null, "not the ally")
	for i in range(cap + 3):
		_pull_noclear(b, u, u, 100.0)
	t.eq(u.status_stacks("g5_gale"), cap, "up to %d stacks" % cap)
	t.near(u.get_stats().attack_speed_multiplier, as0 + per * float(cap), 0.001, "+%.0f%% attack speed a stack" % (per * 100.0))
	t.near(u.get_stats().haste, per * float(cap), 0.001, "haste")
	t.near(u.get_stats().reload_time_pct, -per * float(cap), 0.001, "and faster reloads")
	t.eq(u.get_status("g5_gale").expires_at, -1.0, "lasts the battle")
	var wt: Dictionary = FitTags.weapon_tags(_eq("g5_gale_crossbow"))
	t.ok(bool(wt["any_target"]) and str(wt["side"]) == "dual" and bool(wt["basic"]), "fit tags: ignores the target, 【Basic】")


# ---------------------------------------------------------------- 救难信号弩
func test_flare_launcher(t: TestCtx) -> void:
	var b := _setup("g5_flare_launcher")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("g5_flare_launcher")
	var r: float = e.abilities[2].value_multiplier
	var amp: float = float(e.abilities[1].effect_config["stats"]["damage_taken_amp"]["flat"])
	var evs: Array[Dictionary] = _pull(b, u, foe, 100.0)
	t.eq(foe.status_count("burning"), 1, "an enemy is set Burning")
	t.ok(foe.get_status("g5_flare_mark") != null, "and Lit Up")
	t.near(_sum(evs, "damage", foe), 100.0 * r * (1.0 + amp), 1.0, "and takes trigger value × %.0f%% magic damage (+%.0f%% while Lit Up)" % [r * 100.0, amp * 100.0])
	ally.hp = 1000.0
	evs = _pull(b, u, ally, 200.0)
	var hb: float = 1.0 + u.get_stats().healing_done_pct
	t.near(_sum(evs, "heal", ally), (e.abilities[0].fixed_value + 200.0 * r) * hb, 1.0, "an ally heals %.0f + trigger value × %.0f%%" % [e.abilities[0].fixed_value, r * 100.0])
	t.eq(ally.status_count("burning"), 0, "and doesn't burn")
	t.eq(ally.get_status("g5_flare_mark"), null, "or get Lit Up")
	t.eq(_sum(evs, "damage", ally), 0.0, "or get hurt")
	_pull_noclear(b, u, foe, 100.0)
	t.eq(foe.status_count("burning"), 2, "【Basic】: Burning stacks up as separate fires")


# ---------------------------------------------------------------- 雷鸣手弩
func test_thunder_crossbow(t: TestCtx) -> void:
	# 敌人身边 1 米还有一个敌人(电弧跳过去)和一个队友(不该被电到)
	var b := _setup("g5_thunder_crossbow", [{"def": "test_dummy", "team": 1, "pos": Vector2(1, 3)}, {"def": "test_dummy", "pos": Vector2(-1, 3)}])
	var u: BUnit = b.units[0]
	var foe: BUnit = b.units[2]
	var foe2: BUnit = b.units[3]
	var ally2: BUnit = b.units[4]
	var e: EquipmentDef = _eq("g5_thunder_crossbow")
	var r: float = e.abilities[1].value_multiplier
	var evs: Array[Dictionary] = _pull(b, u, foe, 1000.0)
	var st: BStatus = foe.get_status("paralysis")
	t.ok(st != null, "the target is Paralyzed")
	var p: float = float(st.meta.get("paralyze", 0.0)) if st != null else 0.0
	t.near(p, float(e.abilities[0].effect_config["extra_effects"][0]["fixed_value"]) / 100.0, 0.001, "Paralysis %.0f%%" % (p * 100.0))
	var d: float = _sum(evs, "damage", foe)
	t.ok(d >= e.abilities[0].fixed_value + 1000.0 * r * 0.99, "fixed %.0f + trigger value × %.0f%% magic damage (%.0f)" % [e.abilities[0].fixed_value, r * 100.0, d])
	t.eq(_kinds(evs, foe), ["magic"], "magic")
	t.ok(_sum(evs, "damage", foe2) >= 1000.0 * r * 0.5 * 0.99, "the arc jumps to an enemy beside it (half)")
	t.eq(_sum(evs, "damage", ally2), 0.0, "but not to an ally standing there")
	var d2: float = _sum(_pull_noclear(b, u, foe, 1000.0), "damage", foe)
	t.ok(d2 > 0.0 and d2 < 1000.0 * r * 0.5, "right after: only the 【Basic】 part (the arc is on cooldown)")


# ---------------------------------------------------------------- 蜂巢手弩
func test_hive_crossbow(t: TestCtx) -> void:
	var b := _setup("g5_hive_crossbow")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("g5_hive_crossbow")
	var hc: Dictionary = e.abilities[0].effect_config["ally_effect"]["cfg"]
	var vc: Dictionary = e.abilities[0].effect_config["enemy_effect"]["cfg"]
	var r: float = e.abilities[1].value_multiplier
	ally.hp = 1000.0
	var atk0: float = ally.get_stats().attack_power
	var evs: Array[Dictionary] = _pull(b, u, ally, 200.0)
	t.eq(ally.status_stacks("g5_honey"), 1, "an ally gets Honey")
	t.eq(ally.get_status("g5_venom"), null, "not Venom")
	t.near(ally.get_stats().attack_power, atk0 * (1.0 + float(hc["stats"]["attack_power"]["pct"])), 0.5, "more attack")
	t.near(_sum(evs, "heal", ally), 200.0 * r * (1.0 + u.get_stats().healing_done_pct), 1.0, "and heals trigger value × %.0f%%" % (r * 100.0))
	for i in range(4):
		_pull_noclear(b, u, ally, 200.0)
	t.eq(ally.status_stacks("g5_honey"), 3, "Honey stacks to 3")
	evs = _pull(b, u, foe, 200.0)
	t.eq(foe.status_stacks("g5_venom"), 1, "an enemy gets Venom")
	t.eq(foe.get_status("g5_honey"), null, "not Honey")
	t.near(_sum(evs, "damage", foe), 200.0 * r, 1.0, "and takes trigger value × %.0f%% physical damage" % (r * 100.0))
	t.eq(_kinds(evs, foe), ["physical"], "physical")
	var vst: BStatus = foe.get_status("g5_venom")
	t.near(float(vst.dot.get("amount", 0.0)), float(vc["dot"]["amount"]), 0.01, "Venom: %.0f magic a second a stack" % float(vc["dot"]["amount"]))
	t.ok(ally.get_status("g5_honey").dot.is_empty(), "Honey doesn't hurt")


# ---------------------------------------------------------------- 荆棘手弩
func test_thorn_crossbow(t: TestCtx) -> void:
	var b := _setup("g5_thorn_crossbow")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("g5_thorn_crossbow")
	var fixed: float = e.abilities[0].fixed_value
	var evs: Array[Dictionary] = _pull(b, u, ally, 999.0)
	t.near(ally.shield, fixed, 0.5, "an ally gains a fixed %.0f shield (trigger value doesn't matter)" % fixed)
	t.eq(ally.status_count("regen"), 1, "and a Regeneration")
	t.eq(_sum(evs, "damage", ally), 0.0, "and isn't hurt")
	t.eq(ally.get_status("g5_thorn_bind"), null, "or bound")
	evs = _pull(b, u, foe, 999.0)
	t.near(_sum(evs, "damage", foe), fixed, 0.5, "an enemy takes a fixed %.0f physical damage" % fixed)
	t.eq(_kinds(evs, foe), ["physical"], "physical")
	t.ok(foe.get_status("g5_thorn_bind") != null and foe.has_flag("rooted"), "and is Thornbound (rooted)")
	t.ok(foe.is_disarmed(), "…and can't make normal attacks")
	t.eq(foe.status_count("regen"), 0, "no Regeneration for enemies")
	t.eq(foe.shield, 0.0, "or shield")
	_pull_noclear(b, u, ally, 1.0)
	t.eq(ally.status_count("regen"), 2, "【Basic】: again right away (Regeneration stacks as separate instances)")
