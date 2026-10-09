extends SceneTree
## 战役基准：一个贪心机器人用 Run 的真实规则(出发/买/上场/装备/升级/开晶球)打完整章，统计每个地图节点的胜率与战利品。
## 第零章打完接着打第一章·红之章(方格网地图：挑节点、修整、商店、追猎)，统计各类战斗(弱怪池/强怪池/精英/首领/追猎)的胜率与卡车受损。
## 用法: godot --headless --path . --script res://tools/campaign_bench.gd --quit-after 6000 -- n=40 seed=1 [starter=smart|none] [dump=8] [ch1=0] [branch=ch1_red|ch1_blue]
##   tram=board|follow|watch：机器人在事件「末班电车」里固定选哪一项(默认 board = 上车打一场)
##   dump=K：打印第 K 个地图节点每场战斗的双方输出/承伤(调平衡用)
##   basic=bench：空白节点一直不上场(默认 deploy = 每场都放到卡车后面)
var cat: Catalog
var lv_stat := {"ch0": 0, "boss_lv": 0, "boss_n": 0, "boss_c4": 0, "boss_costs": {}}     # 等级曲线：第零章打完 / 打第一章首领时的等级、拥有的棋子费用分布
var by_iv: Dictionary = {}     # 第一章普通作战(含强怪)：按战斗强度(每 ivbin 点一档，默认 4)统计胜率
var dump_kind := ""          # dump1=strong：打印第一章这类战斗的前几场明细
var dumped := 0
var sweep: Array[int] = []   # sweep=10,15,18：第零章打完后，用那时的队伍分别打这些战斗强度的普通作战(看强度曲线)
var reps := 4
var sweep_rec := {}          # 强度 -> [胜, 场, 卡车受损]
var use_workshop := true     # workshop=0：机器人不用车间(对照)
var craft_at := 12           # 材料攒到这么多份就全投进去造一件
var ws_stat := {"crafted": 0, "salvaged": 0, "cost": 0}
var tram_pick := "board"     # tram=board|follow|watch：事件「末班电车」里机器人选哪一项


var _args: Dictionary = {}


