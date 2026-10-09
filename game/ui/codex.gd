class_name Codex
extends Control
## 图鉴(资料库)：只收录按新设计重构过的内容(UnitDef / EquipmentDef.reworked)。四个分页：节点 / 武器 / 羁绊 / 关键词。
## 左边是条目列表；右边是详情——节点与武器有一个能拖着转的 3D 展台(真实模型 + 待机动作，武器由它的主人拿着，
## 可以切换 待机 / 小动作 / 胜利 / 攻击)，旁边是和游戏里一样的详情卡(节点能切星级、切基础/专属武器)；
## 关键词显示说明，以及"出现在哪些内容里"(点一下跳过去)。整页由代码构建，颜色全走 UIKit 语义色。

signal closed

const TABS := [["units", "ui.codex.tab_units", "NODES"], ["weapons", "ui.codex.tab_weapons", "WEAPONS"],
	["traits", "ui.codex.tab_traits", "TRAITS"], ["keywords", "ui.codex.tab_keywords", "KEYWORDS"]]
const LIST_W := 400.0
const STAGE_W := 560.0

var cat: Catalog
var tab: String = "units"
var sel: String = ""
var star: int = 1
var use_exclusive: bool = true
var pose: String = "idle"

var _tab_buttons: Dictionary = {}
var _list: VBoxContainer
var _list_scroll: ScrollContainer
var _entry_buttons: Dictionary = {}
var _stage_panel: Control
var _stage_hint: Label
var _stage_vp: SubViewport
var _pivot: Node3D
var _view: UnitView
var _info_scroll: ScrollContainer
var _info: VBoxContainer
var _yaw: float = -24.0
var _spin: bool = true
var _dragging: bool = false
var _kw_cache: Array = []


func setup(p_cat: Catalog) -> void:
	cat = p_cat
	_kw_cache = _gather_keywords()


func _ready() -> void:
	UIKit.ensure()
	theme = UIKit.theme()
	process_mode = Node.PROCESS_MODE_ALWAYS          # 暂停菜单里打开时展台照样转、照样动
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var o: Color = UIKit.OVERLAY
	bg.color = Color(o.r, o.g, o.b, 0.93)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_build_header()
	_build_body()
	select_tab("units")


# ---------------------------------------------------------------- 条目数据
func units() -> Array[String]:
	var r: Array[String] = []
	for id: String in cat.units.keys():
		var d: UnitDef = cat.get_unit(id)
		if d.reworked:
			r.append(id)
	r.sort_custom(func(a: String, b: String) -> bool:
		var da: UnitDef = cat.get_unit(a)
		var db: UnitDef = cat.get_unit(b)
		return da.cost < db.cost if da.cost != db.cost else Loc.t("unit.%s.name" % a) < Loc.t("unit.%s.name" % b))
	return r


func weapons() -> Array[String]:
	var r: Array[String] = []
	for id: String in cat.equipment.keys():
		var e: EquipmentDef = cat.get_equipment(id)
		if e.reworked:
			r.append(id)
	r.sort_custom(func(a: String, b: String) -> bool:
		var ea: EquipmentDef = cat.get_equipment(a)
		var eb: EquipmentDef = cat.get_equipment(b)
		return ea.cost < eb.cost if ea.cost != eb.cost else a < b)
	return r


## 重构过的羁绊(羁绊还没开始重构：先留空)
func traits() -> Array[String]:
	return []


## 关键词与结算规则：只收录重构过的内容里真正出现的(节点被动、节点武器大类的普攻关键词、武器效果)
func keywords() -> Array[String]:
	var r: Array[String] = []
	for k: Dictionary in _kw_cache:
		r.append(str(k["id"]))
	return r


