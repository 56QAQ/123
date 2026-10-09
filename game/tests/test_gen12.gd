extends RefCounted
## 通用武器 · gen12(矛 2 把 + 单手剑 2 把 + 双手剑 2 把)：鲸歌长枪 / 翠竹长枪(矛)、金雀细剑 / 紫藤长剑(单手剑)、梦魇巨剑 / 金钟巨剑(双手剑)。
## 每把用一个"探针触发器"(目标 = 事件目标 / 指定规则、固定触发数值)直接扣动载荷验证效果；再查数据(格子、外观、随机池、刀光)和适配角色。

## 武器 -> [费用, 颜色, 大类, 外观]
const SLOTS := {
	"g12_whalesong_spear": [2, "blue", "polearm", "g12_whalesong"],
	"g12_jadebamboo_spear": [4, "cyan", "polearm", "g12_jadebamboo"],
	"g12_goldfinch_rapier": [2, "yellow", "sword", "g12_goldfinch"],
	"g12_wisteria_sword": [4, "purple", "sword", "g12_wisteria"],
	"g12_nightmare_greatsword": [2, "purple", "heavy", "g12_nightmare"],
	"g12_goldbell_greatsword": [4, "yellow", "heavy", "g12_goldbell"],
}
## 合手的棋子(测强度定下的)：都要在适配角色里，并且 1~3 星都装得上
const CARRIERS := {
	"g12_whalesong_spear": ["node_druid", "node_paladin"],
	"g12_jadebamboo_spear": ["node_warden", "node_peasant"],
	"g12_goldfinch_rapier": ["node_noble", "node_samurai", "node_killer"],
	"g12_wisteria_sword": ["node_pacifist", "node_druid"],
	"g12_nightmare_greatsword": ["node_magi", "node_berserker"],
	"g12_goldbell_greatsword": ["node_berserker", "node_pacifist"],
}
## 测强度去掉的(标签算上了，但测出来 +0~1)：不能再出现在适配角色里
const REMOVED := {
	"g12_goldfinch_rapier": ["node_commando"],
	"g12_wisteria_sword": ["node_shielder"],
	"g12_nightmare_greatsword": ["node_astronaut"],
}
## 测强度加上的(标签没算上，但测出来合手)
const ADDED := {}


