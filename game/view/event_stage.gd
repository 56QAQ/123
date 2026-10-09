class_name EventStage
extends SubViewport
## 事件场景：每个事件一幕实际建模的场景(体素模型 + 粒子火 + 灯光)，渲染在事件界面左边的大画面里。
## 场景按事件数据的 scene 搭；镜头绕着场景中心慢慢地左右摆。只是表现，不影响逻辑。
## 有战斗的事件：scene = 它的专属战场的布景(ArenaSet)——画面里的东西(布景 + 战斗地图上的障碍物 / 落火点)和战场用同一套模型、
## 同一组坐标(战斗坐标：卡车会停在原点)，事件发生的地方就是打仗的地方；这里只多摆一圈远处的背景，换一个镜头。

var scene_id: String = ""
var cam: Camera3D
var root3d: Node3D
var focus := Vector3(0, 1.2, 0)
var cam_dist: float = 9.5
var cam_height: float = 4.6
var cam_yaw: float = 0.0
var arena: ArenaSet = null              # 专属战场的布景(事件画面模式)
var _t: float = 0.0
var _outcome: String = ""
var _props: Array = []                  # 事件数据里的道具(街景套件 roadside 用)
var _theme: String = "red"              # 章节主题：地面 / 天色 / 背景按它选


## props = 事件数据的 props(街景套件里摆的东西)，cam_cfg = 镜头参数(focus / dist / height / yaw)，theme = 章节主题
func setup(p_scene: String, px: Vector2i = Vector2i(1000, 760), cat: Catalog = null, props: Array = [], cam_cfg: Dictionary = {}, theme: String = "red") -> void:
	scene_id = p_scene
	_props = props
	_theme = theme
	size = px
	own_world_3d = true
	msaa_3d = Viewport.MSAA_4X
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root3d = Node3D.new()
	add_child(root3d)
	cam = Camera3D.new()
	cam.fov = 38.0
	cam.far = 200.0
	add_child(cam)
	match scene_id:
		"fountain_park":
			_build_fountain_park(cat)
		"tram_stop":
			_build_tram_stop(cat)
		"roadside":
			_build_roadside()
		_:
			_build_quiet()
	if cam_cfg.has("focus"):
		var f: Array = cam_cfg["focus"]
		focus = Vector3(float(f[0]), float(f[1]), float(f[2]))
	cam_dist = float(cam_cfg.get("dist", cam_dist))
	cam_height = float(cam_cfg.get("height", cam_height))
	if cam_cfg.has("yaw"):
		cam_yaw = deg_to_rad(float(cam_cfg["yaw"]))
	_place_cam()


func _process(dt: float) -> void:
	_t += dt
	_place_cam()


## 选项的结果出来了(EventScreen 在显示结果时调用，可能调多次)：场景可以跟着变(电车开走)
func on_outcome(outcome: String) -> void:
	if outcome == "" or outcome == _outcome:
		return
	_outcome = outcome
	if scene_id == "tram_stop" and arena != null and (outcome == "follow" or outcome == "watch"):
		arena.depart()


## 镜头：从斜上方看，绕中心 ±16° 慢慢来回摆(周期 26 秒)。cam_yaw = 0 从南边(+Z)看，180° 从北边看
func _place_cam() -> void:
	if cam == null:
		return
	var a: float = cam_yaw + deg_to_rad(16.0) * sin(_t * TAU / 26.0)
	var p: Vector3 = focus + Vector3(sin(a) * cam_dist, cam_height, cos(a) * cam_dist)
	cam.transform = Transform3D(Basis.looking_at(focus - p, Vector3.UP), p)


# ---------------------------------------------------------------- 共用：夜景环境
func _night_env(fog_color: Color, ambient: Color, fog_begin: float = 11.0, fog_end: float = 34.0, bg: Color = Color("#0d0605")) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = fog_color
	env.fog_depth_begin = fog_begin
	env.fog_depth_end = fog_end
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 2.4
	var we := WorldEnvironment.new()
	we.environment = env
	root3d.add_child(we)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-52, 38, 0)
	moon.light_color = Color("#8ea2ff")
	moon.light_energy = 0.32
	moon.shadow_enabled = true
	root3d.add_child(moon)


