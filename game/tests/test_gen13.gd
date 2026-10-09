extends RefCounted
## 通用武器 · gen13：琥珀双刃 / 螳螂双镰(双匕)、催眠双枪(手枪)、摇篮月长弓 / 青龙长弓(弓)、玫瑰花束(法器)。
## 每把用一个"探针触发器"(目标 = 事件目标 / 指定规则、固定触发数值)直接扣动载荷验证效果；再查数据(格子、外观、投射物、随机池)、文本里的数值和适配角色。

## 武器 -> [费用, 颜色, 大类, 外观, 投射物("" = 这个大类的默认弹 / 近战)]
const SLOTS := {
	"g13_amber_daggers": [4, "yellow", "dual", "g13_amber", ""],
	"g13_mantis_sickles": [2, "green", "dual", "g13_mantis", ""],
	"g13_hypno_pistols": [2, "purple", "pistols", "g13_hypno", "g13_hypno"],
	"g13_cradle_bow": [2, "blue", "bow", "g13_cradle", ""],
	"g13_azure_dragon_bow": [4, "cyan", "bow", "g13_azure_dragon", ""],
	"g13_rose_bouquet": [3, "red", "focus", "g13_rose", "g13_petals"],
}
## 合手的棋子(测强度定下的)：都要在适配角色里，并且 1~3 星都装得上
const CARRIERS := {
	"g13_amber_daggers": ["node_commando", "node_maid"],
	"g13_mantis_sickles": ["node_hunter", "node_rogue"],
	"g13_hypno_pistols": ["node_archer", "node_nurse"],
	"g13_cradle_bow": ["node_druid"],
	"g13_azure_dragon_bow": ["node_hunter", "node_druid"],
	"g13_rose_bouquet": ["node_dancer", "node_nurse"],
}
## 单人格(用户特意开放给这一只棋子的格子)：适配 1 只就算达标
const SOLO := ["g13_cradle_bow"]


