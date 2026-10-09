extends "res://tools/model_weapons.gd"
## 通用武器 · gen12 的模型(tools/build_kits.gd 按 PARTS 登记)：矛 2 把 + 单手剑 2 把 + 双手剑 2 把。
## 近战约定(同 model_weapons.gd)：原点 = 握点(拳心)，+Y = 刃(枪头)的方向，z = 刃宽，x = 厚度；拳头大约占 x -3..3、y -7..0、z -4..3。
## 尺寸照同大类现有武器：长矛 杆 2×2、y -40..62，枪头 y 62..~94(两只手握在 y 0 和 y 18 附近)；
## 单手剑 柄 y -7..2、刃 y 6..~58、柄头 y -11..-8；双手剑 柄 y -16..3(双手握)、剑格 y 4..~12、刃 ..~77、柄尾 y -22..-17。
## 颜色一律写死(VGrid.hexc；不用调色板里会按武器颜色换色的青色系)；每把的主色就是它的武器颜色。
## 刀光长度在 game/view/proj_kinds/gen12.gd 的 TRAILS(g12_*)。
## PARTS：部件名 -> [资源名, 方法名, 参数…]

const PARTS := {
	"W_polearm_g12_whalesong": ["wpn_polearm_g12_whalesong", "g12_whalesong_spear"],
	"W_polearm_g12_jadebamboo": ["wpn_polearm_g12_jadebamboo", "g12_jadebamboo_spear"],
	"W_sword_g12_goldfinch": ["wpn_sword_g12_goldfinch", "g12_goldfinch_rapier"],
	"W_sword_g12_wisteria": ["wpn_sword_g12_wisteria", "g12_wisteria_sword"],
	"W_heavy_g12_nightmare": ["wpn_heavy_g12_nightmare", "g12_nightmare_blade"],
	"W_heavy_g12_goldbell": ["wpn_heavy_g12_goldbell", "g12_goldbell_blade"],
}

const G12_WHALE_BLADE := [72, 95]
const G12_BAMBOO_BLADE := [64, 93]
const G12_FINCH_BLADE := [11, 60]
const G12_WIST_BLADE := [6, 57]
const G12_NIGHT_BLADE := [10, 76]
const G12_BELL_BLADE := [13, 78]


# ====================================================================== 小工具
## 胶囊：离线段 a→b 不超过 r 的体素(连续坐标：体素 (x, y, z) 的中心在 (x + 0.5, y + 0.5, z + 0.5))。only_empty = 只填空格子
func _g12_seg(a: Vector3, b: Vector3, r: float, c: int, glow: int = 0, only_empty: bool = false) -> void:
	var ab: Vector3 = b - a
	var l2: float = maxf(ab.dot(ab), 0.000001)
	for x in range(int(floor(minf(a.x, b.x) - r)), int(ceil(maxf(a.x, b.x) + r)) + 1):
		for y in range(int(floor(minf(a.y, b.y) - r)), int(ceil(maxf(a.y, b.y) + r)) + 1):
			for z in range(int(floor(minf(a.z, b.z) - r)), int(ceil(maxf(a.z, b.z) + r)) + 1):
				var p := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5)
				var t: float = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
				if p.distance_to(a + ab * t) > r:
					continue
				if only_empty and g.solid(x, y, z):
					continue
				D(x, y, z, c, glow)


## 扁的胶囊：只在 Y-Z 平面里量距离(a / b 是 (y, z))，x 只占 [x0, x1]——薄片(鲸尾、翅膀、羽毛)
func _g12_flat(a: Vector2, b: Vector2, r: float, x0: int, x1: int, c: int, glow: int = 0, only_empty: bool = false) -> void:
	var ab: Vector2 = b - a
	var l2: float = maxf(ab.dot(ab), 0.000001)
	for y in range(int(floor(minf(a.x, b.x) - r)), int(ceil(maxf(a.x, b.x) + r)) + 1):
		for z in range(int(floor(minf(a.y, b.y) - r)), int(ceil(maxf(a.y, b.y) + r)) + 1):
			var p := Vector2(float(y) + 0.5, float(z) + 0.5)
			var t: float = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
			if p.distance_to(a + ab * t) > r:
				continue
			for x in range(x0, x1 + 1):
				if only_empty and g.solid(x, y, z):
					continue
				D(x, y, z, c, glow)


## 球(col2：下半边的颜色)
func _g12_ball(c: Vector3, r: float, col: int, glow: int = 0, col2: int = 0) -> void:
	for x in range(int(floor(c.x - r)), int(ceil(c.x + r)) + 1):
		for y in range(int(floor(c.y - r)), int(ceil(c.y + r)) + 1):
			for z in range(int(floor(c.z - r)), int(ceil(c.z + r)) + 1):
				var p := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5)
				if p.distance_to(c) <= r:
					D(x, y, z, col2 if (col2 != 0 and p.y < c.y - r * 0.3) else col, glow)


## 2×2 的杆：每 period 格里前 light 格是 c、其余 c2
func _g12_shaft(y0: int, y1: int, c: int, c2: int, period: int, light: int) -> void:
	for y in range(y0, y1 + 1):
		B(-1, y, -1, 0, y, 0, c if posmod(y, period) < light else c2)


