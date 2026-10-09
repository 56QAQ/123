extends RefCounted
## 专属棋子模型(与通用模型同一副骨骼、同一套动画、同样的 Q 版比例与雕刻手法)：
##   dancer — Node Dancer 起舞节点：蓬松卷曲的红发 + 双丸子，琥珀色眼睛，精灵耳；天蓝色抹胸与多片裙摆(金边、金珠)，金臂环/手镯/脚环，蓝色高跟鞋
##   archer — Node Archer 连射节点：凌乱的红色短发 + 呆毛，绿眼；绿色兜帽短斗篷(金边、锯齿下摆)，白色短上衣 + 皮带，绿裙 + 红色腰饰，皮护臂，毛边长靴
##   nurse  — Node Nurse 护理节点：红色长发 + 侧马尾，护士帽(红十字)，红眼；白色护士裙(红边、金扣)，泡泡袖，白手套，白长靴，粉色妖精翅膀(会扇动)
## 身体各部位的形体与通用模型一致(骨骼、软权重区都相同)，所以所有动作模组、武器握持都直接通用。
## 服装颜色全部是专属色，不参与阵营换色；头发归到发色类别(3)、皮肤用调色板肤色(类别 4)，发色/肤色可以按单位数据整体换。
## 每个专属模型一个文件 tools/chars/<名字>.gd(extends 本文件)：const HAIR = 头发(及同色兽耳/尾巴)用到的颜色(HAIR[0] = 原发色)，
## func build() 雕刻整个身体；build_kits 自动发现并生成 assets/unit_body_<名字>.res(游戏里按需加载，不进 unit_model.tscn)。
const VGrid = preload("res://tools/vgrid.gd")
const RIG = preload("res://tools/rig.gd")

const HAIR_DANCER := ["#c93642", "#b02e3a", "#952734"]
const CURL_DANCER := ["#c93642", "#a92b37", "#86212f"]
const HAIR_ARCHER := ["#c83e37", "#ae3530", "#962c2a"]
const HAIR_NURSE := ["#c4303e", "#aa2836", "#912231"]

var g
var rig
var skin: int
var skin2: int
var skin3: int

# 通用模型的脸部开窗(按 |x| 的整数部分索引)：刘海/头发不覆盖这之下的脸
const FACE_WIN := [80, 80, 83, 83, 82, 82, 83, 82, 77, 74]
const LOCK_SPLITS := [["SideLock_L1", 78, 93], ["SideLock_L2", 71, 77], ["SideLock_L3", 62, 70]]
const PANEL_SLABS := [["Panel_L1", 38, 60], ["Panel_L2", 27, 37], ["Panel_L3", -10, 26]]


static func _hpal(pal: Array) -> Array:
	var r: Array = []
	for hx: String in pal:
		r.append(H(hx))
	return r


func _init(grid, p_rig) -> void:
	g = grid
	rig = p_rig
	skin = H("#f8cdb8")
	skin2 = H("#efb7a3")
	skin3 = H("#e59f92")


static func H(s: String) -> int:
	return VGrid.hexc(s)


static func h01(x: int, y: int, z: int) -> float:
	var h: int = (x * 374761393) ^ (y * 668265263) ^ (z * 2147483647)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(h & 1023) / 1023.0


# ======================================================================= 通用小工具
func paint_box(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, c: int, lv: int = 0) -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.PAINT
	g.cur_glow = lv
	g.box(x0, y0, z0, x1, y1, z1, c)
	g.mode = sm
	g.cur_glow = sg


## 只给属于 bone 的体素改色(例如只给裙子描边，不碰到腿)
func paint_bone(bone: String, x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, fn: Callable) -> void:
	var b: int = rig.ids[bone]
	for z in range(mini(z0, z1), maxi(z0, z1) + 1):
		for y in range(mini(y0, y1), maxi(y0, y1) + 1):
			for x in range(mini(x0, x1), maxi(x0, x1) + 1):
				if not g.inb(x, y, z):
					continue
				var i: int = g.idx(x, y, z)
				if g.col[i] == 0 or g.bn[i] != b:
					continue
				var c: int = fn.call(x, y, z)
				if c != 0:
					g.col[i] = c


## 宝石：金框 + 两层芯(菱形)，axis=2 面向 +z
func gem(cx: int, cy: int, cz: int, r: int, frame: int, c1: int, c2: int, glow_lv: int = 40, axis: int = 2) -> void:
	var sg: int = g.cur_glow
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var d := absi(dx) + absi(dy)
			if d > r:
				continue
			var c: int = frame if d == r else (c1 if d == r - 1 else c2)
			g.cur_glow = 0 if d == r else glow_lv
			if axis == 2:
				g.put(cx + dx, cy + dy, cz, c)
			else:
				g.put(cx, cy + dy, cz + dx, c)
	g.cur_glow = sg


func ytaper_split(y0: int, y1: int, cx0: float, cz0: float, rx0: float, rz0: float, cx1: float, cz1: float, rx1: float, rz1: float, c: Variant, n: float, splits: Array) -> void:
	var span := float(y1 - y0 + 1)
	for s in splits:
		var a: int = maxi(y0, s[1])
		var b: int = mini(y1, s[2])
		if a > b:
			continue
		var ta := float(a - y0) / span
		var tb := float(b + 1 - y0) / span
		g.use(s[0])
		g.ytaper(a, b, lerpf(cx0, cx1, ta), lerpf(cz0, cz1, ta), lerpf(rx0, rx1, ta), lerpf(rz0, rz1, ta),
			lerpf(cx0, cx1, tb), lerpf(cz0, cz1, tb), lerpf(rx0, rx1, tb), lerpf(rz0, rz1, tb), c, n)


# ======================================================================= 身体(与通用模型同形)
## 裸露的身体底模：骨盆/躯干/颈/手臂/腿都用皮肤色；服装在上面覆盖或包裹
func body_skin() -> void:
	g.sym = false
	g.use("Hips")
	g.sq(0.0, 46.0, 0.0, 10.2, 5.2, 5.2, skin, 3.0)
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 6.2, 4.6, 0.0, 0.0, 7.4, 5.0, skin, 2.6)
	g.use("Chest")
	g.ytaper(58, 68, 0.0, 0.0, 7.6, 5.0, 0.0, 0.0, 8.7, 4.6, skin, 2.6)
	g.use("Neck")
	g.box(-2, 68, -3, 1, 72, 0, skin)
	g.sym = true
	# 手臂(A 字姿势)
	g.use("UpperArm_L")
	g.ytaper(57, 66, 13.0, 0.5, 2.5, 2.5, 10.5, 0.5, 2.5, 2.5, skin, 3.0)
	g.sq(10.5, 66.0, 0.5, 3.3, 2.4, 3.1, skin, 2.6)
	g.use("LowerArm_L")
	g.ytaper(47, 56, 16.0, 0.5, 2.3, 2.2, 13.0, 0.5, 2.6, 2.5, skin, 3.0)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.4, 2.4, 16.3, 0.5, 2.4, 2.5, skin, 2.6)
	g.use("Fingers_L")
	g.ytaper(38, 41, 18.0, 1.5, 2.4, 2.5, 17.4, 1.0, 2.4, 2.5, skin, 2.6)
	g.use("Thumb_L")
	g.box(13, 42, 2, 14, 45, 4, skin)
	# 腿：大腿上粗下细，小腿带一点腿肚
	g.use("Thigh_L")
	g.ytaper(28, 46, 5.5, 0.5, 3.8, 3.8, 5.5, 0.5, 4.9, 4.9, skin, 3.0)
	g.use("Shin_L")
	g.ytaper(9, 27, 5.5, 0.5, 2.8, 2.8, 5.5, 0.5, 3.7, 3.7, skin, 3.0)
	g.sq(5.5, 19.0, -0.3, 3.5, 5.5, 3.6, skin, 2.4)
	g.sym = false


## 脚：沿用通用模型的鞋底轮廓；fn(x,y,z) 给颜色
func feet(fn: Callable, heel: bool = false) -> void:
	g.sym = true
	g.use("Foot_L")
	var prof := PackedVector2Array([Vector2(-5, 0), Vector2(10, 0), Vector2(10, 2.2), Vector2(8.2, 4), Vector2(4.5, 5.2), Vector2(0.5, 7.4), Vector2(-5, 7.4)])
	if heel:
		prof = PackedVector2Array([Vector2(-5, 0), Vector2(-2, 0), Vector2(-1, 2), Vector2(5, 1.2), Vector2(10, 0), Vector2(10, 2.4), Vector2(8.2, 4), Vector2(4.5, 5.4), Vector2(0.5, 7.6), Vector2(-5, 7.6)])
	g.poly("zy", prof, 1, 9, fn)
	g.set_mode(VGrid.CLEAR)
	g.box(1, 0, 9, 1, 3, 9)
	g.box(9, 0, 9, 9, 3, 9)
	g.box(1, 0, -5, 1, 1, -5)
	g.box(9, 0, -5, 9, 1, -5)
	g.set_mode(VGrid.FILL)
	g.use("Toe_L")
	g.set_mode(VGrid.BONE_ONLY)
	g.box(0, 0, 5, 10, 6, 10)
	g.set_mode(VGrid.FILL)
	g.sym = false


