class_name StorageCard
extends PanelContainer
## 仓库里的一个节点(卡车货厢的多元空间里，暂不出战)。仓库没有数量上限，横向滚动。
## 外观：竖版干员卡——头像铺满上半部，左侧阵营色条，左上武器大类，右上星级，底部名字；装了武器时右下角显示武器模型图。
## 交互：点击(按下后没有拖动就松开) → 打开详情卡；拖到场上出战；可以接住武器(直接装备)、商店卡(购买)、场上的节点(收纳)。
## roster_id 为空的卡是末尾的"拖到这里收纳"位。

signal hover_in(slot: int)
signal hover_out(slot: int)
signal dropped(slot: int, data: Dictionary)
signal clicked(roster_id: String)

const W := 78.0
const H := 98.0

var slot: int = 0
var roster_id: String = ""
var _mark: ColorRect
var _cat: Catalog
var _press: Vector2 = Vector2(-1, -1)
var _hover: bool = false
var _base: StyleBoxFlat
var _hot: StyleBoxFlat


func setup(cat: Catalog, p_slot: int, u: Dictionary, weapon: EquipmentDef) -> void:
	_cat = cat
	slot = p_slot
	roster_id = str(u.get("id", ""))
	custom_minimum_size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var empty: bool = u.is_empty()
	var d: UnitDef = null if empty else cat.get_unit(str(u["def"]))
	if d != null:
		set_meta("def", d.id)
	_base = UIKit.style(UIKit.BG_DEEP if not empty else Color(0, 0, 0, 0.18), 0, UIKit.BORDER, 1, 0)
	_base.shadow_size = 0
	if empty:
		_base.border_color = UIKit.LINE_STRONG
	else:
		_base.border_color = GC.faction_color(d.faction_id)
		_base.border_width_left = 3
	_hot = _base.duplicate()
	_hot.border_color = UIKit.ACCENT
	_hot.set_border_width_all(2)
	_hot.border_width_left = 3
	add_theme_stylebox_override("panel", _base)
	var stack := Control.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.clip_contents = true
	add_child(stack)
	if empty:
		var v := UIKit.vbox(2)
		v.position = Vector2(4, 24)
		v.size = Vector2(W - 8, 50)
		var plus: Label = UIKit.num("+", 26, UIKit.TEXT_DIM)
		plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(plus)
		var l: Label = UIKit.label(Loc.t("ui.storage_drop"), 11, UIKit.TEXT_DIM)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(W - 8, 0)
		v.add_child(l)
		stack.add_child(v)
	else:
		if UIKit.portraits.has(d.id):
			var tr := TextureRect.new()
			tr.texture = UIKit.portraits[d.id]
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tr.position = Vector2(3, 0)
			tr.size = Vector2(W - 3, 74)
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stack.add_child(tr)
		# 左上：武器大类
		var cls_box := ColorRect.new()
		cls_box.color = Color(0, 0, 0, 0.55)
		cls_box.position = Vector2(3, 0)
		cls_box.size = Vector2(20, 20)
		cls_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(cls_box)
		var wc: String = weapon.class_id if weapon != null else d.base_weapon_class
		var g: Glyph = UIKit.weapon_glyph(wc, UIKit.TEXT, 16.0)
		g.position = Vector2(5, 2)
		g.size = Vector2(16, 16)
		stack.add_child(g)
		# 右上：星级
		var pips: HBoxContainer = UIKit.pips(int(u["star"]), UIKit.GOLD, 10.0)
		pips.position = Vector2(W - 4 - 12.0 * float(u["star"]), 4)
		stack.add_child(pips)
		# 装了(非基础)武器：右下角武器模型图
		if weapon != null and not weapon.basic:
			var wi: Control = UIKit.equipment_icon(weapon, 28.0)
			wi.position = Vector2(W - 30, 46)
			stack.add_child(wi)
		# 底部：名字条
		var band := ColorRect.new()
		band.color = Color(UIKit.BG_DEEP.r, UIKit.BG_DEEP.g, UIKit.BG_DEEP.b, 0.92)
		band.position = Vector2(3, 74)
		band.size = Vector2(W - 3, H - 74)
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(band)
		var nm: Label = UIKit.label(Loc.t("unit.%s.name" % d.id), 12, UIKit.TEXT, true)
		nm.position = Vector2(7, 77)
		nm.size = Vector2(W - 10, 18)
		nm.clip_text = true
		stack.add_child(nm)
	_mark = ColorRect.new()
	_mark.color = Color(0, 0, 0, 0)
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mark.position = Vector2(0, H - 3)
	_mark.size = Vector2(W, 3)
	stack.add_child(_mark)
	mouse_entered.connect(func() -> void:
		_hover = true
		add_theme_stylebox_override("panel", _hot)
		hover_in.emit(slot))
	mouse_exited.connect(func() -> void:
		_hover = false
		add_theme_stylebox_override("panel", _base)
		hover_out.emit(slot))


## QoL 高亮(可装备/同名)：底部一条色带
func set_mark(c: Color) -> void:
	_mark.color = c


func _gui_input(ev: InputEvent) -> void:
	if not (ev is InputEventMouseButton) or (ev as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT:
		return
	var mb := ev as InputEventMouseButton
	if mb.pressed:
		_press = mb.position
	elif _press.x >= 0.0:
		# 真正的点击：按下后没有拖动就松开
		if mb.position.distance_to(_press) < 8.0 and not get_viewport().gui_is_dragging() and roster_id != "":
			clicked.emit(roster_id)
		_press = Vector2(-1, -1)


func _get_drag_data(_pos: Vector2) -> Variant:
	_press = Vector2(-1, -1)
	if roster_id == "":
		return null
	var prev := PanelContainer.new()
	var sb: StyleBoxFlat = UIKit.style(UIKit.BG_DEEP, 0, UIKit.ACCENT, 2, 2)
	prev.add_theme_stylebox_override("panel", sb)
	var def_id: String = str(get_meta("def", ""))
	if UIKit.portraits.has(def_id):
		var tr := TextureRect.new()
		tr.texture = UIKit.portraits[def_id]
		tr.custom_minimum_size = Vector2(80, 60)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		prev.add_child(tr)
	set_drag_preview(prev)
	hover_out.emit(slot)
	return {"kind": "roster", "id": roster_id}


func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	if not (data is Dictionary):
		return false
	var k: String = str((data as Dictionary).get("kind", ""))
	if k == "roster":
		return str((data as Dictionary).get("id", "")) != roster_id
	if k == "equip":
		return roster_id != ""
	return k == "shop"


func _drop_data(_pos: Vector2, data: Variant) -> void:
	dropped.emit(slot, data as Dictionary)
