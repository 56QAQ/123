class_name Stripes
extends Control
## 警示斜纹(装饰)：一组 45° 平行斜条，裁在自身矩形里。

var color: Color = Color(1, 1, 1, 0.2)
var step: float = 7.0
var width: float = 3.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func _draw() -> void:
	var h: float = size.y
	var box := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, h)])
	var x: float = -h
	while x < size.x:
		var pts := PackedVector2Array([Vector2(x, h), Vector2(x + width, h), Vector2(x + width + h, 0), Vector2(x + h, 0)])
		for poly: PackedVector2Array in Geometry2D.intersect_polygons(pts, box):
			if poly.size() >= 3:
				draw_colored_polygon(poly, color)
		x += step


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