# ======================================================================= 头部
## 头(与通用模型同一个颅骨/下颌)；style 只改下巴那一两行：
##   dancer 下巴收窄成小尖下巴；archer 两颊下角各削一格(脸更利落)；nurse 下巴底多一行、圆一点(娃娃脸)
func head_base(style: String = "base") -> void:
	g.sym = false
	g.use("Head")
	g.sq(0.0, 84.4, -0.5, 12.0, 10.2, 11.3, skin, 3.2)
	g.ytaper(73, 79, 0.0, 0.5, 8.8, 8.6, 0.0, 0.5, 10.8, 10.4, skin, 3.6)
	match style:
		"dancer":
			g.box(-9, 75, 9, 8, 82, 10, skin)
			g.box(-8, 74, 9, 7, 74, 10, skin)
			g.box(-6, 73, 9, 5, 73, 10, skin)
		"archer":
			g.box(-9, 75, 9, 8, 82, 10, skin)
			g.box(-8, 74, 9, 7, 74, 10, skin)
			g.box(-7, 73, 9, 6, 73, 10, skin)
		"nurse":
			g.box(-9, 74, 9, 8, 82, 10, skin)
			g.box(-8, 73, 9, 7, 73, 10, skin)
			g.box(-5, 72, 8, 4, 72, 9, skin)
		_:
			g.box(-9, 74, 9, 8, 82, 10, skin)
			g.box(-8, 73, 9, 7, 73, 10, skin)


## 眼睛(与通用模型同一套版式：3 列虹膜 + 2 列眼白 + 上睫毛线)，颜色按角色；腮红；嘴；闭眼用的眼睑
func face(e: Dictionary, mouth: String) -> void:
	var we := H("#f4f3f6")
	var we2 := H("#d9dbe4")
	var ed: int = e["dark"]
	var em: int = e["mid"]
	var el: int = e["light"]
	var hl: int = e["hl"]
	var lash: int = e["lash"]
	var blush := H("#f6a8a3")
	g.sym = true
	g.use("Head")
	var eye_fn := func(u: int, v: int) -> int:
		var ex := u - 3
		if v == 80:
			return lash
		if ex > 4:
			return 0
		if ex >= 3:
			return we2 if v == 76 else we
		if v == 79:
			return ed
		if v == 78:
			return hl if ex == 1 else em
		if v == 77:
			return em if ex != 0 else ed
		if v == 76:
			return el
		return 0
	g.decal(2, 1, 3, 76, 8, 80, eye_fn, 1)
	var blush_fn := func(u: int, v: int) -> int:
		return blush if (v == 75 and u >= 6 and u <= 7) else 0
	g.decal(2, 1, 6, 75, 7, 75, blush_fn, 1)
	g.use("Eyelid_L")
	var lid := func(x: int, y: int, z: int) -> int:
		return lash if y == 77 else skin
	g.box(2, 76, 8, 9, 81, 8, lid)
	g.sym = false
	g.use("Head")
	var m1 := H("#8e2a3c")
	var m2 := H("#ef7b88")
	var mfn := func(u: int, v: int) -> int:
		match mouth:
			"open":         # 张嘴笑：上沿深色，下面舌头
				if v == 75 and (u == -1 or u == 0):
					return m1
				if v == 74 and (u == -1 or u == 0):
					return m2
				if v == 75 and (u == -2 or u == 1):
					return m1
			"smile":        # 微笑：两端上翘
				if v == 74 and (u == -1 or u == 0):
					return m1
				if v == 75 and (u == -2 or u == 1):
					return m1
			"flat":         # 抿嘴
				if v == 74 and (u == -1 or u == 0):
					return H("#c4756c")
		return 0
	g.decal(2, 1, -2, 74, 1, 75, mfn, 1)


## 精灵耳：从头侧向外上方伸出的尖耳朵，内侧略深
func elf_ears() -> void:
	g.sym = true
	g.use("Head")
	g.seg(Vector3(11.0, 80.5, 1.0), Vector3(19.5, 86.5, -1.5), 2.4, 0.6, skin)
	var sm: int = g.mode
	g.mode = VGrid.PAINT_SURF
	g.seg(Vector3(12.5, 80.8, 2.4), Vector3(17.0, 84.6, 0.8), 1.1, 0.5, skin2)
	g.mode = sm
	g.sym = false


## 头发帽壳(脸部开窗)
func hair_shell(c: Vector3, r: Vector3, n: float, colfn: Callable) -> void:
	g.sym = false
	g.use("Head")
	var shell := func(x: int, y: int, z: int) -> int:
		if z >= 5:
			var ax := int(absf(x + 0.5))
			if ax <= 9 and y <= int(FACE_WIN[ax]) - 1:
				return 0
		return colfn.call(x, y, z)
	g.sq(c.x, c.y, c.z, r.x, r.y, r.z, shell, n)


## 刘海：z 平面上一列列发束，bottom[x] = 该列的下沿
func bangs(bottom: Dictionary, z: int, top: int, colfn: Callable, seam: Array = []) -> void:
	g.sym = false
	g.use("Head")
	for x: int in bottom.keys():
		var yb: int = bottom[x]
		for y in range(yb, top):
			var cc: int = colfn.call(x, y, z)
			if x in seam or y == yb:
				cc = VGrid.shade(cc, 0.86)
			g.put(x, y, z, cc)
			if y >= yb + 2:
				g.put(x, y, z - 1, cc)


## 后发(挂在马尾骨链上，会随动作飘动)：prof(y) -> [cz, rx, rz]；bottom(x) = 该列最低点
func back_hair(y0: int, y1: int, prof: Callable, colfn: Callable, bottom: Callable, xoff: float = 0.0) -> void:
	g.sym = false
	var seg_ys := [84, 75, 66, 57, 48, 39]
	for y in range(y0, y1 + 1):
		var pr: Array = prof.call(float(y) + 0.5)
		var cz: float = pr[0]
		var rx: float = pr[1]
		var rz: float = pr[2]
		var seg := 0
		for s in seg_ys:
			if y >= s:
				break
			seg += 1
		for x in range(int(floor(xoff - rx)) - 1, int(ceil(xoff + rx)) + 1):
			var xc := float(x) + 0.5
			if y < int(bottom.call(x)):
				continue
			for z in range(int(floor(cz - rz)), int(ceil(cz + rz)) + 1):
				var dz := absf((float(z) + 0.5 - cz) / rz)
				var dx := absf((xc - xoff) / rx)
				if pow(dx, 2.6) + pow(dz, 2.6) > 1.0:
					continue
				var col := "C"
				if xc > 3.6:
					col = "L"
				elif xc < -3.6:
					col = "R"
				g.cur_bone = rig.ids["Tail" + col + str(mini(seg + 1, 7))]
				g.cur_glow = 0
				g.put(x, y, z, colfn.call(x, y, z))


## 布片(挂在裙甲骨链 Panel 上，会摆动)：从 p0 垂到 p1，宽度方向 across，末端收尖；
## 每个采样点往法线方向再铺一格(两格厚)。fn(x,y,z,t,side) 给颜色：side = -1/1 为两条长边，2 为尖端，0 为布面
func flap(p0: Vector3, p1: Vector3, w0: float, w1: float, across: Vector3, fn: Callable) -> void:
	var dir: Vector3 = (p1 - p0).normalized()
	var nrm: Vector3 = across.cross(dir).normalized()
	if nrm.dot(Vector3(p0.x, 0, p0.z)) < 0.0:
		nrm = -nrm                     # 法线朝外(远离身体)，厚度往外长
	var steps: int = int(ceil(p0.distance_to(p1) * 2.0))
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var p: Vector3 = p0.lerp(p1, t)
		var w: float = lerpf(w0, w1, t)
		if t > 0.7:
			w = lerpf(w, 0.3, (t - 0.7) / 0.3)
		var kmax: int = int(ceil(w * 2.0))
		for k in range(-kmax, kmax + 1):
			var off: float = float(k) * 0.5
			if absf(off) > w:
				continue
			var side: int = 0
			if off > w - 0.9:
				side = 1
			elif off < -w + 0.9:
				side = -1
			if t > 0.95:
				side = 2
			for th: float in [0.0, 0.8]:
				var q: Vector3 = p + across * off + nrm * th
				var x: int = int(floor(q.x))
				var y: int = int(floor(q.y))
				var z: int = int(floor(q.z))
				var bone := ""
				for s in PANEL_SLABS:
					if y >= int(s[1]) and y <= int(s[2]):
						bone = str(s[0])
				if bone == "":
					continue
				g.use(bone)
				var c: int = fn.call(x, y, z, t, side)
				if c != 0:
					g.put(x, y, z, c)


