extends SceneTree
## 背后灵预览(守林节点)：三个守林节点并排(狮子 / 巨蛛 / 巨蟾形态)，各自身后的灵体；times= 截几张拼一张表，attack= 秒数时让灵体扑向前方。
## godot --path . --script res://tools/spirit_probe.gd -- [theme=white|red] [times=1.0,1.5,1.62,1.75,1.9] [attack=1.4] [yaw=150 pitch=24 dist=9]
##   [kinds=lion,spider,toad] [cell=960x540] [out=res://out/spirit_probe.png]
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cell := String(args.get("cell", "960x540")).split("x")
	var sv := SubViewport.new()
	sv.size = Vector2i(int(cell[0]), int(cell[1]))
	sv.msaa_3d = Viewport.MSAA_4X
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var world := GameWorld.new()
	sv.add_child(world)
	await process_frame
	await process_frame
	var cat := Catalog.load_all()
	world.show_battlefield({"theme": str(args.get("theme", "white")), "obstacles": [], "embers": [], "burning": []}, 5)
	var d: UnitDef = cat.get_unit("node_warden")
	var kinds: PackedStringArray = str(args.get("kinds", "lion,spider,toad")).split(",")
	var cx: float = 6.0
	var spirits: Array = []
	for i in range(kinds.size()):
		var v := UnitView.new()
		world.battle_root.add_child(v)
		v.setup(d, 2, 0, false, cat.get_equipment("basic_polearm"))
		v.position = Vector3(cx + (float(i) - float(kinds.size() - 1) * 0.5) * 3.2, 0.0, 0.0)
		v.rotation.y = 0.0
		v.set_bar_visible(false)
		v.set_beast_form(kinds[i])
		var bs: BeastSpirit = BeastSpirit.create(kinds[i], v, null)
		world.add_child(bs)
		spirits.append(bs)
	world.rig.set_view(Vector3(cx, 1.0, 0.0), float(args.get("yaw", "150")), float(args.get("pitch", "24")), float(args.get("dist", "9")), true)
	var times: PackedStringArray = str(args.get("times", "1.0,1.5,1.62,1.75,1.9,2.4")).split(",")
	var t_atk: float = float(args.get("attack", "1.4"))
	var imgs: Array = []
	var el := 0.0
	var ti := 0
	var attacked := false
	while ti < times.size():
		await process_frame
		el += 1.0 / 60.0
		if not attacked and el >= t_atk:
			attacked = true
			for bs2: Variant in spirits:
				var b: BeastSpirit = bs2
				b.attack(b.follow.global_position + Vector3(0.0, 0.8, 2.6), 0.25)
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
	sheet.save_png(str(args.get("out", "res://out/spirit_probe.png")))
	print("saved spirit probe")
	quit()
