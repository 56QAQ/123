extends RefCounted
## 锁芯节点：万物闭锁(每普攻 x1 次，智能选一个圆，里面的敌人受到魔法伤害 + 眩晕；开局已攒 x8 次计数)、
## 血色仪式(不用 2 星：自己每秒受到真实伤害、无法被治疗；我方施加的【眩晕】持续时间 +y%)、
## 触发器 打开深空之门(场上累计被眩晕的时间每满 z1 秒；目标 = 所有曾被眩晕过的敌人)；
## 专武开与闭(【群攻 5】：把目标往它们的中心拉到一起，再眩晕 每 n 点触发数值 1 秒)。


func _def() -> UnitDef:
	return Fixture.catalog().get_unit("node_cultist")


func _trig(id: String) -> TriggerDef:
	for tr: TriggerDef in _def().triggers:
		if tr.id == id:
			return tr
	return null


func _calm(v: BUnit) -> void:
	v.attack_cd = 1.0e9
	v.base.move_speed = 0.0
	v.base.crit_chance = 0.0
	v.mark_dirty()


func _run(b: Battle, sec: float) -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	while b.time < sec - 0.0001 and b.state != "ended":
		b.step()
		all.append_array(b.poll_events())
	return all


static func _of(evs: Array[Dictionary], type: String) -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for e: Dictionary in evs:
		if e.get("t") == type:
			r.append(e)
	return r


func _amp(star: int) -> float:
	return float(_def().passive_by_id("node_cultist_rite").effect_config["meta_by_star"]["stun_amp"][str(star)])


