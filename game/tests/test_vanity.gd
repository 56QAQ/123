extends RefCounted
## 第一章·红之章的精英：虚荣的余烬(虚荣 / 龙息 / 煌然)，以及驱散、体型变化这些新规则。


func _step(b: Battle, seconds: float) -> void:
	for i in range(int(round(seconds / GC.SIM_DT))):
		b.step()


## 跑到下一次龙息 / 普攻出手(最多 max_s 秒)；返回那个事件(没有 = {})
func _until_attack(b: Battle, u: BUnit, max_s: float = 3.0) -> Dictionary:
	var n: int = int(round(max_s / GC.SIM_DT))
	for i in range(n):
		b.step()
		for e: Dictionary in b.poll_events():
			if str(e.get("t", "")) == "attack_release" and e.get("unit") == u:
				return e
	return {}


func _dragon(extra: Array, star: int = 1, at: Vector2 = Vector2.ZERO) -> Battle:
	var specs: Array = [{"def": "elite_ember_vanity", "team": 1, "star": star, "pos": at}]
	specs.append_array(extra)
	var b: Battle = Fixture.make(specs)
	b.start()
	return b


func test_vanity_at_battle_start_doubles_everything(t: TestCtx) -> void:
	var b: Battle = _dragon([{"def": "test_dummy", "team": 0, "pos": Vector2(9, 0)}])
	var d: BUnit = b.units[0]
	var base: StatBlock = d.def.stats_for_star(1)
	t.near(d.base_radius, 1.0, 0.001, "4× a normal unit's footprint: radius 0.5 × scale 2 = 1 m (diameter ×2)")
	_step(b, 0.1)
	var st: BStatus = d.get_status("elite_vanity")
	t.ok(st != null and st.stacks == 3, "gains 3 stacks of Vanity at the start of battle")
	t.ok(st != null and st.has_flag("dispellable") and st.has_flag("dispel_one"), "dispellable, one stack at a time")
	t.near(st.expires_at - b.time, 20.0 - 0.1, 0.06, "lasts 20 s")
	var s: StatBlock = d.get_stats()
	t.near(s.max_health, base.max_health * 2.0, 0.5, "max health doubled")
	t.near(d.hp, s.max_health, 0.5, "…and it starts at full (doubled) health")
	t.near(s.attack_power, base.attack_power * 2.0, 0.01, "attack doubled")
	t.near(s.defense, base.defense * 2.0, 0.01, "armor doubled")
	t.near(s.magic_resistance, base.magic_resistance * 2.0, 0.01, "magic resist doubled")
	t.near(s.damage_taken_pct, 0.5, 0.001, "takes 50% less damage")
	t.near(s.damage_dealt_pct, 1.0, 0.001, "deals 100% more damage")
	t.near(d.radius, 1.0 * 1.4142, 0.01, "size doubled (area ×2 → diameter ×√2)")
	t.ok(not d.breath_cfg().is_empty(), "its attacks become a dragon breath")
	# 层数只标记驱散进度：1 层和 3 层效果一样
	st.stacks = 1
	d.mark_dirty()
	t.near(d.get_stats().attack_power, base.attack_power * 2.0, 0.01, "1 stack = same effect as 3")
	st.stacks = 3
	d.mark_dirty()


