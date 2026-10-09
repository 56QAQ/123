extends "res://tools/model_weapons.gd"
## 通用武器 · gen8 的模型(tools/build_kits.gd 按 PARTS 登记)：手枪(双持)6 把。
## 枪械约定(同 model_weapons.gd 的 pistol / flintlock_pistol)：原点 = 握点(拳心)，-Y = 枪口(朝前)，+Z = 上，握把沿 Z 穿过拳心
## (握把在 x -1..0、y -1..2 附近，往下到 z≈-7)；枪身在 z 2..9、y -22..6 附近。
## 双持：右手 W_pistols_<外观>(挂 Bow)、左手 L_pistols_<外观>(挂 Weapon_L，B()/D() 自动左右镜像)。
## 颜色一律写死(不用调色板里会按武器颜色换色的青色系)；每把的主色就是它的武器颜色。
## PARTS：部件名 -> [资源名, 方法名, 参数…]

const PARTS := {
	"W_pistols_g8_peapod": ["wpn_pistols_g8_peapod", "g8_peapod", false],
	"L_pistols_g8_peapod": ["wpn_pistols_g8_peapod_l", "g8_peapod", true],
	"W_pistols_g8_rivet": ["wpn_pistols_g8_rivet", "g8_rivet", false],
	"L_pistols_g8_rivet": ["wpn_pistols_g8_rivet_l", "g8_rivet", true],
	"W_pistols_g8_dart": ["wpn_pistols_g8_dart", "g8_dart", false],
	"L_pistols_g8_dart": ["wpn_pistols_g8_dart_l", "g8_dart", true],
	"W_pistols_g8_crane": ["wpn_pistols_g8_crane", "g8_crane", false],
	"L_pistols_g8_crane": ["wpn_pistols_g8_crane_l", "g8_crane", true],
	"W_pistols_g8_firework": ["wpn_pistols_g8_firework", "g8_firework", false],
	"L_pistols_g8_firework": ["wpn_pistols_g8_firework_l", "g8_firework", true],
	"W_pistols_g8_sunray": ["wpn_pistols_g8_sunray", "g8_sunray", false],
	"L_pistols_g8_sunray": ["wpn_pistols_g8_sunray_l", "g8_sunray", true],
}


## 沿 Y 的圆柱段(连续坐标：轴心 (cx, cz)，半径 r)：每个体素按它在截面上的方向挑颜色——
## 顶面(朝 +Z)亮、底面暗、其余中间色；inner > 0 时只画外壳(半径 inner 以内留空)
func _g8_tube(y0: int, y1: int, cx: float, cz: float, r: float, c: int, c_hi: int, c_dk: int, inner: float = -1.0, glow: int = 0) -> void:
	var ri: int = int(ceil(r)) + 1
	for y in range(mini(y0, y1), maxi(y0, y1) + 1):
		for x in range(int(floor(cx)) - ri, int(ceil(cx)) + ri):
			for z in range(int(floor(cz)) - ri, int(ceil(cz)) + ri):
				var q := Vector2(float(x) + 0.5 - cx, float(z) + 0.5 - cz)
				var d: float = q.length()
				if d > r or (inner > 0.0 and d < inner):
					continue
				var c2: int = c
				if d > 0.1:
					var nz: float = q.y / d
					if nz > 0.55:
						c2 = c_hi
					elif nz < -0.55:
						c2 = c_dk
				D(x, y, z, c2, glow)


## 握把(竖着穿过拳心，z -7..2；下半截往后错一格) + 扳机护圈 + 扳机
func _g8_grip(gc: int, gc2: int, cap: int, guard: int, trig: int) -> void:
	for z in range(-7, 3):
		var off: int = 1 if z <= -4 else 0
		B(-1, -1 + off, z, 0, 2 + off, z, gc2 if posmod(z, 3) == 0 else gc)
	B(-1, 0, -8, 0, 3, -8, cap)
	B(-1, -6, -1, 0, -6, 1, guard)
	B(-1, -6, -1, 0, -2, -1, guard)
	B(-1, -3, 0, 0, -3, 1, trig)


