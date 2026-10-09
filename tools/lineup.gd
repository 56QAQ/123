extends SceneTree
## 怪物排排站：把一章的敌人(默认红之章全部 11 种)摆在这一章的真实战场上，用游戏里的战斗镜头截图——看"在上空分不分得出谁是谁"。
## godot --path . --script res://tools/lineup.gd -- [units=mob_ember_wrath,...] [chapter=ch1_red] [dist=25.5] [pitch=56] [yaw=0]
##   [cell=1920x1080] [gap=2.6] [t=1.5 截图前等几秒(让待机动作 / 光环转起来)] [out=res://out/lineup.png] [boss=boss_ember_dragon] [elite=elite_ember_vanity,…]
##   [anim=attack 让它们都播普攻(看攻击动作)] [seq=res://out/seq/l 逐帧存 PNG，t0/t1 秒]
const RED := ["mob_ember_wrath", "mob_ember_sloth", "mob_ember_lust", "mob_ember_glut", "mob_ember_envy", "mob_ember_greed",
	"elite_ember_vanity", "elite_ember_melancholy", "elite_ember_pride", "boss_ember_dragon"]


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var cell := String(args.get("cell", "1920x1080")).split("x")
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
	var run := Run.create(cat, int(args.get("seed", "5")), str(args.get("chapter", "ch1_red")))
	var layout: Dictionary = run.current_layout().duplicate(true)
	if layout.is_empty() or not args.has("keep"):
		layout = {"theme": str(args.get("theme", "red")), "obstacles": [], "embers": [], "burning": []}
	layout["obstacles"] = []
	world.show_battlefield(layout, 5)
	var ids: Array = str(args.get("units", ",".join(RED))).split(",", false)
	var gap: float = float(args.get("gap", "2.6"))
	var cols: int = int(args.get("cols", "5"))
	var views: Array = []
	for i in range(ids.size()):
		var d: UnitDef = cat.get_unit(str(ids[i]))
		if d == null:
			push_warning("no unit " + str(ids[i]))
			continue
		var v := UnitView.new()
		world.battle_root.add_child(v)
		var is_boss: bool = str(ids[i]).begins_with("boss_")
		v.setup(d, 1, 1, is_boss, cat.resolve_weapon(d, ""))
		if v.has_method("set_elite"):
			v.call("set_elite", str(ids[i]).begins_with("elite_"))
		var r: int = i / cols
		var c: int = i % cols
		var n_in_row: int = mini(cols, ids.size() - r * cols)
		v.position = Vector3((float(c) - float(n_in_row - 1) * 0.5) * gap, 0.0, float(args.get("z0", "-5.5")) - float(r) * gap * 1.25)
		v.rotation.y = 0.0                                 # 敌人朝我方(+Z = 镜头这边)，和战斗里一样露出正面
		v.set_bar_visible(args.has("bars"))
		views.append(v)
	await process_frame
	for v: UnitView in views:
		v.play_loop(str(args.get("anim", "idle")) if str(args.get("anim", "idle")) != "attack" else "idle")
	world.rig.set_view(Vector3(float(args.get("cx", "0")), 0.0, float(args.get("cz", "-5"))), float(args.get("yaw", "0")),
		float(args.get("pitch", "56")), float(args.get("dist", "25.5")), true)
	var t_wait: float = float(args.get("t", "1.5"))
	var el := 0.0
	var seq: String = str(args.get("seq", ""))
	var k := 0
	var next_atk := 0.0
	while el < t_wait:
		await process_frame
		el += 1.0 / 30.0
		if str(args.get("anim", "")) == "attack" and el >= next_atk:
			for v2: UnitView in views:
				v2.play_attack(1.0)
			next_atk = el + float(args.get("every", "1.4"))
		if seq != "" and el >= float(args.get("t0", "0")):
			var fr: Image = sv.get_texture().get_image()
			fr.convert(Image.FORMAT_RGB8)
			fr.save_png("%s_%03d.png" % [seq, k])
			k += 1
	if seq == "":
		var img: Image = sv.get_texture().get_image()
		img.convert(Image.FORMAT_RGB8)
		img.save_png(str(args.get("out", "res://out/lineup.png")))
		print("saved ", str(args.get("out", "res://out/lineup.png")))
	else:
		print("saved %d frames" % k)
	quit()
