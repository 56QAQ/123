extends RefCounted
## 通用武器(第三阶段第一批)：没有主人、进随机来源；每把用一个"探针触发器"(目标 = 事件目标、固定触发数值)直接扣动载荷验证效果。
##   双生烛台(双模：友方回复 / 敌方魔法伤害，触发数值 × r)、号令短剑(固定值：【锋芒】叠 4 层)、标定步枪(固定值伤害 + 【破绽】)、
##   碎岩巨剑(触发数值 × r 物理 + 【碎甲】叠 3 层)、蚀月(【学习】：每学一次伤害 +10%)

const IDS := ["twin_candelabra", "rally_blade", "spotter_rifle", "rockbreaker", "waning_moon"]


func _probe(v: float) -> TriggerDef:
	return TriggerDef.from_dict({"id": "probe_trigger", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
		"target_rule": "event_target", "team_filter": "any", "base_value_mode": "fixed", "base_value_flat": v})


## 用探针触发器扣一次(先清掉冷却)；返回这一次的事件
func _pull(b: Battle, u: BUnit, target: BUnit, v: float) -> Array[Dictionary]:
	u.ability_cd.clear()
	u.trig_cd.clear()
	b.poll_events()
	var ev: Dictionary = b.pipeline.make_event("OnBattleFrame", u, target, 0.0, ["battle_frame"], {})
	b.pipeline._fire(ev, _probe(v), u)
	b.pipeline.drain()
	return b.poll_events()


func _setup(weapon: String) -> Battle:
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2(0, -3), "weapon": weapon}, {"def": "test_dummy", "pos": Vector2(2, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}])
	b.start()
	for u: BUnit in b.units:
		u.attack_cd = 1.0e9
		u.base.crit_chance = 0.0
		u.mark_dirty()
	return b


func _cfg(id: String) -> Dictionary:
	return Fixture.catalog().get_equipment(id).abilities[0].effect_config


static func _sum(evs: Array[Dictionary], type: String, dst: BUnit) -> float:
	var s := 0.0
	for e: Dictionary in evs:
		if e.get("t") == type and e.get("dst") == dst:
			s += float(e.get("amount", 0.0))
	return s


func test_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var pool: Array[String] = cat.equipment_ids()
	var classes := {}
	for id: String in IDS:
		var e: EquipmentDef = cat.get_equipment(id)
		t.ok(e != null and e.owner == "" and e.reworked and not e.no_drop, "%s: no owner, reworked, droppable" % id)
		t.ok(pool.has(id), "%s is in the random pool (orbs / black market / workshop / events)" % id)
		t.ok(e.model != "ornate" and e.model != "plain", "%s has its own look (%s)" % [id, e.model])
		classes[e.class_id] = true
	t.ok(classes.size() >= 4, "spread over %d weapon classes" % classes.size())
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_twin_candelabra(t: TestCtx) -> void:
	var b := _setup("twin_candelabra")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var r: float = float(_cfg("twin_candelabra")["ally_effect"]["value_multiplier"])
	ally.hp = 1000.0
	var evs: Array[Dictionary] = _pull(b, u, ally, 200.0)
	t.near(_sum(evs, "heal", ally), 200.0 * r * (1.0 + u.get_stats().healing_done_pct), 1.0, "an ally is healed for value × %.0f%% (+ healing bonus)" % (r * 100.0))
	t.eq(_sum(evs, "damage", ally), 0.0, "and not hurt")
	evs = _pull(b, u, foe, 200.0)
	t.ok(_sum(evs, "damage", foe) > 200.0 * r * 0.9, "an enemy takes value × %.0f%% magic damage" % (r * 100.0))
	var kinds: Array = evs.filter(func(e: Dictionary) -> bool: return e.get("t") == "damage" and e.get("dst") == foe).map(func(e: Dictionary) -> String: return str(e["kind"]))
	t.eq(kinds, ["magic"], "magic")


