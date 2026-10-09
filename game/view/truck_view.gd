class_name TruckView
extends Node3D
## 工坊卡车：在大地图上沿虚线开往下一个地图节点；在战斗场景里停在卡车位上(布局里的 truck_rect / truck_rot：默认正中央、车头朝 +X；
## 开局改装允许的话备战时能挪 / 转，glide 滑到新摆法)。
## 战斗中它只是一个不可选中的掩体；敌人涌入时货厢门缝的次元光会闪。

signal arrived

var body: MeshInstance3D
var _dust: GPUParticles3D
var _moving: bool = false
var _tw: Tween = null
const TRUCK_LAYER := 1 << 19
var _t: float = 0.0
var _hit: float = 0.0


func _ready() -> void:
	body = MeshInstance3D.new()
	body.mesh = WorldAssets.mesh("truck")
	body.layers = TRUCK_LAYER            # 卡车单独在一层上：车顶的工作灯不照卡车本身(否则车顶一片死白)；镜头照常看得见
	add_child(body)
	_dust = GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(-1, 0.6, 0)
	pm.spread = 35.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.6
	pm.gravity = Vector3(0, -0.4, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	_dust.process_material = pm
	var bx := BoxMesh.new()
	bx.size = Vector3(0.12, 0.12, 0.12)
	_dust.draw_pass_1 = bx
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.95, 0.94, 0.9, 0.8)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_dust.material_override = dm
	_dust.amount = 40
	_dust.lifetime = 0.8
	_dust.position = Vector3(-1.6, 0.2, 0)
	_dust.emitting = false
	add_child(_dust)


## 夜里的大地图上卡车太小不好找：打开车灯(一盏青白色的灯 + 车头方向的一束光)
var _beacon: OmniLight3D = null
var _head: SpotLight3D = null


func set_beacon(on: bool) -> void:
	if on and _beacon == null:
		_beacon = OmniLight3D.new()
		_beacon.light_color = Color("#9ff0ff")
		_beacon.light_energy = 3.0
		_beacon.omni_range = 7.0
		_beacon.position = Vector3(0, 3.0, 0)
		add_child(_beacon)
		_head = SpotLight3D.new()
		_head.light_color = Color("#fff1c8")
		_head.light_energy = 6.0
		_head.spot_range = 14.0
		_head.spot_angle = 28.0
		_head.position = Vector3(1.6, 0.8, 0)
		_head.rotation_degrees = Vector3(-12, -90, 0)
		add_child(_head)
	if _beacon != null:
		_beacon.visible = on
		_head.visible = on


## 夜里的战场：卡车顶上一盏稳定的暖白工作灯 + 车头一束大灯，照亮卡车四周(不闪、不投影)
var _work: OmniLight3D = null
var _work_head: SpotLight3D = null


func set_worklight(on: bool) -> void:
	if on and _work == null:
		_work = OmniLight3D.new()
		_work.light_color = Color("#ffe6c8")
		_work.light_energy = 3.2
		_work.omni_range = 17.0
		_work.omni_attenuation = 0.7
		_work.position = Vector3(-0.6, 4.2, 0)
		_work.light_cull_mask = 0xFFFFF & ~TRUCK_LAYER
		add_child(_work)
		_work_head = SpotLight3D.new()
		_work_head.light_color = Color("#fff1d6")
		_work_head.light_energy = 5.0
		_work_head.spot_range = 16.0
		_work_head.spot_angle = 34.0
		_work_head.spot_attenuation = 0.8
		_work_head.position = Vector3(1.7, 1.0, 0)
		_work_head.rotation_degrees = Vector3(-14, -90, 0)
		_work_head.light_cull_mask = 0xFFFFF & ~TRUCK_LAYER
		add_child(_work_head)
	if _work != null:
		_work.visible = on
		_work_head.visible = on


## 车头朝向 dir(水平方向)；模型车头朝 +X
func face(dir: Vector3) -> void:
	if Vector2(dir.x, dir.z).length() > 0.01:
		rotation.y = atan2(-dir.z, dir.x)


## 停到战场的卡车位上：位置 / 车头朝向按布局里的卡车摆法(没写 = 初始摆法：正中央、车头朝 +X)
func park(stage_origin: Vector3, layout: Dictionary = {}) -> void:
	if _tw != null and _tw.is_valid():
		_tw.kill()
	var tl: TruckLayout = TruckLayout.from_layout(layout)
	var c: Vector2 = tl.truck_center()
	position = stage_origin + Vector3(c.x, 0.0, c.y)
	rotation.y = tl.facing_yaw()


## 备战时挪动 / 旋转了卡车：滑到新摆法(扬一点尘土)
func glide(stage_origin: Vector3, layout: Dictionary) -> void:
	var tl: TruckLayout = TruckLayout.from_layout(layout)
	var c: Vector2 = tl.truck_center()
	var to: Vector3 = stage_origin + Vector3(c.x, 0.0, c.y)
	var yaw: float = tl.facing_yaw()
	if _tw != null and _tw.is_valid():
		_tw.kill()
	if position.distance_to(to) < 0.01 and absf(angle_difference(rotation.y, yaw)) < 0.01:
		rotation.y = yaw
		return
	_dust.emitting = true
	var tw: Tween = create_tween().set_parallel(true)
	_tw = tw
	tw.tween_property(self, "position", to, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "rotation:y", lerp_angle(rotation.y, yaw, 1.0), 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(func() -> void:
		_dust.emitting = false
		rotation.y = yaw)


## 沿 points(世界坐标折线)开过去，时长 dur 秒；结束后停好并发出 arrived
func drive(points: PackedVector3Array, dur: float, end_park: Vector3) -> void:
	_moving = true
	_dust.emitting = true
	var total := 0.0
	for i in range(points.size() - 1):
		total += points[i].distance_to(points[i + 1])
	if _tw != null and _tw.is_valid():
		_tw.kill()
	var tw: Tween = create_tween()
	_tw = tw
	tw.tween_method(func(k: float) -> void: _place_along(points, total, k), 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		_moving = false
		_dust.emitting = false
		position = end_park
		arrived.emit())


func _place_along(points: PackedVector3Array, total: float, k: float) -> void:
	var dist: float = k * total
	for i in range(points.size() - 1):
		var seg: float = points[i].distance_to(points[i + 1])
		if dist <= seg or i == points.size() - 2:
			var f: float = clampf(dist / maxf(seg, 0.001), 0.0, 1.0)
			position = points[i].lerp(points[i + 1], f)
			var d: Vector3 = points[i + 1] - points[i]
			rotation.y = lerp_angle(rotation.y, atan2(-d.z, d.x), 0.2)
			return
		dist -= seg


## 中途停下(黑屏换场景时)：不再发出 arrived
func stop_drive() -> void:
	if _tw != null and _tw.is_valid():
		_tw.kill()
	_tw = null
	_moving = false
	_dust.emitting = false


## 敌人冲进货厢：车身一震
func hit() -> void:
	_hit = 1.0


func _process(dt: float) -> void:
	_t += dt
	if _moving:
		body.position.y = 0.03 * sin(_t * 18.0)
	elif _hit > 0.0:
		_hit = maxf(0.0, _hit - dt * 3.0)
		body.position = Vector3(0.06 * sin(_t * 60.0) * _hit, 0.0, 0.0)
	else:
		body.position = Vector3.ZERO
