extends RefCounted
## 通用武器 · gen15：仙人掌双枪 / 拳套弹簧枪 / 磁极双枪(手枪)、薄荷手弩(手弩)、心火双刃 / 蝙蝠双刃(双匕)。
## 每把用一个"探针触发器"(目标 = 事件目标 / 指定规则、固定触发数值)直接扣动载荷验证效果；再查数据(格子、外观、投射物、随机池)、文本里的数值和适配角色。

## 武器 -> [费用, 颜色, 大类, 外观, 投射物("" = 这个大类的默认弹 / 近战)]
const SLOTS := {
	"g15_cactus_revolvers": [4, "green", "pistols", "g15_cactus", "g15_spine"],
	"g15_boxing_pistols": [3, "red", "pistols", "g15_boxing", "g15_glove"],
	"g15_magnet_pistols": [4, "purple", "pistols", "g15_magnet", "g15_magnet"],
	"g15_mint_crossbow": [3, "green", "crossbow", "g15_mint", "g15_mint"],
	"g15_heartfire_daggers": [3, "red", "dual", "g15_heartfire", ""],
	"g15_bat_daggers": [2, "purple", "dual", "g15_bat", ""],
}
## 合手的棋子(测强度定下的)：都要在适配角色里，并且 1~3 星都装得上
const CARRIERS := {
	"g15_cactus_revolvers": ["node_cowboy", "node_taoist", "node_rogue"],
	"g15_boxing_pistols": ["node_archer", "node_nurse"],
	"g15_magnet_pistols": ["node_shielder", "node_nurse"],
	"g15_mint_crossbow": ["node_cowboy", "node_taoist"],
	"g15_heartfire_daggers": ["node_berserker", "node_dancer"],
	"g15_bat_daggers": ["node_maid", "node_gladiator", "node_runner"],
}
## 标签算上了、测出来 +0 的(fit_remove)：清扫拿手枪女仆护身术一次都不响；巧运拿拳套 / 蝙蝠 +0
const NOT_FIT := {"g15_boxing_pistols": ["node_maid", "node_rogue"], "g15_bat_daggers": ["node_rogue"]}


