class_name SaintAura
extends Node3D
## 灭罪节点(她是唯一的光)吟唱时身上的光：
##   · 脚下一枚慢慢转的圣印(Fx.holy_seal，叠加 + 普通混合垫底)
##   · 身后一轮竖着的光轮(同一种圣印，永远朝着镜头、垫在她身后——从哪边看都是"背后有光")
##   · 一圈发光的经文(灭 罪 赦 光 圣 誓 审 判)绕着她腰间慢慢转，上下起伏
##   · 圣印里往上飘的光点
## 光束每结算一次(0.25 秒)pulse()：圣印 / 光轮 / 经文一起亮一下；end()：淡掉再删。跟着她的视图走(top_level，不随朝向转)

const WORDS := ["灭", "罪", "赦", "光", "圣", "誓", "审", "判"]

var fx: Fx
var follow: Node3D
var height := 1.3
var _ground: Node3D
var _wheel: Node3D
var _words: Array[Label3D] = []
var _mats: Array = []             # 圣印的材质(叠加的那层)：pulse / fade
var _tints: Array = []            # 垫底的普通混合层：只跟着 fade
var _motes: GPUParticles3D
var _t := 0.0
var _pulse := 0.0
var _fade := 0.0
var _ending := false


static func create(p_fx: Fx, p_follow: Node3D, p_height: float, k: float = 1.0) -> SaintAura:
	var a := SaintAura.new()
	a.fx = p_fx
	a.follow = p_follow
	a.height = p_height
	a.top_level = true
	a.name = "SaintAura"
	p_fx.add_child(a)
	a.global_position = p_follow.global_position
	a._ground = Node3D.new()
	a._ground.position.y = 0.03
	a._ground.scale = Vector3.ONE * 0.95 * k
	a.add_child(a._ground)
	var gm: Array = p_fx.holy_seal(a._ground, "Seal", 0.8, 0.3)
	a._mats.append(gm[0])
	a._tints.append(gm[1])
	a._wheel = Node3D.new()
	a.add_child(a._wheel)
	var wm: Array = p_fx.holy_seal(a._wheel, "Wheel", -0.5, 0.18)
	for wn: String in ["Wheel", "WheelTint"]:
		var mi: MeshInstance3D = a._wheel.get_node(wn)
		mi.rotation.x = PI * 0.5                       # 竖起来：圆盘面朝 +Z(之后整个 _wheel 转向镜头)
		mi.scale = Vector3.ONE * 0.62 * k
	(wm[0] as ShaderMaterial).set_shader_parameter("pool_k", 0.5)
	a._mats.append(wm[0])
	a._tints.append(wm[1])
	for i in range(WORDS.size()):
		var l := Label3D.new()
		l.text = WORDS[i]
		l.modulate = Color("#ffe27a")
		l.outline_modulate = Color(0.45, 0.25, 0.0, 0.9)
		l.outline_size = 10
		l.font_size = 46
		l.pixel_size = 0.0048 * k
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.shaded = false
		l.render_priority = 30
		a.add_child(l)
		a._words.append(l)
	a._motes = SoftFX.particles(16, 1.4, SoftFX.ramp([Color(1.0, 0.95, 0.7, 0.0), Color(1.0, 0.88, 0.5, 1.0), Color(1.0, 0.8, 0.3, 0.0)]), 0.1)
	var pm: ParticleProcessMaterial = a._motes.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = 0.8 * k
	pm.emission_ring_inner_radius = 0.2 * k
	pm.emission_ring_height = 0.05
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 10.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 1.1
	pm.gravity = Vector3.ZERO
	a._motes.position.y = 0.05
	a._motes.emitting = true
	a.add_child(a._motes)
	a._t = randf() * 10.0
	a._apply()
	return a


func pulse() -> void:
	_pulse = 1.0


func end() -> void:
	if _ending:
		return
	_ending = true
	_motes.emitting = false


func _apply() -> void:
	var p: float = _pulse * _pulse
	for m: Variant in _mats:
		(m as ShaderMaterial).set_shader_parameter("pulse", p)
		(m as ShaderMaterial).set_shader_parameter("fade", _fade)
	(_tints[0] as ShaderMaterial).set_shader_parameter("fade", 0.3 * _fade)
	(_tints[1] as ShaderMaterial).set_shader_parameter("fade", 0.18 * _fade)
	for l: Label3D in _words:
		l.modulate.a = _fade * (0.75 + 0.25 * p)
		l.outline_modulate.a = _fade * 0.9


func _process(delta: float) -> void:
	if follow == null or not is_instance_valid(follow):
		queue_free()
		return
	var s: float = maxf(0.2, fx.speed_scale) if fx != null else 1.0
	var dt: float = delta * s
	_t += dt
	_pulse = maxf(0.0, _pulse - dt * 4.0)
	_fade = move_toward(_fade, 0.0 if _ending else 1.0, dt * (2.5 if _ending else 3.0))
	if _ending and _fade <= 0.0:
		queue_free()
		return
	global_position = follow.global_position
	# 身后的光轮：在她头后面、永远朝着镜头(从镜头看过去垫在她身后)
	var head := Vector3(0.0, height * 0.72, 0.0)
	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() != null else null
	if cam != null:
		var to_cam: Vector3 = cam.global_position - (global_position + head)
		var flat := Vector3(to_cam.x, 0.0, to_cam.z)
		var dir: Vector3 = flat.normalized() if flat.length() > 0.01 else Vector3.BACK
		_wheel.position = head - dir * 0.3
		_wheel.basis = Basis.looking_at(-to_cam.normalized(), Vector3.UP)
	_wheel.scale = Vector3.ONE * (1.0 + 0.08 * _pulse)
	# 经文：绕着腰间转一圈，上下起伏
	var n: int = _words.size()
	for i in range(n):
		var a: float = _t * 0.6 + TAU * float(i) / float(n)
		_words[i].position = Vector3(cos(a) * 0.78, height * 0.42 + 0.08 * sin(_t * 1.7 + float(i)), sin(a) * 0.78)
	_apply()
