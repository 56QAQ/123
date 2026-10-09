extends "res://tools/model_chars.gd"
## 角色卡还原(第四版，2026-10-06 重建 angel / rogue / paladin / brave / killer / shaman / psychic / pacifist)共用的雕刻工具。
## 文件名以 _ 开头：不是一个身体模型(build_kits 不会把它当模型)，这批模型都继承它。
## 头部仍然照抄通用模型的构造(帽壳 shell_orig + 平刘海 + 鬓发 + 同一套眼睛版式)，在上面用"发束"盖出角色卡的发型轮廓：
##   一缕发束 = 沿一条平滑路径扫出来的扁带(根宽、梢尖、两三格厚)，外表面本色、两侧边一格暗色(发束之间的缝)、贴头的里层暗色、
##   靠近发根的一段高光(动漫式光带)。发束整齐地一层压一层排列(不是随机的团块/尖簇)，所以轮廓有角色卡那种"一级一级的发块"。
## 羽毛、披风、袖子、裙片也都用同一个扫掠(sweep)：给路径 + 截面(半宽, 厚度) + 外法线 + 配色 + 挂骨。

const HEAD_C := Vector3(0.0, 85.4, -1.6)      # 头壳中心(shell_orig)

## 扫掠写入前的检查(x,y,z) -> bool；无效 = 不检查。画头发时设成 hair_guard(...)：只写空格子或已有的头发
var put_guard := Callable()


# ======================================================================= 路径
## Catmull-Rom 平滑插值，按大约 step 体素的间距采样；返回 [点数组, 每点的弧长参数 0..1]
static func spline(ctrl: Array, step: float = 0.3) -> Array:
	var pts: Array = []
	var n: int = ctrl.size()
	if n == 1:
		return [[ctrl[0]], [0.0]]
	for i in range(n - 1):
		var p0: Vector3 = ctrl[maxi(i - 1, 0)]
		var p1: Vector3 = ctrl[i]
		var p2: Vector3 = ctrl[i + 1]
		var p3: Vector3 = ctrl[mini(i + 2, n - 1)]
		if i == 0:
			p0 = p1 * 2.0 - p2
		if i + 2 > n - 1:
			p3 = p2 * 2.0 - p1
		var m: int = maxi(2, int(ceil(p1.distance_to(p2) / step)))
		for k in range(m):
			var t: float = float(k) / float(m)
			var t2: float = t * t
			var t3: float = t2 * t
			pts.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	pts.append(ctrl[n - 1])
	var acc: Array = [0.0]
	for i in range(1, pts.size()):
		acc.append(float(acc[i - 1]) + (pts[i] as Vector3).distance_to(pts[i - 1]))
	var total: float = maxf(float(acc[acc.size() - 1]), 0.001)
	var ts: Array = []
	for a: float in acc:
		ts.append(a / total)
	return [pts, ts]


static func mirror_pts(pts: Array) -> Array:
	var r: Array = []
	for p: Vector3 in pts:
		r.append(Vector3(-p.x, p.y, p.z))
	return r


