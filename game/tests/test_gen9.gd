extends RefCounted
## 通用武器 · gen9(矛 3 把 + 双手剑 3 把)：凝潮长枪 / 曦光长枪 / 星轨长枪(矛)、荆棘巨剑 / 凯旋巨剑 / 涌泉巨剑(双手剑)。
## 每把用一个"探针触发器"(目标 = 事件目标 / 指定规则、固定触发数值)直接扣动载荷验证效果；再查数据(格子、外观、随机池)和适配角色。

## 武器 -> [费用, 颜色, 大类, 外观]
const SLOTS := {
	"g9_rimetide_spear": [2, "cyan", "polearm", "g9_rimetide"],
	"g9_dawnlight_spear": [3, "yellow", "polearm", "g9_dawnlight"],
	"g9_starorbit_lance": [4, "purple", "polearm", "g9_starorbit"],
	"g9_thornbrand": [2, "green", "heavy", "g9_thorn"],
	"g9_laurel_greatsword": [3, "red", "heavy", "g9_laurel"],
	"g9_wellspring_greatsword": [4, "cyan", "heavy", "g9_wellspring"],
}
## 合手的棋子(测强度定下的)：都要在适配角色里，并且 1~3 星都装得上
const CARRIERS := {
	"g9_rimetide_spear": ["node_cultist", "node_astronaut"],
	"g9_dawnlight_spear": ["node_peasant", "node_warden"],
	"g9_starorbit_lance": ["node_druid", "node_magi"],
	"g9_thornbrand": ["node_killer", "node_samurai"],
	"g9_laurel_greatsword": ["node_gladiator", "node_darkknight"],
	"g9_wellspring_greatsword": ["node_vampire", "node_paladin"],
}


