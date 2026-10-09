class_name ReportPanel
extends VBoxContainer
## 结算界面的详细战报(数据来自逻辑层的 BattleReport)。
## 上方：队伍切换(我方 / 敌方) + 指标页签(输出 / 承伤 / 治疗 / 护盾)。
## 左边：这一队按当前指标排的单位榜——条形按伤害类型分段(治疗 = 有效 + 溢出)、数值、占比、击杀、存活时间；点一行看明细。
## 右边：选中单位的概况(输出 / 秒伤 / 承伤 / 治疗 / 护盾 / 击杀 / 存活) + 当前指标的明细：
##   输出 → 来源技能(类型 / 次数 / 暴击率 / 数值 / 占比) + 打了谁；承伤 → 伤害来自谁的哪个技能 + 护盾吸收 / 抵挡 / 实际扣血；
##   治疗 → 来源技能(次数 / 有效 / 溢出) + 治疗了谁；护盾 → 来源技能 + 给了谁。

signal state_changed(team: int, metric: String, selected: String)

const METRICS: Array[String] = ["dealt", "taken", "heal", "shield"]
const METRIC_EN := {"dealt": "Damage", "taken": "Taken", "heal": "Healing", "shield": "Shield"}
const LIST_W := 610.0
const DETAIL_W := 880.0
const BODY_H := 410.0
const ROW_H := 44.0

var cat: Catalog
var rep: BattleReport
var team: int = GC.TEAM_PLAYER
var metric: String = "dealt"
var selected: String = ""
var _team_btns: Dictionary = {}
var _metric_btns: Dictionary = {}
var _list: VBoxContainer
var _detail: VBoxContainer


func setup(p_cat: Catalog, p_rep: BattleReport, p_team: int = GC.TEAM_PLAYER, p_metric: String = "dealt", p_sel: String = "") -> void:
	cat = p_cat
	rep = p_rep
	team = p_team
	metric = p_metric if METRICS.has(p_metric) else "dealt"
	selected = p_sel
	add_theme_constant_override("separation", 10)
	var head := UIKit.hbox(8)
	var sec: Control = UIKit.section(Loc.t("ui.result_stats"), "Combat record")
	sec.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sec)
	for tm: int in [GC.TEAM_PLAYER, GC.TEAM_ENEMY]:
		var b: Button = _chip(Loc.t("ui.ally") if tm == GC.TEAM_PLAYER else Loc.t("ui.enemy"), "Allies" if tm == GC.TEAM_PLAYER else "Hostiles", 112.0)
		b.pressed.connect(func() -> void:
			team = tm
			selected = ""
			_rebuild())
		_team_btns[tm] = b
		head.add_child(b)
	head.add_child(UIKit.spacer(10, 0))
	for m: String in METRICS:
		var b2: Button = _chip(Loc.t("ui.report.tab_" + m), str(METRIC_EN[m]), 104.0)
		b2.pressed.connect(func() -> void:
			metric = m
			selected = ""                     # 换指标：明细跟到这一项的第一名
			_rebuild())
		_metric_btns[m] = b2
		head.add_child(b2)
	add_child(head)
	var body := UIKit.hbox(16)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(LIST_W, BODY_H)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list = UIKit.vbox(2)
	_list.custom_minimum_size = Vector2(LIST_W - 12.0, 0)
	sc.add_child(_list)
	body.add_child(sc)
	body.add_child(UIKit.vline(0.7))
	_detail = UIKit.vbox(10)
	_detail.custom_minimum_size = Vector2(DETAIL_W, BODY_H)
	body.add_child(_detail)
	add_child(body)
	_rebuild()


# ---------------------------------------------------------------- 小部件
## 页签：中文 + 英文标注；选中的那个强调色描边 + 底边加粗
func _chip(cn: String, en: String, w: float) -> Button:
	var b: Button = UIKit.button("", "normal", Vector2(w, 34))
	var h := UIKit.hbox(5)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.add_child(UIKit.label(cn, 14, UIKit.TEXT, true))
	var cap: Label = UIKit.caption(en, 9)
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(cap)
	b.add_child(h)
	return b