func test_rally_blade(t: TestCtx) -> void:
	var b := _setup("rally_blade")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var atk0: float = ally.get_stats().attack_power
	var as0: float = ally.get_stats().attack_speed_multiplier
	_pull(b, u, ally, 1.0)
	t.eq(ally.status_stacks("edge_rally"), 1, "the target gains a stack of Rallied (the trigger value doesn't matter)")
	for i in range(5):
		_pull(b, u, ally, 1.0)
	var per: float = float(_cfg("rally_blade")["stats"]["attack_power"]["pct"])
	t.eq(ally.status_stacks("edge_rally"), 4, "up to 4 stacks")
	t.near(ally.get_stats().attack_power, atk0 * (1.0 + 4.0 * per), 0.5, "+%.0f%% attack a stack" % (per * 100.0))
	t.near(ally.get_stats().attack_speed_multiplier, as0 + 4.0 * per, 0.001, "and attack speed")
	t.ok(absf(float(ally.get_status("edge_rally").expires_at) - b.time - 8.0) < 0.01, "lasts 8 s")


func test_spotter_rifle(t: TestCtx) -> void:
	var b := _setup("spotter_rifle")
	var u: BUnit = b.units[0]
	var foe: BUnit = b.units[2]
	var dmg: float = Fixture.catalog().get_equipment("spotter_rifle").abilities[0].fixed_value
	var evs: Array[Dictionary] = _pull(b, u, foe, 1.0)
	t.near(_sum(evs, "damage", foe), dmg, 1.0, "fixed %.0f physical, whatever the trigger value" % dmg)
	t.ok(foe.get_status("exposed") != null, "and the target is Exposed")
	var amp: float = float(_cfg("spotter_rifle")["extra_effects"][0]["stats"]["damage_taken_amp"]["flat"])
	evs = _pull(b, u, foe, 1.0)
	t.near(_sum(evs, "damage", foe), dmg * (1.0 + amp), 1.0, "Exposed: +%.0f%% damage taken" % (amp * 100.0))


func test_rockbreaker(t: TestCtx) -> void:
	var b := _setup("rockbreaker")
	var u: BUnit = b.units[0]
	var foe: BUnit = b.units[2]
	foe.base.defense = 50.0
	foe.base.magic_resistance = 50.0
	foe.mark_dirty()
	var r: float = Fixture.catalog().get_equipment("rockbreaker").abilities[0].value_multiplier
	var shred: float = -float(_cfg("rockbreaker")["extra_effects"][0]["stats"]["defense"]["flat"])
	var evs: Array[Dictionary] = _pull(b, u, foe, 300.0)
	t.ok(_sum(evs, "damage", foe) > 0.0, "value × %.0f%% physical damage" % (r * 100.0))
	t.eq(foe.status_stacks("armor_crack"), 1, "and a stack of Cracked Armor")
	_pull(b, u, foe, 300.0)
	_pull(b, u, foe, 300.0)
	_pull(b, u, foe, 300.0)
	t.eq(foe.status_stacks("armor_crack"), 3, "up to 3 stacks")
	t.near(foe.get_stats().defense, 50.0 - 3.0 * shred, 0.01, "-%.0f armor a stack" % shred)
	t.near(foe.get_stats().magic_resistance, 50.0 - 3.0 * shred, 0.01, "and magic resist")


