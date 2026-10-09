extends RefCounted
## 详细战报(BattleReport)：每一下伤害 / 治疗 / 护盾都记账，分项(来源技能 / 目标 / 攻击者)加起来等于总量，
## 和单位自己的统计(st_damage / st_taken / st_heal)一致；阵亡时刻、击杀、被护甲挡掉的量、护盾吸收；
## 独立的状态实例(燃烧#3)算同一个来源；战报里出现的来源都查得到名字(ReportNames)。


func _run(b: Battle, sec: float = 90.0) -> void:
	while b.time < sec and b.state != "ended":
		b.step()


func _sum(d: Dictionary, key: String) -> float:
	var s := 0.0
	for v: Dictionary in d.values():
		s += float(v[key])
	return s


func test_totals_add_up(t: TestCtx) -> void:
	var b := Fixture.make([
		{"def": "node_darkknight", "pos": Vector2(-1, 0), "star": 2, "weapon": "blackblade"},
		{"def": "node_nurse", "pos": Vector2(1, -2), "star": 2, "weapon": "heart_syringe"},
		{"def": "node_shielder", "pos": Vector2(0, 0), "star": 2},
		{"def": "node_peasant", "team": 1, "pos": Vector2(-1, 3), "star": 2},
		{"def": "node_archer", "team": 1, "pos": Vector2(1, 5), "star": 2},
		{"def": "node_student", "team": 1, "pos": Vector2(0, 5), "star": 2}], 11)
	b.start()
	_run(b)
	t.eq(b.state, "ended", "the battle finishes")
	var rep: BattleReport = b.report
	t.eq(rep.rows.size(), b.units.size(), "one row per unit (summons included)")
	t.near(rep.duration(), b.end_time - GC.START_DELAY, 0.01, "duration = fighting time")
	for u: BUnit in b.units:
		var r: Dictionary = rep.rows[u.uid]
		var nm: String = u.def.id
		t.near(float(r["dealt"]), u.st_damage, 0.5, "%s: dealt = st_damage" % nm)
		t.near(float(r["taken"]), u.st_taken, 0.5, "%s: taken = st_taken" % nm)
		t.near(float(r["heal"]), u.st_heal, 0.5, "%s: healing = st_heal" % nm)
		t.near(_sum(r["src"], "dmg"), float(r["dealt"]), 0.5, "%s: sources add up to the damage dealt" % nm)
		t.near(_sum(r["to"], "dmg"), float(r["dealt"]), 0.5, "%s: targets add up to the damage dealt" % nm)
		t.near(_sum(r["from"], "dmg"), float(r["taken"]), 0.5, "%s: attackers add up to the damage taken" % nm)
		t.near(_sum(r["from_src"], "dmg"), float(r["taken"]), 0.5, "%s: attacker skills add up to the damage taken" % nm)
		t.near(_sum(r["src"], "heal"), float(r["heal"]), 0.5, "%s: heal sources add up" % nm)
		t.ok(float(r["mitigated"]) >= 0.0 and float(r["absorbed"]) <= float(r["taken"]) + 0.5, "%s: mitigated ≥ 0, absorbed ≤ taken" % nm)
		var kinds := 0.0
		for k: String in (r["dealt_kind"] as Dictionary).keys():
			kinds += float(r["dealt_kind"][k])
		t.near(kinds, float(r["dealt"]), 0.5, "%s: damage types add up" % nm)
		t.eq(bool(r["alive"]), u.alive, "%s: alive flag" % nm)
		if not u.alive:
			t.ok(float(r["death"]) >= 0.0 and float(r["death"]) <= rep.duration() + 0.01, "%s: time of death recorded (%.1f s)" % [nm, float(r["death"])])
	var kills := 0
	for u2: BUnit in b.units:
		kills += int(rep.rows[u2.uid]["kills"])
	var deaths := 0
	for u3: BUnit in b.units:
		if not u3.alive:
			deaths += 1
	t.ok(kills <= deaths and kills > 0, "kills counted (%d kills, %d deaths)" % [kills, deaths])
	t.near(rep.team_total(0, "dealt") + rep.team_total(1, "dealt"), rep.team_total(0, "taken") + rep.team_total(1, "taken"), 1.0,
		"every point of damage dealt is someone's damage taken (no environment here)")


