extends RefCounted
## 通用武器 · gen16：青玉葫芦 / 三兽图腾 / 萤火虫瓶(法器)、凤首箜篌 / 青鸾长弓(弓)、向日葵步枪(步枪)。
## 每把用一个"探针触发器"(目标 = 事件目标 / 指定规则、固定触发数值)直接扣动载荷验证效果；再查数据(格子、外观、投射物、随机池)、文本里的数值和适配角色。

## 武器 -> [费用, 颜色, 大类, 外观, 投射物]
const SLOTS := {
	"g16_jade_gourd": [2, "green", "focus", "g16_gourd", "g16_elixir"],
	"g16_beast_totem": [4, "green", "focus", "g16_totem", "g16_spirit"],
	"g16_firefly_jar": [2, "yellow", "focus", "g16_firefly", "g16_fireflies"],
	"g16_konghou_bow": [3, "yellow", "bow", "g16_konghou", "g16_note"],
	"g16_luan_bow": [3, "cyan", "bow", "g16_luan", "g16_feather"],
	"g16_sunflower_rifle": [4, "yellow", "rifle", "g16_sunflower", "g16_seed"],
}
## 合手的棋子(测强度定下的)：都要在适配角色里，并且 1~3 星都装得上(青鸾长弓的和星是 fit_add)
const CARRIERS := {
	"g16_jade_gourd": ["node_taoist", "node_warden"],
	"g16_beast_totem": ["node_taoist", "node_warden"],
	"g16_firefly_jar": ["node_absolver", "node_psychic", "node_dancer"],
	"g16_konghou_bow": ["node_bard", "node_hunter", "node_sniper"],
	"g16_luan_bow": ["node_hunter", "node_druid"],
	"g16_sunflower_rifle": ["node_archer", "node_nurse", "node_commando", "node_taoist"],
}


