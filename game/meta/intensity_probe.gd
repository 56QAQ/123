class_name IntensityProbe
extends RefCounted
## 战斗强度阈值测试(测试场里用；口径和 tools/intensity_bench.gd 一样)：
## 阵容去打某个战斗强度的随机配怪(和游戏里普通作战同一套 Run._make_encounter)，胜率的 Wilson 区间整个在通过线以上 = 这个强度通过、
## 整个在以下 = 不通过，否则接着打(一边倒的少打几场，门槛边缘的多打，最多 max_n 场，打满按点估计判、标"边缘")；
## 先按 4 往上 / 往下跳着找，夹住门槛后二分；阵容的强度 = 最高通过的战斗强度。
## 不依赖场景树、也不自己打仗：调用方 next_job() 取下一场 → make_battle(job) 生成战斗 → 自己 step(可以分帧) → report(胜负)。
## 同一个强度的第 k 场永远是同一个配怪 / 地图 / 随机数(公共随机数)，结果可复现。

const DEPLOY_ORDER: Array[String] = ["front", "compact", "guard"]

var cat: Catalog
var run: Run                       # 测试用的 Run(和测试场的 Run 分开)
var traits := true
var keep_cells := false            # true = 按玩家自己摆的位置打；false = 每个强度依次试 前压 / 抱团 / 护卫，有一种通过就算
var p0 := 0.7
var z := 1.645
var min_n := 4
var max_n := 120
var lo := 4
var hi := 100
var seed0 := 1
var deploys: Array[String] = []
var cache := {}                    # 强度 -> {w, n, pass, edge, dep, tries}
var best := -1                     # 最高通过的强度(-1 = lo 都过不了；≥ hi = 刻度封顶)
var done := false
var fights := 0
# 当前在评估的强度
var cur_iv := -1
var _dep_i := 0
var _w := 0
var _n := 0
var _tries := {}
# 搜索状态
var _stage := ""
var _ok := -1
var _bad := 0
var _step := 4
var _probe := 0


## team = [{def, star, weapon, cell}]；opts: traits / keep_cells / pass / min / max / lo / hi / start / seed / chapter
func setup(p_cat: Catalog, team: Array, opts: Dictionary = {}) -> void:
	cat = p_cat
	traits = bool(opts.get("traits", true))
	keep_cells = bool(opts.get("keep_cells", false))
	p0 = float(opts.get("pass", 0.7))
	min_n = int(opts.get("min", 4))
	max_n = int(opts.get("max", 120))
	lo = int(opts.get("lo", 4))
	hi = int(opts.get("hi", 100))
	seed0 = int(opts.get("seed", 1))
	run = Run.create(cat, seed0, str(opts.get("chapter", "ch1_red")))
	run.sandbox = true
	run.roster.clear()
	run.inventory.clear()
	for i in range(team.size()):
		var t: Dictionary = team[i]
		var u: Dictionary = run.add_unit(str(t["def"]), int(t["star"]), null, i)
		u["weapon"] = str(t.get("weapon", ""))
		if keep_cells and t.get("cell") != null:
			u["cell"] = t["cell"]
			u["bench"] = -1
	if keep_cells:
		deploys = ["mine"]
	else:
		deploys = DEPLOY_ORDER.duplicate()
		if not _has_melee_tank():
			deploys.erase("guard")                     # 没有近战坦克：护卫和前压摆得一模一样
	_stage = "start"
	_eval(clampi(int(opts.get("start", 14)), lo, hi))


static func wilson(w: int, n: int, zz: float = 1.645) -> Vector2:
	if n <= 0:
		return Vector2(0.0, 1.0)
	var p: float = float(w) / float(n)
	var z2: float = zz * zz
	var den: float = 1.0 + z2 / float(n)
	var cen: float = (p + z2 / (2.0 * float(n))) / den
	var half: float = zz * sqrt(p * (1.0 - p) / float(n) + z2 / (4.0 * float(n) * float(n))) / den
	return Vector2(maxf(0.0, cen - half), minf(1.0, cen + half))


# ---------------------------------------------------------------- 一场一场地打
## 下一场：{iv, k, deploy}；测完了 = {}
func next_job() -> Dictionary:
	if done:
		return {}
	return {"iv": cur_iv, "k": _n, "deploy": deploys[_dep_i]}


## 当前强度的进度(界面用)
func progress() -> Dictionary:
	return {"iv": cur_iv, "w": _w, "n": _n, "deploy": deploys[_dep_i] if _dep_i < deploys.size() else "", "fights": fights}


## 生成这一场的战斗(已 setup，还没开打)：配怪、地图、随机数只由 (seed, 强度, 第几场) 决定
func make_battle(job: Dictionary) -> Battle:
	var iv: int = int(job["iv"])
	var k: int = int(job["k"])
	run.rng.seed = seed0 * 1000003 + iv * 7919 + k * 104729
	var enc: Dictionary = run._make_encounter("fight", iv)
	for e: Array in enc["units"]:
		(e[4] as Dictionary).erase("orb")
	run.seed_value = seed0
	run.visits = iv * 1000 + k
	var nd: Dictionary = run.gnode(run.pos)
	nd["encounter"] = enc
	nd["layout"] = run._make_layout(enc)
	run.phase = "prepare"
	if str(job["deploy"]) != "mine":
		place(str(job["deploy"]))
	var setup: Dictionary = run.build_battle_setup()
	if not traits:
		(setup["cfg"] as Dictionary)["traits"] = false
	var b := Battle.new(cat, run.rng.randi())
	b.setup(setup)
	return b


