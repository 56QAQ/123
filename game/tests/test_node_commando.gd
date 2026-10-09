extends RefCounted
## 止息节点：画上句点(索敌目标没有标定 → 突进：把它从它正在打的人那里击退、冲到它背后恰好够得着的位置、立刻普攻、强制它索敌自己、施加【标定】；
## 标定 = 承受伤害 +x% 增幅，累计 3 秒 → 攻击力最高的远程友军打出一发免费普攻弹道(不消耗资源、不算攻击、不打断瞄准)，命中时消耗)、
## 掩护支援(2 星：近战敌人靠近那个远程友军 2.8 米以内 → 改为索敌它)、突击(发动突进时触发)、专武黑色任务(即时普攻 + 战场感知：普攻闪避)。


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


func _still(u: BUnit) -> void:
	u.base.move_speed = 0.0
	u.mark_dirty()


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = cat.get_unit("node_commando")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model], [2, "yellow", "security", "warrior", "dual", "captain"],
		"rarity 2, yellow, Security, warrior, dual-wield melee, the captain model")
	t.eq(d.weapon_classes, ["dual", "crossbow", "rifle", "pistols", "sword"] as Array[String], "one-handed / two-handed / dual ranged, one-handed melee")
	var e: EquipmentDef = cat.get_equipment("black_mission")
	t.eq([e.class_id, e.color_id, e.cost, e.owner, e.projectile], ["crossbow", "black", 2, "node_commando", "bullet"], "Black Mission: one-handed ranged, black, rarity 2, hers")
	t.eq([float(e.flat_mods.get("magic_resistance", 0.0)), float(e.flat_mods.get("defense", 0.0))], [15.0, 15.0], "+15 MR, +15 armor")
	var ab: AbilityDef = e.abilities[0]
	t.eq([ab.cooldown, Pipeline.kw_value(null, ab, "charged")], [2.0, 3], "2 s cooldown 【Charged 3】")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_lunge_knocks_back_dashes_behind_attacks_taunts_and_marks(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_commando", "pos": Vector2(0, -5)}, {"def": "test_dummy", "pos": Vector2(0, -1.5)},
		{"def": "test_hitter", "team": 1, "pos": Vector2(0, 0)}])
	var c: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	b.start()
	_still(foe)
	foe.target = ally
	var p0: Vector2 = foe.pos
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 0.3)
	var ls: Array[Dictionary] = _of(evs, "lunge_start")
	t.eq(ls.size(), 1, "she lunges at the target she picked")
	t.ok(not ls.is_empty() and str(ls[0]["style"]) == "flip", "melee weapon: flips over its head")
	var kb: Array[Dictionary] = _of(evs, "knockback")
	t.ok(not kb.is_empty() and (kb[0]["to"] as Vector2).y > p0.y + 1.9, "knocked 2 m away from the ally it was attacking")
	var evs2: Array[Dictionary] = _run(b, b.time + 1.0)
	t.eq(_of(evs2, "lunge_end").size(), 1, "lands")
	t.ok(c.pos.y > foe.pos.y, "behind it (on the far side from the ally)")
	t.ok(BattleAI.in_reach(c, foe, c.pos.distance_to(foe.pos), c.get_stats().range_meters()), "right within her reach")
	var hit := false
	for e: Dictionary in _of(evs2, "damage"):
		if e["src"] == c and e["dst"] == foe and str(e.get("surface", "")) == "normal_attack":
			hit = true
	t.ok(hit, "attacks at once")
	t.eq(foe.forced_target, c, "forced to target her")
	var st: BStatus = foe.get_status("commando_mark")
	t.ok(st != null and st.has_flag("debuff") and not st.has_flag("dispellable"), "【Marked】: an undispellable debuff")
	t.near(foe.get_stats().damage_taken_amp, 0.15, 0.0001, "1★: +15% damage taken amplification")
	# 标定在：不再突进
	var evs3: Array[Dictionary] = _run(b, b.time + 1.0)
	t.eq(_of(evs3, "lunge_start").size(), 0, "no new lunge while it's marked")


func test_mark_amplifies_damage_taken(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2(0, -5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 5)}])
	var foe: BUnit = b.units[1]
	b.start()
	var h0: float = foe.hp
	b.pipeline.fx.damage(b.units[0], foe, 100.0, "true", {"surface": "other"})
	var plain: float = h0 - foe.hp
	b.pipeline.fx.apply_status(b.units[0], foe, {"status_id": "commando_mark", "max_stacks": 1, "flags": ["debuff", "no_dispel"],
		"stats": {"damage_taken_amp": {"flat": 0.2}}})
	var h1: float = foe.hp
	b.pipeline.fx.damage(b.units[0], foe, 100.0, "true", {"surface": "other"})
	t.near(h1 - foe.hp, plain * 1.2, 0.01, "+20% amplification on the damage it takes (same zone as the attacker's amps)")


