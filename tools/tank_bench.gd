extends SceneTree
## 单抗基准：一个坦克单独顶住一个输出棋子，量能撑多久(真实规则：AI、攻击状态机、护盾、触发器、暴击)。用作单人承伤的平衡基准。
## godot --headless --path . --script res://tools/tank_bench.gd -- tank=node_shielder tank_weapons=basic_sword,dual_use_stunner
##     dps=node_archer dps_weapon=rapidfire_arbalest stars=1,2,3 seeds=12 [duel=1]
##   默认输出方不死(血量无限)：只量坦克能撑多久；duel=1 时是正常的 1v1(谁先倒)，另外报胜率
##   dps_count=N 同时 N 个输出方；paddy=1 坦克脚下一块不会消失的稻田(加成 = 0.1 × 20% × 坦克最大生命)；pin=1 坦克站着不动(全程在稻田里)
##   "撑(秒)" 到上限(75 秒)的记为撑住；另报结束时的生命比例
##   dps_perm=ability_power:12 输出方身上的永恒成长(例如求知节点被动 1 攒的法术强度)；sx=a,b,c 覆盖求知节点"把咒语念出来！"的 x
##   heal=node_nurse heal_weapon=heart_syringe 坦克身后 2.5 米站一个同星级的治疗(护理节点)；hx=a,b,c 覆盖广义治疗的 x，hy=a,b,c 覆盖药水填充的 y，hn= 覆盖爱心针剂的 n
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	# 调参：x=a,b,c 覆盖耕植节点【吃苦耐劳】每层普攻减免，y=a,b,c 覆盖韧性每层回血比例，iv= 韧性回血间隔(秒)
	if args.has("x") or args.has("y") or args.has("iv"):
		var pd: UnitDef = cat.get_unit("node_peasant")
		for pa: AbilityDef in pd.passives:
			if args.has("x") and pa.id == "node_peasant_hardwork":
				var xs: PackedStringArray = str(args["x"]).split(",")
				pa.effect_config["stats_by_star"] = {"na_damage_taken_flat": {"flat": {"1": float(xs[0]), "2": float(xs[1]), "3": float(xs[2])}}}
			if pa.id == "node_peasant_toughness":
				if args.has("y"):
					var ys: PackedStringArray = str(args["y"]).split(",")
					pa.effect_config["hot"]["pct_by_star"] = {"1": float(ys[0]), "2": float(ys[1]), "3": float(ys[2])}
				if args.has("iv"):
					pa.effect_config["hot"]["interval"] = float(args["iv"])
		print("  调参 x=%s y=%s iv=%s" % [args.get("x", "-"), args.get("y", "-"), args.get("iv", "-")])
	if args.has("hx"):
		var hxs: PackedStringArray = str(args["hx"]).split(",")
		for pa2: AbilityDef in cat.get_unit("node_nurse").passives:
			if pa2.id == "node_nurse_general_care":
				pa2.effect_config["stats_by_star"] = {"na_ally_heal_pct": {"flat": {"1": float(hxs[0]), "2": float(hxs[1]), "3": float(hxs[2])}}}
	if args.has("hy"):
		var hys: PackedStringArray = str(args["hy"]).split(",")
		for tr2: TriggerDef in cat.get_unit("node_nurse").triggers:
			if tr2.id == "node_nurse_potion_fill":
				tr2.ratio_by_star = {1: float(hys[0]), 2: float(hys[1]), 3: float(hys[2])}
	if args.has("hn"):
		cat.get_equipment("heart_syringe").abilities[0].value_multiplier = float(args["hn"])
	if args.has("hx") or args.has("hy") or args.has("hn"):
		print("  调参 hx=%s hy=%s hn=%s" % [args.get("hx", "-"), args.get("hy", "-"), args.get("hn", "-")])
	if args.has("sx"):
		var sxs: PackedStringArray = str(args["sx"]).split(",")
		for tr: TriggerDef in cat.get_unit("node_student").triggers:
			if tr.id == "node_student_recite":
				tr.flat_by_star = {1: float(sxs[0]), 2: float(sxs[1]), 3: float(sxs[2])}
		print("  调参 sx=%s" % args["sx"])
	var dperm := {}
	if args.has("dps_perm"):
		for kvs: String in str(args["dps_perm"]).split(","):
			var kv2: PackedStringArray = kvs.split(":")
			dperm[kv2[0]] = float(kv2[1])
	var tank: String = str(args.get("tank", "node_shielder"))
	var dps: String = str(args.get("dps", "node_archer"))
	var dps_w: String = str(args.get("dps_weapon", "rapidfire_arbalest"))
	var seeds: int = int(args.get("seeds", "12"))
	var duel: bool = args.has("duel")
	var n_dps: int = int(args.get("dps_count", "1"))
	var paddy: bool = args.has("paddy")
	var pin: bool = args.has("pin")
	var healer: String = str(args.get("heal", ""))
	var heal_w: String = str(args.get("heal_weapon", ""))
	print("单抗  %s  对  %s(%s)%s  每组 %d 场" % [tank, dps, dps_w, "  正常 1v1" if duel else "  输出方不死", seeds])
	if healer != "":
		print("  坦克身后：%s(%s)" % [healer, heal_w if heal_w != "" else "基础武器"])
	print("  输出方 %d 个%s%s%s" % [n_dps, "  坦克脚下常驻稻田" if paddy else "", "  坦克不动" if pin else "",
		("  输出方永恒成长 %s" % str(dperm)) if not dperm.is_empty() else ""])
	print("%-18s %-3s %8s %8s %8s %8s %8s %7s %7s" % ["tank weapon", "★", "撑(秒)", "承伤", "护盾吸收", "受到DPS", "缩头%", "坦克胜", "剩血"])
	for tw: String in str(args.get("tank_weapons", "basic_sword,dual_use_stunner")).split(","):
		for sts: String in str(args.get("stars", "1,2,3")).split(","):
			var star: int = int(sts)
			var t_sum := 0.0
			var taken := 0.0
			var absorbed := 0.0
			var turtle_t := 0.0
			var wins := 0
			var hp_end := 0.0
			var hp_mid := 0.0
			var survived := 0
			for s in range(seeds):
				var b := Battle.new(cat, 2000 + s)
				var ul: Array = [{"def": tank, "team": 0, "star": star, "pos": Vector2(0, -2.0), "weapon": tw}]
				for k in range(n_dps):
					var ang: float = (float(k) - float(n_dps - 1) * 0.5) * 0.7
					ul.append({"def": dps, "team": 1, "star": star, "pos": Vector2(0, -2.0) + Vector2(sin(ang), cos(ang)) * 5.0, "weapon": dps_w, "perm": dperm.duplicate()})
				if healer != "":
					ul.append({"def": healer, "team": 0, "star": star, "pos": Vector2(0, -4.5), "weapon": heal_w})
				b.setup({"units": ul, "map": {"truck": false}, "cfg": {}})
				var tu: BUnit = b.units[0]
				var du: BUnit = b.units[1]
				if not duel:
					for k2 in range(1, 1 + n_dps):
						var dx: BUnit = b.units[k2]
						dx.base.max_health = 1.0e9
						dx.mark_dirty()
						dx.recompute()
						dx.hp = 1.0e9
				if pin:
					tu.base.move_speed = 0.0
					tu.mark_dirty()
				b.start()
				if paddy:
					b.add_field({"kind": "paddy", "pos": tu.pos, "radius": 1.2, "until": 1.0e9,
						"heal_bonus": 0.1 * 0.2 * tu.get_stats().max_health, "src": tu})
				var t_limit: float = GC.START_DELAY + GC.BATTLE_MAX_SECONDS
				var mid_done := false
				while tu.alive and du.alive and b.time < t_limit and b.state != "ended":
					b.step()
					if not mid_done and b.time >= GC.START_DELAY + 35.0:
						mid_done = true
						hp_mid += tu.hp / tu.get_stats().max_health
					if tu.has_flag("turtle"):
						turtle_t += GC.SIM_DT
				var lived: float = b.time - GC.START_DELAY
				t_sum += lived
				taken += tu.st_taken
				for e: Dictionary in b.events:
					if e.get("t") == "damage" and e.get("dst") == tu:
						absorbed += float(e.get("absorbed", 0.0))
				if tu.alive and not du.alive:
					wins += 1
				if tu.alive:
					survived += 1
					hp_end += tu.hp / tu.get_stats().max_health
			var n := float(seeds)
			var lived_txt: String = ("%8.1f" % (t_sum / n)) if survived == 0 else ("撑住%d/%d" % [survived, seeds])
			print("%-18s %-3d %8s %8.0f %8.0f %8.1f %7.0f%% %6d/%d %6.0f%%  (35 秒时 %.0f%%)" % [tw, star, lived_txt, taken / n, absorbed / n, taken / maxf(0.01, t_sum),
				100.0 * turtle_t / maxf(0.01, t_sum), wins, seeds, 100.0 * hp_end / maxf(1.0, float(survived)), 100.0 * hp_mid / n])
	quit()
