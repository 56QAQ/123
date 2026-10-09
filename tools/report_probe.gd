extends SceneTree
## 战报来源探针：随机 3v3(各拿专属武器、随机星级)打很多场，列出战报里出现过的每一种来源(surface | ability | equip)
## 和界面会显示的名字；名字查不到(落到"其他")的标 ✗。改了技能 / 新棋子后跑一下，确保战报里没有无名来源。
## godot --headless --path . --script res://tools/report_probe.gd -- [n=200] [chapter=ch1]
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	Loc.load_all()
	var n: int = int(args.get("n", "200"))
	var ids: Array[String] = []
	for uid: String in cat.units.keys():
		var d: UnitDef = cat.get_unit(uid)
		if d.cost > 0 or uid == "node_basic":
			ids.append(uid)
	var ex_of := {}
	for eid: String in cat.equipment.keys():
		var e: EquipmentDef = cat.get_equipment(eid)
		if e.owner != "":
			ex_of[e.owner] = eid
	# 地图：空地 / 第一章的燃烧废墟 + 余烬 / 两个专属战场(电车、喷泉)
	var maps: Array = [{}]
	for ch: String in cat.chapters.keys():
		var bm: Dictionary = (cat.chapters[ch] as Dictionary).get("battle_map", {})
		if bm.has("strong"):
			var mc: Dictionary = (bm["strong"] as Dictionary).duplicate()
			mc["regions"] = []
			maps.append(MapGen.generate(mc, 11 + maps.size()))
	for aid: String in cat.arenas.keys():
		maps.append(Events.arena_layout(cat, aid))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var seen := {}
	for i in range(n):
		var units: Array = []
		for side: int in [0, 1]:
			for k in range(4):
				var id: String = ids[rng.randi() % ids.size()]
				var star: int = 1 + rng.randi() % 3
				var wid: String = str(ex_of.get(id, "")) if rng.randf() < 0.7 else ""
				if wid != "" and cat.get_equipment(wid).equip_problem(cat.get_unit(id), star) != "":
					wid = ""
				var x: float = (float(k) - 1.5) * 1.5
				units.append({"def": id, "team": side, "star": star, "pos": Vector2(x, (-1.0 if side == 0 else 1.0) * (2.0 + float(k % 2) * 2.0)), "weapon": wid})
		var b := Battle.new(cat, 100 + i)
		b.setup({"units": units, "map": maps[i % maps.size()]})
		b.start()
		var guard := 0
		while b.state != "ended" and guard < 30 * 120:
			b.step()
			guard += 1
		for uid2: String in b.report.rows.keys():
			var r: Dictionary = b.report.rows[uid2]
			for sk: String in (r["src"] as Dictionary).keys():
				var se: Dictionary = r["src"][sk]
				var key: String = "%s | %s | %s | %s" % [r["def"], se["surface"], se["ability"], se["equip"]]
				if not seen.has(key):
					seen[key] = ReportNames.source(cat, str(r["def"]), str(se["surface"]), str(se["ability"]), str(se["equip"]))
			for fk: String in (r["from_src"] as Dictionary).keys():
				var fe: Dictionary = r["from_src"][fk]
				if str(fe["uid"]) == "":
					var key2: String = "(none) | %s | %s | %s" % [fe["surface"], fe["ability"], fe["equip"]]
					if not seen.has(key2):
						seen[key2] = ReportNames.source(cat, "", str(fe["surface"]), str(fe["ability"]), str(fe["equip"]))
	var keys: Array = seen.keys()
	keys.sort()
	var bad := 0
	for k2: String in keys:
		var nm: Dictionary = seen[k2]
		var ok: bool = not bool(nm.get("unknown", false))
		if not ok:
			bad += 1
		print("%s  %s  →  %s%s" % ["✓" if ok else "✗", k2, nm["name"], ("  (" + str(nm["sub"]) + ")") if str(nm.get("sub", "")) != "" else ""])
	print("REPORT_PROBE sources=%d unknown=%d maps=%d" % [keys.size(), bad, maps.size()])
	quit()

