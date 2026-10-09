extends RefCounted
## 通用武器 · gen11(步枪 3 把 + 手弩 3 把)：数据(格子 / 随机池 / 外观 / 投射物)、适配角色、每把的效果(探针触发器直接扣载荷，抄 test_generic_weapons.gd)；
## 蓝墨钢笔枪另外用真的求知节点测"学习计数 → 永久法强"。

## 分给 gen11 的格子：id -> [费用, 颜色, 大类]
const GRID := {
	"g11_inkwell_rifle": [2, "blue", "rifle"], "g11_parasol_rifle": [2, "cyan", "rifle"], "g11_vermilion_rifle": [4, "red", "rifle"],
	"g11_pearl_crossbow": [4, "cyan", "crossbow"], "g11_chili_crossbow": [2, "red", "crossbow"], "g11_dandelion_crossbow": [2, "green", "crossbow"],
}
## 合手的棋子(测强度定下的；FitTags 也要算出来)。步枪·蓝是单人格(只有求知能装)
const CARRIERS := {
	"g11_inkwell_rifle": ["node_student"], "g11_parasol_rifle": ["node_taoist", "node_student", "node_leader"],
	"g11_vermilion_rifle": ["node_archer", "node_nurse"], "g11_pearl_crossbow": ["node_cowboy", "node_taoist", "node_leader", "node_angel"],
	"g11_chili_crossbow": ["node_archer", "node_nurse"], "g11_dandelion_crossbow": ["node_cowboy", "node_taoist"],
}
## 单人格：只要求这一只合手
const SINGLE := ["g11_inkwell_rifle"]
## 自己的投射物(game/view/proj_kinds/gen11.gd)；"" = 这个大类默认的子弹
const OWN_PROJ := {
	"g11_inkwell_rifle": "g11_ink_drop", "g11_parasol_rifle": "", "g11_vermilion_rifle": "g11_flame_feather",
	"g11_pearl_crossbow": "g11_pearl", "g11_chili_crossbow": "g11_chili", "g11_dandelion_crossbow": "g11_dandelion",
}
const Models = preload("res://tools/weapons/gen11_models.gd")


func _probe(v: float) -> TriggerDef:
	return TriggerDef.from_dict({"id": "probe_trigger", "timing": "OnBattleFrame", "tags": ["battle_frame", "equipment_payload"],
		"target_rule": "event_target", "team_filter": "any", "base_value_mode": "fixed", "base_value_flat": v})


## 用探针触发器扣一次(先清掉冷却)；返回这一次的事件
func _pull(b: Battle, u: BUnit, target: BUnit, v: float) -> Array[Dictionary]:
	u.ability_cd.clear()
	u.trig_cd.clear()
	return _pull_noclear(b, u, target, v)


## 不清冷却地扣一次(【基本】没有冷却：连扣都生效)
func _pull_noclear(b: Battle, u: BUnit, target: BUnit, v: float) -> Array[Dictionary]:
	b.poll_events()
	var ev: Dictionary = b.pipeline.make_event("OnBattleFrame", u, target, 0.0, ["battle_frame"], {})
	b.pipeline._fire(ev, _probe(v), u)
	b.pipeline.drain()
	return b.poll_events()


## 携带者(打手) + 一个队友木桩 + 一个敌人木桩(+ extra)
func _setup(weapon: String, extra: Array = []) -> Battle:
	var specs: Array = [{"def": "test_hitter", "pos": Vector2(0, -3), "weapon": weapon}, {"def": "test_dummy", "pos": Vector2(2, -3)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}]
	specs.append_array(extra)
	var b := Fixture.make(specs)
	b.start()
	for u: BUnit in b.units:
		u.attack_cd = 1.0e9
		u.base.crit_chance = 0.0
		u.mark_dirty()
	return b


## 溅射用的站位：队友身边 1 米另一个队友、一个敌人；敌人身边 1 米另一个敌人
func _setup_splash(weapon: String) -> Battle:
	return _setup(weapon, [{"def": "test_dummy", "pos": Vector2(3, -3)}, {"def": "test_dummy", "team": 1, "pos": Vector2(2, -2)},
		{"def": "test_dummy", "team": 1, "pos": Vector2(1, 3)}])


func _eq(id: String) -> EquipmentDef:
	return Fixture.catalog().get_equipment(id)


func _branch(id: String, ability: int, side: String) -> Dictionary:
	return _eq(id).abilities[ability].effect_config[side]


