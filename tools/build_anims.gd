extends SceneTree
## 烘焙动画库：对 anim_defs 中每个动画做 FK/IK + 弹簧骨模拟，逐帧(30fps)写入 Animation。
## 用法: godot --path . --script res://tools/build_anims.gd -- [only=idle,walk] [out=res://out/anim_dev.res]
##   out=：另存到别的文件(在正式动画库的基础上叠加 only 里的动画)，预览时 shot.gd 用 lib= 读它，不动正式库
const Rig = preload("res://tools/rig.gd")
const Lib = preload("res://tools/anim_lib.gd")
const Defs = preload("res://tools/anim_chars.gd")     # 基础动作 ⊂ 持械动作(anim_combat) ⊂ 棋子专属动作(anim_chars)

const FPS := 30.0
const POS_BONES := ["Root", "Hips", "Chest", "Halo", "Eyelid_L", "Eyelid_R", "Bow_Nock", "Arrow"]
const SCL_BONES := ["Eyelid_L", "Eyelid_R", "Arrow", "Bow", "Weapon_L", "Shield"]   # 武器骨缩到 0 = 收起武器
## 只在这个动作真的缩放了它们时才写缩放轨道(忧郁的余烬的伞盖脉动 = Head、暴食的余烬的呼吸 = Spine、虚荣的余烬 = Chest)，
## 免得每个动作都多三条逐帧的缩放轨道
const SCL_BONES_IF_USED := ["Head", "Spine", "Chest"]
## 只在这个动作真的平移了它们时才写位置轨道：武器骨钉在世界里不跟手走(屏息节点跪姿换弹：枪搁在箱子上，右手去拉栓)
const POS_BONES_IF_USED := ["Bow"]

var rig
var defs


func _init() -> void:
	var t0 := Time.get_ticks_msec()
	var only := PackedStringArray()
	var out_path := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5).split(",")
		if a.begins_with("out="):
			out_path = a.substr(4)
	rig = Rig.new()
	rig.build()
	defs = Defs.new(rig)
	var lib := AnimationLibrary.new()
	var path := "res://assets/archer_anims.res"
	if only.size() > 0 and ResourceLoader.exists(path):
		var old: AnimationLibrary = load(path)
		for nm in old.get_animation_list():
			lib.add_animation(nm, old.get_animation(nm).duplicate())
	var tbl: Dictionary = defs.table()
	for nm in tbl:
		if only.size() > 0 and not (nm in only):
			continue
		var t1 := Time.get_ticks_msec()
		var anim := bake(nm, tbl[nm])
		if lib.has_animation(nm):
			lib.remove_animation(nm)
		lib.add_animation(nm, anim)
		print("baked ", nm, "  dur=", tbl[nm]["dur"], "  tracks=", anim.get_track_count(), "  (", Time.get_ticks_msec() - t1, " ms)")
	if out_path != "":
		path = out_path
	ResourceSaver.save(lib, path, ResourceSaver.FLAG_COMPRESS)
	print("saved ", path, "  total ", Time.get_ticks_msec() - t0, " ms")
	quit()


