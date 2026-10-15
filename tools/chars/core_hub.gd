extends "res://tools/chars/_droid.gd"
## CN-00 中枢主机(Core Hub，蓝之章的精英·支援：不移动、不攻击，站在敌方阵型最后面广播增幅链路、把倒下的机器重新组装起来)。
## 城市管理网络的一个节点主机：
##   基座(挂 Root，完全不动)：八角形的深色底台 + 一圈紫罗兰的灯环；一根深藏青的立柱(四面白色装甲板 + 散热缝，正面三颗状态灯)；
##     顶上一圈往外翻的托座 + 四根白色的托爪(爪尖亮着)，中间一块发光的悬浮垫；六根数据线缆从立柱侧面弯下去、插进地面的插座里。
##   悬浮的球形主机(球心 C，半径 R，比基座的托爪高出一截 = 飘着)：白色装甲板拼成(上下两圈白板 + 中间一道深藏青的腰带，腰带上一圈紫灯)，
##     正面一只大的"眼"(深色的镜筒 + 白色的镜框，里面是一圈分成叶片的紫色虹膜、深色的光圈环、白紫色的瞳核)，
##     两侧一对深色的端口(白盖 + 紫色灯环)，背后三片散热鳍，底部一圈紫色的悬浮发射口。
##   顶盖(纬度约 35° 以上，单独挂 Neck：慢慢自转)：深藏青 / 白相间的八瓣，四道紫色的光缝 + 四颗传感灯，正中一根短天线(横杆 + 发光的天线头)。
##   三道数据环(半径 22.6 / 27 / 31.8，同心；连同凸出的卡箍 / 节点 / 卫星舱各占一层球壳，怎么转都不会互相穿插，也碰不到球和眼眶)：
##     内环(Eyelid_L)：石墨色(深浅分段) + 四组三段的紫色"数据包" + 四个白色卡箍；
##     中环(Eyelid_R)：白色装甲弧(每 30° 一道板缝) + 三个藏青节点(正中一颗紫色透镜)；
##     外环(Halo)：藏青的导轨 + 每 20° 一段紫光 + 三个白色的卫星舱(外侧一颗紫灯)。
##   环上的花纹只按角度分段：倾斜的体素环按截面上色会碎成噪点。
## 挂骨(全部刚体，rigid())：
##   基座 → Root；球体 + 眼眶 + 端口 + 散热鳍 → Chest；瞳核 → Spine(广播时"一亮" = 缩放 + 往前顶)；顶盖 + 天线 → Neck；
##   三道环 → Eyelid_L / Eyelid_R / Halo。动作在 anim_chars.gd 的 [BLUE-C] 一节：
##   每道环模型里的法线 = (骨头关节 − 球心) 的方向，所以它绕自己的法线"在环面里转"时骨头的位移恒定(交叉淡化不会把环甩离球心)，
##   游戏里的倾角由动作给一个固定的预旋转(HUB_TILT)——静止姿势 / 通用动作里看到的环的倾角不是游戏里的样子。
##   Hips 不挂体素(只给 Spine 的瞳核补位移)，Head 不挂体素(给 Halo 补缩放)。
## 身份色：紫罗兰(#9d86ff，rim)；发光的体素用偏蓝一点的 #6e5cff(亮紫在发光里会泛成粉白)。游戏里 scale 1.5。
## 尺寸：高约 99 体素(1.24 m)，外环连卫星舱直径约 68 体素(0.85 m)，基座的线缆插座半径约 28 体素。
## 主会话挂特效用的点(静止坐标，体素，bone_point 用)：瞳核 Spine (0, 62, 16.5)；天线头 Neck (0, 97, -1)；悬浮垫 Root (0, 31.5, -1)。

const IDENTITY := {"rim": "#9d86ff", "rim_k": 0.12, "pulse": 0.0}

