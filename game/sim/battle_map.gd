class_name BattleMap
extends RefCounted
## 战斗地图(纯逻辑)：GC.MAP_W × GC.MAP_H 的格子，每格 GC.CELL 米，原点在地图中心。
## 格子类型：
##   FREE  空地
##   LOW   矮的断壁残垣：挡移动与寻路，不挡视线
##   HIGH  高的断壁残垣(含终点祭坛)：挡移动，也挡远程索敌与弹道
##   TRUCK 工坊卡车：挡移动；是否挡视线由 truck_blocks_los(team) 决定(卡车改装接口)
## 卡车的位置 / 朝向 / 我方部署区(truck_rect / truck_rot / deploy_rect)来自布局里 TruckLayout.write_into 写的键(Run.truck_layout)，
## 没写 = 初始摆法(GC.TRUCK_RECT / GC.DEPLOY_RECT)。能放棋子的格子 = 部署区内、没有卡车和地形占着(is_deploy_cell)。
## 地形效果(第一章·红之章起)：
##   障碍物可以带 terrain = "burning"(燃烧废墟：占格，周围的棋子会被施加【燃烧】)；不带的就是普通的断壁残垣(死灰废墟)
##   embers 余烬地块：不占格、不挡路，棋子踩上去被施加【燃烧】，然后这块余烬熄灭清空(lit = false)
##   frost 寒雾地块(紫之章)：不占格、不挡路，站在上面的棋子每秒被施加【寒气】(OnTerrainTick[frost])，不会消失
##   hazards 战场机制(事件战斗的专属战场，配置见 tools/author_events.py 的 ARENAS)：按时刻表冲过战场的电车 / 周期性喷发的喷泉；
##     时刻表由 Battle 推进(Battle.hazards)，这里只存配置
##   打碎(圣战节点·裂地猛击)：障碍物 / 寒雾标 destroyed = true(数组下标就是表现层的 id，不删)，障碍物占的格子清空；余烬直接熄灭
##   效果本身由 Battle 发出地形事件(OnTerrainTick / OnTerrainEnter / OnTerrainHit)，交给每个单位身上的地形触发器走管线，地图只管"在不在范围里"。
## 棋子在战斗中仍是连续坐标，地图只负责：能不能走、看不看得见、怎么绕路。

const FREE := 0
const LOW := 1
const HIGH := 2
const TRUCK := 3

var w: int = GC.MAP_W
var h: int = GC.MAP_H
var cells: PackedByteArray = PackedByteArray()
var obstacles: Array[Dictionary] = []      # {rect: Rect2i, kind: LOW/HIGH, style: String, terrain: ""/"burning"}
var embers: Array[Dictionary] = []         # 余烬地块 {id:int, rect: Rect2i, style: String, lit: bool}
var frost: Array[Dictionary] = []          # 寒雾地块 {id:int, rect: Rect2i, style: String}
var hazards: Array = []                    # 战场机制的配置 [{type: sweep / eruption, id, tag, …}]
var truck_rect: Rect2i = GC.TRUCK_RECT
var truck_rot: int = 0                     # 卡车朝向(TruckLayout.rot)
var deploy_rect: Rect2i = GC.DEPLOY_RECT   # 我方部署区(含卡车格)
## 卡车改装接口：卡车默认对双方都是高掩体。设为 false = "卡车只遮挡敌人的远程攻击与弹道，不挡队友的"
var truck_blocks_ally_los: bool = true
var _astar: AStarGrid2D = null


static func empty() -> BattleMap:
	var m := BattleMap.new()
	m.cells.resize(m.w * m.h)
	m._stamp(m.truck_rect, TRUCK)
	return m


