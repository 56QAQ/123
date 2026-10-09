class_name ItemTile
extends PanelContainer
## 武器库里的一件武器：可拖拽到棋子身上(替换它的武器)。悬停显示武器提示。
## 外观：深色方格 + 左侧武器颜色条 + 真实体素模型图 + 左上颜色点 + 底部费用小菱形。

signal hover_in
signal hover_out
signal clicked                          # 按下又松开、没有拖动 = 点击(固定它的详情提示)

var equip_id: String = ""
var _press_at: Vector2 = Vector2(-1, -1)
var _cat: Catalog
var _base: StyleBoxFlat
var _hot: StyleBoxFlat


func setup(cat: Catalog, id: String) -> void:
	_cat = cat
	equip_id = id
	var e: EquipmentDef = cat.get_equipment(id)
	custom_minimum_size = Vector2(60, 60)
	var col: Color = UIKit.weapon_color(e)
	_base = UIKit.style(UIKit.BG_DEEP, 0, UIKit.BORDER, 1, 2)
	_base.shadow_size = 0
	_base.border_color = col
	_base.border_width_left = 3
	_hot = _base.duplicate()
	_hot.border_color = UIKit.ACCENT
	_hot.set_border_width_all(2)
	_hot.border_width_left = 3
	add_theme_stylebox_override("panel", _base)
	var stack := Control.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stack)
	var g: Control = UIKit.equipment_icon(e, 50.0)
	g.position = Vector2(2, -1)
	g.size = Vector2(50, 50)
	stack.add_child(g)
	var dot: Glyph = UIKit.faction_dot(e.color_id, 11.0)
	dot.position = Vector2(2, 2)
	dot.size = Vector2(11, 11)
	stack.add_child(dot)
	for i in range(e.cost if e.slot != "token" else 0):          # 特殊物品不标稀有度
		var p: Glyph = UIKit.glyph("gem", UIKit.GOLD, 7.0)
		p.position = Vector2(4.0 + float(i) * 8.0, 46.0)
		p.size = Vector2(7, 7)
		stack.add_child(p)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void:
		add_theme_stylebox_override("panel", _hot)
		hover_in.emit())
	mouse_exited.connect(func() -> void:
		add_theme_stylebox_override("panel", _base)
		hover_out.emit())


func _gui_input(ev: InputEvent) -> void:
	var mb := ev as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		_press_at = mb.position
	elif _press_at.x >= 0.0 and mb.position.distance_to(_press_at) < 6.0:
		_press_at = Vector2(-1, -1)
		clicked.emit()


func _get_drag_data(_pos: Vector2) -> Variant:
	_press_at = Vector2(-1, -1)
	set_drag_preview(drag_preview(_cat, equip_id))
	hover_out.emit()
	return {"kind": "equip", "id": equip_id}


## 拖武器时跟着鼠标的小牌子(武器库里拖、详情卡里拖都用它)
static func drag_preview(cat: Catalog, id: String) -> Control:
	var e: EquipmentDef = cat.get_equipment(id)
	var prev := PanelContainer.new()
	var col: Color = UIKit.weapon_color(e)
	var sb: StyleBoxFlat = UIKit.style(UIKit.BG_DEEP, 0, col, 1, 6)
	sb.border_width_left = 3
	prev.add_theme_stylebox_override("panel", sb)
	var h := UIKit.hbox(6)
	h.add_child(UIKit.equipment_icon(e, 36.0))
	h.add_child(UIKit.label(Loc.t("equipment.%s.name" % id), 14, UIKit.TEXT, true))
	prev.add_child(h)
	prev.modulate.a = 0.94
	return prev
