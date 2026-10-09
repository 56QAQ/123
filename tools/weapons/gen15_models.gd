extends "res://tools/model_weapons.gd"
## 通用武器 · gen15 的模型(tools/build_kits.gd 按 PARTS 登记)：手枪 3 把(W_ + L_)、手弩 1 把、双匕 2 把(W_ + L_)。
## 枪械约定(同 model_weapons.gd 的 pistol / gen8)：原点 = 握点(拳心)，-Y = 枪口(朝前)，+Z = 上，握把沿 Z 穿过拳心
##   (握把 x -1..0、y -1..2 附近，往下到 z≈-7)；枪身在 z 2..9、y -22..6 附近。
## 手弩(同 crossbow / gen5 / gen11)：弩身 y -27..9、z 2..7，弩臂在 y≈-22 往 ±x 展开(x -14..13)，弦连到弦扣 (0, -7)、z 6。
## 近战(同 dagger / gen13)：+Y = 刃的方向，z = 刃宽，x = 厚度；柄 y -6..2、刃 y 5..~28。
## 双持：右手 W_<大类>_<外观>(挂 Bow)、左手 L_…(挂 Weapon_L，B()/D() 自动左右镜像)。
## 颜色一律写死(VGrid.hexc；不用调色板里会按武器颜色换色的青色系)；每把的主色就是它的武器颜色。
## 刀光长度在 game/view/proj_kinds/gen15.gd 的 TRAILS。
## PARTS：部件名 -> [资源名, 方法名, 参数…]

const PARTS := {
	"W_pistols_g15_cactus": ["wpn_pistols_g15_cactus", "g15_cactus_revolver", false],
	"L_pistols_g15_cactus": ["wpn_pistols_g15_cactus_l", "g15_cactus_revolver", true],
	"W_pistols_g15_boxing": ["wpn_pistols_g15_boxing", "g15_boxing_pistol", false],
	"L_pistols_g15_boxing": ["wpn_pistols_g15_boxing_l", "g15_boxing_pistol", true],
	"W_pistols_g15_magnet": ["wpn_pistols_g15_magnet", "g15_magnet_pistol", false],
	"L_pistols_g15_magnet": ["wpn_pistols_g15_magnet_l", "g15_magnet_pistol", true],
	"W_crossbow_g15_mint": ["wpn_crossbow_g15_mint", "g15_mint_crossbow"],
	"W_dual_g15_heartfire": ["wpn_dual_g15_heartfire", "g15_heartfire_dagger", false],
	"L_dual_g15_heartfire": ["wpn_dual_g15_heartfire_l", "g15_heartfire_dagger", true],
	"W_dual_g15_bat": ["wpn_dual_g15_bat", "g15_bat_dagger", false],
	"L_dual_g15_bat": ["wpn_dual_g15_bat_l", "g15_bat_dagger", true],
}

const G15_HEART_BLADE := [8, 28]
const G15_BAT_BLADE := [5, 26]


## 握把(竖着穿过拳心，z -7..2；下半截往后错一格) + 扳机护圈 + 扳机(同 gen8)
func _g15_grip(gc: int, gc2: int, cap: int, guard: int, trig: int) -> void:
	for z in range(-7, 3):
		var off: int = 1 if z <= -4 else 0
		B(-1, -1 + off, z, 0, 2 + off, z, gc2 if posmod(z, 3) == 0 else gc)
	B(-1, 0, -8, 0, 3, -8, cap)
	B(-1, -6, -1, 0, -6, 1, guard)
	B(-1, -6, -1, 0, -2, -1, guard)
	B(-1, -3, 0, 0, -3, 1, trig)


## 沿 Y 的圆柱段(连续坐标：轴心 (cx, cz)，半径 r)；col(y, ang, d) 给颜色(ang = 截面上的角度，0 = +X、π/2 = +Z；d = 离轴心的距离)
func _g15_rod(y0: int, y1: int, cx: float, cz: float, r: float, col: Callable, glow: int = 0) -> void:
	for y in range(mini(y0, y1), maxi(y0, y1) + 1):
		for x in range(int(floor(cx - r)) - 1, int(ceil(cx + r)) + 2):
			for z in range(int(floor(cz - r)) - 1, int(ceil(cz + r)) + 2):
				var dx: float = float(x) + 0.5 - cx
				var dz: float = float(z) + 0.5 - cz
				var d: float = sqrt(dx * dx + dz * dz)
				if d <= r:
					D(x, y, z, col.call(y, atan2(dz, dx), d), glow)


