class_name GameWorld
extends Node3D
## 3D 世界：光照/雾(白之章：明亮的灰白色调，远处融进天空) + 两个分开的场景 + 工坊卡车 + 相机。
##  · overworld(OverworldView)：章节大地图(战斗外)，俯视角，虚线连接的地图节点
##  · battle_root：战斗场景(战斗内)——BattlefieldView(当前节点的遗迹与障碍物) + stage(BattleStage)。
##    备战/战斗的一切(棋子、战斗表现、射程环、晶球)都挂在 stage 下面，用战斗坐标(原点 = 战斗地图中心 = 卡车)。
## 同一时间只显示一个场景；卡车在两个场景之间共用。

const Stage = preload("res://scripts/stage.gd")

var overworld: OverworldView
var battle_root: Node3D
var battlefield: BattlefieldView
var stage: BattleStage
var truck: TruckView
var rig: CamRig
var battle_view: BattleView
var units_layer: Node3D            # 备战期的棋子(战斗坐标)
var range_ring: RangeRing          # 悬停/拖动棋子时的攻击范围
var range_ghost: RangeRing         # 预览：换武器后的新攻击范围(虚线)
var target_line: MeshInstance3D    # 战斗中悬停棋子：指向它当前目标的连线
var env: Environment
var sun: DirectionalLight3D
var fill: DirectionalLight3D
var theme_name: String = ""
var weather_kind: String = ""      # 变天(导向节点)：rain / sunny / fog；"" = 章节本来的光照
var _weather_base: Dictionary = {}  # 换天气之前的光照(恢复用)
var _rain: GPUParticles3D = null
var _weather_tw: Tween = null


func _ready() -> void:
	var st: Dictionary = Stage.build(self, Color("#e8ebf0"))
	var old_cam: Camera3D = st["camera"]
	old_cam.queue_free()
	var old_ground: Node = get_node_or_null("Ground")
	if old_ground != null:
		old_ground.queue_free()
	env = st["env"]
	sun = st["sun"]
	sun.light_energy = 1.05
	sun.rotation_degrees = Vector3(-52, 32, 0)
	sun.directional_shadow_max_distance = 45.0
	sun.shadow_blur = 1.4
	env.ambient_light_color = Color("#eeeae4")
	env.ambient_light_energy = 0.55
	env.tonemap_exposure = 0.9
	env.ssao_radius = 0.35
	env.ssao_intensity = 1.1
	env.glow_enabled = false           # 泛光会在白发/白甲周围形成大片光晕，关闭；特效自身足够亮
	env.adjustment_saturation = 1.06
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color("#e8ebf0")
	env.fog_density = 1.0
	env.fog_sky_affect = 0.0
	fill = get_node_or_null("Fill") as DirectionalLight3D
	set_theme("white")
	overworld = OverworldView.new()
	overworld.name = "Overworld"
	add_child(overworld)
	battle_root = Node3D.new()
	battle_root.name = "BattleScene"
	add_child(battle_root)
	battlefield = BattlefieldView.new()
	battlefield.name = "Battlefield"
	battle_root.add_child(battlefield)
	truck = TruckView.new()
	truck.name = "Truck"
	add_child(truck)
	stage = BattleStage.new()
	stage.name = "Stage"
	battle_root.add_child(stage)
	units_layer = Node3D.new()
	units_layer.name = "PrepUnits"
	stage.add_child(units_layer)
	range_ring = RangeRing.new()
	stage.add_child(range_ring)
	range_ghost = RangeRing.new()
	stage.add_child(range_ghost)
	target_line = MeshInstance3D.new()
	target_line.mesh = ImmediateMesh.new()
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lm.vertex_color_use_as_albedo = true
	lm.no_depth_test = true
	target_line.material_override = lm
	target_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stage.add_child(target_line)
	battle_view = BattleView.new()
	battle_view.name = "BattleView"
	stage.add_child(battle_view)
	rig = CamRig.new()
	rig.name = "CamRig"
	add_child(rig)
	rig.set_preset("prep", true)
	battle_view.shake.connect(rig.shake)
	battle_view.weather.connect(set_weather)
	battle_view.terrain_break.connect(func(kind: String, id: int) -> void: battlefield.break_terrain(kind, id, battle_view.fx))
	overworld.visible = false