# ====================================================================== 豌豆荚双枪(绿 · 2)
## 一根晒干的大豌豆荚当枪身(y -23..5，轴心 z 6；两头尖、中间按豆子一鼓一鼓)：顶上一道深绿的荚缝，侧面透出几颗豆子的鼓包；
## 枪口那一截荚壳裂开(上下两片荚唇)，露出一颗亮绿的豌豆(微光)；荚尾一根弯弯往上翘的荚柄 + 一片卷起来的叶子；
## 握把是缠着青藤的树枝(浅褐)，扳机是一根卷须
const G8_PEA_BUMPS := [-17.5, -11.5, -5.5, 0.5]           # 豆子的位置(y)


func g8_peapod(p_left: bool) -> void:
	_begin(p_left)
	var tw := VGrid.hexc("#7a5a36")                        # 树枝
	var tw2 := VGrid.hexc("#5e4428")
	var vn := VGrid.hexc("#4e8a2e")                        # 青藤
	var pd := VGrid.hexc("#5ea83a")                        # 荚壳
	var pd2 := VGrid.hexc("#86c95a")
	var pd3 := VGrid.hexc("#3c7a24")
	var seam := VGrid.hexc("#2e6420")
	var pea := VGrid.hexc("#a8e070")
	var pea2 := VGrid.hexc("#cdf29a")
	var dk := VGrid.hexc("#1e3a14")
	# ---- 握把：树枝 + 斜缠的青藤；卷须扳机
	for z in range(-7, 3):
		var off: int = 1 if z <= -4 else 0
		for y in range(-1 + off, 3 + off):
			for x in range(-1, 1):
				var c: int = tw if posmod(y + z, 3) != 0 else tw2
				if posmod(y + z + x * 2, 5) == 0:
					c = vn
				D(x, y, z, c)
	B(-1, 0, -8, 0, 3, -8, tw2)
	B(-1, -5, 1, 0, -5, 2, vn)
	D(-1, -4, 0, vn)
	D(0, -4, 0, vn)
	B(-1, -3, -1, 0, -3, -1, pd2)
	# ---- 荚身：截面椭圆(x 半径 rx、z 半径 rz)，两头尖；豆子处鼓一点
	for y in range(-23, 6):
		var t: float = (float(y) + 0.5 + 23.0) / 29.0          # 0 = 枪口，1 = 荚尾
		var env: float = pow(maxf(0.0, sin(PI * clampf(t * 0.92 + 0.04, 0.0, 1.0))), 0.45)
		var bump := 0.0
		for by: float in G8_PEA_BUMPS:
			bump = maxf(bump, 0.45 * maxf(0.0, 1.0 - absf(float(y) + 0.5 - by) / 3.0))
		var rx: float = (2.2 + bump) * env
		var rz: float = (2.6 + bump * 0.6) * env
		var mouth: bool = y <= -19
		for x in range(-4, 4):
			for z in range(2, 11):
				var qx: float = (float(x) + 0.5) / maxf(0.3, rx)
				var qz: float = (float(z) + 0.5 - 6.0) / maxf(0.3, rz)
				var e: float = qx * qx + qz * qz
				if e > 1.0:
					continue
				if mouth:
					# 枪口那一截裂开：只留上下两片荚唇，侧面敞开
					if e < 0.5 or absf(qz) < 0.45:
						continue
				var c2: int = pd
				if qz > 0.55:
					c2 = pd2
				elif qz < -0.5:
					c2 = pd3
				if absf(qx) < 0.3 and qz > 0.75:
					c2 = seam                                          # 顶上的荚缝
				elif bump > 0.3 and absf(qz) < 0.4 and absf(qx) > 0.8:
					c2 = pd2                                           # 侧面透出豆子的鼓包
				D(x, y, z, c2)
	# 枪口里的豌豆(亮绿，微光) + 后面一颗半露的
	for y2 in range(-22, -19):
		for x2 in range(-1, 1):
			for z2 in range(5, 8):
				var cc: int = pea2 if (z2 == 7 and y2 <= -21) else pea
				D(x2, y2, z2, cc, 24)
	B(-1, -19, 5, 0, -19, 6, dk)
	# ---- 荚柄：从荚尾往后、往上翘；一片卷叶
	for pt: Vector3i in [Vector3i(6, 6, 0), Vector3i(7, 7, 0), Vector3i(8, 8, 0), Vector3i(8, 9, 0), Vector3i(7, 10, 0)]:
		B(-1, pt.x, pt.y, 0, pt.x, pt.y, pd3)
	for ly in range(2, 8):
		var w: int = 2 if (ly > 2 and ly < 7) else 1
		for lx in range(-w - 1, w):
			D(lx - 1, ly, 10 + (1 if ly > 5 else 0), vn if lx != -1 else pd3)
	D(-3, 7, 11, pd2)
	_end()