static func _set_on(b: Button, on: bool, col: Color) -> void:
	var sb: StyleBoxFlat = UIKit.style(UIKit.BG_DEEP if on else UIKit.BG_SOFT, 0, col if on else UIKit.BORDER, 1, 6)
	sb.shadow_size = 0
	if on:
		sb.border_width_bottom = 3
	b.add_theme_stylebox_override("normal", sb)
	var h: HBoxContainer = b.get_child(0) as HBoxContainer
	if h != null:
		(h.get_child(0) as Label).add_theme_color_override("font_color", col if on else UIKit.TEXT_SOFT)


## 伤害类型 / 治疗 / 护盾的颜色(真实伤害用正文色，浅色主题下也看得见)
static func kind_color(kind: String) -> Color:
	match kind:
		"physical":
			return Fx.COLORS["physical"]
		"magic":
			return Fx.COLORS["magic"]
		"heal":
			return UIKit.GOOD
		"shield":
			return Fx.COLORS["shield"]
	return UIKit.TEXT


## 12345 → "12,345"
static func big(x: float) -> String:
	var s: String = str(int(roundf(maxf(0.0, x))))
	var out := ""
	while s.length() > 3:
		out = "," + s.right(3) + out
		s = s.left(s.length() - 3)
	return s + out


static func clock(t: float) -> String:
	return "%02d:%02d" % [int(t) / 60, int(t) % 60]


static func pct(part: float, whole: float) -> String:
	return "%d%%" % int(roundf(100.0 * part / whole)) if whole > 0.0 else "—"


## 一根分段条：segs = [[数值, 颜色], ...]，按 mx 缩放
static func _bar(w: float, h: float, segs: Array, mx: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h + 4.0)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back: Color = Color(UIKit.BORDER.r, UIKit.BORDER.g, UIKit.BORDER.b, 0.6)
	c.draw.connect(func() -> void:
		c.draw_rect(Rect2(0, 2, w, h), back)
		var x := 0.0
		for sg: Array in segs:
			var ww: float = w * float(sg[0]) / maxf(1.0, mx)
			if ww > 0.0:
				c.draw_rect(Rect2(x, 2, minf(ww, w - x), h), sg[1])
				x += ww)
	return c


static func _kind_segs(kinds: Dictionary) -> Array:
	var segs: Array = []
	for k: String in BattleReport.KINDS:
		if float(kinds.get(k, 0.0)) > 0.0:
			segs.append([float(kinds[k]), kind_color(k)])
	return segs


## 主要伤害类型的名字(混合了就写"混合")
static func _kind_label(kinds: Dictionary) -> Array:
	var tot := 0.0
	var top := ""
	var topv := 0.0
	for k: String in kinds.keys():
		tot += float(kinds[k])
		if float(kinds[k]) > topv:
			topv = float(kinds[k])
			top = k
	if top == "":
		return ["—", UIKit.TEXT_DIM]
	if topv < tot * 0.9:
		return [Loc.t("ui.report.mixed"), UIKit.TEXT_SOFT]
	return [Loc.t("dmgkind." + top), kind_color(top)]