## 裙摆上的一片：按绕腰一圈的角度 ang(度，0 = 正前，90 = 左侧)放置，从腰(y_top)垂到 y_tip，向外张开 flare
func skirt_flap(ang: float, y_top: float, y_tip: float, rx: float, rz: float, flare: float, w0: float, w1: float, fn: Callable) -> void:
	var a: float = deg_to_rad(ang)
	var top := Vector3(sin(a) * rx, y_top, cos(a) * rz)
	var outv := Vector3(sin(a), 0.0, cos(a) * 0.8).normalized()
	var tip: Vector3 = top + outv * flare + Vector3(0, y_tip - y_top, 0)
	var across := Vector3(cos(a), 0.0, -sin(a))
	flap(top, tip, w0, w1, across, fn)


## 马尾骨链上的骨骼：按高度分段、按 x 分三列
func tail_bone(x: int, y: int) -> int:
	var seg_ys := [84, 75, 66, 57, 48, 39]
	var seg := 0
	for s in seg_ys:
		if y >= s:
			break
		seg += 1
	var xc := float(x) + 0.5
	var col := "C"
	if xc > 3.6:
		col = "L"
	elif xc < -3.6:
		col = "R"
	return rig.ids["Tail" + col + str(mini(seg + 1, 7))]


## 一团头发(卷发的"一卷"、乱发的"一簇")：椭球，上亮下暗；pal = [base, light, dark, deep]
## bone = "" 时按马尾骨链分配(后发)，"SideLock" 按高度分配到鬓发骨链(需 sym、在 +x 侧)；skip(x,y,z) 为真则跳过(给脸让位)
func puff(c: Vector3, r: Vector3, pal: Array, bone: String = "Head", skip: Callable = Callable()) -> void:
	for z in range(int(floor(c.z - r.z)), int(ceil(c.z + r.z)) + 1):
		for y in range(int(floor(c.y - r.y)), int(ceil(c.y + r.y)) + 1):
			for x in range(int(floor(c.x - r.x)), int(ceil(c.x + r.x)) + 1):
				var d := Vector3((float(x) + 0.5 - c.x) / r.x, (float(y) + 0.5 - c.y) / r.y, (float(z) + 0.5 - c.z) / r.z)
				if d.length_squared() > 1.0:
					continue
				if skip.is_valid() and bool(skip.call(x, y, z)):
					continue
				var t: float = d.y + (h01(x, y, z) - 0.5) * 0.25
				var col: int = pal[0]
				if t > 0.42:
					col = pal[1]
				elif t < -0.62:
					col = pal[3]
				elif t < -0.2:
					col = pal[2]
				if bone == "":
					g.cur_bone = tail_bone(x, y)
				elif bone == "SideLock":
					g.cur_bone = rig.ids["SideLock_L1" if y >= 78 else ("SideLock_L2" if y >= 71 else "SideLock_L3")]
				else:
					g.cur_bone = rig.ids[bone]
				g.cur_glow = 0
				g.put(x, y, z, col)


## 一缕尖发(乱发)：从发根到发梢的锥体，发根偏暗、中段本色、朝上的一面有高光
func clump(p0: Vector3, p1: Vector3, r0: float, r1: float, pal: Array, bone: String = "Head") -> void:
	var d: Vector3 = p1 - p0
	var dd: float = d.length_squared()
	var rm: float = maxf(r0, r1) + 0.5
	var lo := Vector3(minf(p0.x, p1.x), minf(p0.y, p1.y), minf(p0.z, p1.z)) - Vector3.ONE * rm
	var hi := Vector3(maxf(p0.x, p1.x), maxf(p0.y, p1.y), maxf(p0.z, p1.z)) + Vector3.ONE * rm
	for z in range(int(floor(lo.z)), int(ceil(hi.z)) + 1):
		for y in range(int(floor(lo.y)), int(ceil(hi.y)) + 1):
			for x in range(int(floor(lo.x)), int(ceil(hi.x)) + 1):
				var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
				var t: float = clampf((q - p0).dot(d) / maxf(dd, 0.0001), 0.0, 1.0)
				var cl: Vector3 = p0 + d * t
				var r: float = lerpf(r0, r1, t)
				var off: Vector3 = q - cl
				if off.length() > r:
					continue
				var col: int = pal[0]
				if t < 0.18:
					col = pal[2]
				elif off.y > r * 0.35 and t < 0.8:
					col = pal[1]
				elif off.y < -r * 0.5:
					col = pal[2]
				if bone == "":
					g.cur_bone = tail_bone(x, y)
				elif bone == "SideLock":
					g.cur_bone = rig.ids["SideLock_L1" if y >= 78 else ("SideLock_L2" if y >= 71 else "SideLock_L3")]
				else:
					g.cur_bone = rig.ids[bone]
				g.cur_glow = 0
				g.put(x, y, z, col)


## 直发的颜色：绕头顶的放射状发丝(扇区明暗)，低频变化；band_y 处一圈断续的高光(动漫式发光带)
func strand_fn(pal: Array, band_y: int) -> Callable:
	return func(x: int, y: int, z: int) -> int:
		var ang := atan2(float(x) + 0.5, float(z) + 1.0)
		var sector := int(floor((ang + PI) / (PI / 11.0)))
		var r := h01(x >> 1, y >> 2, z >> 1)
		if (y == band_y or y == band_y + 1) and z > -6 and (x + 40) % 4 != 0:
			return pal[1]
		if sector % 2 == 0:
			return pal[2] if r > 0.7 else pal[0]
		if r > 0.9:
			return pal[3]
		return pal[0]


# ======================================================================= 头部(第三版：完全沿用通用模型的头部做法)
## 通用模型的头发配色逻辑：绕头顶的放射状发束(扇区交替明暗) + 少量随机杂色；pal = [本色, 稍暗, 更暗]
func strand_orig(pal: Array) -> Callable:
	return func(x: int, y: int, z: int) -> int:
		var ang := atan2(float(x) + 0.5, float(z) + 1.0)
		var sector := int(floor((ang + PI) / (PI / 11.0)))
		var r := h01(x, y, z)
		if sector % 2 == 0:
			return pal[1] if r > 0.55 else pal[0]
		if sector % 5 == 0 and r > 0.6:
			return pal[2]
		if r > 0.94:
			return pal[1]
		return pal[0]


## 通用模型的头发帽壳(同尺寸、同脸部开窗) + 后颈 + 头顶发旋
func shell_orig(colfn: Callable) -> void:
	g.sym = false
	g.use("Head")
	var shell := func(x: int, y: int, z: int) -> int:
		if z >= 5:
			var ax := int(absf(x + 0.5))
			if ax <= 9 and y <= int(FACE_WIN[ax]) - 1:
				return 0
		return colfn.call(x, y, z)
	g.sq(0.0, 85.4, -1.6, 14.0, 10.7, 12.4, shell, 3.8)
	g.box(-8, 75, -11, 7, 79, -5, colfn)
	g.box(-3, 96, -3, 2, 96, 3, colfn)


## 刘海(通用模型的做法)：头壳前再凸出一格的发簇，bottom[x] 为下沿，seam 列是簇间的深色缝
func bangs_orig(bottom: Dictionary, seam: Array, colfn: Callable, dark: int) -> void:
	g.sym = false
	g.use("Head")
	for x in range(-8, 8):
		var yb: int = bottom[x]
		for y in range(yb, 91):
			var c: int = dark if (x in seam) else colfn.call(x, y, 11)
			if y == yb and h01(x, y, 5) > 0.5:
				c = dark
			g.put(x, y, 11, c)


## 鬓发(通用模型的做法)：脸侧两缕，从 y0 垂下，根部与头壳衔接
func locks_orig(colfn: Callable, y0: int = 62) -> void:
	g.sym = true
	ytaper_split(y0, 88, 12.8, 4.5, 1.7, 2.6, 12.3, 4.2, 2.3, 3.4, colfn, 2.6, LOCK_SPLITS)
	g.use("Head")
	g.box(11, 80, 1, 13, 87, 7, colfn)
	g.sym = false


## 螺旋卷(钻头卷)：竖直向下，一圈圈螺旋沟纹；bone 同 puff("" = 马尾骨链，"SideLock" = 鬓发骨链)
func ringlet(top: Vector3, y_bot: float, r0: float, r1: float, pal: Array, bone: String) -> void:
	var h: float = top.y - y_bot
	for y in range(int(floor(y_bot)), int(ceil(top.y)) + 1):
		var t: float = (top.y - (float(y) + 0.5)) / h
		if t < 0.0 or t > 1.0:
			continue
		var r: float = lerpf(r0, r1, t) * (0.9 + 0.1 * cos(t * TAU * 2.0))
		if t > 0.8:
			r *= sqrt(maxf(0.05, (1.0 - t) / 0.2))
		var cx: float = top.x
		var cz: float = top.z
		for z in range(int(floor(cz - r)) - 1, int(ceil(cz + r)) + 1):
			for x in range(int(floor(cx - r)) - 1, int(ceil(cx + r)) + 1):
				var dx: float = float(x) + 0.5 - cx
				var dz: float = float(z) + 0.5 - cz
				if dx * dx + dz * dz > r * r:
					continue
				var ang: float = atan2(dz, dx)
				var groove: bool = fmod(float(y) / 3.5 + ang / TAU + 20.0, 1.0) < 0.2
				var col: int = pal[2] if groove else (pal[1] if dz < -r * 0.3 else pal[0])
				if bone == "":
					g.cur_bone = tail_bone(x, y)
				elif bone == "SideLock":
					g.cur_bone = rig.ids["SideLock_L1" if y >= 78 else ("SideLock_L2" if y >= 71 else "SideLock_L3")]
				else:
					g.cur_bone = rig.ids[bone]
				g.cur_glow = 0
				g.put(x, y, z, col)


