extends RefCounted
## 蓝之章第二批(2026-10-15，docs/BLUE_CHAPTER.md)：BX-09 殉爆蛛机 / MR-05 维修无人机，
## 精英 GW-20 重装步行机 / CN-00 中枢主机 / RG-09 电磁轨道炮，首领 OS-00 箱庭管理者。


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


## src 的某个能力打出去的伤害(减伤前)：{目标 uid: 合计}
func _raw_by_target(evs: Array[Dictionary], src: BUnit, ability: String) -> Dictionary:
	var out := {}
	for e: Dictionary in _of(evs, "damage"):
		if e.get("src") == src and str(e.get("ability", "")) == ability:
			var dst: BUnit = e["dst"]
			out[dst.uid] = float(out.get(dst.uid, 0.0)) + float(e["amount"]) + float(e.get("mitigated", 0.0))
	return out


func test_data_and_chapter(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	for id: String in ["mob_bx_spider", "mob_mr_drone", "elite_gw_walker", "elite_cn_hub", "elite_rg_railgun", "boss_os_overseer"]:
		var d: UnitDef = cat.get_unit(id)
		t.ok(d != null and not d.available_in_shop, "%s exists and is not in the shop" % id)
		var amp := false
		for pa: AbilityDef in d.passives:
			if pa.has_keyword("amplify"):
				amp = true
		t.ok(amp, "%s: a passive carries 【Amplify】" % id)
	var ch: Dictionary = cat.chapters["ch1_blue"]
	var mons: Dictionary = ch["monsters"]
	for id2: String in ["mob_bx_spider", "mob_mr_drone", "elite_gw_walker", "elite_cn_hub", "elite_rg_railgun", "boss_os_overseer"]:
		t.ok(mons.has(id2), "the blue chapter prices %s" % id2)
	t.eq(str((ch["boss"] as Dictionary)["unit"]), "boss_os_overseer", "the blue chapter's own boss")
	var elites: Array = []
	for el: Dictionary in ch["elites"]:
		elites.append(str(el["unit"]))
	t.eq(elites, ["elite_gw_walker", "elite_cn_hub", "elite_rg_railgun"], "the blue chapter's own elites (no more red placeholders)")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


## 殉爆蛛机：倒下时 2.2 米内不分敌我各吃 攻击力 × 120% × 增幅；增幅按倒下那一刻(站在力场里 +2)；炸死旁边的蛛机 → 连锁
func test_spider_detonates_on_death(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "mob_bx_spider", "team": 1, "pos": Vector2(0, 0)}, {"def": "test_dummy", "pos": Vector2(1.2, 0)},
		{"def": "mob_ax_assault", "team": 1, "pos": Vector2(-1.2, 0)}, {"def": "test_dummy", "pos": Vector2(5.0, 0)}])
	var sp: BUnit = b.units[0]
	var near_foe: BUnit = b.units[1]
	var ally: BUnit = b.units[2]
	var far_foe: BUnit = b.units[3]
	b.start()
	_step(b, 0.1)
	var atk: float = sp.get_stats().attack_power
	sp.hp = 1.0
	b.pipeline.fx.damage(null, sp, 50.0, "true", {"surface": "test"})
	var evs: Array[Dictionary] = _step(b, 0.1)
	t.ok(not sp.alive, "the spider is destroyed")
	var by: Dictionary = _raw_by_target(evs, sp, "mob_bx_detonate")
	t.near(float(by.get(near_foe.uid, 0.0)), atk * 1.2 * 2.0, 1.0, "the enemy next to it takes attack × 120%% × 2 (%.0f)" % float(by.get(near_foe.uid, 0.0)))
	t.near(float(by.get(ally.uid, 0.0)), atk * 1.2 * 2.0, 1.0, "…and so does its own ally (friend or foe)")
	t.ok(not by.has(far_foe.uid), "nothing beyond 2.2 m")
	# 力场里倒下：增幅 4
	var b2 := Fixture.make([{"def": "mob_bx_spider", "team": 1, "pos": Vector2(0, 0)}, {"def": "test_dummy", "pos": Vector2(1.2, 0)}])
	var sp2: BUnit = b2.units[0]
	b2.start()
	b2.pipeline.fx.create_field(sp2, sp2.pos, {"kind": "amp", "radius": 2.5, "duration": 30.0}, 2.0)
	_step(b2, 0.2)
	sp2.hp = 1.0
	b2.pipeline.fx.damage(null, sp2, 50.0, "true", {"surface": "test"})
	var by2: Dictionary = _raw_by_target(_step(b2, 0.1), sp2, "mob_bx_detonate")
	t.near(float(by2.get(b2.units[1].uid, 0.0)), sp2.get_stats().attack_power * 1.2 * 4.0, 1.0, "dying inside an amp field: Amplify 4 at the moment it goes down")
	# 连锁殉爆
	var b3 := Fixture.make([{"def": "mob_bx_spider", "team": 1, "pos": Vector2(0, 0)}, {"def": "mob_bx_spider", "team": 1, "pos": Vector2(1.5, 0)},
		{"def": "test_dummy", "pos": Vector2(3.0, 0)}])
	b3.start()
	_step(b3, 0.1)
	b3.units[1].hp = 20.0
	b3.units[0].hp = 1.0
	b3.pipeline.fx.damage(null, b3.units[0], 50.0, "true", {"surface": "test"})
	var evs3: Array[Dictionary] = _step(b3, 0.1)
	t.ok(not b3.units[1].alive, "the blast takes out the second spider")
	t.ok(_raw_by_target(evs3, b3.units[1], "mob_bx_detonate").has(b3.units[2].uid), "…which detonates in turn (chain reaction)")


