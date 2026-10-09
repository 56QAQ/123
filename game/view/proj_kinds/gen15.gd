extends RefCounted
## 通用武器 · gen15 的投射物与刀光(ProjRegistry 登记；接口见 game/view/proj_registry.gd)。
##   g15_spine    仙人掌双枪：一簇五根淡黄的仙人掌刺(尖朝前、尾部一点绿)，直直地飞；出手一小团绿色的尘，命中刺散开 + 几片粉花瓣
##   g15_glove    拳套弹簧枪：一只红拳套(白护腕)，身后拖一截一圈圈的弹簧；往前一冲一冲地飞；出手"嘣"的一圈白，命中一颗黄白的"POW"星爆
##   g15_magnet   磁极双枪：一圈半红半蓝的磁力环(绕飞行轴转)，中间一点白芯，外面两道淡淡的磁力线；命中红蓝两圈涟漪 + 火花
##   g15_mint     薄荷手弩：两片交叉的薄荷叶(嫩绿、中间一道深色叶脉)绕飞行轴打转，带一点清凉的白光、身后飘白色的凉气；
##                命中碎叶散开 + 一圈淡青白的"清凉"涟漪
## 弹体的 -Z = 飞行方向(BattleView 用 look_at 对准目标)。

const KINDS: Array[String] = ["g15_spine", "g15_glove", "g15_magnet", "g15_mint"]
## 近战武器的刀光(外观名 → {base, tip, life, energy, alpha, color}，刃根 / 刃尖是武器骨局部 +Y 的体素)；WeaponTrail 会查这里
const TRAILS := {
	# 心火双刃：红刃 6~27，火红
	"g15_heartfire": {"base": 7.0, "tip": 26.0, "life": 0.14, "energy": 1.3, "alpha": 0.78, "color": Color("#ff4a3a")},
	# 蝙蝠双刃：蝠翼刃 5~26，紫
	"g15_bat": {"base": 6.0, "tip": 25.0, "life": 0.13, "energy": 1.2, "alpha": 0.74, "color": Color("#b46cff")},
}

const SPINE := Color("#f4e7a6")
const CACT := Color("#4fae4a")
const CACT2 := Color("#9be07a")
const FLOWER := Color("#ff8fc0")
const GLOVE := Color("#e02828")
const GLOVE2 := Color("#ff6a5a")
const CUFF := Color("#f6f2ea")
const SPRING := Color("#c8ccd4")
const POW := Color("#fff1a0")
const MAG_R := Color("#ff3a4a")
const MAG_B := Color("#3a7cff")
const MAG_W := Color("#f2ecff")
const MINT := Color("#7ed36a")
const MINT2 := Color("#a8ec8a")
const MINT3 := Color("#4e9e44")
const COOL := Color("#d8fff4")


static func make(fx: Fx, kind: String, _heal: bool, _color: Color) -> Node3D:
	var root := Node3D.new()
	match kind:
		"g15_spine":
			_spine(fx, root)
		"g15_glove":
			_glove(fx, root)
		"g15_magnet":
			_magnet(fx, root)
		"g15_mint":
			_mint(fx, root)
	return root


static func fly(node: Node3D, kind: String, frac: float, t: float, seed: float) -> Vector3:
	match kind:
		"g15_spine":
			var ss: Node3D = node.get_node_or_null("Spin")
			if ss != null:
				ss.rotation.z = t * 14.0 + seed
			return Vector3(0.0, sin(frac * PI) * 0.06, 0.0)
		"g15_glove":
			# 一冲一冲：往前多走一点又收回来，弹簧跟着伸缩
			var sp: Node3D = node.get_node_or_null("Spring")
			var pump: float = sin(frac * PI * 4.0 + seed)
			if sp != null:
				sp.scale = Vector3(1.0, 1.0, 1.0 + 0.35 * pump)
			return Vector3(0.0, sin(frac * PI) * 0.08, pump * 0.06)
		"g15_magnet":
			var ms: Node3D = node.get_node_or_null("Spin")
			if ms != null:
				ms.rotation.z = t * 10.0 + seed
				var pulse: float = 1.0 + 0.1 * sin(t * 26.0 + seed * 1.7)
				ms.scale = Vector3(pulse, pulse, 1.0)
			return Vector3(sin(frac * PI * 2.0 + seed) * 0.04, sin(frac * PI) * 0.05, 0.0)
		"g15_mint":
			# 叶子绕飞行轴打转，路线微微往上拱、左右飘一点
			var ns: Node3D = node.get_node_or_null("Spin")
			if ns != null:
				ns.rotation.z = t * 12.0 + seed
			return Vector3(sin(frac * PI * 2.0 + seed) * 0.06, sin(frac * PI) * 0.18, 0.0)
	return Vector3.ZERO