static func _cell(text: String, w: float, size: int = 14, col: Color = Color(-1, 0, 0), right: bool = true, is_num: bool = true) -> Label:
	var l: Label = UIKit.num(text, size, UIKit.TEXT_SOFT if col.r < 0.0 else col) if is_num else UIKit.label(text, size, UIKit.TEXT_SOFT if col.r < 0.0 else col)
	l.custom_minimum_size = Vector2(w, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	l.clip_text = true
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


static func _head_cell(cn: String, w: float, right: bool = true) -> Label:
	var l: Label = UIKit.label(cn, 11, UIKit.TEXT_DIM, true)
	l.custom_minimum_size = Vector2(w, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	return l


## 来源的小标签(普攻 / 被动 / 武器 / 羁绊 / 状态 / 地形 / 回复)
static func _src_tag(kind: String) -> Control:
	var col: Color = UIKit.TEXT_DIM
	match kind:
		"weapon":
			col = UIKit.GOLD
		"passive":
			col = UIKit.ACCENT
		"trait":
			col = UIKit.KEYWORD
		"status", "terrain":
			col = UIKit.BAD
		"regen":
			col = UIKit.GOOD
	var t: PanelContainer = UIKit.tag(Loc.t("ui.report.kind_" + kind), col, false, 10)
	t.custom_minimum_size = Vector2(44, 0)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return t


func _metric_value(r: Dictionary) -> float:
	return float(r.get(metric, 0.0))


func _metric_segs(r: Dictionary) -> Array:
	match metric:
		"dealt":
			return _kind_segs(r["dealt_kind"])
		"taken":
			return _kind_segs(r["taken_kind"])
		"heal":
			var oc: Color = UIKit.GOOD
			return [[float(r["heal"]), oc], [float(r["overheal"]), Color(oc.r, oc.g, oc.b, 0.3)]]
	return [[float(r["shield"]), kind_color("shield")]]


func _accent() -> Color:
	return UIKit.PLAYER if team == GC.TEAM_PLAYER else UIKit.ENEMY


# ---------------------------------------------------------------- 重建
func _rebuild() -> void:
	for tm: int in _team_btns.keys():
		_set_on(_team_btns[tm], tm == team, UIKit.PLAYER if tm == GC.TEAM_PLAYER else UIKit.ENEMY)
	for m: String in _metric_btns.keys():
		_set_on(_metric_btns[m], m == metric, UIKit.ACCENT)
	var rows: Array[Dictionary] = rep.team_rows(team)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var va: float = _metric_value(a) + (float(a["overheal"]) * 0.001 if metric == "heal" else 0.0)
		var vb: float = _metric_value(b) + (float(b["overheal"]) * 0.001 if metric == "heal" else 0.0)
		return va > vb)
	if (selected == "" or not rep.rows.has(selected) or int(rep.rows[selected]["team"]) != team) and not rows.is_empty():
		selected = str(rows[0]["uid"])
	_build_list(rows)
	_build_detail()
	state_changed.emit(team, metric, selected)


func _build_list(rows: Array[Dictionary]) -> void:
	for ch: Node in _list.get_children():
		ch.queue_free()
	var head := UIKit.hbox(8)
	head.add_child(UIKit.spacer(4, 0))
	head.add_child(_head_cell(Loc.t("ui.report.col_unit"), 44.0 + 8.0 + 118.0, false))
	head.add_child(_head_cell("", 170.0))
	head.add_child(_head_cell(Loc.t("ui.report.col_total"), 70.0))
	head.add_child(_head_cell(Loc.t("ui.report.col_share"), 46.0))
	head.add_child(_head_cell(Loc.t("ui.report.col_kills"), 36.0))
	head.add_child(_head_cell(Loc.t("ui.report.col_life"), 66.0))
	_list.add_child(head)
	var total: float = rep.team_total(team, metric)
	var mx := 1.0
	for r: Dictionary in rows:
		mx = maxf(mx, _metric_value(r) + (float(r["overheal"]) if metric == "heal" else 0.0))
	for r2: Dictionary in rows:
		_list.add_child(_list_row(r2, mx, total))
	# 合计：总量 + 每秒
	var dur: float = maxf(1.0, rep.duration())
	var foot := UIKit.hbox(8)
	foot.add_child(UIKit.spacer(4, 0))
	foot.add_child(UIKit.label(Loc.t("ui.report.team_total"), 12, UIKit.TEXT_DIM, true))
	foot.add_child(UIKit.spacer(0, 0, true))
	foot.add_child(UIKit.num(big(total), 15, _accent()))
	foot.add_child(UIKit.caption(Loc.t("ui.report.per_sec", [big(total / dur)]), 10))
	foot.add_child(UIKit.spacer(8, 0))
	_list.add_child(UIKit.spacer(0, 2))
	_list.add_child(foot)


func _list_row(r: Dictionary, mx: float, total: float) -> Control:
	var uid: String = str(r["uid"])
	var on: bool = uid == selected
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, ROW_H)
	var n: StyleBoxFlat = UIKit.style(UIKit.BG_SOFT if on else Color(0, 0, 0, 0), 0, _accent() if on else Color(0, 0, 0, 0), 0, 0)
	n.border_width_left = 3 if on else 0
	n.shadow_size = 0
	var hv: StyleBoxFlat = n.duplicate() as StyleBoxFlat
	hv.bg_color = UIKit.BG_SOFT
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("pressed", hv)
	b.pressed.connect(func() -> void:
		selected = uid
		_rebuild())
	var h := UIKit.hbox(8)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.add_child(UIKit.spacer(4, 0))
	var d: UnitDef = cat.get_unit(str(r["def"]))
	var alive: bool = bool(r["alive"])
	var pic: Control = UIKit.portrait(d.id, Vector2(44, 33), d.faction_id)
	pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not alive:
		pic.modulate = Color(1, 1, 1, 0.45)
	h.add_child(pic)
	var nv := UIKit.vbox(-1)
	nv.custom_minimum_size = Vector2(118, 0)
	nv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var nm: Label = UIKit.label(Loc.t("unit.%s.name" % d.id), 13, UIKit.TEXT if alive else UIKit.TEXT_DIM, true)
	nm.clip_text = true
	nv.add_child(nm)
	var sub := UIKit.hbox(4)
	sub.add_child(UIKit.pips(int(r["star"]), UIKit.GOLD, 8.0))
	if bool(r.get("summon", false)):
		sub.add_child(UIKit.caption(Loc.t("ui.report.summon"), 9, UIKit.TEXT_DIM))
	nv.add_child(sub)
	h.add_child(nv)
	h.add_child(_bar(170.0, 10.0, _metric_segs(r), mx))
	var v: float = _metric_value(r)
	h.add_child(_cell(big(v), 70.0, 16, UIKit.TEXT if v > 0.0 else UIKit.TEXT_MUTE))
	h.add_child(_cell(pct(v, total) if v > 0.0 else "", 46.0, 13, UIKit.TEXT_DIM))
	h.add_child(_cell(str(int(r["kills"])) if int(r["kills"]) > 0 else "·", 36.0, 14, UIKit.TEXT_SOFT))
	var life := UIKit.hbox(4)
	life.custom_minimum_size = Vector2(66, 0)
	life.alignment = BoxContainer.ALIGNMENT_END
	life.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if alive:
		life.add_child(UIKit.label(Loc.t("ui.report.alive"), 12, UIKit.GOOD, true))
	else:
		life.add_child(UIKit.glyph("skull", UIKit.TEXT_DIM, 12.0))
		life.add_child(UIKit.num(clock(maxf(0.0, float(r["death"]))), 13, UIKit.TEXT_DIM))
	h.add_child(life)
	b.add_child(h)
	return b


