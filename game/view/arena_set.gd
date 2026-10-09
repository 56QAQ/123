class_name ArenaSet
extends Node3D
## 事件战场的布景。事件画面(EventStage)和事件战斗的战场(BattlefieldView)用同一套布景、同一组坐标——事件发生的地方就是打仗的地方。
## 坐标 = 战斗坐标(原点 = 战斗地图中心，卡车停在原点；x 向东，z 向南)。障碍物(长椅 / 树 / 喷泉本体…)不在这里，
## 它们是专属战场的战斗地图(Catalog.arenas[..].obstacles)，两边都按格子画(BattlefieldView.obstacle_node)。
##   tram_stop      电车站：铁轨沿 X 横贯(中心线 z = TRACK_Z)，轨道北边是和路面齐平的站台(候车棚 / 站名牌 / 路线图灯箱)，
##                  东头是道口(警报机 + 栏杆)，头顶一根架空线。电车(模型 + 火 + 前灯)是一个可以整体挪动的节点
##   fountain_park  公园喷泉：铺砖的圆形广场(地面着色器)，北侧正中是燃烧的喷泉，周围几盏歪掉的公园路灯
## 模式：
##   battle = false(事件画面)：电车停在站台前，道口栏杆放着、红灯一直闪；depart() 让电车开走
##   battle = true (战斗)：电车等在西边地图外，按逻辑层的时刻表冲过战场(on_hazard + sync_battle)，道口平时抬着、
##                         预警时放下并闪灯，轨道上亮起红色的警示带；喷泉预警时火柱暴涨，喷发时火弧飞向各个落火点
## 只是表现，不影响逻辑。

const TRACK_Z := -7.0                    # 轨道中心线(格子第 2~3 行之间；战场 25 × 20，北沿 z = -10)
const TRAM_Y := 0.1                      # 车轮压在轨面上
const STOP_POS := Vector3(-1.5, 0.0, -9.4)   # 站台中心(12 × 2.4 米，贴着轨道北沿)
const TRAM_AT_STOP_X := 1.0              # 事件画面里电车停的位置(车头停在道口前，车尾在候车棚旁边)
const FOUNTAIN_POS := Vector3(0.0, 0.0, -5.5)
const FOUNTAIN_K := 1.6                  # FireFX.fountain 的缩放(喷泉模型就是按它雕的)
const PLAZA_RADIUS := 13.5

var set_id: String = ""
var battle: bool = false
var layout: Dictionary = {}
var _t: float = 0.0
# ---- 电车站
var tram: Node3D = null
var _spark: OmniLight3D = null
var _lamps: Array = []                   # [[灯面, 灯光, 第几拍亮]]
var _arms: Array[Node3D] = []            # 道口栏杆(绕 Z 轴转：抬起 80° / 放下 0°)
var _arm_k: float = 0.0                  # 0 = 抬起，1 = 放下
var _warn: bool = false                  # 道口在预警(闪灯、放栏杆)
var _strip: MeshInstance3D = null        # 轨道上的红色警示带(战斗)
var _tram_running: bool = false
var _rest_x: float = -17.6
var _arrive: Tween = null
var _coast: bool = false                 # 战斗已经结束、电车还在半路上：自己开出去
# ---- 喷泉
var _surge: GPUParticles3D = null        # 蓄力时暴涨的火柱
var _surge_light: OmniLight3D = null
var _arcs: Array[Dictionary] = []        # 飞行中的火弧 {node, from, to, t0, dur}
var _nozzle: Vector3 = FOUNTAIN_POS + Vector3(0, 3.3, 0)


static func make(p_set: String, p_battle: bool, p_layout: Dictionary = {}) -> ArenaSet:
	var a := ArenaSet.new()
	a.set_id = p_set
	a.battle = p_battle
	a.layout = p_layout
	match p_set:
		"tram_stop":
			a._build_tram_stop()
		"fountain_park":
			a._build_fountain_park()
	return a


static func known(p_set: String) -> bool:
	return p_set == "tram_stop" or p_set == "fountain_park"


