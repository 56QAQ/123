class_name ArkPanel
extends PanelContainer
## 战术终端风格的面板：底色/切角/描边来自 StyleBox(UIKit.style)，这里再画强调色条与角标。
##   edge = "left"：左侧一条 3px 强调色；"top"：顶部一条细线 + 左端一小段粗块；"" = 不画
##   corners = true：右上/左下画 L 形角标

var edge: String = "left"
var accent: Color = Color.WHITE
var corners: bool = false


func _draw() -> void:
	var s: Vector2 = size
	match edge:
		"left":
			draw_rect(Rect2(0, 0, 3, s.y), accent)
		"top":
			draw_rect(Rect2(0, 0, s.x, 1), Color(accent.r, accent.g, accent.b, 0.55))
			draw_rect(Rect2(0, 0, minf(64.0, s.x * 0.3), 3), accent)
	if corners:
		var c: Color = UIKit.LINE_STRONG
		var k := 10.0
		draw_line(Vector2(s.x - k, 1), Vector2(s.x - 1, 1), c, 1.5)
		draw_line(Vector2(s.x - 1, 1), Vector2(s.x - 1, k), c, 1.5)
		draw_line(Vector2(1, s.y - k), Vector2(1, s.y - 1), c, 1.5)
		draw_line(Vector2(1, s.y - 1), Vector2(k, s.y - 1), c, 1.5)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
