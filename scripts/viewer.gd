extends Node3D
## 展示场景：灰米色摄影棚、环绕相机、动作切换 UI。
## 鼠标：左键拖动旋转 / 滚轮缩放 / 中键或右键拖动平移；键盘：1-7 切换动作，R 自动旋转，F 聚焦头部，T 慢动作
const Stage = preload("res://scripts/stage.gd")

const ANIMS := [
	["idle", "待机 Idle"],
	["walk", "行走 Walk"],
	["run", "奔跑 Run"],
	["aim", "瞄准 Aim"],
	["shoot", "射击 Shoot"],
	["jump", "跳跃 Jump"],
	["showcase", "展示 Showcase"],
]
const ONESHOT := ["shoot", "jump"]

@onready var archer: Node3D = $Archer

var cam: Camera3D
var ap: AnimationPlayer
var yaw := 24.0
var pitch := 10.0
var dist := 4.4
var target := Vector3(0, 0.62, 0)
var goal_target := Vector3(0, 0.62, 0)
var goal_dist := 4.4
var auto_rotate := false
var slow := false
var dragging := 0
var buttons: Dictionary = {}
var current := "idle"
var info: Label
var shot_path := ""
var frames := 0
var skel: Skeleton3D
var bone_im: ImmediateMesh
var bone_mi: MeshInstance3D
var show_bones := false
var bones_btn: CheckButton


func _ready() -> void:
	var st: Dictionary = Stage.build(self)
	cam = st["camera"]
	cam.fov = 26.0
	get_viewport().msaa_3d = Viewport.MSAA_4X
	ap = archer.get_node("AnimationPlayer")
	ap.playback_default_blend_time = 0.25
	ap.animation_finished.connect(_on_anim_finished)
	_build_ui()
	_setup_bones()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot_path = a.substr(7)
		elif a.begins_with("--anim="):
			current = a.substr(7)
		elif a.begins_with("--yaw="):
			yaw = float(a.substr(6))
		elif a == "--bones":
			show_bones = true
	play(current)
	_update_camera(1.0)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var title := Label.new()
	title.text = "Voxel Archer · 体素弓箭手"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#3b3630"))
	title.position = Vector2(24, 16)
	root.add_child(title)

	info = Label.new()
	info.add_theme_font_size_override("font_size", 13)
	info.add_theme_color_override("font_color", Color("#5b544b"))
	info.position = Vector2(26, 50)
	info.text = "左键旋转 · 滚轮缩放 · 右键平移 · 1-7 切换动作 · R 自动旋转 · F 聚焦头部 · T 慢动作 · B 显示骨骼"
	root.add_child(info)

	var bottom := CenterContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -78.0
	bottom.offset_bottom = -16.0
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.55)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", sb)
	bottom.add_child(panel)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	panel.add_child(hb)
	var i := 1
	for a in ANIMS:
		var b := Button.new()
		b.text = "%d %s" % [i, a[1]]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(96, 34)
		b.pressed.connect(play.bind(a[0]))
		hb.add_child(b)
		buttons[a[0]] = b
		i += 1
	var rot := CheckButton.new()
	rot.text = "自动旋转"
	rot.add_theme_color_override("font_color", Color("#3b3630"))
	rot.add_theme_color_override("font_hover_color", Color("#000000"))
	rot.add_theme_color_override("font_pressed_color", Color("#000000"))
	rot.add_theme_color_override("font_hover_pressed_color", Color("#000000"))
	rot.focus_mode = Control.FOCUS_NONE
	rot.toggled.connect(func(v: bool): auto_rotate = v)
	hb.add_child(rot)
	bones_btn = CheckButton.new()
	bones_btn.text = "骨骼"
	bones_btn.add_theme_color_override("font_color", Color("#3b3630"))
	bones_btn.add_theme_color_override("font_hover_color", Color("#000000"))
	bones_btn.add_theme_color_override("font_pressed_color", Color("#000000"))
	bones_btn.add_theme_color_override("font_hover_pressed_color", Color("#000000"))
	bones_btn.focus_mode = Control.FOCUS_NONE
	bones_btn.toggled.connect(func(v: bool): show_bones = v)
	hb.add_child(bones_btn)
	var sheet := Button.new()
	sheet.text = "示例卡 →"
	sheet.focus_mode = Control.FOCUS_NONE
	sheet.custom_minimum_size = Vector2(96, 34)
	sheet.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/character_sheet.tscn"))
	hb.add_child(sheet)