func _init() -> void:
	for a0 in OS.get_cmdline_user_args():
		var kv0: PackedStringArray = a0.split("=", true, 1)
		_args[kv0[0]] = kv0[1] if kv0.size() == 2 else "1"
	var n := 40
	var seed_value := 1
	var smart := true
	var dump := -1
	var ch1 := true
	for a in OS.get_cmdline_user_args():
		if a.begins_with("dump="):
			dump = int(a.substr(5))
		if a.begins_with("n="):
			n = int(a.substr(2))
		elif a.begins_with("seed="):
			seed_value = int(a.substr(5))
		elif a == "starter=none":
			smart = false
		elif a == "ch1=0":
			ch1 = false
		elif a.begins_with("dump1="):
			dump_kind = a.substr(6)
		elif a.begins_with("sweep="):
			for v: String in a.substr(6).split(","):
				sweep.append(int(v))
		elif a.begins_with("reps="):
			reps = int(a.substr(5))
		elif a == "workshop=0":
			use_workshop = false
		elif a.begins_with("craft_at="):
			craft_at = int(a.substr(9))
		elif a.begins_with("tram="):
			tram_pick = a.substr(5)
	cat = Catalog.load_all()
	# 调第一章的强度用(不改数据就能并行试几组)：ch1_iv=base:per_depth:max:elite_bonus:boss:hunt  strong=chance:from:bump_lo:bump_hi
	if _args.has("ch1_iv") or _args.has("strong"):
		var icd: Dictionary = (cat.chapters[str(_args.get("branch", "ch1_red"))] as Dictionary)["intensity"]
		if _args.has("ch1_iv"):
			var vs: PackedStringArray = str(_args["ch1_iv"]).split(":")
			var keys: Array = ["base", "per_depth", "max", "elite_bonus", "boss", "hunt"]
			for i in range(mini(vs.size(), keys.size())):
				if vs[i] != "":
					icd[keys[i]] = float(vs[i])
		if _args.has("strong"):
			var sv: PackedStringArray = str(_args["strong"]).split(":")
			icd["strong"] = {"chance": float(sv[0]), "from": float(sv[1]), "bump": [int(sv[2]), int(sv[3])]}
	var reached := {}            # node -> runs that reached it
	var attempts := {}           # node -> [wins, fights]
	var run_wins := 0
	var truck_left := 0
	var loot_tot := {"weapons": 0, "units": 0, "gold": 0, "orbs": 0}
	var c1 := {"runs": 0, "clears": 0, "hunts": 0, "dead": 0, "truck_end": 0, "steps": 0, "visits": 0, "ap_left": 0}
	var kinds := {}              # 战斗类型 -> [wins, fights, 卡车受损合计]
	var t0 := Time.get_ticks_msec()
	for i in range(n):
		var r := Run.create(cat, seed_value * 1000 + i)
		var guard := 0
		while r.phase != "over" and r.phase != "branch" and guard < 30:
			guard += 1
			r.travel()
			var nd: int = r.node_index + 1
			reached[nd] = int(reached.get(nd, 0)) + 1
			_prepare(r, smart and r.node_index == 0)
			var b := Battle.new(cat, r.rng.randi())
			b.setup(r.build_battle_setup())
			b.run_to_end()
			if nd == dump:
				_dump(b)
			var rec: Array = attempts.get(nd, [0, 0])
			rec[1] += 1
			if b.winner == GC.TEAM_PLAYER:
				rec[0] += 1
			attempts[nd] = rec
			r.begin_battle()
			r.finish_battle(b)
			_loot(r, loot_tot)
		if r.phase == "branch":
			run_wins += 1
		truck_left += r.truck_hp
		lv_stat["ch0"] = int(lv_stat["ch0"]) + r.level
		if not ch1 or r.phase != "branch":
			continue
		# ---------------------------------------------------------- 第一章(默认红之章，branch=ch1_blue 打蓝之章；先选分支，再三选一改装：机器人拿第一项)
		r.choose_branch(str(_args.get("branch", "ch1_red")))
		if r.phase == "chapter_end":
			r.pick_mod(r.mod_options[0])
		if not sweep.is_empty():
			_sweep(r)
			continue
		c1["runs"] = int(c1["runs"]) + 1
		_play_grid(r, kinds, c1)
	print("runs=%d  chapter 0 clears=%d  avg truck hp left %.1f  wall=%d ms" % [n, run_wins, float(truck_left) / maxf(1.0, n), Time.get_ticks_msec() - t0])
	print("  level: end of chapter 0 avg %.2f   at the chapter 1 boss avg %.2f   4-cost units owned at the boss %.2f   unit costs owned at the boss %s" % [
		float(lv_stat["ch0"]) / maxf(1.0, n), float(lv_stat["boss_lv"]) / maxf(1.0, float(lv_stat["boss_n"])),
		float(lv_stat["boss_c4"]) / maxf(1.0, float(lv_stat["boss_n"])), str(lv_stat["boss_costs"])])
	print("  workshop: crafted %.2f per run (avg cost %.2f), salvaged %.2f per run%s" % [float(ws_stat["crafted"]) / n,
		float(ws_stat["cost"]) / maxf(1.0, float(ws_stat["crafted"])), float(ws_stat["salvaged"]) / n, "" if use_workshop else "  (workshop=0)"])
	print("  per run: orbs %.2f  -> weapons %.2f  units %.2f  gold %.2f" % [float(loot_tot["orbs"]) / n, float(loot_tot["weapons"]) / n,
		float(loot_tot["units"]) / n, float(loot_tot["gold"]) / n])
	var nodes: Array = attempts.keys()
	nodes.sort()
	for k in nodes:
		var rec2: Array = attempts[k]
		print("  node %d: reached %2d  fight win-rate %3d%% (%d/%d)" % [k, int(reached.get(k, 0)), int(100.0 * rec2[0] / rec2[1]), rec2[0], rec2[1]])
	if not sweep.is_empty():
		print("intensity sweep (team at the end of chapter 0, %d fights each per run):" % reps)
		for iv: int in sweep:
			var sr: Array = sweep_rec.get(iv, [0, 0, 0])
			print("  intensity %2d  win %3d%%  avg truck damage %.1f  (%d fights)" % [iv, int(100.0 * sr[0] / maxf(1, sr[1])), float(sr[2]) / maxf(1, sr[1]), sr[1]])
	if int(c1["runs"]) > 0:
		var rn: float = float(c1["runs"])
		print("chapter 1 (%s): runs %d  boss cleared %d (%d%%)  truck destroyed %d  hunts %d  avg truck hp at end %.1f  avg steps %.1f  avg nodes %.1f  avg AP left at boss %.1f" % [str(_args.get("branch", "ch1_red")),
			int(c1["runs"]), int(c1["clears"]), int(100.0 * float(c1["clears"]) / rn), int(c1["dead"]), int(c1["hunts"]),
			float(c1["truck_end"]) / rn, float(c1["steps"]) / rn, float(c1["visits"]) / rn, float(c1["ap_left"]) / maxf(1.0, float(c1["clears"]))])
		var kk_list: Array = ["weak", "strong", "elite", "boss", "hunt"]
		var ev_kinds: Array = kinds.keys().filter(func(x: String) -> bool: return x.begins_with("event"))
		ev_kinds.sort()
		kk_list.append_array(ev_kinds)
		for kk: String in kk_list:
			if kinds.has(kk):
				var kr: Array = kinds[kk]
				print("  %-6s fights %3d  win %3d%%  avg truck damage per fight %.1f" % ["normal" if kk == "weak" else kk, kr[1], int(100.0 * kr[0] / maxf(1, kr[1])), float(kr[2]) / maxf(1, kr[1])])
		print("  events seen: %s   AP at the end (all runs): %.1f" % [str(c1.get("event_ids", {})), float(c1.get("ap_end", 0)) / rn])
		var ivk: Array = by_iv.keys()
		ivk.sort()
		for ib2: int in ivk:
			var ir2: Array = by_iv[ib2]
			print("    intensity %2d-%2d  fights %3d  win %3d%%  avg truck damage %.1f" % [ib2, ib2 + int(_args.get("ivbin", "4")) - 1, ir2[1], int(100.0 * ir2[0] / maxf(1, ir2[1])), float(ir2[2]) / maxf(1, ir2[1])])
	quit()


