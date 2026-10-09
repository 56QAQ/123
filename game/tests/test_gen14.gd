extends RefCounted
## 通用武器 · gen14(单手剑 3 把 + 双手剑 2 把 + 矛 1 把)：翠鳞鞭剑 / 蓝徽骑士剑 / 斗牛士剑(单手剑)、苔衣巨剑 / 沉锚巨剑(双手剑)、鮟鱇灯杖(矛)。
## 每把用一个"探针触发器"(目标 = 事件目标 / 指定规则、固定触发数值)直接扣动载荷验证效果；再查数据(格子、外观、随机池、刀光)和适配角色。

## 武器 -> [费用, 颜色, 大类, 外观]
const SLOTS := {
	"g14_jadescale_whip": [4, "green", "sword", "g14_jadescale"],
	"g14_bluecrest_sword": [3, "blue", "sword", "g14_bluecrest"],
	"g14_matador_estoque": [2, "red", "sword", "g14_matador"],
	"g14_mossmantle_greatsword": [3, "green", "heavy", "g14_mossmantle"],
	"g14_anchor_greatsword": [2, "blue", "heavy", "g14_anchor"],
	"g14_angler_staff": [3, "blue", "polearm", "g14_angler"],
}
## 合手的棋子(测强度定下的)：都要在适配角色里，并且 1~3 星都装得上
const CARRIERS := {
	"g14_jadescale_whip": ["node_killer", "node_samurai"],
	"g14_bluecrest_sword": ["node_shielder", "node_druid"],
	"g14_matador_estoque": ["node_pacifist", "node_gladiator"],
	"g14_mossmantle_greatsword": ["node_killer", "node_peasant"],
	"g14_anchor_greatsword": ["node_paladin", "node_druid"],
	"g14_angler_staff": ["node_witch", "node_paladin", "node_wizard"],
}
## 测强度去掉的(标签算上了，但测出来 +0~1)：不能再出现在适配角色里
const REMOVED := {
	"g14_bluecrest_sword": ["node_paladin"],
	"g14_anchor_greatsword": ["node_astronaut"],
	"g14_angler_staff": ["node_druid"],
}
## 测强度加上的(标签没算上，但测出来合手)
const ADDED := {
	"g14_matador_estoque": ["node_gladiator"],
	"g14_angler_staff": ["node_wizard"],
}