func _probe(v: float) -> TriggerDef:
	return TriggerDef.from_dict({"id": "probe_trigger_g9", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
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


## 探针触发器：目标规则 rule(多目标用)；clear = 先清冷却
func _pull_rule(b: Battle, u: BUnit, rule: String, team: String, v: float, clear: bool = true) -> Array[Dictionary]:
	if clear:
		u.ability_cd.clear()
		u.trig_cd.clear()
	b.poll_events()
	var trig := TriggerDef.from_dict({"id": "probe_trigger_g9_multi", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
		"target_rule": rule, "team_filter": team, "base_value_mode": "fixed", "base_value_flat": v})
	b.pipeline._fire(b.pipeline.make_event("OnBattleFrame", u, null, 0.0, ["battle_frame"], {}), trig, u)
	b.pipeline.drain()
	return b.poll_events()


## 携带者 + allies 个木桩队友 + foes 个木桩敌人(都不攻击、不动)
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


func _eq(id: String) -> EquipmentDef:
	return Fixture.catalog().get_equipment(id)


func _cfg(id: String, i: int = 0) -> Dictionary:
	return _eq(id).abilities[i].effect_config


static func _sum(evs: Array[Dictionary], type: String, dst: BUnit) -> float:
	var s := 0.0
	for e: Dictionary in evs:
		if e.get("t") == type and e.get("dst") == dst:
			s += float(e.get("amount", 0.0))
	return s


static func _kinds(evs: Array[Dictionary]) -> Array:
	return evs.filter(func(e: Dictionary) -> bool: return e.get("t") == "damage").map(func(e: Dictionary) -> String: return str(e["kind"]))


func _foes(b: Battle, u: BUnit) -> Array[BUnit]:
	var r: Array[BUnit] = []
	for f: BUnit in b.units:
		if f.team != u.team:
			r.append(f)
	return r


func _allies(b: Battle, u: BUnit) -> Array[BUnit]:
	var r: Array[BUnit] = []
	for a: BUnit in b.units:
		if a.team == u.team and a != u:
			r.append(a)
	return r


## 身上有几个【寒气】(每个都是独立的实例)
static func _chills(u: BUnit) -> int:
	var n := 0
	for st: BStatus in u.statuses.values():
		if st.has_flag("chill"):
			n += 1
	return n


# ================================================================ 数据 / 适配
func test_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var pool: Array[String] = cat.equipment_ids()
	var models := {}
	for id: String in SLOTS.keys():
		var e: EquipmentDef = cat.get_equipment(id)
		var s: Array = SLOTS[id]
		t.ok(e != null, "%s exists" % id)
		if e == null:
			continue
		t.ok(e.owner == "" and e.reworked and not e.no_drop and not e.basic, "%s: generic (no owner), reworked, droppable" % id)
		t.ok(pool.has(id), "%s is in the random pool (orbs / black market / workshop / events)" % id)
		t.eq([e.cost, e.color_id, e.class_id], [s[0], s[1], s[2]], "%s sits in its slot (cost / color / class)" % id)
		t.eq(e.model, str(s[3]), "%s has its own look" % id)
		t.ok(not models.has(e.model), "%s: look not shared with another gen9 weapon" % id)
		models[e.model] = true
		t.eq(e.projectile, "", "%s is melee: no projectile of its own" % id)
		t.ok(not ProjRegistry.trail(e.model).is_empty(), "%s has its own sword trail (proj_kinds/gen9.gd TRAILS)" % id)
		for a: AbilityDef in e.abilities:
			t.ok(a.required_trigger_tags.has("equipment_payload"), "%s/%s pairs with weapon triggers" % [id, a.id])
	# 外观全局唯一：别的武器(专武、其他批)没有用同一个外观名
	for oid: String in cat.equipment.keys():
		var o: EquipmentDef = cat.get_equipment(oid)
		if not SLOTS.has(oid) and o.model != "" and models.has(o.model):
			t.ok(false, "look %s is also used by %s" % [o.model, oid])
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_fit(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	for wid: String in CARRIERS.keys():
		var fits: Array[String] = cat.fit_units(wid)
		t.ok(fits.size() >= 2, "%s fits %d pieces (%s)" % [wid, fits.size(), ",".join(fits)])
		var e: EquipmentDef = cat.get_equipment(wid)
		for uid: String in CARRIERS[wid]:
			t.ok(fits.has(uid), "%s fits %s" % [wid, uid])
			for star: int in [1, 2, 3]:
				t.eq(e.equip_problem(cat.get_unit(uid), star), "", "%s can be equipped by %s ★%d" % [wid, uid, star])


# ================================================================ 凝潮长枪
func test_rimetide_spear(t: TestCtx) -> void:
	var id := "g9_rimetide_spear"
	var a: AbilityDef = _eq(id).abilities[0]
	var ex: Dictionary = (a.effect_config["extra_effects"] as Array)[0]
	var reps: int = int(ex.get("repeat", 1))
	var ma: int = int(a.keyword_values.get("multi_attack", 1))
	# 6 个敌人：【群攻】只打其中 ma 个，各吃固定的魔法伤害(不看触发数值)和 reps 个【寒气】
	var b := _crowd(id, 0, 6)
	var u: BUnit = b.units[0]
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_enemies", "enemy", 999.0)
	var hit := 0
	for f: BUnit in _foes(b, u):
		var d: float = _sum(evs, "damage", f)
		if d > 0.0:
			hit += 1
			t.near(d, a.fixed_value, a.fixed_value * 0.05, "a target takes a fixed %.0f damage, whatever the trigger value" % a.fixed_value)
			t.eq(_chills(f), reps, "and gets %d Chill" % reps)
		else:
			t.eq(_chills(f), 0, "an enemy that wasn't hit isn't chilled")
	t.eq(hit, ma, "Multi Attack %d: %d of the 6 enemies" % [ma, ma])
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "magic"), "magic damage")
	t.eq(_chills(u), 0, "the holder isn't chilled")
	# 【基本】：没有冷却，连扣几下，寒气合计超过 40% 就冻结(冻结 = 眩晕，寒气全部消耗)
	var b2 := _crowd(id, 0, ma)
	var u2: BUnit = b2.units[0]
	var need: int = int(floor(GC.FREEZE_OVER / (GC.CHILL_AS * float(reps)) + 0.0001)) + 1
	for i in range(need):
		_pull_rule(b2, u2, "all_enemies", "enemy", 1.0, false)
	var frozen := 0
	for f2: BUnit in _foes(b2, u2):
		if f2.get_status("frozen") != null and f2.is_stunned() and _chills(f2) < reps * need:
			frozen += 1
	t.eq(frozen, ma, "【Basic】: %d pulls in a row freeze all %d targets (the Chill is used up)" % [need, ma])
	t.near(u2.get_stats().attack_speed_multiplier, 1.0 + float(_eq(id).pct_mods.get("attack_speed_multiplier", 0.0)), 0.001, "the holder attacks faster")


# ================================================================ 曦光长枪
func test_dawnlight_spear(t: TestCtx) -> void:
	var id := "g9_dawnlight_spear"
	var b := _crowd(id, 1, 1)
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var a: AbilityDef = _eq(id).abilities[0]
	var ex: Dictionary = (a.effect_config["extra_effects"] as Array)[0]
	var dr: float = float(ex["stats"]["damage_taken_pct"]["flat"])
	var atkp: float = float(ex["stats"]["attack_power"]["pct"])
	var dr0: float = u.get_stats().damage_taken_pct
	var atk0: float = u.get_stats().attack_power
	var evs: Array[Dictionary] = _pull(b, u, u, 300.0)
	t.near(u.shield, 300.0 * a.value_multiplier, 300.0 * a.value_multiplier * 0.05 + 0.5, "self: a shield of value × %.0f%%" % (a.value_multiplier * 100.0))
	t.ok(u.get_status("g9_dawnlight") != null, "and Dawnlight")
	t.near(u.get_stats().damage_taken_pct, dr0 + dr, 0.001, "+%.0f%% damage reduction" % (dr * 100.0))
	t.near(u.get_stats().attack_power, atk0 * (1.0 + atkp), 0.5, "+%.0f%% attack" % (atkp * 100.0))
	t.ok(absf(float(u.get_status("g9_dawnlight").expires_at) - b.time - float(ex["duration"])) < 0.01, "lasts %.0f s" % float(ex["duration"]))
	t.eq(_sum(evs, "damage", u), 0.0, "no damage to the holder")
	# 冷却 2 秒
	var sh0: float = u.shield
	_pull_noclear(b, u, u, 300.0)
	t.near(u.shield, sh0, 0.01, "2 s cooldown")
	# 队友也行
	_pull(b, u, ally, 200.0)
	t.near(ally.shield, 200.0 * a.value_multiplier, 200.0 * a.value_multiplier * 0.05 + 0.5, "an ally: a shield too")
	t.ok(ally.get_status("g9_dawnlight") != null and foe.get_status("g9_dawnlight") == null, "an ally gets Dawnlight; the enemy doesn't")


# ================================================================ 星轨长枪
func test_starorbit_lance(t: TestCtx) -> void:
	var id := "g9_starorbit_lance"
	var b := _crowd(id, 3, 6)
	var u: BUnit = b.units[0]
	var c0: Dictionary = _cfg(id, 0)
	var c1: Dictionary = _cfg(id, 1)
	var arm: float = float(c0["ally_effect"]["cfg"]["stats"]["defense"]["flat"])
	var weak: float = float(c0["enemy_effect"]["cfg"]["stats"]["attack_power"]["pct"])
	var h: float = float(c1["ally_effect"]["value_multiplier"])
	var r: float = float(c1["enemy_effect"]["value_multiplier"])
	var ma: int = int(_eq(id).abilities[0].keyword_values.get("multi_attack", 1))
	var team: Array[BUnit] = [u]
	team.append_array(_allies(b, u))
	for m: BUnit in team:
		m.hp = m.get_stats().max_health * 0.5
	var a0: BUnit = _allies(b, u)[0]
	var def0: float = a0.get_stats().defense
	# 队友(含自己)：【星护】+ 回复 触发数值 × h
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_allies", "ally", 200.0)
	var warded := 0
	for m2: BUnit in team:
		if m2.get_status("g9_star_ward") != null:
			warded += 1
			t.near(_sum(evs, "heal", m2), 200.0 * h, 200.0 * h * 0.05 + 0.5, "an ally heals value × %.0f%%" % (h * 100.0))
		t.eq(_sum(evs, "damage", m2), 0.0, "allies aren't hurt")
	t.eq(warded, mini(ma, team.size()), "Multi Attack %d: allies (self included) gain Star Ward" % ma)
	t.near(a0.get_stats().defense, def0 + arm, 0.01, "+%.0f armor" % arm)
	# 敌人：【星蚀】+ 触发数值 × r 魔法伤害，最多 ma 个
	var atk0: float = _foes(b, u)[0].get_stats().attack_power
	evs = _pull_rule(b, u, "all_enemies", "enemy", 200.0)
	var hit := 0
	for f: BUnit in _foes(b, u):
		var d: float = _sum(evs, "damage", f)
		if d > 0.0:
			hit += 1
			t.near(d, 200.0 * r, 200.0 * r * 0.05, "an enemy takes value × %.0f%% magic" % (r * 100.0))
			t.ok(f.get_status("g9_star_eclipse") != null, "and is Eclipsed")
			t.near(f.get_stats().attack_power, atk0 * (1.0 + weak), 0.5, "%.0f%% attack" % (weak * 100.0))
		t.ok(f.get_status("g9_star_ward") == null, "enemies don't get Star Ward")
		t.eq(_sum(evs, "heal", f), 0.0, "enemies aren't healed")
	t.eq(hit, ma, "Multi Attack %d: %d of the 6 enemies" % [ma, ma])
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "magic"), "magic damage")
	# 冷却 2 秒
	evs = _pull_rule(b, u, "all_enemies", "enemy", 200.0, false)
	var again := 0.0
	for f2: BUnit in _foes(b, u):
		again += _sum(evs, "damage", f2)
	t.eq(again, 0.0, "2 s cooldown")