func _probe(v: float) -> TriggerDef:
	return TriggerDef.from_dict({"id": "probe_trigger_g16", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
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
	var trig := TriggerDef.from_dict({"id": "probe_trigger_g16_multi", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
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
	return _start(specs)


func _start(specs: Array) -> Battle:
	var b := Fixture.make(specs)
	b.start()
	for u: BUnit in b.units:
		u.attack_cd = 1.0e9
		u.base.crit_chance = 0.0
		u.mark_dirty()
	return b


func _step_for(b: Battle, sec: float) -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	var until: float = b.time + sec
	while b.time < until and b.state != "ended":
		b.step()
		all.append_array(b.poll_events())
	return all


func _kill(b: Battle, u: BUnit) -> void:
	u.hp = 0.0
	b.pipeline.fx.try_kill(u, null)
	b.pipeline.drain()


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
		t.ok(not models.has(e.model), "%s: look not shared with another gen16 weapon" % id)
		models[e.model] = true
		t.eq(e.projectile, str(s[4]), "%s shoots %s (not its class's default projectile)" % [id, str(s[4])])
		t.ok(ProjRegistry.has(e.projectile), "%s: projectile %s is registered (proj_kinds/gen16.gd)" % [id, e.projectile])
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
	# 测出来不合手的：fit_remove(屏息拿向日葵步枪 +1、护理拿凤首箜篌 +0)
	t.ok(not cat.fit_units("g16_sunflower_rifle").has("node_sniper"), "sunflower rifle: the sniper is removed")
	t.ok(not cat.fit_units("g16_konghou_bow").has("node_nurse"), "konghou bow: the nurse is removed")
	t.ok(cat.fit_units("g16_luan_bow").has("node_leader"), "luan bow: the leader still fits (tags)")
	for wid: String in CARRIERS.keys():
		var fits: Array[String] = cat.fit_units(wid)
		t.ok(fits.size() >= 2, "%s fits %d pieces (%s)" % [wid, fits.size(), ",".join(fits)])
		var e: EquipmentDef = cat.get_equipment(wid)
		for uid: String in CARRIERS[wid]:
			t.ok(fits.has(uid), "%s fits %s" % [wid, uid])
			for star: int in [1, 2, 3]:
				t.eq(e.equip_problem(cat.get_unit(uid), star), "", "%s can be equipped by %s ★%d" % [wid, uid, star])


## 描述里的数值和数据一致(百分比按 ×100 写)
func test_text_numbers(t: TestCtx) -> void:
	var gourd: EquipmentDef = _eq("g16_jade_gourd")
	var drunk: Dictionary = _cfg("g16_jade_gourd", 1)
	var totem: EquipmentDef = _eq("g16_beast_totem")
	var soul: Dictionary = _branch("g16_beast_totem", 1, "ally_effect")["cfg"]
	var awe: Dictionary = _branch("g16_beast_totem", 1, "enemy_effect")["cfg"]
	var jar: EquipmentDef = _eq("g16_firefly_jar")
	var mark: Dictionary = _branch("g16_firefly_jar", 0, "enemy_effect")["cfg"]
	var warm: Dictionary = _branch("g16_firefly_jar", 0, "ally_effect")["cfg"]
	var harp: EquipmentDef = _eq("g16_konghou_bow")
	var conc: Dictionary = _branch("g16_konghou_bow", 1, "ally_effect")["cfg"]
	var disc: Dictionary = _branch("g16_konghou_bow", 1, "enemy_effect")["cfg"]
	var luan: EquipmentDef = _eq("g16_luan_bow")
	var sun: EquipmentDef = _eq("g16_sunflower_rifle")
	var nums := {
		"g16_jade_gourd": [gourd.flat_mods["max_health"], gourd.abilities[0].fixed_value, drunk["duration"],
			gourd.abilities[0].keyword_values.get("splash", 0) * 1.2, drunk["stats"]["attack_power"]["pct"] * -100.0, drunk["stats"]["move_speed"]["pct"] * -100.0],
		"g16_beast_totem": [totem.flat_mods["max_health"], totem.flat_mods["ability_power"], _branch("g16_beast_totem", 0, "ally_effect")["value_multiplier"] * 100.0,
			_cfg("g16_beast_totem", 0)["shield_cap_pct"] * 100.0, _branch("g16_beast_totem", 0, "enemy_effect")["value_multiplier"] * 100.0,
			soul["max_stacks"], soul["stats"]["attack_power"]["pct"] * 100.0, soul["stats"]["damage_taken_pct"]["flat"] * 100.0,
			awe["duration"], awe["stats"]["attack_speed_multiplier"]["flat"] * -100.0],
		"g16_firefly_jar": [jar.flat_mods["attack_power"], jar.flat_mods["max_health"], jar.abilities[0].keyword_values.get("multi_attack", 0),
			mark["duration"], mark["stats"]["damage_taken_amp"]["flat"] * 100.0, warm["stats"]["health_regen_per_second"]["flat"],
			warm["stats"]["damage_taken_pct"]["flat"] * 100.0, jar.abilities[1].fixed_value, jar.abilities[2].cooldown,
			_branch("g16_firefly_jar", 2, "enemy_effect")["value_multiplier"] * 100.0, _branch("g16_firefly_jar", 2, "ally_effect")["value_multiplier"] * 100.0],
		"g16_konghou_bow": [harp.flat_mods["attack_power"], harp.flat_mods["ability_power"], harp.flat_mods["max_health"], harp.abilities[0].cooldown,
			_branch("g16_konghou_bow", 0, "enemy_effect")["value_multiplier"] * 100.0, _branch("g16_konghou_bow", 0, "ally_effect")["value_multiplier"] * 100.0,
			harp.abilities[0].keyword_values.get("splash", 0) * 1.2, conc["duration"], conc["stats"]["attack_power"]["pct"] * 100.0,
			conc["stats"]["ability_power"]["flat"], disc["duration"], disc["stats"]["attack_speed_multiplier"]["flat"] * -100.0],
		"g16_luan_bow": [luan.flat_mods["attack_power"], luan.flat_mods["max_health"], luan.pct_mods["attack_speed_multiplier"] * 100.0,
			luan.abilities[0].cooldown, _branch("g16_luan_bow", 0, "enemy_effect")["value_multiplier"] * 100.0,
			_branch("g16_luan_bow", 0, "ally_effect")["value_multiplier"] * 100.0, luan.abilities[1].fixed_value],
		"g16_sunflower_rifle": [sun.flat_mods["attack_power"], sun.flat_mods["max_health"], sun.pct_mods["attack_speed_multiplier"] * 100.0,
			sun.abilities[0].fixed_value, sun.abilities[1].cooldown, _branch("g16_sunflower_rifle", 1, "enemy_effect")["value_multiplier"] * 100.0,
			_branch("g16_sunflower_rifle", 1, "ally_effect")["value_multiplier"] * 100.0],
	}
	for id: String in nums.keys():
		for lang: String in ["zh", "en"]:
			var desc: String = Loc.t_in(lang, "equipment.%s.desc" % id)
			for n: Variant in nums[id]:
				var s: String = str(int(round(float(n)))) if absf(float(n) - round(float(n))) < 0.001 else str(float(n))
				t.ok(desc.contains(s), "%s (%s): the text says %s" % [id, lang, s])
	for sid: String in ["g16_drunk", "g16_beast_soul", "g16_beast_awe", "g16_firefly_mark", "g16_firefly_warm", "g16_concord", "g16_discord"]:
		for lang2: String in ["zh", "en"]:
			t.ok(Loc.t_in(lang2, "status." + sid) != "status." + sid, "status %s has a %s name" % [sid, lang2])
			t.ok(Loc.t_in(lang2, "status.%s.desc" % sid) != "status.%s.desc" % sid, "status %s has a %s description" % [sid, lang2])


# ================================================================ 青玉葫芦
func test_jade_gourd(t: TestCtx) -> void:
	# 携带者 + 远处的队友 + 主目标敌人 + 贴着它的敌人 + 远远的敌人 + 贴着携带者的队友
	var b := _start([{"def": "test_hitter", "pos": Vector2(0, -3), "weapon": "g16_jade_gourd"}, {"def": "test_dummy", "pos": Vector2(6.0, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.0, 3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(8.0, 3)}, {"def": "test_dummy", "pos": Vector2(1.0, -3)}])
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var near_foe: BUnit = b.units[3]
	var far_foe: BUnit = b.units[4]
	var near_ally: BUnit = b.units[5]
	var e: EquipmentDef = _eq("g16_jade_gourd")
	var pill: float = e.abilities[0].fixed_value
	var drunk: Dictionary = e.abilities[1].effect_config
	# 队友：最大生命 + pill(本场一直有效)，并回复同样多；不受伤、不喝醉
	ally.hp = 500.0
	var mh0: float = ally.get_stats().max_health
	var evs: Array[Dictionary] = _pull(b, u, ally, 999.0)
	t.near(ally.get_stats().max_health, mh0 + pill, 0.01, "an ally's max health +%.0f (whatever the trigger value)" % pill)
	t.near(ally.hp, 500.0 + pill, 0.01, "and heals as much")
	t.eq(_sum(evs, "damage", ally), 0.0, "allies aren't hurt")
	t.ok(ally.get_status("g16_drunk") == null, "allies don't get drunk")
	# 【基本】：连扣都生效，一直叠
	_pull_noclear(b, u, ally, 1.0)
	_pull_noclear(b, u, ally, 1.0)
	t.near(ally.get_stats().max_health, mh0 + pill * 3.0, 0.01, "【Basic】: every pull, stacking without limit")
	_step_for(b, 20.0)
	t.near(ally.get_stats().max_health, mh0 + pill * 3.0, 0.01, "the max health lasts the battle")
	# 自己也吃；青雾散给身边的队友(一样多)，远处的队友、敌人不吃
	var smh0: float = u.get_stats().max_health
	var nmh0: float = near_ally.get_stats().max_health
	var amh1: float = ally.get_stats().max_health
	var emh0: float = near_foe.get_stats().max_health
	_pull(b, u, u, 1.0)
	t.near(u.get_stats().max_health, smh0 + pill, 0.01, "the holder can swallow one too")
	t.near(near_ally.get_stats().max_health, nmh0 + pill, 0.01, "Splash: the ally next to the target gets one too")
	t.near(ally.get_stats().max_health, amh1, 0.01, "but not one far away")
	t.near(near_foe.get_stats().max_health, emh0, 0.01, "enemies never get the elixir")
	# 敌人：固定魔法伤害 + 【醉】(攻击力 / 移动速度降低)
	var atk0: float = foe.get_stats().attack_power
	var ms0: float = foe.get_stats().move_speed
	var fmh0: float = foe.get_stats().max_health
	evs = _pull(b, u, foe, 999.0)
	t.near(_sum(evs, "damage", foe), pill, pill * 0.05, "an enemy takes a fixed %.0f magic" % pill)
	t.near(_sum(evs, "damage", near_foe), pill, pill * 0.05, "Splash: so does the enemy next to it (in full)")
	t.eq(_sum(evs, "damage", far_foe), 0.0, "but not one far away")
	t.eq(_sum(evs, "damage", near_ally) + _sum(evs, "damage", u), 0.0, "the mist never hurts our side")
	t.ok(near_foe.get_status("g16_drunk") == null, "only the target gets drunk")
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "magic"), "magic damage")
	t.near(foe.get_stats().max_health, fmh0, 0.01, "enemies get no elixir")
	t.ok(foe.get_status("g16_drunk") != null, "and gets Drunk")
	t.near(foe.get_stats().attack_power, atk0 * (1.0 + float(drunk["stats"]["attack_power"]["pct"])), 0.5, "less attack")
	t.near(foe.get_stats().move_speed, ms0 * (1.0 + float(drunk["stats"]["move_speed"]["pct"])), 0.01, "less move speed")
	t.near(_expires_in(b, foe, "g16_drunk"), float(drunk["duration"]), 0.01, "for %.0f s" % float(drunk["duration"]))
	var hp0: float = foe.hp
	_pull_noclear(b, u, foe, 1.0)
	t.near(hp0 - foe.hp, pill, pill * 0.05, "【Basic】: the magic lands on every pull too")


# ================================================================ 三兽图腾
func test_beast_totem(t: TestCtx) -> void:
	var b := _crowd("g16_beast_totem", 1, 1)
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("g16_beast_totem")
	var r: float = float(e.abilities[0].effect_config["ally_effect"]["value_multiplier"])
	var cap: float = float(e.abilities[0].effect_config["shield_cap_pct"])
	var soul: Dictionary = e.abilities[1].effect_config["ally_effect"]["cfg"]
	var awe: Dictionary = e.abilities[1].effect_config["enemy_effect"]["cfg"]
	var hb: float = 1.0 + u.get_stats().healing_done_pct
	# 队友：回复 触发数值 × r；1 层兽魂
	ally.hp = 1000.0
	var atk0: float = ally.get_stats().attack_power
	var dr0: float = ally.get_stats().damage_taken_pct
	var evs: Array[Dictionary] = _pull(b, u, ally, 300.0)
	t.near(_sum(evs, "heal", ally), 300.0 * r * hb, 1.0, "an ally heals trigger value × %.0f%%" % (r * 100.0))
	t.eq(ally.status_stacks("g16_beast_soul"), 1, "and gains a stack of Beast Soul")
	t.ok(ally.get_status("g16_beast_soul").expires_at < 0.0, "Beast Soul lasts the battle")
	t.near(ally.get_stats().attack_power, atk0 * (1.0 + float(soul["stats"]["attack_power"]["pct"])), 0.5, "more attack")
	t.near(ally.get_stats().damage_taken_pct, dr0 + float(soul["stats"]["damage_taken_pct"]["flat"]), 0.001, "less damage taken")
	for i in range(5):
		_pull_noclear(b, u, ally, 1.0)
	t.eq(ally.status_stacks("g16_beast_soul"), int(soul["max_stacks"]), "【Basic】: stacks to %d" % int(soul["max_stacks"]))
	t.eq(_sum(evs, "damage", ally), 0.0, "allies aren't hurt")
	# 满血时：溢出的回复变成护盾，最多到最大生命的 cap
	ally.hp = ally.get_stats().max_health
	ally.shield = 0.0
	_pull(b, u, ally, 300.0)
	t.near(ally.shield, minf(300.0 * r * hb, ally.get_stats().max_health * cap), 1.0, "overhealing becomes a shield")
	ally.shield = 0.0
	_pull(b, u, ally, 1.0e6)
	t.near(ally.shield, ally.get_stats().max_health * cap, 1.0, "up to %.0f%% of max health" % (cap * 100.0))
	# 敌人：触发数值 × r 魔法 + 【兽威】(攻击速度降低)，不叠兽魂
	var as0: float = foe.get_stats().attack_speed_multiplier
	evs = _pull(b, u, foe, 200.0)
	t.near(_sum(evs, "damage", foe), 200.0 * r, 200.0 * r * 0.05, "an enemy takes trigger value × %.0f%% magic" % (r * 100.0))
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "magic"), "magic damage")
	t.ok(foe.get_status("g16_beast_awe") != null, "and dreads the beasts")
	t.near(foe.get_stats().attack_speed_multiplier, as0 + float(awe["stats"]["attack_speed_multiplier"]["flat"]), 0.001, "slower attacks")
	t.near(_expires_in(b, foe, "g16_beast_awe"), float(awe["duration"]), 0.01, "for %.0f s" % float(awe["duration"]))
	t.eq(foe.status_stacks("g16_beast_soul"), 0, "enemies get no Beast Soul")


# ================================================================ 萤火虫瓶
func test_firefly_jar(t: TestCtx) -> void:
	var b := _crowd("g16_firefly_jar", 4, 4)
	var u: BUnit = b.units[0]
	var e: EquipmentDef = _eq("g16_firefly_jar")
	var ma: int = int(e.abilities[0].keyword_values.get("multi_attack", 1))
	var mark: Dictionary = e.abilities[0].effect_config["enemy_effect"]["cfg"]
	var warm: Dictionary = e.abilities[0].effect_config["ally_effect"]["cfg"]
	# 敌人：【群攻】个敌人亮起【萤光】(受到的伤害提高)，不受伤
	var sting: float = e.abilities[1].fixed_value
	var r: float = float(e.abilities[2].effect_config["enemy_effect"]["value_multiplier"])
	var amp: float = float(mark["stats"]["damage_taken_amp"]["flat"])
	var amp0: float = _foes(b, u)[0].get_stats().damage_taken_amp
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_enemies", "enemy", 200.0)
	var lit := 0
	var stung := 0
	for f: BUnit in _foes(b, u):
		if f.get_status("g16_firefly_mark") != null:
			lit += 1
			t.near(f.get_stats().damage_taken_amp, amp0 + amp, 0.001, "Firefly Glow: takes more damage")
			t.near(_expires_in(b, f, "g16_firefly_mark"), float(mark["duration"]), 0.01, "for %.0f s" % float(mark["duration"]))
			t.ok(f.get_status("g16_firefly_warm") == null, "enemies get no warmth")
		var d: float = _sum(evs, "damage", f)
		if d > 0.0:
			stung += 1
			# 萤光先亮(第一段)，之后的两段都吃到 +amp
			t.near(d, (sting + 200.0 * r) * (1.0 + amp), 1.0, "each enemy: a fixed %.0f + trigger value x %.0f%% magic (glowing)" % [sting, r * 100.0])
	t.eq(lit, ma, "Multi Attack %d: %d enemies glow" % [ma, ma])
	t.eq(stung, ma, "and %d are stung" % ma)
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "magic"), "magic damage")
	# 【基本】：灼一下连扣都生效，第三段有冷却
	var tf: BUnit = null
	for f1: BUnit in _foes(b, u):
		if f1.get_status("g16_firefly_mark") != null:
			tf = f1
	var thp: float = tf.hp
	_pull_noclear(b, u, tf, 200.0)
	t.near(thp - tf.hp, sting * (1.0 + amp), 0.5, "【Basic】: the sting lands on every pull; the swarm has a %.0f s cooldown" % e.abilities[2].cooldown)
	# 队友：【群攻】个队友获得【萤火】(每秒回复 + 受到的伤害降低) + 回复 触发数值 × r；不受伤
	var dr0: float = _allies(b, u)[0].get_stats().damage_taken_pct
	for a0: BUnit in b.units:
		if a0.team == u.team:
			a0.hp = 1000.0
	var hb: float = 1.0 + u.get_stats().healing_done_pct
	evs = _pull_rule(b, u, "all_allies", "ally", 200.0)
	var warmed := 0
	for a: BUnit in b.units:
		if a.team != u.team:
			continue
		t.eq(_sum(evs, "damage", a), 0.0, "allies aren't stung")
		if a.get_status("g16_firefly_warm") != null:
			warmed += 1
			t.near(a.get_stats().health_regen_per_second, float(warm["stats"]["health_regen_per_second"]["flat"]), 0.01, "Firefly Warmth: regenerates health")
			t.ok(a.get_status("g16_firefly_mark") == null, "allies don't glow")
			t.near(_sum(evs, "heal", a), 200.0 * r * hb, 1.0, "and heals trigger value x %.0f%%" % (r * 100.0))
			if a != u:
				t.near(a.get_stats().damage_taken_pct, dr0 + float(warm["stats"]["damage_taken_pct"]["flat"]), 0.001, "and takes less damage")
	t.eq(warmed, ma, "Multi Attack %d: %d allies warmed" % [ma, ma])
	# 【基本】：连扣都刷新(没有冷却)
	_step_for(b, 2.0)
	_pull_rule(b, u, "all_enemies", "enemy", 1.0, false)
	for f3: BUnit in _foes(b, u):
		if f3.get_status("g16_firefly_mark") != null:
			t.near(_expires_in(b, f3, "g16_firefly_mark"), float(mark["duration"]), 0.3, "【Basic】: every pull refreshes the glow")
			break


