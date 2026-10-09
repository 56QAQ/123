extends RefCounted
## 通用武器 · gen16 的投射物(ProjRegistry 登记；接口见 game/view/proj_registry.gd)。
##   g16_elixir     青玉葫芦：一粒青玉色的仙丹(中间一道白色的丹纹，绕飞行轴打转)，裹着一团淡青的雾，微微上下晃着飞；
##                  出手葫芦口冒一小股青雾，命中一团青雾散开 + 几点白光
##   g16_spirit     三兽图腾：一团绿色的兽灵火(拉长的火苗 + 两只小耳朵 + 两点亮眼)，一闪一闪地往前窜，身后拖一道绿光；
##                  出手一圈绿火星，命中一团绿火炸开
##   g16_fireflies  萤火虫瓶：五只萤火虫绕着飞行轴各自打转(一明一暗地闪)，外面一层淡黄的光；
##                  出手几点黄光从瓶口飘出来，命中一群萤火往上四散
##   g16_note       凤首箜篌：一道金色的音波(三道往前鼓的弧，横竖各一组，一胀一缩) + 正中一个发光的小音符；
##                  出手一圈金色的涟漪，命中一层层往外扩的音波
##   g16_feather    青鸾长弓：一根发光的青色翎羽(白色羽轴 + 两边青羽片，羽尖一点亮)，绕着羽轴轻轻摆着飞，身后拖一道青光；
##                  出手几片青羽抖落，命中一把青羽散开
##   g16_seed       向日葵步枪：一颗葵花籽(黑色的籽壳 + 两道白纹，外面一圈金光)，绕飞行轴打转；
##                  出手枪口一圈金色花瓣，命中一团金光 + 几片小黄花瓣
## 弹体的 -Z = 飞行方向(BattleView 用 look_at 对准目标)。

const KINDS: Array[String] = ["g16_elixir", "g16_spirit", "g16_fireflies", "g16_note", "g16_feather", "g16_seed"]
## 近战武器的刀光(这一批没有近战武器)
const TRAILS := {}

const JADE := Color("#3fbf7a")
const JADE2 := Color("#9ff0c0")
const MIST := Color("#c8f5dc")
const SPIRIT := Color("#46e070")
const SPIRIT2 := Color("#b8ffb0")
const SPIRIT3 := Color("#1f8a3c")
const FLY := Color("#ffe25a")
const FLY2 := Color("#fff6b0")
const FLY3 := Color("#c8a020")
const GOLD := Color("#ffc83a")
const GOLD2 := Color("#fff0a8")
const GOLD3 := Color("#d08a10")
const LUAN := Color("#2ec8d8")
const LUAN2 := Color("#b8f6ff")
const LUAN3 := Color("#1a7a9a")
const SEED := Color("#2a2420")
const SEED2 := Color("#f0ead8")
const PETAL := Color("#ffcf1f")


static func make(fx: Fx, kind: String, _heal: bool, _color: Color) -> Node3D:
	var root := Node3D.new()
	match kind:
		"g16_elixir":
			_elixir(fx, root)
		"g16_spirit":
			_spirit(fx, root)
		"g16_fireflies":
			_fireflies(fx, root)
		"g16_note":
			_note(fx, root)
		"g16_feather":
			_feather(fx, root)
		"g16_seed":
			_seed(fx, root)
	return root


static func fly(node: Node3D, kind: String, frac: float, t: float, seed: float) -> Vector3:
	match kind:
		"g16_elixir":
			var sp: Node3D = node.get_node_or_null("Spin")
			if sp != null:
				sp.rotation.z = t * 8.0 + seed
			return Vector3(0.0, sin(frac * PI) * 0.12 + sin(t * 14.0 + seed) * 0.02, 0.0)
		"g16_spirit":
			var fl: Node3D = node.get_node_or_null("Flame")
			if fl != null:
				var k: float = 1.0 + 0.16 * sin(t * 26.0 + seed * 3.1)
				fl.scale = Vector3(k, k, 1.0 + 0.2 * sin(t * 19.0 + seed))
			return Vector3(sin(frac * PI * 4.0 + seed) * 0.05, sin(frac * PI) * 0.08, 0.0)
		"g16_fireflies":
			var fs: Node3D = node.get_node_or_null("Spin")
			if fs != null:
				fs.rotation.z = t * 6.5 + seed
				for i in range(fs.get_child_count()):
					var f: Node3D = fs.get_child(i)
					var ph: float = float(i) * 1.7 + seed
					f.position.z = sin(t * 9.0 + ph) * 0.05
					var g: float = 0.7 + 0.45 * sin(t * 13.0 + ph * 2.0)
					f.scale = Vector3.ONE * g
			return Vector3(sin(frac * PI * 2.0 + seed) * 0.12, sin(frac * PI) * 0.18, 0.0)
		"g16_note":
			var ns: Node3D = node.get_node_or_null("Wave")
			if ns != null:
				var pulse: float = 1.0 + 0.18 * sin(t * 24.0 + seed)
				ns.scale = Vector3(pulse, pulse, pulse)
			return Vector3(0.0, sin(frac * PI) * 0.06, 0.0)
		"g16_feather":
			var fe: Node3D = node.get_node_or_null("Quill")
			if fe != null:
				fe.rotation.z = sin(t * 10.0 + seed) * 0.6
			return Vector3(sin(frac * PI * 3.0 + seed) * 0.06, sin(frac * PI) * 0.1, 0.0)
		"g16_seed":
			var ss: Node3D = node.get_node_or_null("Spin")
			if ss != null:
				ss.rotation.z = t * 16.0 + seed
	return Vector3.ZERO


