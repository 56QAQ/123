extends RefCounted
## 重构版护理节点：广义治疗(普攻索敌血最少的受伤队友；对友方的普攻伤害按最终伤害值 × x 换成治疗，溅射到敌人的照常是伤害)、
## 一对一看护(2 星：治疗带负面状态的队友时驱散持续时间最长的 1/1/3 个，冷却 5 秒【充能 2】，没有负面状态不触发)、
## 药水填充(每第 3 次普攻，目标 = 这次普攻的对象，触发数值 = 攻击力 × y)、专属武器爱心针剂(视为普攻伤害的物理溅射)。


func _run_until(b: Battle, sec: float) -> void:
	while b.time < sec and b.state != "ended":
		b.step()


## 关掉暴击(精确比数值)
func _no_crit(u: BUnit) -> void:
	u.base.crit_chance = 0.0
	u.mark_dirty()


func _x(star: int) -> float:
	for pa: AbilityDef in Fixture.catalog().get_unit("node_nurse").passives:
		if pa.id == "node_nurse_general_care":
			return float((pa.effect_config["stats_by_star"]["na_ally_heal_pct"]["flat"] as Dictionary)[str(star)])
	return 0.0


func _heals_from(b: Battle, src: BUnit, dst: BUnit = null) -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for e: Dictionary in Fixture.events_of(b, "heal"):
		if e["src"] == src and (dst == null or e["dst"] == dst):
			r.append(e)
	return r


func _damage_from(b: Battle, src: BUnit, dst: BUnit = null) -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for e: Dictionary in Fixture.events_of(b, "damage"):
		if e["src"] == src and (dst == null or e["dst"] == dst):
			r.append(e)
	return r


func test_targets_the_hurt_ally_with_the_lowest_current_health(t: TestCtx) -> void:
	# A：5 万 / 10 万(比例 50%)；B：4 万 / 10 万但离得更远 → B 的当前生命更低；满血的 C 不考虑
	var b := Fixture.make([{"def": "node_nurse", "pos": Vector2.ZERO}, {"def": "test_dummy", "pos": Vector2(1.5, 0)},
		{"def": "test_dummy", "pos": Vector2(-2.5, 0)}, {"def": "test_dummy", "pos": Vector2(0, 1.0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 3.0)}])
	var n: BUnit = b.units[0]
	b.start()
	b.units[1].hp = 50000.0
	b.units[2].hp = 40000.0
	_run_until(b, 2.0)
	t.eq(n.target, b.units[2], "the lowest current health (not ratio), even if farther")
	# 换目标发生在两次出手之间(前摇 + 后摇 ≈ 0.6 秒)
	b.units[2].hp = 100000.0
	_run_until(b, b.time + 1.0)
	t.eq(n.target, b.units[1], "switches as soon as that one is at full health")
	b.units[1].hp = 100000.0
	_run_until(b, b.time + 1.0)
	t.eq(n.target, b.units[4], "everyone at full health → attacks the enemy")
	t.ok(n.target.team != n.team, "an enemy")


func test_normal_attack_on_an_ally_heals_final_damage_times_x(t: TestCtx) -> void:
	for star: int in [1, 2, 3]:
		var b := Fixture.make([{"def": "node_nurse", "pos": Vector2.ZERO, "star": star}, {"def": "test_dummy", "pos": Vector2(0, 2.0)},
			{"def": "test_dummy", "team": 1, "pos": Vector2(0, 12)}])
		var n: BUnit = b.units[0]
		var ally: BUnit = b.units[1]
		_no_crit(n)
		b.start()
		ally.hp = 50000.0
		_run_until(b, 3.0)
		var hs: Array[Dictionary] = _heals_from(b, n, ally)
		t.ok(not hs.is_empty(), "%d★: the normal attack lands on the hurt ally" % star)
		if hs.is_empty():
			continue
		# 学徒魔典：普攻 = 攻击力 × 1.0 的魔法伤害，木桩 0 魔抗 → 最终伤害 = 攻击力
		t.near(float(hs[0]["amount"]), n.get_stats().attack_power * _x(star), 0.01, "%d★: heal = final damage × %d%%" % [star, int(_x(star) * 100)])
		t.eq(str(hs[0]["surface"]), "normal_attack", "a normal-attack heal")
		t.eq(_damage_from(b, n, ally).size(), 0, "the ally takes no damage")


