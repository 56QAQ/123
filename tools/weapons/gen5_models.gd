extends "res://tools/model_weapons.gd"
## 通用武器 · gen5 的模型(tools/build_kits.gd 按 PARTS 登记)：手弩 6 把。
## 手弩约定(同 model_weapons.gd 的 crossbow / arbalest)：原点 = 握点(拳心)，-Y = 弩口，+Z = 上，握把沿 -Z 往下(约 z -6..3)；
## 弩臂在 y≈-22 附近横向展开(±X)、两端往后(+Y)弯，弦从两端连到扳机前的弦扣(y≈-7)，弩箭搁在 z≈6 的箭槽里。
## 颜色一律写死(不用调色板里的青色系：那几种会被着色器按武器颜色换色)；每把的主色就是它的武器颜色。
## PARTS：部件名 -> [资源名, 方法名, 参数…]

const PARTS := {
	"W_crossbow_g5rime": ["wpn_crossbow_g5rime", "g5_rime"],
	"W_crossbow_g5gale": ["wpn_crossbow_g5gale", "g5_gale"],
	"W_crossbow_g5flare": ["wpn_crossbow_g5flare", "g5_flare"],
	"W_crossbow_g5thunder": ["wpn_crossbow_g5thunder", "g5_thunder"],
	"W_crossbow_g5hive": ["wpn_crossbow_g5hive", "g5_hive"],
	"W_crossbow_g5thorn": ["wpn_crossbow_g5thorn", "g5_thorn"],
}


## 弦：从弩臂两端 (±tip_x, tip_y) 连到弦扣 (0, nut_y)，高度 z
func _g5_string(tip_x: int, tip_y: int, nut_y: int, z: int, c: int, glow: int = 0) -> void:
	var n: int = tip_x + 1
	for i in range(0, n + 1):
		var t: float = float(i) / float(n)
		var x2: int = int(round(lerpf(-float(tip_x), -1.0, t)))
		var y2: int = int(round(lerpf(float(tip_y), float(nut_y), t)))
		D(x2, y2, z, c, glow)
		D(-1 - x2, y2, z, c, glow)


## 握把 + 扳机护圈(各把自己的颜色)
func _g5_grip(gc: int, gc2: int, cap: int, guard: int) -> void:
	for z in range(-5, 3):
		B(-1, -1, z, 0, 3, z, gc if (z % 2) == 0 else gc2)
	B(-1, -1, -6, 0, 3, -6, cap)
	B(-1, -5, 0, 0, -5, 2, guard)
	B(-1, -4, 0, 0, -2, 0, guard)
	D(-1, -3, 1, guard)