# ---------------------------------------------------------------- 明细
func _build_detail() -> void:
	for ch: Node in _detail.get_children():
		ch.queue_free()
	if selected == "" or not rep.rows.has(selected):
		_detail.add_child(UIKit.label(Loc.t("ui.report.empty"), 13, UIKit.TEXT_DIM))
		return
	var r: Dictionary = rep.rows[selected]
	_detail.add_child(_overview(r))
	var cols := UIKit.hbox(18)
	match metric:
		"dealt":
			cols.add_child(_sources_table(r, "dealt"))
			cols.add_child(_targets_list(r, "dmg", Loc.t("ui.report.by_target"), "Targets"))
		"taken":
			cols.add_child(_attackers_table(r))
			cols.add_child(_taken_breakdown(r))
		"heal":
			cols.add_child(_sources_table(r, "heal"))
			cols.add_child(_targets_list(r, "heal", Loc.t("ui.report.heal_targets"), "Healed"))
		"shield":
			cols.add_child(_sources_table(r, "shield"))
			cols.add_child(_targets_list(r, "shield", Loc.t("ui.report.shield_targets"), "Shielded"))
	_detail.add_child(cols)


## 选中单位的概况条
func _overview(r: Dictionary) -> Control:
	var p: ArkPanel = UIKit.ark_panel(8, "left", 0, UIKit.BG_SOFT, _accent())
	var h := UIKit.hbox(14)
	var d: UnitDef = cat.get_unit(str(r["def"]))
	h.add_child(UIKit.portrait(d.id, Vector2(60, 45), d.faction_id))
	var nv := UIKit.vbox(0)
	nv.custom_minimum_size = Vector2(150, 0)
	var nm: Label = UIKit.label(Loc.t("unit.%s.name" % d.id), 18, UIKit.TEXT, true)
	nm.clip_text = true
	nv.add_child(nm)
	nv.add_child(UIKit.pips(int(r["star"]), UIKit.GOLD, 9.0))
	h.add_child(nv)
	# 秒伤按"在场时间"算：阵亡的算到阵亡那一刻
	var dur: float = maxf(1.0, float(r["death"]) if float(r["death"]) >= 0.0 else rep.duration())
	var cells: Array = [["ui.report.tab_dealt", "Damage", big(float(r["dealt"])), kind_color("physical") if float(r["dealt"]) > 0.0 else UIKit.TEXT_MUTE],
		["ui.report.dps", "DPS", big(float(r["dealt"]) / dur), UIKit.TEXT_SOFT],
		["ui.report.tab_taken", "Taken", big(float(r["taken"])), UIKit.TEXT_SOFT],
		["ui.report.tab_heal", "Healing", big(float(r["heal"])), UIKit.GOOD if float(r["heal"]) > 0.0 else UIKit.TEXT_MUTE],
		["ui.report.tab_shield", "Shield", big(float(r["shield"])), kind_color("shield") if float(r["shield"]) > 0.0 else UIKit.TEXT_MUTE],
		["ui.report.col_kills", "Kills", str(int(r["kills"])), UIKit.TEXT_SOFT]]
	for c: Array in cells:
		var cv := UIKit.vbox(-2)
		cv.custom_minimum_size = Vector2(82, 0)
		cv.add_child(UIKit.caption(str(c[1]), 9))
		cv.add_child(UIKit.num(str(c[2]), 19, c[3]))
		cv.add_child(UIKit.label(Loc.t(str(c[0])), 11, UIKit.TEXT_DIM))
		h.add_child(cv)
	var lv := UIKit.vbox(-2)
	lv.add_child(UIKit.caption("Status", 9))
	if bool(r["alive"]):
		lv.add_child(UIKit.label(Loc.t("ui.report.alive"), 17, UIKit.GOOD, true))
		lv.add_child(UIKit.label("%s / %s" % [big(float(r["hp"])), big(float(r["max_hp"]))], 11, UIKit.TEXT_DIM))
	else:
		lv.add_child(UIKit.label(Loc.t("ui.report.fell"), 17, UIKit.BAD, true))
		lv.add_child(UIKit.num(clock(maxf(0.0, float(r["death"]))), 12, UIKit.TEXT_DIM))
	h.add_child(lv)
	p.add_child(h)
	return p


