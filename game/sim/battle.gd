class_name Battle
extends RefCounted
## 一场战斗的模拟(纯逻辑)。固定步长 GC.SIM_DT。视图层每帧调用 step() 若干次，并 poll_events() 取表现事件。
## 棋子只在开局摆放在格子里(anchor)；战斗中位置是连续的 Vector2(x,z)，由 BattleAI 自由移动，绕开地图上的障碍物(BattleMap)。
## 工坊卡车占据地图中央：不可选中、不受伤；我方全灭后存活的敌人会涌入卡车(state = "raid")，对卡车耐久造成伤害(truck_damage)。

var catalog: Catalog
var units: Array[BUnit] = []
var projectiles: Array[Dictionary] = []
var hunt_targets: Dictionary = {}        # 队伍 -> 当前的狩猎对象(狩胜节点；同一队的狩胜节点共用一个)
var thrown: Array[Dictionary] = []       # 飞行中的投掷武器(狩胜节点·必胜){id, src, target, pos, prev, dest, speed, amount, o}
var _throw_id: int = 0
var fields: Array[Dictionary] = []      # 地形(稻田等)：{id, kind, pos, radius, until, heal_bonus, src}
var hazards: Array[Dictionary] = []     # 战场机制(专属战场)的运行状态：{cfg, id, type, phase, next, t0, x, prev_x, hit}
var _field_id: int = 1
var _status_serial: int = 0            # "每次施加相互独立"的状态(乱念的咒语等)的实例编号
var pending: Array[Dictionary] = []
var scheduled: Array[Dictionary] = []    # 到点调用：{at, fn}(虹光飞弹在天上飞完才命中)
var pending_exec: Array[Dictionary] = []   # 延迟结算的能力(天降流星)：{at, ctx}     # 延后出手的普攻(追击副本等另一只手的那一下)：{at, src, dst, is_copy, opts}
var time: float = 0.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var pipeline: Pipeline
var ai: BattleAI
var cfg: Dictionary = {"potion_variance": true}
var mod_defs: Array[Dictionary] = []    # 本场生效的卡车改装(cfg.mods 的 id → Catalog.mods)
var mod_rules: Dictionary = {}          # 改写规则的改装：rule -> params(我方单位的 meta.mod_rules 指向它；Pipeline.mod_rule 读)
var map: BattleMap = BattleMap.empty()
var state: String = "setup"          # setup / countdown / running / raid / ended
var truck_damage: int = 0            # 本场对卡车耐久造成的伤害(失败时)
var drops: Array[Dictionary] = []    # 被击杀的敌人掉落的晶球 [{tier, pos}]
var raid_start: float = -1.0
var winner: int = -1                  # 0 我方 / 1 敌方 / 2 平局(超时)
var events: Array[Dictionary] = []
var weather: String = ""                    # 战场天气(导向节点·变天)：rain = 所有人被施加的燃烧持续时间减半；sunny = 寒气的攻速削减减半；
											# fog = 敌我双方的远程非法器普攻有 weather_params.dodge 的概率被闪避
var weather_params: Dictionary = {}         # 这种天气的参数(变天能力的 cfg.params[天气])
var chapter_color: String = "white"         # 这一场在哪一章(cfg.chapter_color，没给就看地图主题)：变天按它决定天气
var gentle: Array[Dictionary] = []          # 温柔地(共歌节点)：[{until, k, src}]——这段时间里所有单位受到的伤害最终 × (1 - k)(几个同时在场取最大的)
var learning_out: Dictionary = {}          # 战斗结束时我方棋子【永恒】【学习】能力的学习计数：roster_id -> {能力 id: 计数}(Run.finish_battle 写回花名册)
var eternal_out: Dictionary = {}            # 战斗结束时我方棋子身上的永恒状态：roster_id -> [序列化的状态](Run.finish_battle 写回花名册)
var gold_gain: Dictionary = {0: 0, 1: 0}
var xp_gain: Dictionary = {0: 0, 1: 0}
var death_times: Array[float] = []            # 非召唤物的阵亡时刻(少女幻葬：吟唱期间全场阵亡了几个)       # 战斗里获得的经验(万语千言)；Run.finish_battle 加进等级经验
var growth: Dictionary = {}           # roster_id -> {stat: v}   (永恒成长，战后回写)
var trait_reports: Dictionary = {}    # team -> Array[Dictionary]
var report: BattleReport = BattleReport.new()
var stun_time: float = 0.0             # 本场全场累计被【眩晕】的时间(每个被眩晕的单位每秒 +1；锁芯节点·打开深空之门)
var stun_seconds: int = 0              # 已经按整秒发过的 OnStunSecond 次数
var dot_dealt: float = 0.0             # 本场全场造成的持续伤害累计(血嗜节点·血宴：每 y 点 1 层)   # 详细战报(结算界面的伤害 / 承伤 / 治疗 / 护盾明细)
var frame_timer: float = 0.0
var frames: int = 0
var _next_uid: int = 1
var _proj_id: int = 1
var end_time: float = 0.0


func _init(p_catalog: Catalog, seed_value: int = 1) -> void:
	catalog = p_catalog
	rng.seed = seed_value
	pipeline = Pipeline.new(self)
	ai = BattleAI.new(self)


# ---------------------------------------------------------------- 构建
## setup: {"units":[{"def","team","star","cell":Vector2i,"weapon":id("" = 基础武器),"roster_id","perm","orb","boss"}],
##         "map": 障碍物布局(MapGen.generate 的结果，可选), "cfg":{"truck_blocks_ally_los":bool, ...}}
## (兼容旧格式 "equipment":[id...]：取第一个非空 id 作为武器)
func setup(data: Dictionary) -> void:
	for k: String in (data.get("cfg", {}) as Dictionary).keys():
		cfg[k] = (data["cfg"] as Dictionary)[k]
	if data.has("map"):
		map = BattleMap.from_layout(data["map"])
	map.truck_blocks_ally_los = bool(cfg.get("truck_blocks_ally_los", true))
	chapter_color = str(cfg.get("chapter_color", (data.get("map", {}) as Dictionary).get("theme", "white")))
	_load_mods(cfg.get("mods", []))
	hazards.clear()
	for hc: Variant in map.hazards:
		var hd: Dictionary = hc
		hazards.append({"cfg": hd, "id": str(hd.get("id", "")), "type": str(hd.get("type", "")), "phase": "idle",
			"next": float(hd.get("first", 5.0)), "t0": 0.0, "x": float(hd.get("rest_x", 0.0)), "prev_x": float(hd.get("rest_x", 0.0)), "hit": {}})
	for e: Dictionary in data.get("units", []):
		var def: UnitDef = catalog.get_unit(str(e["def"]))
		if def != null and str(e.get("form", "")) != "":
			def = def.form_def(str(e["form"]))          # 形态(变奏节点·表里之间)：这一场按这个形态的部门 / 外观
		if def == null:
			push_error("Battle.setup: unknown unit %s" % str(e["def"]))
			continue
		var cell: Vector2i = e.get("cell", Vector2i(0, 0))
		var pos: Vector2 = e["pos"] if e.has("pos") else GC.cell_to_world(cell.x, cell.y)
		var u: BUnit = spawn_unit(def, int(e.get("team", 0)), int(e.get("star", 1)), pos, false)
		u.roster_id = str(e.get("roster_id", ""))
		u.perm_flat = (e.get("perm", {}) as Dictionary).duplicate()
		var wid: String = str(e.get("weapon", ""))
		if wid == "":
			for x: Variant in e.get("equipment", []):
				if x != null and str(x) != "":
					wid = str(x)
					break
		if wid != "":
			u.set_weapon(catalog.resolve_weapon(def, wid))
		if bool(e.get("unarmed", false)):
			u.set_weapon(null)
		if str(e.get("orb", "")) != "":
			u.meta["orb"] = str(e["orb"])
		if bool(e.get("boss", false)):
			u.meta["boss"] = true
			u.radius *= 1.35
			u.base.max_health *= 1.3
		if bool(e.get("elite", false)):
			u.meta["elite"] = true
		# 备战时被狩猎旗标标记的敌人：记下是哪一队标的(开战时那一队的狩胜节点优先把它当狩猎对象)
		if e.has("hunt_marked_by"):
			u.meta["hunt_marked_by"] = int(e["hunt_marked_by"])
		# 上一场带下来的永恒状态(共歌节点的沉醉)：原样挂回去
		for es: Variant in e.get("eternal", []):
			restore_eternal(u, es as Dictionary)
		# 无我(无我节点)：备战时点过按钮——这一场开战清场(她的触发器条件 source_meta_has selfless)
		if bool(e.get("selfless", false)):
			u.meta["selfless"] = true
		# 上一场带下来的学习计数(【永恒】【学习】：匕首与金币)
		var ln: Dictionary = e.get("learning", {})
		for lk: Variant in ln.keys():
			u.learning[str(lk)] = int(ln[lk])
		# 从仓库坠落(星旅节点·渡星而来)：倒计时里还在天上——不能被选中、不参与碰撞、不行动，开打那一刻落地(_land_drops)
		if bool(e.get("drop", false)):
			u.meta["dropping"] = true
			u.phase = "drop"
		# 遭遇的强度倍率(方格网章节：遭遇池 + 已走的步数)
		if e.has("hp_mult"):
			u.base.max_health *= float(e["hp_mult"])
		if e.has("atk_mult"):
			u.base.attack_power *= float(e["atk_mult"])
			u.base.ability_power *= float(e["atk_mult"])
		u.mark_dirty()
		u.recompute()
		u.hp = u.get_stats().max_health
	_apply_mod_stats()
	for u4: BUnit in units:
		u4.recompute()
		u4.hp = u4.get_stats().max_health
	state = "setup"


# ---------------------------------------------------------------- 卡车改装
## cfg.mods：这一局已选的改装 id。属性 / 配对像羁绊档位一样挂到受益单位上(who：all / ranged / melee / enemy)；
## 改写规则的改装记在 mod_rules，我方单位(含召唤物)的 meta.mod_rules 指向它
func _load_mods(ids: Array) -> void:
	mod_defs.clear()
	mod_rules.clear()
	for id: Variant in ids:
		var d: Dictionary = catalog.mods.get(str(id), {})
		if d.is_empty():
			continue
		mod_defs.append(d)
		if d.has("rule"):
			var params: Dictionary = (d.get("params", {}) as Dictionary).duplicate()
			params["on"] = true                 # 没有参数的规则(珠光力场)也得是非空字典：Pipeline.mod_rule 用 is_empty 判有没有
			mod_rules[str(d["rule"])] = params


func _apply_mod_stats() -> void:
	for d: Dictionary in mod_defs:
		var id: String = str(d["id"])
		var who: String = str(d.get("who", "all"))
		var stats: Dictionary = d.get("stats", {})
		var pairs: Array = d.get("pairs", [])
		if stats.is_empty() and pairs.is_empty():
			continue
		for u: BUnit in units:
			if u.is_summon or not mod_applies(u, who):
				continue
			if stats.has("flat"):
				u.trait_flat["mod:" + id] = (stats["flat"] as Dictionary).duplicate()
			if stats.has("pct"):
				u.trait_pct["mod:" + id] = (stats["pct"] as Dictionary).duplicate()
			for p: Variant in pairs:
				u.runtime_triggers.append(TriggerDef.from_dict((p as Dictionary).get("trigger", {})))
				u.runtime_abilities.append(AbilityDef.from_dict((p as Dictionary).get("ability", {})))
			u.mark_dirty()


## 改装的受益者：ranged = 手里是远程大类武器的我方节点，melee = 其余我方节点，enemy = 敌人，all = 所有我方节点
static func mod_applies(u: BUnit, who: String) -> bool:
	match who:
		"enemy":
			return u.team == GC.TEAM_ENEMY
		"ranged":
			return u.team == GC.TEAM_PLAYER and u.is_ranged()
		"melee":
			return u.team == GC.TEAM_PLAYER and not u.is_ranged()
	return u.team == GC.TEAM_PLAYER