# ====================================================================== 霜棱手弩(紫 · 2)：和风紫漆弩身 + 冰晶弩臂
## 云上空岛(紫之章)的样式：紫漆弩身、金箍，握把缠紫绳；弩臂是两条淡紫的冰棱(中间厚、两端细，端头各一簇冰晶)，
## 弩口前一簇往前伸的冰晶；上弦的是一枚冰棱(发微光)；弩身下挂一条紫色流苏。
func g5_rime() -> void:
	_begin(false)
	var lq := VGrid.hexc("#55307f")
	var lq2 := VGrid.hexc("#7446a8")
	var lq3 := VGrid.hexc("#321b4d")
	var au := VGrid.hexc("#d6b05a")
	var au2 := VGrid.hexc("#f0d48a")
	var ice := VGrid.hexc("#ad92f0")
	var ice2 := VGrid.hexc("#8461d8")
	var ice3 := VGrid.hexc("#e2d6ff")
	var silk := VGrid.hexc("#efe9fb")
	_g5_grip(lq3, lq, au, au)
	# 弩身：前段厚(z 2..6)，后段细；顶面亮一档；尾部加粗的托
	B(-1, -27, 2, 0, -9, 5, lq)
	B(-1, -27, 6, 0, -9, 6, lq2)
	B(-1, -8, 3, 0, 6, 5, lq)
	B(-1, -8, 6, 0, 6, 6, lq2)
	B(-2, 3, 2, 1, 8, 5, lq)
	B(-2, 3, 6, 1, 8, 6, lq2)
	B(-2, 9, 2, 1, 9, 6, au)
	for ry: int in [-24, -15, -9, 2]:
		B(-2, ry, 2, 1, ry, 7, au)
	D(-2, -15, 4, au2)
	D(1, -15, 4, au2)
	# 箭槽
	B(-1, -27, 7, 0, -10, 7, lq3)
	# 弩身两侧：雪花纹(金)
	for sx: int in [-2, 1]:
		for p: Vector2i in [Vector2i(-19, 4), Vector2i(-20, 4), Vector2i(-18, 4), Vector2i(-19, 3), Vector2i(-19, 5), Vector2i(-21, 3), Vector2i(-17, 5), Vector2i(-21, 5), Vector2i(-17, 3)]:
			D(sx, p.x, p.y, au2 if p == Vector2i(-19, 4) else au)
	# 冰棱弩臂：y≈-25 横向展开，两端往后弯；中间厚(z 3..6)，往外收细(z 4..5)，一路发微光
	for x in range(-16, 16):
		var a: float = absf(float(x) + 0.5) / 16.0
		var off: int = int(round(a * a * 7.0))
		var thick: bool = a < 0.55
		var c: int = ice2 if ((x + 40) % 4) == 0 else ice
		B(x, -26 + off, 4, x, -25 + off, 5, c, 35)
		if thick:
			D(x, -26 + off, 3, ice2, 25)
			D(x, -25 + off, 6, ice3, 45)
	# 端头的冰晶簇(往外、往前各一根尖)
	for sgn: int in [-1, 1]:
		var tx: int = 16 if sgn > 0 else -17
		var inner: int = 15 if sgn > 0 else -16
		B(mini(tx, inner), -19, 3, maxi(tx, inner), -17, 6, ice, 70)
		D(tx + sgn, -18, 4, ice2, 60)
		D(tx + sgn, -18, 5, ice, 70)
		D(tx + 2 * sgn, -18, 5, ice3, 120)
		D(tx, -20, 5, ice3, 110)
		D(tx, -21, 5, ice3, 130)
		D(inner, -16, 6, ice2, 60)
	# 弦(白丝)
	_g5_string(15, -17, -8, 7, silk)
	B(-1, -9, 7, 0, -7, 8, au)
	# 上弦的冰棱(中间厚、两头尖，发光)
	B(-1, -33, 8, 0, -10, 8, ice, 80)
	B(-1, -30, 9, 0, -14, 9, ice2, 60)
	D(-1, -34, 8, ice3, 150)
	D(0, -34, 8, ice3, 150)
	D(-1, -35, 8, ice3, 180)
	# 弩口前的冰晶簇
	B(-1, -29, 3, 0, -28, 6, ice, 70)
	D(-2, -29, 5, ice2, 60)
	D(1, -29, 4, ice2, 60)
	D(-1, -30, 4, ice3, 110)
	D(0, -30, 5, ice3, 110)
	D(0, -31, 4, ice3, 140)
	# 紫色流苏(弩身下)：金扣 + 紫绳 + 穗子
	B(-1, -15, 0, 0, -15, 1, au)
	B(-1, -15, -5, 0, -15, -1, lq2)
	B(-2, -15, -8, 1, -15, -6, lq)
	D(-1, -15, -9, au2)
	_end()


