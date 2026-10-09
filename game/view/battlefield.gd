class_name BattlefieldView
extends Node3D
## 战斗场景(战斗内地图)：当前地图节点那一小片遗迹的放大版，与大地图(OverworldView)是两个分开的场景。
##  · 地面是错缝铺的大理石石板，一直延伸进雾里——没有"棋盘"边框，战场和周围的废墟连成一片
##  · 断壁残垣 = 这个节点的战斗地图(Run.layouts)里的障碍物，按格子摆放(矮的挡路，高的还挡视线/弹道)
##  · 战场外围散布装饰废墟(不参与战斗)：南侧(镜头一侧)只放矮碎石，免得挡住战场
##  · 有祭坛的节点：彩虹水晶祭坛 + 能量光柱
##  · 红之章(layout.theme = red)：烧黑的柏油地面；燃烧废墟上烧着火(粒子 + 火光灯)；余烬地块是一片发光的裂纹炭灰，
##    有人踩上去就熄灭变暗、冒一股烟然后消失；四周是烧着的城市(战斗尺度的残骸 + 大地图尺度的楼，比例一致)，天上飘着余烬
## 坐标 = 战斗坐标(原点 = 战斗地图中心)，卡车停在原点。

const EMBER_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform float lit = 1.0;
uniform float seed = 0.0;
uniform vec2 size = vec2(1.0, 1.0);
varying vec3 wpos;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y); }
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	// 10 cm 一格的块状炭灰(体素感)，边缘参差；灰里是细裂纹和零星的炭火
	vec2 cell = floor(wpos.xz * 10.0) / 10.0;
	float edge = max(abs(UV.x - 0.5) * 2.0, abs(UV.y - 0.5) * 2.0);
	float keep = step(edge, 0.78 + 0.22 * h21(cell + seed));
	float crack = abs(n2(cell * 2.6 + seed) - 0.5);
	float hot = 1.0 - smoothstep(0.0, 0.03, crack);
	float coal = step(0.93, h21(cell * 7.3 + seed));
	float flick = 0.75 + 0.25 * sin(TIME * 3.0 + h21(cell) * 6.28);
	vec3 base = mix(vec3(0.05, 0.04, 0.036), vec3(0.2, 0.19, 0.18), 1.0 - lit) * (0.8 + 0.4 * h21(cell * 3.1));
	vec3 glow = mix(vec3(0.85, 0.12, 0.03), vec3(1.0, 0.42, 0.08), h21(cell * 1.7)) * 1.05 * flick;
	ALBEDO = mix(base, glow, max(hot, coal) * lit);
	ALPHA = keep * (0.95 * (0.35 + 0.65 * lit));
}
"""

## 燃烧废墟上火苗的位置(相对障碍物矩形中心；竖放时绕 Y 转 90°)与大小
const FIRE_POINTS := {
	"burn_debris": [[Vector3(0, 0.3, 0), 0.45]],
	"burn_car": [[Vector3(0.1, 0.55, 0), 0.5], [Vector3(-0.6, 0.4, 0), 0.3]],
	"burn_house": [[Vector3(-0.2, 0.4, -0.2), 0.75], [Vector3(-0.6, 2.0, -0.6), 0.4], [Vector3(0.6, 0.9, 0.6), 0.35]],
	"burn_shopfront": [[Vector3(-0.6, 0.5, -0.2), 0.6], [Vector3(0.7, 0.4, -0.2), 0.5], [Vector3(-0.8, 2.1, 0.25), 0.35]],
}

## 公园(事件「燃烧喷泉」的战场)外围的装饰：近处是烧秃的树、长椅、路灯，远处才是城市
const PARK_DECO_NEAR := ["evt_bench", "ash_rubble_a", "ash_rubble_b", "evt_bench"]
const PARK_DECO_MID := ["evt_tree", "evt_tree", "evt_tree", "evt_lamp", "evt_bench", "ash_wall", "ash_pillar"]

var _beam: MeshInstance3D = null
var _t: float = 0.0
var _embers: Dictionary = {}           # 余烬地块 id -> 贴花节点
var theme_purple: bool = false        # 紫之章(碎掉的是冰)
var _obs_nodes: Dictionary = {}        # 障碍物下标 -> 节点(裂地猛击打碎时拿来演)
var _frost_nodes: Dictionary = {}      # 寒雾地块 id -> 节点
static var _ember_shader: Shader = null
static var _frost_shader: Shader = null

## 寒雾地块：一片白霜(霜花从中心向外、边缘参差)，上面有慢慢旋转的冷雾，零星的紫色冰晶闪光
const FROST_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform float seed = 0.0;
varying vec3 wpos;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y); }
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 cell = floor(wpos.xz * 10.0) / 10.0;
	float edge = max(abs(UV.x - 0.5) * 2.0, abs(UV.y - 0.5) * 2.0);
	float keep = step(edge, 0.72 + 0.28 * h21(cell + seed));
	float frost = n2(cell * 3.0 + seed) * 0.6 + n2(cell * 9.0 - seed) * 0.4;
	float ang = atan(UV.y - 0.5, UV.x - 0.5);
	float mist = n2(vec2(ang * 2.0 + TIME * 0.25, length(UV - 0.5) * 6.0 - TIME * 0.2) + seed);
	float glint = step(0.975, h21(cell * 5.1 + seed)) * (0.5 + 0.5 * sin(TIME * 4.0 + h21(cell) * 6.28));
	vec3 base = mix(vec3(0.55, 0.68, 0.95), vec3(0.78, 0.86, 1.0), frost);
	base = mix(base, vec3(0.7, 0.6, 1.0), mist * 0.45);
	ALBEDO = mix(base, vec3(0.9, 0.8, 1.0) * 1.3, glint);
	ALPHA = keep * (0.3 + 0.25 * frost + 0.15 * mist);
}
"""
var _lights: int = 0
var arena: ArenaSet = null             # 事件战斗的专属战场：布景(和事件画面是同一套，见 ArenaSet)


