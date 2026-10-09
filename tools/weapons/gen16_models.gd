extends "res://tools/model_weapons.gd"
## 通用武器 · gen16 的模型(tools/build_kits.gd 按 PARTS 登记)：法器 3 把、弓 2 把、步枪 1 把。
## 法器竖着握(+Z = 上、-Y = 前)，柄的轴心在 (x 0, y -3)(F3_AXIS，同杨柳净瓶 / 玫瑰花束)；拳头大约占 x -3..3、y -7..0、z -4..3。
## 弓(照 gen6 / gen10 / gen13 的弓)：弓坐标系原点 = 握把中心，Y = 弓臂方向，+Z = 弓腹(朝目标)，弦在 z = BowModel.STRING_Z；
##   弓臂按 |y| 分段绑 Bow_U1/U2、Bow_D1/D2，弦在端帽骨与搭箭点(Bow_Nock)之间插值；箭画在 Arrow 骨上(局部 z = 0 为箭尾)。
## 步枪照 spotter_rifle() / gen11：手枪式握把在原点，护木 y -32..-13(左手托在 y -13 附近)，枪管到 y -50 左右，枪托 y 7..19。
##   枪械约定：-Y = 枪口，+Z = 上，x = 厚度，握把沿 -Z 往下。
## 颜色一律写死(VGrid.hexc；不用调色板里会按武器颜色换色的青色系)；每把的主色就是它的武器颜色。
## PARTS：部件名 -> [资源名, 方法名, 参数…]

const PARTS := {
	"W_focus_g16_gourd": ["wpn_focus_g16_gourd", "g16_jade_gourd"],
	"W_focus_g16_totem": ["wpn_focus_g16_totem", "g16_beast_totem"],
	"W_focus_g16_firefly": ["wpn_focus_g16_firefly", "g16_firefly_jar"],
	"W_bow_g16_konghou": ["wpn_bow_g16_konghou", "g16_konghou_bow"],
	"W_bow_g16_luan": ["wpn_bow_g16_luan", "g16_luan_bow"],
	"W_rifle_g16_sunflower": ["wpn_rifle_g16_sunflower", "g16_sunflower_rifle"],
}


# ====================================================================== 法器：共用
## 绕轴心的一层圆片，半径 r(连续)；col(q, d, nd) 给颜色(q = 相对轴心的平面坐标，d = 到轴心的距离，nd = 朝亮面的程度 -1..1)；
## hollow > 0 时只画外面 hollow 格厚的一圈
func _g16_ring(z: int, r: float, col: Callable, hollow: float = 0.0, glow: int = 0) -> void:
	for x in range(int(floor(F3_AXIS.x - r)) - 1, int(ceil(F3_AXIS.x + r)) + 1):
		for y in range(int(floor(F3_AXIS.y - r)) - 1, int(ceil(F3_AXIS.y + r)) + 1):
			var q := Vector2(float(x) + 0.5 - F3_AXIS.x, float(y) + 0.5 - F3_AXIS.y)
			var d: float = q.length()
			if d > r or (hollow > 0.0 and d < r - hollow):
				continue
			var nd: float = q.normalized().dot(Vector2(-0.6, -0.8)) if d > 0.1 else 0.0
			var c: int = col.call(q, d, nd)
			if c != 0:
				D(x, y, z, c, glow)


## 三档明暗：亮面 hi、正常 c、背光 lo
static func _g16_shade(nd: float, c: int, hi: int, lo: int) -> int:
	return hi if nd > 0.45 else (lo if nd < -0.45 else c)