## 强度曲线：用第零章结束时的队伍(先按机器人的习惯花掉手里的钱)打各个强度的普通作战
func _sweep(r: Run) -> void:
	var nd: Dictionary = r.gnode(r.pos)
	var spent := false
	for iv: int in sweep:
		for k in range(reps):
			var enc: Dictionary = r._make_encounter("fight", iv)
			nd["encounter"] = enc
			nd["layout"] = r._make_layout(enc)
			r.phase = "prepare"
			if not spent:
				_prepare(r, false)
				spent = true
			else:
				_place_best(r)
			var b := Battle.new(cat, r.rng.randi())
			b.setup(r.build_battle_setup())
			b.run_to_end()
			if dump_kind == "sweep%d" % iv and dumped < 3:
				dumped += 1
				_dump(b)
			var rec: Array = sweep_rec.get(iv, [0, 0, 0])
			rec[1] += 1
			if b.winner == GC.TEAM_PLAYER:
				rec[0] += 1
			else:
				rec[2] += b.truck_damage + int(r.chapter.get("truck_damage_base", 0))
			sweep_rec[iv] = rec


func _loot(r: Run, loot_tot: Dictionary) -> void:
	if r.phase == "loot":
		loot_tot["orbs"] = int(loot_tot["orbs"]) + r.pending_orbs.size()
		for k in range(r.pending_orbs.size()):
			var l: Dictionary = r.open_orb(k)
			loot_tot["weapons"] = int(loot_tot["weapons"]) + (l.get("weapons", []) as Array).size()
			loot_tot["units"] = int(loot_tot["units"]) + (l.get("units", []) as Array).size()
			loot_tot["gold"] = int(loot_tot["gold"]) + int(l.get("gold", 0))
		r.finish_loot()


