extends RefCounted
## 战斗强度阈值测试(测试场用的 IntensityProbe)：搜索能找到门槛、一边倒的强度少打几场、同一场的配怪可复现、按自己的摆放 / 自动站位。


func _team() -> Array:
	return [{"def": "node_archer", "star": 1, "weapon": "", "cell": Vector2i(12, 8)},
		{"def": "node_shielder", "star": 1, "weapon": "", "cell": Vector2i(11, 8)}]


func _drive(p: IntensityProbe, win: Callable) -> int:
	var guard := 0
	while not p.done and guard < 20000:
		var job: Dictionary = p.next_job()
		p.report(bool(win.call(int(job["iv"]), int(job["k"]))))
		guard += 1
	return guard


func test_search_finds_the_highest_passing_intensity(t: TestCtx) -> void:
	for thr: int in [2, 4, 9, 14, 23, 57, 99, 140]:
		var p := IntensityProbe.new()
		p.setup(Fixture.catalog(), _team(), {"seed": 3})
		var n: int = _drive(p, func(iv: int, _k: int) -> bool: return iv <= thr)
		var want: int = -1 if thr < 4 else mini(thr, 100)
		t.ok(p.done, "the search finishes (threshold %d, %d fights)" % [thr, n])
		t.eq(p.best, want, "highest passing intensity = %d" % want)
		for iv: int in p.cache.keys():
			var c: Dictionary = p.cache[iv]
			t.eq(bool(c["pass"]), iv <= thr, "intensity %d judged %s" % [iv, "pass" if iv <= thr else "fail"])
			t.ok(int(c["n"]) <= 7, "lopsided intensities take few fights (%d at %d)" % [int(c["n"]), iv])


func test_edge_intensities_get_more_fights(t: TestCtx) -> void:
	# 每个强度的胜率是 1 - iv / 40(30 → 25%，10 → 75%)：门槛附近的强度要多打才分得出来
	var p := IntensityProbe.new()
	p.setup(Fixture.catalog(), _team(), {"seed": 5, "max": 60})
	_drive(p, func(iv: int, k: int) -> bool: return float((k * 7919 + iv * 104729) % 1000) / 1000.0 < 1.0 - float(iv) / 40.0)
	t.ok(p.done and p.best >= 4 and p.best <= 14, "lands near the 70%% line (%d)" % p.best)
	var most := 0
	for iv: int in p.cache.keys():
		most = maxi(most, int(p.cache[iv]["n"]))
	t.ok(most > 7, "an edge intensity was fought more than 7 times (%d)" % most)


func test_the_same_job_is_the_same_fight(t: TestCtx) -> void:
	var a := IntensityProbe.new()
	a.setup(Fixture.catalog(), _team(), {"seed": 9})
	var b := IntensityProbe.new()
	b.setup(Fixture.catalog(), _team(), {"seed": 9})
	var job := {"iv": 22, "k": 3, "deploy": "front"}
	var ba: Battle = a.make_battle(job)
	var bb: Battle = b.make_battle(job)
	t.eq(str(a.run.wave_def()["units"]), str(b.run.wave_def()["units"]), "same monsters for the same (seed, intensity, k)")
	t.eq(ba.units.size(), bb.units.size(), "same battle")
	var orbs := 0
	for e: Array in a.run.wave_def()["units"]:
		orbs += 1 if (e[4] as Dictionary).has("orb") else 0
	t.eq(orbs, 0, "no loot orbs in test fights")


func test_keep_cells_or_auto_deploy(t: TestCtx) -> void:
	var mine := IntensityProbe.new()
	mine.setup(Fixture.catalog(), _team(), {"seed": 2, "keep_cells": true})
	t.eq(mine.deploys, ["mine"] as Array[String], "keep my positions: one way of standing")
	var job: Dictionary = mine.next_job()
	var b: Battle = mine.make_battle(job)
	var at := {}
	for u: BUnit in b.units:
		if u.team == GC.TEAM_PLAYER:
			at[u.def.id] = GC.world_to_cell(u.pos)
	t.eq(at.get("node_archer"), Vector2i(12, 8), "the archer stands where I put her")
	var auto := IntensityProbe.new()
	auto.setup(Fixture.catalog(), [{"def": "node_archer", "star": 1, "weapon": "", "cell": null}], {"seed": 2})
	t.eq(auto.deploys, ["front", "compact"] as Array[String], "auto: front → compact (no melee tank, so no guard)")
