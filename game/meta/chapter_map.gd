class_name ChapterMap
extends RefCounted
## 方格网章节地图(第一章起；第零章还是一条直线)。移动机制参照《明日方舟·沉沦者的黑流树海》：
##  · 地图 = W×H 的格点，节点放在格点上，路只连上下左右(四向连通)。连线很稀疏：一棵随机生成树(长走廊 + 死胡同) + 少量回路
##  · 整体轮廓不是矩形：只用一条弯弯曲曲的"带子"里的格点(mask = band：每一列的中心与宽度随机起伏)，像一片城区的形状
##    (格点只是逻辑坐标；大地图上的位置由表现层弯曲、错开，见 CityOverworld)
##  · 卡车受「行动力」限制：沿路每经过 1 个格点扣 1 点；不能穿过还没完成的节点(只能停在它上面)；
##    完成的节点变成空地，可以穿行；商店完成后还能再进
##  · 观测：从卡车出发、中间只经过已完成节点就能走到的节点会被观测到(看得见类型)；更远的只看得到"那里有个节点"；
##    首领一开始就标在地图上
##  · 行动力用完还没打倒首领 → 追猎(Run 负责)
## 节点类型(由离起点的步数决定，类似《杀戮尖塔》按层数排房间)：
##   start 起点 / fight 普通作战 / elite 精英作战 / boss 首领 / rest 修整 / event 事件 / shop_black 黑市 / shop_parts 零件铺
##   首领前一格固定是修整；其它格子在一定步数之后按权重随机(所以"其他步也有概率出现修整")。
## 空岛(第二章-A·紫之章，mask = island)：岛是一片椭圆形的格点；cfg.scar 时一道斜着的剑痕把岛切成两半
##   (dir 0：沿 x - y，dir 1：沿 x + y)，两边各自长一棵生成树，只在 bridges 处(沿剑痕均匀挑的几对相邻格点)架桥相通；
##   起点在岛边缘、剑痕的另一侧——要过桥才能打到首领。
##   冰山(cfg.mountain)：首领格(岛中心往背离剑痕的方向挪 2 格)四周一圈 8 格是山体；只有一条上山的路：从离剑痕最远的那个角上山，
##   沿着山腰绕 ring 格(一格比一格高：节点 h = 1, 2, …)，最后登顶(首领，h = ring + 1)；圈上其余格子没有节点。
##   结果里带 island / scar{dir, bridges} / mountain{center, path, entry, height}
## 纯逻辑、可复现：同一 seed + 同一参数 = 同一张地图。

const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const TYPES := ["start", "fight", "elite", "boss", "rest", "event", "shop_black", "shop_parts"]


static func key(c: Vector2i) -> String:
	return "%d,%d" % [c.x, c.y]


static func cell(k: String) -> Vector2i:
	var p: PackedStringArray = k.split(",")
	return Vector2i(int(p[0]), int(p[1]))


