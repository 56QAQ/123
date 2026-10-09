extends SceneTree
## 踏影节点的过程探针：-- a=node_knight_errant,node_shielder,node_archer,node_student b=… star=2 [weapon=cyan_shadow|none]
## 打印每次逆光(瞬移到谁背后、凝暗层数)、淬血流失的生命、诛影层数与附带量、每 2 秒有几个敌人在索敌他，最后按来源汇总他的伤害(调试用)
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
				if id2 == "node_knight_errant" and side == 0:
					w = str(args.get("weapon", "cyan_shadow"))
					if w == "none":
						w = ""
				units.append({"def": id2, "team": side, "star": star, "pos": Vector2((float(n) - float(r.size() - 1) * 0.5) * 1.6, sgn * (2.2 if row == 0 else 4.2)), "weapon": w})
	var b := Battle.new(cat, int(args.get("seed", "3")))
	b.setup({"units": units, "map": {"truck": false}, "cfg": {"traits": false}})
	b.start()
	var k: BUnit = null
	for u: BUnit in b.units:
		if u.def.id == "node_knight_errant" and u.team == 0:
			k = u
	var by_src := {}
	var next_print := GC.START_DELAY
	while b.time < GC.START_DELAY + GC.BATTLE_MAX_SECONDS and b.state != "ended":
		b.step()
		for e: Dictionary in b.poll_events():
			var tt: float = b.time - GC.START_DELAY
			match str(e["t"]):
				"shadow_step":
					if e["unit"] == k:
						print("%5.2f BACKLIGHT -> behind %s  veil=%d" % [tt, (e["target"] as BUnit).def.id, k.status_stacks("shadow_veil")])
				"self_cost":
					if e["unit"] == k:
						print("        blood temper: lost %d hp" % int(float(e["amount"])))
				"shadow_slay":
					if e["unit"] == k:
						print("        shadow slay x%d (each hit +%d magic dot)" % [int(e["stacks"]), int(float(e["total"]))])
				"damage":
					if e.get("src") == k:
						var key: String = str(e.get("surface", "")) + ":" + str(e.get("ability", "")).get_slice("#", 0)
						by_src[key] = float(by_src.get(key, 0.0)) + float(e["amount"])
		if b.time >= next_print and k != null:
			next_print += 2.0
			var n_t := 0
			for o: BUnit in b.units:
				if o.alive and o.team != k.team and o.target == k:
					n_t += 1
					print("        targeted by %s (forced=%s, phase=%s)" % [o.def.id, str(o.forced_target == k), o.phase])
			print("%5.2f hp=%d veil=%d targeted_by=%d target=%s" % [b.time - GC.START_DELAY, int(k.hp), k.status_stacks("shadow_veil"), n_t,
				k.target.def.id if k.target != null else "-"])
	print("damage by source ", by_src)
	print("t=%.1f winner=%d" % [b.time - GC.START_DELAY, b.winner])
	quit()