# ====================================================================== 铆钉双枪(蓝 · 2)
## 维护部的气动铆钉枪：钢蓝色的方机身(顶面亮一档，侧面两道散热槽)，前面一截钢制的圆枪鼻，枪口顶着一颗烧红的铆钉(发光)；
## 机身右侧(外侧)一条铆钉弹带(亮钢的钉帽一排)，顶上后部一个白底红针的气压表；黑色橡胶握把，柄底接一小截往后弯的气管
func g8_rivet(p_left: bool) -> void:
	_begin(p_left)
	var bl := VGrid.hexc("#2f5f9e")                        # 钢蓝漆
	var bl2 := VGrid.hexc("#4a80c4")
	var bl3 := VGrid.hexc("#1e3f6c")
	var st := VGrid.hexc("#7d848e")                        # 钢
	var st2 := VGrid.hexc("#a8afba")
	var st3 := VGrid.hexc("#525862")
	var rb := VGrid.hexc("#26272c")                        # 橡胶
	var rb2 := VGrid.hexc("#3a3c43")
	var hot := VGrid.hexc("#ff7a2a")
	var hot2 := VGrid.hexc("#ffd08a")
	_g8_grip(rb, rb2, st3, st3, st2)
	# 气管：柄底往后弯
	for pt: Vector2i in [Vector2i(2, -9), Vector2i(3, -9), Vector2i(4, -9), Vector2i(5, -8), Vector2i(6, -7), Vector2i(6, -6)]:
		B(-1, pt.x, pt.y, 0, pt.x, pt.y, rb)
	D(-1, 6, -5, st2)
	D(0, 6, -5, st2)
	# 机身：方盒(x -2..1、y -10..5、z 2..8)；顶面亮、底面暗；侧面两道散热槽
	B(-2, -10, 2, 1, 5, 8, bl)
	B(-2, -10, 8, 1, 5, 8, bl2)
	B(-2, -10, 2, 1, 5, 2, bl3)
	for gy: int in [-7, -4]:
		for sx: int in [-2, 1]:
			B(sx, gy, 4, sx, gy, 6, bl3)
	B(-2, 4, 3, 1, 6, 7, bl3)                              # 尾盖
	# 枪鼻：钢圆管(y -19..-11，轴心 z 5)，一道箍；前端更细
	_g8_tube(-18, -11, 0.0, 5.5, 2.4, st, st2, st3)
	_g8_tube(-21, -19, 0.0, 5.5, 1.6, st, st2, st3)
	B(-2, -13, 3, 1, -13, 8, st3)
	# 枪口的铆钉：钉杆 + 烧红的钉帽(发光)
	B(-1, -23, 5, 0, -22, 6, hot, 90)
	B(-1, -24, 4, 0, -24, 7, hot, 110)
	D(-1, -24, 5, hot2, 140)
	D(0, -24, 6, hot2, 140)
	# 外侧(-X)的铆钉弹带：一排亮钢钉帽
	for ry in range(-9, 4, 2):
		B(-3, ry, 3, -3, ry, 4, st2)
		D(-3, ry + 1, 3, st3)
	# 顶上后部的气压表(白底 + 红针)
	B(-2, 0, 9, 1, 3, 9, st3)
	B(-1, 1, 10, 0, 2, 10, VGrid.hexc("#e8e6dc"))
	D(-1, 1, 10, VGrid.hexc("#c8282a"))
	_end()