## layout: {"obstacles":[{"x","y","w","h","kind":"low"/"high","style","terrain"}], "embers":[{"x","y","w","h","style"}],
##          "hazards":[战场机制], "truck": bool(默认 true；测试用 false 得到空地图)}
static func from_layout(layout: Dictionary) -> BattleMap:
	var m := BattleMap.new()
	m.cells.resize(m.w * m.h)
	var tl: TruckLayout = TruckLayout.from_layout(layout)
	m.truck_rect = tl.truck
	m.truck_rot = tl.rot
	m.deploy_rect = tl.deploy
	if not bool(layout.get("truck", true)):
		m.truck_rect = Rect2i(-100, -100, 0, 0)
	else:
		m._stamp(m.truck_rect, TRUCK)
	for o: Variant in layout.get("obstacles", []):
		var d: Dictionary = o
		var r := Rect2i(int(d["x"]), int(d["y"]), int(d.get("w", 1)), int(d.get("h", 1)))
		var k: int = HIGH if str(d.get("kind", "low")) == "high" else LOW
		m.add_obstacle(r, k, str(d.get("style", "")), str(d.get("terrain", "")))
	for e: Variant in layout.get("embers", []):
		var ed: Dictionary = e
		m.add_ember(Rect2i(int(ed["x"]), int(ed["y"]), int(ed.get("w", 1)), int(ed.get("h", 1))), str(ed.get("style", "")))
	for fr: Variant in layout.get("frost", []):
		var fd: Dictionary = fr
		m.add_frost(Rect2i(int(fd["x"]), int(fd["y"]), int(fd.get("w", 1)), int(fd.get("h", 1))), str(fd.get("style", "")))
	m.hazards = (layout.get("hazards", []) as Array).duplicate(true)
	return m


func add_obstacle(r: Rect2i, kind: int, style: String, terrain: String = "") -> void:
	obstacles.append({"rect": r, "kind": kind, "style": style, "terrain": terrain})
	_stamp(r, kind)
	_astar = null


## 打不碎的障碍物(战场机制的核心 / 终点祭坛)
const UNBREAKABLE := ["altar", "burn_fountain"]


## 打碎第 i 个障碍物：格子清空(和别的障碍物 / 卡车重叠的格子照旧)，寻路重建
func destroy_obstacle(i: int) -> void:
	if i < 0 or i >= obstacles.size() or bool(obstacles[i].get("destroyed", false)):
		return
	obstacles[i]["destroyed"] = true
	_stamp(obstacles[i]["rect"], FREE)
	for o: Dictionary in obstacles:
		if not bool(o.get("destroyed", false)):
			_stamp(o["rect"], int(o["kind"]))
	if has_truck():
		_stamp(truck_rect, TRUCK)
	_astar = null


func destroy_frost(id: int) -> void:
	if id >= 0 and id < frost.size():
		frost[id]["destroyed"] = true


func add_ember(r: Rect2i, style: String) -> int:
	embers.append({"id": embers.size(), "rect": r, "style": style, "lit": true})
	return embers.size() - 1


func add_frost(r: Rect2i, style: String) -> int:
	frost.append({"id": frost.size(), "rect": r, "style": style})
	return frost.size() - 1


## 单位(圆心附近)踩着的寒雾地块；没有返回 -1
func frost_at(p: Vector2, radius: float) -> int:
	for f: Dictionary in frost:
		if not bool(f.get("destroyed", false)) and _dist_to_rect(p, rect_world(f["rect"])) <= radius * 0.35:
			return int(f["id"])
	return -1


## 盖着格子 c 的余烬地块(不管亮不亮)；没有返回 -1
func ember_at_cell(c: Vector2i) -> int:
	for e: Dictionary in embers:
		if (e["rect"] as Rect2i).has_point(c):
			return int(e["id"])
	return -1


## 格子 c 能不能新烧起一块余烬：在地图里、没有障碍 / 卡车
func ember_cell_ok(c: Vector2i) -> bool:
	return in_bounds(c) and cells[c.y * w + c.x] == FREE


## 现在亮着的余烬占了多少格
func lit_ember_cells() -> int:
	var n := 0
	for e: Dictionary in embers:
		if bool(e["lit"]):
			n += (e["rect"] as Rect2i).get_area()
	return n


func _stamp(r: Rect2i, kind: int) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if in_bounds(Vector2i(x, y)):
				cells[y * w + x] = kind


