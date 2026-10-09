extends RefCounted
## 武器的适配角色(FitTags)：触发器的三组内置标签(实测写进单位数据)、武器的三组标签(由能力推)、匹配规则、适配角色列表。


func _w(abilities: Array, extra: Dictionary = {}) -> EquipmentDef:
	var d := {"id": "fit_test_weapon", "cost": 2, "color_id": "black", "weapon_class": "sword", "abilities": abilities}
	d.merge(extra, true)
	return EquipmentDef.from_dict(d)


func _a(effect: String, keywords: Array = [], cfg: Dictionary = {}, cls: String = "blade") -> Dictionary:
	var kv := {}
	if keywords.has("multi_attack"):
		kv["multi_attack"] = 3
	return {"id": "fit_test_ability", "ability_class": cls, "effect_type": effect, "keywords": keywords, "keyword_values": kv,
		"required_trigger_tags": ["equipment_payload"], "effect_config": cfg}


func test_weapon_tags(t: TestCtx) -> void:
	var wt: Dictionary = FitTags.weapon_tags(_w([_a("physical_damage")]))
	t.eq([wt["side"], wt["multi"], wt["basic"], wt["any_target"]], ["enemy", false, false, false], "damage: enemies, single, no Basic")
	wt = FitTags.weapon_tags(_w([_a("heal", ["basic", "multi_attack"])]))
	t.eq([wt["side"], wt["multi"], wt["basic"]], ["ally", true, true], "heal with Multi Attack + Basic")
	wt = FitTags.weapon_tags(_w([_a("stat_status", [], {"flags": ["debuff"]})]))
	t.eq(wt["side"], "enemy", "a debuff status is for enemies")
	wt = FitTags.weapon_tags(_w([_a("stat_status", [], {"flags": ["buff"]})]))
	t.eq(wt["side"], "ally", "a buff status is for allies")
	wt = FitTags.weapon_tags(_w([_a("stat_status", [], {"ally_effect": {}, "enemy_effect": {}}, "amulet")]))
	t.eq(wt["side"], "dual", "an amulet with ally / enemy branches provides dual-mode")
	wt = FitTags.weapon_tags(_w([_a("magic_damage"), _a("heal")]))
	t.eq(wt["side"], "dual", "one enemy part + one ally part = dual-mode")
	wt = FitTags.weapon_tags(_w([_a("summon_aura", ["multi_attack"])]))
	t.eq([wt["side"], wt["multi"], wt["any_target"]], ["dual", false, true], "an effect that ignores the trigger target: any side, any count")
	wt = FitTags.weapon_tags(_w([_a("physical_damage", [], {"all_targets": true})]))
	t.ok(bool(wt["multi"]), "all_targets counts as Multi Attack")
	wt = FitTags.weapon_tags(_w([_a("physical_damage")], {"fit_tags": {"side": "ally", "multi": true, "basic": true}}))
	t.eq([wt["side"], wt["multi"], wt["basic"]], ["ally", true, true], "the data can override the derived tags")


func test_matching_rules(t: TestCtx) -> void:
	var enemy_w := {"side": "enemy", "multi": false, "basic": false}
	var dual_w := {"side": "dual", "multi": false, "basic": false}
	var trig := {"side": "enemy", "count": "single", "freq": "low"}
	t.ok(FitTags.matches(trig, enemy_w), "enemy / single / low ← enemy weapon, no Multi, no Basic")
	t.ok(FitTags.matches(trig, dual_w), "dual-mode fits a one-sided trigger too")
	t.ok(not FitTags.matches({"side": "ally", "count": "single", "freq": "low"}, enemy_w), "an enemy weapon doesn't fit an ally trigger")
	t.ok(not FitTags.matches({"side": "both", "count": "single", "freq": "low"}, enemy_w), "a trigger that needs dual-mode needs a dual-mode weapon")
	t.ok(FitTags.matches({"side": "both", "count": "single", "freq": "low"}, dual_w), "…and takes one")
	t.ok(not FitTags.matches({"side": "enemy", "count": "multi", "freq": "low"}, enemy_w), "several targets want Multi Attack")
	t.ok(FitTags.matches({"side": "enemy", "count": "multi", "freq": "low"}, {"side": "enemy", "multi": true, "basic": false}), "…and take it")
	t.ok(not FitTags.matches(trig, {"side": "enemy", "multi": true, "basic": false}), "Multi Attack is wasted on one target")
	t.ok(not FitTags.matches({"side": "enemy", "count": "single", "freq": "high"}, enemy_w), "a frequent trigger wants Basic (no cooldown)")
	t.ok(FitTags.matches({"side": "enemy", "count": "single", "freq": "high"}, {"side": "enemy", "multi": false, "basic": true}), "…and takes it")
	t.ok(FitTags.matches(trig, {"side": "enemy", "multi": false, "basic": true}), "an infrequent trigger takes Basic or not")
	t.ok(FitTags.matches({"side": "ally", "count": "multi", "freq": "low"}, {"side": "dual", "multi": false, "basic": false, "any_target": true}),
		"a weapon that ignores the target doesn't care about the target count")
	t.ok(not FitTags.matches({}, enemy_w), "an untagged trigger fits nothing")


