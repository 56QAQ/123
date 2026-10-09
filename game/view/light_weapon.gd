class_name LightWeapon
extends Node3D
## 正行节点·花蕊的光武器：身上有【花蕊】(强化普攻)时，手里的武器化成一把发光的大武器——
##   sword   剑 → 一柄光剑(白金色的菱形刃，刃缘金、刃尖带一点粉)
##   polearm 长枪 → 一杆光枪(细长的光杆 + 一片宽大的叶形光刃)
##   focus   法器 → 外面套一门光炮(半透明的光管 + 三道转着的金环，炮口是六瓣张开的光百合)
## 平时(持有花蕊)是"握持"的长度(层数越多越长)；放花蕊的横扫(attack_cone_noble_*)时按动画时间走：
## 蓄力时一口气长到全长 → 横扫(更亮、刃上撒花瓣) → 随挥之后收回握持长度；花蕊用完就碎成花瓣散掉。
## 挂在武器骨 Bow 上：骨局部 +Y = 刃的方向(握点在原点)，法器的炮口朝 -Y、法器本体在拳头上方(+Z)。
## 刀光(WeaponTrail.ANIM_STYLES)在横扫时用长刃参数，和光刃的长度对上。

const LILY_CORE := Color("#fffdf2")
const LILY_GLOW := Color("#ffd46a")
const LILY_PINK := Color("#ffb3cf")
const PETAL_COLS: Array[Color] = [Color("#ffb3cf"), Color("#f07aa6"), Color("#fff4ee"), Color("#d0a8f6"), Color("#ffd8e6")]

## hold = 握持长度(1 / 2 / 3 层花蕊)，full = 横扫时的全长(米，从 base 算起)；
## grow = 动画里从握持长到全长的时间段，keep = 动画里全长保持到几秒，flare = 横扫最亮的时间段
const KINDS := {
	"sword": {"anim": "attack_cone_noble_sword", "hold": [1.05, 1.3, 1.55], "full": 4.0, "base": 0.07, "width": 0.17, "thick": 0.045,
		"grow": [0.0, 0.12], "keep": 0.42, "back": 0.56, "flare": [0.17, 0.36]},
	"polearm": {"anim": "attack_cone_noble_polearm", "hold": [1.4, 1.65, 1.9], "full": 3.4, "base": -0.45, "width": 0.3, "thick": 0.05,
		"grow": [0.0, 0.15], "keep": 0.48, "back": 0.64, "flare": [0.20, 0.42]},
	"focus": {"anim": "attack_cone_noble_focus", "hold": [0.32, 0.4, 0.48], "full": 1.25, "base": 0.12, "width": 0.17, "thick": 0.0,
		"grow": [0.0, 0.22], "keep": 0.62, "back": 0.8, "flare": [0.30, 0.5], "fire": 0.36},
}

