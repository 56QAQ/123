class_name UnitView
extends Node3D
## 棋子的 3D 表现：体素模型(手里拿着当前武器) + 动画(该武器大类的动作模组) + 头顶血条 + 脚下队伍环。
## 备战期由花名册数据驱动(待机；站久了随机播一次该模型的待机小动作，各棋子错开)；战斗期绑定 BUnit，位置/朝向/动画都读取逻辑层；
## 胜利时播该模型的胜利动作。小动作和胜利动作都会收起武器(动画把武器骨缩到 0)。

const MODEL_SCENE := preload("res://scenes/unit_model.tscn")
const BAR_SHADER := preload("res://assets/hp_bar.gdshader")

var def: UnitDef
var star: int = 1
var team: int = 0
var weapon: EquipmentDef = null
var look: Dictionary = {}               # UnitSkin.look_for：武器大类/外观/颜色/副手盾
var model: Node3D
var ap: AnimationPlayer
var bu: BUnit = null
var roster_id: String = ""
var bench_index: int = -1
var cell: Vector2i = Vector2i(-1, -1)
var bar: MeshInstance3D
var name_label: Label3D                 # 血条上方的名字(白字 + 粗深色描边：白色地面上也清楚)
var ring: MeshInstance3D
var ring_mat: StandardMaterial3D
var hover_ring: MeshInstance3D
var mark_ring: MeshInstance3D           # QoL 高亮(可装备/同名/羁绊成员)
var scale_mult: float = 1.0
var aura: BossAura = null                # 首领 / 精英的存在感特效(缠绕的火蛇、焦土、纹章……)
var _blade_fire: GPUParticles3D = null   # 首领薙刀上一直烧着的火(武器收起 = 武器骨缩到 0 时熄掉)
var lev_target: float = 0.0              # 悬浮高度(米，吟唱大招时升到空中)：抬的是骨架节点，不碰 model 的位置(受击 / 跳跃会写它)
const FLY_HIGH := 0.95                   # 会飞的(鸟)：移动时飞多高
const FLY_LOW := 0.45                    # 会飞的：站着打的时候悬停多高
var _lev: float = 0.0
var _lev_v: float = 0.0
var _blade_bone: int = -1
var size_k: float = 1.0                  # 状态改的体型倍率(虚荣：√2)；set_size 会带一小段放大 / 缩小的过渡
var void_k: float = 0.0                  # 身体化成星空的程度(星旅节点·真实形态；着色器 void_k)
var form_size: float = 1.0               # 只是表现的体型倍率(星旅节点·真实形态 1.7)：乘在逻辑体型(size_mult)上
var size_target: float = 1.0
var beast_form: String = ""              # 守林节点的变身形态(lion / spider / toad)：待机 / 跑 / 攻击换成 <种类>_<模型>_<形态>，手里不显示武器
var _size_tw: Tween
var dying: bool = false
var dead_done: bool = false
var selected: bool = false
var hovered: bool = false
var body_height: float = 1.32
var time_scale: float = 1.0

var _state: String = "idle"            # idle / loco / attack / fidget / victory
var fidget_enabled: bool = true         # 拖动中不放待机小动作
var _fidget_at: float = 0.0             # 下一次待机小动作的时刻(_clock)
var _busy_until: float = 0.0            # 攻击等动作占用动画的截止时间(真实时间秒)
var _clock: float = 0.0
var _loop_at: float = -1.0               # 上一次切换循环动作(待机 / 跑 / 端枪)的时刻(_clock)：刚起的交叉淡化上面别再叠一层
var _flash: float = 0.0
var _flinch: float = 0.0
var _flinch_dir: Vector3 = Vector3.ZERO
var _dissolve: float = 0.0
var _die_t: float = 0.0
var _die_fast := false                    # 无我斩开的：定格一会儿后一下子崩散(die_cut)
var _pulse: float = 0.0
var _glow: float = 0.0
var ghost_target: float = 0.0          # 半透明紫色虚影(迅游节点穿过别人 / 地形)：BattleView 每帧给目标值，这里平滑过去
var _ghost_tint := Color(0.62, 0.32, 1.0)
var _ghost: float = 0.0
var _attack_anim: String = ""
var _attack_speed: float = 1.0
var trails: Array[WeaponTrail] = []      # 近战武器的刀光(双持两把)
var light_weapon: LightWeapon = null     # 正行节点·花蕊的光武器(第一次有花蕊时才挂上)
var _stop_until: float = -1.0            # 顿帧(命中停顿)结束的时刻(_clock)
var _stop_speed: float = 1.0
var weapon_hidden: bool = false          # 武器离手了(投掷出去还没拿回来)
var _leap_t0: float = -1.0               # 飞扑腾空：开始时刻、真实时长、高度、水平距离(> 0 = 按"蓄力 → 扑出去 → 砸地"重排水平进度)
var _leap_real: float = 0.0
var _leap_h: float = 0.0
var _leap_dist: float = 0.0
var _leap_off: float = 0.0               # 沿冲刺方向的表现偏移(米)：整个棋子节点(连脚下的圈、血条)一起挪，update_battle 里加上
## 远距离飞扑 / 突进的节奏(占整段的比例)：蓄力蹲在原地 → LEAP_PREP 蹬地扑出去 → LEAP_LAND 砸到地上 → 收势。逻辑层的位移是一条缓出曲线，
## 表现层把模型沿冲刺方向往回拉 / 往前推，让看上去的进度换成这一套(逻辑位置、到达时刻都不变)
const LEAP_PREP := 0.18
const LEAP_LAND := 0.85
var _emerge_t0: float = -1.0             # 从影子里升起来(踏影节点·逆光)：开始时刻、真实时长、从多深的地下升上来
var _emerge_real: float = 0.4
var _emerge_d: float = 1.2
var _fall_t0: float = -1.0               # 从天上落下来(星旅节点·渡星而来)：开始时刻(_clock)、真实时长、起始高度
var _fall_real: float = 0.0
var _fall_h: float = 0.0
var _quarry: Node3D = null               # 头顶的狩猎旗标(被标记为狩猎对象)
var chant_anim: String = ""              # 吟唱时放的动作(空 = 待机)：追猎节点的钓鱼
# 狙击窝(屏息节点：武器大类参数里的 nest)：停下来作战时单膝跪地、枪架在身前的黑箱子上；跑起来才起身
var nest_on := false
var nest_yaw := 0.0                      # 进窝时的朝向：箱子摆在这个方向，转身超过 nest.turn 度才起身换个方向重新架
var nest_crate: NestCrate = null
var _nest_idle := 0.0                    # 在窝里却没有可打的目标多久了(秒)
var _nest_clock := 0.0
var _nest_left_at := -10.0