func _probe(v: float) -> TriggerDef:
	return TriggerDef.from_dict({"id": "probe_trigger_g13", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
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
	var trig := TriggerDef.from_dict({"id": "probe_trigger_g13_multi", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
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


func _branch(id: String, i: int, key: String) -> Dictionary:
	return _cfg(id, i)[key]


static func _sum(evs: Array[Dictionary], type: String, dst: BUnit) -> float:
	var s := 0.0
	for e: Dictionary in evs:
		if e.get("t") == type and e.get("dst") == dst:
			s += float(e.get("amount", 0.0))
	return s


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


func _expires_in(b: Battle, u: BUnit, sid: String) -> float:
	var st: BStatus = u.get_status(sid)
	return -999.0 if st == null else float(st.expires_at) - b.time


func _kinds(evs: Array[Dictionary]) -> Array:
	return evs.filter(func(e: Dictionary) -> bool: return e.get("t") == "damage").map(func(e: Dictionary) -> String: return str(e["kind"]))


# ================================================================ 数据 / 适配 / 文本
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
		t.ok(not models.has(e.model), "%s: look not shared with another gen13 weapon" % id)
		models[e.model] = true
		t.eq(e.projectile, str(s[4]), "%s shoots %s" % [id, str(s[4]) if str(s[4]) != "" else "its class's default projectile"])
		if e.projectile != "":
			t.ok(ProjRegistry.has(e.projectile), "%s: projectile %s is registered (proj_kinds/gen13.gd)" % [id, e.projectile])
		for a: AbilityDef in e.abilities:
			t.ok(a.required_trigger_tags.has("equipment_payload"), "%s/%s pairs with weapon triggers" % [id, a.id])
	# 外观全局唯一：别的武器(专武、其他批)没有用同一个外观名
	for oid: String in cat.equipment.keys():
		var o: EquipmentDef = cat.get_equipment(oid)
		if not SLOTS.has(oid) and o.model != "" and models.has(o.model):
			t.ok(false, "look %s is also used by %s" % [o.model, oid])
	# 近战(双匕)的刀光登记在 proj_kinds/gen13.gd 的 TRAILS
	for did: String in ["g13_amber_daggers", "g13_mantis_sickles"]:
		t.ok(not ProjRegistry.trail(_eq(did).model).is_empty(), "%s has a weapon trail" % did)
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_fit(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	for wid: String in CARRIERS.keys():
		var fits: Array[String] = cat.fit_units(wid)
		t.ok(fits.size() >= (1 if SOLO.has(wid) else 2), "%s fits %d pieces (%s)" % [wid, fits.size(), ",".join(fits)])
		var e: EquipmentDef = cat.get_equipment(wid)
		for uid: String in CARRIERS[wid]:
			t.ok(fits.has(uid), "%s fits %s" % [wid, uid])
			for star: int in [1, 2, 3]:
				t.eq(e.equip_problem(cat.get_unit(uid), star), "", "%s can be equipped by %s ★%d" % [wid, uid, star])


## 描述里的数值和数据一致(百分比按 ×100 写)
func test_text_numbers(t: TestCtx) -> void:
	var amber: EquipmentDef = _eq("g13_amber_daggers")
	var shell: Dictionary = (_cfg("g13_amber_daggers", 0)["pre_effects"] as Array)[0]
	var mantis: EquipmentDef = _eq("g13_mantis_sickles")
	var mimic: Dictionary = (_cfg("g13_mantis_sickles", 0)["pre_effects"] as Array)[0]
	var grip: Dictionary = _cfg("g13_mantis_sickles", 1)
	var hypno: EquipmentDef = _eq("g13_hypno_pistols")
	var sugg: Dictionary = _branch("g13_hypno_pistols", 1, "ally_effect")["cfg"]
	var cradle: EquipmentDef = _eq("g13_cradle_bow")
	var crad: Dictionary = _branch("g13_cradle_bow", 0, "ally_effect")["cfg"]
	var drow: Dictionary = _branch("g13_cradle_bow", 0, "enemy_effect")["cfg"]
	var dragon: EquipmentDef = _eq("g13_azure_dragon_bow")
	var awe: Dictionary = _cfg("g13_azure_dragon_bow", 1)
	var rose: EquipmentDef = _eq("g13_rose_bouquet")
	var frag: Dictionary = _branch("g13_rose_bouquet", 0, "ally_effect")["cfg"]
	var nums := {
		"g13_amber_daggers": [amber.flat_mods["attack_power"], amber.flat_mods["max_health"], amber.abilities[0].cooldown,
			shell["duration"], shell["stats"]["damage_taken_pct"]["flat"] * 100.0, amber.abilities[0].value_multiplier * 100.0,
			_branch("g13_amber_daggers", 0, "ally_effect")["value_multiplier"] * 100.0, _cfg("g13_amber_daggers", 1)["duration"]],
		"g13_mantis_sickles": [mantis.flat_mods["attack_power"], mantis.flat_mods["max_health"], mantis.flat_mods["na_dodge"] * 100.0,
			mantis.pct_mods["attack_speed_multiplier"] * 100.0, mimic["max_stacks"], mimic["stats"]["na_dodge"]["flat"] * 100.0,
			mimic["stats"]["attack_speed_multiplier"]["flat"] * 100.0, mantis.abilities[0].fixed_value,
			grip["add_stacks"], grip["max_stacks"], grip["stats"]["attack_power"]["pct"] * -100.0],
		"g13_hypno_pistols": [hypno.flat_mods["attack_power"], hypno.pct_mods["attack_speed_multiplier"] * 100.0, hypno.abilities[0].fixed_value,
			hypno.abilities[1].cooldown, _branch("g13_hypno_pistols", 1, "enemy_effect")["cfg"]["duration"], sugg["duration"],
			sugg["stats"]["damage_taken_pct"]["flat"] * 100.0],
		"g13_cradle_bow": [cradle.flat_mods["max_health"], cradle.flat_mods["haste"] * 100.0, cradle.abilities[0].cooldown,
			cradle.abilities[0].keyword_values.get("multi_attack", 0), crad["duration"], crad["stats"]["damage_taken_pct"]["flat"] * 100.0,
			crad["stats"]["health_regen_per_second"]["flat"], drow["duration"], drow["stats"]["attack_speed_multiplier"]["flat"] * -100.0],
		"g13_azure_dragon_bow": [dragon.flat_mods["attack_power"], dragon.flat_mods["max_health"], dragon.pct_mods["attack_speed_multiplier"] * 100.0,
			dragon.abilities[0].cooldown, _branch("g13_azure_dragon_bow", 0, "enemy_effect")["value_multiplier"] * 100.0,
			_branch("g13_azure_dragon_bow", 0, "ally_effect")["value_multiplier"] * 100.0, awe["duration"], awe["stats"]["damage_taken_amp"]["flat"] * 100.0],
		"g13_rose_bouquet": [rose.flat_mods["attack_power"], rose.flat_mods["max_health"], rose.pct_mods["attack_speed_multiplier"] * 100.0,
			rose.abilities[0].keyword_values.get("multi_attack", 0), frag["duration"], frag["stats"]["damage_taken_pct"]["flat"] * 100.0,
			frag["stats"]["health_regen_per_second"]["flat"], rose.abilities[0].fixed_value, rose.abilities[1].cooldown,
			_branch("g13_rose_bouquet", 1, "ally_effect")["value_multiplier"] * 100.0],
	}
	for id: String in nums.keys():
		for lang: String in ["zh", "en"]:
			var desc: String = Loc.t_in(lang, "equipment.%s.desc" % id)
			for n: Variant in nums[id]:
				var s: String = str(int(round(float(n)))) if absf(float(n) - round(float(n))) < 0.001 else str(float(n))
				t.ok(desc.contains(s), "%s (%s): the text says %s" % [id, lang, s])
	for sid: String in ["g13_amber_shell", "g13_mimicry", "g13_mantis_grip", "g13_suggestion", "g13_cradle", "g13_drowse", "g13_dragon_awe", "g13_fragrance"]:
		for lang2: String in ["zh", "en"]:
			t.ok(Loc.t_in(lang2, "status." + sid) != "status." + sid, "status %s has a %s name" % [sid, lang2])
			t.ok(Loc.t_in(lang2, "status.%s.desc" % sid) != "status.%s.desc" % sid, "status %s has a %s description" % [sid, lang2])


# ================================================================ 琥珀双刃
func test_amber_daggers(t: TestCtx) -> void:
	var b := _crowd("g13_amber_daggers", 1, 1)
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("g13_amber_daggers")
	var r: float = e.abilities[0].value_multiplier
	var shell: Dictionary = (e.abilities[0].effect_config["pre_effects"] as Array)[0]
	var stun: float = float(e.abilities[1].effect_config["duration"])
	var dr0: float = u.get_stats().damage_taken_pct
	# 敌人：触发数值 × r 物理伤害 + 【眩晕】；携带者先披【琥珀甲】
	var evs: Array[Dictionary] = _pull(b, u, foe, 200.0)
	t.near(_sum(evs, "damage", foe), 200.0 * r, 200.0 * r * 0.05, "an enemy takes trigger value × %.0f%% physical" % (r * 100.0))
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "physical"), "physical damage")
	t.ok(foe.is_stunned(), "and is sealed in amber (stunned)")
	t.near(_expires_in(b, foe, "stun"), stun, 0.01, "for %.1f s" % stun)
	t.ok(u.get_status("g13_amber_shell") != null and foe.get_status("g13_amber_shell") == null, "the holder (only) gains Amber Shell")
	t.near(u.get_stats().damage_taken_pct, dr0 + float(shell["stats"]["damage_taken_pct"]["flat"]), 0.001, "-%.0f%% damage taken" % (float(shell["stats"]["damage_taken_pct"]["flat"]) * 100.0))
	t.near(_expires_in(b, u, "g13_amber_shell"), float(shell["duration"]), 0.01, "for %.0f s" % float(shell["duration"]))
	t.eq(foe.shield, 0.0, "enemies aren't shielded")
	# 冷却
	var hp0: float = foe.hp
	_pull_noclear(b, u, foe, 200.0)
	t.near(foe.hp, hp0, 0.01, "%.0f s cooldown" % e.abilities[0].cooldown)
	# 队友(含自己)：触发数值 × r 护盾，不受伤、不眩晕
	evs = _pull(b, u, ally, 100.0)
	t.near(ally.shield, 100.0 * r, 0.5, "an ally gains a shield of trigger value × %.0f%%" % (r * 100.0))
	t.eq(_sum(evs, "damage", ally), 0.0, "allies aren't hurt")
	t.ok(not ally.is_stunned(), "allies aren't stunned")
	_pull(b, u, u, 100.0)
	t.near(u.shield, 100.0 * r, 0.5, "self: a shield too")
	t.ok(not u.is_stunned(), "the holder isn't stunned")


# ================================================================ 螳螂双镰
func test_mantis_sickles(t: TestCtx) -> void:
	# 携带者 + 2 个队友(一个贴着、一个远远的) + 2 个敌人(一个贴着主目标、一个远远的)
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2(0, -3), "weapon": "g13_mantis_sickles"},
		{"def": "test_dummy", "pos": Vector2(1.0, -3)}, {"def": "test_dummy", "pos": Vector2(6.0, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.0, 3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(7.0, 3)}])
	b.start()
	for bu: BUnit in b.units:
		bu.attack_cd = 1.0e9
		bu.base.crit_chance = 0.0
		bu.mark_dirty()
	var u: BUnit = b.units[0]
	var near_ally: BUnit = b.units[1]
	var far_ally: BUnit = b.units[2]
	var foe: BUnit = b.units[3]
	var near_foe: BUnit = b.units[4]
	var far_foe: BUnit = b.units[5]
	var e: EquipmentDef = _eq("g13_mantis_sickles")
	var hit: float = e.abilities[0].fixed_value
	var mimic: Dictionary = (e.abilities[0].effect_config["pre_effects"] as Array)[0]
	var grip: Dictionary = e.abilities[1].effect_config
	var add: int = int(grip["add_stacks"])
	var maxs: int = int(grip["max_stacks"])
	t.near(u.get_stats().na_dodge, float(e.flat_mods["na_dodge"]), 0.001, "the holder has the sickles' dodge")
	var dodge0: float = u.get_stats().na_dodge
	var fatk0: float = foe.get_stats().attack_power
	# 敌人：固定物理伤害(溅给它身边的敌人) + add 层【螳斧】；携带者先叠 1 层【拟态】
	var evs: Array[Dictionary] = _pull(b, u, foe, 999.0)
	t.near(_sum(evs, "damage", foe), hit, hit * 0.05, "an enemy takes a fixed %.0f physical (whatever the trigger value)" % hit)
	t.near(_sum(evs, "damage", near_foe), hit, hit * 0.05, "Splash: so does the enemy next to it")
	t.eq(_sum(evs, "damage", far_foe), 0.0, "but not one far away")
	t.eq(_sum(evs, "damage", near_ally) + _sum(evs, "damage", u), 0.0, "no damage to our side")
	t.eq(foe.status_stacks("g13_mantis_grip"), add, "and gains %d stacks of Mantis Grip" % add)
	t.near(foe.get_stats().attack_power, fatk0 * (1.0 + float(grip["stats"]["attack_power"]["pct"]) * float(add)), 0.5, "less attack per stack")
	t.ok(foe.get_status("g13_mantis_grip").expires_at < 0.0, "Mantis Grip lasts the battle")
	t.eq(u.status_stacks("g13_mimicry"), 1, "the holder gains a stack of Mimicry")
	t.ok(u.get_status("g13_mimicry").expires_at < 0.0, "Mimicry lasts the battle")
	t.eq(foe.status_stacks("g13_mimicry"), 0, "the target doesn't")
	t.near(u.get_stats().na_dodge, dodge0 + float(mimic["stats"]["na_dodge"]["flat"]), 0.001, "more normal-attack dodge")
	for i in range(maxs + 2):
		_pull(b, u, foe, 1.0)
	t.eq(foe.status_stacks("g13_mantis_grip"), maxs, "Mantis Grip stacks to %d" % maxs)
	t.eq(u.status_stacks("g13_mimicry"), int(mimic["max_stacks"]), "Mimicry stacks to %d" % int(mimic["max_stacks"]))
	t.eq(u.status_stacks("g13_mantis_grip"), 0, "the holder isn't gripped")
	# 队友(含自己)：回复固定值，也溅给它身边的队友；不受伤、不挨螳斧
	u.hp = 100.0
	near_ally.hp = 100.0
	far_ally.hp = 100.0
	evs = _pull(b, u, u, 1.0)
	var hb: float = 1.0 + u.get_stats().healing_done_pct
	t.near(_sum(evs, "heal", u), hit * hb, 1.0, "the holder heals a fixed %.0f" % hit)
	t.near(_sum(evs, "heal", near_ally), hit * hb, 1.0, "Splash: so does the ally next to it")
	t.eq(_sum(evs, "heal", far_ally), 0.0, "but not one far away")
	t.eq(_sum(evs, "heal", near_foe), 0.0, "enemies aren't healed")
	t.eq(near_ally.status_stacks("g13_mantis_grip") + u.status_stacks("g13_mantis_grip"), 0, "allies aren't gripped")


# ================================================================ 催眠双枪
func test_hypno_pistols(t: TestCtx) -> void:
	var b := _crowd("g13_hypno_pistols", 1, 2)
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("g13_hypno_pistols")
	var zap: float = e.abilities[0].fixed_value
	var dur: float = float(e.abilities[1].effect_config["enemy_effect"]["cfg"]["duration"])
	var sugg: Dictionary = e.abilities[1].effect_config["ally_effect"]["cfg"]
	# 敌人：固定魔法伤害 + 【误导】
	var evs: Array[Dictionary] = _pull(b, u, foe, 999.0)
	t.near(_sum(evs, "damage", foe), zap, zap * 0.05, "an enemy takes a fixed %.0f magic" % zap)
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "magic"), "magic damage")
	t.ok(foe.misled_status() != null, "and is Misled")
	t.near(_expires_in(b, foe, "misled"), dur, 0.01, "for %.0f s" % dur)
	# 【基本】：伤害段连扣都生效；误导有冷却
	var hp0: float = foe.hp
	_pull_noclear(b, u, foe, 1.0)
	t.near(hp0 - foe.hp, zap, zap * 0.05, "【Basic】: the zap lands on every pull")
	var foe2: BUnit = b.units[3]
	_pull_noclear(b, u, foe2, 1.0)
	t.ok(foe2.misled_status() == null, "the mislead has a %.0f s cooldown" % e.abilities[1].cooldown)
	# 队友：回复固定值 + 【暗示】(受到的伤害降低)，不被误导
	ally.hp = 100.0
	var dr0: float = ally.get_stats().damage_taken_pct
	evs = _pull(b, u, ally, 999.0)
	var hb: float = 1.0 + u.get_stats().healing_done_pct
	t.near(_sum(evs, "heal", ally), zap * hb, 1.0, "an ally heals a fixed %.0f" % zap)
	t.eq(_sum(evs, "damage", ally), 0.0, "allies aren't hurt")
	t.ok(ally.misled_status() == null, "allies aren't misled")
	t.ok(ally.get_status("g13_suggestion") != null, "an ally gains Suggestion")
	t.near(ally.get_stats().damage_taken_pct, dr0 + float(sugg["stats"]["damage_taken_pct"]["flat"]), 0.001, "less damage taken")
	t.near(_expires_in(b, ally, "g13_suggestion"), float(sugg["duration"]), 0.01, "for %.0f s" % float(sugg["duration"]))


