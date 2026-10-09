extends RefCounted
## 通用武器 gen6：步枪 4 把(红·3 输血步枪 / 黄·3 乘势连发枪 / 青·4 回潮步枪 / 紫·2 咒纹步枪) + 弓 2 把(青·2 逐风短弓 / 黄·4 金乌长弓)。
## 效果测试用"探针触发器"(目标 = 事件目标、固定触发数值)直接扣动载荷；回潮步枪的复活用真的真望节点(勇气：自己阵亡时)。

## 每把武器的格子(费用 / 颜色 / 大类)、外观、投射物("" = 这个大类默认的子弹 / 箭)、合手的棋子
const SPEC := {
	"transfusion_rifle": {"cost": 3, "color": "red", "cls": "rifle", "model": "g6_transfusion", "proj": "", "fits": ["node_archer", "node_nurse"]},
	"momentum_repeater": {"cost": 3, "color": "yellow", "cls": "rifle", "model": "g6_momentum", "proj": "",
		"fits": ["node_archer", "node_commando", "node_sniper"]},
	"returning_tide": {"cost": 4, "color": "cyan", "cls": "rifle", "model": "g6_tide", "proj": "g6_tide_drop", "fits": ["node_taoist", "node_leader"]},
	"hexline_rifle": {"cost": 2, "color": "purple", "cls": "rifle", "model": "g6_hexline", "proj": "", "fits": ["node_archer", "node_nurse", "node_tinker"]},
	"windchaser_bow": {"cost": 2, "color": "cyan", "cls": "bow", "model": "g6_windchaser", "proj": "", "fits": ["node_hunter", "node_leader"]},
	"goldcrow_longbow": {"cost": 4, "color": "yellow", "cls": "bow", "model": "g6_goldcrow", "proj": "g6_sun_arrow",
		"fits": ["node_bard", "node_hunter", "node_sniper"]},
}


func _probe(v: float, timing: String = "OnBattleFrame") -> TriggerDef:
	return TriggerDef.from_dict({"id": "g6_probe", "timing": timing, "tags": ["battle_frame", "equipment_payload"],
		"target_rule": "event_target", "team_filter": "any", "base_value_mode": "fixed", "base_value_flat": v})


## 用探针触发器扣一次(先清掉冷却)；返回这一次的事件
func _pull(b: Battle, u: BUnit, target: BUnit, v: float) -> Array[Dictionary]:
	u.ability_cd.clear()
	u.trig_cd.clear()
	b.poll_events()
	var ev: Dictionary = b.pipeline.make_event("OnBattleFrame", u, target, 0.0, ["battle_frame"], {})
	b.pipeline._fire(ev, _probe(v), u)
	b.pipeline.drain()
	return b.poll_events()


## 携带者 + 一个队友 + 一个敌人(都是零抗性的木桩，攻击打不出来)
func _setup(weapon: String) -> Battle:
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2(0, -3), "weapon": weapon}, {"def": "test_dummy", "pos": Vector2(2, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}])
	b.start()
	for u: BUnit in b.units:
		u.attack_cd = 1.0e9
		u.base.crit_chance = 0.0
		u.mark_dirty()
	return b


func _eq(id: String) -> EquipmentDef:
	return Fixture.catalog().get_equipment(id)


static func _sum(evs: Array[Dictionary], type: String, dst: BUnit, kind: String = "") -> float:
	var s := 0.0
	for e: Dictionary in evs:
		if e.get("t") == type and e.get("dst") == dst and (kind == "" or str(e.get("kind", "")) == kind):
			s += float(e.get("amount", 0.0))
	return s


func _step_for(b: Battle, sec: float) -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	var until: float = b.time + sec
	while b.time < until and b.state != "ended":
		b.step()
		all.append_array(b.poll_events())
	return all


## 状态配置里的属性(双模分支)
func _branch(id: String, ability: int, side: String) -> Dictionary:
	return _eq(id).abilities[ability].effect_config[side]


