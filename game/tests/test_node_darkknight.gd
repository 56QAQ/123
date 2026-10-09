extends RefCounted
## 重构版守誓节点(1 费 · 红 · 安保部 · 战士模版)：誓血仇(觉醒：有队友被击杀；每次普攻流失最大生命 10% × x 当伤害；优先打凶手)、
## 誓绶身(2 星，觉醒：队伍里有稀有度 5 的棋子；绑定、视为它的召唤物、加星、它挨的普攻转到自己身上)、
## 起誓之时(完成任意觉醒后触发，触发数值 = 最大生命 × y)、专属武器黑剑(暗色誓约 / 光色誓约 + 生命上限提升)。


func _step(b: Battle, seconds: float) -> void:
	for i in range(int(round(seconds / GC.SIM_DT))):
		b.step()


## 跑到 unit 的下一个 type 事件(不清空事件流，后面还要数伤害事件)
func _until(b: Battle, type: String, unit: BUnit, cap_s: float = 4.0) -> Dictionary:
	var n0: int = _count(b, type, unit)
	for i in range(int(cap_s / GC.SIM_DT)):
		b.step()
		if _count(b, type, unit) > n0:
			var all: Array[Dictionary] = Fixture.events_of(b, type)
			return all.back()
	return {}


func _count(b: Battle, type: String, unit: BUnit) -> int:
	var n := 0
	for e: Dictionary in Fixture.events_of(b, type):
		if e.get("unit") == unit:
			n += 1
	return n


## 守誓节点 + 一个队友木桩 + 敌人(凶手)；kill_ally 时由 killer 打死队友
func _setup(star: int = 1, weapon: String = "", extra: Array = []) -> Battle:
	var specs: Array = [{"def": "node_darkknight", "team": 0, "star": star, "pos": Vector2(0, 0), "weapon": weapon},
		{"def": "test_dummy", "team": 0, "pos": Vector2(-3, 0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.6)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(5, 3)}]
	specs.append_array(extra)
	var b: Battle = Fixture.make(specs)
	b.start()
	_step(b, GC.START_DELAY + 0.05)
	return b


func test_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = cat.get_unit("node_darkknight")
	t.eq(d.cost, 1, "rarity 1")
	t.eq(d.faction_id, "red", "red")
	t.eq(d.base_weapon_class, "heavy", "two-handed heavy by default")
	t.ok(d.can_use_weapon_class("sword") and d.can_use_weapon_class("polearm") and not d.can_use_weapon_class("dual"), "can use one-handed swords and polearms")
	t.ok(d.reworked and d.model == "darkknight", "reworked, his own body")
	var e: EquipmentDef = cat.get_equipment("blackblade")
	t.ok(e != null and e.cost == 2 and e.color_id == "red" and e.class_id == "heavy" and e.owner == "node_darkknight", "Blackblade: rarity 2, red, heavy, his")
	t.eq(cat.get_equipment("oathkeeper_greatsword"), null, "the old Oathkeeper Greatsword is gone")
	t.ok(Run.create(cat, 3).inventory.has("blackblade"), "the starting armory holds the Blackblade instead")


