extends RefCounted
## 执剑节点：勇者，圣剑(开战及每 5 秒，对当前目标：普通怪物直接击杀，否则 x × (100 + 法强)% × 最大生命的真实伤害)、
## 梦想，未来(免疫负面状态；队友给的属性提升 × y；阵亡时把持有的属性提升扩散给全体队友、无限持续)、
## 与你，再度飞翔(每 10 秒，自身 + 攻击力最高的已阵亡队友，触发数值 z × (100 + 法强)%)、唯一；
## 专武希望(法强 / 最大生命；冷却 9 秒【群攻 2】回复 n × 触发数值，已阵亡则以该生命值复活)。


func _step(b: Battle) -> Array[Dictionary]:
	b.step()
	return b.poll_events()


static func _of(evs: Array[Dictionary], type: String) -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for e: Dictionary in evs:
		if e.get("t") == type:
			r.append(e)
	return r


func _run(b: Battle, sec: float) -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	while b.time < sec - 0.0001 and b.state != "ended":
		all.append_array(_step(b))
	return all


func _def() -> UnitDef:
	return Fixture.catalog().get_unit("node_brave")


func _trig(id: String) -> TriggerDef:
	for tr: TriggerDef in _def().triggers:
		if tr.id == id:
			return tr
	return null


func _y(star: int) -> float:
	return float(_def().passive_by_id("node_brave_dream").effect_config["meta_by_star"]["ally_buff_amp"][str(star)])


func _calm(v: BUnit) -> void:
	v.attack_cd = 1.0e9
	v.base.move_speed = 0.0
	v.base.crit_chance = 0.0
	v.mark_dirty()


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = _def()
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model, d.unique], [4, "blue", "security", "warrior", "sword", "brave", true],
		"rarity 4, blue, Security, warrior, one-hand melee, brave model, unique")
	t.eq(d.weapon_classes, ["sword", "heavy"] as Array[String], "can equip two-handed heavy")
	t.ok(d.base_stats.attack_power < 200.0 and d.base_stats.max_health < 2600.0,
		"warrior template trimmed (%d attack / %d health; the rarity-4 template is 200 / 2600): slaying common monsters is worth a card by itself" % [int(d.base_stats.attack_power), int(d.base_stats.max_health)])
	var e: EquipmentDef = cat.get_equipment("hope")
	t.eq([e.class_id, e.color_id, e.cost, e.owner, e.model], ["sword", "blue", 4, "node_brave", "hope"], "Hope: one-hand melee, blue, rarity 4, hers")
	t.ok(float(e.flat_mods.get("ability_power", 0.0)) > 0.0 and float(e.flat_mods.get("max_health", 0.0)) > 0.0, "ability power + max health")
	var ab: AbilityDef = e.abilities[0]
	t.eq([ab.keyword_value("multi_attack", 1), ab.cooldown, ab.effect_type], [2, 9.0, "heal"], "9 s cooldown 【Multi-Attack 2】 heal")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_holy_sword_slays_common_monsters(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_brave", "pos": Vector2(0, -3)}, {"def": "mob_guardian", "team": 1, "pos": Vector2(0, 6)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(4, 8)}])
	var v: BUnit = b.units[0]
	var mob: BUnit = b.units[1]
	_calm(v)
	b.start()
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 0.3)
	var hs: Array[Dictionary] = _of(evs, "holy_sword")
	t.eq(hs.size(), 1, "strikes as the battle starts")
	t.ok(not hs.is_empty() and hs[0]["target"] == mob and bool(hs[0]["kill"]), "no target yet: the nearest enemy — a common monster — slain outright")
	t.ok(not mob.alive, "dead")
	t.ok(b.units[2].alive, "the other one untouched")