func has_mod(id: String) -> bool:
	for d: Dictionary in mod_defs:
		if str(d["id"]) == id:
			return true
	return false


func spawn_unit(def: UnitDef, team: int, star: int, pos: Vector2, summoned: bool) -> BUnit:
	var u := BUnit.new()
	var prefix: String = "p" if team == GC.TEAM_PLAYER else "e"
	u.setup(def, team, star, "%s%d" % [prefix, _next_uid])
	u.set_weapon(catalog.resolve_weapon(def, ""))     # 先拿基础武器；setup() 里再换成装备的武器
	u.recompute()
	u.hp = u.get_stats().max_health
	_next_uid += 1
	u.is_summon = summoned
	u.pos = pos
	u.prev_pos = pos
	u.anchor = pos
	u.facing = GC.facing_to(pos, Vector2.ZERO) if team != GC.TEAM_PLAYER else PI * 0.5
	u.prev_facing = u.facing
	u.spawn_time = time
	if team == GC.TEAM_PLAYER and not mod_rules.is_empty():
		u.meta["mod_rules"] = mod_rules
	units.append(u)
	if summoned and bool(cfg.get("traits", true)):
		# 召唤物：套用当前队伍已激活的羁绊档位
		var defs: Array = []
		for o: BUnit in units:
			if o.team == team and not o.is_summon:
				defs.append(o.def)
		var rep: Array[Dictionary] = TraitRuntime.compute(catalog, defs)
		for r: Dictionary in rep:
			if int(r["tier"]) > 0 and not def.summon_only and GC.faction_contributions(def.faction_id).has((r["trait"] as TraitDef).member_filter):
				TraitRuntime.apply_tier_to_unit(u, r["trait"], int(r["tier"]))
		u.attack_cd = 0.6
		face_nearest_enemy(u)
	_attach_terrain(u)
	return u


# ---------------------------------------------------------------- 地形效果(燃烧废墟 / 余烬地块 / 战场机制)
## 地图上有地形效果时，每个单位(含之后的召唤物)都挂上地形的"触发器 + 能力"(tag terrain_payload，数据在 terrain.json)：
## 地形只负责发事件，效果和羁绊/装备一样走管线
func _attach_terrain(u: BUnit) -> void:
	if not map.has_terrain():
		return
	for pair: Dictionary in catalog.terrain_pairs:
		u.runtime_triggers.append(pair["trigger"])
		u.runtime_abilities.append(pair["ability"])


## 每个战斗帧：站在燃烧废墟周围的单位收到 OnTerrainTick(burning_ruin)
func _terrain_frame() -> void:
	if state != "running" and state != "raid":
		return
	for u: BUnit in units.duplicate():
		if not u.alive:
			continue
		if map.near_burning(u.pos, u.radius):
			pipeline.emit("OnTerrainTick", u, u, 0.0, ["terrain", "burning_ruin"], {"terrain": "burning_ruin"})
		var fid: int = map.frost_at(u.pos, u.radius)
		if fid >= 0:
			pipeline.emit("OnTerrainTick", u, u, 0.0, ["terrain", "frost"], {"terrain": "frost", "frost": fid})


## 每一步：踩上还在燃烧的余烬地块 → 这块余烬熄灭清空，并发出 OnTerrainEnter(ember)。
## 场上有"余烬守护者"(龙的余烬：flag ember_keeper)时余烬不会熄灭：踩上一块新的余烬才发一次，
## 一直站在同一块上每 EMBER_REBURN 秒再发一次；免疫燃烧的单位(flag burn_immune)不触发
const EMBER_REBURN := 2.5


func _step_embers() -> void:
	if map.embers.is_empty() or (state != "running" and state != "raid"):
		return
	var keep: bool = ember_keeper() != null
	for u: BUnit in units.duplicate():
		if not u.alive:
			continue
		var id: int = map.lit_ember_at(u.pos, u.radius)
		if id < 0:
			u.meta.erase("_ember_on")
			continue
		if keep:
			if u.has_flag("burn_immune"):
				continue
			if int(u.meta.get("_ember_on", -1)) == id and time < float(u.meta.get("_ember_next", 0.0)):
				continue
			u.meta["_ember_on"] = id
			u.meta["_ember_next"] = time + EMBER_REBURN
			fx({"t": "ember_flare", "id": id, "unit": u})
			pipeline.emit("OnTerrainEnter", u, u, 0.0, ["terrain", "ember"], {"terrain": "ember", "ember_id": id})
			continue
		map.put_out_ember(id)
		fx({"t": "ember_out", "id": id, "unit": u})
		pipeline.emit("OnTerrainEnter", u, u, 0.0, ["terrain", "ember"], {"terrain": "ember", "ember_id": id})


## 我方再生的效能倍率：在场(活着)的友方里，带 regen_amp 被动(调香节点·飘香)的取它【叠加 N】的 N(几个调香节点不相乘，取最大)；没有就是 1
func regen_mult(team: int) -> float:
	var m := 1.0
	for u: BUnit in units:
		if not u.alive or u.team != team:
			continue
		for pa: AbilityDef in u.def.passives:
			if bool(pa.effect_config.get("regen_amp", false)) and u.star >= pa.unlock_star:
				m = maxf(m, float(Pipeline.kw_value(u, pa, "stacking", 1)))
	return m


## 场上活着的余烬守护者(龙的余烬)；没有返回 null
func ember_keeper() -> BUnit:
	for u: BUnit in units:
		if u.alive and u.has_flag("ember_keeper"):
			return u
	return null


## 有没有活着的、不在 team 这一边的"燃烧移除生命上限"的单位(龙的余烬：flag burn_wither)
func wither_against(team: int) -> bool:
	for u: BUnit in units:
		if u.alive and u.team != team and u.has_flag("burn_wither"):
			return true
	return false


## 在格子 c 上烧起一块 1×1 的余烬(格子上已经有熄灭的余烬就把它重新点燃)；返回余烬 id，烧不了返回 -1
func ignite_cell(c: Vector2i, src: BUnit = null) -> int:
	if not map.ember_cell_ok(c):
		return -1
	var ex: int = map.ember_at_cell(c)
	if ex >= 0:
		if bool(map.embers[ex]["lit"]):
			return -1
		map.relight_ember(ex)
		fx({"t": "ember_lit", "id": ex, "src": src})
		return ex
	var id: int = map.add_ember(Rect2i(c, Vector2i.ONE), "ember_spread")
	fx({"t": "ember_add", "id": id, "x": c.x, "y": c.y, "w": 1, "h": 1, "style": "ember_spread", "src": src})
	return id


# ---------------------------------------------------------------- 战场机制(事件战斗的专属战场)
## 时刻表按"开打以后过了几秒"走(time - START_DELAY)。机制只负责：什么时候、打到谁——发 OnTerrainHit 给被打到的单位，
## 伤害 / 燃烧由它身上的地形触发器走管线(terrain.json)；另外发表现事件 hazard(warn / go / end) 和 hazard_hit。
func _step_hazards() -> void:
	if hazards.is_empty() or (state != "running" and state != "raid"):
		return
	var rt: float = time - GC.START_DELAY
	for hz: Dictionary in hazards:
		hz["prev_x"] = hz["x"]
		match str(hz["type"]):
			"sweep":
				_step_sweep(hz, rt)
			"eruption":
				_step_eruption(hz, rt)


## 电车：平时停在 rest_x(地图外)，到点从静止加速冲过整条轨道(z ± half_width)，车身扫到的单位每班只撞一次
func _step_sweep(hz: Dictionary, rt: float) -> void:
	var hc: Dictionary = hz["cfg"]
	var nxt: float = float(hz["next"])
	match str(hz["phase"]):
		"idle":
			if rt >= nxt - float(hc.get("warn", 3.0)):
				hz["phase"] = "warn"
				fx({"t": "hazard", "id": hz["id"], "ev": "warn", "lead": nxt - rt})
		"warn":
			if rt >= nxt:
				hz["phase"] = "run"
				hz["t0"] = rt
				hz["hit"] = {}
				fx({"t": "hazard", "id": hz["id"], "ev": "go"})
		"run":
			var s: float = rt - float(hz["t0"])
			var acc: float = maxf(0.1, float(hc.get("accel", 7.0)))
			var v: float = float(hc.get("speed", 11.0))
			var ta: float = v / acc
			var dist: float = 0.5 * acc * s * s if s < ta else 0.5 * v * ta + v * (s - ta)
			var x: float = float(hc.get("rest_x", 0.0)) + dist
			hz["x"] = x
			var half_l: float = float(hc.get("length", 10.0)) * 0.5
			var z: float = float(hc.get("z", 0.0))
			var hw: float = float(hc.get("half_width", 1.0))
			for u: BUnit in units.duplicate():
				if not u.alive or (hz["hit"] as Dictionary).has(u.uid):
					continue
				if absf(u.pos.y - z) > hw + u.radius * 0.5 or u.pos.x < x - half_l - u.radius or u.pos.x > x + half_l + 0.3:
					continue
				(hz["hit"] as Dictionary)[u.uid] = true
				_sweep_hit(u, hz)
			if x - half_l > GC.map_half().x + 1.0:
				hz["phase"] = "idle"
				hz["next"] = nxt + float(hc.get("period", 13.0))
				hz["x"] = float(hc.get("rest_x", 0.0))
				hz["prev_x"] = hz["x"]
				fx({"t": "hazard", "id": hz["id"], "ev": "end"})


## 被电车撞到：发 OnTerrainHit(伤害 + 燃烧走管线)，然后被撞开——往前带一截、甩到轨道离得近的那一侧(和冲锋一样是一段位移)
func _sweep_hit(u: BUnit, hz: Dictionary) -> void:
	var hc: Dictionary = hz["cfg"]
	var tag: String = str(hc.get("tag", hz["id"]))
	fx({"t": "hazard_hit", "id": hz["id"], "unit": u})
	pipeline.emit("OnTerrainHit", u, u, 0.0, ["terrain", tag], {"terrain": tag})
	if not u.alive:
		return
	var z: float = float(hc.get("z", 0.0))
	var side: float = 1.0 if u.pos.y >= z else -1.0
	var want := Vector2(u.pos.x + 1.2, z + side * (float(hc.get("half_width", 1.0)) + u.radius + 0.3))
	var dest: Vector2 = find_free_position(want, u.radius, u)
	interrupt(u)
	u.phase = "dash"
	u.vel = Vector2.ZERO
	u.meta["dash"] = {"from": u.pos, "to": dest, "t0": time, "dur": 0.3, "quiet": true}


## 喷泉：蓄力 warn 秒 → 喷发(火弧飞 flight 秒) → 落在各个落火点上：重新点燃那块余烬地块，砸到的单位收到 OnTerrainHit
func _step_eruption(hz: Dictionary, rt: float) -> void:
	var hc: Dictionary = hz["cfg"]
	var nxt: float = float(hz["next"])
	match str(hz["phase"]):
		"idle":
			if rt >= nxt - float(hc.get("warn", 2.0)):
				hz["phase"] = "warn"
				fx({"t": "hazard", "id": hz["id"], "ev": "warn", "lead": nxt - rt})
		"warn":
			if rt >= nxt:
				hz["phase"] = "run"
				fx({"t": "hazard", "id": hz["id"], "ev": "go", "flight": float(hc.get("flight", 1.2)), "embers": hc.get("embers", [])})
		"run":
			if rt >= nxt + float(hc.get("flight", 1.2)):
				var tag: String = str(hc.get("tag", hz["id"]))
				for eid: Variant in hc.get("embers", []):
					var id: int = int(eid)
					map.relight_ember(id)
					fx({"t": "ember_lit", "id": id})
					for u: BUnit in units.duplicate():
						if u.alive and map.touches_ember(id, u.pos, u.radius):
							fx({"t": "hazard_hit", "id": hz["id"], "unit": u})
							pipeline.emit("OnTerrainHit", u, u, 0.0, ["terrain", tag], {"terrain": tag, "ember_id": id})
				hz["phase"] = "idle"
				hz["next"] = nxt + float(hc.get("period", 9.0))
				fx({"t": "hazard", "id": hz["id"], "ev": "end"})