# ======================================================================= 扫掠
## 沿路径扫出一条扁带。
##   prof(t) -> Vector2(半宽, 厚度)(t = 0 起点 .. 1 终点)；
##   outfn(p) -> 外法线方向(厚度从外表面往里长；与切线垂直的分量才算)；
##   colfn(t, a, d) -> 颜色(a = -1..1 横向位置，d = 0 外表面 .. 1 最里层；0 = 不画)；
##   bonefn(x, y, z) -> 骨骼序号(无效 Callable = 用当前画笔骨)。
## 先画里层再画外层，所以同一格被多次采到时外表面的颜色优先。
func sweep(ctrl: Array, prof: Callable, outfn: Callable, colfn: Callable, bonefn: Callable = Callable(), twist: float = 0.0) -> void:
	var sp: Array = spline(ctrl)
	var pts: Array = sp[0]
	var ts: Array = sp[1]
	var n: int = pts.size()
	var prev_across := Vector3.ZERO
	for i in range(n):
		var p: Vector3 = pts[i]
		var tg: Vector3 = ((pts[mini(i + 1, n - 1)] as Vector3) - (pts[maxi(i - 1, 0)] as Vector3)).normalized()
		var t: float = ts[i]
		var pr: Vector2 = prof.call(t)
		if pr.x <= 0.0:
			continue
		var out: Vector3 = outfn.call(p)
		out = out - tg * out.dot(tg)
		if out.length_squared() < 0.0001:
			out = Vector3(0, 0, -1)
		out = out.normalized()
		var across: Vector3 = tg.cross(out).normalized()
		if twist != 0.0:
			var tw: float = twist * t
			across = across.rotated(tg, tw)
			out = out.rotated(tg, tw)
		if prev_across != Vector3.ZERO and across.dot(prev_across) < 0.0:
			across = -across
		prev_across = across
		var w: float = pr.x
		var th: float = maxf(pr.y, 0.01)
		var nd: int = maxi(1, int(ceil(th / 0.45)))
		var na: int = int(ceil(w / 0.4))
		for k in range(nd, -1, -1):
			var dd: float = th * float(k) / float(nd)
			if dd > th - 0.01 and k > 0 and th < 0.5:
				continue
			for j in range(-na, na + 1):
				var a: float = float(j) * 0.4
				if absf(a) > w:
					a = signf(a) * w
				var q: Vector3 = p + across * a - out * dd
				var x: int = int(floor(q.x))
				var y: int = int(floor(q.y))
				var z: int = int(floor(q.z))
				if put_guard.is_valid() and not bool(put_guard.call(x, y, z)):
					continue
				var c: int = colfn.call(t, a / maxf(w, 0.01), dd / th)
				if c == 0:
					continue
				if bonefn.is_valid():
					g.cur_bone = bonefn.call(x, y, z)
				g.cur_glow = 0
				g.put(x, y, z, c)


## 左右对称地扫两次(镜像路径 + 镜像骨；不依赖 g.sym，马尾链 TailL/TailR 这种不带 _L/_R 的骨也能正确镜像)
func sweep2(ctrl: Array, prof: Callable, outfn: Callable, colfn: Callable, bonefn: Callable = Callable(), twist: float = 0.0) -> void:
	var save: bool = g.sym
	g.sym = false
	sweep(ctrl, prof, outfn, colfn, bonefn, twist)
	var mb := Callable()
	if bonefn.is_valid():
		mb = func(x: int, y: int, z: int) -> int: return mirror_bone(int(bonefn.call(-1 - x, y, z)))
	else:
		var b0: int = g.cur_bone
		var b1: int = mirror_bone(b0)
		mb = func(_x: int, _y: int, _z: int) -> int: return b1
	var mcol := func(t: float, a: float, d: float) -> int: return colfn.call(t, -a, d)
	sweep(mirror_pts(ctrl), prof, outfn_mirror(outfn), mcol, mb, -twist)
	g.sym = save


func outfn_mirror(fn: Callable) -> Callable:
	return func(p: Vector3) -> Vector3:
		var o: Vector3 = fn.call(Vector3(-p.x, p.y, p.z))
		return Vector3(-o.x, o.y, o.z)


## 骨骼镜像：rig 的镜像表 + 马尾链 TailL ↔ TailR
func mirror_bone(b: int) -> int:
	var nm: String = rig.names[b]
	if nm.begins_with("TailL"):
		return rig.ids["TailR" + nm.substr(5)]
	if nm.begins_with("TailR"):
		return rig.ids["TailL" + nm.substr(5)]
	return g.mirror_of[b]


# ======================================================================= 截面 / 外法线 / 挂骨
## 截面：根部半宽 w0 → 中段 w1(t = mid)，从 t = tip 起收尖到 0.35；厚度 th(末端稍薄)
static func prof_lock(w0: float, w1: float, th: float, tip: float = 0.6, mid: float = 0.35) -> Callable:
	return func(t: float) -> Vector2:
		var w: float = lerpf(w0, w1, minf(1.0, t / mid))
		if t > tip:
			var u: float = (t - tip) / (1.0 - tip)
			w = lerpf(w, 0.35, u * u * 0.4 + u * 0.6)
		var h: float = th if t < 0.8 else lerpf(th, maxf(1.0, th * 0.6), (t - 0.8) / 0.2)
		return Vector2(w, h)


## 头发的外法线：头顶(y > 86)从头壳中心放射，往下是水平地从身体中轴往外
static func out_hair(p: Vector3) -> Vector3:
	var c := Vector3(0.0, minf(p.y, 86.0), -1.8)
	var o: Vector3 = p - c
	if p.y <= 86.0:
		o.y = 0.0
	return o


