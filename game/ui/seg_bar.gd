class_name SegBar
extends Control
## 分段进度条(卡车耐久/经验)：一格一格的小块，未满的格子是暗底。

var segments: int = 10
var fill: Color = Color.WHITE
var back: Color = Color(1, 1, 1, 0.1)
var max_value: float = 1.0:
	set(v):
		max_value = v
		queue_redraw()
var value: float = 1.0:
	set(v):
		value = v
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var n: int = maxi(1, segments)
	var gap := 2.0
	var w: float = (size.x - gap * float(n - 1)) / float(n)
	var frac: float = clampf(value / maxf(0.0001, max_value), 0.0, 1.0) * float(n)
	for i in range(n):
		var r := Rect2(float(i) * (w + gap), 0, w, size.y)
		draw_rect(r, back)
		var f: float = clampf(frac - float(i), 0.0, 1.0)
		if f > 0.0:
			draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), fill)
