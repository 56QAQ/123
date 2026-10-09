class_name CityOverworld
extends Node3D
## 第一章·红之章的大地图(战斗外)：从高空俯瞰一座黑夜里燃烧的大都市(现代日本)。
##  · 逻辑还是黑流树海式的格点(ChapterMap)，但画面上不横平竖直：格点的位置整体弯曲、再各自错开；
##    节点之间有路 = 一条弯曲的大街(两端是路口广场)；没有路的地方就是成片的楼，自然走不通
##  · 一条大河弯弯曲曲地穿城而过(只在有路的地方架桥)；北边是一段坍塌的首都高；远处的城市一直延伸进雾里
##  · 街区从起点到首领依次是居民区(民宅 / 团地 / 小神社) → 学校(校舍 + 操场) → 市中心(写字楼 / 商店街 / 倒下的高楼)
##    → 工厂区(厂房 / 红白烟囱 / 球罐 / 熔炉)
##  · 细节分两级：节点附近(开车时镜头会拉近的地方)放体素模型；其余的城市是便宜的楼块(着色器画窗户，零星透出火光)，
##    废墟楼的楼顶参差不齐
##  · 比例按卡车定(tools/model_city.gd)：一层楼 1.75 m，卡车 3 m 长
## 节点按钮由 HUD 画；这里提供 node_pos、路线预览、卡车沿路开出去的折线。

const S := 40.0                 # 格点间距(米)
const ROW := 0.85               # 行距 = S × ROW
const ROAD_W := 9.0
const PLAZA_R := 8.5
const RIVER_W := 30.0
const RIVER_GAP := 28.0         # 河两岸的两列格点额外拉开的距离
const TYPE_COLORS := {
	"start": Color("#cfd6df"), "fight": Color("#ff5a3c"), "elite": Color("#ff9b2a"), "boss": Color("#ff2a2a"),
	"rest": Color("#5be08a"), "event": Color("#57c8ff"), "shop_black": Color("#ffd24a"), "shop_parts": Color("#c58bff"),
	"unknown": Color("#8a8f99"),
}

const ROAD_SHADER := """
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
	vec3 c = vec3(0.15, 0.142, 0.138) * (0.85 + 0.3 * n2(wpos.xz * 0.5));
	c *= 1.0 - 0.35 * smoothstep(0.62, 0.8, n2(wpos.xz * 0.12 + 3.1));
	vec3 paint = vec3(0.7, 0.68, 0.62) * (0.6 + 0.3 * n2(wpos.xz * 2.0));
	float edge = step(0.07, across) * (1.0 - step(0.1, across)) + step(0.9, across) * (1.0 - step(0.93, across));
	float mid = (1.0 - step(0.025, abs(across - 0.5))) * step(fract(along / 4.0), 0.5);
	c = mix(c, paint, clamp(edge + mid, 0.0, 1.0) * 0.75);
	float walk = step(across, 0.05) + step(0.95, across);
	c = mix(c, vec3(0.22, 0.21, 0.2), walk);
	ALBEDO = c;
	ROUGHNESS = 0.9;
}
"""

const PLAZA_SHADER := """
shader_type spatial;
render_mode diffuse_burley;
varying vec3 wpos;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y); }
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	ALBEDO = vec3(0.15, 0.142, 0.138) * (0.85 + 0.3 * n2(wpos.xz * 0.5));
	ROUGHNESS = 0.9;
}
"""

const PAD_SHADER := """
shader_type spatial;
render_mode diffuse_burley;
uniform vec3 base : source_color = vec3(0.3, 0.22, 0.17);
varying vec3 wpos;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y); }
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 c = base * (0.8 + 0.35 * n2(wpos.xz * 0.9));
	vec2 q = (UV - 0.5) * vec2(1.0, 1.7);
	float r = length(q);
	float line = 1.0 - smoothstep(0.0, 0.012, abs(r - 0.36));
	line += 1.0 - smoothstep(0.0, 0.012, abs(r - 0.43));
	c = mix(c, vec3(0.6, 0.57, 0.52), clamp(line, 0.0, 1.0) * 0.75);
	ALBEDO = c;
	ROUGHNESS = 0.95;
}
"""

const WATER_SHADER := """
shader_type spatial;
render_mode unshaded;
varying vec3 wpos;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y); }
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float r = n2(wpos.xz * vec2(0.08, 0.5) + vec2(0.0, TIME * 0.3)) * 0.6 + n2(wpos.xz * 0.9 - TIME * 0.2) * 0.4;
	vec3 base = vec3(0.003, 0.005, 0.009) + vec3(0.002, 0.003, 0.005) * r;
	// 水面：映着夜空的冷色底光 + 两岸火光的暗红倒影 + 随波纹闪动的橙色碎光(大块一点，从高空也看得见)
	float glint = smoothstep(0.72, 0.92, n2(wpos.xz * vec2(0.3, 1.5) + vec2(TIME * 0.15, 0.0)));
	float band = 0.4 + 0.6 * n2(wpos.xz * 0.02 + 7.0);
	ALBEDO = base + vec3(0.018, 0.004, 0.002) * band + vec3(1.0, 0.45, 0.12) * glint * 0.3 * band * band;
}
"""

