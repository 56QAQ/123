extends "res://tools/model_weapons.gd"
## 通用武器 · gen6 的模型(tools/build_kits.gd 按 PARTS 登记)。可以直接用 model_weapons.gd 里的所有辅助函数(_begin / 画体素的那些)。
## PARTS：部件名 -> [资源名, 方法名, 参数…]。
## 步枪 4 把照 spotter_rifle() / keeneye_rifle() 的尺寸与握点：手枪式握把在原点，弹匣 y -9..-6，护木 y -32..-13(底 z 1：左手托在 y -13 附近)，
##   枪管到 y -51 左右，枪口 -55..-52，枪托 y 7..19(往下加深到 z -3，Q 版短托)。枪械约定：-Y = 枪口，+Z = 上，x = 厚度(-2..1)。
## 弓 2 把照 bow_short() / bow_farthest()：弓坐标系原点 = 握把中心，Y = 弓臂方向，+Z = 弓腹(朝目标)，弦在 z = BowModel.STRING_Z；
##   弓臂按 |y| 分段绑 Bow_U1/U2、Bow_D1/D2，弦在端帽骨与搭箭点(Bow_Nock)之间插值；箭画在 Arrow 骨上(局部 z = 0 为箭尾)。
## 颜色一律写死(VGrid.hexc)，不用调色板里会被换色的青色 / 眼睛 / 头发 / 皮肤色。

const PARTS := {
	"W_rifle_g6_transfusion": ["wpn_rifle_g6_transfusion", "g6_transfusion_rifle"],
	"W_rifle_g6_momentum": ["wpn_rifle_g6_momentum", "g6_momentum_repeater"],
	"W_rifle_g6_tide": ["wpn_rifle_g6_tide", "g6_tide_rifle"],
	"W_rifle_g6_hexline": ["wpn_rifle_g6_hexline", "g6_hexline_rifle"],
	"W_bow_g6_windchaser": ["wpn_bow_g6_windchaser", "g6_windchaser_bow"],
	"W_bow_g6_goldcrow": ["wpn_bow_g6_goldcrow", "g6_goldcrow_bow"],
}


## 手枪式握把(一道道防滑纹) + 握把底 + 扳机护圈 + 扳机：照 spotter_rifle()
func _g6_grip(c1: int, c2: int, base: int, guard: int, trig: int) -> void:
	for z in range(-5, 3):
		B(-1, -1, z, 0, 2, z, c1 if posmod(z, 2) == 0 else c2)
	B(-1, 3, -4, 0, 3, 2, c2)
	B(-1, -1, -6, 0, 3, -6, base)
	B(-1, -5, 0, 0, -5, 2, guard)
	B(-1, -4, 0, 0, -2, 0, guard)
	D(-1, -3, 1, trig)
	D(0, -3, 1, trig)


## 枪托：往后(+Y)并往下加深(Q 版短托)；col(y) 给每一排的颜色
func _g6_stock(col: Callable, y0: int = 7, y1: int = 17) -> void:
	for y in range(y0, y1 + 1):
		var t: float = float(y - y0) / float(maxi(1, y1 - y0))
		var zlo: int = int(round(lerpf(1.0, -3.0, t)))
		B(-1, y, zlo, 0, y, 5, col.call(y))


