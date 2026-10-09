extends RefCounted
## 通用武器 · gen8(手枪)的投射物(ProjRegistry 登记；接口见 game/view/proj_registry.gd)。
##   g8_pea      豌豆荚双枪：一颗亮绿的豌豆(微微转着)，往上拱一点，身后飘几点绿；出手一小团绿雾，命中啪地裂开(豆皮 + 绿汁)
##   g8_rivet    铆钉双枪：一颗烧红的铆钉(钢钉杆 + 发红光的钉帽)，几乎直线，身后拖火星；出手一股白气 + 火星，命中当地一声迸出一圈火星
##   g8_dart     调剂镖枪：一支药镖(银针 + 发光的紫色药管 + 紫尾羽)，直线；出手一点紫雾，命中溅开一把紫色药液
##   g8_crane    千纸鹤双枪：一只青色的纸鹤(翅膀一扇一扇)，左右飘着飞过去；出手抖落几片纸屑，命中散成一把青白的碎纸
##   g8_rocket   庆典烟花筒：一枚小火箭(红筒 + 金尖 + 尾巴喷火星)，往上拱着飞；出手一股烟，命中炸开一朵彩色烟花
##   g8_sunbeam  金阳射线枪：一道日光束(白热的芯拉成一长条 + 金色光晕)，笔直；出手一团金光，命中一轮小日冕
## 弹体的 -Z = 飞行方向(BattleView 用 look_at 对准目标)。

const KINDS: Array[String] = ["g8_pea", "g8_rivet", "g8_dart", "g8_crane", "g8_rocket", "g8_sunbeam"]
## 近战刀光(这批都是远程，没有)
const TRAILS := {}

const PEA := Color("#8fd64e")
const PEA2 := Color("#c9f28e")
const POD := Color("#4e9a2e")
const RIVET := Color("#9aa2ae")
const HOT := Color("#ff7a2a")
const HOT2 := Color("#ffd08a")
const STEAM := Color("#e6ecf2")
const DART := Color("#a050f0")
const DART2 := Color("#e2bcff")
const SILVER := Color("#d8dce4")
const CRANE := Color("#3cb4be")
const CRANE2 := Color("#a8e8ea")
const PAPER := Color("#f4f0e4")
const FW_RED := Color("#e0302a")
const FW_GOLD := Color("#ffc040")
const FW_COLORS := [Color("#ff4a4a"), Color("#ffd040"), Color("#5ad0ff"), Color("#7aff7a"), Color("#ff7ae0")]
const SMOKE := Color("#a8a2a0")
const SUN := Color("#ffc22e")
const SUN2 := Color("#fff6c8")


static func make(fx: Fx, kind: String, heal: bool, _color: Color) -> Node3D:
	var root := Node3D.new()
	match kind:
		"g8_pea":
			_pea(fx, root)
		"g8_rivet":
			_rivet(fx, root)
		"g8_dart":
			_dart(fx, root)
		"g8_crane":
			_crane(fx, root)
		"g8_rocket":
			_rocket(fx, root)
		"g8_sunbeam":
			_sunbeam(fx, root, heal)
	return root


