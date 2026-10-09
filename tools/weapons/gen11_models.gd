extends "res://tools/model_weapons.gd"
## 通用武器 · gen11 的模型(tools/build_kits.gd 按 PARTS 登记)：步枪 3 把 + 手弩 3 把。
## 步枪照 spotter_rifle() / gen6 的尺寸与握点：手枪式握把在原点，弹匣 y -9..-6，护木 y -32..-13(底 z 1：左手托在 y -13 附近)，
##   枪管到 y -51 左右，枪口 -55..-52，枪托 y 7..19(往下加深到 z -3，Q 版短托)。
## 手弩照 crossbow() / gen5：弩身 y -27..9，弩臂在 y≈-22 附近横向展开(±X 约 15 格)、两端往后(+Y)弯，弦从两端连到弦扣(y≈-7)，弩箭搁在 z≈6。
## 枪械约定：-Y = 枪口 / 弩口，+Z = 上，x = 厚度，握把沿 -Z 往下(z -6..3)。颜色一律写死(VGrid.hexc)，主色就是武器颜色。

const PARTS := {
	"W_rifle_g11_inkwell": ["wpn_rifle_g11_inkwell", "g11_inkwell_rifle"],
	"W_rifle_g11_parasol": ["wpn_rifle_g11_parasol", "g11_parasol_rifle"],
	"W_rifle_g11_vermilion": ["wpn_rifle_g11_vermilion", "g11_vermilion_rifle"],
	"W_crossbow_g11_pearl": ["wpn_crossbow_g11_pearl", "g11_pearl_crossbow"],
	"W_crossbow_g11_chili": ["wpn_crossbow_g11_chili", "g11_chili_crossbow"],
	"W_crossbow_g11_dandelion": ["wpn_crossbow_g11_dandelion", "g11_dandelion_crossbow"],
}
## 枪身截面的正中(体素中心坐标)：x -2..1、z 2..5 这 4 × 4 格的中心
const G11_CX := -0.5
const G11_CZ := 3.5


# ====================================================================== 共用
## 手枪式握把(一道道防滑纹) + 握把底 + 扳机护圈 + 扳机
func _g11_grip(c1: int, c2: int, base: int, guard: int, trig: int) -> void:
	for z in range(-5, 3):
		B(-1, -1, z, 0, 2, z, c1 if posmod(z, 2) == 0 else c2)
	B(-1, 3, -4, 0, 3, 2, c2)
	B(-1, -1, -6, 0, 3, -6, base)
	B(-1, -5, 0, 0, -5, 2, guard)
	B(-1, -4, 0, 0, -2, 0, guard)
	D(-1, -3, 1, trig)
	D(0, -3, 1, trig)


## 一截圆杆(沿 Y)：截面中心 (cx, cz)(体素中心坐标)，半径 r(2.0 = 切了角的 4 × 4，2.6 = 外面一圈箍)；
## col(y, ang) 给颜色(ang = 截面上的角度，0 = +X、π/2 = +Z)
func _g11_rod(y0: int, y1: int, cx: float, cz: float, r: float, col: Callable, glow: int = 0) -> void:
	for y in range(y0, y1 + 1):
		for x in range(int(floor(cx - r)) - 1, int(ceil(cx + r)) + 2):
			for z in range(int(floor(cz - r)) - 1, int(ceil(cz + r)) + 2):
				var dx: float = float(x) - cx
				var dz: float = float(z) - cz
				if dx * dx + dz * dz <= r * r + 0.15:
					D(x, y, z, col.call(y, atan2(dz, dx)), glow)


## 单色的一圈箍
func _g11_band(y: int, r: float, c: int) -> void:
	_g11_rod(y, y, G11_CX, G11_CZ, r, func(_y: int, _a: float) -> int: return c)


## 一颗球：球心 (cx, cy, cz)(体素中心坐标)、半径 r；col(dx, dy, dz) 给颜色
func _g11_ball(cx: float, cy: float, cz: float, r: float, col: Callable, glow: int = 0) -> void:
	for x in range(int(floor(cx - r)) - 1, int(ceil(cx + r)) + 2):
		for y in range(int(floor(cy - r)) - 1, int(ceil(cy + r)) + 2):
			for z in range(int(floor(cz - r)) - 1, int(ceil(cz + r)) + 2):
				var d := Vector3(float(x) - cx, float(y) - cy, float(z) - cz)
				if d.length_squared() <= r * r + 0.2:
					D(x, y, z, col.call(d.x, d.y, d.z), glow)