static func release(fx: Fx, kind: String, at: Vector3, dir: Vector3) -> void:
	match kind:
		"g15_spine":
			fx.soft_flash(at, CACT2, 0.35, 0.14, 1.3)
			fx.burst(at, CACT, 4, 0.8, 0.4, 0.4, 0.35, false)
		"g15_glove":
			fx.soft_flash(at, CUFF, 0.45, 0.14, 1.6)
			fx._ripple(at, dir, CUFF, 0.04, 0.24, 0.18, 0.6)
		"g15_magnet":
			fx.soft_flash(at, MAG_W, 0.4, 0.15, 1.6)
			fx._ripple(at, dir, MAG_R, 0.03, 0.2, 0.2, 0.6)
			fx._ripple(at, dir, MAG_B, 0.05, 0.26, 0.22, 0.6)
		"g15_mint":
			fx.soft_flash(at, COOL, 0.35, 0.16, 1.5)
			fx.burst(at, MINT, 3, 0.6, 0.45, 0.4, 0.35, false)
		_:
			fx.soft_flash(at, Color("#fff4dc"), 0.4, 0.15, 1.4)


static func hit(fx: Fx, kind: String, at: Vector3, dir: Vector3) -> void:
	match kind:
		"g15_spine":
			# 刺散开 + 几片粉花瓣
			fx.soft_flash(at, CACT2, 0.45, 0.16, 1.5)
			fx.burst(at, SPINE, 7, 1.8, 0.35, 0.5, 0.3, false)
			fx.burst(at, CACT, 4, 1.2, 0.4, 0.6, 0.4, false)
			fx.burst(at, FLOWER, 3, 1.0, 0.5, 0.6, 0.35)
		"g15_glove":
			# "POW"：一颗黄白的星爆 + 红光
			fx.soft_flash(at, POW, 0.45, 0.14, 1.6)
			fx.soft_flash(at, GLOVE2, 0.35, 0.2, 1.2)
			fx._ripple(at, dir, POW, 0.05, 0.42, 0.22, 0.8)
			fx.burst(at, POW, 8, 2.2, 0.3, 0.5, 0.35)
			fx.burst(at, GLOVE, 3, 1.0, 0.35, 0.5, 0.3, false)
		"g15_magnet":
			# 红蓝两圈涟漪 + 火花
			fx.soft_flash(at, MAG_W, 0.55, 0.2, 2.0)
			fx._ripple(at, dir, MAG_R, 0.05, 0.4, 0.3, 0.7)
			fx._ripple(at, dir, MAG_B, 0.03, 0.3, 0.4, 0.7)
			fx.burst(at, MAG_W, 6, 1.8, 0.3, 0.5, 0.3)
			fx.burst(at, MAG_R, 3, 1.2, 0.3, 0.5, 0.3)
			fx.burst(at, MAG_B, 3, 1.2, 0.3, 0.5, 0.3)
		"g15_mint":
			# 碎叶散开 + 一圈清凉的涟漪 + 几点白
			fx.soft_flash(at, COOL, 0.55, 0.2, 1.8)
			fx.burst(at, MINT, 7, 1.4, 0.5, 0.7, 0.45, false)
			fx.burst(at, MINT2, 4, 1.0, 0.5, 0.7, 0.4, false)
			fx.burst(at, COOL, 6, 1.2, 0.5, 0.8, 0.3)
			fx._ripple(at, dir, COOL, 0.05, 0.4, 0.32, 0.6)
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


static func _cone(r: float, h: float) -> CylinderMesh:
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 6
	cm.rings = 1
	return cm


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


## 仙人掌刺：五根细长的淡黄刺(圆锥，尖朝 -Z)排成一小簇，尾部一小截绿色的刺座；整簇绕飞行轴慢慢转
static func _spine(fx: Fx, root: Node3D) -> void:
	var spin := Node3D.new()
	spin.name = "Spin"
	root.add_child(spin)
	var offs: Array = [Vector2(0, 0), Vector2(0.03, 0.018), Vector2(-0.03, 0.018), Vector2(0.018, -0.028), Vector2(-0.018, -0.028)]
	for k in range(offs.size()):
		var o: Vector2 = offs[k]
		var back: float = 0.0 if k == 0 else 0.03
		# CylinderMesh 的轴是 Y、尖在 +Y：转 -90° 让尖朝 -Z
		spin.add_child(_mi(_cone(0.009, 0.16), fx._emissive(SPINE, 1.4), Vector3(o.x, o.y, back), Vector3(-PI * 0.5, 0, 0)))
		spin.add_child(_mi(_boxm(Vector3(0.016, 0.016, 0.03)), fx._solid(CACT), Vector3(o.x, o.y, back + 0.085)))
	root.add_child(_mi(SoftFX.quad(0.2), SoftFX.sprite_mat(CACT2, 0.6)))
	_ribbon(fx, root, SPINE, 0.035, 0.1)
	root.scale = Vector3.ONE * 1.9