# ================================================================ 荆棘巨剑
func test_thornbrand(t: TestCtx) -> void:
	var id := "g9_thornbrand"
	var b := _crowd(id, 0, 2)
	var u: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	var clean: BUnit = b.units[2]
	var a: AbilityDef = _eq(id).abilities[0]
	var ex: Dictionary = (a.effect_config["extra_effects"] as Array)[0]
	var per: float = -float(ex["stats"]["na_damage_taken_flat"]["flat"])
	var maxs: int = int(ex["max_stacks"])
	var evs: Array[Dictionary] = _pull(b, u, foe, 999.0)
	t.near(_sum(evs, "damage", foe), a.fixed_value, a.fixed_value * 0.05, "fixed %.0f physical, whatever the trigger value" % a.fixed_value)
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "physical"), "physical damage")
	t.eq(foe.status_stacks("g9_thorns"), 1, "the target gains a stack of Thorns")
	t.eq(u.status_stacks("g9_thorns"), 0, "not the holder")
	for i in range(maxs + 2):
		_pull_noclear(b, u, foe, 1.0)
	t.eq(foe.status_stacks("g9_thorns"), maxs, "【Basic】: every pull adds a stack, up to %d" % maxs)
	# 每一下普攻伤害 + 层数 × per(减伤之后加)；别的伤害不变
	var na := {"surface": "normal_attack", "ability_id": "probe"}
	var hit_t: float = b.pipeline.fx.damage(u, foe, 100.0, "physical", na.duplicate())
	var hit_c: float = b.pipeline.fx.damage(u, clean, 100.0, "physical", na.duplicate())
	t.near(hit_t - hit_c, per * float(maxs), 0.5, "each normal-attack hit it takes deals +%.0f (%d stacks × %.0f)" % [per * float(maxs), maxs, per])
	var sk := {"surface": "passive", "ability_id": "probe"}
	t.near(b.pipeline.fx.damage(u, foe, 100.0, "physical", sk.duplicate()), b.pipeline.fx.damage(u, clean, 100.0, "physical", sk.duplicate()), 0.01,
		"other damage isn't changed")
	# t 秒后掉光(不再续)
	var frames: int = int(round((float(ex["duration"]) + 0.5) / GC.SIM_DT))
	for i2 in range(frames):
		b.step()
	t.eq(foe.status_stacks("g9_thorns"), 0, "wears off after %.0f s without new stacks" % float(ex["duration"]))


