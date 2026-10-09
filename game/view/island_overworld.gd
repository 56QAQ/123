class_name IslandOverworld
extends CityOverworld
## 第二章-A·紫之章的大地图：一座漂在云海上的和风空岛(紫色的夜)。
##  · 逻辑仍是方格网(ChapterMap：mask = island，首领在岛正中央)；画面上格点略微弯曲、错开(沿用 CityOverworld 的格网变形)
##  · 岛被一道斜着的巨大剑痕斩成两半(ChapterMap 的 scar)：剑痕是一条看得见云海的深沟，谷底透着紫光，只有几座红色的太鼓桥跨过去(= 桥边)
##  · 北方立着九条巨大的冰质狐狸尾巴(扇形张开、尾尖卷向天空)；岛正中央是巨大的紫色冰山(首领就在它脚下)
##  · 四处散落着坚冰(冰晶)；节点附近是和风建筑(神社、宝塔、民家、石灯笼、白墙、雪松)，石畳的路把路口连起来
##  · 进入地点(起点)在岛边缘；岛外是云海(远处融进紫色的雾里)
## 节点按钮、路线预览、卡车折线等接口和 CityOverworld 一样(HUD / GameRoot 不用区分)

const SCAR_W := 24.0            # 剑痕(深沟)的宽度(米)
const SCAR_DEPTH := 58.0
const ISLAND_PAD := 72.0        # 岛沿离最外的格点多远
const CLOUD_Y := -80.0
const TAIL_N := 9
const PLAZA_CLEAR := 4.0        # 路口广场离剑痕沟沿至少这么远
const TERRACE := 9.5            # 冰山每一级台阶的高差(米)：节点 h = 1..5 → 9.5 … 47.5
const MOUNT_R := 54.0           # 冰山山体的底半径
const RING_R0 := 52.0           # 山腰上第 h 级台阶离山心的水平距离 = RING_R0 - RING_DR × h(h = 4 时还有 28 米：别和山顶的标记叠在一起)
const RING_DR := 6.0
const SUMMIT_R := 12.5          # 山顶平台(神社所在)的半径
const CRAG_H := 68.0            # 神社背后那座冰峰的顶

## 岩石(岛的下半截、剑痕的沟壁)：一层层的紫灰岩 + 零星发光的冰脉；带一点自发光 + 云海从下面照上来的冷光，背光面也不会黑成一片
const ROCK_SHADER := """
shader_type spatial;
render_mode diffuse_burley, cull_disabled;
uniform vec3 tint : source_color = vec3(0.3, 0.25, 0.42);
uniform float vein = 0.6;
varying vec3 wpos;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y); }
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float band = step(0.5, fract(wpos.y * 0.14 + n2(wpos.xz * 0.05) * 0.6));
	vec3 c = tint * (0.72 + 0.28 * band) * (0.85 + 0.3 * n2(wpos.xz * 0.3 + wpos.y * 0.2));
	float v = step(0.94, n2(wpos.xz * 0.8 + wpos.y * 0.9 + 3.0));
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float under = clamp(-wn.y, 0.0, 1.0);
	float depth = clamp(-wpos.y / 55.0, 0.0, 1.0) * (1.0 - under);
	c = mix(c, vec3(0.1, 0.05, 0.22), depth * 0.75);
	ALBEDO = c;
	EMISSION = vec3(0.55, 0.35, 1.0) * v * vein + tint * 0.3 * (1.0 - depth * 0.6) + vec3(0.55, 0.5, 0.75) * 0.22 * under;
	ROUGHNESS = 0.9;
}
"""

## 冰山：一层层的紫冰(台阶带)，越高越亮；裂纹里透着紫光，顶上泛光
const MOUNTAIN_SHADER := """
shader_type spatial;
render_mode diffuse_burley, cull_disabled;
uniform float top = 48.0;
varying vec3 wpos;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y); }
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float t = clamp(wpos.y / top, 0.0, 1.0);
	float band = step(0.6, fract(wpos.y * 0.2 + n2(wpos.xz * 0.08) * 0.5));
	vec3 deep = vec3(0.12, 0.05, 0.3);
	vec3 light = vec3(0.42, 0.28, 0.78);
	vec3 c = mix(deep, light, t * 0.7 + 0.1 * band) * (0.85 + 0.3 * n2(wpos.xz * 0.35 + wpos.y * 0.5));
	float v = step(0.92, n2(wpos.xz * 0.6 + wpos.y * 0.9 + 3.0));
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = c;
	EMISSION = vec3(0.6, 0.4, 1.0) * (v * 0.6 + fres * 0.45 + 0.06 * t) + deep * 0.15;
	ROUGHNESS = 0.35;
	SPECULAR = 0.5;
}
"""

const ISLAND_GROUND_SHADER := """
shader_type spatial;
render_mode diffuse_burley, cull_disabled;
uniform vec2 island_c = vec2(0.0);
uniform float island_r = 220.0;
uniform vec2 scar_p = vec2(0.0);
uniform vec2 scar_d = vec2(1.0, 0.0);
uniform float scar_w = 24.0;
uniform float seed = 0.0;
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
	vec2 rel = p - island_c;
	float ang = atan(rel.y, rel.x);
	float rim = island_r * (1.0 + 0.07 * sin(ang * 3.0 + seed) + 0.035 * sin(ang * 7.0 - seed * 1.7) + 0.03 * (n2(p * 0.03) - 0.5));
	float d_edge = length(rel) - rim;
	if (d_edge > 0.0) { discard; }
	vec2 sp = p - scar_p;
	float along = dot(sp, scar_d);
	float sd = abs(sp.x * scar_d.y - sp.y * scar_d.x);
	float half_w = scar_w * 0.5 * (0.85 + 0.3 * n2(vec2(along * 0.06, seed)));
	if (sd < half_w) { discard; }
	// 石畳的地：冷灰蓝的石板 + 板缝；大片的积雪(高处 / 远离路的地方更白)；剑痕沟沿一圈冻成紫色的冰
	vec2 q = floor(p * 4.0);
	vec3 stone = vec3(0.36, 0.39, 0.47) * (0.86 + 0.2 * h21(q));
	float k = 1.0 - smoothstep(0.0, 0.03, cracks(p * 0.45));
	stone = mix(stone, vec3(0.2, 0.21, 0.28), k * 0.8);
	float snow = smoothstep(0.42, 0.7, n2(p * 0.05 + 3.0) * 0.6 + n2(p * 0.3 + 9.0) * 0.4);
	vec3 white = vec3(0.86, 0.9, 0.98) * (0.94 + 0.06 * h21(q + 5.0));
	vec3 c = mix(stone, white, snow);
	float rimk = 1.0 - smoothstep(0.0, 9.0, sd - half_w);
	c = mix(c, vec3(0.62, 0.5, 0.95), rimk * 0.6);
	float edgek = 1.0 - smoothstep(-6.0, 0.0, d_edge);
	c = mix(c, vec3(0.3, 0.3, 0.4), (1.0 - edgek) * 0.0 + smoothstep(-4.0, 0.0, d_edge) * 0.35);
	ALBEDO = c;
	EMISSION = vec3(0.55, 0.3, 1.0) * rimk * rimk * 0.5;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
}
"""

