extends RefCounted
## 炽照节点：斩恶(拔刀连斩【追击 2/3/4】，他自己的节奏：1 秒一轮、0.3 秒出手、副本每 0.08 秒一下)、
## 残光(每一下普攻给目标叠【剑痕】：0.75 秒，叠满 / 到期时引爆，每层各触发一次，触发数值随层数 +5%/层)、
## 不灭(2 星：造成普攻伤害叠【重燃】，承受普攻伤害时每层回血后消耗)、专武炽霞(攻速 +50%；触发数值 × n 的物理普攻伤害，0.1 秒内连锁 ×1.05)。


func _run_until(b: Battle, sec: float) -> void:
	while b.time < sec and b.state != "ended":
		b.step()


func _no_crit(u: BUnit) -> void:
	u.base.crit_chance = 0.0
	u.mark_dirty()


## 残光的 y(按星级)、重燃每层回复量(按星级)：从数据里读，调数值不用改测试
func _y(star: int) -> float:
	for tr: TriggerDef in Fixture.catalog().get_unit("node_samurai").triggers:
		if tr.id == "node_samurai_canguang":
			return tr.ratio_for(star)
	return 0.0


func _x(star: int) -> float:
	var a: AbilityDef = Fixture.catalog().get_unit("node_samurai").passive_by_id("node_samurai_rekindle")
	var per: Dictionary = a.effect_config.get("per_stack_by_star", {})
	return float(per.get(str(star), 0.0))


func _dmg_from(b: Battle, src: BUnit, ability: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in Fixture.events_of(b, "damage"):
		if e["src"] == src and (ability == "" or str(e.get("ability", "")) == ability):
			out.append(e)
	return out


func test_unit_data(t: TestCtx) -> void:
	var d: UnitDef = Fixture.catalog().get_unit("node_samurai")
	t.eq([d.cost, d.faction_id, d.profession_id, d.role], [3, "green", "security", "warrior"], "rarity 3, green, Security, warrior")
	t.eq(d.special_traits, ["blaze"] as Array[String], "special tag 如火")
	t.eq(d.weapon_classes, ["sword", "heavy"] as Array[String], "one-handed melee default; two-handed heavy allowed")
	var e: EquipmentDef = Fixture.catalog().get_equipment("blazing_glow")
	t.eq([e.class_id, e.color_id, e.cost, e.owner], ["sword", "green", 3, "node_samurai"], "Blazing Glow: one-handed melee, green, rarity 3, his")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


func test_drawing_flurry_rhythm(t: TestCtx) -> void:
	# 基础剑：1 秒一轮 / 攻速 0.9 = 1.11 秒；每轮 1 + 追击 N 下，副本每 0.08 秒一下
	for star: int in [1, 3]:
		var b := Fixture.make([{"def": "node_samurai", "pos": Vector2(0, 0), "star": star}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.0)}])
		var s: BUnit = b.units[0]
		b.start()
		t.near(s.get_stats().attack_interval(), 1.0 / 0.9, 0.01, "%d★: his own rhythm, 1 s a round at 0.9 attack speed" % star)
		_run_until(b, GC.START_DELAY + 6.0)
		var hits: Array[Dictionary] = _dmg_from(b, s)
		var starts: int = Fixture.events_of(b, "attack_start").size()
		var per: int = 1 + [2, 3, 4][star - 1]
		t.ok(starts >= 4 and absi(hits.size() - starts * per) <= per, "%d★: %d cuts per round (%d rounds, %d hits)" % [star, per, starts, hits.size()])
		if hits.size() >= per:
			var gap: float = float(hits[1]["time"]) - float(hits[0]["time"])
			t.near(gap, 0.08, 0.02, "%d★: the follow-up cuts come 0.08 s apart" % star)
	# 炽霞：攻速 +50% → 0.74 秒一轮(剑痕 0.75 秒续得上)
	var b2 := Fixture.make([{"def": "node_samurai", "pos": Vector2(0, 0), "weapon": "blazing_glow"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.0)}])
	b2.start()
	t.ok(b2.units[0].get_stats().attack_interval() <= 0.75, "Blazing Glow: a round every %.3f s (≤ 0.75)" % b2.units[0].get_stats().attack_interval())


