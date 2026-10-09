class_name FireFX
extends Node3D
## 火焰类表现(第一章·红之章)：体素风格的火苗(发光的小方块往上飘、越飘越暗越小) + 烟柱 + 一盏会闪的火光灯。
##   FireFX.make(size, light, smoke)  一团火(燃烧废墟、大地图上烧着的楼)
##   FireFX.body(height)               棋子身上的【燃烧】
##   FireFX.fountain() / FireFX.tram() 事件场景：燃烧喷泉的火柱与火弧 / 末班电车车厢里的火
##   FireFX.ember_snow(extent, amount) 满天飘落的余烬
## 只是表现，不影响逻辑。

static var _cube: BoxMesh = null
static var _flame_mat: StandardMaterial3D = null
static var _smoke_mat: StandardMaterial3D = null
static var _spark_mat: StandardMaterial3D = null
static var _ramp_fire: GradientTexture1D = null
static var _ramp_smoke: GradientTexture1D = null
static var _snow_mat: StandardMaterial3D = null
static var _ramp_snow: GradientTexture1D = null

var light: OmniLight3D = null
var base_energy: float = 1.0
var _t: float = 0.0
var _seed: float = 0.0


static func _init_static() -> void:
	if _cube != null:
		return
	_cube = BoxMesh.new()
	_cube.size = Vector3.ONE * 0.1
	_flame_mat = StandardMaterial3D.new()
	_flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flame_mat.vertex_color_use_as_albedo = true
	_flame_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flame_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_flame_mat.albedo_color = Color(1.6, 1.3, 1.0)
	_smoke_mat = StandardMaterial3D.new()
	_smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_smoke_mat.vertex_color_use_as_albedo = true
	_smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_spark_mat = _flame_mat.duplicate() as StandardMaterial3D
	_spark_mat.albedo_color = Color(2.2, 1.5, 0.9)
	var gf := Gradient.new()
	gf.offsets = PackedFloat32Array([0.0, 0.18, 0.5, 0.8, 1.0])
	gf.colors = PackedColorArray([Color(1.0, 0.95, 0.6, 0.0), Color(1.0, 0.82, 0.3, 0.95), Color(1.0, 0.42, 0.08, 0.8), Color(0.7, 0.1, 0.03, 0.45), Color(0.2, 0.03, 0.02, 0.0)])
	_ramp_fire = GradientTexture1D.new()
	_ramp_fire.gradient = gf
	var gs := Gradient.new()
	gs.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	gs.colors = PackedColorArray([Color(0.12, 0.1, 0.1, 0.0), Color(0.1, 0.085, 0.08, 0.32), Color(0.16, 0.14, 0.13, 0.0)])
	_ramp_smoke = GradientTexture1D.new()
	_ramp_smoke.gradient = gs
	_snow_mat = _flame_mat.duplicate() as StandardMaterial3D
	_snow_mat.albedo_color = Color(1.3, 1.45, 1.7)
	var gn := Gradient.new()
	gn.offsets = PackedFloat32Array([0.0, 0.15, 0.85, 1.0])
	gn.colors = PackedColorArray([Color(0.9, 0.95, 1.0, 0.0), Color(0.92, 0.96, 1.0, 0.85), Color(0.8, 0.85, 1.0, 0.6), Color(0.7, 0.75, 1.0, 0.0)])
	_ramp_snow = GradientTexture1D.new()
	_ramp_snow.gradient = gn


static func _particles(amount: int, life: float, mat: StandardMaterial3D, ramp: GradientTexture1D) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.color_ramp = ramp
	p.process_material = pm
	p.draw_pass_1 = _cube
	p.material_override = mat
	p.amount = amount
	p.lifetime = life
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-6, -1, -6), Vector3(12, 30, 12))
	p.preprocess = life
	return p