func _probe(v: float) -> TriggerDef:
	return TriggerDef.from_dict({"id": "probe_trigger_g15", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
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
	var trig := TriggerDef.from_dict({"id": "probe_trigger_g15_multi", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
		"target_rule": rule, "team_filter": team, "base_value_mode": "fixed", "base_value_flat": v})
	b.pipeline._fire(b.pipeline.make_event("OnBattleFrame", u, null, 0.0, ["battle_frame"], {}), trig, u)
	b.pipeline.drain()
	return b.poll_events()


## 一组木桩：specs = [[def, team, pos, weapon]]；都不攻击、不动、不暴击
func _field(specs: Array) -> Battle:
	var list: Array = []
	for s: Array in specs:
		var d: Dictionary = {"def": s[0], "team": s[1], "pos": s[2]}
		if s.size() > 3:
			d["weapon"] = s[3]
		list.append(d)
	var b := Fixture.make(list)
	b.start()
	for u: BUnit in b.units:
		u.attack_cd = 1.0e9
		u.base.crit_chance = 0.0
		u.mark_dirty()
	return b


## 携带者 + allies 个木桩队友 + foes 个木桩敌人(都不攻击、不动)
func _crowd(weapon: String, allies: int, foes: int) -> Battle:
	var specs: Array = [["test_hitter", 0, Vector2(0, -3), weapon]]
	for i in range(allies):
		specs.append(["test_dummy", 0, Vector2(1.5 + i, -3)])
	for j in range(foes):
		specs.append(["test_dummy", 1, Vector2(-2.0 + j, 3)])
	return _field(specs)


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


func _kinds(evs: Array[Dictionary], dst: BUnit = null) -> Array:
	return evs.filter(func(e: Dictionary) -> bool: return e.get("t") == "damage" and (dst == null or e.get("dst") == dst)) \
		.map(func(e: Dictionary) -> String: return str(e["kind"]))


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
		t.ok(not models.has(e.model), "%s: look not shared with another gen15 weapon" % id)
		models[e.model] = true
		t.eq(e.projectile, str(s[4]), "%s shoots %s" % [id, str(s[4]) if str(s[4]) != "" else "its class's default projectile"])
		if e.projectile != "":
			t.ok(ProjRegistry.has(e.projectile), "%s: projectile %s is registered (proj_kinds/gen15.gd)" % [id, e.projectile])
		for a: AbilityDef in e.abilities:
			t.ok(a.required_trigger_tags.has("equipment_payload"), "%s/%s pairs with weapon triggers" % [id, a.id])
	# 外观全局唯一：别的武器(专武、其他批)没有用同一个外观名
	for oid: String in cat.equipment.keys():
		var o: EquipmentDef = cat.get_equipment(oid)
		if not SLOTS.has(oid) and o.model != "" and models.has(o.model):
			t.ok(false, "look %s is also used by %s" % [o.model, oid])
	# 近战(双匕)的刀光登记在 proj_kinds/gen15.gd 的 TRAILS
	for did: String in ["g15_heartfire_daggers", "g15_bat_daggers"]:
		t.ok(not ProjRegistry.trail(_eq(did).model).is_empty(), "%s has a weapon trail" % did)
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
	for wid2: String in NOT_FIT.keys():
		for uid2: String in NOT_FIT[wid2]:
			t.ok(not cat.fit_units(wid2).has(uid2), "%s: %s is removed from the fits (measured +0)" % [wid2, uid2])


## 描述里的数值和数据一致(百分比按 ×100 写)
func test_text_numbers(t: TestCtx) -> void:
	var cac: EquipmentDef = _eq("g15_cactus_revolvers")
	var coat: Dictionary = _branch("g15_cactus_revolvers", 0, "ally_effect")["cfg"]
	var prick: Dictionary = (coat["pairs"] as Array)[0]["ability"]
	var box: EquipmentDef = _eq("g15_boxing_pistols")
	var spirit: Dictionary = _branch("g15_boxing_pistols", 0, "ally_effect")["cfg"]
	var mag: EquipmentDef = _eq("g15_magnet_pistols")
	var magz: Dictionary = _branch("g15_magnet_pistols", 0, "enemy_effect")["cfg"]
	var fly: EquipmentDef = _eq("g15_mint_crossbow")
	var glow: Dictionary = _branch("g15_mint_crossbow", 0, "ally_effect")["cfg"]
	var daze: Dictionary = _branch("g15_mint_crossbow", 0, "enemy_effect")["cfg"]
	var heart: EquipmentDef = _eq("g15_heartfire_daggers")
	var hf: Dictionary = _branch("g15_heartfire_daggers", 0, "ally_effect")["cfg"]
	var bat: EquipmentDef = _eq("g15_bat_daggers")
	var swarm: Dictionary = _branch("g15_bat_daggers", 0, "ally_effect")["cfg"]
	var nums := {
		"g15_cactus_revolvers": [cac.flat_mods["max_health"], cac.flat_mods["defense"], cac.flat_mods["reload_time_pct"] * -100.0, cac.abilities[0].fixed_value,
			coat["duration"], coat["stats"]["defense"]["flat"], coat["stats"]["health_regen_per_second"]["flat"], prick["fixed_value"],
			cac.abilities[0].keyword_values["splash"] * 1.2, _cfg("g15_cactus_revolvers", 1)["duration"]],
		"g15_boxing_pistols": [box.flat_mods["attack_power"], box.pct_mods["attack_speed_multiplier"] * 100.0, box.abilities[0].fixed_value, spirit["duration"],
			spirit["stats"]["omnivamp"]["flat"] * 100.0, spirit["stats"]["attack_power"]["pct"] * 100.0, _cfg("g15_boxing_pistols", 1)["duration"],
			box.abilities[2].cooldown, _branch("g15_boxing_pistols", 2, "ally_effect")["value_multiplier"] * 100.0],
		"g15_magnet_pistols": [mag.flat_mods["attack_power"], mag.flat_mods["max_health"], mag.abilities[0].keyword_values["multi_attack"], mag.abilities[0].fixed_value,
			magz["duration"], magz["max_stacks"], magz["stats"]["attack_speed_multiplier"]["flat"] * -100.0, magz["stats"]["defense"]["flat"] * -1.0,
			mag.abilities[1].cooldown, _branch("g15_magnet_pistols", 1, "ally_effect")["value_multiplier"] * 100.0,
			_branch("g15_magnet_pistols", 1, "enemy_effect")["cfg"]["taunt"]],
		"g15_mint_crossbow": [fly.flat_mods["max_health"], fly.flat_mods["attack_power"], glow["max_stacks"], glow["stats"]["health_regen_per_second"]["flat"],
			glow["stats"]["healing_received_pct"]["flat"] * 100.0, daze["duration"], daze["stats"]["damage_dealt_pct"]["flat"] * -100.0,
			fly.abilities[0].keyword_values["splash"] * 1.2, fly.abilities[1].fixed_value],
		"g15_heartfire_daggers": [heart.flat_mods["attack_power"], heart.flat_mods["max_health"], heart.abilities[0].keyword_values["multi_attack"], hf["duration"],
			hf["stats"]["damage_taken_pct"]["flat"] * -100.0, hf["stats"]["health_regen_per_second"]["flat"],
			_branch("g15_heartfire_daggers", 0, "enemy_effect")["value_multiplier"] * 100.0, heart.abilities[1].cooldown,
			(_cfg("g15_heartfire_daggers", 1)["pre_effects"] as Array)[0]["fixed_value"], _branch("g15_heartfire_daggers", 1, "ally_effect")["value_multiplier"] * 100.0],
		"g15_bat_daggers": [bat.flat_mods["attack_power"], bat.flat_mods["physical_lifesteal"] * 100.0, bat.abilities[0].cooldown, bat.abilities[0].value_multiplier * 100.0,
			swarm["max_stacks"], swarm["stats"]["physical_lifesteal"]["flat"] * 100.0, swarm["stats"]["attack_power"]["pct"] * 100.0, _cfg("g15_bat_daggers", 1)["duration"]],
	}
	for id: String in nums.keys():
		for lang: String in ["zh", "en"]:
			var desc: String = Loc.t_in(lang, "equipment.%s.desc" % id)
			for n: Variant in nums[id]:
				var s: String = str(int(round(float(n)))) if absf(float(n) - round(float(n))) < 0.001 else str(snappedf(float(n), 0.01))
				t.ok(desc.contains(s), "%s (%s): the text says %s" % [id, lang, s])
	for sid: String in ["g15_spine_coat", "g15_fighting_spirit", "g15_magnetized", "g15_mint_cool", "g15_mint_sting", "g15_heartfire", "g15_bat_swarm"]:
		for lang2: String in ["zh", "en"]:
			t.ok(Loc.t_in(lang2, "status." + sid) != "status." + sid, "status %s has a %s name" % [sid, lang2])
			t.ok(Loc.t_in(lang2, "status.%s.desc" % sid) != "status.%s.desc" % sid, "status %s has a %s description" % [sid, lang2])


# ================================================================ 仙人掌双枪
func test_cactus_revolvers(t: TestCtx) -> void:
	# 携带者 + 队友(一个贴着、一个远远的) + 敌人(一个主目标、一个贴着它、一个远远的；还有一个会出手的打手)
	var b := _field([["test_hitter", 0, Vector2(0, -3), "g15_cactus_revolvers"], ["test_dummy", 0, Vector2(1.0, -3)], ["test_dummy", 0, Vector2(8.0, -3)],
		["test_dummy", 1, Vector2(0, 3)], ["test_dummy", 1, Vector2(1.0, 3)], ["test_dummy", 1, Vector2(8.0, 3)], ["test_hitter", 1, Vector2(1.0, -2)]])
	var u: BUnit = b.units[0]
	var near_ally: BUnit = b.units[1]
	var far_ally: BUnit = b.units[2]
	var foe: BUnit = b.units[3]
	var near_foe: BUnit = b.units[4]
	var far_foe: BUnit = b.units[5]
	var brute: BUnit = b.units[6]
	var e: EquipmentDef = _eq("g15_cactus_revolvers")
	var hit: float = e.abilities[0].fixed_value
	var coat: Dictionary = e.abilities[0].effect_config["ally_effect"]["cfg"]
	var prick: float = float((coat["pairs"] as Array)[0]["ability"]["fixed_value"])
	var stun: float = float(e.abilities[1].effect_config["duration"])
	# 敌人：固定物理伤害(溅给它身边的敌人) + 眩晕(只有主目标)
	var evs: Array[Dictionary] = _pull(b, u, foe, 999.0)
	t.near(_sum(evs, "damage", foe), hit, hit * 0.05, "an enemy takes a fixed %.0f physical (whatever the trigger value)" % hit)
	t.ok(_kinds(evs, foe).all(func(k: String) -> bool: return k == "physical"), "physical damage")
	t.near(_sum(evs, "damage", near_foe), hit, hit * 0.05, "Splash: so does the enemy next to it")
	t.eq(_sum(evs, "damage", far_foe), 0.0, "but not one far away")
	t.ok(foe.is_stunned(), "the target is stunned")
	t.near(_expires_in(b, foe, "stun"), stun, 0.01, "for %.1f s" % stun)
	t.ok(not near_foe.is_stunned(), "the stun doesn't splash")
	t.ok(foe.get_status("g15_spine_coat") == null, "enemies get no Spine Coat")
	t.eq(_sum(evs, "damage", near_ally) + _sum(evs, "damage", u), 0.0, "no damage to our side")
	# 【基本】：连扣都生效
	var hp0: float = near_foe.hp
	_pull_noclear(b, u, foe, 1.0)
	t.near(hp0 - near_foe.hp, hit, hit * 0.05, "【Basic】: lands on every pull")
	# 队友：【刺甲】(护甲 + 每秒回复)，也给它身边的队友
	var def0: float = near_ally.get_stats().defense
	evs = _pull(b, u, near_ally, 999.0)
	t.ok(near_ally.get_status("g15_spine_coat") != null, "an ally dons a Spine Coat")
	t.ok(u.get_status("g15_spine_coat") != null, "Splash: so does the holder standing next to it")
	t.ok(far_ally.get_status("g15_spine_coat") == null, "but not an ally far away")
	t.near(near_ally.get_stats().defense, def0 + float(coat["stats"]["defense"]["flat"]), 0.01, "more armor")
	t.near(near_ally.get_stats().health_regen_per_second, float(coat["stats"]["health_regen_per_second"]["flat"]), 0.01, "regenerates health")
	t.near(_expires_in(b, near_ally, "g15_spine_coat"), float(coat["duration"]), 0.01, "for %.0f s" % float(coat["duration"]))
	t.eq(_sum(evs, "damage", near_ally), 0.0, "allies aren't hurt")
	t.ok(not near_ally.is_stunned(), "allies aren't stunned")
	# 刺甲：挨了普攻就扎回去
	b.poll_events()
	b.pipeline.normal_attack(brute, near_ally)
	b.pipeline.drain()
	evs = b.poll_events()
	t.near(_sum(evs, "damage", brute), prick, prick * 0.05, "a normal attack on a Spine Coat pricks the attacker for %.0f" % prick)
	t.ok(_kinds(evs, brute).all(func(k: String) -> bool: return k == "physical"), "physical")
	b.poll_events()
	b.pipeline.normal_attack(brute, far_ally)
	b.pipeline.drain()
	evs = b.poll_events()
	t.eq(_sum(evs, "damage", brute), 0.0, "no Spine Coat, no prick")


# ================================================================ 拳套弹簧枪
func test_boxing_pistols(t: TestCtx) -> void:
	var b := _crowd("g15_boxing_pistols", 1, 2)
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("g15_boxing_pistols")
	var jab: float = e.abilities[0].fixed_value
	var spirit: Dictionary = e.abilities[0].effect_config["ally_effect"]["cfg"]
	var stun: float = float(e.abilities[1].effect_config["duration"])
	var r: float = float(e.abilities[2].effect_config["ally_effect"]["value_multiplier"])
	# 敌人：固定物理伤害 + 眩晕
	var evs: Array[Dictionary] = _pull(b, u, foe, 999.0)
	t.near(_sum(evs, "damage", foe), jab, jab * 0.05, "an enemy takes a fixed %.0f physical" % jab)
	t.ok(_kinds(evs, foe).all(func(k: String) -> bool: return k == "physical"), "physical damage")
	t.ok(foe.is_stunned(), "and is stunned (seeing stars)")
	t.near(_expires_in(b, foe, "stun"), stun, 0.01, "for %.1f s" % stun)
	t.ok(foe.get_status("g15_fighting_spirit") == null, "enemies get no Fighting Spirit")
	# 【基本】：连扣都生效
	var hp0: float = foe.hp
	_pull_noclear(b, u, foe, 1.0)
	t.near(hp0 - foe.hp, jab, jab * 0.05, "【Basic】: the jab lands on every pull")
	# 队友：【斗魂】(全能吸血 + 攻击力) + 回复 触发数值 × r(冷却)
	ally.hp = 100.0
	var atk0: float = ally.get_stats().attack_power
	evs = _pull(b, u, ally, 200.0)
	var hb: float = 1.0 + u.get_stats().healing_done_pct
	t.near(_sum(evs, "heal", ally), 200.0 * r * hb, 1.0, "an ally heals trigger value × %.0f%%" % (r * 100.0))
	t.ok(ally.get_status("g15_fighting_spirit") != null, "and gains Fighting Spirit")
	t.near(ally.get_stats().omnivamp, float(spirit["stats"]["omnivamp"]["flat"]), 0.001, "omnivamp")
	t.near(ally.get_stats().attack_power, atk0 * (1.0 + float(spirit["stats"]["attack_power"]["pct"])), 0.5, "more attack")
	t.near(_expires_in(b, ally, "g15_fighting_spirit"), float(spirit["duration"]), 0.01, "for %.0f s" % float(spirit["duration"]))
	t.eq(_sum(evs, "damage", ally), 0.0, "allies aren't hurt")
	t.ok(not ally.is_stunned(), "allies aren't stunned")
	ally.hp = 100.0
	evs = _pull_noclear(b, u, ally, 200.0)
	t.eq(_sum(evs, "heal", ally), 0.0, "the heal has a %.0f s cooldown" % e.abilities[2].cooldown)


# ================================================================ 磁极双枪
func test_magnet_pistols(t: TestCtx) -> void:
	var b := _field([["test_hitter", 0, Vector2(0, -3), "g15_magnet_pistols"], ["test_dummy", 0, Vector2(1.5, -3)], ["test_dummy", 0, Vector2(2.5, -3)],
		["test_dummy", 1, Vector2(0, 3)], ["test_dummy", 1, Vector2(1.0, 3)], ["test_dummy", 1, Vector2(2.0, 3)]])
	var u: BUnit = b.units[0]
	var e: EquipmentDef = _eq("g15_magnet_pistols")
	var ma: int = int(e.abilities[0].keyword_values["multi_attack"])
	var sh: float = e.abilities[0].fixed_value
	var magz: Dictionary = e.abilities[0].effect_config["enemy_effect"]["cfg"]
	var r: float = float(e.abilities[1].effect_config["ally_effect"]["value_multiplier"])
	var taunt: float = float(e.abilities[1].effect_config["enemy_effect"]["cfg"]["taunt"])
	# 队友(含自己)：【群攻】个人各拿 固定护盾 + 触发数值 × r 护盾
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_allies", "ally", 100.0)
	var shielded := 0
	for a: BUnit in b.units:
		if a.team == u.team and a.shield > 0.0:
			shielded += 1
			t.near(a.shield, sh + 100.0 * r, 0.5, "an ally gains %.0f + trigger value × %.0f%% shield" % [sh, r * 100.0])
		t.eq(_sum(evs, "damage", a), 0.0, "allies aren't hurt")
		t.ok(a.get_status("g15_magnetized") == null, "allies aren't magnetized")
	t.eq(shielded, ma, "Multi Attack %d: %d allies shielded" % [ma, ma])
	# 【基本】：固定护盾连扣都有，放大的那段有冷却
	var s0: float = u.shield
	_pull_rule(b, u, "self", "ally", 100.0, false)
	t.near(u.shield - s0, sh, 0.5, "【Basic】: the fixed shield lands on every pull; the scaled one has a %.0f s cooldown" % e.abilities[1].cooldown)
	# 敌人：【磁化】(攻速 / 护甲降低) + 被吸到携带者面前、嘲讽
	var foes: Array[BUnit] = _foes(b, u)
	var fas0: float = foes[0].get_stats().attack_speed_multiplier
	var fdef0: float = foes[0].get_stats().defense
	var d0: Array = foes.map(func(f: BUnit) -> float: return f.pos.distance_to(u.pos))
	evs = _pull_rule(b, u, "all_enemies", "enemy", 100.0)
	for _i in range(20):
		b.step()                                   # 吸过来要飞一小会儿
	var mag_n := 0
	var pulled := 0
	for i in range(foes.size()):
		var f: BUnit = foes[i]
		t.eq(_sum(evs, "damage", f), 0.0, "no damage")
		if f.get_status("g15_magnetized") != null:
			mag_n += 1
			t.near(f.get_stats().attack_speed_multiplier, fas0 + float(magz["stats"]["attack_speed_multiplier"]["flat"]), 0.001, "Magnetized: slower attacks")
			t.near(f.get_stats().defense, fdef0 + float(magz["stats"]["defense"]["flat"]), 0.01, "and less armor")
		if f.pos.distance_to(u.pos) < float(d0[i]) - 1.0:
			pulled += 1
			t.ok(f.forced_target == u, "a pulled enemy is taunted by the holder")
			t.ok(f.forced_until > b.time + taunt - 1.0, "for about %.0f s" % taunt)
	t.eq(mag_n, ma, "Multi Attack %d: %d enemies magnetized" % [ma, ma])
	t.eq(pulled, ma, "and pulled in")


# ================================================================ 薄荷手弩
func test_mint_crossbow(t: TestCtx) -> void:
	var b := _field([["test_hitter", 0, Vector2(0, -3), "g15_mint_crossbow"], ["test_dummy", 0, Vector2(1.0, -3)], ["test_dummy", 0, Vector2(8.0, -3)],
		["test_dummy", 1, Vector2(0, 3)], ["test_dummy", 1, Vector2(1.0, 3)], ["test_dummy", 1, Vector2(8.0, 3)]])
	var u: BUnit = b.units[0]
	var near_ally: BUnit = b.units[1]
	var far_ally: BUnit = b.units[2]
	var foe: BUnit = b.units[3]
	var near_foe: BUnit = b.units[4]
	var far_foe: BUnit = b.units[5]
	var e: EquipmentDef = _eq("g15_mint_crossbow")
	var glow: Dictionary = e.abilities[0].effect_config["ally_effect"]["cfg"]
	var daze: Dictionary = e.abilities[0].effect_config["enemy_effect"]["cfg"]
	var spark: float = e.abilities[1].fixed_value
	# 队友：1 层【清凉】(本场，叠加)，也给它身边的队友；回复固定值
	near_ally.hp = 100.0
	var evs: Array[Dictionary] = _pull(b, u, near_ally, 999.0)
	var hb: float = 1.0 + u.get_stats().healing_done_pct
	t.eq(near_ally.status_stacks("g15_mint_cool"), 1, "an ally gains a stack of Cool Mint")
	t.eq(u.status_stacks("g15_mint_cool"), 1, "Splash: so does the holder standing next to it")
	t.eq(far_ally.status_stacks("g15_mint_cool"), 0, "but not an ally far away")
	t.ok(near_ally.get_status("g15_mint_cool").expires_at < 0.0, "Cool Mint lasts the battle")
	t.near(near_ally.get_stats().health_regen_per_second, float(glow["stats"]["health_regen_per_second"]["flat"]), 0.01, "regenerates health")
	t.near(near_ally.get_stats().healing_received_pct, float(glow["stats"]["healing_received_pct"]["flat"]), 0.001, "receives more healing")
	t.ok(_sum(evs, "heal", near_ally) >= spark * hb - 1.0, "and heals a fixed %.0f" % spark)
	t.eq(_sum(evs, "damage", near_ally), 0.0, "allies aren't hurt")
	for i in range(int(glow["max_stacks"]) + 2):
		_pull_noclear(b, u, near_ally, 1.0)
	t.eq(near_ally.status_stacks("g15_mint_cool"), int(glow["max_stacks"]), "【Basic】: stacks on every pull, up to %d" % int(glow["max_stacks"]))
	t.near(near_ally.get_stats().health_regen_per_second, float(glow["stats"]["health_regen_per_second"]["flat"]) * float(glow["max_stacks"]), 0.01, "regen per stack")
	# 敌人：【呛眼】(造成的伤害降低)，也给它身边的敌人；固定魔法伤害
	evs = _pull(b, u, foe, 999.0)
	t.near(_sum(evs, "damage", foe), spark, spark * 0.05, "an enemy takes a fixed %.0f magic" % spark)
	t.ok(_kinds(evs, foe).all(func(k: String) -> bool: return k == "magic"), "magic damage")
	t.ok(foe.get_status("g15_mint_sting") != null and near_foe.get_status("g15_mint_sting") != null, "the enemy and the one next to it are dazed")
	t.ok(far_foe.get_status("g15_mint_sting") == null, "but not one far away")
	t.near(foe.get_stats().damage_dealt_pct, float(daze["stats"]["damage_dealt_pct"]["flat"]), 0.001, "deals less damage")
	t.near(_expires_in(b, foe, "g15_mint_sting"), float(daze["duration"]), 0.01, "for %.0f s" % float(daze["duration"]))
	t.eq(foe.status_stacks("g15_mint_cool"), 0, "enemies get no Cool Mint")


# ================================================================ 心火双刃
func test_heartfire_daggers(t: TestCtx) -> void:
	var b := _crowd("g15_heartfire_daggers", 4, 4)
	var u: BUnit = b.units[0]
	var e: EquipmentDef = _eq("g15_heartfire_daggers")
	var ma: int = int(e.abilities[0].keyword_values["multi_attack"])
	var hf: Dictionary = e.abilities[0].effect_config["ally_effect"]["cfg"]
	var r: float = float(e.abilities[0].effect_config["enemy_effect"]["value_multiplier"])
	var self_heal: float = float((e.abilities[1].effect_config["pre_effects"] as Array)[0]["fixed_value"])
	var s: float = float(e.abilities[1].effect_config["ally_effect"]["value_multiplier"])
	var hb: float = 1.0 + u.get_stats().healing_done_pct
	# 队友：【群攻】个人【心火】+ 回复 触发数值 × s；携带者先回复固定值(就算快倒下了)
	for a: BUnit in _allies(b, u):
		a.hp = 100.0
	u.hp = 5.0
	var dr0: float = _allies(b, u)[0].get_stats().damage_taken_pct
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_allies_except_self", "ally", 100.0)
	t.near(_sum(evs, "heal", u), self_heal * hb, 1.0, "the holder first heals a fixed %.0f" % self_heal)
	var warm := 0
	var healed := 0
	for a2: BUnit in _allies(b, u):
		if a2.get_status("g15_heartfire") != null:
			warm += 1
			t.near(a2.get_stats().damage_taken_pct, dr0 + float(hf["stats"]["damage_taken_pct"]["flat"]), 0.001, "Heartfire: less damage taken")
			t.near(a2.get_stats().health_regen_per_second, float(hf["stats"]["health_regen_per_second"]["flat"]), 0.01, "and regenerates health")
			t.near(_expires_in(b, a2, "g15_heartfire"), float(hf["duration"]), 0.01, "for %.0f s" % float(hf["duration"]))
		if _sum(evs, "heal", a2) > 0.0:
			healed += 1
			t.near(_sum(evs, "heal", a2), 100.0 * s * hb, 1.0, "an ally heals trigger value × %.0f%%" % (s * 100.0))
		t.eq(_sum(evs, "damage", a2), 0.0, "allies aren't hurt")
	t.eq(warm, ma, "Multi Attack %d: %d allies warmed" % [ma, ma])
	t.eq(healed, ma, "and healed")
	# 【基本】：心火连扣都有；回复(和携带者的那一口)有冷却
	u.hp = 5.0
	evs = _pull_rule(b, u, "all_allies_except_self", "ally", 100.0, false)
	t.eq(_sum(evs, "heal", u), 0.0, "the self-heal has a %.0f s cooldown" % e.abilities[1].cooldown)
	# 敌人：【群攻】个人受到 触发数值 × r 物理伤害；不给心火
	evs = _pull_rule(b, u, "all_enemies", "enemy", 100.0, false)
	var hit := 0
	for f: BUnit in _foes(b, u):
		var d: float = _sum(evs, "damage", f)
		if d > 0.0:
			hit += 1
			t.near(d, 100.0 * r, 100.0 * r * 0.05, "an enemy takes trigger value × %.0f%% physical" % (r * 100.0))
		t.ok(f.get_status("g15_heartfire") == null, "enemies get no Heartfire")
	t.eq(hit, ma, "Multi Attack %d: %d enemies hit" % [ma, ma])
	t.ok(_kinds(evs).all(func(k: String) -> bool: return k == "physical"), "physical damage")


# ================================================================ 蝙蝠双刃
func test_bat_daggers(t: TestCtx) -> void:
	var b := _crowd("g15_bat_daggers", 1, 2)
	var u: BUnit = b.units[0]
	var e: EquipmentDef = _eq("g15_bat_daggers")
	var r: float = e.abilities[0].value_multiplier
	var swarm: Dictionary = e.abilities[0].effect_config["ally_effect"]["cfg"]
	var stun: float = float(e.abilities[1].effect_config["duration"])
	var foe: BUnit = _foes(b, u)[0]
	# 敌人：触发数值 × r 魔法伤害 + 携带者回复同样多 + 眩晕
	u.hp = 1000.0
	var evs: Array[Dictionary] = _pull(b, u, foe, 400.0)
	var hb: float = 1.0 + u.get_stats().healing_done_pct
	t.near(_sum(evs, "damage", foe), 400.0 * r, 400.0 * r * 0.05, "an enemy takes trigger value × %.0f%% magic" % (r * 100.0))
	t.ok(_kinds(evs, foe).all(func(k: String) -> bool: return k == "magic"), "magic damage")
	t.ok(_sum(evs, "heal", u) >= 400.0 * r * hb - 1.0, "the holder drinks it back (heals as much)")
	t.ok(foe.is_stunned(), "the enemy is stunned by the shriek")
	t.near(_expires_in(b, foe, "stun"), stun, 0.01, "for %.1f s" % stun)
	t.eq(foe.status_stacks("g15_bat_swarm"), 0, "enemies get no Bat Swarm")
	# 冷却
	var hp0: float = foe.hp
	_pull_noclear(b, u, foe, 400.0)
	t.near(foe.hp, hp0, 0.01, "%.0f s cooldown" % e.abilities[0].cooldown)
	# 队友(含自己)：1 层【蝠群】(本场，叠加)
	var ls0: float = u.get_stats().physical_lifesteal
	var atk0: float = u.get_stats().attack_power
	evs = _pull(b, u, u, 36.0)
	t.eq(u.status_stacks("g15_bat_swarm"), 1, "self: a stack of Bat Swarm")
	t.ok(u.get_status("g15_bat_swarm").expires_at < 0.0, "lasts the battle")
	t.near(u.get_stats().physical_lifesteal, ls0 + float(swarm["stats"]["physical_lifesteal"]["flat"]), 0.001, "more lifesteal")
	t.ok(u.get_stats().attack_power > atk0, "more attack")
	t.ok(not u.is_stunned(), "the holder isn't stunned")
	t.eq(_sum(evs, "damage", u), 0.0, "and isn't hurt")
	for i in range(int(swarm["max_stacks"]) + 2):
		_pull(b, u, u, 36.0)
	t.eq(u.status_stacks("g15_bat_swarm"), int(swarm["max_stacks"]), "Bat Swarm stacks to %d" % int(swarm["max_stacks"]))