## 弦：从弩臂两端 (-tip_x / tip_x - 1, tip_y) 连到弦扣 (0, nut_y)，高度 z
func _g11_string(tip_x: int, tip_y: int, nut_y: int, z: int, c: int, glow: int = 0) -> void:
	var n: int = tip_x + 1
	for i in range(0, n + 1):
		var t: float = float(i) / float(n)
		var x2: int = int(round(lerpf(-float(tip_x), -1.0, t)))
		var y2: int = int(round(lerpf(float(tip_y), float(nut_y), t)))
		D(x2, y2, z, c, glow)
		D(-1 - x2, y2, z, c, glow)


## 手弩的弩身(照 gen5)：前段 y -27..-9、中段 -8..6、尾托 3..9；顶面亮一档；箭槽
func _g11_stock(c: int, top: int, tail: int, groove: int) -> void:
	B(-1, -27, 2, 0, -9, 5, c)
	B(-1, -27, 6, 0, -9, 6, top)
	B(-1, -8, 3, 0, 6, 5, c)
	B(-1, -8, 6, 0, 6, 6, top)
	B(-2, 3, 2, 1, 8, 5, c)
	B(-2, 3, 6, 1, 8, 6, top)
	B(-2, 9, 2, 1, 9, 6, tail)
	B(-1, -27, 7, 0, -10, 7, groove)


# ====================================================================== 蓝墨钢笔枪(蓝 · 步枪)
## 一支大号钢笔：藏青笔杆 + 金箍，枪托是插在笔尾的笔帽(顶上一条金笔夹、尾端金顶)，机匣两侧开着看墨水的小窗(发光的蓝墨水)，
## 护木是一圈圈防滑纹的握位，前面是一枚竖着的金笔尖(中缝 + 气孔 + 刻花，底下黑色的导墨舌)，笔尖上挂着一滴发光的墨；弹匣是一只蓝墨水瓶(金瓶盖 + 白标签)。
func g11_inkwell_rifle() -> void:
	_begin(false)
	var nv := VGrid.hexc("#22388a")
	var nv2 := VGrid.hexc("#3352b4")
	var nv3 := VGrid.hexc("#15204f")
	var nvk := VGrid.hexc("#0d1230")
	var au := VGrid.hexc("#d6a849")
	var au2 := VGrid.hexc("#f3d27c")
	var au3 := VGrid.hexc("#9a7424")
	var ink := VGrid.hexc("#2f5cff")
	var ink2 := VGrid.hexc("#86a6ff")
	var glass := VGrid.hexc("#cfdcf5")
	var paper := VGrid.hexc("#eee7d4")
	var bk := VGrid.hexc("#1a1c22")
	_g11_grip(nv3, nvk, au, au, au2)
	# ---- 笔杆(机匣)：圆杆，顶面亮一档；两侧的看墨窗(玻璃 + 发光的墨水)；前后两道金箍
	_g11_rod(-12, 6, G11_CX, G11_CZ, 2.0, func(_y: int, a: float) -> int: return nv2 if a > 0.6 and a < 2.5 else nv)
	for wy in range(-10, -2):
		for sx: int in [-2, 1]:
			D(sx, wy, 3, ink, 90)
			D(sx, wy, 4, glass if posmod(wy, 3) != 0 else ink2, 40)
	_g11_band(6, 2.6, au)
	_g11_band(-12, 2.6, au)
	_g11_band(-11, 2.6, au3)
	# ---- 墨水瓶弹匣：方玻璃瓶(深蓝墨水透出来)、白标签、细瓶颈 + 金瓶盖
	B(-1, -9, 0, 0, -7, 1, au)
	B(-1, -9, -1, 0, -7, -1, au3)
	B(-2, -10, -6, 1, -6, -2, ink, 45)
	B(-2, -10, -4, 1, -6, -4, paper)
	D(-2, -8, -4, nv)
	D(1, -8, -4, nv)
	for gy: int in [-10, -6]:
		B(-2, gy, -6, 1, gy, -2, glass, 20)
	B(-2, -10, -7, 1, -6, -7, nv3)
	# ---- 护木 = 笔的握位：一圈圈防滑纹(左手托在这里)，前端一道金箍
	_g11_rod(-32, -13, G11_CX, G11_CZ, 2.0, func(y: int, a: float) -> int:
		return (nvk if posmod(y, 3) == 0 else nv3) if a < 0.4 or a > 2.7 else (nv if posmod(y, 3) == 0 else nv2))
	_g11_band(-33, 2.6, au)
	_g11_band(-34, 1.6, au3)
	# ---- 笔尖：竖着的金色薄片(x -1..0)，从 y -35 收到 -56 的尖；中缝、气孔、刻花；底下一条黑色的导墨舌(带鳍)
	for y in range(-56, -34):
		var t: float = float(-35 - y) / 21.0
		var half: float = 3.4 * pow(1.0 - t, 0.75)
		var zlo: int = int(round(3.0 - half))
		var zhi: int = maxi(zlo, int(round(3.5 + half)))
		B(-1, y, zlo, 0, y, zhi, au)
		B(-1, y, zhi, 0, y, zhi, au2)
		B(-1, y, zlo, 0, y, zlo, au3)
		if y <= -43:
			B(-1, y, 3, 0, y, 3, au3)                          # 中缝
		if y >= -45:
			B(-1, y, zlo - 1, 0, y, zlo - 1, bk)               # 导墨舌
			if posmod(y, 2) == 0:
				B(-1, y, zlo - 2, 0, y, zlo - 2, bk)
	B(-1, -42, 3, 0, -41, 4, nvk)                              # 气孔
	for p: Vector2i in [Vector2i(-37, 5), Vector2i(-38, 4), Vector2i(-37, 2), Vector2i(-39, 5), Vector2i(-39, 2)]:
		B(-1, p.x, p.y, 0, p.x, p.y, au2)                      # 刻花
	# 笔尖上挂着的一滴墨
	B(-1, -58, 3, 0, -57, 3, ink, 140)
	B(-1, -57, 2, 0, -57, 2, ink2, 120)
	# ---- 枪托 = 插在笔尾的笔帽：藏青、圆润，两道金箍，金顶；顶上一条金笔夹(前端一颗金珠)
	for y2 in range(7, 18):
		var zlo2: int = int(round(lerpf(1.0, -3.0, float(y2 - 7) / 10.0)))
		B(-2, y2, zlo2 + 1, 1, y2, 4, nv)
		B(-1, y2, zlo2, 0, y2, 5, nv)
		B(-1, y2, 5, 0, y2, 5, nv2)
	for gy2: int in [8, 15]:
		var zl: int = int(round(lerpf(1.0, -3.0, float(gy2 - 7) / 10.0)))
		B(-2, gy2, zl + 1, 1, gy2, 4, au)
		B(-1, gy2, zl, 0, gy2, 5, au)
	B(-2, 18, -2, 1, 18, 4, au)
	B(-1, 18, -3, 0, 18, 5, au)
	B(-1, 19, -1, 0, 19, 3, au2)
	B(-1, 9, 6, 0, 17, 6, au)                                  # 笔夹
	B(-1, 16, 6, 0, 17, 7, au2)
	B(-1, 9, 7, 0, 10, 7, au2)
	_end()