# ====================================================================== 青玉葫芦(绿 · 法器 · 2)
## 一只青玉雕的小葫芦，托在一根缠满红绳的柄上(柄 z -6..2，底下一枚金柄头)：下肚圆鼓鼓的(z 3..12，正面刻着金色的乾卦 ☰)、
## 束腰处系一道红绳(正面打结，垂下一束红穗子 + 金珠)、上肚小一圈(z 13..18)，葫芦口一道金箍、木塞 + 金顶，塞子上飘起一缕发光的青雾。
## 玉色：亮面浅、背光深，往上偏亮；几道深一点的玉纹。全高 z -7..24，宽约 x -5..4。
func g16_jade_gourd() -> void:
	_begin(false)
	var jd := VGrid.hexc("#3f9e68")
	var jd2 := VGrid.hexc("#7cd29c")
	var jd3 := VGrid.hexc("#2a6e48")
	var jdk := VGrid.hexc("#1d4d33")
	var jdw := VGrid.hexc("#b8f0cc")
	var au := VGrid.hexc("#cfa54a")
	var au2 := VGrid.hexc("#ecca72")
	var au3 := VGrid.hexc("#8c6a22")
	var rd := VGrid.hexc("#b8283a")
	var rd2 := VGrid.hexc("#e0485a")
	var rd3 := VGrid.hexc("#7e1626")
	var wd := VGrid.hexc("#7a5230")
	var wd2 := VGrid.hexc("#9c6d40")
	var mist := VGrid.hexc("#c8f5dc")
	# ---- 柄：金柄头(z -7..-6) + 缠红绳的玉柄(z -5..2，一圈圈红绳斜着缠)
	_f3_disc(-7, 1.7, au3, au, au3)
	_f3_disc(-6, 2.2, au, au2, au3)
	for z in range(-5, 3):
		if posmod(z, 3) == 2:
			_f3_disc(z, 1.7, rd3, rd, rd3)                                  # 一圈圈绳之间的凹缝
		else:
			_f3_disc(z, 1.8, rd, rd2, rd3)
	_f3_disc(2, 2.1, au, au2, au3)
	# ---- 葫芦：下肚 + 束腰 + 上肚
	for z2 in range(3, 19):
		var zc: float = float(z2) + 0.5
		var r1: float = 4.5 * sqrt(maxf(0.0, 1.0 - pow((zc - 7.6) / 4.6, 2.0)))
		var r2: float = 3.0 * sqrt(maxf(0.0, 1.0 - pow((zc - 15.4) / 3.2, 2.0)))
		var r: float = maxf(maxf(r1, r2), 1.6)
		var up: float = clampf((zc - 3.0) / 16.0, 0.0, 1.0)
		_g16_ring(z2, r, func(q2: Vector2, d2: float, nd2: float) -> int:
			var c: int = _g16_shade(nd2 + up * 0.25, jd, jd2, jd3)
			# 玉纹：几道斜着的深色细纹
			var ang2: float = atan2(q2.y, q2.x)
			if d2 > r - 1.0 and absf(fposmod(ang2 * 2.0 + zc * 0.35, TAU) - 1.0) < 0.12:
				c = jdk if nd2 < 0.3 else jd3
			# 下肚亮面上一块高光
			if d2 > r - 1.0 and nd2 > 0.82 and zc > 7.0 and zc < 10.0:
				c = jdw
			return c)
	# 正面(-Y)刻着金色的乾卦(三道横)
	for tz: int in [6, 8, 10]:
		var rr: float = 4.5 * sqrt(maxf(0.0, 1.0 - pow((float(tz) + 0.5 - 7.6) / 4.6, 2.0)))
		var fy: int = int(floor(F3_AXIS.y - rr + 0.5))
		B(-2, fy, tz, 1, fy, tz, au2)
	# ---- 束腰的红绳(z 12) + 正面一个结 + 垂下的红穗子(金珠)
	_g16_ring(12, 2.3, func(_q: Vector2, _d: float, nd3: float) -> int: return _g16_shade(nd3, rd, rd2, rd3), 0.9)
	B(-1, -6, 12, 0, -6, 12, rd2)
	D(-2, -6, 13, rd)
	D(1, -6, 13, rd)
	_f3_line([Vector3(0.5, -6.2, 11.5), Vector3(1.4, -7.6, 10.0), Vector3(2.2, -8.4, 7.5)], rd)
	B(1, -9, 6, 2, -8, 7, au2)
	for sx in range(1, 4):
		for sz in range(1, 6):
			D(sx, -9, sz, rd if posmod(sx + sz, 2) == 0 else rd3)
	D(2, -9, 0, rd2)
	# ---- 葫芦口：金箍 + 木塞 + 金顶
	_f3_disc(19, 1.6, au, au2, au3)
	_f3_disc(20, 1.4, wd, wd2, wd)
	_f3_disc(21, 1.2, wd2, wd2, wd)
	D(-1, -4, 22, au2)
	D(0, -4, 22, au)
	D(-1, -3, 22, au)
	D(0, -3, 22, au2)
	# ---- 一缕青雾(发光)
	for mp: Vector3i in [Vector3i(0, -3, 23), Vector3i(1, -3, 24), Vector3i(1, -2, 25), Vector3i(0, -2, 26), Vector3i(-1, -2, 27)]:
		D(mp.x, mp.y, mp.z, mist, 70)
	_end()


# ====================================================================== 三兽图腾(绿 · 法器 · 4)
## 一根长满青苔的老木图腾，竖着握：缠皮的木柄(z -6..3)，往上一截方方正正的图腾柱(截面 x -4..3、y -7..0)，从下到上刻着三张兽脸(都朝 -Y)：
##   蟾蜍(z 4..9，最宽：两只鼓出来的大眼、一道宽嘴)、蜘蛛(z 11..15，深绿：两大两小四只眼、一对小獠牙，两侧各伸出三条折着的腿)、
##   狮子(z 17..22：一圈青苔长成的鬃毛围着脸、突出的鼻吻、两只小耳朵)；三张脸的眼睛都点着发光的绿火。
## 脸与脸之间一道深色的刻线；柱身零星的青苔、顶上一撮苔 + 一棵小芽。全高 z -7..25，宽约 x -7..6。
const G16_TOTEM_X0 := -4
const G16_TOTEM_X1 := 3
const G16_TOTEM_Y0 := -7
const G16_TOTEM_Y1 := 0