func test_armor_shield_and_crits(t: TestCtx) -> void:
	# 打手(攻 100)打一个 100 护甲的木桩：每下 50 被挡掉；木桩带 300 护盾
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.9)}])
	var h: BUnit = b.units[0]
	var d: BUnit = b.units[1]
	d.base.defense = 100.0
	d.mark_dirty()
	b.start()
	d.shield = 300.0
	for i in range(4):
		b.pipeline.normal_attack(h, d)
	var r: Dictionary = b.report.rows[d.uid]
	t.near(float(r["taken"]), 4 * 50.0, 0.5, "taken = after armor")
	t.near(float(r["mitigated"]), 4 * 50.0, 0.5, "mitigated = what the armor stopped")
	t.near(float(r["absorbed"]), 200.0, 0.5, "the shield absorbed it all")
	t.near(float(r["hp_lost"]), 0.0, 0.5, "no health lost behind the shield")
	var rh: Dictionary = b.report.rows[h.uid]
	t.eq(int(rh["hits"]), 4, "4 hits")
	t.ok((rh["src"] as Dictionary).has("na"), "normal attacks are one source")
	t.eq(int(rh["src"]["na"]["hits"]), 4, "with 4 hits")


func test_burn_instances_are_one_source(t: TestCtx) -> void:
	# 燃烧(各自独立的状态实例 burning#1, #2 …)：战报里只算一个来源
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2(0, 0)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 0.9)}])
	var h: BUnit = b.units[0]
	var d: BUnit = b.units[1]
	b.start()
	var cfg := {"status_id": "burning", "duration": 3.0, "independent": true, "flags": ["debuff", "burning"], "dot": {"kind": "magic", "amount": 20.0, "interval": 1.0}}
	for i in range(3):
		b.pipeline.fx.apply_status(h, d, cfg, {})
	_run(b, b.time + 4.0)
	var srcs: Dictionary = b.report.rows[h.uid]["src"]
	var burn_keys: Array = []
	for k: String in srcs.keys():
		if str(srcs[k]["ability"]).begins_with("burning"):
			burn_keys.append(k)
	t.eq(burn_keys.size(), 1, "three burns, one source (%s)" % str(burn_keys))
	if burn_keys.size() == 1:
		t.ok(int(srcs[burn_keys[0]]["hits"]) >= 6, "all their ticks counted (%d)" % int(srcs[burn_keys[0]]["hits"]))
		var nm: Dictionary = ReportNames.source(Fixture.catalog(), "test_hitter", str(srcs[burn_keys[0]]["surface"]), str(srcs[burn_keys[0]]["ability"]), "")
		t.eq(str(nm["name"]), Loc.t("status.burning"), "named after the status")


func test_every_source_has_a_name(t: TestCtx) -> void:
	# 几个带被动 / 武器效果 / 羁绊的阵容：战报里的每个来源都查得到名字(查不到会落到"其他")
	var teams: Array = [["node_taoist", "node_magi", "node_druid", "node_vine"], ["node_gladiator", "node_cowboy", "node_witch", "node_berserker"],
		["node_nurse", "node_dancer", "node_student", "node_shielder"]]
	var cat: Catalog = Fixture.catalog()
	var unknown: Array = []
	for i in range(teams.size()):
		var specs: Array = []
		for side: int in [0, 1]:
			var tm: Array = teams[i] if side == 0 else teams[(i + 1) % teams.size()]
			for k in range(tm.size()):
				specs.append({"def": tm[k], "team": side, "star": 2, "pos": Vector2((float(k) - 1.5) * 1.4, (-1.0 if side == 0 else 1.0) * (2.0 + float(k % 2) * 2.0))})
		var b := Fixture.make(specs, 5 + i)
		b.start()
		_run(b)
		for r: Dictionary in b.report.rows.values():
			for se: Dictionary in (r["src"] as Dictionary).values():
				var nm: Dictionary = ReportNames.source(cat, str(r["def"]), str(se["surface"]), str(se["ability"]), str(se["equip"]))
				if bool(nm["unknown"]):
					unknown.append("%s:%s/%s/%s" % [r["def"], se["surface"], se["ability"], se["equip"]])
	t.eq(unknown, [], "no nameless sources")