func test_scars_burst_when_they_lapse(t: TestCtx) -> void:
	# 一轮 3 下 = 3 层剑痕；之后不再出刀 → 0.75 秒后到期引爆 3 次，每次触发数值 = 攻击力 × 25% × (100 + 3 × 5)%
	var b := Fixture.make([{"def": "node_samurai", "pos": Vector2(0, 0), "weapon": "blazing_glow"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.0)}])
	var s: BUnit = b.units[0]
	var d: BUnit = b.units[1]
	_no_crit(s)
	b.start()
	while d.status_stacks("sword_scar") == 0 and b.time < 8.0:
		b.step()
	_run_until(b, b.time + 0.25)
	s.attack_cd = 99.0                  # 打完这一轮就停手
	t.eq(d.status_stacks("sword_scar"), 3, "one stack per cut (1 + Pursuit 2)")
	var st: BStatus = d.get_status("sword_scar")
	t.ok(st != null and st.has_flag("debuff") and st.has_flag("dispellable"), "a dispellable debuff")
	t.eq(st.max_stacks if st != null else 0, 10, "capped at Undying's Stacking 10 (even at 1★, where Undying is locked)")
	var n0: int = b.events.size()
	_run_until(b, b.time + 0.7)
	var bursts: Array[Dictionary] = []
	var cuts: Array[Dictionary] = []
	for e: Dictionary in b.events.slice(n0):
		if str(e["t"]) == "status_burst":
			bursts.append(e)
		if str(e["t"]) == "damage" and str(e.get("ability", "")) == "blazing_glow_cut":
			cuts.append(e)
	t.ok(bursts.size() == 1 and int(bursts[0]["stacks"]) == 3, "the 3 stacks burst when they run out")
	t.eq(cuts.size(), 3, "Afterglow triggers once per stack")
	if cuts.size() == 3:
		var base: float = s.get_stats().attack_power * _y(1) * 1.15
		t.near(float(cuts[0]["amount"]), base, 0.6, "trigger value = attack × y × (100 + 3 × 5)%% (%.1f)" % float(cuts[0]["amount"]))
		t.near(float(cuts[2]["amount"]), base * 1.05 * 1.05, 0.6, "and the chain: the third is × 1.05²")
	t.eq(d.status_stacks("sword_scar"), 0, "used up")


func test_full_scar_burst_with_blazing_glow(t: TestCtx) -> void:
	# 炽霞：叠到 10 层当场引爆 → 10 次触发，每次造成 触发数值(攻击 × 25% × 150%)× 1.05^k 的物理普攻伤害
	var b := Fixture.make([{"def": "node_samurai", "pos": Vector2(0, 0), "weapon": "blazing_glow"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.0)}])
	var s: BUnit = b.units[0]
	var d: BUnit = b.units[1]
	_no_crit(s)
	b.start()
	_run_until(b, GC.START_DELAY + 4.0)
	var cuts: Array[Dictionary] = _dmg_from(b, s, "blazing_glow_cut")
	t.ok(cuts.size() >= 10, "a full burst happened (%d weapon hits)" % cuts.size())
	if cuts.size() >= 10:
		var base: float = s.get_stats().attack_power * _y(1) * 1.5
		var ok_chain := true
		for k in range(10):
			ok_chain = ok_chain and absf(float(cuts[k]["amount"]) - base * pow(1.05, k)) < 0.6
			ok_chain = ok_chain and absf(float(cuts[k]["time"]) - float(cuts[0]["time"])) < 0.001
		t.ok(ok_chain, "10 hits at once: ×1, ×1.05, ×1.05² … of attack × y × 150%% (first %.1f, last %.1f)" % [float(cuts[0]["amount"]), float(cuts[9]["amount"])])
	t.eq(d.status_stacks("sword_scar") <= 9, true, "the scar was used up at 10 and starts over")


func test_rekindle(t: TestCtx) -> void:
	# 不灭(2 星)：造成普攻伤害叠【重燃】(上限 10)；承受普攻伤害时每层回复 20，然后消耗全部
	var b := Fixture.make([{"def": "node_samurai", "pos": Vector2(0, 0), "star": 2}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.0)},
		{"def": "test_hitter", "team": 1, "pos": Vector2(6.0, -6.0)}])
	var s: BUnit = b.units[0]
	var h: BUnit = b.units[2]
	b.start()
	s.target = b.units[1]
	_run_until(b, GC.START_DELAY + 3.0)
	t.eq(s.status_stacks("rekindle"), 10, "stacks up to 10 from his cuts")
	var st: BStatus = s.get_status("rekindle")
	t.ok(st != null and st.has_flag("dispellable") and st.expires_at < 0.0, "dispellable, no duration")
	s.hp = s.get_stats().max_health - 500.0
	var hp0: float = s.hp
	b.pipeline.normal_attack(h, s)
	t.near(s.hp - hp0, 10 * _x(2) - 100.0 * 100.0 / (100.0 + s.get_stats().defense), 1.0, "taking a hit: +x per stack, minus the hit")
	t.eq(s.status_stacks("rekindle"), 0, "then all stacks are used up")
	# 1 星：不灭还没解锁
	var b1 := Fixture.make([{"def": "node_samurai", "pos": Vector2(0, 0), "star": 1}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 1.0)}])
	b1.start()
	_run_until(b1, GC.START_DELAY + 3.0)
	t.eq(b1.units[0].status_stacks("rekindle"), 0, "1★: no Rekindle yet")