func test_every_shop_trigger_tagged(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var n := 0
	for uid: String in cat.shop_unit_ids():
		for tr: TriggerDef in FitTags.payload_triggers(cat.get_unit(uid)):
			n += 1
			t.ok(FitTags.SIDES.has(str(tr.fit.get("side", ""))) and ["multi", "single"].has(str(tr.fit.get("count", "")))
				and ["high", "low", "never"].has(str(tr.fit.get("freq", ""))), "%s %s has fit tags (%s)" % [uid, tr.id, str(tr.fit)])
	t.ok(n >= 40, "%d weapon triggers checked" % n)


## 实测标签的几个样本：和设计一致
func test_measured_samples(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var tg := func(uid: String) -> Dictionary: return FitTags.payload_triggers(cat.get_unit(uid))[0].fit
	t.eq(tg.call("node_nurse")["side"], "ally", "Nurse's potion fill mostly hits hurt allies")
	t.eq(tg.call("node_witch")["side"], "both", "Witch's stars hit both sides")
	t.eq(tg.call("node_vampire")["count"], "multi", "Vampire's blood circle hits several enemies")
	t.eq(tg.call("node_samurai")["freq"], "high", "Samurai's sword marks pop often")
	t.eq(tg.call("node_gladiator")["freq"], "low", "Gladiator triggers on kills")


func test_fit_units(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	t.eq(cat.fit_units("basic_sword"), [] as Array[String], "basic weapons have no fit list")
	# 每把通用武器的适配角色里至少有一只测强度定下的合手棋子(test_generic_weapons.gd 的 CARRIERS)
	var carriers: Dictionary = load("res://game/tests/test_generic_weapons.gd").CARRIERS
	for wid: String in carriers.keys():
		var fits: Array[String] = cat.fit_units(wid)
		var hit := false
		for c: String in carriers[wid]:
			if fits.has(c):
				hit = true
		t.ok(hit, "%s fits one of its proven carriers (%s)" % [wid, ", ".join(fits)])
		for uid: String in fits:
			t.ok(FitTags.can_equip(cat.get_equipment(wid), cat.get_unit(uid)), "%s: %s can equip it" % [wid, uid])
	# 前提：强化召唤物的武器只给有召唤物的；充能类只给有【充能】被动的
	for uid2: String in cat.fit_units("puppet_lantern"):
		t.ok(FitTags.unit_has(cat.get_unit(uid2), "summon"), "puppet_lantern → %s has summons" % uid2)
	for uid3: String in cat.fit_units("capacitor_codex"):
		t.ok(FitTags.unit_has(cat.get_unit(uid3), "charged"), "capacitor_codex → %s has Charged" % uid3)
	# 专武大多适配自己的主人(定规则时的校准：45 把里 39 把)
	var ok := 0
	var n := 0
	for eid: String in cat.equipment.keys():
		var e: EquipmentDef = cat.get_equipment(eid)
		if e.owner != "" and e.reworked and cat.get_unit(e.owner) != null and cat.get_unit(e.owner).available_in_shop:
			n += 1
			if cat.fit_units(eid).has(e.owner):
				ok += 1
	t.ok(ok * 10 >= n * 8, "exclusive weapons fit their owners: %d / %d" % [ok, n])


## 有两个武器触发器的棋子(舞星：一个给队友、一个给敌人)：单边的武器会被另一个触发器用反，不算适配；双模的才算
func test_two_sided_units(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var sides := {}
	for tr: TriggerDef in FitTags.payload_triggers(cat.get_unit("node_dancer")):
		sides[str(tr.fit.get("side", ""))] = true
	t.ok(sides.has("ally") and sides.has("enemy"), "Dancer has an ally trigger and an enemy trigger")
	t.ok(not cat.fit_units("stardust_orb").has("node_dancer"), "a one-sided weapon doesn't fit her, though her enemy trigger matches it")
	t.ok(cat.fit_units("chord_fork").has("node_dancer"), "a dual-mode one does")
	t.ok(cat.fit_units("dance_fans").has("node_dancer"), "…like her own fans")