# ================================================================ 凤首箜篌
func test_konghou_bow(t: TestCtx) -> void:
	# 携带者 + 2 个队友(一个贴着、一个远远的) + 3 个敌人(主目标、贴着它的、远远的)
	var b := _start([{"def": "test_hitter", "pos": Vector2(0, -3), "weapon": "g16_konghou_bow"},
		{"def": "test_dummy", "pos": Vector2(1.0, -3)}, {"def": "test_dummy", "pos": Vector2(7.0, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.0, 3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(7.0, 3)}])
	var u: BUnit = b.units[0]
	var near_ally: BUnit = b.units[1]
	var far_ally: BUnit = b.units[2]
	var foe: BUnit = b.units[3]
	var near_foe: BUnit = b.units[4]
	var far_foe: BUnit = b.units[5]
	var e: EquipmentDef = _eq("g16_konghou_bow")
	var r: float = float(e.abilities[0].effect_config["enemy_effect"]["value_multiplier"])
	var h: float = float(e.abilities[0].effect_config["ally_effect"]["value_multiplier"])
	var conc: Dictionary = e.abilities[1].effect_config["ally_effect"]["cfg"]
	var disc: Dictionary = e.abilities[1].effect_config["enemy_effect"]["cfg"]
	# 敌人：触发数值 × r 魔法，溅给它身边的敌人(50%)，不溅我方；【乱弦】
	var as0: float = foe.get_stats().attack_speed_multiplier
	var evs: Array[Dictionary] = _pull(b, u, foe, 200.0)
	t.near(_sum(evs, "damage", foe), 200.0 * r, 200.0 * r * 0.05, "an enemy takes trigger value × %.0f%% magic" % (r * 100.0))
	t.near(_sum(evs, "damage", near_foe), 200.0 * r * 0.5, 200.0 * r * 0.05, "Splash: the enemy next to it takes half")
	t.eq(_sum(evs, "damage", far_foe), 0.0, "but not one far away")
	t.eq(_sum(evs, "damage", near_ally) + _sum(evs, "damage", u), 0.0, "the splash never hits our side")
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "magic"), "magic damage")
	t.ok(foe.get_status("g16_discord") != null, "the target gets Discord")
	t.near(foe.get_stats().attack_speed_multiplier, as0 + float(disc["stats"]["attack_speed_multiplier"]["flat"]), 0.001, "slower attacks")
	t.near(_expires_in(b, foe, "g16_discord"), float(disc["duration"]), 0.01, "for %.0f s" % float(disc["duration"]))
	# 冷却
	var hp0: float = foe.hp
	_pull_noclear(b, u, foe, 200.0)
	t.near(foe.hp, hp0, 0.01, "%.0f s cooldown on the note" % e.abilities[0].cooldown)
	# 队友：回复 触发数值 × r，溅给身边的队友；【和鸣】
	u.hp = 1000.0
	near_ally.hp = 1000.0
	far_ally.hp = 1000.0
	var hb: float = 1.0 + u.get_stats().healing_done_pct
	var atk0: float = near_ally.get_stats().attack_power
	var ap0: float = near_ally.get_stats().ability_power
	evs = _pull(b, u, near_ally, 200.0)
	t.near(_sum(evs, "heal", near_ally), 200.0 * h * hb, 1.0, "an ally heals trigger value × %.0f%%" % (h * 100.0))
	t.near(_sum(evs, "heal", u), 200.0 * h * hb * 0.5, 1.0, "Splash: so does the holder next to it (half)")
	t.eq(_sum(evs, "heal", far_ally), 0.0, "but not one far away")
	t.eq(_sum(evs, "heal", near_foe) + _sum(evs, "heal", foe), 0.0, "enemies aren't healed")
	t.ok(near_ally.get_status("g16_concord") != null, "the ally gets Concord")
	t.near(near_ally.get_stats().attack_power, atk0 * (1.0 + float(conc["stats"]["attack_power"]["pct"])), 0.5, "more attack")
	t.near(near_ally.get_stats().ability_power, ap0 + float(conc["stats"]["ability_power"]["flat"]), 0.01, "more ability power")
	t.ok(near_ally.get_status("g16_discord") == null, "no Discord on allies")