# ====================================================================== 青岚手弩(青 · 2)：白桦木弩身 + 两根大羽毛当弩臂
## 轻巧的风之弩：白桦木弩身嵌青色木条，弩臂是两根往后掠的白羽(羽轴白、羽片外缘渐成青色)，弩口一圈青色的旋风纹，
## 弩身前端系一条往后飘的青色缎带；上弦的是一支青色尾羽的弩箭(默认弹)。
func g5_gale() -> void:
	_begin(false)
	var bw := VGrid.hexc("#ebe6d8")
	var bw2 := VGrid.hexc("#d6cfbd")
	var bw3 := VGrid.hexc("#b9b09b")
	var tl := VGrid.hexc("#2aa597")
	var tl2 := VGrid.hexc("#62d0c1")
	var tl3 := VGrid.hexc("#16695f")
	var fw := VGrid.hexc("#f8f8f4")
	var fw2 := VGrid.hexc("#e2ece9")
	var silver := VGrid.hexc("#c9d2d6")
	_g5_grip(tl3, tl, silver, silver)
	# 弩身(细长、两头收)
	B(-1, -26, 3, 0, 5, 5, bw)
	B(-1, -26, 6, 0, 5, 6, bw2)
	B(-1, -20, 2, 0, -8, 2, bw3)
	B(-1, 6, 2, 0, 9, 5, bw)
	B(-1, 10, 3, 0, 10, 5, bw2)
	# 青色嵌条(两侧)
	for sx: int in [-2, 1]:
		B(sx, -22, 4, sx, 4, 4, tl)
		D(sx, -23, 4, tl2)
		D(sx, 5, 4, tl2)
	for ry: int in [-21, -10, 1]:
		B(-2, ry, 3, 1, ry, 6, silver)
	# 箭槽
	B(-1, -26, 7, 0, -9, 7, bw3)
	# 羽毛弩臂：羽轴从 x=±2 往外(y 往后掠、z 往上翘一点)，羽片往后(+y)拖 1~4 格，外缘一圈青色
	for sgn: int in [-1, 1]:
		for i in range(0, 17):
			var xo: int = 2 + i
			var x: int = xo if sgn > 0 else -1 - xo
			var t: float = float(i) / 16.0
			var y: int = -23 + int(round(t * t * 8.0))
			var z: int = 5 + int(round(t * 2.0))
			D(x, y, z, fw)
			var vane: int = 1 + int(round(sin(t * PI) * 3.0))
			for k in range(1, vane + 1):
				var edge: bool = k == vane
				D(x, y + k, z, tl2 if edge else fw2, 40 if edge else 0)
				if k <= 1:
					D(x, y + k, z - 1, fw2)
			D(x, y - 1, z, tl if i > 10 else fw2)
		# 羽尖
		var tipx: int = 19 if sgn > 0 else -20
		D(tipx, -14, 7, tl2, 60)
		D(tipx, -13, 7, tl, 40)
	# 弦
	_g5_string(16, -15, -8, 6, fw2)
	B(-1, -9, 6, 0, -7, 7, silver)
	# 上弦的弩箭：木杆 + 银头 + 青色尾羽
	B(-1, -31, 8, -1, -9, 8, bw3)
	B(-1, -33, 8, -1, -32, 8, silver)
	D(-1, -34, 8, fw)
	B(-1, -12, 9, -1, -9, 9, tl)
	B(-2, -12, 8, -2, -10, 8, tl2)
	B(0, -12, 8, 0, -10, 8, tl2)
	# 弩口的旋风纹：一圈青色的环(正对前方)
	for a in range(0, 12):
		var ang: float = TAU * float(a) / 12.0
		var rx: int = int(round(cos(ang) * 2.6 - 0.5))
		var rz: int = int(round(sin(ang) * 2.6 + 5.0))
		D(rx, -28, rz, tl2 if (a % 3) == 0 else tl, 50)
	D(-1, -27, 2, tl3)
	D(0, -27, 2, tl3)
	# 往后飘的缎带(系在弩身前端下面)
	for i2 in range(0, 9):
		var yy: int = -18 + i2 * 2
		var zz: int = 1 - int(round(sin(float(i2) * 0.9) * 1.2)) - i2 / 3
		B(-1, yy, zz, -1, yy + 1, zz, tl if (i2 % 2) == 0 else tl2)
	_end()


