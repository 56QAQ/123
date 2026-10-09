class_name OverworldView
extends Node3D
## 章节大地图(战斗外地图)：俯视角的体素遗迹世界，类似《杀戮尖塔》的路线图(不用羊皮纸)。
##  · 地图节点 = 地上的小石台；可交互的图标按钮由 HUD 画在它们上方(悬停看节点信息，点"下一站"出发)
##  · 节点之间用虚线连接：走过的 = 金色实点线，下一段 = 流动的金色虚线，之后的 = 灰色虚线
##  · 终点：彩虹水晶祭坛 + 冲天光柱；四周散布断壁残垣(纯装饰)
##  · 工坊卡车停在当前位置(起点或上一个打完的节点)，出发时沿虚线开过去——这段行驶就是载入战斗场景的过程
##  · 方格网章节(第一章起)：整张大地图交给 CityOverworld(燃烧的城市街区，节点 = 十字路口)

const DASH_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 color : source_color;
uniform vec3 seg_a = vec3(0.0);
uniform vec3 seg_dir = vec3(0.0, 0.0, 1.0);
uniform float period = 1.2;
uniform float duty = 0.55;
uniform float speed = 0.0;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float s = dot(wpos - seg_a, seg_dir) - TIME * speed;
	float d = step(fract(s / period), duty);
	float edge = smoothstep(0.0, 0.2, UV.x) * smoothstep(1.0, 0.8, UV.x);
	ALBEDO = color.rgb;
	ALPHA = color.a * d * edge;
}
"""

const RING_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 color : source_color;
void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float band = smoothstep(0.70, 0.78, r) * (1.0 - smoothstep(0.90, 1.0, r));
	ALBEDO = color.rgb;
	ALPHA = band * color.a;
}
"""

const COL_DONE := Color(0.84, 0.64, 0.22, 0.95)
const COL_NEXT := Color(0.95, 0.70, 0.18, 0.95)
const COL_LATER := Color(0.36, 0.41, 0.52, 0.7)

var start_pos: Vector3 = Vector3(0, 0, 21)
var node_pos: Array[Vector3] = []          # 每个地图节点在大地图上的位置
var _segments: Array[MeshInstance3D] = []  # 第 k 段：从第 k-1 个节点(或起点)到第 k 个节点
var _rings: Array[MeshInstance3D] = []     # 下一站石台上的光环
var _next: int = 0
var _hover: int = -1
var _beam: MeshInstance3D = null
var _t: float = 0.0
var city: CityOverworld = null             # 方格网章节的城市地图(线性章节为 null)


## 按本局的章节搭建大地图(同一个 seed 得到同一片遗迹)
func build(run: Run) -> void:
	for ch: Node in get_children():
		ch.queue_free()
	_segments.clear()
	_rings.clear()
	node_pos.clear()
	_beam = null
	city = null
	if run.is_grid():
		# 方格网章节的大地图：章节数据的 overworld 选布景(city = 燃烧的城市；island = 云海上的和风空岛)
		var ow: String = str(run.chapter.get("overworld", "city"))
		city = IslandOverworld.new() if ow == "island" else (DomeOverworld.new() if ow == "dome" else CityOverworld.new())
		add_child(city)
		city.build(run)
		return
	var n: int = run.total_nodes()
	# 自下而上的一条路线，左右轻微摆动
	var xs: Array[float] = [-5.0, 5.0, 0.0, -4.0, 4.0]
	for i in range(n):
		var z: float = start_pos.z - 12.5 * float(i + 1)
		node_pos.append(Vector3(xs[i % xs.size()] if i < n - 1 else 0.0, 0.0, z))
	WorldAssets.ground(self, Vector3(0, 0, -10), 600.0, 4.2, 0.45)
	var pts: Array[Vector3] = [start_pos]
	pts.append_array(node_pos)
	for k in range(n):
		_segments.append(_dash_segment(pts[k], pts[k + 1]))
	_pedestal(start_pos, false)
	for i2 in range(n):
		_pedestal(node_pos[i2], true)
	# 终点：彩虹水晶祭坛(在最后一个节点的北侧)
	var alt := MeshInstance3D.new()
	alt.mesh = WorldAssets.mesh("altar")
	alt.position = node_pos[n - 1] + Vector3(0, 0, -5.2)
	alt.scale = Vector3.ONE * 1.25
	add_child(alt)
	_beam = WorldAssets.altar_beam(self, alt.position, 70.0, 1.2)
	_scatter_deco(run.seed_value, pts)
	refresh(run.node_index)


## 下一站 = next_index；之前的已通过
func refresh(next_index: int) -> void:
	_next = next_index
	if city != null:
		return
	for k in range(_segments.size()):
		var m: ShaderMaterial = _segments[k].material_override
		if k < next_index:
			m.set_shader_parameter("color", COL_DONE)
			m.set_shader_parameter("duty", 0.72)
			m.set_shader_parameter("speed", 0.0)
		elif k == next_index:
			m.set_shader_parameter("color", COL_NEXT)
			m.set_shader_parameter("duty", 0.55)
			m.set_shader_parameter("speed", 1.1)
		else:
			m.set_shader_parameter("color", COL_LATER)
			m.set_shader_parameter("duty", 0.5)
			m.set_shader_parameter("speed", 0.0)
	for i in range(_rings.size()):
		_rings[i].visible = i == next_index


## 悬停某个节点按钮：通往它的那一段虚线加亮
func set_hover(i: int) -> void:
	_hover = i


