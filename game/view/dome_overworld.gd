class_name DomeOverworld
extends CityOverworld
## 第一章-B·蓝之章的大地图：蓝色穹顶包围的"箱庭"——一座未来风的科幻都市。
## 蓝色靠穿过穹顶的光来表现：天光被穹顶染成蓝色(World 的 blue 主题)，几道光柱从穹顶斜照下来、在地上落成一片片光斑；
## 穹顶本身只是一层淡淡的玻璃(三角形的格、肋条、顶上的天窗环)，从外面看整座城市泡在蓝光里，穹顶外是黑夜。
## 格点 = 城市的路口(直线格网 + 小错开)。首领在城北：那里立着巨大的未来风信标(sf_beacon)，首领的路口就在它脚下，
## 信标顶上一道光柱直通穹顶。布景：白色的塔楼(体素模型 sf_* + 着色器画玻璃带的方块楼)、玻璃路面、发光的石庭、路灯、树、全息路牌。

const DOME_PAD := 110.0            # 穹顶半径 = 格点群的半径 + 这么多
const DUST_H := 70.0

## 路面：深色的玻璃路 + 两侧的导光边 + 中间一串发光的短划
const TECH_ROAD_SHADER := """
shader_type spatial;
render_mode diffuse_burley;
varying vec2 uv;
float h21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() { uv = UV; }
void fragment() {
	float x = abs(uv.x - 0.5) * 2.0;
	vec3 c = vec3(0.1, 0.12, 0.17) * (0.9 + 0.1 * h21(floor(vec2(uv.x * 4.0, uv.y * 0.5))));
	float edge = smoothstep(0.86, 0.9, x) * (1.0 - smoothstep(0.96, 1.0, x));
	float dash = step(0.5, fract(uv.y * 0.12)) * (1.0 - smoothstep(0.03, 0.06, x));
	ALBEDO = c;
	EMISSION = vec3(0.3, 0.7, 1.0) * (edge * 0.9 + dash * 0.6);
	ROUGHNESS = 0.35;
	SPECULAR = 0.5;
}
"""

## 路口的石庭：浅色的圆盘 + 同心环 + 发光的边
const TECH_COURT_SHADER := """
shader_type spatial;
render_mode diffuse_burley;
void fragment() {
	vec2 p = UV - 0.5;
	float r = length(p) * 2.0;
	if (r > 1.0) { discard; }
	vec3 c = vec3(0.8, 0.84, 0.9);
	float ring = 1.0 - smoothstep(0.0, 0.06, abs(fract(r * 3.0) - 0.5) - 0.4);
	c = mix(c, vec3(0.35, 0.4, 0.5), ring * 0.5);
	float rim = smoothstep(0.84, 0.92, r) * (1.0 - smoothstep(0.96, 1.0, r));
	ALBEDO = c;
	EMISSION = vec3(0.3, 0.7, 1.0) * rim * 1.1;
	ROUGHNESS = 0.5;
}
"""

## 方块楼：白色的墙 + 每层一道深色的玻璃带(零星亮着的窗是青色的) + 竖向的接缝；屋顶一圈边、中间深色的设备
const TECH_BLOCK_SHADER := """
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
	vec3 wn = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	vec3 wall = mix(vec3(0.7, 0.74, 0.8), vec3(0.86, 0.9, 0.95), cust.w);
	vec3 col = wall;
	vec3 emi = vec3(0.0);
	if (abs(wn.y) > 0.7) {
		float edge = step(0.4, max(abs(lp.x) / max(scl.x, 1.0), abs(lp.z) / max(scl.z, 1.0)));
		col = mix(vec3(0.3, 0.34, 0.4), wall * 0.95, edge);
	} else {
		float band = fract(lp.y / 3.5);
		float along = abs(wn.x) > abs(wn.z) ? lp.z : lp.x;
		if (band > 0.55 && lp.y > 1.5) {
			col = vec3(0.1, 0.16, 0.26);
			float r = h21(vec2(floor(along / 2.2) + seed, floor(lp.y / 3.5)));
			emi = vec3(0.3, 0.75, 1.0) * step(0.86, r) * 1.5 + vec3(0.12, 0.25, 0.4) * 0.35;
		}
		if (fract(along / 6.0) < 0.03) { col *= 0.7; }
	}
	if (!FRONT_FACING) { col *= 0.3; emi = vec3(0.0); }
	ALBEDO = col;
	EMISSION = emi;
	ROUGHNESS = 0.6;
	SPECULAR = 0.4;
}
"""