## 伤害分类的一行小字：普攻 62% · 技能 30% · 持续 8%
func _cat_strip(cats: Dictionary, total: float) -> Control:
	var h := UIKit.hbox(10)
	h.add_child(UIKit.label(Loc.t("ui.report.by_cat"), 11, UIKit.TEXT_DIM, true))
	for c: String in Effects.DAMAGE_CATEGORIES:
		var cv: float = float(cats.get(c, 0.0))
		if cv > 0.0:
			h.add_child(UIKit.label("%s %s" % [Loc.t("ui.report.cat_" + c), pct(cv, total)], 11, UIKit.TEXT_SOFT))
	return h


## 来源技能表(输出 / 治疗 / 护盾)
func _sources_table(r: Dictionary, what: String) -> Control:
	var v := UIKit.vbox(3)
	v.custom_minimum_size = Vector2(530, 0)
	v.add_child(UIKit.section(Loc.t("ui.report.by_source"), "By source"))
	if what == "dealt" and float(r["dealt"]) > 0.0:
		v.add_child(_cat_strip(r["dealt_cat"], float(r["dealt"])))
	var key: String = {"dealt": "dmg", "heal": "heal", "shield": "shield"}[what]
	var list: Array = []
	var total := 0.0
	for se: Dictionary in (r["src"] as Dictionary).values():
		if float(se[key]) > 0.0 or (what == "heal" and float(se["over"]) > 0.0):
			list.append(se)
			total += float(se[key])
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a[key]) > float(b[key]))
	if list.is_empty():
		v.add_child(UIKit.label(Loc.t("ui.report.empty"), 13, UIKit.TEXT_DIM))
		return v
	var head := UIKit.hbox(6)
	head.add_child(_head_cell(Loc.t("ui.report.col_source"), 44.0 + 6.0 + 150.0, false))
	match what:
		"dealt":
			head.add_child(_head_cell(Loc.t("ui.report.col_type"), 50.0))
			head.add_child(_head_cell(Loc.t("ui.report.col_hits"), 42.0))
			head.add_child(_head_cell(Loc.t("ui.report.col_crit"), 44.0))
		"heal":
			head.add_child(_head_cell(Loc.t("ui.report.col_casts"), 42.0))
			head.add_child(_head_cell(Loc.t("ui.report.col_over"), 94.0))
		_:
			head.add_child(_head_cell(Loc.t("ui.report.col_casts"), 42.0))
			head.add_child(_head_cell("", 94.0))
	head.add_child(_head_cell(Loc.t("ui.report.col_total"), 62.0))
	head.add_child(_head_cell(Loc.t("ui.report.col_share"), 104.0))
	v.add_child(head)
	var sc := _scroll(238.0)
	var rows := UIKit.vbox(3)
	for se2: Dictionary in list:
		var nm: Dictionary = ReportNames.source(cat, str(r["def"]), str(se2["surface"]), str(se2["ability"]), str(se2["equip"]))
		var h := UIKit.hbox(6)
		h.add_child(_src_tag(str(nm["kind"])))
		var nl: Label = UIKit.label(str(nm["name"]), 13, UIKit.TEXT, true)
		nl.custom_minimum_size = Vector2(150, 0)
		nl.clip_text = true
		h.add_child(nl)
		var val: float = float(se2[key])
		match what:
			"dealt":
				var kl: Array = _kind_label(se2["kind"])
				h.add_child(_cell(str(kl[0]), 50.0, 12, kl[1], true, false))
				h.add_child(_cell(str(int(se2["hits"])), 42.0, 13))
				h.add_child(_cell(pct(float(se2["crits"]), float(se2["hits"])) if int(se2["crits"]) > 0 else "·", 44.0, 13, UIKit.TEXT_DIM))
			"heal":
				h.add_child(_cell(str(int(se2["casts"])), 42.0, 13))
				h.add_child(_cell("+" + big(float(se2["over"])) if float(se2["over"]) >= 1.0 else "·", 94.0, 13, UIKit.TEXT_DIM))
			_:
				h.add_child(_cell(str(int(se2["casts"])), 42.0, 13))
				h.add_child(_cell("", 94.0))
		h.add_child(_cell(big(val), 62.0, 15, UIKit.TEXT))
		var sh := UIKit.hbox(4)
		sh.custom_minimum_size = Vector2(104, 0)
		var segs: Array = _kind_segs(se2["kind"]) if what == "dealt" else [[val, kind_color(what)]]
		sh.add_child(_bar(60.0, 6.0, segs, total))
		sh.add_child(_cell(pct(val, total), 38.0, 12, UIKit.TEXT_DIM))
		h.add_child(sh)
		rows.add_child(h)
	sc.add_child(rows)
	v.add_child(sc)
	return v