func setup(p_def: UnitDef, p_star: int, p_team: int, boss: bool = false, p_weapon: EquipmentDef = null) -> void:
	def = p_def
	star = p_star
	team = p_team
	add_to_group("unit_views")
	# 首领 / 精英整体显示得大一圈(只是表现，碰撞半径和数值不变)
	var elite: bool = def.id.begins_with("elite_")
	scale_mult = 1.55 if boss else (1.2 if elite else 1.0)
	model = MODEL_SCENE.instantiate()
	add_child(model)
	model.scale = Vector3.ONE * def.scale * scale_mult
	ap = model.get_node("AnimationPlayer") as AnimationPlayer
	weapon = p_weapon
	look = UnitSkin.look_for(def, weapon)
	UnitSkin.apply(model, look, def.faction_id)
	ap.playback_default_blend_time = 0.12
	_refresh_trails()
	body_height = 1.30 * def.scale * scale_mult
	_build_ring()
	_build_bar()
	if (boss or elite) and team == GC.TEAM_ENEMY:
		_build_aura("boss" if boss else "elite")
	_body_fx()
	play_loop("idle")
	ap.seek(randf() * 2.5, true)
	_fidget_at = randf_range(3.0, 12.0)      # 第一次也错开，别让整排棋子同时开始


## 体型变化(虚荣的余烬获得 / 失去虚荣)：模型、脚下的圈、血条和名字一起，0.5 秒左右的过渡(放大时有一点回弹)
## 长在身体上的持续特效(跟着骨头走)：怠惰的余烬肩后的烟囱一直冒着细细的灰烟
func _body_fx() -> void:
	if def.model != "ember_sloth":
		return
	var sk: Skeleton3D = UnitSkin.skeleton_of(model)
	var bi: int = sk.find_bone("Chest")
	if bi < 0:
		return
	var ba := BoneAttachment3D.new()
	ba.bone_name = "Chest"
	sk.add_child(ba)
	var smoke: GPUParticles3D = SoftFX.particles(7, 1.8, SoftFX.ramp([Color(0.42, 0.4, 0.38, 0.0), Color(0.45, 0.42, 0.4, 0.55),
		Color(0.32, 0.3, 0.29, 0.3), Color(0.25, 0.24, 0.24, 0.0)], [0.0, 0.15, 0.6, 1.0]), 0.22, false)
	var pm: ParticleProcessMaterial = smoke.process_material
	pm.direction = Vector3(0, 1, -0.3)
	pm.spread = 12.0
	pm.initial_velocity_min = 0.25
	pm.initial_velocity_max = 0.45
	pm.gravity = Vector3(0.1, 0.25, 0)
	pm.damping_min = 0.2
	pm.damping_max = 0.4
	smoke.position = Vector3(12.5, 90.0, -12.0) * 0.0125 - sk.get_bone_global_rest(bi).origin
	smoke.emitting = true
	ba.add_child(smoke)


## 首领 / 精英的存在感：颜色取身体模型的身份色(IDENTITY 的轮廓光颜色)
func _build_aura(kind: String) -> void:
	var ident: Dictionary = UnitSkin.identity_of(def.model)
	var mid: Color = Color(str(ident.get("rim", "#e4182a")))
	var hot: Color = mid.lerp(Color("#fff2c8"), 0.55)
	if kind == "boss":
		mid = mid.lerp(Color("#c00818"), 0.35)
		hot = Color("#ff8a2a")
	aura = BossAura.make(kind, hot, mid, def.radius * scale_mult, body_height)
	add_child(aura)
	# 首领的熔岩薙刀一直烧着：刀头(武器骨局部 +Y 63~97 体素)上挂一团火，挥起来拖出火尾
	if kind == "boss" and str(look.get("model", "")) == "ember_glaive":
		var sk: Skeleton3D = UnitSkin.skeleton_of(model)
		var ba := BoneAttachment3D.new()
		ba.bone_name = "Bow"
		sk.add_child(ba)
		# 叠加混合的火团挤在一起会烧成一团白：这里用饱和的橙红(不往白里调)、低透明度
		var gr: GradientTexture1D = SoftFX.ramp([Color(1.0, 0.55, 0.15, 0.0), Color(1.0, 0.5, 0.12, 0.5), Color(0.9, 0.15, 0.06, 0.35), Color(0.3, 0.03, 0.02, 0.0)],
			[0.0, 0.12, 0.5, 1.0])
		var fl: GPUParticles3D = SoftFX.particles(16, 0.34, gr, 0.13)
		var pm: ParticleProcessMaterial = fl.process_material
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(0.02, 0.18, 0.04)
		pm.direction = Vector3(0, 1, 0)
		pm.spread = 25.0
		pm.initial_velocity_min = 0.2
		pm.initial_velocity_max = 0.6
		pm.gravity = Vector3(0, 1.4, 0)
		fl.position = Vector3(0.0, 1.0, 0.04)
		fl.emitting = true
		ba.add_child(fl)
		_blade_fire = fl
		_blade_bone = sk.find_bone("Bow")


## 星旅节点·真实形态：身体化成星空(0..1，secs 秒过渡)
func set_void(k: float, secs: float = 0.4) -> void:
	var tw := create_tween()
	tw.tween_method(func(x: float) -> void: UnitSkin.set_param(model, "void_k", x), void_k, k, maxf(0.01, secs))
	void_k = k


func set_size(k: float, animate: bool = true) -> void:
	size_target = k
	if _size_tw != null:
		_size_tw.kill()
	if not animate:
		_apply_size(k)
		return
	_size_tw = create_tween()
	var grow: bool = k > size_k
	_size_tw.tween_method(_apply_size, size_k, k, 0.55 if grow else 0.45).set_trans(Tween.TRANS_BACK if grow else Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _apply_size(k: float) -> void:
	size_k = k
	model.scale = Vector3.ONE * def.scale * scale_mult * k
	body_height = 1.30 * def.scale * scale_mult * k
	var rs: float = def.radius / 0.42 * scale_mult * k
	ring.scale = Vector3(rs, 0.7, rs)
	hover_ring.scale = ring.scale
	mark_ring.scale = Vector3(rs, 0.35, rs)
	if bar != null:
		bar.position = Vector3(0, body_height + 0.28, 0)
	if name_label != null:
		name_label.position = Vector3(0, body_height + 0.43, 0)


func _build_ring() -> void:
	ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.45 if scale_mult <= 1.0 else 0.5      # 首领 / 精英的环本来就放大了，再画那么粗就盖住了脚下的存在感特效
	tm.outer_radius = 0.55
	tm.rings = 28 if scale_mult <= 1.0 else 48
	tm.ring_segments = 6
	ring.mesh = tm
	ring.scale = Vector3(def.radius / 0.42 * scale_mult, 0.7, def.radius / 0.42 * scale_mult)
	ring.position = Vector3(0, 0.075, 0)     # 棋盘格顶面在 y=0.05，环要浮在上面
	ring_mat = StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.albedo_color = Color(0.31, 0.71, 1.0, 0.9) if team == GC.TEAM_PLAYER else Color(1.0, 0.35, 0.35, 0.9 if scale_mult <= 1.0 else 0.7)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = ring_mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	hover_ring = MeshInstance3D.new()
	var tm2 := TorusMesh.new()
	tm2.inner_radius = 0.62
	tm2.outer_radius = 0.72
	tm2.rings = 28
	tm2.ring_segments = 6
	hover_ring.mesh = tm2
	hover_ring.scale = ring.scale
	hover_ring.position = Vector3(0, 0.09, 0)
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.albedo_color = Color("#ffe27a")
	hover_ring.material_override = hm
	hover_ring.visible = false
	hover_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(hover_ring)
	mark_ring = MeshInstance3D.new()
	var tm3 := TorusMesh.new()
	tm3.inner_radius = 0.50
	tm3.outer_radius = 0.66
	tm3.rings = 28
	tm3.ring_segments = 6
	mark_ring.mesh = tm3
	mark_ring.scale = Vector3(ring.scale.x, 0.35, ring.scale.z)
	mark_ring.position = Vector3(0, 0.1, 0)
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mark_ring.material_override = mm
	mark_ring.visible = false
	mark_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mark_ring)


