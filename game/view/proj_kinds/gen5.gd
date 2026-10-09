extends RefCounted
## 通用武器 · gen5(手弩)的投射物(ProjRegistry 登记；接口见 game/view/proj_registry.gd)。
##   g5_ice_shard   霜棱手弩：一枚淡紫的冰棱(两头尖的晶体，绕自身的轴转)，拖一缕寒雾；出手一团冷光，命中碎成冰屑 + 一圈霜环
##   g5_flare       救难信号弩：一发信号弹(白热的芯 + 橙红的光晕，忽明忽暗)，往上拱着飞、一路掉火星、拖一道烟；命中炸开一团火
##   g5_spark_bolt  雷鸣手弩：一道电弩箭(白热的芯 + 绕着它乱跳的电弧)，几乎直线；出手迸电火花，命中炸开 + 几道往外的小闪电
##   g5_bee         蜂巢手弩：一只小蜜蜂(黄黑条纹、翅膀扑扇)，左右绕着飞过去，身后飘一点花粉；命中一团花粉(打队友时落几滴蜂蜜)
##   g5_seed        荆棘手弩：一颗带叶的刺种子(翻着跟头)，往上拱一点，身后飘落叶；命中崩出一把叶子和木屑
## 弹体的 -Z = 飞行方向(BattleView 用 look_at 对准目标)。

const KINDS: Array[String] = ["g5_ice_shard", "g5_flare", "g5_spark_bolt", "g5_bee", "g5_seed"]

const ICE := Color("#c4b2ff")
const ICE_CORE := Color("#f4f0ff")
const ICE_MIST := Color("#ddd4ff")
const FLARE := Color("#ff5326")
const FLARE_HOT := Color("#ffd27a")
const SMOKE := Color("#8d8a90")
const SPARK := Color("#ffd23a")
const SPARK_CORE := Color("#fffbe0")
const BEE_Y := Color("#f4c443")
const BEE_K := Color("#231c15")
const POLLEN := Color("#ffd75a")
const HONEY := Color("#f6a623")
const SEED := Color("#4a3a1c")
const SEED2 := Color("#b07a40")
const LEAF := Color("#6cc24f")
const LEAF2 := Color("#3f8c3a")


static func make(fx: Fx, kind: String, heal: bool, _color: Color) -> Node3D:
	var root := Node3D.new()
	match kind:
		"g5_ice_shard":
			_ice_shard(fx, root)
		"g5_flare":
			_flare(fx, root)
		"g5_spark_bolt":
			_spark_bolt(fx, root)
		"g5_bee":
			_bee(fx, root, heal)
		"g5_seed":
			_seed(fx, root)
	return root


static func fly(node: Node3D, kind: String, frac: float, t: float, seed: float) -> Vector3:
	match kind:
		"g5_ice_shard":
			var sp: Node3D = node.get_node_or_null("Spin")
			if sp != null:
				sp.rotation.z = t * 14.0 + seed
			return Vector3(0.0, sin(frac * PI) * 0.06, 0.0)
		"g5_flare":
			# 信号弹：往上拱得高一点；光晕忽明忽暗
			var hl: Node3D = node.get_node_or_null("Halo")
			if hl != null:
				hl.scale = Vector3.ONE * (1.0 + 0.18 * sin(t * 37.0 + seed * 2.3))
			return Vector3(0.0, sin(frac * PI) * 0.32, 0.0)
		"g5_spark_bolt":
			# 电弧每一帧重新抖一下(位置跟着战斗时间变)
			var arc: Node3D = node.get_node_or_null("Arc")
			if arc != null:
				var i := 0
				for c: Node in arc.get_children():
					var m: Node3D = c as Node3D
					var ph: float = floor(t * 30.0) * 1.7 + float(i) * 2.9 + seed
					m.position = Vector3(sin(ph) * 0.05, cos(ph * 1.3) * 0.05, -0.15 + 0.3 * float(i) / 5.0)
					m.rotation = Vector3(sin(ph * 0.7) * 1.2, 0.0, cos(ph) * 1.5)
					i += 1
			return Vector3(0.0, sin(frac * PI) * 0.03, 0.0)
		"g5_bee":
			# 蜜蜂：左右绕着飞(每一只的相位不同)，上下点几下；翅膀扑扇
			var bee: Node3D = node.get_node_or_null("Bee")
			if bee != null:
				var wl: Node3D = bee.get_node_or_null("WingL")
				var wr: Node3D = bee.get_node_or_null("WingR")
				var flap: float = sin(t * 70.0 + seed) * 0.9
				if wl != null:
					wl.rotation.z = 0.35 + flap
				if wr != null:
					wr.rotation.z = -0.35 - flap
			var side: float = 1.0 if int(seed) % 2 == 0 else -1.0
			return Vector3(side * sin(frac * PI * 2.0) * 0.22, sin(frac * PI) * 0.18 + sin(t * 16.0 + seed) * 0.03, 0.0)
		"g5_seed":
			var ss: Node3D = node.get_node_or_null("Spin")
			if ss != null:
				ss.rotation.x = t * 15.0 + seed
			return Vector3(0.0, sin(frac * PI) * 0.2, 0.0)
	return Vector3.ZERO