func _probe(v: float) -> TriggerDef:
	return TriggerDef.from_dict({"id": "probe_trigger_g14", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
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
	var trig := TriggerDef.from_dict({"id": "probe_trigger_g14_multi", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
		"target_rule": rule, "team_filter": team, "base_value_mode": "fixed", "base_value_flat": v})
	b.pipeline._fire(b.pipeline.make_event("OnBattleFrame", u, null, 0.0, ["battle_frame"], {}), trig, u)
	b.pipeline.drain()
	return b.poll_events()


## 携带者 + allies 个木桩队友 + foes 个木桩敌人(都不攻击、不动)；敌人排成一排，间距 gap 米
func _crowd(weapon: String, allies: int, foes: int, gap: float = 1.0) -> Battle:
	var specs: Array = [{"def": "test_hitter", "pos": Vector2(0, -3), "weapon": weapon}]
	for i in range(allies):
		specs.append({"def": "test_dummy", "pos": Vector2(1.5 + i, -3)})
	for j in range(foes):
		specs.append({"def": "test_dummy", "team": 1, "pos": Vector2(-2.0 + float(j) * gap, 3)})
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


func _steps(b: Battle, secs: float) -> void:
	for i in range(int(round(secs / GC.SIM_DT))):
		b.step()


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
		t.ok(not models.has(e.model), "%s: look not shared with another gen14 weapon" % id)
		models[e.model] = true
		t.eq(e.projectile, "", "%s is melee: no projectile of its own" % id)
		t.ok(not ProjRegistry.trail(e.model).is_empty(), "%s has its own sword trail (proj_kinds/gen14.gd TRAILS)" % id)
		for a: AbilityDef in e.abilities:
			t.ok(a.required_trigger_tags.has("equipment_payload"), "%s/%s pairs with weapon triggers" % [id, a.id])
	# 外观全局唯一：别的武器(专武、其他批)没有用同一个外观名
	for oid: String in cat.equipment.keys():
		var o: EquipmentDef = cat.get_equipment(oid)
		if not SLOTS.has(oid) and o.model != "" and models.has(o.model):
			t.ok(false, "look %s is also used by %s" % [o.model, oid])
	# 鮟鱇灯杖不是护符(灾星 2 星起不能装护符)，但两段都按目标阵营分支 = 提供双模
	for a2: AbilityDef in _eq("g14_angler_staff").abilities:
		t.ok(a2.ability_class != "amulet", "Angler's Lantern Staff/%s isn't an amulet (the witch can equip it)" % a2.id)
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


# ================================================================ 翠鳞鞭剑
func test_jadescale_whip(t: TestCtx) -> void:
	var id := "g14_jadescale_whip"
	var a: AbilityDef = _eq(id).abilities[0]
	var ex: Dictionary = (a.effect_config["extra_effects"] as Array)[0]
	var armor: float = float(ex["stats"]["defense"]["flat"])
	var maxs: int = int(ex["max_stacks"])
	var ratio: float = float(a.effect_config["splash_ratio"])
	var rad: float = float(a.keyword_values.get("splash", 1)) * GC.SPLASH_M_PER_POINT
	t.ok(a.has_keyword("basic") and a.has_keyword("splash"), "【Basic】【Splash】")
	# 敌人排成一排、间距 0.7 米：主目标两边贴着的被扫到，远的扫不到
	var b := _crowd(id, 1, 5, 0.7)
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foes: Array[BUnit] = _foes(b, u)
	var main: BUnit = foes[2]
	var def0: float = main.get_stats().defense
	var evs: Array[Dictionary] = _pull(b, u, main, 999.0)
	t.near(_sum(evs, "damage", main), a.fixed_value, a.fixed_value * 0.05, "fixed %.0f physical to the target, whatever the trigger value" % a.fixed_value)
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "physical"), "physical damage")
	for f: BUnit in foes:
		if f == main:
			continue
		var near: bool = f.pos.distance_to(main.pos) <= rad + f.radius
		var d: float = _sum(evs, "damage", f)
		if near:
			t.near(d, a.fixed_value * ratio, a.fixed_value * ratio * 0.05 + 0.5, "an enemy next to it is lashed for %.0f%%" % (ratio * 100.0))
		else:
			t.eq(d, 0.0, "an enemy %.1f m away isn't" % f.pos.distance_to(main.pos))
		t.eq(f.status_stacks("g14_scale_rend"), 0, "only the trigger target gets Scale Rend")
	t.eq(_sum(evs, "damage", ally) + _sum(evs, "damage", u), 0.0, "the lash never hits our side")
	t.eq(main.status_stacks("g14_scale_rend"), 1, "the target gains a stack of Scale Rend")
	for i in range(maxs + 2):
		_pull_noclear(b, u, main, 1.0)
	t.eq(main.status_stacks("g14_scale_rend"), maxs, "【Basic】: every pull adds a stack, up to %d" % maxs)
	t.near(main.get_stats().defense, def0 + armor * float(maxs), 0.01, "%.0f armor a stack" % armor)
	t.eq(u.status_stacks("g14_scale_rend"), 0, "not the holder")
	_steps(b, float(ex["duration"]) + 0.5)
	t.eq(main.status_stacks("g14_scale_rend"), 0, "wears off after %.0f s without new stacks" % float(ex["duration"]))
	# 打到队友(探针)：伤害照样打——武器只对敌人(本来就只配敌人的插槽)