## 方格网章节的机器人：挑一个"去了以后剩下的行动力还够走到首领"的节点；卡车耐久低先修整，钱多逛黑市
func _play_grid(r: Run, kinds: Dictionary, c1: Dictionary) -> void:
	var dummy := {"orbs": 0, "weapons": 0, "units": 0, "gold": 0}
	var guard := 0
	var adj: Dictionary = ChapterMap.neighbors(r.gmap)
	var boss: String = str(r.gmap["boss"])
	var gdist: Dictionary = _graph_dist(adj, boss)
	while r.phase != "over" and r.phase != "branch" and guard < 80:
		guard += 1
		match r.phase:
			"map":
				var dest: String = _pick_dest(r, gdist)
				if dest == "":
					dest = boss if r.pos == boss else _any_move(r)
				var res: Dictionary = r.move_to(dest)
				if not res["ok"]:
					# 走不动了：把行动力花掉触发追猎
					r.ap = 0
					r._after_node()
			"prepare":
				var kind: String = r.battle_kind()
				if kind == "fight":
					kind = str(r.wave_def().get("pool", "weak"))
				if kind == "hunt":
					c1["hunts"] = int(c1["hunts"]) + 1
				if kind == "event":
					kind = "event:" + str(r.event_state.get("id", ""))
				_prepare(r, false)
				if kind == "boss":
					lv_stat["boss_lv"] = int(lv_stat["boss_lv"]) + r.level
					lv_stat["boss_n"] = int(lv_stat["boss_n"]) + 1
					for ru: Dictionary in r.roster.values():
						var rc: int = cat.get_unit(str(ru["def"])).cost
						(lv_stat["boss_costs"] as Dictionary)[rc] = int((lv_stat["boss_costs"] as Dictionary).get(rc, 0)) + 1
						if rc == 4:
							lv_stat["boss_c4"] = int(lv_stat["boss_c4"]) + 1
				var b := Battle.new(cat, r.rng.randi())
				b.setup(r.build_battle_setup())
				b.run_to_end()
				var lost_dump: bool = dump_kind == kind + "_lost" and b.winner != GC.TEAM_PLAYER and (kind == "elite" or int(r.wave_def().get("intensity", 99)) <= 13)
				if kind == "elite" and dump_kind == "elite_sum":
					var dr: BUnit = null
					for bu: BUnit in b.units:
						if bu.def.id.begins_with("elite_"):
							dr = bu
					print("  elite: win=%s t=%.1f intensity=%d dragon %d* hp %.0f/%.0f vanity=%d team=%d" % [str(b.winner == GC.TEAM_PLAYER), b.end_time - GC.START_DELAY,
						int(r.wave_def().get("intensity", 0)), dr.star if dr != null else 0, dr.hp if dr != null else 0.0, dr.get_stats().max_health if dr != null else 0.0,
						dr.status_stacks("elite_vanity") if dr != null else -1, r.board_units().size()])
				if (kind == dump_kind or lost_dump) and dumped < 6:
					dumped += 1
					print("  [%s] step %d  level %d  scale %s" % [kind, r.steps, r.level, str(r.enemy_scale())])
					_dump(b)
				r.begin_battle()
				var hp0: int = r.truck_hp
				r.finish_battle(b)
				var rec: Array = kinds.get(kind, [0, 0, 0])
				rec[1] += 1
				if b.winner == GC.TEAM_PLAYER:
					rec[0] += 1
				rec[2] += hp0 - r.truck_hp
				kinds[kind] = rec
				if kind == "weak" or kind == "strong":
					var ib: int = int(r.wave_def().get("intensity", 0)) / int(_args.get("ivbin", "4")) * int(_args.get("ivbin", "4"))
					var ir: Array = by_iv.get(ib, [0, 0, 0])
					ir[1] += 1
					if b.winner == GC.TEAM_PLAYER:
						ir[0] += 1
					ir[2] += hp0 - r.truck_hp
					by_iv[ib] = ir
				if kind == "boss" and b.winner == GC.TEAM_PLAYER:
					c1["ap_left"] = int(c1["ap_left"]) + r.ap
				_loot(r, dummy)
			"rest":
				if r.truck_hp < int(r.truck_max * 0.7) or r.rest_upgrade_candidates().is_empty():
					r.rest_repair()
				else:
					r.rest_upgrade(str(r.rest_upgrade_candidates()[0]["id"]))
			"event":
				# 机器人：能破坏喷泉就破坏(金币或者一场好处多的仗)，卡车耐久够就收集火焰，否则选最后一个能选的；
				# 末班电车按 tram= 选(默认上车打一场)
				if int(r.event_state.get("option", -1)) < 0:
					var opts: Array = r.event_def().get("options", [])
					var pick := -1
					for oi in range(opts.size()):
						if r.event_option_check(oi)["ok"]:
							var oid: String = str((opts[oi] as Dictionary).get("id", ""))
							if oid == "destroy" or (oid == "collect" and r.truck_hp > 60 and pick < 0):
								pick = oi
							if str(r.event_state.get("id", "")) == "last_tram" and oid == tram_pick:
								pick = oi
					var eid: String = str(r.event_state.get("id", ""))
					var seen_ev: Dictionary = c1.get("event_ids", {})
					seen_ev[eid] = int(seen_ev.get(eid, 0)) + 1
					c1["event_ids"] = seen_ev
					if pick < 0:
						for oi2 in range(opts.size() - 1, -1, -1):
							if r.event_option_check(oi2)["ok"]:
								pick = oi2
								break
					r.event_choose(pick)
					c1["events"] = int(c1.get("events", 0)) + 1
				r.event_continue()
			"shop":
				var offers: Array = r.node_shop().get("offers", [])
				for i in range(offers.size()):
					var of: Dictionary = offers[i]
					if bool(of["sold"]) or r.gold < int(of["price"]):
						continue
					if str(of["kind"]) == "repair" and r.truck_hp < r.truck_max - 10:
						r.node_shop_buy(i)
					elif str(of["kind"]) == "weapon" and r.gold >= int(of["price"]) + 4:
						r.node_shop_buy(i)
					elif str(of["id"]) == "jerrycan":
						r.node_shop_buy(i)
				for j in range(r.parts.size() - 1, -1, -1):
					if r.parts[j] == "jerrycan" and r.phase == "shop":
						pass
				r.leave_node()
				for j2 in range(r.parts.size() - 1, -1, -1):
					if r.phase == "map" and r.parts[j2] == "jerrycan":
						r.use_part(j2)
			_:
				break
	c1["steps"] = int(c1["steps"]) + r.steps
	c1["ap_end"] = int(c1.get("ap_end", 0)) + r.ap
	c1["visits"] = int(c1["visits"]) + r.node_index
	if r.phase == "branch" or (r.phase == "over" and r.won_run):
		c1["clears"] = int(c1["clears"]) + 1
		c1["truck_end"] = int(c1["truck_end"]) + r.truck_hp
	elif r.phase == "over":
		c1["dead"] = int(c1["dead"]) + 1


