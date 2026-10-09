extends RefCounted
## 圣战节点：裂地猛击(每 5 秒、身边有敌人才计时，智能锥形魔法伤害 x × (100 + 法强)%，破坏锥形里的地形)、
## 圣疗(2 星：每 4 秒、有人掉血才计时，回复生命比例最低的友军 y × (100 + 法强)%)、
## 神圣战争(裂地猛击造成伤害时，目标 = 受到伤害的敌人，z × (100 + 法强)%)；专武大锤(【群攻 4】：每 n 点触发数值眩晕 1 秒)。


func _def() -> UnitDef:
	return Fixture.catalog().get_unit("node_paladin")


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


func _cell(p: Vector2) -> Vector2i:
	return GC.world_to_cell(p)


func _obs(p: Vector2, style: String = "rubble_a", terrain: String = "") -> Dictionary:
	var c: Vector2i = _cell(p)
	var d := {"x": c.x, "y": c.y, "w": 1, "h": 1, "kind": "low", "style": style}
	if terrain != "":
		d["terrain"] = terrain
	return d


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = _def()
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class, d.model], [3, "blue", "security", "warrior", "heavy", "paladin"],
		"rarity 3, blue, Security, warrior, two-handed heavy, paladin model")
	t.eq(d.weapon_classes, ["heavy", "sword", "polearm"] as Array[String], "can equip one-hand swords and two-handed long weapons")
	t.eq(d.passive_by_id("node_paladin_heal").unlock_star, 2, "Holy Mending unlocks at 2 stars")
	var e: EquipmentDef = cat.get_equipment("warhammer")
	t.eq([e.class_id, e.color_id, e.cost, e.owner, e.model], ["heavy", "blue", 3, "node_paladin", "warhammer"], "War Hammer: heavy, blue, 3, his")
	var ab: AbilityDef = e.abilities[0]
	t.ok(ab.cooldown == 4.0 and ab.keyword_value("multi_attack", 1) == 4, "4 s cooldown 【Multi 4】")
	t.ok(float(e.flat_mods.get("ability_power", 0.0)) > 0.0 and float(e.flat_mods.get("damage_taken_pct", 0.0)) > 0.0, "ability power + damage reduction")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_slam_hits_the_cone_and_breaks_terrain(t: TestCtx) -> void:
	var lay := {"truck": false, "obstacles": [_obs(Vector2(1.2, -0.6)), _obs(Vector2(-1.2, -0.6), "rubble_a", "burning"), _obs(Vector2(0.6, 0.5), "altar"),
		_obs(Vector2(0, -5.5))],
		"embers": [{"x": _cell(Vector2(-0.4, -0.2)).x, "y": _cell(Vector2(-0.4, -0.2)).y, "w": 1, "h": 1, "style": "ember"}],
		"frost": [{"x": _cell(Vector2(0.4, -1.2)).x, "y": _cell(Vector2(0.4, -1.2)).y, "w": 1, "h": 1, "style": "frost"}]}
	var b := Fixture.make([{"def": "node_paladin", "pos": Vector2(0, -2)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0.9, 0.3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(-0.9, 0.3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, -6.2)}], 7, lay)
	var p: BUnit = b.units[0]
	b.start()
	_calm(p)
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 5.6)
	var wind: Array[Dictionary] = _of(evs, "quake_windup")
	var slam: Array[Dictionary] = _of(evs, "quake_slam")
	t.eq(wind.size(), 1, "one slam in the first 5 s of contact")
	t.eq(slam.size(), 1, "it lands")
	var dmg: Array[Dictionary] = _of(evs, "damage").filter(func(e: Dictionary) -> bool: return e["src"] == p and e.get("ability", "") == "node_paladin_slam")
	var hit_ids: Array = dmg.map(func(e: Dictionary) -> BUnit: return e["dst"])
	t.ok(hit_ids.has(b.units[1]) and hit_ids.has(b.units[2]) and hit_ids.has(b.units[3]), "all three enemies in front are hit")
	t.ok(not hit_ids.has(b.units[4]), "the one behind him isn't")
	var want: float = _trig("node_paladin_slam").flat_for(1) * (1.0 + p.get_stats().ability_power / 100.0)
	t.near(float(dmg[0]["amount"]), want, 0.5, "x × (100 + AP)%% magic (%.0f)" % want)
	t.eq(dmg[0]["kind"], "magic", "magic damage")
	var m: BattleMap = b.map
	t.ok(bool(m.obstacles[0].get("destroyed", false)) and m.kind_at(_cell(Vector2(1.2, -0.6))) == BattleMap.FREE, "ruin in the cone shattered; its cell is free")
	t.ok(bool(m.obstacles[1].get("destroyed", false)) and not m.near_burning(Vector2(-1.2, -0.6), 0.4), "burning ruin in the cone shattered and stops burning")
	t.ok(not bool(m.obstacles[2].get("destroyed", false)), "the altar can't be broken")
	t.ok(not bool(m.obstacles[3].get("destroyed", false)), "the ruin behind him is untouched")
	t.ok(not bool(m.embers[0]["lit"]), "ember in the cone put out")
	t.ok(bool(m.frost[0].get("destroyed", false)) and m.frost_at(Vector2(0.4, -1.2), 0.4) < 0, "frost mist in the cone cleared")
	t.ok(slam[0]["unit"] == p and absf(float(wind[0]["impact"]) - 0.3) < 0.001, "lands 0.3 s after the wind-up")