# ================================================================ 数据
func test_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var pool: Array[String] = cat.equipment_ids()
	var models := {}
	for id: String in SPEC.keys():
		var e: EquipmentDef = cat.get_equipment(id)
		var sp: Dictionary = SPEC[id]
		t.ok(e != null, "%s exists" % id)
		if e == null:
			continue
		t.ok(e.owner == "" and e.reworked and not e.no_drop and pool.has(id), "%s: no owner, reworked, in the random pool" % id)
		t.eq([e.cost, e.color_id, e.class_id], [sp["cost"], sp["color"], sp["cls"]], "%s sits in its grid cell" % id)
		t.eq(e.model, str(sp["model"]), "%s has its own look" % id)
		models[e.model] = true
		t.eq(e.projectile, str(sp["proj"]), "%s projectile" % id)
		if e.projectile != "":
			t.ok(ProjRegistry.has(e.projectile), "%s: projectile %s is registered (game/view/proj_kinds/gen6.gd)" % [id, e.projectile])
		for a: AbilityDef in e.abilities:
			t.ok(a.required_trigger_tags.has("equipment_payload"), "%s/%s pairs with weapon triggers" % [id, a.id])
	t.eq(models.size(), SPEC.size(), "six different looks")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


## 每把适配 ≥ 2 只(内置标签)，包含设计时定的合手棋子；合手的 ★1~3 都装得上
func test_fits(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	for id: String in SPEC.keys():
		var fits: Array[String] = cat.fit_units(id)
		t.ok(fits.size() >= 2, "%s fits %d pieces (%s)" % [id, fits.size(), ", ".join(fits)])
		for uid: String in SPEC[id]["fits"]:
			t.ok(fits.has(uid), "%s fits %s" % [id, uid])
			for star: int in [1, 2, 3]:
				t.eq(_eq(id).equip_problem(cat.get_unit(uid), star), "", "%s: %s ★%d can equip it" % [id, uid, star])


## 描述里的数值和数据一致
func test_text_numbers(t: TestCtx) -> void:
	var nums := {
		"transfusion_rifle": [_branch("transfusion_rifle", 0, "enemy_effect")["cfg"]["dot"]["amount"],
			_branch("transfusion_rifle", 0, "ally_effect")["cfg"]["stats"]["healing_received_pct"]["flat"] * 100.0,
			_branch("transfusion_rifle", 0, "ally_effect")["cfg"]["duration"], _eq("transfusion_rifle").flat_mods["attack_power"]],
		"momentum_repeater": [_eq("momentum_repeater").abilities[0].fixed_value, _eq("momentum_repeater").abilities[1].value_multiplier * 100.0,
			_eq("momentum_repeater").abilities[0].effect_config["extra_effects"][0]["stats"]["attack_power"]["pct"] * 100.0],
		"returning_tide": [_eq("returning_tide").abilities[0].fixed_value, _eq("returning_tide").abilities[1].fixed_value,
			_eq("returning_tide").abilities[0].cooldown],
		"hexline_rifle": [_eq("hexline_rifle").abilities[0].fixed_value, _eq("hexline_rifle").abilities[1].fixed_value,
			_branch("hexline_rifle", 0, "ally_effect")["cfg"]["stats"]["na_bonus_magic_pct"]["flat"] * 100.0, _eq("hexline_rifle").flat_mods["ability_power"]],
		"windchaser_bow": [_branch("windchaser_bow", 0, "ally_effect")["cfg"]["stats"]["attack_speed_multiplier"]["flat"] * 100.0,
			_branch("windchaser_bow", 0, "enemy_effect")["cfg"]["stats"]["move_speed"]["pct"] * -100.0,
			_eq("windchaser_bow").abilities[1].value_multiplier * 100.0],
		"goldcrow_longbow": [_branch("goldcrow_longbow", 0, "enemy_effect")["value_multiplier"] * 100.0,
			_branch("goldcrow_longbow", 0, "ally_effect")["value_multiplier"] * 100.0,
			_eq("goldcrow_longbow").abilities[0].effect_config["learning"]["bonus_per_learning"] * 100.0,
			_eq("goldcrow_longbow").abilities[0].effect_config["learning"]["cap"]],
	}
	for id: String in nums.keys():
		for lang: String in ["zh", "en"]:
			var desc: String = Loc.t_in(lang, "equipment.%s.desc" % id)
			for n: Variant in nums[id]:
				var s: String = str(int(round(float(n))))
				t.ok(desc.contains(s), "%s (%s): the text says %s" % [id, lang, s])


# ================================================================ 输血步枪
func test_transfusion_rifle(t: TestCtx) -> void:
	var b := _setup("transfusion_rifle")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var acfg: Dictionary = _branch("transfusion_rifle", 0, "ally_effect")["cfg"]
	var atk0: float = ally.get_stats().attack_power
	var hr0: float = ally.get_stats().healing_received_pct
	var evs: Array[Dictionary] = _pull(b, u, ally, 1.0)
	t.ok(ally.get_status("g6_transfused") != null, "an ally gets Transfused (the trigger value doesn't matter)")
	t.near(ally.get_stats().healing_received_pct - hr0, float(acfg["stats"]["healing_received_pct"]["flat"]), 0.001, "+healing received")
	t.near(ally.get_stats().attack_power, atk0 * (1.0 + float(acfg["stats"]["attack_power"]["pct"])), 0.5, "+attack")
	t.eq(_sum(evs, "damage", ally), 0.0, "and isn't hurt")
	t.eq(ally.status_count("g6_bloodlet"), 0, "no bleeding on allies")
	_pull(b, u, foe, 1.0)
	_pull(b, u, foe, 1.0)
	t.eq(foe.status_count("g6_bloodlet"), 2, "an enemy bleeds: each shot is its own Bloodletting")
	t.ok(foe.get_status("g6_transfused") == null, "and gets no buff")
	var dps: float = float(_branch("transfusion_rifle", 0, "enemy_effect")["cfg"]["dot"]["amount"])
	var ticks: Array[Dictionary] = _step_for(b, 2.05)
	t.near(_sum(ticks, "damage", foe, "physical"), dps * 2.0 * 2.0, 1.0, "two bleeds × %.0f physical a second" % dps)


# ================================================================ 乘势连发枪
func test_momentum_repeater(t: TestCtx) -> void:
	var b := _setup("momentum_repeater")
	var u: BUnit = b.units[0]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("momentum_repeater")
	var d: float = e.abilities[0].fixed_value
	var r: float = e.abilities[1].value_multiplier
	var per: float = float(e.abilities[0].effect_config["extra_effects"][0]["stats"]["attack_power"]["pct"])
	var atk0: float = u.get_stats().attack_power
	var evs: Array[Dictionary] = _pull(b, u, foe, 0.0)
	t.near(_sum(evs, "damage", foe, "physical"), d, 0.5, "fixed %.0f physical, whatever the trigger value" % d)
	t.eq(u.status_stacks("g6_momentum"), 1, "the holder gains a stack of Momentum")
	for i in range(6):
		_pull(b, u, foe, 0.0)
	t.eq(u.status_stacks("g6_momentum"), 5, "up to 5 stacks")
	t.near(u.get_stats().attack_power, atk0 * (1.0 + 5.0 * per), 0.5, "+%.0f%% attack a stack" % (per * 100.0))
	var dv: float = _sum(_pull(b, u, foe, 1000.0), "damage", foe, "physical")
	t.near(dv, d + 1000.0 * r, 1.0, "second part: trigger value × %.0f%% physical" % (r * 100.0))
	var ally: BUnit = b.units[1]
	t.eq(ally.status_stacks("g6_momentum"), 0, "Momentum is only the holder's")


# ================================================================ 回潮步枪
func test_returning_tide_heals_and_hits(t: TestCtx) -> void:
	var b := _setup("returning_tide")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var v: float = _eq("returning_tide").abilities[0].fixed_value
	ally.hp = 1000.0
	var evs: Array[Dictionary] = _pull(b, u, ally, 1.0)
	t.near(_sum(evs, "heal", ally), v * (1.0 + u.get_stats().healing_done_pct), 1.0, "an ally heals %.0f, whatever the trigger value" % v)
	t.eq(_sum(evs, "damage", ally), 0.0, "and isn't hurt")
	evs = _pull(b, u, foe, 1.0)
	t.near(_sum(evs, "damage", foe, "magic"), v, 1.0, "an enemy takes %.0f magic damage" % v)
	t.eq(_sum(evs, "heal", foe), 0.0, "and isn't healed")
	# 冷却：不清冷却再扣一次 = 没反应
	b.poll_events()
	var ev: Dictionary = b.pipeline.make_event("OnBattleFrame", u, foe, 0.0, ["battle_frame"], {})
	b.pipeline._fire(ev, _probe(1.0), u)
	b.pipeline.drain()
	t.eq(_sum(b.poll_events(), "damage", foe), 0.0, "%.0f s cooldown" % _eq("returning_tide").abilities[0].cooldown)


func _kill(b: Battle, u: BUnit) -> void:
	u.hp = 0.0
	b.pipeline.fx.try_kill(u, null)
	b.pipeline.drain()


## 真望节点(勇气：自己阵亡时触发，目标 = 自己)：第一次倒下以 400 生命原地复活，第二次不再复活(每场限一次)
func test_returning_tide_revives_leader_once(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_leader", "pos": Vector2(0, -4), "star": 2, "weapon": "returning_tide"},
		{"def": "test_dummy", "pos": Vector2(2, -4)}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 8)}])
	b.start()
	var ld: BUnit = b.units[0]
	t.eq(ld.weapon.id if ld.weapon != null else "", "returning_tide", "she carries the Returning Tide")
	var rv: float = _eq("returning_tide").abilities[1].fixed_value
	_kill(b, ld)
	var evs: Array[Dictionary] = _step_for(b, 0.2)
	t.ok(ld.alive, "Courage (her own fall) → she gets back up")
	t.near(ld.hp, ld.get_stats().calc_heal(ld.get_stats(), rv), 2.0, "with %.0f health (+ healing bonuses)" % rv)
	var revs: int = evs.filter(func(e: Dictionary) -> bool: return e.get("t") == "revive").size()
	t.eq(revs, 1, "one revive")
	_step_for(b, 5.0)
	_kill(b, ld)
	_step_for(b, 0.5)
	t.ok(not ld.alive, "once per battle: the second fall sticks")