## 穹顶：加色的淡蓝玻璃——掠射角亮(菲涅尔)，三角形的格线，顶上的天窗环；只画地面以上的半球
const DOME_SHADER := """
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never;
uniform vec3 tint : source_color = vec3(0.25, 0.55, 1.0);
uniform float radius = 300.0;
varying vec3 wpos;
varying vec3 lpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; lpos = VERTEX; }
void fragment() {
	if (wpos.y < 0.5) { discard; }
	vec2 p = vec2(atan(lpos.z, -lpos.x) * radius * 0.5, lpos.y * 0.5) / 17.0;
	float g = min(abs(fract(p.x) - 0.5), min(abs(fract(p.x * 0.5 + p.y * 0.866) - 0.5), abs(fract(-p.x * 0.5 + p.y * 0.866) - 0.5)));
	float line = smoothstep(0.455, 0.5, g);
	float fres = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.2);
	float top = smoothstep(0.86, 0.9, lpos.y / radius) * (1.0 - smoothstep(0.93, 0.97, lpos.y / radius));
	ALBEDO = tint * (0.04 + 0.42 * fres) + tint * line * 0.3 + vec3(0.6, 0.85, 1.0) * (line * fres * 0.35 + top * 0.6);
}
"""

const DOME_DETAIL := [["sf_block", 9.0], ["sf_block", 9.0], ["sf_tower_b", 8.0], ["sf_tree", 3.0], ["sf_tree", 3.0], ["sf_sign", 3.5], ["sf_tower_a", 6.0], ["sf_pylon", 2.5]]

var _dome_c: Vector3 = Vector3.ZERO
var _dome_r: float = 300.0
var _beacon_light: OmniLight3D = null
var _beacon_top: Vector3 = Vector3.ZERO
var _tt: float = 0.0


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
	_beacon_light = null
	var gm: Dictionary = run.gmap
	w = int(gm["w"])
	h = int(gm["h"])
	_rng.seed = int(gm.get("seed", run.seed_value)) * 17 + 3
	_layout_nodes(gm)
	_layout_edges(gm)
	var mn := Vector2(1e9, 1e9)
	var mx := Vector2(-1e9, -1e9)
	for k: String in node_pos.keys():
		var p: Vector3 = node_pos[k]
		mn = Vector2(minf(mn.x, p.x), minf(mn.y, p.z))
		mx = Vector2(maxf(mx.x, p.x), maxf(mx.y, p.z))
	_bounds = Rect2(mn, mx - mn)
	_dome_c = Vector3(_bounds.get_center().x, 0.0, _bounds.get_center().y)
	_dome_r = maxf(_bounds.size.x, _bounds.size.y) * 0.5 + DOME_PAD
	_occ_init(_bounds.grow(400.0))
	_rasterize()
	WorldAssets.ground_tech(self, _dome_c, 2600.0, Vector2(_dome_c.x, _dome_c.z), _dome_r)
	_build_road_mesh()
	_build_plazas()
	_build_beacon(run)
	_build_detail()
	_build_fabric()
	_build_lamps()
	_build_shafts()
	_build_dome()
	_build_markers(run)
	WorldAssets.add_multimesh(self, _groups)
	_flush_blocks()
	var dust: GPUParticles3D = FireFX.snow(Vector2(_bounds.size.x + 240.0, _bounds.size.y + 240.0), 600, DUST_H)
	dust.position += _dome_c
	add_child(dust)


func center() -> Vector3:
	return _dome_c


func span() -> float:
	return maxf(_bounds.size.x, _bounds.size.y) + 60.0


# ---------------------------------------------------------------- 节点位置：直线的格网 + 小错开(城市是规划出来的，路是直的)
func _layout_nodes(gm: Dictionary) -> void:
	_rot = _rng.randf_range(-0.06, 0.06)
	_ph1 = 0.0
	_ph2 = 0.0
	_river_col = -1
	var keys: Array = (gm["nodes"] as Dictionary).keys()
	keys.sort()
	for k: String in keys:
		var c: Vector2i = ChapterMap.cell(k)
		var u: float = float(c.x) - float(w - 1) * 0.5
		var v: float = float(c.y) - float(h - 1) * 0.5
		var x: float = u * S
		var z: float = v * S * ROW
		var p := Vector3(x * cos(_rot) - z * sin(_rot), 0.0, x * sin(_rot) + z * cos(_rot))
		node_pos[k] = p + Vector3(_rng.randf_range(-1.0, 1.0), 0.0, _rng.randf_range(-1.0, 1.0)) * S * 0.06