func test_dispel_removes_one_stack_at_a_time(t: TestCtx) -> void:
	var b: Battle = _dragon([{"def": "test_dummy", "team": 0, "pos": Vector2(9, 0)}])
	var d: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	_step(b, 0.1)
	var ratio: float = d.hp_ratio()
	var n: int = b.pipeline.fx.dispel(foe, d, "buff", 1)
	t.eq(n, 1, "one dispel")
	t.eq(d.status_stacks("elite_vanity"), 2, "3 → 2 stacks")
	t.near(d.get_stats().damage_dealt_pct, 1.0, 0.001, "still empowered")
	b.pipeline.fx.dispel(foe, d, "buff", 1)
	t.eq(d.status_stacks("elite_vanity"), 1, "2 → 1")
	b.pipeline.fx.dispel(foe, d, "buff", 1)
	t.eq(d.status_stacks("elite_vanity"), 0, "the last stack ends Vanity")
	var base: StatBlock = d.def.stats_for_star(1)
	t.near(d.get_stats().max_health, base.max_health, 0.5, "max health back to normal")
	t.near(d.hp_ratio(), ratio, 0.001, "…keeping the same health ratio")
	t.near(d.radius, 1.0, 0.01, "shrinks back")
	t.ok(d.breath_cfg().is_empty(), "back to single-target claws")
	# 普通的可驱散增益：一次整个去掉；不可驱散的不动；对友军是净化负面
	var buff := {"status_id": "test_buff", "duration": 5.0, "max_stacks": 3, "add_stacks": 3, "flags": ["buff", "dispellable"], "stat_id": "attack_power", "flat": 5.0}
	b.pipeline.fx.apply_status(d, d, buff)
	b.pipeline.fx.dispel(foe, d, "buff", 1)
	t.eq(d.status_stacks("test_buff"), 0, "an ordinary dispellable buff goes all at once")
	var locked := {"status_id": "test_locked", "duration": 5.0, "flags": ["buff", "dispellable", "no_dispel"]}
	b.pipeline.fx.apply_status(d, d, locked)
	t.eq(b.pipeline.fx.dispel(foe, d, "buff", 1), 0, "no_dispel can't be dispelled")
	var burn: Dictionary = (Fixture.catalog().get_unit("mob_ember_wrath").passives[0] as AbilityDef).effect_config.duplicate(true)
	b.pipeline.fx.apply_status(d, foe, burn)
	b.pipeline.fx.apply_status(d, foe, burn)
	t.eq(b.pipeline.fx.dispel(foe, foe, "debuff", 1), 1, "cleansing an ally removes one debuff")
	t.eq(foe.status_count("burning"), 1, "…one Burning left")


func test_vanity_wears_off_after_20_seconds(t: TestCtx) -> void:
	var b: Battle = _dragon([{"def": "test_dummy", "team": 0, "pos": Vector2(9, 9)}])
	var d: BUnit = b.units[0]
	for u: BUnit in b.units:
		u.attack_cd = 1.0e9
	_step(b, 19.5)
	t.eq(d.status_stacks("elite_vanity"), 3, "still there at 19.5 s")
	_step(b, 1.0)
	t.eq(d.status_stacks("elite_vanity"), 0, "gone after 20 s")
	t.near(d.radius, 1.0, 0.01, "back to normal size")


func test_breath_burns_everyone_on_the_ray(t: TestCtx) -> void:
	# 战场 19 × 14 米：龙在左边，往 +x 方向排一行
	var b: Battle = _dragon([{"def": "test_dummy", "team": 0, "pos": Vector2(-3.5, 0.0)}, {"def": "test_dummy", "team": 0, "pos": Vector2(-2.2, 0.4)},
		{"def": "test_dummy", "team": 0, "pos": Vector2(-1.4, -0.5)}, {"def": "test_dummy", "team": 0, "pos": Vector2(-6.0, 3.6)},
		{"def": "test_dummy", "team": 0, "pos": Vector2(0.5, 0.0)}], 1, Vector2(-6.0, 0.0))
	var d: BUnit = b.units[0]
	var e: Dictionary = _until_attack(b, d)
	t.ok(not e.is_empty(), "the dragon attacks")
	_step(b, 0.05)
	var line: Array = [b.units[1], b.units[2], b.units[3]]
	for u: BUnit in line:
		t.ok(u.hp < u.get_stats().max_health, "a dummy on the ray is hit (%.1f, %.1f)" % [u.pos.x, u.pos.y])
		t.eq(u.status_count("burning"), 3, "…and set Burning 3 times (Vanity)")
	t.near(b.units[4].hp, b.units[4].get_stats().max_health, 0.01, "the dummy off to the side is not hit")
	t.near(b.units[5].hp, b.units[5].get_stats().max_health, 0.01, "the one beyond the ray's 5 m reach is not hit")
	t.eq(b.units[4].status_count("burning"), 0, "…and not burning")
	var bst: BStatus = b.units[1].status_instances("burning")[0]
	t.near(bst.expires_at - b.time, 1.0 - 0.05, 0.1, "1★ burns last 1 s")


