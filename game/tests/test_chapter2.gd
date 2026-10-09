extends RefCounted
## 第二章-A·紫之章：空岛方格网(首领在正中央、剑痕把岛切成两半只在桥上相通、起点在岛边缘)、寒气地形(寒雾地块)、
## 紫之章的战斗地图(坚冰 + 寒雾)、从红之章进入紫之章。怪物暂时是红之章的占位。


func _cat() -> Catalog:
	return Fixture.catalog()


func _win(r: Run, seed_value: int = 1) -> void:
	var b := Battle.new(_cat(), seed_value)
	b.setup(r.build_battle_setup())
	b.winner = GC.TEAM_PLAYER
	r.begin_battle()
	r.finish_battle(b)
	r.finish_loot()


func test_chapter_data(t: TestCtx) -> void:
	var cat: Catalog = _cat()
	t.ok(cat.chapters.has("ch2_purple"), "chapter 2-A exists")
	var ch: Dictionary = cat.chapters["ch2_purple"]
	t.eq(int(ch["chapter_no"]), 2, "chapter number 2")
	t.eq(str(ch["color"]), "purple", "purple")
	t.eq(str(ch["theme"]), "purple", "purple battle theme")
	t.eq(str(ch["overworld"]), "island", "the sky-island map")
	t.eq(str(ch["grid"]["mask"]), "island", "island grid")
	t.ok(ch.has("monsters") and not (ch["monsters"] as Dictionary).is_empty(), "placeholder monsters are listed")
	var nx: Variant = cat.chapters["ch1_red"]["next"]
	var ids: Array = []
	for b: Dictionary in (nx as Dictionary).get("branches", []):
		ids.append(str(b["id"]))
	t.ok(ids.has("ch2_purple"), "the red chapter leads to chapter 2 (branches: %s)" % str(ids))
	for key: String in ["name", "short", "desc"]:
		t.ok(Loc.has_key("chapter.ch2_purple.%s" % key), "loc key chapter.ch2_purple.%s" % key)
	t.eq(cat.validate_all().filter(func(e: String) -> bool: return e.contains("ch2") or e.begins_with("terrain")), [], "content validates")


static func _scar_s(c: Vector2i, dir: int, w: int) -> int:
	return (c.x - c.y) if dir == 0 else (c.x + c.y - (w - 1))