## 头发的挂骨："Head" / "Tail"(马尾链，y_head 以上挂头) / "SideLock"(鬓发链，按高度) / "Cape" / 其它骨名
func bone_fn(mode: String, y_head: int = 86) -> Callable:
	match mode:
		"Tail":
			var hid: int = rig.ids["Head"]
			return func(x: int, y: int, z: int) -> int: return hid if y >= y_head else tail_bone(x, y)
		"SideLock":
			var hid2: int = rig.ids["Head"]
			return func(x: int, y: int, z: int) -> int:
				if y >= 86:
					return hid2
				var side: String = "_L" if x >= 0 else "_R"
				return rig.ids["SideLock" + side + ("1" if y >= 78 else ("2" if y >= 71 else "3"))]
		"Cape":
			return func(x: int, y: int, z: int) -> int: return cape_bone(x, y)
		_:
			var bid: int = rig.ids[mode]
			return func(_x: int, _y: int, _z: int) -> int: return bid


## 只允许写进空格子或颜色属于 cols 的格子(头发盖头发，不盖皮肤/衣服)
func hair_guard(cols: Array) -> Callable:
	var okc := {}
	for c: int in cols:
		okc[c] = true
	return func(x: int, y: int, z: int) -> bool:
		var c: int = g.get_col(x, y, z)
		return c == 0 or okc.has(c)


## 刘海(第四版)：在头壳前面(z = 10..11)铺一簇簇平的发块，每簇 = [中心 x, 半宽, 发梢 y]；
## 发块从 y = 91 垂到发梢，最后几行收成尖；发块之间靠"一侧暗一格"分开(低对比)，顶部一条高光带。
## 后画的簇盖住先画的，所以把长的簇放后面。
func bangs_v4(clumps: Array, pal: Array, top: int = 91, hl: bool = true) -> void:
	g.sym = false
	g.use("Head")
	var seam: int = VGrid.shade(pal[0], 0.92)
	for cl: Array in clumps:
		var cx: float = cl[0]
		var hw: float = cl[1]
		var ty: float = cl[2]
		for y in range(int(floor(ty)), top + 1):
			var w: float = hw
			var fromtip: float = float(y) - ty
			if fromtip < hw * 1.2:
				w = hw * (fromtip + 0.6) / (hw * 1.2 + 0.6)
			for x in range(int(floor(cx - hw - 1.0)), int(ceil(cx + hw + 1.0))):
				var xc: float = float(x) + 0.5
				if absf(xc - cx) > w:
					continue
				var c: int = pal[0]
				if xc - cx > w - 1.0 and fromtip > 1.0:
					c = seam
				elif hl and y == top - 2 and absf(xc - cx) < w - 1.0:
					c = pal[1]
				if fromtip < 1.0:
					c = seam
				g.put(x, y, 11, c)
				if fromtip >= 2.0:
					g.put(x, y, 10, c)


# ======================================================================= 发束配色
## pal = [本色, 亮(高光), 暗(缝/里层), 更暗]；hl = 高光带在 t 上的区间；edge = 两侧缝的宽度(a 的比例)
## 缝用本色 × 0.92(低对比，和通用模型"放射状低对比发丝"一致；也在发色类别里，能整体换发色)
static func lock_col(pal: Array, hl := Vector2(0.12, 0.26), edge: float = 0.72, tint: int = 0) -> Callable:
	var seam: int = VGrid.shade(pal[0], 0.92)
	return func(t: float, a: float, d: float) -> int:
		if d > 0.62:
			return pal[3] if t > 0.15 else pal[2]
		if absf(a) > edge:
			return pal[2] if tint != 0 else seam
		if t >= hl.x and t <= hl.y and absf(a) < edge - 0.15 and d < 0.3:
			return pal[1]
		if tint != 0:
			return tint
		return pal[0]


## 一缕头发(最常用的一层封装)。pts = 发根 → 发梢；mode 见 bone_fn；mirror = 左右各一缕
func hair_lock(pts: Array, w0: float, w1: float, th: float, pal: Array, mode: String = "Head", tip: float = 0.6, hl := Vector2(0.12, 0.26), mirror: bool = false, tint: int = 0, wave := Vector2.ZERO) -> void:
	var pf: Callable = prof_lock(w0, w1, th, tip)
	var cf: Callable = lock_col(pal, hl, 0.72, tint)
	if wave.x > 0.0:
		# 波浪发：每个波峰(发束朝外鼓出的地方)一道浅色高光，代替固定的发根光带
		var y0: float = (pts[0] as Vector3).y
		var y1: float = (pts[pts.size() - 1] as Vector3).y
		var base_cf: Callable = lock_col(pal, Vector2(-1.0, -1.0), 0.72, tint)
		var light: int = pal[1] if tint == 0 else pal[0]
		cf = func(t: float, a: float, d: float) -> int:
			var yy: float = lerpf(y0, y1, t)
			if t > 0.12 and t < 0.92 and d < 0.3 and absf(a) < 0.45 and sin(yy * wave.x + wave.y) > 0.86:
				return light
			return base_cf.call(t, a, d)
	var bf: Callable = bone_fn(mode)
	if mirror:
		sweep2(pts, pf, out_hair, cf, bf)
	else:
		var save: bool = g.sym
		g.sym = false
		sweep(pts, pf, out_hair, cf, bf)
		g.sym = save