## cfg: {w, h, nodes(目标节点数), loops(额外回路数), min_path, max_path(起点到首领的最短步数范围), ap_spare(行动力 = 最短步数 + 这么多),
##       weights:{类型: 权重}, min_depth:{类型: 最少离起点几步}, min_count:{类型: 至少几个}, max_count:{类型: 至多几个}}
## 返回 {w, h, start, boss, nodes:{key:{x,y,type,state,depth}}, edges:[[k,k]...], path_len, ap}
static func generate(cfg: Dictionary, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var last: Dictionary = {}
	for attempt in range(80):
		var res: Dictionary = _try(cfg, rng)
		if res.is_empty():
			continue
		last = res
		var d: int = int(res["path_len"])
		if d >= int(cfg.get("min_path", 6)) and d <= int(cfg.get("max_path", 10)):
			break
	last["seed"] = seed_value
	_assign_types(last, cfg, rng)
	last["ap"] = int(last["path_len"]) + int(cfg.get("ap_spare", 4))
	return last


static func _try(cfg: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var w: int = int(cfg.get("w", 7))
	var h: int = int(cfg.get("h", 5))
	var island: bool = str(cfg.get("mask", "")) == "island"
	var dome: bool = str(cfg.get("mask", "")) == "dome"
	var allowed: Dictionary = _mask(cfg, w, h, rng)
	var start := Vector2i(0, rng.randi_range(1, h - 2))
	var boss := Vector2i(w - 1, rng.randi_range(1, h - 2))
	if not allowed.is_empty() and not island:
		start = _mid_allowed(allowed, 0, h)
		boss = _mid_allowed(allowed, w - 1, h)
	# 空岛：首领在岛中央(有剑痕时往背离剑痕的方向挪 2 格，给冰山留地方)；剑痕斜着把岛切成两半；起点在岛边缘、剑痕的另一侧
	var sides: Dictionary = {}
	var scar: Dictionary = {}
	var mountain: Dictionary = {}
	var mcells: Dictionary = {}
	if island:
		boss = Vector2i(w / 2, h / 2)
		if not (cfg.get("scar", {}) as Dictionary).is_empty():
			var sdir: int = rng.randi_range(0, 1)
			scar = {"dir": sdir, "bridges": []}
			if not (cfg.get("mountain", {}) as Dictionary).is_empty():
				boss += Vector2i(-1, 1) if sdir == 0 else Vector2i(-1, -1)
			for c0: Vector2i in allowed.keys():
				sides[c0] = scar_side(c0, sdir, w)
		allowed[boss] = true
		if not sides.is_empty():
			sides[boss] = scar_side(boss, int(scar["dir"]), w)
		if not (cfg.get("mountain", {}) as Dictionary).is_empty():
			mountain = _mountain(boss, scar, w, int((cfg["mountain"] as Dictionary).get("ring", 4)), rng)
			for mc0: Vector2i in mountain["cells"]:
				mcells[mc0] = true
				allowed[mc0] = true
				if not sides.is_empty():
					sides[mc0] = scar_side(mc0, int(scar["dir"]), w)
		var ang: float = rng.randf() * TAU
		var pref := Vector2(cos(ang), sin(ang))
		var best := Vector2i(-1, -1)
		var bs := -1e9
		for c1: Vector2i in allowed.keys():
			if c1 == boss or mcells.has(c1) or (not sides.is_empty() and int(sides[c1]) == int(sides[boss])):
				continue
			var off := Vector2(c1 - boss)
			var sc: float = off.length() * 2.0 + off.normalized().dot(pref)
			if sc > bs:
				bs = sc
				best = c1
		if best.x >= 0:
			start = best
	if dome:
		# 穹顶箱庭(第一章-B·蓝之章)：首领在城北(信标之下)，起点在最南的边缘，都尽量靠中线
		boss = _edge_allowed(allowed, w, -1)
		start = _edge_allowed(allowed, w, 1)
	# 1) 随机深度优先生成树(迷宫式：长走廊 + 分岔)；有剑痕时两边各自长一棵，再用桥连起来；冰山的格子先不进树
	var adj: Dictionary = {}
	for y in range(h):
		for x in range(w):
			var cc := Vector2i(x, y)
			if (allowed.is_empty() or allowed.has(cc)) and not mcells.has(cc):
				adj[cc] = []
	var seen := {}
	_grow_tree(adj, seen, start, sides, rng)
	if not sides.is_empty():
		var root0: Vector2i = boss
		if not mcells.is_empty():
			# 冰山不在树里：首领那一侧从离冰山最近的普通格子开始长
			var bd0 := 1e9
			for ca: Vector2i in adj.keys():
				if int(sides[ca]) == int(sides[boss]) and float((ca - boss).length_squared()) < bd0:
					bd0 = float((ca - boss).length_squared())
					root0 = ca
		_grow_tree(adj, seen, root0, sides, rng)
	var protected := {start: true, boss: true}
	if not mountain.is_empty():
		# 冰山：上山的路(角 → 沿山腰绕 → 山顶)是一条固定的链，只在起点角上接一条进山的路(不对着剑痕的那一角)
		var path: Array = mountain["path"]
		for i in range(path.size()):
			var pc: Vector2i = path[i]
			adj[pc] = []
			seen[pc] = true
			protected[pc] = true
		adj[boss] = []
		seen[boss] = true
		for i2 in range(path.size() - 1):
			(adj[path[i2]] as Array).append(path[i2 + 1])
			(adj[path[i2 + 1]] as Array).append(path[i2])
		(adj[path.back()] as Array).append(boss)
		(adj[boss] as Array).append(path.back())
		var corner: Vector2i = path[0]
		var ecands: Array[Vector2i] = []
		for d1: Vector2i in DIRS:
			var ec: Vector2i = corner + d1
			if adj.has(ec) and seen.has(ec) and not mcells.has(ec) and (sides.is_empty() or int(sides[ec]) == int(sides[boss])):
				ecands.append(ec)
		if ecands.is_empty():
			return {}
		var entry: Vector2i = ecands[rng.randi() % ecands.size()]
		(adj[entry] as Array).append(corner)
		(adj[corner] as Array).append(entry)
		protected[entry] = true
		mountain["entry"] = entry
	if not sides.is_empty():
		# 桥：沿剑痕均匀挑 bridges 对隔着剑痕相邻的格点连起来(固定的过河点)
		var cands: Array = []
		for a0: Vector2i in adj.keys():
			if not seen.has(a0) or int(sides[a0]) != 1:
				continue
			for d0: Vector2i in DIRS:
				var b0: Vector2i = a0 + d0
				if adj.has(b0) and seen.has(b0) and int(sides[b0]) == 0:
					cands.append([a0, b0, float(a0.x + a0.y) if int(scar["dir"]) == 0 else float(a0.x - a0.y)])
		if cands.is_empty():
			return {}
		cands.sort_custom(func(p: Array, q: Array) -> bool: return float(p[2]) < float(q[2]))
		var nb: int = clampi(int((cfg["scar"] as Dictionary).get("bridges", 2)), 1, cands.size())
		var used := {}
		for i in range(nb):
			var target: float = lerpf(float(cands[0][2]), float(cands[cands.size() - 1][2]), (float(i) + 0.5) / float(nb))
			var bi := -1
			var bd := 1e9
			for j in range(cands.size()):
				var dd: float = absf(float(cands[j][2]) - target)
				if not used.has(j) and dd < bd:
					bd = dd
					bi = j
			if bi < 0:
				break
			used[bi] = true
			var a2: Vector2i = cands[bi][0]
			var b2: Vector2i = cands[bi][1]
			(adj[a2] as Array).append(b2)
			(adj[b2] as Array).append(a2)
			protected[a2] = true
			protected[b2] = true
			(scar["bridges"] as Array).append([key(a2), key(b2)])
	# 2) 少量回路(不跨剑痕)
	var loops: int = int(cfg.get("loops", 4))
	var guard := 0
	while loops > 0 and guard < 400:
		guard += 1
		var a := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(0, h - 1))
		var b: Vector2i = a + DIRS[rng.randi() % 4]
		if not adj.has(a) or not adj.has(b) or (adj[a] as Array).has(b) or not seen.has(a) or not seen.has(b):
			continue
		if not sides.is_empty() and int(sides[a]) != int(sides[b]):
			continue
		if mcells.has(a) or mcells.has(b):
			continue
		(adj[a] as Array).append(b)
		(adj[b] as Array).append(a)
		loops -= 1
	# 3) 剪掉一些死胡同的末端，节点数降到目标值(起点、首领、桥头不剪)
	# 没被生成树连上的格点(带子断开时)直接去掉
	for c5: Vector2i in adj.keys():
		if not seen.has(c5):
			adj.erase(c5)
	var want: int = int(cfg.get("nodes", w * h - 8))
	var alive: int = adj.size()
	guard = 0
	while alive > want and guard < 2000:
		guard += 1
		var leaves: Array[Vector2i] = []
		for c2: Vector2i in adj.keys():
			if not protected.has(c2) and (adj[c2] as Array).size() == 1:
				leaves.append(c2)
		if leaves.is_empty():
			break
		var lf: Vector2i = leaves[rng.randi() % leaves.size()]
		var other: Vector2i = (adj[lf] as Array)[0]
		(adj[other] as Array).erase(lf)
		adj.erase(lf)
		alive -= 1
	# 4) 起点到首领的最短步数
	var dist: Dictionary = _bfs(adj, start)
	if not dist.has(boss):
		return {}
	var nodes := {}
	for c3: Vector2i in adj.keys():
		nodes[key(c3)] = {"x": c3.x, "y": c3.y, "type": "fight", "state": "hidden", "depth": int(dist.get(c3, 99))}
	if not mountain.is_empty():
		var mpath: Array = mountain["path"]
		for i3 in range(mpath.size()):
			nodes[key(mpath[i3])]["h"] = i3 + 1
		nodes[key(boss)]["h"] = mpath.size() + 1
	var edges: Array = []
	for c4: Vector2i in adj.keys():
		for n2: Vector2i in adj[c4]:
			if c4.x < n2.x or (c4.x == n2.x and c4.y < n2.y):
				edges.append([key(c4), key(n2)])
	var out := {"w": w, "h": h, "start": key(start), "boss": key(boss), "nodes": nodes, "edges": edges, "path_len": int(dist[boss])}
	if island:
		out["island"] = true
	if dome:
		out["dome"] = true
	if not scar.is_empty():
		out["scar"] = scar
	if not mountain.is_empty():
		var pk: Array = []
		for pc2: Vector2i in mountain["path"]:
			pk.append(key(pc2))
		out["mountain"] = {"center": key(boss), "path": pk, "entry": key(mountain["entry"]), "height": pk.size() + 1}
	return out


## 冰山：首领格 mc 四周一圈 8 格(顺时针)。上山的路从离剑痕最远的那个角开始(没有剑痕就随机一个角)，顺时针或逆时针沿着圈走 ring 格
## (ring 取偶数：角 → 边 → 角 → 边，最后一格和山顶相邻)，然后登顶。返回 {center, path:[格…], cells:[圈 + 中心], corner}
static func _mountain(mc: Vector2i, scar: Dictionary, w: int, ring_n: int, rng: RandomNumberGenerator) -> Dictionary:
	var ring: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0)]
	var corner_i: int = [0, 2, 4, 6][rng.randi() % 4]
	if not scar.is_empty():
		var best := 1e9
		for ci: int in [0, 2, 4, 6]:
			var c: Vector2i = mc + ring[ci]
			var s: float = float(c.x - c.y) if int(scar["dir"]) == 0 else float(c.x + c.y - (w - 1))
			if s < best:
				best = s
				corner_i = ci
	var step: int = 1 if rng.randf() < 0.5 else -1
	var path: Array = []
	for i in range(ring_n):
		path.append(mc + ring[posmod(corner_i + i * step, 8)])
	var cells: Array = []
	for r: Vector2i in ring:
		cells.append(mc + r)
	cells.append(mc)
	return {"center": mc, "path": path, "cells": cells, "corner": path[0]}