## 实心球(连续坐标的球心)；col(dx, dy, dz) 给颜色
func _g15_ball(cx: float, cy: float, cz: float, rx: float, ry: float, rz: float, col: Callable, glow: int = 0) -> void:
	for x in range(int(floor(cx - rx)) - 1, int(ceil(cx + rx)) + 1):
		for y in range(int(floor(cy - ry)) - 1, int(ceil(cy + ry)) + 1):
			for z in range(int(floor(cz - rz)) - 1, int(ceil(cz + rz)) + 1):
				var dx: float = (float(x) + 0.5 - cx) / rx
				var dy: float = (float(y) + 0.5 - cy) / ry
				var dz: float = (float(z) + 0.5 - cz) / rz
				if dx * dx + dy * dy + dz * dz <= 1.0:
					D(x, y, z, col.call(dx, dy, dz), glow)


# ====================================================================== 仙人掌双枪(绿 · 手枪 · 4)
## 陶土花盆当枪托：握把是一只倒过来的小陶盆(赭红，盆沿一圈亮一档)，枪身后段是一只横放的陶盆(转轮的位置，盆口朝前)；
## 盆里长出一根柱形仙人掌当枪管(y -21..-2，轴心 z 5.5，半径 2.6)：一道道竖棱(深绿 / 亮绿相间)，棱上一排排淡黄的刺(朝外凸出一格)；
## 枪管中段顶上往上长出一根小分枝(像巨人柱的手臂)当准星；枪口顶着一朵粉花(五瓣 + 黄蕊)。
func g15_cactus_revolver(p_left: bool) -> void:
	_begin(p_left)
	var tc := VGrid.hexc("#c4673a")                        # 陶土
	var tc2 := VGrid.hexc("#e0895a")
	var tc3 := VGrid.hexc("#9a4626")
	var soil := VGrid.hexc("#4a3020")
	var cg := VGrid.hexc("#4f9a3c")                        # 仙人掌
	var cg2 := VGrid.hexc("#78c25a")
	var cg3 := VGrid.hexc("#2f6e2a")
	var sp := VGrid.hexc("#f3e6a8")                        # 刺
	var fl := VGrid.hexc("#ff7fb4")                        # 花
	var fl2 := VGrid.hexc("#ffb3d4")
	var fc := VGrid.hexc("#ffd84a")
	# ---- 握把：倒过来的小陶盆(越往下越宽一点)，盆沿(底下)亮一档；扳机是一根小刺
	for z in range(-7, 3):
		var off: int = 1 if z <= -4 else 0
		var wide: int = 1 if z <= -5 else 0
		B(-1 - wide, -1 + off, z, wide, 2 + off, z, tc3 if posmod(z, 4) == 0 else tc)
	B(-2, -1, -8, 1, 4, -8, tc2)
	B(-1, -6, -1, 0, -6, 1, tc3)
	B(-1, -6, -1, 0, -2, -1, tc3)
	B(-1, -3, 0, 0, -3, 1, sp)
	# ---- 枪身后段：横放的陶盆(y -2..5，盆底在后、盆口朝前)，盆口一圈盆沿；盆口里一圈土
	for y in range(-2, 6):
		var r: float = 3.6 if y <= -1 else 3.2 - float(y) * 0.08
		var rim: bool = y <= -1
		_g15_rod(y, y, -0.5, 5.5, r, func(_y: int, ang: float, _d: float) -> int:
			if rim:
				return tc2
			return tc2 if sin(ang) > 0.55 else (tc3 if sin(ang) < -0.55 else tc))
	_g15_rod(-3, -3, -0.5, 5.5, 2.8, func(_y: int, _a: float, _d: float) -> int: return soil)
	# ---- 枪管：柱形仙人掌(8 道竖棱)，棱上隔几格一根刺(凸出到 r + 1)
	_g15_rod(-21, -3, -0.5, 5.5, 2.6, func(y: int, ang: float, d: float) -> int:
		var rib: int = posmod(int(floor((ang + PI) / TAU * 8.0 + 0.5)), 2)
		if d < 1.6:
			return cg3
		if y <= -20:
			return cg2
		return cg2 if rib == 0 else cg3 if sin(ang) < -0.3 else cg)
	for y2 in range(-19, -3, 3):
		for k in range(8):
			if posmod(k + y2, 2) != 0:
				continue
			var a: float = TAU * float(k) / 8.0 - PI
			var px: int = int(floor(-0.5 + cos(a) * 3.3))
			var pz: int = int(floor(5.5 + sin(a) * 3.3))
			D(px, y2, pz, sp, 20)
	# ---- 准星：枪管中段顶上长出一根小分枝(先往前伸一格，再往上弯)
	B(-1, -12, 8, 0, -10, 9, cg)
	B(-1, -13, 9, 0, -13, 12, cg)
	B(-1, -12, 10, 0, -12, 12, cg2)
	D(-1, -14, 11, sp, 20)
	D(0, -13, 13, sp, 20)
	# ---- 枪口的粉花：五片花瓣(一圈)，正中黄蕊(微光)
	for k2 in range(5):
		var a2: float = TAU * float(k2) / 5.0 + 0.3
		var fx: int = int(floor(-0.5 + cos(a2) * 2.2))
		var fz: int = int(floor(5.5 + sin(a2) * 2.2))
		B(fx, -24, fz, fx, -22, fz, fl if k2 % 2 == 0 else fl2, 10)
		D(int(floor(-0.5 + cos(a2) * 3.2)), -23, int(floor(5.5 + sin(a2) * 3.2)), fl, 10)
		D(int(floor(-0.5 + cos(a2) * 3.9)), -22, int(floor(5.5 + sin(a2) * 3.9)), fl2, 10)
	B(-1, -25, 5, 0, -22, 6, fc, 50)
	_end()