## 蓬松乱发：一圈圈短发束从头壳上往外、往下翘(发梢离开头皮 lift 格)，一层压一层；每圈 = [发根 y, 发梢 y, lift, 束数, 半宽, 相位(度)]。
## skip_front：正面 ±skip 度之内不长(留给刘海)；每束的方向带一点确定性的随机偏转(jit 度)，轮廓参差但仍是一束束干净的发块
func tousled(rows: Array, pal: Array, skip_front: float = 40.0, jit: float = 14.0, th: float = 2.6) -> void:
	for r: Array in rows:
		var ry: float = r[0]
		var ty: float = r[1]
		var lift: float = r[2]
		var nlock: int = int(r[3])
		var hw: float = r[4]
		var ph: float = r[5]
		for i in range(nlock):
			var deg: float = ph + float(i) * 360.0 / float(nlock)
			deg = fposmod(deg + 180.0, 360.0) - 180.0
			if absf(absf(deg) - 180.0) < skip_front:
				continue
			var j: float = (h01(i, int(ry), 7) - 0.5) * 2.0 * jit
			var j2: float = (h01(i, int(ry), 13) - 0.5) * 2.0
			var p0: Vector3 = on_skull(deg, ry, 0.2)
			var p1: Vector3 = on_skull(deg + j * 0.5, lerpf(ry, ty, 0.5), lift * 0.55)
			var p2: Vector3 = on_skull(deg + j, ty + j2 * 1.2, lift)
			var tint: int = VGrid.shade(pal[0], 0.92) if (i % 3 == 1) else 0
			hair_lock([p0, p1, p2], hw * 0.9, hw, th, pal, "Head", 0.5, Vector2(0.15, 0.35), false, tint)


## 头壳表面上的一点：绕 y 轴的方位角 deg(0 = 正后方，+90 = 角色左侧 +x)、高度 y，再往外 lift 格
static func on_skull(deg: float, y: float, lift: float = 0.0) -> Vector3:
	var a: float = deg_to_rad(deg)
	var ry: float = clampf((maxf(y, 77.5) - HEAD_C.y) / 10.7, -1.0, 1.0)      # 后颈以下按 y = 77.5 的截面(不往中轴缩)
	var k: float = pow(maxf(0.0, 1.0 - pow(absf(ry), 3.8)), 1.0 / 3.8)
	var sx: float = sin(a)
	var sz: float = -cos(a)
	# 超椭圆截面(n = 3.8)上沿方向 (sx, sz) 的半径
	var r: float = 1.0 / pow(pow(absf(sx) / (14.0 * k + 0.001), 3.8) + pow(absf(sz) / (12.4 * k + 0.001), 3.8), 1.0 / 3.8)
	r += lift
	return Vector3(sx * r, y, HEAD_C.z + sz * r)


# ======================================================================= 身体表面的贴片
## 在 (x,y) 处身体正面(+z)最外层的外面一格放一个体素(挂同一根骨)
func front_put(x: int, y: int, c: int, glow: int = 0, from_z: int = 24) -> void:
	for z in range(from_z, -14, -1):
		if g.solid(x, y, z):
			g.cur_bone = g.get_bone(x, y, z)
			g.cur_glow = glow
			g.put(x, y, z + 1, c)
			g.cur_glow = 0
			return


## 同上，背面(-z)
func back_put(x: int, y: int, c: int, glow: int = 0, from_z: int = -24) -> void:
	for z in range(from_z, 14):
		if g.solid(x, y, z):
			g.cur_bone = g.get_bone(x, y, z)
			g.cur_glow = glow
			g.put(x, y, z - 1, c)
			g.cur_glow = 0
			return