func _probe(v: float) -> TriggerDef:
	return TriggerDef.from_dict({"id": "probe_trigger_g12", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
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
	var trig := TriggerDef.from_dict({"id": "probe_trigger_g12_multi", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
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


func _total(evs: Array[Dictionary], type: String, us: Array[BUnit]) -> float:
	var s := 0.0
	for x: BUnit in us:
		s += _sum(evs, type, x)
	return s


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
		t.ok(not models.has(e.model), "%s: look not shared with another gen12 weapon" % id)
		models[e.model] = true
		t.eq(e.projectile, "", "%s is melee: no projectile of its own" % id)
		t.ok(not ProjRegistry.trail(e.model).is_empty(), "%s has its own sword trail (proj_kinds/gen12.gd TRAILS)" % id)
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
	for wid2: String in REMOVED.keys():
		var fits2: Array[String] = cat.fit_units(wid2)
		for uid2: String in REMOVED[wid2]:
			t.ok(not fits2.has(uid2), "%s: %s is taken out of the fits (fit_remove, measured +0~1)" % [wid2, uid2])
	for wid3: String in ADDED.keys():
		var fits3: Array[String] = cat.fit_units(wid3)
		for uid3: String in ADDED[wid3]:
			t.ok(fits3.has(uid3), "%s: %s is added to the fits (fit_add, measured)" % [wid3, uid3])


# ================================================================ 鲸歌长枪
func test_whalesong_spear(t: TestCtx) -> void:
	var id := "g12_whalesong_spear"
	var c0: Dictionary = _cfg(id, 0)
	var c1: Dictionary = _cfg(id, 1)
	var ap: float = float(c0["ally_effect"]["cfg"]["stats"]["ability_power"]["flat"])
	var haste: float = float(c0["ally_effect"]["cfg"]["stats"]["haste"]["flat"])
	var mr: float = float(c0["enemy_effect"]["cfg"]["stats"]["magic_resistance"]["flat"])
	var slow: float = float(c0["enemy_effect"]["cfg"]["stats"]["move_speed"]["pct"])
	var r: float = float(c1["enemy_effect"]["value_multiplier"])
	var sh: float = float(c1["ally_effect"]["value_multiplier"])
	t.eq(str(c1["ally_effect"]["effect_type"]), "shield", "allies get a shield in part two")
	var ma: int = int(_eq(id).abilities[0].keyword_values.get("multi_attack", 1))
	var b := _crowd(id, 3, 6)
	var u: BUnit = b.units[0]
	var team: Array[BUnit] = [u]
	team.append_array(_allies(b, u))
	var ap0: float = team[1].get_stats().ability_power
	var h0: float = team[1].get_stats().haste
	# 队友(含自己)：【鲸歌】，没有伤害
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_allies", "ally", 300.0)
	var sung := 0
	for m: BUnit in team:
		if m.get_status("g12_whalesong") != null:
			sung += 1
			t.near(m.shield, 300.0 * sh, 300.0 * sh * 0.05 + 0.5, "and a shield of value × %.0f%%" % (sh * 100.0))
		else:
			t.eq(m.shield, 0.0, "an ally out of the Multi Attack gets no shield")
		t.eq(_sum(evs, "damage", m), 0.0, "allies aren't hurt")
	t.eq(sung, mini(ma, team.size()), "Multi Attack %d: allies (self included) gain Whalesong" % ma)
	var sang: BUnit = team[1] if team[1].get_status("g12_whalesong") != null else team[2]
	t.near(sang.get_stats().ability_power, ap0 + ap, 0.01, "+%.0f ability power" % ap)
	t.near(sang.get_stats().haste, h0 + haste, 0.001, "+%.0f%% haste" % (haste * 100.0))
	# 敌人：【深压】+ 触发数值 × r 魔法伤害，最多 ma 个
	var foes: Array[BUnit] = _foes(b, u)
	var mr0: float = foes[0].get_stats().magic_resistance
	var ms0: float = foes[0].get_stats().move_speed
	evs = _pull_rule(b, u, "all_enemies", "enemy", 300.0)
	var hit := 0
	for f: BUnit in foes:
		var d: float = _sum(evs, "damage", f)
		if d > 0.0:
			hit += 1
			t.near(d, 300.0 * r, 300.0 * r * 0.05, "an enemy takes value × %.0f%% magic" % (r * 100.0))
			t.ok(f.get_status("g12_deep_pressure") != null, "and is under Deep Pressure")
			t.near(f.get_stats().magic_resistance, mr0 + mr, 0.01, "%.0f magic resist" % mr)
			t.near(f.get_stats().move_speed, ms0 * (1.0 + slow), 0.01, "%.0f%% move speed" % (slow * 100.0))
		t.ok(f.get_status("g12_whalesong") == null, "enemies don't get Whalesong")
	t.eq(hit, ma, "Multi Attack %d: %d of the 6 enemies" % [ma, ma])
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "magic"), "magic damage")
	# 冷却 3 秒
	evs = _pull_rule(b, u, "all_enemies", "enemy", 300.0, false)
	t.eq(_total(evs, "damage", foes), 0.0, "3 s cooldown")


# ================================================================ 翠竹长枪
func test_jadebamboo_spear(t: TestCtx) -> void:
	var id := "g12_jadebamboo_spear"
	var b := _crowd(id, 1, 1)
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var h: float = _eq(id).abilities[0].value_multiplier
	var k: float = _eq(id).abilities[1].value_multiplier
	u.hp = u.get_stats().max_health * 0.3
	var evs: Array[Dictionary] = _pull(b, u, u, 400.0)
	t.near(_sum(evs, "heal", u), 400.0 * h, 400.0 * h * 0.05 + 0.5, "heals value × %.0f%%" % (h * 100.0))
	var st: BStatus = u.get_status("g12_bamboo_grit")
	t.ok(st != null, "and gains Bamboo Grit")
	t.ok(st != null and st.has_flag("no_dispel"), "which can't be dispelled")
	t.near(u.get_stats().health_regen_per_second, 400.0 * k, 0.01, "regen = value × %.0f%% a second" % (k * 100.0))
	# 【基本】：马上再扣一次也生效；按新的数值重算(不累加)
	evs = _pull_noclear(b, u, u, 200.0)
	t.near(_sum(evs, "heal", u), 200.0 * h, 200.0 * h * 0.05 + 0.5, "【Basic】: heals again right away")
	t.near(u.get_stats().health_regen_per_second, 200.0 * k, 0.01, "Bamboo Grit is recalculated, not stacked")
	# 回血真的在走；30 秒后还在(本场有效)
	var hp0: float = u.hp
	for i in range(int(round(2.0 / GC.SIM_DT))):
		b.step()
	t.near(u.hp - hp0, 2.0 * 200.0 * k, 200.0 * k * 0.6 + 1.0, "it heals every second")
	for i2 in range(int(round(30.0 / GC.SIM_DT))):
		b.step()
	t.ok(u.get_status("g12_bamboo_grit") != null, "lasts the battle")
	# 队友也行；敌人什么都没有
	ally.hp = ally.get_stats().max_health * 0.5
	evs = _pull(b, u, ally, 300.0)
	t.ok(_sum(evs, "heal", ally) > 0.0 and ally.get_status("g12_bamboo_grit") != null, "an ally target heals and gets Bamboo Grit too")
	t.ok(foe.get_status("g12_bamboo_grit") == null, "the enemy doesn't")


# ================================================================ 金雀细剑
func test_goldfinch_rapier(t: TestCtx) -> void:
	var id := "g12_goldfinch_rapier"
	var b := _crowd(id, 0, 1)
	var u: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	var a: AbilityDef = _eq(id).abilities[0]
	var ex: Dictionary = (a.effect_config["extra_effects"] as Array)[0]
	var cc: float = float(ex["stats"]["crit_chance"]["flat"])
	var cd: float = float(ex["stats"]["crit_damage"]["flat"])
	var maxs: int = int(ex["max_stacks"])
	var cc0: float = u.get_stats().crit_chance
	var cd0: float = u.get_stats().crit_damage
	t.ok(a.has_keyword("crit"), "【Crit】: the hit can crit")
	var evs: Array[Dictionary] = _pull(b, u, foe, 999.0)
	t.near(_sum(evs, "damage", foe), a.fixed_value, a.fixed_value * 0.05, "fixed %.0f physical, whatever the trigger value (no crit yet)" % a.fixed_value)
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "physical"), "physical damage")
	t.eq(u.status_stacks("g12_finch"), 1, "the holder gains a stack of Finch's Glee")
	t.eq(foe.status_stacks("g12_finch"), 0, "not the target")
	for i in range(maxs + 2):
		_pull_noclear(b, u, foe, 1.0)
	t.eq(u.status_stacks("g12_finch"), maxs, "【Basic】: every pull adds a stack, up to %d" % maxs)
	t.near(u.get_stats().crit_chance, cc0 + cc * float(maxs), 0.001, "+%.0f%% crit chance a stack" % (cc * 100.0))
	t.near(u.get_stats().crit_damage, cd0 + cd * float(maxs), 0.001, "+%.0f%% crit damage a stack" % (cd * 100.0))
	# 叠满后打出去的会暴击(暴击率拉满看看)
	u.base.crit_chance = 1.0
	u.mark_dirty()
	evs = _pull_noclear(b, u, foe, 1.0)
	t.near(_sum(evs, "damage", foe), a.fixed_value * u.get_stats().crit_damage, a.fixed_value * 0.1, "a crit deals × crit damage")
	# t 秒后掉光
	for i2 in range(int(round((float(ex["duration"]) + 0.5) / GC.SIM_DT))):
		b.step()
	t.eq(u.status_stacks("g12_finch"), 0, "wears off after %.0f s without new stacks" % float(ex["duration"]))