func _gather_keywords() -> Array:
	var found: Dictionary = {}          # id -> {id, kind, uses:[{tab, id, where}]}
	var order: Array[String] = []
	var add := func(kid: String, kind: String, use: Dictionary) -> void:
		if not found.has(kid):
			found[kid] = {"id": kid, "kind": kind, "uses": []}
			order.append(kid)
		for u0: Dictionary in found[kid]["uses"]:
			if u0["tab"] == use["tab"] and u0["id"] == use["id"] and u0["where"] == use["where"]:
				return
		(found[kid]["uses"] as Array).append(use)
	for uid: String in units():
		var d: UnitDef = cat.get_unit(uid)
		for pa: AbilityDef in d.passives:
			var where: String = _bold_name(Loc.t("unit.%s.passive.%s" % [uid, pa.id]))
			for k: String in pa.keywords:
				if k != "normal_attack" and Loc.has_key("keyword." + k):
					add.call("kw:" + k, "keyword", {"tab": "units", "id": uid, "where": where})
		var nk: Dictionary = GC.weapon_class(d.base_weapon_class).get("na_keywords", {})
		for k2: String in nk.keys():
			add.call("kw:" + k2, "keyword", {"tab": "units", "id": uid, "where": Loc.t("wclass.%s.name" % d.base_weapon_class)})
	for eid: String in weapons():
		var e: EquipmentDef = cat.get_equipment(eid)
		for a: AbilityDef in e.abilities:
			add.call("rule:" + a.ability_class, "rule", {"tab": "weapons", "id": eid, "where": Loc.t("ui.codex.payload")})
			for xr: Variant in a.effect_config.get("extra_rules", []):
				add.call("rule:" + str(xr), "rule", {"tab": "weapons", "id": eid, "where": Loc.t("ui.codex.payload")})
			for k3: String in a.keywords:
				if k3 != "normal_attack" and Loc.has_key("keyword." + k3):
					add.call("kw:" + k3, "keyword", {"tab": "weapons", "id": eid, "where": Loc.t("ui.codex.payload")})
	var r: Array = []
	for kid2: String in order:
		r.append(found[kid2])
	return r


static func _bold_name(t: String) -> String:
	var i: int = t.find("[b]")
	var j: int = t.find("[/b]")
	if i >= 0 and j > i:
		return t.substr(i + 3, j - i - 3)
	return t.left(12)


func _kw_entry(kid: String) -> Dictionary:
	for k: Dictionary in _kw_cache:
		if str(k["id"]) == kid:
			return k
	return {}


func _kw_name(kid: String) -> String:
	var kind_id: String = kid.split(":")[1]
	return Loc.t("class." + kind_id) if kid.begins_with("rule:") else Loc.t("keyword." + kind_id)


func _kw_desc(kid: String) -> String:
	var kind_id: String = kid.split(":")[1]
	return Loc.t("classrule." + kind_id) if kid.begins_with("rule:") else Loc.t("keyword_desc." + kind_id)


func exclusive_of(unit_id: String) -> String:
	for eid: String in weapons():
		if cat.get_equipment(eid).owner == unit_id:
			return eid
	return ""


# ---------------------------------------------------------------- 顶栏
func _build_header() -> void:
	var head := UIKit.vbox(2)
	head.position = Vector2(64, 36)
	add_child(head)
	head.add_child(UIKit.caption("Archive · Hyperdimensional Workshop", 13, UIKit.ACCENT))
	var row := UIKit.hbox(18)
	row.add_child(UIKit.label(Loc.t("ui.codex.title"), 46, UIKit.TEXT, true))
	var st := Stripes.new()
	st.color = UIKit.ACTION
	st.custom_minimum_size = Vector2(90, 12)
	st.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(st)
	var sub: Label = UIKit.label(Loc.t("ui.codex.subtitle"), 15, UIKit.TEXT_DIM)
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(sub)
	head.add_child(row)
	var close: Button = UIKit.button(Loc.t("ui.codex.close"), "normal", Vector2(150, 44))
	close.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close.offset_left = -214
	close.offset_right = -64
	close.offset_top = 48
	close.offset_bottom = 92
	close.pressed.connect(close_codex)
	add_child(close)
	UIKit.add_key_hint(close, "Esc")
	# 分页
	var tabs := UIKit.hbox(6)
	tabs.position = Vector2(64, 138)
	add_child(tabs)
	for tdef: Array in TABS:
		var tid: String = tdef[0]
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(196, 58)
		b.pressed.connect(select_tab.bind(tid))
		var hb := UIKit.hbox(10)
		hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hb.offset_left = 16
		hb.offset_right = -14
		var v := UIKit.vbox(-2)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(UIKit.label(Loc.t(str(tdef[1])), 19, UIKit.TEXT, true))
		v.add_child(UIKit.caption(str(tdef[2]), 10, UIKit.TEXT_DIM))
		hb.add_child(v)
		hb.add_child(UIKit.spacer(0, 0, true))
		var n: Label = UIKit.num("%02d" % _count_of(tid), 22, UIKit.TEXT_MUTE)
		n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(n)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(hb)
		tabs.add_child(b)
		_tab_buttons[tid] = b


