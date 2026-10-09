extends SceneTree
## 战斗模拟基准：随机组队 + 随机断壁残垣地图跑 N 场，统计时长/胜率/超时/冲撞卡车。用法: -- n=200 seed=1
func _init() -> void:
	var n := 100
	var seed_value := 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("n="):
			n = int(a.substr(2))
		if a.begins_with("seed="):
			seed_value = int(a.substr(5))
	var cat := Catalog.load_all()
	var ids: Array[String] = cat.shop_unit_ids()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var wins := [0, 0, 0]
	var durations: Array[float] = []
	var timeouts := 0
	var raids := 0
	var by_unit_damage := {}
	var by_unit_count := {}
	var t0 := Time.get_ticks_msec()
	for i in range(n):
		var b := Battle.new(cat, rng.randi())
		var list: Array = []
		var sizes := [rng.randi_range(3, 5), rng.randi_range(3, 5)]
		# 我方在卡车四周的部署区，敌方随机分布在 1~3 个方位区域(与正式关卡同一套出生规则)
		var regions: Array = GC.REGION_ANGLE.keys()
		var wave: Array = []
		for k in range(sizes[1]):
			wave.append([ids[rng.randi() % ids.size()], 1 + rng.randi() % 2, regions[rng.randi() % regions.size()] if k < 3 else wave[k % 3][2], ""])
		var used: Array = []
		for e: Array in wave:
			used.append(e[2])
		var layout: Dictionary = MapGen.generate({"low": rng.randi_range(2, 5), "high": rng.randi_range(1, 4), "regions": used}, rng.randi())
		var map := BattleMap.from_layout(layout)
		var spawn: Array[Vector2] = cat.wave_positions(wave, map)
		var cells: Array[Vector2i] = GC.deploy_cells()
		for k2 in range(sizes[0]):
			var c: Vector2i = cells.pop_at(rng.randi() % cells.size())
			list.append({"def": ids[rng.randi() % ids.size()], "team": 0, "star": 1 + rng.randi() % 2,
				"cell": c, "weapon": ""})
		for k3 in range(wave.size()):
			list.append({"def": wave[k3][0], "team": 1, "star": wave[k3][1], "pos": spawn[k3], "weapon": ""})
		b.setup({"units": list, "map": layout})
		b.run_to_end()
		wins[b.winner] += 1
		if b.truck_damage > 0:
			raids += 1
		durations.append(b.time - GC.START_DELAY)
		if b.time - GC.START_DELAY >= GC.BATTLE_MAX_SECONDS - 0.1:
			timeouts += 1
			print("  timeout #%d state=%s" % [i, b.state])
			for u0: BUnit in b.units:
				if u0.alive:
					print("    team %d %-16s pos %s  hp %.0f  target %s" % [u0.team, u0.def.id, str(u0.pos.snapped(Vector2(0.1, 0.1))), u0.hp,
						u0.target.def.id if u0.target != null else "-"])
		for u: BUnit in b.units:
			by_unit_damage[u.def.id] = float(by_unit_damage.get(u.def.id, 0.0)) + u.st_damage + u.st_heal * 0.5
			by_unit_count[u.def.id] = int(by_unit_count.get(u.def.id, 0)) + 1
	durations.sort()
	print("battles=%d  wins(player/enemy/draw)=%s  timeouts=%d  truck raids=%d  wall=%d ms" % [n, str(wins), timeouts, raids, Time.get_ticks_msec() - t0])
	print("duration s: min %.1f  median %.1f  p90 %.1f  max %.1f" % [durations[0], durations[n / 2], durations[int(n * 0.9)], durations[n - 1]])
	var keys: Array = by_unit_damage.keys()
	keys.sort()
	for k in keys:
		print("  %-16s avg output/battle %.0f" % [k, float(by_unit_damage[k]) / float(by_unit_count[k])])
	quit()
