class_name BeastSpirit
extends Node3D
## 守林节点的背后灵：她每个兽形身后浮着那种野兽的灵体(模型 tools/model_spirits.gd → assets/world/spirit_<兽>_<部件>.res)，
##   狮子 = 金色、巨蛛 = 紫色、巨蟾 = 青绿(灵体着色器按形态上色，模型只有灰阶明暗；发光体素 = 眼睛 / 爪尖 / 背上的纹，更亮)。
## 比她大一圈、浮在她身后上方(像替身一样压在她背后)，跟着她走、转身。动作全是代码驱动的关节转动：
##   待机   狮子：呼吸、头慢慢摆、尾巴一甩一甩；巨蛛：八条腿此起彼伏地挪、肚子一鼓一鼓、螯牙抽动；巨蟾：喉咙一鼓一鼓、眼睛眨
##   移动   狮子：四条腿奔跑、身子起伏；巨蛛：八条腿交替快走；巨蟾：一蹦一蹦
##   普攻   attack(目标, 前摇)：前摇里蓄力，出手那一刻——狮子扑出去、张嘴吼、前爪撕下去；巨蛛扬起身子再一口咬下去；巨蟾张嘴吐出长舌打到目标身上再收回
##   出现 / 消失：appear() 从下往上一格格凝出来(体素溶解的反向) + 一闪；vanish() 一格格散掉、往上飘，然后删掉自己
## 世界坐标(top_level)，每帧跟到 follow(她的 UnitView)身后。

const COLS := {"lion": Color("#ffaa22"), "spider": Color("#9a5cff"), "toad": Color("#2fe0a0")}
const SCALE := {"lion": 1.25, "spider": 1.15, "toad": 1.2}
const BACK := 0.95                       # 在她身后多远(米)
const LIFT := 0.28                       # 浮起多高

const SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_prepass_alpha, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 col : source_color = vec4(1.0, 0.78, 0.35, 1.0);
uniform float fade = 1.0;
uniform float dissolve = 0.0;
uniform float flash = 0.0;
varying vec3 wp;
varying float vh;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vh = UV.y;
}
void fragment() {
	if (vh < dissolve) {
		discard;
	}
	float lum = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	float fr = pow(1.0 - clamp(abs(dot(normalize(NORMAL), VIEW)), 0.0, 1.0), 1.5);
	vec3 deep = col.rgb * 0.28;
	vec3 lite = mix(col.rgb, vec3(1.0), 0.12);
	vec3 c = mix(deep, lite, smoothstep(0.15, 0.95, lum));
	c = mix(c, mix(col.rgb, vec3(1.0), 0.4), fr * 0.75);
	float stream = smoothstep(0.82, 1.0, sin(wp.y * 16.0 - TIME * 3.5 + wp.x * 3.0) * 0.5 + 0.5);
	c += col.rgb * stream * 0.25;
	c += mix(col.rgb, vec3(1.0), 0.6) * COLOR.a * 2.5;
	float edge = 1.0 - smoothstep(dissolve, dissolve + 0.08, vh);
	c = mix(c, vec3(1.0), edge * step(0.001, dissolve));
	c = mix(c, vec3(1.0), flash * 0.5);
	ALBEDO = c * (1.0 + flash * 0.4);
	float a = 0.3 + 0.55 * fr + 0.12 * stream + 0.7 * COLOR.a + flash * 0.3;
	ALPHA = clamp(a, 0.0, 1.0) * fade;
}
"""

static var _shader: Shader = null

var kind: String = "lion"
var follow: UnitView = null
var bu: BUnit = null
var color: Color = Color.WHITE
var _mat: ShaderMaterial
var _parts: Dictionary = {}              # 名字 -> Node3D(关节)
var _rest: Dictionary = {}               # 名字 -> 关节的静止 Transform3D
var _legs: Array = []                    # [关节, 相位, 静止旋转] (巨蛛的八条腿 / 狮子、巨蟾的腿)
var _t: float = 0.0
var _move_k: float = 0.0
var _atk_t: float = -1.0                 # 普攻动作的进度(秒，从出手前的蓄力开始)；< 0 = 没在打
var _atk_wind: float = 0.3               # 蓄力多久(= 她的前摇)
var _atk_target: Vector3 = Vector3.ZERO
var _flash: float = 0.0
var _dissolve: float = 1.0
var _dying: bool = false
var _hop: float = 0.0
var _tongue_len: float = 0.0


static func create(p_kind: String, p_follow: UnitView, p_unit: BUnit) -> BeastSpirit:
	var b := BeastSpirit.new()
	b.kind = p_kind
	b.follow = p_follow
	b.bu = p_unit
	b.color = COLS.get(p_kind, Color("#9fe07a"))
	return b


func _ready() -> void:
	top_level = true
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	_mat.set_shader_parameter("col", color)
	_mat.set_shader_parameter("dissolve", 1.0)
	_mat.render_priority = 1
	var holder := Node3D.new()
	holder.name = "Holder"
	add_child(holder)
	holder.scale = Vector3.ONE * float(SCALE.get(kind, 1.2))
	match kind:
		"lion":
			_build_lion(holder)
		"spider":
			_build_spider(holder)
		"toad":
			_build_toad(holder)
	for nm: String in _parts.keys():
		_rest[nm] = (_parts[nm] as Node3D).transform
	if follow != null and is_instance_valid(follow):
		global_position = _home()
		rotation.y = follow.rotation.y
	appear()


## 一个部件：加载 assets/world/spirit_<兽>_<部件>.res，挂在 parent 下 at 处；mirror = 左右镜像(右边那条腿)
func _part(nm: String, parent: Node3D, at: Vector3, mirror: bool = false, rot: Vector3 = Vector3.ZERO) -> Node3D:
	var joint := Node3D.new()
	joint.name = nm + ("_r" if mirror else "")
	joint.set_meta("mir", -1.0 if mirror else 1.0)
	joint.position = at
	joint.rotation = rot
	parent.add_child(joint)
	var path: String = "res://assets/world/spirit_%s_%s.res" % [kind, nm]
	if ResourceLoader.exists(path):
		var mi := MeshInstance3D.new()
		mi.mesh = load(path) as Mesh
		mi.material_override = _mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mirror:
			mi.scale = Vector3(-1.0, 1.0, 1.0)
		joint.add_child(mi)
	_parts[String(joint.name)] = joint
	return joint


func _build_lion(h: Node3D) -> void:
	var body: Node3D = _part("body", h, Vector3(0.0, 1.05, 0.0))
	var head: Node3D = _part("head", body, Vector3(0.0, 0.3, 0.72))
	_part("jaw", head, Vector3(0.0, -0.17, 0.45))
	_legs.append([_part("leg_f", body, Vector3(0.3, -0.2, 0.5)), 0.0, Vector3.ZERO])
	_legs.append([_part("leg_f", body, Vector3(-0.3, -0.2, 0.5), true), PI, Vector3.ZERO])
	_legs.append([_part("leg_b", body, Vector3(0.3, -0.12, -0.55)), PI, Vector3.ZERO])
	_legs.append([_part("leg_b", body, Vector3(-0.3, -0.12, -0.55), true), 0.0, Vector3.ZERO])
	_part("tail", body, Vector3(0.0, 0.25, -0.75))


func _build_spider(h: Node3D) -> void:
	var ceph: Node3D = _part("ceph", h, Vector3(0.0, 0.72, 0.3))
	_part("abdomen", ceph, Vector3(0.0, 0.06, -0.32))
	_part("fang", ceph, Vector3(0.1, -0.12, 0.4))
	_part("fang", ceph, Vector3(-0.1, -0.12, 0.4), true)
	# 八条腿：左边四条往左前 → 左后张开，右边镜像(腿的模型沿 +X 伸出去，绕 Y 转到各自的方向)
	var yaws: Array = [-55.0, -20.0, 15.0, 50.0]
	for i in range(4):
		var z: float = 0.18 - 0.12 * float(i)
		var yl: float = deg_to_rad(float(yaws[i]))
		_legs.append([_part("leg", ceph, Vector3(0.22, 0.0, z), false, Vector3(0.0, yl, 0.0)), float(i) * PI * 0.5, Vector3(0.0, yl, 0.0)])
		var yr: float = deg_to_rad(-float(yaws[i]))
		_legs.append([_part("leg", ceph, Vector3(-0.22, 0.0, z), true, Vector3(0.0, yr, 0.0)), float(i) * PI * 0.5 + PI, Vector3(0.0, yr, 0.0)])
	# 镜像的腿：模型沿 -X 伸出去(scale x -1)，绕 Y 的角度也镜像


func _build_toad(h: Node3D) -> void:
	var body: Node3D = _part("body", h, Vector3(0.0, 0.5, 0.0))
	var jaw: Node3D = _part("jaw", body, Vector3(0.0, -0.1, 0.42))
	var tongue: Node3D = _part("tongue", jaw, Vector3(0.0, 0.02, 0.1))
	tongue.scale = Vector3(1.0, 1.0, 0.05)
	tongue.visible = false
	_legs.append([_part("leg_f", body, Vector3(0.48, -0.12, 0.42)), 0.0, Vector3.ZERO])
	_legs.append([_part("leg_f", body, Vector3(-0.48, -0.12, 0.42), true), 0.0, Vector3.ZERO])
	_legs.append([_part("leg_b", body, Vector3(0.52, -0.05, -0.35)), 0.0, Vector3.ZERO])
	_legs.append([_part("leg_b", body, Vector3(-0.52, -0.05, -0.35), true), 0.0, Vector3.ZERO])


## 她身后上方
func _home() -> Vector3:
	var yaw: float = follow.rotation.y
	var fwd := Vector3(sin(yaw), 0.0, cos(yaw))
	return follow.global_position - fwd * BACK + Vector3(0.0, LIFT + 0.06 * sin(_t * 1.4), 0.0)


## 从下往上一格格凝出来 + 一闪
func appear() -> void:
	_dissolve = 1.0
	_flash = 1.0
	_dying = false


## 一格格散掉，散完删掉自己
func vanish() -> void:
	_dying = true


## 普攻：wind = 离出手还有多久(秒，真实时间)；at = 目标的胸口
func attack(at: Vector3, wind: float) -> void:
	if _dying:
		return
	_atk_t = 0.0
	_atk_wind = clampf(wind, 0.12, 0.6)
	_atk_target = at


## 吼一声(胜利 / 变身)：不打人，原地扬起来、张嘴
func roar() -> void:
	if _dying:
		return
	_atk_t = 0.0
	_atk_wind = 0.25
	_atk_target = global_position + Vector3(sin(rotation.y), 0.0, cos(rotation.y)) * 3.0 + Vector3(0.0, 1.0, 0.0)
	_flash = maxf(_flash, 0.6)


func _process(delta: float) -> void:
	_t += delta
	if follow == null or not is_instance_valid(follow) or follow.dying:
		_dying = true
	_dissolve = minf(1.0, _dissolve + delta / 0.55) if _dying else maxf(0.0, _dissolve - delta / 0.6)
	if _dying and _dissolve >= 1.0:
		queue_free()
		return
	_flash = maxf(0.0, _flash - delta * 2.0)
	_mat.set_shader_parameter("dissolve", _dissolve)
	_mat.set_shader_parameter("flash", _flash)
	if follow == null or not is_instance_valid(follow):
		position.y += delta * 0.6                     # 散掉时往上飘
		return
	var moving: bool = bu != null and bu.alive and bu.vel.length() > 0.35
	_move_k = move_toward(_move_k, 1.0 if moving else 0.0, delta * 4.0)
	global_position = global_position.lerp(_home(), 1.0 - exp(-delta * 7.0))
	if _dying:
		global_position.y += _dissolve * 0.8
	var face: float = follow.rotation.y
	if _atk_t >= 0.0:
		var d: Vector3 = _atk_target - global_position
		if Vector2(d.x, d.z).length() > 0.1:
			face = atan2(d.x, d.z)
	rotation.y = lerp_angle(rotation.y, face, 1.0 - exp(-delta * 8.0))
	var atk: float = -1.0
	if _atk_t >= 0.0:
		_atk_t += delta
		atk = _atk_t
		if _atk_t > _atk_wind + 0.6:
			_atk_t = -1.0
	_reset_pose()
	match kind:
		"lion":
			_pose_lion(atk)
		"spider":
			_pose_spider(atk)
		"toad":
			_pose_toad(atk, delta)


func _reset_pose() -> void:
	for nm: String in _rest.keys():
		(_parts[nm] as Node3D).transform = _rest[nm]
	($Holder as Node3D).position = Vector3.ZERO
	($Holder as Node3D).rotation = Vector3.ZERO


## 普攻的三段：蓄力 0 → 1(前摇里)、出手的一下 0 → 1 → 0(出手前后 0.25 秒)、收势
func _phases(atk: float) -> Array:
	if atk < 0.0:
		return [0.0, 0.0]
	var wind: float = clampf(atk / _atk_wind, 0.0, 1.0)
	var after: float = atk - _atk_wind
	var strike: float = 0.0
	if after >= 0.0:
		strike = clampf(after / 0.08, 0.0, 1.0) * (1.0 - clampf((after - 0.18) / 0.35, 0.0, 1.0))
		wind = 1.0 - clampf(after / 0.1, 0.0, 1.0)
	return [wind, strike]


func _pose_lion(atk: float) -> void:
	var body: Node3D = _parts["body"]
	var head: Node3D = _parts["head"]
	var jaw: Node3D = _parts["jaw"]
	var tail: Node3D = _parts["tail"]
	var ph: Array = _phases(atk)
	var wind: float = ph[0]
	var strike: float = ph[1]
	var br: float = sin(_t * 2.2)
	body.scale = Vector3(1.0, 1.0 + 0.025 * br, 1.0)
	head.rotation += Vector3(0.04 * br - 0.25 * wind + 0.2 * strike, 0.18 * sin(_t * 0.7) * (1.0 - _move_k), 0.0)
	jaw.rotation.x += 0.08 + 0.75 * maxf(wind * 0.6, strike)
	tail.rotation += Vector3(0.2 + 0.25 * sin(_t * 3.0), 0.5 * sin(_t * 1.7), 0.0)
	# 跑：四条腿前后摆、身子起伏
	var run: float = _t * 11.0
	for L: Array in _legs:
		var j: Node3D = L[0]
		j.rotation.x += 0.65 * _move_k * sin(run + float(L[1]))
	body.position.y += 0.06 * _move_k * absf(sin(run))
	body.rotation.x += 0.05 * _move_k * sin(run)
	# 普攻：后坐扬起(前半身抬、前爪举高)→ 扑出去(整只往前冲、前爪往下撕)
	var holder: Node3D = $Holder
	holder.position.z += -0.15 * wind + 0.55 * strike
	holder.position.y += 0.12 * wind
	body.rotation.x += -0.35 * wind + 0.18 * strike
	var fl: Node3D = _legs[0][0]
	fl.rotation.x += -1.3 * wind + 0.9 * strike
	var fr: Node3D = _legs[1][0]
	fr.rotation.x += -0.5 * wind + 0.3 * strike


func _pose_spider(atk: float) -> void:
	var ceph: Node3D = _parts["ceph"]
	var abd: Node3D = _parts["abdomen"]
	var ph: Array = _phases(atk)
	var wind: float = ph[0]
	var strike: float = ph[1]
	abd.scale = Vector3.ONE * (1.0 + 0.03 * sin(_t * 1.8))
	abd.rotation.x += 0.08 * sin(_t * 1.1)
	# 腿：此起彼伏地抬(绕腿自己的前后轴 = 关节局部的 Z 轴转)，走的时候快、幅度大，还前后划
	var speed: float = lerpf(2.2, 12.0, _move_k)
	for L: Array in _legs:
		var j: Node3D = L[0]
		var ph0: float = float(L[1])
		var mir: float = float(j.get_meta("mir", 1.0))
		var lift: float = maxf(0.0, sin(_t * speed + ph0)) * lerpf(0.12, 0.35, _move_k)
		j.rotate_object_local(Vector3(0, 0, 1), lift * mir)
		j.rotate_object_local(Vector3(0, 1, 0), 0.25 * _move_k * cos(_t * speed + ph0) * mir)
	# 普攻：前半身扬起来、前面两对腿举高 → 一口往前下咬下去
	var holder: Node3D = $Holder
	holder.position.z += 0.4 * strike - 0.1 * wind
	ceph.rotation.x += -0.45 * wind + 0.35 * strike
	for i in range(4):
		var j2: Node3D = _legs[i][0]
		var mir2: float = float(j2.get_meta("mir", 1.0))
		j2.rotate_object_local(Vector3(0, 0, 1), (0.6 * wind - 0.2 * strike) * mir2)
	for fn: String in ["fang", "fang_r"]:
		if _parts.has(fn):
			var f: Node3D = _parts[fn]
			f.rotation.x += -0.5 * wind + 0.7 * strike + 0.1 * sin(_t * 9.0)


func _pose_toad(atk: float, delta: float) -> void:
	var body: Node3D = _parts["body"]
	var jaw: Node3D = _parts["jaw"]
	var tongue: Node3D = _parts["tongue"]
	var ph: Array = _phases(atk)
	var wind: float = ph[0]
	var strike: float = ph[1]
	# 喉咙一鼓一鼓
	var gulp: float = maxf(0.0, sin(_t * 2.4))
	body.scale = Vector3(1.0 + 0.03 * gulp + 0.06 * wind, 1.0 + 0.05 * gulp + 0.08 * wind, 1.0)
	# 一蹦一蹦
	_hop = fposmod(_hop + delta * 1.8 * _move_k, 1.0) if _move_k > 0.01 else 0.0
	var hk: float = sin(_hop * PI) * _move_k
	var holder: Node3D = $Holder
	holder.position.y += 0.45 * hk
	body.rotation.x += -0.2 * hk
	for i in range(2, 4):
		var lb: Node3D = _legs[i][0]
		lb.rotation.x += 0.8 * hk
	# 普攻：鼓起来、往后一缩 → 张嘴、舌头打到目标身上(按距离拉长) → 收回
	body.rotation.x += 0.12 * wind - 0.1 * strike
	jaw.rotation.x += 0.05 + 0.65 * maxf(wind * 0.3, strike)
	if strike > 0.01:
		tongue.visible = true
		var from: Vector3 = tongue.global_position
		var dist: float = maxf(0.2, from.distance_to(_atk_target))
		var sc: float = holder.scale.x
		tongue.look_at(_atk_target, Vector3.UP)
		tongue.rotate_object_local(Vector3.UP, PI)                     # 舌头的模型沿 +Z；look_at 让 -Z 朝目标
		tongue.scale = Vector3(1.0, 1.0, maxf(0.05, dist / sc * strike))
	else:
		tongue.visible = false
