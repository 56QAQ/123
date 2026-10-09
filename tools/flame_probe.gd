extends SceneTree
## 武器火(狩胜节点·光荣)的预览：一排狩胜节点站着待机，每个手里的武器挂着不同层数的火(WeaponFlame)，镜头从侧面拍一张。
## godot --path . --script res://tools/flame_probe.gd -- [levels=0,3,5,8,10] [wclass=polearm] [theme=white|red] [out=res://out/flame_probe.png]
##   [unit=node_gladiator] [t=1.6 截图前等几秒(让火烧起来)] [cell=1600x600] [yaw=90] [pitch=14] [dist=7.5]
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cell := String(args.get("cell", "1600x600")).split("x")
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
	var d: UnitDef = cat.get_unit(str(args.get("unit", "node_gladiator")))
	var wc: String = str(args.get("wclass", "polearm"))
	var levels: PackedStringArray = str(args.get("levels", "0,3,5,8,10")).split(",", false)
	var gap: float = float(args.get("gap", "1.6"))
	var flames: Array = []
	for i in range(levels.size()):
		var v := UnitView.new()
		world.battle_root.add_child(v)
		v.setup(d, 2, 0, false, cat.get_equipment("basic_" + wc))
		v.position = Vector3(float(args.get("x", "6")), 0.0, (float(i) - float(levels.size() - 1) * 0.5) * gap)         # 离开卡车(在原点)
		v.rotation.y = 0.0                                 # 朝 +Z(沿着这一排)：镜头从侧面看，武器横在画面里
		v.set_bar_visible(false)
		var wf: WeaponFlame = WeaponFlame.create(v, wc)
		v.add_child(wf)
		wf.set_level(int(levels[i]), 10)
		flames.append(wf)
	world.rig.set_view(Vector3(float(args.get("x", "6")), 0.8, 0.0), float(args.get("yaw", "90")), float(args.get("pitch", "14")), float(args.get("dist", "7.5")), true)
	var el := 0.0
	var t_wait: float = float(args.get("t", "1.6"))
	while el < t_wait:
		await process_frame
		el += 1.0 / 60.0
	for wf0: Variant in flames:
		var wfx: WeaponFlame = wf0
		if not wfx._parts.is_empty():
			var hd: Node3D = wfx._parts[0]["holder"]
			var gl: Node3D = wfx._parts[0]["glow"]
			print("PROBE lvl=%d view=%s holder=%s hscale=%s glowscale=%s" % [wfx.level, str(wfx.view.global_position), str(hd.global_position), str(hd.global_transform.basis.get_scale()), str(gl.global_transform.basis.get_scale())])
	var img: Image = sv.get_texture().get_image()
	img.save_png(str(args.get("out", "res://out/flame_probe.png")))
	print("saved flame probe")
	quit()
