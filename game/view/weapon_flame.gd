class_name WeaponFlame
extends Node3D
## 狩胜节点·光荣(凯旋击杀叠的层数，上限 10)：武器一层层被点燃。挂在武器骨上(双持两把都挂)，沿着刃(骨局部 +Y 的一段)冒火：
##   1~4 层  刃尖一点暗红的小火苗、几颗火星(层数越多火越大)
##   5~7 层  第一阶段：整条刃烧起来(橙)，刃上一团柔和的火光
##   8~9 层  第二阶段：金色的火、更大，火光更亮，往上飘的火星多起来
##   10 层   第三阶段(满)：白金色的烈焰，挥起来拖出长长的火尾和一路火星
## 火是世界坐标的粒子：挥武器时自己拖出火尾。武器扔出去(UnitView.weapon_hidden)时手上不冒火。
## 跨过 5 / 8 / 10 的那一下由 BattleView 放阶段特效(Fx.weapon_ignite)

## 各武器大类的刃(骨局部 +Y，体素)：火从哪一段冒出来
const BLADE := {"heavy": [16.0, 78.0], "sword": [18.0, 58.0], "polearm": [56.0, 90.0], "dual": [6.0, 27.0]}
const STAGES := [5, 8, 10]
const VOX := 0.0125

var view: UnitView = null
var wclass: String = "polearm"
var level: int = 0
var cap: int = 10
var _k: float = 0.0                       # 平滑过去的火势(0..1)
var _stage: int = -1
var _parts: Array = []                    # 每把武器：{att, flame, heat, embers, glow, glow_mat}


static func create(p_view: UnitView, p_wclass: String) -> WeaponFlame:
	var wf := WeaponFlame.new()
	wf.view = p_view
	wf.wclass = p_wclass if BLADE.has(p_wclass) else "sword"
	return wf


func _ready() -> void:
	var sk: Skeleton3D = UnitSkin.skeleton_of(view.model)
	var bones: Array = ["Bow", "Weapon_L"] if wclass == "dual" else ["Bow"]
	var bl: Array = BLADE[wclass]
	var y0: float = float(bl[0]) * VOX
	var y1: float = float(bl[1]) * VOX
	for bn: Variant in bones:
		if sk.find_bone(str(bn)) < 0:
			continue
		var att := BoneAttachment3D.new()
		att.bone_name = str(bn)
		sk.add_child(att)
		var holder := Node3D.new()
		holder.position = Vector3(0.0, (y0 + y1) * 0.5, 0.0)
		att.add_child(holder)
		var half: float = (y1 - y0) * 0.5
		var flame: GPUParticles3D = _fire(14, 0.24, 0.06, true)
		var heat: GPUParticles3D = _fire(40, 0.34, 0.1, false)
		var embers: GPUParticles3D = _embers()
		for p: GPUParticles3D in [flame, heat, embers]:
			(p.process_material as ParticleProcessMaterial).emission_box_extents = Vector3(0.02, half, 0.025)
			holder.add_child(p)
		var glow := MeshInstance3D.new()
		glow.mesh = SoftFX.quad(1.0)
		var gm: StandardMaterial3D = SoftFX.sprite_mat(Color("#ff7a2a"), 1.0, true)
		gm.albedo_color.a = 0.0
		gm.disable_fog = true
		glow.material_override = gm
		glow.scale = Vector3.ONE * (half * 1.1 + 0.12)
		glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(glow)
		_parts.append({"att": att, "flame": flame, "heat": heat, "embers": embers, "glow": glow, "glow_mat": gm, "holder": holder})
	_apply_stage(0)


func _exit_tree() -> void:
	for pt: Dictionary in _parts:
		if is_instance_valid(pt["att"]):
			(pt["att"] as Node).queue_free()


func set_level(n: int, p_cap: int = 10) -> void:
	level = maxi(0, n)
	cap = maxi(1, p_cap)


## 刃的中点(世界坐标)：阶段特效放在这
func blade_center() -> Vector3:
	if _parts.is_empty():
		return view.global_position + Vector3(0.0, 1.0, 0.0)
	return (_parts[0]["holder"] as Node3D).global_position


static func stage_of(n: int) -> int:
	var st := 0
	for th: int in STAGES:
		if n >= th:
			st += 1
	return st