func g16_beast_totem() -> void:
	_begin(false)
	var wd := VGrid.hexc("#6e4c2c")
	var wd2 := VGrid.hexc("#8e6a40")
	var wd3 := VGrid.hexc("#4a321c")
	var lt := VGrid.hexc("#3a2616")
	var ms := VGrid.hexc("#4f8a34")
	var ms2 := VGrid.hexc("#7cb84c")
	var ms3 := VGrid.hexc("#33602a")
	var td := VGrid.hexc("#5f9a46")
	var td2 := VGrid.hexc("#8cc466")
	var td3 := VGrid.hexc("#3f6e30")
	var sp := VGrid.hexc("#244a2c")
	var sp2 := VGrid.hexc("#3a6a40")
	var sp3 := VGrid.hexc("#16301c")
	var ln := VGrid.hexc("#9a8a48")
	var ln2 := VGrid.hexc("#c0ac62")
	var ln3 := VGrid.hexc("#6c5e2c")
	var eye := VGrid.hexc("#3cf05a")
	var eye2 := VGrid.hexc("#9cff9a")
	var fang := VGrid.hexc("#e8e4cc")
	var dk := VGrid.hexc("#1a1410")
	# ---- 柄：缠皮的木柄 + 木柄头
	_f3_disc(-7, 1.5, wd3, wd, wd3)
	_f3_disc(-6, 2.0, wd, wd2, wd3)
	for z in range(-5, 4):
		_f3_disc(z, 1.7, lt if posmod(z, 2) == 0 else wd3, wd if posmod(z, 2) == 0 else wd2, lt)
	# ---- 图腾柱：三段方柱(蟾蜍那段宽一圈)，柱身的木纹 + 零星青苔
	for z2 in range(4, 23):
		var wide: int = 1 if z2 <= 9 else 0
		var c0: int = td if z2 <= 9 else (sp if z2 <= 15 else wd2)
		var c1: int = td2 if z2 <= 9 else (sp2 if z2 <= 15 else ln2)
		var c2: int = td3 if z2 <= 9 else (sp3 if z2 <= 15 else wd)
		if z2 == 10 or z2 == 16:
			c0 = wd3
			c1 = wd
			c2 = lt
		for x in range(G16_TOTEM_X0 - wide, G16_TOTEM_X1 + wide + 1):
			for y in range(G16_TOTEM_Y0 - wide, G16_TOTEM_Y1 + wide + 1):
				var edge_x: bool = x == G16_TOTEM_X0 - wide or x == G16_TOTEM_X1 + wide
				var edge_y: bool = y == G16_TOTEM_Y0 - wide or y == G16_TOTEM_Y1 + wide
				if edge_x and edge_y:
					continue                                              # 去掉四条竖棱
				var c: int = c0
				if y == G16_TOTEM_Y0 - wide or x == G16_TOTEM_X0 - wide:
					c = c1                                                # 正面 / 左面亮一档
				elif y == G16_TOTEM_Y1 + wide or x == G16_TOTEM_X1 + wide:
					c = c2
				if (edge_x or edge_y) and posmod(x * 7 + y * 3 + z2 * 5, 13) == 0:
					c = ms if posmod(z2, 2) == 0 else ms2                # 零星青苔
				D(x, y, z2, c)
	var fy: int = G16_TOTEM_Y0 - 1                                         # 正面再往外一格(脸上凸出来的部分)
	# ---- 蟾蜍(z 4..9)：两只鼓出来的大眼(顶上)、一道宽嘴(深色 + 浅色嘴唇)、两颊的疙瘩
	for ex: int in [-4, 2]:
		B(ex, fy - 1, 8, ex + 1, fy, 10, td2)
		B(ex, fy - 1, 9, ex + 1, fy - 1, 9, eye, 70)
		D(ex, fy - 1, 10, td)
		D(ex + 1, fy - 1, 10, td)
	B(-4, fy - 1, 5, 3, fy - 1, 5, dk)
	B(-4, fy - 1, 6, 3, fy - 1, 6, td2)
	B(-3, fy - 1, 4, 2, fy - 1, 4, td3)
	for w: Vector2i in [Vector2i(-5, 7), Vector2i(4, 7), Vector2i(-2, 7), Vector2i(1, 7)]:
		D(w.x, fy, w.y, td3)
	# ---- 蜘蛛(z 11..15)：四只眼(两大两小)、一对獠牙、两侧各三条折着的腿
	B(-3, fy, 13, -2, fy, 14, eye, 70)
	B(1, fy, 13, 2, fy, 14, eye, 70)
	D(-4, fy, 15, eye2, 50)
	D(3, fy, 15, eye2, 50)
	B(-2, fy, 11, -2, fy, 12, fang)
	B(1, fy, 11, 1, fy, 12, fang)
	B(-1, fy, 12, 0, fy, 12, sp3)
	for sgn: int in [-1, 1]:
		for k in range(3):
			var lz: int = 11 + k * 2
			var x0: int = G16_TOTEM_X1 + 1 if sgn > 0 else G16_TOTEM_X0 - 1
			var ly: int = -6 + k * 2
			# 往外伸(x)再往下折
			for m in range(3):
				D(x0 + sgn * m, ly, lz + 1, sp if m < 2 else sp2)
			D(x0 + sgn * 3, ly, lz, sp2)
			D(x0 + sgn * 3, ly, lz - 1, sp)
			D(x0 + sgn * 3, ly, lz - 2, sp3)
	# ---- 狮子(z 17..22)：鬃毛(一圈青苔，围着脸)、鼻吻、眼、耳
	for z3 in range(16, 25):
		for x3 in range(-6, 6):
			for y3 in range(G16_TOTEM_Y0 - 1, G16_TOTEM_Y1 + 2):
				var dxm: float = float(x3) + 0.5
				var dzm: float = float(z3) + 0.5 - 19.8
				var rm: float = sqrt(dxm * dxm + dzm * dzm)
				if rm > 5.6 or rm < 3.6:
					continue
				var inside_col: bool = x3 >= G16_TOTEM_X0 and x3 <= G16_TOTEM_X1 and y3 >= G16_TOTEM_Y0 and y3 <= G16_TOTEM_Y1
				if inside_col and z3 <= 22:
					continue
				if y3 > G16_TOTEM_Y1 and rm < 4.6:
					continue
				var mc: int = ms if posmod(x3 * 3 + z3 * 5 + y3, 4) != 0 else ms2
				if rm > 5.0:
					mc = ms3 if posmod(x3 + z3, 3) == 0 else ms
				D(x3, y3, z3, mc)
	B(-2, fy - 1, 17, 1, fy - 1, 19, ln)                                   # 鼻吻
	B(-1, fy - 2, 18, 0, fy - 2, 19, ln2)
	B(-1, fy - 2, 19, 0, fy - 2, 19, dk)                                   # 鼻头
	B(-1, fy - 1, 17, 0, fy - 1, 17, ln3)                                  # 嘴
	D(-3, fy, 21, eye, 70)
	D(2, fy, 21, eye, 70)
	B(-3, fy, 22, -2, fy, 22, ln3)                                         # 眉骨
	B(1, fy, 22, 2, fy, 22, ln3)
	for ex2: int in [-4, 3]:
		B(ex2, -5, 23, ex2, -3, 24, ln)
	# ---- 顶上：一撮青苔 + 一棵小芽(两片嫩叶)
	B(-3, -6, 23, 2, -1, 23, ms)
	B(-2, -5, 24, 1, -2, 24, ms2)
	D(0, -4, 25, ms)
	D(0, -4, 26, ms2)
	D(-1, -4, 27, ms2, 20)
	D(1, -4, 27, ms2, 20)
	_end()


# ====================================================================== 萤火虫瓶(黄 · 法器 · 2)
## 一只用麻绳吊着的小玻璃瓶，托在一根缠麻绳的木柄上(z -6..2)：黄铜瓶托(z 3)，夜色的玻璃瓶身(z 4..14，圆角)、
## 瓶底一丛青草，瓶身里外零星十几只发光的萤火虫(亮黄 / 浅黄，有的拖着暗色的小尾巴)，亮面一道竖着的反光；
## 瓶颈系一道麻绳、软木塞、瓶顶一个麻绳提环。全高 z -7..21，宽约 x -4..3。
## 萤火虫：[方位角(弧度，0 = +X、π/2 = +Y)、高度 z、离瓶身多远(0 = 贴在瓶面上 = 看得见瓶里那只，1 = 在瓶外飞)]
const G16_FIREFLIES := [
	[4.1, 6, 0], [4.7, 8, 0], [5.4, 7, 0], [0.2, 10, 0], [3.6, 11, 1], [4.9, 12, 0], [2.6, 12, 0], [1.6, 9, 0],
	[0.9, 5, 0], [3.3, 13, 0], [4.4, 10, 1], [5.9, 13, 0], [4.0, 9, 0], [1.2, 13, 1], [2.9, 7, 0], [5.1, 5, 0],
]


