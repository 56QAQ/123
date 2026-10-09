class_name Run
extends RefCounted
## 一局游戏(roguelite)的状态：卡车耐久、金币/等级、花名册(棋盘 + 仓库，仓库不限数量)、武器背包、商店，以及章节地图上的进度。
## 流程(线性章节，第零章)：map(地图) → travel() 抵达节点 → prepare(备战，商店免费刷新) → battle → finish_battle() → loot(开晶球) → finish_loot()
##       → 下一个节点 / 章节结束(chapter_end)。卡车耐久归零也会结束(over，失败)。
## 方格网章节(第一章起，ChapterMap)：map → move_to(格点)(扣行动力) → 按节点类型：
##       作战/精英/首领 → prepare → battle → loot → map；修整 rest / 事件 event / 商店 shop → leave_node() → map。
##       行动力用完还没打倒首领 → 追猎(hunt_active，就地开战)。打倒首领或赢下追猎 → chapter_end。
## 章节结束：branch(选下一章的分支) → chapter_end(按下一章的颜色 / 出现时间从改装池里三选一：roll_mod_options) → 新章节的 map；
## 没有下一章 → over(通关)。开局(正式游戏)：start_mod(出现时间 0 的三个初始改装 = 卡车摆法，决定卡车能不能在备战时移动 / 旋转、部署区多大) → map。
## 改装数据在 Catalog.mods(tools/author_mods.py)；已选的记在 truck_mods，开战时 build_battle_setup 的 cfg.mods 交给 Battle 挂到单位上。
##   卡车摆法 truck_layout(卡车格子 / 朝向 / 部署区)在备战时用 move_truck / rotate_truck 改，写进 current_layout() 交给战斗地图和表现层。
## 所有操作返回 {ok:bool, reason:String(本地化键)}，界面据此给出可读的失败提示。

signal changed(reason: String)

var catalog: Catalog
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var seed_value: int = 1
var shop_rule: Dictionary = {}

var gold: int = 3
var level: int = 3
var xp: int = 0
var truck_hp: int = GC.TRUCK_MAX_HP
var truck_max: int = GC.TRUCK_MAX_HP
var truck_mods: Array[String] = []      # 已选的卡车改装 id(Catalog.mods；开局那一个带 layout = 卡车摆法)
var pending_chapter: String = ""        # 选了分支、还在选改装：要进的那一章
var truck_layout: TruckLayout = TruckLayout.make("")   # 卡车现在的摆法(位置 / 朝向 / 部署区)
var phase: String = "map"               # start_mod / map / prepare / battle / loot / rest / event / shop / chapter_end / branch / over
var won_run: bool = false               # 章节全部打通

# ---- 章节地图
var chapter_id: String = "ch0"
var chapter: Dictionary = {}
var node_index: int = 0                 # 下一个(或当前)地图节点
var layouts: Array[Dictionary] = []     # 每个地图节点的战斗地图(障碍物布局)，开局就生成好：大地图与战斗地图一致

# ---- 方格网章节(第一章起；线性章节时 gmap 为空)
var gmap: Dictionary = {}               # ChapterMap.generate 的结果；节点状态 hidden / seen / done 直接改在里面
var pos: String = ""                    # 卡车所在的格点
var ap: int = 0                         # 行动力
var ap_max: int = 0
var steps: int = 0                      # 本章走过的格点数(= 花掉的行动力)；遭遇难度按它算
var parts: Array[String] = []           # 零件箱(卡车零件)
var hunt_active: bool = false           # 当前这场是追猎
var hunt_enc: Dictionary = {}
var hunt_layout: Dictionary = {}
var ap_penalty: int = 0                 # 被追猎过：下一章初始行动力 -1(累计)
var node_shops: Dictionary = {}         # 格点 -> 商店状态 {type, offers:[{kind,id,price,sold}], refreshes}
var visits: int = 0                     # 进入战斗节点的次数(战斗地图的种子)
var chapters_cleared: Array[String] = []
var mod_options: Array[String] = []     # 现在可选的卡车改装(开局 / 章节过渡的三选一)

# ---- 花名册 / 背包 / 商店
var roster: Dictionary = {}             # roster_id -> {id, def, star, weapon:id|""(=基础武器), perm:{}, cell:Vector2i|null, bench:int}
var inventory: Array[String] = []       # 背包里的武器(不含基础武器)；也放特殊物品(slot = token，例如狩猎旗标)
var hunt_mark: int = -1                 # 狩猎旗标标记的敌人(当前遭遇 units 里的下标)；-1 = 没有标记
var materials: Dictionary = {"red": 0, "green": 0, "blue": 0}   # 车间材料：燃素 / 有机物 / 液态负熵
var craft_last: Dictionary = {}         # 车间上次的选择 {kind, cats:{种类: [门类]}, mats}(界面打开时沿用)
var crafted: int = 0                    # 本局在车间造了几件
var events_gone: Array[String] = []     # 出现过的通用 / 特定章节事件(整局移出事件池)
var events_this_chapter: Array[String] = []   # 本章出现过的事件(颜色 / 限定事件同一章不重复)
var event_state: Dictionary = {}        # 当前事件 {id, node, option(-1 = 还没选), outcome, picks{选项: 次数}, closed[], gains[], repeat}
var flags: Dictionary = {}              # 事件留下的局内状态(诅咒 / 祝福)：id -> {value, until: next_battle / chapter / run}(Events.FLAG_IDS)
var shop: Array[Dictionary] = []        # [{def:String, sold:bool}]
var shop_locked: bool = false
var sandbox: bool = false               # 测试场(标题画面进入)：随意加棋子 / 改星级 / 换武器，上场人数不限

# ---- 战利品
var pending_orbs: Array[Dictionary] = []   # 本场掉落的晶球 [{tier, pos:Vector2, opened:bool, loot:{}}]
var loot_counts: Dictionary = {"weapon": 0, "unit": 0}   # 本章晶球已开出的武器/节点数(保底用)
var last_result: Dictionary = {}
var _next_id: int = 1
var _store_seq: int = 1                  # 进仓库的先后(roster 的 stored_at；星旅节点"最先进入仓库"的那个先坠落)


## choose_start = true(正式游戏)：先进 start_mod 阶段三选一初始卡车改装(pick_mod)再到地图；false(测试 / 跑分)= 初始摆法、卡车不能动
static func create(cat: Catalog, p_seed: int = 0, chapter_id: String = "ch0", choose_start: bool = false) -> Run:
	var r := Run.new()
	r.catalog = cat
	r.seed_value = p_seed if p_seed != 0 else int(Time.get_ticks_usec() % 1000000007)
	r.rng.seed = r.seed_value
	r.shop_rule = cat.shop
	r.enter_chapter(chapter_id)
	r.add_unit("node_archer", 1, GC.TRUCK_RECT.position + Vector2i(-1, -1), -1)
	r.add_unit("node_darkknight", 1, GC.TRUCK_RECT.position + Vector2i(3, -1), -1)
	# 开局还送一个空白节点(站在卡车正后方，不占上阵人数)，手里拿着打工小帮手
	var nb: Dictionary = r.add_unit("node_basic", 1, GC.TRUCK_RECT.position + Vector2i(1, 2), -1)
	nb["weapon"] = "work_helper"
	r.inventory = ["rapidfire_arbalest", "blackblade"]
	r.materials = Crafting.empty_mats()
	r.add_materials(cat.workshop.get("start", {}))
	r.roll_shop(false)
	if choose_start:
		r.mod_options = r.roll_mod_options(0, "white")
		r.phase = "start_mod"
	return r


## 进入一个章节：读取起始资源(仅开局的第一个章节生效；之后的章节沿用金币/等级/卡车耐久)，生成地图
func enter_chapter(id: String, first: bool = true) -> void:
	chapter_id = id
	chapter = catalog.chapters.get(id, {})
	node_index = 0
	phase = "map"
	loot_counts = {"weapon": 0, "unit": 0}
	events_this_chapter.clear()
	event_state = {}
	_expire_flags("chapter")
	_expire_flags("next_battle")
	if first:
		gold = int(chapter.get("start_gold", gold))
		level = int(chapter.get("start_level", level))
		truck_max = int(chapter.get("truck_hp", GC.TRUCK_MAX_HP))
		truck_hp = truck_max
	layouts.clear()
	gmap = {}
	hunt_active = false
	node_shops.clear()
	if is_grid():
		_setup_grid()
		return
	var nodes: Array = chapter.get("nodes", [])
	for i in range(nodes.size()):
		var enc: Dictionary = (nodes[i] as Dictionary).get("encounter", {})
		var mcfg: Dictionary = (enc.get("map", {}) as Dictionary).duplicate()
		var regions: Array = []
		for e: Variant in enc.get("units", []):
			regions.append((e as Array)[2])
		mcfg["regions"] = regions
		layouts.append(MapGen.generate(mcfg, seed_value * 131 + i * 7919 + 17))


func map_nodes() -> Array:
	return chapter.get("nodes", [])


func is_grid() -> bool:
	return str(chapter.get("map_kind", "")) == "grid"


func current_node() -> Dictionary:
	if is_grid():
		return (gmap.get("nodes", {}) as Dictionary).get(pos, {})
	var nodes: Array = map_nodes()
	return nodes[clampi(node_index, 0, nodes.size() - 1)] if not nodes.is_empty() else {}


## 这一场的战斗地图布局 = 节点的障碍物布局 + 卡车现在的摆法(truck_rect / truck_rot / deploy_rect)
func current_layout() -> Dictionary:
	return truck_layout.write_into(_node_layout().duplicate())


func _node_layout() -> Dictionary:
	if is_grid():
		return hunt_layout if hunt_active else (current_node().get("layout", {}) as Dictionary)
	return layouts[clampi(node_index, 0, layouts.size() - 1)] if not layouts.is_empty() else {}


func current_map() -> BattleMap:
	return BattleMap.from_layout(current_layout())


# ------------------------------------------------------------------ 查询
## 这个棋子能不能站到 cell：部署区里没有卡车 / 地形占着的格子都行；能"随心所欲"的(单位数据 deploy_anywhere_star，星级够了)备战时还能站到
## 战场上任何没有地形占着的格子(卡车、断壁残垣、燃烧废墟都不行)
func can_deploy_at(u: Dictionary, cell: Vector2i) -> bool:
	if unit_def(u).deploy_near_enemies:
		return near_enemy_cells().has(cell)
	var m: BattleMap = _deploy_map()
	if m.is_deploy_cell(cell):
		return true
	if not deploys_anywhere(u):
		return false
	return m.in_bounds(cell) and not m.blocks_move(cell)


## 千变万化(幻形节点)能站的格子：这一场每个敌人出生点所在格子周围一圈(8 格)，去掉敌人自己站的格子、地形和卡车；
## 只有备战阶段才知道敌人在哪(其它时候 = 空)
func near_enemy_cells() -> Dictionary:
	var out := {}
	if phase != "prepare":
		return out
	var wave: Array = wave_def().get("units", [])
	if wave.is_empty():
		return out
	var m: BattleMap = _deploy_map()
	var occ := {}
	for p: Vector2 in enemy_positions(m):
		occ[GC.world_to_cell(p)] = true
	for c: Vector2i in occ.keys():
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var n: Vector2i = c + Vector2i(dx, dy)
				if occ.has(n) or not m.in_bounds(n) or m.blocks_move(n):
					continue
				out[n] = true
	return out


## 这一场每个敌人的出生位置(世界坐标)：测试场里摆过的怪用自己摆的位置(遭遇条目的 opt.pos)，其余按方位
func enemy_positions(m: BattleMap = null) -> Array[Vector2]:
	var wave: Array = wave_def().get("units", [])
	var spawn: Array[Vector2] = catalog.wave_positions(wave, m if m != null else current_map())
	for i in range(mini(wave.size(), spawn.size())):
		var e: Array = wave[i]
		if e.size() > 4 and (e[4] as Dictionary).has("pos"):
			spawn[i] = (e[4] as Dictionary)["pos"]
	return spawn


## 这个棋子现在能不能部署到部署区以外(随心所欲：星级够了，并且在备战阶段——要知道这一场的地形)
func deploys_anywhere(u: Dictionary) -> bool:
	var d: UnitDef = unit_def(u)
	return phase == "prepare" and d.deploy_anywhere_star > 0 and int(u["star"]) >= d.deploy_anywhere_star


var _dmap: BattleMap = null
var _dmap_key: String = ""


func _deploy_map() -> BattleMap:
	var key: String = "%s|%s|%d|%s|%d" % [chapter_id, pos, node_index, str(current_layout().get("seed", "")), current_layout().hash()]
	if _dmap == null or key != _dmap_key:
		_dmap = current_map()
		_dmap_key = key
	return _dmap


## 进入备战时：站在这一场不能站的格子上的棋子(上一场随心所欲部署到远处、这一场那里有地形)挪到最近的空部署格，没有空格就收回仓库
func _fix_board_cells() -> void:
	for u: Dictionary in board_units():
		var c: Vector2i = u["cell"]
		if can_deploy_at(u, c):
			continue
		var best := Vector2i(-1, -1)
		var bd := 1.0e9
		var cands: Array = near_enemy_cells().keys() if unit_def(u).deploy_near_enemies else _deploy_map().deploy_cells()
		for dc: Vector2i in cands:
			if unit_at_cell(dc).is_empty():
				var dd: float = Vector2(dc - c).length()
				if dd < bd:
					bd = dd
					best = dc
		if best.x >= 0:
			u["cell"] = best
		else:
			u["cell"] = null
			u["bench"] = free_bench_slot()