## 拳套：一只红拳套(压扁的大球 = 拳面、侧面一小块拇指)，后面一圈白护腕，再往后一截一圈圈的银弹簧(Spring 节点，飞的时候伸缩)
static func _glove(fx: Fx, root: Node3D) -> void:
	var fist := _mi(_sphere(0.075, 10), fx._emissive(GLOVE, 0.9))
	fist.scale = Vector3(1.0, 0.85, 1.05)
	root.add_child(fist)
	root.add_child(_mi(_sphere(0.04, 8), fx._emissive(GLOVE2, 1.0), Vector3(-0.012, 0.03, -0.035)))       # 拳面的高光
	var thumb := _mi(_sphere(0.032, 8), fx._emissive(GLOVE, 0.9), Vector3(0.068, -0.01, -0.01))
	thumb.scale = Vector3(0.8, 1.0, 1.4)
	root.add_child(thumb)
	root.add_child(_mi(_torus(0.045, 0.07), fx._solid(CUFF), Vector3(0, 0, 0.07), Vector3(PI * 0.5, 0, 0)))
	var spring := Node3D.new()
	spring.name = "Spring"
	spring.position = Vector3(0, 0, 0.09)
	root.add_child(spring)
	for k in range(5):
		spring.add_child(_mi(_torus(0.02, 0.032), fx._emissive(SPRING, 0.6), Vector3(0, 0, 0.03 * float(k)), Vector3(PI * 0.5, 0, 0.3)))
	root.add_child(_mi(SoftFX.quad(0.3), SoftFX.sprite_mat(GLOVE2, 0.6)))
	_ribbon(fx, root, GLOVE2, 0.05, 0.1)
	root.scale = Vector3.ONE * 1.5


## 磁力环：一圈环(上半红、下半蓝，各半圈用小方块拼)，圆环面朝飞行方向；中间一点白芯；外面一层淡紫光、身后拖一道红蓝光带
static func _magnet(fx: Fx, root: Node3D) -> void:
	var spin := Node3D.new()
	spin.name = "Spin"
	root.add_child(spin)
	var n := 14
	for k in range(n):
		var a: float = TAU * float(k) / float(n)
		var col: Color = MAG_R if sin(a) >= 0.0 else MAG_B
		spin.add_child(_mi(_boxm(Vector3(0.034, 0.022, 0.022)), fx._emissive(col, 2.4), Vector3(cos(a) * 0.08, sin(a) * 0.08, 0.0), Vector3(0, 0, a + PI * 0.5)))
	# 两道磁力线(细环，前后错开)
	spin.add_child(_mi(_torus(0.11, 0.118), fx._emissive(MAG_W, 1.4), Vector3(0, 0, 0.03), Vector3(PI * 0.5, 0, 0)))
	spin.add_child(_mi(_sphere(0.024, 8), fx._emissive(MAG_W, 4.0)))
	root.add_child(_mi(SoftFX.quad(0.36), SoftFX.sprite_mat(Color("#b07cff"), 1.0)))
	_ribbon(fx, root, MAG_R, 0.04, 0.12)
	root.scale = Vector3.ONE * 1.5


## 薄荷叶：两片交叉的叶子(压扁的长椭球：嫩绿、中间一道深一档的叶脉)绕飞行轴排开，叶尖朝前；中间一点清凉的白光；身后飘白色的凉气
static func _mint(fx: Fx, root: Node3D) -> void:
	var spin := Node3D.new()
	spin.name = "Spin"
	root.add_child(spin)
	for k in range(2):
		var a: float = PI * 0.5 * float(k)
		var leaf := _mi(_sphere(0.06, 8), fx._emissive(MINT if k == 0 else MINT2, 1.1), Vector3.ZERO, Vector3(0, 0, a))
		leaf.scale = Vector3(0.55, 0.12, 1.5)
		spin.add_child(leaf)
		var v := _mi(_boxm(Vector3(0.012, 0.016, 0.15)), fx._solid(MINT3), Vector3.ZERO, Vector3(0, 0, a))
		spin.add_child(v)
	spin.add_child(_mi(_sphere(0.02, 8), fx._emissive(COOL, 3.0), Vector3(0, 0, -0.07)))
	root.add_child(_mi(SoftFX.quad(0.26), SoftFX.sprite_mat(COOL, 0.8)))
	root.add_child(_bits(fx, 6, 0.5, COOL, 1.6, Vector3(0, 0.3, 0), 0.25))
	_ribbon(fx, root, MINT2, 0.04, 0.14)
	root.scale = Vector3.ONE * 1.6