# ================================================================ 蓝徽骑士剑
func test_bluecrest_sword(t: TestCtx) -> void:
	var id := "g14_bluecrest_sword"
	var e: EquipmentDef = _eq(id)
	var fixed: float = e.abilities[0].fixed_value
	var c1: Dictionary = _cfg(id, 1)
	var ap: float = float(c1["ally_effect"]["cfg"]["stats"]["ability_power"]["flat"])
	var haste: float = float(c1["ally_effect"]["cfg"]["stats"]["haste"]["flat"])
	var rad: float = float(c1["radius"])
	var dur: float = float(c1["duration"])
	var ma: int = int(e.abilities[0].keyword_values.get("multi_attack", 1))
	var b := _crowd(id, 3, 6)
	var u: BUnit = b.units[0]
	var team: Array[BUnit] = [u]
	team.append_array(_allies(b, u))
	var ap0: float = team[1].get_stats().ability_power
	var h0: float = team[1].get_stats().haste
	# 队友(含自己)：固定护盾 + 【蓝徽】，不挨打
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_allies", "ally", 999.0)
	var crested := 0
	for m: BUnit in team:
		if m.get_status("g14_crest") != null:
			crested += 1
			t.near(m.shield, fixed, 0.5, "and a fixed %.0f-point shield" % fixed)
		else:
			t.eq(m.shield, 0.0, "an ally out of the Multi Attack gets no shield")
		t.eq(_sum(evs, "damage", m), 0.0, "allies aren't hurt")
	t.eq(crested, mini(ma, team.size()), "Multi Attack %d: allies (self included) gain Bluecrest" % ma)
	var cm: BUnit = team[1] if team[1].get_status("g14_crest") != null else team[2]
	t.near(cm.get_stats().ability_power, ap0 + ap, 0.01, "+%.0f ability power" % ap)
	t.near(cm.get_stats().haste, h0 + haste, 0.001, "+%.0f%% haste" % (haste * 100.0))
	for f0: BUnit in _foes(b, u):
		t.ok(f0.forced_target == null, "allies being targeted doesn't taunt anyone")
	# 敌人：固定魔法伤害；携带者身边 rad 米内的敌人被嘲讽(只能打携带者)，远的不受影响
	var foes: Array[BUnit] = _foes(b, u)
	var far_foe: BUnit = foes[5]
	far_foe.pos = u.pos + Vector2(rad + 4.0, 0.0)
	var near_foe: BUnit = foes[0]
	near_foe.pos = u.pos + Vector2(0.0, 1.5)
	evs = _pull_rule(b, u, "all_enemies", "enemy", 999.0)
	var hit := 0
	for f: BUnit in foes:
		var d: float = _sum(evs, "damage", f)
		if d > 0.0:
			hit += 1
			t.near(d, fixed, fixed * 0.05, "an enemy takes a fixed %.0f magic" % fixed)
		t.ok(f.get_status("g14_crest") == null and f.shield == 0.0, "enemies get no crest, no shield")
	t.eq(hit, ma, "Multi Attack %d: %d of the 6 enemies" % [ma, ma])
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "magic"), "magic damage")
	t.ok(near_foe.forced_target == u and near_foe.forced_until > b.time + dur - 0.1, "an enemy within %.0f m is taunted for %.1f s" % [rad, dur])
	t.ok(far_foe.forced_target == null, "an enemy %.0f m away isn't" % (rad + 4.0))
	# 冷却 3 秒
	evs = _pull_rule(b, u, "all_enemies", "enemy", 999.0, false)
	t.eq(_total(evs, "damage", foes), 0.0, "3 s cooldown")