static func release(fx: Fx, kind: String, at: Vector3, dir: Vector3) -> void:
	match kind:
		"g5_ice_shard":
			fx.soft_flash(at, ICE, 0.45, 0.18, 1.6)
			fx.burst(at + dir * 0.05, ICE_CORE, 5, 1.2, 0.45, 0.6, 0.3)
			fx.fire_puff(at, ICE_MIST, 5, 0.3, 0.6, 0.45, 0.2, false)
		"g5_flare":
			fx.soft_flash(at, FLARE_HOT, 0.6, 0.18, 2.0)
			fx.burst(at + dir * 0.08, FLARE_HOT, 7, 2.0, 0.45, 0.9, 0.3)
			fx.fire_puff(at, SMOKE, 6, 0.35, 0.7, 0.7, 0.5, false)
		"g5_spark_bolt":
			fx.soft_flash(at, SPARK, 0.5, 0.14, 2.0)
			fx.burst(at + dir * 0.05, SPARK_CORE, 6, 2.8, 0.35, 0.4, 0.18)
			for i in range(2):
				var d: Vector3 = (dir + Vector3(randf_range(-0.8, 0.8), randf_range(-0.3, 0.6), randf_range(-0.8, 0.8))).normalized()
				LightningArc.create(fx, at, at + d * 0.32, 0.0, 0.16, 0.03, 3)
		"g5_bee":
			fx.soft_flash(at, POLLEN, 0.35, 0.16, 1.4)
			fx.burst(at, POLLEN, 4, 0.8, 0.4, 0.7, 0.35)
		"g5_seed":
			fx.soft_flash(at, LEAF, 0.35, 0.16, 1.2)
			fx.burst(at + dir * 0.05, LEAF, 5, 1.2, 0.55, 0.8, 0.45, false)
		_:
			fx.soft_flash(at, Color("#fff4dc"), 0.4, 0.15, 1.4)