## 变天(导向节点)：rain = 战场上下起雨(雨丝 + 光线暗一点、冷一点)；sunny = 晴天(阳光更亮、更暖，环境光提一档)；
## fog = 起雾(贴地飘的灰白雾团 + 深度雾拉近、发灰发白)；"" = 恢复章节本来的光照
func set_weather(kind: String) -> void:
	if kind == weather_kind:
		return
	if _weather_tw != null and _weather_tw.is_valid():
		_weather_tw.kill()
	if weather_kind != "" and not _weather_base.is_empty():
		sun.light_energy = float(_weather_base["sun_e"])
		sun.light_color = _weather_base["sun_c"]
		env.ambient_light_energy = float(_weather_base["amb_e"])
		env.ambient_light_color = _weather_base["amb_c"]
		env.adjustment_saturation = float(_weather_base["sat"])
		env.fog_depth_begin = float(_weather_base["fog_b"])
		env.fog_depth_end = float(_weather_base["fog_e"])
		env.fog_light_color = _weather_base["fog_c"]
	if _rain != null:
		_rain.queue_free()
		_rain = null
	weather_kind = kind
	if kind == "":
		_weather_base = {}
		return
	_weather_base = {"sun_e": sun.light_energy, "sun_c": sun.light_color, "amb_e": env.ambient_light_energy, "amb_c": env.ambient_light_color,
		"sat": env.adjustment_saturation, "fog_b": env.fog_depth_begin, "fog_e": env.fog_depth_end, "fog_c": env.fog_light_color}
	_weather_tw = create_tween().set_parallel(true)
	if kind == "rain":
		_rain = _make_rain()
		battle_root.add_child(_rain)
		_weather_tw.tween_property(sun, "light_energy", sun.light_energy * 0.65, 1.2)
		_weather_tw.tween_property(env, "ambient_light_energy", env.ambient_light_energy * 0.85, 1.2)
		_weather_tw.tween_property(env, "ambient_light_color", (env.ambient_light_color as Color).lerp(Color("#4a5a78"), 0.35), 1.2)
		_weather_tw.tween_property(env, "adjustment_saturation", env.adjustment_saturation * 0.88, 1.2)
	elif kind == "fog":
		_rain = _make_mist()
		battle_root.add_child(_rain)
		_weather_tw.tween_property(sun, "light_energy", sun.light_energy * 0.75, 1.5)
		_weather_tw.tween_property(env, "ambient_light_color", (env.ambient_light_color as Color).lerp(Color("#d4dae2"), 0.4), 1.5)
		_weather_tw.tween_property(env, "adjustment_saturation", env.adjustment_saturation * 0.8, 1.5)
		_weather_tw.tween_property(env, "fog_depth_begin", 22.0, 1.5)
		_weather_tw.tween_property(env, "fog_depth_end", 95.0, 1.5)
		_weather_tw.tween_property(env, "fog_light_color", Color("#c9d1dc"), 1.5)
	elif kind == "sunny":
		_weather_tw.tween_property(sun, "light_energy", maxf(sun.light_energy * 1.8, 0.95), 1.2)
		_weather_tw.tween_property(sun, "light_color", Color("#fff1d2"), 1.2)
		_weather_tw.tween_property(env, "ambient_light_energy", env.ambient_light_energy * 1.3, 1.2)
		_weather_tw.tween_property(env, "ambient_light_color", (env.ambient_light_color as Color).lerp(Color("#f4ead8"), 0.45), 1.2)


## 雨丝：覆盖整片战场(25 × 20 米)的细长亮线从 7 米高落下
func _make_rain() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 1400
	p.lifetime = 0.75
	p.preprocess = 0.8
	p.visibility_aabb = AABB(Vector3(-16, -1, -13), Vector3(32, 12, 26))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(15.0, 0.3, 12.0)
	pm.direction = Vector3(0.12, -1.0, 0.05)
	pm.spread = 2.0
	pm.initial_velocity_min = 13.0
	pm.initial_velocity_max = 16.0
	pm.gravity = Vector3(0, -6, 0)
	p.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.012, 0.42)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.78, 0.86, 1.0, 0.32)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	qm.material = mat
	p.draw_pass_1 = qm
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.position = Vector3(0, 7.0, 0)
	return p