## 一团火：size = 火苗覆盖的半径(米)；light = 带一盏闪烁的火光灯；smoke = 上面冒一柱黑烟
static func make(size: float = 0.5, with_light: bool = true, smoke: bool = true, light_energy: float = 2.4) -> FireFX:
	_init_static()
	var f := FireFX.new()
	f._seed = randf() * 10.0
	var fl: GPUParticles3D = _particles(int(clampf(26.0 * size * size + 14.0, 14.0, 140.0)), 0.9, _flame_mat, _ramp_fire)
	var pm: ParticleProcessMaterial = fl.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = size
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = 0.6 + size * 0.6
	pm.initial_velocity_max = 1.4 + size * 1.0
	pm.gravity = Vector3(0, 0.8, 0)
	pm.damping_min = 0.4
	pm.damping_max = 1.0
	pm.scale_min = 1.2 + size * 1.2
	pm.scale_max = 2.6 + size * 2.4
	var sc := Curve.new()
	sc.add_point(Vector2(0.0, 0.5))
	sc.add_point(Vector2(0.25, 1.0))
	sc.add_point(Vector2(1.0, 0.1))
	var sct := CurveTexture.new()
	sct.curve = sc
	pm.scale_curve = sct
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_scale = 2.0
	f.add_child(fl)
	# 火星：零星往上蹦的亮点
	var sp: GPUParticles3D = _particles(int(6.0 + size * 10.0), 1.6, _spark_mat, _ramp_fire)
	var spm: ParticleProcessMaterial = sp.process_material
	spm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spm.emission_sphere_radius = size
	spm.direction = Vector3(0, 1, 0)
	spm.spread = 35.0
	spm.initial_velocity_min = 1.5
	spm.initial_velocity_max = 3.5
	spm.gravity = Vector3(0, -0.6, 0)
	spm.scale_min = 0.25
	spm.scale_max = 0.5
	spm.turbulence_enabled = true
	spm.turbulence_noise_strength = 1.2
	f.add_child(sp)
	if smoke:
		var sm: GPUParticles3D = _particles(int(10.0 + size * 12.0), 4.0, _smoke_mat, _ramp_smoke)
		var smm: ParticleProcessMaterial = sm.process_material
		smm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		smm.emission_sphere_radius = size * 0.7
		smm.direction = Vector3(0.15, 1, 0)
		smm.spread = 10.0
		smm.initial_velocity_min = 0.8 + size * 0.5
		smm.initial_velocity_max = 1.4 + size * 0.8
		smm.gravity = Vector3(0.25, 0.1, 0)
		smm.scale_min = 2.5 + size * 2.0
		smm.scale_max = 4.0 + size * 3.5
		sm.position = Vector3(0, size * 1.2 + 0.4, 0)
		f.add_child(sm)
	if with_light:
		var lt := OmniLight3D.new()
		lt.light_color = Color("#ff7a2c")
		lt.light_energy = light_energy
		lt.omni_range = 2.5 + size * 4.0
		lt.omni_attenuation = 1.4
		lt.shadow_enabled = false
		lt.position = Vector3(0, 0.4 + size * 0.6, 0)
		f.add_child(lt)
		f.light = lt
		f.base_energy = light_energy
	return f


## 余烬地块上零星蹦起来的火星(没有火苗、没有灯)
static func sparks(extent: Vector2) -> FireFX:
	_init_static()
	var f := FireFX.new()
	var sp: GPUParticles3D = _particles(int(clampf(extent.x * extent.y * 6.0, 4.0, 24.0)), 1.4, _spark_mat, _ramp_fire)
	var spm: ParticleProcessMaterial = sp.process_material
	spm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	spm.emission_box_extents = Vector3(extent.x, 0.02, extent.y)
	spm.direction = Vector3(0, 1, 0)
	spm.spread = 25.0
	spm.initial_velocity_min = 0.4
	spm.initial_velocity_max = 1.2
	spm.gravity = Vector3(0, 0.2, 0)
	spm.scale_min = 0.2
	spm.scale_max = 0.4
	spm.turbulence_enabled = true
	spm.turbulence_noise_strength = 0.6
	f.add_child(sp)
	return f


## 大火上方的烟柱：柔边的圆形烟团(不是方块)，越升越大越淡，被风吹偏(远看才好看，大地图用)
static var _plume_mat: StandardMaterial3D = null
static var _plume_quad: QuadMesh = null