func g16_firefly_jar() -> void:
	_begin(false)
	var hm := VGrid.hexc("#b89a62")
	var hm2 := VGrid.hexc("#d8bc84")
	var hm3 := VGrid.hexc("#8a7040")
	var wd := VGrid.hexc("#6a4a2c")
	var wd2 := VGrid.hexc("#8a6440")
	var br := VGrid.hexc("#c99b45")
	var br2 := VGrid.hexc("#ecc675")
	var br3 := VGrid.hexc("#8c6a2a")
	var gl := VGrid.hexc("#22344a")
	var gl2 := VGrid.hexc("#3c5670")
	var gl3 := VGrid.hexc("#18243a")
	var glh := VGrid.hexc("#a8c8dc")
	var gr := VGrid.hexc("#4a8a3a")
	var gr2 := VGrid.hexc("#76b056")
	var ff := VGrid.hexc("#ffcf2a")
	var ff2 := VGrid.hexc("#ffe680")
	var ffk := VGrid.hexc("#5a4a20")
	var ck := VGrid.hexc("#c9a46c")
	var ck2 := VGrid.hexc("#e0c08a")
	# ---- 柄：缠麻绳的木柄 + 木柄头
	_f3_disc(-7, 1.4, wd, wd2, wd)
	_f3_disc(-6, 1.9, wd, wd2, wd)
	for z in range(-5, 3):
		_f3_disc(z, 1.7, hm if posmod(z, 2) == 0 else hm3, hm2, hm3)
	# ---- 黄铜瓶托
	_f3_disc(3, 3.4, br, br2, br3)
	# ---- 玻璃瓶身(z 4..14，上下圆角)：夜色玻璃，亮面一道竖着的反光；瓶底一丛青草
	for z2 in range(4, 15):
		var r: float = 3.6
		if z2 == 4:
			r = 3.0
		elif z2 == 14:
			r = 3.0
		elif z2 == 13:
			r = 3.4
		_g16_ring(z2, r, func(q: Vector2, d: float, nd: float) -> int:
			var c: int = _g16_shade(nd, gl, gl2, gl3)
			if d > r - 1.0 and nd > 0.78 and z2 >= 6 and z2 <= 12:
				c = glh
			if z2 <= 5 and d > r - 1.0 and posmod(int(floor(atan2(q.y, q.x) * 3.0)) + z2, 2) == 0:
				c = gr if z2 == 4 else gr2
			return c)
	# 萤火虫：贴着瓶身的一层(发光)，有的拖着暗色的小尾巴
	for i in range(G16_FIREFLIES.size()):
		var f: Array = G16_FIREFLIES[i]
		var fr: float = 3.3 + 1.1 * float(f[2])
		var fx: int = int(floor(F3_AXIS.x + cos(float(f[0])) * fr))
		var fy: int = int(floor(F3_AXIS.y + sin(float(f[0])) * fr))
		var fz: int = int(f[1])
		D(fx, fy, fz, ff if i % 3 != 0 else ff2, 75 if i % 2 == 0 else 55)
		if i % 4 == 1:
			D(fx, fy, fz - 1, ffk)
		elif i % 4 == 3:
			D(fx, fy, fz + 1, ff, 40)
	# ---- 瓶肩 / 瓶颈 / 瓶口
	_f3_disc(15, 2.4, gl, gl2, gl3)
	_g16_ring(16, 2.0, func(_q: Vector2, _d: float, nd2: float) -> int: return _g16_shade(nd2, hm, hm2, hm3))      # 麻绳
	_f3_disc(17, 2.4, gl2, glh, gl)
	# ---- 软木塞 + 麻绳提环
	_f3_disc(18, 1.8, ck, ck2, ck)
	_f3_disc(19, 1.5, ck2, ck2, ck)
	for i2 in range(0, 13):
		var a: float = PI * float(i2) / 12.0
		var px: int = int(floor(F3_AXIS.x + cos(a) * 2.6))
		var pz: int = int(floor(19.5 + sin(a) * 2.4))
		D(px, -3, pz, hm if i2 % 2 == 0 else hm3)
	_end()


# ====================================================================== 弓：共用的"弓臂分段 + 端帽 + 弦"(照 gen6 / gen10 / gen13)
func _g16_bow_begin() -> void:
	g.tx = -16
	g.ty = 44
	g.tz = 3
	g.sym = false
	g.mode = VGrid.FILL
	g.use("Bow")
	left = false


## 把还在 Bow 骨上的体素按 |y| 分到 Bow_U1/U2、Bow_D1/D2
func _g16_bow_bones(r1: float, r2: float) -> void:
	var bow_id: int = rig.ids["Bow"]
	for z in range(-26, 26):
		for y in range(-64, 64):
			for x in range(-16, 16):
				if not g.inb(x, y, z):
					continue
				var i: int = g.idx(x, y, z)
				if g.col[i] == 0 or g.bn[i] != bow_id:
					continue
				var aa := absf(float(y) + 0.5)
				if aa >= r2:
					g.bn[i] = rig.ids["Bow_U2"] if y >= 0 else rig.ids["Bow_D2"]
				elif aa >= r1:
					g.bn[i] = rig.ids["Bow_U1"] if y >= 0 else rig.ids["Bow_D1"]