# ====================================================================== 油纸伞枪(青 · 步枪)
## 一把收拢的青色油纸伞：前半截是裹起来的伞面(一道道略带旋的褶、几朵白梅，中间系一道红绳和一颗铜扣)，伞尖铜头就是枪口；
## 后半截是竹伞柄(竹节)、木质的伞巢，枪托是往下弯的伞柄弯钩(藤条缠着)，钩底垂一束青色流苏。
func g11_parasol_rifle() -> void:
	_begin(false)
	var cy := VGrid.hexc("#2ba39a")
	var cy2 := VGrid.hexc("#4cc4b9")
	var cy3 := VGrid.hexc("#1b766f")
	var cyd := VGrid.hexc("#11524d")
	var wt := VGrid.hexc("#eef7f2")
	var pk := VGrid.hexc("#f0a2b4")
	var bam := VGrid.hexc("#d0bb78")
	var bam2 := VGrid.hexc("#b29d57")
	var bamk := VGrid.hexc("#7c6a34")
	var br := VGrid.hexc("#c99b45")
	var br2 := VGrid.hexc("#ecc675")
	var rd := VGrid.hexc("#c8323a")
	var wd := VGrid.hexc("#6a4428")
	var wd2 := VGrid.hexc("#87593a")
	_g11_grip(bam2, bamk, br, br, br2)
	# ---- 竹伞柄(机匣那一段)：竹节 + 木伞巢
	for y in range(-8, 8):
		var c: int = bamk if posmod(y, 7) == 0 else (bam if posmod(y, 2) == 0 else bam2)
		B(-1, y, 2, 0, y, 5, c)
		B(-1, y, 5, 0, y, 5, bam if posmod(y, 7) != 0 else bamk)
	_g11_rod(-10, -8, G11_CX, G11_CZ, 2.3, func(y2: int, _a: float) -> int: return wd2 if y2 == -9 else wd)
	B(-1, -11, 2, 0, -11, 5, wd)
	# ---- 伞面：从伞巢往前裹成一根纺锤(中间最粗)，一道道略带旋的褶
	var pleat := func(yy: int, a: float) -> int:
		var k: int = posmod(int(floor((a + float(yy) * 0.09) / (PI / 4.0))), 2)
		if a > 0.0:
			return cy2 if k == 0 else cy
		return cy if k == 0 else cy3
	for y3 in range(-48, -11):
		_g11_rod(y3, y3, G11_CX, G11_CZ, _g11_canopy_r(y3), pleat)
	# 白梅(伞面两侧各几朵：一个十字的白花瓣 + 粉色花心，贴在伞面最外面那一格)
	for f: Vector3i in [Vector3i(-1, -20, 4), Vector3i(-1, -29, 2), Vector3i(-1, -38, 4), Vector3i(1, -24, 3), Vector3i(1, -34, 4)]:
		for p: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 0)]:
			var yy2: int = f.y + p.x
			var zz: int = f.z + p.y
			var r: float = _g11_canopy_r(yy2)
			var dz: float = float(zz) - G11_CZ
			var w: float = r * r + 0.15 - dz * dz
			if w <= 0.0:
				continue
			var xo: int = int(floor(G11_CX + sqrt(w))) if f.x > 0 else int(ceil(G11_CX - sqrt(w)))
			D(xo, yy2, zz, pk if p == Vector2i.ZERO else wt)
	# 红绳 + 铜扣
	_g11_rod(-31, -30, G11_CX, G11_CZ, _g11_canopy_r(-30) + 0.7, func(_y: int, _a: float) -> int: return rd)
	B(-1, -31, int(round(G11_CZ + _g11_canopy_r(-30))) + 1, 0, -30, int(round(G11_CZ + _g11_canopy_r(-30))) + 1, br2)
	# ---- 伞尖(枪口)：铜头，一道箍
	for y4 in range(-56, -48):
		B(-1, y4, 3, 0, y4, 4, br if posmod(y4, 3) != 0 else br2)
	B(-2, -53, 2, 1, -52, 5, br2)
	B(-1, -57, 3, 0, -57, 4, cyd)
	# ---- 枪托 = 伞柄的弯钩：竹柄往后伸，再往下弯一圈(藤条一道道缠着)
	for y5 in range(8, 14):
		B(-1, y5, 2, 0, y5, 5, bamk if posmod(y5, 2) == 0 else bam2)
	for i in range(0, 41):
		var a2: float = PI * 0.5 - PI * 1.15 * float(i) / 40.0      # 从正上方往后、往下绕
		var py: int = int(round(13.5 + cos(a2) * 4.6))
		var pz: int = int(round(-1.0 + sin(a2) * 4.6))
		var col: int = bamk if posmod(int(floor(float(i) / 4.0)), 2) == 0 else bam2
		B(-2, py - 1, pz - 1, 1, py, pz, col)
	# 钩底的流苏：铜珠 + 青丝
	B(-1, 11, -8, 0, 11, -7, br2)
	for tz in range(-12, -8):
		B(-1, 11, tz, 0, 11, tz, cy if tz > -11 else cy2)
		D(-2, 11, tz, cy3)
		D(1, 11, tz, cy3)
	_end()