# ================================================================ 凯旋巨剑
func test_laurel_greatsword(t: TestCtx) -> void:
	var id := "g9_laurel_greatsword"
	var b := _crowd(id, 1, 1)
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var a: AbilityDef = _eq(id).abilities[0]
	var cfg: Dictionary = a.effect_config
	var per_v: float = 1.0 / a.value_multiplier
	var maxs: int = int(cfg["max_stacks"])
	var atkp: float = float(cfg["stats"]["attack_power"]["pct"])
	var ls: float = float(cfg["stats"]["physical_lifesteal"]["flat"])
	var hx: float = float((cfg["extra_effects"] as Array)[0]["value_multiplier"]) * a.value_multiplier
	u.hp = u.get_stats().max_health * 0.5
	var atk0: float = u.get_stats().attack_power
	var ls0: float = u.get_stats().physical_lifesteal
	# 狩胜的一次击杀(数值 ≈ 38)：每 per_v 点一层(四舍五入)，并回复 触发数值 × hx
	var v1: float = per_v * 1.9
	var evs: Array[Dictionary] = _pull(b, u, u, v1)
	t.eq(u.status_stacks("g9_laurel"), 2, "value %.0f → 2 stacks (1 per %.0f, rounded)" % [v1, per_v])
	t.near(_sum(evs, "heal", u), v1 * hx, v1 * hx * 0.05 + 0.5, "and heals value × %.0f%%" % (hx * 100.0))
	# 【基本】：连着扣也生效；数值很小也至少一层
	_pull_noclear(b, u, u, 1.0)
	t.eq(u.status_stacks("g9_laurel"), 3, "【Basic】, and at least one stack")
	# 守誓的觉醒(数值 ≈ 715)：一下叠满
	_pull_noclear(b, u, u, per_v * 40.0)
	t.eq(u.status_stacks("g9_laurel"), maxs, "a big value fills it up to %d at once" % maxs)
	t.near(u.get_stats().attack_power, atk0 * (1.0 + float(maxs) * atkp), 0.5, "+%.0f%% attack a stack" % (atkp * 100.0))
	t.near(u.get_stats().physical_lifesteal, ls0 + float(maxs) * ls, 0.001, "+%.0f%% physical lifesteal a stack" % (ls * 100.0))
	var st: BStatus = u.get_status("g9_laurel")
	t.ok(st.has_flag("no_dispel"), "can't be dispelled")
	for i in range(int(round(30.0 / GC.SIM_DT))):
		b.step()
	t.eq(u.status_stacks("g9_laurel"), maxs, "lasts the battle")
	_pull(b, u, ally, per_v * 3.0)
	t.eq(ally.status_stacks("g9_laurel"), 3, "an ally target gets it too")
	t.eq(foe.status_stacks("g9_laurel"), 0, "the enemy doesn't")