func _process(delta: float) -> void:
	if view == null or not is_instance_valid(view):
		queue_free()
		return
	var target: float = clampf(float(level) / float(cap), 0.0, 1.0)
	_k = move_toward(_k, target, delta * 1.5)
	var st: int = stage_of(level)
	if st != _stage:
		_apply_stage(st)
	var on: bool = level > 0 and not view.weapon_hidden and not view.dying
	var t: float = Time.get_ticks_msec() * 0.001
	for pt: Dictionary in _parts:
		var flame: GPUParticles3D = pt["flame"]
		var heat: GPUParticles3D = pt["heat"]
		var embers: GPUParticles3D = pt["embers"]
		flame.emitting = on
		heat.emitting = on
		embers.emitting = on and level >= 3
		# 1~4 层只有刃尖冒火(发射盒子缩到刃的上面一截)，5 层起整条刃都烧
		var full: float = clampf((float(level) - 4.0) / 1.0, 0.0, 1.0)
		var holder: Node3D = pt["holder"]
		for p: GPUParticles3D in [flame, heat]:
			var pm: ParticleProcessMaterial = p.process_material
			var ext: Vector3 = pm.emission_box_extents
			var core: float = 0.5 if p == flame else 1.0          # 叠加的亮芯小一圈，外面那层普通混合的火身(白地上看得见)
			p.position = Vector3(0.0, ext.y * (1.0 - full) * 0.75, 0.0)
			p.amount_ratio = clampf(0.25 + 0.75 * _k, 0.0, 1.0) * (0.35 + 0.65 * maxf(full, 0.4))
			pm.scale_min = (0.09 + 0.12 * _k) * core
			pm.scale_max = (0.13 + 0.2 * _k) * core
			pm.initial_velocity_min = 0.2 + 0.3 * _k
			pm.initial_velocity_max = 0.35 + 0.7 * _k
			# 火往世界的上方窜(发射方向是发射器局部的：武器怎么转都换算成"朝上")
			var up_l: Vector3 = p.global_transform.basis.inverse() * Vector3.UP
			if up_l.length() > 0.001:
				pm.direction = up_l.normalized()
		embers.amount_ratio = clampf(_k, 0.0, 1.0)
		var eu: Vector3 = embers.global_transform.basis.inverse() * Vector3.UP
		if eu.length() > 0.001:
			(embers.process_material as ParticleProcessMaterial).direction = eu.normalized()
		var gm: StandardMaterial3D = pt["glow_mat"]
		var ga: float = (0.0 if st < 2 else 0.1 + 0.06 * float(st - 2)) * (0.85 + 0.15 * sin(t * 9.0))
		gm.albedo_color.a = ga if on else 0.0
		(pt["glow"] as Node3D).visible = on and ga > 0.01
		holder.visible = true


## 换阶段：火的颜色(暗红 → 橙 → 金 → 白金)、火星的多少和寿命(满层拖出长长的火尾)
func _apply_stage(st: int) -> void:
	_stage = st
	var cols: Array = [Color("#e8461a"), Color("#ff7a1a"), Color("#ffb02a"), Color("#ffd86a")]
	var c: Color = cols[clampi(st, 0, 3)]
	for pt: Dictionary in _parts:
		var flame: GPUParticles3D = pt["flame"]
		(flame.process_material as ParticleProcessMaterial).color_ramp = SoftFX.ramp([Color(1.0, 0.95, 0.7, 0.0), Color(1.0, 0.92, 0.6, 0.8),
			Color(c.r, c.g * 0.85, c.b * 0.5, 0.4), Color(c.r * 0.5, c.g * 0.2, c.b * 0.1, 0.0)], [0.0, 0.1, 0.45, 1.0])
		flame.lifetime = 0.26 + 0.06 * float(st)
		(pt["heat"] as GPUParticles3D).lifetime = 0.34 + 0.08 * float(st)
		# 火身(普通混合)：黄 → 饱和的橙 → 暗红 → 一点黑烟；阶段越高越偏金
		var heat: GPUParticles3D = pt["heat"]
		var tip_c: Color = Color(1.0, 0.82, 0.3).lerp(Color(1.0, 0.95, 0.6), clampf(float(st) - 1.0, 0.0, 2.0) * 0.5)
		(heat.process_material as ParticleProcessMaterial).color_ramp = SoftFX.ramp([Color(tip_c.r, tip_c.g, tip_c.b, 0.0),
			Color(tip_c.r, tip_c.g, tip_c.b, 0.9), Color(c.r, c.g * 0.75, c.b * 0.4, 0.85), Color(c.r * 0.8, c.g * 0.28, c.b * 0.1, 0.6),
			Color(0.22, 0.05, 0.02, 0.0)], [0.0, 0.08, 0.3, 0.65, 1.0])
		var embers: GPUParticles3D = pt["embers"]
		embers.lifetime = 0.7 + 0.35 * float(st)
		(pt["glow_mat"] as StandardMaterial3D).albedo_color = Color(c.r * 1.2, c.g * 1.1, c.b, (pt["glow_mat"] as StandardMaterial3D).albedo_color.a)


func _fire(n: int, life: float, size: float, additive: bool) -> GPUParticles3D:
	var p: GPUParticles3D = SoftFX.particles(n, life, SoftFX.fire_ramp(Color("#e8461a"), 1.4, false), size, additive)
	var pm: ParticleProcessMaterial = p.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.5
	pm.gravity = Vector3(0, 1.8, 0)
	pm.damping_min = 0.0
	pm.damping_max = 0.2
	# 火舌：一出来最大、往上窜的时候越来越细(不是一团往外胀的光)
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.7))
	curve.add_point(Vector2(0.15, 1.0))
	curve.add_point(Vector2(1.0, 0.12))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	pm.damping_min = 0.5
	pm.damping_max = 1.0
	(p.material_override as StandardMaterial3D).disable_fog = true
	p.visibility_aabb = AABB(Vector3(-4, -2, -4), Vector3(8, 8, 8))
	p.emitting = false
	p.amount_ratio = 0.0
	return p


func _embers() -> GPUParticles3D:
	var p: GPUParticles3D = SoftFX.particles(16, 0.8, SoftFX.ramp([Color(1.0, 0.9, 0.5, 0.0), Color(1.0, 0.75, 0.3, 1.0), Color(1.0, 0.4, 0.1, 0.0)],
		[0.0, 0.1, 1.0]), 0.03, true)
	var pm: ParticleProcessMaterial = p.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 60.0
	pm.initial_velocity_min = 0.4
	pm.initial_velocity_max = 1.4
	pm.gravity = Vector3(0, 0.9, 0)
	pm.scale_min = 0.025
	pm.scale_max = 0.045
	(p.material_override as StandardMaterial3D).disable_fog = true
	p.visibility_aabb = AABB(Vector3(-4, -2, -4), Vector3(8, 8, 8))
	p.emitting = false
	return p