# ====================================================================== 拳套弹簧枪(红 · 手枪 · 3)
## 一把玩具枪：大红的圆鼓鼓枪身(顶上一道黄条、侧面一颗黄星)，粗短的枪管口上顶着一只红拳套(白护腕，侧面一块拇指)，
## 拳套和枪口之间露出一截银弹簧；握把是黑色橡胶 + 黄扳机。
func g15_boxing_pistol(p_left: bool) -> void:
	_begin(p_left)
	var rd := VGrid.hexc("#d8282a")
	var rd2 := VGrid.hexc("#ff5a4a")
	var rd3 := VGrid.hexc("#981a1c")
	var yl := VGrid.hexc("#ffd23a")
	var yl2 := VGrid.hexc("#e0a418")
	var bk := VGrid.hexc("#2a2228")
	var bk2 := VGrid.hexc("#3e343c")
	var wt := VGrid.hexc("#f6f2ea")
	var wt2 := VGrid.hexc("#d6d0c4")
	var sv := VGrid.hexc("#c8ccd4")
	var sv2 := VGrid.hexc("#8a909c")
	_g15_grip(bk, bk2, rd3, yl2, yl)
	# ---- 枪身：圆鼓鼓的红壳(y -9..5)，顶上一道黄条；侧面一颗黄星
	_g15_rod(-9, 5, -0.5, 5.5, 3.3, func(y: int, ang: float, _d: float) -> int:
		if y >= 4:
			return rd3
		if absf(ang - PI * 0.5) < 0.35:
			return yl
		return rd2 if sin(ang) > 0.5 else (rd3 if sin(ang) < -0.5 else rd))
	for sp2: Vector2i in [Vector2i(-3, 6), Vector2i(-4, 5), Vector2i(-2, 5), Vector2i(-3, 5), Vector2i(-3, 4), Vector2i(-4, 3), Vector2i(-2, 3)]:
		D(-4, sp2.x, sp2.y, yl, 10)
		D(3, sp2.x, sp2.y, yl, 10)
	# ---- 枪管：粗短的红管(y -14..-10) + 黄口沿
	_g15_rod(-14, -10, -0.5, 5.5, 2.3, func(_y: int, ang: float, _d: float) -> int: return rd2 if sin(ang) > 0.5 else rd)
	_g15_rod(-15, -15, -0.5, 5.5, 2.6, func(_y: int, _a: float, _d: float) -> int: return yl)
	# ---- 一截银弹簧(y -17..-16)
	for y3 in range(-17, -15):
		_g15_rod(y3, y3, -0.5, 5.5, 1.6, func(yy: int, ang: float, d: float) -> int:
			return sv if (d > 0.9 and posmod(int(floor((ang + PI) / TAU * 6.0)) + yy, 2) == 0) else sv2)
	# ---- 拳套：白护腕(y -19..-18) + 红拳头(压扁的球，y -26..-19) + 侧面一块拇指(+X 那一侧)
	_g15_rod(-19, -18, -0.5, 5.5, 2.6, func(y: int, _a: float, _d: float) -> int: return wt if y == -18 else wt2)
	_g15_ball(-0.5, -22.5, 5.5, 3.4, 3.8, 3.6, func(dx: float, dy: float, dz: float) -> int:
		if dy < -0.75:
			return rd2                                      # 拳面
		return rd2 if dz > 0.5 else (rd3 if dz < -0.55 else rd))
	_g15_ball(2.4, -21.0, 4.5, 1.4, 2.0, 1.4, func(_dx: float, _dy: float, dz: float) -> int: return rd2 if dz > 0.3 else rd)
	# 拳背上的一道白缝线
	for y4 in range(-25, -19):
		D(-1, y4, 9, wt2)
	_end()