func test_holy_sword_percent_true_damage_on_elites_and_nodes(t: TestCtx) -> void:
	for star: int in [1, 2]:
		var b := Fixture.make([{"def": "node_brave", "pos": Vector2(0, -3), "star": star}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)},
			{"def": "mob_guardian", "team": 1, "pos": Vector2(6, 9)}])
		var v: BUnit = b.units[0]
		var dm: BUnit = b.units[1]
		var elite: BUnit = b.units[2]
		elite.meta["elite"] = true
		_calm(v)
		b.start()
		var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 0.3)
		var x: float = _trig("node_brave_holy").flat_for(star)
		var dmg: Array[Dictionary] = _of(evs, "damage").filter(func(e: Dictionary) -> bool: return e["dst"] == dm)
		t.eq(dmg.size(), 1, "★%d a non-monster (dummy) isn't slain" % star)
		t.near(float(dmg[0]["amount"]), dm.get_stats().max_health * x, 0.5, "★%d: %d%% of its max health" % [star, int(round(x * 100.0))])
		t.eq(dmg[0]["kind"], "true", "true damage")
		# 当前目标 = 精英：也只是百分比伤害；每 5 秒一次
		v.target = elite
		var hp0: float = elite.hp
		evs = _run(b, GC.START_DELAY + 4.9)
		t.eq(_of(evs, "holy_sword").size(), 0, "★%d nothing more within 5 s" % star)
		evs = _run(b, GC.START_DELAY + 5.45)
		var hs: Array[Dictionary] = _of(evs, "holy_sword")
		t.ok(hs.size() == 1 and hs[0]["target"] == elite and not bool(hs[0]["kill"]), "★%d 5 s later: on her current target, an elite isn't slain" % star)
		t.near(hp0 - elite.hp, elite.get_stats().max_health * x, 0.5, "★%d elite takes the % damage" % star)
		t.ok(elite.alive, "still alive")


func test_holy_sword_scales_with_ability_power(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_brave", "pos": Vector2(0, -3), "weapon": "hope"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var v: BUnit = b.units[0]
	var dm: BUnit = b.units[1]
	_calm(v)
	b.start()
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 0.3)
	var ap: float = v.get_stats().ability_power
	t.ok(ap > 0.0, "Hope gives ability power (%d)" % int(ap))
	var dmg: Array[Dictionary] = _of(evs, "damage").filter(func(e: Dictionary) -> bool: return e["dst"] == dm and e["surface"] == "passive")
	t.near(float(dmg[0]["amount"]), dm.get_stats().max_health * _trig("node_brave_holy").flat_for(1) * (1.0 + ap / 100.0), 0.5, "× (100 + AP)%")


