class_name DropPanel
extends PanelContainer
## 可以接住拖放的面板(用回调判断/处理)，例如：把货厢里的节点拖到底部面板 = 出售。

var can_drop_cb: Callable = Callable()
var drop_cb: Callable = Callable()


func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return can_drop_cb.is_valid() and bool(can_drop_cb.call(data))


func _drop_data(_pos: Vector2, data: Variant) -> void:
	if drop_cb.is_valid():
		drop_cb.call(data)
