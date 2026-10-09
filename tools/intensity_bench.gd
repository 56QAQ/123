extends SceneTree
## 战斗强度基准(用户 2026-10-05 定的强度口径)：拿一套阵容去打某个战斗强度的随机怪物配置(和游戏里普通作战同一套配怪：Run._make_encounter)，
## 胜率到 70% 就算这个强度"通过"；阵容 / 卡的强度 = 最高通过的战斗强度。不再用游戏里不会出现的棋子对决。
##
## 用法: godot --headless --path . --script res://tools/intensity_bench.gd --quit-after 9000000 -- team=node_archer,node_darkknight:2:blackblade,...
##   team=id[:星级[:武器]],…   星级默认 star=(2)；武器默认 weapons=(exclusive|basic)，写 "-" = 基础武器，写武器 id = 指定(装不了的颜色退回基础武器)；
##                              写 basic_<大类>(如 basic_focus)= 换成那个大类的基础武器(量"光换大类"值多少)
##   chapter=ch1_red            用哪一章的配怪(战斗强度的刻度是章节自己的)
##   pass=0.70                  通过线
##   z=1.645                    置信水平(1.645 ≈ 90%)：胜率的 Wilson 置信区间整个在通过线以上 = 通过、整个在以下 = 不通过，
##                              否则接着打——一边倒的少打几场(全胜 7 场、全败 4 场就够)，门槛边缘的多打
##   min=4 max=120              每个强度最少 / 最多打几场(打满还分不出来就按点估计判，标"边缘")
##   lo=4 hi=100 start=14       搜索范围与起点：先按 4 往上 / 往下跳，夹住门槛后二分
##   seed=1                     同一个强度的第 k 场对每套阵容都是同一个配怪、同一张地图(公共随机数：比两张卡时方差小得多)
##   traits=1                   算羁绊(默认算，和游戏里一样；怪物都是白色，现在没有白色羁绊)；traits=0 我方不算羁绊(看羁绊值多少强度)
##   deploy=any                 站位：front = 前压(近战站离来敌最近的格子、远程靠卡车，和 campaign_bench 的机器人一样)；
##                              compact = 抱团(所有人贴着卡车，近战站朝敌人那一侧、远程在他们旁边)；
##                              guard = 护卫(坦克守在卡车边护着远程，其余近战前压；阵容里没有近战坦克就跳过)；
##                              any(默认) = 每个强度依次试 前压 → 抱团 → 护卫，有一种通过就算通过
##                              (玩家会按阵容调站位：同一套阵容换个站法能差好几档强度，例如 速射 + 架盾(电击器) + 耕植 前压 6、护卫 12)
##   eternal=node_pacifist:node_pacifist_song:10[:星级]   我方每个(别的)棋子开战时已经带着这个被动的永恒状态 10 层(共歌节点的沉醉打到一局中途的样子)
##   mods=powder_boost,sharp_arms   这一局已选的卡车改装(Catalog.mods 的 id；看某个改装值多少强度)
##   label=xxx                  输出里的名字(批量跑时区分)；quiet=1 只打印最后一行；verbose=1 打印每一场(配怪、胜负、站位)
## 刻度：战斗强度是绝对刻度(2026-10-05 重做配怪：强度每 +1 难度都平滑地涨；强怪 = 普通作战加几级强度，没有单独的怪池)。
##   mode=curve 打一条"胜率 − 强度"曲线(检查平滑)；mode=calib 打怪物强度点数的标定数据(给 tools/fit_power.py)。
##   mode=fitprobe units=a,b,… [base=… iv=40 n=6]：量棋子的武器触发器实战里每秒触发几次、每次几个目标、目标是敌是友(见 run_fitprobe)，
##     给 tools/fit_tags.py 定触发器的内置适配标签(./run_fitprobe.sh)。
## 并行比较几套阵容 / 几张卡用 ./run_intensity.sh。
## 输出：每个测过的强度一行(胜场 / 场数、胜率、置信区间、判定)，最后 "RESULT <label> 最高通过强度 N"
const TEAM_PLAYER := 0
const DEPLOY_NAME := {"front": "前压", "compact": "抱团", "guard": "护卫"}