## 便宜的楼块：BoxMesh + 着色器画窗户。INSTANCE_CUSTOM = (随机种子, 类型, 着火程度, 墙色)
##   类型 > 0.75：废墟(楼顶参差)；0.25~0.75：没有窗户的构筑物(高架、桥、堤)；其余：普通的楼
const BLOCK_SHADER := """
shader_type spatial;
render_mode diffuse_burley, cull_disabled;
varying vec3 lp;
varying vec3 scl;
varying vec4 cust;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() {
	scl = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	lp = (VERTEX + vec3(0.0, 0.5, 0.0)) * scl;
	cust = INSTANCE_CUSTOM;
}
void fragment() {
	float seed = cust.x * 97.0;
	bool plain = cust.y > 0.25 && cust.y < 0.75;
	if (cust.y > 0.75) {
		float jag = scl.y * (0.6 + 0.32 * h21(vec2(floor((lp.x + lp.z) * 0.5), seed)));
		if (lp.y > jag) { discard; }
	}
	vec3 wn = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	vec3 wall = mix(vec3(0.13, 0.125, 0.125), vec3(0.24, 0.215, 0.195), cust.w);
	wall *= 0.85 + 0.15 * h21(vec2(seed, 3.0));
	wall *= 1.0 - 0.45 * clamp(lp.y / max(scl.y, 1.0), 0.0, 1.0) * cust.z;
	vec3 col = wall;
	vec3 emi = vec3(0.0);
	if (!FRONT_FACING) {
		col = wall * 0.22;
	} else if (abs(wn.y) > 0.7) {
		col = wall * (plain ? 0.8 : 0.55) * (0.8 + 0.4 * h21(floor(lp.xz * 0.5) + seed));
	} else if (!plain) {
		float along = abs(wn.x) > abs(wn.z) ? lp.z : lp.x;
		float fl = floor(lp.y / 1.75);
		float fy = fract(lp.y / 1.75);
		float cx = floor(along / 1.6);
		float fx = fract(along / 1.6);
		if (fy > 0.32 && fy < 0.78 && fx > 0.18 && fx < 0.72 && lp.y > 1.0) {
			float r = h21(vec2(cx + seed, fl));
			col = vec3(0.025, 0.03, 0.035);
			float lit = step(0.94 - cust.z * 0.2, r);
			// 着火的楼：一段一段地透出火光(只在中下层)
			float burn = step(0.55, h21(vec2(floor(cx / 3.0) + seed, fl))) * step(0.55, cust.z) * step(fl, floor(scl.y / 1.75) * 0.6 + 1.0);
			vec3 warm = mix(vec3(1.0, 0.55, 0.18), vec3(1.0, 0.3, 0.06), h21(vec2(cx, fl + seed)));
			emi = warm * max(lit * 1.4, burn * 2.2);
		}
	}
	ALBEDO = col;
	EMISSION = emi;
	ROUGHNESS = 0.9;
}
"""

const GLOW_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 color : source_color = vec4(1.0, 0.4, 0.1, 1.0);
void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float k = pow(max(0.0, 1.0 - r), 2.2);
	ALBEDO = color.rgb;
	ALPHA = k * color.a;
}
"""

const RING_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 color : source_color;
uniform float pulse = 0.0;
void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float band = smoothstep(0.7, 0.78, r) * (1.0 - smoothstep(0.88, 0.97, r));
	float fill = (1.0 - smoothstep(0.0, 0.75, r)) * 0.15;
	float k = 0.75 + 0.25 * sin(TIME * 3.0) * pulse;
	ALBEDO = color.rgb * k;
	ALPHA = (band + fill) * color.a;
}
"""