# ====================================================================== 调剂镖枪(紫 · 3)
## 福利部的麻醉镖枪：深紫的枪身(顶面亮一档) + 一根细长的银枪管，枪口一圈发光的紫环；
## 枪身顶上插着一排三支药剂瓶(透明的玻璃瓶身、下半截发光的紫色药液、银瓶盖)，瓶底银色的接管通进枪身；
## 握把深紫黑，银色柄底；枪管下挂一支备用的药镖(银针 + 紫色尾羽)
func g8_dart(p_left: bool) -> void:
	_begin(p_left)
	var pu := VGrid.hexc("#5e3290")                        # 深紫
	var pu2 := VGrid.hexc("#8452c0")
	var pu3 := VGrid.hexc("#3c1c60")
	var gp := VGrid.hexc("#2a1f33")
	var gp2 := VGrid.hexc("#3d2e4a")
	var sv := VGrid.hexc("#b8bcc6")                        # 银
	var sv2 := VGrid.hexc("#dfe2e8")
	var sv3 := VGrid.hexc("#80848e")
	var gl := VGrid.hexc("#d8ccec")                        # 玻璃
	var lq := VGrid.hexc("#a050f0")                        # 药液
	var lq2 := VGrid.hexc("#d49cff")
	_g8_grip(gp, gp2, sv3, sv3, sv)
	# 枪身(x -2..1、y -9..5、z 2..7)
	B(-2, -9, 2, 1, 5, 7, pu)
	B(-2, -9, 7, 1, 5, 7, pu2)
	B(-2, -9, 2, 1, 5, 2, pu3)
	B(-2, 4, 3, 1, 6, 6, pu3)
	B(-2, -1, 4, -2, 3, 5, pu2)                            # 侧面一道亮线
	B(1, -1, 4, 1, 3, 5, pu2)
	# 细长的银枪管(y -25..-10)
	B(-1, -25, 4, 0, -10, 5, sv)
	B(-1, -25, 5, 0, -10, 5, sv2)
	B(-1, -25, 4, 0, -10, 4, sv3)
	for by: int in [-13, -19]:
		B(-2, by, 3, 1, by, 6, pu3)
	# 枪口一圈发光的紫环
	for pt: Vector2i in [Vector2i(-2, 3), Vector2i(-2, 4), Vector2i(-2, 5), Vector2i(-2, 6), Vector2i(1, 3), Vector2i(1, 4), Vector2i(1, 5), Vector2i(1, 6),
			Vector2i(-1, 3), Vector2i(0, 3), Vector2i(-1, 6), Vector2i(0, 6)]:
		D(pt.x, -26, pt.y, lq, 90)
	# 三支药剂瓶(y -7 / -3 / 1)：玻璃瓶身(z 8..12)，下半截药液发光，银瓶盖；瓶底接管
	for vy: int in [-7, -3, 1]:
		for z in range(8, 13):
			for x in range(-1, 1):
				for dy in range(0, 2):
					var c: int = gl
					var g := 0
					if z <= 10:
						c = lq2 if (z == 10 and dy == 0) else lq
						g = 70
					D(x, vy + dy, z, c, g)
		B(-1, vy, 13, 0, vy + 1, 13, sv2)
		B(-2, vy, 8, -2, vy + 1, 8, sv3)
		B(1, vy, 8, 1, vy + 1, 8, sv3)
	# 枪管下挂的备用药镖：银针 + 紫色尾羽
	B(-1, -20, 2, 0, -12, 2, sv3)
	D(-1, -21, 2, sv2)
	for fy in range(-12, -9):
		D(-2, fy, 2, pu2)
		D(1, fy, 2, pu2)
		D(-1, fy, 1, lq)
	_end()


