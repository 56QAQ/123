extends RefCounted
## 通用武器 · gen13 的投射物与刀光(ProjRegistry 登记；接口见 game/view/proj_registry.gd)。
##   g13_hypno   催眠双枪：一圈紫色的催眠波纹(两层套着的光环 + 中间一点亮芯，绕飞行轴一直转)，微微左右晃着飞；
##               出手一圈紫色的涟漪，命中一层层往外扩的螺旋波纹 + 几点星
##   g13_petals  玫瑰花束：一小把绕着飞行轴打转的红玫瑰花瓣(五片深浅不一的红 + 一点粉光)，往上拱一点飞过去，身后飘几片粉瓣；
##               出手抖落几片花瓣，命中一把花瓣散开 + 一圈粉光
## 弹体的 -Z = 飞行方向(BattleView 用 look_at 对准目标)。

const KINDS: Array[String] = ["g13_hypno", "g13_petals"]
## 近战武器的刀光(外观名 → {base, tip, life, energy, alpha, color}，刃根 / 刃尖是武器骨局部 +Y 的体素)；WeaponTrail 会查这里
const TRAILS := {
	# 琥珀双刃：琥珀刃 5~28，蜜金
	"g13_amber": {"base": 7.0, "tip": 27.0, "life": 0.14, "energy": 1.25, "alpha": 0.78, "color": Color("#ffc246")},
	# 螳螂双镰：镰刃 5~27，往刀背弯的镰尖取到 25；嫩绿
	"g13_mantis": {"base": 7.0, "tip": 25.0, "life": 0.13, "energy": 1.2, "alpha": 0.74, "color": Color("#9cf06a")},
}

const HYP := Color("#a24ef0")
const HYP2 := Color("#e0b8ff")
const HYP3 := Color("#6a2cc0")
const STAR := Color("#fff2c8")
const ROSE := Color("#d81e3c")
const ROSE2 := Color("#ff5a74")
const ROSE3 := Color("#9a1028")
const PINK := Color("#ffb4c8")
const LEAF := Color("#3f8a3a")


static func make(fx: Fx, kind: String, _heal: bool, _color: Color) -> Node3D:
	var root := Node3D.new()
	match kind:
		"g13_hypno":
			_hypno(fx, root)
		"g13_petals":
			_petals(fx, root)
	return root


static func fly(node: Node3D, kind: String, frac: float, t: float, seed: float) -> Vector3:
	match kind:
		"g13_hypno":
			var sp: Node3D = node.get_node_or_null("Spin")
			if sp != null:
				sp.rotation.z = t * 9.0 + seed
				var pulse: float = 1.0 + 0.12 * sin(t * 30.0 + seed * 2.3)
				sp.scale = Vector3(pulse, pulse, 1.0)
			return Vector3(sin(frac * PI * 3.0 + seed) * 0.05, sin(frac * PI) * 0.05, 0.0)
		"g13_petals":
			var ps: Node3D = node.get_node_or_null("Spin")
			if ps != null:
				ps.rotation.z = t * 11.0 + seed
			return Vector3(0.0, sin(frac * PI) * 0.22, 0.0)
	return Vector3.ZERO


static func release(fx: Fx, kind: String, at: Vector3, dir: Vector3) -> void:
	match kind:
		"g13_hypno":
			fx.soft_flash(at, HYP, 0.45, 0.16, 1.8)
			fx._ripple(at, dir, HYP2, 0.04, 0.26, 0.22, 0.7)
		"g13_petals":
			fx.soft_flash(at, ROSE2, 0.4, 0.16, 1.4)
			fx.burst(at, ROSE, 4, 0.9, 0.5, 0.5, 0.45, false)
			fx.burst(at, PINK, 3, 0.7, 0.45, 0.5, 0.4)
		_:
			fx.soft_flash(at, Color("#fff4dc"), 0.4, 0.15, 1.4)


static func hit(fx: Fx, kind: String, at: Vector3, dir: Vector3) -> void:
	match kind:
		"g13_hypno":
			# 一层层往外扩的螺旋波纹 + 几点星
			fx.soft_flash(at, HYP, 0.6, 0.2, 2.0)
			fx._ripple(at, dir, HYP2, 0.06, 0.45, 0.3, 0.8)
			fx._ripple(at, dir, HYP, 0.03, 0.3, 0.42, 0.6)
			fx.burst(at, STAR, 5, 1.4, 0.3, 0.6, 0.35)
			fx.burst(at, HYP2, 6, 1.6, 0.35, 0.5, 0.3)
		"g13_petals":
			# 一把花瓣散开 + 一圈粉光
			fx.soft_flash(at, ROSE2, 0.55, 0.2, 1.8)
			fx.burst(at, ROSE, 8, 1.6, 0.55, 0.8, 0.6, false)
			fx.burst(at, ROSE3, 4, 1.2, 0.5, 0.8, 0.6, false)
			fx.burst(at, PINK, 5, 1.4, 0.4, 0.7, 0.4)
			fx._ripple(at, dir, PINK, 0.05, 0.4, 0.3, 0.6)
		_:
			fx.burst(at, Color("#ffe6b0"), 5, 1.6, 0.8)