const C := Vector3(0.0, 62.0, -1.0)    # 球心
const R := 16.5                         # 球半径
const CAP_Y := 72                       # y >= 这一层的球面 = 顶盖(Neck)
const EYE := Vector3(0.0, 62.0, 15.0)   # 瞳核的中心(Spine 绕它缩放)
## 三道环：[骨头, 半径, 截面半宽(径向), 截面半厚(沿法线), 凸出部件的余量, 上色函数]
const RINGS := [
	["Eyelid_L", 22.6, 1.2, 1.0, 0.8, "_ring_a"],
	["Eyelid_R", 27.0, 1.4, 1.2, 1.1, "_ring_b"],
	["Halo", 31.8, 1.2, 1.0, 1.3, "_ring_c"],
]

var V0: int     # 紫(N0)稍暗一档：虹膜叶片之间的缝


func build() -> void:
	droid_init("#6e5cff", "#252a4a")
	V0 = VGrid.shade(N0, 0.62)
	_base()
	_sphere()
	_eye()
	_ports()
	_antenna()
	for e: Array in RINGS:
		g.sym = false
		g.use(str(e[0]))
		_band((rig.pos[rig.ids[str(e[0])]] - C).normalized(), float(e[1]), float(e[2]), float(e[3]), float(e[4]), Callable(self, str(e[5])))
	g.sym = false
	_rigid()