var cat: Catalog
var args := {}
var run: Run
var team: Array = []          # [{def, star, weapon}]
var cache := {}               # 强度 -> {w, n, pass, edge, dep, tries}
var deploys: Array = ["front", "compact", "guard"]   # deploy=any 时依次试的站位
var deploy := "front"                       # 当前这一场用的站位
var p0 := 0.7
var z := 1.645
var min_n := 4
var max_n := 120
var seed0 := 1
var fights := 0
var last_battle: Battle = null               # 最近打完的一场
var step_hook := Callable()                   # 设了就每一步把这一步的表现事件交给它(mode=fitprobe)；run_to_end 每步都清空事件


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	cat = Catalog.load_all()
	p0 = float(args.get("pass", "0.70"))
	z = float(args.get("z", "1.645"))
	min_n = int(args.get("min", "4"))
	max_n = int(args.get("max", "120"))
	seed0 = int(args.get("seed", "1"))
	if str(args.get("mode", "")) == "fitprobe":
		run_fitprobe()
		quit()
		return
	if not args.has("team"):
		push_error("intensity_bench: team=… is required")
		quit(1)
		return
	team = parse_team(str(args["team"]))
	var chap: String = str(args.get("chapter", "ch1_red"))
	if not cat.chapters.has(chap):
		push_error("intensity_bench: unknown chapter " + chap)
		quit(1)
		return
	setup_run(chap)
	var dep: String = str(args.get("deploy", "any"))
	if dep != "any":
		deploys = [dep]
	elif not has_melee_tank():
		deploys.erase("guard")                       # 没有近战坦克：护卫和前压摆得一模一样
	var label: String = str(args.get("label", str(args["team"])))
	var t0 := Time.get_ticks_msec()
	match str(args.get("mode", "")):
		"curve":
			run_curve(label)
			quit()
			return
		"calib":
			run_calib(label)
			quit()
			return
	var lo: int = int(args.get("lo", "4"))
	var best: int = search(lo, int(args.get("hi", "100")), int(args.get("start", "14")))
	_report(label, best, lo, chap, t0)
	quit()


## 按 team 建一局：进章节、清空花名册、按顺序摆上阵容里的棋子(各带指定的武器 / 形态)
func setup_run(chap: String) -> void:
	run = Run.create(cat, seed0)
	run.enter_chapter(chap, false)
	if args.has("max_star"):                          # max_star=16:32 试别的星级上限(从这个强度起允许 2 星 / 3 星)
		var ms: PackedStringArray = str(args["max_star"]).split(":")
		run.chapter = run.chapter.duplicate(true)
		run.chapter["max_star"] = [[0, 1], [int(ms[0]), 2], [int(ms[1]), 3]]
	run.roster.clear()
	run.inventory.clear()
	for mid: String in str(args.get("mods", "")).split(","):
		if mid != "" and cat.mods.has(mid):
			run.truck_mods.append(mid)
	run.level = team.size()
	for i in range(team.size()):
		var t: Dictionary = team[i]
		var u: Dictionary = run.add_unit(str(t["def"]), int(t["star"]), null, i)
		u["weapon"] = str(t["weapon"])
		if str(t.get("form", "")) != "":
			u["form"] = str(t["form"])                 # node_pianist@angel：带形态的棋子(变奏节点)


func _report(label: String, best: int, lo: int, chap: String, t0: int) -> void:
	if not bool(int(args.get("quiet", "0"))):
		print("阵容 %s(★%s，%s，羁绊%s)，%s 的配怪，通过线 %d%%" % [label, str(args.get("star", "2")), str(args.get("weapons", "exclusive")),
			"算" if str(args.get("traits", "1")) != "0" else "不算", chap, int(p0 * 100.0)])
		var lineup: Array = []
		for t2: Dictionary in team:
			lineup.append("%s★%d%s" % [str(t2["def"]).trim_prefix("node_"), int(t2["star"]), ("·" + str(t2["weapon"])) if str(t2["weapon"]) != "" else ""])
		print("  " + "、".join(lineup))
		print_table(cache)
	var shown: String = shown_iv(best, lo, int(args.get("hi", "100")))
	var nxt := ""
	for k2: int in cache.keys():
		if k2 > best and not bool(cache[k2]["pass"]) and (nxt == "" or k2 < int(nxt)):
			nxt = str(k2)
	var extra := ""
	if deploys.size() > 1 and cache.has(best):
		extra = "(%s)" % DEPLOY_NAME.get(str(cache[best].get("dep", "")), "")
	print("RESULT %s 最高通过强度 %s%s%s  (%d 场，%.0f 秒)" % [label, shown, ("，%s 不通过" % nxt) if nxt != "" else "", extra, fights, float(Time.get_ticks_msec() - t0) / 1000.0])
	quit()