# ====================================================================== 输血步枪(红)
## 白漆的枪身、红色警示条；枪托两侧各挂一袋血浆(暗红，袋口一根透明软管一路接进机匣)，枪管下挂一支装着发光血清的玻璃药管(两头镀铬)；
## 机匣顶上一只小红点瞄具(红色镜片)，枪口镀铬 + 一圈红。枪托侧面一枚红色血滴标记。
func g6_transfusion_rifle() -> void:
	_begin(false)
	var wt := VGrid.hexc("#ece7e2")
	var wt2 := VGrid.hexc("#d5cec8")
	var wt3 := VGrid.hexc("#b9b1aa")
	var rd := VGrid.hexc("#c4262f")
	var rd2 := VGrid.hexc("#e24b4f")
	var rd3 := VGrid.hexc("#86161e")
	var bk := VGrid.hexc("#26272c")
	var bk2 := VGrid.hexc("#393b42")
	var st := VGrid.hexc("#666b75")
	var st2 := VGrid.hexc("#878c97")
	var cr := VGrid.hexc("#c8cdd5")
	var cr2 := VGrid.hexc("#e6e9ee")
	var blood := VGrid.hexc("#b0101c")
	var blood2 := VGrid.hexc("#e0303a")
	var tube := VGrid.hexc("#e9b9b9")
	var glass := VGrid.hexc("#f2d6d6")
	_g6_grip(bk, bk2, rd3, st, rd2)
	# ---- 机匣(白漆，每 6 格一道接缝)：两侧一条红色警示条(z 4)，几颗螺丝；顶上一只小红点瞄具
	for y in range(-12, 7):
		B(-2, y, 2, 1, y, 5, wt3 if posmod(y, 6) == 0 else wt)
		B(-2, y, 5, 1, y, 5, wt2 if posmod(y, 6) == 0 else wt)
	B(-2, -12, 4, -2, 6, 4, rd)
	B(1, -12, 4, 1, 6, 4, rd)
	for sy: int in [-10, -2, 4]:
		D(-3, sy, 3, st2)
		D(2, sy, 3, st2)
	B(-3, -6, 3, -3, -3, 3, bk)                               # 抛壳口
	B(-1, -9, 6, 0, -2, 6, bk)
	B(-2, -8, 7, 1, -3, 9, bk2)
	B(-1, -9, 7, 0, -9, 8, rd2, 140)                          # 红点镜片(朝前)
	B(-1, -2, 7, 0, -2, 8, bk)
	# ---- 直弹匣(白，底板红)
	B(-1, -9, -4, 0, -6, 1, wt2)
	B(-1, -9, -5, 0, -6, -5, rd)
	# ---- 护木(白，三道红箍；底下一条防滑纹：左手托在这里)
	B(-2, -32, 1, 1, -13, 5, wt)
	for yb: int in [-31, -23, -15]:
		B(-3, yb, 1, 2, yb, 5, rd)
	for y2 in range(-30, -14):
		if posmod(y2, 8) != 1:
			D(-3, y2, 3, wt2)
			D(2, y2, 3, wt2)
	for y4 in range(-31, -13, 2):
		B(-1, y4, 1, 0, y4, 1, wt3)
	# ---- 枪管(枪灰) + 镀铬枪口(一圈红)
	for y5 in range(-51, -32):
		B(-1, y5, 3, 0, y5, 4, st2 if posmod(y5, 6) == 0 else st)
	B(-2, -55, 2, 1, -52, 5, cr)
	B(-2, -52, 2, 1, -52, 5, rd)
	B(-2, -55, 2, 1, -55, 5, cr2)
	B(-1, -55, 3, 0, -55, 4, bk)
	# ---- 枪管下的血清药管：两头镀铬，中间玻璃 + 发光的血清(一格一格往前流的气泡)
	B(-1, -48, 1, 0, -47, 2, cr)
	B(-1, -37, 1, 0, -36, 2, cr)
	B(-2, -47, -2, 1, -47, 2, cr2)
	B(-2, -37, -2, 1, -37, 2, cr2)
	for yv in range(-46, -37):
		B(-2, yv, 0, 1, yv, 0, glass)                          # 玻璃(上下两排)
		B(-2, yv, -2, 1, yv, -2, glass)
		B(-2, yv, -1, 1, yv, -1, blood if posmod(yv, 4) != 0 else blood2, 70 if posmod(yv, 4) != 0 else 110)
	B(-2, -38, -3, 1, -38, -3, cr)                            # 下面的卡箍
	# ---- 枪托(白漆，红色托底) + 侧面的红色血滴
	_g6_stock(func(y: int) -> int: return wt3 if posmod(y, 6) == 0 else wt)
	B(-1, 9, 6, 0, 14, 6, wt2)
	B(-2, 18, -3, 1, 19, 5, rd)
	B(-2, 19, -3, 1, 19, 5, rd3)
	for side: int in [-2, 1]:
		D(side, 12, 3, rd)
		B(side, 13, 1, side, 13, 3, rd)
		D(side, 14, 2, rd2)
	# ---- 两袋血浆：挂在枪托两侧(暗红的袋子 + 白标签 + 袋口)，一根透明软管从袋口往前接进机匣
	for bx: Array in [[-4, -3, -3], [2, 3, 2]]:
		var x0: int = bx[0]
		var x1: int = bx[1]
		var xi: int = bx[2]
		B(x0, 9, -1, x1, 15, 3, blood, 25)
		B(x0, 10, 0, x1, 14, 2, blood2, 45)
		B(x0, 11, 1, x1, 12, 1, wt)                            # 标签
		B(x0, 8, 2, x1, 8, 3, wt2)                             # 袋口
		for ty in range(-4, 8):
			D(xi, ty, 5 if ty > 2 else 4, tube)
		D(xi, -5, 4, cr)
	_end()