static func hit(fx: Fx, kind: String, at: Vector3, dir: Vector3) -> void:
	match kind:
		"g5_ice_shard":
			# 碎成一把冰屑(顺着飞来的方向崩) + 一圈霜环 + 一点寒雾
			fx.soft_flash(at, ICE, 0.6, 0.2, 1.8)
			fx.burst(at + dir * 0.05, ICE, 10, 2.6, 0.5, 0.5, 0.45)
			fx.burst(at, ICE_CORE, 4, 1.8, 0.35, 0.8, 0.3)
			fx._ripple(at, dir, ICE, 0.08, 0.5, 0.3, 0.7)
			fx.fire_puff(at, ICE_MIST, 7, 0.4, 0.7, 0.6, 0.15, false)
		"g5_flare":
			# 一团火 + 四溅的火星 + 一点烟
			fx.soft_flash(at, FLARE, 0.55, 0.2, 1.8)
			fx.fire_puff(at, FLARE, 9, 0.32, 1.3, 0.45, 1.0)
			fx.burst(at, FLARE, 8, 3.0, 0.45, 0.8, 0.45)
			fx.burst(at, FLARE_HOT, 5, 2.4, 0.35, 0.9, 0.35)
			fx.fire_puff(at + Vector3(0, 0.15, 0), SMOKE, 6, 0.45, 0.6, 0.9, 0.6, false)
		"g5_spark_bolt":
			# 炸开一团电光 + 几道往外的小闪电
			fx.soft_flash(at, SPARK, 0.7, 0.18, 2.4)
			fx.burst(at, SPARK, 10, 3.6, 0.4, 0.5, 0.25)
			fx.burst(at, SPARK_CORE, 4, 2.4, 0.3, 0.6, 0.18)
			for i in range(3):
				var d: Vector3 = (dir.normalized() + Vector3(randf_range(-0.9, 0.9), randf_range(-0.3, 0.7), randf_range(-0.9, 0.9))).normalized()
				LightningArc.create(fx, at, at + d * randf_range(0.35, 0.6), 0.0, 0.25, 0.04 if i == 0 else 0.03, 4)
		"g5_bee":
			# 一团花粉；打在队友身上(治疗)时多落几滴蜂蜜
			fx.soft_flash(at, POLLEN, 0.5, 0.18, 1.6)
			fx.burst(at, POLLEN, 9, 1.6, 0.4, 0.8, 0.5)
			fx.burst(at, HONEY, 4, 1.0, 0.5, 0.2, 0.5, false)
		"g5_seed":
			# 崩出一把叶子 + 几块木屑
			fx.soft_flash(at, LEAF, 0.45, 0.18, 1.4)
			fx.burst(at, LEAF, 9, 2.0, 0.6, 0.9, 0.6, false)
			fx.burst(at, LEAF2, 5, 1.6, 0.5, 0.7, 0.5, false)
			fx.burst(at, SEED2, 4, 2.2, 0.4, 0.5, 0.35, false)
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


static func _cone(r: float, h: float, segs: int) -> CylinderMesh:
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = segs
	cm.rings = 1
	return cm


static func _boxm(s: Vector3) -> BoxMesh:
	var bm := BoxMesh.new()
	bm.size = s
	return bm


static func _trail(amount: int, life: float, ramp: GradientTexture1D, size: float, additive: bool, grav: Vector3, vel: float) -> GPUParticles3D:
	var tr := SoftFX.particles(amount, life, ramp, size, additive)
	var pm: ParticleProcessMaterial = tr.process_material
	pm.direction = Vector3(0, 0.3, 0)
	pm.spread = 40.0
	pm.initial_velocity_min = vel * 0.3
	pm.initial_velocity_max = vel
	pm.gravity = grav
	tr.emitting = true
	return tr


static func _bits(fx: Fx, amount: int, life: float, col: Color, energy: float, grav: Vector3, scale: float) -> GPUParticles3D:
	var sp := GPUParticles3D.new()
	var spm := ParticleProcessMaterial.new()
	spm.direction = Vector3(0, 1, 0)
	spm.spread = 70.0
	spm.initial_velocity_min = 0.2
	spm.initial_velocity_max = 0.7
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