## 维修无人机：每 2 秒修生命比例最低的友方机器 攻击力 × 75% × 增幅；没人受伤就不修
func test_drone_repairs_lowest_ally(t: TestCtx) -> void:
	# (载具离远一点：它开战时在脚下放的增幅力场会让无人机的增幅变成 4)
	var b := Fixture.make([{"def": "mob_mr_drone", "team": 1, "pos": Vector2(0, 0)}, {"def": "mob_hv_carrier", "team": 1, "pos": Vector2(7, 0)},
		{"def": "mob_ax_assault", "team": 1, "pos": Vector2(-2, 0)}, {"def": "test_dummy", "pos": Vector2(0, 9.0)}])
	var dr: BUnit = b.units[0]
	var hv: BUnit = b.units[1]
	var ax: BUnit = b.units[2]
	b.start()
	_step(b, 0.1)
	hv.hp = hv.get_stats().max_health * 0.5
	ax.hp = ax.get_stats().max_health * 0.3
	var hv0: float = hv.hp
	var ax0: float = ax.hp
	var evs: Array[Dictionary] = _step(b, GC.START_DELAY + 2.1)
	var heals := 0
	for e: Dictionary in _of(evs, "heal"):
		if e.get("src") == dr:
			heals += 1
			t.eq(e.get("dst"), ax, "repairs the one with the lowest health ratio")
	t.ok(heals >= 1, "it repaired (%d)" % heals)
	t.near(ax.hp - ax0, dr.get_stats().attack_power * 0.75 * 2.0 * float(heals), 1.0, "attack × 75%% × 2 per repair")
	t.near(hv.hp, hv0, 0.01, "the carrier waits its turn")


