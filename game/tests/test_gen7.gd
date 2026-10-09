extends RefCounted
## 通用武器 · gen7(近战 6 把)：彩绸双刃 / 雾隐双刃(双匕)、鎏金军刀 / 裁誓仪剑(单手剑)、雷鸣巨剑 / 蚀骨巨剑(双手剑)。
## 每把用一个"探针触发器"(目标 = 事件目标 / 指定规则、固定触发数值)直接扣动载荷验证效果；再查数据(格子、外观、随机池)和适配角色。

## 武器 -> [费用, 颜色, 大类, 外观]
const SLOTS := {
	"ribbon_daggers": [2, "yellow", "dual", "g7_ribbon"],
	"mistveil_daggers": [3, "cyan", "dual", "g7_mistveil"],
	"gilded_saber": [4, "yellow", "sword", "g7_gilded"],
	"verdict_sword": [2, "purple", "sword", "g7_verdict"],
	"thunder_greatsword": [3, "yellow", "heavy", "g7_thunder"],
	"blight_greatsword": [4, "green", "heavy", "g7_blight"],
}
## 合手的棋子(测强度定下的)：都要在适配角色里，并且 1~3 星都装得上
const CARRIERS := {
	"ribbon_daggers": ["node_dancer", "node_berserker"],
	"mistveil_daggers": ["node_knight_errant", "node_hunter"],
	"gilded_saber": ["node_noble", "node_samurai"],
	"verdict_sword": ["node_pacifist", "node_druid"],
	"thunder_greatsword": ["node_cultist", "node_berserker"],
	"blight_greatsword": ["node_killer", "node_samurai"],
}