# ====================================================================== 乘势连发枪(黄)
## 杠杆连发枪：胡桃木枪托和前托、金色机匣(侧面刻一轮放射的旭日纹)、八角形的长枪管下面贴着一根管状弹仓、几道金箍；
## 握把外面一只大大的金色杠杆环；准星是一片金色的刀片，没有瞄准镜。
func g6_momentum_repeater() -> void:
	_begin(false)
	var wd := VGrid.hexc("#5c351a")
	var wd2 := VGrid.hexc("#744422")
	var wd3 := VGrid.hexc("#40240e")
	var au := VGrid.hexc("#d3a128")
	var au2 := VGrid.hexc("#f1cb4e")
	var au3 := VGrid.hexc("#97700f")
	var ds := VGrid.hexc("#363940")
	var ds2 := VGrid.hexc("#4f535c")
	var tb := VGrid.hexc("#6b707a")
	_g6_grip(wd, wd2, au3, au, au2)
	# ---- 杠杆环(金)：从扳机护圈往下绕过握把的前面和底下
	B(-1, -6, -8, 0, -6, -1, au)
	B(-1, -6, -8, 0, 4, -8, au)
	B(-1, 4, -8, 0, 4, -6, au)
	B(-1, -6, -8, 0, -6, -8, au2)
	# ---- 机匣(金，z 2..5)：两侧刻一轮旭日纹(暗金的放射线)；右侧装弹口(深色)，顶上击锤
	for y in range(-12, 7):
		B(-2, y, 2, 1, y, 5, au3 if posmod(y, 6) == 0 else au)
		B(-2, y, 5, 1, y, 5, au2 if posmod(y, 6) != 0 else au)
	for side: int in [-2, 1]:
		var cy := -3.0
		var cz := 3.5
		for k in range(7):
			var a: float = PI * (0.15 + 0.7 * float(k) / 6.0)       # 半轮旭日：放射线朝后上方
			for r in range(1, 5):
				var py: int = int(round(cy + cos(a) * float(r) * 1.5))
				var pz: int = int(round(cz + sin(a) * float(r) * 0.6))
				if py >= -11 and py <= 5 and pz >= 2 and pz <= 5:
					D(side, py, pz, au3)
		D(side, -3, 3, au2)
	B(-3, 1, 3, -3, 4, 4, ds)                                 # 装弹口
	B(-1, 5, 6, 0, 6, 7, ds)                                  # 击锤
	D(-1, 6, 8, ds2)
	# ---- 前托(胡桃木，包着弹仓；左手托在 y -13 附近) + 金箍
	B(-2, -32, 0, 1, -13, 3, wd)
	for y2 in range(-31, -13):
		if posmod(y2, 5) == 0:
			B(-2, y2, 0, 1, y2, 0, wd3)
	B(-2, -33, 0, 1, -33, 3, au)
	# ---- 八角枪管(深钢) + 下面的管状弹仓(枪灰) + 两道金箍 + 金色枪口
	for y5 in range(-52, -12):
		B(-1, y5, 4, 0, y5, 5, ds2 if posmod(y5, 7) == 0 else ds)
	for y6 in range(-48, -32):
		B(-1, y6, 2, 0, y6, 3, tb)
	B(-1, -49, 2, 0, -49, 3, au3)
	for yb: int in [-46, -39]:
		B(-2, yb, 2, 1, yb, 5, au)
	B(-2, -54, 3, 1, -53, 6, au)
	B(-1, -54, 4, 0, -54, 5, VGrid.hexc("#16171a"))
	# ---- 准星(金色刀片) + 照门
	B(-1, -51, 6, 0, -50, 8, au2)
	B(-2, -16, 6, 1, -15, 7, ds)
	D(-1, -16, 7, VGrid.hexc("#16171a"))
	D(0, -16, 7, VGrid.hexc("#16171a"))
	# ---- 枪托(胡桃木，一侧亮一点)，金色托底板，托侧一枚金色旭日
	_g6_stock(func(y: int) -> int: return wd3 if posmod(y, 6) == 0 else wd)
	for y8 in range(7, 18):
		D(-1, y8, 5, wd2)
	B(-2, 18, -3, 1, 19, 5, au)
	B(-2, 19, -3, 1, 19, 5, au3)
	for side2: int in [-2, 1]:
		B(side2, 11, 1, side2, 13, 3, au)
		D(side2, 12, 2, au2)
		for d: Vector2i in [Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
			D(side2, 12 + d.x, 2 + d.y, au3)
	_end()


# ====================================================================== 回潮步枪(青)
## 珍珠白的枪身、青色的护木(白色鳞纹)、枪管上一根灌满海水的玻璃管(发光的青色水 + 几颗白气泡)；枪口张开成一只海螺(扇贝棱)；
## 枪托底下卷着一道青色的浪(浪尖白沫)；握把上镶珠母贝。
func g6_tide_rifle() -> void:
	_begin(false)
	var pw := VGrid.hexc("#eef3f1")
	var pw2 := VGrid.hexc("#d6e2e1")
	var pw3 := VGrid.hexc("#b6caca")
	var tl := VGrid.hexc("#229eac")
	var tl2 := VGrid.hexc("#5ac4cd")
	var tl3 := VGrid.hexc("#146d78")
	var wa := VGrid.hexc("#2fb6c4")
	var wa2 := VGrid.hexc("#86dde4")
	var foam := VGrid.hexc("#f2fcfd")
	var nacre := VGrid.hexc("#f2dfe8")
	var nacre2 := VGrid.hexc("#dbe7f4")
	var sv := VGrid.hexc("#a9b4bb")
	var sv2 := VGrid.hexc("#cdd5da")
	var dk := VGrid.hexc("#1d3a40")
	_g6_grip(pw, pw2, tl3, sv, tl2)
	for gz: int in [-4, -2, 0]:
		D(-2, 0, gz, nacre if gz != -2 else nacre2)
		D(1, 1, gz, nacre2 if gz != -2 else nacre)
	# ---- 机匣(珍珠白)：两侧一道青色的波浪线
	for y in range(-12, 7):
		B(-2, y, 2, 1, y, 5, pw3 if posmod(y, 6) == 0 else pw)
		B(-2, y, 5, 1, y, 5, pw2)
		var wz: int = 3 + int(round(sin(float(y) * 0.7)))
		D(-2, y, wz, tl)
		D(1, y, wz, tl)
	B(-3, -6, 3, -3, -4, 4, dk)
	# ---- 直弹匣(青，底板白)
	B(-1, -9, -4, 0, -6, 1, tl)
	B(-1, -9, -5, 0, -6, -5, pw2)
	# ---- 护木(青色 + 白色鳞纹；底下防滑纹)
	B(-2, -32, 1, 1, -13, 5, tl)
	for y2 in range(-31, -13):
		for z2 in range(2, 5):
			if posmod(y2 + (z2 % 2) * 2, 4) == 0:
				D(-3, y2, z2, tl2)
				D(2, y2, z2, tl2)
			else:
				D(-3, y2, z2, tl)
				D(2, y2, z2, tl)
	for y4 in range(-31, -13, 2):
		B(-1, y4, 1, 0, y4, 1, tl3)
	# ---- 枪管(银白) + 海螺枪口(往外张开的扇贝棱，口沿青)
	for y5 in range(-51, -32):
		B(-1, y5, 3, 0, y5, 4, sv2 if posmod(y5, 6) == 0 else sv)
	for yq in range(-56, -51):
		var rr: int = -51 - yq                                  # 1..5：越往前张得越开
		var hw: int = 1 + rr / 2
		for x in range(-1 - hw, 1 + hw):
			for z in range(3 - hw, 5 + hw):
				var edge: bool = x == -1 - hw or x == hw or z == 3 - hw or z == 4 + hw
				if not edge and yq > -56:
					continue
				var ridge: bool = posmod(x + z, 2) == 0
				D(x, yq, z, tl if yq == -56 else (pw if ridge else pw2))
	B(-1, -56, 3, 0, -56, 4, dk)
	# ---- 枪管上的海水玻璃管(两头银箍，中间发光的青色海水 + 白气泡)
	B(-1, -47, 5, 0, -47, 8, sv)
	B(-1, -14, 5, 0, -14, 8, sv)
	for yt in range(-46, -14):
		B(-1, yt, 5, 0, yt, 5, sv2)                             # 托架
		var bub: bool = posmod(yt * 7, 11) == 0
		B(-1, yt, 6, 0, yt, 7, foam if bub else (wa if posmod(yt, 3) != 0 else wa2), 30 if not bub else 60)
		if posmod(yt, 6) == 0:
			B(-1, yt, 8, 0, yt, 8, wa2, 20)
	# ---- 枪托(珍珠白，一侧珠母贝) + 托底下卷着的一道浪(青，浪尖白沫)
	_g6_stock(func(y: int) -> int: return pw3 if posmod(y, 6) == 0 else pw)
	B(-1, 9, 6, 0, 14, 6, pw2)
	B(-2, 18, -3, 1, 19, 5, tl3)
	for yn in range(9, 15):
		D(-2, yn, 3, nacre if posmod(yn, 2) == 0 else nacre2)
		D(1, yn, 3, nacre2 if posmod(yn, 2) == 0 else nacre)
	# 浪：从托底往前卷到托下面(y 17 → 9)，越往前越高、浪头往回卷
	for k in range(9):
		var a: float = float(k) / 8.0
		var yw: int = 17 - k
		var zb: int = int(round(lerpf(-3.0, -1.0, a)))
		var zd: int = int(round(lerpf(-5.0, -3.0, a) - sin(a * PI) * 1.5))
		B(-1, yw, zd, 0, yw, zb - 1, tl if k < 6 else tl2)
	B(-1, 8, -4, 0, 9, -3, foam)
	D(-1, 10, -5, foam)
	D(0, 10, -5, foam)
	B(-1, 7, -3, 0, 7, -2, tl2)
	_end()


# ====================================================================== 咒纹步枪(紫)
## 乌木的细长步枪：银色的包角和箍，护木与枪托两侧刻着一串发光的紫色咒文，枪管顶上一排咒点；机匣两侧各嵌一颗切面紫晶，
## 枪口下面坠着一枚小紫晶。
func g6_hexline_rifle() -> void:
	_begin(false)
	var eb := VGrid.hexc("#251b2b")
	var eb2 := VGrid.hexc("#35273e")
	var eb3 := VGrid.hexc("#16101b")
	var sv := VGrid.hexc("#a8aebd")
	var sv2 := VGrid.hexc("#d0d5df")
	var sv3 := VGrid.hexc("#767c8c")
	var vl := VGrid.hexc("#8840dc")
	var vl2 := VGrid.hexc("#b47cf4")
	var am := VGrid.hexc("#7b3cc6")
	var am2 := VGrid.hexc("#ad7cec")
	var am3 := VGrid.hexc("#4c2283")
	_g6_grip(eb, eb2, sv3, sv, vl2)
	# ---- 机匣(乌木 + 银边)；两侧各嵌一颗切面紫晶(菱形，中间亮)
	for y in range(-12, 7):
		B(-2, y, 2, 1, y, 5, eb3 if posmod(y, 6) == 0 else eb)
		B(-2, y, 5, 1, y, 5, sv3)
	B(-2, -12, 2, 1, -12, 5, sv)
	B(-2, 6, 2, 1, 6, 5, sv)
	for side: int in [-3, 2]:
		for d: Array in [[-5, 3, am3], [-4, 2, am], [-4, 3, am2], [-4, 4, am], [-3, 3, am2], [-2, 3, am], [-3, 2, am3], [-3, 4, am3], [-5, 4, am3], [-2, 2, am3]]:
			D(side, int(d[0]), int(d[1]), int(d[2]), 90 if int(d[2]) == am2 else 30)
	B(-1, -9, 6, 0, -2, 6, eb2)                              # 机匣顶
	# ---- 直弹匣(乌木，底板银)
	B(-1, -9, -4, 0, -6, 1, eb2)
	B(-1, -9, -5, 0, -6, -5, sv)
	# ---- 护木(乌木，y -34..-13)：两侧一串咒文(发光的紫：竖 / 斜 / 点，三格一个字)
	B(-2, -34, 1, 1, -13, 5, eb)
	var glyphs := [[[0, 0], [0, 1], [0, 2]], [[0, 0], [1, 1], [0, 2]], [[0, 1], [1, 0], [1, 2]], [[0, 0], [0, 2], [1, 1]]]
	var gi := 0
	for gy in range(-32, -14, 3):
		var gl: Array = glyphs[gi % glyphs.size()]
		gi += 1
		for side2: int in [-3, 2]:
			for p: Array in gl:
				D(side2, gy - int(p[0]), 2 + int(p[1]), vl, 45)
	for yb: int in [-34, -24, -13]:
		B(-3, yb, 1, 2, yb, 5, sv)
	for y4 in range(-33, -13, 2):
		B(-1, y4, 1, 0, y4, 1, eb3)
	# ---- 细长枪管(深银) + 三道银箍 + 顶上一排咒点；银色枪口，下面坠一枚小紫晶
	for y5 in range(-54, -34):
		B(-1, y5, 3, 0, y5, 4, sv3)
		if posmod(y5, 4) == 0:
			D(-1, y5, 5, vl, 45)
	for yb2: int in [-50, -43]:
		B(-2, yb2, 2, 1, yb2, 5, sv)
	B(-2, -57, 2, 1, -55, 5, sv)
	B(-2, -55, 2, 1, -55, 5, sv2)
	B(-1, -57, 3, 0, -57, 4, eb3)
	B(-1, -56, 0, 0, -55, 1, sv3)
	B(-1, -57, -2, 0, -55, -1, am, 60)
	D(-1, -56, -3, am2, 110)
	D(0, -56, -3, am3, 30)
	# ---- 枪托(乌木，一侧咒文)，银色托底板
	_g6_stock(func(y: int) -> int: return eb3 if posmod(y, 6) == 0 else eb)
	B(-1, 9, 6, 0, 14, 6, eb2)
	B(-2, 18, -3, 1, 19, 5, sv)
	B(-2, 19, -3, 1, 19, 5, sv3)
	for side3: int in [-2, 1]:
		for gy2: int in [9, 12, 15]:
			D(side3, gy2, 3, vl, 45)
			D(side3, gy2 + 1, 2, vl, 45)
			D(side3, gy2 + 1, 4, vl2, 60)
	_end()


# ====================================================================== 弓：共用的"弓臂分段 + 端帽 + 弦"
## 把还在 Bow 骨上的体素按 |y| 分到 Bow_U1/U2、Bow_D1/D2(照 bow_short / bow_farthest)
func _g6_bow_bones(r1: float, r2: float) -> void:
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
func _g6_bow_string(tip: int, cap: int, string_c: int, string_glow: int, nock_c: int) -> void:
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


## 箭(Arrow 骨，局部 z = 0 为箭尾)：杆、四片羽、箭头
func _g6_arrow(shaft: int, fletch: int, fletch2: int, head: int, head2: int, head_glow: int = 0) -> void:
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


func _g6_bow_begin() -> void:
	g.tx = -16
	g.ty = 44
	g.tz = 3
	g.sym = false
	g.mode = VGrid.FILL
	g.use("Bow")
	left = false


# ====================================================================== 逐风短弓(青)
## 浅色桦木的反曲短弓(比普通的弓短一截，弓梢往前卷)：握把缠青色皮条(白色缝线)；两头弓臂上各系一束羽毛(白羽青梢，往弓腹外翘)
## 和一条往后飘的青色飘带；弦是淡青白色。箭：桦木杆、青白羽、钢箭头。
const G6_WIND_TIP := 43


func g6_windchaser_bow() -> void:
	_g6_bow_begin()
	var bw := VGrid.hexc("#d8c296")
	var bw2 := VGrid.hexc("#c2a878")
	var bw3 := VGrid.hexc("#a38759")
	var tl := VGrid.hexc("#2896a4")
	var tl2 := VGrid.hexc("#55bcc6")
	var tl3 := VGrid.hexc("#176a75")
	var fw := VGrid.hexc("#f2f4f2")
	var fw2 := VGrid.hexc("#d6dcdc")
	# 握把：桦木 + 青色皮条(白缝线) + 上下两道深青箍
	g.box(-2, -7, -2, 1, 7, 2, bw)
	g.box(-2, -5, -3, 1, 5, 3, tl)
	for sy in range(-5, 6, 2):
		g.box(-2, sy, 3, -2, sy, 3, fw)
		g.box(1, sy, 3, 1, sy, 3, fw)
	g.box(-3, 6, -3, 2, 7, 3, tl3)
	g.box(-3, -7, -3, 2, -6, 3, tl3)
	# 弓臂(沿 model_bow 的曲线，短一截)；几道桦木的深色节
	for sgn: float in [1.0, -1.0]:
		for a in range(8, G6_WIND_TIP):
			var y0 := float(a) * sgn
			var y1 := float(a + 1) * sgn
			var r := lerpf(1.8, 1.0, float(a - 8) / float(G6_WIND_TIP - 8))
			var col: int = bw if (a % 9) < 7 else bw2
			if a == 14 or a == 27:
				col = bw3
			g.seg(Vector3(0.0, y0, BowModel.zc(y0)), Vector3(0.0, y1, BowModel.zc(y1)), r, r, col, true)
		# 反曲：弓梢往前(+Z)卷起
		for k in range(0, 5):
			var yy: float = float(G6_WIND_TIP - 1 + k / 2) * sgn
			var zz: float = BowModel.zc(float(G6_WIND_TIP) * sgn) + 1.0 + float(k)
			g.seg(Vector3(0.0, yy, zz - 1.0), Vector3(0.0, yy + 0.8 * sgn, zz), 1.0, 1.0, bw2, true)
		# 弓臂上的青色缠绳 + 一束羽毛(三根，往弓腹外翘、白羽青梢)
		var yf: float = 31.0 * sgn
		var zf: float = BowModel.zc(yf)
		g.seg(Vector3(0.0, yf - 1.5 * sgn, zf), Vector3(0.0, yf + 1.5 * sgn, BowModel.zc(yf + 1.5 * sgn)), 2.1, 2.1, tl, true)
		for fk in range(3):
			var ang: float = -0.5 + 0.5 * float(fk)
			var base := Vector3(float(fk - 1) * 0.8, yf, zf + 1.5)
			for s in range(6):
				var p := base + Vector3(sin(ang) * float(s) * 0.6, -sgn * float(s) * 0.35, float(s) * 0.9)
				g.box(int(floor(p.x)), int(floor(p.y)), int(floor(p.z)), int(floor(p.x)), int(floor(p.y)), int(floor(p.z)),
					tl2 if s >= 4 else (fw if s > 0 else fw2))
		# 飘带：从缠绳往后(-Z，朝射手)飘出去，一路轻轻起伏
		for rk in range(9):
			var ry: float = yf + sgn * (1.0 + float(rk) * 0.5)
			var rz: float = zf - 2.0 - float(rk) * 0.9
			var rx: float = sin(float(rk) * 0.8) * 1.2
			g.box(int(floor(rx)), int(floor(ry)), int(floor(rz)), int(floor(rx)), int(floor(ry)) + (1 if sgn > 0 else -1), int(floor(rz)),
				tl if rk % 3 != 2 else tl2)
	_g6_bow_bones(9.0, 26.0)
	_g6_bow_string(G6_WIND_TIP, tl3, VGrid.hexc("#dff2f2"), 0, VGrid.hexc("#2d4a50"))
	_g6_arrow(bw2, fw, tl2, VGrid.hexc("#9aa1ad"), VGrid.hexc("#c4cad3"))
	_end()


# ====================================================================== 金乌长弓(黄)
## 金色的长弓(比普通的弓长)：弓臂金色、每隔一段一道暗金的箍；握把缠深色皮革、上下金箍；握把上方弓腹一侧嵌一轮日轮
## (发光的金色圆盘 + 一圈放射的光芒)；两头弓梢各插一簇乌鸦的黑羽(往外张开，带一点蓝色的光泽)；弦是发光的金白色。
## 箭：金杆、赤金色的羽、发光的金箭头。
const G6_CROW_TIP := 52


func g6_goldcrow_bow() -> void:
	_g6_bow_begin()
	var au := VGrid.hexc("#d6a42c")
	var au2 := VGrid.hexc("#f0c850")
	var au3 := VGrid.hexc("#9c7218")
	var lt := VGrid.hexc("#3a2414")
	var lt2 := VGrid.hexc("#4e3220")
	var sun := VGrid.hexc("#ffd257")
	var sun2 := VGrid.hexc("#fff0b0")
	var ray := VGrid.hexc("#f2a826")
	var cw := VGrid.hexc("#1c1b22")
	var cw2 := VGrid.hexc("#2f2f3a")
	var cw3 := VGrid.hexc("#2a3654")
	var crim := VGrid.hexc("#b5401c")
	# 握把：深色皮革 + 上下金箍
	g.box(-2, -8, -2, 1, 8, 2, lt)
	g.box(-2, -6, -3, 1, 6, 3, lt2)
	g.box(-3, 7, -3, 2, 8, 3, au)
	g.box(-3, -8, -3, 2, -7, 3, au)
	# 弓臂：金色，每 6 格一道暗金箍
	for sgn: float in [1.0, -1.0]:
		for a in range(9, G6_CROW_TIP):
			var y0 := float(a) * sgn
			var y1 := float(a + 1) * sgn
			var r := lerpf(2.0, 1.1, float(a - 9) / float(G6_CROW_TIP - 9))
			var col: int = au if (a % 6) != 0 else au3
			if (a % 6) == 3:
				col = au2
			g.seg(Vector3(0.0, y0, BowModel.zc(y0)), Vector3(0.0, y1, BowModel.zc(y1)), r + (0.35 if (a % 6) == 0 else 0.0), r, col, true)
		# 弓梢往前卷一点(金)
		for k2 in range(0, 5):
			var yy: float = float(G6_CROW_TIP - 1) * sgn + float(k2) * 0.35 * sgn
			var zz: float = BowModel.zc(float(G6_CROW_TIP) * sgn) + 1.0 + float(k2) * 0.8
			g.seg(Vector3(0.0, yy, zz - 1.0), Vector3(0.0, yy + 0.8 * sgn, zz), 1.1, 1.1, au if k2 < 3 else au3, true)
		# 乌鸦黑羽：一簇 5 根，从弓梢往外(弓腹 +Z、往尖外)张开，羽尖带一点蓝色光泽
		var yt: float = float(G6_CROW_TIP - 4) * sgn
		var zt: float = BowModel.zc(yt)
		for fk in range(5):
			var ang: float = -0.9 + 0.45 * float(fk)
			var fx := sin(ang) * 0.5
			for s in range(8):
				var p := Vector3(fx * float(s), yt + sgn * (float(s) * 0.55 + absf(ang) * 1.5), zt + 1.0 + float(s) * 0.8 * cos(ang))
				var c: int = cw if s < 5 else (cw3 if s == 7 else cw2)
				g.box(int(floor(p.x)), int(floor(p.y)), int(floor(p.z)), int(floor(p.x)) + (1 if s < 3 else 0), int(floor(p.y)), int(floor(p.z)), c)
	# 日轮：握把上方、弓腹一侧(圆心 y 13、z 5，在 Y-Z 平面里)：发光的圆盘 + 一圈放射的光芒 + 外圈金环
	var cy := 13.0
	var cz := 5.0
	g.cur_glow = 0
	for yy2 in range(4, 23):
		for zz2 in range(-4, 15):
			var d := Vector2(float(yy2) + 0.5 - cy, float(zz2) + 0.5 - cz).length()
			if d <= 2.6:
				g.cur_glow = 130
				g.box(-1, yy2, zz2, 0, yy2, zz2, sun2)
			elif d <= 4.4:
				g.cur_glow = 90
				g.box(-1, yy2, zz2, 0, yy2, zz2, sun)
			elif d <= 5.4:
				g.cur_glow = 0
				g.box(-1, yy2, zz2, 0, yy2, zz2, au3)
	g.cur_glow = 0
	for rk in range(12):
		var ra: float = TAU * float(rk) / 12.0 + 0.13
		var ln: float = 8.4 if rk % 2 == 0 else 7.2
		for s2 in range(6, int(ln) + 1):
			var py: int = int(floor(cy + cos(ra) * float(s2)))
			var pz: int = int(floor(cz + sin(ra) * float(s2)))
			if pz < -3 and absi(py) < 9:
				continue                                         # 别伸进握把
			g.cur_glow = 60
			g.box(0, py, pz, 0, py, pz, ray if s2 < int(ln) else crim)
	g.cur_glow = 0
	_g6_bow_bones(10.0, 30.0)
	_g6_bow_string(G6_CROW_TIP, au2, VGrid.hexc("#fff0c4"), 70, au3)
	_g6_arrow(au2, crim, VGrid.hexc("#e8b440"), au, VGrid.hexc("#fff2b0"), 90)
	_end()
