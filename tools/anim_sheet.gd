extends SceneTree
## 动画审片：把一个(或一串)动画逐帧渲染成联系表，或导出帧序列(配合 ffmpeg 做 gif)。用来逐帧看节奏、弧线、预备/跟随动作。
## godot --path . --script res://tools/anim_sheet.gd -- wclass=bow chain=attack_bow@0-0.34,draw_bow,draw_bow_hold*1.0,release_bow
##   chain   逗号分隔的片段：name = 整段；name@a-b = 只取 a..b 秒；name*T = 循环播 T 秒
##   step    每隔几帧(30fps)取一帧，默认 2        view  q34 | game | side | sideL | front | back | top | x:y:z
##   face    模型绕竖轴转多少度(看侧面的招式)     cell  单格像素，默认 240x280     cols  每行几格(默认 10)
##   model   武器外观 plain | ornate | <专属外观>   body 专属身体(如 shielder)   shield[=tower] / male / trail(画刀光) 开关   zoom 取景高度(米，默认 2.1)
##   out     联系表路径(默认 res://out/sheet.png)  seq   帧序列目录前缀(给了就逐帧存 PNG，不拼表)
##   hide    不显示手里的武器(怪物 hide_weapon)
##   lib     另一份动画库(build_anims 的 out= 产物，例如 res://out/anim_dev.res)：审还没进正式库的动作
const Stage = preload("res://scripts/stage.gd")

const VIEWS := {
	"q34": Vector3(0.62, 0.2, 0.75), "front": Vector3(0, 0.05, 1), "side": Vector3(-1, 0.05, 0.02),
	"sideL": Vector3(1, 0.05, 0.02), "back": Vector3(0.3, 0.2, -1), "top": Vector3(0.3, 1.0, 0.4),
	"game": Vector3(0.0, 0.83, 0.56),
}


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cw := 240
	var ch := 280
	if args.has("cell"):
		var c: PackedStringArray = str(args["cell"]).split("x")
		cw = int(c[0])
		ch = int(c[1])
	var step: int = maxi(1, int(args.get("step", "2")))
	var cols: int = int(args.get("cols", "10"))
	var sv := SubViewport.new()
	sv.size = Vector2i(cw, ch)
	sv.msaa_3d = Viewport.MSAA_4X
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var st := Stage.build(sv)
	var cam: Camera3D = st["camera"]
	cam.fov = 26.0
	var holder := Node3D.new()
	sv.add_child(holder)
	var model: Node3D = (load("res://scenes/unit_model.tscn") as PackedScene).instantiate()
	holder.add_child(model)
	holder.rotation.y = deg_to_rad(float(args.get("face", "0")))
	var ap: AnimationPlayer = model.get_node("AnimationPlayer")
	ap.autoplay = ""
	if args.has("lib"):
		# lib=res://out/anim_dev.res：用另存的动画库(build_anims 的 out= 产物)审还没进正式库的动作
		ap.remove_animation_library("")
		ap.add_animation_library("", load(str(args["lib"])))
	var look := {"wclass": str(args.get("wclass", "bow")), "model": str(args.get("model", "plain")),
		"color": str(args.get("color", "cyan")), "shield": args.has("shield"), "male": args.has("male"),
		"body": str(args.get("body", "")), "shield_kind": str(args.get("shield", "")) if str(args.get("shield", "")) != "1" else "shield",
		"hide_weapon": args.has("hide")}
	await process_frame
	UnitSkin.apply(model, look, str(args.get("faction", "red")))
	var trails: Array = []
	if args.has("trail"):
		var sk: Skeleton3D = UnitSkin.skeleton_of(model)
		for bn: String in (["Bow", "Weapon_L"] if look["wclass"] == "dual" else ["Bow"]):
			var tr: WeaponTrail = WeaponTrail.create(sk, ap, bn, look["wclass"], GC.faction_color(str(args.get("faction", "blue"))).lerp(Color.WHITE, 0.15), str(look["model"]))
			if tr != null:
				tr.offline = true
				sv.add_child(tr)
				trails.append(tr)
	# ---- 片段 → 逐帧采样表 [[动画名, 时刻], ...]
	var samples: Array = []
	for seg: String in str(args.get("chain", args.get("anim", "attack_bow"))).split(","):
		var nm: String = seg
		var a0 := 0.0
		var a1 := -1.0
		var loop_for := -1.0
		if seg.contains("*"):
			nm = seg.split("*")[0]
			loop_for = float(seg.split("*")[1])
		elif seg.contains("@"):
			nm = seg.split("@")[0]
			var r: PackedStringArray = seg.split("@")[1].split("-")
			a0 = float(r[0])
			a1 = float(r[1])
		if not ap.has_animation(nm):
			push_error("no animation " + nm)
			continue
		var L: float = ap.get_animation(nm).length
		if a1 < 0.0:
			a1 = L
		var n: int = int(round(((loop_for if loop_for > 0.0 else a1 - a0)) * 30.0))
		for f in range(n + (0 if loop_for > 0.0 else 1)):
			var tt: float = a0 + float(f) / 30.0
			if loop_for > 0.0:
				tt = fposmod(tt, L)
			samples.append([nm, minf(tt, L)])
	var vs: String = str(args.get("view", "q34"))
	var dir: Vector3 = (VIEWS.get(vs, VIEWS["q34"]) as Vector3).normalized()
	if vs.contains(":"):                     # view=x:y:z 自定义相机方向
		var c3: PackedStringArray = vs.split(":")
		dir = Vector3(float(c3[0]), float(c3[1]), float(c3[2])).normalized()
	var tgt := Vector3(0, float(args.get("ty", "0.7")), 0.15)
	var dist: float = float(args.get("zoom", "2.1")) / (2.0 * tan(deg_to_rad(cam.fov * 0.5)))
	cam.position = tgt + dir * dist
	cam.look_at(tgt, Vector3.UP if absf(dir.y) < 0.95 else Vector3.FORWARD)
	var seq: String = str(args.get("seq", ""))
	var imgs: Array = []
	for i in range(0, samples.size(), step):
		var s: Array = samples[i]
		ap.play(str(s[0]))
		ap.seek(float(s[1]), true)
		for tr2: WeaponTrail in trails:
			tr2.bake_at(str(s[0]), float(s[1]))
		ap.pause()
		for k in 2:
			await process_frame
		var im: Image = sv.get_texture().get_image()
		im.convert(Image.FORMAT_RGB8)
		if seq != "":
			im.save_png("%s_%03d.png" % [seq, imgs.size()])
		imgs.append(im)
	if seq != "":
		print("saved %d frames to %s_*.png" % [imgs.size(), seq])
		quit()
		return
	cols = mini(cols, imgs.size())
	var rows: int = int(ceil(float(imgs.size()) / float(cols)))
	var sheet := Image.create(cw * cols, ch * rows, false, Image.FORMAT_RGB8)
	sheet.fill(Color("#8a857d"))
	for i2 in imgs.size():
		sheet.blit_rect(imgs[i2], Rect2i(0, 0, cw, ch), Vector2i((i2 % cols) * cw, (i2 / cols) * ch))
	var out_path: String = str(args.get("out", "res://out/sheet.png"))
	sheet.save_png(out_path)
	print("saved ", out_path, " ", sheet.get_size(), " frames=", imgs.size())
	quit()
