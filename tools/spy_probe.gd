extends SceneTree
## 幻形节点的过程探针：她站在敌人身边开打，打印误导(谁被误导、免疫自相残杀没有)、自相残杀的伤害、充能剩余、少女幻嘘的眩晕与战斗结束时的小小收获(调试用)。
## godot --headless --path . --script res://tools/spy_probe.gd -- star=1 weapon=myriad_words foes=node_berserker,node_archer,node_shielder [mates=node_shielder] [elite=0] secs=30
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	var star: int = int(args.get("star", "1"))
	var foes: PackedStringArray = str(args.get("foes", "node_berserker,node_archer,node_shielder")).split(",")
	var units: Array = [{"def": "node_spy", "team": 0, "star": star, "pos": Vector2(0.0, -3.4), "weapon": str(args.get("weapon", "myriad_words"))}]
	var mates: PackedStringArray = str(args.get("mates", "node_shielder,node_archer")).split(",", false)
	for j in range(mates.size()):
		units.append({"def": mates[j], "team": 0, "star": star, "pos": Vector2(float(j) * 1.6 - 0.8, 3.0), "weapon": ""})
	for i in range(foes.size()):
		var e := {"def": foes[i], "team": 1, "star": star, "pos": Vector2((float(i) - (foes.size() - 1) * 0.5) * 1.5, -4.5), "weapon": ""}
		if str(args.get("elite", "0")) == "1" and i == 0:
			e["elite"] = true
		units.append(e)
	var b := Battle.new(cat, int(args.get("seed", "3")))
	b.setup({"units": units, "map": {"truck": false}, "cfg": {"traits": false}})
	b.start()
	var spy: BUnit = b.units[0]
	var secs: float = float(args.get("secs", "30"))
	var ff := {0: 0.0, 1: 0.0}
	var misled := 0
	while b.time < GC.START_DELAY + secs and b.state != "ended":
		b.step()
		for e2: Dictionary in b.poll_events():
			match str(e2["t"]):
				"misled":
					misled += 1
					var mu: BUnit = e2["unit"]
					print("%5.2f misled %-16s team %d%s  (spy charges %d)" % [b.time - GC.START_DELAY, mu.def.id, mu.team, " [resist]" if bool(e2["resist"]) else "",
						int(spy.ability_charges.get("node_spy_shift", -1))])
				"damage":
					var s: BUnit = e2["src"]
					var d: BUnit = e2["dst"]
					if s != null and d != null and s.team == d.team and s != d:
						ff[s.team] += float(e2["amount"])
				"chant_start":
					if e2["unit"] == spy:
						print("%5.2f spy starts chanting" % (b.time - GC.START_DELAY))
				"spy_hush":
					print("%5.2f GRAND HUSH: chanted %.1f s → stun %.2f s on %d units" % [b.time - GC.START_DELAY, float(e2["chanted"]), float(e2["dur"]), (e2["hits"] as Array).size()])
				"gold", "xp":
					print("%5.2f %s +%d" % [b.time - GC.START_DELAY, str(e2["t"]), int(e2["amount"])])
	print("t=%.1f winner=%d misled=%d friendly fire: ours %d / theirs %d  spy alive=%s charges left %d  gold %d xp %d" % [b.time - GC.START_DELAY, b.winner, misled,
		int(ff[0]), int(ff[1]), str(spy.alive), int(spy.ability_charges.get("node_spy_shift", -1)), int(b.gold_gain[0]), int(b.xp_gain[0])])
	quit()
