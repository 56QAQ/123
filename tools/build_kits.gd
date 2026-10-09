extends SceneTree
## 通用武器的分批模型文件(三批一组并行做，各写各的；见 tools/author_data.py 的"分批文件")
const BATCH_MODELS: Array[String] = ["res://tools/weapons/gen5_models.gd", "res://tools/weapons/gen6_models.gd", "res://tools/weapons/gen7_models.gd",
	"res://tools/weapons/gen8_models.gd", "res://tools/weapons/gen9_models.gd", "res://tools/weapons/gen10_models.gd",
	"res://tools/weapons/gen11_models.gd", "res://tools/weapons/gen12_models.gd", "res://tools/weapons/gen13_models.gd",
	"res://tools/weapons/gen14_models.gd", "res://tools/weapons/gen15_models.gd", "res://tools/weapons/gen16_models.gd"]
## 构建"棋子模型套件"：身体网格 + 全部武器网格(9 大类 × 外观，双持武器另有左手那把) + 副手盾 + 箭(投射物)，
## 以及场景 scenes/unit_model.tscn。全部共用同一副骨骼与同一套动画库；阵营/武器换色由 voxel_unit.gdshader 的 instance uniform 完成。
## 部件命名：W_<大类>_<外观>(右手，"Bow" 骨；例外：变奏节点本人的大三角钢琴 W_focus_grand / W_focus_grand_white 整台挂 Root 骨，放在她身前) / L_<大类>_<外观>(左手，"Weapon_L" 骨) / A_<大类>_<外观>(挂在身上的附件，如炽霞的刀鞘) / P_<名字>(动作里临时出现的道具，平时隐藏，如钓鱼竿) / Body / Shield。
## 专属身体：tools/chars/<模型>.gd 各一个文件(自动发现)，生成 assets/unit_body_<模型>.res；不放进场景，
## 游戏里 UnitSkin 按单位数据的 "model" 按需加载成 Body_<模型> 节点(几十个专属身体不会一次全进内存)。
## 网格一律压缩存盘(ResourceSaver.FLAG_COMPRESS)。
## 用法: godot --path . --script res://tools/build_kits.gd [-- only=unit_body_dancer,wpn_focus_syringe]  (only：只重新雕刻这些网格，其余沿用已有资源)
##       [-- chars=berserker,maid]  只生成这几个专属身体，不碰武器和场景(并行做模型时用，见 run_char.sh)
const Rig = preload("res://tools/rig.gd")
const VGrid = preload("res://tools/vgrid.gd")
const Mesher = preload("res://tools/mesher.gd")
const Pal = preload("res://tools/pal.gd")
const Body = preload("res://tools/model_body.gd")
const Head = preload("res://tools/model_head.gd")
const BowModel = preload("res://tools/model_bow.gd")
const Props = preload("res://tools/model_props.gd")
const Weapons = preload("res://tools/model_weapons.gd")

var rig
var pal: Dictionary
var mat: ShaderMaterial
var only: PackedStringArray = PackedStringArray()
const CHARS_DIR := "res://tools/chars"