func _count_of(tid: String) -> int:
	match tid:
		"units":
			return units().size()
		"weapons":
			return weapons().size()
		"traits":
			return traits().size()
		_:
			return keywords().size()


func _style_tab(b: Button, on: bool) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(UIKit.BG.r, UIKit.BG.g, UIKit.BG.b, 0.96) if on else Color(UIKit.BG_DEEP.r, UIKit.BG_DEEP.g, UIKit.BG_DEEP.b, 0.7)
	n.border_color = UIKit.ACCENT if on else UIKit.BORDER
	n.border_width_bottom = 4 if on else 1
	n.border_width_top = 0
	var h := n.duplicate() as StyleBoxFlat
	h.border_color = UIKit.ACCENT
	for k: String in ["normal", "pressed", "focus"]:
		b.add_theme_stylebox_override(k, n)
	b.add_theme_stylebox_override("hover", h)


# ---------------------------------------------------------------- 主体：列表 | 展台 | 详情
func _build_body() -> void:
	var body := UIKit.hbox(16)
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 64
	body.offset_right = -64
	body.offset_top = 214
	body.offset_bottom = -44
	add_child(body)
	# 列表
	var lp: ArkPanel = UIKit.ark_panel(10, "top", 12, UIKit.BG_DEEP)
	lp.custom_minimum_size = Vector2(LIST_W, 0)
	body.add_child(lp)
	_list_scroll = ScrollContainer.new()
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lp.add_child(_list_scroll)
	_list = UIKit.vbox(6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_scroll.add_child(_list)
	# 展台
	var sp: ArkPanel = UIKit.ark_panel(6, "top", 12, UIKit.BG_DEEP)
	sp.custom_minimum_size = Vector2(STAGE_W, 0)
	body.add_child(sp)
	_stage_panel = sp
	var sv := UIKit.vbox(6)
	sp.add_child(sv)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	svc.custom_minimum_size = Vector2(STAGE_W - 12, 560)
	svc.mouse_filter = Control.MOUSE_FILTER_STOP
	svc.gui_input.connect(_on_stage_input)
	sv.add_child(svc)
	_stage_vp = _make_stage()
	svc.add_child(_stage_vp)
	var poses := UIKit.hbox(6)
	poses.alignment = BoxContainer.ALIGNMENT_CENTER
	for pz: Array in [["idle", "ui.codex.pose_idle"], ["fidget", "ui.codex.pose_fidget"], ["victory", "ui.codex.pose_victory"], ["attack", "ui.codex.pose_attack"]]:
		var pb: Button = UIKit.button(Loc.t(str(pz[1])), "ghost", Vector2(118, 36))
		pb.pressed.connect(_set_pose.bind(str(pz[0])))
		poses.add_child(pb)
	sv.add_child(poses)
	_stage_hint = UIKit.caption(Loc.t("ui.codex.drag_hint"), 11, UIKit.TEXT_MUTE)
	_stage_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sv.add_child(_stage_hint)
	# 详情
	var ip: ArkPanel = UIKit.ark_panel(14, "top", 12, UIKit.BG_DEEP)
	ip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(ip)
	_info_scroll = ScrollContainer.new()
	_info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ip.add_child(_info_scroll)
	_info = UIKit.vbox(10)
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_scroll.add_child(_info)


## 展台：自己的 3D 世界(不画游戏场景)、透明底；一个深色圆台 + 强调色细环，模型站在上面
func _make_stage() -> SubViewport:
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#efe6dc")
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -40, 0)
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	vp.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, 130, 0)
	fill.light_energy = 0.45
	fill.light_color = Color("#cfe0ff")
	vp.add_child(fill)
	var cam := Camera3D.new()
	cam.fov = 26.0
	vp.add_child(cam)
	# 还不在场景树里，look_at 用不了：直接给变换
	var cpos := Vector3(0.0, 1.35, 4.1)
	cam.transform = Transform3D(Basis.looking_at(Vector3(0.0, 0.74, 0.0) - cpos, Vector3.UP), cpos)
	# 圆台
	var ped := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.54
	cm.height = 0.08
	cm.radial_segments = 40
	ped.mesh = cm
	var pm := StandardMaterial3D.new()
	pm.albedo_color = UIKit.BG.darkened(0.2)
	pm.roughness = 0.8
	ped.material_override = pm
	ped.position = Vector3(0, -0.04, 0)
	vp.add_child(ped)
	var ringm := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.485
	tm.outer_radius = 0.51
	tm.rings = 48
	ringm.mesh = tm
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = UIKit.ACCENT
	ringm.material_override = rm
	ringm.position = Vector3(0, 0.005, 0)
	ringm.scale = Vector3(1, 0.3, 1)
	vp.add_child(ringm)
	_pivot = Node3D.new()
	vp.add_child(_pivot)
	return vp