func _build_bar() -> void:
	bar = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.15, 0.25)
	bar.mesh = q
	var m := ShaderMaterial.new()
	m.shader = BAR_SHADER
	m.render_priority = 40
	bar.material_override = m
	bar.position = Vector3(0, body_height + 0.28, 0)
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bar)
	bar.set_instance_shader_parameter("stars", float(star))
	var fc: Color = Color("#5be071") if team == GC.TEAM_PLAYER else Color("#ee5a5a")
	bar.set_instance_shader_parameter("fill_color", fc)
	bar.set_instance_shader_parameter("tint", GC.faction_color(def.faction_id).lightened(0.15))
	bar.set_instance_shader_parameter("hp", 1.0)
	bar.set_instance_shader_parameter("shield", 0.0)
	name_label = Label3D.new()
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.no_depth_test = true
	name_label.fixed_size = false
	name_label.font = UIKit.font_bold if UIKit.font_bold != null else null
	name_label.font_size = 56
	name_label.pixel_size = 0.0056
	name_label.outline_size = 18
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	name_label.modulate = Color("#eef7ff") if team == GC.TEAM_PLAYER else Color("#ffe6e2")
	name_label.outline_modulate = Color(0.04, 0.045, 0.06, 0.95)
	name_label.render_priority = 42
	name_label.outline_render_priority = 41
	name_label.position = Vector3(0, body_height + 0.43, 0)      # 字的底边在血条上沿之上
	name_label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(name_label)
	refresh_name()


## 头顶名字(切换语言时重新取)
func refresh_name() -> void:
	if name_label != null and def != null:
		name_label.text = Loc.t("unit.%s.name" % def.id)


func set_bar_visible(v: bool) -> void:
	bar.visible = v
	name_label.visible = v


func set_star(s: int) -> void:
	star = s
	bar.set_instance_shader_parameter("stars", float(s))


## 换武器：外观(武器网格/颜色/副手盾)与动作模组一起换
func set_weapon(w: EquipmentDef) -> void:
	var same: bool = w == weapon
	weapon = w
	look = UnitSkin.look_for(def, weapon)
	_apply_beast_look()
	UnitSkin.apply(model, look, def.faction_id)
	_refresh_trails()
	if not same and not dying:
		var nm: String = UnitSkin.anim(look, "idle")
		if ap.has_animation(nm):
			ap.play(nm, 0.2)
		if _state == "fidget":
			_state = "idle"
			_fidget_at = _clock + randf_range(6.0, 14.0)


func weapon_class() -> String:
	return str(look.get("wclass", ""))


## 武器离手(投掷)：藏起手里的武器网格；拿回来时再显示
func set_weapon_hidden(v: bool) -> void:
	if weapon_hidden == v:
		return
	weapon_hidden = v
	look["hide_weapon"] = v or def.hide_weapon
	UnitSkin.apply(model, look, def.faction_id)


## 石化(奇兴节点)：变成灰石、动作定住；解除时石色退掉、动作接着放
var stone_k: float = 0.0
func set_stone(on: bool) -> void:
	var to: float = 1.0 if on else 0.0
	if absf(to - stone_k) < 0.001:
		return
	var tw: Tween = create_tween()
	tw.tween_method(func(x: float) -> void:
		stone_k = x
		UnitSkin.set_param(model, "stone", x), stone_k, to, 0.25 if on else 0.45)
	if on:
		ap.pause()
	else:
		ap.play()


## 换武器外观(无我节点拔刀)：手里的网格和专属动作一起换
## 换一个形态的 def(变奏节点·表里之间：身体、部门、武器外观跟着形态走)
func set_def(d: UnitDef) -> void:
	if d == def:
		return
	def = d
	look = UnitSkin.look_for(def, weapon)
	_apply_beast_look()
	UnitSkin.apply(model, look, def.faction_id)
	_refresh_trails()
	if not dying:
		var nm: String = UnitSkin.anim(look, "idle")
		if ap.has_animation(nm) and _state != "attack":
			ap.play(nm, 0.15)
		if _state == "fidget":
			_state = "idle"


func set_weapon_model(m: String) -> void:
	UnitSkin.set_weapon_model(look, def, m)
	UnitSkin.apply(model, look, def.faction_id)
	_refresh_trails()


## 变身(守林节点)：form = lion / spider / toad 时待机 / 跑 / 攻击换成这个形态的动作、收起武器；"" / "base" = 回到手里武器的动作模组
func set_beast_form(form: String) -> void:
	beast_form = "" if form == "base" else form
	look = UnitSkin.look_for(def, weapon)
	_apply_beast_look()
	UnitSkin.apply(model, look, def.faction_id)
	_refresh_trails()
	if not dying:
		var nm: String = UnitSkin.anim(look, "idle")
		if ap.has_animation(nm) and _state != "attack":
			ap.play(nm, 0.15)


func _apply_beast_look() -> void:
	if beast_form == "":
		return
	var ov: Dictionary = {}
	for kind: String in ["idle", "run", "attack"]:
		var nm: String = "%s_%s_%s" % [kind, def.model, beast_form]
		if ap != null and ap.has_animation(nm):
			ov[kind] = nm
	look["overrides"] = ov
	look["hide_weapon"] = true