func to_layout() -> Dictionary:
	var obs: Array = []
	for o: Dictionary in obstacles:
		if bool(o.get("destroyed", false)):
			continue
		var r: Rect2i = o["rect"]
		var od := {"x": r.position.x, "y": r.position.y, "w": r.size.x, "h": r.size.y,
			"kind": "high" if int(o["kind"]) == HIGH else "low", "style": o["style"]}
		if str(o.get("terrain", "")) != "":
			od["terrain"] = str(o["terrain"])
		obs.append(od)
	var out := {"obstacles": obs}
	if not embers.is_empty():
		var em: Array = []
		for e: Dictionary in embers:
			var er: Rect2i = e["rect"]
			em.append({"x": er.position.x, "y": er.position.y, "w": er.size.x, "h": er.size.y, "style": e["style"]})
		out["embers"] = em
	if not frost.is_empty():
		var fl: Array = []
		for f: Dictionary in frost:
			if bool(f.get("destroyed", false)):
				continue
			var fr: Rect2i = f["rect"]
			fl.append({"x": fr.position.x, "y": fr.position.y, "w": fr.size.x, "h": fr.size.y, "style": f["style"]})
		out["frost"] = fl
	return out


# ---------------------------------------------------------------- 地形效果
## 燃烧废墟的"周围"：离废墟外缘不超过 BURN_REACH 米(加上单位半径)——基本就是紧挨着它的一圈格子(含斜角)
const BURN_REACH := 0.6


func has_terrain() -> bool:
	if not embers.is_empty() or not hazards.is_empty() or not frost.is_empty():
		return true
	for o: Dictionary in obstacles:
		if str(o.get("terrain", "")) != "" and not bool(o.get("destroyed", false)):
			return true
	return false


## 半径 radius 的单位是否在某块燃烧废墟的周围
func near_burning(p: Vector2, radius: float) -> bool:
	for o: Dictionary in obstacles:
		if str(o.get("terrain", "")) == "burning" and not bool(o.get("destroyed", false)) and _dist_to_rect(p, rect_world(o["rect"])) <= radius + BURN_REACH:
			return true
	return false


## 单位(圆心附近)踩着的、还在燃烧的余烬地块；没有返回 -1
func lit_ember_at(p: Vector2, radius: float) -> int:
	for e: Dictionary in embers:
		if bool(e["lit"]) and _dist_to_rect(p, rect_world(e["rect"])) <= radius * 0.35:
			return int(e["id"])
	return -1


func put_out_ember(id: int) -> void:
	if id >= 0 and id < embers.size():
		embers[id]["lit"] = false


## 喷泉的火弧把一块余烬地块重新点燃
func relight_ember(id: int) -> void:
	if id >= 0 and id < embers.size():
		embers[id]["lit"] = true


## 半径 radius 的单位有没有碰到第 id 块余烬地块(火弧砸下来的那一下：身体挨着就算，比"踩上去"宽)
func touches_ember(id: int, p: Vector2, radius: float) -> bool:
	return id >= 0 and id < embers.size() and _dist_to_rect(p, rect_world(embers[id]["rect"])) <= radius * 0.6


## 格子矩形 → 世界坐标矩形
func rect_world(r: Rect2i) -> Rect2:
	var a: Vector2 = GC.cell_to_world(r.position.x, r.position.y) - Vector2(GC.CELL, GC.CELL) * 0.5
	return Rect2(a, Vector2(r.size) * GC.CELL)


# ---------------------------------------------------------------- 查询
func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < w and c.y < h


func kind_at(c: Vector2i) -> int:
	return int(cells[c.y * w + c.x]) if in_bounds(c) else HIGH


func blocks_move(c: Vector2i) -> bool:
	return kind_at(c) != FREE


func truck_blocks_los(team: int) -> bool:
	return team != GC.TEAM_PLAYER or truck_blocks_ally_los


## 某阵营的远程攻击/弹道是否被这一格挡住
func blocks_los(c: Vector2i, team: int) -> bool:
	match kind_at(c):
		HIGH:
			return true
		TRUCK:
			return truck_blocks_los(team)
	return false


func has_truck() -> bool:
	return truck_rect.size.x > 0 and truck_rect.size.y > 0


## 卡车中心(世界坐标)；没有卡车 = 地图中心
func truck_center() -> Vector2:
	return GC.rect_center(truck_rect) if has_truck() else Vector2.ZERO


## 能放我方棋子的格子：部署区内、在地图里、没有卡车 / 地形占着
func is_deploy_cell(c: Vector2i) -> bool:
	return deploy_rect.has_point(c) and in_bounds(c) and cells[c.y * w + c.x] == FREE