static func fly(node: Node3D, kind: String, frac: float, t: float, seed: float) -> Vector3:
	match kind:
		"g8_pea":
			var sp: Node3D = node.get_node_or_null("Spin")
			if sp != null:
				sp.rotation.x = t * 12.0 + seed
			return Vector3(0.0, sin(frac * PI) * 0.14, 0.0)
		"g8_rivet":
			return Vector3(0.0, sin(frac * PI) * 0.04, 0.0)
		"g8_dart":
			var dsp: Node3D = node.get_node_or_null("Spin")
			if dsp != null:
				dsp.rotation.z = t * 10.0 + seed
			return Vector3(0.0, sin(frac * PI) * 0.05, 0.0)
		"g8_crane":
			# 纸鹤：翅膀一扇一扇，左右飘、上下点
			var bd: Node3D = node.get_node_or_null("Crane")
			if bd != null:
				var flap: float = sin(t * 22.0 + seed) * 0.55
				var wl: Node3D = bd.get_node_or_null("WingL")
				var wr: Node3D = bd.get_node_or_null("WingR")
				if wl != null:
					wl.rotation.z = 0.25 + flap
				if wr != null:
					wr.rotation.z = -0.25 - flap
				bd.rotation.z = sin(frac * PI * 2.0 + seed) * 0.35
			var side: float = 1.0 if int(seed) % 2 == 0 else -1.0
			return Vector3(side * sin(frac * PI * 2.0) * 0.18, sin(frac * PI) * 0.22 + sin(t * 9.0 + seed) * 0.02, 0.0)
		"g8_rocket":
			var rs: Node3D = node.get_node_or_null("Spin")
			if rs != null:
				rs.rotation.z = t * 16.0 + seed
			return Vector3(0.0, sin(frac * PI) * 0.36, 0.0)
		"g8_sunbeam":
			var hl: Node3D = node.get_node_or_null("Halo")
			if hl != null:
				hl.scale = Vector3.ONE * (1.0 + 0.15 * sin(t * 41.0 + seed * 3.1))
			return Vector3.ZERO
	return Vector3.ZERO


static func release(fx: Fx, kind: String, at: Vector3, dir: Vector3) -> void:
	match kind:
		"g8_pea":
			fx.soft_flash(at, PEA, 0.35, 0.14, 1.2)
			fx.fire_puff(at, PEA2, 5, 0.25, 0.6, 0.35, 0.2, false)
		"g8_rivet":
			fx.soft_flash(at, HOT, 0.45, 0.12, 1.8)
			fx.burst(at + dir * 0.05, HOT2, 6, 2.6, 0.35, 0.4, 0.22)
			fx.fire_puff(at, STEAM, 6, 0.3, 0.8, 0.4, 0.3, false)
		"g8_dart":
			fx.soft_flash(at, DART, 0.4, 0.14, 1.6)
			fx.fire_puff(at, DART2, 5, 0.25, 0.5, 0.4, 0.2, false)
		"g8_crane":
			fx.soft_flash(at, CRANE2, 0.35, 0.16, 1.2)
			fx.burst(at, PAPER, 4, 0.9, 0.5, 0.6, 0.45, false)
			fx.burst(at, CRANE, 3, 0.8, 0.5, 0.6, 0.45, false)
		"g8_rocket":
			fx.soft_flash(at, FW_GOLD, 0.5, 0.16, 1.8)
			fx.burst(at + dir * 0.06, FW_GOLD, 7, 2.2, 0.4, 0.6, 0.3)
			fx.fire_puff(at, SMOKE, 7, 0.4, 0.7, 0.7, 0.5, false)
		"g8_sunbeam":
			fx.soft_flash(at, SUN, 0.6, 0.14, 2.4)
			fx.burst(at + dir * 0.05, SUN2, 5, 2.0, 0.3, 0.3, 0.18)
		_:
			fx.soft_flash(at, Color("#fff4dc"), 0.4, 0.15, 1.4)


