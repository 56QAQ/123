extends SceneTree
## 截图工具。
## godot --path . --script res://tools/shot.gd -- views=front,back,side,q34 out=out/a.png cell=560x760 anim=idle t=0.5 scene=res://scenes/archer.tscn
## 棋子模型：scene=res://scenes/unit_model.tscn wclass=rifle model=plain|ornate faction=red [shield=1] [body=dancer|archer|nurse]
##   wclass=none：空手；hair=#rrggbb skin=<GC.SKIN_TONES 键> 换发色/肤色；lib=res://out/anim_dev.res 用另一份动画库(预览未入库的动画)
const Stage = preload("res://scripts/stage.gd")

# [方向, 目标点, 可视高度(米)]
const VIEWS := {
	"front": [Vector3(0, 0.04, 1), Vector3(0, 0.66, 0), 1.7],
	"back": [Vector3(0, 0.04, -1), Vector3(0, 0.66, 0), 1.7],
	"left": [Vector3(1, 0.04, 0), Vector3(0, 0.66, 0), 1.7],
	"right": [Vector3(-1, 0.04, 0), Vector3(0, 0.66, 0), 1.7],
	"q34": [Vector3(0.62, 0.2, 0.75), Vector3(0, 0.66, 0), 1.7],
	"q34b": [Vector3(-0.7, 0.2, 0.7), Vector3(0, 0.66, 0), 1.7],
	"qback": [Vector3(0.7, 0.2, -0.7), Vector3(0, 0.66, 0), 1.7],
	"head": [Vector3(0.0, 0.03, 1), Vector3(0, 1.08, 0), 0.78],
	"head34": [Vector3(0.55, 0.1, 0.8), Vector3(0, 1.08, 0), 0.78],
	"headL": [Vector3(1, 0.03, 0), Vector3(0, 1.1, -0.05), 0.75],
	"headB": [Vector3(0.0, 0.05, -1), Vector3(0, 1.1, 0), 0.8],
	"torso": [Vector3(0.0, 0.05, 1), Vector3(0, 0.8, 0), 0.8],
	"torso34": [Vector3(0.5, 0.1, 0.85), Vector3(0, 0.8, 0), 0.85],
	"torsoB": [Vector3(0.0, 0.05, -1), Vector3(0, 0.8, 0), 0.8],
	"legs": [Vector3(0.0, 0.05, 1), Vector3(0, 0.3, 0), 0.85],
	"legs34": [Vector3(0.6, 0.15, 0.8), Vector3(0, 0.3, 0), 0.85],
	"legsB": [Vector3(0.0, 0.05, -1), Vector3(0, 0.3, 0), 0.85],
	"bow": [Vector3(1, 0.03, 0), Vector3(-0.2, 0.55, 0), 1.7],
	"wide": [Vector3(0.0, 0.1, 1), Vector3(0, 0.66, 0), 2.6],
	"wide34": [Vector3(0.5, 0.2, 0.85), Vector3(0, 0.66, 0), 2.6],
	"top": [Vector3(0.0, 1, 0.02), Vector3(0, 0.3, 0), 1.6],
}

func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	var views: PackedStringArray = String(args.get("views", "front,back,left,q34")).split(",")
	var cell := String(args.get("cell", "480x640")).split("x")
	var cw := int(cell[0])
	var ch := int(cell[1])
	var out_path: String = args.get("out", "res://out/shot.png")
	var scene_path: String = args.get("scene", "res://scenes/archer.tscn")
	var anim: String = args.get("anim", "")
	var times: PackedStringArray = String(args.get("t", "0")).split(",")
	var fov := float(args.get("fov", "20"))

	var sv := SubViewport.new()
	sv.size = Vector2i(cw, ch)
	sv.msaa_3d = Viewport.MSAA_4X
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var st := Stage.build(sv)
	var cam: Camera3D = st["camera"]
	cam.fov = fov
	var packed: PackedScene = load(scene_path)
	var model: Node3D = packed.instantiate()
	sv.add_child(model)
	if args.has("wclass") and model.has_node("Skeleton3D/Body"):
		var fac: String = str(args.get("faction", "cyan"))
		var lk := {"wclass": "" if str(args["wclass"]) == "none" else str(args["wclass"]), "model": str(args.get("model", "ornate")), "color": str(args.get("color", fac)),
			"shield": args.has("shield"), "body": str(args.get("body", ""))}
		if args.has("hair"):
			lk["hair"] = Color(str(args["hair"]))
		if args.has("skin"):
			lk["skin"] = GC.skin_color_of(str(args["skin"]))
		UnitSkin.apply(model, lk, fac)
		# props=P_hunter_rod：把动作道具也显示出来(看钓鱼之类的动作)
		for pr: String in str(args.get("props", "")).split(",", false):
			var pm: MeshInstance3D = model.get_node_or_null("Skeleton3D/" + pr) as MeshInstance3D
			if pm != null:
				pm.visible = true
				UnitSkin.tint(pm, fac)
	var ap: AnimationPlayer = model.get_node_or_null("AnimationPlayer")
	if ap and args.has("lib"):
		# 用另一份动画库(build_anims 的 out= 产物)预览还没进正式库的动画
		ap.remove_animation_library("")
		ap.add_animation_library("", load(str(args["lib"])))
	if ap:
		ap.autoplay = ""
		ap.stop()

	var imgs: Array = []
	await process_frame
	await process_frame
	# 每个 (view, t) 组合一张
	for tstr in times:
		if ap and anim != "":
			ap.play(anim)
			ap.seek(float(tstr), true)
			ap.pause()
		for v in views:
			var cfg: Array
			if v == "custom":
				var d: PackedStringArray = String(args.get("dir", "0,0,1")).split(",")
				var tg: PackedStringArray = String(args.get("target", "0,0.66,0")).split(",")
				cfg = [Vector3(float(d[0]), float(d[1]), float(d[2])), Vector3(float(tg[0]), float(tg[1]), float(tg[2])), float(args.get("h", "1.7"))]
			elif VIEWS.has(v):
				cfg = VIEWS[v]
			else:
				cfg = VIEWS["front"]
			var dir: Vector3 = (cfg[0] as Vector3).normalized()
			var tgt: Vector3 = cfg[1]
			var dist: float = float(cfg[2]) / (2.0 * tan(deg_to_rad(fov * 0.5)))
			cam.position = tgt + dir * dist
			cam.look_at(tgt, Vector3.UP)
			for i in 4:
				await process_frame
			imgs.append(sv.get_texture().get_image())

	var cols := imgs.size()
	if args.has("cols"):
		cols = int(args["cols"])
	var rows := int(ceil(float(imgs.size()) / float(cols)))
	var sheet := Image.create(cw * cols, ch * rows, false, Image.FORMAT_RGB8)
	for i in imgs.size():
		var im: Image = imgs[i]
		im.convert(Image.FORMAT_RGB8)
		sheet.blit_rect(im, Rect2i(0, 0, cw, ch), Vector2i((i % cols) * cw, (i / cols) * ch))
	sheet.save_png(out_path)
	print("saved ", out_path, " ", sheet.get_size())
	quit()