static func plume(size: float) -> GPUParticles3D:
	_init_static()
	if _plume_mat == null:
		var gt := GradientTexture2D.new()
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 64
		gt.height = 64
		_plume_mat = StandardMaterial3D.new()
		_plume_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_plume_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_plume_mat.vertex_color_use_as_albedo = true
		_plume_mat.albedo_texture = gt
		_plume_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		_plume_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		_plume_quad = QuadMesh.new()
		_plume_quad.size = Vector2.ONE
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	var gs := Gradient.new()
	gs.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	gs.colors = PackedColorArray([Color(0.3, 0.12, 0.06, 0.0), Color(0.05, 0.045, 0.045, 0.4), Color(0.07, 0.06, 0.06, 0.0)])
	var gtex := GradientTexture1D.new()
	gtex.gradient = gs
	pm.color_ramp = gtex
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = size * 0.6
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 8.0
	pm.initial_velocity_min = 2.0 + size
	pm.initial_velocity_max = 3.0 + size * 1.4
	pm.gravity = Vector3(1.2, 0.2, 0.3)
	pm.damping_min = 0.3
	pm.damping_max = 0.6
	pm.scale_min = 3.0 + size * 2.0
	pm.scale_max = 5.0 + size * 3.0
	var sc := Curve.new()
	sc.add_point(Vector2(0.0, 0.4))
	sc.add_point(Vector2(1.0, 2.2))
	var sct := CurveTexture.new()
	sct.curve = sc
	pm.scale_curve = sct
	p.process_material = pm
	p.draw_pass_1 = _plume_quad
	p.material_override = _plume_mat
	p.amount = 26
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-40, -5, -40), Vector3(80, 120, 80))
	return p


## 棋子身上的【燃烧】：贴着身体往上窜的小火苗(没有灯，免得一大群人着火时灯太多)
static func body(height: float = 1.0) -> FireFX:
	_init_static()
	var f := FireFX.new()
	var fl: GPUParticles3D = _particles(18, 0.6, _flame_mat, _ramp_fire)
	var pm: ParticleProcessMaterial = fl.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.22, height * 0.35, 0.22)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 15.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 1.1
	pm.gravity = Vector3(0, 0.6, 0)
	pm.scale_min = 0.9
	pm.scale_max = 1.6
	fl.position = Vector3(0, height * 0.45, 0)
	fl.local_coords = false
	f.add_child(fl)
	# 方块火苗外面再裹一层柔光的火焰团(白热 → 橙 → 暗红 → 烟)：不然只是一堆往上飘的硬方块
	var soft: GPUParticles3D = SoftFX.particles(12, 0.55, SoftFX.fire_ramp(Color("#ff5a1a"), 1.3), 0.34)
	var spm: ParticleProcessMaterial = soft.process_material
	spm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	spm.emission_box_extents = Vector3(0.2, height * 0.3, 0.2)
	spm.direction = Vector3(0, 1, 0)
	spm.spread = 12.0
	spm.initial_velocity_min = 0.4
	spm.initial_velocity_max = 0.9
	spm.gravity = Vector3(0, 0.5, 0)
	soft.position = Vector3(0, height * 0.4, 0)
	soft.emitting = true
	f.add_child(soft)
	return f


