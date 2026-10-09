extends SceneTree
## 武器预览图：每一行一个武器大类，每一列是动作的一个时刻(或一个视角)，用来目测持械姿态/攻击动作。
## godot --path . --script res://tools/weapon_shot.gd -- kind=attack t=0,0.3,0.45,1 view=q34 model=plain out=res://out/w.png
##   kind   idle | run | attack | 动画名(如 attack_heavy_whirl / reload_rifle)
##   t      动作时刻：<=1 视为占动画时长的比例，>1 视为秒
##   view   q34 | front | side | back | top
##   classes 逗号分隔(默认全部 9 类)
const Stage = preload("res://scripts/stage.gd")

const VIEWS := {
	"q34": Vector3(0.62, 0.2, 0.75), "front": Vector3(0, 0.05, 1), "side": Vector3(-1, 0.05, 0.02),
	"sideL": Vector3(1, 0.05, 0.02), "back": Vector3(0.3, 0.2, -1), "top": Vector3(0.3, 1.0, 0.4),
}


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	var kind: String = str(args.get("kind", "idle"))
	var times: PackedStringArray = str(args.get("t", "0")).split(",")
	var views: PackedStringArray = str(args.get("view", "q34")).split(",")
	var model_kind: String = str(args.get("model", "ornate"))
	var classes: PackedStringArray = str(args.get("classes", ",".join(GC.WEAPON_CLASS_IDS))).split(",")
	var cw := 300
	var ch := 340
	if args.has("cell"):
		var c: PackedStringArray = str(args["cell"]).split("x")
		cw = int(c[0])
		ch = int(c[1])
	var out_path: String = str(args.get("out", "res://out/weapons.png"))
	var sv := SubViewport.new()
	sv.size = Vector2i(cw, ch)
	sv.msaa_3d = Viewport.MSAA_4X
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var st := Stage.build(sv)
	var cam: Camera3D = st["camera"]
	cam.fov = 26.0
	var model: Node3D = (load("res://scenes/unit_model.tscn") as PackedScene).instantiate()
	sv.add_child(model)
	var ap: AnimationPlayer = model.get_node("AnimationPlayer")
	ap.autoplay = ""
	var imgs: Array = []
	var cols: int = times.size() * views.size()
	await process_frame
	for cls: String in classes:
		var look := {"wclass": cls, "model": model_kind, "color": str(args.get("color", "cyan")), "shield": args.has("shield")}
		if cls == "unarmed":
			look["wclass"] = ""
		UnitSkin.apply(model, look, str(args.get("faction", "red")))
		var nm: String = kind if ap.has_animation(kind) else UnitSkin.anim(look, kind)     # kind 也可以直接写动画名(如 attack_heavy_whirl)
		for ts: String in times:
			var tt: float = float(ts)
			if ap.has_animation(nm):
				var L: float = ap.get_animation(nm).length
				ap.play(nm)
				ap.seek(tt * L if tt <= 1.0 else tt, true)
				ap.pause()
			for v: String in views:
				var dir: Vector3 = (VIEWS.get(v, VIEWS["q34"]) as Vector3).normalized()
				var tgt := Vector3(0, 0.7, 0.15)
				var dist: float = 2.0 / (2.0 * tan(deg_to_rad(cam.fov * 0.5)))
				cam.position = tgt + dir * dist
				cam.look_at(tgt, Vector3.UP)
				for i in 3:
					await process_frame
				var im: Image = sv.get_texture().get_image()
				im.convert(Image.FORMAT_RGB8)
				imgs.append(im)
	var rows: int = classes.size()
	var sheet := Image.create(cw * cols, ch * rows, false, Image.FORMAT_RGB8)
	for i in imgs.size():
		sheet.blit_rect(imgs[i], Rect2i(0, 0, cw, ch), Vector2i((i % cols) * cw, (i / cols) * ch))
	sheet.save_png(out_path)
	print("saved ", out_path, " ", sheet.get_size())
	quit()