func deploy_cells() -> Array[Vector2i]:
	var r: Array[Vector2i] = []
	for y in range(deploy_rect.position.y, deploy_rect.end.y):
		for x in range(deploy_rect.position.x, deploy_rect.end.x):
			if is_deploy_cell(Vector2i(x, y)):
				r.append(Vector2i(x, y))
	return r


## 卡车占的矩形(世界坐标，米)
func truck_world_rect() -> Rect2:
	var a: Vector2 = GC.cell_to_world(truck_rect.position.x, truck_rect.position.y) - Vector2(GC.CELL, GC.CELL) * 0.5
	return Rect2(a, Vector2(truck_rect.size) * GC.CELL)


func point_free(p: Vector2) -> bool:
	return not blocks_move(GC.world_to_cell(p))


## 圆(单位)是否与任何挡路格子重叠
func circle_free(p: Vector2, radius: float) -> bool:
	var c0: Vector2i = GC.world_to_cell(p - Vector2(radius, radius))
	var c1: Vector2i = GC.world_to_cell(p + Vector2(radius, radius))
	for y in range(c0.y, c1.y + 1):
		for x in range(c0.x, c1.x + 1):
			var c := Vector2i(x, y)
			if blocks_move(c) and _cell_rect(c).has_point(p):
				return false
			if blocks_move(c) and _dist_to_rect(p, _cell_rect(c)) < radius:
				return false
	return true


func _cell_rect(c: Vector2i) -> Rect2:
	var o: Vector2 = GC.cell_to_world(c.x, c.y) - Vector2(GC.CELL, GC.CELL) * 0.5
	return Rect2(o, Vector2(GC.CELL, GC.CELL))


static func _dist_to_rect(p: Vector2, r: Rect2) -> float:
	var q := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
	return p.distance_to(q)


## 视线：从 a 到 b 的线段有没有穿过挡住 team 视线的格子(每 0.15 米采样一次；两端所在格不算)
func has_los(a: Vector2, b: Vector2, team: int) -> bool:
	var d: float = a.distance_to(b)
	var n: int = maxi(1, int(ceil(d / 0.15)))
	var ca: Vector2i = GC.world_to_cell(a)
	var cb: Vector2i = GC.world_to_cell(b)
	for i in range(1, n):
		var c: Vector2i = GC.world_to_cell(a.lerp(b, float(i) / float(n)))
		if c == ca or c == cb:
			continue
		if blocks_los(c, team):
			return false
	return true


## 移动：半径 radius 的圆沿 a→b 平移时会不会撞上挡路格子
func path_clear(a: Vector2, b: Vector2, radius: float) -> bool:
	var d: float = a.distance_to(b)
	var n: int = maxi(1, int(ceil(d / 0.2)))
	for i in range(1, n + 1):
		if not circle_free(a.lerp(b, float(i) / float(n)), radius * 0.92):
			return false
	return true


# ---------------------------------------------------------------- 寻路
func _ensure_astar() -> void:
	if _astar != null:
		return
	_astar = AStarGrid2D.new()
	_astar.region = Rect2i(0, 0, w, h)
	_astar.cell_size = Vector2(1, 1)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.update()
	for y in range(h):
		for x in range(w):
			if blocks_move(Vector2i(x, y)):
				_astar.set_point_solid(Vector2i(x, y), true)


## 从 a 走到 b 的路点(世界坐标，不含起点)。b 在障碍物里时走到它旁边最近的空地。找不到路返回空数组。
func find_path(a: Vector2, b: Vector2) -> PackedVector2Array:
	_ensure_astar()
	var ca: Vector2i = nearest_free_cell(GC.world_to_cell(a))
	var cb: Vector2i = nearest_free_cell(GC.world_to_cell(b))
	var out := PackedVector2Array()
	if ca == Vector2i(-1, -1) or cb == Vector2i(-1, -1):
		return out
	var ids: Array[Vector2i] = _astar.get_id_path(ca, cb)
	for i in range(1, ids.size()):
		out.append(GC.cell_to_world(ids[i].x, ids[i].y))
	if ids.size() >= 1 and not blocks_move(GC.world_to_cell(b)):
		if out.is_empty():
			out.append(b)
		else:
			out[out.size() - 1] = b
	return out