func build(layout: Dictionary, seed_value: int) -> void:
	for ch: Node in get_children():
		ch.queue_free()
	_beam = null
	_embers.clear()
	_obs_nodes.clear()
	_frost_nodes.clear()
	_lights = 0
	arena = null
	var red: bool = str(layout.get("theme", "")) == "red"
	var purple: bool = str(layout.get("theme", "")) == "purple"
	theme_purple = purple
	var blue: bool = str(layout.get("theme", "")) == "blue"
	var set_id: String = str(layout.get("set", ""))
	if ArenaSet.known(set_id):
		arena = ArenaSet.make(set_id, true, layout)      # 布景自带地面
		add_child(arena)
	elif red:
		WorldAssets.ground_red(self, Vector3.ZERO, 420.0, 1.0, true)
	elif purple:
		WorldAssets.ground_ice(self, Vector3.ZERO, 420.0)
	elif blue:
		WorldAssets.ground_tech(self, Vector3.ZERO, 420.0)
	else:
		WorldAssets.ground(self, Vector3.ZERO, 420.0, 2.6, 0.5)
	var oi := 0
	for o: Variant in layout.get("obstacles", []):
		var od: Dictionary = o
		var burning: bool = str(od.get("terrain", "")) == "burning"
		var on: Node3D = obstacle_node(od, _lights < 6)
		add_child(on)
		_obs_nodes[oi] = on
		oi += 1
		if burning:
			_lights += 1
		if str(od.get("style", "")) == "altar":
			var r := _rect_of(od)
			var mid: Vector2 = _rect_mid(r)
			_beam = WorldAssets.altar_beam(self, Vector3(mid.x, 0, mid.y), 60.0, 1.4)
	var ei := 0
	for e: Variant in layout.get("embers", []):
		_ember_decal(ei, e as Dictionary)
		ei += 1
	var fi := 0
	for f: Variant in layout.get("frost", []):
		var fn: Node3D = frost_node(fi, f as Dictionary)
		add_child(fn)
		_frost_nodes[fi] = fn
		fi += 1
	if red:
		_scatter_city(seed_value, set_id == "fountain_park")
		var snow: GPUParticles3D = FireFX.ember_snow(Vector2(40, 34), 160, 12.0)
		add_child(snow)
	elif purple:
		_scatter_ice(seed_value)
		var flakes: GPUParticles3D = FireFX.snow(Vector2(44, 38), 260, 14.0)
		add_child(flakes)
	elif blue:
		_scatter_tech(seed_value)
		var motes: GPUParticles3D = FireFX.snow(Vector2(44, 38), 110, 14.0)
		add_child(motes)
	else:
		_scatter_surroundings(seed_value)


