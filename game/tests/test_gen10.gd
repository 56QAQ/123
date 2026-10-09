extends RefCounted
## 通用武器 · gen10：青藤剑 / 刻时剑 / 血宴长剑(单手剑)、流水双刃 / 蛇牙双刃(双匕)、杨柳净瓶(法器)、夜莺长弓(弓，追加)。
## 每把用一个"探针触发器"(目标 = 事件目标 / 指定规则、固定触发数值)直接扣动载荷验证效果；再查数据(格子、外观、随机池)、文本里的数值和适配角色。

## 武器 -> [费用, 颜色, 大类, 外观]
const SLOTS := {
	"g10_vine_sword": [3, "green", "sword", "g10_vine"],
	"g10_chrono_sword": [2, "blue", "sword", "g10_chrono"],
	"g10_feast_sword": [4, "red", "sword", "g10_feast"],
	"g10_current_daggers": [2, "cyan", "dual", "g10_current"],
	"g10_viper_daggers": [4, "green", "dual", "g10_viper"],
	"g10_willow_vase": [3, "green", "focus", "g10_willow"],
	"g10_nightingale_bow": [3, "purple", "bow", "g10_nightingale"],
}
## 合手的棋子(测强度定下的)：都要在适配角色里，并且 1~3 星都装得上
const CARRIERS := {
	"g10_vine_sword": ["node_samurai", "node_killer", "node_warden", "node_peasant"],
	"g10_chrono_sword": ["node_druid", "node_paladin", "node_shielder"],
	"g10_feast_sword": ["node_gladiator", "node_darkknight"],
	"g10_current_daggers": ["node_knight_errant", "node_hunter"],
	"g10_viper_daggers": ["node_hunter", "node_rogue"],
	"g10_willow_vase": ["node_taoist", "node_warden"],
	"g10_nightingale_bow": ["node_druid", "node_nurse"],
}