func _stun_left(b: Battle, u: BUnit) -> float:
	var st: BStatus = u.get_status("stun")
	return st.expires_at - b.time if st != null else 0.0


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = _def()
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model], [3, "green", "research", "caster", "polearm", "keeper"],
		"rarity 3, green, Research, caster, polearm, keeper model")
	t.eq(d.weapon_classes, ["polearm", "heavy"] as Array[String], "can equip a two-handed heavy weapon")
	t.eq(d.passive_by_id("node_cultist_rite").unlock_star, 1, "Blood Rite needs no second star")
	t.ok(int(_trig("node_cultist_lock").extra.get("count_init", 0)) > 0, "Lock All Things starts with some attacks already counted")
	var e: EquipmentDef = cat.get_equipment("open_shut_key")
	t.eq([e.class_id, e.color_id, e.cost, e.owner, e.model], ["polearm", "green", 3, "node_cultist", "key"], "Open and Shut: polearm, green, 3, hers")
	t.ok(e.abilities[0].cooldown == 6.0 and e.abilities[0].keyword_value("multi_attack", 1) == 5, "6 s cooldown 【Multi 5】")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_lock_starts_precounted(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_cultist", "pos": Vector2(0, -2)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0)}])
	var a: BUnit = b.units[0]
	b.start()
	_calm(a)
	var th: int = _trig("node_cultist_lock").threshold_for(1)
	var init: int = int(_trig("node_cultist_lock").extra["count_init"])
	t.eq(int(a.counters.get("node_cultist_lock", 0)), init, "%d of %d attacks already counted at the start" % [init, th])
	b.poll_events()
	for i in range(th - init - 1):
		b.pipeline.emit("OnNormalAttackPerform", a, b.units[1], 0.0, ["normal_attack_perform"], {})
	t.eq(_of(b.poll_events(), "lock_cast").size(), 0, "attack %d: nothing yet" % (th - 1))
	b.pipeline.emit("OnNormalAttackPerform", a, b.units[1], 0.0, ["normal_attack_perform"], {})
	var evs0: Array[Dictionary] = b.poll_events()
	t.eq(_of(evs0, "lock_cast").size(), 1, "attack %d: Lock All Things" % th)
	t.eq(_of(evs0, "damage").filter(func(e: Dictionary) -> bool: return e["dst"] == a).size(), 0, "and the trigger never hits herself")
	for i in range(th - 1):
		b.pipeline.emit("OnNormalAttackPerform", a, b.units[1], 0.0, ["normal_attack_perform"], {})
	t.eq(_of(b.poll_events(), "lock_cast").size(), 0, "then every %d attacks again" % th)
	b.pipeline.emit("OnNormalAttackPerform", a, b.units[1], 0.0, ["normal_attack_perform"], {})
	t.eq(_of(b.poll_events(), "lock_cast").size(), 1, "the next lock")


func test_lock_picks_the_crowded_circle(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_cultist", "pos": Vector2(0, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(-1, 4)}, {"def": "test_dummy", "team": 1, "pos": Vector2(-0.2, 4.4)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(-1.4, 5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(6, -2)}])
	var a: BUnit = b.units[0]
	b.start()
	_calm(a)
	_run(b, GC.START_DELAY + 0.05)
	var ab: AbilityDef = _def().passive_by_id("node_cultist_lock")
	var hp0: Array[float] = []
	for u: BUnit in b.units:
		hp0.append(u.hp)
	b.pipeline._lock_all(a, 300.0, ab, {"cfg": ab.effect_config})
	var evs: Array[Dictionary] = _run(b, b.time + 0.45)
	var cl: Array[Dictionary] = _of(evs, "lock_close")
	t.eq(cl.size(), 1, "the lock closes after its short windup")
	t.eq((cl[0]["targets"] as Array).size(), 3, "it covers the three bunched enemies")
	var stun: float = float(ab.effect_config["stun_by_star"]["1"]) * (1.0 + _amp(1))
	for i in [1, 2, 3]:
		t.ok(b.units[i].hp < hp0[i] - 100.0, "enemy %d takes the magic damage" % i)
		t.near(_stun_left(b, b.units[i]), stun - 0.1, 0.06, "and is stunned %.2f s (Blood Rite +%d%%)" % [stun, int(_amp(1) * 100)])
	t.ok(b.units[4].hp == hp0[4] and b.units[4].get_status("stun") == null, "the lone enemy far away is untouched")


func test_blood_rite(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_cultist", "pos": Vector2(0, -3), "star": 2}, {"def": "test_hitter", "pos": Vector2(2, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var a: BUnit = b.units[0]
	b.start()
	_calm(a)
	t.ok(a.get_status("blood_rite") != null, "she starts the battle with Blood Rite")
	t.near(b.stun_amp(0), _amp(2), 0.001, "★2: her team's stuns last +%d%%" % int(_amp(2) * 100))
	t.eq(b.stun_amp(1), 0.0, "the other team gets nothing")
	var hp0: float = a.hp
	_run(b, GC.START_DELAY + 3.05)
	var bleed: float = float(_def().passive_by_id("node_cultist_rite").effect_config["dot"]["amount"])
	t.ok(hp0 - a.hp >= bleed * 3.0 - 0.5, "she loses %.0f true damage a second" % bleed)
	var hp1: float = a.hp
	b.pipeline.fx.heal(b.units[1], a, 500.0, {"raw": true})
	t.eq(a.hp, hp1, "and can't be healed")
	b.pipeline.fx.dispel(b.units[1], a, "debuff", 5)
	t.ok(a.get_status("blood_rite") != null, "it can't be dispelled")
	# 我方施加的眩晕变长；被对面施加的不变
	b.pipeline.fx.apply_status(b.units[1], b.units[2], {"status_id": "stun", "flags": ["debuff", "dispellable", "stun"], "max_stacks": 1, "duration": 2.0})
	t.near(_stun_left(b, b.units[2]), 2.0 * (1.0 + _amp(2)), 0.01, "a teammate's 2 s stun lasts %.1f s" % (2.0 * (1.0 + _amp(2))))
	b.pipeline.fx.apply_status(b.units[2], b.units[1], {"status_id": "stun", "flags": ["debuff", "dispellable", "stun"], "max_stacks": 1, "duration": 2.0})
	t.near(_stun_left(b, b.units[1]), 2.0, 0.01, "an enemy's stun on us is unchanged")
	a.hp = 0.0
	b.pipeline.fx.try_kill(a, null)
	t.eq(b.stun_amp(0), 0.0, "only while she's on the field")


func test_stun_refresh_keeps_the_longer(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2(0, -3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}])
	b.start()
	var e: BUnit = b.units[1]
	var cfg := {"status_id": "stun", "flags": ["debuff", "dispellable", "stun"], "max_stacks": 1, "duration": 3.0}
	b.pipeline.fx.apply_status(b.units[0], e, cfg)
	cfg["duration"] = 1.0
	b.pipeline.fx.apply_status(b.units[0], e, cfg)
	t.near(_stun_left(b, e), 3.0, 0.01, "a shorter stun doesn't cut a longer one short")
	cfg["duration"] = 5.0
	b.pipeline.fx.apply_status(b.units[0], e, cfg)
	t.near(_stun_left(b, e), 5.0, 0.01, "a longer one extends it")
	t.ok(bool(e.meta.get("was_stunned", false)), "and the unit is remembered as stunned")


func test_gate_opens_on_stun_time(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_cultist", "pos": Vector2(0, -4), "weapon": "open_shut_key"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(-3, 3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 5)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(3, 3.5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(5, -3)}])
	var a: BUnit = b.units[0]
	b.start()
	_calm(a)
	_run(b, GC.START_DELAY + 0.05)
	# 三个敌人各眩晕 z1 / 3 + 0.2 秒(施加者不是她那一队：不吃血色仪式)= 场上累计 z1 秒出头
	var z1: int = _trig("node_cultist_gate").threshold_for(1)
	var each: float = float(z1) / 3.0
	for i in [1, 2, 3]:
		b.pipeline.fx.apply_status(null, b.units[i], {"status_id": "stun", "flags": ["debuff", "dispellable", "stun"], "max_stacks": 1, "duration": each + 0.2})
	var t0: float = b.time
	var evs: Array[Dictionary] = _run(b, t0 + each - 0.1)
	t.eq(_of(evs, "key_gate").size(), 0, "3 stunned for %.1f s = %.1f s: not yet" % [each - 0.1, 3.0 * (each - 0.1)])
	evs = _run(b, t0 + each + 0.08)
	var g: Array[Dictionary] = _of(evs, "key_gate")
	t.eq(g.size(), 1, "the field's stun time reaches %d s: the Deep-Space Gate opens" % z1)
	if g.is_empty():
		return
	t.near(b.stun_time, 3.0 * (each + 0.08), 0.2, "stun time is summed over every stunned unit")
	var tg: Array = g[0]["targets"]
	t.eq(tg.size(), 3, "targets = every enemy that has been stunned")
	t.ok(not tg.has(b.units[4]), "never-stunned enemies are left alone")
	_run(b, b.time + 0.35)
	var gp: Vector2 = g[0]["pos"]
	for i in [1, 2, 3]:
		t.ok(b.units[i].pos.distance_to(gp) < 0.9, "enemy %d is yanked to the gathering point (%.2f m)" % [i, b.units[i].pos.distance_to(gp)])
	var z: float = _trig("node_cultist_gate").flat_for(1)
	var n: float = float(Fixture.catalog().get_equipment("open_shut_key").abilities[0].effect_config["n"])
	var want: float = z / n * (1.0 + _amp(1)) - (b.time - float(g[0]["time"]))
	t.near(_stun_left(b, b.units[2]), want, 0.06, "and stunned %.0f / %.0f s × Blood Rite" % [z, n])