# ====================================================================== 救难信号弩(红 · 3)：信号红的弩身 + 顶上一根粗信号弹管
## 救援队的信号弩：信号红的弩身(白色警示条、黄铜件)，顶上架着一根方口的粗信号弹管(管口里一点橙红的光 = 装好的信号弹)，
## 短而粗的黑钢弩臂(红色端头)，右侧弹夹里插着 3 发备用信号弹(红壳、黄铜底)，管身侧面一个白底红十字。
func g5_flare() -> void:
	_begin(false)
	var rd := VGrid.hexc("#c8322b")
	var rd2 := VGrid.hexc("#e5533f")
	var rd3 := VGrid.hexc("#8c1d1b")
	var wh := VGrid.hexc("#f1ede4")
	var bk := VGrid.hexc("#26272c")
	var st := VGrid.hexc("#3c3e45")
	var st2 := VGrid.hexc("#5a5d66")
	var br := VGrid.hexc("#d6a548")
	var br2 := VGrid.hexc("#f0c870")
	var glow := VGrid.hexc("#ffb04a")
	var glow2 := VGrid.hexc("#fff0c0")
	_g5_grip(bk, st, br, br)
	# 弩身
	B(-1, -22, 2, 0, 6, 4, rd)
	B(-1, -22, 1, 0, -10, 1, rd3)
	B(-2, 3, 1, 1, 9, 4, rd)
	B(-2, 9, 1, 1, 9, 4, bk)
	for sx: int in [-2, 1]:
		B(sx, -20, 3, sx, -14, 3, wh)
	# 信号弹管：方口粗管 x -2..1、z 5..8，y -27..2；顶面亮一档；管口挖空、里面一点光
	B(-2, -27, 5, 1, 2, 8, rd)
	B(-2, -27, 8, 1, 2, 8, rd2)
	B(-2, -27, 5, 1, -27, 8, br)
	B(-3, -26, 4, 2, -25, 9, br)
	B(-3, -1, 4, 2, 0, 9, br)
	g.mode = VGrid.CLEAR
	B(-1, -27, 6, 0, -24, 7, 0)
	g.mode = VGrid.FILL
	B(-1, -23, 6, 0, -23, 7, glow, 140)
	D(-1, -24, 6, glow2, 180)
	D(0, -24, 7, glow2, 180)
	# 管身侧面的白底红十字(两面)
	for sx2: int in [-3, 2]:
		B(sx2, -16, 5, sx2, -10, 8, wh)
		B(sx2, -14, 5, sx2, -12, 8, rd)
		B(sx2, -16, 6, sx2, -10, 7, rd)
	# 管尾的击发帽 + 准星
	B(-1, 3, 6, 0, 4, 7, st2)
	B(-1, -22, 9, 0, -22, 10, bk)
	# 短粗的黑钢弩臂(在管下，y≈-19)：两端红漆
	for x in range(-12, 12):
		var a: float = absf(float(x) + 0.5) / 12.0
		var off: int = int(round(a * a * 4.0))
		B(x, -20 + off, 3, x, -18 + off, 4, rd2 if a > 0.8 else st)
	B(-13, -17, 2, -12, -15, 5, rd3)
	B(11, -17, 2, 12, -15, 5, rd3)
	_g5_string(12, -15, -8, 5, bk)
	# 右侧弹夹：3 发备用信号弹(竖着插，红壳 + 黄铜底 + 顶上一点白)
	B(2, -8, 2, 2, 1, 3, bk)
	for i in range(0, 3):
		var yy: int = -7 + i * 3
		B(3, yy, 1, 4, yy + 1, 6, rd2 if i == 1 else rd)
		B(3, yy, 0, 4, yy + 1, 0, br)
		D(3, yy, 7, wh)
		D(4, yy + 1, 7, br2)
	_end()