func test_slam_is_held_until_enemies_come(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_paladin", "pos": Vector2(0, -4)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 6)}])
	var p: BUnit = b.units[0]
	b.start()
	_calm(p)
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 7.0)
	t.eq(_of(evs, "quake_windup").size(), 0, "nobody within reach: no slam")
	t.ok(p.meta.has("slam_pending"), "the ready slam is held")
	b.units[1].pos = Vector2(0, -2.5)
	evs = _run(b, b.time + 0.3)
	t.eq(_of(evs, "quake_windup").size(), 1, "an enemy comes close: it lands at once")
	evs = _run(b, b.time + 4.6)
	t.eq(_of(evs, "quake_windup").size(), 0, "then a fresh 5 s: not yet after 4.6 s")
	evs = _run(b, b.time + 0.5)
	t.eq(_of(evs, "quake_windup").size(), 1, "5 s after the last one: slam")


func test_holy_mending_heals_the_lowest(t: TestCtx) -> void:
	for star: int in [1, 2]:
		var b := Fixture.make([{"def": "node_paladin", "pos": Vector2(0, -4), "star": star}, {"def": "test_hitter", "pos": Vector2(2, -4)},
			{"def": "test_hitter", "pos": Vector2(-2, -4)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 8)}])
		var p: BUnit = b.units[0]
		b.start()
		_calm(p)
		_calm(b.units[1])
		_calm(b.units[2])
		b.units[1].hp = b.units[1].get_stats().max_health * 0.5
		b.units[2].hp = b.units[2].get_stats().max_health * 0.3
		var hp1: float = b.units[1].hp
		var hp2: float = b.units[2].hp
		_run(b, GC.START_DELAY + 4.3)
		if star == 1:
			t.near(b.units[2].hp, hp2, 0.01, "★1: no Holy Mending yet")
			continue
		var want: float = _trig("node_paladin_heal").flat_for(2) * (1.0 + p.get_stats().ability_power / 100.0) * (1.0 + p.get_stats().healing_done_pct)
		t.near(b.units[2].hp - hp2, want, 1.0, "★2: the lowest-ratio ally gets y × (100 + AP)%% (%.0f)" % want)
		t.near(b.units[1].hp, hp1, 0.01, "only one target")


func test_holy_war_and_the_hammer_stun(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_paladin", "pos": Vector2(0, -2), "weapon": "warhammer"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0.9, 0.3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(-0.9, 0.3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0.5, 1.0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(-0.5, 1.0)}])
	var p: BUnit = b.units[0]
	b.start()
	_calm(p)
	var slam_at := -1.0
	while b.time < GC.START_DELAY + 5.5 and slam_at < 0.0:
		b.step()
		for ev: Dictionary in b.poll_events():
			if ev["t"] == "quake_slam":
				slam_at = b.time
	t.ok(slam_at > 0.0, "slammed")
	var stunned: Array = b.units.filter(func(u: BUnit) -> bool: return u.team == 1 and u.get_status("stun") != null)
	t.eq(stunned.size(), 4, "Holy War → War Hammer: 【Multi 4】 of the 5 damaged enemies are stunned")
	var n: float = float(Fixture.catalog().get_equipment("warhammer").abilities[0].effect_config["n"])
	var v: float = _trig("node_paladin_holywar").flat_for(1) * (1.0 + p.get_stats().ability_power / 100.0)
	var st: BStatus = (stunned[0] as BUnit).get_status("stun")
	t.near(st.expires_at - slam_at, v / n, 0.01, "stun = 1 s per %d trigger value (%.2f s)" % [int(n), v / n])
	t.ok(p.get_stats().damage_taken_pct >= 0.0999, "the hammer's damage reduction")


func test_slam_animations_match_the_impact(t: TestCtx) -> void:
	var lib: AnimationLibrary = load("res://assets/archer_anims.res") as AnimationLibrary
	var cfg: Dictionary = _def().passive_by_id("node_paladin_slam").effect_config
	for cls: String in _def().weapon_classes:
		var nm: String = "slam_paladin_" + cls
		t.ok(lib.has_animation(nm), nm + " baked")
		if lib.has_animation(nm):
			t.ok(lib.get_animation(nm).length >= float(cfg["impact"]) + 0.2 and lib.get_animation(nm).length <= float(cfg["lock"]) + 0.01,
				"%s: longer than the impact (%.2f s), not longer than the stance (%.2f s)" % [nm, float(cfg["impact"]), float(cfg["lock"])])
	for nm2: String in ["fidget_paladin", "victory_paladin"]:
		t.ok(lib.has_animation(nm2), nm2 + " baked")