## 界面用：每个战场机制离下一次发动还有几秒(正在发动 = 0)
func hazard_info() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rt: float = maxf(0.0, time - GC.START_DELAY)
	for hz: Dictionary in hazards:
		out.append({"id": hz["id"], "type": hz["type"], "phase": hz["phase"],
			"eta": 0.0 if str(hz["phase"]) == "run" else maxf(0.0, float(hz["next"]) - rt)})
	return out


# ---------------------------------------------------------------- 流程
func start() -> void:
	if state != "setup":
		return
	for team: int in [GC.TEAM_PLAYER, GC.TEAM_ENEMY]:
		# cfg.traits = false：不计羁绊(平衡基准用)；cfg.trait_teams = [0]：只给这几队算羁绊(羁绊基准：看某个颜色的阵容吃到羁绊后强多少)
		var tt: Array = cfg.get("trait_teams", [GC.TEAM_PLAYER, GC.TEAM_ENEMY])
		if bool(cfg.get("traits", true)) and tt.has(team):
			trait_reports[team] = TraitRuntime.apply_to_team(self, team)
	for u: BUnit in units:
		u.recompute()
		u.hp = u.get_stats().max_health
		u.attack_cd = 0.25 + rng.randf() * 0.25
		face_nearest_enemy(u)
		# 开局已经攒好的计数(触发器 extra.count_init；锁芯节点·万物闭锁)
		for tg: TriggerDef in u.all_triggers():
			if tg.extra.has("count_init"):
				u.counters[tg.id] = int(tg.extra["count_init"])
	state = "countdown"
	fx({"t": "battle_countdown"})
	for du: BUnit in units:
		if bool(du.meta.get("dropping", false)):
			fx({"t": "starfall_start", "unit": du, "to": du.pos, "dur": GC.START_DELAY})
	for u2: BUnit in units.duplicate():
		pipeline.emit("OnBattleStart", u2, null, 0.0, ["battle_start"], {})


func step() -> void:
	if state == "ended" or state == "setup":
		return
	var dt: float = GC.SIM_DT
	time += dt
	pipeline.processed_in_step = 0
	for u: BUnit in units:
		u.prev_pos = u.pos
		u.prev_facing = u.facing
	if state == "countdown" and time >= GC.START_DELAY:
		state = "running"
		fx({"t": "battle_go"})
		_land_drops()
	_update_statuses(dt)
	_step_stun_time(dt)
	_step_throws(dt)
	_step_dashes()
	frame_timer += dt
	while frame_timer >= GC.FRAME_SECONDS:
		frame_timer -= GC.FRAME_SECONDS
		frames += 1
		for u2: BUnit in units.duplicate():
			if u2.alive:
				var st: StatBlock = u2.get_stats()
				if st.health_regen_per_second > 0.0:
					pipeline.fx.heal(u2, u2, st.health_regen_per_second * GC.FRAME_SECONDS, {"surface": "lifesteal", "raw": true})
				if not u2.is_stunned():                       # 【眩晕】："每 x 秒"的触发器暂停计时
					pipeline.emit("OnBattleFrame", u2, null, float(frames), ["battle_frame"], {})
		_terrain_frame()
	if state == "running":
		for u3: BUnit in units.duplicate():
			if u3.alive:
				ai.step(u3, dt)
		_step_binds(dt)
		_step_approach()
		_step_near()
	elif state == "raid":
		_step_raid(dt)
	_step_light_beams(dt)
	_step_gentle()
	_step_fields()
	_step_hazards()
	_step_embers()
	_step_pending()
	_step_projectiles(dt)
	_step_knocks()
	resolve_collisions()
	_check_end()


## 场上被【眩晕】的总时间：每个身上有【眩晕】的活着的单位每秒 +1；每满 1 秒发一次 OnStunSecond 给有这个时机触发器的单位
func _step_stun_time(dt: float) -> void:
	if state != "running":
		return
	var n := 0
	for u: BUnit in units:
		if u.alive and u.statuses.has("stun"):
			n += 1
	if n == 0:
		return
	stun_time += dt * float(n)
	while stun_time + 0.0001 >= float(stun_seconds + 1):
		stun_seconds += 1
		for u2: BUnit in units.duplicate():
			if not u2.alive:
				continue
			for tg: TriggerDef in u2.all_triggers():
				if tg.timing == "OnStunSecond":
					pipeline.emit("OnStunSecond", u2, null, float(stun_seconds), ["stun_second"], {})
					break


## 血色仪式(锁芯节点)：这一队施加的【眩晕】持续时间加成 = 活着的队友身上【血色仪式】的 stun_amp 之和
func stun_amp(team: int) -> float:
	var k := 0.0
	for u: BUnit in units:
		if u.alive and u.team == team and u.statuses.has("blood_rite"):
			k += float((u.statuses["blood_rite"] as BStatus).meta.get("stun_amp", 0.0))
	return k


func run_to_end(max_seconds: float = GC.BATTLE_MAX_SECONDS + 5.0) -> void:
	if state == "setup":
		start()
	var guard: int = int(max_seconds / GC.SIM_DT) + 10
	while state != "ended" and guard > 0:
		step()
		guard -= 1
		events.clear()      # 无头运行不需要表现事件


func poll_events() -> Array[Dictionary]:
	var e: Array[Dictionary] = events
	events = []
	return e


func fx(e: Dictionary) -> void:
	e["time"] = time
	events.append(e)
	report.consume(e, time)


# ---------------------------------------------------------------- 触手(色欲的余烬)
const BIND_PULL := 1.6        # 缠在一起的两个单位，还有一方打不到对方时，每秒互相拉近多少米(各拉一半)
const BIND_IDS: Array[String] = ["lust_bind", "toad_bind"]     # 互相缠住的状态(色欲的侵蚀 / 守林节点·巨蟾蜍的长舌)

## 色欲的侵蚀把两边都定在原地；被别人挤开以后两边就再也够不着、永远僵住——所以只要还有一方普攻打不到对方，就把两边往一起拉
## (打得到了就不拉；空手的那一方不算)
func _step_binds(dt: float) -> void:
	for u: BUnit in units:
		if not u.alive:
			continue
		for st: BStatus in _binds_of(u):
			for pid: Variant in st.meta.get("partners", []):
				var p: BUnit = get_unit_by_uid(str(pid))
				if p == null or not p.alive or p.uid < u.uid:
					continue                      # 每一对只处理一次
				var d: float = u.pos.distance_to(p.pos)
				var u_ok: bool = not u.can_attack() or BattleAI.in_reach(u, p, d, u.get_stats().range_meters())
				var p_ok: bool = not p.can_attack() or BattleAI.in_reach(p, u, d, p.get_stats().range_meters())
				if (u_ok and p_ok) or d < 0.001:
					continue
				var dir: Vector2 = (p.pos - u.pos) / d
				var step_len: float = minf(BIND_PULL * dt, maxf(0.0, d - BattleAI.touch_reach(u, p) + 0.08)) * 0.5
				if not _planted_by_dash(u):
					u.pos = map.push_out(u.pos + dir * step_len, u.radius)
				if not _planted_by_dash(p):
					p.pos = map.push_out(p.pos - dir * step_len, p.radius)


func _planted_by_dash(u: BUnit) -> bool:
	return u.phase == "dash" or u.phase == "throw" or u.phase == "drop"


# ---------------------------------------------------------------- 从仓库坠落(星旅节点)
## 开打那一刻落地：落点有人就挪到旁边最近的空地，然后发 OnStarfall(渡星而来：按落点范围里的敌人数给护盾、对它们造成一半的伤害)
func _land_drops() -> void:
	for u: BUnit in units:
		if not u.alive or not bool(u.meta.get("dropping", false)):
			continue
		u.meta.erase("dropping")
		u.phase = "idle"
		var at: Vector2 = u.pos
		u.pos = find_free_position(at, u.radius, u)
		u.prev_pos = u.pos
		face_nearest_enemy(u)
		fx({"t": "starfall_land", "unit": u, "at": at})
		pipeline.emit("OnStarfall", u, null, 0.0, ["starfall"], {"at": at})


# ---------------------------------------------------------------- 状态刷新
func _update_statuses(dt: float) -> void:
	var wither: Dictionary = {}                     # 队伍 -> 这一队的燃烧是不是改成移除生命上限(龙的余烬在场)
	for u: BUnit in units.duplicate():
		if not u.alive or u.statuses.is_empty():
			continue
		var changed := false
		for sid: String in u.statuses.keys():
			if not u.statuses.has(sid):
				continue
			var s: BStatus = u.statuses[sid]
			# 持续伤害：到期那一刻的最后一跳也算(持续 N 秒、每秒一跳 = 正好 N 跳)
			if not s.dot.is_empty() and time + 0.0001 >= float(s.dot.get("next_at", 1e9)) and (s.expires_at < 0.0 or float(s.dot["next_at"]) <= s.expires_at + 0.0001):
				s.dot["next_at"] = float(s.dot["next_at"]) + float(s.dot.get("interval", 1.0))
				var src0: BUnit = get_unit_by_uid(s.source_id)
				var per0: float = float(s.dot.get("amount", 0.0)) + u.get_stats().max_health * float(s.dot.get("pct_max_health", 0.0))
				if not wither.has(u.team):
					wither[u.team] = wither_against(u.team)
				if bool(wither[u.team]) and s.has_flag("burning"):
					# 龙的余烬在场：燃烧不造成法术伤害，改为直接移除这么多生命上限(连同这部分生命)
					pipeline.fx.wither(src0, u, per0 * s.stacks, {"surface": "status", "ability_id": sid, "status_base": str(s.meta.get("base_id", sid))})
				else:
					var dealt0: float = pipeline.fx.damage(src0, u, per0 * s.stacks, str(s.dot.get("kind", "magic")), {"surface": "status", "ability_id": sid,
						"status_base": str(s.meta.get("base_id", sid))})
					# 失血(血嗜节点)：施加者回复这一跳的最终伤害量
					if bool(s.meta.get("drain", false)) and src0 != null and src0.alive and dealt0 > 0.0:
						pipeline.fx.heal(src0, src0, dealt0, {"surface": "drain", "raw": true, "ability_id": "bleed"})
				if not u.alive:
					break
			# 脉冲(外神之貌 → 真实形态)：每 pulse_interval 秒发一次 OnStatusPulse 给持有者
			if s.meta.has("pulse_next") and time + 0.0001 >= float(s.meta["pulse_next"]) and (s.expires_at < 0.0 or time < s.expires_at - 0.0001):
				s.meta["pulse_next"] = float(s.meta["pulse_next"]) + maxf(0.05, float(s.meta.get("pulse_interval", 0.5)))
				var bsid: String = str(s.meta.get("base_id", sid))
				fx({"t": "status_pulse", "unit": u, "id": bsid})
				pipeline.emit("OnStatusPulse", u, null, 0.0, ["status_pulse", bsid], {"status_id": bsid})
				if not u.alive:
					break
			var ended: bool = s.expires_at >= 0.0 and time >= s.expires_at
			# 结束条件：护盾超过某值(且已过最短持续时间)，例如"缩头"持续到护盾超过 100
			if not ended and s.meta.has("end_when_shield_above") and time >= float(s.meta.get("min_until", 0.0)) \
					and u.shield > float(s.meta["end_when_shield_above"]):
				ended = true
			if ended:
				if bool(s.meta.get("burst", false)):
					pipeline.fx.burst_status(u, s)          # 剑痕到期：引爆
					changed = true
					if not u.alive:
						break
					continue
				if bool(s.meta.get("doom", false)):
					# 到期必定死亡(外神之貌的锁血结束)：不再走任何"免死"
					u.statuses.erase(sid)
					u.mark_dirty()
					fx({"t": "status", "unit": u, "id": sid, "base_id": str(s.meta.get("base_id", sid)), "stacks": 0, "created": false, "flags": []})
					u.meta["_doomed"] = true
					u.hp = 0.0
					pipeline.fx.try_kill(u, get_unit_by_uid(s.source_id) if s.source_id != u.uid else null)
					break
				u.statuses.erase(sid)
				changed = true
				fx({"t": "status", "unit": u, "id": sid, "base_id": str(s.meta.get("base_id", sid)), "stacks": 0, "created": false, "flags": []})
				continue
			# 每层持续回血：每层单独一次回复(每次回复都能吃到稻田之类的"每次回复 +X")
			if not s.hot.is_empty() and time >= float(s.hot.get("next_at", 1e9)):
				var iv: float = float(s.hot.get("interval", 0.5))
				s.hot["next_at"] = float(s.hot["next_at"]) + iv
				var per: float = (u.get_stats().max_health * float(s.hot.get("pct", 0.0)) + float(s.hot.get("flat", 0.0))) * iv
				if s.has_flag("regen"):
					per *= regen_mult(u.team)              # 飘香：再生的效能 × 叠加数
				# 【再生】算施加者的治疗(吃施加者的治疗加成，记进她的治疗量：焚花)；其它持续回血按持有者自己的原始量
				var hsrc: BUnit = u
				var hraw := true
				if s.has_flag("regen") or bool(s.hot.get("src_heal", false)):
					var ap0: BUnit = get_unit_by_uid(s.source_id)
					if ap0 != null and ap0.alive:
						hsrc = ap0
						hraw = false
				for k in range(s.stacks):
					pipeline.fx.heal(hsrc, u, per, {"surface": "regen", "raw": hraw, "ability_id": str(s.meta.get("base_id", sid))})

		if changed:
			u.mark_dirty()
		if u.forced_target != null and (time >= u.forced_until or not u.forced_target.alive):
			u.forced_target = null