const CLOUD_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float seed = 0.0;
varying vec3 wpos;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y); }
float fbm(vec2 p) { return n2(p) * 0.5 + n2(p * 2.1 + 3.0) * 0.25 + n2(p * 4.3 + 7.0) * 0.125 + n2(p * 8.7 + 11.0) * 0.0625; }
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = wpos.xz * 0.0075 + vec2(TIME * 0.008, seed);
	float a = fbm(p) * 0.6 + fbm(p * 3.1 + 11.0) * 0.4;
	float b = fbm(p * 1.9 + vec2(5.0, 2.0) - TIME * 0.006) * 0.6 + fbm(p * 5.3 + 3.0) * 0.4;
	vec3 deep = vec3(0.1, 0.07, 0.2);
	vec3 mid = vec3(0.3, 0.24, 0.48);
	vec3 top = vec3(0.6, 0.55, 0.8);
	vec3 c = mix(deep, mid, smoothstep(0.3, 0.65, a));
	c = mix(c, top, smoothstep(0.5, 0.85, b) * 0.7);
	ALBEDO = c;
}
"""

const SCAR_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;
varying vec2 uv;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y); }
void vertex() { uv = UV; }
void fragment() {
	// 谷底：深紫的黑暗，中间一道像剑光一样的亮线(呼吸)，两旁有冷雾
	float x = abs(uv.x - 0.5) * 2.0;
	float line = pow(max(0.0, 1.0 - x * 2.2), 2.0);
	float pulse = 0.75 + 0.25 * sin(TIME * 1.1 + uv.y * 40.0);
	float mist = n2(vec2(uv.x * 6.0, uv.y * 120.0 - TIME * 0.05));
	vec3 c = vec3(0.12, 0.07, 0.24) + vec3(0.45, 0.25, 0.85) * line * pulse + vec3(0.3, 0.22, 0.55) * mist * 0.45 * (1.0 - x);
	ALBEDO = c;
	ALPHA = 1.0;
}
"""

const STONE_ROAD_SHADER := """
shader_type spatial;
render_mode diffuse_burley;
varying vec3 wpos;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y); }
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float across = UV.x;
	float along = UV.y;
	// 石畳：一块块 1.6 米的石板，板缝深；两侧一道雪边
	vec2 cell = vec2(floor(across * 5.0), floor(along / 1.6));
	float gap = step(0.08, fract(across * 5.0)) * step(0.06, fract(along / 1.6));
	vec3 slab = vec3(0.33, 0.35, 0.42) * (0.85 + 0.25 * h21(cell + 1.3));
	vec3 c = mix(vec3(0.16, 0.17, 0.22), slab, gap);
	float snow = smoothstep(0.55, 0.85, n2(wpos.xz * 0.35 + 2.0));
	float side = smoothstep(0.9, 1.0, abs(across - 0.5) * 2.0);
	c = mix(c, vec3(0.86, 0.9, 0.98), max(side * 0.9, snow * 0.35));
	ALBEDO = c;
	ROUGHNESS = 0.9;
}
"""

const COURT_SHADER := """
shader_type spatial;
render_mode diffuse_burley;
varying vec3 wpos;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	// 圆形的石庭：同心的石板环 + 放射的板缝
	vec2 q = UV * 2.0 - 1.0;
	float r = length(q);
	float ang = atan(q.y, q.x);
	float ring = fract(r * 5.0);
	float spoke = fract(ang / 6.2831853 * 20.0 + floor(r * 5.0) * 0.5);
	float gap = step(0.08, ring) * step(0.06, spoke);
	vec3 c = mix(vec3(0.17, 0.18, 0.23), vec3(0.35, 0.37, 0.45) * (0.85 + 0.25 * h21(vec2(floor(r * 5.0), floor(spoke * 7.0)))), gap);
	ALBEDO = c;
	ROUGHNESS = 0.9;
}
"""

var _scar_p: Vector3 = Vector3.ZERO          # 剑痕(直线)上的一点 / 方向(世界坐标)
var _scar_d: Vector3 = Vector3.RIGHT
var _has_scar: bool = false
var _island_c: Vector3 = Vector3.ZERO
var _island_r: float = 220.0
var _ice_mat: StandardMaterial3D = null
var _berg_light: OmniLight3D = null
var _tt: float = 0.0
var _mount: Dictionary = {}                  # gmap.mountain(冰山：山顶 / 上山的路 / 进山的路口)
var _mount_c: Vector3 = Vector3.ZERO         # 山心(山顶节点在地面上的投影)
var _mount_mat: ShaderMaterial = null
var _ground_seed: float = 0.0                # 岛沿起伏的种子(和地面着色器同一份)


# ================================================================ 搭建
func build(run: Run) -> void:
	for ch: Node in get_children():
		ch.queue_free()
	node_pos.clear()
	_edges.clear()
	_markers.clear()
	_lines.clear()
	_path.clear()
	_groups.clear()
	_blocks.clear()
	_hot.clear()
	_fires = 0
	_lights = 0
	_mount_mat = null
	_berg_light = null
	var gm: Dictionary = run.gmap
	w = int(gm["w"])
	h = int(gm["h"])
	_rng.seed = int(gm.get("seed", run.seed_value)) * 13 + 5
	_layout_nodes(gm)
	_layout_scar(gm)
	_layout_edges(gm)
	var mn := Vector2(1e9, 1e9)
	var mx := Vector2(-1e9, -1e9)
	for k: String in node_pos.keys():
		var p: Vector3 = node_pos[k]
		mn = Vector2(minf(mn.x, p.x), minf(mn.y, p.z))
		mx = Vector2(maxf(mx.x, p.x), maxf(mx.y, p.z))
	_bounds = Rect2(mn, mx - mn)
	_island_c = Vector3(_bounds.get_center().x, 0.0, _bounds.get_center().y)
	_island_r = maxf(_bounds.size.x, _bounds.size.y) * 0.5 + ISLAND_PAD
	_occ_init(_bounds.grow(300.0))
	_rasterize()
	_occ_scar()
	_build_clouds()
	_build_island_ground()
	_build_scar()
	_build_road_mesh()
	_build_plazas()
	_build_tails()
	_build_mountain(run)
	_build_detail()
	_build_fabric()
	_build_lanterns()
	_build_markers(run)
	WorldAssets.add_multimesh(self, _groups)
	_flush_blocks()
	var snow: GPUParticles3D = FireFX.snow(Vector2(_bounds.size.x + 300.0, _bounds.size.y + 300.0), 1100, 70.0)
	snow.position += _island_c
	add_child(snow)