func play(nm: String) -> void:
	current = nm
	if ap.has_animation(nm):
		ap.play(nm)
		ap.speed_scale = 0.35 if slow else 1.0
	for k in buttons:
		(buttons[k] as Button).set_pressed_no_signal(k == nm)


func _on_anim_finished(nm: StringName) -> void:
	if String(nm) in ONESHOT:
		play("idle")


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			goal_dist = clampf(goal_dist * 0.9, 0.8, 9.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			goal_dist = clampf(goal_dist * 1.1, 0.8, 9.0)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			dragging = 1 if mb.pressed else 0
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = 2 if mb.pressed else 0
	elif ev is InputEventMouseMotion:
		var mm := ev as InputEventMouseMotion
		if dragging == 1:
			yaw -= mm.relative.x * 0.35
			pitch = clampf(pitch + mm.relative.y * 0.3, -20.0, 75.0)
		elif dragging == 2:
			var right := cam.global_transform.basis.x
			var up := cam.global_transform.basis.y
			goal_target += (-right * mm.relative.x + up * mm.relative.y) * 0.0015 * goal_dist
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		var k := ev as InputEventKey
		if k.keycode >= KEY_1 and k.keycode <= KEY_7:
			play(ANIMS[k.keycode - KEY_1][0])
		elif k.keycode == KEY_R:
			auto_rotate = not auto_rotate
		elif k.keycode == KEY_F:
			if goal_dist > 2.5:
				goal_target = Vector3(0, 1.05, 0)
				goal_dist = 1.8
			else:
				goal_target = Vector3(0, 0.62, 0)
				goal_dist = 4.4
		elif k.keycode == KEY_B:
			show_bones = not show_bones
			bones_btn.set_pressed_no_signal(show_bones)
		elif k.keycode == KEY_T:
			slow = not slow
			ap.speed_scale = 0.35 if slow else 1.0


func _setup_bones() -> void:
	skel = archer.get_node("Skeleton3D")
	bone_im = ImmediateMesh.new()
	bone_mi = MeshInstance3D.new()
	bone_mi.mesh = bone_im
	bone_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color("#ff4d2e")
	m.no_depth_test = true
	m.render_priority = 20
	bone_mi.material_override = m
	add_child(bone_mi)


func _update_bones() -> void:
	bone_im.clear_surfaces()
	if not show_bones:
		return
	bone_im.surface_begin(Mesh.PRIMITIVE_LINES)
	var xf := skel.global_transform
	for i in range(skel.get_bone_count()):
		var p := skel.get_bone_parent(i)
		var b: Vector3 = xf * skel.get_bone_global_pose(i).origin
		if p >= 0:
			var a: Vector3 = xf * skel.get_bone_global_pose(p).origin
			bone_im.surface_add_vertex(a)
			bone_im.surface_add_vertex(b)
		# 关节小十字
		var d := 0.006
		for ax in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
			bone_im.surface_add_vertex(b - ax * d)
			bone_im.surface_add_vertex(b + ax * d)
	bone_im.surface_end()


func _update_camera(k: float) -> void:
	dist = lerpf(dist, goal_dist, k)
	target = target.lerp(goal_target, k)
	var cp := cos(deg_to_rad(pitch))
	var dir := Vector3(sin(deg_to_rad(yaw)) * cp, sin(deg_to_rad(pitch)), cos(deg_to_rad(yaw)) * cp)
	cam.position = target + dir * dist
	cam.look_at(target, Vector3.UP)


func _process(delta: float) -> void:
	if auto_rotate and dragging == 0:
		yaw += delta * 18.0
	_update_camera(clampf(delta * 10.0, 0.0, 1.0))
	_update_bones()
	frames += 1
	if shot_path != "" and frames == 40:
		get_viewport().get_texture().get_image().save_png(shot_path)
		get_tree().quit()