const BLADE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_opaque, shadows_disabled, fog_disabled;
uniform vec4 core : source_color = vec4(1.0, 0.99, 0.95, 1.0);
uniform vec4 glow : source_color = vec4(1.0, 0.7, 0.22, 1.0);
uniform vec4 tipc : source_color = vec4(1.0, 0.7, 0.81, 1.0);
uniform float len = 1.0;
uniform float base = 0.0;
uniform float reach = 1.0;
uniform float vis = 1.0;
uniform float flare = 0.0;
uniform float halo = 0.0;
uniform float fuller = 0.0;
uniform vec4 fuller_col : source_color = vec4(0.45, 0.6, 1.0, 1.0);
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
void vertex() {
	VERTEX.y = base + VERTEX.y * len;
}
void fragment() {
	float y = UV.x;
	float e = UV.y;
	if (y > reach) {
		discard;
	}
	float n = noise(vec2(y * len * 7.0 - TIME * 3.0, e * 4.0 + TIME));
	if (n < 1.0 - vis) {
		discard;
	}
	vec3 c = mix(core.rgb, glow.rgb, smoothstep(0.3, 1.0, e));
	c = mix(c, tipc.rgb, smoothstep(0.72, 1.0, y) * 0.45);
	float flow = smoothstep(0.75, 1.0, sin(y * len * 8.0 - TIME * 16.0) * 0.5 + 0.5) * (1.0 - e);
	c += vec3(0.35, 0.3, 0.2) * flow * (0.4 + flare);
	// 血槽(圣剑)：刃脊上一条带颜色的槽，里面一节节的光纹往刃尖流
	float fl = (1.0 - smoothstep(0.1, 0.2, e)) * smoothstep(0.03, 0.06, y) * (1.0 - smoothstep(0.74, 0.8, y)) * fuller;
	float rune = smoothstep(0.55, 0.75, fract(y * len * 3.5 - TIME * 1.5));
	c = mix(c, fuller_col.rgb * (1.0 + 0.6 * rune), fl * 0.8);
	float front = smoothstep(reach - 0.05, reach, y) * step(reach, 0.995);
	c = mix(c, vec3(1.0), front * 0.8);
	float edge_vis = smoothstep(1.0 - vis, 1.0 - vis + 0.12, n);
	c = mix(glow.rgb * 1.6, c, edge_vis);
	if (halo > 0.5) {
		ALBEDO = glow.rgb * (1.2 + flare * 0.5);
		ALPHA = (1.0 - e) * (0.3 + 0.2 * flare) * vis;
	} else {
		ALBEDO = c * (1.35 + flare * 0.45);
		ALPHA = clamp(0.95 - 0.18 * e, 0.0, 1.0);
	}
}
"""
## 光炮的管壁：边缘亮、中间透，沿管子往炮口流的一道道光纹
const SHELL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec4 core : source_color = vec4(1.0, 0.99, 0.95, 1.0);
uniform vec4 glow : source_color = vec4(1.0, 0.83, 0.42, 1.0);
uniform float vis = 1.0;
uniform float flare = 0.0;
void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), VIEW)), 1.6);
	float bands = smoothstep(0.6, 1.0, sin(UV.y * 40.0 + TIME * 18.0) * 0.5 + 0.5);
	ALBEDO = mix(glow.rgb, core.rgb, rim * 0.6 + bands * 0.3) * (1.4 + flare * 0.6);
	ALPHA = clamp(rim * 0.9 + 0.12 + bands * 0.18 + flare * 0.15, 0.0, 1.0) * vis;
}
"""

const SPEAR_LEAF := 1.4                 # 光枪叶形刃的长度(米)
const SPEAR_LAP := 0.3                   # 叶形刃压在光杆头上的长度
const CANNON_Z := 0.08                   # 光炮的轴线(法器本体在拳头上方)

static var _blade_shader: Shader = null
static var _shell_shader: Shader = null
static var _blade_mesh: ArrayMesh = null
static var _leaf_mesh: ArrayMesh = null

var kind: String = "sword"
var cfg: Dictionary = {}
var skel: Skeleton3D
var ap: AnimationPlayer
var charges: int = 0                     # 花蕊层数(0 = 没有：碎掉)
var _len: float = 0.0                    # 现在的长度(米)
var _vis: float = 0.0
var _reach: float = 0.0                  # 刚化出来时从刃根往外长(0..1)
var _was_on: bool = false
var _parts: Array = []                   # [MeshInstance3D, ShaderMaterial, kind]：kind = blade / halo / shell / leaf
var _rings: Array[MeshInstance3D] = []
var _muzzle: Array[Node3D] = []          # 炮口的六片光瓣(绕 -Y 张开)
var _core: MeshInstance3D = null         # 炮口的蓄能光球
var _stream: GPUParticles3D = null       # 刃上撒出来的花瓣
var _burst: GPUParticles3D = null        # 碎掉时一次性炸开的花瓣
var _att: BoneAttachment3D = null


static func create(p_skel: Skeleton3D, p_ap: AnimationPlayer, wclass: String) -> LightWeapon:
	if p_skel == null or not KINDS.has(wclass) or p_skel.find_bone("Bow") < 0:
		return null
	var lw := LightWeapon.new()
	lw.kind = wclass
	lw.cfg = KINDS[wclass]
	lw.skel = p_skel
	lw.ap = p_ap
	return lw


func _ready() -> void:
	_att = BoneAttachment3D.new()
	_att.bone_name = "Bow"
	skel.add_child(_att)
	var holder := Node3D.new()
	_att.add_child(holder)
	match kind:
		"focus":
			_build_cannon(holder)
		"polearm":
			_build_spear(holder)
		_:
			_build_blade(holder)
	_stream = _petal_particles(26, 0.7)
	_stream.emitting = false
	holder.add_child(_stream)
	_burst = _petal_particles(40, 0.9)
	_burst.one_shot = true
	_burst.explosiveness = 0.9
	_burst.emitting = false
	holder.add_child(_burst)
	holder.visible = false
	_set_all(0.0, 0.0, 0.0, 0.0)


