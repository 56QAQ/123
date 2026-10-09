extends RefCounted
## 追猎节点：猎人笔记(开战盯住威胁最高的敌人——首领 > 精英 > 预估输出；吟唱 6 秒，结束 / 被打断时每秒 +x 针对它的普攻闪避 / 增伤 / 穿甲)、
## 意外渔获(2 星：没被打断 → 钓到面前、嘲讽、够得着的队友改打它)、灵敏身法(闪开它的普攻时触发)、专武易用短弓(立刻反射一发普攻，触发数值每 100 = 100%)。


func _run(b: Battle, sec: float) -> void:
	while b.time < sec and b.state != "ended":
		b.step()


func _x(star: int) -> float:
	var a: AbilityDef = Fixture.catalog().get_unit("node_hunter").passive_by_id("node_hunter_notes")
	return float((a.effect_config["per_sec_by_star"] as Dictionary)[str(star)])


## 一开始吟唱就当作已经吟唱满(下一步完整结束)
func _free_chant(b: Battle, h: BUnit) -> void:
	for i in range(200):
		if h.phase == "chant":
			h.chant_until = b.time
			return
		b.step()


func test_unit_data(t: TestCtx) -> void:
	var d: UnitDef = Fixture.catalog().get_unit("node_hunter")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role], [2, "green", "engineering", "archer"], "rarity 2, green, Engineering, archer")
	t.eq(d.weapon_classes, ["bow", "dual"] as Array[String], "drawn ranged default; dual melee allowed")
	var e: EquipmentDef = Fixture.catalog().get_equipment("easy_shortbow")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["bow", "green", 2, "node_hunter"], "Handy Shortbow: drawn ranged, green, rarity 2, his")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_picks_the_biggest_threat(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_hunter", "pos": Vector2(0, 0)}, {"def": "node_student", "team": 1, "pos": Vector2(-2, 5)},
		{"def": "node_archer", "team": 1, "pos": Vector2(2, 5), "weapon": "rapidfire_arbalest"}, {"def": "node_shielder", "team": 1, "pos": Vector2(0, 4)}])
	b.start()
	_run(b, 0.5)
	var h: BUnit = b.units[0]
	t.eq(h.meta.get("threat_mark"), b.units[2], "no boss / elite: the highest expected damage (the archer)")
	t.eq(h.phase, "chant", "and he starts preparing (standing still)")
	var b2 := Fixture.make([{"def": "node_hunter", "pos": Vector2(0, 0)}, {"def": "node_archer", "team": 1, "pos": Vector2(2, 5)},
		{"def": "node_shielder", "team": 1, "pos": Vector2(0, 4)}])
	b2.units[2].meta["elite"] = true
	b2.start()
	_run(b2, 0.5)
	t.eq(b2.units[0].meta.get("threat_mark"), b2.units[2], "an elite is picked over everything else")
	var b3 := Fixture.make([{"def": "node_hunter", "pos": Vector2(0, 0)}, {"def": "node_archer", "team": 1, "pos": Vector2(2, 5)},
		{"def": "node_shielder", "team": 1, "pos": Vector2(0, 4)}, {"def": "node_student", "team": 1, "pos": Vector2(-2, 5)}])
	b3.units[2].meta["elite"] = true
	b3.units[3].meta["boss"] = true
	b3.start()
	_run(b3, 0.5)
	t.eq(b3.units[0].meta.get("threat_mark"), b3.units[3], "a boss beats an elite")