## 卡车在地图上的位置：起点，或者停在上一个打完的节点旁边、车头朝向下一站(不被节点图标挡住)
func truck_spot(next_index: int) -> Vector3:
	if city != null:
		return start_pos
	if next_index <= 0:
		return start_pos
	var here: Vector3 = node_pos[mini(next_index - 1, node_pos.size() - 1)]
	if next_index >= node_pos.size():
		return here
	return here + (node_pos[next_index] - here).normalized() * 3.4


## 整条路线的中点和跨度(镜头取景用)
func route_center() -> Vector3:
	if city != null:
		return city.center()
	return (start_pos + node_pos.back()) * 0.5 + Vector3(0, 0, -2.0)


func route_span() -> float:
	if city != null:
		return city.span()
	return start_pos.distance_to(node_pos.back()) + 12.0


# ---------------------------------------------------------------- 构件
func _dash_segment(a: Vector3, b: Vector3) -> MeshInstance3D:
	var d: Vector3 = b - a
	d.y = 0.0
	var dir: Vector3 = d.normalized()
	# 两端各留出石台的半径
	var a2: Vector3 = a + dir * 2.1
	var b2: Vector3 = b - dir * 2.1
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(0.42, a2.distance_to(b2))
	mi.mesh = pm
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = DASH_SHADER
	sm.shader = sh
	sm.set_shader_parameter("seg_a", a2)
	sm.set_shader_parameter("seg_dir", dir)
	mi.material_override = sm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = (a2 + b2) * 0.5 + Vector3(0, 0.03, 0)
	mi.rotation.y = atan2(dir.x, dir.z)
	add_child(mi)
	return mi


## 地图节点的小石台：大理石圆台 + 金边；节点石台上还有"下一站"光环
func _pedestal(p: Vector3, is_node: bool) -> void:
	var base := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.45
	cm.bottom_radius = 1.6
	cm.height = 0.22
	cm.radial_segments = 24
	base.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#ece8e0")
	mat.roughness = 0.7
	base.material_override = mat
	base.position = p + Vector3(0, 0.1, 0)
	add_child(base)
	var rim := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.43
	tm.outer_radius = 1.58
	tm.rings = 32
	tm.ring_segments = 6
	rim.mesh = tm
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color("#c9a553")
	rm.metallic = 0.6
	rm.roughness = 0.35
	rim.material_override = rm
	rim.position = p + Vector3(0, 0.22, 0)
	add_child(rim)
	if not is_node:
		return
	var ring := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(4.8, 4.8)
	q.orientation = PlaneMesh.FACE_Y
	ring.mesh = q
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = RING_SHADER
	sm.shader = sh
	sm.set_shader_parameter("color", Color(1.0, 0.78, 0.25, 0.8))
	ring.material_override = sm
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position = p + Vector3(0, 0.05, 0)
	ring.visible = false
	add_child(ring)
	_rings.append(ring)


## 断壁残垣散布在路线两旁：靠近路线的小而稀，远处大而密
func _scatter_deco(seed_value: int, pts: Array[Vector3]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 17 + 3
	var groups: Dictionary = {}
	for nm: String in WorldAssets.DECO_TALL + WorldAssets.DECO_LOW:
		groups[nm] = []
	var placed := 0
	var tries := 0
	while placed < 420 and tries < 9000:
		tries += 1
		var p := Vector3(rng.randf_range(-80.0, 80.0), 0.0, rng.randf_range(-90.0, 70.0))
		var d: float = _dist_to_route(p, pts)
		if d < 2.6:
			continue
		if rng.randf() > clampf(0.45 + d * 0.05, 0.0, 1.0):
			continue
		var tall: bool = rng.randf() < (0.3 if d < 7.0 else 0.6)
		var names: Array = WorldAssets.DECO_TALL if tall else WorldAssets.DECO_LOW
		var nm2: String = names[rng.randi() % names.size()]
		var sc: float = clampf(0.5 + d * 0.05, 0.5, 2.4) * rng.randf_range(0.85, 1.15)
		var tf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * sc), p)
		(groups[nm2] as Array).append(tf)
		placed += 1
	WorldAssets.add_multimesh(self, groups)


static func _dist_to_route(p: Vector3, pts: Array[Vector3]) -> float:
	var best := 1e9
	var q := Vector2(p.x, p.z)
	for i in range(pts.size() - 1):
		var a := Vector2(pts[i].x, pts[i].z)
		var b := Vector2(pts[i + 1].x, pts[i + 1].z)
		var ab: Vector2 = b - a
		var t: float = clampf((q - a).dot(ab) / maxf(0.001, ab.length_squared()), 0.0, 1.0)
		best = minf(best, q.distance_to(a + ab * t))
	for c: Vector3 in pts:
		best = minf(best, q.distance_to(Vector2(c.x, c.z)) - 1.5)
	return best


func _process(dt: float) -> void:
	_t += dt
	if not visible:
		return
	for i in range(_rings.size()):
		if _rings[i].visible:
			var s: float = 1.0 + 0.06 * sin(_t * 3.2)
			_rings[i].scale = Vector3(s, 1.0, s)
	if city != null:
		return
	if _next < _segments.size():
		var m: ShaderMaterial = _segments[_next].material_override
		var hot: bool = _hover == _next
		m.set_shader_parameter("color", Color(1.0, 0.82, 0.3, 1.0) if hot else COL_NEXT)
		m.set_shader_parameter("speed", 2.2 if hot else 1.1)
	if _beam != null:
		(_beam.material_override as StandardMaterial3D).albedo_color.a = 0.18 + 0.06 * sin(_t * 1.7)
