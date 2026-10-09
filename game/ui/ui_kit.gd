class_name UIKit
extends RefCounted
## UI 工具包(超次元工坊 · 战术终端风格，参考《明日方舟》)：
##   直角/切角的深色面板 + 细描边 + 一条主题强调色；中文标题配小号英文大写标注；数字用 DIN 风格字体；
##   主要行动按钮是明黄色的斜切块，带警示斜纹；图标全部矢量绘制(Glyph)或离屏渲染的体素模型。
## 配色来自 UITheme(章节主题接口)：apply_theme() 之后新建的控件都用新配色。

# ---- 当前配色(由 apply_theme 设置；名字沿用旧常量，调用处不用改)
static var theme_name: String = ""
static var BG: Color
static var BG_SOFT: Color
static var BG_DEEP: Color
static var BORDER: Color
static var LINE_STRONG: Color
static var TEXT: Color
static var TEXT_SOFT: Color
static var TEXT_DIM: Color
static var TEXT_MUTE: Color
static var ACCENT: Color
static var ACTION: Color
static var ACTION_TEXT: Color
static var GOLD: Color
static var GOOD: Color
static var BAD: Color
static var KEYWORD: Color
static var PLAYER: Color
static var ENEMY: Color
static var FADE: Color
static var OVERLAY: Color

## 启动时由 Portraits 离屏渲染好的贴图：单位头像(def id -> Texture2D)、武器图标(武器 id -> Texture2D，真实体素模型)
static var portraits: Dictionary = {}
static var weapon_icons: Dictionary = {}
static var material_icons: Dictionary = {}   # 车间材料的像素图标：材料 -> {"s": 26 px, "l": 48 px}(Portraits 渲染)

# ---- 字体：中文正文/粗体(系统黑体)，数字与英文标注(Bahnschrift，DIN 风格窄体)
static var font_body: Font
static var font_bold: Font
static var font_num: Font
static var font_caps: Font
static var _theme: Theme = null
static var _bb_map: Dictionary = {}
## 关键词悬停回调(HUD 注册)：func(keyword_id: String, on: bool)
static var kw_handler: Callable = Callable()


## 切换章节配色(未知名字 = 默认)。返回是否真的变了
static func apply_theme(name: String) -> bool:
	var n: String = name if UITheme.has(name) else UITheme.DEFAULT
	if n == theme_name:
		return false
	theme_name = n
	var p: Dictionary = UITheme.palette(n)
	BG = p["panel"]
	BG_SOFT = p["panel_soft"]
	BG_DEEP = p["panel_deep"]
	BORDER = p["line"]
	LINE_STRONG = p["line_strong"]
	TEXT = p["text"]
	TEXT_SOFT = p["text_soft"]
	TEXT_DIM = p["text_dim"]
	TEXT_MUTE = p["text_mute"]
	ACCENT = p["accent"]
	ACTION = p["action"]
	ACTION_TEXT = p["action_text"]
	GOLD = p["gold"]
	GOOD = p["good"]
	BAD = p["danger"]
	PLAYER = p["player"]
	KEYWORD = p.get("keyword", Color("#4d8bff"))
	ENEMY = p["enemy"]
	FADE = p["fade"]
	OVERLAY = p["overlay"]
	# 富文本里写死的旧色值 → 当前主题的语义色(描述文字不用逐处改)
	_bb_map = {
		"#9aa3b5": TEXT_DIM, "#7d8598": TEXT_DIM, "#6d7588": TEXT_MUTE, "#8f96a3": TEXT_DIM, "#8a8fa0": TEXT_DIM,
		"#6f778a": TEXT_MUTE, "#5f6a80": TEXT_MUTE, "#c8d3e8": TEXT_SOFT, "#b8c0d0": TEXT_SOFT,
		"#ffd875": GOLD, "#ffe0a8": GOLD.lerp(TEXT, 0.35), "#ffd23a": GOLD, "#9be8ff": ACCENT, "#7dff9a": GOOD,
		Describe.KW_COLOR: KEYWORD,
	}
	return true