func test_notes_after_a_full_chant(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_hunter", "pos": Vector2(0, 0), "star": 1}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 3.0)}])
	var h: BUnit = b.units[0]
	var d: BUnit = b.units[1]
	b.start()
	_run(b, GC.START_DELAY + 5.5)
	t.eq(h.phase, "chant", "still preparing 5.5 s into the fight (6 s from when the fighting starts)")
	t.eq(Fixture.events_of(b, "attack_start").size(), 0, "no attacks while preparing")
	_run(b, GC.START_DELAY + 6.3)
	var st: BStatus = h.get_status("hunter_notes")
	t.ok(st != null, "notes written")
	if st != null:
		t.eq(str(st.meta["vs_target"]), d.uid, "against the marked enemy")
		t.near(float(st.meta["dodge"]), 6.0 * _x(1), 0.001, "6 s × x dodge")
		t.near(float(st.meta["amp"]), 6.0 * _x(1), 0.001, "6 s × x damage amplification")
		t.near(float(st.meta["pen"]), 6.0 * _x(1), 0.001, "6 s × x armor penetration")
	t.ok(d.pos.distance_to(Vector2(0, 3.0)) < 0.05, "1★: no Unexpected Catch (the dummy stays where it was)")
	t.eq(h.target, d, "he targets the marked enemy afterwards")


func test_interrupted_chant_counts_whole_seconds(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_hunter", "pos": Vector2(0, 0), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 3.0)}])
	var h: BUnit = b.units[0]
	var d: BUnit = b.units[1]
	b.start()
	_run(b, GC.START_DELAY + 3.4)            # 开战时机就开始的吟唱：从倒计时结束才开始计时
	b.pipeline.fx.apply_status(d, h, {"status_id": "test_stun", "duration": 0.3, "flags": ["stun"]}, {})
	var st: BStatus = h.get_status("hunter_notes")
	t.ok(st != null and int(st.meta["secs"]) == 3, "interrupted after 3.4 s: 3 whole seconds count (%s)" % str(st.meta.get("secs", "?") if st != null else "none"))
	if st != null:
		t.near(float(st.meta["dodge"]), 3.0 * _x(2), 0.001, "3 s × x")
	_run(b, b.time + 1.0)
	t.ok(d.pos.distance_to(Vector2(0, 3.0)) < 0.05, "interrupted: no Unexpected Catch even at 2★")


func test_unexpected_catch(t: TestCtx) -> void:
	# 2 星：笔记写完 → 钓到面前、嘲讽 3 秒、够得着的队友改打它
	var b := Fixture.make([{"def": "node_hunter", "pos": Vector2(0, 0), "star": 2},
		{"def": "test_hitter", "pos": Vector2(1.6, 0.6)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 5.0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.5, 1.7)}])
	var h: BUnit = b.units[0]
	var mate: BUnit = b.units[1]
	var far: BUnit = b.units[2]
	b.start()
	h.meta["threat_mark"] = far                 # (测试：指定它为威胁最高的敌人)
	_free_chant(b, h)
	mate.target = b.units[3]
	_run(b, GC.START_DELAY + 0.8)
	t.ok(far.pos.distance_to(h.pos) < h.radius + far.radius + 0.5, "the marked enemy is reeled in right in front of him (%.2f m)" % far.pos.distance_to(h.pos))
	t.eq(far.forced_target, h, "and taunted")
	t.eq(mate.target, far, "a teammate whose range reaches it switches to it")


func test_dodge_and_counter_shot(t: TestCtx) -> void:
	# 笔记写满后被盯上的敌人的普攻有 6x 的几率被闪开；每次闪开触发灵敏身法 → 易用短弓立刻反射一发普攻(触发数值 100 = 原伤害 ×1)
	var b := Fixture.make([{"def": "node_hunter", "pos": Vector2(0, 0), "star": 1, "weapon": "easy_shortbow"},
		{"def": "test_hitter", "team": 1, "pos": Vector2(0, 1.4)}], 13)
	var h: BUnit = b.units[0]
	var hit: BUnit = b.units[1]
	h.base.max_health = 1.0e6
	h.base.crit_chance = 0.0
	h.mark_dirty()
	b.start()
	h.hp = 1.0e6
	_free_chant(b, h)
	_run(b, b.time + 40.0)
	var tries := 0
	for e: Dictionary in Fixture.events_of(b, "attack_start"):
		if e["unit"] == hit:
			tries += 1
	var dodges: int = Fixture.events_of(b, "dodge").size()
	t.ok(tries > 30, "plenty of attacks from the marked enemy (%d)" % tries)
	t.near(float(dodges) / float(maxi(1, tries)), 6.0 * _x(1), 0.12, "≈ 6x of them dodged (%d / %d)" % [dodges, tries])
	var shots: int = Fixture.events_of(b, "instant_shot").size()
	t.ok(shots > 0 and shots <= dodges, "each dodge fires a counter-shot (charges permitting): %d shots for %d dodges" % [shots, dodges])


func test_fishing_assets_exist(t: TestCtx) -> void:
	# 意外渔获的钓鱼表现：动作在动画库里，钓鱼竿部件在棋子套件里(平时隐藏)
	var d: UnitDef = Fixture.catalog().get_unit("node_hunter")
	var cfx: Dictionary = d.chant_fx.get("node_hunter_notes", {})
	t.eq(int(cfx.get("min_star", 0)), 2, "fishing from 2★ (when Unexpected Catch unlocks)")
	var lib: AnimationLibrary = load("res://assets/archer_anims.res") as AnimationLibrary
	for k: String in ["anim", "pull_anim"]:
		t.ok(lib.has_animation(str(cfx.get(k, ""))), "animation %s" % str(cfx.get(k, "")))
	var scene: Node = (load("res://scenes/unit_model.tscn") as PackedScene).instantiate()
	var rod: Node = scene.get_node_or_null("Skeleton3D/" + str(cfx.get("prop", "")))
	t.ok(rod != null and not (rod as Node3D).visible, "the fishing rod part exists and starts hidden")
	scene.free()