# ------------------------------------------------------------------ 卡车摆法(开局改装 truck_zone / truck_free 才能动)
## 备战时能不能挪卡车(测试场的沙盒 Run 没有改装：不能)
func truck_can_move() -> bool:
	return truck_layout.can_move() and phase == "prepare"


## 把卡车(左上角格子)挪到 pos：会被夹进初始部署区；truck_zone 的部署区和上面的棋子一起平移，truck_free 被压住的棋子挪开
func move_truck(pos: Vector2i) -> Dictionary:
	if not truck_layout.can_move():
		return _fail("ui.err.truck_fixed")
	if phase != "prepare":
		return _fail("ui.err.not_now")
	return _apply_truck_layout(truck_layout.moved_to(pos))


## 卡车顺时针转 steps 个 90°(负数 = 逆时针)
func rotate_truck(steps: int = 1) -> Dictionary:
	if not truck_layout.can_move():
		return _fail("ui.err.truck_fixed")
	if phase != "prepare":
		return _fail("ui.err.not_now")
	return _apply_truck_layout(truck_layout.rotated(steps))


func _apply_truck_layout(nl: TruckLayout) -> Dictionary:
	if nl.equals(truck_layout):
		return _ok()
	var old: TruckLayout = truck_layout
	for u: Dictionary in board_units():
		var c: Vector2i = u["cell"]
		if not unit_def(u).deploy_near_enemies and old.deploy.has_point(c):
			u["cell"] = old.map_cell(c, nl)
	truck_layout = nl
	_dmap = null
	_fix_board_cells()
	_changed("truck")
	return _ok()


## 占上阵人数的场上棋子数(不占人数的棋子——空白节点——不算)
func board_count() -> int:
	var n := 0
	for u: Dictionary in board_units():
		if not unit_def(u).free_deploy:
			n += 1
	return n


func board_capacity() -> int:
	return 99 if sandbox else level


func board_units() -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for id: String in roster.keys():
		if roster[id]["cell"] != null:
			r.append(roster[id])
	return r


## 备战时计入羁绊人数的棋子：场上的 + 仓库里"在仓库里也算羁绊"的(星旅节点·渡星而来)
func trait_defs() -> Array:
	var defs: Array = []
	for u: Dictionary in board_units():
		defs.append(unit_def(u))
	for ub: Dictionary in bench_units():
		if unit_def(ub).bench_traits:
			defs.append(unit_def(ub))
	return defs


## 仓库里的节点(按仓库顺序)。仓库没有容量上限
func bench_units() -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for id: String in roster.keys():
		if roster[id]["cell"] == null:
			r.append(roster[id])
	r.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["bench"]) < int(b["bench"]))
	return r


func unit_at_cell(cell: Vector2i) -> Dictionary:
	for id: String in roster.keys():
		if roster[id]["cell"] != null and roster[id]["cell"] == cell:
			return roster[id]
	return {}


func unit_at_bench(idx: int) -> Dictionary:
	for id: String in roster.keys():
		if roster[id]["cell"] == null and int(roster[id]["bench"]) == idx:
			return roster[id]
	return {}


## 仓库末尾的下一个位置(仓库无上限，总是有位置)
func free_bench_slot() -> int:
	var n := 0
	for id: String in roster.keys():
		if roster[id]["cell"] == null:
			n = maxi(n, int(roster[id]["bench"]) + 1)
	return n


## 仓库顺序重新编号为 0..n-1(收进/取出/合星之后保持紧凑)
func _compact_bench() -> void:
	var list: Array[Dictionary] = bench_units()
	for i in range(list.size()):
		list[i]["bench"] = i


func unit_def(u: Dictionary) -> UnitDef:
	var d: UnitDef = catalog.get_unit(str(u["def"]))
	return d.form_def(str(u.get("form", ""))) if d != null else null


## 该棋子手里实际的武器(装备的武器，否则基础武器)
func weapon_of(u: Dictionary) -> EquipmentDef:
	return catalog.resolve_weapon(unit_def(u), str(u.get("weapon", "")))


## 节点(花名册里的一个)拿着现在的武器时的攻击力(星级、武器加成、永恒成长都算)
func unit_attack(u: Dictionary) -> float:
	var bu := BUnit.new()
	bu.setup(unit_def(u), GC.TEAM_PLAYER, int(u["star"]), "probe")
	bu.set_weapon(weapon_of(u))
	bu.perm_flat = (u.get("perm", {}) as Dictionary).duplicate()
	bu.mark_dirty()
	return bu.get_stats().attack_power


func next_level_xp() -> int:
	return int((shop_rule.get("level_xp", {}) as Dictionary).get(str(level + 1), 0))


func max_level() -> int:
	return int(shop_rule.get("max_level", 6))


func interest() -> int:
	var per: int = int(shop_rule.get("interest_per", 10))
	return mini(int(shop_rule.get("max_interest", 3)), gold / per)


func total_nodes() -> int:
	if is_grid():
		return (gmap.get("nodes", {}) as Dictionary).size()
	return map_nodes().size()


func _ok() -> Dictionary:
	return {"ok": true, "reason": ""}


func _fail(key: String) -> Dictionary:
	return {"ok": false, "reason": key}


func _changed(reason: String) -> void:
	_compact_bench()
	_sync_prep_items()
	changed.emit(reason)


## 场上棋子带来的特殊物品(单位数据 prep_items，例如狩胜节点 → 狩猎旗标)：有人在场上就放进武器库(同一件只放一个，几个狩胜节点共用)，
## 都下场了就收走(连同它做的标记)
func _sync_prep_items() -> void:
	var want: Array[String] = []
	for u: Dictionary in board_units():
		for it: String in unit_def(u).prep_items:
			if not want.has(it) and catalog.get_equipment(it) != null:
				want.append(it)
	for it2: String in want:
		if not inventory.has(it2):
			inventory.append(it2)
	for i in range(inventory.size() - 1, -1, -1):
		var e: EquipmentDef = catalog.get_equipment(inventory[i])
		if e != null and e.slot == "token" and not want.has(inventory[i]):
			inventory.remove_at(i)
	if not has_token("hunt_mark"):
		hunt_mark = -1


## 武器库里有没有某种用途的特殊物品
func has_token(kind: String) -> bool:
	for id: String in inventory:
		var e: EquipmentDef = catalog.get_equipment(id)
		if e != null and e.slot == "token" and e.token == kind:
			return true
	return false


## 狩猎旗标：拖到敌人(备战时的敌方预览)身上 → 这个敌人成为狩胜节点开战时的狩猎对象；旗标用完回到武器库(再拖一次 = 换人)
func set_hunt_mark(enemy_index: int) -> Dictionary:
	if phase != "prepare":
		return _fail("ui.err.not_now")
	if not has_token("hunt_mark"):
		return _fail("ui.err.bad_target")
	var wave: Array = wave_def().get("units", [])
	if enemy_index < 0 or enemy_index >= wave.size():
		return _fail("ui.err.bad_target")
	hunt_mark = enemy_index
	_changed("mark")
	return _ok()


# ------------------------------------------------------------------ 单位
func add_unit(def_id: String, star: int, cell: Variant, bench_idx: int) -> Dictionary:
	var id := "r%d" % _next_id
	_next_id += 1
	var u := {"id": id, "def": def_id, "star": star, "weapon": "", "perm": {}, "cell": cell, "bench": bench_idx}
	roster[id] = u
	if cell == null:
		_stored(u)
	return u


# ------------------------------------------------------------------ 测试场(sandbox)：直接改阵容，不走商店 / 合星 / 背包
## 加一个棋子到仓库(任意星级)
func sandbox_add(def_id: String, star: int) -> Dictionary:
	var u: Dictionary = add_unit(def_id, clampi(star, 1, GC.MAX_STAR), null, free_bench_slot())
	_changed("sandbox")
	return u


func sandbox_set_star(id: String, star: int) -> void:
	if roster.has(id):
		roster[id]["star"] = clampi(star, 1, GC.MAX_STAR)
		# 星级变了，装不了的武器换回基础武器(比如灾星节点 2 星才能装的红色武器)
		var w: String = str(roster[id]["weapon"])
		if w != "" and catalog.get_equipment(w).equip_problem(unit_def(roster[id]), int(roster[id]["star"])) != "":
			roster[id]["weapon"] = ""
		_changed("sandbox")


## 换武器(任意一把能装的；"" = 基础武器)，不经过背包
func sandbox_set_weapon(id: String, equip_id: String) -> Dictionary:
	if not roster.has(id):
		return _fail("ui.err.bad_target")
	if equip_id != "":
		var chk: Dictionary = equip_check(id, equip_id)
		if not chk["ok"]:
			return chk
	roster[id]["weapon"] = equip_id
	_changed("sandbox")
	return _ok()


func sandbox_remove(id: String) -> void:
	if roster.erase(id):
		_changed("sandbox")


## 记下进仓库的先后
func _stored(u: Dictionary) -> void:
	u["stored_at"] = _store_seq
	_store_seq += 1


func cost_of_unit(u: Dictionary) -> int:
	return unit_def(u).cost


func sell_value(u: Dictionary) -> int:
	var c: int = cost_of_unit(u)
	var star: int = int(u["star"])
	return maxi(0, c * int(pow(3.0, star - 1)) - (1 if star > 1 else 0))


func sell(id: String) -> Dictionary:
	if not _can_manage() or not roster.has(id):
		return _fail("ui.err.not_now")
	var u: Dictionary = roster[id]
	gold += sell_value(u)
	if str(u["weapon"]) != "":
		inventory.append(str(u["weapon"]))       # 基础武器不会进背包
	roster.erase(id)
	_changed("sell")
	return _ok()


## 拖动：目标 {"cell":Vector2i} 或 {"bench":int}。目标被占用则互换。
## 地图上与备战时都能管理阵容/背包/商店(战斗中不行)
func _can_manage() -> bool:
	return phase == "prepare" or phase == "map" or phase == "loot" or phase == "rest" or phase == "shop" or phase == "event"


func move_unit(id: String, target: Dictionary) -> Dictionary:
	if not _can_manage() or not roster.has(id):
		return _fail("ui.err.not_now")
	var u: Dictionary = roster[id]
	var other: Dictionary = {}
	if target.has("cell"):
		var cell: Vector2i = target["cell"]
		if not can_deploy_at(u, cell):
			return _fail("ui.err.near_enemies" if unit_def(u).deploy_near_enemies else "ui.err.bad_cell")
		other = unit_at_cell(cell)
		# 交换位置：被换过去的那个也得能站到这里原来的格子(千变万化只能站敌人身边、别人站不了敌人身边)
		if not other.is_empty() and other["id"] != id and u["cell"] != null and not can_deploy_at(other, u["cell"] as Vector2i):
			return _fail("ui.err.bad_cell")
		# 唯一的节点(真望节点)：场上已经有一个同名的(而且不是和它换位置)就不行
		if unit_def(u).unique and u["cell"] == null:
			for bu: Dictionary in board_units():
				if bu["id"] != id and bu["def"] == u["def"] and (other.is_empty() or other["id"] != bu["id"]):
					return _fail("ui.err.unique")
		# 上场人数限制：从仓库上场且目标为空
		if u["cell"] == null and other.is_empty() and not unit_def(u).free_deploy and board_count() >= board_capacity():
			return _fail("ui.err.board_full")
		if not other.is_empty() and other["id"] == id:
			return _ok()
		var old_cell: Variant = u["cell"]
		var old_bench: int = int(u["bench"])
		u["cell"] = cell
		u["bench"] = -1
		if not other.is_empty():
			other["cell"] = old_cell
			other["bench"] = old_bench
			if old_cell == null:
				_stored(other)
	else:
		var idx: int = int(target["bench"])
		if idx < 0:
			return _fail("ui.err.bad_cell")
		other = unit_at_bench(idx)
		if not other.is_empty() and other["id"] == id:
			return _ok()
		var oc: Variant = u["cell"]
		var ob: int = int(u["bench"])
		u["cell"] = null
		u["bench"] = idx
		if oc != null:
			_stored(u)
		if not other.is_empty():
			other["cell"] = oc
			other["bench"] = ob
	_changed("move")
	return _ok()


# ------------------------------------------------------------------ 装备(武器)
## 能否把背包里的武器给这个棋子：武器大类要在棋子允许的范围内，颜色要兼容
func equip_check(id: String, equip_id: String) -> Dictionary:
	var u: Dictionary = roster.get(id, {})
	var e: EquipmentDef = catalog.get_equipment(equip_id)
	if u.is_empty() or e == null:
		return _fail("ui.err.bad_target")
	var why: String = e.equip_problem(unit_def(u), int(u["star"]))
	if why != "":
		return _fail(why)
	return _ok()