func center() -> Vector3:
	return _island_c


func span() -> float:
	return maxf(_bounds.size.x, _bounds.size.y * 1.5) + 40.0


# ---------------------------------------------------------------- 节点位置：直线的格网(剑痕是直线，节点和它的关系得和逻辑层一致)+ 小错开；
## 冰山上的台阶节点：沿着格子的方向、按高度往山心收(第 h 级离山心 RING_R0 - RING_DR × h 米)、抬高 h × TERRACE；山顶在山心
func _layout_nodes(gm: Dictionary) -> void:
	_rot = _rng.randf_range(-0.12, 0.12)
	_ph1 = _rng.randf() * TAU
	_ph2 = _rng.randf() * TAU
	_river_col = -1
	_mount = gm.get("mountain", {})
	var nodes: Dictionary = gm["nodes"]
	var keys: Array = nodes.keys()
	keys.sort()
	var top_key: String = str(_mount.get("center", ""))
	if not _mount.is_empty():
		var cc: Vector2i = ChapterMap.cell(top_key)
		_mount_c = _lin(float(cc.x), float(cc.y))
	for k: String in keys:
		var c: Vector2i = ChapterMap.cell(k)
		var p: Vector3 = _lin(float(c.x), float(c.y))
		var hgt: int = int((nodes[k] as Dictionary).get("h", 0))
		if hgt > 0 and k == top_key:
			node_pos[k] = _mount_c + Vector3(0, float(hgt) * TERRACE, 0)
		elif hgt > 0:
			var dir: Vector3 = (p - _mount_c).normalized()
			node_pos[k] = _mount_c + dir * (RING_R0 - RING_DR * float(hgt)) + Vector3(0, float(hgt) * TERRACE, 0)
		else:
			var j := Vector3(_rng.randf_range(-1.0, 1.0), 0.0, _rng.randf_range(-1.0, 1.0)) * S * 0.08
			node_pos[k] = p + j


## 不带起伏的格网映射(剑痕是一条直线：按它定)
func _lin(fx: float, fy: float) -> Vector3:
	var u: float = fx - float(w - 1) * 0.5
	var v: float = fy - float(h - 1) * 0.5
	var x: float = u * S
	var z: float = v * S * ROW
	return Vector3(x * cos(_rot) - z * sin(_rot), 0.0, x * sin(_rot) + z * cos(_rot))


## 剑痕：格网里 s = 0 和 s = 1 两条斜线之间(dir 0：x - y；dir 1：x + y - (w - 1))，世界里是一条直线；
## 路口广场离沟沿至少 PLAZA_CLEAR 米(太近的沿法线推开)
func _layout_scar(gm: Dictionary) -> void:
	_has_scar = gm.has("scar")
	if not _has_scar:
		return
	var dir: int = int((gm["scar"] as Dictionary).get("dir", 0))
	var a: Vector3
	var b: Vector3
	if dir == 0:
		a = _lin(0.5, 0.0)
		b = _lin(float(w - 1) + 0.5, float(w - 1))
	else:
		a = _lin(float(w - 1) + 0.5, 0.0)
		b = _lin(0.5, float(w - 1))
	_scar_p = (a + b) * 0.5
	_scar_d = (b - a).normalized()
	var need: float = SCAR_W * 0.5 + PLAZA_R + PLAZA_CLEAR
	for k: String in node_pos.keys():
		var p: Vector3 = node_pos[k]
		if p.y > 0.5:
			continue
		var sd: float = _scar_signed(p)
		if absf(sd) < need:
			var n := Vector3(-_scar_d.z, 0, _scar_d.x)
			node_pos[k] = p + n * (need - absf(sd)) * (1.0 if sd >= 0.0 else -1.0)


## 到剑痕中线的带符号距离
func _scar_signed(p: Vector3) -> float:
	var rel: Vector3 = p - _scar_p
	return rel.x * _scar_d.z - rel.z * _scar_d.x


func _scar_dist(p: Vector2) -> float:
	if not _has_scar:
		return 1e9
	return absf(_scar_signed(Vector3(p.x, 0, p.y)))


func _layout_edges(gm: Dictionary) -> void:
	var bridges: Dictionary = {}
	if _has_scar:
		for br: Array in (gm["scar"] as Dictionary).get("bridges", []):
			bridges["%s|%s" % [br[0], br[1]]] = true
			bridges["%s|%s" % [br[1], br[0]]] = true
	for e: Array in gm["edges"]:
		var a: Vector3 = node_pos[e[0]]
		var b: Vector3 = node_pos[e[1]]
		var d: Vector3 = b - a
		var L: float = d.length()
		var dir: Vector3 = d / L
		var perp := Vector3(-dir.z, 0, dir.x)
		var cross: bool = bridges.has("%s|%s" % [e[0], e[1]])
		var k: float = 0.05 if (cross or a.y > 0.5 or b.y > 0.5) else 0.3
		var o1: float = (_rng.randf() - 0.5) * k * L
		var o2: float = (_rng.randf() - 0.5) * k * L
		var p1: Vector3 = a + dir * L * 0.33 + perp * o1
		var p2: Vector3 = a + dir * L * 0.66 + perp * o2
		var pts := PackedVector3Array()
		for i in range(25):
			var t: float = float(i) / 24.0
			var u: float = 1.0 - t
			pts.append(a * u * u * u + p1 * 3.0 * u * u * t + p2 * 3.0 * u * t * t + b * t * t * t)
		_edges.append({"a": e[0], "b": e[1], "pts": pts, "cross": cross})


func _occ_scar() -> void:
	if not _has_scar:
		return
	for i in range(-40, 41):
		var p: Vector3 = _scar_p + _scar_d * float(i) * 10.0
		_occ_disc(Vector2(p.x, p.z), SCAR_W * 0.5 + 7.0)


# ---------------------------------------------------------------- 云海 / 岛 / 剑痕
func _build_clouds() -> void:
	var cl := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(3200, 3200)
	cl.mesh = pm
	var m: ShaderMaterial = _mat("cloud", CLOUD_SHADER)
	m.set_shader_parameter("seed", _rng.randf() * 10.0)
	cl.material_override = m
	cl.position = _island_c + Vector3(0, CLOUD_Y, 0)
	cl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cl)