## mode=fitprobe：棋子的武器触发器(tags 带 equipment_payload)在实战里是什么样子——给它装一把什么都不做的探针武器
## (它自己基础大类的；能力【基本】【群攻 99】、all_targets、空效果：每次触发都执行、触发器给出的目标全都"吃到")，
## 和 base 阵容一起打 n 场这一章强度 iv 的随机配怪，按 trigger 事件统计：每秒触发几次、每次几个目标、目标里自己 / 队友 / 敌人各占多少。
## 每个触发器打印一行 "FIT <棋子> <触发器> rate=<次/秒> tgt=<平均目标数> self=… ally=…(不含自己) enemy=… fires=<次数> time=<总秒数> val=<平均触发数值>"，
## 交给 tools/fit_tags.py 写成触发器的内置适配标签。units=a,b,…(默认：所有进商店的棋子)、base=(速射,架盾,耕植)、iv=40、n=6、star=2；
## class=<大类>：探针换成那个大类(设计某个大类的武器时量"拿上它以后"的样子；写进适配标签的数据要用默认的基础大类)
func run_fitprobe() -> void:
	for cls: String in GC.WEAPON_CLASSES.keys():
		var pid: String = "fit_probe_" + cls
		cat.equipment[pid] = EquipmentDef.from_dict({"id": pid, "cost": 1, "color_id": "black", "weapon_class": cls,
			"abilities": [{"id": pid, "ability_class": "blade", "effect_type": "none", "keywords": ["basic", "multi_attack"],
				"keyword_values": {"multi_attack": 99}, "required_trigger_tags": ["equipment_payload"], "effect_config": {"all_targets": true}}]})
	var ids: Array[String] = []
	for s0: String in str(args.get("units", "")).split(",", false):
		ids.append(s0)
	if ids.is_empty():
		ids = cat.shop_unit_ids()
	var base: String = str(args.get("base", "node_archer,node_shielder,node_peasant"))
	var star: String = str(args.get("star", "2"))
	var iv: int = int(args.get("iv", "40"))
	var n: int = int(args.get("n", "6"))
	var chap: String = str(args.get("chapter", "ch1_red"))
	deploy = "front"
	for uid: String in ids:
		var ud: UnitDef = cat.get_unit(uid)
		if ud == null:
			continue
		var trig_ids: Array[String] = []
		for tr: TriggerDef in ud.triggers:
			if tr.tags.has("equipment_payload"):
				trig_ids.append(tr.id)
		if trig_ids.is_empty():
			continue
		# class=<大类>：探针武器用这个大类(棋子能拿的话)——量"换成这个大类以后"触发器的样子(手枪攻速快还带追击，触发得更勤)
		var pcls: String = str(args.get("class", ud.base_weapon_class))
		if not ud.can_use_weapon_class(pcls):
			pcls = ud.base_weapon_class
		team = parse_team("%s,%s:%s:fit_probe_%s" % [base, uid, star, pcls])
		setup_run(chap)
		var st := {}
		for tid: String in trig_ids:
			st[tid] = {"fires": 0, "tgt": 0, "self": 0, "ally": 0, "enemy": 0, "val": 0.0}
		var time := 0.0
		step_hook = func(b: Battle) -> void:
			for e: Dictionary in b.events:
				if str(e.get("t", "")) != "trigger" or not st.has(str(e.get("trigger", ""))):
					continue
				var u: BUnit = e.get("unit") as BUnit
				if u == null or u.def.id != uid or u.is_summon:
					continue
				var row: Dictionary = st[str(e["trigger"])]
				row["fires"] = int(row["fires"]) + 1
				row["val"] = float(row["val"]) + float(e.get("value", 0.0))
				for tu: Variant in e.get("targets", []):
					var t: BUnit = tu as BUnit
					if t == null:
						continue
					row["tgt"] = int(row["tgt"]) + 1
					var side: String = "self" if t == u else ("ally" if t.team == u.team else "enemy")
					row[side] = int(row[side]) + 1
		for k in range(n):
			fight(iv, k)
			time += last_battle.time
		step_hook = Callable()
		for tid2: String in trig_ids:
			var r: Dictionary = st[tid2]
			var f: int = int(r["fires"])
			var tg: int = maxi(1, int(r["tgt"]))
			print("FIT %s %s rate=%.3f tgt=%.2f self=%.2f ally=%.2f enemy=%.2f fires=%d time=%.0f val=%.0f" % [uid, tid2, float(f) / maxf(1.0, time),
				float(r["tgt"]) / maxf(1.0, float(f)), float(r["self"]) / tg, float(r["ally"]) / tg, float(r["enemy"]) / tg, f, time, float(r["val"]) / maxf(1.0, float(f))])