## 目标列表(打了谁 / 治疗了谁 / 给谁上了护盾)
func _targets_list(r: Dictionary, key: String, cn: String, en: String) -> Control:
	var v := UIKit.vbox(3)
	v.custom_minimum_size = Vector2(330, 0)
	v.add_child(UIKit.section(cn, en))
	var list: Array = []
	var total := 0.0
	var mx := 1.0
	for uid: String in (r["to"] as Dictionary).keys():
		var tv: float = float(r["to"][uid][key])
		if tv > 0.0 and rep.rows.has(uid):
			list.append([uid, tv])
			total += tv
			mx = maxf(mx, tv)
	list.sort_custom(func(a: Array, b: Array) -> bool: return float(a[1]) > float(b[1]))
	if list.is_empty():
		v.add_child(UIKit.label(Loc.t("ui.report.empty"), 13, UIKit.TEXT_DIM))
		return v
	var sc := _scroll(260.0)
	var rows := UIKit.vbox(4)
	for it: Array in list:
		var tr: Dictionary = rep.rows[str(it[0])]
		var td: UnitDef = cat.get_unit(str(tr["def"]))
		var h := UIKit.hbox(6)
		var pic: Control = UIKit.portrait(td.id, Vector2(32, 24), td.faction_id)
		pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(pic)
		var nl: Label = UIKit.label(Loc.t("unit.%s.name" % td.id), 12, UIKit.TEXT_SOFT, true)
		nl.custom_minimum_size = Vector2(92, 0)
		nl.clip_text = true
		h.add_child(nl)
		var segs: Array = _kind_segs(r["to"][str(it[0])]["kind"]) if key == "dmg" else [[float(it[1]), kind_color(key)]]
		h.add_child(_bar(96.0, 6.0, segs, mx))
		h.add_child(_cell(big(float(it[1])), 58.0, 14, UIKit.TEXT))
		h.add_child(_cell(pct(float(it[1]), total), 36.0, 11, UIKit.TEXT_DIM))
		rows.add_child(h)
	sc.add_child(rows)
	v.add_child(sc)
	return v