## 剑痕的哪一侧：dir 0 按 x - y，dir 1 按 x + y - (w - 1)；> 0 的一侧 = 1，其余(含正中央的那条斜线)= 0
static func scar_side(c: Vector2i, dir: int, w: int) -> int:
	var s: int = (c.x - c.y) if dir == 0 else (c.x + c.y - (w - 1))
	return 1 if s > 0 else 0


## 从 root 出发在同一侧(sides 为空 = 不限)的格点上随机深度优先长一棵树
static func _grow_tree(adj: Dictionary, seen: Dictionary, root: Vector2i, sides: Dictionary, rng: RandomNumberGenerator) -> void:
	if not adj.has(root) or seen.has(root):
		return
	seen[root] = true
	var stack: Array[Vector2i] = [root]
	while not stack.is_empty():
		var c: Vector2i = stack.back()
		var opts: Array[Vector2i] = []
		for d: Vector2i in DIRS:
			var n: Vector2i = c + d
			if adj.has(n) and not seen.has(n) and (sides.is_empty() or int(sides[n]) == int(sides[c])):
				opts.append(n)
		if opts.is_empty():
			stack.pop_back()
			continue
		var nx: Vector2i = opts[rng.randi() % opts.size()]
		seen[nx] = true
		(adj[c] as Array).append(nx)
		(adj[nx] as Array).append(c)
		stack.append(nx)