func _prop(name: String, pos: Vector3, yaw_deg: float = 0.0, k: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = WorldAssets.mesh(name)
	mi.position = pos
	mi.rotation.y = deg_to_rad(yaw_deg)
	mi.scale = Vector3.ONE * k
	root3d.add_child(mi)
	return mi


## 地面：烧黑的柏油(和战场同一种地面)
func _ground() -> void:
	WorldAssets.ground_red(root3d, Vector3.ZERO, 120.0, 1.0, false)


## 专属战场的布景 + 战斗地图上的东西(障碍物、落火点)：和战场画的是同一份数据
func _arena_set(cat: Catalog) -> void:
	var layout: Dictionary = {}
	if cat != null:
		for aid: String in cat.arenas.keys():
			if str((cat.arenas[aid] as Dictionary).get("set", "")) == scene_id:
				layout = Events.arena_layout(cat, aid)
	arena = ArenaSet.make(scene_id, false, layout)
	root3d.add_child(arena)
	for o: Variant in layout.get("obstacles", []):
		root3d.add_child(BattlefieldView.obstacle_node(o as Dictionary, true))
	var ei := 0
	for e: Variant in layout.get("embers", []):
		root3d.add_child(BattlefieldView.ember_node(ei, e as Dictionary)["node"])
		ei += 1


## 一组背景：[[模型, 位置, 朝向(度)], …]
func _backdrop(list: Array) -> void:
	for r: Array in list:
		_prop(str(r[0]), r[1] as Vector3, float(r[2]))


func _fires(list: Array) -> void:
	for fp: Array in list:
		var f: FireFX = FireFX.make(float(fp[1]), true, false, 2.0)
		f.position = fp[0]
		root3d.add_child(f)


# ---------------------------------------------------------------- 燃烧喷泉：公园(= 专属战场 fountain_park)
## 镜头在南边(战斗时卡车停的那一侧)朝北看：正中是三人多高的火柱，近处是长椅、烧秃的树和秋千，喷泉背后一圈烧塌的城市
func _build_fountain_park(cat: Catalog) -> void:
	_night_env(Color("#3a1410"), Color("#5a3836"), 16.0, 48.0)
	_arena_set(cat)
	_backdrop([["evt_tree", Vector3(-6.4, 0, -11.0), 20.0], ["evt_tree", Vector3(6.0, 0, -12.0), -70.0], ["evt_tree", Vector3(-11.0, 0, -4.5), 110.0],
		["evt_tree", Vector3(11.5, 0, -6.0), 200.0], ["evt_bench", Vector3(-5.0, 0, -9.6), 30.0], ["evt_swing", Vector3(1.5, 0, -13.5), 8.0],
		["evt_lamp", Vector3(-3.6, 0, -10.4), 140.0], ["evt_lamp", Vector3(4.2, 0, -10.2), -100.0],
		["ash_corner", Vector3(-13.0, 0, -17.0), 30.0], ["ash_wall", Vector3(-4.0, 0, -21.0), 5.0], ["burn_house", Vector3(7.5, 0, -19.5), -20.0],
		["ash_shopfront", Vector3(15.0, 0, -13.0), -80.0], ["ash_pillar", Vector3(-16.0, 0, -9.0), 0.0], ["ash_heap", Vector3(-17.0, 0, 2.0), 10.0],
		["burn_car", Vector3(16.5, 0, 0.5), 35.0], ["bld_house_a", Vector3(-22.0, 0, -24.0), 0.0], ["bld_shops", Vector3(2.0, 0, -31.0), 0.0],
		["bld_house_b", Vector3(21.0, 0, -22.0), 0.0], ["bld_office_a", Vector3(-9.0, 0, -40.0), 0.0], ["bld_danchi", Vector3(26.0, 0, -36.0), 0.0]])
	_fires([[Vector3(7.5, 0.4, -19.5), 0.8], [Vector3(16.5, 0.5, 0.5), 0.5]])
	root3d.add_child(FireFX.ember_snow(Vector2(34, 34), 170, 12.0))
	focus = Vector3(0, 3.3, -5.0)
	cam_dist = 17.5
	cam_height = 4.4
	cam_yaw = deg_to_rad(14.0)


# ---------------------------------------------------------------- 末班电车：电车站(= 专属战场 tram_stop)
## 镜头在北边(站台背后)朝南看：近处是只剩骨架的候车棚和站台，燃烧的电车停在站台前、车门朝这边开着，窗后一排黑色的人影；
## 右手是道口(栏杆放着、红灯交替地闪)，电车背后是大街南侧一排烧空的店面。选了「跟上去」/「目送」之后电车拖着火开走
func _build_tram_stop(cat: Catalog) -> void:
	_night_env(Color("#3a1410"), Color("#5a3836"), 15.0, 46.0)
	_arena_set(cat)
	# 大街南侧(画面深处)：一排店面朝北(朝镜头)，更远是大地图尺度的楼
	_backdrop([["ash_wall", Vector3(-15.5, 0, 10.6), 180.0], ["ash_shopfront", Vector3(-11.0, 0, 10.4), 180.0], ["burn_shopfront", Vector3(-6.2, 0, 10.8), 180.0],
		["ash_corner", Vector3(-1.6, 0, 11.2), 180.0], ["ash_shopfront", Vector3(3.6, 0, 10.5), 180.0], ["ash_wall", Vector3(8.2, 0, 10.9), 180.0],
		["burn_house", Vector3(13.0, 0, 11.6), 180.0], ["ash_pillar", Vector3(17.0, 0, 10.2), 0.0], ["ash_shopfront", Vector3(-20.5, 0, 10.8), 180.0],
		["bld_shops", Vector3(-9.0, 0, 20.0), 180.0], ["bld_office_a", Vector3(6.0, 0, 27.0), 180.0], ["bld_house_a", Vector3(19.0, 0, 20.0), 180.0],
		["bld_danchi", Vector3(-26.0, 0, 26.0), 180.0], ["bld_house_b", Vector3(-22.0, 0, 16.0), 180.0], ["bld_house_a", Vector3(27.0, 0, 9.0), 90.0],
		["ash_car", Vector3(-9.0, 0, 3.4), 12.0], ["ash_rubble_b", Vector3(6.5, 0, 4.6), 40.0]])
	_fires([[Vector3(-5.6, 0.5, 11.0), 0.6], [Vector3(13.2, 0.4, 11.8), 0.7]])
	root3d.add_child(FireFX.ember_snow(Vector2(36, 30), 170, 11.0))
	focus = Vector3(1.0, 1.8, -7.6)
	cam_dist = 16.5
	cam_height = 3.2
	cam_yaw = deg_to_rad(160.0)


# ---------------------------------------------------------------- 街景套件：路边(第二批事件共用)
## 一段路肩 + 远处的城市剪影(按章节主题：红 = 烧空的街区，紫 = 坚冰和雪)，中间摆事件数据里的主角道具(props)：
##   {kind: model(默认), model, pos, yaw, scale} / {kind: fire, pos, size} / {kind: light, pos, color, energy, range} /
##   {kind: sphere, pos, r, color}(发光的球：晶球) / {kind: embers, size, amount, height}(漫天的余烬)
func _build_roadside() -> void:
	if _theme == "blue":
		_night_env(Color("#1b3b78"), Color("#5d86c8"), 14.0, 46.0, Color("#0a1f46"))
		WorldAssets.ground_tech(root3d, Vector3.ZERO, 120.0)
		_backdrop([["tech_gate", Vector3(-6.5, 0, -9.5), 0.0], ["tech_server", Vector3(1.0, 0, -10.5), 10.0], ["tech_kiosk", Vector3(6.5, 0, -9.0), -20.0],
			["tech_pillar", Vector3(-11.0, 0, -4.0), 0.0], ["tech_pillar", Vector3(11.0, 0, -5.0), 0.0], ["tech_planter", Vector3(-9.0, 0, -1.0), 0.0],
			["tech_barrier", Vector3(12.5, 0, 1.0), 80.0], ["tech_crates", Vector3(-13.0, 0, -11.0), 25.0], ["tech_planter", Vector3(9.5, 0, -2.5), 0.0]])
		root3d.add_child(FireFX.snow(Vector2(24, 24), 90, 9.0))
		var sky := OmniLight3D.new()
		sky.light_color = Color("#8fd0ff")
		sky.light_energy = 1.4
		sky.omni_range = 16.0
		sky.shadow_enabled = false
		sky.position = Vector3(0, 7, 0)
		root3d.add_child(sky)
	elif _theme == "purple":
		_night_env(Color("#1a1030"), Color("#4a4470"), 12.0, 40.0)
		WorldAssets.ground_ice(root3d, Vector3.ZERO, 120.0)
		_backdrop([["ice_wall", Vector3(-7.5, 0, -9.0), 20.0], ["ice_spire", Vector3(6.5, 0, -10.0), -30.0], ["ice_pillar", Vector3(-11.0, 0, -4.0), 0.0],
			["ice_corner", Vector3(10.5, 0, -5.0), 60.0], ["ice_heap", Vector3(-4.0, 0, -13.0), 0.0], ["ice_block", Vector3(12.0, 0, 1.5), 15.0],
			["ice_spire", Vector3(-13.0, 0, -12.0), 0.0], ["ice_wall", Vector3(3.0, 0, -15.0), -10.0]])
		root3d.add_child(FireFX.snow(Vector2(26, 26), 160, 10.0))
	else:
		_night_env(Color("#24120f"), Color("#4a3434"))
		_ground()
		_backdrop([["ash_wall", Vector3(-7.0, 0, -9.0), 0.0], ["ash_shopfront", Vector3(-1.5, 0, -10.0), 0.0], ["burn_shopfront", Vector3(4.5, 0, -10.2), 0.0],
			["ash_corner", Vector3(10.5, 0, -8.5), -20.0], ["ash_pillar", Vector3(-11.0, 0, -5.0), 0.0], ["ash_car", Vector3(11.5, 0, -1.0), 70.0],
			["ash_rubble_a", Vector3(-9.5, 0, -1.5), 0.0], ["burn_house", Vector3(-15.0, 0, -14.0), 25.0], ["bld_shops", Vector3(3.0, 0, -22.0), 0.0],
			["bld_house_a", Vector3(-14.0, 0, -22.0), 0.0], ["bld_office_a", Vector3(16.0, 0, -20.0), 0.0]])
		_fires([[Vector3(4.5, 0.4, -10.2), 0.6]])
		root3d.add_child(FireFX.ember_snow(Vector2(24, 24), 110, 9.0))
	for pr: Variant in _props:
		_place_prop(pr as Dictionary)
	focus = Vector3(0, 1.1, 0)
	cam_dist = 9.0
	cam_height = 3.8
	cam_yaw = deg_to_rad(10.0)


func _place_prop(pr: Dictionary) -> void:
	var p: Array = pr.get("pos", [0, 0, 0])
	var pos := Vector3(float(p[0]), float(p[1]), float(p[2]))
	match str(pr.get("kind", "model")):
		"model":
			_prop(str(pr.get("model", "")), pos, float(pr.get("yaw", 0.0)), float(pr.get("scale", 1.0)))
		"fire":
			var f: FireFX = FireFX.make(float(pr.get("size", 0.5)), true, bool(pr.get("smoke", true)), float(pr.get("energy", 2.2)))
			f.position = pos
			root3d.add_child(f)
		"light":
			var l := OmniLight3D.new()
			l.light_color = Color(str(pr.get("color", "#ffffff")))
			l.light_energy = float(pr.get("energy", 2.0))
			l.omni_range = float(pr.get("range", 6.0))
			l.shadow_enabled = false
			l.position = pos
			root3d.add_child(l)
		"sphere":
			var mi := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = float(pr.get("r", 0.3))
			sm.height = sm.radius * 2.0
			mi.mesh = sm
			var m := StandardMaterial3D.new()
			var col := Color(str(pr.get("color", "#ffffff")))
			m.albedo_color = col
			m.emission_enabled = true
			m.emission = col
			m.emission_energy_multiplier = 1.8
			mi.material_override = m
			mi.position = pos
			root3d.add_child(mi)
			var l2 := OmniLight3D.new()
			l2.light_color = col
			l2.light_energy = 1.4
			l2.omni_range = 3.5
			l2.shadow_enabled = false
			l2.position = pos
			root3d.add_child(l2)
		"embers":
			var ex: float = float(pr.get("size", 24.0))
			root3d.add_child(FireFX.ember_snow(Vector2(ex, ex), int(pr.get("amount", 400)), float(pr.get("height", 9.0))))


# ---------------------------------------------------------------- 兜底：寂静的街道
func _build_quiet() -> void:
	_night_env(Color("#24120f"), Color("#4a3434"))
	_ground()
	for r: Array in [["ash_wall", Vector3(-2.5, 0, -2.5), 0.0], ["ash_shopfront", Vector3(2.5, 0, -2.8), 0.0], ["ash_car", Vector3(0.8, 0, 0.6), 25.0],
		["ash_rubble_a", Vector3(-1.6, 0, 1.4), 0.0], ["ash_pillar", Vector3(-4.2, 0, 0.5), 0.0], ["burn_debris", Vector3(3.6, 0, 1.6), 0.0]]:
		_prop(str(r[0]), r[1] as Vector3, float(r[2]))
	var f: FireFX = FireFX.make(0.45, true, true, 2.2)
	f.position = Vector3(3.6, 0.3, 1.6)
	root3d.add_child(f)
	root3d.add_child(FireFX.ember_snow(Vector2(18, 18), 80, 8.0))
	focus = Vector3(0, 0.9, 0)
	cam_dist = 8.0
	cam_height = 3.6