## 4×4 去角的箍 / 握把(c2：每隔 k 格斜着缠一道；k = 0 不缠)
func _g12_band(y0: int, y1: int, c: int, c2: int = 0, k: int = 0) -> void:
	for y in range(y0, y1 + 1):
		for x in range(-2, 2):
			for z in range(-2, 2):
				if (x == -2 or x == 1) and (z == -2 or z == 1):
					continue
				D(x, y, z, c2 if (k > 0 and c2 != 0 and posmod(y + x + z, k) == 0) else c)


## 去角的方块(半宽 h)：柄头 / 配重
func _g12_cap(y0: int, y1: int, h: int, c: int, c_top: int = 0) -> void:
	for y in range(y0, y1 + 1):
		for x in range(-h, h):
			for z in range(-h, h):
				if (x == -h or x == h - 1) and (z == -h or z == h - 1):
					continue
				D(x, y, z, c_top if (c_top != 0 and y == y1) else c)


## 2×2 的柄：底色 c、每隔 k 格一道斜缠的 c2
func _g12_grip(y0: int, y1: int, c: int, c2: int, k: int = 3) -> void:
	for y in range(y0, y1 + 1):
		for x in range(-1, 1):
			for z in range(-1, 1):
				D(x, y, z, c2 if posmod(y + x - z, k) == 0 else c)


## 刃：y0..y1，每一格的半宽 = half.call(y)；x 厚度：离刃口 ≥ 2 格的 xr2 格(-xr2..xr2-1)，其余 2 格(-1..0)；
## col.call(x, y, z, e) -> int：e = 离刃口几格(0 = 刃口)
func _g12_blade(y0: int, y1: int, half: Callable, xr2: int, col: Callable) -> void:
	for y in range(y0, y1 + 1):
		var hw: float = maxf(float(half.call(y)), 0.5)
		var za: int = int(floor(-hw))
		var zb: int = int(ceil(hw)) - 1
		for z in range(za, zb + 1):
			var e: int = mini(z - za, zb - z)
			var xr: int = xr2 if (e >= 2 and y < y1 - 3) else 1
			for x in range(-xr, xr):
				D(x, y, z, int(col.call(x, y, z, e)))