## 投掷出去的武器：把手里的武器网格(双持连左手那把)按此刻手上的姿势复制一份，挂在一个以右手握点为原点的节点上。
## 节点的局部 +Y = 刃 / 矛尖方向(武器骨静止时的朝向 = 模型空间)，缩放 = 模型缩放；没有可见的武器返回 null
func make_thrown_weapon() -> Node3D:
	var sk: Skeleton3D = UnitSkin.skeleton_of(model)
	var l2: Dictionary = look.duplicate()
	l2["hide_weapon"] = false
	var names: Array[String] = UnitSkin.part_names(model, l2)
	var root: Node3D = null
	var root_inv := Transform3D.IDENTITY
	var k: float = model.scale.x
	for nm: String in names:
		if not (nm.begins_with("W_") or nm.begins_with("L_")):
			continue
		var src: MeshInstance3D = sk.get_node_or_null(nm) as MeshInstance3D
		if src == null:
			continue
		var bi: int = sk.find_bone("Weapon_L" if nm.begins_with("L_") else "Bow")
		var pose: Transform3D = sk.global_transform * sk.get_bone_global_pose(bi)
		pose.basis = pose.basis.orthonormalized().scaled(Vector3.ONE * k)
		if root == null:
			root = Node3D.new()
			root.transform = pose
			root_inv = pose.affine_inverse()
		var mi := MeshInstance3D.new()
		mi.mesh = src.mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.transform = (root_inv * pose) * sk.get_bone_global_rest(bi).affine_inverse()
		UnitSkin.tint(mi, str(look.get("color", def.faction_id)))
		mi.set_instance_shader_parameter("hair_ref", 0.0)
		root.add_child(mi)
	return root


## 飞扑(投掷后追着武器扑过去)：播 leap(按位移时长缩放)，模型沿抛物线腾空 height 米；dist = 扑多远(米，按"蓄力 → 扑 → 砸地"重排进度)
func play_leap(seconds: float, height: float = 0.55, dist: float = 0.0) -> void:
	if not ap.has_animation("leap"):
		return
	var real: float = maxf(0.05, seconds / maxf(0.01, time_scale))
	ap.clear_queue()
	ap.play("leap", 0.05)
	ap.seek(0.0, false)
	ap.speed_scale = ap.get_animation("leap").length / real
	_stop_until = -1.0
	_state = "attack"
	_attack_anim = "leap"
	_busy_until = _clock + real
	_leap_t0 = _clock
	_leap_real = real
	_leap_h = height
	_leap_dist = dist


## 从影子里升起来(踏影节点·逆光的瞬移落点)：模型从 depth 米深的地下升上来，seconds = 战斗时间
func emerge(seconds: float, depth: float = 1.2) -> void:
	_emerge_t0 = _clock
	_emerge_real = maxf(0.05, seconds / maxf(0.01, time_scale))
	_emerge_d = depth
	model.position.y = -depth


## 突进(止息节点·画上句点)：把指定的动作拉伸到 seconds(战斗时间)放完；height > 0 时同时腾空(空翻过目标头顶)；dist 同 play_leap
func play_lunge(anim: String, seconds: float, height: float = 0.0, dist: float = 0.0) -> void:
	if not ap.has_animation(anim):
		return
	var real: float = maxf(0.05, seconds / maxf(0.01, time_scale))
	ap.clear_queue()
	ap.play(anim, 0.05)
	ap.seek(0.0, false)
	ap.speed_scale = ap.get_animation(anim).length / real
	_stop_until = -1.0
	_state = "attack"
	_attack_anim = anim
	_busy_until = _clock + real
	if height > 0.0 or dist > 0.0:
		_leap_t0 = _clock
		_leap_real = real
		_leap_h = height
		_leap_dist = dist


## 从 height 米高处落下来，seconds = 真实时间(落地前血条和名字先藏起来)
func fall_in(seconds: float, height: float) -> void:
	_fall_t0 = _clock
	_fall_real = maxf(0.05, seconds)
	_fall_h = height
	model.position.y = height
	set_bar_visible(false)


## 被标记为狩猎对象：头顶插一面小旗(狩猎旗标的图标)、脚下一圈红色标记
func set_quarry(on: bool) -> void:
	if on == (_quarry != null):
		return
	if not on:
		_quarry.queue_free()
		_quarry = null
		clear_mark()
		return
	_quarry = Node3D.new()
	add_child(_quarry)
	var tex: Texture2D = UIKit.weapon_icons.get("hunt_flag", null) as Texture2D
	if tex != null:
		var sp := Sprite3D.new()
		sp.texture = tex
		sp.pixel_size = 0.0045
		sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sp.no_depth_test = true
		sp.render_priority = 30
		sp.shaded = false
		_quarry.add_child(sp)
	else:
		var lb := Label3D.new()
		lb.text = "◎"
		lb.modulate = Color("#ff4a3a")
		lb.font_size = 64
		lb.pixel_size = 0.006
		lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lb.no_depth_test = true
		_quarry.add_child(lb)
	_quarry.position = Vector3(0.0, body_height * size_k + 0.95, 0.0)
	set_mark(Color("#ff4a3a"))


## 刀最近的挥动(WeaponTrail.swing)：没有刀光 / 不在挥刀时返回空
func blade_swing() -> Dictionary:
	for tr: WeaponTrail in trails:
		if is_instance_valid(tr):
			var d: Dictionary = tr.swing()
			if not d.is_empty():
				return d
	return {}


## 近战武器挂刀光：右手武器骨 Bow；双持再挂左手 Weapon_L。颜色 = 武器颜色往白里调(刃光)
func _refresh_trails() -> void:
	for tr: WeaponTrail in trails:
		tr.queue_free()
	trails.clear()
	if beast_form != "":
		return                                # 变身形态：武器收起来了，爪 / 牙 / 舌头不拖刀光
	var cls: String = weapon_class()
	var sk: Skeleton3D = UnitSkin.skeleton_of(model)
	var c: Color = GC.faction_color(str(look.get("color", def.faction_id)))
	for bn: String in (["Bow", "Weapon_L"] if cls == "dual" else ["Bow"]):
		var tr2: WeaponTrail = WeaponTrail.create(sk, ap, bn, cls, c, str(look.get("model", "")))
		if tr2 != null:
			add_child(tr2)
			trails.append(tr2)


# ---------------------------------------------------------------- 动画
func play_loop(kind: String) -> void:
	var nm: String = UnitSkin.anim(look, kind) if kind in ["idle", "run", "attack"] else kind
	if not ap.has_animation(nm):
		return
	if ap.current_animation != nm:
		ap.play(nm, 0.15)
		_loop_at = _clock
	ap.speed_scale = 1.0