## 蓝之章战场外围：近处是花坛 / 货箱 / 长凳，中景是立柱 / 全息亭 / 路灯 / 树，远处是白色的街区楼和塔楼；几盏青色的灯
func _scatter_tech(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 29 + 11
	var half: Vector2 = GC.map_half()
	var groups: Dictionary = {}
	var placed := 0
	var tries := 0
	while placed < 150 and tries < 6000:
		tries += 1
		var p := Vector2(rng.randf_range(-90.0, 90.0), rng.randf_range(-90.0, 45.0))
		var dx: float = maxf(0.0, absf(p.x) - half.x)
		var dz: float = maxf(0.0, absf(p.y) - half.y)
		var d: float = Vector2(dx, dz).length()
		if d < 1.4:
			continue
		var south: bool = p.y > half.y
		if rng.randf() > clampf(0.3 + d * 0.03, 0.0, 1.0):
			continue
		var list: Array = WorldAssets.TECH_DECO_NEAR
		if d > 45.0:
			list = WorldAssets.TECH_DECO_SKY
		elif d > 16.0:
			list = WorldAssets.TECH_DECO_FAR
		elif d > 5.0:
			list = WorldAssets.TECH_DECO_MID
		if south and d < 30.0:
			list = WorldAssets.TECH_DECO_NEAR
		var nm: String = list[rng.randi() % list.size()]
		var yaw: float = PI * 0.5 * float(rng.randi() % 4) + rng.randf_range(-0.12, 0.12)
		var tf := Transform3D(Basis(Vector3.UP, yaw), Vector3(p.x, 0.0, p.y))
		if not groups.has(nm):
			groups[nm] = []
		(groups[nm] as Array).append(tf)
		placed += 1
	WorldAssets.add_multimesh(self, groups, false)
	for i in range(3):
		var lt := OmniLight3D.new()
		lt.light_color = Color("#7fd4ff")
		lt.light_energy = 1.1
		lt.omni_range = 18.0
		lt.shadow_enabled = false
		var a: float = rng.randf() * TAU
		lt.position = Vector3(cos(a) * 20.0, 4.0, -8.0 + sin(a) * 12.0)
		add_child(lt)


## 一块寒雾地块的贴花：白霜 + 冷雾
static func frost_node(id: int, f: Dictionary) -> Node3D:
	var r := Rect2i(int(f["x"]), int(f["y"]), int(f.get("w", 1)), int(f.get("h", 1)))
	var mid: Vector2 = _rect_mid(r)
	var n := Node3D.new()
	n.position = Vector3(mid.x, 0.03, mid.y)
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(float(r.size.x) * GC.CELL + 0.3, float(r.size.y) * GC.CELL + 0.3)
	q.orientation = PlaneMesh.FACE_Y
	mi.mesh = q
	if _frost_shader == null:
		_frost_shader = Shader.new()
		_frost_shader.code = FROST_SHADER
	var m := ShaderMaterial.new()
	m.shader = _frost_shader
	m.set_shader_parameter("seed", float(id) * 2.9 + float(r.position.y))
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(mi)
	var mist: GPUParticles3D = FireFX.snow(Vector2(r.size) * GC.CELL * 0.9, 5 * r.size.x * r.size.y, 0.8)
	mist.position = Vector3(0, 0.1, 0)
	n.add_child(mist)
	return n


## 紫之章战场外围：近处坚冰 / 石灯笼，中景冰柱 / 雪松 / 白墙，远处民家 / 神社，天际是宝塔和大冰晶
func _scatter_ice(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 31 + 23
	var half: Vector2 = GC.map_half()
	var groups: Dictionary = {}
	var placed := 0
	var tries := 0
	while placed < 150 and tries < 6000:
		tries += 1
		var p := Vector2(rng.randf_range(-90.0, 90.0), rng.randf_range(-90.0, 45.0))
		var dx: float = maxf(0.0, absf(p.x) - half.x)
		var dz: float = maxf(0.0, absf(p.y) - half.y)
		var d: float = Vector2(dx, dz).length()
		if d < 1.4:
			continue
		var south: bool = p.y > half.y
		if rng.randf() > clampf(0.3 + d * 0.03, 0.0, 1.0):
			continue
		var list: Array = WorldAssets.ICE_DECO_NEAR
		if d > 45.0:
			list = WorldAssets.ICE_DECO_SKY
		elif d > 16.0:
			list = WorldAssets.ICE_DECO_FAR
		elif d > 5.0:
			list = WorldAssets.ICE_DECO_MID
		if south and d < 30.0:
			list = WorldAssets.ICE_DECO_NEAR
		var nm: String = list[rng.randi() % list.size()]
		var yaw: float = rng.randf() * TAU if not nm.begins_with("jp_") else PI * 0.5 * float(rng.randi() % 4) + rng.randf_range(-0.2, 0.2)
		var tf := Transform3D(Basis(Vector3.UP, yaw), Vector3(p.x, 0.0, p.y))
		if not groups.has(nm):
			groups[nm] = []
		(groups[nm] as Array).append(tf)
		placed += 1
	WorldAssets.add_multimesh(self, groups, false)
	# 外围几根冰柱里透出的紫光
	for i in range(3):
		var lt := OmniLight3D.new()
		lt.light_color = Color("#a98cff")
		lt.light_energy = 1.2
		lt.omni_range = 16.0
		lt.shadow_enabled = false
		var a: float = rng.randf() * TAU
		lt.position = Vector3(cos(a) * 20.0, 3.0, -8.0 + sin(a) * 12.0)
		add_child(lt)


## 一个障碍物(战斗地图里的一块断壁残垣 / 专属战场里的喷泉、长椅…)：模型按格子放好(竖放的转 90°，o.ox / o.oz = 相对格子矩形中心的偏移)，
## 燃烧废墟按款式在几个位置点火(with_light = 第一团带火光灯)。事件画面(EventStage)画专属战场的障碍物也用它
static func obstacle_node(o: Dictionary, with_light: bool = true) -> Node3D:
	var r := _rect_of(o)
	var style: String = str(o.get("style", "rubble_a"))
	var mid: Vector2 = _rect_mid(r)
	var n := Node3D.new()
	n.position = Vector3(mid.x + float(o.get("ox", 0.0)), 0.0, mid.y + float(o.get("oz", 0.0)))
	if r.size.y > r.size.x:
		n.rotation.y = PI * 0.5
	elif r.size.x == r.size.y and style != "altar":
		n.rotation.y = PI * 0.5 * float(absi(r.position.x * 7 + r.position.y * 3) % 4)
	var mi := MeshInstance3D.new()
	mi.mesh = WorldAssets.mesh(style)
	n.add_child(mi)
	if str(o.get("terrain", "")) != "burning":
		return n
	if style == "burn_fountain":
		# 燃烧喷泉：火柱 + 火弧
		n.add_child(FireFX.fountain(ArenaSet.FOUNTAIN_K, with_light))
		return n
	var pts: Array = FIRE_POINTS.get(style, [[Vector3(0, 0.4, 0), 0.4]])
	for i in range(pts.size()):
		var f: FireFX = FireFX.make(float(pts[i][1]), i == 0 and with_light, false, 2.6)
		f.position = pts[i][0]
		n.add_child(f)
	return n


## 余烬地块：一片发光的裂纹炭灰 + 零星火星
func _ember_decal(id: int, e: Dictionary) -> void:
	var d: Dictionary = ember_node(id, e)
	add_child(d["node"])
	_embers[id] = d


## 一块余烬地块的贴花节点：{node, mat, fire, keep}(事件画面也用它画落火点)
static func ember_node(id: int, e: Dictionary) -> Dictionary:
	var r := Rect2i(int(e["x"]), int(e["y"]), int(e.get("w", 1)), int(e.get("h", 1)))
	var mid: Vector2 = _rect_mid(r)
	var n := Node3D.new()
	n.position = Vector3(mid.x, 0.03, mid.y)
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(float(r.size.x) * GC.CELL, float(r.size.y) * GC.CELL)
	q.orientation = PlaneMesh.FACE_Y
	mi.mesh = q
	if _ember_shader == null:
		_ember_shader = Shader.new()
		_ember_shader.code = EMBER_SHADER
	var m := ShaderMaterial.new()
	m.shader = _ember_shader
	m.set_shader_parameter("seed", float(id) * 3.7 + float(r.position.x))
	m.set_shader_parameter("size", Vector2(r.size))
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(mi)
	var sp: FireFX = FireFX.sparks(Vector2(r.size) * GC.CELL * 0.45)
	n.add_child(sp)
	# 喷泉的落火点(ember_jet)：熄灭以后留着一块焦痕，下次喷发再点燃
	return {"node": n, "mat": m, "fire": sp, "keep": str(e.get("style", "")) == "ember_jet"}


## 地形被打碎(圣战节点·裂地猛击)：障碍物炸开一团碎石、往下沉着缩没；寒雾地块淡掉
func break_terrain(kind: String, id: int, fx: Fx) -> void:
	var dict: Dictionary = _obs_nodes if kind == "obstacle" else _frost_nodes
	if not dict.has(id):
		return
	var n: Node3D = dict[id]
	dict.erase(id)
	if not is_instance_valid(n):
		return
	if fx != null:
		var purple: bool = theme_purple
		fx.terrain_shatter(n.position, 1.0 if kind == "obstacle" else 0.6, "ice" if (purple or kind == "frost") else ("burning" if n.find_children("*", "FireFX", true, false).size() > 0 else "stone"))
	for fire: Node in n.find_children("*", "FireFX", true, false):
		(fire as FireFX).set_emitting(false)
	var tw: Tween = create_tween().set_parallel(true)
	if kind == "obstacle":
		tw.tween_property(n, "position:y", n.position.y - 0.9, 0.5).set_ease(Tween.EASE_IN)
		tw.tween_property(n, "scale", Vector3(1.15, 0.2, 1.15), 0.5).set_ease(Tween.EASE_IN)
	else:
		tw.tween_property(n, "scale", Vector3(0.01, 1.0, 0.01), 0.6).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(n.queue_free)


## 有人踩上了余烬：火光暗下去、冒一股烟，然后这块地清空
func put_out_ember(id: int, fx: Fx) -> void:
	if not _embers.has(id):
		return
	var d: Dictionary = _embers[id]
	var n: Node3D = d["node"]
	(d["fire"] as FireFX).set_emitting(false)
	var m: ShaderMaterial = d["mat"]
	var tw: Tween = create_tween()
	tw.tween_method(func(v: float) -> void: m.set_shader_parameter("lit", v), 1.0, 0.0, 0.5)
	if not bool(d.get("keep", false)):
		_embers.erase(id)
		tw.tween_interval(0.8)
		tw.tween_property(n, "scale", Vector3(1.0, 1.0, 1.0) * 0.01, 0.6)
		tw.tween_callback(n.queue_free)
	if fx != null:
		fx.burst(n.position + Vector3(0, 0.2, 0), Color(0.3, 0.27, 0.25), 14, 1.4, 1.2, 1.4, 0.9, false)
		fx.burst(n.position + Vector3(0, 0.1, 0), Color(1.0, 0.5, 0.15), 8, 2.2, 0.6, 1.0, 0.4)


## 战斗中新烧起来的一块余烬(龙的余烬点燃 / 蔓延)：从中间长出来 + 一团火星
func add_ember(id: int, e: Dictionary, fx: Fx) -> void:
	if _embers.has(id):
		return
	var d: Dictionary = ember_node(id, e)
	var n: Node3D = d["node"]
	add_child(n)
	_embers[id] = d
	n.scale = Vector3(0.05, 1.0, 0.05)
	create_tween().tween_property(n, "scale", Vector3.ONE, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	if fx != null:
		fx.burst(n.position + Vector3(0, 0.15, 0), Color(1.0, 0.5, 0.15), 8, 2.0, 0.7, 1.4, 0.4)


## 喷泉的火弧砸在落火点上：这块余烬重新烧起来
func relight_ember(id: int, fx: Fx) -> void:
	if not _embers.has(id):
		return
	var d: Dictionary = _embers[id]
	(d["fire"] as FireFX).set_emitting(true)
	var m: ShaderMaterial = d["mat"]
	var tw: Tween = create_tween()
	tw.tween_method(func(v: float) -> void: m.set_shader_parameter("lit", v), 0.0, 1.0, 0.25)
	if fx != null:
		fx.burst((d["node"] as Node3D).position + Vector3(0, 0.2, 0), Color(1.0, 0.55, 0.15), 16, 3.0, 0.8, 1.2, 0.5)


## 专属战场的机制(Battle 的 hazard 事件)：交给布景去演(电车进站的预警、喷泉喷发)
func on_hazard(e: Dictionary) -> void:
	if arena != null:
		arena.on_hazard(e)


## 每帧：布景里跟着逻辑层走的东西(电车的位置)
func sync_battle(b: Battle, alpha: float) -> void:
	if arena != null:
		arena.sync_battle(b, alpha)


## 红之章战场外围：近处是战斗尺度的残骸(镜头一侧只放矮的)，远处是大地图尺度的楼，再远是高楼和烟囱的天际线；零星有几处在烧
## 专属战场：布景占着的地方(轨道、站台的延长线)不放；park = 公园，近处换成烧秃的树 / 长椅 / 路灯
func _scatter_city(seed_value: int, park: bool = false) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 31 + 11
	var half: Vector2 = GC.map_half()
	var groups: Dictionary = {}
	var fires := 0
	var placed := 0
	var tries := 0
	while placed < 150 and tries < 6000:
		tries += 1
		var p := Vector2(rng.randf_range(-90.0, 90.0), rng.randf_range(-90.0, 45.0))
		var dx: float = maxf(0.0, absf(p.x) - half.x)
		var dz: float = maxf(0.0, absf(p.y) - half.y)
		var d: float = Vector2(dx, dz).length()
		if d < 1.4:
			continue
		if arena != null and arena.blocks_scatter(p):
			continue
		var south: bool = p.y > half.y
		if rng.randf() > clampf(0.3 + d * 0.03, 0.0, 1.0):
			continue
		var list: Array = PARK_DECO_NEAR if park else WorldAssets.RED_DECO_NEAR
		if d > 45.0:
			list = WorldAssets.RED_DECO_SKY
		elif d > 16.0:
			list = WorldAssets.RED_DECO_FAR
		elif d > 5.0 or (park and d > 2.5 and not south):
			list = PARK_DECO_MID if park and d < 12.0 else WorldAssets.RED_DECO_MID
		if south and d < 30.0:
			list = PARK_DECO_NEAR if park else WorldAssets.RED_DECO_NEAR
		var nm: String = list[rng.randi() % list.size()]
		var yaw: float = rng.randf() * TAU if not nm.begins_with("bld_") else PI * 0.5 * float(rng.randi() % 4)
		var tf := Transform3D(Basis(Vector3.UP, yaw), Vector3(p.x, 0.0, p.y))
		if not groups.has(nm):
			groups[nm] = []
		(groups[nm] as Array).append(tf)
		placed += 1
		if fires < 9 and (nm.begins_with("burn_") or (nm.begins_with("bld_") and rng.randf() < 0.3)):
			var f: FireFX = FireFX.make(0.6 if nm.begins_with("burn_") else 1.6, fires < 5, true, 3.0)
			f.position = Vector3(p.x, 0.4 if nm.begins_with("burn_") else 3.0, p.y)
			add_child(f)
			fires += 1
	WorldAssets.add_multimesh(self, groups, false)


static func _rect_of(o: Dictionary) -> Rect2i:
	return Rect2i(int(o["x"]), int(o["y"]), int(o.get("w", 1)), int(o.get("h", 1)))


static func _rect_mid(r: Rect2i) -> Vector2:
	return (GC.cell_to_world(r.position.x, r.position.y) + GC.cell_to_world(r.end.x - 1, r.end.y - 1)) * 0.5


## 战场外的装饰废墟：离战场边缘越远越大越密；南侧近处只有矮碎石
func _scatter_surroundings(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 31 + 7
	var half: Vector2 = GC.map_half()
	var groups: Dictionary = {}
	for nm: String in WorldAssets.DECO_TALL + WorldAssets.DECO_LOW:
		groups[nm] = []
	var placed := 0
	var tries := 0
	while placed < 170 and tries < 5000:
		tries += 1
		var p := Vector2(rng.randf_range(-70.0, 70.0), rng.randf_range(-70.0, 40.0))
		# 到战斗区域(矩形)边缘的距离
		var dx: float = maxf(0.0, absf(p.x) - half.x)
		var dz: float = maxf(0.0, absf(p.y) - half.y)
		var d: float = Vector2(dx, dz).length()
		if d < 1.3:
			continue
		# 近处稀疏一些，远处密：接受概率随距离上升
		if rng.randf() > clampf(0.35 + d * 0.04, 0.0, 1.0):
			continue
		var south: bool = p.y > half.y
		var tall: bool = rng.randf() < (0.2 if d < 6.0 else 0.6)
		if south and d < 14.0:
			tall = false
		var names: Array = WorldAssets.DECO_TALL if tall else WorldAssets.DECO_LOW
		var nm2: String = names[rng.randi() % names.size()]
		var sc: float = rng.randf_range(0.9, 1.3) + d * 0.035
		if tall:
			sc = rng.randf_range(1.0, 1.4) + d * 0.05
		var tf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * sc), Vector3(p.x, 0.0, p.y))
		(groups[nm2] as Array).append(tf)
		placed += 1
	WorldAssets.add_multimesh(self, groups)


func _process(dt: float) -> void:
	_t += dt
	if _beam != null and visible:
		(_beam.material_override as StandardMaterial3D).albedo_color.a = 0.18 + 0.06 * sin(_t * 1.7)