## 冰棱：前面一根长尖、后面一根短尖(四棱，像一块劈开的冰晶)，两侧各一片小碎晶；外面一层淡淡的冷光
static func _ice_shard(fx: Fx, root: Node3D) -> void:
	var spin := Node3D.new()
	spin.name = "Spin"
	root.add_child(spin)
	var body: StandardMaterial3D = fx._emissive(ICE, 1.6)
	var core: StandardMaterial3D = fx._emissive(ICE_CORE, 2.4)
	spin.add_child(_mi(_cone(0.055, 0.24, 4), body, Vector3(0, 0, -0.12), Vector3(-PI * 0.5, 0, 0)))
	spin.add_child(_mi(_cone(0.055, 0.09, 4), body, Vector3(0, 0, 0.045), Vector3(PI * 0.5, 0, 0)))
	spin.add_child(_mi(_cone(0.022, 0.2, 4), core, Vector3(0, 0, -0.1), Vector3(-PI * 0.5, 0, 0)))
	for s: float in [-1.0, 1.0]:
		spin.add_child(_mi(_cone(0.025, 0.1, 4), body, Vector3(0.045 * s, 0.02, -0.02), Vector3(-PI * 0.5, 0, -0.5 * s)))
	var halo := _mi(SoftFX.quad(0.38), SoftFX.sprite_mat(ICE, 1.2))
	root.add_child(halo)
	root.add_child(_trail(14, 0.4, SoftFX.ramp([Color(ICE_MIST.r, ICE_MIST.g, ICE_MIST.b, 0.0), Color(ICE_MIST.r, ICE_MIST.g, ICE_MIST.b, 0.55),
		Color(ICE.r, ICE.g, ICE.b, 0.0)], [0.0, 0.25, 1.0]), 0.16, false, Vector3(0, -0.4, 0), 0.25))
	var rib: RibbonTrail = RibbonTrail.create(root, ICE, 0.05, 0.16)
	rib.time_scale = maxf(0.2, fx.speed_scale)
	root.add_child(rib)
	root.scale = Vector3.ONE * 1.25


## 信号弹：白热的芯 + 橙红光晕(Halo，忽明忽暗)，一路往下掉火星，后面拖一道烟
static func _flare(fx: Fx, root: Node3D) -> void:
	var sm := SphereMesh.new()
	sm.radius = 0.055
	sm.height = 0.11
	sm.radial_segments = 10
	sm.rings = 5
	root.add_child(_mi(sm, fx._emissive(FLARE_HOT, 4.0)))
	var halo := Node3D.new()
	halo.name = "Halo"
	root.add_child(halo)
	halo.add_child(_mi(SoftFX.quad(0.55), SoftFX.sprite_mat(FLARE, 2.0)))
	halo.add_child(_mi(SoftFX.quad(0.26), SoftFX.sprite_mat(FLARE_HOT, 2.6)))
	root.add_child(_bits(fx, 12, 0.45, FLARE_HOT, 3.0, Vector3(0, -3.0, 0), 0.45))
	root.add_child(_trail(18, 0.6, SoftFX.ramp([Color(SMOKE.r, SMOKE.g, SMOKE.b, 0.0), Color(SMOKE.r, SMOKE.g, SMOKE.b, 0.5),
		Color(SMOKE.r, SMOKE.g, SMOKE.b, 0.0)], [0.0, 0.2, 1.0]), 0.22, false, Vector3(0, 0.5, 0), 0.2))
	var rib: RibbonTrail = RibbonTrail.create(root, FLARE, 0.07, 0.18)
	rib.time_scale = maxf(0.2, fx.speed_scale)
	root.add_child(rib)


## 电弩箭：白热的芯(沿飞行方向的细长胶囊) + 金色光晕 + 绕着它乱跳的几段电弧(Arc 的子节点，fly 每帧抖)
static func _spark_bolt(fx: Fx, root: Node3D) -> void:
	var cm := CapsuleMesh.new()
	cm.radius = 0.026
	cm.height = 0.32
	cm.radial_segments = 6
	cm.rings = 2
	root.add_child(_mi(cm, fx._emissive(SPARK_CORE, 4.0), Vector3.ZERO, Vector3(PI * 0.5, 0, 0)))
	root.add_child(_mi(SoftFX.quad(0.42), SoftFX.sprite_mat(SPARK, 1.8)))
	var arc := Node3D.new()
	arc.name = "Arc"
	root.add_child(arc)
	for i in range(5):
		arc.add_child(_mi(_boxm(Vector3(0.012, 0.012, 0.11)), fx._emissive(SPARK if i % 2 == 0 else SPARK_CORE, 3.2)))
	var rib: RibbonTrail = RibbonTrail.create(root, SPARK, 0.05, 0.14)
	rib.time_scale = maxf(0.2, fx.speed_scale)
	root.add_child(rib)
	root.scale = Vector3.ONE * 1.35