## 装备武器：替换棋子当前的武器。原来装备的武器回到背包；基础武器不会进背包(卸下新武器时自动拿回)
func equip(id: String, equip_id: String) -> Dictionary:
	if not _can_manage():
		return _fail("ui.err.not_now")
	var chk: Dictionary = equip_check(id, equip_id)
	if not chk["ok"]:
		return chk
	var idx: int = inventory.find(equip_id)
	if idx < 0 and not sandbox:                      # 测试场：武器随便拿，不经过背包
		return _fail("ui.err.bad_target")
	var u: Dictionary = roster[id]
	if idx >= 0:
		inventory.remove_at(idx)
	var old: String = str(u["weapon"])
	u["weapon"] = equip_id
	if old != "" and not sandbox:
		inventory.append(old)
	_changed("equip")
	return _ok()


## 把一个棋子手上的武器直接交给另一个棋子(从详情卡里拖过去)：原主换回基础武器；接手的棋子原来的武器回背包。
## 接手的棋子用不了这把武器时什么都不变
func move_weapon(from_id: String, to_id: String) -> Dictionary:
	if not _can_manage() or not roster.has(from_id) or not roster.has(to_id):
		return _fail("ui.err.not_now")
	var eid: String = str(roster[from_id]["weapon"])
	if eid == "":
		return _fail("ui.err.base_weapon")
	if from_id == to_id:
		return _ok()
	var chk: Dictionary = equip_check(to_id, eid)
	if not chk["ok"]:
		return chk
	roster[from_id]["weapon"] = ""
	if not sandbox:
		inventory.append(eid)
	var res: Dictionary = equip(to_id, eid)
	if not res["ok"]:
		inventory.erase(eid)
		roster[from_id]["weapon"] = eid
		_changed("equip")
	return res


## 卸下武器：武器回背包，棋子重新拿起自己的基础武器
func unequip(id: String) -> Dictionary:
	if not _can_manage() or not roster.has(id):
		return _fail("ui.err.not_now")
	var u: Dictionary = roster[id]
	var e: String = str(u["weapon"])
	if e == "":
		return _fail("ui.err.base_weapon")
	u["weapon"] = ""
	if not sandbox:
		inventory.append(e)
	_changed("unequip")
	return _ok()


# ------------------------------------------------------------------ 商店 / 经济
func roll_shop(paid: bool) -> Dictionary:
	if paid:
		var cost: int = int(shop_rule.get("refresh_cost", 2))
		if gold < cost:
			return _fail("ui.err.no_gold")
		gold -= cost
	shop.clear()
	var odds_lv: int = clampi(level + int(flag_value("shop_odds_shift")), 1, max_level())
	var odds: Dictionary = (shop_rule.get("odds_by_level", {}) as Dictionary).get(str(odds_lv), {"1": 100})
	var ids: Array[String] = catalog.shop_unit_ids()
	for i in range(int(shop_rule.get("shop_size", 5))):
		var c: int = _roll_cost(odds)
		var pool: Array[String] = []
		for id: String in ids:
			if catalog.get_unit(id).cost == c:
				pool.append(id)
		if pool.is_empty():
			pool = ids
		shop.append({"def": pool[rng.randi() % pool.size()], "sold": false})
	_changed("shop")
	return _ok()


func _roll_cost(odds: Dictionary) -> int:
	var total := 0.0
	for k: String in odds.keys():
		total += float(odds[k])
	var roll: float = rng.randf() * total
	for k2: String in odds.keys():
		roll -= float(odds[k2])
		if roll <= 0.0:
			return int(k2)
	return 1


func toggle_lock() -> void:
	shop_locked = not shop_locked
	_changed("lock")


func buy(index: int) -> Dictionary:
	if not _can_manage() or index < 0 or index >= shop.size():
		return _fail("ui.err.not_now")
	var offer: Dictionary = shop[index]
	if offer["sold"]:
		return _fail("ui.err.sold")
	var def: UnitDef = catalog.get_unit(str(offer["def"]))
	if gold < def.cost:
		return _fail("ui.err.no_gold")
	gold -= def.cost
	offer["sold"] = true
	add_unit(def.id, 1, null, free_bench_slot())
	_merge_all()
	_changed("buy")
	return _ok()


func _would_merge(def_id: String) -> bool:
	var n := 0
	for id: String in roster.keys():
		if roster[id]["def"] == def_id and int(roster[id]["star"]) == 1:
			n += 1
	return n >= 2


func buy_xp() -> Dictionary:
	if level >= max_level():
		return _fail("ui.err.max_level")
	var cost: int = int(shop_rule.get("buy_xp_cost", 4))
	if gold < cost:
		return _fail("ui.err.no_gold")
	gold -= cost
	add_xp(int(shop_rule.get("xp_per_purchase", 4)))
	_changed("xp")
	return _ok()


func add_xp(amount: int) -> void:
	xp += amount
	while level < max_level() and xp >= next_level_xp() and next_level_xp() > 0:
		xp -= next_level_xp()
		level += 1
	if level >= max_level():
		xp = 0


# ------------------------------------------------------------------ 合星(3 合 1)
func _merge_all() -> void:
	var again := true
	while again:
		again = false
		var groups: Dictionary = {}
		for id: String in roster.keys():
			var u: Dictionary = roster[id]
			if int(u["star"]) >= GC.MAX_STAR:
				continue
			var key := "%s|%d" % [u["def"], int(u["star"])]
			if not groups.has(key):
				groups[key] = []
			(groups[key] as Array).append(id)
		for key: String in groups.keys():
			var ids: Array = groups[key]
			if ids.size() >= 3:
				# 保留优先：上场的 > 仓库里的；其次装备多的
				ids.sort_custom(func(a: String, b: String) -> bool:
					var ua: Dictionary = roster[a]
					var ub: Dictionary = roster[b]
					var sa: int = (2 if ua["cell"] != null else 0) + _equip_count(ua)
					var sb: int = (2 if ub["cell"] != null else 0) + _equip_count(ub)
					return sa > sb)
				var keep: Dictionary = roster[ids[0]]
				for i in [1, 2]:
					var gone: Dictionary = roster[ids[i]]
					if str(gone["weapon"]) != "":
						inventory.append(str(gone["weapon"]))
					for st: String in (gone["perm"] as Dictionary).keys():
						keep["perm"][st] = maxf(float(keep["perm"].get(st, 0.0)), float(gone["perm"][st]))
					keep["eternal"] = merge_eternal(keep.get("eternal", []), gone.get("eternal", []))
					var kl: Dictionary = keep.get_or_add("learning", {})
					for lk2: Variant in (gone.get("learning", {}) as Dictionary).keys():
						kl[lk2] = maxi(int(kl.get(lk2, 0)), int(gone["learning"][lk2]))
					roster.erase(ids[i])
				keep["star"] = int(keep["star"]) + 1
				# 升星后装备规则可能变了(例如 2 星起不能装[双模])：装不了的武器回背包
				if str(keep["weapon"]) != "":
					var kw: EquipmentDef = catalog.get_equipment(str(keep["weapon"]))
					if kw != null and kw.equip_problem(unit_def(keep), int(keep["star"])) != "":
						inventory.append(str(keep["weapon"]))
						keep["weapon"] = ""
				if keep["cell"] == null and int(keep["bench"]) < 0:
					keep["bench"] = free_bench_slot()
				again = true
				_changed("merge")
				break
	# 清理虚拟槽位
	for id2: String in roster.keys():
		var u2: Dictionary = roster[id2]
		if u2["cell"] == null and int(u2["bench"]) < 0:
			u2["bench"] = free_bench_slot()


func _equip_count(u: Dictionary) -> int:
	return 1 if str(u["weapon"]) != "" else 0


# ------------------------------------------------------------------ 地图 / 战斗
## 开着卡车前往下一个地图节点：收入 + 利息、经验、商店免费刷新(除非锁定)
func travel() -> Dictionary:
	if phase != "map" or is_grid():
		return _fail("ui.err.not_now")
	var nd: Dictionary = current_node()
	var inc: int = int(nd.get("income", 0))
	var itr: int = interest() if node_index > 0 else 0
	gold += inc + itr
	if node_index > 0:
		add_xp(int(shop_rule.get("xp_per_node", 2)))
	last_result = {"income": inc, "interest": itr}
	if not shop_locked:
		roll_shop(false)
	shop_locked = false
	phase = "prepare"
	_fix_board_cells()
	hunt_mark = -1
	_changed("travel")
	return _ok()


func wave_def() -> Dictionary:
	if hunt_active:
		return hunt_enc
	return (current_node().get("encounter", {}) as Dictionary)


func can_start_battle() -> Dictionary:
	if phase != "prepare":
		return _fail("ui.err.not_now")
	if board_units().is_empty():
		return _fail("ui.err.empty_board")
	return _ok()


## 升星合并时的永恒状态：同一种状态取层数多的那份
static func merge_eternal(a: Variant, b2: Variant) -> Array:
	var by: Dictionary = {}
	for src: Variant in [a, b2]:
		for es: Variant in (src as Array if src is Array else []):
			var d: Dictionary = es
			var id: String = str(d.get("id", ""))
			if not by.has(id) or int(d.get("stacks", 0)) > int((by[id] as Dictionary).get("stacks", 0)):
				by[id] = d.duplicate(true)
	return by.values()


## 真骰(巧运节点 2 星)：花名册里(场上 / 仓库都算)有这个被动生效的棋子 → 它的配置(event_rarity_mult)；没有 = {}
func luck_cfg() -> Dictionary:
	for rid: String in roster.keys():
		var u: Dictionary = roster[rid]
		var d: UnitDef = unit_def(u)
		if d == null:
			continue
		for pa: AbilityDef in d.passives:
			if pa.effect_type == "true_dice" and pa.unlock_star <= int(u.get("star", 1)):
				return pa.effect_config
	return {}


## 诅咒的武器(杀：cfg.curse_at)：携带者这件武器的学习计数累计达到 curse_at → 永久降低一星(计数减掉 curse_at，可以连着降)；
## 已经是一星 → 移除携带者，武器回到武器库。返回 [{id, def, weapon, star(降到几星；0 = 被移除)}]
func _settle_curses() -> Array:
	var out: Array = []
	for rid: String in roster.keys():
		var u: Dictionary = roster[rid]
		var wid: String = str(u.get("weapon", ""))
		var we: EquipmentDef = catalog.get_equipment(wid) if wid != "" else null
		if we == null:
			continue
		for ab: AbilityDef in we.abilities:
			var at: int = int(ab.effect_config.get("curse_at", 0))
			if at <= 0:
				continue
			var lr: Dictionary = u.get_or_add("learning", {})
			while int(lr.get(ab.id, 0)) >= at and roster.has(rid):
				lr[ab.id] = int(lr[ab.id]) - at
				if int(u["star"]) > 1:
					u["star"] = int(u["star"]) - 1
					out.append({"id": rid, "def": str(u["def"]), "weapon": wid, "star": int(u["star"])})
				else:
					inventory.append(wid)
					roster.erase(rid)
					out.append({"id": rid, "def": str(u["def"]), "weapon": wid, "star": 0})
	if not out.is_empty():
		_compact_bench()
	return out


## 无我(无我节点)：带着这个被动的单位类型(被动效果 selfless_purge)
func _has_selfless(d: UnitDef) -> bool:
	if d == null:
		return false
	for pa: AbilityDef in d.passives:
		if pa.effect_type == "selfless_purge" and pa.unlock_star <= 1:
			return true
	return false


## 备战时哪些棋子身上显示无我的按钮：场上的无我节点，而且仓库里还有别的同种棋子(或者她已经点过了：按钮显示"就绪")。返回 {roster_id: 已就绪?}
func selfless_buttons() -> Dictionary:
	var out := {}
	if phase != "prepare":
		return out
	for rid: String in roster.keys():
		var u: Dictionary = roster[rid]
		if u["cell"] == null or not _has_selfless(unit_def(u)):
			continue
		if bool(u.get("selfless", false)):
			out[rid] = true
		elif not _selfless_fodder(rid).is_empty():
			out[rid] = false
	return out


## 仓库里可以被无我移除的同种棋子(星级最低的；同星级取后放进仓库的)；没有 = ""
func _selfless_fodder(rid: String) -> String:
	var def_id: String = str(roster[rid]["def"])
	var best := ""
	for oid: String in roster.keys():
		var o: Dictionary = roster[oid]
		if oid == rid or o["cell"] != null or str(o["def"]) != def_id:
			continue
		if best == "" or int(o["star"]) < int(roster[best]["star"]) or (int(o["star"]) == int(roster[best]["star"])
				and int(o.get("stored_at", 0)) > int(roster[best].get("stored_at", 0))):
			best = oid
	return best


## 点无我的按钮：移除仓库里一个同种棋子(星级最低的；它的武器回到武器库)，下一场战斗开始时她清场(Battle：无我节点·无我的触发器)
func selfless(rid: String) -> Dictionary:
	if phase != "prepare":
		return _fail("ui.err.not_now")
	if not roster.has(rid) or roster[rid]["cell"] == null or not _has_selfless(unit_def(roster[rid])):
		return _fail("ui.err.bad_target")
	if bool(roster[rid].get("selfless", false)):
		return _fail("ui.err.selfless_ready")
	var fodder: String = _selfless_fodder(rid)
	if fodder == "":
		return _fail("ui.err.selfless_none")
	if str(roster[fodder]["weapon"]) != "":
		inventory.append(str(roster[fodder]["weapon"]))
	roster.erase(fodder)
	roster[rid]["selfless"] = true
	_changed("selfless")
	return _ok()