## 字符画贴到身体正面(或背面)：rows[0] 是最上一行；ox/oy = 左上角(x 向 +x、y 向下)；key 字符 → 颜色；"." 跳过
func pix_front(rows: Array, ox: int, oy: int, key: Dictionary, back: bool = false, outer: bool = true) -> void:
	for r in range(rows.size()):
		var s: String = rows[r]
		for i in range(s.length()):
			var ch: String = s[i]
			if ch == "." or ch == " " or not key.has(ch):
				continue
			var x: int = ox + i
			var y: int = oy - r
			if outer:
				if back:
					back_put(x, y, key[ch])
				else:
					front_put(x, y, key[ch])
			else:
				_paint_outer(x, y, key[ch], back)


func _paint_outer(x: int, y: int, c: int, back: bool) -> void:
	if back:
		for z in range(-24, 14):
			if g.solid(x, y, z):
				g.col[g.idx(x, y, z)] = c
				return
	else:
		for z in range(24, -14, -1):
			if g.solid(x, y, z):
				g.col[g.idx(x, y, z)] = c
				return


## 只在"别的骨骼没占的格子"或"本骨骼的格子"里画(衣服盖在身体上，不会把手臂/头发改挂到躯干骨)
func guard(fn: Callable) -> Callable:
	return func(x: int, y: int, z: int) -> int:
		if g.solid(x, y, z) and g.get_bone(x, y, z) != g.cur_bone:
			return 0
		return fn.call(x, y, z)


## 改色：把骨骼 bone 上、区域内满足 pred 的表面体素换成 c(fn 版本见 paint_bone)
func recolor(bone: String, x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, c: int) -> void:
	paint_bone(bone, x0, y0, z0, x1, y1, z1, func(_x: int, _y: int, _z: int) -> int: return c)


# ======================================================================= 四肢上的东西(手臂在 A 字姿势里是斜的)
## 手臂轴上的点：t = 0 肩(上臂根) → 1 肘 → 2 腕 → 2.45 指尖(左臂 +x；右臂取镜像)
static func arm_axis(t: float) -> Vector3:
	var sh := Vector3(10.5, 66.0, 0.5)
	var el := Vector3(13.0, 56.0, 0.5)
	var wr := Vector3(16.0, 47.0, 0.5)
	var tip := Vector3(17.6, 38.5, 1.2)
	if t <= 1.0:
		return sh.lerp(el, t)
	if t <= 2.0:
		return el.lerp(wr, t - 1.0)
	return wr.lerp(tip, minf(1.0, (t - 2.0) / 0.45))


## 绕手臂的一段管子(袖子/护臂/臂环)：t0..t1 为 arm_axis 参数，r0/r1 半径(n 超椭圆指数)，colfn(t, e, fb) -> 颜色
## (e = 0 轴心 .. 1 表面；fb = 截面里沿 z 方向的偏移，> 0 朝前)
## 只画左臂(+x)，配合 g.sym = true 自动镜像到右臂。挂骨按 t：< 1 上臂，< 2 前臂，其余手
func arm_tube(t0: float, t1: float, r0: float, r1: float, colfn: Callable, n: float = 2.4, hollow: float = 0.0) -> void:
	var steps: int = maxi(2, int(ceil((t1 - t0) * 24.0)))
	for i in range(steps + 1):
		var t: float = lerpf(t0, t1, float(i) / float(steps))
		var c: Vector3 = arm_axis(t)
		var d: Vector3 = (arm_axis(minf(t + 0.02, 2.45)) - arm_axis(maxf(t - 0.02, 0.0))).normalized()
		var r: float = lerpf(r0, r1, float(i) / float(steps))
		var u: Vector3 = d.cross(Vector3(0, 0, 1)).normalized()
		var v: Vector3 = d.cross(u).normalized()
		var bone: String = "UpperArm_L" if t < 1.0 else ("LowerArm_L" if t < 2.0 else "Hand_L")
		g.use(bone)
		var m: int = int(ceil(r / 0.4))
		for a in range(-m, m + 1):
			for b in range(-m, m + 1):
				var fa: float = float(a) * 0.4
				var fb: float = float(b) * 0.4
				var e: float = pow(absf(fa) / r, n) + pow(absf(fb) / r, n)
				if e > 1.0:
					continue
				if hollow > 0.0 and pow(absf(fa) / maxf(r - hollow, 0.1), n) + pow(absf(fb) / maxf(r - hollow, 0.1), n) < 1.0:
					continue
				var q: Vector3 = c + u * fa + v * fb
				var cc: int = colfn.call(t, pow(e, 1.0 / n), q.z - c.z)
				if cc != 0:
					g.put(int(floor(q.x)), int(floor(q.y)), int(floor(q.z)), cc)


