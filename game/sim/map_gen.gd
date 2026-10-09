class_name MapGen
extends RefCounted
## 战斗地图的障碍物布局生成(纯逻辑、可复现)：同一 seed + 同一参数 = 同一张地图。
## 断壁残垣分两类，各有数种尺寸/款式(style 由表现层映射到不同的体素模型)：
##   矮(low，只挡移动)：碎石堆 1×1 / 大碎石堆 2×2 / 矮墙 2×1 / 倒塌的石柱 3×1
##   高(high，还挡视线与弹道)：石柱 1×1 / 雕像 1×1 / 断墙 2×1 / 拱门残段 3×1
## 横竖两种朝向都会出现(rect 的宽高互换)。放置时避开：我方部署区(外扩 1 格)、本遭遇的敌人出生区、终点祭坛；
## 每放一块都检查地图仍然全部连通，否则撤回。
## 主题 theme = "red"(第一章·红之章：燃烧的现代城市废墟)换一套款式，并多出两种地形：
##   死灰废墟(普通障碍，烧尽的水泥与车壳)：矮 = 碎水泥块 1×1 / 烧毁的汽车 2×1 / 塌落的楼板堆 2×2 / 矮墙残段 3×1
##                                        高 = 露钢筋的水泥柱 1×1 / 带窗洞的断墙 2×1 / 楼房的墙角 2×2 / 卷帘门店面残段 3×1
##   燃烧废墟(terrain = burning，占格，周围的棋子被施加【燃烧】)：矮 = 燃烧的杂物堆 1×1 / 燃烧的汽车 2×1
##                                                              高 = 燃烧的木屋骨架 2×2 / 燃烧的店面 3×1
##   余烬地块(embers，不占格)：1×1 / 2×1 / 2×2 / 3×2，不放在部署区(外扩 1 格：卡车改装"扩大部署区"的那一圈也留空)、出生区和障碍物上
## 部署区只按初始摆法(GC.DEPLOY_RECT)留空：卡车改装"部署区跟着卡车走"把部署区推到障碍物上时，那些格子就是不能放棋子。

const LOW_SHAPES := [
	{"size": Vector2i(1, 1), "styles": ["rubble_a", "rubble_b"]},
	{"size": Vector2i(2, 2), "styles": ["rubble_big"]},
	{"size": Vector2i(2, 1), "styles": ["wall_low_a", "wall_low_b"]},
	{"size": Vector2i(3, 1), "styles": ["column_fallen"]},
]
const HIGH_SHAPES := [
	{"size": Vector2i(1, 1), "styles": ["column_a", "column_b"]},
	{"size": Vector2i(1, 1), "styles": ["statue"]},
	{"size": Vector2i(2, 1), "styles": ["wall_a", "wall_b"]},
	{"size": Vector2i(3, 1), "styles": ["arch"]},
]
const RED_LOW := [
	{"size": Vector2i(1, 1), "styles": ["ash_rubble_a", "ash_rubble_b"]},
	{"size": Vector2i(2, 1), "styles": ["ash_car"]},
	{"size": Vector2i(2, 2), "styles": ["ash_heap"]},
	{"size": Vector2i(3, 1), "styles": ["ash_wall_low"]},
]
const RED_HIGH := [
	{"size": Vector2i(1, 1), "styles": ["ash_pillar"]},
	{"size": Vector2i(2, 1), "styles": ["ash_wall"]},
	{"size": Vector2i(2, 2), "styles": ["ash_corner"]},
	{"size": Vector2i(3, 1), "styles": ["ash_shopfront"]},
]
const RED_BURNING := [
	{"size": Vector2i(1, 1), "styles": ["burn_debris"], "kind": "low"},
	{"size": Vector2i(2, 1), "styles": ["burn_car"], "kind": "low"},
	{"size": Vector2i(2, 2), "styles": ["burn_house"], "kind": "high"},
	{"size": Vector2i(3, 1), "styles": ["burn_shopfront"], "kind": "high"},
]
const EMBER_SHAPES := [
	{"size": Vector2i(1, 1), "styles": ["ember_s"]},
	{"size": Vector2i(2, 1), "styles": ["ember_m"]},
	{"size": Vector2i(2, 2), "styles": ["ember_l"]},
	{"size": Vector2i(3, 2), "styles": ["ember_xl"]},
]
## 主题 purple(第二章-A·紫之章：云海上的和风空岛)：坚冰(普通障碍)矮 = 冰晶 1×1 / 冰块 2×1 / 冰堆 2×2 / 矮冰墙 3×1，
##   高 = 冰柱 1×1 / 冰墙 2×1 / 冰角 2×2 / 冰尖 3×1；寒雾地块(frost，不占格)：1×1 / 2×1 / 2×2 / 3×2，站在上面每秒一个【寒气】
const ICE_LOW := [
	{"size": Vector2i(1, 1), "styles": ["ice_rubble_a", "ice_rubble_b"]},
	{"size": Vector2i(2, 1), "styles": ["ice_block"]},
	{"size": Vector2i(2, 2), "styles": ["ice_heap"]},
	{"size": Vector2i(3, 1), "styles": ["ice_wall_low"]},
]
const ICE_HIGH := [
	{"size": Vector2i(1, 1), "styles": ["ice_pillar"]},
	{"size": Vector2i(2, 1), "styles": ["ice_wall"]},
	{"size": Vector2i(2, 2), "styles": ["ice_corner"]},
	{"size": Vector2i(3, 1), "styles": ["ice_spire"]},
]
const FROST_SHAPES := [
	{"size": Vector2i(1, 1), "styles": ["frost_s"]},
	{"size": Vector2i(2, 1), "styles": ["frost_m"]},
	{"size": Vector2i(2, 2), "styles": ["frost_l"]},
	{"size": Vector2i(3, 2), "styles": ["frost_xl"]},
]
## 主题 blue(第一章-B·蓝之章：蓝色穹顶下的未来都市)：科技障碍，矮 = 花坛 / 货箱 1×1 / 长凳 2×1 / 货箱堆 2×2 / 光栅 3×1，
##   高 = 立柱 1×1 / 全息亭 2×1 / 机柜 2×2 / 门架 3×1；没有地形效果
const TECH_LOW := [
	{"size": Vector2i(1, 1), "styles": ["tech_planter", "tech_crate"]},
	{"size": Vector2i(2, 1), "styles": ["tech_bench"]},
	{"size": Vector2i(2, 2), "styles": ["tech_crates"]},
	{"size": Vector2i(3, 1), "styles": ["tech_barrier"]},
]
const TECH_HIGH := [
	{"size": Vector2i(1, 1), "styles": ["tech_pillar"]},
	{"size": Vector2i(2, 1), "styles": ["tech_kiosk"]},
	{"size": Vector2i(2, 2), "styles": ["tech_server"]},
	{"size": Vector2i(3, 1), "styles": ["tech_gate"]},
]
const ALTAR_RECT := Rect2i(11, 0, 3, 2)      # 终点祭坛：北侧(敌方一侧)正中，3×2，高障碍


