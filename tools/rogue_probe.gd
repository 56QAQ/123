extends SceneTree
## 巧运节点的过程探针(经济)：-- star=1 [weapon=coin_dagger|none] [n=12] [ehp=1.5] [b=mob_…,…]
## 连打 n 场(学习计数像真的一局那样跨战斗带下去)，每场统计：普攻命中次数、妙手摸到的金币、钱袋最后兑现的金币(翻倍 / 清空几次)、
## 打完的学习计数、胜负。看"一局下来他能赚多少"(一场普通作战收入 3 金)
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	var star: int = int(args.get("star", "1"))
	var n: int = int(args.get("n", "12"))
	var w: String = str(args.get("weapon", "coin_dagger"))
	if w == "none":
		w = ""
	var learning: Dictionary = {}
	var tot := {"hits": 0, "pick": 0, "cash": 0, "dbl": 0, "clr": 0, "wins": 0}
	for run_i in range(n):
		var units: Array = []
		var ids: PackedStringArray = ["node_rogue", "node_archer", "node_shielder", "node_peasant"]
		var eids: PackedStringArray = str(args.get("b", "mob_ember_wrath,mob_ember_wrath,mob_ember_glut,mob_ember_sloth")).split(",", false)
		for i in range(ids.size()):
			var d: UnitDef = cat.get_unit(ids[i])
			var ranged: bool = d.wclass_for(d.base_weapon_class).get("ranged", false)
			var e := {"def": ids[i], "team": 0, "star": star, "pos": Vector2((float(i) - 1.5) * 1.6, -(4.2 if ranged else 2.2))}
			if i == 0:
				e["weapon"] = w
				e["roster_id"] = "r1"
				e["learning"] = learning.duplicate()
			units.append(e)
		for i in range(eids.size()):
			units.append({"def": eids[i], "team": 1, "star": star, "pos": Vector2((float(i) - float(eids.size() - 1) * 0.5) * 1.6, 2.2)})
		var b := Battle.new(cat, 300 + run_i)
		b.setup({"units": units, "map": {"truck": false}, "cfg": {"traits": false}})
		b.start()
		var ehp: float = float(args.get("ehp", "1.5"))
		for u0: BUnit in b.units:
			if u0.team == 1:
				u0.base.max_health *= ehp
				u0.mark_dirty()
				u0.get_stats()
				u0.hp = u0.get_stats().max_health
		var rg: BUnit = b.units[0]
		var line := {"hits": 0, "pick": 0, "cash": 0, "dbl": 0, "clr": 0}
		while b.state != "ended" and b.time < GC.START_DELAY + GC.BATTLE_MAX_SECONDS:
			b.step()
			for e2: Dictionary in b.poll_events():
				match str(e2["t"]):
					"damage":
						if e2.get("src") == rg and str(e2.get("surface", "")) == "normal_attack":
							line["hits"] += 1
					"pickpocket":
						if e2.get("unit") == rg:
							line["pick"] += int(e2.get("amount", 1))
					"money_bag":
						if e2.get("unit") == rg:
							match str(e2.get("change", "")):
								"double":
									line["dbl"] += 1
								"clear":
									line["clr"] += 1
								"cash":
									line["cash"] += int(e2.get("delta", 0))
		learning = (b.learning_out.get("r1", {}) as Dictionary).duplicate()
		if b.winner == 0:
			tot["wins"] += 1
		for k: String in line.keys():
			tot[k] += line[k]
		print("battle %2d  %s  %.1f s  hits %3d  pickpocket %d  purse %3d (×2 %d, emptied %d)  learning %s" % [run_i + 1,
			"win " if b.winner == 0 else "lose", b.time - GC.START_DELAY, line["hits"], line["pick"], line["cash"], line["dbl"], line["clr"], str(learning)])
	print("total over %d battles: wins %d  pickpocket %d gold  purse %d gold  (%.1f gold / battle)" % [n, int(tot["wins"]), int(tot["pick"]), int(tot["cash"]),
		float(int(tot["pick"]) + int(tot["cash"])) / n])
	quit()