# ================================================================ 紫藤长剑
func test_wisteria_sword(t: TestCtx) -> void:
	var id := "g12_wisteria_sword"
	var c0: Dictionary = _cfg(id, 0)
	var c1: Dictionary = _cfg(id, 1)
	var h: float = float(c0["ally_effect"]["value_multiplier"])
	var r: float = float(c0["enemy_effect"]["value_multiplier"])
	var cap: float = float(c0["shield_cap_pct"])
	var vamp: float = float(c1["ally_effect"]["cfg"]["stats"]["omnivamp"]["flat"])
	var slow: float = float(c1["enemy_effect"]["cfg"]["stats"]["move_speed"]["pct"])
	var anti: float = -float(c1["enemy_effect"]["cfg"]["stats"]["healing_received_pct"]["flat"])
	var ma: int = int(_eq(id).abilities[0].keyword_values.get("multi_attack", 1))
	var b := _crowd(id, 4, 6)
	var u: BUnit = b.units[0]
	var team: Array[BUnit] = [u]
	team.append_array(_allies(b, u))
	for m: BUnit in team:
		m.hp = m.get_stats().max_health * 0.5
	# 一个几乎满血的队友：溢出的部分变成护盾(最多补到最大生命的 cap)
	var full: BUnit = team[1]
	full.hp = full.get_stats().max_health - 10.0
	var vamp0: float = team[2].get_stats().omnivamp
	var v := 2000.0
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_allies", "ally", v)
	var shaded := 0
	for m2: BUnit in team:
		if m2.get_status("g12_wisteria_shade") != null:
			shaded += 1
			if m2 != full:
				t.near(_sum(evs, "heal", m2), v * h, v * h * 0.05 + 0.5, "an ally heals value × %.0f%%" % (h * 100.0))
		t.eq(_sum(evs, "damage", m2), 0.0, "allies aren't hurt")
	t.eq(shaded, mini(ma, team.size()), "Multi Attack %d: allies (self included) heal and gain Wisteria Shade" % ma)
	if full.get_status("g12_wisteria_shade") != null:
		t.near(full.shield, minf(v * h - 10.0, full.get_stats().max_health * cap), 1.0, "overflow becomes a shield, up to %.0f%% of max health" % (cap * 100.0))
	var shade_m: BUnit = team[2] if team[2].get_status("g12_wisteria_shade") != null else team[3]
	t.near(shade_m.get_stats().omnivamp, vamp0 + vamp, 0.001, "+%.0f%% omnivamp" % (vamp * 100.0))
	# 敌人：触发数值 × r 魔法 + 【藤缚】
	var foes: Array[BUnit] = _foes(b, u)
	var ms0: float = foes[0].get_stats().move_speed
	var hr0: float = foes[0].get_stats().healing_received_pct
	evs = _pull_rule(b, u, "all_enemies", "enemy", 500.0)
	var hit := 0
	for f: BUnit in foes:
		var d: float = _sum(evs, "damage", f)
		if d > 0.0:
			hit += 1
			t.near(d, 500.0 * r, 500.0 * r * 0.05, "an enemy takes value × %.0f%% magic" % (r * 100.0))
			t.ok(f.get_status("g12_wisteria_bind") != null, "and is bound")
			t.near(f.get_stats().move_speed, ms0 * (1.0 + slow), 0.01, "%.0f%% move speed" % (slow * 100.0))
			t.near(f.get_stats().healing_received_pct, hr0 - anti, 0.001, "-%.0f%% healing received" % (anti * 100.0))
		t.ok(f.get_status("g12_wisteria_shade") == null, "enemies don't get the shade")
		t.eq(_sum(evs, "heal", f), 0.0, "enemies aren't healed")
	t.eq(hit, ma, "Multi Attack %d: %d of the 6 enemies" % [ma, ma])
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "magic"), "magic damage")
	# 冷却 3 秒
	evs = _pull_rule(b, u, "all_enemies", "enemy", 500.0, false)
	t.eq(_total(evs, "damage", foes), 0.0, "3 s cooldown")