func _on_stage_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_dragging = (ev as InputEventMouseButton).pressed
		if _dragging:
			_spin = false
	elif ev is InputEventMouseMotion and _dragging:
		_yaw += (ev as InputEventMouseMotion).relative.x * 0.6


func _process(delta: float) -> void:
	if _spin:
		_yaw += delta * 14.0
	if _pivot != null:
		_pivot.rotation.y = deg_to_rad(_yaw)


func _set_pose(p: String) -> void:
	pose = p
	if _view != null:
		_view.showcase(p)


## 展台上换人(unit_id = "" 时清空)
func _show_model(unit_id: String, weapon_id: String) -> void:
	if _view != null:
		_view.queue_free()
		_view = null
	if unit_id == "":
		return
	var d: UnitDef = cat.get_unit(unit_id)
	_view = UnitView.new()
	_pivot.add_child(_view)
	_view.setup(d, star, 0, false, cat.resolve_weapon(d, weapon_id))
	_view.set_bar_visible(false)
	_view.set_team_ring_visible(false)
	_view.showcase(pose if pose != "attack" else "idle")


# ---------------------------------------------------------------- 分页 / 列表
func select_tab(tid: String) -> void:
	tab = tid
	for k: String in _tab_buttons.keys():
		_style_tab(_tab_buttons[k] as Button, k == tid)
	for c: Node in _list.get_children():
		c.queue_free()
	_entry_buttons.clear()
	var ids: Array[String] = []
	match tid:
		"units":
			ids = units()
		"weapons":
			ids = weapons()
		"traits":
			ids = traits()
		_:
			ids = keywords()
	if ids.is_empty():
		_list.add_child(UIKit.spacer(0, 12))
		var el: Label = UIKit.label(Loc.t("ui.codex.empty_" + tid) if Loc.has_key("ui.codex.empty_" + tid) else Loc.t("ui.codex.empty"), 14, UIKit.TEXT_DIM)
		el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		el.custom_minimum_size = Vector2(LIST_W - 40, 0)
		_list.add_child(el)
		_stage_panel.visible = false
		_clear_info()
		var box := UIKit.vbox(8)
		box.add_child(UIKit.section(Loc.t("ui.codex.tab_" + tid), str(TABS[_tab_index(tid)][2])))
		box.add_child(UIKit.rich("[color=%s]%s[/color]" % [UIKit.hx(UIKit.TEXT_DIM), Loc.t("ui.codex.empty_" + tid) if Loc.has_key("ui.codex.empty_" + tid) else Loc.t("ui.codex.empty")], 15, 700))
		_info.add_child(box)
		sel = ""
		return
	for id: String in ids:
		var b: Button = _entry_button(id)
		_list.add_child(b)
		_entry_buttons[id] = b
	select_entry(ids[0])


func _tab_index(tid: String) -> int:
	for i in range(TABS.size()):
		if TABS[i][0] == tid:
			return i
	return 0