# ---------------------------------------------------------------- 普攻的出手(近战当场结算 / 远程发射投射物)
## 所有普攻(包括追击副本)都走这里，保证副本和正常普攻的表现、命中事件完全一样。opts 见 Pipeline.normal_attack
func deliver_normal_attack(u: BUnit, t: BUnit, is_copy: bool = false, opts: Dictionary = {}) -> void:
	if not u.alive or not u.can_attack():
		return
	# 引雷(导向节点)：普攻改为连锁闪电——当场打中目标，再在敌人之间弹跳(武器自己的倍率 / 关键词照旧；不走弹道)
	if t != null and t.team != u.team and not opts.has("chain_hop"):
		var ch: Dictionary = u.chain_cfg()
		if not ch.is_empty():
			chain_lightning(u, t, is_copy, opts, ch)
			return
	var wc: Dictionary = u.wclass()
	var proj: String = str(wc.get("projectile", ""))
	if proj != "" and u.weapon != null and u.weapon.projectile != "":
		proj = u.weapon.projectile               # 武器自己的投射物外观(爱心针剂的针剂飞镖)；速度仍按武器大类
	if proj != "" and u.def.projectile != "":
		proj = u.def.projectile                  # 单位自己的投射物外观(余烬的火弹)；速度仍按武器大类
	# 天降流星施法者(灾星节点)：普攻是从天上落下的火流星，不走直线弹道(不受掩体阻挡)，fall 秒后落地结算
	if u.def.sky_caster and not bool(opts.get("landed", false)) and t != null:
		var fall: float = 0.45
		var o2: Dictionary = opts.duplicate()
		o2["landed"] = true
		pending.append({"at": time + fall, "src": u, "dst": t, "is_copy": is_copy, "opts": o2, "own": true, "meteor": true})
		var extra: Array = []
		if str(opts.get("attack_variant", "")) == "multi":
			extra = Targeting.multi_extra(self, u, t).slice(0, maxi(0, Pipeline.kw_value(u, u.na_payload(), "multi_attack", 1) - 1))
		fx({"t": "meteor_na", "unit": u, "target": t, "extra": extra, "fall": fall})
		return
	if u.def.sky_caster and bool(opts.get("landed", false)):
		pipeline.normal_attack(u, t, is_copy, opts)       # 流星落地：当场结算(不再走武器自己的弹道)
		return
	# 近战武器加了射程(舞扇)：目标在 min_dist 米外时改发投射物
	var rp: Dictionary = u.weapon.ranged_projectile if u.weapon != null else {}
	if proj == "" and not rp.is_empty() and t != null and u.pos.distance_to(t.pos) > float(rp.get("min_dist", 1.9)):
		spawn_projectile(u, t, str(rp.get("kind", "ring")), float(rp.get("speed", 10.0)), false, is_copy, opts)
	elif proj != "":
		# 治疗弹：普攻本身是治疗，或者打向队友、会被广义治疗转成治疗
		var heal: bool = (u.def.normal_attack != null and u.def.normal_attack.effect_type == "heal") or 			(t != null and t.team == u.team and (u.get_stats().na_ally_heal_pct > 0.0 or Pipeline.status_meta(u, "angel_alt") != null))
		spawn_projectile(u, t, proj, float(wc["proj_speed"]), heal, is_copy, opts)
	else:
		pipeline.normal_attack(u, t, is_copy, opts)


func next_status_serial() -> int:
	_status_serial += 1
	return _status_serial


# ---------------------------------------------------------------- 地形
func add_field(f: Dictionary) -> void:
	f["id"] = _field_id
	_field_id += 1
	fields.append(f)
	fx({"t": "field_start", "field": f})


func _step_fields() -> void:
	if fields.is_empty():
		return
	var keep: Array[Dictionary] = []
	for f: Dictionary in fields:
		if time >= float(f["until"]):
			fx({"t": "field_end", "field": f})
		else:
			keep.append(f)
	fields = keep
	# 增幅力场(蓝之章)：站在里面的单位(不分敌我)每帧刷新一个短状态——被动技能的增幅 +amp；几块重叠时最后一块说了算
	for f2: Dictionary in fields:
		if str(f2["kind"]) != "amp":
			continue
		var amp: float = float(f2.get("amp", 0.0))
		for u: BUnit in units:
			if u.alive and u.pos.distance_to(f2["pos"]) <= float(f2["radius"]) + u.radius * 0.5:
				pipeline.fx.apply_status(u, u, {"status_id": "amp_field", "duration": 0.35, "max_stacks": 1, "flags": ["buff", "no_dispel"],
					"stat_id": "passive_amplify_bonus", "flat": amp, "sourceless": true})


## 站在稻田上的单位每次回复的额外固定值(几块稻田重叠时取最大的一块，不叠加)
func field_heal_bonus(u: BUnit) -> float:
	var best := 0.0
	for f: Dictionary in fields:
		if str(f["kind"]) == "paddy" and u.pos.distance_to(f["pos"]) <= float(f["radius"]) + u.radius * 0.5:
			best = maxf(best, float(f["heal_bonus"]))
	return best


## 追击副本(另一只手的那一下)：对齐原普攻的出手时刻 + 武器大类的 copy_delay 再出手，继承原普攻的拉弓倍率与落点
## own = 普攻载荷自己的 [追击](双枪/双匕的另一只手)，表现上就是正常的第二下
## idx = 这次追击里的第几下(0 起)：副本按 copy_delay 依次出手(追击 4 = 四下连斩)；copy_delay_scales = 副本间隔跟着攻速缩短(和攻击动画对上)
## 到点调用 fn(逻辑时间 at；虹光飞弹在天上绕完才命中)
func schedule(at: float, fn: Callable) -> void:
	scheduled.append({"at": at, "fn": fn})


func deliver_copy(u: BUnit, t: BUnit, src_meta: Dictionary, own: bool = false, idx: int = 0) -> void:
	var opts := {}
	for k: String in ["chant_scale", "attack_variant", "dmg_cap"]:
		if src_meta.has(k):
			opts[k] = src_meta[k]
	if t == null and src_meta.get("aim_point") is Vector2:
		opts["aim_point"] = src_meta["aim_point"]
	var wcc: Dictionary = u.wclass()
	var delay: float = float(wcc.get("copy_delay", 0.0))
	if bool(wcc.get("copy_delay_scales", false)):
		delay *= minf(1.0, u.get_stats().attack_interval() / maxf(0.05, float(wcc.get("interval", 1.0))))
	var at: float = maxf(time, float(src_meta.get("released_at", time)) + delay * float(idx + 1))
	opts["released_at"] = at
	pending.append({"at": at, "src": u, "dst": t, "is_copy": true, "opts": opts, "own": own})
	if not pipeline.draining:
		_step_pending()


func _step_pending() -> void:
	if not scheduled.is_empty():
		var due0: Array[Dictionary] = []
		var keep0: Array[Dictionary] = []
		for sc: Dictionary in scheduled:
			if float(sc["at"]) <= time + 0.0001:
				due0.append(sc)
			else:
				keep0.append(sc)
		scheduled = keep0
		for sc2: Dictionary in due0:
			(sc2["fn"] as Callable).call()
	# 延迟结算的能力(天降流星落地)：施法者倒下了流星照样落地
	if not pending_exec.is_empty():
		var due: Array[Dictionary] = []
		var keep: Array[Dictionary] = []
		for pe: Dictionary in pending_exec:
			if float(pe["at"]) <= time + 0.0001:
				due.append(pe)
			else:
				keep.append(pe)
		pending_exec = keep
		for pe2: Dictionary in due:
			pipeline.execute(pe2["ctx"])
	if pending.is_empty():
		return
	var now: Array[Dictionary] = []
	var later: Array[Dictionary] = []
	for e: Dictionary in pending:
		if float(e["at"]) <= time + 0.0001:
			now.append(e)
		else:
			later.append(e)
	pending = later
	for e2: Dictionary in now:
		var u: BUnit = e2["src"]
		var t: BUnit = e2["dst"]
		if not u.alive or (t != null and not t.alive):
			continue
		if not bool(e2.get("meteor", false)):
			fx({"t": "attack_copy", "unit": u, "target": t, "weapon_class": u.weapon_class(), "aim": (e2["opts"] as Dictionary).get("aim_point"),
				"own": bool(e2.get("own", false))})
		deliver_normal_attack(u, t, bool(e2["is_copy"]), e2["opts"])


## 不跑 AI，只推进延后出手与投射物(测试用：让追击副本、飞行中的投射物落地)
func advance_pending(seconds: float) -> void:
	var n: int = int(ceil(seconds / GC.SIM_DT))
	for i in range(n):
		time += GC.SIM_DT
		_step_pending()
		_step_projectiles(GC.SIM_DT)


# ---------------------------------------------------------------- 投射物
## to = 目标(追着它飞)；to = null 时飞向 opts.aim_point(打地板)。落地时按普攻结算(opts 原样带过去)
func spawn_projectile(from: BUnit, to: BUnit, kind: String, speed: float, heal: bool = false, is_copy: bool = false, opts: Dictionary = {}) -> void:
	var muzzle: Vector2 = from.pos + Vector2(sin(from.facing), cos(from.facing)) * 0.5
	var dest: Vector2 = to.pos if to != null else (opts.get("aim_point", from.pos) as Vector2)
	var p := {"id": _proj_id, "kind": kind, "from": from, "target": to, "dest": dest, "pos": muzzle, "prev": muzzle, "speed": speed,
		"heal": heal, "born": time, "travel": 0.0, "start": muzzle, "total": maxf(0.3, muzzle.distance_to(dest)),
		"is_copy": is_copy, "opts": opts}
	_proj_id += 1
	# 完美时计(清扫节点)：打向敌人的投射物先停在半空中
	var ts: Variant = Pipeline.status_meta(from, "time_stop_pct") if to != null and to.team != from.team and not heal else null
	if ts != null:
		_hold_projectile(p, from, to, float(ts))
	projectiles.append(p)
	fx({"t": "projectile", "proj": p})
	if ts != null and not is_copy:
		_send_held_copies(p, from, to)