## 别的时机(不是"有人阵亡")扣到第二段：什么都不做——只有阵亡的触发器才复活人
func test_returning_tide_rebirth_is_limited(t: TestCtx) -> void:
	var b := _setup("returning_tide")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	_kill(b, ally)
	t.ok(not ally.alive, "the ally is down")
	_pull(b, u, ally, 1.0)
	_step_for(b, 0.1)
	t.ok(not ally.alive, "a non-death trigger doesn't revive anyone")


# ================================================================ 咒纹步枪
func test_hexline_rifle(t: TestCtx) -> void:
	var b := _setup("hexline_rifle")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("hexline_rifle")
	var d: float = e.abilities[0].fixed_value
	var evs: Array[Dictionary] = _pull(b, u, foe, 1.0)
	t.near(_sum(evs, "damage", foe, "magic"), d, 0.5, "an enemy takes %.0f magic, whatever the trigger value" % d)
	t.ok(foe.get_status("g6_hexline") == null, "and gets no buff")
	var st: Dictionary = _branch("hexline_rifle", 0, "ally_effect")["cfg"]["stats"]
	var ap0: float = ally.get_stats().ability_power
	evs = _pull(b, u, ally, 1.0)
	t.ok(ally.get_status("g6_hexline") != null, "an ally gets Hexline")
	t.eq(_sum(evs, "damage", ally), 0.0, "and isn't hurt")
	t.near(ally.get_stats().na_bonus_magic_pct, float(st["na_bonus_magic_pct"]["flat"]), 0.001, "normal attacks carry extra magic damage")
	t.near(ally.get_stats().ability_power - ap0, float(st["ability_power"]["flat"]), 0.01, "+ability power")
	var sh: float = e.abilities[1].fixed_value
	t.near(ally.shield, sh, 1.0, "and a %.0f-point shield" % sh)
	t.eq(foe.shield, 0.0, "enemies get no shield")