# ====================================================================== 磁极双枪(紫 · 手枪 · 4)
## 一只马蹄磁铁当枪身：U 形开口朝前(-Y)，上下两根磁腿(z 2..4 / z 7..9)在枪身后段弯成一道弧连起来；
## 右手那把红漆、左手那把蓝漆(合起来是紫)；两根磁腿的尖头包银；两腿之间(枪口)悬着一团发光的紫色磁力球，
## 外面绕着几点淡紫的磁力线。握把深紫，柄底一颗紫色的灯。
func g15_magnet_pistol(p_left: bool) -> void:
	_begin(p_left)
	var mc := VGrid.hexc("#3a6cf0") if p_left else VGrid.hexc("#e0303c")
	var mc2 := VGrid.hexc("#6c98ff") if p_left else VGrid.hexc("#ff6a6a")
	var mc3 := VGrid.hexc("#2446a8") if p_left else VGrid.hexc("#9e1a26")
	var sv := VGrid.hexc("#d8dce6")
	var sv2 := VGrid.hexc("#9aa0ae")
	var pu := VGrid.hexc("#8a3ce8")
	var pu2 := VGrid.hexc("#c08aff")
	var dk := VGrid.hexc("#2a1a3e")
	var dk2 := VGrid.hexc("#40285c")
	_g15_grip(dk, dk2, dk2, sv2, sv)
	D(-1, 1, -9, pu, 90)
	D(0, 1, -9, pu, 90)
	# ---- 两根磁腿(y -14..-1)：截面 4 × 3(x -2..1)，顶面亮一档、底面暗一档；靠后一圈发光的紫箍
	for leg: Array in [[2, 4], [7, 9]]:
		var z0: int = leg[0]
		var z1: int = leg[1]
		for y in range(-14, 0):
			for z in range(z0, z1 + 1):
				var c: int = mc2 if z == z1 else (mc3 if z == z0 else mc)
				if y == -3 or y == -2:
					c = pu
				B(-2, y, z, 1, y, z, c, 50 if c == pu else 0)
		# 包银的尖头 y -17..-15
		for y2 in range(-17, -14):
			for z2 in range(z0, z1 + 1):
				B(-2, y2, z2, 1, y2, z2, sv if z2 == z1 or y2 == -17 else sv2)
	# ---- 后面的弧：y 0..6 把两腿连起来(半圆，圆心 (y 0, z 5.5)，内半径 1.5、外半径 5)
	for y3 in range(0, 7):
		for z3 in range(0, 12):
			var q := Vector2(float(y3) + 0.5, float(z3) + 0.5 - 5.5)
			var d: float = q.length()
			if d < 1.5 or d > 5.0:
				continue
			var c3: int = mc2 if q.y > 2.2 else (mc3 if q.y < -2.2 else mc)
			B(-2, y3, z3, 1, y3, z3, c3)
	# 两腿之间的银横档(握把正上方，把手连到磁铁上)
	B(-1, -1, 2, 0, 2, 2, sv2)
	# ---- 枪口的磁力球：两腿尖头之间 y -19..-15，发光的紫
	_g15_ball(-0.5, -18.0, 5.5, 1.9, 2.2, 1.7, func(_dx: float, dy: float, dz: float) -> int: return pu2 if (dz > 0.3 or dy < -0.6) else pu, 90)
	# 磁力线：两侧各一道弧，从一条腿的尖头绕到另一条腿的尖头
	for k in range(7):
		var t: float = float(k) / 6.0
		var zz: int = int(round(lerpf(3.0, 8.0, t)))
		var yy: int = -18 - int(round(sin(t * PI) * 3.0))
		D(-3, yy, zz, pu, 60)
		D(2, yy, zz, pu, 60)
	_end()