func _graph_dist(adj: Dictionary, from: String) -> Dictionary:
	var dist := {from: 0}
	var q: Array = [from]
	var i := 0
	while i < q.size():
		var c: String = q[i]
		i += 1
		for nb: String in adj[c]:
			if not dist.has(nb):
				dist[nb] = int(dist[c]) + 1
				q.append(nb)
	return dist


func _pick_dest(r: Run, gdist: Dictionary) -> String:
	var reach: Dictionary = r.reachable()
	var boss: String = str(r.gmap["boss"])
	var best := ""
	var best_s := -1e9
	for k: String in reach.keys():
		if k == r.pos or r.passable(k) or k == boss:
			continue
		var cost: int = int(reach[k])
		var slack: int = r.ap - cost - int(gdist.get(k, 99))
		if slack < 0:
			continue
		var t: String = str(r.gnode(k)["type"]) if str(r.gnode(k)["state"]) != "hidden" else "unknown"
		var v := 2.5
		match t:
			"fight":
				v = 3.0
			"elite":
				v = 2.4
			"event":
				v = 2.2
			"rest":
				v = 5.0 if r.truck_hp < int(r.truck_max * 0.75) else 1.5
			"shop_black":
				v = 3.2 if r.gold >= 8 else 0.6
			"shop_parts":
				v = 1.0 if r.gold >= 6 else 0.2
		var s: float = v - float(cost - 1) * 1.6 + float(mini(slack, 3)) * 0.15
		if s > best_s:
			best_s = s
			best = k
	if best == "" and reach.has(boss) and int(reach[boss]) <= r.ap:
		return boss
	return best