func _exit_tree() -> void:
	if is_instance_valid(_att):
		_att.queue_free()


## 花蕊层数变了(BattleView 收到 lily_stamen 的状态事件时调)
func set_charges(n: int) -> void:
	charges = maxi(0, n)


func _hold_len() -> float:
	var h: Array = cfg["hold"]
	return float(h[clampi(charges - 1, 0, h.size() - 1)])


func _process(delta: float) -> void:
	if skel == null or not is_instance_valid(skel) or _att == null:
		return
	var anim: String = String(ap.current_animation) if ap != null else ""
	var at: float = ap.current_animation_position if ap != null else 0.0
	var swinging: bool = ap != null and ap.is_playing() and anim == String(cfg["anim"]) and at < float(cfg["keep"])
	var on: bool = charges > 0 or swinging
	var flare: float = 0.0
	if swinging:
		var g: Array = cfg["grow"]
		var k: float = clampf((at - float(g[0])) / maxf(0.01, float(g[1]) - float(g[0])), 0.0, 1.0)
		k = 1.0 - pow(1.0 - k, 3.0)
		_len = lerpf(_hold_len() if charges > 0 else float(cfg["hold"][0]), float(cfg["full"]), k)
		var fl: Array = cfg["flare"]
		flare = clampf(minf((at - float(fl[0])) / 0.05, (float(fl[1]) - at) / 0.08), 0.0, 1.0)
	elif charges > 0:
		_len = lerpf(_len, _hold_len(), 1.0 - exp(-delta * 9.0))
	if on and not _was_on:
		_reach = 0.0                       # 化出来：光从刃根往外长
		if _len < 0.05:
			_len = _hold_len()
	if not on and _was_on:
		_burst.restart()                   # 碎成花瓣
		_burst.emitting = true
	_was_on = on
	_reach = minf(1.0, _reach + delta / 0.28) if on else _reach
	_vis = minf(1.0, _vis + delta / 0.15) if on else maxf(0.0, _vis - delta / 0.32)
	_att.get_child(0).visible = _vis > 0.001 or _burst.emitting
	_stream.emitting = on and (flare > 0.1 or (charges > 0 and _vis > 0.9 and randf() < 0.3))
	_set_all(_len, _vis, minf(_reach, 1.0), flare)
	if kind == "focus":
		_update_cannon(swinging, at, delta)


func _set_all(length: float, vis: float, reach: float, flare: float) -> void:
	var base: float = float(cfg["base"])
	var ln: float = maxf(0.02, length)
	for pr: Array in _parts:
		var mat: ShaderMaterial = pr[1]
		match String(pr[2]):
			"blade", "halo":
				mat.set_shader_parameter("len", ln)
				mat.set_shader_parameter("reach", reach)
				mat.set_shader_parameter("vis", vis)
				mat.set_shader_parameter("flare", flare)
			"leaf":
				# 光枪的叶形刃：底部压在光杆的头上(重叠 SPEAR_LAP 米)，光杆长出来之后才出现
				mat.set_shader_parameter("vis", vis)
				mat.set_shader_parameter("flare", flare)
				mat.set_shader_parameter("reach", clampf((reach - 0.75) / 0.25, 0.0, 1.0))
				(pr[0] as MeshInstance3D).position.y = base + ln * reach - SPEAR_LAP
			"guard", "shell":
				mat.set_shader_parameter("vis", vis)
				mat.set_shader_parameter("flare", flare)
	if kind == "focus":
		for pr3: Array in _parts:
			if String(pr3[2]) == "shell":
				var m: MeshInstance3D = pr3[0]
				m.scale = Vector3(1.0, ln, 1.0)
				m.position = Vector3(0.0, base - ln * 0.5, CANNON_Z)
	# 花瓣从刃上撒出去：发射盒子沿着刃
	var box: float = maxf(0.05, ln * 0.5)
	for p: GPUParticles3D in [_stream, _burst]:
		var pm: ParticleProcessMaterial = p.process_material
		if kind == "focus":
			pm.emission_box_extents = Vector3(0.12, box, 0.12)
			p.position = Vector3(0.0, base - ln * 0.5, CANNON_Z)
		else:
			pm.emission_box_extents = Vector3(0.04, box, float(cfg["width"]))
			p.position = Vector3(0.0, base + ln * 0.5, 0.0)


