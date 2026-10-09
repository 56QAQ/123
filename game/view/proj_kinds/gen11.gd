extends RefCounted
## 通用武器 · gen11(步枪 / 手弩)的投射物(ProjRegistry 登记；接口见 game/view/proj_registry.gd)。
##   g11_ink_drop       蓝墨钢笔枪：一团蓝墨水(前圆后尖、一胀一缩，白色高光)，身后拖一道墨痕、往下滴墨点；出手枪口溅一小团墨，命中"啪"地洇开一圈墨渍
##   g11_flame_feather  朱雀步枪：一片燃着的羽毛(金色的羽轴 + 朱红 / 橙色的羽片，飘着翻动)，身后拖一道火光、掉火星；出手一团火光，命中炸开火星 + 几片飘落的羽毛
##   g11_pearl          珍珠贝手弩：一颗珍珠(珠光白 + 青粉的晕彩光圈)，轻轻往上拱；出手一闪珠光，命中碎成一把亮晶晶的碎光 + 一圈青色的光环
##   g11_chili          朝天椒手弩：一只红辣椒(青蒂，翻着跟头)，往上拱，身后飘几点火星和一缕热气；命中一团辣椒红的呛人烟雾 + 火星
##   g11_dandelion      蒲公英手弩：一朵蒲公英绒伞(白色冠毛 + 细柄 + 褐色的种子)，慢慢飘过去、左右晃；命中散开一大把飘着的白绒
## 弹体的 -Z = 飞行方向(BattleView 用 look_at 对准目标)。步枪的出手点是扳机那只手：出手特效往前挪到枪口(RIFLE_MUZZLE 米)。

const KINDS: Array[String] = ["g11_ink_drop", "g11_flame_feather", "g11_pearl", "g11_chili", "g11_dandelion"]
## 近战武器的刀光(这一批没有近战)
const TRAILS := {}

const INK := Color("#2f5cff")
const INK_DEEP := Color("#16248a")
const INK_LIGHT := Color("#9ab4ff")
const FIRE := Color("#ff6a1f")
const FIRE_HOT := Color("#ffd060")
const VERMILION := Color("#e2381e")
const GOLD := Color("#f2c24a")
const PEARL := Color("#fbf8ef")
const NACRE_CY := Color("#8fe3dc")
const NACRE_PK := Color("#f3c7e0")
const CHILI := Color("#e0281a")
const CHILI_DARK := Color("#8d150c")
const STEM := Color("#4a9a30")
const SPICE := Color("#ff7a3a")
const FLUFF := Color("#f6f6ee")
const FLUFF_DIM := Color("#d8d8c8")
const SEED := Color("#7a5a30")
const RIFLE_MUZZLE := 0.45


static func make(fx: Fx, kind: String, heal: bool, _color: Color) -> Node3D:
	var root := Node3D.new()
	match kind:
		"g11_ink_drop":
			_ink_drop(fx, root, heal)
		"g11_flame_feather":
			_flame_feather(fx, root)
		"g11_pearl":
			_pearl(fx, root)
		"g11_chili":
			_chili(fx, root)
		"g11_dandelion":
			_dandelion(fx, root)
	return root


static func fly(node: Node3D, kind: String, frac: float, t: float, seed: float) -> Vector3:
	match kind:
		"g11_ink_drop":
			# 墨团：几乎直线；一胀一缩
			var wb: Node3D = node.get_node_or_null("Wobble")
			if wb != null:
				var sq: float = sin(t * 26.0 + seed * 1.3) * 0.12
				wb.scale = Vector3(1.0 - sq, 1.0 + sq, 1.0 + sq * 0.5)
			return Vector3(0.0, sin(frac * PI) * 0.06, 0.0)
		"g11_flame_feather":
			# 羽毛：绕飞行方向慢慢翻动、左右飘一点
			var fe: Node3D = node.get_node_or_null("Flutter")
			if fe != null:
				fe.rotation.z = sin(t * 9.0 + seed) * 0.9
				fe.rotation.x = sin(t * 13.0 + seed * 2.0) * 0.25
			return Vector3(sin(frac * PI * 2.0 + seed) * 0.08, sin(frac * PI) * 0.1, 0.0)
		"g11_pearl":
			var hl: Node3D = node.get_node_or_null("Halo")
			if hl != null:
				hl.scale = Vector3.ONE * (1.0 + 0.15 * sin(t * 20.0 + seed))
				hl.rotation.z = t * 3.0
			return Vector3(0.0, sin(frac * PI) * 0.14, 0.0)
		"g11_chili":
			var sp: Node3D = node.get_node_or_null("Spin")
			if sp != null:
				sp.rotation.x = t * 16.0 + seed
			return Vector3(0.0, sin(frac * PI) * 0.22, 0.0)
		"g11_dandelion":
			# 绒伞：慢慢飘、左右晃、上下浮
			var sw: Node3D = node.get_node_or_null("Sway")
			if sw != null:
				sw.rotation.z = sin(t * 5.0 + seed) * 0.35
			var side: float = 1.0 if int(seed) % 2 == 0 else -1.0
			return Vector3(side * sin(frac * PI) * 0.18 + sin(t * 6.0 + seed) * 0.04, sin(frac * PI) * 0.3 + sin(t * 4.0 + seed) * 0.03, 0.0)
	return Vector3.ZERO