func make_chains() -> Array:
	var g0: Array = []
	var g1: Array = []
	for col in ["C", "L", "R"]:
		var names: Array = []
		for i in range(1, 8):
			names.append("Tail" + col + str(i))
		names.append("Tail" + col + "End")
		var c = Lib.make_chain(rig, names, 9.0, 0.30, 650.0, 0)
		c.wall_z = -8.5
		c.wall_y0 = 30.0
		c.wall_y1 = 78.0
		c.limit_deg = 15.0
		c.world_hold = 0.75
		g0.append(c)
	for s in ["L", "R"]:
		var c1 = Lib.make_chain(rig, ["SideLock_" + s + "1", "SideLock_" + s + "2", "SideLock_" + s + "3", "SideLock_" + s + "End"], 12.0, 0.32, 650.0, 0)
		c1.limit_deg = 20.0
		c1.world_hold = 0.6
		g0.append(c1)
		var c2 = Lib.make_chain(rig, ["EarDrop_" + s + "1", "EarDrop_" + s + "End"], 10.0, 0.42, 700.0, 0)
		c2.limit_deg = 28.0
		c2.world_hold = 0.85
		g0.append(c2)
		var c3 = Lib.make_chain(rig, ["Panel_" + s + "1", "Panel_" + s + "2", "Panel_" + s + "3", "Panel_" + s + "End"], 14.0, 0.35, 600.0, 0)
		c3.limit_deg = 16.0
		c3.world_hold = 0.25
		g0.append(c3)
		var c4 = Lib.make_chain(rig, ["Dangle_" + s + "1", "Dangle_" + s + "2", "Dangle_" + s + "End"], 10.0, 0.4, 700.0, 0)
		c4.limit_deg = 26.0
		c4.world_hold = 0.85
		g0.append(c4)
		var c5 = Lib.make_chain(rig, ["ATassel_" + s + "1", "ATassel_" + s + "End"], 9.0, 0.4, 700.0, 0)
		c5.limit_deg = 30.0
		c5.world_hold = 0.8
		g0.append(c5)
		var d1 = Lib.make_chain(rig, ["PTassel_" + s + "1", "PTassel_" + s + "End"], 9.0, 0.4, 700.0, 1)
		d1.limit_deg = 28.0
		d1.world_hold = 0.85
		g1.append(d1)
		var d2 = Lib.make_chain(rig, ["PTassel2_" + s + "1", "PTassel2_" + s + "End"], 9.0, 0.4, 700.0, 1)
		d2.limit_deg = 28.0
		d2.world_hold = 0.85
		g1.append(d2)
	# 兽尾：保持形状为主(world_hold 高)，跑动时甩
	var bt = Lib.make_chain(rig, ["BTail1", "BTail2", "BTail3", "BTail4", "BTail5", "BTailEnd"], 11.0, 0.36, 500.0, 0)
	bt.limit_deg = 18.0
	bt.world_hold = 0.7
	g0.append(bt)
	# 披风三列：垂坠感更强(world_hold 低)，不许飘进后背
	for cn: String in ["CapeC", "Cape_L", "Cape_R"]:
		var cc = Lib.make_chain(rig, [cn + "1", cn + "2", cn + "3", cn + "4", cn + "End"], 13.0, 0.36, 650.0, 0)
		cc.limit_deg = 15.0
		cc.world_hold = 0.3
		cc.wall_z = -6.0
		cc.wall_y0 = 18.0
		cc.wall_y1 = 68.0
		g0.append(cc)
	return [g0, g1]


## 妖精翅膀扑动：绕 Y 轴向后收拢/展开 + 轻微上下扇动。循环动画取整数个周期，保证首尾衔接
func _wing_flutter(t: float, dur: float, loop: bool, pose, hz: float = 1.4, amp: float = 1.0) -> void:
	if not rig.ids.has("Wing_L"):
		return
	var f: float = (maxf(1.0, roundf(dur * hz)) / dur) if loop else hz
	var a: float = sin(TAU * f * t)
	var fold: float = deg_to_rad(10.0 + 12.0 * amp * a)
	var flap: float = deg_to_rad(5.0 * amp * a)
	pose.rot[rig.ids["Wing_L"]] = Quaternion(Vector3.UP, fold) * Quaternion(Vector3.BACK, flap)
	pose.rot[rig.ids["Wing_R"]] = Quaternion(Vector3.UP, -fold) * Quaternion(Vector3.BACK, -flap)


