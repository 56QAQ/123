extends RefCounted
## 第一章-B·蓝之章：穹顶箱庭的方格网(圆形的轮廓、首领在最北的信标下、起点在最南的边缘)、未来风的战斗地图(科技障碍、没有地形效果)、
## 从第零章的分支进入蓝之章。怪物暂时是红之章的占位。


func _cat() -> Catalog:
	return Fixture.catalog()


func test_chapter_data(t: TestCtx) -> void:
	var cat: Catalog = _cat()
	t.ok(cat.chapters.has("ch1_blue"), "chapter 1-B exists")
	var ch: Dictionary = cat.chapters["ch1_blue"]
	t.eq(int(ch["chapter_no"]), 1, "chapter number 1")
	t.eq(str(ch["color"]), "blue", "blue")
	t.eq(str(ch["theme"]), "blue", "blue battle theme")
	t.eq(str(ch["ui_theme"]), "dome", "dome UI theme")
	t.ok(UITheme.has("dome"), "the dome palette exists")
	t.eq(str(ch["overworld"]), "dome", "the dome-city map")
	t.eq(str(ch["grid"]["mask"]), "dome", "dome grid")
	t.ok(ch.has("monsters") and not (ch["monsters"] as Dictionary).is_empty(), "placeholder monsters are listed")
	for kind: String in ["fight", "elite", "boss", "hunt"]:
		var bm: Dictionary = ch["battle_map"][kind]
		t.ok(not bm.has("burning") and not bm.has("embers") and not bm.has("frost"), "%s battle maps have no terrain effects" % kind)
	var avail := false
	for b: Dictionary in (cat.chapters["ch0"]["next"] as Dictionary).get("branches", []):
		if str(b["id"]) == "ch1_blue":
			avail = bool(b.get("available", false))
	t.ok(avail, "chapter 0 offers the blue branch")
	for key: String in ["name", "short", "desc"]:
		t.ok(Loc.has_key("chapter.ch1_blue.%s" % key), "loc key chapter.ch1_blue.%s" % key)
	t.eq(cat.validate_all().filter(func(e: String) -> bool: return e.contains("ch1_blue")), [], "content validates")


func test_dome_map_shape(t: TestCtx) -> void:
	var cfg: Dictionary = _cat().chapters["ch1_blue"]["grid"]
	var w: int = int(cfg["w"])
	var h: int = int(cfg["h"])
	var cx: float = float(w - 1) * 0.5
	var cy: float = float(h - 1) * 0.5
	var rr: float = minf(cx, cy) + 0.45
	for sd in [1, 2, 3, 4, 5, 6, 7, 8]:
		var m: Dictionary = ChapterMap.generate(cfg, sd)
		t.eq(JSON.stringify(m), JSON.stringify(ChapterMap.generate(cfg, sd)), "deterministic (seed %d)" % sd)
		t.ok(bool(m.get("dome", false)) and not m.has("scar") and not m.has("mountain"), "a dome map (seed %d)" % sd)
		var nodes: Dictionary = m["nodes"]
		var boss: Vector2i = ChapterMap.cell(str(m["boss"]))
		var start: Vector2i = ChapterMap.cell(str(m["start"]))
		var miny := 999
		var maxy := -1
		for k: String in nodes.keys():
			var c: Vector2i = ChapterMap.cell(k)
			miny = mini(miny, c.y)
			maxy = maxi(maxy, c.y)
			var u: float = float(c.x) - cx
			var v: float = float(c.y) - cy
			t.ok(u * u + v * v <= (rr + 0.6) * (rr + 0.6), "nodes lie inside the dome (%s)" % k)
		t.eq(boss.y, miny, "the boss is on the northernmost row (under the beacon)")
		t.ok(absf(float(boss.x) - cx) <= 1.5, "…near the middle of it (%s)" % str(boss))
		t.eq(start.y, maxy, "the start is on the southernmost row")
		t.ok(absf(float(start.x) - cx) <= 2.0, "…near the middle too (%s)" % str(start))
		var adj: Dictionary = ChapterMap.neighbors(m)
		for e: Array in m["edges"]:
			var a: Vector2i = ChapterMap.cell(e[0])
			var b: Vector2i = ChapterMap.cell(e[1])
			t.eq(absi(a.x - b.x) + absi(a.y - b.y), 1, "edges join 4-neighbours")
		var seen := {m["start"]: true}
		var q: Array = [m["start"]]
		while not q.is_empty():
			var c2: String = q.pop_back()
			for n: String in adj[c2]:
				if not seen.has(n):
					seen[n] = true
					q.append(n)
		t.eq(seen.size(), nodes.size(), "connected")
		var d: int = int(m["path_len"])
		t.ok(d >= int(cfg["min_path"]) and d <= int(cfg["max_path"]), "start → boss shortest path in range (%d)" % d)
		t.ok(nodes.size() >= int(cfg["nodes"]) - 5 and nodes.size() <= w * h, "node count %d" % nodes.size())
		var types := {}
		for k2: String in nodes.keys():
			types[str(nodes[k2]["type"])] = int(types.get(str(nodes[k2]["type"]), 0)) + 1
		t.eq(int(types.get("boss", 0)), 1, "one boss")
		t.ok(int(types.get("elite", 0)) >= 2, "elites")
		t.ok(int(types.get("rest", 0)) >= 1, "a rest stop")
		t.ok(int(types.get("event", 0)) >= 2, "events")


