extends SceneTree
## 白羽节点的过程探针：-- a=node_angel,node_archer,node_shielder,node_peasant b=mob_ember_wrath,mob_ember_wrath,mob_ember_glut,mob_ember_sloth star=1
##   [weapon=butterfly|none] [n=20] [ehp=1]
## 打 n 场(不同种子)，统计：送葬叠满倒下的我方 / 敌方单位数、精英失去上限次数、致求生的意志救下的次数、打向队友的回复次数与总量、
## 她对敌造成的伤害、胜负与时长(调平衡用)
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	var star: int = int(args.get("star", "1"))
	var n: int = int(args.get("n", "20"))
	var tot := {"ally_funeral": 0, "enemy_funeral": 0, "scar": 0, "saves": 0, "heal_shots": 0, "heal": 0.0, "dmg": 0.0, "wins": 0, "time": 0.0, "ally_deaths": 0}
	for run_i in range(n):
		var units: Array = []
		for side in range(2):
			var ids: PackedStringArray = str(args.get("a" if side == 0 else "b", "node_angel,node_archer,node_shielder,node_peasant" if side == 0 else
				"mob_ember_wrath,mob_ember_wrath,mob_ember_glut,mob_ember_sloth")).split(",", false)
			var sgn: float = -1.0 if side == 0 else 1.0
			for i in range(ids.size()):
				var d: UnitDef = cat.get_unit(ids[i])
				var ranged: bool = d.wclass_for(d.base_weapon_class).get("ranged", false)
				var w: String = ""
				if ids[i] == "node_angel" and side == 0:
					w = str(args.get("weapon", "butterfly"))
					if w == "none":
						w = ""
				units.append({"def": ids[i], "team": side, "star": star, "pos": Vector2((float(i) - float(ids.size() - 1) * 0.5) * 1.6, sgn * (4.2 if ranged else 2.2)), "weapon": w})
		var b := Battle.new(cat, 100 + run_i)
		b.setup({"units": units, "map": {"truck": false}, "cfg": {"traits": false}})
		b.start()
		var ehp: float = float(args.get("ehp", "1"))
		if ehp != 1.0:
			for u0: BUnit in b.units:
				if u0.team == 1:
					u0.base.max_health *= ehp
					u0.mark_dirty()
					u0.get_stats()
					u0.hp = u0.get_stats().max_health
		var ang: BUnit = null
		for u: BUnit in b.units:
			if u.def.id == "node_angel" and u.team == 0:
				ang = u
		while b.state != "ended" and b.time < GC.START_DELAY + GC.BATTLE_MAX_SECONDS:
			b.step()
			for e: Dictionary in b.poll_events():
				match str(e["t"]):
					"funeral":
						var ft: BUnit = e["target"]
						if not bool(e.get("kill", false)):
							tot["scar"] += 1
						elif ft.team == 0:
							tot["ally_funeral"] += 1
						else:
							tot["enemy_funeral"] += 1
					"funeral_save":
						tot["saves"] += 1
					"heal":
						if e.get("src") == ang and str(e.get("ability", "")) == "angel_heal":
							tot["heal_shots"] += 1
							tot["heal"] += float(e["amount"])
					"damage":
						if e.get("src") == ang and (e["dst"] as BUnit).team == 1:
							tot["dmg"] += float(e["amount"])
					"death":
						if (e["unit"] as BUnit).team == 0:
							tot["ally_deaths"] += 1
		if b.winner == 0:
			tot["wins"] += 1
		tot["time"] += b.time - GC.START_DELAY
	print("battles %d  wins %d  avg time %.1f s" % [n, int(tot["wins"]), float(tot["time"]) / float(n)])
	print("per battle: ally deaths %.2f (by funeral %.2f)  enemy funeral kills %.2f  elite scars %.2f  saves %.2f" % [float(tot["ally_deaths"]) / n,
		float(tot["ally_funeral"]) / n, float(tot["enemy_funeral"]) / n, float(tot["scar"]) / n, float(tot["saves"]) / n])
	print("per battle: heal shots %.1f (%.0f healed)  angel damage to enemies %.0f" % [float(tot["heal_shots"]) / n, float(tot["heal"]) / n, float(tot["dmg"]) / n])
	quit()