func _build_island_ground() -> void:
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(_island_r * 2.6, _island_r * 2.6)
	pm.subdivide_width = 8
	pm.subdivide_depth = 8
	g.mesh = pm
	var m: ShaderMaterial = _mat("island", ISLAND_GROUND_SHADER)
	m.set_shader_parameter("island_c", Vector2(_island_c.x, _island_c.z))
	m.set_shader_parameter("island_r", _island_r)
	m.set_shader_parameter("scar_p", Vector2(_scar_p.x, _scar_p.z))
	m.set_shader_parameter("scar_d", Vector2(_scar_d.x, _scar_d.z) if _has_scar else Vector2(1, 0))
	m.set_shader_parameter("scar_w", SCAR_W if _has_scar else 0.0)
	_ground_seed = _rng.randf() * 6.28
	m.set_shader_parameter("seed", _ground_seed)
	g.material_override = m
	g.position = _island_c + Vector3(0, -0.02, 0)
	add_child(g)
	# 岛身：一截深色的岩柱(上粗下细)，底下尖尖地垂进云海
	var cliff := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = _island_r * 0.96
	cm.bottom_radius = _island_r * 0.55
	cm.height = 70.0
	cm.radial_segments = 48
	cm.cap_top = false
	cliff.mesh = cm
	var rock: ShaderMaterial = _mat("rock", ROCK_SHADER)
	rock.set_shader_parameter("tint", Color(0.3, 0.25, 0.42))
	rock.set_shader_parameter("vein", 0.5)
	cliff.material_override = rock
	cliff.position = _island_c + Vector3(0, -35.0, 0)
	add_child(cliff)
	var tip := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = _island_r * 0.55
	tm.bottom_radius = 0.0
	tm.height = 60.0
	tm.radial_segments = 48
	tip.mesh = tm
	tip.material_override = rock
	tip.position = _island_c + Vector3(0, -100.0, 0)
	add_child(tip)
	# 岛底垂着几根冰凌
	for i in range(14):
		var a: float = _rng.randf() * TAU
		var rr: float = _rng.randf_range(0.2, 0.75) * _island_r
		var p: Vector3 = _island_c + Vector3(cos(a) * rr, -70.0 - _rng.randf_range(0.0, 30.0), sin(a) * rr)
		var ic := MeshInstance3D.new()
		var icm := CylinderMesh.new()
		icm.top_radius = _rng.randf_range(4.0, 9.0)
		icm.bottom_radius = 0.0
		icm.height = _rng.randf_range(25.0, 55.0)
		icm.radial_segments = 6
		ic.mesh = icm
		ic.material_override = _ice_material()
		ic.position = p - Vector3(0, icm.height * 0.5, 0)
		add_child(ic)


## 岛沿在某个方位角上的半径(照抄地面着色器的起伏，不含那一点噪声)
func _rim_r(ang: float) -> float:
	return _island_r * (1.0 + 0.07 * sin(ang * 3.0 + _ground_seed) + 0.035 * sin(ang * 7.0 - _ground_seed * 1.7))


## 剑痕中线和岛沿的两个交点：沿 _scar_d 相对 _scar_p 的参数(x = 负的那头，y = 正的那头)
func _scar_span() -> Vector2:
	var out := Vector2.ZERO
	var o := Vector2(_scar_p.x - _island_c.x, _scar_p.z - _island_c.z)
	var d := Vector2(_scar_d.x, _scar_d.z)
	for sgn: float in [-1.0, 1.0]:
		var t: float = sgn * _island_r
		for it in range(6):
			var rel: Vector2 = o + d * t
			var rr: float = _rim_r(atan2(rel.y, rel.x))
			var b: float = o.dot(d)
			var disc: float = maxf(0.0, b * b - (o.dot(o) - rr * rr))
			t = -b + sgn * sqrt(disc)
		if sgn < 0.0:
			out.x = t
		else:
			out.y = t
	return out


## 岛身(岩柱)在离岛心 rho 米处的表面高度：岛沿 0.96 R 处是地面，往下收到 0.55 R(-70 米)，再往下是尖(-130 米)
func _cliff_y(rho: float) -> float:
	var top_r: float = _island_r * 0.96
	var bot_r: float = _island_r * 0.55
	if rho >= top_r:
		return 0.0
	if rho <= bot_r:
		return -70.0 - 60.0 * (1.0 - rho / bot_r)
	return -70.0 * (top_r - rho) / (top_r - bot_r)


## 剑痕中线上、离岛心不超过 rad 米的那一段(沿 _scar_d 相对 _scar_p 的参数)；不相交返回 (0, 0)
func _line_circle(rad: float) -> Vector2:
	var o := Vector2(_scar_p.x - _island_c.x, _scar_p.z - _island_c.z)
	var d := Vector2(_scar_d.x, _scar_d.z)
	var b: float = o.dot(d)
	var disc: float = b * b - (o.dot(o) - rad * rad)
	if disc <= 0.0:
		return Vector2.ZERO
	return Vector2(-b - sqrt(disc), -b + sqrt(disc))


