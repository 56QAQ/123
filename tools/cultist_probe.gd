extends SceneTree
## 锁芯节点的过程探针：-- star=1 [weapon=open_shut_key|none] [n=20] [ehp=1.5] [b=…]
## 打 n 场，统计：她活了多久、万物闭锁放了几次 / 平均锁住几个、开与闭发动几次 / 拽了几个、场上累计眩晕秒数、
## 闭锁的伤害、自己掉的血(血色仪式)、她的普攻次数
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	var star: int = int(args.get("star", "1"))
	var n: int = int(args.get("n", "20"))
	var w: String = str(args.get("weapon", "open_shut_key"))
	if w == "none":
		w = ""
	var tot := {"wins": 0, "time": 0.0, "alive": 0.0, "locks": 0, "locked": 0, "gates": 0, "pulled": 0, "stun": 0.0, "lock_dmg": 0.0,
		"other_dmg": 0.0, "bleed": 0.0, "attacks": 0, "deaths": 0}
	var taken := {}
	for run_i in range(n):
		var units: Array = []
		var ids: PackedStringArray = ["node_cultist", "node_archer", "node_shielder", "node_peasant"]
		var eids: PackedStringArray = str(args.get("b", "mob_ember_wrath,mob_ember_wrath,mob_ember_glut,mob_ember_sloth")).split(",", false)
		for i in range(ids.size()):
			var d: UnitDef = cat.get_unit(ids[i])
			var ranged: bool = d.wclass_for(d.base_weapon_class).get("ranged", false)
			units.append({"def": ids[i], "team": 0, "star": star, "pos": Vector2((float(i) - 1.5) * 1.6, -(4.2 if ranged else 2.2)), "weapon": w if i == 0 else ""})
		for i in range(eids.size()):
			units.append({"def": eids[i], "team": 1, "star": star, "pos": Vector2((float(i) - float(eids.size() - 1) * 0.5) * 1.6, 2.2)})
		var b := Battle.new(cat, 700 + run_i)
		b.setup({"units": units, "map": {"truck": false}, "cfg": {"traits": false}})
		b.start()
		var ehp: float = float(args.get("ehp", "1.5"))
		for u0: BUnit in b.units:
			if u0.team == 1:
				u0.base.max_health *= ehp
				u0.mark_dirty()
				u0.get_stats()
				u0.hp = u0.get_stats().max_health
		var cu: BUnit = b.units[0]
		while b.state != "ended" and b.time < GC.START_DELAY + GC.BATTLE_MAX_SECONDS:
			b.step()
			if cu.alive and b.time > GC.START_DELAY:
				tot["alive"] += GC.SIM_DT
			for e: Dictionary in b.poll_events():
				match str(e["t"]):
					"lock_close":
						if e.get("unit") == cu:
							tot["locks"] += 1
							tot["locked"] += (e.get("targets", []) as Array).size()
					"key_gate":
						if e.get("unit") == cu:
							tot["gates"] += 1
							tot["pulled"] += (e.get("targets", []) as Array).size()
					"attack_start":
						if e.get("unit") == cu:
							tot["attacks"] += 1
					"damage":
						if e.get("src") == cu and (e["dst"] as BUnit).team == 1:
							if str(e.get("ability", "")) == "node_cultist_lock":
								tot["lock_dmg"] += float(e["amount"])
							else:
								tot["other_dmg"] += float(e["amount"])
						elif e.get("dst") == cu and str(e.get("ability", "")) == "blood_rite":
							tot["bleed"] += float(e["amount"])
						elif e.get("dst") == cu and e.get("src") is BUnit:
							var sk: String = "%s/%s" % [(e["src"] as BUnit).def.id, str(e.get("ability", ""))]
							taken[sk] = float(taken.get(sk, 0.0)) + float(e["amount"])
		if not cu.alive:
			tot["deaths"] += 1
		if b.winner == 0:
			tot["wins"] += 1
		tot["time"] += b.time - GC.START_DELAY
		tot["stun"] += b.stun_time
	var lk: float = maxf(1.0, float(tot["locks"]))
	var gt: float = maxf(1.0, float(tot["gates"]))
	print("battles %d  wins %d  avg time %.1f s  cultist alive %.1f s  died in %d" % [n, int(tot["wins"]), float(tot["time"]) / n, float(tot["alive"]) / n, int(tot["deaths"])])
	print("per battle: attacks %.1f  locks %.1f (%.1f caught)  gates %.1f (%.1f pulled)  field stun %.1f s" % [float(tot["attacks"]) / n,
		float(tot["locks"]) / n, float(tot["locked"]) / lk, float(tot["gates"]) / n, float(tot["pulled"]) / gt, float(tot["stun"]) / n])
	var keys: Array = taken.keys()
	keys.sort_custom(func(x, y) -> bool: return float(taken[x]) > float(taken[y]))
	for k in keys.slice(0, 6):
		print("  taken from %s: %.0f / battle" % [k, float(taken[k]) / n])
	print("per battle: lock dmg %.0f  other dmg %.0f  bleed taken %.0f" % [float(tot["lock_dmg"]) / n, float(tot["other_dmg"]) / n, float(tot["bleed"]) / n])
	quit()