func test_final_damage_counts_only_what_raises_damage(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_nurse", "pos": Vector2.ZERO}, {"def": "test_dummy", "pos": Vector2(0, 2.0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 12)}])
	var n: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	_no_crit(n)
	ally.base.magic_resistance = 50.0
	ally.mark_dirty()
	b.start()
	ally.hp = 50000.0
	b.pipeline.fx.apply_status(null, ally, {"status_id": "hardwork_test", "stats": {"na_damage_taken_flat": {"flat": 60.0}}})
	_run_until(b, 3.0)
	var hs: Array[Dictionary] = _heals_from(b, n, ally)
	t.ok(not hs.is_empty(), "healed")
	if not hs.is_empty():
		t.near(float(hs[0]["amount"]), n.get_stats().attack_power * _x(1), 0.01, "magic resistance and flat NA reduction ignored")
	# 提升伤害的照算：她的增伤 +20%、对方易伤 20%
	n.base.damage_dealt_pct = 0.2
	n.mark_dirty()
	b.pipeline.fx.apply_status(null, ally, {"status_id": "vuln_test", "stats": {"damage_taken_pct": {"flat": -0.2}}})
	var c0: int = hs.size()
	_run_until(b, b.time + 2.0)
	hs = _heals_from(b, n, ally)
	t.ok(hs.size() > c0, "healed again")
	if hs.size() > c0:
		t.near(float(hs[c0]["amount"]), n.get_stats().attack_power * 1.2 * 1.2 * _x(1), 0.01, "damage dealt +20% and vulnerability 20% both count")


func test_splash_heals_allies_and_still_damages_enemies(t: TestCtx) -> void:
	# 治疗打在 A 身上：溅射(1.2 米)里的队友 B 回 50%，敌人 E 照常受到 50% 的伤害
	var b := Fixture.make([{"def": "node_nurse", "pos": Vector2.ZERO}, {"def": "test_dummy", "pos": Vector2(0, 2.5)},
		{"def": "test_dummy", "pos": Vector2(0.8, 2.5)}, {"def": "test_dummy", "team": 1, "pos": Vector2(-0.8, 2.5)}])
	var n: BUnit = b.units[0]
	var a: BUnit = b.units[1]
	var ally2: BUnit = b.units[2]
	var foe: BUnit = b.units[3]
	_no_crit(n)
	b.start()
	a.hp = 40000.0
	ally2.hp = 60000.0
	_run_until(b, 3.0)
	var atk: float = n.get_stats().attack_power
	var ha: Array[Dictionary] = _heals_from(b, n, a)
	var hb: Array[Dictionary] = _heals_from(b, n, ally2)
	var de: Array[Dictionary] = _damage_from(b, n, foe)
	t.ok(not ha.is_empty() and not hb.is_empty() and not de.is_empty(), "direct heal + splash heal + splash damage")
	if ha.is_empty() or hb.is_empty() or de.is_empty():
		return
	t.near(float(ha[0]["amount"]), atk * _x(1), 0.01, "direct: × x")
	t.near(float(hb[0]["amount"]), atk * 0.5 * _x(1), 0.01, "splashed ally: 50% × x")
	t.ok(bool(hb[0]["splash"]), "marked as splash")
	t.near(float(de[0]["amount"]), atk * 0.5, 0.01, "splashed enemy: plain 50% damage, not converted")
	var sp: Array[Dictionary] = Fixture.events_of(b, "splash")
	t.ok(not sp.is_empty() and bool(sp[0]["heal_ally"]), "the view is told this splash is a heal")


func test_one_on_one_care_dispels_the_longest_debuffs_with_charges(t: TestCtx) -> void:
	for star: int in [1, 2, 3]:
		var b := Fixture.make([{"def": "node_nurse", "pos": Vector2.ZERO, "star": star}, {"def": "test_dummy", "pos": Vector2(0, 2.0)},
			{"def": "test_dummy", "team": 1, "pos": Vector2(0, 12)}])
		var n: BUnit = b.units[0]
		var ally: BUnit = b.units[1]
		b.start()
		ally.hp = 50000.0
		var t_apply: float = b.time
		for dur: float in [5.0, 9.0, 7.0, 12.0]:
			b.pipeline.fx.apply_status(null, ally, {"status_id": "burning", "independent": true, "duration": dur, "flags": ["debuff", "dispellable"]})
		b.pipeline.fx.apply_status(null, ally, {"status_id": "curse_test", "duration": 30.0, "flags": ["debuff"]})     # 不可驱散
		var hp0: float = ally.hp
		while ally.hp <= hp0 + 0.5 and b.time < 4.0:
			b.step()
		var durs: Array[float] = []                  # 还在的那几个原本的持续时间
		for st: BStatus in ally.status_instances("burning"):
			durs.append(snappedf(st.expires_at - t_apply, 0.01))
		durs.sort()
		var want: int = [0, 1, 3][star - 1]
		t.eq(durs.size(), 4 - want, "%d★: dispels %d on the first heal" % [star, want])
		if star == 2:
			t.eq(durs, [5.0, 7.0, 9.0] as Array[float], "2★: the 12 s one (longest remaining) is gone")
		if star == 3:
			t.eq(durs, [5.0] as Array[float], "3★: only the shortest is left")
		t.eq(ally.status_count("curse_test"), 1, "%d★: non-dispellable debuff untouched" % star)


func test_one_on_one_care_spends_charges_only_on_debuffed_allies(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_nurse", "pos": Vector2.ZERO, "star": 2}, {"def": "test_dummy", "pos": Vector2(0, 2.0)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 12)}])
	var n: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	b.start()
	ally.hp = 50000.0
	_run_until(b, 4.0)
	t.ok(not _heals_from(b, n, ally).is_empty(), "heals happened")
	t.eq(Fixture.events_of(b, "dispel").size(), 0, "no debuff → doesn't trigger")
	t.eq(int(n.ability_charges.get("node_nurse_one_on_one", 2)), 2, "and spends no charge")
	# 一口气挂很多个：充能 2 → 连着两次治疗各驱散 1 个，然后要等冷却
	for i in range(8):
		b.pipeline.fx.apply_status(null, ally, {"status_id": "burning", "independent": true, "duration": 20.0, "flags": ["debuff", "dispellable"]})
	var t0: float = b.time
	_run_until(b, t0 + 2.4)
	t.eq(ally.status_count("burning"), 6, "two charges → two dispels in quick succession")
	_run_until(b, t0 + 4.5)
	t.eq(ally.status_count("burning"), 6, "out of charges: nothing more for a while")
	_run_until(b, t0 + 7.5)
	t.eq(ally.status_count("burning"), 5, "then one more after the 5 s cooldown")


func test_potion_refill_every_third_attack_fires_the_heart_syringe(t: TestCtx) -> void:
	# 敌人 0 防木桩：每第 3 次普攻，爱心针剂对普攻对象造成 攻击力 × y × 1 的物理伤害(溅射 1.5 = 1.8 米)
	var b := Fixture.make([{"def": "node_nurse", "pos": Vector2.ZERO, "weapon": "heart_syringe"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 3.0)}])
	var n: BUnit = b.units[0]
	var foe: BUnit = b.units[1]
	_no_crit(n)
	b.start()
	var y := 0.0
	for tr: TriggerDef in n.def.triggers:
		if tr.id == "node_nurse_potion_fill":
			y = tr.ratio_for(1)
	_run_until(b, 6.0)
	var na: Array[Dictionary] = []
	var dose: Array[Dictionary] = []
	for e: Dictionary in _damage_from(b, n, foe):
		if str(e["surface"]) == "normal_attack":
			na.append(e)
		elif str(e["ability"]) == "heart_syringe_dose":
			dose.append(e)
	t.ok(na.size() >= 3, "several normal attacks")
	t.eq(dose.size(), na.size() / 3, "the syringe fires on every 3rd attack")
	if not dose.is_empty():
		t.near(float(dose[0]["amount"]), n.get_stats().attack_power * y, 0.01, "physical damage = attack × y × 1")
		t.eq(str(dose[0]["kind"]), "physical", "physical")
	var st: StatBlock = n.get_stats()
	t.near(st.attack_power, 70.0 + 15.0, 0.01, "+15 attack")
	t.near(st.attack_speed_multiplier, 1.15, 0.0001, "+15% attack speed")
	var sp: Array[Dictionary] = Fixture.events_of(b, "splash")
	var heart := false
	for e2: Dictionary in sp:
		if str(e2.get("style", "")) == "heart":
			heart = true
			t.near(float(e2["radius"]), 1.5 * GC.SPLASH_M_PER_POINT, 0.0001, "【溅射 1.5】= 1.8 m")
	t.ok(heart, "heart-shaped splash")
	var projs: Array[Dictionary] = Fixture.events_of(b, "projectile")
	t.ok(not projs.is_empty() and str((projs[0]["proj"] as Dictionary)["kind"]) == "syringe_dart", "normal attacks fly as syringe darts")


func test_heart_syringe_dose_on_an_ally_is_converted_and_counts_as_na_damage(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_nurse", "pos": Vector2.ZERO, "weapon": "heart_syringe"}, {"def": "test_dummy", "pos": Vector2(0, 2.5)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(1.2, 2.5)}])
	var n: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	_no_crit(n)
	b.start()
	ally.hp = 30000.0
	b.pipeline.fx.apply_status(null, foe, {"status_id": "hardwork_test", "stats": {"na_damage_taken_flat": {"flat": 20.0}}})
	var y := 0.0
	for tr: TriggerDef in n.def.triggers:
		if tr.id == "node_nurse_potion_fill":
			y = tr.ratio_for(1)
	_run_until(b, 6.0)
	var atk: float = n.get_stats().attack_power
	var dose_h: Array[Dictionary] = []
	for e: Dictionary in _heals_from(b, n, ally):
		if str(e["ability"]) == "heart_syringe_dose":
			dose_h.append(e)
	t.ok(not dose_h.is_empty(), "the dose on the ally heals")
	if not dose_h.is_empty():
		t.near(float(dose_h[0]["amount"]), atk * y * _x(1), 0.01, "heal = attack × y × 1 × x")
	var dose_d: Array[Dictionary] = []
	for e2: Dictionary in _damage_from(b, n, foe):
		if str(e2["ability"]) == "heart_syringe_dose":
			dose_d.append(e2)
	t.ok(not dose_d.is_empty(), "the enemy in the 1.8 m splash takes damage")
	if not dose_d.is_empty():
		t.near(float(dose_d[0]["amount"]), atk * y * 0.5 - 20.0, 0.01, "50% splash, minus the flat normal-attack reduction (counts as NA damage)")


func test_fractional_keyword_value_and_unit_data(t: TestCtx) -> void:
	var e: EquipmentDef = Fixture.catalog().get_equipment("heart_syringe")
	t.eq(e.class_id, "focus", "focus")
	t.eq(e.color_id, "red", "red")
	t.eq(e.cost, 2, "rarity 2")
	t.eq(e.owner, "node_nurse", "hers")
	t.near(e.abilities[0].keyword_value_f("splash", 1, 0.0), 1.5, 0.0001, "【溅射 1.5】")
	t.near(e.abilities[0].cooldown, 1.5, 0.0001, "1.5 s cooldown")
	t.ok(e.abilities[0].has_keyword("crit"), "【暴击】")
	t.ok(Describe.keyword_tags(e.abilities[0]).contains("1.5"), "the card shows 1.5")
	var d: UnitDef = Fixture.catalog().get_unit("node_nurse")
	t.eq(d.cost, 3, "rarity 3")
	t.eq(d.faction_id, "red", "red")
	t.eq(d.profession_id, "welfare", "Welfare Department")
	t.eq(d.weapon_classes, ["focus", "crossbow", "pistols", "rifle", "bow"] as Array[String], "focus default; one-handed / dual / two-handed / drawn ranged allowed")
	t.near(d.base_stats.attack_power, 70.0, 0.01, "caster template (3)")
	t.near(d.base_stats.max_health, 950.0, 0.01, "caster template (3)")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")