func test_vendetta_wakes_when_an_ally_is_killed(t: TestCtx) -> void:
	var b: Battle = _setup()
	var d: BUnit = b.units[0]
	var foe: BUnit = b.units[2]
	var killer: BUnit = b.units[3]
	# 还没觉醒：普攻不流失生命
	_until(b, "attack_release", d)
	_step(b, 0.05)
	t.near(d.hp, d.get_stats().max_health, 0.5, "not awakened yet: no drain")
	# 远处那个敌人打死队友
	b.pipeline.fx.damage(killer, b.units[1], 1.0e7, "true")
	_step(b, 0.05)
	t.ok(d.awakened.get("node_darkknight_vendetta", false), "an ally killed → Blood Vendetta awakens")
	t.eq(d.forced_target, killer, "he now hunts the killer, not the enemy next to him")
	var hp0: float = d.hp
	var hits0: int = Fixture.events_of(b, "damage", "passive").size()
	_until(b, "attack_release", d, 8.0)
	_step(b, 0.05)
	var drained: float = d.get_stats().max_health * 0.1
	t.near(hp0 - d.hp, drained, 1.0, "each normal attack drains 10% of max health")
	var extra: Array[Dictionary] = []
	for ev: Dictionary in Fixture.events_of(b, "damage", "passive"):
		if ev["src"] == d:
			extra.append(ev)
	t.ok(extra.size() > hits0, "…and adds a hit")
	var x1: float = float(((Fixture.catalog().get_unit("node_darkknight").passives[0] as AbilityDef).effect_config["damage_multiplier_by_star"] as Dictionary)["1"])
	t.near(float(extra.back()["amount"]), drained * x1, 1.0, "1★: %.1f× the drained health as physical damage (0-def dummy)" % x1)
	t.eq(extra.back()["dst"], killer, "on the killer")
	# 生命最多流失到 1
	d.hp = 1.0
	_until(b, "attack_release", d, 8.0)
	_step(b, 0.05)
	t.ok(d.alive and d.hp >= 1.0, "never drains himself to death")


func test_oath_hour_and_the_blackblade(t: TestCtx) -> void:
	var b: Battle = _setup(2, "blackblade")
	var d: BUnit = b.units[0]
	var killer: BUnit = b.units[3]
	var max0: float = d.get_stats().max_health
	b.pipeline.fx.damage(killer, b.units[1], 1.0e7, "true")
	_step(b, 0.05)
	var st: BStatus = d.get_status("dark_oath")
	t.ok(st != null, "awakening → Hour of the Oath → Blackblade grants Dark Oath")
	t.ok(st != null and st.has_flag("no_dispel") and st.expires_at < 0.0, "Dark Oath: permanent, can't be dispelled")
	t.eq(d.get_status("light_oath"), null, "no Light Oath: he isn't anyone's summon")
	var y2: float = 0.0
	for tr: TriggerDef in d.def.triggers:
		if tr.id == "node_darkknight_oath_hour":
			y2 = tr.ratio_for(2)
	var gain: float = max0 * y2 * 0.5
	t.near(d.get_stats().max_health, max0 + gain, 1.0, "2★: max health + y(%.2f) × 50%% of it" % y2)
	t.near(d.hp, d.get_stats().max_health, 1.0, "the added health is restored at once")
	var as0: float = d.get_stats().attack_speed_multiplier
	t.near(d.get_stats().damage_dealt_pct, 0.0, 0.001, "Dark Oath is dormant until awakened")
	# 暗色誓约觉醒：击杀那个击杀过队友的敌人
	b.pipeline.fx.damage(d, killer, 1.0e7, "true")
	_step(b, 0.05)
	t.ok(bool(st.meta.get("awakened", false)), "killing the ally's killer awakens Dark Oath")
	t.near(d.get_stats().attack_speed_multiplier, as0 * 2.0, 0.01, "attack interval halved")
	t.near(d.get_stats().damage_dealt_pct, 1.0, 0.001, "+100% damage")
	t.ok(d.get_stats().max_health > max0 + gain + 1.0, "that was another awakening: Hour of the Oath fired again (+max health)")