# ================================================================ 斗牛士剑
func test_matador_estoque(t: TestCtx) -> void:
	var id := "g14_matador_estoque"
	var e: EquipmentDef = _eq(id)
	var c0: Dictionary = _cfg(id, 0)
	var c1: Dictionary = _cfg(id, 1)
	var atk: float = float(c0["ally_effect"]["cfg"]["stats"]["attack_power"]["pct"])
	var nad: float = float(c0["ally_effect"]["cfg"]["stats"]["na_damage_pct"]["flat"])
	var cape: float = -float(c0["enemy_effect"]["cfg"]["stats"]["defense"]["flat"])
	var h: float = float(c1["ally_effect"]["value_multiplier"])
	var r: float = float(c1["enemy_effect"]["value_multiplier"])
	var ma: int = int(e.abilities[0].keyword_values.get("multi_attack", 1))
	var b := _crowd(id, 4, 6)
	var u: BUnit = b.units[0]
	var team: Array[BUnit] = [u]
	team.append_array(_allies(b, u))
	for m0: BUnit in team:
		m0.hp = m0.get_stats().max_health * 0.5
	var atk0: float = team[1].get_stats().attack_power
	var na0: float = team[1].get_stats().na_damage_pct
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_allies", "ally", 400.0)
	var brave := 0
	for m: BUnit in team:
		if m.get_status("g14_bravura") != null:
			brave += 1
			t.near(_sum(evs, "heal", m), 400.0 * h, 400.0 * h * 0.05 + 0.5, "an ally heals value × %.0f%%" % (h * 100.0))
		t.eq(_sum(evs, "damage", m), 0.0, "allies aren't hurt")
	t.eq(brave, mini(ma, team.size()), "Multi Attack %d: allies (self included) gain Bravura" % ma)
	var bm: BUnit = team[1] if team[1].get_status("g14_bravura") != null else team[2]
	t.near(bm.get_stats().attack_power, atk0 * (1.0 + atk), 0.5, "+%.0f%% attack" % (atk * 100.0))
	t.near(bm.get_stats().na_damage_pct, na0 + nad, 0.001, "+%.0f%% normal attack damage" % (nad * 100.0))
	# 敌人：【红布】+ 触发数值 × r 物理
	var foes: Array[BUnit] = _foes(b, u)
	var def0: float = foes[0].get_stats().defense
	var mr0: float = foes[0].get_stats().magic_resistance
	evs = _pull_rule(b, u, "all_enemies", "enemy", 400.0)
	var hit := 0
	for f: BUnit in foes:
		var d: float = _sum(evs, "damage", f)
		if d > 0.0:
			hit += 1
			t.ok(f.get_status("g14_red_cape") != null, "a hit enemy is caught by the Red Cape")
			t.near(f.get_stats().defense, def0 - cape, 0.01, "-%.0f armor" % cape)
			t.near(f.get_stats().magic_resistance, mr0 - cape, 0.01, "-%.0f magic resist" % cape)
			# 护甲已经降下去了(先上红布、再刺)：木桩护甲 0 → 负护甲吃得更多，至少有 value × r
			t.ok(d >= 400.0 * r * 0.99, "takes value × %.0f%% physical (after the cape)" % (r * 100.0))
		t.ok(f.get_status("g14_bravura") == null, "enemies don't get Bravura")
		t.eq(_sum(evs, "heal", f), 0.0, "enemies aren't healed")
	t.eq(hit, ma, "Multi Attack %d: %d of the 6 enemies" % [ma, ma])
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "physical"), "physical damage")
	evs = _pull_rule(b, u, "all_enemies", "enemy", 400.0, false)
	t.eq(_total(evs, "damage", foes), 0.0, "3 s cooldown")


# ================================================================ 苔衣巨剑
func test_mossmantle_greatsword(t: TestCtx) -> void:
	var id := "g14_mossmantle_greatsword"
	var e: EquipmentDef = _eq(id)
	var a0: AbilityDef = e.abilities[0]
	var pre: Dictionary = (a0.effect_config["pre_effects"] as Array)[0]
	var dr: float = float(pre["stats"]["damage_taken_pct"]["flat"])
	var regen: float = float(pre["stats"]["health_regen_per_second"]["flat"])
	var maxs: int = int(pre["max_stacks"])
	var fill: int = int(_cfg(id, 1)["ally_effect"]["cfg"]["add_stacks"])
	var b := _crowd(id, 1, 1)
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var dr0: float = u.get_stats().damage_taken_pct
	var rg0: float = u.get_stats().health_regen_per_second
	# 打敌人：固定物理伤害 + 携带者 1 层苔衣
	var evs: Array[Dictionary] = _pull(b, u, foe, 999.0)
	t.near(_sum(evs, "damage", foe), a0.fixed_value, a0.fixed_value * 0.05, "fixed %.0f physical to an enemy" % a0.fixed_value)
	t.eq(u.status_stacks("g14_moss"), 1, "the holder grows a stack of Mossmantle")
	t.eq(foe.status_stacks("g14_moss"), 0, "the enemy doesn't")
	for i in range(maxs + 3):
		_pull_noclear(b, u, foe, 1.0)
	t.eq(u.status_stacks("g14_moss"), maxs, "【Basic】: every pull adds a stack, up to %d" % maxs)
	t.near(u.get_stats().damage_taken_pct, dr0 + dr * float(maxs), 0.0001, "+%.1f%% damage reduction a stack" % (dr * 100.0))
	t.near(u.get_stats().health_regen_per_second, rg0 + regen * float(maxs), 0.01, "+%.0f regen a stack" % regen)
	_steps(b, 30.0)
	t.eq(u.status_stacks("g14_moss"), maxs, "lasts the battle")
	# 打自己(收获时刻)：一下长满，不打自己
	var b2 := _crowd(id, 1, 1)
	var u2: BUnit = b2.units[0]
	evs = _pull(b2, u2, u2, 400.0)
	t.eq(u2.status_stacks("g14_moss"), mini(maxs, 1 + fill), "a self trigger fills Mossmantle at once (1 + %d)" % fill)
	t.eq(_sum(evs, "damage", u2), 0.0, "and doesn't hurt the holder")
	# 打队友：队友长满，携带者照样 1 层
	var b3 := _crowd(id, 1, 1)
	var u3: BUnit = b3.units[0]
	var al3: BUnit = b3.units[1]
	evs = _pull(b3, u3, al3, 400.0)
	t.eq(al3.status_stacks("g14_moss"), mini(maxs, fill), "an ally target gains %d stacks" % fill)
	t.eq(u3.status_stacks("g14_moss"), 1, "the holder still grows one")
	t.eq(_sum(evs, "damage", al3), 0.0, "the ally isn't hurt")
	# 回血真的在走
	u.hp = u.get_stats().max_health * 0.5
	var hp0: float = u.hp
	_steps(b, 2.0)
	t.ok(u.hp - hp0 >= regen * float(maxs) * 1.5, "Mossmantle heals every second")


