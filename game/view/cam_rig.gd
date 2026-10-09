class_name CamRig
extends Node3D
## 环绕相机：拖动旋转、滚轮缩放、右键平移、预设视角、屏幕震动、世界<->屏幕坐标换算。

var cam: Camera3D
var yaw: float = 0.0
var pitch: float = 54.0
var dist: float = 21.0
var target: Vector3 = Vector3(0.0, 0.0, 1.0)
var g_yaw: float = 0.0
var g_pitch: float = 54.0
var g_dist: float = 21.0
var g_target: Vector3 = Vector3(0.0, 0.0, 1.0)
var focus: Vector3 = Vector3.ZERO          # 预设视角的参照点(当前地图节点在世界里的位置)
var shake_amt: float = 0.0
var user_moved: bool = false
var max_dist: float = 140.0                 # 滚轮能拉到的最远距离(大地图俯瞰整座城市时放大)
var pan_range: Vector2 = Vector2(30.0, 60.0)  # 平移镜头能离开 focus 多远(x, z)

## 预设的 target 是相对 focus 的偏移。备战：整个战斗地图(25×20 格，敌人出生点在边上) + 底部面板；战斗：稍近；
## menu：标题画面(卡车旁)；map 由 set_view() 直接给出。
const PRESETS := {
	"prep": {"yaw": 0.0, "pitch": 58.0, "dist": 44.0, "target": Vector3(0.0, 0.0, 2.6)},
	"battle": {"yaw": 0.0, "pitch": 56.0, "dist": 29.5, "target": Vector3(0.0, 0.0, 0.8)},
	"menu": {"yaw": -28.0, "pitch": 20.0, "dist": 11.0, "target": Vector3(0.4, 0.9, 0.4)},
	"top": {"yaw": 0.0, "pitch": 80.0, "dist": 27.0, "target": Vector3(0.0, 0.0, 0.4)},
}


func _init() -> void:
	cam = Camera3D.new()
	cam.fov = 30.0
	cam.near = 0.1
	cam.far = 1600.0               # 大地图从高空俯瞰整座城市，远处一直延伸进雾里
	cam.current = true
	add_child(cam)


func set_preset(name: String, instant: bool = false) -> void:
	var p: Dictionary = PRESETS.get(name, PRESETS["prep"])
	set_view(focus + (p["target"] as Vector3), float(p["yaw"]), float(p["pitch"]), float(p["dist"]), instant)


## 直接指定视角(世界坐标的注视点)
func set_view(p_target: Vector3, p_yaw: float, p_pitch: float, p_dist: float, instant: bool = false) -> void:
	g_yaw = p_yaw
	g_pitch = p_pitch
	g_dist = p_dist
	g_target = p_target
	user_moved = false
	if instant:
		yaw = g_yaw
		pitch = g_pitch
		dist = g_dist
		target = g_target
		_apply()


func orbit(dx: float, dy: float) -> void:
	g_yaw -= dx * 0.28
	g_pitch = clampf(g_pitch + dy * 0.25, 12.0, 82.0)
	user_moved = true


func zoom(factor: float) -> void:
	g_dist = clampf(g_dist * factor, 6.0, max_dist)
	user_moved = true


func pan(dx: float, dy: float) -> void:
	var right: Vector3 = cam.global_transform.basis.x
	var fwd: Vector3 = -cam.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	g_target += (-right * dx + fwd * dy) * 0.012 * g_dist / 12.0
	g_target.x = clampf(g_target.x, focus.x - pan_range.x, focus.x + pan_range.x)
	g_target.z = clampf(g_target.z, focus.z - pan_range.y, focus.z + pan_range.y)
	user_moved = true


func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount)


func _process(dt: float) -> void:
	var k: float = clampf(dt * 6.0, 0.0, 1.0)
	yaw = lerpf(yaw, g_yaw, k)
	pitch = lerpf(pitch, g_pitch, k)
	dist = lerpf(dist, g_dist, k)
	target = target.lerp(g_target, k)
	_apply()
	if shake_amt > 0.001:
		shake_amt = maxf(0.0, shake_amt - dt * 0.5)
		cam.h_offset = randf_range(-1.0, 1.0) * shake_amt
		cam.v_offset = randf_range(-1.0, 1.0) * shake_amt
	else:
		cam.h_offset = 0.0
		cam.v_offset = 0.0


func _apply() -> void:
	var yr: float = deg_to_rad(yaw)
	var pr: float = deg_to_rad(pitch)
	var dir := Vector3(sin(yr) * cos(pr), sin(pr), cos(yr) * cos(pr))
	cam.position = target + dir * dist
	cam.look_at(target, Vector3.UP)


func ray(screen_pos: Vector2) -> Array:
	return [cam.project_ray_origin(screen_pos), cam.project_ray_normal(screen_pos)]


func project(world: Vector3) -> Vector2:
	return cam.unproject_position(world)


func is_behind(world: Vector3) -> bool:
	return cam.is_position_behind(world)
