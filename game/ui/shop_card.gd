class_name ShopCard
extends PanelContainer
## 招募卡(商店)：点击购买；也可以拖到场上(卡车四周的格子)或仓库。
## 外观：竖版干员卡——头像铺满上半部，左侧阵营色条，右上费用牌，底部中文名 + 英文名标注 + 阵营/职业/武器大类。

signal clicked(index: int)
signal hover_in
signal hover_out

const W := 132.0
const H := 166.0

var index: int = 0
var def_id: String = ""
var sold: bool = false
var _portrait: Texture2D
var _cat: Catalog
var _base: StyleBoxFlat
var _hot: StyleBoxFlat


func setup(cat: Catalog, p_index: int, p_def: String, p_sold: bool, portrait: Texture2D, gold: int) -> void:
	_cat = cat
	index = p_index
	def_id = p_def
	sold = p_sold
	_portrait = portrait
	var d: UnitDef = cat.get_unit(p_def)
	var fc: Color = GC.faction_color(d.faction_id)
	custom_minimum_size = Vector2(W, H)
	_base = UIKit.style(UIKit.BG_DEEP, 0, UIKit.BORDER, 1, 0)
	_base.shadow_size = 0
	_base.border_color = fc
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
	var tr := TextureRect.new()
	tr.position = Vector2(3, 0)
	tr.size = Vector2(W - 3, 98)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.texture = portrait
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(tr)
	# 阵营色的底部渐变，把头像和信息区接起来
	var grad := TextureRect.new()
	var gt := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(fc.r, fc.g, fc.b, 0.0))
	g.set_color(1, Color(fc.r * 0.35, fc.g * 0.35, fc.b * 0.35, 0.85))
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	grad.texture = gt
	grad.position = Vector2(3, 58)
	grad.size = Vector2(W - 3, 40)
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(grad)
	# 右上：费用牌
	var cost := PanelContainer.new()
	var cs: StyleBoxFlat = UIKit.style(Color(0, 0, 0, 0.72), 0, Color(0, 0, 0, 0), 0, 3)
	cs.shadow_size = 0
	cost.add_theme_stylebox_override("panel", cs)
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ch := UIKit.hbox(2)
	ch.add_child(UIKit.glyph("coin", Color.WHITE, 13.0))
	ch.add_child(UIKit.num(str(d.cost), 17, UIKit.GOLD if gold >= d.cost else UIKit.BAD))
	cost.add_child(ch)
	cost.position = Vector2(W - 44, 0)
	cost.size = Vector2(44, 24)
	stack.add_child(cost)
	# 左上：基础武器大类
	var wb := ColorRect.new()
	wb.color = Color(0, 0, 0, 0.55)
	wb.position = Vector2(3, 0)
	wb.size = Vector2(22, 22)
	wb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(wb)
	var wg: Glyph = UIKit.weapon_glyph(d.base_weapon_class, UIKit.TEXT, 17.0)
	wg.position = Vector2(5, 2)
	wg.size = Vector2(17, 17)
	stack.add_child(wg)
	# 底部信息
	var info := UIKit.vbox(0)
	info.position = Vector2(9, 96)
	info.size = Vector2(W - 14, H - 98)
	var nm: Label = UIKit.label(Loc.t("unit.%s.name" % p_def), 15, UIKit.TEXT, true)
	nm.clip_text = true
	nm.custom_minimum_size = Vector2(W - 16, 0)
	info.add_child(nm)
	var en: Label = UIKit.caption(Loc.t_in("en", "unit.%s.name" % p_def), 9, UIKit.TEXT_DIM)
	en.clip_text = true
	en.custom_minimum_size = Vector2(W - 16, 0)
	info.add_child(en)
	info.add_child(UIKit.spacer(0, 3))
	var tags := UIKit.hbox(4)
	tags.add_child(UIKit.faction_dot(d.faction_id, 12.0))
	tags.add_child(UIKit.label(Loc.t("color." + d.faction_id), 11, UIKit.TEXT_SOFT, true))
	tags.add_child(UIKit.label(Loc.t("profession." + d.profession_id), 11, UIKit.TEXT_DIM))
	info.add_child(tags)
	var tags2 := UIKit.hbox(4)
	tags2.add_child(UIKit.label(Loc.t("role." + d.role), 11, UIKit.TEXT_DIM))
	tags2.add_child(UIKit.label("· " + Loc.t("wclass.%s.name" % d.base_weapon_class), 11, UIKit.TEXT_MUTE))
	info.add_child(tags2)
	stack.add_child(info)
	if sold:
		modulate = Color(1, 1, 1, 0.32)
		var stamp: PanelContainer = UIKit.tag(Loc.t("ui.sold"), UIKit.TEXT, true, 14)
		stamp.position = Vector2(W * 0.5 - 30, 40)
		stack.add_child(stamp)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void:
		if not sold:
			add_theme_stylebox_override("panel", _hot)
			hover_in.emit())
	mouse_exited.connect(func() -> void:
		add_theme_stylebox_override("panel", _base)
		hover_out.emit())


func _gui_input(ev: InputEvent) -> void:
	if sold:
		return
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed:
		if not get_viewport().gui_is_dragging():
			clicked.emit(index)


func _get_drag_data(_pos: Vector2) -> Variant:
	if sold:
		return null
	var prev := PanelContainer.new()
	prev.add_theme_stylebox_override("panel", UIKit.style(UIKit.BG_DEEP, 0, UIKit.ACTION, 2, 2))
	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(90, 64)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.texture = _portrait
	prev.add_child(tr)
	set_drag_preview(prev)
	hover_out.emit()
	return {"kind": "shop", "index": index, "def": def_id}
