extends RefCounted
## 第一章-B·蓝之章的机械造物(2026-10-07 第一版 4 只普通怪物)：核心原语是【增幅】——
## RX 增幅中继给周围友军加"被动技能的增幅"，HV 场域载具放出增幅力场(地形：站在里面的所有单位增幅临时提升)，
## SG 哨戒炮台 / AX 突击仿生人是吃增幅的输出终端。


func _step(b: Battle, seconds: float) -> Array[Dictionary]:
	var evs: Array[Dictionary] = []
	for i in range(int(round(seconds / GC.SIM_DT))):
		b.step()
		evs.append_array(b.poll_events())
	return evs


static func _of(evs: Array[Dictionary], type: String) -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for e: Dictionary in evs:
		if e.get("t") == type:
			r.append(e)
	return r


## src 对 dst 造成的 surface 类伤害之和(surface = normal_attack / passive …)
func _dmg(evs: Array[Dictionary], src: BUnit, surface: String) -> Array:
	var total := 0.0
	var n := 0
	for e: Dictionary in _of(evs, "damage"):
		if e.get("src") == src and str(e.get("surface", "")) == surface:
			total += float(e["amount"])
			n += 1
	return [total, n]


func test_unit_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	for id: String in ["mob_sg_sentry", "mob_rx_relay", "mob_hv_carrier", "mob_ax_assault"]:
		var d: UnitDef = cat.get_unit(id)
		t.ok(d != null and not d.available_in_shop and d.hide_weapon, "%s exists, not in the shop, weapon built in" % id)
		t.ok(ResourceLoader.exists("res://assets/unit_body_%s.res" % d.model), "%s has a body model (%s)" % [id, d.model])
		var amp := false
		for pa: AbilityDef in d.passives:
			if pa.has_keyword("amplify"):
				amp = true
		t.ok(amp, "%s: its passive carries 【Amplify】" % id)
	t.near(cat.get_unit("mob_sg_sentry").base_stats.move_speed, 0.0, 0.0001, "the sentry turret never moves")
	t.eq(cat.get_unit("mob_sg_sentry").base_weapon_class, "rifle", "the turret shoots like a rifle (long range)")
	t.eq(cat.get_unit("mob_hv_carrier").role, "tank", "the carrier is the tank")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


## 哨戒炮台：每次普攻命中追加 攻击力 × 25% × 增幅 的法术伤害；增幅 2 → +50%，站在增幅力场里 +2 → 增幅 4 → +100%
func test_sentry_turret_scales_with_amplify(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "mob_sg_sentry", "team": 1, "pos": Vector2(0, 3.0)}, {"def": "test_dummy", "pos": Vector2(0, 0)}])
	var sg: BUnit = b.units[0]
	b.start()
	var evs: Array[Dictionary] = _step(b, GC.START_DELAY + 4.0)
	var na: Array = _dmg(evs, sg, "normal_attack")
	var sk: Array = _dmg(evs, sg, "passive")
	t.ok(int(na[1]) >= 3, "the turret fires (%d hits)" % int(na[1]))
	t.eq(int(sk[1]), int(na[1]), "every hit adds a fire-control bolt")
	var atk: float = sg.get_stats().attack_power
	var per_hit: float = float(sk[0]) / maxf(1.0, float(sk[1]))
	# 木桩有魔抗：按减伤前的数值比(事件带 mitigated)
	var raw := 0.0
	var rn := 0
	for e: Dictionary in _of(evs, "damage"):
		if e.get("src") == sg and str(e.get("surface", "")) == "passive":
			raw += float(e["amount"]) + float(e.get("mitigated", 0.0))
			rn += 1
	t.near(raw / maxf(1.0, float(rn)), atk * 0.25 * 2.0, atk * 0.02, "bonus = attack × 25%% × Amplify 2 (%.1f per hit)" % (raw / maxf(1.0, float(rn))))
	t.ok(per_hit > 0.0, "and it lands (%.1f after resistance)" % per_hit)
	# 站在增幅力场里：增幅 +2
	var b2 := Fixture.make([{"def": "mob_sg_sentry", "team": 1, "pos": Vector2(0, 3.0)}, {"def": "test_dummy", "pos": Vector2(0, 0)}])
	var sg2: BUnit = b2.units[0]
	b2.start()
	b2.pipeline.fx.create_field(sg2, sg2.pos, {"kind": "amp", "radius": 2.5, "duration": 30.0}, 2.0)
	var evs2: Array[Dictionary] = _step(b2, GC.START_DELAY + 4.0)
	t.eq(sg2.status_stacks("amp_field"), 1, "standing in the field: 【Amp Field】 on it")
	t.near(sg2.get_stats().passive_amplify_bonus, 2.0, 0.001, "+2 Amplify to its passives")
	var raw2 := 0.0
	var rn2 := 0
	for e2: Dictionary in _of(evs2, "damage"):
		if e2.get("src") == sg2 and str(e2.get("surface", "")) == "passive":
			raw2 += float(e2["amount"]) + float(e2.get("mitigated", 0.0))
			rn2 += 1
	t.near(raw2 / maxf(1.0, float(rn2)), atk * 0.25 * 4.0, atk * 0.03, "in the field the bolt is attack × 25% × 4 (%.1f)" % (raw2 / maxf(1.0, float(rn2))))


