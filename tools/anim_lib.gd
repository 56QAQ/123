extends RefCounted
## 动画工具库：姿态(FK) / 双骨 IK / 弹簧骨二次运动 / 烘焙到 Animation。
## 约定：位置单位=体素；旋转为四元数(骨骼静止旋转均为单位)；角度输入用度。
## 坐标：+Y 上，+Z 前，角色左手侧 +X。绕 +X 正转 = 下垂肢体向后摆(-Z)；绕 +Y 正转 = 向左转；绕 +Z 正转 = 下垂肢体向 +X。

const VOX := 0.0125


# =============================================================== 姿态
class Pose:
	extends RefCounted
	var rig
	var n: int
	var rest_local: PackedVector3Array = PackedVector3Array()
	var parent: PackedInt32Array = PackedInt32Array()
	var rot: Array[Quaternion] = []
	var off: PackedVector3Array = PackedVector3Array()
	var scl: PackedVector3Array = PackedVector3Array()
	var gx: Array[Transform3D] = []
	var dirty: bool = true

	func _init(p_rig) -> void:
		rig = p_rig
		n = rig.names.size()
		parent = rig.parent
		rest_local.resize(n)
		for i in range(n):
			var p: int = parent[i]
			rest_local[i] = rig.pos[i] - (rig.pos[p] if p >= 0 else Vector3.ZERO)
		rot.resize(n)
		off.resize(n)
		scl.resize(n)
		gx.resize(n)
		reset()

	func reset() -> void:
		for i in range(n):
			rot[i] = Quaternion.IDENTITY
			off[i] = Vector3.ZERO
			scl[i] = Vector3.ONE
		if rig.ids.has("Arrow"):
			scl[rig.ids["Arrow"]] = Vector3.ONE * 0.001
		dirty = true

	func copy_from(o) -> void:
		for i in range(n):
			rot[i] = o.rot[i]
			off[i] = o.off[i]
			scl[i] = o.scl[i]
		dirty = true

	func idx(nm: String) -> int:
		return rig.ids[nm]

	## 设置局部欧拉角(度)。默认 YXZ 顺序
	func r(nm: String, x: float, y: float = 0.0, z: float = 0.0) -> void:
		rot[rig.ids[nm]] = Quaternion(Basis.from_euler(Vector3(deg_to_rad(x), deg_to_rad(y), deg_to_rad(z))))
		dirty = true

	## 在当前局部旋转上叠加(左乘，即在父空间中再转一次)
	func radd(nm: String, x: float, y: float = 0.0, z: float = 0.0) -> void:
		var i: int = rig.ids[nm]
		rot[i] = Quaternion(Basis.from_euler(Vector3(deg_to_rad(x), deg_to_rad(y), deg_to_rad(z)))) * rot[i]
		dirty = true

	func rq(nm: String, q: Quaternion) -> void:
		rot[rig.ids[nm]] = q
		dirty = true

	func move(nm: String, v: Vector3) -> void:
		off[rig.ids[nm]] = v
		dirty = true

	func madd(nm: String, v: Vector3) -> void:
		off[rig.ids[nm]] += v
		dirty = true

	func scale_(nm: String, v: Vector3) -> void:
		scl[rig.ids[nm]] = v

	func fk() -> void:
		if not dirty:
			return
		for i in range(n):
			var p: int = parent[i]
			var b := Basis(rot[i]).scaled(scl[i])
			var t := Transform3D(b, rest_local[i] + off[i])
			if p >= 0:
				gx[i] = gx[p] * t
			else:
				gx[i] = t
		dirty = false

	func gpos(i: int) -> Vector3:
		fk()
		return gx[i].origin

	func grot(i: int) -> Quaternion:
		fk()
		return Quaternion(gx[i].basis.orthonormalized())

	func gpos_n(nm: String) -> Vector3:
		return gpos(rig.ids[nm])

	func grot_n(nm: String) -> Quaternion:
		return grot(rig.ids[nm])

	func parent_grot(i: int) -> Quaternion:
		var p: int = parent[i]
		if p < 0:
			return Quaternion.IDENTITY
		return grot(p)

	## 直接指定某骨骼的世界旋转
	func set_grot(nm: String, q: Quaternion) -> void:
		var i: int = rig.ids[nm]
		rot[i] = parent_grot(i).inverse() * q
		dirty = true

	## 世界空间整体平移某骨骼(仅对根/髋等无父平移使用)
	func set_gpos_via_off(nm: String, target: Vector3) -> void:
		var i: int = rig.ids[nm]
		var p: int = parent[i]
		fk()
		var pt: Transform3D = gx[p] if p >= 0 else Transform3D.IDENTITY
		var local_target := pt.affine_inverse() * target
		off[i] = local_target - rest_local[i]
		dirty = true

	## 双骨 IK：root→mid→end，end 的世界位置(关节头)到达 target；pole 决定 mid 关节朝向(世界方向)
	func ik2(root_nm: String, mid_nm: String, end_nm: String, target: Vector3, pole: Vector3) -> void:
		var ri: int = rig.ids[root_nm]
		var mi: int = rig.ids[mid_nm]
		var ei: int = rig.ids[end_nm]
		fk()
		var A: Vector3 = gx[ri].origin
		var Rp := parent_grot(ri)
		var l1: float = rest_local[mi].length()
		var l2: float = rest_local[ei].length()
		var to_t := target - A
		var d := to_t.length()
		var u := Vector3.DOWN
		if d > 1e-5:
			u = to_t / d
		d = clampf(d, absf(l1 - l2) + 0.01, (l1 + l2) * 0.9995)
		var cos_a := (l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d)
		var sin_a := sqrt(maxf(0.0, 1.0 - cos_a * cos_a))
		var pv := pole - u * pole.dot(u)
		if pv.length() < 1e-4:
			pv = Vector3.FORWARD.cross(u)
			if pv.length() < 1e-4:
				pv = Vector3.RIGHT
		var v := pv.normalized()
		var M := A + (u * cos_a + v * sin_a) * l1
		var T := A + u * d
		# 起始朝向不取"从当前姿态转最短弧"(胳膊举过头顶时最短弧的转轴不确定，上臂会整个翻转 180°)，
		# 而是把静止时的"根→末端连线 + 屈曲方向(中间关节往哪边鼓：肘往后、膝往前)"对齐到"目标连线 + pole"：
		# 上臂/大腿的滚转由 pole 连续决定，关节始终绕解剖学上的铰链轴弯曲
		var L0: Vector3 = (rest_local[mi] + rest_local[ei]).normalized()
		var s0: Vector3 = Vector3(0, 0, 1) if root_nm.begins_with("Thigh") else Vector3(0, 0, -1)
		s0 = (s0 - L0 * s0.dot(L0)).normalized()
		var Brest := Basis(L0, s0, L0.cross(s0))
		var Btgt := Basis(u, v, u.cross(v))
		var Rg0 := Quaternion((Btgt * Brest.transposed()).orthonormalized())
		var cur1 := (Rg0 * rest_local[mi]).normalized()
		var want1 := (M - A).normalized()
		var Rg1 := Quaternion(cur1, want1) * Rg0
		rot[ri] = Rp.inverse() * Rg1
		var Rm0 := Rg1
		var cur2 := (Rm0 * rest_local[ei]).normalized()
		var want2 := (T - M).normalized()
		var Rm1 := Quaternion(cur2, want2) * Rm0
		rot[mi] = Rg1.inverse() * Rm1
		dirty = true

	## 朝向：让 bone 的 rest 子方向指向 target(单骨 aim)
	func aim(nm: String, child_nm: String, target: Vector3) -> void:
		var bi: int = rig.ids[nm]
		var ci: int = rig.ids[child_nm]
		fk()
		var Rp := parent_grot(bi)
		var Rg0 := Rp * rot[bi]
		var cur := (Rg0 * rest_local[ci]).normalized()
		var want := (target - gx[bi].origin).normalized()
		rot[bi] = Rp.inverse() * (Quaternion(cur, want) * Rg0)
		dirty = true


