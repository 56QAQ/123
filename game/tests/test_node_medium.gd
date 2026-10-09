extends RefCounted
## 幻灵节点：无形伙伴(【充能 9】【召唤】：开局 + 每 4 秒在当前目标背后召唤幽灵；普攻改成在目标脚下召唤幽灵犬并令它普攻)、
## 少女幻葬(4 费 1 星就有：充能用光 → 【吟唱 9】每秒在范围里随机一人背后召唤不分敌我、出不了范围、没有魂体存在的幽灵；
## 结束时每 3 秒吟唱召唤 吟唱期间阵亡数 个幽灵，然后强制阵亡)、遗愿(友方召唤物阵亡 → 最近的敌人，数值 = 它的最大生命)；
## 幽灵犬(最好的伙伴：额外魔法伤害 = 召唤者普攻伤害)、幽灵(无声无息：背后的普攻必定暴击 + 真实伤害)，魂体存在(不能被选中、不受伤害、普攻一次后阵亡)；
## 专武魔典(召唤物 +1 星；遗愿 → 目标背后召唤幽灵，首次攻击额外 触发数值 × n)。


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
	while b.time < sec and b.state != "ended":
		all.append_array(_step(b))
	return all


func _tough(u: BUnit) -> void:
	u.base.max_health = 1.0e6
	u.base.defense = 0.0
	u.base.magic_resistance = 0.0
	u.mark_dirty()
	u.get_stats()
	u.hp = 1.0e6