## 增幅中继：每 4 秒给 4 米内的友军【增幅链路】5 秒(被动增幅 +1)；远的拿不到；中继倒下 5 秒后链路消失
func test_relay_links_nearby_allies(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "mob_rx_relay", "team": 1, "pos": Vector2(0, 4.0)}, {"def": "mob_sg_sentry", "team": 1, "pos": Vector2(2.0, 4.0)},
		{"def": "mob_sg_sentry", "team": 1, "pos": Vector2(7.0, 6.0)}, {"def": "test_dummy", "pos": Vector2(0, -3.0)}])
	var rx: BUnit = b.units[0]
	var near: BUnit = b.units[1]
	var far: BUnit = b.units[2]
	b.start()
	_step(b, GC.START_DELAY + 4.4)
	t.eq(near.status_stacks("amp_link"), 1, "the turret 2 m away is linked")
	t.near(near.get_stats().passive_amplify_bonus, 2.0, 0.001, "+2 Amplify")
	t.eq(far.status_stacks("amp_link"), 0, "the one 7 m away isn't")
	t.near(far.get_stats().passive_amplify_bonus, 0.0, 0.001, "…and has no bonus")
	t.ok(rx.status_stacks("amp_link") >= 0, "the relay may link itself too")
	var amp_before: int = Pipeline.kw_value(near, near.def.passives[0], "amplify", 0)
	t.eq(amp_before, 4, "the linked turret's Fire Control runs at Amplify 4")
	# 中继倒下：链路不再刷新，5 秒后掉光
	b.pipeline.fx.damage(b.units[3], rx, 99999.0, "true")
	t.ok(not rx.alive, "the relay is destroyed")
	_step(b, 5.5)
	t.eq(near.status_stacks("amp_link"), 0, "the link expires 5 s after the last broadcast")
	t.eq(Pipeline.kw_value(near, near.def.passives[0], "amplify", 0), 2, "back to Amplify 2")


