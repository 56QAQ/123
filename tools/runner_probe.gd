extends SceneTree
## 迅游节点的过程探针：打印一场战斗里每一脚飞身踢(目标 / 路程 / 倍率 / 伤害)、卡车借力、击退和他的移动速度(调试用)。
## godot --headless --path . --script res://tools/runner_probe.gd -- star=1 weapon=lightning_gloves foes=node_shielder,node_archer,node_berserker secs=20 truck=1
##   [mates=node_shielder,node_archer] 他的队友(站他旁边)
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	var star: int = int(args.get("star", "1"))
	var foes: PackedStringArray = str(args.get("foes", "node_shielder,node_archer,node_berserker")).split(",")
	var units: Array = [{"def": "node_runner", "team": 0, "star": star, "pos": Vector2(-2.0, 1.6), "weapon": str(args.get("weapon", "lightning_gloves"))}]
	var mates: PackedStringArray = str(args.get("mates", "")).split(",", false)
	for j in range(mates.size()):
		units.append({"def": mates[j], "team": 0, "star": star, "pos": Vector2(float(j) * 1.6 - 0.5, 2.2 if j % 2 == 0 else 3.6), "weapon": ""})
	for i in range(foes.size()):
		units.append({"def": foes[i], "team": 1, "star": star, "pos": Vector2((float(i) - (foes.size() - 1) * 0.5) * 1.8, -5.0), "weapon": ""})
	var b := Battle.new(cat, int(args.get("seed", "3")))
	b.setup({"units": units, "map": {"truck": str(args.get("truck", "1")) == "1"}, "cfg": {"traits": false}})
	b.start()
	var r: BUnit = b.units[0]
	var secs: float = float(args.get("secs", "20"))
	var dealt := 0.0
	var kicks := 0
	while b.time < GC.START_DELAY + secs and b.state != "ended":
		b.step()
		for e: Dictionary in b.poll_events():
			match str(e["t"]):
				"runner_kick":
					kicks += 1
					var tg: BUnit = e["target"]
					print("%5.2f kick #%d %-16s run %5.2f m  ×%.2f  speed %.2f m/s" % [b.time - GC.START_DELAY, kicks, tg.def.id, float(e["dist"]), float(e["mult"]),
						r.get_stats().speed_mps()])
				"runner_spring":
					print("%5.2f   spring at (%.1f, %.1f) truck=%s" % [b.time - GC.START_DELAY, (e["pos"] as Vector2).x, (e["pos"] as Vector2).y, str(e["truck"])])
				"knockback":
					print("%5.2f   knockback %s %.2f m" % [b.time - GC.START_DELAY, (e["unit"] as BUnit).def.id, (e["from"] as Vector2).distance_to(e["to"])])
				"damage":
					if e["src"] == r:
						dealt += float(e["amount"])
						if str(args.get("dmg", "0")) == "1":
							print("        dmg %-16s %6.0f %s %s" % [(e["dst"] as BUnit).def.id, float(e["amount"]), str(e["kind"]), str(e.get("ability", ""))])
	var t: float = b.time - GC.START_DELAY
	var died := ""
	if not r.alive:
		died = " (runner died)"
	print("t=%.1f state=%s winner=%d kicks=%d dealt=%d (%.0f/s) runner hp %d/%d%s" % [t, b.state, b.winner, kicks, int(dealt), dealt / maxf(0.1, t),
		int(r.hp), int(r.get_stats().max_health), died])
	quit()
