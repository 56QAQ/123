extends SceneTree
## 清扫节点的过程探针：打印一场小战斗里飞刀的停顿 / 放出 / 命中、清洁世界、女仆护身术 + 闪烁刀刃的时间线(调试用)。
## godot --headless --path . --script res://tools/maid_probe.gd -- star=1 weapon=blink_blade foe=node_samurai n=2 secs=12
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var star: int = int(args.get("star", "1"))
	var n: int = int(args.get("n", "2"))
	var units: Array = [{"def": "node_maid", "team": 0, "star": star, "pos": Vector2(0, -3.0), "weapon": str(args.get("weapon", "blink_blade"))}]
	for i in range(n):
		units.append({"def": str(args.get("foe", "node_samurai")), "team": 1, "star": star, "pos": Vector2((float(i) - float(n - 1) * 0.5) * 1.6, 3.5), "weapon": ""})
	var b := Battle.new(Fixture.catalog(), int(args.get("seed", "3")))
	b.setup({"units": units, "map": {"truck": false}, "cfg": {"traits": false}})
	b.start()
	var secs: float = float(args.get("secs", "12"))
	var held_max := 0
	while b.time < GC.START_DELAY + secs and b.state != "ended":
		b.step()
		var h := 0
		for p: Dictionary in b.projectiles:
			if p.has("hold") and str(p["hold"]["phase"]) != "in":
				h += 1
		held_max = maxi(held_max, h)
		if args.has("trace") and b.frames != int(args.get("_last", "-1")) and b.frames % 4 == 0:
			args["_last"] = str(b.frames)
			var line := "%6.2f  held %2d  maid hp %4d  phase %-7s" % [b.time - GC.START_DELAY, h, int(b.units[0].hp), b.units[0].phase]
			for fu: BUnit in b.units:
				if fu.team == 1:
					line += "  foe hp %4d d=%.1f" % [int(fu.hp), fu.pos.distance_to(b.units[0].pos)]
			print(line)
		for e: Dictionary in b.poll_events():
			var t: String = str(e["t"])
			var tm: String = "%6.2f" % (float(e["time"]) - GC.START_DELAY)
			match t:
				"held_release":
					print(tm, "  release ×", e["count"], " → ", (e["target"] as BUnit).def.id, "  hp ", int((e["target"] as BUnit).hp))
				"storm_start":
					print(tm, "  STORM  targets ", (e["targets"] as Array).size())
				"blink":
					print(tm, "  BLINK  ", e["from"], " → ", e["to"], "  ×", e["count"])
				"damage":
					if (e["src"] as BUnit) != null and (e["src"] as BUnit).def.id == "node_maid" and bool(args.get("dmg", "0") == "1"):
						print(tm, "    dmg ", int(float(e["amount"])), " crit=", e["crit"], " → ", (e["dst"] as BUnit).uid)
				"unit_died":
					print(tm, "  DIED ", (e["unit"] as BUnit).def.id, " team ", (e["unit"] as BUnit).team)
	var m: BUnit = b.units[0]
	print("end t=%.1f state=%s winner=%d  maid hp %d/%d  dealt %d  held max %d" % [b.time - GC.START_DELAY, b.state, b.winner, int(m.hp), int(m.get_stats().max_health), int(m.st_damage), held_max])
	quit()