## anim ≠ "" = 这一下用的招式动画(群攻招式：贯穿/旋斩)，否则用武器大类的普攻动画
func play_attack(speed_scale: float, anim: String = "") -> void:
	# 拿着专属武器时把某个动作直接换成别的(无我节点：旋斩 → 挥刀鞘的旋斩 / 出鞘的旋斩；UnitSkin.set_weapon_model)
	var ovm: Dictionary = look.get("overrides", {})
	if anim != "" and ovm.has(anim):
		anim = str(ovm[anim])
	var nm: String = anim if anim != "" and ap.has_animation(anim) else UnitSkin.anim(look, "attack")
	var into_nest: bool = _nest_try_enter()
	if nest_on:
		nm = _nest_anim("fire", nm)
	if nm == "" or not ap.has_animation(nm):
		return
	ap.clear_queue()
	# 动作最慢放到原速的一半(攻速很慢时别拖沓)；慢放倍速(×0.5 / ×0.25)再跟着往下压
	var floor_s: float = 0.5 * minf(1.0, time_scale)
	# speed_scale(事件给的)已经乘过战斗倍速：播放器的全局速度要归 1(待机时它被设成了倍速)，不然倍速会乘两次——
	# ×0.25 时动作只有 1/16 速，伤害出来了动作才播个开头；×4 时又快 16 倍
	ap.speed_scale = 1.0
	# 有"端着武器"姿势(hold_anim)的大类，攻击从端枪 / 弓的预备开始、也回到那里：连射时首尾帧相接，
	# 从待机 / 跑动直接进来时交叉淡化放长一点(身体要侧过去)，别一帧扭过去
	var blend: float = 0.05
	var hold: String = str(bu.wclass().get("hold_anim", "")) if bu != null else ""
	if hold != "" and ap.current_animation != nm and ap.current_animation != hold:
		blend = 0.14
	# 上一帧刚切到待机 / 端枪(那段交叉淡化才开始)就接着开火：两层交叉淡化在相邻两帧叠起来，Godot 会混出一帧
	# "身体转回正面、弓横在胸前"的怪姿势(离线复现过：隔一帧就没事)。各大类的攻击首帧本来就 = 待机 / 端枪姿势，直接切过去不会跳
	if _clock - _loop_at < 0.06:
		blend = 0.0
	if into_nest:
		blend = 0.22                         # 站着端枪 → 直接跪下开枪：交叉淡化放长，别一帧跪下去
	ap.play(nm, blend, maxf(floor_s, speed_scale))
	# 同一个动作连着放要 seek 回 0 才会重新开始；但别带 update=true：上一段交叉淡化还没完时(待机 → 端枪 → 开火 连着切)
	# 立刻按新位置求值会把一部分权重算成静止姿势，出一帧"身体转回正面、弓横在胸前"的怪帧。下一帧正常推进时再求值就没事
	ap.seek(0.0, false)
	_state = "attack"
	_attack_anim = nm
	_attack_speed = maxf(floor_s, speed_scale)
	_busy_until = _clock + ap.get_animation(nm).length / _attack_speed * 0.92


## [吟唱] 拉弓：前摇放完接着再往后拉(anim)，拉到位后循环"用力拉住"(hold)；seconds = 真实时间。出手时 play_release
func start_draw(anim: String, hold: String, seconds: float) -> void:
	var into_nest: bool = _nest_try_enter()
	if nest_on:
		anim = _nest_anim("aim", anim)
		hold = anim
	if anim == "" or not ap.has_animation(anim):
		return
	ap.clear_queue()
	ap.play(anim, 0.22 if into_nest else 0.04)
	if hold != "" and ap.has_animation(hold):
		ap.queue(hold)
	ap.speed_scale = time_scale
	_state = "attack"
	_busy_until = _clock + seconds + 0.3


## 正在放攻击 / 拉弓 / 一次性的动作(别被别的一次性动作打断)
func is_busy() -> bool:
	return _state == "attack" and _clock < _busy_until


## 放一段一次性的动作(起竿之类)，放完回到待机 / 跑动
func play_once(anim: String) -> void:
	if anim == "" or not ap.has_animation(anim):
		return
	ap.clear_queue()
	ap.play(anim, 0.06)
	ap.seek(0.0, false)
	ap.speed_scale = maxf(0.05, time_scale)
	_stop_until = -1.0
	_state = "attack"
	_attack_anim = anim
	_busy_until = _clock + ap.get_animation(anim).length / maxf(0.05, time_scale)


## 动作道具(P_*：钓鱼竿)：显示 / 隐藏
func set_prop(part: String, on: bool) -> void:
	var sk: Skeleton3D = model.get_node_or_null("Skeleton3D") as Skeleton3D
	if sk == null or not sk.has_node(part):
		return
	var mi: MeshInstance3D = sk.get_node(part) as MeshInstance3D
	mi.visible = on
	if on:
		UnitSkin.tint(mi, def.faction_id if def != null else "white")


## 骨骼上某个静止坐标点(体素)现在的世界位置(钓鱼竿的竿尖)
## 正行节点·花蕊的光武器：第一次用到时挂到武器骨上(剑 / 长枪 / 法器以外的武器没有)
func ensure_light_weapon() -> LightWeapon:
	if light_weapon != null and is_instance_valid(light_weapon):
		return light_weapon
	light_weapon = LightWeapon.create(UnitSkin.skeleton_of(model), ap, weapon_class())
	if light_weapon != null:
		add_child(light_weapon)
	return light_weapon


## 骨头现在的原点(世界坐标)：手 / 头在哪
func bone_origin(bone: String) -> Vector3:
	var sk: Skeleton3D = model.get_node_or_null("Skeleton3D") as Skeleton3D
	if sk == null:
		return global_position
	var i: int = sk.find_bone(bone)
	if i < 0:
		return global_position
	return sk.global_transform * sk.get_bone_global_pose(i).origin


func bone_point(bone: String, rest_vox: Vector3) -> Vector3:
	var sk: Skeleton3D = model.get_node_or_null("Skeleton3D") as Skeleton3D
	if sk == null:
		return global_position
	var i: int = sk.find_bone(bone)
	if i < 0:
		return global_position
	return sk.global_transform * (sk.get_bone_global_pose(i) * sk.get_bone_global_rest(i).affine_inverse() * (rest_vox * 0.0125))


## 拉弓后放箭：有专门的放箭动画(anim)就放它，否则从普攻动画的出手时刻(release_at)接着放完
func play_release(anim: String, release_at: float) -> void:
	if anim == "" or not ap.has_animation(anim):
		resume_attack(release_at)
		return
	ap.clear_queue()
	ap.speed_scale = 1.0                         # _attack_speed 已经含战斗倍速
	ap.play(anim, 0.02, _attack_speed)
	ap.seek(0.0, false)
	_state = "attack"
	_busy_until = _clock + ap.get_animation(anim).length / _attack_speed * 0.92


## 顿帧：出手命中的一瞬把动作停住 seconds(真实时间)，打击感来自这一下"卡住"
func hitstop(seconds: float) -> void:
	if _stop_until < _clock:
		_stop_speed = ap.speed_scale
	ap.speed_scale = 0.03
	_stop_until = _clock + seconds
	_busy_until += seconds


