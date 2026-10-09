extends SceneTree
## 心音节点的过程探针：两队按 team_bench 的站位打一场，打印每段演奏(效果 / 对象)、结束时的治疗 / 伤害、冻结、阵亡(调试用)。
## godot --headless --path . --script res://tools/bard_probe.gd -- a=node_bard,node_archer,node_shielder b=node_archer,node_peasant,node_berserker
##     star=2 [basic=node_leader] [seed=3] [quiet=1] [ff=1 打印同队之间的伤害]
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	var star: int = int(args.get("star", "2"))
	var basic: PackedStringArray = str(args.get("basic", "")).split(",", false)
	var ex_of := {}
	for eid: String in cat.equipment.keys():
		var e: EquipmentDef = cat.get_equipment(eid)
		if e.owner != "":
			ex_of[e.owner] = eid
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
				var w: String = "" if basic.has(id2) else str(ex_of.get(id2, ""))
				units.append({"def": id2, "team": side, "star": star, "pos": Vector2((float(n) - float(r.size() - 1) * 0.5) * 1.6, sgn * (2.2 if row == 0 else 4.2)), "weapon": w})
	for ue: Dictionary in units:
		if cat.get_unit(str(ue["def"])).deploy_near_enemies:
			for uo: Dictionary in units:
				if int(uo["team"]) != int(ue["team"]):
					ue["pos"] = (uo["pos"] as Vector2) + Vector2(0.9, -signf((uo["pos"] as Vector2).y) * 0.9)
					break
	var b := Battle.new(cat, int(args.get("seed", "3")))
	b.setup({"units": units, "map": {"truck": false}, "cfg": {"traits": false}})
	b.start()
	var quiet: bool = args.has("quiet")
	while b.time < GC.START_DELAY + GC.BATTLE_MAX_SECONDS and b.state != "ended":
		b.step()
		for e2: Dictionary in b.poll_events():
			var tm: float = b.time - GC.START_DELAY
			match str(e2["t"]):
				"perform_start":
					var pt: BUnit = e2["target"]
					print("%5.2f PERFORM %s → %s(team %d)" % [tm, str(e2["opt"]), pt.def.id, pt.team])
				"freeze":
					print("%5.2f FREEZE %s %.2fs" % [tm, (e2["unit"] as BUnit).def.id, float(e2["duration"])])
				"heal":
					if (e2.get("src") as BUnit) != null and (e2["src"] as BUnit).def.id == "node_bard" and float(e2["amount"]) > 1.0 and not quiet:
						print("%5.2f   heal %s +%d" % [tm, (e2["dst"] as BUnit).def.id, int(float(e2["amount"]))])
				"damage":
					var ds: BUnit = e2.get("src") as BUnit
					if ds != null and ds.def.id == "node_bard" and float(e2["amount"]) > 1.0 and not quiet:
						print("%5.2f   dmg %s -%d %s" % [tm, (e2["dst"] as BUnit).def.id, int(float(e2["amount"])), str(e2.get("ability", ""))])
				"death":
					var du: BUnit = e2["unit"]
					if not du.is_summon:
						print("%5.2f %s (team %d) died" % [tm, du.def.id, du.team])
	var rep: Dictionary = b.report.rows
	for uu: BUnit in b.units:
		var rr: Dictionary = rep.get(uu.uid, {})
		print("  %s team %d dealt %d healed(done) %d taken %d" % [uu.def.id, uu.team, int(float(rr.get("dealt", 0))), int(float(rr.get("heal", 0))), int(float(rr.get("taken", 0)))])
	print("t=%.1f winner=%d" % [b.time - GC.START_DELAY, b.winner])
	quit()