func _entry_button(id: String) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(LIST_W - 28, 78 if tab != "keywords" else 58)
	b.pressed.connect(select_entry.bind(id))
	var row := UIKit.hbox(12)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 10
	row.offset_right = -12
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	var v := UIKit.vbox(1)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match tab:
		"units":
			var d: UnitDef = cat.get_unit(id)
			var pt: Control = UIKit.portrait(id, Vector2(92, 62), d.faction_id)
			pt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(pt)
			v.add_child(UIKit.label(Loc.t("unit.%s.name" % id), 18, UIKit.TEXT, true))
			v.add_child(UIKit.caption(Loc.t_in("en", "unit.%s.name" % id), 10, GC.faction_color(d.faction_id)))
			var tg := UIKit.hbox(4)
			tg.add_child(UIKit.tag(Loc.t("color." + d.faction_id), GC.faction_color(d.faction_id), false, 11))
			tg.add_child(UIKit.tag(Loc.t("role." + d.role), UIKit.TEXT_DIM, false, 11))
			v.add_child(tg)
			row.add_child(v)
			var pp: Control = UIKit.pips(d.cost, UIKit.GOLD, 9.0)
			pp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(pp)
		"weapons":
			var e: EquipmentDef = cat.get_equipment(id)
			var ic: Control = UIKit.equipment_icon(e, 60.0)
			ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(ic)
			v.add_child(UIKit.label(Loc.t("equipment.%s.name" % id), 18, UIKit.TEXT, true))
			v.add_child(UIKit.caption(Loc.t_in("en", "equipment.%s.name" % id), 10, UIKit.ACCENT))
			var tg2 := UIKit.hbox(4)
			tg2.add_child(UIKit.tag(Loc.t("wclass.%s.name" % e.class_id), UIKit.TEXT_DIM, false, 11))
			tg2.add_child(UIKit.tag(Loc.t("color." + e.color_id), GC.faction_color(e.color_id), false, 11))
			v.add_child(tg2)
			row.add_child(v)
			var pp2: Control = UIKit.pips(e.cost, UIKit.GOLD, 9.0)
			pp2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(pp2)
		_:
			var k: Dictionary = _kw_entry(id)
			var is_rule: bool = str(k.get("kind", "")) == "rule"
			v.add_child(UIKit.label(_kw_name(id), 17, UIKit.KEYWORD, true))
			v.add_child(UIKit.caption(("Rule · " if is_rule else "Keyword · ") + Loc.t_in("en", ("class." if is_rule else "keyword.") + id.split(":")[1]), 10, UIKit.TEXT_DIM))
			row.add_child(v)
			var n: Label = UIKit.num("%d" % (k.get("uses", []) as Array).size(), 18, UIKit.TEXT_MUTE)
			n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(n)
	return b


func _style_entry(b: Button, on: bool) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(UIKit.BG.r, UIKit.BG.g, UIKit.BG.b, 0.95) if on else Color(UIKit.BG_SOFT.r, UIKit.BG_SOFT.g, UIKit.BG_SOFT.b, 0.35)
	n.border_color = UIKit.ACCENT if on else UIKit.BORDER
	n.border_width_left = 5 if on else 1
	n.border_width_bottom = 1
	var h := n.duplicate() as StyleBoxFlat
	h.border_color = UIKit.ACCENT
	h.border_width_left = 5
	for k: String in ["normal", "pressed", "focus"]:
		b.add_theme_stylebox_override(k, n)
	b.add_theme_stylebox_override("hover", h)


func select_entry(id: String) -> void:
	sel = id
	for k: String in _entry_buttons.keys():
		_style_entry(_entry_buttons[k] as Button, k == id)
	_refresh_detail()


## 跳到别的分页的某个条目(关键词的"出现在"、武器的"专属")
func jump(tid: String, id: String) -> void:
	select_tab(tid)
	if _entry_buttons.has(id):
		select_entry(id)


# ---------------------------------------------------------------- 详情
func _clear_info() -> void:
	for c: Node in _info.get_children():
		c.queue_free()