## 剑痕：谷底一条发紫光的长条 + 两道沟壁，沟沿立着一排排的冰晶。这一刀是把岛身整个斩穿的：沟壁的下沿贴着岩柱收窄的侧面，
## 谷底只铺在岩柱够厚的那一段，靠近岛沿的地方沟是通的(从侧面能透过裂口看见云海)
func _build_scar() -> void:
	if not _has_scar:
		return
	var span: Vector2 = _scar_span()
	var L: float = span.y - span.x
	var mid: Vector3 = _scar_p + _scar_d * (span.x + span.y) * 0.5
	var yaw: float = atan2(_scar_d.x, _scar_d.z)
	var fl: Vector2 = _line_circle(_island_r * (0.96 - 0.41 * SCAR_DEPTH / 70.0) - 2.0)
	if fl.y > fl.x:
		var floor_mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(SCAR_W * 1.1, fl.y - fl.x)
		floor_mi.mesh = pm
		floor_mi.material_override = _mat("scar", SCAR_SHADER)
		floor_mi.position = _scar_p + _scar_d * (fl.x + fl.y) * 0.5 + Vector3(0, -SCAR_DEPTH, 0)
		floor_mi.rotation.y = yaw
		floor_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(floor_mi)
	var wall_mat: ShaderMaterial = _mat("rock_wall", ROCK_SHADER)
	wall_mat.set_shader_parameter("tint", Color(0.34, 0.27, 0.5))
	wall_mat.set_shader_parameter("vein", 1.2)
	var perp := Vector3(-_scar_d.z, 0, _scar_d.x)
	var n_st: int = maxi(2, int(L / 5.0) + 1)
	for side: float in [-1.0, 1.0]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(n_st):
			var t: float = span.x + L * float(i) / float(n_st - 1)
			var p: Vector3 = _scar_p + _scar_d * t + perp * side * SCAR_W * 0.5
			var rho: float = Vector2(p.x - _island_c.x, p.z - _island_c.z).length()
			var yb: float = maxf(-SCAR_DEPTH - 2.0, _cliff_y(rho))
			st.set_uv(Vector2(0, 0))
			st.add_vertex(Vector3(p.x, 2.0, p.z))
			st.set_uv(Vector2(0, 1))
			st.add_vertex(Vector3(p.x, minf(yb, 1.9), p.z))
		for i2 in range(n_st - 1):
			var a: int = i2 * 2
			for idx: int in [a, a + 2, a + 1, a + 1, a + 2, a + 3]:
				st.add_index(idx)
		st.generate_normals()
		var wm := MeshInstance3D.new()
		wm.mesh = st.commit()
		wm.material_override = wall_mat
		add_child(wm)
	# 沟沿的冰晶(断口上冻出来的)
	var n: int = int(L / 9.0)
	for i in range(n):
		var t: float = (float(i) + 0.5) / float(n) - 0.5
		var base: Vector3 = mid + _scar_d * t * L
		if base.distance_to(_island_c) > _island_r - 6.0:
			continue
		for side2: float in [-1.0, 1.0]:
			if _rng.randf() < 0.35:
				continue
			var p: Vector3 = base + perp * side2 * (SCAR_W * 0.5 + _rng.randf_range(1.5, 6.0)) + _scar_d * _rng.randf_range(-3.0, 3.0)
			var nm: String = ["ice_shard_a", "ice_shard_a", "ice_shard_b"][_rng.randi() % 3]
			_place(nm, p, _rng.randf() * TAU, _rng.randf_range(0.35, 0.8))
	# 紫光：沟里的光从下面照上来(几盏)
	for j in range(4):
		var lt := OmniLight3D.new()
		lt.light_color = Color("#9a6cff")
		lt.light_energy = 2.2
		lt.omni_range = 70.0
		lt.position = mid + _scar_d * (float(j) - 1.5) * L * 0.25 + Vector3(0, -12.0, 0)
		lt.shadow_enabled = false
		add_child(lt)


# ---------------------------------------------------------------- 路 / 路口 / 桥
func _build_road_mesh() -> void:
	var m: ShaderMaterial = _mat("stone_road", STONE_ROAD_SHADER)
	for e: Dictionary in _edges:
		var pts: PackedVector3Array = e["pts"]
		var mi := MeshInstance3D.new()
		mi.mesh = _strip(pts, ROAD_W * 0.8, 0.04)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		if bool(e["cross"]):
			_bridge(pts)
		elif pts[0].y > 0.5 or pts[pts.size() - 1].y > 0.5:
			_ramp(pts, ROAD_W * 0.8 + 1.2)


## 冰堤：路的两侧各一道壁从路面落到地面(埋进山体的部分看不见)，顶面比路面低一点点，路面盖在上头
func _ramp(pts: PackedVector3Array, width: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(pts.size()):
		var t: Vector3 = (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)])
		t.y = 0.0
		t = t.normalized()
		var perp := Vector3(-t.z, 0, t.x) * width * 0.5
		var top: Vector3 = pts[i] - Vector3(0, 0.02, 0)
		for v: Vector3 in [top - perp, top + perp, Vector3(top.x - perp.x, -1.0, top.z - perp.z), Vector3(top.x + perp.x, -1.0, top.z + perp.z)]:
			st.set_uv(Vector2(0, 0))
			st.add_vertex(v)
	for i2 in range(pts.size() - 1):
		var a: int = i2 * 4
		for q: Array in [[0, 4, 1, 1, 4, 5], [0, 2, 4, 4, 2, 6], [1, 5, 3, 3, 5, 7]]:
			for idx: int in q:
				st.add_index(a + idx)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _ice_material()
	add_child(mi)


## 太鼓桥：红色的栏杆 + 一节节拱起来的桥板 + 桥下几根红柱，跨过剑痕
func _bridge(pts: PackedVector3Array) -> void:
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(0.72, 0.2, 0.17)
	red.roughness = 0.6
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.42, 0.26, 0.17)
	wood.roughness = 0.8
	var half: float = SCAR_W * 0.5 + 6.0
	for i in range(pts.size() - 1):
		var p: Vector3 = pts[i]
		var d: float = _scar_dist(Vector2(p.x, p.z))
		if d > half:
			continue
		var t: Vector3 = (pts[i + 1] - p).normalized()
		var perp := Vector3(-t.z, 0, t.x)
		var seg: float = p.distance_to(pts[i + 1])
		var arch: float = 2.6 * (1.0 - pow(d / half, 2.0))      # 拱桥：中间高
		var mid: Vector3 = p + t * seg * 0.5 + Vector3(0, arch, 0)
		_rbox(mid + Vector3(0, 0.3, 0), Vector3(ROAD_W * 0.8, 0.6, seg + 0.4), atan2(t.x, t.z), wood)
		for side: float in [-1.0, 1.0]:
			_rbox(mid + perp * side * (ROAD_W * 0.4 - 0.3) + Vector3(0, 1.4, 0), Vector3(0.35, 1.6, seg + 0.4), atan2(t.x, t.z), red)
			_rbox(mid + perp * side * (ROAD_W * 0.4 - 0.3) + Vector3(0, 2.3, 0), Vector3(0.5, 0.3, seg + 0.4), atan2(t.x, t.z), red)
		if i % 3 == 0 and d < SCAR_W * 0.5:
			for side2: float in [-1.0, 1.0]:
				_rbox(mid + perp * side2 * ROAD_W * 0.3 - Vector3(0, 9.0 + arch * 0.5, 0), Vector3(0.9, 18.0, 0.9), atan2(t.x, t.z), red)