static func release(fx: Fx, kind: String, at: Vector3, dir: Vector3) -> void:
	match kind:
		"g16_elixir":
			fx.soft_flash(at, JADE, 0.4, 0.18, 1.4)
			fx.burst(at, MIST, 5, 0.6, 0.6, 0.6, 0.5)
		"g16_spirit":
			fx.soft_flash(at, SPIRIT, 0.45, 0.16, 1.8)
			fx.burst(at, SPIRIT2, 6, 1.2, 0.35, 0.8, 0.35)
		"g16_fireflies":
			fx.soft_flash(at, FLY, 0.35, 0.18, 1.4)
			fx.burst(at, FLY2, 5, 0.5, 0.3, 1.0, 0.6)
		"g16_note":
			fx.soft_flash(at, GOLD, 0.45, 0.16, 1.8)
			fx._ripple(at, dir, GOLD2, 0.05, 0.3, 0.22, 0.7)
		"g16_feather":
			fx.soft_flash(at, LUAN, 0.4, 0.16, 1.6)
			fx.burst(at, LUAN2, 4, 0.8, 0.45, 0.5, 0.45, false)
		"g16_seed":
			fx.soft_flash(at, GOLD, 0.45, 0.16, 1.8)
			fx.burst(at, PETAL, 5, 1.0, 0.45, 0.5, 0.4, false)
		_:
			fx.soft_flash(at, Color("#fff4dc"), 0.4, 0.15, 1.4)


static func hit(fx: Fx, kind: String, at: Vector3, dir: Vector3) -> void:
	match kind:
		"g16_elixir":
			# 一团青雾散开 + 几点白光
			fx.soft_flash(at, JADE, 0.6, 0.24, 1.8)
			fx.burst(at, MIST, 8, 0.9, 0.9, 0.5, 0.7)
			fx.burst(at, JADE2, 5, 1.4, 0.4, 0.7, 0.35)
			fx._ripple(at, dir, JADE2, 0.05, 0.38, 0.3, 0.6)
		"g16_spirit":
			# 一团绿火炸开
			fx.soft_flash(at, SPIRIT, 0.7, 0.22, 2.2)
			fx.burst(at, SPIRIT, 9, 1.8, 0.5, 1.0, 0.45)
			fx.burst(at, SPIRIT2, 5, 1.2, 0.35, 1.2, 0.35)
			fx.burst(at, SPIRIT3, 4, 1.0, 0.5, 0.6, 0.5, false)
		"g16_fireflies":
			# 一群萤火往上四散(慢慢飘)
			fx.soft_flash(at, FLY, 0.55, 0.22, 1.8)
			fx.burst(at, FLY, 8, 0.8, 0.35, 1.6, 0.9)
			fx.burst(at, FLY2, 4, 0.6, 0.3, 1.8, 1.0)
		"g16_note":
			# 一层层往外扩的音波
			fx.soft_flash(at, GOLD, 0.6, 0.2, 2.0)
			fx._ripple(at, dir, GOLD2, 0.06, 0.45, 0.28, 0.8)
			fx._ripple(at, dir, GOLD, 0.04, 0.32, 0.4, 0.6)
			fx.burst(at, GOLD2, 5, 1.4, 0.3, 0.6, 0.35)
		"g16_feather":
			# 一把青羽散开
			fx.soft_flash(at, LUAN, 0.6, 0.2, 2.0)
			fx.burst(at, LUAN, 7, 1.5, 0.55, 0.7, 0.6, false)
			fx.burst(at, LUAN2, 5, 1.3, 0.4, 0.8, 0.45)
		"g16_seed":
			# 一团金光 + 几片小黄花瓣
			fx.soft_flash(at, GOLD, 0.6, 0.2, 2.0)
			fx.burst(at, PETAL, 7, 1.5, 0.5, 0.8, 0.55, false)
			fx.burst(at, GOLD2, 5, 1.6, 0.35, 0.6, 0.35)
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
	spm.initial_velocity_min = 0.1
	spm.initial_velocity_max = 0.4
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


