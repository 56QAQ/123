extends SceneTree
## (2026-10-05 起阵容 / 卡的强度改用 ./run_intensity.sh 的"最高通过战斗强度"判断；单挑只用来看机制、找 bug，不当强度判据。)
## 单挑 / 以一敌多：a 方 1 个棋子对 b 方 n 个棋子，真实规则(AI、攻击状态机、触发器、暴击、吸血)，同星级，按种子取平均。
## godot --headless --path . --script res://tools/duel_bench.gd -- a=node_berserker a_weapons=basic_dual,wolf_blades
##     b=node_archer,node_shielder b_weapon=exclusive stars=1,2,3 seeds=12 [n=5 form=dense|spread] [dist=6]
##   b_weapon   exclusive = 各自的专属武器(EquipmentDef.owner)；basic = 基础武器；或者直接写武器 id
##   n / form   b 方几个、站位(dense = 挤成一团，间距约 0.9 米；spread = 横排、间距 2.2 米；gap= 覆盖间距)；dist = 两方开局距离(米)
##   b_perm     b 方的永恒成长(如 ability_power:12)
##   a_awaken   白送 a 的觉醒任务(觉醒键，逗号分隔；开战就算完成，照常发"完成觉醒"事件)
##   a_free_chant=1  白送 a 开战时的吟唱(追猎节点的猎人笔记：一开始就当作已经吟唱满)
##   a_mark=1   用狩猎旗标标记 b 方第一个棋子(狩胜节点开战就投它)；a_stats=attack_power:170,max_health:2000 临时覆盖 a 的基础数值
##   tx= / tz= / bn=   临时覆盖狩胜节点的投掷倍率 x(a,b,c)、我已得胜的 z(a,b,c)、赤焰战旗的 n
##   报：a 的胜率、平均结束时间、a 胜时剩血、a 平均击杀数
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	if args.has("a_stats"):
		var ad: UnitDef = cat.get_unit(str(args.get("a", "")))
		for kv0: String in str(args["a_stats"]).split(","):
			var kv1: PackedStringArray = kv0.split(":")
			ad.base_stats.set_stat(kv1[0], float(kv1[1]))
	var gd: UnitDef = cat.get_unit("node_gladiator")
	for tr0: TriggerDef in gd.triggers:
		if args.has("tx") and (tr0.id == "node_gladiator_throw" or tr0.id == "node_gladiator_glory_throw"):
			var xs0: PackedStringArray = str(args["tx"]).split(",")
			tr0.ratio_by_star = {1: float(xs0[0]), 2: float(xs0[1]), 3: float(xs0[2])}
		if args.has("tz") and tr0.id == "node_gladiator_triumph":
			var zs0: PackedStringArray = str(args["tz"]).split(",")
			tr0.ratio_by_star = {1: float(zs0[0]), 2: float(zs0[1]), 3: float(zs0[2])}
	if args.has("bn"):
		cat.get_equipment("flame_banner").abilities[0].value_multiplier = 0.01 / float(args["bn"])
	var a_id: String = str(args.get("a", "node_berserker"))
	var seeds: int = int(args.get("seeds", "12"))
	var n: int = int(args.get("n", "1"))
	var form: String = str(args.get("form", "dense"))
	var dist: float = float(args.get("dist", "6"))
	var bperm := {}
	if args.has("b_perm"):
		for kvs: String in str(args["b_perm"]).split(","):
			var kv2: PackedStringArray = kvs.split(":")
			bperm[kv2[0]] = float(kv2[1])
	print("单挑  %s  对  %s × %d%s  每组 %d 场" % [a_id, str(args.get("b", "node_archer")), n, ("  站位 " + form) if n > 1 else "", seeds])
	print("%-16s %-18s %-18s %-3s %7s %8s %8s %6s" % ["对手", "a 武器", "b 武器", "★", "a 胜率", "结束(秒)", "a 剩血", "a 击杀"])
	for b_id: String in str(args.get("b", "node_archer")).split(","):
		var b_def: UnitDef = cat.get_unit(b_id)
		var bw: String = str(args.get("b_weapon", "exclusive"))
		if bw == "exclusive":
			bw = ""
			for eid: String in cat.equipment.keys():
				if cat.get_equipment(eid).owner == b_id:
					bw = eid
		elif bw == "basic":
			bw = ""
		for aw: String in str(args.get("a_weapons", "")).split(","):
			for sts: String in str(args.get("stars", "1,2,3")).split(","):
				var star: int = int(sts)
				var wins := 0
				var t_sum := 0.0
				var hp_sum := 0.0
				var kills := 0
				for s in range(seeds):
					var units: Array = [{"def": a_id, "team": 0, "star": star, "pos": Vector2(0, -dist * 0.5), "weapon": aw}]
					for k in range(n):
						var off := Vector2.ZERO
						if k == 0 and args.has("a_mark"):
							pass
						if n > 1:
							var step: float = float(args.get("gap", "0.9" if form == "dense" else "2.2"))
							var cols: int = 3 if form == "dense" else n
							off = Vector2((float(k % cols) - float(mini(n, cols) - 1) * 0.5) * step, float(k / cols) * step * 0.9)
						units.append({"def": b_id, "team": 1, "star": star, "pos": Vector2(0, dist * 0.5) + off, "weapon": bw, "perm": bperm.duplicate()})
						if k == 0 and args.has("a_mark"):
							(units.back() as Dictionary)["hunt_marked_by"] = 0
					var b := Battle.new(cat, 3000 + s)
					b.setup({"units": units, "map": {"truck": false}, "cfg": {}})
					b.start()
					var t_limit: float = GC.START_DELAY + GC.BATTLE_MAX_SECONDS
					var au: BUnit = b.units[0]
					# a_awaken=key,...：白送 a 的觉醒任务(开战就当作完成，照常发"完成觉醒"事件)
					for ak: String in str(args.get("a_awaken", "")).split(",", false):
						au.awakened[ak] = true
						b.pipeline.emit("OnAwakeningCompleted", au, null, 1.0, ["awakening", "equipment_payload"], {"awakening_key": ak})
					var freed := not args.has("a_free_chant")
					while b.time < t_limit and b.state != "ended":
						# a_free_chant=1：白送 a 开战时的吟唱(猎人笔记)——一开始吟唱就当作已经吟唱满(下一步完整结束，照常触发"吟唱完成")
						if not freed and au.phase == "chant":
							au.chant_until = b.time
							freed = true
						b.step()
						var left := 0
						for k2 in range(1, b.units.size()):
							if b.units[k2].alive and b.units[k2].team == 1:       # 召唤物也要打死(如护星节点)
								left += 1
						if left == 0 or not au.alive:
							break
					t_sum += b.time - GC.START_DELAY
					var alive_b := 0
					for k3 in range(1, b.units.size()):
						if b.units[k3].team != 1:
							continue
						if b.units[k3].alive:
							alive_b += 1
						elif not b.units[k3].is_summon:
							kills += 1
					if au.alive and alive_b == 0:
						wins += 1
						hp_sum += au.hp / au.get_stats().max_health
				var nf := float(seeds)
				print("%-16s %-18s %-18s %-3d %6.0f%% %8.1f %7.0f%% %6.1f" % [b_id, aw if aw != "" else "(基础)", bw if bw != "" else "(基础)", star,
					100.0 * wins / nf, t_sum / nf, 100.0 * hp_sum / maxf(1.0, float(wins)), float(kills) / nf])
	quit()
