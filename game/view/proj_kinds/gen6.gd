extends RefCounted
## 通用武器 · gen6(步枪 / 弓)的投射物(ProjRegistry 登记；接口见 game/view/proj_registry.gd)。
##   g6_tide_drop   回潮步枪：一颗水弹(半透明的青色水珠 + 白色高光，飞的时候一胀一缩)，身后拖一道水痕、甩出几滴水珠；
##                  出手枪口一圈水花，命中"啪"地溅开(一圈水环 + 往下落的水珠)
##   g6_sun_arrow   金乌长弓：一支带着日光的金箭(发光的箭 + 箭头一团小太阳)，身后拖一道金色光带、飘火星；
##                  出手弓上一闪金光，命中炸开一轮小日冕(金光 + 一圈光环 + 四散的火星)
## 弹体的 -Z = 飞行方向(BattleView 用 look_at 对准目标)。步枪的出手点是扳机那只手：往前挪到枪口(RIFLE_MUZZLE 米)。

const KINDS: Array[String] = ["g6_tide_drop", "g6_sun_arrow"]

const TIDE := Color("#2fb8c8")
const TIDE_LIGHT := Color("#9fe9f0")
const TIDE_FOAM := Color("#e8fbff")
const SUN := Color("#ffc23a")
const SUN_HOT := Color("#fff3c0")
const SUN_DEEP := Color("#ff8a1c")
const RIFLE_MUZZLE := 0.45


static func make(fx: Fx, kind: String, heal: bool, _color: Color) -> Node3D:
	var root := Node3D.new()
	match kind:
		"g6_tide_drop":
			_tide_drop(fx, root, heal)
		"g6_sun_arrow":
			_sun_arrow(fx, root)
	return root


static func fly(node: Node3D, kind: String, frac: float, t: float, seed: float) -> Vector3:
	match kind:
		"g6_tide_drop":
			# 水弹：几乎直线(轻轻往上拱)；水珠一胀一缩
			var wb: Node3D = node.get_node_or_null("Wobble")
			if wb != null:
				var sq: float = sin(t * 24.0 + seed * 1.7) * 0.1
				wb.scale = Vector3(1.0 - sq, 1.0 + sq, 1.0 + sq * 0.6)
			return Vector3(0.0, sin(frac * PI) * 0.05, 0.0)
		"g6_sun_arrow":
			# 金箭：和箭一样往上拱一点；箭头的小太阳一明一暗
			var sn: Node3D = node.get_node_or_null("Sun")
			if sn != null:
				sn.scale = Vector3.ONE * (1.0 + 0.2 * sin(t * 31.0 + seed * 2.1))
			return Vector3(0.0, sin(frac * PI) * 0.16, 0.0)
	return Vector3.ZERO


static func release(fx: Fx, kind: String, at: Vector3, dir: Vector3) -> void:
	match kind:
		"g6_tide_drop":
			var mz: Vector3 = at + dir * RIFLE_MUZZLE
			fx.soft_flash(mz, TIDE_LIGHT, 0.35, 0.14, 1.2)
			fx._ripple(mz, dir, TIDE, 0.05, 0.28, 0.25, 0.75)
			fx.burst(mz + dir * 0.05, TIDE_LIGHT, 6, 1.4, 0.45, 0.6, 0.3)
		"g6_sun_arrow":
			fx.soft_flash(at, SUN, 0.4, 0.16, 1.6)
			fx.burst(at, SUN_HOT, 5, 1.2, 0.4, 0.5, 0.25)


static func hit(fx: Fx, kind: String, at: Vector3, dir: Vector3) -> void:
	match kind:
		"g6_tide_drop":
			# "啪"：一闪 + 一圈很快散开的水环 + 往下落的水珠 + 几点白沫
			fx.soft_flash(at, TIDE_LIGHT, 0.6, 0.16, 1.5)
			fx._ripple(at, dir, TIDE, 0.12, 0.55, 0.28, 0.85)
			fx._ripple(at, Vector3.UP, TIDE_LIGHT, 0.1, 0.45, 0.3, 0.6)
			fx.burst(at, TIDE, 12, 2.0, 0.5, 0.9, 0.45, false)
			fx.burst(at, TIDE_FOAM, 4, 1.4, 0.35, 0.8, 0.3)
		"g6_sun_arrow":
			# 小日冕：金光 + 一圈光环 + 四散的火星
			fx.soft_flash(at, SUN, 0.6, 0.2, 1.8)
			fx.soft_flash(at, SUN_HOT, 0.3, 0.12, 2.2)
			fx._ripple(at, dir, SUN, 0.1, 0.6, 0.3, 0.8)
			fx.burst(at + dir * 0.05, SUN_DEEP, 10, 3.0, 0.45, 0.6, 0.32)
			fx.burst(at, SUN_HOT, 5, 2.0, 0.35, 0.8, 0.25)