func _summons(b: Battle, id: String) -> Array[BUnit]:
	var r: Array[BUnit] = []
	for u: BUnit in b.units:
		if u.def.id == id:
			r.append(u)
	return r


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var d: UnitDef = cat.get_unit("node_medium")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role, d.base_weapon_class], [4, "purple", "research", "caster", "focus"], "rarity 4, purple, Research, caster, focus")
	t.eq(d.weapon_classes, ["focus"] as Array[String], "focus only")
	var dog: UnitDef = cat.get_unit("node_dog")
	t.eq([dog.cost, dog.faction_id, dog.profession_id, dog.role, dog.base_weapon_class, dog.summon_only], [4, "purple", "security", "warrior", "heavy", true],
		"Ghost Hound: rarity 4, purple, Security, warrior, two-handed heavy, summon only")
	var gh: UnitDef = cat.get_unit("node_ghost")
	t.eq([gh.cost, gh.faction_id, gh.profession_id, gh.role, gh.base_weapon_class, gh.summon_only], [3, "purple", "information", "assassin", "sword", true],
		"Ghost: rarity 3, purple, Information, assassin, one-handed melee, summon only")
	var e: EquipmentDef = cat.get_equipment("necro_grimoire")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["focus", "purple", 4, "node_medium"], "Grimoire: focus, purple, rarity 4, hers")
	t.near(float(e.flat_mods.get("summon_star_bonus", 0.0)), 1.0, 0.001, "summons +1 star")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_ghost_at_start_backstabs_and_vanishes(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_medium", "pos": Vector2(0, -6)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 4)}])
	var md: BUnit = b.units[0]
	var dm: BUnit = b.units[1]
	b.start()
	_tough(dm)
	var gs: Array[BUnit] = _summons(b, "node_ghost")
	t.eq(gs.size(), 1, "a ghost at the start")
	if gs.is_empty():
		return
	var g: BUnit = gs[0]
	t.eq(int(md.ability_charges.get("node_medium_partner", 9)), 8, "…for one charge")
	t.ok(Pipeline.is_behind(g, dm), "behind the target")
	_run(b, 0.1)
	t.ok(g.has_flag("untargetable") and g.has_flag("invulnerable"), "Spectral")
	t.ok(not b.enemies_of(dm).has(g), "can't be targeted")
	t.near(b.pipeline.fx.damage(dm, g, 500.0, "true", {"surface": "other"}), 0.0, 0.001, "takes no damage")
	var evs: Array[Dictionary] = _run(b, GC.START_DELAY + 2.0)
	var hit: Array[Dictionary] = []
	for e: Dictionary in _of(evs, "damage"):
		if e["src"] == g:
			hit.append(e)
	t.eq(hit.size(), 1, "attacks once")
	if not hit.is_empty():
		t.eq(str(hit[0]["kind"]), "true", "from behind: true damage")
		t.ok(bool(hit[0]["crit"]), "…and always crits")
	t.ok(not g.alive, "then vanishes")


func test_normal_attack_summons_a_hound(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_medium", "pos": Vector2(0, -1.5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.5)}])
	var md: BUnit = b.units[0]
	var dm: BUnit = b.units[1]
	b.start()
	_tough(dm)
	md.ability_charges["node_medium_partner"] = 5
	var dogs_seen: Array[BUnit] = []
	var dmg: Array[Dictionary] = []
	while b.time < GC.START_DELAY + 3.0 and dogs_seen.is_empty():
		var ev: Array[Dictionary] = _step(b)
		for s: Dictionary in _of(ev, "summon"):
			if (s["unit"] as BUnit).def.id == "node_dog":
				dogs_seen.append(s["unit"])
	t.eq(dogs_seen.size(), 1, "her normal attack summons a Ghost Hound")
	if dogs_seen.is_empty():
		return
	var dog: BUnit = dogs_seen[0]
	t.ok(dog.pos.distance_to(dm.pos) < 0.6, "at the target")
	t.eq(int(md.ability_charges.get("node_medium_partner", 9)), 4, "…for one charge")
	dmg = []
	for e: Dictionary in _of(_run(b, b.time + 0.6), "damage"):
		if e["src"] == dog:
			dmg.append(e)
	var phys := 0.0
	var mag := 0.0
	for e2: Dictionary in dmg:
		if str(e2["kind"]) == "physical":
			phys += float(e2["amount"])
		elif str(e2["kind"]) == "magic":
			mag += float(e2["amount"])
	t.ok(phys > 0.0, "the hound bites (physical)")
	var want: float = md.get_stats().attack_power * float(md.wclass().get("na_mult", 1.0))
	t.near(mag, want, want * 0.01 + 1.0, "Best Friend: + her normal attack damage as magic")
	t.ok(not dog.alive, "then vanishes")


func test_requiem(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_medium", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.5)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(1.6, 0.8)}, {"def": "test_dummy", "team": 1, "pos": Vector2(-6, -5)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(6, -5)}, {"def": "test_dummy", "pos": Vector2(-1.4, -0.8)}])
	var md: BUnit = b.units[0]
	b.start()
	for u: BUnit in b.units:
		if u != md:
			_tough(u)
	md.ability_charges["node_medium_partner"] = 2              # 开局一个幽灵 → 1 层；第一下普攻 → 0 层
	var t0 := -1.0
	while b.time < GC.START_DELAY + 4.0 and t0 < 0.0:
		_step(b)
		if md.phase == "chant":
			t0 = b.time
	t.ok(t0 > 0.0, "charges out: she starts chanting")
	_run(b, t0 + 3.2)
	var ferals: Array[BUnit] = []
	for u2: BUnit in b.units:
		if u2.alive and bool(u2.meta.get("feral", false)):
			ferals.append(u2)
	t.ok(ferals.size() >= 3, "a ghost every second (%d)" % ferals.size())
	var rad: float = b.pipeline.passive_splash_radius(md)
	var ok_all := true
	for f: BUnit in ferals:
		ok_all = ok_all and not f.has_flag("untargetable") and f.pos.distance_to(md.pos) <= rad + 0.05
	t.ok(ok_all, "no Spectral, and they stay inside Splash range")
	t.ok(ferals.size() > 0 and b.enemies_of(b.units[5]).has(ferals[0]), "anyone can fight them (they attack friend and foe)")
	# 吟唱期间死两个
	b.pipeline.fx.damage(md, b.units[3], 1.0e7, "true", {"surface": "other"})
	b.pipeline.fx.damage(md, b.units[4], 1.0e7, "true", {"surface": "other"})
	var fin: Array[Dictionary] = []
	while b.time < t0 + 9.5 and md.alive:
		fin.append_array(_of(_step(b), "medium_funeral"))
	t.eq(fin.size(), 1, "the Grand Requiem")
	if not fin.is_empty():
		t.eq(int(fin[0]["deaths"]), 2, "2 died during the chant")
		t.eq((fin[0]["spots"] as Array).size(), 3 * 2, "9 s chanted = 3 × 2 ghosts")
	t.ok(not md.alive and bool(md.meta.get("funeral_death", false)), "then she falls")
	_run(b, b.time + 0.3)
	var left := 0
	for u3: BUnit in b.units:
		if u3.alive and bool(u3.meta.get("feral", false)):
			left += 1
	t.eq(left, 0, "her chant ghosts disperse with her")


func test_requiem_ghosts_fight_inside_the_domain(t: TestCtx) -> void:
	# 领域里的幽灵就该在领域里打人：以前它们和她同一队，被"队友的不分敌我领域先跑出去"的走位规则赶到边上，一直贴着拴绳的边打不着人
	var b := Fixture.make([{"def": "node_medium", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.2)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(1.0, -0.6)}])
	var md: BUnit = b.units[0]
	b.start()
	for u: BUnit in b.units:
		if u != md:
			_tough(u)
	md.ability_charges["node_medium_partner"] = 2
	var t0 := -1.0
	while b.time < GC.START_DELAY + 4.0 and t0 < 0.0:
		_step(b)
		if md.phase == "chant":
			t0 = b.time
	t.ok(t0 > 0.0, "charges out: she starts chanting")
	var hits := 0
	var on_dummy := 0
	while b.time < t0 + 4.0 and md.alive:
		for e: Dictionary in _of(_step(b), "damage"):
			var s0: BUnit = e.get("src") as BUnit
			if s0 != null and bool(s0.meta.get("feral", false)):
				hits += 1
				if e.get("dst") == b.units[1] or e.get("dst") == b.units[2]:
					on_dummy += 1
	t.ok(hits >= 2, "the chant ghosts attack inside the domain instead of fleeing to its rim (%d hits)" % hits)
	t.ok(on_dummy >= 1, "including the enemies standing next to her (%d)" % on_dummy)


func test_last_wish_and_grimoire(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_medium", "pos": Vector2(0, -6), "weapon": "necro_grimoire"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 4)}])
	var md: BUnit = b.units[0]
	b.start()
	_tough(b.units[1])
	var gs: Array[BUnit] = _summons(b, "node_ghost")
	t.ok(not gs.is_empty() and gs[0].star == md.star + 1, "Grimoire: summons +1 star")
	var g0: BUnit = gs[0] if not gs.is_empty() else null
	var mh: float = g0.get_stats().max_health if g0 != null else 0.0
	var made: Array[BUnit] = []
	while b.time < GC.START_DELAY + 3.0 and made.is_empty():
		for s: Dictionary in _of(_step(b), "summon"):
			var su: BUnit = s["unit"]
			if su != g0 and su.def.id == "node_ghost":
				made.append(su)
	t.eq(made.size(), 1, "Last Wish: the first ghost vanished → the Grimoire summons another")
	if not made.is_empty():
		t.ok(Pipeline.is_behind(made[0], b.units[1]), "behind the enemy nearest to it")
		t.near(float(made[0].meta.get("first_hit_bonus", 0.0)), mh * 0.03, 1.0, "first hit +max health of the dead summon × 0.03")