func test_waning_moon_learns(t: TestCtx) -> void:
	var b := _setup("waning_moon")
	var u: BUnit = b.units[0]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = Fixture.catalog().get_equipment("waning_moon")
	var fixed: float = e.abilities[0].fixed_value
	var r: float = e.abilities[1].value_multiplier
	# 第一段：固定值(不吃触发数值)；触发数值 0 时只有这一段
	var d1: float = _sum(_pull(b, u, foe, 0.0), "damage", foe)
	t.near(d1, fixed, 1.0, "fixed %.0f magic, whatever the trigger value" % fixed)
	var per: float = float(_cfg("waning_moon")["learning"]["bonus_per_learning"])
	for i in range(4):
		_pull(b, u, foe, 0.0)
	var d6: float = _sum(_pull(b, u, foe, 0.0), "damage", foe)
	t.near(d6 / d1, 1.0 + 5.0 * per, 0.02, "after 5 uses it hits %.0f%% harder" % (5.0 * per * 100.0))
	for i in range(30):
		_pull(b, u, foe, 0.0)
	var dcap: float = _sum(_pull(b, u, foe, 0.0), "damage", foe)
	var cap: int = int(_cfg("waning_moon")["learning"]["cap"])
	t.near(dcap / d1, 1.0 + float(cap) * per, 0.02, "capped at %d learns" % cap)
	# 第二段：触发数值 × r(不学习)
	var dv: float = _sum(_pull(b, u, foe, 500.0), "damage", foe)
	t.near(dv - dcap, 500.0 * r, 1.0, "plus trigger value × %.0f%% (no learning)" % (r * 100.0))


# ================================================================ 第二批：召唤系 / 暴击系 / 充能系
const IDS2 := ["puppet_lantern", "requiem_banner", "crimson_fang", "keeneye_rifle", "echo_blade", "capacitor_codex"]