## 实在没有能去的新节点：随便往一个能去的地方挪(花掉行动力)
func _any_move(r: Run) -> String:
	var reach: Dictionary = r.reachable()
	for k: String in reach.keys():
		if k != r.pos and int(reach[k]) <= r.ap:
			return k
	return ""


## 贪心备战：先把装备穿上，再买人(优先能合星/已有的)，多余的钱升级，最后把最强的放上场
func _prepare(r: Run, smart_start: bool) -> void:
	if smart_start:
		# 起手武器：连射弩给速射节点，守誓大剑给誓约节点(开局背包里的两把)
		for id: String in r.roster.keys():
			var d: String = r.roster[id]["def"]
			if d == "node_archer":
				r.equip(id, "rapidfire_arbalest")
			elif d == "node_darkknight":
				r.equip(id, "blackblade")
	var safety := 0
	while safety < 12:
		safety += 1
		var bought := false
		for i in range(r.shop.size()):
			var offer: Dictionary = r.shop[i]
			if offer["sold"]:
				continue
			var def: UnitDef = cat.get_unit(str(offer["def"]))
			var owned := 0
			for u: Dictionary in r.roster.values():
				if u["def"] == def.id:
					owned += 1
			var want: bool = owned >= 1 or r.roster.size() < r.board_capacity() + 2
			if want and r.gold >= def.cost and r.buy(i)["ok"]:
				bought = true
		if not bought:
			if r.gold >= 8 and r.level < r.max_level():
				r.buy_xp()
			elif r.gold >= 6 and safety < 3:
				r.roll_shop(true)
			else:
				break
	_workshop(r)
	_place_best(r)
	_equip_all(r)


## 车间(机器人)：先分解谁都装不上的武器；材料攒够 craft_at 份就全投进去(最多 30)，门类按阵容
func _workshop(r: Run) -> void:
	if not use_workshop:
		return
	for item: String in r.inventory.duplicate():
		var usable := false
		for u: Dictionary in r.roster.values():
			if r.equip_check(u["id"], item)["ok"]:
				usable = true
				break
		if not usable and r.salvage(item)["ok"]:
			ws_stat["salvaged"] = int(ws_stat["salvaged"]) + 1
	if r.material_total() < craft_at:
		return
	var mats: Dictionary = Crafting.empty_mats()
	var left: int = int(Crafting.cfg(cat).get("max_total", 30))
	for m: String in Crafting.MATS:
		var take: int = mini(int(r.materials[m]), left)
		mats[m] = take
		left -= take
	var res: Dictionary = r.craft("weapon", r.craft_team_categories("weapon"), mats)
	if res["ok"]:
		ws_stat["crafted"] = int(ws_stat["crafted"]) + 1
		ws_stat["cost"] = int(ws_stat["cost"]) + cat.get_equipment(str(res["id"])).cost


