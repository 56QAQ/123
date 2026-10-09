class_name MixTriangle
extends Control
## 车间的配比三角图：三个角 = 三种材料(上 燃素 / 左下 有机物 / 右下 液态负熵)，三角形里每一点 = 一种配比，
## 底色 = 那个配比下各颜色概率加权混出来的颜色(只算当前门类里造得出的颜色)，平滑过渡；白圈 = 当前投入的配比。

var cat: Catalog
var mix := Vector3(1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0)   # 当前配比 (r, g, b)，和为 1
var has_mix: bool = false
var avail: Dictionary = {}                           # 造得出的颜色 -> true(空 = 都算)
const STEPS := 18


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(320, 286)


## 三个角的位置(留出放图标的边距)
func corners() -> Array[Vector2]:
	var w: float = size.x
	var h: float = size.y
	var side: float = minf(w - 40.0, (h - 40.0) / 0.866)
	var top := Vector2(w * 0.5, (h - side * 0.866) * 0.5)
	return [top, top + Vector2(-side * 0.5, side * 0.866), top + Vector2(side * 0.5, side * 0.866)]


func point_of(m: Vector3) -> Vector2:
	var c: Array[Vector2] = corners()
	return c[0] * m.x + c[1] * m.y + c[2] * m.z


func color_at(m: Vector3) -> Color:
	var w: Dictionary = Crafting.color_weights(cat, {"red": int(round(m.x * 1000.0)), "green": int(round(m.y * 1000.0)), "blue": int(round(m.z * 1000.0))})
	var acc := Color(0, 0, 0, 0)
	var sum := 0.0
	for col: String in w.keys():
		if not avail.is_empty() and not avail.has(col):
			continue
		var cc: Color = GC.faction_color(col)
		if col == "black":
			cc = cc.lightened(0.3)
		acc += cc * float(w[col])
		sum += float(w[col])
	if sum <= 0.0:
		return UIKit.BG_SOFT
	var r: Color = acc / sum
	r.a = 1.0
	return r


func _draw() -> void:
	if cat == null:
		return
	var c: Array[Vector2] = corners()
	# 小三角形网格：每个顶点按它的配比上色，draw_polygon 在顶点之间插值 = 平滑的颜色场
	var n: int = STEPS
	var cols: Dictionary = {}
	for i in range(n + 1):
		for j in range(n + 1 - i):
			var k: int = n - i - j
			cols[Vector2i(i, j)] = color_at(Vector3(float(i), float(j), float(k)) / float(n)).darkened(0.18)
	for i2 in range(n):
		for j2 in range(n - i2):
			var a := Vector2i(i2, j2)
			var b := Vector2i(i2 + 1, j2)
			var d := Vector2i(i2, j2 + 1)
			_tri([a, b, d], cols)
			if i2 + j2 + 1 < n:
				_tri([b, Vector2i(i2 + 1, j2 + 1), d], cols)
	# 外框 + 中线刻度
	var edge := PackedVector2Array([c[0], c[1], c[2], c[0]])
	draw_polyline(edge, UIKit.LINE_STRONG, 2.0)
	for t: float in [0.25, 0.5, 0.75]:
		for e2 in range(3):
			var p0: Vector2 = c[e2].lerp(c[(e2 + 1) % 3], t)
			var inward: Vector2 = (c[(e2 + 2) % 3] - p0).normalized()
			draw_line(p0, p0 + inward * 6.0, UIKit.LINE_STRONG, 1.0)
	# 当前配比
	if has_mix:
		var p: Vector2 = point_of(mix)
		draw_circle(p, 9.0, Color(0, 0, 0, 0.55))
		draw_arc(p, 8.0, 0.0, TAU, 24, Color.WHITE, 2.5)
		draw_circle(p, 3.0, Color.WHITE)


func _tri(ks: Array, cols: Dictionary) -> void:
	var pts := PackedVector2Array()
	var cs := PackedColorArray()
	var n: float = float(STEPS)
	for kk: Vector2i in ks:
		var m := Vector3(float(kk.x), float(kk.y), n - float(kk.x) - float(kk.y)) / n
		pts.append(point_of(m))
		cs.append(cols[kk])
	draw_polygon(pts, cs)