# ====================================================================== 千纸鹤双枪(青 · 3)
## 拳头里攥着一卷用青丝带扎好的信笺(米白的纸卷，竖着穿过拳心)，纸卷顶上站着一只青色信纸折的纸鹤，鹤头朝前(-Y)：
## 菱形的鹤身、两片往上斜着张开的翅膀(上面青、下面浅青，中间一道白折痕)、往前伸的细脖子 + 低头的尖喙、往后翘的尾巴
func g8_crane(p_left: bool) -> void:
	_begin(p_left)
	var pp := VGrid.hexc("#ece6d6")                        # 信笺(米白)
	var pp2 := VGrid.hexc("#d4ccb8")
	var rb := VGrid.hexc("#1f9aa4")                        # 青丝带
	var rb2 := VGrid.hexc("#5cc8cc")
	var cy := VGrid.hexc("#33aab4")                        # 纸鹤(青)
	var cy2 := VGrid.hexc("#7fd6da")
	var cy3 := VGrid.hexc("#1d7c86")
	var crease := VGrid.hexc("#f2fbfb")
	var wax := VGrid.hexc("#b02a36")
	# ---- 纸卷(轴沿 Z，z -7..3，截面圆 r 1.9)：一圈圈的纸边；两道青丝带 + 一枚红火漆
	for z in range(-7, 4):
		for x in range(-3, 2):
			for y in range(-2, 4):
				var q := Vector2(float(x) + 0.5, float(y) + 0.5 - 0.5)
				var d: float = q.length()
				if d > 1.95:
					continue
				var c: int = pp if posmod(z, 2) == 0 else pp2
				if z == -7 or z == 3:
					c = pp2 if d > 1.0 else VGrid.hexc("#b8ae98")       # 纸卷两头：一圈圈卷进去
				if z == -4 or z == 1:
					c = rb if d > 1.2 else c
				D(x, y, z, c)
	D(-2, -1, -4, rb2)
	B(-3, 0, -3, -3, 1, -2, wax)
	# ---- 纸鹤：鹤身(菱形，y -5..3、z 4..8)
	for y in range(-5, 4):
		var t: float = 1.0 - absf(float(y) + 0.5 + 1.0) / 4.6
		if t <= 0.0:
			continue
		var hz: int = int(round(2.2 * t))
		var hx: int = int(round(1.3 * t))
		for z in range(5 - hz, 6 + hz + 1):
			for x in range(-1 - hx, 1 + hx):
				var c3: int = cy if z >= 6 else cy3
				if x == -1 - hx or x == hx:
					c3 = cy3
				D(x, y, z, c3)
		D(-1, y, 6 + hz + 1, crease)                       # 背上的折棱
	# 两片翅膀：从鹤身两侧(x ±2)往外、往上斜张开(到 x ±6、z 11；再宽，待机时会戳进大腿)，前缘 y -3、后缘 y 3 往外收窄
	for side: int in [-1, 1]:
		for k in range(0, 5):
			var xo: int = 2 + k                                 # 往外第几格
			var zo: int = 7 + k                                 # 越往外越高
			var ya: int = -3 + int(floor(float(k) * 0.5))
			var yb: int = 3 - int(floor(float(k) * 0.75))
			for y2 in range(ya, yb + 1):
				var xx: int = (-1 - xo) if side < 0 else xo
				var c4: int = cy2 if y2 >= 0 else cy
				if y2 == ya:
					c4 = crease                                # 前缘一道白折痕
				D(xx, y2, zo, c4)
				D(xx, y2, zo - 1, cy3)                          # 下面一层(浅青的反面看着暗一点)
	# 脖子：从鹤身前端往前、往上(y -6..-11，z 7..12)；头往下弯，尖喙
	for i in range(0, 6):
		B(-1, -6 - i, 7 + i, 0, -6 - i, 7 + i, cy if i < 5 else cy2)
	B(-1, -12, 11, 0, -12, 12, cy)
	B(-1, -13, 10, 0, -13, 11, cy2)
	D(-1, -14, 9, cy3)
	D(0, -14, 9, cy3)
	# 尾巴：从鹤身后端往后、往上翘(y 4..8，z 7..11)
	for j in range(0, 5):
		B(-1, 4 + j, 7 + j, 0, 4 + j, 7 + j, cy if j < 4 else cy2)
	_end()