# ---------------------------------------------------------------- 弹体
static func _tide_drop(fx: Fx, root: Node3D, heal: bool) -> void:
	var wob := Node3D.new()
	wob.name = "Wobble"
	root.add_child(wob)
	# 水珠：前圆后尖(一个球 + 往后拉长的一截)，半透明的青色，芯亮一点
	var body := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.1
	sm.height = 0.2
	sm.radial_segments = 14
	sm.rings = 7
	body.mesh = sm
	body.material_override = fx._emissive(TIDE_LIGHT if heal else TIDE, 1.6, 0.75)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wob.add_child(body)
	var tail := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = 0.085
	cm.height = 0.2
	cm.radial_segments = 10
	tail.mesh = cm
	tail.rotation.x = PI * 0.5                        # 尖头朝后(+Z)，粗的一头贴着水珠
	tail.position = Vector3(0.0, 0.0, 0.09)
	tail.material_override = fx._emissive(TIDE_LIGHT if heal else TIDE, 1.4, 0.6)
	tail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wob.add_child(tail)
	var core := MeshInstance3D.new()
	var cs := SphereMesh.new()
	cs.radius = 0.05
	cs.height = 0.1
	cs.radial_segments = 8
	cs.rings = 4
	core.mesh = cs
	core.material_override = fx._emissive(TIDE_FOAM, 2.2)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wob.add_child(core)
	var hl := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.022
	hs.height = 0.044
	hs.radial_segments = 6
	hs.rings = 3
	hl.mesh = hs
	hl.position = Vector3(-0.04, 0.055, -0.04)
	hl.material_override = fx._emissive(Color.WHITE, 2.0, 0.9)
	hl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wob.add_child(hl)
	# 水痕 + 甩出去的水珠
	var rib: RibbonTrail = RibbonTrail.create(root, TIDE_LIGHT, 0.07, 0.16)
	rib.name = "Ribbon"
	rib.time_scale = maxf(0.2, fx.speed_scale)
	root.add_child(rib)
	var dr := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0.6, 0)
	pm.spread = 70.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.6
	pm.gravity = Vector3(0, -3.0, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	dr.process_material = pm
	var ds := SphereMesh.new()
	ds.radius = 0.02
	ds.height = 0.04
	ds.radial_segments = 6
	ds.rings = 3
	dr.draw_pass_1 = ds
	dr.material_override = fx._emissive(TIDE_LIGHT, 1.6, 0.85)
	dr.amount = 10
	dr.lifetime = 0.35
	dr.local_coords = false
	dr.emitting = true
	dr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dr.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
	root.add_child(dr)
	root.scale = Vector3.ONE * 1.3


static func _sun_arrow(fx: Fx, root: Node3D) -> void:
	# 发光的金箭(箭的网格，换成发光材质)
	var am := MeshInstance3D.new()
	am.mesh = fx.arrow_mesh
	am.rotation.y = PI
	am.position = Vector3(Fx.ARROW_CENTER.x, -Fx.ARROW_CENTER.y, Fx.ARROW_CENTER.z)
	am.material_override = fx._emissive(SUN, 3.2)
	am.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(am)
	# 箭头的小太阳：柔光的光晕 + 白热的芯
	var sun := Node3D.new()
	sun.name = "Sun"
	sun.position = Vector3(0.0, 0.0, -0.3)
	root.add_child(sun)
	var halo := MeshInstance3D.new()
	halo.mesh = SoftFX.quad(0.26)
	halo.material_override = SoftFX.sprite_mat(SUN, 1.1)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sun.add_child(halo)
	var core := MeshInstance3D.new()
	core.mesh = SoftFX.quad(0.11)
	core.material_override = SoftFX.sprite_mat(SUN_HOT, 1.8)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sun.add_child(core)
	# 金色光带 + 飘落的火星
	var rib: RibbonTrail = RibbonTrail.create(root, SUN, 0.08, 0.2)
	rib.name = "Ribbon"
	rib.time_scale = maxf(0.2, fx.speed_scale)
	root.add_child(rib)
	var sp := GPUParticles3D.new()
	var spm := ParticleProcessMaterial.new()
	spm.direction = Vector3(0, 0.3, 0)
	spm.spread = 40.0
	spm.initial_velocity_min = 0.05
	spm.initial_velocity_max = 0.35
	spm.gravity = Vector3(0, -0.6, 0)
	spm.scale_min = 0.4
	spm.scale_max = 0.8
	sp.process_material = spm
	sp.draw_pass_1 = fx._box
	sp.material_override = fx._emissive(SUN_DEEP, 3.0)
	sp.amount = 14
	sp.lifetime = 0.32
	sp.local_coords = false
	sp.emitting = true
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sp.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
	root.add_child(sp)
	root.scale = Vector3.ONE * 1.1