# ====================================================================== 鲸歌长枪(蓝 · 矛 · 2)
## 一杆深海蓝的长枪：藏青枪杆上一道道浅蓝的浪纹，两段深蓝皮握把，银蓝色的箍；枪口箍上托着一条往上甩起的鲸尾——
## 尾柄从箍里升起，两片尾鳍往两边(±Z)展开、尖端往上翘(背面深蓝、腹面带白斑，像座头鲸)，尾鳍正中升起一片海蓝的叶形枪刃
## (浅蓝刃口、刃心一线发光的蓝)；尾鳍和刃根边上浮着几颗发光的小气泡。
## 杆 y -40..62，枪口箍 y 58..63，尾柄 y 63..70，尾鳍 y 66..78(z ±11)，枪刃 y 72..95，杆尾银箍 + 圆头。
func g12_whalesong_spear() -> void:
	_begin(false)
	var sh := VGrid.hexc("#1d3270")
	var sh2 := VGrid.hexc("#294a95")
	var wave := VGrid.hexc("#9cc4ff")
	var gr := VGrid.hexc("#142650")
	var gr2 := VGrid.hexc("#3c64b4")
	var si := VGrid.hexc("#c0cee8")
	var si2 := VGrid.hexc("#8193b9")
	var wh := VGrid.hexc("#2c5cb8")
	var wh2 := VGrid.hexc("#1d3f8a")
	var belly := VGrid.hexc("#dce8ff")
	var bl := VGrid.hexc("#4f87e2")
	var bl2 := VGrid.hexc("#d2e4ff")
	var core := VGrid.hexc("#6cc0ff")
	var bub := VGrid.hexc("#b2e6ff")
	# ---- 杆：藏青，隔一段一道浅蓝的浪纹(在四个面上起伏)
	_g12_shaft(-40, 62, sh, sh2, 10, 7)
	# 浪纹：每 13 格一段、5 格长的浅蓝螺旋(画在杆面上，不凸出来)
	var spiral: Array = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(0, 0), Vector2i(-1, 0)]
	for y in range(-36, 57):
		if posmod(y, 13) < 5:
			var sp: Vector2i = spiral[posmod(y, 4)]
			D(sp.x, y, sp.y, wave)
			var sp2: Vector2i = spiral[posmod(y + 2, 4)]
			D(sp2.x, y, sp2.y, wave if posmod(y, 13) == 2 else sh2)
	# 握把(右手 y -4..5、左手 y 14..22)：深蓝皮斜缠
	_g12_band(-4, 5, gr, gr2, 3)
	_g12_band(14, 22, gr, gr2, 3)
	for yb: int in [-30, 30, 46]:
		_g12_band(yb, yb + 1, si2, si, 2)
	# ---- 杆尾：银箍 + 圆头
	_g12_band(-44, -41, si, si2, 2)
	_g12_ball(Vector3(0, -45.5, 0), 1.6, si2)
	# ---- 枪口箍
	_g12_band(58, 63, si, si2, 4)
	B(-2, 60, -2, 1, 61, 1, si2)
	# ---- 尾柄：从箍里升起，往上收细(背面 +X 一侧深一点)
	for y2 in range(63, 71):
		var r: float = lerpf(2.4, 1.6, float(y2 - 63) / 7.0)
		for x2 in range(-3, 3):
			for z2 in range(-3, 3):
				var p := Vector2(float(x2) + 0.5, float(z2) + 0.5)
				if p.length() <= r:
					D(x2, y2, z2, wh2 if x2 >= 1 else wh)
	# ---- 两片尾鳍：从尾柄往 ±Z 展开、尖端往上翘；后缘(下沿)一排白斑
	for s: int in [-1, 1]:
		var pts: Array = [Vector2(68.0, 1.5 * s), Vector2(68.6, 4.0 * s), Vector2(69.6, 6.6 * s), Vector2(71.0, 8.8 * s), Vector2(72.8, 10.6 * s),
			Vector2(74.8, 11.9 * s)]
		var rads: Array = [3.0, 3.4, 3.3, 2.9, 2.2, 1.1]
		for i2 in range(pts.size() - 1):
			_g12_flat(pts[i2], pts[i2 + 1], float(rads[i2]), -1, 0, wh)
			_g12_flat(pts[i2] + Vector2(0.4, 0.0), pts[i2 + 1] + Vector2(0.4, 0.0), float(rads[i2]) * 0.55, 1, 1, wh2)
			_g12_flat(pts[i2] + Vector2(0.4, 0.0), pts[i2 + 1] + Vector2(0.4, 0.0), float(rads[i2]) * 0.55, -2, -2, wh)
		# 下沿的白斑(座头鲸尾鳍的腹面)
		for k in range(5):
			var q: Vector2 = (pts[k] as Vector2).lerp(pts[k + 1] as Vector2, 0.5)
			var lo: int = int(floor(q.x - float(rads[k]) + 0.6))
			D(-1, lo, int(floor(q.y)), belly)
			D(0, lo, int(floor(q.y)) - s * (k % 2), belly)
	# ---- 枪刃：叶形，最宽处在刃根往上 5 格
	var y0: int = G12_WHALE_BLADE[0]
	var y1: int = G12_WHALE_BLADE[1]
	var hb := func(y: int) -> float:
		var t: float = float(y - y0) / float(y1 - y0)
		var hw: float = 1.8 + 1.4 * sin(clampf(t * 2.6, 0.0, PI * 0.5)) - 2.6 * pow(t, 1.7)
		if y > y1 - 8:
			hw = minf(hw, lerpf(2.0, 0.5, float(y - (y1 - 8)) / 8.0))
		return hw
	var cb := func(xx: int, y: int, zz: int, e: int) -> int:
		if e == 0:
			return bl2
		return bl if (_vhash(xx, y, zz) % 5) != 0 else wh
	_g12_blade(y0, y1, hb, 1, cb)
	for y3 in range(y0 + 1, y1 - 4):
		B(-1, y3, -1, 0, y3, 0, core, 80)
	# ---- 浮着的小气泡(发光)
	for bp: Vector3i in [Vector3i(-1, 74, 4), Vector3i(0, 77, -5), Vector3i(-1, 80, 3), Vector3i(0, 83, -3), Vector3i(-1, 71, -8), Vector3i(0, 73, 8)]:
		D(bp.x, bp.y, bp.z, bub, 120)
	_end()