static func hit(fx: Fx, kind: String, at: Vector3, dir: Vector3) -> void:
	match kind:
		"g8_pea":
			# 啪地裂开：一把亮绿的豆汁 + 几片豆皮
			fx.soft_flash(at, PEA, 0.45, 0.16, 1.4)
			fx.burst(at, PEA2, 7, 1.8, 0.45, 0.6, 0.35)
			fx.burst(at, POD, 5, 1.4, 0.5, 0.8, 0.45, false)
		"g8_rivet":
			# 当地一声：一圈火星 + 一点白光
			fx.soft_flash(at, HOT2, 0.55, 0.14, 2.2)
			fx.burst(at, HOT, 10, 3.2, 0.35, 0.6, 0.3)
			fx.burst(at, HOT2, 4, 2.2, 0.3, 0.8, 0.2)
			fx.burst(at, RIVET, 3, 1.4, 0.4, 0.6, 0.35, false)
		"g8_dart":
			# 溅开一把紫色药液 + 一圈淡紫的雾
			fx.soft_flash(at, DART, 0.5, 0.18, 1.8)
			fx.burst(at, DART, 8, 1.8, 0.45, 0.4, 0.4)
			fx.burst(at, DART2, 4, 1.2, 0.35, 0.7, 0.3)
			fx._ripple(at, dir, DART2, 0.06, 0.4, 0.28, 0.6)
		"g8_crane":
			# 散成一把青白的碎纸
			fx.soft_flash(at, CRANE2, 0.45, 0.18, 1.4)
			fx.burst(at, PAPER, 8, 1.6, 0.6, 0.9, 0.6, false)
			fx.burst(at, CRANE, 6, 1.4, 0.6, 0.9, 0.6, false)
		"g8_rocket":
			# 炸开一朵彩色烟花：金色的芯 + 几种颜色的火星往四面散 + 一圈光环
			fx.soft_flash(at, FW_GOLD, 0.8, 0.22, 2.6)
			for i in range(FW_COLORS.size()):
				var c: Color = FW_COLORS[(i + int(absf(at.x * 7.0))) % FW_COLORS.size()]
				fx.burst(at + Vector3(0, 0.08, 0), c, 6, 3.0, 0.4, 0.9, 0.5)
			fx.burst(at, FW_GOLD, 6, 1.8, 0.35, 1.2, 0.6)
			fx._ripple(at + Vector3(0, 0.1, 0), Vector3.UP, FW_GOLD, 0.1, 0.7, 0.35, 0.7)
			fx.fire_puff(at, SMOKE, 6, 0.45, 0.6, 0.9, 0.5, false)
		"g8_sunbeam":
			# 一轮小日冕
			fx.soft_flash(at, SUN, 0.75, 0.2, 2.6)
			fx.burst(at, SUN2, 8, 2.6, 0.3, 0.5, 0.25)
			fx._ripple(at, dir, SUN, 0.08, 0.55, 0.3, 0.8)
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


static func _sphere(r: float, segs: int = 10) -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = segs
	sm.rings = maxi(3, segs / 2)
	return sm


static func _cyl(r0: float, r1: float, h: float, segs: int = 8) -> CylinderMesh:
	var cm := CylinderMesh.new()
	cm.top_radius = r0
	cm.bottom_radius = r1
	cm.height = h
	cm.radial_segments = segs
	cm.rings = 1
	return cm


static func _boxm(s: Vector3) -> BoxMesh:
	var bm := BoxMesh.new()
	bm.size = s
	return bm


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


static func _ribbon(fx: Fx, root: Node3D, c: Color, w: float, life: float) -> void:
	var rib: RibbonTrail = RibbonTrail.create(root, c, w, life)
	rib.time_scale = maxf(0.2, fx.speed_scale)
	root.add_child(rib)


## 豌豆：一颗亮绿的球(顶上一点高光)，外面一层淡绿的光；身后掉几点绿
static func _pea(fx: Fx, root: Node3D) -> void:
	var spin := Node3D.new()
	spin.name = "Spin"
	root.add_child(spin)
	spin.add_child(_mi(_sphere(0.055), fx._emissive(PEA, 1.1)))
	spin.add_child(_mi(_sphere(0.018, 6), fx._emissive(PEA2, 1.8), Vector3(0.02, 0.035, -0.01)))
	root.add_child(_mi(SoftFX.quad(0.24), SoftFX.sprite_mat(PEA, 0.9)))
	root.add_child(_bits(fx, 6, 0.4, PEA2, 1.4, Vector3(0, -1.0, 0), 0.3))
	_ribbon(fx, root, PEA, 0.04, 0.12)
	root.scale = Vector3.ONE * 1.3


