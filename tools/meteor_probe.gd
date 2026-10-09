extends SceneTree
## 火流星预览(灾星节点)：空场地上丢几颗流星，按 times= 截几张拼成一张表(看下落 / 拖尾 / 预警 / 爆炸)。
## godot --path . --script res://tools/meteor_probe.gd -- [kind=staff|na] [n=4 颗] [theme=white|red] [times=0.2,0.45,0.7,0.8,0.95,1.3]
##   [pitch=56 dist=13 yaw=0 战斗镜头] [cell=720x480] [out=res://out/meteor_probe.png] [stagger=0.25 流星爆魔杖一颗接一颗的间隔]
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cell := String(args.get("cell", "720x480")).split("x")
	var sv := SubViewport.new()
	sv.size = Vector2i(int(cell[0]), int(cell[1]))
	sv.msaa_3d = Viewport.MSAA_4X
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var world := GameWorld.new()
	sv.add_child(world)
	await process_frame
	await process_frame
	world.show_battlefield({"theme": str(args.get("theme", "white")), "obstacles": [], "embers": [], "burning": []}, 5)
	var fx := Fx.new()
	world.add_child(fx)
	var kind: String = str(args.get("kind", "staff"))
	var n: int = int(args.get("n", "4"))
	var cx: float = 6.0
	world.rig.set_view(Vector3(cx, 0.4, 0.0), float(args.get("yaw", "0")), float(args.get("pitch", "56")), float(args.get("dist", "13")), true)
	var stagger: float = float(args.get("stagger", "0.25"))
	for i in range(n):
		var a: float = TAU * float(i) / float(n) + 0.4
		var p := Vector3(cx + cos(a) * 1.8, 0.4 if kind == "staff" else 0.5, sin(a) * 1.8)
		if kind == "staff":
			var dl: float = stagger * float(i)
			if dl <= 0.0:
				fx.meteor(p, 0.7, Color("#ff4a26"), 2.0, 1.4)
			else:
				create_timer(dl).timeout.connect(fx.meteor.bind(p, 0.7, Color("#ff4a26"), 2.0, 1.4))
		else:
			fx.meteor(p, 0.45, Color("#ff7a2a"), 1.0, 0.6)
	var times: PackedStringArray = str(args.get("times", "0.2,0.45,0.7,0.8,0.95,1.3")).split(",")
	var imgs: Array = []
	var el := 0.0
	var ti := 0
	while ti < times.size():
		await process_frame
		el += 1.0 / 60.0
		if el >= float(times[ti]):
			imgs.append(sv.get_texture().get_image())
			ti += 1
	var w: int = sv.size.x
	var h: int = sv.size.y
	var cols: int = mini(3, imgs.size())
	var rows: int = (imgs.size() + cols - 1) / cols
	var sheet := Image.create(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	for i in range(imgs.size()):
		var im: Image = imgs[i]
		im.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	sheet.save_png(str(args.get("out", "res://out/meteor_probe.png")))
	print("saved meteor probe")
	quit()