## 眼睛版式(+x 那只，列 = x 3..8 内→外，行 = y 81..75 上→下)。通用模型的是 "base"；
## 专属模型在它上面只动一两处"微差"来换气质：
##   dancer 上睫毛外端上挑一格 + 外下眼角收一格 → 眼尾微微上扬，明朗有精神
##   archer 上睫毛整体压低一行、眼睛只剩 3 行高 → 半垂的眼睑，冷静、锐利
##   nurse  上睫毛外端往下垂 + 下方多一个小高光 → 垂眼，温柔湿润
## 字符：L 睫毛  D 虹膜上沿(暗)  M 虹膜中暗  m 虹膜本色  l 虹膜下沿(亮)  H 高光  W 眼白  w 眼白(下沿阴影)  . 不画(皮肤)
const EYES := {
	"base": ["......", "LLLLLL", "DDDWW.", "MHMWW.", "mmmWW.", "lllww.", "......"],
	"dancer": ["....LL", "LLLLL.", "DDDWW.", "MHMWW.", "mmmWW.", "lllw..", "......"],
	"archer": ["......", "......", "LLLLLL", "DDDWW.", "MHMWW.", "lllww.", "......"],
	"nurse": ["......", "LLLLL.", "DDDWL.", "MHMWWL", "mmmWW.", "lHlww.", "......"],
}


## 专属模型的脸：通用模型那套眼睛(3 列虹膜 + 2 列眼白 + 上睫毛线)加一点点差分(EYES)，只换虹膜颜色；没有嘴和腮红
## e = {dark, mid2, mid, light, hl}(对应通用模型的 eye3 / eye2 / eye / cyan2 / cyanw)
func face_orig(e: Dictionary, style: String = "base") -> void:
	face_rows(e, EYES.get(style, EYES["base"]))


## 同上，眼睛直接给字符画 rows(7 行 × 6 列，格式见 EYES)；新模型各自写一版微差
func face_rows(e: Dictionary, rows: Array) -> void:
	var we := H("#f4f3f6")
	var we2 := H("#d9dbe4")
	var lash := H("#20232a")
	var key := {"L": lash, "D": e["dark"], "M": e["mid2"], "m": e["mid"], "l": e["light"], "H": e["hl"], "W": we, "w": we2, "S": skin3}
	g.sym = true
	g.use("Head")
	var eye_fn := func(u: int, v: int) -> int:
		var row: int = 81 - v
		var col: int = u - 3
		if row < 0 or row >= rows.size() or col < 0 or col > 5:
			return 0
		return int(key.get(str(rows[row])[col], 0))
	g.decal(2, 1, 3, 75, 8, 81, eye_fn, 1)
	g.use("Eyelid_L")
	var lid := func(x: int, y: int, z: int) -> int:
		return lash if y == 77 else skin
	g.box(2, 75, 8, 9, 81, 8, lid)
	g.sym = false


# ======================================================================= 男性款
## 男性角色共用：身体(平胸、宽胸廓、窄胯、粗脖子、手臂/腿更直更粗一点，关节和握点完全不变)、
## 下巴更长更收的 V 形脸、以及男性眼睛版式(更扁、上眼睑更厚、眼白更少、没有亮色下沿)。
## 女性的眼睛靠"大虹膜 + 两列眼白 + 亮色下沿 + 高光"显得萌；男性去掉亮色下沿、眼白收成一列、外眼角的睫毛加粗压住眼白。
const EYES_MALE := {
	"base": ["......", "LLLLLL", "DDDLLL", "MHMWL.", "mmmW..", "......", "......"],
	"sharp": ["......", "LLLLLL", "LDDLLL", "MHMWL.", "mmmW..", "......", "......"],     # 更凶：内眼角也压一格
	"calm": ["......", "......", "LLLLLL", "DDDWLL", "MHmW..", "......", "......"],     # 更沉：整体低一行、半垂
	"soft": ["......", "LLLLL.", "DDDWLL", "MHMW..", "mmmW..", "......", "......"],     # 温和：睫毛外端不加粗
}


## 男性身体：与 body_skin() 同一套骨骼/关节/握点，只改形体
func body_skin_male() -> void:
	g.sym = false
	g.use("Hips")
	g.sq(0.0, 46.5, 0.0, 8.8, 5.0, 5.0, skin, 3.0)
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 7.0, 4.9, 0.0, 0.0, 8.0, 5.1, skin, 2.8)
	g.use("Chest")
	g.ytaper(58, 68, 0.0, 0.0, 8.2, 5.2, 0.0, 0.0, 9.4, 4.9, skin, 2.8)
	g.use("Neck")
	g.box(-3, 68, -3, 2, 72, 0, skin)
	g.sym = true
	g.use("UpperArm_L")
	g.ytaper(57, 66, 13.0, 0.5, 2.7, 2.7, 10.5, 0.5, 2.8, 2.8, skin, 3.0)
	g.sq(10.6, 66.0, 0.5, 3.6, 2.6, 3.3, skin, 2.6)
	g.use("LowerArm_L")
	g.ytaper(47, 56, 16.0, 0.5, 2.5, 2.4, 13.0, 0.5, 2.8, 2.7, skin, 3.0)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.6, 2.6, 16.3, 0.5, 2.6, 2.7, skin, 2.6)
	g.use("Fingers_L")
	g.ytaper(38, 41, 18.0, 1.5, 2.6, 2.6, 17.4, 1.0, 2.6, 2.6, skin, 2.6)
	g.use("Thumb_L")
	g.box(13, 42, 2, 14, 45, 4, skin)
	g.use("Thigh_L")
	g.ytaper(28, 46, 5.5, 0.5, 4.1, 4.1, 5.5, 0.5, 4.5, 4.5, skin, 3.0)
	g.use("Shin_L")
	g.ytaper(9, 27, 5.5, 0.5, 3.1, 3.1, 5.5, 0.5, 3.8, 3.8, skin, 3.0)
	g.sq(5.5, 19.0, -0.3, 3.6, 5.5, 3.7, skin, 2.4)
	g.sym = false


## 男性的脸型：同一个颅骨，只把下巴做长一格、两侧收成 V 形
func head_base_male() -> void:
	g.sym = false
	g.use("Head")
	g.sq(0.0, 84.4, -0.5, 12.0, 10.2, 11.3, skin, 3.2)
	g.ytaper(73, 79, 0.0, 0.5, 8.4, 8.4, 0.0, 0.5, 10.8, 10.4, skin, 3.6)
	g.box(-9, 76, 9, 8, 82, 10, skin)
	g.box(-8, 75, 9, 7, 75, 10, skin)
	g.box(-7, 74, 9, 6, 74, 10, skin)
	g.box(-5, 73, 9, 4, 73, 10, skin)
	g.box(-3, 72, 8, 2, 72, 9, skin)


## 男性眼睛：style 取 EYES_MALE 的键，或直接给 7 行字符画(再在上面做自己的微差)；
## brow = 眉毛颜色(0 = 不画，一般取比发色深得多的颜色)：一行粗眉(外端上挑一格)，画在眼睛上方脸或刘海的最外层上
## (被刘海挡住的地方就画在刘海上，动画里常见的"眉毛透过刘海")
func face_male(e: Dictionary, style: Variant = "base", brow: int = 0) -> void:
	var rows: Array = style if style is Array else EYES_MALE.get(str(style), EYES_MALE["base"])
	face_rows(e, rows)
	if brow != 0:
		g.sym = true
		g.use("Head")
		var bfn := func(u: int, v: int) -> int:
			return brow if (v == 82 and u >= 3 and u <= 7) or (v == 83 and u == 8) else 0
		g.decal(2, 1, 3, 82, 8, 83, bfn, 1)
		g.sym = false


## 兽尾(腰后的 BTail 弹簧链)：按体素离链上哪一节最近挂骨；画尾巴时 g.cur_bone = btail_bone(x, y, z)
func btail_bone(x: int, y: int, z: int) -> int:
	return _nearest_seg(Vector3(x + 0.5, y + 0.5, z + 0.5), RIG.BTAIL_PTS, "BTail")


## 披风/长外套后摆(胸口背后的 Cape 三列弹簧链)：按 x 分列、按 y 分节挂骨；y 在 66 以上的挂 Chest
func cape_bone(x: int, y: int) -> int:
	if y >= 66:
		return rig.ids["Chest"]
	var seg: int = clampi(int((66 - y) / 10) + 1, 1, 4)
	var xc: float = float(x) + 0.5
	var col: String = "CapeC" if absf(xc) < 3.5 else ("Cape_L" if xc > 0.0 else "Cape_R")
	return rig.ids[col + str(seg)]


