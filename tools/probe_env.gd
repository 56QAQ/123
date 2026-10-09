extends SceneTree
func _init() -> void:
	var sv := SubViewport.new()
	sv.size = Vector2i(900, 600)
	sv.msaa_3d = Viewport.MSAA_4X
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var world := GameWorld.new()
	sv.add_child(world)
	await process_frame
	await process_frame
	var cat := Catalog.load_all()
	var v := UnitView.new()
	world.units_layer.add_child(v)
	v.setup(cat.get_unit("node_darkknight"), 1, 0)
	v.position = Vector3(-1.5, 0, 0)
	v.rotation.y = 0.8
	var v2 := UnitView.new()
	world.units_layer.add_child(v2)
	v2.setup(cat.get_unit("node_archer"), 1, 1)
	v2.position = Vector3(1.0, 0, 0.6)
	v2.rotation.y = -0.8
	world.rig.g_target = Vector3(0, 0.5, 0)
	world.rig.g_dist = 7.0
	world.rig.g_pitch = 40.0
	world.rig.set_preset("prep", true)
	world.rig.g_target = Vector3(0, 0.5, 0.3)
	world.rig.g_dist = 6.5
	world.rig.g_pitch = 38.0
	world.rig.target = world.rig.g_target
	world.rig.dist = world.rig.g_dist
	world.rig.pitch = world.rig.g_pitch
	var imgs: Array = []
	var variants := [["default", func() -> void: pass],
		["no glow", func() -> void: world.env.glow_enabled = false],
		["no ssao", func() -> void:
			world.env.glow_enabled = true
			world.env.ssao_enabled = false],
		["no glow no ssao", func() -> void: world.env.glow_enabled = false]]
	for vr: Array in variants:
		(vr[1] as Callable).call()
		for i in range(6):
			await process_frame
		imgs.append(sv.get_texture().get_image())
	var sheet := Image.create(1800, 1200, false, Image.FORMAT_RGB8)
	for i in range(imgs.size()):
		var im: Image = imgs[i]
		im.convert(Image.FORMAT_RGB8)
		sheet.blit_rect(im, Rect2i(0, 0, 900, 600), Vector2i((i % 2) * 900, (i / 2) * 600))
	sheet.save_png("res://out/probe_env.png")
	quit()