## 仙丹：一粒青玉色的丸子(中间一圈白色的丹纹)，外面一团淡青的雾，身后飘几缕青雾
static func _elixir(fx: Fx, root: Node3D) -> void:
	var spin := Node3D.new()
	spin.name = "Spin"
	root.add_child(spin)
	spin.add_child(_mi(_sphere(0.045, 10), fx._emissive(JADE, 1.6)))
	spin.add_child(_mi(_boxm(Vector3(0.096, 0.014, 0.03)), fx._emissive(MIST, 2.6), Vector3.ZERO, Vector3(0, 0, 0.5)))
	spin.add_child(_mi(_sphere(0.016, 6), fx._emissive(JADE2, 3.0), Vector3(0.02, 0.025, -0.03)))
	root.add_child(_mi(SoftFX.quad(0.3), SoftFX.sprite_mat(JADE, 1.0)))
	root.add_child(_bits(fx, 8, 0.6, MIST, 0.8, Vector3(0, 0.4, 0), 0.4))
	_ribbon(fx, root, JADE2, 0.05, 0.16)
	root.scale = Vector3.ONE * 1.6


## 兽灵火：拉长的绿火苗(三层套着：深绿外焰、亮绿、浅绿内芯)，前端两只小三角耳朵、两点亮眼；身后一道绿光带
static func _spirit(fx: Fx, root: Node3D) -> void:
	var flame := Node3D.new()
	flame.name = "Flame"
	root.add_child(flame)
	var outer := _mi(_sphere(0.06, 10), fx._emissive(SPIRIT3, 1.6, 0.8))
	outer.scale = Vector3(1.0, 1.0, 1.9)
	outer.position = Vector3(0, 0, 0.04)
	flame.add_child(outer)
	var mid := _mi(_sphere(0.045, 10), fx._emissive(SPIRIT, 2.6))
	mid.scale = Vector3(1.0, 1.0, 1.6)
	flame.add_child(mid)
	flame.add_child(_mi(_sphere(0.024, 8), fx._emissive(SPIRIT2, 3.4), Vector3(0, 0, -0.02)))
	# 两只小耳朵(往上、往后斜)
	for sx: float in [-1.0, 1.0]:
		flame.add_child(_mi(_boxm(Vector3(0.022, 0.05, 0.022)), fx._emissive(SPIRIT, 2.4), Vector3(sx * 0.03, 0.055, -0.01), Vector3(0.4, 0, sx * -0.35)))
		flame.add_child(_mi(_sphere(0.009, 6), fx._emissive(Color("#fffbe0"), 4.0), Vector3(sx * 0.02, 0.012, -0.05)))
	root.add_child(_mi(SoftFX.quad(0.34), SoftFX.sprite_mat(SPIRIT, 1.2)))
	_ribbon(fx, root, SPIRIT, 0.07, 0.18)
	root.scale = Vector3.ONE * 1.6


## 萤火虫：五只亮黄的小光点(发光的尾灯 + 一点暗色的小身子)绕飞行轴排开，外面一层淡黄的光
static func _fireflies(fx: Fx, root: Node3D) -> void:
	var spin := Node3D.new()
	spin.name = "Spin"
	root.add_child(spin)
	var rs: Array = [0.07, 0.045, 0.09, 0.055, 0.075]
	for k in range(5):
		var a: float = TAU * float(k) / 5.0 + 0.4
		var f := Node3D.new()
		f.position = Vector3(cos(a) * float(rs[k]), sin(a) * float(rs[k]), 0.02 * float(k % 3) - 0.02)
		f.add_child(_mi(_sphere(0.026, 8), fx._emissive(FLY if k % 2 == 0 else FLY2, 5.0)))
		f.add_child(_mi(SoftFX.quad(0.06), SoftFX.sprite_mat(FLY, 1.2)))
		f.add_child(_mi(_boxm(Vector3(0.012, 0.012, 0.018)), fx._solid(Color("#4a3a20")), Vector3(0, 0, -0.026)))
		spin.add_child(f)
	root.add_child(_mi(SoftFX.quad(0.36), SoftFX.sprite_mat(FLY, 0.7)))
	root.add_child(_bits(fx, 6, 0.7, FLY2, 2.0, Vector3(0, 0.3, 0), 0.25))
	root.scale = Vector3.ONE * 1.6