static func release(fx: Fx, kind: String, at: Vector3, dir: Vector3) -> void:
	match kind:
		"g11_ink_drop":
			var mz: Vector3 = at + dir * RIFLE_MUZZLE
			fx.soft_flash(mz, INK_LIGHT, 0.32, 0.14, 1.2)
			fx.burst(mz + dir * 0.05, INK, 6, 1.4, 0.45, 0.4, 0.3, false)
			fx.burst(mz, INK_DEEP, 3, 0.9, 0.35, 0.2, 0.35, false)
		"g11_flame_feather":
			var mz2: Vector3 = at + dir * RIFLE_MUZZLE
			fx.soft_flash(mz2, FIRE_HOT, 0.5, 0.16, 2.0)
			fx.fire_puff(mz2, FIRE, 6, 0.28, 1.0, 0.4, 0.8)
			fx.burst(mz2 + dir * 0.06, FIRE_HOT, 5, 1.8, 0.35, 0.8, 0.3)
		"g11_pearl":
			fx.soft_flash(at, NACRE_CY, 0.4, 0.16, 1.5)
			fx.burst(at, PEARL, 5, 1.0, 0.35, 0.6, 0.3)
		"g11_chili":
			fx.soft_flash(at, SPICE, 0.35, 0.14, 1.4)
			fx.burst(at + dir * 0.05, CHILI, 4, 1.2, 0.4, 0.6, 0.3)
		"g11_dandelion":
			fx.soft_flash(at, FLUFF, 0.3, 0.16, 1.0)
			fx.burst(at, FLUFF, 6, 0.6, 0.35, 0.6, 0.6, false)


static func hit(fx: Fx, kind: String, at: Vector3, dir: Vector3) -> void:
	match kind:
		"g11_ink_drop":
			# 墨渍：一圈很快洇开的墨环 + 四溅的墨点(往下落)
			fx.soft_flash(at, INK_LIGHT, 0.5, 0.16, 1.4)
			fx._ripple(at, dir, INK, 0.1, 0.5, 0.3, 0.85)
			fx._ripple(at, Vector3.UP, INK_DEEP, 0.08, 0.4, 0.35, 0.6)
			fx.burst(at, INK, 10, 2.0, 0.5, 0.5, 0.45, false)
			fx.burst(at, INK_DEEP, 5, 1.4, 0.45, 0.2, 0.5, false)
		"g11_flame_feather":
			# 一团火 + 四溅的火星 + 两三片飘落的金色羽屑
			fx.soft_flash(at, FIRE, 0.6, 0.2, 2.0)
			fx.fire_puff(at, FIRE, 9, 0.3, 1.2, 0.45, 1.0)
			fx.burst(at, FIRE_HOT, 8, 2.8, 0.4, 0.8, 0.4)
			fx.burst(at, GOLD, 4, 1.0, 0.6, 0.6, 0.8, false)
		"g11_pearl":
			# 碎成一把亮晶晶的碎光 + 一圈青色的光环 + 一点粉色的晕彩
			fx.soft_flash(at, PEARL, 0.6, 0.18, 2.0)
			fx._ripple(at, dir, NACRE_CY, 0.1, 0.55, 0.3, 0.8)
			fx.burst(at, PEARL, 10, 2.4, 0.4, 0.6, 0.35)
			fx.burst(at, NACRE_PK, 5, 1.6, 0.35, 0.7, 0.3)
		"g11_chili":
			# 一团辣椒红的呛人烟雾 + 火星 + 几块辣椒皮
			fx.soft_flash(at, SPICE, 0.5, 0.18, 1.6)
			fx.fire_puff(at, SPICE, 8, 0.4, 0.8, 0.6, 0.5, false)
			fx.burst(at, FIRE_HOT, 6, 2.4, 0.35, 0.8, 0.3)
			fx.burst(at, CHILI, 5, 1.8, 0.5, 0.6, 0.45, false)
		"g11_dandelion":
			# 散开一大把慢慢飘的白绒
			fx.soft_flash(at, FLUFF, 0.45, 0.2, 1.2)
			fx.burst(at, FLUFF, 14, 1.0, 0.4, 1.0, 1.1, false)
			fx.burst(at, FLUFF_DIM, 6, 0.7, 0.35, 0.8, 0.9, false)
			fx._ripple(at, dir, FLUFF, 0.08, 0.45, 0.35, 0.5)


