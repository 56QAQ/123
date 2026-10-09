class_name WorldAssets
extends RefCounted
## 世界静态模型(assets/world/*.res，由 tools/model_world.gd + ./run_world.sh 生成)与共用材质。
## 大地图(OverworldView)和战斗场景(BattlefieldView)都从这里取网格、地面材质、散布装饰。

const GROUND_SHADER := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec3 base_a : source_color = vec3(0.80, 0.785, 0.76);
uniform vec3 base_b : source_color = vec3(0.74, 0.725, 0.70);
uniform vec3 seam : source_color = vec3(0.60, 0.585, 0.56);
uniform float slab = 2.4;
uniform float seam_w = 0.035;
uniform float seam_strength = 1.0;
varying vec3 wpos;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	// 错缝铺的大理石石板：每一行错开半块，石板大小不和战斗格子对齐(地面上看不出"棋盘")
	vec2 q = wpos.xz / vec2(slab * 1.6, slab);
	q.x += 0.5 * mod(floor(q.y), 2.0);
	vec2 id = floor(q);
	vec2 f = fract(q);
	float r = h21(id);
	vec3 c = mix(base_a, base_b, r * 0.8);
	float v = sin(wpos.x * 1.7 + wpos.z * 2.3 + 3.0 * sin(wpos.z * 0.35 + r * 6.0));
	c = mix(c, seam * 1.08, smoothstep(0.985, 1.0, abs(v)) * 0.35);
	float e = min(min(f.x * 1.6, (1.0 - f.x) * 1.6), min(f.y, 1.0 - f.y));
	c = mix(mix(c, seam, seam_strength), c, smoothstep(0.0, seam_w, e));
	ALBEDO = c;
	ROUGHNESS = 0.82;
	SPECULAR = 0.25;
}
"""

## 第一章·红之章的地面：烧黑的柏油路面 + 灰烬斑块 + 裂缝(裂缝里隐约透着暗红的余温)
## 第一章·红之章的地面：烧黑的柏油路。要清楚、不糊：
##   · 5 cm 一格的颗粒(和体素同一个尺度)，大尺度的明暗起伏很弱(否则会变成一块一块的软边色斑)
##   · 煤烟和灰烬只是很淡的柔和起伏(硬边的色块会显得一块一块)，龟裂是细细的多边形网(Voronoi)，只有零星几段透着暗红
##   · marks = 1(战场)：磨损的道路标线(白色车道线、黄色中线)
const GROUND_RED_SHADER := """
shader_type spatial;
render_mode diffuse_burley;
uniform float dark = 1.0;
uniform float marks = 0.0;
varying vec3 wpos;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
vec2 h22(vec2 p) { return vec2(h21(p), h21(p + 17.31)); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y); }
float cracks(vec2 p) {
	vec2 i = floor(p);
	float f1 = 9.0;
	float f2 = 9.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = h22(i + g) * 0.8 + 0.1;
			float d = length(g + o - fract(p));
			if (d < f1) { f2 = f1; f1 = d; } else if (d < f2) { f2 = d; }
		}
	}
	return f2 - f1;
}
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = wpos.xz;
	vec2 q = floor(p * 20.0);
	vec2 qq = floor(p * 4.0) / 4.0;
	vec3 c = vec3(0.12, 0.115, 0.11) * (0.88 + 0.16 * h21(q) + 0.06 * h21(floor(p * 5.0) + 3.0));
	c *= 0.95 + 0.08 * n2(p * 0.07);
	// 路面标线(战场)：先画，后面的煤烟 / 灰烬 / 裂缝会盖在上面
	if (marks > 0.5) {
		float wear = step(0.32, n2(p * 0.9 + 5.0)) * step(0.12, h21(q));
		vec3 white = vec3(0.55, 0.53, 0.5);
		vec3 yellow = vec3(0.55, 0.42, 0.12);
		float lane = (step(abs(abs(p.y) - 4.5), 0.07)) * step(0.5, fract(p.x / 3.0));
		float edge = step(abs(abs(p.y) - 9.0), 0.08);
		float mid = step(abs(abs(p.y) - 0.12), 0.05) * step(abs(p.x), 30.0);
		c = mix(c, white, max(lane, edge) * wear * 0.55);
		c = mix(c, yellow, mid * wear * 0.55);
	}
	// 煤烟与灰烬：很淡、柔和的大片起伏(不要硬边的色块)
	float soot = smoothstep(0.55, 0.85, n2(p * 0.18 + 9.0));
	c *= 1.0 - 0.18 * soot;
	float ash = smoothstep(0.62, 0.9, n2(p * 0.22 + 4.0));
	c = mix(c, vec3(0.22, 0.21, 0.2), ash * 0.25);
	// 碎屑：零星的深色 / 浅色 5 cm 小点
	float bit = h21(q + 7.0);
	c = mix(c, vec3(0.04), step(0.985, bit));
	c = mix(c, vec3(0.32, 0.3, 0.28), step(bit, 0.008));
	// 龟裂：细线，只有一部分区域有；零星几段透着暗红
	float region = step(0.48, n2(p * 0.09 + 21.0));
	float k = (1.0 - smoothstep(0.0, 0.022, cracks(p * 0.9))) * region;
	c = mix(c, vec3(0.03, 0.025, 0.022), k * 0.9);
	float warm = step(0.8, n2(p * 0.16 + 13.0));
	ALBEDO = c * dark;
	EMISSION = vec3(0.9, 0.2, 0.04) * k * warm * 0.55;
	ROUGHNESS = 0.92;
	SPECULAR = 0.15;
}
"""

## 公园的铺砖广场(事件「燃烧喷泉」的画面和战场)：以喷泉为圆心的圆形广场——0.5 米见方的地砖 + 砖缝，池边和广场外沿各一圈红砖，
## 越靠近喷泉越被烤黑；广场外面是烧焦的泥地。颗粒和别的地面一样是 5 cm 一格
const GROUND_PARK_SHADER := """
shader_type spatial;
render_mode diffuse_burley;
uniform vec2 center = vec2(0.0, -5.5);
uniform float radius = 13.5;
varying vec3 wpos;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y); }
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = floor(wpos.xz * 20.0) / 20.0 + 0.025;
	vec2 q = floor(wpos.xz * 20.0);
	vec2 rel = p - center;
	float d = length(rel);
	// 地砖
	vec2 tid = floor(p * 2.0);
	vec2 tf = fract(p * 2.0);
	float grout = max(step(tf.x, 0.1), step(tf.y, 0.1));
	float r = h21(tid);
	vec3 tile = mix(vec3(0.185, 0.175, 0.165), vec3(0.235, 0.225, 0.21), step(0.5, r));
	tile = mix(tile, vec3(0.135, 0.128, 0.12), step(0.82, r));
	tile *= 0.95 + 0.1 * h21(q);
	vec3 c = mix(tile, vec3(0.045, 0.04, 0.037), grout);
	// 红砖圈
	float ang = atan(rel.y, rel.x);
	float ring = max(step(abs(d - 2.75), 0.2), max(step(abs(d - 7.0), 0.1), step(abs(d - (radius - 0.3)), 0.3)));
	vec3 brick = mix(vec3(0.15, 0.03, 0.02), vec3(0.105, 0.022, 0.016), step(0.5, h21(vec2(floor(ang * d * 3.0), floor(d * 10.0)))));
	c = mix(c, brick, ring);
	// 喷泉周围烤黑：整体压暗一圈，紧挨着水池的地方有成片的焦块(10 cm 一块，越近越密)
	c *= 1.0 - 0.45 * (1.0 - smoothstep(2.6, 6.5, d));
	float scorch = 1.0 - smoothstep(2.6, 4.4, d);
	c = mix(c, vec3(0.022, 0.019, 0.017), step(h21(floor(p * 10.0) + 3.0), scorch * 0.5));
	// 灰烬：很淡的柔和起伏
	c = mix(c, vec3(0.2, 0.19, 0.18), smoothstep(0.62, 0.9, n2(p * 0.22 + 4.0)) * 0.2);
	// 广场外面：烧焦的泥地
	vec3 soil = vec3(0.05, 0.043, 0.038) * (0.8 + 0.4 * h21(q)) * (0.9 + 0.2 * n2(p * 0.3));
	soil = mix(soil, vec3(0.14, 0.13, 0.125), smoothstep(0.6, 0.9, n2(p * 0.25 + 7.0)) * 0.3);
	float outside = step(radius, d);
	c = mix(c, soil, outside);
	// 零星余烬(砖缝里、泥地上)
	float hot = step(0.9993, h21(q + 11.0)) * mix(grout, 1.0, outside);
	ALBEDO = c;
	EMISSION = vec3(1.0, 0.32, 0.06) * hot * 1.4;
	ROUGHNESS = 0.9;
	SPECULAR = 0.15;
}
"""

## 第二章-A·紫之章：云海上的和风空岛。积雪的石板地；近处坚冰，中景冰柱 / 石灯笼 / 雪松，远处和风建筑，天际是宝塔和大冰晶
const GROUND_ICE_SHADER := """
shader_type spatial;
render_mode diffuse_burley;
varying vec3 wpos;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
vec2 h22(vec2 p) { return vec2(h21(p), h21(p + 17.31)); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y); }
float cracks(vec2 p) {
	vec2 i = floor(p);
	float f1 = 9.0;
	float f2 = 9.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = h22(i + g) * 0.8 + 0.1;
			float d = length(g + o - fract(p));
			if (d < f1) { f2 = f1; f1 = d; } else if (d < f2) { f2 = d; }
		}
	}
	return f2 - f1;
}
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = wpos.xz;
	vec2 q = floor(p * 20.0);
	// 冷灰蓝的石板(1 米见方的板缝) + 大片的积雪 + 冻在石板上的冰(淡淡的紫)
	vec3 stone = vec3(0.3, 0.33, 0.42) * (0.88 + 0.16 * h21(q) + 0.06 * h21(floor(p * 5.0) + 3.0));
	float seam = step(0.94, fract(p.x)) + step(0.94, fract(p.y));
	stone = mix(stone, vec3(0.16, 0.17, 0.23), clamp(seam, 0.0, 1.0) * 0.6);
	float snow = smoothstep(0.48, 0.78, n2(p * 0.16 + 3.0) * 0.65 + n2(p * 0.7 + 9.0) * 0.35);
	vec3 white = vec3(0.7, 0.75, 0.88) * (0.93 + 0.07 * h21(q + 5.0));
	vec3 c = mix(stone, white, snow * 0.85);
	float ice = smoothstep(0.6, 0.85, n2(p * 0.25 + 21.0)) * (1.0 - snow);
	c = mix(c, vec3(0.6, 0.62, 0.9), ice * 0.5);
	float k = (1.0 - smoothstep(0.0, 0.022, cracks(p * 0.9))) * ice;
	c = mix(c, vec3(0.3, 0.25, 0.5), k * 0.8);
	float bit = h21(q + 7.0);
	c = mix(c, vec3(0.96, 0.98, 1.0), step(0.985, bit) * 0.8);
	ALBEDO = c;
	EMISSION = vec3(0.5, 0.35, 1.0) * k * 0.25;
	ROUGHNESS = 0.75 - 0.3 * ice;
	SPECULAR = 0.3;
}
"""

const ICE_DECO_NEAR := ["ice_rubble_a", "ice_rubble_b", "ice_block", "ice_wall_low", "jp_lantern"]
const ICE_DECO_MID := ["ice_pillar", "ice_wall", "ice_corner", "ice_spire", "jp_lantern", "jp_pine", "jp_wall", "ice_shard_a"]
const ICE_DECO_FAR := ["jp_house", "jp_house", "jp_shrine", "jp_wall", "jp_pine", "jp_pine", "ice_shard_a", "ice_shard_b"]
const ICE_DECO_SKY := ["jp_pagoda", "jp_shrine", "ice_shard_c", "ice_shard_b", "jp_pine"]
## 蓝之章战场外围的装饰(战斗尺度的科技障碍 + 大地图尺度的楼)
const TECH_DECO_NEAR := ["tech_planter", "tech_crate", "tech_bench", "tech_crates", "tech_barrier", "tech_planter"]
const TECH_DECO_MID := ["tech_pillar", "tech_kiosk", "tech_server", "tech_gate", "sf_lamp", "sf_tree", "tech_planter"]
const TECH_DECO_FAR := ["sf_block", "sf_block", "sf_tree", "sf_pylon", "sf_sign", "sf_tower_b", "sf_lamp"]
const TECH_DECO_SKY := ["sf_tower_a", "sf_tower_b", "sf_block", "sf_tower_a"]
## 蓝之章的地面：浅色的大板 + 板缝 + 每 8 米一道发光的导光缝；dome_r > 0 时穹顶外面是黑夜，穹顶脚下一圈光
const GROUND_TECH_SHADER := """
shader_type spatial;
render_mode diffuse_burley;
uniform vec2 dome_c = vec2(0.0);
uniform float dome_r = 0.0;
varying vec3 wpos;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y); }
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = wpos.xz;
	vec2 q = floor(p * 0.5);
	vec3 c = vec3(0.74, 0.78, 0.85) * (0.9 + 0.1 * h21(q));
	float seam = clamp(step(0.96, fract(p.x * 0.5)) + step(0.96, fract(p.y * 0.5)), 0.0, 1.0);
	c = mix(c, vec3(0.5, 0.55, 0.64), seam * 0.7);
	float gl = clamp(step(0.985, fract(p.x / 8.0)) + step(0.985, fract(p.y / 8.0)), 0.0, 1.0);
	c *= 1.0 - n2(p * 0.08) * 0.12;
	vec3 emi = vec3(0.3, 0.7, 1.0) * gl * 0.9;
	if (dome_r > 0.0) {
		float d = length(p - dome_c) - dome_r;
		float outside = smoothstep(-6.0, 6.0, d);
		c = mix(c, vec3(0.03, 0.05, 0.1), outside);
		emi *= 1.0 - outside;
		emi += vec3(0.35, 0.7, 1.0) * (1.0 - smoothstep(0.0, 5.0, abs(d + 3.0))) * 0.8;
	}
	ALBEDO = c;
	EMISSION = emi;
	ROUGHNESS = 0.45;
	SPECULAR = 0.45;
}
"""
const DECO_TALL := ["column_a", "column_b", "wall_a", "wall_b", "arch", "statue"]
## 红之章战场外围的装饰(战斗尺度的废墟 + 大地图尺度的楼，比例一致)
const RED_DECO_NEAR := ["ash_rubble_a", "ash_rubble_b", "ash_car", "ash_heap", "ash_wall_low", "burn_debris", "burn_car"]
const RED_DECO_MID := ["ash_pillar", "ash_wall", "ash_corner", "ash_shopfront", "bld_rubble", "bld_house_a", "bld_house_b", "bld_vending", "bld_pole"]
const RED_DECO_FAR := ["bld_house_a", "bld_house_b", "bld_shops", "bld_danchi", "bld_office_a", "bld_fallen", "bld_factory", "bld_rubble"]
const RED_DECO_SKY := ["bld_office_b", "bld_office_a", "bld_danchi", "bld_chimney", "bld_school"]
const DECO_LOW := ["rubble_a", "rubble_b", "rubble_big", "column_fallen", "wall_low_a", "wall_low_b"]

static var _meshes: Dictionary = {}
static var _ground_shader: Shader = null
static var _ground_red: Shader = null
static var _ground_park: Shader = null
static var _ground_ice: Shader = null
static var _ground_tech: Shader = null


static func mesh(name: String) -> Mesh:
	if not _meshes.has(name):
		_meshes[name] = load("res://assets/world/%s.res" % name) as Mesh
	return _meshes[name]


## 一大片大理石地面(看不到边际，远处由雾吞没)
static func ground(parent: Node3D, center: Vector3, extent: float, slab: float = 2.4, seam_strength: float = 1.0) -> MeshInstance3D:
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(extent, extent)
	g.mesh = pm
	var sm := ShaderMaterial.new()
	if _ground_shader == null:
		_ground_shader = Shader.new()
		_ground_shader.code = GROUND_SHADER
	sm.shader = _ground_shader
	sm.set_shader_parameter("slab", slab)
	sm.set_shader_parameter("seam_strength", seam_strength)
	g.material_override = sm
	g.position = center + Vector3(0, -0.02, 0)
	parent.add_child(g)
	return g


## 紫之章的积雪石板地面
static func ground_ice(parent: Node3D, center: Vector3, extent: float) -> MeshInstance3D:
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(extent, extent)
	g.mesh = pm
	var sm := ShaderMaterial.new()
	if _ground_ice == null:
		_ground_ice = Shader.new()
		_ground_ice.code = GROUND_ICE_SHADER
	sm.shader = _ground_ice
	g.material_override = sm
	g.position = center + Vector3(0, -0.02, 0)
	parent.add_child(g)
	return g


## 蓝之章的科技地面(dome_r > 0：穹顶外是黑夜)
static func ground_tech(parent: Node3D, center: Vector3, extent: float, dome_c: Vector2 = Vector2.ZERO, dome_r: float = 0.0) -> MeshInstance3D:
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(extent, extent)
	g.mesh = pm
	var sm := ShaderMaterial.new()
	if _ground_tech == null:
		_ground_tech = Shader.new()
		_ground_tech.code = GROUND_TECH_SHADER
	sm.shader = _ground_tech
	sm.set_shader_parameter("dome_c", dome_c)
	sm.set_shader_parameter("dome_r", dome_r)
	g.material_override = sm
	g.position = center + Vector3(0, -0.02, 0)
	parent.add_child(g)
	return g


## 红之章的烧黑柏油地面
static func ground_red(parent: Node3D, center: Vector3, extent: float, dark: float = 1.0, marks: bool = false) -> MeshInstance3D:
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(extent, extent)
	g.mesh = pm
	var sm := ShaderMaterial.new()
	if _ground_red == null:
		_ground_red = Shader.new()
		_ground_red.code = GROUND_RED_SHADER
	sm.shader = _ground_red
	sm.set_shader_parameter("dark", dark)
	sm.set_shader_parameter("marks", 1.0 if marks else 0.0)
	g.material_override = sm
	g.position = center + Vector3(0, -0.02, 0)
	parent.add_child(g)
	return g


## 公园的铺砖广场(圆心 center、半径 radius，广场外是烧焦的泥地)
static func ground_park(parent: Node3D, center: Vector2, radius: float, extent: float = 420.0) -> MeshInstance3D:
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(extent, extent)
	g.mesh = pm
	var sm := ShaderMaterial.new()
	if _ground_park == null:
		_ground_park = Shader.new()
		_ground_park.code = GROUND_PARK_SHADER
	sm.shader = _ground_park
	sm.set_shader_parameter("center", center)
	sm.set_shader_parameter("radius", radius)
	g.material_override = sm
	g.position = Vector3(0, -0.02, 0)
	parent.add_child(g)
	return g


## 把一组 {网格名: [Transform3D]} 用 MultiMesh 一次性画出来；shadows = false：不投影(战场外围的装饰，免得把整片战场盖上大块的影子)
static func add_multimesh(parent: Node3D, groups: Dictionary, shadows: bool = true) -> void:
	for nm: String in groups.keys():
		var list: Array = groups[nm]
		if list.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh(nm)
		mm.instance_count = list.size()
		for k in range(list.size()):
			mm.set_instance_transform(k, list[k])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		if not shadows:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mmi)


## 冲天的能量光柱 + 彩虹色补光(终点祭坛)
static func altar_beam(parent: Node3D, at: Vector3, height: float, radius: float) -> MeshInstance3D:
	var beam := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius * 0.65
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 16
	cm.cap_top = false
	cm.cap_bottom = false
	beam.mesh = cm
	var bmat := StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.albedo_color = Color(0.85, 0.95, 1.0, 0.22)
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam.material_override = bmat
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.position = at + Vector3(0, height * 0.5, 0)
	parent.add_child(beam)
	var lt := OmniLight3D.new()
	lt.light_color = Color("#d9c8ff")
	lt.light_energy = 2.2
	lt.omni_range = 9.0
	lt.position = at + Vector3(0, 3.5, 0)
	parent.add_child(lt)
	return beam