## mode=curve：从 lo 到 hi(步长 step)每个强度固定打 n 场(固定站位 deploy，默认前压)，打印 "CURVE <label> <强度> <胜> <场>"——看难度是不是随强度平滑上升
## kind=elite / boss：打精英战 / 首领战的曲线(首领战把首领强度临时改成 iv)——看"同样的强度 = 同样多的资源"
func run_curve(label: String) -> void:
	deploy = deploys[0]
	var n: int = int(args.get("n", "40"))
	var kind: String = str(args.get("kind", "fight"))
	var iv: int = int(args.get("lo", "6"))
	while iv <= int(args.get("hi", "60")):
		var w := 0
		for k in range(n):
			var ok := false
			if kind == "fight":
				ok = fight(iv, k)
			else:
				run.rng.seed = seed0 * 1000003 + iv * 7919 + k * 104729
				if kind == "boss":
					(run.chapter["intensity"] as Dictionary)["boss"] = iv
				var enc: Dictionary = run._make_encounter(kind, iv) if kind == "elite" else run._make_encounter(kind)
				ok = fight_enc(enc, iv * 1000 + k, iv, k)
			if ok:
				w += 1
		print("CURVE %s %d %d %d" % [label, iv, w, n])
		iv += int(args.get("step", "2"))


