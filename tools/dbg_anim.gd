extends SceneTree
## 调试：打印指定动画里某些骨骼的欧拉角随帧变化。用法: -- anim=shoot bones=LowerArm_L,UpperArm_L from=0 to=30
func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	var lib: AnimationLibrary = load("res://assets/archer_anims.res")
	var anim: Animation = lib.get_animation(String(args.get("anim", "idle")))
	var bones: PackedStringArray = String(args.get("bones", "Head")).split(",")
	var f0 := int(args.get("from", "0"))
	var f1 := int(args.get("to", "30"))
	for f in range(f0, f1 + 1):
		var line: String = "f%02d" % f
		for b in bones:
			var tr := anim.find_track(NodePath("Skeleton3D:" + b), Animation.TYPE_ROTATION_3D)
			var q: Quaternion = anim.rotation_track_interpolate(tr, float(f) / 30.0)
			var qp: Quaternion = anim.rotation_track_interpolate(tr, float(maxi(f - 1, 0)) / 30.0)
			line += "  %s(step %.1f deg)" % [b, rad_to_deg(q.angle_to(qp))]
		print(line)
	quit()