static func ensure() -> void:
	if theme_name == "":
		apply_theme(UITheme.DEFAULT)
	if font_body == null:
		_init_fonts()


static func _init_fonts() -> void:
	var cn := PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "PingFang SC", "Noto Sans CJK SC", "Source Han Sans SC", "Noto Sans SC"])
	var b := SystemFont.new()
	b.font_names = cn
	b.font_weight = 400
	font_body = b
	var bd := SystemFont.new()
	bd.font_names = cn
	bd.font_weight = 700
	font_bold = bd
	var n := SystemFont.new()
	n.font_names = PackedStringArray(["Bahnschrift", "DIN Alternate", "Roboto Condensed", "Arial Narrow", "Segoe UI"])
	n.font_weight = 600
	n.font_stretch = 87
	n.fallbacks = [bd]
	font_num = n
	var cap := FontVariation.new()
	cap.base_font = n
	cap.spacing_glyph = 2
	font_caps = cap


## 挂到 HUD/Screens 上的 Theme：默认字体 + 滚动条等通用控件的外观
static func theme() -> Theme:
	ensure()
	if _theme == null:
		_theme = Theme.new()
	_theme.default_font = font_body
	_theme.default_font_size = 15
	var grab := StyleBoxFlat.new()
	grab.bg_color = LINE_STRONG
	grab.content_margin_top = 3
	grab.content_margin_bottom = 3
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0.2)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	for sb_name: String in ["HScrollBar", "VScrollBar"]:
		_theme.set_stylebox("grabber", sb_name, grab)
		_theme.set_stylebox("grabber_highlight", sb_name, grab)
		_theme.set_stylebox("grabber_pressed", sb_name, grab)
		_theme.set_stylebox("scroll", sb_name, track)
	return _theme


# ================================================================ 面板
## 面板底：直角；radius ≥ 10 时做成左上/右下两个 45° 切角(战术终端的切角面板)
static func style(bg: Color = Color(-1, 0, 0), radius: int = 0, border: Color = Color(-1, 0, 0), border_w: int = 1, pad: int = 8) -> StyleBoxFlat:
	ensure()
	var s := StyleBoxFlat.new()
	s.bg_color = BG if bg.r < 0.0 else bg
	s.border_color = BORDER if border.r < 0.0 else border
	s.set_border_width_all(border_w)
	var ch: int = 0 if radius < 10 else mini(radius, 14)
	if ch > 0:
		s.corner_radius_top_left = ch
		s.corner_radius_bottom_right = ch
		s.corner_detail = 1
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad
	s.content_margin_bottom = pad
	s.shadow_color = Color(0, 0, 0, 0.22)
	s.shadow_size = 3
	s.shadow_offset = Vector2(0, 2)
	s.anti_aliasing = true
	return s


static func panel(bg: Color = Color(-1, 0, 0), radius: int = 12, pad: int = 8) -> PanelContainer:
	return ark_panel(pad, "", radius, bg)


## 战术面板：切角 + 细描边 + 一条强调色(edge = "left"/"top"/"")；corners = 画角标
static func ark_panel(pad: int = 10, edge: String = "left", chamfer: int = 12, bg: Color = Color(-1, 0, 0), accent: Color = Color(-1, 0, 0)) -> ArkPanel:
	ensure()
	var p := ArkPanel.new()
	p.add_theme_stylebox_override("panel", style(bg, chamfer, BORDER, 1, pad))
	p.edge = edge
	p.accent = ACCENT if accent.r < 0.0 else accent
	return p


# ================================================================ 文字
static func label(text: String, size: int = 15, color: Color = Color(-1, 0, 0), bold: bool = false) -> Label:
	ensure()
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", TEXT if color.r < 0.0 else color)
	if bold:
		l.add_theme_font_override("font", font_bold)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## 飘在 3D 画面上的文字：加一圈深色描边保证可读
static func outlined(l: Label, width: int = 6) -> Label:
	l.add_theme_constant_override("outline_size", width)
	l.add_theme_color_override("font_outline_color", Color(0.04, 0.045, 0.06, 0.9))
	return l