## 表里之间(变奏节点)：备战时场上有形态的棋子 → 头顶一个切换形态的按钮：roster_id -> 当前形态
func form_buttons() -> Dictionary:
	var out := {}
	if phase != "prepare":
		return out
	for rid: String in roster.keys():
		var u: Dictionary = roster[rid]
		var d: UnitDef = unit_def(u)
		if u["cell"] == null or d == null or d.forms.is_empty():
			continue
		out[rid] = d.form
	return out


## 切换形态(战斗外随时可以切；部门、被动 2 跟着变，羁绊立刻重算)
func toggle_form(rid: String) -> Dictionary:
	if phase != "prepare" and phase != "map":
		return _fail("ui.err.not_now")
	if not roster.has(rid):
		return _fail("ui.err.bad_target")
	var d: UnitDef = unit_def(roster[rid])
	if d == null or d.forms.is_empty():
		return _fail("ui.err.bad_target")
	roster[rid]["form"] = d.other_form()
	_changed("form")
	return _ok()


## 生成战斗配置：我方 = 部署区里的棋子；敌方 = 当前节点的遭遇(从四周方位出现)；地图 = 本节点的障碍物布局
func build_battle_setup() -> Dictionary:
	var units: Array = []
	for u: Dictionary in board_units():
		units.append({"def": u["def"], "team": 0, "star": u["star"], "cell": u["cell"],
			"weapon": str(u["weapon"]), "roster_id": u["id"], "perm": (u["perm"] as Dictionary).duplicate(),
			"eternal": (u.get("eternal", []) as Array).duplicate(true), "learning": (u.get("learning", {}) as Dictionary).duplicate(),
			"selfless": bool(u.get("selfless", false)), "form": str(u.get("form", ""))})
	var wave: Array = wave_def().get("units", [])
	var spawn: Array[Vector2] = enemy_positions()
	for i in range(wave.size()):
		var e: Array = wave[i]
		var opt: Dictionary = e[4] if e.size() > 4 else {}
		var entry := {"def": e[0], "team": 1, "star": e[1], "pos": spawn[i], "weapon": Catalog.wave_weapon_id(e)}
		if opt.has("orb"):
			entry["orb"] = str(opt["orb"])
		if bool(opt.get("boss", false)):
			entry["boss"] = true
		if bool(opt.get("elite", false)):
			entry["elite"] = true
		if i == hunt_mark and has_token("hunt_mark"):
			entry["hunt_marked_by"] = GC.TEAM_PLAYER
		if opt.has("hp_mult"):
			entry["hp_mult"] = float(opt["hp_mult"])
		if opt.has("atk_mult"):
			entry["atk_mult"] = float(opt["atk_mult"])
		units.append(entry)
	# 星旅节点·渡星而来：场上没有她、仓库里有 → 开战时从仓库坠落到敌人最密集的地方(落点 = 备战时显示的预计落点)
	var sf: Dictionary = starfall_preview()
	if not sf.is_empty():
		var su: Dictionary = sf["unit"]
		units.append({"def": su["def"], "team": 0, "star": su["star"], "pos": sf["pos"], "drop": true,
			"weapon": str(su["weapon"]), "roster_id": su["id"], "perm": (su["perm"] as Dictionary).duplicate(),
			"eternal": (su.get("eternal", []) as Array).duplicate(true)})
	return {"units": units, "map": current_layout(),
		"cfg": {"potion_variance": true, "truck_blocks_ally_los": not truck_mods.has("one_way_cover"), "mods": truck_mods.duplicate(),
			"chapter_color": str(chapter.get("color", "white"))}}


## 战斗开始时会从仓库坠落的星旅节点：场上已经有一个就不坠落；仓库里有好几个时只坠落一个——
## 装着非基础武器的 > 星级高的 > 最先进入仓库的。没有 = {}
func starfall_unit() -> Dictionary:
	for u: Dictionary in board_units():
		if unit_def(u).bench_drop:
			return {}
	var best: Dictionary = {}
	for u2: Dictionary in bench_units():
		if not unit_def(u2).bench_drop:
			continue
		if best.is_empty() or _drop_first(u2, best):
			best = u2
	return best


func _drop_first(a: Dictionary, b: Dictionary) -> bool:
	var wa: bool = str(a["weapon"]) != ""
	var wb: bool = str(b["weapon"]) != ""
	if wa != wb:
		return wa
	if int(a["star"]) != int(b["star"]):
		return int(a["star"]) > int(b["star"])
	return int(a.get("stored_at", 0)) < int(b.get("stored_at", 0))


## 预计落点：{unit, pos, radius}(敌人还在出生点时，坠落范围里能罩住最多敌人的地方；和开战时的真实落点是同一个算法)；没有要坠落的 = {}
func starfall_preview() -> Dictionary:
	var su: Dictionary = starfall_unit()
	if su.is_empty():
		return {}
	var d: UnitDef = unit_def(su)
	var wave: Array = wave_def().get("units", [])
	if wave.is_empty():
		return {}
	var spawn: Array[Vector2] = enemy_positions()
	var rad: float = d.passive_splash_radius(int(su["star"]))
	return {"unit": su, "pos": Targeting.densest_point(spawn, rad, current_map(), d.radius), "radius": rad}


func begin_battle() -> void:
	phase = "battle"
	_changed("battle")


## 战斗结束：永恒成长回写；失败时卡车耐久受损；被击杀的敌人掉落的晶球进入待领取
func finish_battle(b: Battle) -> Dictionary:
	var win: bool = b.winner == GC.TEAM_PLAYER
	hunt_mark = -1
	_expire_flags("next_battle")
	for rid: String in b.growth.keys():
		if roster.has(rid):
			for st: String in (b.growth[rid] as Dictionary).keys():
				var perm: Dictionary = roster[rid]["perm"]
				perm[st] = float(perm.get(st, 0.0)) + float((b.growth[rid] as Dictionary)[st])
	# 永恒状态(共歌节点的沉醉)：参战的棋子身上的永恒状态原样写回花名册，下一场开战时挂回去
	for rid2: String in b.eternal_out.keys():
		if roster.has(rid2):
			roster[rid2]["eternal"] = (b.eternal_out[rid2] as Array).duplicate(true)
	# 【永恒】【学习】：学习计数写回(记在棋子身上；没参战 / 没带这件武器的计数保留)
	for rid3: String in b.learning_out.keys():
		if roster.has(rid3):
			var lr: Dictionary = roster[rid3].get_or_add("learning", {})
			for lk: String in (b.learning_out[rid3] as Dictionary).keys():
				lr[lk] = int(b.learning_out[rid3][lk])
	var curses: Array = _settle_curses()
	# 无我：点过按钮的那一场打完了(没上场也算用掉)
	for rid4: String in roster.keys():
		roster[rid4].erase("selfless")
	var gold_from_units: int = int(b.gold_gain.get(GC.TEAM_PLAYER, 0))
	gold += gold_from_units
	var xp_from_units: int = int(b.xp_gain.get(GC.TEAM_PLAYER, 0))
	if xp_from_units > 0:
		add_xp(xp_from_units)
	var dmg := 0
	if not win and b.winner != 2 and b.truck_damage > 0:
		dmg = b.truck_damage + int(chapter.get("truck_damage_base", 0))
	truck_hp = maxi(0, truck_hp - dmg)
	pending_orbs.clear()
	for d: Dictionary in b.drops:
		pending_orbs.append({"tier": str(d["tier"]), "pos": d["pos"], "opened": false, "loot": {}})
	last_result = {"win": win, "node": node_index, "gold_units": gold_from_units, "xp_units": xp_from_units, "truck_damage": dmg,
		"orbs": pending_orbs.size(), "draw": b.winner == 2, "kind": battle_kind(), "curses": curses}
	if truck_hp <= 0:
		phase = "over"
		won_run = false
	else:
		phase = "loot"
	_changed("result")
	return last_result


# ------------------------------------------------------------------ 晶球(战利品)
## 打开第 i 个晶球：按掉落表随机，结果立刻入账。返回 {gold, units:[def ids], weapons:[ids]}
func open_orb(i: int) -> Dictionary:
	if i < 0 or i >= pending_orbs.size() or bool(pending_orbs[i]["opened"]):
		return {}
	var orb: Dictionary = pending_orbs[i]
	var loot: Dictionary = _grant_orb(str(orb["tier"]))
	orb["opened"] = true
	orb["loot"] = loot
	_changed("orb")
	return loot


## 开一个晶球(晶球表 + 本章的保底 + 附带的车间材料)，东西直接进仓库 / 武器库；返回开出了什么
func _grant_orb(tier: String) -> Dictionary:
	var entry: Dictionary = _roll_loot_entry(tier)
	var loot := {"gold": 0, "units": [], "weapons": [], "tier": tier, "materials": {}}
	if entry.has("gold"):
		loot["gold"] = int(entry["gold"])
		gold += int(entry["gold"])
	if entry.has("unit_cost"):
		var uid: String = _random_unit_of_cost(int(entry["unit_cost"]))
		if uid != "":
			add_unit(uid, 1, null, free_bench_slot())
			_merge_all()
			(loot["units"] as Array).append(uid)
			loot_counts["unit"] = int(loot_counts["unit"]) + 1
	if entry.has("weapon_max_cost"):
		var wid: String = _random_weapon(int(entry["weapon_max_cost"]))
		if wid != "":
			inventory.append(wid)
			(loot["weapons"] as Array).append(wid)
			loot_counts["weapon"] = int(loot_counts["weapon"]) + 1
	# 每个晶球还附带几份车间材料(颜色按章节的 material_weights)
	var mg: Dictionary = Crafting.roll_orb_materials(catalog, tier, chapter.get("material_weights", {}), rng)
	add_materials(mg)
	loot["materials"] = mg
	return loot


## 武器库里的武器(不含特殊物品)：[下标]
func spare_weapons() -> Array[int]:
	var r: Array[int] = []
	for i in range(inventory.size()):
		var e: EquipmentDef = catalog.get_equipment(inventory[i])
		if e != null and e.is_gear():
			r.append(i)
	return r


# ------------------------------------------------------------------ 局内状态(事件给的诅咒 / 祝福)
func flag_value(id: String) -> float:
	return float((flags.get(id, {}) as Dictionary).get("value", 0.0))


## 同一个状态再给一次 = 数值叠加，期限取新的
func set_flag(id: String, value: float, until: String) -> void:
	var cur: Dictionary = flags.get(id, {})
	flags[id] = {"value": float(cur.get("value", 0.0)) + value, "until": until}


func _expire_flags(when: String) -> void:
	for id: String in flags.keys().duplicate():
		if str((flags[id] as Dictionary).get("until", "")) == when:
			flags.erase(id)


# ------------------------------------------------------------------ 车间(装备制造 / 分解)
func add_materials(d: Dictionary) -> void:
	for m: String in Crafting.MATS:
		materials[m] = int(materials.get(m, 0)) + int(d.get(m, 0))


func material_total() -> int:
	return Crafting.total(materials)


## 制造：kind = 装备种类(现在只有 weapon)，cats = 选中的门类(至少 min_categories 个)，mats = 投入的材料 {red, green, blue}。
## 成功时扣材料、成品放进武器库，返回 {ok, id}
func craft(kind: String, cats: Array, mats: Dictionary) -> Dictionary:
	if not _can_manage():
		return _fail("ui.err.not_now")
	var why: String = Crafting.problem(catalog, kind, cats, mats, materials)
	if why != "":
		return _fail(why)
	var id: String = Crafting.roll(catalog, kind, cats, mats, rng)
	if id == "":
		return _fail("ui.err.craft_nothing")
	for m: String in Crafting.MATS:
		materials[m] = int(materials[m]) - int(mats.get(m, 0))
	inventory.append(id)
	crafted += 1
	remember_craft(kind, cats, mats)
	_changed("craft")
	var r: Dictionary = _ok()
	r["id"] = id
	return r


## 按阵容推荐的门类：花名册里的节点能用的武器大类，按"多少人能用(基础武器大类算 2)"排序，至少凑够下限
func craft_team_categories(kind: String) -> Array:
	var valid: Array = Crafting.kind_cfg(catalog, kind).get("categories", [])
	var score: Dictionary = {}
	for u: Dictionary in roster.values():
		var d: UnitDef = unit_def(u)
		if d == null:
			continue
		for cid: Variant in valid:
			if d.can_use_weapon_class(str(cid)) and not d.weapon_classes.is_empty():
				score[cid] = int(score.get(cid, 0)) + (2 if str(cid) == d.base_weapon_class else 1)
	var order: Array = valid.duplicate()
	order.sort_custom(func(a: Variant, b: Variant) -> bool:
		return int(score.get(a, 0)) > int(score.get(b, 0)) if int(score.get(a, 0)) != int(score.get(b, 0)) else valid.find(a) < valid.find(b))
	var r: Array = []
	for cid2: Variant in order:
		if int(score.get(cid2, 0)) > 0:
			r.append(cid2)
	var need: int = Crafting.min_categories(catalog, kind)
	for cid3: Variant in order:
		if r.size() >= need:
			break
		if not r.has(cid3):
			r.append(cid3)
	return r


