extends SceneTree
## 世界模型展示：把 assets/world/ 里的若干模型排成一排(或网格)离屏渲染，旁边放一辆卡车和一个棋子当比例尺。
## 用法: godot --path . --script res://tools/world_shot.gd --quit-after 3000 -- names=ash_car,burn_house out=res://out/world.png
##   [night=1(红之章夜景灯光)] [cols=5] [gap=4.5(米)] [size=1600x900] [dist=..] [pitch=..] [yaw=..] [truck=0] [unit=0]
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	var sz := String(args.get("size", "1600x900")).split("x")
	var sv := SubViewport.new()
	sv.size = Vector2i(int(sz[0]), int(sz[1]))
	sv.msaa_3d = Viewport.MSAA_4X
	sv.own_world_3d = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var night: bool = str(args.get("night", "0")) == "1"
	var w := Node3D.new()
	sv.add_child(w)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#140b0a") if night else Color("#cfd6df")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#6b4a52") if night else Color("#eeeae4")
	env.ambient_light_energy = 0.55 if night else 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = night
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05
	var we := WorldEnvironment.new()
	we.environment = env
	w.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 0.35 if night else 1.1
	sun.light_color = Color("#9fb0ff") if night else Color.WHITE
	sun.shadow_enabled = true
	w.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("#2a2726") if night else Color("#d8d4cc")
	gm.roughness = 0.9
	ground.material_override = gm
	w.add_child(ground)
	var names: PackedStringArray = String(args.get("names", "truck")).split(",")
	var cols: int = int(args.get("cols", "5"))
	var gap: float = float(args.get("gap", "4.5"))
	var rows: int = int(ceil(float(names.size()) / float(cols)))
	for i in range(names.size()):
		var mi := MeshInstance3D.new()
		mi.mesh = load("res://assets/world/%s.res" % names[i]) as Mesh
		var cx: int = i % cols
		var rz: int = i / cols
		mi.position = Vector3((float(cx) - float(mini(cols, names.size()) - 1) * 0.5) * gap, 0, (float(rz) - float(rows - 1) * 0.5) * gap)
		w.add_child(mi)
		if night and (names[i].begins_with("burn_") or names[i].begins_with("bld_")):
			var lt := OmniLight3D.new()
			lt.light_color = Color("#ff7a2a")
			lt.light_energy = 2.0
			lt.omni_range = 4.0
			lt.position = mi.position + Vector3(0, 1.0, 0)
			w.add_child(lt)
	var span: float = maxf(float(mini(cols, names.size())) * gap, float(rows) * gap)
	if str(args.get("truck", "1")) == "1":
		var tr := MeshInstance3D.new()
		tr.mesh = load("res://assets/world/truck.res") as Mesh
		tr.position = Vector3(-span * 0.5 - 3.0, 0, 0)
		w.add_child(tr)
	var cam := Camera3D.new()
	var dist: float = float(args.get("dist", str(span * 0.95 + 6.0)))
	var pitch: float = deg_to_rad(float(args.get("pitch", "38")))
	var yaw: float = deg_to_rad(float(args.get("yaw", "-20")))
	var tgt := Vector3(float(args.get("tx", "-1.5")), float(args.get("ty", "0.8")), 0)
	cam.position = tgt + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	cam.fov = 40
	w.add_child(cam)
	cam.look_at_from_position(cam.position, tgt, Vector3.UP)
	cam.current = true
	for k in range(int(args.get("frames", "30"))):
		await process_frame
	sv.get_texture().get_image().save_png(String(args.get("out", "res://out/world.png")))
	print("saved ", args.get("out", "res://out/world.png"))
	quit()