## cfg: {"low": int, "high": int, "altar": bool, "regions": [方位...], "theme": "white"/"red"/"purple", "burning": int, "embers": int, "frost": int}
static func generate(cfg: Dictionary, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var m: BattleMap = BattleMap.empty()
	var reserved: Array[Rect2i] = [GC.DEPLOY_RECT.grow(1)]
	if bool(cfg.get("altar", false)):
		m.add_obstacle(ALTAR_RECT, BattleMap.HIGH, "altar")
		reserved.append(ALTAR_RECT.grow(1))
	var keep: Array[Vector2] = []
	for rg: Variant in cfg.get("regions", []):
		var a: Vector2 = GC.region_anchor(str(rg))
		keep.append(a)
		keep.append(a + GC.region_dir(str(rg)) * 0.9)
	var start: Vector2i = GC.DEPLOY_RECT.position
	var red: bool = str(cfg.get("theme", "white")) == "red"
	var purple: bool = str(cfg.get("theme", "white")) == "purple"
	var blue: bool = str(cfg.get("theme", "white")) == "blue"
	# 固定要放的障碍(没有专属战场的事件战斗)：最先放，位置随机；块头大、能放的地方少，多试几次保证放得下
	for fx_o: Variant in cfg.get("fixed", []):
		var fo: Dictionary = fx_o
		var shape := {"size": Vector2i(int(fo.get("w", 1)), int(fo.get("h", 1))), "styles": [str(fo.get("style", "rubble_a"))], "kind": str(fo.get("kind", "low"))}
		_place_obstacles(m, rng, [shape], 1, -1, str(fo.get("terrain", "")), reserved, keep, start, 600)
	# 燃烧废墟先放(数量少、体积大)，再放高的、矮的死灰废墟
	if red:
		_place_obstacles(m, rng, RED_BURNING, int(cfg.get("burning", 0)), -1, "burning", reserved, keep, start)
	var high_shapes: Array = TECH_HIGH if blue else (ICE_HIGH if purple else (RED_HIGH if red else HIGH_SHAPES))
	var low_shapes: Array = TECH_LOW if blue else (ICE_LOW if purple else (RED_LOW if red else LOW_SHAPES))
	_place_obstacles(m, rng, high_shapes, int(cfg.get("high", 0)), BattleMap.HIGH, "", reserved, keep, start)
	_place_obstacles(m, rng, low_shapes, int(cfg.get("low", 0)), BattleMap.LOW, "", reserved, keep, start)
	if int(cfg.get("embers", 0)) > 0:
		_place_embers(m, rng, int(cfg["embers"]), keep)
	if int(cfg.get("frost", 0)) > 0:
		_place_patches(m, rng, FROST_SHAPES, int(cfg["frost"]), keep, true)
	var layout: Dictionary = m.to_layout()
	layout["seed"] = seed_value
	if red:
		layout["theme"] = "red"
	elif purple:
		layout["theme"] = "purple"
	elif blue:
		layout["theme"] = "blue"
	return layout


## 放 want 块障碍(kind = -1 表示由款式表里的 kind 决定高矮；max_tries = 最多试几次，默认每块 40 次)
static func _place_obstacles(m: BattleMap, rng: RandomNumberGenerator, shapes: Array, want: int, kind: int, terrain: String,
		reserved: Array[Rect2i], keep: Array[Vector2], start: Vector2i, max_tries: int = -1) -> void:
	var placed := 0
	var tries := 0
	while placed < want and tries < (max_tries if max_tries > 0 else want * 40):
		tries += 1
		var sh: Dictionary = shapes[rng.randi() % shapes.size()]
		var sz: Vector2i = sh["size"]
		if sz.x != sz.y and rng.randf() < 0.5:
			sz = Vector2i(sz.y, sz.x)
		var r := Rect2i(rng.randi_range(0, m.w - sz.x), rng.randi_range(0, m.h - sz.y), sz.x, sz.y)
		if not _can_place(m, r, reserved, keep):
			continue
		var styles: Array = sh["styles"]
		var k: int = kind
		if k < 0:
			k = BattleMap.HIGH if str(sh.get("kind", "low")) == "high" else BattleMap.LOW
		m.add_obstacle(r, k, str(styles[rng.randi() % styles.size()]), terrain)
		if m.reachable_count(start) != m.free_count():
			_undo_last(m)
			continue
		placed += 1


## 余烬地块：铺在空地上(不挡路，所以不影响连通)；不进我方部署区与敌人出生区，彼此不重叠
static func _place_embers(m: BattleMap, rng: RandomNumberGenerator, want: int, keep: Array[Vector2]) -> void:
	_place_patches(m, rng, EMBER_SHAPES, want, keep, false)


## 不占格的地块(余烬 / 寒雾)：铺在空地上，不进我方部署区(外扩 1 格)与敌人出生区，和别的地块不重叠
static func _place_patches(m: BattleMap, rng: RandomNumberGenerator, shapes: Array, want: int, keep: Array[Vector2], is_frost: bool) -> void:
	var placed := 0
	var tries := 0
	while placed < want and tries < want * 60:
		tries += 1
		var sh: Dictionary = shapes[rng.randi() % shapes.size()]
		var sz: Vector2i = sh["size"]
		if sz.x != sz.y and rng.randf() < 0.5:
			sz = Vector2i(sz.y, sz.x)
		var r := Rect2i(rng.randi_range(0, m.w - sz.x), rng.randi_range(0, m.h - sz.y), sz.x, sz.y)
		if r.intersects(GC.DEPLOY_RECT.grow(1)):
			continue
		var ok := true
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				if m.blocks_move(Vector2i(x, y)):
					ok = false
		for e: Dictionary in m.embers:
			if (e["rect"] as Rect2i).grow(1).intersects(r):
				ok = false
		for f: Dictionary in m.frost:
			if (f["rect"] as Rect2i).grow(1).intersects(r):
				ok = false
		for p: Vector2 in keep:
			var c: Vector2i = GC.world_to_cell(p)
			if Rect2i(c - Vector2i(1, 1), Vector2i(3, 3)).intersects(r):
				ok = false
		if not ok:
			continue
		var styles: Array = sh["styles"]
		if is_frost:
			m.add_frost(r, str(styles[rng.randi() % styles.size()]))
		else:
			m.add_ember(r, str(styles[rng.randi() % styles.size()]))
		placed += 1


static func _can_place(m: BattleMap, r: Rect2i, reserved: Array[Rect2i], keep: Array[Vector2]) -> bool:
	for rr: Rect2i in reserved:
		if rr.intersects(r):
			return false
	# 与已有障碍物至少隔 1 格(不形成死胡同式的密缝)
	for o: Dictionary in m.obstacles:
		if (o["rect"] as Rect2i).grow(1).intersects(r):
			return false
	for p: Vector2 in keep:
		var c: Vector2i = GC.world_to_cell(p)
		if Rect2i(c - Vector2i(1, 1), Vector2i(3, 3)).intersects(r):
			return false
	return true


static func _undo_last(m: BattleMap) -> void:
	var o: Dictionary = m.obstacles.pop_back()
	var r: Rect2i = o["rect"]
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			m.cells[y * m.w + x] = BattleMap.FREE
	m._astar = null