## 端帽 + 弦(权重在端帽骨与搭箭点之间线性分配) + 搭箭点
func _g16_bow_string(tip: int, cap: int, string_c: int, string_glow: int, nock_c: int) -> void:
	var sz: int = BowModel.STRING_Z
	for sgn2: float in [1.0, -1.0]:
		var bone := "Bow_U2" if sgn2 > 0.0 else "Bow_D2"
		var b_id: int = rig.ids[bone]
		var nock_id: int = rig.ids["Bow_Nock"]
		g.use(bone)
		var ytip := tip - 1 if sgn2 > 0.0 else -tip
		g.box(-1, ytip - 1, sz - 1, 0, ytip + 1, sz + 1, cap)
		for a2 in range(0, tip - 1):
			var y := a2 if sgn2 > 0.0 else -a2 - 1
			var t := (float(a2) + 0.5) / float(tip - 1)
			g._put(0, y, sz, string_c, b_id, string_glow)
			g.set_weights(0, y, sz, [[b_id, t], [nock_id, 1.0 - t]])
	g.use("Bow_Nock")
	g.box(-1, -1, sz - 1, 0, 0, sz, nock_c)


## 弓臂：从 |y| = a0 到 tip，沿弓臂中线画一节节的圆杆(半径从 r0 收到 r1)；col(a) 给每一节的颜色
func _g16_limbs(a0: int, tip: int, r0: float, r1: float, col: Callable) -> void:
	for sgn: float in [1.0, -1.0]:
		for a in range(a0, tip):
			var ya := float(a) * sgn
			var yb := float(a + 1) * sgn
			var r := lerpf(r0, r1, float(a - a0) / float(tip - a0))
			g.seg(Vector3(0.0, ya, BowModel.zc(ya)), Vector3(0.0, yb, BowModel.zc(yb)), r, r, col.call(a, sgn), true)


# ====================================================================== 凤首箜篌(黄 · 弓 · 3)
## 一架改成长弓的凤首箜篌：金色的弓臂(一节亮一节暗)，握把是深色漆木 + 金箍；上半张弓的弓腹一侧(+Z)立着一根朱漆描金的琴柱(y 7..36)，
## 柱顶往弓臂弯过去接上，琴柱和弓臂之间绷着五根发光的金弦(像一架小箜篌)；上弓梢是一只回首的金凤(凤头、金喙朝前、发光的红眼、
## 三根往后飘的凤冠羽)，下弓梢垂着三根长长的凤尾羽(金 / 橙 / 朱，尾梢一点亮)。弦是淡金(微光)。箭：金杆、朱羽、发光的金箭头。
const G16_HARP_TIP := 48
const G16_HARP_PILLAR_Z := 7


func g16_konghou_bow() -> void:
	_g16_bow_begin()
	var au := VGrid.hexc("#d9a62a")
	var au2 := VGrid.hexc("#f5d26a")
	var au3 := VGrid.hexc("#9a6c14")
	var lk := VGrid.hexc("#4a2414")
	var lk2 := VGrid.hexc("#6a3420")
	var vm := VGrid.hexc("#b02a26")
	var vm2 := VGrid.hexc("#d84a3a")
	var og := VGrid.hexc("#f08a20")
	var sw := VGrid.hexc("#fff0a8")
	var ey := VGrid.hexc("#ff3a2a")
	# 握把：深色漆木 + 上下金箍，正中一颗金珠
	g.box(-2, -8, -2, 1, 8, 2, lk)
	for sy in range(-6, 7, 3):
		g.box(-2, sy, -2, 1, sy, 2, lk2)
	g.box(-3, 7, -3, 2, 8, 3, au)
	g.box(-3, -8, -3, 2, -7, 3, au)
	g.cur_glow = 60
	g.box(-1, -1, 3, 0, 0, 3, au2)
	g.cur_glow = 0
	# 弓臂：金，每 6 格一道亮节
	_g16_limbs(9, G16_HARP_TIP, 2.0, 1.1, func(a: int, _s: float) -> int: return au2 if posmod(a, 6) == 0 else (au if posmod(a, 6) < 4 else au3))
	# ---- 琴柱：上半张弓的弓腹一侧(z = PILLAR_Z)，朱漆描金；柱脚接握把顶的金箍，柱顶往弓臂弯过去
	for y in range(7, 37):
		var c: int = vm if posmod(y, 5) != 0 else au2
		g.box(-1, y, G16_HARP_PILLAR_Z - 1, 0, y, G16_HARP_PILLAR_Z, c)
	g.box(-1, 7, 3, 0, 8, G16_HARP_PILLAR_Z, au)
	var top_a := Vector3(-0.5, 36.5, float(G16_HARP_PILLAR_Z) - 0.5)
	var top_b := Vector3(-0.5, 40.5, BowModel.zc(40.5) + 1.0)
	g.seg(top_a, top_b, 1.0, 1.0, vm, true)
	g.seg(top_a, top_a + (top_b - top_a) * 0.15, 1.2, 1.2, au2, true)
	# 五根发光的金弦：从琴柱绷到弓臂(沿 z)
	g.cur_glow = 70
	for sy2: int in [14, 19, 24, 29, 34]:
		var zl: int = int(ceil(BowModel.zc(float(sy2)) + 1.6))
		for z2 in range(zl, G16_HARP_PILLAR_Z - 1):
			g.box(-1, sy2, z2, -1, sy2, z2, sw)
	g.cur_glow = 0
	# ---- 上弓梢：回首的金凤(凤头在弓梢稍往弓腹一侧，金喙朝前 +Z，红眼，三根往后(-Z)上飘的凤冠羽)
	var hy: float = float(G16_HARP_TIP) - 1.0
	var hz: float = BowModel.zc(hy) + 2.2
	g.seg(Vector3(-0.5, hy - 3.0, hz - 1.6), Vector3(-0.5, hy, hz), 1.5, 2.1, au, false)
	g.seg(Vector3(-0.5, hy, hz), Vector3(-0.5, hy + 0.6, hz + 1.2), 2.1, 1.6, au2, false)
	g.box(-1, int(hy), int(hz) + 3, 0, int(hy), int(hz) + 4, og)                      # 喙
	g.box(-1, int(hy) - 1, int(hz) + 3, 0, int(hy) - 1, int(hz) + 3, au3)
	g.cur_glow = 140
	g.box(-2, int(hy) + 1, int(hz) + 1, -2, int(hy) + 1, int(hz) + 1, ey)
	g.box(1, int(hy) + 1, int(hz) + 1, 1, int(hy) + 1, int(hz) + 1, ey)
	g.cur_glow = 0
	for cf: Array in [[Vector3(-0.5, hy + 2.0, hz - 0.5), Vector3(-0.5, hy + 5.5, hz - 3.0), vm], [Vector3(-0.5, hy + 1.6, hz - 1.0), Vector3(-0.5, hy + 4.0, hz - 4.8), og],
			[Vector3(-0.5, hy + 1.0, hz - 1.5), Vector3(-0.5, hy + 2.0, hz - 5.8), au2]]:
		g.seg(cf[0], cf[1], 0.8, 0.5, cf[2], true)
	# ---- 下弓梢：三根长长的凤尾羽(往下、往弦那一侧飘)，尾梢一点亮
	var ty: float = -float(G16_HARP_TIP) + 1.0
	var tz: float = BowModel.zc(ty)
	for tf: Array in [[Vector3(-0.5, ty - 6.0, tz + 1.5), au], [Vector3(-0.5, ty - 7.5, tz - 1.5), og], [Vector3(-0.5, ty - 5.5, tz - 4.0), vm]]:
		var tip_p: Vector3 = tf[0]
		g.seg(Vector3(-0.5, ty, tz), tip_p, 1.0, 0.7, tf[1], true)
		g.cur_glow = 90
		g.box(-1, int(floor(tip_p.y)), int(floor(tip_p.z)), 0, int(floor(tip_p.y)), int(floor(tip_p.z)), sw)
		g.cur_glow = 0
	_g16_bow_bones(19.0, 32.0)
	_g16_bow_string(G16_HARP_TIP, au2, VGrid.hexc("#ffe9a0"), 35, au3)
	_g16_arrow(au, vm, vm2, au2, sw, 90)
	_end()