func test_blue_battle_maps_are_city_tech(t: TestCtx) -> void:
	for sd in [3, 4, 5]:
		var layout: Dictionary = MapGen.generate({"low": 3, "high": 2, "theme": "blue", "regions": ["n", "nw", "ne"]}, sd)
		t.eq(str(layout["theme"]), "blue", "blue layout (seed %d)" % sd)
		var obs: Array = layout["obstacles"]
		t.eq(obs.size(), 5, "five obstacles")
		for o: Dictionary in obs:
			t.ok(str(o["style"]).begins_with("tech_"), "obstacle %s is city tech" % str(o["style"]))
			t.ok(ResourceLoader.exists("res://assets/world/%s.res" % str(o["style"])), "…with a model")
		t.ok((layout.get("embers", []) as Array).is_empty() and (layout.get("frost", []) as Array).is_empty(), "no ember / frost patches")
		var m: BattleMap = BattleMap.from_layout(layout)
		t.eq(m.reachable_count(GC.DEPLOY_RECT.position), m.free_count(), "connected")
	for nm: String in ["sf_tower_a", "sf_tower_b", "sf_block", "sf_pylon", "sf_tree", "sf_lamp", "sf_sign", "sf_beacon"]:
		t.ok(ResourceLoader.exists("res://assets/world/%s.res" % nm), "big-map model %s" % nm)


func test_entering_the_blue_chapter(t: TestCtx) -> void:
	var cat: Catalog = _cat()
	var r := Run.create(cat, 3)
	r.phase = "branch"
	t.eq(str(r.choose_branch("ch1_green")["reason"]), "ui.err.locked", "green is still locked")
	t.ok(bool(r.choose_branch("ch1_blue")["ok"]), "blue can be chosen from chapter 0")
	if r.phase == "chapter_end":
		t.eq(r.mod_options.size(), 3, "three mods offered on the way in")
		t.ok(bool(r.pick_mod(r.mod_options[0])["ok"]), "pick one")
	t.eq(r.chapter_id, "ch1_blue", "now in the blue chapter")
	t.ok(r.is_grid() and bool(r.gmap.get("dome", false)), "its dome grid is laid out")
	t.eq(str(r.chapter.get("theme", "")), "blue", "blue theme")
	# 走到最近的作战节点：战斗地图是科技障碍、没有地形
	var reach: Dictionary = r.reachable()
	var best := ""
	for k: String in reach.keys():
		if str(r.gnode(k).get("type", "")) == "fight" and (best == "" or int(reach[k]) < int(reach[best])):
			best = k
	t.ok(best != "", "a fight node is reachable")
	if best != "":
		t.ok(bool(r.move_to(best)["ok"]), "drive there")
		t.eq(r.phase, "prepare", "preparing")
		var lay: Dictionary = r.current_layout()
		t.eq(str(lay.get("theme", "")), "blue", "blue battle map")
		for o: Dictionary in lay.get("obstacles", []):
			t.ok(str(o["style"]).begins_with("tech_"), "tech obstacle %s" % str(o["style"]))
		t.ok((lay.get("embers", []) as Array).is_empty() and (lay.get("frost", []) as Array).is_empty(), "no terrain effects")
