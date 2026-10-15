extends RefCounted
## 蓝之章的事件(2026-10-15，docs/BLUE_CHAPTER.md)：宵禁(专属战场·宵禁广场 + 探照灯) / 等门的家政机 / 停摆的钟(蓝色事件)。


func _battle(specs: Array) -> Battle:
	var cat: Catalog = Fixture.catalog()
	var b: Battle = Fixture.make(specs, 3, Events.arena_layout(cat, "curfew_plaza"))
	b.start()
	b.advance_pending(0.0)
	return b


func _run_for(b: Battle, seconds: float) -> void:
	for i in range(int(round(seconds / GC.SIM_DT))):
		b.step()


func _events(b: Battle, type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in b.events:
		if str(e["t"]) == type:
			out.append(e)
	return out


func _pair(cat: Catalog, trig_id: String) -> Dictionary:
	for p: Dictionary in cat.terrain_pairs:
		if (p["trigger"] as TriggerDef).id == trig_id:
			return p
	return {}


func test_events_and_pools(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	for id: String in ["curfew", "waiting_android", "stopped_clock"]:
		t.ok(cat.events.has(id), "event %s exists" % id)
	t.eq(str(cat.events["curfew"]["pool"]["chapter"]), "ch1_blue", "the curfew only happens in the blue chapter")
	t.eq(str(cat.events["waiting_android"]["pool"]["chapter"]), "ch1_blue", "so does the waiting android")
	t.eq(str(cat.events["stopped_clock"]["pool"]["color"]), "blue", "the stopped clock is a blue event")
	t.ok(Events.pool_fits(cat.events["stopped_clock"], "ch2_purple", cat.chapters["ch2_purple"]), "…so it also shows up in the purple chapter (purple = red + blue)")
	t.ok(not Events.pool_fits(cat.events["stopped_clock"], "ch1_red", cat.chapters["ch1_red"]), "…but not in the red chapter")
	t.ok(not Events.pool_fits(cat.events["curfew"], "ch1_red", cat.chapters["ch1_red"]), "no curfew in the red chapter")
	t.eq(Events.validate_arenas(cat), [] as Array[String], "arenas validate")
	t.eq(cat.validate_all().filter(func(e: String) -> bool: return e.begins_with("arena") or e.begins_with("event") or e.begins_with("terrain")), [] as Array[String],
		"content validates")
	# 规则说明里的数字和数据对得上
	var hz: Dictionary = cat.arenas["curfew_plaza"]["hazards"][0]
	var hit: TriggerDef = _pair(cat, "terrain_searchlight_hit")["trigger"]
	var dz: AbilityDef = _pair(cat, "terrain_searchlight")["ability"]
	var rule: String = Loc.t_in("zh", "arena.curfew_plaza.rule")
	for num: String in ["%d 秒后" % int(hz["first"]), "每 %d 秒" % int(hz["period"]), "提前 %d 秒" % int(hz["warn"]),
			"%d%% 最大生命 + %d" % [int(round(hit.base_value_ratio * 100.0)), int(hit.base_value_flat)], "【过曝】%d 秒" % int(dz.effect_config["duration"]),
			"攻击速度 -%d%%" % int(round(-float(dz.effect_config["stats"]["attack_speed_multiplier"]["flat"]) * 100.0))]:
		t.ok(rule.contains(num), "the searchlight rule text says \"%s\"" % num)


## 探照灯：开战 first 秒后从西扫到东；照到的(不分敌我)各一次：12% 最大生命 + 70 的法术伤害 + 过曝；躲在全息亭 / 卡车背后的照不到
func test_the_searchlight_sweeps_and_shadows_protect(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var hz: Dictionary = cat.arenas["curfew_plaza"]["hazards"][0]
	# 我方：一个站在空地上(部署区北沿正中)，一个躲在西边全息亭(格子 9..10, 5)的影子里；敌方：一个站在东边的空地上
	var open_p: Vector2 = GC.cell_to_world(11, 7)
	var hide_p: Vector2 = GC.cell_to_world(8, 8)
	var foe_p: Vector2 = GC.cell_to_world(19, 6)
	var b: Battle = _battle([{"def": "test_dummy", "team": 0, "pos": open_p}, {"def": "test_dummy", "team": 0, "pos": hide_p},
		{"def": "test_dummy", "team": 1, "pos": foe_p}])
	t.ok(BattleMap.searchlight_exposed(b.map, hz, open_p), "the open spot is lit")
	t.ok(not BattleMap.searchlight_exposed(b.map, hz, hide_p), "the spot behind the kiosk is in shadow")
	t.ok(BattleMap.searchlight_exposed(b.map, hz, foe_p), "the enemy stands in the light too")
	_run_for(b, GC.START_DELAY + float(hz["first"]) - float(hz["warn"]) - 0.2)
	t.eq(_events(b, "hazard_hit").size(), 0, "nothing yet")
	_run_for(b, float(hz["warn"]) + float(hz["sweep"]) + 0.6)
	var hits: Array[Dictionary] = _events(b, "hazard_hit")
	var hit_ids: Array = hits.map(func(e: Dictionary) -> String: return (e["unit"] as BUnit).uid)
	t.ok(hit_ids.has(b.units[0].uid), "the unit in the open is caught")
	t.ok(not hit_ids.has(b.units[1].uid), "the one in the kiosk's shadow is not")
	t.ok(hit_ids.has(b.units[2].uid), "friend or foe")
	t.eq(hit_ids.count(b.units[0].uid), 1, "once per sweep")
	var dmg := 0.0
	for e: Dictionary in _events(b, "damage"):
		if e["dst"] == b.units[0] and str(e.get("kind", "")) == "magic":
			dmg += float(e["amount"]) + float(e.get("mitigated", 0.0))
	t.near(dmg, b.units[0].get_stats().max_health * 0.12 + 70.0, 1.0, "12%% max health + 70 (%.0f)" % dmg)
	t.ok(b.units[0].status_stacks("dazzled") > 0, "and dazzled")
	t.eq(str(b.hazards[0]["phase"]), "idle", "the sweep is over")
	t.near(float(b.hazard_info()[0]["eta"]), float(hz["first"]) + float(hz["period"]) - (b.time - GC.START_DELAY), 0.06, "next sweep %d s after the last one" % int(hz["period"]))


## 事件的结果：宵禁的「闯过广场」在宵禁广场打；停摆的钟「往回拨」= 下一场强度 -5；家政机「拆下核心」= 下一场 +4
func test_event_outcomes(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var dash: Dictionary = (cat.events["curfew"]["options"] as Array).filter(func(o: Dictionary) -> bool: return str(o["id"]) == "dash")[0]
	var ef: Dictionary = dash["outcomes"][0]["effects"][0]
	t.eq(str(ef["type"]), "battle", "making a run for it = a battle")
	t.eq(str(ef["arena"]), "curfew_plaza", "…in the curfew plaza")
	var r := Run.create(cat, 5)
	r.enter_chapter("ch1_blue", false)
	var base: int = int(r._make_encounter("fight", 20).get("intensity", 20))
	r.set_flag("next_battle_ease", 5.0, "next_battle")
	t.eq(int(r._make_encounter("fight", 20).get("intensity", 0)), base - 5, "turning the clock back: next battle -5 intensity")
	t.ok(Events.is_gain({"type": "flag", "id": "next_battle_ease", "value": 5}), "…which counts as a gain")
	t.ok(not Events.is_gain({"type": "flag", "id": "next_battle_intensity", "value": 4}), "the salvaged core's curse does not")