## 收拢的伞面在 y 处的半径(纺锤：靠伞巢细一点、中间最粗、往伞尖收细)
static func _g11_canopy_r(y: int) -> float:
	var t: float = float(-12 - y) / 36.0
	var r: float = 1.6 + 2.6 * sin(clampf(t * 1.25, 0.0, 1.0) * PI * 0.5) * (1.0 - smoothstep(0.55, 1.0, t)) + 0.6 * (1.0 - t)
	return maxf(r, 1.1)


# ====================================================================== 朱雀步枪(红 · 步枪)
## 朱漆描金：机匣两侧金色祥云纹、护木两侧收拢的翅羽(朱红 / 金一层压一层)，枪管几道金箍，枪口是一只朱雀的头(金喙 = 枪口、发光的金眼、
## 头顶往后飘的火焰羽冠)；枪托末端展开成一把尾羽(金边、橙色的焰尖)。
func g11_vermilion_rifle() -> void:
	_begin(false)
	var vr := VGrid.hexc("#c4301c")
	var vr2 := VGrid.hexc("#e24e32")
	var vr3 := VGrid.hexc("#8c1e12")
	var au := VGrid.hexc("#e0b445")
	var au2 := VGrid.hexc("#f8dc80")
	var au3 := VGrid.hexc("#a37a1c")
	var fl := VGrid.hexc("#ff8a2a")
	var fl2 := VGrid.hexc("#ffd060")
	var bk := VGrid.hexc("#2a1a14")
	_g11_grip(vr3, bk, au, au, au2)
	# ---- 机匣(朱漆，顶面亮一档) + 两侧金色祥云纹 + 金色照门
	for y in range(-12, 7):
		B(-2, y, 2, 1, y, 5, vr3 if posmod(y, 6) == 0 else vr)
		B(-1, y, 6, 0, y, 6, vr2)
	for sx: int in [-2, 1]:
		for p: Vector2i in [Vector2i(-9, 4), Vector2i(-8, 5), Vector2i(-7, 5), Vector2i(-6, 4), Vector2i(-7, 3), Vector2i(-8, 3), Vector2i(-5, 3),
				Vector2i(-4, 3), Vector2i(-3, 4), Vector2i(-2, 4), Vector2i(-1, 3), Vector2i(0, 3)]:
			D(sx, p.x, p.y, au2 if p.y == 5 else au)
	B(-1, -2, 7, 0, 3, 7, au)
	B(-1, 3, 8, 0, 3, 8, au2)
	# ---- 弹匣(朱红，金底)
	B(-1, -9, -4, 0, -6, 1, vr)
	B(-1, -9, -5, 0, -6, -5, au)
	# ---- 护木 + 两侧收拢的翅羽(一层压一层，往后斜)
	B(-2, -32, 1, 1, -13, 5, vr)
	B(-1, -32, 6, 0, -13, 6, vr2)
	for i in range(4):
		var y0: int = -32 + i * 5
		for k in range(7):
			var yy: int = y0 + k
			var zt: int = 5 - int(round(float(k) * 0.55))
			var c: int = au if k == 0 else (vr2 if i % 2 == 0 else vr)
			for sx2: int in [-3, 2]:
				B(sx2, yy, maxi(1, zt - 2), sx2, yy, zt, c)
				D(sx2, yy, maxi(1, zt - 2), au3)
	# ---- 枪管 + 金箍
	for y2 in range(-46, -32):
		B(-1, y2, 3, 0, y2, 4, vr3 if posmod(y2, 5) == 0 else vr)
	for ry: int in [-44, -39, -35]:
		B(-2, ry, 2, 1, ry, 5, au)
	# ---- 朱雀头：圆脑袋、金喙(枪口在喙尖)、金眼、头顶往后飘的火焰羽冠
	for y3 in range(-52, -46):
		var hw: int = 2 if y3 > -51 else 1
		B(-hw, y3, 1, hw - 1, y3, 6, vr)
		B(-1, y3, 7, 0, y3, 7, vr2)
	B(-1, -57, 3, 0, -53, 4, au)                               # 喙
	B(-1, -55, 2, 0, -53, 2, au3)
	B(-1, -57, 4, 0, -57, 4, au2)
	B(-1, -58, 3, 0, -58, 3, bk)                               # 喙尖 = 枪口
	for sx3: int in [-3, 2]:
		D(sx3, -50, 5, fl2, 150)                               # 眼睛
		D(sx3, -49, 5, bk)
		D(sx3, -51, 4, au)
	for j in range(6):                                         # 羽冠：从头顶往后飘的火焰羽
		var cy0: int = -50 + j
		var hh: int = int(float(j) / 2.0)
		B(-1, cy0, 8, 0, cy0, 8 + hh, fl if j < 4 else fl2, 110)
		B(-1, cy0, 9 + hh, 0, cy0, 9 + hh, fl2, 150)
	B(-1, -51, 8, 0, -51, 9, vr2)
	# ---- 枪托：朱漆，末端展开成尾羽(金边、焰尖)
	for y4 in range(7, 16):
		var zlo: int = int(round(lerpf(1.0, -3.0, float(y4 - 7) / 10.0)))
		B(-1, y4, zlo, 0, y4, 5, vr if posmod(y4, 4) != 0 else vr3)
		B(-1, y4, 6, 0, y4, 6, vr2)
	B(-2, 9, 2, 1, 9, 5, au)
	B(-1, 14, -3, 0, 16, 5, vr)
	# 尾羽：五根，从 y 15 往后、往上下展开成扇形
	for f in range(5):
		var ang: float = deg_to_rad(-55.0 + 27.5 * float(f))
		for s in range(0, 8):
			var py: int = 15 + int(round(cos(ang) * float(s) * 0.6))
			var pz: int = 1 + int(round(sin(ang) * float(s)))
			var c2: int = fl2 if s >= 7 else (fl if s >= 5 else (vr2 if f % 2 == 0 else vr))
			var g2: int = 140 if s >= 7 else (90 if s >= 5 else 0)
			B(-1, py, pz, 0, py, pz, c2, g2)
			if s >= 2 and s < 6:
				D(-2, py, pz, au)
				D(1, py, pz, au)
	_end()