func _nearest_seg(q: Vector3, pts: Array, prefix: String) -> int:
	var best := 0
	var bd := 1e9
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var t: float = clampf((q - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		var d: float = (q - a.lerp(b, t)).length()
		if d < bd:
			bd = d
			best = i
	return rig.ids[prefix + str(best + 1)]


## 精灵耳(小一号，向后上方斜，藏在鬓发后面)
func ears_small() -> void:
	g.sym = true
	g.use("Head")
	g.seg(Vector3(11.5, 81.0, 0.5), Vector3(16.8, 86.5, -2.5), 1.9, 0.5, skin)
	var sm: int = g.mode
	g.mode = VGrid.PAINT_SURF
	g.seg(Vector3(12.5, 81.3, 1.4), Vector3(15.5, 84.8, -1.0), 0.9, 0.4, skin2)
	g.mode = sm
	g.sym = false


# ---------------------------------------------------------------- 舞星：干净的头壳 + 双丸子 + 钻头卷鬓发 + 到肩的后发(发尾一排小卷)
func _head_dancer() -> void:
	var pal: Array = _hpal(HAIR_DANCER)
	var curl: Array = _hpal(CURL_DANCER)
	var hair: Callable = strand_orig(pal)
	var au := H("#dba94a")
	var au2 := H("#f6d47a")
	var bl := H("#2f6fe0")
	# 后发：到肩的一片(三列，竖向发缝)，发尾一排钻头卷
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		var c: int = hair.call(x, y, z)
		return VGrid.shade(c, 0.92) if absf(xc - k * 4.6) > 1.8 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 30.0, 0.0, 1.0)
		return [lerpf(-9.0, -10.5, t), lerpf(11.5, 12.6, minf(1.0, t * 1.8)), lerpf(5.6, 6.2, minf(1.0, t * 1.8))]
	back_hair(73, 95, prof, back_col, func(x: int) -> int: return 73)
	for xr: float in [-9.6, -4.8, 0.0, 4.8, 9.6]:
		ringlet(Vector3(xr, 78.0, -10.8 + absf(xr) * 0.08), 55.0 + absf(xr) * 0.45, 3.2, 2.4, curl, "")
	body_skin()
	head_base("dancer")
	face_orig({"dark": H("#8a4210"), "mid2": H("#c8741c"), "mid": H("#f0a232"), "light": H("#ffd76a"), "hl": H("#fff7e2")}, "dancer")
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 83, -6: 84, -5: 83, -4: 82, -3: 81, -2: 80, -1: 79, 0: 79, 1: 80, 2: 81, 3: 82, 4: 83, 5: 84, 6: 83, 7: 82}, [-5, -2, 1, 4], hair, pal[2])
	# 鬓发：螺旋卷(挂鬓发骨链)
	g.sym = true
	g.use("Head")
	g.box(11, 80, 1, 13, 87, 7, hair)
	ringlet(Vector3(12.9, 86.0, 4.6), 62.0, 2.6, 2.2, curl, "SideLock")
	g.sym = false
	# 双丸子：两侧头顶的圆发髻，带一圈螺旋纹；金发箍 + 蓝宝石
	g.sym = true
	g.use("Head")
	var bun := func(x: int, y: int, z: int) -> int:
		var dx := float(x) + 0.5 - 10.5
		var dy := float(y) + 0.5 - 97.0
		var d := sqrt(dx * dx + dy * dy)
		var a := atan2(dy, dx)
		if fmod(d / 2.1 - a / TAU + 20.0, 1.0) < 0.22 and d > 1.0:
			return curl[2]
		return pal[0] if dy > -1.0 else pal[1]
	g.sq(10.5, 97.0, -3.5, 4.4, 4.2, 4.2, bun, 2.2)
	g.ring(Vector3(9.0, 94.0, -3.0), Vector3(0.55, -0.8, 0.0), 3.3, 1.5, au)
	g.put(12, 92, 0, au2)
	g.put(12, 93, 0, bl)
	g.sym = false
	# 呆毛
	g.use("Head")
	var ahoge := [Vector3(0.5, 96.5, 1.0), Vector3(1.5, 101.5, 0.5), Vector3(4.0, 104.5, -1.0), Vector3(6.0, 102.5, -2.5)]
	for i in range(ahoge.size() - 1):
		g.seg(ahoge[i], ahoge[i + 1], lerpf(1.3, 0.8, float(i) / 3.0), lerpf(1.1, 0.6, float(i) / 3.0), pal[0])
	ears_small()


# ---------------------------------------------------------------- 连射：干净的头壳 + 锯齿刘海 + 后颈几簇翘发 + 短鬓发 + 大呆毛
func _head_archer() -> void:
	var pal: Array = _hpal(HAIR_ARCHER)
	var hair: Callable = strand_orig(pal)
	body_skin()
	head_base("archer")
	face_orig({"dark": H("#155a2c"), "mid2": H("#259a46"), "mid": H("#43cc63"), "light": H("#9ff29c"), "hl": H("#effff0")}, "archer")
	shell_orig(hair)
	bangs_orig({-8: 82, -7: 84, -6: 81, -5: 84, -4: 82, -3: 80, -2: 83, -1: 78, 0: 81, 1: 83, 2: 80, 3: 82, 4: 84, 5: 81, 6: 84, 7: 82}, [-6, -3, 0, 3, 5], hair, pal[2])
	locks_orig(hair, 71)
	# 翘发：后颈一排、耳上两簇、头顶两簇(都是贴着轮廓的小尖簇)
	g.use("Head")
	for xn: float in [-9.5, -6.5, -3.0, 0.5, 4.0, 7.5, 10.5]:
		g.seg(Vector3(xn, 78.0, -10.5), Vector3(xn * 1.12, 72.0 - absf(xn) * 0.1, -13.2), 1.9, 0.45, pal[1])
	g.sym = true
	g.seg(Vector3(12.5, 89.0, 0.0), Vector3(16.5, 87.0, -2.5), 1.7, 0.4, pal[0])
	g.seg(Vector3(12.5, 85.0, -4.0), Vector3(16.0, 82.5, -6.5), 1.6, 0.4, pal[1])
	g.sym = false
	for sp: Array in [[Vector3(-6.0, 95.0, -6.0), Vector3(-9.0, 98.5, -9.5)], [Vector3(5.0, 95.0, -7.0), Vector3(8.0, 98.5, -10.5)], [Vector3(0.0, 95.5, -9.0), Vector3(0.5, 98.0, -13.5)]]:
		g.seg(sp[0], sp[1], 2.0, 0.5, pal[0])
	var ahoge := [Vector3(0.5, 96.5, 1.0), Vector3(1.5, 102.5, 0.0), Vector3(-0.5, 107.0, -2.0), Vector3(-3.5, 107.5, 0.0), Vector3(-4.5, 104.5, 2.0)]
	for i in range(ahoge.size() - 1):
		g.seg(ahoge[i], ahoge[i + 1], lerpf(1.4, 0.7, float(i) / 4.0), lerpf(1.2, 0.6, float(i) / 4.0), pal[0])
	ears_small()