## 在穹顶里(离穹顶脚至少 margin 米)
func _inside(p: Vector3, margin: float) -> bool:
	return Vector2(p.x - _dome_c.x, p.z - _dome_c.z).length() < _dome_r * 0.9 - margin


# ---------------------------------------------------------------- 路 / 路口
func _build_road_mesh() -> void:
	var m: ShaderMaterial = _mat("tech_road", TECH_ROAD_SHADER)
	for e: Dictionary in _edges:
		var mi := MeshInstance3D.new()
		mi.mesh = _strip(e["pts"], ROAD_W * 0.9, 0.04)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)


func _build_plazas() -> void:
	var m: ShaderMaterial = _mat("tech_court", TECH_COURT_SHADER)
	for k: String in node_pos.keys():
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(PLAZA_R * 2.0, PLAZA_R * 2.0)
		q.orientation = PlaneMesh.FACE_Y
		mi.mesh = q
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = node_pos[k] + Vector3(0, 0.06, 0)
		add_child(mi)


# ---------------------------------------------------------------- 城北的信标：首领路口背后的巨大建筑，顶上一道光柱直通穹顶
func _build_beacon(run: Run) -> void:
	var bp: Vector3 = node_pos[str(run.gmap["boss"])]
	var north := Vector3(sin(_rot), 0, -cos(_rot))
	var at: Vector3 = bp + north * 36.0
	_place("sf_beacon", at, _rng.randf_range(-0.2, 0.2), 1.0)
	_occ_disc(Vector2(at.x, at.z), 38.0)
	_beacon_top = at + Vector3(0, 112.0, 0)
	_beacon_light = OmniLight3D.new()
	_beacon_light.light_color = Color("#7fd4ff")
	_beacon_light.light_energy = 4.0
	_beacon_light.omni_range = 170.0
	_beacon_light.shadow_enabled = false
	_beacon_light.position = _beacon_top
	add_child(_beacon_light)
	var beam := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 4.0
	cm.bottom_radius = 9.0
	cm.height = maxf(40.0, _dome_r - 112.0)
	cm.radial_segments = 16
	cm.cap_top = false
	cm.cap_bottom = false
	beam.mesh = cm
	beam.material_override = _beam_mat(Color(0.5, 0.8, 1.0, 0.16))
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.position = _beacon_top + Vector3(0, cm.height * 0.5, 0)
	add_child(beam)
	_glow_disc(Vector3(at.x, 0.1, at.z), 70.0, Color(0.35, 0.7, 1.0, 0.35))
	# 首领路口两侧各一根高杆
	var side := Vector3(-north.z, 0, north.x)
	_place("sf_pylon", bp + side * (PLAZA_R + 3.0), 0.0, 1.0)
	_place("sf_pylon", bp - side * (PLAZA_R + 3.0), 0.0, 1.0)


func _beam_mat(col: Color) -> StandardMaterial3D:
	var bmat := StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bmat.albedo_color = col
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	bmat.no_depth_test = false
	return bmat


func _glow_disc(at: Vector3, size: float, col: Color) -> void:
	var g := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.orientation = PlaneMesh.FACE_Y
	g.mesh = q
	var gm := ShaderMaterial.new()
	gm.shader = _shader("glow", GLOW_SHADER)
	gm.set_shader_parameter("color", col)
	g.material_override = gm
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.position = at
	add_child(g)


# ---------------------------------------------------------------- 路口附近的楼 / 树 / 路牌
func _build_detail() -> void:
	var keys: Array = node_pos.keys()
	keys.sort()
	for k: String in keys:
		var np: Vector3 = node_pos[k]
		var placed := 0
		for tries in range(70):
			if placed >= 4:
				break
			var spec: Array = DOME_DETAIL[_rng.randi() % DOME_DETAIL.size()]
			var rad: float = float(spec[1])
			var a: float = _rng.randf() * TAU
			var p := np + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(PLAZA_R + rad + 1.5, PLAZA_R + rad + 13.0)
			if not _inside(p, rad) or not _occ_free(Vector2(p.x, p.z), rad):
				continue
			var nr: Array = _nearest_road(Vector2(p.x, p.z))
			var d: Vector2 = nr[1]
			var yaw: float = atan2(d.x, d.y) + (PI * 0.5 if _rng.randf() < 0.5 else -PI * 0.5)
			_place(str(spec[0]), p, yaw, _rng.randf_range(0.9, 1.15) if str(spec[0]).begins_with("sf_tower") else 1.0)
			_occ_disc(Vector2(p.x, p.z), rad)
			placed += 1


