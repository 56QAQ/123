extends SceneTree
## 离屏预览一场战斗并按时间截图(第零章的地图节点：卡车 + 断壁残垣)。
## 用法: -- times=0.5,3,6 out=res://out/b.png cell=960x540 speed=1 node=3 raid=0
##   dist=12 target=0:1 pitch=56 yaw=0  相机拉近/对准某处；seq=res://out/seq/b t0=2 t1=6  逐帧存 PNG(配 --fixed-fps 30 做 gif)
##   add=node_runner:lightning_gloves:2  再往我方加一个棋子(武器、星级可省)，站在卡车左边；ehp=4 敌人生命 ×4(看慢热的技能)
##   magi=1  幻彩节点 2 星 + 幻彩镰刀，不按 times 截，改成按她的进度截：吟唱 1.5 秒 / 6 秒、终结一击后 0.05 / 0.3 / 0.9 秒(看黑白领域与闪烁)
##   wseq=res://out/x/f [every=2] 逐帧存：从她开始吟唱到阵亡后 1.5 秒(配 magi=1 / watch=…)；theme=red 换红之章的地面
##   watch=node_spy  同样按这个棋子的进度截(吟唱 1.5 / 6 秒、阵亡后 0.05 / 0.3 / 0.9 秒)；charges=N 开打时把它带【充能】的被动设成只剩 N 层
##   (千变万化只能站敌人身边：add 进来的这种棋子会放在敌人身边的格子上)
##   follow=node_warden  镜头每帧跟着我方这个棋子；wforms=1(配 follow=node_warden)：每次变身后 0.15 / 0.9 秒各截一张；wskip=N 开局后直接跳过 N 个形态
##   selfless=1(配 add=node_killer:…)：这一场算点过无我的按钮
##   on_status=<状态 id> [n=2](配 follow=…)：这个棋子身上出现这个状态后 0.3 / 0.38 / 0.55 / 0.9 秒各截一张(看圣战节点的裂地猛击)
##   release=N(配 follow=…)：这个棋子吟唱(拉弓)结束出手后 0.02 / 0.07 / 0.14 秒各截一张，截 N 次出手(看导向节点的连锁闪电)
##   noble=1  配 add=node_noble:true_flower:2：开打给她满层花瓣，按吟唱 / 花开 / 第一道光刃截图(看正行节点的特效)
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	var times: PackedStringArray = String(args.get("times", "1.5,4,8,12")).split(",")
	var cell := String(args.get("cell", "960x540")).split("x")
	var cw := int(cell[0])
	var ch := int(cell[1])
	var sv := SubViewport.new()
	sv.size = Vector2i(cw, ch)
	sv.msaa_3d = Viewport.MSAA_4X
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var world := GameWorld.new()
	sv.add_child(world)
	await process_frame
	await process_frame
	var cat := Catalog.load_all()
	# 第零章的某个地图节点(node=1..3，默认 3：有祭坛)；raid=1 时我方只派一个人，用来看敌人冲进卡车
	var run := Run.create(cat, int(args.get("seed", "5")))
	var node: int = clampi(int(args.get("node", "3")), 1, run.total_nodes())
	run.node_index = node - 1
	run.phase = "map"
	run.travel()
	var lay: Dictionary = run.current_layout().duplicate(true)
	if args.has("theme"):
		lay["theme"] = str(args["theme"])          # theme=red：换成红之章的地面看特效
	world.show_battlefield(lay, 5)
	if args.get("raid", "0") == "1":
		for id: String in run.roster.keys():
			if run.roster[id]["def"] == "node_darkknight":
				run.sell(id)
	if args.get("raid", "0") != "1":
		var extra := [["node_magi", Vector2i(10, 11)], ["node_nurse", Vector2i(12, 11)], ["node_berserker", Vector2i(14, 11)]]
		for e: Array in extra:
			var mu: Dictionary = run.add_unit(e[0], 2 if (e[0] == "node_magi" and args.has("magi")) else 1, e[1], -1)
			if e[0] == "node_magi" and args.has("magi"):
				run.inventory.append("prism_scythe")
				run.equip(str(mu["id"]), "prism_scythe")
		for id2: String in run.roster.keys():
			var d: String = run.roster[id2]["def"]
			if d == "node_archer":
				run.equip(id2, "rapidfire_arbalest")
			elif d == "node_darkknight":
				run.equip(id2, "blackblade")
	if args.has("add"):
		var ad: PackedStringArray = String(args["add"]).split(":")
		var cell0 := Vector2i(9, 10)
		if cat.get_unit(ad[0]).deploy_near_enemies and not run.near_enemy_cells().is_empty():
			cell0 = run.near_enemy_cells().keys()[0]
		var au: Dictionary = run.add_unit(ad[0], int(ad[2]) if ad.size() > 2 else 1, cell0, -1)
		if args.has("selfless"):
			au["selfless"] = true                      # selfless=1：这一场算点过无我的按钮(无我节点开场拔刀清场)
		if ad.size() > 1 and ad[1] != "":
			run.inventory.append(ad[1])
			run.equip(str(au["id"]), ad[1])
	var setup: Dictionary = run.build_battle_setup()
	if args.has("theme"):
		# theme=red / purple：这一场也算在那一章(导向节点·变天按章节换天气)，光照也换成那一章的
		(setup["cfg"] as Dictionary)["chapter_color"] = str(args["theme"])
		world.set_theme(str(args["theme"]))
		world.set_fog_far(false)
	if args.has("ehp"):
		# ehp=4：敌人生命 ×4(让战斗打得久一点，看慢热的技能)
		for ue: Dictionary in setup["units"]:
			if int(ue.get("team", 0)) == 1:
				ue["hp_mult"] = float(ue.get("hp_mult", 1.0)) * float(args["ehp"])
	world.rig.set_preset("battle", true)
	if args.has("dist"):
		var tg: PackedStringArray = String(args.get("target", "0:1")).split(":")
		world.rig.set_view(Vector3(float(tg[0]), 0.0, float(tg[1])), float(args.get("yaw", "0")), float(args.get("pitch", "56")), float(args["dist"]), true)
	world.battle_view.speed = float(args.get("speed", "1"))
	world.battle_view.start(setup, cat, 12)
	var imgs: Array = []
	var t_next := 0
	var elapsed := 0.0
	var fps := 30.0
	var frames := 0
	var seq: String = String(args.get("seq", ""))
	if seq != "":
		var t0: float = float(args.get("t0", "2"))
		var t1: float = float(args.get("t1", "6"))
		var n := 0
		while frames < 20000:
			await process_frame
			frames += 1
			elapsed = world.battle_view.battle.time if world.battle_view.battle != null else elapsed
			if elapsed >= t0:
				var fr: Image = sv.get_texture().get_image()
				fr.convert(Image.FORMAT_RGB8)
				fr.save_png("%s_%03d.png" % [seq, n])
				n += 1
			if elapsed >= t1 or world.battle_view.battle == null or world.battle_view.battle.state == "ended":
				break
		print("saved %d frames to %s_*.png" % [n, seq])
		quit()
		return
	if args.has("magi") or args.has("watch"):
		var mg: BUnit = null
		var wid: String = String(args.get("watch", "node_magi"))
		for u: BUnit in world.battle_view.battle.units:
			if u.def.id == wid and u.team == 0:
				mg = u
				if args.has("charges"):
					for pa: AbilityDef in u.def.passives:
						if pa.has_keyword("charged"):
							u.ability_charges[pa.id] = int(args["charges"])
			elif u.team != 0:
				u.base.max_health *= 8.0                 # 敌人耐打一点：撑到她吟唱完
				u.mark_dirty()
				u.hp = u.get_stats().max_health
		var t_chant := -1.0
		var t_fin := -1.0
		var marks := [1.5, 6.0]
		var fmarks := [0.05, 0.3, 0.9]
		# wseq=res://out/x/f：从吟唱开始前 0.3 秒起逐帧存到阵亡后 1.5 秒(每 every 帧存一张)
		var wseq: String = str(args.get("wseq", ""))
		var wn := 0
		var every: int = int(args.get("every", "1"))
		while frames < 9000 and mg != null and (marks.size() > 0 or fmarks.size() > 0):
			await process_frame
			frames += 1
			var bt: Battle = world.battle_view.battle
			if bt == null:
				break
			if t_chant < 0.0 and mg.phase == "chant":
				t_chant = bt.time
			if wseq != "" and t_chant >= 0.0 and frames % every == 0:
				var wf: Image = sv.get_texture().get_image()
				wf.convert(Image.FORMAT_RGB8)
				wf.save_png("%s_%03d.png" % [wseq, wn])
				wn += 1
				if t_fin >= 0.0 and bt.time > t_fin + 1.5:
					break
				if wn > 400:
					break
			if t_fin < 0.0 and (bool(mg.meta.get("finale_death", false)) or bool(mg.meta.get("hush_death", false)) or bool(mg.meta.get("funeral_death", false))):
				t_fin = bt.time
			if wseq == "" and t_chant >= 0.0 and marks.size() > 0 and t_fin < 0.0 and bt.time >= t_chant + float(marks[0]):
				imgs.append(sv.get_texture().get_image())
				marks.pop_front()
			if wseq == "" and t_fin >= 0.0 and fmarks.size() > 0 and bt.time >= t_fin + float(fmarks[0]):
				marks.clear()
				imgs.append(sv.get_texture().get_image())
				fmarks.pop_front()
			if bt.state == "ended" and t_fin < 0.0:
				break
		print("magi chant at %.2f finale at %.2f" % [t_chant, t_fin])
	if args.has("noble"):
		# noble=1(配 add=node_noble:true_flower:2)：开打就给她满层花瓣——立刻吟唱再绽之花；按她的进度截：
		# 吟唱 0.6 / 2.0 秒、花开后 0.15 秒、第一道光刃出手后 0.03 / 0.08 / 0.16 秒
		var nb: BUnit = null
		for u2: BUnit in world.battle_view.battle.units:
			if u2.def.id == "node_noble" and u2.team == 0:
				nb = u2
			elif u2.team != 0:
				u2.base.max_health *= 6.0
				u2.mark_dirty()
				u2.hp = u2.get_stats().max_health
		var given := false
		var t_ch := -1.0
		var t_bl := -1.0
		var t_cone := -1.0
		var cmarks := [0.6, 2.0]
		var bmarks := [0.15]
		var smarks := [0.03, 0.08, 0.16]
		var seen := 0
		while frames < 9000 and nb != null and (cmarks.size() + bmarks.size() + smarks.size()) > 0:
			await process_frame
			frames += 1
			var bn: Battle = world.battle_view.battle
			if bn == null or bn.state == "ended":
				break
			if not given and bn.state == "running":
				given = true
				var lc: Dictionary = nb.def.passive_by_id("node_noble_lily").effect_config.duplicate(true)
				lc["add_stacks"] = 12
				lc["max_stacks"] = 12
				bn.pipeline.fx.apply_status(nb, nb, lc)
			var ahead: Vector2 = nb.pos + Vector2(sin(nb.facing), cos(nb.facing)) * float(args.get("ahead", "0"))
			world.rig.set_view(Vector3(ahead.x, 0.0, ahead.y), float(args.get("yaw", "0")), float(args.get("pitch", "56")), float(args.get("dist", "9")), true)
			# (事件被 BattleView 每帧取走了，这里看她的状态)
			if t_ch < 0.0 and nb.phase == "chant":
				t_ch = bn.time
			if t_bl < 0.0 and nb.status_stacks("lily_bloom") > 0:
				t_bl = bn.time
			if t_cone < 0.0 and seen == 3 and nb.status_stacks("lily_stamen") < 3:
				t_cone = bn.time
			seen = maxi(seen, nb.status_stacks("lily_stamen"))
			if t_ch >= 0.0 and cmarks.size() > 0 and bn.time >= t_ch + float(cmarks[0]):
				imgs.append(sv.get_texture().get_image())
				cmarks.pop_front()
			if t_bl >= 0.0 and bmarks.size() > 0 and bn.time >= t_bl + float(bmarks[0]):
				imgs.append(sv.get_texture().get_image())
				bmarks.pop_front()
			if t_cone >= 0.0 and smarks.size() > 0 and bn.time >= t_cone + float(smarks[0]):
				imgs.append(sv.get_texture().get_image())
				smarks.pop_front()
		print("noble chant at %.2f bloom at %.2f cone at %.2f" % [t_ch, t_bl, t_cone])
	# follow=node_warden：镜头每帧对准我方这个棋子；wforms=1(守林节点)：不按 times，每次变身后 0.15 / 0.9 秒各截一张
	var fu: BUnit = null
	if args.has("follow"):
		for u3: BUnit in world.battle_view.battle.units:
			if u3.def.id == str(args["follow"]) and u3.team == 0:
				fu = u3
	var wforms: bool = args.has("wforms") and fu != null
	var form0 := ""
	var fmk: Array = []
	# release=N(配 follow=…)：这个棋子吟唱(拉弓)结束出手后 0.02 / 0.07 / 0.14 秒各截一张，截 N 次出手
	var rel_n: int = int(args.get("release", "0")) if fu != null else 0
	# on_status=quake_stance [n=2](配 follow=…)：这个棋子身上出现这个状态后 0.3 / 0.38 / 0.55 / 0.9 秒各截一张(看圣战节点的裂地猛击)
	var st_id: String = str(args.get("on_status", ""))
	var st_n: int = int(args.get("n", "2")) if st_id != "" and fu != null else 0
	var had_st := false
	var prev_phase := ""
	var rmk: Array = []
	while (t_next < times.size() or wforms or rel_n > 0 or st_n > 0 or not rmk.is_empty()) and frames < (12000 if wforms else 4000) and not args.has("magi") and not args.has("watch") and not args.has("noble"):
		await process_frame
		frames += 1
		elapsed = world.battle_view.battle.time if world.battle_view.battle != null else elapsed
		if fu != null:
			world.rig.set_view(Vector3(fu.pos.x, 0.0, fu.pos.y), float(args.get("yaw", "0")), float(args.get("pitch", "56")), float(args.get("dist", "8")), true)
		if rel_n > 0 or st_n > 0 or not rmk.is_empty():
			var br: Battle = world.battle_view.battle
			if br == null or br.state == "ended":
				break
			var has_st: bool = st_id != "" and fu.get_status(st_id) != null
			if has_st and not had_st and st_n > 0:
				st_n -= 1
				for dt2: float in [0.3, 0.38, 0.55, 0.9]:
					rmk.append(br.time + dt2)
			had_st = has_st
			if prev_phase == "draw" and fu.phase != "draw" and rel_n > 0:
				rel_n -= 1
				for dt: float in [0.02, 0.07, 0.14]:
					rmk.append(br.time + dt)
			prev_phase = fu.phase
			if not rmk.is_empty() and br.time >= float(rmk[0]):
				imgs.append(sv.get_texture().get_image())
				rmk.pop_front()
			continue
		if wforms:
			var bw: Battle = world.battle_view.battle
			if bw == null or bw.state == "ended" or not fu.alive:
				break
			# wskip=N：开局狮子之后直接替她挨 N 下致命伤(跳到后面的形态看表现)
			if args.has("wskip") and bw.state == "running" and form0 == "lion" and int(fu.meta.get("_demo_skip", 0)) < int(args["wskip"]):
				var foe0: BUnit = null
				for u4: BUnit in bw.units:
					if u4.team != 0 and u4.alive:
						foe0 = u4
				for _k in range(int(args["wskip"])):
					fu.shield = 0.0
					bw.pipeline.fx.damage(foe0, fu, fu.hp + 5000.0, "true", {})
				fu.meta["_demo_skip"] = int(args["wskip"])
			var f1: String = Pipeline.warden_form(fu)
			if f1 != form0:
				form0 = f1
				fmk.append(bw.time + 0.15)
				fmk.append(bw.time + 0.9)
			if not fmk.is_empty() and bw.time >= float(fmk[0]):
				imgs.append(sv.get_texture().get_image())
				fmk.pop_front()
		elif t_next < times.size() and elapsed >= float(times[t_next]):
			imgs.append(sv.get_texture().get_image())
			t_next += 1
	var cols: int = int(args.get("cols", str(mini(imgs.size(), 2))))
	var rows: int = int(ceil(float(imgs.size()) / float(cols)))
	var sheet := Image.create(cw * cols, ch * rows, false, Image.FORMAT_RGB8)
	for i in imgs.size():
		var im: Image = imgs[i]
		im.convert(Image.FORMAT_RGB8)
		sheet.blit_rect(im, Rect2i(0, 0, cw, ch), Vector2i((i % cols) * cw, (i / cols) * ch))
	sheet.save_png(String(args.get("out", "res://out/battle.png")))
	print("saved ", args.get("out", "res://out/battle.png"), " battle_time=", elapsed, " state=", world.battle_view.battle.state)
	quit()