# ====================================================================== 庆典烟花筒(红 · 4)
## 一支手持的庆典烟花筒：大红的纸筒(y -18..4，轴心 z 6，半径 3；顶面亮一档)，三道金箍，筒身侧面一颗金色的五角星；
## 筒口一圈金边，里面暗、闪着几点火星(发光)；筒尾一个米黄纸帽，后面翘出一截燃着的引信(橙色发光)；
## 筒身中间系一个红绸蝴蝶结，两条短飘带往外侧垂；木握把
func g8_firework(p_left: bool) -> void:
	_begin(p_left)
	var rd := VGrid.hexc("#b8262a")
	var rd2 := VGrid.hexc("#de4a40")
	var rd3 := VGrid.hexc("#7a1418")
	var au := VGrid.hexc("#c8982c")
	var au2 := VGrid.hexc("#ecc65a")
	var au3 := VGrid.hexc("#8a6418")
	var wd := VGrid.hexc("#7a4a26")
	var wd2 := VGrid.hexc("#5a341a")
	var cap := VGrid.hexc("#e6d4a8")
	var fz := VGrid.hexc("#3a2a1e")
	var sp := VGrid.hexc("#ffb040")
	var sp2 := VGrid.hexc("#fff0b0")
	_g8_grip(wd, wd2, au3, au3, au)
	# 纸筒
	_g8_tube(-18, 4, 0.0, 6.0, 3.1, rd, rd2, rd3)
	for by: int in [-16, -7, 2]:
		_g8_tube(by, by, 0.0, 6.0, 3.5, au, au2, au3)
	# 筒口：金边 + 暗的筒膛 + 火星
	_g8_tube(-19, -19, 0.0, 6.0, 3.5, au, au2, au3, 2.2)
	_g8_tube(-19, -18, 0.0, 6.0, 2.2, VGrid.hexc("#2a1210"), VGrid.hexc("#2a1210"), VGrid.hexc("#2a1210"))
	D(-1, -19, 6, sp, 140)
	D(0, -19, 7, sp2, 160)
	D(0, -19, 5, sp, 120)
	# 侧面(外侧 -X)一颗金色五角星
	for pt: Vector2i in [Vector2i(-12, 8), Vector2i(-12, 7), Vector2i(-13, 6), Vector2i(-11, 6), Vector2i(-12, 6), Vector2i(-12, 5),
			Vector2i(-14, 7), Vector2i(-10, 7), Vector2i(-13, 4), Vector2i(-11, 4)]:
		D(-4, pt.x, pt.y, au2)
	# 筒尾纸帽 + 燃着的引信
	_g8_tube(5, 5, 0.0, 6.0, 2.8, cap, cap, VGrid.hexc("#c8b488"))
	for pt2: Vector2i in [Vector2i(6, 7), Vector2i(7, 8), Vector2i(8, 9)]:
		B(-1, pt2.x, pt2.y, -1, pt2.x, pt2.y, fz)
	D(-1, 9, 10, sp, 150)
	D(-1, 9, 11, sp2, 170)
	# 红绸蝴蝶结(筒身中间顶上) + 两条往外侧垂的短飘带
	B(-1, -9, 10, 0, -8, 10, rd2)
	B(-3, -10, 10, -2, -7, 11, rd)
	B(1, -10, 10, 2, -7, 11, rd)
	D(-4, -10, 11, rd2)
	D(3, -10, 11, rd2)
	for k in range(0, 4):
		D(-4, -8 + k % 2, 9 - k, rd)
	_end()