## mode=calib：给怪物强度点数做标定用的数据。随机配一群怪(普通余烬 / 精英 + 手下 / 首领单挑；数量、星级、整体生命攻击倍率都随机)，
## 让这套阵容打 n 场，每场打印 "CALIB <label> <胜0/1> <种类> <怪1:星:倍率>|<怪2:星:倍率>|…"，交给 tools/fit_power.py 拟合
## ref=阵容大概能过的强度(按粗估的点数把配怪的总量撒在 ref × e^±0.6 里，胜负才有信息量)
func run_calib(label: String) -> void:
	deploy = deploys[0]
	var n: int = int(args.get("n", "200"))
	var ref: float = float(args.get("ref", "15"))
	var mobs: Array = []                                  # 普通余烬(monsters 里 head = 精英 / 首领的本体，不算)
	for mid: String in (run.chapter.get("monsters", {}) as Dictionary).keys():
		if not bool((run.chapter["monsters"][mid] as Dictionary).get("head", false)):
			mobs.append(mid)
	var crng := RandomNumberGenerator.new()
	crng.seed = hash(label) + seed0 * 7777
	var gen: bool = str(args.get("gen", "0")) == "1"
	var spread: float = float(args.get("spread", "0.6"))
	for k in range(n):
		var target: float = ref * exp(crng.randf_range(-spread, spread))
		if gen:
			calib_gen(label, target, crng, k)
			continue
		var units: Array = []
		var kind := "mobs"
		var roll: float = crng.randf()
		if roll < 0.12:
			kind = "boss"
			units.append([str((run.chapter["boss"] as Dictionary)["unit"]), 1 if crng.randf() < 0.6 else 2, "n", "", {"boss": true}])
		elif roll < 0.36:
			kind = "elite"
			var els: Array = run.chapter.get("elites", [])
			var el: Dictionary = els[crng.randi() % els.size()]
			units.append([str(el["unit"]), 1 if crng.randf() < 0.65 else 2, "n", "", {"elite": true}])
			var forms: Array = el.get("forms", [])
			var cnt: int = crng.randi_range(0, 4)
			for i in range(cnt):
				var pick: String = str(mobs[crng.randi() % mobs.size()])
				if not forms.is_empty():
					var f: Dictionary = forms[crng.randi() % forms.size()]
					var lst: Array = (f.get("req", []) as Array) + (f.get("extra", []) as Array)
					pick = str(lst[crng.randi() % lst.size()])
				units.append([pick, 1, "n", "", {}])
		else:
			var cnt2: int = crng.randi_range(2, 6)
			for i in range(cnt2):
				units.append([str(mobs[crng.randi() % mobs.size()]), 1, "n", "", {}])
		# 星级：按目标总量粗估该升几星(只给普通余烬随机升星)
		var lvl: float = crng.randf()
		for e: Array in units:
			if (e[4] as Dictionary).has("boss") or (e[4] as Dictionary).has("elite"):
				continue
			var hi_star: int = 1 if target < 14.0 else (2 if target < 30.0 else 3)
			e[1] = clampi(1 + int(floor(lvl * float(hi_star) + crng.randf_range(-0.5, 0.5))), 1, 3)
		# 整体倍率：把粗估点数拉到目标附近，再随机抖一下(倍率本身也是要拟合的量)
		var rough := 0.0
		for e2: Array in units:
			rough += _rough_power(str(e2[0]), int(e2[1]))
		var m: float = clampf(pow(target / maxf(rough, 0.1), 1.0 / run._scale_exp()) * exp(crng.randf_range(-0.15, 0.15)), 0.35, 2.2)
		var regs: Array = (run.chapter.get("regions", [["n", "nw", "ne"]]) as Array)[crng.randi() % (run.chapter.get("regions", [["n"]]) as Array).size()]
		var desc: Array = []
		for i2 in range(units.size()):
			var e3: Array = units[i2]
			e3[2] = str(regs[i2 % regs.size()])
			(e3[4] as Dictionary)["hp_mult"] = m
			(e3[4] as Dictionary)["atk_mult"] = m
			desc.append("%s:%d:%.3f" % [e3[0], e3[1], m])
		var bm: Dictionary = run.chapter.get("battle_map", {})
		var enc := {"units": units, "map": (bm.get("fight", bm.get("weak", {})) as Dictionary).duplicate(), "pool": "calib", "intensity": 0}
		(enc["map"] as Dictionary)["theme"] = str(run.chapter.get("theme", "white"))
		var win: bool = fight_enc(enc, 900000 + k)
		print("CALIB %s %d %s %s" % [label, 1 if win else 0, kind, "|".join(desc)])


## gen=1：标定数据直接用游戏的配怪算法生成(普通作战 / 精英 / 首领，强度 = 目标点数)，覆盖的正好是游戏里会出现的组合与倍率
func calib_gen(label: String, target: float, crng: RandomNumberGenerator, k: int) -> void:
	var iv: int = maxi(4, int(round(target)))
	var roll: float = crng.randf()
	var kind := "mobs"
	run.rng.seed = hash(label) + seed0 * 7777 + k * 104729
	var enc: Dictionary
	if roll < 0.15:
		kind = "boss"
		(run.chapter["intensity"] as Dictionary)["boss"] = iv
		enc = run._make_encounter("boss")
	elif roll < 0.40:
		kind = "elite"
		enc = run._make_encounter("elite", iv)
	else:
		enc = run._make_encounter("fight", iv)
	var desc: Array = []
	for e: Array in enc["units"]:
		desc.append("%s:%d:%.3f" % [e[0], e[1], float((e[4] as Dictionary).get("hp_mult", 1.0))])
	var win: bool = fight_enc(enc, 900000 + k)
	print("CALIB %s %d %s %s" % [label, 1 if win else 0, kind, "|".join(desc)])


