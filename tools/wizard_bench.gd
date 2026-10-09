extends SceneTree
## 巫术节点输出基准：巫术节点(+ 他召来的鸟)打 N 个木桩(0 防、血无限、不动不还手)secs 秒，报总输出 / 秒，
## 以及飞弹 / 燃烧 / 鸟的普攻 / 虹光花(使魔之喙)各占多少、平均几只鸟、第几秒召出第一只鸟。
## 可以带一个队友(mate=node_cowboy mate_weapon=fleeting_revolver)，看鸟的天空视野给高频攻击的队友加了多少(mate 的输出单独列)。
## godot --headless --path . --script res://tools/wizard_bench.gd -- stars=1,2,3 weapons=basic_focus,rainbow_flower ns=1 secs=40 seeds=3
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat: Catalog = Fixture.catalog()
	var secs: float = float(args.get("secs", "40"))
	var seeds: int = int(args.get("seeds", "3"))
	var mate: String = str(args.get("mate", ""))
	print("巫术节点  打木桩  每组 %d 场 × %.0f 秒%s" % [seeds, secs, ("  队友 " + mate) if mate != "" else ""])
	print("%-15s %-3s %-3s %9s %8s %8s %8s %8s %6s %7s %9s" % ["武器", "★", "N", "总输出/s", "飞弹", "燃烧", "鸟普攻", "虹光花", "鸟数", "首鸟s", "队友/s"])
	for wid: String in str(args.get("weapons", "basic_focus,rainbow_flower")).split(","):
		for star_s: String in str(args.get("stars", "1,2,3")).split(","):
			var star: int = int(star_s)
			for n_s: String in str(args.get("ns", "1")).split(","):
				var n: int = int(n_s)
				var sums := {"tot": 0.0, "missile": 0.0, "burn": 0.0, "bird": 0.0, "flower": 0.0, "mate": 0.0, "birds": 0.0, "first": 0.0}
				for sd in range(seeds):
					var units: Array = [{"def": "node_wizard", "team": 0, "star": star, "pos": Vector2(0, -4.0), "weapon": wid}]
					if mate != "":
						units.append({"def": mate, "team": 0, "star": star, "pos": Vector2(1.5, -3.0), "weapon": str(args.get("mate_weapon", ""))})
					for i in range(n):
						units.append({"def": "test_dummy", "team": 1, "star": 1, "pos": Vector2((float(i) - float(n - 1) * 0.5) * 1.4, 3.0)})
					var b := Battle.new(cat, 900 + sd)
					b.setup({"units": units, "map": {"truck": false}})
					b.start()
					for du: BUnit in b.units:
						if du.team == 1:
							du.base.max_health = 1.0e8
							du.mark_dirty()
							du.hp = 1.0e8
					var w: BUnit = b.units[0]
					var first := -1.0
					var bird_t := 0.0
					while b.time < GC.START_DELAY + secs and b.state != "ended":
						b.step()
						var nb := 0
						for u: BUnit in b.units:
							if u.alive and u.is_summon and u.def.id == "node_bird":
								nb += 1
						if nb > 0 and first < 0.0:
							first = b.time - GC.START_DELAY
						bird_t += float(nb) * GC.SIM_DT
					for e: Dictionary in Fixture.events_of(b, "damage"):
						var src: BUnit = e["src"]
						var dst: BUnit = e["dst"]
						if src == null or dst.team != 1:
							continue
						var amt: float = float(e["amount"])
						if src == w:
							sums["tot"] += amt
							if str(e.get("surface", "")) == "status":
								sums["burn"] += amt
							elif str(e.get("surface", "")) == "equipment":
								sums["flower"] += amt
							else:
								sums["missile"] += amt
						elif src.is_summon and src.def.id == "node_bird":
							sums["tot"] += amt
							sums["bird"] += amt
						elif mate != "" and src == b.units[1]:
							sums["mate"] += amt
					sums["birds"] += bird_t / secs
					sums["first"] += first if first >= 0.0 else secs
				var k: float = 1.0 / (float(seeds) * secs)
				print("%-15s %-3d %-3d %9.1f %8.1f %8.1f %8.1f %8.1f %6.1f %7.1f %9.1f" % [wid, star, n, sums["tot"] * k, sums["missile"] * k, sums["burn"] * k,
					sums["bird"] * k, sums["flower"] * k, sums["birds"] / float(seeds), sums["first"] / float(seeds), sums["mate"] * k])
	quit()