## 箭(Arrow 骨，局部 z = 0 为箭尾)：杆、四片羽、箭头(照 gen13)
func _g16_arrow(shaft: int, fletch: int, fletch2: int, head: int, head2: int, head_glow: int = 0) -> void:
	g.tx = -14
	g.ty = 45
	g.tz = -10
	g.use("Arrow")
	g.box(0, 0, 0, 1, 1, 40, shaft)
	for z2 in range(1, 7):
		var c: int = fletch if z2 > 2 else fletch2
		g.box(0, 2, z2, 0, 3, z2, c)
		g.box(0, -2, z2, 0, -1, z2, c)
		g.box(2, 0, z2, 3, 0, z2, c)
		g.box(-2, 0, z2, -1, 0, z2, c)
	g.cur_glow = head_glow
	g.box(-1, -1, 41, 2, 2, 42, head)
	g.box(0, 0, 43, 1, 1, 44, head2)
	g.cur_glow = 0
	g.box(-2, 0, -1, 1, 1, 0, fletch2)


# ====================================================================== 青鸾长弓(青 · 弓 · 3)
## 一张青鸾展翅的长弓：两条弓臂是两只翅膀——青色的弓臂上，弓腹一侧(+Z)一片压一片地长着翎羽(越往弓梢越短，羽尖一道白)；
## 上弓梢是鸾首(青色的头、金色的小喙朝前、发光的白眼、三根往后飘的长冠羽)，下弓梢拖着两根长长的尾羽(末端一点金色的"眼")。
## 握把缠深青皮革、银箍，正中弓腹上一颗发光的青玉。弦是淡青色(微光)。箭：一支整根的青色翎羽(白羽轴、青羽片、银箭头)。
const G16_LUAN_TIP := 48


func g16_luan_bow() -> void:
	_g16_bow_begin()
	var cy := VGrid.hexc("#2aa8b8")
	var cy2 := VGrid.hexc("#6fdde8")
	var cy3 := VGrid.hexc("#17707e")
	var cyd := VGrid.hexc("#0f4a56")
	var wt := VGrid.hexc("#eafcff")
	var lt := VGrid.hexc("#1a4a52")
	var lt2 := VGrid.hexc("#2a6470")
	var sv := VGrid.hexc("#c6d4dc")
	var sv2 := VGrid.hexc("#eef4f8")
	var au := VGrid.hexc("#e0b040")
	var au2 := VGrid.hexc("#ffd870")
	var jd := VGrid.hexc("#5ff0e0")
	# 握把：深青皮革 + 银箍，正中弓腹一颗发光的青玉
	g.box(-2, -8, -2, 1, 8, 2, lt)
	for sy in range(-6, 7, 3):
		g.box(-2, sy, -2, 1, sy, 2, lt2)
	g.box(-3, 7, -3, 2, 8, 3, sv)
	g.box(-3, -8, -3, 2, -7, 3, sv)
	g.cur_glow = 110
	g.box(-1, -1, 3, 0, 0, 4, jd)
	g.cur_glow = 0
	# 弓臂(翅骨)：青
	_g16_limbs(9, G16_LUAN_TIP, 2.0, 1.1, func(a: int, _s: float) -> int: return cy if posmod(a, 7) != 0 else cy2)
	# 翎羽：弓腹一侧，从 |y| = 10 起每 3 格一片，大幅往弓梢方向斜着长(像收拢的翅膀)、越往弓梢越短；下层深青长、上层青短，羽尖一道白
	for sgn: float in [1.0, -1.0]:
		var a := 10
		var n := 0
		while a < G16_LUAN_TIP - 5:
			var ya: float = float(a) * sgn
			var base := Vector3(-0.5, ya, BowModel.zc(ya) + 1.2)
			var u: float = float(a - 10) / float(G16_LUAN_TIP - 15)
			var length: float = lerpf(12.0, 4.0, u)
			var dir := Vector3(0.0, 0.85 * sgn, 0.75 - 0.35 * u).normalized()
			var tip_p: Vector3 = base + dir * length
			g.seg(base, tip_p, 1.4, 0.7, cy3 if n % 2 == 0 else cyd, true)
			var tip2: Vector3 = base + Vector3(0.0, 0.0, 0.8) + dir * length * 0.6
			g.seg(base + Vector3(0.0, 0.0, 0.8), tip2, 1.2, 0.6, cy if n % 2 == 0 else cy2, true)
			g.seg(tip_p - dir * 1.4, tip_p, 0.7, 0.5, wt, true)
			a += 3
			n += 1
	# ---- 上弓梢：鸾首(青色的头，小金喙朝前 +Z，发光的白眼，三根往后(-Z)飘的长冠羽)
	var hy: float = float(G16_LUAN_TIP) - 1.0
	var hz: float = BowModel.zc(hy) + 1.8
	g.seg(Vector3(-0.5, hy - 3.0, hz - 1.4), Vector3(-0.5, hy, hz), 1.4, 2.0, cy, false)
	g.seg(Vector3(-0.5, hy, hz), Vector3(-0.5, hy + 0.5, hz + 1.0), 2.0, 1.5, cy2, false)
	g.box(-1, int(hy), int(hz) + 3, 0, int(hy), int(hz) + 4, au)
	g.box(-1, int(hy), int(hz) + 5, 0, int(hy), int(hz) + 5, au2)
	g.cur_glow = 150
	g.box(-2, int(hy) + 1, int(hz) + 1, -2, int(hy) + 1, int(hz) + 1, wt)
	g.box(1, int(hy) + 1, int(hz) + 1, 1, int(hy) + 1, int(hz) + 1, wt)
	g.cur_glow = 0
	for cf: Array in [[Vector3(-0.5, hy + 5.0, hz - 3.5), cy2], [Vector3(-0.5, hy + 3.5, hz - 6.0), cy], [Vector3(-0.5, hy + 1.5, hz - 7.5), cy3]]:
		g.seg(Vector3(-0.5, hy + 1.2, hz - 0.8), cf[0], 0.8, 0.5, cf[1], true)
	# ---- 下弓梢：两根长长的尾羽(往下、往弦那一侧飘)，末端一点金色的"眼"
	var ty: float = -float(G16_LUAN_TIP) + 1.0
	var tz: float = BowModel.zc(ty)
	for tf: Array in [[Vector3(-0.5, ty - 8.0, tz + 0.5), cy2], [Vector3(-0.5, ty - 6.5, tz - 3.5), cy]]:
		var tp: Vector3 = tf[0]
		g.seg(Vector3(-0.5, ty, tz), tp, 1.1, 0.8, tf[1], true)
		g.cur_glow = 80
		g.box(-1, int(floor(tp.y)), int(floor(tp.z)), 0, int(floor(tp.y)) + 1, int(floor(tp.z)), au2)
		g.cur_glow = 0
		g.box(-1, int(floor(tp.y)) - 1, int(floor(tp.z)), 0, int(floor(tp.y)) - 1, int(floor(tp.z)), cyd)
	_g16_bow_bones(19.0, 32.0)
	_g16_bow_string(G16_LUAN_TIP, sv2, VGrid.hexc("#c8f4ff"), 35, cyd)
	_g16_feather_arrow(wt, cy, cy3, sv2)
	_end()


