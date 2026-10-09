extends RefCounted
## 棋子外观差分：发色落在本色系里、同模型同色的棋子发色不撞；每个身体模型都有自己的待机小动作和胜利动作，且会收起武器。


func test_hair_family_palettes_classify_as_their_own_color(t: TestCtx) -> void:
	for fam: String in GC.HAIR_FAMILY.keys():
		t.ok(GC.FACTIONS.has(fam), "hair family %s is a unit color" % fam)
		for hx: String in GC.HAIR_FAMILY[fam]:
			t.eq(GC.color_family(Color(hx)), fam, "%s belongs to the %s family" % [hx, fam])
	for tone: String in GC.SKIN_TONES.keys():
		t.ok(Color.html_is_valid(str(GC.SKIN_TONES[tone])), "skin tone %s" % tone)


func test_every_unit_has_hair_in_its_color_family(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	for id: String in cat.units.keys():
		var d: UnitDef = cat.get_unit(id)
		t.ok(GC.SKIN_TONES.has(d.skin), "%s skin tone %s" % [id, d.skin])
		var look: Dictionary = UnitSkin.look_for(d, null)
		t.ok(look.get("skin") is Color, "%s look carries a skin color" % id)
		if d.model != "" and d.hair == "":
			t.ok(not look.has("hair"), "%s keeps its model's own hair" % id)     # 专属模型没写发色 = 用模型原发色
			continue
		var hc: Color = GC.hair_color_of(d.id, d.faction_id, d.hair)
		t.eq(GC.color_family(hc), d.faction_id, "%s hair %s is %s" % [id, hc.to_html(false), d.faction_id])
		t.ok(look.get("hair") is Color, "%s look carries its hair color" % id)


## 同一个身体模型 + 同一种颜色的棋子(商店里能同时出现的)，发色必须互不相同，一眼能分开
func test_same_model_same_color_units_differ_in_hair(t: TestCtx) -> void:
	var cat: Catalog = Fixture.catalog()
	var seen := {}
	for id: String in cat.units.keys():
		var d: UnitDef = cat.get_unit(id)
		if not d.available_in_shop or d.summon_only or id.begins_with("sample_") or id.begins_with("mob_"):
			continue
		var key: String = "%s|%s|%s" % [d.model, d.faction_id, GC.hair_color_of(d.id, d.faction_id, d.hair).to_html(false)]
		t.ok(not seen.has(key), "%s and %s share model, color and hair" % [id, str(seen.get(key, ""))])
		seen[key] = id


func test_every_body_model_has_fidget_and_victory_that_stow_the_weapon(t: TestCtx) -> void:
	var lib: AnimationLibrary = load("res://assets/archer_anims.res") as AnimationLibrary
	t.ok(lib != null, "animation library exists")
	if lib == null:
		return
	var cat: Catalog = Fixture.catalog()
	var bodies := {"": true}
	for id: String in cat.units.keys():
		bodies[cat.get_unit(id).model] = true
	for body: String in bodies.keys():
		for kind: String in ["fidget", "victory"]:
			var nm: String = UnitSkin.char_anim({"body": body}, kind)
			t.ok(lib.has_animation(nm), "body '%s' has %s" % [body, nm])
			if not lib.has_animation(nm):
				continue
			var a: Animation = lib.get_animation(nm)
			t.eq(a.loop_mode != Animation.LOOP_NONE, kind == "victory", "%s loops only if it is a victory" % nm)
			for bone: String in ["Bow", "Weapon_L", "Shield"]:
				var tr: int = a.find_track(NodePath("Skeleton3D:" + bone), Animation.TYPE_SCALE_3D)
				t.ok(tr >= 0 and a.scale_track_interpolate(tr, a.length * 0.5).x < 0.01, "%s stows %s" % [nm, bone])
	# 普通待机/攻击动作里武器是正常大小
	var idle: Animation = lib.get_animation("idle_sword")
	for bone2: String in ["Bow", "Weapon_L", "Shield"]:
		var tr2: int = idle.find_track(NodePath("Skeleton3D:" + bone2), Animation.TYPE_SCALE_3D)
		t.ok(tr2 >= 0 and idle.scale_track_interpolate(tr2, 0.5).x > 0.99, "idle keeps %s visible" % bone2)


## 男性款：每个待机/跑步动作都有 *_m 版，男性身体的外观会选它们(攻击男女共用)
func test_male_bodies_use_male_idle_and_run(t: TestCtx) -> void:
	var lib: AnimationLibrary = load("res://assets/archer_anims.res") as AnimationLibrary
	t.ok(lib != null, "animation library exists")
	if lib == null:
		return
	var names: Array = [GC.UNARMED_ANIMS["idle"], GC.UNARMED_ANIMS["run"]]
	for wc: String in GC.WEAPON_CLASS_IDS:
		var c: Dictionary = GC.WEAPON_CLASSES[wc]
		for set_key: String in ["anims", "guard_anims"]:
			if c.has(set_key):
				names.append(c[set_key]["idle"])
				names.append(c[set_key]["run"])
	for nm: Variant in names:
		t.ok(lib.has_animation(str(nm) + "_m"), "male variant of %s" % str(nm))
	var male_look := {"wclass": "sword", "male": true}
	t.eq(UnitSkin.anim(male_look, "idle"), str(GC.WEAPON_CLASSES["sword"]["anims"]["idle"]) + "_m", "male look picks the male idle")
	t.eq(UnitSkin.anim(male_look, "attack"), str(GC.WEAPON_CLASSES["sword"]["anims"]["attack"]), "attacks are shared")
	t.eq(UnitSkin.anim({"wclass": "", "male": true}, "run"), str(GC.UNARMED_ANIMS["run"]) + "_m", "unarmed male run")
	t.eq(UnitSkin.anim({"wclass": "sword"}, "idle"), str(GC.WEAPON_CLASSES["sword"]["anims"]["idle"]), "female/default look keeps the base idle")