static func _sum(evs: Array[Dictionary], type: String, dst: BUnit, kind: String = "") -> float:
	var s := 0.0
	for e: Dictionary in evs:
		if e.get("t") == type and e.get("dst") == dst and (kind == "" or str(e.get("kind", "")) == kind):
			s += float(e.get("amount", 0.0))
	return s


func _step_seconds(b: Battle, s: float) -> void:
	for i in range(int(round(s / GC.SIM_DT))):
		b.step()


# ================================================================ 数据
func test_data(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var pool: Array[String] = cat.equipment_ids()
	var looks := {}
	for id: String in GRID.keys():
		var e: EquipmentDef = cat.get_equipment(id)
		t.ok(e != null, "%s exists" % id)
		if e == null:
			continue
		var gcell: Array = GRID[id]
		t.ok(e.owner == "" and e.reworked and not e.no_drop and pool.has(id), "%s: no owner, reworked, in the random pool" % id)
		t.eq([e.cost, e.color_id, e.class_id], [int(gcell[0]), str(gcell[1]), str(gcell[2])], "%s sits in its grid cell (cost / color / class)" % id)
		t.ok(e.model.begins_with("g11_") and Models.PARTS.has("W_%s_%s" % [e.class_id, e.model]), "%s has its own model W_%s_%s" % [id, e.class_id, e.model])
		looks[e.model] = true
		t.eq(e.projectile, str(OWN_PROJ[id]), "%s projectile" % id)
		if e.projectile != "":
			t.ok(ProjRegistry.has(e.projectile), "%s: projectile %s is registered (game/view/proj_kinds/gen11.gd)" % [id, e.projectile])
		for a: AbilityDef in e.abilities:
			t.ok(a.required_trigger_tags.has("equipment_payload"), "%s: %s is an equipment payload" % [id, a.id])
	t.eq(looks.size(), GRID.size(), "every weapon has a different look")
	t.eq(Catalog.load_all().validate_all(), [] as Array[String], "catalog validates")


## 每把适配 ≥ 2 只(单人格 = 那一只)，包含设计时定的合手棋子；合手的 ★1~3 都装得上
func test_fit_units(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	for id: String in CARRIERS.keys():
		var fit: Array[String] = cat.fit_units(id)
		t.ok(fit.size() >= (1 if SINGLE.has(id) else 2), "%s fits %d units (%s)" % [id, fit.size(), ",".join(fit)])
		for uid: String in CARRIERS[id]:
			t.ok(fit.has(uid), "%s fits %s" % [id, uid])
			for star: int in [1, 2, 3]:
				t.eq(_eq(id).equip_problem(cat.get_unit(uid), star), "", "%s: %s ★%d can equip it" % [id, uid, star])


## 描述里的数值和数据一致
func test_text_numbers(t: TestCtx) -> void:
	var ink: EquipmentDef = _eq("g11_inkwell_rifle")
	var umb: EquipmentDef = _eq("g11_parasol_rifle")
	var verm: EquipmentDef = _eq("g11_vermilion_rifle")
	var pearl: EquipmentDef = _eq("g11_pearl_crossbow")
	var chili: EquipmentDef = _eq("g11_chili_crossbow")
	var dand: EquipmentDef = _eq("g11_dandelion_crossbow")
	var nums := {
		"g11_inkwell_rifle": [ink.abilities[0].value_multiplier * 100.0, float(ink.abilities[0].effect_config["learning"]["bonus_per_learning"]) * 100.0,
			ink.abilities[0].effect_config["learning"]["cap"], float(ink.abilities[0].effect_config["extra_effects"][0]["stats"]["haste"]["flat"]) * 100.0,
			ink.flat_mods["ability_power"], ink.flat_mods["max_health"]],
		"g11_parasol_rifle": [float(umb.abilities[0].effect_config["stats"]["damage_taken_pct"]["flat"]) * 100.0, umb.abilities[0].effect_config["duration"],
			umb.abilities[1].fixed_value, float(umb.abilities[2].effect_config["stats"]["attack_speed_multiplier"]["flat"]) * -100.0,
			float(_branch("g11_parasol_rifle", 3, "enemy_effect")["value_multiplier"]) * 100.0, umb.abilities[3].cooldown, umb.flat_mods["max_health"]],
		"g11_vermilion_rifle": [verm.abilities[0].fixed_value, verm.abilities[1].fixed_value, _branch("g11_vermilion_rifle", 2, "ally_effect")["cfg"]["duration"],
			float(_branch("g11_vermilion_rifle", 2, "ally_effect")["cfg"]["stats"]["healing_received_pct"]["flat"]) * 100.0,
			verm.flat_mods["attack_power"], verm.flat_mods["max_health"]],
		"g11_pearl_crossbow": [pearl.abilities[0].fixed_value, pearl.abilities[1].effect_config["stats"]["na_damage_taken_flat"]["flat"],
			float(pearl.abilities[2].effect_config["stats"]["attack_speed_multiplier"]["flat"]) * -100.0, pearl.flat_mods["max_health"]],
		"g11_chili_crossbow": [float(_branch("g11_chili_crossbow", 0, "ally_effect")["cfg"]["stats"]["attack_power"]["pct"]) * 100.0,
			_branch("g11_chili_crossbow", 0, "ally_effect")["cfg"]["duration"], chili.flat_mods["attack_power"], chili.flat_mods["max_health"]],
		"g11_dandelion_crossbow": [float(_branch("g11_dandelion_crossbow", 0, "ally_effect")["cfg"]["stats"]["na_dodge"]["flat"]) * 100.0,
			float(_branch("g11_dandelion_crossbow", 0, "enemy_effect")["cfg"]["stats"]["attack_power"]["pct"]) * -100.0,
			dand.abilities[1].fixed_value, dand.flat_mods["max_health"]],
	}
	for id: String in nums.keys():
		for lang: String in ["zh", "en"]:
			var desc: String = Loc.t_in(lang, "equipment.%s.desc" % id)
			for n: Variant in nums[id]:
				var s: String = str(int(round(float(n))))
				t.ok(desc.contains(s), "%s (%s): the text says %s" % [id, lang, s])
	var choke: float = float(chili.abilities[1].effect_config["duration"])
	t.ok(Loc.t_in("zh", "equipment.g11_chili_crossbow.desc").contains(str(snappedf(choke, 0.01))), "chili: choke seconds in the text")


# ================================================================ 蓝墨钢笔枪
func test_inkwell_rifle(t: TestCtx) -> void:
	var b := _setup("g11_inkwell_rifle")
	var u: BUnit = b.units[0]
	var foe: BUnit = b.units[2]
	var a: AbilityDef = _eq("g11_inkwell_rifle").abilities[0]
	var lc: Dictionary = a.effect_config["learning"]
	var per: float = float(lc["bonus_per_learning"])
	var cap: int = int(lc["cap"])
	var haste: float = float(a.effect_config["extra_effects"][0]["stats"]["haste"]["flat"])
	var h0: float = u.get_stats().haste
	var d1: float = _sum(_pull(b, u, foe, 200.0), "damage", foe, "magic")
	t.near(d1, 200.0 * a.value_multiplier, 1.0, "trigger value × %.0f%% magic" % (a.value_multiplier * 100.0))
	t.eq(int(u.learning.get(a.id, 0)), 1, "【学习】: one learning count per activation")
	t.eq(u.status_stacks("g11_ink_focus"), 1, "the holder gains 1 Ink Focus")
	t.near(u.get_stats().haste - h0, haste, 0.0001, "+%.0f%% haste" % (haste * 100.0))
	for i in range(4):
		_pull_noclear(b, u, foe, 200.0)
	var d6: float = _sum(_pull_noclear(b, u, foe, 200.0), "damage", foe, "magic")
	t.near(d6 / d1, 1.0 + 5.0 * per, 0.01, "after 5 uses it hits %.0f%% harder (no cooldown: every pull counts)" % (5.0 * per * 100.0))
	for i in range(30):
		_pull_noclear(b, u, foe, 200.0)
	t.eq(int(u.learning.get(a.id, 0)), cap, "learning count capped at %d" % cap)
	t.eq(u.status_stacks("g11_ink_focus"), cap, "Ink Focus capped at %d stacks" % cap)
	t.near(u.get_stats().haste - h0, haste * float(cap), 0.0001, "haste capped too")
	var dc: float = _sum(_pull_noclear(b, u, foe, 200.0), "damage", foe, "magic")
	t.near(dc / d1, 1.0 + float(cap) * per, 0.01, "damage capped at %d learns" % cap)


## 真的求知节点：每念一次学一次，Ink Focus 让她念得更快；战后永久法强 = 1 + 学习计数
func test_inkwell_with_the_student(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_student", "pos": Vector2.ZERO, "star": 2, "weapon": "g11_inkwell_rifle"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(0, 2.5)}])
	var u: BUnit = b.units[0]
	b.start()
	_step_seconds(b, GC.START_DELAY + 12.0)
	var learned: int = int(u.learning.get("g11_inkwell_script", 0))
	t.ok(learned >= 4, "learned %d times in 12 s" % learned)
	t.eq(u.status_stacks("g11_ink_focus"), learned, "one Ink Focus per learning")
	b.pipeline.fx.damage(b.units[1], u, 1.0e6, "true")
	var guard := 0
	while b.state != "ended" and guard < 20000:
		b.step()
		guard += 1
	var key: String = u.roster_id if u.roster_id != "" else u.uid
	t.near(float((b.growth.get(key, {}) as Dictionary).get("ability_power", 0.0)), 1.0 + float(learned), 0.001,
		"after the battle she keeps 1 + %d ability power" % learned)


# ================================================================ 油纸伞枪
func test_parasol_rifle(t: TestCtx) -> void:
	var b := _setup_splash("g11_parasol_rifle")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var ally2: BUnit = b.units[3]
	var foe_by_ally: BUnit = b.units[4]
	var foe2: BUnit = b.units[5]
	var e: EquipmentDef = _eq("g11_parasol_rifle")
	var dr: float = float(e.abilities[0].effect_config["stats"]["damage_taken_pct"]["flat"])
	var r: float = float(_branch("g11_parasol_rifle", 3, "enemy_effect")["value_multiplier"])
	var dr0: float = ally.get_stats().damage_taken_pct
	var evs: Array[Dictionary] = _pull(b, u, ally, 200.0)
	t.ok(ally.get_status("g11_shelter") != null, "an ally gets Parasol Shade")
	t.near(ally.get_stats().damage_taken_pct - dr0, dr, 0.001, "-%.0f%% damage taken" % (dr * 100.0))
	t.ok(ally2.get_status("g11_shelter") != null, "so does the ally beside it (Splash)")
	t.eq(foe_by_ally.get_status("g11_shelter"), null, "but not an enemy standing there")
	t.near(ally.shield, 200.0 * r, 0.5, "4th part: an ally gains trigger value × %.0f%% shield" % (r * 100.0))
	t.eq(_sum(evs, "damage", ally) + _sum(evs, "damage", ally2), 0.0, "allies aren't hurt")
	t.ok(not ally.meta.has("knock") and ally.get_status("g11_soaked") == null, "allies aren't pushed or soaked")
	var p0: Vector2 = foe.pos
	evs = _pull(b, u, foe, 200.0)
	t.near(_sum(evs, "damage", foe, "magic"), 200.0 * r, 1.0, "an enemy takes trigger value × %.0f%% magic" % (r * 100.0))
	var kn: Dictionary = foe.meta.get("knock", {})
	t.ok(not kn.is_empty(), "and is knocked back")
	if not kn.is_empty():
		t.near(((kn["to"] as Vector2) - p0).length(), e.abilities[1].fixed_value, 0.15, "%.1f m" % e.abilities[1].fixed_value)
		t.ok(((kn["to"] as Vector2) - p0).dot(p0 - u.pos) > 0.0, "away from the holder")
	t.ok(foe.get_status("g11_soaked") != null, "and Soaked")
	t.eq(foe2.get_status("g11_soaked"), null, "only the target is soaked")
	t.eq(foe.get_status("g11_shelter"), null, "no shade for enemies")
	var d2: float = _sum(_pull_noclear(b, u, foe, 200.0), "damage", foe, "magic")
	t.eq(d2, 0.0, "the damage part has a %.0f s cooldown" % e.abilities[3].cooldown)


# ================================================================ 朱雀步枪
func test_vermilion_rifle(t: TestCtx) -> void:
	var b := _setup("g11_vermilion_rifle")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("g11_vermilion_rifle")
	var heal: float = e.abilities[0].fixed_value
	var dmg: float = e.abilities[1].fixed_value
	var acfg: Dictionary = _branch("g11_vermilion_rifle", 2, "ally_effect")["cfg"]
	var hr0: float = ally.get_stats().healing_received_pct
	ally.hp = 1000.0
	var evs: Array[Dictionary] = _pull(b, u, ally, 999.0)
	t.near(_sum(evs, "heal", ally), heal * (1.0 + u.get_stats().healing_done_pct), 1.0, "an ally heals a fixed %.0f" % heal)
	t.ok(ally.get_status("g11_rebirth") != null and ally.has_flag("undying"), "and gets Phoenix Fire (undying)")
	t.near(ally.get_stats().healing_received_pct - hr0, float(acfg["stats"]["healing_received_pct"]["flat"]), 0.001, "+healing received")
	b.pipeline.fx.damage(foe, ally, 1.0e7, "true")
	t.ok(ally.alive and ally.hp >= 1.0, "a killing blow leaves it at 1 health")
	t.eq(_sum(evs, "damage", ally), 0.0, "allies aren't hurt")
	t.ok(not ally.is_disarmed(), "or disarmed")
	evs = _pull(b, u, foe, 999.0)
	t.near(_sum(evs, "damage", foe, "magic"), dmg, 1.0, "an enemy takes a fixed %.0f magic" % dmg)
	t.eq(_sum(evs, "heal", foe), 0.0, "and isn't healed")
	t.ok(foe.get_status("g11_scorched") != null and foe.is_disarmed(), "and is Scorched (can't normal attack)")
	t.ok(not foe.has_flag("undying"), "no Phoenix Fire for enemies")
	var d2: float = _sum(_pull_noclear(b, u, foe, 1.0), "damage", foe, "magic")
	t.near(d2, dmg, 1.0, "【Basic】: again right away")
	_step_seconds(b, float(acfg["duration"]) + 0.2)
	t.ok(not ally.has_flag("undying"), "Phoenix Fire wears off")


# ================================================================ 珍珠贝手弩
func test_pearl_crossbow(t: TestCtx) -> void:
	var b := _setup_splash("g11_pearl_crossbow")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var ally2: BUnit = b.units[3]
	var foe_by_ally: BUnit = b.units[4]
	var foe2: BUnit = b.units[5]
	var e: EquipmentDef = _eq("g11_pearl_crossbow")
	var v: float = e.abilities[0].fixed_value
	var shell: float = float(e.abilities[1].effect_config["stats"]["na_damage_taken_flat"]["flat"])
	var evs: Array[Dictionary] = _pull(b, u, ally, 999.0)
	t.near(ally.shield, v, 0.5, "an ally gains a fixed %.0f shield" % v)
	t.near(ally2.shield, v, 0.5, "so does the ally beside it (Splash)")
	t.near(ally.get_stats().na_damage_taken_flat, shell, 0.001, "Nacre: -%.0f per normal attack taken" % shell)
	t.ok(ally2.get_status("g11_nacre") != null, "the ally beside it gets Nacre too")
	t.eq(foe_by_ally.shield, 0.0, "an enemy standing there gets no shield")
	t.eq(foe_by_ally.get_status("g11_nacre"), null, "…no Nacre")
	t.eq(_sum(evs, "damage", foe_by_ally), 0.0, "…and isn't hurt")
	t.eq(_sum(evs, "damage", ally) + _sum(evs, "damage", ally2), 0.0, "allies aren't hurt")
	t.eq(ally.get_status("g11_pearl_glare"), null, "or dazzled")
	evs = _pull(b, u, foe, 999.0)
	t.near(_sum(evs, "damage", foe, "magic"), v, 1.0, "an enemy takes a fixed %.0f magic" % v)
	t.near(_sum(evs, "damage", foe2, "magic"), v, 1.0, "its neighbor too (Splash)")
	t.ok(foe.get_status("g11_pearl_glare") != null, "the target is dazzled by Pearl Glare")
	t.eq(foe2.get_status("g11_pearl_glare"), null, "only the target")
	t.eq(foe.get_status("g11_nacre"), null, "no Nacre for enemies")
	# 珠贝真的减普攻伤害：木桩打一下
	var hitter: BUnit = foe_by_ally
	var raw: float = 200.0
	ally.shield = 0.0
	var dealt: float = b.pipeline.fx.damage(hitter, ally, raw, "physical", {"surface": "normal_attack"})
	t.near(dealt, raw - shell, 1.0, "a normal attack on a Nacre'd ally deals %.0f less" % shell)


# ================================================================ 朝天椒手弩
func test_chili_crossbow(t: TestCtx) -> void:
	var b := _setup("g11_chili_crossbow")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var e: EquipmentDef = _eq("g11_chili_crossbow")
	var buff: Dictionary = _branch("g11_chili_crossbow", 0, "ally_effect")["cfg"]
	var atk0: float = ally.get_stats().attack_power
	var as0: float = ally.get_stats().attack_speed_multiplier
	var evs: Array[Dictionary] = _pull(b, u, ally, 1.0)
	t.ok(ally.get_status("g11_spicy") != null, "an ally gets Spice Rush (whatever the trigger value)")
	t.near(ally.get_stats().attack_power, atk0 * (1.0 + float(buff["stats"]["attack_power"]["pct"])), 0.5, "+attack")
	t.near(ally.get_stats().attack_speed_multiplier - as0, float(buff["stats"]["attack_speed_multiplier"]["flat"]), 0.001, "+attack speed")
	t.ok(ally.status_count("burning") == 0 and not ally.has_flag("stun"), "allies don't burn or choke")
	t.eq(_sum(evs, "damage", ally), 0.0, "and aren't hurt")
	_pull(b, u, foe, 1.0)
	t.ok(foe.status_count("burning") >= 1, "an enemy catches 1 Burning (the shared status)")
	var st: BStatus = foe.get_status("g11_choke")
	t.ok(st != null and foe.has_flag("stun"), "and Chokes (stunned)")
	if st != null:
		t.near(st.expires_at - b.time, float(e.abilities[1].effect_config["duration"]), 0.01, "for %.1f s" % float(e.abilities[1].effect_config["duration"]))
	t.eq(foe.get_status("g11_spicy"), null, "no Spice Rush for enemies")
	_pull_noclear(b, u, foe, 1.0)
	t.ok(foe.status_count("burning") >= 2, "【Basic】: again right away (Burning instances are independent)")


# ================================================================ 蒲公英手弩
func test_dandelion_crossbow(t: TestCtx) -> void:
	var b := _setup_splash("g11_dandelion_crossbow")
	var u: BUnit = b.units[0]
	var ally: BUnit = b.units[1]
	var foe: BUnit = b.units[2]
	var ally2: BUnit = b.units[3]
	var foe_by_ally: BUnit = b.units[4]
	var foe2: BUnit = b.units[5]
	var e: EquipmentDef = _eq("g11_dandelion_crossbow")
	var v: float = e.abilities[1].fixed_value
	var dodge: float = float(_branch("g11_dandelion_crossbow", 0, "ally_effect")["cfg"]["stats"]["na_dodge"]["flat"])
	var weak: float = float(_branch("g11_dandelion_crossbow", 0, "enemy_effect")["cfg"]["stats"]["attack_power"]["pct"])
	ally.hp = 1000.0
	ally2.hp = 1000.0
	var evs: Array[Dictionary] = _pull(b, u, ally, 999.0)
	t.near(ally.get_stats().na_dodge, dodge, 0.001, "an ally gets Fluff Veil: +%.0f%% dodge" % (dodge * 100.0))
	t.ok(ally2.get_status("g11_fluff_veil") != null, "so does the ally beside it (Splash)")
	t.near(_sum(evs, "heal", ally), v, 1.0, "an ally heals a fixed %.0f" % v)
	t.near(_sum(evs, "heal", ally2), v, 1.0, "so does the ally beside it")
	t.eq(foe_by_ally.get_status("g11_fluff_veil"), null, "an enemy standing there gets nothing")
	t.eq(foe_by_ally.get_status("g11_fluff_haze"), null, "…and isn't blinded")
	t.eq(_sum(evs, "damage", foe_by_ally), 0.0, "…or hurt")
	t.eq(_sum(evs, "damage", ally) + _sum(evs, "damage", ally2), 0.0, "allies aren't hurt")
	var a0: float = foe.get_stats().attack_power
	evs = _pull(b, u, foe, 999.0)
	t.near(_sum(evs, "damage", foe, "physical"), v, 1.0, "an enemy takes a fixed %.0f physical" % v)
	t.near(_sum(evs, "damage", foe2, "physical"), v, 1.0, "its neighbor too (Splash)")
	t.near(foe.get_stats().attack_power, a0 * (1.0 + weak), 0.5, "and is Fluff-Blinded (-%.0f%% attack)" % (-weak * 100.0))
	t.ok(foe2.get_status("g11_fluff_haze") != null, "the neighbor too")
	t.eq(foe.get_status("g11_fluff_veil"), null, "no Fluff Veil for enemies")
