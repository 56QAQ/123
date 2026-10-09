extends RefCounted
## 重构版舞星节点：初星的偶像(开战召唤护星节点；已有就把星级加给他，最高 9 星)、偶像的舞与歌(2 星：双持 → 拉着护星节点冲刺、
## 护星节点减伤 + 嘲讽；攻击距离 > 2 米 → 所有队友按增幅加攻速攻击力)、偶像的笑与泪(血量 > 50% 治所有队友，否则打当前目标)、
## 专属武器舞扇(攻击距离 +2、远了发魔力飞环；【基本】【双模】【群攻 10】)。护星节点：黑色、1 费坦克模版、不享受羁绊。


func _warriors(b: Battle, team: int = 0) -> Array[BUnit]:
	var r: Array[BUnit] = []
	for u: BUnit in b.units:
		if u.alive and u.team == team and u.def.id == "node_warrior":
			r.append(u)
	return r


func _step_until(b: Battle, type: String, n: int = 1, cap: int = 400) -> void:
	var g := 0
	while Fixture.events_of(b, type).size() < n and g < cap:
		b.step()
		g += 1


func test_idol_summons_one_warrior_and_shared_stars_add_up(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_dancer", "pos": Vector2(-1, 0), "star": 2}, {"def": "node_dancer", "pos": Vector2(1, 0), "star": 1},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}])
	b.start()
	var ws: Array[BUnit] = _warriors(b)
	t.eq(ws.size(), 1, "only one Node Warrior on the field")
	t.eq(ws[0].star, 3, "his star = 2★ + 1★ = 3★")
	t.eq((ws[0].meta.get("summoners", []) as Array).size(), 2, "he counts as both dancers' summon")
	t.near(ws[0].get_stats().max_health, 1300.0 * GC.star_mult(3), 0.5, "stats rescale to the new star (full health)")
	t.near(ws[0].hp, ws[0].get_stats().max_health, 0.5, "full health")
	var specs: Array = []
	for i in range(4):
		specs.append({"def": "node_dancer", "pos": Vector2(-3 + 2 * i, 0), "star": 3})
	specs.append({"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)})
	var b2 := Fixture.make(specs)
	b2.start()
	t.eq(_warriors(b2)[0].star, 9, "capped at 9★")
	t.ok(GC.star_mult(9) - GC.star_mult(8) > GC.star_mult(4) - GC.star_mult(3), "stars above 4 give bigger steps")


func test_warrior_is_a_black_1_cost_tank_summon(t: TestCtx) -> void:
	var d: UnitDef = Fixture.catalog().get_unit("node_warrior")
	t.eq(d.faction_id, "black", "black")
	t.ok(d.summon_only and not d.available_in_shop, "summon only, not in the shop")
	t.near(d.base_stats.max_health, 1300.0, 0.1, "1-cost tank template")
	t.eq(d.weapon_classes, ["sword"] as Array[String], "sword only")


func test_dance_dashes_with_the_warrior_from_2_stars_with_twin_blades(t: TestCtx) -> void:
	for spec: Array in [[1, "", 0], [2, "", 2], [2, "basic_focus", 0], [3, "dance_fans", 2]]:
		var b := Fixture.make([{"def": "node_dancer", "pos": Vector2.ZERO, "star": spec[0], "weapon": spec[1]},
			{"def": "test_hitter", "team": 1, "pos": Vector2(0, 7.5)}, {"def": "test_hitter", "team": 1, "pos": Vector2(1, 8)}])
		var u: BUnit = b.units[0]
		b.start()
		for i in range(int((GC.START_DELAY + 1.0) / GC.SIM_DT)):
			b.step()
		var n: int = Fixture.events_of(b, "dash_start").size()
		t.eq(n, int(spec[2]), "%d★ %s: %d dash events" % [spec[0], spec[1] if spec[1] != "" else "basic dual", spec[2]])
		if int(spec[2]) > 0:
			var w: BUnit = _warriors(b)[0]
			t.ok(u.pos.y > 3.0 and w.pos.y > 2.5, "both moved forward (%s / %s)" % [str(u.pos), str(w.pos)])
			var amp: int = 2 if int(spec[0]) < 3 else 4
			t.near(w.get_stats().damage_taken_pct, 0.05 * amp, 0.0001, "warrior damage reduction = amplify × 5% (damage_taken_pct > 0 = takes less)")
			t.ok(b.units[1].forced_target == w and b.units[2].forced_target == w, "enemies nearby are taunted by the warrior")


func _trig(id: String) -> TriggerDef:
	for tr: TriggerDef in Fixture.catalog().get_unit("node_dancer").triggers:
		if tr.id == id:
			return tr
	return null


func test_song_buffs_teammates_only_with_range_over_2_m(t: TestCtx) -> void:
	var song: TriggerDef = _trig("node_dancer_song")
	for spec: Array in [[2, "dance_fans", 2.0 * song.ratio_for(2)], [3, "dance_fans", 4.0 * song.ratio_for(3)], [2, "", 0.0], [1, "dance_fans", 0.0]]:
		var b := Fixture.make([{"def": "node_dancer", "pos": Vector2.ZERO, "star": spec[0], "weapon": spec[1]},
			{"def": "test_hitter", "pos": Vector2(2, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 9)}])
		var ally: BUnit = b.units[1]
		var as0: float = ally.get_stats().attack_speed_multiplier
		var ap0: float = ally.get_stats().attack_power
		b.start()
		var k: float = float(spec[2])
		t.near(ally.get_stats().attack_speed_multiplier, as0 * (1.0 + k), 0.001, "%d★ %s: teammate attack speed +%d%%" % [spec[0], spec[1], int(k * 100)])
		t.near(ally.get_stats().attack_power, ap0 * (1.0 + k), 0.01, "…and attack +%d%%" % int(k * 100))
		t.ok(b.units[0].get_status("idol_song_as") == null, "not on herself")


func test_smile_heals_teammates_above_half_and_tears_strike_below(t: TestCtx) -> void:
	for star: int in [1, 2]:
		var b := Fixture.make([{"def": "node_dancer", "pos": Vector2.ZERO, "star": star, "weapon": "dance_fans"},
			{"def": "test_hitter", "pos": Vector2(-1.5, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.2)}])
		var u: BUnit = b.units[0]
		var ally: BUnit = b.units[1]
		b.start()
		u.base.crit_chance = 0.0
		u.mark_dirty()
		ally.hp = ally.get_stats().max_health * 0.5
		var h0: float = ally.hp
		b.pipeline.normal_attack(u, b.units[b.units.size() - 1] if b.units[b.units.size() - 1].team == 1 else b.units[2])
		var amp: int = 0 if star == 1 else 2
		var y: float = _trig("node_dancer_smile").ratio_for(star)
		var z: float = Fixture.catalog().get_equipment("dance_fans").abilities[0].effect_config["ally_effect"]["value_multiplier"]
		t.near(ally.hp - h0, float(amp + 1) * y * z, 0.05, "%d★ above half: heals teammates for (amplify + 1) × y × z = %.0f" % [star, float(amp + 1) * y * z])
		var dummy: BUnit = null
		for x: BUnit in b.units:
			if x.team == 1:
				dummy = x
		u.hp = u.get_stats().max_health * 0.4
		var n0: int = Fixture.events_of(b, "damage", "equipment").size()
		b.pipeline.normal_attack(u, dummy)
		var ds: Array[Dictionary] = Fixture.events_of(b, "damage", "equipment")
		t.eq(ds.size() - n0, 1, "%d★ at 40%%: strikes the current target instead" % star)
		t.eq(str(ds[-1]["kind"]), "true", "true damage")
		var z2: float = Fixture.catalog().get_equipment("dance_fans").abilities[0].effect_config["enemy_effect"]["value_multiplier"]
		t.near(float(ds[-1]["amount"]), u.get_stats().attack_power * 0.15 * float(amp + 1) * z2, 0.05, "attack × 0.15 × (amplify + 1) × z")


func test_fans_fling_rings_from_afar(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_dancer", "pos": Vector2.ZERO, "weapon": "dance_fans"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 3.5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.2, 0)}])
	var u: BUnit = b.units[0]
	t.ok(u.get_stats().range_meters() > 4.0, "attack range +2 (%.2f m)" % u.get_stats().range_meters())
	b.deliver_normal_attack(u, b.units[1])
	t.eq(b.projectiles.size(), 1, "far target: a projectile")
	t.eq(str(b.projectiles[0]["kind"]), "fan_ring", "a magic ring")
	b.deliver_normal_attack(u, b.units[2])
	t.eq(b.projectiles.size(), 1, "close target: hit directly")