## 粗估 = 章节数据里现在的点数(只用来把标定数据撒在有信息量的范围里；新的点数由拟合给出，可以一轮一轮迭代)
func _rough_power(id: String, star: int) -> float:
	return run._unit_power(id, star)


func shown_iv(v: int, lo: int, hi: int) -> String:
	if v == -1:
		return "<%d" % lo
	if v >= hi:
		return "≥%d" % v
	return str(v)


## 每个测过的强度一行
func print_table(c0: Dictionary) -> void:
	var ks: Array = c0.keys()
	ks.sort()
	for k: int in ks:
		var c: Dictionary = c0[k]
		var ci: Vector2 = wilson(int(c["w"]), int(c["n"]))
		var other := ""
		for d: String in (c.get("tries", {}) as Dictionary).keys():
			if d != str(c.get("dep", "")):
				var o: Dictionary = c["tries"][d]
				other += "，%s %d/%d" % [DEPLOY_NAME.get(d, d), o["w"], o["n"]]
		print("  强度 %2d: %3d/%-3d %3d%%  [%3d%%, %3d%%]  %s%s" % [k, c["w"], c["n"], int(100.0 * float(c["w"]) / float(c["n"])), int(ci.x * 100.0), int(ci.y * 100.0),
			("通过" if c["pass"] else "不通过") + ("(边缘)" if c["edge"] else ""),
			("  [%s%s]" % [DEPLOY_NAME.get(str(c.get("dep", "")), ""), other]) if deploys.size() > 1 else ""])


## team=id[:星级[:武器]],…
func parse_team(spec: String) -> Array:
	var star_def: int = int(args.get("star", "2"))
	var use_ex: bool = str(args.get("weapons", "exclusive")) == "exclusive"
	var ex_of := {}
	for eid: String in cat.equipment.keys():
		var e: EquipmentDef = cat.get_equipment(eid)
		if e.owner != "":
			ex_of[e.owner] = eid
	var r: Array = []
	for part: String in spec.split(",", false):
		var bits: PackedStringArray = part.split(":")
		var id: String = bits[0]
		var form := ""
		if id.contains("@"):
			form = id.get_slice("@", 1)
			id = id.get_slice("@", 0)
		if cat.get_unit(id) == null:
			push_error("intensity_bench: unknown unit " + id)
			continue
		var star: int = int(bits[1]) if bits.size() > 1 and bits[1] != "" else star_def
		var w: String = str(ex_of.get(id, "")) if use_ex else ""
		if bits.size() > 2:
			w = "" if bits[2] == "-" else bits[2]
		var we: EquipmentDef = cat.get_equipment(w) if w != "" else null
		# basic_<大类>：换成别的大类的基础武器(量"只是换大类"值多少——比如正行拿法器)
		var basic_ok: bool = we != null and we.basic and cat.get_unit(id).can_use_weapon_class(we.class_id)
		if w != "" and not basic_ok and (we == null or we.equip_problem(cat.get_unit(id), star) != ""):
			w = ""                                     # 装不了(颜色 / 大类 / 星级)：基础武器
		r.append({"def": id, "star": star, "weapon": w, "form": form})
	return r


# ---------------------------------------------------------------- 搜索最高通过强度
func passed(iv: int) -> bool:
	if not cache.has(iv):
		cache[iv] = evaluate(iv)
	return bool(cache[iv]["pass"])


## 先按 4 往上(或往下)跳着找，夹住门槛以后二分；返回最高通过的强度，lo 都不通过 = -1
func search(lo: int, hi: int, start: int) -> int:
	start = clampi(start, lo, hi)
	var ok_iv := -1
	var bad_iv := hi + 1
	if passed(start):
		ok_iv = start
		var step := 4
		var probe: int = start + step
		while probe <= hi:
			if passed(probe):
				ok_iv = probe
				step *= 2
				probe = mini(hi, ok_iv + step) if ok_iv < hi else hi + 1
			else:
				bad_iv = probe
				break
		if ok_iv >= hi:
			return hi
	else:
		bad_iv = start
		var probe2: int = start - 4
		while probe2 >= lo:
			if passed(probe2):
				ok_iv = probe2
				break
			bad_iv = probe2
			probe2 -= 4
		if ok_iv < 0:
			if bad_iv > lo and passed(lo):
				ok_iv = lo
			else:
				return -1
	while bad_iv - ok_iv > 1:
		var mid: int = (ok_iv + bad_iv) / 2
		if passed(mid):
			ok_iv = mid
		else:
			bad_iv = mid
	return ok_iv