## 燃烧喷泉(事件「燃烧喷泉」的场景 / 事件战斗地图上的喷泉)：喷口往上冲的一道三人多高的火柱，
## 上层小盘边上往四面八方洒出 8 道火弧(像喷泉的水线一样划着曲线落进池子)，两层盘和池底都烧着，一盏火光灯。
## 原点 = 喷泉底座中心；k = 缩放(模型就是 1：池子半径 1.4 米，喷口高 2.05 米)
static func fountain(k: float = 1.0, with_light: bool = true) -> FireFX:
	_init_static()
	var f := FireFX.new()
	f._seed = randf() * 10.0
	# 中间的火柱：往上冲到 ~5 米(三人多高)再散落
	var col: GPUParticles3D = _particles(120, 2.0, _flame_mat, _ramp_fire)
	var cpm: ParticleProcessMaterial = col.process_material
	cpm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	cpm.emission_sphere_radius = 0.12 * k
	cpm.direction = Vector3(0, 1, 0)
	cpm.spread = 4.0
	cpm.initial_velocity_min = 5.0 * sqrt(k)
	cpm.initial_velocity_max = 5.5 * sqrt(k)
	cpm.gravity = Vector3(0, -4.6, 0)
	cpm.scale_min = 1.1 * k
	cpm.scale_max = 2.0 * k
	var sc := Curve.new()
	sc.add_point(Vector2(0.0, 0.7))
	sc.add_point(Vector2(0.45, 1.0))
	sc.add_point(Vector2(1.0, 0.15))
	var sct := CurveTexture.new()
	sct.curve = sc
	cpm.scale_curve = sct
	col.position = Vector3(0, 2.05 * k, 0)
	col.visibility_aabb = AABB(Vector3(-4, -3, -4), Vector3(8, 9, 8))
	f.add_child(col)
	# 8 道火弧：从上层小盘的边上斜着洒出去，落进外面的大池子
	for i in range(8):
		var a: float = float(i) * TAU / 8.0 + 0.2
		var arc: GPUParticles3D = _particles(30, 1.05, _flame_mat, _ramp_fire)
		var apm: ParticleProcessMaterial = arc.process_material
		apm.direction = Vector3(cos(a) * 0.62, 1.0, sin(a) * 0.62)
		apm.spread = 2.5
		apm.initial_velocity_min = 3.1 * sqrt(k)
		apm.initial_velocity_max = 3.3 * sqrt(k)
		apm.gravity = Vector3(0, -7.5, 0)
		apm.scale_min = 0.5 * k
		apm.scale_max = 0.85 * k
		apm.scale_curve = sct
		arc.position = Vector3(cos(a) * 0.3 * k, 1.78 * k, sin(a) * 0.3 * k)
		arc.visibility_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))
		f.add_child(arc)
	# 两层盘里和池底的火
	for spot: Array in [[Vector3(0, 1.12, 0), 0.45], [Vector3(0, 0.1, 0), 1.05]]:
		var fl: FireFX = make(float(spot[1]) * k, false, false)
		fl.position = (spot[0] as Vector3) * k
		f.add_child(fl)
	if with_light:
		var lt := OmniLight3D.new()
		lt.light_color = Color("#ff7a2c")
		lt.light_energy = 3.6
		lt.omni_range = 8.0 * k
		lt.omni_attenuation = 1.3
		lt.shadow_enabled = false
		lt.position = Vector3(0, 2.6 * k, 0)
		f.add_child(lt)
		f.light = lt
		f.base_energy = 3.6
	return f


## 末班电车(事件「末班电车」的画面 / 电车站战场上冲过去的电车)：车厢里沿着整节车往上窜的火(从窗口和车顶冒出来)，
## 车顶烧穿的洞和两扇开着的车门里各有一团火，一盏火光灯。原点 = 电车底面中心，车头朝 +X，车门在 -Z 一侧
## (模型 burn_tram：长 9.8 米、宽 2.2 米、车顶 2.8 米)。粒子用世界坐标：电车开动时火会在车后拖成一条尾巴
static func tram(with_light: bool = true) -> FireFX:
	_init_static()
	var f := FireFX.new()
	f._seed = randf() * 10.0
	var fl: GPUParticles3D = _particles(170, 0.9, _flame_mat, _ramp_fire)
	var pm: ParticleProcessMaterial = fl.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(4.4, 0.25, 0.5)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 14.0
	pm.initial_velocity_min = 0.8
	pm.initial_velocity_max = 2.0
	pm.gravity = Vector3(0, 0.8, 0)
	pm.damping_min = 0.4
	pm.damping_max = 1.0
	pm.scale_min = 1.4
	pm.scale_max = 3.0
	var sc := Curve.new()
	sc.add_point(Vector2(0.0, 0.5))
	sc.add_point(Vector2(0.25, 1.0))
	sc.add_point(Vector2(1.0, 0.1))
	var sct := CurveTexture.new()
	sct.curve = sc
	pm.scale_curve = sct
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_scale = 2.0
	fl.position = Vector3(0, 2.25, 0)
	fl.visibility_aabb = AABB(Vector3(-12, -4, -12), Vector3(24, 14, 24))
	f.add_child(fl)
	# 车顶的洞、前后车门
	for spot: Array in [[Vector3(1.1, 2.75, 0), 0.6], [Vector3(3.55, 1.1, -0.9), 0.2], [Vector3(-3.55, 1.1, -0.9), 0.2]]:
		var s: FireFX = make(float(spot[1]), false, false)
		s.position = spot[0]
		f.add_child(s)
	if with_light:
		var lt := OmniLight3D.new()
		lt.light_color = Color("#ff7a2c")
		lt.light_energy = 4.2
		lt.omni_range = 11.0
		lt.omni_attenuation = 1.3
		lt.shadow_enabled = false
		lt.position = Vector3(0, 2.4, 0)
		f.add_child(lt)
		f.light = lt
		f.base_energy = 4.2
	return f