func _rbox(center: Vector3, size: Vector3, yaw: float, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = center
	mi.rotation.y = yaw
	add_child(mi)


func _build_plazas() -> void:
	var m: ShaderMaterial = _mat("court", COURT_SHADER)
	for k: String in node_pos.keys():
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = PLAZA_R
		cm.bottom_radius = PLAZA_R
		cm.height = 0.08
		cm.radial_segments = 28
		mi.mesh = cm
		mi.material_override = m
		mi.position = node_pos[k] + Vector3(0, 0.04, 0)
		add_child(mi)


# ---------------------------------------------------------------- 九条冰尾 / 紫色冰山
func _ice_material() -> StandardMaterial3D:
	if _ice_mat == null:
		_ice_mat = StandardMaterial3D.new()
		_ice_mat.albedo_color = Color(0.58, 0.74, 0.96)
		_ice_mat.emission_enabled = true
		_ice_mat.emission = Color(0.4, 0.3, 0.85)
		_ice_mat.emission_energy_multiplier = 0.22
		_ice_mat.roughness = 0.35
		_ice_mat.metallic = 0.1
	return _ice_mat


## 九条巨大的冰质狐狸尾巴：从岛北沿的一处根部扇形张开，往上扬、尾尖往回卷；一节节的方块越到尖端越细
func _build_tails() -> void:
	var tfs: Array[Transform3D] = []
	var north := Vector3(sin(_rot), 0, -cos(_rot))
	var east := Vector3(cos(_rot), 0, sin(_rot))
	var root_c: Vector3 = _island_c + north * (_island_r - 26.0)
	for i in range(TAIL_N):
		var f: float = (float(i) - float(TAIL_N - 1) * 0.5) / (float(TAIL_N - 1) * 0.5)     # -1 … 1
		var fan: float = f * 1.25
		var out_dir: Vector3 = (north * cos(fan) + east * sin(fan)).normalized()
		var root: Vector3 = root_c + east * f * 110.0 - north * absf(f) * 30.0 + Vector3(0, -2.0, 0)
		var L: float = 170.0 - absf(f) * 40.0
		var p0: Vector3 = root
		var p1: Vector3 = root + out_dir * L * 0.45 + Vector3(0, L * 0.25, 0)
		var p2: Vector3 = root + out_dir * L * 0.55 + Vector3(0, L * 0.9, 0)
		var p3: Vector3 = root + out_dir * L * 0.25 + Vector3(0, L * 1.08, 0)
		var segs := 22
		var prev: Vector3 = p0
		for s in range(1, segs + 1):
			var t: float = float(s) / float(segs)
			var u: float = 1.0 - t
			var p: Vector3 = p0 * u * u * u + p1 * 3.0 * u * u * t + p2 * 3.0 * u * t * t + p3 * t * t * t
			var r: float = 6.5 * pow(1.0 - t, 0.7) + 1.2
			var d: Vector3 = p - prev
			var len: float = d.length()
			var mid: Vector3 = (p + prev) * 0.5
			var basis := Basis.looking_at(d.normalized(), Vector3.UP if absf(d.normalized().y) < 0.95 else Vector3.RIGHT)
			var roll := Basis(Vector3.FORWARD, float(s) * 0.21 + float(i))
			tfs.append(Transform3D(basis * roll * Basis().scaled(Vector3(r * 2.0, r * 2.0, len * 1.12)), mid))
			prev = p
		_occ_disc(Vector2(root.x, root.z), 16.0)
		# 根部冻在地上的冰晶
		_place("ice_shard_b", root + east * _rng.randf_range(-6.0, 6.0), _rng.randf() * TAU, _rng.randf_range(0.9, 1.5))
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = bm
	mm.instance_count = tfs.size()
	for i2 in range(tfs.size()):
		mm.set_instance_transform(i2, tfs[i2])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _ice_material()
	add_child(mmi)


func _mountain_mat() -> ShaderMaterial:
	if _mount_mat == null:
		_mount_mat = _mat("mountain", MOUNTAIN_SHADER)
		_mount_mat.set_shader_parameter("top", float(_mount.get("height", 5)) * TERRACE)
	return _mount_mat


## 山体的轮廓：离山心 r 米处的高度。台阶节点在 RING_R0 - RING_DR × h 处、高 h × TERRACE，山体在每级台阶下方 5 米(台阶 = 冰柱托着的平台，
## 坡道 = 冰堤)，往外到 MOUNT_R 处落到地面；山顶平台之内平的
func _mprofile(r: float) -> float:
	var pts: Array = [[MOUNT_R, -0.5], [MOUNT_R - 6.0, 1.5]]
	for hh in range(1, 5):
		pts.append([RING_R0 - RING_DR * float(hh), TERRACE * float(hh) - 5.0])
	pts.append([SUMMIT_R - 2.0, TERRACE * 5.0 - 7.5])
	pts.append([0.0, TERRACE * 5.0 - 5.0])
	if r >= MOUNT_R:
		return -0.5
	for i in range(pts.size() - 1):
		var a: Array = pts[i]
		var b: Array = pts[i + 1]
		if r <= float(a[0]) and r >= float(b[0]):
			var t: float = (float(a[0]) - r) / maxf(0.001, float(a[0]) - float(b[0]))
			return lerpf(float(a[1]), float(b[1]), t)
	return float(pts.back()[1])


## 冰山：钟形的紫冰山体(旋转面，外沿参差)；每级台阶各一根紫冰柱托着圆形的石庭，坡道是斜着爬上去的冰堤(连线)；
## 山顶的石庭上是首领的神社(首领就在神社里)，神社背后立着一座更高的冰峰(山顶的光从它顶上射出)；进山的路口立一座鸟居
func _build_mountain(_run: Run) -> void:
	if _mount.is_empty():
		return
	var mc: Vector3 = _mount_c
	_occ_disc(Vector2(mc.x, mc.z), MOUNT_R + 6.0)
	var mat: ShaderMaterial = _mountain_mat()
	var body := MeshInstance3D.new()
	body.mesh = _mountain_mesh(MOUNT_R, 22, 12, _rng.randf() * TAU)
	body.material_override = mat
	body.position = mc
	add_child(body)
	# 台阶：每个山上的节点一根冰柱(从地面托到它的高度)，山顶那根更粗(神社的平台)
	var top_key: String = str(_mount["center"])
	var path: Array = _mount["path"]
	var mkeys: Array = path.duplicate()
	mkeys.append(top_key)
	for k: String in mkeys:
		var p: Vector3 = node_pos[k]
		var pil := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = SUMMIT_R if k == top_key else PLAZA_R + 1.8
		cm.bottom_radius = cm.top_radius + 3.5
		cm.height = p.y + 1.0
		cm.radial_segments = 24
		pil.mesh = cm
		pil.material_override = _ice_material()
		pil.position = Vector3(p.x, p.y - cm.height * 0.5, p.z)
		add_child(pil)
		if k != top_key:
			for j in range(2):
				var a: float = _rng.randf() * TAU
				_place("ice_shard_a", p + Vector3(cos(a), 0, sin(a)) * (PLAZA_R + 0.6), _rng.randf() * TAU, _rng.randf_range(0.25, 0.45))
	# 山顶：神社正面朝着上来的坡道；背后一座冰峰 + 几根冰尖
	var top: Vector3 = node_pos[top_key]
	var last: Vector3 = node_pos[str(path.back())]
	var fwd: Vector3 = top - last
	fwd.y = 0.0
	fwd = fwd.normalized()
	var back: Vector3 = -fwd
	var yaw: float = atan2(-fwd.x, -fwd.z)
	_place("jp_shrine", top + back * 4.5, yaw + PI, 0.62)
	var side := Vector3(-fwd.z, 0, fwd.x)
	_place("jp_lantern", top + fwd * 3.0 + side * 5.0, yaw)
	_place("jp_lantern", top + fwd * 3.0 - side * 5.0, yaw)
	var crag_c: Vector3 = top + back * 15.0
	_crystal(Vector3(crag_c.x, top.y - 18.0, crag_c.z), 15.0, CRAG_H - (top.y - 18.0), 9, 0.0, _rng.randf() * TAU, mat)
	for j2 in range(4):
		var a2: float = _rng.randf_range(-1.2, 1.2)
		var dir2: Vector3 = back.rotated(Vector3.UP, a2)
		var sp: Vector3 = top + dir2 * _rng.randf_range(8.0, 11.0)
		_crystal(Vector3(sp.x, top.y - 4.0, sp.z), _rng.randf_range(2.5, 4.0), _rng.randf_range(10.0, 18.0), 6, _rng.randf_range(0.1, 0.3), _rng.randf() * TAU, mat)
	# 山脚一圈歪着的大晶体(避开路和台阶)：冰山从岛里长出来的样子
	var mnodes: Array = []
	for mk: String in mkeys:
		mnodes.append(node_pos[mk])
	var cnt := 0
	for tries in range(160):
		if cnt >= 14:
			break
		var a3: float = _rng.randf() * TAU
		var rad3: float = _rng.randf_range(34.0, MOUNT_R + 4.0)
		var cp: Vector3 = mc + Vector3(cos(a3), 0, sin(a3)) * rad3
		if float(_nearest_road(Vector2(cp.x, cp.z))[0]) < 11.0 or _scar_dist(Vector2(cp.x, cp.z)) < SCAR_W * 0.5 + 8.0:
			continue
		var ok := true
		for mp: Vector3 in mnodes:
			if Vector2(mp.x, mp.z).distance_to(Vector2(cp.x, cp.z)) < PLAZA_R + 9.0:
				ok = false
		if not ok:
			continue
		var base_y: float = _mprofile(rad3) - 3.0
		_crystal(Vector3(cp.x, base_y, cp.z), _rng.randf_range(4.0, 8.0), _rng.randf_range(14.0, 30.0), 5 + _rng.randi() % 3,
			_rng.randf_range(0.12, 0.35), _rng.randf() * TAU, mat)
		cnt += 1
	_berg_light = OmniLight3D.new()
	_berg_light.light_color = Color("#b48cff")
	_berg_light.light_energy = 3.0
	_berg_light.omni_range = 110.0
	_berg_light.shadow_enabled = false
	_berg_light.position = top + Vector3(0, 16.0, 0)
	add_child(_berg_light)
	var beam := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 4.0
	bc.bottom_radius = 7.0
	bc.height = 140.0
	bc.radial_segments = 16
	bc.cap_top = false
	bc.cap_bottom = false
	beam.mesh = bc
	var bmat := StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.albedo_color = Color(0.7, 0.5, 1.0, 0.1)
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam.material_override = bmat
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.position = Vector3(crag_c.x, CRAG_H + 65.0, crag_c.z)
	add_child(beam)
	# 进山的路口：一座鸟居对着上山的坡道
	var entry: Vector3 = node_pos[str(_mount["entry"])]
	var first: Vector3 = node_pos[str(path[0])]
	var ed: Vector3 = first - entry
	ed.y = 0.0
	ed = ed.normalized()
	_place("bld_torii", entry + ed * (PLAZA_R + 1.5), atan2(ed.x, ed.z) + PI * 0.5, 1.2)


## 带棱的晶体：底面一圈顶点带随机起伏、顶上一个尖，整体歪 tilt 弧度；不共用顶点 → 每个面平着着色
func _crystal(base: Vector3, r: float, hgt: float, segs: int, tilt: float, yaw: float, mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring: Array[Vector3] = []
	for i in range(segs):
		var a: float = TAU * float(i) / float(segs)
		var rr: float = r * _rng.randf_range(0.7, 1.15)
		ring.append(Vector3(cos(a) * rr, _rng.randf_range(-0.15, 0.1) * hgt, sin(a) * rr))
	var apex := Vector3(_rng.randf_range(-0.15, 0.15) * r, hgt, _rng.randf_range(-0.15, 0.15) * r)
	var low := Vector3(0, -hgt * 0.35, 0)
	for i2 in range(segs):
		var p0: Vector3 = ring[i2]
		var p1: Vector3 = ring[(i2 + 1) % segs]
		for v: Vector3 in [p0, apex, p1, p0, p1, low]:
			st.set_uv(Vector2(0, 0))
			st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.position = base
	mi.rotation = Vector3(tilt * cos(yaw * 1.7), yaw, tilt * sin(yaw * 1.7))
	add_child(mi)


## 钟形的山体：旋转面(半径 R)，轮廓按 _mprofile；外沿(离路远的地方)起伏大；不共用顶点 → 平面着色的棱
func _mountain_mesh(R: float, segs: int, rings: int, seed: float) -> ArrayMesh:
	var grid: Array = []
	for j in range(rings + 1):
		var r: float = R * pow(float(j) / float(rings), 0.8)
		var row: Array[Vector3] = []
		for i in range(segs):
			var a: float = TAU * float(i) / float(segs) + (0.5 * TAU / float(segs) if j % 2 == 1 else 0.0)
			var wob: float = clampf((r - (R - 12.0)) / 12.0, 0.0, 1.0)
			var rr: float = r * (1.0 + wob * (0.07 * sin(a * 5.0 + seed) + 0.04 * sin(a * 11.0 - seed * 1.3)) + (1.0 - wob) * _rng.randf_range(-0.03, 0.03))
			var hgt: float = _mprofile(r) * (1.0 + wob * 0.1 * sin(a * 7.0 + seed)) + _rng.randf_range(-0.6, 0.6)
			if j == 0:
				rr = 0.0
				hgt = _mprofile(0.0)
			row.append(Vector3(cos(a) * rr, hgt, sin(a) * rr))
		grid.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j2 in range(rings):
		for i2 in range(segs):
			var a0: Vector3 = grid[j2][i2]
			var b0: Vector3 = grid[j2][(i2 + 1) % segs]
			var c0: Vector3 = grid[j2 + 1][i2]
			var d0: Vector3 = grid[j2 + 1][(i2 + 1) % segs]
			for v: Vector3 in [a0, b0, c0, b0, d0, c0]:
				st.set_uv(Vector2(0, 0))
				st.add_vertex(v)
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------- 节点附近的和风建筑 / 岛上散落的坚冰与雪松
const ISLAND_DETAIL := [["jp_house", 6.5], ["jp_house", 6.5], ["jp_shrine", 10.0], ["jp_wall", 7.0], ["jp_pine", 4.5], ["jp_pine", 4.5],
	["jp_lantern", 1.6], ["ice_shard_a", 3.5], ["ice_shard_c", 5.0]]


func _build_detail() -> void:
	var keys: Array = node_pos.keys()
	keys.sort()
	var pagodas := 0
	for k: String in keys:
		var np: Vector3 = node_pos[k]
		if np.y > 0.5:
			continue
		var placed := 0
		for tries in range(70):
			if placed >= 5:
				break
			var spec: Array = ISLAND_DETAIL[_rng.randi() % ISLAND_DETAIL.size()]
			var rad: float = float(spec[1])
			var a: float = _rng.randf() * TAU
			var p := np + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(PLAZA_R + rad + 1.0, PLAZA_R + rad + 14.0)
			if not _inside(p, rad) or not _occ_free(Vector2(p.x, p.z), rad):
				continue
			var nr: Array = _nearest_road(Vector2(p.x, p.z))
			var d: Vector2 = nr[1]
			var yaw: float = atan2(d.x, d.y) + (PI * 0.5 if _rng.randf() < 0.5 else -PI * 0.5)
			_place(str(spec[0]), p, yaw)
			_occ_disc(Vector2(p.x, p.z), rad)
			placed += 1
		# 路口边的石灯笼
		for j in range(2):
			var a2: float = _rng.randf() * TAU
			var p2: Vector3 = np + Vector3(cos(a2), 0, sin(a2)) * (PLAZA_R + 0.8)
			if float(_nearest_road(Vector2(p2.x, p2.z))[0]) > ROAD_W * 0.5 + 1.5 and _inside(p2, 1.0):
				_place("jp_lantern", p2, a2 + PI)
				_hot.append(p2)
	# 一两座宝塔(远离路，整个岛上最高的建筑)
	for tries2 in range(200):
		if pagodas >= 2:
			break
		var a3: float = _rng.randf() * TAU
		var p3: Vector3 = _island_c + Vector3(cos(a3), 0, sin(a3)) * _rng.randf_range(_island_r * 0.25, _island_r * 0.8)
		if float(_nearest_road(Vector2(p3.x, p3.z))[0]) < 16.0 or not _inside(p3, 9.0) or not _occ_free(Vector2(p3.x, p3.z), 9.0):
			continue
		_place("jp_pagoda", p3, _rng.randf() * TAU)
		_occ_disc(Vector2(p3.x, p3.z), 10.0)
		pagodas += 1


## 在岛上(离岛沿至少 margin 米、不在剑痕里)
func _inside(p: Vector3, margin: float) -> bool:
	if p.distance_to(_island_c) > _island_r * 0.95 - margin:
		return false
	return _scar_dist(Vector2(p.x, p.z)) > SCAR_W * 0.5 + 3.0 + margin


## 岛上其余的地方：坚冰 + 雪松 + 零星的民家、白墙(离路远一点)
func _build_fabric() -> void:
	var specs: Array = [["ice_shard_a", 3.0, 240], ["ice_shard_b", 4.5, 90], ["ice_shard_c", 5.0, 70], ["jp_pine", 4.0, 170], ["jp_house", 6.5, 36], ["jp_wall", 7.0, 28]]
	for sp: Array in specs:
		var nm: String = sp[0]
		var rad: float = float(sp[1])
		var want: int = int(sp[2])
		var placed := 0
		for tries in range(want * 12):
			if placed >= want:
				break
			var a: float = _rng.randf() * TAU
			var p: Vector3 = _island_c + Vector3(cos(a), 0, sin(a)) * sqrt(_rng.randf()) * _island_r * 0.95
			if not _inside(p, rad) or not _occ_free(Vector2(p.x, p.z), rad * 0.8):
				continue
			var road_d: float = float(_nearest_road(Vector2(p.x, p.z))[0])
			if (nm == "jp_house" or nm == "jp_wall") and road_d < 15.0:
				continue
			var sc: float = _rng.randf_range(0.7, 1.6) if nm.begins_with("ice_") else _rng.randf_range(0.9, 1.15)
			_place(nm, p, _rng.randf() * TAU, sc)
			_occ_disc(Vector2(p.x, p.z), rad * 0.8 * sc)
			placed += 1


## 路边的石灯笼(每十几米一盏，暖光)：从高空看，亮着的路就是能走的路网
func _build_lanterns() -> void:
	var glows: Array[Vector3] = []
	for e: Dictionary in _edges:
		var pts: PackedVector3Array = e["pts"]
		var acc := 0.0
		for i in range(1, pts.size()):
			acc += pts[i].distance_to(pts[i - 1])
			if acc < 13.0:
				continue
			acc = 0.0
			if _scar_dist(Vector2(pts[i].x, pts[i].z)) < SCAR_W * 0.5 + 5.0:
				continue
			var t: Vector3 = (pts[i] - pts[i - 1]).normalized()
			var perp := Vector3(-t.z, 0, t.x)
			var side: float = 1.0 if (i / 4) % 2 == 0 else -1.0
			var p: Vector3 = pts[i] + perp * side * (ROAD_W * 0.4 + 1.0)
			_place("jp_lantern", p, atan2(t.x, t.z))
			glows.append(p)
	for hp: Vector3 in _hot:
		glows.append(hp)
	if glows.is_empty():
		return
	var gq := QuadMesh.new()
	gq.size = Vector2(9.0, 9.0)
	gq.orientation = PlaneMesh.FACE_Y
	var gm := ShaderMaterial.new()
	gm.shader = _shader("glow", GLOW_SHADER)
	gm.set_shader_parameter("color", Color(1.0, 0.78, 0.45, 0.26))
	gq.material = gm
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = gq
	mm.instance_count = glows.size()
	for i2 in range(glows.size()):
		mm.set_instance_transform(i2, Transform3D(Basis(), Vector3(glows[i2].x, glows[i2].y + 0.1, glows[i2].z)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


func _process(dt: float) -> void:
	_tt += dt
	if _berg_light != null:
		_berg_light.light_energy = 2.6 + 0.6 * sin(_tt * 1.3)