# ================================================================ 沉锚巨剑
func test_anchor_greatsword(t: TestCtx) -> void:
	var id := "g14_anchor_greatsword"
	var e: EquipmentDef = _eq(id)
	var c0: Dictionary = _cfg(id, 0)
	var c1: Dictionary = _cfg(id, 1)
	var s: float = float(c0["ally_effect"]["value_multiplier"])
	var r: float = float(c0["enemy_effect"]["value_multiplier"])
	var dr: float = float(c1["ally_effect"]["cfg"]["stats"]["damage_taken_pct"]["flat"])
	var slow: float = float(c1["enemy_effect"]["cfg"]["stats"]["move_speed"]["pct"])
	var asd: float = float(c1["enemy_effect"]["cfg"]["stats"]["attack_speed_multiplier"]["flat"])
	var ma: int = int(e.abilities[0].keyword_values.get("multi_attack", 1))
	var b := _crowd(id, 3, 6)
	var u: BUnit = b.units[0]
	var team: Array[BUnit] = [u]
	team.append_array(_allies(b, u))
	var dr0: float = team[1].get_stats().damage_taken_pct
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_allies", "ally", 500.0)
	var anchored := 0
	for m: BUnit in team:
		if m.get_status("g14_anchored") != null:
			anchored += 1
			t.near(m.shield, 500.0 * s, 500.0 * s * 0.05 + 0.5, "an ally gains a shield of value × %.0f%%" % (s * 100.0))
		t.eq(_sum(evs, "damage", m), 0.0, "allies aren't hurt")
	t.eq(anchored, mini(ma, team.size()), "Multi Attack %d: allies (self included) are anchored" % ma)
	var am: BUnit = team[1] if team[1].get_status("g14_anchored") != null else team[2]
	t.near(am.get_stats().damage_taken_pct, dr0 + dr, 0.0001, "+%.0f%% damage reduction" % (dr * 100.0))
	var foes: Array[BUnit] = _foes(b, u)
	var ms0: float = foes[0].get_stats().move_speed
	var as0: float = foes[0].get_stats().attack_speed_multiplier
	evs = _pull_rule(b, u, "all_enemies", "enemy", 500.0)
	var hit := 0
	for f: BUnit in foes:
		var d: float = _sum(evs, "damage", f)
		if d > 0.0:
			hit += 1
			t.near(d, 500.0 * r, 500.0 * r * 0.05, "an enemy takes value × %.0f%% magic" % (r * 100.0))
			t.ok(f.get_status("g14_sunk") != null, "and is Sunk")
			t.near(f.get_stats().move_speed, ms0 * (1.0 + slow), 0.01, "%.0f%% move speed" % (slow * 100.0))
			t.near(f.get_stats().attack_speed_multiplier, as0 + asd, 0.001, "%.0f%% attack speed" % (asd * 100.0))
		t.ok(f.shield == 0.0 and f.get_status("g14_anchored") == null, "enemies get no shield, no anchor")
	t.eq(hit, ma, "Multi Attack %d: %d of the 6 enemies" % [ma, ma])
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "magic"), "magic damage")
	evs = _pull_rule(b, u, "all_enemies", "enemy", 500.0, false)
	t.eq(_total(evs, "damage", foes), 0.0, "3 s cooldown")