func test_free_shot_after_three_seconds_keeps_the_snipers_aim(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_commando", "pos": Vector2(-1, -5)}, {"def": "node_sniper", "pos": Vector2(1, -3.0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 0)}])
	var c: BUnit = b.units[0]
	var sn: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	b.start()
	_still(sn)
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 1.2)
	var st: BStatus = foe.get_status("commando_mark")
	t.ok(st != null, "marked")
	var ammo0: int = b.pipeline.ammo(sn).stacks if b.pipeline.ammo(sn) != null else -1
	var t_mark: float = float(st.meta.get("t0", 0.0)) if st != null else 0.0
	var evs2: Array[Dictionary] = _run(b, t_mark + 3.3)
	var mv: Array[Dictionary] = _of(evs2, "mark_volley")
	t.eq(mv.size(), 1, "3 s later: one free shot")
	t.ok(not mv.is_empty() and mv[0]["shooter"] == sn, "from the ranged ally with the highest attack (the sniper)")
	t.ok(not mv.is_empty() and float(mv[0]["chant_scale"]) > 1.5, "carrying the aim she has built up so far (×%.2f)" % (float(mv[0]["chant_scale"]) if not mv.is_empty() else 0.0))
	t.eq(sn.phase, "draw", "and she keeps aiming (not counted as an attack)")
	t.eq(b.pipeline.ammo(sn).stacks if b.pipeline.ammo(sn) != null else -1, ammo0, "no ammo spent")
	t.eq(_of(evs2, "mark_consumed").size(), 1, "the hit consumes the mark")
	t.eq(_of(evs2, "lunge_start").size(), 1, "her target is unmarked again → lunges again")


func test_covering_support_retargets_onto_a_diver(t: TestCtx) -> void:
	for star: int in [1, 2]:
		var b := Fixture.make([{"def": "node_commando", "pos": Vector2(0, -2), "star": star}, {"def": "node_archer", "pos": Vector2(4, -6)},
			{"def": "test_dummy", "team": 1, "pos": Vector2(0, 1)}, {"def": "test_hitter", "team": 1, "pos": Vector2(6.5, -2)}])
		var c: BUnit = b.units[0]
		var archer: BUnit = b.units[1]
		var near: BUnit = b.units[2]
		var diver: BUnit = b.units[3]
		b.start()
		_still(archer)
		_still(diver)
		_run(b, GC.START_DELAY + 1.5)
		t.eq(c.target, near, "%d★: busy with the nearest enemy" % star)
		diver.pos = archer.pos + Vector2(1.8, 0)
		var evs: Array[Dictionary] = _run(b, b.time + 1.0)
		if star == 1:
			t.eq(_of(evs, "cover").size(), 0, "1★: no Covering Support yet")
			continue
		t.eq(_of(evs, "cover").size(), 1, "2★: a melee enemy within 2.8 m of the archer → switches to it")
		t.eq(c.target, diver, "now targeting the diver")
		t.ok(not _of(evs, "lunge_start").is_empty(), "and lunges at it (it isn't marked)")


func test_assault_triggers_black_mission_and_battle_sense(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_commando", "pos": Vector2(0, -5), "weapon": "black_mission"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 2)}])
	var c: BUnit = b.units[0]
	b.start()
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 0.3)
	t.ok(not _of(evs, "lunge_start").is_empty() and str(_of(evs, "lunge_start")[0]["style"]) == "slide", "ranged weapon: slides past its side")
	t.eq(_of(evs, "instant_shot").size(), 1, "Assault (on lunge) fires Black Mission: an instant normal attack")
	var bs: BStatus = c.get_status("battle_sense")
	t.ok(bs != null and bs.has_flag("dispellable"), "【Battle Sense】(dispellable)")
	var val: float = c.get_stats().attack_power * 1.0
	t.near(c.get_stats().na_dodge, val / 10.0 * 0.01, 0.0005, "1% dodge per 10 trigger value (attack × 100%% = %d → %.1f%%)" % [int(val), val / 10.0])
	t.near(bs.expires_at - b.time, 3.0, 0.3, "3 s")


func test_dodge_chance_avoids_normal_attacks(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.2)}])
	var h: BUnit = b.units[0]
	var d: BUnit = b.units[1]
	b.start()
	d.base.na_dodge = 0.5
	d.mark_dirty()
	var dodged := 0
	for i in range(200):
		b.pipeline.normal_attack(h, d)
		dodged += _of(b.poll_events(), "dodge").size()
	t.ok(dodged > 70 and dodged < 130, "50%% dodge chance dodges about half (%d / 200)" % dodged)
