extends Control
## 角色示例卡：按参考图的版式(主图 / 弓侧面 / 前后侧转面 / 三张细节特写)，全部是实时 3D 视口。
## 主图为"展示"动作(可看到头发、流苏、光环的实时飘动)。按 ESC 或左上角按钮返回。
const Stage = preload("res://scripts/stage.gd")

const REF := Vector2(1122, 1402)
const CARD_BG := Color("#bdb8ae")
const LINE := Color("#8f897f")

# rect 单位为参考图像素；h = 视口内可见的世界高度(米)
var PANELS := [
	{"rect": Rect2(6, 6, 760, 800), "scene": "res://scenes/archer.tscn", "anim": "showcase",
		"target": Vector3(-0.11, 0.6, 0), "yaw": 9.0, "pitch": 5.0, "h": 1.58, "frame": false},
	{"rect": Rect2(792, 34, 318, 748), "scene": "res://scenes/bow.tscn", "anim": "", "lift": 0.68,
		"target": Vector3(0, 0.68, 0), "yaw": 90.0, "pitch": 2.0, "h": 1.42, "frame": false},
	{"rect": Rect2(24, 818, 262, 556), "scene": "res://scenes/archer.tscn", "anim": "apose",
		"target": Vector3(0, 0.66, 0), "yaw": 0.0, "pitch": 3.0, "h": 1.62, "frame": false},
	{"rect": Rect2(288, 818, 262, 556), "scene": "res://scenes/archer.tscn", "anim": "apose",
		"target": Vector3(0, 0.66, 0), "yaw": 180.0, "pitch": 3.0, "h": 1.62, "frame": false},
	{"rect": Rect2(552, 818, 250, 556), "scene": "res://scenes/archer.tscn", "anim": "apose",
		"target": Vector3(0, 0.66, 0), "yaw": 90.0, "pitch": 3.0, "h": 1.62, "frame": false},
	{"rect": Rect2(818, 782, 286, 212), "scene": "res://scenes/archer.tscn", "anim": "apose",
		"target": Vector3(0, 1.06, 0), "yaw": 0.0, "pitch": 4.0, "h": 0.5, "frame": true},
	{"rect": Rect2(818, 1000, 286, 150), "scene": "res://scenes/archer.tscn", "anim": "apose",
		"target": Vector3(0, 0.8, 0), "yaw": 0.0, "pitch": 6.0, "h": 0.3, "frame": true},
	{"rect": Rect2(818, 1156, 286, 228), "scene": "res://scenes/archer.tscn", "anim": "apose",
		"target": Vector3(0.02, 0.4, 0), "yaw": 24.0, "pitch": 8.0, "h": 0.52, "frame": true},
]

var bg: ColorRect
var items: Array = []
var deco: Control
var back_btn: Button


func _ready() -> void:
	bg = ColorRect.new()
	bg.color = CARD_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	deco = Control.new()
	deco.set_anchors_preset(Control.PRESET_FULL_RECT)
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deco.draw.connect(_draw_deco)
	add_child(deco)
	for cfg in PANELS:
		items.append(_make_panel(cfg))
	back_btn = Button.new()
	back_btn.text = "← 返回展示"
	back_btn.position = Vector2(14, 12)
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	add_child(back_btn)
	resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _make_panel(cfg: Dictionary) -> Dictionary:
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(svc)
	var sv := SubViewport.new()
	sv.own_world_3d = true
	sv.msaa_3d = Viewport.MSAA_4X
	sv.transparent_bg = true
	svc.add_child(sv)
	var st: Dictionary = Stage.build(sv, Color.WHITE, true)
	var cam: Camera3D = st["camera"]
	cam.fov = 18.0
	var model: Node3D = (load(cfg["scene"]) as PackedScene).instantiate()
	sv.add_child(model)
	if cfg.has("lift"):
		model.position.y = float(cfg["lift"])
	var anim: String = cfg["anim"]
	if anim != "":
		var ap: AnimationPlayer = model.get_node("AnimationPlayer")
		ap.play(anim)
	var dist := float(cfg["h"]) / (2.0 * tan(deg_to_rad(cam.fov * 0.5)))
	var yaw := deg_to_rad(float(cfg["yaw"]))
	var pit := deg_to_rad(float(cfg["pitch"]))
	var dir := Vector3(sin(yaw) * cos(pit), sin(pit), cos(yaw) * cos(pit))
	var tgt: Vector3 = cfg["target"]
	cam.position = tgt + dir * dist
	cam.look_at(tgt, Vector3.UP)
	return {"svc": svc, "cfg": cfg}


func _card_rect() -> Rect2:
	var sc := minf(size.x / REF.x, size.y / REF.y)
	var sz := REF * sc
	return Rect2((size - sz) * 0.5, sz)


func _layout() -> void:
	var cr := _card_rect()
	var sc := cr.size.x / REF.x
	for it in items:
		var r: Rect2 = it["cfg"]["rect"]
		var svc: SubViewportContainer = it["svc"]
		svc.position = cr.position + r.position * sc
		svc.size = r.size * sc
	deco.queue_redraw()


func _draw_deco() -> void:
	var cr := _card_rect()
	var sc := cr.size.x / REF.x
	var w := maxf(1.0, 1.6 * sc)
	# 卡片外框
	deco.draw_rect(Rect2(cr.position + Vector2(4, 4) * sc, cr.size - Vector2(8, 8) * sc), LINE, false, w)
	# 主图与弓之间的分隔线(带菱形)
	var x := cr.position.x + 774.0 * sc
	deco.draw_line(Vector2(x, cr.position.y + 60 * sc), Vector2(x, cr.position.y + 730 * sc), LINE, w)
	for yy in [60.0, 730.0]:
		_diamond(Vector2(x, cr.position.y + yy * sc), 7.0 * sc)
	_diamond(Vector2(x, cr.position.y + 383.0 * sc), 6.0 * sc)
	# 转面图外框
	var tr := Rect2(cr.position + Vector2(16, 810) * sc, Vector2(790, 566) * sc)
	deco.draw_rect(tr, LINE, false, w)
	for k in [0, 1, 2, 3]:
		var cpos: Vector2 = tr.position + Vector2((k % 2) * tr.size.x, (k / 2) * tr.size.y)
		deco.draw_rect(Rect2(cpos - Vector2(4, 4) * sc, Vector2(8, 8) * sc), LINE, false, w)
	# 细节特写外框(圆角)
	for it in items:
		if it["cfg"]["frame"]:
			var r: Rect2 = it["cfg"]["rect"]
			var rr := Rect2(cr.position + r.position * sc, r.size * sc).grow(2.0 * sc)
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0, 0, 0, 0)
			sb.set_border_width_all(int(maxf(2.0, 2.5 * sc)))
			sb.border_color = LINE
			sb.set_corner_radius_all(int(9.0 * sc))
			deco.draw_style_box(sb, rr)


func _diamond(c: Vector2, r: float) -> void:
	deco.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), LINE)


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and (ev as InputEventKey).keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/main.tscn")