## 腿上一段管子(袜口/腿环/靴筒)：y0..y1，圆心 (5.5, *, 0.5)(左腿，sym 自动镜像)
func leg_band(bone: String, y0: int, y1: int, r0: float, r1: float, colfn: Variant, n: float = 3.0, cz: float = 0.5) -> void:
	g.use(bone)
	g.ytaper(y0, y1, 5.5, cz, r0, r0, 5.5, cz, r1, r1, colfn, n)


## 袖子(斜着的圆台，水平截面，体素化比沿手臂方向扫干净)：y0(上) → y1(下)，圆心沿手臂轴(A 字姿势)，半径 r0 → r1；
## 空心(壳厚 th)，colfn(x, y, z, edge: 0 外表面 .. 1 里层, t: 0 上口 .. 1 下口)；y > 56 挂上臂，其余挂前臂(sym 自动镜像到右臂)
func sleeve(y0: int, y1: int, r0: float, r1: float, th: float, colfn: Callable, n: float = 2.3) -> void:
	for y in range(y1, y0 + 1):
		var t: float = float(y0 - y) / float(maxi(1, y0 - y1))
		var tt: float = clampf((66.0 - float(y) - 0.5) / 19.0 * 2.0, 0.0, 2.0)
		var c: Vector3 = arm_axis(tt)
		var r: float = lerpf(r0, r1, t)
		g.use("UpperArm_L" if y > 56 else "LowerArm_L")
		for z in range(int(floor(c.z - r)) - 1, int(ceil(c.z + r)) + 1):
			for x in range(int(floor(c.x - r)) - 1, int(ceil(c.x + r)) + 1):
				var dx: float = absf(float(x) + 0.5 - c.x) / r
				var dz: float = absf(float(z) + 0.5 - c.z) / r
				var e: float = pow(dx, n) + pow(dz, n)
				if e > 1.0:
					continue
				var ri: float = maxf(r - th, 0.5)
				var ei: float = pow(dx * r / ri, n) + pow(dz * r / ri, n)
				if ei < 1.0:
					if y > y1 + 1:
						continue
					var cc0: int = colfn.call(x, y, z, 1.0, t)
					if cc0 != 0 and not g.solid(x, y, z):
						g.put(x, y, z, cc0)
					continue
				var edge: float = clampf((1.0 - pow(e, 1.0 / n)) * r / maxf(th, 0.5), 0.0, 1.0)
				var cc: int = colfn.call(x, y, z, edge, t)
				if cc != 0:
					g.put(x, y, z, cc)