# ================================================================ 鮟鱇灯杖
func test_angler_staff(t: TestCtx) -> void:
	var id := "g14_angler_staff"
	var e: EquipmentDef = _eq(id)
	var c0: Dictionary = _cfg(id, 0)
	var per_ap: float = float(c0["ally_effect"]["cfg"]["stats"]["ability_power"]["flat"])
	var per_mr: float = -float(c0["enemy_effect"]["cfg"]["stats"]["magic_resistance"]["flat"])
	var maxs: int = int(c0["ally_effect"]["cfg"]["max_stacks"])
	var dmg: float = e.abilities[1].fixed_value
	var ma: int = int(e.abilities[0].keyword_values.get("multi_attack", 1))
	t.ok(e.abilities[0].has_keyword("basic") and e.abilities[1].has_keyword("basic"), "both parts are 【Basic】")
	var b := _crowd(id, 3, 6)
	var u: BUnit = b.units[0]
	var team: Array[BUnit] = [u]
	team.append_array(_allies(b, u))
	var ap0: float = team[1].get_stats().ability_power
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_allies", "ally", 999.0)
	var lit := 0
	for m: BUnit in team:
		if m.status_stacks("g14_lamplight") > 0:
			lit += 1
		t.eq(_sum(evs, "damage", m), 0.0, "allies aren't hurt")
	t.eq(lit, mini(ma, team.size()), "Multi Attack %d: allies (self included) gain Lamplight" % ma)
	for i in range(maxs + 2):
		_pull_rule(b, u, "all_allies", "ally", 1.0, false)
	t.eq(team[1].status_stacks("g14_lamplight"), maxs, "【Basic】: every pull adds a stack, up to %d" % maxs)
	t.near(team[1].get_stats().ability_power, ap0 + per_ap * float(maxs), 0.01, "+%.0f ability power a stack" % per_ap)
	var foes: Array[BUnit] = _foes(b, u)
	var mr0: float = foes[0].get_stats().magic_resistance
	evs = _pull_rule(b, u, "all_enemies", "enemy", 999.0)
	var hit := 0
	var lured: BUnit = null
	for f: BUnit in foes:
		var d: float = _sum(evs, "damage", f)
		if d > 0.0:
			hit += 1
			t.near(d, dmg, dmg * 0.05 + 0.5, "an enemy takes a fixed %.0f magic" % dmg)
			t.eq(f.status_stacks("g14_lured"), 1, "and is Lured")
			lured = f
		t.eq(f.status_stacks("g14_lamplight"), 0, "enemies don't get Lamplight")
	t.eq(hit, ma, "Multi Attack %d: %d of the 6 enemies" % [ma, ma])
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "magic"), "magic damage")
	for j in range(maxs + 2):
		_pull_rule(b, u, "all_enemies", "enemy", 1.0, false)
	if lured != null:
		t.eq(lured.status_stacks("g14_lured"), maxs, "【Basic】: Lured stacks up to %d" % maxs)
		t.near(lured.get_stats().magic_resistance, mr0 - per_mr * float(maxs), 0.01, "-%.0f magic resist a stack" % per_mr)
	_steps(b, float(c0["ally_effect"]["cfg"]["duration"]) + 0.5)
	t.eq(team[1].status_stacks("g14_lamplight"), 0, "Lamplight wears off")
	# 灾星节点(2 星起不能装护符)装得上
	var w: UnitDef = Fixture.catalog().get_unit("node_witch")
	for star: int in [2, 3]:
		t.eq(e.equip_problem(w, star), "", "the witch can equip it at ★%d" % star)