# ================================================================ 青鸾长弓
func test_luan_bow(t: TestCtx) -> void:
	var b := _crowd("g16_luan_bow", 1, 1)
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("g16_luan_bow")
	var r: float = float(e.abilities[0].effect_config["enemy_effect"]["value_multiplier"])
	var s: float = float(e.abilities[0].effect_config["ally_effect"]["value_multiplier"])
	# 敌人：触发数值 × r 物理
	var evs: Array[Dictionary] = _pull(b, u, foe, 200.0)
	t.near(_sum(evs, "damage", foe), 200.0 * r, 200.0 * r * 0.05, "an enemy takes trigger value × %.0f%% physical" % (r * 100.0))
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "physical"), "physical damage")
	var hp0: float = foe.hp
	_pull_noclear(b, u, foe, 200.0)
	t.near(foe.hp, hp0, 0.01, "%.0f s cooldown" % e.abilities[0].cooldown)
	# 队友(含自己)：触发数值 × s 护盾，不受伤
	evs = _pull(b, u, ally, 300.0)
	t.near(ally.shield, 300.0 * s, 0.5, "an ally gains a shield of trigger value × %.0f%%" % (s * 100.0))
	t.eq(_sum(evs, "damage", ally), 0.0, "allies aren't hurt")
	_pull(b, u, u, 300.0)
	t.near(u.shield, 300.0 * s, 0.5, "self: a shield too")
	# 第二段只在"有人阵亡时"响：普通时机扣到一个已倒下的队友，什么都不做
	_kill(b, ally)
	t.ok(not ally.alive, "the ally is down")
	_pull(b, u, ally, 1.0)
	_step_for(b, 0.1)
	t.ok(not ally.alive, "a non-death trigger doesn't revive anyone")