# ================================================================ 梦魇巨剑
func test_nightmare_greatsword(t: TestCtx) -> void:
	var id := "g12_nightmare_greatsword"
	var a: AbilityDef = _eq(id).abilities[0]
	var ex: Dictionary = (a.effect_config["extra_effects"] as Array)[0]
	var atkd: float = float(ex["stats"]["attack_power"]["pct"])
	var asd: float = float(ex["stats"]["attack_speed_multiplier"]["flat"])
	var r: float = a.value_multiplier
	var ma: int = int(a.keyword_values.get("multi_attack", 1))
	var b := _crowd(id, 1, 6)
	var u: BUnit = b.units[0]
	var foes: Array[BUnit] = _foes(b, u)
	var atk0: float = foes[0].get_stats().attack_power
	var as0: float = foes[0].get_stats().attack_speed_multiplier
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_enemies", "enemy", 400.0)
	var hit := 0
	for f: BUnit in foes:
		var d: float = _sum(evs, "damage", f)
		if d > 0.0:
			hit += 1
			t.near(d, 400.0 * r, 400.0 * r * 0.05, "a target takes value × %.0f%% magic" % (r * 100.0))
			t.ok(f.get_status("g12_nightmare") != null, "and has a Nightmare")
			t.near(f.get_stats().attack_power, atk0 * (1.0 + atkd), 0.5, "%.0f%% attack" % (atkd * 100.0))
			t.near(f.get_stats().attack_speed_multiplier, as0 + asd, 0.001, "%.0f%% attack speed" % (asd * 100.0))
		else:
			t.ok(f.get_status("g12_nightmare") == null, "an enemy that wasn't hit has no Nightmare")
	t.eq(hit, ma, "Multi Attack %d: %d of the 6 enemies" % [ma, ma])
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "magic"), "magic damage")
	t.ok(u.get_status("g12_nightmare") == null, "not the holder")
	# 冷却 3 秒；t 秒后梦醒
	evs = _pull_rule(b, u, "all_enemies", "enemy", 400.0, false)
	t.eq(_total(evs, "damage", foes), 0.0, "3 s cooldown")
	for i in range(int(round((float(ex["duration"]) + 0.3) / GC.SIM_DT))):
		b.step()
	var left := 0
	for f2: BUnit in foes:
		if f2.get_status("g12_nightmare") != null:
			left += 1
	t.eq(left, 0, "wears off after %.0f s" % float(ex["duration"]))