## 拉弓结束出手：从普攻动画的出手时刻(release_at，动画时间)接着放完
func resume_attack(release_at: float) -> void:
	var nm: String = _attack_anim if _attack_anim != "" else UnitSkin.anim(look, "attack")
	if nest_on:
		nm = _nest_anim("fire", nm)
	if nm == "" or not ap.has_animation(nm):
		return
	ap.speed_scale = 1.0                         # _attack_speed 已经含战斗倍速
	ap.play(nm, 0.04, _attack_speed)
	ap.seek(release_at, false)
	_state = "attack"
	_busy_until = _clock + maxf(0.0, ap.get_animation(nm).length - release_at) / _attack_speed * 0.92


## 装弹：seconds = 真实时间，动画按这个时长放完
func play_reload(anim: String, seconds: float) -> void:
	_nest_try_enter()
	if nest_on:
		anim = _nest_anim("reload", anim)
	if anim == "" or not ap.has_animation(anim):
		return
	ap.clear_queue()
	ap.speed_scale = 1.0                         # seconds 是真实时间(已经按倍速换算)，速度全在 custom_speed 里
	ap.play(anim, 0.1, ap.get_animation(anim).length / maxf(0.05, seconds))
	ap.seek(0.0, false)
	_state = "attack"
	_busy_until = _clock + seconds


## 虚影的颜色(线性色；默认紫)：踏影节点的凝暗 = 墨青
func set_ghost_tint(c: Color) -> void:
	if c.is_equal_approx(_ghost_tint):
		return
	_ghost_tint = c
	UnitSkin.set_param(model, "ghost_tint", c)


func flash() -> void:
	_flash = 1.0


func flinch(from_dir: Vector3, flash_k: float = 0.7, push_k: float = 1.0) -> void:
	# 首领 / 精英：被一群人围着打时一直在闪白，整只怪就成了一团白影(压迫感全没了)——闪得轻、晃得小
	var big: bool = scale_mult > 1.0
	_flinch = maxf(_flinch, push_k * (0.4 if big else 1.0))
	_flinch_dir = from_dir
	_flash = maxf(_flash, flash_k * (0.3 if big else 1.0))


## anim = 阵亡动作(少女幻终之后的强制阵亡 = death_magi，没有就用通用的)
func die(anim: String = "death", blend: float = 0.05) -> void:
	if dying:
		return
	dying = true
	_die_t = 0.0
	_nest_leave()
	if aura != null and is_instance_valid(aura):
		aura.fade_out()
	if anim == "vanish":
		_die_t = 0.9                             # 魂体：不倒下，直接很快地化掉
		bar.visible = false
		name_label.visible = false
		ring.visible = false
		hover_ring.visible = false
		return
	var nm: String = anim if ap.has_animation(anim) else "death"
	if ap.has_animation(nm):
		ap.play(nm, blend)
		ap.speed_scale = 1.0
	bar.visible = false
	name_label.visible = false
	ring.visible = false
	hover_ring.visible = false


## 无我斩开的(开战被拔刀清场)：不倒下——动作定格、在原地停 delay 秒(画面黑白、身上一道刀痕)，然后一下子崩散(0.22 秒)
func die_cut(delay: float) -> void:
	if dying:
		return
	dying = true
	_die_fast = true
	_die_t = 1.0 - maxf(0.0, delay)
	ap.speed_scale = 0.0
	if aura != null and is_instance_valid(aura):
		aura.fade_out()
	bar.visible = false
	name_label.visible = false
	ring.visible = false
	hover_ring.visible = false


func win_pose() -> void:
	lev_target = 0.0
	_nest_leave()
	var nm: String = _char_anim("victory")
	if not dying and nm != "":
		ap.play(nm, 0.25)
		ap.speed_scale = 1.0
		_state = "victory"


## 该模型的专属动作名(没有就用通用的)；都没有返回 ""
func _char_anim(kind: String) -> String:
	var nm: String = UnitSkin.char_anim(look, kind)
	if ap.has_animation(nm):
		return nm
	return kind if ap.has_animation(kind) else ""


## 非战斗时：待机够久了就随机播一次待机小动作，播完淡回待机，再重新计时
func _update_fidget() -> void:
	if _state == "fidget":
		if _clock >= _busy_until or not fidget_enabled:
			stop_fidget()
		return
	if _state != "idle" or not fidget_enabled or not is_visible_in_tree():
		return
	if _clock < _fidget_at:
		return
	var nm: String = _char_anim("fidget")
	if nm == "":
		return
	ap.play(nm, 0.35)
	ap.speed_scale = 1.0
	_state = "fidget"
	_busy_until = _clock + ap.get_animation(nm).length - 0.3


func stop_fidget() -> void:
	if _state == "fidget":
		var ni: String = UnitSkin.anim(look, "idle")
		if ap.has_animation(ni):
			ap.play(ni, 0.35)          # 交叉淡化期间武器从手里长回来
		_state = "idle"
	_fidget_at = _clock + randf_range(9.0, 20.0)


func is_fidgeting() -> bool:
	return _state == "fidget"


## 技能动作(狼狩：冲锋 dash / 落地旋斩 spin)：动作名取武器大类的 skill_anims(没有就退回跑步 / 普攻)；
## seconds > 0 = 占用这么久(冲锋的实际时长，逻辑时间)，否则占用整段动作
func play_skill(kind: String, seconds: float = 0.0) -> void:
	var sa: Dictionary = GC.weapon_class(weapon_class()).get("skill_anims", {})
	var nm: String = str(sa.get(kind, ""))
	if nm == "" or not ap.has_animation(nm):
		nm = UnitSkin.anim(look, "attack" if kind == "spin" else "run")
	if nm == "" or not ap.has_animation(nm):
		return
	ap.clear_queue()
	ap.play(nm, 0.06)
	ap.seek(0.0, false)
	ap.speed_scale = maxf(0.05, time_scale)
	_stop_until = -1.0
	_state = "attack"
	_attack_anim = nm
	_attack_speed = 1.0
	var real: float = seconds if seconds > 0.0 else ap.get_animation(nm).length * 0.95
	_busy_until = _clock + real / maxf(0.05, time_scale)


## 展示用(图鉴的展台)：kind = idle / fidget / victory / attack；攻击打完自动回到待机
func showcase(kind: String) -> void:
	match kind:
		"fidget":
			stop_fidget()
			_fidget_at = _clock
		"victory":
			win_pose()
		"attack":
			play_attack(1.0)
		_:
			_state = "idle"
			play_loop("idle")
			_fidget_at = _clock + randf_range(9.0, 20.0)


func set_dissolve(v: float) -> void:
	_dissolve = v
	UnitSkin.set_param(model, "dissolve", v)


func set_glow(v: float) -> void:
	_glow = v
	UnitSkin.set_param(model, "glow_boost", v)


func pulse_bar() -> void:
	_pulse = 1.0


func set_selected(v: bool) -> void:
	selected = v
	_refresh_hover()


func set_hovered(v: bool) -> void:
	hovered = v
	_refresh_hover()


func _refresh_hover() -> void:
	hover_ring.visible = (hovered or selected) and not dying