func _refresh_detail() -> void:
	_clear_info()
	match tab:
		"units":
			_stage_panel.visible = true
			var wid: String = exclusive_of(sel) if use_exclusive else ""
			_show_model(sel, wid)
			_unit_detail(sel, wid)
		"weapons":
			_stage_panel.visible = true
			var e: EquipmentDef = cat.get_equipment(sel)
			var holder: String = e.owner
			if holder == "" and not cat.fit_units(sel).is_empty():
				holder = cat.fit_units(sel)[0]          # 通用武器没有主人：拿在第一只适配角色手里展示
			_show_model(holder, sel)
			_weapon_detail(e)
		_:
			_stage_panel.visible = false
			_show_model("", "")
			_keyword_detail(sel)


func _toggle(text: String, on: bool, cb: Callable, w: float = 86.0) -> Button:
	var b: Button = UIKit.button(text, "accent" if on else "ghost", Vector2(w, 36))
	b.pressed.connect(cb)
	return b


func _unit_detail(uid: String, wid: String) -> void:
	var d: UnitDef = cat.get_unit(uid)
	var ctl := UIKit.hbox(8)
	ctl.add_child(UIKit.label(Loc.t("ui.codex.star"), 13, UIKit.TEXT_DIM))
	for s: int in [1, 2, 3]:
		ctl.add_child(_toggle("★".repeat(s), s == star, func() -> void:
			star = s
			_refresh_detail()))
	ctl.add_child(UIKit.spacer(18, 0))
	ctl.add_child(UIKit.label(Loc.t("ui.codex.weapon"), 13, UIKit.TEXT_DIM))
	ctl.add_child(_toggle(Loc.t("ui.codex.weapon_basic"), not use_exclusive, func() -> void:
		use_exclusive = false
		_refresh_detail(), 110.0))
	var ex: String = exclusive_of(uid)
	if ex != "":
		ctl.add_child(_toggle(Loc.t("equipment.%s.name" % ex), use_exclusive, func() -> void:
			use_exclusive = true
			_refresh_detail(), 130.0))
	_info.add_child(ctl)
	var cols := UIKit.hbox(18)
	cols.add_child(TipContent.unit_card(cat, d, star, wid))
	# 右列：专属武器速览 + 这个节点用到的关键词(点一下跳过去)
	var side := UIKit.vbox(8)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if ex != "":
		side.add_child(UIKit.section(Loc.t("ui.codex.exclusive_weapon"), "EXCLUSIVE"))
		var er := UIKit.hbox(10)
		er.add_child(UIKit.equipment_icon(cat.get_equipment(ex), 56.0))
		var ev := UIKit.vbox(2)
		ev.add_child(UIKit.label(Loc.t("equipment.%s.name" % ex), 17, UIKit.TEXT, true))
		var jb: Button = UIKit.button(Loc.t("ui.codex.open_entry"), "ghost", Vector2(120, 32))
		jb.pressed.connect(jump.bind("weapons", ex))
		ev.add_child(jb)
		er.add_child(ev)
		side.add_child(er)
		side.add_child(UIKit.spacer(0, 6))
	_keyword_links(side, "units", uid)
	cols.add_child(side)
	_info.add_child(cols)


## 这个条目用到的关键词/结算规则：一排可点击的小按钮
func _keyword_links(parent: Control, tid: String, id: String) -> void:
	var ks: Array[String] = []
	for k: Dictionary in _kw_cache:
		for u: Dictionary in k["uses"]:
			if str(u["tab"]) == tid and str(u["id"]) == id and not ks.has(str(k["id"])):
				ks.append(str(k["id"]))
	if ks.is_empty():
		return
	parent.add_child(UIKit.section(Loc.t("ui.codex.tab_keywords"), "KEYWORDS"))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	flow.custom_minimum_size = Vector2(320, 0)
	for kid: String in ks:
		var b: Button = UIKit.button(("〔%s〕" if kid.begins_with("rule:") else "【%s】") % _kw_name(kid), "ghost", Vector2(0, 34))
		b.add_theme_color_override("font_color", UIKit.KEYWORD)
		b.pressed.connect(jump.bind("keywords", kid))
		flow.add_child(b)
	parent.add_child(flow)