# ====================================================================== 翠竹长枪(青 · 矛 · 4)
## 一根还带着竹叶的翠竹削成的长枪：青绿的竹竿每 10 格一个竹节(浅色节环、下面一道深线、微微鼓出来)，几个竹节上抽出两三片竹叶；
## 握把缠着麻绳；枪口是一个粗一圈的竹节，枪头是一片青玉(半透明的翠青、刃口近白、刃心一线发光)，刃根两侧各伸出一片斜向上的竹叶，
## 箍下吊一颗青玉珠。杆 y -40..62，枪口竹节 y 58..63，玉刃 y 64..93，杆尾一个封口的竹节。
func g12_jadebamboo_spear() -> void:
	_begin(false)
	var bb := VGrid.hexc("#2f9f86")
	var bb2 := VGrid.hexc("#27866f")
	var nd := VGrid.hexc("#79d3b2")
	var nd2 := VGrid.hexc("#1d6a57")
	var rope := VGrid.hexc("#cdbd8c")
	var rope2 := VGrid.hexc("#a38f62")
	var lf := VGrid.hexc("#4fbf7c")
	var lf2 := VGrid.hexc("#a0e6b0")
	var jd := VGrid.hexc("#4fd2ae")
	var jd2 := VGrid.hexc("#2fae8c")
	var jd3 := VGrid.hexc("#b6f5e2")
	var core := VGrid.hexc("#6dffcf")
	# ---- 竹竿：竖纹(两种青绿交错)，每 10 格一个竹节
	for y in range(-40, 63):
		for x in range(-1, 1):
			for z in range(-1, 1):
				D(x, y, z, bb if posmod(x + z + y / 7, 2) == 0 else bb2)
	for yn in range(-36, 58, 10):
		_g12_band(yn, yn, nd)
		_g12_band(yn - 1, yn - 1, nd2)
	# 竹节上抽出的竹叶：细长、往外上方斜伸(薄片)
	var leaves: Array = [[34, 1, 0], [34, -1, 1], [44, 1, 1], [-26, -1, 0], [54, -1, 0]]
	for lv: Array in leaves:
		var yl: int = int(lv[0])
		var s: int = int(lv[1])
		var along_x: bool = int(lv[2]) == 1
		for k in range(1, 9):
			var w: int = 1 if (k < 2 or k > 6) else 2
			var yy: int = yl + 1 + int(round(float(k) * 0.55))
			var off: int = 1 + k
			for j in range(w):
				var cc: int = lf2 if k == 8 else (lf if j == 0 else lf2)
				if along_x:
					D(off * s - (1 if s < 0 else 0), yy + j, -1 + (k % 2), cc)
				else:
					D(-1 + (k % 2), yy + j, off * s - (1 if s < 0 else 0), cc)
	# 握把：麻绳
	_g12_band(-4, 5, rope, rope2, 2)
	_g12_band(14, 22, rope, rope2, 2)
	# ---- 杆尾：封口的竹节
	_g12_band(-42, -41, nd)
	B(-1, -43, -1, 0, -43, 0, nd2)
	# ---- 枪口：粗一圈的竹节(y 58..63)
	_g12_band(58, 63, bb, nd2, 4)
	_g12_band(63, 63, nd)
	for z0: int in [-3, 2]:
		B(-1, 59, z0, 0, 62, z0, bb2)
	for x0: int in [-3, 2]:
		B(x0, 59, -1, x0, 62, 0, bb2)
	# 吊着的青玉珠(+Z 一侧，绳 + 珠)
	for k2 in range(4):
		D(0, 57 - k2, 2, rope2)
	_g12_ball(Vector3(0.5, 51.5, 2.5), 1.5, jd, 60, jd2)
	# ---- 刃根两侧的竹叶(往 ±Z 斜向上伸)
	for s2: int in [-1, 1]:
		_g12_flat(Vector2(63.5, 1.5 * s2), Vector2(67.0, 5.0 * s2), 1.2, -1, 0, lf)
		_g12_flat(Vector2(67.0, 5.0 * s2), Vector2(71.5, 7.0 * s2), 0.9, -1, 0, lf)
		_g12_flat(Vector2(71.5, 7.0 * s2), Vector2(74.0, 7.4 * s2), 0.6, -1, 0, lf2)
	# ---- 青玉枪刃：叶形
	var y0: int = G12_BAMBOO_BLADE[0]
	var y1: int = G12_BAMBOO_BLADE[1]
	var hb := func(y: int) -> float:
		var t: float = float(y - y0) / float(y1 - y0)
		var hw: float = 2.0 + 1.5 * sin(clampf(t * 2.4, 0.0, PI * 0.5)) - 2.9 * pow(t, 1.6)
		if y > y1 - 8:
			hw = minf(hw, lerpf(2.1, 0.5, float(y - (y1 - 8)) / 8.0))
		return hw
	var cb := func(x: int, y: int, z: int, e: int) -> int:
		if e == 0:
			return jd3
		return jd if (_vhash(x, y, z) % 4) != 0 else jd2
	_g12_blade(y0, y1, hb, 1, cb)
	for y3 in range(y0 + 1, y1 - 4):
		B(-1, y3, -1, 0, y3, 0, core, 75)
	_end()