# ====================================================================== 雷鸣手弩(黄 · 3)：枪灰机身 + 铜线圈 + 特斯拉电极
## 工程部的电磁弩：枪灰色机身、黄黑警示条纹的弩头，导轨上绕着三圈铜线圈；直折的金属弩臂端头各一根发光的电极针，
## 弩口两根往前伸的电极叉(发光)；导轨下面一个电池盒(黄色的发光窗)；上弦的是一枚发光的电弩箭。
func g5_thunder() -> void:
	_begin(false)
	var gm := VGrid.hexc("#3c4049")
	var gm2 := VGrid.hexc("#575d6a")
	var gm3 := VGrid.hexc("#25282e")
	var yl := VGrid.hexc("#f2c230")
	var yl2 := VGrid.hexc("#ffe27a")
	var bk := VGrid.hexc("#1c1d21")
	var cu := VGrid.hexc("#c4773b")
	var cu2 := VGrid.hexc("#e39a5a")
	var arc := VGrid.hexc("#fff3a8")
	_g5_grip(bk, gm3, gm2, gm2)
	# 机身 + 导轨
	B(-2, -24, 2, 1, 6, 5, gm)
	B(-2, -24, 6, 1, 6, 6, gm2)
	B(-2, 7, 1, 1, 10, 5, gm)
	B(-2, 10, 1, 1, 10, 5, gm3)
	B(-1, -24, 7, 0, -9, 7, gm3)
	# 弩头：黄黑警示斜纹
	for y in range(-28, -24):
		for z in range(1, 7):
			B(-2, y, z, 1, y, z, bk if ((y + z + 40) % 4) < 2 else yl)
	# 三圈铜线圈(绕着机身)
	for cy: int in [-21, -17, -13]:
		B(-3, cy, 1, 2, cy + 1, 7, cu)
		B(-3, cy, 3, -3, cy + 1, 4, cu2)
		B(2, cy, 3, 2, cy + 1, 4, cu2)
	# 电池盒(导轨下)：黄色发光窗
	B(-2, -14, -2, 1, -6, 1, gm3)
	B(-3, -12, -1, -3, -8, 0, yl, 110)
	B(2, -12, -1, 2, -8, 0, yl, 110)
	D(-3, -10, 0, yl2, 160)
	D(2, -10, 0, yl2, 160)
	# 直折的金属弩臂(y≈-22)：中段平、外段斜着往后折
	for x in range(-15, 15):
		var ax: float = absf(float(x) + 0.5)
		var off: int = 0 if ax < 7.0 else int(round((ax - 7.0) * 0.75))
		B(x, -23 + off, 4, x, -22 + off, 5, gm2 if ax < 7.0 else gm)
		if (int(ax) % 4) == 2:
			D(x, -23 + off, 6, yl)
	# 端头电极针(竖着，顶端发光)
	for tx: int in [-16, 15]:
		B(tx, -17, 3, tx, -16, 6, gm3)
		B(tx, -17, 7, tx, -17, 8, cu2)
		D(tx, -17, 9, arc, 200)
	_g5_string(15, -16, -8, 6, VGrid.hexc("#aab0ba"))
	B(-1, -9, 6, 0, -7, 7, cu)
	# 上弦的电弩箭(发光)
	B(-1, -30, 8, 0, -10, 8, yl, 120)
	B(-1, -32, 8, 0, -31, 8, arc, 200)
	D(-1, -33, 8, arc, 220)
	# 弩口两根往前伸的电极叉
	for sx: int in [-2, 1]:
		B(sx, -31, 2, sx, -29, 2, cu)
		D(sx, -32, 2, arc, 200)
		B(sx, -31, 6, sx, -29, 6, cu)
		D(sx, -32, 6, arc, 200)
	_end()