## 带状轮廓：每一列一个中心 cy(x)(正弦起伏 + 随机) 和半宽 hw(x)；|y - cy| <= hw 的格点可用。
## 空岛轮廓(island)：以中心为圆心的椭圆(边缘微微起伏)。cfg.mask 不是这两种时不限制
static func _mask(cfg: Dictionary, w: int, h: int, rng: RandomNumberGenerator) -> Dictionary:
	var out := {}
	if str(cfg.get("mask", "")) == "dome":
		# 穹顶：一个圆(边缘略有随机)
		var cx0: float = float(w - 1) * 0.5
		var cy0: float = float(h - 1) * 0.5
		var rr: float = minf(cx0, cy0) + 0.45
		for x in range(w):
			for y in range(h):
				var u0: float = float(x) - cx0
				var v0: float = float(y) - cy0
				if u0 * u0 + v0 * v0 <= rr * rr + rng.randf_range(-0.3, 0.3):
					out[Vector2i(x, y)] = true
		return out
	if str(cfg.get("mask", "")) == "island":
		var cx: float = float(w - 1) * 0.5
		var cy: float = float(h - 1) * 0.5
		var rx: float = cx + 0.35
		var ry: float = cy + 0.35
		var ph: float = rng.randf() * TAU
		for x in range(w):
			for y in range(h):
				var u: float = (float(x) - cx) / rx
				var v: float = (float(y) - cy) / ry
				var wob: float = 0.1 * sin(atan2(v, u) * 3.0 + ph) + rng.randf_range(-0.06, 0.06)
				if u * u + v * v <= 1.0 + wob:
					out[Vector2i(x, y)] = true
		return out
	if str(cfg.get("mask", "")) != "band":
		return {}
	var ph: float = rng.randf() * TAU
	var amp: float = float(h) * 0.22
	for x in range(w):
		var cy: float = float(h - 1) * 0.5 + amp * sin(float(x) * 0.85 + ph) + rng.randf_range(-0.35, 0.35)
		var hw: float = rng.randf_range(1.6, 2.7) if x != 0 and x != w - 1 else rng.randf_range(1.2, 1.8)
		for y in range(h):
			if absf(float(y) - cy) <= hw:
				out[Vector2i(x, y)] = true
	return out