# =============================================================== 数学小工具
static func E(x: float, y: float = 0.0, z: float = 0.0) -> Quaternion:
	return Quaternion(Basis.from_euler(Vector3(deg_to_rad(x), deg_to_rad(y), deg_to_rad(z))))


static func basis_zy(zdir: Vector3, ydir: Vector3) -> Quaternion:
	var z := zdir.normalized()
	var x := ydir.cross(z).normalized()
	var y := z.cross(x)
	return Quaternion(Basis(x, y, z))


static func smooth(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func smoother(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


static func ease_out(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t)


static func ease_in(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * t


## 分段关键帧插值：keys = [[t, value], ...]，按 smooth 缓动；value 为 float
static func curve(keys: Array, t: float) -> float:
	if t <= float(keys[0][0]):
		return float(keys[0][1])
	for i in range(1, keys.size()):
		var t1: float = keys[i][0]
		if t <= t1:
			var t0: float = keys[i - 1][0]
			var a: float = keys[i - 1][1]
			var b: float = keys[i][1]
			return lerpf(a, b, smooth((t - t0) / maxf(t1 - t0, 1e-6)))
	return float(keys[keys.size() - 1][1])


static func curve_v(keys: Array, t: float) -> Vector3:
	if t <= float(keys[0][0]):
		return keys[0][1]
	for i in range(1, keys.size()):
		var t1: float = keys[i][0]
		if t <= t1:
			var t0: float = keys[i - 1][0]
			var a: Vector3 = keys[i - 1][1]
			var b: Vector3 = keys[i][1]
			return a.lerp(b, smooth((t - t0) / maxf(t1 - t0, 1e-6)))
	return keys[keys.size() - 1][1]


# =============================================================== 弹簧骨链
class Chain:
	extends RefCounted
	var bones: Array[int] = []
	var tails: Array[Vector3] = []       # 每节骨骼 rest 尾部偏移(局部)
	var lens: Array[float] = []
	var cur: Array[Vector3] = []
	var prev: Array[Vector3] = []
	var stiff: float = 8.0
	var drag: float = 0.06
	var grav: float = 120.0
	var group: int = 0
	var wall_z: float = -1e9           # 世界空间 z 上限(避免头发穿进身体)，仅当 y 落在 wall_y 范围内
	var wall_y0: float = 0.0
	var wall_y1: float = 0.0
	var limit_deg: float = 80.0        # 每节相对静止方向的最大偏角
	var world_hold: float = 0.0        # 0=完全跟随父骨骼朝向, 1=保持世界空间原始垂落方向
	var initialized: bool = false


## names：链上骨骼名(含末端 End 骨)。bones = 除最后一个外的全部；每节的尾部 = 下一节的静止偏移
static func make_chain(rig, names: Array, stiff: float, drag: float, grav: float, group: int = 0) -> Chain:
	var c := Chain.new()
	c.stiff = stiff
	c.drag = drag
	c.grav = grav
	c.group = group
	for k in range(names.size() - 1):
		var i: int = rig.ids[names[k]]
		var j: int = rig.ids[names[k + 1]]
		c.bones.append(i)
		var t: Vector3 = rig.pos[j] - rig.pos[i]
		c.tails.append(t)
		c.lens.append(t.length())
		c.cur.append(Vector3.ZERO)
		c.prev.append(Vector3.ZERO)
	return c


static func chain_init(pose: Pose, c: Chain) -> void:
	pose.fk()
	for k in range(c.bones.size()):
		var b: int = c.bones[k]
		var Hk: Vector3 = pose.gx[b].origin
		var Rk := Quaternion(pose.gx[b].basis.orthonormalized())
		c.cur[k] = Hk + Rk * c.tails[k]
		c.prev[k] = c.cur[k]
	c.initialized = true


static func chain_step(pose: Pose, c: Chain, dt: float) -> void:
	var b0: int = c.bones[0]
	var p0: int = pose.parent[b0]
	pose.fk()
	var Rp: Quaternion = Quaternion(pose.gx[p0].basis.orthonormalized()) if p0 >= 0 else Quaternion.IDENTITY
	var H: Vector3 = pose.gx[b0].origin
	var damp := pow(1.0 - c.drag, dt * 60.0)
	for k in range(c.bones.size()):
		var b: int = c.bones[k]
		var t_local: Vector3 = c.tails[k]
		var q_prim: Quaternion = pose.rot[b]
		var Rrest := Rp * q_prim
		var rest_dir_p := (Rrest * t_local).normalized()
		var rest_dir := rest_dir_p
		if c.world_hold > 0.0:
			var mix: Vector3 = rest_dir_p.lerp(t_local.normalized(), c.world_hold)
			# 父骨骼几乎倒过来(手臂举过头顶)时两个方向快抵消、方向不确定 → 用上一帧的方向稳住，不让流苏翻面
			if mix.length() < 0.35:
				var pd: Vector3 = c.cur[k] - H
				if pd.length() > 1e-4:
					mix += pd.normalized() * (0.35 - mix.length())
			rest_dir = mix.normalized()
		var target := H + rest_dir * c.lens[k]
		var vel := (c.cur[k] - c.prev[k]) * damp
		var nxt: Vector3 = c.cur[k] + vel + (target - c.cur[k]) * minf(c.stiff * dt, 0.9) + Vector3(0, -c.grav, 0) * dt * dt
		var dir := nxt - H
		if dir.length() < 1e-5:
			dir = target - H
		var nd := dir.normalized()
		# 偏角限制
		var ang := rest_dir.angle_to(nd)
		var lim := deg_to_rad(c.limit_deg)
		if ang > lim:
			var axis := rest_dir.cross(nd)
			if axis.length() > 1e-6:
				nd = rest_dir.rotated(axis.normalized(), lim)
		nxt = H + nd * c.lens[k]
		# 与背部平面碰撞
		if c.wall_z > -1e8 and nxt.y > c.wall_y0 and nxt.y < c.wall_y1 and nxt.z > c.wall_z:
			nxt.z = c.wall_z
			var d2 := (nxt - H)
			if d2.length() > 1e-5:
				nxt = H + d2.normalized() * c.lens[k]
		c.prev[k] = c.cur[k]
		c.cur[k] = nxt
		var R := Quaternion(rest_dir_p, (nxt - H).normalized()) * Rrest
		pose.rot[b] = Rp.inverse() * R
		Rp = R
		H = nxt
	pose.dirty = true