func _init() -> void:
	var t0 := Time.get_ticks_msec()
	var chars_only := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5).split(",")
		if a.begins_with("chars="):
			chars_only = a.substr(6).split(",")
	rig = Rig.new()
	rig.build()
	pal = Pal.make()
	mat = ShaderMaterial.new()
	mat.shader = load("res://assets/voxel_unit.gdshader")
	# ---- 专属身体(按需加载，不进场景)
	for cid: String in char_ids():
		if not chars_only.is_empty() and not (cid in chars_only):
			continue
		var script: GDScript = load("%s/%s.gd" % [CHARS_DIR, cid])
		var consts: Dictionary = script.get_script_constant_map()
		var hair: Array = consts.get("HAIR", [])
		var cls := {}
		for hx: String in hair:
			for f: float in [1.0, 0.92, 0.86, 0.45]:          # 0.45 = 男性眉毛(face_male 的 brow 取发色暗部 × 0.45)
				cls[VGrid.shade(VGrid.hexc(hx), f)] = 3
		var native: Color = Color(str(hair[0])) if not hair.is_empty() else Color("#eeeae9")
		# 男性款(const MALE := true)记进网格元数据：游戏里据此播男性的待机/跑步姿态(UnitSkin)
		# 怪物的"身份"表现(const IDENTITY := {"rim": "#rrggbb", "rim_k": 强度, "pulse": 熔岩脉动幅度})也记进网格元数据：UnitSkin 设成着色器参数
		_mesh("unit_body_" + cid, func(g) -> void: script.new(g, rig).build(), true, cls, native, not chars_only.is_empty(), bool(consts.get("MALE", false)),
			consts.get("IDENTITY", {}))
	if not chars_only.is_empty():
		print("chars built: ", ",".join(chars_only), " in %d ms" % (Time.get_ticks_msec() - t0))
		quit()
		return
	var parts := {}         # 部件名 -> 资源路径
	var W := func(g) -> Object: return Weapons.new(g, rig, pal)
	parts["Body"] = _mesh("unit_body", func(g) -> void:
		Body.new(g, pal).build()
		Head.new(g, rig, pal).build(), true)
	parts["Shield"] = _mesh("prop_shield", func(g) -> void: Props.new(g, rig, pal).build_shield(), true)
	parts["Shield_tower"] = _mesh("prop_shield_tower", func(g) -> void: Props.new(g, rig, pal).build_tower_shield(), true)
	parts["Shield_lily"] = _mesh("prop_shield_lily", func(g) -> void: Props.new(g, rig, pal).build_lily_shield(), true)
	parts["W_sword_plain"] = _mesh("wpn_sword_plain", func(g) -> void: W.call(g).sword_plain(), true)
	parts["W_sword_ornate"] = _mesh("wpn_sword_ornate", func(g) -> void: Props.new(g, rig, pal).build_sword(), true)
	parts["W_polearm_plain"] = _mesh("wpn_polearm_plain", func(g) -> void: W.call(g).polearm(false), true)
	parts["W_polearm_ornate"] = _mesh("wpn_polearm_ornate", func(g) -> void: W.call(g).polearm(true), true)
	parts["W_heavy_plain"] = _mesh("wpn_heavy_plain", func(g) -> void: W.call(g).heavy(false), true)
	parts["W_heavy_ornate"] = _mesh("wpn_heavy_ornate", func(g) -> void: W.call(g).heavy(true), true)
	parts["W_dual_plain"] = _mesh("wpn_dual_plain", func(g) -> void: W.call(g).dagger(false, false), true)
	parts["W_dual_ornate"] = _mesh("wpn_dual_ornate", func(g) -> void: W.call(g).dagger(true, false), true)
	parts["L_dual_plain"] = _mesh("wpn_dual_plain_l", func(g) -> void: W.call(g).dagger(false, true), true)
	parts["L_dual_ornate"] = _mesh("wpn_dual_ornate_l", func(g) -> void: W.call(g).dagger(true, true), true)
	parts["W_dual_wolf"] = _mesh("wpn_dual_wolf", func(g) -> void: W.call(g).wolf_blade(false), true)
	parts["W_dual_fan"] = _mesh("wpn_dual_fan", func(g) -> void: W.call(g).fan(false), true)
	parts["W_polearm_meteor"] = _mesh("wpn_polearm_meteor", func(g) -> void: W.call(g).meteor_staff(), true)
	parts["W_polearm_cane"] = _mesh("wpn_polearm_cane", func(g) -> void: W.call(g).cane(), true)
	parts["L_dual_fan"] = _mesh("wpn_dual_fan_l", func(g) -> void: W.call(g).fan(true), true)
	parts["L_dual_wolf"] = _mesh("wpn_dual_wolf_l", func(g) -> void: W.call(g).wolf_blade(true), true)
	parts["W_dual_blink"] = _mesh("wpn_dual_blink", func(g) -> void: W.call(g).blink_knife(false), true)
	parts["L_dual_blink"] = _mesh("wpn_dual_blink_l", func(g) -> void: W.call(g).blink_knife(true), true)
	parts["W_bow_plain"] = _mesh("wpn_bow_plain", func(g) -> void: W.call(g).bow_plain(), true)
	parts["W_bow_ornate"] = _mesh("wpn_bow_ornate", func(g) -> void: BowModel.new(g, rig, pal).build(), true)
	parts["W_crossbow_plain"] = _mesh("wpn_crossbow_plain", func(g) -> void: W.call(g).crossbow(false), true)
	parts["W_crossbow_ornate"] = _mesh("wpn_crossbow_ornate", func(g) -> void: W.call(g).crossbow(true), true)
	parts["W_pistols_plain"] = _mesh("wpn_pistols_plain", func(g) -> void: W.call(g).pistol(false, false), true)
	parts["W_pistols_ornate"] = _mesh("wpn_pistols_ornate", func(g) -> void: W.call(g).pistol(true, false), true)
	parts["L_pistols_plain"] = _mesh("wpn_pistols_plain_l", func(g) -> void: W.call(g).pistol(false, true), true)
	parts["L_pistols_ornate"] = _mesh("wpn_pistols_ornate_l", func(g) -> void: W.call(g).pistol(true, true), true)
	parts["W_rifle_plain"] = _mesh("wpn_rifle_plain", func(g) -> void: W.call(g).rifle(false), true)
	parts["W_rifle_ornate"] = _mesh("wpn_rifle_ornate", func(g) -> void: W.call(g).rifle(true), true)
	parts["W_focus_plain"] = _mesh("wpn_focus_plain", func(g) -> void: W.call(g).focus_plain(), true)
	parts["W_focus_ornate"] = _mesh("wpn_focus_ornate", func(g) -> void: W.call(g).focus_orb(), true)
	parts["W_focus_tome"] = _mesh("wpn_focus_tome", func(g) -> void: W.call(g).focus_tome(), true)
	parts["W_focus_notes"] = _mesh("wpn_focus_notes", func(g) -> void: W.call(g).notes(), true)
	parts["W_focus_electro"] = _mesh("wpn_focus_electro", func(g) -> void: W.call(g).electro_book(), true)
	parts["W_rifle_arbalest"] = _mesh("wpn_rifle_arbalest", func(g) -> void: W.call(g).arbalest(), true)
	parts["W_rifle_drive"] = _mesh("wpn_rifle_drive", func(g) -> void: W.call(g).drive_rifle(), true)
	parts["W_polearm_rake"] = _mesh("wpn_polearm_rake", func(g) -> void: W.call(g).rake(), true)
	parts["W_heavy_blood"] = _mesh("wpn_heavy_blood", func(g) -> void: W.call(g).blood_greatsword(), true)
	parts["W_pistols_stunner"] = _mesh("wpn_pistols_stunner", func(g) -> void: W.call(g).stunner(false), true)
	parts["L_pistols_stunner"] = _mesh("wpn_pistols_stunner_l", func(g) -> void: W.call(g).stunner(true), true)
	parts["W_pistols_butterfly"] = _mesh("wpn_pistols_butterfly", func(g) -> void: W.call(g).butterfly_pistol(false), true)
	parts["L_pistols_butterfly"] = _mesh("wpn_pistols_butterfly_l", func(g) -> void: W.call(g).butterfly_pistol(true), true)
	parts["W_focus_syringe"] = _mesh("wpn_focus_syringe", func(g) -> void: W.call(g).syringe(), true)
	parts["W_polearm_banner"] = _mesh("wpn_polearm_banner", func(g) -> void: W.call(g).banner(), true)
	parts["W_polearm_hunt_flag"] = _mesh("wpn_polearm_hunt_flag", func(g) -> void: W.call(g).hunt_flag(), true)
	parts["W_polearm_starflag"] = _mesh("wpn_polearm_starflag", func(g) -> void: W.call(g).starflag(), true)
	parts["W_heavy_prism"] = _mesh("wpn_heavy_prism", func(g) -> void: W.call(g).prism_scythe(), true)
	parts["W_dual_volt"] = _mesh("wpn_dual_volt", func(g) -> void: W.call(g).volt_glove(false), true)
	parts["L_dual_volt"] = _mesh("wpn_dual_volt_l", func(g) -> void: W.call(g).volt_glove(true), true)
	parts["W_dual_slips"] = _mesh("wpn_dual_slips", func(g) -> void: W.call(g).bamboo_slips(false), true)
	parts["W_focus_grimoire"] = _mesh("wpn_focus_grimoire", func(g) -> void: W.call(g).grimoire(), true)
	parts["L_dual_slips"] = _mesh("wpn_dual_slips_l", func(g) -> void: W.call(g).bamboo_slips(true), true)
	parts["W_dual_coin"] = _mesh("wpn_dual_coin", func(g) -> void: W.call(g).coin_dagger(false), true)
	parts["L_dual_coin"] = _mesh("wpn_dual_coin_l", func(g) -> void: W.call(g).coin_dagger(true), true)
	parts["W_sword_wrench"] = _mesh("wpn_sword_wrench", func(g) -> void: W.call(g).wrench(), true)
	parts["W_focus_talisman"] = _mesh("wpn_focus_talisman", func(g) -> void: W.call(g).talisman(), true)
	parts["W_crossbow_revolver"] = _mesh("wpn_crossbow_revolver", func(g) -> void: W.call(g).revolver(), true)
	parts["W_sword_katana"] = _mesh("wpn_sword_katana", func(g) -> void: W.call(g).katana(), true)
	parts["A_sword_katana"] = _mesh("wpn_sword_katana_saya", func(g) -> void: W.call(g).katana_saya(), true)
	parts["W_bow_short"] = _mesh("wpn_bow_short", func(g) -> void: W.call(g).bow_short(), true)
	parts["W_bow_farthest"] = _mesh("wpn_bow_farthest", func(g) -> void: W.call(g).bow_farthest(), true)
	parts["W_polearm_ember_glaive"] = _mesh("wpn_polearm_ember_glaive", func(g) -> void: W.call(g).ember_glaive(), true)
	parts["W_polearm_lily"] = _mesh("wpn_polearm_lily", func(g) -> void: W.call(g).lily_spear(), true)
	parts["W_polearm_verdant"] = _mesh("wpn_polearm_verdant", func(g) -> void: W.call(g).verdant_staff(), true)
	parts["W_polearm_dice"] = _mesh("wpn_polearm_dice", func(g) -> void: W.call(g).dice_staff(), true)
	parts["W_polearm_key"] = _mesh("wpn_polearm_key", func(g) -> void: W.call(g).key_staff(), true)
	parts["W_bow_lute"] = _mesh("wpn_bow_lute", func(g) -> void: W.call(g).lute(), true)
	parts["P_bard_lute"] = _mesh("prop_bard_lute", func(g) -> void: W.call(g).lute_prop(), true)
	parts["W_focus_censer"] = _mesh("wpn_focus_censer", func(g) -> void: W.call(g).censer(), true)
	parts["W_heavy_clot"] = _mesh("wpn_heavy_clot", func(g) -> void: W.call(g).clotted_blade(), true)
	parts["W_heavy_warhammer"] = _mesh("wpn_heavy_warhammer", func(g) -> void: W.call(g).warhammer(), true)
	parts["W_heavy_odachi"] = _mesh("wpn_heavy_odachi", func(g) -> void: W.call(g).odachi(false), true)
	parts["W_heavy_odachi_drawn"] = _mesh("wpn_heavy_odachi_drawn", func(g) -> void: W.call(g).odachi(true), true)
	parts["W_focus_lightheart"] = _mesh("wpn_focus_lightheart", func(g) -> void: W.call(g).light_heart(), true)
	parts["W_rifle_sniper"] = _mesh("wpn_rifle_sniper", func(g) -> void: W.call(g).sniper_rifle(), true)
	parts["W_crossbow_blackmission"] = _mesh("wpn_crossbow_blackmission", func(g) -> void: W.call(g).black_mission(), true)
	parts["W_sword_cyanshadow"] = _mesh("wpn_sword_cyanshadow", func(g) -> void: W.call(g).cyan_shadow(), true)
	parts["W_sword_hope"] = _mesh("wpn_sword_hope", func(g) -> void: W.call(g).hope_sword(), true)
	parts["W_sword_mic"] = _mesh("wpn_sword_mic", func(g) -> void: W.call(g).mic(), true)
	parts["P_commando_smg"] = _mesh("prop_commando_smg", func(g) -> void: W.call(g).black_mission(), true)
	parts["P_commando_knife"] = _mesh("prop_commando_knife", func(g) -> void: W.call(g).commando_knife(), true)
	parts["P_hunter_rod"] = _mesh("prop_hunter_rod", func(g) -> void: W.call(g).hunter_rod(), true)
	parts["W_focus_rainbow"] = _mesh("wpn_focus_rainbow", func(g) -> void: W.call(g).rainbow_flower(), true)
	parts["W_focus_rosary"] = _mesh("wpn_focus_rosary", func(g) -> void: W.call(g).rosary(), true)
	# 通用武器(没有主人、谁都能装的专属外观)
	parts["W_focus_candelabra"] = _mesh("wpn_focus_candelabra", func(g) -> void: W.call(g).candelabra(), true)
	parts["W_sword_rally"] = _mesh("wpn_sword_rally", func(g) -> void: W.call(g).rally_sword(), true)
	parts["W_rifle_spotter"] = _mesh("wpn_rifle_spotter", func(g) -> void: W.call(g).spotter_rifle(), true)
	parts["W_heavy_rockbreaker"] = _mesh("wpn_heavy_rockbreaker", func(g) -> void: W.call(g).rockbreaker(), true)
	parts["W_sword_moon"] = _mesh("wpn_sword_moon", func(g) -> void: W.call(g).moon_sword(), true)
	# 通用武器 · 第二批
	parts["W_focus_lantern"] = _mesh("wpn_focus_lantern", func(g) -> void: W.call(g).focus_lantern(), true)
	parts["W_focus_requiem"] = _mesh("wpn_focus_requiem", func(g) -> void: W.call(g).requiem_focus(), true)
	parts["W_dual_fang"] = _mesh("wpn_dual_fang", func(g) -> void: W.call(g).fang_dagger(false), true)
	parts["L_dual_fang"] = _mesh("wpn_dual_fang_l", func(g) -> void: W.call(g).fang_dagger(true), true)
	parts["W_rifle_keeneye"] = _mesh("wpn_rifle_keeneye", func(g) -> void: W.call(g).keeneye_rifle(), true)
	parts["W_sword_echo"] = _mesh("wpn_sword_echo", func(g) -> void: W.call(g).echo_sword(), true)
	parts["W_focus_capacitor"] = _mesh("wpn_focus_capacitor", func(g) -> void: W.call(g).focus_capacitor(), true)
	# 通用武器 · 第三批：法器
	parts["W_focus_kaleido"] = _mesh("wpn_focus_kaleido", func(g) -> void: W.call(g).kaleido_focus(), true)
	parts["W_focus_stardust"] = _mesh("wpn_focus_stardust", func(g) -> void: W.call(g).stardust_focus(), true)
	parts["W_focus_chord"] = _mesh("wpn_focus_chord", func(g) -> void: W.call(g).chord_focus(), true)
	parts["W_focus_mirror"] = _mesh("wpn_focus_mirror", func(g) -> void: W.call(g).mirror_focus(), true)
	parts["W_focus_erudite"] = _mesh("wpn_focus_erudite", func(g) -> void: W.call(g).erudite_focus(), true)
	# 通用武器 · 第四批：手枪(双持：右手 W_ + 左手 L_)
	parts["W_pistols_flintlock"] = _mesh("wpn_pistols_flintlock", func(g) -> void: W.call(g).flintlock_pistol(false), true)
	parts["L_pistols_flintlock"] = _mesh("wpn_pistols_flintlock_l", func(g) -> void: W.call(g).flintlock_pistol(true), true)
	parts["W_pistols_chakram"] = _mesh("wpn_pistols_chakram", func(g) -> void: W.call(g).chakram_ring(false), true)
	parts["L_pistols_chakram"] = _mesh("wpn_pistols_chakram_l", func(g) -> void: W.call(g).chakram_ring(true), true)
	parts["W_pistols_cards"] = _mesh("wpn_pistols_cards", func(g) -> void: W.call(g).fortune_cards(false), true)
	parts["L_pistols_cards"] = _mesh("wpn_pistols_cards_l", func(g) -> void: W.call(g).fortune_cards(true), true)
	parts["W_pistols_bubble"] = _mesh("wpn_pistols_bubble", func(g) -> void: W.call(g).bubble_blaster(false), true)
	parts["L_pistols_bubble"] = _mesh("wpn_pistols_bubble_l", func(g) -> void: W.call(g).bubble_blaster(true), true)
	parts["W_pistols_bells"] = _mesh("wpn_pistols_bells", func(g) -> void: W.call(g).resonance_bell(false), true)
	parts["L_pistols_bells"] = _mesh("wpn_pistols_bells_l", func(g) -> void: W.call(g).resonance_bell(true), true)
	# 通用武器 · 分批文件(三批一组并行做：tools/weapons/<批>_models.gd，extends model_weapons.gd；
	# PARTS = {部件名: [资源名, 方法名, 参数…]}，比如 {"W_crossbow_x": ["wpn_crossbow_x", "x_bow", false]})
	for bp: String in BATCH_MODELS:
		var BS: GDScript = load(bp)
		var plist: Dictionary = BS.PARTS
		for pn: String in plist.keys():
			var spec: Array = plist[pn]
			var meth: String = str(spec[1])
			var margs: Array = spec.slice(2)
			parts[pn] = _mesh(str(spec[0]), func(g) -> void: BS.new(g, rig, pal).callv(meth, margs), true)
	# 黑键 / 白键(变奏节点)：别人拿 = 托在手上的小钢琴(挂 Bow)；她本人拿 = 大三角钢琴(整台挂 Root，放在她身前；恶魔形态黑键 / 天使形态白键)
	parts["W_focus_piano"] = _mesh("wpn_focus_piano", func(g) -> void: W.call(g).piano_small(), true)
	parts["W_focus_grand"] = _mesh("wpn_focus_grand", func(g) -> void: W.call(g).grand_piano(false), true)
	parts["W_focus_grand_white"] = _mesh("wpn_focus_grand_white", func(g) -> void: W.call(g).grand_piano(true), true)
	_mesh("prop_arrow", func(g) -> void: BowModel.new(g, rig, pal).build_arrow_only(), false)

	var root := Node3D.new()
	root.name = "UnitModel"
	var sk: Skeleton3D = rig.make_skeleton()
	root.add_child(sk)
	var skin: Skin = sk.create_skin_from_rest_transforms()
	var names: Array = parts.keys()
	for nm: String in names:
		var mi := MeshInstance3D.new()
		mi.name = nm
		mi.mesh = load(parts[nm])
		mi.mesh.surface_set_material(0, mat)
		sk.add_child(mi)
		mi.skin = skin
		mi.skeleton = NodePath("..")
		mi.custom_aabb = AABB(Vector3(-2, -0.5, -2), Vector3(4, 4, 4))
		mi.visible = nm == "Body"
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	root.add_child(ap)
	if ResourceLoader.exists("res://assets/archer_anims.res"):
		ap.add_animation_library("", load("res://assets/archer_anims.res"))
	_own(root, root)
	var ps := PackedScene.new()
	ps.pack(root)
	ResourceSaver.save(ps, "res://scenes/unit_model.tscn")
	print("kits built (%d parts) in %d ms" % [names.size(), Time.get_ticks_msec() - t0])
	quit()