# ======================================================================= 裙子 / 外套下摆
## 一圈锥壳(超椭圆截面)：y_bot..y_top，prm(y) -> [cz, rx, rz]，壳厚 th。
## fn(x, y, z, ang, outer) -> 颜色(0 = 不画)；ang = 绕身体的方位角(度，0 = 正前，+90 = 左侧 +x，±180 = 正后)，outer = 外表面一层。
## 外表面判定：沿截面法线往外一格就出了壳 → 外层(不会出现里子颜色漏到外面的条纹)。
## 挂骨：y >= hip_y 挂 Hips；以下 |ang| <= side_ang 挂同侧大腿(迈腿时跟着腿走)，再往后挂 Cape 链(cape = false 则一律 Hips)
func skirt_shell(y_bot: int, y_top: int, prm: Callable, th: float, fn: Callable, hip_y: int = 44, side_ang: float = 105.0, cape: bool = true, n: float = 2.4) -> void:
	var hips_id: int = rig.ids["Hips"]
	var thl: int = rig.ids["Thigh_L"]
	var thr: int = rig.ids["Thigh_R"]
	var save_mode: int = g.mode
	var save_sym: bool = g.sym
	g.sym = false
	# 第一遍：收集壳上的格子(及其截面法线方向)
	var cells := {}
	for y in range(y_bot, y_top + 1):
		var p: Array = prm.call(y)
		var cz: float = p[0]
		var rx: float = p[1]
		var rz: float = p[2]
		for z in range(int(floor(cz - rz)) - 1, int(ceil(cz + rz)) + 2):
			for x in range(int(floor(-rx)) - 1, int(ceil(rx)) + 2):
				var xc: float = float(x) + 0.5
				var zc: float = float(z) + 0.5 - cz
				if pow(absf(xc / rx), n) + pow(absf(zc / rz), n) > 1.0:
					continue
				if pow(absf(xc / (rx - th)), n) + pow(absf(zc / (rz - th)), n) < 1.0:
					continue
				var gx: float = pow(absf(xc / rx), n - 1.0) / rx * signf(xc)
				var gz: float = pow(absf(zc / rz), n - 1.0) / rz * signf(zc)
				cells[Vector3i(x, y, z)] = Vector3(gx, gz, rad_to_deg(atan2(xc, zc)))
	# 第二遍：沿法线方向往外一格(x / z 分量够大就各走一格)还有壳 → 里层，否则外层
	g.set_mode(VGrid.ADD)
	for k: Vector3i in cells.keys():
		var v: Vector3 = cells[k]
		var gl: float = maxf(sqrt(v.x * v.x + v.y * v.y), 0.0001)
		var sx: int = int(signf(v.x)) if absf(v.x) / gl > 0.38 else 0
		var sz: int = int(signf(v.y)) if absf(v.y) / gl > 0.38 else 0
		var outer: bool = not cells.has(Vector3i(k.x + sx, k.y, k.z + sz))
		if not outer and sx != 0 and sz != 0:
			outer = not (cells.has(Vector3i(k.x + sx, k.y, k.z)) and cells.has(Vector3i(k.x, k.y, k.z + sz)))
		var ang: float = v.z
		var c: int = fn.call(k.x, k.y, k.z, ang, outer)
		if c == 0:
			continue
		var bone: int = hips_id
		if k.y < hip_y:
			if absf(ang) <= side_ang:
				bone = thl if float(k.x) + 0.5 > 0.0 else thr
			elif cape:
				bone = cape_bone(k.x, k.y)
		g.cur_bone = bone
		g.cur_glow = 0
		g.put(k.x, k.y, k.z, c)
	g.set_mode(save_mode)
	g.sym = save_sym


## 披风(背后一片两格厚的布，挂 Cape 链)：从 y_top 垂到 y_bot，半宽 w_top → w_bot，离背 z_top → z_bot，往两侧包 curl(越靠边越往前)；
## fn(x, y, u, v, outer) -> 颜色(u = -1..1 左右，v = 0 上 .. 1 下；outer = 朝外(背后)那层)；hem(u) -> 下摆在 v 上的偏移(格)
func cape_sheet(y_top: int, y_bot: int, w_top: float, w_bot: float, z_top: float, z_bot: float, curl: float, fn: Callable, hem: Callable = Callable(), th: int = 2) -> void:
	var save_sym: bool = g.sym
	var save_mode: int = g.mode
	g.sym = false
	g.set_mode(VGrid.ADD)
	for y in range(y_bot - 6, y_top + 1):
		var v: float = float(y_top - y) / float(maxi(1, y_top - y_bot))
		var w: float = lerpf(w_top, w_bot, clampf(v, 0.0, 1.0))
		var zc: float = lerpf(z_top, z_bot, clampf(v, 0.0, 1.0))
		for x in range(int(floor(-w)) - 1, int(ceil(w)) + 1):
			var xc: float = float(x) + 0.5
			var u: float = xc / w
			if absf(u) > 1.0:
				continue
			var yb: float = float(y_bot)
			if hem.is_valid():
				yb -= float(hem.call(u))
			if float(y) < yb:
				continue
			var zs: float = zc + u * u * curl
			for k in range(th):
				var z: int = int(floor(zs)) + k
				var c: int = fn.call(x, y, u, v, k == 0)
				if c == 0:
					continue
				g.cur_bone = cape_bone(x, y)
				g.cur_glow = 0
				g.put(x, y, z, c)
	g.set_mode(save_mode)
	g.sym = save_sym


## 线性插值的锥壳参数：y_top 处 [cz0, rx0, rz0] → y_bot 处 [cz1, rx1, rz1]
static func cone(y_top: int, y_bot: int, a: Vector3, b: Vector3) -> Callable:
	return func(y: int) -> Array:
		var t: float = clampf(float(y_top - y) / float(maxi(1, y_top - y_bot)), 0.0, 1.0)
		var v: Vector3 = a.lerp(b, t)
		return [v.x, v.y, v.z]


