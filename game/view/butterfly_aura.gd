class_name ButterflyAura
extends Node3D
## 白羽节点身边一直跟着的几只蝴蝶(两黑两白)：各自绕着她上半身走一条不规则的 8 字(李萨如)，慢慢扇；
## 她倒下时 scatter()：全部往上散开飞走。跟着单位视图走(top_level，不随朝向转)

var fx: Fx
var follow: Node3D
var height := 1.0
var _bfs: Array = []            # {bf, ph: Vector3}
var _t := 0.0


static func create(p_fx: Fx, p_follow: Node3D, p_height: float) -> ButterflyAura:
	var a := ButterflyAura.new()
	a.fx = p_fx
	a.follow = p_follow
	a.height = p_height
	a.top_level = true
	a.name = "ButterflyAura"
	p_fx.add_child(a)
	a.global_position = p_follow.global_position
	for i in range(4):
		var bf: Butterfly = Butterfly.make("white" if i % 2 == 0 else "black", 1.15)
		bf.flap_hz = randf_range(5.0, 6.5)
		a.add_child(bf)
		a._bfs.append({"bf": bf, "ph": Vector3(randf() * TAU, randf() * TAU, randf() * TAU), "sp": randf_range(0.8, 1.15)})
	a._t = randf() * 10.0
	return a


## 她倒下：蝴蝶各自往上散开飞走，然后删掉
func scatter() -> void:
	if follow == null:
		return
	for it: Dictionary in _bfs:
		if is_instance_valid(it["bf"]):
			var bf: Butterfly = it["bf"]
			ButterflyFlock.burst(fx, bf.global_position, 1 if bf.kind == "black" else 0, 1 if bf.kind == "white" else 0, 1.4, 1.4, 1.6, 1.15, 0.0, 1.0)
	queue_free()


func _process(delta: float) -> void:
	if follow == null or not is_instance_valid(follow):
		queue_free()
		return
	var s: float = maxf(0.2, fx.speed_scale) if fx != null else 1.0
	var dt: float = delta * s
	_t += dt
	global_position = follow.global_position
	for it: Dictionary in _bfs:
		if not is_instance_valid(it["bf"]):
			continue
		var bf: Butterfly = it["bf"]
		var ph: Vector3 = it["ph"]
		var t: float = _t * float(it["sp"])
		var target := Vector3(sin(t * 0.9 + ph.x) * 0.62, height + 0.22 * sin(t * 1.7 + ph.y), cos(t * 0.65 + ph.z) * 0.55)
		var p: Vector3 = bf.position.lerp(target, 1.0 - exp(-5.0 * dt))
		var vel: Vector3 = p - bf.position
		bf.position = p
		bf.time_scale = s
		if vel.length() > 1e-4:
			bf.face(vel)