# ---------------------------------------------------------------- 外形
## 给别的特效用的一把光刃(圣剑…)：长 length 米(从 base 起沿 +Y)、刃宽 width、厚 thick；halo = 外面那层光晕
static func make_blade(length: float, base: float, width: float, thick: float, core: Color, glow: Color, tip: Color, halo: bool = false) -> MeshInstance3D:
	if _blade_mesh == null:
		_blade_mesh = _blade_geom(1.0, 1.0, false)
	var mi := MeshInstance3D.new()
	mi.mesh = _blade_mesh
	var mat: ShaderMaterial = _mat("blade")
	mat.set_shader_parameter("len", length)
	mat.set_shader_parameter("base", base)
	mat.set_shader_parameter("core", core)
	mat.set_shader_parameter("glow", glow)
	mat.set_shader_parameter("tipc", tip)
	if halo:
		mat.set_shader_parameter("halo", 1.0)
		mat.render_priority = 3
	mi.material_override = mat
	mi.scale = Vector3(thick * (3.5 if halo else 1.0), 1.0, width * (2.4 if halo else 1.0))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 4.0
	return mi


static func _mat(code_kind: String) -> ShaderMaterial:
	if _blade_shader == null:
		_blade_shader = Shader.new()
		_blade_shader.code = BLADE_SHADER
		_shell_shader = Shader.new()
		_shell_shader.code = SHELL_SHADER
	var m := ShaderMaterial.new()
	m.shader = _shell_shader if code_kind == "shell" else _blade_shader
	m.render_priority = 4
	return m


## 菱形截面的刃(归一化长度 0..1，着色器按 len 拉长)：UV.x = 沿刃 0..1，UV.y = 0 刃脊 → 1 刃缘
static func _blade_geom(w: float, t: float, leaf: bool) -> ArrayMesh:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var n: int = 18
	for i in range(n + 1):
		var y: float = float(i) / float(n)
		var ww: float
		if leaf:
			ww = w * pow(sin(PI * clampf(y, 0.0, 1.0) * 0.98 + 0.02), 0.8)       # 叶形：两头尖、中间宽
		else:
			ww = w * (0.72 + 0.28 * smoothstep(0.0, 0.08, y))
			if y > 0.84:
				ww *= 1.0 - smoothstep(0.84, 1.0, y)                           # 刃尖
		var tt: float = t * (ww / maxf(w, 0.001)) * 0.8 + t * 0.2
		for c: Array in [[Vector3(0.0, y, ww), 1.0], [Vector3(tt, y, 0.0), 0.0], [Vector3(0.0, y, -ww), 1.0], [Vector3(-tt, y, 0.0), 0.0]]:
			verts.append(c[0])
			uvs.append(Vector2(y, float(c[1])))
	for i in range(n):
		for j in range(4):
			var a0: int = i * 4 + j
			var a1: int = i * 4 + (j + 1) % 4
			var b0: int = a0 + 4
			var b1: int = a1 + 4
			idx.append_array([a0, b0, a1, a1, b0, b1])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m


