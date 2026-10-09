extends SceneTree
## 打桩 DPS：一个棋子对着不会动、不会还手、血无限的木桩打 secs 秒，按真实战斗规则(AI、攻击状态机、装弹、触发器、暴击)统计。
## 用作单人输出的平衡基准。
## godot --headless --path . --script res://tools/dps_bench.gd -- def=node_archer weapons=basic_rifle,rapidfire_arbalest stars=1,2,3 secs=60 seeds=8 armor=0
##   armor   木桩的防御与魔抗(默认 0 = 裸伤)      dist  木桩距离(米，默认 3.5)
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	var armor: float = float(args.get("armor", "0"))
	var dummy := UnitDef.from_dict({"id": "bench_dummy", "cost": 1, "role": "tank", "base_weapon_class": "", "faction_id": "white",
		"available_in_shop": false, "base_stats": {"attack_power": 0, "defense": armor, "magic_resistance": armor, "max_health": 1.0e9,
		"crit_chance": 0.0, "move_speed": 0.0}, "triggers": [{"id": "bench_nothing", "timing": "OnBattleStart", "tags": ["none"]}]})
	cat.units["bench_dummy"] = dummy
	var unit_id: String = str(args.get("def", "node_archer"))
	var secs: float = float(args.get("secs", "60"))
	var seeds: int = int(args.get("seeds", "8"))
	var dist: float = float(args.get("dist", "3.5"))
	print("打桩 DPS  %s  木桩防御/魔抗 %.0f  每组 %d 场 × %.0f 秒" % [unit_id, armor, seeds, secs])
	print("%-22s %-3s %8s %8s %8s %8s %7s %7s %6s" % ["weapon", "★", "DPS", "普攻", "武器", "其它", "出手/s", "普攻暴击", "连射层"])
	for wid: String in str(args.get("weapons", "basic_rifle,rapidfire_arbalest")).split(","):
		for sts: String in str(args.get("stars", "1,2,3")).split(","):
			var star: int = int(sts)
			var tot := 0.0
			var by: Dictionary = {}
			var shots := 0
			var crits := 0
			var dmg_events := 0
			var stack_time := 0.0
			for s in range(seeds):
				var b := Battle.new(cat, 1000 + s)
				b.setup({"units": [{"def": unit_id, "team": 0, "star": star, "pos": Vector2(0, -dist * 0.5), "weapon": wid},
					{"def": "bench_dummy", "team": 1, "star": 1, "pos": Vector2(0, dist * 0.5), "weapon": ""}],
					"map": {"truck": false}, "cfg": {}})
				b.start()
				var u: BUnit = b.units[0]
				var t_end: float = GC.START_DELAY + secs
				while b.time < t_end and b.state != "ended":
					b.step()
					stack_time += float(u.status_stacks("rapid_fire")) * GC.SIM_DT
				tot += u.st_damage
				for sf: String in u.st_dmg_by_surface.keys():
					by[sf] = float(by.get(sf, 0.0)) + float(u.st_dmg_by_surface[sf])
				for e: Dictionary in b.events:
					if e.get("t") == "attack_release" and e.get("unit") == u:
						shots += 1
					if e.get("t") == "damage" and e.get("src") == u and e.get("surface") == "normal_attack":
						dmg_events += 1
						if bool(e.get("crit", false)):
							crits += 1
			var n: float = float(seeds) * secs
			var other: float = tot - float(by.get("normal_attack", 0.0)) - float(by.get("equipment", 0.0))
			print("%-22s %-3d %8.1f %8.1f %8.1f %8.1f %7.2f %6.1f%% %6.2f" % [wid, star, tot / n, float(by.get("normal_attack", 0.0)) / n,
				float(by.get("equipment", 0.0)) / n, other / n, float(shots) / n, 100.0 * float(crits) / maxf(1.0, float(dmg_events)), stack_time / n])
	quit()