## hair_cls：额外归为发色类别的颜色；hair_native：原发色(存进网格元数据，游戏里换发色时按它的亮度保留明暗)
func _mesh(name: String, sculpt: Callable, skinned: bool, hair_cls: Dictionary = {}, hair_native: Color = Color("#eeeae9"), force: bool = false, male: bool = false,
		identity: Dictionary = {}) -> String:
	var path0 := "res://assets/%s.res" % name
	if not force and not only.is_empty() and not (name in only) and ResourceLoader.exists(path0):
		return path0
	var g = VGrid.new(Vector3i(-64, -16, -56), Vector3i(63, 140, 55), rig.ids, rig.mirror_of)
	sculpt.call(g)
	var m = Mesher.new(g, rig)
	m.skinned = skinned
	m.color_class = Pal.classes()
	m.color_class.merge(hair_cls, true)
	var mesh: ArrayMesh = m.build()
	mesh.surface_set_material(0, mat)
	mesh.custom_aabb = AABB(Vector3(-2, -0.5, -2), Vector3(4, 4, 4))
	mesh.set_meta("hair_native", hair_native)
	mesh.set_meta("male", male)
	mesh.set_meta("identity", identity)
	var path := "res://assets/%s.res" % name
	ResourceSaver.save(mesh, path, ResourceSaver.FLAG_COMPRESS)
	print("  ", name, ": voxels ", g.count_solid(), " oob ", g.oob_count, " quads ", m.stats["quads"])
	return path


## tools/chars/ 下的专属模型名(文件名；_ 开头的不算)
static func char_ids() -> Array[String]:
	var r: Array[String] = []
	for f: String in DirAccess.get_files_at(CHARS_DIR):
		if f.ends_with(".gd") and not f.begins_with("_"):
			r.append(f.get_basename())
	r.sort()
	return r


func _own(n: Node, o: Node) -> void:
	for c in n.get_children():
		c.owner = o
		_own(c, o)
