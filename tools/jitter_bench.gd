extends SceneTree
## 近战乱晃基准：几组近战 / 混编对打，量"已经贴上目标(在射程内)的近战棋子"每秒的——
##   转向：朝向变化的总角度(度/秒；一直对着目标打应该接近 0)、转向反复：朝向转动方向反过来的次数(次/秒)
##   挪动：位置移动的总距离(米/秒；站着打应该接近 0)、换目标：目标切换次数(次/分钟)
## godot --headless --path . --script res://tools/jitter_bench.gd -- [seeds=6] [secs=20]
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	var seeds: int = int(args.get("seeds", "6"))
	var secs: float = float(args.get("secs", "20"))
	var comps: Array = [
		["近战 4v4", ["node_darkknight", "node_berserker", "node_dancer", "node_vine"], ["node_shielder", "node_peasant", "node_druid", "node_gladiator"]],
		["混编 4v4", ["node_darkknight", "node_samurai", "node_archer", "node_student"], ["node_berserker", "node_vine", "node_bounty", "node_magi"]],
		["近战 5v5 挤一团", ["node_darkknight", "node_berserker", "node_samurai", "node_vine", "node_shielder"], ["node_peasant", "node_druid", "node_gladiator", "node_dancer", "node_warrior"]],
	]
	print("%-16s %10s %10s %10s %10s %8s" % ["阵容", "转向°/s", "反复/s", "挪动m/s", "换目标/分", "样本s"])
	for comp: Array in comps:
		var turn := 0.0
		var flips := 0
		var moved := 0.0
		var swaps := 0
		var sample := 0.0
		for sd in range(seeds):
			var units: Array = []
			for side: int in [0, 1]:
				var ids: Array = comp[1] if side == 0 else comp[2]
				for k in range(ids.size()):
					var x: float = (float(k) - float(ids.size() - 1) * 0.5) * 1.3
					units.append({"def": ids[k], "team": side, "star": 2, "pos": Vector2(x, (-1.0 if side == 0 else 1.0) * (2.5 + float(k % 2)))})
			var b := Battle.new(cat, 500 + sd)
			b.setup({"units": units, "map": {"truck": false}})
			b.start()
			var prev_f := {}
			var prev_p := {}
			var prev_d := {}
			var prev_t := {}
			while b.time < GC.START_DELAY + secs and b.state != "ended":
				b.step()
				for u: BUnit in b.units:
					if not u.alive or u.is_ranged() or not u.can_attack():
						prev_f.erase(u.uid)
						continue
					var t: BUnit = u.target
					var engaged: bool = t != null and t.alive and BattleAI.in_reach(u, t, u.pos.distance_to(t.pos), u.get_stats().range_meters()) \
						and u.phase != "dash"
					if prev_f.has(u.uid) and engaged and bool(prev_f[u.uid][1]):
						var df: float = angle_difference(float(prev_f[u.uid][0]), u.facing)
						turn += absf(rad_to_deg(df))
						var sgn: float = signf(df) if absf(df) > 0.002 else 0.0
						if sgn != 0.0 and float(prev_d.get(u.uid, 0.0)) != 0.0 and sgn != float(prev_d[u.uid]):
							flips += 1
						if sgn != 0.0:
							prev_d[u.uid] = sgn
						moved += u.pos.distance_to(prev_p[u.uid])
						sample += GC.SIM_DT
					if prev_t.has(u.uid) and prev_t[u.uid] != t and t != null and prev_t[u.uid] != null and (prev_t[u.uid] as BUnit).alive:
						swaps += 1
					prev_t[u.uid] = t
					prev_f[u.uid] = [u.facing, engaged]
					prev_p[u.uid] = u.pos
		var s: float = maxf(0.001, sample)
		print("%-16s %10.1f %10.2f %10.3f %10.1f %8.0f" % [comp[0], turn / s, float(flips) / s, moved / s, float(swaps) / s * 60.0, s])
	quit()