func test_island_map_shape(t: TestCtx) -> void:
	var cfg: Dictionary = _cat().chapters["ch2_purple"]["grid"]
	var w: int = int(cfg["w"])
	var h: int = int(cfg["h"])
	var center := Vector2i(w / 2, h / 2)
	for sd in [1, 2, 3, 4, 5, 6, 7, 8]:
		var m: Dictionary = ChapterMap.generate(cfg, sd)
		t.eq(JSON.stringify(m), JSON.stringify(ChapterMap.generate(cfg, sd)), "deterministic (seed %d)" % sd)
		t.ok(bool(m.get("island", false)) and m.has("scar"), "island with a scar (seed %d)" % sd)
		var nodes: Dictionary = m["nodes"]
		var boss: Vector2i = ChapterMap.cell(str(m["boss"]))
		t.ok((boss - center).length() <= 1.5, "the boss (iceberg) sits near the island's centre (%s)" % str(boss))
		var start: Vector2i = ChapterMap.cell(str(m["start"]))
		t.ok((start - center).length() >= 3.0, "the start is out at the island's edge (%s)" % str(start))
		var dir: int = int(m["scar"]["dir"])
		t.ok(ChapterMap.scar_side(start, dir, w) != ChapterMap.scar_side(boss, dir, w), "start and boss are on opposite sides of the scar")
		# 冰山：首领格四周一圈；上山的路只有一条，从背离剑痕的那个角上去，一格比一格高，山顶是首领
		t.ok(m.has("mountain"), "an iceberg")
		var mt: Dictionary = m["mountain"]
		var path: Array = mt["path"]
		t.eq(path.size(), 4, "four terraces on the way up")
		t.eq(str(mt["center"]), str(m["boss"]), "the summit is the boss")
		var mset := {str(m["boss"]): true}
		for i in range(path.size()):
			mset[str(path[i])] = true
			t.eq(int(nodes[str(path[i])].get("h", 0)), i + 1, "terrace %d is one step higher" % (i + 1))
			t.ok((ChapterMap.cell(str(path[i])) - boss).length() < 1.5, "terraces hug the summit")
		t.eq(int(nodes[str(m["boss"])].get("h", 0)), 5, "the summit is the highest")
		var ascents := 0
		for e0: Array in m["edges"]:
			var ina: bool = mset.has(str(e0[0]))
			var inb: bool = mset.has(str(e0[1]))
			if ina != inb:
				ascents += 1
				var outside: String = str(e0[1]) if ina else str(e0[0])
				var inside: String = str(e0[0]) if ina else str(e0[1])
				t.eq(outside, str(mt["entry"]), "the only way up starts at the entry")
				t.eq(inside, str(path[0]), "…and climbs onto the first terrace")
			if ina and inb:
				var ha: int = int(nodes[str(e0[0])].get("h", 0))
				var hb: int = int(nodes[str(e0[1])].get("h", 0))
				t.eq(absi(ha - hb), 1, "mountain roads join neighbouring terraces")
		t.eq(ascents, 1, "exactly one road leads up the iceberg")
		var s_entry: int = _scar_s(ChapterMap.cell(str(mt["entry"])), dir, w)
		var s_boss: int = _scar_s(boss, dir, w)
		t.ok(absi(s_entry) >= absi(s_boss), "the way up faces away from the scar (entry s=%d, summit s=%d)" % [s_entry, s_boss])
		# 跨剑痕的边只有桥
		var bridges: Array = m["scar"]["bridges"]
		var crossing := 0
		for e: Array in m["edges"]:
			var a: Vector2i = ChapterMap.cell(e[0])
			var b: Vector2i = ChapterMap.cell(e[1])
			t.eq(absi(a.x - b.x) + absi(a.y - b.y), 1, "edges join 4-neighbours")
			if ChapterMap.scar_side(a, dir, w) != ChapterMap.scar_side(b, dir, w):
				crossing += 1
				var listed := false
				for br: Array in bridges:
					if (br[0] == e[0] and br[1] == e[1]) or (br[0] == e[1] and br[1] == e[0]):
						listed = true
				t.ok(listed, "a crossing edge is one of the bridges")
		t.eq(crossing, bridges.size(), "exactly the fixed crossings exist (%d)" % crossing)
		t.ok(crossing >= 1 and crossing <= int(cfg["scar"]["bridges"]), "1..%d bridges" % int(cfg["scar"]["bridges"]))
		# 连通、路长、节点数
		var adj: Dictionary = ChapterMap.neighbors(m)
		var seen := {m["start"]: true}
		var q: Array = [m["start"]]
		while not q.is_empty():
			var c: String = q.pop_back()
			for n: String in adj[c]:
				if not seen.has(n):
					seen[n] = true
					q.append(n)
		t.eq(seen.size(), nodes.size(), "connected")
		var d: int = int(m["path_len"])
		t.ok(d >= int(cfg["min_path"]) and d <= int(cfg["max_path"]), "start → boss shortest path in range (%d)" % d)
		t.ok(nodes.size() >= int(cfg["nodes"]) - 5 and nodes.size() <= w * h, "node count %d" % nodes.size())
		var types := {}
		for k: String in nodes.keys():
			var c2: Vector2i = ChapterMap.cell(k)
			var u: float = (float(c2.x) - float(w - 1) * 0.5) / (float(w - 1) * 0.5 + 0.35)
			var v: float = (float(c2.y) - float(h - 1) * 0.5) / (float(h - 1) * 0.5 + 0.35)
			t.ok(u * u + v * v <= 1.3, "nodes lie inside the island disc (%s)" % k)
			types[str(nodes[k]["type"])] = int(types.get(str(nodes[k]["type"]), 0)) + 1
		t.eq(int(types.get("boss", 0)), 1, "one boss")
		t.ok(int(types.get("elite", 0)) >= 2, "elites")
		t.ok(int(types.get("rest", 0)) >= 1, "a rest stop")


func test_run_enters_the_purple_chapter(t: TestCtx) -> void:
	var r := Run.create(_cat(), 41)
	r.enter_chapter("ch1_red", false)
	var boss: String = str(r.gmap["boss"])
	r.pos = boss
	r.ap = 5
	r.gnode(boss)["state"] = "seen"
	r.phase = "prepare"
	r.hunt_active = false
	_win(r)
	t.eq(r.phase, "branch", "red boss down → choose the chapter-2 branch")
	t.ok(bool(r.choose_branch("ch2_purple")["ok"]), "purple chapter")
	t.eq(r.phase, "chapter_end", "…then a truck mod (time 2)")
	for id: String in r.mod_options:
		var md: Dictionary = r.mod_def(id)
		t.ok(int(md["t_min"]) <= 2 and int(md["t_max"]) >= 2, "%s appears at time 2" % id)
	var purple := false
	for id2: String in r.mod_options:
		if str(r.mod_def(id2)["color"]) == "purple":
			purple = true
	t.ok(purple, "at least one purple mod for the purple chapter")
	t.ok(bool(r.pick_mod(r.mod_options[0])["ok"]), "pick")
	t.eq(r.chapter_id, "ch2_purple", "now in chapter 2-A")
	t.ok(r.is_grid() and bool(r.gmap.get("island", false)), "on the sky island")
	t.eq(r.phase, "map", "on its map")
	t.eq(str(r.chapter.get("theme", "")), "purple", "purple theme")
	# 第一场作战：紫之章的战斗地图(坚冰 + 寒雾)
	var reach: Dictionary = r.reachable()
	var fight := ""
	for k: String in reach.keys():
		if k != r.pos and str(r.gnode(k)["type"]) == "fight":
			fight = k
			break
	if fight == "":
		for k2: String in reach.keys():
			if k2 != r.pos:
				fight = k2
				r.gnode(k2)["type"] = "fight"
				break
	t.ok(fight != "", "(a reachable fight node)")
	t.ok(bool(r.move_to(fight)["ok"]), "drive there")
	t.eq(r.phase, "prepare", "preparing")
	var lay: Dictionary = r.current_layout()
	t.eq(str(lay.get("theme", "")), "purple", "purple battle map")
	var ice := 0
	for o: Dictionary in lay.get("obstacles", []):
		if str(o["style"]).begins_with("ice_"):
			ice += 1
	t.ok(ice >= 3 and ice == (lay.get("obstacles", []) as Array).size(), "the ruins are hard ice (%d)" % ice)
	t.ok((lay.get("frost", []) as Array).size() >= 1, "frost patches (%d)" % (lay.get("frost", []) as Array).size())
	var b := Battle.new(_cat(), 5)
	b.setup(r.build_battle_setup())
	t.ok(b.map.has_terrain(), "the battle has terrain effects")
	b.run_to_end()
	t.ok(b.state == "ended", "the placeholder encounter plays out")