## 记住车间里的选择(下次打开沿用)
func remember_craft(kind: String, cats: Array, mats: Dictionary) -> void:
	var per: Dictionary = craft_last.get("cats", {})
	per[kind] = cats.duplicate()
	craft_last = {"kind": kind, "cats": per, "mats": mats.duplicate()}


## 分解：武器库里的一件武器拆成材料
func salvage(equip_id: String) -> Dictionary:
	if not _can_manage():
		return _fail("ui.err.not_now")
	var i: int = inventory.find(equip_id)
	if i < 0:
		return _fail("ui.err.salvage_missing")
	if not catalog.get_equipment(equip_id).is_gear():
		return _fail("ui.err.not_wearable")
	var gain: Dictionary = Crafting.salvage_yield(catalog, equip_id)
	inventory.remove_at(i)
	add_materials(gain)
	_changed("salvage")
	var r: Dictionary = _ok()
	r["gain"] = gain
	return r


## 按掉落表抽一项；本章保底(loot_guarantee)快来不及时强制开出武器/节点
func _roll_loot_entry(tier: String) -> Dictionary:
	var table: Array = (catalog.loot.get("orbs", {}) as Dictionary).get(tier, [])
	var guar: Dictionary = chapter.get("loot_guarantee", {})
	var remaining: int = _orbs_left_in_chapter()
	var need_w: int = int(guar.get("weapon", 0)) - int(loot_counts["weapon"])
	var need_u: int = int(guar.get("unit", 0)) - int(loot_counts["unit"])
	if need_w > 0 and need_w + maxi(0, need_u) >= remaining:
		for e: Dictionary in table:
			if e.has("weapon_max_cost"):
				return e
	if need_u > 0 and need_u >= remaining:
		for e2: Dictionary in table:
			if e2.has("unit_cost"):
				return e2
	var total := 0.0
	for e3: Dictionary in table:
		total += float(e3.get("w", 1))
	var roll: float = rng.randf() * total
	for e4: Dictionary in table:
		roll -= float(e4.get("w", 1))
		if roll <= 0.0:
			return e4
	return table.back() if not table.is_empty() else {"gold": 1}


## 本章还剩多少个晶球没开(当前待领取的 + 后面节点里带晶球的敌人)
func _orbs_left_in_chapter() -> int:
	var n := 0
	for o: Dictionary in pending_orbs:
		if not bool(o["opened"]):
			n += 1
	if is_grid():
		return n
	var nodes: Array = map_nodes()
	for k in range(node_index + 1, nodes.size()):
		for e: Variant in ((nodes[k] as Dictionary).get("encounter", {}) as Dictionary).get("units", []):
			if (e as Array).size() > 4 and ((e as Array)[4] as Dictionary).has("orb"):
				n += 1
	return n


func _random_unit_of_cost(c: int) -> String:
	var pool: Array[String] = []
	for id: String in catalog.shop_unit_ids():
		if catalog.get_unit(id).cost == c:
			pool.append(id)
	if pool.is_empty():
		pool = catalog.shop_unit_ids()
	return pool[rng.randi() % pool.size()] if not pool.is_empty() else ""


func _random_weapon(max_cost: int) -> String:
	var pool: Array[String] = []
	for id: String in catalog.equipment_ids():
		if catalog.get_equipment(id).cost <= max_cost and not id.begins_with("sample_"):
			pool.append(id)
	return pool[rng.randi() % pool.size()] if not pool.is_empty() else ""


func unopened_orbs() -> int:
	var n := 0
	for o: Dictionary in pending_orbs:
		if not bool(o["opened"]):
			n += 1
	return n


## 离开战场：没点开的晶球自动打开；前往下一个节点，或者章节结束
func finish_loot() -> Array[Dictionary]:
	var auto: Array[Dictionary] = []
	for i in range(pending_orbs.size()):
		if not bool(pending_orbs[i]["opened"]):
			auto.append(open_orb(i))
	pending_orbs.clear()
	if phase == "over":
		return auto
	if is_grid():
		_grid_after_battle()
		_changed("loot_done")
		return auto
	node_index += 1
	if node_index >= total_nodes():
		_chapter_cleared()
	else:
		phase = "map"
	_changed("loot_done")
	return auto


# ================================================================== 章节结束 / 换章
## 打通一个章节：先选下一章的分支(branch)，再按那一章的颜色选一项卡车改装(chapter_end)；没有下一章 = 通关
func _chapter_cleared() -> void:
	if not chapters_cleared.has(chapter_id):
		chapters_cleared.append(chapter_id)
	mod_options.clear()
	pending_chapter = ""
	if next_branches().is_empty():
		phase = "over"
		won_run = true
	else:
		phase = "branch"


## 改装池三选一：出现时间 t(0 = 开局；n = 进第 n 章之前)在 [t_min, t_max] 内、还没选过的改装；按稀有度权重抽 offer 个；
## color(下一章的颜色)不为空时，抽出来的里面必定至少有一项是这个颜色(池子里有的话)。用独立的随机数，不打乱主随机序列
func roll_mod_options(t: int, color: String) -> Array[String]:
	var pool: Array[Dictionary] = []
	var ids: Array = catalog.mods.keys()
	ids.sort()
	for id: Variant in ids:
		var m: Dictionary = catalog.mods[id]
		if truck_mods.has(str(id)) or t < int(m.get("t_min", 0)) or t > int(m.get("t_max", 0)):
			continue
		pool.append(m)
	var mr := RandomNumberGenerator.new()
	mr.seed = seed_value * 97 + t * 7919 + truck_mods.size() * 131 + 5
	var picks: Array[Dictionary] = []
	var rest: Array[Dictionary] = pool.duplicate()
	while picks.size() < int(catalog.mod_cfg.get("offer", 3)) and not rest.is_empty():
		var p: Dictionary = _weighted_mod(rest, mr)
		picks.append(p)
		rest.erase(p)
	if color != "":
		var has_color := false
		for pk: Dictionary in picks:
			if str(pk.get("color", "")) == color:
				has_color = true
		if not has_color:
			var cands: Array[Dictionary] = []
			for c: Dictionary in rest:
				if str(c.get("color", "")) == color:
					cands.append(c)
			if not cands.is_empty() and not picks.is_empty():
				picks[picks.size() - 1] = _weighted_mod(cands, mr)
	var out: Array[String] = []
	for pk2: Dictionary in picks:
		out.append(str(pk2["id"]))
	return out


func _weighted_mod(cands: Array[Dictionary], mr: RandomNumberGenerator) -> Dictionary:
	var ws: Dictionary = catalog.mod_cfg.get("rarity_weights", {})
	var total := 0.0
	for c: Dictionary in cands:
		total += float(ws.get(str(int(c.get("rarity", 1))), 1.0))
	var x: float = mr.randf() * total
	for c2: Dictionary in cands:
		x -= float(ws.get(str(int(c2.get("rarity", 1))), 1.0))
		if x <= 0.0:
			return c2
	return cands.back()


## 选一项卡车改装：开局(start_mod)→ 地图；章节过渡(chapter_end)→ 进 pending_chapter。带 layout 的改装换卡车的摆法规则
func pick_mod(id: String) -> Dictionary:
	if phase != "start_mod" and phase != "chapter_end":
		return _fail("ui.err.not_now")
	if not mod_options.has(id) or not catalog.mods.has(id):
		return _fail("ui.err.bad_target")
	truck_mods.append(id)
	var d: Dictionary = catalog.mods[id]
	if d.has("layout"):
		truck_layout = TruckLayout.make(str(d["layout"]))
		_dmap = null
	mod_options.clear()
	if phase == "start_mod":
		phase = "map"
		_changed("mod")
		return _ok()
	_enter_next_chapter()
	_changed("chapter")
	return _ok()


func mod_def(id: String) -> Dictionary:
	return catalog.mods.get(id, {})


func _enter_next_chapter() -> void:
	enter_chapter(pending_chapter, false)
	pending_chapter = ""
	if not shop_locked:
		roll_shop(false)


## 下一章的分支 [{id, available}]；空 = 没有下一章
func next_branches() -> Array:
	var nx: Variant = chapter.get("next", "")
	if nx is Dictionary:
		return (nx as Dictionary).get("branches", [])
	if str(nx) != "":
		return [{"id": str(nx), "available": true}]
	return []


## 选下一章的分支：之后按那一章的颜色 / 出现时间(chapter_no)三选一改装(chapter_end)；池子空了就直接进章
func choose_branch(id: String) -> Dictionary:
	if phase != "branch":
		return _fail("ui.err.not_now")
	for b: Dictionary in next_branches():
		if str(b["id"]) == id and bool(b.get("available", false)) and catalog.chapters.has(id):
			var ch: Dictionary = catalog.chapters[id]
			pending_chapter = id
			mod_options = roll_mod_options(int(ch.get("chapter_no", 1)), str(ch.get("color", "")))
			if mod_options.is_empty():
				_enter_next_chapter()
				_changed("chapter")
			else:
				phase = "chapter_end"
				_changed("branch")
			return _ok()
	return _fail("ui.err.locked")


# ================================================================== 方格网章节(第一章起)
func _setup_grid() -> void:
	gmap = ChapterMap.generate(chapter.get("grid", {}), seed_value * 7 + chapter_id.hash() % 100003)
	pos = str(gmap["start"])
	ap_max = maxi(1, int(gmap["ap"]) - ap_penalty)
	ap = ap_max
	steps = 0
	visits = 0
	# 战斗强度的随机浮动(±jitter)：开局就给每个格点定好，悬停看到的就是进去打的强度。用单独的随机数，不打乱主随机序列
	var jr := RandomNumberGenerator.new()
	jr.seed = seed_value * 31 + chapter_id.hash() % 7919
	var jit: float = float((chapter.get("intensity", {}) as Dictionary).get("jitter", 0.0))
	var keys: Array = (gmap["nodes"] as Dictionary).keys()
	keys.sort()
	for k: Variant in keys:
		gnode(str(k))["iv_jitter"] = jr.randf_range(-jit, jit) if jit > 0.0 else 0.0
	# 强怪：后半程(离起点的步数超过首领的 from 倍)的普通作战，有 chance 的几率在浮动之上再加 bump 级强度
	var sc: Dictionary = (chapter.get("intensity", {}) as Dictionary).get("strong", {})
	var boss_depth: float = float(int(gnode(str(gmap.get("boss", ""))).get("depth", 0)))
	if not sc.is_empty():
		var bump: Array = sc.get("bump", [3, 5])
		for k2: Variant in keys:
			var nd2: Dictionary = gnode(str(k2))
			if str(nd2.get("type", "")) != "fight" or float(int(nd2.get("depth", 0))) <= boss_depth * float(sc.get("from", 0.5)):
				continue
			if jr.randf() < float(sc.get("chance", 0.0)):
				nd2["strong_bump"] = jr.randi_range(int(bump[0]), int(bump[1]))
	_observe()


func gnode(k: String) -> Dictionary:
	return (gmap.get("nodes", {}) as Dictionary).get(k, {})


func _adj() -> Dictionary:
	if not gmap.has("_adj"):
		gmap["_adj"] = ChapterMap.neighbors(gmap)
	return gmap["_adj"]


## 已完成的节点可以穿行(商店完成后也可以再进)
func passable(k: String) -> bool:
	return str(gnode(k).get("state", "")) == "done"


## 从卡车出发到每个能去的格点的最短步数：只能穿过已完成的节点(终点可以是未完成的)
func reachable() -> Dictionary:
	var dist := {pos: 0}
	var q: Array[String] = [pos]
	var i := 0
	var adj: Dictionary = _adj()
	while i < q.size():
		var c: String = q[i]
		i += 1
		if c != pos and not passable(c):
			continue
		for n: String in adj.get(c, []):
			if not dist.has(n):
				dist[n] = int(dist[c]) + 1
				q.append(n)
	return dist


## 去 dest 的路线(不含起点，含终点)；去不了返回空
func path_to(dest: String) -> Array[String]:
	var prev := {pos: ""}
	var q: Array[String] = [pos]
	var i := 0
	var adj: Dictionary = _adj()
	while i < q.size():
		var c: String = q[i]
		i += 1
		if c == dest:
			break
		if c != pos and not passable(c):
			continue
		for n: String in adj.get(c, []):
			if not prev.has(n):
				prev[n] = c
				q.append(n)
	var out: Array[String] = []
	if not prev.has(dest) or dest == pos:
		return out
	var k: String = dest
	while k != pos:
		out.push_front(k)
		k = str(prev[k])
	return out


func move_cost(dest: String) -> int:
	if dest == pos:
		return 0
	var p: Array[String] = path_to(dest)
	return p.size() if not p.is_empty() else -1


