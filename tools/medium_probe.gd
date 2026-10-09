extends SceneTree
## 幻灵节点的过程探针：打印一场战斗里的召唤(幽灵 / 幽灵犬 / 吟唱中的狂野幽灵)、背刺、遗愿(魔典)、少女幻葬与召唤物的伤害(调试用)。
## godot --headless --path . --script res://tools/medium_probe.gd -- star=1 weapon=necro_grimoire foes=node_berserker,node_archer,node_shielder [mates=node_shielder] secs=40
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	var star: int = int(args.get("star", "1"))
	var foes: PackedStringArray = str(args.get("foes", "node_berserker,node_archer,node_shielder")).split(",")
	var units: Array = [{"def": "node_medium", "team": 0, "star": star, "pos": Vector2(0.0, 4.0), "weapon": str(args.get("weapon", "necro_grimoire"))}]
	var mates: PackedStringArray = str(args.get("mates", "node_shielder,node_archer")).split(",", false)
	for j in range(mates.size()):
		units.append({"def": mates[j], "team": 0, "star": star, "pos": Vector2(float(j) * 1.6 - 0.8, 2.2), "weapon": ""})
	for i in range(foes.size()):
		units.append({"def": foes[i], "team": 1, "star": star, "pos": Vector2((float(i) - (foes.size() - 1) * 0.5) * 1.6, -2.4), "weapon": ""})
	var b := Battle.new(cat, int(args.get("seed", "3")))
	b.setup({"units": units, "map": {"truck": false}, "cfg": {"traits": false}})
	b.start()
	var md: BUnit = b.units[0]
	var secs: float = float(args.get("secs", "40"))
	var by := {}
	var counts := {}
	while b.time < GC.START_DELAY + secs and b.state != "ended":
		b.step()
		for e: Dictionary in b.poll_events():
			var tm: float = b.time - GC.START_DELAY
			match str(e["t"]):
				"summon":
					var su: BUnit = e["unit"]
					var key: String = su.def.id + ("" if bool(e.get("spectral", true)) else "(feral)")
					counts[key] = int(counts.get(key, 0)) + 1
					if str(args.get("all", "0")) == "1":
						print("%5.2f summon %s ★%d" % [tm, key, su.star])
				"backstab":
					counts["backstab"] = int(counts.get("backstab", 0)) + 1
				"chant_start":
					if e["unit"] == md:
						print("%5.2f medium starts chanting (charges %d)" % [tm, int(md.ability_charges.get("node_medium_partner", -1))])
				"medium_funeral":
					print("%5.2f REQUIEM: chanted %.1f s, %d died during it → %d ghosts" % [tm, float(e["chanted"]), int(e["deaths"]), (e["spots"] as Array).size()])
				"damage":
					var s: BUnit = e["src"]
					if s != null and s.team == 0 and (s == md or s.is_summon):
						var k2: String = s.def.id + (" ff" if (e["dst"] as BUnit).team == 0 else "")
						by[k2] = float(by.get(k2, 0.0)) + float(e["amount"])
				"death":
					var du: BUnit = e["unit"]
					if not du.is_summon:
						print("%5.2f %s (team %d) died" % [tm, du.def.id, du.team])
	print("summons %s" % str(counts))
	print("damage by source %s" % str(by))
	print("t=%.1f winner=%d medium alive=%s" % [b.time - GC.START_DELAY, b.winner, str(md.alive)])
	quit()