## 起雾：贴着地面慢慢飘的一大团团灰白雾(普通混合的柔光片，很淡；整片战场 25 × 20 米)
func _make_mist() -> GPUParticles3D:
	var ramp := SoftFX.ramp([Color(0.86, 0.89, 0.93, 0.0), Color(0.86, 0.89, 0.93, 0.16), Color(0.86, 0.89, 0.93, 0.16), Color(0.86, 0.89, 0.93, 0.0)],
		[0.0, 0.25, 0.7, 1.0])
	var p: GPUParticles3D = SoftFX.particles(90, 10.0, ramp, 4.2, false)
	var pm: ParticleProcessMaterial = p.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(14.0, 0.35, 11.5)
	pm.direction = Vector3(1.0, 0.0, 0.25)
	pm.spread = 25.0
	pm.initial_velocity_min = 0.15
	pm.initial_velocity_max = 0.45
	pm.gravity = Vector3.ZERO
	p.preprocess = 8.0
	p.visibility_aabb = AABB(Vector3(-18, -2, -15), Vector3(36, 8, 30))
	p.position = Vector3(0, 0.7, 0)
	return p


## 深度雾：近处清晰，远处融进天空(看不到边际)。大地图镜头更远，把雾推远
func set_fog_far(map_view: bool) -> void:
	if theme_name == "purple":
		# 紫之章：空岛在云海上，大地图的雾很远(要看见北边的九条冰尾)；战场和红之章一样只吞掉远处
		env.fog_depth_begin = 520.0 if map_view else 70.0
		env.fog_depth_end = 1500.0 if map_view else 220.0
		env.fog_depth_curve = 1.2
		env.glow_enabled = false
		sun.shadow_blur = 0.7
		env.ambient_light_energy = 0.42 if map_view else 0.55
		sun.light_energy = 0.5 if map_view else 0.62
		return
	if theme_name == "blue":
		# 蓝之章：穹顶很大，大地图的雾推得很远(要看见整座穹顶)；战场同红之章
		env.fog_depth_begin = 500.0 if map_view else 70.0
		env.fog_depth_end = 1500.0 if map_view else 220.0
		env.fog_depth_curve = 1.2
		env.glow_enabled = false
		sun.shadow_blur = 0.7
		env.ambient_light_energy = 0.5 if map_view else 0.6
		sun.light_energy = 0.8 if map_view else 0.95
		return
	if theme_name == "red":
		# 战场：雾从 60 m 才开始(备战镜头约 35 m，整片战场要清楚，雾只吞掉远处的城市)
		env.fog_depth_begin = 330.0 if map_view else 60.0
		env.fog_depth_end = 950.0 if map_view else 190.0
		env.fog_depth_curve = 1.2
		# 大地图更暗(只看得见火光)；战场亮一点，棋子和废墟要看得清。
		# 不开泛光：大地图上满城灯火一起泛光会蒙上一层灰紫色的雾；战场上会把棋子身上随火光明灭的高光放大成一团团闪烁的白光
		env.glow_enabled = false
		sun.shadow_blur = 0.7
		env.ambient_light_energy = 0.2 if map_view else 0.5
		sun.light_energy = 0.2 if map_view else 0.55
		return
	env.fog_depth_begin = 95.0 if map_view else 38.0
	env.fog_depth_end = 260.0 if map_view else 160.0
	env.fog_depth_curve = 1.4