## 真望节点(勇气：自己阵亡时触发，目标 = 自己)：第一次倒下以 G16_LUAN_REVIVE 生命原地复活，第二次不再复活(每场限一次)
func test_luan_bow_revives_leader_once(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_leader", "pos": Vector2(0, -4), "star": 2, "weapon": "g16_luan_bow"},
		{"def": "test_dummy", "pos": Vector2(2, -4)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 8)}])
	b.start()
	var ld: BUnit = b.units[0]
	t.eq(ld.weapon.id if ld.weapon != null else "", "g16_luan_bow", "she carries the Azure Luan Longbow")
	var rv: float = _eq("g16_luan_bow").abilities[1].fixed_value
	_kill(b, ld)
	var evs: Array[Dictionary] = _step_for(b, 0.2)
	t.ok(ld.alive, "Courage (her own fall) → she rises again")
	t.near(ld.hp, ld.get_stats().calc_heal(ld.get_stats(), rv), 2.0, "with %.0f health (+ healing bonuses)" % rv)
	t.eq(evs.filter(func(e: Dictionary) -> bool: return e.get("t") == "revive").size(), 1, "one revive")
	_step_for(b, 5.0)
	_kill(b, ld)
	_step_for(b, 0.5)
	t.ok(not ld.alive, "once per battle: the second fall sticks")


