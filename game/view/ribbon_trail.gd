class_name RibbonTrail
extends MeshInstance3D
## 拖尾光带(巫术节点的虹光飞弹…)：跟着 follow 走，记下最近 life 秒走过的位置，画成一条面向镜头的光带——
## 越新越宽越亮、越旧越细越淡；外面一层颜色(普通混合：白地上也看得见)，中间一条白热的芯。
## detach()：不再跟着(弹头没了)，剩下的这一截自己淡完再删掉。世界坐标(top_level)。

var follow: Node3D = null
var color: Color = Color.WHITE
var width: float = 0.14
var life: float = 0.3
var _pts: Array = []                     # [位置, 时刻]
var _clock: float = 0.0
var _detached: bool = false
var _im: ImmediateMesh
var _mat: StandardMaterial3D
var time_scale: float = 1.0               # 慢放 / 倍速：拖尾按战斗时间淡
var active: bool = true                   # false = 暂时不记新的点(跟着的东西停在半空：完美时计的飞刀)，旧的照常淡掉


static func create(p_follow: Node3D, p_color: Color, p_width: float = 0.14, p_life: float = 0.3) -> RibbonTrail:
	var r := RibbonTrail.new()
	r.follow = p_follow
	r.color = p_color
	r.width = p_width
	r.life = p_life
	return r


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_im = ImmediateMesh.new()
	mesh = _im
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.vertex_color_is_srgb = true
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.disable_fog = true
	material_override = _mat
	extra_cull_margin = 16.0


func detach() -> void:
	_detached = true


func _process(delta: float) -> void:
	_clock += delta * time_scale
	if active and not _detached and follow != null and is_instance_valid(follow) and follow.is_inside_tree() and follow.visible:
		var p: Vector3 = follow.global_position
		if _pts.is_empty() or (_pts[-1][0] as Vector3).distance_to(p) > 0.02:
			_pts.append([p, _clock])
		else:
			_pts[-1][1] = _clock
	elif not _detached and (follow == null or not is_instance_valid(follow)):
		_detached = true
	while not _pts.is_empty() and _clock - float(_pts[0][1]) > life:
		_pts.pop_front()
	if _detached and _pts.is_empty():
		queue_free()
		return
	_rebuild()


func _rebuild() -> void:
	_im.clear_surfaces()
	var n: int = _pts.size()
	if n < 2:
		return
	var cam: Camera3D = get_viewport().get_camera_3d()
	var eye: Vector3 = cam.global_position if cam != null else Vector3(0, 20, 20)
	var hot: Color = color.lerp(Color.WHITE, 0.55)
	for layer: Array in [[1.0, color, 0.9], [0.22, hot, 0.85]]:
		var wk: float = float(layer[0])
		var c: Color = layer[1]
		var a0: float = float(layer[2])
		_im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _mat)
		for i in range(n):
			var p: Vector3 = _pts[i][0]
			var k: float = clampf(1.0 - (_clock - float(_pts[i][1])) / life, 0.0, 1.0)
			var tg: Vector3 = (_pts[mini(i + 1, n - 1)][0] as Vector3) - (_pts[maxi(i - 1, 0)][0] as Vector3)
			var side: Vector3 = tg.cross(eye - p)
			side = side.normalized() if side.length() > 1e-5 else Vector3.RIGHT
			var w: float = width * wk * pow(k, 0.7)
			_im.surface_set_color(Color(c.r, c.g, c.b, a0 * k * k))
			_im.surface_add_vertex(p + side * w)
			_im.surface_set_color(Color(c.r, c.g, c.b, a0 * k * k))
			_im.surface_add_vertex(p - side * w)
		_im.surface_end()