# ---------------------------------------------------------------- 弹体
static func _mi(mesh: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.position = pos
	m.rotation = rot
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


static func _torus(r_in: float, r_out: float) -> TorusMesh:
	var tm := TorusMesh.new()
	tm.inner_radius = r_in
	tm.outer_radius = r_out
	tm.rings = 16
	tm.ring_segments = 6
	return tm


static func _sphere(r: float, segs: int = 8) -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = segs
	sm.rings = maxi(3, segs / 2)
	return sm


static func _boxm(s: Vector3) -> BoxMesh:
	var bm := BoxMesh.new()
	bm.size = s
	return bm


static func _ribbon(fx: Fx, root: Node3D, c: Color, w: float, life: float) -> void:
	var rib: RibbonTrail = RibbonTrail.create(root, c, w, life)
	rib.time_scale = maxf(0.2, fx.speed_scale)
	root.add_child(rib)


static func _bits(fx: Fx, amount: int, life: float, col: Color, energy: float, grav: Vector3, scale: float) -> GPUParticles3D:
	var sp := GPUParticles3D.new()
	var spm := ParticleProcessMaterial.new()
	spm.direction = Vector3(0, 1, 0)
	spm.spread = 70.0
	spm.initial_velocity_min = 0.15
	spm.initial_velocity_max = 0.5
	spm.gravity = grav
	spm.scale_min = scale * 0.5
	spm.scale_max = scale
	sp.process_material = spm
	sp.draw_pass_1 = fx._box
	sp.material_override = fx._emissive(col, energy) if energy > 0.0 else fx._solid(col)
	sp.amount = amount
	sp.lifetime = life
	sp.local_coords = false
	sp.emitting = true
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sp.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
	return sp


## 催眠波纹：两圈套着的紫色光环(圆环面朝飞行方向)，中间一点亮芯；Spin 绕飞行轴转、一胀一缩；外面一层淡紫的光，身后拖一道紫光带
static func _hypno(fx: Fx, root: Node3D) -> void:
	var spin := Node3D.new()
	spin.name = "Spin"
	root.add_child(spin)
	# TorusMesh 的轴是 Y：转 90° 让圆环面朝 -Z(飞行方向)
	spin.add_child(_mi(_torus(0.07, 0.095), fx._emissive(HYP, 2.6), Vector3.ZERO, Vector3(PI * 0.5, 0, 0)))
	spin.add_child(_mi(_torus(0.03, 0.05), fx._emissive(HYP2, 3.0), Vector3(0, 0, 0.04), Vector3(PI * 0.5, 0, 0)))
	# 螺旋的"臂"：四小块绕着圈排开(转起来像螺旋盘)
	for k in range(4):
		var a: float = TAU * float(k) / 4.0
		spin.add_child(_mi(_boxm(Vector3(0.05, 0.016, 0.012)), fx._emissive(HYP3 if k % 2 == 0 else HYP2, 2.2),
			Vector3(cos(a) * 0.06, sin(a) * 0.06, 0.02), Vector3(0, 0, a + 0.9)))
	spin.add_child(_mi(_sphere(0.022, 8), fx._emissive(STAR, 4.0)))
	root.add_child(_mi(SoftFX.quad(0.36), SoftFX.sprite_mat(HYP, 1.2)))
	_ribbon(fx, root, HYP2, 0.06, 0.14)
	root.scale = Vector3.ONE * 1.6


## 玫瑰花瓣：五片椭圆的花瓣(压扁的球，深浅不一的红)绕飞行轴排成一小圈，中间一点粉光；身后飘几片粉瓣
static func _petals(fx: Fx, root: Node3D) -> void:
	var spin := Node3D.new()
	spin.name = "Spin"
	root.add_child(spin)
	var cols: Array = [ROSE, ROSE2, ROSE3, ROSE, ROSE2]
	for k in range(5):
		var a: float = TAU * float(k) / 5.0
		var pm := _mi(_sphere(0.04, 8), fx._emissive(cols[k], 1.2), Vector3(cos(a) * 0.055, sin(a) * 0.055, 0.015 * float(k % 2)),
			Vector3(0.0, 0.0, a))
		pm.scale = Vector3(1.0, 0.55, 0.25)
		spin.add_child(pm)
	spin.add_child(_mi(_sphere(0.025, 8), fx._emissive(PINK, 2.4)))
	# 一片小绿叶(在后)
	spin.add_child(_mi(_boxm(Vector3(0.05, 0.016, 0.006)), fx._solid(LEAF), Vector3(0.0, -0.07, 0.04), Vector3(0, 0, 0.5)))
	root.add_child(_mi(SoftFX.quad(0.28), SoftFX.sprite_mat(ROSE2, 0.9)))
	root.add_child(_bits(fx, 8, 0.6, PINK, 1.0, Vector3(0, -0.8, 0), 0.35))
	_ribbon(fx, root, PINK, 0.05, 0.16)
	root.scale = Vector3.ONE * 1.7