# ================================================================ 金钟巨剑
func test_goldbell_greatsword(t: TestCtx) -> void:
	var id := "g12_goldbell_greatsword"
	var c0: Dictionary = _cfg(id, 0)
	var s: float = float(c0["ally_effect"]["value_multiplier"])
	var r: float = float(c0["enemy_effect"]["value_multiplier"])
	var knock: float = _eq(id).abilities[1].fixed_value
	var ma: int = int(_eq(id).abilities[0].keyword_values.get("multi_attack", 1))
	var b := _crowd(id, 4, 6)
	var u: BUnit = b.units[0]
	var team: Array[BUnit] = [u]
	team.append_array(_allies(b, u))
	var pos0 := {}
	for m0: BUnit in team:
		pos0[m0] = m0.pos
	# 队友(含自己)：触发数值 × s 的护盾，不挨打、不被震开
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_allies", "ally", 500.0)
	var shielded := 0
	for m: BUnit in team:
		if m.shield > 0.0:
			shielded += 1
			t.near(m.shield, 500.0 * s, 500.0 * s * 0.05 + 0.5, "an ally gains a shield of value × %.0f%%" % (s * 100.0))
		t.eq(_sum(evs, "damage", m), 0.0, "allies aren't hurt")
		t.ok(not m.meta.has("knock"), "allies aren't knocked back")
	t.eq(shielded, mini(ma, team.size()), "Multi Attack %d: allies (self included) are shielded" % ma)
	# 敌人：触发数值 × r 物理伤害 + 震退 knock 米(离携带者更远)
	var foes: Array[BUnit] = _foes(b, u)
	evs = _pull_rule(b, u, "all_enemies", "enemy", 500.0)
	var hit := 0
	for f: BUnit in foes:
		var d: float = _sum(evs, "damage", f)
		if d > 0.0:
			hit += 1
			t.near(d, 500.0 * r, 500.0 * r * 0.05, "an enemy takes value × %.0f%% physical" % (r * 100.0))
			t.ok(f.meta.has("knock"), "and is knocked back")
			if f.meta.has("knock"):
				var kn: Dictionary = f.meta["knock"]
				var fr: Vector2 = kn["from"]
				var to: Vector2 = kn["to"]
				t.near(fr.distance_to(to), knock, 0.15, "by %.1f m" % knock)
				t.ok(to.distance_to(u.pos) > fr.distance_to(u.pos), "away from the holder")
		t.eq(f.shield, 0.0, "enemies get no shield")
	t.eq(hit, ma, "Multi Attack %d: %d of the 6 enemies" % [ma, ma])
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "physical"), "physical damage")
	# 冷却 3 秒
	evs = _pull_rule(b, u, "all_enemies", "enemy", 500.0, false)
	t.eq(_total(evs, "damage", foes), 0.0, "3 s cooldown")
