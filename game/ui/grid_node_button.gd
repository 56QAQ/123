class_name GridNodeButton
extends Control
## 方格网大地图(第一章起)上的节点按钮：浮在十字路口上的切角小方块，中间是类型图标，下面一行小字。
##  · 能去：强调色描边 + 呼吸光晕 + 右下角的行动力花费(不够时变红)
##  · 卡车所在：顶上一个 "HERE" 小旗(商店 / 打输的首领可以再点一次进入)
##  · 未观测：灰色的 "?"；完成：变暗(商店完成后仍然亮着，可以再进)；首领更大、红色
## 悬停时放大，并由 HUD 弹出节点信息卡片；GameRoot 同时在 3D 地图上画出路线。

signal hover_changed(key: String, on: bool)
signal clicked(key: String)

const SIZE := 46.0

var key: String = ""
var kind: String = "unknown"        # 节点类型(未观测 = unknown)
var state: String = "hidden"
var color: Color = Color.WHITE
var cost: int = -1                  # 去那里要花的行动力(-1 = 去不了)
var affordable: bool = false
var here: bool = false
var boss: bool = false
var targeted: bool = false          # 零件选目标模式：这个格点是合法目标
var _hover: bool = false
var _t: float = 0.0
var _glyph: Glyph
var _label: Label
var _cost: Label


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	size = Vector2(SIZE, SIZE)
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	_glyph = Glyph.new()
	_glyph.size = Vector2(28, 28)
	_glyph.position = Vector2(9, 8)
	add_child(_glyph)
	_label = UIKit.label("", 11, UIKit.TEXT, true)
	_label.position = Vector2(-27, SIZE + 1)
	_label.size = Vector2(SIZE + 54, 16)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.outlined(_label, 4)
	add_child(_label)
	_cost = UIKit.num("", 13, UIKit.TEXT)
	_cost.position = Vector2(SIZE - 12, SIZE - 17)
	_cost.size = Vector2(26, 16)
	UIKit.outlined(_cost, 4)
	add_child(_cost)
	mouse_entered.connect(func() -> void:
		_hover = true
		hover_changed.emit(key, true)
		queue_redraw())
	mouse_exited.connect(func() -> void:
		_hover = false
		hover_changed.emit(key, false)
		queue_redraw())


func setup(p_key: String, p_kind: String, p_state: String, p_color: Color, label_text: String, p_cost: int, p_afford: bool, p_here: bool, p_boss: bool) -> void:
	key = p_key
	kind = p_kind
	state = p_state
	color = p_color
	cost = p_cost
	affordable = p_afford
	here = p_here
	boss = p_boss
	var sz: float = SIZE * (1.25 if boss else 1.0)
	custom_minimum_size = Vector2(sz, sz)
	size = Vector2(sz, sz)
	pivot_offset = size * 0.5
	_glyph.size = Vector2(sz * 0.6, sz * 0.6)
	_glyph.position = Vector2(sz * 0.2, sz * 0.18)
	_glyph.kind = "n_" + kind
	var dim: bool = state == "done" and kind != "shop_black" and kind != "shop_parts"
	_glyph.color = Color(color.r, color.g, color.b, 0.45 if dim else 1.0)
	_glyph.queue_redraw()
	_label.text = label_text
	_label.position = Vector2(-27, sz + 1)
	_label.size = Vector2(sz + 54, 16)
	_label.add_theme_color_override("font_color", UIKit.TEXT_DIM if dim or state == "hidden" else UIKit.TEXT)
	_cost.position = Vector2(sz - 12, sz - 17)
	_cost.text = ("-%d" % cost) if cost > 0 else ""
	_cost.add_theme_color_override("font_color", UIKit.ACTION if affordable else UIKit.BAD)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if clickable() else Control.CURSOR_ARROW
	queue_redraw()


func clickable() -> bool:
	if targeted:
		return true
	if here:
		return state != "done" or kind == "shop_black" or kind == "shop_parts"
	return cost > 0 and affordable


func is_hovered() -> bool:
	return _hover


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and (ev as InputEventMouseButton).pressed:
		if clickable():
			clicked.emit(key)
		accept_event()


func _process(dt: float) -> void:
	_t += dt
	var s: float = 1.12 if _hover else 1.0
	scale = scale.lerp(Vector2.ONE * s, clampf(dt * 14.0, 0.0, 1.0))
	if clickable() or here:
		queue_redraw()


func _draw() -> void:
	var sz: float = size.x
	var c: float = sz * 0.22
	var pts := PackedVector2Array([Vector2(c, 0), Vector2(sz, 0), Vector2(sz, sz - c), Vector2(sz - c, sz), Vector2(0, sz), Vector2(0, c)])
	var live: bool = clickable() and not here
	if live or targeted:
		var k: float = 0.5 + 0.5 * sin(_t * 3.6)
		var g: float = 3.0 + 4.0 * k
		var glow: Color = UIKit.ACTION if targeted else (color if affordable else UIKit.BAD)
		draw_rect(Rect2(-g, -g, sz + g * 2.0, sz + g * 2.0), Color(glow.r, glow.g, glow.b, 0.12 + 0.16 * k))
	draw_colored_polygon(PackedVector2Array([pts[0] + Vector2(2, 3), pts[1] + Vector2(2, 3), pts[2] + Vector2(2, 3), pts[3] + Vector2(2, 3), pts[4] + Vector2(2, 3), pts[5] + Vector2(2, 3)]), Color(0, 0, 0, 0.35))
	var bg: Color = UIKit.BG_DEEP
	if state == "hidden":
		bg = Color(bg.r, bg.g, bg.b, 0.75)
	if _hover:
		bg = bg.lightened(0.12)
	draw_colored_polygon(pts, bg)
	var edge: Color = color if state != "hidden" else UIKit.LINE_STRONG
	if state == "done" and kind != "shop_black" and kind != "shop_parts":
		edge = UIKit.TEXT_MUTE
	if targeted:
		edge = UIKit.ACTION
	var closed := PackedVector2Array(pts)
	closed.append(pts[0])
	draw_polyline(closed, edge, 2.0 if (live or here or boss or targeted) else 1.0)
	if here:
		draw_rect(Rect2(0, -15, 44, 13), UIKit.ACCENT)
		draw_string(UIKit.font_caps, Vector2(5, -5), "HERE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UIKit.BG_DEEP)
	if state == "done" and kind != "shop_black" and kind != "shop_parts" and not here:
		draw_line(Vector2(sz * 0.2, sz * 0.8), Vector2(sz * 0.8, sz * 0.2), Color(edge.r, edge.g, edge.b, 0.5), 1.5)
