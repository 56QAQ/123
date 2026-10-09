extends RefCounted
## 通用武器 · gen8(手枪 6 把)：数据(格子 / 随机池 / 外观 / 投射物)、适配角色、每把的效果(探针触发器直接扣载荷，抄 test_generic_weapons.gd)。

## 分给 gen8 的格子：id -> [费用, 颜色]
const GRID := {
	"g8_peapod_pistols": [2, "green"], "g8_rivet_guns": [2, "blue"], "g8_dart_pistols": [3, "purple"],
	"g8_crane_pistols": [3, "cyan"], "g8_firework_tubes": [4, "red"], "g8_sunray_blasters": [4, "yellow"],
}
## 合手的棋子(测强度定下的；FitTags 也要算出来)
const CARRIERS := {
	"g8_peapod_pistols": ["node_cowboy", "node_taoist"], "g8_rivet_guns": ["node_shielder", "node_rogue"],
	"g8_dart_pistols": ["node_archer", "node_nurse"], "g8_crane_pistols": ["node_angel", "node_shielder"],
	"g8_firework_tubes": ["node_archer", "node_nurse"], "g8_sunray_blasters": ["node_psychic", "node_commando"],
}
## 标签算上、但实测不合手(拿手枪时触发器不响 / 测出来 +0)而去掉的
const NOT_FIT := {
	"g8_dart_pistols": ["node_maid"], "g8_firework_tubes": ["node_maid"],
}
## 都射自己的投射物(game/view/proj_kinds/gen8.gd)
const OWN_PROJ := {
	"g8_peapod_pistols": "g8_pea", "g8_rivet_guns": "g8_rivet", "g8_dart_pistols": "g8_dart",
	"g8_crane_pistols": "g8_crane", "g8_firework_tubes": "g8_rocket", "g8_sunray_blasters": "g8_sunbeam",
}
const Models = preload("res://tools/weapons/gen8_models.gd")


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


## 探针触发器：目标规则 rule(多目标用)
func _pull_rule(b: Battle, u: BUnit, rule: String, team: String, v: float, clear: bool = true) -> Array[Dictionary]:
	if clear:
		u.ability_cd.clear()
		u.trig_cd.clear()
	b.poll_events()
	var trig := TriggerDef.from_dict({"id": "probe_trigger_multi", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
		"target_rule": rule, "team_filter": team, "base_value_mode": "fixed", "base_value_flat": v})
	b.pipeline._fire(b.pipeline.make_event("OnBattleFrame", u, null, 0.0, ["battle_frame"], {}), trig, u)
	b.pipeline.drain()
	return b.poll_events()


## 携带者(打手) + 一个队友木桩 + 一个敌人木桩(+ extra)
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
		t.eq([e.cost, e.color_id, e.class_id], [int(GRID[id][0]), str(GRID[id][1]), "pistols"], "%s sits in its grid cell (cost / color / class)" % id)
		t.ok(e.model.begins_with("g8_") and Models.PARTS.has("W_pistols_" + e.model) and Models.PARTS.has("L_pistols_" + e.model),
			"%s has its own dual-wield model W_ / L_pistols_%s" % [id, e.model])
		looks[e.model] = true
		t.eq(e.projectile, str(OWN_PROJ[id]), "%s shoots its own projectile" % id)
		t.ok(ProjRegistry.has(e.projectile), "%s: projectile %s is registered" % [id, e.projectile])
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
		for uid2: String in NOT_FIT.get(id, []):
			t.ok(not fit.has(uid2), "%s doesn't list %s" % [id, uid2])


