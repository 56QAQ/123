extends SceneTree
## 清场基准：一个棋子(+ 它召出来的东西)打 n 个不动不还手的木桩(每个 hp 生命、def 护甲 / 魔抗)，报打死全部要几秒、平均每秒有效伤害。
## 用来比"攒到能打死才放"的输出(清扫节点的完美时计)和普通输出：打不死就不算伤害的机制，在无限血木桩上量不出来。
## godot --headless --path . --script res://tools/clear_bench.gd -- units=node_maid:blink_blade,node_samurai:blazing_glow,node_wizard:rainbow_flower
##     stars=1,2,3 n=3 hp=2000 def=40 dist=4.5 seeds=4 [cap=60]
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat: Catalog = Fixture.catalog()
	var n: int = int(args.get("n", "3"))
	var hp: float = float(args.get("hp", "2000"))
	var df: float = float(args.get("def", "40"))
	var dist: float = float(args.get("dist", "4.5"))
	var seeds: int = int(args.get("seeds", "4"))
	var cap: float = float(args.get("cap", "60"))
	print("清场  %d 个木桩 × %d 生命 / %d 护甲魔抗，距离 %.1f 米，每组 %d 场" % [n, int(hp), int(df), dist, seeds])
	print("%-16s %-18s %-3s %9s %9s %9s" % ["棋子", "武器", "★", "清场(秒)", "首杀(秒)", "有效伤害/s"])
	for spec: String in str(args.get("units", "node_maid:blink_blade,node_samurai:blazing_glow,node_wizard:rainbow_flower")).split(","):
		var parts: PackedStringArray = spec.split(":")
		var uid: String = parts[0]
		var wid: String = parts[1] if parts.size() > 1 else ""
		for star_s: String in str(args.get("stars", "1,2,3")).split(","):
			var star: int = int(star_s)
			var t_sum := 0.0
			var f_sum := 0.0
			for sd in range(seeds):
				var units: Array = [{"def": uid, "team": 0, "star": star, "pos": Vector2(0, -dist * 0.5), "weapon": wid}]
				for i in range(n):
					units.append({"def": "test_dummy", "team": 1, "star": 1, "pos": Vector2((float(i) - float(n - 1) * 0.5) * 1.6, dist * 0.5)})
				var b := Battle.new(cat, 500 + sd)
				b.setup({"units": units, "map": {"truck": false}, "cfg": {"traits": false}})
				b.start()
				for du: BUnit in b.units:
					if du.team == 1:
						du.base.max_health = hp
						du.base.defense = df
						du.base.magic_resistance = df
						du.mark_dirty()
						du.get_stats()                    # 先按新上限重算(按比例改当前生命)，再把当前生命设满
						du.hp = hp
				var first := -1.0
				while b.time < GC.START_DELAY + cap:
					b.step()
					b.events.clear()
					var alive := 0
					for du2: BUnit in b.units:
						if du2.team == 1 and du2.alive:
							alive += 1
					if alive < n and first < 0.0:
						first = b.time - GC.START_DELAY
					if alive == 0:
						break
				t_sum += b.time - GC.START_DELAY
				f_sum += first if first >= 0.0 else cap
			var tt: float = t_sum / float(seeds)
			print("%-16s %-18s %-3d %9.1f %9.1f %9.0f" % [uid, wid, star, tt, f_sum / float(seeds), hp * float(n) / maxf(0.1, tt)])
	quit()
