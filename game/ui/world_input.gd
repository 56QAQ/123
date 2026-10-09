class_name WorldInput
extends Control
## 铺满屏幕、位于 HUD 之下的输入层：把鼠标事件转给 GameRoot(拾取棋子/格子、拖拽、相机)，
## 同时作为 Godot 拖放(商店卡/装备)的落点。

signal moved(pos: Vector2, rel: Vector2, buttons: int)
signal pressed(pos: Vector2, button: int)
signal released(pos: Vector2, button: int)
signal wheel(pos: Vector2, dir: int)
signal drop_hover(pos: Vector2, data: Variant)
signal dropped(pos: Vector2, data: Variant)

var can_drop_cb: Callable


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		moved.emit(ev.position, ev.relative, ev.button_mask)
	elif ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP and ev.pressed:
			wheel.emit(ev.position, -1)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN and ev.pressed:
			wheel.emit(ev.position, 1)
		elif ev.pressed:
			pressed.emit(ev.position, ev.button_index)
		else:
			released.emit(ev.position, ev.button_index)


func _can_drop_data(pos: Vector2, data: Variant) -> bool:
	drop_hover.emit(pos, data)
	if can_drop_cb.is_valid():
		return bool(can_drop_cb.call(pos, data))
	return false


func _drop_data(pos: Vector2, data: Variant) -> void:
	dropped.emit(pos, data)