## 翎羽箭(Arrow 骨，局部 z = 0 为箭尾)：白色的羽轴，两侧的青色羽片从箭尾到箭身中段(越往前越窄)，前端一枚银箭头
func _g16_feather_arrow(shaft: int, vane: int, vane2: int, head: int) -> void:
	g.tx = -14
	g.ty = 45
	g.tz = -10
	g.use("Arrow")
	g.box(0, 0, 0, 1, 1, 40, shaft)
	for z2 in range(1, 26):
		var w: int = 3 if z2 < 12 else (2 if z2 < 20 else 1)
		var c: int = vane if posmod(z2, 4) != 0 else vane2
		g.box(0, 2, z2, 0, 1 + w, z2, c)
		g.box(0, -w, z2, 0, -1, z2, c)
	g.cur_glow = 80
	g.box(0, -1, 41, 1, 2, 42, head)
	g.box(0, 0, 43, 1, 1, 44, head)
	g.cur_glow = 0


# ====================================================================== 向日葵步枪(黄 · 步枪 · 4)
## 机匣漆成葵花黄(铜边、两侧一道深橙的纹)，枪托是暖色的木头(托上刻一朵小葵花)；护木和枪管是一根青绿的向日葵茎(一节节的细绒)，
## 茎上左右各长出一片大叶子(浅色叶脉，往下垂)；枪口开着一朵大向日葵(花盘朝前：深褐的籽盘一圈圈的籽，外面一圈金黄的花瓣，背面绿色的萼片)，
## 枪口就在花盘正中。弹匣是一颗大葵花籽(黑壳白纹)。
const G16_SUN_CX := -0.5
const G16_SUN_CZ := 3.5
const G16_SUN_HEAD_Y := -49


## 一截圆杆(沿 Y)：截面中心 (G16_SUN_CX, G16_SUN_CZ)，半径 r；col(y, ang) 给颜色(ang = 截面上的角度，0 = +X、π/2 = +Z)
func _g16_rod(y0: int, y1: int, r: float, col: Callable, glow: int = 0) -> void:
	for y in range(y0, y1 + 1):
		for x in range(int(floor(G16_SUN_CX - r)) - 1, int(ceil(G16_SUN_CX + r)) + 2):
			for z in range(int(floor(G16_SUN_CZ - r)) - 1, int(ceil(G16_SUN_CZ + r)) + 2):
				var dx: float = float(x) - G16_SUN_CX
				var dz: float = float(z) - G16_SUN_CZ
				if dx * dx + dz * dz <= r * r + 0.15:
					D(x, y, z, col.call(y, atan2(dz, dx)), glow)