## 轮廓里最北(dir < 0)/最南(dir > 0)那一行里最靠中线的格点
static func _edge_allowed(allowed: Dictionary, w: int, dir: int) -> Vector2i:
	var best := Vector2i(-1, -1)
	var cx: float = float(w - 1) * 0.5
	for c: Vector2i in allowed.keys():
		if best.x < 0:
			best = c
			continue
		var better: bool = (c.y < best.y) if dir < 0 else (c.y > best.y)
		if better or (c.y == best.y and absf(float(c.x) - cx) < absf(float(best.x) - cx)):
			best = c
	return best


static func _mid_allowed(allowed: Dictionary, x: int, h: int) -> Vector2i:
	var ys: Array[int] = []
	for y in range(h):
		if allowed.has(Vector2i(x, y)):
			ys.append(y)
	return Vector2i(x, ys[ys.size() / 2]) if not ys.is_empty() else Vector2i(x, h / 2)


static func _bfs(adj: Dictionary, from: Vector2i) -> Dictionary:
	var dist := {from: 0}
	var q: Array[Vector2i] = [from]
	var i := 0
	while i < q.size():
		var c: Vector2i = q[i]
		i += 1
		for n: Vector2i in adj[c]:
			if not dist.has(n):
				dist[n] = int(dist[c]) + 1
				q.append(n)
	return dist