func _prop(mesh_name: String, pos: Vector3, yaw_deg: float = 0.0, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = WorldAssets.mesh(mesh_name)
	mi.position = pos
	mi.rotation.y = deg_to_rad(yaw_deg)
	(parent if parent != null else self).add_child(mi)
	return mi


func _hazard_cfg(id: String) -> Dictionary:
	for h: Variant in layout.get("hazards", []):
		if str((h as Dictionary).get("id", "")) == id:
			return h
	return {}


## 战场外围撒装饰的时候，这个位置要不要空出来(轨道、站台、道口的延长线上不能堆废墟)
func blocks_scatter(p: Vector2) -> bool:
	match set_id:
		"tram_stop":
			return absf(p.y - TRACK_Z) < 2.6 or (p.y < TRACK_Z and p.y > -13.5 and absf(p.x) < 24.0)
		"fountain_park":
			return p.distance_to(Vector2(FOUNTAIN_POS.x, FOUNTAIN_POS.z)) < 6.0
	return false


# ================================================================== 电车站
func _build_tram_stop() -> void:
	WorldAssets.ground_red(self, Vector3.ZERO, 420.0, 1.0, true)
	# 轨道：4 米一节，一直铺到雾里
	var tiles: Array = []
	for i in range(-16, 17):
		tiles.append(Transform3D(Basis.IDENTITY, Vector3(float(i) * 4.0, 0.0, TRACK_Z)))
	WorldAssets.add_multimesh(self, {"evt_track": tiles}, false)
	# 架空线 + 架线柱(立在站台背后，横臂伸到轨道正上方)
	var wire := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(132.0, 0.03, 0.03)
	wire.mesh = wm
	var wmat := StandardMaterial3D.new()
	wmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wmat.albedo_color = Color("#0c0b0b")
	wire.material_override = wmat
	wire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wire.position = Vector3(0, 3.97, TRACK_Z)
	add_child(wire)
	for px: float in [-36.0, -27.0, -18.0, -9.2, 5.6, 14.4, 23.0, 32.0]:
		_prop("evt_wire_pole", Vector3(px, 0, TRACK_Z - 3.85))
	# 站台 + 路线图灯箱的一点冷光
	_prop("evt_tram_stop", STOP_POS)
	var map_lt := OmniLight3D.new()
	map_lt.light_color = Color("#cfe4ff")
	map_lt.light_energy = 0.8
	map_lt.omni_range = 2.6
	map_lt.shadow_enabled = false
	map_lt.position = STOP_POS + Vector3(-5.6, 1.75, -0.6)
	add_child(map_lt)
	# 道口(东头的横街)：轨道两侧各一座警报机，栏杆横在街上
	_crossing(Vector3(5.9, 0, TRACK_Z + 1.3), 0.0)
	_crossing(Vector3(9.1, 0, TRACK_Z - 1.3), 180.0)
	_arm_k = 0.0 if battle else 1.0
	_apply_arms()
	# 电车
	var hz: Dictionary = _hazard_cfg("tram")
	_rest_x = float(hz.get("rest_x", -17.6))
	tram = Node3D.new()
	tram.position = Vector3(_rest_x if battle else TRAM_AT_STOP_X, TRAM_Y, TRACK_Z)
	add_child(tram)
	_prop("burn_tram", Vector3.ZERO, 0.0, tram)
	tram.add_child(FireFX.tram(true))
	var head := SpotLight3D.new()
	head.light_color = Color("#ffe6b0")
	head.light_energy = 8.0
	head.spot_range = 16.0
	head.spot_angle = 30.0
	head.shadow_enabled = false
	head.position = Vector3(5.0, 1.0, 0)
	head.rotation_degrees = Vector3(-8, -90, 0)
	tram.add_child(head)
	_spark = OmniLight3D.new()
	_spark.light_color = Color("#a8dcff")
	_spark.light_energy = 0.0
	_spark.omni_range = 5.0
	_spark.shadow_enabled = false
	_spark.position = Vector3(-1.4, 3.85, 0)
	tram.add_child(_spark)
	if battle:
		# 轨道上的警示带：电车要来的时候一闪一闪(平时不显示)
		_strip = MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(GC.MAP_W * GC.CELL + 8.0, float(hz.get("half_width", 1.1)) * 2.0)
		q.orientation = PlaneMesh.FACE_Y
		_strip.mesh = q
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.albedo_color = Color(1.0, 0.16, 0.08, 0.0)
		_strip.material_override = sm
		_strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_strip.position = Vector3(0, 0.13, float(hz.get("z", TRACK_Z)))
		_strip.visible = false
		add_child(_strip)


## 一座道口警报机：立柱模型 + 两盏红灯(亮的灯面正反两面都看得见 + 一点红光) + 一根能抬能放的栏杆
func _crossing(pos: Vector3, yaw_deg: float) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = deg_to_rad(yaw_deg)
	add_child(n)
	_prop("evt_crossing", Vector3.ZERO, 0.0, n)
	var arm := Node3D.new()
	arm.position = Vector3(0, 1.1, -0.45)
	n.add_child(arm)
	_prop("evt_crossing_arm", Vector3.ZERO, 0.0, arm)
	_arms.append(arm)
	for k in range(2):
		var lens := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.3, 0.3, 0.27)
		lens.mesh = bm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.9, 0.1, 0.05)
		lens.material_override = m
		lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lens.position = Vector3(-0.425 if k == 0 else 0.425, 2.725, 0.025)
		lens.visible = false
		n.add_child(lens)
		var lt := OmniLight3D.new()
		lt.light_color = Color("#ff2a18")
		lt.light_energy = 1.8
		lt.omni_range = 3.6
		lt.shadow_enabled = false
		lt.position = lens.position + Vector3(0, 0, 0.4)
		lt.visible = false
		n.add_child(lt)
		_lamps.append([lens, lt, k])


