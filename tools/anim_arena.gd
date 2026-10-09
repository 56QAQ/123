extends SceneTree
## 动作审片场：在第零章的地图上摆一个指定武器的我方棋子 + 几个敌人，相机拉近跟拍，逐帧存 PNG(配 --fixed-fps 30 拼 gif)。
## 看的是游戏里真实的表现：动画 + 顿帧 + 蓄力光点 + 投射物 + 斩击特效一起。
## godot --path . --fixed-fps 30 --script res://tools/anim_arena.gd -- wclass=bow def=node_archer foes=2 t0=0.5 t1=5 seq=res://out/seq/a
##   fd     敌人站在前方多少米(挤成一团；看冲锋类技能)
##   cz     相机注视点在我方前方多少米(默认 0.8；看落点特效时调大)
##   foes   敌人个数(站成一排；wclass=polearm 时排成一条直线，方便看贯穿)   dist 相机距离(默认 6.5)   pitch / yaw 相机角度
##   out    不给 seq 时，按 times= 截图拼表
##   weapon 我方武器 id(默认 basic_<wclass>)   hurt=0.55 在 hurt_at 秒(默认 1)时让我方掉这么多比例的生命(看"低血触发"的装备效果，如丰收的稻田)；hurt_every=2 之后每隔 2 秒再来一下
##   ally=node_shielder 在我方和敌人之间再摆一个我方棋子(看治疗类普攻，如护理节点)；ally_hurt=0.08 每秒让它掉这么多比例的生命；
##   ally_burn=1 每 2 秒给它挂一层可驱散的【燃烧】(看一对一看护的净化)；ally_kill=5 第 5 秒把它打死(看复活：执剑节点的与你，再度飞翔)
##   drop=1 我方棋子从仓库坠落到敌人中间(星旅节点)
##   charges=1 我方棋子带【充能】的被动只剩 N 层(看充能用光才放的大招)
##   allies=node_archer,node_magi 在我方身后再摆一排队友(看直线范围技能)
##   real=1 敌人用 foe= 指定的真单位(会还手，看怪物的攻击 / 技能特效；foe_star=星级)
##   foe_hp=1500 木桩的生命(默认打不死；清扫节点的飞刀要打得死才放出去)   rusher=node_samurai 再从前方远处放一个真的敌人冲过来(看女仆护身术的瞬移)
##   back=mob_archer:2 [back_d=7] 后面再放几个真的敌人(看踏影节点的逆光)
##   arc=30 敌人在她前方 fd 米的圆弧上排开(相邻隔 30 度：看转身 / 换目标；屏息节点的狙击窝)
##   pstatus=node_noble_lily:12 开打时按我方棋子某个被动的状态配置直接给 N 层(正行节点满层花瓣 → 马上再绽；node_vampire_lust:12 → 马上至亲的故事)
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cell := String(args.get("cell", "720x540")).split("x")
	var sv := SubViewport.new()
	sv.size = Vector2i(int(cell[0]), int(cell[1]))
	sv.msaa_3d = Viewport.MSAA_4X
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var world := GameWorld.new()
	sv.add_child(world)
	await process_frame
	await process_frame
	var cat := Catalog.load_all()
	# 木桩：拿祭坛守卫的外观，空手(不会攻击)、不会走、血很厚——只挨打
	var src: UnitDef = cat.get_unit(String(args.get("foe", "mob_guardian")))
	var dummy := UnitDef.from_dict({"id": "arena_dummy", "role": "tank", "faction_id": src.faction_id, "base_weapon_class": "",
		"model": src.model, "hair": src.hair, "skin": src.skin, "available_in_shop": false})
	dummy.radius = src.radius                        # 体型照抄(看非常规体型敌人身上的特效：foe=elite_ember_vanity 之类)
	dummy.scale = src.scale
	dummy.base_stats.max_health = float(args.get("foe_hp", "99999"))
	dummy.base_stats.move_speed = 0.0
	dummy.strings_key = src.strings_key if src.strings_key != "" else "unit." + src.id
	cat.units["arena_dummy"] = dummy
	var run := Run.create(cat, 5)
	run.node_index = 0
	run.phase = "map"
	run.travel()
	var layout: Dictionary = run.current_layout().duplicate(true)
	layout["obstacles"] = []                         # 空场地：不让断壁挡镜头、挡视线
	if args.has("red"):
		layout["theme"] = "red"                      # red=1：红之章的地面(看火系特效在暗地面上的样子)
	if args.has("theme"):
		layout["theme"] = String(args["theme"])      # theme=blue / purple：别的章节的地面
		layout["embers"] = []
		layout["burning"] = []
	world.show_battlefield(layout, 5)
	var wc: String = String(args.get("wclass", "bow"))
	var me := Vector2(float(args.get("x", "-5.5")), float(args.get("z", "3.5")))
	var units: Array = [{"def": String(args.get("def", "node_archer")), "team": 0, "star": int(args.get("star", "2")), "pos": me, "weapon": String(args.get("weapon", "basic_" + wc))}]
	if args.has("selfless"):
		units[0]["selfless"] = true                  # selfless=1：无我节点点过按钮的那一场(开战拔刀清场)
	var reach: float = float(GC.weapon_class(wc)["range"]) * GC.RANGE_UNIT
	var n: int = int(args.get("foes", "2"))
	for i in range(n):
		var fp: Vector2
		if args.has("arc"):
			# arc=度数：敌人在她前方 fd 米的圆弧上一字排开(相邻两个隔这么多度；看转身 / 换目标)
			var aa: float = deg_to_rad((float(i) - (n - 1) * 0.5) * float(args["arc"]))
			fp = me + Vector2(sin(aa), cos(aa)) * float(args.get("fd", "5"))
		elif args.has("fd"):
			fp = me + Vector2((float(i) - (n - 1) * 0.5) * 0.8, float(args["fd"]) + 0.45 * float(i % 2))
		elif wc == "polearm" or args.has("line"):
			fp = me + Vector2(0.0, 1.1 + 0.75 * i)
		else:
			fp = me + Vector2((float(i) - (n - 1) * 0.5) * 1.0, maxf(1.0, minf(reach * 0.8, 3.0)))
		# real=1：敌人用真的单位(会攻击、放技能；看怪物的攻击动作与特效)，否则是打不还手的木桩
		if args.has("real"):
			units.append({"def": src.id, "team": 1, "star": int(args.get("foe_star", "1")), "pos": fp, "weapon": "",
				"boss": src.id.begins_with("boss_"), "elite": src.id.begins_with("elite_")})
		else:
			units.append({"def": "arena_dummy", "team": 1, "star": 1, "pos": fp, "weapon": ""})
	# drop=1：我方棋子从仓库坠落(星旅节点·渡星而来)：落点 = 敌人最密集的地方，镜头对着落点
	if args.has("drop"):
		var fps: Array[Vector2] = []
		for ue: Dictionary in units:
			if int(ue["team"]) == 1:
				fps.append(ue["pos"])
		var ddef: UnitDef = cat.get_unit(String(args.get("def", "node_archer")))
		var land: Vector2 = Targeting.densest_point(fps, ddef.passive_splash_radius(int(args.get("star", "2"))), null, ddef.radius)
		units[0]["pos"] = land
		units[0]["drop"] = true
		me = land - Vector2(0.0, float(args.get("cz", "0.8")))
	if args.has("rusher"):
		units.append({"def": String(args["rusher"]), "team": 1, "star": 1, "pos": me + Vector2(1.5, 6.0), "weapon": ""})
	# back=mob_archer:2 在后面 back_d 米处再放几个真的敌人(踏影节点的逆光要有远程敌人才会瞬移过去)
	if args.has("back"):
		# 可以写几种：back=mob_sg_sentry:1,mob_rx_relay:2(全部排成一排)
		var bl: Array = []
		for part: String in String(args["back"]).split(","):
			var bk: PackedStringArray = part.split(":")
			for bi in range(int(bk[1]) if bk.size() > 1 else 1):
				bl.append(bk[0])
		for bi in range(bl.size()):
			units.append({"def": bl[bi], "team": 1, "star": 1, "pos": me + Vector2((float(bi) - (bl.size() - 1) * 0.5) * 1.6, float(args.get("back_d", "7"))), "weapon": "",
				"boss": String(bl[bi]).begins_with("boss_"), "elite": String(bl[bi]).begins_with("elite_")})
	if args.has("ally"):
		units.append({"def": String(args["ally"]), "team": 0, "star": int(args.get("star", "2")), "pos": me + Vector2(0.7, 1.5), "weapon": ""})
	# allies=a,b,c：再摆一排我方棋子(在我方身后左右散开；看龙息这种直线范围技能扫到一排人)
	var extra: PackedStringArray = String(args.get("allies", "")).split(",", false)
	for ai in range(extra.size()):
		units.append({"def": extra[ai], "team": 0, "star": int(args.get("star", "2")), "pos": me + Vector2((float(ai) - float(extra.size() - 1) * 0.5) * 1.3, -1.6 - 0.6 * float(ai % 2)), "weapon": ""})
	var setup := {"units": units, "map": layout, "cfg": {}}
	world.battle_view.speed = float(args.get("speed", "1"))
	world.battle_view.start(setup, cat, 7)
	if args.has("charges"):
		# charges=1：我方棋子带【充能】的被动只剩这么多层(看充能用光才放的大招)
		var cu0: BUnit = world.battle_view.battle.units[0]
		for pa: AbilityDef in cu0.def.passives:
			if pa.has_keyword("charged"):
				cu0.ability_charges[pa.id] = int(args["charges"])
	for uid: String in world.battle_view.views.keys():
		(world.battle_view.views[uid] as UnitView).set_bar_visible(false)
	world.rig.set_view(Vector3(me.x, 0.6, me.y + float(args.get("cz", "0.8"))), float(args.get("yaw", "25")), float(args.get("pitch", "38")), float(args.get("dist", "6.5")), true)
	var seq: String = String(args.get("seq", ""))
	var t0: float = float(args.get("t0", "0.5"))
	var t1: float = float(args.get("t1", "5"))
	var k := 0
	var frames := 0
	var hurt: float = float(args.get("hurt", "0"))
	var hurt_at: float = float(args.get("hurt_at", "1"))
	while frames < 20000:
		await process_frame
		frames += 1
		var b: Battle = world.battle_view.battle
		var el: float = b.time if b != null else 0.0
		if args.has("pstatus") and b != null and b.state == "running":
			var pu: BUnit = b.units[0]
			for ps: String in String(args["pstatus"]).split(","):
				var kv2: PackedStringArray = ps.split(":")
				var pa2: AbilityDef = pu.def.passive_by_id(kv2[0])
				if pa2 != null:
					var pc: Dictionary = pa2.effect_config.duplicate(true)
					pc["add_stacks"] = int(kv2[1]) if kv2.size() > 1 else 1
					pc["max_stacks"] = maxi(int(pc.get("max_stacks", 0)), pa2.keyword_value("stacking", pu.star, int(pc["add_stacks"])))
					b.pipeline.fx.apply_status(pu, pu, pc)
			args.erase("pstatus")
		if args.has("ally_kill") and b != null and b.state == "running" and el >= float(args["ally_kill"]):
			var ak: BUnit = b.units[b.units.size() - 1]
			if ak.alive:
				b.pipeline.fx.damage(b.units[1], ak, ak.hp + ak.shield + 99999.0, "true")
			args.erase("ally_kill")
		if args.has("ally") and b != null and b.state == "running":
			var au: BUnit = b.units[b.units.size() - 1]
			var tick: int = int(el)
			if au.alive and tick != int(au.meta.get("_arena_tick", -1)):
				au.meta["_arena_tick"] = tick
				au.hp = maxf(1.0, au.hp - au.get_stats().max_health * float(args.get("ally_hurt", "0.08")))
				if args.has("ally_burn") and tick % 2 == 0:
					b.pipeline.fx.apply_status(null, au, {"status_id": "burning", "independent": true, "duration": 6.0, "flags": ["debuff", "dispellable"]})
		if hurt > 0.0 and b != null and el >= hurt_at:
			var mu: BUnit = b.units[0]
			b.pipeline.fx.damage(b.units[1], mu, mu.get_stats().max_health * hurt, "true")
			if args.has("hurt_every"):
				hurt_at += float(args["hurt_every"])      # hurt_every=2：每隔这么多秒再打一下(看守林节点一次次变身)
			else:
				hurt = 0.0
		if el >= t0 and seq != "":
			var fr: Image = sv.get_texture().get_image()
			fr.convert(Image.FORMAT_RGB8)
			fr.save_png("%s_%03d.png" % [seq, k])
			if args.has("animlog"):                  # 每帧打印我方棋子正在播的动作(查交叉淡化 / 状态切换)
				var hv: UnitView = world.battle_view.views.get(b.units[0].uid) as UnitView
				if hv != null:
					print("ANIM %03d t=%.2f %s @%.2f phase=%s yaw=%.1f spd=%.2f" % [k, el, hv.ap.current_animation, hv.ap.current_animation_position, b.units[0].phase,
						rad_to_deg(hv.rotation.y), hv.ap.speed_scale])
			k += 1
		if el >= t1 or b == null or b.state == "ended":
			break
	print("saved %d frames to %s_*.png" % [k, seq])
	quit()