# ================================================================ 逐风短弓
func test_windchaser_bow(t: TestCtx) -> void:
	var b := _setup("windchaser_bow")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var r: float = _eq("windchaser_bow").abilities[1].value_multiplier
	var buff: Dictionary = _branch("windchaser_bow", 0, "ally_effect")["cfg"]["stats"]
	var as0: float = ally.get_stats().attack_speed_multiplier
	ally.hp = 1000.0
	var evs: Array[Dictionary] = _pull(b, u, ally, 200.0)
	t.ok(ally.get_status("g6_tailwind") != null, "an ally gets Tailwind")
	t.near(ally.get_stats().attack_speed_multiplier - as0, float(buff["attack_speed_multiplier"]["flat"]), 0.001, "+attack speed")
	t.ok(_sum(evs, "heal", ally) > 200.0 * r * 0.99, "and heals trigger value × %.0f%%" % (r * 100.0))
	t.eq(_sum(evs, "damage", ally), 0.0, "and isn't hurt")
	var fas0: float = foe.get_stats().attack_speed_multiplier
	var fms0: float = foe.get_stats().move_speed
	evs = _pull(b, u, foe, 200.0)
	t.ok(foe.get_status("g6_headwind") != null, "an enemy gets Headwind")
	t.ok(foe.get_stats().attack_speed_multiplier < fas0 - 0.1, "slower attacks")
	t.ok(foe.get_stats().move_speed < fms0 or fms0 <= 0.0, "slower steps")
	t.near(_sum(evs, "damage", foe, "physical"), 200.0 * r, 1.0, "and takes trigger value × %.0f%% physical" % (r * 100.0))