const LINE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 color : source_color;
uniform float speed = 0.0;
uniform float period = 5.0;
uniform float duty = 0.5;
void fragment() {
	float d = step(fract((UV.y - TIME * speed) / period), duty);
	float edge = smoothstep(0.0, 0.3, UV.x) * smoothstep(1.0, 0.7, UV.x);
	ALBEDO = color.rgb;
	ALPHA = color.a * d * edge;
}
"""

var w: int = 7
var h: int = 6
var node_pos: Dictionary = {}          # 格点 key -> 世界坐标(路口中心)
var _edges: Array = []                 # [{a, b, pts: PackedVector3Array, cross}]
var _river: PackedVector3Array = PackedVector3Array()
var _river_col: int = -1
var _rot: float = 0.0
var _ph1: float = 0.0
var _ph2: float = 0.0
var _bounds: Rect2 = Rect2()
var _rng := RandomNumberGenerator.new()
var _groups: Dictionary = {}           # 体素模型 -> [Transform3D]
var _blocks: Array = []                # 楼块 [Transform3D, Color(custom)]
var _occ: PackedByteArray = PackedByteArray()
var _occ_o: Vector2 = Vector2.ZERO
var _occ_w: int = 0
var _occ_h: int = 0
const OCC_RES := 2.0
var _markers: Dictionary = {}          # key -> ShaderMaterial
var _lines: Array = []                 # [{a, b, mat}]
var _path: Array[MeshInstance3D] = []
var _fires: int = 0
var _lights: int = 0
var _sh: Dictionary = {}
var _hot: Array[Vector3] = []          # 着火的地方


func center() -> Vector3:
	return Vector3(_bounds.get_center().x, 0.0, _bounds.get_center().y)


func span() -> float:
	return maxf(_bounds.size.x, _bounds.size.y * 1.6)


func _shader(name: String, code: String) -> Shader:
	if not _sh.has(name):
		var s := Shader.new()
		s.code = code
		_sh[name] = s
	return _sh[name]


func _mat(name: String, code: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader(name, code)
	return m


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
	var gm: Dictionary = run.gmap
	w = int(gm["w"])
	h = int(gm["h"])
	_rng.seed = int(gm.get("seed", run.seed_value)) * 13 + 5
	_layout_nodes(gm)
	_layout_river()
	_layout_edges(gm)
	var mn := Vector2(1e9, 1e9)
	var mx := Vector2(-1e9, -1e9)
	for k: String in node_pos.keys():
		var p: Vector3 = node_pos[k]
		mn = Vector2(minf(mn.x, p.x), minf(mn.y, p.z))
		mx = Vector2(maxf(mx.x, p.x), maxf(mx.y, p.z))
	_bounds = Rect2(mn, mx - mn)
	_occ_init(_bounds.grow(300.0))
	_rasterize()
	WorldAssets.ground_red(self, center(), 2400.0, 0.5)
	_build_road_mesh()
	_build_plazas()
	_build_river()
	_build_highway()
	_build_landmarks(run)
	_build_detail()
	_build_fabric()
	_build_fires()
	_build_streetlights()
	_build_markers(run)
	WorldAssets.add_multimesh(self, _groups)
	_flush_blocks()
	var snow: GPUParticles3D = FireFX.ember_snow(Vector2(_bounds.size.x + 260.0, _bounds.size.y + 240.0), 900, 60.0)
	snow.position += center()
	add_child(snow)


# ---------------------------------------------------------------- 节点位置：弯曲的格网 + 错开
func _lattice(fx: float, fy: float) -> Vector3:
	var u: float = fx - float(w - 1) * 0.5
	var v: float = fy - float(h - 1) * 0.5
	var x: float = u * S
	if _river_col >= 0:
		x += RIVER_GAP * (0.5 if fx > float(_river_col) + 0.5 else -0.5) if absf(fx - (float(_river_col) + 0.5)) > 0.01 else 0.0
	var z: float = v * S * ROW
	x += 0.3 * S * sin(v * 0.95 + _ph1)
	z += 0.3 * S * ROW * sin(u * 0.75 + _ph2)
	return Vector3(x * cos(_rot) - z * sin(_rot), 0.0, x * sin(_rot) + z * cos(_rot))


func _layout_nodes(gm: Dictionary) -> void:
	_rot = _rng.randf_range(-0.14, 0.14)
	_ph1 = _rng.randf() * TAU
	_ph2 = _rng.randf() * TAU
	_river_col = clampi(int(w / 2) - 1 + _rng.randi_range(0, 1), 1, w - 3)
	var keys: Array = (gm["nodes"] as Dictionary).keys()
	keys.sort()
	for k: String in keys:
		var c: Vector2i = ChapterMap.cell(k)
		var p: Vector3 = _lattice(float(c.x), float(c.y))
		var j := Vector3(_rng.randf_range(-1.0, 1.0), 0.0, _rng.randf_range(-1.0, 1.0)) * S * 0.13
		node_pos[k] = p + j


## 河：沿着第 river_col 列和下一列之间的中线(上下都延伸到城市外)，平滑成曲线
func _layout_river() -> void:
	var raw: Array[Vector3] = []
	for i in range(-6, h + 6):
		var p: Vector3 = _lattice(float(_river_col) + 0.5, float(i))
		p.x += sin(float(i) * 1.7 + _ph1) * 4.0
		raw.append(p)
	_river = _smooth(raw, 6)


static func _smooth(pts: Array[Vector3], sub: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in range(pts.size() - 1):
		var p0: Vector3 = pts[maxi(i - 1, 0)]
		var p1: Vector3 = pts[i]
		var p2: Vector3 = pts[i + 1]
		var p3: Vector3 = pts[mini(i + 2, pts.size() - 1)]
		for s in range(sub):
			var t: float = float(s) / float(sub)
			var t2: float = t * t
			var t3: float = t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(pts.back())
	return out


## 路：每条连线是一条三次贝塞尔曲线(过河的那几条几乎是直的，像桥)
func _layout_edges(gm: Dictionary) -> void:
	for e: Array in gm["edges"]:
		var a: Vector3 = node_pos[e[0]]
		var b: Vector3 = node_pos[e[1]]
		var d: Vector3 = b - a
		var L: float = d.length()
		var dir: Vector3 = d / L
		var perp := Vector3(-dir.z, 0, dir.x)
		var ca: Vector2i = ChapterMap.cell(e[0])
		var cb: Vector2i = ChapterMap.cell(e[1])
		var cross: bool = mini(ca.x, cb.x) == _river_col and maxi(ca.x, cb.x) == _river_col + 1
		var k: float = 0.08 if cross else 0.36
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


# ---------------------------------------------------------------- 占地网格(放楼时避开路、河、广场)
func _occ_init(r: Rect2) -> void:
	_occ_o = r.position
	_occ_w = int(ceil(r.size.x / OCC_RES))
	_occ_h = int(ceil(r.size.y / OCC_RES))
	_occ = PackedByteArray()
	_occ.resize(_occ_w * _occ_h)


func _occ_disc(p: Vector2, rad: float) -> void:
	var c0 := Vector2i(int((p.x - rad - _occ_o.x) / OCC_RES), int((p.y - rad - _occ_o.y) / OCC_RES))
	var c1 := Vector2i(int((p.x + rad - _occ_o.x) / OCC_RES), int((p.y + rad - _occ_o.y) / OCC_RES))
	for y in range(maxi(0, c0.y), mini(_occ_h - 1, c1.y) + 1):
		for x in range(maxi(0, c0.x), mini(_occ_w - 1, c1.x) + 1):
			var q := Vector2(_occ_o.x + (float(x) + 0.5) * OCC_RES, _occ_o.y + (float(y) + 0.5) * OCC_RES)
			if q.distance_to(p) <= rad:
				_occ[y * _occ_w + x] = 1


func _occ_free(p: Vector2, rad: float) -> bool:
	var c0 := Vector2i(int((p.x - rad - _occ_o.x) / OCC_RES), int((p.y - rad - _occ_o.y) / OCC_RES))
	var c1 := Vector2i(int((p.x + rad - _occ_o.x) / OCC_RES), int((p.y + rad - _occ_o.y) / OCC_RES))
	if c1.x < 0 or c1.y < 0 or c0.x >= _occ_w or c0.y >= _occ_h:
		return true          # 网格外(远景)：不检查
	for y in range(maxi(0, c0.y), mini(_occ_h - 1, c1.y) + 1):
		for x in range(maxi(0, c0.x), mini(_occ_w - 1, c1.x) + 1):
			if _occ[y * _occ_w + x] != 0:
				return false
	return true


func _rasterize() -> void:
	for e: Dictionary in _edges:
		var pts: PackedVector3Array = e["pts"]
		for i in range(pts.size()):
			_occ_disc(Vector2(pts[i].x, pts[i].z), ROAD_W * 0.5 + 2.5)
	for k: String in node_pos.keys():
		var p: Vector3 = node_pos[k]
		_occ_disc(Vector2(p.x, p.z), PLAZA_R + 3.0)
	for i2 in range(_river.size()):
		_occ_disc(Vector2(_river[i2].x, _river[i2].z), RIVER_W * 0.5 + 5.0)


## 离最近的路的距离与那段路的走向(放楼时让楼面朝街)
func _nearest_road(p: Vector2) -> Array:
	var best := 1e9
	var dir := Vector2.RIGHT
	for e: Dictionary in _edges:
		var pts: PackedVector3Array = e["pts"]
		for i in range(0, pts.size() - 1, 2):
			var a := Vector2(pts[i].x, pts[i].z)
			var d: float = p.distance_to(a)
			if d < best:
				best = d
				dir = (Vector2(pts[i + 1].x, pts[i + 1].z) - a).normalized()
	return [best, dir]


# ---------------------------------------------------------------- 路面 / 路口 / 河 / 高架
func _strip(pts: PackedVector3Array, width: float, y: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dist := 0.0
	for i in range(pts.size()):
		var t: Vector3 = (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var perp := Vector3(-t.z, 0, t.x) * width * 0.5
		if i > 0:
			dist += pts[i].distance_to(pts[i - 1])
		st.set_uv(Vector2(0.0, dist))
		st.set_normal(Vector3.UP)
		st.add_vertex(pts[i] - perp + Vector3(0, y, 0))
		st.set_uv(Vector2(1.0, dist))
		st.set_normal(Vector3.UP)
		st.add_vertex(pts[i] + perp + Vector3(0, y, 0))
	# Godot 的正面是顺时针：从上往下看要顺时针排
	for i2 in range(pts.size() - 1):
		var a: int = i2 * 2
		st.add_index(a)
		st.add_index(a + 2)
		st.add_index(a + 1)
		st.add_index(a + 1)
		st.add_index(a + 2)
		st.add_index(a + 3)
	return st.commit()


func _build_road_mesh() -> void:
	var m: ShaderMaterial = _mat("road", ROAD_SHADER)
	for e: Dictionary in _edges:
		var mi := MeshInstance3D.new()
		mi.mesh = _strip(e["pts"], ROAD_W, 0.03)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		if bool(e["cross"]):
			_bridge(e["pts"])


## 桥：河面上方那一段加两道栏杆 + 桥墩
func _bridge(pts: PackedVector3Array) -> void:
	for i in range(pts.size() - 1):
		var p: Vector3 = pts[i]
		if _river_dist(Vector2(p.x, p.z)) > RIVER_W * 0.5 + 3.0:
			continue
		var t: Vector3 = (pts[i + 1] - p).normalized()
		var perp := Vector3(-t.z, 0, t.x)
		var seg: float = p.distance_to(pts[i + 1])
		for side: float in [-1.0, 1.0]:
			_box(p + perp * side * (ROAD_W * 0.5 - 0.2) + Vector3(0, 0.05, 0) + t * seg * 0.5, Vector3(0.35, 0.9, seg + 0.2), atan2(t.x, t.z), 0.6)
		if i % 4 == 0:
			_box(p + Vector3(0, -5.0, 0), Vector3(ROAD_W * 0.6, 5.0, 2.0), atan2(t.x, t.z), 0.3)


func _river_dist(p: Vector2) -> float:
	var best := 1e9
	for i in range(_river.size()):
		best = minf(best, p.distance_to(Vector2(_river[i].x, _river[i].z)))
	return best


func _build_plazas() -> void:
	var m: ShaderMaterial = _mat("plaza", PLAZA_SHADER)
	for k: String in node_pos.keys():
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = PLAZA_R
		cm.bottom_radius = PLAZA_R
		cm.height = 0.06
		cm.radial_segments = 24
		mi.mesh = cm
		mi.material_override = m
		mi.position = node_pos[k] + Vector3(0, 0.035, 0)
		add_child(mi)


func _build_river() -> void:
	var water := MeshInstance3D.new()
	water.mesh = _strip(_river, RIVER_W, 0.03)
	water.material_override = _mat("water", WATER_SHADER)
	add_child(water)
	# 河岸：两道混凝土堤顶步道 + 堤壁(看得见的落差)
	for side: float in [-1.0, 1.0]:
		var edge := PackedVector3Array()
		for i in range(_river.size()):
			var t: Vector3 = (_river[mini(i + 1, _river.size() - 1)] - _river[maxi(i - 1, 0)]).normalized()
			edge.append(_river[i] + Vector3(-t.z, 0, t.x) * side * (RIVER_W * 0.5 + 1.6))
		var bank := MeshInstance3D.new()
		bank.mesh = _strip(edge, 3.4, 0.05)
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color(0.3, 0.29, 0.27)
		bm.roughness = 0.9
		bank.material_override = bm
		add_child(bank)
		for i2 in range(edge.size() - 1):
			var a: Vector3 = edge[i2]
			var b: Vector3 = edge[i2 + 1]
			var t2: Vector3 = b - a
			var inward: Vector3 = Vector3(-t2.z, 0, t2.x).normalized() * side * 1.75
			_box((a + b) * 0.5 - inward, Vector3(0.5, 0.7, t2.length() + 0.1), atan2(t2.x, t2.z), 0.55)


## 首都高：城市北边一段弯曲的高架路，墩柱 + 桥面 + 护栏，中间塌了两截(一截斜着砸在地上)
func _build_highway() -> void:
	var raw: Array[Vector3] = []
	var z0: float = _bounds.position.y - 48.0
	for i in range(-5, 12):
		var x: float = _bounds.position.x - 120.0 + float(i) * 45.0
		raw.append(Vector3(x, 0, z0 + 16.0 * sin(float(i) * 0.6 + _ph2) - 6.0 * float(i % 3)))
	var pts: PackedVector3Array = _smooth(raw, 3)
	var gap0: int = pts.size() / 2 + _rng.randi_range(-3, 3)
	for i2 in range(pts.size() - 1):
		var a: Vector3 = pts[i2]
		var b: Vector3 = pts[i2 + 1]
		var t: Vector3 = b - a
		var yaw: float = atan2(t.x, t.z)
		var mid: Vector3 = (a + b) * 0.5
		var side := Vector3(-t.z, 0, t.x).normalized() * 6.2
		_occ_disc(Vector2(mid.x, mid.z), 9.0)
		if i2 % 2 == 0:
			_box(a, Vector3(3.0, 9.0, 2.4), yaw, 0.35)
		if i2 == gap0:
			# 塌下来的一截：一头还挂在墩上，一头砸在地上
			var tb := Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, 0.3) * Basis().scaled(Vector3(13.0, 1.4, t.length() + 0.5)), mid + Vector3(0, 4.6, 0))
			_blocks.append([tb, Color(_rng.randf(), 0.5, 0.3, 0.4)])
			continue
		if i2 == gap0 + 1:
			continue
		_box(mid + Vector3(0, 9.0, 0), Vector3(13.0, 1.2, t.length() + 0.3), yaw, 0.45)
		_box(mid + side + Vector3(0, 10.2, 0), Vector3(0.5, 1.0, t.length() + 0.3), yaw, 0.6)
		_box(mid - side + Vector3(0, 10.2, 0), Vector3(0.5, 1.0, t.length() + 0.3), yaw, 0.6)


## 没有窗户的构筑物(高架、桥、堤)：底面中心在 base，混进楼块的 MultiMesh 里一起画；shade = 墙色(0 暗 ~ 1 亮)
func _box(base: Vector3, size: Vector3, yaw: float, shade: float) -> void:
	var tf := Transform3D(Basis(Vector3.UP, yaw) * Basis().scaled(size), base + Vector3(0, size.y * 0.5, 0))
	_blocks.append([tf, Color(_rng.randf(), 0.5, 0.0, shade)])


# ---------------------------------------------------------------- 街区：区的划分
## u = 沿起点→首领方向的位置(0 = 起点一侧，1 = 首领一侧)
func _u(p: Vector3) -> float:
	return clampf((p.x - _bounds.position.x) / maxf(1.0, _bounds.size.x), -0.5, 1.5)


func _district(p: Vector3) -> String:
	var u: float = _u(p)
	if u < 0.3:
		return "res"
	if u < 0.68:
		return "down"
	return "fac"


## 地标：学校(居民区和市中心交界)、首领旁的熔炉、工厂区的烟囱群、居民区的小神社
func _build_landmarks(run: Run) -> void:
	for tries in range(300):
		var p := Vector3(lerpf(_bounds.position.x, _bounds.end.x, _rng.randf_range(0.18, 0.45)), 0, _rng.randf_range(_bounds.position.y - 10.0, _bounds.end.y + 10.0))
		var nr: Array = _nearest_road(Vector2(p.x, p.z))
		if float(nr[0]) < 15.0 or float(nr[0]) > 32.0 or not _occ_free(Vector2(p.x, p.z), 11.0):
			continue
		var d: Vector2 = nr[1]
		var yaw: float = atan2(d.x, d.y) + PI * 0.5
		var back := Vector3(sin(yaw + PI * 0.5), 0, cos(yaw + PI * 0.5)) * 17.0
		var fp: Vector3 = p + back
		if not _occ_free(Vector2(fp.x, fp.z), 9.0):
			fp = p - back
			if not _occ_free(Vector2(fp.x, fp.z), 9.0):
				continue
		_place("bld_school", p, yaw)
		_occ_disc(Vector2(p.x, p.z), 11.0)
		var pad := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(26, 15)
		pad.mesh = pm
		pad.material_override = _mat("pad", PAD_SHADER)
		pad.position = fp + Vector3(0, 0.05, 0)
		pad.rotation.y = yaw
		add_child(pad)
		_place("bld_goal", fp + Vector3(sin(yaw + PI * 0.5), 0, cos(yaw + PI * 0.5)) * 11.0, yaw + PI * 0.5)
		_place("bld_goal", fp - Vector3(sin(yaw + PI * 0.5), 0, cos(yaw + PI * 0.5)) * 11.0, yaw - PI * 0.5)
		_occ_disc(Vector2(fp.x, fp.z), 13.0)
		_hot.append(p + Vector3(-5, 3, 0))
		break
	# 首领旁的熔炉
	var bp: Vector3 = node_pos[str(run.gmap["boss"])]
	for tries2 in range(160):
		var a: float = _rng.randf() * TAU
		var p2: Vector3 = bp + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(18.0, 30.0)
		if _occ_free(Vector2(p2.x, p2.z), 6.5):
			_place("bld_furnace", p2, _rng.randf() * TAU)
			_occ_disc(Vector2(p2.x, p2.z), 7.0)
			_fire_at(p2 + Vector3(0, 16.5, 0), 2.6, true)
			break
	# 首领路口自己也在烧
	_fire_at(bp + Vector3(0, 0.4, 0), 1.6, true)
	# 工厂区的红白烟囱
	for i in range(9):
		for tries3 in range(40):
			var p3 := Vector3(lerpf(_bounds.position.x, _bounds.end.x, _rng.randf_range(0.7, 1.25)), 0, _rng.randf_range(_bounds.position.y - 80.0, _bounds.end.y + 10.0))
			if _occ_free(Vector2(p3.x, p3.z), 3.5):
				_place("bld_chimney", p3, 0.0, _rng.randf_range(1.0, 1.5))
				_occ_disc(Vector2(p3.x, p3.z), 3.5)
				break
	# 小神社的鸟居
	for tries4 in range(120):
		var p4 := Vector3(lerpf(_bounds.position.x, _bounds.end.x, _rng.randf_range(-0.05, 0.25)), 0, _rng.randf_range(_bounds.position.y, _bounds.end.y))
		var nr4: Array = _nearest_road(Vector2(p4.x, p4.z))
		if float(nr4[0]) < 14.0 and _occ_free(Vector2(p4.x, p4.z), 4.0):
			var d4: Vector2 = nr4[1]
			_place("bld_torii", p4, atan2(d4.x, d4.y))
			_occ_disc(Vector2(p4.x, p4.z), 6.0)
			break


# ---------------------------------------------------------------- 节点附近的体素模型(开车时镜头拉近会看见)
const DETAIL := {
	"res": [["bld_house_a", 4.2], ["bld_house_b", 4.2], ["bld_house_a", 4.2], ["bld_danchi", 9.5], ["bld_shops", 7.5]],
	"down": [["bld_office_a", 6.6], ["bld_shops", 7.5], ["bld_fallen", 11.0], ["bld_office_a", 6.6], ["bld_rubble", 5.5]],
	"fac": [["bld_factory", 9.5], ["bld_tank", 4.5], ["bld_factory", 9.5], ["bld_rubble", 5.5]],
}


func _build_detail() -> void:
	var keys: Array = node_pos.keys()
	keys.sort()
	for k: String in keys:
		var np: Vector3 = node_pos[k]
		var list: Array = DETAIL[_district(np)]
		var placed := 0
		for tries in range(70):
			if placed >= 5:
				break
			var spec: Array = list[_rng.randi() % list.size()]
			var rad: float = float(spec[1])
			var a: float = _rng.randf() * TAU
			var p := np + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(PLAZA_R + rad + 1.0, PLAZA_R + rad + 14.0)
			if not _occ_free(Vector2(p.x, p.z), rad):
				continue
			var nr: Array = _nearest_road(Vector2(p.x, p.z))
			var d: Vector2 = nr[1]
			var yaw: float = atan2(d.x, d.y) + (PI * 0.5 if _rng.randf() < 0.5 else -PI * 0.5)
			_place(str(spec[0]), p, yaw)
			_occ_disc(Vector2(p.x, p.z), rad)
			placed += 1
			if str(spec[0]) in ["bld_house_b", "bld_fallen", "bld_rubble"] or _rng.randf() < 0.15:
				_hot.append(p + Vector3(0, 2.5, 0))
		# 路口边零星的车壳、自动售货机
		# (只放在路口边上、两条路之间，别挡着卡车开出去的路)
		var cars := 0
		for j in range(12):
			if cars >= 3:
				break
			var a2: float = _rng.randf() * TAU
			var p2: Vector3 = np + Vector3(cos(a2), 0, sin(a2)) * _rng.randf_range(PLAZA_R - 2.5, PLAZA_R + 1.5)
			if float(_nearest_road(Vector2(p2.x, p2.z))[0]) < ROAD_W * 0.5 + 2.0:
				continue
			_place("burn_car" if _rng.randf() < 0.3 else "ash_car", p2, a2 + PI * 0.5 + _rng.randf_range(-0.4, 0.4))
			cars += 1
			if _rng.randf() < 0.25:
				_hot.append(p2 + Vector3(0, 0.6, 0))
		if _rng.randf() < 0.4:
			var a3: float = _rng.randf() * TAU
			_place("bld_vending", np + Vector3(cos(a3), 0, sin(a3)) * (PLAZA_R + 0.5), a3 + PI)


func _place(name: String, p: Vector3, yaw: float = 0.0, sc: float = 1.0) -> void:
	if not _groups.has(name):
		_groups[name] = []
	(_groups[name] as Array).append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * sc), p))


# ---------------------------------------------------------------- 其余的城市：楼块(着色器画窗户)
## 按区挑楼的尺寸：居民区小而密(民宅、团地)，市中心高(北边外圈是摩天楼天际线)，工厂区宽而矮；三成是楼顶参差的废墟
func _build_fabric() -> void:
	var ext: Rect2 = _bounds.grow(290.0)
	for i in range(42000):
		var p := Vector3(_rng.randf_range(ext.position.x, ext.end.x), 0, _rng.randf_range(ext.position.y, ext.end.y))
		var p2 := Vector2(p.x, p.z)
		var out_d: float = maxf(maxf(_bounds.position.x - p.x, p.x - _bounds.end.x), maxf(_bounds.position.y - p.z, p.z - _bounds.end.y))
		if out_d > 0.0 and _rng.randf() < clampf(out_d / 600.0, 0.0, 0.5):
			continue
		var dk: String = _district(p)
		var fw: float
		var fd: float
		var fh: float
		match dk:
			"res":
				if _rng.randf() < 0.22:
					fw = _rng.randf_range(16.0, 24.0)
					fd = _rng.randf_range(6.0, 8.0)
					fh = 1.75 * float(_rng.randi_range(4, 8))
				else:
					fw = _rng.randf_range(5.0, 8.0)
					fd = _rng.randf_range(5.0, 7.0)
					fh = 1.75 * float(_rng.randi_range(1, 3))
			"down":
				fw = _rng.randf_range(9.0, 18.0)
				fd = _rng.randf_range(9.0, 16.0)
				fh = 1.75 * float(_rng.randi_range(5, 14))
				if out_d > 30.0 and p.z < _bounds.get_center().y:
					fh *= _rng.randf_range(1.5, 3.2)
			_:
				# 工厂区：大厂房 + 小仓库 / 办公楼
				if _rng.randf() < 0.5:
					fw = _rng.randf_range(16.0, 34.0)
					fd = _rng.randf_range(10.0, 20.0)
					fh = _rng.randf_range(5.0, 10.0)
				else:
					fw = _rng.randf_range(7.0, 14.0)
					fd = _rng.randf_range(6.0, 10.0)
					fh = 1.75 * float(_rng.randi_range(2, 4))
		if p.z > _bounds.end.y - 10.0:
			fh = minf(fh, 10.0)            # 镜头一侧只放矮楼
		var rad: float = sqrt(fw * fw + fd * fd) * 0.5
		if not _occ_free(p2, rad * 0.62):
			continue
		var yaw: float
		var nr: Array = _nearest_road(p2) if out_d < 60.0 else [999.0, Vector2.RIGHT]
		if float(nr[0]) < 45.0:
			var d: Vector2 = nr[1]
			yaw = atan2(d.x, d.y) + PI * 0.5 * float(_rng.randi() % 2)
		else:
			yaw = _district_angle(dk) + PI * 0.5 * float(_rng.randi() % 2) + _rng.randf_range(-0.08, 0.08)
		var ruin: bool = _rng.randf() < 0.35
		var burn: float = _rng.randf() if _rng.randf() < 0.45 else 0.0
		var tf := Transform3D(Basis(Vector3.UP, yaw) * Basis().scaled(Vector3(fw, fh, fd)), Vector3(p.x, fh * 0.5, p.z))
		_blocks.append([tf, Color(_rng.randf(), 1.0 if ruin else 0.0, burn, _rng.randf())])
		_occ_disc(p2, rad * 0.66)
		if burn > 0.75 and _rng.randf() < 0.12:
			_hot.append(Vector3(p.x, fh * (0.6 if ruin else 1.0), p.z))
		if ruin and out_d < 40.0 and _rng.randf() < 0.4 and dk != "fac":
			_place("bld_rubble", p + Vector3(_rng.randf_range(-3, 3), 0, _rng.randf_range(-3, 3)), _rng.randf() * TAU, clampf(fw / 12.0, 0.6, 1.6))


func _district_angle(dk: String) -> float:
	match dk:
		"res":
			return 0.21 + _rot
		"down":
			return -0.12 + _rot
	return 0.44 + _rot


func _flush_blocks() -> void:
	if _blocks.is_empty():
		return
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = bm
	mm.instance_count = _blocks.size()
	for i in range(_blocks.size()):
		mm.set_instance_transform(i, _blocks[i][0])
		mm.set_instance_custom_data(i, _blocks[i][1])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _mat("block", BLOCK_SHADER)
	add_child(mmi)


# ---------------------------------------------------------------- 火
## 粒子火 + 烟柱；少数大火带灯，其余在地面铺一圈加色的火光贴花(代替灯光，镜头移动时不会闪)
func _build_fires() -> void:
	_hot.shuffle()
	for p: Vector3 in _hot.slice(0, 40):
		_fire_at(p, _rng.randf_range(1.2, 2.6), false)


func _fire_at(p: Vector3, size: float, big: bool) -> void:
	var f: FireFX = FireFX.make(size, big and _lights < 4, false, 6.0)
	if f.light != null:
		f.light.omni_range = 14.0 + size * 6.0
		_lights += 1
	f.position = p
	add_child(f)
	if _fires % 3 == 0 or big:
		var pl: GPUParticles3D = FireFX.plume(size)
		pl.position = p + Vector3(0, size * 1.2, 0)
		add_child(pl)
	var g := MeshInstance3D.new()
	var q := QuadMesh.new()
	var r: float = 10.0 + size * 7.0
	q.size = Vector2(r, r)
	q.orientation = PlaneMesh.FACE_Y
	g.mesh = q
	var gm := ShaderMaterial.new()
	gm.shader = _shader("glow", GLOW_SHADER)
	gm.set_shader_parameter("color", Color(1.0, 0.36, 0.08, 0.35))
	g.material_override = gm
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.position = Vector3(p.x, 0.15, p.z)
	add_child(g)
	_fires += 1


## 路灯：大街两侧一排暖色的小灯(有的坏了)。从高空看，亮着的街道就是能走的路网；河堤上也有一排冷色的灯
func _build_streetlights() -> void:
	var cool: Array[Transform3D] = []
	for side2: float in [-1.0, 1.0]:
		var acc2 := 0.0
		for i0 in range(1, _river.size()):
			acc2 += _river[i0].distance_to(_river[i0 - 1])
			if acc2 < 13.0:
				continue
			acc2 = 0.0
			var t0: Vector3 = (_river[i0] - _river[i0 - 1]).normalized()
			if _rng.randf() < 0.75:
				cool.append(Transform3D(Basis(), _river[i0] + Vector3(-t0.z, 0, t0.x) * side2 * (RIVER_W * 0.5 + 2.4) + Vector3(0, 0.4, 0)))
	if not cool.is_empty():
		var cb := BoxMesh.new()
		cb.size = Vector3(0.8, 0.4, 0.8)
		var cmat := StandardMaterial3D.new()
		cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cmat.albedo_color = Color(1.1, 1.5, 2.0)
		cb.material = cmat
		var cmm := MultiMesh.new()
		cmm.transform_format = MultiMesh.TRANSFORM_3D
		cmm.mesh = cb
		cmm.instance_count = cool.size()
		for c0 in range(cool.size()):
			cmm.set_instance_transform(c0, cool[c0])
		var cmi := MultiMeshInstance3D.new()
		cmi.multimesh = cmm
		add_child(cmi)
	var tfs: Array[Transform3D] = []
	for e: Dictionary in _edges:
		var pts: PackedVector3Array = e["pts"]
		var acc := 0.0
		for i in range(1, pts.size()):
			acc += pts[i].distance_to(pts[i - 1])
			if acc < 11.0:
				continue
			acc = 0.0
			var t: Vector3 = (pts[i] - pts[i - 1]).normalized()
			var perp := Vector3(-t.z, 0, t.x)
			for side: float in [-1.0, 1.0]:
				if _rng.randf() < 0.3:
					continue
				tfs.append(Transform3D(Basis(), pts[i] + perp * side * (ROAD_W * 0.5 + 0.6) + Vector3(0, 0.4, 0)))
	if tfs.is_empty():
		return
	var bm := BoxMesh.new()
	bm.size = Vector3(0.55, 0.3, 0.55)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(2.2, 1.5, 0.75)
	bm.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = bm
	mm.instance_count = tfs.size()
	for i2 in range(tfs.size()):
		mm.set_instance_transform(i2, tfs[i2])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	# 路灯在地上的光斑(加色贴花)
	var gq := QuadMesh.new()
	gq.size = Vector2(7.0, 7.0)
	gq.orientation = PlaneMesh.FACE_Y
	var gm := ShaderMaterial.new()
	gm.shader = _shader("glow", GLOW_SHADER)
	gm.set_shader_parameter("color", Color(1.0, 0.7, 0.35, 0.22))
	gq.material = gm
	var mm2 := MultiMesh.new()
	mm2.transform_format = MultiMesh.TRANSFORM_3D
	mm2.mesh = gq
	mm2.instance_count = tfs.size()
	for i3 in range(tfs.size()):
		mm2.set_instance_transform(i3, Transform3D(Basis(), Vector3(tfs[i3].origin.x, 0.08, tfs[i3].origin.z)))
	var mmi2 := MultiMeshInstance3D.new()
	mmi2.multimesh = mm2
	mmi2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi2)


# ---------------------------------------------------------------- 节点标记 / 路线的线
func _build_markers(run: Run) -> void:
	for k: String in node_pos.keys():
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(PLAZA_R * 2.2, PLAZA_R * 2.2)
		q.orientation = PlaneMesh.FACE_Y
		mi.mesh = q
		var m: ShaderMaterial = _mat("ring", RING_SHADER)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = node_pos[k] + Vector3(0, 0.12, 0)
		add_child(mi)
		_markers[k] = m
	# 每条路中间一道细线(像终端地图上的连线)：能走的亮，其余暗
	for e: Dictionary in _edges:
		var mi2 := MeshInstance3D.new()
		mi2.mesh = _strip(e["pts"], 1.0, 0.2)
		var lm: ShaderMaterial = _mat("line", LINE_SHADER)
		lm.set_shader_parameter("period", 5.0)
		lm.set_shader_parameter("duty", 0.55)
		mi2.material_override = lm
		mi2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi2)
		_lines.append({"a": e["a"], "b": e["b"], "mat": lm})
	refresh(run)


## 节点标记：类型色(未观测 = 灰)，完成的变暗，能去的呼吸闪烁。连线：卡车能穿行的那片(已完成的节点之间)亮，通往新节点的半亮，其余暗
func refresh(run: Run) -> void:
	var reach: Dictionary = run.reachable() if run.phase == "map" else {}
	for k: String in _markers.keys():
		var nd: Dictionary = run.gnode(k)
		var st: String = str(nd.get("state", "hidden"))
		var t: String = str(nd.get("type", "fight")) if st != "hidden" else "unknown"
		var col: Color = TYPE_COLORS.get(t, Color.WHITE)
		var a: float = 0.9
		if st == "done" and t != "shop_black" and t != "shop_parts":
			col = Color(0.55, 0.55, 0.58)
			a = 0.35
		var can: bool = reach.has(k) and int(reach[k]) <= run.ap and k != run.pos
		var m: ShaderMaterial = _markers[k]
		m.set_shader_parameter("color", Color(col.r, col.g, col.b, a if (can or st != "hidden") else 0.12))
		m.set_shader_parameter("pulse", 1.0 if can else 0.0)
	for l: Dictionary in _lines:
		var ka: String = l["a"]
		var kb: String = l["b"]
		var open_a: bool = run.passable(ka) or ka == run.pos
		var open_b: bool = run.passable(kb) or kb == run.pos
		var lm: ShaderMaterial = l["mat"]
		if open_a and open_b:
			lm.set_shader_parameter("color", Color(1.0, 0.85, 0.6, 0.55))
		elif (open_a and reach.has(ka)) or (open_b and reach.has(kb)):
			lm.set_shader_parameter("color", Color(1.0, 0.62, 0.3, 0.5))
		else:
			lm.set_shader_parameter("color", Color(0.75, 0.75, 0.8, 0.16))


## 一条连线的折线点，从 from 这头开始
func _edge_pts(from: String, to: String) -> PackedVector3Array:
	for e: Dictionary in _edges:
		if e["a"] == from and e["b"] == to:
			return e["pts"]
		if e["a"] == to and e["b"] == from:
			var p: PackedVector3Array = (e["pts"] as PackedVector3Array).duplicate()
			p.reverse()
			return p
	return PackedVector3Array([node_pos.get(from, Vector3.ZERO), node_pos.get(to, Vector3.ZERO)])


## 悬停一个能去的节点：沿路画一条流动的亮线
func show_path(from_key: String, keys: Array, col: Color) -> void:
	for mi: MeshInstance3D in _path:
		mi.queue_free()
	_path.clear()
	var prev: String = from_key
	for k: String in keys:
		if not node_pos.has(prev) or not node_pos.has(k):
			break
		var mi2 := MeshInstance3D.new()
		mi2.mesh = _strip(_edge_pts(prev, k), 2.8, 0.3)
		var lm: ShaderMaterial = _mat("line", LINE_SHADER)
		lm.set_shader_parameter("color", col)
		lm.set_shader_parameter("speed", 9.0)
		lm.set_shader_parameter("period", 6.0)
		lm.set_shader_parameter("duty", 0.6)
		mi2.material_override = lm
		mi2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi2)
		_path.append(mi2)
		prev = k


## 卡车出发：沿第一段路开出去的折线(frac = 开到这段路的几成就黑屏)；跳跃类零件没有路，就朝目标方向开一小段
func drive_points(from_key: String, to_key: String, frac: float) -> PackedVector3Array:
	var pts: PackedVector3Array = _edge_pts(from_key, to_key)
	var out := PackedVector3Array()
	var n: int = maxi(2, int(float(pts.size() - 1) * frac) + 1)
	for i in range(mini(n, pts.size())):
		out.append(pts[i])
	return out


## 整条路线的折线
func path_points(from_key: String, keys: Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	var prev: String = from_key
	for k: String in keys:
		out.append_array(_edge_pts(prev, k))
		prev = k
	if out.is_empty():
		out.append(node_pos.get(from_key, Vector3.ZERO))
	return out
