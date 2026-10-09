class_name BossAura
extends Node3D
## 首领 / 精英的"存在感"：挂在 UnitView 下面(跟着走，不跟着转向)，一直在。
## 首领(mode "boss")：
##   · 缠绕：几条火蛇绕着身体盘旋上下(亮芯 + 拖着黑烟的宽带，面向镜头的带子，ImmediateMesh 每帧重画)
##   · 脚下：一片压暗的焦土圆盘，上面放射状的熔岩裂纹顺着往外流，外圈一道慢慢转的火环；每 BEAT 秒"心跳"一次(裂纹一亮、一道暗红的冲击环往外推)
##   · 往上飘的火星和黑灰
## 精英(mode "elite")：脚下一圈慢转的纹章(身份色) + 往上飘的光点，比首领克制得多。
## 颜色：hot = 最亮的火，mid = 主色(身份色)，smoke = 烟。size = 脚下的半径(米，按体型)，height = 身高(米)。

const BEAT := 2.4
const DISC_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 hot : source_color = vec4(1.0, 0.45, 0.15, 1.0);
uniform vec4 mid : source_color = vec4(0.85, 0.08, 0.06, 1.0);
uniform float beat = 0.0;
uniform float fade = 1.0;
uniform float spin = 0.0;
uniform float boss = 1.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float a = atan(p.y, p.x);
	vec3 col = vec3(0.0);
	float alpha = 0.0;
	if (boss > 0.5) {
		// 焦土：中间最暗，往外淡出
		float dark = (1.0 - smoothstep(0.25, 0.95, r)) * 0.62;
		// 放射状的裂纹：11 条主缝，沿半径弯折、时断时续、粗细不一；外加一段段细的环向支缝
		float wob = (noise(vec2(r * 7.0, a * 2.0 + 3.1)) - 0.5) * 1.6 + (noise(vec2(r * 19.0, a * 5.0)) - 0.5) * 0.5;
		float k = fract(a / 6.2831853 * 11.0 + wob * 0.16);
		float seg = smoothstep(0.32, 0.5, noise(vec2(floor(a / 6.2831853 * 11.0 + wob * 0.16) * 3.7, r * 6.0)));
		float wid = (0.05 + 0.04 * noise(vec2(r * 9.0, a * 4.0))) * (1.15 - r * 0.7);
		float main_c = smoothstep(wid, wid * 0.25, abs(k - 0.5) * (0.55 + r)) * seg;
		float ring_c = smoothstep(0.05, 0.0, abs(fract(r * 3.3 + noise(vec2(a * 3.0, r * 2.0)) * 0.6) - 0.5) * 2.0) * step(0.62, noise(vec2(a * 5.0, floor(r * 3.3) * 7.0)));
		float crack = max(main_c, ring_c * 0.6) * smoothstep(0.1, 0.28, r) * (1.0 - smoothstep(0.78, 0.97, r));
		// 熔岩往外流：沿半径的一道道亮带
		float flow = 0.5 + 0.5 * sin(r * 15.0 - TIME * 3.0 + a * 0.5);
		float heat = crack * (0.45 + 0.55 * flow) * (0.75 + 1.5 * beat);
		// 外圈：一道柔和的火带(往上舔的火舌，慢慢转)
		float tongue = (noise(vec2(a * 8.0 + spin * 2.0, TIME * 1.2)) - 0.5) * 0.07;
		float band = smoothstep(0.075, 0.0, abs(r - 0.86 - tongue)) * (0.45 + 0.55 * noise(vec2(a * 14.0 - spin * 4.0, TIME * 2.0)));
		float rim = band * (0.7 + 0.6 * beat);
		col = mix(vec3(0.02, 0.0, 0.01), mix(mid.rgb, hot.rgb, flow * 0.5) * (1.8 + 2.2 * beat), clamp(heat + rim, 0.0, 1.0));
		alpha = max(dark, clamp(heat * 1.15 + rim * 0.7, 0.0, 1.0));
	} else {
		// 精英的纹章：两道细环 + 环间一圈转动的短划 + 四个菱形
		float ring1 = smoothstep(0.018, 0.0, abs(r - 0.92));
		float ring2 = smoothstep(0.012, 0.0, abs(r - 0.78));
		float aa = a + spin;
		float dash = step(0.5, fract(aa / 6.2831853 * 24.0)) * smoothstep(0.03, 0.0, abs(r - 0.85));
		float dia = 0.0;
		for (int i = 0; i < 4; i++) {
			float ca = float(i) * 1.5707963 - spin * 0.5;
			vec2 c = vec2(cos(ca), sin(ca)) * 0.85;
			vec2 d = abs(p - c);
			dia = max(dia, smoothstep(0.075, 0.05, d.x + d.y));
		}
		float glow = (1.0 - smoothstep(0.4, 1.0, r)) * 0.18;
		float m = clamp(ring1 + ring2 * 0.7 + dash * 0.8 + dia, 0.0, 1.0);
		col = mix(mid.rgb * 0.6, hot.rgb, m) * (1.6 + 1.5 * beat);
		alpha = max(glow * (0.6 + 0.6 * beat), m * (0.75 + 0.25 * beat));
	}
	ALBEDO = col;
	ALPHA = alpha * fade;
}
"""

var mode: String = "boss"
var hot: Color = Color("#ffb04a")
var mid: Color = Color("#e4182a")
var smoke: Color = Color(0.06, 0.02, 0.03)
var size: float = 1.0
var height: float = 2.0
var time_scale: float = 1.0

var _t: float = 0.0
var _beat_t: float = 0.0
var _disc: MeshInstance3D
var _disc_mat: ShaderMaterial
var _ribbons: MeshInstance3D
var _im: ImmediateMesh
var _rmat: StandardMaterial3D
var _particles: Array = []
var _fade: float = 0.0
var _fading_out: bool = false
var _snakes: Array = []          # [{phase, speed, rad, rise, width}]


static func make(p_mode: String, p_hot: Color, p_mid: Color, p_size: float, p_height: float) -> BossAura:
	var a := BossAura.new()
	a.mode = p_mode
	a.hot = p_hot
	a.mid = p_mid
	a.size = p_size
	a.height = p_height
	return a


func _ready() -> void:
	# 地面圆盘
	_disc = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	var dr: float = size * (2.6 if mode == "boss" else 1.55)
	pm.size = Vector2(dr * 2.0, dr * 2.0)
	_disc.mesh = pm
	var sh := Shader.new()
	sh.code = DISC_SHADER
	_disc_mat = ShaderMaterial.new()
	_disc_mat.shader = sh
	_disc_mat.set_shader_parameter("hot", hot)
	_disc_mat.set_shader_parameter("mid", mid)
	_disc_mat.set_shader_parameter("boss", 1.0 if mode == "boss" else 0.0)
	_disc_mat.render_priority = -2
	_disc.material_override = _disc_mat
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_disc.position = Vector3(0, 0.035, 0)
	add_child(_disc)
	if mode == "boss":
		# 缠绕的火蛇
		_im = ImmediateMesh.new()
		_ribbons = MeshInstance3D.new()
		_ribbons.mesh = _im
		_ribbons.top_level = true
		_ribbons.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_rmat = StandardMaterial3D.new()
		_rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_rmat.vertex_color_use_as_albedo = true
		_rmat.vertex_color_is_srgb = true
		_rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_rmat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_rmat.render_priority = 4
		_ribbons.material_override = _rmat
		add_child(_ribbons)
		for i in range(3):
			_snakes.append({"phase": float(i) * TAU / 3.0 + randf() * 0.4, "speed": 1.55 + 0.25 * float(i % 2), "rad": 0.95 + 0.18 * float(i),
				"rise": 0.45 + 0.13 * float(i), "width": 0.085 - 0.012 * float(i), "dir": 1.0 if i != 1 else -1.0})
		_add_particles(hot, 22, 1.4, 0.9, 0.055, true)
		_add_particles(Color(0.08, 0.04, 0.04), 16, 0.6, 2.2, 0.09, false)
		_add_particles(mid, 10, 2.2, 0.7, 0.04, true)
	else:
		_add_particles(hot, 8, 0.9, 1.1, 0.04, true)


## 往上飘的粒子：从脚下的一圈冒出来
func _add_particles(c: Color, amount: int, speed: float, life: float, sz: float, glow: bool) -> void:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = size * (1.25 if mode == "boss" else 0.9)
	pm.emission_ring_inner_radius = size * 0.35
	pm.emission_ring_height = 0.05
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 18.0
	pm.initial_velocity_min = speed * 0.5
	pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, 0.6 if glow else 0.2, 0)
	pm.damping_min = 0.3
	pm.damping_max = 0.8
	pm.tangential_accel_min = 0.6 if mode == "boss" else 0.0
	pm.tangential_accel_max = 1.4 if mode == "boss" else 0.0
	pm.scale_min = 0.6
	pm.scale_max = 1.3
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.2))
	curve.add_point(Vector2(0.25, 1.0))
	curve.add_point(Vector2(1, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	p.process_material = pm
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE * sz
	p.draw_pass_1 = bm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	if glow:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 2.6
	else:
		m.albedo_color = Color(c.r, c.g, c.b, 0.75)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p.material_override = m
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-4, -1, -4), Vector3(8, 8, 8))
	add_child(p)
	_particles.append(p)


func fade_out() -> void:
	_fading_out = true
	for p: GPUParticles3D in _particles:
		p.emitting = false


func _process(delta: float) -> void:
	var dt: float = delta * time_scale
	_t += dt
	_fade = clampf(_fade + (-delta * 1.4 if _fading_out else delta * 1.2), 0.0, 1.0)
	if _fading_out and _fade <= 0.0:
		queue_free()
		return
	for p: GPUParticles3D in _particles:
		p.speed_scale = maxf(0.05, time_scale)
	# 心跳：一下亮、慢慢暗
	_beat_t += dt
	if _beat_t >= BEAT:
		_beat_t -= BEAT
		_pulse()
	var b: float = exp(-_beat_t * 5.0)
	_disc_mat.set_shader_parameter("beat", b)
	_disc_mat.set_shader_parameter("fade", _fade)
	_disc_mat.set_shader_parameter("spin", _t * (0.25 if mode == "boss" else 0.4))
	if mode == "boss":
		_draw_snakes(b)


## 心跳的冲击环：一道贴地的暗红圆环往外推、淡掉
func _pulse() -> void:
	if _fading_out:
		return
	var m := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.95
	tm.outer_radius = 1.0
	tm.rings = 48
	tm.ring_segments = 4
	m.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(mid.r, mid.g, mid.b, 0.5) if mode == "boss" else Color(hot.r, hot.g, hot.b, 0.35)
	mat.emission_enabled = true
	mat.emission = mid if mode == "boss" else hot
	mat.emission_energy_multiplier = 1.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position = Vector3(0, 0.05, 0)
	var r0: float = size * (0.6 if mode == "boss" else 0.8)
	var r1: float = size * (3.4 if mode == "boss" else 1.7)
	m.scale = Vector3(r0, 0.06, r0)
	add_child(m)
	var s: float = maxf(0.2, time_scale)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(m, "scale", Vector3(r1, 0.06, r1), 0.9 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.9 / s).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(m.queue_free)


## 火蛇：沿着螺旋往回取一串点(蛇头在前、尾巴在后)，画成面向镜头的带子——一层宽的黑烟带(稍微落后) + 一层亮的火芯
func _draw_snakes(b: float) -> void:
	_im.clear_surfaces()
	if _fade <= 0.001:
		return
	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() != null else null
	var cam_pos: Vector3 = cam.global_position if cam != null else global_position + Vector3(0, 10, 10)
	var base: Vector3 = global_position
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for layer in range(3):
		for sn: Dictionary in _snakes:
			var pts: Array = []
			var n: int = 40
			for k in range(n):
				var tt: float = _t - float(k) * 0.04 - (0.07 if layer == 0 else 0.0)
				pts.append(_snake_pos(sn, tt, base))
			_ribbon(pts, cam_pos, sn, layer, b)
	_im.surface_end()


## 火蛇的位置：绕身体转，同时上下起伏得比较快 → 看起来是一圈圈往上盘、再往下绕的螺旋
func _snake_pos(sn: Dictionary, tt: float, base: Vector3) -> Vector3:
	var ph: float = float(sn["phase"])
	var th: float = ph + tt * float(sn["speed"]) * float(sn["dir"])
	var r: float = size * float(sn["rad"]) * (1.0 + 0.14 * sin(tt * 2.3 + ph))
	var y: float = height * (0.1 + 0.82 * float(sn["rise"]) * (0.5 + 0.5 * sin(tt * 1.25 + ph * 1.7)))
	return base + Vector3(cos(th) * r, y, sin(th) * r)


## layer 0 = 拖在后面的黑烟(宽)，1 = 火的光晕(中)，2 = 亮芯(细)
func _ribbon(pts: Array, cam_pos: Vector3, sn: Dictionary, layer: int, b: float) -> void:
	var n: int = pts.size()
	var w0: float = float(sn["width"]) * size * [2.6, 1.7, 0.75][layer]
	var prev_l := Vector3.ZERO
	var prev_r := Vector3.ZERO
	var prev_c := Color()
	var ph: float = float(sn["phase"])
	for k in range(n):
		var p: Vector3 = pts[k]
		var tan: Vector3 = (pts[mini(k + 1, n - 1)] - pts[maxi(k - 1, 0)]) as Vector3
		var side: Vector3 = tan.cross(cam_pos - p)
		if side.length() < 1e-5:
			side = Vector3.RIGHT
		side = side.normalized()
		var u: float = float(k) / float(n - 1)            # 0 = 蛇头
		var flick: float = 0.75 + 0.25 * sin(u * 23.0 - _t * 11.0 + ph) * sin(u * 9.0 + _t * 5.0)
		var w: float = w0 * pow(1.0 - u, 0.7) * (0.4 + 0.6 * sin(minf(u * 6.0, PI * 0.5))) * flick
		var c: Color
		if layer == 0:
			c = Color(smoke.r, smoke.g, smoke.b, 0.5 * (1.0 - u) * _fade)
		elif layer == 1:
			var e1: float = 1.0 + 0.4 * b
			c = Color(mid.r * e1, mid.g * e1, mid.b * e1, 0.38 * pow(1.0 - u, 1.2) * _fade)
		else:
			var hotk: float = clampf(1.0 - u * 1.8, 0.0, 1.0)
			var cc: Color = mid.lerp(hot, hotk * 0.9)
			var e: float = 1.1 + 0.6 * hotk + 0.5 * b
			c = Color(cc.r * e, cc.g * e, cc.b * e, pow(1.0 - u, 1.3) * 0.95 * _fade)
		var l: Vector3 = p + side * w
		var r: Vector3 = p - side * w
		if k > 0:
			_tri(prev_l, prev_c, prev_r, prev_c, l, c)
			_tri(prev_r, prev_c, r, c, l, c)
		prev_l = l
		prev_r = r
		prev_c = c


func _tri(a: Vector3, ca: Color, b: Vector3, cb: Color, c: Vector3, cc: Color) -> void:
	_im.surface_set_color(ca)
	_im.surface_add_vertex(a)
	_im.surface_set_color(cb)
	_im.surface_add_vertex(b)
	_im.surface_set_color(cc)
	_im.surface_add_vertex(c)