# ====================================================================== 金雀细剑(黄 · 单手剑 · 2)
## 一把细长的金色刺剑，护手是一只张开翅膀的小金雀：鹅黄的身子蹲在剑根上，翅膀往两边(±Z)张开、尖端往上翘(黑底、一道明黄的翅斑、白色的羽尖)，
## 头朝剑尖(红脸、黑顶)，细长的金色剑身就是从它的喙里伸出来的。+Z 一侧一道金色的护指弓弯到柄头；黑皮柄缠金丝，柄头一颗金球，挂一根短尾羽。
## 身子 y 2..8，头 y 8..11，刃 y 11..60，翅膀 z ±10(尖到 y 12)，柄 y -7..1，柄头 y -11..-8。
func g12_goldfinch_rapier() -> void:
	_begin(false)
	var yl := VGrid.hexc("#f4d23a")
	var yl2 := VGrid.hexc("#d9b326")
	var bk := VGrid.hexc("#1d1b1e")
	var bar := VGrid.hexc("#ffdf4f")
	var wt := VGrid.hexc("#f6f3ea")
	var red := VGrid.hexc("#d8402a")
	var bk2 := VGrid.hexc("#2a2522")
	var au := VGrid.hexc("#e1b444")
	var au2 := VGrid.hexc("#f7da7c")
	var au3 := VGrid.hexc("#9c7424")
	var bd := VGrid.hexc("#e8cd6a")
	var bd2 := VGrid.hexc("#fff3b6")
	var bd3 := VGrid.hexc("#b8902e")
	var beak := VGrid.hexc("#f0c2a0")
	var eye := VGrid.hexc("#0e0c10")
	# ---- 柄：黑皮缠金丝
	_g12_grip(-7, 1, bk2, au, 3)
	# ---- 柄头：金球 + 一根往下垂的短尾羽(黑底白尖)
	_g12_ball(Vector3(0, -9.5, 0), 2.0, au, 0, au3)
	for k in range(5):
		D(-1 + k % 2, -12 - k, 0, bk if k < 4 else wt)
	# ---- 护指弓(+Z 一侧，从翅根弯到柄头，避开拳头 z -4..3)
	var bow: Array = [Vector2(2.5, 3.5), Vector2(0.0, 5.2), Vector2(-4.0, 5.6), Vector2(-7.5, 4.6), Vector2(-9.5, 2.2)]
	for i in range(bow.size() - 1):
		_g12_flat(bow[i], bow[i + 1], 0.55, -1, 0, au)
	# ---- 身子：圆滚滚的鹅黄(背 -X 一侧略深)，下腹白
	_g12_ball(Vector3(0.0, 5.4, 0.0), 3.4, yl, 0, wt)
	for x in range(-3, 3):
		for y in range(3, 9):
			for z in range(-3, 3):
				if g.solid(x, y, z) and x <= -3:
					D(x, y, z, yl2)
	# ---- 头：红脸、黑顶，眼睛在两侧(±X)
	_g12_ball(Vector3(0.0, 9.8, 0.0), 2.3, red)
	for x2 in range(-2, 2):
		for z2 in range(-2, 2):
			D(x2, 12, z2, bk)
			if absi(z2 * 2 + 1) > 1:
				D(x2, 11, z2, bk)
	D(-2, 10, -1, eye)
	D(1, 10, -1, eye)
	D(-2, 10, 0, eye)
	D(1, 10, 0, eye)
	# 喙(淡粉，刃根)
	B(-1, 12, -1, 0, 13, 0, beak)
	# ---- 翅膀：往 ±Z 张开、尖端往上翘；黑底，一道明黄翅斑，白色羽尖
	for s: int in [-1, 1]:
		var wp: Array = [Vector2(5.0, 2.0 * s), Vector2(6.0, 5.0 * s), Vector2(8.0, 7.8 * s), Vector2(11.0, 9.8 * s)]
		var wr: Array = [2.2, 1.9, 1.4, 0.8]
		for i2 in range(wp.size() - 1):
			_g12_flat(wp[i2], wp[i2 + 1], float(wr[i2]), -1, 0, bk)
		# 翅斑：沿着翅膀中线一道明黄
		for i3 in range(3):
			var a: Vector2 = wp[i3]
			var b2: Vector2 = wp[i3 + 1]
			for k2 in range(4):
				var q: Vector2 = a.lerp(b2, float(k2) / 4.0) + Vector2(0.4, 0.0)
				D(-1, int(floor(q.x)), int(floor(q.y)), bar)
				D(0, int(floor(q.x)), int(floor(q.y)), bar)
		# 羽尖(白)：翅膀下沿的几根飞羽
		for k3 in range(3):
			var tip: Vector2 = (wp[1] as Vector2).lerp(wp[3] as Vector2, float(k3) / 2.0)
			var lo: int = int(floor(tip.x - float(wr[1]) * 0.9))
			D(-1, lo, int(floor(tip.y)) + s, wt)
			D(0, lo, int(floor(tip.y)), wt)
		D(-1, 12, 10 * s - (1 if s < 0 else 0), wt)
		D(0, 12, 10 * s - (1 if s < 0 else 0), wt)
	# ---- 剑身：细长的金色刺剑(中脊深金，刃口浅金)，从喙里伸出去
	var y0: int = G12_FINCH_BLADE[0]
	var y1: int = G12_FINCH_BLADE[1]
	var hb := func(y: int) -> float:
		var t: float = float(y - y0) / float(y1 - y0)
		var hw: float = lerpf(1.5, 1.0, t)
		if y > y1 - 7:
			hw = lerpf(1.0, 0.5, float(y - (y1 - 7)) / 7.0)
		return hw
	var cb := func(x: int, yy: int, z: int, e: int) -> int:
		if e == 0 and absi(z) > 0:
			return bd2
		return bd3 if (x == -1 and z == -1 and yy < y1 - 10) else bd
	_g12_blade(y0 + 2, y1, hb, 1, cb)
	_end()


