class_name ButterflyFlock
extends Node3D
## 一次性的一群蝴蝶(白羽节点)：从 at 附近带着初速度往外 / 往上飞出去，边飞边被扰动(蝴蝶不走直线)、慢慢减速往上飘，
## 寿命到了缩小消失，全部飞完自己删。送葬(满层倒下：黑白一大群)、送葬之痕(黑蝶咬一口散开)、治疗弹(一只白蝶)、
## 求生的意志(一圈白蝶)、她自己倒下都用它

var fx: Fx
var _items: Array = []          # {bf, vel, age, life, wob, size}


## n_black / n_white 只；speed = 初速度(米/秒)，rise = 往上飘的加速度，spread = 出生点散开的半径，size = 蝴蝶大小
static func burst(p_fx: Fx, at: Vector3, n_black: int, n_white: int, speed: float = 2.0, rise: float = 1.2, life: float = 1.4,
		size: float = 1.0, spread: float = 0.2, up_bias: float = 0.6) -> ButterflyFlock:
	var f := ButterflyFlock.new()
	f.fx = p_fx
	f.top_level = true
	p_fx.add_child(f)
	f.global_position = Vector3.ZERO
	var n: int = n_black + n_white
	for i in range(n):
		var k: String = "black" if i < n_black else "white"
		var bf: Butterfly = Butterfly.make(k, size * randf_range(0.8, 1.15))
		bf.flap_hz = randf_range(7.0, 9.5)
		f.add_child(bf)
		var a: float = TAU * (float(i) + randf() * 0.6) / float(maxi(1, n))
		var out := Vector3(cos(a), 0.0, sin(a))
		bf.position = at + out * spread * randf_range(0.3, 1.0) + Vector3(0.0, randf_range(-0.15, 0.2), 0.0)
		var v: Vector3 = (out * randf_range(0.6, 1.0) + Vector3(0.0, up_bias + randf_range(-0.2, 0.4), 0.0)).normalized() * speed * randf_range(0.6, 1.1)
		f._items.append({"bf": bf, "vel": v, "age": -randf() * 0.06, "life": life * randf_range(0.75, 1.15), "wob": randf() * TAU,
			"size": bf.scale.x, "rise": rise})
	return f


func _process(delta: float) -> void:
	var s: float = maxf(0.2, fx.speed_scale) if fx != null else 1.0
	var dt: float = delta * s
	var alive := 0
	for it: Dictionary in _items:
		if not is_instance_valid(it["bf"]):
			continue
		var bf: Butterfly = it["bf"]
		it["age"] = float(it["age"]) + dt
		var age: float = float(it["age"])
		var life: float = float(it["life"])
		if age >= life:
			bf.queue_free()
			it["bf"] = null
			continue
		alive += 1
		bf.time_scale = s
		if age < 0.0:
			bf.visible = false
			continue
		bf.visible = true
		var v: Vector3 = it["vel"]
		var w: float = float(it["wob"]) + age * 5.0
		# 蝴蝶的飞法：一顿一顿往上(扇一下升一下)、左右摆
		v += Vector3(cos(w) * 1.6, float(it["rise"]) + sin(w * 1.7) * 1.2, sin(w * 0.8) * 1.6) * dt
		v *= exp(-1.6 * dt)
		it["vel"] = v
		bf.position += v * dt
		var sc: float = float(it["size"]) * minf(1.0, age / 0.08) * (1.0 - smoothstep(life * 0.7, life, age))
		bf.scale = Vector3.ONE * maxf(0.001, sc)
		bf.face(v)
	if alive == 0:
		queue_free()
