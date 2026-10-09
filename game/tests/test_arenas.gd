extends RefCounted
## 事件战斗的专属战场(Catalog.arenas)：电车站(电车按时刻表冲过战场) / 公园喷泉(喷泉周期性喷发)。
## 战场机制只发地形事件 OnTerrainHit，伤害 / 燃烧走 terrain.json 的"触发器 + 能力"。


func _battle(arena: String, specs: Array) -> Battle:
	var cat: Catalog = Fixture.catalog()
	var b: Battle = Fixture.make(specs, 3, Events.arena_layout(cat, arena))
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


func test_arenas_validate_and_match_their_events(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	t.eq(cat.arenas.keys().size(), 2, "two arenas: the park fountain and the tram stop")
	t.eq(Events.validate_arenas(cat), [], "arenas validate")
	t.eq(cat.validate_all().filter(func(e: String) -> bool: return e.begins_with("arena") or e.begins_with("event") or e.begins_with("terrain")), [], "content validates")
	for pr: Array in [["burning_fountain", "fountain_park"], ["last_tram", "tram_stop"]]:
		var ev: Dictionary = cat.events[pr[0]]
		t.eq(str(ev["scene"]), str(cat.arenas[pr[1]]["set"]), "%s: the event picture is the battlefield's own set" % pr[0])
		var found := false
		for o: Dictionary in ev["options"]:
			for oc: Dictionary in o["outcomes"]:
				for ef: Dictionary in oc["effects"]:
					if str(ef.get("type", "")) == "battle":
						found = found or str(ef.get("arena", "")) == pr[1]
		t.ok(found, "%s: its battle is fought in %s" % [pr[0], pr[1]])
	# 规则说明里的数字和数据对得上
	var tram: Dictionary = cat.arenas["tram_stop"]["hazards"][0]
	var hit: TriggerDef = _pair(cat, "terrain_tram_hit")["trigger"]
	var burn: AbilityDef = _pair(cat, "terrain_tram")["ability"]
	var rule: String = Loc.t_in("zh", "arena.tram_stop.rule")
	for num: String in ["%d 秒后" % int(tram["first"]), "每 %d 秒" % int(tram["period"]), "提前 %d 秒" % int(tram["warn"]),
			"%d%% 最大生命 + %d" % [int(round(hit.base_value_ratio * 100.0)), int(hit.base_value_flat)], "【燃烧】%d 秒" % int(burn.effect_config["duration"])]:
		t.ok(rule.contains(num), "the tram rule text says \"%s\"" % num)
	var fountain: Dictionary = cat.arenas["fountain_park"]["hazards"][0]
	var arc: TriggerDef = _pair(cat, "terrain_fire_arc_hit")["trigger"]
	var rule2: String = Loc.t_in("zh", "arena.fountain_park.rule")
	for num2: String in ["%d 秒后" % int(fountain["first"]), "每 %d 秒" % int(fountain["period"]), "%d 道火弧" % (fountain["embers"] as Array).size(),
			"]%d[" % int(arc.base_value_flat)]:
		t.ok(rule2.contains(num2), "the fountain rule text says \"%s\"" % num2)


func test_the_tram_runs_on_schedule_and_hits_whatever_is_on_the_track(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var hz: Dictionary = cat.arenas["tram_stop"]["hazards"][0]
	var z: float = float(hz["z"])
	# 木桩：我方一个站在轨道上、一个站在轨道南边；敌方一个站在轨道上(更靠东)、一个站在北边的站台上
	var b: Battle = _battle("tram_stop", [{"def": "test_dummy", "team": 0, "pos": Vector2(-2.0, z)}, {"def": "test_dummy", "team": 0, "pos": Vector2(-2.0, z + 2.0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(5.0, z + 0.4)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0.0, z - 2.0)}])
	var on_track: BUnit = b.units[0]
	var south: BUnit = b.units[1]
	var foe_on_track: BUnit = b.units[2]
	var foe_platform: BUnit = b.units[3]
	t.ok(b.map.has_terrain() and b.hazards.size() == 1, "the arena carries one hazard")
	t.eq(str(b.hazards[0]["phase"]), "idle", "the tram waits")
	_run_for(b, GC.START_DELAY + float(hz["first"]) - float(hz["warn"]) - 0.2)
	t.eq(_events(b, "hazard").size(), 0, "nothing yet")
	t.near(float(b.hazard_info()[0]["eta"]), float(hz["warn"]) + 0.2, 0.06, "the countdown the HUD shows")
	_run_for(b, 0.4)
	t.eq(str(b.hazards[0]["phase"]), "warn", "3 s ahead: the crossing warning")
	t.eq(str(_events(b, "hazard")[0]["ev"]), "warn", "…as a hazard(warn) event for the view")
	t.near(on_track.hp, on_track.get_stats().max_health, 0.01, "nobody is hurt during the warning")
	_run_for(b, float(hz["warn"]) + 3.9)
	var evs: Array = []
	for e: Dictionary in _events(b, "hazard"):
		evs.append(str(e["ev"]))
	t.eq(evs, ["warn", "go", "end"], "warn → go → end")
	t.eq(str(b.hazards[0]["phase"]), "idle", "the tram is through")
	t.near(float(b.hazards[0]["next"]), float(hz["first"]) + float(hz["period"]), 0.001, "the next one is due 13 s after the first")
	# 轨道上的两个都被撞了：物理伤害 = 20% 最大生命 + 120(木桩 0 防御) + 4 秒【燃烧】，并且被撞出了轨道
	var mh: float = on_track.get_stats().max_health
	var hits: Array[Dictionary] = _events(b, "hazard_hit")
	t.eq(hits.size(), 2, "two units were on the track")
	for u: BUnit in [on_track, foe_on_track]:
		var phys := 0.0
		for d: Dictionary in _events(b, "damage"):
			if d["dst"] == u and str(d["kind"]) == "physical":
				phys += float(d["amount"])
				t.ok(d["src"] == null, "the hit has no source unit")
		t.near(phys, mh * 0.2 + 120.0, 0.5, "hit once for 20%% max health + 120 (%.0f)" % phys)
		t.ok(u.status_count("burning") == 1 or mh - u.hp > phys + 20.0, "and set alight")
		t.ok(absf(u.pos.y - z) > float(hz["half_width"]) + 0.2, "knocked off the track (z = %.2f)" % u.pos.y)
		t.ok(u.phase != "dash", "…and back on its feet")
	t.ok(on_track.pos.y > z and foe_on_track.pos.y > z, "thrown to the side they were nearer to")
	t.near(south.hp, mh, 0.01, "the unit south of the track is untouched")
	t.near(foe_platform.hp, mh, 0.01, "the unit on the platform is untouched")
	t.eq(on_track.st_damage + south.st_damage + foe_on_track.st_damage + foe_platform.st_damage, 0.0, "nobody is credited with the damage")
	# 第二班
	var hp1: float = on_track.hp
	on_track.pos = Vector2(-2.0, z)
	_run_for(b, float(hz["period"]))
	t.ok(hp1 - on_track.hp > mh * 0.2 + 100.0, "the second tram hits again (lost %.0f)" % (hp1 - on_track.hp))


func test_the_fountain_erupts_and_relights_its_embers(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var arena: Dictionary = cat.arenas["fountain_park"]
	var hz: Dictionary = arena["hazards"][0]
	var spot: Dictionary = arena["embers"][3]
	var on_spot: Vector2 = GC.cell_to_world(int(spot["x"]), int(spot["y"]))
	var b: Battle = _battle("fountain_park", [{"def": "test_dummy", "team": 0, "pos": on_spot}, {"def": "test_dummy", "team": 0, "pos": GC.cell_to_world(12, 12)},
		{"def": "test_dummy", "team": 1, "pos": GC.cell_to_world(4, 15)}])
	var u: BUnit = b.units[0]
	var far: BUnit = b.units[1]
	var mh: float = u.get_stats().max_health
	t.eq(b.map.embers.size(), 7, "seven scorch marks around the fountain")
	_run_for(b, GC.START_DELAY + 0.5)
	t.eq(u.status_count("burning"), 1, "the marks start lit: standing on one burns")
	t.ok(not bool(b.map.embers[3]["lit"]), "…and it goes out, like any ember patch")
	_run_for(b, float(hz["first"]) - float(hz["warn"]) - 0.3)
	t.eq(_events(b, "hazard").size(), 1, "the fountain gathers itself (warn)")
	_run_for(b, float(hz["warn"]))
	var go: Array[Dictionary] = _events(b, "hazard")
	t.eq(str(go[go.size() - 1]["ev"]), "go", "the eruption")
	t.eq(_events(b, "ember_lit").size(), 0, "the arcs are still in the air")
	var hp0: float = u.hp
	_run_for(b, float(hz["flight"]) + 0.3)
	t.eq(_events(b, "ember_lit").size(), 7, "all seven marks are relit")
	var magic := 0.0
	for d: Dictionary in _events(b, "damage"):
		if d["dst"] == u and str(d.get("ability", "")) == "terrain_fire_arc_hit_dmg":
			magic += float(d["amount"])
			t.ok(d["src"] == null, "the arc has no source unit")
	t.near(magic, 80.0, 0.5, "the arc lands on the unit: 80 magic damage")
	t.ok(u.status_count("burning") >= 1 and not bool(b.map.embers[3]["lit"]), "and it stands in the fresh embers: burning again, patch out")
	t.ok(hp0 - u.hp >= 80.0, "lost %.0f" % (hp0 - u.hp))
	t.ok(bool(b.map.embers[0]["lit"]) and bool(b.map.embers[6]["lit"]), "the other marks burn until someone steps on them")
	t.near(far.hp, mh, 0.01, "a unit away from the marks is untouched")
	t.near(float(b.hazards[0]["next"]), float(hz["first"]) + float(hz["period"]), 0.001, "next eruption 9 s later")
	# 紧挨着喷泉 = 燃烧废墟的灼烧
	far.pos = GC.cell_to_world(9, 5)
	_run_for(b, 1.2)
	t.ok(far.status_count("burning") >= 1, "right next to the fountain: Burning every second")


func test_event_battles_are_fought_in_their_arena(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	for pr: Array in [["last_tram", 1, "tram_stop"], ["burning_fountain", 1, "fountain_park"]]:
		for s in range(12):
			var r := Run.create(cat, 400 + s, "ch1_red")
			var key := ""
			for k: String in (r.gmap["nodes"] as Dictionary).keys():
				if str(r.gnode(k).get("type", "")) == "event" and key == "":
					key = k
			r.pos = key
			r.phase = "event"
			r.event_state = {"id": pr[0], "node": key, "option": -1, "outcome": ""}
			var opt: Dictionary = (cat.events[pr[0]]["options"] as Array)[int(pr[1])]
			for oc: Dictionary in opt["outcomes"]:
				for ef: Dictionary in oc["effects"]:
					if str(ef.get("type", "")) == "battle":
						r.event_state["option"] = int(pr[1])
						r.event_state["battle"] = ef
			r.event_continue()
			t.eq(r.phase, "prepare", "%s: into the battle" % pr[0])
			var layout: Dictionary = r.current_layout()
			t.eq(str(layout.get("arena", "")), str(pr[2]), "fought in its own arena")
			t.eq(layout["obstacles"], cat.arenas[pr[2]]["obstacles"], "the arena's obstacles, not a random map")
			t.eq((layout["hazards"] as Array).size(), 1, "with its hazard")
			var allowed: Array = cat.arenas[pr[2]]["regions"]
			var setup: Dictionary = r.build_battle_setup()
			var m: BattleMap = r.current_map()
			for e: Array in r.wave_def()["units"]:
				t.ok(allowed.has(str(e[2])), "enemies come from the arena's regions (%s)" % str(e[2]))
			for su: Dictionary in setup["units"]:
				if int(su["team"]) != 1:
					continue
				var p: Vector2 = su["pos"]
				t.ok(m.point_free(p), "enemy spawns on open ground")
				if str(pr[2]) == "tram_stop":
					t.ok(p.y < -5.0, "the passengers stand on the platform, north of the track (z = %.1f)" % p.y)
		# 打一场：机制不会卡住战斗
	var r2 := Run.create(cat, 77, "ch1_red")
	for arena: String in ["tram_stop", "fountain_park"]:
		var b: Battle = Fixture.make([{"def": "node_darkknight", "team": 0, "pos": GC.cell_to_world(11, 7)}, {"def": "node_archer", "team": 0, "pos": GC.cell_to_world(13, 8)},
			{"def": "mob_ember_lust", "team": 1, "pos": GC.cell_to_world(12, 4)}, {"def": "mob_ember_sloth", "team": 1, "pos": GC.cell_to_world(5, 4)}], 5, Events.arena_layout(cat, arena))
		b.run_to_end()
		t.ok(b.state == "ended", "%s: a real fight plays out (%.1f s, winner %d)" % [arena, b.time, b.winner])
	t.ok(r2 != null, "done")