# ====================================================================== 紫藤长剑(紫 · 单手剑 · 4)
## 一柄银白的长剑(浅紫的血槽)，剑格是一截紫藤老藤横档，两头各垂下一串紫藤花穗(上深紫、往下渐浅到淡紫白，挂在拳头两边)；
## 一根细藤从剑格顺着剑身螺旋往上爬到一半，藤上隔几格在刃口外开一小簇紫花；柄缠着老藤，柄头是一团紫色的花苞。
## 刃 y 6..57，剑格 y 3..5(z -7..6)，花穗 y -6..4(z ±8)，柄 y -7..2，柄头 y -11..-8。
func g12_wisteria_sword() -> void:
	_begin(false)
	var sv := VGrid.hexc("#e6e4f0")
	var sv2 := VGrid.hexc("#ffffff")
	var fu := VGrid.hexc("#c4b0e6")
	var vn := VGrid.hexc("#5e4a6c")
	var vn2 := VGrid.hexc("#7d6690")
	var lf := VGrid.hexc("#79b86a")
	var p1 := VGrid.hexc("#7c4cc8")
	var p2 := VGrid.hexc("#a27ae6")
	var p3 := VGrid.hexc("#cdb4f6")
	var p4 := VGrid.hexc("#efe4ff")
	# ---- 柄：老藤缠绕
	_g12_grip(-7, 2, vn, vn2, 3)
	# ---- 柄头：一团紫花苞
	_g12_ball(Vector3(0.0, -9.0, 0.0), 2.1, p2, 0, p1)
	D(-1, -11, 0, p3, 40)
	D(0, -11, -1, p3, 40)
	# ---- 剑格：老藤横档(微微扭)
	for z in range(-7, 7):
		var dy: int = 1 if posmod(z, 5) == 0 else 0
		B(-2, 3 + dy, z, 1, 4 + dy, z, vn if posmod(z, 3) != 0 else vn2)
	B(-1, 5, -3, 0, 5, 2, vn2)
	# 几片叶子
	for lz: Array in [[-6, 1], [5, -1], [-2, 1]]:
		D(-2, 5, int(lz[0]), lf)
		D(1, 5, int(lz[0]) + int(lz[1]), lf)
	# ---- 两串花穗：挂在剑格两头(z ±8)，往下垂、越往下越细越浅
	for s: int in [-1, 1]:
		var zc: float = 8.0 * float(s)
		for yy in range(-8, 5):
			var t: float = float(4 - yy) / 12.0
			var r: float = lerpf(2.4, 0.7, t)
			var c: int = p1 if t < 0.3 else (p2 if t < 0.6 else (p3 if t < 0.85 else p4))
			for x in range(-3, 3):
				for z2 in range(int(floor(zc - 3.0)), int(ceil(zc + 3.0))):
					var p := Vector2(float(x) + 0.5, float(z2) + 0.5 - zc + 0.5 * float(s))
					if p.length() <= r + (0.3 if posmod(yy, 2) == 0 else 0.0):
						D(x, yy, z2, c, 35 if c == p4 else 0)
		B(-1, 5, int(zc) - (1 if s < 0 else 0), 0, 5, int(zc) - (1 if s < 0 else 0), vn)
	# ---- 剑身：银白，浅紫血槽，最后 8 格收尖
	var y0: int = G12_WIST_BLADE[0]
	var y1: int = G12_WIST_BLADE[1]
	var halves := {}
	var hb := func(y: int) -> float:
		var t: float = float(y - y0) / float(y1 - y0)
		var hw: float = lerpf(3.3, 2.3, t)
		if y > y1 - 8:
			hw = lerpf(hw, 0.5, float(y - (y1 - 8)) / 8.0)
		return hw
	var cb := func(x: int, y: int, z: int, e: int) -> int:
		if e == 0:
			return sv2
		if (z == -1 or z == 0) and y < y1 - 9:
			return fu
		return sv
	for y in range(y0, y1 + 1):
		halves[y] = float(hb.call(y))
	_g12_blade(y0, y1, hb, 1, cb)
	# ---- 细藤：螺旋爬到剑身一半；绕到刃口时在外面开一小簇紫花
	var bloom_next: int = y0 + 4
	for y2 in range(y0, y0 + 28):
		var th: float = float(y2 - y0) * 0.36
		var half2: float = float(halves[y2])
		var cz: float = cos(th)
		var sz: float = sin(th)
		var za2: int = int(floor(-half2))
		var zb2: int = int(ceil(half2)) - 1
		var zz: int = clampi(int(round(sz * half2 * 0.85)) - (1 if sz < 0.0 else 0), za2, zb2)
		if cz >= 0.4:
			D(1, y2, zz, vn2)
		elif cz <= -0.4:
			D(-2, y2, zz, vn2)
		else:
			var ze2: int = zb2 + 1 if sz > 0.0 else za2 - 1
			B(-1, y2, ze2, 0, y2, ze2, vn2)
			if y2 >= bloom_next:
				bloom_next = y2 + 7
				var s2: int = 1 if sz > 0.0 else -1
				B(-1, y2, ze2 + s2, 0, y2 + 1, ze2 + s2, p2)
				D(-1, y2 - 1, ze2 + s2, p1)
				D(0, y2 - 1, ze2 + 2 * s2, p3, 40)
				D(-1, y2 - 2, ze2 + s2, p3)
				D(0, y2 + 1, ze2 + 2 * s2, p4, 50)
	_end()