# ====================================================================== 蜂巢手弩(黄 · 4)：蜜色木弩身 + 顶上一个六角蜂巢 + 蜂翼弩臂
## 养蜂人的手弩：蜜色木弩身(深褐条纹)，顶上背着一个六角蜂巢匣(金黄的巢室、深色巢壁，侧面淌着一道发光的蜂蜜)，
## 弩臂是两对往后斜的半透明蜂翼(淡白微光、翅脉深一档)，根部是黄黑相间的环；弩口一根黑色的蜂针；箭槽里趴着一只小蜜蜂(= 它射出去的东西)。
func g5_hive() -> void:
	_begin(false)
	var hw := VGrid.hexc("#c07f2c")
	var hw2 := VGrid.hexc("#dc9c45")
	var hw3 := VGrid.hexc("#7f4f17")
	var cell := VGrid.hexc("#f4c443")
	var cell2 := VGrid.hexc("#ffdc6e")
	var wall := VGrid.hexc("#a2650f")
	var honey := VGrid.hexc("#f6a623")
	var bk := VGrid.hexc("#201b16")
	var wing := VGrid.hexc("#eef3f6")
	var wing2 := VGrid.hexc("#c9d8e2")
	_g5_grip(hw3, hw, bk, bk)
	# 弩身(深褐条纹)
	B(-1, -25, 2, 0, 6, 5, hw)
	B(-1, -25, 6, 0, 6, 6, hw2)
	for ry: int in [-22, -18, 0, 4]:
		B(-1, ry, 2, 0, ry, 6, hw3)
	B(-2, 4, 1, 1, 9, 5, hw)
	B(-2, 9, 1, 1, 9, 5, hw3)
	# 六角蜂巢匣(弩身后段顶上)：x -3..2、y -13..-2、z 7..12，四个侧面画巢室(每 3×3 一格，中心亮)
	B(-3, -13, 7, 2, -2, 12, wall)
	for y in range(-13, -1):
		for z in range(7, 13):
			var cu: int = (y + 40) % 3
			var cv: int = (z + ((y + 40) / 3 % 2) + 40) % 3
			if cu != 0 and cv != 0:
				var cc: int = cell2 if (cu == 1 and cv == 1) else cell
				D(-4, y, z, cc, 30)
				D(3, y, z, cc, 30)
	B(-2, -12, 13, 1, -3, 13, cell)
	B(-1, -11, 14, 0, -4, 14, cell2)
	# 侧面淌下来的蜂蜜(发光)
	B(3, -9, 4, 3, -8, 6, honey, 70)
	D(3, -9, 3, honey, 90)
	B(-4, -5, 5, -4, -5, 6, honey, 70)
	# 弩臂：两对半透明蜂翼(上下各一片，往后斜)，翅根黄黑环
	for sgn: int in [-1, 1]:
		var rx0: int = 2 if sgn > 0 else -3
		B(rx0, -23, 3, rx0, -21, 6, bk)
		B(rx0 + sgn, -23, 3, rx0 + sgn, -21, 6, cell)
		for i in range(0, 14):
			var xo: int = 4 + i
			var x: int = xo if sgn > 0 else -1 - xo
			var t: float = float(i) / 13.0
			var y0: int = -23 + int(round(t * 6.0))
			var hgt: float = sin((0.15 + t * 0.85) * PI) * 3.2
			for z in range(5, 6 + int(round(hgt))):
				D(x, y0, z, wing2 if (z == 5 or i % 4 == 0) else wing, 35)
			if i < 9:
				var lo: float = sin((0.2 + t / 0.65 * 0.8) * PI) * 1.8
				for z2 in range(4 - int(round(lo)), 4):
					D(x, y0 + 1, z2, wing2 if i % 4 == 0 else wing, 35)
	_g5_string(16, -17, -8, 5, VGrid.hexc("#e8dcc0"))
	B(-1, -9, 6, 0, -7, 7, bk)
	# 箭槽里的小蜜蜂(黄黑条纹的身子 + 一对小翅膀)
	B(-1, -24, 7, 0, -24, 7, bk)
	B(-1, -23, 7, 0, -22, 8, cell)
	B(-1, -21, 7, 0, -21, 8, bk)
	B(-1, -20, 7, 0, -19, 8, cell)
	D(-1, -18, 7, bk)
	D(0, -18, 7, bk)
	D(-2, -21, 9, wing, 50)
	D(1, -21, 9, wing, 50)
	# 弩口的黑色蜂针
	B(-1, -27, 3, 0, -26, 5, bk)
	D(-1, -28, 4, bk)
	D(0, -28, 4, bk)
	D(0, -29, 4, VGrid.hexc("#4a4036"))
	_end()


