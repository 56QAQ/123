extends RefCounted
## 事件节点：事件池(通用 / 特定章节 / 特定颜色 / 限定 / 兜底)、稀有度抽取、选项条件、结果与事件战斗。
## 红之章的事件：「燃烧喷泉」(示例)、「末班电车」。第二批(docs/EVENTS_BATCH2.md)：可重复的选项 / 纯负面 / 高收益的通用事件。

const BATCH2: Array[String] = ["gacha_machine", "dig_site", "entropy_well", "toll_gate", "blowout", "spoiled_supplies", "ash_storm",
	"lost_armory", "wandering_mechanic", "orb_rain", "old_altar", "old_friend"]


func _red_run(seed_value: int = 5) -> Run:
	var r := Run.create(Fixture.catalog(), seed_value, "ch1_red")
	return r


## 把卡车摆到一个事件节点上，进入事件。want = 指定抽到哪个事件(把池子里别的事件都记成"本章出过了")
func _enter_event(r: Run, want: String = "burning_fountain") -> String:
	var key := ""
	for k: String in (r.gmap["nodes"] as Dictionary).keys():
		if str(r.gnode(k).get("type", "")) == "event" and key == "":
			key = k
	if want != "":
		for id: String in r.catalog.events.keys():
			if id != want and not r.events_this_chapter.has(id):
				r.events_this_chapter.append(id)
	r.pos = key
	r.gnode(key)["state"] = "seen"
	r._enter_node()
	if want != "":
		r.events_this_chapter = [want]
	return key


func _fake_events() -> Dictionary:
	return {
		"common_a": {"id": "common_a", "rarity": 1, "pool": {"type": "common"}},
		"ch1_a": {"id": "ch1_a", "rarity": 1, "pool": {"type": "chapter", "chapter": 1}},
		"ch2_a": {"id": "ch2_a", "rarity": 1, "pool": {"type": "chapter", "chapter": 2}},
		"red_a": {"id": "red_a", "rarity": 1, "pool": {"type": "color", "color": "red"}},
		"blue_a": {"id": "blue_a", "rarity": 1, "pool": {"type": "color", "color": "blue"}},
		"only_red": {"id": "only_red", "rarity": 1, "pool": {"type": "exclusive", "chapter": "ch1_red"}},
		"only_blue": {"id": "only_blue", "rarity": 1, "pool": {"type": "exclusive", "chapter": "ch1_blue"}},
	}


func test_pools_follow_the_chapter_number_and_colors(t: TestCtx) -> void:
	var red := {"chapter_no": 1, "color": "red"}
	var purple := {"chapter_no": 2, "color": "purple"}
	var yellow := {"chapter_no": 2, "color": "yellow"}
	var black := {"chapter_no": 3, "color": "black"}
	var blue := {"chapter_no": 1, "color": "blue"}
	var ev: Dictionary = _fake_events()
	t.ok(Events.pool_fits(ev["common_a"], "ch1_red", red) and Events.pool_fits(ev["common_a"], "ch2_purple", purple), "common events fit anywhere")
	t.ok(Events.pool_fits(ev["ch1_a"], "ch1_red", red) and Events.pool_fits(ev["ch1_a"], "ch1_blue", blue), "chapter-1 events fit the red and the blue chapter 1")
	t.ok(not Events.pool_fits(ev["ch1_a"], "ch2_purple", purple), "…but not chapter 2")
	t.ok(Events.pool_fits(ev["ch2_a"], "ch2_purple", purple) and not Events.pool_fits(ev["ch2_a"], "ch1_red", red), "chapter-2 events only in chapter 2")
	for c: Dictionary in [red, purple, yellow, black]:
		t.ok(Events.pool_fits(ev["red_a"], "x", c), "red events fit the %s chapter" % str(c["color"]))
	t.ok(not Events.pool_fits(ev["red_a"], "ch1_blue", blue), "…but not the blue chapter")
	t.ok(Events.pool_fits(ev["blue_a"], "ch2_purple", purple) and not Events.pool_fits(ev["blue_a"], "ch2_yellow", yellow), "blue events: purple yes, yellow no")
	t.ok(Events.pool_fits(ev["only_red"], "ch1_red", red), "an exclusive event fits its own chapter")
	t.ok(not Events.pool_fits(ev["only_red"], "ch2_purple", purple) and not Events.pool_fits(ev["only_blue"], "ch1_red", red), "…and no other")
	t.ok(Events.removed_for_run(ev["common_a"]) and Events.removed_for_run(ev["ch1_a"]), "common / chapter events leave the pool for the run")
	t.ok(not Events.removed_for_run(ev["red_a"]) and not Events.removed_for_run(ev["only_red"]), "color / exclusive events only don't repeat within a chapter")