func _step_projectiles(dt: float) -> void:
	var keep: Array[Dictionary] = []
	for p: Dictionary in projectiles:
		var target: BUnit = p["target"]
		var from: BUnit = p["from"]
		p["prev"] = p["pos"]
		var ground: bool = target == null
		if not ground and not target.alive:
			p["done"] = true
			fx({"t": "projectile_end", "proj": p, "hit": false})
			continue
		if p.has("hold") and _step_held(p, dt):
			keep.append(p)
			continue
		if bool(p.get("done", false)):
			continue
		var dest: Vector2 = p["dest"] if ground else target.pos
		p["dest"] = dest
		var to_vec: Vector2 = dest - (p["pos"] as Vector2)
		var step_len: float = float(p["speed"]) * dt
		var reach: float = 0.05 if ground else target.radius * 0.8
		if to_vec.length() <= step_len + reach:
			p["pos"] = dest
			p["done"] = true
			fx({"t": "projectile_end", "proj": p, "hit": true})
			if from.alive:
				var o: Dictionary = (p.get("opts", {}) as Dictionary).duplicate()
				if ground:
					o["aim_point"] = dest
				pipeline.normal_attack(from, target, bool(p.get("is_copy", false)), o)
			continue
		var np: Vector2 = (p["pos"] as Vector2) + to_vec.normalized() * step_len
		if not p.has("hold") and _proj_blocked(p["pos"], np, from.team):           # 完美时计放出去的飞刀不会被挡
			# 撞上高的断壁残垣(或卡车)：弹道被挡住
			p["pos"] = np
			p["done"] = true
			fx({"t": "projectile_end", "proj": p, "hit": false, "blocked": true})
			continue
		p["pos"] = np
		keep.append(p)
	projectiles = keep
	_release_held()


# ---------------------------------------------------------------- 完美时计(停在半空的飞刀)
## 飞刀先飞到半空中的一个停顿点停住(在自己和目标之间错开：远近 40~88% / 左右 / 高低 0.5~1.35 米各不相同；h 是给表现层的高度)，停顿期间每秒 +pct 伤害；
## 瞄着同一个目标的所有停着的飞刀加起来够打死它时(_release_held)一起继续飞——追踪目标、不会被掩体挡。
## 发射者倒下 → 停着的飞刀掉在地上；目标倒下 → 瞄着它的飞刀消失(_step_projectiles 的通用规则)
func _hold_projectile(p: Dictionary, from: BUnit, to: BUnit, pct: float) -> void:
	var dir: Vector2 = to.pos - from.pos
	var dist: float = dir.length()
	dir = dir / dist if dist > 0.001 else Vector2(sin(from.facing), cos(from.facing))
	var perp := Vector2(-dir.y, dir.x)
	var muzzle: Vector2 = from.pos + dir * 0.4 + perp * rng.randf_range(-0.22, 0.22)      # 出手的位置也错开一点
	var span: float = maxf(0.0, muzzle.distance_to(to.pos) - to.radius - 0.35)           # 停顿点离目标至少留出一点距离
	var pt: Vector2 = muzzle + dir * span * rng.randf_range(0.4, 0.88) + perp * rng.randf_range(-1.0, 1.0) * minf(0.9, 0.2 + span * 0.25)
	pt = clamp_to_arena(pt, 0.1)
	if map.blocks_los(GC.world_to_cell(pt), from.team) or not map.has_los(muzzle, pt, from.team):
		pt = muzzle + dir * span * 0.5                                                   # 旁边是高墙：就停在直线上
	p["pos"] = muzzle
	p["prev"] = muzzle
	p["start"] = muzzle
	p["hold"] = {"point": pt, "h": rng.randf_range(0.5, 1.35), "phase": "out", "t_hover": -1.0, "pct": pct, "released": -1.0}


## 普攻载荷自己的[追击](另一只手)：平时是这一发命中时才出手；停在半空的飞刀要等很久才命中，所以另一只手在扔出去时就跟着扔
func _send_held_copies(p: Dictionary, from: BUnit, to: BUnit) -> void:
	var na: AbilityDef = from.na_payload()
	if na == null or not na.has_keyword("pursuit") or not na.has_keyword("normal_attack"):
		return
	var opts: Dictionary = (p["opts"] as Dictionary).duplicate()
	opts["copies_sent"] = true
	p["opts"] = opts
	var cm := {"released_at": time}
	for k: String in ["chant_scale", "attack_variant"]:
		if opts.has(k):
			cm[k] = opts[k]
	for i in range(maxi(1, Pipeline.kw_value(from, na, "pursuit", 1))):
		deliver_copy(from, to, cm, true, i)


## 停在半空的飞刀这一步怎么动：返回 true = 还停着 / 还在往停顿点飞(这一步处理完了)；false = 已经放出去了(照普通投射物追目标)或掉了
func _step_held(p: Dictionary, dt: float) -> bool:
	var hd: Dictionary = p["hold"]
	if not (p["from"] as BUnit).alive:
		p["done"] = true
		fx({"t": "projectile_end", "proj": p, "hit": false, "dropped": true})
		return false
	match str(hd["phase"]):
		"out":
			var to_pt: Vector2 = (hd["point"] as Vector2) - (p["pos"] as Vector2)
			var stp: float = float(p["speed"]) * dt
			if to_pt.length() <= stp:
				p["pos"] = hd["point"]
				hd["phase"] = "hover"
				hd["t_hover"] = time
			else:
				p["pos"] = (p["pos"] as Vector2) + to_pt.normalized() * stp
			return true
		"hover":
			return true
	return false


## 这一发停顿攒下的增伤：停顿的秒数 × pct(进增伤乘区，和其它增伤加在一起)
func held_amp(p: Dictionary) -> float:
	var hd: Dictionary = p["hold"]
	var t_end: float = float(hd["released"]) if float(hd["released"]) >= 0.0 else time
	var secs: float = maxf(0.0, t_end - float(hd["t_hover"])) if float(hd["t_hover"]) >= 0.0 else 0.0
	return float(hd["pct"]) * secs


## 表现用：1 + 停顿的增伤(越停越红)
func held_scale(p: Dictionary) -> float:
	return 1.0 + held_amp(p)


## 瞄着同一个目标的停着的飞刀：预计伤害(Pipeline.estimate_na，按现在的倍率)加起来够打掉它的生命 + 护盾 → 一起放出去
func _release_held() -> void:
	var groups: Dictionary = {}
	for p: Dictionary in projectiles:
		if p.has("hold") and str(p["hold"]["phase"]) != "in":
			var t: BUnit = p["target"]
			if not groups.has(t):
				groups[t] = []
			(groups[t] as Array).append(p)
	for t2: BUnit in groups.keys():
		var sum := 0.0
		for p2: Dictionary in groups[t2]:
			sum += pipeline.estimate_na(p2["from"], t2, float((p2["opts"] as Dictionary).get("na_scale", 1.0)), held_amp(p2))
		if sum + 0.01 < t2.hp + t2.shield:
			continue
		for p3: Dictionary in groups[t2]:
			var o: Dictionary = (p3["opts"] as Dictionary).duplicate()
			o["na_amp_bonus"] = held_amp(p3)
			p3["opts"] = o
			p3["hold"]["phase"] = "in"
			p3["hold"]["released"] = time
			p3["start"] = p3["pos"]
			p3["total"] = maxf(0.3, (p3["pos"] as Vector2).distance_to(t2.pos))
		fx({"t": "held_release", "target": t2, "count": (groups[t2] as Array).size(), "src": (groups[t2][0] as Dictionary)["from"]})


## 女仆护身术：拿近战武器的敌人走进了它自己打得到 u 的距离 → 发 OnMeleeApproach 给 u(目标 = 那个敌人)。只给有触发器在听的单位算；
## 同一个敌人走开(比够得着再远 0.9 米)之后再进来才算下一次
func _step_approach() -> void:
	for u: BUnit in units:
		if not u.alive or not pipeline._listens(u, "OnMeleeApproach"):
			continue
		var inside: Dictionary = u.meta.get("approached", {})
		for e: BUnit in units:
			if not e.alive or e.team == u.team or e.is_ranged() or not e.can_attack():
				continue
			var d: float = e.pos.distance_to(u.pos)
			var reach: float = e.get_stats().range_meters()
			if BattleAI.in_reach(e, u, d, reach + 0.2):
				if not inside.has(e.uid):
					inside[e.uid] = true
					pipeline.emit("OnMeleeApproach", u, e, 0.0, ["melee_approach"], {})
			elif inside.has(e.uid) and d > reach + u.radius + e.radius + 0.9:
				inside.erase(e.uid)
		u.meta["approached"] = inside


## 百合骑士的骑士(正行节点)：每个监听 OnEnemyNear 的触发器各自跟踪——敌人(身体边缘)进入 target_radius 米内 → 发一次(reason enter)；
## 在里面连续待满 extra.linger 秒 → 再发一次并重新计时(reason linger)；出去了就忘掉，再进来算新的一次。目标 = 那个敌人
func _step_near() -> void:
	for u: BUnit in units:
		if not u.alive or not pipeline._listens(u, "OnEnemyNear"):
			continue
		for trig: TriggerDef in u.all_triggers():
			if trig.timing != "OnEnemyNear":
				continue
			var r: float = trig.target_radius if trig.target_radius > 0.0 else 3.0
			var linger: float = float(trig.extra.get("linger", 0.0))
			var key: String = "near_" + trig.id
			var inside: Dictionary = u.meta.get(key, {})
			for e: BUnit in units:
				if not e.alive or e.team == u.team or e.has_flag("untargetable") or bool(e.meta.get("dropping", false)):
					if inside.has(e.uid):
						inside.erase(e.uid)
					continue
				if e.pos.distance_to(u.pos) - e.radius <= r:
					if not inside.has(e.uid):
						inside[e.uid] = time
						pipeline.emit("OnEnemyNear", u, e, 0.0, ["enemy_near"], {"trigger": trig.id, "reason": "enter"})
					elif linger > 0.0 and time - float(inside[e.uid]) >= linger - GC.SIM_DT * 0.5:
						inside[e.uid] = time
						pipeline.emit("OnEnemyNear", u, e, 0.0, ["enemy_near"], {"trigger": trig.id, "reason": "linger"})
				elif inside.has(e.uid):
					inside.erase(e.uid)
			u.meta[key] = inside


## 有拿着近战武器的敌人够得着 u(屏息节点：集中呼吸重置、瞄准眉心不再多瞄)
func melee_threat(u: BUnit) -> bool:
	for e: BUnit in units:
		if not e.alive or e.team == u.team or e.is_ranged() or not e.can_attack() or e.has_flag("untargetable"):
			continue
		if BattleAI.in_reach(e, u, e.pos.distance_to(u.pos), e.get_stats().range_meters() + 0.2):
			return true
	return false


## u 身边 r 米以内(边到边)有没有敌人
func enemy_near(u: BUnit, r: float) -> bool:
	for e: BUnit in enemies_of(u):
		if e.pos.distance_to(u.pos) - e.radius - u.radius <= r:
			return true
	return false


func _proj_blocked(a: Vector2, b2: Vector2, team: int) -> bool:
	for f: float in [0.5, 1.0]:
		if map.blocks_los(GC.world_to_cell(a.lerp(b2, f)), team):
			return true
	return false


# ---------------------------------------------------------------- 空间
## 朝向最近的敌人(开战时 / 召唤出场时)
func face_nearest_enemy(u: BUnit) -> void:
	var best: BUnit = null
	var bd := 1e18
	for o: BUnit in units:
		if o.alive and o.team != u.team:
			var d: float = o.pos.distance_squared_to(u.pos)
			if d < bd:
				bd = d
				best = o
	if best != null:
		u.facing = GC.facing_to(u.pos, best.pos)
		u.prev_facing = u.facing


func alive_units(team: int = -1) -> Array[BUnit]:
	var r: Array[BUnit] = []
	for u: BUnit in units:
		if u.alive and (team < 0 or u.team == team):
			r.append(u)
	return r


func enemies_of(u: BUnit) -> Array[BUnit]:
	return _side(u, false)