## 重装步行机：开战 6 秒过载(增幅 +3、攻速 +60%) → 5 秒后过热 3 秒(眩晕、受伤 +50%) → 6 秒后再过载；震荡锤打一圈
func test_walker_overload_cycle(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "elite_gw_walker", "team": 1, "pos": Vector2(0, 0)}, {"def": "test_dummy", "pos": Vector2(0, 1.6)},
		{"def": "test_dummy", "pos": Vector2(1.2, 2.2)}, {"def": "test_dummy", "pos": Vector2(0, 7.0)}])
	var gw: BUnit = b.units[0]
	gw.meta["elite"] = true
	b.start()
	var evs: Array[Dictionary] = _step(b, 5.0)
	t.eq(gw.status_stacks("gw_overload"), 0, "not overloaded yet at 5 s")
	evs.append_array(_step(b, 2.0))
	t.eq(gw.status_stacks("gw_overload"), 1, "overloaded at 7 s")
	t.near(gw.get_stats().passive_amplify_bonus, 3.0, 0.001, "Overload: +3 Amplify")
	evs.append_array(_step(b, 5.0))
	t.eq(gw.status_stacks("gw_overheat"), 1, "then it overheats")
	t.ok(gw.is_stunned(), "Overheat: it can't act")
	var st: BStatus = gw.statuses.get("gw_overheat")
	t.ok(st != null and st.expires_at - b.time > 1.0, "…for the full 3 s (elite stun halving doesn't apply)")
	evs.append_array(_step(b, 3.5))
	t.eq(gw.status_stacks("gw_overheat"), 0, "the overheat ends")
	t.ok(not gw.is_stunned(), "and it moves again")
	evs.append_array(_step(b, 6.5))
	t.eq(gw.status_stacks("gw_overload"), 1, "and overloads again after cooling for 6 s")
	# 震荡锤：命中时目标周围 2.4 米内的敌人都吃一下
	var quake: Dictionary = _raw_by_target(evs, gw, "elite_gw_quake")
	t.ok(quake.has(b.units[1].uid) and quake.has(b.units[2].uid), "the shock hammer hits the target and the enemy beside it")
	t.ok(not quake.has(b.units[3].uid), "…but not one 7 m away")


## 中枢主机：全场的友方挂上增幅链路；倒下的机器 4 秒后在中枢身边以 50% 生命重新组装，每台一次；中枢倒下 → 作废；不攻击
func test_hub_broadcast_and_rebuild(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "elite_cn_hub", "team": 1, "pos": Vector2(0, -6)}, {"def": "mob_ax_assault", "team": 1, "pos": Vector2(0, 3)},
		{"def": "mob_sg_sentry", "team": 1, "pos": Vector2(6, -2)}, {"def": "test_dummy", "pos": Vector2(0, 9.0)}])
	var hub: BUnit = b.units[0]
	var ax: BUnit = b.units[1]
	var sg: BUnit = b.units[2]
	b.start()
	_step(b, GC.START_DELAY + 4.2)
	t.eq(sg.status_stacks("amp_link"), 1, "the far-away turret is linked too (whole field)")
	t.near(ax.get_stats().passive_amplify_bonus, 2.0, 0.001, "Amp Link +2")
	t.ok(hub.has_flag("disarm"), "the hub never attacks")
	ax.hp = 1.0
	b.pipeline.fx.damage(null, ax, 50.0, "true", {"surface": "test"})
	_step(b, 3.5)
	t.ok(not ax.alive, "still down after 3.5 s")
	var evs: Array[Dictionary] = []
	for i in range(20):
		evs.append_array(_step(b, 0.05))
		if ax.alive:
			break
	t.ok(ax.alive, "reassembled after 4 s")
	t.near(ax.hp, ax.get_stats().max_health * 0.5, 1.0, "at 50% health")
	t.ok(ax.pos.distance_to(hub.pos) < 2.5, "beside the hub (%.2f m)" % ax.pos.distance_to(hub.pos))
	t.ok(not _of(evs, "reassemble_done").is_empty(), "the view is told")
	ax.hp = 1.0
	b.pipeline.fx.damage(null, ax, 50.0, "true", {"surface": "test"})
	_step(b, 5.0)
	t.ok(not ax.alive, "only once per machine")
	# 中枢倒下：还没组装好的作废
	sg.hp = 1.0
	b.pipeline.fx.damage(null, sg, 50.0, "true", {"surface": "test"})
	_step(b, 1.0)
	hub.hp = 1.0
	b.pipeline.fx.damage(null, hub, 50.0, "true", {"surface": "test"})
	_step(b, 4.0)
	t.ok(not sg.alive, "the hub falls → the pending rebuild is lost")


