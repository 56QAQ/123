extends SceneTree
## 调试：直接调用动画定义函数(不经烘焙)，打印指定时刻若干骨骼的世界位置/朝向，外加每帧骨骼跳变最大的地方。
## godot --path . --script res://tools/pose_probe.gd -- anim=draw_bow_hold t=0,0.5 bones=Head,Hand_L,Hand_R,Bow [steps=1]
const Rig = preload("res://tools/rig.gd")
const Lib = preload("res://tools/anim_lib.gd")
const Defs = preload("res://tools/anim_chars.gd")


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var rig = Rig.new()
	rig.build()
	var defs = Defs.new(rig)
	var tbl: Dictionary = defs.table()
	var nm: String = str(args.get("anim", "idle"))
	var fn: Callable = tbl[nm]["fn"]
	var p = Lib.Pose.new(rig)
	for ts: String in str(args.get("t", "0")).split(","):
		p.reset()
		fn.call(float(ts), p)
		p.fk()
		var line := "t=%s" % ts
		for b: String in str(args.get("bones", "Head,Hand_L,Hand_R")).split(","):
			var i: int = rig.ids[b]
			var fwd: Vector3 = p.gx[i].basis.z.normalized()
			line += "  %s pos%s fwd%s up%s" % [b, str(p.gpos_n(b).snapped(Vector3(0.1, 0.1, 0.1))), str(fwd.snapped(Vector3(0.01, 0.01, 0.01))), str(p.gx[i].basis.y.normalized().snapped(Vector3(0.01, 0.01, 0.01)))]
		print(line)
	if args.has("steps"):
		var dur: float = float(tbl[nm]["dur"])
		var prev: Array = []
		for f in range(int(round(dur * 30.0)) + 1):
			p.reset()
			fn.call(float(f) / 30.0, p)
			var worst := 0.0
			var wb := ""
			if not prev.is_empty():
				for i2 in range(rig.names.size()):
					var d: float = rad_to_deg((p.rot[i2] as Quaternion).angle_to(prev[i2]))
					if d > worst:
						worst = d
						wb = rig.names[i2]
			prev = p.rot.duplicate()
			print("  f%02d worst step %.1f %s" % [f, worst, wb])
	quit()
