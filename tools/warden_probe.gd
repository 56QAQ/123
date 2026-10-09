extends SceneTree
## 守林节点的过程探针：-- a=node_warden,node_archer,node_shielder,node_peasant b=mob_ember_wrath,mob_ember_wrath,mob_ember_glut,mob_ember_sloth star=1
##   [weapon=verdant_grove|none] [n=20] [ehp=1]
## 打 n 场(不同种子)，统计：她在各形态里待了多久、各形态对敌的伤害(中毒单列)、切换了几次 / 真正倒下的比例、荒野意志的护盾量、
## 翠绿之林最后叠到的攻速、胜负与时长(调平衡用)
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	var star: int = int(args.get("star", "1"))
	var n: int = int(args.get("n", "20"))
	var forms: Array[String] = ["lion", "spider", "toad", "base"]
	var tot := {"wins": 0, "time": 0.0, "shifts": 0, "dead": 0, "shield": 0.0, "poison": 0.0, "as": 0.0}
	var t_in := {}
	var d_in := {}
	var reach := {}
	for f: String in forms:
		t_in[f] = 0.0
		d_in[f] = 0.0
		reach[f] = 0
	for run_i in range(n):
		var units: Array = []
		for side in range(2):
			var ids: PackedStringArray = str(args.get("a" if side == 0 else "b", "node_warden,node_archer,node_shielder,node_peasant" if side == 0 else
				"mob_ember_wrath,mob_ember_wrath,mob_ember_glut,mob_ember_sloth")).split(",", false)
			var sgn: float = -1.0 if side == 0 else 1.0
			for i in range(ids.size()):
				var d: UnitDef = cat.get_unit(ids[i])
				var ranged: bool = d.wclass_for(d.base_weapon_class).get("ranged", false)
				var w: String = ""
				if ids[i] == "node_warden" and side == 0:
					w = str(args.get("weapon", "verdant_grove"))
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
		var wd: BUnit = null
		for u: BUnit in b.units:
			if u.def.id == "node_warden" and u.team == 0:
				wd = u
		var seen := {}
		while b.state != "ended" and b.time < GC.START_DELAY + GC.BATTLE_MAX_SECONDS:
			b.step()
			var f0: String = Pipeline.warden_form(wd)
			if wd.alive and b.time > GC.START_DELAY:
				t_in[f0] += GC.SIM_DT
				seen[f0] = true
			for e: Dictionary in b.poll_events():
				match str(e["t"]):
					"form_shift":
						if e.get("unit") == wd and str(e.get("reason", "")) == "death":
							tot["shifts"] += 1
					"shield":
						if e.get("dst") == wd and str(e.get("ability", "")) == "node_warden_will":
							tot["shield"] += float(e.get("amount", 0.0))
					"damage":
						if e.get("src") == wd and (e["dst"] as BUnit).team == 1:
							if str(e.get("surface", "")) == "status":
								tot["poison"] += float(e["amount"])
							else:
								d_in[f0] += float(e["amount"])
					"death":
						if e.get("unit") == wd:
							tot["dead"] += 1
		for f: String in seen.keys():
			reach[f] += 1
		var hs: BStatus = wd.get_status("verdant_haste")
		if hs != null:
			tot["as"] += float(hs.pct_per_stack.get("attack_speed_multiplier", 0.0))
		if b.winner == 0:
			tot["wins"] += 1
		tot["time"] += b.time - GC.START_DELAY
	print("battles %d  wins %d  avg time %.1f s  warden really died %d  form shifts / battle %.2f" % [n, int(tot["wins"]), float(tot["time"]) / n,
		int(tot["dead"]), float(tot["shifts"]) / n])
	for f: String in forms:
		print("  %-6s reached %2d/%d  avg %.1f s  hit dmg %.0f" % [f, int(reach[f]), n, float(t_in[f]) / n, float(d_in[f]) / n])
	print("per battle: poison dmg %.0f  will shield %.0f  final verdant AS +%.0f%%" % [float(tot["poison"]) / n, float(tot["shield"]) / n, float(tot["as"]) / n * 100.0])
	quit()