## 承伤：伤害来自谁的哪个技能
func _attackers_table(r: Dictionary) -> Control:
	var v := UIKit.vbox(3)
	v.custom_minimum_size = Vector2(530, 0)
	v.add_child(UIKit.section(Loc.t("ui.report.by_attacker"), "Damage from"))
	var list: Array = (r["from_src"] as Dictionary).values()
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["dmg"]) > float(b["dmg"]))
	var total: float = float(r["taken"])
	if list.is_empty():
		v.add_child(UIKit.label(Loc.t("ui.report.empty"), 13, UIKit.TEXT_DIM))
		return v
	var head := UIKit.hbox(6)
	head.add_child(_head_cell(Loc.t("ui.report.col_attacker"), 32.0 + 6.0 + 92.0, false))
	head.add_child(_head_cell(Loc.t("ui.report.col_source"), 44.0 + 6.0 + 104.0, false))
	head.add_child(_head_cell(Loc.t("ui.report.col_hits"), 36.0))
	head.add_child(_head_cell(Loc.t("ui.report.col_total"), 62.0))
	head.add_child(_head_cell(Loc.t("ui.report.col_share"), 98.0))
	v.add_child(head)
	var sc := _scroll(238.0)
	var rows := UIKit.vbox(3)
	for fe: Dictionary in list:
		var h := UIKit.hbox(6)
		var ad: String = str(fe["def"])
		if ad != "":
			var ud: UnitDef = cat.get_unit(ad)
			var pic: Control = UIKit.portrait(ud.id, Vector2(32, 24), ud.faction_id)
			pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(pic)
		else:
			h.add_child(UIKit.spacer(32, 24))
		var an: Label = UIKit.label(ReportNames.unit_name(ad), 12, UIKit.TEXT_SOFT, true)
		an.custom_minimum_size = Vector2(92, 0)
		an.clip_text = true
		h.add_child(an)
		var nm: Dictionary = ReportNames.source(cat, ad, str(fe["surface"]), str(fe["ability"]), str(fe["equip"]))
		h.add_child(_src_tag(str(nm["kind"])))
		var nl: Label = UIKit.label(str(nm["name"]), 12, UIKit.TEXT, true)
		nl.custom_minimum_size = Vector2(104, 0)
		nl.clip_text = true
		h.add_child(nl)
		h.add_child(_cell(str(int(fe["hits"])), 36.0, 13))
		h.add_child(_cell(big(float(fe["dmg"])), 62.0, 15, UIKit.TEXT))
		var sh := UIKit.hbox(4)
		sh.custom_minimum_size = Vector2(98, 0)
		sh.add_child(_bar(56.0, 6.0, _kind_segs(fe["kind"]), total))
		sh.add_child(_cell(pct(float(fe["dmg"]), total), 36.0, 12, UIKit.TEXT_DIM))
		h.add_child(sh)
		rows.add_child(h)
	sc.add_child(rows)
	v.add_child(sc)
	return v