# ====================================================================== 薄荷手弩(绿 · 手弩 · 3)
## 浅色白桦木的弩身(顶上一道箭槽，两道嫩绿的缎带缠着)，弩托尾巴上插着一大把薄荷枝；
## 弩臂是两根方茎的薄荷(薄荷的茎是方的：深绿)，茎上一对对带锯齿的嫩绿叶子(中间一道深一档的叶脉)，梢头一小串淡紫的薄荷花；
## 弦是近白的淡绿丝；弩身右侧挂着一只圆圆的银色薄荷糖盒(盒盖上一片绿叶)；弩槽里是一片卷起来的薄荷叶当箭，箭头一点发光的清凉的白。
func g15_mint_crossbow() -> void:
	_begin(false)
	var wd := VGrid.hexc("#d8c8a0")                        # 白桦木
	var wd2 := VGrid.hexc("#efe2bc")
	var wd3 := VGrid.hexc("#9a8660")
	var bark := VGrid.hexc("#3a3428")
	var rib := VGrid.hexc("#58c06a")                       # 缎带
	var stem := VGrid.hexc("#3f8a3a")
	var lf := VGrid.hexc("#7ed36a")
	var lf2 := VGrid.hexc("#a8ec8a")
	var vein := VGrid.hexc("#4e9e44")
	var flw := VGrid.hexc("#d8c8f0")
	var strc := VGrid.hexc("#e8f8ea")
	var tin := VGrid.hexc("#c8d0d8")
	var tin2 := VGrid.hexc("#eef2f6")
	var cool := VGrid.hexc("#d8fff4")
	# ---- 握把(白桦：几道深色的树皮纹)
	for z in range(-5, 3):
		B(-1, -1, z, 0, 2, z, bark if posmod(z, 3) == 0 else wd)
	B(-1, -1, -6, 0, 3, -6, wd3)
	B(-1, -5, 0, 0, -5, 2, wd3)
	B(-1, -4, 0, 0, -2, 0, wd3)
	D(-1, -3, 1, stem)
	D(0, -3, 1, stem)
	# ---- 弩身：前段 y -27..-9、中段 -8..6、尾托 3..9(顶面亮一档，零星几道树皮纹)，箭槽
	B(-1, -27, 2, 0, -9, 5, wd)
	B(-1, -27, 6, 0, -9, 6, wd2)
	B(-1, -8, 3, 0, 6, 5, wd)
	B(-1, -8, 6, 0, 6, 6, wd2)
	B(-2, 3, 2, 1, 8, 5, wd)
	B(-2, 3, 6, 1, 8, 6, wd2)
	B(-2, 9, 2, 1, 9, 6, wd3)
	for bk: Vector2i in [Vector2i(-20, 3), Vector2i(-13, 4), Vector2i(-6, 3), Vector2i(5, 4)]:
		D(-1, bk.x, bk.y, bark)
		D(0, bk.x + 1, bk.y, bark)
	B(-1, -27, 7, 0, -10, 7, wd3)
	# 两道缎带
	for ry: int in [-17, 1]:
		B(-2, ry, 1, 1, ry + 1, 7, rib)
	# ---- 弩托尾巴上插着的一把薄荷枝(往后上方张开)
	for k in range(3):
		var dz: int = k - 1
		for i in range(0, 7):
			var yy: int = 10 + i
			var zz: int = 4 + dz * (i / 2) + i / 3
			D(-1 + (k % 2), yy, zz, stem)
			if i >= 2 and i % 2 == 0:
				D(-2 + (k % 2) * 3, yy, zz, lf)
				D(-1 + (k % 2), yy, zz + 1, lf2)
		D(-1 + (k % 2), 17, 4 + dz * 3 + 2, flw, 30)
	# ---- 弩臂：两根方茎的薄荷(往外弯、往后弯)，茎上每隔 3 格一对锯齿叶，梢头一小串淡紫的花
	for side: int in [-1, 1]:
		for xi in range(1, 15):
			var a: float = float(xi) / 15.0
			var yv: int = -23 + int(round(a * a * 6.0))
			var x2: int = xi if side > 0 else -1 - xi
			D(x2, yv, 4, stem)
			D(x2, yv, 5, stem)
			if posmod(xi, 3) == 1 and xi > 1:
				# 一对叶子：一片往前(-Y)、一片往后(+Y)，各 3 格长、中间一道叶脉
				for lk in range(1, 4):
					var c: int = vein if lk == 2 else (lf2 if lk == 3 else lf)
					D(x2, yv - lk, 4 + (1 if lk == 3 else 0), c)
					D(x2, yv + lk, 5 - (1 if lk == 3 else 0), c)
					D(x2 + side, yv - lk + 1, 4, lf)
		var tipx: int = 15 if side > 0 else -16
		B(tipx, -18, 4, tipx, -16, 5, stem)
		for fy in range(-21, -18):
			D(tipx, fy, 4, flw, 25)
			D(tipx, fy, 5, flw, 25)
	B(-2, -24, 3, 1, -22, 5, wd3)
	# ---- 弦 + 弦扣
	for i2 in range(0, 16):
		var t: float = float(i2) / 15.0
		var sx: int = int(round(lerpf(-15.0, -1.0, t)))
		var sy: int = int(round(lerpf(-17.0, -7.0, t)))
		D(sx, sy, 6, strc, 20)
		D(-1 - sx, sy, 6, strc, 20)
	B(-1, -8, 6, 0, -7, 7, wd3)
	# ---- 右侧的圆形薄荷糖盒(银，盒盖上一片绿叶)
	for y3 in range(-15, -8):
		for z3 in range(1, 8):
			var q := Vector2(float(y3) + 0.5 + 11.5, float(z3) + 0.5 - 4.5)
			if q.length() > 3.4:
				continue
			D(1, y3, z3, tin)
			D(2, y3, z3, tin2 if q.length() > 2.6 else (lf if absf(q.x - q.y * 0.6) < 0.9 else tin2))
	# ---- 弩槽里卷起来的薄荷叶(当箭)，箭头一点发光的白
	B(-1, -27, 8, 0, -12, 8, lf)
	B(-1, -26, 9, -1, -14, 9, vein)
	B(-1, -29, 8, 0, -28, 8, cool, 140)
	_end()