func bake(nm: String, def: Dictionary) -> Animation:
	var dur: float = def["dur"]
	var loop: bool = def["loop"]
	var fn: Callable = def["fn"]
	# 表里可以给单个动作指定更高的烘焙帧率(fps: 60)：极快的连斩 30 帧采样时一帧就转 100° 以上，播放时帧间插值会乱甩
	var fps: float = float(def.get("fps", FPS))
	var stride: int = maxi(1, int(round(60.0 / fps)))
	var frames := int(round(dur * fps))
	var dt := 1.0 / 60.0
	var warm_steps := int(round(60.0 * dur * 4.0)) if loop else 60
	var total_steps := frames * stride
	var pose = Lib.Pose.new(rig)
	var chain_groups: Array = make_chains()
	var rec_rot: Array = []
	var rec_off: Array = []
	var rec_scl: Array = []
	var first := true
	for s in range(-warm_steps, total_steps + 1):
		var tm := float(s) * dt
		var te := tm if loop else maxf(tm, 0.0)
		pose.reset()
		fn.call(te, pose)
		if not bool(def.get("wing_custom", false)):
			_wing_flutter(te, dur, loop, pose, float(def.get("wing_hz", 1.4)), float(def.get("wing_amp", 1.0)))
		if first:
			pose.fk()
			for grp in chain_groups:
				for c in grp:
					Lib.chain_init(pose, c)
			first = false
		for c in chain_groups[0]:
			Lib.chain_step(pose, c, dt)
		pose.fk()
		for c in chain_groups[1]:
			Lib.chain_step(pose, c, dt)
		if s >= 0 and s % stride == 0:
			rec_rot.append(pose.rot.duplicate())
			rec_off.append(pose.off.duplicate())
			rec_scl.append(pose.scl.duplicate())

	# 循环动画：最后几帧向第 0 帧渐变，消除弹簧模拟的接缝
	if loop:
		var B := 8
		var last := frames
		for f in range(last - B, last + 1):
			var w := Lib.smooth(float(f - (last - B)) / float(B))
			for i in range(rig.names.size()):
				var q0: Quaternion = rec_rot[0][i]
				var q1: Quaternion = rec_rot[f][i]
				rec_rot[f][i] = q1.slerp(q0, w)

	if OS.get_cmdline_user_args().has("debug=1"):
		for f in range(0, rec_rot.size(), 3):
			var line := "f%02d " % f
			for k in range(1, 8):
				var q: Quaternion = rec_rot[f][rig.ids["TailC" + str(k)]]
				line += " %5.1f" % rad_to_deg(q.get_angle())
			print(line)
	# ---- 质检：循环接缝误差、逐帧最大跳变
	var seam := 0.0
	var max_step := 0.0
	var max_step_bone := ""
	var max_step_frame := 0
	for i in range(rig.names.size()):
		if loop:
			var qa: Quaternion = rec_rot[0][i]
			var qb: Quaternion = rec_rot[frames][i]
			seam = maxf(seam, rad_to_deg(qa.angle_to(qb)))
		for f in range(1, rec_rot.size()):
			var q0: Quaternion = rec_rot[f - 1][i]
			var q1: Quaternion = rec_rot[f][i]
			var d := rad_to_deg(q0.angle_to(q1))
			if d > max_step:
				max_step = d
				max_step_bone = rig.names[i]
				max_step_frame = f
	print("  QA ", nm, ": seam=%.2f deg  max frame step=%.1f deg (%s @f%d)" % [seam, max_step, max_step_bone, max_step_frame])
	var anim := Animation.new()
	anim.length = float(frames) / fps
	anim.step = 1.0 / fps
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var rest_local: PackedVector3Array = pose.rest_local
	for i in range(rig.names.size()):
		if rig.leaf[i] == 1:
			continue
		var bname: String = rig.names[i]
		var path := NodePath("Skeleton3D:" + bname)
		# 旋转轨道
		var constant := true
		var q_ref: Quaternion = rec_rot[0][i]
		for f in range(1, rec_rot.size()):
			var qf: Quaternion = rec_rot[f][i]
			if absf(qf.dot(q_ref)) < 0.9999999:
				constant = false
				break
		var tr := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(tr, path)
		anim.track_set_interpolation_type(tr, Animation.INTERPOLATION_LINEAR)
		if constant:
			anim.rotation_track_insert_key(tr, 0.0, q_ref)
		else:
			var prev_q: Quaternion = q_ref
			for f in range(rec_rot.size()):
				var q: Quaternion = rec_rot[f][i]
				if q.dot(prev_q) < 0.0:
					q = -q
				prev_q = q
				anim.rotation_track_insert_key(tr, float(f) / fps, q)
		# 位置轨道
		var pos_used: bool = bname in POS_BONES
		if not pos_used and bname in POS_BONES_IF_USED:
			for f1 in range(rec_off.size()):
				if (rec_off[f1][i] as Vector3).length() > 0.001:
					pos_used = true
					break
		if pos_used:
			var tp := anim.add_track(Animation.TYPE_POSITION_3D)
			anim.track_set_path(tp, path)
			anim.track_set_interpolation_type(tp, Animation.INTERPOLATION_LINEAR)
			for f in range(rec_off.size()):
				var pv: Vector3 = (rest_local[i] + rec_off[f][i]) * Lib.VOX
				anim.position_track_insert_key(tp, float(f) / fps, pv)
		# 缩放轨道
		var scl_used := false
		if bname in SCL_BONES_IF_USED:
			for f0 in range(rec_scl.size()):
				if not (rec_scl[f0][i] as Vector3).is_equal_approx(Vector3.ONE):
					scl_used = true
					break
		if bname in SCL_BONES or scl_used:
			var ts := anim.add_track(Animation.TYPE_SCALE_3D)
			anim.track_set_path(ts, path)
			anim.track_set_interpolation_type(ts, Animation.INTERPOLATION_LINEAR)
			for f in range(rec_scl.size()):
				anim.scale_track_insert_key(ts, float(f) / fps, rec_scl[f][i])
	return anim