## 电磁轨道炮：每 9 秒锁定最远的敌人吟唱 3 秒 → 贯穿线上的敌人各吃 攻击力 × 60% × 增幅；线外的不吃；被打断就没有
func test_railgun_charged_shot(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "elite_rg_railgun", "team": 1, "pos": Vector2(0, -8)}, {"def": "test_dummy", "pos": Vector2(0, 2.0)},
		{"def": "test_dummy", "pos": Vector2(0.3, -3.0)}, {"def": "test_dummy", "pos": Vector2(-3.0, -5.0)}])
	var rg: BUnit = b.units[0]
	var far: BUnit = b.units[1]
	var mid: BUnit = b.units[2]
	var side: BUnit = b.units[3]
	b.start()
	var evs: Array[Dictionary] = _step(b, GC.START_DELAY + 9.2)
	t.eq(rg.phase, "chant", "charging at 9 s")
	t.eq(rg.target, far, "locked onto the farthest enemy")
	evs.append_array(_step(b, 3.2))
	var by: Dictionary = _raw_by_target(evs, rg, "elite_rg_charge")
	var want: float = rg.get_stats().attack_power * 0.6 * 2.0
	t.near(float(by.get(far.uid, 0.0)), want, 1.0, "the locked target takes attack × 60%% × 2 (%.0f)" % float(by.get(far.uid, 0.0)))
	t.near(float(by.get(mid.uid, 0.0)), want, 1.0, "the enemy standing on the line too (piercing)")
	t.ok(not by.has(side.uid), "the one off the line is spared")
	# 被打断：白充
	var b2 := Fixture.make([{"def": "elite_rg_railgun", "team": 1, "pos": Vector2(0, -8)}, {"def": "test_dummy", "pos": Vector2(0, 2.0)}])
	var rg2: BUnit = b2.units[0]
	b2.start()
	var evs2: Array[Dictionary] = _step(b2, GC.START_DELAY + 9.5)
	t.eq(rg2.phase, "chant", "charging")
	b2.interrupt(rg2)
	evs2.append_array(_step(b2, 3.5))
	t.ok(_raw_by_target(evs2, rg2, "elite_rg_charge").is_empty(), "interrupted → the charge is wasted")


## 箱庭管理者：每 10 秒 +1 层系统升级(增幅 +1)；格栅 1.5 秒后落下，只打还站在里面的；每 24 秒吟唱 3 秒全域清除
func test_overseer_kit(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "boss_os_overseer", "team": 1, "pos": Vector2(0, -8)}, {"def": "test_dummy", "pos": Vector2(-3, 4.0)},
		{"def": "test_dummy", "pos": Vector2(3, 4.0)}])
	var os: BUnit = b.units[0]
	os.meta["boss"] = true
	b.start()
	var evs: Array[Dictionary] = _step(b, GC.START_DELAY + 5.2)
	var marks: Array[Dictionary] = _of(evs, "grid_mark")
	t.eq(marks.size(), 2, "grids under (up to 3, here both) enemies at 5 s")
	t.ok(_of(evs, "grid_land").is_empty(), "not landed yet")
	evs = _step(b, 1.5)
	t.eq(_of(evs, "grid_land").size(), 2, "…they drop 1.5 s later")
	var by: Dictionary = _raw_by_target(evs, os, "boss_os_grid")
	var atk: float = os.get_stats().attack_power
	t.near(float(by.get(b.units[1].uid, 0.0)), atk * 0.25 * 2.0, 1.0, "attack × 25%% × 2 (%.0f)" % float(by.get(b.units[1].uid, 0.0)))
	_step(b, 4.0)
	t.eq(os.status_stacks("os_upgrade"), 1, "1 stack of System Upgrade at 10 s")
	t.near(os.get_stats().passive_amplify_bonus, 1.0, 0.001, "+1 Amplify")
	# 全域清除：24 秒开始吟唱，27 秒落下
	var evs2: Array[Dictionary] = _step(b, GC.START_DELAY + 24.2 - b.time)
	t.eq(os.phase, "chant", "chanting Total Purge at 24 s")
	evs2.append_array(_step(b, 3.2))
	var pg: Dictionary = _raw_by_target(evs2, os, "boss_os_purge")
	t.eq(pg.size(), 2, "the purge hits every enemy")
	t.near(float(pg.get(b.units[2].uid, 0.0)), atk * 0.4 * (2.0 + 2.0), 1.0, "attack × 40%% × (2 + 2 upgrades) (%.0f)" % float(pg.get(b.units[2].uid, 0.0)))