func _weapon_detail(e: EquipmentDef) -> void:
	var cols := UIKit.hbox(18)
	cols.add_child(TipContent.equipment_tip(cat, e.id))
	var side := UIKit.vbox(8)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if e.owner != "":
		side.add_child(UIKit.section(Loc.t("ui.codex.owner"), "OWNER"))
		var orow := UIKit.hbox(10)
		orow.add_child(UIKit.portrait(e.owner, Vector2(110, 74), cat.get_unit(e.owner).faction_id))
		var ov := UIKit.vbox(2)
		ov.add_child(UIKit.label(Loc.t("unit.%s.name" % e.owner), 17, UIKit.TEXT, true))
		ov.add_child(UIKit.caption(Loc.t("ui.codex.owner_note"), 11, UIKit.TEXT_DIM))
		var jb: Button = UIKit.button(Loc.t("ui.codex.open_entry"), "ghost", Vector2(120, 32))
		jb.pressed.connect(jump.bind("units", e.owner))
		ov.add_child(jb)
		orow.add_child(ov)
		side.add_child(orow)
		side.add_child(UIKit.spacer(0, 6))
	var fits: Array[String] = cat.fit_units(e.id)
	if not fits.is_empty():
		side.add_child(UIKit.section(Loc.t("ui.card.fits"), "FITS"))
		side.add_child(UIKit.caption(Loc.t("ui.codex.fits_note"), 11, UIKit.TEXT_DIM))
		for uid: String in fits:
			var frow := UIKit.hbox(10)
			frow.add_child(UIKit.portrait(uid, Vector2(74, 50), cat.get_unit(uid).faction_id))
			var fb: Button = UIKit.button(Loc.t("unit.%s.name" % uid), "ghost", Vector2(200, 36))
			fb.alignment = HORIZONTAL_ALIGNMENT_LEFT
			fb.pressed.connect(jump.bind("units", uid))
			frow.add_child(fb)
			side.add_child(frow)
		side.add_child(UIKit.spacer(0, 6))
	_keyword_links(side, "weapons", e.id)
	cols.add_child(side)
	_info.add_child(cols)


func _keyword_detail(kid: String) -> void:
	var k: Dictionary = _kw_entry(kid)
	var is_rule: bool = str(k.get("kind", "")) == "rule"
	var box := UIKit.vbox(10)
	box.custom_minimum_size = Vector2(760, 0)
	box.add_child(UIKit.caption(("Settlement rule" if is_rule else "Keyword") + " · " + Loc.t_in("en", ("class." if is_rule else "keyword.") + kid.split(":")[1]), 12, UIKit.ACCENT))
	box.add_child(UIKit.label(("〔%s〕" if is_rule else "【%s】") % _kw_name(kid), 38, UIKit.KEYWORD, true))
	box.add_child(UIKit.label(Loc.t("ui.codex.rule") if is_rule else Loc.t("ui.codex.keyword"), 13, UIKit.TEXT_DIM))
	box.add_child(UIKit.spacer(0, 4))
	box.add_child(UIKit.section(Loc.t("ui.codex.meaning"), "DEFINITION"))
	box.add_child(UIKit.rich(_kw_desc(kid), 17, 740))
	box.add_child(UIKit.spacer(0, 8))
	box.add_child(UIKit.section(Loc.t("ui.codex.used_by"), "USED BY"))
	for u: Dictionary in k.get("uses", []):
		var tid: String = str(u["tab"])
		var id: String = str(u["id"])
		var row := UIKit.hbox(12)
		if tid == "units":
			row.add_child(UIKit.portrait(id, Vector2(74, 50), cat.get_unit(id).faction_id))
		else:
			row.add_child(UIKit.equipment_icon(cat.get_equipment(id), 50.0))
		var nm: String = Loc.t(("unit.%s.name" if tid == "units" else "equipment.%s.name") % id)
		var b: Button = UIKit.button("%s  ·  %s" % [nm, str(u["where"])], "ghost", Vector2(360, 40))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(jump.bind(tid, id))
		row.add_child(b)
		box.add_child(row)
	_info.add_child(box)


# ---------------------------------------------------------------- 关闭
func close_codex() -> void:
	closed.emit()
	queue_free()


func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and (ev as InputEventKey).pressed and not (ev as InputEventKey).echo and (ev as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close_codex()
