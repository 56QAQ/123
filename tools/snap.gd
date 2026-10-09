extends SceneTree
## 把任意场景离屏渲染成 PNG。
## godot --path . --script res://tools/snap.gd -- scene=res://scenes/character_sheet.tscn out=res://out/sheet.png size=1122x1402 frames=90
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	var sz := String(args.get("size", "1280x800")).split("x")
	var sv := SubViewport.new()
	sv.size = Vector2i(int(sz[0]), int(sz[1]))
	sv.msaa_3d = Viewport.MSAA_4X
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var scene: Node = (load(String(args.get("scene", "res://scenes/main.tscn"))) as PackedScene).instantiate()
	sv.add_child(scene)
	var n := int(args.get("frames", "60"))
	for i in n:
		await process_frame
	sv.get_texture().get_image().save_png(String(args.get("out", "res://out/snap.png")))
	print("saved ", args.get("out", "res://out/snap.png"))
	quit()