# ---------------------------------------------------------------- 弹体
static func _mi(mesh: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.position = pos
	m.rotation = rot
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


static func _sphere(r: float, segs: int = 10) -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = segs
	sm.rings = maxi(3, int(segs / 2.0))
	return sm


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


static func _ribbon(fx: Fx, root: Node3D, col: Color, w: float, life: float) -> void:
	var rib: RibbonTrail = RibbonTrail.create(root, col, w, life)
	rib.time_scale = maxf(0.2, fx.speed_scale)
	root.add_child(rib)


## 往下掉的小方块(墨点 / 火星 / 白绒)
static func _bits(fx: Fx, amount: int, life: float, col: Color, energy: float, grav: Vector3, scale: float) -> GPUParticles3D:
	var sp := GPUParticles3D.new()
	var spm := ParticleProcessMaterial.new()
	spm.direction = Vector3(0, 1, 0)
	spm.spread = 70.0
	spm.initial_velocity_min = 0.15
	spm.initial_velocity_max = 0.6
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


## 墨团：前圆后尖的深蓝墨水(Wobble 一胀一缩) + 白色高光；身后一道墨痕、往下滴墨点
static func _ink_drop(fx: Fx, root: Node3D, heal: bool) -> void:
	var wob := Node3D.new()
	wob.name = "Wobble"
	root.add_child(wob)
	var col: Color = INK_LIGHT if heal else INK
	wob.add_child(_mi(_sphere(0.075, 12), fx._emissive(col, 1.5, 0.95)))
	wob.add_child(_mi(_cone(0.065, 0.17, 10), fx._emissive(col, 1.3, 0.9), Vector3(0, 0, 0.08), Vector3(PI * 0.5, 0, 0)))
	wob.add_child(_mi(_sphere(0.045, 8), fx._emissive(INK_DEEP, 1.0)))
	wob.add_child(_mi(_sphere(0.018, 6), fx._emissive(Color.WHITE, 2.2, 0.9), Vector3(-0.03, 0.045, -0.035)))
	_ribbon(fx, root, INK, 0.06, 0.16)
	root.add_child(_bits(fx, 9, 0.5, INK_DEEP, 0.0, Vector3(0, -3.5, 0), 0.35))


## 燃着的羽毛：金色羽轴 + 两侧朱红的羽片(越往尾越宽)、橙色的焰梢；Flutter 慢慢翻动；身后一道火光 + 火星
static func _flame_feather(fx: Fx, root: Node3D) -> void:
	var fe := Node3D.new()
	fe.name = "Flutter"
	root.add_child(fe)
	fe.add_child(_mi(_boxm(Vector3(0.012, 0.012, 0.34)), fx._emissive(GOLD, 2.4), Vector3(0, 0, 0.02)))
	var vane: StandardMaterial3D = fx._emissive(VERMILION, 2.0)
	var tip: StandardMaterial3D = fx._emissive(FIRE_HOT, 3.0)
	for i in range(5):
		var z: float = -0.12 + float(i) * 0.06
		var w: float = 0.03 + float(i) * 0.012
		for s: float in [-1.0, 1.0]:
			fe.add_child(_mi(_boxm(Vector3(w, 0.008, 0.05)), vane if i < 4 else tip, Vector3(s * (w * 0.5 + 0.006), 0, z), Vector3(0, s * 0.35, 0)))
	fe.add_child(_mi(_boxm(Vector3(0.05, 0.008, 0.05)), tip, Vector3(0, 0, -0.16), Vector3(0, PI * 0.25, 0)))
	root.add_child(_mi(SoftFX.quad(0.42), SoftFX.sprite_mat(FIRE, 1.6)))
	root.add_child(_bits(fx, 12, 0.45, FIRE_HOT, 3.0, Vector3(0, -1.5, 0), 0.35))
	_ribbon(fx, root, FIRE, 0.07, 0.2)
	root.scale = Vector3.ONE * 1.2


## 珍珠：珠光白的球 + 一圈青 / 粉交替的晕彩光点(Halo，转着、一胀一缩) + 一道浅青的光带
static func _pearl(fx: Fx, root: Node3D) -> void:
	root.add_child(_mi(_sphere(0.06, 14), fx._emissive(PEARL, 1.4)))
	root.add_child(_mi(_sphere(0.02, 6), fx._emissive(Color.WHITE, 2.6, 0.9), Vector3(-0.022, 0.03, -0.025)))
	var halo := Node3D.new()
	halo.name = "Halo"
	root.add_child(halo)
	halo.add_child(_mi(SoftFX.quad(0.3), SoftFX.sprite_mat(NACRE_CY, 1.1)))
	for i in range(6):
		var a: float = TAU * float(i) / 6.0
		halo.add_child(_mi(_sphere(0.012, 4), fx._emissive(NACRE_CY if i % 2 == 0 else NACRE_PK, 2.4), Vector3(cos(a) * 0.1, sin(a) * 0.1, 0)))
	_ribbon(fx, root, NACRE_CY, 0.05, 0.16)


## 红辣椒：弯弯的辣椒(粗的一头一个青蒂，尖头朝前)，翻着跟头(Spin)；身后飘火星 + 一缕热气
static func _chili(fx: Fx, root: Node3D) -> void:
	var spin := Node3D.new()
	spin.name = "Spin"
	root.add_child(spin)
	var red: StandardMaterial3D = fx._emissive(CHILI, 1.2)
	spin.add_child(_mi(_cone(0.045, 0.2, 8), red, Vector3(0, 0, -0.06), Vector3(-PI * 0.5, 0, 0)))
	spin.add_child(_mi(_sphere(0.045, 8), red, Vector3(0, 0, 0.04)))
	spin.add_child(_mi(_cone(0.012, 0.05, 4), fx._emissive(SPICE, 2.2), Vector3(0, 0.01, -0.17), Vector3(-PI * 0.5 + 0.3, 0, 0)))
	spin.add_child(_mi(_boxm(Vector3(0.06, 0.02, 0.025)), fx._solid(STEM), Vector3(0, 0, 0.085)))
	spin.add_child(_mi(_boxm(Vector3(0.012, 0.012, 0.05)), fx._solid(STEM), Vector3(0, 0.01, 0.115), Vector3(0.5, 0, 0)))
	root.add_child(_bits(fx, 8, 0.45, FIRE_HOT, 2.6, Vector3(0, 0.6, 0), 0.3))
	_ribbon(fx, root, SPICE, 0.04, 0.14)
	root.scale = Vector3.ONE * 1.35


## 蒲公英绒伞：Sway 下面一圈白色的冠毛(往外散开的细刺) + 细柄 + 褐色的种子(朝前)；身后飘几点白绒
static func _dandelion(fx: Fx, root: Node3D) -> void:
	var sw := Node3D.new()
	sw.name = "Sway"
	root.add_child(sw)
	var fl: StandardMaterial3D = fx._emissive(FLUFF, 1.3, 0.9)
	sw.add_child(_mi(_sphere(0.022, 6), fl, Vector3(0, 0, 0.06)))
	for i in range(10):
		var a: float = TAU * float(i) / 10.0
		var d := Vector3(cos(a), sin(a), 0.35).normalized()
		var hair := _mi(_boxm(Vector3(0.006, 0.006, 0.09)), fl)
		hair.position = Vector3(0, 0, 0.06) + d * 0.045
		hair.basis = Basis(Quaternion(Vector3(0, 0, 1), d))
		sw.add_child(hair)
		sw.add_child(_mi(_sphere(0.008, 4), fl, Vector3(0, 0, 0.06) + d * 0.09))
	sw.add_child(_mi(_boxm(Vector3(0.006, 0.006, 0.09)), fx._solid(FLUFF_DIM), Vector3(0, 0, 0.0)))
	sw.add_child(_mi(_sphere(0.014, 6), fx._solid(SEED), Vector3(0, 0, -0.05)))
	root.add_child(_mi(SoftFX.quad(0.26), SoftFX.sprite_mat(FLUFF, 0.7)))
	root.add_child(_bits(fx, 6, 0.8, FLUFF, 1.2, Vector3(0, -0.3, 0), 0.25))
	root.scale = Vector3.ONE * 1.5
