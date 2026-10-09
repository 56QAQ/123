class_name BattleStage
extends Node3D
## 战斗场景的交互层(子节点都用战斗坐标，原点 = 战斗地图中心 = 卡车)：
## 拖动棋子时的区域着色(我方部署格 = 高亮蓝，其余地面 = 高亮红，一直铺到远处；平时不显示)、格子高亮、地面拾取、
## 敌人来袭方位箭头、晶球层。
## 断壁残垣与卡车的模型由 BattlefieldView / TruckView 负责，这里只处理"交互用"的东西。

const TILE_Y := 0.012

## 卡车摆法 tl(apply_layout：卡车在哪、朝向、部署区多大)来自战斗地图布局——开局改装能挪卡车时每次挪动都会换。
## 区域着色：一整块大平面，按战斗坐标判断"部署格 / 卡车 / 其它"。
## 颜色用不受光照影响的高饱和色 + 亮白格线，将来换成蓝色主题的章节也不会和地面混在一起。
const ZONE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 ally : source_color = vec4(0.08, 0.52, 1.0, 0.8);
uniform vec4 ally_edge : source_color = vec4(0.82, 0.95, 1.0, 1.0);
uniform vec4 foe : source_color = vec4(0.95, 0.06, 0.05, 0.6);
uniform vec4 deploy = vec4(0.0);      // x0, z0, x1, z1(战斗坐标，米)
uniform vec4 truck = vec4(0.0);
uniform vec2 origin = vec2(0.0);      // 格子原点(地图左上角)
uniform float cell = 1.0;
uniform float fade = 0.0;
varying vec2 lp;
void vertex() { lp = VERTEX.xz; }
bool inside(vec4 r, vec2 p) { return p.x >= r.x && p.x <= r.z && p.y >= r.y && p.y <= r.w; }
void fragment() {
	vec4 c = vec4(0.0);
	if (inside(truck, lp)) {
		c = vec4(0.0);
	} else if (inside(deploy, lp)) {
		vec2 f = fract((lp - origin) / cell);
		float e = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
		float grid = 1.0 - smoothstep(0.025, 0.06, e);
		// 部署区外圈：更粗的亮边
		float de = min(min(lp.x - deploy.x, deploy.z - lp.x), min(lp.y - deploy.y, deploy.w - lp.y));
		float rim = 1.0 - smoothstep(0.05, 0.12, de);
		float pulse = 0.88 + 0.12 * sin(TIME * 4.0);
		c = mix(ally, ally_edge, max(grid * 0.85, rim));
		c.rgb *= pulse + (1.0 - pulse) * max(grid, rim);
	} else {
		// 斜条纹让"不能放"的区域一眼可辨
		float stripe = step(0.5, fract((lp.x + lp.y) * 0.55));
		c = foe;
		c.a *= mix(0.78, 1.0, stripe);
	}
	ALBEDO = c.rgb;
	ALPHA = c.a * fade;
}
"""

var hl: Dictionary = {}                 # Vector2i -> MeshInstance3D (高亮)
var arrows: Dictionary = {}             # 方位 -> {arrow, label}
var orbs_layer: Node3D
var _hl_mat_cache: Dictionary = {}
var deploy_shown: bool = false
var zone: MeshInstance3D                # 区域着色平面
var _zone_mat: ShaderMaterial
var _fade: Tween = null
var _threat: Dictionary = {}
var _t: float = 0.0
var tl: TruckLayout = TruckLayout.make("")   # 当前的卡车摆法(部署区 / 卡车格子)


func _ready() -> void:
	zone = MeshInstance3D.new()
	zone.name = "DeployZone"
	var pm := PlaneMesh.new()
	pm.size = Vector2(600, 600)
	zone.mesh = pm
	_zone_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = ZONE_SHADER
	_zone_mat.shader = sh
	_zone_mat.render_priority = -1        # 画在格子高亮、射程环、选中圈下面
	var half: Vector2 = GC.map_half()
	_apply_rects(tl.deploy, tl.truck)
	_zone_mat.set_shader_parameter("origin", -half)
	_zone_mat.set_shader_parameter("cell", GC.CELL)
	zone.material_override = _zone_mat
	zone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	zone.position = Vector3(0, TILE_Y, 0)
	zone.visible = false
	add_child(zone)
	for region: String in GC.REGION_ANGLE.keys():
		var d: Vector2 = GC.region_dir(region)
		var a: Vector2 = GC.region_anchor(region) + d * 1.2
		var arrow := MeshInstance3D.new()
		arrow.mesh = _arrow_mesh()
		arrow.material_override = _mat(Color(1.0, 0.42, 0.34, 0.6)).duplicate()
		arrow.position = Vector3(a.x, TILE_Y + 0.01, a.y)
		arrow.rotation.y = GC.facing_to(Vector2.ZERO, d) + PI
		arrow.scale = Vector3.ONE * 1.25
		arrow.visible = false
		arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(arrow)
		var lab := Label3D.new()
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.font_size = 60
		lab.pixel_size = 0.006
		lab.outline_size = 14
		lab.modulate = Color("#ffb0a0")
		lab.outline_modulate = Color(0.2, 0.02, 0.02, 0.9)
		lab.position = Vector3(a.x, 0.45, a.y) + Vector3(-d.y, 0, d.x) * 1.0
		lab.no_depth_test = true
		lab.visible = false
		add_child(lab)
		arrows[region] = {"arrow": arrow, "label": lab}
	orbs_layer = Node3D.new()
	orbs_layer.name = "Orbs"
	add_child(orbs_layer)


## 区域着色：拖着棋子(场上的、货厢里的、商店卡)时淡入，松手后淡出；平时战场上看不到任何格子。
## wide = 拖的是能"随心所欲"部署的棋子：整张战斗地图都着成可放的蓝色(有地形的格子另外用红色格子标出)
func show_deploy(v: bool, instant: bool = false, wide: bool = false) -> void:
	_set_wide(wide)
	if v == deploy_shown and not instant:
		return
	deploy_shown = v
	if _fade != null and _fade.is_valid():
		_fade.kill()
	var a: float = 1.0 if v else 0.0
	if instant or not is_inside_tree():
		_set_zone_fade(a)
		zone.visible = v
		return
	zone.visible = true
	_fade = create_tween()
	_fade.tween_method(_set_zone_fade, float(_zone_mat.get_shader_parameter("fade")), a, 0.14)
	if not v:
		_fade.tween_callback(func() -> void: zone.visible = false)


var _wide := false


func _set_wide(w: bool) -> void:
	if w == _wide:
		return
	_wide = w
	_apply_rects(Rect2i(0, 0, GC.MAP_W, GC.MAP_H) if w else tl.deploy, tl.truck)


## 区域着色用的两块矩形(格子 → 战斗坐标的边)
func _apply_rects(deploy_r: Rect2i, truck_r: Rect2i) -> void:
	var d0: Vector2 = GC.cell_to_world(deploy_r.position.x, deploy_r.position.y) - Vector2(0.5, 0.5) * GC.CELL
	var d1: Vector2 = GC.cell_to_world(deploy_r.end.x - 1, deploy_r.end.y - 1) + Vector2(0.5, 0.5) * GC.CELL
	var t0: Vector2 = GC.cell_to_world(truck_r.position.x, truck_r.position.y) - Vector2(0.5, 0.5) * GC.CELL
	var t1: Vector2 = GC.cell_to_world(truck_r.end.x - 1, truck_r.end.y - 1) + Vector2(0.5, 0.5) * GC.CELL
	_zone_mat.set_shader_parameter("deploy", Vector4(d0.x, d0.y, d1.x, d1.y))
	_zone_mat.set_shader_parameter("truck", Vector4(t0.x, t0.y, t1.x, t1.y))


## 换成这个战斗地图布局里的卡车摆法(进战场 / 卡车挪动之后)
func apply_layout(layout: Dictionary) -> void:
	tl = TruckLayout.from_layout(layout)
	_apply_rects(Rect2i(0, 0, GC.MAP_W, GC.MAP_H) if _wide else tl.deploy, tl.truck)


## 拖着卡车时：区域着色先按候选的摆法画(松手后 apply_layout 换回真正的)
func preview_layout(p: TruckLayout) -> void:
	_apply_rects(p.deploy, p.truck)


func _set_zone_fade(a: float) -> void:
	_zone_mat.set_shader_parameter("fade", a)


## 区域着色的颜色(测试/调试用)：战斗坐标 p 处是 "ally"(部署格) / "truck" / "foe"
func zone_kind(p: Vector2) -> String:
	var c: Vector2i = GC.world_to_cell(p)
	if tl.truck.has_point(c):
		return "truck"
	return "ally" if tl.deploy.has_point(c) else "foe"


## 备战期：标出本次遭遇的敌人从哪些方位来(方位 -> 人数)
func set_threats(counts: Dictionary) -> void:
	_threat = counts
	for region: String in arrows.keys():
		var n: int = int(counts.get(region, 0))
		(arrows[region]["arrow"] as MeshInstance3D).visible = n > 0
		var lab: Label3D = arrows[region]["label"]
		lab.visible = n > 0
		lab.text = "×%d" % n


func _process(dt: float) -> void:
	_t += dt
	if _sf_mark != null and _sf_mark.visible:
		(_sf_mark.get_node("Star") as Node3D).rotation.y += dt * 1.2
		var k: float = 1.0 + 0.08 * sin(_t * 5.0)
		_sf_mark.get_child(0).scale = Vector3(k, 0.1, k)
	for region: String in arrows.keys():
		if int(_threat.get(region, 0)) > 0:
			var ar: MeshInstance3D = arrows[region]["arrow"]
			(ar.material_override as StandardMaterial3D).albedo_color.a = 0.35 + 0.3 * (0.5 + 0.5 * sin(_t * 4.0))


# ---------------------------------------------------------------- 星旅节点的预计落点(备战时)
## info = Run.starfall_preview()：{pos, radius, unit}；空 = 不显示。平时只画一个小落点标记(蓝色星形 + 一圈)，
## 悬停时(set_starfall_hover)再把整个落点范围画出来
var starfall_info: Dictionary = {}
const STARFALL_ICON_Y := 2.4
var _sf_mark: Node3D = null
var _sf_area: MeshInstance3D = null


func set_starfall(info: Dictionary) -> void:
	starfall_info = info
	if info.is_empty():
		if _sf_mark != null:
			_sf_mark.visible = false
		return
	if _sf_mark == null:
		_sf_mark = Node3D.new()
		_sf_mark.name = "StarfallMark"
		add_child(_sf_mark)
		var col := Color(0.45, 0.72, 1.0, 0.95)
		var ring_m := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.42
		tm.outer_radius = 0.5
		tm.rings = 40
		tm.ring_segments = 4
		ring_m.mesh = tm
		ring_m.scale = Vector3(1.0, 0.1, 1.0)
		ring_m.material_override = _mat(col)
		ring_m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_sf_mark.add_child(ring_m)
		var star := Node3D.new()
		star.name = "Star"
		_sf_mark.add_child(star)
		for i in range(4):
			var bm := BoxMesh.new()
			bm.size = Vector3(0.07, 0.01, 0.62 if i % 2 == 0 else 0.36)
			var st := MeshInstance3D.new()
			st.mesh = bm
			st.rotation.y = PI * 0.25 * float(i)
			st.material_override = _mat(Color(0.82, 0.92, 1.0, 1.0))
			st.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			star.add_child(st)
		# 落点正上方飘着的星形图标 + 一根往下的细线(落点常在敌人脚下，地上的标记会被挡住；指它也算指落点)
		var icon := Label3D.new()
		icon.name = "Icon"
		icon.text = "★"
		icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		icon.font_size = 96
		icon.pixel_size = 0.006
		icon.outline_size = 18
		icon.modulate = Color("#a8d2ff")
		icon.outline_modulate = Color(0.05, 0.1, 0.3, 0.95)
		icon.no_depth_test = true
		icon.position = Vector3(0, STARFALL_ICON_Y, 0)
		_sf_mark.add_child(icon)
		for si in range(6):
			var seg := MeshInstance3D.new()
			var sb := BoxMesh.new()
			sb.size = Vector3(0.025, 0.18, 0.025)
			seg.mesh = sb
			seg.position = Vector3(0, 0.25 + 0.33 * float(si), 0)
			seg.material_override = _mat(Color(0.65, 0.82, 1.0, 0.7))
			seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_sf_mark.add_child(seg)
		_sf_area = MeshInstance3D.new()
		var tm2 := TorusMesh.new()
		tm2.inner_radius = 0.96
		tm2.outer_radius = 1.0
		tm2.rings = 64
		tm2.ring_segments = 4
		_sf_area.mesh = tm2
		_sf_area.material_override = _mat(Color(0.45, 0.72, 1.0, 0.85))
		_sf_area.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_sf_area.visible = false
		_sf_mark.add_child(_sf_area)
		var disc := MeshInstance3D.new()
		disc.name = "Disc"
		var cm := CylinderMesh.new()
		cm.top_radius = 1.0
		cm.bottom_radius = 1.0
		cm.height = 0.01
		cm.radial_segments = 48
		disc.mesh = cm
		disc.material_override = _mat(Color(0.3, 0.55, 1.0, 0.18))
		disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_sf_area.add_child(disc)
	var p: Vector2 = info["pos"]
	_sf_mark.position = Vector3(p.x, TILE_Y + 0.02, p.y)
	var r: float = float(info.get("radius", 2.4))
	_sf_area.scale = Vector3(r, 0.08, r)
	(_sf_area.get_node("Disc") as Node3D).scale = Vector3(1.0, 1.0 / 0.08, 1.0)
	_sf_mark.visible = true


func set_starfall_hover(on: bool) -> void:
	if _sf_area != null:
		_sf_area.visible = on and not starfall_info.is_empty()


## 落点上方星形图标的世界坐标(用来判断鼠标是不是指着它)
func starfall_icon_pos() -> Vector3:
	var p: Vector2 = starfall_info.get("pos", Vector2.ZERO)
	return Vector3(p.x, STARFALL_ICON_Y, p.y)


## 屏幕上这一点(地面上的 lp)是不是指着落点标记
func starfall_hit(lp: Vector3) -> bool:
	if starfall_info.is_empty() or _sf_mark == null or not _sf_mark.visible:
		return false
	var p: Vector2 = starfall_info["pos"]
	return Vector2(lp.x, lp.z).distance_to(p) <= 0.75


# ---------------------------------------------------------------- 坐标 / 高亮 / 拾取(都是战斗坐标)
func cell_local(c: Vector2i) -> Vector3:
	var p: Vector2 = GC.cell_to_world(c.x, c.y)
	return Vector3(p.x, 0.0, p.y)


func clear_highlights() -> void:
	for c: Vector2i in hl.keys():
		(hl[c] as MeshInstance3D).visible = false


func highlight_cell(c: Vector2i, col: Color) -> void:
	if not hl.has(c):
		if c.x < 0 or c.y < 0 or c.x >= GC.MAP_W or c.y >= GC.MAP_H:
			return
		# 部署区以外的格子(随心所欲)：用到时再建
		var p: Vector2 = GC.cell_to_world(c.x, c.y)
		var h := MeshInstance3D.new()
		var hq := QuadMesh.new()
		hq.size = Vector2(GC.CELL - 0.14, GC.CELL - 0.14)
		hq.orientation = PlaneMesh.FACE_Y
		h.mesh = hq
		h.position = Vector3(p.x, TILE_Y + 0.006, p.y)
		h.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(h)
		hl[c] = h
	var h: MeshInstance3D = hl[c]
	h.material_override = _mat(col)
	h.visible = true


func highlight_rect(r: Rect2i, col: Color) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			highlight_cell(Vector2i(x, y), col)


## 射线(世界坐标) → {"type":"cell"/"none", "cell":Vector2i, "point":Vector3(战斗坐标)}；wide = 整张战斗地图的格子都算(卡车除外)
func pick(ray_o: Vector3, ray_d: Vector3, wide: bool = false) -> Dictionary:
	if absf(ray_d.y) < 0.0001:
		return {"type": "none"}
	var t: float = (global_position.y - ray_o.y) / ray_d.y
	if t < 0.0:
		return {"type": "none"}
	var wp: Vector3 = ray_o + ray_d * t
	var lp: Vector3 = wp - global_position
	var cell: Vector2i = GC.world_to_cell(Vector2(lp.x, lp.z))
	if tl.is_deploy_cell(cell):
		return {"type": "cell", "cell": cell, "point": lp}
	if wide and cell.x >= 0 and cell.y >= 0 and cell.x < GC.MAP_W and cell.y < GC.MAP_H and not tl.truck.has_point(cell):
		return {"type": "cell", "cell": cell, "point": lp}
	return {"type": "none", "point": lp}


func _mat(c: Color) -> StandardMaterial3D:
	var key: String = c.to_html()
	if _hl_mat_cache.has(key):
		return _hl_mat_cache[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = c
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_hl_mat_cache[key] = m
	return m


var _arrow_cache: ArrayMesh = null


func _arrow_mesh() -> ArrayMesh:
	if _arrow_cache != null:
		return _arrow_cache
	var v := PackedVector3Array([
		Vector3(0, 0, -0.55), Vector3(0.42, 0, -0.05), Vector3(-0.42, 0, -0.05),
		Vector3(0.16, 0, -0.05), Vector3(-0.16, 0, -0.05), Vector3(0.16, 0, 0.45), Vector3(-0.16, 0, 0.45)])
	var idx := PackedInt32Array([0, 1, 2, 3, 5, 4, 4, 5, 6])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_INDEX] = idx
	_arrow_cache = ArrayMesh.new()
	_arrow_cache.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return _arrow_cache