# =============================================================== 基座(Root)
func _oct(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in range(8):
		var a: float = deg_to_rad(22.5 + 45.0 * float(k))
		pts.append(Vector2(r * sin(a), C.z + r * cos(a)))
	return pts


func _base() -> void:
	var jf := Callable(self, "joint")
	var nf := Callable(self, "navy")
	g.sym = false
	g.use("Root")
	# 八角底台 + 藏青的倒角 + 灯环
	g.poly("xz", _oct(18.5), 0, 2, jf)
	g.poly("xz", _oct(16.8), 3, 4, nf)
	glow_ring(Vector3(0.0, 4.6, C.z), Vector3.UP, 14.8, 1.4, 70)
	# 立柱(深藏青，截面圆角方)
	g.ytaper(5, 25, 0.0, C.z, 11.0, 11.0, 0.0, C.z, 8.6, 8.6, nf, 3.2)
	# 四面白色装甲板(凸出一层) + 散热缝 + 正面状态灯
	var sm: int = g.mode
	g.mode = VGrid.ADD
	g.ytaper(7, 21, 0.0, C.z, 11.9, 11.9, 0.0, C.z, 9.9, 9.9, Callable(self, "_col_plate"), 3.2)
	g.mode = sm
	g.cur_glow = 0
	# 托座：往外翻的一圈 + 上沿 + 中间的悬浮垫
	g.ytaper(26, 29, 0.0, C.z, 8.6, 8.6, 0.0, C.z, 12.2, 12.2, jf, 3.2)
	g.ytaper(30, 30, 0.0, C.z, 12.6, 12.6, 0.0, C.z, 12.6, 12.6, nf, 3.2)
	g.ytaper(30, 30, 0.0, C.z, 7.2, 7.2, 0.0, C.z, 7.2, 7.2, D0, 2.0)
	g.cur_glow = 85
	g.ytaper(31, 31, 0.0, C.z, 4.6, 4.6, 0.0, C.z, 4.6, 4.6, N0, 2.0)
	g.cur_glow = 100
	g.ytaper(31, 31, 0.0, C.z, 1.6, 1.6, 0.0, C.z, 1.6, 1.6, N1, 2.0)
	g.cur_glow = 0
	# 四根托爪(对角)：白色，爪尖亮着
	for k in range(4):
		var a: float = deg_to_rad(45.0 + 90.0 * float(k))
		var dv := Vector3(sin(a), 0.0, cos(a))
		var o := Vector3(0.0, 0.0, C.z)
		g.seg(o + dv * 9.5 + Vector3(0, 27.0, 0), o + dv * 13.6 + Vector3(0, 35.0, 0), 1.9, 1.3, Callable(self, "plate"))
		g.seg(o + dv * 9.0 + Vector3(0, 26.0, 0), o + dv * 11.5 + Vector3(0, 30.0, 0), 1.6, 1.6, D2)
		glow_sq(dv.x * 14.0, 36.2, C.z + dv.z * 14.0, 1.1, 1.1, 1.1, 85)
	# 六根数据线缆(左右对称各三根)：从立柱侧面拱出去、弯下来插进地面的插座
	g.sym = true
	g.use("Root")
	for az: float in [38.0, 96.0, 148.0]:
		var a2: float = deg_to_rad(az)
		var dv2 := Vector3(sin(a2), 0.0, cos(a2))
		var o2 := Vector3(0.0, 0.0, C.z)
		var s0: Vector3 = o2 + dv2 * 9.6 + Vector3(0, 15.0, 0)
		var m0: Vector3 = o2 + dv2 * 22.0 + Vector3(0, 16.0, 0)
		var e0: Vector3 = o2 + dv2 * 25.5 + Vector3(0, 1.2, 0)
		var prev: Vector3 = s0
		for i in range(1, 13):
			var t: float = float(i) / 12.0
			var b: Vector3 = s0 * (1.0 - t) * (1.0 - t) + m0 * 2.0 * (1.0 - t) * t + e0 * t * t
			g.seg(prev, b, 1.35, 1.35, D0)
			if i % 2 == 0 and i < 12:
				glow_sq(b.x, b.y + 1.1, b.z, 0.65, 0.65, 0.65, 70)
			prev = b
		g.sq(s0.x, s0.y, s0.z, 2.3, 2.3, 2.3, Callable(self, "plate"), 3.0)
		g.ytaper(0, 2, e0.x, e0.z, 3.2, 3.2, e0.x, e0.z, 2.6, 2.6, nf, 3.0)
		glow_sq(e0.x, 3.2, e0.z, 0.9, 0.7, 0.9, 80)
	g.sym = false


## 立柱的白色装甲板：四个正面方向(±45° 以内的 28°)是白板，板上三道深色散热缝；正面一列三颗紫色状态灯
## (put 先调用这个函数再读 g.cur_glow，所以灯在这里顺手把发光设上)
func _col_plate(x: int, y: int, z: int) -> int:
	g.cur_glow = 0
	var a: float = rad_to_deg(atan2(float(x) + 0.5, float(z) + 0.5 - C.z))
	var w: float = absf(fposmod(a + 45.0, 90.0) - 45.0)
	if w > 27.0:
		return 0
	if w < 15.0 and (y == 10 or y == 13 or y == 16):
		return D0
	if absf(a) < 20.0 and y == 19 and (x == -5 or x == -4 or x == -1 or x == 0 or x == 3 or x == 4):
		g.cur_glow = 75
		return N0
	return P0 if h01(x >> 1, y >> 1, z >> 1) > 0.12 else P1


# =============================================================== 球体(Chest) + 顶盖(Neck)
func _sphere() -> void:
	var ri: int = int(ceil(R)) + 1
	for z in range(int(C.z) - ri, int(C.z) + ri + 1):
		for y in range(int(C.y) - ri, int(C.y) + ri + 1):
			for x in range(-ri, ri):
				var q := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - C
				var d: float = q.length()
				if d > R:
					continue
				var cap: bool = y >= CAP_Y
				g.use("Neck" if cap else "Chest")
				var cg: Vector2i = _cap_col(x, y, z, q, d) if cap else _shell_col(x, y, z, q, d)
				g.cur_glow = cg.y
				g.put(x, y, z, cg.x)
	g.cur_glow = 0


func _pl(x: int, y: int, z: int) -> int:
	var r: float = h01(x >> 1, y >> 1, z >> 1)
	if r > 0.9:
		return P2
	if r < 0.08:
		return P1
	return P0


## 角度差(度)换成球面上的弧长(体素)：rho = 所在纬圈的半径
func _arc(dlon: float, rho: float) -> float:
	return absf(dlon) * PI / 180.0 * rho


static func _wrap(a: float, period: float) -> float:
	return fposmod(a + period * 0.5, period) - period * 0.5


func _shell_col(x: int, y: int, z: int, q: Vector3, d: float) -> Vector2i:
	if d < R - 2.6:
		return Vector2i(D0, 0)
	var lat: float = rad_to_deg(asin(clampf(q.y / d, -1.0, 1.0)))
	var lon: float = rad_to_deg(atan2(q.x, q.z))
	var rho: float = Vector2(q.x, q.z).length()
	# 顶盖下面那一道深色的缝
	if y == CAP_Y - 1:
		return Vector2i(D0, 0)
	# 中间的腰带(深藏青) + 一圈紫灯
	if absf(lat) <= 12.0:
		if absf(lon) > 48.0 and _arc(_wrap(lon, 30.0), rho) < 0.75 and absf(lat) < 6.0:
			return Vector2i(N0, 60)
		if absf(lat) > 10.0:
			return Vector2i(D1, 0)
		return Vector2i(navy(x, y, z), 0)
	# 上圈白板：8 块(缝在 22.5° + 45° k)
	if lat > 12.0:
		if _arc(_wrap(lon - 22.5, 45.0), rho) < 0.55:
			return Vector2i(P1, 0)
		return Vector2i(_pl(x, y, z), 0)
	# 下圈白板：错开半块，中间一道纬向的缝
	if lat > -52.0:
		if _arc(_wrap(lon, 45.0), rho) < 0.55 or absf(lat + 32.0) * PI / 180.0 * d < 0.5:
			return Vector2i(P1, 0)
		return Vector2i(_pl(x, y, z), 0)
	# 底部：藏青 + 紫色的悬浮发射口
	if lat < -85.0:
		return Vector2i(N1, 90)
	if lat < -74.0:
		return Vector2i(N0, 75)
	if lat < -70.0:
		return Vector2i(D0, 0)
	return Vector2i(navy(x, y, z), 0)


## 顶盖：藏青 / 白相间的八瓣，四道紫色的光缝(0° / 90° / 180° / 270°)，藏青瓣中间各一颗传感灯
func _cap_col(x: int, y: int, z: int, q: Vector3, d: float) -> Vector2i:
	if d < R - 2.6:
		return Vector2i(D0, 0)
	var lat: float = rad_to_deg(asin(clampf(q.y / d, -1.0, 1.0)))
	var lon: float = rad_to_deg(atan2(q.x, q.z))
	var rho: float = Vector2(q.x, q.z).length()
	if lat > 78.0:
		return Vector2i(D0, 0)
	if _arc(_wrap(lon, 90.0), rho) < 0.7 and lat < 74.0:
		return Vector2i(N0, 70)
	var sector: int = int(floor(fposmod(lon, 360.0) / 45.0))
	if sector % 2 == 0:
		var dl: float = _wrap(lon - 22.5, 90.0)
		if Vector2(_arc(dl, rho), (lat - 52.0) * PI / 180.0 * d).length() < 1.25:
			return Vector2i(N0, 80)
		return Vector2i(navy(x, y, z), 0)
	return Vector2i(_pl(x, y, z), 0)


# =============================================================== 眼(Chest 的镜筒 + Spine 的瞳核)
func _eye() -> void:
	g.sym = false
	g.use("Chest")
	for z in range(5, 17):
		for y in range(51, 73):
			for x in range(-11, 11):
				var rr: float = Vector2(float(x) + 0.5, float(y) + 0.5 - EYE.y).length()
				if rr > 10.0:
					continue
				if rr >= 7.4:
					# 镜筒：外侧藏青，正面一圈白色的镜框，内沿深色
					if z == 16:
						g.put(x, y, z, P2 if rr > 8.2 else D1)
					elif z == 15 and rr < 8.2:
						g.put(x, y, z, D0)
					else:
						g.put(x, y, z, navy(x, y, z))
					continue
				# 镜筒里：往里凹两格，镜面在 z = 14 这一层
				if z >= 15:
					var sm: int = g.mode
					g.mode = VGrid.CLEAR
					g.put(x, y, z, 1)
					g.mode = sm
					continue
				if z < 14:
					g.put(x, y, z, D0)
					continue
				var c: int = D0
				var lv: int = 0
				if rr < 2.6:
					c = N1
					lv = 90
				elif rr < 3.6:
					c = N2
				elif rr < 6.6:
					var ang: float = rad_to_deg(atan2(float(y) + 0.5 - EYE.y, float(x) + 0.5))
					if fposmod(ang + 15.0, 30.0) < 4.5:
						c = V0
						lv = 45
					else:
						c = N0
						lv = 78
				g.cur_glow = lv
				g.put(x, y, z, c)
				g.cur_glow = 0
	# 瞳核(Spine)：白紫色的一颗，广播时它"一亮"(缩放 + 往前顶)
	g.use("Spine")
	glow_sq(EYE.x, EYE.y, EYE.z, 2.6, 2.6, 1.6, 88)
	glow_sq(EYE.x, EYE.y, EYE.z + 0.9, 1.3, 1.3, 1.0, 100, N1)


# =============================================================== 两侧的端口 + 背后的散热鳍(Chest)
func _ports() -> void:
	var nf := Callable(self, "navy")
	g.sym = true
	g.use("Chest")
	for x in range(13, 18):
		for y in range(56, 69):
			for z in range(-8, 7):
				var rr: float = Vector2(float(y) + 0.5 - C.y, float(z) + 0.5 - C.z).length()
				if rr > 4.5:
					continue
				if x == 17:
					if rr < 1.4:
						g.put(x, y, z, N2)
					elif rr < 2.5:
						g.cur_glow = 80
						g.put(x, y, z, N0)
						g.cur_glow = 0
					elif rr < 3.6:
						g.put(x, y, z, P2)
					else:
						g.put(x, y, z, D1)
				elif x == 16 and rr > 3.6:
					g.put(x, y, z, P0)
				else:
					g.put(x, y, z, nf.call(x, y, z))
	# 散热鳍：背后三片竖着的薄板
	g.sym = true
	for fx: int in [0, 4]:
		for y in range(54, 71):
			for z in range(-20, -6):
				var q := Vector3(float(fx) + 0.5, float(y) + 0.5, float(z) + 0.5) - C
				var d: float = q.length()
				if d < R - 1.0 or d > R + 1.8:
					continue
				g.put(fx, y, z, D1 if d > R + 1.0 else D2)
	g.sym = false


# =============================================================== 天线(Neck，跟顶盖一起转)
func _antenna() -> void:
	g.sym = false
	g.use("Neck")
	g.ytaper(77, 80, 0.0, C.z, 4.2, 4.2, 0.0, C.z, 3.0, 3.0, Callable(self, "navy"), 2.6)
	g.ytaper(81, 82, 0.0, C.z, 2.2, 2.2, 0.0, C.z, 1.8, 1.8, Callable(self, "joint"), 2.0)
	g.seg(Vector3(0.0, 82.0, C.z), Vector3(0.0, 95.0, C.z), 1.0, 0.8, Callable(self, "joint"))
	g.sym = true
	g.use("Neck")
	g.box(0, 88, -2, 2, 88, -1, Callable(self, "plate"))
	glow_box(3, 88, -2, 3, 88, -1, 80)
	g.sym = false
	glow_sq(0.0, 97.0, C.z, 1.7, 1.7, 1.7, 90)
	glow_sq(0.0, 97.0, C.z, 0.9, 0.9, 0.9, 100, N1)


# =============================================================== 数据环
## 一道倾斜的环：球心为环心，n = 法线，r = 半径；hw / ht = 截面的半宽(径向) / 半厚(沿法线)，pad = 给凸出部件留的余量；
## fn(phi 度, dr, h) -> Vector2i(颜色, 发光)，颜色 0 = 空。phi 从"法线面里最靠上的方向"量起
func _band(n: Vector3, r: float, hw: float, ht: float, pad: float, fn: Callable) -> void:
	var nn := n.normalized()
	var ref := Vector3.UP if absf(nn.y) < 0.995 else Vector3.BACK
	var u := (ref - nn * ref.dot(nn)).normalized()
	var v := nn.cross(u)
	var rm: float = r + hw + pad + 1.0
	for z in range(int(floor(C.z - rm)), int(ceil(C.z + rm)) + 1):
		for y in range(int(floor(C.y - rm)), int(ceil(C.y + rm)) + 1):
			for x in range(int(floor(C.x - rm)), int(ceil(C.x + rm)) + 1):
				var q := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - C
				var h: float = q.dot(nn)
				if absf(h) > ht + pad:
					continue
				var w: Vector3 = q - nn * h
				var dr: float = w.length() - r
				if absf(dr) > hw + pad:
					continue
				var phi: float = fposmod(rad_to_deg(atan2(w.dot(v), w.dot(u))), 360.0)
				var cg: Vector2i = fn.call(phi, dr, h)
				if cg.x == 0:
					continue
				g.cur_glow = cg.y
				g.put(x, y, z, cg.x)
	g.cur_glow = 0


## 内环：石墨色(每 15° 深浅交替一段)；每 90° 一组三段紫色的数据包，组与组之间一个白色卡箍(截面大一圈)。
## 环上的花纹只按角度分段(不按截面分)：倾斜的体素环按截面上色会碎成噪点
func _ring_a(phi: float, dr: float, h: float) -> Vector2i:
	var s: float = fposmod(phi, 90.0)
	if s >= 54.0 and s < 64.0:
		if dr >= -1.2 - 0.3 and dr <= 1.2 + 0.7 and absf(h) <= 1.0 + 0.6:
			return Vector2i(D1 if s >= 58.0 and s < 60.0 else P0, 0)
		return Vector2i(0, 0)
	if absf(dr) > 1.2 or absf(h) > 1.0:
		return Vector2i(0, 0)
	if s < 26.0 and fposmod(s, 9.0) < 6.0:
		return Vector2i(N0, 70)
	return Vector2i(D1 if fposmod(phi, 30.0) < 15.0 else D0, 0)


## 中环：白色装甲弧(每 30° 一道板缝)；每 120° 一个藏青节点(截面大一圈，正中一颗紫色透镜)
func _ring_b(phi: float, dr: float, h: float) -> Vector2i:
	var s: float = fposmod(phi, 120.0)
	if s < 12.0:
		if dr >= -1.4 - 0.5 and dr <= 1.4 + 1.1 and absf(h) <= 1.2 + 0.9:
			if absf(s - 6.0) < 2.6 and (dr > 1.7 or absf(h) > 1.5):
				return Vector2i(N0, 75)
			return Vector2i(D2, 0)
		return Vector2i(0, 0)
	if absf(dr) > 1.4 or absf(h) > 1.2:
		return Vector2i(0, 0)
	if fposmod(s - 12.0, 30.0) < 1.7:
		return Vector2i(D1, 0)
	return Vector2i(P0, 0)


## 外环：藏青导轨，每 20° 一段紫色的光(像数据在环上跑)；每 120° 一个白色卫星舱(截面大一圈，外侧一颗紫灯)
func _ring_c(phi: float, dr: float, h: float) -> Vector2i:
	var s: float = fposmod(phi, 120.0)
	if s < 10.0:
		if dr >= -1.2 - 0.4 and dr <= 1.2 + 1.2 and absf(h) <= 1.0 + 1.3:
			if absf(s - 5.0) < 1.8 and dr > 1.6:
				return Vector2i(N0, 80)
			return Vector2i(P0, 0)
		return Vector2i(0, 0)
	if absf(dr) > 1.2 or absf(h) > 1.0:
		return Vector2i(0, 0)
	if fposmod(s - 10.0, 20.0) < 8.0:
		return Vector2i(N0, 65)
	return Vector2i(D2, 0)


# =============================================================== 刚体权重
## 所有体素只跟自己那根骨头走：球、环都是刚体，骨骼的软权重区(胸 / 颈 / 肩)不能把它们扯变形
func _rigid() -> void:
	for z in range(-40, 40):
		for y in range(-4, 106):
			for x in range(-40, 40):
				if g.solid(x, y, z):
					g.set_weights(x, y, z, [[int(g.get_bone(x, y, z)), 1.0]])