# ====================================================================== 梦魇巨剑(紫 · 双手剑 · 2)
## 一把夜紫色的巨剑：刃口像烟一样起伏(波浪刃)，暗紫的刃身上爬着一道道发光的紫色细纹；刃根正中(两面都有)睁着一只半闭的眼——
## 上半被深紫的眼皮盖住、眼皮边一排睫毛，露出下半的淡紫眼白和发光的紫色竖瞳。剑格是两根往外上方弯起的黑紫尖角，
## 柄缠深紫皮带，柄尾一颗暗色的圆珠，里面透出一点紫光。刃 y 10..76，剑格 y 4..15(z ±11)，柄 y -16..3，柄尾 y -22..-17。
func g12_nightmare_blade() -> void:
	_begin(false)
	var dk := VGrid.hexc("#3a2258")
	var dk2 := VGrid.hexc("#2a1842")
	var ed := VGrid.hexc("#9a76d8")
	var vein := VGrid.hexc("#c27cff")
	var hn := VGrid.hexc("#2b1c3e")
	var hn2 := VGrid.hexc("#4a3168")
	var gr := VGrid.hexc("#24142f")
	var gr2 := VGrid.hexc("#5c2f84")
	var orb := VGrid.hexc("#1a1024")
	var lid := VGrid.hexc("#4f2f73")
	var lash := VGrid.hexc("#120a18")
	var ew := VGrid.hexc("#efe4ff")
	var iris := VGrid.hexc("#b43cff")
	var pup := VGrid.hexc("#120a18")
	# ---- 柄：深紫皮带斜缠
	for y in range(-16, 4):
		for x in range(-1, 1):
			for z in range(-1, 1):
				D(x, y, z, gr2 if posmod(y + x - z, 4) == 0 else gr)
	# ---- 柄尾：暗色圆珠 + 一点紫光
	_g12_ball(Vector3(0.0, -19.5, 0.0), 2.6, orb)
	B(-3, -20, -1, -3, -19, 0, vein, 90)
	B(2, -20, -1, 2, -19, 0, vein, 90)
	# ---- 剑格：中间一块 + 两根往外上方弯的尖角
	_g12_cap(4, 8, 3, hn, hn2)
	for s: int in [-1, 1]:
		var hp: Array = [Vector2(6.0, 2.0 * s), Vector2(6.5, 6.0 * s), Vector2(8.5, 9.0 * s), Vector2(12.0, 10.8 * s), Vector2(15.5, 11.0 * s)]
		var hr: Array = [1.8, 1.6, 1.2, 0.8]
		for i in range(hp.size() - 1):
			var a: Vector2 = hp[i]
			var b2: Vector2 = hp[i + 1]
			_g12_seg(Vector3(-0.0, a.x, a.y), Vector3(-0.0, b2.x, b2.y), float(hr[i]), hn if i < 2 else hn2)
	B(-2, 6, -1, 1, 7, 0, vein, 80)
	# ---- 刃：波浪刃口，暗紫刃身
	var y0: int = G12_NIGHT_BLADE[0]
	var y1: int = G12_NIGHT_BLADE[1]
	var hb := func(y: int) -> float:
		var t: float = float(y - y0) / float(y1 - y0)
		var hw: float = lerpf(5.6, 2.6, t) + 0.75 * sin(float(y) * 0.5)
		if y > y1 - 10:
			hw *= 1.0 - pow(float(y - (y1 - 10)) / 11.0, 1.15)
		return hw
	var cb := func(x: int, y: int, z: int, e: int) -> int:
		if e == 0:
			return ed
		return dk2 if (x == -2 or x == 1) and posmod(y + z, 9) == 0 else dk
	_g12_blade(y0, y1, hb, 2, cb)
	# 发光的细纹：从刃根往上蜿蜒的几道(两面)
	for v: Array in [[-2.0, 0.0], [2.0, 2.1], [0.0, 4.2]]:
		for y2 in range(y0 + 16, y1 - 8):
			var zf: float = float(v[0]) + 1.6 * sin(float(y2) * 0.22 + float(v[1]))
			var hw2: float = float(hb.call(y2))
			if absf(zf) > hw2 - 1.5:
				continue
			if posmod(y2 + int(v[1] * 3.0), 7) == 0:
				continue
			var zi: int = int(floor(zf))
			D(-2, y2, zi, vein, 70)
			D(1, y2, zi, vein, 70)
	# ---- 刃根的眼睛(两面，x = -3 / 2 贴在刃面上)：杏仁形，上半被眼皮盖住
	var ec := Vector2(19.5, -0.5)
	for face: int in [-3, 2]:
		for y3 in range(14, 26):
			for z3 in range(-6, 6):
				var q := Vector2(float(y3) + 0.5, float(z3) + 0.5) - ec
				var almond: float = absf(q.x) / 3.6 + pow(absf(q.y) / 5.2, 1.6)
				if almond > 1.0:
					continue
				var c: int = ew
				if q.x > 0.4:
					c = lid                                  # 上半：眼皮
				elif absf(q.y) < 1.0 and q.x > -1.8:
					c = pup                                  # 竖瞳
				elif q.length() < 2.6:
					c = iris
				D(face, y3, z3, c, 110 if c == iris else 0)
			# 睫毛：眼皮下沿往下的一排短线
		for zl in range(-4, 4, 2):
			D(face, 19, zl, lash)
		for zl2 in range(-5, 5):
			var top: Vector2 = Vector2(0.0, float(zl2) + 0.5)
			if absf(top.y) < 5.0:
				D(face, 22 + (0 if absf(top.y) > 3.0 else 1), zl2, lid)
	_end()


