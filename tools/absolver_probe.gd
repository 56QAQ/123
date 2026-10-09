extends SceneTree
## 灭罪节点的过程探针：-- a=node_absolver,node_shielder,node_archer,node_student b=… star=2 [weapon=light_heart|none]
## 打印每 2 秒的光束位置 / 锁定对象 / 增长倍率 / 半径，斩杀、击杀加成，按来源的伤害(光束主目标 / 溅射到敌人 / 溅射到队友)(调试用)
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
				if id2 == "node_absolver":
					w = str(args.get("weapon", "light_heart"))
					if w == "none":
						w = ""
				units.append({"def": id2, "team": side, "star": star, "pos": Vector2((float(n) - float(r.size() - 1) * 0.5) * 1.6, sgn * (2.2 if row == 0 else 4.2)), "weapon": w})
	var b := Battle.new(cat, int(args.get("seed", "3")))
	b.setup({"units": units, "map": {"truck": false}, "cfg": {"traits": false}})
	b.start()
	var v: BUnit = null
	for u: BUnit in b.units:
		if u.def.id == "node_absolver" and u.team == 0:
			v = u
	var by_src := {"main": 0.0, "splash_enemy": 0.0, "splash_ally": 0.0, "absolve": 0}
	var next_print := GC.START_DELAY
	while b.time < GC.START_DELAY + GC.BATTLE_MAX_SECONDS and b.state != "ended":
		b.step()
		for e: Dictionary in b.poll_events():
			match str(e["t"]):
				"damage":
					if e.get("src") == v and str(e.get("ability", "")) == "node_absolver_light":
						var dst: BUnit = e["dst"]
						var k: String = "main" if not bool(e.get("splash", false)) else ("splash_ally" if dst.team == v.team else "splash_enemy")
						by_src[k] = float(by_src[k]) + float(e["amount"])
				"absolve":
					by_src["absolve"] = int(by_src["absolve"]) + 1
					var tg: BUnit = e["target"]
					print("%5.2f ABSOLVE %s hp=%d" % [b.time - GC.START_DELAY, tg.def.id, int(tg.hp)])
				"light_boost":
					print("%5.2f light boost (kill)" % [b.time - GC.START_DELAY])
				"light_beam_start":
					print("%5.2f beam descends at %s" % [b.time - GC.START_DELAY, str(e["pos"])])
				"light_beam_end":
					print("%5.2f beam ends" % [b.time - GC.START_DELAY])
		if b.time >= next_print and v != null:
			next_print += 2.0
			var lb: Dictionary = v.meta.get("light_beam", {})
			if lb.is_empty():
				print("%5.2f no beam  phase=%s hp=%d" % [b.time - GC.START_DELAY, v.phase, int(v.hp)])
			else:
				var lk: BUnit = lb.get("lock") as BUnit
				print("%5.2f beam at %s lock=%s mult=%.2f rad=%.2f main=%s hp=%d" % [b.time - GC.START_DELAY, str(lb["pos"]), lk.def.id if lk != null else "-",
					float(lb["mult"]), float(lb["rad"]), str(b.pipeline.light_beam_main(v) != null), int(v.hp)])
	print("damage by source ", by_src)
	print("t=%.1f winner=%d" % [b.time - GC.START_DELAY, b.winner])
	quit()
