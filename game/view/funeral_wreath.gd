class_name FuneralWreath
extends Node3D
## 【送葬】(白羽节点)的层数：每一层 = 一只黑蝶，绕着目标胸口一圈一圈地飞(一只只排开，上下起伏)。
## 层数越接近满层，圈收得越紧、飞得越快、扇得越急；新的一层从施加者(她的枪口)那一侧飞进来。
## pulse()：圈一下子被撑开(求生的意志把死亡推开了一下)；release(kill)：全部扑进目标身体里，然后自己消失
## (满层倒下 / 送葬之痕的那一群由 Fx 接着放)。跟着单位视图走(top_level，不随单位朝向转)

const SIZE := 1.35              # 翼展 27 cm：游戏镜头下也看得出是蝴蝶

var fx: Fx
var follow: Node3D
var height := 0.85
var stacks := 0
var of := 10
var _bfs: Array = []             # {bf, slot, prev}
var _t := 0.0
var _pulse := 0.0
var _closing := -1.0             # >= 0：正在扑进身体里(秒)


static func create(p_fx: Fx, p_follow: Node3D, p_height: float) -> FuneralWreath:
	var w := FuneralWreath.new()
	w.fx = p_fx
	w.follow = p_follow
	w.height = p_height
	w.top_level = true
	w.name = "FuneralWreath"
	p_fx.add_child(w)
	w.global_position = p_follow.global_position
	w._t = randf() * 10.0
	return w


## n 层(满层 z)；src = 施加者的位置(新的黑蝶从那一侧飞进来)，没有就从随机方向
func set_stacks(n: int, z: int, src: Variant = null) -> void:
	of = maxi(1, z)
	n = clampi(n, 0, 12)
	if n == stacks or _closing >= 0.0:
		return
	while _bfs.size() < n:
		var bf: Butterfly = Butterfly.make("black", SIZE)
		add_child(bf)
		var dir := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
		if src is Vector3 and follow != null:
			var d: Vector3 = (src as Vector3) - follow.global_position
			d.y = 0.0
			if d.length() > 0.1:
				dir = d.normalized()
		bf.position = dir * 1.1 + Vector3(0.0, height + 0.35, 0.0)
		bf.scale = Vector3.ONE * 0.3
		_bfs.append({"bf": bf, "prev": bf.position})
	while _bfs.size() > n:
		var it: Dictionary = _bfs.pop_back()
		if not is_instance_valid(it["bf"]):
			continue
		var bf2: Butterfly = it["bf"]
		var tw := bf2.create_tween()
		tw.tween_property(bf2, "scale", Vector3.ONE * 0.01, 0.25)
		tw.tween_callback(bf2.queue_free)
	stacks = n
	if n == 0:
		get_tree().create_timer(0.3).timeout.connect(queue_free)


## 求生的意志：圈一下子被撑开、再慢慢收回来
func pulse() -> void:
	_pulse = 1.0


## 满层：全部扑进身体里(0.22 秒)，然后消失
func release() -> void:
	if _closing < 0.0:
		_closing = 0.0


func _process(delta: float) -> void:
	if follow == null or not is_instance_valid(follow):
		queue_free()
		return
	var s: float = maxf(0.2, fx.speed_scale) if fx != null else 1.0
	var dt: float = delta * s
	global_position = follow.global_position
	_t += dt
	_pulse = maxf(0.0, _pulse - dt * 1.6)
	var n: int = _bfs.size()
	var k: float = clampf(float(stacks) / float(of), 0.0, 1.0)
	var r: float = lerpf(0.6, 0.42, k) + 0.5 * _pulse * _pulse
	var w: float = lerpf(1.5, 3.4, k)
	if _closing >= 0.0:
		_closing += dt
		var ck: float = clampf(_closing / 0.22, 0.0, 1.0)
		for it: Dictionary in _bfs:
			if is_instance_valid(it["bf"]):
				var bf: Butterfly = it["bf"]
				bf.time_scale = s * 2.0
				var p0: Vector3 = it["prev"]
				var p1: Vector3 = p0.lerp(Vector3(0.0, height, 0.0), ck * ck)
				bf.face(p1 - bf.position)
				bf.position = p1
				bf.scale = Vector3.ONE * SIZE * (1.0 - 0.6 * ck)
		if _closing >= 0.24:
			queue_free()
		return
	for i in range(n):
		var it: Dictionary = _bfs[i]
		if not is_instance_valid(it["bf"]):
			continue
		var bf: Butterfly = it["bf"]
		bf.time_scale = s * lerpf(1.0, 1.6, k)
		var a: float = _t * w + TAU * float(i) / float(maxi(1, n))
		var bob: float = 0.07 * sin(_t * 3.1 + float(i) * 2.3) + 0.04 * float(i % 3 - 1)
		var target := Vector3(cos(a) * r, height + bob, sin(a) * r)
		var p: Vector3 = bf.position.lerp(target, 1.0 - exp(-7.0 * dt))
		var vel: Vector3 = p - bf.position
		if vel.length() < 1e-4:
			vel = Vector3(-sin(a), 0.0, cos(a))
		bf.position = p
		bf.face(vel)
		bf.scale = Vector3.ONE * lerpf(bf.scale.x, SIZE, 1.0 - exp(-8.0 * dt))
		it["prev"] = p