## 观测：从卡车出发、只经过已完成节点能走到的节点都看得见类型
func _observe() -> void:
	var adj: Dictionary = _adj()
	var seen := {pos: true}
	var q: Array[String] = [pos]
	var i := 0
	while i < q.size():
		var c: String = q[i]
		i += 1
		if c != pos and not passable(c):
			continue
		for n: String in adj.get(c, []):
			if str(gnode(n).get("state", "")) == "hidden":
				gnode(n)["state"] = "seen"
			if not seen.has(n):
				seen[n] = true
				q.append(n)


## 开着卡车去 dest(一路扣行动力)，然后按节点类型进入：作战 → prepare，修整 → rest，事件 → event，商店 → shop。
## dest == 卡车所在的格点：再进一次(首领打输了重新挑战 / 再逛一次商店)，不扣行动力
func move_to(dest: String) -> Dictionary:
	if phase != "map" or not is_grid():
		return _fail("ui.err.not_now")
	if gnode(dest).is_empty():
		return _fail("ui.err.bad_target")
	var cost: int = move_cost(dest)
	if cost < 0:
		return _fail("ui.err.unreachable")
	if cost > ap:
		return _fail("ui.err.no_ap")
	ap -= cost
	steps += cost
	pos = dest
	_observe()
	return _enter_node()


func _enter_node() -> Dictionary:
	hunt_mark = -1
	var nd: Dictionary = current_node()
	var t: String = str(nd.get("type", ""))
	var done: bool = str(nd.get("state", "")) == "done"
	if t == "shop_black" or t == "shop_parts":
		_ensure_node_shop(pos, t)
		node_shops[pos]["refreshes"] = 0
		phase = "shop"
	elif done:
		phase = "map"
		if ap <= 0 and pos != str(gmap.get("boss", "")):
			_begin_hunt()
	elif t == "fight" or t == "elite" or t == "boss":
		_begin_fight(t)
	elif t == "rest":
		phase = "rest"
	elif t == "event":
		_start_event()
		phase = "event"
	else:
		phase = "map"
	_changed("move")
	return _ok()


## 本场战斗的类型：fight / elite / boss / hunt(线性章节 = reward)
func battle_kind() -> String:
	if hunt_active:
		return "hunt"
	if is_grid():
		return str(current_node().get("type", "fight"))
	return str(current_node().get("type", "reward"))


func _begin_fight(kind: String) -> void:
	var nd: Dictionary = current_node()
	if not nd.has("encounter"):
		nd["encounter"] = _make_encounter(kind)
	nd["intensity"] = int(nd["encounter"].get("intensity", 0))
	visits += 1
	nd["layout"] = _make_layout(nd["encounter"])
	_pay_arrival(kind)
	phase = "prepare"
	_fix_board_cells()


## 行动力用完还没打倒首领：首领的强化版就地追上来(追猎)
func _begin_hunt() -> void:
	hunt_active = true
	hunt_enc = _make_encounter("hunt")
	visits += 1
	hunt_layout = _make_layout(hunt_enc)
	_pay_arrival("hunt")
	phase = "prepare"
	_fix_board_cells()


## 抵达战斗节点：收入 + 利息、经验、商店免费刷新(除非锁定)
func _pay_arrival(kind: String) -> void:
	var inc: int = int((chapter.get("income", {}) as Dictionary).get(kind, 0))
	if inc > 0:
		inc = maxi(0, inc + int(flag_value("income_bonus")))
	var itr: int = interest()
	gold += inc + itr
	add_xp(int(shop_rule.get("xp_per_node", 2)))
	last_result = {"income": inc, "interest": itr}
	if not shop_locked:
		roll_shop(false)
	shop_locked = false


## 敌人的强度倍率接口(占位：怪的强弱都写进配怪条目的 hp_mult / atk_mult 里了)
func enemy_scale() -> Vector2:
	return Vector2.ONE


# ------------------------------------------------------------------ 战斗强度与配怪
## 战斗强度 = 一场战斗敌方总水平的绝对刻度(用户 2026-10-05)：普通 / 精英 / 首领 / 追猎，同样的强度 = 同样多的"强度点数"
## (实际难度会因为配怪组合不同而有差别)。一只怪的点数 = power × 星级系数 × (生命攻击倍率)^scale_exp，
## 三样都由 tools/fit_power.py 用模拟战斗标定：同样的点数 ≈ 同样的难度，不管几只、几星、普通还是精英 / 首领。
## 节点的强度：离起点越远越高(base + per_depth × (步数 − 1)，最高 max)；精英再 +elite_bonus；普通 / 精英再乘开局定好的 1 ± jitter；
## 后半程的普通作战有几率是"强怪"：在浮动之上再加几级(intensity.strong，开局定好)；首领 / 追猎是固定值
func node_intensity(k: String) -> int:
	var nd: Dictionary = gnode(k)
	var ic: Dictionary = chapter.get("intensity", {})
	var v: float = _depth_value(int(nd.get("depth", 1)))
	match str(nd.get("type", "")):
		"boss":
			return int(ic.get("boss", 30))
		"elite":
			v += float(ic.get("elite_bonus", 4))
	return int(round(v * (1.0 + float(nd.get("iv_jitter", 0.0))))) + int(nd.get("strong_bump", 0))


## 这个格点的普通作战是不是"强怪"(只在后半程，开局定好；强度里已经加上了)
func node_strong(k: String) -> bool:
	return int(gnode(k).get("strong_bump", 0)) > 0


## 不带浮动的强度(按离起点的步数线性增长)
func _depth_intensity(depth: int) -> int:
	return int(round(_depth_value(depth)))


func _depth_value(depth: int) -> float:
	var ic: Dictionary = chapter.get("intensity", {})
	var v: float = float(ic.get("base", 10)) + float(ic.get("per_depth", 1.6)) * float(maxi(0, depth - 1))
	return minf(v, float(ic.get("max", 28)))


func _max_star(intensity: int) -> int:
	var best := 1
	for e: Array in chapter.get("max_star", [[0, 1]]):
		if intensity >= int(e[0]):
			best = int(e[1])
	return best


## 一只怪的强度点数：power × 星级系数(精英 / 首领用 head_star_power) × 倍率^scale_exp
func _unit_power(id: String, star: int, mult: float = 1.0) -> float:
	var md: Dictionary = (chapter.get("monsters", {}) as Dictionary).get(id, {})
	var sp: Dictionary = chapter.get("head_star_power" if bool(md.get("head", false)) else "star_power", {})
	return float(md.get("power", 3.4)) * float(sp.get(str(star), float(star))) * pow(mult, _scale_exp())


func _scale_exp() -> float:
	return float(chapter.get("scale_exp", 2.0))


## 点数从 have 拉到 want 要乘的生命攻击倍率
func _mult_for(have: float, want: float) -> float:
	if have <= 0.0:
		return 1.0
	return clampf(pow(maxf(want, 0.01) / have, 1.0 / _scale_exp()), 0.4, 3.0)


## 生成遭遇(进入节点时现配)。kind = fight / elite / boss / hunt；intensity < 0 = 用当前节点的强度(和它是不是强怪)。
## 怎么配：精英 / 首领的本体先占自己的点数；剩下的点数挑一个阵型(必备的怪 + 可选的怪)，先补可选的怪、再升星，只要不超过剩下的点数；
## 最后把这批怪的生命 / 攻击按同一个倍率微调，让总点数正好等于战斗强度(所以强度每 +1，难度都平滑地涨一点，没有台阶)。
## 单挑的首领 / 追猎、或者剩下的点数不够配手下时，倍率加在本体上。
func _make_encounter(kind: String, intensity: int = -1, strong: bool = false) -> Dictionary:
	var ic: Dictionary = chapter.get("intensity", {})
	var inten: int = intensity
	if inten < 0:
		match kind:
			"hunt":
				inten = int(ic.get("hunt", 34))
			"boss":
				inten = int(ic.get("boss", 30))
			_:
				inten = node_intensity(pos)
		strong = kind == "fight" and node_strong(pos)
	inten = maxi(1, inten + int(flag_value("next_battle_intensity")))
	var pool: String = kind
	if kind == "fight":
		pool = "strong" if strong else "weak"
	var regions_all: Array = chapter.get("regions", [["n", "nw", "ne", "n", "nw", "ne"]])
	var regions: Array = regions_all[rng.randi() % regions_all.size()]
	var units: Array = []
	var budget: float = float(inten)
	var head: Array = []
	var solo := false
	var el_forms: Array = []                     # 精英自己的阵型(忧郁 / 傲慢的余烬依赖手下：配合它的小怪组合)
	match kind:
		"elite":
			var pe: Array = _pick_elite(budget)
			var el: Dictionary = pe[0]
			el_forms = el.get("forms", [])
			head = [str(el["unit"]), int(pe[1]), str(el.get("region", "n")), "", {"orb": "gold", "elite": true}]
		"boss", "hunt":
			var bd: Dictionary = chapter.get(kind, {})
			head = [str(bd["unit"]), int(bd.get("star", 1)), str(bd.get("region", "n")), "", {"orb": "gold", "boss": true}]
			solo = bool(bd.get("solo", false))
	var head_pts := 0.0
	if not head.is_empty():
		head_pts = _unit_power(str(head[0]), int(head[1]))
		units.append(head)
		budget -= head_pts
	var embers: Array = []
	if kind == "fight" or (not solo and budget > 0.0):
		var list: Array = el_forms if not el_forms.is_empty() else fight_formations()
		var form: Dictionary = _pick_formation(list, budget)
		embers = _fill_formation(form, maxf(budget, 0.0), _max_star(inten), kind == "fight")
	var pts := 0.0
	for e: Array in embers:
		pts += _unit_power(str(e[0]), int(e[1]))
	var m := 1.0
	if not embers.is_empty():
		m = _mult_for(pts, budget)                                   # 小怪的倍率：总点数正好补到强度
	elif not head.is_empty():
		var hm: float = _mult_for(head_pts, head_pts + budget)      # 没有手下：倍率加在本体上(单挑首领 / 点数不够配手下 / 本体比强度还强)
		if absf(hm - 1.0) > 0.001:
			(head[4] as Dictionary)["hp_mult"] = snappedf(hm, 0.001)
			(head[4] as Dictionary)["atk_mult"] = snappedf(hm, 0.001)
	var start: int = 1 if not head.is_empty() else 0
	for i in range(embers.size()):
		var e2: Array = embers[i]
		var eo: Dictionary = {}
		if absf(m - 1.0) > 0.001:
			eo = {"hp_mult": snappedf(m, 0.001), "atk_mult": snappedf(m, 0.001)}
		units.append([e2[0], e2[1], str(regions[(i + start) % regions.size()]) if kind != "hunt" else ["s", "se", "sw"][i % 3], "", eo])
	# 晶球：普通作战 1 个白(强怪 1 个蓝，给点数最高的怪)；精英 / 首领的本体掉金色，手下掉一个蓝
	var order: Array = []
	for i2 in range(units.size()):
		if (units[i2][4] as Dictionary).has("orb"):
			continue
		order.append([_unit_power(str(units[i2][0]), int(units[i2][1])), i2])
	order.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) > float(y[0]))
	var od: Dictionary = chapter.get("orb_drops", {"weak": ["white"], "strong": ["blue"], "minions": ["blue"]})
	var orbs: Array = od.get("weak", ["white"]) if pool == "weak" else (od.get("strong", ["blue"]) if kind == "fight" else od.get("minions", ["blue"]))
	for k2 in range(mini(orbs.size(), order.size())):
		(units[int(order[k2][1])][4] as Dictionary)["orb"] = orbs[k2]
	# 战斗地图：普通作战(含强怪)用同一种，精英 / 首领 / 追猎各自一种
	var bm: Dictionary = chapter.get("battle_map", {})
	var mcfg: Dictionary = (bm.get("fight" if kind == "fight" else kind, bm.get("weak", {})) as Dictionary).duplicate()
	mcfg["theme"] = str(chapter.get("theme", "white"))
	return {"units": units, "map": mcfg, "pool": pool, "intensity": inten, "strong": strong}


## 挑精英 [精英, 星级]：本体的点数不超过战斗强度的精英里随机(本体缩得太小会比点数说的更强，所以强度不够时不出这只)；
## 2 星本体的点数 ≤ 强度 × elite_star2_share(给手下留点位置)就出 2 星。都放不下就挑 1 星点数最少的(再按倍率缩小)
func _pick_elite(budget: float) -> Array:
	var els: Array = chapter.get("elites", [])
	var share: float = float(chapter.get("elite_star2_share", 0.8))
	var ok: Array = []
	var cheapest: Dictionary = els[0] if not els.is_empty() else {}
	for el: Dictionary in els:
		var id: String = str(el["unit"])
		if _unit_power(id, 2) <= budget * share + 0.001:
			ok.append([el, 2])
		elif _unit_power(id, 1) <= budget + 0.001:
			ok.append([el, 1])
		if _unit_power(id, 1) < _unit_power(str(cheapest["unit"]), 1):
			cheapest = el
	return ok[rng.randi() % ok.size()] if not ok.is_empty() else [cheapest, 1]


## 一场战斗的总点数(含倍率)：配怪算法的自检用，应该 ≈ 战斗强度
func encounter_power(enc: Dictionary) -> float:
	var tot := 0.0
	for e: Array in enc.get("units", []):
		var mult: float = float((e[4] as Dictionary).get("hp_mult", 1.0)) if e.size() > 4 else 1.0
		tot += _unit_power(str(e[0]), int(e[1]), mult)
	return tot