func _add_part(holder: Node3D, mesh: Mesh, kind_s: String, scale_v: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat: ShaderMaterial = _mat(kind_s)
	mat.set_shader_parameter("base", float(cfg["base"]))
	if kind_s == "halo":
		mat.set_shader_parameter("halo", 1.0)
		mat.render_priority = 3
	mi.material_override = mat
	mi.scale = scale_v
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 6.0
	holder.add_child(mi)
	_parts.append([mi, mat, kind_s])
	return mi


func _build_blade(holder: Node3D) -> void:
	if _blade_mesh == null:
		_blade_mesh = _blade_geom(1.0, 1.0, false)
	var w: float = float(cfg["width"])
	var t: float = float(cfg["thick"])
	_add_part(holder, _blade_mesh, "blade", Vector3(t, 1.0, w))
	_add_part(holder, _blade_mesh, "halo", Vector3(t * 3.5, 1.0, w * 2.4))
	_guard(holder, 0.06)


## 光枪：细长的光杆(刃形压得很窄) + 杆头一片宽大的叶形光刃(跟着长度走)
func _build_spear(holder: Node3D) -> void:
	if _blade_mesh == null:
		_blade_mesh = _blade_geom(1.0, 1.0, false)
	if _leaf_mesh == null:
		_leaf_mesh = _blade_geom(1.0, 1.0, true)
	_add_part(holder, _blade_mesh, "blade", Vector3(0.045, 1.0, 0.05))
	_add_part(holder, _blade_mesh, "halo", Vector3(0.12, 1.0, 0.13))
	for H: Array in [[1.0, false], [2.4, true]]:
		var lm: MeshInstance3D = _add_part(holder, _leaf_mesh, "leaf", Vector3(0.05 * float(H[0]), 1.0, float(cfg["width"]) * float(H[0])))
		var mat: ShaderMaterial = lm.material_override
		mat.set_shader_parameter("base", 0.0)
		mat.set_shader_parameter("len", SPEAR_LEAF)
		if bool(H[1]):
			mat.set_shader_parameter("halo", 1.0)
			mat.render_priority = 3
	_guard(holder, 0.62)


## 刃根的百合护手：五片小光瓣绕着握点往外张开
func _guard(holder: Node3D, y: float) -> void:
	if _leaf_mesh == null:
		_leaf_mesh = _blade_geom(1.0, 1.0, true)
	for i in range(5):
		var piv := Node3D.new()
		piv.position = Vector3(0.0, y, 0.0)
		piv.rotation = Vector3(0.0, TAU * float(i) / 5.0, 0.0)
		holder.add_child(piv)
		var mi: MeshInstance3D = _add_part(piv, _leaf_mesh, "guard", Vector3(0.012, 1.0, 0.035))
		mi.rotation = Vector3(0.0, 0.0, -1.0)
		var mat: ShaderMaterial = mi.material_override
		mat.set_shader_parameter("base", 0.0)
		mat.set_shader_parameter("len", 0.14)
		mat.set_shader_parameter("reach", 1.0)


## 光炮：一根往 -Y 伸出去的光管(半透明、边缘亮) + 三道转着的金环 + 炮口六瓣张开的光百合 + 炮口的蓄能光球
func _build_cannon(holder: Node3D) -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = 0.13
	cm.bottom_radius = 0.2
	cm.height = 1.0
	cm.radial_segments = 20
	cm.rings = 2
	cm.cap_top = false
	cm.cap_bottom = false
	_add_part(holder, cm, "shell")
	var tm := TorusMesh.new()
	tm.inner_radius = 0.17
	tm.outer_radius = 0.21
	tm.rings = 24
	tm.ring_segments = 6
	for i in range(3):
		var r := MeshInstance3D.new()
		r.mesh = tm
		var rm := StandardMaterial3D.new()
		rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rm.albedo_color = Color(LILY_GLOW.r * 1.4, LILY_GLOW.g * 1.4, LILY_GLOW.b * 1.4, 0.95)
		rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rm.disable_fog = true
		r.material_override = rm
		r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(r)
		_rings.append(r)
	if _blade_mesh == null:
		_blade_mesh = _blade_geom(1.0, 1.0, false)
	if _leaf_mesh == null:
		_leaf_mesh = _blade_geom(1.0, 1.0, true)
	for i in range(6):
		var piv := Node3D.new()
		holder.add_child(piv)
		var mi := MeshInstance3D.new()
		mi.mesh = _leaf_mesh
		var mat: ShaderMaterial = _mat("blade")
		mat.set_shader_parameter("base", 0.0)
		mat.set_shader_parameter("len", 0.42)
		mat.set_shader_parameter("tipc", LILY_PINK)
		mi.material_override = mat
		mi.scale = Vector3(0.02, 1.0, 0.12)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		piv.add_child(mi)
		_parts.append([mi, mat, "petal"])
		_muzzle.append(piv)
	_core = MeshInstance3D.new()
	_core.mesh = SoftFX.quad(1.0)
	var cmat: StandardMaterial3D = SoftFX.sprite_mat(LILY_GLOW.lerp(LILY_CORE, 0.5), 2.0)
	cmat.disable_fog = true
	_core.material_override = cmat
	_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(_core)


## 光炮每帧：金环沿管子排开、绕管子转；炮口的光瓣蓄能时合拢、开炮时一下张开；蓄能光球跟着变大，开炮时一闪
func _update_cannon(swinging: bool, at: float, delta: float) -> void:
	var base: float = float(cfg["base"])
	var tip: float = base - _len
	var t: float = Time.get_ticks_msec() * 0.001
	for i in range(_rings.size()):
		var r: MeshInstance3D = _rings[i]
		var y: float = lerpf(base - 0.1, tip + 0.08, (float(i) + 0.5) / float(_rings.size()))
		r.position = Vector3(0.0, y, CANNON_Z)
		r.rotation = Vector3(0.0, t * (3.0 + float(i)) * (1.0 if i % 2 == 0 else -1.0), 0.0)
		var sc: float = lerpf(1.0, 1.35, float(i) / 2.0) * _vis
		r.scale = Vector3(sc, sc, sc)
		r.visible = _vis > 0.01
	# 光瓣：0 = 合拢(贴着管子往前)，1 = 张开(往外翻成一朵花)
	var open: float = 0.55
	var charge: float = 0.0
	var fire: float = float(cfg.get("fire", 0.36))
	if swinging:
		charge = clampf((at - 0.18) / (fire - 0.18), 0.0, 1.0) if at < fire else 0.0
		open = lerpf(0.55, 0.15, charge) if at < fire else lerpf(1.0, 0.7, clampf((at - fire) / 0.25, 0.0, 1.0))
	var burst_k: float = clampf(1.0 - (at - fire) / 0.12, 0.0, 1.0) if swinging and at >= fire else 0.0
	for i in range(_muzzle.size()):
		var piv: Node3D = _muzzle[i]
		piv.position = Vector3(0.0, tip + 0.02, CANNON_Z)
		var a: float = TAU * float(i) / float(_muzzle.size()) + t * 0.6
		# 光瓣的 +Y 先朝 -Y(往前)，再往外翻 open × 70°
		piv.basis = Basis(Vector3(0, 1, 0), a) * Basis(Vector3(1, 0, 0), PI - deg_to_rad(15.0 + 70.0 * open))
		piv.scale = Vector3.ONE * (0.6 + 0.4 * _vis)
	for pr: Array in _parts:
		if String(pr[2]) == "petal":
			(pr[1] as ShaderMaterial).set_shader_parameter("vis", _vis)
			(pr[1] as ShaderMaterial).set_shader_parameter("reach", 1.0)
			(pr[1] as ShaderMaterial).set_shader_parameter("flare", burst_k)
	_core.position = Vector3(0.0, tip - 0.05, CANNON_Z)
	var cs: float = (0.18 + 0.35 * charge + 0.9 * burst_k) * _vis
	_core.scale = Vector3.ONE * maxf(0.001, cs)
	_core.visible = _vis > 0.01


static var _petal_mesh: BoxMesh = null


## 刃上的花瓣粒子：世界坐标(挥过去留在原地飘落)，颜色在几种花瓣色里随机
func _petal_particles(amount: int, life: float) -> GPUParticles3D:
	if _petal_mesh == null:
		_petal_mesh = BoxMesh.new()
		_petal_mesh.size = Vector3(0.075, 0.012, 0.05)
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.04, 0.5, 0.1)
	pm.direction = Vector3(0, 0, 1)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.9
	pm.gravity = Vector3(0, -1.2, 0)
	pm.damping_min = 0.8
	pm.damping_max = 1.6
	pm.angle_min = 0.0
	pm.angle_max = 360.0
	pm.angular_velocity_min = -240.0
	pm.angular_velocity_max = 240.0
	pm.particle_flag_rotate_y = true
	pm.scale_min = 0.8
	pm.scale_max = 1.4
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in range(PETAL_COLS.size()):
		offs.append(float(i) / float(PETAL_COLS.size()))
		cols.append(PETAL_COLS[i])
	g.offsets = offs
	g.colors = cols
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_initial_ramp = gt
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	fade.colors = PackedColorArray([Color(1.3, 1.3, 1.3, 1.0), Color(1.1, 1.1, 1.1, 1.0), Color(1, 1, 1, 0.0)])
	var ft := GradientTexture1D.new()
	ft.gradient = fade
	pm.color_ramp = ft
	p.process_material = pm
	p.draw_pass_1 = _petal_mesh
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.disable_fog = true
	p.material_override = m
	p.amount = amount
	p.lifetime = life
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-6, -3, -6), Vector3(12, 8, 12))
	return p