func test_frost_patches_chill_whoever_stands_in_them(t: TestCtx) -> void:
	var layout := {"truck": false, "obstacles": [], "frost": [{"x": 6, "y": 6, "w": 2, "h": 2, "style": "frost_l"}]}
	var b: Battle = Fixture.make([{"def": "test_dummy", "pos": GC.cell_to_world(6, 6) + Vector2(0.5, 0.5)},
		{"def": "test_dummy", "team": 1, "pos": GC.cell_to_world(14, 14)}], 7, layout)
	var u: BUnit = b.units[0]
	var far: BUnit = b.units[1]
	t.eq(b.map.frost.size(), 1, "one frost patch on the map")
	t.ok(b.map.frost_at(u.pos, u.radius) == 0 and b.map.frost_at(far.pos, far.radius) == -1, "standing in it / not")
	t.ok(b.map.has_terrain(), "frost counts as terrain")
	b.start()
	b.advance_pending(GC.START_DELAY)
	for i in range(int(1.3 / GC.SIM_DT)):
		b.step()
	t.ok(u.status_count("chill") >= 1, "a second in the frost: Chilled (%d)" % u.status_count("chill"))
	t.eq(far.status_count("chill"), 0, "the unit outside is fine")
	t.ok(u.get_stats().attack_speed_multiplier < far.get_stats().attack_speed_multiplier, "chill slows attack speed")
	for i2 in range(int(5.0 / GC.SIM_DT)):
		b.step()
	t.ok(u.has_status_flag("frozen") or u.status_count("chill") >= 4, "standing in it for 6 s piles up chill until it freezes (chill %d, frozen %s)" % [u.status_count("chill"), str(u.has_status_flag("frozen"))])
	u.pos = GC.cell_to_world(2, 2)
	for i3 in range(int(12.0 / GC.SIM_DT)):
		b.step()
	t.eq(u.status_count("chill"), 0, "away from the frost the chill wears off")


func test_purple_maps_generate_ice_and_frost(t: TestCtx) -> void:
	var cfg := {"theme": "purple", "low": 3, "high": 3, "frost": 4, "regions": ["n", "e", "sw"]}
	var a: Dictionary = MapGen.generate(cfg, 77)
	t.eq(JSON.stringify(a), JSON.stringify(MapGen.generate(cfg, 77)), "same seed → same purple map")
	t.eq(str(a.get("theme", "")), "purple", "purple theme")
	var m: BattleMap = BattleMap.from_layout(a)
	t.eq(m.reachable_count(GC.DEPLOY_RECT.position), m.free_count(), "every free cell reachable")
	for o: Dictionary in m.obstacles:
		t.ok(str(o["style"]).begins_with("ice_"), "ruins are ice (%s)" % str(o["style"]))
		t.ok(not (o["rect"] as Rect2i).intersects(GC.DEPLOY_RECT), "no ice in the deploy zone")
		t.ok(ResourceLoader.exists("res://assets/world/%s.res" % str(o["style"])), "the ice model exists (%s)" % str(o["style"]))
	t.ok(m.frost.size() >= 2, "frost patches placed (%d)" % m.frost.size())
	for f: Dictionary in m.frost:
		t.ok(not (f["rect"] as Rect2i).intersects(GC.DEPLOY_RECT.grow(1)), "no frost in or next to the deploy zone")
		var fr: Rect2i = f["rect"]
		for y in range(fr.position.y, fr.end.y):
			for x in range(fr.position.x, fr.end.x):
				t.ok(not m.blocks_move(Vector2i(x, y)), "frost lies on open ground")
	t.eq(BattleMap.from_layout(m.to_layout()).frost.size(), m.frost.size(), "frost survives the layout round trip")
	for nm: String in ["jp_shrine", "jp_pagoda", "jp_house", "jp_lantern", "jp_wall", "jp_pine", "ice_shard_a", "ice_shard_b", "ice_shard_c", "ice_berg"]:
		t.ok(ResourceLoader.exists("res://assets/world/%s.res" % nm), "big-map model %s exists" % nm)