# ================================================================ 涌泉巨剑
func test_wellspring_greatsword(t: TestCtx) -> void:
	var id := "g9_wellspring_greatsword"
	var b := _crowd(id, 3, 6)
	var u: BUnit = b.units[0]
	var a: AbilityDef = _eq(id).abilities[0]
	var r: float = a.value_multiplier
	var ma: int = int(a.keyword_values.get("multi_attack", 1))
	var al: Array[BUnit] = _allies(b, u)
	u.hp = 10.0                                  # 携带者自己最少——但"血量最少的队友"不算自己
	al[0].hp = 30000.0
	al[1].hp = 1000.0                            # 血量最少的队友
	al[2].hp = 60000.0
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_enemies", "enemy", 500.0)
	var hit := 0
	var dealt := 0.0
	for f: BUnit in _foes(b, u):
		var d: float = _sum(evs, "damage", f)
		if d > 0.0:
			hit += 1
			dealt += d
			t.near(d, 500.0 * r, 500.0 * r * 0.05, "a target takes value × %.0f%% magic" % (r * 100.0))
	t.eq(hit, ma, "Multi Attack %d: %d of the 6 enemies" % [ma, ma])
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "magic"), "magic damage")
	t.near(_sum(evs, "heal", al[1]), dealt, dealt * 0.02 + 0.5, "the ally with the least health heals as much as was dealt")
	t.eq(_sum(evs, "heal", al[0]) + _sum(evs, "heal", al[2]), 0.0, "nobody else")
	t.eq(_sum(evs, "heal", u), 0.0, "not the holder")
	# 冷却 3 秒
	evs = _pull_rule(b, u, "all_enemies", "enemy", 500.0, false)
	var again := 0.0
	for f2: BUnit in _foes(b, u):
		again += _sum(evs, "damage", f2)
	t.eq(again, 0.0, "3 s cooldown")