## 穹顶里其余的地方：成片的方块楼(着色器画玻璃带，越靠城北越高)、零星的体素塔楼、树
func _build_fabric() -> void:
	var north := Vector3(sin(_rot), 0, -cos(_rot))
	var placed := 0
	for tries in range(2600):
		if placed >= 320:
			break
		var a: float = _rng.randf() * TAU
		var p: Vector3 = _dome_c + Vector3(cos(a), 0, sin(a)) * sqrt(_rng.randf()) * _dome_r * 0.86
		var sx: float = _rng.randf_range(7.0, 15.0)
		var sz: float = _rng.randf_range(7.0, 15.0)
		var rad: float = maxf(sx, sz) * 0.72
		if not _occ_free(Vector2(p.x, p.z), rad) or float(_nearest_road(Vector2(p.x, p.z))[0]) < rad + 6.0:
			continue
		var nk: float = clampf((p - _dome_c).dot(north) / _dome_r + 0.5, 0.0, 1.0)      # 0 = 城南，1 = 城北
		var hgt: float = _rng.randf_range(12.0, 30.0) + nk * _rng.randf_range(10.0, 40.0)
		_box(p, Vector3(sx, hgt, sz), _rot + (PI * 0.5 if _rng.randf() < 0.5 else 0.0), _rng.randf())
		_occ_disc(Vector2(p.x, p.z), rad)
		placed += 1
	var specs: Array = [["sf_tower_a", 6.0, 24], ["sf_tower_b", 8.0, 18], ["sf_block", 9.0, 30], ["sf_tree", 3.0, 110], ["sf_sign", 3.5, 24]]
	for sp: Array in specs:
		var nm: String = sp[0]
		var rad2: float = float(sp[1])
		var want: int = int(sp[2])
		var n := 0
		for tries2 in range(want * 14):
			if n >= want:
				break
			var a2: float = _rng.randf() * TAU
			var p2: Vector3 = _dome_c + Vector3(cos(a2), 0, sin(a2)) * sqrt(_rng.randf()) * _dome_r * 0.88
			if not _inside(p2, rad2) or not _occ_free(Vector2(p2.x, p2.z), rad2):
				continue
			var road_d: float = float(_nearest_road(Vector2(p2.x, p2.z))[0])
			if nm != "sf_tree" and road_d < 12.0:
				continue
			_place(nm, p2, _rot + PI * 0.5 * float(_rng.randi() % 4), _rng.randf_range(0.9, 1.2) if nm.begins_with("sf_tower") else 1.0)
			_occ_disc(Vector2(p2.x, p2.z), rad2)
			n += 1


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
	mmi.material_override = _mat("tech_block", TECH_BLOCK_SHADER)
	add_child(mmi)