## 铆钉：钢钉杆(沿飞行方向，在后) + 圆钉帽(在前，发红光) + 一圈橙色光晕；身后拖火星
static func _rivet(fx: Fx, root: Node3D) -> void:
	root.add_child(_mi(_cyl(0.018, 0.018, 0.14), fx._solid(RIVET), Vector3(0, 0, 0.06), Vector3(PI * 0.5, 0, 0)))
	root.add_child(_mi(_cyl(0.045, 0.045, 0.03, 10), fx._emissive(HOT, 2.6), Vector3(0, 0, -0.025), Vector3(PI * 0.5, 0, 0)))
	root.add_child(_mi(_sphere(0.035, 8), fx._emissive(HOT2, 3.2), Vector3(0, 0, -0.04)))
	root.add_child(_mi(SoftFX.quad(0.26), SoftFX.sprite_mat(HOT, 1.6)))
	root.add_child(_bits(fx, 10, 0.3, HOT2, 3.0, Vector3(0, -2.5, 0), 0.3))
	_ribbon(fx, root, HOT, 0.04, 0.1)
	root.scale = Vector3.ONE * 1.3


## 药镖：前面一根银针，中间一截发光的紫色药管，后面四片紫尾羽(Spin 绕飞行轴慢慢转)
static func _dart(fx: Fx, root: Node3D) -> void:
	var spin := Node3D.new()
	spin.name = "Spin"
	root.add_child(spin)
	spin.add_child(_mi(_cyl(0.004, 0.01, 0.12, 6), fx._solid(SILVER), Vector3(0, 0, -0.13), Vector3(-PI * 0.5, 0, 0)))
	spin.add_child(_mi(_cyl(0.022, 0.022, 0.13, 8), fx._emissive(DART, 2.2, 0.85), Vector3(0, 0, -0.01), Vector3(PI * 0.5, 0, 0)))
	spin.add_child(_mi(_cyl(0.026, 0.026, 0.02, 8), fx._solid(SILVER), Vector3(0, 0, 0.06), Vector3(PI * 0.5, 0, 0)))
	for k in range(4):
		var a: float = TAU * float(k) / 4.0
		spin.add_child(_mi(_boxm(Vector3(0.004, 0.045, 0.06)), fx._emissive(DART2, 1.0), Vector3(cos(a) * 0.028, sin(a) * 0.028, 0.1), Vector3(0, 0, a)))
	root.add_child(_mi(SoftFX.quad(0.22), SoftFX.sprite_mat(DART, 1.0)))
	_ribbon(fx, root, DART2, 0.03, 0.12)
	root.scale = Vector3.ONE * 1.35


## 纸鹤：菱形的身子 + 往前伸的脖子 + 翘起的尾巴，两片翅膀(WingL / WingR，fly 里扇)；外面一层淡青的光
static func _crane(fx: Fx, root: Node3D) -> void:
	var bd := Node3D.new()
	bd.name = "Crane"
	root.add_child(bd)
	var pm: StandardMaterial3D = fx._emissive(CRANE, 0.9)
	var pm2: StandardMaterial3D = fx._emissive(CRANE2, 1.0)
	bd.add_child(_mi(_boxm(Vector3(0.032, 0.032, 0.12)), pm, Vector3.ZERO, Vector3(0, 0, PI * 0.25)))
	bd.add_child(_mi(_boxm(Vector3(0.016, 0.016, 0.1)), pm2, Vector3(0, 0.04, -0.09), Vector3(0.7, 0, 0)))      # 脖子
	bd.add_child(_mi(_boxm(Vector3(0.016, 0.03, 0.016)), pm2, Vector3(0, 0.07, -0.13), Vector3(0, 0, 0)))       # 头
	bd.add_child(_mi(_boxm(Vector3(0.016, 0.016, 0.09)), pm2, Vector3(0, 0.035, 0.09), Vector3(-0.7, 0, 0)))     # 尾巴
	for s: float in [-1.0, 1.0]:
		var w := Node3D.new()
		w.name = "WingL" if s < 0.0 else "WingR"
		w.position = Vector3(0.02 * s, 0.02, 0.0)
		bd.add_child(w)
		w.add_child(_mi(_boxm(Vector3(0.16, 0.006, 0.09)), pm2 if s < 0.0 else pm, Vector3(0.08 * s, 0.0, 0.01), Vector3(0, 0.35 * s, 0)))
	root.add_child(_mi(SoftFX.quad(0.3), SoftFX.sprite_mat(CRANE2, 0.6)))
	_ribbon(fx, root, CRANE2, 0.05, 0.16)
	root.scale = Vector3.ONE * 1.5