func _apply_arms() -> void:
	for a: Node3D in _arms:
		a.rotation.z = deg_to_rad(lerpf(80.0, 0.0, _arm_k))


## 事件画面：电车关门开走——先停半拍，再慢慢加速驶出画面(火是世界坐标的粒子，会在车后拖成一条尾巴)
func depart() -> void:
	if tram == null or _tram_running:
		return
	_tram_running = true
	var tw: Tween = create_tween()
	tw.tween_interval(0.7)
	tw.tween_property(tram, "position:x", 70.0, 9.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(tram.hide)


func _tick_tram_stop(dt: float) -> void:
	var lit: bool = _warn or not battle
	var beat: int = int(_t / 0.5) % 2
	for e: Array in _lamps:
		var on: bool = lit and int(e[2]) == beat
		(e[0] as Node3D).visible = on
		(e[1] as Node3D).visible = on
	_arm_k = move_toward(_arm_k, 1.0 if lit else 0.0, dt * 1.1)
	_apply_arms()
	if _strip != null:
		_strip.visible = _warn
		if _warn:
			var sm: StandardMaterial3D = _strip.material_override
			sm.albedo_color = Color(1.0, 0.16, 0.08, 0.16 + 0.14 * sin(_t * TAU * 2.0))
	if _coast and tram != null:
		tram.position.x += float(_hazard_cfg("tram").get("speed", 11.0)) * dt
		if tram.position.x > GC.map_half().x + 12.0:
			_coast = false
			_warn = false
			_tram_running = false
			_next_tram_arrives()
	# 开动时集电弓擦着架空线打出蓝白色的电火花
	if _spark != null:
		var ph: float = fmod(_t, 1.7)
		_spark.light_energy = 5.0 if _tram_running and (ph < 0.06 or (ph > 0.14 and ph < 0.19) or (ph > 0.9 and ph < 0.95)) else 0.0


# ================================================================== 公园喷泉
func _build_fountain_park() -> void:
	WorldAssets.ground_park(self, Vector2(FOUNTAIN_POS.x, FOUNTAIN_POS.z), PLAZA_RADIUS)
	# 广场边上几盏歪掉的公园路灯(细杆，不挡路)
	for lp: Array in [[Vector3(-5.5, 0, -1.0), 140.0], [Vector3(5.5, 0, -1.0), -100.0], [Vector3(-7.5, 0, 5.0), 60.0], [Vector3(7.5, 0, 5.0), -40.0]]:
		_prop("evt_lamp", lp[0] as Vector3, float(lp[1]))
	# 蓄力时暴涨的火柱(平时不喷)
	_surge = FireFX.jet(8.5, 0.5)
	_surge.position = _nozzle
	_surge.emitting = false
	add_child(_surge)
	_surge_light = OmniLight3D.new()
	_surge_light.light_color = Color("#ffb04a")
	_surge_light.light_energy = 0.0
	_surge_light.omni_range = 14.0
	_surge_light.shadow_enabled = false
	_surge_light.position = _nozzle + Vector3(0, 2.5, 0)
	add_child(_surge_light)


## 余烬地块(落火点)的中心(世界坐标)
func _ember_pos(id: int) -> Vector3:
	var em: Array = layout.get("embers", [])
	if id < 0 or id >= em.size():
		return FOUNTAIN_POS
	var e: Dictionary = em[id]
	var a: Vector2 = GC.cell_to_world(int(e["x"]), int(e["y"]))
	var b: Vector2 = GC.cell_to_world(int(e["x"]) + int(e.get("w", 1)) - 1, int(e["y"]) + int(e.get("h", 1)) - 1)
	return Vector3((a.x + b.x) * 0.5, 0.05, (a.y + b.y) * 0.5)


## 一道火弧：一团火沿抛物线从喷口飞到落火点(世界坐标的粒子拖成一道弧线)，落地炸开
func _launch_arc(to: Vector3, dur: float) -> void:
	var f: FireFX = FireFX.make(0.2, true, false, 1.6)
	f.position = _nozzle
	add_child(f)
	_arcs.append({"node": f, "from": _nozzle, "to": to, "t0": _t, "dur": maxf(0.2, dur)})


func _tick_fountain(dt: float) -> void:
	if _surge_light != null:
		_surge_light.light_energy = move_toward(_surge_light.light_energy, 4.5 if _warn else 0.0, dt * 6.0)
	var keep: Array[Dictionary] = []
	for a: Dictionary in _arcs:
		var k: float = (_t - float(a["t0"])) / float(a["dur"])
		var n: FireFX = a["node"]
		if k >= 1.0:
			n.set_emitting(false)
			var land := FireFX.make(0.45, false, false)
			land.position = a["to"]
			add_child(land)
			var tw: Tween = create_tween()
			tw.tween_interval(0.5)
			tw.tween_callback(land.set_emitting.bind(false))
			tw.tween_interval(1.5)
			tw.tween_callback(land.queue_free)
			tw.tween_callback(n.queue_free)
			continue
		var p: Vector3 = (a["from"] as Vector3).lerp(a["to"], k)
		p.y += 3.2 * 4.0 * k * (1.0 - k)
		n.position = p
		keep.append(a)
	_arcs = keep


# ================================================================== 战斗：跟着逻辑层走
## Battle 的表现事件 hazard(ev = warn / go / end)
func on_hazard(e: Dictionary) -> void:
	var ev: String = str(e.get("ev", ""))
	match str(e.get("id", "")):
		"tram":
			match ev:
				"warn":
					_warn = true
				"go":
					_tram_running = true
					if _arrive != null and _arrive.is_valid():
						_arrive.kill()
					if tram != null:
						tram.visible = true
						tram.position.x = _rest_x
				"end":
					_warn = false
					_tram_running = false
					_next_tram_arrives()
		"fountain":
			match ev:
				"warn":
					_warn = true
					if _surge != null:
						_surge.emitting = true
				"go":
					for eid: Variant in e.get("embers", []):
						_launch_arc(_ember_pos(int(eid)), float(e.get("flight", 1.2)))
				"end":
					_warn = false
					if _surge != null:
						_surge.emitting = false


## 下一班车：从西边的雾里开过来，在地图外停下等发车
func _next_tram_arrives() -> void:
	if tram == null:
		return
	tram.position.x = _rest_x - 40.0
	_arrive = create_tween()
	_arrive.tween_interval(1.0)
	_arrive.tween_property(tram, "position:x", _rest_x, 3.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## 每帧：电车的位置跟逻辑层(Battle.hazards 的 x，逻辑步之间插值)。战斗打完时电车还在半路上 = 逻辑停了，
## 让它自己照原速开出战场(_tick_tram_stop)，别僵在轨道中间
func sync_battle(b: Battle, alpha: float) -> void:
	if b == null:
		return
	if b.state == "ended":
		_coast = _tram_running
		if not _tram_running:
			_warn = false                    # 预警到一半战斗结束了：道口放行、喷泉收住
			if _surge != null:
				_surge.emitting = false
		return
	for hz: Dictionary in b.hazards:
		if tram != null and str(hz["id"]) == "tram" and str(hz["phase"]) == "run":
			tram.position.x = lerpf(float(hz["prev_x"]), float(hz["x"]), alpha)


func _process(dt: float) -> void:
	_t += dt
	match set_id:
		"tram_stop":
			_tick_tram_stop(dt)
		"fountain_park":
			_tick_fountain(dt)
