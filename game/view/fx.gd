class_name Fx
extends Node3D
## 特效管理：伤害数字、漂字、体素碎屑爆发、扩散圈、斩击弧、投射物外观。全部是一次性节点，自带清理。

const COLORS := {
	"physical": Color("#ffb35a"), "magic": Color("#c39bff"), "true": Color("#ffffff"),
	"heal": Color("#72ff92"), "shield": Color("#9adcff"), "crit": Color("#ffd23a"),
	"trigger": Color("#ffd875"), "gold": Color("#ffd23a"), "buff": Color("#8fc4ff"),
}

const ARROW_CENTER := Vector3(0.0125, 0.0125, 0.28)   # 箭网格(prop_arrow)的中心：箭杆占 x/y 两格，z 从箭尾扣到箭头约 46 格

var arrow_mesh: Mesh
var speed_scale: float = 1.0
var _ring_mesh: TorusMesh
var _box: BoxMesh
var _mat_cache: Dictionary = {}
var _shell_shader: Shader = null
const SHELL_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;
uniform vec4 col : source_color = vec4(1.0);
uniform float fade = 1.0;
void fragment() {
	float f = 1.0 - abs(dot(normalize(NORMAL), normalize(VIEW)));
	float rim = pow(f, 2.2);
	ALBEDO = mix(col.rgb, vec3(1.0), rim * 0.35);
	ALPHA = clamp(rim * 1.25 + 0.1, 0.0, 1.0) * col.a * fade;
}
"""
var _count: int = 0
var _recent: Array = []          # [{p:Vector3, t:int msec}] 最近的漂字，用来错开重叠


func _init() -> void:
	arrow_mesh = load("res://assets/prop_arrow.res")
	_ring_mesh = TorusMesh.new()
	_ring_mesh.inner_radius = 0.92
	_ring_mesh.outer_radius = 1.0
	_ring_mesh.rings = 40
	_ring_mesh.ring_segments = 5
	_box = BoxMesh.new()
	_box.size = Vector3(0.07, 0.07, 0.07)


func _emissive(c: Color, energy: float = 2.5, alpha: float = 1.0) -> StandardMaterial3D:
	var key := "%s|%.1f|%.2f" % [c.to_html(), energy, alpha]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	if alpha < 0.999:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_cache[key] = m
	return m


# ---------------------------------------------------------------- 文字
func number(pos: Vector3, text: String, color: Color, size: float = 1.0, rise: float = 0.9, dur: float = 0.85) -> void:
	if speed_scale < 1.0:
		dur *= speed_scale / maxf(0.5, speed_scale)      # 慢放时飘字最多慢一半，不然堆成一片
	var l := Label3D.new()
	l.text = text
	l.modulate = color
	l.outline_modulate = Color(0.05, 0.05, 0.08, 0.95)
	l.outline_size = 14
	l.font_size = int(58.0 * size)
	l.pixel_size = 0.0058
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 60
	l.shaded = false
	l.position = pos + Vector3(randf_range(-0.22, 0.22), _stack_offset(pos), randf_range(-0.1, 0.1))
	add_child(l)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + rise, dur / speed_scale).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, dur * 0.45 / speed_scale).set_delay(dur * 0.55 / speed_scale)
	tw.tween_property(l, "outline_modulate:a", 0.0, dur * 0.45 / speed_scale).set_delay(dur * 0.55 / speed_scale)
	tw.chain().tween_callback(l.queue_free)
	l.scale = Vector3.ONE * 0.6
	create_tween().tween_property(l, "scale", Vector3.ONE, 0.12 / speed_scale).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## 一次性粒子的播放速度：慢放(×0.5 / ×0.25)时跟着变慢；快进时照常(粒子本身很短，不用加速)
func _pslow() -> float:
	return clampf(speed_scale, 0.2, 1.0)


## 同一处短时间内连续冒字时，逐个抬高，避免叠成一团
func _stack_offset(pos: Vector3) -> float:
	var now: int = Time.get_ticks_msec()
	var window: float = 420.0 / maxf(speed_scale, 0.5)
	var kept: Array = []
	var n := 0
	for r: Dictionary in _recent:
		if float(now - int(r["t"])) < window:
			kept.append(r)
			if (r["p"] as Vector3).distance_to(pos) < 0.7:
				n += 1
	kept.append({"p": pos, "t": now})
	_recent = kept
	return minf(float(n) * 0.24, 0.72)


func damage_number(pos: Vector3, amount: float, kind: String, crit: bool, splash: bool) -> void:
	if amount < 0.5:
		return
	var c: Color = COLORS.get(kind, Color.WHITE)
	var size := 1.0
	var txt := str(int(round(amount)))
	if crit:
		c = COLORS["crit"]
		size = 1.55
		txt += "!"
	elif splash:
		size = 0.8
	elif amount > 300.0:
		size = 1.1
	else:
		size = 0.78
	number(pos, txt, c, size, 0.8, 0.75)


# ---------------------------------------------------------------- 体素碎屑
func burst(pos: Vector3, color: Color, count: int = 10, speed: float = 2.2, size: float = 1.0, up: float = 1.0, life: float = 0.6, glow: bool = true) -> void:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, up, 0)
	pm.spread = 75.0 if up > 0.5 else 180.0
	pm.initial_velocity_min = speed * 0.5
	pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, -7.0, 0)
	pm.scale_min = 0.6 * size
	pm.scale_max = 1.5 * size
	pm.damping_min = 1.0
	pm.damping_max = 2.5
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1.0))
	curve.add_point(Vector2(1, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	p.process_material = pm
	p.draw_pass_1 = _box
	p.material_override = _emissive(color, 2.2) if glow else _solid(color)
	p.amount = count
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 1.0
	p.local_coords = false
	p.emitting = true
	p.position = pos
	p.visibility_aabb = AABB(Vector3(-3, -2, -3), Vector3(6, 6, 6))
	add_child(p)
	p.speed_scale = _pslow()
	get_tree().create_timer((life + 0.4) / _pslow()).timeout.connect(p.queue_free)


func ring(pos: Vector3, radius: float, color: Color, dur: float = 0.5, width: float = 1.0, start_scale: float = 0.15) -> void:
	var m := MeshInstance3D.new()
	m.mesh = _ring_mesh
	var rmat: StandardMaterial3D = _emissive(color, 2.0, 0.85).duplicate() as StandardMaterial3D
	m.material_override = rmat
	m.position = pos + Vector3(0, 0.06, 0)
	m.scale = Vector3(radius * start_scale, 0.10 * width, radius * start_scale)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(m, "scale", Vector3(radius, 0.10 * width, radius), dur / speed_scale).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(rmat, "albedo_color:a", 0.0, dur / speed_scale).set_delay(dur * 0.35 / speed_scale)
	tw.chain().tween_callback(m.queue_free)


## 光柱(召唤/觉醒)
func pillar(pos: Vector3, color: Color, dur: float = 0.7) -> void:
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.34
	cm.bottom_radius = 0.42
	cm.height = 2.6
	cm.radial_segments = 8
	m.mesh = cm
	var mat := _emissive(color, 2.4, 0.5).duplicate() as StandardMaterial3D
	m.material_override = mat
	m.position = pos + Vector3(0, 1.3, 0)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(m, "scale", Vector3(0.2, 1.15, 0.2), dur / speed_scale).set_ease(Tween.EASE_IN)
	tw.tween_property(mat, "albedo_color:a", 0.0, dur / speed_scale)
	tw.chain().tween_callback(m.queue_free)


## 爆炸([溅射] 的落点，法器普攻最常见)：center = 爆心(命中单位时在胸口高度，打地板时贴地)，radius = 溅射半径(米)。
## 分层：①一闪的白热核心 + 点光源照亮周围 ②半透明的冲击波球壳长到溅射半径(把范围交代清楚)
## ③地面两道冲击环 + 焦痕 ④往外崩的发光体素碎屑、慢慢飘起的余烬、深色体素烟团。整体 0.6 秒左右收干净，不挡后面的攻击
func explosion(center: Vector3, radius: float, color: Color, power: float = 1.0) -> void:
	var ground := Vector3(center.x, 0.0, center.z)
	var sat: Color = Color.from_hsv(color.h, clampf(color.s * 1.15 + 0.15, 0.0, 1.0), clampf(color.v, 0.55, 0.95)) if color.s > 0.12 else color.darkened(0.25)
	var hot: Color = sat.lightened(0.7)
	var s: float = maxf(0.2, speed_scale)
	# ① 核心：外层是饱和色的菲涅耳球(边缘亮、中间透)，里面一颗白热的小球；一下子胀开，再缩着淡掉
	var ck: float = minf(radius * 0.55 * power, 1.3)     # 大半径(流星爆魔杖的溅射 3)时核心别把整个屏幕糊白
	var outer := _shell(center, sat, 0.95)
	outer.scale = Vector3.ONE * 0.12
	var inner := MeshInstance3D.new()
	var ism := SphereMesh.new()
	ism.radius = 0.5
	ism.height = 1.0
	ism.radial_segments = 12
	ism.rings = 6
	inner.mesh = ism
	var imat: StandardMaterial3D = _emissive(hot, 5.0, 1.0).duplicate() as StandardMaterial3D
	imat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	inner.material_override = imat
	inner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inner.position = center
	inner.scale = Vector3.ONE * 0.1
	add_child(inner)
	var tc: Tween = create_tween().set_parallel(true)
	tc.tween_property(outer, "scale", Vector3.ONE * ck, 0.07 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tc.tween_property(inner, "scale", Vector3.ONE * ck * 0.55, 0.05 / s).set_ease(Tween.EASE_OUT)
	tc.chain().tween_property(outer, "scale", Vector3.ONE * ck * 1.15, 0.16 / s)
	tc.tween_method(func(v: float) -> void: (outer.material_override as ShaderMaterial).set_shader_parameter("fade", v), 1.0, 0.0, 0.16 / s)
	tc.tween_property(inner, "scale", Vector3.ONE * ck * 0.1, 0.12 / s).set_ease(Tween.EASE_IN)
	tc.tween_property(imat, "albedo_color:a", 0.0, 0.12 / s)
	tc.chain().tween_callback(outer.queue_free)
	tc.tween_callback(inner.queue_free)
	# 点光源：把周围照亮一下(别太亮，白色地面会过曝)
	var light := OmniLight3D.new()
	light.light_color = sat.lightened(0.2)
	light.light_energy = 1.8 * power
	light.omni_range = radius * 2.4
	light.shadow_enabled = false
	light.position = center + Vector3(0, 0.3, 0)
	add_child(light)
	var tl: Tween = create_tween()
	tl.tween_property(light, "light_energy", 0.0, 0.3 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tl.tween_callback(light.queue_free)
	# ② 冲击波球壳：贴地的菲涅耳半球，长到溅射半径(= 实际受波及的范围)
	var dome := _shell(ground, sat, 0.75 if radius < 2.5 else 0.45, true)
	dome.scale = Vector3(radius * 0.3, radius * 0.2, radius * 0.3)
	var td: Tween = create_tween().set_parallel(true)
	td.tween_property(dome, "scale", Vector3(radius, radius * 0.62, radius), 0.28 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	td.tween_method(func(v: float) -> void: (dome.material_override as ShaderMaterial).set_shader_parameter("fade", v), 1.0, 0.0, 0.3 / s).set_delay(0.06 / s)
	td.chain().tween_callback(dome.queue_free)
	# ③ 地面冲击环(粗的饱和色 + 细的白热、快一拍) + 焦痕
	ring(ground, radius, sat, 0.42, 2.2, 0.12)
	ring(ground, radius * 0.85, hot, 0.22, 0.9, 0.05)
	var scorch := MeshInstance3D.new()
	var scm := CylinderMesh.new()
	scm.top_radius = radius * 0.5
	scm.bottom_radius = radius * 0.5
	scm.height = 0.004
	scm.radial_segments = 20
	scorch.mesh = scm
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var dk: Color = sat.darkened(0.8)
	smat.albedo_color = Color(dk.r, dk.g, dk.b, 0.3)
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	scorch.material_override = smat
	scorch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scorch.position = ground + Vector3(0, 0.014, 0)
	add_child(scorch)
	var tsc: Tween = create_tween()
	tsc.tween_property(smat, "albedo_color:a", 0.0, 0.9 / s).set_delay(0.35 / s)
	tsc.tween_callback(scorch.queue_free)
	# ④ 碎屑：饱和色的发光体素往外崩 + 几颗白热的；深色碎块(不发光)抛起来落地；余烬慢慢飘；深色烟团往上翻
	burst(center, sat, int(12 * power), 4.4 * sqrt(radius / 1.2), 1.2, 0.5, 0.45)
	burst(center, hot, int(5 * power), 5.0 * sqrt(radius / 1.2), 0.8, 0.7, 0.3)
	burst(ground + Vector3(0, 0.1, 0), sat.darkened(0.7), int(6 * power), 3.2, 1.7, 1.3, 0.7, false)
	_motes(center, sat.lightened(0.35), int(7 * power), 0.9)
	_smoke(center, sat.darkened(0.6), int(8 * power), radius)


## 菲涅耳球壳(边缘亮、中间透，亮背景上也看得清)：fade 从 1 → 0 淡出；hemi = 贴地的半球
func _shell(pos: Vector3, color: Color, alpha: float, hemi: bool = false) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0 if hemi else 0.5
	sm.height = 1.0
	sm.is_hemisphere = hemi
	sm.radial_segments = 24
	sm.rings = 10
	m.mesh = sm
	if _shell_shader == null:
		_shell_shader = Shader.new()
		_shell_shader.code = SHELL_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _shell_shader
	mat.set_shader_parameter("col", Color(color.r, color.g, color.b, alpha))
	mat.set_shader_parameter("fade", 1.0)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position = pos
	add_child(m)
	return m


func _solid(c: Color) -> StandardMaterial3D:
	var key := "solid|" + c.to_html()
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	_mat_cache[key] = m
	return m


## 残影：把模型此刻的姿势拷一份(骨骼姿势跟着拷过来、动画播放器去掉 = 冻住)，所有网格换成半透明的纯色，原地淡出。
## 冲锋这类位移技能每隔几帧留一个，拉出一串残影
func afterimage(model: Node3D, color: Color, life: float = 0.3, start_alpha: float = 0.55) -> void:
	if model == null or not is_instance_valid(model):
		return
	var g: Node3D = model.duplicate(0) as Node3D
	for c: Node in g.find_children("*", "AnimationPlayer", true, false):
		c.free()
	g.top_level = true
	add_child(g)
	g.global_transform = model.global_transform
	# 骨骼姿势不会随 duplicate 拷过来(动画每帧写进去的)：逐骨抄一遍
	var src_sk: Array[Node] = model.find_children("*", "Skeleton3D", true, false)
	var dst_sk: Array[Node] = g.find_children("*", "Skeleton3D", true, false)
	if not src_sk.is_empty() and not dst_sk.is_empty():
		var a0 := src_sk[0] as Skeleton3D
		var b0 := dst_sk[0] as Skeleton3D
		for bi in range(a0.get_bone_count()):
			b0.set_bone_pose_position(bi, a0.get_bone_pose_position(bi))
			b0.set_bone_pose_rotation(bi, a0.get_bone_pose_rotation(bi))
			b0.set_bone_pose_scale(bi, a0.get_bone_pose_scale(bi))
	var mat: StandardMaterial3D = _mat_cache.get("ghost|" + color.to_html(), null)
	if mat == null:
		mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_cache["ghost|" + color.to_html()] = mat
	var meshes: Array[Node] = g.find_children("*", "MeshInstance3D", true, false)
	var tw: Tween = create_tween().set_parallel(true)
	for n: Node in meshes:
		var mi := n as MeshInstance3D
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.transparency = 1.0 - start_alpha
		tw.tween_property(mi, "transparency", 1.0, life / maxf(0.2, speed_scale)).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(g.queue_free)


## 龙息(虚荣的余烬)：从嘴里沿 dir 喷出一道宽 width、长 length 的火流——一大团往前冲的火焰粒子 + 贴地一条发光的焦痕
## 龙息(虚荣的余烬)：从嘴(mouth，世界坐标)往前下方喷到射线的尽头(end，贴地)——
## 一股柔光的火焰洪流(白热 → 橙 → 暗红 → 烟)沿着这条斜线冲下去、越远越大，一层黑烟落在后面，迸飞的火星块；
## 火落地的那一段地面烧起一串火团和焦痕，被喷到的人(hits = 胸口位置)身上各炸一团火
func breath(mouth: Vector3, end: Vector3, width: float, hits: Array = []) -> void:
	var flat: Vector3 = Vector3(end.x - mouth.x, 0.0, end.z - mouth.z)
	var reach: float = flat.length()
	if reach < 0.3:
		return
	var hd: Vector3 = flat / reach
	# 火流从高处斜着往下喷，砸在最近的那个被喷到的人身上(没有人就砸在射线中段)，再顺着地面往射线尽头烧过去
	var land: Vector3 = Vector3(mouth.x, 0.5, mouth.z) + hd * reach * 0.55
	var best: float = 1e9
	for h0: Variant in hits:
		var hp0: Vector3 = h0
		var dd: float = Vector3(hp0.x - mouth.x, 0.0, hp0.z - mouth.z).length()
		if dd < best:
			best = dd
			land = Vector3(hp0.x, hp0.y * 0.7, hp0.z)
	var aim: Vector3 = land - mouth
	var length: float = aim.length()
	# 一股很快的火柱：0.15 秒就砸到人身上(伤害数字是出手那一刻就跳的，火要跟得上)，然后接着往下灌 0.35 秒
	var s0: float = maxf(0.3, speed_scale)
	var travel: float = 0.15 / s0
	var pour: float = 0.35 / s0
	var life: float = travel * 1.35
	var basis := Basis.looking_at(-aim.normalized(), Vector3.UP)
	var spread: float = rad_to_deg(atan2(width * 0.5, length)) * 1.05
	var layers: Array = [
		[SoftFX.fire_ramp(Color("#ff5a1a"), 1.2), 60, 0.7, true, 1.0, 1.0],
		[SoftFX.fire_ramp(Color("#ffa030"), 1.15, false), 24, 0.4, true, 0.9, 0.85],
		[SoftFX.ramp([Color(0.1, 0.06, 0.05, 0.0), Color(0.12, 0.07, 0.06, 0.4), Color(0.08, 0.05, 0.05, 0.0)], [0.0, 0.4, 1.0]), 18, 0.9, false, 0.55, 2.2],
	]
	for L: Array in layers:
		var p := SoftFX.particles(int(L[1]), life * float(L[5]), L[0], float(L[2]), bool(L[3]))
		var pm: ParticleProcessMaterial = p.process_material
		pm.direction = Vector3(0, 0, 1)
		pm.spread = spread
		pm.initial_velocity_min = length / travel * 0.9 * float(L[4])
		pm.initial_velocity_max = length / travel * 1.05 * float(L[4])
		pm.gravity = Vector3(0, 0.6, 0)
		pm.damping_min = 0.4
		pm.damping_max = 1.0
		var curve := Curve.new()
		curve.add_point(Vector2(0, 0.3))
		curve.add_point(Vector2(0.5, 1.0))
		curve.add_point(Vector2(1, 1.5))
		var ct := CurveTexture.new()
		ct.curve = curve
		pm.scale_curve = ct
		p.visibility_aabb = AABB(Vector3(-length, -length, -length), Vector3(length * 2.0, length * 2.0, length * 2.0))
		add_child(p)
		p.global_transform = Transform3D(basis, mouth)
		p.emitting = true
		p.speed_scale = _pslow()
		var pp: GPUParticles3D = p
		get_tree().create_timer(pour / _pslow()).timeout.connect(func() -> void:
			if is_instance_valid(pp):
				pp.emitting = false)
		get_tree().create_timer((pour + life * 2.4 + 0.3) / _pslow()).timeout.connect(p.queue_free)
	var sp := GPUParticles3D.new()
	var spm := ParticleProcessMaterial.new()
	spm.direction = Vector3(0, 0, 1)
	spm.spread = spread * 1.2
	spm.initial_velocity_min = length / travel * 0.75
	spm.initial_velocity_max = length / travel * 1.1
	spm.gravity = Vector3(0, -4.0, 0)
	spm.scale_min = 0.5
	spm.scale_max = 1.0
	sp.process_material = spm
	sp.draw_pass_1 = _box
	sp.material_override = _emissive(Color("#ffd35a"), 3.0)
	sp.amount = 20
	sp.lifetime = life
	sp.local_coords = false
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sp.visibility_aabb = AABB(Vector3(-length, -length, -length), Vector3(length * 2.0, length * 2.0, length * 2.0))
	add_child(sp)
	sp.global_transform = Transform3D(basis, mouth)
	sp.emitting = true
	sp.speed_scale = _pslow()
	get_tree().create_timer(pour / _pslow()).timeout.connect(func() -> void:
		if is_instance_valid(sp):
			sp.emitting = false)
	get_tree().create_timer((pour + life + 0.5) / _pslow()).timeout.connect(sp.queue_free)
	soft_flash(mouth, Color("#ff8a2a"), 0.9, 0.25, 1.2)
	# 火砸到地上之后：从落点顺着射线往尽头一路烧过去，一串火团 + 焦痕(一团接一团)
	var g0: Vector3 = Vector3(mouth.x, 0.0, mouth.z)
	var k0: float = clampf(Vector3(land.x - mouth.x, 0.0, land.z - mouth.z).length() / reach, 0.0, 0.95)
	var n: int = maxi(3, int(reach * (1.0 - k0) / 0.8) + 1)
	var t_land: float = travel
	for i in range(n):
		var k: float = lerpf(k0, 1.0, float(i) / float(maxi(1, n - 1)))
		var at: Vector3 = g0 + hd * reach * k
		var rr: float = lerpf(0.55, width * 0.5, (k - k0) / maxf(0.05, 1.0 - k0))
		get_tree().create_timer(t_land + 0.05 * float(i) / s0).timeout.connect(func() -> void:
			fire_puff(at + Vector3(0, 0.2, 0), Color("#ff5a1a"), 5, rr * 0.8, 1.2, 0.5, 1.2)
			scorch(at, rr, Color("#ff5a1a"), 2.0))
	# 喷到的人：火流到达时身上炸一团火
	for h: Variant in hits:
		var hp: Vector3 = h
		var kk: float = clampf((Vector3(hp.x - mouth.x, 0.0, hp.z - mouth.z).length() / reach - k0) / maxf(0.05, 1.0 - k0), 0.0, 1.0)
		get_tree().create_timer(t_land + 0.05 * float(n) * kk / s0).timeout.connect(func() -> void:
			soft_flash(hp, Color("#ff7a22"), 0.9, 0.22, 1.3)
			fire_puff(hp, Color("#ff5a1a"), 8, 0.4, 1.6, 0.5, 0.8)
			burst(hp, Color("#ffb03a"), 6, 2.4, 0.6, 0.8, 0.4))


## 冲锋在地上犁出的一道拖痕(from → to，贴地的细长条，淡出)，起点扬一小撮尘土
func streak(from: Vector3, to: Vector3, color: Color, width: float = 0.4, life: float = 0.45) -> void:
	var d: Vector3 = to - from
	d.y = 0.0
	var len: float = d.length()
	if len < 0.1:
		return
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, 0.006, len)
	m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(color.r, color.g, color.b, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	var mid: Vector3 = (from + to) * 0.5
	m.global_transform = Transform3D(Basis.looking_at(d.normalized(), Vector3.UP), Vector3(mid.x, 0.02, mid.z))
	var tw: Tween = create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, life / maxf(0.2, speed_scale)).set_delay(0.1 / maxf(0.2, speed_scale))
	tw.tween_callback(m.queue_free)
	burst(Vector3(from.x, 0.1, from.z), Color("#b9a58c"), 7, 2.0, 1.4, 0.6, 0.45, false)


## 落地旋斩：齐胸高的一圈斩击光环(粗的武器色 + 细的白)快速张开、转着淡出；地上一圈尘土冲击环 + 碎石
func spin_slash(center: Vector3, radius: float, color: Color) -> void:
	var s: float = maxf(0.2, speed_scale)
	for layer: Array in [[color, 0.55, 1.0, 0.28, 1.0], [Color(1, 1, 1), 0.62, 0.92, 0.18, 0.45]]:
		var m := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.86
		tm.outer_radius = 1.0
		tm.rings = 48
		tm.ring_segments = 4
		m.mesh = tm
		var mat: StandardMaterial3D = _emissive(layer[0] as Color, 2.2, 0.9).duplicate() as StandardMaterial3D
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.position = Vector3(center.x, float(layer[1]), center.z)
		m.scale = Vector3(radius * 0.45, float(layer[4]) * 0.9, radius * 0.45)
		add_child(m)
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(m, "scale", Vector3(radius * float(layer[2]), float(layer[4]) * 0.5, radius * float(layer[2])), float(layer[3]) / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(m, "rotation:y", -PI * 0.8, float(layer[3]) / s)
		tw.tween_property(mat, "albedo_color:a", 0.0, float(layer[3]) / s).set_delay(float(layer[3]) * 0.4 / s)
		tw.chain().tween_callback(m.queue_free)
	var ground := Vector3(center.x, 0.0, center.z)
	ring(ground, radius * 1.05, Color("#c9b59a"), 0.4, 1.6, 0.2)
	burst(ground + Vector3(0, 0.1, 0), Color("#8f8474"), 9, 3.0, 1.5, 1.0, 0.55, false)


## 天降火流星(灾星节点)：从斜上方的天空砸向 to(fall 秒，越落越快)。size：1 = 普攻的小流星，2 左右 = 流星爆魔杖的大流星。
##   流星本体：一块翻滚的焦黑岩石(裂缝里透出熔岩光)，外面裹着一团往后吹的火焰(叠加的亮芯 + 普通混合的火身)，
##   身后拖一条宽的火焰光带(RibbonTrail) + 一路灰黑的烟 + 迸出去的火星；越接近地面把地面照得越亮
##   落点：warn_radius > 0 时地上先出一个预警(往里收的圈 + 一片越来越红的地面 + 准星)
##   落地：meteor_impact(火球腾起、熔岩迸溅、碎石、尘土冲击波、焦坑、冲击环、往上飘的烟柱和余烬)
## 实际的伤害 / 溅射由逻辑层在同一刻结算；溅射事件那边不再另外画爆炸(只补一圈溅射范围的冲击环)
func meteor(to: Vector3, fall: float, color: Color, size: float = 1.0, warn_radius: float = 0.0) -> void:
	var s: float = maxf(0.2, speed_scale)
	var dur: float = fall / s
	var ground := Vector3(to.x, 0.0, to.z)
	if warn_radius > 0.0:
		_meteor_warn(ground, warn_radius, dur, color, size)
	var m := Node3D.new()
	var start: Vector3 = to + Vector3(-1.9, 8.5, 1.6) * (0.85 + 0.15 * size)
	m.position = start
	add_child(m)
	# 岩石：几块焦黑的方块拼成的不规则石头，一直在翻滚；裂缝的亮度随下落越来越亮
	var rock := Node3D.new()
	m.add_child(rock)
	var rmat := StandardMaterial3D.new()
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED      # 不吃流星自己的灯(不然整块被照成橙色的方块)
	rmat.albedo_color = Color(0.1, 0.06, 0.05)
	var hot := StandardMaterial3D.new()
	hot.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hot.albedo_color = Color(1.0, 0.55, 0.15) * 1.5
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	var rs: float = 0.11 * size
	for pc: Array in [[Vector3(0, 0, 0), Vector3(1.6, 1.4, 1.5), rmat], [Vector3(0.7, 0.4, -0.3), Vector3(1.0, 1.0, 1.1), rmat],
			[Vector3(-0.6, -0.4, 0.4), Vector3(1.1, 0.9, 0.9), rmat], [Vector3(0.2, 0.7, 0.6), Vector3(0.8, 0.7, 0.8), rmat],
			[Vector3(-0.2, 0.1, -0.8), Vector3(0.55, 0.55, 0.55), hot], [Vector3(0.5, -0.6, 0.5), Vector3(0.45, 0.45, 0.45), hot]]:
		var b := MeshInstance3D.new()
		b.mesh = bm
		b.material_override = pc[2]
		b.position = (pc[0] as Vector3) * rs
		b.scale = (pc[1] as Vector3) * rs
		b.rotation = Vector3(randf() * 0.6, randf() * 0.6, randf() * 0.6)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		rock.add_child(b)
	var spin: Tween = rock.create_tween().set_loops()
	spin.tween_property(rock, "rotation", Vector3(TAU, TAU * 0.6, TAU * 0.3), 0.7).from(Vector3.ZERO)
	# 包着它的火：亮芯(叠加，小) + 火身(普通混合，白地上也看得见)，都往后(远离落点)吹
	var back: Vector3 = (start - to).normalized()
	for L: Array in [[SoftFX.fire_ramp(Color("#ff8a2a"), 1.2, false), int(14 * size), 0.16, 0.13 * size, true],
			[SoftFX.ramp([Color(1.0, 0.75, 0.25, 0.0), Color(1.0, 0.5, 0.08, 1.0), Color(0.85, 0.16, 0.03, 0.9), Color(0.35, 0.06, 0.02, 0.6),
				Color(0.12, 0.05, 0.04, 0.0)], [0.0, 0.1, 0.4, 0.7, 1.0]), int(46 * size), 0.42, 0.26 * size, false]]:
		var p: GPUParticles3D = SoftFX.particles(int(L[1]), float(L[2]), L[0], float(L[3]), bool(L[4]))
		var pm: ParticleProcessMaterial = p.process_material
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 0.1 * size
		pm.direction = back
		pm.spread = 40.0
		pm.initial_velocity_min = 0.1
		pm.initial_velocity_max = 1.6
		pm.gravity = Vector3(0, 0.6, 0)
		(p.material_override as StandardMaterial3D).disable_fog = true
		p.visibility_aabb = AABB(Vector3(-6, -10, -6), Vector3(12, 20, 12))
		p.emitting = true
		p.name = "Fire"
		m.add_child(p)
	# 火焰头：跟着岩石走(局部坐标)的一团火，把岩石整个裹住、往后吹成彗星头的形状
	var head: GPUParticles3D = SoftFX.particles(int(26 * size), 0.22, SoftFX.ramp([Color(1.0, 0.8, 0.35, 0.0), Color(1.0, 0.55, 0.12, 0.95),
		Color(0.95, 0.25, 0.05, 0.8), Color(0.4, 0.08, 0.03, 0.0)], [0.0, 0.12, 0.55, 1.0]), 0.3 * size, false)
	var hpm: ParticleProcessMaterial = head.process_material
	hpm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	hpm.emission_sphere_radius = 0.12 * size
	hpm.direction = back
	hpm.spread = 35.0
	hpm.initial_velocity_min = 0.5 * size
	hpm.initial_velocity_max = 1.6 * size
	hpm.gravity = Vector3.ZERO
	(head.material_override as StandardMaterial3D).disable_fog = true
	head.local_coords = true
	head.emitting = true
	head.name = "FireHead"
	m.add_child(head)
	var glow := MeshInstance3D.new()
	glow.mesh = SoftFX.quad(1.0)
	var gmat: StandardMaterial3D = SoftFX.sprite_mat(Color("#ff8a2a"), 1.2, true)
	gmat.albedo_color.a = 0.7
	gmat.disable_fog = true
	glow.material_override = gmat
	glow.scale = Vector3.ONE * 0.75 * size
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.add_child(glow)
	# 烟：灰黑的一路拖在后面，慢慢散开
	var smoke: GPUParticles3D = SoftFX.particles(int(30 * size), 1.2, SoftFX.ramp([Color(0.12, 0.09, 0.08, 0.0), Color(0.14, 0.1, 0.09, 0.7),
		Color(0.24, 0.21, 0.2, 0.4), Color(0.32, 0.3, 0.29, 0.0)], [0.0, 0.12, 0.5, 1.0]), 0.32 * size, false)
	var smp: ParticleProcessMaterial = smoke.process_material
	smp.direction = back
	smp.spread = 30.0
	smp.initial_velocity_min = 0.1
	smp.initial_velocity_max = 0.4
	smp.gravity = Vector3(0, 0.35, 0)
	smoke.visibility_aabb = AABB(Vector3(-8, -10, -8), Vector3(16, 20, 16))
	smoke.emitting = true
	smoke.name = "Smoke"
	m.add_child(smoke)
	# 火星：往外迸
	var sp := SoftFX.particles(int(16 * size), 0.5, SoftFX.ramp([Color(1.0, 0.95, 0.6, 0.0), Color(1.0, 0.8, 0.35, 1.0), Color(1.0, 0.35, 0.08, 0.0)],
		[0.0, 0.1, 1.0]), 0.04 * size, true)
	var spm: ParticleProcessMaterial = sp.process_material
	spm.direction = back
	spm.spread = 60.0
	spm.initial_velocity_min = 1.5
	spm.initial_velocity_max = 3.5
	spm.gravity = Vector3(0, -6.0, 0)
	(sp.material_override as StandardMaterial3D).disable_fog = true
	sp.visibility_aabb = AABB(Vector3(-8, -10, -8), Vector3(16, 20, 16))
	sp.emitting = true
	sp.name = "Sparks"
	m.add_child(sp)
	# 火焰光带
	var rib: RibbonTrail = RibbonTrail.create(m, Color("#ff4a12"), 0.07 * size, 0.14)
	rib.time_scale = s
	rib.name = "Ribbon"
	m.add_child(rib)
	var light := OmniLight3D.new()
	light.light_color = Color("#ff8a3a")
	light.light_energy = 0.4
	light.omni_range = 2.5 * size
	light.shadow_enabled = false
	light.position = back * 0.6                   # 灯在火焰里、岩石后面
	m.add_child(light)
	var tw: Tween = create_tween()
	tw.tween_method(func(k: float) -> void:
		if not is_instance_valid(m):
			return
		var e: float = k * k
		m.position = start.lerp(to, e)
		light.light_energy = 0.4 + 2.2 * size * k
		rmat.albedo_color = Color(0.1, 0.06, 0.05).lerp(Color(0.35, 0.1, 0.04), k), 0.0, 1.0, dur)
	tw.tween_callback(_meteor_land.bind(m, to, color, size))


## 落点预警：一圈往里收的圈、一片越来越红的地面(普通混合)、中心一个十字准星；size 大的(流星爆魔杖)再加一圈慢慢转的刻度
func _meteor_warn(ground: Vector3, radius: float, dur: float, color: Color, size: float) -> void:
	var wm := MeshInstance3D.new()
	wm.mesh = _ring_mesh
	var wmat: StandardMaterial3D = _emissive(color, 1.6, 0.7).duplicate() as StandardMaterial3D
	wm.material_override = wmat
	wm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wm.position = ground + Vector3(0, 0.05, 0)
	wm.scale = Vector3(radius, 0.08, radius)
	add_child(wm)
	var disc := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2.0, 2.0)
	disc.mesh = pm
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.albedo_texture = SoftFX._texture()
	dm.albedo_color = Color(1.0, 0.25, 0.05, 0.0)
	dm.disable_fog = true
	dm.render_priority = -1
	disc.material_override = dm
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	disc.position = ground + Vector3(0, 0.03, 0)
	disc.scale = Vector3(radius, 1.0, radius)
	add_child(disc)
	var cross := Node3D.new()
	cross.position = ground + Vector3(0, 0.06, 0)
	add_child(cross)
	var cm: StandardMaterial3D = _emissive(Color("#ffd27a"), 2.0, 0.9).duplicate() as StandardMaterial3D
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(1.0, 0.02, 0.06)
	for r0 in [0.0, PI * 0.5]:
		var c := MeshInstance3D.new()
		c.mesh = bmesh
		c.material_override = cm
		c.scale = Vector3(radius * 0.5, 1.0, 1.0)
		c.rotation.y = r0
		c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cross.add_child(c)
	var tw0: Tween = create_tween().set_parallel(true)
	tw0.tween_property(wm, "scale", Vector3(radius * 0.2, 0.08, radius * 0.2), dur).set_ease(Tween.EASE_IN)
	tw0.tween_property(wmat, "albedo_color:a", 0.95, dur)
	tw0.tween_property(dm, "albedo_color:a", 0.45, dur).set_ease(Tween.EASE_IN)
	tw0.tween_property(cross, "rotation:y", PI * 0.5 * (1.0 + size), dur)
	tw0.chain().tween_callback(func() -> void:
		wm.queue_free()
		disc.queue_free()
		cross.queue_free())


## 流星落地：本体没了(火 / 烟 / 光带留在原地散完)，然后炸
func _meteor_land(m: Variant, to: Vector3, color: Color, size: float) -> void:
	if is_instance_valid(m):
		var mn: Node3D = m
		for nm: String in ["Fire", "Smoke", "Sparks", "Ribbon"]:
			for ch: Node in mn.get_children():
				if not String(ch.name).begins_with(nm):
					continue
				var c3: Node3D = ch
				var gx: Transform3D = c3.global_transform
				mn.remove_child(c3)
				add_child(c3)
				c3.global_transform = gx
				if c3 is GPUParticles3D:
					(c3 as GPUParticles3D).emitting = false
					get_tree().create_timer((c3 as GPUParticles3D).lifetime + 0.3).timeout.connect(c3.queue_free)
				elif c3 is RibbonTrail:
					(c3 as RibbonTrail).detach()
		mn.queue_free()
	meteor_impact(to, color, size)


## 流星砸地的爆炸：白热的一闪 → 一团火球往上翻滚(叠加的亮火 + 普通混合的火身)→ 熔岩滴迸溅、焦黑碎石崩开、尘土冲击波、
## 地上砸出一个焦坑(外圈发光的余烬边)、冲击环；之后一柱灰黑的烟慢慢往上飘，余烬闪着熄灭。size 1 = 普攻，2 = 流星爆魔杖
func meteor_impact(at: Vector3, color: Color, size: float = 1.0) -> void:
	var g := Vector3(at.x, 0.0, at.z)
	var k: float = size
	soft_flash(at + Vector3(0.0, 0.2, 0.0), Color("#ffd8a0"), 0.55 * k, 0.1, 1.6)
	soft_flash(at + Vector3(0.0, 0.3, 0.0), Color("#ff5a1a"), 1.1 * k, 0.25, 1.0)
	fire_puff(at + Vector3(0.0, 0.1, 0.0), Color("#ff7a1a"), int(6 * k), 0.3 * k, 1.4 * k, 0.45, 1.2)
	# 火球(普通混合：饱和的橙红往上翻滚、外圈变成黑烟)——白地上也是一团火，不是一片白光
	var fb: GPUParticles3D = SoftFX.particles(int(12 * k), 0.7, SoftFX.ramp([Color(1.0, 0.8, 0.3, 0.0), Color(1.0, 0.55, 0.1, 1.0), Color(0.9, 0.2, 0.04, 0.95),
		Color(0.3, 0.07, 0.03, 0.75), Color(0.12, 0.08, 0.07, 0.0)], [0.0, 0.08, 0.3, 0.6, 1.0]), 0.4 * k, false)
	var fbm: ParticleProcessMaterial = fb.process_material
	fbm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	fbm.emission_sphere_radius = 0.2 * k
	fbm.direction = Vector3(0, 1, 0)
	fbm.spread = 70.0
	fbm.initial_velocity_min = 0.6 * k
	fbm.initial_velocity_max = 1.8 * k
	fbm.gravity = Vector3(0, 1.4, 0)
	fbm.damping_min = 2.0
	fbm.damping_max = 3.5
	(fb.material_override as StandardMaterial3D).disable_fog = true
	fb.one_shot = true
	fb.explosiveness = 0.9
	fb.emitting = true
	add_child(fb)
	fb.global_position = at + Vector3(0.0, 0.15, 0.0)
	fb.speed_scale = _pslow()
	get_tree().create_timer(1.2 / _pslow()).timeout.connect(fb.queue_free)
	lava_splash(at + Vector3(0.0, 0.1, 0.0), 0.8 * k, Color("#ff6a1a"))
	debris(g, Vector3.ZERO, int(10 * k), 3.6 * sqrt(k), Color(0.12, 0.08, 0.07))
	dust_ring(g, 1.1 * k, int(10 * k), 0.4 * k, 0.7)
	scorch(g, 0.65 * k, Color("#ff6a1a"), 2.4 + 0.6 * k)
	ring(g + Vector3(0.0, 0.04, 0.0), 1.2 * k, Color("#ff7a2a"), 0.35, 1.4, 0.12)
	# 烟柱
	var smoke: GPUParticles3D = SoftFX.particles(int(10 * k), 1.6, SoftFX.ramp([Color(0.2, 0.17, 0.16, 0.0), Color(0.24, 0.2, 0.19, 0.5),
		Color(0.32, 0.3, 0.29, 0.28), Color(0.38, 0.36, 0.35, 0.0)], [0.0, 0.15, 0.6, 1.0]), 0.4 * k, false)
	var spm: ParticleProcessMaterial = smoke.process_material
	spm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spm.emission_sphere_radius = 0.25 * k
	spm.direction = Vector3(0, 1, 0)
	spm.spread = 15.0
	spm.initial_velocity_min = 0.4
	spm.initial_velocity_max = 0.9
	spm.gravity = Vector3(0, 0.3, 0)
	spm.damping_min = 0.3
	spm.damping_max = 0.6
	smoke.one_shot = true
	smoke.explosiveness = 0.6
	smoke.emitting = true
	add_child(smoke)
	smoke.global_position = g + Vector3(0.0, 0.3, 0.0)
	smoke.speed_scale = _pslow()
	get_tree().create_timer(2.2 / _pslow()).timeout.connect(smoke.queue_free)
	_motes(g + Vector3(0.0, 0.3, 0.0), Color("#ffb04a"), int(6 * k), 1.0)


## 余烬：几颗小亮点从爆心慢慢飘起、闪着熄灭
func _motes(pos: Vector3, color: Color, count: int, life: float) -> void:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.35
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 55.0
	pm.initial_velocity_min = 0.4
	pm.initial_velocity_max = 1.1
	pm.gravity = Vector3(0, 0.6, 0)
	pm.damping_min = 0.6
	pm.damping_max = 1.2
	pm.scale_min = 0.35
	pm.scale_max = 0.7
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1.0))
	curve.add_point(Vector2(0.7, 0.8))
	curve.add_point(Vector2(1, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	p.process_material = pm
	p.draw_pass_1 = _box
	p.material_override = _emissive(color, 3.0)
	p.amount = maxi(1, count)
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 0.85
	p.local_coords = false
	p.emitting = true
	p.position = pos
	p.visibility_aabb = AABB(Vector3(-3, -2, -3), Vector3(6, 6, 6))
	add_child(p)
	p.speed_scale = _pslow()
	get_tree().create_timer((life + 0.4) / _pslow()).timeout.connect(p.queue_free)


## 烟团：深色半透明体素块从爆心往外、往上翻滚，先胀大再淡掉
func _smoke(pos: Vector3, color: Color, count: int, radius: float) -> void:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.2
	pm.direction = Vector3(0, 0.6, 0)
	pm.spread = 80.0
	pm.initial_velocity_min = 0.9 * radius
	pm.initial_velocity_max = 1.6 * radius
	pm.gravity = Vector3(0, 0.9, 0)
	pm.damping_min = 3.0
	pm.damping_max = 4.5
	pm.angle_min = -40.0
	pm.angle_max = 40.0
	pm.angular_velocity_min = -90.0
	pm.angular_velocity_max = 90.0
	pm.scale_min = 1.8
	pm.scale_max = 3.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.5))
	curve.add_point(Vector2(0.35, 1.0))
	curve.add_point(Vector2(1, 0.7))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.55))
	grad.set_color(1, Color(1, 1, 1, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	p.process_material = pm
	p.draw_pass_1 = _box
	var key := "smoke|" + color.to_html()
	var mat: StandardMaterial3D = _mat_cache.get(key, null)
	if mat == null:
		mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.vertex_color_use_as_albedo = true
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat_cache[key] = mat
	p.material_override = mat
	p.amount = maxi(1, count)
	p.lifetime = 0.8
	p.one_shot = true
	p.explosiveness = 0.9
	p.local_coords = false
	p.emitting = true
	p.position = pos
	p.visibility_aabb = AABB(Vector3(-3, -2, -3), Vector3(6, 6, 6))
	add_child(p)
	p.speed_scale = _pslow()
	get_tree().create_timer(1.2 / _pslow()).timeout.connect(p.queue_free)


## 斩击弧：在 pos 处，沿 dir(水平方向) 出现一个新月形，快速淡出
## 稻田(地形)：泥埂围着一汪浅水，水里一行行秧苗；长出来时从中心铺开，秧苗轻轻摆。返回节点，结束时交给 remove_field
func paddy(pos: Vector3, radius: float) -> Node3D:
	var n := Node3D.new()
	n.position = pos + Vector3(0, 0.012, 0)
	add_child(n)
	var water := MeshInstance3D.new()
	var wm := CylinderMesh.new()
	wm.top_radius = radius
	wm.bottom_radius = radius
	wm.height = 0.03
	wm.radial_segments = 40
	water.mesh = wm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.56, 0.5, 0.82)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.15
	mat.metallic_specular = 0.8
	water.material_override = mat
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(water)
	var rim := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = radius - 0.06
	tm.outer_radius = radius + 0.07
	tm.rings = 40
	tm.ring_segments = 6
	rim.mesh = tm
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color("#7a5a36")
	rim.material_override = rm
	rim.scale = Vector3(1.0, 0.45, 1.0)
	n.add_child(rim)
	# 秧苗：一行行的小绿方块(每簇两三根，高矮不一)
	var sprout := BoxMesh.new()
	sprout.size = Vector3(0.035, 0.14, 0.035)
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color("#7cc64a")
	var sm2 := StandardMaterial3D.new()
	sm2.albedo_color = Color("#a8dd66")
	var sway := Node3D.new()
	n.add_child(sway)
	var step := 0.3
	var rows: int = int(radius / step)
	for ix in range(-rows, rows + 1):
		for iz in range(-rows, rows + 1):
			var p2 := Vector2(ix * step, iz * step + (0.5 * step if ix % 2 == 0 else 0.0))
			if p2.length() > radius - 0.14:
				continue
			for k in 3:
				var s := MeshInstance3D.new()
				s.mesh = sprout
				s.material_override = sm if k != 1 else sm2
				var h: float = 0.75 + 0.35 * float((ix * 7 + iz * 13 + k * 5) % 5) / 4.0
				s.scale = Vector3(1.0, h, 1.0)
				s.position = Vector3(p2.x + (k - 1) * 0.03, 0.07 * h, p2.y + (k % 2) * 0.02)
				s.rotation = Vector3(0.0, 0.0, (k - 1) * 0.25)
				s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				sway.add_child(s)
	n.scale = Vector3(0.15, 1.0, 0.15)
	var tw: Tween = n.create_tween()
	tw.tween_property(n, "scale", Vector3.ONE, 0.35 / speed_scale).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var ts: Tween = n.create_tween().set_loops()
	ts.tween_property(sway, "rotation:z", 0.05, 0.9).set_trans(Tween.TRANS_SINE)
	ts.tween_property(sway, "rotation:z", -0.05, 0.9).set_trans(Tween.TRANS_SINE)
	ring(pos, radius, Color("#9be36a"), 0.5, 1.2, 0.3)
	return n


## 增幅力场(HV 场域载具)：地上一片六边形网格的光盘(青色叠加 + 深藏青的普通混合描边：淡蓝白的地面上也看得见)，
## 一圈圈的光波从中心往外推，边缘一道亮环 + 一圈慢慢转的刻度；场里往上飘的青色小方块(增幅的数据)；中心一团柔光
const AMP_HEX_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 col : source_color = vec4(0.3, 0.82, 1.0, 1.0);
uniform float fade = 1.0;
uniform float pulse = 0.0;
uniform float scale_k = 5.0;
float hexd(vec2 p) { p = abs(p); return max(dot(p, normalize(vec2(1.0, 1.732))), p.x); }
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) { discard; }
	vec2 q = p * scale_k;
	vec2 s = vec2(1.0, 1.732);
	vec2 a = mod(q, s) - s * 0.5;
	vec2 b = mod(q - s * 0.5, s) - s * 0.5;
	vec2 gv = dot(a, a) < dot(b, b) ? a : b;
	float line = smoothstep(0.40, 0.47, hexd(gv));
	float wave = pow(0.5 + 0.5 * sin(r * 14.0 - TIME * 3.2), 3.0);
	float rim = smoothstep(0.90, 0.965, r) * (1.0 - smoothstep(0.98, 1.0, r));
	float ang = atan(p.y, p.x) + TIME * 0.4;
	float ticks = step(0.6, fract(ang * 36.0 / 6.2831853)) * smoothstep(0.82, 0.84, r) * (1.0 - smoothstep(0.865, 0.885, r));
	float core = exp(-r * r * 10.0) * 0.8;
	float v = line * (0.18 + 0.55 * wave) * (0.35 + 0.65 * r) + rim * 1.3 + ticks * 0.8 + core;
	ALBEDO = col.rgb * v * (1.0 + 0.8 * pulse);
	ALPHA = clamp(v, 0.0, 1.0) * fade;
}
"""
var _amp_hex_shader: Shader = null
var _amp_hex_tint: Shader = null
const MECH_CYAN := Color("#4fd2ff")
const MECH_NAVY := Color("#1c3a66")


func _amp_disc(radius: float, additive: bool, c: Color, a: float) -> MeshInstance3D:
	if _amp_hex_shader == null:
		_amp_hex_shader = Shader.new()
		_amp_hex_shader.code = AMP_HEX_SHADER
		_amp_hex_tint = Shader.new()
		_amp_hex_tint.code = AMP_HEX_SHADER.replace("blend_add", "blend_mix")
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(radius * 2.0, radius * 2.0)
	q.orientation = PlaneMesh.FACE_Y
	m.mesh = q
	var mat := ShaderMaterial.new()
	mat.shader = _amp_hex_shader if additive else _amp_hex_tint
	mat.set_shader_parameter("col", c)
	mat.set_shader_parameter("fade", a)
	mat.set_shader_parameter("scale_k", 1.9 * radius)
	mat.render_priority = 2 if additive else 0
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


func amp_field(pos: Vector3, radius: float) -> Node3D:
	var n := Node3D.new()
	n.position = pos + Vector3(0, 0.014, 0)
	add_child(n)
	var tint: MeshInstance3D = _amp_disc(radius, false, MECH_NAVY, 0.42)
	n.add_child(tint)
	var glow: MeshInstance3D = _amp_disc(radius, true, MECH_CYAN, 1.0)
	glow.position.y = 0.006
	n.add_child(glow)
	var motes: GPUParticles3D = SoftFX.particles(26, 1.5, SoftFX.ramp([Color(0.4, 0.9, 1.0, 0.0), Color(0.5, 0.95, 1.0, 1.0), Color(0.3, 0.8, 1.0, 0.0)]), 0.08)
	var pm: ParticleProcessMaterial = motes.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = radius * 0.9
	pm.emission_ring_inner_radius = 0.0
	pm.emission_ring_height = 0.05
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 5.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 1.2
	pm.gravity = Vector3.ZERO
	motes.draw_pass_1 = _box
	motes.material_override = _emissive(MECH_CYAN.lightened(0.3), 2.4)
	pm.scale_min = 0.8
	pm.scale_max = 1.4
	motes.visibility_aabb = AABB(Vector3(-radius - 1, -1, -radius - 1), Vector3(radius * 2 + 2, 4, radius * 2 + 2))
	motes.emitting = true
	n.add_child(motes)
	n.scale = Vector3(0.15, 1.0, 0.15)
	var tw: Tween = n.create_tween()
	tw.tween_property(n, "scale", Vector3.ONE, 0.35 / speed_scale).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ring(pos, radius, Color("#7fd4ff"), 0.5, 1.4, 0.3)
	soft_flash(pos + Vector3(0, 0.3, 0), MECH_CYAN, 1.2, 0.3, 2.2)
	return n


## 力场投射：载具车顶的发射环往落点射一道青色的光束(一道折线电光 + 落点一圈收拢的环)，力场随后展开
func field_projection(from: Vector3, to: Vector3) -> void:
	var arc: LightningArc = LightningArc.create(self, from, to, 0.16, 0.35, 0.07, 3)
	arc.cols = [MECH_NAVY, MECH_CYAN, Color("#dff8ff")]
	arc._head.material_override = SoftFX.sprite_mat(MECH_CYAN, 2.6)
	soft_flash(from, MECH_CYAN, 0.9, 0.2, 2.4)


## 机械的枪口火光：一团身份色的闪光 + 几粒火星 + 一小缕烟
func mech_muzzle(at: Vector3, dir: Vector3, c: Color, big: float = 1.0) -> void:
	soft_flash(at, c.lerp(Color.WHITE, 0.3), 0.55 * big, 0.12, 2.6)
	burst(at + dir * 0.08, c, int(4 * big), 2.2, 0.45, 0.2, 0.18)
	fire_puff(at + dir * 0.1, Color("#8f96a2"), 3, 0.18 * big, 0.6, 0.45, 0.6, false)


## SG 火控终端(普攻命中额外的法术伤害)：目标身上一圈琥珀色的六边形锁定框收紧、一闪
func firecontrol_hit(at: Vector3) -> void:
	var c := Color("#ffb84a")
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.42
	cm.bottom_radius = 0.42
	cm.height = 0.02
	cm.radial_segments = 6
	cm.cap_top = false
	cm.cap_bottom = false
	m.mesh = cm
	var mat: StandardMaterial3D = _emissive(c, 2.6, 0.9).duplicate() as StandardMaterial3D
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	m.global_position = at
	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() != null else null
	if cam != null:
		var to: Vector3 = (cam.global_position - at).normalized()
		m.global_transform = Transform3D(Basis.looking_at(-to, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5), at)
	m.scale = Vector3(1.6, 3.0, 1.6)
	var s: float = maxf(0.2, speed_scale)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(m, "scale", Vector3(0.7, 3.0, 0.7), 0.16 / s).set_ease(Tween.EASE_IN)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.18 / s).set_delay(0.12 / s)
	tw.chain().tween_callback(m.queue_free)
	soft_flash(at, c, 0.7, 0.18, 2.2)
	burst(at, c, 6, 1.8, 0.45, 0.6, 0.3)


## AX 输出协议(每第 3 次普攻追加的物理伤害)：一个赤红的交叉斩 + 迸出的火花
func protocol_strike(at: Vector3, dir: Vector3) -> void:
	var c := Color("#ff4d6d")
	var d: Vector3 = Vector3(dir.x, 0.0, dir.z).normalized() if Vector3(dir.x, 0.0, dir.z).length() > 0.01 else Vector3(0, 0, 1)
	slash(at, d.rotated(Vector3.UP, 0.7), c, 1.1)
	slash(at, d.rotated(Vector3.UP, -0.7), c, 1.1)
	soft_flash(at, c.lerp(Color.WHITE, 0.3), 0.8, 0.16, 2.4)
	burst(at, Color("#ffd2dc"), 8, 2.6, 0.45, 0.5, 0.3)


## RX 中继广播：中继的天线顶上一闪 + 一圈薄荷色的信号波往外扩到广播半径
func relay_pulse(antenna: Vector3, ground: Vector3, radius: float) -> void:
	var c := Color("#5dffc8")
	soft_flash(antenna, c, 0.9, 0.25, 2.6)
	ring(Vector3(ground.x, 0.05, ground.z), radius, c, 0.7, 1.0, 0.1)
	ring(Vector3(ground.x, 0.06, ground.z), radius * 0.55, Color("#c8fff0"), 0.5, 0.8, 0.1)


## 增幅链路：一道薄荷色的数据光从中继的天线连到队友身上(一节一节的数据块顺着飞过去)
func data_link(from: Vector3, to: Vector3) -> void:
	var c := Color("#5dffc8")
	tracer(from, to, 0.05, 0.4, Color("#e6fff8"), c)
	var s: float = maxf(0.2, speed_scale)
	for i in range(3):
		var m := MeshInstance3D.new()
		m.mesh = _box
		m.material_override = _emissive(c, 2.6)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.scale = Vector3.ONE * 0.9
		add_child(m)
		m.global_position = from
		var tw: Tween = create_tween()
		tw.tween_interval(0.06 * float(i) / s)
		tw.tween_property(m, "global_position", to, 0.22 / s).set_ease(Tween.EASE_IN)
		tw.tween_callback(m.queue_free)
	get_tree().create_timer(0.3 / s).timeout.connect(soft_flash.bind(to, c, 0.5, 0.18, 2.2))


## 增幅链路挂着时：脚下一个慢慢转的薄荷色六边形(挂在单位视图上)
func link_marker(parent: Node3D, r: float) -> Node3D:
	var root := Node3D.new()
	root.name = "LinkMarker"
	parent.add_child(root)
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 0.02
	cm.radial_segments = 6
	cm.cap_top = false
	cm.cap_bottom = false
	var m := MeshInstance3D.new()
	m.mesh = cm
	var mat: StandardMaterial3D = _emissive(Color("#5dffc8"), 2.0, 0.8).duplicate() as StandardMaterial3D
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position.y = 0.04
	m.scale = Vector3(1.0, 2.5, 1.0)
	root.add_child(m)
	var tw: Tween = root.create_tween().set_loops()
	tw.tween_property(m, "rotation:y", PI / 3.0, 1.2).from(0.0)
	return root


## 机械的毁灭：白色装甲碎片 + 深色零件四散、身份色的火花、一团黑烟往上冒；big = 炮台 / 载具(整台炸开，更大)
func mech_explode(at: Vector3, c: Color, big: bool) -> void:
	var k: float = 1.5 if big else 1.0
	soft_flash(at, c.lerp(Color.WHITE, 0.4), 1.4 * k, 0.25, 2.6)
	burst(at, Color("#e8edf4"), int(12 * k), 3.2 * k, 1.1, 1.4, 0.8, false)
	burst(at, Color("#26304a"), int(10 * k), 2.6 * k, 1.0, 1.2, 0.8, false)
	burst(at, c, int(10 * k), 3.6, 0.5, 1.0, 0.4)
	fire_puff(at, Color("#3a3f48"), int(8 * k), 0.5 * k, 1.2, 1.2, 1.2, false)
	if big:
		fire_puff(at, Color("#ff8a3a"), 8, 0.45, 1.6, 0.5, 0.8)
		ring(Vector3(at.x, 0.05, at.z), 1.6, c, 0.45, 1.4, 0.2)
		scorch(Vector3(at.x, 0.0, at.z), 0.7, c, 2.4)


func remove_field(n: Node3D) -> void:
	var tw: Tween = n.create_tween()
	tw.tween_property(n, "scale", Vector3(0.05, 1.0, 0.05), 0.35 / speed_scale).set_ease(Tween.EASE_IN)
	tw.tween_callback(n.queue_free)


## 蓄力光点：挂在 parent(模型)上 offset 处的一粒发光体素，dur 秒内从小长大、越转越快，外圈一圈圈往里收(聚能)；
## 蓄满时闪一下。返回节点，出手/被打断时交给 release_charge
func charge(parent: Node3D, offset: Vector3, color: Color, dur: float) -> Node3D:
	var n := Node3D.new()
	n.position = offset
	parent.add_child(n)
	var core := MeshInstance3D.new()
	core.mesh = _box
	core.material_override = _emissive(color, 4.5)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(core)
	var halo := MeshInstance3D.new()
	halo.mesh = _ring_mesh
	halo.material_override = _emissive(color, 3.0, 0.8).duplicate()
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.rotation.x = PI * 0.5
	n.add_child(halo)
	var d: float = maxf(0.05, dur / speed_scale)
	n.scale = Vector3.ONE * 0.35
	var tw: Tween = n.create_tween().set_parallel(true)
	tw.tween_property(n, "scale", Vector3.ONE * 1.25, d).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(core, "rotation", Vector3(TAU * 2.0, TAU * 3.0, 0.0), d).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func() -> void: ring(n.global_position, 0.35, color, 0.25, 1.2, 0.3))
	var th: Tween = n.create_tween().set_loops()
	th.tween_property(halo, "scale", Vector3.ONE * 0.05, 0.32 / speed_scale).from(Vector3.ONE * 0.28)
	return n


func release_charge(n: Node3D, color: Color, flash: bool) -> void:
	if flash:
		burst(n.global_position, color, 9, 2.6, 0.9, 0.4, 0.35)
	n.queue_free()


func slash(pos: Vector3, dir: Vector3, color: Color, size: float = 1.0) -> void:
	var m := MeshInstance3D.new()
	m.mesh = _arc_mesh()
	m.material_override = _emissive(color, 3.0, 0.9).duplicate()
	m.position = pos
	m.scale = Vector3.ONE * size
	m.look_at_from_position(pos, pos + Vector3(dir.x, 0.0, dir.z), Vector3.UP)
	m.rotation.z += randf_range(-0.5, 0.5)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(m, "scale", Vector3.ONE * size * 1.35, 0.16 / speed_scale).set_ease(Tween.EASE_OUT)
	tw.tween_property(m.material_override, "albedo_color:a", 0.0, 0.18 / speed_scale)
	tw.chain().tween_callback(m.queue_free)


var _arc: ArrayMesh = null


func _arc_mesh() -> ArrayMesh:
	if _arc != null:
		return _arc
	var verts := PackedVector3Array()
	var idx := PackedInt32Array()
	var n := 14
	for i in range(n + 1):
		var a: float = lerpf(-1.05, 1.05, float(i) / float(n))
		var outer := Vector3(sin(a) * 0.62, cos(a) * 0.62 - 0.4, 0.0)
		var inner := Vector3(sin(a) * 0.62 * 0.92, cos(a) * 0.62 * 0.92 - 0.4 + 0.10 * (1.0 - absf(a) / 1.05), 0.0)
		verts.append(outer)
		verts.append(inner)
	for i in range(n):
		var b: int = i * 2
		idx.append_array([b, b + 1, b + 2, b + 1, b + 3, b + 2])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_INDEX] = idx
	_arc = ArrayMesh.new()
	_arc.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return _arc


# ---------------------------------------------------------------- 体素小图标(爱心 / 十字)
const HEART_ROWS := [".XX.XX.", "XXXXXXX", "XXXXXXX", ".XXXXX.", "..XXX..", "...X..."]
const CROSS_ROWS := [".X.", "XXX", ".X."]
var _icon_meshes: Dictionary = {}


## 体素小图标：rows 从上到下，"X" = 一格；在 XY 平面上(1 格厚)，原点在中心。粒子用 billboard 让它始终正对镜头
func _voxel_icon(key: String, rows: Array, vox: float) -> ArrayMesh:
	if _icon_meshes.has(key):
		return _icon_meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h: int = rows.size()
	var w: int = str(rows[0]).length()
	for r in range(h):
		var line: String = rows[r]
		for c in range(w):
			if line[c] != "X":
				continue
			var o := Vector3((float(c) - float(w) * 0.5) * vox, (float(h) * 0.5 - float(r) - 1.0) * vox, -vox * 0.5)
			_cube(st, o, vox)
	var m: ArrayMesh = st.commit()
	_icon_meshes[key] = m
	return m


func _cube(st: SurfaceTool, o: Vector3, v: float) -> void:
	var p := [o, o + Vector3(v, 0, 0), o + Vector3(v, v, 0), o + Vector3(0, v, 0),
		o + Vector3(0, 0, v), o + Vector3(v, 0, v), o + Vector3(v, v, v), o + Vector3(0, v, v)]
	for f: Array in [[0, 1, 2, 3], [5, 4, 7, 6], [4, 0, 3, 7], [1, 5, 6, 2], [3, 2, 6, 7], [4, 5, 1, 0]]:
		st.add_vertex(p[f[0]])
		st.add_vertex(p[f[1]])
		st.add_vertex(p[f[2]])
		st.add_vertex(p[f[0]])
		st.add_vertex(p[f[2]])
		st.add_vertex(p[f[3]])


func heart_mesh() -> ArrayMesh:
	return _voxel_icon("heart", HEART_ROWS, 0.022)


func cross_mesh() -> ArrayMesh:
	return _voxel_icon("cross", CROSS_ROWS, 0.03)


## 粒子用的发光材质：正对镜头(billboard)、双面
func _icon_mat(c: Color, energy: float = 2.4) -> StandardMaterial3D:
	var key := "icon|%s|%.1f" % [c.to_html(), energy]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m: StandardMaterial3D = _emissive(c, energy).duplicate() as StandardMaterial3D
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_cache[key] = m
	return m


## 一把往上飘的小图标(爱心 / 十字)：从 pos 周围 spread 米的球里冒出来，慢慢往上飘、边飘边缩小
func float_icons(pos: Vector3, mesh: Mesh, color: Color, count: int, spread: float, life: float = 0.9, size: float = 1.0) -> void:
	if count <= 0:
		return
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = maxf(0.05, spread)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 35.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 1.3
	pm.gravity = Vector3(0, 0.6, 0)
	pm.damping_min = 1.2
	pm.damping_max = 2.0
	pm.scale_min = 0.8 * size
	pm.scale_max = 1.35 * size
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(0.15, 1.0))
	curve.add_point(Vector2(0.7, 0.85))
	curve.add_point(Vector2(1, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	p.process_material = pm
	p.draw_pass_1 = mesh
	p.material_override = _icon_mat(color)
	p.amount = count
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 0.8
	p.local_coords = false
	p.emitting = true
	p.position = pos
	p.visibility_aabb = AABB(Vector3(-3, -2, -3), Vector3(6, 6, 6))
	add_child(p)
	p.speed_scale = _pslow()
	get_tree().create_timer((life + 0.5) / _pslow()).timeout.connect(p.queue_free)


## 治疗的溅射(护理节点的普攻打在队友身上，或爱心针剂打在队友身上)：不炸——一圈柔和的粉色波纹 + 一圈细的治疗绿，
## 往上飘的粉色爱心和绿色十字。big = 爱心针剂：再从目标头顶升起一颗大爱心、贴地的粉色半球罩交代溅射范围(1.8 米)
func care_splash(center: Vector3, radius: float, big: bool) -> void:
	var ground := Vector3(center.x, 0.0, center.z)
	var pink := Color("#ff8cc8")
	var s: float = maxf(0.2, speed_scale)
	ring(ground, radius, pink, 0.55 if big else 0.42, 1.8 if big else 1.2, 0.18)
	ring(ground, radius * 0.72, COLORS["heal"], 0.35, 0.7, 0.1)
	float_icons(center, heart_mesh(), pink, 16 if big else 6, radius * (0.55 if big else 0.4), 1.0 if big else 0.8)
	float_icons(center, cross_mesh(), (COLORS["heal"] as Color).lightened(0.2), 6 if big else 2, radius * 0.4, 0.8, 0.9)
	burst(center, Color("#ffd6ea"), 8 if big else 4, 1.8, 0.7, 0.8, 0.35)
	if not big:
		return
	var dome := _shell(ground, pink, 0.55, true)
	dome.scale = Vector3(radius * 0.3, radius * 0.2, radius * 0.3)
	var td: Tween = create_tween().set_parallel(true)
	td.tween_property(dome, "scale", Vector3(radius, radius * 0.55, radius), 0.3 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	td.tween_method(func(v: float) -> void: (dome.material_override as ShaderMaterial).set_shader_parameter("fade", v), 1.0, 0.0, 0.42 / s).set_delay(0.08 / s)
	td.chain().tween_callback(dome.queue_free)
	_big_heart(center + Vector3(0, 0.55, 0), pink)
	var light := OmniLight3D.new()
	light.light_color = pink
	light.light_energy = 1.4
	light.omni_range = radius * 2.0
	light.shadow_enabled = false
	light.position = center + Vector3(0, 0.3, 0)
	add_child(light)
	var tl: Tween = create_tween()
	tl.tween_property(light, "light_energy", 0.0, 0.4 / s)
	tl.tween_callback(light.queue_free)


## 飞出去的符(清心节点)：一张发光的黄符(朱砂符文) + 外面一圈光晕 + 一盏小灯(照亮沿途的地面) + 沿途留下的光点。
## heal = 清心符(绿)，否则 = 弱体符(紫)。由 BattleView 的能力投射物推着飞(跟着目标)，落地交给 talisman_land
func make_talisman(heal: bool) -> Node3D:
	var col: Color = Color("#7dffa8") if heal else Color("#c07cff")
	var node := Node3D.new()
	var card := Node3D.new()                 # 符纸(往镜头方向仰着，飞的时候自己转)
	card.name = "Card"
	card.rotation.x = -0.9
	node.add_child(card)
	var parts: Array = [[Vector3(0.22, 0.44, 0.016), Vector3.ZERO, Color("#ffe9a8"), 1.5],
		[Vector3(0.045, 0.32, 0.02), Vector3(0, -0.02, 0), Color("#e83030"), 1.8],
		[Vector3(0.14, 0.035, 0.02), Vector3(0, 0.1, 0), Color("#e83030"), 1.8],
		[Vector3(0.1, 0.03, 0.02), Vector3(0, -0.06, 0), Color("#e83030"), 1.8]]
	for pt: Array in parts:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = pt[0]
		mi.mesh = bm
		mi.position = pt[1]
		mi.material_override = _emissive(pt[2], float(pt[3]))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		card.add_child(mi)
	var glow := MeshInstance3D.new()
	var gm := SphereMesh.new()
	gm.radius = 0.34
	gm.height = 0.68
	gm.radial_segments = 10
	gm.rings = 5
	glow.mesh = gm
	glow.material_override = _emissive(col, 2.2, 0.28)
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(glow)
	var light := OmniLight3D.new()
	light.light_color = col
	light.light_energy = 1.6
	light.omni_range = 1.8
	light.shadow_enabled = false
	node.add_child(light)
	# 沿途的光点(世界坐标里留在原地慢慢往上飘、缩小)
	var tr := GPUParticles3D.new()
	tr.name = "Trail"
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.12
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 60.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.6
	pm.gravity = Vector3(0, 0.4, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1.0))
	curve.add_point(Vector2(1, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	tr.process_material = pm
	tr.draw_pass_1 = _box
	tr.material_override = _emissive(col.lightened(0.2), 2.8)
	tr.amount = 40
	tr.lifetime = 0.45
	tr.local_coords = false
	tr.emitting = true
	tr.visibility_aabb = AABB(Vector3(-6, -3, -6), Vector3(12, 8, 12))
	node.add_child(tr)
	return node


## 施放符的一瞬：手边一闪 + 一小圈光点
func talisman_cast(at: Vector3, heal: bool) -> void:
	var col: Color = Color("#7dffa8") if heal else Color("#c07cff")
	burst(at, Color("#ffe9a8"), 6, 1.6, 0.7, 0.6, 0.3)
	burst(at, col, 6, 1.2, 0.8, 0.8, 0.35)


## 符落到目标身上：符消失、拖尾的光点留在原地散掉；化成一团光(清心符再冒几个十字)
func talisman_land(node: Node3D, at: Vector3, heal: bool) -> void:
	var col: Color = Color("#7dffa8") if heal else Color("#c07cff")
	var tr: GPUParticles3D = node.get_node_or_null("Trail") as GPUParticles3D
	if tr != null:
		var gx: Transform3D = tr.global_transform
		node.remove_child(tr)
		add_child(tr)
		tr.global_transform = gx
		tr.emitting = false
		get_tree().create_timer(tr.lifetime + 0.3).timeout.connect(tr.queue_free)
	node.queue_free()
	burst(at, col, 16, 2.8, 1.0, 1.0, 0.55)
	burst(at, Color("#ffe9a8"), 6, 1.8, 0.7, 0.8, 0.35)
	ring(Vector3(at.x, 0.0, at.z), 0.9, col, 0.45, 1.2, 0.2)
	if heal:
		float_icons(at, cross_mesh(), col, 3, 0.3, 0.7, 0.8)


## ---------------------------------------------------------------- 炽照节点：拔刀术的斩光 / 剑痕
## 都是"刀口形"的光弧：以目标中心为圆心、在这一刀的挥动平面里的一段圆弧(两头尖、中间粗；平面内一条 + 沿平面法线一条，十字截面，
## 从哪个角度看都不会变成一条线)。照常做深度测试：身体后面那截被挡住，看起来就是刀绕着身体切过去 / 刀口留在身上，
## 不再是悬在半空、盖在所有东西上面的随机小棍。半径、高度由 BattleView 按目标的体型和刀的高度算好(大体型敌人的刀痕在它被砍到的地方)
const CUT_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;
uniform vec4 core : source_color = vec4(1.0, 0.96, 0.84, 1.0);
uniform vec4 glow : source_color = vec4(1.0, 0.48, 0.16, 1.0);
uniform float energy = 1.6;
uniform float head = 1.0;
uniform float tail = 0.0;
uniform float fade = 1.0;
uniform float flicker = 0.0;
uniform float seed = 0.0;
void fragment() {
	float s = UV.x;
	if (s > head || s < tail) {
		discard;
	}
	float w = abs(UV.y * 2.0 - 1.0);
	float along = smoothstep(tail, mix(tail, head, 0.55), s);
	float core_k = 1.0 - smoothstep(0.05, 0.42, w);
	vec3 c = mix(glow.rgb, core.rgb, core_k);
	float fl = 1.0 - flicker * (0.22 + 0.22 * sin(TIME * 19.0 + s * 11.0 + seed));
	ALBEDO = c * energy * fl;
	ALPHA = clamp((1.0 - smoothstep(0.5, 1.0, w)) * along * fade, 0.0, 1.0);
}
"""
var _cut_shader: Shader = null
const SCAR_COL := Color("#ff6a24")
const SCAR_CORE := Color("#fff8e6")
const CUT_GLOW := Color("#ffb04a")
const CUT_CORE := Color("#fffaf0")


## 刀口形弧带的网格：XY 平面里以原点为圆心、半径 r 的一段圆弧(以 +X 为中线，张角 span 弧度)，最宽 w、两头尖；
## 第二条带子沿 Z(平面法线)方向展开。UV.x = 沿弧 0..1(从 -Y 一侧到 +Y 一侧)，UV.y = 横跨 0..1
func _crescent(r: float, span: float, w: float, segs: int = 22) -> ArrayMesh:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for strip in 2:
		var base: int = verts.size()
		for i in range(segs + 1):
			var sv: float = float(i) / float(segs)
			var a: float = lerpf(-span * 0.5, span * 0.5, sv)
			var half: float = w * 0.5 * pow(sin(PI * sv), 0.65) * (1.0 if strip == 0 else 0.7)
			var dir := Vector3(cos(a), sin(a), 0.0)
			if strip == 0:
				verts.append(dir * (r - half))
				verts.append(dir * (r + half))
			else:
				verts.append(dir * r + Vector3(0.0, 0.0, -half))
				verts.append(dir * r + Vector3(0.0, 0.0, half))
			uvs.append(Vector2(sv, 0.0))
			uvs.append(Vector2(sv, 1.0))
		for i in range(segs):
			var b: int = base + i * 2
			idx.append_array([b, b + 1, b + 2, b + 1, b + 3, b + 2])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am


func _cut_mat(core: Color, glow: Color, energy: float) -> ShaderMaterial:
	if _cut_shader == null:
		_cut_shader = Shader.new()
		_cut_shader.code = CUT_SHADER
	var m := ShaderMaterial.new()
	m.shader = _cut_shader
	m.set_shader_parameter("core", core)
	m.set_shader_parameter("glow", glow)
	m.set_shader_parameter("energy", energy)
	m.render_priority = 6
	return m


## 圆弧的朝向：中线(+X)朝 toward、平面法线 normal、沿弧正方向(+Y) = 刀走的方向(sweep = ±1)
static func _cut_basis(toward: Vector3, normal: Vector3, sweep: float) -> Basis:
	var n: Vector3 = normal.normalized()
	var u: Vector3 = toward - n * toward.dot(n)
	if u.length() < 1e-3:
		u = n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT)
	u = u.normalized()
	var v: Vector3 = n.cross(u) * (1.0 if sweep >= 0.0 else -1.0)
	return Basis(u, v, u.cross(v))


## 一刀斩过目标：光弧从刀来的一侧沿刀的走向扫过去(0.05 秒)，马上从尾巴收掉；切口处溅几点火星
## center = 目标中心(刀的高度)，toward = 目标 → 出刀的人(水平)，normal = 挥动平面法线，radius = 光弧半径
func iaido_cut(center: Vector3, toward: Vector3, normal: Vector3, sweep: float, radius: float) -> void:
	var s: float = maxf(0.2, speed_scale)
	var m := MeshInstance3D.new()
	m.mesh = _crescent(radius, deg_to_rad(150.0), clampf(radius * 0.16, 0.05, 0.16))
	var mat: ShaderMaterial = _cut_mat(CUT_CORE, CUT_GLOW, 1.7)
	mat.set_shader_parameter("head", 0.0)
	mat.set_shader_parameter("tail", 0.0)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	var b: Basis = _cut_basis(toward, normal, sweep)
	m.global_transform = Transform3D(b, center)
	var tw: Tween = create_tween()
	tw.tween_method(func(x: float) -> void: mat.set_shader_parameter("head", x), 0.0, 1.0, 0.05 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_method(func(x: float) -> void: mat.set_shader_parameter("tail", x), 0.0, 0.3, 0.05 / s)
	tw.tween_method(func(x: float) -> void: mat.set_shader_parameter("tail", x), 0.3, 1.0, 0.16 / s).set_ease(Tween.EASE_IN)
	tw.parallel().tween_method(func(x: float) -> void: mat.set_shader_parameter("fade", x), 1.0, 0.0, 0.16 / s).set_delay(0.04 / s)
	tw.tween_callback(m.queue_free)
	burst(center + b.x * radius, CUT_GLOW, 3, 2.4, 0.35, 0.4, 0.2)


## 剑痕的挂架：挂在目标模型下面(跟着它走、转、变大变小)
func scar_holder(parent: Node3D) -> Node3D:
	var h := Node3D.new()
	parent.add_child(h)
	return h


## 一道剑痕：这一刀在身上留下的一小段发光刀口(张角 28~40°)，位置 / 朝向沿用这一刀的光弧(沿弧挪一点、平面歪一点，几道刀痕不叠成一根)；
## 出现时从刀来的方向"划"出来，之后像余烬一样明灭
func scar_mark(holder: Node3D, center: Vector3, toward: Vector3, normal: Vector3, sweep: float, radius: float) -> Node3D:
	var s: float = maxf(0.2, speed_scale)
	var n: Vector3 = normal.normalized()
	var side: Vector3 = toward.cross(n)
	if side.length() > 0.01:
		n = Basis(side.normalized(), randf_range(-0.22, 0.22)) * n
	var b: Basis = _cut_basis(toward, n, sweep)
	b = Basis(n.normalized(), randf_range(-0.35, 0.35)) * b
	var m := MeshInstance3D.new()
	m.mesh = _crescent(radius, deg_to_rad(randf_range(28.0, 40.0)), clampf(radius * 0.16, 0.05, 0.14))
	var mat: ShaderMaterial = _cut_mat(SCAR_CORE, SCAR_COL, 1.7)
	mat.set_shader_parameter("head", 0.0)
	mat.set_shader_parameter("flicker", 1.0)
	mat.set_shader_parameter("seed", randf() * 10.0)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(m)
	m.global_transform = Transform3D(b, center + Vector3(0.0, randf_range(-0.1, 0.1) * radius, 0.0))
	var tw: Tween = create_tween()
	tw.tween_method(func(x: float) -> void: mat.set_shader_parameter("head", x), 0.0, 1.0, 0.07 / s).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_method(func(x: float) -> void: mat.set_shader_parameter("energy", x), 3.0, 1.7, 0.25 / s)
	return m


## 剑痕引爆(残光)：每道刀口一道接一道亮成白金、撑开，从刀口里迸出火星后沿刀口烧尽；地上一圈细的火环(层数越多越大)
func scar_burst(marks: Array, center: Vector3, stacks: int) -> void:
	var s: float = maxf(0.2, speed_scale)
	var k: float = clampf(float(stacks) / 10.0, 0.2, 1.0)
	for i in range(marks.size()):
		var n: MeshInstance3D = marks[i] as MeshInstance3D
		if n == null or not is_instance_valid(n):
			continue
		var mat: ShaderMaterial = n.material_override as ShaderMaterial
		var mid: Vector3 = n.global_transform * n.get_aabb().get_center()
		var tw: Tween = create_tween()
		tw.tween_interval(0.022 * float(i) / s)
		tw.tween_callback(func() -> void:
			mat.set_shader_parameter("flicker", 0.0)
			mat.set_shader_parameter("core", Color("#ffffff"))
			mat.set_shader_parameter("glow", Color("#ffcf6a")))
		tw.tween_method(func(x: float) -> void: mat.set_shader_parameter("energy", x), 1.5, 3.2, 0.05 / s)
		tw.parallel().tween_property(n, "scale", n.scale * 1.18, 0.05 / s)
		tw.tween_callback(func() -> void:
			burst(mid, SCAR_CORE if i % 2 == 0 else SCAR_COL, 2, 2.4, 0.3, 0.5, 0.22))
		tw.tween_method(func(x: float) -> void: mat.set_shader_parameter("tail", x), 0.0, 1.0, 0.12 / s).set_ease(Tween.EASE_IN)
		tw.tween_callback(n.queue_free)
	var ground := Vector3(center.x, 0.0, center.z)
	ring(ground, 0.55 + 0.45 * k, SCAR_COL, 0.38, 0.55, 0.3)
	burst(center, CUT_GLOW, int(2 + 3 * k), 2.0 + k, 0.4, 0.7, 0.28)
	if stacks >= 10:
		ring(ground, 1.15, SCAR_CORE, 0.42, 0.45, 0.35)


## 剑痕被驱散 / 持有者倒下：刀口直接淡掉
func scar_fade(marks: Array) -> void:
	var s: float = maxf(0.2, speed_scale)
	for n0 in marks:
		var n: MeshInstance3D = n0 as MeshInstance3D
		if n == null or not is_instance_valid(n):
			continue
		var mat: ShaderMaterial = n.material_override as ShaderMaterial
		var tw: Tween = create_tween()
		tw.tween_method(func(x: float) -> void: mat.set_shader_parameter("fade", x), 1.0, 0.0, 0.18 / s)
		tw.tween_callback(n.queue_free)


## 重燃(不灭)：挨打时消耗层数回血——脚下一圈火、身上往上窜的火苗 + 绿色的十字
func rekindle_heal(center: Vector3, stacks: int) -> void:
	var ground := Vector3(center.x, 0.0, center.z)
	ring(ground, 0.9, Color("#ff9a3a"), 0.45, 1.3, 0.2)
	burst(center, Color("#ffb04a"), 6 + stacks, 2.2, 0.9, 1.8, 0.6)
	_motes(center - Vector3(0, 0.4, 0), Color("#ff8a2a"), 4 + stacks, 0.8)
	float_icons(center, cross_mesh(), Color("#7dff9a"), mini(4, 1 + stacks / 3), 0.3, 0.7, 0.8)


## ---------------------------------------------------------------- 巫术节点：魔法阵 / 虹光飞弹
const MISSILE_COL := {"red": Color("#ff5a3c"), "blue": Color("#4f8dff"), "green": Color("#5dffa0"), "white": Color("#f4f0ff")}


## 吟唱的魔法阵：脚下两圈发光的环 + 一圈符文块 + 内圈六芒星(两个三角)，慢慢转；返回节点(结束时 magic_circle_end)
func magic_circle(at: Vector3, color: Color) -> Node3D:
	var root := Node3D.new()
	root.position = Vector3(at.x, 0.03, at.z)
	add_child(root)
	for rr: Array in [[1.05, 0.035], [0.82, 0.02]]:
		var ring_m := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = float(rr[0]) - float(rr[1])
		tm.outer_radius = float(rr[0])
		tm.rings = 48
		tm.ring_segments = 4
		ring_m.mesh = tm
		ring_m.scale = Vector3(1.0, 0.15, 1.0)
		ring_m.material_override = _emissive(color, 2.4, 0.85)
		ring_m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(ring_m)
	var spin := Node3D.new()
	spin.name = "Spin"
	root.add_child(spin)
	# 符文：环上一圈小方块(长短不一)
	for i in range(18):
		var a: float = TAU * float(i) / 18.0
		var bm := BoxMesh.new()
		bm.size = Vector3(0.05 + 0.06 * float(i % 3), 0.01, 0.04)
		var m := MeshInstance3D.new()
		m.mesh = bm
		m.material_override = _emissive(color.lightened(0.3), 2.8, 0.9)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.position = Vector3(cos(a) * 0.935, 0.0, sin(a) * 0.935)
		m.rotation.y = -a
		spin.add_child(m)
	# 六芒星：两个三角，每边一根细条
	for tri in range(2):
		for e in range(3):
			var a0: float = TAU * float(e) / 3.0 + PI * float(tri) / 3.0 + PI * 0.5
			var a1: float = a0 + TAU / 3.0
			var p0 := Vector3(cos(a0), 0.0, sin(a0)) * 0.8
			var p1 := Vector3(cos(a1), 0.0, sin(a1)) * 0.8
			var bm2 := BoxMesh.new()
			bm2.size = Vector3(0.025, 0.01, p0.distance_to(p1))
			var m2 := MeshInstance3D.new()
			m2.mesh = bm2
			m2.material_override = _emissive(color, 2.2, 0.75)
			m2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			m2.position = (p0 + p1) * 0.5
			m2.look_at_from_position(m2.position, p1, Vector3.UP)
			spin.add_child(m2)
	root.scale = Vector3.ONE * 0.2
	var s: float = maxf(0.2, speed_scale)
	create_tween().tween_property(root, "scale", Vector3.ONE, 0.25 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	return root


func magic_circle_end(n: Node3D, flash: bool) -> void:
	if n == null or not is_instance_valid(n):
		return
	var s: float = maxf(0.2, speed_scale)
	var tw: Tween = create_tween()
	if flash:
		tw.tween_property(n, "scale", Vector3.ONE * 1.25, 0.08 / s)
	tw.tween_property(n, "scale", Vector3(1.4, 1.0, 1.4) * 0.01, 0.25 / s).set_ease(Tween.EASE_IN)
	tw.tween_callback(n.queue_free)



## 虹光飞弹的弹头：一颗转着的多面晶体(颜色) + 白热的光芯(叠加) + 一团颜色的光晕(普通混合：白地上也看得见) + 两颗绕着它转的小光点，
## 后面拖一条面向镜头、越来越细的光带(RibbonTrail) + 一路撒下的柔光星屑；按颜色加点味道：红 = 往下掉的火星、绿 = 往上飘的绿光。
## 节点名 Trail / Ribbon / Sparks：命中时(missile_impact)留在原地自己散完
func make_missile(color: Color, kind: String = "") -> Node3D:
	var node := Node3D.new()
	var crystal := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 0.075
	cm.height = 0.2
	cm.radial_segments = 4
	cm.rings = 2
	crystal.mesh = cm
	crystal.material_override = _emissive(color.lightened(0.25), 3.6)
	crystal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(crystal)
	var spin: Tween = crystal.create_tween().set_loops()
	spin.tween_property(crystal, "rotation", Vector3(TAU, TAU * 2.0, 0.0), 0.6).from(Vector3.ZERO)
	for L: Array in [[0.55, color, 1.0, false, 0.75], [0.26, color.lerp(Color.WHITE, 0.8), 2.0, true, 1.0]]:
		var g := MeshInstance3D.new()
		g.mesh = SoftFX.quad(float(L[0]))
		var gm: StandardMaterial3D = SoftFX.sprite_mat(L[1] as Color, float(L[2]), bool(L[3]))
		gm.albedo_color.a = float(L[4])
		gm.disable_fog = true
		g.material_override = gm
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(g)
	# 绕着转的两颗小光点
	var orbit := Node3D.new()
	node.add_child(orbit)
	for i in range(2):
		var o := MeshInstance3D.new()
		o.mesh = SoftFX.quad(0.11)
		var om: StandardMaterial3D = SoftFX.sprite_mat(color.lerp(Color.WHITE, 0.6), 1.8, true)
		om.disable_fog = true
		o.material_override = om
		o.position = Vector3(cos(PI * i), 0.0, sin(PI * i)) * 0.17
		o.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		orbit.add_child(o)
	orbit.rotation = Vector3(0.6, 0.0, 0.3)
	var ot: Tween = orbit.create_tween().set_loops()
	ot.tween_property(orbit, "rotation:y", TAU, 0.35).from(0.0)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.0
	light.omni_range = 1.2
	node.add_child(light)
	# 光带拖尾
	var rib: RibbonTrail = RibbonTrail.create(node, color, 0.085, 0.34)
	rib.name = "Ribbon"
	rib.time_scale = maxf(0.2, speed_scale)
	node.add_child(rib)
	# 一路撒下的星屑(柔光粒子，世界坐标)
	var ramp_cols: Array = [Color(color.r, color.g, color.b, 0.0), Color(color.r, color.g, color.b, 0.9), Color(color.r * 0.6, color.g * 0.6, color.b * 0.6, 0.0)]
	if kind == "red":
		ramp_cols = [Color(1.0, 0.8, 0.4, 0.0), Color(1.0, 0.55, 0.2, 0.95), Color(0.5, 0.1, 0.05, 0.0)]
	var tr: GPUParticles3D = SoftFX.particles(46, 0.55, SoftFX.ramp(ramp_cols, [0.0, 0.15, 1.0]), 0.09, true)
	tr.name = "Trail"
	var pm: ParticleProcessMaterial = tr.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.06
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.1
	pm.initial_velocity_max = 0.45
	pm.gravity = Vector3(0, 0.6 if kind == "green" else (-0.8 if kind == "red" else 0.1), 0)
	pm.damping_min = 0.5
	pm.damping_max = 1.2
	(tr.material_override as StandardMaterial3D).disable_fog = true
	tr.visibility_aabb = AABB(Vector3(-14, -4, -14), Vector3(28, 14, 28))
	tr.emitting = true
	node.add_child(tr)
	return node


## 飞弹命中：弹头没了(拖尾光带和星屑留在原地自己散完)；颜色的一闪 + 一圈往外推的符文环 + 碎光，按颜色：
## 红 = 一团火 + 一点焦痕、蓝 = 冰晶似的碎片往外崩、绿 = 治疗的绿光往上飘、白 = 十字星芒一闪
func missile_impact(node: Node3D, at: Vector3, color: Color, kind: String = "") -> void:
	if node != null and is_instance_valid(node):
		for nm: String in ["Trail", "Ribbon"]:
			var ch: Node3D = node.get_node_or_null(nm) as Node3D
			if ch == null:
				continue
			var gx: Transform3D = ch.global_transform
			node.remove_child(ch)
			add_child(ch)
			ch.global_transform = gx
			if ch is GPUParticles3D:
				(ch as GPUParticles3D).emitting = false
				get_tree().create_timer((ch as GPUParticles3D).lifetime + 0.3).timeout.connect(ch.queue_free)
			elif ch is RibbonTrail:
				(ch as RibbonTrail).detach()
		node.queue_free()
	var g := Vector3(at.x, 0.0, at.z)
	soft_flash(at, color.lerp(Color.WHITE, 0.4), 0.8, 0.18, 1.8)
	ring(g + Vector3(0.0, 0.04, 0.0), 0.65, color, 0.32, 1.0, 0.2)
	match kind:
		"red":
			fire_puff(at, color, 8, 0.32, 1.4, 0.5)
			burst(at, Color("#ffd08a"), 6, 2.6, 0.5, 1.0, 0.35)
			scorch(g, 0.32, color, 1.0)
		"green":
			burst(at, color, 8, 1.4, 0.6, 2.4, 0.6)
			soft_flash(at + Vector3(0.0, 0.25, 0.0), Color("#c8ffd8"), 0.6, 0.35, 1.4)
			var gp := SoftFX.particles(10, 0.9, SoftFX.ramp([Color(0.6, 1.0, 0.75, 0.0), Color(0.55, 1.0, 0.7, 0.9), Color(0.3, 0.9, 0.5, 0.0)], [0.0, 0.2, 1.0]), 0.09, true)
			var gpm: ParticleProcessMaterial = gp.process_material
			gpm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			gpm.emission_sphere_radius = 0.3
			gpm.direction = Vector3(0, 1, 0)
			gpm.spread = 20.0
			gpm.initial_velocity_min = 0.6
			gpm.initial_velocity_max = 1.2
			(gp.material_override as StandardMaterial3D).disable_fog = true
			gp.one_shot = true
			gp.explosiveness = 0.6
			gp.emitting = true
			add_child(gp)
			gp.global_position = at
			gp.speed_scale = _pslow()
			get_tree().create_timer(1.3 / _pslow()).timeout.connect(gp.queue_free)
		"white":
			_star_flare(at, 0.9)
			burst(at, Color("#ffffff"), 8, 2.8, 0.6, 0.6, 0.35)
		_:
			burst(at, color.lightened(0.3), 10, 3.0, 0.7, 0.6, 0.4)
			burst(at, Color("#dce8ff"), 5, 2.2, 0.5, 0.5, 0.3)


## 渡鸦使魔被召出来：一团淡蓝灵焰一闪、蓝色光环，蓝黑的羽毛炸开再飘落、几点蓝色火星
func raven_summon(at: Vector3) -> void:
	var g := Vector3(at.x, 0.0, at.z)
	soft_flash(g + Vector3(0.0, 0.6, 0.0), Color("#6f9cff"), 1.1, 0.3, 1.6)
	ring(g + Vector3(0.0, 0.04, 0.0), 1.0, Color("#5a8cff"), 0.45, 1.2, 0.2)
	feather_fall(g + Vector3(0.0, 0.5, 0.0), 9, 1.1, Color("#3a3f6e"), Color("#151628"))
	burst(g + Vector3(0.0, 0.7, 0.0), Color("#5a8cff"), 8, 1.8, 0.6, 1.4, 0.5)


## 十字星芒：两道交叉的细光一下张开再收掉
func _star_flare(at: Vector3, size: float) -> void:
	var s: float = maxf(0.2, speed_scale)
	var root := Node3D.new()
	add_child(root)
	root.global_position = at
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam != null and cam.global_position.distance_to(at) > 0.1:
		root.look_at(cam.global_position, Vector3.UP)        # 星芒面朝镜头(四道光在这个平面里转开)
	var mats: Array = []
	for r0 in [0.0, PI * 0.5, PI * 0.25, PI * 0.75]:
		var bm := MeshInstance3D.new()
		var q := QuadMesh.new()
		var big: bool = r0 == 0.0 or r0 == PI * 0.5
		q.size = Vector2(size * (1.0 if big else 0.55), 0.04 if big else 0.03)
		bm.mesh = q
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.cull_mode = BaseMaterial3D.CULL_DISABLED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		sm.albedo_color = Color(1.6, 1.6, 1.7, 1.0)
		sm.disable_fog = true
		bm.material_override = sm
		bm.rotation.z = r0
		bm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(bm)
		mats.append(sm)
	root.scale = Vector3.ONE * 0.2
	var tw: Tween = create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.08 / s).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(x: float) -> void:
		for m0: Variant in mats:
			(m0 as StandardMaterial3D).albedo_color.a = x, 1.0, 0.0, 0.22 / s)
	tw.tween_callback(root.queue_free)


## 投掷的武器扎中目标：一闪 + 冲击环 + 往外崩的碎屑 + 一道顺着来向的冲击线
## fire_k(0..1)：狩胜节点的光荣——武器带着火扎进去，炸开一团火
func throw_impact(at: Vector3, dir: Vector3, color: Color, fire_k: float = 0.0) -> void:
	var ground := Vector3(at.x, 0.0, at.z)
	soft_flash(at, Color("#fff1d8"), 0.9, 0.14, 1.8)
	ring(ground + Vector3(0.0, 0.04, 0.0), 1.4, color.lightened(0.2), 0.4, 1.8, 0.12)
	ring(ground + Vector3(0.0, 0.05, 0.0), 0.8, Color("#fff1c8"), 0.22, 0.9, 0.1)
	burst(at, color.lightened(0.3), 14, 4.2, 1.0, 0.6, 0.45)
	burst(at, Color("#fff4d8"), 8, 5.5, 0.6, 0.8, 0.3)
	dust_ring(ground, 1.2, 12, 0.45, 0.6)
	debris(ground, dir, 10, 4.0)
	scorch(ground, 0.5, Color(0.5, 0.45, 0.4) if fire_k <= 0.0 else Color("#ff6a1a"), 1.4)
	if dir.length() > 0.01:
		streak(at - dir.normalized() * 2.0, at, color.lightened(0.45), 0.3, 0.32)
	if fire_k > 0.0:
		var fc := Color("#ff6a1a").lerp(Color("#ffd35a"), fire_k)
		fire_puff(at, fc, int(6 + 12 * fire_k), 0.3 + 0.25 * fire_k, 1.4 + 1.6 * fire_k, 0.55)


## 一圈贴地往外冲的尘土(普通混合：白地上是灰黄的烟，暗地上也看得见)：radius 冲多远，n 团数
func dust_ring(at: Vector3, radius: float, n: int = 14, size: float = 0.45, life: float = 0.7) -> void:
	var p := SoftFX.particles(n, life, SoftFX.ramp([Color(0.62, 0.57, 0.5, 0.0), Color(0.6, 0.55, 0.48, 0.55), Color(0.5, 0.46, 0.4, 0.25),
		Color(0.45, 0.42, 0.38, 0.0)], [0.0, 0.12, 0.55, 1.0]), size, false)
	var pm: ParticleProcessMaterial = p.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = 0.25
	pm.emission_ring_inner_radius = 0.1
	pm.emission_ring_height = 0.05
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 15.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.6
	pm.radial_velocity_min = radius * 2.4
	pm.radial_velocity_max = radius * 3.4
	pm.damping_min = radius * 3.0
	pm.damping_max = radius * 4.5
	pm.gravity = Vector3(0, 0.25, 0)
	p.one_shot = true
	p.explosiveness = 0.95
	p.emitting = true
	add_child(p)
	p.global_position = Vector3(at.x, 0.12, at.z)
	p.speed_scale = _pslow()
	get_tree().create_timer((life + 0.3) / _pslow()).timeout.connect(p.queue_free)


## 地上崩起来的碎块(体素小方块，沿 dir 往外 / 四面迸开、抛物线落下)
func debris(at: Vector3, dir: Vector3, n: int, speed: float, color: Color = Color(0.55, 0.5, 0.45)) -> void:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	var d := Vector3(dir.x, 0.0, dir.z)
	pm.direction = (d.normalized() + Vector3(0, 1.3, 0)).normalized() if d.length() > 0.01 else Vector3(0, 1, 0)
	pm.spread = 50.0 if d.length() > 0.01 else 75.0
	pm.initial_velocity_min = speed * 0.5
	pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, -12.0, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.3
	pm.angular_velocity_min = -400.0
	pm.angular_velocity_max = 400.0
	p.process_material = pm
	p.draw_pass_1 = _box
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	p.material_override = m
	p.amount = n
	p.lifetime = 0.7
	p.one_shot = true
	p.explosiveness = 0.95
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-4, -2, -4), Vector3(8, 6, 8))
	p.emitting = true
	add_child(p)
	p.global_position = Vector3(at.x, 0.1, at.z)
	p.speed_scale = _pslow()
	get_tree().create_timer(1.0 / _pslow()).timeout.connect(p.queue_free)


## 远距离飞扑 / 突进蹬地起跳：脚下一圈尘土往外冲、往后崩一把碎块、地上踩出一个浅坑，一道贴地的冲击环
func leap_takeoff(at: Vector3, dir: Vector3, color: Color) -> void:
	var g := Vector3(at.x, 0.0, at.z)
	dust_ring(g, 0.9, 10, 0.4, 0.55)
	debris(g, -dir, 9, 3.4)
	scorch(g, 0.42, Color(0.55, 0.5, 0.45), 1.2)
	ring(g + Vector3(0.0, 0.04, 0.0), 0.9, color.lerp(Color.WHITE, 0.4), 0.25, 1.2, 0.25)


## 砸到地上：一圈大的尘土冲击波 + 往四面崩的碎块 + 地上砸出一个坑 + 冲击环 + 一点闪光；
## fire_k(0..1) > 0 时(狩胜节点的光荣)：再炸开一圈火、火星四溅，越高越大
func leap_land(at: Vector3, dir: Vector3, color: Color, power: float = 1.0, fire_k: float = 0.0) -> void:
	var g := Vector3(at.x, 0.0, at.z)
	dust_ring(g, 1.6 * power, int(16 * power), 0.55 * power, 0.75)
	debris(g, Vector3.ZERO, int(14 * power), 4.2 * power)
	debris(g, dir, int(6 * power), 3.0 * power)
	scorch(g, 0.7 * power, Color(0.5, 0.45, 0.4) if fire_k <= 0.0 else Color("#ff6a1a"), 1.6)
	ring(g + Vector3(0.0, 0.04, 0.0), 1.7 * power, color.lerp(Color.WHITE, 0.3), 0.35, 1.8, 0.12)
	soft_flash(g + Vector3(0.0, 0.4, 0.0), color.lerp(Color.WHITE, 0.5), 0.9 * power, 0.14, 1.4)
	if fire_k > 0.0:
		var fc := Color("#ff6a1a").lerp(Color("#ffd35a"), clampf(fire_k * 1.2 - 0.2, 0.0, 1.0))
		fire_puff(g + Vector3(0.0, 0.3, 0.0), fc, int(6 + 14 * fire_k), 0.35 + 0.3 * fire_k, 1.6 + 2.0 * fire_k, 0.6, 0.3)
		burst(g + Vector3(0.0, 0.4, 0.0), Color("#ffc46a"), int(6 + 10 * fire_k), 3.0 + 2.0 * fire_k, 0.6, 1.4, 0.5)
		if fire_k >= 0.75:
			lava_splash(g + Vector3(0.0, 0.2, 0.0), 1.4 * power, fc)


## 扔出去的武器：刃尖拖一条光带(风切)、长矛再拖一条细的；光荣有层数时武器带着火飞(fire_k 0..1：火越大、火星越多)
func dress_thrown(node: Node3D, wclass: String, color: Color, fire_k: float) -> void:
	if node == null:
		return
	var bl: Dictionary = {"polearm": [0.75, 1.05], "heavy": [0.25, 0.95], "sword": [0.2, 0.7], "dual": [0.08, 0.33]}
	var seg: Array = bl.get(wclass, [0.2, 0.7])
	var tip := Node3D.new()
	tip.position = Vector3(0.0, float(seg[1]), 0.0)
	node.add_child(tip)
	var wind: Color = Color("#fff2dc").lerp(Color("#ff9a3a"), fire_k * 0.5)
	var rib: RibbonTrail = RibbonTrail.create(tip, wind, 0.045, 0.14)
	rib.name = "Ribbon"
	rib.time_scale = maxf(0.2, speed_scale)
	node.add_child(rib)
	if wclass == "polearm":
		var tail := Node3D.new()
		tail.position = Vector3(0.0, -0.4, 0.0)
		node.add_child(tail)
		var rib2: RibbonTrail = RibbonTrail.create(tail, color.lerp(Color.WHITE, 0.5), 0.03, 0.12)
		rib2.name = "Ribbon2"
		rib2.time_scale = maxf(0.2, speed_scale)
		node.add_child(rib2)
	if fire_k > 0.0:
		var c: Color = Color("#ff6a1a").lerp(Color("#ffd35a"), fire_k)
		var p: GPUParticles3D = SoftFX.particles(int(16 + 30 * fire_k), 0.35 + 0.2 * fire_k, SoftFX.fire_ramp(c, 1.5, false), 0.12 + 0.12 * fire_k)
		p.name = "Trail"
		var pm: ParticleProcessMaterial = p.process_material
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(0.03, (float(seg[1]) - float(seg[0])) * 0.5, 0.03)
		pm.direction = Vector3(0, 1, 0)
		pm.spread = 40.0
		pm.initial_velocity_min = 0.2
		pm.initial_velocity_max = 0.8
		pm.gravity = Vector3(0, 1.2, 0)
		(p.material_override as StandardMaterial3D).disable_fog = true
		p.visibility_aabb = AABB(Vector3(-12, -4, -12), Vector3(24, 10, 24))
		p.position = Vector3(0.0, (float(seg[0]) + float(seg[1])) * 0.5, 0.0)
		p.emitting = true
		node.add_child(p)


## 光荣跨过 5 / 8 / 10 层：武器上一下子腾起一团火，脚下一圈火光；stage 3(满)再加一道火柱
func weapon_ignite(at: Vector3, feet: Vector3, stage: int) -> void:
	var c: Color = [Color("#ff7a1a"), Color("#ff7a1a"), Color("#ffb02a"), Color("#ffd86a")][clampi(stage, 0, 3)]
	soft_flash(at, c.lerp(Color.WHITE, 0.3), 0.8 + 0.3 * float(stage), 0.25, 1.8)
	fire_puff(at, c, 8 + 4 * stage, 0.3 + 0.08 * float(stage), 1.4 + 0.4 * float(stage), 0.55)
	burst(at, Color("#ffd27a"), 8 + 4 * stage, 2.6, 0.6, 1.6, 0.5)
	ring(Vector3(feet.x, 0.04, feet.z), 1.0 + 0.3 * float(stage), c, 0.55, 1.6, 0.15)
	if stage >= 2:
		fire_puff(Vector3(feet.x, 0.2, feet.z), c, 10, 0.4, 1.8, 0.6, 0.2)
	if stage >= 3:
		pillar(Vector3(feet.x, 0.0, feet.z), Color("#ffd27a"), 0.7)
		lava_splash(Vector3(feet.x, 0.2, feet.z), 1.4, c)


## 赤焰战旗的强化：脚下一圈火色的波纹 + 往上窜的火星(溅射范围 = 一圈大的淡火环)
func banner_splash(center: Vector3, radius: float) -> void:
	var ground := Vector3(center.x, 0.0, center.z)
	var flame := Color("#ff6a1a")
	ring(ground, radius, flame, 0.6, 1.2, 0.1)
	ring(ground, 1.0, Color("#ffc23a"), 0.4, 1.6, 0.2)
	burst(center, flame, 14, 2.6, 1.0, 1.6, 0.7)
	burst(center, Color("#ffd35a"), 8, 3.2, 0.7, 2.0, 0.5)


## 爱心针剂打在敌人身上：粉红色的爆炸 + 往外崩的爱心碎片
func heart_burst(center: Vector3, radius: float) -> void:
	explosion(center, radius, Color("#ff3f86"), 1.0)
	float_icons(center, heart_mesh(), Color("#ff5c9c"), 8, radius * 0.35, 0.6, 0.9)


## 一颗大爱心：从 pos 弹出来(回弹放大)、往上升、淡掉
func _big_heart(pos: Vector3, color: Color) -> void:
	var m := MeshInstance3D.new()
	m.mesh = heart_mesh()
	var mat: StandardMaterial3D = _emissive(color, 2.8, 0.95).duplicate() as StandardMaterial3D
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true
	mat.render_priority = 20
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position = pos
	m.scale = Vector3.ONE * 0.5
	add_child(m)
	var s: float = maxf(0.2, speed_scale)
	var tw: Tween = create_tween()
	tw.tween_property(m, "scale", Vector3.ONE * 3.4, 0.16 / s).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "scale", Vector3.ONE * 2.8, 0.1 / s)
	tw.parallel().tween_property(m, "position:y", pos.y + 0.75, 0.7 / s).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.45 / s).set_delay(0.25 / s)
	tw.tween_callback(m.queue_free)


# ---------------------------------------------------------------- 投射物外观
## 沿 Z 轴的圆柱(look_at 让节点 -Z 对准目标：tip 端在 -Z)：z = 中心，r_tip = -Z 端半径，r_back = +Z 端半径
func _zcyl(parent: Node3D, r_tip: float, r_back: float, h: float, z: float, mat: Material, segs: int = 8) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_tip
	cm.bottom_radius = r_back
	cm.height = h
	cm.radial_segments = segs
	cm.rings = 1
	mi.mesh = cm
	mi.rotation.x = -PI * 0.5                 # 圆柱的 +Y(顶) → -Z(朝前)
	mi.position = Vector3(0, 0, z)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## 针剂飞镖(爱心针剂的普攻)：针尖朝前的小针筒——钢针、金色接头与金箍、半透明玻璃管里发光的药液(治疗 = 粉、伤害 = 血红)、
## 尾部指环、推杆与推板；飞行中绕自身轴滚转，一路洒下粉色小爱心(治疗)或血红的药滴(伤害)
func _syringe_dart(heal: bool) -> Node3D:
	var root := Node3D.new()
	var roll := Node3D.new()
	roll.name = "Roll"
	root.add_child(roll)
	# 亮色地面上发光太强会糊成一团白：药液用饱和色、低一点的发光，金属件用偏暗的颜色撑出轮廓
	var liq: Color = Color("#ff3d96") if heal else Color("#e8102e")
	var gold: StandardMaterial3D = _emissive(Color("#e0a020"), 1.0)
	var steel: StandardMaterial3D = _emissive(Color("#aeb8c8"), 1.0)
	var glass: StandardMaterial3D = _emissive(Color("#ffffff"), 1.0, 0.22)
	_zcyl(roll, 0.003, 0.007, 0.12, -0.22, steel, 6)            # 钢针
	_zcyl(roll, 0.011, 0.03, 0.045, -0.142, gold)              # 金色锥形接头
	_zcyl(roll, 0.043, 0.043, 0.014, -0.112, gold, 10)         # 前金箍
	_zcyl(roll, 0.03, 0.03, 0.15, -0.03, _emissive(liq, 1.5))       # 药液(发光)
	_zcyl(roll, 0.039, 0.039, 0.17, -0.02, glass, 10)          # 玻璃管
	_zcyl(roll, 0.043, 0.043, 0.014, 0.072, gold, 10)          # 后金箍
	var fl := MeshInstance3D.new()                             # 两侧指环(压扁的金框)
	var fb := BoxMesh.new()
	fb.size = Vector3(0.15, 0.022, 0.018)
	fl.mesh = fb
	fl.material_override = gold
	fl.position = Vector3(0, 0, 0.08)
	fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	roll.add_child(fl)
	_zcyl(roll, 0.008, 0.008, 0.06, 0.112, steel, 6)           # 推杆
	_zcyl(roll, 0.03, 0.03, 0.012, 0.146, gold, 10)            # 推板
	var halo := MeshInstance3D.new()                           # 药液的光晕
	var hm := SphereMesh.new()
	hm.radius = 0.07
	hm.height = 0.14
	hm.radial_segments = 10
	hm.rings = 5
	halo.mesh = hm
	halo.scale = Vector3(1.0, 1.0, 1.7)
	halo.position = Vector3(0, 0, -0.03)
	halo.material_override = _emissive(liq, 1.4, 0.12)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(halo)
	root.scale = Vector3.ONE * 1.75
	# 拖尾：治疗弹洒爱心(往上飘)，伤害弹洒药滴(往下落)
	var tr := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0.4, 0)
	pm.spread = 50.0
	pm.initial_velocity_min = 0.15
	pm.initial_velocity_max = 0.5
	pm.gravity = Vector3(0, 0.9, 0) if heal else Vector3(0, -3.5, 0)
	pm.scale_min = 1.0 if heal else 0.5
	pm.scale_max = 1.5 if heal else 1.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1.0))
	curve.add_point(Vector2(1, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	tr.process_material = pm
	tr.draw_pass_1 = heart_mesh() if heal else _box
	tr.material_override = _icon_mat(liq.lightened(0.15), 1.6) if heal else _emissive(liq, 1.6)
	tr.amount = 14 if heal else 18
	tr.lifetime = 0.45 if heal else 0.35
	tr.local_coords = false
	tr.emitting = true
	tr.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
	root.add_child(tr)
	return root


# ---------------------------------------------------------------- 通用手枪(第四批)：不射子弹的几种投射物 + 出手 / 命中小特效
## 刃轮(回旋双轮) / 纸牌(命运双牌) / 泡泡(泡泡枪) / 声波环(共振双铃)。飞行轨迹在 BattleView._update_projectiles，
## 出手(BattleView._on_release：不画枪口火光，换成 pistol_release)和命中(projectile_end：pistol_hit)
const PISTOL_PROJ := ["chakram", "card", "bubble", "sound_ring"]
const CHAKRAM_COLD := Color("#a8e4ee")                  # 刃轮的冷光
const CARD_CYAN := Color("#2aa6b4")
const RING_TEAL := Color("#26b4bc")                     # 声波环(亮地面上要看得见：饱和一点、不要太亮)
## 泡泡：半透明的彩虹皂膜——正对镜头的地方几乎透明，越往边上越不透明、颜色随视角和时间流动
const SOAP_SHADER := """
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, blend_mix, shadows_disabled;
uniform float fade = 1.0;
void fragment() {
	float f = 1.0 - abs(dot(normalize(NORMAL), normalize(VIEW)));
	float rim = pow(f, 1.5);
	float h = fract(rim * 1.3 + TIME * 0.22 + dot(NORMAL, vec3(0.35, 0.6, 0.2)) * 0.45);
	vec3 rainbow = 0.45 + 0.55 * cos(6.2831 * (h + vec3(0.0, 0.33, 0.67)));
	ALBEDO = mix(vec3(0.8, 0.92, 1.0), rainbow, 0.85);
	ALPHA = clamp(0.1 + rim * 1.1, 0.0, 1.0) * fade;
}
"""
var _soap_shader: Shader = null


func _soap_bubble_mat() -> ShaderMaterial:
	if _soap_shader == null:
		_soap_shader = Shader.new()
		_soap_shader.code = SOAP_SHADER
	var m := ShaderMaterial.new()
	m.shader = _soap_shader
	return m


func _pistol_projectile(kind: String) -> Node3D:
	var root := Node3D.new()
	match kind:
		"chakram":
			# 刃轮：深色钢环 + 一圈 12 颗锯齿(齿尖青白冷光)，平着(环面水平)飞、绕自身的竖轴高速旋转(Spin)；
			# 环面上一层淡淡的转动光盘(看起来转得快)，后面拖一道淡淡的冷光残影
			var spin := Node3D.new()
			spin.name = "Spin"
			root.add_child(spin)
			var tm := TorusMesh.new()
			tm.inner_radius = 0.12
			tm.outer_radius = 0.18
			tm.rings = 24
			tm.ring_segments = 4
			var rm := MeshInstance3D.new()
			rm.mesh = tm
			rm.scale = Vector3(1.0, 0.45, 1.0)
			rm.material_override = _solid(Color("#3a3e48"))
			rm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			spin.add_child(rm)
			for k in range(12):
				var a: float = TAU * float(k) / 12.0
				var tooth := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(0.075, 0.022, 0.03)
				tooth.mesh = bm
				tooth.material_override = _emissive(CHAKRAM_COLD, 1.4)
				tooth.position = Vector3(cos(a) * 0.2, 0.0, sin(a) * 0.2)
				tooth.rotation.y = -a + 0.5                      # 斜着往前翘(锯齿)
				tooth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				spin.add_child(tooth)
			var bar := MeshInstance3D.new()
			var bb := BoxMesh.new()
			bb.size = Vector3(0.025, 0.025, 0.24)
			bar.mesh = bb
			bar.material_override = _solid(Color("#3a2a22"))
			spin.add_child(bar)
			var blur := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.235
			cm.bottom_radius = 0.235
			cm.height = 0.004
			cm.radial_segments = 20
			blur.mesh = cm
			blur.material_override = _emissive(CHAKRAM_COLD, 1.0, 0.16)
			blur.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(blur)
			var rib: RibbonTrail = RibbonTrail.create(root, CHAKRAM_COLD, 0.1, 0.16)
			rib.name = "Ribbon"
			rib.time_scale = maxf(0.2, speed_scale)
			root.add_child(rib)
			root.scale = Vector3.ONE * 1.35
		"card":
			# 纸牌：一张平放的牌(牌背青色 + 金边、牌面米白 + 红方块)，直线飞、绕自己的横轴翻跟头(Flip)；后面一串青色闪光
			var flip := Node3D.new()
			flip.name = "Flip"
			root.add_child(flip)
			var parts := [[Vector3(0.17, 0.010, 0.24), Color("#c8a050"), Vector3.ZERO, false],
				[Vector3(0.14, 0.016, 0.21), CARD_CYAN, Vector3.ZERO, true],
				[Vector3(0.15, 0.004, 0.22), Color("#f2eee4"), Vector3(0, 0.0095, 0), false],
				[Vector3(0.05, 0.004, 0.07), Color("#c8283a"), Vector3(0, 0.0115, 0), false]]
			for pt: Array in parts:
				var cmi := MeshInstance3D.new()
				var cb := BoxMesh.new()
				cb.size = pt[0]
				cmi.mesh = cb
				cmi.material_override = _emissive(pt[1] as Color, 1.3) if bool(pt[3]) else _emissive(pt[1] as Color, 0.9)
				cmi.position = pt[2]
				if (pt[0] as Vector3).x < 0.06:
					cmi.rotation.y = PI * 0.25                   # 红方块(♦)
				cmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				flip.add_child(cmi)
			var glint := GPUParticles3D.new()
			var gpm := ParticleProcessMaterial.new()
			gpm.direction = Vector3(0, 0.3, 0)
			gpm.spread = 60.0
			gpm.initial_velocity_min = 0.05
			gpm.initial_velocity_max = 0.3
			gpm.gravity = Vector3.ZERO
			gpm.scale_min = 0.3
			gpm.scale_max = 0.7
			glint.process_material = gpm
			glint.draw_pass_1 = _box
			glint.material_override = _emissive(Color("#8ff0f4"), 2.4)
			glint.amount = 14
			glint.lifetime = 0.28
			glint.local_coords = false
			glint.emitting = true
			glint.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
			root.add_child(glint)
			var crib: RibbonTrail = RibbonTrail.create(root, CARD_CYAN.lightened(0.3), 0.05, 0.14)
			crib.name = "Ribbon"
			crib.time_scale = maxf(0.2, speed_scale)
			root.add_child(crib)
			root.scale = Vector3.ONE * 1.4
		"bubble":
			# 泡泡：半透明的彩虹泡泡(真的透明：着色器按视角算透明度)，左上一点白色高光；一胀一缩(Wobble)，后面飘几颗小泡泡
			var wob := Node3D.new()
			wob.name = "Wobble"
			root.add_child(wob)
			var bm2 := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.2
			sm.height = 0.4
			sm.radial_segments = 18
			sm.rings = 9
			bm2.mesh = sm
			bm2.material_override = _soap_bubble_mat()
			bm2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			wob.add_child(bm2)
			for hp: Array in [[Vector3(-0.085, 0.1, -0.07), 0.032], [Vector3(-0.04, 0.135, -0.035), 0.016]]:
				var hl := MeshInstance3D.new()
				var hs := SphereMesh.new()
				hs.radius = float(hp[1])
				hs.height = float(hp[1]) * 2.0
				hs.radial_segments = 6
				hs.rings = 3
				hl.mesh = hs
				hl.material_override = _emissive(Color("#ffffff"), 1.6, 0.85)
				hl.position = hp[0]
				hl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				wob.add_child(hl)
			var tb := GPUParticles3D.new()
			var tpm := ParticleProcessMaterial.new()
			tpm.direction = Vector3(0, 1, 0)
			tpm.spread = 50.0
			tpm.initial_velocity_min = 0.1
			tpm.initial_velocity_max = 0.3
			tpm.gravity = Vector3(0, 0.25, 0)
			tpm.scale_min = 0.5
			tpm.scale_max = 1.0
			tb.process_material = tpm
			var tsm := SphereMesh.new()
			tsm.radius = 0.045
			tsm.height = 0.09
			tsm.radial_segments = 8
			tsm.rings = 4
			tb.draw_pass_1 = tsm
			tb.material_override = _soap_bubble_mat()
			tb.amount = 8
			tb.lifetime = 0.55
			tb.local_coords = false
			tb.emitting = true
			tb.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
			root.add_child(tb)
			root.scale = Vector3.ONE * 1.4
		"sound_ring":
			# 声波环：两圈扁扁的环(环面正对目标)，边飞边变大、变淡(Ring 的缩放 + 材质透明度，BattleView 每帧按飞行进度设)
			var ring := Node3D.new()
			ring.name = "Ring"
			root.add_child(ring)
			var mats: Array = []
			for layer: Array in [[0.15, 0.225, 1.0, 1.2], [0.25, 0.285, 0.55, 1.0]]:
				var tm2 := TorusMesh.new()
				tm2.inner_radius = float(layer[0])
				tm2.outer_radius = float(layer[1])
				tm2.rings = 32
				tm2.ring_segments = 4
				var lm := MeshInstance3D.new()
				lm.mesh = tm2
				lm.rotation.x = PI * 0.5                         # 环的轴(Y)转到飞行方向(-Z)
				lm.scale = Vector3(1.0, 0.35, 1.0)               # 扁一点
				var mt := StandardMaterial3D.new()               # 每发自己一份材质(要单独淡掉)
				mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				mt.albedo_color = Color(RING_TEAL.r, RING_TEAL.g, RING_TEAL.b, float(layer[2]))
				mt.emission_enabled = true
				mt.emission = RING_TEAL
				mt.emission_energy_multiplier = float(layer[3])
				mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mt.set_meta("a0", float(layer[2]))
				lm.material_override = mt
				lm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				ring.add_child(lm)
				mats.append(mt)
			root.set_meta("mats", mats)
	return root


## 一圈涟漪：在 at 处、环面正对 dir 的扁环从 r0 长到 r1、淡掉
func _ripple(at: Vector3, dir: Vector3, color: Color, r0: float, r1: float, life: float, alpha: float = 0.8) -> void:
	var m := MeshInstance3D.new()
	m.mesh = _ring_mesh
	var mat: StandardMaterial3D = _emissive(color, 2.0, alpha).duplicate() as StandardMaterial3D
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	m.global_position = at
	var fwd: Vector3 = dir.normalized() if dir.length() > 0.01 else Vector3(0, 0, 1)
	var up: Vector3 = Vector3.UP if absf(fwd.y) < 0.95 else Vector3.RIGHT
	m.look_at(at + fwd, up)
	m.rotate_object_local(Vector3.RIGHT, PI * 0.5)       # 环的轴(Y)对着 dir
	m.scale = Vector3(r0, 0.12, r0)
	var s: float = maxf(0.2, speed_scale)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(m, "scale", Vector3(r1, 0.12, r1), life / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mat, "albedo_color:a", 0.0, life / s).set_delay(life * 0.3 / s)
	tw.chain().tween_callback(m.queue_free)


## 不射子弹的手枪出手：at = 出手的那只手(往前一点)，dir = 朝目标的水平方向
func pistol_release(kind: String, at: Vector3, dir: Vector3) -> void:
	match kind:
		"chakram":
			soft_flash(at, CHAKRAM_COLD, 0.45, 0.16, 1.6)
			burst(at, CHAKRAM_COLD, 4, 1.6, 0.4, 0.4, 0.18)
		"card":
			soft_flash(at, Color("#8ff0f4"), 0.5, 0.18, 1.8)
			burst(at, Color("#e6c070"), 3, 1.2, 0.4, 0.8, 0.22)
			burst(at, Color("#8ff0f4"), 3, 1.4, 0.35, 0.6, 0.2)
		"bubble":
			soft_flash(at, Color("#e8f6ff"), 0.4, 0.15, 1.2)
			burst(at + dir * 0.1, Color("#bfe6f8"), 5, 1.0, 0.45, 0.9, 0.3)
		"sound_ring":
			_ripple(at, dir, RING_TEAL, 0.06, 0.32, 0.3, 0.75)
			_ripple(at, dir, RING_TEAL.lightened(0.3), 0.03, 0.2, 0.22, 0.6)
		_:
			soft_flash(at, Color("#fff4dc"), 0.4, 0.15, 1.4)


## 不射子弹的手枪命中：at = 命中点(目标胸口)，dir = 飞来的水平方向
func pistol_hit(kind: String, at: Vector3, dir: Vector3) -> void:
	match kind:
		"chakram":
			# 一小簇火星(顺着飞来的方向往前崩) + 一点冷光
			soft_flash(at, CHAKRAM_COLD, 0.5, 0.14, 1.6)
			burst(at + dir * 0.05, Color("#ffc560"), 11, 3.4, 0.45, 0.5, 0.28)
			burst(at, Color("#fff6e0"), 4, 2.4, 0.3, 0.6, 0.18)
		"card":
			# 纸牌碎成几点光屑(青 + 金)，慢慢飘散
			soft_flash(at, Color("#8ff0f4"), 0.6, 0.2, 1.8)
			burst(at, CARD_CYAN.lightened(0.3), 7, 1.6, 0.45, 0.6, 0.45)
			burst(at, Color("#e6c070"), 4, 1.3, 0.4, 0.8, 0.5)
		"bubble":
			# "啪"：一闪 + 一圈很快散开的皂膜 + 几颗往下落的水珠
			soft_flash(at, Color("#e8f6ff"), 0.7, 0.14, 1.6)
			_ripple(at, Vector3.UP, Color("#7cc8ec"), 0.15, 0.5, 0.2, 0.8)
			burst(at, Color("#5ab4e0"), 10, 2.0, 0.5, 0.8, 0.45, false)
			burst(at, Color("#e8f8ff"), 3, 1.4, 0.35, 0.9, 0.3)
		"sound_ring":
			# 一圈涟漪(正对飞来的方向)，再晚一点一圈更大更淡的
			soft_flash(at, RING_TEAL, 0.45, 0.18, 1.3)
			_ripple(at, dir, RING_TEAL, 0.1, 0.6, 0.35, 0.8)
			_ripple(at, dir, RING_TEAL.lightened(0.25), 0.05, 0.9, 0.5, 0.45)
		_:
			burst(at, Color("#ffe6b0"), 5, 1.6, 0.8)


func make_projectile(kind: String, heal: bool, color: Color) -> Node3D:
	if ProjRegistry.has(kind):
		return ProjRegistry.make(self, kind, heal, color)   # 通用武器分批文件的投射物(game/view/proj_kinds/)
	if PISTOL_PROJ.has(kind):
		return _pistol_projectile(kind)          # 通用手枪(第四批)：刃轮 / 纸牌 / 泡泡 / 声波环
	if kind == "syringe_dart":
		return _syringe_dart(heal)
	if kind == "knife":
		return make_knife()
	if kind == "ember" or kind == "ember_violet":
		# 余烬的火弹(愤怒 / 怠惰 / 傲慢 / 贪婪……)：颜色 = 施放者那一种火(BattleView 按身体模型的身份色传进来；ember_violet = 贪婪的紫火)。
		# 三块打着转的熔岩碎块 + 一圈柔和的火光 + 往后拖的火焰团(柔光粒子：白热 → 主色 → 烟)
		var col: Color = GREED_VIOLET if kind == "ember_violet" else color
		var eb := Node3D.new()
		var spin := Node3D.new()
		spin.name = "Spin"
		eb.add_child(spin)
		for i in range(3):
			var m := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3.ONE * (0.15 - 0.03 * float(i))
			m.mesh = bm
			m.material_override = _emissive(col.lerp(Color(1, 0.96, 0.85), 0.25 + 0.25 * float(i)), 2.6 + 0.6 * float(i))
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			m.position = Vector3(0.06 * cos(float(i) * 2.1), 0.06 * sin(float(i) * 2.1), 0.0) if i > 0 else Vector3.ZERO
			m.rotation = Vector3(0.6 * float(i + 1), 0.7, 0.2 * float(i))
			spin.add_child(m)
		var tws: Tween = spin.create_tween().set_loops()
		tws.tween_property(spin, "rotation:z", TAU, 0.45).from(0.0)
		var halo := MeshInstance3D.new()
		halo.mesh = SoftFX.quad(0.75)
		halo.material_override = SoftFX.sprite_mat(col, 1.5)
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		eb.add_child(halo)
		var core := MeshInstance3D.new()
		core.mesh = SoftFX.quad(0.32)
		core.material_override = SoftFX.sprite_mat(col.lerp(Color(1, 0.97, 0.9), 0.7), 2.2)
		core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		eb.add_child(core)
		var tr := SoftFX.particles(26, 0.32, SoftFX.fire_ramp(col, 1.5), 0.26)
		var tpm: ParticleProcessMaterial = tr.process_material
		tpm.direction = Vector3(0, 0.4, 0)
		tpm.spread = 35.0
		tpm.initial_velocity_min = 0.1
		tpm.initial_velocity_max = 0.45
		tpm.gravity = Vector3(0, 0.8, 0)
		tr.emitting = true
		eb.add_child(tr)
		var sp := GPUParticles3D.new()
		var spm := ParticleProcessMaterial.new()
		spm.direction = Vector3(0, 1, 0)
		spm.spread = 60.0
		spm.initial_velocity_min = 0.3
		spm.initial_velocity_max = 0.9
		spm.gravity = Vector3(0, -1.5, 0)
		spm.scale_min = 0.25
		spm.scale_max = 0.5
		sp.process_material = spm
		sp.draw_pass_1 = _box
		sp.material_override = _emissive(col.lerp(Color(1, 0.95, 0.8), 0.4), 3.0)
		sp.amount = 10
		sp.lifetime = 0.4
		sp.local_coords = false
		sp.emitting = true
		sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sp.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
		eb.add_child(sp)
		return eb
	if kind == "light_arrow":
		# 光箭(和星节点)：金白发光的箭(用箭的网格，换成发光材质) + 一串光点
		var la := Node3D.new()
		var am := MeshInstance3D.new()
		am.mesh = arrow_mesh
		am.rotation.y = PI
		am.position = Vector3(ARROW_CENTER.x, -ARROW_CENTER.y, ARROW_CENTER.z)
		am.material_override = _emissive(Color("#fff1b0"), 4.0)
		am.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		la.add_child(am)
		la.scale = Vector3.ONE * 1.1
		var tr0 := GPUParticles3D.new()
		var pm0 := ParticleProcessMaterial.new()
		pm0.direction = Vector3(0, 0.2, 0)
		pm0.spread = 30.0
		pm0.initial_velocity_min = 0.05
		pm0.initial_velocity_max = 0.3
		pm0.gravity = Vector3.ZERO
		pm0.scale_min = 0.5
		pm0.scale_max = 0.9
		tr0.process_material = pm0
		tr0.draw_pass_1 = _box
		tr0.material_override = _emissive(Color("#ffe27a"), 3.0)
		tr0.amount = 16
		tr0.lifetime = 0.3
		tr0.local_coords = false
		tr0.emitting = true
		tr0.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
		la.add_child(tr0)
		return la
	if kind == "fan_ring":
		# 魔力飞环(舞扇)：一圈发光的环(外金内彩)，平着飞、自己高速旋转，拖一串亮点
		var fr := Node3D.new()
		var spin := Node3D.new()
		spin.name = "Spin"
		fr.add_child(spin)
		for layer: Array in [[0.22, 0.28, Color("#ffd875"), 3.0], [0.15, 0.21, color.lightened(0.35), 3.4]]:
			var ring_m := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = float(layer[0])
			tm.outer_radius = float(layer[1])
			tm.rings = 20
			tm.ring_segments = 5
			ring_m.mesh = tm
			ring_m.material_override = _emissive(layer[2] as Color, float(layer[3]))
			ring_m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			spin.add_child(ring_m)
		for k in range(4):
			var sp := MeshInstance3D.new()
			sp.mesh = _box
			sp.material_override = _emissive(Color("#fff2c0"), 3.5)
			var a: float = TAU * float(k) / 4.0
			sp.position = Vector3(cos(a) * 0.25, 0.0, sin(a) * 0.25)
			sp.scale = Vector3.ONE * 0.9
			spin.add_child(sp)
		var tr := GPUParticles3D.new()
		var tpm := ParticleProcessMaterial.new()
		tpm.direction = Vector3(0, 0.3, 0)
		tpm.spread = 60.0
		tpm.initial_velocity_min = 0.1
		tpm.initial_velocity_max = 0.4
		tpm.gravity = Vector3.ZERO
		tpm.scale_min = 0.4
		tpm.scale_max = 0.8
		tr.process_material = tpm
		tr.draw_pass_1 = _box
		tr.material_override = _emissive(color.lightened(0.5), 2.6)
		tr.amount = 12
		tr.lifetime = 0.3
		tr.local_coords = false
		tr.emitting = true
		tr.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
		fr.add_child(tr)
		return fr
	if kind == "arrow" or kind == "bolt":
		# 箭的网格沿 +Z 建模(z=0 箭尾 → z≈0.57 m 箭头)，而 look_at 让节点的 -Z 对准目标：
		# 所以把网格绕 Y 转 180°，并让箭身中点落在节点原点(箭头朝目标、飞行位置 = 箭身中点)
		var root := Node3D.new()
		var m := MeshInstance3D.new()
		m.mesh = arrow_mesh
		m.rotation.y = PI
		m.position = Vector3(ARROW_CENTER.x, -ARROW_CENTER.y, ARROW_CENTER.z)
		root.add_child(m)
		root.scale = Vector3.ONE * 0.9 if kind == "arrow" else Vector3(0.8, 0.8, 0.55)
		return root
	if kind == "bullet":
		# 子弹：细长的发光弹头 + 短拖尾
		var b := Node3D.new()
		var slug := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.035
		cm.height = 0.26
		cm.radial_segments = 6
		cm.rings = 2
		slug.mesh = cm
		slug.rotation.x = PI * 0.5
		slug.material_override = _emissive(Color("#ffe3a0"), 4.0)
		b.add_child(slug)
		var tail := MeshInstance3D.new()
		var tm := CapsuleMesh.new()
		tm.radius = 0.05
		tm.height = 0.7
		tm.radial_segments = 6
		tm.rings = 2
		tail.mesh = tm
		tail.rotation.x = PI * 0.5
		tail.position = Vector3(0, 0, 0.28)
		tail.material_override = _emissive(color.lightened(0.4), 2.0, 0.35)
		b.add_child(tail)
		return b
	var root := Node3D.new()
	var c: Color = COLORS["heal"] if heal else color
	var core := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.11
	sm.height = 0.22
	sm.radial_segments = 8
	sm.rings = 4
	core.mesh = sm
	core.material_override = _emissive(c.lightened(0.45), 3.5)
	root.add_child(core)
	var halo := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.2
	hm.height = 0.4
	hm.radial_segments = 8
	hm.rings = 4
	halo.mesh = hm
	halo.material_override = _emissive(c, 2.0, 0.35)
	root.add_child(halo)
	var trail := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0.2, 0)
	pm.spread = 40.0
	pm.initial_velocity_min = 0.1
	pm.initial_velocity_max = 0.5
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	trail.process_material = pm
	trail.draw_pass_1 = _box
	trail.material_override = _emissive(c, 2.4)
	trail.amount = 14
	trail.lifetime = 0.35
	trail.local_coords = false
	trail.emitting = true
	trail.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
	root.add_child(trail)
	return root


# ---------------------------------------------------------------- 清扫节点：飞刀 / 时停 / 怀表
var _knife_blade: ArrayMesh = null


## 飞刀的刀身：菱形截面的双刃(刀尖朝 -Z)
func _knife_blade_mesh() -> ArrayMesh:
	if _knife_blade != null:
		return _knife_blade
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tip := Vector3(0, 0, -0.25)
	var ring_p: Array[Vector3] = [Vector3(0.036, 0, -0.05), Vector3(0, 0.012, -0.05), Vector3(-0.036, 0, -0.05), Vector3(0, -0.012, -0.05)]
	for i in range(4):
		st.add_vertex(tip)
		st.add_vertex(ring_p[i])
		st.add_vertex(ring_p[(i + 1) % 4])
	st.add_vertex(ring_p[0])
	st.add_vertex(ring_p[2])
	st.add_vertex(ring_p[1])
	st.add_vertex(ring_p[0])
	st.add_vertex(ring_p[3])
	st.add_vertex(ring_p[2])
	st.generate_normals()
	_knife_blade = st.commit()
	return _knife_blade


## 一把飞刀(闪烁刀刃 / 清扫节点的飞刀)：银色菱形双刃、红宝石护手、黑缠柄、尾环；刀尖朝 -Z(look_at 朝目标)。
## Glow = 停在半空时的红色光晕(越停越亮，BattleView 调它的透明度)，Trail = 飞行时的拖尾
func make_knife() -> Node3D:
	var root := Node3D.new()
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var steel := StandardMaterial3D.new()
	steel.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	steel.albedo_color = Color("#dfe4ee")
	steel.cull_mode = BaseMaterial3D.CULL_DISABLED
	var blade := MeshInstance3D.new()
	blade.mesh = _knife_blade_mesh()
	blade.material_override = steel
	blade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(blade)
	var edge := MeshInstance3D.new()                   # 刃口的一线亮光(从上往下看也有轮廓)
	var em := BoxMesh.new()
	em.size = Vector3(0.008, 0.026, 0.19)
	edge.mesh = em
	edge.position = Vector3(0, 0, -0.14)
	edge.material_override = _emissive(Color("#ffffff"), 1.6)
	edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(edge)
	for part: Array in [[Vector3(0.085, 0.03, 0.026), Vector3(0, 0, -0.04), Color("#b8c0cc"), 1.0],     # 护手
			[Vector3(0.03, 0.036, 0.03), Vector3(0, 0, -0.04), Color("#e8203a"), 2.2],                 # 红宝石
			[Vector3(0.026, 0.026, 0.09), Vector3(0, 0, 0.01), Color("#26232b"), 0.6]]:                # 黑缠柄
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = part[0]
		mi.mesh = bm
		mi.position = part[1]
		mi.material_override = _emissive(part[2], float(part[3]))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(mi)
	var ring_m := MeshInstance3D.new()                 # 尾环
	var tm := TorusMesh.new()
	tm.inner_radius = 0.014
	tm.outer_radius = 0.024
	tm.rings = 10
	tm.ring_segments = 4
	ring_m.mesh = tm
	ring_m.rotation = Vector3(0, 0, PI * 0.5)
	ring_m.position = Vector3(0, 0, 0.075)
	ring_m.material_override = _emissive(Color("#b8c0cc"), 1.0)
	ring_m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(ring_m)
	# 停住时的光：一团柔和的光(越停越红、越亮；不再是拉长的一条，满天的飞刀不会变成一根根糖果棍)
	var glow := MeshInstance3D.new()
	glow.name = "Glow"
	glow.mesh = SoftFX.quad(0.22)
	var gmat: StandardMaterial3D = SoftFX.sprite_mat(Color("#ffffff"), 1.0, false)       # 每把一份：越停越红
	gmat.albedo_color = Color(1.0, 0.55, 0.6, 0.0)
	gmat.disable_fog = true
	glow.material_override = gmat
	glow.position = Vector3(0, 0, -0.08)
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(glow)
	# 停住时套在刀身上的一圈小表圈(四道刻度，慢慢转；越停越红)
	var halo := Node3D.new()
	halo.name = "Halo"
	halo.position = Vector3(0, 0, -0.08)
	halo.visible = false
	root.add_child(halo)
	var hmat := StandardMaterial3D.new()
	hmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hmat.albedo_color = Color(0.95, 0.97, 1.0, 0.85)
	hmat.disable_fog = true
	var htm := TorusMesh.new()
	htm.inner_radius = 0.052
	htm.outer_radius = 0.06
	htm.rings = 24
	htm.ring_segments = 3
	var hr := MeshInstance3D.new()
	hr.mesh = htm
	hr.rotation.x = PI * 0.5                    # 圈面垂直于刀身
	hr.material_override = hmat
	hr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.add_child(hr)
	var tb := BoxMesh.new()
	tb.size = Vector3(0.008, 0.024, 0.006)
	for i in range(4):
		var tk := MeshInstance3D.new()
		tk.mesh = tb
		var ta: float = PI * 0.5 * float(i)
		tk.position = Vector3(sin(ta) * 0.045, cos(ta) * 0.045, 0.0)
		tk.rotation.z = -ta
		tk.material_override = hmat
		tk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		halo.add_child(tk)
	var hspin: Tween = halo.create_tween().set_loops()
	hspin.tween_property(halo, "rotation:z", TAU, 2.4).from(0.0)
	# 飞行的拖尾：一条细细的银光(带一点红边)，停住时暂停
	var rib: RibbonTrail = RibbonTrail.create(root, Color("#ff6a7a"), 0.035, 0.16)
	rib.name = "Ribbon"
	rib.time_scale = maxf(0.2, speed_scale)
	root.add_child(rib)
	# 刀尖迸出的几点银光(飞行时)
	var tr: GPUParticles3D = SoftFX.particles(10, 0.25, SoftFX.ramp([Color(1, 1, 1, 0.0), Color(1.0, 0.95, 0.96, 0.9), Color(1.0, 0.6, 0.65, 0.0)], [0.0, 0.15, 1.0]), 0.03, true)
	tr.name = "Trail"
	var pm: ParticleProcessMaterial = tr.process_material
	pm.direction = Vector3(0, 0.2, 0)
	pm.spread = 40.0
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.25
	(tr.material_override as StandardMaterial3D).disable_fog = true
	tr.visibility_aabb = AABB(Vector3(-8, -3, -8), Vector3(16, 8, 16))
	tr.emitting = true
	root.add_child(tr)
	root.scale = Vector3.ONE * 2.3              # 俯视镜头下一把刀也要看得出形状
	return root


## 停在半空的飞刀：k = 0..1(停得越久越接近 1)——红色光晕越来越亮，刀身微微发红
## 停着的飞刀越停越"烫"(完美时计的增伤)：光团越红越大、表圈从银白变红；hover = 停在半空(才显示表圈)
func knife_heat(node: Node3D, k: float, pulse: float, hover: bool = true) -> void:
	var g: MeshInstance3D = node.get_node_or_null("Glow") as MeshInstance3D
	if g == null:
		return
	var m: StandardMaterial3D = g.material_override as StandardMaterial3D
	var a: float = clampf(0.25 + 0.35 * k + 0.12 * pulse * k, 0.0, 0.8) if hover else 0.0
	m.albedo_color = Color(1.0, lerpf(0.75, 0.15, k), lerpf(0.8, 0.22, k), a)
	g.scale = Vector3.ONE * (1.0 + 0.8 * k)
	var halo: Node3D = node.get_node_or_null("Halo") as Node3D
	if halo != null:
		halo.visible = hover
		halo.scale = Vector3.ONE * (1.0 + 0.25 * k)
		var hm: MeshInstance3D = halo.get_child(0) as MeshInstance3D
		if hm != null:
			(hm.material_override as StandardMaterial3D).albedo_color = Color(1.0, lerpf(0.97, 0.3, k), lerpf(1.0, 0.36, k), 0.85)


## 飞刀刚停住：刀尖一点"咔"的闪光 + 一圈很小的表圈
func knife_freeze(at: Vector3) -> void:
	soft_flash(at, Color("#e8f2ff"), 0.35, 0.12, 1.6)
	burst(at, Color("#ffe4e8"), 3, 0.8, 0.45, 0.2, 0.18)


## 停着的飞刀放出去的那一下：表圈一下崩开(往外扩着淡掉)
func knife_unfreeze(at: Vector3) -> void:
	soft_flash(at, Color("#fff0f2"), 0.4, 0.1, 1.8)
	burst(at, Color("#ffd0d6"), 4, 1.6, 0.4, 0.2, 0.2)


## 停着的飞刀一起放出去：目标身上一圈怀表刻度闪一下
func knife_release(at: Vector3, color: Color) -> void:
	clock_face(Vector3(at.x, 0.0, at.z), color, 0.75, 0.45)
	burst(at + Vector3(0, 0.3, 0), Color("#fff0f2"), 6, 2.0, 0.6, 0.4, 0.25)


## 发射者倒下：停着的飞刀掉在地上，躺一会儿淡出
func knife_drop(node: Node3D) -> void:
	if node == null or not is_instance_valid(node):
		return
	var tr: GPUParticles3D = node.get_node_or_null("Trail") as GPUParticles3D
	if tr != null:
		tr.emitting = false
	knife_heat(node, 0.0, 0.0)
	var s: float = maxf(0.2, speed_scale)
	var fall: float = 0.35 + node.position.y * 0.25
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(node, "position:y", 0.04, fall / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(node, "rotation:x", 0.0, fall / s)
	tw.chain().tween_interval(0.8 / s)
	tw.chain().tween_property(node, "scale", Vector3.ONE * 0.01, 0.35 / s)
	tw.chain().tween_callback(node.queue_free)


## 目标没了：瞄着它的飞刀碎成几点光消失
func knife_vanish(node: Node3D) -> void:
	if node == null or not is_instance_valid(node):
		return
	burst(node.global_position, Color("#ffd6dc"), 4, 1.0, 0.5, 0.3, 0.25)
	node.queue_free()


## 清洁世界(时间停止)：她脚下一面大怀表——两圈表圈、罗马数字位置的 12 道刻度、两根表针飞快地倒转然后"咔"地停住，
## 外圈一圈慢慢转的齿轮齿；停 hold 秒后表针重新走一格、整面淡掉。返回根节点
func timestop_clock(at: Vector3, radius: float, hold: float) -> Node3D:
	var s: float = maxf(0.2, speed_scale)
	var root := Node3D.new()
	root.position = Vector3(at.x, 0.04, at.z)
	add_child(root)
	var gold := StandardMaterial3D.new()
	gold.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gold.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gold.albedo_color = Color(1.0, 0.86, 0.55, 0.0)
	gold.disable_fog = true
	gold.cull_mode = BaseMaterial3D.CULL_DISABLED
	var pale := gold.duplicate() as StandardMaterial3D
	pale.albedo_color = Color(0.9, 0.96, 1.0, 0.0)
	var mats: Array = [gold, pale]
	for rr: Array in [[1.0, 0.05, gold], [0.9, 0.02, pale], [0.32, 0.02, pale]]:
		var rm := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = radius * (float(rr[0]) - float(rr[1]))
		tm.outer_radius = radius * float(rr[0])
		tm.rings = 64
		tm.ring_segments = 4
		rm.mesh = tm
		rm.scale = Vector3(1.0, 0.1, 1.0)
		rm.material_override = rr[2]
		rm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(rm)
	var gear := Node3D.new()
	root.add_child(gear)
	var gb := BoxMesh.new()
	gb.size = Vector3(radius * 0.05, 0.01, radius * 0.06)
	for i in range(36):
		var a: float = TAU * float(i) / 36.0
		var gm := MeshInstance3D.new()
		gm.mesh = gb
		gm.material_override = gold
		gm.position = Vector3(sin(a), 0.0, cos(a)) * radius * 1.04
		gm.rotation.y = a
		gm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		gear.add_child(gm)
	for i in range(12):
		var a2: float = TAU * float(i) / 12.0
		var long: bool = i % 3 == 0
		var bm := BoxMesh.new()
		bm.size = Vector3(radius * (0.035 if long else 0.02), 0.01, radius * (0.16 if long else 0.08))
		var m := MeshInstance3D.new()
		m.mesh = bm
		m.material_override = pale if not long else gold
		m.position = Vector3(sin(a2), 0.0, cos(a2)) * radius * (0.78 if long else 0.82)
		m.rotation.y = a2
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(m)
	var hands: Array = []
	for hd: Array in [[0.5, 0.045], [0.75, 0.028]]:
		var piv := Node3D.new()
		var hm := MeshInstance3D.new()
		var hb := BoxMesh.new()
		hb.size = Vector3(radius * float(hd[1]), 0.012, radius * float(hd[0]))
		hm.mesh = hb
		hm.position = Vector3(0, 0.006, radius * float(hd[0]) * 0.5)
		hm.material_override = gold
		hm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		piv.add_child(hm)
		root.add_child(piv)
		hands.append(piv)
	var total: float = 0.25 + hold + 0.4
	var tw: Tween = create_tween()
	tw.tween_method(func(k: float) -> void:
		if not is_instance_valid(root):
			return
		var t: float = k * total
		var a_in: float = clampf(t / 0.2, 0.0, 1.0)
		var a_out: float = 1.0 - clampf((t - 0.25 - hold) / 0.4, 0.0, 1.0)
		for mm: Variant in mats:
			(mm as StandardMaterial3D).albedo_color.a = 0.9 * a_in * a_out
		root.scale = Vector3.ONE * lerpf(0.6, 1.0, 1.0 - pow(1.0 - a_in, 3.0))
		gear.rotation.y = -t * 0.6
		# 表针：前 0.25 秒飞快地倒转，然后停住；最后时间恢复时往前走一格
		var spin_t: float = clampf(t / 0.25, 0.0, 1.0)
		var stop: float = (1.0 - pow(1.0 - spin_t, 3.0))
		var tick: float = clampf((t - 0.25 - hold) / 0.06, 0.0, 1.0)
		(hands[0] as Node3D).rotation.y = -TAU * 1.5 * stop - 0.52 * tick
		(hands[1] as Node3D).rotation.y = -TAU * 6.0 * stop - 0.1 * tick, 0.0, 1.0, total / s)
	tw.tween_callback(root.queue_free)
	return root


## 怀表的表盘(清扫节点：瞬移的起点 / 落点、飞刀放出去的那一下)：地上一圈表圈 + 12 道刻度(3/6/9/12 点长) + 两根表针转一下，然后淡出
func clock_face(at: Vector3, color: Color, radius: float = 0.9, life: float = 0.6) -> void:
	var root := Node3D.new()
	root.position = Vector3(at.x, 0.035, at.z)
	add_child(root)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(color.r, color.g, color.b, 0.9)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var pale := mat.duplicate() as StandardMaterial3D
	pale.albedo_color = Color(1.0, 0.95, 0.9, 0.9)
	for rr: Array in [[1.0, 0.07, mat], [0.86, 0.025, pale]]:
		var rm := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = radius * (float(rr[0]) - float(rr[1]))
		tm.outer_radius = radius * float(rr[0])
		tm.rings = 48
		tm.ring_segments = 4
		rm.mesh = tm
		rm.scale = Vector3(1.0, 0.12, 1.0)
		rm.material_override = rr[2]
		rm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(rm)
	for i in range(12):
		var a: float = TAU * float(i) / 12.0
		var long: bool = i % 3 == 0
		var bm := BoxMesh.new()
		bm.size = Vector3(0.035 if long else 0.022, 0.01, radius * (0.2 if long else 0.11))
		var m := MeshInstance3D.new()
		m.mesh = bm
		m.material_override = pale
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var rr2: float = radius * (0.72 if long else 0.77)
		m.position = Vector3(sin(a) * rr2, 0.0, cos(a) * rr2)
		m.rotation.y = a
		root.add_child(m)
	var hands := Node3D.new()
	root.add_child(hands)
	for hd: Array in [[0.42, 0.045], [0.66, 0.03]]:
		var bm2 := BoxMesh.new()
		bm2.size = Vector3(float(hd[1]), 0.012, radius * float(hd[0]))
		var hm := MeshInstance3D.new()
		hm.mesh = bm2
		hm.position = Vector3(0, 0.005, -radius * float(hd[0]) * 0.5)
		hm.material_override = mat
		hm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var piv := Node3D.new()
		piv.rotation.y = randf() * TAU
		piv.add_child(hm)
		hands.add_child(piv)
	var s: float = maxf(0.2, speed_scale)
	root.scale = Vector3.ONE * 0.55
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(root, "scale", Vector3.ONE, 0.16 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(hands, "rotation:y", -TAU * 0.5, life / s)
	tw.tween_property(mat, "albedo_color:a", 0.0, life / s).set_ease(Tween.EASE_IN)
	tw.tween_property(pale, "albedo_color:a", 0.0, life / s).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(root.queue_free)


# ---------------------------------------------------------------- 星旅节点：坠落 / 落地 / 外神之貌
## 坠落的拖尾(挂在模型上跟着落)：蓝白的星光 + 往上飘的光点
func comet_trail() -> Node3D:
	var root := Node3D.new()
	var core := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.45
	sm.height = 0.9
	sm.radial_segments = 10
	sm.rings = 5
	core.mesh = sm
	core.position = Vector3(0, 0.7, 0)
	core.material_override = _emissive(Color("#9fd0ff"), 3.0, 0.35)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(core)
	var tr := GPUParticles3D.new()
	tr.name = "Trail"
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.35
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 3.0
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.8
	pm.scale_max = 1.8
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1.0))
	curve.add_point(Vector2(1, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	tr.process_material = pm
	tr.draw_pass_1 = _box
	tr.material_override = _emissive(Color("#cfe6ff"), 3.4)
	tr.amount = 90
	tr.lifetime = 0.6
	tr.local_coords = false
	tr.emitting = true
	tr.visibility_aabb = AABB(Vector3(-8, -20, -8), Vector3(16, 40, 16))
	tr.position = Vector3(0, 0.7, 0)
	root.add_child(tr)
	return root


func end_comet(node: Node3D) -> void:
	if node == null or not is_instance_valid(node):
		return
	var tr: GPUParticles3D = node.get_node_or_null("Trail") as GPUParticles3D
	if tr != null:
		var gx: Transform3D = tr.global_transform
		node.remove_child(tr)
		add_child(tr)
		tr.global_transform = gx
		tr.emitting = false
		get_tree().create_timer(tr.lifetime + 0.3).timeout.connect(tr.queue_free)
	node.queue_free()


## 坠落的目标点：地上一圈蓝色的预警圈(落点范围)，落地时消失
func starfall_warn(at: Vector3, radius: float, life: float) -> void:
	var root := Node3D.new()
	root.position = Vector3(at.x, 0.04, at.z)
	add_child(root)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.5, 0.75, 1.0, 0.0)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rm := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = radius - 0.06
	tm.outer_radius = radius
	tm.rings = 64
	tm.ring_segments = 4
	rm.mesh = tm
	rm.scale = Vector3(1.0, 0.1, 1.0)
	rm.material_override = mat
	rm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(rm)
	var s: float = maxf(0.2, speed_scale)
	var tw: Tween = create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.9, life * 0.5 / s)
	tw.tween_property(rm, "scale", Vector3(0.15, 0.1, 0.15), life * 0.5 / s).set_ease(Tween.EASE_IN)
	tw.tween_callback(root.queue_free)


## 落地：蓝紫色的冲击 + 落点范围的冲击环 + 往外崩的碎屑与星光
func starfall_impact(at: Vector3, radius: float) -> void:
	var g := Vector3(at.x, 0.0, at.z)
	explosion(g + Vector3(0, 0.3, 0), radius * 0.8, Color("#5a8cff"), 1.1)
	ring(g, radius, Color("#9fd0ff"), 0.5, 2.0, 0.2)
	ring(g, radius * 0.6, Color("#ffffff"), 0.3, 1.2, 0.1)
	burst(g + Vector3(0, 0.4, 0), Color("#cfe6ff"), 18, 5.0, 1.0, 1.4, 0.6)
	burst(g + Vector3(0, 0.1, 0), Color(0.3, 0.3, 0.36), 12, 3.0, 1.4, 1.4, 0.7, false)



## 外神之貌(锁血)醒来的一瞬：一团深紫的黑暗炸开、一道品红的光环、往上冲的虚空碎屑和一圈暗紫的雾
func outer_awaken(at: Vector3) -> void:
	var g := Vector3(at.x, 0.0, at.z)
	soft_flash(g + Vector3(0.0, 1.0, 0.0), Color("#b04dff"), 2.2, 0.35, 1.6)
	ring(g + Vector3(0.0, 0.04, 0.0), 2.6, Color("#c04dff"), 0.55, 2.0, 0.1)
	ring(g + Vector3(0.0, 0.06, 0.0), 1.6, Color("#2a0a44"), 0.7, 2.4, 0.1)
	burst(g + Vector3(0.0, 0.6, 0.0), Color("#1a0630"), 22, 3.4, 1.4, 1.6, 0.8, false)
	burst(g + Vector3(0.0, 0.8, 0.0), Color("#e0b0ff"), 14, 4.0, 0.8, 1.8, 0.6)
	var p := SoftFX.particles(18, 1.0, SoftFX.ramp([Color(0.3, 0.05, 0.5, 0.0), Color(0.25, 0.04, 0.42, 0.6), Color(0.06, 0.0, 0.12, 0.0)], [0.0, 0.25, 1.0]), 0.8, false)
	var pm: ParticleProcessMaterial = p.process_material
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 80.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 2.6
	pm.damping_min = 1.5
	pm.damping_max = 2.5
	(p.material_override as StandardMaterial3D).disable_fog = true
	p.one_shot = true
	p.explosiveness = 0.9
	p.emitting = true
	add_child(p)
	p.global_position = g + Vector3(0.0, 0.4, 0.0)
	p.speed_scale = _pslow()
	get_tree().create_timer(1.4 / _pslow()).timeout.connect(p.queue_free)


## 触手抽中一个敌人：暗紫的一闪、虚空碎屑往外溅、几点星光
func tentacle_hit(at: Vector3) -> void:
	soft_flash(at, Color("#a040ff"), 0.7, 0.16, 1.4)
	burst(at, Color("#1a0630"), 9, 2.6, 1.0, 0.6, 0.45, false)
	burst(at, Color("#e6b8ff"), 6, 3.0, 0.6, 0.8, 0.35)
	ring(Vector3(at.x, 0.04, at.z), 0.55, Color("#9b4dff"), 0.3, 1.2, 0.2)


## 真实形态触发一次：脚下一圈深紫的波纹扩到溅射范围
func outer_pulse(at: Vector3, radius: float) -> void:
	ring(Vector3(at.x, 0.0, at.z), radius, Color("#9b4dff"), 0.45, 1.6, 0.15)
	burst(at + Vector3(0, 0.8, 0), Color("#c58cff"), 6, 2.0, 0.7, 0.6, 0.35)


## 锁血结束、必定死亡：虚空外壳往里塌缩再炸开
func outer_collapse(at: Vector3) -> void:
	# 一团黑暗把她裹住、往里塌成一个点(0.3 秒)，然后一闪、品红光环炸开、星屑四散
	var g := Vector3(at.x, 0.0, at.z)
	var s: float = maxf(0.2, speed_scale)
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 20
	sm.rings = 10
	m.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.03, 0.0, 0.07, 0.85)
	mat.disable_fog = true
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	m.global_position = g + Vector3(0.0, 1.0, 0.0)
	m.scale = Vector3.ONE * 1.5
	var tw: Tween = create_tween()
	tw.tween_property(m, "scale", Vector3.ONE * 0.04, 0.3 / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(func() -> void:
		soft_flash(g + Vector3(0.0, 1.0, 0.0), Color("#e0a8ff"), 2.0, 0.25, 2.0)
		burst(g + Vector3(0, 1.0, 0), Color("#2a0a44"), 16, 3.0, 1.2, 1.0, 0.7, false)
		burst(g + Vector3(0, 1.0, 0), Color("#d7a8ff"), 16, 4.4, 0.8, 1.2, 0.5)
		ring(g + Vector3(0.0, 0.05, 0.0), 2.4, Color("#c04dff"), 0.5, 1.8, 0.1)
		m.queue_free())


# ---------------------------------------------------------------- 改修节点：全息准星
## 枪口前面立起来一个紫色的全息靶环(角色卡上那个)：两圈环 + 十字刻度 + 中心点，朝着射击方向，一闪而过
func holo_reticle(at: Vector3, dir: Vector3) -> void:
	var root := Node3D.new()
	add_child(root)
	root.position = at
	if dir.length() > 0.01:
		root.look_at(at + dir, Vector3.UP)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.72, 0.45, 1.0, 0.9)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for rr: Array in [[0.34, 0.03], [0.2, 0.02]]:
		var rm := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = float(rr[0]) - float(rr[1])
		tm.outer_radius = float(rr[0])
		tm.rings = 32
		tm.ring_segments = 4
		rm.mesh = tm
		rm.rotation.x = PI * 0.5                     # 环面竖起来，朝着射击方向(-Z)
		rm.scale = Vector3(1.0, 0.2, 1.0)
		rm.material_override = mat
		rm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(rm)
	for i in range(4):
		var bm := BoxMesh.new()
		bm.size = Vector3(0.02, 0.14, 0.01)
		var tick := MeshInstance3D.new()
		tick.mesh = bm
		var a: float = PI * 0.5 * float(i)
		tick.position = Vector3(sin(a) * 0.27, cos(a) * 0.27, 0.0)
		tick.rotation.z = -a
		tick.material_override = mat
		tick.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(tick)
	var dot := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(0.05, 0.05, 0.01)
	dot.mesh = dm
	dot.material_override = _emissive(Color("#e8ccff"), 3.0)
	root.add_child(dot)
	var s: float = maxf(0.2, speed_scale)
	root.scale = Vector3.ONE * 0.4
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(root, "scale", Vector3.ONE * 1.1, 0.12 / s).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.5 / s).set_delay(0.15 / s)
	tw.chain().tween_callback(root.queue_free)


# ---------------------------------------------------------------- 幻彩节点：颜料 / 少女幻终
const PAINT_COLORS := {"red": Color("#ff4a5e"), "blue": Color("#4a8cff")}


## 拿到颜料：手边炸开一小团颜料点
func paint_gain(at: Vector3, color: String) -> void:
	var c: Color = PAINT_COLORS.get(color, Color.WHITE)
	burst(at, c, 9, 1.8, 0.9, 1.3, 0.45)
	ring(Vector3(at.x, 0.02, at.z), 0.55, c, 0.35, 1.2, 0.3)


## 用掉颜料：打中的地方泼开一大团颜料(颜料点 + 一圈波纹)
func paint_splash(at: Vector3, color: String) -> void:
	var c: Color = PAINT_COLORS.get(color, Color.WHITE)
	burst(at, c, 16, 3.0, 1.2, 0.7, 0.55, false)
	burst(at, c.lightened(0.4), 6, 2.0, 0.8, 1.2, 0.4)
	ring(Vector3(at.x, 0.02, at.z), 0.8, c, 0.4, 1.4, 0.2)


## 身上的颜料：头顶边上一颗转着的发光颜料块(红 / 蓝)；挂在 parent 下面
func paint_orb(parent: Node3D, offset: Vector3, color: String) -> Node3D:
	var root := Node3D.new()
	root.position = offset
	parent.add_child(root)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.11, 0.11, 0.11)
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	mi.material_override = _emissive(PAINT_COLORS.get(color, Color.WHITE), 3.0)
	mi.position = Vector3(0.16, 0.0, 0.0)
	mi.rotation = Vector3(0.6, 0.0, 0.6)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	var tw := root.create_tween().set_loops()
	tw.tween_property(root, "rotation:y", TAU, 1.1).from(0.0)
	return root


## 少女幻终的领域：领域里的世界变成黑白水墨(纸白 / 墨黑 / 网点 + 墨线轮廓)，领域外整张地图褪成灰色——世界的颜色都被她抽走了，
## 只有她自己(和她的颜料)还是彩色的(DomainFX ink)。里面漂着红 / 蓝 / 白的颜料块(彩色：在去色之后画)；地上一圈毛糙的墨圈(着色器画)。
## BattleView 每帧 magi_domain_keep 把"留色的圆柱"摆到她身上(她悬浮着)
func magi_domain(at: Vector3, radius: float) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	root.position = Vector3(at.x, 0.0, at.z)
	var sp: float = 1.0 / maxf(0.25, speed_scale)
	var dfx := DomainFX.make("ink", root.position, radius)
	add_child(dfx)
	dfx.open(0.5 * sp, 0.85)
	# 漂浮的颜料块(红 / 蓝 / 白)：黑白世界里唯一的颜色
	var pt := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = radius * 0.9
	pm.emission_ring_inner_radius = 0.6
	pm.emission_ring_height = 0.4
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 25.0
	pm.initial_velocity_min = 0.15
	pm.initial_velocity_max = 0.5
	pm.gravity = Vector3(0, 0.1, 0)
	pm.scale_min = 1.0
	pm.scale_max = 2.2
	pm.angular_velocity_min = -160.0
	pm.angular_velocity_max = 160.0
	# 只取纯红 / 白 / 纯蓝三种(阶梯渐变，不插值成粉、浅蓝)
	var grad := Gradient.new()
	grad.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	grad.offsets = PackedFloat32Array([0.0, 0.42, 0.58])
	grad.colors = PackedColorArray([PAINT_COLORS["red"], Color("#fff6e8"), PAINT_COLORS["blue"]])
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_initial_ramp = gt
	pt.process_material = pm
	pt.draw_pass_1 = _box
	var pmat := StandardMaterial3D.new()
	pmat.vertex_color_is_srgb = true
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.vertex_color_use_as_albedo = true
	pmat.albedo_color = Color(1.4, 1.4, 1.4, 1.0)
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA     # 半透明管线 = 在黑白之后画：黑白世界里唯一的颜色
	pt.material_override = pmat
	pt.amount = 70
	pt.lifetime = 2.6
	pt.position = Vector3(0, 0.2, 0)
	pt.visibility_aabb = AABB(Vector3(-9, -3, -9), Vector3(18, 9, 18))
	root.add_child(pt)
	root.set_meta("dfx", dfx)
	root.set_meta("radius", radius)
	# 张开的一瞬：一圈墨色冲击波从她脚下推到领域边
	ring(root.position, radius, Color("#1a1620"), 0.55, 2.2, 0.05)
	ring(root.position, radius * 0.96, Color("#fff4e8"), 0.65, 1.2, 0.05)
	return root


## 大招开始：脚下一道光柱冲上天(柔光 + 一圈圈往上飞的光环)，地上一圈冲击波，身上迸出一把光点
func ultimate_rise(at: Vector3, color: Color, height: float) -> void:
	var g := Vector3(at.x, 0.05, at.z)
	var sp: float = 1.0 / maxf(0.25, speed_scale)
	pillar(g, color.lerp(Color.WHITE, 0.35), 0.9)
	soft_flash(g + Vector3(0, height * 0.6 + 0.8, 0), color, 2.6, 0.45, 1.6)
	ring(g, 2.6, color, 0.6, 2.2, 0.05)
	ring(g, 1.6, Color.WHITE, 0.45, 1.4, 0.05)
	for i in range(4):
		var m := MeshInstance3D.new()
		m.mesh = _ring_mesh
		var mat: StandardMaterial3D = _emissive(color.lerp(Color.WHITE, 0.3), 2.6, 0.85).duplicate() as StandardMaterial3D
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		m.global_position = g
		m.scale = Vector3(0.9, 0.4, 0.9)
		var tw := m.create_tween().set_parallel(true)
		tw.tween_interval(0.08 * float(i) * sp)
		tw.chain().tween_property(m, "global_position:y", 3.2 + 0.4 * float(i), 0.7 * sp).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.parallel().tween_property(m, "scale", Vector3(0.3, 0.4, 0.3), 0.7 * sp)
		tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.7 * sp)
		tw.chain().tween_callback(m.queue_free)
	burst(g + Vector3(0, height * 0.6, 0), color.lerp(Color.WHITE, 0.4), 22, 3.4, 1.0, 2.2, 0.7)


## 留色的圆柱跟着她：feet = 她脚下，h = 留色的高度(身高 + 悬浮高度)
func magi_domain_keep(root: Node3D, feet: Vector3, r: float, h: float) -> void:
	if root == null or not is_instance_valid(root) or not root.has_meta("dfx"):
		return
	var dfx: DomainFX = root.get_meta("dfx")
	if is_instance_valid(dfx):
		dfx.set_keep(feet, r, h)


## 领域收掉。flash = 少女幻终的终结一击：里面黑白反相闪几下、二值化、往外扩，再褪色；否则直接淡出
func magi_domain_end(root: Node3D, flash: bool) -> void:
	if root == null or not is_instance_valid(root) or root.has_meta("ending"):
		return
	root.set_meta("ending", true)
	var sp: float = 1.0 / maxf(0.25, speed_scale)
	var dfx: DomainFX = root.get_meta("dfx")
	if is_instance_valid(dfx):
		dfx.close((0.9 if flash else 0.4) * sp, flash)
	var tw := root.create_tween()
	tw.tween_interval(0.9 * sp)
	tw.tween_callback(root.queue_free)


## 少女幻终的终结一击：中心一团白光炸开，红 / 蓝 / 白三道冲击环扩到范围边，彩色碎块四散；打中的每个人身上一道光柱 + 红蓝交叉的两刀
func magi_finale(at: Vector3, radius: float, hits: Array) -> void:
	var c0 := Vector3(at.x, 0.0, at.z)
	explosion(c0 + Vector3(0, 1.2, 0), radius * 0.6, Color("#efe0ff"), 1.4)
	ring(c0, radius, Color("#ff4a5e"), 0.55, 2.4, 0.1)
	ring(c0, radius * 0.85, Color("#4a8cff"), 0.65, 2.4, 0.1)
	ring(c0, radius * 1.2, Color("#ffffff"), 0.5, 1.4, 0.3)
	ring(c0, radius * 1.05, Color("#1a1620"), 0.7, 3.0, 0.2)
	for c: Color in [Color("#ff8fd0"), Color("#8fd8ff"), Color("#fff4c0")]:
		burst(c0 + Vector3(0, 1.2, 0), c, 26, 6.0, 1.4, 1.2, 1.0)
	burst(c0 + Vector3(0, 0.6, 0), Color("#14101a"), 30, 5.0, 1.6, 0.8, 0.9, false)       # 墨点四溅
	for h: Vector3 in hits:
		pillar(Vector3(h.x, 0.0, h.z), Color("#f2ddff"), 0.8)
		slash(h, Vector3(1.0, 0.45, 0.0), PAINT_COLORS["red"], 1.6)
		slash(h, Vector3(-1.0, 0.45, 0.0), PAINT_COLORS["blue"], 1.6)


## 少女幻终之后的阵亡：身上崩出一大把彩色方块往上飘散
func magi_death(at: Vector3) -> void:
	for c: Color in [Color("#ff8fd0"), Color("#8fd8ff"), Color("#d9c2ff"), Color("#fff4c0")]:
		burst(at, c, 10, 1.6, 1.1, 2.4, 1.1)
	ring(Vector3(at.x, 0.0, at.z), 1.0, Color("#d7b8ff"), 0.7, 1.4, 0.3)


# ---------------------------------------------------------------- 迅游节点：闪电跑者 / 飞身踢
const VOLT := Color("#b56cff")
const VOLT_HOT := Color("#ecd8ff")


## 一道折线闪电(从 a 到 b，中间几个拐点随机错开)，一闪而过
func lightning(a: Vector3, b: Vector3, color: Color, width: float = 0.05, life: float = 0.18, kinks: int = 4) -> void:
	var pts: Array[Vector3] = [a]
	var side: Vector3 = (b - a).cross(Vector3.UP).normalized()
	if side.length() < 0.1:
		side = Vector3.RIGHT
	for i in range(1, kinks):
		var k: float = float(i) / float(kinks)
		var off: float = randf_range(-1.0, 1.0) * a.distance_to(b) * 0.12
		pts.append(a.lerp(b, k) + side * off + Vector3(0, randf_range(-0.08, 0.08), 0))
	pts.append(b)
	for i in range(pts.size() - 1):
		streak(pts[i], pts[i + 1], color, width, life)


## 飞身踢命中：一圈紫电炸开 + 几道向外的闪电 + 冲击环；倍率越高越大
func volt_kick(at: Vector3, dir: Vector3, mult: float) -> void:
	var k: float = clampf(0.6 + 0.25 * mult, 0.6, 1.8)
	burst(at, VOLT, int(8 + 4 * k), 3.2 * k, 0.9, 0.7, 0.4)
	burst(at, VOLT_HOT, 5, 2.4 * k, 0.6, 0.9, 0.25)
	ring(Vector3(at.x, 0.03, at.z), 0.9 * k, VOLT, 0.35, 1.4, 0.2)
	for i in range(3):
		var d: Vector3 = (dir.normalized() + Vector3(randf_range(-0.7, 0.7), randf_range(-0.2, 0.5), randf_range(-0.7, 0.7))).normalized()
		lightning(at, at + d * (0.7 + 0.35 * k), VOLT_HOT if i == 0 else VOLT, 0.045, 0.16, 3)


## 卡车借力：脚下一蹬，迸出一圈电火花
func volt_spring(at: Vector3) -> void:
	burst(at + Vector3(0, 0.2, 0), VOLT, 10, 2.6, 0.7, 1.2, 0.35)
	ring(Vector3(at.x, 0.03, at.z), 0.7, VOLT_HOT, 0.3, 1.2, 0.2)


## 被击退：起点一团电光 + 一道拖出去的光痕
func volt_knock(from: Vector3, to: Vector3) -> void:
	streak(from, to, VOLT, 0.12, 0.3)
	burst(from, VOLT_HOT, 6, 2.0, 0.6, 0.6, 0.3)
	burst(Vector3(to.x, 0.1, to.z), Color("#8a8090"), 6, 1.2, 1.0, 0.5, 0.45, false)


# ---------------------------------------------------------------- 幻形节点：误导 / 眩晕 / 少女幻嘘
## 领域里转的"各种语言的无意义文本"(拉丁 / 希腊 / 西里尔 / 汉字 / 假名 / 谚文 / 阿拉伯 / 卢恩 / 符号)
const GLYPHS := ["ʘΞλ", "Ψϟ", "ЖЯФ", "ЩЭЮ", "語謎", "言書", "かなの", "カタ", "한글", "말씀", "ابت", "سلم", "ᚠᚢᚦ", "ᚨᚱᚲ", "∑∂∞", "§¶", "θσω", "дцъ", "幻形", "ᛟᛞ"]
const GLYPH_COLS := [Color("#f4f2ff"), Color("#d9d0ff"), Color("#c8c2d8"), Color("#ffffff"), Color("#b8a8ff")]


func _glyph_label(size: float = 1.0) -> Label3D:
	var l := Label3D.new()
	l.text = str(GLYPHS[randi() % GLYPHS.size()])
	l.modulate = GLYPH_COLS[randi() % GLYPH_COLS.size()]
	l.outline_modulate = Color(0.12, 0.08, 0.22, 0.8)
	l.outline_size = 8
	l.font_size = int(44.0 * size)
	l.pixel_size = 0.0055
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.shaded = false
	l.render_priority = 40
	return l


## 少女幻嘘的领域：画面变成信号干扰(DomainFX hush：去色冷紫、扫描线、一条条撕裂错位、红蓝分离)，
## 三圈各种语言的无意义文字绕着她转(每圈速度、方向不同)，她头顶一个大大的"嘘"一下一下地脉动；张开时从小撑到满
func glyph_domain(at: Vector3, radius: float) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	root.position = Vector3(at.x, 0.0, at.z)
	var sp: float = 1.0 / maxf(0.25, speed_scale)
	var dfx := DomainFX.make("hush", root.position, radius, Color("#b8a8ff"))
	add_child(dfx)
	dfx.open(0.45 * sp, 0.5)
	var labels: Array = []
	var rings: Array = []
	var holder := Node3D.new()
	root.add_child(holder)
	for ri in range(3):
		var rnode := Node3D.new()
		holder.add_child(rnode)
		rings.append(rnode)
		var rr: float = radius * [0.38, 0.64, 0.9][ri]
		var hy: float = [2.0, 1.25, 0.55][ri]
		var n: int = [10, 16, 24][ri]
		for k in range(n):
			var l: Label3D = _glyph_label(1.0 + 0.35 * randf())
			var ang: float = TAU * float(k) / float(n) + randf_range(-0.15, 0.15)
			l.position = Vector3(cos(ang) * rr, hy + randf_range(-0.2, 0.2), sin(ang) * rr)
			rnode.add_child(l)
			labels.append(l)
		var dirn: float = 1.0 if ri % 2 == 0 else -1.0
		var tw := rnode.create_tween().set_loops()
		tw.tween_property(rnode, "rotation:y", dirn * TAU, (7.0 + 3.0 * float(ri)) * sp).as_relative()
	# 字不停地换(看不懂的文字一直在变)
	var swap := root.create_tween().set_loops()
	swap.tween_interval(0.12 * sp)
	swap.tween_callback(func() -> void:
		if labels.is_empty():
			return
		var l2: Variant = labels[randi() % labels.size()]
		if is_instance_valid(l2) and not root.has_meta("ending"):
			(l2 as Label3D).text = str(GLYPHS[randi() % GLYPHS.size()]))
	# 头顶的大"嘘"
	var hush := Label3D.new()
	hush.text = "嘘"
	hush.modulate = Color("#f4f0ff")
	hush.outline_modulate = Color(0.25, 0.1, 0.45, 0.95)
	hush.outline_size = 18
	hush.font_size = 150
	hush.pixel_size = 0.0075
	hush.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hush.shaded = false
	hush.no_depth_test = true
	hush.render_priority = 45
	hush.position = Vector3(0, 2.9, 0)
	root.add_child(hush)
	var hp := hush.create_tween().set_loops()
	hp.tween_property(hush, "scale", Vector3.ONE * 1.12, 0.5 * sp).set_trans(Tween.TRANS_SINE)
	hp.tween_property(hush, "scale", Vector3.ONE * 0.94, 0.5 * sp).set_trans(Tween.TRANS_SINE)
	holder.scale = Vector3.ONE * 0.2
	holder.create_tween().tween_property(holder, "scale", Vector3.ONE, 0.45 * sp).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	root.set_meta("labels", labels)
	root.set_meta("dfx", dfx)
	root.set_meta("hush", hush)
	ring(root.position, radius, Color("#e6dcff"), 0.5, 1.8, 0.05)
	return root


## 领域收掉。into = 还在领域里的敌人的胸口：文字一个个灌进他们身体里，大"嘘"往外一冲、炸开；空 = 文字散掉淡出
func glyph_domain_end(root: Node3D, into: Array) -> void:
	if root == null or not is_instance_valid(root) or root.has_meta("ending"):
		return
	root.set_meta("ending", true)
	var sp: float = 1.0 / maxf(0.25, speed_scale)
	var dfx: DomainFX = root.get_meta("dfx")
	if is_instance_valid(dfx):
		dfx.close(0.5 * sp, false)
	var hush: Label3D = root.get_meta("hush")
	if is_instance_valid(hush):
		var th := hush.create_tween().set_parallel(true)
		th.tween_property(hush, "scale", Vector3.ONE * (3.0 if not into.is_empty() else 1.4), 0.35 * sp).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		th.tween_property(hush, "modulate:a", 0.0, 0.35 * sp)
		th.tween_property(hush, "outline_modulate:a", 0.0, 0.35 * sp)
	var labels: Array = root.get_meta("labels")
	var i := 0
	for l: Label3D in labels:
		if not is_instance_valid(l):
			continue
		var gp: Vector3 = l.global_position
		var parent: Node = l.get_parent()
		parent.remove_child(l)
		add_child(l)
		l.global_position = gp
		var tw := l.create_tween()
		if into.is_empty():
			tw.set_parallel(true)
			tw.tween_property(l, "position", l.position + Vector3(randf_range(-0.6, 0.6), randf_range(0.4, 1.2), randf_range(-0.6, 0.6)), 0.6 * sp)
			tw.tween_property(l, "modulate:a", 0.0, 0.6 * sp)
			tw.tween_property(l, "outline_modulate:a", 0.0, 0.6 * sp)
		else:
			var dest: Vector3 = into[i % into.size()]
			var delay: float = 0.012 * float(i) * sp
			tw.tween_interval(delay)
			tw.tween_property(l, "position", dest, 0.3 * sp).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			tw.parallel().tween_property(l, "scale", Vector3.ONE * 0.3, 0.3 * sp)
			tw.tween_property(l, "modulate:a", 0.0, 0.08 * sp)
		tw.tween_callback(l.queue_free)
		i += 1
	if not into.is_empty():
		for dest2: Vector3 in into:
			burst(dest2, Color("#e6dcff"), 10, 1.8, 0.8, 0.6, 0.4)
			ring(Vector3(dest2.x, 0.03, dest2.z), 0.7, Color("#e6dcff"), 0.4, 1.2, 0.3)
	var tw_end := root.create_tween()
	tw_end.tween_interval(1.3 * sp)
	tw_end.tween_callback(root.queue_free)


## 误导：从她身上飞出几个字落到对方头上
func mislead_cast(from: Vector3, to: Vector3) -> void:
	var sp: float = 1.0 / maxf(0.25, speed_scale)
	for k in range(3):
		var l: Label3D = _glyph_label(0.8)
		add_child(l)
		l.position = from + Vector3(randf_range(-0.2, 0.2), 0.2 + 0.15 * float(k), randf_range(-0.2, 0.2))
		var tw := l.create_tween()
		tw.tween_interval(0.05 * float(k) * sp)
		tw.tween_property(l, "position", to + Vector3(0, 0.55, 0), 0.35 * sp).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(l, "modulate:a", 0.0, 0.2 * sp)
		tw.tween_callback(l.queue_free)


## 头顶的误导标记：一个慢慢摇晃的紫色"?"
func misled_mark(parent: Node3D, offset: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = offset
	parent.add_child(root)
	var l := Label3D.new()
	l.text = "?"
	l.modulate = Color("#d6c2ff")
	l.outline_modulate = Color(0.15, 0.05, 0.3, 0.95)
	l.outline_size = 12
	l.font_size = 72
	l.pixel_size = 0.006
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.shaded = false
	l.no_depth_test = true
	l.render_priority = 50
	root.add_child(l)
	var tw := root.create_tween().set_loops()
	tw.tween_property(l, "position:y", 0.08, 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_property(l, "position:y", 0.0, 0.45).set_trans(Tween.TRANS_SINE)
	return root


## 头顶的眩晕标记：三颗黄色小星星绕着转
func stun_mark(parent: Node3D, offset: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = offset
	parent.add_child(root)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.07, 0.07, 0.07)
	for k in range(3):
		var mi := MeshInstance3D.new()
		mi.mesh = bm
		mi.material_override = _emissive(Color("#ffe27a"), 3.0)
		var a: float = TAU * float(k) / 3.0
		mi.position = Vector3(cos(a) * 0.22, 0.03 * float(k % 2), sin(a) * 0.22)
		mi.rotation = Vector3(0.7, 0.0, 0.7)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	var tw := root.create_tween().set_loops()
	tw.tween_property(root, "rotation:y", TAU, 0.9).from(0.0)
	return root


## 少女幻嘘之后的阵亡：身上散出一大把文字往上飘
func glyph_burst(at: Vector3) -> void:
	var sp: float = 1.0 / maxf(0.25, speed_scale)
	for k in range(12):
		var l: Label3D = _glyph_label(0.8 + 0.4 * randf())
		add_child(l)
		l.position = at + Vector3(randf_range(-0.25, 0.25), randf_range(-0.3, 0.3), randf_range(-0.25, 0.25))
		var tw := l.create_tween().set_parallel(true)
		tw.tween_property(l, "position", l.position + Vector3(randf_range(-0.9, 0.9), randf_range(0.8, 1.8), randf_range(-0.9, 0.9)), 1.1 * sp)
		tw.tween_property(l, "modulate:a", 0.0, 1.1 * sp).set_delay(0.3 * sp)
		tw.tween_property(l, "outline_modulate:a", 0.0, 1.1 * sp).set_delay(0.3 * sp)
		tw.chain().tween_callback(l.queue_free)
	ring(Vector3(at.x, 0.0, at.z), 1.0, Color("#e6dcff"), 0.7, 1.4, 0.3)


# ---------------------------------------------------------------- 幻灵节点：魂体 / 少女幻葬
const SOUL := Color("#c9a6ff")
const SOUL_HOT := Color("#f0e4ff")


## 魂体存在的召唤物出现 / 散掉：一团淡紫灵火
func spirit_puff(at: Vector3, big: bool = false) -> void:
	burst(at, SOUL, 10 if big else 6, 1.6, 0.9, 1.4, 0.45)
	burst(at, SOUL_HOT, 4, 1.0, 0.6, 1.8, 0.35)
	if big:
		ring(Vector3(at.x, 0.03, at.z), 0.6, SOUL, 0.35, 1.2, 0.3)


## 背刺：目标身后一道斜斩
func backstab(at: Vector3, dir: Vector3) -> void:
	slash(at, dir, Color("#d9b8ff"), 1.0)
	burst(at, SOUL_HOT, 5, 1.8, 0.6, 0.6, 0.3)


func _soul_node() -> Node3D:
	var n := Node3D.new()
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.07
	sm.height = 0.14
	sm.radial_segments = 8
	sm.rings = 4
	mi.mesh = sm
	mi.material_override = _emissive(SOUL_HOT, 3.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(mi)
	var pt := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 25.0
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.2
	pm.gravity = Vector3(0, 0.4, 0)
	pm.scale_min = 0.4
	pm.scale_max = 0.8
	pt.process_material = pm
	pt.draw_pass_1 = _box
	pt.material_override = _emissive(SOUL, 2.4, 0.85)
	pt.amount = 10
	pt.lifetime = 0.5
	pt.local_coords = false
	pt.visibility_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))
	n.add_child(pt)
	return n


## 少女幻葬的领域：画面变成冷紫蓝的冥界(DomainFX spirit：像隔着水一样慢慢扭动，暗处泛灵光)，地上一圈发光的魂火(着色器画)，
## 地面上一圈慢转的招魂纹(两圈环 + 一圈符点)，灵魂绕着她转(soul_domain_grow 随吟唱时间 / 阵亡数加)，地上不断往上飘起淡紫的灵火
func soul_domain(at: Vector3, radius: float) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	root.position = Vector3(at.x, 0.0, at.z)
	var sp: float = 1.0 / maxf(0.25, speed_scale)
	var dfx := DomainFX.make("spirit", root.position, radius, Color("#8f7cff"))
	add_child(dfx)
	dfx.open(0.5 * sp, 0.55)
	# 招魂纹：内外两圈细环 + 12 个菱形符点，慢慢转
	var sigil := Node3D.new()
	sigil.position.y = 0.04
	root.add_child(sigil)
	for rk: float in [0.42, 0.6]:
		var rm := MeshInstance3D.new()
		rm.mesh = _ring_mesh
		rm.material_override = _emissive(SOUL, 2.2, 0.8)
		rm.scale = Vector3(radius * rk, 0.25, radius * rk)
		rm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sigil.add_child(rm)
	for k in range(12):
		var a: float = TAU * float(k) / 12.0
		var bm := BoxMesh.new()
		bm.size = Vector3(0.16, 0.01, 0.16)
		var dm := MeshInstance3D.new()
		dm.mesh = bm
		dm.material_override = _emissive(SOUL_HOT, 2.6, 0.9)
		dm.position = Vector3(cos(a), 0.0, sin(a)) * radius * 0.51
		dm.rotation.y = a + PI * 0.25
		dm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sigil.add_child(dm)
	var st := sigil.create_tween().set_loops()
	st.tween_property(sigil, "rotation:y", -TAU, 14.0 * sp).as_relative()
	# 往上飘的灵火
	var wisps := SoftFX.particles(40, 2.4, SoftFX.ramp([Color(0.75, 0.62, 1.0, 0.0), Color(0.75, 0.62, 1.0, 0.7), Color(0.55, 0.45, 1.0, 0.0)], [0.0, 0.3, 1.0]), 0.22)
	var wpm: ParticleProcessMaterial = wisps.process_material
	wpm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	wpm.emission_ring_axis = Vector3.UP
	wpm.emission_ring_radius = radius * 0.95
	wpm.emission_ring_inner_radius = 0.4
	wpm.emission_ring_height = 0.05
	wpm.direction = Vector3(0, 1, 0)
	wpm.spread = 12.0
	wpm.initial_velocity_min = 0.4
	wpm.initial_velocity_max = 0.9
	wpm.gravity = Vector3(0, 0.2, 0)
	wisps.visibility_aabb = AABB(Vector3(-9, -1, -9), Vector3(18, 8, 18))
	wisps.emitting = true
	root.add_child(wisps)
	var orbit := Node3D.new()
	root.add_child(orbit)
	var tw := orbit.create_tween().set_loops()
	tw.tween_property(orbit, "rotation:y", TAU, 6.0 * sp).as_relative()
	root.set_meta("orbit", orbit)
	root.set_meta("souls", [])
	root.set_meta("radius", radius)
	root.set_meta("dfx", dfx)
	root.set_meta("sigil", sigil)
	root.set_meta("wisps", wisps)
	sigil.scale = Vector3.ONE * 0.2
	sigil.create_tween().tween_property(sigil, "scale", Vector3.ONE, 0.5 * sp).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	ring(root.position, radius, SOUL, 0.5, 1.8, 0.05)
	soul_domain_grow(root, 6)
	return root


## 领域里的灵魂补到 n 个(新的从中心飘出去，绕着转、上下浮)
func soul_domain_grow(root: Node3D, n: int) -> void:
	if root == null or not is_instance_valid(root) or root.has_meta("ending"):
		return
	var souls: Array = root.get_meta("souls")
	var orbit: Node3D = root.get_meta("orbit")
	var rad: float = float(root.get_meta("radius"))
	while souls.size() < mini(n, 40):
		var s := _soul_node()
		orbit.add_child(s)
		var k: int = souls.size()
		var ang: float = float(k) * 2.39996
		var rr: float = rad * (0.35 + 0.55 * fmod(float(k) * 0.618, 1.0))
		var hy: float = 0.4 + 1.2 * fmod(float(k) * 0.381, 1.0)
		s.position = Vector3(0, 0.8, 0)
		s.create_tween().tween_property(s, "position", Vector3(cos(ang) * rr, hy, sin(ang) * rr), 0.5)
		var bob := s.create_tween().set_loops()
		bob.tween_property(s, "position:y", hy + 0.15, 0.7 + 0.1 * float(k % 4)).set_trans(Tween.TRANS_SINE).set_delay(0.5)
		bob.tween_property(s, "position:y", hy - 0.1, 0.7 + 0.1 * float(k % 4)).set_trans(Tween.TRANS_SINE)
		souls.append(s)


## 领域收掉：灵魂一个个飞散到 spots(战场上变成幽灵的地方)；没有落点的往上飘散
func soul_domain_end(root: Node3D, spots: Array) -> void:
	if root == null or not is_instance_valid(root) or root.has_meta("ending"):
		return
	root.set_meta("ending", true)
	var sp0: float = 1.0 / maxf(0.25, speed_scale)
	var dfx: DomainFX = root.get_meta("dfx")
	if is_instance_valid(dfx):
		dfx.close(0.6 * sp0, false)
	var sigil: Node3D = root.get_meta("sigil")
	var wisps: GPUParticles3D = root.get_meta("wisps")
	if is_instance_valid(wisps):
		wisps.emitting = false
	if is_instance_valid(sigil):
		sigil.create_tween().tween_property(sigil, "scale", Vector3.ONE * 1.3, 0.35 * sp0)
		var tws := sigil.create_tween()
		tws.tween_interval(0.35 * sp0)
		tws.tween_callback(sigil.queue_free)
	var souls: Array = root.get_meta("souls")
	var i := 0
	for s: Node3D in souls:
		if not is_instance_valid(s):
			continue
		var gp: Vector3 = s.global_position
		s.get_parent().remove_child(s)
		add_child(s)
		s.global_position = gp
		var dest: Vector3 = gp + Vector3(randf_range(-1.5, 1.5), 2.5, randf_range(-1.5, 1.5))
		if i < spots.size():
			var sp: Vector2 = spots[i]
			dest = Vector3(sp.x, 0.6, sp.y)
		var tw := s.create_tween()
		tw.tween_interval(0.03 * float(i))
		tw.tween_property(s, "position", dest, 0.45).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func() -> void: spirit_puff(dest, true))
		tw.tween_callback(s.queue_free)
		i += 1
	# 落点比灵魂多：多出来的直接冒灵火
	while i < spots.size():
		var sp2: Vector2 = spots[i]
		spirit_puff(Vector3(sp2.x, 0.6, sp2.y), true)
		i += 1
	var tw_end := root.create_tween()
	tw_end.tween_interval(1.2 * sp0)
	tw_end.tween_callback(root.queue_free)


# ---------------------------------------------------------------- 真望节点：金矢 / 黄金的指引 / 少女真心
const GOLD := Color("#ffd75a")
const GOLD_HOT := Color("#fff4c4")


## 金矢命中队友：金色的光点往上散 + 一圈金环
func golden_hit(at: Vector3) -> void:
	burst(at, GOLD, 10, 1.6, 0.8, 1.6, 0.5)
	burst(at, GOLD_HOT, 5, 1.0, 0.6, 2.0, 0.4)
	ring(Vector3(at.x, 0.03, at.z), 0.7, GOLD, 0.4, 1.2, 0.3)


# ---------------------------------------------------------------- 红之章的余烬(嫉妒 / 贪婪 / 忧郁 / 傲慢 / 龙)
## 每一种余烬烧的火颜色不一样(和模型的身份色一致)：嫉妒 = 毒绿，贪婪 = 紫，龙 = 深红
const ENVY_CORE := Color("#f0ffbc")
const ENVY_GLOW := Color("#4ec41c")
const DRAGON_FIRE := Color("#e4182a")
const DRAGON_HOT := Color("#ff8a2a")
const GREED_VIOLET := Color("#b04cff")
const GREED_PALE := Color("#f0d8ff")
const WITHER := Color("#8a1a24")
const BEAM_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 core : source_color = vec4(0.94, 1.0, 0.74, 1.0);
uniform vec4 glow : source_color = vec4(0.3, 0.77, 0.11, 1.0);
uniform float len = 1.0;
uniform float pulse = 1.0;
uniform float fade = 1.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
void fragment() {
	float x = UV.x * 2.0 - 1.0;
	float along = 1.0 - UV.y;
	// 能量顺着射线往目标流：两层滚动的噪声扭动光芯、明暗
	float n = noise(vec2(along * len * 6.0 - TIME * 16.0, UV.x * 3.0));
	float n2 = noise(vec2(along * len * 13.0 - TIME * 26.0, UV.x * 6.0 + 3.0));
	float xc = x + (n - 0.5) * 0.35;
	float c = exp(-pow(xc * 5.0, 2.0));
	float g = exp(-pow(x * 1.7, 2.0)) * (0.55 + 0.6 * n2);
	float ends = smoothstep(0.0, 0.05, along) * smoothstep(1.0, 0.97, along);
	ALBEDO = (glow.rgb * g * 1.7 + core.rgb * c * 2.6) * (0.75 + 0.35 * pulse);
	ALPHA = clamp((g * 0.8 + c) * ends * fade, 0.0, 1.0);
}
"""
var _beam_shader: Shader = null


## 嫉妒的余烬的射线：一条面向镜头的光带(着色器：毒绿的光晕 + 扭动的亮芯，能量往目标流)，眼睛和命中点各一团柔光；
## 每帧用 beam_set 摆到眼睛 → 目标之间
func envy_beam() -> Node3D:
	var root := Node3D.new()
	if _beam_shader == null:
		_beam_shader = Shader.new()
		_beam_shader.code = BEAM_SHADER
	var bm := MeshInstance3D.new()
	bm.name = "Beam"
	bm.mesh = QuadMesh.new()
	var mat := ShaderMaterial.new()
	mat.shader = _beam_shader
	mat.set_shader_parameter("core", ENVY_CORE)
	mat.set_shader_parameter("glow", ENVY_GLOW)
	mat.render_priority = 4
	bm.material_override = mat
	bm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bm.top_level = true
	root.add_child(bm)
	for nm: String in ["Src", "Hit"]:
		var f := MeshInstance3D.new()
		f.name = nm
		f.mesh = SoftFX.quad(0.45 if nm == "Src" else 0.5)
		f.material_override = SoftFX.sprite_mat(ENVY_GLOW.lerp(ENVY_CORE, 0.35), 1.6)
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		f.top_level = true
		root.add_child(f)
	add_child(root)
	return root


## 把射线摆到 from → to；pulse = 0..1(粗细的呼吸)。光带的宽度方向 = 射线方向 × 视线方向(永远侧对镜头)
func beam_set(root: Node3D, from: Vector3, to: Vector3, pulse: float) -> void:
	var d: Vector3 = to - from
	var len: float = d.length()
	var bm: MeshInstance3D = root.get_node_or_null("Beam") as MeshInstance3D
	if len < 0.05 or bm == null:
		root.visible = false
		return
	root.visible = true
	var mid: Vector3 = (from + to) * 0.5
	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() != null else null
	var view: Vector3 = (cam.global_position - mid) if cam != null else Vector3(0, 1, 1)
	var side: Vector3 = d.cross(view)
	if side.length() < 1e-4:
		side = d.cross(Vector3.UP)
	side = side.normalized()
	var w: float = 0.32 + 0.12 * pulse
	var nrm: Vector3 = side.cross(d.normalized())
	bm.global_transform = Transform3D(Basis(side * w, d, nrm), mid)
	(bm.material_override as ShaderMaterial).set_shader_parameter("len", len)
	(bm.material_override as ShaderMaterial).set_shader_parameter("pulse", pulse)
	var src: Node3D = root.get_node("Src")
	var hit: Node3D = root.get_node("Hit")
	src.global_position = from
	hit.global_position = to
	var k: float = 0.85 + 0.3 * pulse
	src.scale = Vector3.ONE * k
	hit.scale = Vector3.ONE * (0.8 + 0.45 * pulse)


## 射线打中的那一点：一小撮火星
func beam_hit(at: Vector3) -> void:
	burst(at, ENVY_GLOW, 4, 1.6, 0.45, 0.8, 0.25)
	burst(at, ENVY_CORE, 2, 1.0, 0.4, 1.0, 0.2)


## 柔光一闪：一片面向镜头的光，很快张开再淡掉(火弹 / 爆裂的核心)
func soft_flash(at: Vector3, color: Color, size: float = 1.0, life: float = 0.22, energy: float = 1.8) -> void:
	var m := MeshInstance3D.new()
	m.mesh = SoftFX.quad(1.0)
	var mat: StandardMaterial3D = SoftFX.sprite_mat(color, energy)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	m.global_position = at
	m.scale = Vector3.ONE * size * 0.35
	var s: float = maxf(0.2, speed_scale)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(m, "scale", Vector3.ONE * size, life * 0.35 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mat, "albedo_color:a", 0.0, life / s).set_ease(Tween.EASE_IN).set_delay(life * 0.15 / s)
	tw.chain().tween_callback(m.queue_free)


## 一团往外翻滚的柔光火焰(一次性)：up = 往上飘的力度
func fire_puff(at: Vector3, color: Color, amount: int = 10, size: float = 0.45, speed: float = 1.4, life: float = 0.55, up: float = 1.0, additive: bool = true) -> void:
	var p := SoftFX.particles(amount, life, SoftFX.fire_ramp(color, 1.5) if additive else SoftFX.ramp([Color(color.r, color.g, color.b, 0.0),
		Color(color.r, color.g, color.b, 0.6), Color(color.r * 0.6, color.g * 0.6, color.b * 0.6, 0.0)], [0.0, 0.2, 1.0]), size, additive)
	var pm: ParticleProcessMaterial = p.process_material
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0 if up < 0.3 else 70.0
	pm.initial_velocity_min = speed * 0.4
	pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, 1.6 * up, 0)
	pm.damping_min = 1.5
	pm.damping_max = 3.0
	p.one_shot = true
	p.explosiveness = 0.9
	p.emitting = true
	add_child(p)
	p.global_position = at
	p.speed_scale = _pslow()
	get_tree().create_timer((life + 0.4) / _pslow()).timeout.connect(p.queue_free)


## 地上留一块焦痕(中间焦黑、外圈一道发光的余烬边)，慢慢淡掉
func scorch(at: Vector3, radius: float, color: Color, life: float = 1.6) -> void:
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(radius * 2.0, radius * 2.0)
	m.mesh = pm
	var mat: ShaderMaterial = SoftFX.scorch_mat(color)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	m.global_position = Vector3(at.x, 0.04, at.z)
	m.rotation.y = randf() * TAU
	var s: float = maxf(0.2, speed_scale)
	var tw: Tween = create_tween()
	tw.tween_method(func(x: float) -> void: mat.set_shader_parameter("glow", x), 1.6, 0.0, life * 0.5 / s)
	tw.tween_method(func(x: float) -> void: mat.set_shader_parameter("fade", x), 1.0, 0.0, life * 0.5 / s)
	tw.tween_callback(m.queue_free)


## 余烬的火弹落地：一闪 + 翻滚的火团 + 迸飞的熔岩碎块 + 地上一块焦痕(颜色 = 那一种火)
func ember_impact(at: Vector3, color: Color, size: float = 1.0) -> void:
	soft_flash(at, color.lerp(Color(1, 0.97, 0.88), 0.2), 0.7 * size, 0.2, 1.3)
	fire_puff(at, color, int(8 + 4 * size), 0.42 * size, 1.5 * size, 0.5)
	burst(at, color.lerp(Color(1, 0.95, 0.8), 0.3), 5, 2.4, 0.55, 1.4, 0.45)
	scorch(at, 0.55 * size, color, 1.4)


## 贪婪的余烬吞掉燃烧：紫色的火团从目标身上被一缕缕吸走，飞进书里
func greed_swallow(from: Vector3, to: Vector3, count: int) -> void:
	soft_flash(from, GREED_VIOLET, 0.8, 0.3, 1.4)
	burst(from, GREED_VIOLET, 3 + count, 1.6, 0.5, 0.8, 0.4)
	var s: float = maxf(0.2, speed_scale)
	for i in range(mini(7, 3 + count)):
		var m := MeshInstance3D.new()
		m.mesh = SoftFX.quad(0.3 if i % 2 == 0 else 0.2)
		m.material_override = SoftFX.sprite_mat(GREED_VIOLET if i % 2 == 0 else GREED_PALE, 1.8)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		var off := Vector3(randf_range(-0.3, 0.3), randf_range(0.0, 0.4), randf_range(-0.3, 0.3))
		var a: Vector3 = from + off
		var ctrl: Vector3 = (a + to) * 0.5 + Vector3(randf_range(-0.6, 0.6), 0.9 + randf() * 0.5, randf_range(-0.6, 0.6))
		m.global_position = a
		var tw: Tween = create_tween()
		tw.tween_interval(float(i) * 0.05 / s)
		tw.tween_method(func(k: float) -> void:
			if is_instance_valid(m):
				m.global_position = a.lerp(ctrl, k).lerp(ctrl.lerp(to, k), k), 0.0, 1.0, 0.42 / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(m.queue_free)
	soft_flash(to, GREED_PALE, 0.6, 0.35, 1.4)


## 金焰：紫色的爆炸里崩出金色的碎光，地上一块紫色的焦痕
func greed_burst(center: Vector3, radius: float) -> void:
	soft_flash(center, GREED_VIOLET.lerp(GREED_PALE, 0.3), radius * 1.8, 0.3, 1.8)
	fire_puff(center, GREED_VIOLET, 16, 0.5, 2.2 * clampf(radius, 0.8, 1.6), 0.6, 0.6)
	burst(center, GOLD, 14, 3.0, 0.7, 1.2, 0.55)
	ring(Vector3(center.x, 0.03, center.z), radius, GOLD, 0.5, 0.9, 0.2)
	scorch(center, radius * 0.8, GREED_VIOLET, 1.8)


## 龙的余烬点燃脚下：从地里喷起一根火柱(柔光火团往上冲) + 炸开的火星 + 地上一块焦痕、一圈火环
func ember_ignite(at: Vector3) -> void:
	var g := Vector3(at.x, 0.05, at.z)
	soft_flash(g + Vector3(0, 0.3, 0), DRAGON_HOT, 1.6, 0.3, 2.0)
	var p := SoftFX.particles(26, 0.75, SoftFX.fire_ramp(DRAGON_FIRE, 1.6), 0.5)
	var pm: ParticleProcessMaterial = p.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.25
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 10.0
	pm.initial_velocity_min = 2.5
	pm.initial_velocity_max = 4.5
	pm.gravity = Vector3(0, -2.0, 0)
	pm.damping_min = 1.0
	pm.damping_max = 2.0
	p.one_shot = true
	p.explosiveness = 0.75
	p.emitting = true
	add_child(p)
	p.global_position = g
	p.speed_scale = _pslow()
	get_tree().create_timer(1.3 / _pslow()).timeout.connect(p.queue_free)
	burst(g + Vector3(0, 0.3, 0), DRAGON_HOT, 10, 3.2, 0.6, 1.8, 0.5)
	burst(g + Vector3(0, 0.2, 0), Color("#2a1e1c"), 6, 1.6, 0.9, 1.4, 0.7, false)
	ring(Vector3(at.x, 0.03, at.z), 0.8, DRAGON_FIRE, 0.45, 0.9, 0.2)
	scorch(g, 0.7, DRAGON_FIRE, 1.6)


## 余烬蔓延 / 余烬不熄时又烧到人：地块上蹿起一小团火
func ember_flare(at: Vector3) -> void:
	fire_puff(Vector3(at.x, 0.15, at.z), DRAGON_FIRE, 7, 0.4, 1.2, 0.5, 1.4)


## 生命上限被烧掉：暗红的烟往下沉 + 几片灰烬
func wither_ash(at: Vector3) -> void:
	fire_puff(at, Color("#3a0c12"), 6, 0.45, 0.6, 0.8, -0.4, false)
	burst(at, WITHER, 4, 1.0, 0.6, -0.4, 0.6, false)


## 余烬的溅射(暴食的赤油、其它余烬的范围伤害)：熔岩炸开——一闪、翻滚的火团、往外抛的熔岩滴(带重力的发光块)、一圈贴地的火浪、焦痕
func lava_splash(center: Vector3, radius: float, color: Color) -> void:
	# 叠加混合的光在暗地面上很容易烧成一片白：爆心的光小而偏红，主体靠往外抛的熔岩滴、贴地的火浪和焦痕
	var g := Vector3(center.x, 0.04, center.z)
	var r: float = clampf(radius, 0.6, 2.4)
	var deep: Color = color.lerp(Color("#d8300a"), 0.45)
	soft_flash(center, deep, minf(1.6, r * 0.7), 0.22, 1.0)
	fire_puff(center, deep, int(6 + 3 * r), 0.32, 1.2 + 0.6 * r, 0.55, 0.6)
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 70.0
	pm.initial_velocity_min = 1.8 + 0.8 * r
	pm.initial_velocity_max = 2.8 + 1.2 * r
	pm.gravity = Vector3(0, -12.0, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.3
	p.process_material = pm
	p.draw_pass_1 = _box
	p.material_override = _emissive(color, 2.2)
	p.amount = int(10 + 4 * r)
	p.lifetime = 0.7
	p.one_shot = true
	p.explosiveness = 0.95
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-4, -2, -4), Vector3(8, 6, 8))
	add_child(p)
	p.global_position = center
	p.emitting = true
	p.speed_scale = _pslow()
	get_tree().create_timer(1.2 / _pslow()).timeout.connect(p.queue_free)
	ring(g, r, deep, 0.45, 0.6, 0.25)
	scorch(g, r * 0.7, color, 1.8)


## 忧郁之潮(忧郁的余烬，每秒一次)：从水母脚下往外推的两道柔和的蓝紫涟漪 + 几滴往下落的"泪"
func melancholy_tide(center: Vector3, radius: float, color: Color, tear: Color) -> void:
	var g := Vector3(center.x, 0.05, center.z)
	ring(g, radius, color, 0.9, 0.55, 0.25)
	var s: float = maxf(0.2, speed_scale)
	get_tree().create_timer(0.18 / s).timeout.connect(func() -> void: ring(g, radius * 0.75, tear, 0.8, 0.4, 0.2))
	for i in range(3):
		var m := MeshInstance3D.new()
		m.mesh = SoftFX.quad(0.16)
		m.material_override = SoftFX.sprite_mat(tear, 1.8)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		var a := Vector3(randf_range(-0.45, 0.45), 1.1 + randf() * 0.3, randf_range(-0.45, 0.45))
		m.global_position = center + a
		var tw: Tween = create_tween()
		tw.tween_interval(float(i) * 0.12 / s)
		tw.tween_property(m, "global_position:y", 0.05, 0.45 / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func() -> void:
			ring(Vector3(m.global_position.x, 0.04, m.global_position.z), 0.3, tear, 0.35, 0.4, 0.2)
			m.queue_free())


## 余烬从熔岩里爬出来(傲慢的余烬召唤小怪 / 余烬现身)：地上一圈熔岩翻涌、一道火柱(那一种火的颜色) + 金色的敕令环
func ember_summon(at: Vector3, color: Color, size: float = 1.0) -> void:
	var g := Vector3(at.x, 0.05, at.z)
	scorch(g, 0.9 * size, color, 2.2 * size)
	soft_flash(g + Vector3(0, 0.5 * size, 0), color, 1.6 * size, 0.4, 1.6)
	var p := SoftFX.particles(int(22 * size), 0.8 * sqrt(size), SoftFX.fire_ramp(color, 1.5), 0.45 * size)
	var pm: ParticleProcessMaterial = p.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = 0.55 * size
	pm.emission_ring_inner_radius = 0.2 * size
	pm.emission_ring_height = 0.05
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 8.0
	pm.initial_velocity_min = 1.6 * sqrt(size)
	pm.initial_velocity_max = 3.0 * sqrt(size)
	pm.gravity = Vector3(0, -1.0, 0)
	p.one_shot = true
	p.explosiveness = 0.7
	p.emitting = true
	add_child(p)
	p.global_position = g
	p.speed_scale = _pslow()
	get_tree().create_timer(1.4 / _pslow()).timeout.connect(p.queue_free)
	burst(g + Vector3(0, 0.3, 0), color, int(10 * size), 2.6 * sqrt(size), 0.6, 1.6, 0.5)
	ring(g, 1.1 * size, GOLD if size <= 1.0 else color, 0.6, 0.6, 0.2)


# ---------------------------------------------------------------- 心音节点：演奏的音符、寒气、冻结的冰块、再生
const NOTE_ROWS := ["...XX", "...XX", "...X.", "...X.", ".XXX.", "XXXX.", "XXX.."]
const PERFORM_COLORS := {"might": Color("#ffd75a"), "burn": Color("#ff6a2a"), "chill": Color("#8fd8ff"), "regen": Color("#7dffa0"),
	"repel": Color("#ffb0e0"), "wound": Color("#c08cff"), "shred": Color("#ff8a8a")}
const ICE := Color("#bfe9ff")


func note_mesh() -> ArrayMesh:
	return _voxel_icon("note", NOTE_ROWS, 0.026)


## 演奏开始：一串音符从琴上飘向演奏对象(弧线)，到了以后在它身上散开
func music_notes(from: Vector3, to: Vector3, color: Color) -> void:
	var s: float = maxf(0.2, speed_scale)
	for i in range(4):
		var m := MeshInstance3D.new()
		m.mesh = note_mesh()
		m.material_override = _icon_mat(color, 2.6)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.scale = Vector3.ONE * (1.6 + 0.3 * float(i % 2))
		add_child(m)
		m.global_position = from
		var mid: Vector3 = (from + to) * 0.5 + Vector3(0, 0.9 + 0.25 * float(i), 0) + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
		var tw: Tween = create_tween()
		tw.tween_interval(float(i) * 0.09 / s)
		tw.tween_method(_note_arc.bind(m, from, mid, to), 0.0, 1.0, 0.5 / s)
		tw.tween_callback(m.queue_free)
	float_icons(to + Vector3(0, 0.3, 0), note_mesh(), color, 5, 0.3, 0.9, 1.4)


func _note_arc(k: float, m: Node3D, from: Vector3, mid: Vector3, to: Vector3) -> void:
	if is_instance_valid(m):
		m.global_position = from.lerp(mid, k).lerp(mid.lerp(to, k), k)


## ---------------------------------------------------------------- 心音节点：演奏的连线
## 演奏期间一直挂着：从演奏者胸前(琴 / 嘴边)到演奏对象之间一条五线谱一样的光带(三条细线，沿着一条往上拱的弧，微微起伏)，
## 音符顺着光带一个接一个飘过去；演奏对象脚下一圈慢转的音符环、头顶一个一直浮着的大音符(这一段的颜色)。
## BattleView 每帧 perform_link_set 摆位置，结束 / 被打断时 perform_link_end
const STAFF_LINES := 3


func perform_link(color: Color) -> Node3D:
	var root := Node3D.new()
	var im := ImmediateMesh.new()
	var lines := MeshInstance3D.new()
	lines.name = "Lines"
	lines.mesh = im
	lines.top_level = true
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true
	mat.render_priority = 6
	lines.material_override = mat
	lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(lines)
	# 顺着光带飘的音符(8 个，按相位错开)
	var notes := Node3D.new()
	notes.name = "Notes"
	notes.top_level = true
	root.add_child(notes)
	for i in range(8):
		var m := MeshInstance3D.new()
		m.mesh = note_mesh()
		m.material_override = _icon_mat(color, 2.6)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.scale = Vector3.ONE * (1.5 if i % 3 != 0 else 2.0)
		notes.add_child(m)
	# 演奏对象：脚下一圈音符环 + 头顶一个大音符
	var ring_n := Node3D.new()
	ring_n.name = "Ring"
	ring_n.top_level = true
	root.add_child(ring_n)
	var tm := TorusMesh.new()
	tm.inner_radius = 0.94
	tm.outer_radius = 1.0
	tm.rings = 48
	tm.ring_segments = 4
	var rm := MeshInstance3D.new()
	rm.mesh = tm
	rm.scale = Vector3(1.0, 0.05, 1.0)
	var rmat: StandardMaterial3D = _emissive(color, 1.8, 0.75).duplicate() as StandardMaterial3D
	rm.material_override = rmat
	rm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring_n.add_child(rm)
	for i in range(6):
		var a: float = TAU * float(i) / 6.0
		var nm := MeshInstance3D.new()
		nm.mesh = note_mesh()
		nm.material_override = _icon_mat(color, 2.2)
		nm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		nm.position = Vector3(cos(a), 0.12, sin(a))
		nm.scale = Vector3.ONE * 1.1
		ring_n.add_child(nm)
	var big := MeshInstance3D.new()
	big.name = "Big"
	big.mesh = note_mesh()
	big.material_override = _icon_mat(color, 3.0)
	big.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	big.top_level = true
	big.scale = Vector3.ONE * 3.2
	root.add_child(big)
	root.set_meta("color", color)
	root.set_meta("t", 0.0)
	add_child(root)
	return root


## 每帧摆位置：from = 演奏者胸前，to = 演奏对象胸口，ground = 演奏对象脚下(半径 r)，head = 演奏对象头顶；dt = 这一帧的(战斗)时间
func perform_link_set(root: Node3D, from: Vector3, to: Vector3, ground: Vector3, r: float, head: Vector3, dt: float) -> void:
	var t: float = float(root.get_meta("t")) + dt
	root.set_meta("t", t)
	var col: Color = root.get_meta("color")
	var fade: float = clampf(t / 0.3, 0.0, 1.0)
	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() != null else null
	var d: Vector3 = to - from
	var dist: float = d.length()
	var lift: float = clampf(dist * 0.22, 0.35, 1.4)
	var view_dir: Vector3 = (cam.global_position - (from + to) * 0.5).normalized() if cam != null else Vector3(0, 1, 1).normalized()
	var side: Vector3 = d.cross(view_dir)
	side = side.normalized() if side.length() > 1e-4 else Vector3.RIGHT
	# 五线谱：三条线，沿弧走，线距 6 cm，带一点波动(像旋律)
	var im: ImmediateMesh = (root.get_node("Lines") as MeshInstance3D).mesh as ImmediateMesh
	im.clear_surfaces()
	if dist > 0.2:
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		var n := 28
		for li in range(STAFF_LINES):
			var off: float = (float(li) - 1.0) * 0.08
			var prev_a := Vector3.ZERO
			var prev_b := Vector3.ZERO
			var prev_c := Color()
			for k in range(n + 1):
				var u: float = float(k) / float(n)
				var wave: float = 0.05 * sin(u * 9.0 - t * 5.0 + float(li) * 0.6) * sin(u * PI)
				var p: Vector3 = _perf_arc(from, to, lift, u) + side * (off + wave) + Vector3(0, wave * 0.5, 0)
				var w: float = 0.02 if li != 1 else 0.028
				var a: Vector3 = p + Vector3(0, w, 0)
				var bb: Vector3 = p - Vector3(0, w, 0)
				var flow: float = 0.55 + 0.45 * sin(u * 14.0 - t * 7.0)
				var c := Color(col.r * 1.6, col.g * 1.6, col.b * 1.6, (0.45 + 0.5 * flow) * minf(1.0, sin(u * PI) * 2.5) * fade)
				if k > 0:
					for v: Array in [[prev_a, prev_c], [prev_b, prev_c], [a, c], [prev_b, prev_c], [bb, c], [a, c]]:
						im.surface_set_color(v[1])
						im.surface_add_vertex(v[0])
				prev_a = a
				prev_b = bb
				prev_c = c
		im.surface_end()
	# 音符顺着谱线飘过去
	var notes: Node3D = root.get_node("Notes")
	for i in range(notes.get_child_count()):
		var m: Node3D = notes.get_child(i)
		var u2: float = fposmod(t * 0.55 + float(i) / float(notes.get_child_count()), 1.0)
		var line_off: float = (float(i % 3) - 1.0) * 0.08
		m.global_position = _perf_arc(from, to, lift, u2) + side * line_off + Vector3(0, 0.05 + 0.04 * sin(t * 6.0 + float(i)), 0)
		m.visible = dist > 0.2
		m.scale = Vector3.ONE * (2.0 if i % 3 != 0 else 2.6) * minf(1.0, sin(u2 * PI) * 2.0) * fade
	# 对象身上：脚下音符环慢转、头顶大音符上下浮
	var ring_n: Node3D = root.get_node("Ring")
	ring_n.global_position = ground + Vector3(0, 0.06, 0)
	ring_n.scale = Vector3(r, 1.0, r) * (0.7 + 0.3 * fade)
	ring_n.rotation.y = t * 0.8
	var big: Node3D = root.get_node("Big")
	big.global_position = head + Vector3(0, 0.12 * sin(t * 3.0), 0)
	big.scale = Vector3.ONE * 3.0 * fade * (1.0 + 0.08 * sin(t * 6.0))


static func _perf_arc(from: Vector3, to: Vector3, lift: float, u: float) -> Vector3:
	return from.lerp(to, u) + Vector3(0, lift * 4.0 * u * (1.0 - u), 0)


## 演奏结束：连线和音符一起淡掉；complete = 完整演完(对象身上一圈音符炸开)
func perform_link_end(root: Node3D, at: Vector3, complete: bool) -> void:
	if not is_instance_valid(root):
		return
	var col: Color = root.get_meta("color")
	if complete:
		float_icons(at + Vector3(0, 0.3, 0), note_mesh(), col, 6, 0.45, 0.8, 1.3)
	var tw: Tween = create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.01)
	tw.tween_callback(root.queue_free)


## 冻结：一块半透明的淡蓝冰块罩住单位(冻结结束时拿掉)
func ice_block(parent: Node3D, radius: float, height: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(radius * 2.4, height * 1.08, radius * 2.4)
	m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(ICE.r, ICE.g, ICE.b, 0.42)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = ICE
	mat.emission_energy_multiplier = 0.6
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position = Vector3(0, height * 0.54, 0)
	m.rotation.y = 0.35
	parent.add_child(m)
	m.scale = Vector3.ONE * 0.3
	create_tween().tween_property(m, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return m


## 冰块碎掉
func ice_shatter(at: Vector3) -> void:
	burst(at, ICE, 16, 2.6, 0.9, 1.0, 0.5)
	burst(at, Color.WHITE, 6, 1.8, 0.6, 1.2, 0.35)


## 浸染：身上缠一缕青烟；被打到时青烟炸开(一半飞向攻击者)
const INFUSE := Color("#5fd6c8")


func infusion_puff(at: Vector3) -> void:
	burst(at, INFUSE, 6, 0.8, 0.9, 0.6, 0.6, false)


func infusion_pop(at: Vector3, to: Vector3) -> void:
	burst(at, INFUSE, 10, 2.2, 0.8, 0.8, 0.45)
	burst(at, Color("#b48cff"), 5, 1.6, 0.6, 0.6, 0.35)
	float_icons(to, cross_mesh(), INFUSE, 2, 0.2, 0.7, 0.9)


## 寒气：身上冒一点淡蓝的冰晶
func chill_puff(at: Vector3) -> void:
	burst(at, ICE, 5, 1.0, 0.6, 0.4, 0.45)


# ---------------------------------------------------------------- 血嗜节点：血雾、血球、血之细流、血浪、血箭、失血、血迹
## 白色地面上叠加光看不见：血一律用普通混合(暗红的雾、深色的血迹)，只在核心叠一点亮红的光
const BLOOD := Color("#c4121f")
const BLOOD_HOT := Color("#ff4a52")
const BLOOD_DARK := Color("#5a0610")
const BLOOD_DEEP := Color("#2a0207")
const GRAV := 11.0

## 血球的表面：暗红的血在球面上流动(两层噪声)，中间一道道发亮的血脉，边缘一圈亮红的轮廓光 + 一点湿亮的高光；
## 顶点随时间轻轻起伏(液体的球)，beat = 心跳(鼓一下 + 变亮)
const BLOOD_ORB_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_back, shadows_disabled, fog_disabled;
uniform vec4 deep : source_color = vec4(0.16, 0.0, 0.02, 1.0);
uniform vec4 mid : source_color = vec4(0.77, 0.07, 0.12, 1.0);
uniform vec4 hot : source_color = vec4(1.0, 0.36, 0.38, 1.0);
uniform float wobble = 0.05;
uniform float beat = 0.0;
uniform float seed = 0.0;
varying vec3 lp;
float hash3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), u.x), mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), u.x), u.y);
	float b = mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), u.x), mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), u.x), u.y);
	return mix(a, b, u.z);
}
void vertex() {
	lp = VERTEX;
	vec3 n = normalize(VERTEX);
	float w = sin(n.y * 7.0 + TIME * 4.2 + seed) * sin(n.x * 6.0 - TIME * 3.3) + 0.5 * sin(n.z * 9.0 + TIME * 5.1);
	VERTEX += NORMAL * length(VERTEX) * (w * wobble + beat * 0.09);
}
void fragment() {
	vec3 n = normalize(lp);
	float t = TIME * 0.55;
	float flow = noise3(n * 2.6 + vec3(0.0, t, seed)) * 0.65 + noise3(n * 6.5 - vec3(t * 1.8, 0.0, seed)) * 0.35;
	float vein = 1.0 - smoothstep(0.0, 0.035, abs(flow - 0.5));
	vec3 c = mix(deep.rgb, mid.rgb, smoothstep(0.22, 0.78, flow));
	c += hot.rgb * vein * (0.9 + beat);
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.4);
	c = mix(c, hot.rgb * 1.5, fr * 0.75);
	vec3 L = normalize(vec3(-0.45, 0.75, 0.5));
	float spec = pow(clamp(dot(reflect(-L, NORMAL), VIEW), 0.0, 1.0), 28.0);
	c += vec3(1.0, 0.82, 0.82) * spec * 1.3;
	ALBEDO = c * (1.0 + beat * 0.55);
}
"""
## 血浪的浪墙：UV.x 绕圈、UV.y 横跨浪的剖面(0 内侧浪脚 → 0.6 浪尖 → 1 外侧浪脚)；浪尖亮、往上翻的血丝、浪尖撕开几个口子(飞溅)，fade 时从口子开始碎掉
const BLOOD_WAVE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 deep : source_color = vec4(0.1, 0.0, 0.012, 1.0);
uniform vec4 mid : source_color = vec4(0.42, 0.015, 0.04, 1.0);
uniform vec4 hot : source_color = vec4(0.95, 0.2, 0.24, 1.0);
uniform float fade = 1.0;
uniform float seed = 0.0;
uniform float radius = 1.0;
uniform float thick = 0.6;
uniform float height = 0.6;
void vertex() {
	vec2 d = normalize(VERTEX.xz);
	float off = length(VERTEX.xz) - 1.0;
	float ang = atan(d.y, d.x);
	float lump = sin(ang * 7.0 + seed) * 0.5 + sin(ang * 13.0 - seed * 1.7 + TIME * 3.0) * 0.3 + sin(ang * 3.0 + seed * 0.6) * 0.4;
	VERTEX.xz = d * max(0.05, radius + off * thick + lump * 0.06 * radius / 3.0);
	VERTEX.y *= height * (0.85 + 0.3 * lump);
}
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
void fragment() {
	float a = UV.x * 56.0;
	float v = UV.y;
	float n1 = noise(vec2(a, seed + TIME * 2.0));
	float n2 = noise(vec2(a * 2.3 + 17.0, v * 5.0 - TIME * 6.0 + seed));
	float crest = 1.0 - smoothstep(0.0, 0.32, abs(v - 0.6));
	if (crest > 0.55 && n2 < 0.22 + 0.5 * (1.0 - fade)) {
		discard;
	}
	if (n1 * 0.6 + n2 * 0.4 < (1.0 - fade) * 0.9) {
		discard;
	}
	vec3 c = mix(deep.rgb, mid.rgb, smoothstep(0.05, 0.55, v));
	float streak = smoothstep(0.55, 0.95, sin(a * 1.7 + n2 * 5.0 + v * 4.0) * 0.5 + 0.5);
	c += mid.rgb * streak * 0.35 * (1.0 - crest);
	c = mix(c, hot.rgb * 1.35, crest * (0.55 + 0.45 * n1));
	float foot = smoothstep(0.0, 0.3, v) * (1.0 - smoothstep(0.88, 1.0, v));
	vec3 nv = normalize(NORMAL) * (FRONT_FACING ? 1.0 : -1.0);
	float fr = 1.0 - abs(dot(nv, VIEW));
	vec3 L = normalize(vec3(-0.4, 0.8, 0.45));
	float spec = pow(clamp(dot(reflect(-L, nv), VIEW), 0.0, 1.0), 18.0) * (0.5 + n2);
	c = mix(c * 0.7, c * 1.15, fr);
	c += vec3(1.0, 0.75, 0.75) * spec * 0.9;
	float sheer = mix(0.42, 0.95, pow(fr, 0.8)) + 0.15 * n2 + crest * 0.2;
	ALBEDO = c;
	ALPHA = clamp(sheer * foot * fade, 0.0, 1.0);
}
"""
## 血柱(至亲的故事落地时，每个真正被打中的人脚下冲起来的)：一根往上喷的血柱，表面的血往上流、顶端参差不齐，top = 冲到多高(0..1)
const BLOOD_PILLAR_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_opaque, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 deep : source_color = vec4(0.14, 0.0, 0.02, 1.0);
uniform vec4 mid : source_color = vec4(0.62, 0.03, 0.08, 1.0);
uniform vec4 hot : source_color = vec4(1.0, 0.32, 0.34, 1.0);
uniform float top = 1.0;
uniform float seed = 0.0;
varying float hy;
varying float ang;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
void vertex() {
	hy = VERTEX.y + 0.5;
	ang = atan(VERTEX.z, VERTEX.x);
	float w = sin(hy * 9.0 - TIME * 14.0 + seed) * 0.12 + sin(ang * 3.0 + TIME * 6.0 + seed) * 0.06;
	VERTEX.xz *= 1.0 + w;
}
void fragment() {
	float n = noise(vec2(ang * 2.5 + seed, hy * 6.0 - TIME * 9.0));
	float cut = top - 0.14 * n;
	if (hy > cut) {
		discard;
	}
	float streak = smoothstep(0.55, 0.92, noise(vec2(ang * 5.0 + seed * 2.0, hy * 2.5 - TIME * 12.0)));
	vec3 c = mix(deep.rgb, mid.rgb, 0.4 + 0.45 * n);
	c += hot.rgb * streak * 0.55;
	float fr = pow(1.0 - abs(dot(normalize(NORMAL), VIEW)), 2.0);
	c = mix(c, hot.rgb * 1.25, fr * 0.55);
	c = mix(c, hot.rgb * 1.45, smoothstep(cut - 0.12, cut, hy) * 0.55);
	ALBEDO = c;
}
"""
var _blood_pillar_shader: Shader = null
var _blood_orb_shader: Shader = null
var _blood_wave_shader: Shader = null
var _wave_mesh: ArrayMesh = null
var _drop_mesh: SphereMesh = null


func _blood_drop_mesh() -> SphereMesh:
	if _drop_mesh == null:
		_drop_mesh = SphereMesh.new()
		_drop_mesh.radius = 0.5
		_drop_mesh.height = 1.0
		_drop_mesh.radial_segments = 8
		_drop_mesh.rings = 4
	return _drop_mesh


func _blood_orb_mat() -> ShaderMaterial:
	if _blood_orb_shader == null:
		_blood_orb_shader = Shader.new()
		_blood_orb_shader.code = BLOOD_ORB_SHADER
	var m := ShaderMaterial.new()
	m.shader = _blood_orb_shader
	m.set_shader_parameter("seed", randf() * 40.0)
	return m


## 一滴血(拉长的小球)：沿速度方向拉长
func _blood_drop(size: float) -> MeshInstance3D:
	var d := MeshInstance3D.new()
	d.mesh = _blood_drop_mesh()
	d.material_override = _emissive(BLOOD.lerp(BLOOD_HOT, randf() * 0.35), 1.25)
	d.scale = Vector3.ONE * size
	d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return d


static func _stretch_basis(vel: Vector3, size: float, stretch: float) -> Basis:
	var sp: float = vel.length()
	if sp < 0.05:
		return Basis.from_scale(Vector3.ONE * size)
	var f: Vector3 = vel / sp
	var up: Vector3 = Vector3.UP if absf(f.y) < 0.95 else Vector3.RIGHT
	return Basis.looking_at(f, up) * Basis.from_scale(Vector3(size, size, size * (1.0 + minf(stretch, sp * 0.35))))


## 一团暗红的雾(一次性)
func blood_mist(at: Vector3, amount: int = 4, size: float = 0.3, speed: float = 0.5, life: float = 0.6) -> void:
	var p := SoftFX.particles(amount, life, SoftFX.ramp([Color(BLOOD.r, BLOOD.g, BLOOD.b, 0.0), Color(BLOOD.r * 0.8, BLOOD.g, BLOOD.b, 0.5),
		Color(BLOOD_DARK.r, BLOOD_DARK.g, BLOOD_DARK.b, 0.3), Color(BLOOD_DEEP.r, BLOOD_DEEP.g, BLOOD_DEEP.b, 0.0)], [0.0, 0.18, 0.6, 1.0]), size, false)
	var pm: ParticleProcessMaterial = p.process_material
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = speed * 0.3
	pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, 0.35, 0)
	pm.damping_min = 1.2
	pm.damping_max = 2.4
	(p.material_override as StandardMaterial3D).disable_fog = true
	p.one_shot = true
	p.explosiveness = 0.85
	p.emitting = true
	add_child(p)
	p.global_position = at
	p.speed_scale = _pslow()
	get_tree().create_timer((life + 0.3) / _pslow()).timeout.connect(p.queue_free)


## 地上一滩血：radius 半径，spread 秒内摊开，停 hold 秒后 life 秒里淡掉
func blood_splat(at: Vector3, radius: float, spread: float = 0.12, hold: float = 0.6, life: float = 1.2, drops: float = 1.0) -> void:
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(radius * 2.0, radius * 2.0)
	m.mesh = pm
	var mat: ShaderMaterial = SoftFX.splat_mat()
	mat.set_shader_parameter("drops", drops)
	mat.set_shader_parameter("grow", 0.15)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	m.global_position = Vector3(at.x, 0.03 + randf() * 0.006, at.z)
	m.rotation.y = randf() * TAU
	var s: float = maxf(0.2, speed_scale)
	var tw: Tween = create_tween()
	tw.tween_method(func(x: float) -> void: mat.set_shader_parameter("grow", x), 0.15, 1.0, maxf(0.02, spread) / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_interval(hold / s)
	tw.tween_method(func(x: float) -> void: mat.set_shader_parameter("fade", x), 1.0, 0.0, life / s).set_ease(Tween.EASE_IN)
	tw.tween_callback(m.queue_free)


## 几滴血从 at 溅出去(抛物线)，落地留一小点血迹。dir = 主要往哪边溅(水平；零向量 = 四面)
func blood_spray(at: Vector3, dir: Vector3, count: int = 5, speed: float = 1.4, up: float = 1.2, size: float = 0.05, stains: bool = true) -> void:
	var s: float = maxf(0.2, speed_scale)
	var h: Vector3 = Vector3(dir.x, 0.0, dir.z)
	for i in range(count):
		var a: float = randf() * TAU
		var side := Vector3(cos(a), 0.0, sin(a))
		var v0: Vector3 = (h.normalized() * 0.75 + side * 0.45).normalized() * speed * randf_range(0.5, 1.15) if h.length() > 0.01 else side * speed * randf_range(0.3, 1.0)
		v0.y = up * randf_range(0.5, 1.2)
		var p0: Vector3 = at + side * 0.04
		var hgt: float = maxf(0.02, p0.y - 0.03)
		var t_land: float = (v0.y + sqrt(v0.y * v0.y + 2.0 * GRAV * hgt)) / GRAV
		var d: MeshInstance3D = _blood_drop(size * randf_range(0.7, 1.25))
		add_child(d)
		d.global_position = p0
		var sz: float = d.scale.x
		var tw: Tween = create_tween()
		tw.tween_method(func(t: float) -> void:
			if is_instance_valid(d):
				var v: Vector3 = v0 + Vector3(0.0, -GRAV * t, 0.0)
				d.global_transform = Transform3D(_stretch_basis(v, sz, 1.6), p0 + v0 * t + Vector3(0.0, -0.5 * GRAV * t * t, 0.0)), 0.0, t_land, t_land / s)
		if stains and i % 2 == 0:
			tw.tween_callback(func() -> void:
				if is_instance_valid(d):
					blood_splat(d.global_position, randf_range(0.06, 0.12), 0.05, 0.5, 0.9, 0.3))
		tw.tween_callback(d.queue_free)


## 血球(至亲的故事)：流动的血构成的液体球(会起伏、一下一下地心跳)，外面一圈暗红的雾晕，几颗血珠绕着它转；挂在 parent 下面。
## 返回根节点：缩放 = 球的大小；"Beat" 子节点上挂着心跳的 tween
func blood_orb(parent: Node3D, radius: float) -> Node3D:
	var root := Node3D.new()
	root.name = "BloodOrb"
	var shell := MeshInstance3D.new()
	shell.name = "Shell"
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 24
	sm.rings = 12
	shell.mesh = sm
	var mat: ShaderMaterial = _blood_orb_mat()
	shell.material_override = mat
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(shell)
	# 雾晕：暗红的普通混合(白地上也看得见) + 一点亮红的叠加光(暗地上发光)
	for H: Array in [[3.2, BLOOD_DARK, 1.0, false, 0.55], [2.3, BLOOD_HOT, 0.9, true, 0.8]]:
		var hm := MeshInstance3D.new()
		hm.name = "Halo"
		hm.mesh = SoftFX.quad(1.0)
		var hmat: StandardMaterial3D = SoftFX.sprite_mat(H[1] as Color, float(H[2]), bool(H[3]))
		hmat.albedo_color.a = float(H[4])
		hmat.disable_fog = true
		hm.material_override = hmat
		hm.scale = Vector3.ONE * radius * float(H[0])
		hm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(hm)
	# 绕着转的血珠：三个倾斜的轨道
	for k in range(3):
		var orbit := Node3D.new()
		orbit.name = "Orbit"
		orbit.rotation = Vector3(deg_to_rad(25.0 + 40.0 * k), deg_to_rad(70.0 * k), 0.0)
		root.add_child(orbit)
		for j in range(2):
			var d: MeshInstance3D = _blood_drop(radius * (0.3 - 0.06 * j))
			var a: float = PI * float(j) + 0.7 * k
			d.position = Vector3(cos(a), 0.0, sin(a)) * radius * (1.5 + 0.12 * k)
			d.rotation.y = -a
			d.scale = Vector3(1.0, 1.0, 1.7) * radius * (0.3 - 0.06 * j)
			orbit.add_child(d)
		var to: Tween = orbit.create_tween().set_loops()
		to.tween_property(orbit, "rotation:y", orbit.rotation.y + TAU * (1.0 if k % 2 == 0 else -1.0), 1.1 + 0.35 * k).from(orbit.rotation.y)
	# 心跳：咚-咚——停
	var beat := Node3D.new()
	beat.name = "Beat"
	root.add_child(beat)
	var tb: Tween = beat.create_tween().set_loops()
	tb.tween_method(func(x: float) -> void: mat.set_shader_parameter("beat", x), 0.0, 1.0, 0.07)
	tb.tween_method(func(x: float) -> void: mat.set_shader_parameter("beat", x), 1.0, 0.0, 0.13)
	tb.tween_method(func(x: float) -> void: mat.set_shader_parameter("beat", x), 0.0, 0.6, 0.07)
	tb.tween_method(func(x: float) -> void: mat.set_shader_parameter("beat", x), 0.6, 0.0, 0.2)
	tb.tween_interval(0.45)
	parent.add_child(root)
	return root


## 血液往血球里聚：一条细细的血流从 from 沿弯曲的弧线流进血球(跟着血球走)，流头亮、流尾细，源头渗出一点雾
func blood_stream(from: Vector3, orb: Node3D) -> void:
	if not is_instance_valid(orb):
		return
	var s: float = maxf(0.2, speed_scale)
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.material_override = _rivulet_mat()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.top_level = true
	mi.global_transform = Transform3D.IDENTITY
	var dest: Vector3 = orb.global_position
	var side: Vector3 = (dest - from).cross(Vector3.UP)
	side = side.normalized() * randf_range(-0.7, 0.7) if side.length() > 0.01 else Vector3.RIGHT * 0.3
	var lift: float = randf_range(0.3, 0.7)
	var ph: float = randf() * TAU
	var dur: float = clampf(0.35 + from.distance_to(dest) * 0.06, 0.4, 0.75)
	var tw: Tween = create_tween()
	tw.tween_method(_rivulet_step.bind(im, from, orb, side, lift, ph, dest), 0.0, 1.5, dur * 1.5 / s)
	tw.tween_callback(mi.queue_free)
	blood_mist(from, 2, 0.2, 0.35, 0.45)


var _riv_mat: StandardMaterial3D = null


func _rivulet_mat() -> StandardMaterial3D:
	if _riv_mat == null:
		_riv_mat = StandardMaterial3D.new()
		_riv_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_riv_mat.vertex_color_use_as_albedo = true
		_riv_mat.vertex_color_is_srgb = true
		_riv_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_riv_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_riv_mat.disable_fog = true
	return _riv_mat


## 细流的一帧：k 0 → 1 流头从源头流到血球，k 1 → 1.5 流尾跟进去；沿途是一根两头尖的血管(管子)，带一点蛇行
func _rivulet_step(k: float, im: ImmediateMesh, from: Vector3, orb: Variant, side: Vector3, lift: float, ph: float, last: Vector3) -> void:
	var dest: Vector3 = (orb as Node3D).global_position if is_instance_valid(orb) else last
	var head: float = clampf(k, 0.0, 1.0)
	var tail: float = clampf(k - 0.5, 0.0, 1.0)
	im.clear_surfaces()
	if head - tail < 0.02:
		return
	var mid: Vector3 = (from + dest) * 0.5 + Vector3(0.0, lift, 0.0) + side
	var n: int = 12
	var pts: Array = []
	var rad: Array = []
	var cols: Array = []
	for i in range(n + 1):
		var u: float = lerpf(tail, head, float(i) / float(n))
		var p: Vector3 = from.lerp(mid, u).lerp(mid.lerp(dest, u), u)
		var w: float = sin(u * PI) * 0.07
		p += side.normalized() * sin(u * 9.0 + ph) * w + Vector3(0.0, cos(u * 7.0 + ph) * w * 0.6, 0.0)
		pts.append(p)
		var e: float = float(i) / float(n)
		rad.append(0.028 * pow(sin(PI * clampf(e * 0.92 + 0.04, 0.0, 1.0)), 0.6) * (0.7 + 0.5 * e))
		var c: Color = BLOOD_DARK.lerp(BLOOD, e).lerp(BLOOD_HOT * 1.3, pow(e, 6.0))
		cols.append(Color(c.r, c.g, c.b, 0.95))
	_tube(im, pts, rad, cols)


## 沿一串点画一根管子(5 边形截面)；rad / cols 是每个点的半径和颜色
func _tube(im: ImmediateMesh, pts: Array, rad: Array, cols: Array, sides: int = 5) -> void:
	var n: int = pts.size()
	if n < 2:
		return
	var rings: Array = []
	for i in range(n):
		var t: Vector3 = (pts[mini(i + 1, n - 1)] as Vector3) - (pts[maxi(i - 1, 0)] as Vector3)
		t = t.normalized() if t.length() > 1e-5 else Vector3.FORWARD
		var nn: Vector3 = t.cross(Vector3.UP if absf(t.y) < 0.95 else Vector3.RIGHT).normalized()
		var bb: Vector3 = t.cross(nn)
		var ring: Array = []
		for j in range(sides):
			var a: float = TAU * float(j) / float(sides)
			ring.append((pts[i] as Vector3) + (nn * cos(a) + bb * sin(a)) * float(rad[i]))
		rings.append(ring)
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _rivulet_mat())
	for i in range(n - 1):
		var c0: Color = cols[i]
		var c1: Color = cols[i + 1]
		for j in range(sides):
			var j2: int = (j + 1) % sides
			var a0: Vector3 = rings[i][j]
			var a1: Vector3 = rings[i][j2]
			var b0: Vector3 = rings[i + 1][j]
			var b1: Vector3 = rings[i + 1][j2]
			for vc: Array in [[a0, c0], [b0, c1], [a1, c0], [a1, c0], [b0, c1], [b1, c1]]:
				im.surface_set_color(vc[1])
				im.surface_add_vertex(vc[0])
	im.surface_end()


## 吸血的血雾：失血的目标伤口渗出一团暗红的雾，雾拉成一缕、打着旋沿弧线飘向血嗜节点(跟着他走)，被他吸进胸口
## to = 他的模型节点，to_off = 胸口相对模型的偏移
func blood_drain(from: Vector3, to: Node3D, to_off: Vector3) -> void:
	if not is_instance_valid(to):
		return
	var s: float = maxf(0.2, speed_scale)
	blood_mist(from, 3, 0.24, 0.35, 0.5)
	var dest: Vector3 = to.global_position + to_off
	var dist: float = from.distance_to(dest)
	var side: Vector3 = (dest - from).cross(Vector3.UP)
	side = side.normalized() * randf_range(-0.55, 0.55) if side.length() > 0.01 else Vector3.ZERO
	var lift: float = randf_range(0.25, 0.5) + dist * 0.08
	var ph: float = randf() * TAU
	var dur: float = clampf(0.45 + dist * 0.06, 0.5, 0.9) / s
	var n: int = 12
	for i in range(n):
		var dark: bool = i % 3 != 1
		var m := MeshInstance3D.new()
		m.mesh = SoftFX.quad(1.0)
		var mat: StandardMaterial3D = SoftFX.sprite_mat(BLOOD_DARK.lerp(BLOOD, randf_range(0.3, 0.8)) if dark else BLOOD_HOT, 1.0 if dark else 1.2, not dark)
		mat.albedo_color.a = 0.0
		mat.disable_fog = true
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		m.global_position = from
		m.scale = Vector3.ONE * 0.01
		var tw: Tween = create_tween()
		tw.tween_interval(float(i) * 0.04 / s)
		tw.tween_method(_drain_step.bind(m, mat, from, to, to_off, side, lift, ph + float(i) * 0.6, dark, dest), 0.0, 1.0, dur)
		tw.tween_callback(m.queue_free)
	# 两三滴血跟着雾一起飞(更快、更靠中线)
	for j in range(3):
		var d: MeshInstance3D = _blood_drop(0.035)
		add_child(d)
		d.global_position = from
		var tw2: Tween = create_tween()
		tw2.tween_interval((0.04 + 0.08 * float(j)) / s)
		tw2.tween_method(_drain_drop_step.bind(d, from, to, to_off, side * 0.5, lift * 0.8, dest), 0.0, 1.0, dur * 0.8)
		tw2.tween_callback(d.queue_free)
	get_tree().create_timer(dur + float(n) * 0.04 / s).timeout.connect(_drain_land.bind(to, to_off))


func _drain_path(k: float, from: Vector3, to: Variant, to_off: Vector3, side: Vector3, lift: float, last: Vector3) -> Vector3:
	var dest: Vector3 = (to as Node3D).global_position + to_off if is_instance_valid(to) else last
	var mid: Vector3 = (from + dest) * 0.5 + Vector3(0.0, lift, 0.0) + side
	return from.lerp(mid, k).lerp(mid.lerp(dest, k), k)


func _drain_step(k: float, m: Variant, mat: StandardMaterial3D, from: Vector3, to: Variant, to_off: Vector3, side: Vector3, lift: float,
		ph: float, dark: bool, last: Vector3) -> void:
	if not is_instance_valid(m):
		return
	var mi: MeshInstance3D = m
	var kk: float = ease(k, 0.8)
	var p: Vector3 = _drain_path(kk, from, to, to_off, side, lift, last)
	var sw: float = sin(k * PI)
	var rr: float = 0.13 * sw
	p += Vector3(cos(ph + k * 8.0), sin(ph + k * 8.0) * 0.6, sin(ph + k * 8.0)) * rr
	mi.global_position = p
	var sz: float = (0.16 + 0.3 * pow(sw, 0.7)) * (1.0 - 0.6 * k * k) if dark else 0.1 + 0.07 * sw
	mi.scale = Vector3.ONE * sz
	mat.albedo_color.a = pow(sw, 0.5) * (0.8 if dark else 0.9)


func _drain_drop_step(k: float, d0: Variant, from: Vector3, to: Variant, to_off: Vector3, side: Vector3, lift: float, last: Vector3) -> void:
	if not is_instance_valid(d0):
		return
	var d: MeshInstance3D = d0
	var p: Vector3 = _drain_path(k, from, to, to_off, side, lift, last)
	var p2: Vector3 = _drain_path(minf(1.0, k + 0.05), from, to, to_off, side, lift, last)
	d.global_transform = Transform3D(_stretch_basis((p2 - p) * 40.0, 0.035 * (1.0 - 0.5 * k), 1.4), p)


## 血雾被吸进胸口：一圈雾往里一收 + 一点红光
func _drain_land(to: Variant, to_off: Vector3) -> void:
	if not is_instance_valid(to):
		return
	var at: Vector3 = (to as Node3D).global_position + to_off
	soft_flash(at, BLOOD_HOT, 0.45, 0.18, 1.2)
	var s: float = maxf(0.2, speed_scale)
	for i in range(4):
		var m := MeshInstance3D.new()
		m.mesh = SoftFX.quad(1.0)
		var mat: StandardMaterial3D = SoftFX.sprite_mat(BLOOD_DARK.lerp(BLOOD, 0.5), 1.0, false)
		mat.albedo_color.a = 0.6
		mat.disable_fog = true
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		var a: float = TAU * float(i) / 4.0 + randf() * 0.5
		m.global_position = at + Vector3(cos(a) * 0.35, randf_range(-0.1, 0.15), sin(a) * 0.35)
		m.scale = Vector3.ONE * 0.22
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(m, "global_position", at, 0.18 / s).set_ease(Tween.EASE_IN)
		tw.tween_property(m, "scale", Vector3.ONE * 0.05, 0.18 / s)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.18 / s).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(m.queue_free)


## 血欲(血嗜节点身上一直挂着)：脚下一圈暗红的雾往上飘，层数越多越浓(set_blood_aura 调)
func blood_aura(parent: Node3D, radius: float) -> GPUParticles3D:
	var p := SoftFX.particles(18, 1.5, SoftFX.ramp([Color(BLOOD.r, BLOOD.g, BLOOD.b, 0.0), Color(BLOOD.r * 0.7, BLOOD.g, BLOOD.b, 0.32),
		Color(BLOOD_DARK.r, BLOOD_DARK.g, BLOOD_DARK.b, 0.2), Color(BLOOD_DEEP.r, BLOOD_DEEP.g, BLOOD_DEEP.b, 0.0)], [0.0, 0.25, 0.6, 1.0]), 0.34, false)
	var pm: ParticleProcessMaterial = p.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = radius
	pm.emission_ring_inner_radius = radius * 0.5
	pm.emission_ring_height = 0.05
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 20.0
	pm.initial_velocity_min = 0.15
	pm.initial_velocity_max = 0.35
	pm.gravity = Vector3(0, 0.25, 0)
	pm.tangential_accel_min = 0.3
	pm.tangential_accel_max = 0.6
	(p.material_override as StandardMaterial3D).disable_fog = true
	p.amount_ratio = 0.0
	p.emitting = true
	p.position = Vector3(0.0, 0.08, 0.0)
	parent.add_child(p)
	return p


## 群攻：血球沿抛物线丢到 to，砸下去：一柱血冲起来 + 一道血浪往外推到 radius(浪尖撕开的地方飞溅) + 地上摊开一大片血；
## 血浪扫到 hits(被打中的人的胸口)时，那个人身上炸开一团血
## flight = 飞多久(战斗秒)：BattleView 按逻辑层给的落地时刻倒推，落地的一瞬 = 武器效果结算(throw_land)
func blood_throw(orb: Node3D, to: Vector3, radius: float, big: bool, flight: float = 0.3) -> void:
	if not is_instance_valid(orb):
		return
	var from: Vector3 = orb.global_position
	var gx: Transform3D = orb.global_transform
	orb.get_parent().remove_child(orb)
	add_child(orb)
	orb.global_transform = gx
	var trail: Array = _blood_trail(orb, big)
	var s: float = maxf(0.2, speed_scale)
	var arc: float = 1.1 if big else 0.8
	var tw: Tween = create_tween()
	tw.tween_method(func(k: float) -> void:
		if is_instance_valid(orb):
			orb.global_position = from.lerp(to + Vector3(0.0, 0.2, 0.0), k * k * 0.35 + k * 0.65) + Vector3(0.0, arc * sin(minf(k, 1.0) * PI), 0.0), 0.0, 1.0, maxf(0.03, flight) / s)
	tw.tween_callback(_blood_trail_drop.bind(trail))
	tw.tween_callback(_blood_crash.bind(to, radius, big))
	tw.tween_callback(orb.queue_free)


## 飞行中的血球拖出的尾巴：血珠(世界坐标的粒子) + 一缕暗红的雾
func _blood_trail(orb: Node3D, big: bool) -> Array:
	var out: Array = []
	var drops := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 60.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.8
	pm.gravity = Vector3(0, -GRAV, 0)
	pm.scale_min = 0.03 if big else 0.02
	pm.scale_max = 0.07 if big else 0.04
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.2 if big else 0.08
	drops.process_material = pm
	drops.draw_pass_1 = _blood_drop_mesh()
	drops.material_override = _emissive(BLOOD, 1.3)
	drops.amount = 40 if big else 14
	drops.lifetime = 0.5
	drops.local_coords = false
	drops.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	drops.visibility_aabb = AABB(Vector3(-6, -4, -6), Vector3(12, 8, 12))
	drops.emitting = true
	drops.speed_scale = _pslow()
	orb.add_child(drops)
	out.append(drops)
	var mist := SoftFX.particles(24 if big else 10, 0.5, SoftFX.ramp([Color(BLOOD.r, BLOOD.g, BLOOD.b, 0.0), Color(BLOOD.r * 0.8, BLOOD.g, BLOOD.b, 0.45),
		Color(BLOOD_DEEP.r, BLOOD_DEEP.g, BLOOD_DEEP.b, 0.0)], [0.0, 0.2, 1.0]), 0.42 if big else 0.2, false)
	var mm: ParticleProcessMaterial = mist.process_material
	(mist.material_override as StandardMaterial3D).disable_fog = true
	mm.spread = 180.0
	mm.initial_velocity_min = 0.05
	mm.initial_velocity_max = 0.2
	mist.visibility_aabb = AABB(Vector3(-6, -4, -6), Vector3(12, 8, 12))
	mist.emitting = true
	mist.speed_scale = _pslow()
	orb.add_child(mist)
	out.append(mist)
	return out


## 血球落地 / 打中：尾巴的粒子留在原地自己散完(不跟着血球一起没)
func _blood_trail_drop(trail: Array) -> void:
	for p0: Variant in trail:
		var p := p0 as GPUParticles3D
		if p == null or not is_instance_valid(p):
			continue
		var gp: Transform3D = p.global_transform
		p.get_parent().remove_child(p)
		add_child(p)
		p.global_transform = gp
		p.emitting = false
		get_tree().create_timer(0.8 / _pslow()).timeout.connect(p.queue_free)


func _blood_crash(at: Vector3, radius: float, big: bool) -> void:
	var g := Vector3(at.x, 0.0, at.z)
	var s: float = maxf(0.2, speed_scale)
	var r: float = maxf(1.0, radius)
	# 砸下去的一瞬：暗红的一闪 + 中心冲起一柱血 + 一大团雾
	soft_flash(g + Vector3(0.0, 0.4, 0.0), BLOOD_HOT, 1.6 if big else 0.9, 0.2, 1.3)
	_blood_geyser(g, big)
	blood_mist(g + Vector3(0.0, 0.3, 0.0), 12 if big else 6, 0.75 if big else 0.45, 1.8 if big else 1.0, 0.9)
	blood_splat(g, 1.3 if big else 0.75, 0.12, 1.6, 1.4)
	# 血浪：一道薄薄的浪墙往外推到 radius，越推越矮，推到头碎掉；浪尖一路往外甩血珠，扫过的地上溅出一块块血迹
	var dur: float = (0.5 + 0.06 * r) * (1.0 if big else 0.85)
	var hgt: float = 0.62 if big else 0.32
	var w := MeshInstance3D.new()
	w.mesh = _blood_wave_mesh()
	if _blood_wave_shader == null:
		_blood_wave_shader = Shader.new()
		_blood_wave_shader.code = BLOOD_WAVE_SHADER
	var wm := ShaderMaterial.new()
	wm.shader = _blood_wave_shader
	wm.set_shader_parameter("seed", randf() * 30.0)
	wm.set_shader_parameter("thick", 2.2 if big else 1.3)
	wm.set_shader_parameter("radius", 0.3)
	wm.set_shader_parameter("height", 0.05)
	wm.render_priority = 2
	w.material_override = wm
	w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	w.custom_aabb = AABB(Vector3(-r - 1.0, -0.5, -r - 1.0), Vector3(2.0 * r + 2.0, 2.0, 2.0 * r + 2.0))
	add_child(w)
	w.global_position = g + Vector3(0.0, 0.02, 0.0)
	var spray := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = 0.3
	pm.emission_ring_inner_radius = 0.25
	pm.emission_ring_height = 0.05
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 30.0
	pm.initial_velocity_min = 1.4 if big else 0.9
	pm.initial_velocity_max = 3.0 if big else 1.8
	pm.radial_velocity_min = 0.8
	pm.radial_velocity_max = 2.0
	pm.gravity = Vector3(0, -GRAV, 0)
	pm.scale_min = 0.035
	pm.scale_max = 0.07
	spray.process_material = pm
	spray.draw_pass_1 = _blood_drop_mesh()
	spray.material_override = _emissive(BLOOD, 1.2)
	spray.amount = int((70 if big else 30) * clampf(r / 4.0, 0.6, 1.6))
	spray.lifetime = 0.55
	spray.local_coords = false
	spray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	spray.visibility_aabb = AABB(Vector3(-r - 2.0, -1, -r - 2.0), Vector3(2.0 * r + 4.0, 5, 2.0 * r + 4.0))
	spray.speed_scale = _pslow()
	spray.emitting = true
	add_child(spray)
	spray.global_position = g + Vector3(0.0, 0.1, 0.0)
	var st := {"r": 0.6}                      # 上一次在多远处溅过血迹
	var tw: Tween = create_tween()
	tw.tween_method(func(k: float) -> void:
		if not is_instance_valid(w):
			return
		var e: float = 1.0 - pow(1.0 - k, 2.2)
		var rr: float = lerpf(0.3, r, e)
		wm.set_shader_parameter("radius", rr)
		wm.set_shader_parameter("height", maxf(0.02, hgt * minf(1.0, k * 7.0) * (1.0 - 0.75 * k)))
		wm.set_shader_parameter("fade", 1.0 - smoothstep(0.62, 1.0, k))
		if is_instance_valid(spray):
			pm.emission_ring_radius = rr
			pm.emission_ring_inner_radius = rr * 0.94
			if k > 0.85:
				spray.emitting = false
		# 浪扫过的地方：每往外推 0.55 米，在浪脚后面溅几块血迹(越外越稀)
		while rr - float(st["r"]) > 0.55:
			st["r"] = float(st["r"]) + 0.55
			var cnt: int = maxi(1, int(round(float(st["r"]) * (1.1 if big else 0.6))))
			for i in range(cnt):
				var aa: float = randf() * TAU
				var rd: float = float(st["r"]) - randf() * 0.4
				blood_splat(g + Vector3(cos(aa) * rd, 0.0, sin(aa) * rd), randf_range(0.14, 0.34) * (1.0 if big else 0.75), 0.08, 0.9 + randf() * 0.6, 1.1, 0.6), 0.0, 1.0, dur / s)
	tw.tween_callback(w.queue_free)
	tw.tween_interval(0.6 / s)
	tw.tween_callback(spray.queue_free)
	# (被打中的人身上的血柱由 throw_land 画：blood_pillar)



## 中心冲起来的一柱血：往上喷的血珠 + 一道细的血柱(拉长的血滴)
func _blood_geyser(g: Vector3, big: bool) -> void:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 16.0 if big else 24.0
	pm.initial_velocity_min = 3.5 if big else 2.2
	pm.initial_velocity_max = 6.5 if big else 3.6
	pm.gravity = Vector3(0, -GRAV * 1.2, 0)
	pm.scale_min = 0.04
	pm.scale_max = 0.1 if big else 0.07
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.15
	p.process_material = pm
	p.draw_pass_1 = _blood_drop_mesh()
	p.material_override = _emissive(BLOOD, 1.4)
	p.amount = 48 if big else 18
	p.lifetime = 1.0
	p.one_shot = true
	p.explosiveness = 0.75
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 6, 6))
	p.speed_scale = _pslow()
	p.emitting = true
	add_child(p)
	p.global_position = g + Vector3(0.0, 0.15, 0.0)
	get_tree().create_timer(1.4 / _pslow()).timeout.connect(p.queue_free)


## 浪墙的网格：半径 1、高 1 的一圈浪(剖面：内侧缓坡 → 浪尖 → 外侧陡坡往外卷)，UV.x 绕圈、UV.y 横跨剖面
func _blood_wave_mesh() -> ArrayMesh:
	if _wave_mesh != null:
		return _wave_mesh
	var prof: Array = [Vector2(0.74, 0.0), Vector2(0.84, 0.12), Vector2(0.91, 0.38), Vector2(0.955, 0.7), Vector2(0.985, 0.93), Vector2(1.0, 1.0),
		Vector2(1.025, 0.9), Vector2(1.045, 0.62), Vector2(1.05, 0.3), Vector2(1.04, 0.0)]
	var segs: int = 72
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var np: int = prof.size()
	var norms := PackedVector3Array()
	for i in range(segs + 1):
		var a: float = TAU * float(i) / float(segs)
		var d := Vector3(cos(a), 0.0, sin(a))
		for j in range(np):
			var pr: Vector2 = prof[j]
			var tg: Vector2 = (prof[mini(j + 1, np - 1)] as Vector2) - (prof[maxi(j - 1, 0)] as Vector2)
			var nn := Vector2(-tg.y, tg.x).normalized()
			verts.append(d * pr.x + Vector3(0.0, pr.y, 0.0))
			norms.append((d * nn.x + Vector3(0.0, nn.y, 0.0)).normalized())
			uvs.append(Vector2(float(i) / float(segs), float(j) / float(np - 1)))
	for i in range(segs):
		for j in range(np - 1):
			var a0: int = i * np + j
			var b0: int = (i + 1) * np + j
			idx.append_array([a0, b0, a0 + 1, a0 + 1, b0, b0 + 1])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	_wave_mesh = ArrayMesh.new()
	_wave_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return _wave_mesh


## 被血打中：身上炸开一团血(往远离来向的一边喷)，一团雾，脚下一小滩血
func _blood_hit(at: Vector3, away: Vector3, big: bool = false) -> void:
	soft_flash(at, BLOOD_HOT, 0.55 if big else 0.4, 0.14, 1.2)
	blood_spray(at, away, 7 if big else 5, 1.8 if big else 1.3, 1.6, 0.05, true)
	blood_mist(at, 4 if big else 3, 0.3, 0.6, 0.55)
	blood_splat(Vector3(at.x, 0.0, at.z) + Vector3(away.x, 0.0, away.z).normalized() * 0.15, randf_range(0.22, 0.32), 0.1, 0.8, 1.2)


## 无群攻：血球拉长成一支血矛射向 to(一路掉血珠、拖着雾)，打中炸开
func blood_arrow(orb: Node3D, to: Vector3, flight: float = 0.2) -> void:
	if not is_instance_valid(orb):
		return
	var from: Vector3 = orb.global_position
	orb.get_parent().remove_child(orb)
	add_child(orb)
	orb.global_position = from
	for hn: Node in orb.get_children():
		if hn.name.begins_with("Halo") or hn.name.begins_with("Orbit"):
			(hn as Node3D).visible = false
	var d: Vector3 = to - from
	if d.length() > 0.05:
		orb.global_transform = Transform3D(Basis.looking_at(d.normalized(), Vector3.UP if absf(d.normalized().y) < 0.95 else Vector3.RIGHT)
			* Basis.from_scale(Vector3(0.5, 0.5, 2.8)), from)
	var trail: Array = _blood_trail(orb, false)
	var s: float = maxf(0.2, speed_scale)
	var tw: Tween = create_tween()
	tw.tween_property(orb, "global_position", to, maxf(0.03, flight) / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(_blood_trail_drop.bind(trail))
	tw.tween_callback(_blood_hit.bind(to, Vector3(d.x, 0.0, d.z), false))
	tw.tween_callback(orb.queue_free)


## 吟唱被打断：血球破掉——血往下泼、一团雾、地上一滩血
func blood_orb_pop(orb: Variant) -> void:
	if not is_instance_valid(orb):
		return
	var at: Vector3 = (orb as Node3D).global_position
	(orb as Node3D).queue_free()
	soft_flash(at, BLOOD_HOT, 0.8, 0.16, 1.2)
	blood_mist(at, 6, 0.45, 0.9, 0.7)
	blood_spray(at, Vector3.ZERO, 10, 1.4, 0.4, 0.06, true)
	blood_splat(Vector3(at.x, 0.0, at.z), 0.75, 0.35, 1.0, 1.2)


## 血柱：at 脚下冲起一根血柱(高 height 米)：地上先炸开一圈血、一滩血，柱子 0.1 秒冲到顶、顶上喷出一把血珠和一团雾，然后从上往下塌回去
func blood_pillar(at: Vector3, height: float, big: bool = true) -> void:
	var g := Vector3(at.x, 0.0, at.z)
	var s: float = maxf(0.2, speed_scale)
	if _blood_pillar_shader == null:
		_blood_pillar_shader = Shader.new()
		_blood_pillar_shader.code = BLOOD_PILLAR_SHADER
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.13
	cm.bottom_radius = 0.25
	cm.height = 1.0
	cm.radial_segments = 14
	cm.rings = 10
	cm.cap_top = false
	cm.cap_bottom = false
	m.mesh = cm
	var mat := ShaderMaterial.new()
	mat.shader = _blood_pillar_shader
	mat.set_shader_parameter("seed", randf() * 30.0)
	mat.set_shader_parameter("top", 0.0)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	var w: float = 1.0 if big else 0.75
	m.global_position = g + Vector3(0.0, height * 0.5, 0.0)
	m.scale = Vector3(w, height, w)
	soft_flash(g + Vector3(0.0, 0.25, 0.0), BLOOD_HOT, 0.7 if big else 0.5, 0.14, 1.2)
	blood_splat(g, randf_range(0.32, 0.42) * w, 0.08, 1.0, 1.2)
	blood_spray(g + Vector3(0.0, 0.08, 0.0), Vector3.ZERO, 6 if big else 4, 1.6, 0.9, 0.05, false)
	var tw: Tween = create_tween()
	tw.tween_method(func(x: float) -> void: mat.set_shader_parameter("top", x), 0.0, 1.0, 0.1 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(_pillar_crown.bind(g + Vector3(0.0, height, 0.0), big))
	tw.tween_interval(0.12 / s)
	tw.tween_method(func(x: float) -> void: mat.set_shader_parameter("top", x), 1.0, 0.0, 0.32 / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(m, "scale", Vector3(w * 0.45, height, w * 0.45), 0.32 / s)
	tw.tween_callback(m.queue_free)


## 血柱的顶：往上喷开的一把血珠 + 一团雾
func _pillar_crown(at: Vector3, big: bool) -> void:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 42.0
	pm.initial_velocity_min = 1.2
	pm.initial_velocity_max = 3.2 if big else 2.2
	pm.gravity = Vector3(0, -GRAV, 0)
	pm.scale_min = 0.035
	pm.scale_max = 0.07
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.08
	p.process_material = pm
	p.draw_pass_1 = _blood_drop_mesh()
	p.material_override = _emissive(BLOOD, 1.3)
	p.amount = 22 if big else 12
	p.lifetime = 0.9
	p.one_shot = true
	p.explosiveness = 0.85
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-3, -4, -3), Vector3(6, 6, 6))
	p.speed_scale = _pslow()
	p.emitting = true
	add_child(p)
	p.global_position = at
	get_tree().create_timer(1.3 / _pslow()).timeout.connect(p.queue_free)
	blood_mist(at, 4 if big else 2, 0.35, 0.6, 0.6)


## 失血上身：伤口往外溅几滴血(away = 远离伤害来源的方向)，一缕雾，落在地上留下小血点
func bleed_drip(at: Vector3, away: Vector3 = Vector3.ZERO) -> void:
	blood_spray(at, away, 4, 0.9, 0.7, 0.04, true)
	blood_mist(at, 2, 0.18, 0.25, 0.45)


## 血宴 +1：四周的血雾往他脚下收，脚下一圈暗红
func blood_feast(at: Vector3) -> void:
	var s: float = maxf(0.2, speed_scale)
	var g := Vector3(at.x, 0.0, at.z)
	ring(g + Vector3(0.0, 0.03, 0.0), 1.1, BLOOD_DARK, 0.5, 1.4, 0.4)
	for i in range(6):
		var m := MeshInstance3D.new()
		m.mesh = SoftFX.quad(1.0)
		var mat: StandardMaterial3D = SoftFX.sprite_mat(BLOOD_DARK.lerp(BLOOD, 0.4), 1.0, false)
		mat.albedo_color.a = 0.0
		mat.disable_fog = true
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		var a: float = TAU * float(i) / 6.0 + randf() * 0.4
		var p0: Vector3 = g + Vector3(cos(a) * 1.5, 0.25 + randf() * 0.3, sin(a) * 1.5)
		m.global_position = p0
		m.scale = Vector3.ONE * 0.4
		var tw: Tween = create_tween()
		tw.tween_method(func(k: float) -> void:
			if is_instance_valid(m):
				var aa: float = a + k * 1.6
				var rr: float = 1.5 * (1.0 - k)
				m.global_position = g + Vector3(cos(aa) * rr, lerpf(p0.y - g.y, 0.6, k), sin(aa) * rr)
				m.scale = Vector3.ONE * (0.4 - 0.25 * k)
				mat.albedo_color.a = sin(k * PI) * 0.5, 0.0, 1.0, 0.5 / s)
		tw.tween_callback(m.queue_free)


## 黄金的指引：脚下一圈淡金色的光环(持有时一直在，层数越多越亮)
func guidance_ring(parent: Node3D, radius: float) -> MeshInstance3D:
	var rim := MeshInstance3D.new()
	rim.mesh = _ring_mesh
	rim.material_override = _emissive(GOLD, 1.6, 0.6)
	rim.scale = Vector3(radius, 0.3, radius)
	rim.position.y = 0.05
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(rim)
	var tw := rim.create_tween().set_loops()
	tw.tween_property(rim, "scale", Vector3(radius * 1.12, 0.3, radius * 1.12), 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(rim, "scale", Vector3(radius, 0.3, radius), 0.8).set_trans(Tween.TRANS_SINE)
	return rim


## 复活：一道金色光柱 + 金色碎光往上飘
func revive_pillar(at: Vector3) -> void:
	pillar(Vector3(at.x, 0.0, at.z), GOLD, 1.0)
	burst(at + Vector3(0, 0.8, 0), GOLD_HOT, 14, 1.8, 0.9, 2.2, 0.8)
	ring(Vector3(at.x, 0.03, at.z), 1.2, GOLD, 0.6, 1.6, 0.2)


# ---------------------------------------------------------------- 灭罪节点：她是唯一的光
const LIGHT_CORE := Color("#fffbea")
const LIGHT_GLOW := Color("#ffc23e")
const LIGHT_HEIGHT := 16.0
const LIGHT_TINT := Color("#f0a020")     # 垫在下面的普通混合金色(浅色地面上也看得出是金光)
const LIGHT_TINT_A := 0.45
## 光柱：一条侧对镜头的竖直光带。金色光晕 + 白热的光芯，两层噪声让光往下流(flow < 0 = 往上流)、光芯轻轻扭动；
## 越往天上越淡，贴地的那一截最亮。grow：dir > 0 时从天上往下长(降临)，dir < 0 时从脚下往上长(她往天上射的细光)
const LIGHT_COL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 core : source_color = vec4(1.0, 0.98, 0.92, 1.0);
uniform vec4 glow : source_color = vec4(1.0, 0.76, 0.24, 1.0);
uniform float height = 16.0;
uniform float pulse = 0.0;
uniform float fade = 1.0;
uniform float grow = 1.0;
uniform float dir = 1.0;
uniform float flow = 7.0;
uniform float base_boost = 0.8;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
void fragment() {
	float x = UV.x * 2.0 - 1.0;
	float h = (1.0 - UV.y) * height;
	float down = smoothstep(height * (1.0 - grow) - 0.2, height * (1.0 - grow) + 0.8, h);
	float up = 1.0 - smoothstep(height * grow - 0.8, height * grow + 0.2, h);
	float vis = dir > 0.0 ? down : up;
	float n = noise(vec2(x * 2.2, h * 0.7 + TIME * flow));
	float n2 = noise(vec2(x * 5.0 + 3.0, h * 1.9 + TIME * flow * 1.7));
	float xc = x + (n - 0.5) * 0.10;
	float c = exp(-pow(xc * 4.5, 2.0));
	float g = exp(-pow(x * 1.7, 2.0)) * (0.55 + 0.55 * n2);
	float top = 1.0 - smoothstep(height * 0.45, height, h);
	float base = 1.0 + base_boost * exp(-h * 1.4);
	ALBEDO = (glow.rgb * g * 1.25 + core.rgb * c * 2.2) * base * (0.8 + 0.45 * pulse);
	ALPHA = clamp((g * 0.5 + c) * top * vis * fade, 0.0, 1.0);
}
"""
## 圣印(灭罪节点：光束脚下 / 天上 / 她脚下 / 她身后的光轮)：外缘双圈 → 一圈慢慢转的经文刻痕(长短不一的短划)→ 内圈 →
## 十二道放射的光芒 → 一颗八角星的轮廓 → 正中一个十字 + 一汪白光；spin = 转速(正负 = 方向)，pulse = 结算时亮一下。
## 叠加的版本发光，普通混合的版本(琥珀色)垫在下面——白地上叠加光看不出来
const LIGHT_DISC_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 col : source_color = vec4(1.0, 0.76, 0.24, 1.0);
uniform vec4 hot : source_color = vec4(1.0, 0.98, 0.92, 1.0);
uniform float pulse = 0.0;
uniform float fade = 1.0;
uniform float spin = 1.0;
uniform float pool_k = 1.0;
float hash(float x) { return fract(sin(x * 91.17) * 43758.5453); }
float band(float r, float c, float w) { return 1.0 - smoothstep(w * 0.5, w * 0.5 + 0.012, abs(r - c)); }
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) { discard; }
	float a = atan(p.y, p.x);
	float T = TIME * spin;
	float rings = band(r, 0.955, 0.03) + band(r, 0.885, 0.014) * 0.8 + band(r, 0.715, 0.016) * 0.9 + band(r, 0.665, 0.008) * 0.6;
	// 经文刻痕：0.74~0.86 之间一圈长短不一的短划，慢慢转
	float ra = a + T * 0.35;
	float segs = 40.0;
	float sid = floor(ra / 6.2831853 * segs);
	float sf = fract(ra / 6.2831853 * segs);
	float len = 0.3 + 0.6 * hash(sid);
	float runes = step(0.18, sf) * step(sf, 0.18 + len * 0.7) * (1.0 - smoothstep(0.0, 0.01, abs(r - 0.80) - 0.035)) * (0.6 + 0.4 * hash(sid + 7.0));
	// 十二道光芒(往反方向慢慢转)
	float rb = a - T * 0.2;
	float rays = pow(abs(cos(rb * 6.0)), 60.0) * smoothstep(0.2, 0.3, r) * (1.0 - smoothstep(0.55, 0.64, r));
	// 八角星的轮廓
	float ss = a + T * 0.12;
	float star_r = 0.5 / (1.0 + 0.32 * pow(abs(cos(ss * 4.0)), 0.6));
	float star = 1.0 - smoothstep(0.0, 0.016, abs(r - star_r));
	// 十字(跟着光芒转)
	vec2 q = vec2(cos(rb) * p.x + sin(rb) * p.y, -sin(rb) * p.x + cos(rb) * p.y);
	float cross = (1.0 - smoothstep(0.012, 0.024, min(abs(q.x), abs(q.y)))) * (1.0 - smoothstep(0.26, 0.34, r)) * 0.9;
	float pool = exp(-r * r * 16.0) * 1.4 * pool_k;
	float wash = (1.0 - r) * 0.08;
	float v = rings * 1.15 + runes + rays * 0.8 + star * 0.85 + cross + wash;
	ALBEDO = (col.rgb * v + hot.rgb * pool) * (0.9 + 0.6 * pulse);
	ALPHA = clamp(v + pool, 0.0, 1.0) * fade;
}
"""
var _light_col_shader: Shader = null
var _light_col_tint: Shader = null
var _light_disc_shader: Shader = null
var _light_disc_tint: Shader = null


## tint = 普通混合的版本(不是叠加)：浅色地面上叠加光几乎看不出来(白上加白)，垫一层淡淡的金色把光的颜色交代出来
func _light_col_mat(core: Color, glow: Color, flow: float, dir: float, tint: bool = false) -> ShaderMaterial:
	if _light_col_shader == null:
		_light_col_shader = Shader.new()
		_light_col_shader.code = LIGHT_COL_SHADER
		_light_col_tint = Shader.new()
		_light_col_tint.code = LIGHT_COL_SHADER.replace("blend_add", "blend_mix")
	var mat := ShaderMaterial.new()
	mat.shader = _light_col_tint if tint else _light_col_shader
	mat.set_shader_parameter("core", core)
	mat.set_shader_parameter("glow", glow)
	mat.set_shader_parameter("height", LIGHT_HEIGHT)
	mat.set_shader_parameter("flow", flow)
	mat.set_shader_parameter("dir", dir)
	mat.set_shader_parameter("grow", 0.0)
	mat.set_shader_parameter("fade", 1.0)          # 先设上：没设过的 uniform 不能 tween(tween_property 会返回 null)
	mat.render_priority = 4
	return mat


func _light_quad(nm: String, width: float, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	var q := QuadMesh.new()
	q.size = Vector2(width, LIGHT_HEIGHT)
	q.center_offset = Vector3(0.0, LIGHT_HEIGHT * 0.5, 0.0)
	m.mesh = q
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


func holy_seal_mat(additive: bool, spin: float = 1.0) -> ShaderMaterial:
	if _light_disc_shader == null:
		_light_disc_shader = Shader.new()
		_light_disc_shader.code = LIGHT_DISC_SHADER
		_light_disc_tint = Shader.new()
		_light_disc_tint.code = LIGHT_DISC_SHADER.replace("blend_add", "blend_mix")
	var mm := ShaderMaterial.new()
	mm.shader = _light_disc_shader if additive else _light_disc_tint
	mm.set_shader_parameter("col", LIGHT_GLOW if additive else LIGHT_TINT)
	mm.set_shader_parameter("hot", LIGHT_CORE if additive else LIGHT_TINT)
	mm.set_shader_parameter("fade", 1.0)
	mm.set_shader_parameter("spin", spin)
	mm.set_shader_parameter("pulse", 0.0)
	mm.render_priority = 3 if additive else 1
	return mm


## 一枚圣印(水平的圆盘，半径 1，叠加 + 普通混合垫底两层)：名字 nm / nm + "Tint"
func holy_seal(parent: Node3D, nm: String, spin: float, tint_a: float = LIGHT_TINT_A) -> Array:
	var mats: Array = []
	for k: int in range(2):
		var disc := MeshInstance3D.new()
		disc.name = nm if k == 0 else nm + "Tint"
		var dq := QuadMesh.new()
		dq.size = Vector2(2.0, 2.0)
		dq.orientation = PlaneMesh.FACE_Y
		disc.mesh = dq
		var mm: ShaderMaterial = holy_seal_mat(k == 0, spin)
		mm.set_shader_parameter("fade", 1.0 if k == 0 else tint_a)
		disc.material_override = mm
		disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		disc.position.y = 0.005 * float(1 - k)
		parent.add_child(disc)
		mats.append(mm)
	return mats


## 灭罪节点的光束：从天上直直落下的光柱(光芯 + 外面一层宽而淡的光晕)、脚下溅射范围的光环、贴地一团柔光、
## 一盏照亮周围的金色灯、光柱里往下飘的光点。每帧用 light_beam_set 摆到光束的位置；刚创建时 0.3 秒从天上长下来(降临)
func light_beam() -> Node3D:
	var root := Node3D.new()
	root.top_level = true
	var cm := _light_col_mat(LIGHT_CORE, LIGHT_GLOW, 7.0, 1.0)
	root.add_child(_light_quad("Col", 1.5, cm))
	var hm := _light_col_mat(Color(0, 0, 0), LIGHT_GLOW * 0.25, 3.0, 1.0)
	root.add_child(_light_quad("Halo", 3.6, hm))
	var tm := _light_col_mat(Color(0, 0, 0), LIGHT_TINT, 3.0, 1.0, true)
	tm.set_shader_parameter("fade", LIGHT_TINT_A)
	tm.render_priority = 2
	root.add_child(_light_quad("Tint", 2.6, tm))
	# 地上的圣印(溅射范围)：降临时从小转着展开
	var ground := Node3D.new()
	ground.name = "Ground"
	ground.position.y = 0.035
	root.add_child(ground)
	var gms: Array = holy_seal(ground, "Disc", 1.0)
	var dm: ShaderMaterial = gms[0]
	dm.set_shader_parameter("fade", 0.0)
	(gms[1] as ShaderMaterial).set_shader_parameter("fade", 0.0)
	create_tween().tween_property(gms[1], "shader_parameter/fade", LIGHT_TINT_A, 0.25 / maxf(0.2, speed_scale)).set_delay(0.25 / maxf(0.2, speed_scale))
	ground.scale = Vector3.ONE * 0.15
	# 天上的圣印：光柱从它中间穿下来(俯视的镜头里是目标上方一大圈慢慢转的光轮)
	var sky := Node3D.new()
	sky.name = "Sky"
	sky.position.y = 3.3
	root.add_child(sky)
	var sms: Array = holy_seal(sky, "Seal", -0.7, 0.25)
	(sms[0] as ShaderMaterial).set_shader_parameter("pool_k", 0.4)
	sky.scale = Vector3.ONE * 0.1
	# 光圈里往上窜的细光丝(净化)
	var st: GPUParticles3D = SoftFX.particles(26, 0.9, SoftFX.ramp([Color(1.0, 0.95, 0.7, 0.0), Color(1.0, 0.9, 0.55, 1.0), Color(1.0, 0.8, 0.3, 0.0)]), 0.09)
	st.name = "Streaks"
	var spm: ParticleProcessMaterial = st.process_material
	spm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	spm.emission_ring_axis = Vector3.UP
	spm.emission_ring_radius = 1.0
	spm.emission_ring_inner_radius = 0.2
	spm.emission_ring_height = 0.05
	spm.direction = Vector3(0.0, 1.0, 0.0)
	spm.spread = 4.0
	spm.initial_velocity_min = 1.6
	spm.initial_velocity_max = 2.8
	spm.gravity = Vector3.ZERO
	spm.scale_min = 0.6
	spm.scale_max = 1.0
	st.position.y = 0.05
	st.draw_pass_1 = SoftFX.quad(1.0)
	st.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 0.05, 0.0))
	root.add_child(st)
	var gl := MeshInstance3D.new()
	gl.name = "Glow"
	gl.mesh = SoftFX.quad(1.0)
	gl.material_override = SoftFX.sprite_mat(LIGHT_GLOW.lerp(LIGHT_CORE, 0.4), 0.9)
	gl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gl.position.y = 0.45
	gl.scale = Vector3.ONE * 1.1
	root.add_child(gl)
	var lamp := OmniLight3D.new()
	lamp.name = "Lamp"
	lamp.light_color = Color("#ffd27a")
	lamp.light_energy = 0.0
	lamp.omni_range = 3.5
	lamp.position.y = 1.4
	lamp.shadow_enabled = false
	root.add_child(lamp)
	var pt: GPUParticles3D = SoftFX.particles(24, 1.1, SoftFX.ramp([Color(1.0, 0.95, 0.7, 0.0), Color(1.0, 0.86, 0.42, 1.0), Color(1.0, 0.8, 0.3, 0.0)]), 0.11)
	pt.name = "Motes"
	var ppm: ParticleProcessMaterial = pt.process_material
	ppm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	ppm.emission_box_extents = Vector3(0.35, 2.5, 0.35)
	ppm.direction = Vector3(0.0, -1.0, 0.0)
	ppm.spread = 8.0
	ppm.initial_velocity_min = 2.0
	ppm.initial_velocity_max = 3.5
	ppm.gravity = Vector3.ZERO
	pt.position.y = 3.0
	root.add_child(pt)
	add_child(root)
	var s: float = maxf(0.2, speed_scale)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(cm, "shader_parameter/grow", 1.0, 0.3 / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(hm, "shader_parameter/grow", 1.0, 0.3 / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(tm, "shader_parameter/grow", 1.0, 0.3 / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(dm, "shader_parameter/fade", 1.0, 0.25 / s).set_delay(0.25 / s)
	tw.tween_property(ground, "scale", Vector3.ONE, 0.45 / s).set_delay(0.22 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(ground, "rotation:y", PI * 0.5, 0.6 / s).set_delay(0.22 / s).set_ease(Tween.EASE_OUT)
	tw.tween_property(sky, "scale", Vector3.ONE, 0.5 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(lamp, "light_energy", 1.0, 0.25 / s).set_delay(0.25 / s)
	tw.chain().tween_callback(root.set_meta.bind("lit", true))
	return root


## 把光束摆到 at(地面)；radius = 现在的溅射半径(照亮长夜会让它越来越大)；pulse = 0..1(每 0.25 秒结算一次时亮一下)
func light_beam_set(root: Node3D, at: Vector3, radius: float, pulse: float) -> void:
	if root == null or not is_instance_valid(root):
		return
	root.global_position = Vector3(at.x, 0.0, at.z)
	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() != null else null
	if cam != null:
		var to: Vector3 = cam.global_position - root.global_position
		var yaw: float = atan2(to.x, to.z)
		for nm: String in ["Col", "Halo", "Tint"]:
			(root.get_node(nm) as Node3D).rotation.y = yaw
	for nm2: String in ["Col", "Halo", "Ground/Disc", "Sky/Seal"]:
		((root.get_node(nm2) as MeshInstance3D).material_override as ShaderMaterial).set_shader_parameter("pulse", pulse)
	for nm3: String in ["Ground/Disc", "Ground/DiscTint"]:
		(root.get_node(nm3) as Node3D).scale = Vector3(radius, 1.0, radius)
	for nm4: String in ["Sky/Seal", "Sky/SealTint"]:
		(root.get_node(nm4) as Node3D).scale = Vector3(radius * 0.75, 1.0, radius * 0.75)
	var stp: ParticleProcessMaterial = (root.get_node("Streaks") as GPUParticles3D).process_material
	stp.emission_ring_radius = radius * 0.95
	stp.emission_ring_inner_radius = radius * 0.2
	(root.get_node("Streaks") as GPUParticles3D).visibility_aabb = AABB(Vector3(-radius - 1.0, -1.0, -radius - 1.0), Vector3(radius * 2.0 + 2.0, 6.0, radius * 2.0 + 2.0))
	# 移动时在地上留一道光痕(每挪 0.35 米落一块，慢慢淡掉)
	var last: Vector3 = root.get_meta("trail_at", root.global_position)
	if root.has_meta("lit") and last.distance_to(root.global_position) > 0.35:
		root.set_meta("trail_at", root.global_position)
		_light_trail(root.global_position, minf(radius * 0.45, 1.1))
	elif not root.has_meta("trail_at"):
		root.set_meta("trail_at", root.global_position)
	(root.get_node("Glow") as Node3D).scale = Vector3.ONE * (1.0 + 0.4 * pulse)
	var lamp: OmniLight3D = root.get_node("Lamp")
	lamp.omni_range = radius + 1.5
	if root.has_meta("lit") and not root.has_meta("ending"):
		lamp.light_energy = 1.0 + 0.6 * pulse


## 光束消失(她被打断 / 倒下 / 战斗结束)：光芯变细、整体往上淡掉，光环收掉
func light_beam_end(root: Node3D) -> void:
	if root == null or not is_instance_valid(root) or root.has_meta("ending"):
		return
	root.set_meta("ending", true)
	var s: float = maxf(0.2, speed_scale)
	var tw: Tween = create_tween().set_parallel(true)
	for nm: String in ["Col", "Halo", "Tint", "Ground/Disc", "Ground/DiscTint", "Sky/Seal", "Sky/SealTint"]:
		var mat: ShaderMaterial = (root.get_node(nm) as MeshInstance3D).material_override
		tw.tween_property(mat, "shader_parameter/fade", 0.0, 0.4 / s)
	tw.tween_property(root.get_node("Sky"), "scale", Vector3.ONE * 1.4, 0.4 / s)
	(root.get_node("Streaks") as GPUParticles3D).emitting = false
	for nm2: String in ["Col", "Halo", "Tint"]:
		tw.tween_property(root.get_node(nm2), "scale", Vector3(0.15, 1.0, 1.0), 0.4 / s).set_ease(Tween.EASE_IN)
	tw.tween_property(root.get_node("Lamp"), "light_energy", 0.0, 0.35 / s)
	tw.tween_property(root.get_node("Glow"), "scale", Vector3.ONE * 0.05, 0.35 / s)
	(root.get_node("Motes") as GPUParticles3D).emitting = false
	tw.chain().tween_interval(0.8 / s)
	tw.chain().tween_callback(root.queue_free)


## 降临：落地那一下的白光 + 一圈冲开到溅射范围的光环 + 溅起的金色光点
func light_descend(at: Vector3, radius: float) -> void:
	soft_flash(at + Vector3(0, 0.5, 0), LIGHT_CORE, 2.8, 0.4, 2.4)
	soft_flash(at + Vector3(0, 3.3, 0), LIGHT_CORE, 2.0, 0.35, 2.0)
	ring(Vector3(at.x, 0.04, at.z), radius, LIGHT_GLOW, 0.5, 1.6, 0.15)
	ring(Vector3(at.x, 0.05, at.z), radius * 1.6, LIGHT_TINT, 0.7, 1.0, 0.3)
	burst(at + Vector3(0, 0.3, 0), GOLD_HOT, 18, 3.0, 0.7, 1.4, 0.6)
	fire_puff(at + Vector3(0, 0.1, 0), Color("#e8dcc0"), 10, 0.5, 2.2, 0.6, 0.3, false)


## 光束每 0.25 秒灼一下中心的主目标：一小撮金色火星 + 身上一闪 + 往上飘的光点
func light_beam_hit(at: Vector3) -> void:
	burst(at, GOLD_HOT, 4, 1.6, 0.45, 1.2, 0.25)
	burst(at, LIGHT_GLOW, 3, 1.0, 0.45, 1.6, 0.3)


## 光束每 0.25 秒结算一次：一圈光环从天上的圣印顺着光柱滑到地上(审判落下)，落地时地上的圣印亮一下
func light_beam_tick(root: Node3D, radius: float) -> void:
	if root == null or not is_instance_valid(root) or root.has_meta("ending"):
		return
	var s: float = maxf(0.2, speed_scale)
	var m := MeshInstance3D.new()
	m.mesh = _ring_mesh
	var rm: StandardMaterial3D = _emissive(LIGHT_CORE, 2.4, 0.85).duplicate() as StandardMaterial3D
	m.material_override = rm
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(m)
	m.position = Vector3(0.0, 3.2, 0.0)
	m.scale = Vector3(0.55, 0.05, 0.55)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(m, "position:y", 0.08, 0.24 / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(m, "scale", Vector3(0.8, 0.05, 0.8), 0.24 / s)
	tw.chain().tween_property(m, "scale", Vector3(radius * 0.9, 0.05, radius * 0.9), 0.18 / s).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(rm, "albedo_color:a", 0.0, 0.18 / s)
	tw.chain().tween_callback(m.queue_free)


## 光束挪过的地方：一块金色的光痕(普通混合，白地上也看得见)，慢慢淡掉
func _light_trail(at: Vector3, r: float) -> void:
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(2.0, 2.0)
	q.orientation = PlaneMesh.FACE_Y
	m.mesh = q
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = SoftFX._texture()
	mat.albedo_color = Color(LIGHT_TINT.r, LIGHT_TINT.g, LIGHT_TINT.b, 0.42)
	mat.disable_fog = true
	mat.render_priority = 0
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	m.global_position = Vector3(at.x, 0.025, at.z)
	m.scale = Vector3(r, 1.0, r)
	var s: float = maxf(0.2, speed_scale)
	var tw: Tween = create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 1.6 / s).set_ease(Tween.EASE_IN)
	tw.tween_callback(m.queue_free)


## 她手里的光之心往天上射的一道细光(从球心往上长，光往上流)，球外一团柔光
func light_ray() -> Node3D:
	var root := Node3D.new()
	root.top_level = true
	var cm := _light_col_mat(LIGHT_CORE, LIGHT_GLOW, -9.0, -1.0)
	cm.set_shader_parameter("base_boost", 0.3)
	root.add_child(_light_quad("Col", 0.42, cm))
	var gl := MeshInstance3D.new()
	gl.name = "Glow"
	gl.mesh = SoftFX.quad(1.0)
	gl.material_override = SoftFX.sprite_mat(LIGHT_GLOW.lerp(LIGHT_CORE, 0.5), 1.2)
	gl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gl.scale = Vector3.ONE * 0.5
	root.add_child(gl)
	add_child(root)
	var s: float = maxf(0.2, speed_scale)
	create_tween().tween_property(cm, "shader_parameter/grow", 1.0, 0.35 / s).set_ease(Tween.EASE_OUT)
	return root


func light_ray_set(root: Node3D, from: Vector3, pulse: float) -> void:
	if root == null or not is_instance_valid(root):
		return
	root.global_position = from
	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() != null else null
	if cam != null:
		var to: Vector3 = cam.global_position - from
		(root.get_node("Col") as Node3D).rotation.y = atan2(to.x, to.z)
	((root.get_node("Col") as MeshInstance3D).material_override as ShaderMaterial).set_shader_parameter("pulse", pulse)
	(root.get_node("Glow") as Node3D).scale = Vector3.ONE * (0.45 + 0.15 * pulse)


func light_ray_end(root: Node3D) -> void:
	if root == null or not is_instance_valid(root):
		return
	var s: float = maxf(0.2, speed_scale)
	var mat: ShaderMaterial = (root.get_node("Col") as MeshInstance3D).material_override
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(mat, "shader_parameter/fade", 0.0, 0.3 / s)
	tw.tween_property(root.get_node("Glow"), "scale", Vector3.ONE * 0.02, 0.3 / s)
	tw.chain().tween_callback(root.queue_free)


## 光之心的斩杀：目标身上一个金色的光十字(竖长横短)，一道光柱冲起，往上飘散的光点
func absolve_cross(at: Vector3) -> void:
	var s: float = maxf(0.2, speed_scale)
	for bar: Array in [[0.32, 2.6, 0.0], [1.5, 0.3, 0.35]]:
		var m := MeshInstance3D.new()
		m.mesh = SoftFX.quad(1.0)
		var mat: StandardMaterial3D = SoftFX.sprite_mat(LIGHT_CORE, 2.6)
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		m.global_position = at + Vector3(0.0, float(bar[2]), 0.0)
		m.scale = Vector3(float(bar[0]) * 0.3, float(bar[1]) * 0.3, 1.0)
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(m, "scale", Vector3(float(bar[0]), float(bar[1]), 1.0), 0.12 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.7 / s).set_ease(Tween.EASE_IN).set_delay(0.2 / s)
		tw.chain().tween_callback(m.queue_free)
	pillar(Vector3(at.x, 0.0, at.z), GOLD, 0.8)
	soft_flash(at, LIGHT_CORE, 1.6, 0.3, 2.0)
	burst(at, GOLD_HOT, 18, 1.6, 0.8, 2.6, 0.9)
	ring(Vector3(at.x, 0.04, at.z), 1.1, LIGHT_GLOW, 0.5, 1.4, 0.2)


## 照亮长夜(造成击杀)：光束脚下的光环往外一冲
func light_boost(at: Vector3, radius: float) -> void:
	ring(Vector3(at.x, 0.05, at.z), radius * 1.05, GOLD_HOT, 0.45, 1.8, 0.6)
	burst(at + Vector3(0, 0.6, 0), GOLD_HOT, 8, 2.0, 0.6, 1.8, 0.5)


# ---------------------------------------------------------------- 屏息节点：瞄准眉心 / 一石二鸟
const SNIPE_CORE := Color("#fff6d8")
const SNIPE_GLOW := Color("#ffb347")
const LASER_CORE := Color("#ffd6cc")
const LASER_GLOW := Color("#ff3424")


func _band_mat(core: Color, glow: Color) -> ShaderMaterial:
	if _beam_shader == null:
		_beam_shader = Shader.new()
		_beam_shader.code = BEAM_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _beam_shader
	mat.set_shader_parameter("core", core)
	mat.set_shader_parameter("glow", glow)
	mat.set_shader_parameter("pulse", 1.0)
	mat.set_shader_parameter("fade", 1.0)
	mat.render_priority = 4
	return mat


## 把一条光带(QuadMesh，本地 X = 宽、Y = 长)摆到 from → to，宽 w 米，侧对镜头
func _orient_band(m: MeshInstance3D, from: Vector3, to: Vector3, w: float) -> void:
	var d: Vector3 = to - from
	if d.length() < 0.02:
		m.visible = false
		return
	m.visible = true
	var mid: Vector3 = (from + to) * 0.5
	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() != null else null
	var view: Vector3 = (cam.global_position - mid) if cam != null else Vector3(0, 1, 1)
	var side: Vector3 = d.cross(view)
	if side.length() < 1e-4:
		side = d.cross(Vector3.UP)
	side = side.normalized()
	m.global_transform = Transform3D(Basis(side * w, d, side.cross(d.normalized())), mid)
	(m.material_override as ShaderMaterial).set_shader_parameter("len", d.length())


## 一闪而过的弹道光(金色光带)：width 米宽，life 秒淡掉
func tracer(from: Vector3, to: Vector3, width: float, life: float, core: Color = SNIPE_CORE, glow: Color = SNIPE_GLOW) -> void:
	var m := MeshInstance3D.new()
	m.mesh = QuadMesh.new()
	var mat := _band_mat(core, glow)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.top_level = true
	add_child(m)
	_orient_band(m, from, to, width)
	var tw: Tween = create_tween()
	tw.tween_property(mat, "shader_parameter/fade", 0.0, life / maxf(0.2, speed_scale)).set_ease(Tween.EASE_IN)
	tw.tween_callback(m.queue_free)


## 瞄准眉心：枪口到目标的一道细红激光(越瞄越亮)，目标脚下一个慢慢收紧、转着的红色准星(两圈 + 四根刻线)
func sniper_aim() -> Node3D:
	var root := Node3D.new()
	root.top_level = true
	var laser := MeshInstance3D.new()
	laser.name = "Laser"
	laser.mesh = QuadMesh.new()
	laser.material_override = _band_mat(LASER_CORE, LASER_GLOW)
	laser.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	laser.top_level = true
	root.add_child(laser)
	var ret := Node3D.new()
	ret.name = "Reticle"
	ret.top_level = true
	root.add_child(ret)
	for rr: Array in [[1.0, 0.04], [0.55, 0.025]]:
		var rm := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = float(rr[0]) - float(rr[1])
		tm.outer_radius = float(rr[0])
		tm.rings = 40
		tm.ring_segments = 4
		rm.mesh = tm
		rm.scale = Vector3(1.0, 0.15, 1.0)
		rm.material_override = _emissive(LASER_GLOW, 2.6, 0.85)
		rm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ret.add_child(rm)
	for i in range(4):
		var a: float = TAU * float(i) / 4.0
		var bm := BoxMesh.new()
		bm.size = Vector3(0.05, 0.01, 0.42)
		var tk := MeshInstance3D.new()
		tk.mesh = bm
		tk.material_override = _emissive(LASER_CORE.lerp(LASER_GLOW, 0.4), 2.8, 0.9)
		tk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tk.position = Vector3(sin(a), 0.0, cos(a)) * 1.15
		tk.rotation.y = a
		ret.add_child(tk)
	# 瞄准镜的反光：镜片上一颗蓝白的十字星芒(横竖两道拉长的光 + 一团光晕)，瞄得越久越亮，瞄满了一下一下地闪
	var gl := Node3D.new()
	gl.name = "Glint"
	gl.top_level = true
	gl.visible = false
	root.add_child(gl)
	for gs: Vector3 in [Vector3(0.22, 0.22, 1.0), Vector3(0.9, 0.035, 1.0), Vector3(0.035, 0.7, 1.0)]:
		var gm := MeshInstance3D.new()
		gm.mesh = SoftFX.quad()
		gm.material_override = SoftFX.sprite_mat(Color("#7cc6ff"), 2.6)
		gm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		gm.scale = gs
		gm.set_meta("s0", gs)
		gl.add_child(gm)
	add_child(root)
	return root


## k = 0..1 瞄准的进度(瞄得越久激光越亮越粗、准星越收越紧)；scope = 瞄准镜镜片的位置(反光的星芒，INF = 不画)
func sniper_aim_set(root: Node3D, from: Vector3, to: Vector3, ground: Vector3, k: float, spin: float, scope: Vector3 = Vector3.INF) -> void:
	if root == null or not is_instance_valid(root):
		return
	var laser: MeshInstance3D = root.get_node("Laser")
	_orient_band(laser, from, to, 0.05 + 0.07 * k)
	(laser.material_override as ShaderMaterial).set_shader_parameter("fade", 0.25 + 0.6 * k)
	(laser.material_override as ShaderMaterial).set_shader_parameter("pulse", k)
	var ret: Node3D = root.get_node("Reticle")
	ret.global_position = Vector3(ground.x, 0.04, ground.z)
	ret.scale = Vector3.ONE * lerpf(1.25, 0.5, k)
	ret.rotation.y = spin
	var gl: Node3D = root.get_node_or_null("Glint")
	if gl != null:
		gl.visible = scope != Vector3.INF
		if gl.visible:
			gl.global_position = scope
			# 瞄满以后每 0.8 秒闪一下(星芒一下子拉长)
			var flash: float = pow(maxf(0.0, sin(spin * 6.5)), 8.0) if k >= 1.0 else 0.0
			var g: float = (0.3 + 0.7 * k) * (1.0 + 0.9 * flash)
			for gm: Node in gl.get_children():
				var s0: Vector3 = (gm as Node3D).get_meta("s0")
				(gm as Node3D).scale = Vector3(s0.x * g * (1.0 + 0.6 * flash * float(s0.x > 0.5)), s0.y * g, 1.0)


func sniper_aim_end(root: Node3D) -> void:
	if root != null and is_instance_valid(root):
		root.queue_free()


## 瞄准过的一枪：枪口一团火光 + 一道金色弹道光(瞄得越久越粗)，命中点一圈冲击
func sniper_shot(from: Vector3, to: Vector3, big: float) -> void:
	var k: float = clampf(big, 0.0, 1.0)
	if k >= 0.4:
		_muzzle_blast(from, (to - from).normalized(), k)
	tracer(from, to, 0.12 + 0.22 * k, 0.28 + 0.2 * k)
	soft_flash(from, SNIPE_CORE, 0.6 + 0.6 * k, 0.18, 2.2)
	burst(from, Color("#ffd98a"), 6 + int(6.0 * k), 2.0, 0.6, 0.3, 0.2)
	soft_flash(to, SNIPE_GLOW.lerp(SNIPE_CORE, 0.5), 0.5 + 0.7 * k, 0.22, 2.0)
	burst(to, SNIPE_CORE, 4 + int(8.0 * k), 2.2, 0.5, 0.8, 0.3)


## 瞄得久的一枪：枪口一圈垂直于枪管往外扩的冲击环(两圈)+ 枪口下方地面被气浪掀起一圈尘土 + 一团慢慢散的枪口烟
func _muzzle_blast(at: Vector3, dir: Vector3, k: float) -> void:
	var s: float = maxf(0.2, speed_scale)
	for i in range(2):
		var m := MeshInstance3D.new()
		m.mesh = _ring_mesh
		var rm: StandardMaterial3D = _emissive(SNIPE_CORE, 2.2, 0.8).duplicate() as StandardMaterial3D
		m.material_override = rm
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		var up: Vector3 = Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT
		var bx: Vector3 = up.cross(dir).normalized()
		m.global_transform = Transform3D(Basis(bx, dir, bx.cross(dir)), at + dir * (0.08 + 0.12 * float(i)))
		var r: float = (0.35 + 0.25 * k) * (1.0 - 0.3 * float(i))
		m.scale = Vector3(0.05, 0.08, 0.05)
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(m, "scale", Vector3(r, 0.06, r), 0.22 / s).set_delay(0.03 * float(i) / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(rm, "albedo_color:a", 0.0, 0.22 / s).set_delay((0.06 + 0.03 * float(i)) / s)
		tw.chain().tween_callback(m.queue_free)
	var ground := Vector3(at.x, 0.03, at.z) + Vector3(dir.x, 0.0, dir.z) * 0.15
	ring(ground, 0.9 + 0.5 * k, Color("#d8cbb4"), 0.45, 1.2, 0.2)
	fire_puff(ground + Vector3(0.0, 0.08, 0.0), Color("#b8ab98"), 8, 0.4, 1.6, 0.6, 0.4, false)
	fire_puff(at + dir * 0.1, Color("#8a8580"), 5, 0.3, 0.5, 0.9, 0.6, false)


## 拉栓退壳：一枚黄铜弹壳从抛壳口往右上翻着跳出去，落地弹一下、滚一点，过一会儿淡掉。right = 枪的右侧
func shell_casing(at: Vector3, right: Vector3) -> void:
	var s: float = maxf(0.2, speed_scale)
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.016, 0.016, 0.05)
	m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#d9a43a")
	mat.metallic = 0.7
	mat.roughness = 0.3
	mat.emission_enabled = true
	mat.emission = Color("#6a4a10")
	m.material_override = mat
	add_child(m)
	m.global_position = at
	var v0: Vector3 = (right.normalized() * 1.3 + Vector3(0.0, 1.9, 0.0) + Vector3(randf_range(-0.2, 0.2), 0.0, randf_range(-0.2, 0.2)))
	var spin := Vector3(randf_range(14.0, 20.0), randf_range(-6.0, 6.0), randf_range(8.0, 14.0))
	var land: Vector3 = at + Vector3(v0.x, 0.0, v0.z) * 0.6
	land.y = 0.012
	var peak: float = at.y + 0.18
	var tw: Tween = create_tween()
	tw.tween_method(func(u: float) -> void:
		if not is_instance_valid(m):
			return
		var p: Vector3 = at.lerp(land, u)
		p.y = lerpf(at.y, land.y, u) + 4.0 * (peak - lerpf(at.y, land.y, 0.5)) * u * (1.0 - u)
		m.global_position = p
		m.rotation = spin * u * 0.5, 0.0, 1.0, 0.42 / s)
	# 落地弹一下、滚开一点
	var bounce: Vector3 = land + Vector3(v0.x, 0.0, v0.z) * 0.18
	tw.tween_method(func(u: float) -> void:
		if not is_instance_valid(m):
			return
		var p2: Vector3 = land.lerp(bounce, u)
		p2.y = 0.012 + 0.06 * sin(PI * u)
		m.global_position = p2
		m.rotation.y += 0.2, 0.0, 1.0, 0.22 / s)
	tw.tween_interval(0.9 / s)
	tw.tween_property(m, "scale", Vector3.ONE * 0.01, 0.3 / s)
	tw.tween_callback(m.queue_free)


## 一石二鸟：子弹从刚倒下的那个敌人身上弹出去，一道细一点的弹道光 + 两头的火星
func ricochet(from: Vector3, to: Vector3) -> void:
	tracer(from, to, 0.1, 0.3)
	burst(from, SNIPE_CORE, 6, 2.4, 0.45, 0.6, 0.25)
	burst(to, SNIPE_GLOW, 5, 1.8, 0.45, 0.8, 0.25)
	soft_flash(to, SNIPE_CORE, 0.6, 0.18, 2.0)


# ---------------------------------------------------------------- 止息节点：画上句点 / 标定
const MARK_COL := Color("#ffb03a")
const MARK_HOT := Color("#ff4a2a")


## 【标定】：被标定的敌人脚下一个金红色的锁定准星(两圈 + 四根刻线)，3 秒里从大收到小(收紧 = 远程友军的免费弹道要来了)
func mark_ring() -> Node3D:
	var root := Node3D.new()
	root.top_level = true
	for rr: Array in [[1.0, 0.05], [0.62, 0.03]]:
		var rm := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = float(rr[0]) - float(rr[1])
		tm.outer_radius = float(rr[0])
		tm.rings = 40
		tm.ring_segments = 4
		rm.mesh = tm
		rm.scale = Vector3(1.0, 0.15, 1.0)
		rm.material_override = _emissive(MARK_COL, 2.6, 0.85)
		rm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(rm)
	for i in range(4):
		var a: float = TAU * float(i) / 4.0 + PI * 0.25
		var bm := BoxMesh.new()
		bm.size = Vector3(0.06, 0.012, 0.36)
		var tk := MeshInstance3D.new()
		tk.mesh = bm
		tk.material_override = _emissive(MARK_HOT, 2.8, 0.9)
		tk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tk.position = Vector3(sin(a), 0.0, cos(a)) * 0.82
		tk.rotation.y = a
		root.add_child(tk)
	add_child(root)
	return root


func mark_ring_set(root: Node3D, at: Vector3, size: float, k: float, spin: float) -> void:
	if root == null or not is_instance_valid(root):
		return
	root.global_position = Vector3(at.x, 0.05, at.z)
	root.scale = Vector3.ONE * size * lerpf(1.25, 0.6, k)
	root.rotation.y = spin


func mark_ring_end(root: Node3D, pop: bool) -> void:
	if root == null or not is_instance_valid(root):
		return
	if pop:
		ring(Vector3(root.global_position.x, 0.06, root.global_position.z), 0.9, MARK_COL, 0.35, 1.4, 0.4)
	root.queue_free()


## 突进的冲刺：空翻扫射时一路的枪口火光(按时间点各一团)，滑铲时贴地一道擦痕 + 匕首划过的那一下
func lunge_dust(from: Vector3, to: Vector3) -> void:
	burst(Vector3(from.x, 0.1, from.z), Color("#b9a58c"), 6, 1.8, 1.2, 0.5, 0.4, false)
	burst(Vector3(to.x, 0.1, to.z), Color("#b9a58c"), 8, 2.0, 1.3, 0.6, 0.45, false)


func smg_burst(at: Vector3, dir: Vector3) -> void:
	soft_flash(at, Color("#ffd98a"), 0.35, 0.1, 2.0)
	burst(at + dir * 0.1, Color("#ffd98a"), 3, 1.6, 0.35, 0.2, 0.12)


func knife_slash(at: Vector3, dir: Vector3) -> void:
	slash(at, dir, Color("#e8eef5"), 0.8)


# ---------------------------------------------------------------- 踏影节点：逆光 / 墨刃
const SHADOW_INK := Color("#0c1016")
const SHADOW_TEAL := Color("#3fe0e8")


## 影子：地上一滩扩开又收回的黑影(普通混合，压暗地面)+ 往上翻的黑烟 + 几点青色碎光
func shadow_pool(at: Vector3, size: float = 1.0) -> void:
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(2.0, 2.0)
	q.orientation = PlaneMesh.FACE_Y
	m.mesh = q
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = SoftFX._texture()
	mat.albedo_color = Color(SHADOW_INK.r, SHADOW_INK.g, SHADOW_INK.b, 0.0)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	m.global_position = Vector3(at.x, 0.03, at.z)
	m.scale = Vector3.ONE * 0.3 * size
	var s: float = maxf(0.2, speed_scale)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(m, "scale", Vector3.ONE * 0.9 * size, 0.18 / s).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.85, 0.15 / s)
	tw.chain().tween_interval(0.25 / s)
	tw.chain().tween_property(mat, "albedo_color:a", 0.0, 0.35 / s)
	tw.chain().tween_callback(m.queue_free)
	burst(Vector3(at.x, 0.2, at.z), SHADOW_INK, 10, 1.4, 1.1, 1.6, 0.6, false)
	burst(Vector3(at.x, 0.4, at.z), SHADOW_TEAL, 5, 1.2, 0.4, 1.4, 0.4)


## 沉进影子：原地留下一个漆黑的残影，往地下沉下去、淡掉
func shadow_sink(model: Node3D, at: Vector3) -> void:
	shadow_pool(at)
	if model == null or not is_instance_valid(model):
		return
	var g: Node3D = model.duplicate(0) as Node3D
	for c: Node in g.find_children("*", "AnimationPlayer", true, false):
		c.free()
	g.top_level = true
	add_child(g)
	g.global_transform = model.global_transform
	var src_sk: Array[Node] = model.find_children("*", "Skeleton3D", true, false)
	var dst_sk: Array[Node] = g.find_children("*", "Skeleton3D", true, false)
	if not src_sk.is_empty() and not dst_sk.is_empty():
		var a0 := src_sk[0] as Skeleton3D
		var b0 := dst_sk[0] as Skeleton3D
		for bi in range(a0.get_bone_count()):
			b0.set_bone_pose_position(bi, a0.get_bone_pose_position(bi))
			b0.set_bone_pose_rotation(bi, a0.get_bone_pose_rotation(bi))
			b0.set_bone_pose_scale(bi, a0.get_bone_pose_scale(bi))
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.03, 0.05, 0.08, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for n: Node in g.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var s: float = maxf(0.2, speed_scale)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(g, "global_position:y", g.global_position.y - 1.3, 0.35 / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.35 / s).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(g.queue_free)


## 墨刃：一道墨色的新月剑气(墨黑的弧 + 青色的刃口)从他身上飞向目标、边飞边微微转，
## 命中处溅开一滩墨(地上的墨渍 + 黑色墨点)+ 一个青色的交叉斩光
func ink_blade(from: Vector3, to: Vector3) -> void:
	var s: float = maxf(0.2, speed_scale)
	var d: Vector3 = to - from
	var dist: float = d.length()
	if dist < 0.1:
		return
	var dir: Vector3 = d / dist
	var flat := Vector3(dir.x, 0.0, dir.z).normalized() if Vector3(dir.x, 0.0, dir.z).length() > 0.01 else Vector3(0, 0, 1)
	var root := Node3D.new()
	add_child(root)
	var span: float = deg_to_rad(110.0)
	for layer: Array in [[0.62, 0.18, false], [0.66, 0.06, true]]:
		var m := MeshInstance3D.new()
		m.mesh = _crescent(float(layer[0]), span, float(layer[1]), 20)
		if bool(layer[2]):
			var em: ShaderMaterial = _cut_mat(Color("#bff9ff"), SHADOW_TEAL, 2.4)
			em.set_shader_parameter("fade", 1.0)
			em.set_shader_parameter("head", 1.0)
			m.material_override = em
		else:
			var dm := StandardMaterial3D.new()
			dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			dm.albedo_color = Color(SHADOW_INK.r, SHADOW_INK.g, SHADOW_INK.b, 0.92)
			dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			dm.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.material_override = dm
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(m)
	# 竖着的新月(弧开口朝后)，朝飞行方向
	root.global_transform = Transform3D(_cut_basis(flat, flat.cross(Vector3.UP).normalized(), 1.0), from)
	var basis0: Basis = root.global_transform.basis
	var tw: Tween = create_tween()
	tw.tween_method(func(k: float) -> void:
		if is_instance_valid(root):
			root.global_transform = Transform3D(basis0.rotated(flat, sin(k * PI) * 0.4), from.lerp(to, k))
			if randf() < 0.6:
				burst(root.global_position, SHADOW_INK, 1, 0.6, 0.5, 0.3, 0.3, false), 0.0, 1.0, clampf(dist / 14.0, 0.12, 0.3) / s)
	tw.tween_callback(func() -> void:
		root.queue_free()
		_ink_splat(Vector3(to.x, 0.0, to.z), 0.55)
		burst(to, SHADOW_INK, 10, 2.2, 0.6, 0.6, 0.45, false)
		burst(to, SHADOW_TEAL, 5, 1.8, 0.4, 0.8, 0.3)
		slash(to, flat.rotated(Vector3.UP, 0.6), Color("#5fe6ee"), 1.0)
		slash(to, flat.rotated(Vector3.UP, -0.6), Color("#5fe6ee"), 1.0)
		soft_flash(to, SHADOW_TEAL, 0.7, 0.18, 2.0))


## 地上溅开的一滩墨渍(普通混合的墨黑，边上几个小墨点)，慢慢淡掉
func _ink_splat(at: Vector3, r: float) -> void:
	var s: float = maxf(0.2, speed_scale)
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(2.0, 2.0)
	q.orientation = PlaneMesh.FACE_Y
	m.mesh = q
	var mat: ShaderMaterial = SoftFX.splat_mat()
	mat.set_shader_parameter("col", Color(SHADOW_INK.r, SHADOW_INK.g, SHADOW_INK.b, 0.85))
	mat.set_shader_parameter("wet", Color("#1c2a33"))
	mat.set_shader_parameter("sheen", Vector3(0.04, 0.22, 0.26))
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	m.global_position = Vector3(at.x, 0.022, at.z)
	m.rotation.y = randf() * TAU
	m.scale = Vector3.ONE * r * 0.4
	var tw: Tween = create_tween()
	tw.tween_property(m, "scale", Vector3.ONE * r, 0.12 / s).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.8 / s)
	tw.tween_method(func(a: float) -> void: mat.set_shader_parameter("fade", a), 1.0, 0.0, 0.8 / s)
	tw.tween_callback(m.queue_free)


## 逆光的路：一串墨渍顺着地面从起点窜到终点(影子在地上一路滑过去)+ 一道贴地的青色细光
func shadow_dash(from: Vector3, to: Vector3) -> void:
	var s: float = maxf(0.2, speed_scale)
	var d: Vector3 = Vector3(to.x - from.x, 0.0, to.z - from.z)
	var dist: float = d.length()
	if dist < 0.2:
		return
	var n: int = clampi(int(dist / 0.45), 2, 18)
	for i in range(n + 1):
		var k: float = float(i) / float(n)
		var p: Vector3 = from.lerp(to, k) + d.normalized().cross(Vector3.UP) * sin(k * PI * 2.0) * 0.12
		get_tree().create_timer(k * 0.22 / s).timeout.connect(_ink_blot.bind(Vector3(p.x, 0.0, p.z), lerpf(0.35, 0.5, sin(k * PI))))
	var a := Vector3(from.x, 0.08, from.z)
	var b := Vector3(to.x, 0.08, to.z)
	var trail: LightningArc = LightningArc.create(self, a, b, 0.22, 0.3, 0.045, 4)
	trail.cols = [SHADOW_INK, SHADOW_TEAL, Color("#c8fbff")]
	trail._head.material_override = SoftFX.sprite_mat(SHADOW_TEAL, 2.6)


func _ink_blot(at: Vector3, r: float) -> void:
	var s: float = maxf(0.2, speed_scale)
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(2.0, 2.0)
	q.orientation = PlaneMesh.FACE_Y
	m.mesh = q
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = SoftFX._texture()
	mat.albedo_color = Color(SHADOW_INK.r, SHADOW_INK.g, SHADOW_INK.b, 0.9)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	m.global_position = Vector3(at.x, 0.024, at.z)
	m.scale = Vector3.ONE * r
	var tw: Tween = create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.7 / s).set_delay(0.35 / s)
	tw.tween_callback(m.queue_free)
	if randf() < 0.5:
		burst(at + Vector3(0, 0.1, 0), SHADOW_INK, 2, 0.8, 0.5, 0.8, 0.35, false)


## 逆光：从影子里升起来时，身后一下子亮起一团青白的逆光(他整个人成了剪影)：一大团青白柔光 + 一圈光环 + 往外迸的青色碎光，
## 脚下一滩大墨渍、墨点往上溅；at = 他的脚下，h = 身高
func backlight_flare(at: Vector3, h: float) -> void:
	var s: float = maxf(0.2, speed_scale)
	var chest: Vector3 = at + Vector3(0, h * 0.6, 0)
	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() != null else null
	var behind: Vector3 = chest
	if cam != null:
		var to_cam: Vector3 = cam.global_position - chest
		behind = chest - Vector3(to_cam.x, 0.0, to_cam.z).normalized() * 0.35
	soft_flash(behind, Color("#e8fdff"), 2.4, 0.35, 2.6)
	soft_flash(behind, SHADOW_TEAL, 1.6, 0.5, 2.0)
	ring(Vector3(at.x, 0.05, at.z), 1.2, SHADOW_TEAL, 0.4, 1.6, 0.2)
	burst(chest, SHADOW_TEAL, 12, 3.0, 0.5, 1.0, 0.4)
	_ink_splat(at, 0.85)
	burst(at + Vector3(0, 0.15, 0), SHADOW_INK, 14, 2.4, 0.9, 1.6, 0.6, false)
	# 几道往外放射的逆光光芒(细长的青白光条，竖在他身后)
	for i in range(6):
		var a: float = TAU * float(i) / 6.0 + randf_range(-0.2, 0.2)
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.05, 1.0, 0.02)
		m.mesh = bm
		var mat: StandardMaterial3D = _emissive(Color("#c8fbff"), 2.6, 0.85).duplicate() as StandardMaterial3D
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		var basis := Basis.IDENTITY
		if cam != null:
			var fwd: Vector3 = (cam.global_position - behind).normalized()
			var right: Vector3 = Vector3.UP.cross(fwd).normalized()
			var up: Vector3 = fwd.cross(right).normalized()
			var rd: Vector3 = (right * cos(a) + up * sin(a)).normalized()
			basis = Basis(rd.cross(fwd).normalized(), rd, fwd)
		m.global_transform = Transform3D(basis, behind)
		m.scale = Vector3(1.0, 0.2, 1.0)
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_method(func(k: float) -> void:
			if is_instance_valid(m):
				m.scale = Vector3(1.0 - 0.6 * k, 0.3 + 1.4 * k, 1.0)
				m.global_position = behind + m.global_transform.basis.y.normalized() * (0.25 + 0.55 * k), 0.0, 1.0, 0.3 / s).set_ease(Tween.EASE_OUT)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.3 / s).set_delay(0.08 / s)
		tw.chain().tween_callback(m.queue_free)


## 凝暗(层数 1~3)：身上一直往上冒的黑烟 + 青色碎光(挂在视图上)；shadow_aura_set 按层数调浓度，0 = 停
func shadow_aura(parent: Node3D, h: float) -> Node3D:
	var root := Node3D.new()
	root.name = "ShadowAura"
	parent.add_child(root)
	var smoke: GPUParticles3D = SoftFX.particles(16, 1.1, SoftFX.ramp([Color(0.02, 0.03, 0.05, 0.0), Color(0.03, 0.05, 0.07, 0.75), Color(0.05, 0.1, 0.12, 0.0)]), 0.32, false)
	smoke.name = "Smoke"
	var sp: ParticleProcessMaterial = smoke.process_material
	sp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	sp.emission_box_extents = Vector3(0.22, h * 0.4, 0.22)
	sp.direction = Vector3(0, 1, 0)
	sp.spread = 15.0
	sp.initial_velocity_min = 0.4
	sp.initial_velocity_max = 0.9
	sp.gravity = Vector3(0, 0.4, 0)
	smoke.position.y = h * 0.4
	root.add_child(smoke)
	var motes: GPUParticles3D = SoftFX.particles(10, 0.9, SoftFX.ramp([Color(0.25, 0.9, 0.95, 0.0), Color(0.4, 1.0, 1.0, 1.0), Color(0.2, 0.8, 0.9, 0.0)]), 0.07)
	motes.name = "Motes"
	var mp: ParticleProcessMaterial = motes.process_material
	mp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mp.emission_box_extents = Vector3(0.28, h * 0.45, 0.28)
	mp.direction = Vector3(0, 1, 0)
	mp.spread = 30.0
	mp.initial_velocity_min = 0.3
	mp.initial_velocity_max = 0.8
	mp.gravity = Vector3.ZERO
	motes.position.y = h * 0.45
	root.add_child(motes)
	shadow_aura_set(root, 0.0)
	return root


func shadow_aura_set(root: Node3D, k: float) -> void:
	if root == null or not is_instance_valid(root):
		return
	for nm: String in ["Smoke", "Motes"]:
		var p: GPUParticles3D = root.get_node(nm)
		p.emitting = k > 0.01
		p.amount_ratio = clampf(0.35 + 0.65 * k, 0.0, 1.0)


## 诛影(层数 1~3)：剑上缠着青黑的影火——刃上往上冒的黑烟(普通混合)+ 青色的火苗(叠加)；挂在武器骨上(BoneAttachment)
## blade = [刃根, 刃尖](体素，武器局部 y)；shadow_blade_set 按层数调火势，0 = 灭
func shadow_blade(view: UnitView, blade: Array) -> Node3D:
	var sk: Skeleton3D = UnitSkin.skeleton_of(view.model)
	if sk == null or sk.find_bone("Bow") < 0:
		return null
	var att := BoneAttachment3D.new()
	att.bone_name = "Bow"
	att.name = "ShadowBlade"
	sk.add_child(att)
	var y0: float = float(blade[0]) * 0.0125
	var y1: float = float(blade[1]) * 0.0125
	var holder := Node3D.new()
	holder.name = "H"
	holder.position = Vector3(0.0, (y0 + y1) * 0.5, 0.0)
	att.add_child(holder)
	var half: float = (y1 - y0) * 0.5
	var smoke: GPUParticles3D = SoftFX.particles(18, 0.55, SoftFX.ramp([Color(0.02, 0.03, 0.05, 0.0), Color(0.02, 0.04, 0.06, 0.85), Color(0.04, 0.08, 0.1, 0.0)]), 0.12, false)
	smoke.name = "Smoke"
	var flame: GPUParticles3D = SoftFX.particles(22, 0.35, SoftFX.ramp([Color(0.6, 1.0, 1.0, 0.0), Color(0.3, 0.95, 1.0, 1.0), Color(0.05, 0.4, 0.5, 0.0)]), 0.08)
	flame.name = "Flame"
	for p: GPUParticles3D in [smoke, flame]:
		var pm: ParticleProcessMaterial = p.process_material
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(0.02, half, 0.025)
		pm.direction = Vector3(0, 1, 0)
		pm.spread = 20.0
		pm.initial_velocity_min = 0.3
		pm.initial_velocity_max = 0.7
		pm.gravity = Vector3(0, 1.2, 0)
		p.visibility_aabb = AABB(Vector3(-1, -1, -1), Vector3(2, 3, 2))
		holder.add_child(p)
	shadow_blade_set(att, 0.0)
	return att


func shadow_blade_set(att: Node3D, k: float) -> void:
	if att == null or not is_instance_valid(att):
		return
	for nm: String in ["H/Smoke", "H/Flame"]:
		var p: GPUParticles3D = att.get_node(nm)
		p.emitting = k > 0.01
		p.amount_ratio = clampf(0.3 + 0.7 * k, 0.0, 1.0)
		(p.process_material as ParticleProcessMaterial).scale_min = (0.1 + 0.08 * k) * (1.7 if nm == "H/Smoke" else 1.0)
		(p.process_material as ParticleProcessMaterial).scale_max = (0.16 + 0.12 * k) * (1.7 if nm == "H/Smoke" else 1.0)


## 诛影·蚀(持续伤害的每一跳)：身上冒一小团青黑的影子
func shadow_rot_tick(at: Vector3) -> void:
	fire_puff(at, Color("#0f1a20"), 4, 0.25, 0.8, 0.5, 0.8, false)
	burst(at, SHADOW_TEAL, 3, 1.0, 0.4, 0.8, 0.3)


## 淬血：从他胸口拉出几缕暗红的血雾，绕一圈卷进剑里，剑身一闪红光
func temper_blood(chest: Vector3, blade: Vector3) -> void:
	var s: float = maxf(0.2, speed_scale)
	for i in range(6):
		var m := MeshInstance3D.new()
		m.mesh = SoftFX.quad()
		var mat: StandardMaterial3D = SoftFX.sprite_mat(Color("#8a0f1e"), 1.0, false)
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.scale = Vector3.ONE * 0.16
		add_child(m)
		var a0: float = TAU * float(i) / 6.0
		var off := Vector3(cos(a0), randf_range(-0.2, 0.3), sin(a0)) * 0.35
		var dl: float = 0.03 * float(i) / s
		var tw: Tween = create_tween()
		tw.tween_interval(dl)
		tw.tween_method(func(k: float) -> void:
			if is_instance_valid(m):
				var swirl: Vector3 = off.rotated(Vector3.UP, k * 3.0) * (1.0 - k)
				m.global_position = chest.lerp(blade, k * k) + swirl
				m.scale = Vector3.ONE * (0.16 + 0.08 * sin(k * PI)), 0.0, 1.0, 0.38 / s)
		tw.tween_callback(m.queue_free)
	get_tree().create_timer(0.38 / s).timeout.connect(func() -> void:
		soft_flash(blade, Color("#ff3a4a"), 0.8, 0.22, 2.2)
		burst(blade, Color("#b5121f"), 6, 1.4, 0.4, 0.6, 0.3))


# ---------------------------------------------------------------- 正行节点(花骑士)：花瓣 / 花蕊 / 光刃 / 光矛 / 光炮 / 花开
const LILY_CORE := Color("#fffdf2")
const LILY_GLOW := Color("#ffd46a")
const LILY_HEAL := Color("#c9ffb0")
const PETAL_COLS: Array[Color] = [Color("#ffb3cf"), Color("#f07aa6"), Color("#fff4ee"), Color("#d0a8f6"), Color("#ffd8e6")]
var _petal_mesh_cache: BoxMesh = null


## 一片花瓣：扁扁的小方片，自己微微发光(粉 / 玫红 / 白 / 淡紫)
func _petal(c: Color, size: float = 1.0) -> MeshInstance3D:
	if _petal_mesh_cache == null:
		_petal_mesh_cache = BoxMesh.new()
		_petal_mesh_cache.size = Vector3(0.075, 0.012, 0.05)
	var m := MeshInstance3D.new()
	m.mesh = _petal_mesh_cache
	m.material_override = _emissive(c, 1.3)
	m.scale = Vector3.ONE * size
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


## 一把花瓣从 at 往四周飘开(落下、翻转、淡出)
func petal_puff(at: Vector3, count: int = 6, speed: float = 1.2, life: float = 0.8) -> void:
	var s: float = maxf(0.2, speed_scale)
	for i in range(count):
		var p: MeshInstance3D = _petal(PETAL_COLS[(i + randi()) % PETAL_COLS.size()], randf_range(0.8, 1.3))
		add_child(p)
		p.global_position = at + Vector3(randf_range(-0.12, 0.12), randf_range(-0.1, 0.1), randf_range(-0.12, 0.12))
		p.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		var a: float = randf() * TAU
		var to: Vector3 = p.global_position + Vector3(cos(a), 0.0, sin(a)) * speed * randf_range(0.35, 0.7) + Vector3(0.0, randf_range(-0.35, 0.25), 0.0)
		var lf: float = life * randf_range(0.75, 1.2) / s
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(p, "global_position", to, lf).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(p, "rotation", p.rotation + Vector3(randf_range(3.0, 6.0), randf_range(-3.0, 3.0), randf_range(2.0, 5.0)), lf)
		tw.tween_property(p, "scale", Vector3.ONE * 0.2, lf).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(p.queue_free)


## 花蕊的光刃 / 光矛 / 光炮(正行节点)：origin = 她的脚下，dir = 锥形的朝向(水平)，扫过 angle 度、长 length 米。
##   sword  一把延长过的光剑从她右手边横扫到左手边：胸口高度的宽光弧(白金芯、金边)，地上同一扇面淡淡亮一下，扫过的弧上撒出花瓣
##   polearm 光矛：先沿正前方刺出一道长光，再同样横扫(光带更细、更靠外)
##   focus  光炮：从她身前喷出一个扇形的冲击波(一层层往外推的光弧)，正中一道粗光束
## hits = 被扫到的人的胸口位置：每个亮一下 + 几片花瓣
func lily_sweep(origin: Vector3, dir: Vector3, angle_deg: float, length: float, kind: String, hits: Array) -> void:
	var s: float = maxf(0.2, speed_scale)
	var d: Vector3 = Vector3(dir.x, 0.0, dir.z).normalized()
	if d.length() < 0.01:
		d = Vector3(0, 0, 1)
	var span: float = deg_to_rad(angle_deg)
	var chest: Vector3 = origin + Vector3(0.0, 0.78, 0.0)
	var b_flat: Basis = _cut_basis(d, Vector3.UP, 1.0)        # 弧的 +Y = 她的左手边：光从右往左扫
	# 地上的扇面
	var fan := MeshInstance3D.new()
	fan.mesh = _crescent((length + 0.3) * 0.5, span, length - 0.3, 26)
	var fm: ShaderMaterial = _cut_mat(Color("#fff7d8"), LILY_GLOW, 0.55)
	fan.material_override = fm
	fan.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(fan)
	fan.global_transform = Transform3D(b_flat, origin + Vector3(0.0, 0.035, 0.0))
	if kind == "focus":
		# 光炮：几层光弧从身前一层层往外推
		fm.set_shader_parameter("head", 1.0)
		var tw0: Tween = create_tween()
		tw0.tween_method(func(x: float) -> void: fm.set_shader_parameter("fade", x), 0.0, 0.8, 0.06 / s)
		tw0.tween_method(func(x: float) -> void: fm.set_shader_parameter("fade", x), 0.8, 0.0, 0.5 / s).set_ease(Tween.EASE_IN)
		tw0.tween_callback(fan.queue_free)
		for k in range(3):
			var w := MeshInstance3D.new()
			w.mesh = _crescent(1.0, span, 0.22, 26)
			var wm: ShaderMaterial = _cut_mat(LILY_CORE, LILY_GLOW, 2.0 - 0.4 * float(k))
			w.material_override = wm
			w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(w)
			w.global_transform = Transform3D(b_flat, chest - Vector3(0.0, 0.08 * float(k), 0.0))
			w.scale = Vector3(0.5, 0.5, 1.0)
			var tw1: Tween = create_tween().set_parallel(true)
			var dl: float = 0.05 * float(k) / s
			tw1.tween_property(w, "scale", Vector3(length, length, 1.0 + float(k) * 0.4), 0.24 / s).set_delay(dl).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tw1.tween_method(func(x: float) -> void: wm.set_shader_parameter("fade", x), 1.0, 0.0, 0.24 / s).set_delay(dl + 0.08 / s).set_ease(Tween.EASE_IN)
			tw1.chain().tween_callback(w.queue_free)
		tracer(chest + d * 0.3, chest + d * length, 0.32, 0.26, LILY_CORE, LILY_GLOW)
		soft_flash(chest + d * 0.45, LILY_GLOW, 1.4, 0.22, 2.2)
	else:
		var t_in: float = 0.11 / s
		fm.set_shader_parameter("head", 0.0)
		var twf: Tween = create_tween()
		twf.tween_method(func(x: float) -> void: fm.set_shader_parameter("head", x), 0.0, 1.0, t_in)
		twf.tween_method(func(x: float) -> void: fm.set_shader_parameter("fade", x), 1.0, 0.0, 0.45 / s).set_ease(Tween.EASE_IN)
		twf.tween_callback(fan.queue_free)
		# 胸口高度的光刃轨迹不再另画：手里的光剑 / 光枪(LightWeapon)真的扫过去，刀光(WeaponTrail)跟着它画；
		# 这里只在外缘补一道细细的刃口光弧(光刃的尖扫过的地方)
		var m := MeshInstance3D.new()
		m.mesh = _crescent(length * 0.97, span, 0.12, 26)
		var mm: ShaderMaterial = _cut_mat(Color("#ffffff"), Color("#ffb3cf"), 2.0)
		mm.set_shader_parameter("head", 0.0)
		mm.set_shader_parameter("tail", 0.0)
		m.material_override = mm
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		m.global_transform = Transform3D(b_flat, chest)
		var tw: Tween = create_tween()
		tw.tween_method(func(x: float) -> void: mm.set_shader_parameter("head", x), 0.0, 1.0, t_in).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_method(func(x: float) -> void: mm.set_shader_parameter("tail", x), 0.0, 0.25, t_in)
		tw.tween_method(func(x: float) -> void: mm.set_shader_parameter("tail", x), 0.25, 1.0, 0.24 / s).set_ease(Tween.EASE_IN)
		tw.parallel().tween_method(func(x: float) -> void: mm.set_shader_parameter("fade", x), 1.0, 0.0, 0.24 / s).set_delay(0.05 / s)
		tw.tween_callback(m.queue_free)
	# 扫过的弧上撒出花瓣(从右往左依次)
	var nps: int = 9
	for i in range(nps):
		var a: float = lerpf(-span * 0.5, span * 0.5, (float(i) + 0.5) / float(nps))
		var pd: Vector3 = b_flat.x * cos(a) + b_flat.y * sin(a)
		var at: Vector3 = chest + pd * length * randf_range(0.45, 0.95)
		var dl2: float = (0.11 * float(i) / float(nps) if kind != "focus" else 0.12 * randf()) / s
		get_tree().create_timer(dl2).timeout.connect(petal_puff.bind(at, 2, 1.0, 0.7))
	for h: Variant in hits:
		var hp: Vector3 = h
		burst(hp, LILY_GLOW, 5, 1.8, 0.6, 0.6, 0.3)
		soft_flash(hp, LILY_CORE, 0.5, 0.14, 1.6)
	ring(origin + Vector3(0.0, 0.03, 0.0), 0.9, LILY_GLOW, 0.35, 1.4, 0.3)


## 再绽之花的吟唱：一圈花瓣绕着她慢慢转、上下浮动，脚下一圈淡金的光。返回根节点(petal_swirl_end 收掉)
func petal_swirl(at: Vector3, height: float) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	root.global_position = at
	var spin := Node3D.new()
	root.add_child(spin)
	var n: int = 22
	for i in range(n):
		var p: MeshInstance3D = _petal(PETAL_COLS[i % PETAL_COLS.size()], randf_range(0.9, 1.4))
		var a: float = TAU * float(i) / float(n)
		var r: float = 0.55 + 0.22 * float(i % 3) / 2.0
		var y0: float = 0.15 + height * 0.85 * float((i * 7) % n) / float(n)
		p.position = Vector3(cos(a) * r, y0, sin(a) * r)
		p.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		spin.add_child(p)
		var tb: Tween = p.create_tween().set_loops()
		tb.tween_property(p, "position:y", y0 + 0.18, 0.7 + 0.1 * float(i % 4)).set_trans(Tween.TRANS_SINE)
		tb.tween_property(p, "position:y", y0, 0.7 + 0.1 * float(i % 4)).set_trans(Tween.TRANS_SINE)
		var tr: Tween = p.create_tween().set_loops()
		tr.tween_property(p, "rotation:x", p.rotation.x + TAU, 1.6 + 0.2 * float(i % 5)).from(p.rotation.x)
	var ts: Tween = spin.create_tween().set_loops()
	ts.tween_property(spin, "rotation:y", TAU, 2.2).from(0.0)
	var disc := MeshInstance3D.new()
	disc.mesh = _crescent(0.75, TAU, 0.18, 40)
	var dm: ShaderMaterial = _cut_mat(Color("#fff4d0"), LILY_GLOW, 1.2)
	dm.set_shader_parameter("fade", 0.0)
	disc.material_override = dm
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(disc)
	disc.transform = Transform3D(_cut_basis(Vector3(1, 0, 0), Vector3.UP, 1.0), Vector3(0.0, 0.04, 0.0))
	create_tween().tween_method(func(x: float) -> void: dm.set_shader_parameter("fade", x), 0.0, 0.7, 0.4)
	return root


## 吟唱结束：bloom = 完整唱完(花瓣一起收进她身体里、亮一下)；否则(被打断)花瓣四散落下
func petal_swirl_end(root: Node3D, bloom: bool) -> void:
	if root == null or not is_instance_valid(root):
		return
	var s: float = maxf(0.2, speed_scale)
	var center: Vector3 = root.global_position + Vector3(0.0, 0.8, 0.0)
	for p0: Node in root.find_children("*", "MeshInstance3D", true, false):
		var p := p0 as MeshInstance3D
		if p.mesh != _petal_mesh_cache:
			continue
		var gp: Vector3 = p.global_position
		p.reparent(self)
		p.global_position = gp
		var to: Vector3 = center if bloom else gp + Vector3(randf_range(-0.6, 0.6), -gp.y + 0.05, randf_range(-0.6, 0.6))
		var lf: float = (0.22 if bloom else 0.6) / s
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(p, "global_position", to, lf).set_ease(Tween.EASE_IN if bloom else Tween.EASE_OUT)
		tw.tween_property(p, "scale", Vector3.ONE * 0.15, lf)
		tw.chain().tween_callback(p.queue_free)
	root.queue_free()
	if bloom:
		soft_flash(center, LILY_GLOW, 1.0, 0.2, 2.0)


## 花蕊 +1：几片花瓣从四周收进她胸口，一点金光
func petal_gather(at: Vector3) -> void:
	var s: float = maxf(0.2, speed_scale)
	for i in range(6):
		var p: MeshInstance3D = _petal(PETAL_COLS[i % PETAL_COLS.size()], 1.1)
		add_child(p)
		var a: float = TAU * float(i) / 6.0 + randf() * 0.5
		p.global_position = at + Vector3(cos(a) * 0.9, randf_range(-0.2, 0.5), sin(a) * 0.9)
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(p, "global_position", at, 0.3 / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(p, "scale", Vector3.ONE * 0.2, 0.3 / s)
		tw.chain().tween_callback(p.queue_free)
	get_tree().create_timer(0.3 / s).timeout.connect(soft_flash.bind(at, LILY_GLOW, 0.6, 0.18, 1.8))


## 花开(获得【花】)：脚下一朵六瓣的大百合(金白 → 粉的花瓣)从花苞一下张开，金光一闪、花瓣冲天，然后慢慢淡掉
func lily_bloom(at: Vector3) -> void:
	var s: float = maxf(0.2, speed_scale)
	var root := Node3D.new()
	add_child(root)
	root.global_position = at + Vector3(0.0, 0.04, 0.0)
	for i in range(6):
		var pivot := Node3D.new()
		pivot.rotation.y = TAU * float(i) / 6.0 + 0.3
		root.add_child(pivot)
		var hinge := Node3D.new()
		hinge.position = Vector3(0.0, 0.0, 0.18)
		hinge.rotation.x = -1.35            # 合着(花瓣朝上)
		pivot.add_child(hinge)
		var m: MeshInstance3D = LilyCounter.make_petal(Color("#fff8e0"), Color("#ffd46a") if i % 2 == 0 else Color("#ff8fbb"))
		m.scale = Vector3(0.55, 1.1, 1.25)
		hinge.add_child(m)
		var mat: ShaderMaterial = m.material_override
		mat.set_shader_parameter("lit", 1.0)
		var tw: Tween = create_tween()
		tw.tween_property(hinge, "rotation:x", -0.22, 0.38 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.parallel().tween_method(func(x: float) -> void: mat.set_shader_parameter("lit", x), 1.0, 0.2, 0.5 / s)
		tw.tween_interval(0.35 / s)
		tw.tween_method(func(x: float) -> void: mat.set_shader_parameter("fade", x), 1.0, 0.0, 0.6 / s)
	create_tween().tween_callback(root.queue_free).set_delay(1.5 / s)
	ring(at + Vector3(0.0, 0.03, 0.0), 1.6, LILY_GLOW, 0.6, 1.8, 0.2)
	pillar(at, Color("#fff1c4"), 0.6)
	petal_puff(at + Vector3(0.0, 0.9, 0.0), 16, 2.2, 1.1)


## 智能分配的治疗：几片花瓣沿弧线从她飞到受伤的友军身上，落下时一点绿金的光
func petal_stream(from: Vector3, to: Vector3) -> void:
	var s: float = maxf(0.2, speed_scale)
	var mid: Vector3 = (from + to) * 0.5 + Vector3(0.0, 0.6 + from.distance_to(to) * 0.12, 0.0)
	for i in range(4):
		var p: MeshInstance3D = _petal(PETAL_COLS[(i * 2) % PETAL_COLS.size()], 1.2)
		add_child(p)
		p.global_position = from
		var dl: float = 0.05 * float(i) / s
		var fl: float = clampf(from.distance_to(to) / 8.0, 0.25, 0.5) / s
		var tw: Tween = create_tween()
		tw.tween_interval(dl)
		tw.tween_method(func(k: float) -> void:
			if is_instance_valid(p):
				p.global_position = from.lerp(mid, k).lerp(mid.lerp(to, k), k)
				p.rotation = Vector3(k * 9.0, k * 5.0, 0.0), 0.0, 1.0, fl)
		tw.tween_callback(p.queue_free)
	get_tree().create_timer(0.5 / s).timeout.connect(burst.bind(to, LILY_HEAL, 5, 1.2, 0.6, 1.2, 0.4))


## 头顶一圈小小的发光花蕊(花蕊的层数)：金色的花药(竖着的小椭球) + 一点柔光，慢慢转；挂在 parent 下面
func stamen_buds(parent: Node3D, offset: Vector3, n: int) -> Node3D:
	var root := Node3D.new()
	root.position = offset
	parent.add_child(root)
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 10
	sm.rings = 5
	for i in range(n):
		var a: float = TAU * float(i) / float(maxi(1, n))
		var m := MeshInstance3D.new()
		m.mesh = sm
		m.material_override = _emissive(LILY_GLOW, 2.6)
		m.scale = Vector3(0.06, 0.12, 0.06)
		m.rotation.z = 0.35
		m.position = Vector3(cos(a) * 0.24, 0.0, sin(a) * 0.24)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(m)
		var g := MeshInstance3D.new()
		g.mesh = SoftFX.quad(0.26)
		var gm: StandardMaterial3D = SoftFX.sprite_mat(LILY_GLOW, 1.2, false)
		gm.albedo_color.a = 0.55
		gm.disable_fog = true
		g.material_override = gm
		g.position = m.position
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(g)
	var tw := root.create_tween().set_loops()
	tw.tween_property(root, "rotation:y", TAU, 1.8).from(0.0)
	return root


## 正花：一道带花瓣的光刺向目标
func lily_thrust(from: Vector3, to: Vector3) -> void:
	tracer(from, to, 0.14, 0.22, LILY_CORE, Color("#ffb3cf"))
	petal_puff(to, 4, 1.0, 0.6)


# ---------------------------------------------------------------- 执剑节点(勇者)：圣剑 / 再度飞翔 / 未来
const HOLY_CORE := Color("#f4f8ff")
const HOLY_GLOW := Color("#8fb4ff")
const HOLY_GOLD := Color("#ffd86a")


## 圣剑的法阵 / 复活的法阵：贴地的一圈蓝白光阵(三道环、一圈符文刻度、八道星芒、正中一个金色的十字剑徽)，open 张开、spin 转、flare 亮一下
const HOLY_SIGIL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 col : source_color = vec4(0.55, 0.72, 1.0, 1.0);
uniform vec4 gold : source_color = vec4(1.0, 0.85, 0.42, 1.0);
uniform float open = 1.0;
uniform float fade = 1.0;
uniform float spin = 0.0;
uniform float flare = 0.0;
uniform float cross_k = 1.0;
float ring_at(float r, float c, float w) {
	return 1.0 - smoothstep(w * 0.5, w * 0.5 + 0.012, abs(r - c));
}
void fragment() {
	vec2 p = (UV * 2.0 - 1.0) / max(open, 0.01);
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float a = atan(p.y, p.x) + spin;
	float m = ring_at(r, 0.95, 0.04) + ring_at(r, 0.81, 0.022) + ring_at(r, 0.44, 0.022);
	float gi = floor(a / 6.2831853 * 36.0);
	float seg = fract(a / 6.2831853 * 36.0);
	float rb = step(0.84, r) * step(r, 0.92);
	m += rb * step(abs(seg - 0.5), 0.13) * step(0.35, fract(sin(gi * 12.9898) * 43758.5453));
	m += rb * step(abs(seg - 0.5), 0.04);
	float rays = pow(abs(cos(a * 4.0)), 60.0) * step(0.46, r) * step(r, 0.8);
	m += rays * 0.85;
	vec2 q = vec2(cos(spin) * p.x - sin(spin) * p.y, sin(spin) * p.x + cos(spin) * p.y);
	float crs = (step(abs(q.x), 0.04) * step(abs(q.y + 0.08), 0.62) + step(abs(q.y - 0.3), 0.035) * step(abs(q.x), 0.3)) * cross_k;
	m = clamp(m + crs, 0.0, 1.0);
	vec3 c = mix(col.rgb, gold.rgb, step(0.5, crs));
	c = mix(c, vec3(1.0), flare * 0.6);
	float fill = (1.0 - r) * (0.14 + 0.3 * flare);
	ALBEDO = c * (1.3 + flare);
	ALPHA = clamp(m * (0.85 + 0.15 * flare) + fill, 0.0, 1.0) * fade;
}
"""
var _holy_sigil_shader: Shader = null


## 贴地法阵：at 脚下、半径 radius，open_t 秒张开，停 hold 秒，fade_t 秒淡掉；一直慢慢转。返回材质(调用者可以让它 flare 一下)
func holy_sigil(at: Vector3, radius: float, open_t: float, hold: float, fade_t: float, gold_cross: bool = true) -> ShaderMaterial:
	if _holy_sigil_shader == null:
		_holy_sigil_shader = Shader.new()
		_holy_sigil_shader.code = HOLY_SIGIL_SHADER
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(radius * 2.0, radius * 2.0)
	m.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = _holy_sigil_shader
	mat.set_shader_parameter("open", 0.0)
	if not gold_cross:
		mat.set_shader_parameter("gold", HOLY_GLOW)
	mat.render_priority = 1
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	m.global_position = Vector3(at.x, 0.05, at.z)
	var s: float = maxf(0.2, speed_scale)
	var sp0: float = randf() * TAU
	var total: float = open_t + hold + fade_t
	var tw: Tween = create_tween()
	tw.tween_method(func(k: float) -> void:
		mat.set_shader_parameter("spin", sp0 + k * total * 0.8)
		mat.set_shader_parameter("open", 1.0 - pow(1.0 - clampf(k * total / maxf(open_t, 0.01), 0.0, 1.0), 3.0))
		mat.set_shader_parameter("fade", 1.0 - clampf((k * total - open_t - hold) / maxf(fade_t, 0.01), 0.0, 1.0)), 0.0, 1.0, total / s)
	tw.tween_callback(m.queue_free)
	return mat


## 竖着 / 斜着的法阵圆盘(同一套法阵着色器)：圆心 at、盘面朝 normal、半径 radius；没有正中的十字剑徽(cross_k 0)
func sigil_disc(at: Vector3, normal: Vector3, radius: float, col: Color, open_t: float, hold: float, fade_t: float) -> ShaderMaterial:
	if _holy_sigil_shader == null:
		_holy_sigil_shader = Shader.new()
		_holy_sigil_shader.code = HOLY_SIGIL_SHADER
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(radius * 2.0, radius * 2.0)
	m.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = _holy_sigil_shader
	mat.set_shader_parameter("col", col)
	mat.set_shader_parameter("gold", col.lerp(Color.WHITE, 0.5))
	mat.set_shader_parameter("cross_k", 0.0)
	mat.set_shader_parameter("open", 0.0)
	mat.render_priority = 2
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	var y: Vector3 = normal.normalized() if normal.length() > 0.01 else Vector3.UP
	var x: Vector3 = y.cross(Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).normalized()
	m.global_transform = Transform3D(Basis(x, y, x.cross(y)), at)
	var s: float = maxf(0.2, speed_scale)
	var total: float = open_t + hold + fade_t
	var sp0: float = randf() * TAU
	var tw: Tween = create_tween()
	tw.tween_method(func(k: float) -> void:
		mat.set_shader_parameter("spin", sp0 + k * total * 1.6)
		mat.set_shader_parameter("open", 1.0 - pow(1.0 - clampf(k * total / maxf(open_t, 0.01), 0.0, 1.0), 3.0))
		mat.set_shader_parameter("fade", 1.0 - clampf((k * total - open_t - hold) / maxf(fade_t, 0.01), 0.0, 1.0)), 0.0, 1.0, total / s)
	tw.tween_callback(m.queue_free)
	return mat


## 求知节点·把咒语念出来！：她面前竖起一圈法阵(盘面朝着目标)，书里一个接一个飞出发光的字，沿弧线打到目标身上，
## 目标脚下一圈小法阵一闪、身上一团光。字从 RECITE_CHARS 里随机挑(head 留着给以后的"念出来"气泡)
const RECITE_CHARS := ["咒", "言", "火", "雷", "风", "光", "星", "冰", "符", "法", "念", "知", "明", "破"]


func recite_spell(from: Vector3, to: Vector3, head: Vector3, col: Color) -> void:
	var s: float = maxf(0.2, speed_scale)
	var d: Vector3 = Vector3(to.x - from.x, 0.0, to.z - from.z)
	var dir: Vector3 = d.normalized() if d.length() > 0.01 else Vector3(0, 0, 1)
	var disc_at: Vector3 = from + dir * 0.32 + Vector3(0.0, 0.05, 0.0)
	var dm: ShaderMaterial = sigil_disc(disc_at, dir, 0.42, col, 0.1, 0.35, 0.3)
	dm.set_shader_parameter("flare", 0.5)
	soft_flash(disc_at, col.lerp(Color.WHITE, 0.5), 0.7, 0.2, 1.6)
	var n: int = 5
	var hit_t: float = 0.0
	for i in range(n):
		var l := Label3D.new()
		l.text = RECITE_CHARS[randi() % RECITE_CHARS.size()]
		l.modulate = col.lerp(Color.WHITE, 0.55)
		l.outline_modulate = Color(0.06, 0.1, 0.3, 0.95)
		l.outline_size = 12
		l.font_size = 64
		l.pixel_size = 0.0055
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.render_priority = 40
		l.shaded = false
		l.visible = false
		add_child(l)
		l.global_position = disc_at
		var side: Vector3 = dir.cross(Vector3.UP).normalized() * (float(i) - float(n - 1) * 0.5) * 0.35
		var mid: Vector3 = (disc_at + to) * 0.5 + Vector3(0.0, 0.55 + 0.15 * float(i % 2), 0.0) + side
		var dl: float = 0.045 * float(i)
		var fl: float = clampf(disc_at.distance_to(to) / 12.0, 0.14, 0.32)
		hit_t = maxf(hit_t, dl + fl)
		var tw: Tween = create_tween()
		tw.tween_interval(dl / s)
		tw.tween_callback(func() -> void: l.visible = true)
		tw.tween_method(func(k: float) -> void:
			if is_instance_valid(l):
				l.global_position = disc_at.lerp(mid, k).lerp(mid.lerp(to, k), k)
				l.scale = Vector3.ONE * (0.6 + 0.6 * sin(k * PI)), 0.0, 1.0, fl / s)
		tw.tween_callback(func() -> void:
			burst(to, col.lerp(Color.WHITE, 0.3), 3, 1.6, 0.5, 0.6, 0.25)
			l.queue_free())
	var g := Vector3(to.x, 0.05, to.z)
	get_tree().create_timer(hit_t * 0.7 / s).timeout.connect(func() -> void:
		var tm: ShaderMaterial = sigil_disc(g, Vector3.UP, 0.6, col, 0.08, 0.2, 0.3)
		tm.set_shader_parameter("flare", 0.8)
		soft_flash(to, col.lerp(Color.WHITE, 0.4), 0.8, 0.2, 1.8))


## 一把圣剑(剑尖朝 +Y 的局部坐标：护手中心在原点)：白里透蓝的阔刃(刃缘蓝光、刃脊一条皇家蓝的血槽、槽里光纹往刃尖流)，
## 金色 V 形十字护手(两臂往刃的方向扬起、末端翻卷)、正中菱形金座托着一颗大蓝宝石，金色剑柄、圆盘柄头嵌蓝宝石；外面一层蓝光
## 返回 [根节点, 刃的材质们, 其余部件的材质们]
func _holy_sword_node(k: float) -> Array:
	var root := Node3D.new()
	var blades: Array = []
	var others: Array = []
	var bl: MeshInstance3D = LightWeapon.make_blade(2.3 * k, 0.1 * k, 0.15 * k, 0.05 * k, HOLY_CORE, Color("#6f9cff"), Color("#ffffff"))
	(bl.material_override as ShaderMaterial).set_shader_parameter("fuller", 1.0)
	(bl.material_override as ShaderMaterial).set_shader_parameter("fuller_col", Color("#4e6bff"))
	root.add_child(bl)
	blades.append(bl.material_override)
	var hl: MeshInstance3D = LightWeapon.make_blade(2.3 * k, 0.1 * k, 0.15 * k, 0.05 * k, HOLY_CORE, Color("#4f7dff"), Color("#ffffff"), true)
	root.add_child(hl)
	blades.append(hl.material_override)
	var gold := StandardMaterial3D.new()
	gold.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gold.albedo_color = Color(1.0, 0.86, 0.45, 1.0) * 1.25
	gold.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gold.disable_fog = true
	var gem := StandardMaterial3D.new()
	gem.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gem.albedo_color = Color(0.3, 0.5, 1.0, 1.0) * 1.3
	gem.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gem.disable_fog = true
	others.append_array([gold, gem])
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	# [尺寸, 位置, 绕 Z 转(度), 材质]
	var parts: Array = [
		[Vector3(0.2, 0.2, 0.09), Vector3(0, 0.02, 0), 45.0, gold],                   # 菱形金座
		[Vector3(0.12, 0.12, 0.11), Vector3(0, 0.02, 0), 45.0, gem],                  # 大蓝宝石
		[Vector3(0.38, 0.085, 0.08), Vector3(0.24, 0.045, 0), 7.0, gold],             # 右臂(往刃的方向微微扬起)
		[Vector3(0.38, 0.085, 0.08), Vector3(-0.24, 0.045, 0), -7.0, gold],           # 左臂
		[Vector3(0.09, 0.15, 0.08), Vector3(0.45, 0.02, 0), -35.0, gold],             # 末端往柄头一侧翻卷
		[Vector3(0.09, 0.15, 0.08), Vector3(-0.45, 0.02, 0), 35.0, gold],
		[Vector3(0.06, 0.06, 0.09), Vector3(0.28, 0.07, 0), 45.0, gem],               # 两臂上的小蓝宝石
		[Vector3(0.06, 0.06, 0.09), Vector3(-0.28, 0.07, 0), 45.0, gem],
		[Vector3(0.05, 0.3, 0.05), Vector3(0, -0.2, 0), 0.0, gold],                   # 剑柄
		[Vector3(0.13, 0.13, 0.05), Vector3(0, -0.4, 0), 45.0, gold],                 # 圆盘柄头
		[Vector3(0.06, 0.06, 0.07), Vector3(0, -0.4, 0), 45.0, gem],
	]
	for pt: Array in parts:
		var m := MeshInstance3D.new()
		m.mesh = bm
		m.material_override = pt[3]
		m.scale = (pt[0] as Vector3) * k
		m.position = (pt[1] as Vector3) * k
		m.rotation.z = deg_to_rad(float(pt[2]))
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(m)
	# 剑身外面一圈柔光(普通混合的蓝：白地上也看得见)
	var g := MeshInstance3D.new()
	g.mesh = SoftFX.quad(1.0)
	var gm: StandardMaterial3D = SoftFX.sprite_mat(Color("#7fa4ff"), 1.0, false)
	gm.albedo_color.a = 0.5
	gm.disable_fog = true
	g.material_override = gm
	g.scale = Vector3(1.0, 2.6, 1.0) * k
	g.position = Vector3(0, 1.2 * k, 0)
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(g)
	others.append(gm)
	return [root, blades, others]


## 勇者，圣剑：目标脚下先亮起一圈法阵、头顶 3.6 米处一道金色光环张开，光环里化出一把圣剑(剑尖朝下，从剑柄往剑尖长出来)，
## 一顿之后直直插下去(0.1 秒)；插地的一瞬法阵一闪、碎光 + 几片白羽往上溅；圣剑插在地上亮一会儿，再化成光点散掉。
## kill = 直接击杀：剑大一圈、法阵是金色的、多一道光柱
func holy_sword(at: Vector3, kill: bool) -> void:
	var s: float = maxf(0.2, speed_scale)
	var k: float = 1.3 if kill else 1.0
	var g := Vector3(at.x, 0.0, at.z)
	var sig: ShaderMaterial = holy_sigil(g, 1.15 * k, 0.1, 0.65, 0.45, true)
	# 剑插在目标朝镜头的那一侧一点(插在正中会被目标的身体整个挡住)
	var cam: Camera3D = get_viewport().get_camera_3d()
	var gs: Vector3 = g
	if cam != null:
		var tc := Vector3(cam.global_position.x - g.x, 0.0, cam.global_position.z - g.z)
		if tc.length() > 0.01:
			gs = g + tc.normalized() * 0.3
	if kill:
		sig.set_shader_parameter("col", Color("#ffe39a"))
	var made: Array = _holy_sword_node(k)
	var root: Node3D = made[0]
	add_child(root)
	root.rotation.z = PI
	var sky: Vector3 = gs + Vector3(0.0, 2.9 + 2.4 * k, 0.0)
	root.global_position = sky
	# 天上的光环
	var halo := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.86
	tm.outer_radius = 1.0
	tm.rings = 40
	tm.ring_segments = 6
	halo.mesh = tm
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.albedo_color = Color(1.25, 1.1, 0.62, 0.95)
	hm.disable_fog = true
	halo.material_override = hm
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(halo)
	halo.global_position = gs + Vector3(0.0, 2.9, 0.0)
	halo.scale = Vector3(0.1, 0.3, 0.1)
	var hr: float = 0.55 * k
	var tw0: Tween = create_tween()
	tw0.tween_property(halo, "scale", Vector3(hr, 0.3, hr), 0.08 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw0.tween_interval(0.12 / s)
	tw0.tween_property(hm, "albedo_color:a", 0.0, 0.25 / s)
	tw0.parallel().tween_property(halo, "scale", Vector3(hr * 1.6, 0.3, hr * 1.6), 0.25 / s)
	tw0.tween_callback(halo.queue_free)
	soft_flash(g + Vector3(0.0, 2.9, 0.0), HOLY_CORE, 1.2 * k, 0.25, 1.6)
	# 化出来(从剑柄往剑尖长) → 一顿 → 插下去 → 插在地上 → 化成光点
	var blades: Array = made[1]
	var others: Array = made[2]
	var land: Vector3 = gs + Vector3(0.0, 2.3 * k - 0.45 * k, 0.0)
	var tw: Tween = create_tween()
	tw.tween_method(func(x: float) -> void:
		for bmat: Variant in blades:
			(bmat as ShaderMaterial).set_shader_parameter("reach", x), 0.0, 1.0, 0.07 / s).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.02 / s)
	tw.tween_property(root, "global_position", land, 0.07 / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(_holy_impact.bind(g, k, kill, sig))
	tw.tween_interval(0.6 / s)
	tw.tween_method(func(x: float) -> void:
		for bmat2: Variant in blades:
			(bmat2 as ShaderMaterial).set_shader_parameter("vis", x)
		for om: Variant in others:
			var sm0 := om as StandardMaterial3D
			if sm0 != null:
				sm0.albedo_color.a = x * (0.5 if sm0.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED else 1.0), 1.0, 0.0, 0.35 / s)
	tw.parallel().tween_callback(burst.bind(g + Vector3(0, 1.2 * k, 0), HOLY_CORE, 10, 0.8, 0.5, 2.2, 0.6))
	tw.tween_callback(root.queue_free)


## 圣剑插地的一瞬：法阵一闪、一圈蓝光、碎光往上溅、几片白羽；直接击杀再加一道光柱
func _holy_impact(g: Vector3, k: float, kill: bool, sig: ShaderMaterial) -> void:
	var s: float = maxf(0.2, speed_scale)
	sig.set_shader_parameter("flare", 0.6)
	create_tween().tween_method(func(x: float) -> void: sig.set_shader_parameter("flare", x), 0.6, 0.0, 0.4 / s)
	soft_flash(g + Vector3(0, 0.5, 0), HOLY_CORE, 1.1 * k, 0.2, 1.6)
	ring(g + Vector3(0.0, 0.04, 0.0), 1.5 * k, HOLY_GLOW, 0.4, 1.6, 0.15)
	burst(g + Vector3(0, 0.3, 0), HOLY_GLOW, 14 if kill else 9, 3.4, 0.8, 1.6, 0.5)
	burst(g + Vector3(0, 0.3, 0), HOLY_GOLD, 6, 2.6, 0.6, 2.0, 0.5)
	feather_fall(g + Vector3(0.0, 0.6, 0.0), 8 if kill else 5, 0.9)
	if kill:
		pillar(g, Color("#dce8ff"), 0.6)


## 几片白羽从 at 往上扬起、再打着旋慢慢飘落(带一点左右摆)
func feather_fall(at: Vector3, n: int, life: float = 1.2, base: Color = Color("#ffffff"), tip: Color = Color("#cfe0ff")) -> void:
	var s: float = maxf(0.2, speed_scale)
	for i in range(n):
		var f: MeshInstance3D = LilyCounter.make_petal(base, tip)
		var fmat: ShaderMaterial = f.material_override
		fmat.set_shader_parameter("lit", 0.6)
		f.scale = Vector3(0.07, 0.25, 0.2)
		add_child(f)
		var a: float = TAU * float(i) / float(maxi(1, n)) + randf() * 0.6
		var p0: Vector3 = at + Vector3(cos(a) * 0.15, 0.0, sin(a) * 0.15)
		var top: Vector3 = at + Vector3(cos(a) * randf_range(0.4, 0.9), randf_range(0.5, 1.1), sin(a) * randf_range(0.4, 0.9))
		var ph: float = randf() * TAU
		var lf: float = life * randf_range(0.85, 1.25)
		f.global_position = p0
		var tw: Tween = create_tween()
		tw.tween_method(_feather_step.bind(f, fmat, p0, top, at.y, ph), 0.0, 1.0, lf / s)
		tw.tween_callback(f.queue_free)


func _feather_step(k: float, f: Variant, fmat: ShaderMaterial, p0: Vector3, top: Vector3, ground: float, ph: float) -> void:
	if not is_instance_valid(f):
		return
	var fm: MeshInstance3D = f
	var up: float = minf(k / 0.25, 1.0)
	var p: Vector3 = p0.lerp(top, 1.0 - pow(1.0 - up, 2.0))
	if k > 0.25:
		var d: float = (k - 0.25) / 0.75
		p = top + Vector3(sin(ph + d * 7.0) * 0.18, -d * (top.y - ground + 0.4), cos(ph + d * 5.0) * 0.12)
	fm.global_position = p
	fm.rotation = Vector3(0.6 * sin(ph + k * 9.0), ph + k * 4.0, 0.5 * cos(ph + k * 7.0))
	fmat.set_shader_parameter("fade", 1.0 - smoothstep(0.7, 1.0, k))


## 与你，再度飞翔：一道蓝白的光从她身上飞到被复活的队友身上，那里扬起一阵白羽
func fly_again(from: Vector3, to: Vector3) -> void:
	tracer(from, to, 0.18, 0.35, HOLY_CORE, HOLY_GLOW)
	var s: float = maxf(0.2, speed_scale)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.05, 0.012, 0.14)
	for i in range(12):
		var f := MeshInstance3D.new()
		f.mesh = bm
		f.material_override = _emissive(Color("#ffffff") if i % 3 else Color("#cfe0ff"), 1.4)
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(f)
		var a: float = TAU * float(i) / 12.0
		f.global_position = to + Vector3(cos(a) * 0.2, randf_range(-0.2, 0.2), sin(a) * 0.2)
		f.rotation = Vector3(randf() * TAU, a, randf() * TAU)
		var dst: Vector3 = to + Vector3(cos(a) * randf_range(0.6, 1.1), randf_range(0.6, 1.4), sin(a) * randf_range(0.6, 1.1))
		var lf: float = randf_range(0.7, 1.1) / s
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(f, "global_position", dst, lf).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(f, "rotation", f.rotation + Vector3(randf_range(2.0, 5.0), 0.0, randf_range(2.0, 5.0)), lf)
		tw.tween_property(f, "scale", Vector3.ONE * 0.2, lf).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(f.queue_free)


## 与你，再度飞翔(希望复活了一个队友)：她那边一道蓝白的光飞过去；被复活的人脚下张开一圈带金十字的法阵，
## 天上降下一道蓝白的光柱罩住他，他背后展开一对光之翼(两排白羽，从收拢一下张开、扇一下)，再散成白羽飘落，身边往上飘着光点
## view = 被复活的人的模型节点(翅膀挂在它下面，跟着它走、转)
func hope_rebirth(view: Node3D, body_h: float, from: Vector3) -> void:
	if view == null or not is_instance_valid(view):
		return
	var s: float = maxf(0.2, speed_scale)
	var g := Vector3(view.global_position.x, 0.0, view.global_position.z)
	var chest: Vector3 = g + Vector3(0.0, body_h * 0.72, 0.0)
	tracer(from, chest, 0.16, 0.4, HOLY_CORE, HOLY_GLOW)
	holy_sigil(g, 1.3, 0.2, 1.3, 0.6, true)
	_light_shaft(g, 1.1, 1.4)
	soft_flash(chest, HOLY_CORE, 1.4, 0.3, 1.8)
	ring(g + Vector3(0.0, 0.05, 0.0), 1.6, HOLY_GLOW, 0.6, 1.6, 0.15)
	# 往上飘的光点
	var p := SoftFX.particles(26, 1.4, SoftFX.ramp([Color(0.8, 0.88, 1.0, 0.0), Color(0.9, 0.95, 1.0, 0.95), Color(0.55, 0.7, 1.0, 0.0)], [0.0, 0.3, 1.0]), 0.09)
	var pm: ParticleProcessMaterial = p.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = 0.7
	pm.emission_ring_inner_radius = 0.2
	pm.emission_ring_height = 0.1
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 10.0
	pm.initial_velocity_min = 0.8
	pm.initial_velocity_max = 1.6
	(p.material_override as StandardMaterial3D).disable_fog = true
	p.emitting = true
	add_child(p)
	p.global_position = g + Vector3(0.0, 0.1, 0.0)
	p.speed_scale = _pslow()
	get_tree().create_timer(1.0 / s).timeout.connect(func() -> void:
		if is_instance_valid(p):
			p.emitting = false)
	get_tree().create_timer(2.6 / s).timeout.connect(p.queue_free)
	_light_wings(view, body_h)


## 天上降下来的一道光柱(两片交叉的竖直光带，中间亮、两边淡；普通混合的淡蓝 + 叠加的白芯)：从天上往下长、停一会儿、变细淡掉
func _light_shaft(g: Vector3, width: float, life: float) -> void:
	var s: float = maxf(0.2, speed_scale)
	var gt := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, 0.35, 0.5, 0.65, 1.0])
	gr.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.5), Color(1, 1, 1, 1), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
	gt.gradient = gr
	gt.width = 64
	gt.height = 4
	var h: float = 9.0
	var root := Node3D.new()
	add_child(root)
	root.global_position = g
	var mats: Array = []
	for L: Array in [[Color(0.62, 0.76, 1.0, 0.55), false, 1.0], [Color(1.0, 1.0, 1.0, 0.9), true, 0.45]]:
		for rot in [0.0, PI * 0.5]:
			var m := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(width * float(L[2]), h)
			q.center_offset = Vector3(0.0, h * 0.5, 0.0)
			m.mesh = q
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if bool(L[1]) else BaseMaterial3D.BLEND_MODE_MIX
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			mat.albedo_texture = gt
			mat.albedo_color = L[0]
			mat.disable_fog = true
			mat.no_depth_test = false
			m.material_override = mat
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			m.rotation.y = rot
			root.add_child(m)
			mats.append(mat)
	# 从天上往下长：根节点贴地、整体从顶上往下"放"(缩放 y 从 0 到 1，锚点在顶上 → 用位置补)
	root.scale = Vector3(1.0, 0.01, 1.0)
	root.global_position = g + Vector3(0.0, h, 0.0)
	var tw: Tween = create_tween()
	tw.tween_method(func(k: float) -> void:
		if is_instance_valid(root):
			root.scale = Vector3(1.0, maxf(0.01, k), 1.0)
			root.global_position = g + Vector3(0.0, h * (1.0 - k), 0.0), 0.0, 1.0, 0.16 / s).set_ease(Tween.EASE_OUT)
	tw.tween_interval(life * 0.45 / s)
	tw.tween_method(func(k: float) -> void:
		if is_instance_valid(root):
			root.scale = Vector3(1.0 - 0.8 * k, 1.0, 1.0 - 0.8 * k)
			for mm: Variant in mats:
				var sm0 := mm as StandardMaterial3D
				sm0.albedo_color.a = (0.55 if sm0.blend_mode == BaseMaterial3D.BLEND_MODE_MIX else 0.9) * (1.0 - k), 0.0, 1.0, life * 0.55 / s)
	tw.tween_callback(root.queue_free)


## 光之翼：挂在 view 下面(她背后、肩膀高)，左右各两排白羽(外排长、内排短)。0.3 秒从收拢张开 → 扇一下 → 淡掉、散成白羽飘落
func _light_wings(view: Node3D, body_h: float) -> void:
	var s: float = maxf(0.2, speed_scale)
	var root := Node3D.new()
	view.add_child(root)
	root.position = Vector3(0.0, body_h * 0.72, -0.14)
	var feathers: Array = []                     # [pivot, side, 张开后的角度(弧度)]
	var mats: Array = []
	for side: float in [1.0, -1.0]:
		var wing := Node3D.new()
		wing.name = "Wing"
		wing.position = Vector3(0.1 * side, 0.0, 0.0)
		wing.set_meta("side", side)
		root.add_child(wing)
		for row: Array in [[7, 1.05, 0.17, 18.0, 118.0, 0.0], [5, 0.55, 0.14, 28.0, 105.0, 0.02]]:
			var cnt: int = int(row[0])
			for i in range(cnt):
				var u: float = float(i) / float(cnt - 1)
				var phi: float = deg_to_rad(lerpf(float(row[3]), float(row[4]), u))
				var pivot := Node3D.new()
				pivot.position = Vector3(0.0, 0.0, -float(row[5]))
				wing.add_child(pivot)
				var f: MeshInstance3D = LilyCounter.make_petal(Color("#ffffff"), Color("#b9d0ff"))
				f.rotation.x = -PI * 0.5
				f.scale = Vector3(float(row[2]), 0.25, float(row[1]) * (1.0 - 0.45 * u))
				pivot.add_child(f)
				var fm: ShaderMaterial = f.material_override
				fm.set_shader_parameter("lit", 0.5)
				fm.set_shader_parameter("fade", 0.0)
				mats.append(fm)
				feathers.append([pivot, side, phi])
	var total: float = 1.5
	var tw: Tween = create_tween()
	tw.tween_method(func(t: float) -> void:
		if not is_instance_valid(root):
			return
		var open: float = 1.0 - pow(1.0 - clampf(t / 0.3, 0.0, 1.0), 3.0)
		var flap: float = sin(clampf((t - 0.35) / 0.5, 0.0, 1.0) * PI) * 0.55
		var fade: float = clampf(t / 0.12, 0.0, 1.0) * (1.0 - clampf((t - 1.0) / 0.5, 0.0, 1.0))
		for fd: Array in feathers:
			var pv: Node3D = fd[0]
			pv.rotation.z = -float(fd[1]) * lerpf(0.08, float(fd[2]), open)
		for wn: Node in root.get_children():
			var w3 := wn as Node3D
			w3.rotation.y = float(w3.get_meta("side", 1.0)) * (0.55 - 0.45 * open - flap)
		for fm2: Variant in mats:
			(fm2 as ShaderMaterial).set_shader_parameter("fade", fade), 0.0, total, total / s)
	tw.tween_callback(func() -> void:
		if is_instance_valid(root):
			feather_fall(root.global_position, 10, 1.4)
			root.queue_free())


## 梦想，未来(她倒下时)：一道道蓝金色的光从她身上飞向每个队友，落在身上亮一下
func future_stream(from: Vector3, to: Vector3) -> void:
	tracer(from, to, 0.12, 0.45, HOLY_GOLD, HOLY_GLOW)
	var s: float = maxf(0.2, speed_scale)
	get_tree().create_timer(0.2 / s).timeout.connect(soft_flash.bind(to, HOLY_GOLD, 0.9, 0.3, 2.0))


# ---------------------------------------------------------------- 共歌节点(人鱼歌姬)：温柔地 / 美妙地 / 沉醉 / 善良地 / 沉沦之梦
## 主题 = 人鱼的歌：粉金的五线谱、音符、泡泡。温柔地 = 整个战场沉进一场温柔的水下梦境(DomainFX lullaby + 满场往上飘的泡泡)；
## 美妙地 = 麦克风里旋出一条五线谱(SongStaff)+ 一圈圈声波 + 给每个人飞去一枚拖着闪光的音符；沉醉 = 头部周围绕着转的小音符(IntoxMarks)；
## 善良地 = 她身上一圈心形的脉冲、被打到的人头上的音符亮一下；沉沦之梦 = 队友金色的祝福、敌人往下沉的紫色泡泡。
## 白地上叠加光会洗掉：线条 / 泡泡边一律用饱和的粉(普通混合)
const SONG_PINK := Color("#ff9ec8")
const SONG_GOLD := Color("#ffe08a")
const SONG_DEEP := Color("#ff4f9e")
const DREAM_GOLD := Color("#ffc23a")
const DREAM_PURPLE := Color("#8a4dff")
const NOTE2_ROWS := ["..XXXXX", "..XXXXX", "..X...X", "..X...X", ".XX..XX", "XXX.XXX", "XX..XX."]

var _bubble_tex: GradientTexture2D = null


## 两个连在一起的八分音符(♫)
func note2_mesh() -> ArrayMesh:
	return _voxel_icon("note2", NOTE2_ROWS, 0.026)


## 泡泡的贴图：中间几乎透明、边上一圈亮边、外缘一点柔光
func _bubble_texture() -> GradientTexture2D:
	if _bubble_tex != null:
		return _bubble_tex
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 0.74, 0.84, 0.93, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.12), Color(1, 1, 1, 0.55), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.0)])
	_bubble_tex = GradientTexture2D.new()
	_bubble_tex.gradient = g
	_bubble_tex.fill = GradientTexture2D.FILL_RADIAL
	_bubble_tex.fill_from = Vector2(0.5, 0.5)
	_bubble_tex.fill_to = Vector2(1.0, 0.5)
	_bubble_tex.width = 64
	_bubble_tex.height = 64
	return _bubble_tex


func _bubble_mat() -> StandardMaterial3D:
	if _mat_cache.has("bubble"):
		return _mat_cache["bubble"]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _bubble_texture()
	m.disable_fog = true
	m.render_priority = 3
	_mat_cache["bubble"] = m
	return m


## 一团泡泡粒子：从 extents 的盒子(或 radius 的球)里冒出来，往上飘(rise < 0 = 往下沉)、左右晃，快到寿命时缩小消失(啵)。col = 泡泡边的颜色
## 持续的(one_shot = false)由调用方管 emitting；一次性的几乎同时冒出来
func bubbles(amount: int, life: float, size: float, col: Color, extents: Vector3 = Vector3.ZERO, radius: float = 0.3, rise: float = 0.5, one_shot: bool = false) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	if extents != Vector3.ZERO:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = extents
	else:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = maxf(0.02, radius)
	pm.direction = Vector3(0, 1, 0) if rise >= 0.0 else Vector3(0, -1, 0)
	pm.spread = 25.0 if not one_shot else 60.0
	pm.initial_velocity_min = absf(rise) * 0.5
	pm.initial_velocity_max = absf(rise)
	pm.gravity = Vector3(0, 0.25 if rise >= 0.0 else -0.35, 0)
	pm.damping_min = 0.3
	pm.damping_max = 0.8
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_scale = 1.6
	pm.turbulence_influence_min = 0.04
	pm.turbulence_influence_max = 0.12
	pm.scale_min = size * 0.55
	pm.scale_max = size * 1.25
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.2))
	curve.add_point(Vector2(0.15, 1.0))
	curve.add_point(Vector2(0.85, 1.05))
	curve.add_point(Vector2(1.0, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	var hi: Color = col.lightened(0.35)
	pm.color_ramp = SoftFX.ramp([Color(col.r, col.g, col.b, 0.0), Color(col.r, col.g, col.b, 0.95), Color(hi.r, hi.g, hi.b, 0.85), Color(1, 1, 1, 0.0)],
		[0.0, 0.12, 0.8, 1.0])
	p.process_material = pm
	p.draw_pass_1 = SoftFX.quad()
	p.material_override = _bubble_mat()
	p.amount = amount
	p.lifetime = life
	p.one_shot = one_shot
	p.explosiveness = 0.85 if one_shot else 0.0
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ext: Vector3 = extents + Vector3.ONE * 3.0
	p.visibility_aabb = AABB(-ext - Vector3(0, 1, 0), ext * 2.0 + Vector3(0, 6, 0))
	p.speed_scale = _pslow()
	p.emitting = true
	return p


## 一次性的一小把泡泡(放完自己删)
func bubble_puff(at: Vector3, col: Color, count: int = 8, size: float = 0.16, rise: float = 0.8, life: float = 0.9, radius: float = 0.25) -> void:
	var p: GPUParticles3D = bubbles(count, life, size, col, Vector3.ZERO, radius, rise, true)
	p.position = at
	add_child(p)
	get_tree().create_timer((life + 0.3) / _pslow()).timeout.connect(p.queue_free)


## 她身上一直冒的泡泡(挂在视图上、跟着她走；世界坐标粒子 → 移动时身后拖一串)
func song_aura(parent: Node3D, h: float) -> GPUParticles3D:
	var p: GPUParticles3D = bubbles(12, 2.0, 0.15, Color("#ff6fb8"), Vector3.ZERO, 0.42, 0.35)
	p.name = "SongAura"
	p.position = Vector3(0.0, h * 0.45, 0.0)
	parent.add_child(p)
	return p


## 温柔地期间满场往上飘的泡泡(盒子铺满战场)；停掉用 gentle_bubbles_stop(放完自己删)
func gentle_bubbles(center: Vector3, half: Vector2) -> GPUParticles3D:
	var p: GPUParticles3D = bubbles(110, 3.4, 0.2, Color("#ff86c4"), Vector3(half.x, 0.15, half.y), 0.3, 0.45)
	p.name = "GentleBubbles"
	p.position = Vector3(center.x, 0.2, center.z)
	add_child(p)
	return p


func gentle_bubbles_stop(p: GPUParticles3D) -> void:
	if p == null or not is_instance_valid(p):
		return
	p.emitting = false
	get_tree().create_timer(3.6 / _pslow()).timeout.connect(p.queue_free)


## 温柔地挡掉的伤害：命中处一下子炸开一小圈泡泡(像被一个泡泡接住了)
func bubble_pop(at: Vector3) -> void:
	bubble_puff(at, Color("#ff6fb6"), 6, 0.14, 1.1, 0.5, 0.12)


const _BUBBLE_DOME := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec4 col : source_color = vec4(1.0, 0.55, 0.8, 1.0);
uniform float alpha = 1.0;
void fragment() {
	float f = 1.0 - abs(dot(NORMAL, VIEW));
	float rim = pow(f, 2.2);
	// 一点虹彩：边缘往青 / 金偏
	vec3 iri = mix(col.rgb, vec3(0.6, 0.95, 1.0), smoothstep(0.55, 0.95, f) * 0.5) + vec3(0.25, 0.18, 0.0) * sin(f * 14.0 + TIME * 2.0) * 0.3;
	ALBEDO = iri * 1.15;
	ALPHA = clamp(rim * 1.1 + 0.04, 0.0, 1.0) * alpha;
}
"""
var _bubble_dome_shader: Shader = null


## 一个从 at 鼓起来的大泡泡(球壳只有边缘亮)：dur 秒长到 r 米、后半段淡掉
func bubble_dome(at: Vector3, r: float, dur: float, col: Color = Color("#ff8ccc")) -> void:
	if _bubble_dome_shader == null:
		_bubble_dome_shader = Shader.new()
		_bubble_dome_shader.code = _BUBBLE_DOME
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 32
	sm.rings = 16
	m.mesh = sm
	var mat := ShaderMaterial.new()
	mat.shader = _bubble_dome_shader
	mat.set_shader_parameter("col", col)
	mat.render_priority = 2
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position = at
	m.scale = Vector3.ONE * 0.3
	add_child(m)
	var s: float = maxf(0.2, speed_scale)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(m, "scale", Vector3(r, r * 0.8, r), dur / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(func(a: float) -> void: mat.set_shader_parameter("alpha", a), 1.0, 0.0, dur * 0.6 / s).set_delay(dur * 0.4 / s)
	tw.chain().tween_callback(m.queue_free)


## 一枚飞过去的音符(拖着一串小闪光，到了啵一下)：from → 往上拱的弧 → to；delay 秒后出发，on_land 到了时调
func _song_note(from: Vector3, to: Vector3, col: Color, delay: float, size: float = 2.0, double: bool = false, on_land: Callable = Callable()) -> void:
	var s: float = maxf(0.2, speed_scale)
	var m := MeshInstance3D.new()
	m.mesh = note2_mesh() if double else note_mesh()
	m.material_override = _icon_mat(col, 2.6)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.scale = Vector3.ZERO
	add_child(m)
	m.global_position = from
	var tr := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.3
	pm.gravity = Vector3(0, -0.4, 0)
	pm.scale_min = 0.35
	pm.scale_max = 0.7
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1.0))
	curve.add_point(Vector2(1, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	tr.process_material = pm
	tr.draw_pass_1 = _box
	tr.material_override = _emissive(col.lightened(0.3), 2.6)
	tr.amount = 14
	tr.lifetime = 0.38
	tr.local_coords = false
	tr.emitting = false
	tr.speed_scale = _pslow()
	tr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tr.visibility_aabb = AABB(Vector3(-4, -3, -4), Vector3(8, 8, 8))
	m.add_child(tr)
	var mid: Vector3 = (from + to) * 0.5 + Vector3(0, clampf(from.distance_to(to) * 0.18, 0.5, 1.4), 0)
	var dur: float = clampf(from.distance_to(to) / 8.5, 0.3, 0.75)
	var tw: Tween = create_tween()
	tw.tween_interval(delay / s)
	tw.tween_callback(func() -> void:
		if is_instance_valid(tr):
			tr.emitting = true)
	tw.tween_property(m, "scale", Vector3.ONE * size, 0.08 / s)
	tw.tween_method(_note_arc.bind(m, from, mid, to), 0.0, 1.0, dur / s).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		if is_instance_valid(tr):
			tr.emitting = false
			tr.reparent(self)
			get_tree().create_timer(0.5 / maxf(0.2, speed_scale)).timeout.connect(tr.queue_free)
		burst(to, col, 5, 1.6, 0.55, 1.0, 0.35)
		soft_flash(to, col, 0.55, 0.18, 1.6)
		if on_land.is_valid():
			on_land.call()
		m.queue_free())


## 美妙地(每次普攻)：麦克风里旋出一条五线谱绕着她盘下来 + 脚下两圈一前一后的声波(深粉 → 金)
## + 给每个被唱到的人飞去一枚拖着闪光的音符(一个人一枚，最多 14 枚，错开出发)。at = 她脚下，mic = 麦克风
func song_wave(at: Vector3, mic: Vector3, targets: Array) -> void:
	var s: float = maxf(0.2, speed_scale)
	SongStaff.create(self, at, mic, SONG_DEEP, SONG_GOLD)
	soft_flash(mic, SONG_PINK, 0.7, 0.25, 2.0)
	ring(Vector3(at.x, 0.05, at.z), 1.8, SONG_DEEP, 0.5, 1.0, 0.15)
	get_tree().create_timer(0.12 / s).timeout.connect(ring.bind(Vector3(at.x, 0.05, at.z), 2.7, SONG_GOLD, 0.6, 0.7, 0.15))
	var n := 0
	for tp: Variant in targets:
		if n >= 14:
			break
		var to: Vector3 = tp
		_song_note(mic, to, SONG_DEEP if n % 2 == 0 else SONG_GOLD, 0.06 + 0.035 * float(n), 1.9, n % 3 == 1)
		n += 1


## 温柔地：她身上鼓起一个大泡泡、往外推出两圈粉白的光波，飘起一把音符和泡泡(水下梦境由 BattleView 的 DomainFX 铺满全场)
func gentle_wave(at: Vector3) -> void:
	bubble_dome(at + Vector3(0, 0.7, 0), 3.2, 1.1)
	ring(Vector3(at.x, 0.05, at.z), 14.0, Color("#ffd1e4"), 1.4, 2.2, 0.05)
	ring(Vector3(at.x, 0.06, at.z), 8.0, SONG_DEEP, 1.0, 1.6, 0.05)
	soft_flash(at + Vector3(0.0, 1.0, 0.0), Color("#ffe3ef"), 2.2, 0.5, 1.6)
	float_icons(at + Vector3(0, 1.2, 0), note_mesh(), SONG_DEEP, 6, 0.8, 1.4, 1.6)
	float_icons(at + Vector3(0, 1.2, 0), note2_mesh(), SONG_GOLD, 4, 0.8, 1.4, 1.6)
	bubble_puff(at + Vector3(0, 0.6, 0), Color("#ff7fbf"), 24, 0.22, 1.4, 1.6, 0.6)


## 温柔地结束：一圈淡粉的波往外退、几个泡泡啵掉
func gentle_fade(at: Vector3) -> void:
	ring(Vector3(at.x, 0.05, at.z), 6.0, Color("#ffd1e4"), 0.9, 1.4, 0.2)
	bubble_puff(at + Vector3(0, 0.8, 0), Color("#ff9ccd"), 10, 0.18, 1.0, 1.0, 0.5)


## 善良地(每 5 秒)：她身上一圈心形的脉冲(两圈粉环 + 飘起几颗心)；目标头上的音符由 IntoxMarks.pulse 亮一下
func kind_pulse(at: Vector3, chest: Vector3) -> void:
	ring(Vector3(at.x, 0.05, at.z), 2.4, SONG_DEEP, 0.55, 1.8, 0.1)
	var s: float = maxf(0.2, speed_scale)
	get_tree().create_timer(0.12 / s).timeout.connect(ring.bind(Vector3(at.x, 0.05, at.z), 3.4, SONG_PINK, 0.65, 1.2, 0.1))
	float_icons(chest + Vector3(0, 0.3, 0), heart_mesh(), SONG_DEEP, 5, 0.35, 1.0, 1.4)
	soft_flash(chest, SONG_PINK, 0.9, 0.25, 1.8)


## 善良地打到一个目标：头上一颗小心 + 一点粉光(和 IntoxMarks.pulse 一起)
func kind_mark(at: Vector3) -> void:
	float_icons(at, heart_mesh(), SONG_DEEP, 1, 0.05, 0.7, 1.2)
	soft_flash(at, SONG_PINK, 0.45, 0.2, 1.6)


## 往里收的一圈环(沉沦：脚下的漩涡)
func ring_in(pos: Vector3, radius: float, color: Color, dur: float = 0.6, width: float = 1.0) -> void:
	var m := MeshInstance3D.new()
	m.mesh = _ring_mesh
	var rmat: StandardMaterial3D = _emissive(color, 2.0, 0.85).duplicate() as StandardMaterial3D
	rmat.albedo_color.a = 0.0
	m.material_override = rmat
	m.position = pos + Vector3(0, 0.06, 0)
	m.scale = Vector3(radius, 0.10 * width, radius)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	var s: float = maxf(0.2, speed_scale)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(m, "scale", Vector3(radius * 0.15, 0.10 * width, radius * 0.15), dur / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(rmat, "albedo_color:a", 0.9, dur * 0.25 / s)
	tw.tween_property(rmat, "albedo_color:a", 0.0, dur * 0.35 / s).set_delay(dur * 0.65 / s)
	tw.chain().tween_callback(m.queue_free)


## 沉沦之梦：一枚音符从她手里飞到触发目标身上。队友 = 金色的祝福(脚下一圈金环、身上往上冒金色的光点和两枚小音符)；
## 敌人 = 往下沉的梦(脚下一圈往里收的紫色漩涡、身上往下坠的紫色泡泡)
func dream_echo(from: Vector3, to: Vector3, ally: bool) -> void:
	var c: Color = DREAM_GOLD if ally else DREAM_PURPLE
	var ground := Vector3(to.x, 0.0, to.z)
	var land: Callable
	if ally:
		land = func() -> void:
			ring(ground + Vector3(0, 0.04, 0), 0.95, DREAM_GOLD, 0.55, 1.4, 0.2)
			burst(to, DREAM_GOLD, 8, 1.8, 0.6, 1.0, 0.6)
			float_icons(to + Vector3(0, 0.2, 0), note_mesh(), DREAM_GOLD, 2, 0.2, 0.9, 1.2)
	else:
		land = func() -> void:
			ring_in(ground + Vector3(0, 0.04, 0), 1.0, DREAM_PURPLE, 0.7, 1.5)
			bubble_puff(to + Vector3(0, 0.2, 0), Color("#7a3cff"), 8, 0.15, -0.9, 0.9, 0.25)
	_song_note(from, to, c, 0.0, 2.1, not ally, land)


# ---------------------------------------------------------------- 白羽节点(天使枪手)：黑白蝴蝶
## 视觉原语 = 黑白的蝴蝶(Butterfly)：黑蝶 = 送葬 / 死亡，白蝶 = 救赎 / 求生。
## 送葬的层数 = 绕着目标飞的黑蝶(FuneralWreath，BattleView 按状态事件同步)；满层倒下 = 黑蝶扑进身体、身体化掉、化成一大群黑白蝴蝶飞散；
## 精英 / 首领(送葬之痕)= 黑蝶咬一口四散、身上停下一只合着翅膀的黑蝶(最多 3 只)；治疗弹 = 一只白蝶从队友身上飞起；
## 求生的意志 = 身后张开一对半透明的白蝶大翅膀 + 一圈白蝶；致将亡而未亡者 = 黑白蝴蝶一只只扑向送葬最多的敌人；
## 她身边常驻两黑两白(ButterflyAura)，倒下时散开飞走
const ANGEL_WHITE := Color("#f4f2ff")
const ANGEL_DARK := Color("#2a2238")
const ANGEL_BLUE := Color("#9fd0ff")


## 送葬满层：at = 脚下，h = 身高。kill = 倒下(黑蝶扑进去 → 身体化成一大群黑白蝴蝶飞散)；否则 = 送葬之痕(黑蝶咬一口四散、撕下几块暗色碎片)
func funeral(at: Vector3, kill: bool, h: float = 1.3) -> void:
	var s: float = maxf(0.2, speed_scale)
	var chest: Vector3 = at + Vector3(0.0, h * 0.62, 0.0)
	get_tree().create_timer(0.2 / s).timeout.connect(_funeral_burst.bind(at, chest, h) if kill else _funeral_bite.bind(at, chest))


func _funeral_burst(at: Vector3, chest: Vector3, h: float) -> void:
	soft_flash(chest, ANGEL_WHITE, 1.0, 0.25, 1.6)
	fire_puff(chest, ANGEL_DARK, 8, 0.55, 1.0, 0.8, 0.8, false)
	ring(Vector3(at.x, 0.04, at.z), 1.5, ANGEL_DARK, 0.75, 2.0, 0.2)
	ring(Vector3(at.x, 0.05, at.z), 1.0, ANGEL_WHITE, 0.6, 1.2, 0.25)
	ButterflyFlock.burst(self, chest, 14, 7, 2.6, 1.6, 1.9, 1.4, 0.3, 0.7)
	# 身体化掉的同时，下半身再飞出一小群(像整个人散成了蝴蝶)
	var s: float = maxf(0.2, speed_scale)
	get_tree().create_timer(0.22 / s).timeout.connect(func() -> void:
		ButterflyFlock.burst(self, at + Vector3(0.0, h * 0.3, 0.0), 6, 4, 1.6, 2.0, 1.7, 1.2, 0.25, 1.0))


func _funeral_bite(at: Vector3, chest: Vector3) -> void:
	soft_flash(chest, Color("#d8d0ff"), 1.0, 0.22, 1.6)
	ring(Vector3(at.x, 0.04, at.z), 1.3, ANGEL_DARK, 0.6, 1.8, 0.2)
	burst(chest, ANGEL_DARK, 12, 2.4, 0.8, 0.5, 0.6, false)
	ButterflyFlock.burst(self, chest, 10, 0, 3.0, 0.7, 1.1, 1.3, 0.15, 0.25)


## 送葬之痕：精英 / 首领身上停下一只合着翅膀慢慢开合的黑蝶(第 i 只停在不同的地方：左肩 / 右肩 / 头顶)
const SCAR_SPOTS := [Vector3(0.2, 0.7, 0.06), Vector3(-0.21, 0.66, 0.02), Vector3(0.04, 1.02, -0.02)]


func funeral_scar(parent: Node3D, i: int, h: float) -> Butterfly:
	var bf: Butterfly = Butterfly.make("black", 1.5)
	bf.flap_hz = randf_range(0.6, 0.9)
	bf.flap_lo = 0.35
	bf.flap_hi = 1.35
	parent.add_child(bf)
	var sp: Vector3 = SCAR_SPOTS[i % SCAR_SPOTS.size()]
	bf.position = Vector3(sp.x, sp.y * h, sp.z)
	bf.face(Vector3(sp.x * 0.6, 1.0, 0.5))
	var s0: float = bf.scale.x
	bf.scale = Vector3.ONE * 0.01
	var tw := bf.create_tween()
	tw.tween_property(bf, "scale", Vector3.ONE * s0, 0.25).set_delay(0.35)
	return bf


## 治疗弹打到队友：一只白蝶从身上飞起 + 一点淡蓝的光
func angel_heal_mark(chest: Vector3) -> void:
	soft_flash(chest, ANGEL_BLUE, 0.6, 0.2, 1.6)
	ButterflyFlock.burst(self, chest, 0, 1, 0.9, 1.5, 1.3, 1.4, 0.05, 1.0)


## 致求生的意志：本应倒下的人身后张开一对半透明的白蝶大翅膀(从合着往后到展开、扇一下、淡掉)+ 一圈白蝶飞散；facing = 那个人的朝向
func will_live(at: Vector3, facing: float = 0.0, h: float = 1.3) -> void:
	soft_flash(at, Color("#fff6d8"), 1.3, 0.3, 2.2)
	ring(Vector3(at.x, 0.04, at.z), 0.9, Color("#ffe9a8"), 0.4, 1.4, 0.3)
	var s: float = maxf(0.2, speed_scale)
	var fwd := Vector3(sin(facing), 0.0, cos(facing))
	var right := Vector3(cos(facing), 0.0, -sin(facing))
	var bf: Butterfly = Butterfly.make("white", 6.5 * clampf(h / 1.3, 0.8, 1.6), true)
	bf.manual = true
	add_child(bf)
	var sz: float = bf.scale.x
	bf.global_position = at - fwd * 0.2 + Vector3(0.0, -0.05, 0.0)
	bf.basis = Basis(right, Vector3.UP.cross(right), Vector3.UP).scaled(Vector3.ONE * sz)
	bf.set_alpha(0.0)
	var tw := bf.create_tween().set_parallel(true)
	tw.tween_method(func(a: float) -> void:
		if is_instance_valid(bf):
			bf.set_wing(a), 1.35, 0.05, 0.22 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(bf.set_alpha, 0.0, 0.85, 0.12 / s)
	tw.chain().tween_method(func(a: float) -> void:
		if is_instance_valid(bf):
			bf.set_wing(a), 0.05, 0.75, 0.2 / s).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_method(func(a: float) -> void:
		if is_instance_valid(bf):
			bf.set_wing(a), 0.75, 0.0, 0.25 / s).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(bf, "global_position:y", bf.global_position.y + 0.25, 0.5 / s)
	tw.chain().tween_method(bf.set_alpha, 0.85, 0.0, 0.45 / s)
	tw.chain().tween_callback(bf.queue_free)
	ButterflyFlock.burst(self, at, 0, 7, 2.0, 1.4, 1.4, 1.3, 0.3, 0.6)


## 致将亡而未亡者(每一发)：一只蝴蝶(黑 / 白轮流)从她身上箭一样扑到送葬最多的那个敌人身上，打到时一小团
func butterfly_dart(from: Vector3, to: Vector3, kind: String) -> void:
	var s: float = maxf(0.2, speed_scale)
	var bf: Butterfly = Butterfly.make(kind, 1.5)
	bf.flap_hz = 9.5
	add_child(bf)
	bf.global_position = from
	var side: Vector3 = (to - from).cross(Vector3.UP)
	side = side.normalized() if side.length() > 0.01 else Vector3.RIGHT
	var mid: Vector3 = (from + to) * 0.5 + Vector3(0.0, 0.45, 0.0) + side * randf_range(-0.6, 0.6)
	var prev := [from]
	var tw := bf.create_tween()
	tw.tween_method(func(k: float) -> void:
		if not is_instance_valid(bf):
			return
		var p: Vector3 = from.lerp(mid, k).lerp(mid.lerp(to, k), k)
		bf.face(p - (prev[0] as Vector3))
		prev[0] = p
		bf.global_position = p, 0.0, 1.0, clampf(from.distance_to(to) / 14.0, 0.18, 0.4) / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void:
		soft_flash(to, ANGEL_WHITE if kind == "white" else Color("#b9a8e8"), 0.6, 0.18, 1.8)
		burst(to, ANGEL_DARK if kind == "black" else ANGEL_WHITE, 6, 1.8, 0.55, 0.6, 0.4, kind == "white")
		bf.queue_free())


## 她自己倒下：一群黑白蝴蝶从身上飞散(白的多)
func angel_fall(chest: Vector3) -> void:
	ButterflyFlock.burst(self, chest, 5, 9, 2.0, 1.5, 1.8, 1.3, 0.3, 0.8)
	soft_flash(chest, ANGEL_WHITE, 1.1, 0.3, 1.8)


# ---------------------------------------------------------------- 守林节点(荒野萨满)：变身 / 翠绿之林
const WARDEN_LEAVES: Array[Color] = [Color("#7fbf4a"), Color("#4f9a3a"), Color("#b4d870"), Color("#3d7a34"), Color("#d8c060")]
const WARDEN_FORM_COLS := {"lion": Color("#ffc65a"), "spider": Color("#b07aff"), "toad": Color("#5fd6a8"), "base": Color("#9fe07a")}


## 变身：一圈绿叶从脚下卷起来，裹住她又散开；地上一圈这个形态颜色的环(狮子金、巨蜘蛛紫、巨蟾蜍青绿、基础形态嫩绿)
func wild_shift(at: Vector3, height: float, form: String) -> void:
	var s: float = maxf(0.2, speed_scale)
	var c: Color = WARDEN_FORM_COLS.get(form, Color("#9fe07a"))
	ring(Vector3(at.x, 0.04, at.z), 1.5, c, 0.55, 1.8, 0.2)
	ring(Vector3(at.x, 0.05, at.z), 0.9, Color("#7fbf4a"), 0.45, 1.2, 0.2)
	soft_flash(at + Vector3(0, height * 0.55, 0), c, 1.5, 0.35, 2.0)
	for i in range(18):
		var p: MeshInstance3D = _petal(WARDEN_LEAVES[(i + randi()) % WARDEN_LEAVES.size()], randf_range(1.1, 1.6))
		add_child(p)
		var a0: float = TAU * float(i) / 18.0
		var r0: float = randf_range(0.45, 0.65)
		var h0: float = randf_range(0.05, 0.3)
		p.global_position = at + Vector3(cos(a0) * r0, h0, sin(a0) * r0)
		p.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		var lf: float = randf_range(0.55, 0.8) / s
		var tw: Tween = create_tween()
		tw.tween_method(_leaf_spiral.bind(p, at, a0, r0, h0, height * randf_range(0.9, 1.3)), 0.0, 1.0, lf).set_ease(Tween.EASE_OUT)
		tw.tween_callback(p.queue_free)
	burst(at + Vector3(0, height * 0.5, 0), c, 14, 2.4, 1.0, 1.0, 0.5)


func _leaf_spiral(k: float, p: MeshInstance3D, at: Vector3, a0: float, r0: float, h0: float, h1: float) -> void:
	if not is_instance_valid(p):
		return
	var a: float = a0 + k * 4.2
	var r: float = r0 * (1.0 - 0.45 * sin(k * PI)) + k * k * 0.8
	p.global_position = at + Vector3(cos(a) * r, lerpf(h0, h1, k), sin(a) * r)
	p.rotation += Vector3(0.21, 0.13, 0.17)
	p.scale = Vector3.ONE * (1.0 - k * 0.7)


## 翠绿之林：几片叶子从杖头飘落到她身上(加速)；回复的话脚下再冒一圈嫩绿
func verdant_grove(at: Vector3, heal: bool) -> void:
	petal_like_leaves(at + Vector3(0, 0.5, 0), 8)
	if heal:
		ring(Vector3(at.x, 0.04, at.z), 0.8, Color("#b4f08a"), 0.45, 1.2, 0.3)
	soft_flash(at, Color("#c8f0a0"), 0.9, 0.25, 1.6)


func petal_like_leaves(at: Vector3, count: int) -> void:
	var s: float = maxf(0.2, speed_scale)
	for i in range(count):
		var p: MeshInstance3D = _petal(WARDEN_LEAVES[(i + randi()) % WARDEN_LEAVES.size()], randf_range(0.9, 1.3))
		add_child(p)
		p.global_position = at + Vector3(randf_range(-0.3, 0.3), randf_range(0.0, 0.3), randf_range(-0.3, 0.3))
		p.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		var lf: float = randf_range(0.6, 0.9) / s
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(p, "global_position", p.global_position + Vector3(randf_range(-0.2, 0.2), -0.55, randf_range(-0.2, 0.2)), lf).set_trans(Tween.TRANS_SINE)
		tw.tween_property(p, "rotation", p.rotation + Vector3(randf_range(2.0, 4.0), randf_range(-2.0, 2.0), randf_range(2.0, 4.0)), lf)
		tw.tween_property(p, "scale", Vector3.ONE * 0.2, lf).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(p.queue_free)


## 变身形态的普攻命中(战斗视角下她的大头挡住身体，形态靠这个一眼分辨)：
##   lion   三道金白爪痕斜着划过目标胸口；spider 紫绿毒液溅开 + 几滴往下落；toad 一条粉红长舌从她嘴边弹到目标身上再收回
func beast_hit(form: String, from: Vector3, to: Vector3) -> void:
	var s: float = maxf(0.2, speed_scale)
	match form:
		"lion":
			var d: Vector3 = Vector3(to.x - from.x, 0.0, to.z - from.z).normalized()
			if d.length() < 0.01:
				d = Vector3(0, 0, 1)
			var side: Vector3 = d.cross(Vector3.UP).normalized()
			var mat: StandardMaterial3D = _emissive(Color("#fff0c0"), 3.2, 0.95).duplicate()
			for i in range(3):
				var m := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(0.035, 0.62, 0.02)
				m.mesh = bm
				m.material_override = mat
				m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				add_child(m)
				var c: Vector3 = to - d * 0.28 + side * (float(i) - 1.0) * 0.11
				m.global_transform = Transform3D(Basis.looking_at(d, Vector3.UP), c)
				m.rotate_object_local(Vector3(0, 0, 1), 0.6)
				m.scale = Vector3(1.0, 0.2, 1.0)
				var tw: Tween = create_tween().set_parallel(true)
				tw.tween_property(m, "scale", Vector3.ONE, 0.07 / s).set_ease(Tween.EASE_OUT)
				tw.chain().tween_property(m, "scale:x", 0.1, 0.18 / s)
				tw.tween_callback(m.queue_free).set_delay(0.26 / s)
			var tw2: Tween = create_tween()
			tw2.tween_property(mat, "albedo_color:a", 0.0, 0.26 / s).set_delay(0.06 / s)
			burst(to, Color("#ffd27a"), 6, 2.0, 0.8, 0.8, 0.35)
		"spider":
			burst(to, Color("#9a6bff"), 8, 1.8, 0.9, 0.6, 0.45)
			burst(to, Color("#8fe04a"), 6, 1.4, 0.8, -0.4, 0.55)
			ring(Vector3(to.x, 0.04, to.z), 0.55, Color("#9a6bff"), 0.35, 1.0, 0.3)
		"toad":
			var m2 := MeshInstance3D.new()
			var bm2 := BoxMesh.new()
			bm2.size = Vector3(0.07, 0.04, 1.0)
			m2.mesh = bm2
			m2.material_override = _emissive(Color("#ff7aa0"), 1.4, 1.0)
			m2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(m2)
			var tip := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.07
			sm.height = 0.12
			tip.mesh = sm
			tip.material_override = m2.material_override
			add_child(tip)
			var tw3: Tween = create_tween()
			tw3.tween_method(_tongue_set.bind(m2, tip, from, to), 0.0, 1.0, 0.07 / s)
			tw3.tween_interval(0.06 / s)
			tw3.tween_method(_tongue_set.bind(m2, tip, from, to), 1.0, 0.0, 0.12 / s)
			tw3.tween_callback(m2.queue_free)
			tw3.tween_callback(tip.queue_free)
			burst(to, Color("#ffb0c8"), 5, 1.4, 0.8, 0.5, 0.35)


func _tongue_set(k: float, m: MeshInstance3D, tip: MeshInstance3D, from: Vector3, to: Vector3) -> void:
	if not is_instance_valid(m) or not is_instance_valid(tip):
		return
	var end: Vector3 = from.lerp(to, k)
	var len: float = maxf(0.01, from.distance_to(end))
	var mid: Vector3 = (from + end) * 0.5
	if from.distance_to(to) > 0.01:
		m.global_transform = Transform3D(Basis.looking_at(to - from, Vector3.UP), mid)
	m.scale = Vector3(1.0, 1.0, len)
	tip.global_position = end


# ---------------------------------------------------------------- 导向节点(雷电魔导士)：连锁闪电 / 吟唱电光 / 麻痹 / 变天
const THUNDER := Color("#ffd84a")
const THUNDER_HOT := Color("#fffbe0")


## 一道立体的闪电(空中，不贴地)：a → b 折几下；外层金色光带 + 里面一条白芯，偶尔分出一小叉；life 秒内淡掉
func thunder_bolt(a: Vector3, b: Vector3, width: float = 0.07, life: float = 0.22, kinks: int = 6) -> void:
	var s: float = maxf(0.2, speed_scale)
	var dist: float = a.distance_to(b)
	if dist < 0.05:
		return
	var dir: Vector3 = (b - a) / dist
	var side: Vector3 = dir.cross(Vector3.UP)
	if side.length() < 0.1:
		side = Vector3.RIGHT
	side = side.normalized()
	var up: Vector3 = side.cross(dir).normalized()
	var pts: Array[Vector3] = [a]
	for i in range(1, kinks):
		var k: float = float(i) / float(kinks)
		var amp: float = minf(0.35, dist * 0.09) * sin(k * PI)
		pts.append(a.lerp(b, k) + side * randf_range(-1.0, 1.0) * amp + up * randf_range(-1.0, 1.0) * amp * 0.7)
	pts.append(b)
	var glow: StandardMaterial3D = _emissive(THUNDER, 3.0, 0.75).duplicate()
	var core: StandardMaterial3D = _emissive(THUNDER_HOT, 4.0, 1.0).duplicate()
	core.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var root := Node3D.new()
	add_child(root)
	for i in range(pts.size() - 1):
		for layer: Array in [[glow, width], [core, width * 0.38]]:
			_bolt_seg(root, pts[i], pts[i + 1], layer[0] as StandardMaterial3D, float(layer[1]))
		# 分叉
		if i > 0 and randf() < 0.35:
			var fork_end: Vector3 = pts[i] + (dir * randf_range(0.1, 0.3) + side * randf_range(-0.4, 0.4) + up * randf_range(-0.2, 0.3)).normalized() * randf_range(0.2, 0.45)
			_bolt_seg(root, pts[i], fork_end, glow, width * 0.5)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(glow, "albedo_color:a", 0.0, life / s).set_ease(Tween.EASE_IN)
	tw.tween_property(core, "albedo_color:a", 0.0, life * 0.8 / s).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(root.queue_free)


func _bolt_seg(root: Node3D, a: Vector3, b: Vector3, mat: StandardMaterial3D, width: float) -> void:
	var d: Vector3 = b - a
	var len: float = d.length()
	if len < 0.01:
		return
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, width, len + width * 0.5)
	m.mesh = bm
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(m)
	var upv: Vector3 = Vector3.UP if absf(d.normalized().dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	m.global_transform = Transform3D(Basis.looking_at(d / len, upv), (a + b) * 0.5)


## 连锁闪电的一跳(Battle 一跳一跳地结算，每跳发 chain_hop)：from → to 一道 travel 秒推过去的闪电(LightningArc：闪电头带着一团电光往前推)，
## 打中那一刻一团金色电火花 + 闪光 + 脚下一圈电弧环；之后整条闪电留在原地 1.1 秒忽明忽暗地跳(看得清整条链)，最后变细淡掉。
## first = 从她手里打出去的第一下(更粗、更亮)
func chain_hop(from: Vector3, to: Vector3, travel: float, first: bool) -> LightningArc:
	var arc: LightningArc = LightningArc.create(self, from, to, travel, 1.1, 0.11 if first else 0.09, 8)
	arc.on_hit = func() -> void:
		burst(to, THUNDER, 10, 2.8, 0.8, 0.6, 0.32)
		soft_flash(to, THUNDER, 1.1, 0.22, 2.4)
		ring(Vector3(to.x, 0.05, to.z), 0.75, THUNDER, 0.4, 1.4, 0.25)
	if first:
		soft_flash(from, THUNDER_HOT, 0.8, 0.18, 2.6)
	return arc


## 整条链传完：每一节一起再亮一下，每个被打中的人脚下再闪一圈(一眼看出这条链连了谁)
func chain_done(arcs: Array, nodes: Array) -> void:
	for a0: Variant in arcs:
		if is_instance_valid(a0):
			(a0 as LightningArc).pulse()
	for np: Variant in nodes:
		var p: Vector3 = np
		ring(Vector3(p.x, 0.05, p.z), 0.55, THUNDER_HOT, 0.35, 1.0, 0.5)


## 导向节点(引雷)的溅射：雷电炸开——中心一团白光、几道贴着地面往外窜到溅射半径的电弧、地上一圈电弧环和一块焦痕，
## 每个被溅到的人身上再跳过去一道细闪电。at = 爆心，r = 溅射半径，hits = 被溅到的人的胸口
func thunder_splash(at: Vector3, r: float, hits: Array) -> void:
	var g := Vector3(at.x, 0.0, at.z)
	soft_flash(at, THUNDER_HOT, 1.2 + 0.4 * r, 0.22, 2.6)
	ring(g + Vector3(0.0, 0.05, 0.0), r, THUNDER, 0.45, 1.2, 0.35)
	ring(g + Vector3(0.0, 0.06, 0.0), r * 0.6, THUNDER_HOT, 0.3, 0.8, 0.3)
	scorch(g, r * 0.55, THUNDER, 1.6)
	var n := 6
	var a0: float = randf() * TAU
	for i in range(n):
		var ang: float = a0 + TAU * (float(i) + randf_range(-0.25, 0.25)) / float(n)
		var to: Vector3 = g + Vector3(cos(ang), 0.0, sin(ang)) * r * randf_range(0.85, 1.05) + Vector3(0.0, 0.12, 0.0)
		LightningArc.create(self, at.lerp(g, 0.5) + Vector3(0.0, 0.1, 0.0), to, 0.07, 0.4, 0.045, 4)
	for hp: Variant in hits:
		var h: Vector3 = hp
		var arc: LightningArc = LightningArc.create(self, at, h, 0.09, 0.55, 0.055, 5)
		arc.on_hit = burst.bind(h, THUNDER, 5, 2.0, 0.6, 0.6, 0.25)


## 吟唱时身上噼啪作响：手边 / 身周跳几道短电弧
func volt_crackle(center: Vector3, hand: Vector3, k: float) -> void:
	for i in range(2 + int(k * 2.0)):
		var from: Vector3 = hand if i < 2 else center + Vector3(randf_range(-0.35, 0.35), randf_range(-0.3, 0.4), randf_range(-0.35, 0.35))
		var to: Vector3 = from + Vector3(randf_range(-1, 1), randf_range(-0.6, 1.0), randf_range(-1, 1)).normalized() * randf_range(0.25, 0.5 + 0.35 * k)
		thunder_bolt(from, to, 0.05 + 0.02 * k, 0.14, 3)
	soft_flash(hand, THUNDER, 0.5 + 0.6 * k, 0.12, 2.4)
	if randf() < 0.6:
		burst(hand, THUNDER, 4, 1.6, 0.6, 0.6, 0.22)


## 麻痹：身上一闪金色电光(施加时大一点；平时一小下)
func paralysis_zap(at: Vector3, big: bool) -> void:
	for i in range(3 if big else 1):
		var a: Vector3 = at + Vector3(randf_range(-0.25, 0.25), randf_range(-0.35, 0.3), randf_range(-0.25, 0.25))
		thunder_bolt(a, a + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf_range(0.2, 0.35), 0.03, 0.12, 3)
	if big:
		burst(at, THUNDER, 8, 2.0, 0.7, 0.5, 0.3)


# ---------------------------------------------------------------- 圣战节点(锤骑士)：裂地猛击 / 地形碎裂 / 圣疗
const PALADIN_BLUE := Color("#7fb4ff")
const PALADIN_GOLD := Color("#ffe08a")
const PALADIN_DEEP := Color("#2f6fe0")      # 普通混合的深蓝(白地上交代形状)
const STONE_COLS: Array[Color] = [Color("#8a8378"), Color("#6f685e"), Color("#a39b8e"), Color("#5c564e")]


## 裂地猛击的前摇(到砸地之前 impact 秒)：锥形范围的轮廓在地上淡淡亮起来(预告：两条边 + 外弧，深蓝普通混合 + 金色叠加)，
## 砸点先亮起一枚从大往小收的圣印(瞄准)，锤头上聚起一团蓝金色的圣光、光点往锤头里收。hammer = 每帧取锤头位置
func quake_windup(origin: Vector3, dir: Vector3, angle_deg: float, length: float, impact: float, hammer: Callable) -> void:
	var s: float = maxf(0.2, speed_scale)
	var d: Vector3 = Vector3(dir.x, 0.0, dir.z).normalized()
	if d.length() < 0.01:
		d = Vector3(0, 0, 1)
	var span: float = deg_to_rad(angle_deg)
	var b_flat: Basis = _cut_basis(d, Vector3.UP, 1.0)
	# 锥形的轮廓：外弧 + 两条边(细线)
	var outline := Node3D.new()
	add_child(outline)
	outline.global_position = origin + Vector3(0.0, 0.03, 0.0)
	var arc := MeshInstance3D.new()
	arc.mesh = _crescent(length, span, 0.08, 28)
	var am: ShaderMaterial = _cut_mat(PALADIN_GOLD, PALADIN_DEEP, 1.4)
	am.set_shader_parameter("head", 1.0)
	arc.material_override = am
	arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	outline.add_child(arc)
	arc.global_transform = Transform3D(b_flat, origin + Vector3(0.0, 0.03, 0.0))
	for sgn: float in [-1.0, 1.0]:
		var ed: Vector3 = d.rotated(Vector3.UP, sgn * span * 0.5)
		var e := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.05, 0.006, length - 0.4)
		e.mesh = bm
		e.material_override = _emissive(PALADIN_GOLD, 1.8, 0.7)
		e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		outline.add_child(e)
		e.global_transform = Transform3D(Basis.looking_at(ed, Vector3.UP), origin + ed * (0.4 + (length - 0.4) * 0.5) + Vector3(0.0, 0.03, 0.0))
	outline.scale = Vector3(1.0, 1.0, 1.0)
	var tw0: Tween = create_tween()
	tw0.tween_method(func(x: float) -> void: am.set_shader_parameter("fade", x), 0.0, 0.8, impact * 0.6 / s)
	tw0.tween_interval(impact * 0.4 / s)
	tw0.tween_method(func(x: float) -> void: am.set_shader_parameter("fade", x), 0.8, 0.0, 0.25 / s)
	tw0.tween_callback(outline.queue_free)
	# 砸点：一枚从大往小收的圣印(蓝金)
	var hit: Vector3 = origin + d * 0.9
	var seal := Node3D.new()
	add_child(seal)
	seal.global_position = Vector3(hit.x, 0.04, hit.z)
	var sm: Array = holy_seal(seal, "Seal", 2.0, 0.3)
	(sm[0] as ShaderMaterial).set_shader_parameter("col", PALADIN_BLUE)
	(sm[0] as ShaderMaterial).set_shader_parameter("hot", PALADIN_GOLD)
	(sm[1] as ShaderMaterial).set_shader_parameter("col", PALADIN_DEEP)
	(sm[1] as ShaderMaterial).set_shader_parameter("hot", PALADIN_DEEP)
	seal.scale = Vector3.ONE * 1.6
	var tw1: Tween = create_tween().set_parallel(true)
	tw1.tween_property(seal, "scale", Vector3.ONE * 0.75, impact / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw1.tween_property(seal, "rotation:y", PI * 0.6, impact / s)
	tw1.chain().tween_callback(seal.queue_free)
	# 锤头：一团聚起来的蓝金色光，光点往里收
	var orb := MeshInstance3D.new()
	orb.mesh = SoftFX.quad()
	orb.material_override = SoftFX.sprite_mat(PALADIN_BLUE.lerp(Color.WHITE, 0.3), 2.2)
	orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	orb.scale = Vector3.ONE * 0.2
	add_child(orb)
	var start: Vector3 = hammer.call() if hammer.is_valid() else origin + Vector3(0, 1.5, 0)
	orb.global_position = start
	var tw2: Tween = create_tween()
	tw2.tween_method(func(k: float) -> void:
		if not is_instance_valid(orb):
			return
		if hammer.is_valid():
			orb.global_position = hammer.call()
		orb.scale = Vector3.ONE * lerpf(0.2, 0.75, k)
		if randf() < 0.5:
			var from: Vector3 = orb.global_position + Vector3(randf_range(-1, 1), randf_range(-0.5, 1), randf_range(-1, 1)).normalized() * 0.6
			_converge_mote(from, orb), 0.0, 1.0, impact / s)
	tw2.tween_callback(orb.queue_free)


func _converge_mote(from: Vector3, to_node: Node3D) -> void:
	var m := MeshInstance3D.new()
	m.mesh = _box
	m.material_override = _emissive(PALADIN_GOLD, 2.4)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.scale = Vector3.ONE * 0.6
	add_child(m)
	m.global_position = from
	var s: float = maxf(0.2, speed_scale)
	var tw: Tween = create_tween()
	var tref: WeakRef = weakref(to_node)              # 锤头那团光先没了也别报错(lambda 不直接抓节点)
	var last := [from]
	tw.tween_method(func(k: float) -> void:
		if not is_instance_valid(m):
			return
		var tn: Node3D = tref.get_ref() as Node3D
		if tn != null:
			last[0] = tn.global_position
		m.global_position = from.lerp(last[0] as Vector3, k * k)
		m.scale = Vector3.ONE * 0.6 * (1.0 - k * 0.7), 0.0, 1.0, 0.16 / s)
	tw.tween_callback(m.queue_free)


## 裂地猛击：锤子砸地的那一刻——
##   砸点：一闪白光 + 一枚盖在地上的蓝金圣印(日轮十字，慢慢淡掉)+ 一个焦黑的坑
##   扇面：一道蓝金光弧贴着地面往外推，经过的地方一排排碎石从地里蹦起来(越远越晚：地面像波浪一样翻起来)、扬起尘土；
##        扇面里裂开几道发着金光的裂缝(慢慢暗下去)，裂缝上冒出几根细细的光柱
##   origin = 他的脚下，dir = 锥形朝向，angle 度、length 米
func quake_slam(origin: Vector3, dir: Vector3, angle_deg: float, length: float) -> void:
	var s: float = maxf(0.2, speed_scale)
	var d: Vector3 = Vector3(dir.x, 0.0, dir.z).normalized()
	if d.length() < 0.01:
		d = Vector3(0, 0, 1)
	var span: float = deg_to_rad(angle_deg)
	var b_flat: Basis = _cut_basis(d, Vector3.UP, 1.0)
	var hit: Vector3 = origin + d * 0.9
	# 砸点：白光 + 圣印 + 焦坑
	soft_flash(hit + Vector3(0, 0.35, 0), Color("#eaf3ff"), 1.5, 0.25, 2.2)
	soft_flash(hit + Vector3(0, 0.2, 0), PALADIN_GOLD, 1.4, 0.4, 2.0)
	var seal := Node3D.new()
	add_child(seal)
	seal.global_position = Vector3(hit.x, 0.04, hit.z)
	var sm: Array = holy_seal(seal, "Seal", 0.6, 0.45)
	(sm[0] as ShaderMaterial).set_shader_parameter("col", PALADIN_BLUE)
	(sm[0] as ShaderMaterial).set_shader_parameter("hot", PALADIN_GOLD)
	(sm[1] as ShaderMaterial).set_shader_parameter("col", PALADIN_DEEP)
	(sm[1] as ShaderMaterial).set_shader_parameter("hot", PALADIN_DEEP)
	seal.scale = Vector3.ONE * 0.5
	var tws: Tween = create_tween().set_parallel(true)
	tws.tween_property(seal, "scale", Vector3.ONE * 1.25, 0.25 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tws.tween_method(func(x: float) -> void:
		(sm[0] as ShaderMaterial).set_shader_parameter("fade", x)
		(sm[1] as ShaderMaterial).set_shader_parameter("fade", x * 0.45), 1.0, 0.0, 1.2 / s).set_delay(0.3 / s).set_ease(Tween.EASE_IN)
	tws.chain().tween_callback(seal.queue_free)
	scorch(Vector3(hit.x, 0.0, hit.z), 0.55, PALADIN_GOLD, 2.2)
	# 扇面贴地亮一下(白芯、蓝金边)
	var fan := MeshInstance3D.new()
	fan.mesh = _crescent((length + 0.2) * 0.5, span, length - 0.2, 26)
	var fm: ShaderMaterial = _cut_mat(Color("#eaf3ff"), PALADIN_DEEP, 0.9)
	fm.set_shader_parameter("head", 1.0)
	fan.material_override = fm
	fan.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(fan)
	fan.global_transform = Transform3D(b_flat, origin + Vector3(0.0, 0.04, 0.0))
	var tw0: Tween = create_tween()
	tw0.tween_method(func(x: float) -> void: fm.set_shader_parameter("fade", x), 0.0, 0.7, 0.05 / s)
	tw0.tween_method(func(x: float) -> void: fm.set_shader_parameter("fade", x), 0.7, 0.0, 0.5 / s).set_ease(Tween.EASE_IN)
	tw0.tween_callback(fan.queue_free)
	# 往外推的光弧(三道：金 → 白 → 蓝，一道比一道晚)
	for k in range(3):
		var w := MeshInstance3D.new()
		w.mesh = _crescent(1.0, span, 0.24, 26)
		var wm: ShaderMaterial = _cut_mat(PALADIN_GOLD if k == 0 else (Color("#eaf3ff") if k == 1 else PALADIN_BLUE), PALADIN_DEEP, 2.2 - 0.4 * float(k))
		w.material_override = wm
		w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(w)
		w.global_transform = Transform3D(b_flat, origin + Vector3(0.0, 0.12 + 0.05 * float(k), 0.0))
		w.scale = Vector3(0.4, 0.4, 1.0)
		var tw1: Tween = create_tween().set_parallel(true)
		var dl: float = 0.07 * float(k) / s
		tw1.tween_property(w, "scale", Vector3(length, length, 1.0 + float(k) * 0.4), 0.34 / s).set_delay(dl).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw1.tween_method(func(x: float) -> void: wm.set_shader_parameter("fade", x), 1.0, 0.0, 0.34 / s).set_delay(dl + 0.12 / s).set_ease(Tween.EASE_IN)
		tw1.chain().tween_callback(w.queue_free)
	# 地面翻起来：一排排碎石(越远越晚)
	var rows: int = int(ceil((length - 0.6) / 0.38))
	for r in range(rows):
		var dist: float = 0.7 + 0.38 * float(r)
		var delay: float = dist / 11.0
		var n: int = 2 + int(dist * 0.9)
		for i in range(n):
			var a: float = lerpf(-span * 0.46, span * 0.46, (float(i) + randf_range(0.1, 0.9)) / float(n))
			var p: Vector3 = origin + d.rotated(Vector3.UP, a) * (dist + randf_range(-0.12, 0.12))
			get_tree().create_timer(delay / s).timeout.connect(_quake_rock.bind(p, randf_range(0.7, 1.25) * (1.25 - 0.4 * dist / length)))
		if r % 2 == 0:
			var pd: Vector3 = origin + d * dist
			get_tree().create_timer(delay / s).timeout.connect(burst.bind(pd + Vector3(0, 0.1, 0), Color("#c9c0b2"), 6, 1.8, 1.4, 0.9, 0.7, false))
	# 发金光的裂缝(慢慢暗下去)，裂缝上冒几根细光柱
	for i in range(7):
		var a2: float = lerpf(-span * 0.45, span * 0.45, (float(i) + randf_range(-0.3, 0.3)) / 6.0)
		var cd: Vector3 = d.rotated(Vector3.UP, a2)
		var from: Vector3 = hit + cd * 0.1
		var to: Vector3 = hit + cd * (length - 0.9) * randf_range(0.55, 1.0)
		var mid: Vector3 = from.lerp(to, 0.5) + cd.cross(Vector3.UP) * randf_range(-0.22, 0.22)
		_glow_crack(from, mid, 0.08)
		_glow_crack(mid, to, 0.06)
		if i % 2 == 0:
			get_tree().create_timer((0.08 + 0.05 * float(i)) / s).timeout.connect(_crack_beam.bind(mid.lerp(to, randf_range(0.2, 0.8))))
	burst(hit + Vector3(0, 0.15, 0), Color("#8f877c"), 18, 3.4, 1.3, 1.6, 0.8, false)
	fire_puff(hit + Vector3(0, 0.15, 0), Color("#cfc6b6"), 12, 0.55, 2.4, 0.8, 0.4, false)
	ring(Vector3(hit.x, 0.05, hit.z), 1.4, PALADIN_GOLD, 0.45, 1.8, 0.2)
	ring(Vector3(origin.x, 0.05, origin.z), length * 0.9, PALADIN_DEEP, 0.55, 1.2, 0.3)


## 一块从地里蹦起来的碎石(体素方块：蹦高、翻滚、落回去碎掉)
func _quake_rock(at: Vector3, k: float) -> void:
	var s: float = maxf(0.2, speed_scale)
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var sz: float = randf_range(0.1, 0.2) * k
	bm.size = Vector3(sz, sz * randf_range(0.7, 1.1), sz * randf_range(0.8, 1.2))
	m.mesh = bm
	m.material_override = _solid(STONE_COLS[randi() % STONE_COLS.size()])
	add_child(m)
	m.global_position = Vector3(at.x, -sz * 0.5, at.z)
	m.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
	var peak: float = randf_range(0.35, 0.75) * k
	var drift := Vector3(randf_range(-0.15, 0.15), 0.0, randf_range(-0.15, 0.15))
	var lf: float = randf_range(0.42, 0.55) / s
	var p0: Vector3 = m.global_position
	var spin := Vector3(randf_range(-6, 6), randf_range(-6, 6), randf_range(-6, 6))
	var tw: Tween = create_tween()
	tw.tween_method(func(u: float) -> void:
		if not is_instance_valid(m):
			return
		m.global_position = p0 + drift * u + Vector3(0.0, 4.0 * peak * u * (1.0 - u) + sz * 0.5 * u, 0.0)
		m.rotation = spin * u, 0.0, 1.0, lf)
	tw.tween_property(m, "scale", Vector3.ONE * 0.01, 0.25 / s).set_delay(0.3 / s)
	tw.tween_callback(m.queue_free)


## 发着金光的裂缝：一道深色的缝 + 缝里一条金蓝色的光(慢慢暗下去)
func _glow_crack(from: Vector3, to: Vector3, width: float) -> void:
	var d: Vector3 = to - from
	d.y = 0.0
	var len: float = d.length()
	if len < 0.1:
		return
	var s: float = maxf(0.2, speed_scale)
	var basis := Basis.looking_at(d.normalized(), Vector3.UP)
	var mid: Vector3 = (from + to) * 0.5
	for layer: Array in [[Color("#2a2622"), width, 0.75, 0.02, false], [PALADIN_GOLD, width * 0.45, 1.0, 0.026, true]]:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(float(layer[1]), 0.006, len)
		m.mesh = bm
		var mat: StandardMaterial3D
		if bool(layer[4]):
			mat = _emissive(layer[0], 2.6, 1.0).duplicate() as StandardMaterial3D
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		else:
			mat = StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = layer[0]
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = float(layer[2])
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		m.global_transform = Transform3D(basis, Vector3(mid.x, float(layer[3]), mid.z))
		var tw: Tween = create_tween()
		tw.tween_property(mat, "albedo_color:a", 0.0, (1.6 if bool(layer[4]) else 2.0) / s).set_delay(0.35 / s).set_ease(Tween.EASE_IN)
		tw.tween_callback(m.queue_free)


## 裂缝里冒出来的一根细光柱(蓝白，往上冲、变细淡掉)
func _crack_beam(at: Vector3) -> void:
	var s: float = maxf(0.2, speed_scale)
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = 0.09
	cm.height = 1.8
	cm.radial_segments = 8
	m.mesh = cm
	var mat: StandardMaterial3D = _emissive(Color("#eaf3ff"), 2.6, 0.75).duplicate() as StandardMaterial3D
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	m.global_position = Vector3(at.x, 0.9, at.z)
	m.scale = Vector3(1.0, 0.1, 1.0)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(m, "scale", Vector3(1.0, 1.0, 1.0), 0.12 / s).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "scale:x", 0.1, 0.4 / s).set_delay(0.12 / s)
	tw.tween_property(m, "scale:z", 0.1, 0.4 / s).set_delay(0.12 / s)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.4 / s).set_delay(0.12 / s)
	tw.chain().tween_callback(m.queue_free)
	burst(Vector3(at.x, 0.1, at.z), PALADIN_GOLD, 4, 1.4, 0.5, 1.6, 0.4)


## 地形被打碎：一团石块从它身上炸开 + 尘土(颜色按地形：燃烧废墟带火星、寒雾是冰屑)
func terrain_shatter(at: Vector3, size: float, kind: String) -> void:
	var stone: Color = Color("#d6e6f2") if kind == "ice" else Color("#857d72")
	burst(at + Vector3(0, 0.4 * size, 0), stone, int(16 * size), 3.0, 1.5, 1.8, 0.9, false)
	burst(at + Vector3(0, 0.1, 0), Color("#c9c0b2") if kind != "ice" else Color("#eef6ff"), int(12 * size), 2.0, 2.0, 0.8, 1.1, false)
	if kind == "burning":
		burst(at + Vector3(0, 0.5, 0), Color(1.0, 0.55, 0.15), 14, 2.6, 0.8, 1.6, 0.5)


## 圣疗：对方头顶亮起一枚蓝金色的日轮十字(体素：外圈 + 十字 + 八道光芒)，往下洒一道光落在身上，
## 脚下一圈蓝金光环、身上往上飘的光点；from = 圣战节点的胸口(一道细光从他身上连过去)
func holy_mend(at: Vector3, from: Vector3 = Vector3.INF) -> void:
	var s: float = maxf(0.2, speed_scale)
	var emb := Node3D.new()
	add_child(emb)
	emb.global_position = at + Vector3(0, 0.95, 0)
	var gm: StandardMaterial3D = _emissive(PALADIN_GOLD, 2.4, 1.0).duplicate() as StandardMaterial3D
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	var tm := TorusMesh.new()
	tm.inner_radius = 0.2
	tm.outer_radius = 0.24
	tm.rings = 24
	tm.ring_segments = 4
	var rm := MeshInstance3D.new()
	rm.mesh = tm
	rm.material_override = gm
	rm.rotation.x = PI * 0.5
	emb.add_child(rm)
	for sz: Vector3 in [Vector3(0.055, 0.42, 0.04), Vector3(0.42, 0.055, 0.04)]:
		var cmi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = sz
		cmi.mesh = bm
		cmi.material_override = gm
		emb.add_child(cmi)
	for i in range(8):
		var ray := MeshInstance3D.new()
		var rb := BoxMesh.new()
		rb.size = Vector3(0.03, 0.1, 0.03)
		ray.mesh = rb
		ray.material_override = gm
		var a: float = TAU * float(i) / 8.0 + PI / 8.0
		ray.position = Vector3(cos(a), sin(a), 0.0) * 0.32
		ray.rotation.z = a - PI * 0.5
		emb.add_child(ray)
	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() != null else null
	if cam != null:
		var to: Vector3 = cam.global_position - emb.global_position
		emb.rotation.y = atan2(to.x, to.z)
	emb.scale = Vector3.ONE * 0.3
	var tw: Tween = create_tween()
	tw.tween_property(emb, "scale", Vector3.ONE * 1.05, 0.18 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(emb, "rotation:z", 0.4, 0.4 / s)
	tw.parallel().tween_property(emb, "global_position:y", emb.global_position.y - 0.25, 0.4 / s)
	tw.tween_property(gm, "albedo_color:a", 0.0, 0.3 / s)
	tw.tween_callback(emb.queue_free)
	get_tree().create_timer(0.18 / s).timeout.connect(func() -> void:
		pillar(Vector3(at.x, 0.0, at.z), PALADIN_BLUE.lerp(Color.WHITE, 0.4), 0.6)
		soft_flash(at, PALADIN_GOLD, 1.1, 0.3, 2.0)
		ring(Vector3(at.x, 0.05, at.z), 0.9, PALADIN_GOLD, 0.45, 1.4, 0.3)
		ring(Vector3(at.x, 0.06, at.z), 0.6, PALADIN_DEEP, 0.4, 1.0, 0.3)
		float_icons(at + Vector3(0, 0.1, 0), cross_mesh(), PALADIN_GOLD, 4, 0.3, 0.9, 1.0))
	if from != Vector3.INF:
		tracer(from, at, 0.06, 0.3, Color("#eaf3ff"), PALADIN_BLUE)


# ---------------------------------------------------------------- 巧运节点：妙手的金币 / 钱袋
const COIN_GOLD := Color("#ffc93a")
var _coin_mesh: CylinderMesh = null


## 一枚金币从 at 弹起来、翻着跟头落下(妙手摸到金币 / 钱袋进账)
func coin_pop(at: Vector3, count: int = 1, spread: float = 0.25) -> void:
	var s: float = maxf(0.2, speed_scale)
	if _coin_mesh == null:
		_coin_mesh = CylinderMesh.new()
		_coin_mesh.top_radius = 0.075
		_coin_mesh.bottom_radius = 0.075
		_coin_mesh.height = 0.02
		_coin_mesh.radial_segments = 12
	for i in range(count):
		var m := MeshInstance3D.new()
		m.mesh = _coin_mesh
		m.material_override = _emissive(COIN_GOLD, 1.6)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		var p0: Vector3 = at + Vector3(randf_range(-spread, spread) * float(mini(count - 1, 1)), 0.0, randf_range(-spread, spread) * float(mini(count - 1, 1)))
		m.global_position = p0
		var peak: Vector3 = p0 + Vector3(randf_range(-0.15, 0.15), randf_range(0.55, 0.75), randf_range(-0.15, 0.15))
		var land: Vector3 = peak + Vector3(randf_range(-0.1, 0.1), -0.35, randf_range(-0.1, 0.1))
		var lf: float = randf_range(0.5, 0.65) / s
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(m, "global_position", peak, lf * 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD).set_delay(0.04 * float(i) / s)
		tw.tween_property(m, "rotation:x", TAU * 3.0, lf).set_delay(0.04 * float(i) / s)
		tw.chain().tween_property(m, "global_position", land, lf * 0.55).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.chain().tween_property(m, "scale", Vector3.ONE * 0.05, 0.12 / s)
		tw.chain().tween_callback(m.queue_free)
	burst(at + Vector3(0, 0.3, 0), COIN_GOLD, 4 + count, 1.4, 0.5, 1.2, 0.35)


# ---------------------------------------------------------------- 心连节点(人偶修女)：量产复制 / 治疗祈愿 / 奇迹
const SISTER_NAVY := Color("#3b4fa8")
const SISTER_GOLD := Color("#f2cf6a")


## 量产型号：复制品出场——脚下一圈齿轮状的金环转着收拢，几片金色碎屑和一道淡蓝光柱
func clockwork_copy(at: Vector3) -> void:
	var s: float = maxf(0.2, speed_scale)
	ring(Vector3(at.x, 0.04, at.z), 1.1, SISTER_GOLD, 0.5, 1.4, 1.0)
	ring(Vector3(at.x, 0.05, at.z), 0.7, SISTER_NAVY.lightened(0.3), 0.45, 1.0, 1.2)
	pillar(Vector3(at.x, 0.0, at.z), SISTER_NAVY.lightened(0.45), 0.5)
	# 齿：一圈小方块绕着转、往里收
	for i in range(10):
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.08, 0.05, 0.12)
		m.mesh = bm
		m.material_override = _emissive(SISTER_GOLD, 1.8)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		var a0: float = TAU * float(i) / 10.0
		m.global_position = at + Vector3(cos(a0) * 0.9, 0.08, sin(a0) * 0.9)
		m.rotation.y = -a0
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_method(func(k: float) -> void:
			if is_instance_valid(m):
				var a: float = a0 + k * 2.4
				var r: float = lerpf(0.9, 0.35, k)
				m.global_position = at + Vector3(cos(a) * r, 0.08 + k * 0.5, sin(a) * r)
				m.rotation.y = -a
				m.scale = Vector3.ONE * (1.0 - k * 0.8), 0.0, 1.0, 0.5 / s)
		tw.chain().tween_callback(m.queue_free)
	burst(at + Vector3(0, 0.5, 0), SISTER_GOLD, 8, 1.6, 0.6, 1.0, 0.4)


## 治疗祈愿：对方身上一小圈蓝金光点往上飘
func prayer_glow(at: Vector3) -> void:
	soft_flash(at, SISTER_GOLD, 0.8, 0.25, 1.8)
	burst(at, SISTER_NAVY.lightened(0.5), 6, 1.0, 0.6, 1.6, 0.6)


## 奇迹：倒下的人身上升起一枚金十字(镶蓝宝石)，金光一闪
func miracle_cross(at: Vector3) -> void:
	var s: float = maxf(0.2, speed_scale)
	var cross := Node3D.new()
	add_child(cross)
	cross.global_position = at + Vector3(0, 0.6, 0)
	var cm: StandardMaterial3D = _emissive(SISTER_GOLD, 2.4, 0.95).duplicate()
	for sz: Vector3 in [Vector3(0.1, 0.6, 0.1), Vector3(0.38, 0.1, 0.1)]:
		var m := MeshInstance3D.new()
		var b0 := BoxMesh.new()
		b0.size = sz
		m.mesh = b0
		m.material_override = cm
		m.position = Vector3(0, 0.1 if sz.y < 0.2 else 0.0, 0)
		cross.add_child(m)
	var gem := MeshInstance3D.new()
	var gb := BoxMesh.new()
	gb.size = Vector3(0.09, 0.09, 0.12)
	gem.mesh = gb
	gem.material_override = _emissive(Color("#4f8cff"), 3.0)
	gem.position = Vector3(0, 0.1, 0)
	cross.add_child(gem)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(cross, "global_position:y", at.y + 1.8, 1.2 / s).set_ease(Tween.EASE_OUT)
	tw.tween_property(cross, "rotation:y", TAU, 1.2 / s)
	tw.tween_property(cm, "albedo_color:a", 0.0, 1.2 / s).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(cross.queue_free)
	soft_flash(at, SISTER_GOLD, 1.6, 0.4, 2.4)
	ring(Vector3(at.x, 0.05, at.z), 1.3, SISTER_GOLD, 0.6, 1.4, 0.2)


# ---------------------------------------------------------------- 无我节点(咒刃武士)：逆时幻影 / 斩断
const PHANTOM_VIOLET := Color("#9b6bff")
const SEVER_RED := Color("#c2203a")


## 逆时幻影出现：脚下一圈紫色钟面光环(刻度) + 光环逆着转、收拢
func phantom_rewind(at: Vector3) -> void:
	var s: float = maxf(0.2, speed_scale)
	ring(Vector3(at.x, 0.04, at.z), 1.0, PHANTOM_VIOLET, 0.5, 1.4, 1.0)
	for i in range(12):
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.04, 0.03, 0.16)
		m.mesh = bm
		m.material_override = _emissive(PHANTOM_VIOLET.lightened(0.3), 2.0, 0.9)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		var a0: float = TAU * float(i) / 12.0
		var tw: Tween = create_tween()
		tw.tween_method(func(k: float) -> void:
			if is_instance_valid(m):
				var a: float = a0 - k * 1.6
				var r: float = lerpf(0.85, 0.3, k)
				m.global_position = at + Vector3(cos(a) * r, 0.05 + k * 0.6, sin(a) * r)
				m.rotation.y = -a
				m.scale = Vector3.ONE * (1.0 - k * 0.85), 0.0, 1.0, 0.45 / s)
		tw.tween_callback(m.queue_free)
	soft_flash(at + Vector3(0, 0.7, 0), PHANTOM_VIOLET, 1.2, 0.3, 2.0)


## 斩断(杀 / 无我)：召唤物 = 一道黑紫的十字刀痕 + 碎成紫色光点；否则一道暗红的斜刀痕 + 血色碎屑(生命上限被削掉)
func sever_mark(at: Vector3, erase: bool) -> void:
	var c: Color = PHANTOM_VIOLET if erase else SEVER_RED
	var d := Vector3(1, 0, 0).rotated(Vector3.UP, randf() * TAU)
	slash(at, d, c, 1.4)
	if erase:
		slash(at, d.rotated(Vector3.UP, PI * 0.5), c, 1.4)
		burst(at, PHANTOM_VIOLET, 14, 2.4, 0.7, 1.0, 0.5)
	else:
		burst(at, SEVER_RED, 10, 2.0, 0.7, 0.4, 0.45)
	soft_flash(at, c, 0.9, 0.2, 2.2)


## 无我·一闪：拔刀那一刻，一道巨大的新月刀光贴着胸口的高度从她身前横扫过整个战场(白芯紫边，0.14 秒扫开，再淡掉)
func iai_sweep(origin: Vector3, dir: Vector3, reach: float) -> void:
	var s: float = maxf(0.2, speed_scale)
	var d: Vector3 = Vector3(dir.x, 0.0, dir.z).normalized() if Vector3(dir.x, 0.0, dir.z).length() > 0.01 else Vector3(0, 0, 1)
	for k in range(2):
		var w := MeshInstance3D.new()
		w.mesh = _crescent(1.0, deg_to_rad(170.0), 0.06 if k == 0 else 0.16, 40)
		var wm: ShaderMaterial = _cut_mat(Color("#ffffff") if k == 0 else Color("#e8dcff"), PHANTOM_VIOLET, 3.0 - float(k))
		wm.set_shader_parameter("head", 1.0)
		w.material_override = wm
		w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(w)
		w.global_transform = Transform3D(_cut_basis(d, Vector3.UP, 1.0), origin + Vector3(0.0, 0.95 - 0.05 * float(k), 0.0))
		w.scale = Vector3(0.6, 0.6, 1.0)
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(w, "scale", Vector3(reach, reach, 1.0), 0.14 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		tw.tween_method(func(x: float) -> void: wm.set_shader_parameter("fade", x), 1.0, 0.0, 0.5 / s).set_delay(0.12 / s).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(w.queue_free)
	soft_flash(origin + Vector3(0, 1.0, 0) + d * 0.4, Color("#f4eeff"), 2.2, 0.3, 2.6)


## 无我·迟来的刀痕：被斩开的人身上一道细长的白线(斜着，0.06 秒划开)，一直留到 hold 秒后——然后人崩散(cut_shatter)
func iai_cut_line(at: Vector3, hold: float) -> void:
	var s: float = maxf(0.2, speed_scale)
	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() != null else null
	var right := Vector3.RIGHT
	var up := Vector3.UP
	if cam != null:
		var fwd: Vector3 = (cam.global_position - at).normalized()
		right = Vector3.UP.cross(fwd).normalized()
		up = fwd.cross(right).normalized()
	var ang: float = randf_range(0.35, 0.75) * (1.0 if randf() < 0.5 else -1.0)
	var ld: Vector3 = (right * cos(ang) + up * sin(ang)).normalized()
	var root := Node3D.new()
	add_child(root)
	root.global_position = at
	for layer: Array in [[0.06, Color("#9b6bff"), 2.4, 0.7], [0.022, Color("#ffffff"), 3.2, 1.0]]:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.2, float(layer[0]), float(layer[0]))
		m.mesh = bm
		m.material_override = _emissive(layer[1], float(layer[2]), float(layer[3]))
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(m)
	var fwd2: Vector3 = ld.cross(up).normalized() if absf(ld.dot(up)) < 0.99 else Vector3.FORWARD
	root.global_transform = Transform3D(Basis(ld, ld.cross(fwd2).normalized() * -1.0, fwd2).orthonormalized(), at)
	root.scale = Vector3(0.02, 1.0, 1.0)
	var tw: Tween = create_tween()
	tw.tween_property(root, "scale", Vector3(1.0, 1.0, 1.0), 0.06 / s).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(0.0, hold - 0.06) / s)
	tw.tween_callback(func() -> void:
		cut_shatter(at)
		root.queue_free())


## 崩散：被斩开的人碎成一把黑紫的碎片 + 白色的刃光碎点，往两边炸开
func cut_shatter(at: Vector3) -> void:
	soft_flash(at, Color("#f4eeff"), 1.1, 0.18, 2.4)
	burst(at, Color("#1a1320"), 14, 2.6, 1.0, 0.8, 0.6, false)
	burst(at, PHANTOM_VIOLET, 12, 3.0, 0.7, 1.0, 0.5)
	burst(at, Color("#ffffff"), 6, 3.4, 0.45, 0.6, 0.3)


## 无我对精英 / 首领：一道又长又重的暗红刀痕斜劈过身体 + 往下滴的血色碎屑 + "−N% 上限"
func selfless_scar(at: Vector3, pct: float) -> void:
	var d := Vector3(1, 0, 0).rotated(Vector3.UP, randf() * TAU)
	slash(at, d, SEVER_RED, 2.0)
	slash(at + Vector3(0, 0.08, 0), d, Color("#ffffff"), 1.4)
	burst(at, SEVER_RED, 18, 2.4, 0.8, 0.3, 0.6)
	soft_flash(at, SEVER_RED, 1.4, 0.25, 2.2)
	number(at + Vector3(0, 0.7, 0), "-%d%%" % int(round(pct * 100.0)), Color("#ff6b7a"), 1.1, 0.9, 1.3)


## 逆时幻影脚下一直转着的钟面：一圈紫色的刻度环 + 两根指针(逆着转：时间在往回走)；挂在幻影的视图上
func phantom_clock(parent: Node3D, r: float) -> Node3D:
	var root := Node3D.new()
	root.name = "PhantomClock"
	parent.add_child(root)
	root.position.y = 0.04
	var tm := TorusMesh.new()
	tm.inner_radius = r - 0.03
	tm.outer_radius = r
	tm.rings = 40
	tm.ring_segments = 4
	var rim := MeshInstance3D.new()
	rim.mesh = tm
	rim.scale = Vector3(1.0, 0.25, 1.0)
	rim.material_override = _emissive(PHANTOM_VIOLET, 2.2, 0.85)
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(rim)
	var face := Node3D.new()
	root.add_child(face)
	for i in range(12):
		var a: float = TAU * float(i) / 12.0
		var tk := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.025, 0.01, 0.1 if i % 3 == 0 else 0.055)
		tk.mesh = bm
		tk.material_override = _emissive(Color("#d6c4ff"), 2.4, 0.9)
		tk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tk.position = Vector3(sin(a), 0.0, cos(a)) * (r - 0.09)
		tk.rotation.y = a
		face.add_child(tk)
	for hl: Array in [[0.55, 0.035], [0.8, 0.025]]:
		var hand_root := Node3D.new()
		face.add_child(hand_root)
		var hm := MeshInstance3D.new()
		var hb := BoxMesh.new()
		hb.size = Vector3(float(hl[1]), 0.012, r * float(hl[0]))
		hm.mesh = hb
		hm.material_override = _emissive(Color("#efe6ff"), 2.6, 0.95)
		hm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hm.position = Vector3(0.0, 0.01, r * float(hl[0]) * 0.5)
		hand_root.add_child(hm)
		var twh: Tween = hand_root.create_tween().set_loops()
		twh.tween_property(hand_root, "rotation:y", -TAU, 1.6 if float(hl[0]) > 0.7 else 6.0).from(0.0)
	var tw: Tween = face.create_tween().set_loops()
	tw.tween_property(face, "rotation:y", -TAU, 9.0).from(0.0)
	return root


## 逆时幻影的一刀：紫色刀痕 + 两道晚一点、淡一点、错开一点的回声(时间的残响)
func phantom_echo(at: Vector3, dir: Vector3) -> void:
	slash(at, dir, PHANTOM_VIOLET, 1.1)
	var s: float = maxf(0.2, speed_scale)
	for i in range(2):
		var off := Vector3(randf_range(-0.12, 0.12), 0.06 * float(i + 1), randf_range(-0.12, 0.12))
		get_tree().create_timer((0.08 + 0.08 * float(i)) / s).timeout.connect(slash.bind(at + off, dir.rotated(Vector3.UP, 0.25 * float(i + 1)), Color("#c9b0ff"), 0.8 - 0.2 * float(i)))
	burst(at, PHANTOM_VIOLET, 4, 1.6, 0.4, 0.6, 0.3)


# ---------------------------------------------------------------- 奇兴节点(骰子术士)：掷骰 / 换位 / 石化
const DICE_PURPLE := Color("#b47cff")
var _die_mesh: BoxMesh = null


## 掷骰：两颗白骰子从她手里翻着跟头飞到 to(敌人群的中心)，落地炸开一团紫光
func dice_toss(from: Vector3, to: Vector3, chaos: bool) -> void:
	var s: float = maxf(0.2, speed_scale)
	if _die_mesh == null:
		_die_mesh = BoxMesh.new()
		_die_mesh.size = Vector3.ONE * 0.16
	for i in range(2):
		var m := MeshInstance3D.new()
		m.mesh = _die_mesh
		m.material_override = _emissive(Color("#f4f0e8"), 0.6)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		var off := Vector3(randf_range(-0.25, 0.25), 0.0, randf_range(-0.25, 0.25))
		var a: Vector3 = from + off * 0.3
		var b: Vector3 = to + off
		var mid: Vector3 = (a + b) * 0.5 + Vector3(0, 1.2, 0)
		m.global_position = a
		var tw: Tween = create_tween().set_parallel(true)
		var lf: float = 0.45 / s
		tw.tween_method(func(k: float) -> void:
			if is_instance_valid(m):
				m.global_position = a.lerp(mid, k).lerp(mid.lerp(b, k), k), 0.0, 1.0, lf).set_delay(0.06 * float(i) / s)
		tw.tween_property(m, "rotation", Vector3(randf_range(6, 12), randf_range(6, 12), randf_range(6, 12)), lf).set_delay(0.06 * float(i) / s)
		tw.chain().tween_callback(m.queue_free)
	var land := create_tween()
	land.tween_interval(0.5 / s)
	land.tween_callback(burst.bind(to + Vector3(0, 0.3, 0), Color("#ff4a6a") if chaos else DICE_PURPLE, 18 if chaos else 10, 2.6, 0.9, 0.8, 0.5))
	land.tween_callback(ring.bind(Vector3(to.x, 0.05, to.z), 2.4 if chaos else 1.4, Color("#ff4a6a") if chaos else DICE_PURPLE, 0.5, 1.6, 0.2))


## 换位：一道紫色的光从原来的位置连到新位置，两头各一团光
func swap_flash(a: Vector3, b: Vector3) -> void:
	thunder_bolt_colored(a + Vector3(0, 0.6, 0), b + Vector3(0, 0.6, 0), DICE_PURPLE)
	burst(a + Vector3(0, 0.5, 0), DICE_PURPLE, 6, 1.4, 0.6, 0.6, 0.3)
	burst(b + Vector3(0, 0.5, 0), DICE_PURPLE, 8, 1.8, 0.7, 0.8, 0.35)


func thunder_bolt_colored(a: Vector3, b: Vector3, c: Color) -> void:
	var s: float = maxf(0.2, speed_scale)
	var root := Node3D.new()
	add_child(root)
	var mat: StandardMaterial3D = _emissive(c, 2.6, 0.8).duplicate()
	_bolt_seg(root, a, a.lerp(b, 0.5) + Vector3(0, 0.25, 0), mat, 0.05)
	_bolt_seg(root, a.lerp(b, 0.5) + Vector3(0, 0.25, 0), b, mat, 0.05)
	var tw: Tween = create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.35 / s)
	tw.tween_callback(root.queue_free)


## 从石化里醒来：一圈灰石碎块往外崩开 + 金紫色的光
func stone_break(at: Vector3) -> void:
	burst(at, Color("#8a8580"), 22, 2.8, 1.3, 1.2, 0.9, false)
	burst(at, Color("#5c5854"), 12, 2.0, 1.0, 0.8, 0.8, false)
	soft_flash(at, DICE_PURPLE, 1.6, 0.35, 2.4)
	ring(Vector3(at.x, 0.05, at.z), 1.4, DICE_PURPLE, 0.5, 1.4, 0.2)


# ---------------------------------------------------------------- 锁芯节点
const CULT_GOLD := Color("#f0c060")
const CULT_GREEN := Color("#86c46e")
const CULT_DEEP := Color("#24502c")         # 普通混合的深绿(白地上交代法阵的形状)
const CULT_VOID := Color("#2a1248")         # 深空之门：暗紫的门里
const CULT_STAR := Color("#e4d8ff")
var _chain_link: BoxMesh = null


## 一条金色锁链：从 a 一节节射到 b(shoot 秒)，停 hold 秒后淡掉。相邻两节绕链子的方向错开 90°(看起来像一环扣一环)
func key_chain(a: Vector3, b: Vector3, shoot: float = 0.12, hold: float = 0.25, c: Color = CULT_GOLD) -> void:
	var s: float = maxf(0.2, speed_scale)
	var d: Vector3 = b - a
	var ln: float = d.length()
	if ln < 0.05:
		return
	if _chain_link == null:
		_chain_link = BoxMesh.new()
		_chain_link.size = Vector3(0.035, 0.085, 0.13)
	var n: int = clampi(int(ln / 0.12), 2, 80)
	var root := Node3D.new()
	add_child(root)
	var mat: StandardMaterial3D = _emissive(c, 2.0, 0.98).duplicate() as StandardMaterial3D
	var dn: Vector3 = d / ln
	var bs: Basis = Basis.looking_at(dn, Vector3.UP if absf(dn.y) < 0.95 else Vector3.RIGHT)
	var links: Array[MeshInstance3D] = []
	for i in range(n):
		var lk := MeshInstance3D.new()
		lk.mesh = _chain_link
		lk.material_override = mat
		lk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lk.transform = Transform3D(bs * Basis(Vector3(0, 0, 1), PI * 0.5 * float(i % 2)), a + d * ((float(i) + 0.5) / float(n)))
		lk.visible = false
		root.add_child(lk)
		links.append(lk)
	var tw: Tween = create_tween()
	tw.tween_method(func(k: float) -> void:
		var m: int = int(ceil(k * float(n)))
		for j in range(mini(m, links.size())):
			if is_instance_valid(links[j]):
				links[j].visible = true, 0.0, 1.0, maxf(0.01, shoot) / s)
	tw.tween_interval(hold / s)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.2 / s)
	tw.tween_callback(root.queue_free)


## 万物闭锁的前摇：地上张开一圈绿金法阵(半径 = 闭锁的圆)，外沿一圈金色锁环绕着转；impact 秒内法阵转着往里收一点、亮起来
func lock_sigil(center: Vector3, radius: float, impact: float) -> void:
	var s: float = maxf(0.2, speed_scale)
	var root := Node3D.new()
	add_child(root)
	root.global_position = Vector3(center.x, 0.04, center.z)
	var sm: Array = holy_seal(root, "Lock", -1.6, 0.35)
	(sm[0] as ShaderMaterial).set_shader_parameter("col", CULT_GREEN)
	(sm[0] as ShaderMaterial).set_shader_parameter("hot", CULT_GOLD)
	(sm[1] as ShaderMaterial).set_shader_parameter("col", CULT_DEEP)
	(sm[1] as ShaderMaterial).set_shader_parameter("hot", CULT_DEEP)
	root.scale = Vector3.ONE * radius * 1.25
	# 外沿的锁环：8 节金色的环，跟着法阵转
	var rim := Node3D.new()
	root.add_child(rim)
	var lm: StandardMaterial3D = _emissive(CULT_GOLD, 2.2, 0.98).duplicate() as StandardMaterial3D
	for i in range(16):
		var a: float = TAU * float(i) / 16.0
		var lk := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.06, 0.12 if i % 2 == 0 else 0.03, 0.2) / (radius * 1.25)
		lk.mesh = bm
		lk.material_override = lm
		lk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lk.position = Vector3(sin(a), 0.05, cos(a)) * 0.96
		lk.rotation.y = a + PI * 0.5
		rim.add_child(lk)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(root, "scale", Vector3.ONE * radius * 1.02, impact / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(rim, "rotation:y", -PI * 0.75, impact / s)
	tw.chain().tween_callback(root.queue_free)
	ring_in(Vector3(center.x, 0.0, center.z), radius * 1.15, CULT_GOLD, impact, 1.2)


## 万物闭锁锁上：外沿 8 条金色锁链同时射向圆心、圆心"咔哒"一闪(一把金色的锁影 + 绿金光点)，被锁的每个人身上一圈往里收的金环
func lock_close(center: Vector3, radius: float, hits: Array) -> void:
	var c: Vector3 = Vector3(center.x, 0.0, center.z)
	for i in range(8):
		var a: float = TAU * float(i) / 8.0 + 0.2
		key_chain(c + Vector3(sin(a), 0.0, cos(a)) * radius + Vector3(0, 0.35, 0), c + Vector3(0, 0.6, 0), 0.08, 0.22)
	var s: float = maxf(0.2, speed_scale)
	var pad := Node3D.new()
	add_child(pad)
	pad.global_position = c + Vector3(0, 1.0, 0)
	var pm: StandardMaterial3D = _emissive(CULT_GOLD, 2.4, 0.98).duplicate() as StandardMaterial3D
	# 锁身(方块) + 锁梁(倒 U)：体素拼的小锁
	for part: Array in [[Vector3(0, 0, 0), Vector3(0.34, 0.28, 0.1)], [Vector3(-0.12, 0.22, 0), Vector3(0.06, 0.18, 0.06)],
			[Vector3(0.12, 0.22, 0), Vector3(0.06, 0.18, 0.06)], [Vector3(0, 0.32, 0), Vector3(0.3, 0.06, 0.06)]]:
		var pm1 := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = part[1]
		pm1.mesh = pb
		pm1.material_override = pm
		pm1.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pm1.position = part[0]
		pad.add_child(pm1)
	pad.scale = Vector3.ONE * 1.6
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(pad, "scale", Vector3.ONE * 1.0, 0.12 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(pm, "albedo_color:a", 0.0, 0.3 / s).set_delay(0.3 / s)
	tw.chain().tween_callback(pad.queue_free)
	soft_flash(c + Vector3(0, 0.8, 0), CULT_GOLD, 1.8, 0.3, 2.2)
	burst(c + Vector3(0, 0.6, 0), CULT_GREEN, 14, 2.4, 0.9, 0.8, 0.5)
	ring(c, radius, CULT_GOLD, 0.35, 1.6, 0.9)
	key_turn(c)
	for h: Variant in hits:
		var hp: Vector3 = h
		ring_in(Vector3(hp.x, 0.0, hp.z), 0.7, CULT_GOLD, 0.3, 1.4)


## 打开深空之门：地上张开一扇暗紫的门(门里是星空：往上飘的星点)，金色锁链从门里射向每个触发目标、把它们拽过来；
## 门在 0.7 秒后转着收拢合上
func deep_gate(center: Vector3, chests: Array) -> void:
	var s: float = maxf(0.2, speed_scale)
	var c: Vector3 = Vector3(center.x, 0.0, center.z)
	var root := Node3D.new()
	add_child(root)
	root.global_position = c + Vector3(0, 0.05, 0)
	var sm: Array = holy_seal(root, "Gate", 2.4, 0.85)
	(sm[0] as ShaderMaterial).set_shader_parameter("col", Color("#8a5cff"))
	(sm[0] as ShaderMaterial).set_shader_parameter("hot", CULT_STAR)
	(sm[1] as ShaderMaterial).set_shader_parameter("col", CULT_VOID)
	(sm[1] as ShaderMaterial).set_shader_parameter("hot", Color("#05020c"))
	# 门里：一片暗紫的星空(普通混合的深色圆盘，压在圣印下面；白地上看得出是一个"洞")
	var void_m := MeshInstance3D.new()
	var vq := QuadMesh.new()
	vq.size = Vector2(1.7, 1.7)
	vq.orientation = PlaneMesh.FACE_Y
	void_m.mesh = vq
	var vmat := StandardMaterial3D.new()
	vmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vmat.albedo_texture = SoftFX._texture()
	vmat.albedo_color = Color(0.06, 0.02, 0.12, 0.92)
	vmat.render_priority = 0
	void_m.material_override = vmat
	void_m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	void_m.position.y = -0.004
	root.add_child(void_m)
	root.scale = Vector3.ONE * 0.1
	var tw: Tween = create_tween()
	tw.tween_property(root, "scale", Vector3.ONE * 1.4, 0.18 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(0.55 / s)
	tw.tween_property(root, "scale", Vector3.ONE * 0.05, 0.25 / s).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(root, "rotation:y", PI, 0.25 / s)
	tw.tween_callback(root.queue_free)
	# 门里的星：往上飘的白紫色光点
	for i in range(14):
		var st := MeshInstance3D.new()
		st.mesh = _box
		st.material_override = _emissive(CULT_STAR if i % 3 != 0 else Color("#a080ff"), 2.6)
		st.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(st)
		var a: float = randf() * TAU
		var r: float = randf() * 1.1
		var p0: Vector3 = c + Vector3(sin(a) * r, 0.08, cos(a) * r)
		st.global_position = p0
		st.scale = Vector3.ONE * randf_range(0.4, 0.9)
		var tws: Tween = create_tween().set_parallel(true)
		var lf: float = randf_range(0.5, 0.9) / s
		tws.tween_property(st, "global_position", p0 + Vector3(0, randf_range(0.8, 1.8), 0), lf).set_delay(randf() * 0.2 / s)
		tws.tween_property(st, "scale", Vector3.ZERO, lf).set_delay(randf() * 0.2 / s)
		tws.chain().tween_callback(st.queue_free)
	for h: Variant in chests:
		key_chain(c + Vector3(0, 0.3, 0), h, 0.1, 0.3)
	soft_flash(c + Vector3(0, 0.4, 0), Color("#8a5cff"), 2.2, 0.4, 2.0)
	ring(c, 1.8, Color("#8a5cff"), 0.5, 1.6, 0.2)


# ---------------------------------------------------------------- 锁芯节点(2026-10-08 精修)：血色仪式 / 闭锁的锁 / 深空之门的计数
const CULT_BLOOD := Color("#9e1028")
var _lock_link: TorusMesh = null


## 血色仪式：她脚下一圈慢慢转的暗红仪式法阵(普通混合垫底 + 暗红叠加)+ 身上往上飘的血雾；挂在她的视图上
func blood_rite_circle(parent: Node3D, r: float) -> Node3D:
	var root := Node3D.new()
	root.name = "BloodRite"
	parent.add_child(root)
	root.position.y = 0.03
	var seal := Node3D.new()
	seal.scale = Vector3.ONE * r
	root.add_child(seal)
	var sm: Array = holy_seal(seal, "Rite", -0.5, 0.9)
	(sm[0] as ShaderMaterial).set_shader_parameter("col", Color("#ff2a48"))
	(sm[0] as ShaderMaterial).set_shader_parameter("hot", Color("#ff4a5c"))
	(sm[0] as ShaderMaterial).set_shader_parameter("pool_k", 0.15)
	(sm[0] as ShaderMaterial).set_shader_parameter("fade", 0.45)
	(sm[1] as ShaderMaterial).set_shader_parameter("col", Color("#6a0a1c"))       # 普通混合垫底：浅色地面上看得出暗红的刻线
	(sm[1] as ShaderMaterial).set_shader_parameter("hot", Color("#6a0a1c"))
	(sm[1] as ShaderMaterial).set_shader_parameter("pool_k", 0.0)
	var mist: GPUParticles3D = blood_aura(root, r * 0.8)
	mist.amount_ratio = 1.0
	return root


## 被她锁住(她给的眩晕)：头顶一把晃着的金锁 + 胸口一圈慢慢转的金色锁链(替代通用的眩晕星星)
func lock_mark(parent: Node3D, offset: Vector3, chest_y: float, r: float) -> Node3D:
	var root := Node3D.new()
	root.position = offset
	parent.add_child(root)
	var pm: StandardMaterial3D = _emissive(CULT_GOLD, 2.2)
	var pad := Node3D.new()
	root.add_child(pad)
	for part: Array in [[Vector3(0, 0, 0), Vector3(0.2, 0.16, 0.06)], [Vector3(-0.07, 0.12, 0), Vector3(0.035, 0.11, 0.035)],
			[Vector3(0.07, 0.12, 0), Vector3(0.035, 0.11, 0.035)], [Vector3(0, 0.18, 0), Vector3(0.17, 0.035, 0.035)]]:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = part[1]
		m.mesh = bm
		m.material_override = pm
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.position = part[0]
		pad.add_child(m)
	var kh := MeshInstance3D.new()
	var kb := BoxMesh.new()
	kb.size = Vector3(0.03, 0.06, 0.07)
	kh.mesh = kb
	kh.material_override = _emissive(Color("#3a2a10"), 0.2)
	kh.position = Vector3(0, -0.01, 0.0)
	pad.add_child(kh)
	var tw := pad.create_tween().set_loops()
	tw.tween_property(pad, "rotation:z", 0.25, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(pad, "rotation:z", -0.25, 0.4).set_trans(Tween.TRANS_SINE)
	# 胸口：两道交叉、斜着缠在身上的锁链(一环扣一环，横竖交替)，各自慢慢转
	if _lock_link == null:
		_lock_link = TorusMesh.new()
		_lock_link.inner_radius = 0.022
		_lock_link.outer_radius = 0.042
		_lock_link.rings = 8
		_lock_link.ring_segments = 4
		_lock_link.material = _emissive(Color("#e8b44a"), 1.4)
	var n: int = maxi(16, int(TAU * r / 0.062))
	for k in range(2):
		var tilt := Node3D.new()
		tilt.position = Vector3(0.0, chest_y - offset.y - 0.06 * float(k), 0.0)
		tilt.rotation = Vector3(0.32 * (1.0 if k == 0 else -1.0), 0.6 * float(k), 0.0)
		root.add_child(tilt)
		var chain := MultiMeshInstance3D.new()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _lock_link
		mm.instance_count = n
		for i in range(n):
			var a: float = TAU * float(i) / float(n)
			var bs := Basis(Vector3.UP, -a + PI * 0.5)                    # 环面沿着切线
			if i % 2 == 1:
				bs = bs * Basis(Vector3.RIGHT, PI * 0.5)                    # 隔一个绕切线竖起来：扣在一起
			mm.set_instance_transform(i, Transform3D(bs, Vector3(cos(a), 0.0, sin(a)) * r))
		chain.multimesh = mm
		chain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tilt.add_child(chain)
		var tc := chain.create_tween().set_loops()
		tc.tween_property(chain, "rotation:y", TAU * (1.0 if k == 0 else -1.0), 3.2).from(0.0)
	return root


## 深空之门的计数：她脚下一圈 n 颗小石(场上累计眩晕每满 1 秒亮一颗，亮满开门)；gate_gauge_set 每帧摆
func gate_gauge(parent: Node3D, r: float, n: int) -> Node3D:
	var root := Node3D.new()
	root.name = "GateGauge"
	parent.add_child(root)
	root.position.y = 0.16
	for i in range(n):
		var a: float = TAU * float(i) / float(n) - PI * 0.5
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.085, 0.085, 0.085)
		m.mesh = bm
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.position = Vector3(cos(a), 0.0, sin(a)) * r
		m.rotation = Vector3(PI * 0.25, -a, PI * 0.25)                     # 立着的菱形
		root.add_child(m)
	var tw := root.create_tween().set_loops()
	tw.tween_property(root, "rotation:y", TAU, 14.0).from(0.0)
	gate_gauge_set(root, 0, n)
	return root


func gate_gauge_set(root: Node3D, lit: int, n: int) -> void:
	if root == null or not is_instance_valid(root):
		return
	if int(root.get_meta("lit", -1)) == lit:
		return
	var prev: int = int(root.get_meta("lit", 0))
	root.set_meta("lit", lit)
	var kids: Array = root.get_children()
	for i in range(kids.size()):
		var m: MeshInstance3D = kids[i]
		var on: bool = i < lit
		m.material_override = _emissive(Color("#c4a2ff") if on else Color("#2a1d40"), 3.0 if on else 0.3)
		m.scale = Vector3.ONE * (1.45 if on else 1.0)
	if lit > prev and lit > 0 and lit <= kids.size():
		var m2: MeshInstance3D = kids[lit - 1]
		soft_flash(m2.global_position + Vector3(0, 0.1, 0), Color("#b08cff"), 0.5, 0.2, 2.2)


## 万物闭锁锁上的那一下：圆心上方一把大金钥匙插下来、"咔"地转 90 度(一闪)，然后淡掉
func key_turn(center: Vector3) -> void:
	var s: float = maxf(0.2, speed_scale)
	var root := Node3D.new()
	add_child(root)
	root.global_position = center + Vector3(0, 1.6, 0)
	var km: StandardMaterial3D = _emissive(CULT_GOLD, 2.4, 0.98).duplicate() as StandardMaterial3D
	var parts: Array = [[Vector3(0, 0, 0), Vector3(0.07, 0.8, 0.07)], [Vector3(0.09, -0.32, 0), Vector3(0.12, 0.06, 0.05)],
		[Vector3(0.07, -0.22, 0), Vector3(0.08, 0.05, 0.05)]]
	for pa: Array in parts:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = pa[1]
		m.mesh = bm
		m.material_override = km
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.position = pa[0]
		root.add_child(m)
	var tm := TorusMesh.new()
	tm.inner_radius = 0.1
	tm.outer_radius = 0.17
	tm.rings = 16
	tm.ring_segments = 4
	var bow := MeshInstance3D.new()
	bow.mesh = tm
	bow.material_override = km
	bow.rotation.x = PI * 0.5
	bow.position = Vector3(0, 0.5, 0)
	bow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(bow)
	var tw: Tween = create_tween()
	tw.tween_property(root, "global_position:y", center.y + 0.85, 0.12 / s).set_ease(Tween.EASE_IN)
	tw.tween_property(root, "rotation:y", PI * 0.5, 0.1 / s).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(soft_flash.bind(center + Vector3(0, 0.8, 0), Color("#fff4c4"), 1.2, 0.18, 2.6))
	tw.tween_interval(0.2 / s)
	tw.tween_property(km, "albedo_color:a", 0.0, 0.25 / s)
	tw.tween_callback(root.queue_free)


# ---------------------------------------------------------------- 变奏节点(2026-10-08 精修)：音符弹 / 和弦 / 沮丧 · 亢奋 / 悲怆 · 热情的波 / 下一乐章
const PIANO_DEMON_NOTE := Color("#ff3a5c")
const PIANO_ANGEL_NOTE := Color("#ffbf2e")        # 白金在浅色地面上发白看不见：用饱和一点的金


## 她的普攻弹：一枚大音符(恶魔 = 猩红、天使 = 白金)，身后拖一串小闪光
func make_note_projectile(angel: bool) -> Node3D:
	var c: Color = PIANO_ANGEL_NOTE if angel else PIANO_DEMON_NOTE
	var root := Node3D.new()
	var m := MeshInstance3D.new()
	m.mesh = note2_mesh() if randf() < 0.5 else note_mesh()
	m.material_override = _icon_mat(c, 2.8)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.scale = Vector3.ONE * 2.4
	root.add_child(m)
	var tr := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.3
	pm.gravity = Vector3(0, -0.3, 0)
	pm.scale_min = 0.4
	pm.scale_max = 0.8
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1.0))
	curve.add_point(Vector2(1, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	tr.process_material = pm
	tr.draw_pass_1 = _box
	tr.material_override = _emissive(c.lightened(0.3), 2.6)
	tr.amount = 16
	tr.lifetime = 0.35
	tr.local_coords = false
	tr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tr.visibility_aabb = AABB(Vector3(-4, -3, -4), Vector3(8, 8, 8))
	root.add_child(tr)
	return root


## 和弦(她的音符弹落地的溅射)：一圈颜色的环 + 往外崩的几枚小音符 + 一闪；黑 / 白琴键的碎片
func chord_burst(at: Vector3, r: float, angel: bool) -> void:
	var c: Color = PIANO_ANGEL_NOTE if angel else PIANO_DEMON_NOTE
	soft_flash(at, c, 1.0 + 0.3 * r, 0.22, 2.4)
	ring(Vector3(at.x, 0.05, at.z), r, c, 0.45, 1.4, 0.2)
	ring(Vector3(at.x, 0.06, at.z), r * 0.6, PIANO_GOLD, 0.35, 0.9, 0.2)
	float_icons(at + Vector3(0, 0.1, 0), note_mesh(), c, 4, 0.3, 0.8, 1.4)
	burst(at, Color("#f6f4ee") if angel else Color("#18141a"), 8, 2.2, 0.6, 0.7, 0.4, angel)


## 弹琴(每次普攻)：琴上飘起一把音符(恶魔 = 猩红 / 黑，天使 = 白金)
func piano_notes(at: Vector3, angel: bool) -> void:
	var c: Color = PIANO_ANGEL_NOTE if angel else PIANO_DEMON_NOTE
	float_icons(at, note_mesh(), c, 3, 0.25, 0.9, 1.2)
	float_icons(at, note2_mesh(), Color("#6cc8ff") if angel else Color("#2a1a22"), 2, 0.25, 0.9, 1.1)


## 沮丧 / 亢奋的层数：身上一直飘的音符——沮丧 = 暗红的音符往下坠(像滴下来)，亢奋 = 金色的音符往上蹦；按层数调浓度
func stack_notes(parent: Node3D, h: float, rising: bool) -> GPUParticles3D:
	var c: Color = Color("#ffd36a") if rising else Color("#8a1028")
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.35
	pm.direction = Vector3(0, 1, 0) if rising else Vector3(0, -1, 0)
	pm.spread = 25.0
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.7
	pm.gravity = Vector3(0, 0.6 if rising else -0.8, 0)
	pm.scale_min = 0.9
	pm.scale_max = 1.4
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.3))
	curve.add_point(Vector2(0.2, 1.0))
	curve.add_point(Vector2(1, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	p.process_material = pm
	p.draw_pass_1 = note_mesh()
	p.material_override = _icon_mat(c, 2.2 if rising else 1.4)
	p.amount = 8
	p.lifetime = 1.2
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 5, 4))
	p.position = Vector3(0.0, h * (0.8 if rising else 1.05), 0.0)
	p.amount_ratio = 0.0
	p.emitting = true
	parent.add_child(p)
	return p


## 悲怆 / 热情(每 3 秒全场 +1 层)：从她身上往外推一道大波——恶魔 = 暗红的波 + 往下坠的暗色音符，天使 = 金色的波 + 往上飘的音符
func piano_wave(at: Vector3, angel: bool) -> void:
	var c: Color = Color("#ffd36a") if angel else Color("#b0142e")
	ring(Vector3(at.x, 0.05, at.z), 9.0, c, 1.1, 1.6, 0.05)
	ring(Vector3(at.x, 0.06, at.z), 5.0, Color("#f6f4ee") if angel else Color("#2a1a22"), 0.8, 1.0, 0.05)
	float_icons(at + Vector3(0, 1.0, 0), note2_mesh(), c, 5, 0.5, 1.0, 1.4)


## 下一乐章(想加层但已经叠满)：一条五线谱从她身上旋出来盘上去 + 一声和弦的闪光 + 一把音符
func next_movement(at: Vector3, chest: Vector3, angel: bool) -> void:
	var c: Color = PIANO_ANGEL_NOTE if angel else PIANO_DEMON_NOTE
	SongStaff.create(self, at, chest + Vector3(0, 0.2, 0), c, PIANO_GOLD)
	soft_flash(chest, c, 1.6, 0.3, 2.4)
	ring(Vector3(at.x, 0.05, at.z), 2.6, PIANO_GOLD, 0.55, 1.6, 0.1)
	float_icons(chest + Vector3(0, 0.3, 0), note_mesh(), c, 6, 0.5, 1.1, 1.6)


# ---------------------------------------------------------------- 变奏节点
const PIANO_RED := Color("#d23a52")
const PIANO_GOLD := Color("#f2cc7a")
const PIANO_WHITE := Color("#eef2ff")


## 表里之间：换形态(恶魔 ↔ 天使)——一团柔光 + 黑红 / 白金的碎片往外崩开 + 地上一圈光环和一道光柱
func pianist_flip(at: Vector3, angel: bool) -> void:
	var c: Color = PIANO_WHITE if angel else PIANO_RED
	soft_flash(at, c, 2.2, 0.45, 2.2)
	burst(at, c, 18, 2.6, 1.0, 1.2, 0.8)
	burst(at, PIANO_GOLD if angel else Color("#24161c"), 10, 1.8, 0.8, 1.5, 0.9, angel)
	ring(Vector3(at.x, 0.05, at.z), 1.6, c, 0.6, 1.4, 0.2)
	pillar(Vector3(at.x, 0.0, at.z), c, 0.7)
	var s: float = maxf(0.2, speed_scale)
	for i in range(16):
		var k := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.07, 0.03, 0.22) if i % 2 == 0 else Vector3(0.05, 0.04, 0.15)
		k.mesh = bm
		k.material_override = _emissive(Color("#f6f4ee") if i % 2 == 0 else Color("#18141a"), 1.2 if i % 2 == 0 else 0.4)
		k.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(k)
		var a0: float = TAU * float(i) / 16.0
		var tw: Tween = create_tween()
		tw.tween_method(func(q: float) -> void:
			if is_instance_valid(k):
				var a: float = a0 + q * 4.0
				var r: float = lerpf(0.5, 1.3, q)
				k.global_position = Vector3(at.x, 0.2, at.z) + Vector3(cos(a) * r, q * 1.6 - 0.2 * q * q, sin(a) * r)
				k.rotation = Vector3(0.0, -a, q * 3.0)
				k.scale = Vector3.ONE * (1.0 - q * 0.6), 0.0, 1.0, 0.8 / s)
		tw.tween_callback(k.queue_free)


## 黑键 / 白键：一串黑白相间的琴键从她身前飞向目标，落在目标身上一闪(白键 = 白金色，黑键 = 黑红色)
func black_keys(from: Vector3, to: Vector3, white: bool) -> void:
	var s: float = maxf(0.2, speed_scale)
	var c: Color = PIANO_WHITE if white else PIANO_RED
	for i in range(7):
		var k := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.07, 0.03, 0.22) if i % 2 == 0 else Vector3(0.05, 0.04, 0.15)
		k.mesh = bm
		k.material_override = _emissive(Color("#f6f4ee") if i % 2 == 0 else Color("#18141a"), 1.2 if i % 2 == 0 else 0.4)
		k.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(k)
		var a: Vector3 = from + Vector3(randf_range(-0.2, 0.2), randf_range(-0.1, 0.2), randf_range(-0.2, 0.2))
		var mid: Vector3 = (a + to) * 0.5 + Vector3(0, 0.8, 0)
		k.global_position = a
		var tw: Tween = create_tween().set_parallel(true)
		var lf: float = 0.32 / s
		var dl: float = 0.035 * float(i) / s
		tw.tween_method(func(q: float) -> void:
			if is_instance_valid(k):
				k.global_position = a.lerp(mid, q).lerp(mid.lerp(to, q), q), 0.0, 1.0, lf).set_delay(dl)
		tw.tween_property(k, "rotation", Vector3(randf_range(-3, 3), randf_range(-6, 6), randf_range(-3, 3)), lf).set_delay(dl)
		tw.chain().tween_callback(k.queue_free)
	var land := create_tween()
	land.tween_interval(0.42 / s)
	land.tween_callback(soft_flash.bind(to, c, 1.8, 0.35, 2.4))
	land.tween_callback(burst.bind(to, c, 14, 2.2, 0.9, 0.9, 0.6))
	land.tween_callback(ring.bind(Vector3(to.x, 0.05, to.z), 1.0, PIANO_GOLD, 0.45, 1.2, 0.2))