func g16_sunflower_rifle() -> void:
	_begin(false)
	var yl := VGrid.hexc("#e8b420")
	var yl2 := VGrid.hexc("#ffd85a")
	var yl3 := VGrid.hexc("#b07c10")
	var og := VGrid.hexc("#d06a12")
	var br := VGrid.hexc("#c99b45")
	var br2 := VGrid.hexc("#ecc675")
	var wd := VGrid.hexc("#8a5a30")
	var wd2 := VGrid.hexc("#a8743e")
	var wd3 := VGrid.hexc("#5e3a1c")
	var st := VGrid.hexc("#4a8a2e")
	var st2 := VGrid.hexc("#6cae44")
	var st3 := VGrid.hexc("#2f6420")
	var lf := VGrid.hexc("#3f8a2a")
	var lf2 := VGrid.hexc("#8ccc5a")
	var sd := VGrid.hexc("#4a2c14")
	var sd2 := VGrid.hexc("#6e4420")
	var sdk := VGrid.hexc("#2a180a")
	var pt := VGrid.hexc("#ffc81f")
	var pt2 := VGrid.hexc("#ffe070")
	var pt3 := VGrid.hexc("#e08a10")
	var sk := VGrid.hexc("#1e1a18")
	var skw := VGrid.hexc("#e8e2d0")
	# ---- 握把(木) + 扳机护圈(铜)
	for z in range(-5, 3):
		B(-1, -1, z, 0, 2, z, wd if posmod(z, 2) == 0 else wd2)
	B(-1, 3, -4, 0, 3, 2, wd3)
	B(-1, -1, -6, 0, 3, -6, br)
	B(-1, -5, 0, 0, -5, 2, br)
	B(-1, -4, 0, 0, -2, 0, br)
	D(-1, -3, 1, br2)
	D(0, -3, 1, br2)
	# ---- 机匣：葵花黄，顶面亮一档，两侧一道深橙的纹；前后铜箍
	_g16_rod(-11, 6, 2.0, func(y: int, a: float) -> int:
		if absf(a) < 0.5 or absf(a) > 2.64:
			return og if posmod(y, 4) == 0 else yl
		return yl2 if a > 0.6 and a < 2.5 else (yl3 if a < -0.6 and a > -2.5 else yl))
	_g16_rod(6, 6, 2.6, func(_y: int, _a: float) -> int: return br)
	_g16_rod(-12, -12, 2.6, func(_y: int, _a: float) -> int: return br)
	# ---- 弹匣：一颗大葵花籽(黑壳白纹，竖着插在机匣下面)
	for mz in range(-6, 2):
		var hw: int = 1 if mz > -5 and mz < 1 else 0
		for mx in range(-1 - hw, 1 + hw):
			for my in range(-10, -5):
				var c: int = sk
				if (my == -10 or my == -6) and (mx == -1 - hw or mx == hw):
					continue
				if mx == -1 - hw or mx == hw:
					c = skw if posmod(my, 2) == 0 and mz > -5 else sk
				D(mx, my, mz, c)
	# ---- 枪托：暖色木头，往下加深(Q 版短托)，托侧刻一朵小葵花
	for y2 in range(7, 18):
		var zlo: int = int(round(lerpf(1.0, -3.0, float(y2 - 7) / 10.0)))
		B(-1, y2, zlo, 0, y2, 5, wd if posmod(y2, 5) != 0 else wd2)
		B(-2, y2, zlo + 1, 1, y2, 4, wd)
	B(-2, 18, -3, 1, 18, 5, wd3)
	for sx: int in [-3, 2]:
		D(sx, 12, 1, sd2)
		for p: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			D(sx, 12 + p.x, 1 + p.y, pt)
	# ---- 护木 + 枪管：一根青绿的向日葵茎(一节节的细绒)，越往前越细
	_g16_rod(-32, -13, 2.0, func(y3: int, a3: float) -> int:
		if posmod(y3, 6) == 0:
			return st3
		return st2 if a3 > 0.4 and a3 < 2.7 else st)
	_g16_rod(G16_SUN_HEAD_Y + 2, -33, 1.4, func(y4: int, _a: float) -> int: return st if posmod(y4, 4) != 0 else st2)
	# 茎上两片大叶子：左(-X)一片在 y -19、右(+X)一片在 y -28，从茎上斜着往外、往下垂，浅色叶脉
	for lv: Array in [[-1, -19], [1, -28]]:
		var sgn: int = lv[0]
		var y0: int = lv[1]
		for k in range(10):
			var t: float = float(k) / 9.0
			var px: float = G16_SUN_CX + float(sgn) * (2.0 + 6.5 * t)
			var pz: float = G16_SUN_CZ + 1.0 - 4.0 * t * t
			var half: float = 2.4 * sin(t * PI) + 0.4
			for dy in range(-int(ceil(half)), int(ceil(half)) + 1):
				var c2: int = lf2 if dy == 0 else lf
				if absf(float(dy)) > half:
					continue
				D(int(floor(px)), y0 + dy - int(round(t * 3.0)), int(floor(pz)), c2)
	# ---- 枪口的向日葵：花盘朝前(-Y)，籽盘(深褐，一圈圈的籽) + 外面一圈花瓣 + 背面绿色萼片
	var hy: int = G16_SUN_HEAD_Y
	for x5 in range(-9, 9):
		for z5 in range(-5, 13):
			var dx: float = float(x5) + 0.5 - (G16_SUN_CX + 0.5)
			var dz: float = float(z5) + 0.5 - (G16_SUN_CZ + 0.5)
			var rr: float = sqrt(dx * dx + dz * dz)
			var ang: float = atan2(dz, dx)
			if rr <= 3.4:
				# 籽盘：前面两层；一圈圈的籽(按半径和角度交错)；正中是枪口
				var ring: int = int(floor(rr * 1.4))
				var cs: int = sd if posmod(ring + int(floor((ang + PI) * 3.0)), 2) == 0 else sd2
				if rr > 2.8:
					cs = sdk
				D(x5, hy - 1, z5, cs)
				D(x5, hy, z5, sd)
				D(x5, hy + 1, z5, st3)
			else:
				# 花瓣：12 瓣，瓣尖圆
				var lobe: float = absf(fposmod(ang * 12.0 / TAU, 1.0) - 0.5) * 2.0         # 0 = 瓣中线，1 = 两瓣之间
				var rmax: float = 7.4 - 2.2 * lobe * lobe
				if rr > rmax:
					continue
				var u: float = (rr - 3.4) / (rmax - 3.4)
				var cp: int = pt3 if u < 0.25 else (pt if u < 0.7 else pt2)
				if lobe > 0.8:
					cp = pt3
				D(x5, hy, z5, cp)
				if u < 0.5:
					D(x5, hy + 1, z5, st if rr < 4.6 else pt3)                          # 背面的萼片 / 花瓣根
	# 枪口：花盘正中一个深色的孔
	B(-1, hy - 1, 3, 0, hy, 4, sdk)
	_end()
