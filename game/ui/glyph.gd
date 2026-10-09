class_name Glyph
extends Control
## 矢量图标：金币/心/星/宝石 + 6 类载荷规则图标 + 9 类武器图标(w_<大类>)。用 _draw 画，跟随 color 着色。

var kind: String = "gem"
var color: Color = Color.WHITE
var filled_alpha: float = 1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(16, 16)


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	if s <= 0.0:
		return
	var o := Vector2((size.x - s) * 0.5, (size.y - s) * 0.5)
	var c: Color = color
	c.a *= filled_alpha
	var dark: Color = Color(0, 0, 0, 0.45)
	match kind:
		"gem":
			var pts := PackedVector2Array([o + Vector2(0.5, 0.04) * s, o + Vector2(0.94, 0.5) * s, o + Vector2(0.5, 0.96) * s, o + Vector2(0.06, 0.5) * s])
			draw_colored_polygon(pts, c)
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), dark, maxf(1.0, s * 0.07))
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.5, 0.18) * s, o + Vector2(0.72, 0.5) * s, o + Vector2(0.5, 0.5) * s]), Color(1, 1, 1, 0.35))
		"coin":
			draw_circle(o + Vector2(0.5, 0.5) * s, s * 0.46, Color("#c98d1e"))
			draw_circle(o + Vector2(0.5, 0.5) * s, s * 0.40, Color("#ffd24a"))
			draw_circle(o + Vector2(0.5, 0.5) * s, s * 0.26, Color("#f0b52a"))
			draw_rect(Rect2(o + Vector2(0.44, 0.30) * s, Vector2(0.12, 0.40) * s), Color("#ffe48a"))
		"heart":
			var pts2 := PackedVector2Array()
			for i in range(41):
				var t: float = TAU * float(i) / 40.0
				var x: float = 16.0 * pow(sin(t), 3.0)
				var y: float = 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
				pts2.append(o + Vector2(0.5 + x / 36.0, 0.46 - y / 36.0) * s)
			draw_colored_polygon(pts2, c)
		"star":
			var pts3 := PackedVector2Array()
			for i in range(10):
				var ang: float = -PI * 0.5 + PI * float(i) / 5.0
				var r: float = 0.48 if i % 2 == 0 else 0.20
				pts3.append(o + (Vector2(0.5, 0.52) + Vector2(cos(ang), sin(ang)) * r) * s)
			draw_colored_polygon(pts3, c)
		"lock":
			draw_rect(Rect2(o + Vector2(0.2, 0.44) * s, Vector2(0.6, 0.46) * s), c)
			draw_arc(o + Vector2(0.5, 0.44) * s, s * 0.22, PI, TAU, 14, c, maxf(1.5, s * 0.10))
		"bullet":
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.5, 0.05) * s, o + Vector2(0.74, 0.30) * s, o + Vector2(0.74, 0.92) * s, o + Vector2(0.26, 0.92) * s, o + Vector2(0.26, 0.30) * s]), c)
			draw_rect(Rect2(o + Vector2(0.26, 0.66) * s, Vector2(0.48, 0.07) * s), dark)
		"blade":
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.86, 0.06) * s, o + Vector2(0.94, 0.14) * s, o + Vector2(0.34, 0.74) * s, o + Vector2(0.26, 0.66) * s]), c)
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.14, 0.58) * s, o + Vector2(0.42, 0.86) * s, o + Vector2(0.34, 0.94) * s, o + Vector2(0.06, 0.66) * s]), c.darkened(0.25))
			draw_line(o + Vector2(0.2, 0.8) * s, o + Vector2(0.08, 0.92) * s, c.darkened(0.4), maxf(2.0, s * 0.12))
		"amulet":
			draw_arc(o + Vector2(0.5, 0.34) * s, s * 0.26, 0.0, TAU, 20, c.darkened(0.2), maxf(1.2, s * 0.06))
			draw_circle(o + Vector2(0.5, 0.64) * s, s * 0.30, c)
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.5, 0.50) * s, o + Vector2(0.62, 0.64) * s, o + Vector2(0.5, 0.78) * s, o + Vector2(0.38, 0.64) * s]), Color(1, 1, 1, 0.55))
		"potion":
			draw_circle(o + Vector2(0.5, 0.66) * s, s * 0.30, c)
			draw_rect(Rect2(o + Vector2(0.4, 0.14) * s, Vector2(0.2, 0.30) * s), c.lightened(0.15))
			draw_rect(Rect2(o + Vector2(0.34, 0.08) * s, Vector2(0.32, 0.08) * s), c.darkened(0.3))
			draw_circle(o + Vector2(0.42, 0.62) * s, s * 0.07, Color(1, 1, 1, 0.5))
		"chip":
			draw_rect(Rect2(o + Vector2(0.22, 0.22) * s, Vector2(0.56, 0.56) * s), c)
			draw_rect(Rect2(o + Vector2(0.36, 0.36) * s, Vector2(0.28, 0.28) * s), dark)
			for i in range(3):
				var t2: float = 0.30 + 0.20 * float(i)
				draw_rect(Rect2(o + Vector2(0.10, t2) * s, Vector2(0.12, 0.07) * s), c.darkened(0.2))
				draw_rect(Rect2(o + Vector2(0.78, t2) * s, Vector2(0.12, 0.07) * s), c.darkened(0.2))
		"tome":
			draw_rect(Rect2(o + Vector2(0.14, 0.18) * s, Vector2(0.72, 0.64) * s), c.darkened(0.2))
			draw_rect(Rect2(o + Vector2(0.18, 0.22) * s, Vector2(0.30, 0.56) * s), c)
			draw_rect(Rect2(o + Vector2(0.52, 0.22) * s, Vector2(0.30, 0.56) * s), c.lightened(0.1))
			draw_line(o + Vector2(0.5, 0.2) * s, o + Vector2(0.5, 0.8) * s, dark, maxf(1.0, s * 0.06))
		"xp":
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.5, 0.08) * s, o + Vector2(0.9, 0.80) * s, o + Vector2(0.1, 0.80) * s]), c)
			draw_rect(Rect2(o + Vector2(0.46, 0.34) * s, Vector2(0.08, 0.26) * s), dark)
			draw_circle(o + Vector2(0.5, 0.68) * s, s * 0.05, dark)
		"reroll":
			draw_arc(o + Vector2(0.5, 0.5) * s, s * 0.32, -0.3, TAU * 0.78, 20, c, maxf(1.6, s * 0.11))
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.86, 0.40) * s, o + Vector2(0.62, 0.34) * s, o + Vector2(0.80, 0.10) * s]), c)
		"play":
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.24, 0.14) * s, o + Vector2(0.86, 0.5) * s, o + Vector2(0.24, 0.86) * s]), c)
		"pause":
			draw_rect(Rect2(o + Vector2(0.22, 0.16) * s, Vector2(0.20, 0.68) * s), c)
			draw_rect(Rect2(o + Vector2(0.58, 0.16) * s, Vector2(0.20, 0.68) * s), c)
		"skull":
			draw_circle(o + Vector2(0.5, 0.42) * s, s * 0.34, c)
			draw_rect(Rect2(o + Vector2(0.32, 0.60) * s, Vector2(0.36, 0.28) * s), c)
			draw_circle(o + Vector2(0.38, 0.44) * s, s * 0.08, dark)
			draw_circle(o + Vector2(0.62, 0.44) * s, s * 0.08, dark)
		"w_sword":
			_blade_icon(o, s, c, dark, Vector2(0.84, 0.16), Vector2(0.30, 0.70), 0.075, 0.20)
		"w_heavy":
			_blade_icon(o, s, c, dark, Vector2(0.88, 0.12), Vector2(0.32, 0.68), 0.13, 0.28)
		"w_polearm":
			draw_line(o + Vector2(0.10, 0.90) * s, o + Vector2(0.74, 0.26) * s, c.darkened(0.25), maxf(2.0, s * 0.08))
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.94, 0.06) * s, o + Vector2(0.82, 0.32) * s, o + Vector2(0.68, 0.32) * s,
				o + Vector2(0.68, 0.18) * s]), c)
			draw_line(o + Vector2(0.62, 0.30) * s, o + Vector2(0.74, 0.42) * s, c, maxf(1.5, s * 0.06))
		"w_dual":
			_blade_icon(o, s * 0.8, c, dark, Vector2(0.9, 0.1), Vector2(0.38, 0.62), 0.07, 0.16, Vector2(0.0, 0.2) * s)
			_blade_icon(o, s * 0.8, c.darkened(0.12), dark, Vector2(0.1, 0.1), Vector2(0.62, 0.62), 0.07, 0.16, Vector2(0.25, 0.2) * s)
		"w_bow":
			draw_arc(o + Vector2(0.28, 0.5) * s, s * 0.44, -1.1, 1.1, 18, c, maxf(2.0, s * 0.09))
			var tip_a: Vector2 = o + (Vector2(0.28, 0.5) + Vector2(cos(-1.1), sin(-1.1)) * 0.44) * s
			var tip_b: Vector2 = o + (Vector2(0.28, 0.5) + Vector2(cos(1.1), sin(1.1)) * 0.44) * s
			draw_line(tip_a, tip_b, c.lightened(0.3), maxf(1.0, s * 0.03))
			draw_line(o + Vector2(0.40, 0.5) * s, o + Vector2(0.95, 0.5) * s, c.lightened(0.15), maxf(1.2, s * 0.05))
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.98, 0.5) * s, o + Vector2(0.86, 0.42) * s, o + Vector2(0.86, 0.58) * s]), c)
		"w_crossbow":
			draw_rect(Rect2(o + Vector2(0.44, 0.30) * s, Vector2(0.12, 0.62) * s), c.darkened(0.2))
			draw_arc(o + Vector2(0.5, 0.62) * s, s * 0.42, PI * 1.18, PI * 1.82, 16, c, maxf(2.0, s * 0.09))
			draw_line(o + Vector2(0.14, 0.40) * s, o + Vector2(0.5, 0.52) * s, c.lightened(0.3), maxf(1.0, s * 0.03))
			draw_line(o + Vector2(0.86, 0.40) * s, o + Vector2(0.5, 0.52) * s, c.lightened(0.3), maxf(1.0, s * 0.03))
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.5, 0.04) * s, o + Vector2(0.42, 0.18) * s, o + Vector2(0.58, 0.18) * s]), c)
		"w_pistols":
			for k in range(2):
				var dx: float = 0.02 + 0.46 * float(k)
				draw_rect(Rect2(o + Vector2(dx, 0.30 + 0.08 * k) * s, Vector2(0.46, 0.13) * s), c if k == 0 else c.darkened(0.15))
				draw_colored_polygon(PackedVector2Array([o + Vector2(dx + 0.30, 0.40 + 0.08 * k) * s, o + Vector2(dx + 0.44, 0.40 + 0.08 * k) * s,
					o + Vector2(dx + 0.40, 0.74 + 0.08 * k) * s, o + Vector2(dx + 0.26, 0.74 + 0.08 * k) * s]), c.darkened(0.3 if k == 0 else 0.4))
		"w_rifle":
			draw_line(o + Vector2(0.04, 0.72) * s, o + Vector2(0.96, 0.30) * s, c.lightened(0.1), maxf(1.6, s * 0.06))
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.02, 0.70) * s, o + Vector2(0.30, 0.56) * s, o + Vector2(0.36, 0.66) * s,
				o + Vector2(0.10, 0.86) * s]), c.darkened(0.25))
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.30, 0.56) * s, o + Vector2(0.70, 0.38) * s, o + Vector2(0.72, 0.46) * s,
				o + Vector2(0.34, 0.64) * s]), c)
			draw_rect(Rect2(o + Vector2(0.40, 0.44) * s, Vector2(0.18, 0.06) * s), dark)
		"w_focus":
			draw_circle(o + Vector2(0.5, 0.40) * s, s * 0.30, c)
			draw_circle(o + Vector2(0.42, 0.32) * s, s * 0.09, Color(1, 1, 1, 0.55))
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.30, 0.94) * s, o + Vector2(0.70, 0.94) * s, o + Vector2(0.60, 0.72) * s,
				o + Vector2(0.40, 0.72) * s]), c.darkened(0.35))
		"check":
			draw_polyline(PackedVector2Array([o + Vector2(0.16, 0.54) * s, o + Vector2(0.40, 0.78) * s, o + Vector2(0.86, 0.24) * s]), c, maxf(2.0, s * 0.16), true)
		"crystal":
			# 彩虹水晶祭坛：石台 + 三根彩色水晶
			draw_rect(Rect2(o + Vector2(0.12, 0.76) * s, Vector2(0.76, 0.14) * s), c)
			var cols: Array[Color] = [Color("#ff8fb0"), Color("#9fe8ff"), Color("#c8a2ff")]
			var xs: Array[float] = [0.28, 0.5, 0.72]
			var hs: Array[float] = [0.42, 0.66, 0.46]
			for k in range(3):
				var cx: float = xs[k]
				var top: float = 0.76 - hs[k]
				var cc: Color = cols[k]
				cc.a = c.a
				draw_colored_polygon(PackedVector2Array([o + Vector2(cx, top) * s, o + Vector2(cx + 0.1, top + 0.14) * s,
					o + Vector2(cx + 0.07, 0.76) * s, o + Vector2(cx - 0.07, 0.76) * s, o + Vector2(cx - 0.1, top + 0.14) * s]), cc)
		"truck":
			# 工坊卡车：方形货厢 + 驾驶室 + 两个轮子
			draw_rect(Rect2(o + Vector2(0.04, 0.22) * s, Vector2(0.58, 0.46) * s), c)
			draw_rect(Rect2(o + Vector2(0.64, 0.36) * s, Vector2(0.30, 0.32) * s), c.darkened(0.2))
			draw_rect(Rect2(o + Vector2(0.72, 0.40) * s, Vector2(0.16, 0.12) * s), Color(0.55, 0.85, 1.0, c.a))
			draw_line(o + Vector2(0.30, 0.28) * s, o + Vector2(0.30, 0.62) * s, dark, maxf(1.0, s * 0.04))
			draw_circle(o + Vector2(0.20, 0.74) * s, s * 0.10, dark)
			draw_circle(o + Vector2(0.78, 0.74) * s, s * 0.10, dark)
		"w_unarmed":
			draw_rect(Rect2(o + Vector2(0.26, 0.30) * s, Vector2(0.48, 0.42) * s), c)
			for f in range(4):
				draw_line(o + Vector2(0.30 + 0.12 * f, 0.30) * s, o + Vector2(0.30 + 0.12 * f, 0.50) * s, dark, maxf(1.0, s * 0.03))
		# ---- 方格网大地图的节点类型(第一章起)
		"n_unknown":
			draw_string(UIKit.font_bold, o + Vector2(0.27, 0.8) * s, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(s * 0.8), c)
		"n_start":
			draw_line(o + Vector2(0.3, 0.1) * s, o + Vector2(0.3, 0.92) * s, c, maxf(1.5, s * 0.08))
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.33, 0.12) * s, o + Vector2(0.86, 0.28) * s, o + Vector2(0.33, 0.46) * s]), c)
		"n_fight":
			_blade_icon(o, s, c, dark, Vector2(0.86, 0.12), Vector2(0.3, 0.68), 0.06, 0.13)
			_blade_icon(o, s, c, dark, Vector2(0.14, 0.12), Vector2(0.7, 0.68), 0.06, 0.13)
		"n_elite", "n_boss", "n_hunt":
			# 头骨(精英带角，首领头上冒火)
			var cc2: Vector2 = o + Vector2(0.5, 0.48) * s
			draw_circle(cc2, s * 0.3, c)
			draw_rect(Rect2(o + Vector2(0.34, 0.62) * s, Vector2(0.32, 0.22) * s), c)
			draw_circle(o + Vector2(0.39, 0.48) * s, s * 0.08, dark.darkened(0.5))
			draw_circle(o + Vector2(0.61, 0.48) * s, s * 0.08, dark.darkened(0.5))
			for tx in [0.42, 0.5, 0.58]:
				draw_line(o + Vector2(tx, 0.7) * s, o + Vector2(tx, 0.84) * s, dark, maxf(1.0, s * 0.03))
			if kind == "n_elite":
				draw_colored_polygon(PackedVector2Array([o + Vector2(0.24, 0.32) * s, o + Vector2(0.1, 0.05) * s, o + Vector2(0.34, 0.24) * s]), c)
				draw_colored_polygon(PackedVector2Array([o + Vector2(0.76, 0.32) * s, o + Vector2(0.9, 0.05) * s, o + Vector2(0.66, 0.24) * s]), c)
			else:
				var fc := Color("#ffb03a")
				fc.a = c.a
				draw_colored_polygon(PackedVector2Array([o + Vector2(0.3, 0.22) * s, o + Vector2(0.36, 0.0) * s, o + Vector2(0.44, 0.16) * s,
					o + Vector2(0.5, -0.06) * s, o + Vector2(0.56, 0.16) * s, o + Vector2(0.64, 0.0) * s, o + Vector2(0.7, 0.22) * s]), fc)
		"n_rest":
			# 篝火：两根交叉的木柴 + 火苗
			draw_line(o + Vector2(0.18, 0.88) * s, o + Vector2(0.82, 0.66) * s, c.darkened(0.35), maxf(2.0, s * 0.1))
			draw_line(o + Vector2(0.18, 0.66) * s, o + Vector2(0.82, 0.88) * s, c.darkened(0.35), maxf(2.0, s * 0.1))
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.5, 0.08) * s, o + Vector2(0.72, 0.5) * s, o + Vector2(0.62, 0.72) * s,
				o + Vector2(0.38, 0.72) * s, o + Vector2(0.28, 0.5) * s]), c)
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.5, 0.36) * s, o + Vector2(0.6, 0.6) * s, o + Vector2(0.4, 0.6) * s]), Color(1, 1, 1, 0.55 * c.a))
		"n_event":
			draw_string(UIKit.font_bold, o + Vector2(0.18, 0.8) * s, "!?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(s * 0.72), c)
		"n_shop_black":
			# 钱袋
			draw_circle(o + Vector2(0.5, 0.62) * s, s * 0.3, c)
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.36, 0.18) * s, o + Vector2(0.64, 0.18) * s, o + Vector2(0.56, 0.36) * s, o + Vector2(0.44, 0.36) * s]), c)
			draw_string(UIKit.font_bold, o + Vector2(0.38, 0.78) * s, "$", HORIZONTAL_ALIGNMENT_LEFT, -1, int(s * 0.42), dark.darkened(0.4))
		"n_shop_parts", "p_part":
			# 齿轮
			var gc: Vector2 = o + Vector2(0.5, 0.5) * s
			for i in range(8):
				var a: float = float(i) * TAU / 8.0
				draw_rect(Rect2(gc + Vector2(cos(a), sin(a)) * s * 0.36 - Vector2(0.08, 0.08) * s, Vector2(0.16, 0.16) * s), c)
			draw_circle(gc, s * 0.32, c)
			draw_circle(gc, s * 0.13, dark.darkened(0.4))
		# ---- 卡车零件
		"fuel", "p_jerrycan":
			draw_rect(Rect2(o + Vector2(0.22, 0.22) * s, Vector2(0.56, 0.7) * s), c)
			draw_rect(Rect2(o + Vector2(0.5, 0.08) * s, Vector2(0.2, 0.16) * s), c)
			draw_line(o + Vector2(0.3, 0.32) * s, o + Vector2(0.7, 0.82) * s, dark, maxf(1.0, s * 0.06))
			draw_line(o + Vector2(0.7, 0.32) * s, o + Vector2(0.3, 0.82) * s, dark, maxf(1.0, s * 0.06))
		"p_offroad_tire":
			draw_circle(o + Vector2(0.5, 0.5) * s, s * 0.42, c)
			draw_circle(o + Vector2(0.5, 0.5) * s, s * 0.22, dark.darkened(0.3))
			for i2 in range(10):
				var a2: float = float(i2) * TAU / 10.0
				draw_line(o + Vector2(0.5, 0.5) * s + Vector2(cos(a2), sin(a2)) * s * 0.3, o + Vector2(0.5, 0.5) * s + Vector2(cos(a2), sin(a2)) * s * 0.42, dark, maxf(1.0, s * 0.05))
		"p_spring_jack":
			for i3 in range(4):
				var y0: float = 0.2 + float(i3) * 0.16
				draw_line(o + Vector2(0.25, y0) * s, o + Vector2(0.75, y0 + 0.08) * s, c, maxf(1.5, s * 0.08))
			draw_rect(Rect2(o + Vector2(0.18, 0.84) * s, Vector2(0.64, 0.1) * s), c)
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.5, 0.0) * s, o + Vector2(0.66, 0.16) * s, o + Vector2(0.34, 0.16) * s]), c)
		"p_scout_drone":
			draw_rect(Rect2(o + Vector2(0.36, 0.42) * s, Vector2(0.28, 0.18) * s), c)
			for dx in [0.14, 0.86]:
				draw_line(o + Vector2(0.5, 0.5) * s, o + Vector2(dx, 0.32) * s, c, maxf(1.0, s * 0.05))
				draw_line(o + Vector2(dx - 0.12, 0.3) * s, o + Vector2(dx + 0.12, 0.3) * s, c, maxf(1.5, s * 0.06))
			draw_circle(o + Vector2(0.5, 0.66) * s, s * 0.07, Color("#ff5a3c"))
		# ---- 车间材料(没渲染出像素图标时的备用)：燃素 = 火苗、有机物 = 发芽的豆子、液态负熵 = 水瓶
		"m_red":
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.5, 0.04) * s, o + Vector2(0.78, 0.46) * s, o + Vector2(0.82, 0.7) * s, o + Vector2(0.66, 0.92) * s,
				o + Vector2(0.34, 0.92) * s, o + Vector2(0.18, 0.7) * s, o + Vector2(0.24, 0.48) * s, o + Vector2(0.38, 0.6) * s]), Color("#ff5a1c"))
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.52, 0.42) * s, o + Vector2(0.66, 0.68) * s, o + Vector2(0.6, 0.86) * s, o + Vector2(0.4, 0.86) * s, o + Vector2(0.36, 0.7) * s]), Color("#ffd85a"))
		"m_green":
			draw_line(o + Vector2(0.5, 0.62) * s, o + Vector2(0.52, 0.3) * s, Color("#4aa63a"), maxf(1.5, s * 0.08))
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.52, 0.3) * s, o + Vector2(0.2, 0.16) * s, o + Vector2(0.3, 0.34) * s]), Color("#78cf4e"))
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.52, 0.3) * s, o + Vector2(0.84, 0.14) * s, o + Vector2(0.74, 0.34) * s]), Color("#78cf4e"))
			draw_circle(o + Vector2(0.5, 0.74) * s, s * 0.22, Color("#9c6634"))
		"m_blue":
			draw_rect(Rect2(o + Vector2(0.3, 0.3) * s, Vector2(0.4, 0.64) * s), Color("#5ab4ff"))
			draw_colored_polygon(PackedVector2Array([o + Vector2(0.3, 0.3) * s, o + Vector2(0.42, 0.16) * s, o + Vector2(0.58, 0.16) * s, o + Vector2(0.7, 0.3) * s]), Color("#9ad6ff"))
			draw_rect(Rect2(o + Vector2(0.4, 0.04) * s, Vector2(0.2, 0.12) * s), Color("#2f6fd8"))
			draw_rect(Rect2(o + Vector2(0.3, 0.52) * s, Vector2(0.4, 0.14) * s), Color("#f2f6fa"))
		_:
			draw_circle(o + Vector2(0.5, 0.5) * s, s * 0.4, c)


## 刀剑图标：刃从 hilt 指向 tip，护手垂直于刃
func _blade_icon(o: Vector2, s: float, c: Color, dark: Color, tip: Vector2, hilt: Vector2, half_w: float, guard: float, shift: Vector2 = Vector2.ZERO) -> void:
	var d: Vector2 = (tip - hilt).normalized()
	var n := Vector2(-d.y, d.x)
	var base: Vector2 = o + shift
	draw_colored_polygon(PackedVector2Array([base + tip * s, base + (hilt + n * half_w) * s, base + (hilt - n * half_w) * s]), c)
	draw_line(base + (hilt + n * guard) * s, base + (hilt - n * guard) * s, c.darkened(0.3), maxf(1.6, s * 0.08))
	draw_line(base + hilt * s, base + (hilt - d * 0.2) * s, c.darkened(0.5), maxf(1.6, s * 0.08))