## 一个强度：依次试各种站位，有一种通过就算通过(记下每种的战绩)
func evaluate(iv: int) -> Dictionary:
	var tries := {}
	var r: Dictionary = {}
	for d: String in deploys:
		deploy = d
		r = evaluate_one(iv)
		r["dep"] = d
		tries[d] = r
		if bool(r["pass"]):
			break
	r = r.duplicate()
	r["tries"] = tries
	return r


## 一种站位：一场一场打，Wilson 区间整个在通过线以上 / 以下就停
func evaluate_one(iv: int) -> Dictionary:
	var w := 0
	var n := 0
	while true:
		if fight(iv, n):
			w += 1
		n += 1
		if n >= min_n:
			var ci: Vector2 = wilson(w, n)
			if ci.x >= p0:
				return {"w": w, "n": n, "pass": true, "edge": false}
			if ci.y < p0:
				return {"w": w, "n": n, "pass": false, "edge": false}
		if n >= max_n:
			return {"w": w, "n": n, "pass": float(w) / float(n) >= p0, "edge": true}
	return {}


static func wilson_s(w: int, n: int, zz: float) -> Vector2:
	if n <= 0:
		return Vector2(0.0, 1.0)
	var p: float = float(w) / float(n)
	var z2: float = zz * zz
	var den: float = 1.0 + z2 / float(n)
	var cen: float = (p + z2 / (2.0 * float(n))) / den
	var half: float = zz * sqrt(p * (1.0 - p) / float(n) + z2 / (4.0 * float(n) * float(n))) / den
	return Vector2(maxf(0.0, cen - half), minf(1.0, cen + half))


func wilson(w: int, n: int) -> Vector2:
	return wilson_s(w, n, z)


## 第 k 场：配怪、地图、战斗的随机数都只由 (seed, 强度, k) 决定
func fight(iv: int, k: int) -> bool:
	run.rng.seed = seed0 * 1000003 + iv * 7919 + k * 104729
	var enc: Dictionary = run._make_encounter("fight", iv)
	return fight_enc(enc, iv * 1000 + k, iv, k)


## 打一场给定的遭遇(fight 用游戏的配怪，calib 用随机配的怪)
func fight_enc(enc: Dictionary, visit: int, iv: int = 0, k: int = 0) -> bool:
	fights += 1
	run.seed_value = seed0
	run.visits = visit
	var nd: Dictionary = run.gnode(run.pos)
	nd["encounter"] = enc
	nd["layout"] = run._make_layout(enc)
	run.phase = "prepare"
	place()
	var setup: Dictionary = run.build_battle_setup()
	if str(args.get("traits", "1")) == "0":
		(setup["cfg"] as Dictionary)["traits"] = false
	# eternal=<被动所在的单位>:<被动>:<层数>[:<星级>]：我方每个棋子开战时已经带着这个被动的永恒状态 N 层(模拟一局打到中途：共歌节点的沉醉)
	if args.has("eternal"):
		var ep: PackedStringArray = str(args["eternal"]).split(":")
		var pa: AbilityDef = cat.get_unit(ep[0]).passive_by_id(ep[1])
		var scfg: Dictionary = pa.effect_config.get("status", pa.effect_config)
		var est: int = int(ep[3]) if ep.size() > 3 else int(args.get("star", "2"))
		var flat := {}
		for k0: String in (scfg.get("stats_by_star", {}) as Dictionary).keys():
			var bys: Dictionary = scfg["stats_by_star"][k0].get("flat", {})
			flat[k0] = float(bys.get(str(est), 0.0))
		for su0: Dictionary in setup["units"]:
			if int(su0.get("team", 0)) == GC.TEAM_PLAYER and str(su0["def"]) != ep[0]:
				su0["eternal"] = [{"id": str(scfg.get("status_id", ep[1])), "stacks": int(ep[2]), "max_stacks": int(pa.keyword_value("stacking", 1)),
					"flat": flat, "pct": {}, "flags": scfg.get("flags", [])}]
	var b := Battle.new(cat, run.rng.randi())
	b.setup(setup)
	if step_hook.is_valid():
		b.start()
		var guard: int = int((GC.BATTLE_MAX_SECONDS + 5.0) / GC.SIM_DT) + 10
		while b.state != "ended" and guard > 0:
			b.step()
			step_hook.call(b)
			b.events.clear()
			guard -= 1
	else:
		b.run_to_end()
	last_battle = b
	if bool(int(args.get("verbose", "0"))):
		var foes: Array = []
		for e: Array in enc["units"]:
			foes.append("%s★%d" % [str(e[0]).trim_prefix("ember_"), int(e[1])])
		var mine: Array = []
		for su: Dictionary in setup["units"]:
			if int(su.get("team", 0)) == TEAM_PLAYER:
				mine.append("%s@%s" % [str(su["def"]).trim_prefix("node_"), str(su.get("cell", su.get("pos")))])
		print("    强度 %d #%d %s %.1fs  敌[%s] %s  %s[%s]" % [iv, k, "胜" if b.winner == TEAM_PLAYER else "负", b.time, ", ".join(foes), str(enc["pool"]),
			DEPLOY_NAME.get(deploy, deploy), ", ".join(mine)])
	return b.winner == TEAM_PLAYER