func allies_of(u: BUnit, include_self: bool = false) -> Array[BUnit]:
	return _side(u, true, include_self)


## 还在天上没落地的(星旅节点的坠落)不算：不能被选中
## 魂体存在的召唤物(flag untargetable)不在任何"敌人 / 队友"列表里：不能被选中
func _side(u: BUnit, same: bool, include_self: bool = false) -> Array[BUnit]:
	var r: Array[BUnit] = []
	for o: BUnit in units:
		if not o.alive or bool(o.meta.get("dropping", false)):
			continue
		if o.has_flag("untargetable") and o != u:
			continue
		# 少女幻葬的幽灵(feral)攻击不分敌我：它对所有人都是敌人，谁都可以打它
		var hostile: bool = o.team != u.team or (o != u and (bool(o.meta.get("feral", false)) or bool(u.meta.get("feral", false))))
		if hostile == same:
			continue
		if o == u and not include_self:
			continue
		r.append(o)
	return r


func get_unit_by_uid(uid: String) -> BUnit:
	for u: BUnit in units:
		if u.uid == uid:
			return u
	return null


func has_unit_id(def_id: String, team: int) -> bool:
	for u: BUnit in units:
		if u.alive and u.team == team and u.def.id == def_id:
			return true
	return false


func clamp_to_arena(p: Vector2, radius: float) -> Vector2:
	return GC.clamp_to_arena(p, radius)


func position_blocked(p: Vector2, radius: float, ignore: BUnit) -> bool:
	if not map.circle_free(p, radius):
		return true
	for u: BUnit in units:
		if not u.alive or u == ignore:
			continue
		if u.pos.distance_to(p) < u.radius + radius - 0.02:
			return true
	return false


func find_free_position(want: Vector2, radius: float, ignore: BUnit) -> Vector2:
	var p: Vector2 = clamp_to_arena(want, radius)
	if not position_blocked(p, radius, ignore):
		return p
	for ring in range(1, 8):
		for i in range(12):
			var a: float = TAU * float(i) / 12.0 + float(ring)
			var c: Vector2 = clamp_to_arena(want + Vector2(sin(a), cos(a)) * (0.5 * ring), radius)
			if not position_blocked(c, radius, ignore):
				return c
	return p


## 冲锋：沿直线(先快后慢)移到落点，无视碰撞；到了交给 Pipeline.dash_arrive 结算落地斩
# ---------------------------------------------------------------- 狩胜节点：狩猎对象 / 投掷
## 狩猎对象：现在的还活着就继续；否则(备战时被狩猎旗标标记、还活着的敌人优先)选本场至今造成伤害最多的存活敌人；
## 一样多时(开战时大家都是 0)取攻击力 + 法术强度最高的(最能造成伤害的)，再一样取离 u 最近的
func hunt_target_of(u: BUnit) -> BUnit:
	var cur: BUnit = hunt_targets.get(u.team, null) as BUnit
	if cur != null and cur.alive:
		return cur
	var best: BUnit = null
	var best_k := -1.0e30
	for e: BUnit in enemies_of(u):
		var est: StatBlock = e.get_stats()
		var k: float = e.st_damage * 1.0e6 + (est.attack_power + est.ability_power) * 100.0 - e.pos.distance_to(u.pos)
		if int(e.meta.get("hunt_marked_by", -1)) == u.team:
			k += 1.0e15
		if k > best_k:
			best_k = k
			best = e
	hunt_targets[u.team] = best
	if best != null:
		fx({"t": "hunt_target", "team": u.team, "unit": best})
	return best


## 投掷：前摇结束出手(武器离手飞出去，追着目标飞)；命中后造成伤害，投掷者立刻位移到目标身边(冲刺落地时拿回武器)
func _step_throws(dt: float) -> void:
	for u: BUnit in units.duplicate():
		if u.phase != "throw" or not u.alive:
			continue
		var d: Dictionary = u.meta.get("throw", {})
		if d.is_empty():
			u.phase = "idle"
			continue
		if bool(d.get("released", false)) or time < float(d["at"]):
			continue
		d["released"] = true
		var tgt: BUnit = d["target"]
		var dir := Vector2(sin(u.facing), cos(u.facing))
		var muzzle: Vector2 = u.pos + dir * 0.4
		var dest: Vector2 = tgt.pos if tgt != null else muzzle + dir
		_throw_id += 1
		var th := {"id": _throw_id, "src": u, "target": tgt, "pos": muzzle, "prev": muzzle, "dest": dest, "speed": float(d["speed"]),
			"amount": float(d["amount"]), "o": d["o"], "dash_speed": float(d.get("dash_speed", 16.0))}
		thrown.append(th)
		fx({"t": "throw_release", "unit": u, "target": tgt, "id": _throw_id, "flight": muzzle.distance_to(dest) / maxf(1.0, float(d["speed"]))})
	if thrown.is_empty():
		return
	var keep: Array[Dictionary] = []
	for th2: Dictionary in thrown:
		var src: BUnit = th2["src"]
		var tg: BUnit = th2["target"]
		th2["prev"] = th2["pos"]
		if tg != null and tg.alive:
			th2["dest"] = tg.pos
		var to_v: Vector2 = (th2["dest"] as Vector2) - (th2["pos"] as Vector2)
		var stp: float = float(th2["speed"]) * dt
		var reach: float = tg.radius * 0.8 if tg != null and tg.alive else 0.05
		if to_v.length() > stp + reach:
			th2["pos"] = (th2["pos"] as Vector2) + to_v.normalized() * stp
			keep.append(th2)
			continue
		th2["pos"] = th2["dest"]
		var hit: bool = tg != null and tg.alive
		fx({"t": "throw_hit", "unit": src, "target": tg if hit else null, "id": th2["id"], "pos": th2["dest"]})
		if hit and src != null:
			pipeline.fx.damage(src, tg, float(th2["amount"]), "physical", th2["o"])
		if src != null and src.alive and src.phase == "throw":
			_throw_dash(src, th2["dest"], tg if tg != null and tg.alive else null, float(th2["dash_speed"]))
	thrown = keep


## 投掷命中后：立刻位移到目标身边(在投掷者这一侧，贴着目标站)；落地时拿回武器(Pipeline.dash_arrive 的 after_throw)
func _throw_dash(u: BUnit, at: Vector2, tgt: BUnit, speed: float) -> void:
	u.meta.erase("throw")
	var away: Vector2 = u.pos - at
	if away.length() < 0.01:
		away = Vector2(0.0, -1.0 if u.team == GC.TEAM_PLAYER else 1.0)
	var gap: float = u.radius + (tgt.radius if tgt != null else 0.3) + 0.12
	var to: Vector2 = map.push_out(clamp_to_arena(at + away.normalized() * gap, u.radius), u.radius)
	var dist: float = u.pos.distance_to(to)
	var dur: float = clampf(dist / maxf(1.0, speed), 0.18, 0.55)
	u.phase = "dash"
	u.vel = Vector2.ZERO
	if dist > 0.05:
		u.facing = atan2(to.x - u.pos.x, to.y - u.pos.y)
	u.meta["dash"] = {"from": u.pos, "to": to, "t0": time, "dur": dur, "quiet": true, "after_throw": true}
	fx({"t": "dash_start", "unit": u, "from": u.pos, "to": to, "dur": dur, "leap": true})


func _step_dashes() -> void:
	for u: BUnit in units.duplicate():
		if not u.alive or u.phase != "dash":
			continue
		var d: Dictionary = u.meta.get("dash", {})
		if d.is_empty():
			u.phase = "idle"
			continue
		var k: float = clampf((time - float(d["t0"])) / maxf(0.01, float(d["dur"])), 0.0, 1.0)
		var e: float = 1.0 - (1.0 - k) * (1.0 - k)
		u.pos = (d["from"] as Vector2).lerp(d["to"], e)
		if k >= 1.0:
			u.pos = d["to"]
			u.phase = "idle"
			u.meta.erase("dash")
			pipeline.dash_arrive(u, d)


## 击退：按缓出曲线把这一步该走的那一段位移叠加上去(和 AI 自己的移动叠加，不抢状态机)
func _step_knocks() -> void:
	for u: BUnit in units:
		if not u.alive or not u.meta.has("knock"):
			continue
		var kn: Dictionary = u.meta["knock"]
		var k: float = clampf((time - float(kn["t0"])) / maxf(0.01, float(kn["dur"])), 0.0, 1.0)
		var e: float = 1.0 - (1.0 - k) * (1.0 - k)
		u.pos += ((kn["to"] as Vector2) - (kn["from"] as Vector2)) * (e - float(kn["done"]))
		kn["done"] = e
		if k >= 1.0:
			u.meta.erase("knock")


func resolve_collisions() -> void:
	var alive: Array[BUnit] = []
	for au: BUnit in alive_units():
		if au.has_flag("phasing"):
			au.pos = clamp_to_arena(au.pos, au.radius)     # 闪电跑者：穿过地形和其他人(不参与碰撞，只是不出场地)
			continue
		if au.phase != "dash" and au.phase != "drop":     # 冲锋中无视碰撞体积(穿过去)；还在天上的不碰撞
			alive.append(au)
	for _pass in range(2):
		for i in range(alive.size()):
			var a: BUnit = alive[i]
			for j in range(i + 1, alive.size()):
				var c: BUnit = alive[j]
				var d: Vector2 = a.pos - c.pos
				var minimum: float = a.radius + c.radius
				var dist2: float = d.length_squared()
				if dist2 >= minimum * minimum:
					continue
				var dist: float = sqrt(dist2)
				var n: Vector2 = d / dist if dist > 0.0001 else Vector2(rng.randf() - 0.5, rng.randf() - 0.5).normalized()
				var overlap: float = minimum - dist
				var wa: float = a.radius * a.radius * (2.5 if _planted(a) else 1.0)
				var wc: float = c.radius * c.radius * (2.5 if _planted(c) else 1.0)
				a.pos += n * overlap * (wc / (wa + wc))
				c.pos -= n * overlap * (wa / (wa + wc))
	for u: BUnit in alive:
		u.pos = map.push_out(clamp_to_arena(u.pos, u.radius), u.radius)
	for lu: BUnit in units:
		if lu.alive and lu.meta.has("leash"):
			var ls: Dictionary = lu.meta["leash"]
			var lc: Vector2 = ls["c"]
			var lr: float = maxf(0.1, float(ls["r"]) - lu.radius)
			if lu.pos.distance_to(lc) > lr:
				lu.pos = lc + (lu.pos - lc).normalized() * lr


## 灭罪节点的光束(她是唯一的光)：她不在吟唱(被打断 / 倒下)就消失；开打后每一步慢慢挪向敌方本场伤害最高的单位
## (Targeting.top_damage_pick；直线过去，不避让友军、不管地形)。伤害由她的被动在每个战斗帧结算(Pipeline._light_beam)
func _step_light_beams(dt: float) -> void:
	for u: BUnit in units:
		if not u.meta.has("light_beam"):
			continue
		var lb: Dictionary = u.meta["light_beam"]
		if not u.alive or u.phase != "chant" or not is_equal_approx(float(lb["chant"]), u.chant_until):
			u.meta.erase("light_beam")
			fx({"t": "light_beam_end", "unit": u, "pos": lb["pos"]})
			continue
		lb["prev"] = lb["pos"]
		if state != "running":
			continue
		var lk: BUnit = Targeting.top_damage_pick(self, u)
		lb["lock"] = lk
		if lk == null:
			continue
		var p: Vector2 = lb["pos"]
		var to: Vector2 = lk.pos - p
		var stp: float = float(lb.get("speed", 1.0)) * dt
		lb["pos"] = clamp_to_arena(lk.pos if to.length() <= stp else p + to.normalized() * stp, 0.0)


## 站定的单位碰撞时更"重"(被挤动得少)：出招 / 吟唱 / 拉弓 / 装弹 / 收招，以及贴着目标打的近战
func _planted(u: BUnit) -> bool:
	return u.def.sky_caster or u.engaged or u.phase == "windup" or u.phase == "chant" or u.phase == "draw" or u.phase == "reload" 		or u.phase == "recover" or u.phase == "storm"