func _probe(v: float) -> TriggerDef:
	return TriggerDef.from_dict({"id": "probe_trigger_g7", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
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
func _pull_rule(b: Battle, u: BUnit, rule: String, team: String, v: float) -> Array[Dictionary]:
	u.ability_cd.clear()
	u.trig_cd.clear()
	b.poll_events()
	var trig := TriggerDef.from_dict({"id": "probe_trigger_g7_multi", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
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
		t.ok(not models.has(e.model), "%s: look not shared with another gen7 weapon" % id)
		models[e.model] = true
		t.eq(e.projectile, "", "%s is melee: no projectile of its own" % id)
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


# ================================================================ 彩绸双刃
func test_ribbon_daggers(t: TestCtx) -> void:
	var b := _crowd("ribbon_daggers", 4, 4)
	var u: BUnit = b.units[0]
	var cfg: Dictionary = _cfg("ribbon_daggers")
	var ally_cfg: Dictionary = cfg["ally_effect"]["cfg"]
	var per_atk: float = float(ally_cfg["stats"]["attack_power"]["pct"])
	var per_ls: float = float(ally_cfg["stats"]["physical_lifesteal"]["flat"])
	var maxs: int = int(ally_cfg["max_stacks"])
	var r: float = float(cfg["enemy_effect"]["value_multiplier"])
	var allies: Array[BUnit] = _allies(b, u)
	var a0: BUnit = allies[0]
	var atk0: float = a0.get_stats().attack_power
	var ls0: float = a0.get_stats().physical_lifesteal
	# 队友：每扣一次 1 层【喝彩】(【基本】：连扣都生效)，【群攻 4】= 4 个队友都吃到
	_pull_rule(b, u, "all_allies_except_self", "ally", 30.0)
	var cheered := 0
	for a: BUnit in allies:
		if a.status_stacks("ribbon_cheer") == 1:
			cheered += 1
	t.eq(cheered, 4, "Multi Attack 4: all four allies gain a stack of Cheer")
	for i in range(maxs + 2):
		b.poll_events()
		var trig := TriggerDef.from_dict({"id": "probe_g7_ally", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
			"target_rule": "all_allies_except_self", "team_filter": "ally", "base_value_mode": "fixed", "base_value_flat": 30.0})
		b.pipeline._fire(b.pipeline.make_event("OnBattleFrame", u, null, 0.0, ["battle_frame"], {}), trig, u)
		b.pipeline.drain()
	t.eq(a0.status_stacks("ribbon_cheer"), maxs, "【Basic】: no cooldown, stacks to %d" % maxs)
	t.near(a0.get_stats().attack_power, atk0 * (1.0 + float(maxs) * per_atk), 0.5, "+%.0f%% attack a stack" % (per_atk * 100.0))
	t.near(a0.get_stats().physical_lifesteal, ls0 + float(maxs) * per_ls, 0.001, "and +%.0f%% physical lifesteal a stack" % (per_ls * 100.0))
	t.eq(_sum(b.poll_events(), "damage", a0), 0.0, "allies aren't hurt")
	# 敌人：触发数值 × r 物理伤害，最多 4 个
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_enemies", "enemy", 400.0)
	var hit := 0
	for f: BUnit in _foes(b, u):
		var d: float = _sum(evs, "damage", f)
		if d > 0.0:
			hit += 1
			t.near(d, 400.0 * r, 400.0 * r * 0.05, "an enemy takes value × %.0f%% physical" % (r * 100.0))
		t.eq(f.status_stacks("ribbon_cheer"), 0, "enemies don't get Cheer")
	t.eq(hit, 4, "four enemies hit")
	var kinds: Array = evs.filter(func(e: Dictionary) -> bool: return e.get("t") == "damage").map(func(e: Dictionary) -> String: return str(e["kind"]))
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "physical"), "physical damage")
	t.near(u.get_stats().physical_lifesteal, float(_eq("ribbon_daggers").flat_mods["physical_lifesteal"]), 0.001, "the holder has the weapon's lifesteal")


# ================================================================ 雾隐双刃
func test_mistveil_daggers(t: TestCtx) -> void:
	var b := _crowd("mistveil_daggers", 1, 1)
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var cfg: Dictionary = _cfg("mistveil_daggers")
	var pre: Dictionary = (cfg["pre_effects"] as Array)[0]
	var dg: float = float(pre["stats"]["na_dodge"]["flat"])
	var asb: float = float(pre["stats"]["attack_speed_multiplier"]["flat"])
	var atkp: float = float(pre["stats"]["attack_power"]["pct"])
	var s: float = float(cfg["ally_effect"]["value_multiplier"])
	var r: float = float(cfg["enemy_effect"]["value_multiplier"])
	t.near(u.get_stats().na_dodge, float(_eq("mistveil_daggers").flat_mods["na_dodge"]), 0.001, "the holder dodges normal attacks more often")
	# 打敌人(追猎)：携带者照样获得【雾隐】，敌人受到 触发数值 × r 物理伤害
	var d0: float = u.get_stats().na_dodge
	var as0: float = u.get_stats().attack_speed_multiplier
	var atk0: float = u.get_stats().attack_power
	var evs: Array[Dictionary] = _pull(b, u, foe, 150.0)
	t.near(_sum(evs, "damage", foe), 150.0 * r, 150.0 * r * 0.05, "an enemy takes value × %.0f%% physical" % (r * 100.0))
	t.ok(u.get_status("mistveil") != null, "the holder gains Mistveil whoever the target is")
	t.ok(foe.get_status("mistveil") == null and ally.get_status("mistveil") == null, "only the holder")
	t.near(u.get_stats().na_dodge, d0 + dg, 0.001, "+%.0f%% dodge" % (dg * 100.0))
	var aspct: float = 1.0 + float(_eq("mistveil_daggers").pct_mods.get("attack_speed_multiplier", 0.0))
	t.near(u.get_stats().attack_speed_multiplier, as0 + asb * aspct, 0.001, "+%.0f%% attack speed" % (asb * 100.0))
	t.near(u.get_stats().attack_power, atk0 * (1.0 + atkp), 0.5, "+%.0f%% attack" % (atkp * 100.0))
	t.ok(absf(float(u.get_status("mistveil").expires_at) - b.time - float(pre["duration"])) < 0.01, "lasts %.0f s" % float(pre["duration"]))
	# 冷却 2 秒
	evs = _pull_noclear(b, u, foe, 150.0)
	t.eq(_sum(evs, "damage", foe), 0.0, "2 s cooldown")
	# 打自己 / 队友(踏影 / 巧运)：触发数值 × s 的护盾
	evs = _pull(b, u, u, 152.0)
	t.near(u.shield, 152.0 * s, 152.0 * s * 0.05 + 0.5, "self: a shield of value × %.0f%%" % (s * 100.0))
	_pull(b, u, ally, 100.0)
	t.near(ally.shield, 100.0 * s, 100.0 * s * 0.05 + 0.5, "an ally: a shield too")
	t.eq(_sum(evs, "damage", u), 0.0, "and no damage to the holder")


# ================================================================ 鎏金军刀
func test_gilded_saber(t: TestCtx) -> void:
	var b := _crowd("gilded_saber", 0, 1)
	var u: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	var a: AbilityDef = _eq("gilded_saber").abilities[0]
	var ex: Dictionary = (a.effect_config["extra_effects"] as Array)[0]
	var per: float = float(ex["stats"]["attack_speed_multiplier"]["flat"])
	var maxs: int = int(ex["max_stacks"])
	var as0: float = u.get_stats().attack_speed_multiplier
	var evs: Array[Dictionary] = _pull(b, u, foe, 999.0)
	t.near(_sum(evs, "damage", foe), a.fixed_value, a.fixed_value * 0.05, "fixed %.0f physical, whatever the trigger value" % a.fixed_value)
	t.eq(u.status_stacks("saber_momentum"), 1, "the holder gains a stack of Momentum")
	t.eq(foe.status_stacks("saber_momentum"), 0, "the target doesn't")
	var total := 0.0
	for i in range(maxs + 3):
		total += _sum(_pull_noclear(b, u, foe, 1.0), "damage", foe)
	t.ok(total >= a.fixed_value * float(maxs + 3) * 0.95, "【Basic】: every pull hits, no cooldown")
	t.eq(u.status_stacks("saber_momentum"), maxs, "Momentum stacks to %d" % maxs)
	t.near(u.get_stats().attack_speed_multiplier, as0 + float(maxs) * per, 0.001, "+%.0f%% attack speed a stack" % (per * 100.0))


# ================================================================ 裁誓仪剑
func test_verdict_sword(t: TestCtx) -> void:
	var b := _crowd("verdict_sword", 3, 4)
	var u: BUnit = b.units[0]
	var cfg: Dictionary = _cfg("verdict_sword")
	var dr: float = float(cfg["ally_effect"]["cfg"]["stats"]["damage_taken_pct"]["flat"])
	var amp: float = float(cfg["enemy_effect"]["cfg"]["stats"]["damage_taken_amp"]["flat"])
	# 队友：【庇誓】(受到的伤害降低)，不吃触发数值
	var a0: BUnit = _allies(b, u)[0]
	var dr0: float = a0.get_stats().damage_taken_pct
	_pull_rule(b, u, "all_allies", "ally", 1.0)
	var warded := 0
	for a: BUnit in b.units:
		if a.team == u.team and a.get_status("verdict_ward") != null:
			warded += 1
	t.eq(warded, 3, "Multi Attack 3: three allies (self included) gain Sworn Ward")
	t.near(a0.get_stats().damage_taken_pct, dr0 + dr, 0.001, "-%.0f%% damage taken" % (dr * 100.0))
	# 敌人：【判罪】(受到的伤害提高)，最多 3 个
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_enemies", "enemy", 1.0)
	var marked: Array[BUnit] = []
	for f: BUnit in _foes(b, u):
		if f.get_status("verdict_mark") != null:
			marked.append(f)
		t.eq(_sum(evs, "damage", f), 0.0, "no damage of its own")
	t.eq(marked.size(), 3, "Multi Attack 3: three enemies are Condemned")
	t.near(marked[0].get_stats().damage_taken_amp, amp, 0.001, "+%.0f%% damage taken" % (amp * 100.0))
	t.ok(absf(float(marked[0].get_status("verdict_mark").expires_at) - b.time - float(cfg["enemy_effect"]["cfg"]["duration"])) < 0.01, "lasts %.0f s" % float(cfg["enemy_effect"]["cfg"]["duration"]))
	# 被判罪的敌人吃到的伤害确实变多
	var foe: BUnit = marked[0]
	var clean: BUnit = null
	for f2: BUnit in _foes(b, u):
		if f2.get_status("verdict_mark") == null:
			clean = f2
	var hit_m: float = b.pipeline.fx.damage(u, foe, 100.0, "physical", {"surface": "passive", "ability_id": "probe"})
	var hit_c: float = b.pipeline.fx.damage(u, clean, 100.0, "physical", {"surface": "passive", "ability_id": "probe"})
	t.near(hit_m / maxf(hit_c, 0.001), 1.0 + amp, 0.02, "Condemned: the same hit lands %.0f%% harder" % (amp * 100.0))


# ================================================================ 雷鸣巨剑
func test_thunder_greatsword(t: TestCtx) -> void:
	var b := _crowd("thunder_greatsword", 0, 6)
	var u: BUnit = b.units[0]
	var a: AbilityDef = _eq("thunder_greatsword").abilities[0]
	var ex: Dictionary = (a.effect_config["extra_effects"] as Array)[0]
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_enemies", "enemy", 500.0)
	var hit := 0
	for f: BUnit in _foes(b, u):
		var d: float = _sum(evs, "damage", f)
		if d > 0.0:
			hit += 1
			t.near(d, 500.0 * a.value_multiplier, 500.0 * a.value_multiplier * 0.05, "value × %.0f%% physical" % (a.value_multiplier * 100.0))
			t.ok(f.is_stunned() and f.statuses.has("stun"), "and Stunned (the shared 【Stun】 status)")
			t.ok(absf(float(f.get_status("stun").expires_at) - b.time - float(ex["duration"])) < 0.01, "for %.1f s" % float(ex["duration"]))
		else:
			t.ok(not f.is_stunned(), "an enemy that wasn't hit isn't stunned")
	var ma: int = int(a.keyword_values.get("multi_attack", 1))
	t.eq(hit, ma, "Multi Attack %d: %d of the 6 enemies" % [ma, ma])
	# 冷却 4 秒
	evs = b.poll_events()
	var trig := TriggerDef.from_dict({"id": "probe_g7_cd", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
		"target_rule": "all_enemies", "team_filter": "enemy", "base_value_mode": "fixed", "base_value_flat": 500.0})
	b.pipeline._fire(b.pipeline.make_event("OnBattleFrame", u, null, 0.0, ["battle_frame"], {}), trig, u)
	b.pipeline.drain()
	var again := 0.0
	for f2: BUnit in _foes(b, u):
		again += _sum(b.poll_events(), "damage", f2)
	t.eq(again, 0.0, "4 s cooldown")
	# 眩晕会计入场上被眩晕的总时间(锁芯节点的深空之门按它算)
	var guard := 0
	while b.state != "running" and guard < 2000:
		b.step()
		guard += 1
	_pull_rule(b, u, "all_enemies", "enemy", 500.0)
	var st0: float = b.stun_time
	for i in range(8):
		b.step()
	t.ok(b.stun_time > st0, "stunned enemies count towards the battle's stun time")


# ================================================================ 蚀骨巨剑
func test_blight_greatsword(t: TestCtx) -> void:
	var b := _crowd("blight_greatsword", 0, 1)
	var u: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	var cfg: Dictionary = _cfg("blight_greatsword")
	var maxs: int = int(cfg["max_stacks"])
	var dot: float = float(cfg["dot"]["amount"])
	_pull(b, u, foe, 9999.0)
	t.eq(foe.status_stacks("blight_venom"), 1, "the target gains a stack of Blight (whatever the trigger value)")
	for i in range(maxs + 2):
		_pull_noclear(b, u, foe, 1.0)
	t.eq(foe.status_stacks("blight_venom"), maxs, "【Basic】: every pull adds a stack, up to %d" % maxs)
	t.ok(u.status_stacks("blight_venom") == 0, "not on the holder")
	# 每层每秒 dot 点魔法伤害
	b.poll_events()
	var hp0: float = foe.hp
	var frames: int = int(round(1.0 / GC.SIM_DT))
	for i2 in range(frames):
		b.step()
	var evs: Array[Dictionary] = b.poll_events()
	var ticks: Array = evs.filter(func(e: Dictionary) -> bool: return e.get("t") == "damage" and e.get("dst") == foe and str(e.get("kind", "")) == "magic")
	t.eq(ticks.size(), 1, "one tick a second")
	t.near(hp0 - foe.hp, dot * float(maxs), dot * float(maxs) * 0.05, "%.0f magic damage a stack a second" % dot)
	# 4 秒后掉光(不再续)
	for i3 in range(frames * 4):
		b.step()
	t.eq(foe.status_stacks("blight_venom"), 0, "wears off after 4 s without new stacks")