# ---------------------------------------------------------------- 护理：干净的头壳 + 齐刘海 + 长鬓发 + 及腿的长后发 + 侧马尾
func _head_nurse() -> void:
	var pal: Array = _hpal(HAIR_NURSE)
	var hair: Callable = strand_orig(pal)
	var au := H("#dcac4b")
	var au2 := H("#f6d47b")
	# 长后发：三列竖向发缝，发尾一缕缕收尖
	var back_col := func(x: int, y: int, z: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		var c: int = hair.call(x, y, z)
		return VGrid.shade(c, 0.92) if absf(xc - k * 4.6) > 1.75 else c
	var prof := func(yf: float) -> Array:
		var t: float = clampf((96.0 - yf) / 56.0, 0.0, 1.0)
		return [lerpf(-9.5, -12.5, minf(1.0, t * 1.5)), lerpf(11.2, 12.2, minf(1.0, t * 2.5)) - maxf(0.0, t - 0.75) * 3.0, lerpf(5.4, 6.0, minf(1.0, t * 2.5)) - maxf(0.0, t - 0.7) * 3.0]
	var bottom := func(x: int) -> int:
		var xc := float(x) + 0.5
		var k: float = roundf(xc / 4.6)
		return 40 + int(absf(xc - k * 4.6) * 2.2) + int(absf(k))
	back_hair(40, 95, prof, back_col, bottom)
	# 侧马尾(角色右侧)：一束收尖的直发，并入后发右列一起摆动
	var tail_pts := [Vector3(-12.5, 92.0, -6.0), Vector3(-15.0, 82.0, -8.5), Vector3(-15.8, 68.0, -10.0), Vector3(-15.0, 55.0, -9.5)]
	var tail_r := [3.6, 3.4, 2.8, 1.2]
	for i in range(tail_pts.size() - 1):
		g.cur_glow = 0
		var p0: Vector3 = tail_pts[i]
		var p1: Vector3 = tail_pts[i + 1]
		var d: Vector3 = p1 - p0
		var lo := Vector3(minf(p0.x, p1.x), minf(p0.y, p1.y), minf(p0.z, p1.z)) - Vector3.ONE * 4.5
		var hi := Vector3(maxf(p0.x, p1.x), maxf(p0.y, p1.y), maxf(p0.z, p1.z)) + Vector3.ONE * 4.5
		for z in range(int(floor(lo.z)), int(ceil(hi.z)) + 1):
			for y in range(int(floor(lo.y)), int(ceil(hi.y)) + 1):
				for x in range(int(floor(lo.x)), int(ceil(hi.x)) + 1):
					var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
					var t: float = clampf((q - p0).dot(d) / d.length_squared(), 0.0, 1.0)
					if (q - (p0 + d * t)).length() > lerpf(tail_r[i], tail_r[i + 1], t):
						continue
					g.cur_bone = tail_bone(x, y)
					g.put(x, y, z, hair.call(x, y, z) if (x + z) % 3 != 0 else pal[1])
	body_skin()
	head_base("nurse")
	face_orig({"dark": H("#7a1222"), "mid2": H("#b8243a"), "mid": H("#ec4b5a"), "light": H("#ff9aa2"), "hl": H("#fff0f1")}, "nurse")
	shell_orig(hair)
	bangs_orig({-8: 83, -7: 83, -6: 83, -5: 83, -4: 82, -3: 82, -2: 80, -1: 80, 0: 80, 1: 80, 2: 82, 3: 82, 4: 83, 5: 83, 6: 83, 7: 83}, [-4, -2, 2, 4], hair, pal[2])
	locks_orig(hair, 60)
	# 侧马尾根部 + 金发圈
	g.use("Head")
	g.sq(-12.0, 94.0, -5.0, 3.8, 3.8, 4.0, hair, 2.4)
	g.ring(Vector3(-12.3, 91.5, -6.0), Vector3(-0.3, -1.0, -0.3), 2.9, 1.5, au)
	g.put(-14, 91, -3, au2)
	ears_small()


# ======================================================================= Node Dancer
func dancer() -> void:
	var sky := H("#9fd6ec")
	var sky2 := H("#79b8d8")
	var sky3 := H("#d4f1fb")
	var wht := H("#f5f3f1")
	var wht2 := H("#dcd8de")
	var au := H("#dba94a")
	var au2 := H("#f6d47a")
	var au3 := H("#a57a2e")
	var bl := H("#2f6fe0")
	var bl2 := H("#8cc0ff")
	var shoe := H("#4d72bd")
	var shoe2 := H("#35548f")
	var sole := H("#2b2e3a")
	_head_dancer()
	# ---- 抹胸(天蓝) + 金边 + 胸前蓝宝石
	var skyfn := func(x: int, y: int, z: int) -> int:
		if y >= 65:
			return sky3
		if y <= 60:
			return sky2
		return sky
	g.use("Chest")
	g.sym = true
	g.sq(3.9, 62.4, 4.0, 4.4, 3.6, 3.9, skyfn, 2.4)
	g.sym = false
	g.ytaper(59, 63, 0.0, 0.3, 8.2, 5.4, 0.0, 0.3, 8.9, 5.3, skyfn, 2.6)
	paint_bone("Chest", -11, 59, -8, 10, 59, 10, func(x: int, y: int, z: int) -> int: return au)
	var cup_top := func(x: int, y: int, z: int) -> int:
		return au2 if (y >= 64 and z >= 4 and not g.solid(x, y + 1, z)) else 0
	paint_bone("Chest", -10, 63, 2, 9, 67, 9, cup_top)
	g.use("Chest")
	gem(0, 62, 8, 1, au, bl, bl2, 50)
	# ---- 金项圈 + 吊坠
	g.use("Neck")
	g.ytaper(70, 71, 0.0, -1.0, 3.4, 3.4, 0.0, -1.0, 3.4, 3.4, au, 3.0)
	gem(0, 69, 3, 1, au2, bl, bl2, 50)
	g.put(-1, 67, 3, au)
	g.put(0, 67, 3, au)
	# ---- 金臂环(上臂)、手镯(腕)
	g.sym = true
	g.use("UpperArm_L")
	var armlet := func(x: int, y: int, z: int) -> int: return au2 if (x + z + 40) % 3 == 0 else au
	g.ytaper(60, 63, 12.3, 0.5, 3.2, 3.2, 11.7, 0.5, 3.3, 3.3, armlet, 3.0)
	gem(15, 61, 0, 1, au3, bl, bl2, 40, 0)
	g.use("LowerArm_L")
	g.ytaper(48, 50, 15.9, 0.5, 3.3, 3.1, 15.6, 0.5, 3.3, 3.1, armlet, 3.0)
	g.ytaper(52, 52, 15.2, 0.5, 3.1, 2.9, 15.2, 0.5, 3.1, 2.9, au3, 3.0)
	g.sym = false
	# ---- 金腰带 + 大蓝宝石 + 垂坠
	g.use("Hips")
	var belt := func(x: int, y: int, z: int) -> int: return au3 if (x * 2 + z + 60) % 5 == 0 else au
	g.ytaper(48, 50, 0.0, 0.2, 10.6, 5.9, 0.0, 0.2, 10.3, 5.7, belt, 3.0)
	gem(0, 47, 7, 2, au2, bl, bl2, 55)
	# ---- 白色衬裙(只填空处，腿不被覆盖)
	g.set_mode(VGrid.ADD)
	g.use("Hips")
	var pleat := func(x: int, y: int, z: int) -> int: return wht2 if (x + z + 40) % 3 == 0 else wht
	g.ytaper(38, 47, 0.0, 0.0, 12.2, 7.2, 0.0, 0.0, 10.8, 6.2, pleat, 2.6)
	g.set_mode(VGrid.FILL)
	paint_bone("Hips", -14, 38, -9, 13, 38, 9, func(x: int, y: int, z: int) -> int: return sky2)
	# ---- 天蓝裙片：前片/后片(骨盆)，两侧三片一组(裙甲骨链，会摆)
	var front := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var hw := 3.4 - maxf(0.0, 40.0 - float(y)) * 0.42
		if y < 32 or ax > hw:
			return 0
		if ax > hw - 1.0 or y <= 33:
			return au
		return sky if y > 39 else sky2
	g.use("Hips")
	g.each(-5, 31, 8, 4, 46, 8, front)
	g.each(-5, 31, 9, 4, 44, 9, front)
	g.box(-1, 30, 8, 0, 31, 9, au2)
	g.box(-1, 42, 9, 0, 45, 9, au)
	gem(0, 41, 10, 1, au2, bl, bl2, 50)
	var back := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		var hw := 4.6 - maxf(0.0, 36.0 - float(y)) * 0.5
		if y < 28 or ax > hw:
			return 0
		if ax > hw - 1.0 or y <= 29:
			return au
		return sky if y > 36 else sky2
	g.each(-6, 27, -9, 5, 46, -9, back)
	g.each(-6, 27, -10, 5, 44, -10, back)
	g.box(-1, 26, -10, 0, 27, -11, au2)
	var clothfn := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if side == 2:
			return au2
		if side == 1:
			return au
		if t < 0.14:
			return sky3
		if t > 0.72:
			return sky2
		if side == -1:
			return sky3
		return sky
	g.sym = true
	skirt_flap(48.0, 47.0, 25.0, 10.4, 6.6, 3.0, 3.2, 2.4, clothfn)
	skirt_flap(92.0, 47.5, 21.0, 10.6, 6.0, 4.0, 3.6, 2.6, clothfn)
	skirt_flap(132.0, 47.0, 23.0, 10.2, 6.4, 3.5, 3.2, 2.4, clothfn)
	g.sym = false
	# ---- 左大腿的天蓝腿环
	g.use("Thigh_L")
	g.ytaper(34, 35, 5.5, 0.5, 4.5, 4.5, 5.5, 0.5, 4.6, 4.6, sky3, 3.0)
	paint_box(9, 34, 0, 10, 35, 1, au)
	# ---- 脚环(金 + 蓝珠)
	g.sym = true
	g.use("Shin_L")
	g.ytaper(10, 12, 5.5, 0.5, 3.3, 3.3, 5.5, 0.5, 3.3, 3.3, armlet, 3.0)
	g.box(5, 8, 4, 6, 9, 4, bl2)
	g.box(9, 8, 1, 9, 9, 2, bl)
	g.sym = false
	# ---- 蓝色高跟鞋
	var shoefn := func(x: int, y: int, z: int) -> int:
		if y == 0 or (z <= -2 and y <= 2):
			return sole
		if y >= 5:
			return au
		if x >= 8:
			return shoe2
		if z >= 8 and y <= 2:
			return au2
		return shoe
	feet(shoefn, true)
	g.sym = true
	g.use("Foot_L")
	paint_box(1, 4, 2, 9, 4, 2, au)
	g.sym = false


# ======================================================================= Node Archer
func archer() -> void:
	var grn := H("#58803e")
	var grn2 := H("#406330")
	var grn3 := H("#79a656")
	var au := H("#d6a845")
	var au2 := H("#f0ce6a")
	var lea := H("#6b4128")
	var lea2 := H("#8b5834")
	var lea3 := H("#472a18")
	var wht := H("#f2eee5")
	var wht2 := H("#d9d2c5")
	var red := H("#c3322f")
	var red2 := H("#8e1f22")
	var fur := H("#ece2cf")
	var fur2 := H("#d4c6ad")
	var gm := H("#2ec46c")
	var gm2 := H("#a4f4be")
	_head_archer()
	# ---- 白色短上衣 + 皮带交叉 + 金扣
	g.use("Chest")
	g.sym = true
	g.sq(3.9, 62.6, 3.9, 4.3, 3.8, 3.8, wht, 2.4)
	g.sym = false
	var top := func(x: int, y: int, z: int) -> int: return wht2 if y == 58 else wht
	g.ytaper(58, 62, 0.0, 0.2, 8.0, 5.3, 0.0, 0.2, 8.8, 5.2, top, 2.6)
	var strap := func(u: int, v: int) -> int:
		var ax := absf(float(u) + 0.5)
		if absf(ax - (1.0 + float(v - 58) * 0.9)) < 0.9 and v >= 58 and v <= 66:
			return lea
		return 0
	g.decal(2, 1, -9, 58, 8, 66, strap, 1)
	g.box(-1, 59, 8, 0, 61, 8, au)
	g.put(-1, 60, 9, au2)
	for yy: int in [63, 65]:
		g.put(-1, yy, 8, lea3)
		g.put(0, yy, 8, lea3)
	# ---- 兜帽短斗篷(只填空处：手臂/躯干的骨骼不被改掉)
	var cape := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if z > 2 and ax < 6.8 - float(70 - y) * 0.12:
			return 0
		var hem: int = 57 + int(round(2.0 * absf(sin(float(x) * 0.55))))
		if y < hem:
			return 0
		if y <= hem + 1:
			return au
		if z > 1 and ax < 8.2 - float(70 - y) * 0.12:
			return au
		return grn3 if y >= 68 else (grn2 if y <= hem + 3 else grn)
	g.set_mode(VGrid.ADD)
	g.use("Chest")
	g.ytaper(55, 70, 0.0, -0.8, 15.3, 7.6, 0.0, -0.8, 12.8, 6.8, cape, 2.4)
	g.use("Neck")
	var hood := func(x: int, y: int, z: int) -> int: return au if y <= 68 else (grn3 if y >= 74 else grn)
	g.sq(0.0, 72.0, -8.4, 8.8, 5.0, 4.2, hood, 2.4)
	g.set_mode(VGrid.FILL)
	# ---- 背后的斗篷下摆(挂在马尾骨链上，会飘)
	for y in range(43, 58):
		for x in range(-11, 11):
			var ax := absf(float(x) + 0.5)
			var hem: int = 43 + int(round(3.0 * absf(sin(float(x) * 0.62))))
			if y < hem or ax > 10.5:
				continue
			var c: int = au if y <= hem + 1 else (grn2 if y < hem + 4 else grn)
			g.cur_bone = tail_bone(x, y)
			var zz: int = -7 - int((57 - y) / 5)
			g.put(x, y, zz, c)
			g.put(x, y, zz - 1, c)
	# ---- 皮腰带 + 金扣 + 腰包
	g.use("Hips")
	var belt := func(x: int, y: int, z: int) -> int: return lea2 if y == 49 else lea
	g.ytaper(47, 49, 0.0, 0.2, 10.6, 5.9, 0.0, 0.2, 10.4, 5.8, belt, 3.0)
	g.box(-2, 46, 6, 1, 49, 7, au)
	g.box(-1, 47, 7, 0, 48, 7, lea3)
	g.box(-13, 41, -2, -10, 47, 3, lea)
	g.box(-13, 45, -2, -10, 47, 3, lea2)
	g.box(-12, 45, 3, -11, 45, 4, au)
	# ---- 绿色外裙(后面与两侧)，白色百褶衬裙，红色腰饰
	g.set_mode(VGrid.ADD)
	var skirt := func(x: int, y: int, z: int) -> int:
		if z > 1:
			return 0
		var hem: int = 34 + int(round(2.0 * absf(sin(float(x) * 0.5))))
		if y < hem:
			return 0
		if y <= hem + 1:
			return au
		return grn2 if y < 40 else grn
	g.ytaper(34, 47, 0.0, -0.4, 12.9, 7.8, 0.0, -0.4, 11.0, 6.6, skirt, 2.6)
	var pleat := func(x: int, y: int, z: int) -> int: return wht2 if (x + z + 40) % 3 == 0 else wht
	g.ytaper(38, 47, 0.0, 0.0, 11.4, 6.9, 0.0, 0.0, 10.6, 6.1, pleat, 2.6)
	g.set_mode(VGrid.FILL)
	var sash := func(x: int, y: int, z: int) -> int:
		if y <= 32:
			return au
		return red2 if (x == -1 and y % 3 == 0) else red
	g.box(-2, 31, 7, 1, 46, 7, sash)
	g.box(-1, 30, 7, 0, 30, 8, au2)
	# 两侧的绿裙片(会摆)
	var clothfn := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if side != 0:
			return au if side != -1 else grn3
		return grn3 if t < 0.15 else (grn2 if t > 0.7 else grn)
	g.sym = true
	skirt_flap(62.0, 47.0, 31.0, 10.8, 6.6, 3.0, 3.4, 2.6, clothfn)
	skirt_flap(105.0, 47.0, 32.0, 10.8, 6.4, 3.0, 3.4, 2.6, clothfn)
	g.sym = false
	# ---- 左大腿皮环 + 金环
	g.use("Thigh_L")
	g.ytaper(36, 37, 5.5, 0.5, 4.7, 4.7, 5.5, 0.5, 4.8, 4.8, lea, 3.0)
	g.box(10, 35, 0, 11, 37, 1, au)
	# ---- 皮护臂 + 露指手套
	g.sym = true
	g.use("LowerArm_L")
	var brace := func(x: int, y: int, z: int) -> int:
		if y == 49 or y == 53:
			return lea2
		return lea
	g.ytaper(47, 54, 16.0, 0.5, 3.0, 2.8, 13.9, 0.5, 3.1, 3.0, brace, 3.0)
	g.box(18, 50, 0, 18, 51, 1, au)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.6, 2.6, 16.3, 0.5, 2.6, 2.7, lea3, 2.6)
	g.sym = false
	# ---- 毛边长靴 + 金饰 + 绿宝石
	g.sym = true
	g.use("Shin_L")
	var boot := func(x: int, y: int, z: int) -> int:
		if z <= -3:
			return lea3
		if y == 12 or y == 17:
			return lea3
		return lea2 if x >= 8 else lea
	g.ytaper(8, 23, 5.5, 0.5, 3.6, 3.7, 5.5, 0.5, 4.3, 4.3, boot, 3.0)
	var furfn := func(x: int, y: int, z: int) -> int: return fur2 if h01(x, y, z) > 0.6 else fur
	g.ytaper(23, 26, 5.5, 0.5, 4.8, 4.8, 5.5, 0.5, 4.9, 4.9, furfn, 3.0)
	paint_box(0, 22, -6, 11, 22, 6, au)
	gem(10, 16, 0, 1, au, gm, gm2, 40, 0)
	g.box(9, 11, 3, 9, 13, 4, au)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y == 0:
			return lea3
		if z >= 8 and y <= 3:
			return au
		return lea2 if x >= 8 else lea
	feet(bootfoot)