# ====================================================================== 心火双刃(红 · 双匕 · 3)
## 一对红刃短刀：护手是一颗金边的心(两瓣心尖朝下、往刃那边鼓)，心里封着一团一跳一跳的火(两面都看得见，发光的橙红)；
## 刃从心的两瓣之间伸出去：深红的刃身、刃口一线亮红、中线一道暗红的血槽，刃尖往上略收成火舌的样子；
## 柄是深红皮革缠金线，柄头一颗小小的金心。
## 刃 y 8..28，心形护手 y -1..11，柄 y -6..0，柄头 y -9..-7。
func g15_heartfire_dagger(p_left: bool) -> void:
	_begin(p_left)
	var rd := VGrid.hexc("#c81e2e")
	var rd2 := VGrid.hexc("#ff7a6a")
	var rd3 := VGrid.hexc("#8a0e1a")
	var au := VGrid.hexc("#d8a53a")
	var au2 := VGrid.hexc("#f6d36a")
	var au3 := VGrid.hexc("#946624")
	var fire := VGrid.hexc("#ff7a28")
	var fire2 := VGrid.hexc("#ffd060")
	var fire3 := VGrid.hexc("#a8141e")
	var lt := VGrid.hexc("#5a1418")
	var heartc := VGrid.hexc("#d8202a")
	# ---- 柄：深红皮革缠金线
	for y in range(-6, 1):
		for x in range(-1, 1):
			for z in range(-1, 1):
				D(x, y, z, au if posmod(y + x - z, 3) == 0 else lt)
	# ---- 柄头：一颗小金心(心尖朝下)
	B(-1, -8, -1, 0, -8, 0, au)
	B(-1, -7, -2, 0, -7, 1, au2)
	D(-1, -9, -1, au3)
	D(0, -9, 0, au3)
	# ---- 心形护手：在 Y-Z 平面上(x -2..1 的厚度)，心尖在 y 1、两瓣在 y 6..9；外面一圈金边，里面是火
	var heart := func(y: int, z: int) -> float:
		# 心形的隐函数(连续坐标)：< 0 在里面
		var hx: float = (float(z) + 0.5) / 5.8
		var hy: float = (float(y) + 0.5 - 5.2) / 5.0
		var q: float = hx * hx + hy * hy - 1.0
		return q * q * q - hx * hx * hy * hy * hy
	for y2 in range(-1, 12):
		for z2 in range(-8, 8):
			var f: float = heart.call(y2, z2)
			if f > 0.0:
				continue
			# 边：周围有一个格子在外面
			var rim := false
			for n: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if heart.call(y2 + n.x, z2 + n.y) > 0.0:
					rim = true
			if rim:
				B(-2, y2, z2, 1, y2, z2, au2 if y2 >= 6 else au)
			else:
				# 心里的火：外圈深红、往里橙、正中一束黄的火苗(往上窜)
				var core: float = absf(float(z2) + 0.5) + maxf(0.0, float(y2) - 5.0) * 0.6
				var cf: int = heartc
				var gw := 30
				if core < 1.3 and y2 >= 1 and y2 <= 7:
					cf = fire2
					gw = 110
				elif core < 2.6 and y2 >= 1:
					cf = fire
					gw = 80
				elif y2 <= 1 or core > 3.8:
					cf = fire3
				B(-2, y2, z2, 1, y2, z2, cf, gw)
	# 心的两面嵌一圈暗金(看得出是"护手里封着火")
	D(-3, 4, -1, au3)
	D(-3, 4, 0, au3)
	D(2, 4, -1, au3)
	D(2, 4, 0, au3)
	# ---- 刃：从心的两瓣之间(y 8)伸出去，到 y 28；越往尖越窄，尖头往 +Z 微微一挑(火舌)
	var y0: int = G15_HEART_BLADE[0]
	var y1: int = G15_HEART_BLADE[1]
	for y3 in range(y0, y1 + 1):
		var t: float = float(y3 - y0) / float(y1 - y0)
		var half: float = lerpf(2.6, 2.9, t / 0.3) if t < 0.3 else lerpf(2.9, 0.5, pow((t - 0.3) / 0.7, 1.2))
		var shift: float = 0.9 * pow(t, 3.0)
		var za: int = int(floor(-half + shift))
		var zb: int = int(ceil(half + shift)) - 1
		for z3 in range(za, zb + 1):
			var c: int = rd
			var gl := 0
			if z3 == za or z3 == zb:
				c = rd2
				gl = 30
			elif absf(float(z3) + 0.5 - shift) < 0.8 and t < 0.8:
				c = rd3
			B(-1, y3, z3, 0, y3, z3, c, gl)
	_end()