## 小蜜蜂：黄黑相间的身子(沿 Z)、黑脑袋、尾针，背上一对半透明的翅膀(WingL / WingR，fly 里扑扇)；身后飘一点花粉
static func _bee(fx: Fx, root: Node3D, _heal: bool) -> void:
	var bee := Node3D.new()
	bee.name = "Bee"
	root.add_child(bee)
	var yl: StandardMaterial3D = fx._emissive(BEE_Y, 1.2)
	var bk: StandardMaterial3D = fx._solid(BEE_K)
	bee.add_child(_mi(_boxm(Vector3(0.06, 0.06, 0.045)), bk, Vector3(0, 0, -0.07)))           # 头
	bee.add_child(_mi(_boxm(Vector3(0.075, 0.07, 0.04)), yl, Vector3(0, 0, -0.03)))
	bee.add_child(_mi(_boxm(Vector3(0.08, 0.075, 0.035)), bk, Vector3(0, 0, 0.005)))
	bee.add_child(_mi(_boxm(Vector3(0.075, 0.07, 0.035)), yl, Vector3(0, 0, 0.04)))
	bee.add_child(_mi(_boxm(Vector3(0.05, 0.05, 0.03)), bk, Vector3(0, 0, 0.07)))
	bee.add_child(_mi(_boxm(Vector3(0.012, 0.012, 0.03)), bk, Vector3(0, -0.005, 0.095)))     # 尾针
	var wm: StandardMaterial3D = fx._emissive(Color("#eef6ff"), 1.0, 0.6)
	for s: float in [-1.0, 1.0]:
		var w := Node3D.new()
		w.name = "WingL" if s < 0.0 else "WingR"
		w.position = Vector3(0.02 * s, 0.035, -0.01)
		bee.add_child(w)
		w.add_child(_mi(_boxm(Vector3(0.09, 0.006, 0.05)), wm, Vector3(0.045 * s, 0, 0.01)))
	root.add_child(_mi(SoftFX.quad(0.26), SoftFX.sprite_mat(POLLEN, 0.8)))
	root.add_child(_bits(fx, 8, 0.5, POLLEN, 2.2, Vector3(0, -0.6, 0), 0.3))
	root.scale = Vector3.ONE * 1.6


## 刺种子：一颗深色的刺果(圆圆的种荚，四面八方伸出浅色的尖刺)，后面拖一片叶子，翻着跟头(Spin)；身后飘几片落叶
static func _seed(fx: Fx, root: Node3D) -> void:
	var spin := Node3D.new()
	spin.name = "Spin"
	root.add_child(spin)
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	sm.radial_segments = 8
	sm.rings = 4
	spin.add_child(_mi(sm, fx._solid(SEED)))
	var thorn: StandardMaterial3D = fx._solid(Color("#e8dcb4"))
	for i in range(8):
		var th: float = TAU * float(i) / 8.0
		var tilt: float = 0.6 if i % 2 == 0 else -0.6
		var d := Vector3(cos(th), sin(th), tilt * 0.6).normalized()
		var sp := _mi(_cone(0.014, 0.06, 4), thorn, d * 0.06)
		spin.add_child(sp)
		sp.basis = Basis(Quaternion(Vector3.UP, d))
		sp.position = d * 0.065
	spin.add_child(_mi(_boxm(Vector3(0.1, 0.01, 0.06)), fx._emissive(LEAF, 0.9), Vector3(0.0, 0.0, 0.1), Vector3(0, 0.4, 0.2)))
	spin.add_child(_mi(_boxm(Vector3(0.012, 0.012, 0.05)), fx._solid(LEAF2), Vector3(0.0, 0.0, 0.065)))
	root.add_child(_bits(fx, 7, 0.6, LEAF, 0.0, Vector3(0, -1.2, 0), 0.5))
	var rib: RibbonTrail = RibbonTrail.create(root, LEAF.lightened(0.2), 0.035, 0.14)
	rib.time_scale = maxf(0.2, fx.speed_scale)
	root.add_child(rib)
	root.scale = Vector3.ONE * 1.4