# ======================================================================= Node Nurse
func nurse() -> void:
	var wht := H("#f7f4f2")
	var wht2 := H("#e0dcda")
	var red := H("#d6303d")
	var red2 := H("#a61f2c")
	var red3 := H("#f0606a")
	var au := H("#dcac4b")
	var au2 := H("#f6d47b")
	var brn := H("#6e4429")
	var wing := H("#f6c3d2")
	var wing2 := H("#fde4ec")
	var wing3 := H("#e690ab")
	var wing4 := H("#f0a6be")
	_head_nurse()
	# ---- 护士帽(白 + 红十字 + 金边)
	g.use("Head")
	var cap := func(x: int, y: int, z: int) -> int: return wht2 if y <= 95 else wht
	g.sq(0.0, 97.6, 1.0, 8.8, 3.2, 6.8, cap, 4.0)
	g.box(-7, 94, 6, 6, 100, 7, wht)
	paint_box(-7, 94, 6, 6, 94, 7, au)
	g.box(-1, 95, 8, 0, 99, 8, red)
	g.box(-3, 96, 8, 2, 97, 8, red)
	g.sym = true
	g.box(7, 96, 3, 8, 97, 5, au2)
	g.sym = false
	# ---- 连衣裙上身(白)：领口露出皮肤，红边、金扣、胸前红十字
	var bodice := func(x: int, y: int, z: int) -> int:
		var ax := absf(float(x) + 0.5)
		if y >= 64 and z > 1 and ax < 3.5 + float(y - 64) * 1.2:
			return skin
		if y == 51 or y == 52:
			return red
		return wht if z > -3 else wht2
	g.use("Spine")
	g.ytaper(51, 57, 0.0, 0.0, 6.4, 4.8, 0.0, 0.0, 7.6, 5.2, bodice, 2.6)
	g.use("Chest")
	g.ytaper(58, 67, 0.0, 0.0, 7.8, 5.2, 0.0, 0.0, 8.8, 4.8, bodice, 2.6)
	g.sym = true
	g.sq(3.9, 62.4, 3.9, 4.3, 3.6, 3.8, wht, 2.4)
	g.sym = false
	var neckline := func(x: int, y: int, z: int) -> int:
		return red if (y >= 64 and z >= 3 and not g.solid(x, y + 1, z)) else 0
	paint_bone("Chest", -10, 63, 0, 9, 68, 10, neckline)
	g.use("Chest")
	g.box(-1, 61, 8, 0, 63, 8, red)
	g.put(-2, 62, 8, red)
	g.put(1, 62, 8, red)
	g.use("Spine")
	for yy: int in [53, 56]:
		g.put(-1, yy, 6, au2)
		g.put(0, yy, 6, au2)
	# 红色项圈 + 金十字
	g.use("Neck")
	g.ytaper(70, 71, 0.0, -1.0, 3.4, 3.4, 0.0, -1.0, 3.4, 3.4, red, 3.0)
	g.box(-1, 67, 3, 0, 69, 3, au)
	g.put(-2, 68, 3, au)
	g.put(1, 68, 3, au)
	# ---- 泡泡袖(红 + 白边 + 金线)
	g.sym = true
	g.use("UpperArm_L")
	var sleeve := func(x: int, y: int, z: int) -> int:
		if y <= 60:
			return wht
		if y == 61:
			return au
		return red3 if y >= 66 else red
	g.sq(11.4, 63.6, 0.5, 4.4, 3.8, 4.2, sleeve, 2.4)
	# ---- 白手套 + 红袖口
	g.use("LowerArm_L")
	var glove := func(x: int, y: int, z: int) -> int:
		if y >= 52:
			return red if y == 52 else wht
		return wht2 if x >= 17 else wht
	g.ytaper(47, 53, 16.0, 0.5, 2.6, 2.4, 14.4, 0.5, 3.1, 3.0, glove, 3.0)
	g.put(18, 52, 1, au2)
	g.use("Hand_L")
	g.ytaper(42, 46, 17.3, 0.5, 2.5, 2.5, 16.3, 0.5, 2.5, 2.6, wht, 2.6)
	g.use("Fingers_L")
	g.ytaper(38, 41, 18.0, 1.5, 2.5, 2.6, 17.4, 1.0, 2.5, 2.6, wht, 2.6)
	g.use("Thumb_L")
	g.box(13, 42, 2, 14, 45, 4, wht)
	g.sym = false
	# ---- 腰带 + 金扣 + 右侧腰包(红十字)
	g.use("Hips")
	g.ytaper(47, 49, 0.0, 0.2, 10.7, 6.0, 0.0, 0.2, 10.5, 5.9, brn, 3.0)
	g.box(-2, 46, 6, 1, 49, 7, au)
	g.box(-1, 47, 7, 0, 48, 7, red)
	g.box(-13, 40, -2, -10, 46, 3, brn)
	g.box(-13, 44, -2, -10, 46, 4, wht)
	g.box(-12, 41, 4, -11, 43, 4, red)
	g.put(-13, 42, 4, red)
	g.put(-10, 42, 4, red)
	# ---- 裙子：白色百褶 + 红色裙边(只填空处)
	g.set_mode(VGrid.ADD)
	var skirt := func(x: int, y: int, z: int) -> int:
		if y <= 38:
			return red2 if (x + z + 40) % 3 == 0 else red
		return wht2 if (x + z + 40) % 3 == 0 else wht
	g.ytaper(36, 47, 0.0, 0.0, 13.4, 8.0, 0.0, 0.0, 10.9, 6.3, skirt, 2.6)
	g.set_mode(VGrid.FILL)
	# 身后两侧的白色燕尾(会摆)
	var tailfn := func(x: int, y: int, z: int, t: float, side: int) -> int:
		if side == 2 or (side != 0 and t > 0.85):
			return red
		if side == 1:
			return au
		return wht if t < 0.6 else wht2
	g.sym = true
	skirt_flap(125.0, 47.0, 25.0, 10.4, 6.4, 3.5, 3.4, 2.4, tailfn)
	skirt_flap(155.0, 47.0, 27.0, 9.0, 6.6, 3.0, 3.2, 2.4, tailfn)
	g.sym = false
	# ---- 白色长袜 + 红边；右大腿皮环 + 红蝴蝶结
	g.sym = true
	g.use("Thigh_L")
	var sock := func(x: int, y: int, z: int) -> int: return red if y >= 33 else wht
	g.ytaper(28, 34, 5.5, 0.5, 4.0, 4.0, 5.5, 0.5, 4.5, 4.5, sock, 3.0)
	g.use("Shin_L")
	g.ytaper(22, 27, 5.5, 0.5, 3.8, 3.8, 5.5, 0.5, 3.9, 3.9, wht, 3.0)
	g.sym = false
	g.use("Thigh_R")
	g.ytaper(38, 39, -5.5, 0.5, 4.9, 4.9, -5.5, 0.5, 5.0, 5.0, brn, 3.0)
	g.box(-12, 37, 0, -11, 40, 2, red)
	g.box(-13, 36, 1, -12, 37, 1, red2)
	g.box(-13, 40, 1, -12, 41, 1, red2)
	# ---- 白长靴：红边、红蝴蝶结、金十字、红鞋跟
	g.sym = true
	g.use("Shin_L")
	var boot := func(x: int, y: int, z: int) -> int:
		if y >= 22:
			return red
		return wht2 if (x >= 8 or z <= -3) else wht
	g.ytaper(8, 23, 5.5, 0.5, 3.6, 3.7, 5.5, 0.5, 4.3, 4.3, boot, 3.0)
	g.box(4, 20, 4, 7, 21, 5, red)
	g.box(5, 19, 5, 6, 19, 5, red2)
	g.box(10, 14, 0, 10, 18, 0, au)
	g.box(10, 16, -1, 10, 16, 1, au)
	var bootfoot := func(x: int, y: int, z: int) -> int:
		if y == 0 or (z <= -2 and y <= 2):
			return red2
		return wht2 if x >= 8 else wht
	feet(bootfoot, true)
	g.sym = true
	g.use("Foot_L")
	paint_box(1, 4, 3, 9, 4, 3, red)
	g.sym = false
	# ---- 妖精翅膀(粉色，两对；挂在翅膀骨上会扇动；只填空处，头发在前面)
	_wings(wing, wing2, wing3, wing4)