func _power(u: Dictionary) -> float:
	var d: UnitDef = r_def(u)
	return (float(u["star"]) * 1.0 + 0.5 * float(d.cost)) + (0.3 if u["cell"] != null else 0.0)


func r_def(u: Dictionary) -> UnitDef:
	return cat.get_unit(str(u["def"]))


func _place_best(r: Run) -> void:
	var all: Array = []
	var free_units: Array = []
	for ru: Dictionary in r.roster.values():
		(free_units if r_def(ru).free_deploy else all).append(ru)
	all.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _power(a) > _power(b))
	var want: Array = all.slice(0, r.board_capacity())
	# 先把不需要上场的下场，再把要上场的全部先放回备战席，按"近战外圈迎敌、远程中间"重新摆
	for u: Dictionary in all:
		if u["cell"] != null:
			r.move_unit(u["id"], {"bench": r.free_bench_slot()})
	var wave: Array = r.wave_def()["units"]
	var spawn: Array[Vector2] = cat.wave_positions(wave, r.current_map())
	var cells: Array[Vector2i] = GC.deploy_cells()
	for u2: Dictionary in want:
		var w: EquipmentDef = r.weapon_of(u2)
		var melee: bool = r_def(u2).style_for_weapon(w != null and w.plays_ranged()) in ["melee", "assassin", "tank"]
		var best := Vector2i(-1, -1)
		var best_s := 1e9
		for c2: Vector2i in cells:
			if not r.unit_at_cell(c2).is_empty():
				continue
			var p: Vector2 = GC.cell_to_world(c2.x, c2.y)
			var sc: float = p.length()                      # 远程：越靠卡车越好
			if melee:
				var dmin := 1e9
				for sp: Vector2 in spawn:
					dmin = minf(dmin, p.distance_to(sp))
				sc = dmin                                   # 近战：离来敌最近的格子
			if sc < best_s:
				best_s = sc
				best = c2
		if best.x >= 0:
			r.move_unit(u2["id"], {"cell": best})
	# 不占上阵人数的棋子(空白节点)：站到离来敌最远的空格子(卡车后面)；basic=bench 时一直放在仓库里(对比"拖后腿"的代价)
	for fu: Dictionary in free_units:
		if str(_args.get("basic", "deploy")) == "bench":
			if fu["cell"] != null:
				r.move_unit(fu["id"], {"bench": r.free_bench_slot()})
			continue
		var fbest := Vector2i(-1, -1)
		var fsc := -1.0
		for c3: Vector2i in cells:
			if not r.unit_at_cell(c3).is_empty():
				continue
			var p3: Vector2 = GC.cell_to_world(c3.x, c3.y)
			var dm := 1e9
			for sp3: Vector2 in spawn:
				dm = minf(dm, p3.distance_to(sp3))
			if dm > fsc:
				fsc = dm
				fbest = c3
		if fbest.x >= 0:
			r.move_unit(fu["id"], {"cell": fbest})


## 把背包里的武器给还拿着基础武器、且能用这把武器的场上棋子
func _equip_all(r: Run) -> void:
	for item: String in r.inventory.duplicate():
		for u: Dictionary in r.board_units():
			if str(u["weapon"]) == "" and r.equip_check(u["id"], item)["ok"]:
				r.equip(u["id"], item)
				break


func _dump(b: Battle) -> void:
	print("  -- battle winner=%d  t=%.1fs" % [b.winner, b.end_time - GC.START_DELAY])
	for s: Dictionary in b.summary():
		var u: BUnit = b.get_unit_by_uid(str(s["uid"]))
		print("    %s %-16s %d* %-22s dmg %6.0f  taken %6.0f  heal %5.0f  %s" % ["P" if int(s["team"]) == 0 else "E", s["def"], int(s["star"]),
			u.weapon.id if u.weapon != null else "-", float(s["damage"]), float(s["taken"]), float(s["heal"]), "alive" if bool(s["alive"]) else "dead"])