## 摆位。前压(和 campaign_bench 的机器人一样)：近战站离来敌最近的格子、远程站离卡车最近的格子；
## 抱团：都贴着卡车，近战挑朝敌人那一侧、远程挨着他们；不占人数的(空白节点)都站到离来敌最远的空格；会坠落的(星旅节点)留在仓库
func place() -> void:
	var all: Array = []
	for ru: Dictionary in run.roster.values():
		if ru["cell"] != null:
			run.move_unit(ru["id"], {"bench": run.free_bench_slot()})
		if not run.unit_def(ru).bench_drop:          # 星旅节点留在仓库：开战时从仓库坠落(她本来的用法)
			all.append(ru)
	var wave: Array = run.wave_def()["units"]
	var spawn: Array[Vector2] = cat.wave_positions(wave, run.current_map())
	var cells: Array[Vector2i] = GC.deploy_cells()
	# 近战先摆(抢前排)，远程后摆
	all.sort_custom(func(a: Dictionary, b2: Dictionary) -> bool: return int(_melee(a)) > int(_melee(b2)))
	for u: Dictionary in all:
		var free: bool = run.unit_def(u).free_deploy
		var melee: bool = _melee(u)
		var best := Vector2i(-1, -1)
		var best_s := 1.0e9
		for c: Vector2i in cells:
			if not run.unit_at_cell(c).is_empty():
				continue
			var p: Vector2 = GC.cell_to_world(c.x, c.y)
			var dmin := 1.0e9
			for sp: Vector2 in spawn:
				dmin = minf(dmin, p.distance_to(sp))
			var sc: float = p.length()
			if free:
				sc = -dmin
			elif deploy == "compact":
				sc = p.length() + (0.5 if melee else 0.2) * dmin
			elif deploy == "guard" and melee and run.unit_def(u).role == "tank":
				sc = p.length() + 0.2 * dmin                 # 守在卡车边(偏向来敌一侧一点，别躲到卡车背后)
			elif melee:
				sc = dmin
			if sc < best_s:
				best_s = sc
				best = c
		if best.x >= 0:
			run.move_unit(u["id"], {"cell": best})


func has_melee_tank() -> bool:
	for u: Dictionary in run.roster.values():
		if _melee(u) and run.unit_def(u).role == "tank":
			return true
	return false


func _melee(u: Dictionary) -> bool:
	var w: EquipmentDef = run.weapon_of(u)
	return run.unit_def(u).style_for_weapon(w != null and w.plays_ranged()) in ["melee", "assassin", "tank"]       # 电击器(射程归零的手枪)按近战摆