## 音波：三道往前鼓的金弧(一道套一道，横着一组、竖着一组——从上面、侧面看都是"))))")，正中一个发光的小音符
static func _note(fx: Fx, root: Node3D) -> void:
	var wave := Node3D.new()
	wave.name = "Wave"
	root.add_child(wave)
	for i in range(3):
		var r: float = 0.05 + 0.025 * float(i)
		var c: Color = GOLD2 if i == 0 else (GOLD if i == 1 else GOLD3)
		var cz: float = r + 0.035 * float(i)
		for k in range(7):
			var th: float = lerpf(-1.0, 1.0, float(k) / 6.0)
			var z: float = cz - r * cos(th)
			var mat: Material = fx._emissive(c, 2.8 - 0.5 * float(i))
			wave.add_child(_mi(_boxm(Vector3(0.022, 0.012, 0.012)), mat, Vector3(r * sin(th), 0.0, z), Vector3(0, -th, 0)))
			wave.add_child(_mi(_boxm(Vector3(0.012, 0.022, 0.012)), mat, Vector3(0.0, r * sin(th), z), Vector3(th, 0, 0)))
	# 音符：符头(扁球) + 符干 + 符尾
	var head := _mi(_sphere(0.02, 8), fx._emissive(GOLD2, 3.4), Vector3(-0.008, -0.02, 0.06))
	head.scale = Vector3(1.3, 1.0, 0.6)
	wave.add_child(head)
	wave.add_child(_mi(_boxm(Vector3(0.008, 0.06, 0.008)), fx._emissive(GOLD2, 3.0), Vector3(0.012, 0.01, 0.06)))
	wave.add_child(_mi(_boxm(Vector3(0.026, 0.008, 0.008)), fx._emissive(GOLD2, 3.0), Vector3(0.024, 0.036, 0.06), Vector3(0, 0, -0.6)))
	root.add_child(_mi(SoftFX.quad(0.34), SoftFX.sprite_mat(GOLD, 1.0)))
	_ribbon(fx, root, GOLD2, 0.05, 0.12)
	root.scale = Vector3.ONE * 1.6


## 翎羽：一根白色的羽轴(沿飞行方向)，两边青色的羽片(往后渐宽再收)，羽尖一点亮；身后一道青光
static func _feather(fx: Fx, root: Node3D) -> void:
	var quill := Node3D.new()
	quill.name = "Quill"
	root.add_child(quill)
	quill.add_child(_mi(_boxm(Vector3(0.008, 0.008, 0.2)), fx._emissive(LUAN2, 2.6), Vector3(0, 0, 0.02)))
	for k in range(6):
		var z: float = -0.06 + 0.026 * float(k)
		var w: float = 0.02 + 0.012 * sin(float(k) / 5.0 * PI)
		var c: Color = LUAN if k % 2 == 0 else LUAN3
		for sx: float in [-1.0, 1.0]:
			quill.add_child(_mi(_boxm(Vector3(w, 0.006, 0.024)), fx._emissive(c, 1.8), Vector3(sx * (w * 0.5 + 0.004), 0, z), Vector3(0, sx * 0.25, 0)))
	quill.add_child(_mi(_sphere(0.012, 6), fx._emissive(Color("#f0ffff"), 4.0), Vector3(0, 0, -0.08)))
	root.add_child(_mi(SoftFX.quad(0.26), SoftFX.sprite_mat(LUAN, 0.9)))
	_ribbon(fx, root, LUAN, 0.05, 0.16)
	root.scale = Vector3.ONE * 1.7


## 葵花籽：压扁的水滴形籽壳(黑)，两道白纹，外面一圈金光；绕飞行轴打转
static func _seed(fx: Fx, root: Node3D) -> void:
	var spin := Node3D.new()
	spin.name = "Spin"
	root.add_child(spin)
	var shell := _mi(_sphere(0.035, 8), fx._solid(SEED))
	shell.scale = Vector3(0.75, 0.45, 1.6)
	spin.add_child(shell)
	for sx: float in [-0.012, 0.012]:
		spin.add_child(_mi(_boxm(Vector3(0.006, 0.034, 0.09)), fx._emissive(SEED2, 0.6), Vector3(sx, 0.0, 0.0)))
	spin.add_child(_mi(_sphere(0.012, 6), fx._emissive(GOLD2, 3.0), Vector3(0, 0, -0.05)))
	root.add_child(_mi(SoftFX.quad(0.3), SoftFX.sprite_mat(GOLD, 1.3)))
	_ribbon(fx, root, GOLD, 0.05, 0.12)
	root.scale = Vector3.ONE * 1.6
