extends SceneTree
## (2026-10-05 起阵容 / 卡的强度改用 ./run_intensity.sh 的"最高通过战斗强度"判断；这个群战基准只用来看机制、找 bug，不当强度判据。)
## 群战基准(3v3，不计羁绊)：池子里每 3 个组一队(不重复)，和所有队伍各打 seeds 场；再把每队的每一个成员换成 sub，看换人后的胜率。
## 用来回答"把 X 换成舞星节点，这队会不会变强、变强多少"。同星级，各拿专属武器(没有专属就拿基础武器)，站位：近战前排、远程后排。
## godot --headless --path . --script res://tools/team_bench.gd -- sub=node_dancer pool=node_archer,node_shielder,node_peasant,node_student,node_berserker
##     star=2 seeds=2 [student_ap=12] [weapons=exclusive|basic]
##   mark=1 模拟玩家用狩猎旗标：两边各自标记对面攻击力最高的非坦克
##   drop=node_astronaut[:武器] A 队仓库里放一个会坠落的星旅节点(白送，不占人数)；extra=node_maid[:武器] A 队后排多上一个(对照)
##   只能部署在敌人身边的棋子(deploy_near_enemies)放在对面前排中间那个敌人身边
##   traits=a 只给 A 队算羁绊(traits=both 两边都算；默认都不算)
##   basic_for=node_leader 这些棋子固定拿基础武器；weapon_for=node_absolver:fireball_tome 这些棋子固定拿指定武器
##   报：每个被换掉的节点 → 原队伍平均胜率 / 换成 sub 后的平均胜率；以及 sub 所在队伍的总胜率
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cat := Catalog.load_all()
	var sub: String = str(args.get("sub", "node_dancer"))
	var pool: PackedStringArray = str(args.get("pool", "node_archer,node_shielder,node_peasant,node_student,node_berserker")).split(",")
	var star: int = int(args.get("star", "2"))
	var seeds: int = int(args.get("seeds", "2"))
	var ap: float = float(args.get("student_ap", "12"))
	var use_ex: bool = str(args.get("weapons", "exclusive")) == "exclusive"
	var basic_for: PackedStringArray = str(args.get("basic_for", "")).split(",", false)      # 这些棋子固定拿基础武器(例如不带专武的真望节点)
	var ex_of := {}
	for eid: String in cat.equipment.keys():
		var e: EquipmentDef = cat.get_equipment(eid)
		if e.owner != "":
			ex_of[e.owner] = eid
	# weapon_for=node_absolver:fireball_tome,… 这些棋子固定拿指定的武器(看专武以外的武器配她怎么样)
	for wf: String in str(args.get("weapon_for", "")).split(",", false):
		var wp: PackedStringArray = wf.split(":")
		if wp.size() == 2:
			ex_of[wp[0]] = wp[1]
	var teams: Array = []
	for i in range(pool.size()):
		for j in range(i + 1, pool.size()):
			for k in range(j + 1, pool.size()):
				teams.append([pool[i], pool[j], pool[k]])
	# 一场：返回 A 队是否赢(A 是我方 team 0)
	var fight := func(ta: Array, tb: Array, seed_v: int) -> bool:
		var units: Array = []
		for side: int in [0, 1]:
			var tm: Array = ta if side == 0 else tb
			var sgn: float = -1.0 if side == 0 else 1.0
			var front: Array = []
			var back: Array = []
			for id: String in tm:
				# 按拿着的武器的实际射程排前后排(舞扇这种加了射程的近战武器站后排)
				var d: UnitDef = cat.get_unit(id)
				var wid: String = ex_of.get(id, "") if use_ex and not basic_for.has(id) else ""
				var we: EquipmentDef = cat.resolve_weapon(d, wid)
				var rng_pts: float = float(d.wclass_for(we.class_id).get("range", 1.0)) + float(we.flat_mods.get("attack_range", 0.0))
				rng_pts *= 1.0 + float(we.pct_mods.get("attack_range", 0.0))
				(back if rng_pts * GC.RANGE_UNIT > 2.5 or d.sky_caster else front).append(id)
			for row: int in [0, 1]:
				var ids: Array = front if row == 0 else back
				for n in range(ids.size()):
					var id2: String = ids[n]
					var x: float = (float(n) - float(ids.size() - 1) * 0.5) * 1.6
					var y: float = sgn * (2.2 if row == 0 else 4.2)
					var perm := {}
					if id2 == "node_student":
						perm = {"ability_power": ap}
					var wid2: String = ex_of.get(id2, "") if use_ex and not basic_for.has(id2) else ""
					if wid2 != "" and cat.get_equipment(wid2).equip_problem(cat.get_unit(id2), star) != "":
						wid2 = ""                                  # 这个星级装不了(例如 1 星灾星节点装不了红色的流星爆魔杖)
					units.append({"def": id2, "team": side, "star": star, "pos": Vector2(x, y), "weapon": wid2, "perm": perm})
		# 只能部署在敌人身边的(幻形节点·千变万化)：挪到对面前排中间那个敌人的身边(真实部署的样子)
		for ue2: Dictionary in units:
			if not cat.get_unit(str(ue2["def"])).deploy_near_enemies:
				continue
			var best_p := Vector2(1.0e9, 1.0e9)
			for uo: Dictionary in units:
				if int(uo["team"]) != int(ue2["team"]) and absf((uo["pos"] as Vector2).y) < absf(best_p.y) + 0.01 and absf((uo["pos"] as Vector2).x) <= absf(best_p.x):
					best_p = uo["pos"]
			if best_p.x < 1.0e8:
				ue2["pos"] = best_p + Vector2(0.9, -signf(best_p.y) * 0.9)
		# drop=node_astronaut[:武器]：A 队仓库里再放一个会坠落的棋子(星旅节点·渡星而来；落点 = B 队最密集的地方)
		# extra=node_maid[:武器]：A 队后排再多上一个棋子(和"白送一个坠落的"比)
		for opt_k: String in ["drop", "extra"]:
			if args.has(opt_k):
				var od: PackedStringArray = str(args[opt_k]).split(":")
				var oid: String = od[0]
				var owid: String = od[1] if od.size() > 1 else str(ex_of.get(oid, "")) if use_ex else ""
				var e2 := {"def": oid, "team": 0, "star": star, "weapon": owid}
				if opt_k == "drop":
					var bpos: Array[Vector2] = []
					for ue: Dictionary in units:
						if int(ue["team"]) == 1:
							bpos.append(ue["pos"])
					var dd: UnitDef = cat.get_unit(oid)
					e2["pos"] = Targeting.densest_point(bpos, dd.passive_splash_radius(star), null, dd.radius)
					e2["drop"] = true
				else:
					e2["pos"] = Vector2(0.0, -6.0)
				units.append(e2)
		# mark=1：模拟玩家用狩猎旗标——标记对面攻击力最高的非坦克(两边各标各的)
		if args.has("mark"):
			for side2: int in [0, 1]:
				var best_i := -1
				var best_a := -1.0
				for ui in range(units.size()):
					var ud: Dictionary = units[ui]
					if int(ud["team"]) == side2:
						continue
					var udef: UnitDef = cat.get_unit(str(ud["def"]))
					var sc: float = udef.base_stats.attack_power + udef.base_stats.ability_power - (1000.0 if udef.role == "tank" else 0.0)
					if sc > best_a:
						best_a = sc
						best_i = ui
				if best_i >= 0:
					(units[best_i] as Dictionary)["hunt_marked_by"] = side2
		var b := Battle.new(cat, seed_v)
		var bcfg := {"traits": false, "na_flat_floor": float(args.get("na_floor", "0"))}
		if args.has("traits"):
			# traits=a：只给 A 队算羁绊(看这个阵容吃到羁绊以后强多少)；traits=both：两边都算
			bcfg["traits"] = true
			bcfg["trait_teams"] = [0, 1] if str(args["traits"]) == "both" else [0]
		b.setup({"units": units, "map": {"truck": false}, "cfg": bcfg})
		b.start()
		var t_limit: float = GC.START_DELAY + GC.BATTLE_MAX_SECONDS
		while b.time < t_limit and b.state != "ended":
			b.step()
			var alive := [0, 0]
			for u: BUnit in b.units:
				if u.alive:
					alive[u.team] += 1
			if alive[0] == 0 or alive[1] == 0:
				return alive[1] == 0 and alive[0] > 0
		return false
	# 固定队伍模式：team=a,b,c 对池子里每 vs_n 个组成的队伍(人数劣势就把 vs_n 设大)
	if args.has("team"):
		var mine: Array = Array(str(args["team"]).split(","))
		var vs_n: int = int(args.get("vs_n", "3"))
		var opps: Array = []
		var idx: Array = range(pool.size())
		var combo := func(start: int, picked: Array, rec: Callable) -> void:
			if picked.size() == vs_n:
				var tm: Array = []
				for q: int in picked:
					tm.append(pool[q])
				opps.append(tm)
				return
			for q2 in range(start, pool.size()):
				rec.call(q2 + 1, picked + [q2], rec)
		combo.call(0, [], combo)
		var tw := 0
		var tn := 0
		print("固定队伍 %s 对 %d 人队伍(不计羁绊)  ★%d  每组 %d 场" % [str(mine), vs_n, star, seeds])
		for ob: Array in opps:
			var w0 := 0
			for s3 in range(seeds):
				if fight.call(mine, ob, 7000 + s3):
					w0 += 1
			tw += w0
			tn += seeds
			print("  对 %-58s %d/%d" % [",".join(ob), w0, seeds])
		print("总胜率 %.0f%% (%d/%d)" % [100.0 * float(tw) / float(tn), tw, tn])
		quit()
		return
	print("群战 3v3(不计羁绊)  ★%d  每组 %d 场  换入 %s  %s" % [star, seeds, sub, "专属武器" if use_ex else "基础武器"])
	var base_wr := {}      # 队伍 key -> 胜率
	var sub_wr := {}
	var s0 := 7000
	for ta: Array in teams:
		var w := 0
		var n := 0
		for tb: Array in teams:
			for s in range(seeds):
				if fight.call(ta, tb, s0 + s):
					w += 1
				n += 1
		base_wr[",".join(ta)] = float(w) / float(n)
	var by_member := {}    # 被换掉的 id -> [原胜率和, 换后胜率和, 次数]
	var sub_all := 0.0
	var sub_n := 0
	for ta2: Array in teams:
		for m: String in ta2:
			var t2: Array = ta2.duplicate()
			t2[t2.find(m)] = sub
			var w2 := 0
			var n2 := 0
			for tb2: Array in teams:
				for s2 in range(seeds):
					if fight.call(t2, tb2, s0 + s2):
						w2 += 1
					n2 += 1
			var wr2: float = float(w2) / float(n2)
			var e: Array = by_member.get(m, [0.0, 0.0, 0])
			e[0] += base_wr[",".join(ta2)]
			e[1] += wr2
			e[2] += 1
			by_member[m] = e
			sub_all += wr2
			sub_n += 1
	print("%-16s %10s %12s %8s" % ["换掉的节点", "原队胜率", "换成后胜率", "变化"])
	for m2: String in pool:
		var e2: Array = by_member[m2]
		var a0: float = e2[0] / float(e2[2])
		var a1: float = e2[1] / float(e2[2])
		print("%-16s %9.0f%% %11.0f%% %+7.0f%%" % [m2, 100.0 * a0, 100.0 * a1, 100.0 * (a1 - a0)])
	print("含 %s 的队伍总胜率 %.0f%%(基线 = 50%%)" % [sub, 100.0 * sub_all / float(sub_n)])
	for tk: String in base_wr.keys():
		print("  基线 %-45s %3.0f%%" % [tk, 100.0 * base_wr[tk]])
	quit()