# ====================================================================== 荆棘手弩(绿 · 4)：缠着青藤的老树枝 + 带刺的枝条弩臂
## 林中的手弩：深色树皮的弩身，两条青藤一路绕着它盘上去(叶子错着长)，尾托上开着一朵粉白的花；
## 弩臂是两根往后弯的带刺枝条(上下错开的尖刺、端头抽出新叶)，弦是一股藤丝；上弦的是一颗带叶的刺种子(= 它射出去的东西)。
func g5_thorn() -> void:
	_begin(false)
	var bk := VGrid.hexc("#5a3a21")
	var bk2 := VGrid.hexc("#77502c")
	var bk3 := VGrid.hexc("#3c2614")
	var vn := VGrid.hexc("#3f8c3a")
	var vn2 := VGrid.hexc("#64b44c")
	var lf := VGrid.hexc("#7cc95a")
	var thorn := VGrid.hexc("#d8c79a")
	var pk := VGrid.hexc("#f3a6c0")
	var pk2 := VGrid.hexc("#fff0f5")
	var pist := VGrid.hexc("#f0cf4a")
	_g5_grip(bk3, bk, vn, bk3)
	# 弩身：树枝(粗细有点起伏、树皮纹)
	for y in range(-26, 8):
		var bump: int = 1 if ((y + 40) % 9) < 2 else 0
		B(-1, y, 3 - bump, 0, y, 5, bk if ((y + 40) % 5) != 0 else bk2)
		D(-1, y, 6, bk2 if ((y + 40) % 3) != 0 else bk)
	B(-2, 4, 1, 1, 9, 5, bk)
	B(-2, 10, 2, 1, 10, 5, bk3)
	B(-1, -27, 3, 0, -27, 5, bk3)
	B(-1, -26, 7, 0, -10, 7, bk3)
	# 两条青藤沿弩身盘绕(一条从左侧、一条从右侧起)，隔几格长一片叶子
	for k in range(0, 34):
		var y2: int = -25 + k
		var ph: int = (k % 8)
		var side: Array = [[-2, 3], [-2, 4], [-2, 5], [-1, 7], [0, 7], [1, 5], [1, 4], [1, 3]]
		var sp: Array = side[ph]
		D(int(sp[0]), y2, int(sp[1]), vn2 if (k % 3) == 0 else vn)
		var sp2: Array = side[(ph + 4) % 8]
		if (k % 2) == 0:
			D(int(sp2[0]), y2, int(sp2[1]), vn)
		if (k % 7) == 3:
			var lx: int = -3 if int(sp[0]) < 0 else 2
			D(lx, y2, int(sp[1]), lf)
			D(lx, y2 + 1, int(sp[1]) + 1, lf)
	# 带刺的枝条弩臂(y≈-24)，两端往后弯；上下错开的尖刺，端头抽出新叶
	for x in range(-15, 15):
		var a: float = absf(float(x) + 0.5) / 15.0
		var off: int = int(round(a * a * 6.0))
		B(x, -25 + off, 4, x, -24 + off, 5, bk2 if (x % 3) != 0 else bk)
		var ax: int = int(absf(float(x) + 0.5))
		if ax > 2 and (ax % 3) == 0:
			D(x, -26 + off, 6, thorn)
			D(x, -25 + off, 6, bk3)
		elif ax > 3 and (ax % 3) == 1:
			D(x, -24 + off, 3, bk3)
			D(x, -23 + off, 2, thorn)
	for sgn: int in [-1, 1]:
		var tx: int = 15 if sgn > 0 else -16
		D(tx, -18, 5, bk2)
		D(tx + sgn, -17, 6, lf)
		D(tx + sgn, -16, 6, vn2)
		D(tx, -16, 7, lf)
		D(tx + 2 * sgn, -18, 6, lf)
	_g5_string(15, -18, -8, 6, VGrid.hexc("#a6c46e"))
	B(-1, -9, 6, 0, -7, 7, vn)
	# 上弦的刺种子：一颗棕色的种荚(两头尖)，尾上一片叶
	B(-1, -30, 8, 0, -21, 8, VGrid.hexc("#8a5a2e"))
	B(-1, -28, 9, 0, -23, 9, VGrid.hexc("#a8733d"))
	D(-1, -31, 8, thorn)
	D(0, -31, 8, thorn)
	D(-1, -32, 8, thorn)
	B(-1, -20, 8, 0, -18, 9, lf)
	D(-2, -19, 9, vn2)
	D(1, -19, 9, vn2)
	# 尾托上的花：五片粉白花瓣 + 黄色花心
	for p: Vector3i in [Vector3i(-3, 6, 4), Vector3i(2, 6, 4), Vector3i(-3, 7, 5), Vector3i(2, 7, 5), Vector3i(-3, 6, 6), Vector3i(2, 6, 6)]:
		D(p.x, p.y, p.z, pk)
	for p2: Vector3i in [Vector3i(-4, 6, 5), Vector3i(3, 6, 5), Vector3i(-3, 5, 5), Vector3i(2, 5, 5)]:
		D(p2.x, p2.y, p2.z, pk2)
	D(-3, 6, 5, pist, 40)
	D(2, 6, 5, pist, 40)
	_end()
