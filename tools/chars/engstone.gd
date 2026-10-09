extends "res://tools/model_chars.gd"
## Node EngStone 工程石：一块矮胖不规则的灰色巨石(阶梯状碎裂石板、深色裂缝)，赤道一圈黄黑斜纹警示带；没有头脸四肢。
## 挂骨：整块挂 Hips(刚性权重，不参与髋/腿/脊柱的软权重区)，跟着待机呼吸/跑步轻轻起伏；落地放。

const HAIR := []

const C := Vector3(0.0, 26.5, 0.0)       # 石头中心
const R := Vector3(23.0, 26.5, 20.5)     # 半径(高 53、宽 46)
const N := 2.4                           # 超椭球指数(>2 更敦实)
const BAND_Y0 := 23
const BAND_Y1 := 29


func build() -> void:
	var seeds: Array = _engstone_seeds(19)
	_engstone_rock(seeds)
	_engstone_chunks()
	_engstone_band()
	_engstone_rigid()


## 表面碎块的"种子方向"(斐波那契球面 + 抖动)；每块一个外凸量、一个倾斜方向、一个灰度
func _engstone_seeds(n: int) -> Array:
	var r: Array = []
	var ga: float = PI * (3.0 - sqrt(5.0))
	for i in range(n):
		var y: float = 1.0 - 2.0 * (float(i) + 0.5) / float(n)
		var rad: float = sqrt(maxf(0.0, 1.0 - y * y))
		var th: float = ga * float(i) + (h01(i, 7, 3) - 0.5) * 0.6
		var d := Vector3(cos(th) * rad, y + (h01(i, 1, 9) - 0.5) * 0.15, sin(th) * rad).normalized()
		var tilt := Vector3(h01(i, 3, 1) - 0.5, h01(i, 5, 2) - 0.5, h01(i, 2, 8) - 0.5)
		var nrm: Vector3 = (d + tilt * 0.5).normalized()
		r.append({"d": d, "n": nrm, "off": 0.02 + 0.12 * h01(i, 11, 4), "tone": h01(i, 13, 6)})
	return r


func _engstone_rock(seeds: Array) -> void:
	var gA := H("#74716d")
	var gB := H("#67645f")
	var gC := H("#5b5854")
	var gD := H("#807d78")
	var top := H("#918e89")
	var dark := H("#45423f")
	var crack := H("#353230")
	g.sym = false
	g.use("Hips")
	# 第一遍：形体(每个体素属于最近的碎块；碎块各自外凸/倾斜 → 阶梯状石板；块与块之间下凹一道裂缝)
	var cell := {}
	for z in range(int(C.z - R.z) - 3, int(C.z + R.z) + 3):
		for y in range(0, int(C.y + R.y) + 3):
			for x in range(int(C.x - R.x) - 3, int(C.x + R.x) + 3):
				var q := Vector3((x + 0.5 - C.x) / R.x, (y + 0.5 - C.y) / R.y, (z + 0.5 - C.z) / R.z)
				var rr: float = pow(pow(absf(q.x), N) + pow(absf(q.y), N) + pow(absf(q.z), N), 1.0 / N)
				if rr > 1.15 or rr < 0.0001:
					continue
				var d: Vector3 = q.normalized()
				var b1 := -2.0
				var b2 := -2.0
				var k1 := 0
				for k in range(seeds.size()):
					var dd: float = d.dot(seeds[k]["d"])
					if dd > b1:
						b2 = b1
						b1 = dd
						k1 = k
					elif dd > b2:
						b2 = dd
				var s: Dictionary = seeds[k1]
				# 每块是一片平面石板：沿块法线的投影不超过 0.86 + 外凸量(相邻块外凸量不同 → 台阶)
				var lim: float = 0.86 + float(s["off"])
				var is_crack: bool = b1 - b2 < 0.035
				if is_crack:
					lim -= 0.05
				if q.dot(s["n"]) > lim or rr > 1.02:
					continue
				cell[Vector3i(x, y, z)] = [k1, is_crack]
	# 第二遍：上色(朝上的面更亮、下半更暗、裂缝深色)
	for key: Vector3i in cell.keys():
		var info: Array = cell[key]
		var k: int = info[0]
		var tone: float = seeds[k]["tone"]
		var c: int = gA
		if tone < 0.25:
			c = gC
		elif tone < 0.5:
			c = gB
		elif tone > 0.8:
			c = gD
		if bool(info[1]):
			c = crack
		elif not cell.has(key + Vector3i(0, 1, 0)):
			c = top if tone > 0.3 else gD
		elif h01(key.x, key.y, key.z) > 0.93:
			c = VGrid.shade(c, 0.93)
		if key.y < 12 and not bool(info[1]):
			c = VGrid.mix(c, dark, 0.35 * float(12 - key.y) / 12.0)
		g.put(key.x, key.y, key.z, c)