## 章节的光照主题：white = 第零章的明亮白天；red = 第一章·红之章的黑夜(冷色月光 + 暖色火光 + 暗红的雾，开泛光让余火发亮)
func set_theme(name: String) -> void:
	if name == theme_name:
		return
	theme_name = name
	if name == "purple":
		# 第二章-A·紫之章：紫色的夜空 + 冷白的月光 + 紫色的环境光；雾是深紫
		env.background_color = Color("#140b26")
		env.ambient_light_color = Color("#4a3a78")
		env.ambient_light_energy = 0.5
		env.tonemap_exposure = 1.0
		env.glow_enabled = false
		env.adjustment_saturation = 1.08
		env.fog_light_color = Color("#1c1036")
		sun.light_color = Color("#d8d4ff")
		sun.light_energy = 0.6
		sun.rotation_degrees = Vector3(-55, -28, 0)
		if fill != null:
			fill.light_color = Color("#9a6cff")
			fill.light_energy = 0.22
	elif name == "blue":
		# 第一章-B·蓝之章：穹顶把天光染成蓝色——偏蓝的直射光从高处打下来，环境光和雾都是蓝的
		env.background_color = Color("#0a1f46")
		env.ambient_light_color = Color("#5d86c8")
		env.ambient_light_energy = 0.6
		env.tonemap_exposure = 1.0
		env.glow_enabled = false
		env.adjustment_saturation = 1.05
		env.fog_light_color = Color("#1b3b78")
		sun.light_color = Color("#cfe6ff")
		sun.light_energy = 0.95
		sun.rotation_degrees = Vector3(-66, 20, 0)
		if fill != null:
			fill.light_color = Color("#3f9dff")
			fill.light_energy = 0.3
	elif name == "red":
		env.background_color = Color("#0b0605")
		env.ambient_light_color = Color("#47291f")
		env.ambient_light_energy = 0.42
		env.tonemap_exposure = 1.0
		env.glow_enabled = true
		env.glow_intensity = 0.55
		env.glow_strength = 0.9
		env.glow_bloom = 0.0
		env.glow_hdr_threshold = 1.3
		env.adjustment_saturation = 1.08
		env.fog_light_color = Color("#140705")
		sun.light_color = Color("#b4aec4")
		sun.light_energy = 0.3
		sun.rotation_degrees = Vector3(-58, -35, 0)
		if fill != null:
			fill.light_color = Color("#ff6a3a")
			fill.light_energy = 0.16
	else:
		env.background_color = Color("#e8ebf0")
		env.ambient_light_color = Color("#eeeae4")
		env.ambient_light_energy = 0.55
		env.tonemap_exposure = 0.9
		env.glow_enabled = false           # 泛光会在白发/白甲周围形成大片光晕，关闭；特效自身足够亮
		env.adjustment_saturation = 1.06
		env.fog_light_color = Color("#e8ebf0")
		sun.light_color = Color("#fff4e6")
		sun.light_energy = 1.05
		sun.rotation_degrees = Vector3(-52, 32, 0)
		if fill != null:
			fill.light_color = Color("#dfe9ff")
			fill.light_energy = 0.28
	set_fog_far(overworld != null and overworld.visible)


## 新的一局 / 进入新章节：搭建章节大地图，换章节的光照主题
func build_chapter(run: Run) -> void:
	set_theme(str(run.chapter.get("theme", "white")))
	overworld.build(run)


## 切到大地图：卡车停在当前位置(起点或上一个打完的节点)，车头朝向下一站
func show_map(run: Run) -> void:
	overworld.visible = true
	battle_root.visible = false
	set_fog_far(true)
	set_theme(str(run.chapter.get("theme", "white")))
	if overworld.city != null:
		# 方格网章节：卡车停在所在的路口，车头朝着首领方向；比例和城市一致(不缩小)
		overworld.city.refresh(run)
		truck.position = overworld.city.node_pos.get(run.pos, Vector3.ZERO)
		truck.scale = Vector3.ONE
		truck.face(overworld.city.node_pos.get(str(run.gmap["boss"]), Vector3.RIGHT * 10.0) - truck.position)
		truck.set_beacon(true)
		truck.set_worklight(false)
		# 高空俯瞰时月光阴影的级联会随镜头移动抖动，SSAO 在远处也会闪：大地图上都关掉(夜里本来就看不出月影)
		sun.shadow_enabled = false
		env.ssao_enabled = false
		rig.max_dist = 720.0
		rig.pan_range = Vector2(240.0, 200.0)
	else:
		truck.set_beacon(false)
		sun.shadow_enabled = true
		env.ssao_enabled = true
		rig.max_dist = 140.0
		rig.pan_range = Vector2(30.0, 60.0)
		overworld.refresh(run.node_index)
		var here: Vector3 = overworld.truck_spot(run.node_index)
		truck.position = here
		truck.scale = Vector3.ONE * 0.9
		if run.node_index < overworld.node_pos.size():
			truck.face(overworld.node_pos[run.node_index] - here)
	var c: Vector3 = overworld.route_center()
	rig.focus = c
	sun.directional_shadow_max_distance = 140.0