## 普通作战的阵型表(章节数据 formations：一张表；旧数据按池子分的也认，合在一起)
func fight_formations() -> Array:
	var f: Variant = chapter.get("formations", [])
	if f is Array:
		return f
	var all: Array = []
	for k: String in (f as Dictionary).keys():
		all.append_array((f as Dictionary)[k])
	return all


## 挑阵型：必备的怪(1 星)放得下的阵型里按权重随机；一个都放不下(强度很低)就用必备点数最少的那个(之后按倍率缩小)
func _pick_formation(list: Array, budget: float) -> Dictionary:
	if list.is_empty():
		return {"req": [], "extra": []}
	var ok: Array = []
	var tot := 0.0
	var cheapest: Dictionary = list[0]
	var cheap_pts := 1.0e9
	for f: Dictionary in list:
		var rp := 0.0
		for id: String in f.get("req", []):
			rp += _unit_power(id, 1)
		if rp < cheap_pts:
			cheap_pts = rp
			cheapest = f
		if rp <= budget + 0.001:
			ok.append(f)
			tot += float(f.get("w", 1))
	if ok.is_empty():
		return cheapest
	var r: float = rng.randf() * tot
	for f2: Dictionary in ok:
		r -= float(f2.get("w", 1))
		if r <= 0.0:
			return f2
	return ok.back()


## 按阵型配怪：必备的怪(1 星) → 补可选的怪 → 升星(从星级最低的开始)，每一步都不超过 budget；最多 6 只。
## 阵型的怪都升满了还差得多，就按阵型里的怪再补(轮着来)，补了再升星——免得强度高的时候只靠倍率把 4 只怪硬拉大。
## need_req = false(精英 / 首领的手下)时，放不下的必备怪也去掉
func _fill_formation(form: Dictionary, budget: float, max_star: int, need_req: bool = true) -> Array:
	var slots: Array = []
	for id: String in form.get("req", []):
		slots.append([id, 1])
	var power := 0.0
	for sl: Array in slots:
		power += _unit_power(str(sl[0]), 1)
	if not need_req:
		while not slots.is_empty() and power > budget + 0.001:
			power -= _unit_power(str(slots.back()[0]), 1)
			slots.pop_back()
	for id2: String in form.get("extra", []):
		if slots.size() >= 6:
			break
		var pp: float = _unit_power(id2, 1)
		if power + pp <= budget + 0.001:
			slots.append([id2, 1])
			power += pp
	var cycle: Array = (form.get("extra", []) as Array) + (form.get("req", []) as Array)
	var ci := 0
	var guard := 0
	while guard < 80:
		guard += 1
		var low := 99
		var cands: Array = []
		for i in range(slots.size()):
			var st: int = int(slots[i][1])
			if st >= max_star:
				continue
			var d: float = _unit_power(str(slots[i][0]), st + 1) - _unit_power(str(slots[i][0]), st)
			if power + d > budget + 0.001:
				continue
			if st < low:
				low = st
				cands = [i]
			elif st == low:
				cands.append(i)
		if cands.is_empty():
			# 升不动了：还有空位、而且差得多(超过一只 1 星怪)，就按阵型轮着再补一只
			if slots.size() >= 6 or cycle.is_empty() or ci >= cycle.size() * 2:
				break
			var add: String = str(cycle[ci % cycle.size()])
			ci += 1
			var ap: float = _unit_power(add, 1)
			if power + ap > budget + 0.001:
				continue
			slots.append([add, 1])
			power += ap
			continue
		var pick: int = cands[rng.randi() % cands.size()]
		var before: float = _unit_power(str(slots[pick][0]), int(slots[pick][1]))
		slots[pick][1] = int(slots[pick][1]) + 1
		power += _unit_power(str(slots[pick][0]), int(slots[pick][1])) - before
	return slots


func _make_layout(enc: Dictionary) -> Dictionary:
	var mcfg: Dictionary = (enc.get("map", {}) as Dictionary).duplicate()
	if mcfg.has("arena"):
		return Events.arena_layout(catalog, str(mcfg["arena"]))
	var regions: Array = []
	for e: Variant in enc.get("units", []):
		regions.append((e as Array)[2])
	mcfg["regions"] = regions
	return MapGen.generate(mcfg, seed_value * 131 + visits * 7919 + 17)


## 一场战斗打完、晶球领完之后(方格网章节)
func _grid_after_battle() -> void:
	var won: bool = bool(last_result.get("win", false))
	var nd: Dictionary = current_node()
	if hunt_active:
		if won:
			hunt_active = false
			ap_penalty += 1
			_chapter_cleared()
		else:
			_begin_hunt()                  # 追猎打输了：卡车受损，猎犬还在，只能再打
		return
	if str(nd.get("type", "")) == "boss":
		if won:
			nd["state"] = "done"
			_chapter_cleared()
		else:
			phase = "map"                  # 首领打输了：卡车受损，停在首领面前，可以重新挑战(或者先回头)
		return
	nd["state"] = "done"
	node_index += 1
	_after_node()


## 离开一个非战斗节点(修整 / 事件 / 商店)
func leave_node() -> Dictionary:
	if phase != "rest" and phase != "event" and phase != "shop":
		return _fail("ui.err.not_now")
	var nd: Dictionary = current_node()
	if str(nd.get("state", "")) != "done":
		nd["state"] = "done"
		node_index += 1
	_after_node()
	_changed("leave")
	return _ok()


func _after_node() -> void:
	_observe()
	if ap <= 0 and pos != str(gmap.get("boss", "")):
		_begin_hunt()
	else:
		phase = "map"


# ------------------------------------------------------------------ 修整
## 修整：回复卡车耐久，或者把一个 1 星棋子直接升到 2 星(有最高费用限制)，二选一
func rest_repair_amount() -> int:
	return int(round(float(truck_max) * float((chapter.get("rest", {}) as Dictionary).get("repair_pct", 0.3))))


func rest_upgrade_candidates() -> Array[Dictionary]:
	var cap: int = int((chapter.get("rest", {}) as Dictionary).get("upgrade_max_cost", 3))
	var r: Array[Dictionary] = []
	for id: String in roster.keys():
		var u: Dictionary = roster[id]
		if int(u["star"]) == 1 and cost_of_unit(u) <= cap:
			r.append(u)
	r.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return cost_of_unit(a) > cost_of_unit(b))
	return r


func rest_repair() -> Dictionary:
	if phase != "rest":
		return _fail("ui.err.not_now")
	truck_hp = mini(truck_max, truck_hp + rest_repair_amount())
	return leave_node()


func rest_upgrade(roster_id: String) -> Dictionary:
	if phase != "rest":
		return _fail("ui.err.not_now")
	var ok := false
	for u: Dictionary in rest_upgrade_candidates():
		if str(u["id"]) == roster_id:
			ok = true
	if not ok:
		return _fail("ui.err.bad_target")
	roster[roster_id]["star"] = 2
	_merge_all()
	return leave_node()


# ------------------------------------------------------------------ 事件(规则见 Events，数据 game/data/events.json)
## 进入事件节点：从当前章节能出的事件池里按稀有度抽一个(通用 / 特定章节事件整局移出池子，颜色 / 限定事件本章不再出现)
func _start_event() -> void:
	if not event_state.is_empty() and str(event_state.get("node", "")) == pos and int(event_state.get("option", -1)) < 0:
		return                                   # 同一个事件还没做选择
	var id: String = Events.pick(catalog, self, rng)
	var ev: Dictionary = catalog.events.get(id, {})
	if Events.removed_for_run(ev) and not events_gone.has(id):
		events_gone.append(id)
	if not events_this_chapter.has(id):
		events_this_chapter.append(id)
	event_state = {"id": id, "node": pos, "option": -1, "outcome": "", "picks": {}, "closed": [], "gains": [], "repeat": false}
	current_node()["event"] = id


func event_def() -> Dictionary:
	return catalog.events.get(str(event_state.get("id", "")), {})


func event_option_check(i: int) -> Dictionary:
	return Events.check_option(catalog, self, str(event_state.get("id", "")), i)


## 选一个选项：条件不满足不能选；按权重抽结果(可重复的选项按第几次选取那一组)，立刻生效；实际得到 / 失去的东西记在 event_state.gains；
## 结果可以关掉别的选项(close)。遇到战斗先记下来(界面上先读结果文字)，按「迎战」(event_continue)才进备战
func event_choose(i: int) -> Dictionary:
	if phase != "event" or event_state.is_empty() or int(event_state.get("option", -1)) >= 0:
		return _fail("ui.err.not_now")
	var chk: Dictionary = event_option_check(i)
	if not bool(chk["ok"]):
		return _fail("ui.err.event_requirement")
	var opt: Dictionary = (event_def().get("options", []) as Array)[i]
	var oid: String = str(opt.get("id", ""))
	var picks: Dictionary = event_state.get("picks", {})
	var n: int = int(picks.get(oid, 0))
	var oc: Dictionary = Events.roll_outcome(opt, rng, n, not luck_cfg().is_empty())
	event_state["option"] = i
	event_state["outcome"] = str(oc.get("id", ""))
	event_state["gains"] = []
	picks[oid] = n + 1
	event_state["picks"] = picks
	var closed: Array = event_state.get("closed", [])
	for cid: Variant in oc.get("close", []):
		if not closed.has(str(cid)):
			closed.append(str(cid))
	event_state["closed"] = closed
	event_state["repeat"] = opt.has("repeat") and not bool(oc.get("end", false))
	var battle := false
	for eff: Dictionary in oc.get("effects", []):
		battle = _apply_event_effect(eff) or battle
	_changed("event")
	var r: Dictionary = _ok()
	r["outcome"] = event_state["outcome"]
	r["battle"] = battle
	return r


func _event_gain(g: Dictionary) -> void:
	(event_state.get("gains", []) as Array).append(g)


## 效果做不成(没有棋子可失去 / 零件箱满了 / 没有能升星的)时用它的 fallback
func _event_fallback(eff: Dictionary) -> void:
	if eff.has("fallback"):
		_apply_event_effect(eff["fallback"])


## 花名册里挑一个棋子：random / strongest(费用最高、星级最高) / cheapest
func _pick_roster(who: String) -> Dictionary:
	var ids: Array = roster.keys()
	ids.sort()
	if ids.is_empty():
		return {}
	match who:
		"strongest", "cheapest":
			var best: Dictionary = {}
			var best_v := 0.0
			for rid: Variant in ids:
				var u: Dictionary = roster[rid]
				var v: float = float(cost_of_unit(u)) * 10.0 + float(u["star"])
				if who == "cheapest":
					v = -v
				if best.is_empty() or v > best_v:
					best = u
					best_v = v
			return best
	return roster[ids[rng.randi() % ids.size()]]