## 邻接表(key -> [key])
static func neighbors(m: Dictionary) -> Dictionary:
	var adj := {}
	for k: String in (m["nodes"] as Dictionary).keys():
		adj[k] = []
	for e: Array in m["edges"]:
		(adj[e[0]] as Array).append(e[1])
		(adj[e[1]] as Array).append(e[0])
	return adj


static func _assign_types(m: Dictionary, cfg: Dictionary, rng: RandomNumberGenerator) -> void:
	var nodes: Dictionary = m["nodes"]
	var adj: Dictionary = neighbors(m)
	nodes[m["start"]]["type"] = "start"
	nodes[m["start"]]["state"] = "done"
	nodes[m["boss"]]["type"] = "boss"
	nodes[m["boss"]]["state"] = "seen"
	# 首领前一格(离起点最近的那个邻居)固定是修整
	var pre := ""
	for n: String in adj[m["boss"]]:
		if pre == "" or int(nodes[n]["depth"]) < int(nodes[pre]["depth"]):
			pre = n
	if pre != "" and pre != m["start"]:
		nodes[pre]["type"] = "rest"
		nodes[pre]["fixed"] = true
	var weights: Dictionary = cfg.get("weights", {"fight": 46, "event": 18, "elite": 14, "rest": 7, "shop_black": 7, "shop_parts": 7})
	var min_depth: Dictionary = cfg.get("min_depth", {"elite": 3, "rest": 4, "shop_black": 2, "shop_parts": 2, "event": 2})
	var keys: Array = nodes.keys()
	keys.sort()
	for k: String in keys:
		var nd: Dictionary = nodes[k]
		if str(nd["type"]) != "fight" or bool(nd.get("fixed", false)):
			continue
		var dep: int = int(nd["depth"])
		var total := 0.0
		var cand: Array = []
		for t: String in weights.keys():
			if dep < int(min_depth.get(t, 0)):
				continue
			# 修整、商店不挨在一起
			if t != "fight" and t != "event" and t != "elite":
				var clash := false
				for n2: String in adj[k]:
					if str(nodes[n2]["type"]) == t:
						clash = true
				if clash:
					continue
			cand.append(t)
			total += float(weights[t])
		var roll: float = rng.randf() * total
		for t2: String in cand:
			roll -= float(weights[t2])
			if roll <= 0.0:
				nd["type"] = t2
				break
	# 数量下限 / 上限：不够的从合适深度的普通作战里改，多了的改回普通作战
	var max_count: Dictionary = cfg.get("max_count", {"elite": 4, "rest": 3, "shop_black": 2, "shop_parts": 2, "event": 6})
	var min_count: Dictionary = cfg.get("min_count", {"elite": 2, "shop_black": 1, "shop_parts": 1, "event": 2})
	for t3: String in max_count.keys():
		var have: Array = _of_type(nodes, t3, keys)
		while have.size() > int(max_count[t3]):
			var drop: String = have.pop_back()
			if bool(nodes[drop].get("fixed", false)):
				continue
			nodes[drop]["type"] = "fight"
	for t4: String in min_count.keys():
		var have2: int = _of_type(nodes, t4, keys).size()
		var pool: Array = []
		for k2: String in keys:
			if str(nodes[k2]["type"]) == "fight" and int(nodes[k2]["depth"]) >= int(min_depth.get(t4, 0)) and not bool(nodes[k2].get("fixed", false)):
				pool.append(k2)
		while have2 < int(min_count[t4]) and not pool.is_empty():
			var pick: String = pool[rng.randi() % pool.size()]
			pool.erase(pick)
			nodes[pick]["type"] = t4
			have2 += 1


static func _of_type(nodes: Dictionary, t: String, keys: Array) -> Array:
	var r: Array = []
	for k: String in keys:
		if str(nodes[k]["type"]) == t:
			r.append(k)
	return r