## 地图视角：俯瞰整条路线(从起点到终点祭坛，自下而上)；方格网章节俯瞰整片城市
func map_view(instant: bool) -> void:
	if overworld.city is DomeOverworld:
		# 穹顶城：镜头拉远一点，整座穹顶连同北边的信标都在画面里
		var dd: float = overworld.route_span() * 1.3 + 180.0
		rig.set_view(overworld.route_center() + Vector3(0, 0, -34.0), 0.0, 44.0, dd, instant)
		env.fog_depth_begin = dd + 200.0
		env.fog_depth_end = dd + 1400.0
		return
	if overworld.city is IslandOverworld:
		# 空岛：镜头压低一点、对准岛中心偏北，让北边的九条冰尾露在画面上方
		var di: float = overworld.route_span() * 1.32 + 90.0
		rig.set_view(overworld.route_center() + Vector3(0, 0, -14.0), 0.0, 49.0, di, instant)
		env.fog_depth_begin = di + 120.0
		env.fog_depth_end = di + 1100.0
		return
	if overworld.city != null:
		# 高空俯瞰整座城市：镜头对准节点群的中心稍偏南(留出上方行动力面板与下方零件栏)
		var d: float = overworld.route_span() * 1.3 + 70.0
		rig.set_view(overworld.route_center() + Vector3(0, 0, 10.0), 0.0, 58.0, d, instant)
		env.fog_depth_begin = d + 40.0
		env.fog_depth_end = d + 750.0
		return
	rig.set_view(overworld.route_center(), 0.0, 64.0, overworld.route_span() * 1.75 + 10.0, instant)


## 切到战斗场景：搭建某个地图节点的遗迹(障碍物 = 该节点的战斗地图)，卡车停在正中央
func show_battlefield(layout: Dictionary, seed_value: int) -> void:
	set_theme(str(layout.get("theme", "white")))
	battlefield.build(layout, seed_value)
	overworld.visible = false
	battle_root.visible = true
	set_fog_far(false)
	sun.shadow_enabled = true
	env.ssao_enabled = true
	rig.max_dist = 140.0
	rig.pan_range = Vector2(30.0, 60.0)
	truck.scale = Vector3.ONE
	truck.set_beacon(false)
	truck.set_worklight(theme_name == "red")      # 紫之章的雪地有月光，不开工作灯(否则卡车周围一片死白)
	truck.park(Vector3.ZERO, layout)
	stage.apply_layout(layout)
	# 专属战场：镜头往北挪一点，把场景的主角(北侧的喷泉 / 铁轨和站台)放进画面
	rig.focus = Vector3(0, 0, float(layout.get("cam_z", 0.0)))
	sun.directional_shadow_max_distance = 45.0


## 备战时卡车挪了 / 转了(开局改装)：卡车滑到新摆法，部署区着色跟着换
func apply_truck(layout: Dictionary) -> void:
	truck.glide(Vector3.ZERO, layout)
	stage.apply_layout(layout)


## 从 a 到 b 画一条贴地的粗线(箭头朝 b，战斗坐标)；visible_now=false 时清空
func show_target_line(a: Vector3, b: Vector3, c: Color, visible_now: bool) -> void:
	var im: ImmediateMesh = target_line.mesh as ImmediateMesh
	im.clear_surfaces()
	if not visible_now or a.distance_to(b) < 0.3:
		return
	var y := Vector3(0, 0.12, 0)
	var d: Vector3 = (b - a)
	d.y = 0.0
	var dir: Vector3 = d.normalized()
	var side := Vector3(-dir.z, 0, dir.x) * 0.045
	var end: Vector3 = b - dir * 0.45
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var ca := Color(c.r, c.g, c.b, 0.15)
	for v: Array in [[a + side, ca], [end + side, c], [end - side, c], [a + side, ca], [end - side, c], [a - side, ca],
			[end + side * 4.0, c], [b - dir * 0.2, c], [end - side * 4.0, c]]:
		im.surface_set_color(v[1])
		im.surface_add_vertex((v[0] as Vector3) + y)
	im.surface_end()
