extends SceneTree
## 奇兴节点的过程探针：-- star=1 [weapon=chaos_dice|none] [n=20] [ehp=1.5] [b=…]
## 打 n 场，统计：掷了几次骰、结果的分布(奇 / 偶 / <10 / ≥10 / ≥20 / 双 1)、掷骰造成的伤害、乱数的伤害、她活了多久、石化苏醒的时刻与加成
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	var star: int = int(args.get("star", "1"))
	var n: int = int(args.get("n", "20"))
	var w: String = str(args.get("weapon", "chaos_dice"))
	if w == "none":
		w = ""
	var tot := {"wins": 0, "time": 0.0, "alive": 0.0, "rolls": 0, "odd": 0, "low": 0, "mid": 0, "high": 0, "chaos": 0, "dice_dmg": 0.0, "d20_dmg": 0.0,
		"other_dmg": 0.0, "wakes": 0, "wake_t": 0.0, "wake_gain": 0.0}
	for run_i in range(n):
		var units: Array = []
		var ids: PackedStringArray = ["node_arcanist", "node_archer", "node_shielder", "node_peasant"]
		var eids: PackedStringArray = str(args.get("b", "mob_ember_wrath,mob_ember_wrath,mob_ember_glut,mob_ember_sloth")).split(",", false)
		for i in range(ids.size()):
			var d: UnitDef = cat.get_unit(ids[i])
			var ranged: bool = d.wclass_for(d.base_weapon_class).get("ranged", false)
			units.append({"def": ids[i], "team": 0, "star": star, "pos": Vector2((float(i) - 1.5) * 1.6, -(4.2 if ranged else 2.2)), "weapon": w if i == 0 else ""})
		for i in range(eids.size()):
			units.append({"def": eids[i], "team": 1, "star": star, "pos": Vector2((float(i) - float(eids.size() - 1) * 0.5) * 1.6, 2.2)})
		var b := Battle.new(cat, 500 + run_i)
		b.setup({"units": units, "map": {"truck": false}, "cfg": {"traits": false}})
		b.start()
		var ehp: float = float(args.get("ehp", "1.5"))
		for u0: BUnit in b.units:
			if u0.team == 1:
				u0.base.max_health *= ehp
				u0.mark_dirty()
				u0.get_stats()
				u0.hp = u0.get_stats().max_health
		var ar: BUnit = b.units[0]
		var last_src := ""
		while b.state != "ended" and b.time < GC.START_DELAY + GC.BATTLE_MAX_SECONDS:
			b.step()
			if ar.alive and b.time > GC.START_DELAY:
				tot["alive"] += GC.SIM_DT
			for e: Dictionary in b.poll_events():
				match str(e["t"]):
					"dice_roll":
						if e.get("unit") == ar:
							tot["rolls"] += 1
							if bool(e.get("chaos", false)):
								tot["chaos"] += 1
							else:
								if bool(e.get("odd", false)):
									tot["odd"] += 1
								tot[str(e.get("tier", "low"))] += 1
					"petrify_wake":
						if e.get("unit") == ar:
							tot["wakes"] += 1
							tot["wake_t"] += float(e.get("secs", 0.0))
							tot["wake_gain"] += float(e.get("gain", 0.0))
					"damage":
						if e.get("src") == ar and (e["dst"] as BUnit).team == 1:
							var ab: String = str(e.get("ability", ""))
							if ab == "node_arcanist_worlds":
								tot["dice_dmg"] += float(e["amount"])
							elif ab == "chaos_dice_roll":
								tot["d20_dmg"] += float(e["amount"])
							else:
								tot["other_dmg"] += float(e["amount"])
		if b.winner == 0:
			tot["wins"] += 1
		tot["time"] += b.time - GC.START_DELAY
	var r: float = maxf(1.0, float(tot["rolls"]))
	print("battles %d  wins %d  avg time %.1f s  arcanist alive %.1f s" % [n, int(tot["wins"]), float(tot["time"]) / n, float(tot["alive"]) / n])
	print("per battle: rolls %.1f  (odd %.0f%%  <10 %.0f%%  >=10 %.0f%%  >=20 %.0f%%  snake eyes %d total)" % [float(tot["rolls"]) / n,
		100.0 * float(tot["odd"]) / r, 100.0 * float(tot["low"]) / r, 100.0 * float(tot["mid"]) / r, 100.0 * float(tot["high"]) / r, int(tot["chaos"])])
	print("per battle: dice dmg %.0f  Randomness dmg %.0f  other dmg %.0f  | wakes %d (avg at %.1f s, +%.0f)" % [float(tot["dice_dmg"]) / n,
		float(tot["d20_dmg"]) / n, float(tot["other_dmg"]) / n, int(tot["wakes"]), float(tot["wake_t"]) / maxf(1.0, float(tot["wakes"])),
		float(tot["wake_gain"]) / maxf(1.0, float(tot["wakes"]))])
	quit()