func interrupt(u: BUnit) -> void:
	# 打断时也结算的吟唱(猎人笔记：按已经吟唱的秒数给加成，但不算"完整结束")
	if u.phase == "chant" and u.chant_ability != null and bool(u.chant_ability.effect_config.get("release_on_interrupt", false)):
		fx({"t": "interrupt", "unit": u})
		pipeline.release_chant(u, clampf(u.phase_dur - (u.chant_until - time), 0.0, u.phase_dur), true)
		return
	if u.phase == "storm":
		u.phase = "idle"                             # 清洁世界转到一半被打断：剩下的飞刀不扔了
		u.meta.erase("storm")
		fx({"t": "interrupt", "unit": u})
		return
	if u.phase == "windup" or u.phase == "chant" or u.phase == "recover" or u.phase == "draw" or u.phase == "reload":
		u.phase = "idle"
		u.chant_ability = null
		u.chant_event = {}
		fx({"t": "interrupt", "unit": u})


# ---------------------------------------------------------------- 真骰(巧运节点)
## 有明确好坏的概率，"成功 = 掷出的数 < 概率"：u 带 lucky(真骰)时掷两次取对自己好的那个。
## roll_good：成功对 u 是好事(暴击、闪避、摸到金币)——取小的；roll_bad：成功对 u 是坏事(被麻痹打断、远距离打空)——取大的
func roll_good(u: BUnit) -> float:
	var r: float = rng.randf()
	if u != null and u.has_flag("lucky"):
		r = minf(r, rng.randf())
	return r


func roll_bad(u: BUnit) -> float:
	var r: float = rng.randf()
	if u != null and u.has_flag("lucky"):
		r = maxf(r, rng.randf())
	return r


# ---------------------------------------------------------------- 经济 / 成长
func grant_gold(team: int, amount: int, source: BUnit = null) -> void:
	gold_gain[team] = int(gold_gain.get(team, 0)) + amount
	fx({"t": "gold", "team": team, "amount": amount, "unit": source})


func grant_xp(team: int, amount: int, source: BUnit = null) -> void:
	xp_gain[team] = int(xp_gain.get(team, 0)) + amount
	fx({"t": "xp", "team": team, "amount": amount, "unit": source})


func add_permanent_growth(u: BUnit, stat: String, amount: float) -> void:
	# 永恒：成长写回花名册实例(见 Run.apply_battle_growth)，同时当场生效
	var key: String = u.roster_id if u.roster_id != "" else u.uid
	var g: Dictionary = growth.get(key, {})
	g[stat] = float(g.get(stat, 0.0)) + amount
	growth[key] = g
	u.perm_flat[stat] = float(u.perm_flat.get(stat, 0.0)) + amount
	u.mark_dirty()
	fx({"t": "growth", "unit": u, "stat": stat, "amount": amount})


# ---------------------------------------------------------------- 温柔地 / 永恒状态
## 温柔地：从现在(还在倒计时就从开打)起 dur 秒，所有单位受到的伤害最终 × (1 - k)
func add_gentle(src: BUnit, k: float, dur: float) -> void:
	var start: float = maxf(time, GC.START_DELAY)
	var g := {"until": start + dur, "k": clampf(k, 0.0, 0.99), "src": src}
	gentle.append(g)
	fx({"t": "gentle_start", "unit": src, "until": g["until"], "k": g["k"]})


## 这一刻所有单位受到的伤害最终降低多少(没有 = 0)
func gentle_factor() -> float:
	var k := 0.0
	for g: Dictionary in gentle:
		if time < float(g["until"]):
			k = maxf(k, float(g["k"]))
	return k


func _step_gentle() -> void:
	if gentle.is_empty():
		return
	var keep: Array[Dictionary] = []
	for g: Dictionary in gentle:
		if time >= float(g["until"]):
			fx({"t": "gentle_end", "unit": g["src"]})
		else:
			keep.append(g)
	gentle = keep


## 单位身上的永恒状态序列化(跨战斗保留：只存数值和层数，施加者 / 计时不存)
static func eternal_statuses_of(u: BUnit) -> Array:
	var r: Array = []
	for st: BStatus in u.statuses.values():
		if not st.eternal or st.stacks <= 0:
			continue
		r.append({"id": str(st.meta.get("base_id", st.id)), "stacks": st.stacks, "max_stacks": st.max_stacks,
			"flat": st.flat_per_stack.duplicate(), "pct": st.pct_per_stack.duplicate(), "flags": Array(st.flags)})
	return r


## 把序列化的永恒状态挂回单位身上(不经过 apply_status：免疫 / 倍率之类的规则在第一次挂上时已经算过了)
static func restore_eternal(u: BUnit, es: Dictionary) -> void:
	if int(es.get("stacks", 0)) <= 0:
		return
	var st := BStatus.new()
	st.id = str(es.get("id", "status"))
	st.stacks = int(es.get("stacks", 1))
	st.max_stacks = maxi(st.stacks, int(es.get("max_stacks", 1)))
	st.flat_per_stack = (es.get("flat", {}) as Dictionary).duplicate()
	st.pct_per_stack = (es.get("pct", {}) as Dictionary).duplicate()
	for f: Variant in es.get("flags", []):
		st.flags.append(str(f))
	st.eternal = true
	st.expires_at = -1.0
	st.meta["base_id"] = st.id
	u.statuses[st.id] = st
	u.mark_dirty()


# ---------------------------------------------------------------- 死亡 / 终局
func on_unit_died(u: BUnit) -> void:
	if not u.is_summon:
		death_times.append(time)
	# 少女幻葬的幽灵拴在她的溅射范围里：她倒下(终结 / 被打死)，它们也就散了
	for o: BUnit in units:
		if o.alive and bool(o.meta.get("feral", false)) and o.meta.get("summoner") == u:
			schedule(time + 0.05, _vanish.bind(o))
	if u.team != GC.TEAM_PLAYER and u.meta.has("orb"):
		drops.append({"tier": str(u.meta["orb"]), "pos": u.pos})
		fx({"t": "orb_drop", "tier": str(u.meta["orb"]), "pos": u.pos})
	_clear_refs(u)


## 复活(少女真心)：站起来，生命 = 上限 × pct；负面状态和"必死"之类的标记清掉，动作状态回到待机
## hp_abs >= 0：直接以这么多生命复活(希望：以回复量复活)，否则按最大生命的 pct；kind = 谁复活的(只给表现层挑特效：hope …)
func revive(u: BUnit, pct: float, hp_abs: float = -1.0, kind: String = "") -> void:
	u.alive = true
	u.phase = "idle"
	u.vel = Vector2.ZERO
	for k: String in ["_doomed", "_before_death_done", "no_death_fx", "finale_death", "hush_death", "funeral_death", "spent", "run", "knock", "storm", "dash"]:
		u.meta.erase(k)
	u.chant_ability = null
	u.chant_event = {}
	u.target = null
	u.attack_target = null
	u.attack_cd = 0.4
	for sid: Variant in u.statuses.keys():
		var st: BStatus = u.statuses[sid]
		if st.has_flag("debuff") or st.has_flag("undying") or bool(st.meta.get("doom", false)):
			u.statuses.erase(sid)
	u.mark_dirty()
	u.recompute()
	u.hp = maxf(1.0, minf(u.get_stats().max_health, hp_abs) if hp_abs >= 0.0 else u.get_stats().max_health * pct)
	u.pos = map.push_out(clamp_to_arena(u.pos, u.radius), u.radius)
	fx({"t": "revive", "unit": u, "hp": u.hp, "kind": kind})


func _vanish(u: BUnit) -> void:
	if u.alive:
		u.meta["_doomed"] = true
		u.hp = 0.0
		pipeline.fx.try_kill(u, null)


func _clear_refs(u: BUnit) -> void:
	for o: BUnit in units:
		if o.target == u:
			o.target = null
		if o.forced_target == u:
			o.forced_target = null
		# 缠绕：和倒下的一方解开；没有缠着谁了就解除定身，改为强制瞄准还缠着的另一个
		for st: BStatus in _binds_of(o):
			var partners: Array = st.meta.get("partners", [])
			if partners.has(u.uid):
				partners.erase(u.uid)
				st.meta["partners"] = partners
				if partners.is_empty() or o == u:
					pipeline.fx.end_status(o, st.id)
				elif o.alive:
					var nxt: BUnit = get_unit_by_uid(str(partners[0]))
					if nxt != null and nxt.alive:
						o.forced_target = nxt
						o.forced_until = 1.0e9
						o.target = nxt


## u 身上所有"互相缠住"的状态实例
func _binds_of(u: BUnit) -> Array[BStatus]:
	var r: Array[BStatus] = []
	for bid: String in BIND_IDS:
		r.append_array(u.status_instances(bid))
	return r


## 连锁闪电(导向节点·引雷)：先打中 t，再弹跳 N 次(N 按星级)——每一跳都是一次完整的普攻(倍率、吟唱倍率、武器的普攻关键词都照旧)；
## 下一跳 = 身体边缘在这一跳的目标 radius 米内的另一个敌人：先挑还没打过的里最近的，都打过了才弹回之前打过的(不能连着弹同一个人；没有就提前结束)。
## 只有第一跳会追击(双枪的追击副本自己再连一串)。
## 2026-10-07 起一跳一跳地传过去(用户："闪电的传播过程太快，看不清连锁闪电链")：第一跳当场打中，之后每一跳隔 hop_dt(默认 CHAIN_HOP_DT)秒——
## 选好下一跳就发 chain_hop 事件(表现层画一道这么久飞到的闪电)，到点才结算那一跳；下一跳的目标到点时已经倒下 / 她倒下 / 战斗结束 = 链子断在这里。
## 弹跳结束发 chain_lightning(整条路径，表现层整条链再亮一下)和 OnChainEnd(meta.targets = 打到的所有敌人，按命中顺序、不重复)
const CHAIN_HOP_DT := 0.13


func chain_lightning(u: BUnit, t: BUnit, is_copy: bool, opts: Dictionary, ch: Dictionary) -> void:
	var byst: Dictionary = ch.get("bounces_by_star", {})
	var st := {"u": u, "first": t, "is_copy": is_copy, "opts": opts, "n": int(byst.get(str(mini(u.star, 3)), ch.get("bounces", 1))),
		"rad": float(ch.get("radius", 3.0)), "dt": float(ch.get("hop_dt", CHAIN_HOP_DT)), "hits": [], "path": [t], "i": 0}
	fx({"t": "chain_hop", "unit": u, "from": null, "to": t, "i": 0, "dt": 0.0, "copy": is_copy})
	_chain_hop(st, t)


func _chain_hop(st: Dictionary, cur: BUnit) -> void:
	var u: BUnit = st["u"]
	var i: int = int(st["i"])
	var hits: Array = st["hits"]
	if i > 0 and (not cur.alive or not u.alive or state == "ended"):
		_chain_end(st)
		return
	var o2: Dictionary = (st["opts"] as Dictionary).duplicate()
	o2["chain_hop"] = i
	if i > 0:
		o2["copies_sent"] = true                 # 弹出去的那几跳不再追击
		o2.erase("aim_point")
	pipeline.normal_attack(u, cur, bool(st["is_copy"]), o2)
	if not hits.has(cur):
		hits.append(cur)
	if i >= int(st["n"]) or not u.alive or state == "ended":
		_chain_end(st)
		return
	var rad: float = float(st["rad"])
	var nxt: BUnit = null
	var best: float = INF
	for e: BUnit in units:
		if not e.alive or e.team == u.team or e == cur or e.has_flag("untargetable") or bool(e.meta.get("dropping", false)):
			continue
		var d: float = e.pos.distance_to(cur.pos) - e.radius
		if d > rad:
			continue
		if hits.has(e):
			d += 1000.0                          # 先找还没打过的；都打过了才弹回去
		if d < best:
			best = d
			nxt = e
	if nxt == null:
		_chain_end(st)
		return
	(st["path"] as Array).append(nxt)
	st["i"] = i + 1
	var dt: float = float(st["dt"])
	fx({"t": "chain_hop", "unit": u, "from": cur, "to": nxt, "i": i + 1, "dt": dt, "copy": bool(st["is_copy"])})
	if dt <= 0.0:
		_chain_hop(st, nxt)
	else:
		schedule(time + dt, _chain_hop.bind(st, nxt))