# ====================================================================== 珍珠贝手弩(青 · 手弩)
## 弩身是深青的漆木、两侧嵌着一点点螺钿(青 / 粉 / 淡蓝的贝母)，弩臂是左右张开的两瓣扇贝壳(一道道放射的棱、白色的壳边)，
## 弩口搁着一颗发光的大珍珠；银弦；弩身下吊一串小珍珠。
func g11_pearl_crossbow() -> void:
	_begin(false)
	var lq := VGrid.hexc("#1d3a40")
	var lq2 := VGrid.hexc("#2c5258")
	var lq3 := VGrid.hexc("#11262a")
	var n1 := VGrid.hexc("#8fe3dc")
	var n3 := VGrid.hexc("#f1cfe4")
	var n4 := VGrid.hexc("#b4d9f6")
	var sh := VGrid.hexc("#4fb8b4")
	var sh2 := VGrid.hexc("#86dbd3")
	var sh3 := VGrid.hexc("#2f8a88")
	var sh4 := VGrid.hexc("#e6fbf8")
	var pearl := VGrid.hexc("#f6f4ec")
	var pearl2 := VGrid.hexc("#e4e9f2")
	var sv := VGrid.hexc("#c9d3da")
	var sv2 := VGrid.hexc("#eef3f6")
	_g11_grip(lq3, lq, sv, sv, sv2)
	_g11_stock(lq, lq2, sv, lq3)
	# 螺钿：两侧一串贝母小点(青 / 粉 / 淡蓝轮流)
	var nac: Array = [n1, n3, n4]
	var k := 0
	for y in range(-25, 8, 3):
		var zz: int = 4 if k % 2 == 0 else 3
		if y >= 3:
			D(-2, y, zz, nac[k % 3], 40)
			D(1, y, zz, nac[k % 3], 40)
		else:
			D(-1, y, zz, nac[k % 3], 40)
			D(0, y, zz, nac[(k + 1) % 3], 40)
		k += 1
	for ry: int in [-24, -15, -9]:
		B(-2, ry, 2, 1, ry, 7, sv)
	# ---- 弩臂：左右两瓣扇贝：铰合处在弩身两侧(y -24)，往外、往后张开成一把扇子(外沿一圈波浪形的白色壳边)，放射状的棱一深一浅
	for side: int in [-1, 1]:
		for xi in range(1, 17):
			for y in range(-28, -14):
				var dx: float = float(xi) - 0.5
				var dy: float = float(y + 24)
				var rr: float = sqrt(dx * dx + dy * dy)
				var th: float = atan2(dy, dx)
				if th < deg_to_rad(-14.0) or th > deg_to_rad(30.0) or rr < 1.5:
					continue
				var edge: float = 14.6 + 0.7 * cos((th - deg_to_rad(-14.0)) / deg_to_rad(44.0) * PI * 8.0)
				if rr > edge:
					continue
				var rib: bool = posmod(int(floor((th + 1.0) / deg_to_rad(5.5))), 2) == 0
				var x: int = xi if side > 0 else -1 - xi
				var rim: bool = rr > edge - 1.2
				D(x, y, 4, sh4 if rim else (sh2 if rib else sh), 30 if rim else 0)
				D(x, y, 5, sh4 if rim else (sh2 if rib else sh3))
				if rib and not rim and rr > 3.0:
					D(x, y, 6, sh2)
	B(-2, -26, 3, 1, -22, 6, sh3)                              # 铰合处
	# ---- 银弦 + 弦扣 + 弩口的大珍珠(发光)
	_g11_string(13, -18, -7, 7, sv2, 40)
	B(-1, -8, 6, 0, -7, 7, sv)
	_g11_ball(-0.5, -28.5, 9.0, 2.2, func(dx: float, _dy: float, dz: float) -> int: return pearl if dz + dx * 0.3 > -0.6 else pearl2, 60)
	# ---- 弩身下吊的一串小珍珠
	for i in range(4):
		var py: int = -20 + i * 3
		D(-1, py, 1, sv)
		D(-1, py, 0, pearl, 40)
		D(-1, py, -1 - (i % 2), pearl, 40)
	_end()


