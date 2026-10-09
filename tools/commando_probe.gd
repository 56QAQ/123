extends SceneTree
## 止息节点的过程探针：-- a=node_commando,node_sniper,node_shielder,node_student b=… star=2 [weapon=black_mission|none] [sniper_weapon=black_battlefield|none]
## 打印每次突进(目标、击退)、标定、免费弹道(谁打的、倍率、伤害)、标定被消耗、掩护支援，最后汇总止息节点和远程友军的伤害(调试用)
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	var star: int = int(args.get("star", "2"))
	var units: Array = []
	for side in range(2):
		var ids: PackedStringArray = str(args.get("a" if side == 0 else "b", "")).split(",", false)
		var sgn: float = -1.0 if side == 0 else 1.0
		var front: Array = []
		var back: Array = []
		for id: String in ids:
			var d: UnitDef = cat.get_unit(id)
			(back if d.wclass_for(d.base_weapon_class).get("ranged", false) else front).append(id)
		for row in [0, 1]:
			var r: Array = front if row == 0 else back
			for n in range(r.size()):
				var id2: String = r[n]
				var w: String = ""
				if id2 == "node_commando" and side == 0:
					w = str(args.get("weapon", "black_mission"))
				elif id2 == "node_sniper" and side == 0:
					w = str(args.get("sniper_weapon", "black_battlefield"))
				if w == "none":
					w = ""
				units.append({"def": id2, "team": side, "star": star, "pos": Vector2((float(n) - float(r.size() - 1) * 0.5) * 1.6, sgn * (2.2 if row == 0 else 4.2)), "weapon": w})
	var b := Battle.new(cat, int(args.get("seed", "3")))
	b.setup({"units": units, "map": {"truck": false}, "cfg": {"traits": false}})
	b.start()
	var c: BUnit = null
	for u: BUnit in b.units:
		if u.def.id == "node_commando" and u.team == 0:
			c = u
	var dealt := {}
	while b.time < GC.START_DELAY + GC.BATTLE_MAX_SECONDS and b.state != "ended":
		b.step()
		for e: Dictionary in b.poll_events():
			var tt: float = b.time - GC.START_DELAY
			match str(e["t"]):
				"lunge_start":
					if e["unit"] == c:
						print("%5.2f LUNGE (%s) -> %s" % [tt, str(e["style"]), (e["target"] as BUnit).def.id])
				"lunge_end":
					if e["unit"] == c:
						print("%5.2f   landed, marked %s" % [tt, (e["target"] as BUnit).def.id])
				"mark_volley":
					if e["unit"] == c:
						print("%5.2f   FREE SHOT by %s (x%.2f) -> %s" % [tt, (e["shooter"] as BUnit).def.id, float(e["chant_scale"]), (e["target"] as BUnit).def.id])
				"mark_consumed":
					print("%5.2f   mark consumed on %s" % [tt, (e["unit"] as BUnit).def.id])
				"cover":
					if e["unit"] == c:
						print("%5.2f COVER -> %s" % [tt, (e["target"] as BUnit).def.id])
				"dodge":
					if e["unit"] == c:
						print("%5.2f   commando dodged" % tt)
				"damage":
					var s: BUnit = e.get("src") as BUnit
					if s != null and s.team == 0:
						dealt[s.def.id] = float(dealt.get(s.def.id, 0.0)) + float(e["amount"])
	print("dealt ", dealt)
	print("t=%.1f winner=%d" % [b.time - GC.START_DELAY, b.winner])
	quit()