# ====================================================================== 金钟巨剑(黄 · 双手剑 · 4)
## 一把宽刃的金色巨剑：剑格铸成一口小铜钟(钟口朝下、套在柄上，钟身一圈发光的铭文带，钟口一道亮边)，钟顶的钮托着剑身；
## 剑身是宽阔的金刃(浅金刃口，深金血槽)，血槽里一圈圈往上扩散的"钟声"弧纹微微发光；红褐皮柄缠金箍，柄尾一颗金球、垂一截红绳。
## 刃 y 13..78，钟 y 3..12(半径 5.5 → 2.6)，柄 y -16..2，柄尾 y -22..-17。
func g12_goldbell_blade() -> void:
	_begin(false)
	var au := VGrid.hexc("#e2b23c")
	var au2 := VGrid.hexc("#fff0b8")
	var au3 := VGrid.hexc("#b5862a")
	var br := VGrid.hexc("#c38c38")
	var br2 := VGrid.hexc("#e8bb5a")
	var br3 := VGrid.hexc("#8a5a20")
	var ins := VGrid.hexc("#ffd870")
	var lp := VGrid.hexc("#f6cf66")
	var ring := VGrid.hexc("#ffe596")
	var amb := VGrid.hexc("#f09a1e")
	var le := VGrid.hexc("#7a3a22")
	var le2 := VGrid.hexc("#5a2816")
	var rd := VGrid.hexc("#c8352a")
	# ---- 柄：红褐皮，四道金箍
	for y in range(-16, 3):
		for x in range(-1, 1):
			for z in range(-1, 1):
				D(x, y, z, le2 if posmod(y + x - z, 3) == 0 else le)
	for yb: int in [-13, -8, -3]:
		B(-2, yb, -2, 1, yb, 1, au)
	# ---- 柄尾：金球 + 一截红绳
	_g12_ball(Vector3(0.0, -19.5, 0.0), 2.4, au, 0, au3)
	for k in range(5):
		D(0, -22 - k, 0, rd)
	D(-1, -26, 0, rd)
	# ---- 钟：钟口朝下(y 3)，往上收到钟肩(y 10)，钟顶 y 11..12
	var c0 := Vector2(-0.0, -0.0)
	for y2 in range(3, 13):
		var t: float = float(y2 - 3) / 9.0
		var r: float = lerpf(6.6, 3.4, pow(t, 0.8))
		if y2 == 3:
			r = 7.0
		if y2 >= 11:
			r = 2.9 if y2 == 11 else 2.1
		for x2 in range(-8, 8):
			for z2 in range(-8, 8):
				var p := Vector2(float(x2) + 0.5, float(z2) + 0.5) - c0
				var d: float = p.length()
				if d > r:
					continue
				var c: int = br
				if y2 <= 4:
					c = lp                                   # 钟口的亮边
				elif y2 == 7:
					c = ins                                  # 铭文带
				elif p.x > 1.5:
					c = br3                                  # 背光的一侧
				elif p.x < -2.5:
					c = br2
				D(x2, y2, z2, c, 70 if c == ins and posmod(int(round(atan2(p.y, p.x) * 4.0)), 2) == 0 else 0)
	# 钟口里是暗的(露出柄)
	for x3 in range(-5, 5):
		for z3 in range(-5, 5):
			var p2 := Vector2(float(x3) + 0.5, float(z3) + 0.5)
			if p2.length() < 4.6 and not (x3 >= -1 and x3 <= 0 and z3 >= -1 and z3 <= 0):
				D(x3, 3, z3, br3)
	# ---- 剑身：宽阔的金刃
	var y0: int = G12_BELL_BLADE[0]
	var y1: int = G12_BELL_BLADE[1]
	var hb := func(y: int) -> float:
		var t: float = float(y - y0) / float(y1 - y0)
		var hw: float = lerpf(6.0, 3.6, t)
		if y > y1 - 10:
			hw *= 1.0 - pow(float(y - (y1 - 10)) / 11.0, 1.15)
		return hw
	var cb := func(x: int, y: int, z: int, e: int) -> int:
		if e == 0:
			return au2
		if (z == -1 or z == 0) and y < y1 - 8 and (x == -2 or x == 1):
			return au3
		return au
	_g12_blade(y0, y1, hb, 2, cb)
	# "钟声"弧纹：血槽两边一圈圈往上扩散的弧(两面，微光)
	for yc: int in [22, 33, 44, 55]:
		for z4 in range(-6, 6):
			var zf: float = float(z4) + 0.5
			var yy: int = yc + int(round(-0.14 * zf * zf))
			var hw3: float = float(hb.call(yy))
			if absf(zf) > hw3 - 0.9:
				continue
			for dy in range(2):
				D(-3 if dy == 0 else -2, yy + dy, z4, ring if dy == 0 else amb, 110 if dy == 0 else 40)
				D(2 if dy == 0 else 1, yy + dy, z4, ring if dy == 0 else amb, 110 if dy == 0 else 40)
	_end()