# ======================================================================= 小件
## 十字(竖 h 横 w，交叉点在 cy 往上 up 格)，axis 2 = 贴在 z 平面上
func cross_xy(cx: int, cy: int, z: int, h: int, w: int, up: int, c: int, c2: int = 0) -> void:
	for y in range(cy - h / 2, cy - h / 2 + h):
		g.put(cx, y, z, c)
	var yc: int = cy - h / 2 + h - 1 - up
	for x in range(cx - w / 2, cx - w / 2 + w):
		g.put(x, yc, z, c2 if c2 != 0 else c)


## 一片羽毛/布条(平板)：从 p0 到 p1，宽 w0 → w1，厚 th，法线 nrm；fn(t, a) -> 颜色
func plate(p0: Vector3, p1: Vector3, w0: float, w1: float, th: float, nrm: Vector3, fn: Callable, bonefn: Callable = Callable()) -> void:
	var outf := func(_p: Vector3) -> Vector3: return nrm
	var pf := func(t: float) -> Vector2: return Vector2(lerpf(w0, w1, t), th)
	var cf := func(t: float, a: float, d: float) -> int: return fn.call(t, a)
	sweep([p0, p1], pf, outf, cf, bonefn)


# ======================================================================= 蝙蝠翼(挂 Wing_L/R，sym 自动镜像)
## 翼面坐标 (u = 沿翼展往外(斜往后)，v = 往上)；root = 翼根(胸腔背后)，yaw = 翼面往后转的角度(度)。
## arm = 翼臂折线(根 → 腕 → 翼尖)，fingers = 从"腕"(arm[1])伸出去的指骨末端；膜 = 翼臂 + 各指骨末端 + 翼根下沿围成的多边形，
## 每两根指骨之间的下缘往里凹(扇贝形)。骨(翼臂/指骨)用 bone_c、膜用 mem_c(靠骨处 mem2 稍深)，厚 2 格(骨 3 格)。
func bat_wing(root: Vector3, yaw: float, arm: Array, fingers: Array, bone_c: int, mem_c: int, mem2: int, scallop: float = 2.6) -> void:
	var a: float = deg_to_rad(yaw)
	var U := Vector3(cos(a), 0.0, -sin(a))
	var D := Vector3(-sin(a), 0.0, -cos(a))
	var wrist: Vector2 = arm[1]
	# 膜的外轮廓：翼根 → 翼臂 → 翼尖 → 各指尖(之间扇贝凹进) → 翼根下沿
	var tips: Array = [arm[arm.size() - 1]]
	for f: Vector2 in fingers:
		tips.append(f)
	var poly := PackedVector2Array()
	for p: Vector2 in arm:
		poly.append(p)
	for i in range(tips.size() - 1):
		var p0: Vector2 = tips[i]
		var p1: Vector2 = tips[i + 1]
		for k in range(1, 6):
			var t: float = float(k) / 6.0
			var q: Vector2 = p0.lerp(p1, t)
			var toward: Vector2 = (wrist - q).normalized()
			poly.append(q + toward * sin(t * PI) * scallop)
		poly.append(p1)
	poly.append(Vector2(1.0, -4.0))
	var spars: Array = []
	for i in range(arm.size() - 1):
		spars.append([arm[i], arm[i + 1]])
	for f: Vector2 in fingers:
		spars.append([wrist, f])
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for p: Vector2 in poly:
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	var save_sym: bool = g.sym
	var save_mode: int = g.mode
	g.sym = true
	g.set_mode(VGrid.ADD)
	g.use("Wing_L")
	var u: float = lo.x - 1.0
	while u <= hi.x + 1.0:
		var v: float = lo.y - 1.0
		while v <= hi.y + 1.0:
			var q2 := Vector2(u, v)
			var dmin := 1e9
			for s: Array in spars:
				var sa: Vector2 = s[0]
				var sb: Vector2 = s[1]
				var ab: Vector2 = sb - sa
				var tt: float = clampf((q2 - sa).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
				dmin = minf(dmin, q2.distance_to(sa + ab * tt))
			var on_bone: bool = dmin < 0.9
			if on_bone or Geometry2D.is_point_in_polygon(q2, poly):
				var c: int = bone_c if on_bone else (mem2 if dmin < 2.2 else mem_c)
				var th: int = 3 if on_bone else 2
				for k2 in range(th):
					var p3: Vector3 = root + U * u + Vector3(0.0, v, 0.0) + D * (float(k2) - (1.0 if on_bone else 0.5))
					g.put(int(floor(p3.x)), int(floor(p3.y)), int(floor(p3.z)), c)
			v += 0.5
		u += 0.5
	g.sym = save_sym
	g.set_mode(save_mode)
	g.cur_glow = 0
