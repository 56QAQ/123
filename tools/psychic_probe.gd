extends SceneTree
## 导向节点的过程探针：-- a=node_psychic,node_archer,node_shielder,node_peasant b=mob_ember_wrath,mob_ember_wrath,mob_ember_glut,mob_ember_sloth star=1
##   [weapon=emag_intro|none] [n=20] [ehp=1]
## 打 n 场(不同种子)，统计：出手了几串连锁闪电、平均每串打几下 / 几个不同的敌人、平均吟唱倍率、她对敌的伤害、她活了多久、
## 麻痹施加次数与平均数值、敌人被麻痹打断几次(调平衡用)
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	var star: int = int(args.get("star", "1"))
	var n: int = int(args.get("n", "20"))
	var tot := {"wins": 0, "time": 0.0, "chains": 0, "hops": 0, "uniq": 0, "scale": 0.0, "dmg": 0.0, "alive": 0.0, "par": 0, "par_p": 0.0, "stops": 0}
	for run_i in range(n):
		var units: Array = []
		for side in range(2):
			var ids: PackedStringArray = str(args.get("a" if side == 0 else "b", "node_psychic,node_archer,node_shielder,node_peasant" if side == 0 else
				"mob_ember_wrath,mob_ember_wrath,mob_ember_glut,mob_ember_sloth")).split(",", false)
			var sgn: float = -1.0 if side == 0 else 1.0
			for i in range(ids.size()):
				var d: UnitDef = cat.get_unit(ids[i])
				var ranged: bool = d.wclass_for(d.base_weapon_class).get("ranged", false)
				var w: String = ""
				if ids[i] == "node_psychic" and side == 0:
					w = str(args.get("weapon", "emag_intro"))
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
			if u.def.id == "node_psychic" and u.team == 0:
				ps = u
		while b.state != "ended" and b.time < GC.START_DELAY + GC.BATTLE_MAX_SECONDS:
			b.step()
			if ps.alive and b.time > GC.START_DELAY:
				tot["alive"] += GC.SIM_DT
			for e: Dictionary in b.poll_events():
				match str(e["t"]):
					"chain_lightning":
						if e.get("unit") == ps:
							var path: Array = e.get("path", [])
							tot["chains"] += 1
							tot["hops"] += path.size()
							var uq := {}
							for pu: Variant in path:
								uq[pu] = true
							tot["uniq"] += uq.size()
					"attack_release":
						if e.get("unit") == ps:
							tot["scale"] += float(e.get("chant_scale", 1.0))
					"damage":
						if e.get("src") == ps and (e["dst"] as BUnit).team == 1:
							tot["dmg"] += float(e["amount"])
					"paralyze":
						if e.get("unit") == ps:
							tot["par"] += 1
							tot["par_p"] += float(e.get("p", 0.0))
					"paralyzed":
						if (e["unit"] as BUnit).team == 1:
							tot["stops"] += 1
		if b.winner == 0:
			tot["wins"] += 1
		tot["time"] += b.time - GC.START_DELAY
	var ch: float = maxf(1.0, float(tot["chains"]))
	print("battles %d  wins %d  avg time %.1f s  psychic alive %.1f s" % [n, int(tot["wins"]), float(tot["time"]) / n, float(tot["alive"]) / n])
	print("per battle: chains %.1f  hits/chain %.2f  distinct/chain %.2f  avg chant scale %.2f  damage to enemies %.0f" % [float(tot["chains"]) / n,
		float(tot["hops"]) / ch, float(tot["uniq"]) / ch, float(tot["scale"]) / ch, float(tot["dmg"]) / n])
	print("per battle: paralysis applied %.1f (avg %.1f%%)  enemy attacks interrupted %.1f" % [float(tot["par"]) / n,
		float(tot["par_p"]) / maxf(1.0, float(tot["par"])) * 100.0, float(tot["stops"]) / n])
	quit()