## 场域载具：开战时在脚下放一片增幅力场(半径 2.5 米、6 秒)，之后每 8 秒再放；场里不分敌我都 +2 增幅，出去 / 到期就没了
func test_carrier_lays_an_amp_field(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "mob_hv_carrier", "team": 1, "pos": Vector2(0, 2.0)}, {"def": "mob_ax_assault", "team": 1, "pos": Vector2(1.5, 2.0)},
		{"def": "test_dummy", "pos": Vector2(0, 0.5)}, {"def": "test_dummy", "pos": Vector2(0, -6.0)}])
	var hv: BUnit = b.units[0]
	var ax: BUnit = b.units[1]
	var inside: BUnit = b.units[2]
	var outside: BUnit = b.units[3]
	hv.base.move_speed = 0.0
	hv.mark_dirty()
	b.start()
	_step(b, 0.5)
	t.eq(b.fields.size(), 1, "a field at the start of battle")
	var f: Dictionary = b.fields[0]
	t.eq(str(f["kind"]), "amp", "an amp field")
	t.near(float(f["radius"]), 2.5, 0.001, "radius 2.5 m")
	t.near(float(f["amp"]), 2.0, 0.001, "+2 Amplify inside")
	t.ok((f["pos"] as Vector2).distance_to(Vector2(0, 2.0)) < 0.3, "laid under the carrier")
	t.eq(hv.status_stacks("amp_field"), 1, "the carrier stands in its own field")
	t.eq(inside.status_stacks("amp_field"), 1, "the enemy 1.5 m away is in it too (friend or foe)")
	t.near(inside.get_stats().passive_amplify_bonus, 2.0, 0.001, "…and gets the +2")
	t.eq(outside.status_stacks("amp_field"), 0, "the one 8 m away isn't")
	t.eq(Pipeline.kw_value(ax, ax.def.passives[0], "amplify", 0), 3, "the assault android in the field runs its protocol at Amplify 3")
	# 走出去就掉：把里面那个挪到力场外(3.5 米，还在手弩射程里——AI 不会换目标，载具接着打它)
	inside.pos = Vector2(0, -1.5)
	_step(b, 0.6)
	t.eq(inside.status_stacks("amp_field"), 0, "stepping out, the bonus fades within half a second")
	# 投射：每第 4 次普攻命中把力场铺到目标脚下
	var hits := 0
	var projected := false
	for i in range(int(round(6.0 / GC.SIM_DT))):
		b.step()
		for ev: Dictionary in b.poll_events():
			if str(ev.get("t", "")) == "damage" and ev.get("src") == hv and str(ev.get("surface", "")) == "normal_attack":
				hits += 1
		for f2: Dictionary in b.fields:
			if (f2["pos"] as Vector2).distance_to(inside.pos) < 0.5:
				projected = true
		if projected:
			break
	t.ok(projected, "a field is projected under the target the carrier is shooting")
	t.eq(hits, 4, "…on the 4th normal-attack hit (got %d hits)" % hits)
	_step(b, 0.1)                                   # 力场的状态在下一帧由 _step_fields 刷新
	t.eq(inside.status_stacks("amp_field"), 1, "the target stands in the projected field")
	# 到期：开战时铺在脚下的那片 6 秒后消失(之后场上只剩投射到目标脚下的)
	_step(b, GC.START_DELAY + 6.5 - b.time)
	var start_left := false
	for f3: Dictionary in b.fields:
		if (f3["pos"] as Vector2).distance_to(Vector2(0, 2.0)) < 0.3:
			start_left = true
	t.ok(not start_left, "the starting field is gone after 6 s")


## 突击仿生人：每第 3 次普攻命中追加 攻击力 × 60% × 增幅 的物理伤害
func test_assault_android_third_hit(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "mob_ax_assault", "team": 1, "pos": Vector2(0, 0.7)}, {"def": "test_dummy", "pos": Vector2(0, 0)}])
	var ax: BUnit = b.units[0]
	b.start()
	var evs: Array[Dictionary] = _step(b, GC.START_DELAY + 4.0)
	var na: Array = _dmg(evs, ax, "normal_attack")
	var sk: Array = _dmg(evs, ax, "passive")
	t.ok(int(na[1]) >= 6, "it slashes (%d hits)" % int(na[1]))
	t.eq(int(sk[1]), int(na[1]) / 3, "every 3rd hit adds the full-power stroke (%d of %d)" % [int(sk[1]), int(na[1])])
	var raw := 0.0
	for e: Dictionary in _of(evs, "damage"):
		if e.get("src") == ax and str(e.get("surface", "")) == "passive":
			raw += float(e["amount"]) + float(e.get("mitigated", 0.0))
	var atk: float = ax.get_stats().attack_power
	t.near(raw / maxf(1.0, float(sk[1])), atk * 0.6 * 1.0, atk * 0.02, "stroke = attack × 60% × Amplify 1")


## 蓝之章的配怪：普通作战只出这四种机器(精英 / 首领仍是红之章的占位)
func test_blue_chapter_spawns_the_machines(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var ch: Dictionary = cat.chapters["ch1_blue"]
	var mobs: Array = ["mob_sg_sentry", "mob_rx_relay", "mob_hv_carrier", "mob_ax_assault"]
	for id: String in mobs:
		t.ok((ch["monsters"] as Dictionary).has(id), "%s has strength points" % id)
	for fm: Dictionary in ch["formations"]:
		for u: String in (fm["req"] as Array) + (fm["extra"] as Array):
			t.ok(mobs.has(u), "formation unit %s is a dome machine" % u)
	var r := Run.create(cat, 9)
	r.enter_chapter("ch1_blue", false)
	var seen := {}
	for iv in [12, 20, 30]:
		var enc: Dictionary = r._make_encounter("fight", iv)
		for e: Array in enc["units"]:
			seen[str(e[0])] = true
			t.ok(mobs.has(str(e[0])), "intensity %d spawns %s" % [iv, str(e[0])])
	t.ok(seen.size() >= 3, "several kinds of machine show up (%s)" % str(seen.keys()))
