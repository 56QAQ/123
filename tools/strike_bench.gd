extends SceneTree
## 一击基准(灾星节点 + 流星爆魔杖)：护星节点贴着一个同星级的 1 费坦克，周围再挤 k 个敌人(都定住、不攻击)，
## 等开战第 10 秒的第一轮流星，看这一击能不能秒掉坦克。架盾节点的护盾照常充能(这 10 秒攒下的护盾算进去)。
## godot --headless --path . --script res://tools/strike_bench.gd -- stars=1,2,3 ks=2,4,6 tank=node_shielder,node_peasant filler=node_archer [y=1.5] [x=1.0]
##   报：这一击打在坦克身上的伤害 / 坦克当时的血 + 护盾、秒杀与否、范围命中加成倍率、护星节点承受的伤害
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	if args.has("y"):
		cat.get_equipment("meteor_staff").abilities[0].value_multiplier = float(args["y"])
	if args.has("x"):
		for tr: TriggerDef in cat.get_unit("node_witch").triggers:
			if tr.id == "node_witch_smile":
				tr.base_value_ratio = float(args["x"])
				tr.ratio_by_star = {}
	var filler: String = str(args.get("filler", "node_archer"))
	print("一击  灾星节点(流星爆魔杖)  坦克同星级  周围填充 %s" % filler)
	print("%-14s %-3s %-3s %10s %10s %6s %7s %10s" % ["坦克", "★", "k", "打在坦克上", "坦克血+盾", "秒杀", "加成", "护星承伤"])
	for tank: String in str(args.get("tank", "node_shielder,node_peasant")).split(","):
		for sts: String in str(args.get("stars", "1,2,3")).split(","):
			var star: int = int(sts)
			if star < 2:
				print("%-14s %-3d     (1 星装不了红色的流星爆魔杖)" % [tank, star])
				continue
			for ks: String in str(args.get("ks", "2,4,6")).split(","):
				var k: int = int(ks)
				var units: Array = [{"def": "node_witch", "team": 0, "star": star, "pos": Vector2(0, -7), "weapon": "meteor_staff"},
					{"def": tank, "team": 1, "star": star, "pos": Vector2(0, 2.0), "weapon": ""}]
				for i in range(k):
					var ang: float = TAU * float(i) / float(maxi(1, k))
					units.append({"def": filler, "team": 1, "star": star, "pos": Vector2(0, 2.0) + Vector2(cos(ang), sin(ang)) * 1.3, "weapon": ""})
				var b := Battle.new(cat, 4000)
				b.setup({"units": units, "map": {"truck": false}, "cfg": {"traits": false}})
				b.start()
				var tu: BUnit = b.units[1]
				var wr: BUnit = null
				for u: BUnit in b.units:
					if u.def.id == "node_warrior":
						wr = u
				wr.pos = Vector2(0, 0.85)
				var hp_at := 0.0
				var cast_seen := false
				var dmg_tank := 0.0
				var dmg_wr := 0.0
				var mult := 1.0
				while b.time < 12.0 and b.state != "ended":
					for u2: BUnit in b.units:
						u2.attack_cd = 99.0                 # 都不普攻：只看这一击
						u2.vel = Vector2.ZERO
						if u2 != b.units[0]:
							u2.pos = u2.prev_pos if b.time > 0.1 else u2.pos
					b.step()
					for e: Dictionary in b.poll_events():
						if e.get("t") == "meteor_cast" and not cast_seen:
							cast_seen = true
							hp_at = tu.hp + tu.shield
						if e.get("t") == "damage" and str(e.get("surface", "")) == "equipment" and cast_seen:
							if e["dst"] == tu:
								dmg_tank += float(e["amount"])
							elif e["dst"] == wr:
								dmg_wr += float(e["amount"])
					if cast_seen and b.time > 11.5:
						break
				var ab: AbilityDef = b.units[0].weapon.abilities[0]
				mult = 1.0 + b.units[0].get_stats().aoe_hit_amp_pct * float(k + 1 + 2)
				print("%-14s %-3d %-3d %10.0f %10.0f %6s %6.2fx %10.0f" % [tank, star, k, dmg_tank, hp_at, "是" if not tu.alive else "否", mult, dmg_wr])
	quit()