func _wings(wing: int, wing2: int, wing3: int, wing4: int) -> void:
	var upper := PackedVector2Array([Vector2(1, 1), Vector2(6, 9), Vector2(13, 18), Vector2(21, 26), Vector2(28, 30), Vector2(32, 27), Vector2(31, 19), Vector2(26, 11), Vector2(18, 4), Vector2(9, 0)])
	var lower := PackedVector2Array([Vector2(1, -1), Vector2(8, -6), Vector2(15, -13), Vector2(20, -20), Vector2(21, -26), Vector2(16, -27), Vector2(10, -20), Vector2(5, -11), Vector2(2, -4)])
	var root := Vector3(3.5, 63.0, -6.5)
	var a: float = deg_to_rad(24.0)
	var axis := Vector3(cos(a), 0.0, -sin(a))
	g.set_mode(VGrid.ADD)
	g.sym = true
	g.use("Wing_L", 18)
	for pi in range(2):
		var poly: PackedVector2Array = upper if pi == 0 else lower
		var eye: Vector2 = Vector2(20, 18) if pi == 0 else Vector2(12, -15)
		var u := 0.0
		while u <= 33.0:
			var v := -28.0
			while v <= 31.0:
				var q := Vector2(u, v)
				if Geometry2D.is_point_in_polygon(q, poly):
					var p: Vector3 = root + axis * u + Vector3(0, v, 0)
					var x := int(floor(p.x))
					var y := int(floor(p.y))
					var z := int(floor(p.z))
					var edge := _poly_dist(q, poly) < 1.3
					var d: Vector2 = q - eye
					var rho: float = d.length()
					var phi: float = atan2(d.y, d.x)
					var c: int = wing
					if edge:
						c = wing4
					elif fmod(rho * 0.42 - phi / TAU * 3.0 + 10.0, 1.0) < 0.24 and rho < 11.0:
						c = wing3
					elif u < 7.0:
						c = wing2
					g.put(x, y, z, c)
				v += 0.5
			u += 0.5
	g.sym = false
	g.cur_glow = 0
	g.set_mode(VGrid.FILL)


static func _poly_dist(q: Vector2, poly: PackedVector2Array) -> float:
	var best := 1e9
	for i in range(poly.size()):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]
		var ab: Vector2 = b - a
		var t: float = clampf((q - a).dot(ab) / maxf(0.0001, ab.length_squared()), 0.0, 1.0)
		best = minf(best, q.distance_to(a + ab * t))
	return best