func test_dream_immune_to_debuffs(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_brave", "pos": Vector2(0, -3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var v: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	_calm(v)
	b.start()
	_run(b, GC.START_DELAY + 0.1)
	t.ok(v.has_status_flag("debuff_immune_all"), "Dream is up from the start")
	t.eq(v.get_status("brave_dream").flags.has("no_dispel"), true, "can't be dispelled")
	t.eq(b.pipeline.fx.apply_status(foe, v, {"status_id": "stun", "duration": 2.0, "flags": ["debuff", "stun"]}), null, "no stun")
	t.eq(b.pipeline.fx.apply_chill(foe, v, 4.0), null, "no Chill")
	t.eq(b.pipeline.fx.apply_status(foe, v, {"status_id": "commando_mark", "flags": ["debuff", "no_dispel"], "stats": {"damage_taken_amp": {"flat": 0.2}}}), null,
		"not even undispellable debuffs")
	t.ok(not v.is_stunned(), "still free")
	b.pipeline.fx.wither(foe, v, 300.0)
	t.eq(v.status_stacks("ember_wither"), 0, "no Dragonfire Scar either")


func test_dream_amplifies_teammate_buffs(t: TestCtx) -> void:
	for star: int in [1, 3]:
		var b := Fixture.make([{"def": "node_brave", "pos": Vector2(0, -3), "star": star}, {"def": "test_hitter", "pos": Vector2(2, -3)},
			{"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
		var v: BUnit = b.units[0]
		var ally: BUnit = b.units[1]
		var foe: BUnit = b.units[2]
		_calm(v)
		_calm(ally)
		b.start()
		_run(b, GC.START_DELAY + 0.1)
		var atk0: float = v.get_stats().attack_power
		var as0: float = v.get_stats().attack_speed_multiplier
		b.pipeline.fx.apply_status(ally, v, {"status_id": "t_buff", "flags": ["buff"], "duration": 0.0, "stats": {"attack_power": {"flat": 100.0}}})
		t.near(v.get_stats().attack_power - atk0, 100.0 * _y(star), 0.01, "★%d a teammate's +100 attack becomes +%d" % [star, int(100.0 * _y(star))])
		b.pipeline.fx.apply_status(ally, v, {"status_id": "t_buff2", "flags": ["buff"], "duration": 0.0, "max_stacks": 3, "add_stacks": 2,
			"stats_by_star": {"attack_speed_multiplier": {"pct": {"1": 0.05, "2": 0.05, "3": 0.05}}}})
		t.near(v.get_stats().attack_speed_multiplier, (1.0 + 0.10 * _y(star)) * as0 / 1.0, 0.0001, "★%d per-stack stat buffs too" % star)
		var atk1: float = v.get_stats().attack_power
		b.pipeline.fx.apply_status(v, v, {"status_id": "t_self", "flags": ["buff"], "duration": 0.0, "stats": {"attack_power": {"flat": 50.0}}})
		t.near(v.get_stats().attack_power - atk1, 50.0, 0.01, "★%d her own buffs aren't amplified" % star)
		var hp1: float = foe.get_stats().attack_power
		b.pipeline.fx.apply_status(ally, ally, {"status_id": "t_ally_self", "flags": ["buff"], "duration": 0.0, "stats": {"attack_power": {"flat": 100.0}}})
		t.near(ally.get_stats().attack_power, 200.0, 0.01, "★%d only buffs on her are amplified" % star)
		t.near(foe.get_stats().attack_power, hp1, 0.01, "enemies unaffected")


func test_future_spreads_her_boosts_when_she_falls(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_brave", "pos": Vector2(0, -3)}, {"def": "test_hitter", "pos": Vector2(2, -3)},
		{"def": "test_hitter", "pos": Vector2(-2, -3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var v: BUnit = b.units[0]
	var a1: BUnit = b.units[1]
	var a2: BUnit = b.units[2]
	var foe: BUnit = b.units[3]
	for u: BUnit in [v, a1, a2]:
		_calm(u)
	b.start()
	_run(b, GC.START_DELAY + 0.1)
	b.pipeline.fx.apply_status(a1, v, {"status_id": "t_buff", "flags": ["buff", "dispellable"], "duration": 3.0, "stats": {"attack_power": {"flat": 100.0}}})
	b.pipeline.fx.apply_status(v, v, {"status_id": "t_self", "flags": ["buff"], "duration": 0.0, "stats": {"defense": {"flat": 20.0}}})
	b.pipeline.fx.apply_status(foe, v, {"status_id": "t_bad", "flags": ["debuff"], "duration": 0.0, "stats": {"defense": {"flat": -50.0}}})
	var atk1: float = a1.get_stats().attack_power
	var def2: float = a2.get_stats().defense
	v.hp = 0.0
	b.pipeline.fx.try_kill(v, foe)
	t.ok(not v.alive, "she falls")
	var fu: BStatus = a2.get_status("brave_future")
	t.ok(fu != null, "Future spreads to every teammate")
	t.near(a1.get_stats().attack_power - atk1, 100.0 * _y(1), 0.01, "with the amplified teammate buff (+%d attack)" % int(100.0 * _y(1)))
	t.near(a2.get_stats().defense - def2, 20.0, 0.01, "and her own buffs (+20 armor)")
	t.ok(fu != null and fu.expires_at < 0.0 and fu.flags.has("no_dispel"), "lasts forever, can't be dispelled")
	_run(b, b.time + 4.0)
	t.near(a1.get_stats().attack_power - atk1, 100.0 * _y(1), 0.01, "still there after the original buff would have expired")


func test_fly_again_heals_her_and_revives_the_strongest_fallen(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_brave", "pos": Vector2(0, -3), "weapon": "hope"}, {"def": "node_shielder", "pos": Vector2(2, -3)},
		{"def": "node_samurai", "pos": Vector2(-2, -3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}])
	var v: BUnit = b.units[0]
	var low: BUnit = b.units[1]
	var top: BUnit = b.units[2]
	var foe: BUnit = b.units[3]
	for u: BUnit in [v, low, top]:
		_calm(u)
	b.start()
	_run(b, GC.START_DELAY + 1.0)
	for d: BUnit in [low, top]:
		d.hp = 0.0
		b.pipeline.fx.try_kill(d, foe)
	t.ok(not low.alive and not top.alive, "two teammates down")
	v.hp = 500.0
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 10.1)
	var ap: float = v.get_stats().ability_power
	var val: float = _trig("node_brave_fly").flat_for(1) * (1.0 + ap / 100.0)
	var n: float = Fixture.catalog().get_equipment("hope").abilities[0].value_multiplier
	var heal: float = val * n * (1.0 + v.get_stats().healing_done_pct)
	t.eq(_of(evs, "hope_revive").size(), 1, "10 s: one revive")
	t.ok(top.alive and not low.alive, "the fallen teammate with the highest attack comes back")
	t.near(top.hp, minf(top.get_stats().max_health, heal), 1.0, "with n × trigger value health (%.0f)" % heal)
	t.near(v.hp, 500.0 + heal, 1.0, "and she heals herself the same")
	evs = _run(b, GC.START_DELAY + 20.1)
	t.ok(low.alive, "10 s later the next one")


func test_fly_again_with_a_damaging_weapon_hits_herself(t: TestCtx) -> void:
	# 触发器接受非常规用法(用户 2026-10-07)：会伤人的武器效果(奥术刃)配上这个触发器，照样打在她自己身上；已阵亡的队友打不到
	var b := Fixture.make([{"def": "node_brave", "pos": Vector2(0, -3), "weapon": "sample_arcane_edge"}, {"def": "test_hitter", "pos": Vector2(2, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}])
	var v: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	_calm(v)
	_calm(ally)
	b.start()
	_run(b, GC.START_DELAY + 1.0)
	ally.hp = 0.0
	b.pipeline.fx.try_kill(ally, b.units[2])
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 10.2)
	var self_hits: Array[Dictionary] = _of(evs, "damage").filter(func(e: Dictionary) -> bool: return e["dst"] == v and e["surface"] == "equipment")
	t.eq(self_hits.size(), 1, "the damaging weapon effect hits herself")
	t.ok(not ally.alive, "the fallen teammate stays down (nothing to revive it)")


func test_optional_slay_rules(t: TestCtx) -> void:
	# 可选的收紧写法(能力配置)：slay_first_only = 只有开战那一下直接击杀；slay_below = 目标生命比例不高于它才直接击杀
	var pa: AbilityDef = _def().passive_by_id("node_brave_holy")
	var keep: Dictionary = pa.effect_config.duplicate(true)
	for mode: String in ["first", "below"]:
		pa.effect_config = keep.duplicate(true)
		if mode == "first":
			pa.effect_config["slay_first_only"] = true
		else:
			pa.effect_config["slay_below"] = 0.5
		var b := Fixture.make([{"def": "node_brave", "pos": Vector2(0, -3)}, {"def": "mob_guardian", "team": 1, "pos": Vector2(0, 6)},
			{"def": "mob_guardian", "team": 1, "pos": Vector2(5, 9)}])
		var v: BUnit = b.units[0]
		var m1: BUnit = b.units[1]
		var m2: BUnit = b.units[2]
		_calm(v)
		b.start()
		_run(b, GC.START_DELAY + 0.3)
		if mode == "first":
			t.ok(not m1.alive, "first-only: the opening strike still slays")
			v.target = m2
			_run(b, GC.START_DELAY + 5.45)
			t.ok(m2.alive and m2.hp < m2.get_stats().max_health, "first-only: later strikes only deal % damage")
		else:
			t.ok(m1.alive and m1.hp < m1.get_stats().max_health, "≤50%: a healthy monster only takes % damage")
			m1.hp = m1.get_stats().max_health * 0.45
			v.target = m1
			_run(b, GC.START_DELAY + 5.45)
			t.ok(not m1.alive, "≤50%: once it's at half health, slain")
	pa.effect_config = keep


func test_texts_match_data(t: TestCtx) -> void:
	var tr: TriggerDef = _trig("node_brave_holy")
	var sx := "{★%d%%/%d%%/%d%%}" % [int(round(tr.flat_for(1) * 100.0)), int(round(tr.flat_for(2) * 100.0)), int(round(tr.flat_for(3) * 100.0))]
	var sy := "{★%s/%s/%s}" % [Describe.fmt(_y(1)), Describe.fmt(_y(2)), Describe.fmt(_y(3))]
	var fl: TriggerDef = _trig("node_brave_fly")
	var sz := "{★%d%%/%d%%/%d%%}" % [int(fl.flat_for(1)), int(fl.flat_for(2)), int(fl.flat_for(3))]
	var e: EquipmentDef = Fixture.catalog().get_equipment("hope")
	for lang: String in ["zh", "en"]:
		t.ok(Loc.t_in(lang, "unit.node_brave.passive.node_brave_holy").contains(sx), "%s: holy sword %s" % [lang, sx])
		t.ok(Loc.t_in(lang, "unit.node_brave.passive.node_brave_dream").contains(sy), "%s: dream %s" % [lang, sy])
		t.ok(Loc.t_in(lang, "unit.node_brave.trigger.node_brave_fly").contains(sz), "%s: fly again %s" % [lang, sz])
		var wd: String = Loc.t_in(lang, "equipment.hope.desc")
		t.ok(wd.contains("%d" % int(e.flat_mods["ability_power"])) and wd.contains("%d" % int(e.flat_mods["max_health"])) and wd.contains(Describe.fmt(e.abilities[0].value_multiplier)),
			"%s: Hope numbers" % lang)
