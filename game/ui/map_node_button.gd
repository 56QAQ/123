class_name MapNodeButton
extends Control
## 大地图上的地图节点按钮(关卡牌样式，浮在节点石台上)：左侧编号 "0-1"，右侧类型图标 + 中文类型 + 英文标注。
##  · 下一站：强调色边条 + 呼吸光晕 + 顶部 "NEXT" 小旗，可以点击出发
##  · 已通过：暗色 + 对勾；未到达：白色细边，只能悬停看信息
## 悬停时放大，并由 HUD 弹出节点信息卡片。

signal hover_changed(index: int, on: bool)
signal clicked(index: int)

const W := 150.0
const H := 50.0

var index: int = 0
var status: String = "later"         # done / next / later
var icon: String = "gem"
var icon_color: Color = Color.WHITE
var code: String = ""
var _hover: bool = false
var _t: float = 0.0
var _glyph: Glyph
var _check: Glyph
var _code: Label
var _type: Label
var _type_en: Label


func _init() -> void:
	custom_minimum_size = Vector2(W, H)
	size = Vector2(W, H)
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	_code = UIKit.num("", 24, UIKit.TEXT)
	_code.position = Vector2(10, 0)
	_code.size = Vector2(52, H)
	_code.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_code)
	_glyph = Glyph.new()
	_glyph.size = Vector2(20, 20)
	_glyph.position = Vector2(66, 15)
	add_child(_glyph)
	_type = UIKit.label("", 13, UIKit.TEXT, true)
	_type.position = Vector2(92, 6)
	_type.size = Vector2(56, 20)
	add_child(_type)
	_type_en = UIKit.caption("", 9, UIKit.TEXT_DIM)
	_type_en.position = Vector2(92, 26)
	_type_en.size = Vector2(56, 16)
	add_child(_type_en)
	_check = Glyph.new()
	_check.kind = "check"
	_check.color = UIKit.GOOD
	_check.size = Vector2(18, 18)
	_check.position = Vector2(W - 20, 2)
	add_child(_check)
	mouse_entered.connect(func() -> void:
		_hover = true
		hover_changed.emit(index, true)
		queue_redraw())
	mouse_exited.connect(func() -> void:
		_hover = false
		hover_changed.emit(index, false)
		queue_redraw())


func setup(p_index: int, p_status: String, p_icon: String, p_icon_color: Color, p_code: String, type_cn: String, type_en: String) -> void:
	index = p_index
	status = p_status
	icon = p_icon
	icon_color = p_icon_color
	code = p_code
	_glyph.kind = icon
	var dim: bool = status == "done"
	_glyph.color = Color(icon_color.r, icon_color.g, icon_color.b, 0.45 if dim else 1.0)
	_glyph.queue_redraw()
	_check.visible = dim
	_code.text = code
	_code.add_theme_color_override("font_color", UIKit.TEXT_DIM if dim else UIKit.TEXT)
	_type.text = type_cn
	_type.add_theme_color_override("font_color", UIKit.TEXT_DIM if dim else UIKit.TEXT)
	_type_en.text = type_en.to_upper()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if status == "next" else Control.CURSOR_ARROW
	queue_redraw()


func is_hovered() -> bool:
	return _hover


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and (ev as InputEventMouseButton).pressed:
		if status == "next":
			clicked.emit(index)
		accept_event()


func _process(dt: float) -> void:
	_t += dt
	var s: float = 1.08 if _hover else 1.0
	scale = scale.lerp(Vector2.ONE * s, clampf(dt * 14.0, 0.0, 1.0))
	if status == "next":
		queue_redraw()


func _draw() -> void:
	var next: bool = status == "next"
	var done: bool = status == "done"
	var strip: Color = UIKit.ACCENT if next else (UIKit.TEXT_MUTE if done else UIKit.LINE_STRONG)
	if next:
		var k: float = 0.5 + 0.5 * sin(_t * 3.4)
		var g: float = 4.0 + 4.0 * k
		draw_rect(Rect2(-g, -g, W + g * 2.0, H + g * 2.0), Color(UIKit.ACCENT.r, UIKit.ACCENT.g, UIKit.ACCENT.b, 0.14 + 0.14 * k))
		# 顶部小旗 "NEXT"
		draw_rect(Rect2(0, -15, 44, 13), UIKit.ACCENT)
		draw_string(UIKit.font_caps, Vector2(5, -5), "NEXT", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UIKit.BG_DEEP)
		# 快捷键 SPACE
		draw_rect(Rect2(48, -15, 46, 13), Color(0.02, 0.022, 0.03, 0.8))
		draw_rect(Rect2(48, -15, 46, 13), Color(1, 1, 1, 0.38), false, 1.0)
		draw_string(UIKit.font_num, Vector2(53, -4), "SPACE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#f2f3f5"))
	draw_rect(Rect2(2, 4, W, H), Color(0, 0, 0, 0.3))
	var bg: Color = UIKit.BG_DEEP if not done else Color(UIKit.BG.r, UIKit.BG.g, UIKit.BG.b, 0.82)
	if _hover:
		bg = bg.lightened(0.1)
	draw_rect(Rect2(0, 0, W, H), bg)
	draw_rect(Rect2(0, 0, W, H), UIKit.ACCENT if _hover else UIKit.BORDER, false, 1.0)
	draw_rect(Rect2(0, 0, 4, H), strip)
	draw_line(Vector2(60, 9), Vector2(60, H - 9), UIKit.BORDER, 1.0)