# ================================================================ 摇篮月长弓
func test_cradle_bow(t: TestCtx) -> void:
	var b := _crowd("g13_cradle_bow", 3, 3)
	var u: BUnit = b.units[0]
	var e: EquipmentDef = _eq("g13_cradle_bow")
	var ma: int = int(e.abilities[0].keyword_values.get("multi_attack", 1))
	var crad: Dictionary = e.abilities[0].effect_config["ally_effect"]["cfg"]
	var drow: Dictionary = e.abilities[0].effect_config["enemy_effect"]["cfg"]
	t.near(u.get_stats().haste, float(e.flat_mods["haste"]), 0.001, "the holder has the bow's haste")
	# 队友(含自己)：【群攻】个人裹进【摇篮】(受到的伤害降低 + 每秒回复)，不吃触发数值
	var dr0: float = _allies(b, u)[0].get_stats().damage_taken_pct
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_allies", "ally", 9999.0)
	var lulled := 0
	for a: BUnit in b.units:
		if a.team == u.team and a.get_status("g13_cradle") != null:
			lulled += 1
			t.near(a.get_stats().health_regen_per_second, float(crad["stats"]["health_regen_per_second"]["flat"]), 0.01, "Cradle: regenerates health")
			t.near(_expires_in(b, a, "g13_cradle"), float(crad["duration"]), 0.01, "for %.0f s" % float(crad["duration"]))
		t.eq(a.shield, 0.0, "no shield (fixed effects only)")
		t.eq(_sum(evs, "heal", a), 0.0, "no instant heal from the trigger value")
	t.eq(lulled, ma, "Multi Attack %d: %d allies lulled" % [ma, ma])
	for a2: BUnit in _allies(b, u):
		if a2.get_status("g13_cradle") != null:
			t.near(a2.get_stats().damage_taken_pct, dr0 + float(crad["stats"]["damage_taken_pct"]["flat"]), 0.001, "less damage taken")
	# 冷却
	var c2 := 0
	_pull_rule(b, u, "all_allies", "ally", 1.0, false)
	for a3: BUnit in _allies(b, u):
		if a3.get_status("g13_cradle") != null:
			c2 += 1
	t.ok(c2 <= ma, "%.0f s cooldown: no new Cradle" % e.abilities[0].cooldown)
	# 敌人：【安眠】(攻击速度降低)，不受伤
	var fas0: float = _foes(b, u)[0].get_stats().attack_speed_multiplier
	evs = _pull_rule(b, u, "all_enemies", "enemy", 9999.0)
	var drowsy := 0
	for f: BUnit in _foes(b, u):
		if f.get_status("g13_drowse") != null:
			drowsy += 1
			t.near(f.get_stats().attack_speed_multiplier, fas0 + float(drow["stats"]["attack_speed_multiplier"]["flat"]), 0.001, "Drowse: slower attacks")
			t.ok(f.get_status("g13_cradle") == null, "enemies aren't cradled")
		t.eq(_sum(evs, "damage", f), 0.0, "no damage")
	t.eq(drowsy, ma, "Multi Attack %d: %d enemies drowse" % [ma, ma])