func test_breath_aims_for_the_most_enemies(t: TestCtx) -> void:
	var b: Battle = _dragon([{"def": "test_dummy", "team": 0, "pos": Vector2(0, 2.6)},
		{"def": "test_dummy", "team": 0, "pos": Vector2(2.6, 0.4)}, {"def": "test_dummy", "team": 0, "pos": Vector2(3.6, 0.7)}, {"def": "test_dummy", "team": 0, "pos": Vector2(4.6, 1.0)}])
	var d: BUnit = b.units[0]
	_step(b, 0.1)
	var aim: Dictionary = Targeting.best_breath_aim(b, d, d.breath_cfg(), b.units[1])
	t.eq((aim["targets"] as Array).size(), 3, "picks the ray through the three in a row, not the single closest one")
	t.ok(not (aim["targets"] as Array).has(b.units[1]), "…which leaves the lone one out")
	t.ok((aim["dir"] as Vector2).x > 0.9, "aimed to the right")


func test_claws_without_vanity_hit_one_and_burn_once(t: TestCtx) -> void:
	var b: Battle = _dragon([{"def": "test_dummy", "team": 0, "pos": Vector2(0, 2.0)}, {"def": "test_dummy", "team": 0, "pos": Vector2(0.2, 3.4)}], 2)
	var d: BUnit = b.units[0]
	_step(b, 0.05)
	for i in range(3):
		b.pipeline.fx.dispel(b.units[1], d, "buff", 1)
	t.eq(d.status_stacks("elite_vanity"), 0, "Vanity dispelled")
	var e: Dictionary = _until_attack(b, d)
	t.ok(not e.is_empty(), "claw attack")
	_step(b, 0.05)
	t.ok(b.units[1].hp < b.units[1].get_stats().max_health, "the target is clawed")
	t.near(b.units[2].hp, b.units[2].get_stats().max_health, 0.01, "the one behind it is not (single target)")
	t.eq(b.units[1].status_count("burning"), 1, "one Burning without Vanity")
	t.near(b.units[1].status_instances("burning")[0].expires_at - b.time, 1.5 - 0.05, 0.1, "2★: 1.5 s")


func test_elite_fights_lead_with_an_elite(t: TestCtx) -> void:
	var r := Run.create(Fixture.catalog(), 61)
	r.enter_chapter("ch1_red", false)
	var power := {}
	for el: Dictionary in r.chapter["elites"]:
		power[str(el["unit"])] = r._unit_power(str(el["unit"]), 1)
	var seen := {}
	for iv: int in [18, 22, 26, 30, 34, 40, 18, 22, 26, 30, 34, 40, 48, 56, 64, 48, 56, 64]:
		var enc: Dictionary = r._make_encounter("elite", iv)
		var head: Array = enc["units"][0]
		t.ok(power.has(str(head[0])), "the elite leads (intensity %d: %s)" % [iv, str(head[0])])
		seen[str(head[0])] = true
		t.eq(str((head[4] as Dictionary).get("orb", "")), "gold", "it drops a gold orb")
		var share: float = float(r.chapter.get("elite_star2_share", 0.8))
		t.eq(int(head[1]), 2 if r._unit_power(str(head[0]), 2) <= float(iv) * share else 1, "2★ once the 2★ elite fits in %d%% of the intensity" % int(share * 100.0))
		t.ok(r._unit_power(str(head[0]), int(head[1])) <= float(iv) + 0.001, "the elite itself fits in the intensity")
		for i in range(1, (enc["units"] as Array).size()):
			var e: Array = enc["units"][i]
			t.ok(str(e[0]).begins_with("mob_ember_"), "escorts are embers")
		t.near(r.encounter_power(enc), float(iv), 0.05 * float(iv), "the elite and its escorts add up to the intensity (%d)" % iv)
	t.eq(seen.size(), 3, "Vanity, Melancholy and Pride all show up (%s)" % str(seen.keys()))