func test_picking_respects_pools_rarity_and_removal(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var saved: Dictionary = cat.events
	var fake: Dictionary = _fake_events()
	fake["rare_common"] = {"id": "rare_common", "rarity": 3, "pool": {"type": "common"}}
	fake["fallback_x"] = {"id": "fallback_x", "rarity": 1, "pool": {"type": "fallback"}}
	cat.events = fake
	var r := _red_run(11)
	var c: Array[String] = Events.candidates(cat, r)
	c.sort()
	t.eq(c, ["ch1_a", "common_a", "only_red", "rare_common", "red_a"], "the red chapter 1 can draw: common, chapter 1, red, red-only")
	# 稀有度：3 级的比 1 级的少见得多
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var n_rare := 0
	var n_common := 0
	for i in range(2000):
		var id: String = Events.pick(cat, r, rng)
		if id == "rare_common":
			n_rare += 1
		elif id == "common_a":
			n_common += 1
	t.ok(n_rare * 3 < n_common, "rarity 3 shows up far less than rarity 1 (%d vs %d)" % [n_rare, n_common])
	# 移出事件池
	r.events_gone = ["common_a", "ch1_a"]
	r.events_this_chapter = ["red_a"]
	c = Events.candidates(cat, r)
	c.sort()
	t.eq(c, ["only_red", "rare_common"], "seen events are out of the pool")
	r.events_this_chapter = ["red_a", "only_red", "rare_common"]
	t.eq(Events.pick(cat, r, rng), "fallback_x", "an empty pool falls back to the filler event")
	# 换章：颜色 / 限定事件可以再出现，通用 / 章节事件不行
	r.enter_chapter("ch1_red", false)
	c = Events.candidates(cat, r)
	t.ok(c.has("red_a") and c.has("only_red") and not c.has("common_a") and not c.has("ch1_a"), "a new chapter resets the per-chapter list only")
	cat.events = saved


func test_burning_fountain_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var ev: Dictionary = cat.events["burning_fountain"]
	t.eq(int(ev["rarity"]), 2, "rarity 2")
	t.eq(ev["pool"], {"type": "exclusive", "chapter": "ch1_red"}, "exclusive to the red chapter")
	t.eq((ev["options"] as Array).size(), 3, "three options")
	t.ok(ResourceLoader.exists("res://assets/world/burn_fountain.res"), "the fountain has a voxel model")
	t.eq(cat.validate_all().filter(func(e: String) -> bool: return e.begins_with("event")), [], "events validate")
	var r := _red_run()
	_enter_event(r)
	t.eq(r.phase, "event", "entering an event node opens the event")
	t.eq(str(r.event_state["id"]), "burning_fountain", "the burning fountain shows up in the red chapter")
	t.ok(r.events_this_chapter.has("burning_fountain") and not r.events_gone.has("burning_fountain"), "exclusive: no repeat this chapter, not removed for the run")


func test_collecting_flames_costs_truck_durability_for_phlogiston(t: TestCtx) -> void:
	var r := _red_run()
	_enter_event(r)
	var hp0: int = r.truck_hp
	var red0: int = int(r.materials["red"])
	t.ok(not bool(r.event_continue()["ok"]), "can't leave before choosing")
	var res: Dictionary = r.event_choose(0)
	t.ok(bool(res["ok"]), "collect the flames")
	t.eq(r.truck_hp, hp0 - 6, "-6 truck durability")
	t.eq(int(r.materials["red"]), red0 + 6, "+6 phlogiston")
	t.eq(str(r.event_state["outcome"]), "collect", "outcome text")
	t.ok(not bool(r.event_choose(2)["ok"]), "only one choice")
	r.event_continue()
	t.eq(r.phase, "map", "back on the map")
	t.eq(str(r.current_node()["state"]), "done", "the event node is done")
	# 卡车耐久不够就不能选
	var r2 := _red_run()
	_enter_event(r2)
	r2.truck_hp = 6
	t.ok(not bool(r2.event_option_check(0)["ok"]), "can't risk the truck at 6 durability")


func test_destroying_needs_a_strong_ranged_node(t: TestCtx) -> void:
	var r := _red_run()
	_enter_event(r)
	# 开局：速射节点 1 星拿着基础步枪，攻击力 104 < 120
	var chk: Dictionary = r.event_option_check(1)
	t.ok(not bool(chk["ok"]), "no ranged node with attack ≥ 120 yet")
	t.eq(str(chk["reqs"][0].get("who", "")), "node_archer", "…the best ranged node is the archer")
	t.eq(int(chk["reqs"][0].get("who_value", 0)), 104, "…with 104 attack")
	t.ok(not bool(r.event_choose(1)["ok"]), "the locked option can't be chosen")
	# 2 星的速射节点：135
	for u: Dictionary in r.roster.values():
		if str(u["def"]) == "node_archer":
			u["star"] = 2
	t.ok(bool(r.event_option_check(1)["ok"]), "a 2★ archer (135 attack) can destroy it")
	# 近战武器不算
	var r2 := _red_run()
	_enter_event(r2)
	for u2: Dictionary in r2.roster.values():
		if str(u2["def"]) == "node_darkknight":
			u2["star"] = 3
		if str(u2["def"]) == "node_archer":
			r2.sell(str(u2["id"]))
	t.ok(not bool(r2.event_option_check(1)["ok"]), "a strong melee node doesn't count")


func test_destroying_is_gold_or_a_hard_battle(t: TestCtx) -> void:
	var gold_n := 0
	var fight_n := 0
	for s in range(40):
		var r := _red_run(100 + s)
		_enter_event(r)
		for u: Dictionary in r.roster.values():
			if str(u["def"]) == "node_archer":
				u["star"] = 2
		var g0: int = r.gold
		r.event_choose(1)
		if str(r.event_state["outcome"]) == "destroy_gold":
			gold_n += 1
			t.eq(r.gold, g0 + 10, "+10 gold")
			r.event_continue()
			t.eq(r.phase, "map", "and leave")
		else:
			fight_n += 1
			t.eq(r.phase, "event", "the battle waits until you press Fight")
			r.event_continue()
			t.eq(r.phase, "prepare", "…then it's a battle")
			var enc: Dictionary = r.wave_def()
			t.ok(int(enc["intensity"]) >= 28, "a hard battle: the node +12, at least 28 (%d)" % int(enc["intensity"]))
			var orbs: Array = []
			for e: Array in enc["units"]:
				if (e[4] as Dictionary).has("orb"):
					orbs.append(str(e[4]["orb"]))
			orbs.sort()
			t.eq(orbs, ["blue", "gold"], "extra reward: a gold and a blue orb")
			var fixed := false
			for o: Dictionary in r.current_layout().get("obstacles", []):
				if str(o.get("style", "")) == "burn_fountain":
					fixed = true
					t.eq(str(o.get("terrain", "")), "burning", "the fountain burns")
			t.ok(fixed, "the battle is fought by the burning fountain")
			t.eq(str(r.current_layout().get("arena", "")), "fountain_park", "…in the park itself (its own arena)")
			t.eq(r.battle_kind(), "event", "battle kind: event")
	t.ok(gold_n >= 10 and fight_n >= 10, "about half and half (%d gold / %d fights)" % [gold_n, fight_n])


func test_studying_gives_xp(t: TestCtx) -> void:
	var r := _red_run()
	_enter_event(r)
	var before: int = r.xp + _xp_before_level(r)
	r.event_choose(2)
	t.eq(r.xp + _xp_before_level(r), before + 6, "+6 XP")
	r.event_continue()
	t.eq(r.phase, "map", "and leave")


## 当前等级之前累计的经验(升级后 xp 会清零，按等级把阈值加回来)
func _xp_before_level(r: Run) -> int:
	var total := 0
	var save_level: int = r.level
	for lv in range(3, save_level):
		r.level = lv
		total += r.next_level_xp()
	r.level = save_level
	return total


func test_red_events_do_not_repeat_and_then_fall_back(t: TestCtx) -> void:
	var r := _red_run()
	r.events_gone.append_array(BATCH2)
	var keys: Array = []
	for k: String in (r.gmap["nodes"] as Dictionary).keys():
		if str(r.gnode(k).get("type", "")) == "event":
			keys.append(k)
	t.ok(keys.size() >= 2, "the red map has at least two events")
	var seen: Array = []
	for i in range(2):
		r.pos = keys[i]
		r._enter_node()
		seen.append(str(r.event_state["id"]))
		r.event_choose(2)
		r.event_continue()
		t.eq(r.phase, "map", "event %d done" % i)
	seen.sort()
	t.eq(seen, ["burning_fountain", "last_tram"], "the two red events each show up once")
	t.eq(Events.pick(r.catalog, r, r.rng), "quiet_street", "both already happened this chapter: a quiet street next")
	# 稀有度：末班电车(1)比燃烧喷泉(2)常见，先遇到它的概率约 2/3
	var tram_first := 0
	for s in range(60):
		var r2 := _red_run(300 + s)
		r2.events_gone.append_array(BATCH2)
		if Events.pick(r2.catalog, r2, r2.rng) == "last_tram":
			tram_first += 1
	t.ok(tram_first > 30 and tram_first < 52, "the common tram comes first about two times in three (%d/60)" % tram_first)


# ------------------------------------------------------------------ 末班电车
func test_last_tram_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var ev: Dictionary = cat.events["last_tram"]
	t.eq(int(ev["rarity"]), 1, "rarity 1")
	t.eq(ev["pool"], {"type": "exclusive", "chapter": "ch1_red"}, "exclusive to the red chapter")
	t.eq(str(ev["scene"]), "tram_stop", "its own scene")
	var ids: Array = []
	for o: Dictionary in ev["options"]:
		ids.append(str(o["id"]))
	t.eq(ids, ["follow", "board", "watch"], "three options")
	for nm: String in ["burn_tram", "evt_track", "evt_tram_stop", "evt_crossing", "evt_crossing_arm", "evt_wire_pole"]:
		t.ok(ResourceLoader.exists("res://assets/world/%s.res" % nm), "voxel model %s" % nm)
	t.eq(cat.validate_all().filter(func(e: String) -> bool: return e.begins_with("event")), [], "events validate")
	var r := _red_run()
	_enter_event(r, "last_tram")
	t.eq(str(r.event_state["id"]), "last_tram", "the last tram shows up in the red chapter")
	t.ok(r.events_this_chapter.has("last_tram") and not r.events_gone.has("last_tram"), "exclusive: no repeat this chapter, not removed for the run")


func test_following_the_tram_trades_durability_for_action_points(t: TestCtx) -> void:
	var r := _red_run()
	_enter_event(r, "last_tram")
	var hp0: int = r.truck_hp
	var ap0: int = r.ap
	t.ok(bool(r.event_choose(0)["ok"]), "follow the tram")
	t.eq(r.truck_hp, hp0 - 8, "-8 truck durability")
	t.eq(r.ap, ap0 + 2, "+2 action points")
	t.eq(str(r.event_state["outcome"]), "follow", "outcome text")
	r.event_continue()
	t.eq(r.phase, "map", "back on the map")
	t.eq(r.ap, ap0 + 2, "the action points stay")
	# 卡车耐久不够就不能跟
	var r2 := _red_run()
	_enter_event(r2, "last_tram")
	r2.truck_hp = 8
	t.ok(not bool(r2.event_option_check(0)["ok"]), "no following at 8 durability")
	t.ok(bool(r2.event_option_check(1)["ok"]) and bool(r2.event_option_check(2)["ok"]), "the other two are always open")
	# 行动力用完的时候跟上去：不会被追猎
	var r3 := _red_run()
	_enter_event(r3, "last_tram")
	r3.ap = 0
	r3.event_choose(0)
	r3.event_continue()
	t.ok(r3.phase == "map" and not r3.hunt_active and r3.ap == 2, "out of AP: following the tram saves you from the hunt")


func test_boarding_the_tram_is_a_chosen_battle_at_the_stop(t: TestCtx) -> void:
	for s in range(20):
		var r := _red_run(200 + s)
		var key: String = _enter_event(r, "last_tram")
		var base: int = r._depth_intensity(int(r.gnode(key).get("depth", 1)))
		var res: Dictionary = r.event_choose(1)
		t.ok(bool(res["ok"]) and bool(res["battle"]), "boarding always means a fight")
		t.eq(str(r.event_state["outcome"]), "board_fight", "no luck involved")
		t.eq(r.phase, "event", "the battle waits until you press Fight")
		r.event_continue()
		t.eq(r.phase, "prepare", "…then it is a battle")
		var enc: Dictionary = r.wave_def()
		t.eq(int(enc["intensity"]), maxi(20, base + 6), "intensity = the node +6, at least 20")
		var orbs: Array = []
		for e: Array in enc["units"]:
			if (e[4] as Dictionary).has("orb"):
				orbs.append(str(e[4]["orb"]))
			t.eq(str(e[2]), "n", "the passengers line up on the platform (north)")
		t.eq(orbs, ["blue", "blue"], "extra reward: two blue orbs")
		t.eq(r.battle_kind(), "event", "battle kind: event")
		var layout: Dictionary = r.current_layout()
		t.eq(str(layout.get("arena", "")), "tram_stop", "fought at the tram stop itself (its own arena)")
		t.eq(str((layout["hazards"] as Array)[0]["type"]), "sweep", "…where the tram keeps running on schedule")
		if s == 0:
			# 打一场：电车一班一班地冲过战场，不会卡住战斗
			var b := Battle.new(r.catalog, 7)
			b.setup(r.build_battle_setup())
			b.run_to_end()
			t.ok(b.state == "ended", "the battle at the stop plays out (%.1f s)" % b.time)
			r.begin_battle()
			r.finish_battle(b)
			if r.phase == "loot":
				for k in range(r.pending_orbs.size()):
					r.open_orb(k)
				r.finish_loot()
			t.eq(str(r.gnode(key)["state"]), "done", "win or lose, the event node is done")


func test_watching_the_tram_scouts_the_map(t: TestCtx) -> void:
	var r := _red_run()
	var key: String = _enter_event(r, "last_tram")
	var c0: Vector2i = ChapterMap.cell(key)
	var near_hidden := 0
	var far_hidden := 0
	for k: String in (r.gmap["nodes"] as Dictionary).keys():
		var c: Vector2i = ChapterMap.cell(k)
		if str(r.gnode(k)["state"]) == "hidden":
			if absi(c.x - c0.x) + absi(c.y - c0.y) <= 3:
				near_hidden += 1
			else:
				far_hidden += 1
	t.ok(near_hidden > 0, "some nodes within 3 cells are still unscouted (%d)" % near_hidden)
	var before: int = r.xp + _xp_before_level(r)
	t.ok(bool(r.event_choose(2)["ok"]), "watch it leave and read the route map")
	var left := 0
	var far_left := 0
	for k2: String in (r.gmap["nodes"] as Dictionary).keys():
		var c2: Vector2i = ChapterMap.cell(k2)
		if str(r.gnode(k2)["state"]) == "hidden":
			if absi(c2.x - c0.x) + absi(c2.y - c0.y) <= 3:
				left += 1
			else:
				far_left += 1
	t.eq(left, 0, "every node within 3 cells is scouted")
	t.eq(far_left, far_hidden, "…and nothing farther away")
	t.eq(r.xp + _xp_before_level(r), before + 3, "+3 XP")
	r.event_continue()
	t.eq(r.phase, "map", "and leave")


# ------------------------------------------------------------------ 第二批：可重复的选项 / 纯负面 / 高收益(docs/EVENTS_BATCH2.md)
func test_batch2_events_validate_and_fill_the_common_pool(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	t.eq(cat.validate_all().filter(func(e: String) -> bool: return e.begins_with("event")), [], "events validate")
	for id: String in BATCH2:
		t.ok(cat.events.has(id), "event %s exists" % id)
	var r := _red_run()
	var c: Array[String] = Events.candidates(cat, r)
	for id2: String in BATCH2:
		t.ok(c.has(id2), "%s can show up in the red chapter" % id2)
	var r2 := Run.create(cat, 5, "ch2_purple")
	var c2: Array[String] = Events.candidates(cat, r2)
	t.ok(c2.has("gacha_machine") and c2.has("old_altar"), "common events fit the purple chapter")
	t.ok(c2.has("ash_storm") and not c2.has("burning_fountain"), "…the red ash storm too (purple holds red), the red exclusives don't")
	for ev_id: String in ["toll_gate", "blowout", "spoiled_supplies", "ash_storm"]:
		t.ok(bool(cat.events[ev_id].get("negative", false)), "%s is marked purely negative" % ev_id)
	for sc: String in BATCH2:
		t.eq(str(cat.events[sc]["scene"]), "roadside", "%s uses the roadside kit" % sc)
		var n_models := 0
		for pr: Dictionary in cat.events[sc].get("props", []):
			if str(pr.get("kind", "model")) == "model":
				n_models += 1
				t.ok(ResourceLoader.exists("res://assets/world/%s.res" % str(pr["model"])), "%s: prop %s has a model" % [sc, str(pr["model"])])
		t.ok(n_models >= 1, "%s has a hero prop" % sc)
	t.eq(int(cat.events["lost_armory"]["rarity"]), 3, "the armory is rare")
	t.eq(int(cat.events["gacha_machine"]["rarity"]), 2, "the gacha machine is uncommon")


func test_repeatable_options_return_to_the_scene(t: TestCtx) -> void:
	var r := _red_run(7)
	_enter_event(r, "gacha_machine")
	t.eq(str(r.event_state["id"]), "gacha_machine", "the gacha machine")
	r.gold = 40
	var chk: Dictionary = r.event_option_check(0)
	t.ok(bool(chk["ok"]) and int(chk["reqs"][0]["value"]) == 2, "the first coin costs 2 gold")
	t.ok(not bool(r.event_option_check(1)["ok"]), "can't shake it before two coins")
	var expect: int = r.gold - 2
	t.ok(bool(r.event_choose(0)["ok"]), "drop a coin")
	for g: Dictionary in r.event_state["gains"]:
		if str(g["type"]) == "orb":
			expect += int((g["loot"] as Dictionary).get("gold", 0))
	t.eq(r.gold, expect, "paid 2 gold (plus whatever the capsule held)")
	t.ok(bool(r.event_state["repeat"]), "a repeatable option: the outcome page leads back to the scene")
	t.ok(bool(r.event_continue()["ok"]) and r.phase == "event" and int(r.event_state["option"]) == -1, "back to the options, still at the event")
	t.eq(int((r.event_state["picks"] as Dictionary)["pull"]), 1, "one pick counted")
	t.eq(int(r.event_option_check(0)["reqs"][0]["value"]), 3, "the second coin costs 3")
	for i in range(4):
		var before: int = r.gold
		var cost: int = int(r.event_option_check(0)["reqs"][0]["value"])
		t.ok(bool(r.event_choose(0)["ok"]), "coin %d" % (i + 2))
		var got := 0
		for g2: Dictionary in r.event_state["gains"]:
			if str(g2["type"]) == "orb":
				got += int((g2["loot"] as Dictionary).get("gold", 0))
		t.eq(r.gold, before - cost + got, "coin %d cost %d" % [i + 2, cost])
		r.event_continue()
	t.eq(int((r.event_state["picks"] as Dictionary)["pull"]), 5, "five coins")
	var chk2: Dictionary = r.event_option_check(0)
	t.ok(not bool(chk2["ok"]) and str(chk2["reqs"][0]["type"]) == "repeat_done", "the slot takes no more coins")
	t.ok(bool(r.event_option_check(1)["ok"]), "…but it can be shaken now")
	t.ok(bool(r.event_choose(2)["ok"]) and not bool(r.event_state["repeat"]), "walk away: a plain option")
	r.event_continue()
	t.eq(r.phase, "map", "left the event")
	t.eq(str(r.current_node()["state"]), "done", "the event node is done")


func test_shaking_the_machine_closes_the_slot(t: TestCtx) -> void:
	var r := _red_run(9)
	_enter_event(r, "gacha_machine")
	r.gold = 20
	for i in range(2):
		r.event_choose(0)
		r.event_continue()
	t.ok(bool(r.event_choose(1)["ok"]), "shake it after two coins")
	t.ok((r.event_state["closed"] as Array).has("pull"), "the coin slot is closed")
	t.ok(str(r.event_state["outcome"]).begins_with("shake"), "a shake outcome (%s)" % str(r.event_state["outcome"]))
	t.ok(not bool(r.event_state["repeat"]), "shaking ends the visit")
	r.event_continue()
	t.eq(r.phase, "map", "left")
	# 关掉的选项：再进同一个事件(新的一次)不受影响
	var r2 := _red_run(9)
	_enter_event(r2, "gacha_machine")
	r2.event_state["closed"] = ["pull"]
	var chk: Dictionary = r2.event_option_check(0)
	t.ok(not bool(chk["ok"]) and str(chk["reqs"][0]["type"]) == "closed", "a closed option reports why")


func test_digging_deeper_follows_the_layer_table(t: TestCtx) -> void:
	var r := _red_run(3)
	_enter_event(r, "dig_site")
	var hp0: int = r.truck_hp
	var g0: int = int(r.materials["green"])
	var b0: int = int(r.materials["blue"])
	t.ok(bool(r.event_choose(0)["ok"]) and str(r.event_state["outcome"]) == "dig1", "layer 1")
	r.event_continue()
	t.ok(bool(r.event_choose(0)["ok"]) and str(r.event_state["outcome"]) == "dig2", "layer 2")
	r.event_continue()
	t.eq(r.truck_hp, hp0 - 6, "-3 durability per layer")
	t.eq(int(r.materials["green"]), g0 + 3, "layer 1: +3 organic matter")
	t.eq(int(r.materials["blue"]), b0 + 4, "layer 2: +4 negentropy")
	t.ok(str(r.event_option_check(0)["reqs"][0]["type"]) == "truck_hp_above" or bool(r.event_option_check(0)["ok"]), "digging needs durability above 15")
	r.truck_hp = 15
	t.ok(not bool(r.event_option_check(0)["ok"]), "too battered to dig on at 15")
	t.ok(bool(r.event_choose(1)["ok"]), "pack up")
	r.event_continue()
	t.eq(r.phase, "map", "left")
	# 第 4 层塌方：选完不再回到现场
	var r2 := _red_run(3)
	_enter_event(r2, "dig_site")
	r2.event_state["picks"] = {"dig": 3}
	var collapsed := false
	for s in range(40):
		var r3 := _red_run(100 + s)
		_enter_event(r3, "dig_site")
		r3.event_state["picks"] = {"dig": 3}
		r3.event_choose(0)
		if str(r3.event_state["outcome"]) == "dig4_collapse":
			collapsed = not bool(r3.event_state["repeat"])
			break
	t.ok(collapsed, "a collapse on layer 4 ends the digging")


func test_pure_negative_events_always_leave_a_way_out(t: TestCtx) -> void:
	for ev_id: String in ["toll_gate", "blowout", "spoiled_supplies", "ash_storm"]:
		var r := _red_run(21)
		_enter_event(r, ev_id)
		r.gold = 0
		r.inventory.clear()
		r.parts.clear()
		r.truck_hp = 10
		var opts: Array = r.event_def().get("options", [])
		var any := false
		for i in range(opts.size()):
			if bool(r.event_option_check(i)["ok"]):
				any = true
		t.ok(any, "%s: a broke, battered convoy still has an option" % ev_id)
		for o: Dictionary in opts:
			for oc: Dictionary in Events.all_outcomes(o):
				for ef: Dictionary in oc.get("effects", []):
					t.ok(not Events.is_gain(ef), "%s / %s: no gain (%s)" % [ev_id, str(o["id"]), str(ef["type"])])
	# 路障：有钱时交钱
	var r2 := _red_run(21)
	_enter_event(r2, "toll_gate")
	r2.gold = 9
	t.ok(bool(r2.event_choose(0)["ok"]) and r2.gold == 3, "paid 6 gold")
	# 爆胎：换备胎 -2 行动力
	var r3 := _red_run(22)
	_enter_event(r3, "blowout")
	var ap0: int = r3.ap
	r3.event_choose(0)
	t.eq(r3.ap, maxi(0, ap0 - 2), "the spare costs 2 action points")
	# 余烬风暴：关掉仪器 = 下一场敌人 +6
	var r4 := _red_run(23)
	_enter_event(r4, "ash_storm")
	r4.event_choose(2)
	t.eq(int(r4.flag_value("next_battle_intensity")), 6, "cursed: next battle +6")


func test_new_effects_grant_and_clamp(t: TestCtx) -> void:
	var r := _red_run(4)
	r.event_state = {"gains": []}
	r.gold = 3
	r._apply_event_effect({"type": "gold", "amount": -10})
	t.eq(r.gold, 0, "gold never goes below 0")
	r.materials = {"red": 5, "green": 2, "blue": 0}
	r._apply_event_effect({"type": "materials", "half": "most"})
	t.eq(int(r.materials["red"]), 2, "half of the most plentiful material (rounded up) is lost")
	r._apply_event_effect({"type": "materials", "red": -1, "green": -1, "blue": -1})
	t.eq([int(r.materials["red"]), int(r.materials["green"]), int(r.materials["blue"])], [1, 1, 0], "negative materials clamp at 0")
	r.truck_hp = 60
	r._apply_event_effect({"type": "truck_max", "amount": -30})
	t.ok(r.truck_max == 70 and r.truck_hp == 60, "cap -30")
	r._apply_event_effect({"type": "truck_max", "amount": -40})
	t.ok(r.truck_max == 40 and r.truck_hp == 40, "the cap never drops below 40 and pulls the durability down with it")
	r._apply_event_effect({"type": "truck_max", "amount": 10})
	r._apply_event_effect({"type": "truck_heal", "pct": 1.0})
	t.ok(r.truck_max == 50 and r.truck_hp == 50, "cap +10 and a full repair")
	var n0: int = r.roster.size()
	r._apply_event_effect({"type": "unit", "cost": 3})
	t.eq(r.roster.size(), n0 + 1, "a unit joined")
	var last: Dictionary = r.event_state["gains"].back()
	t.ok(str(last["type"]) == "unit" and r.catalog.get_unit(str(last["id"])).cost == 3, "…a 3-cost one (%s)" % str(last["id"]))
	var w0: int = r.inventory.size()
	r._apply_event_effect({"type": "weapon", "max_cost": 4})
	t.eq(r.inventory.size(), w0 + 1, "a weapon arrived")
	t.ok(r.catalog.get_equipment(r.inventory.back()).cost <= 4, "…costing at most 4")
	r._apply_event_effect({"type": "orb", "tier": "gold"})
	var og: Dictionary = r.event_state["gains"].back()
	t.ok(str(og["type"]) == "orb" and str(og["tier"]) == "gold" and og.has("loot"), "a gold orb was opened on the spot")
	# 永久加成：最强的节点
	r._apply_event_effect({"type": "perm", "who": "strongest", "stats": {"damage_dealt_pct": 0.1}})
	var pg: Dictionary = r.event_state["gains"].back()
	var best_cost := 0
	for u: Dictionary in r.roster.values():
		best_cost = maxi(best_cost, r.cost_of_unit(u))
	t.ok(str(pg["type"]) == "perm" and r.catalog.get_unit(str(pg["id"])).cost == best_cost, "the strongest node got the blessing (%s)" % str(pg["id"]))
	var blessed := 0
	for u2: Dictionary in r.roster.values():
		if absf(float((u2["perm"] as Dictionary).get("damage_dealt_pct", 0.0)) - 0.1) < 0.001:
			blessed += 1
	t.eq(blessed, 1, "exactly one node carries +10% damage")
	# 把拿到加成的那个棋子换到场上(战斗只带场上的)
	var blessed_id := ""
	for rid: String in r.roster.keys():
		if absf(float((r.roster[rid]["perm"] as Dictionary).get("damage_dealt_pct", 0.0)) - 0.1) < 0.001:
			blessed_id = rid
	if r.roster[blessed_id]["cell"] == null:
		var board: Array[Dictionary] = r.board_units()
		var swap: Dictionary = board[0]
		r.roster[blessed_id]["cell"] = swap["cell"]
		swap["cell"] = null
		swap["bench"] = r.free_bench_slot()
	var b := Battle.new(r.catalog, 1)
	b.setup(r.build_battle_setup())
	var carried := false
	for bu: BUnit in b.units:
		if bu.team == GC.TEAM_PLAYER and absf(float(bu.perm_flat.get("damage_dealt_pct", 0.0)) - 0.1) < 0.001:
			carried = true
	t.ok(carried, "the permanent bonus reaches the battle")
	# 升星
	r._apply_event_effect({"type": "star_up", "max_cost": 3})
	var two := 0
	for u3: Dictionary in r.roster.values():
		if int(u3["star"]) >= 2:
			two += 1
	t.ok(two >= 1 and str((r.event_state["gains"].back() as Dictionary)["type"]) == "star_up", "a 1★ node rose to 2★")
	# 零件
	r.parts = []
	r._apply_event_effect({"type": "part", "id": "random"})
	t.eq(r.parts.size(), 1, "a part")
	r.parts = ["jerrycan", "jerrycan", "jerrycan", "jerrycan", "jerrycan"]
	r.gold = 0
	r._apply_event_effect({"type": "part", "id": "random", "fallback": {"type": "gold", "amount": 3}})
	t.ok(r.parts.size() == 5 and r.gold == 3, "parts box full: the fallback pays 3 gold")
	# 失去武器 / 零件
	r.inventory = [r.catalog.equipment_ids()[0]]
	r._apply_event_effect({"type": "lose_weapon", "fallback": {"type": "gold", "amount": -1}})
	t.ok(r.inventory.is_empty() and r.gold == 3, "lost the only weapon")
	r._apply_event_effect({"type": "lose_weapon", "fallback": {"type": "gold", "amount": -1}})
	t.eq(r.gold, 2, "no weapon to lose: the fallback costs 1 gold")
	r._apply_event_effect({"type": "lose_part"})
	t.eq(r.parts.size(), 4, "lost a part")
	# 失去棋子：只剩一个时用 fallback
	var ids: Array = r.roster.keys()
	ids.sort()
	for i in range(1, ids.size()):
		r.roster.erase(ids[i])
	var hp: int = r.truck_hp
	r._apply_event_effect({"type": "lose_unit", "who": "random", "fallback": {"type": "truck_damage", "amount": 10}})
	t.ok(r.roster.size() == 1 and r.truck_hp == hp - 10, "the last node stays; the truck pays instead")
	r.add_unit("node_archer", 1, null, r.free_bench_slot())
	r.add_unit("node_student", 1, null, r.free_bench_slot())
	r._apply_event_effect({"type": "lose_unit", "who": "cheapest"})
	t.eq(r.roster.size(), 2, "lost a node")


func test_flags_curse_bless_and_expire(t: TestCtx) -> void:
	var r := _red_run(6)
	var base: int = int(r._make_encounter("fight", 20)["intensity"])
	r.set_flag("next_battle_intensity", 6, "next_battle")
	t.eq(int(r._make_encounter("fight", 20)["intensity"]), base + 6, "the curse raises the next battle by 6")
	r._expire_flags("next_battle")
	t.ok(r.flags.is_empty() and int(r._make_encounter("fight", 20)["intensity"]) == base, "…and is gone after a battle")
	# 制造按高一级抽：4 级 + 1 = 5 级的概率表(有 4 费)
	r.level = 4
	var four := 0
	for i in range(200):
		r.roll_shop(false)
		for o: Dictionary in r.shop:
			if r.catalog.get_unit(str(o["def"])).cost == 4:
				four += 1
	t.eq(four, 0, "level 4 never rolls 4-costs")
	r.set_flag("shop_odds_shift", 1, "chapter")
	for i2 in range(400):
		r.roll_shop(false)
		for o2: Dictionary in r.shop:
			if r.catalog.get_unit(str(o2["def"])).cost == 4:
				four += 1
	t.ok(four > 0, "blessed: level 4 rolls with level 5 odds (%d 4-costs in 2000 slots)" % four)
	# 节点收入 +2
	r.gold = 0
	r.set_flag("income_bonus", 2, "chapter")
	r._pay_arrival("fight")
	t.eq(r.gold, 3 + 2, "a fight node pays 3 + 2")
	r.gold = 0
	r._pay_arrival("boss")
	t.eq(r.gold, 0, "a node that pays nothing still pays nothing")
	t.eq(r.flags.size(), 2, "two chapter-long blessings")
	r.enter_chapter("ch1_red", false)
	t.ok(r.flags.is_empty(), "a new chapter clears them")


func test_high_reward_events_pay_out(t: TestCtx) -> void:
	# 军火库：等级 5 才能破解
	var r := _red_run(31)
	_enter_event(r, "lost_armory")
	t.ok(not bool(r.event_option_check(0)["ok"]), "level 3 can't crack the lock")
	r.level = 5
	var g0: int = r.gold
	var w0: int = r.inventory.size()
	t.ok(bool(r.event_choose(0)["ok"]), "level 5 cracks it")
	t.ok(r.inventory.size() == w0 + 1 and r.gold == g0 + 8, "a weapon and 8 gold")
	# 技师：10 金大修
	var r2 := _red_run(32)
	_enter_event(r2, "wandering_mechanic")
	r2.gold = 12
	r2.truck_hp = 40
	t.ok(bool(r2.event_choose(0)["ok"]), "hire her")
	t.ok(r2.gold == 2 and r2.truck_max == 110 and r2.truck_hp == 110, "cap 110, fully repaired")
	# 晶球雨：三个蓝球
	var r3 := _red_run(33)
	_enter_event(r3, "orb_rain")
	t.ok(bool(r3.event_choose(0)["ok"]), "grab the nearest")
	var orbs := 0
	for g: Dictionary in r3.event_state["gains"]:
		if str(g["type"]) == "orb" and str(g["tier"]) == "blue":
			orbs += 1
	t.eq(orbs, 3, "three blue orbs opened")
	# 祭坛：献材料 = 本章祝福
	var r4 := _red_run(34)
	_enter_event(r4, "old_altar")
	r4.materials = {"red": 3, "green": 3, "blue": 4}
	t.ok(bool(r4.event_choose(2)["ok"]), "offer materials")
	t.ok(int(r4.materials["red"]) == 0 and int(r4.materials["blue"]) == 1 and int(r4.flag_value("shop_odds_shift")) == 1, "-3 each, blessed")
	# 旧友：人情
	var r5 := _red_run(35)
	_enter_event(r5, "old_friend")
	t.ok(bool(r5.event_choose(1)["ok"]) and int(r5.flag_value("income_bonus")) == 2, "the favor")