# ================================================================ 青龙长弓
func test_azure_dragon_bow(t: TestCtx) -> void:
	var b := _crowd("g13_azure_dragon_bow", 1, 1)
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("g13_azure_dragon_bow")
	var r: float = float(e.abilities[0].effect_config["enemy_effect"]["value_multiplier"])
	var s: float = float(e.abilities[0].effect_config["ally_effect"]["value_multiplier"])
	var awe: Dictionary = e.abilities[1].effect_config
	var amp0: float = foe.get_stats().damage_taken_amp
	# 敌人：触发数值 × r 物理伤害 + 【龙威】(受到的伤害提高)
	var evs: Array[Dictionary] = _pull(b, u, foe, 200.0)
	t.near(_sum(evs, "damage", foe), 200.0 * r, 200.0 * r * 0.25, "an enemy takes about trigger value × %.0f%% physical" % (r * 100.0))
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "physical"), "physical damage")
	t.ok(foe.get_status("g13_dragon_awe") != null, "and is awed")
	t.near(foe.get_stats().damage_taken_amp, amp0 + float(awe["stats"]["damage_taken_amp"]["flat"]), 0.001, "takes more damage")
	t.near(_expires_in(b, foe, "g13_dragon_awe"), float(awe["duration"]), 0.01, "for %.0f s" % float(awe["duration"]))
	# 龙威之后的伤害更痛(下一次扣：同样的触发数值)
	var evs2: Array[Dictionary] = _pull(b, u, foe, 200.0)
	t.ok(_sum(evs2, "damage", foe) > _sum(evs, "damage", foe) * 1.05, "Dragon's Awe amplifies the next hit")
	# 冷却
	var hp0: float = foe.hp
	_pull_noclear(b, u, foe, 200.0)
	t.near(foe.hp, hp0, 0.01, "%.0f s cooldown" % e.abilities[0].cooldown)
	# 队友(含自己)：触发数值 × s 护盾，不受伤、不挨龙威
	evs = _pull(b, u, ally, 300.0)
	t.near(ally.shield, 300.0 * s, 0.5, "an ally gains a shield of trigger value × %.0f%%" % (s * 100.0))
	t.eq(_sum(evs, "damage", ally), 0.0, "allies aren't hurt")
	t.ok(ally.get_status("g13_dragon_awe") == null, "allies aren't awed")