## 一道往上冲的火柱(喷泉蓄力时暴涨的那一截)：冲到 height 米高，底部半径 radius
static func jet(height: float, radius: float = 0.3) -> GPUParticles3D:
	_init_static()
	var p: GPUParticles3D = _particles(220, 1.5, _flame_mat, _ramp_fire)
	var pm: ParticleProcessMaterial = p.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = radius
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 5.0
	var v0: float = sqrt(2.0 * 6.0 * height)
	pm.initial_velocity_min = v0 * 0.85
	pm.initial_velocity_max = v0
	pm.gravity = Vector3(0, -6.0, 0)
	pm.scale_min = 2.2
	pm.scale_max = 4.2
	var sc := Curve.new()
	sc.add_point(Vector2(0.0, 0.7))
	sc.add_point(Vector2(0.5, 1.0))
	sc.add_point(Vector2(1.0, 0.2))
	var sct := CurveTexture.new()
	sct.curve = sc
	pm.scale_curve = sct
	p.preprocess = 0.0
	p.visibility_aabb = AABB(Vector3(-6, -4, -6), Vector3(12, height + 8.0, 12))
	return p


## 满天飘落的余烬：extent = 覆盖范围(米，XZ)，从高处慢慢往下飘、随风横移
## 飘雪(紫之章)：慢慢落下、随风飘的白色小片；高度 height 的一片空间里循环
static func snow(extent: Vector2, amount: int = 220, height: float = 14.0) -> GPUParticles3D:
	_init_static()
	var p: GPUParticles3D = _particles(amount, 11.0, _snow_mat, _ramp_snow)
	var pm: ParticleProcessMaterial = p.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(extent.x * 0.5, height * 0.5, extent.y * 0.5)
	pm.direction = Vector3(0.25, -1, 0.1)
	pm.spread = 20.0
	pm.initial_velocity_min = 0.25
	pm.initial_velocity_max = 0.7
	pm.gravity = Vector3(0.1, -0.12, 0)
	pm.scale_min = 0.3
	pm.scale_max = 0.7
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_scale = 5.0
	p.position = Vector3(0, height * 0.5, 0)
	p.visibility_aabb = AABB(Vector3(-extent.x, -height, -extent.y), Vector3(extent.x * 2.0, height * 2.0, extent.y * 2.0))
	return p


static func ember_snow(extent: Vector2, amount: int = 220, height: float = 14.0) -> GPUParticles3D:
	_init_static()
	var p: GPUParticles3D = _particles(amount, 9.0, _spark_mat, _ramp_fire)
	var pm: ParticleProcessMaterial = p.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(extent.x * 0.5, height * 0.5, extent.y * 0.5)
	pm.direction = Vector3(0.4, -1, 0.1)
	pm.spread = 25.0
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.9
	pm.gravity = Vector3(0.2, -0.15, 0)
	pm.scale_min = 0.25
	pm.scale_max = 0.6
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.8
	pm.turbulence_noise_scale = 6.0
	p.position = Vector3(0, height * 0.5, 0)
	p.visibility_aabb = AABB(Vector3(-extent.x, -height, -extent.y), Vector3(extent.x * 2.0, height * 2.0, extent.y * 2.0))
	return p


func set_emitting(on: bool) -> void:
	for ch: Node in get_children():
		if ch is GPUParticles3D:
			(ch as GPUParticles3D).emitting = on
	if light != null:
		light.visible = on


func _process(dt: float) -> void:
	if light == null or not light.visible:
		return
	_t += dt
	# 火光轻轻起伏(幅度小、频率低：快速大幅的明灭会让棋子身上的高光一闪一闪)
	var k: float = 0.93 + 0.05 * sin(_t * 3.1 + _seed) + 0.02 * sin(_t * 7.3 + _seed * 2.0)
	light.light_energy = base_energy * k