## 一个事件效果；返回 true = 进入了战斗
func _apply_event_effect(eff: Dictionary) -> bool:
	match str(eff.get("type", "")):
		"truck_damage":
			truck_hp = maxi(1, truck_hp - int(eff.get("amount", 0)))
		"truck_heal":
			var amt: int = int(eff.get("amount", 0)) + int(round(float(truck_max) * float(eff.get("pct", 0.0))))
			truck_hp = mini(truck_max, truck_hp + amt)
		"truck_max":
			truck_max = maxi(40, truck_max + int(eff.get("amount", 0)))
			truck_hp = mini(truck_hp, truck_max)
		"materials":
			if str(eff.get("half", "")) == "most":
				var most := ""
				for m: String in Crafting.MATS:
					if most == "" or int(materials.get(m, 0)) > int(materials.get(most, 0)):
						most = m
				var cut: int = int(ceil(float(materials.get(most, 0)) * 0.5))
				materials[most] = int(materials.get(most, 0)) - cut
				if cut > 0:
					_event_gain({"type": "materials_lost", "lost": {most: cut}})
			else:
				var add := {}
				var lost := {}
				for m2: String in Crafting.MATS:
					var v: int = int(eff.get(m2, 0))
					if v >= 0:
						add[m2] = v
					else:
						var cut2: int = mini(int(materials.get(m2, 0)), -v)
						materials[m2] = int(materials.get(m2, 0)) - cut2
						if cut2 > 0:
							lost[m2] = cut2
				add_materials(add)
				if not lost.is_empty():
					_event_gain({"type": "materials_lost", "lost": lost})
		"gold":
			gold = maxi(0, gold + int(eff.get("amount", 0)))
		"xp":
			add_xp(int(eff.get("amount", 0)))
		"ap":
			ap = maxi(0, ap + int(eff.get("amount", 0)))
		"reveal":
			reveal_around(int(eff.get("radius", 2)))
		"unit":
			var uid: String = str(eff["id"]) if eff.has("id") else _random_unit_of_cost(int(eff.get("cost", 1)))
			if uid != "":
				add_unit(uid, clampi(int(eff.get("star", 1)), 1, GC.MAX_STAR), null, free_bench_slot())
				_merge_all()
				_event_gain({"type": "unit", "id": uid})
		"weapon":
			var wid: String = str(eff["id"]) if eff.has("id") else _random_weapon(int(eff.get("max_cost", 3)))
			if wid != "":
				inventory.append(wid)
				_event_gain({"type": "weapon", "id": wid})
		"orb":
			for k in range(int(eff.get("count", 1))):
				var tier: String = str(eff.get("tier", "white"))
				_event_gain({"type": "orb", "tier": tier, "loot": _grant_orb(tier)})
		"perm":
			var u: Dictionary = _pick_roster(str(eff.get("who", "random")))
			if u.is_empty():
				_event_fallback(eff)
			else:
				var perm: Dictionary = u["perm"]
				var stats: Dictionary = eff.get("stats", {})
				for st: String in stats.keys():
					perm[st] = float(perm.get(st, 0.0)) + float(stats[st])
				_event_gain({"type": "perm", "id": str(u["def"]), "stats": stats.duplicate()})
		"star_up":
			var cands: Array = []
			var ids: Array = roster.keys()
			ids.sort()
			for rid: Variant in ids:
				var cu: Dictionary = roster[rid]
				if int(cu["star"]) == 1 and cost_of_unit(cu) <= int(eff.get("max_cost", 3)):
					cands.append(cu)
			if cands.is_empty():
				_event_fallback(eff)
			else:
				var su: Dictionary = cands[rng.randi() % cands.size()]
				su["star"] = 2
				_event_gain({"type": "star_up", "id": str(su["def"])})
				_merge_all()
		"lose_unit":
			if roster.size() <= 1:
				_event_fallback(eff)
			else:
				var lu: Dictionary = _pick_roster(str(eff.get("who", "random")))
				roster.erase(str(lu["id"]))
				_compact_bench()
				_event_gain({"type": "lose_unit", "id": str(lu["def"])})
		"lose_weapon":
			var ws: Array[int] = spare_weapons()
			if ws.is_empty():
				_event_fallback(eff)
			else:
				var wi: int = ws[rng.randi() % ws.size()]
				_event_gain({"type": "lose_weapon", "id": inventory[wi]})
				inventory.remove_at(wi)
		"lose_part":
			if parts.is_empty():
				_event_fallback(eff)
			else:
				var pi: int = rng.randi() % parts.size()
				_event_gain({"type": "lose_part", "id": parts[pi]})
				parts.remove_at(pi)
		"part":
			if parts.size() >= part_cap():
				_event_fallback(eff)
			else:
				var pid: String = str(eff.get("id", ""))
				if pid == "" or pid == "random":
					var pids: Array = (catalog.meta.get("parts", {}) as Dictionary).keys()
					pids.sort()
					pid = str(pids[rng.randi() % pids.size()]) if not pids.is_empty() else ""
				if pid != "":
					parts.append(pid)
					_event_gain({"type": "part", "id": pid})
		"flag":
			set_flag(str(eff.get("id", "")), float(eff.get("value", 0)), str(eff.get("until", "chapter")))
			_event_gain({"type": "flag", "id": str(eff.get("id", "")), "value": float(eff.get("value", 0))})
		"battle":
			event_state["battle"] = eff.duplicate(true)
			return true
	return false


## 事件里的战斗：强度 = 节点按步数的强度 + intensity_bonus(至少 min_intensity)，打赢了掉 orbs 里的晶球(额外奖励)。
## arena = 专属战场(Catalog.arenas：和事件画面是同一个地方，障碍 / 敌人出生方位 / 战场机制都是定好的，不随机生成)；
## 没有专属战场的话，可以在随机生成的战斗地图上固定放几块障碍(fixed)。打完(不论输赢)这个事件节点就完成了
func _event_battle(eff: Dictionary) -> void:
	var nd: Dictionary = current_node()
	var iv: int = maxi(int(eff.get("min_intensity", 0)), _depth_intensity(int(nd.get("depth", 1))) + int(eff.get("intensity_bonus", 0)))
	var enc: Dictionary = _make_encounter("fight", iv)
	var arena_id: String = str(eff.get("arena", ""))
	var regions: Array = (catalog.arenas.get(arena_id, {}) as Dictionary).get("regions", [])
	var order: Array = []
	for i in range((enc["units"] as Array).size()):
		var e: Array = enc["units"][i]
		(e[4] as Dictionary).erase("orb")
		if not regions.is_empty():
			e[2] = str(regions[i % regions.size()])
		order.append([_unit_power(str(e[0]), int(e[1])), i])
	order.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	var orbs: Array = eff.get("orbs", [])
	for k in range(mini(orbs.size(), order.size())):
		(enc["units"][int(order[k][1])][4] as Dictionary)["orb"] = str(orbs[k])
	if catalog.arenas.has(arena_id):
		enc["map"] = {"arena": arena_id}
	else:
		(enc["map"] as Dictionary)["fixed"] = (eff.get("fixed", []) as Array).duplicate(true)
	enc["event_battle"] = true
	nd["encounter"] = enc
	nd["intensity"] = iv
	visits += 1
	nd["layout"] = _make_layout(enc)
	phase = "prepare"
	_fix_board_cells()
	_changed("event_battle")


## 看完结果：离开事件节点；结果是一场战斗时 = 迎战(进备战，打完这个节点才算完成)。必须先做选择。
## 选的是可重复的选项 → 回到现场(选项列表)，已选次数保留
func event_continue() -> Dictionary:
	if phase != "event":
		return _fail("ui.err.not_now")
	if int(event_state.get("option", -1)) < 0:
		return _fail("ui.err.event_choose")
	if bool(event_state.get("repeat", false)) and not event_state.has("battle"):
		event_state["option"] = -1
		event_state["outcome"] = ""
		event_state["repeat"] = false
		event_state["gains"] = []
		_changed("event")
		return _ok()
	if event_state.has("battle"):
		var eff: Dictionary = event_state["battle"]
		event_state.erase("battle")
		_event_battle(eff)
		return _ok()
	return leave_node()


# ------------------------------------------------------------------ 节点商店(黑市 / 零件铺)
func node_shop() -> Dictionary:
	return node_shops.get(pos, {})


func _ensure_node_shop(k: String, t: String) -> void:
	if node_shops.has(k):
		return
	node_shops[k] = {"type": t, "offers": [], "refreshes": 0}
	_roll_node_shop(node_shops[k])


func _roll_node_shop(st: Dictionary) -> void:
	var cfg: Dictionary = (chapter.get("shops", {}) as Dictionary).get(str(st["type"]), {})
	var offers: Array = []
	if str(st["type"]) == "shop_black":
		var pool: Array[String] = []
		for id: String in catalog.equipment_ids():
			if catalog.get_equipment(id).cost <= int(cfg.get("weapon_max_cost", 3)) and not id.begins_with("sample_"):
				pool.append(id)
		var prices: Dictionary = cfg.get("weapon_price", {})
		for i in range(int(cfg.get("weapons", 3))):
			if pool.is_empty():
				break
			var wid: String = pool[rng.randi() % pool.size()]
			pool.erase(wid)
			var c: int = catalog.get_equipment(wid).cost
			offers.append({"kind": "weapon", "id": wid, "price": int(prices.get(str(c), c * 2 + 1)), "sold": false})
		if cfg.has("repair"):
			var rp: Dictionary = cfg["repair"]
			offers.append({"kind": "repair", "id": "repair", "amount": int(rp.get("amount", 15)), "price": int(rp.get("price", 4)), "sold": false})
	var pk: Array = (catalog.meta.get("parts", {}) as Dictionary).keys()
	pk.sort()
	for j in range(int(cfg.get("parts", 0))):
		if pk.is_empty():
			break
		var pid: String = pk[rng.randi() % pk.size()]
		offers.append({"kind": "part", "id": pid, "price": int(part_def(pid).get("price", 3)), "sold": false})
	st["offers"] = offers


func node_shop_refresh_cost() -> int:
	var st: Dictionary = node_shop()
	var costs: Array = ((chapter.get("shops", {}) as Dictionary).get(str(st.get("type", "")), {}) as Dictionary).get("refresh", [2, 2, 3])
	var n: int = int(st.get("refreshes", 0))
	if st.is_empty() or n >= int(costs[2]):
		return -1
	return int(costs[0]) + int(costs[1]) * n


func node_shop_refresh() -> Dictionary:
	if phase != "shop":
		return _fail("ui.err.not_now")
	var cost: int = node_shop_refresh_cost()
	if cost < 0:
		return _fail("ui.err.no_refresh")
	if gold < cost:
		return _fail("ui.err.no_gold")
	gold -= cost
	var st: Dictionary = node_shop()
	st["refreshes"] = int(st["refreshes"]) + 1
	_roll_node_shop(st)
	_changed("node_shop")
	return _ok()


func node_shop_buy(i: int) -> Dictionary:
	if phase != "shop":
		return _fail("ui.err.not_now")
	var offers: Array = node_shop().get("offers", [])
	if i < 0 or i >= offers.size() or bool(offers[i]["sold"]):
		return _fail("ui.err.sold")
	var of: Dictionary = offers[i]
	if gold < int(of["price"]):
		return _fail("ui.err.no_gold")
	match str(of["kind"]):
		"weapon":
			inventory.append(str(of["id"]))
		"part":
			if parts.size() >= part_cap():
				return _fail("ui.err.parts_full")
			parts.append(str(of["id"]))
		"repair":
			if truck_hp >= truck_max:
				return _fail("ui.err.truck_full")
			truck_hp = mini(truck_max, truck_hp + int(of.get("amount", 15)))
	gold -= int(of["price"])
	of["sold"] = true
	_changed("node_shop")
	return _ok()


## 零件铺回收零件(按售价的 sell_ratio)
func part_sell_price(pid: String) -> int:
	var cfg: Dictionary = (chapter.get("shops", {}) as Dictionary).get("shop_parts", {})
	return maxi(1, int(floor(float(part_def(pid).get("price", 2)) * float(cfg.get("sell_ratio", 0.5)))))


func node_shop_sell_part(i: int) -> Dictionary:
	if phase != "shop" or str(node_shop().get("type", "")) != "shop_parts" or i < 0 or i >= parts.size():
		return _fail("ui.err.not_now")
	gold += part_sell_price(parts[i])
	parts.remove_at(i)
	_changed("node_shop")
	return _ok()


# ------------------------------------------------------------------ 卡车零件
func part_def(pid: String) -> Dictionary:
	return (catalog.meta.get("parts", {}) as Dictionary).get(pid, {})


func part_cap() -> int:
	return int(catalog.meta.get("part_cap", 5))


## 移动类零件能去的格点(必须有节点)：line = 上下左右直线 range 格内；ring = 周围一圈 8 格。可以越过未完成/未观测的节点
func part_targets(i: int) -> Array[String]:
	var out: Array[String] = []
	if i < 0 or i >= parts.size():
		return out
	var pd: Dictionary = part_def(parts[i])
	if str(pd.get("kind", "")) != "move":
		return out
	var c0: Vector2i = ChapterMap.cell(pos)
	var rg: int = int(pd.get("range", 1))
	var cand: Array[Vector2i] = []
	if str(pd.get("shape", "")) == "line":
		for d: Vector2i in ChapterMap.DIRS:
			for k in range(1, rg + 1):
				cand.append(c0 + d * k)
	else:
		for dy in range(-rg, rg + 1):
			for dx in range(-rg, rg + 1):
				if dx != 0 or dy != 0:
					cand.append(c0 + Vector2i(dx, dy))
	for c: Vector2i in cand:
		var k2: String = ChapterMap.key(c)
		if not gnode(k2).is_empty():
			out.append(k2)
	return out


## 观测卡车周围 radius 格(曼哈顿距离)内还没观测到的节点(侦察无人机 / 事件效果 reveal)；返回新观测到几个
func reveal_around(radius: int) -> int:
	var n := 0
	var c0: Vector2i = ChapterMap.cell(pos)
	for k: String in (gmap.get("nodes", {}) as Dictionary).keys():
		var c: Vector2i = ChapterMap.cell(k)
		if absi(c.x - c0.x) + absi(c.y - c0.y) <= radius and str(gnode(k)["state"]) == "hidden":
			gnode(k)["state"] = "seen"
			n += 1
	return n


## 用一个零件：ap = 立刻加行动力；reveal = 观测周围；move = 跳到 target(扣 cost 行动力，算步数)，然后照常进入那个节点
func use_part(i: int, target: String = "") -> Dictionary:
	if phase != "map" or not is_grid() or i < 0 or i >= parts.size():
		return _fail("ui.err.not_now")
	var pd: Dictionary = part_def(parts[i])
	match str(pd.get("kind", "")):
		"ap":
			ap += int(pd.get("ap", 1))
			parts.remove_at(i)
			_changed("part")
			return _ok()
		"reveal":
			reveal_around(int(pd.get("radius", 2)))
			parts.remove_at(i)
			_changed("part")
			return _ok()
		"move":
			if not part_targets(i).has(target):
				return _fail("ui.err.bad_target")
			var cost: int = int(pd.get("cost", 1))
			if cost > ap:
				return _fail("ui.err.no_ap")
			parts.remove_at(i)
			ap -= cost
			steps += cost
			pos = target
			if str(gnode(target)["state"]) == "hidden":
				gnode(target)["state"] = "seen"
			_observe()
			return _enter_node()
	return _fail("ui.err.not_now")