func _probe(v: float) -> TriggerDef:
	return TriggerDef.from_dict({"id": "probe_trigger_g10", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
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
	var trig := TriggerDef.from_dict({"id": "probe_trigger_g10_multi", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
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
		t.ok(not models.has(e.model), "%s: look not shared with another gen10 weapon" % id)
		models[e.model] = true
		t.eq(e.projectile, "", "%s shoots its class's default projectile (melee / magic bolt)" % id)
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


func _branch(id: String, i: int, key: String) -> Dictionary:
	return _cfg(id, i)[key]


## 描述里的数值和数据一致(百分比按 ×100 写)
func test_text_numbers(t: TestCtx) -> void:
	var vine: Dictionary = (_cfg("g10_vine_sword", 0)["extra_effects"] as Array)[0]
	var chrono_pre: Dictionary = (_cfg("g10_chrono_sword")["pre_effects"] as Array)[0]
	var feast_ex: Dictionary = (_cfg("g10_feast_sword")["extra_effects"] as Array)[0]
	var flow: Dictionary = _branch("g10_current_daggers", 1, "ally_effect")["cfg"]
	var ebb: Dictionary = _branch("g10_current_daggers", 1, "enemy_effect")["cfg"]
	var coil: Dictionary = (_cfg("g10_viper_daggers")["pre_effects"] as Array)[0]
	var viper: Dictionary = _cfg("g10_viper_daggers")
	var dew: Dictionary = _branch("g10_willow_vase", 0, "ally_effect")["cfg"]
	var wither: Dictionary = _branch("g10_willow_vase", 0, "enemy_effect")["cfg"]
	var noct: Dictionary = _branch("g10_nightingale_bow", 1, "ally_effect")["cfg"]
	var lament: Dictionary = _branch("g10_nightingale_bow", 1, "enemy_effect")["cfg"]
	var nums := {
		"g10_vine_sword": [_eq("g10_vine_sword").flat_mods["attack_power"], _eq("g10_vine_sword").flat_mods["max_health"],
			_eq("g10_vine_sword").abilities[0].fixed_value, vine["max_stacks"], vine["stats"]["attack_power"]["pct"] * 100.0,
			vine["stats"]["max_health"]["flat"], _eq("g10_vine_sword").abilities[1].cooldown, _branch("g10_vine_sword", 1, "ally_effect")["value_multiplier"] * 100.0],
		"g10_chrono_sword": [_eq("g10_chrono_sword").flat_mods["max_health"], _eq("g10_chrono_sword").flat_mods["haste"] * 100.0,
			_eq("g10_chrono_sword").abilities[0].cooldown, chrono_pre["duration"], chrono_pre["max_stacks"], chrono_pre["stats"]["haste"]["flat"] * 100.0,
			_branch("g10_chrono_sword", 0, "ally_effect")["value_multiplier"] * 100.0, _branch("g10_chrono_sword", 0, "enemy_effect")["value_multiplier"] * 100.0],
		"g10_feast_sword": [_eq("g10_feast_sword").flat_mods["attack_power"], _eq("g10_feast_sword").flat_mods["max_health"],
			_eq("g10_feast_sword").flat_mods["physical_lifesteal"] * 100.0, _eq("g10_feast_sword").abilities[0].value_multiplier * 100.0,
			feast_ex["max_stacks"], feast_ex["stats"]["attack_power"]["pct"] * 100.0, feast_ex["stats"]["physical_lifesteal"]["flat"] * 100.0,
			_cfg("g10_feast_sword")["shield_cap_pct"] * 100.0],
		"g10_current_daggers": [_eq("g10_current_daggers").pct_mods["attack_speed_multiplier"] * 100.0, _eq("g10_current_daggers").flat_mods["na_dodge"] * 100.0,
			_eq("g10_current_daggers").flat_mods["physical_lifesteal"] * 100.0, _eq("g10_current_daggers").abilities[0].fixed_value, flow["duration"], flow["stats"]["attack_speed_multiplier"]["flat"] * 100.0,
			flow["stats"]["move_speed"]["pct"] * 100.0, ebb["stats"]["attack_speed_multiplier"]["flat"] * -100.0, ebb["stats"]["move_speed"]["pct"] * -100.0],
		"g10_viper_daggers": [_eq("g10_viper_daggers").flat_mods["attack_power"], _eq("g10_viper_daggers").flat_mods["max_health"],
			coil["max_stacks"], coil["stats"]["attack_power"]["pct"] * 100.0, coil["stats"]["attack_speed_multiplier"]["flat"] * 100.0,
			viper["add_stacks"], viper["duration"], viper["max_stacks"], viper["dot"]["amount"], _eq("g10_viper_daggers").abilities[0].fixed_value],
		"g10_willow_vase": [_eq("g10_willow_vase").flat_mods["ability_power"], _eq("g10_willow_vase").flat_mods["healing_done_pct"] * 100.0,
			dew["duration"], dew["stats"]["healing_received_pct"]["flat"] * 100.0, dew["stats"]["health_regen_per_second"]["flat"],
			wither["stats"]["attack_power"]["pct"] * -100.0, wither["stats"]["healing_received_pct"]["flat"] * -100.0,
			_eq("g10_willow_vase").abilities[1].cooldown, _branch("g10_willow_vase", 1, "ally_effect")["value_multiplier"] * 100.0],
		"g10_nightingale_bow": [_eq("g10_nightingale_bow").flat_mods["healing_done_pct"] * 100.0, _eq("g10_nightingale_bow").flat_mods["max_health"],
			_eq("g10_nightingale_bow").abilities[0].cooldown,
			_branch("g10_nightingale_bow", 0, "ally_effect")["value_multiplier"] * 100.0,
			noct["duration"], noct["stats"]["attack_speed_multiplier"]["flat"] * 100.0, noct["stats"]["healing_received_pct"]["flat"] * 100.0,
			noct["stats"]["attack_power"]["pct"] * 100.0,
			lament["stats"]["attack_speed_multiplier"]["flat"] * -100.0],
	}
	for id: String in nums.keys():
		for lang: String in ["zh", "en"]:
			var desc: String = Loc.t_in(lang, "equipment.%s.desc" % id)
			for n: Variant in nums[id]:
				var s: String = str(int(round(float(n))))
				t.ok(desc.contains(s), "%s (%s): the text says %s" % [id, lang, s])


# ================================================================ 青藤剑
func test_vine_sword(t: TestCtx) -> void:
	var b := _crowd("g10_vine_sword", 1, 1)
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("g10_vine_sword")
	var ex: Dictionary = (e.abilities[0].effect_config["extra_effects"] as Array)[0]
	var maxs: int = int(ex["max_stacks"])
	var per_atk: float = float(ex["stats"]["attack_power"]["pct"])
	var per_hp: float = float(ex["stats"]["max_health"]["flat"])
	var heal_r: float = float(e.abilities[1].effect_config["ally_effect"]["value_multiplier"])
	var atk0: float = u.get_stats().attack_power
	var hp0: float = u.get_stats().max_health
	# 敌人：固定伤害(不吃触发数值)，携带者长一层【抽枝】
	var evs: Array[Dictionary] = _pull(b, u, foe, 999.0)
	t.near(_sum(evs, "damage", foe), e.abilities[0].fixed_value, e.abilities[0].fixed_value * 0.05, "an enemy takes a fixed %.0f physical" % e.abilities[0].fixed_value)
	t.eq(_sum(evs, "heal", foe), 0.0, "enemies aren't healed by the second part")
	t.eq(u.status_stacks("g10_sprout"), 1, "the holder gains a stack of Sprout")
	t.eq(foe.status_stacks("g10_sprout"), 0, "the target doesn't")
	t.ok(u.get_status("g10_sprout").expires_at < 0.0, "Sprout lasts the whole battle")
	# 【基本】：连扣都生效，叠满 maxs 层
	for i in range(maxs + 3):
		_pull_noclear(b, u, foe, 1.0)
	t.eq(u.status_stacks("g10_sprout"), maxs, "【Basic】: every pull adds a stack, up to %d" % maxs)
	t.near(u.get_stats().attack_power, atk0 * (1.0 + per_atk * float(maxs)), 0.5, "+%.0f%% attack a stack" % (per_atk * 100.0))
	t.near(u.get_stats().max_health, hp0 + per_hp * float(maxs), 0.5, "+%.0f max health a stack" % per_hp)
	# 队友：不受伤；第二段回复 触发数值 × r(冷却 3 秒)
	ally.hp = 100.0
	evs = _pull(b, u, ally, 200.0)
	t.eq(_sum(evs, "damage", ally), 0.0, "allies aren't hurt")
	var hb: float = 1.0 + u.get_stats().healing_done_pct
	t.near(_sum(evs, "heal", ally), 200.0 * heal_r * hb, 1.0, "an ally heals trigger value × %.0f%%" % (heal_r * 100.0))
	evs = _pull_noclear(b, u, ally, 200.0)
	t.eq(_sum(evs, "heal", ally), 0.0, "the heal has a %.0f s cooldown" % e.abilities[1].cooldown)


# ================================================================ 刻时剑
func test_chrono_sword(t: TestCtx) -> void:
	var b := _crowd("g10_chrono_sword", 3, 4)
	var u: BUnit = b.units[0]
	var cfg: Dictionary = _cfg("g10_chrono_sword")
	var pre: Dictionary = (cfg["pre_effects"] as Array)[0]
	var per: float = float(pre["stats"]["haste"]["flat"])
	var maxs: int = int(pre["max_stacks"])
	var s: float = float(cfg["ally_effect"]["value_multiplier"])
	var r: float = float(cfg["enemy_effect"]["value_multiplier"])
	t.near(u.get_stats().haste, float(_eq("g10_chrono_sword").flat_mods["haste"]), 0.001, "the holder has the sword's haste")
	var h0: float = u.get_stats().haste
	# 队友：【群攻 3】个队友(含自己)获得 触发数值 × s 的护盾；携带者获得 1 层【超频】(只一层：每次发动一次)
	_pull_rule(b, u, "all_allies", "ally", 200.0)
	var shielded := 0
	for a: BUnit in b.units:
		if a.team == u.team and a.shield > 0.5:
			shielded += 1
			t.near(a.shield, 200.0 * s, 200.0 * s * 0.05 + 0.5, "a shield of value × %.0f%%" % (s * 100.0))
	t.eq(shielded, 3, "Multi Attack 3: three allies shielded")
	t.eq(u.status_stacks("g10_overclock"), 1, "the holder gains one stack of Overclock per activation")
	t.near(u.get_stats().haste, h0 + per, 0.001, "+%.0f%% haste" % (per * 100.0))
	t.near(_expires_in(b, u, "g10_overclock"), float(pre["duration"]), 0.01, "for %.0f s" % float(pre["duration"]))
	for a2: BUnit in _allies(b, u):
		t.eq(a2.status_stacks("g10_overclock"), 0, "only the holder overclocks")
	# 敌人：3 个敌人受到 触发数值 × r 魔法伤害；携带者照样叠【超频】
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_enemies", "enemy", 300.0)
	var hit := 0
	for f: BUnit in _foes(b, u):
		var d: float = _sum(evs, "damage", f)
		if d > 0.0:
			hit += 1
			t.near(d, 300.0 * r, 300.0 * r * 0.05, "an enemy takes value × %.0f%% magic" % (r * 100.0))
		t.eq(f.shield, 0.0, "enemies aren't shielded")
	t.eq(hit, 3, "Multi Attack 3: three enemies hit")
	var kinds: Array = evs.filter(func(e: Dictionary) -> bool: return e.get("t") == "damage").map(func(e: Dictionary) -> String: return str(e["kind"]))
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "magic"), "magic damage")
	t.eq(u.status_stacks("g10_overclock"), 2, "Overclock stacks whoever the target")
	for i in range(maxs + 2):
		_pull_rule(b, u, "all_enemies", "enemy", 1.0)
	t.eq(u.status_stacks("g10_overclock"), maxs, "up to %d stacks" % maxs)
	# 冷却 3 秒(计时加速会缩短它)
	evs = _pull_rule(b, u, "all_enemies", "enemy", 300.0, false)
	var again := 0.0
	for f2: BUnit in _foes(b, u):
		again += _sum(evs, "damage", f2)
	t.eq(again, 0.0, "%.0f s cooldown" % _eq("g10_chrono_sword").abilities[0].cooldown)
	var cd_left: float = float(u.ability_cd.get("g10_chrono_tick", 0.0)) - b.time
	t.near(cd_left, _eq("g10_chrono_sword").abilities[0].cooldown / (1.0 + u.get_stats().haste), 0.01, "haste shortens the cooldown")


# ================================================================ 血宴长剑
func test_feast_sword(t: TestCtx) -> void:
	var b := _crowd("g10_feast_sword", 1, 1)
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var a: AbilityDef = _eq("g10_feast_sword").abilities[0]
	var ex: Dictionary = (a.effect_config["extra_effects"] as Array)[0]
	var maxs: int = int(ex["max_stacks"])
	var per_atk: float = float(ex["stats"]["attack_power"]["pct"])
	var per_ls: float = float(ex["stats"]["physical_lifesteal"]["flat"])
	t.near(u.get_stats().physical_lifesteal, float(_eq("g10_feast_sword").flat_mods["physical_lifesteal"]), 0.001, "the holder has the sword's lifesteal")
	var atk0: float = u.get_stats().attack_power
	var ls0: float = u.get_stats().physical_lifesteal
	# 自己(狩胜 / 守誓)：回复 触发数值 × r，再获得 1 层【血宴】
	u.hp = 100.0
	var evs: Array[Dictionary] = _pull(b, u, u, 100.0)
	var hb: float = 1.0 + u.get_stats().healing_done_pct
	t.near(_sum(evs, "heal", u), 100.0 * a.value_multiplier * hb, 1.0, "the holder heals trigger value × %.0f%%" % (a.value_multiplier * 100.0))
	t.eq(u.shield, 0.0, "no overhealing, no shield")
	t.eq(u.status_stacks("g10_feast"), 1, "and gains a stack of Bloodfeast")
	t.ok(u.get_status("g10_feast").expires_at < 0.0, "Bloodfeast lasts the battle")
	for i in range(maxs + 2):
		_pull_noclear(b, u, u, 10.0)
	t.eq(u.status_stacks("g10_feast"), maxs, "【Basic】: every pull adds a stack, up to %d" % maxs)
	t.near(u.get_stats().attack_power, atk0 * (1.0 + per_atk * float(maxs)), 0.5, "+%.0f%% attack a stack" % (per_atk * 100.0))
	t.near(u.get_stats().physical_lifesteal, ls0 + per_ls * float(maxs), 0.001, "+%.0f%% physical lifesteal a stack" % (per_ls * 100.0))
	# 溢出的治疗变成护盾，最多补到最大生命的 cap
	var cap: float = float(a.effect_config["shield_cap_pct"])
	var mh: float = u.get_stats().max_health
	u.hp = mh - 10.0
	_pull_noclear(b, u, u, 100.0)
	t.near(u.shield, 100.0 * a.value_multiplier * hb - 10.0, 1.0, "overhealing becomes a shield")
	u.hp = mh - 10.0
	_pull_noclear(b, u, u, mh)
	t.near(u.shield, mh * cap, 1.0, "the shield tops out at %.0f%% of max health" % (cap * 100.0))
	# 队友：同样回复 + 一层
	ally.hp = 100.0
	evs = _pull(b, u, ally, 100.0)
	t.near(_sum(evs, "heal", ally), 100.0 * a.value_multiplier * hb, 1.0, "an ally heals too")
	t.eq(ally.status_stacks("g10_feast"), 1, "and gains a stack")
	t.eq(foe.status_stacks("g10_feast"), 0, "enemies don't")


# ================================================================ 流水双刃
func test_current_daggers(t: TestCtx) -> void:
	var b := _crowd("g10_current_daggers", 1, 1)
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("g10_current_daggers")
	var fixed: float = e.abilities[0].fixed_value
	var flow: Dictionary = e.abilities[1].effect_config["ally_effect"]["cfg"]
	var ebb: Dictionary = e.abilities[1].effect_config["enemy_effect"]["cfg"]
	t.near(u.get_stats().na_dodge, float(e.flat_mods["na_dodge"]), 0.001, "the holder dodges normal attacks more often")
	# 敌人：固定物理伤害 + 【逆流】
	var fas0: float = foe.get_stats().attack_speed_multiplier
	var fms0: float = foe.get_stats().move_speed
	var evs: Array[Dictionary] = _pull(b, u, foe, 999.0)
	t.near(_sum(evs, "damage", foe), fixed, fixed * 0.05, "an enemy takes a fixed %.0f physical" % fixed)
	t.ok(foe.get_status("g10_ebb") != null and foe.get_status("g10_flow") == null, "and goes Against the Current")
	t.near(foe.get_stats().attack_speed_multiplier, fas0 + float(ebb["stats"]["attack_speed_multiplier"]["flat"]), 0.001, "slower attacks")
	t.near(foe.get_stats().move_speed, fms0 * (1.0 + float(ebb["stats"]["move_speed"]["pct"])), 0.01, "slower movement")
	t.near(_expires_in(b, foe, "g10_ebb"), float(ebb["duration"]), 0.01, "for %.0f s" % float(ebb["duration"]))
	t.eq(foe.shield, 0.0, "enemies aren't shielded")
	# 自己 / 队友：固定护盾 + 【顺流】
	var as0: float = u.get_stats().attack_speed_multiplier
	evs = _pull(b, u, u, 1.0)
	t.near(u.shield, fixed, 0.5, "self: a fixed %.0f shield (whatever the trigger value)" % fixed)
	t.ok(u.get_status("g10_flow") != null and u.get_status("g10_ebb") == null, "and goes With the Current")
	var aspct: float = 1.0 + float(e.pct_mods.get("attack_speed_multiplier", 0.0))
	t.near(u.get_stats().attack_speed_multiplier, as0 + float(flow["stats"]["attack_speed_multiplier"]["flat"]) * aspct, 0.001, "faster attacks")
	t.eq(_sum(evs, "damage", u), 0.0, "and no damage to the holder")
	_pull(b, u, ally, 1.0)
	t.near(ally.shield, fixed, 0.5, "an ally: a shield too")
	t.ok(ally.get_status("g10_flow") != null, "and the current")


# ================================================================ 蛇牙双刃
func test_viper_daggers(t: TestCtx) -> void:
	var b := _crowd("g10_viper_daggers", 1, 1)
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("g10_viper_daggers")
	var cfg: Dictionary = e.abilities[0].effect_config
	var coil: Dictionary = (cfg["pre_effects"] as Array)[0]
	var add: int = int(cfg["add_stacks"])
	var maxv: int = int(cfg["max_stacks"])
	var dps: float = float(cfg["dot"]["amount"])
	var atk0: float = u.get_stats().attack_power
	# 敌人：add 层【蛇毒】；携带者 1 层【蛇行】
	_pull(b, u, foe, 999.0)
	t.eq(foe.status_stacks("g10_viper_venom"), add, "an enemy gains %d stacks of Viper Venom (whatever the trigger value)" % add)
	t.eq(u.status_stacks("g10_viper_coil"), 1, "the holder gains a stack of Coil")
	t.ok(u.get_status("g10_viper_coil").expires_at < 0.0, "Coil lasts the battle")
	t.eq(u.status_stacks("g10_viper_venom"), 0, "no venom on the holder")
	_pull(b, u, foe, 1.0)
	_pull(b, u, foe, 1.0)
	t.eq(foe.status_stacks("g10_viper_venom"), maxv, "venom stacks to %d" % maxv)
	# 每层每秒 dps 点魔法伤害
	b.poll_events()
	var hp0: float = foe.hp
	var frames: int = int(round(1.0 / GC.SIM_DT))
	for i in range(frames):
		b.step()
	t.near(hp0 - foe.hp, dps * float(maxv), dps * float(maxv) * 0.05, "%.0f magic damage a stack a second" % dps)
	# 【蛇行】叠满
	for i2 in range(int(coil["max_stacks"]) + 2):
		_pull(b, u, foe, 1.0)
	var maxc: int = int(coil["max_stacks"])
	t.eq(u.status_stacks("g10_viper_coil"), maxc, "Coil stacks to %d" % maxc)
	t.near(u.get_stats().attack_power, atk0 * (1.0 + float(coil["stats"]["attack_power"]["pct"]) * float(maxc)), 0.5, "more attack a stack")
	# 队友(含自己)：回复固定值，不中毒
	ally.hp = 100.0
	var evs: Array[Dictionary] = _pull(b, u, ally, 1.0)
	var hb: float = 1.0 + u.get_stats().healing_done_pct
	t.near(_sum(evs, "heal", ally), e.abilities[0].fixed_value * hb, 1.0, "an ally heals a fixed %.0f" % e.abilities[0].fixed_value)
	t.eq(ally.status_stacks("g10_viper_venom"), 0, "allies aren't poisoned")


# ================================================================ 杨柳净瓶
func test_willow_vase(t: TestCtx) -> void:
	var b := _crowd("g10_willow_vase", 1, 1)
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("g10_willow_vase")
	var dew: Dictionary = e.abilities[0].effect_config["ally_effect"]["cfg"]
	var wither: Dictionary = e.abilities[0].effect_config["enemy_effect"]["cfg"]
	var r: float = float(e.abilities[1].effect_config["ally_effect"]["value_multiplier"])
	var hb: float = 1.0 + u.get_stats().healing_done_pct
	# 队友：【甘露】(受到的治疗提高、每秒回复) + 回复 触发数值 × r
	ally.hp = 100.0
	var hr0: float = ally.get_stats().healing_received_pct
	var evs: Array[Dictionary] = _pull(b, u, ally, 200.0)
	t.ok(ally.get_status("g10_sweet_dew") != null and ally.get_status("g10_wither") == null, "an ally gains Sweet Dew")
	t.near(ally.get_stats().healing_received_pct, hr0 + float(dew["stats"]["healing_received_pct"]["flat"]), 0.001, "more healing received")
	t.near(ally.get_stats().health_regen_per_second, float(dew["stats"]["health_regen_per_second"]["flat"]), 0.01, "regenerates health")
	t.ok(_sum(evs, "heal", ally) >= 200.0 * r * hb - 1.0, "and heals at least trigger value × %.0f%%" % (r * 100.0))
	t.eq(_sum(evs, "damage", ally), 0.0, "allies aren't hurt")
	# 【基本】：第一段马上还能再扣；第二段有冷却
	ally.hp = 100.0
	evs = _pull_noclear(b, u, ally, 200.0)
	t.eq(_sum(evs, "heal", ally), 0.0, "the trigger-value heal has a %.0f s cooldown" % e.abilities[1].cooldown)
	t.ok(ally.get_status("g10_sweet_dew") != null, "but Sweet Dew is 【Basic】")
	# 敌人：【枯萎】(攻击力降低、受到的治疗降低) + 触发数值 × r 魔法伤害
	var atk0: float = foe.get_stats().attack_power
	evs = _pull(b, u, foe, 200.0)
	t.ok(foe.get_status("g10_wither") != null and foe.get_status("g10_sweet_dew") == null, "an enemy Withers")
	t.near(foe.get_stats().attack_power, atk0 * (1.0 + float(wither["stats"]["attack_power"]["pct"])), 0.5, "less attack")
	t.near(foe.get_stats().healing_received_pct, float(wither["stats"]["healing_received_pct"]["flat"]), 0.001, "less healing received")
	t.near(_sum(evs, "damage", foe), 200.0 * r, 200.0 * r * 0.05, "and takes trigger value × %.0f%% magic" % (r * 100.0))
	t.near(_expires_in(b, foe, "g10_wither"), float(wither["duration"]), 0.01, "for %.0f s" % float(wither["duration"]))


# ================================================================ 夜莺长弓
func test_nightingale_bow(t: TestCtx) -> void:
	var b := _crowd("g10_nightingale_bow", 3, 3)
	var u: BUnit = b.units[0]
	var e: EquipmentDef = _eq("g10_nightingale_bow")
	var r: float = float(e.abilities[0].effect_config["ally_effect"]["value_multiplier"])
	var noct: Dictionary = e.abilities[1].effect_config["ally_effect"]["cfg"]
	var lament: Dictionary = e.abilities[1].effect_config["enemy_effect"]["cfg"]
	var ma := 1                                                     # 不带【群攻】：一次只给一个人
	var hb: float = 1.0 + u.get_stats().healing_done_pct
	# 队友：【群攻 2】个队友回复 触发数值 × r 并获得【夜曲】
	for a: BUnit in _allies(b, u):
		a.hp = 100.0
	var as0: float = _allies(b, u)[0].get_stats().attack_speed_multiplier
	var hr0: float = _allies(b, u)[0].get_stats().healing_received_pct
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_allies_except_self", "ally", 200.0)
	var sung := 0
	for a2: BUnit in _allies(b, u):
		if a2.get_status("g10_nocturne") != null:
			sung += 1
			t.ok(_sum(evs, "heal", a2) >= 200.0 * r * hb - 1.0, "a sung-to ally heals trigger value × %.0f%%" % (r * 100.0))
			t.near(a2.get_stats().attack_speed_multiplier, as0 + float(noct["stats"]["attack_speed_multiplier"]["flat"]), 0.001, "Nocturne: faster attacks")
			t.near(a2.get_stats().healing_received_pct, hr0 + float(noct["stats"]["healing_received_pct"]["flat"]), 0.001, "and more healing received")
			t.near(_expires_in(b, a2, "g10_nocturne"), float(noct["duration"]), 0.01, "for %.0f s" % float(noct["duration"]))
		t.eq(_sum(evs, "damage", a2), 0.0, "allies aren't hurt")
	t.eq(sung, ma, "no Multi Attack: one ally at a time")
	t.near(u.get_stats().healing_done_pct, float(e.flat_mods["healing_done_pct"]), 0.001, "the holder heals more")
	# 冷却 2 秒
	evs = _pull_rule(b, u, "all_allies_except_self", "ally", 200.0, false)
	var again := 0.0
	for a3: BUnit in _allies(b, u):
		again += _sum(evs, "heal", a3)
	t.eq(again, 0.0, "%.0f s cooldown" % e.abilities[0].cooldown)
	# 敌人：触发数值 × r 魔法伤害 +【夜啼】
	var foe0: BUnit = _foes(b, u)[0]
	var fas0: float = foe0.get_stats().attack_speed_multiplier
	evs = _pull_rule(b, u, "all_enemies", "enemy", 300.0)
	var hit := 0
	for f: BUnit in _foes(b, u):
		var d: float = _sum(evs, "damage", f)
		if d > 0.0:
			hit += 1
			t.near(d, 300.0 * r, 300.0 * r * 0.05, "an enemy takes value × %.0f%% magic" % (r * 100.0))
			t.ok(f.get_status("g10_lament") != null and f.get_status("g10_nocturne") == null, "and Laments")
		t.eq(_sum(evs, "heal", f), 0.0, "enemies aren't healed")
	t.eq(hit, ma, "one enemy at a time")
	if foe0.get_status("g10_lament") != null:
		t.near(foe0.get_stats().attack_speed_multiplier, fas0 + float(lament["stats"]["attack_speed_multiplier"]["flat"]), 0.001, "slower attacks")
	var kinds: Array = evs.filter(func(ev: Dictionary) -> bool: return ev.get("t") == "damage").map(func(ev: Dictionary) -> String: return str(ev["kind"]))
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "magic"), "magic damage")