## 小火箭：红色的纸筒 + 金色的尖头(在前) + 一根细尾杆；尾巴喷金色火星、拖一道烟
static func _rocket(fx: Fx, root: Node3D) -> void:
	var spin := Node3D.new()
	spin.name = "Spin"
	root.add_child(spin)
	spin.add_child(_mi(_cyl(0.03, 0.03, 0.14, 8), fx._emissive(FW_RED, 1.2), Vector3.ZERO, Vector3(PI * 0.5, 0, 0)))
	spin.add_child(_mi(_cyl(0.0, 0.032, 0.06, 8), fx._emissive(FW_GOLD, 1.6), Vector3(0, 0, -0.1), Vector3(-PI * 0.5, 0, 0)))
	spin.add_child(_mi(_cyl(0.033, 0.033, 0.015, 8), fx._emissive(FW_GOLD, 1.4), Vector3(0, 0, 0.03), Vector3(PI * 0.5, 0, 0)))
	spin.add_child(_mi(_boxm(Vector3(0.008, 0.008, 0.16)), fx._solid(Color("#7a4a26")), Vector3(0.02, 0, 0.14)))
	root.add_child(_mi(SoftFX.quad(0.18), SoftFX.sprite_mat(FW_GOLD, 2.0), Vector3(0, 0, 0.08)))
	root.add_child(_bits(fx, 14, 0.4, FW_GOLD, 3.0, Vector3(0, -2.0, 0), 0.35))
	var tr := SoftFX.particles(14, 0.5, SoftFX.ramp([Color(SMOKE.r, SMOKE.g, SMOKE.b, 0.0), Color(SMOKE.r, SMOKE.g, SMOKE.b, 0.45),
		Color(SMOKE.r, SMOKE.g, SMOKE.b, 0.0)], [0.0, 0.2, 1.0]), 0.2, false)
	var pm: ParticleProcessMaterial = tr.process_material
	pm.direction = Vector3(0, 0.3, 0)
	pm.spread = 40.0
	pm.initial_velocity_min = 0.06
	pm.initial_velocity_max = 0.2
	pm.gravity = Vector3(0, 0.4, 0)
	tr.emitting = true
	root.add_child(tr)
	_ribbon(fx, root, FW_GOLD, 0.05, 0.16)
	root.scale = Vector3.ONE * 1.3


## 日光束：白热的芯拉成一长条(沿飞行方向) + 金色光晕(Halo，忽明忽暗)；打在队友身上(没有这种情况，留着)颜色一样
static func _sunbeam(fx: Fx, root: Node3D, _heal: bool) -> void:
	var cm := CapsuleMesh.new()
	cm.radius = 0.024
	cm.height = 0.42
	cm.radial_segments = 6
	cm.rings = 2
	root.add_child(_mi(cm, fx._emissive(SUN2, 4.5), Vector3.ZERO, Vector3(PI * 0.5, 0, 0)))
	var cm2 := CapsuleMesh.new()
	cm2.radius = 0.05
	cm2.height = 0.5
	cm2.radial_segments = 8
	cm2.rings = 2
	root.add_child(_mi(cm2, fx._emissive(SUN, 2.2, 0.35), Vector3.ZERO, Vector3(PI * 0.5, 0, 0)))
	var halo := Node3D.new()
	halo.name = "Halo"
	root.add_child(halo)
	halo.add_child(_mi(SoftFX.quad(0.3), SoftFX.sprite_mat(SUN, 1.5)))
	_ribbon(fx, root, SUN, 0.06, 0.1)
	root.scale = Vector3.ONE * 1.25