func test_data_batch2(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var pool: Array[String] = cat.equipment_ids()
	for id: String in IDS2:
		var e: EquipmentDef = cat.get_equipment(id)
		t.ok(e != null and e.owner == "" and e.reworked and pool.has(id), "%s: no owner, in the random pool" % id)
		t.ok(e.model != "ornate" and e.model != "plain", "%s has its own look (%s)" % [id, e.model])


## 携带者 + 一个算作它召唤物的队友 + 敌人
func _summoner_setup(weapon: String) -> Battle:
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2(0, -3), "weapon": weapon}, {"def": "test_dummy", "pos": Vector2(2, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(2.5, -1.6)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	b.start()
	var sm: BUnit = b.units[1]
	sm.is_summon = true
	sm.meta["summoner"] = b.units[0]
	return b


func test_puppet_lantern(t: TestCtx) -> void:
	var b := _summoner_setup("puppet_lantern")
	var u: BUnit = b.units[0]
	var sm: BUnit = b.units[1]
	var other: BUnit = b.units[2]
	sm.hp = 1000.0
	var atk0: float = sm.get_stats().attack_power
	var hr: float = float(_cfg("puppet_lantern")["heal_ratio"])
	var evs: Array[Dictionary] = _pull(b, u, other, 300.0)
	t.ok(sm.get_status("puppet_strings") != null, "the summon gets Puppet Strings, whoever the trigger target is")
	t.near(sm.get_stats().attack_power, atk0 * (1.0 + float(_cfg("puppet_lantern")["status"]["stats"]["attack_power"]["pct"])), 0.5, "more attack")
	t.ok(_sum(evs, "heal", sm) > 300.0 * hr * 0.9, "and it heals for value × %.0f%%" % (hr * 100.0))
	t.ok(u.get_status("puppet_strings") == null and other.get_status("puppet_strings") == null, "only summons")


func test_requiem_banner(t: TestCtx) -> void:
	var b := _summoner_setup("requiem_banner")
	var u: BUnit = b.units[0]
	var sm: BUnit = b.units[1]
	var near: BUnit = b.units[2]
	var far: BUnit = b.units[3]
	var st: Dictionary = _cfg("requiem_banner")["status"]
	var mh0: float = sm.get_stats().max_health
	_pull(b, u, far, 1.0)
	t.ok(sm.get_status("requiem_soul") != null, "the summon gets Requiem Soul")
	var mh: float = sm.get_stats().max_health
	t.near(mh, mh0 * (1.0 + float(st["stats"]["max_health"]["pct"])), 0.5, "and more max health")
	var r: float = float(st["pairs"][0]["trigger"]["base_value_ratio"])
	var hn: float = near.hp
	var hf: float = far.hp
	b.poll_events()
	sm.hp = 0.0
	b.pipeline.fx.try_kill(sm, null)
	b.pipeline.drain()
	t.near(hn - near.hp, mh * r, 1.0, "when it falls, enemies within 2 m take its max health × %.0f%%" % (r * 100.0))
	t.eq(hf - far.hp, 0.0, "enemies farther away don't")


func test_crimson_fang(t: TestCtx) -> void:
	var b := _setup("crimson_fang")
	var u: BUnit = b.units[0]
	var foe: BUnit = b.units[2]
	u.base.crit_chance = 1.0
	u.mark_dirty()
	var r: float = Fixture.catalog().get_equipment("crimson_fang").abilities[0].value_multiplier
	var evs: Array[Dictionary] = _pull(b, u, foe, 200.0)
	var crits: Array = evs.filter(func(e: Dictionary) -> bool: return e.get("t") == "damage" and e.get("dst") == foe and bool(e.get("crit", false)))
	t.eq(crits.size(), 1, "the payload can crit")
	t.near(_sum(evs, "damage", foe), 200.0 * r * u.get_stats().crit_damage, 1.0, "value × %.0f%% × crit damage" % (r * 100.0))


func test_keeneye_rifle(t: TestCtx) -> void:
	var b := _setup("keeneye_rifle")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var cfg: Dictionary = _cfg("keeneye_rifle")
	var bc: float = float(cfg["ally_effect"]["cfg"]["stats"]["crit_chance"]["flat"])
	var r: float = float(cfg["enemy_effect"]["value_multiplier"])
	var c0: float = ally.get_stats().crit_chance
	_pull(b, u, ally, 100.0)
	t.ok(ally.get_status("keen_eye") != null, "an ally gets Keen Eye")
	t.near(ally.get_stats().crit_chance, c0 + bc, 0.001, "+%.0f%% crit chance" % (bc * 100.0))
	var evs: Array[Dictionary] = _pull(b, u, foe, 100.0)
	t.ok(_sum(evs, "damage", foe) >= 100.0 * r * 0.99, "an enemy is struck for value × %.0f%%" % (r * 100.0))
	var wc: float = float(Fixture.catalog().get_equipment("keeneye_rifle").flat_mods.get("crit_chance", 0.0))
	u.base.crit_chance = 1.25
	u.mark_dirty()
	var cd: float = u.get_stats().crit_damage
	u.base.crit_chance = 0.5
	u.mark_dirty()
	t.near(cd - u.get_stats().crit_damage, 0.25 + wc, 0.001, "crit chance above 100% turns into crit damage")


func test_echo_blade(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_commando", "pos": Vector2(0, -3), "weapon": "echo_blade", "star": 2}, {"def": "test_dummy", "pos": Vector2(2, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	b.start()
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var cfg: Dictionary = _cfg("echo_blade")
	var pa: AbilityDef = u.def.passive_by_id("node_commando_cover")
	var mx: int = Pipeline.kw_value(u, pa, "charged", 0)
	t.eq(mx, int(pa.keyword_value("charged", 1, 0)) + 1, "passive Charged +1 (%d)" % mx)
	u.ability_charges[pa.id] = 0
	u.ability_cd[pa.id] = b.time + 999.0
	var evs: Array[Dictionary] = _pull(b, u, foe, 100.0)
	t.eq(int(u.ability_charges[pa.id]), 1, "the least-charged Charged effect regains 1 charge")
	var r: float = float(cfg["enemy_effect"]["value_multiplier"])
	t.ok(_sum(evs, "damage", foe) >= 100.0 * r * 0.99, "an enemy takes value × %.0f%%" % (r * 100.0))
	ally.hp = 1.0
	evs = _pull(b, u, ally, 100.0)
	t.near(_sum(evs, "heal", ally), 100.0 * float(cfg["ally_effect"]["value_multiplier"]), 1.0, "an ally is healed instead")
	t.eq(_sum(evs, "damage", ally), 0.0, "and not hurt")
	t.eq(int(u.ability_charges[pa.id]), 2, "and it still restores a charge, whoever the target is")


func test_capacitor_codex(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_medium", "pos": Vector2(0, -3), "weapon": "capacitor_codex"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	b.start()
	var u: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	u.base.crit_chance = 0.0
	u.mark_dirty()
	var pa: AbilityDef = u.def.passive_by_id("node_medium_partner")
	var mx: int = Pipeline.kw_value(u, pa, "charged", 0)
	var cb: int = int(Fixture.catalog().get_equipment("capacitor_codex").flat_mods.get("passive_charges_bonus", 0))
	t.eq(mx, 9 + cb, "passive Charged +%d" % cb)
	u.ability_charges[pa.id] = mx
	var cfg: Dictionary = _cfg("capacitor_codex")
	var k: float = float(cfg["base"]) + float(cfg["per"]) * float(mx)
	var full: float = _sum(_pull(b, u, foe, 100.0), "damage", foe)
	u.ability_charges[pa.id] = 0
	u.ability_cd[pa.id] = b.time + 999.0
	var empty: float = _sum(_pull(b, u, foe, 100.0), "damage", foe)
	t.near(full / empty, k / float(cfg["base"]), 0.02, "with %d charges left it hits %.1f× as hard as with none" % [mx, k / float(cfg["base"])])


func test_capacitor_codex_heals_allies(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_medium", "pos": Vector2(0, -3), "weapon": "capacitor_codex"}, {"def": "test_dummy", "pos": Vector2(2, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	b.start()
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	ally.hp = 1.0
	var cfg: Dictionary = _cfg("capacitor_codex")
	var evs: Array[Dictionary] = _pull(b, u, ally, 100.0)
	var pa: AbilityDef = u.def.passive_by_id("node_medium_partner")
	var k: float = float(cfg["ally_base"]) + float(cfg["ally_per"]) * float(u.ability_charges.get(pa.id, 0))
	t.near(_sum(evs, "heal", ally), 100.0 * k, 2.0, "an ally trigger target is healed for value × %.0f%%" % (k * 100.0))
	t.eq(_sum(evs, "damage", ally), 0.0, "not hurt")


## 每把通用武器设计时说的"合手"的棋子必须真的装得上(颜色 / 大类 / 星级规则)：装不上时测强度会悄悄换成基础武器
const CARRIERS := {
	"twin_candelabra": ["node_druid", "node_medium"], "rally_blade": ["node_druid", "node_knight_errant", "node_warden"],
	"spotter_rifle": ["node_commando", "node_archer"], "rockbreaker": ["node_paladin", "node_astronaut"],
	"waning_moon": ["node_killer", "node_runner", "node_vampire"],
	"puppet_lantern": ["node_wizard", "node_druid"], "requiem_banner": ["node_wizard", "node_witch"],
	"crimson_fang": ["node_runner", "node_maid", "node_berserker"], "keeneye_rifle": ["node_sniper", "node_tinker"],
	"echo_blade": ["node_knight_errant", "node_commando"], "capacitor_codex": ["node_medium", "node_nurse"],
	"kaleidoscope": ["node_perfume", "node_wizard"], "stardust_orb": ["node_wizard", "node_medium"],
	"chord_fork": ["node_dancer", "node_druid"], "ward_mirror": ["node_nurse", "node_warden", "node_pianist"], "erudite_case": ["node_student", "node_medium"],
	"twin_flintlock": ["node_archer", "node_commando"], "twin_chakram": ["node_angel", "node_psychic"], "fortune_cards": ["node_taoist", "node_cowboy"],
	"bubble_blasters": ["node_nurse", "node_rogue"], "resonance_bells": ["node_shielder", "node_psychic"],
}


func test_carriers_can_equip(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	for wid: String in CARRIERS.keys():
		var e: EquipmentDef = cat.get_equipment(wid)
		for uid: String in CARRIERS[wid]:
			for star: int in [1, 2, 3]:
				var why: String = e.equip_problem(cat.get_unit(uid), star)
				t.eq(why, "", "%s fits %s ★%d" % [wid, uid, star])


# ================================================================ 第三批：法器(按适配标签补空档)
const IDS3 := ["kaleidoscope", "stardust_orb", "chord_fork", "ward_mirror", "erudite_case"]


func test_data_batch3(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var pool: Array[String] = cat.equipment_ids()
	for id: String in IDS3:
		var e: EquipmentDef = cat.get_equipment(id)
		t.ok(e != null and e.owner == "" and e.reworked and pool.has(id) and e.class_id == "focus", "%s: a generic focus in the random pool" % id)
		t.ok(e.model != "ornate" and e.model != "plain", "%s has its own look (%s)" % [id, e.model])


## 探针触发器：目标规则 rule、固定触发数值 v(多目标用)
func _pull_rule(b: Battle, u: BUnit, rule: String, team: String, v: float) -> Array[Dictionary]:
	u.ability_cd.clear()
	u.trig_cd.clear()
	b.poll_events()
	var trig := TriggerDef.from_dict({"id": "probe_trigger_multi", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
		"target_rule": rule, "team_filter": team, "base_value_mode": "fixed", "base_value_flat": v})
	b.pipeline._fire(b.pipeline.make_event("OnBattleFrame", u, null, 0.0, ["battle_frame"], {}), trig, u)
	b.pipeline.drain()
	return b.poll_events()


## 不清冷却地扣一次(【基本】没有冷却：连扣都生效)
func _pull_noclear(b: Battle, u: BUnit, target: BUnit, v: float) -> Array[Dictionary]:
	b.poll_events()
	var ev: Dictionary = b.pipeline.make_event("OnBattleFrame", u, target, 0.0, ["battle_frame"], {})
	b.pipeline._fire(ev, _probe(v), u)
	b.pipeline.drain()
	return b.poll_events()


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


func test_kaleidoscope(t: TestCtx) -> void:
	var b := _crowd("kaleidoscope", 0, 4)
	var u: BUnit = b.units[0]
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_enemies", "enemy", 1000.0)
	var hit := 0
	var marked := 0
	for f: BUnit in b.units:
		if f.team != u.team:
			if _sum(evs, "damage", f) > 0.0:
				hit += 1
				var fixed: float = Fixture.catalog().get_equipment("kaleidoscope").abilities[0].fixed_value
				t.ok(_sum(evs, "damage", f) >= (fixed + 1000.0 * 0.10) * 0.99, "each target takes the fixed part + trigger value × 10%")
			if f.get_status("prism_shatter") != null:
				marked += 1
	t.eq(hit, 3, "Multi Attack 3: three of the four enemies are hit")
	t.eq(marked, 3, "…and get Shattered Light")
	var f0: BUnit = null
	for f1: BUnit in b.units:
		if f1.team != u.team and f1.get_status("prism_shatter") != null:
			f0 = f1
	var mr0: float = f0.get_stats().magic_resistance
	_pull_rule(b, u, "all_enemies", "enemy", 0.0)
	t.near(f0.get_stats().magic_resistance, mr0 - 15.0, 0.01, "a second stack: -15 more magic resist (stacks to 2)")


func test_stardust_orb(t: TestCtx) -> void:
	var b := _setup("stardust_orb")
	var u: BUnit = b.units[0]
	var foe: BUnit = b.units[2]
	var dmg := 0.0
	for i in range(7):
		dmg += _sum(_pull_noclear(b, u, foe, 1.0), "damage", foe)
	t.ok(dmg >= 12.0 * 7.0 * 0.99, "【基本】: it hits every time, no cooldown (%.0f)" % dmg)
	t.eq(foe.status_stacks("star_mark"), 5, "Star Mark stacks to 5")


func test_chord_fork(t: TestCtx) -> void:
	var b := _crowd("chord_fork", 5, 1)
	var u: BUnit = b.units[0]
	var as0: float = b.units[1].get_stats().attack_speed_multiplier
	for i in range(7):
		_pull_rule(b, u, "all_allies_except_self", "ally", 1.0)
	var got := 0
	var top := 0
	var buffed: BUnit = null
	for a: BUnit in b.units:
		var n: int = a.status_stacks("chord_resonance")
		if a.team == u.team and a != u and n > 0:
			got += 1
		if n > top:
			top = n
			buffed = a
	t.eq(got, 4, "Multi Attack 4: four of the five allies resonate")
	var ac: Dictionary = _cfg("chord_fork")["ally_effect"]["cfg"]
	var mx: int = int(ac["max_stacks"])
	t.eq(top, mx, "【基本】 + stacks to %d" % mx)
	t.near(buffed.get_stats().attack_speed_multiplier, as0 + float(mx) * float(ac["stats"]["attack_speed_multiplier"]["flat"]), 0.001, "+attack speed per stack")
	# 双模：打到敌人身上是魔法伤害，不是增益
	var foe: BUnit = b.units[b.units.size() - 1]
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_enemies", "enemy", 100.0)
	t.ok(_sum(evs, "damage", foe) >= 100.0 * float(_cfg("chord_fork")["enemy_effect"]["value_multiplier"]) * 0.99, "an enemy takes magic damage")
	t.eq(foe.status_stacks("chord_resonance"), 0, "…and gets no Resonance")


func test_ward_mirror(t: TestCtx) -> void:
	var b := _setup("ward_mirror")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var r: float = Fixture.catalog().get_equipment("ward_mirror").abilities[0].value_multiplier
	var s0: float = ally.shield
	_pull(b, u, ally, 500.0)
	t.near(ally.shield - s0, 500.0 * r, 1.0, "the trigger target gets a shield of trigger value × %.0f%%" % (r * 100.0))
	t.ok(ally.get_status("crystal_wall") != null and ally.get_stats().damage_taken_amp < 0.0, "…and Crystal Wall (takes less damage)")


func test_erudite_case(t: TestCtx) -> void:
	var b := _setup("erudite_case")
	var u: BUnit = b.units[0]
	var foe: BUnit = b.units[2]
	var d1: float = _sum(_pull(b, u, foe, 1000.0), "damage", foe)
	var d2: float = _sum(_pull(b, u, foe, 1000.0), "damage", foe)
	var lp: float = float(_cfg("erudite_case")["learning"]["bonus_per_learning"])
	var r: float = Fixture.catalog().get_equipment("erudite_case").abilities[0].value_multiplier
	t.ok(d1 >= 1000.0 * r * 0.99, "trigger value × %.0f%% magic damage (%.0f)" % [r * 100.0, d1])
	t.near(d2 / d1, 1.0 + lp, 0.01, "the second time hits %.0f%% harder (Learning)" % (lp * 100.0))


# ================================================================ 第四批：手枪(双持远程；不射子弹的有自己的投射物)
const IDS4 := ["twin_flintlock", "twin_chakram", "fortune_cards", "bubble_blasters", "resonance_bells"]


func test_data_batch4(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var pool: Array[String] = cat.equipment_ids()
	for id: String in IDS4:
		var e: EquipmentDef = cat.get_equipment(id)
		t.ok(e != null and e.owner == "" and e.reworked and pool.has(id) and e.class_id == "pistols", "%s: a generic pistols weapon in the random pool" % id)
		t.ok(e.model != "ornate" and e.model != "plain", "%s has its own look (%s)" % [id, e.model])
	for id2: String in ["twin_chakram", "fortune_cards", "bubble_blasters", "resonance_bells"]:
		var e2: EquipmentDef = cat.get_equipment(id2)
		t.ok(e2.projectile != "" and e2.projectile != "bullet", "%s doesn't shoot bullets: its own projectile (%s)" % [id2, e2.projectile])


func test_twin_flintlock(t: TestCtx) -> void:
	var b := _setup("twin_flintlock")
	var u: BUnit = b.units[0]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = Fixture.catalog().get_equipment("twin_flintlock")
	var evs: Array[Dictionary] = _pull(b, u, foe, 1000.0)
	t.ok(_sum(evs, "damage", foe) >= (e.abilities[0].fixed_value + 1000.0 * e.abilities[1].value_multiplier) * 0.9, "both parts hit (fixed + trigger value × r)")
	t.ok(foe.get_status("gunsmoke") != null, "…and Gunsmoke lowers its armor")
	var d2: float = _sum(_pull_noclear(b, u, foe, 1000.0), "damage", foe)
	t.ok(d2 > 0.0 and d2 < 1000.0 * e.abilities[1].value_multiplier, "right after: only the 【基本】 part fires (the other is on cooldown)")


func test_twin_chakram(t: TestCtx) -> void:
	var b := _crowd("twin_chakram", 0, 4)
	var u: BUnit = b.units[0]
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_enemies", "enemy", 1.0)
	var hit := 0
	var slowed := 0
	for f: BUnit in b.units:
		if f.team != u.team:
			if _sum(evs, "damage", f) > 0.0:
				hit += 1
			if f.get_status("chakram_slow") != null:
				slowed += 1
	t.eq(hit, 3, "Multi Attack 3")
	t.eq(slowed, 3, "…and they are Hindered")


func test_fortune_cards(t: TestCtx) -> void:
	var b := _setup("fortune_cards")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	_pull(b, u, ally, 1.0)
	t.ok(ally.get_status("good_luck") != null and ally.get_status("bad_luck") == null, "an ally draws Good Luck")
	_pull(b, u, foe, 1.0)
	t.ok(foe.get_status("bad_luck") != null and foe.get_status("good_luck") == null, "an enemy draws Bad Luck")


func test_bubble_blasters(t: TestCtx) -> void:
	var b := _setup("bubble_blasters")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	ally.hp = 1000.0
	var s0: float = ally.shield
	var evs: Array[Dictionary] = _pull_noclear(b, u, ally, 1.0)
	var e: EquipmentDef = Fixture.catalog().get_equipment("bubble_blasters")
	t.near(_sum(evs, "heal", ally), e.abilities[0].fixed_value, 0.5, "heals a fixed amount")
	t.ok(ally.shield > s0, "…and adds a shield")
	_pull_noclear(b, u, ally, 1.0)
	t.ok(ally.shield > s0 + 1.5 * (ally.shield - s0) / 2.0, "【基本】: again right away")


func test_resonance_bells(t: TestCtx) -> void:
	var b := _crowd("resonance_bells", 3, 3)
	var u: BUnit = b.units[0]
	var r: float = float(_cfg("resonance_bells")["ally_effect"]["value_multiplier"])
	_pull_rule(b, u, "all_allies_except_self", "ally", 100.0)
	var shielded := 0
	for a: BUnit in b.units:
		if a.team == u.team and a != u and a.shield >= 100.0 * r * 0.99:
			shielded += 1
	t.eq(shielded, 3, "allies: a shield of trigger value × %.0f%% (Multi Attack 3)" % (r * 100.0))
	var evs: Array[Dictionary] = _pull_rule(b, u, "all_enemies", "enemy", 100.0)
	var hit := 0
	for f: BUnit in b.units:
		if f.team != u.team and _sum(evs, "damage", f) > 0.0:
			hit += 1
	t.eq(hit, 3, "enemies: magic damage instead")