# ================================================================ 向日葵步枪
func test_sunflower_rifle(t: TestCtx) -> void:
	var b := _crowd("g16_sunflower_rifle", 2, 1)
	var u: BUnit = b.units[0]
	var hurt: BUnit = b.units[1]
	var other: BUnit = b.units[2]
	var foe: BUnit = b.units[3]
	var e: EquipmentDef = _eq("g16_sunflower_rifle")
	var seed: float = e.abilities[0].fixed_value
	var r: float = float(e.abilities[1].effect_config["enemy_effect"]["value_multiplier"])
	# 敌人：固定物理伤害(打出来的伤害等量回复给生命最少的、没满血的队友) + 第二段 触发数值 × r 物理
	hurt.hp = 300.0
	other.hp = 800.0
	u.hp = 100.0
	var evs: Array[Dictionary] = _pull(b, u, foe, 200.0)
	t.near(_sum(evs, "damage", foe), seed + 200.0 * r, 1.0, "an enemy takes a fixed %.0f + trigger value × %.0f%% physical" % [seed, r * 100.0])
	var kinds: Array = _kinds(evs)
	t.ok(not kinds.is_empty() and kinds.all(func(k: String) -> bool: return k == "physical"), "physical damage")
	t.near(_sum(evs, "heal", hurt), seed, 0.5, "the seed's damage grows back on the ally with the least health")
	t.eq(_sum(evs, "heal", other) + _sum(evs, "heal", u), 0.0, "(only that one; never the holder)")
	# 【基本】：种子连扣都生效；第二段有冷却
	var hp0: float = foe.hp
	_pull_noclear(b, u, foe, 200.0)
	t.near(hp0 - foe.hp, seed, 0.5, "【Basic】: the seed lands on every pull; the bloom has a %.0f s cooldown" % e.abilities[1].cooldown)
	# 队友：回复固定值 + 触发数值 × r，不受伤
	other.hp = 500.0
	var hb: float = 1.0 + u.get_stats().healing_done_pct
	evs = _pull(b, u, other, 200.0)
	t.near(_sum(evs, "heal", other), (seed + 200.0 * r) * hb, 1.0, "an ally heals a fixed %.0f + trigger value × %.0f%%" % [seed, r * 100.0])
	t.eq(_sum(evs, "damage", other), 0.0, "allies aren't hurt")