## 报告这一场的胜负(job 就是 next_job() 给的那一场)
func report(win: bool) -> void:
	if done:
		return
	fights += 1
	_n += 1
	if win:
		_w += 1
	var dec := ""
	if _n >= min_n:
		var ci: Vector2 = wilson(_w, _n, z)
		if ci.x >= p0:
			dec = "pass"
		elif ci.y < p0:
			dec = "fail"
	if dec == "" and _n >= max_n:
		dec = "pass_edge" if float(_w) / float(_n) >= p0 else "fail_edge"
	if dec == "":
		return
	var r := {"w": _w, "n": _n, "pass": dec.begins_with("pass"), "edge": dec.ends_with("edge"), "dep": deploys[_dep_i]}
	_tries[deploys[_dep_i]] = r
	if not bool(r["pass"]) and _dep_i + 1 < deploys.size():
		_dep_i += 1                                   # 这种站位没过：换下一种站位从第 0 场重打
		_w = 0
		_n = 0
		return
	var res: Dictionary = r.duplicate()
	res["tries"] = _tries
	cache[cur_iv] = res
	_decided(cur_iv, bool(res["pass"]))


# ---------------------------------------------------------------- 搜索：先按 4 往上 / 往下跳，夹住门槛后二分
func _eval(iv: int) -> void:
	if cache.has(iv):
		_decided(iv, bool(cache[iv]["pass"]))
		return
	cur_iv = iv
	_dep_i = 0
	_w = 0
	_n = 0
	_tries = {}


func _decided(iv: int, ok: bool) -> void:
	match _stage:
		"start":
			if ok:
				_ok = iv
				_step = 4
				_probe = iv + 4
				_up()
			else:
				_bad = iv
				_probe = iv - 4
				_down()
		"up":
			if ok:
				_ok = iv
				_step *= 2
				_probe = mini(hi, _ok + _step) if _ok < hi else hi + 1
				_up()
			else:
				_bad = iv
				_bisect()
		"down":
			if ok:
				_ok = iv
				_bisect()
			else:
				_bad = iv
				_probe = iv - 4
				_down()
		"lo":
			if ok:
				_ok = iv
				_bisect()
			else:
				_finish(-1)
		"bisect":
			if ok:
				_ok = iv
			else:
				_bad = iv
			_bisect()


func _up() -> void:
	if _probe <= hi:
		_stage = "up"
		_eval(_probe)
	elif _ok >= hi:
		_finish(hi)
	else:
		_bad = hi + 1
		_bisect()


func _down() -> void:
	if _probe >= lo:
		_stage = "down"
		_eval(_probe)
	elif _bad > lo:
		_stage = "lo"
		_eval(lo)
	else:
		_finish(-1)


func _bisect() -> void:
	if _bad - _ok > 1:
		_stage = "bisect"
		_eval((_ok + _bad) / 2)
	else:
		_finish(_ok)


func _finish(v: int) -> void:
	best = v
	done = true
	_stage = "done"


## 最高通过的强度之上、最近的一个不通过的强度(没有 = -1)
func next_fail() -> int:
	var nf := -1
	for k: int in cache.keys():
		if k > best and not bool(cache[k]["pass"]) and (nf < 0 or k < nf):
			nf = k
	return nf


# ---------------------------------------------------------------- 摆位(和 intensity_bench / campaign_bench 的机器人一样)
## front 前压：近战站离来敌最近的格子、远程站离卡车最近的格子；compact 抱团：都贴着卡车，近战挑朝敌人那一侧；
## guard 护卫：近战坦克守在卡车边，其余近战前压。不占人数的(空白节点)站到离来敌最远的空格；会坠落的(星旅节点)留在仓库
func place(deploy: String) -> void:
	var all: Array = []
	for ru: Dictionary in run.roster.values():
		if ru["cell"] != null:
			run.move_unit(ru["id"], {"bench": run.free_bench_slot()})
		if not run.unit_def(ru).bench_drop:
			all.append(ru)
	var spawn: Array[Vector2] = cat.wave_positions(run.wave_def()["units"], run.current_map())
	var cells: Array[Vector2i] = GC.deploy_cells()
	all.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(_melee(a)) > int(_melee(b)))
	for u: Dictionary in all:
		var free: bool = run.unit_def(u).free_deploy
		var melee: bool = _melee(u)
		var best_c := Vector2i(-1, -1)
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
				sc = p.length() + 0.2 * dmin
			elif melee:
				sc = dmin
			if sc < best_s:
				best_s = sc
				best_c = c
		if best_c.x >= 0:
			run.move_unit(u["id"], {"cell": best_c})


func _melee(u: Dictionary) -> bool:
	var w: EquipmentDef = run.weapon_of(u)
	return run.unit_def(u).style_for_weapon(w != null and w.plays_ranged()) in ["melee", "assassin", "tank"]


func _has_melee_tank() -> bool:
	for u: Dictionary in run.roster.values():
		if _melee(u) and run.unit_def(u).role == "tank":
			return true
	return false