# ================================================================ 玫瑰花束
func test_rose_bouquet(t: TestCtx) -> void:
	var b := _crowd("g13_rose_bouquet", 4, 4)
	var u: BUnit = b.units[0]
	var e: EquipmentDef = _eq("g13_rose_bouquet")
	var ma: int = int(e.abilities[0].keyword_values.get("multi_attack", 1))
	var thorn: float = e.abilities[0].fixed_value
	var frag: Dictionary = e.abilities[0].effect_config["ally_effect"]["cfg"]
	var r: float = float(e.abilities[1].effect_config["ally_effect"]["value_multiplier"])
	var hb: float = 1.0 + u.get_stats().healing_done_pct
	# 队友：【群攻】个人获得【芬芳】；第二段回复 触发数值 × r(只给第一个目标——它不带【群攻】)
	for a: BUnit in _allies(b, u):
		a.hp = 100.0
	var dr0: float = _allies(b, u)[0].get_stats().damage_taken_pct
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_allies_except_self", "ally", 200.0)
	var scented := 0
	var healed := 0
	for a2: BUnit in _allies(b, u):
		if a2.get_status("g13_fragrance") != null:
			scented += 1
			t.near(a2.get_stats().damage_taken_pct, dr0 + float(frag["stats"]["damage_taken_pct"]["flat"]), 0.001, "Fragrance: less damage taken")
			t.near(a2.get_stats().health_regen_per_second, float(frag["stats"]["health_regen_per_second"]["flat"]), 0.01, "and regenerates health")
			t.near(_expires_in(b, a2, "g13_fragrance"), float(frag["duration"]), 0.01, "for %.0f s" % float(frag["duration"]))
		if _sum(evs, "heal", a2) > 0.0:
			healed += 1
			t.near(_sum(evs, "heal", a2), 200.0 * r * hb, 1.0, "an ally heals trigger value × %.0f%%" % (r * 100.0))
		t.eq(_sum(evs, "damage", a2), 0.0, "allies aren't hurt")
	t.eq(scented, ma, "Multi Attack %d: %d allies get flowers" % [ma, ma])
	t.eq(healed, 1, "the heal goes to one ally")
	# 【基本】：芬芳连扣都刷新；回复有冷却
	var a0: BUnit = _allies(b, u)[0]
	a0.hp = 100.0
	evs = _pull_rule(b, u, "all_allies_except_self", "ally", 200.0, false)
	var again := 0.0
	for a3: BUnit in _allies(b, u):
		again += _sum(evs, "heal", a3)
	t.eq(again, 0.0, "the heal has a %.0f s cooldown" % e.abilities[1].cooldown)
	# 敌人：固定物理伤害(刺) + 第二段 触发数值 × r 物理
	evs = _pull_rule(b, u, "all_enemies", "enemy", 100.0)
	var hit := 0
	var total := 0.0
	for f: BUnit in _foes(b, u):
		var d: float = _sum(evs, "damage", f)
		if d > 0.0:
			hit += 1
			total += d
		t.ok(f.get_status("g13_fragrance") == null, "enemies get no flowers")
	t.eq(hit, ma, "Multi Attack %d: thorns for %d enemies" % [ma, ma])
	t.near(total, thorn * float(ma) + 100.0 * r, (thorn * float(ma) + 100.0 * r) * 0.05, "thorns %.0f each + trigger value × %.0f%% on one" % [thorn, r * 100.0])
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "physical"), "physical damage")