func test_vow_binds_to_a_rarity_5_piece(t: TestCtx) -> void:
	var b: Battle = Fixture.make([{"def": "node_darkknight", "team": 0, "star": 2, "pos": Vector2(0, 0), "weapon": "blackblade"},
		{"def": "test_rarity5", "team": 0, "star": 3, "pos": Vector2(-4, 0)},
		{"def": "test_dummy", "team": 0, "star": 1, "pos": Vector2(-1, 3)},
		{"def": "test_hitter", "team": 1, "pos": Vector2(-4, 5)}])
	var d: BUnit = b.units[0]
	var r5: BUnit = b.units[1]
	var foe: BUnit = b.units[3]
	b.start()
	_step(b, 0.1)
	t.eq(d.summoner(), r5, "2★: binds to the rarity-5 piece")
	t.eq(d.star, 5, "…and gains its 3 stars on top of his 2")
	t.near(d.base.max_health, d.def.stats_for_star(5).max_health, 0.5, "stats for 5★")
	t.ok(d.get_status("dark_oath") != null and d.get_status("light_oath") != null, "bind awakening → Blackblade: as a summon he also gets Light Oath")
	# 它挨的普攻转到守誓节点身上
	var hp_r5: float = r5.hp
	var hp_d: float = d.hp
	b.pipeline.normal_attack(foe, r5)
	_step(b, 0.05)
	t.near(r5.hp, hp_r5, 0.01, "the rarity-5 piece takes nothing")
	t.ok(d.hp < hp_d, "the normal attack lands on the Darkknight instead, however far away")
	# 1 星不绑定
	var b1: Battle = Fixture.make([{"def": "node_darkknight", "team": 0, "star": 1, "pos": Vector2(0, 0)},
		{"def": "test_rarity5", "team": 0, "star": 3, "pos": Vector2(-4, 0)}])
	b1.start()
	_step(b1, 0.1)
	t.eq(b1.units[0].summoner(), null, "1★: Oath-bound Body isn't unlocked")


func test_light_oath_saves_him_and_his_summoner_once_each(t: TestCtx) -> void:
	var b: Battle = Fixture.make([{"def": "node_darkknight", "team": 0, "star": 2, "pos": Vector2(0, 0), "weapon": "blackblade"},
		{"def": "test_rarity5", "team": 0, "star": 3, "pos": Vector2(-4, 0)},
		{"def": "test_hitter", "team": 1, "pos": Vector2(0, 5)}])
	var d: BUnit = b.units[0]
	var r5: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	b.start()
	_step(b, 0.1)
	var lo: BStatus = d.get_status("light_oath")
	t.ok(lo != null and not bool(lo.meta.get("awakened", false)), "Light Oath starts dormant")
	for i in range(19):
		b.pipeline.normal_attack(foe, d)
	_step(b, 0.02)
	t.ok(not bool(lo.meta.get("awakened", false)), "19 normal attacks: not yet")
	b.pipeline.normal_attack(foe, d)
	_step(b, 0.02)
	t.ok(bool(lo.meta.get("awakened", false)), "the 20th awakens it")
	b.pipeline.fx.damage(foe, d, 1.0e7, "true")
	_step(b, 0.02)
	t.ok(d.alive and d.hp >= d.get_stats().max_health - 1.0, "about to die → restored to full")
	b.pipeline.fx.damage(foe, d, 1.0e7, "true")
	_step(b, 0.02)
	t.ok(not d.alive, "…only once")
	# 召唤者：守誓节点倒下以后就没人保了；换一场让守誓节点活着
	var b2: Battle = Fixture.make([{"def": "node_darkknight", "team": 0, "star": 2, "pos": Vector2(0, 0), "weapon": "blackblade"},
		{"def": "test_rarity5", "team": 0, "star": 3, "pos": Vector2(-4, 0)},
		{"def": "test_hitter", "team": 1, "pos": Vector2(0, 5)}])
	b2.start()
	_step(b2, 0.1)
	var d2: BUnit = b2.units[0]
	var r52: BUnit = b2.units[1]
	var foe2: BUnit = b2.units[2]
	for i2 in range(20):
		b2.pipeline.normal_attack(foe2, d2)
	_step(b2, 0.02)
	b2.pipeline.fx.damage(foe2, r52, 1.0e7, "true")
	_step(b2, 0.02)
	t.ok(r52.alive and r52.hp >= r52.get_stats().max_health - 1.0, "his summoner about to die → restored to full")
	b2.pipeline.fx.damage(foe2, r52, 1.0e7, "true")
	_step(b2, 0.02)
	t.ok(not r52.alive, "…only once for the summoner too")
