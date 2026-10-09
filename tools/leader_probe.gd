extends SceneTree
## 真望节点的过程探针：两队按 team_bench 的站位打一场，打印金矢(回给谁、哪个能力)、觉醒、全灭 / 少女真心的复活、至远的弓弦的刷新、阵亡(调试用)。
## godot --headless --path . --script res://tools/leader_probe.gd -- a=node_leader,node_magi,node_spy,node_medium b=node_gladiator,node_samurai,node_maid,node_nurse
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
	var revives := 0
	while b.time < GC.START_DELAY + GC.BATTLE_MAX_SECONDS and b.state != "ended":
		b.step()
		for e2: Dictionary in b.poll_events():
			var tm: float = b.time - GC.START_DELAY
			match str(e2["t"]):
				"golden_arrow":
					if not quiet:
						print("%5.2f golden arrow → %s (%s now %d)" % [tm, (e2["target"] as BUnit).def.id, str(e2["ability"]), int(e2["charges"])])
				"awakened":
					print("%5.2f AWAKENED %s %s" % [tm, (e2["unit"] as BUnit).def.id, str(e2.get("key", ""))])
				"team_revive":
					revives += 1
					var names: Array = []
					for ru: BUnit in (e2["revived"] as Array):
						names.append("%s(%d)" % [ru.def.id, int(ru.hp)])
					print("%5.2f TRUE HEART #%d revives %s" % [tm, revives, ", ".join(names)])
				"refresh_once":
					print("%5.2f refresh once-per-battle on %s" % [tm, (e2["unit"] as BUnit).def.id])
				"damage":
					var ds: BUnit = e2["src"]
					var dd2: BUnit = e2["dst"]
					if args.has("ff") and ds != null and dd2 != null and ds.team == dd2.team and float(e2["amount"]) > 0.0:
						print("%5.2f   friendly fire %s → %s %d %s (%s)" % [tm, ds.def.id, dd2.def.id, int(float(e2["amount"])), str(e2["kind"]), str(e2.get("ability", ""))])
				"death":
					var du: BUnit = e2["unit"]
					if not du.is_summon and not quiet:
						print("%5.2f %s (team %d) died" % [tm, du.def.id, du.team])
	print("t=%.1f winner=%d revives=%d" % [b.time - GC.START_DELAY, b.winner, revives])
	quit()