func test_carriers_can_equip(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	for wid: String in CARRIERS.keys():
		var e: EquipmentDef = cat.get_equipment(wid)
		for uid: String in CARRIERS[wid]:
			for star: int in [1, 2, 3]:
				t.eq(e.equip_problem(cat.get_unit(uid), star), "", "%s fits %s ★%d" % [wid, uid, star])


# ---------------------------------------------------------------- 豌豆荚双枪
func test_peapod_pistols(t: TestCtx) -> void:
	var b := _setup("g8_peapod_pistols")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("g8_peapod_pistols")
	var fixed: float = e.abilities[0].fixed_value
	var shell: float = float(e.abilities[1].effect_config["ally_effect"]["cfg"]["stats"]["damage_taken_pct"]["flat"])
	var dr0: float = ally.get_stats().damage_taken_pct
	var evs: Array[Dictionary] = _pull(b, u, ally, 999.0)
	t.near(ally.shield, fixed, 0.5, "an ally gains a fixed %.0f shield (trigger value doesn't matter)" % fixed)
	t.ok(ally.get_status("g8_podshell") != null, "and a Pod Shell")
	t.near(ally.get_stats().damage_taken_pct, dr0 + shell, 0.001, "-%.0f%% damage taken" % (shell * 100.0))
	t.eq(_sum(evs, "damage", ally), 0.0, "and isn't hurt")
	t.ok(not ally.has_flag("stun"), "or stunned")
	evs = _pull(b, u, foe, 999.0)
	t.near(_sum(evs, "damage", foe), fixed, 0.5, "an enemy takes a fixed %.0f physical damage" % fixed)
	t.eq(_kinds(evs, foe), ["physical"], "physical")
	var st: BStatus = foe.get_status("stun")
	t.ok(st != null and foe.has_flag("stun"), "and is Stunned (the shared Stun)")
	if st != null:
		t.near(st.expires_at - b.time, float(e.abilities[1].effect_config["duration"]), 0.01, "for %.1f s" % float(e.abilities[1].effect_config["duration"]))
	t.eq(foe.get_status("g8_podshell"), null, "no Pod Shell for enemies")
	t.eq(foe.shield, 0.0, "or shield")
	var s1: float = ally.shield
	_pull_noclear(b, u, ally, 1.0)
	t.near(ally.shield - s1, fixed, 0.5, "【Basic】: again right away")


# ---------------------------------------------------------------- 铆钉双枪
func test_rivet_guns(t: TestCtx) -> void:
	# 携带者身边 1 米：一个队友(该分到护盾)、一个敌人(不该)；远处还有一个队友(不该)
	var b := _setup("g8_rivet_guns", [{"def": "test_dummy", "pos": Vector2(1, -2)}, {"def": "test_dummy", "team": 1, "pos": Vector2(-1, -2)},
		{"def": "test_dummy", "pos": Vector2(8, -3)}])
	var u: BUnit = b.units[0]
	var near_ally: BUnit = b.units[3]
	var near_foe: BUnit = b.units[4]
	var far_ally: BUnit = b.units[5]
	var e: EquipmentDef = _eq("g8_rivet_guns")
	var sh: float = e.abilities[0].fixed_value
	var ex: Dictionary = e.abilities[0].effect_config["extra_effects"][0]
	var cap: int = int(ex["max_stacks"])
	var per: float = float(ex["stats"]["defense"]["flat"])
	var def0: float = u.get_stats().defense
	var mr0: float = u.get_stats().magic_resistance
	_pull(b, u, u, 1.0)
	t.near(u.shield, sh, 0.5, "the trigger target (the holder) gains a %.0f shield" % sh)
	t.near(near_ally.shield, sh, 0.5, "an ally beside it gets the same (Splash, 100%)")
	t.eq(near_foe.shield, 0.0, "an enemy beside it doesn't")
	t.eq(far_ally.shield, 0.0, "nor a far-away ally")
	t.eq(u.status_stacks("g8_riveted"), 1, "the holder gains Riveted")
	t.eq(near_ally.get_status("g8_riveted"), null, "only the holder")
	for i in range(cap + 3):
		_pull_noclear(b, u, u, 1.0)
	t.eq(u.status_stacks("g8_riveted"), cap, "up to %d stacks" % cap)
	t.near(u.get_stats().defense, def0 + per * float(cap), 0.01, "+%.0f armor a stack" % per)
	t.near(u.get_stats().magic_resistance, mr0 + per * float(cap), 0.01, "and magic resistance")
	t.eq(u.get_status("g8_riveted").expires_at, -1.0, "lasts the battle")


# ---------------------------------------------------------------- 调剂镖枪
func test_dart_pistols(t: TestCtx) -> void:
	var b := _setup("g8_dart_pistols")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("g8_dart_pistols")
	var tox: Dictionary = e.abilities[0].effect_config
	var stim: Dictionary = tox["ally_effect"]["cfg"]
	var r: float = e.abilities[1].value_multiplier
	var slow: float = float(tox["stats"]["attack_speed_multiplier"]["flat"])
	var amp: float = float(tox["stats"]["damage_taken_amp"]["flat"])
	var as0: float = foe.get_stats().attack_speed_multiplier
	var evs: Array[Dictionary] = _pull(b, u, foe, 100.0)
	t.eq(foe.status_stacks("g8_neurotoxin"), 1, "an enemy gains Neurotoxin")
	t.near(foe.get_stats().attack_speed_multiplier, as0 + slow, 0.001, "%.0f%% attack speed" % (slow * 100.0))
	t.near(_sum(evs, "damage", foe), 100.0 * r * (1.0 + amp), 1.0, "and takes trigger value × %.0f%% magic damage (+%.0f%% from the toxin)" % [r * 100.0, amp * 100.0])
	t.eq(_kinds(evs, foe), ["magic"], "magic")
	t.eq(foe.get_status("g8_stimulant"), null, "no Stimulant for enemies")
	for i in range(4):
		_pull_noclear(b, u, foe, 100.0)
	t.eq(foe.status_stacks("g8_neurotoxin"), 3, "【Basic】: Neurotoxin stacks to 3")
	ally.hp = 1000.0
	var as1: float = ally.get_stats().attack_speed_multiplier
	evs = _pull(b, u, ally, 200.0)
	t.ok(ally.get_status("g8_stimulant") != null, "an ally gets the Stimulant")
	t.near(ally.get_stats().attack_speed_multiplier, as1 + float(stim["stats"]["attack_speed_multiplier"]["flat"]), 0.001, "more attack speed")
	var hrx: float = float(stim["stats"]["healing_received_pct"]["flat"])
	t.near(_sum(evs, "heal", ally), 200.0 * r * (1.0 + u.get_stats().healing_done_pct) * (1.0 + hrx), 1.0,
		"and heals trigger value × %.0f%% (+%.0f%% from the Stimulant)" % [r * 100.0, hrx * 100.0])
	t.eq(ally.get_status("g8_neurotoxin"), null, "no toxin for allies")
	t.eq(_sum(evs, "damage", ally), 0.0, "and isn't hurt")
	var h2: float = _sum(_pull_noclear(b, u, ally, 200.0), "heal", ally)
	t.eq(h2, 0.0, "right after: only the 【Basic】 part (the heal is on cooldown)")


# ---------------------------------------------------------------- 千纸鹤双枪
func _crowd(weapon: String, allies: int, foes: int) -> Battle:
	var specs: Array = [{"def": "test_hitter", "pos": Vector2(0, -3), "weapon": weapon}]
	for i in range(allies):
		specs.append({"def": "test_dummy", "pos": Vector2(1.5 + i, -3)})
	for j in range(foes):
		specs.append({"def": "test_dummy", "team": 1, "pos": Vector2(-2.0 + j, 3)})
	var b := Fixture.make(specs)
	b.start()
	for u: BUnit in b.units:
		u.attack_cd = 1.0e9
		u.base.crit_chance = 0.0
		u.mark_dirty()
	return b


func test_crane_pistols(t: TestCtx) -> void:
	var b := _crowd("g8_crane_pistols", 3, 4)
	var u: BUnit = b.units[0]
	var e: EquipmentDef = _eq("g8_crane_pistols")
	var v: float = e.abilities[0].fixed_value
	var self_sh: float = float(e.abilities[0].effect_config["pre_effects"][0]["fixed_value"])
	var amp: float = float(e.abilities[1].effect_config["stats"]["damage_taken_amp"]["flat"])
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_enemies", "enemy", 999.0)
	var hit := 0
	var cut := 0
	for f: BUnit in b.units:
		if f.team != u.team:
			var d: float = _sum(evs, "damage", f)
			if d > 0.0:
				hit += 1
				t.near(d, v, 0.5, "an enemy takes a fixed %.0f magic damage" % v)
			if f.status_stacks("g8_papercut") == 1:
				cut += 1
	t.eq(hit, 3, "Multi Attack 3")
	t.eq(cut, 3, "…and they get a Paper Cut")
	t.near(u.shield, self_sh, 0.5, "the holder gains %.0f shield once per activation (not once per target)" % self_sh)
	var foe: BUnit = null
	for f2: BUnit in b.units:
		if f2.team != u.team and f2.status_stacks("g8_papercut") > 0:
			foe = f2
			break
	for i in range(8):
		_pull_noclear(b, u, foe, 1.0)
	t.eq(foe.status_stacks("g8_papercut"), int(e.abilities[1].effect_config["max_stacks"]), "【Basic】: Paper Cut stacks up")
	t.near(foe.get_stats().damage_taken_amp, amp * float(e.abilities[1].effect_config["max_stacks"]), 0.001, "+%.0f%% damage taken a stack" % (amp * 100.0))
	# 队友：护盾(纸割不打队友)；携带者照样先拿一层
	var s0: float = u.shield
	_pull_rule(b, u, "all_allies_except_self", "ally", 999.0)
	var shielded := 0
	for a: BUnit in b.units:
		if a.team == u.team and a != u:
			if a.shield >= v - 0.5:
				shielded += 1
			t.eq(a.get_status("g8_papercut"), null, "no Paper Cut for allies")
	t.eq(shielded, 3, "allies gain a %.0f shield (Multi Attack 3)" % v)
	t.near(u.shield - s0, self_sh, 0.5, "and the holder its own shield again")
	# 架盾的样子：目标 = 自己 → 先拿一层，再按队友拿一层
	var b2 := _setup("g8_crane_pistols")
	var u2: BUnit = b2.units[0]
	_pull(b2, u2, u2, 1.0)
	t.near(u2.shield, self_sh + v, 0.5, "holder as the target: %.0f + %.0f shield" % [self_sh, v])


# ---------------------------------------------------------------- 庆典烟花筒
func test_firework_tubes(t: TestCtx) -> void:
	# 敌人身边 1 米：一个敌人(该挨炸)、一个队友(不该)；队友身边 1 米：一个队友(该一起庆典)、一个敌人(不该)
	var b := _setup("g8_firework_tubes", [{"def": "test_dummy", "team": 1, "pos": Vector2(1, 3)}, {"def": "test_dummy", "pos": Vector2(-1, 3)},
		{"def": "test_dummy", "pos": Vector2(3, -3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(2, -2)}])
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var foe2: BUnit = b.units[3]
	var ally_by_foe: BUnit = b.units[4]
	var ally2: BUnit = b.units[5]
	var foe_by_ally: BUnit = b.units[6]
	var e: EquipmentDef = _eq("g8_firework_tubes")
	var v: float = e.abilities[0].fixed_value
	var r: float = e.abilities[2].value_multiplier
	var evs: Array[Dictionary] = _pull(b, u, foe, 100.0)
	t.near(_sum(evs, "damage", foe), v + 100.0 * r, 1.0, "an enemy takes %.0f + trigger value × %.0f%% magic damage" % [v, r * 100.0])
	t.eq(_kinds(evs, foe), ["magic"], "magic")
	t.near(_sum(evs, "damage", foe2), v * 0.5, 0.5, "the burst splashes its neighbor for half")
	t.ok(foe.get_status("g8_tinnitus") != null and foe2.get_status("g8_tinnitus") != null, "both get Ringing Ears")
	t.eq(_sum(evs, "damage", ally_by_foe), 0.0, "an ally standing there isn't hurt")
	t.eq(ally_by_foe.get_status("g8_tinnitus"), null, "…or deafened")
	t.eq(ally_by_foe.get_status("g8_festival"), null, "…or celebrating")
	ally.hp = 1000.0
	ally2.hp = 1000.0
	var atk0: float = ally.get_stats().attack_power
	evs = _pull(b, u, ally, 100.0)
	var hb: float = 1.0 + u.get_stats().healing_done_pct
	t.near(_sum(evs, "heal", ally), (v + 100.0 * r) * hb, 1.0, "an ally heals %.0f + trigger value × %.0f%%" % [v, r * 100.0])
	t.near(_sum(evs, "heal", ally2), v * 0.5 * hb, 0.5, "its neighbor heals half the burst")
	t.ok(ally.get_status("g8_festival") != null and ally2.get_status("g8_festival") != null, "both celebrate")
	var fb: float = float(e.abilities[1].effect_config["ally_effect"]["cfg"]["stats"]["attack_power"]["pct"])
	t.near(ally.get_stats().attack_power, atk0 * (1.0 + fb), 0.5, "Festival: +%.0f%% attack" % (fb * 100.0))
	t.eq(_sum(evs, "heal", foe_by_ally), 0.0, "an enemy beside the ally isn't healed")
	t.eq(foe_by_ally.get_status("g8_festival"), null, "…or celebrating")
	t.eq(_sum(evs, "damage", ally) + _sum(evs, "damage", ally2), 0.0, "allies aren't hurt")
	var h2: float = _sum(_pull_noclear(b, u, ally, 100.0), "heal", ally)
	t.near(h2, v * hb, 1.0, "right after: only the 【Basic】 burst (the scaled part is on cooldown)")


# ---------------------------------------------------------------- 金阳射线枪
func test_sunray_blasters(t: TestCtx) -> void:
	var b := _crowd("g8_sunray_blasters", 0, 4)
	var u: BUnit = b.units[0]
	var e: EquipmentDef = _eq("g8_sunray_blasters")
	var r: float = e.abilities[0].value_multiplier
	var dz: Dictionary = e.abilities[0].effect_config["extra_effects"][0]
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_enemies", "enemy", 100.0)
	var hit := 0
	var dazzled := 0
	for f: BUnit in b.units:
		if f.team != u.team:
			var d: float = _sum(evs, "damage", f)
			if d > 0.0:
				hit += 1
				t.near(d, 100.0 * r, 0.5, "trigger value × %.0f%% magic damage" % (r * 100.0))
				t.eq(_kinds(evs, f), ["magic"], "magic")
			if f.get_status("g8_dazzled") != null:
				dazzled += 1
				t.near(f.get_stats().attack_speed_multiplier, 1.0 + float(dz["stats"]["attack_speed_multiplier"]["flat"]), 0.001, "Dazzled: slower attacks")
	t.eq(hit, 3, "Multi Attack 3")
	t.eq(dazzled, 3, "…and they are Dazzled")
	var evs2: Array[Dictionary] = _pull_rule(b, u, "all_enemies", "enemy", 100.0, false)
	var d2 := 0.0
	for f2: BUnit in b.units:
		if f2.team != u.team:
			d2 += _sum(evs2, "damage", f2)
	t.eq(d2, 0.0, "2 s cooldown")