# ====================================================================== 蝙蝠双刃(紫 · 双匕 · 2)
## 刃是一片蝙蝠翼：刃背(-Z)是一根直直的翼骨，刃口(+Z)一段段往里凹的扇贝边(翼膜在两根指骨之间凹进去)，
## 紫黑的翼膜上几根浅紫的指骨从刃根往刃口斜着放出去，刃口一线发光的紫；
## 护手上倒挂着一只小蝙蝠(黑紫的身子、一对尖耳、两颗发光的红眼睛，翅膀收着)；柄缠紫布，柄尾一颗白獠牙。
## 刃 y 5..26，护手 y 2..4，柄 y -6..1，柄尾 y -9..-7。
func g15_bat_dagger(p_left: bool) -> void:
	_begin(p_left)
	var mb := VGrid.hexc("#3a1e52")                        # 翼膜
	var mb2 := VGrid.hexc("#5a2e80")
	var bone := VGrid.hexc("#9a6ad0")
	var edge := VGrid.hexc("#c48aff")
	var spine := VGrid.hexc("#2a1838")
	var body := VGrid.hexc("#241430")
	var body2 := VGrid.hexc("#3c2450")
	var eye := VGrid.hexc("#ff3040")
	var cloth := VGrid.hexc("#5a2e80")
	var cloth2 := VGrid.hexc("#2a1838")
	var fang := VGrid.hexc("#f4f0e6")
	# ---- 柄：紫布缠黑
	for y in range(-6, 2):
		for x in range(-1, 1):
			for z in range(-1, 1):
				D(x, y, z, cloth if posmod(y + z, 2) == 0 else cloth2)
	# ---- 柄尾：一颗白獠牙(往下收尖)
	B(-1, -8, -1, 0, -7, 0, fang)
	D(-1, -9, -1, fang)
	# ---- 护手：一根黑紫的横档(z -4..3)，正中倒挂着一只小蝙蝠(脚抓在横档上、头朝下、两面都看得见)
	B(-2, 2, -4, 1, 3, 3, spine)
	B(-1, 4, -4, 0, 4, 3, body2)
	# 小蝙蝠挂在横档下面那一侧(-Y)也太挤：挂在 +Z 那一头的外侧，身子 y -1..2、z 4..5
	B(-2, 0, 4, 1, 2, 5, body)
	B(-2, -1, 4, 1, -1, 5, body2)                          # 头
	D(-2, -2, 4, body)                                      # 尖耳
	D(1, -2, 4, body)
	D(-2, -2, 5, body)
	D(1, -2, 5, body)
	D(-3, -1, 5, eye, 160)                                  # 两面的红眼睛
	D(2, -1, 5, eye, 160)
	B(-2, 1, 6, 1, 2, 6, body2)                             # 收着的翅膀
	# ---- 刃：翼膜(x -1..0)，刃背一根直的翼骨(z 最低那一格)，刃口按扇贝边凹进去
	var y0: int = G15_BAT_BLADE[0]
	var y1: int = G15_BAT_BLADE[1]
	for y2 in range(y0, y1 + 1):
		var t: float = float(y2 - y0) / float(y1 - y0)
		var back: float = -2.0 + t * 1.2                     # 刃背从 z -2 往 +Z 慢慢收
		var front: float = lerpf(4.8, 0.2, pow(t, 1.2))     # 刃口的外包络
		var seg: float = fposmod(float(y2 - y0), 7.0) / 7.0   # 每 7 格一段扇贝
		front -= 2.0 * sin(seg * PI) * (1.0 - t * 0.6)        # 两根指骨之间凹进去
		var za: int = int(floor(back))
		var zb: int = maxi(za, int(ceil(back + maxf(0.6, front - back))) - 1)
		for z2 in range(za, zb + 1):
			var c: int = mb
			var gl := 0
			if z2 == za:
				c = spine
			elif z2 == zb:
				c = edge
				gl = 50
			elif posmod(y2 - y0, 7) == 0 or posmod(y2 - y0 - (z2 - za), 7) == 0:
				c = bone                                          # 指骨：从刃背斜着放到刃口
			elif posmod(y2 + z2, 3) == 0:
				c = mb2
			B(-1, y2, z2, 0, y2, z2, c, gl)
	_end()