# ================================================================ 金乌长弓
func test_goldcrow_longbow(t: TestCtx) -> void:
	var b := _setup("goldcrow_longbow")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var dr: float = float(_branch("goldcrow_longbow", 0, "enemy_effect")["value_multiplier"])
	var hr: float = float(_branch("goldcrow_longbow", 0, "ally_effect")["value_multiplier"])
	var lc: Dictionary = _eq("goldcrow_longbow").abilities[0].effect_config["learning"]
	var per: float = float(lc["bonus_per_learning"])
	var d1: float = _sum(_pull(b, u, foe, 200.0), "damage", foe, "physical")
	t.near(d1, 200.0 * dr, 1.0, "an enemy takes trigger value × %.0f%% physical" % (dr * 100.0))
	for i in range(4):
		_pull(b, u, foe, 200.0)
	var d6: float = _sum(_pull(b, u, foe, 200.0), "damage", foe, "physical")
	t.near(d6 / d1, 1.0 + 5.0 * per, 0.01, "after 5 uses it hits %.0f%% harder (learning)" % (5.0 * per * 100.0))
	for i in range(30):
		_pull(b, u, foe, 200.0)
	var dc: float = _sum(_pull(b, u, foe, 200.0), "damage", foe, "physical")
	t.near(dc / d1, 1.0 + float(lc["cap"]) * per, 0.01, "capped at %d learns" % int(lc["cap"]))
	ally.hp = 1000.0
	var evs: Array[Dictionary] = _pull(b, u, ally, 200.0)
	t.near(_sum(evs, "heal", ally), 200.0 * hr * (1.0 + float(lc["cap"]) * per) * (1.0 + u.get_stats().healing_done_pct), 2.0,
		"an ally heals trigger value × %.0f%% (learned too)" % (hr * 100.0))
	t.eq(_sum(evs, "damage", ally), 0.0, "and isn't hurt")