## 英文大写小标注(字距加宽)
static func caption(text: String, size: int = 10, color: Color = Color(-1, 0, 0)) -> Label:
	ensure()
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_font_override("font", font_caps)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", TEXT_DIM if color.r < 0.0 else color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## 数字(DIN 风格窄体)
static func num(text: String, size: int = 18, color: Color = Color(-1, 0, 0)) -> Label:
	ensure()
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font_num)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", TEXT if color.r < 0.0 else color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## 富文本里的旧色值换成当前主题色
static func bb(text: String) -> String:
	ensure()
	var out: String = text
	for k: String in _bb_map.keys():
		if out.contains(k):
			out = out.replace(k, "#" + (_bb_map[k] as Color).to_html(false))
	return out


static func hx(c: Color) -> String:
	return "#" + c.to_html(false)


static func rich(bbcode: String, size: int = 14, width: float = 300.0) -> RichTextLabel:
	ensure()
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.custom_minimum_size = Vector2(width, 0)
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_override("bold_font", font_bold)
	r.add_theme_color_override("default_color", TEXT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.text = bb(Describe.link_keywords(bbcode))
	if r.text.contains("[url=kw:"):
		# 关键词：蓝字、不加下划线，指上去显示详情(所在面板固定住/常驻时才能指到)
		r.meta_underlined = false
		r.mouse_filter = Control.MOUSE_FILTER_PASS
		r.set_meta("kw_links", true)
		r.meta_hover_started.connect(func(meta: Variant) -> void: _kw_hover(meta, true))
		r.meta_hover_ended.connect(func(meta: Variant) -> void: _kw_hover(meta, false))
	return r


static func _kw_hover(meta: Variant, on: bool) -> void:
	var m: String = str(meta)
	if m.begins_with("kw:") and kw_handler.is_valid():
		kw_handler.call(m.substr(3), on)


## 小节标题：▌中文标题 + 英文标注 + 一条细线
static func section(cn: String, en: String = "", color: Color = Color(-1, 0, 0)) -> Control:
	ensure()
	var c: Color = ACCENT if color.r < 0.0 else color
	var h := hbox(7)
	var bar := ColorRect.new()
	bar.color = c
	bar.custom_minimum_size = Vector2(3, 14)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(bar)
	h.add_child(label(cn, 14, TEXT, true))
	if en != "":
		var cap: Label = caption(en, 10, c)
		cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(cap)
	var line := ColorRect.new()
	line.color = BORDER
	line.custom_minimum_size = Vector2(0, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(line)
	return h


## 斜切小标签(阵营/职业/节点类型等)
static func tag(text: String, color: Color, filled: bool = false, size: int = 12) -> PanelContainer:
	ensure()
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = color if filled else Color(color.r, color.g, color.b, 0.16)
	s.border_color = color
	s.border_width_left = 3
	s.skew = Vector2(0.18, 0)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 1
	s.content_margin_bottom = 1
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(label(text, size, BG_DEEP if filled else TEXT, true))
	return p


## 编号牌(关卡编号 "0-1" 等)：最深的底 + 大号数字
static func code_badge(code: String, size: int = 30, min_size: Vector2 = Vector2(82, 56)) -> PanelContainer:
	ensure()
	var p := PanelContainer.new()
	var s := style(BG_DEEP, 0, LINE_STRONG, 1, 6)
	s.shadow_size = 0
	p.add_theme_stylebox_override("panel", s)
	p.custom_minimum_size = min_size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l: Label = num(code, size, TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


# ================================================================ 按钮
## kind: primary(明黄行动) / normal(深色) / danger(红) / ghost(透明) / accent(主题色描边)
static func button(text: String, kind: String = "normal", min_size: Vector2 = Vector2(96, 40)) -> Button:
	ensure()
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_font_override("font", font_bold)
	var base: Color = BG_SOFT
	var edge: Color = BORDER
	var fg: Color = TEXT
	var hover_edge: Color = ACCENT
	match kind:
		"primary":
			base = ACTION
			edge = ACTION.lightened(0.3)
			fg = ACTION_TEXT
			hover_edge = ACTION.lightened(0.5)
		"danger":
			base = BAD.darkened(0.35)
			edge = BAD
			hover_edge = BAD.lightened(0.3)
		"ghost":
			base = Color(BG_SOFT.r, BG_SOFT.g, BG_SOFT.b, 0.0)
			edge = Color(0, 0, 0, 0)
			fg = TEXT_SOFT
		"accent":
			base = BG_SOFT
			edge = ACCENT
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg if kind == "primary" else TEXT)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_disabled_color", Color(fg.r, fg.g, fg.b, 0.35))
	var n: StyleBoxFlat = style(base, 0, edge, 1, 8)
	var h: StyleBoxFlat = style(base.lightened(0.1) if kind != "ghost" else Color(TEXT.r, TEXT.g, TEXT.b, 0.08), 0, hover_edge, 1, 8)
	var pr: StyleBoxFlat = style(base.darkened(0.2) if kind != "ghost" else Color(TEXT.r, TEXT.g, TEXT.b, 0.14), 0, hover_edge, 1, 8)
	var d: StyleBoxFlat = style(Color(base.r, base.g, base.b, base.a * 0.45), 0, BORDER, 1, 8)
	for sb: StyleBoxFlat in [n, h, pr, d]:
		sb.shadow_size = 0
		if kind == "primary":
			sb.skew = Vector2(0.16, 0)
	h.border_width_bottom = 2
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", pr)
	b.add_theme_stylebox_override("disabled", d)
	return b


## 主要行动按钮：明黄斜切块 + 中文大字 + 英文标注 + 右侧警示斜纹
static func action_button(cn: String, en: String, min_size: Vector2 = Vector2(240, 70), kind: String = "primary") -> Button:
	var b: Button = button("", kind, min_size)
	var fg: Color = ACTION_TEXT if kind == "primary" else TEXT
	var v := vbox(0)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var big: Label = label(cn, 24 if min_size.y >= 60 else 18, fg, true)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var small: Label = caption(en, 10, Color(fg.r, fg.g, fg.b, 0.72))
	small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(big)
	v.add_child(small)
	b.add_child(v)
	b.set_meta("cn", big)
	b.set_meta("en", small)
	if kind == "primary":
		var st := Stripes.new()
		st.color = Color(fg.r, fg.g, fg.b, 0.22)
		st.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
		st.offset_left = -34
		st.offset_right = -10
		st.offset_top = 8
		st.offset_bottom = -8
		b.add_child(st)
	return b


static func set_action_text(b: Button, cn: String, en: String) -> void:
	if b.has_meta("cn"):
		(b.get_meta("cn") as Label).text = cn
		(b.get_meta("en") as Label).text = en.to_upper()
	else:
		b.text = cn


# ================================================================ 图标 / 小控件
static func faction_dot(faction: String, size: float = 14.0) -> Glyph:
	var g := Glyph.new()
	g.kind = "gem"
	g.color = GC.faction_color(faction)
	g.custom_minimum_size = Vector2(size, size)
	return g


static func glyph(kind: String, color: Color, size: float = 18.0) -> Glyph:
	var g := Glyph.new()
	g.kind = kind
	g.color = color
	g.custom_minimum_size = Vector2(size, size)
	return g


static func class_glyph(cls: String, size: float = 18.0) -> Glyph:
	return glyph(cls, GC.CLASS_COLOR.get(cls, TEXT), size)


## 武器的代表色：基础武器是朴素的灰色，其余用武器颜色
static func weapon_color(e: EquipmentDef) -> Color:
	if e == null:
		return Color("#8f96a3")
	if e.basic:
		return Color("#b9a98f")          # 木/铁的朴素色
	if e.color_id == "black":
		return Color("#c9c2e8")          # 黑色(万用)武器：淡紫银，和基础武器区分开
	return GC.faction_color(e.color_id)


## 武器大类图标(cls 为空 = 空手)
static func weapon_glyph(cls: String, color: Color, size: float = 18.0) -> Glyph:
	return glyph("w_" + (cls if cls != "" else "unarmed"), color, size)


static func equipment_glyph(e: EquipmentDef, size: float = 18.0) -> Glyph:
	return weapon_glyph(e.class_id if e != null else "", weapon_color(e).lightened(0.35), size)


## 武器图标：优先用渲染好的体素模型图(与装备到棋子手里时一模一样)，没有时退回矢量图标
static func equipment_icon(e: EquipmentDef, size: float = 18.0) -> Control:
	if e != null and weapon_icons.has(e.id):
		return texture_icon(weapon_icons[e.id], size)
	return equipment_glyph(e, size)


## 车间材料图标：像素图标(按 size 挑小号 / 大号，按整数倍最近邻放大，保持像素清楚)；没渲染出来时退回矢量图标
static func material_icon(m: String, size: float = 26.0) -> Control:
	var set: Dictionary = material_icons.get(m, {})
	if set.is_empty():
		return glyph("m_" + m, Color.WHITE, size)
	var tex: Texture2D = set["l"] if size >= 44.0 or not set.has("s") else set["s"]
	var px: float = float(tex.get_width())
	var k: float = maxf(1.0, floor(size / px + 0.25))
	var tr: TextureRect = texture_icon(tex, px * k)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return tr


## 材料的显示色(界面条形图 / 三角图的角)
static func material_color(m: String) -> Color:
	return {"red": Color("#ff6a2a"), "green": Color("#6cc84a"), "blue": Color("#4aa6ff")}.get(m, TEXT)


static func texture_icon(tex: Texture2D, size: float) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(size, size)
	tr.size = Vector2(size, size)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


## 单位头像：直角小框 + 左侧阵营色条
static func portrait(def_id: String, size: Vector2, faction: String = "") -> Control:
	ensure()
	var p := PanelContainer.new()
	var sb := style(BG_DEEP, 0, BORDER, 1, 0)
	sb.shadow_size = 0
	if faction != "":
		sb.border_color = GC.faction_color(faction)
		sb.border_width_left = 3
	p.add_theme_stylebox_override("panel", sb)
	p.clip_contents = true
	p.custom_minimum_size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if portraits.has(def_id):
		var tr := TextureRect.new()
		tr.texture = portraits[def_id]
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.custom_minimum_size = size
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(tr)
	return p


static func spacer(w: float = 0.0, h: float = 0.0, expand: bool = false) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


static func hbox(sep: int = 6) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


static func vbox(sep: int = 6) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v


## 星级：实心小菱形
static func pips(n: int, color: Color = Color(-1, 0, 0), size: float = 10.0) -> HBoxContainer:
	var h := hbox(2)
	for i in range(n):
		h.add_child(glyph("gem", GOLD if color.r < 0.0 else color, size))
	return h


static func vline(alpha: float = 1.0) -> ColorRect:
	var l := ColorRect.new()
	l.color = Color(BORDER.r, BORDER.g, BORDER.b, BORDER.a * alpha)
	l.custom_minimum_size = Vector2(1, 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## 快捷键键帽：深色小方块 + 键名(R / L / X / SPACE / 1 …)
static func keycap(key: String) -> PanelContainer:
	ensure()
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.02, 0.022, 0.03, 0.78)
	s.border_color = Color(1, 1, 1, 0.38)
	s.set_border_width_all(1)
	s.border_width_bottom = 2
	s.content_margin_left = 4
	s.content_margin_right = 4
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l: Label = num(key, 11, Color("#f2f3f5"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


## 在按钮角上贴一个快捷键键帽(corner = "tr" 右上 / "tl" 左上)
static func add_key_hint(ctrl: Control, key: String, corner: String = "tr") -> PanelContainer:
	var kc: PanelContainer = keycap(key)
	if corner == "tl":
		kc.set_anchors_preset(Control.PRESET_TOP_LEFT)
		kc.offset_left = 4
		kc.offset_top = 3
	else:
		kc.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		kc.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		kc.offset_right = -3
		kc.offset_top = 3
	ctrl.add_child(kc)
	return kc


static func seg_bar(segments: int, w: float, h: float, fill: Color) -> SegBar:
	var s := SegBar.new()
	s.segments = segments
	s.fill = fill
	s.custom_minimum_size = Vector2(w, h)
	return s