# ====================================================================== 朝天椒手弩(红 · 手弩)
## 木弩身(握把缠红绳)，弩臂是两根往外伸、往后弯的大红辣椒(青色的蒂在弩身两侧，越往外越细、尖头微微上翘)，
## 弩槽里搁着一只当箭的小辣椒；弩身底下吊着一串晒干的朝天椒(麻绳)。
func g11_chili_crossbow() -> void:
	_begin(false)
	var wd := VGrid.hexc("#7a4a26")
	var wd2 := VGrid.hexc("#94603a")
	var wd3 := VGrid.hexc("#55321a")
	var ch := VGrid.hexc("#d4281c")
	var ch2 := VGrid.hexc("#f24a32")
	var ch3 := VGrid.hexc("#8d150c")
	var chh := VGrid.hexc("#ff9a7a")
	var gr := VGrid.hexc("#3e8a2a")
	var gr2 := VGrid.hexc("#62b046")
	var tw := VGrid.hexc("#c9a76a")
	var rope := VGrid.hexc("#b02a20")
	_g11_grip(rope, wd3, wd2, wd3, ch2)
	_g11_stock(wd, wd2, wd3, wd3)
	for ry: int in [-20, -12, 1]:
		B(-2, ry, 2, 1, ry, 7, rope)
	# ---- 弩臂：两根大红辣椒(蒂在里、尖在外)：截面圆，越往外越细；往后弯，尖头微微上翘
	for side: int in [-1, 1]:
		for xi in range(1, 18):
			var a: float = float(xi) / 17.0
			var cyv: float = -24.0 + a * a * 7.0
			var czv: float = 4.0 + maxf(0.0, a - 0.8) * 6.0
			var r: float = 1.6
			if xi > 2:
				r = 2.3 * pow(maxf(0.0, 1.0 - (a - 0.12) / 0.9), 0.6)
			var x: int = xi if side > 0 else -1 - xi
			for y in range(int(floor(cyv - r)) - 1, int(ceil(cyv + r)) + 2):
				for z in range(int(floor(czv - r)) - 1, int(ceil(czv + r)) + 2):
					var dy: float = float(y) - cyv
					var dz: float = float(z) - czv
					if dy * dy + dz * dz > r * r + 0.3:
						continue
					var c: int
					if xi <= 2:
						c = gr2 if dz > 0.0 else gr                  # 蒂
					else:
						c = ch2 if dz > 0.8 else (ch3 if dz < -1.0 else ch)
						if dz > 1.2 and posmod(xi, 4) == 1:
							c = chh
					D(x, y, z, c)
	B(-2, -25, 3, 1, -23, 5, gr)
	# ---- 弦(麻色) + 弦扣 + 弩槽里的小辣椒(尖朝前，蒂在后)
	_g11_string(16, -17, -7, 6, tw)
	B(-1, -8, 6, 0, -7, 7, wd3)
	for y2 in range(-31, -12):
		var thick: bool = float(y2 + 31) / 18.0 > 0.3
		D(-1, y2, 8, ch2 if thick else ch, 30 if y2 < -28 else 0)
		D(0, y2, 8, ch if thick else ch3)
		if thick:
			D(-1, y2, 9, ch2)
			D(0, y2, 9, chh if posmod(y2, 5) == 0 else ch2)
	B(-1, -12, 8, 0, -11, 9, gr)
	B(-1, -10, 9, 0, -10, 9, gr2)
	# ---- 弩身底下吊的一串干辣椒(麻绳)
	for y3 in range(-22, -3):
		D(-1, y3, 1, tw)
	for i in range(4):
		var py: int = -20 + i * 5
		D(-1, py, 0, tw)
		B(-1, py, -1, 0, py, -1, gr)
		B(-1, py, -4, 0, py, -2, ch3 if i % 2 == 0 else ch)
		D(-1, py, -5, ch3)
	_end()