## 石面上几块凸起的方块碎石(让轮廓更"阶梯"、不像光滑多面体)：只填空处，朝上一面亮
func _engstone_chunks() -> void:
	var cA := H("#7a7773")
	var cT := H("#948f8a")
	var cS := H("#5f5c58")
	g.sym = false
	g.use("Hips")
	g.set_mode(VGrid.ADD)
	for i in range(14):
		var th: float = TAU * h01(i, 21, 5)
		var yy: float = lerpf(0.15, 0.95, h01(i, 22, 6))
		if i < 3:
			yy = 0.97
		var rad: float = sqrt(maxf(0.0, 1.0 - yy * yy))
		var p := Vector3(C.x + cos(th) * rad * R.x * 0.9, C.y + yy * R.y * 0.9, C.z + sin(th) * rad * R.z * 0.9)
		var hx: int = 2 + int(h01(i, 23, 7) * 3.0)
		var hy: int = 1 + int(h01(i, 24, 8) * 2.0)
		var hz: int = 2 + int(h01(i, 25, 9) * 3.0)
		var x0: int = int(p.x) - hx
		var y0: int = int(p.y) - hy
		var z0: int = int(p.z) - hz
		var fn := func(x: int, y: int, z: int) -> int:
			if y == y0 + 2 * hy:
				return cT
			return cS if y == y0 else cA
		g.box(x0, y0, z0, x0 + 2 * hx, y0 + 2 * hy, z0 + 2 * hz, fn)
	g.set_mode(VGrid.FILL)


## 赤道一圈黄黑斜纹警示带(比石面凸出 2 格，上下各一行暗边)
func _engstone_band() -> void:
	var yel := H("#f0bf2e")
	var yel2 := H("#d9a41f")
	var blk := H("#2b2a28")
	var blk2 := H("#3a3835")
	g.sym = false
	g.use("Hips")
	var ro := Vector2(R.x * 0.95 + 1.6, R.z * 0.95 + 1.6)
	var ri := Vector2(R.x * 0.6, R.z * 0.6)
	for y in range(BAND_Y0, BAND_Y1 + 1):
		for z in range(-int(ro.y) - 2, int(ro.y) + 2):
			for x in range(-int(ro.x) - 2, int(ro.x) + 2):
				var px: float = x + 0.5 - C.x
				var pz: float = z + 0.5 - C.z
				var eo: float = pow(absf(px / ro.x), N) + pow(absf(pz / ro.y), N)
				var ei: float = pow(absf(px / ri.x), N) + pow(absf(pz / ri.y), N)
				if eo > 1.0 or ei < 1.0:
					continue
				var arc: float = atan2(pz, px) * 22.0
				var s: int = int(floor((arc + float(y - BAND_Y0) * 1.0) / 4.0))
				var c: int = yel if posmod(s, 2) == 0 else blk
				if y == BAND_Y0 or y == BAND_Y1:
					c = yel2 if c == yel else blk2
				g.put(x, y, z, c)


## 整块刚性：所有体素 100% 跟 Hips(不被髋→大腿、髋→脊柱的软权重区拉扯)
func _engstone_rigid() -> void:
	var hb: int = rig.ids["Hips"]
	for z in range(-30, 31):
		for y in range(-2, 62):
			for x in range(-32, 32):
				if g.solid(x, y, z):
					g.set_weights(x, y, z, [[hb, 1.0]])