## 路边每十几米一盏路灯(蓝白的光斑)：从高空看，亮着的就是路网
func _build_lamps() -> void:
	var glows: Array[Vector3] = []
	for e: Dictionary in _edges:
		var pts: PackedVector3Array = e["pts"]
		var acc := 0.0
		for i in range(1, pts.size()):
			acc += pts[i].distance_to(pts[i - 1])
			if acc < 14.0:
				continue
			acc = 0.0
			var t: Vector3 = (pts[i] - pts[i - 1]).normalized()
			var perp := Vector3(-t.z, 0, t.x)
			var side: float = 1.0 if (i / 4) % 2 == 0 else -1.0
			var p: Vector3 = pts[i] + perp * side * (ROAD_W * 0.45 + 1.0)
			_place("sf_lamp", p, atan2(t.x, t.z) + (PI if side < 0.0 else 0.0))
			glows.append(p)
	if glows.is_empty():
		return
	var gq := QuadMesh.new()
	gq.size = Vector2(9.0, 9.0)
	gq.orientation = PlaneMesh.FACE_Y
	var gm := ShaderMaterial.new()
	gm.shader = _shader("glow", GLOW_SHADER)
	gm.set_shader_parameter("color", Color(0.5, 0.8, 1.0, 0.22))
	gq.material = gm
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = gq
	mm.instance_count = glows.size()
	for i2 in range(glows.size()):
		mm.set_instance_transform(i2, Transform3D(Basis(), Vector3(glows[i2].x, 0.1, glows[i2].z)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


# ---------------------------------------------------------------- 穿过穹顶的光：几道斜着的光柱 + 地上的光斑
func _build_shafts() -> void:
	var n := 6
	for i in range(n):
		var a: float = TAU * (float(i) + 0.5) / float(n) + _rng.randf_range(-0.2, 0.2)
		var lat: float = deg_to_rad(_rng.randf_range(48.0, 62.0))
		var s: Vector3 = _dome_c + Vector3(cos(a) * cos(lat), sin(lat), sin(a) * cos(lat)) * _dome_r * 0.98
		var gpos: Vector3 = _dome_c + Vector3(cos(a), 0, sin(a)) * _dome_r * _rng.randf_range(0.2, 0.45)
		var dir: Vector3 = (gpos - s).normalized()
		var L: float = s.distance_to(gpos)
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 11.0
		cm.bottom_radius = 26.0
		cm.height = L
		cm.radial_segments = 18
		cm.cap_top = false
		cm.cap_bottom = false
		mi.mesh = cm
		mi.material_override = _beam_mat(Color(0.45, 0.7, 1.0, 0.045))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var b := Basis()
		b.y = -dir
		b.x = b.y.cross(Vector3.FORWARD).normalized()
		b.z = b.x.cross(b.y)
		mi.transform = Transform3D(b, (s + gpos) * 0.5)
		add_child(mi)
		_glow_disc(Vector3(gpos.x, 0.08, gpos.z), 58.0, Color(0.45, 0.75, 1.0, 0.16))


# ---------------------------------------------------------------- 穹顶：半球玻璃 + 肋条 + 天窗环
func _build_dome() -> void:
	var sm := SphereMesh.new()
	sm.radius = _dome_r
	sm.height = _dome_r * 2.0
	sm.radial_segments = 72
	sm.rings = 36
	var mi := MeshInstance3D.new()
	mi.mesh = sm
	var m: ShaderMaterial = _mat("dome", DOME_SHADER)
	m.set_shader_parameter("radius", _dome_r)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = _dome_c
	add_child(mi)
	# 肋条：10 条经线 + 2 条纬线，一节节的方梁
	var tfs: Array[Transform3D] = []
	var segs := 26
	for i in range(10):
		var lon: float = TAU * float(i) / 10.0
		for j in range(segs):
			var l0: float = deg_to_rad(88.0) * float(j) / float(segs)
			var l1: float = deg_to_rad(88.0) * float(j + 1) / float(segs)
			tfs.append(_rib_tf(_sph(lon, l0), _sph(lon, l1)))
	for lat_deg: float in [32.0, 62.0]:
		var lat: float = deg_to_rad(lat_deg)
		var nseg: int = 60
		for j2 in range(nseg):
			var a0: float = TAU * float(j2) / float(nseg)
			var a1: float = TAU * float(j2 + 1) / float(nseg)
			tfs.append(_rib_tf(_sph(a0, lat), _sph(a1, lat)))
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.82, 0.86, 0.92)
	rm.emission_enabled = true
	rm.emission = Color(0.3, 0.6, 1.0)
	rm.emission_energy_multiplier = 0.25
	rm.roughness = 0.5
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = bm
	mm.instance_count = tfs.size()
	for k in range(tfs.size()):
		mm.set_instance_transform(k, tfs[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = rm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	# 天窗环
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = _dome_r * 0.1
	tm.outer_radius = _dome_r * 0.1 + 4.0
	ring.mesh = tm
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.9, 0.95, 1.0)
	rmat.emission_enabled = true
	rmat.emission = Color(0.5, 0.8, 1.0)
	rmat.emission_energy_multiplier = 1.2
	ring.material_override = rmat
	ring.position = _dome_c + Vector3(0, _dome_r * 0.993, 0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)


func _sph(lon: float, lat: float) -> Vector3:
	return _dome_c + Vector3(cos(lon) * cos(lat), sin(lat), sin(lon) * cos(lat)) * _dome_r


func _rib_tf(p0: Vector3, p1: Vector3) -> Transform3D:
	var dir: Vector3 = p1 - p0
	var L: float = dir.length()
	var up: Vector3 = ((p0 + p1) * 0.5 - _dome_c).normalized()
	var b := Basis.looking_at(dir.normalized(), up) * Basis.from_scale(Vector3(2.4, 2.4, L + 0.3))
	return Transform3D(b, (p0 + p1) * 0.5)


func _process(dt: float) -> void:
	_tt += dt
	if _beacon_light != null:
		_beacon_light.light_energy = 3.6 + 1.0 * sin(_tt * 1.1)