func set_mark(c: Color) -> void:
	(mark_ring.material_override as StandardMaterial3D).albedo_color = c
	mark_ring.visible = not dying


func clear_mark() -> void:
	mark_ring.visible = false


func set_team_ring_visible(v: bool) -> void:
	ring.visible = v and not dying


# ---------------------------------------------------------------- 每帧
func _process(delta: float) -> void:
	_clock += delta
	if aura != null and is_instance_valid(aura):
		aura.time_scale = time_scale
	if _blade_fire != null and is_instance_valid(_blade_fire) and _blade_bone >= 0:
		var bs: float = UnitSkin.skeleton_of(model).get_bone_pose_scale(_blade_bone).y
		_blade_fire.emitting = bs > 0.5 and not dying
	if _stop_until >= 0.0 and _clock >= _stop_until:
		ap.speed_scale = _stop_speed
		_stop_until = -1.0
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 5.0)
		UnitSkin.set_param(model, "hit_flash", _flash * 0.8)
	if absf(ghost_target - _ghost) > 0.001:
		_ghost = move_toward(_ghost, ghost_target, delta * 6.0)
		UnitSkin.set_param(model, "ghost", _ghost)
	if _flinch > 0.0:
		_flinch = maxf(0.0, _flinch - delta * 6.5)
		model.rotation.x = -0.16 * _flinch * _flinch_dir.z
		model.position = _flinch_dir * -0.06 * _flinch
	elif model.rotation.x != 0.0:
		model.rotation.x = 0.0
		model.position = Vector3.ZERO
	if _pulse > 0.0:
		_pulse = maxf(0.0, _pulse - delta * 3.0)
		bar.set_instance_shader_parameter("pulse", _pulse)
	if _leap_t0 >= 0.0:
		var lk: float = (_clock - _leap_t0) / maxf(0.01, _leap_real)
		if lk >= 1.0:
			_leap_t0 = -1.0
			model.position.y = 0.0
			_leap_off = 0.0
		elif _leap_dist <= 0.0:
			model.position.y = _leap_h * sin(PI * lk)
		else:
			# 蓄力时贴地、扑出去走一道前高后陡的弧(四成处到顶，最后一段直直砸下去)，落地后贴地
			var fk: float = clampf((lk - LEAP_PREP) / (LEAP_LAND - LEAP_PREP), 0.0, 1.0)
			var hk: float = 0.0
			if lk > LEAP_PREP and lk < LEAP_LAND:
				hk = 1.0 - pow((0.4 - fk) / 0.4, 2.0) if fk < 0.4 else 1.0 - pow((fk - 0.4) / 0.6, 2.0)
			model.position.y = _leap_h * hk
			# 水平：蓄力时留在起点、空中一口气扑过去(稍微先快后更快)、落地后不动；减去逻辑层这一刻已经走到的进度(缓出)
			var fv: float = fk * fk * (3.0 - 2.0 * fk) * 0.45 + fk * 0.55
			var es: float = 1.0 - (1.0 - lk) * (1.0 - lk)
			_leap_off = (fv - es) * _leap_dist
	if _emerge_t0 >= 0.0:
		var ek: float = clampf((_clock - _emerge_t0) / maxf(0.01, _emerge_real), 0.0, 1.0)
		model.position.y = -_emerge_d * (1.0 - ek) * (1.0 - ek)
		if ek >= 1.0:
			_emerge_t0 = -1.0
			model.position.y = 0.0
	if _fall_t0 >= 0.0:
		var fk: float = clampf((_clock - _fall_t0) / maxf(0.01, _fall_real), 0.0, 1.0)
		model.position.y = _fall_h * (1.0 - fk * fk)          # 越落越快
		if fk >= 1.0:
			_fall_t0 = -1.0
			model.position.y = 0.0
	if absf(lev_target - _lev) > 0.0005 or absf(_lev_v) > 0.0005:
		# 弹簧阻尼地升上去 / 落下来(升得快、到顶微微过冲再稳住；落下慢一点)
		var kk: float = 34.0 if lev_target > _lev else 18.0
		var dt: float = delta * maxf(0.25, time_scale)
		_lev_v += (lev_target - _lev) * kk * dt - _lev_v * 2.0 * sqrt(kk) * 0.75 * dt
		_lev += _lev_v * dt
		var skl: Skeleton3D = UnitSkin.skeleton_of(model)
		skl.position.y = _lev / maxf(0.01, model.scale.y)
	if _quarry != null:
		_quarry.position.y = body_height * size_k + 0.95 + 0.06 * sin(_clock * 4.0)
	if hover_ring.visible:
		hover_ring.rotation.y += delta * 1.5
	if mark_ring.visible:
		var k: float = 1.0 + 0.06 * sin(_clock * 6.0)
		mark_ring.scale = Vector3(ring.scale.x * k, 0.35, ring.scale.z * k)
	if bu == null and not dying:
		# 战斗外的展示：攻击动作打完回到待机
		if _state == "attack" and _clock >= _busy_until:
			_state = "idle"
			play_loop("idle")
		_update_fidget()
	if dying:
		_die_t += delta
		if _die_fast:
			if _die_t > 1.0:
				set_dissolve(clampf((_die_t - 1.0) / 0.22, 0.0, 1.0))
			if _die_t > 1.3:
				dead_done = true
		else:
			if _die_t > 1.0:
				set_dissolve(clampf((_die_t - 1.0) / 0.7, 0.0, 1.0))
			if _die_t > 1.75:
				dead_done = true


