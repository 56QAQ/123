class_name NestCrate
extends Node3D
## 屏息节点的狙击窝：她跪下来时身前那只黑色的硬壳箱子，枪的护木就搁在箱子顶上(UnitView 的 nest 模式摆它)。
## 黑色箱体 + 深灰的上下边框、四根护角、两侧各两个金属搭扣，侧面一道和枪身同色的蓝色细光条。
## drop()：从半空落下来、砸地一颤 + 一小圈灰尘；leave()：留在原地一小会儿，再沉进地里消失(她起身走了)。
## 箱子摆在世界里(top_level)，她在一定角度内转身时箱子不动、枪在箱子上转

const W := 0.42                   # 宽(左右)
const D := 0.24                   # 深(前后)
const BODY := Color("#1b1c21")
const RIM := Color("#2c2f37")
const POST := Color("#3a3e48")
const LATCH := Color("#8a909c")
const GLOW := Color("#2f7dff")

static var _mats: Dictionary = {}
var height := 0.44
var _gone := false


## top = 箱顶的高度(米)：护木搁在上面
static func create(parent: Node3D, xf: Transform3D, top: float, k: float = 1.0) -> NestCrate:
	var c := NestCrate.new()
	c.top_level = true
	c.height = top
	parent.add_child(c)
	c.global_transform = xf
	c._build(k)
	return c


static func _mat(col: Color, glow: bool = false) -> StandardMaterial3D:
	var key: String = col.to_html() + ("g" if glow else "")
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.55
	m.metallic = 0.25 if col == LATCH else 0.0
	if glow:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = 1.6
	_mats[key] = m
	return m


func _box(size: Vector3, pos: Vector3, col: Color, glow: bool = false) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(col, glow)
	mi.position = pos
	if glow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _build(k: float) -> void:
	var w: float = W * k
	var d: float = D * k
	var h: float = height
	var e: float = 0.02 * k
	_box(Vector3(w, h, d), Vector3(0.0, h * 0.5, 0.0), BODY)
	_box(Vector3(w + e, 0.035 * k, d + e), Vector3(0.0, h - 0.0175 * k, 0.0), RIM)
	_box(Vector3(w + e, 0.03 * k, d + e), Vector3(0.0, 0.015 * k, 0.0), RIM)
	_box(Vector3(w + e * 0.5, 0.02 * k, d + e * 0.5), Vector3(0.0, h * 0.62, 0.0), RIM)          # 箱盖的缝
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_box(Vector3(0.032 * k, h, 0.032 * k), Vector3(sx * (w * 0.5 - 0.006 * k), h * 0.5, sz * (d * 0.5 - 0.006 * k)), POST)
	for sz2: float in [-1.0, 1.0]:
		for lx: float in [-0.13, 0.13]:
			_box(Vector3(0.05 * k, 0.07 * k, 0.018 * k), Vector3(lx * k, h * 0.62, sz2 * (d * 0.5 + 0.009 * k)), LATCH)
		_box(Vector3(w * 0.62, 0.014 * k, 0.006 * k), Vector3(0.0, h * 0.3, sz2 * (d * 0.5 + 0.004 * k)), GLOW, true)


## 从 0.55 米高处落下、砸地一颤，扬起一小圈灰
func drop(time_scale: float = 1.0) -> void:
	var s: float = maxf(0.2, time_scale)
	var y0: float = position.y
	position.y = y0 + 0.55
	scale = Vector3.ONE
	var tw := create_tween()
	tw.tween_property(self, "position:y", y0, 0.16 / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(_dust)
	tw.tween_property(self, "scale", Vector3(1.07, 0.88, 1.07), 0.05 / s)
	tw.tween_property(self, "scale", Vector3.ONE, 0.12 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _dust() -> void:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(W * 0.5, 0.02, D * 0.5)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 80.0
	pm.initial_velocity_min = 0.4
	pm.initial_velocity_max = 1.1
	pm.gravity = Vector3(0, -1.5, 0)
	pm.damping_min = 2.0
	pm.damping_max = 3.0
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1.0))
	curve.add_point(Vector2(1, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	pm.color = Color("#b8b0a4")
	p.process_material = pm
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE * 0.05
	p.draw_pass_1 = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("#b8b0a4")
	m.vertex_color_use_as_albedo = true
	p.material_override = m
	p.amount = 10
	p.lifetime = 0.45
	p.one_shot = true
	p.explosiveness = 1.0
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	p.emitting = true
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)


## 她起身走了：箱子在原地留一会儿，再沉进地里、缩小消失
func leave(time_scale: float = 1.0) -> void:
	if _gone:
		return
	_gone = true
	var s: float = maxf(0.2, time_scale)
	var tw := create_tween()
	tw.tween_interval(0.5 / s)
	tw.set_parallel(true)
	tw.tween_property(self, "position:y", position.y - height * 0.9, 0.35 / s).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "scale", Vector3(0.6, 0.6, 0.6), 0.35 / s)
	tw.chain().tween_callback(queue_free)
