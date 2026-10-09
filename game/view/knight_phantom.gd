class_name KnightPhantom
extends Node3D
## 光之虚影(正行节点·百合骑士的骑士；单位数据 phantom_fx)：开战后她身后站着一个黄光组成的骑士——
## 用她自己的模型(同一把武器、同一面盾、同样的持械动作)，换成光的材质(半透明的金色、边缘亮、一道道往上流的光纹)，比她大一圈、微微浮起。
## 每次那个触发器真的触发(BattleView 收到 trigger 事件)，虚影转向那个敌人挥一次普攻；两次挥砍之间至少隔 min_interval 秒(太密的触发只挥一次)。
## 平时跟在她背后(她转身时慢慢绕过去)、轻轻上下浮动；她倒下 / 战斗结束时化成光点散掉。世界坐标(top_level)，不跟着她的节点转。

const GHOST_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_prepass_alpha, cull_back, shadows_disabled, fog_disabled;
uniform vec4 col : source_color = vec4(1.0, 0.84, 0.42, 1.0);
uniform vec4 rim_col : source_color = vec4(0.95, 0.55, 0.08, 1.0);
uniform float fade = 1.0;
uniform float flash = 0.0;
varying vec3 wp;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	// 身体：半透明的亮金色(保留一点原来的明暗，看得出盔甲 / 头发 / 盾的分块)；轮廓：一圈不透明的琥珀金(白地上也描得出人形)
	float fr = pow(1.0 - clamp(abs(dot(normalize(NORMAL), VIEW)), 0.0, 1.0), 1.4);
	float luma = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	float scan = smoothstep(0.8, 1.0, sin(wp.y * 34.0 - TIME * 5.0) * 0.5 + 0.5);
	vec3 body = col.rgb * (0.7 + 0.45 * luma);
	vec3 c = mix(body, rim_col.rgb, clamp(fr * 1.1, 0.0, 1.0));
	c += vec3(0.3, 0.25, 0.1) * scan;
	c = mix(c, vec3(1.0, 0.93, 0.6), flash * 0.55);
	ALBEDO = c * (1.05 + flash * 0.35);
	ALPHA = clamp((0.26 + 0.66 * fr + 0.1 * scan + flash * 0.25) * fade, 0.0, 1.0);
}
"""
static var _shader: Shader = null

var follow: UnitView = null
var cfg: Dictionary = {}
var model: Node3D
var ap: AnimationPlayer
var look: Dictionary = {}
var color: Color = Color("#ffd76a")
var _mat: ShaderMaterial
var _clock: float = 0.0
var _last_swing: float = -99.0
var _fade: float = 0.0
var _flash: float = 0.0
var _dying: bool = false
var _aim: Vector3 = Vector3.ZERO
var _aiming: bool = false
var _motes: GPUParticles3D = null
var _idle: String = ""
var _attack: String = ""


static func create(v: UnitView, p_cfg: Dictionary) -> KnightPhantom:
	if v == null or v.model == null:
		return null
	var kp := KnightPhantom.new()
	kp.follow = v
	kp.cfg = p_cfg
	kp.color = Color(str(p_cfg.get("color", "#ffd76a")))
	return kp


func _ready() -> void:
	top_level = true
	if _shader == null:
		_shader = Shader.new()
		_shader.code = GHOST_SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	_mat.set_shader_parameter("col", color)
	_mat.set_shader_parameter("fade", 0.0)
	_mat.render_priority = 1
	model = UnitView.MODEL_SCENE.instantiate()
	add_child(model)
	model.scale = Vector3.ONE * follow.def.scale * float(cfg.get("scale", 1.3))
	ap = model.get_node("AnimationPlayer") as AnimationPlayer
	look = follow.look.duplicate(true)
	UnitSkin.apply(model, look, follow.def.faction_id)
	var sk: Skeleton3D = UnitSkin.skeleton_of(model)
	for c: Node in sk.get_children():
		var mi := c as MeshInstance3D
		if mi != null and mi.visible:
			mi.material_override = _mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_idle = UnitSkin.anim(look, "idle")
	_attack = UnitSkin.anim(look, "attack")
	if ap.has_animation(_idle):
		ap.play(_idle)
		ap.seek(randf() * 2.0, true)
	# 挥砍的光弧(近战武器才有)：金色
	var tr: WeaponTrail = WeaponTrail.create(sk, ap, "Bow", str(look.get("wclass", "")), color.lerp(Color.WHITE, 0.3), str(look.get("model", "")))
	if tr != null:
		add_child(tr)
	# 身上往上飘的光点
	_motes = SoftFX.particles(14, 1.4, SoftFX.ramp([Color(color.r, color.g, color.b, 0.0), Color(1.0, 0.95, 0.75, 0.9), Color(color.r, color.g, color.b, 0.0)],
		[0.0, 0.3, 1.0]), 0.07)
	var pm: ParticleProcessMaterial = _motes.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.3, 0.6, 0.3)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 15.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.5
	pm.gravity = Vector3(0, 0.2, 0)
	(_motes.material_override as StandardMaterial3D).disable_fog = true
	_motes.position = Vector3(0.0, 0.8, 0.0)
	_motes.emitting = true
	add_child(_motes)
	global_position = _home()
	rotation.y = follow.rotation.y


## 她背后该站的地方(她朝 +Z：背后 = 往 -Z 退 back 米、浮起 lift 米、轻轻上下浮动)
func _home() -> Vector3:
	var yaw: float = follow.rotation.y
	var fwd := Vector3(sin(yaw), 0.0, cos(yaw))
	return follow.global_position - fwd * float(cfg.get("back", 0.8)) + Vector3(0.0, float(cfg.get("lift", 0.2)) + 0.05 * sin(_clock * 1.7), 0.0)


## 触发一次：转向 at 挥一次普攻(离上一次不到 min_interval 秒就不挥)。返回挥了没有
func swing(at: Vector3) -> bool:
	if _dying or _clock - _last_swing < float(cfg.get("min_interval", 0.75)) or not ap.has_animation(_attack):
		return false
	_last_swing = _clock
	_aim = at
	_aiming = true
	_flash = 1.0
	ap.clear_queue()
	ap.play(_attack, 0.08)
	ap.seek(0.0, false)
	if ap.has_animation(_idle):
		ap.queue(_idle)
	return true


## 化成光点散掉(她倒下 / 战斗结束)
func vanish() -> void:
	if _dying:
		return
	_dying = true
	if _motes != null:
		var pm: ParticleProcessMaterial = _motes.process_material
		pm.initial_velocity_max = 1.4
		pm.spread = 80.0
		_motes.amount_ratio = 1.0


func _process(delta: float) -> void:
	_clock += delta
	if follow == null or not is_instance_valid(follow) or follow.dying:
		vanish()
	_fade = maxf(0.0, _fade - delta / 0.5) if _dying else minf(1.0, _fade + delta / 0.6)
	if _dying and _fade <= 0.0:
		queue_free()
		return
	_flash = maxf(0.0, _flash - delta * 2.5)
	_mat.set_shader_parameter("fade", _fade)
	_mat.set_shader_parameter("flash", _flash)
	if follow == null or not is_instance_valid(follow):
		return
	ap.speed_scale = follow.time_scale
	global_position = global_position.lerp(_home(), 1.0 - exp(-delta * 6.0))
	# 挥砍时转向那个敌人，否则和她朝同一个方向
	var face: float = follow.rotation.y
	if _aiming and ap.current_animation == _attack:
		var d: Vector3 = _aim - global_position
		if Vector2(d.x, d.z).length() > 0.05:
			face = atan2(d.x, d.z)
	else:
		_aiming = false
	rotation.y = lerp_angle(rotation.y, face, 1.0 - exp(-delta * 12.0))