## 战斗期：读取逻辑层状态。alpha = 逻辑步内插系数
func update_battle(alpha: float) -> void:
	if bu == null:
		return
	var p: Vector2 = bu.prev_pos.lerp(bu.pos, alpha)
	position = Vector3(p.x, 0.0, p.y)
	rotation.y = lerp_angle(bu.prev_facing, bu.facing, alpha)
	if _leap_off != 0.0:
		position += Vector3(sin(rotation.y), 0.0, cos(rotation.y)) * _leap_off       # 飞扑的节奏(蓄力留在原地、扑出去追上)
	if not bu.alive:
		return
	var mx: float = bu.get_stats().max_health
	bar.set_instance_shader_parameter("hp", clampf(bu.hp / mx, 0.0, 1.0))
	bar.set_instance_shader_parameter("shield", clampf(bu.shield / mx, 0.0, 1.0))
	# 会飞的(巫术节点的鸟)：移动时飞起来，站着打的时候低低地悬停，没有敌人时落在地上
	if bu.has_flag("flying"):
		var fsp: float = bu.vel.length()
		var fight: bool = bu.target != null and bu.target.alive and bu.target.team != bu.team
		lev_target = FLY_HIGH if fsp > 0.35 else (FLY_LOW if fight or (_state == "attack" and _clock < _busy_until) else 0.0)
	_nest_update()
	if _state == "victory" or (_state == "attack" and _clock < _busy_until):
		return
	_state = "loco"
	ap.clear_queue()
	# 摸鱼(空白节点)：蹲在原地打瞌睡
	if bu.has_flag("slacker") and ap.has_animation("idle_slack"):
		if ap.current_animation != "idle_slack":
			ap.play("idle_slack", 0.3)
		ap.speed_scale = time_scale
		return
	# 缩头(架盾节点的被动 2)：蹲到大盾后面发抖，直到状态结束
	if bu.has_flag("turtle") and ap.has_animation("turtle"):
		if ap.current_animation != "turtle":
			ap.play("turtle", 0.22)
		ap.speed_scale = time_scale
		return
	if bu.phase == "chant":
		play_loop(chant_anim if chant_anim != "" and ap.has_animation(chant_anim) else "idle")
		return
	if lev_target > 0.0 and not bu.has_flag("flying"):
		lev_target = 0.0                         # 吟唱完还活着(大招之后没有倒下)：落回地面
	var spd: float = bu.vel.length()
	if spd > 0.35:
		var nm: String = UnitSkin.anim(look, "run")
		if ap.current_animation != nm:
			ap.play(nm, 0.25 if _clock - _nest_left_at < 0.2 else 0.12)       # 刚从跪姿起身：淡化放长一点(站起来的过程)
			_loop_at = _clock
		ap.speed_scale = clampf(spd / float(bu.def.ai.get("run_ref_speed", 1.55)), 0.7, 2.4) * time_scale
	elif spd < 0.15:
		var ni: String = UnitSkin.anim(look, "idle")
		# 会飞的悬在空中时：悬停扇翅(hover_<模型>)，落地了才是站着的待机
		if bu.has_flag("flying") and lev_target > 0.05 and ap.has_animation("hover_" + def.model):
			ni = "hover_" + def.model
		# 步枪连射间隙一直端着枪(有目标在射程内、弹匣里还有子弹)，不回待机体态
		var hold: String = str(bu.wclass().get("hold_anim", ""))
		if hold != "" and ap.has_animation(hold) and _engaged():
			ni = hold
		if nest_on:
			ni = _nest_anim("aim", ni)
		if ap.current_animation != ni:
			ap.play(ni, 0.15)
			_loop_at = _clock
		ap.speed_scale = time_scale


func _engaged() -> bool:
	var t: BUnit = bu.target
	if t == null or not t.alive or bu.phase == "reload":
		return false
	return bu.pos.distance_to(t.pos) <= bu.get_stats().range_meters() * 1.2 + t.radius


# ---------------------------------------------------------------- 狙击窝(屏息节点)
## 武器大类参数里的 nest(单位数据 wclass_overrides.<大类>.nest)：{aim, fire, reload, in, shift, turn, crate: [x, z, top](模型体素)}。
## 停下来作战(有目标在射程里 / 正在瞄准 / 换弹)就单膝跪地，身前落下一只黑箱子(NestCrate，摆在世界里)，枪架在箱子上；
## 瞄准 / 开枪 / 换弹 / 等待都换成跪姿版本，一直维持；转身在 turn 度以内不起身(箱子不动、枪在箱子上转)，
## 超过了就半起身挪一下、换个方向重新架(新箱子)；跑起来才起身(箱子留在原地、沉进地里)
func _nest_cfg() -> Dictionary:
	if bu == null or not bu.alive or dying:
		return {}
	return bu.wclass().get("nest", {}) as Dictionary


func _nest_anim(kind: String, fallback: String) -> String:
	var nm: String = str(_nest_cfg().get(kind, ""))
	return nm if nm != "" and ap.has_animation(nm) else fallback


func _nest_fighting() -> bool:
	return _engaged() or bu.phase == "draw" or bu.phase == "reload" or bu.phase == "windup"


## 开枪 / 瞄准 / 装弹的事件来了：人停着就直接进窝(不放跪下的动作，由那一下的交叉淡化带过去)；返回这次是不是刚进窝
func _nest_try_enter() -> bool:
	if nest_on:
		return false
	var cfg: Dictionary = _nest_cfg()
	if cfg.is_empty() or bu.vel.length() > 0.15:
		return false
	_nest_enter(cfg, false)
	return true


func _nest_enter(cfg: Dictionary, play_in: bool) -> void:
	nest_on = true
	_nest_idle = 0.0
	nest_yaw = rotation.y
	_nest_place(cfg)
	if play_in:
		play_once(str(cfg.get("in", "")))


func _nest_place(cfg: Dictionary) -> void:
	if nest_crate != null and is_instance_valid(nest_crate):
		nest_crate.leave(time_scale)
	var c: Array = cfg.get("crate", [-10.0, 33.0, 35.5])
	var k: float = model.scale.x * 0.0125
	var off := Vector3(float(c[0]), 0.0, float(c[1])) * k
	var basis_y := Basis(Vector3.UP, nest_yaw)
	nest_crate = NestCrate.create(self, Transform3D(basis_y, global_position + basis_y * off), float(c[2]) * k, model.scale.x)
	nest_crate.drop(time_scale)


func _nest_leave() -> void:
	if not nest_on:
		return
	nest_on = false
	_nest_left_at = _clock
	if nest_crate != null and is_instance_valid(nest_crate):
		nest_crate.leave(time_scale)
	nest_crate = null


func _nest_update() -> void:
	var dt: float = maxf(0.0, _clock - _nest_clock)
	_nest_clock = _clock
	var cfg: Dictionary = _nest_cfg()
	if cfg.is_empty():
		_nest_leave()
		return
	var spd: float = bu.vel.length()
	if spd > 0.35 or _state == "victory":
		_nest_leave()
		return
	var busy: bool = _state == "attack" and _clock < _busy_until
	if not nest_on:
		if spd < 0.15 and _nest_fighting():
			_nest_enter(cfg, not busy)
		return
	_nest_idle = 0.0 if _nest_fighting() else _nest_idle + dt
	if _nest_idle > 1.4:
		_nest_leave()                        # 没东西可打了：起身(站着的待机)
		return
	# 转身超过 turn 度：半起身挪一下、换个方向重新架(新箱子)。瞄准中(跪姿瞄准的循环)也挪：挪完接着瞄；
	# 正在开枪 / 装弹时先不动，打完这一下再挪
	if absf(angle_difference(nest_yaw, rotation.y)) <= deg_to_rad(float(cfg.get("turn", 45.0))):
		return
	var aim: String = _nest_anim("aim", "")
	var sh: String = _nest_anim("shift", "")
	if busy and ap.current_animation != aim:
		return
	nest_yaw = rotation.y
	_nest_place(cfg)
	if sh == "":
		return
	if busy:
		ap.play(sh, 0.1)
		ap.queue(aim)
	else:
		play_once(sh)


func screen_anchor() -> Vector3:
	return global_position + Vector3(0, body_height + 0.5, 0)