# ====================================================================== 蒲公英手弩(绿 · 手弩)
## 一根疙疙瘩瘩的老树枝当弩身(握把缠着树皮)，两侧冒出锯齿形的蒲公英叶子，侧面开着一朵小黄花；弩臂是两枝往外弯的嫩绿花茎，
## 茎梢各一颗小绒球(弦系在上面)；弩口顶着一团发着微光的大白绒球(一颗颗种子的冠毛，正中一点褐色)。
func g11_dandelion_crossbow() -> void:
	_begin(false)
	var br := VGrid.hexc("#6e4a2c")
	var br2 := VGrid.hexc("#8b623c")
	var br3 := VGrid.hexc("#4a301a")
	var lf := VGrid.hexc("#5aa83a")
	var lf2 := VGrid.hexc("#3f8a2c")
	var st := VGrid.hexc("#9ccf6a")
	var st2 := VGrid.hexc("#79b04b")
	var fluff := VGrid.hexc("#f4f4ec")
	var fluff2 := VGrid.hexc("#dcdccc")
	var seedc := VGrid.hexc("#8a6a3a")
	var yel := VGrid.hexc("#f6c629")
	var yel2 := VGrid.hexc("#e09c12")
	var strc := VGrid.hexc("#f1efe4")
	_g11_grip(br3, br, br3, br2, br2)
	# ---- 弩身：老树枝(上下边一起一伏、几个树疤)
	for y in range(-27, 10):
		var top: int = 6 + int(round(sin(float(y) * 0.55) * 0.8))
		var bot: int = (2 if y < -8 else 3) + (1 if posmod(y, 7) == 3 else 0)
		if y >= 3:
			B(-2, y, 2, 1, y, 5, br)
			B(-2, y, 6, 1, y, 6, br2)
		else:
			B(-1, y, bot, 0, y, top, br if posmod(y, 5) != 0 else br3)
			B(-1, y, top, 0, y, top, br2)
	for kn: Vector2i in [Vector2i(-19, 4), Vector2i(-4, 4)]:
		D(-1, kn.x, kn.y, br3)
		D(0, kn.x, kn.y, br3)
	B(-1, -27, 7, 0, -10, 7, br3)                              # 箭槽
	# 两侧的蒲公英叶子(锯齿)：从弩身往外斜着伸出去
	for side: int in [-1, 1]:
		for i in range(0, 8):
			var yy: int = -15 + i
			var wv: int = 1 + (i % 3 if i < 6 else 6 - i)
			for w in range(1, wv + 2):
				var x: int = w if side > 0 else -1 - w
				D(x, yy, 3, lf if w <= wv else lf2)
	# 侧面的小黄花
	for p: Vector2i in [Vector2i(4, 4), Vector2i(6, 4), Vector2i(5, 3), Vector2i(5, 5), Vector2i(4, 3), Vector2i(6, 5), Vector2i(4, 5), Vector2i(6, 3)]:
		D(-3, p.x, p.y, yel)
	D(-3, 5, 4, yel2)
	# ---- 弩臂：两枝嫩绿的花茎(往外弯、往后弯)，梢上各一颗小绒球
	for side2: int in [-1, 1]:
		for xi in range(1, 15):
			var a: float = float(xi) / 15.0
			var yv: int = -24 + int(round(a * a * 6.0))
			var x2: int = xi if side2 > 0 else -1 - xi
			D(x2, yv, 4, st if posmod(xi, 3) != 0 else st2)
			D(x2, yv, 5, st)
			if xi < 6:
				D(x2, yv + 1, 4, st2)
		var tipx: float = 15.5 if side2 > 0 else -16.5
		_g11_ball(tipx, -17.0, 4.5, 1.6, func(_dx: float, _dy: float, dz: float) -> int: return fluff if dz > -0.5 else fluff2, 30)
	B(-2, -25, 3, 1, -23, 5, st2)
	# ---- 弦 + 弦扣
	_g11_string(15, -17, -7, 6, strc, 30)
	B(-1, -8, 6, 0, -7, 7, br3)
	# ---- 弩口的大白绒球：一根短茎托着；冠毛一圈圈(外层白、里层灰白)，正中一点种子的褐色
	B(-1, -29, 7, 0, -26, 8, st2)
	var puff := func(dx: float, dy: float, dz: float) -> int:
		if Vector3(dx, dy, dz).length() < 1.6:
			return seedc
		return fluff if posmod(int(floor((atan2(dz, dx) + dy * 0.4) * 2.5)), 2) == 0 else fluff2
	_g11_ball(-0.5, -32.5, 9.0, 3.6, puff, 45)
	_end()