func _chain_end(st: Dictionary) -> void:
	var u: BUnit = st["u"]
	fx({"t": "chain_lightning", "unit": u, "path": st["path"], "copy": bool(st["is_copy"])})
	if u.alive:
		pipeline.emit_now("OnChainEnd", u, st["first"], 0.0, ["chain_end"], {"targets": st["hits"]})


## 一队里(不算召唤物)已阵亡 / 还活着的人数：[阵亡, 活着](奇兴节点：掷骰 + 阵亡的队友数、苏醒条件、乱数的必定 20)
func team_dead_alive(team: int) -> Array[int]:
	var dead := 0
	var alive := 0
	for u: BUnit in units:
		if u.team != team or u.is_summon:
			continue
		if u.alive:
			alive += 1
		else:
			dead += 1
	return [dead, alive]


## 一群单位随机交换位置(无数世界：奇数 → 所有敌人；双 1 → 所有人)：位置打乱后重新分给每个人，正在跑的路线 / 冲刺作废
func shuffle_positions(group: Array, src: BUnit = null) -> void:
	if group.size() < 2:
		return
	var spots: Array[Vector2] = []
	for g: Variant in group:
		spots.append((g as BUnit).pos)
	var order: Array = range(spots.size())
	for i in range(order.size() - 1, 0, -1):
		var j: int = rng.randi() % (i + 1)
		var tmp: Variant = order[i]
		order[i] = order[j]
		order[j] = tmp
	var moves: Array = []
	for k in range(group.size()):
		var u: BUnit = group[k]
		var to: Vector2 = spots[int(order[k])]
		if to.distance_to(u.pos) < 0.01:
			continue
		moves.append({"unit": u, "from": u.pos, "to": to})
		u.pos = to
		u.vel = Vector2.ZERO
	fx({"t": "shuffle", "unit": src, "moves": moves})


## 裂地猛击(圣战节点)：从 origin 朝 dir 的锥形(cone.angle 度、cone.length 米)里的地形打碎——断壁残垣 / 燃烧废墟碎掉(格子空出来，
## 不再挡路 / 挡视线 / 烧人；祭坛、喷泉这类机制核心打不碎)，余烬熄灭，寒雾散开。返回打碎了几块
func break_terrain_in_cone(origin: Vector2, dir: Vector2, cone: Dictionary, src: BUnit = null) -> int:
	var n := 0
	for i in range(map.obstacles.size()):
		var o: Dictionary = map.obstacles[i]
		if bool(o.get("destroyed", false)) or BattleMap.UNBREAKABLE.has(str(o.get("style", ""))):
			continue
		if _rect_in_cone(o["rect"], origin, dir, cone):
			map.destroy_obstacle(i)
			fx({"t": "terrain_break", "kind": "obstacle", "id": i, "unit": src})
			n += 1
	for e: Dictionary in map.embers:
		if bool(e["lit"]) and _rect_in_cone(e["rect"], origin, dir, cone):
			map.put_out_ember(int(e["id"]))
			fx({"t": "ember_out", "id": int(e["id"]), "unit": src})
			n += 1
	for f: Dictionary in map.frost:
		if not bool(f.get("destroyed", false)) and _rect_in_cone(f["rect"], origin, dir, cone):
			map.destroy_frost(int(f["id"]))
			fx({"t": "terrain_break", "kind": "frost", "id": int(f["id"]), "unit": src})
			n += 1
	return n


## 格子矩形有没有一格(格子中心)落在锥形里(边上留半格的余量)
func _rect_in_cone(r: Rect2i, origin: Vector2, dir: Vector2, cone: Dictionary) -> bool:
	var half: float = deg_to_rad(float(cone.get("angle", 100.0)) * 0.5)
	var length: float = float(cone.get("length", 3.5))
	var d: Vector2 = dir.normalized()
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c: Vector2 = map.rect_world(Rect2i(x, y, 1, 1)).get_center()
			var rel: Vector2 = c - origin
			var dist: float = rel.length()
			if dist > length + GC.CELL * 0.5:
				continue
			if dist < GC.CELL * 0.75 or absf(d.angle_to(rel)) <= half + atan2(GC.CELL * 0.5, dist):
				return true
	return false


## 变天(导向节点)：换战场天气(一场只有一种；几个导向节点同时在场不叠加)
func set_weather(kind: String, src: BUnit = null, params: Dictionary = {}) -> void:
	if kind == weather:
		return
	weather = kind
	weather_params = params.duplicate(true)
	fx({"t": "weather", "kind": kind, "unit": src})


## 把 u 从所有缠绕里解开(守林节点离开巨蟾蜍形态)：和倒下时一样处理缠着它的人
func release_binds(u: BUnit) -> void:
	for o: BUnit in units:
		for st: BStatus in _binds_of(o):
			var partners: Array = st.meta.get("partners", [])
			if o == u:
				for pid: Variant in partners:
					var pu: BUnit = get_unit_by_uid(str(pid))
					if pu != null and pu.forced_target == u:
						pu.forced_target = null
				pipeline.fx.end_status(o, st.id)
				continue
			if partners.has(u.uid):
				partners.erase(u.uid)
				st.meta["partners"] = partners
				if o.forced_target == u:
					o.forced_target = null
				if partners.is_empty():
					pipeline.fx.end_status(o, st.id)
	if u.forced_target != null:
		u.forced_target = null


func _check_end() -> void:
	if state == "ended":
		return
	var p_alive: int = 0
	var e_alive: int = 0
	for u: BUnit in units:
		if not u.alive or u.has_flag("untargetable") or bool(u.meta.get("feral", false)):
			continue                                   # 魂体存在的召唤物 / 不分敌我的幽灵不算哪一队还活着
		if u.team == GC.TEAM_PLAYER:
			p_alive += 1
		else:
			e_alive += 1
	if state == "raid":
		if e_alive == 0 or time - raid_start >= GC.RAID_MAX_SECONDS:
			for u2: BUnit in units:
				if u2.alive and u2.team != GC.TEAM_PLAYER:
					_enter_truck(u2)
			_finish(GC.TEAM_ENEMY)
		return
	var battle_elapsed: float = time - GC.START_DELAY
	if (p_alive == 0 or e_alive == 0) and battle_elapsed < GC.BATTLE_MAX_SECONDS and state == "running":
		for team: int in [GC.TEAM_PLAYER, GC.TEAM_ENEMY]:
			if (p_alive if team == GC.TEAM_PLAYER else e_alive) > 0:
				continue
			for wu: BUnit in units.duplicate():
				if wu.team == team and not wu.is_summon:
					pipeline.emit("OnTeamWiped", wu, null, 0.0, ["team_wiped"], {"team": team})
		p_alive = 0
		e_alive = 0
		for u4: BUnit in units:
			if u4.alive and not u4.has_flag("untargetable") and not bool(u4.meta.get("feral", false)):
				if u4.team == GC.TEAM_PLAYER:
					p_alive += 1
				else:
					e_alive += 1
	if p_alive > 0 and e_alive > 0 and battle_elapsed < GC.BATTLE_MAX_SECONDS:
		return
	if p_alive > 0 and e_alive == 0:
		_finish(GC.TEAM_PLAYER)
	elif p_alive == 0 and e_alive == 0:
		_finish(2)
	elif p_alive == 0:
		# 我方全灭：敌人涌入卡车
		state = "raid"
		raid_start = time
		fx({"t": "raid_start"})
	else:
		# 超时：算作失败，场上存活的敌人全部计入卡车伤害
		for u3: BUnit in units:
			if u3.alive and u3.team != GC.TEAM_PLAYER:
				truck_damage += truck_damage_of(u3)
		_finish(GC.TEAM_ENEMY)


func _finish(w: int) -> void:
	winner = w
	state = "ended"
	end_time = time
	# 永恒状态跨战斗保留：我方(有花名册 id 的)棋子身上的永恒状态记下来，倒下的也算
	for ue: BUnit in units:
		if ue.team == GC.TEAM_PLAYER and ue.roster_id != "" and not ue.is_summon:
			eternal_out[ue.roster_id] = eternal_statuses_of(ue)
			# 【永恒】【学习】的武器效果：学习计数跨战斗保留(记在这个棋子身上)
			if ue.weapon != null:
				for wa: AbilityDef in ue.weapon.abilities:
					if wa.has_keyword("eternal") and wa.has_keyword("learning"):
						(learning_out.get_or_add(ue.roster_id, {}) as Dictionary)[wa.id] = int(ue.learning.get(wa.id, 0))
	# 战斗结束时机(永恒成长等)：参战过的棋子都算，中途倒下的也照样结算("每场战斗结束后……")；召唤物不算
	for u2: BUnit in units.duplicate():
		if u2.alive or not u2.is_summon:
			pipeline.emit("OnBattleEnd", u2, null, 0.0, ["battle_end"], {"winner": winner, "alive": u2.alive})
	_apply_trait_growth()
	report.finalize(units, end_time - GC.START_DELAY)
	fx({"t": "battle_end", "winner": winner, "truck_damage": truck_damage})


## 一个敌人涌入卡车造成的耐久伤害
static func truck_damage_of(u: BUnit) -> int:
	var d: int = int(GC.TRUCK_DAMAGE_BY_STAR.get(clampi(u.star, 1, 3), 2))
	if bool(u.meta.get("boss", false)):
		d += GC.TRUCK_DAMAGE_BOSS_BONUS
	return d


func _step_raid(dt: float) -> void:
	for u: BUnit in units.duplicate():
		if not u.alive or u.team == GC.TEAM_PLAYER:
			continue
		ai.raid_step(u, dt)
		if map.dist_to_truck(u.pos) <= u.radius + 0.2:
			_enter_truck(u)


func _enter_truck(u: BUnit) -> void:
	if not u.alive:
		return
	u.alive = false
	u.meta["entered_truck"] = true
	var dmg: int = truck_damage_of(u)
	truck_damage += dmg
	_clear_refs(u)
	fx({"t": "enter_truck", "unit": u, "damage": dmg})


func _team_hp_ratio(team: int) -> float:
	var cur := 0.0
	var mx := 0.0
	for u: BUnit in units:
		if u.team == team:
			cur += maxf(0.0, u.hp)
			mx += u.get_stats().max_health
	return cur / maxf(1.0, mx)


func _apply_trait_growth() -> void:
	for team: int in trait_reports.keys():
		var members: Array[BUnit] = []
		for u: BUnit in units:
			if u.team == team and not u.is_summon:
				members.append(u)
		for r: Dictionary in trait_reports[team]:
			var t: TraitDef = r["trait"]
			var tier: int = int(r["tier"])
			if tier <= 0:
				continue
			var growth_def: Dictionary = (t.tiers.get(tier, {}) as Dictionary).get("growth", {})
			if growth_def.is_empty():
				continue
			for idx: int in r["beneficiary_idx"]:
				if idx < members.size() and members[idx].alive:
					for stat: String in growth_def.keys():
						add_permanent_growth(members[idx], stat, float(growth_def[stat]))


## 战后统计(用于结算界面)
func summary() -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for u: BUnit in units:
		r.append({"uid": u.uid, "def": u.def.id, "team": u.team, "star": u.star, "alive": u.alive and not u.meta.has("entered_truck"),
			"damage": u.st_damage, "taken": u.st_taken, "heal": u.st_heal, "shield": u.st_shield,
			"kills": u.st_kills, "by_kind": u.st_dmg_by_kind.duplicate(), "hp": u.hp, "max_hp": u.get_stats().max_health})
	return r
