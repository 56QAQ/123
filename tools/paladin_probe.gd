extends SceneTree
## 圣战节点的过程探针：-- a=node_paladin,node_archer,node_shielder,node_peasant b=mob_ember_wrath,mob_ember_wrath,mob_ember_glut,mob_ember_sloth star=1
##   [weapon=warhammer|none] [n=20] [ehp=1]
## 打 n 场(不同种子)，统计：裂地猛击砸了几次、平均每次砸到几个敌人、猛击伤害 / 普攻伤害、打碎几块地形、他活了多久、
## 锤子眩晕了几次(平均几秒)、圣疗回复量(调平衡用)
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	var star: int = int(args.get("star", "1"))
	var n: int = int(args.get("n", "20"))
	var tot := {"wins": 0, "time": 0.0, "slams": 0, "hit": 0, "slam_dmg": 0.0, "na_dmg": 0.0, "broke": 0, "alive": 0.0, "stuns": 0, "stun_s": 0.0, "heal": 0.0}
	for run_i in range(n):
		var units: Array = []
		for side in range(2):
			var ids: PackedStringArray = str(args.get("a" if side == 0 else "b", "node_paladin,node_archer,node_shielder,node_peasant" if side == 0 else
				"mob_ember_wrath,mob_ember_wrath,mob_ember_glut,mob_ember_sloth")).split(",", false)
			var sgn: float = -1.0 if side == 0 else 1.0
			for i in range(ids.size()):
				var d: UnitDef = cat.get_unit(ids[i])
				var ranged: bool = d.wclass_for(d.base_weapon_class).get("ranged", false)
				var w: String = ""
				if ids[i] == "node_paladin" and side == 0:
					w = str(args.get("weapon", "warhammer"))
					if w == "none":
						w = ""
				units.append({"def": ids[i], "team": side, "star": star, "pos": Vector2((float(i) - float(ids.size() - 1) * 0.5) * 1.6, sgn * (4.2 if ranged else 2.2)), "weapon": w})
		var b := Battle.new(cat, 100 + run_i)
		b.setup({"units": units, "map": {"truck": false}, "cfg": {"traits": false, "chapter_color": str(args.get("chapter", "red"))}})
		b.start()
		var ehp: float = float(args.get("ehp", "1"))
		if ehp != 1.0:
			for u0: BUnit in b.units:
				if u0.team == 1:
					u0.base.max_health *= ehp
					u0.mark_dirty()
					u0.get_stats()
					u0.hp = u0.get_stats().max_health
		var ps: BUnit = null
		for u: BUnit in b.units:
			if u.def.id == "node_paladin" and u.team == 0:
				ps = u
		while b.state != "ended" and b.time < GC.START_DELAY + GC.BATTLE_MAX_SECONDS:
			b.step()
			if ps.alive and b.time > GC.START_DELAY:
				tot["alive"] += GC.SIM_DT
			for e: Dictionary in b.poll_events():
				match str(e["t"]):
					"quake_slam":
						if e.get("unit") == ps:
							tot["slams"] += 1
							tot["hit"] += (e.get("targets", []) as Array).size()
							tot["broke"] += int(e.get("broke", 0))
					"damage":
						if e.get("src") == ps and (e["dst"] as BUnit).team == 1:
							if str(e.get("ability", "")) == "node_paladin_slam":
								tot["slam_dmg"] += float(e["amount"])
							elif str(e.get("surface", "")) == "normal_attack":
								tot["na_dmg"] += float(e["amount"])
					"status":
						if e.get("src") == ps and str(e.get("id", "")) == "stun":
							tot["stuns"] += 1
							var su: BUnit = e["unit"]
							var sst: BStatus = su.get_status("stun")
							if sst != null:
								tot["stun_s"] += maxf(0.0, sst.expires_at - b.time)
					"heal":
						if e.get("src") == ps and str(e.get("ability", "")) == "node_paladin_heal":
							tot["heal"] += float(e["amount"])
		if b.winner == 0:
			tot["wins"] += 1
		tot["time"] += b.time - GC.START_DELAY
	var sl: float = maxf(1.0, float(tot["slams"]))
	print("battles %d  wins %d  avg time %.1f s  paladin alive %.1f s" % [n, int(tot["wins"]), float(tot["time"]) / n, float(tot["alive"]) / n])
	print("per battle: slams %.1f  enemies/slam %.2f  slam dmg %.0f  NA dmg %.0f  terrain broken %.1f" % [float(tot["slams"]) / n,
		float(tot["hit"]) / sl, float(tot["slam_dmg"]) / n, float(tot["na_dmg"]) / n, float(tot["broke"]) / n])
	print("per battle: stuns %.1f (avg %.2f s)  holy mending healed %.0f" % [float(tot["stuns"]) / n, float(tot["stun_s"]) / maxf(1.0, float(tot["stuns"])),
		float(tot["heal"]) / n])
	quit()
