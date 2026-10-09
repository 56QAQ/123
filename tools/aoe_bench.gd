extends SceneTree
## 群体输出基准(灾星节点 + 流星爆魔杖)：她召来的护星节点(改成打不死、攻击力 0)站在 N 个木桩(0 防、血无限、不动不还手)中间，
## 统计 secs 秒里灾星节点对敌人造成的总伤害 / 秒(打到护星节点身上的不算)。用来和单体输出(dps_bench)比：
## "敌人有几个的时候，她的总输出超过炽照节点"。
## godot --headless --path . --script res://tools/aoe_bench.gd -- stars=1,2,3 ns=1,2,3,4,6 secs=30 seeds=3 [weapon=meteor_staff] [gap=0.9]
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat: Catalog = Fixture.catalog()
	var weapon: String = str(args.get("weapon", "meteor_staff"))
	var secs: float = float(args.get("secs", "30"))
	var seeds: int = int(args.get("seeds", "3"))
	var gap: float = float(args.get("gap", "0.9"))
	print("群体输出  node_witch + %s  护星节点站在木桩中间  每组 %d 场 × %.0f 秒" % [weapon, seeds, secs])
	print("%-4s %-4s %10s %10s %10s %10s" % ["★", "N", "总输出/s", "每个/s", "普攻/s", "武器/s"])
	for star_s: String in str(args.get("stars", "1,2,3")).split(","):
		var star: int = int(star_s)
		for n_s: String in str(args.get("ns", "1,2,3,4,6")).split(","):
			var n: int = int(n_s)
			var tot := 0.0
			var na := 0.0
			var wp := 0.0
			for sd in range(seeds):
				var units: Array = [{"def": "node_witch", "team": 0, "star": star, "pos": Vector2(0, -4.0), "weapon": weapon}]
				var center := Vector2(0, 2.5)
				for i in range(n):
					var a: float = TAU * float(i) / float(maxi(1, n))
					var p: Vector2 = center + (Vector2(sin(a), cos(a)) * gap if n > 1 else Vector2(0, gap))
					units.append({"def": "test_dummy", "team": 1, "star": 1, "pos": p})
				var b := Battle.new(cat, 100 + sd)
				b.setup({"units": units})
				b.start()
				var witch: BUnit = b.units[0]
				var placed := false
				while b.time < secs and b.state != "ended":
					b.step()
					if not placed:
						for u: BUnit in b.units:
							if u.is_summon and u.team == 0:
								# 护星节点：放到木桩中间、打不死、不走不打(只当靶子中心)
								u.pos = center
								u.base.max_health = 1.0e7
								u.base.move_speed = 0.0
								u.base.attack_power = 0.0          # 武器留着(她只能打队友射程内的敌人)，但他自己不造成伤害
								u.mark_dirty()
								u.hp = 1.0e7
								placed = true
				for e: Dictionary in Fixture.events_of(b, "damage"):
					if e["src"] == witch and (e["dst"] as BUnit).team == 1:
						tot += float(e["amount"])
						if str(e.get("surface", "")) == "normal_attack":
							na += float(e["amount"])
						elif str(e.get("surface", "")) == "equipment":
							wp += float(e["amount"])
			var k: float = 1.0 / (float(seeds) * secs)
			print("%-4d %-4d %10.1f %10.1f %10.1f %10.1f" % [star, n, tot * k, tot * k / float(n), na * k, wp * k])
	quit()
