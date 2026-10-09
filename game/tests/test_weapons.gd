extends RefCounted
## 武器系统：基础武器 / 武器大类决定射程、普攻倍率、攻击间隔与动画 / 空手不能攻击 / 武器效果仍需触发器配对。


func test_every_unit_holds_its_basic_weapon_by_default(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	for id: String in cat.units.keys():
		var d: UnitDef = cat.get_unit(id)
		if d.base_weapon_class == "":
			continue
		var w: EquipmentDef = cat.resolve_weapon(d, "")
		t.ok(w != null and w.basic, "%s gets a basic weapon" % id)
		t.eq(w.class_id, d.base_weapon_class, "%s basic weapon class" % id)
		t.ok(w.abilities.is_empty() and w.flat_mods.is_empty() and w.pct_mods.is_empty(), "%s basic weapon has no effect or stats" % id)
	for wc: String in GC.WEAPON_CLASS_IDS:
		t.ok(cat.basic_weapon(wc) != null, "class %s has a basic weapon" % wc)


func test_zero_range_pistols_play_as_melee(t: TestCtx) -> void:
	# 攻击范围归零的电击器：手枪大类(is_ranged)，但实际按近战用——机器人摆位(plays_ranged)和战斗 AI(BUnit.style)一个口径
	var cat: Catalog = Fixture.catalog()
	var stun: EquipmentDef = cat.get_equipment("dual_use_stunner")
	t.ok(stun.is_ranged() and not stun.plays_ranged(), "the stunner is a pistol but plays as melee")
	t.ok(cat.get_equipment("rapidfire_arbalest").plays_ranged(), "a crossbow plays as ranged")
	var b := Fixture.make([{"def": "node_shielder", "pos": Vector2(0, 0), "weapon": "dual_use_stunner"}, {"def": "test_dummy", "team": 1, "pos": Vector2(0, 3)}])
	b.start()
	t.eq(b.units[0].style(), "melee", "and the battle AI walks it in like a melee unit")


func test_weapon_class_sets_range_and_attack_interval(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_archer", "pos": Vector2.ZERO}, {"def": "node_archer", "pos": Vector2(0, 2), "weapon": "amplifier_crossbow"}])
	var rf: BUnit = b.units[0]
	var xb: BUnit = b.units[1]
	t.eq(rf.weapon.id, "basic_rifle", "default weapon (速射节点：步枪)")
	t.near(rf.get_stats().attack_range, 5.0, 0.0001, "rifle range")
	t.near(rf.get_stats().attack_base_interval_seconds, float(GC.WEAPON_CLASSES["rifle"]["interval"]), 0.0001, "rifle interval = its attack animation length")
	t.near(xb.get_stats().attack_range, 3.0, 0.0001, "hand crossbow range")
	t.near(xb.get_stats().attack_base_interval_seconds, float(GC.WEAPON_CLASSES["crossbow"]["interval"]), 0.0001, "crossbow interval")
	t.ok(xb.get_stats().attack_interval() < rf.get_stats().attack_interval(), "the hand crossbow shoots faster than the rifle")
	# 换武器 → 立刻换射程
	xb.set_weapon(Fixture.catalog().get_equipment("calibration_rifle"))
	t.near(xb.get_stats().attack_range, 5.0, 0.0001, "rifle range after swapping")
	t.near(xb.get_stats().attack_power, 104.0 + 12.0, 0.0001, "weapon stat bonus applied (+12 attack)")


func test_normal_attack_multiplier_and_damage_kind_follow_the_weapon(t: TestCtx) -> void:
	# 打手攻击力 100，木桩 0 防 0 魔抗：普攻伤害 = 100 × 武器大类普攻倍率(木桩放远一点，法器的溅射不会溅到自己)
	for wc: String in GC.WEAPON_CLASS_IDS:
		var b := Fixture.make([{"def": "test_hitter", "pos": Vector2.ZERO, "weapon": "basic_" + wc},
			{"def": "test_dummy", "team": 1, "pos": Vector2(3, 0)}])
		b.units[0].base.crit_chance = 0.0
		b.units[0].mark_dirty()
		b.pipeline.normal_attack(b.units[0], b.units[1])
		b.advance_pending(1.0)
		var d: Array[Dictionary] = Fixture.events_of(b, "damage", "normal_attack")
		var hits: int = 1 + int((GC.WEAPON_CLASSES[wc] as Dictionary).get("na_keywords", {}).get("pursuit", 0))
		t.eq(d.size(), hits, "%s: %d hit(s)" % [wc, hits])
		if d.is_empty():
			continue
		var want: float = 100.0 * float(GC.WEAPON_CLASSES[wc]["na_mult"])
		t.near(float(d[0]["amount"]), want, 0.01, "%s: attack × %s" % [wc, str(GC.WEAPON_CLASSES[wc]["na_mult"])])
		t.eq(str(d[0]["kind"]), str(GC.WEAPON_CLASSES[wc]["dmg"]), "%s: damage kind" % wc)


func test_unarmed_unit_cannot_attack(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_darkknight", "pos": Vector2.ZERO, "unarmed": true},
		{"def": "test_dummy", "team": 1, "pos": Vector2(1.0, 0)}])
	var kn: BUnit = b.units[0]
	t.ok(kn.weapon == null and not kn.can_attack(), "no weapon")
	b.pipeline.normal_attack(kn, b.units[1])
	t.eq(Fixture.events_of(b, "damage").size(), 0, "a forced normal attack does nothing without a weapon")
	b.events.clear()
	b.start()
	var starts := 0
	for i in range(int(6.0 / GC.SIM_DT)):
		b.step()
		for e: Dictionary in b.events:
			if e.get("t") == "attack_start" and e.get("unit") == kn:
				starts += 1
		b.events.clear()
	t.eq(starts, 0, "never starts an attack")


func test_attack_speed_speeds_up_the_attack_module(t: TestCtx) -> void:
	var b := Fixture.make([{"def": "node_darkknight", "pos": Vector2.ZERO}, {"def": "test_dummy", "team": 1, "pos": Vector2(1.2, 0)}])
	var kn: BUnit = b.units[0]
	kn.base.attack_speed_multiplier = 2.0
	kn.mark_dirty()
	b.start()
	var ev: Dictionary = {}
	for i in range(int(4.0 / GC.SIM_DT)):
		b.step()
		for e: Dictionary in b.events:
			if e.get("t") == "attack_start" and ev.is_empty():
				ev = e
		b.events.clear()
		if not ev.is_empty():
			break
	t.ok(not ev.is_empty(), "attacked")
	var wc: Dictionary = GC.WEAPON_CLASSES["heavy"]
	t.eq(str(ev.get("weapon_class", "")), "heavy", "heavy weapon module")
	t.near(float(ev.get("speed_scale", 0.0)), 2.0, 0.001, "animation plays 2× faster")
	t.near(float(ev.get("windup", 0.0)), float(wc["windup"]) * 0.5, 0.001, "wind-up halves with 2× attack speed")


func test_weapon_effect_needs_the_units_trigger(t: TestCtx) -> void:
	# 测试木桩没有触发器可以扣动武器效果：拿着奥术刃打再多次也不会出装备伤害
	var b := Fixture.make([{"def": "test_hitter", "pos": Vector2.ZERO, "weapon": "sample_arcane_edge"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(1, 0)}])
	for i in range(12):
		b.pipeline.normal_attack(b.units[0], b.units[1])
	t.eq(Fixture.events_of(b, "damage", "equipment").size(), 0, "no trigger, no weapon effect")
	# 速射节点有"每第 3 次普攻命中"的装备触发器(改装箭头) → 武器效果生效
	var b2 := Fixture.make([{"def": "node_archer", "pos": Vector2.ZERO, "weapon": "rapidfire_arbalest"},
		{"def": "test_dummy", "team": 1, "pos": Vector2(1, 0)}])
	for i2 in range(3):
		b2.pipeline.normal_attack(b2.units[0], b2.units[1])
	t.ok(Fixture.events_of(b2, "damage", "equipment").size() >= 1, "unit trigger + weapon payload = effect")


func test_every_weapon_class_has_its_animation_module(t: TestCtx) -> void:
	var lib: AnimationLibrary = load("res://assets/archer_anims.res") as AnimationLibrary
	t.ok(lib != null, "animation library exists")
	if lib == null:
		return
	for wc: String in GC.WEAPON_CLASS_IDS:
		var c: Dictionary = GC.WEAPON_CLASSES[wc]
		var sets: Array = [c["anims"]]
		for alt: String in ["guard_anims", "tower_anims"]:
			if c.has(alt):
				sets.append(c[alt])
		for anims: Dictionary in sets:
			for which: String in ["idle", "run", "attack"]:
				t.ok(lib.has_animation(str(anims[which])), "%s: animation %s" % [wc, str(anims[which])])
			if lib.has_animation(str(anims["attack"])):
				var a: Animation = lib.get_animation(str(anims["attack"]))
				t.near(a.length, float(c["interval"]), 0.02, "%s: attack animation length = base attack interval" % wc)
		t.ok(float(c["windup"]) + float(c["recover"]) < float(c["interval"]), "%s: wind-up + recover fit in the cycle" % wc)
		# 普攻关键词带来的额外动作：群攻招式(长度 = 招式间隔)、拉弓/端枪(循环)、装弹
		var m: Dictionary = c.get("multi", {})
		if not m.is_empty():
			t.ok(lib.has_animation(str(m["anim"])), "%s: multi-attack animation %s" % [wc, str(m["anim"])])
			if lib.has_animation(str(m["anim"])):
				t.near(lib.get_animation(str(m["anim"])).length, float(m["interval"]), 0.02, "%s: multi-attack animation length = its interval" % wc)
			t.ok(float(m["windup"]) + float(m["recover"]) < float(m["interval"]), "%s: multi wind-up + recover fit" % wc)
		for hk: String in ["draw_anim", "draw_hold_anim", "release_anim", "hold_anim"]:
			if c.has(hk):
				t.ok(lib.has_animation(str(c[hk])), "%s: %s %s" % [wc, hk, str(c[hk])])
		# 拉弓后的放箭动画 = 出手之后这一轮剩下的时间
		if c.has("release_anim") and lib.has_animation(str(c["release_anim"])):
			t.near(lib.get_animation(str(c["release_anim"])).length, float(c["interval"]) - float(c["windup"]), 0.04, "%s: release animation = interval - windup" % wc)
		if c.has("draw_hold_anim") and lib.has_animation(str(c["draw_hold_anim"])):
			var hl: float = lib.get_animation(str(c["draw_hold_anim"])).length * 30.0
			t.near(hl, round(hl), 0.001, "%s: draw hold loop is a whole number of frames" % wc)
		if c.has("ammo"):
			t.ok(lib.has_animation(str(c["ammo"]["anim"])), "%s: reload animation" % wc)
			if lib.has_animation(str(c["ammo"]["anim"])):
				t.near(lib.get_animation(str(c["ammo"]["anim"])).length, float(c["ammo"]["reload"]), 0.02, "%s: reload animation length = reload time" % wc)
	for which2: String in ["idle", "run"]:
		t.ok(lib.has_animation(str(GC.UNARMED_ANIMS[which2])), "unarmed %s" % which2)


## 双手武器(长枪/大剑/步枪)的待机、跑动、攻击逐帧检查：手臂不能陷进躯干(测的是动画生成代码本身，与 tools/arm_clip.gd 同一套几何)
func test_two_handed_weapons_keep_arms_out_of_the_body(t: TestCtx) -> void:
	var rig = load("res://tools/rig.gd").new()
	rig.build()
	var defs = load("res://tools/anim_combat.gd").new(rig)
	var tbl: Dictionary = defs.table()
	var p = load("res://tools/anim_lib.gd").Pose.new(rig)
	var names: Array[String] = []
	for k: String in ["polearm", "heavy", "rifle"]:
		for which: String in ["idle", "run", "attack"]:
			names.append(which + "_" + k)
	names.append_array(["attack_polearm_pierce", "attack_heavy_whirl", "aim_rifle", "reload_rifle", "dash_heavy", "spin_heavy"])
	for nm: String in names:
		var limit: float = 2.5 if nm.begins_with("idle") or nm.begins_with("run") or nm.begins_with("aim") else 3.5     # 体素；上臂贴着胸侧那一点点接触看不出来
		var worst := 0.0
		var frames: int = int(round(float(tbl[nm]["dur"]) * 30.0))
		for f in range(0, frames + 1, 2):
			p.reset()
			(tbl[nm]["fn"] as Callable).call(float(f) / 30.0, p)
			p.fk()
			for side: String in ["L", "R"]:
				worst = maxf(worst, float(defs.arm_penetration(p, side)["depth"]))
		t.ok(worst <= limit, "%s: arms stay outside the torso (worst %.1f voxels)" % [nm, worst])


## 单位自带的动作(anim_overrides)都在动画库里(男性款的待机/跑步要有 *_m)；自带普攻节奏(wclass_overrides)的，攻击动作长度 = 他的普攻间隔
func test_unit_animation_overrides_exist(t: TestCtx) -> void:
	var lib: AnimationLibrary = load("res://assets/archer_anims.res") as AnimationLibrary
	var cat: Catalog = Fixture.catalog()
	for uid: String in cat.units.keys():
		var d: UnitDef = cat.get_unit(uid)
		var male: bool = UnitSkin.is_male_body(d.model)
		for cls: String in d.anim_overrides.keys():
			var ov: Dictionary = d.anim_overrides[cls]
			for which: String in ov.keys():
				var nm: String = str(ov[which])
				if male and (which == "idle" or which == "run"):
					nm += "_m"
				t.ok(lib.has_animation(nm), "%s (%s): animation %s" % [uid, cls, nm])
			var wo: Dictionary = d.wclass_overrides.get(cls, {})
			if wo.has("interval") and ov.has("attack") and lib.has_animation(str(ov["attack"])):
				t.near(lib.get_animation(str(ov["attack"])).length, float(wo["interval"]), 0.02, "%s (%s): attack animation = his own attack interval" % [uid, cls])
				var wc: Dictionary = GC.weapon_class(cls).duplicate()
				wc.merge(wo, true)
				t.ok(float(wc["windup"]) + float(wc["recover"]) < float(wc["interval"]), "%s (%s): wind-up + recover fit his cycle" % [uid, cls])


## 狙击窝(屏息节点：wclass_overrides.<大类>.nest)：跪姿的瞄准 / 开枪 / 换弹 / 跪下 / 挪位都在动画库里；
## 跪姿开枪 = 这个大类的普攻间隔(出手时刻才对得上)，跪姿换弹 = 这个大类的换弹时长；跪姿端枪 / 开枪时手臂不穿进身体
func test_nest_animations(t: TestCtx) -> void:
	var lib: AnimationLibrary = load("res://assets/archer_anims.res") as AnimationLibrary
	var cat: Catalog = Fixture.catalog()
	var found := 0
	for uid: String in cat.units.keys():
		var d: UnitDef = cat.get_unit(uid)
		for cls: String in d.wclass_overrides.keys():
			var nest: Dictionary = (d.wclass_overrides[cls] as Dictionary).get("nest", {})
			if nest.is_empty():
				continue
			found += 1
			for k: String in ["aim", "fire", "reload", "in", "shift"]:
				t.ok(lib.has_animation(str(nest.get(k, ""))), "%s (%s): nest animation %s = %s" % [uid, cls, k, str(nest.get(k, ""))])
			var wc: Dictionary = d.wclass_for(cls)
			if lib.has_animation(str(nest.get("fire", ""))):
				t.near(lib.get_animation(str(nest["fire"])).length, float(wc["interval"]), 0.02, "%s (%s): kneeling shot = attack interval" % [uid, cls])
			if wc.has("ammo") and lib.has_animation(str(nest.get("reload", ""))):
				t.near(lib.get_animation(str(nest["reload"])).length, float((wc["ammo"] as Dictionary)["reload"]), 0.02, "%s (%s): kneeling reload = reload time" % [uid, cls])
			t.ok(nest.get("crate") is Array and (nest["crate"] as Array).size() == 3, "%s (%s): crate placement [x, z, top]" % [uid, cls])
	t.ok(found >= 1, "at least one unit settles into a sniper nest (Node Sniper)")
	var rig = load("res://tools/rig.gd").new()
	rig.build()
	var defs = load("res://tools/anim_chars.gd").new(rig)
	var tbl: Dictionary = defs.table()
	var p = load("res://tools/anim_lib.gd").Pose.new(rig)
	for nm: String in ["nest_aim_sniper", "nest_fire_sniper", "nest_reload_sniper"]:
		var worst := 0.0
		var frames: int = int(round(float(tbl[nm]["dur"]) * 30.0))
		for f in range(0, frames + 1, 2):
			p.reset()
			(tbl[nm]["fn"] as Callable).call(float(f) / 30.0, p)
			p.fk()
			for side: String in ["L", "R"]:
				worst = maxf(worst, float(defs.arm_penetration(p, side)["depth"]))
		t.ok(worst <= 3.5, "%s: arms stay outside the torso (worst %.1f voxels)" % [nm, worst])