# ====================================================================== 金阳射线枪(黄 · 4)
## 老科幻画报里的射线枪：圆鼓鼓的金色机身(椭球)，顶上后部一个玻璃聚光罩，罩里关着一颗发光的小太阳；
## 细长的金色枪管上套着三片散热圆盘(金 / 深金交替)，枪口一个小碟形发射器，中间一点白热的光；机身尾部两片竖着的尾鳍；黑色握把
func g8_sunray(p_left: bool) -> void:
	_begin(p_left)
	var au := VGrid.hexc("#c89a30")
	var au2 := VGrid.hexc("#eccb64")
	var au3 := VGrid.hexc("#8a6418")
	var bk := VGrid.hexc("#24221e")
	var bk2 := VGrid.hexc("#38342c")
	var glass := VGrid.hexc("#d8ecf4")
	var sun := VGrid.hexc("#ffb81e")
	var sun2 := VGrid.hexc("#fff2a0")
	_g8_grip(bk, bk2, au3, au3, au2)
	# 机身：椭球(中心 y 0、z 5.5；y 半径 6、z 半径 3.2、x 半径 2.6)
	for y in range(-7, 7):
		for z in range(2, 10):
			for x in range(-3, 3):
				var q := Vector3((float(x) + 0.5) / 2.6, (float(y) + 0.5) / 6.0, (float(z) + 0.5 - 5.5) / 3.2)
				if q.length() > 1.0:
					continue
				var c: int = au
				if q.z > 0.5:
					c = au2
				elif q.z < -0.5:
					c = au3
				if absf(q.y) < 0.12:
					c = au3                                    # 腰上一道接缝
				D(x, y, z, c)
	# 玻璃聚光罩(半球，中心 y 2、z 8.5，半径 3) + 里面的小太阳(发光)
	for y2 in range(-1, 6):
		for z2 in range(8, 12):
			for x2 in range(-3, 3):
				var p := Vector3(float(x2) + 0.5, float(y2) + 0.5 - 2.0, float(z2) + 0.5 - 8.5)
				var d: float = p.length()
				if d > 3.0 or z2 < 8:
					continue
				if d < 1.6:
					D(x2, y2, z2, sun2 if d < 0.9 else sun, 170 if d < 0.9 else 130)
				elif d > 2.1:
					D(x2, y2, z2, glass, 20)
	# 枪管(y -20..-8，轴心 z 5.5，半径 1) + 三片散热圆盘
	_g8_tube(-20, -7, 0.0, 5.5, 1.1, au, au2, au3)
	for i in range(3):
		var dy: int = -10 - i * 3
		_g8_tube(dy, dy, 0.0, 5.5, 3.0 - float(i) * 0.4, au3 if i % 2 == 0 else au, au2, au3)
	# 碟形发射器 + 白热的光点
	_g8_tube(-21, -21, 0.0, 5.5, 2.3, au, au2, au3)
	_g8_tube(-22, -22, 0.0, 5.5, 1.2, sun, sun, sun, -1.0, 140)
	D(-1, -23, 5, sun2, 180)
	D(0, -23, 5, sun2, 180)
	# 尾鳍：机身尾部竖着两片(往后、往上斜)
	for k in range(0, 4):
		B(-1, 6 + k, 7 + k, 0, 6 + k, 8 + k, au if k < 3 else au2)
	for side: int in [-3, 2]:
		for k2 in range(0, 3):
			D(side, 5 + k2, 3 + k2, au3)
	_end()