## 离 c 最近的可走格子(按曼哈顿圈向外找)
func nearest_free_cell(c: Vector2i) -> Vector2i:
	if in_bounds(c) and not blocks_move(c):
		return c
	for r in range(1, maxi(w, h)):
		var best := Vector2i(-1, -1)
		var bd := 1e9
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var q := Vector2i(c.x + dx, c.y + dy)
				if in_bounds(q) and not blocks_move(q):
					var dd: float = Vector2(dx, dy).length()
					if dd < bd:
						bd = dd
						best = q
		if best.x >= 0:
			return best
	return Vector2i(-1, -1)


## 出生点吸附：离 p 最近、未被占用的空格中心
func snap_free_cell(p: Vector2, taken: Array) -> Vector2:
	var c0: Vector2i = GC.world_to_cell(GC.clamp_to_arena(p, 0.5))
	for r in range(0, maxi(w, h)):
		var best := Vector2i(-1, -1)
		var bd := 1e9
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var q := Vector2i(c0.x + dx, c0.y + dy)
				if in_bounds(q) and not blocks_move(q) and not taken.has(q):
					var dd: float = GC.cell_to_world(q.x, q.y).distance_to(p)
					if dd < bd:
						bd = dd
						best = q
		if best.x >= 0:
			return GC.cell_to_world(best.x, best.y)
	return p


## 把圆推出挡路格子(碰撞解算)；返回新位置
func push_out(p: Vector2, radius: float) -> Vector2:
	var q: Vector2 = p
	for _it in range(3):
		var moved := false
		var c0: Vector2i = GC.world_to_cell(q - Vector2(radius, radius))
		var c1: Vector2i = GC.world_to_cell(q + Vector2(radius, radius))
		for y in range(c0.y, c1.y + 1):
			for x in range(c0.x, c1.x + 1):
				var c := Vector2i(x, y)
				if not blocks_move(c) or not in_bounds(c):
					continue
				var r: Rect2 = _cell_rect(c)
				var cp := Vector2(clampf(q.x, r.position.x, r.end.x), clampf(q.y, r.position.y, r.end.y))
				var dv: Vector2 = q - cp
				var dist: float = dv.length()
				if dist >= radius:
					continue
				if dist < 0.0001:
					# 圆心落进格子里：往最近的一条边推出去
					var left: float = q.x - r.position.x
					var right: float = r.end.x - q.x
					var top: float = q.y - r.position.y
					var bottom: float = r.end.y - q.y
					var m: float = minf(minf(left, right), minf(top, bottom))
					if m == left:
						q.x = r.position.x - radius
					elif m == right:
						q.x = r.end.x + radius
					elif m == top:
						q.y = r.position.y - radius
					else:
						q.y = r.end.y + radius
				else:
					q = cp + dv / dist * radius
				moved = true
		if not moved:
			break
	return GC.clamp_to_arena(q, radius)


## 卡车四周可以"钻进去"的空地(敌人涌入卡车时的目的地)
func truck_entry_points() -> Array[Vector2]:
	var r: Array[Vector2] = []
	var tr: Rect2i = truck_rect.grow(1)
	for y in range(tr.position.y, tr.end.y):
		for x in range(tr.position.x, tr.end.x):
			var c := Vector2i(x, y)
			if truck_rect.has_point(c) or not in_bounds(c) or blocks_move(c):
				continue
			r.append(GC.cell_to_world(c.x, c.y))
	return r


## 离卡车外缘的距离
func dist_to_truck(p: Vector2) -> float:
	var a: Vector2 = GC.cell_to_world(truck_rect.position.x, truck_rect.position.y) - Vector2(GC.CELL, GC.CELL) * 0.5
	return _dist_to_rect(p, Rect2(a, Vector2(truck_rect.size) * GC.CELL))


## 从 start 出发能走到的格子数(用于生成时保证连通)
func reachable_count(start: Vector2i) -> int:
	if blocks_move(start):
		return 0
	var seen := {start: true}
	var q: Array[Vector2i] = [start]
	while not q.is_empty():
		var c: Vector2i = q.pop_back()
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if in_bounds(n) and not blocks_move(n) and not seen.has(n):
				seen[n] = true
				q.append(n)
	return seen.size()


func free_count() -> int:
	var n := 0
	for i in range(cells.size()):
		if cells[i] == FREE:
			n += 1
	return n