## 承伤的去向：总量 = 护盾吸收 + 实际扣血(+ 溢出的致命一击)；另列被抵挡掉的、受到的治疗 / 护盾；按伤害类型分段
func _taken_breakdown(r: Dictionary) -> Control:
	var v := UIKit.vbox(6)
	v.custom_minimum_size = Vector2(330, 0)
	v.add_child(UIKit.section(Loc.t("ui.report.breakdown"), "Breakdown"))
	var taken: float = float(r["taken"])
	v.add_child(_bar(320.0, 10.0, _kind_segs(r["taken_kind"]), taken))
	var leg := UIKit.hbox(10)
	for k: String in BattleReport.KINDS:
		var kv: float = float((r["taken_kind"] as Dictionary).get(k, 0.0))
		if kv > 0.0:
			var it := UIKit.hbox(4)
			var sw := ColorRect.new()
			sw.color = kind_color(k)
			sw.custom_minimum_size = Vector2(8, 8)
			sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			it.add_child(sw)
			it.add_child(UIKit.label("%s %s" % [Loc.t("dmgkind." + k), pct(kv, taken)], 11, UIKit.TEXT_DIM))
			leg.add_child(it)
	v.add_child(leg)
	# 按伤害分类：普攻 / 技能 / 持续
	v.add_child(_cat_strip(r["taken_cat"], taken))
	var lines: Array = [["ui.report.tab_taken", taken, UIKit.TEXT, false],
		["ui.report.absorbed", float(r["absorbed"]), kind_color("shield"), true],
		["ui.report.hp_lost", float(r["hp_lost"]), UIKit.BAD, true],
		["ui.report.mitigated", float(r["mitigated"]), UIKit.TEXT_SOFT, false],
		["ui.report.healed", float(r["healed"]), UIKit.GOOD, false],
		["ui.report.shielded", float(r["shielded"]), kind_color("shield"), false]]
	for ln: Array in lines:
		var h := UIKit.hbox(6)
		var lab: Label = UIKit.label(("└ " if bool(ln[3]) else "") + Loc.t(str(ln[0])), 13, UIKit.TEXT_SOFT if not bool(ln[3]) else UIKit.TEXT_DIM, not bool(ln[3]))
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(lab)
		h.add_child(_cell(big(float(ln[1])), 80.0, 15, ln[2]))
		v.add_child(h)
	v.add_child(UIKit.rich("[color=%s]%s[/color]" % [UIKit.hx(UIKit.TEXT_DIM), Loc.t("ui.report.mitigated_note")], 11, 320))
	return v


static func _scroll(h: float) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, h)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return sc
