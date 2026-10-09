extends RefCounted
## 武器模型：9 个武器大类 × 外观(plain 朴素的基础武器 / ornate 华丽款 / 个别大类的特殊款)。
## 每把武器都在"武器局部坐标"里雕刻，原点 = 握点(拳心)：
##   近战(剑/长枪/大剑/匕首)：+Y = 刃的方向，z = 刃宽，x = 厚度(与原有长剑、法杖一致)
##   枪械(手弩/手枪/步枪)  ：-Y = 枪口方向(与手指同向)，+Z = 枪的"上方"，握把沿 Z 穿过拳心
##   法器(魔典/水晶球)      ：放在拳头上方(+Z)
## 右手武器挂 "Bow" 骨；双持武器的左手那把挂 "Weapon_L" 骨，并左右镜像(x → -1-x)。
## 例外：变奏节点本人的大三角钢琴(grand_piano → W_focus_grand / W_focus_grand_white)不在手上，整台刚性挂 "Root" 骨、按模型坐标雕在她身前。
## 华丽款的强调色(青色系体素)会被 voxel_unit 着色器按武器颜色换色；朴素款只用木/铁/皮革。
const VGrid = preload("res://tools/vgrid.gd")
const BowModel = preload("res://tools/model_bow.gd")

var g
var rig
var P: Dictionary
var left: bool = false


func _init(grid, p_rig, pal: Dictionary) -> void:
	g = grid
	rig = p_rig
	P = pal


func _c(k: String) -> int:
	return P[k]


func _begin(p_left: bool) -> void:
	left = p_left
	g.sym = false
	g.mode = VGrid.FILL
	g.cur_glow = 0
	g.ty = 44
	g.tz = 3
	if left:
		g.tx = 16
		g.use("Weapon_L")
	else:
		g.tx = -16
		g.use("Bow")


func _end() -> void:
	g.tx = 0
	g.ty = 0
	g.tz = 0
	g.cur_glow = 0


## 武器局部坐标的方块(左手自动镜像)
func B(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, c: int, glow: int = 0) -> void:
	g.cur_glow = glow
	if left:
		g.box(-1 - maxi(x0, x1), y0, z0, -1 - mini(x0, x1), y1, z1, c)
	else:
		g.box(x0, y0, z0, x1, y1, z1, c)
	g.cur_glow = 0


func D(x: int, y: int, z: int, c: int, glow: int = 0) -> void:
	B(x, y, z, x, y, z, c, glow)


## 刃：沿 +Y 从 y0 到 y1，半宽(z 方向)从 w0 收到 w1，末端收成尖；x 厚度 [x0,x1]
func _blade(y0: int, y1: int, w0: float, w1: float, x0: int, x1: int, body: int, edge: int, tip_len: int = 6) -> void:
	for y in range(y0, y1 + 1):
		var t: float = float(y - y0) / maxf(1.0, float(y1 - y0))
		var half: float = lerpf(w0, w1, pow(t, 1.2))
		if y > y1 - tip_len:
			half = lerpf(half, 0.5, float(y - (y1 - tip_len)) / float(tip_len))
		var za: int = int(floor(-half))
		var zb: int = int(ceil(half)) - 1
		for z in range(za, zb + 1):
			B(x0, y, z, x1, y, z, edge if (z == za or z == zb) else body)


# ====================================================================== 单手剑
func sword_plain() -> void:
	_begin(false)
	var leather := _c("leather")
	var iron := _c("iron")
	var iron2 := _c("iron2")
	var iron3 := _c("iron3")
	B(-1, -7, -1, 0, 3, 0, leather)
	for ry: int in [-5, -1, 2]:
		B(-1, ry, -1, 0, ry, 0, _c("leather2"))
	B(-2, -10, -2, 1, -8, 1, iron3)
	B(-2, 4, -6, 1, 5, 5, iron3)
	B(-1, 4, -1, 0, 5, 0, iron)
	_blade(6, 56, 3.6, 1.2, -1, 0, iron, iron2, 7)
	for y in range(9, 42):
		B(-1, y, -1, 0, y, -1, iron3)
	_end()


# ====================================================================== 长枪
func polearm(ornate: bool) -> void:
	_begin(false)
	var shaft1 := _c("black2") if ornate else _c("wood")
	var shaft2 := _c("black") if ornate else _c("wood2")
	for y in range(-38, 61):
		B(-1, y, -1, 0, y, 0, shaft1 if (y % 9) < 6 else shaft2)
	B(-2, -41, -2, 1, -39, 1, _c("gold3") if ornate else _c("iron3"))
	if ornate:
		for ry: int in [-30, -14, 22, 40]:
			B(-2, ry, -2, 1, ry + 1, 1, _c("gold"))
		B(-2, -4, -2, 1, 5, 1, _c("white2"))       # 右手握把缠带
		B(-2, 14, -2, 1, 22, 1, _c("white2"))      # 左手握把缠带
		# 枪头：金色托座 + 月牙翼 + 白刃 + 发光刃芯
		B(-2, 60, -2, 1, 64, 1, _c("gold"))
		for k in range(6):
			B(-1, 62 + k, 2 + k, 0, 63 + k, 2 + k, _c("gold2"))
			B(-1, 62 + k, -3 - k, 0, 63 + k, -3 - k, _c("gold2"))
		_blade(65, 86, 3.4, 1.4, -1, 0, _c("white"), _c("white3"), 8)
		for y in range(67, 82):
			B(-1, y, -1, 0, y, 0, _c("cyan2"), 70)
		# 流苏(静态)：从托座下垂
		for k2 in range(8):
			D(0, 58 - k2, 2, _c("cyan") if k2 > 2 else _c("gold"), 40 if k2 > 2 else 0)
	else:
		B(-2, 60, -2, 1, 63, 1, _c("iron3"))
		_blade(64, 80, 3.0, 1.2, -1, 0, _c("iron"), _c("iron2"), 7)
		B(-2, 12, -2, 1, 13, 1, _c("leather"))
		B(-2, 24, -2, 1, 25, 1, _c("leather"))
	_end()


# ====================================================================== 双手大剑
func heavy(ornate: bool) -> void:
	_begin(false)
	var grip := _c("black2") if ornate else _c("leather")
	B(-1, -16, -1, 0, 3, 0, grip)
	for ry: int in [-13, -8, -3, 1]:
		B(-1, ry, -1, 0, ry, 0, _c("gold3") if ornate else _c("leather2"))
	B(-2, -20, -2, 1, -17, 1, _c("gold") if ornate else _c("iron3"))
	# 护手：宽
	B(-2, 4, -10, 1, 6, 9, _c("gold") if ornate else _c("iron3"))
	B(-2, 7, -11, 1, 7, -10, _c("gold2") if ornate else _c("iron3"))
	B(-2, 7, 9, 1, 7, 10, _c("gold2") if ornate else _c("iron3"))
	if ornate:
		# 黑刃白边 + 刃中发光符文
		_blade(7, 74, 5.6, 2.2, -1, 0, _c("black2"), _c("white"), 10)
		for y in range(8, 70):
			B(-2, y, -1, 1, y, 0, _c("black"))
		for y2 in range(12, 64):
			if (y2 % 7) < 4:
				B(-2, y2, -1, 1, y2, 0, _c("cyan"), 60)
		B(-3, 4, -2, 2, 7, 1, _c("gold2"))
		B(-3, 5, -1, 2, 6, 0, _c("cyan2"), 110)    # 护手宝石
	else:
		_blade(7, 72, 5.2, 2.2, -1, 0, _c("iron"), _c("iron2"), 10)
		for y in range(8, 64):
			B(-2, y, -1, 1, y, 0, _c("iron3"))
	_end()






## 凝血(血嗜节点的专属武器，按用户给的图做，不是人物卡上那把大剑)：一柄结晶的血刃——细长的尖叶形刃身(下三分之一最宽、往上收成长尖)，
## 黑色的外缘、暗红的刃身，刃面上交错着一格格发亮的血纹，刃缘是一节节的锯齿；小小的锯齿护手，暗红缠柄，柄尾一颗发光的血珠。比普通大剑大一号
func clotted_blade() -> void:
	_begin(false)
	var bk := VGrid.hexc("#0b0306")
	var cr := VGrid.hexc("#3d0710")
	var cr2 := VGrid.hexc("#52091a")
	var rd := VGrid.hexc("#d81e2c")
	var rd2 := VGrid.hexc("#ff4a56")
	var wrap := VGrid.hexc("#2a0a0e")
	# 柄 + 血珠柄尾
	for y in range(-19, 4):
		B(-1, y, -1, 0, y, 0, rd if (y + 19) % 5 == 0 else wrap)
	B(-1, -22, -1, 0, -20, 0, rd, 110)
	D(-1, -23, 0, rd2, 130)
	# 锯齿护手
	for z in range(-6, 6):
		var hh: int = 1 + (1 if absf(float(z) + 0.5) > 4.0 else 0)
		B(-2, 4, z, 1, 4 + hh, z, bk if absf(float(z) + 0.5) > 4.5 else cr)
	# 刃身：尖叶形，菱形截面
	var y0 := 7
	var y1 := 94                                       # 握点在 y 44，体素格子到 140：刃最长到这里(普通大剑 74)
	for y in range(y0, y1 + 1):
		var t: float = float(y - y0) / float(y1 - y0)
		var hw: float = lerpf(4.0, 10.5, t / 0.28) if t < 0.28 else lerpf(10.5, 0.4, pow((t - 0.28) / 0.72, 0.9))
		hw += 0.9 * (1.0 if (y % 7) < 3 else 0.0) * (1.0 - t)        # 一节节的锯齿
		for z in range(int(floor(-hw)) - 1, int(ceil(hw)) + 1):
			var az: float = absf(float(z) + 0.5)
			if az > hw:
				continue
			var th: float = 2.4 * (1.0 - az / maxf(0.6, hw)) + 0.6       # 中间厚、刃缘薄
			var edge: bool = az > hw - 1.1 or y > y1 - 2
			for x in range(-3, 3):
				if absf(float(x) + 0.5) > th:
					continue
				var c: int = bk if edge else (cr2 if (x + y + z) % 5 == 0 else cr)
				var gl := 0
				if not edge:
					# 交错的血纹(两组斜线 = 一格格菱形) + 刃中一道
					var v1: float = fmod(float(y) * 0.55 + float(z) + 60.0, 9.0)
					var v2: float = fmod(float(y) * 0.55 - float(z) + 60.0, 9.0)
					if v1 < 1.0 or v2 < 1.0 or (az < 0.8 and t < 0.75):
						c = rd2 if (v1 < 0.5 or v2 < 0.5) else rd
						gl = 90
				B(x, y, z, x, y, z, c, gl)
	_end()

## 大锤(圣战节点的专属武器，双手重)：他角色卡上那把战锤——深棕木长柄 + 几道金箍，柄尾一颗一圈圈棱环的金色柄头；
## 锤头是一大块灰色的石钢方块(面亮、棱暗、倒角)，靠两端各一道凸起的金箍，两个锤面(±Z = 挥动方向)上各一枚凸起的金色日轮十字
## (圆环套十字)；柄插进锤头处一叠金色套箍，柄从锤头另一面穿出一颗金帽。握点在原点、+Y 沿柄，锤头的长边沿 X(竖在挥动面外)。
## 双手握在 y -10..+4(右手 0、左手 -6)：y -10..+5 是和别的大剑一样的 2×2 细柄(藏在两只拳头里)，两头各一道金箍，箍外的柄粗一圈
const WARHAMMER_HEAD := Vector3i(13, 48, 8)      # 锤头：x -13..12、y 48..65、z -8..7(半长 13 / 底 48 / 半厚 8)
const WARHAMMER_LEN := 18


## 一圈截面为 (2hw)×(2hw) 的方环(柄的中心在 x/z = -0.5)，hw ≥ 2 时切掉四个角(看着圆一点)
func _warhammer_disc(y: int, hw: int, c: int, c_side: int = 0) -> void:
	for x in range(-hw, hw):
		for z in range(-hw, hw):
			var ax: float = absf(float(x) + 0.5)
			var az: float = absf(float(z) + 0.5)
			if hw >= 2 and ax > float(hw) - 1.0 and az > float(hw) - 1.0:
				continue
			D(x, y, z, c_side if (c_side != 0 and (x == -hw or z == -hw)) else c)


## 锤头的石纹噪声(0..99)
static func _warhammer_n(x: int, y: int, z: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663) ^ (z * 83492791)) % 100


## 锤面上的日轮十字(凸起一格，贴在 z = zf 那层)：圆环 + 十字(臂端外扩)，中心亮一格
func _warhammer_emblem(zf: int, au: int, au2: int, au3: int) -> void:
	var cy: float = float(WARHAMMER_HEAD.y) + float(WARHAMMER_LEN) * 0.5 - 0.5
	for y in range(WARHAMMER_HEAD.y, WARHAMMER_HEAD.y + WARHAMMER_LEN):
		for x in range(-9, 9):
			var dx: float = float(x) + 0.5
			var dy: float = float(y) - cy
			var r: float = sqrt(dx * dx + dy * dy)
			var ax: float = absf(dx)
			var ay: float = absf(dy)
			var c := 0
			var arm_v: bool = (ax < 1.1 and ay < 8.0) or (ax < 2.1 and ay > 6.9 and ay < 8.0)
			var arm_h: bool = (ay < 1.1 and ax < 8.0) or (ay < 2.1 and ax > 6.9 and ax < 8.0)
			if arm_v or arm_h:
				c = au2 if (ax < 1.1 and ay < 1.1) else au
			elif r > 5.4 and r < 6.6:
				c = au3 if (dx + dy > 3.0) else au                  # 圆环(一侧暗一点 = 立体感)
			if c != 0:
				D(x, y, zf, c)


func warhammer() -> void:
	_begin(false)
	var wd := VGrid.hexc("#5c3621")
	var wd2 := VGrid.hexc("#6f4429")
	var wd3 := VGrid.hexc("#47291a")
	var au := VGrid.hexc("#d1952f")             # 金色和圣战节点身上的金边同一套
	var au2 := VGrid.hexc("#ebbe55")
	var au3 := VGrid.hexc("#986520")
	var hd5 := VGrid.hexc("#aaa9b2")            # 锤头：灰色石钢(面) → 暗灰(棱)
	var hd1 := VGrid.hexc("#9897a2")
	var hd2 := VGrid.hexc("#82818d")
	var hd3 := VGrid.hexc("#686774")
	var hd4 := VGrid.hexc("#53525e")
	var hx: int = WARHAMMER_HEAD.x
	var hy0: int = WARHAMMER_HEAD.y
	var hy1: int = hy0 + WARHAMMER_LEN - 1
	var hz: int = WARHAMMER_HEAD.z
	# 木柄：握持段(y -10..+5)是 2×2，其余是倒角的 4×4；两种棕一节节交替，偶尔一格暗纹
	for y in range(-14, hy0):
		var k: int = (y + 70) % 7
		var c: int = wd2 if k < 2 else wd
		if y >= -10 and y <= 5:
			B(-1, y, -1, 0, y, 0, c)
		else:
			_warhammer_disc(y, 2, c, wd3 if k == 4 else c)
	# 握持段两头的金箍 + 柄上再两道
	for by: int in [-12, 6, 22]:
		_warhammer_disc(by, 3, au)
		_warhammer_disc(by + 1, 3, au2 if by != -12 else au3)
	# 柄尾：金色柄头(一叠带棱的环，末端一颗小钮)
	var pommel := [[-14, 2, au3], [-15, 3, au], [-16, 4, au2], [-17, 3, au3], [-18, 4, au], [-19, 4, au2], [-20, 3, au3], [-21, 2, au]]
	for pr: Array in pommel:
		_warhammer_disc(int(pr[0]), int(pr[1]), int(pr[2]))
	# 套箍：柄插进锤头处的一叠金环，最上面一圈宽边托住锤头
	var collar := [[40, 3, au3], [41, 3, au], [42, 3, au2], [43, 4, au], [44, 3, au3], [45, 4, au2], [46, 4, au], [47, 5, au3]]
	for cr: Array in collar:
		_warhammer_disc(int(cr[0]), int(cr[1]), int(cr[2]))
	# 锤头：倒角方块；锤面(±Z)中间一块更亮的面板，棱是暗灰，石纹噪声
	for y2 in range(hy0, hy1 + 1):
		for x2 in range(-hx, hx):
			for z2 in range(-hz, hz):
				var ex: int = mini(x2 + hx, hx - 1 - x2)
				var ey: int = mini(y2 - hy0, hy1 - y2)
				var ez: int = mini(z2 + hz, hz - 1 - z2)
				var n0: int = (1 if ex == 0 else 0) + (1 if ey == 0 else 0) + (1 if ez == 0 else 0)
				if n0 >= 2:
					continue                                   # 倒角：切掉 12 条棱
				var n1: int = (1 if ex <= 1 else 0) + (1 if ey <= 1 else 0) + (1 if ez <= 1 else 0)
				var nz: int = _warhammer_n(x2, y2, z2)
				var c2: int = hd2
				if n1 >= 2:
					c2 = hd4 if nz < 30 else hd3
				elif ez == 0:
					if ex >= 4 and ey >= 2:
						c2 = hd5 if nz < 18 else hd1
					else:
						c2 = hd3 if nz < 25 else hd2
				elif nz < 22:
					c2 = hd3 if nz < 8 else hd1
				D(x2, y2, z2, c2)
	# 两道凸起的金箍(绕锤头一圈，外凸一格，四角切掉)
	for bx: int in [-hx + 2, hx - 4]:
		for x3 in range(bx, bx + 2):
			for y3 in range(hy0 - 1, hy1 + 2):
				for z3 in range(-hz - 1, hz + 1):
					var oy: bool = y3 < hy0 or y3 > hy1
					var oz: bool = z3 < -hz or z3 > hz - 1
					if oy and oz:
						continue
					if y3 > hy0 and y3 < hy1 and z3 > -hz and z3 < hz - 1:
						continue
					var outer: bool = (x3 == bx) == (bx < 0)
					D(x3, y3, z3, au2 if outer else au)
	# 锤面上的日轮十字(两面)
	_warhammer_emblem(-hz - 1, au, au2, au3)
	_warhammer_emblem(hz, au, au2, au3)
	# 柄从锤头另一面穿出的金帽
	_warhammer_disc(hy1 + 1, 4, au)
	_warhammer_disc(hy1 + 2, 3, au2)
	_warhammer_disc(hy1 + 3, 1, au3)
	_end()

## 杀(无我节点的专属武器，双手重)：她角色卡上那把大太刀。墨绿柄卷(两面各一排金色菱形)、金色柄头垂一串金框白珠 + 墨绿流苏，
## 金边黑底的木瓜形刀镡；刀身很长、带弧度(刃口朝 +Z，刀尖往刀背 -Z 弯)：黑钢的刀背与平地 → 起伏的淡紫刃纹 → 银白刃口(微微发光)，
## 刀铓上方缠着几簇紫色的诅咒纹(和她手脚上的一样)。平时连鞘一起挥(drawn = false：黑漆刀鞘，金色鞘口 / 两道金箍 / 金色鞘尾，
## 鞘口下方一个栗形穿着墨绿下绪)，特殊战斗才拔刀(drawn = true)。
## 握点在原点、+Y 沿刀身：柄 y -21..2(双手握在 y -10..+4：右手 0、左手 -6；柄 2 厚 × 4 宽)，柄头 -25..-22，
## 刀镡 3..5，刀铓 7..9，刀身 10..94(普通大剑 7..72、凝血 7..94)，鞘 7..96
const ODACHI_BLADE := [10, 94]
const ODACHI_SORI := 17.0                  # 刀尖往刀背一侧(-Z)弯出的格数
const ODACHI_SAYA_END := 96                # 体素格子的顶(握点 y 44 + 96 = 140)


func odachi(drawn: bool) -> void:
	_begin(false)
	_odachi_hilt()
	if drawn:
		_odachi_blade()
	else:
		_odachi_saya()
	_end()


## 第 y 行刀身的 z 范围(x = 刀背，y = 刃口)：宽 7 收到 5，整条往 -Z 弯(弯在刀身中后段，像真刀的反り)
static func _odachi_span(y: int) -> Vector2i:
	var t: float = clampf(float(y - ODACHI_BLADE[0]) / float(ODACHI_BLADE[1] - ODACHI_BLADE[0]), 0.0, 1.05)
	var za: int = int(round(-3.0 - ODACHI_SORI * pow(t, 1.8)))
	var w: int = int(round(lerpf(7.0, 5.0, minf(t, 1.0))))
	return Vector2i(za, za + w - 1)


## 一层倒角的矩形(x0..x1 × z0..z1，切掉四个角)
func _odachi_ring(y: int, x0: int, x1: int, z0: int, z1: int, c: int, glow: int = 0) -> void:
	for x in range(x0, x1 + 1):
		for z in range(z0, z1 + 1):
			if (x == x0 or x == x1) and (z == z0 or z == z1):
				continue
			D(x, y, z, c, glow)


## 柄 + 柄头 + 刀镡 + 切羽 + 柄头的穗子(拔不拔刀都一样)
func _odachi_hilt() -> void:
	var gn := VGrid.hexc("#34483a")          # 墨绿和她的和服同一套
	var gn2 := VGrid.hexc("#26362b")
	var au := VGrid.hexc("#c4893a")          # 金色和她身上的金饰同一套
	var au2 := VGrid.hexc("#e0ac58")
	var au3 := VGrid.hexc("#8e5f26")
	var bk := VGrid.hexc("#24222a")
	var bk2 := VGrid.hexc("#18161c")
	var gn3 := VGrid.hexc("#405644")
	# 柄：墨绿柄卷(两种绿斜着交错)；两个平面(±X)每 5 格露一颗金色菱形(上亮下暗)，菱形之间柄卷交叉处亮一点
	for y in range(-21, 2):
		var k: int = (y + 40) % 5
		for z in range(-2, 2):
			for x in range(-1, 1):
				var c: int = gn if (y + z + 40) % 2 == 0 else gn2
				var inner: bool = z == -1 or z == 0
				if inner and k == 2:
					c = au2
				elif inner and k == 1:
					c = au
				elif not inner and k == 4:
					c = gn3
				D(x, y, z, c)
	# 柄口的金箍(縁)
	_odachi_ring(2, -2, 1, -3, 2, au)
	# 柄头(金)：比柄大一圈，底面正中一个暗色的穿绳孔
	_odachi_ring(-22, -2, 1, -3, 2, au3)
	_odachi_ring(-23, -2, 1, -3, 2, au)
	_odachi_ring(-24, -2, 1, -3, 2, au2)
	B(-1, -25, -2, 0, -25, 1, au)
	B(-1, -25, -1, 0, -25, 0, bk2)
	_odachi_tsuba(au, au2, au3, bk)
	# 切羽(刀镡上面一片暗金垫片)
	_odachi_ring(6, -2, 1, -4, 4, au3)
	_odachi_tassel()


## 刀镡(y 3..5)：木瓜形(四瓣，对角处往里收)，金边黑底，黑底上四颗金色透雕点，中间金色的切羽座
func _odachi_tsuba(au: int, au2: int, au3: int, bk: int) -> void:
	for x in range(-5, 5):
		for z in range(-7, 7):
			var dx: float = (float(x) + 0.5) / 4.7
			var dz: float = (float(z) + 0.5) / 6.6
			var r: float = sqrt(dx * dx + dz * dz)
			var ph: float = atan2(dz, dx)
			var rim: float = 1.0 - 0.10 * (1.0 - absf(cos(2.0 * ph)))
			if r > rim:
				continue
			var c: int = bk
			var c_top: int = bk
			if r > rim - 0.26:
				c = au
				c_top = au2 if r > rim - 0.13 else au
			elif x >= -2 and x <= 1 and z >= -3 and z <= 2:
				c = au3
				c_top = au3
			elif absf(r - 0.58) < 0.14 and absf(cos(2.0 * ph)) < 0.4:
				c = au
				c_top = au
			D(x, 4, z, c)
			D(x, 5, z, c_top)
			# 靠柄一侧再垫一层小一圈的(刀镡看着厚一点)
			if r <= rim - 0.12:
				D(x, 3, z, au3 if (r > rim - 0.34 or (x >= -2 and x <= 1 and z >= -3 and z <= 2)) else bk)


## 柄头垂下的穗子：金环 → 嵌白珠的金框 → 金环 → 金帽 → 墨绿流苏。从柄头底面出一格，再往"柄尾方向(-Y)与刃口一侧(+Z)之间"斜着垂：
## 待机时刃口朝下、柄尾朝上，扛着跑 / 举刀时柄尾朝下——斜 50° 左右在这几个姿势里都大致是往下或往旁边垂，不会竖着往上翘
func _odachi_tassel() -> void:
	var au := VGrid.hexc("#c4893a")
	var au2 := VGrid.hexc("#e0ac58")
	var au3 := VGrid.hexc("#8e5f26")
	var gn := VGrid.hexc("#34483a")
	var gn2 := VGrid.hexc("#26362b")
	var gn3 := VGrid.hexc("#405644")
	var pearl := VGrid.hexc("#efe9dd")
	var pearl2 := VGrid.hexc("#cfc6b6")
	B(-1, -26, -1, 0, -26, 0, au3)
	var o := Vector3(0.0, -26.0, 0.0)
	var d := Vector3(0.0, -0.6, 0.8).normalized()
	var sd := Vector3(0.0, d.z, -d.y)
	for y in range(-40, -26):
		for z in range(-4, 21):
			for x in range(-2, 2):
				var p := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - o
				var s: float = p.dot(d)
				var v: float = p.dot(sd)
				var ax: float = absf(p.x)
				if s < 0.0:
					continue
				var c := 0
				if s < 1.6:
					if absf(v) < 0.8 and ax < 1.0:
						c = au3
				elif s < 5.4:
					var m: float = maxf(absf(s - 3.5), absf(v))
					if ax < 1.0:
						if m < 0.95:
							c = pearl if s < 3.6 else pearl2
						elif m < 1.95:
							c = au
				elif s < 6.6:
					if absf(v) < 0.8 and ax < 1.0:
						c = au3
				elif s < 8.4:
					if absf(v) < 1.6 and ax < 1.6:
						c = au2 if s < 7.5 else au
				elif s < 17.5:
					var rr: float = lerpf(1.5, 2.3, (s - 8.4) / 9.1)
					if absf(v) < rr and ax < rr - 0.2:
						c = gn if int(floor(v + 10.0)) % 2 == 0 else gn2
						if s > 15.8:
							c = gn3
				if c != 0:
					D(x, y, z, c)


## 出鞘的刀身(+ 金色刀铓)
func _odachi_blade() -> void:
	var mune := VGrid.hexc("#1d1a20")       # 刀背
	var ji := VGrid.hexc("#38343b")         # 平地(黑钢)
	var ji2 := VGrid.hexc("#2f2b32")
	var shin := VGrid.hexc("#4a4550")       # 鎬筋(刀背旁一道亮棱)
	var nioi := VGrid.hexc("#9d8cab")       # 刃纹(淡紫，黑钢和银白之间的过渡)
	var ha := VGrid.hexc("#d4cada")         # 刃(银白)
	var ha2 := VGrid.hexc("#f4f1f6")        # 刃口
	var cu := VGrid.hexc("#5a2a7a")         # 诅咒紫(和她手脚上的诅咒纹同一套)
	var cu2 := VGrid.hexc("#7a3ea0")
	var cu4 := VGrid.hexc("#a070c8")
	var au := VGrid.hexc("#c4893a")
	var au2 := VGrid.hexc("#e0ac58")
	var au3 := VGrid.hexc("#8e5f26")
	var y0: int = ODACHI_BLADE[0]
	var y1: int = ODACHI_BLADE[1]
	# 刀铓(金)：包住刀身根部
	var s0: Vector2i = _odachi_span(y0)
	_odachi_ring(7, -2, 1, s0.x - 1, s0.y + 1, au3)
	_odachi_ring(8, -2, 1, s0.x - 1, s0.y + 1, au)
	_odachi_ring(9, -2, 1, s0.x - 1, s0.y + 1, au2)
	var kis := 11                            # 切先(刀尖)的长度
	for y in range(y0, y1 + 1):
		var sp: Vector2i = _odachi_span(y)
		var za: int = sp.x
		var zb: int = sp.y
		var w: int = zb - za + 1
		if y > y1 - kis:
			# 切先：刀背一直通到尖上，刃口一侧沿外凸的弧收过去
			var u: float = float(y - (y1 - kis)) / float(kis)
			zb = za + int(round(float(w - 1) * sqrt(maxf(0.0, 1.0 - u * u))))
		# 亮的一侧(刃)约占四成宽，刃纹缓缓起伏(湾れ)；黑的一侧占一半多(人物卡上刀背黑、刃口亮)
		var lw: int = mini(maxi(2, int(round(float(w) * 0.40 + 0.6 * sin(float(y) * 0.33)))), zb - za)
		for z in range(za, zb + 1):
			var e: int = zb - z
			for x in range(-1, 1):
				var c: int = ji2 if (y * 3 + z * 5 + x) % 7 == 0 else ji
				var gl := 0
				if e == 0:
					c = ha2
					gl = 25
				elif e < lw - 1:
					c = ha
				elif e == lw - 1:
					c = nioi
				elif z == za:
					c = mune
				elif z == za + 1:
					c = shin
				# 诅咒纹：从刀铓往上窜的几缕细细的紫色火苗(只在黑的那一侧，两面错开)
				var dy: int = y - y0
				if e >= lw and z > za and dy < 12:
					var fh: int = [7, 0, 4, 10, 0, 5, 0, 8, 3][(z - za + (x + 1) * 4 + 90) % 9]
					if dy < fh:
						c = cu2 if dy < 2 else cu
						if dy == fh - 1 and fh >= 7:
							c = cu4
							gl = 45
				D(x, y, z, c, gl)


## 刀鞘(连鞘挥的那一版)：黑漆，刀背一侧一道漆面高光；金色鞘口 / 两道金箍 / 金色鞘尾，鞘口下方栗形 + 墨绿下绪(缠两道，垂一截)
func _odachi_saya() -> void:
	var lac := VGrid.hexc("#24222a")        # 黑漆
	var lac2 := VGrid.hexc("#38333f")       # 漆面高光
	var lac3 := VGrid.hexc("#16141a")
	var au := VGrid.hexc("#c4893a")
	var au2 := VGrid.hexc("#e0ac58")
	var au3 := VGrid.hexc("#8e5f26")
	var gn := VGrid.hexc("#34483a")
	var gn2 := VGrid.hexc("#26362b")
	var gn3 := VGrid.hexc("#405644")
	var ye: int = ODACHI_SAYA_END
	for y in range(7, ye + 1):
		var sp: Vector2i = _odachi_span(y)
		var za: int = sp.x - 1
		var zb: int = sp.y + 1
		if y == ye:
			za += 1
			zb -= 1
		for x in range(-2, 2):
			for z in range(za, zb + 1):
				if (x == -2 or x == 1) and (z == za or z == zb):
					continue
				var c: int = lac
				if y <= 9:
					c = [au, au2, au3][y - 7]                          # 鞘口
				elif y >= ye - 5:
					c = au3 if y == ye - 5 else (au2 if z == za + 1 else au)   # 鞘尾
				elif y == 38 or y == 39 or y == 66 or y == 67:
					c = au2 if (y == 38 or y == 66) else au                 # 两道金箍
				elif z == za or (z == za + 1 and (x == -2 or x == 1)):
					c = lac2                                                # 刀背一侧的漆面高光
				elif z == zb:
					c = lac3
				D(x, y, z, c)
	# 栗形(穿下绪的小钮)：+X 面上、鞘口下面一个黑漆小钮，钮面上一道暗金的鵐目
	var s1: Vector2i = _odachi_span(16)
	var zm: int = (s1.x + s1.y) / 2
	B(2, 14, zm - 1, 2, 18, zm, lac2)
	B(3, 15, zm - 1, 3, 17, zm, lac2)
	B(3, 16, zm - 1, 3, 16, zm, au3)
	# 下绪：从栗形顺着鞘往下，绕鞘两道(墨绿斜纹)，再从刃口一侧斜着垂下一截(和柄头穗子同一个方向)，末端一个小穗
	B(2, 19, zm - 1, 2, 20, zm, gn)
	for yb: int in [21, 22, 25, 26]:
		var s2: Vector2i = _odachi_span(yb)
		var za2: int = s2.x - 2
		var zb2: int = s2.y + 2
		for x2 in range(-3, 3):
			for z2 in range(za2, zb2 + 1):
				var edge_x: bool = x2 == -3 or x2 == 2
				var edge_z: bool = z2 == za2 or z2 == zb2
				if edge_x and edge_z:
					continue
				if edge_x or edge_z:
					D(x2, yb, z2, gn if (x2 + z2 + yb) % 2 == 0 else gn2)
	B(2, 23, zm, 2, 24, zm + 1, gn2)
	var s3: Vector2i = _odachi_span(25)
	var yk := 0
	var zk := 0
	for k in range(0, 10):
		yk = 25 - int(round(float(k) * 0.6))
		zk = s3.y + 3 + int(round(float(k) * 0.8))
		B(-1, yk - 1, zk, 0, yk, zk, gn if k % 2 == 0 else gn2)
	B(-2, yk - 2, zk + 1, 1, yk - 1, zk + 1, au)
	for k2 in range(0, 4):
		B(-2, yk - 3 - k2, zk + 1 + k2, 1, yk - 2 - k2, zk + 2 + k2, gn3 if k2 == 3 else (gn if k2 % 2 == 0 else gn2))


## 旧香炉(调香节点的法器)：她角色卡上那只青铜香炉——圈足、鼓腹(四面各一朵白花)、金色口沿、两只环耳各垂一条青色流苏，
## 镂空的穹顶盖子(一圈圈小孔)，盖顶一颗金色宝珠尖；盖子上冒着几缕淡青色的烟。法器放在拳头上方(+Z)
func censer() -> void:
	_begin(false)
	var br := VGrid.hexc("#b5803e")
	var br2 := VGrid.hexc("#8a5a26")
	var br3 := VGrid.hexc("#dba65a")
	var au := _c("gold")
	var au2 := _c("gold2")
	var wh := VGrid.hexc("#f6efe0")
	var tl := VGrid.hexc("#2fb3a8")
	var tl2 := VGrid.hexc("#1f8c84")
	var hole := VGrid.hexc("#2a1a10")
	var smoke := VGrid.hexc("#bff3ec")
	var cx := -0.5
	var cy := -0.5
	for z in range(1, 27):
		for y in range(-11, 11):
			for x in range(-11, 11):
				var dx: float = float(x) + 0.5 - cx
				var dy: float = float(y) + 0.5 - cy
				var rr: float = sqrt(dx * dx + dy * dy)
				var zf: float = float(z) + 0.5
				var c := 0
				var gl := 0
				if zf < 3.5 and rr < 3.6:
					c = br2 if zf < 2.5 else br                         # 圈足
				elif zf >= 3.5 and zf < 12.5:
					var k: float = (zf - 8.0) / 4.8
					var rad: float = 6.6 * sqrt(maxf(0.0, 1.0 - k * k * 0.85))
					if rr <= rad and rr > rad - 1.6:
						c = br3 if dy > 3.0 and (x + y + z) % 3 == 0 else br     # 鼓腹(一侧亮一点)
						if zf < 5.5:
							c = br2
						# 四面各一朵白花(金色花心)
						var ang: float = atan2(dy, dx)
						for fa: float in [0.0, PI * 0.5, PI, PI * 1.5]:
							var da: float = absf(wrapf(ang - fa, -PI, PI)) * rad
							var dz: float = zf - 8.5
							var fr: float = sqrt(da * da + dz * dz)
							if fr < 2.6:
								c = au2 if fr < 0.9 else wh
				elif zf >= 12.5 and zf < 13.5 and rr < 6.6 and rr > 4.6:
					c = au                                                # 金色口沿
				elif zf >= 13.5 and zf < 19.5:
					var k2: float = (zf - 13.5) / 6.0
					var rad2: float = 5.8 * sqrt(maxf(0.0, 1.0 - k2 * k2))
					if rr <= rad2 and rr > rad2 - 1.3:
						var ang2: float = atan2(dy, dx)
						var ring: int = int(floor(zf - 13.5))
						# 镂空：两圈小孔(错开)
						if (ring == 1 or ring == 3) and fmod(ang2 / (PI / 5.0) + (0.5 if ring == 3 else 0.0) + 20.0, 1.0) < 0.35:
							c = hole
							gl = 20
						else:
							c = br if ring < 4 else br3
				elif zf >= 19.5 and zf < 21.5 and rr < 1.6:
					c = au                                                # 宝珠
				elif zf >= 21.5 and zf < 23.5 and rr < 0.8:
					c = au2                                               # 尖
				if c != 0:
					D(x, y, z, c, gl)
	# 环耳 + 流苏(从耳朵垂下来：-Z 是下)
	for sx: int in [-8, 7]:
		for z2 in range(8, 14):
			D(sx, -1, z2, au if z2 == 8 or z2 == 13 else br3)
		D(sx + (1 if sx < 0 else -1), -1, 13, au)
		D(sx, -1, 7, au2)
		for z3 in range(1, 7):
			for oy: int in [-2, -1, 0]:
				D(sx, oy, z3, tl if (z3 + oy) % 3 != 0 else tl2, 10)
	# 几缕青烟(静止的，淡淡发光)
	for k3 in range(10):
		var zz: int = 23 + k3
		var ox: int = int(round(sin(float(k3) * 0.8) * 2.0))
		D(ox, 0, zz, smoke, 70 - k3 * 5)
		if k3 % 3 == 1:
			D(ox - 1, 0, zz, smoke, 50)
	_end()

## 无声琴(心音节点的鲁特琴)：深色梨形琴身(背面是一条条琴肋拼成的圆背)，浅色面板上一个深色音孔 + 花纹，面板一圈金边镶着蓝 / 紫宝石，
## 黑色指板 + 金色品丝的琴颈，往后折的琴头上一排金色弦轴，四根银弦。
## 琴的局部坐标：u 沿琴颈(朝琴头为正)，v 琴宽，w 面板法线(正 = 面板那面)；原点 = 琴颈和琴身的交界。
## 当拉弦远程武器拿(W_bow_lute)：握在琴颈中段，琴身朝下、面板朝前；演奏时(P_bard_lute)挂在胸口斜抱着(琴颈朝右上)
func lute() -> void:
	_begin(false)
	_lute_voxels(Vector3(0.0, -9.0, 0.0), Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1))
	_end()


const LUTE_U := Vector3(-0.87, 0.48, 0.06)       # 演奏时琴颈的方向(胸腔局部)：朝右上
const LUTE_W0 := Vector3(0.05, 0.3, 1.0)          # 面板大致朝前、略朝上
const LUTE_BODY := Vector3(3.0, 53.0, 10.5)       # 琴身中心(音孔在它往琴颈方向 2 格)


func lute_prop() -> void:
	g.sym = false
	g.mode = VGrid.FILL
	g.cur_glow = 0
	g.tx = 0
	g.ty = 0
	g.tz = 0
	g.use("Chest")
	var U := LUTE_U.normalized()
	var W := (LUTE_W0 - U * LUTE_W0.dot(U)).normalized()
	var V := W.cross(U).normalized()
	_lute_voxels(LUTE_BODY + U * 13.0, U, V, W)
	g.cur_glow = 0


func _lute_voxels(o: Vector3, U: Vector3, V: Vector3, W: Vector3) -> void:
	var lo := Vector3(1e9, 1e9, 1e9)
	var hi := Vector3(-1e9, -1e9, -1e9)
	for cu: float in [-27.0, 32.0]:
		for cv: float in [-12.0, 12.0]:
			for cw: float in [-10.0, 5.0]:
				var pw: Vector3 = o + U * cu + V * cv + W * cw
				lo = Vector3(minf(lo.x, pw.x), minf(lo.y, pw.y), minf(lo.z, pw.z))
				hi = Vector3(maxf(hi.x, pw.x), maxf(hi.y, pw.y), maxf(hi.z, pw.z))
	for z in range(int(floor(lo.z)), int(ceil(hi.z)) + 1):
		for y in range(int(floor(lo.y)), int(ceil(hi.y)) + 1):
			for x in range(int(floor(lo.x)), int(ceil(hi.x)) + 1):
				var q: Vector3 = Vector3(x + 0.5, y + 0.5, z + 0.5) - o
				var r: Array = _lute_col(q.dot(U), q.dot(V), q.dot(W))
				if r.is_empty():
					continue
				g.cur_glow = int(r[1])
				g.put(x, y, z, int(r[0]))
	g.cur_glow = 0


## 琴身的半宽(t = 0 琴底 … 1 接琴颈)：梨形，下宽上窄
static func _lute_half(t: float) -> float:
	if t <= 0.0 or t >= 1.0:
		return 0.0
	return maxf(2.2, 10.5 * pow(sin(PI * pow(t, 0.72)), 0.8))


## 一点在琴上的颜色：[颜色, 发光]；不在琴上返回 []
func _lute_col(u: float, v: float, w: float) -> Array:
	var wood := VGrid.hexc("#6a3a1e")
	var wood2 := VGrid.hexc("#55301a")
	var board := VGrid.hexc("#c8955a")
	var board2 := VGrid.hexc("#b07d46")
	var hole := VGrid.hexc("#24160e")
	var neck := VGrid.hexc("#4a2a18")
	var ebony := VGrid.hexc("#22160f")
	var au := _c("gold")
	var au2 := _c("gold2")
	var silver := VGrid.hexc("#e6e8ef")
	var gem_b := VGrid.hexc("#4fb3e6")
	var gem_p := VGrid.hexc("#a06ae0")
	# 琴身：u ∈ [-26, 0]
	if u >= -26.0 and u <= 0.5:
		var t: float = (u + 26.0) / 26.0
		var hw: float = _lute_half(t)
		if absf(v) <= hw:
			var k: float = clampf(1.0 - pow(absf(v) / maxf(0.01, hw), 2.0), 0.0, 1.0)
			var depth: float = 6.5 * sqrt(k) * pow(sin(PI * clampf(t, 0.0, 1.0)), 0.5)
			# 面板(w ∈ [0, 1])
			if w >= -0.3 and w <= 1.0:
				var edge: float = hw - absf(v)
				if edge < 1.3:
					# 金边：每隔一段一颗宝石
					var ph: float = fmod(u + 30.0 + absf(v) * 0.3, 5.0)
					if ph < 1.1:
						return [gem_b if int(floor((u + 30.0) / 5.0)) % 2 == 0 else gem_p, 70]
					return [au if edge > 0.5 else au2, 0]
				var dh: float = Vector2(u + 11.0, v).length()
				if dh < 3.4:
					return [hole, 0]
				if dh < 4.4:
					return [au if fmod(atan2(v, u + 11.0) * 4.0 + 20.0, 1.0) < 0.5 else board2, 0]
				if u > -21.5 and u < -19.5 and absf(v) < 4.0:
					return [ebony, 0]                    # 琴码
				return [board2 if fmod(v + 20.0, 2.0) < 0.35 else board, 0]
			# 圆背：一条条琴肋
			if w < 0.0 and w >= -depth:
				var rib: float = fmod(atan2(v, -w) * 3.2 + 10.0, 1.0)
				return [wood2 if rib < 0.22 else wood, 0]
	# 琴颈：u ∈ [0, 22]
	if u >= 0.0 and u <= 22.0 and absf(v) <= 2.2:
		if w > 1.0 and w <= 2.0:
			if absf(v) <= 0.9:
				return [silver, 20]                                                    # 琴弦(一束)
			return []
		if w >= 0.0 and w <= 1.0:
			return [au2 if fmod(u, 3.0) < 0.6 else ebony, 0]                             # 指板 + 金品丝
		if w >= -2.6 and w < 0.0:
			return [neck, 0]
	# 面板上的琴弦(琴码 → 琴颈)
	if u >= -20.5 and u < 0.0 and w > 1.0 and w <= 2.0 and absf(v) <= 0.9:
		return [silver, 20]
	# 琴头：往后折(w 往负方向斜)，两侧金色弦轴
	if u > 22.0 and u <= 31.0:
		var cw: float = -(u - 22.0) * 0.75 - 0.6
		if absf(v) <= 2.0 and absf(w - cw) <= 1.4:
			return [au if u > 30.0 else neck, 0]
		for pu: float in [24.5, 27.0, 29.5]:
			if absf(u - pu) < 0.8 and absf(absf(v) - 3.0) < 1.0 and absf(w - cw) < 0.9:
				return [au2, 0]
	return []

## 熔岩薙刀(龙的余烬的武器，怪物自己的武器外观 W_polearm_ember_glaive)：黑柄缠赤红绳、金箍，金色翼形刀镡，
## 往前弯的单刃大刀头(黑色刃身 + 一道发光的熔岩刃口)，刀背燃着一排火舌，柄尾一枚金色尖镦
func ember_glaive() -> void:
	_begin(false)
	var bk := VGrid.hexc("#16141a")
	var bk2 := VGrid.hexc("#2a2630")
	var rd := VGrid.hexc("#8e1c24")
	var au := VGrid.hexc("#d4a240")
	var au2 := VGrid.hexc("#f2cf72")
	var l1 := VGrid.hexc("#ff4a12")
	var l2 := VGrid.hexc("#ff8a1e")
	var l3 := VGrid.hexc("#ffd35a")
	# 长柄：黑，两段缠赤红绳(握把)，几道金箍
	for y in range(-38, 61):
		var c: int = bk if (y % 8) < 6 else bk2
		if (y > -6 and y < 6) or (y > 14 and y < 24):
			c = rd if (y % 2) == 0 else bk
		B(-1, y, -1, 0, y, 0, c)
	for ry: int in [-30, -6, 6, 14, 24, 44]:
		B(-2, ry, -2, 1, ry, 1, au)
	# 柄尾金镦(尖)
	B(-2, -41, -2, 1, -39, 1, au)
	B(-1, -44, -1, 0, -42, 0, au2)
	# 金色翼形刀镡：两边往上翘
	B(-2, 59, -3, 1, 62, 2, au)
	for k in range(5):
		B(-1, 60 + k, 3 + k, 0, 61 + k, 3 + k, au2 if k == 4 else au)
		B(-1, 60 + k, -4 - k, 0, 61 + k, -4 - k, au2 if k == 4 else au)
	B(-2, 60, -1, 1, 61, 0, l1, 90)                  # 刀镡上一颗熔岩宝石
	# 刀头：往 +z(刃口一侧)弯的单刃，刃身黑、刃口熔岩
	for y in range(63, 97):
		var t: float = float(y - 63) / 33.0
		var bend: float = 9.0 * t * t                  # 刀尖往前弯
		var w: float = lerpf(3.2, 4.6, minf(1.0, t * 2.0))
		if t > 0.65:
			w = lerpf(4.6, 0.6, (t - 0.65) / 0.35)
		var back_z: int = int(floor(-1.5 + bend * 0.6))
		var edge_z: int = int(floor(-1.5 + bend + w))
		for z in range(back_z, edge_z + 1):
			var c2: int = bk2 if z == back_z else bk
			var gl := 0
			if z >= edge_z - 1:
				c2 = l3 if z == edge_z else l2
				gl = 120 if z == edge_z else 90
			elif z == edge_z - 2 and (y % 3) != 0:
				c2 = l1
				gl = 60
			B(-1, y, z, 0, y, z, c2, gl)
	# 刀背的火舌：几簇往后上方飘的火
	for f: int in [66, 73, 80, 87]:
		var t2: float = float(f - 63) / 33.0
		var bz: int = int(floor(-1.5 + 9.0 * t2 * t2 * 0.6)) - 1
		for k2 in range(5):
			var col: int = l3 if k2 < 1 else (l2 if k2 < 3 else l1)
			D(0, f + k2, bz - (k2 >> 1), col, 110 - k2 * 15)
			if k2 < 3:
				D(-1, f + k2, bz - (k2 >> 1), col, 100 - k2 * 15)
	_end()

## 黑剑(守誓节点的专属武器)：他角色卡上那把血色大剑——黑红色的宽刃 + 发光的鲜红刃口与血色纹路，蝠翼形状往上翘、带尖刺的护手，
## 缠黑红绳的长柄，柄头是一颗红色的尖刺星形饰件
func blood_greatsword() -> void:
	_begin(false)
	var bk := VGrid.hexc("#1c0d10")
	var bk2 := VGrid.hexc("#2c1116")
	var bk3 := VGrid.hexc("#3c1419")
	var rd := VGrid.hexc("#d81e2c")
	var rd2 := VGrid.hexc("#ff4a52")
	var rd3 := VGrid.hexc("#8c1220")
	var wrap := VGrid.hexc("#5a1018")
	# 柄：黑柄缠暗红绳(斜纹)
	for y in range(-17, 4):
		B(-1, y, -1, 0, y, 0, wrap if ((y + 17) % 3) == 0 else bk2)
	# 柄头：红色尖刺星(四面尖刺 + 往下的一根长刺)
	B(-2, -21, -2, 1, -18, 1, rd3)
	B(-1, -20, -1, 0, -19, 0, rd, 80)
	for sp: Vector3i in [Vector3i(0, -20, -4), Vector3i(0, -20, 3), Vector3i(-4, -20, 0), Vector3i(3, -20, 0)]:
		B(mini(sp.x, -1), sp.y, mini(sp.z, -1), maxi(sp.x, 0), sp.y, maxi(sp.z, 0), rd)
	B(-1, -25, -1, 0, -22, 0, rd)
	D(0, -26, 0, rd2, 70)
	# 护手：中间一块黑底红纹的厚块，两边蝠翼一样往上翘、末端尖刺
	B(-2, 3, -4, 1, 7, 3, bk)
	B(-3, 4, -2, 2, 6, 1, rd3)
	B(-3, 5, -1, 2, 5, 0, rd, 100)
	for side: int in [-1, 1]:
		for i in range(12):
			var z: int = side * (4 + i)
			var y0: int = 3 + int(round(pow(float(i) / 11.0, 1.6) * 9.0))
			B(-2 if i < 6 else -1, y0, z, 1 if i < 6 else 0, y0 + 3, z, bk2 if i < 8 else rd3)
			B(-1, y0 + 1, z, 0, y0 + 1, z, rd3 if i < 8 else rd, 0 if i < 8 else 60)       # 翼面上一道红纹
			if i % 3 == 1:
				D(0, y0 + 4, z, rd)
		B(-1, 13, side * 15, 0, 16, side * 15, rd)                    # 翼尖的尖刺
		D(0, 17, side * 16, rd2, 70)
		B(-1, 0, side * 7, 0, 2, side * 7, rd3)                         # 往下的小钩
		D(0, -1, side * 8, rd)
	# 刃：宽而厚的黑红刃，靠护手处有两对缺口尖刺；鲜红发光的刃口，中间一道血色纹路(两面都有)
	var y0b := 8
	var y1b := 80
	for y2 in range(y0b, y1b + 1):
		var t: float = float(y2 - y0b) / float(y1b - y0b)
		var half: float = lerpf(6.6, 3.2, pow(t, 1.1))
		if y2 > y1b - 12:
			half = lerpf(half, 0.5, float(y2 - (y1b - 12)) / 12.0)
		var za: int = int(floor(-half))
		var zb: int = int(ceil(half)) - 1
		for z2 in range(za, zb + 1):
			var c: int = bk if ((y2 + z2) % 5) != 0 else bk3
			var g2 := 0
			if z2 == za or z2 == zb:
				c = rd
				g2 = 90
			elif z2 == za + 1 or z2 == zb - 1:
				c = rd3
			B(-1, y2, z2, 0, y2, z2, c, g2)
		# 刃脊(加厚一格)
		if y2 < y1b - 10:
			B(-2, y2, -1, 1, y2, 0, bk2)
		# 护手上方的缺口尖刺
		if y2 == 14 or y2 == 22:
			B(-1, y2, za - 2, 0, y2 + 1, za - 1, rd3)
			B(-1, y2, zb + 1, 0, y2 + 1, zb + 2, rd3)
	# 血色纹路：中线上的折线 + 往两边分叉的枝杈(像血管)，发光
	var zc := 0.0
	for y3 in range(y0b + 3, y1b - 10):
		zc = clampf(zc + [0.0, 0.7, -0.6, 0.4, -0.8, 0.5][y3 % 6], -1.5, 1.5)
		var zi: int = int(round(zc))
		B(-2, y3, zi, 1, y3, zi, rd if (y3 % 4) != 0 else rd2, 90)
		if y3 % 9 == 0:
			var dirz: int = 1 if (y3 / 9) % 2 == 0 else -1
			for k in range(1, 4):
				B(-2, y3 + k, zi + dirz * k, 1, y3 + k, zi + dirz * k, rd, 70)
	_end()


# ====================================================================== 匕首(双持)
func dagger(ornate: bool, p_left: bool) -> void:
	_begin(p_left)
	B(-1, -5, -1, 0, 2, 0, _c("black2") if ornate else _c("leather"))
	B(-2, -7, -2, 1, -6, 1, _c("gold") if ornate else _c("iron3"))
	B(-2, 3, -4, 1, 4, 3, _c("gold") if ornate else _c("iron3"))
	if ornate:
		_blade(5, 25, 2.6, 1.2, -1, 0, _c("white"), _c("white3"), 6)
		for y in range(7, 21):
			B(-1, y, -1, 0, y, -1, _c("cyan2"), 70)
		D(-1, 3, 4, _c("cyan"), 60)
		D(-1, 3, -5, _c("cyan"), 60)
	else:
		_blade(5, 23, 2.4, 1.0, -1, 0, _c("iron"), _c("iron2"), 6)
	_end()


## 硬质手杖(和星节点的专属双手长武器)：他角色卡上那根木杖——扭结的深棕木杖身，一根绿藤螺旋缠着往上爬、隔一段冒片叶子，
## 杖身中段缠一圈蓝布；杖顶往一侧弯出一个螺旋卷，卷口下方嵌着金色菱形框的蓝宝石，下面垂着金色星星挂坠 + 蓝水晶。长柄武器约定：+Y 沿杖身，握点在原点
func cane() -> void:
	_begin(false)
	var wd := VGrid.hexc("#6e4326")
	var wd2 := VGrid.hexc("#53301b")
	var wd3 := VGrid.hexc("#8a5832")
	var vine := VGrid.hexc("#3f7a34")
	var leaf := VGrid.hexc("#5aa043")
	var leaf2 := VGrid.hexc("#8cc85c")
	var cloth := VGrid.hexc("#4f6fb8")
	var cloth2 := VGrid.hexc("#3a5594")
	var au := _c("gold")
	var au2 := _c("gold2")
	var sap := VGrid.hexc("#2f62d6")
	var sap2 := VGrid.hexc("#7fb0ff")
	# 杖身：微微扭动的木棍(横向偏移随高度慢慢变)，木纹深浅交替；杖尾粗一点
	for y in range(-42, 62):
		var ox: int = int(round(0.8 * sin(float(y) * 0.11)))
		var oz: int = int(round(0.8 * cos(float(y) * 0.08)))
		var c: int = wd if (y % 6) < 4 else (wd2 if (y % 12) < 6 else wd3)
		B(-1 + ox, y, -1 + oz, ox, y, oz, c)
		if y < -36:
			B(-2 + ox, y, -2 + oz, 1 + ox, y, 1 + oz, wd2)
	# 中段一圈蓝布
	for y2 in range(6, 15):
		var ox2: int = int(round(0.8 * sin(float(y2) * 0.11)))
		var oz2: int = int(round(0.8 * cos(float(y2) * 0.08)))
		B(-2 + ox2, y2, -2 + oz2, 1 + ox2, y2, 1 + oz2, cloth if (y2 % 3) != 0 else cloth2)
	# 绿藤螺旋往上缠，隔一段冒片叶子
	for y3 in range(-30, 60):
		if y3 >= 5 and y3 <= 15:
			continue
		var a: float = float(y3) * 0.35
		var ox3: int = int(round(0.8 * sin(float(y3) * 0.11)))
		var oz3: int = int(round(0.8 * cos(float(y3) * 0.08)))
		var vx: int = int(round(cos(a) * 1.9)) + ox3
		var vz: int = int(round(sin(a) * 1.9)) + oz3
		D(vx, y3, vz, vine)
		if (y3 % 13) == 0:
			var lx: int = int(round(cos(a) * 3.2)) + ox3
			var lz: int = int(round(sin(a) * 3.2)) + oz3
			B(mini(lx, vx), y3, mini(lz, vz), maxi(lx, vx), y3 + 1, maxi(lz, vz), leaf)
			D(lx, y3 + 2, lz, leaf2)
	# 杖顶：往 +Z 一侧弯出螺旋卷
	var cx := 0.0
	var cy := 70.0
	for k in range(0, 70):
		var t: float = float(k) / 69.0
		var ang: float = PI * 1.0 - t * PI * 3.2
		var r: float = 8.5 * (1.0 - 0.75 * t)
		var py: int = int(round(cy + sin(ang) * r))
		var pz: int = int(round(4.0 + cos(ang) * r))
		B(-1, py, pz, 0, py, pz, wd if k % 5 != 0 else wd3)
	# 杖身顶端接到卷口
	B(-1, 61, -1, 0, 63, 0, wd)
	# 卷口两片叶子
	B(-1, 74, 10, 0, 75, 12, leaf)
	B(-1, 66, -5, 0, 67, -3, leaf2)
	# 金色菱形框的蓝宝石(嵌在卷口下方)
	for k2 in range(-3, 4):
		var w2: int = 3 - absi(k2)
		B(-1, 56 + k2, 3 - w2, 0, 56 + k2, 3 + w2, au if absi(k2) == 3 or w2 == 0 else au2)
	B(-2, 55, 2, 1, 57, 4, sap)
	D(-2, 57, 3, sap2, 80)
	D(1, 57, 3, sap2, 80)
	# 挂坠：金链 → 金色小星星 → 蓝水晶
	for y4 in range(49, 54):
		D(0, y4, 6, au2 if (y4 % 2) == 0 else au)
	B(0, 46, 5, 0, 48, 7, au)
	B(0, 47, 4, 0, 47, 8, au)
	B(0, 41, 6, 0, 45, 6, sap)
	D(0, 43, 6, sap2, 60)
	_end()


## 流星爆魔杖(灾星节点的专属双手长武器，她当法杖用)：按她的配色——黑漆杖身 + 金色箍与雕花，杖首是金色的爪形框，
## 托着一颗大晶石(强调色：红色武器就是火红，发光)，晶石里一点白热的核；杖首下挂一枚紫水晶坠子(她裙子上的紫)，杖尾金色尖头。
## 长柄武器约定：+Y 沿杖身，握点在原点
func meteor_staff() -> void:
	_begin(false)
	var lac := VGrid.hexc("#1d1a26")
	var lac2 := VGrid.hexc("#2c2838")
	var au := _c("gold")
	var au2 := _c("gold2")
	var au3 := _c("gold3")
	var vio := VGrid.hexc("#7a3fc8")
	var vio2 := VGrid.hexc("#b07cf0")
	# 杖身(黑漆，隔一段一道金箍)
	for y in range(-40, 58):
		B(-1, y, -1, 0, y, 0, lac if (y % 9) != 0 else lac2)
	for yb: int in [-30, -6, 12, 34, 50]:
		B(-2, yb, -2, 1, yb + 1, 1, au3)
	# 杖尾金色尖头
	B(-2, -43, -2, 1, -41, 1, au)
	B(-1, -46, -1, 0, -44, 0, au2)
	# 杖首：金色的爪形框(四根往外弯、再往里扣的爪)托着晶石
	B(-2, 56, -2, 1, 59, 1, au)
	for cl: Array in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
		var dx: int = cl[0]
		var dz: int = cl[1]
		for k in range(0, 13):
			var out: float = 3.5 * sin(PI * float(k) / 12.0) + 1.0
			var px: int = int(round(dx * out))
			var pz: int = int(round(dz * out))
			B(px - (1 if dx == 0 else 0), 59 + k, pz - (1 if dz == 0 else 0), px, 59 + k, pz, au if k % 4 != 3 else au2)
		B(dx * 2, 72, dz * 2, dx * 2, 73, dz * 2, au2)
	# 大晶石(双锥形，强调色发光)，里面一点白热的核
	for y2 in range(61, 72):
		var t: float = float(y2 - 61) / 10.0
		var rr: float = 3.2 * sin(PI * t)
		for x in range(-4, 5):
			for z in range(-4, 5):
				if absf(float(x) + 0.5) + absf(float(z) + 0.5) <= rr + 0.6:
					var core: bool = absf(float(x) + 0.5) + absf(float(z) + 0.5) <= rr * 0.45
					B(x, y2, z, x, y2, z, _c("cyanw") if core else (_c("cyan") if (x + z + y2) % 3 != 0 else _c("cyan2")), 150 if core else 70)
	# 紫水晶坠子(挂在杖首下面一侧)
	for y3 in range(52, 57):
		D(3, y3, 0, au3)
	B(2, 49, -1, 4, 51, 0, vio)
	D(3, 48, 0, vio2, 50)
	_end()


## 舞扇(舞星节点的专属双持)：按她的配色做的一对折扇——天蓝的丝绸扇面(折痕一深一浅)、金色扇骨与外缘金边、
## 靠外一圈金色细带上点着蓝宝石，扇柄收拢成金色，轴心嵌一颗蓝宝石，下面垂着金线 + 金铃流苏。
## 扇面在 Y-Z 平面里从握点(轴心)展开 ±72°，半径 25 格；厚 1 格(沿 X)。左手那把自动镜像
func fan(p_left: bool) -> void:
	_begin(p_left)
	var silk := VGrid.hexc("#9fd3ef")
	var silk2 := VGrid.hexc("#c8e9fa")
	var silk3 := VGrid.hexc("#7fbfe3")
	var au := _c("gold")
	var au2 := _c("gold2")
	var au3 := _c("gold3")
	var sap := VGrid.hexc("#2f5fd0")
	var sap2 := VGrid.hexc("#6f9cff")
	var rmax := 25.0
	for y in range(-2, 27):
		for z in range(-26, 27):
			var r: float = sqrt(float(y * y + z * z))
			if r > rmax + 0.5 or r < 1.5:
				continue
			var a: float = rad_to_deg(atan2(float(z), float(y)))
			if absf(a) > 72.0:
				continue
			var c: int
			if r > rmax - 1.0:
				c = au                                            # 外缘金边
			elif r < 7.0:
				c = au3 if (int(floor((a + 72.0) / 12.0)) % 2) == 0 else au   # 扇柄一截：收拢的金色扇骨
			elif absf(fmod(a + 72.0, 12.0)) < 1.2:
				c = au2                                           # 扇骨
			elif r > rmax - 4.0 and r < rmax - 2.0:
				c = sap2 if (int(round(a)) % 18) == 0 else au3    # 金色细带 + 蓝宝石点
			else:
				c = silk if (int(floor((a + 72.0) / 6.0)) % 2) == 0 else silk2   # 折痕一深一浅
				if r > rmax - 2.0:
					c = silk3
			B(0, y, z, 0, y, z, c)
	# 两侧最外那根大骨加厚一点(拿着更像扇子)
	for s: int in [-1, 1]:
		for rr in range(2, int(rmax)):
			var ang: float = deg_to_rad(72.0) * float(s)
			var yy: int = int(round(cos(ang) * float(rr)))
			var zz: int = int(round(sin(ang) * float(rr)))
			B(-1, yy, zz, 0, yy, zz, au3)
	# 轴心蓝宝石 + 垂下的金线金铃
	B(-2, 0, 0, 1, 1, 1, sap)
	D(-2, 1, 0, sap2, 60)
	for y2 in range(-7, -1):
		B(0, y2, 0, 0, y2, 0, au if (y2 % 2) == 0 else au3)
	B(-1, -10, -1, 0, -8, 1, au2)
	D(0, -11, 0, sap, 40)
	_end()


## 狼双刃(狂猎节点的专属双持)：他角色卡上的那对狼牙刀——炭黑的宽刃，刃口一侧是一排银色锯齿、刀背一条银线，
## 刃身中间一道发光的红色裂纹(带几条分叉)，护手是带尖刺的银色星形饰件、中心嵌红宝石，木柄缠着深色皮绳，柄尾垂一束红流苏。
## 刃沿 +Y，刃宽沿 Z(锯齿在 +Z 一侧)，厚度沿 X；左手那把自动镜像
## 闪烁刀刃(清扫节点的专属双持近战)：她角色卡上那对飞刀——叶形的银色双刃(中脊深一点、刃口亮)，银色菱形护手嵌红宝石，
## 黑色缠柄(隔几格一道银箍)，柄尾一个中空的银色菱形环。刃沿 +Y，握点在原点
func blink_knife(p_left: bool) -> void:
	_begin(p_left)
	var sil := VGrid.hexc("#d3d8e0")
	var sil2 := VGrid.hexc("#f2f4f8")
	var sil3 := VGrid.hexc("#8f96a3")
	var blk := VGrid.hexc("#26232b")
	var blk2 := VGrid.hexc("#3a3640")
	var red := VGrid.hexc("#d81f34")
	var red2 := VGrid.hexc("#ff6074")
	# 缠柄
	for y in range(-8, 2):
		B(-1, y, -1, 0, y, 0, sil3 if (y + 8) % 4 == 3 else (blk2 if (y % 2) == 0 else blk))
	B(-1, -9, -1, 0, -9, 0, sil3)
	# 柄尾的菱形环(中空)
	for pt: Vector2i in [Vector2i(-1, -10), Vector2i(0, -10), Vector2i(-2, -11), Vector2i(1, -11), Vector2i(-3, -12), Vector2i(2, -12),
			Vector2i(-2, -13), Vector2i(1, -13), Vector2i(-1, -14), Vector2i(0, -14)]:
		B(-1, pt.y, pt.x, 0, pt.y, pt.x, sil)
	# 护手：银色菱形框，两面各嵌一颗红宝石
	for y2 in range(2, 7):
		var hw: int = 3 - absi(y2 - 4)
		B(-2, y2, -hw - 1, 1, y2, hw, sil if absi(y2 - 4) < 2 else sil3)
	B(-3, 3, -1, 2, 5, 0, red, 80)
	D(-3, 4, -1, red2, 110)
	D(2, 4, 0, red2, 110)
	# 刃：叶形双刃(先变宽、再收成尖)，中脊深一点，两侧刃口亮
	var y0 := 7
	var y1 := 32
	for y3 in range(y0, y1 + 1):
		var t: float = float(y3 - y0) / float(y1 - y0)
		var half: float = 1.6 + 1.3 * sin(minf(1.0, t / 0.55) * PI * 0.5)
		if t > 0.55:
			half = lerpf(2.9, 0.5, pow((t - 0.55) / 0.45, 1.3))
		var za: int = int(floor(-half))
		var zb: int = int(ceil(half)) - 1
		for z in range(za, zb + 1):
			B(-1, y3, z, 0, y3, z, sil2 if (z == za or z == zb) else (sil3 if (z == -1 or z == 0) else sil))
	_end()


func wolf_blade(p_left: bool) -> void:
	_begin(p_left)
	var ch := VGrid.hexc("#2f2b2e")
	var ch2 := VGrid.hexc("#3d383b")
	var ch3 := VGrid.hexc("#242124")
	var sil := VGrid.hexc("#c9ccd2")
	var sil2 := VGrid.hexc("#e8eaee")
	var sil3 := VGrid.hexc("#8d9099")
	var red := VGrid.hexc("#e5332a")
	var red2 := VGrid.hexc("#ff6a4a")
	var wd := VGrid.hexc("#6b4128")
	var wd2 := VGrid.hexc("#4a2c1a")
	var tas := VGrid.hexc("#c3322f")
	var tas2 := VGrid.hexc("#8e1f22")
	# 柄：木柄 + 斜缠的皮绳，柄尾银箍
	for y in range(-8, 3):
		B(-1, y, -1, 0, y, 0, wd2 if ((y + 8) % 3) == 0 else wd)
	B(-2, -10, -2, 1, -9, 1, sil3)
	D(-1, -11, -1, sil)
	# 柄尾垂下的红流苏(沿 -Y 往下，末端散开)
	for y2 in range(-17, -11):
		B(-1, y2, 0, 0, y2, 0, tas if (y2 % 2) == 0 else tas2)
	B(-1, -18, -1, 0, -18, 1, tas2)
	B(-1, -19, -1, -1, -19, -1, tas)
	B(0, -19, 1, 0, -19, 1, tas)
	# 护手：带尖刺的银色星形饰件，中心红宝石
	B(-2, 3, -4, 1, 5, 4, sil)
	B(-2, 4, -6, 1, 4, 6, sil3)
	for sp: Vector3i in [Vector3i(0, 6, -3), Vector3i(0, 6, 3), Vector3i(0, 2, -3), Vector3i(0, 2, 3), Vector3i(0, 4, -7), Vector3i(0, 4, 7)]:
		B(-1, sp.y, sp.z, 0, sp.y, sp.z, sil2)
	B(-3, 4, 0, -3, 4, 0, red, 90)
	B(2, 4, 0, 2, 4, 0, red, 90)
	# 刃：从护手往外变宽，末段斜切出刀尖；+Z 一侧是锯齿刃口，-Z 一侧是银色刀背
	var y0 := 7
	var y1 := 43
	for y3 in range(y0, y1 + 1):
		var t: float = float(y3 - y0) / float(y1 - y0)
		var lo: float = -2.5 - 1.2 * t                       # 刀背(-Z)
		var hi: float = 3.0 + 4.6 * sin(minf(1.0, t * 1.2) * PI * 0.5)      # 刃口(+Z)，越往外越宽(砍刀一样的宽刃)
		if y3 > y1 - 11:                                      # 刀尖：刃口一侧斜切回刀背
			var k: float = float(y3 - (y1 - 11)) / 11.0
			hi = lerpf(hi, lo + 0.5, k)
		var za: int = int(floor(lo))
		var zb: int = int(ceil(hi))
		for z in range(za, zb + 1):
			var c: int = ch if ((y3 + z) % 5) != 0 else ch2
			if z == za:
				c = sil3
			elif z == zb:
				c = sil
			elif z == zb - 1 and (y3 % 3) == 0:
				c = sil3
			B(-1, y3, z, 0, y3, z, c)
		# 锯齿：每 3 格往外凸一颗
		if (y3 % 3) == 1 and y3 < y1 - 3:
			B(-1, y3, zb + 1, 0, y3, zb + 1, sil2)
	# 刃身中间的红色裂纹(发光)：一条折线 + 几条分叉，两面都有
	var zc: float = 0.8
	var pts: Array = []
	for y4 in range(y0 + 2, y1 - 5):
		zc += [0.0, 0.8, -0.7, 0.5, -0.9, 0.6][y4 % 6] + 0.06
		zc = clampf(zc, -0.5, 4.0)
		pts.append(Vector2i(y4, int(round(zc))))
	for pt: Vector2i in pts:
		B(-1, pt.x, pt.y, 0, pt.x, pt.y, red if (pt.x % 4) != 0 else red2, 80)
	for br: Array in [[15, 1, 1], [23, -1, -1], [30, 1, 1], [35, -1, 1]]:
		var by: int = br[0]
		var bz: int = pts[by - (y0 + 2)].y
		for s in range(1, 4):
			B(-1, by + s * int(br[2]), bz + s * int(br[1]), 0, by + s * int(br[2]), bz + s * int(br[1]), red, 60)
	_end()


# ====================================================================== 枪械通用：握把 + 扳机护圈
func _gun_grip(ornate: bool) -> void:
	var gc := _c("black2") if ornate else _c("wood")
	B(-1, -1, -4, 0, 2, 3, gc)
	B(-1, 3, -3, 0, 3, 3, gc)
	B(-1, -1, -5, 0, 3, -5, _c("gold") if ornate else _c("iron3"))
	# 扳机护圈
	B(-1, -5, 1, 0, -5, 3, _c("iron3") if not ornate else _c("gold3"))
	B(-1, -4, 1, 0, -2, 1, _c("iron3") if not ornate else _c("gold3"))
	D(-1, -3, 2, _c("iron2"))


# ====================================================================== 手枪(双持)
func pistol(ornate: bool, p_left: bool) -> void:
	_begin(p_left)
	_gun_grip(ornate)
	if ornate:
		B(-1, -6, 3, 0, 5, 6, _c("white"))
		B(-1, -21, 4, 0, -7, 5, _c("white2"))
		for ry: int in [-8, -14, -20]:
			B(-2, ry, 3, 1, ry, 6, _c("gold"))
		for y in range(-19, 3):
			D(-1, y, 6, _c("cyan"), 60)
		B(-1, -22, 4, 0, -22, 5, _c("cyan2"), 120)
		B(-1, 6, 5, 0, 7, 7, _c("gold2"))
	else:
		B(-1, -5, 3, 0, 4, 6, _c("iron3"))
		B(-1, -19, 4, 0, -6, 5, _c("iron"))
		B(-2, -20, 3, 1, -20, 6, _c("iron3"))
		B(-1, 5, 5, 0, 6, 7, _c("iron3"))
	_end()


## 丰收(耕植节点的专属长柄武器)：她角色卡上的钉耙——木柄 + 铁箍、深铁色 Y 形耙架、一排 8 根微弯的耙齿，耙架上挂着一片小叶子。
## 长柄武器约定：+Y 沿柄，握点在原点；刃宽方向(局部 +Z)在枪平举时朝下 → 耙齿沿 +Z，横梁沿 X
func rake() -> void:
	_begin(false)
	var wd := VGrid.hexc("#8b5834")
	var wd2 := VGrid.hexc("#6b4128")
	var wd3 := VGrid.hexc("#a86a3c")
	var fe := VGrid.hexc("#5a5d66")
	var fe2 := VGrid.hexc("#747884")
	var fe3 := VGrid.hexc("#3c3e45")
	var lf := VGrid.hexc("#4aa83a")
	var lf2 := VGrid.hexc("#86d05a")
	# 木柄(带木纹)、尾端铁箍
	for y in range(-38, 61):
		B(-1, y, -1, 0, y, 0, wd if (y % 7) < 5 else (wd2 if (y % 14) < 7 else wd3))
	B(-2, -41, -2, 1, -39, 1, fe3)
	B(-2, 57, -2, 1, 59, 1, fe)
	# Y 形耙架
	for y2 in range(60, 67):
		var k: int = y2 - 60
		B(-1 - k, y2, -1, -k, y2, 0, fe if k < 5 else fe2)
		B(k - 1, y2, -1, k, y2, 0, fe if k < 5 else fe2)
	# 横梁
	B(-13, 67, -1, 12, 68, 0, fe2)
	B(-13, 67, -1, 12, 67, -1, fe3)
	# 8 根耙齿：沿 +Z 伸出去，末端往柄的方向弯一格
	for tx in range(-12, 12, 3):
		for z in range(1, 8):
			var yy: int = 67 if z < 6 else 66
			B(tx, yy, z, tx, yy, z, fe if z < 6 else fe3)
	# 耙架上挂的小叶子(细绳 + 两色叶片)
	B(3, 60, 1, 3, 61, 1, wd2)
	for pt: Vector3i in [Vector3i(3, 59, 2), Vector3i(3, 58, 2), Vector3i(4, 58, 2), Vector3i(3, 57, 2), Vector3i(4, 57, 2), Vector3i(3, 56, 2)]:
		B(pt.x, pt.y, pt.z, pt.x, pt.y, pt.z, lf2 if pt.x == 4 else lf)
	_end()


## 咒语笔记(求知节点的专属法器)：她角色卡上那本法典，摊开托在拳头上——藏青封面 + 金色包边、书页微微拱起，
## 页面上是蓝墨水的笔记(有一行被红笔划掉：念错的咒语)，左页浮着一个发光的雪花符印(强调色，随武器颜色换色)；
## 封底(朝下)是金色雪花纹章；书脊下端垂着金链、蓝水晶和金十字。法器约定：书放在拳头上方(+Z)，书脊沿 Y
func notes() -> void:
	_begin(false)
	var navy := VGrid.hexc("#1f2b62")
	var navy2 := VGrid.hexc("#2c3d85")
	var navy3 := VGrid.hexc("#141c44")
	var au := _c("gold")
	var au2 := _c("gold2")
	var au3 := _c("gold3")
	var pg := _c("paper")
	var pg2 := _c("paper2")
	var ink := VGrid.hexc("#4257ad")
	var red := VGrid.hexc("#c23a35")
	var y0 := -12
	var y1 := 5
	# 两片封面(右 +x、左 -x)：从书脊往外微微翘起成 V 字；最外一圈是金色包边，里面一圈藏青露在书页外
	for side: int in [1, -1]:
		for i in range(1, 12):
			var x: int = i if side > 0 else -1 - i
			var zc: int = 3 + (i - 1) / 4
			for y in range(y0 - 1, y1 + 2):
				var edge: bool = i == 11 or y == y0 - 1 or y == y1 + 1
				var c: int = au if edge else navy
				# 封底的金色雪花纹章(被书页盖住，只有从下面看得到)
				var ex: int = i - 6
				var ey: int = y - (y0 + y1) / 2
				if not edge and ((ex == 0 and absi(ey) <= 4) or (ey == 0 and absi(ex) <= 3) or (absi(ex) == absi(ey) and absi(ex) <= 2)):
					c = au2
				B(x, y, zc, x, y, zc, c)
	# 书脊(藏青，两道金箍)
	B(-1, y0 - 1, 2, 0, y1 + 1, 3, navy3)
	for yb: int in [y0 + 1, y1 - 1]:
		B(-1, yb, 2, 0, yb, 2, au3)
	# 书页：每边 9 格宽，中间拱起、贴近书脊处压下去；翻口一侧画出页边的层次
	for side2: int in [1, -1]:
		for i2 in range(1, 10):
			var x2: int = i2 if side2 > 0 else -1 - i2
			var zc2: int = 3 + (i2 - 1) / 4
			var bump: int = 0 if i2 == 1 else (1 if i2 == 2 or i2 >= 8 else 2)
			var ztop: int = zc2 + 1 + bump
			for y2 in range(y0 + 1, y1):
				for z2 in range(zc2 + 1, ztop + 1):
					var cc: int = pg
					if i2 == 9 or y2 == y0 + 1 or y2 == y1 - 1:
						cc = pg2 if (z2 % 2) == 0 else pg
					B(x2, y2, z2, x2, y2, z2, cc)
			# 页面上的笔记：蓝墨水写的几行字(一段一段的"词"，行距留白)；左页中间留给符印
			var words: Dictionary = {-9: [[2, 3], [6, 2]], -6: [[2, 2], [5, 3]], -1: [[2, 4], [7, 1]], 2: [[3, 3]]} if side2 > 0 \
				else {-9: [[2, 2], [5, 3]], 3: [[2, 3], [6, 2]]}
			for row: int in words.keys():
				for wd: Array in words[row]:
					if i2 >= int(wd[0]) and i2 < int(wd[0]) + int(wd[1]):
						B(x2, row, ztop, x2, row, ztop, ink)
	# 右页有一行被红笔划掉(念错的咒语)
	for i3 in range(2, 8):
		var zc3: int = 3 + (i3 - 1) / 4
		var bump3: int = 1 if i3 == 2 else 2
		B(i3, -4, zc3 + 1 + bump3, i3, -4, zc3 + 1 + bump3, red)
	# 左页浮着发光的雪花符印(强调色：蓝色武器就是蓝色)
	var sx := -6
	var sy := -2
	var sz := 9
	g.cur_glow = 90
	for k in range(-3, 4):
		B(sx, sy + k, sz, sx, sy + k, sz, _c("cyan"), 90)
		B(sx + k, sy, sz, sx + k, sy, sz, _c("cyan"), 90)
	for k2 in range(-2, 3):
		if k2 != 0:
			B(sx + k2, sy + k2, sz, sx + k2, sy + k2, sz, _c("cyan2"), 110)
			B(sx + k2, sy - k2, sz, sx + k2, sy - k2, sz, _c("cyan2"), 110)
	B(sx, sy, sz, sx, sy, sz, _c("cyanw"), 170)
	g.cur_glow = 0
	# 书脊下端垂下的挂饰：金链 → 蓝水晶 → 金十字
	for pt: Vector3i in [Vector3i(0, y0 - 2, 2), Vector3i(0, y0 - 2, 1), Vector3i(0, y0 - 3, 0), Vector3i(0, y0 - 3, -1), Vector3i(0, y0 - 3, -2)]:
		B(pt.x, pt.y, pt.z, pt.x, pt.y, pt.z, au if (pt.z % 2) == 0 else au3)
	B(-1, y0 - 4, -3, 1, y0 - 2, -3, au2)
	for zz in range(-7, -3):
		var r: int = 1 if zz == -5 or zz == -6 else 0
		B(-r, y0 - 3 - r, zz, r, y0 - 3 + r, zz, _c("cyan") if r == 1 else _c("cyan2"), 70)
	B(0, y0 - 3, -8, 0, y0 - 3, -12, au)
	B(-2, y0 - 3, -9, 2, y0 - 3, -9, au)
	D(0, y0 - 3, -10, au2)
	_end()


## 电磁学导论(导向节点的专属法器)：她角色卡上那本雷电魔导书，摊开托在掌心上——书页朝上，两片封面从书脊往外张成浅 V 字。
## 藏青硬壳：四个外角是金包角，封面外侧一圈金线 + 正中凸起的金色闪电纹章(微微发光)；象牙白的书页往上拱成两道弧，
## 右页(-X)上方浮着一道发光的黄色闪电(俯视的镜头一眼看得出"雷")，左页(+X)是蓝墨水的笔记和一个磁感线示意图；
## 书头(-Y)的书脊端镶一颗金托的多面蓝宝石(微光)，下面垂一小段金链 + 金色四角星坠子。固定配色，不随武器颜色换色。
## 法器约定：书放在拳头上方(+Z)，书脊沿 Y(书头朝 -Y = 前方)，握点托着书脊
const ELECTRO_W := 11                                       # 每片封面从书脊往外的列数(i = 1..W)
const ELECTRO_Y0 := -12                                     # 书页的 Y 范围；封面两头各多 1 格
const ELECTRO_Y1 := 5
const ELECTRO_SLOPE := 0.5                                  # 封面每往外一列抬高多少(≈27°)
const ELECTRO_BOLT := ["....###", "...###.", "...##..", "..###..", "..##...", ".######", "...###.", "...##..", "..##...", "..#....", ".#....."]


func electro_book() -> void:
	_begin(false)
	var nv := VGrid.hexc("#272c58")
	var nv2 := VGrid.hexc("#1c2043")
	var nv3 := VGrid.hexc("#363d78")
	var au := _c("gold")
	var au2 := _c("gold2")
	var au3 := _c("gold3")
	var pg := _c("paper")
	var pg2 := _c("paper2")
	var ink := VGrid.hexc("#3f4c8e")
	var ink2 := VGrid.hexc("#2b3266")
	var blue := VGrid.hexc("#3a8fe0")
	var volt := VGrid.hexc("#ffcc1e")
	var volt2 := VGrid.hexc("#ffe866")
	var volt3 := VGrid.hexc("#f5980c")
	var W := ELECTRO_W
	var y0 := ELECTRO_Y0
	var y1 := ELECTRO_Y1
	# 书脊(藏青，4 格宽、两格厚，托在掌心上)：两头金箍，底下两道金线
	B(-2, y0 - 1, 2, 1, y1 + 1, 3, nv2)
	for yb: int in [y0 - 1, y1 + 1]:
		B(-2, yb, 2, 1, yb, 3, au)
	for yb2: int in [y0 + 2, y1 - 2]:
		B(-2, yb2, 2, 1, yb2, 2, au3)
	B(-1, y0, 4, 0, y1, 4, pg2)                              # 书缝里的折页
	# 两片封面：每列两格厚，越往外越高；外角金包角(L 形，包住封面的两面)，外侧一圈金线，正中金色闪电纹章
	for side: int in [1, -1]:
		for i in range(1, W + 1):
			var x: int = _electro_x(side, i)
			var zb: int = _electro_zb(i)
			for y in range(y0 - 1, y1 + 2):
				var v: int = mini(y - (y0 - 1), (y1 + 1) - y)       # 离书头/书尾的距离
				var u: int = W - i                                  # 离翻口的距离
				var corner: bool = u <= 2 and v <= 2 and (u == 0 or v == 0 or (u <= 1 and v <= 1))
				var c_out: int = nv
				var c_in: int = nv3 if (u == 0 or v == 0) else nv
				if corner:
					c_out = au
					c_in = au
				elif (v >= 1 and (i == 2 or i == W - 1)) or (v == 1 and i >= 2 and i <= W - 1):
					c_out = au3                                     # 外侧一圈金线
				var bi: int = i if side > 0 else 12 - i                # -X 那片左右翻过来(从外面看两片都是正的)
				var bolt: bool = _electro_bolt(bi, y)
				if bolt:
					c_out = au
				B(x, y, zb, x, y, zb, c_out)
				B(x, y, zb + 1, x, y, zb + 1, c_in)
				if corner and (u == 0 or v == 0):
					D(x, y, zb - 1, au3)
					D(x, y, zb + 2, au)
				if bolt:
					var lit: bool = not _electro_bolt(bi, y - 1) or not _electro_bolt(bi - 1, y)
					D(x, y, zb - 1, au2 if lit else au, 16 if lit else 12)     # 纹章凸出封面一格(微光)
	# 书页：每边 10 列，贴着书缝压下去、往外拱起；翻口和上下切口画出一层层的页边
	for side2: int in [1, -1]:
		for i2 in range(1, W):
			var x2: int = _electro_x(side2, i2)
			var zt: int = _electro_top(i2)
			for y2 in range(y0, y1 + 1):
				for z2 in range(_electro_zb(i2) + 2, zt + 1):
					var cc: int = pg
					if z2 < zt and (i2 == W - 1 or y2 == y0 or y2 == y1):
						cc = pg2 if (z2 % 2) == 0 else pg
					elif z2 == zt and i2 == 1:
						cc = pg2                                    # 书缝边上的阴影
					B(x2, y2, z2, x2, y2, z2, cc)
	# 右页(-X)上方浮着一道发光的黄色闪电(水平的一片，离书页最高处空一格；读书的人看过去是正的)：左上沿亮、下沿橙。
	# 发光收着点(体素发光 = 颜色 × 发光/255 × 16，太亮会糊成白的，跟书页分不开)
	for i3 in range(3, 10):
		for y3 in range(-9, 2):
			if not _electro_bolt(i3, y3):
				continue
			var cb: int = volt
			var gb := 28
			if not _electro_bolt(i3, y3 - 1) and not _electro_bolt(i3 - 1, y3):
				cb = volt2
				gb = 34
			elif not _electro_bolt(i3, y3 + 1) or not _electro_bolt(i3 + 1, y3):
				cb = volt3
				gb = 22
			D(_electro_x(-1, i3), y3, 12, cb, gb)
	for sp: Vector3i in [Vector3i(2, -8, 14), Vector3i(10, -2, 13)]:
		D(_electro_x(-1, sp.x), sp.y, sp.z, volt2, 45)             # 两点小火花
	# 右页的几行字(闪电的上下两头)
	var words_r: Dictionary = {-11: [[2, 4], [7, 2]], 3: [[2, 3], [6, 3]], 4: [[2, 5]]}
	for row_r: int in words_r.keys():
		for wd_r: Array in words_r[row_r]:
			for k in range(int(wd_r[0]), int(wd_r[0]) + int(wd_r[1])):
				D(_electro_x(-1, k), row_r, _electro_top(k), ink)
	# 左页(+X)：蓝墨水的笔记 + 磁感线示意图(一圈蓝线绕着一根"导线")
	var words: Dictionary = {-10: [[2, 3], [6, 3]], -8: [[2, 6]], -6: [[2, 2], [5, 4]], 3: [[2, 4], [7, 2]]}
	for row: int in words.keys():
		for wd: Array in words[row]:
			for k2 in range(int(wd[0]), int(wd[0]) + int(wd[1])):
				D(_electro_x(1, k2), row, _electro_top(k2), ink)
	for i4 in range(2, W - 1):
		for y4 in range(-4, 2):
			var r: float = Vector2(float(i4) - 5.5, float(y4) + 1.5).length()
			if r > 1.7 and r < 2.9:
				D(_electro_x(1, i4), y4, _electro_top(i4), blue)
			elif r < 0.8:
				D(_electro_x(1, i4), y4, _electro_top(i4), ink2)
	# 书头的书脊端：金托多面蓝宝石(朝前，顶端略高出书缝)
	_electro_gem(y0 - 2)
	# 金链 + 金色四角星坠子(往下垂 = -Z)
	var yc := y0 - 2
	for zc in range(-4, 2):
		B(-1, yc, zc, 0, yc, zc, au if (zc % 2) == 0 else au3)
	D(0, yc, -5, au)                                            # 挂环
	# 四角星(9 高 × 7 宽，正中在 x 0、z -10)：上下两个尖长、左右两个尖短，正中往前后各鼓一层(立体的星)
	var star_w := {4: 0, 3: 0, 2: 1, 1: 1, 0: 3}
	for zs in range(-14, -5):
		var dz: int = absi(zs + 10)
		for xs in range(-3, 4):
			if absi(xs) > int(star_w[dz]):
				continue
			var cs: int = au
			if xs < 0 and zs > -10:
				cs = au2                                            # 左上亮
			elif xs > 0 and zs < -10:
				cs = au3                                            # 右下暗
			D(xs, yc, zs, cs)
			if absi(xs) + dz <= 1:
				D(xs, yc - 1, zs, au2 if xs == 0 and dz == 0 else au)
				D(xs, yc + 1, zs, au)
	_end()


func _electro_x(side: int, i: int) -> int:
	return i if side > 0 else -1 - i


## 封面第 i 列的下层 z(封面两格厚：zb、zb+1)
func _electro_zb(i: int) -> int:
	return 3 + int(floor(float(i - 1) * ELECTRO_SLOPE))


## 书页第 i 列的顶面 z：贴着书缝压低、往外拱起，到翻口又收下来
func _electro_top(i: int) -> int:
	var t: float = clampf((float(i) - 0.2) / (float(ELECTRO_W) - 0.6), 0.0, 1.0)
	return 5 + int(floor(float(i - 1) * ELECTRO_SLOPE + 2.6 * pow(sin(PI * t), 0.6)))


## 闪电纹样(7 × 11)：列 i(3..9) × 行 y(-9..1)，第 0 行在书头那边
func _electro_bolt(i: int, y: int) -> bool:
	var r: int = y + 9
	var c: int = i - 3
	if r < 0 or r >= ELECTRO_BOLT.size() or c < 0 or c >= 7:
		return false
	return ELECTRO_BOLT[r][c] == "#"


## 书脊头上的金托蓝宝石：在 X-Z 平面里的竖菱形(6 宽 × 6 高)，正中再往前凸一格的亮面
func _electro_gem(y: int) -> void:
	var au := _c("gold")
	var au3 := _c("gold3")
	var g0 := VGrid.hexc("#1f56b0")
	var g1 := VGrid.hexc("#2f7fe0")
	var g2 := VGrid.hexc("#7cc4ff")
	var g3 := VGrid.hexc("#dff3ff")
	var rows := {7: [-1, 0], 6: [-2, 1], 5: [-3, 2], 4: [-3, 2], 3: [-2, 1], 2: [-1, 0]}
	for z: int in rows.keys():
		var xr: Array = rows[z]
		for x in range(int(xr[0]), int(xr[1]) + 1):
			var rim: bool = x == int(xr[0]) or x == int(xr[1]) or z == 7 or z == 2
			if rim:
				D(x, y, z, au if z >= 4 else au3)
			else:
				var up: bool = z >= 5
				var lf: bool = x < 0
				D(x, y, z, g2 if (up and lf) else (g0 if (not up and not lf) else g1), 30)
	D(-1, y - 1, 5, g3, 55)
	D(0, y - 1, 5, g2, 40)
	D(-1, y - 1, 4, g2, 40)
	D(0, y - 1, 4, g1, 30)


## 两用电击器(架盾节点的专属手枪)：方块电击枪——黑色胶握把、敦实的深灰机身、顶上一条发光电池槽，
## 枪口是警示黄黑条纹的电击弹匣，前端两根发光电极；侧面一个黄色闪电标。发光部分是强调色(随武器颜色换色)
func stunner(p_left: bool) -> void:
	_begin(p_left)
	var rub := VGrid.hexc("#26272c")
	var rub2 := VGrid.hexc("#34363d")
	var body := VGrid.hexc("#555a64")
	var body2 := VGrid.hexc("#6d7380")
	var body3 := VGrid.hexc("#3f434b")
	var yel := VGrid.hexc("#f2c230")
	var yel2 := VGrid.hexc("#ffe07a")
	# 握把(带防滑纹)
	B(-1, -1, -5, 0, 3, 2, rub)
	for zz: int in [-4, -2, 0]:
		B(-2, 0, zz, 1, 2, zz, rub2)
	# 扳机护圈
	B(-1, -5, 0, 0, -5, 2, body3)
	B(-1, -4, 0, 0, -2, 0, body3)
	D(-1, -3, 1, _c("iron2"))
	# 机身：比普通手枪粗一圈
	B(-2, -14, 2, 1, 5, 8, body)
	B(-2, -14, 8, 1, 5, 8, body2)
	B(-2, 5, 2, 1, 6, 7, body3)
	# 顶上的发光电池槽
	for y in range(-12, 3):
		D(-1, y, 9, _c("cyan"), 80)
		D(0, y, 9, _c("cyan2") if (y % 3) == 0 else _c("cyan"), 80)
	B(-2, -13, 9, -2, 3, 9, body3)
	B(1, -13, 9, 1, 3, 9, body3)
	# 电击弹匣：警示黄黑条纹
	for y2 in range(-19, -14):
		for z2 in range(2, 9):
			B(-2, y2, z2, 1, y2, z2, rub if ((y2 + z2) % 4) < 2 else yel)
	B(-2, -20, 2, 1, -20, 8, rub)
	# 两根电极(发光)
	D(-1, -21, 3, _c("cyanw"), 160)
	D(0, -21, 3, _c("cyanw"), 160)
	D(-1, -21, 7, _c("cyanw"), 160)
	D(0, -21, 7, _c("cyanw"), 160)
	# 侧面的黄色闪电标(两面)
	for sx: int in [-3, 2]:
		for pt: Vector2i in [Vector2i(-4, 7), Vector2i(-5, 6), Vector2i(-6, 5), Vector2i(-5, 5), Vector2i(-4, 5), Vector2i(-5, 4), Vector2i(-6, 3), Vector2i(-7, 2)]:
			D(sx, pt.x - 3, pt.y + 1, yel2 if pt.y > 4 else yel)
	_end()


## 飞蝶(白羽节点的专属双持手枪)：她角色卡上那对现代半自动手枪(套筒 + 枪身 + 扳机护圈 + 握把，套筒前端露出枪口)。
## 右手是白枪：象牙白套筒/枪身，套筒尾部金色防滑纹 + 一个金十字、前端两颗金铆钉，深棕握把镶金十字，象牙白弹匣底板；
## 左手是黑枪：黑色套筒/枪身，尾部斜防滑纹，金色空仓挂机杆与扳机，深色握把镶金十字。两把都是固定配色(白的一直白、黑的一直黑，不随武器颜色换色)。
## 枪械约定：-Y = 枪口，+Z = 上，握把沿 Z 穿过拳心(握把/护圈的位置和两用电击器一样)；左手那把(Weapon_L)自动镜像
func butterfly_pistol(p_left: bool) -> void:
	_begin(p_left)
	var wh: bool = not p_left
	var au := VGrid.hexc("#c99040")
	var au2 := VGrid.hexc("#e8b860")
	var au3 := VGrid.hexc("#8e5f26")
	var dk := VGrid.hexc("#18181c")                                       # 枪口 / 准星 / 凹槽
	var sl := VGrid.hexc("#ece7df") if wh else VGrid.hexc("#2b2c32")      # 套筒
	var sl_hi := VGrid.hexc("#f8f5ef") if wh else VGrid.hexc("#3d3f47")   # 套筒顶面
	var sl_lo := VGrid.hexc("#c4b9aa") if wh else VGrid.hexc("#1a1b1f")   # 套筒与枪身之间的缝
	var fr := VGrid.hexc("#e2dcd2") if wh else VGrid.hexc("#26272c")      # 枪身
	var gp := VGrid.hexc("#3b2820") if wh else VGrid.hexc("#1e1f23")      # 握把
	var gp2 := VGrid.hexc("#4c3428") if wh else VGrid.hexc("#2b2c31")     # 握把防滑纹
	var groove := au if wh else VGrid.hexc("#141418")                      # 尾部防滑纹
	var chamber := VGrid.hexc("#cfc7bb") if wh else VGrid.hexc("#4d515a")  # 抛壳窗里露出的枪管
	# 握把：上半段竖直、下半段往后(+Y)错一格；两侧握把片(带防滑纹)镶金十字，底下是弹匣底板
	for z in range(-7, 3):
		var off: int = 1 if z <= -3 else 0
		B(-1, -1 + off, z, 0, 3 + off, z, gp)
		if z <= -1:
			for x: int in [-2, 1]:
				for y in range(off, 3 + off):
					B(x, y, z, x, y, z, gp2 if (y + z + 20) % 2 == 0 else gp)
	for x2: int in [-2, 1]:
		B(x2, 2, -7, x2, 2, -3, au)
		B(x2, 1, -4, x2, 3, -4, au)
		D(x2, 2, -4, au2)
	B(-2, 0, -8, 1, 4, -8, sl_lo if wh else VGrid.hexc("#3a3c43"))
	# 扳机护圈 + 扳机(金)
	B(-1, -7, -1, 0, -7, 1, fr)
	B(-1, -7, -1, 0, -2, -1, fr)
	B(-1, -3, 0, 0, -3, 1, au)
	D(-1, -4, 1, au3)
	# 枪身(护木一直伸到套筒前端下面)；两侧一根金色空仓挂机杆，前端是复进簧导杆的孔
	B(-2, -17, 2, 1, 4, 3, fr)
	for x3: int in [-2, 1]:
		B(x3, -8, 3, x3, -3, 3, au)
		D(x3, -9, 3, au3)
	B(-1, -17, 3, 0, -17, 3, dk)
	# 套筒：前端枪口(深色)，顶面亮一档、底边一条缝；后面照门(两根柱)、前面准星
	B(-2, -20, 4, 1, 5, 8, sl)
	B(-2, -20, 8, 1, 5, 8, sl_hi)
	B(-2, -20, 4, 1, 5, 4, sl_lo)
	B(-1, -20, 5, 0, -20, 6, dk)
	D(-1, -19, 9, dk)
	D(0, -19, 9, dk)
	B(-2, 4, 9, -2, 5, 9, dk)
	B(1, 4, 9, 1, 5, 9, dk)
	# 抛壳窗：顶上挖一个口，露出枪管
	g.mode = VGrid.CLEAR
	B(-1, -10, 8, 0, -5, 8, 0)
	g.mode = VGrid.FILL
	B(-1, -10, 7, 0, -5, 7, chamber)
	# 套筒尾部的防滑纹(白枪：金色竖纹 + 金十字；黑枪：深色斜纹)，白枪前端两颗金铆钉
	for x4: int in [-2, 1]:
		if wh:
			for yy: int in [2, 4]:
				B(x4, yy, 5, x4, yy, 7, groove)
			B(x4, -1, 4, x4, -1, 8, au)
			B(x4, -2, 7, x4, 0, 7, au)
			D(x4, -1, 7, au2)
			D(x4, -18, 5, au2)
			D(x4, -18, 7, au2)
		else:
			for yb: int in [-1, 1, 3]:
				D(x4, yb, 7, groove)
				D(x4, yb, 6, groove)
				D(x4, yb + 1, 5, groove)
	_end()


# ====================================================================== 手弩(单手)
func crossbow(ornate: bool) -> void:
	_begin(false)
	_gun_grip(ornate)
	var stock := _c("white") if ornate else _c("wood")
	var limb := _c("black2") if ornate else _c("wood3")
	B(-1, -24, 3, 0, 6, 5, stock)
	B(-1, -26, 3, 0, -25, 5, _c("gold") if ornate else _c("iron3"))
	# 弩臂：在 y≈-22 横向展开(±x)，两端向后(+y)弯
	for x in range(-14, 14):
		var a: float = absf(float(x) + 0.5) / 14.0
		var off: int = int(round(a * a * 5.0))
		B(x, -23 + off, 4, x, -22 + off, 5, limb)
	B(-15, -19, 4, -14, -17, 5, _c("gold") if ornate else _c("iron3"))
	B(13, -19, 4, 14, -17, 5, _c("gold") if ornate else _c("iron3"))
	# 弦：从两端连到扳机前的弦扣(0,-7)
	var sc := _c("cyan2") if ornate else _c("paper2")
	for i in range(0, 15):
		var t: float = float(i) / 14.0
		var x2: int = int(round(lerpf(-14.0, -1.0, t)))
		var y2: int = int(round(lerpf(-17.0, -7.0, t)))
		D(x2, y2, 6, sc, 80 if ornate else 0)
		D(-1 - x2, y2, 6, sc, 80 if ornate else 0)
	# 上弦的弩箭
	B(-1, -28, 6, -1, -8, 6, _c("wood2") if not ornate else _c("white2"))
	B(-1, -30, 6, -1, -29, 6, _c("iron") if not ornate else _c("cyan2"), 0 if not ornate else 110)
	if ornate:
		for y in range(-20, 4, 3):
			D(-1, y, 3, _c("cyan"), 50)
	_end()


# ====================================================================== 步枪(双手)
func rifle(ornate: bool) -> void:
	_begin(false)
	_gun_grip(ornate)
	var wood := _c("black2") if ornate else _c("wood")
	var wood2 := _c("black") if ornate else _c("wood2")
	# 机匣 + 枪管
	B(-1, -9, 3, 0, 6, 6, _c("white") if ornate else _c("iron3"))
	B(-1, -48, 4, 0, -10, 5, _c("white2") if ornate else _c("iron"))
	B(-2, -49, 3, 1, -48, 6, _c("gold") if ornate else _c("iron3"))
	# 护木(左手托在下面)
	B(-1, -34, 1, 0, -10, 3, wood)
	B(-2, -30, 1, 1, -14, 2, wood2)
	# 枪托：向后(+y)并向下加深(Q 版小短手，枪托要短，抵肩时才不会穿过后背)
	for y in range(6, 17):
		var t: float = float(y - 6) / 10.0
		var zlo: int = int(round(lerpf(1.0, -3.0, t)))
		B(-1, y, zlo, 0, y, 5, wood if (y % 6) < 4 else wood2)
	B(-2, 17, -3, 1, 18, 5, _c("gold") if ornate else _c("iron3"))
	if ornate:
		# 瞄准镜
		B(-1, -22, 7, 0, -6, 9, _c("black3"))
		B(-2, -23, 6, 1, -21, 10, _c("gold"))
		B(-2, -7, 6, 1, -5, 10, _c("gold"))
		B(-1, -24, 7, 0, -24, 9, _c("cyan2"), 120)
		for y2 in range(-45, -12, 4):
			D(-1, y2, 6, _c("cyan"), 60)
		for ry: int in [-40, -26, -12]:
			B(-2, ry, 1, 1, ry, 6, _c("gold"))
	else:
		# 燧发机
		B(-1, 5, 6, 0, 7, 8, _c("iron3"))
		for ry2: int in [-40, -26]:
			B(-2, ry2, 1, 1, ry2, 6, _c("iron3"))
	_end()


# ====================================================================== 法器
## 朴素款：学徒魔典(合上的书，托在拳头上)
func focus_plain() -> void:
	_begin(false)
	var cov := _c("leather")
	B(-6, -11, 3, 5, 4, 3, cov)
	B(-6, -11, 8, 5, 4, 8, cov)
	B(-5, -10, 4, 5, 3, 7, _c("paper"))
	B(-6, -11, 3, -6, 4, 8, _c("leather2"))       # 书脊
	for yy: int in [-10, 3]:
		B(-5, yy, 4, 5, yy, 7, _c("paper2"))
	B(5, -5, 4, 6, -2, 7, _c("iron3"))             # 书扣
	B(-2, -6, 9, 1, -2, 9, _c("iron3"))            # 封面铁饰
	_end()


## 华丽款：水晶球(金爪托着发光的球，悬在拳头上方)
func focus_orb() -> void:
	_begin(false)
	B(-2, -2, 2, 1, 1, 4, _c("gold"))
	B(-3, -3, 5, 2, 2, 5, _c("gold2"))
	for pr: Array in [[-4, -4], [3, -4], [-4, 3], [3, 3]]:
		B(pr[0], pr[1], 5, pr[0], pr[1], 10, _c("gold"))
		D(pr[0], pr[1], 11, _c("gold2"))
	# 水晶球：外壳强调色(按武器颜色换色)、微光，内核更亮——发光别太强，否则会糊成一团白
	g.cur_glow = 28
	var cx: float = -0.5
	g.sq(cx, -0.5, 11.5, 5.2, 5.2, 5.2, _c("cyan"), 2.0)
	g.cur_glow = 60
	g.sq(cx, -0.5, 11.5, 3.6, 3.6, 3.6, _c("cyan2"), 2.0)
	g.cur_glow = 130
	g.sq(cx, -0.5, 11.5, 1.8, 1.8, 1.8, _c("cyanw"), 2.0)
	g.cur_glow = 0
	_end()


## 特殊款：魔典(黑金封面 + 发光符文，书页发光)
func focus_tome() -> void:
	_begin(false)
	var cov := _c("black2")
	B(-7, -12, 3, 6, 5, 3, cov)
	B(-7, -12, 9, 6, 5, 9, cov)
	B(-6, -11, 4, 6, 4, 8, _c("white"))
	for yy: int in [-11, 4]:
		B(-6, yy, 4, 6, yy, 8, _c("cyan2"), 60)
	B(-7, -12, 3, -7, 5, 9, _c("gold"))
	for cc: Array in [[-7, -12], [5, -12], [-7, 4], [5, 4]]:
		B(cc[0], cc[1], 9, cc[0] + 1, cc[1] + 1, 10, _c("gold"))
	# 封面符文：菱形
	for k in range(-3, 4):
		var w: int = 3 - absi(k)
		B(-1 - w, -4 + k, 10, w, -4 + k, 10, _c("cyan"), 90)
	B(-1, -4, 10, 0, -4, 10, _c("cyanw"), 160)
	B(6, -6, 5, 7, -1, 7, _c("gold2"))
	_end()

## 光之心(灭罪节点的专属法器)：她角色卡上捧着的黄色水晶球——没有托架，直接托在掌心上方(+Z = 上)。
## 琥珀色的球壳：上半边亮、下半边沉，左上一块白色高光 + 一条弧形反光，下沿一圈透过来的暖光(像球心的光从底下透出来)；
## 发光收着点(太亮会糊成一团白)，光束的"光"交给特效
func light_heart() -> void:
	_begin(false)
	var c0 := VGrid.hexc("#a8680e")
	var c1 := VGrid.hexc("#d99a1e")
	var c2 := VGrid.hexc("#f2c03a")
	var c3 := VGrid.hexc("#fadc6c")
	var c4 := VGrid.hexc("#fff3bc")
	var wh := VGrid.hexc("#ffffff")
	var cx := -0.5
	var cy := -0.5
	var cz := 9.6
	var r := 6.7
	var lite := Vector3(0.45, -0.45, 0.77).normalized()
	for z in range(2, 18):
		for y in range(-8, 8):
			for x in range(-8, 8):
				var d := Vector3(float(x) + 0.5 - cx, float(y) + 0.5 - cy, float(z) + 0.5 - cz)
				var l: float = d.length()
				if l > r:
					continue
				var n: Vector3 = d / maxf(0.001, l)
				var c := 0
				var gl := 0
				if l > r - 1.6:
					var lit: float = n.dot(lite)
					if lit > 0.93:
						c = wh                                  # 高光
						gl = 75
					elif lit > 0.78:
						c = c4
						gl = 45
					elif n.z > 0.25:
						c = c3 if lit > 0.3 else c2
						gl = 24
					elif n.z > -0.45:
						c = c2 if lit > -0.2 else c1
						gl = 18
					else:
						c = c1 if (n.z > -0.8) else c0
						gl = 12
					# 弧形反光(高光对面的一道亮弧) + 下沿透出来的暖光
					var back: float = n.dot(-lite)
					if back > 0.55 and back < 0.72:
						c = c4
						gl = 36
					if n.z < -0.55 and n.z > -0.8 and (x + y) % 2 == 0:
						c = c3
						gl = 30
				else:
					c = c4                                      # 球心(看不见，只让烘焙的发光更饱满)
					gl = 40
				if c != 0:
					D(x, y, z, c, gl)
	_end()


# ====================================================================== 祝福之心(心连节点的专属法器)
## 她角色卡上那串念珠：藏青方珠(每三颗一颗金珠，珠间金链)。一圈斜着缠在拳头上(正面看是一条斜过指节的珠带)，虎口上方冒出一小圈；
## 拳底一颗藏青珠 + 金环挂着主角——金色十字架(16 行 × 11 列)：四端是嵌白珍珠的花苞形端头，臂上嵌一道藏青线 + 金点，
## 正中凸起八角金框的蓝宝石(微光)。十字架下端往前荡 ROSARY_TILT(正面朝前上方)：战斗镜头是 52° 俯视，竖直挂着的十字架会被压扁，
## 往前倾一点才看得清(代价：attack_focus 蓄力时手腕后仰，十字架会朝前翘得更多)。固定配色(金色 = 她衣服金边的颜色)，不随武器颜色换色。
## 法器约定：原点 = 握点，+Z = 上，-Y = 前(朝外)，+X = 拇指一侧(朝身体中线)
const ROSARY_CROSS := [
	"....GGG....",
	"...GGWGG...",
	"....GNG....",
	"....GNG....",
	".G..GGG..G.",
	"GGGGBBBGGGG",
	"GWNGBBBGNWG",
	"GGGGBBBGGGG",
	".G..GGG..G.",
	"....GNG....",
	"....GNG....",
	"....GoG....",
	"....GNG....",
	"....GNG....",
	"...GGWGG...",
	"....GGG....",
]
const ROSARY_TILT := 25.0                                  # 十字架往前倾的角度(度)
const ROSARY_FIST := Vector3(-0.5, -3.5, -0.5)             # 握着的拳头的中心(连续坐标；拳头约 x -3..3、y -7..0、z -4..3)
const ROSARY_GOLD := ["#cc9638", "#ecc05e", "#946624"]     # 金 / 亮金 / 暗金(= 她衣服金边的颜色)


func rosary() -> void:
	_begin(false)
	var au := VGrid.hexc(ROSARY_GOLD[0])
	var au3 := VGrid.hexc(ROSARY_GOLD[2])
	var C := ROSARY_FIST
	# 缠在拳头上的一圈：斜着绕过拳头的正面、顶面和背面(从正面看是一条斜过指节的珠带)
	var ax := Vector3(1.0, 0.0, 0.55).normalized()
	var e1 := Vector3(0.0, 1.0, 0.0)
	var e2 := ax.cross(e1)
	var wrap: Array = []
	for i in range(12):
		var a: float = TAU * float(i) / 12.0
		wrap.append(C + e1 * (cos(a) * 4.6) + e2 * (sin(a) * 4.4))
	_rosary_strand(wrap, 2.8, "NNNg", true)
	# 虎口上方冒出的一小圈
	_rosary_strand([C + Vector3(-1.6, 0.4, 3.0), C + Vector3(-2.6, 0.2, 5.6), C + Vector3(-1.4, 0.0, 8.0), C + Vector3(0.8, 0.0, 8.4),
		C + Vector3(2.2, 0.2, 6.2), C + Vector3(1.8, 0.4, 3.4)], 2.7, "NgNN", false)
	# 拳底：一颗藏青珠 → 金环 → 十字架(顶端 o，往前下方挂)
	var bx: int = roundi(C.x + 0.5)
	var by: int = roundi(C.y) - 1
	_rosary_bead(Vector3(float(bx), float(by), -4.0), false)
	D(bx - 1, by - 1, -6, au)
	D(bx - 1, by, -6, au3)
	_rosary_cross(Vector3(float(bx) - 0.5, float(by), -6.0), deg_to_rad(ROSARY_TILT))
	_end()


func _rosary_navy(dx: int, dy: int, dz: int) -> int:
	if dz > 0 and dx <= 0 and dy <= 0:
		return VGrid.hexc("#4a64c4")                           # 左前上的高光
	if dz < 0:
		return VGrid.hexc("#1b2560")
	return VGrid.hexc("#2a3a8c")


## 一串念珠：pts 是控制点(Catmull-Rom 平滑)，每隔 step 放一颗 2×2×2 的珠子(pat：N = 藏青，g = 金)，珠间一格金链
func _rosary_strand(pts: Array, step: float, pat: String, closed: bool) -> void:
	var n: int = pts.size()
	var dense: Array = []
	var segs: int = n if closed else n - 1
	for i in range(segs):
		var p0: Vector3 = pts[(i - 1 + n) % n] if closed else pts[maxi(i - 1, 0)]
		var p1: Vector3 = pts[i]
		var p2: Vector3 = pts[(i + 1) % n]
		var p3: Vector3 = pts[(i + 2) % n] if closed else pts[mini(i + 2, n - 1)]
		for k in range(10):
			var t: float = float(k) / 10.0
			var t2: float = t * t
			var t3: float = t2 * t
			dense.append(0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t3))
	dense.append(pts[0] if closed else pts[n - 1])
	var cs: Array = [dense[0]]
	var acc := 0.0
	for i in range(1, dense.size()):
		var a: Vector3 = dense[i - 1]
		var b: Vector3 = dense[i]
		var L: float = a.distance_to(b)
		var pos := 0.0
		while acc + (L - pos) >= step:
			pos += step - acc
			cs.append(a.lerp(b, pos / L))
			acc = 0.0
		acc += L - pos
	if closed and cs.size() > 1 and (cs[cs.size() - 1] as Vector3).distance_to(cs[0]) < step * 0.6:
		cs.pop_back()
	var au3 := VGrid.hexc(ROSARY_GOLD[2])
	for i in range(1, cs.size()):
		g.seg(cs[i - 1], cs[i], 0.5, 0.5, au3)
	if closed:
		g.seg(cs[cs.size() - 1], cs[0], 0.5, 0.5, au3)
	for i in range(cs.size()):
		_rosary_bead(cs[i], pat[i % pat.length()] == "g")


## 2×2×2 的方珠，中心对齐到格点
func _rosary_bead(c: Vector3, gold: bool) -> void:
	var b := Vector3i(roundi(c.x), roundi(c.y), roundi(c.z))
	for dz: int in [-1, 0]:
		for dy: int in [-1, 0]:
			for dx: int in [-1, 0]:
				var col: int
				if gold:
					col = VGrid.hexc(ROSARY_GOLD[1] if (dz == 0 and dx == -1) else ROSARY_GOLD[0 if dz == 0 else 2])
				else:
					col = _rosary_navy(dx * 2 + 1, dy * 2 + 1, dz * 2 + 1)
				D(b.x + dx, b.y + dy, b.z + dz, col)


## 十字架格子(r 行, c 列)的字符；出界 = "."
func _rosary_at(r: int, c: int) -> String:
	if r < 0 or r >= ROSARY_CROSS.size() or c < 0 or c >= String(ROSARY_CROSS[0]).length():
		return "."
	return String(ROSARY_CROSS[r])[c]


## 十字架：顶端中心 o(连续坐标)，沿 dn = (0, -sin a, -cos a) 往下排行，正面法线 nf = (0, -cos a, sin a)。
## 板厚 2(nf 方向 -1..1)；珍珠、宝石和宝石的八角金框再往前凸一层(1..2)。按体素中心反算格子取色(倾斜后是阶梯状)
func _rosary_cross(o: Vector3, a: float) -> void:
	var au := VGrid.hexc(ROSARY_GOLD[0])
	var au2 := VGrid.hexc(ROSARY_GOLD[1])
	var au3 := VGrid.hexc(ROSARY_GOLD[2])
	var inl := VGrid.hexc("#1c2352")
	var pearl := VGrid.hexc("#f3eee2")
	var pearl2 := VGrid.hexc("#ffffff")
	var g0 := VGrid.hexc("#1a3f9e")
	var g1 := VGrid.hexc("#2a5fd0")
	var g2 := VGrid.hexc("#6a9cf0")
	var dn := Vector3(0.0, -sin(a), -cos(a))
	var nf := Vector3(0.0, -cos(a), sin(a))
	var rows: int = ROSARY_CROSS.size()
	var half: float = float(String(ROSARY_CROSS[0]).length()) * 0.5
	for z in range(int(floor(o.z - float(rows) - 3.0)), int(ceil(o.z + 3.0))):
		for y in range(int(floor(o.y - float(rows) * sin(a) - 4.0)), int(ceil(o.y + 4.0))):
			for x in range(int(floor(o.x - half - 1.0)), int(ceil(o.x + half + 1.0))):
				var q := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - o
				var v: float = q.dot(dn)
				var w: float = q.dot(nf)
				if v < 0.0 or w < -1.0 or w >= 2.0:
					continue
				var r: int = int(floor(v))
				var c: int = int(floor(q.x + half))
				var ch := _rosary_at(r, c)
				if ch == ".":
					continue
				var up_o: bool = _rosary_at(r - 1, c) == "."
				var dn_o: bool = _rosary_at(r + 1, c) == "."
				var rt_o: bool = _rosary_at(r, c + 1) == "."
				var col: int = au
				var glow := 0
				if w < 1.0:
					match ch:
						"G":
							col = au2 if up_o else (au3 if (dn_o or rt_o) else au)
						"N":
							col = inl
						"o":
							col = au2
						"W":
							col = pearl
						"B":
							col = g0
							glow = 22
					if w < 0.0:
						col = inl if ch == "N" else au3                 # 背面一层：暗金(宝石、珍珠只在正面)
						glow = 0
				else:
					# 凸起的一层：珍珠 / 宝石 / 宝石的八角金框
					var bezel := false
					if ch == "G":
						for dr in range(-1, 2):
							for dc in range(-1, 2):
								if _rosary_at(r + dr, c + dc) == "B":
									bezel = true
					if ch == "W":
						col = pearl2
					elif ch == "B":
						var dcx: int = c - int(half)                     # -1..1(左 → 右)
						var drz: int = r - 6                             # -1..1(上 → 下)
						col = g1
						glow = 24
						if dcx == -1 and drz == -1:
							col = g2
							glow = 34                                   # 左上角一点亮光
						elif dcx + drz >= 1:
							col = g0
							glow = 18
					elif bezel:
						col = au2 if (r <= 5 or c < int(half)) else au
					else:
						continue
				D(x, y, z, col, glow)


# ====================================================================== 青影(踏影节点的专属单手剑)
## 他角色卡上那把发光的青色长剑：刃身两色——深蓝的刃芯 + 两侧发亮的青色刃口(发光)，刃根一颗小青宝石；金色十字护手(两端方头、中间嵌青宝石)，
## 黑色剑柄缠两道金箍，金色柄头下面挂一串金饰 + 青色流苏(垂在手下方)。刃沿 +Y
func cyan_shadow() -> void:
	_begin(false)
	var bk := VGrid.hexc("#1c2028")
	var au := _c("gold")
	var au2 := _c("gold2")
	var au3 := _c("gold3")
	var core := VGrid.hexc("#1d4f9a")
	var core2 := VGrid.hexc("#2a6cc8")
	var edge := VGrid.hexc("#7ff4ff")
	var gem := VGrid.hexc("#38e0e8")
	var tas := VGrid.hexc("#1f8a96")
	var tas2 := VGrid.hexc("#2fb6c2")
	# 剑柄 + 两道金箍 + 柄头
	B(-1, -8, -1, 0, 3, 0, bk)
	for ry: int in [-6, -1]:
		B(-1, ry, -1, 0, ry, 0, au)
	B(-2, -11, -2, 1, -9, 1, au)
	D(-1, -10, -2, gem, 90)
	# 流苏：柄头下面一串金饰 + 青色流苏(往下垂 = -Z)
	B(-1, -11, -4, 0, -11, -3, au3)
	B(-1, -11, -6, 0, -11, -5, gem, 60)
	B(-1, -11, -7, 0, -11, -7, au2)
	for z in range(-14, -7):
		var w: int = 1 if z < -9 else 0
		B(-1 - w, -11 - w, z, 0 + w, -11 + w, z, tas if (z % 2) == 0 else tas2)
	# 十字护手：两端方头，中间嵌青宝石
	B(-2, 4, -7, 1, 5, 6, au)
	B(-2, 4, -8, 1, 6, -7, au2)
	B(-2, 4, 6, 1, 6, 7, au2)
	B(-2, 4, -1, 1, 5, 0, au3)
	D(-2, 5, -1, gem, 110)
	D(1, 5, -1, gem, 110)
	# 刃：深蓝刃芯 + 发光的青色刃口
	for y in range(6, 63):
		var t: float = float(y - 6) / 56.0
		var half: float = lerpf(3.4, 1.4, pow(t, 1.2))
		if y > 56:
			half = lerpf(half, 0.5, float(y - 56) / 6.0)
		var za: int = int(floor(-half))
		var zb: int = int(ceil(half)) - 1
		for z in range(za, zb + 1):
			var is_edge: bool = z == za or z == zb
			B(-1, y, z, 0, y, z, edge if is_edge else (core2 if (y + z) % 5 == 0 else core), 120 if is_edge else 25)
	D(-1, 8, -1, gem, 120)
	D(0, 8, -1, gem, 120)
	_end()


# ====================================================================== 希望(执剑节点的专属单手剑)
## 她角色卡上那把勇者的剑：比华丽长剑宽一圈的银色阔刃(刃口最亮、斜面浅银、中间一条偏紫灰的宽带 + 更深的血槽)，刃尖前面嵌一个金色十字；
## 金色十字护手：正中一块菱形金座托着方形(转 45°)的大蓝宝石，两臂往刃的方向微微扬起(V 形)、各嵌一颗小蓝宝石，
## 两端往柄头一侧垂下、翻卷成镂空的小环；刃根两侧一对金色护片。深棕皮革剑柄缠三道银箍，金色圆盘柄头两面各嵌一颗大蓝宝石。
## 刃沿 +Y，握点在原点(和其他单手剑同一套握法)；全长 79 格(华丽长剑 72)，刃宽 12 收到 10，护手宽 26。
## 颜色全用固定色值(不用 cyan 强调色，不跟武器颜色换色)：它本来就是蓝色武器，蓝宝石要保持卡上那种深的皇家蓝，银 / 金也不能变。
## 刀光：刃根(金座上沿)~ 刃尖 = 14 ~ 63(默认 sword 刀光是 18 ~ 58)
const HOPE_BLADE := [6, 63]                               # 刃(局部 Y 范围)


func hope_sword() -> void:
	_begin(false)
	var au := _c("gold")
	var au2 := _c("gold2")
	var au3 := _c("gold3")
	var lea := VGrid.hexc("#4a2c1c")
	var lea2 := VGrid.hexc("#5f3a25")
	var ag := VGrid.hexc("#d9dce6")                       # 剑柄上的银箍
	var ag2 := VGrid.hexc("#a9adbd")
	var edge := VGrid.hexc("#f4f5fa")                     # 刃：刃口 → 斜面 → 中段 → 血槽
	var bev := VGrid.hexc("#d5d7e6")
	var bev2 := VGrid.hexc("#bcbfd6")
	var mid := VGrid.hexc("#a3a6c4")
	var mid2 := VGrid.hexc("#9a9dbd")
	var ful := VGrid.hexc("#7d80a8")
	var ful2 := VGrid.hexc("#888bb0")
	var sap := VGrid.hexc("#2448c8")                      # 蓝宝石
	var sap_d := VGrid.hexc("#172a86")
	var sap2 := VGrid.hexc("#3d6ae6")
	var sap_h := VGrid.hexc("#a9c8ff")
	# ---- 柄头：金色圆盘(和刃同一个平面，切角)，两面各嵌一颗大蓝宝石(凸出一格)，底下一个小钮
	B(-2, -8, -2, 1, -8, 1, au3)
	for y in range(-14, -8):
		for z in range(-3, 3):
			if (z == -3 or z == 2) and (y == -14 or y == -9):
				continue
			B(-2, y, z, 1, y, z, au3 if y == -14 else (au2 if y == -9 else au))
	B(-1, -15, -1, 0, -15, 0, au2)
	for sx: int in [-3, 2]:
		for y in range(-13, -9):
			for z in range(-2, 2):
				if (z == -2 or z == 1) and (y == -13 or y == -10):
					continue
				var pc: int = sap
				if y == -13 or (z == 1 and y < -10):
					pc = sap_d
				elif y == -10 or z == -2:
					pc = sap2
				D(sx, y, z, sap_h if (y == -11 and z == -1) else pc, 30 if (y == -11 and z == -1) else 0)
	# ---- 剑柄：棕色皮革(斜着缠)，三道银箍
	for y in range(-7, 4):
		for z in range(-1, 1):
			for x in range(-1, 1):
				D(x, y, z, lea if (y + z + x + 20) % 2 == 0 else lea2)
	for ry: int in [-5, -1, 3]:
		B(-1, ry, -1, 0, ry, 0, ag)
		D(-1, ry, -1, ag2)
	# ---- 刃：宽 12 格收到 10 格，刃尖收成一格；颜色按离刃口的格数分带，中线两格是血槽
	var y0: int = HOPE_BLADE[0]
	var y1: int = HOPE_BLADE[1]
	for y in range(y0, y1 + 1):
		var half: float = _hope_half(y)
		var za: int = int(floor(-half))
		var zb: int = int(ceil(half)) - 1
		for z in range(za, zb + 1):
			var k: int = mini(z - za, zb - z)
			var c: int = mid if (y + 2 * z) % 5 != 0 else mid2
			if k == 0:
				c = edge
			elif k == 1:
				c = bev
			elif k == 2:
				c = bev2
			elif k >= 4:
				c = mid2
			if (z == -1 or z == 0) and k >= 2 and y <= 38:
				c = ful if (y + z) % 5 != 0 else ful2
			B(-1, y, z, 0, y, z, c)
	# 刃尖前面嵌的金色十字(两面都看得到)
	B(-1, 41, -1, 0, 52, 0, au)
	B(-1, 48, -3, 0, 49, 2, au)
	B(-1, 48, -1, 0, 49, 0, au2)
	B(-1, 41, -1, 0, 41, 0, au3)
	# ---- 护手两臂(4 格厚)：靠中间 4 格高、往外 3 格高，往刃的方向微微扬起(V 形)；两端往柄头一侧垂下、翻卷成镂空的小环，环顶再翘一个小钩
	for z in range(-13, 13):
		var u: int = z if z >= 0 else -1 - z
		var up: int = clampi((u - 5) / 2, 0, 2)
		if u <= 9:
			var ylo: int = (4 if u <= 7 else 5) + up
			for y in range(ylo, 8 + up):
				B(-2, y, z, 1, y, z, au3 if y == ylo else (au2 if y == 7 + up else au))
		else:
			for y in range(2 + up, 8 + up):
				if u == 11 and (y == 4 + up or y == 5 + up):
					continue
				B(-2, y, z, 1, y, z, au2 if y == 7 + up else (au3 if (y == 2 + up or u == 12) else au))
			if u == 12:
				B(-2, 8 + up, z, 1, 8 + up, z, au2)
	# 两臂各一颗小蓝宝石(两面)
	for zz: int in [-8, 7]:
		for sx: int in [-2, 1]:
			D(sx, 6, zz, sap)
			D(sx, 7, zz, sap2)
	# 刃根两侧的金色护片：贴着刃口往上收成尖
	for y in range(8, 12):
		var h2: float = _hope_half(y)
		var ea: int = int(floor(-h2))
		var eb: int = int(ceil(h2)) - 1
		var w: int = 2 if y <= 9 else 1
		for i in range(w):
			B(-2, y, ea + i, 1, y, ea + i, au2 if y == 11 else au)
			B(-2, y, eb - i, 1, y, eb - i, au2 if y == 11 else au)
	# ---- 正中的菱形金座 + 菱形(方形转 45°)大蓝宝石：金座 4 格厚，亮金托座和宝石再各凸出一格
	for y in range(4, 15):
		for z in range(-7, 7):
			var d: float = absf(float(y) - 9.0) + absf(float(z) + 0.5)
			if d > 5.5:
				continue
			if d > 4.5:
				B(-2, y, z, 1, y, z, au3 if y < 9 else au)
			elif d > 3.5:
				B(-3, y, z, 2, y, z, au2 if y >= 9 else au)
			else:
				var gc: int = sap2 if d <= 1.5 else sap
				if d > 2.5 and (y < 9 or (y == 9 and z >= 0)):
					gc = sap_d
				var hl: bool = (y == 11 and z == -1) or (y == 10 and z == -2)
				B(-3, y, z, 2, y, z, sap_h if hl else gc, 30 if hl else 0)
	_end()


## 希望的刃半宽(z 方向，格)：12 格宽收到 10 格，最后 13 格收成尖
func _hope_half(y: int) -> float:
	var y0: int = HOPE_BLADE[0]
	var y1: int = HOPE_BLADE[1]
	var half: float = lerpf(5.6, 4.8, float(y - y0) / float(y1 - y0))
	if y > y1 - 13:
		half = lerpf(half, 0.5, float(y - (y1 - 13)) / 13.0)
	return half


# ====================================================================== 沉沦之梦(共歌节点的专属单手武器：麦克风)
## 她角色卡上右手那支麦克风：灰色金属网罩的大圆球头(浅灰 / 深灰棋盘格体素 = 网格，越往上越亮)，下面一圈金色杯形领口托着球头
## (四面各嵌一颗蓝宝石，从哪边看都有一颗)，深棕色细手柄(拳头下面两道金箍)，柄尾小金钮，下面用细环挂一个小金十字(两片十字交叉成立体的，
## 前后左右都看得出是十字)和一束白色流苏(沿 -Y 垂下)。握法和单手剑一样：握点在原点、话筒头在 +Y(= 剑刃开始的地方)，像拿一根短棒 / 火把；
## 照卡上的拿法，拳头就握在领口下面，手柄大半露在拳头下面。
## 比剑短得多：话筒本体 y -11..17 = 29 格(36 cm，为了俯视镜头看得清比真麦克风夸张一点)，球头直径 10 格，连挂饰全长 49 格(y -31..17)。
## 颜色全用固定色值(和身体 pacifist.gd 同一套金 / 蓝宝石 / 白)，不用 cyan 强调色：不跟武器颜色换色(它是红色武器，但卡上的灰 / 金 / 蓝不能变)。
## 刀光：默认 sword 刀光是 18 ~ 58，整段都在话筒外面；话筒的领口 + 球头在 5 ~ 17
const MIC_HEAD_Y := 13                                    # 球头球心(局部 Y，在体素边界上)
const MIC_HEAD := [5, 17]                                 # 领口 + 球头(局部 Y 范围)


func mic() -> void:
	_begin(false)
	var au := VGrid.hexc("#cc9638")                       # 金(同身体)
	var au2 := VGrid.hexc("#ecc05e")
	var au3 := VGrid.hexc("#946624")
	var wd := VGrid.hexc("#45322a")                       # 手柄深棕
	var wd2 := VGrid.hexc("#5f463a")
	var wd3 := VGrid.hexc("#2a1e19")
	var gm := VGrid.hexc("#2f6fe0")                       # 蓝宝石(同身体)
	var gm_d := VGrid.hexc("#1d47a8")
	var gm_h := VGrid.hexc("#a9c8ff")
	var wh := VGrid.hexc("#f2efe9")                       # 白流苏(同身体的白)
	var wh2 := VGrid.hexc("#d9d3c9")
	# 网罩：棋盘格两种灰，按高度分三档明暗(顶上最亮)
	var grill_l: Array = [VGrid.hexc("#8f949d"), VGrid.hexc("#aab0b8"), VGrid.hexc("#c6cbd2")]
	var grill_d: Array = [VGrid.hexc("#4f545d"), VGrid.hexc("#60656e"), VGrid.hexc("#7a7f88")]
	var cy: int = MIC_HEAD_Y
	# ---- 球头：球心 (0, cy, 0)，半径 4.95 → 剖面 4 / 6 / 8 / 10 / 10 / 10 / 10 / 8 / 6 / 4(最下面两层被领口盖住)
	for y in range(cy - 5, cy + 5):
		for z in range(-5, 5):
			for x in range(-5, 5):
				var p := Vector3(float(x) + 0.5, float(y - cy) + 0.5, float(z) + 0.5)
				if p.length() > 4.95:
					continue
				var band: int = 0 if p.y < -1.0 else (1 if p.y < 2.0 else 2)
				D(x, y, z, grill_l[band] if (x + y + z) % 2 == 0 else grill_d[band])
	# ---- 金色杯形领口(6 格宽的八角柱)：底下一层收进手柄，顶上一圈 8 格宽的亮边(杯口外翻)托住球头
	B(-2, cy - 8, -2, 1, cy - 8, 1, au3)
	for y in range(cy - 7, cy - 3):
		for z in range(-4, 4):
			for x in range(-4, 4):
				if Vector2(float(x) + 0.5, float(z) + 0.5).length() > (3.9 if y == cy - 4 else 3.0):
					continue
				D(x, y, z, au2 if y == cy - 4 else (au3 if y == cy - 7 else au))
	# 蓝宝石：领口四面各一颗 2×2(左上一格高光、右下一格暗)
	for f in range(4):
		for dy in range(2):
			for dk in range(2):
				var gc: int = gm
				if dy == 1 and dk == 0:
					gc = gm_h
				elif dy == 0 and dk == 1:
					gc = gm_d
				var yy: int = cy - 6 + dy
				var k: int = -1 + dk
				var gl: int = 30 if gc == gm_h else 0
				match f:
					0: D(-3, yy, k, gc, gl)
					1: D(2, yy, -1 - k, gc, gl)
					2: D(-1 - k, yy, -3, gc, gl)
					3: D(k, yy, 2, gc, gl)
	# ---- 手柄：深棕，十字形截面(4 格宽、切掉四角 = 圆柱)，一侧亮边、对侧暗边；拳头下面两道金箍(补满四角 = 比手柄鼓出一点)
	for y in range(-10, cy - 8):
		for z in range(-2, 2):
			for x in range(-2, 2):
				if Vector2(float(x) + 0.5, float(z) + 0.5).length() > 1.6:
					continue
				var c3: int = wd
				if x == -2 or z == -2:
					c3 = wd2
				elif x == 1 or z == 1:
					c3 = wd3
				D(x, y, z, c3)
	B(-2, -6, -2, 1, -6, 1, au)
	B(-2, -9, -2, 1, -9, 1, au2)
	# ---- 柄尾小金钮 + 细挂环(一格粗，和十字之间断开一下)
	B(-1, -11, -1, 0, -11, 0, au)
	B(-1, -13, -1, -1, -12, -1, au3)
	# ---- 金十字(两片十字交叉成立体的，从哪一面看都是十字)：竖条 y -21..-14(2 格粗)，横臂 y -17..-16，往四面各伸出 2 格；顶面 / 臂端亮、底下暗
	B(-1, -21, -1, 0, -14, 0, au)
	B(-1, -17, -3, 0, -16, 2, au)
	B(-3, -17, -1, 2, -16, 0, au)
	B(-1, -14, -1, 0, -14, 0, au2)
	B(-1, -16, -3, 0, -16, -3, au2)
	B(-1, -16, 2, 0, -16, 2, au2)
	B(-3, -16, -1, -3, -16, 0, au2)
	B(2, -16, -1, 2, -16, 0, au2)
	B(-1, -21, -1, 0, -21, 0, au3)
	# ---- 白流苏：细绳 + 金色小钟形帽 + 一束白穗(沿 -Y 垂下，越往下越散，末端参差)
	D(-1, -22, -1, au3)
	B(-1, -23, -1, 0, -23, 0, au)
	for z in range(-2, 2):
		for x in range(-2, 2):
			var q: float = Vector2(float(x) + 0.5, float(z) + 0.5).length()
			if q <= 1.6:
				D(x, -24, z, au2 if (x == -2 or z == -2) else au3)
			for y in range(-31, -24):
				var r: float = 1.6 if y >= -27 else 2.2
				if q > r:
					continue
				if (y == -31 and (x + z + 4) % 2 != 0) or (y == -30 and (x + z + 4) % 3 == 0):
					continue
				D(x, y, z, wh if (x + 2 * z + 8) % 3 != 0 else wh2)
	_end()


# ====================================================================== 黑色任务(止息节点的专属单手远程)
## 她角色卡上的黑色微冲：方盒子机匣 + 顶上一条带缺口的导轨(前后准星)，短枪管套着粗一圈的消音式枪口，握把前面一根长直弹匣，
## 机匣后面一截折叠枪托(镂空)，左侧拉机柄。枪械约定：-Y = 枪口，+Z = 上；单手握在原点。突进空翻时手里拿的也是它(P_commando_smg)
func black_mission() -> void:
	_begin(false)
	var bk := VGrid.hexc("#1d1f24")
	var bk2 := VGrid.hexc("#2e3138")
	var gm := VGrid.hexc("#474c55")
	var gm2 := VGrid.hexc("#6a707b")
	var rb := VGrid.hexc("#121316")
	# 握把 + 扳机护圈
	B(-1, -1, -5, 0, 2, 2, bk2)
	B(-1, 3, -4, 0, 3, 2, bk2)
	B(-1, -5, 0, 0, -5, 2, gm)
	B(-1, -4, 0, 0, -2, 0, gm)
	D(-1, -3, 1, gm2)
	# 机匣：方盒子
	B(-2, -12, 2, 1, 5, 7, bk)
	B(-2, -11, 7, 1, 4, 7, bk2)
	B(-3, -6, 4, -3, -3, 5, rb)
	D(2, -5, 6, gm2)
	B(2, -6, 6, 3, -6, 6, gm)
	# 顶上导轨(一格一个缺口) + 前后准星
	for y in range(-12, 5):
		D(-1, y, 8, gm if (y % 2) == 0 else bk2)
		D(0, y, 8, gm if (y % 2) == 0 else bk2)
	B(-1, -11, 9, 0, -11, 10, gm)
	B(-1, 3, 9, 0, 3, 9, gm)
	# 枪管 + 消音式枪口
	B(-1, -16, 4, 0, -13, 5, gm)
	B(-2, -22, 3, 1, -17, 6, bk2)
	B(-1, -22, 4, 0, -22, 5, rb)
	# 长直弹匣(握把前面，微微前倾)
	for z in range(-10, 2):
		var dy: int = int(round(float(1 - z) * 0.18))
		B(-1, -9 - dy, z, 0, -6 - dy, z, bk2 if z > -9 else gm)
	# 折叠枪托：机匣后面一截镂空的框
	B(-1, 6, 6, 0, 12, 7, gm)
	B(-1, 6, 2, 0, 12, 3, gm)
	B(-1, 12, 2, 0, 13, 7, bk2)
	_end()


## 突进时手里那把匕首(P_commando_knife，从目标身侧划过时用)：黑色缠绳刀柄 + 护手，钢刃(深色刃背、亮色刃口)，刀背一排锯齿。刃沿 +Y
func commando_knife() -> void:
	_begin(false)
	var hd := VGrid.hexc("#22242a")
	var hd2 := VGrid.hexc("#3a3e46")
	var st := VGrid.hexc("#b9c0c9")
	var st2 := VGrid.hexc("#e6ebf0")
	var st3 := VGrid.hexc("#7d8590")
	B(-1, -6, -1, 0, 3, 0, hd)
	for y in range(-5, 3, 2):
		B(-1, y, -1, 0, y, 0, hd2)
	B(-1, -7, -1, 0, -7, 0, st3)
	B(-2, 4, -3, 1, 4, 2, st3)
	_blade(5, 22, 2.4, 1.0, -1, 0, st, st2, 6)
	for y2 in range(6, 15, 2):
		D(-1, y2, -2, st3)
		D(0, y2, -2, st3)
	_end()


# ====================================================================== 黑色战场(屏息节点的专属双手远程)
## 她角色卡上那把黑色狙击枪：细长的枪管(两条散热槽)、方头的大口径制退器(两侧开槽)，带导轨的方护木、枪管下折起的两脚架，
## 黑色机匣 + 右侧拉机柄、枪下的直弹匣，骨架式枪托(中间镂空、托腮板、橡胶托底)；机匣上一支粗瞄准镜(前后镜片发蓝光、上面和侧面各一个旋钮)。
## 枪械约定：-Y = 枪口，+Z = 上；枪托短(Q 版小短手，抵肩时别穿过后背)
func sniper_rifle() -> void:
	_begin(false)
	var bk := VGrid.hexc("#1f2126")
	var bk2 := VGrid.hexc("#30333a")
	var gm := VGrid.hexc("#474c55")
	var gm2 := VGrid.hexc("#666c77")
	var rb := VGrid.hexc("#141518")
	var bl := VGrid.hexc("#2f7dff")
	var bl2 := VGrid.hexc("#8fd0ff")
	# 握把(手枪式) + 扳机护圈
	B(-1, -1, -5, 0, 2, 2, bk2)
	B(-1, 3, -4, 0, 3, 2, bk2)
	B(-1, -5, 0, 0, -5, 2, gm)
	B(-1, -4, 0, 0, -2, 0, gm)
	D(-1, -3, 1, gm2)
	# 机匣 + 右侧拉机柄(往外伸、末端一个圆球)
	B(-2, -12, 2, 1, 6, 6, bk)
	B(-2, -11, 6, 1, 5, 6, bk2)
	B(-3, 1, 4, -3, 2, 5, gm)
	B(-5, 1, 4, -4, 2, 4, gm)
	B(-6, 0, 3, -5, 2, 5, gm2)
	# 直弹匣(握把前面)
	B(-1, -9, -4, 0, -6, 1, bk2)
	B(-1, -9, -5, 0, -6, -5, gm)
	# 护木：方形，顶上一条导轨，两侧几个散热孔
	B(-2, -32, 1, 1, -13, 5, bk)
	for y in range(-31, -13, 2):
		B(-1, y, 6, 0, y, 6, gm)
	for y2 in range(-29, -15, 4):
		D(-3, y2, 3, rb)
		D(2, y2, 3, rb)
	# 枪管：细长，两条散热槽
	B(-1, -56, 3, 0, -33, 4, gm)
	for y3 in range(-54, -35, 3):
		D(-1, y3, 4, gm2)
	# 制退器：方头，两侧开槽
	B(-2, -60, 2, 1, -57, 5, bk2)
	for y4: int in [-59, -58]:
		B(-2, y4, 3, -2, y4, 4, rb)
		B(1, y4, 3, 1, y4, 4, rb)
	B(-1, -60, 3, 0, -60, 4, rb)
	# 两脚架：折在枪管下面的两条腿
	B(-2, -31, 0, -2, -18, 0, gm)
	B(1, -31, 0, 1, -18, 0, gm)
	B(-2, -32, -1, 1, -32, 0, bk2)
	# 瞄准镜：粗镜筒 + 前后镜座加粗，前后镜片发蓝光，上面 / 侧面两个旋钮，两个镜环架在机匣上
	B(-2, -22, 8, 1, -7, 11, bk)
	B(-3, -27, 7, 2, -23, 12, bk2)
	B(-3, -6, 7, 2, -3, 12, bk2)
	B(-2, -28, 8, 1, -28, 11, bl, 110)
	D(-1, -28, 10, bl2, 160)
	B(-2, -2, 8, 1, -2, 11, bl, 70)
	B(-1, -16, 12, 0, -14, 13, gm)
	B(2, -16, 9, 3, -14, 10, gm)
	for my: int in [-20, -9]:
		B(-1, my, 7, 0, my + 1, 7, gm)
	# 骨架枪托：上梁 + 下梁，中间镂空，托腮板，橡胶托底
	for y5 in range(7, 18):
		var t: float = float(y5 - 7) / 10.0
		var zlo: int = int(round(lerpf(1.0, -3.0, t)))
		B(-1, y5, 4, 0, y5, 6, bk)
		B(-1, y5, zlo, 0, y5, zlo + 1, bk)
	B(-1, 7, 2, 0, 8, 4, bk)
	B(-1, 10, 7, 0, 15, 7, bk2)
	B(-2, 18, -3, 1, 19, 6, rb)
	_end()


# ====================================================================== 驱动加农(改修节点的专属双手远程)
## 他角色卡上那把紫色步枪：棕色木托(深色木纹)、黄铜机匣上嵌一颗紫宝石，钢管上面一道发光的紫色导能管、黄铜箍，
## 枪口黄铜、口里一圈紫光；机匣上一截黄铜瞄具；枪管下面挂一个黄铜环 + 紫水晶坠子。枪械约定：-Y = 枪口，+Z = 上
func drive_rifle() -> void:
	_begin(false)
	var wd := VGrid.hexc("#7a4626")
	var wd2 := VGrid.hexc("#5a311a")
	var br := VGrid.hexc("#c8963a")
	var br2 := VGrid.hexc("#e6b95a")
	var br3 := VGrid.hexc("#8e6420")
	var st := VGrid.hexc("#9aa0aa")
	var st2 := VGrid.hexc("#6c727c")
	var vi := VGrid.hexc("#7a2ee0")
	var vi2 := VGrid.hexc("#a86bff")
	# 握把 + 扳机护圈(黄铜)
	B(-1, -1, -4, 0, 2, 3, wd2)
	B(-1, 3, -3, 0, 3, 3, wd2)
	B(-1, -1, -5, 0, 3, -5, br)
	B(-1, -5, 1, 0, -5, 3, br3)
	B(-1, -4, 1, 0, -2, 1, br3)
	# 机匣：黄铜，两侧各嵌一颗紫宝石
	B(-2, -10, 2, 1, 6, 6, br)
	B(-2, -9, 6, 1, 5, 6, br2)
	B(-3, -4, 3, -3, -1, 5, vi, 50)
	B(2, -4, 3, 2, -1, 5, vi, 50)
	D(-3, -3, 4, vi2, 80)
	D(2, -3, 4, vi2, 80)
	# 瞄具：一截黄铜管
	B(-1, -9, 7, 0, -2, 8, br3)
	B(-1, -10, 7, 0, -10, 8, vi2, 60)
	# 枪管：钢，上面一道发光的紫色导能管
	B(-1, -50, 3, 0, -11, 4, st)
	for y in range(-50, -11, 5):
		D(-1, y, 3, st2)
	for y2 in range(-44, -11):
		B(-1, y2, 5, 0, y2, 5, vi if (y2 % 3) != 0 else vi2, 45 if (y2 % 3) != 0 else 70)
	for ry: int in [-46, -32, -18]:
		B(-2, ry, 2, 1, ry + 1, 6, br)
	# 枪口：黄铜，口里紫光
	B(-2, -54, 2, 1, -51, 5, br2)
	B(-1, -55, 3, 0, -55, 4, vi2, 90)
	# 护木(左手托在下面)
	B(-1, -34, 0, 0, -11, 2, wd)
	B(-2, -30, 0, 1, -14, 1, wd2)
	# 枪托：向后(+y)并向下加深，深色木纹，黄铜托底
	for y3 in range(7, 18):
		var t: float = float(y3 - 7) / 10.0
		var zlo: int = int(round(lerpf(1.0, -3.0, t)))
		B(-1, y3, zlo, 0, y3, 5, wd if (y3 % 4) != 1 else wd2)
	B(-2, 18, -3, 1, 19, 5, br)
	# 枪管下挂的紫水晶坠子(黄铜环 + 菱形水晶)
	B(-1, -38, -1, 0, -38, 2, br3)
	D(-1, -38, -2, br)
	for k in range(4):
		var w: int = 1 if k == 1 or k == 2 else 0
		B(-1 - w, -38, -3 - k, 0 + w, -38, -3 - k, vi if k != 1 else vi2, 50)
	_end()


# ====================================================================== 特殊款：猎手重弩(步枪大类 = 双手远程)
## 连射节点那把弩：粗木弩身 + 金箍，弩臂横向展开、两端后弯，上弦的弩箭(钢头 + 红羽)，弩身下挂一条红色流苏。
func arbalest() -> void:
	_begin(false)
	var wd := VGrid.hexc("#7b4a2a")
	var wd2 := VGrid.hexc("#9c6337")
	var wd3 := VGrid.hexc("#4e2e1a")
	var au := _c("gold")
	var au2 := _c("gold2")
	var au3 := _c("gold3")
	var red := VGrid.hexc("#c3322f")
	var red2 := VGrid.hexc("#8e1f22")
	var cord := VGrid.hexc("#e6e1d6")
	# 握把 + 扳机护圈
	B(-1, -1, -5, 0, 3, 3, wd3)
	B(-1, -1, -6, 0, 3, -6, au)
	B(-1, -5, 0, 0, -5, 3, au3)
	B(-1, -4, 0, 0, -2, 0, au3)
	D(-1, -3, 1, _c("iron2"))
	# 弩身：枪托在后(+y，向下加深)，弩身向前(-y)
	for y in range(-40, 17):
		var zlo: int = 2 if y < 6 else int(round(lerpf(2.0, -3.0, float(y - 6) / 10.0)))
		B(-2, y, zlo, 1, y, 6, wd if ((y + 40) % 7) < 5 else wd2)
	B(-2, 17, -3, 1, 18, 6, au)
	for ry: int in [-38, -25, -12, 5]:
		B(-3, ry, 1, 2, ry, 7, au)
	B(-3, -30, 2, -3, -18, 5, au3)
	B(2, -30, 2, 2, -18, 5, au3)
	# 弦槽
	B(-1, -38, 7, 0, -10, 7, wd3)
	# 弩臂：y≈-36 横向展开，两端向后弯
	for x in range(-19, 19):
		var t: float = absf(float(x) + 0.5) / 19.0
		var off: int = int(round(t * t * 7.0))
		B(x, -37 + off, 4, x, -35 + off, 6, wd2 if t > 0.2 else wd)
	B(-21, -31, 3, -19, -28, 6, au)
	B(18, -31, 3, 20, -28, 6, au)
	D(-21, -29, 7, au2)
	D(20, -29, 7, au2)
	# 弦：两端 → 弦扣
	for i in range(0, 21):
		var t2: float = float(i) / 20.0
		var x2: int = int(round(lerpf(-19.0, -1.0, t2)))
		var y2: int = int(round(lerpf(-29.0, -12.0, t2)))
		D(x2, y2, 8, cord)
		D(-1 - x2, y2, 8, cord)
	B(-2, -13, 7, 1, -11, 8, au3)
	# 上弦的弩箭
	B(-1, -47, 8, 0, -12, 8, VGrid.hexc("#b08557"))
	B(-1, -50, 8, 0, -48, 8, _c("iron2"))
	D(-1, -51, 8, _c("iron3"))
	B(-2, -16, 9, 1, -13, 9, red)
	B(-1, -16, 10, 0, -14, 10, red2)
	# 前端金护套
	B(-2, -41, 2, 1, -40, 7, au)
	# 红色流苏(挂在弩身下方)
	B(-1, -30, 0, 0, -30, 1, au2)
	B(-1, -30, -6, 0, -30, -1, red)
	B(-2, -30, -9, 1, -30, -7, red2)
	B(-1, -30, -10, 0, -30, -10, au)
	_end()


# ====================================================================== 特殊款：急救针筒(法器大类)
## 护理节点的针筒：粉白玻璃管里装着红色药液(微光)，两端金箍，前端钢针；尾部推杆、推板与指环；像枪一样向前平举。
func syringe() -> void:
	_begin(false)
	var glass := VGrid.hexc("#f4e8ee")
	var glass2 := VGrid.hexc("#ffffff")
	var liq := VGrid.hexc("#d8283a")
	var liq2 := VGrid.hexc("#f25a68")
	var au := _c("gold")
	var au2 := _c("gold2")
	var au3 := _c("gold3")
	var cz: float = 7.5
	# 管身：y -26..-4，药液在前段(-25..-9)，后段是空玻璃
	for y in range(-26, -3):
		for z in range(2, 14):
			for x in range(-6, 6):
				var dx: float = float(x) + 0.5
				var dz: float = float(z) + 0.5 - cz
				var r: float = sqrt(dx * dx + dz * dz)
				if r > 4.6:
					continue
				var c: int = glass
				var gl := 0
				if y <= -9 and y >= -25:
					c = liq
					gl = 30
					if dz > 2.4 and absf(dx + 1.0) < 1.2:
						c = liq2
						gl = 60
				if y == -9 or y == -25:
					c = glass2
				# 高光条 + 刻度
				if dz > 3.4 and absf(dx) < 1.0:
					c = glass2
					gl = 0
				if absf(dx - 4.0) < 0.9 and dz > -1.0 and dz < 1.0 and (y % 3) == 0 and y > -24:
					c = au2
					gl = 0
				g.cur_glow = gl
				g.put(x, y, z, c)
	g.cur_glow = 0
	# 两端金箍
	for ry: int in [-27, -3]:
		for z in range(1, 15):
			for x in range(-7, 7):
				var dx2: float = float(x) + 0.5
				var dz2: float = float(z) + 0.5 - cz
				if sqrt(dx2 * dx2 + dz2 * dz2) <= 5.3:
					g.put(x, ry, z, au if ry == -27 else au3)
	# 前端锥形接头 + 钢针
	g.seg(Vector3(0.0, -27.0, cz), Vector3(0.0, -31.0, cz), 2.6, 1.0, au2)
	g.seg(Vector3(0.0, -31.0, cz), Vector3(0.0, -42.0, cz), 0.7, 0.5, _c("iron2"))
	# 尾部：推杆 + 推板
	g.seg(Vector3(0.0, -3.0, cz), Vector3(0.0, 6.0, cz), 1.4, 1.4, _c("iron"))
	for z in range(3, 13):
		for x in range(-5, 5):
			var dx3: float = float(x) + 0.5
			var dz3: float = float(z) + 0.5 - cz
			if sqrt(dx3 * dx3 + dz3 * dz3) <= 4.0:
				g.put(x, 7, z, au)
	# 指环：管尾两侧各一个金环，推板后一个拇指环
	g.ring(Vector3(-6.5, -2.0, cz), Vector3(0, 1, 0), 2.3, 1.3, au)
	g.ring(Vector3(6.5, -2.0, cz), Vector3(0, 1, 0), 2.3, 1.3, au)
	g.ring(Vector3(0.0, 10.5, cz), Vector3(1, 0, 0), 2.6, 1.3, au2)
	_end()


## 赤焰战旗(狩胜节点的专属双手长武器)：她角色卡上那面燃烧的战旗长矛——红漆矛杆隔一段一道金箍，尾端金色尖头；
## 银色叶形矛头 + 金色托座；矛头下方一根金色横杆(两端金球)，挂着一面红色长旗：金色包边、正中一头金色的立狮，
## 旗的下摆和外缘烧着(焦黑的破边 + 发光的橙黄火舌与火星)。长柄武器约定：+Y 沿杆，握点在原点；旗面在 Y-Z 平面，往 +Z 一侧展开
const BANNER_LION := [
	"....XX....",
	"...XXXX...",
	"..XXXXX...",
	".XXXX.X...",
	"..XXX.....",
	"..XXXXXX..",
	".XXXXXXXX.",
	"XX.XXXX.XX",
	"...XXXX...",
	"..XX..XX..",
	".XX....XX.",
]


func banner() -> void:
	_begin(false)
	var lac := VGrid.hexc("#a8161e")
	var lac2 := VGrid.hexc("#7e1016")
	var au := _c("gold")
	var au2 := _c("gold2")
	var au3 := _c("gold3")
	var silver := VGrid.hexc("#d8dde6")
	var silver2 := VGrid.hexc("#9aa2ae")
	var cloth := VGrid.hexc("#c22630")
	var cloth2 := VGrid.hexc("#a01c26")
	var trim := VGrid.hexc("#e2a62a")
	var lion := VGrid.hexc("#f0c040")
	var char_c := VGrid.hexc("#3a1a14")
	var fire := VGrid.hexc("#ff6a1a")
	var fire2 := VGrid.hexc("#ffc23a")
	# 矛杆(红漆)、金箍、尾端金色尖头
	for y in range(-40, 63):
		B(-1, y, -1, 0, y, 0, lac if (y % 8) < 6 else lac2)
	for yb: int in [-32, -10, 8, 26, 44]:
		B(-2, yb, -2, 1, yb + 1, 1, au3 if yb != 8 else au)
	B(-2, -43, -2, 1, -41, 1, au)
	B(-1, -46, -1, 0, -44, 0, au2)
	# 矛头：金色托座 + 银色叶形刃(中线一道暗槽)
	B(-2, 62, -2, 1, 66, 1, au)
	B(-2, 64, -3, 1, 64, 2, au2)
	_blade(67, 88, 3.2, 1.2, -1, 0, silver, silver2, 8)
	for y2 in range(69, 84):
		D(-1, y2, -1, silver2)
	# 横杆(沿 +Z)，两端金球
	B(-1, 58, 0, 0, 59, 21, au)
	B(-2, 57, 21, 1, 60, 23, au2)
	B(-2, 57, -2, 1, 60, 1, au2)
	# 旗面：y 57 → 18，z 2 → 20；金色包边、金狮；下摆 / 外缘烧焦破边 + 火舌
	var top := 57
	var bot := 18
	for y3 in range(bot, top + 1):
		for z in range(2, 21):
			# 烧掉的部分：下摆往上 0~7 格不规则，外缘(z 大)越往下烧得越多
			var burn: float = 4.0 + 3.0 * sin(float(z) * 1.7) + 2.0 * sin(float(z) * 0.6 + 1.0) + maxf(0.0, float(z - 12)) * 0.9
			var depth: float = float(y3 - bot)
			if depth < burn - 1.0:
				continue
			var c: int = cloth if ((z + int(y3 / 3.0)) % 5) != 0 else cloth2
			var glow := 0
			if z == 2 or z == 20 or y3 == top or y3 == top - 1:
				c = trim
			if z == 4 or z == 18 or y3 == top - 3:
				c = trim if (y3 + z) % 2 == 0 else c
			if depth < burn + 0.6:
				c = char_c                               # 焦边
			elif depth < burn + 2.0 and (y3 + z) % 3 == 0:
				c = fire
				glow = 90
			B(0, y3, z, 0, y3, z, c, glow)
	# 金狮(正中，旗面两侧都有：x = 0 一层，-1 那面再贴一层)
	var lh: int = BANNER_LION.size()
	for r in range(lh):
		var row: String = BANNER_LION[r]
		for k in range(row.length()):
			if row[k] == "X":
				var ly: int = 50 - r
				var lz: int = 7 + k
				B(-1, ly, lz, 0, ly, lz, lion)
	# 火舌与火星：沿烧焦的破边往外窜(发光)
	for z2 in range(3, 21, 2):
		var burn2: float = 4.0 + 3.0 * sin(float(z2) * 1.7) + 2.0 * sin(float(z2) * 0.6 + 1.0) + maxf(0.0, float(z2 - 12)) * 0.9
		var ey: int = bot + int(burn2) - 1
		for k2 in range(1, 4 + (z2 % 3)):
			B(0, ey - k2, z2, 0, ey - k2, z2, fire2 if k2 > 1 else fire, 140 if k2 > 1 else 100)
	for sp: Vector3i in [Vector3i(0, 14, 9), Vector3i(0, 12, 15), Vector3i(0, 20, 22), Vector3i(0, 26, 23), Vector3i(0, 10, 19)]:
		B(sp.x, sp.y, sp.z, sp.x, sp.y, sp.z, fire2, 150)
	_end()


## 打工小帮手(空白节点的单手武器)：一把双头扳手——握在正中间(原点 = 握点)，中段裹着橙色防滑胶套；
## 往上(+Y)是开口扳手头(C 形钳口)，往下(-Y)是梅花扳手的圆环头。刃宽方向(z)当扳手的宽面。做得简单一点
func wrench() -> void:
	_begin(false)
	var steel := VGrid.hexc("#b8bfc8")
	var steel2 := VGrid.hexc("#8a929c")
	var steel3 := VGrid.hexc("#dfe4ea")
	var grip := VGrid.hexc("#f08a24")
	var grip2 := VGrid.hexc("#c86a14")
	# 杆身：x 2 格厚、z 3 格宽，y -20..20
	for y in range(-20, 21):
		B(-1, y, -1, 0, y, 1, steel if (y % 6) != 0 else steel2)
		D(-1, y, 1, steel3)
	# 中段胶套(握的地方)
	for y2 in range(-6, 7):
		B(-2, y2, -2, 1, y2, 2, grip if (y2 % 3) != 0 else grip2)
	# 上头：开口扳手(C 形钳口，开口朝 +Y)
	for y3 in range(21, 31):
		for z in range(-5, 6):
			var inner: bool = absi(z) <= 1 and y3 >= 24
			var edge: bool = absi(z) >= 4 and y3 >= 28
			if inner or (edge and y3 == 30 and absi(z) == 5):
				continue
			B(-1, y3, z, 0, y3, z, steel2 if absi(z) >= 4 else steel)
	# 下头：梅花扳手(圆环)
	for y4 in range(-30, -20):
		for z2 in range(-5, 6):
			var dy: float = float(y4) + 25.5
			var r: float = sqrt(dy * dy + float(z2) * float(z2))
			if r <= 5.3 and r >= 2.4:
				B(-1, y4, z2, 0, y4, z2, steel if r < 4.4 else steel2)
	_end()


## 如律所令(清心节点的法器)：她角色卡上手里那张黄符——米黄色的长条符纸，红色描边，正中一个红色的符文(竖笔 + 几道横笔)，
## 顶端一个小红点；纸面竖在拳头上方(法器约定：+Z 朝上)，两指夹着下端。做得简单一点
func talisman() -> void:
	_begin(false)
	var paper := VGrid.hexc("#f2dc9a")
	var paper2 := VGrid.hexc("#e6c97a")
	var ink := VGrid.hexc("#c8282a")
	# 纸面：x = 0 一层，y -4..4(宽)，z 3..24(高)
	for z in range(3, 25):
		for y in range(-4, 5):
			var c: int = paper if (y + z) % 5 != 0 else paper2
			if absi(y) == 4 or z == 3 or z == 24:
				c = ink
			# 符文：中间一道竖笔，几道横笔，顶上一个点
			if y == 0 and z >= 6 and z <= 20:
				c = ink
			if (z == 18 or z == 14 or z == 10) and absi(y) <= 2:
				c = ink
			if z == 22 and absi(y) <= 1:
				c = ink
			if (z == 7 and (y == -2 or y == 2)):
				c = ink
			B(0, y, z, 0, y, z, c)
	_end()


## 转瞬即逝(浪游节点的单手远程)：他角色卡上那把左轮——银色长枪管(上面一条准星)、银色转轮(一圈弹仓孔、金色中轴)、金色护圈与击锤，
## 棕色木握把(金铆钉)。枪械约定：-Y = 枪口方向，+Z = 枪的上方，握把沿 Z 穿过拳心
func revolver() -> void:
	_begin(false)
	var silver := VGrid.hexc("#c8ced8")
	var silver2 := VGrid.hexc("#9aa2ae")
	var silver3 := VGrid.hexc("#e8ecf2")
	var au := _c("gold")
	var au2 := _c("gold2")
	var wood := VGrid.hexc("#7a4a2a")
	var wood2 := VGrid.hexc("#5c3620")
	# 握把：从拳心往下(-Z)、略往后(+Y)
	for z in range(-6, 3):
		var off: int = int(round(float(-z) * 0.35))
		B(-1, off - 1, z, 0, off + 2, z, wood if (z % 3) != 0 else wood2)
	D(0, 1, -2, au)
	D(-1, 1, -2, au)
	B(-1, -1, -7, 0, 3, -7, au2)
	# 机匣 + 击锤
	B(-1, -4, 2, 0, 2, 5, silver2)
	B(-1, 1, 6, 0, 2, 7, silver)
	D(0, 3, 7, au)
	# 转轮：一圈 3×3 的银色圆柱，正面一点金色中轴
	for y in range(-8, -3):
		for z2 in range(2, 8):
			for x in range(-2, 2):
				var dz: float = float(z2) - 4.5
				var dx: float = float(x) + 0.5
				if dz * dz + dx * dx <= 7.0:
					B(x, y, z2, x, y, z2, silver if (y + z2) % 3 != 0 else silver3)
	D(0, -9, 4, au)
	# 枪管(长、略细)，上沿一条准星
	for y2 in range(-26, -8):
		B(-1, y2, 4, 0, y2, 6, silver if (y2 % 5) != 0 else silver2)
		D(0, y2, 7, silver3)
	B(-1, -26, 7, 0, -25, 8, silver2)
	# 护圈(扳机护弓)
	B(-1, -3, 0, 0, -3, 1, au)
	B(-1, -6, 0, 0, -4, 0, au)
	_end()


## 炽霞(炽照节点)：太刀。黑柄(柄卷露出一排金色菱形)、金色椭圆刀镡、金色刀铓，银白刀身带一点弧度(刃朝 +Z、刀尖往 -Z 弯)，刃口一条更亮的刃纹
const KATANA_BLADE := [8, 57]                             # 刀身(局部 Y 范围)
const KATANA_ENTER := 7.0                                 # 插进鞘里时，刀镡外侧 = 鞘口：握点 = 鞘口 - 鞘方向 × 7


func katana() -> void:
	_begin(false)
	var blk := VGrid.hexc("#1d1b20")
	var blk2 := VGrid.hexc("#2c2930")
	var au := _c("gold")
	var au2 := _c("gold2")
	var au3 := _c("gold3")
	var steel := VGrid.hexc("#d9dee6")
	var steel2 := VGrid.hexc("#aab1bc")
	var edge := VGrid.hexc("#f6f8fb")
	# 柄头(金)
	B(-1, -14, -1, 0, -13, 1, au)
	D(0, -15, 0, au2)
	# 柄：黑色柄卷，正反两面露出金色菱形(隔 4 格一个，中间一格 + 上下两侧各一格)
	for y in range(-12, 4):
		for z in range(-1, 2):
			var c: int = blk if (y + z + 20) % 2 == 0 else blk2
			var k: int = (y + 20) % 4
			if (k == 0 and z == 0) or (k == 2 and z != 0):
				c = au
			B(-1, y, z, 0, y, z, c)
	# 刀镡：金色椭圆(z 方向长)，外圈暗金
	for z2 in range(-4, 5):
		for x in range(-3, 3):
			var dz: float = float(z2) / 4.3
			var dx: float = (float(x) + 0.5) / 2.9
			var r2: float = dz * dz + dx * dx
			if r2 <= 1.0:
				B(x, 4, z2, x, 5, z2, au3 if r2 > 0.6 else au)
	# 刀铓
	B(-1, 6, -1, 0, 7, 1, au2)
	# 刀身：宽 3 格收到 2 格，往 -Z 弯(刀尖处弯出 3 格)；+Z 一侧是刃口，-Z 一侧是刀背
	var y0: int = KATANA_BLADE[0]
	var y1: int = KATANA_BLADE[1]
	for y2 in range(y0, y1 + 1):
		var t: float = float(y2 - y0) / float(y1 - y0)
		var bend: int = int(round(3.0 * t * t))
		var w: int = 3 if t < 0.7 else 2
		var za: int = -1 - bend
		var zb: int = za + w - 1
		if y2 > y1 - 4:
			# 刀尖(切先)：从刀背斜着收到刃口
			za = zb - maxi(0, y1 - y2)
		for z3 in range(za, zb + 1):
			var c2: int = steel
			if z3 == zb:
				c2 = edge
			elif z3 == za and w == 3:
				c2 = steel2
			B(-1, y2, z3, 0, y2, z3, c2)
	_end()


## 炽霞的刀鞘：挂在髋骨上(不在手里)——插在腰带左前，鞘口朝前，往左后下方斜伸出去(参考图：黑漆分节、金色鞘口与鞘尾、红色下绪绕在鞘口后面垂一束流苏)。
## 静止坐标里雕(和 tools/chars 的身体一样)；拔刀术的动作用同一组常量把刀插回鞘里
const SAYA_MOUTH := Vector3(3.5, 50.0, 8.0)              # 插在腰带左前(腰绳结旁边)：再往左右手就够不着刀柄了
const SAYA_DIR := Vector3(0.30, -0.42, -0.86)            # 鞘口 → 鞘尾(用的时候先归一化)：往左后下方斜伸出去
const SAYA_LEN := 52


static func saya_dir() -> Vector3:
	return SAYA_DIR.normalized()


## 刀插在鞘里时刀的"刃宽"方向(局部 +Z)：刃朝上
static func saya_side() -> Vector3:
	var d: Vector3 = saya_dir()
	return (Vector3.UP - d * d.y).normalized()


func katana_saya() -> void:
	g.sym = false
	g.mode = VGrid.FILL
	g.cur_glow = 0
	g.tx = 0
	g.ty = 0
	g.tz = 0
	g.use("Hips")
	var lac := VGrid.hexc("#1d1b20")
	var lac2 := VGrid.hexc("#2e2a31")
	var au := _c("gold")
	var au2 := _c("gold2")
	var red := VGrid.hexc("#b3262f")
	var red2 := VGrid.hexc("#861b25")
	var d: Vector3 = saya_dir()
	var side: Vector3 = saya_side()
	var lat: Vector3 = d.cross(side).normalized()
	for i in range(0, SAYA_LEN + 1):
		# 和刀身一样带弧度：刀插在里面时刃朝上，刀尖往下弯(刀身 y 8..57 对应鞘里 1..50)
		var bt: float = clampf(float(i - 1) / float(KATANA_BLADE[1] - KATANA_BLADE[0]), 0.0, 1.0)
		var c: Vector3 = SAYA_MOUTH + d * float(i) - side * (3.0 * bt * bt)
		var col: int = lac if (i / 4) % 2 == 0 else lac2           # 黑漆分节
		if i <= 2 or i >= SAYA_LEN - 2:
			col = au if i != 1 and i != SAYA_LEN - 1 else au2       # 鞘口 / 鞘尾的金饰
		var half_s: float = 2.2 if i < SAYA_LEN - 3 else 1.6       # 刃宽方向(刀身宽 3 格)
		var half_l: float = 1.3                                    # 厚度方向(刀身厚 2 格)
		for a in range(-4, 5):
			for bb in range(-2, 3):
				var q: Vector3 = c + side * (float(a) * 0.25 * half_s) + lat * (float(bb) * 0.5 * half_l)
				g.put(int(floor(q.x)), int(floor(q.y)), int(floor(q.z)), col)
	# 下绪：鞘口后面绕两圈红绳，垂下一束流苏
	for i2 in [5, 7]:
		var c2: Vector3 = SAYA_MOUTH + d * float(i2)
		for a2 in range(0, 12):
			var ang: float = TAU * float(a2) / 12.0
			var q2: Vector3 = c2 + side * (cos(ang) * 2.0) + lat * (sin(ang) * 2.0)
			g.put(int(floor(q2.x)), int(floor(q2.y)), int(floor(q2.z)), red if a2 % 3 != 0 else red2)
	var knot: Vector3 = SAYA_MOUTH + d * 6.0 - side * 2.2
	for k in range(0, 9):
		var q3: Vector3 = knot + Vector3(0, -float(k), 0) + d * float(k) * 0.15
		g.put(int(floor(q3.x)), int(floor(q3.y)), int(floor(q3.z)), red2 if k == 0 else red)
		if k >= 5:
			g.put(int(floor(q3.x)) + 1, int(floor(q3.y)), int(floor(q3.z)), red2)
	_end()


## 狩猎旗标(狩胜节点带来的特殊物品，不能佩戴)：一根短短的金头红杆，挂一面三角形的红色小旗，旗上一个金色的爪印；
## 只用来做图标和敌人头顶的标记。+Y 沿杆，握点在原点，旗往 +Z 展开
const PAW := [".X.X.", "X...X", ".XXX.", "XXXXX", ".XXX."]


## 某已不知名的星星的旗帜(星旅节点的专属双手长武器)：她角色卡上那面旗——棕色木杆、顶上金色圆头，杆上一道蓝箍；
## 旗面直接挂在杆子上半段、往一侧(+Z)飘出去：白底、蓝色包边，正中金色盾徽(盾里蓝底金十字、顶上一个小十字、两侧金色月桂枝)。
## 旗面沿 z 起伏一点(x 方向前后错一格)，像在风里飘。长柄武器约定：+Y 沿杆身，握点在原点
const STARFLAG_CREST := [
	".......C.......",
	"......CCC......",
	".......C.......",
	"....GGGGGGG....",
	"....GBBGBBG....",
	"....GBBGBBG....",
	"....GGGGGGG....",
	"L...GBBGBBG...L",
	"L...GBBGBBG...L",
	".L...GBGBG...L.",
	"..L...GGG...L..",
	"...LL..G..LL...",
	".....LLLLL.....",
]


func starflag() -> void:
	_begin(false)
	var wd := VGrid.hexc("#7a4a26")
	var wd2 := VGrid.hexc("#5e3719")
	var au := _c("gold")
	var au2 := _c("gold2")
	var au3 := _c("gold3")
	var blue := VGrid.hexc("#2f5fd0")
	var blue2 := VGrid.hexc("#2349a8")
	var wht := VGrid.hexc("#f4f4f2")
	var wht2 := VGrid.hexc("#dcdde2")
	var crest_b := VGrid.hexc("#2a54c4")
	var laurel := VGrid.hexc("#c8962e")
	# 木杆 + 顶上金色圆头 + 杆尾金箍；旗面下沿处一道蓝箍
	for y in range(-42, 66):
		B(-1, y, -1, 0, y, 0, wd if (y % 7) < 5 else wd2)
	B(-2, 66, -2, 1, 66, 1, au3)
	B(-2, 67, -2, 1, 69, 1, au)
	B(-1, 70, -1, 0, 70, 0, au2)
	B(-2, -45, -2, 1, -43, 1, au)
	B(-2, 30, -2, 1, 32, 1, blue)
	# 旗面：y 33..64，z 1..26；顶边、底边随 z 起一点波，x 方向按 z 前后错一格(飘动)
	for z in range(1, 27):
		var wave: int = int(round(1.4 * sin(float(z) * 0.42)))
		var xo: int = 0 if sin(float(z) * 0.42 + 0.8) > -0.25 else -1
		var top: int = 64 + wave
		var bot: int = 33 + wave
		for y2 in range(bot, top + 1):
			var edge: bool = y2 >= top - 1 or y2 <= bot + 1 or z >= 25
			var c: int = blue if edge else (wht if (y2 + z) % 6 != 0 else wht2)
			if edge and (y2 + z) % 5 == 0:
				c = blue2
			B(xo, y2, z, xo, y2, z, c)
	# 盾徽：两面都贴(x = -1 和 0 两层都是旗面，徽记画在旗面上)
	var rows: int = STARFLAG_CREST.size()
	for r in range(rows):
		var row: String = STARFLAG_CREST[r]
		for k in range(row.length()):
			var ch: String = row[k]
			if ch == ".":
				continue
			var cz: int = 6 + k
			var wave2: int = int(round(1.4 * sin(float(cz) * 0.42)))
			var cy: int = 55 + wave2 - r
			var xo2: int = 0 if sin(float(cz) * 0.42 + 0.8) > -0.25 else -1
			var cc: int = au if ch == "G" or ch == "C" else (crest_b if ch == "B" else laurel)
			B(xo2 - 1, cy, cz, xo2 + 1, cy, cz, cc)
	_end()


## 正花(正行节点的专属双手长武器)：缠着花藤与花瓣、末端绽放一朵百合的长枪。
## 银白枪杆 + 金箍、棕色皮握把(两只手的位置同华丽长枪)；一条绿藤从杆尾螺旋缠到枪头，藤上开着粉 / 紫小花、冒出几片叶子；
## 枪头 = 金色花托托着一朵大白百合(6 瓣：内轮 3 瓣宽、外轮 3 瓣窄，喇叭形的花筒往外翻卷，花筒里淡黄、往外渐白)，
## 6 根花丝顶着橙黄的花药，一把细长的银刃(金色刃芯微微发光)从花心直直伸出去；花托下两片百合叶，旁边飘着几片粉色花瓣。
## 颜色全用固定色值(不用 cyan 强调色)：它是黄色武器，但金 / 白 / 花色要保持原样。长柄武器约定：+Y 沿杆身，握点在原点
const LILY_BASE := 63                                     # 百合花瓣根部的局部 Y(花托顶)


func lily_spear() -> void:
	_begin(false)
	var sh := VGrid.hexc("#e6e8ee")
	var sh2 := VGrid.hexc("#c9ced8")
	var au := VGrid.hexc("#d9a441")
	var au2 := VGrid.hexc("#f2cf6e")
	var au3 := VGrid.hexc("#a8782c")
	var lea := VGrid.hexc("#6a4129")
	var lea2 := VGrid.hexc("#865535")
	var vine := VGrid.hexc("#4b8c3c")
	var vine2 := VGrid.hexc("#35692d")
	var leaf := VGrid.hexc("#63ac4d")
	var leaf2 := VGrid.hexc("#86c766")
	var pink := VGrid.hexc("#f07aa6")
	var pink2 := VGrid.hexc("#ffb3cf")
	var purp := VGrid.hexc("#a66ce0")
	var purp2 := VGrid.hexc("#d0a8f6")
	# ---- 枪杆(银白，隔一段深一点) + 杆尾金镦(尖)
	for y in range(-38, LILY_BASE - 1):
		B(-1, y, -1, 0, y, 0, sh if (y % 9) < 6 else sh2)
	B(-2, -41, -2, 1, -39, 1, au)
	B(-1, -44, -1, 0, -42, 0, au2)
	for ry: int in [-30, 40]:
		B(-2, ry, -2, 1, ry + 1, 1, au)
	# ---- 绿藤：从杆尾附近一路螺旋缠到花托(半径 1.9 = 贴着杆子的那一圈)
	var vy0 := -35.0
	var vy1 := float(LILY_BASE - 3)
	var per := 13.0
	var yy := vy0
	while yy <= vy1:
		var a: float = (yy - vy0) / per * TAU
		var px := 1.9 * cos(a)
		var pz := 1.9 * sin(a)
		D(int(floor(px)), int(floor(yy)), int(floor(pz)), vine if int(floor(yy)) % 4 != 0 else vine2)
		yy += 0.2
	# 握把(右手 -4..5、左手 14..22，同华丽长枪)：棕色皮绳，两端金箍；藤从皮绳底下穿过
	for gr: Array in [[-4, 5], [14, 22]]:
		for y2 in range(int(gr[0]), int(gr[1]) + 1):
			B(-2, y2, -2, 1, y2, 1, lea if (y2 % 2) == 0 else lea2)
		B(-2, int(gr[0]) - 1, -2, 1, int(gr[0]) - 1, 1, au3)
		B(-2, int(gr[1]) + 1, -2, 1, int(gr[1]) + 1, 1, au3)
	# 藤上的小花(粉 / 紫交替)与叶子：开在藤经过的地方，花盘朝外、略朝上
	var blooms: Array = [[-33, 0], [-24, 1], [-16, 0], [28, 1], [34, 0], [41, 1], [47, 0], [52, 1], [57, 0]]
	for bl: Array in blooms:
		var by: float = float(bl[0])
		var a2: float = (by - vy0) / per * TAU
		var n := Vector3(cos(a2), 0.45, sin(a2)).normalized()
		var big: bool = by > 40.0
		var cpos := Vector3(2.6 * cos(a2), by + 0.5, 2.6 * sin(a2))
		if int(bl[1]) == 0:
			_lily_blossom(cpos, n, 2.0 if big else 1.7, pink, pink2)
		else:
			_lily_blossom(cpos, n, 2.0 if big else 1.7, purp, purp2)
	for lf: float in [-29.0, -20.0, 25.0, 31.0, 37.5, 44.0, 49.5, 55.0]:
		var a3: float = (lf - vy0) / per * TAU + 0.6
		var o := Vector3(1.9 * cos(a3), lf, 1.9 * sin(a3))
		_lily_leaf(o, Vector3(cos(a3), 0.9, sin(a3)), 4.0, leaf, leaf2)
	# ---- 花托：金箍 + 往外张开的 6 片金色萼片(托在每片花瓣下面)
	B(-2, LILY_BASE - 5, -2, 1, LILY_BASE - 3, 1, au)
	B(-2, LILY_BASE - 2, -2, 1, LILY_BASE - 2, 1, au2)
	for i in range(6):
		var th: float = PI * 0.5 + TAU * float(i) / 6.0
		var er := Vector2(cos(th), sin(th))
		for k in range(4):
			var rr: float = 1.6 + float(k) * 0.75
			var cy: int = LILY_BASE - 2 + k / 2
			D(int(floor(er.x * rr)), cy, int(floor(er.y * rr)), au if k < 3 else au2)
	# 花托下两片长长的百合叶(斜着往外上方伸)
	for side: float in [0.0, PI]:
		var th2: float = side + 0.35
		_lily_leaf(Vector3(1.6 * cos(th2), float(LILY_BASE - 6), 1.6 * sin(th2)), Vector3(cos(th2), 0.75, sin(th2)), 9.0, leaf, leaf2)
	# ---- 枪刃：从花心伸出的细长银刃(柳叶形)，刃口淡金，刃芯一道金色(微微发光)
	_lily_blade(LILY_BASE, 95)
	# ---- 百合：先外轮(窄、低一点)，再内轮(宽)
	for i2 in range(6):
		var th3: float = PI * 0.5 + TAU * float(i2) / 6.0
		if i2 % 2 == 1:
			_lily_petal(th3, float(LILY_BASE) - 0.5, 1.5, 20.0, 3.6, 0.18, 3.35, 2.8, 0.7)
	for i3 in range(6):
		var th4: float = PI * 0.5 + TAU * float(i3) / 6.0
		if i3 % 2 == 0:
			_lily_petal(th4, float(LILY_BASE), 1.3, 22.0, 4.5, 0.1, 3.35, 2.9, 1.0)
	# 花丝 + 花药(6 根，夹在花瓣之间，往外上方张开)
	var fil := VGrid.hexc("#e3ecbf")
	var anth := VGrid.hexc("#e8902a")
	var anth2 := VGrid.hexc("#f6bb3e")
	for i4 in range(6):
		var th5: float = PI * 0.5 + TAU * (float(i4) + 0.5) / 6.0
		var er2 := Vector2(cos(th5), sin(th5))
		var tip := Vector3.ZERO
		for k2 in range(0, 25):
			var s: float = float(k2) / 24.0
			var rr2: float = 1.3 + 4.4 * pow(s, 1.4)
			var py: float = float(LILY_BASE) + 1.0 + 13.5 * s
			tip = Vector3(er2.x * rr2, py, er2.y * rr2)
			D(int(floor(tip.x)), int(floor(tip.y)), int(floor(tip.z)), fil)
		var et := Vector2(-er2.y, er2.x)
		for k3 in range(-1, 2):
			var q := tip + Vector3(et.x * 0.8 * k3, 0.6, et.y * 0.8 * k3)
			D(int(floor(q.x)), int(floor(q.y)), int(floor(q.z)), anth2 if k3 == 0 else anth, 12)
	# ---- 落在藤上的散花瓣(贴着杆子的几片粉 / 紫小花瓣)
	for pt: Array in [[31.0, 2.4], [44.5, 0.9], [-27.0, 3.6], [55.5, 4.4], [37.0, 5.2]]:
		var py2: float = float(pt[0])
		var ap: float = float(pt[1])
		var q2 := Vector3(1.9 * cos(ap), py2, 1.9 * sin(ap))
		D(int(floor(q2.x)), int(floor(q2.y)), int(floor(q2.z)), pink2 if int(py2) % 2 == 0 else purp2)
	_end()


## 正花的枪刃：柳叶形(根部窄、中段最宽、收成长尖)；x 厚 2 格，刃宽沿 z
func _lily_blade(y0: int, y1: int) -> void:
	var bs := VGrid.hexc("#e6eaf1")
	var bs2 := VGrid.hexc("#d0d6e1")
	var edge := VGrid.hexc("#fafbfd")
	var core := VGrid.hexc("#eec258")
	var keys: Array = [[y0, 1.2], [y0 + 8, 1.8], [y0 + 15, 2.9], [y0 + 23, 2.5], [y0 + 28, 1.4], [y1, 0.5]]
	for y in range(y0, y1 + 1):
		var half: float = 0.5
		for k in range(keys.size() - 1):
			var ka: Array = keys[k]
			var kb: Array = keys[k + 1]
			if y >= int(ka[0]) and y <= int(kb[0]):
				var t: float = float(y - int(ka[0])) / maxf(1.0, float(int(kb[0]) - int(ka[0])))
				half = lerpf(float(ka[1]), float(kb[1]), smoothstep(0.0, 1.0, t))
		var za: int = int(floor(-half))
		var zb: int = int(ceil(half)) - 1
		for z in range(za, zb + 1):
			var c: int = bs if (y + z) % 7 != 0 else bs2
			var gl := 0
			if z == za or z == zb:
				c = edge if zb - za >= 3 else bs
			elif (z == -1 or z == 0) and zb - za >= 4 and y >= y0 + 9 and y <= y1 - 5:
				c = core
				gl = 12
			B(-1, y, z, 0, y, z, c, gl)


## 一片百合花瓣：沿中线 s∈[0,1] 从花心往外长，与杆轴的夹角从 phi0 弯到 phi1(> 90° = 往下翻卷；按 s^pw 变化，花筒长、瓣尖卷得急)；
## 半宽 wmax(两头尖)，两边往花里翘 lift(花瓣是凹的)。th = 花瓣的方位角(杆轴 = Y，x/z 平面里的角度)
func _lily_petal(th: float, y0: float, r0: float, L: float, wmax: float, phi0: float, phi1: float, pw: float, lift: float) -> void:
	var lw := VGrid.hexc("#fbf9f1")
	var lw2 := VGrid.hexc("#eeeadc")
	var mid := VGrid.hexc("#f3edd2")
	var lc := VGrid.hexc("#ece6d2")
	var lc2 := VGrid.hexc("#dde4b4")
	var thr := VGrid.hexc("#f4e6a0")
	var thr2 := VGrid.hexc("#dfe7a4")
	var er := Vector2(cos(th), sin(th))
	var et := Vector2(-sin(th), cos(th))
	var n_steps := 110
	var pts: Array = []
	var rho := r0
	var hy := y0
	for i in range(n_steps + 1):
		var s: float = float(i) / float(n_steps)
		var phi: float = phi0 + (phi1 - phi0) * pow(s, pw)
		pts.append([s, rho, hy, phi])
		rho += sin(phi) * L / float(n_steps)
		hy += cos(phi) * L / float(n_steps)
	for e: Array in pts:
		var s2: float = e[0]
		var w: float = maxf(0.45, wmax * sin(PI * pow(s2, 1.3)))
		if s2 < 0.12:
			w = maxf(w, 0.9)
		var nr: float = -cos(float(e[3]))
		var ny: float = sin(float(e[3]))
		var nt: int = int(ceil(w * 4.0))
		for j in range(-nt, nt + 1):
			var t: float = float(j) / 4.0
			if absf(t) > w:
				continue
			# 单层花瓣(1 格厚)：两边往花里翘(凹面)
			var cup: float = lift * pow(absf(t) / maxf(w, 0.6), 2.0) * minf(1.0, w)
			var off: float = -0.15 + cup
			var pr: float = float(e[1]) + nr * off
			var py: float = float(e[2]) + ny * off
			var x: float = er.x * pr + et.x * t
			var z: float = er.y * pr + et.y * t
			var c: int = lw
			if s2 < 0.14:
				c = lc2                      # 花筒根部：带点绿的奶油色
			elif s2 < 0.36 and (s2 < 0.29 or (j % 2) == 0):
				c = thr if s2 > 0.2 else thr2
			elif absf(t) > w - 0.6 and s2 > 0.3:
				c = lw2
			elif absf(t) < 0.4 and s2 < 0.8:
				c = mid
			elif s2 > 0.9:
				c = lc
			D(int(floor(x)), int(floor(py)), int(floor(z)), c)


## 藤上的小花：圆盘(5 瓣的缺口) + 黄色花心，法线 n 朝外
func _lily_blossom(c: Vector3, n: Vector3, r: float, pet: int, pet2: int) -> void:
	var fc := VGrid.hexc("#f7d65c")
	var nn: Vector3 = n.normalized()
	var t1: Vector3 = nn.cross(Vector3.UP if absf(nn.y) < 0.9 else Vector3.RIGHT).normalized()
	var t2: Vector3 = nn.cross(t1).normalized()
	var rm := int(ceil(r)) + 1
	for z in range(int(floor(c.z)) - rm, int(floor(c.z)) + rm + 1):
		for y in range(int(floor(c.y)) - rm, int(floor(c.y)) + rm + 1):
			for x in range(int(floor(c.x)) - rm, int(floor(c.x)) + rm + 1):
				var d := Vector3(x + 0.5, y + 0.5, z + 0.5) - c
				var h: float = d.dot(nn)
				if h < -0.8 or h > 0.6:
					continue
				var p: Vector3 = d - nn * h
				var rr: float = p.length()
				var ang: float = atan2(p.dot(t2), p.dot(t1))
				var lim: float = r * (0.8 + 0.2 * cos(ang * 5.0))
				if rr > lim:
					continue
				var col: int = pet
				if rr < 0.7:
					col = fc
				elif rr < r * 0.55:
					col = pet2
				D(x, y, z, col)


## 叶子：从 o 沿 dir 伸出 ln 格的细长叶(中段两格宽，尖端浅绿)
func _lily_leaf(o: Vector3, dir: Vector3, ln: float, c: int, c2: int) -> void:
	var d: Vector3 = dir.normalized()
	var side: Vector3 = d.cross(Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT).normalized()
	var steps: int = int(ln * 4.0)
	for i in range(steps + 1):
		var s: float = float(i) / float(steps)
		var q: Vector3 = o + d * (s * ln) + Vector3(0.0, -1.2 * s * s * ln / 9.0, 0.0)
		var col: int = c2 if s > 0.75 else c
		D(int(floor(q.x)), int(floor(q.y)), int(floor(q.z)), col)
		var w: float = 0.9 * sin(PI * s)
		if w > 0.45:
			var q2: Vector3 = q + side * 0.9
			D(int(floor(q2.x)), int(floor(q2.y)), int(floor(q2.z)), col)


## 翠绿之林(守林节点的专属双手长武器)：她角色卡上那根荒野萨满的木杖——扭结的深棕木杖身(树皮疙瘩、几处树瘤，两头微微扭动)，
## 一根黄绿的藤蔓从杖尾螺旋缠到杖顶、隔一段冒出几片绿叶(两只手的位置不长叶子)；杖顶的木头弯成一个圆环(也缠着藤、四周冒着叶子，
## 左上方伸出一截断枝)，环心由几根藤须托着一颗光润的翠绿宝珠(微微发光)；环的外沿垂着一根皮绳：金色小珠 + 红色大珠 + 一颗白色兽牙；
## 杖尾缠着藤、垂着两三片叶子。
## 颜色全用固定色值(不用 cyan 强调色)：它是绿色武器，可卡上棕木 + 黄绿藤 + 深绿叶 + 翠绿宝珠的层次要原样保留(换色只会把它们染成同一个色)。
## 长柄武器约定：+Y 沿杖身，握点在原点，-10..22 是两只手的位置(杖身是直的 2×2)；持枪姿势里杖差不多是横着拿的、武器 +Z ≈ 世界的下方，
## 所以圆环的中心略偏 -Z(横拿时在杖身的上方，同卡上的持杖图)、挂坠往 +Z(略往 -Y)垂
const VERDANT_CY := 73.5          # 圆环中心(局部 Y)
const VERDANT_CZ := -2.5          # 圆环中心(局部 Z)
const VERDANT_R := 9.6            # 圆环木头中线的半径
const VERDANT_ORB := 5.6          # 宝珠半径


func verdant_staff() -> void:
	_begin(false)
	var wd := VGrid.hexc("#734528")
	var wd2 := VGrid.hexc("#56331d")
	var wd3 := VGrid.hexc("#90603a")
	var wd4 := VGrid.hexc("#3f2416")
	var vine := VGrid.hexc("#8c9f3d")
	var vine2 := VGrid.hexc("#6a7f2d")
	var vine3 := VGrid.hexc("#adbf57")
	var cy := VERDANT_CY
	var cz := VERDANT_CZ
	# ---- 杖身：2×2 的木棍，两只手之外微微扭动；木纹深浅成竖条(按 2 格高的块随机)，手外面隔一段一个树皮疙瘩
	for y in range(-41, 66):
		var o := _verdant_off(y)
		for x in range(-1, 1):
			for z in range(-1, 1):
				var h: int = _vhash(x, y / 3, z)
				D(x + o.x, y, z + o.y, wd2 if h < 24 else (wd3 if h > 82 else wd))
		if (y < -10 or y > 22) and y < 60:
			for kk in range(2):
				if _vhash(kk, y / 2, 7) >= 45:
					continue
				var k: int = (_vhash(1, y / 2, 3 + kk) + kk * 2) % 4
				var sx: int = [1, -2, 0, -1][k]
				var sz: int = [-1, 0, 1, -2][k]
				var c0: int = wd2 if _vhash(y, kk, 1) < 45 else (wd if _vhash(y, kk, 1) < 80 else wd4)
				D(sx + o.x, y, sz + o.y, c0)
				if _vhash(y / 2, kk, 9) < 50:
					D(sx + o.x + (0 if sx == 1 or sx == -2 else 1), y, sz + o.y + (1 if sx == 1 or sx == -2 else 0), c0)
	# 树瘤：一圈鼓出来的深色树皮 + 一个更深的"眼"
	for ky: int in [-29, 31, 47]:
		var o2 := _verdant_off(ky)
		for dy in range(-1, 2):
			for x2 in range(-2, 2):
				for z2 in range(-2, 2):
					var rim: bool = x2 == -2 or x2 == 1 or z2 == -2 or z2 == 1
					var corner: bool = (x2 == -2 or x2 == 1) and (z2 == -2 or z2 == 1)
					if corner or (rim and dy != 0 and _vhash(x2, ky + dy, z2) < 55):
						continue
					D(x2 + o2.x, ky + dy, z2 + o2.y, wd2 if dy == 0 else wd)
		D(1 + o2.x, ky, -1 + o2.y, wd4)
		D(-2 + o2.x, ky, o2.y, wd4)
	# 杖尾：粗一圈的深色树根头
	var ob := _verdant_off(-41)
	for yb in range(-42, -38):
		for x3 in range(-2, 2):
			for z3 in range(-2, 2):
				var cn: bool = (x3 == -2 or x3 == 1) and (z3 == -2 or z3 == 1)
				if cn or (yb == -42 and (x3 == -2 or x3 == 1 or z3 == -2 or z3 == 1)):
					continue
				D(x3 + ob.x, yb, z3 + ob.y, wd4 if yb <= -41 else wd2)
	# ---- 圆环：杖顶的木头弯成一圈(半径随角度起伏 = 扭结)，截面在环面里 3 格、厚 2 格，偶尔鼓出一格树皮
	for y4 in range(int(cy) - 12, int(cy) + 13):
		for z4 in range(int(cz) - 12, int(cz) + 13):
			var dy4: float = float(y4) + 0.5 - cy
			var dz4: float = float(z4) + 0.5 - cz
			var th: float = atan2(dy4, dz4)
			var rc: float = _verdant_rc(th)
			var dr: float = sqrt(dy4 * dy4 + dz4 * dz4) - rc
			var seg: int = int(floor((th + PI) * rc / 2.5))
			for x4 in range(-2, 2):
				var bump: float = 0.3 if _vhash(seg, 5, x4) < 22 else 0.0
				var dx4: float = float(x4) + 0.5
				if pow(dr / (1.75 + bump), 2.0) + pow(dx4 / (1.05 + bump * 2.0), 2.0) > 1.0:
					continue
				var c4: int = wd
				var hh: int = _vhash(seg, x4, 2)
				if dr > 0.55 and dy4 > -2.0:
					c4 = wd3
				elif dr < -0.6:
					c4 = wd2
				if hh < 18:
					c4 = wd2
				elif bump > 0.0:
					c4 = wd4 if hh % 2 == 0 else wd2
				D(x4, y4, z4, c4)
	# 杖身接进圆环的地方：一团鼓起来的树瘤(像树枝分叉)
	var jth: float = -acos(-cz / VERDANT_R)
	var jy: float = cy + VERDANT_R * sin(jth)
	for y5 in range(int(jy) - 4, int(jy) + 4):
		for z5 in range(-4, 4):
			for x5 in range(-3, 3):
				var e := Vector3((float(x5) + 0.5) / 1.6, (float(y5) + 0.5 - jy + 0.6) / 3.0, (float(z5) + 0.5 - 0.3) / 2.4)
				if e.length_squared() <= 1.0:
					D(x5, y5, z5, wd2 if _vhash(x5, y5, z5) < 40 else wd)
	# 左上方伸出的一截断枝(树枝绕成环后的末梢)：2×2 收成 1 格
	var tth: float = deg_to_rad(138.0)
	var trad: Vector3 = Vector3(0.0, sin(tth), cos(tth))
	var ttan: Vector3 = Vector3(0.0, cos(tth), -sin(tth))
	var t0: Vector3 = Vector3(0.0, cy, cz) + trad * _verdant_rc(tth)
	var tdir: Vector3 = (trad * 0.75 + ttan * 0.65).normalized()
	var ttip: Vector3 = t0
	for i6 in range(0, 25):
		var s6: float = float(i6) / 24.0
		ttip = t0 + tdir * (s6 * 5.0)
		var w6: float = 1.0 if s6 < 0.7 else 0.5
		for xx in range(-1, 1):
			for zz: float in [-w6 * 0.5, w6 * 0.5]:
				if w6 < 0.9 and xx == -1:
					continue
				D(xx, int(floor(ttip.y)), int(floor(ttip.z + zz)), wd if s6 < 0.85 else wd3)
	# ---- 藤蔓：杖身上一条螺旋(半径 1.9 = 贴着杖身那一圈)，杖尾多缠两圈
	var vy := -38.0
	while vy <= 63.0:
		var yi: int = int(floor(vy))
		var o3 := _verdant_off(yi)
		var a: float = (vy + 38.0) / 12.0 * TAU
		var px: float = 1.9 * cos(a) + float(o3.x)
		var pz: float = 1.9 * sin(a) + float(o3.y)
		D(int(floor(px)), yi, int(floor(pz)), _verdant_vine(yi, a, vine, vine2, vine3))
		vy += 0.2
	vy = -37.0
	while vy <= -32.0:
		var yi2: int = int(floor(vy))
		var o4 := _verdant_off(yi2)
		var a2: float = (vy + 37.0) / 2.6 * TAU + 1.3
		D(int(floor(1.9 * cos(a2) + float(o4.x))), yi2, int(floor(1.9 * sin(a2) + float(o4.y))), _verdant_vine(yi2, a2, vine, vine2, vine3))
		vy += 0.12
	# 圆环上的藤：绕着环的木头缠 5 圈
	var tt := 0.0
	while tt < 1.0:
		var th2: float = jth + tt * TAU
		var rc2: float = _verdant_rc(th2)
		var ph: float = tt * 5.0 * TAU
		var rad: float = rc2 + 2.1 * cos(ph)
		var xr: float = 1.5 * sin(ph)
		D(int(floor(xr)), int(floor(cy + rad * sin(th2))), int(floor(cz + rad * cos(th2))), _verdant_vine(int(tt * 300.0), ph, vine, vine2, vine3))
		tt += 0.0012
	# 托着宝珠的藤须(从环的内沿伸到宝珠上)
	for tdeg: float in [72.0, 160.0, 250.0, 338.0]:
		var th3: float = deg_to_rad(tdeg)
		var r3: float = _verdant_rc(th3) - 1.2
		while r3 > VERDANT_ORB - 0.8:
			B(-1, int(floor(cy + r3 * sin(th3))), int(floor(cz + r3 * cos(th3))), 0, int(floor(cy + r3 * sin(th3))), int(floor(cz + r3 * cos(th3))), vine2 if r3 < VERDANT_ORB + 0.6 else vine)
			r3 -= 0.3
	# ---- 宝珠：光润的翠绿球(上前方一块高光、背光的一侧深)，整颗微微发光
	_verdant_orb(Vector3(0.0, cy, cz), VERDANT_ORB)
	# ---- 叶子：杖身(避开两只手)、杖尾(往下垂)、圆环四周、断枝末梢
	for lf: Array in [[-36.5, -0.9, 5.5], [-34.0, -0.8, 5.0], [-31.0, -0.5, 4.0], [-18.0, 0.7, 5.0], [29.0, 0.8, 5.0],
			[41.0, 0.75, 5.5], [53.0, 0.8, 5.0], [59.5, 0.7, 5.5]]:
		var ly: float = float(lf[0])
		var la: float = (ly + 38.0) / 12.0 * TAU + 0.35
		var o5 := _verdant_off(int(floor(ly)))
		var lo := Vector3(1.9 * cos(la) + float(o5.x), ly, 1.9 * sin(la) + float(o5.y))
		_verdant_leaf(lo, Vector3(cos(la), float(lf[1]), sin(la)), Vector3(-sin(la), 0.0, cos(la)), float(lf[2]) * 1.2, 1.65, 0.7)
	for rl: Array in [[112.0, 6.0], [64.0, 5.5], [178.0, 5.5], [10.0, 5.0], [-118.0, 5.0], [-60.0, 4.5]]:
		var th4: float = deg_to_rad(float(rl[0]))
		var rd := Vector3(0.0, sin(th4), cos(th4))
		var tg := Vector3(0.0, cos(th4), -sin(th4))
		var lo2: Vector3 = Vector3(0.0, cy, cz) + rd * (_verdant_rc(th4) + 1.4)
		_verdant_leaf(lo2, rd + tg * 0.25 + Vector3(0.3, 0.0, 0.0), tg * 0.8 + Vector3(0.6, 0.0, 0.0), float(rl[1]) * 1.1, 1.7, 0.5)
	_verdant_leaf(ttip, tdir + Vector3(0.0, 0.5, 0.0), Vector3(0.6, 0.0, 0.0) + Vector3(0.0, -tdir.z, tdir.y), 5.0, 1.4, 0.5)
	_verdant_leaf(ttip, tdir + Vector3(0.0, -0.2, -0.6), Vector3(-0.5, 0.0, 0.0) + Vector3(0.0, -tdir.z, tdir.y), 4.5, 1.3, -0.5)
	# ---- 挂坠：环外沿垂下的皮绳 → 金色小珠 → 红色大珠 → 金箍 → 白色兽牙(往 +Z、略往 -Y 垂，横拿时朝下)
	_verdant_charm(deg_to_rad(-38.0))
	_end()


## 扭动的杖身中心(两只手的位置是直的)
func _verdant_off(y: int) -> Vector2i:
	var a := 0.0
	if y > 22:
		a = clampf(float(y - 22) / 10.0, 0.0, 1.0) * clampf(float(61 - y) / 8.0, 0.0, 1.0)
	elif y < -10:
		a = clampf(float(-10 - y) / 8.0, 0.0, 1.0)
	return Vector2i(int(round(a * 1.1 * sin(float(y) * 0.13 + 0.7))), int(round(a * 1.1 * sin(float(y) * 0.09 + 2.1))))


## 圆环木头中线的半径(随角度起伏)
func _verdant_rc(th: float) -> float:
	return VERDANT_R + 0.45 * sin(3.0 * th + 0.8)


static func _vhash(x: int, y: int, z: int) -> int:
	var h: int = (x * 73856093) ^ (y * 19349663) ^ (z * 83492791)
	return absi(h) % 97


func _verdant_vine(i: int, a: float, c: int, c2: int, c3: int) -> int:
	if i % 5 == 0:
		return c2
	if sin(a) < -0.6:
		return c2
	if cos(a) > 0.75 and i % 3 == 0:
		return c3
	return c


## 只往空格子里放(叶子不盖住木头和藤)
func _vput(x: int, y: int, z: int, c: int, glow: int = 0) -> void:
	if not g.solid(x, y, z):
		D(x, y, z, c, glow)


## 一片叶子：从 o 沿 dir 长 ln 格，叶面在 dir 与 side 张成的平面里，最宽处半宽 w(卵形、尖头)，叶尖往叶面法向卷 curl；
## 一半浅一半深(卡上叶子的两色)，宽的地方叶缘深一点
func _verdant_leaf(o: Vector3, dir: Vector3, side: Vector3, ln: float, w: float, curl: float) -> void:
	var lf := VGrid.hexc("#4b8a3a")
	var lf2 := VGrid.hexc("#69a94c")
	var lf3 := VGrid.hexc("#346a2a")
	var d: Vector3 = dir.normalized()
	var s: Vector3 = (side - d * side.dot(d)).normalized()
	var nrm: Vector3 = d.cross(s)
	var steps: int = int(ln * 4.0)
	for i in range(steps + 1):
		var u: float = float(i) / float(steps)
		var hw: float = w * sin(PI * pow(u, 0.75))
		var sp: Vector3 = o + d * (u * ln) + nrm * (curl * u * u)
		var nj: int = int(ceil(hw * 3.0))
		for j in range(-nj, nj + 1):
			var v: float = float(j) / 3.0
			if absf(v) > hw + 0.01:
				continue
			var q: Vector3 = sp + s * v
			var c: int = lf2 if v > 0.15 else lf
			if absf(v) > hw - 0.35 and hw > 0.9:
				c = lf3
			_vput(int(floor(q.x)), int(floor(q.y)), int(floor(q.z)), c)


## 宝珠：球心 c、半径 r；按法向打光(光从上前方来，两个侧面对称)，亮的地方发一点光
func _verdant_orb(c: Vector3, r: float) -> void:
	var o_dk := VGrid.hexc("#0f4a1f")
	var o_md := VGrid.hexc("#1a6e2e")
	var o_bs := VGrid.hexc("#23903a")
	var o_lt := VGrid.hexc("#4dbb5a")
	var o_hi := VGrid.hexc("#c2f2b4")
	var L: Vector3 = Vector3(0.45, 0.55, -0.7).normalized()
	var ri: int = int(ceil(r)) + 1
	for x in range(-ri, ri + 1):
		for y in range(int(floor(c.y)) - ri, int(floor(c.y)) + ri + 1):
			for z in range(int(floor(c.z)) - ri, int(floor(c.z)) + ri + 1):
				var p := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - c
				var dl: float = p.length()
				if dl > r:
					continue
				var n: Vector3 = p / maxf(dl, 0.01)
				var sh: float = Vector3(absf(n.x), n.y, n.z).dot(L)
				var col := o_bs
				var gl := 8
				if sh > 0.95:
					col = o_hi
					gl = 30
				elif sh > 0.72:
					col = o_lt
					gl = 16
				elif sh < -0.3:
					col = o_dk
					gl = 4
				elif sh < 0.15:
					col = o_md
					gl = 6
				D(x, y, z, col, gl)


## 挂坠：从环外沿 th 角的地方垂下去
func _verdant_charm(th: float) -> void:
	var cord := VGrid.hexc("#6a4a2c")
	var au := VGrid.hexc("#d6a33f")
	var au2 := VGrid.hexc("#f0cc6a")
	var red := VGrid.hexc("#b5302b")
	var red2 := VGrid.hexc("#e05a48")
	var red3 := VGrid.hexc("#7d1d1d")
	var fg := VGrid.hexc("#f3ecdb")
	var fg2 := VGrid.hexc("#dccfb1")
	var fg3 := VGrid.hexc("#c4b28c")
	var d := Vector3(0.0, -0.71, 0.71)
	var p0: Vector3 = Vector3(0.5, VERDANT_CY + sin(th) * (_verdant_rc(th) + 1.2), VERDANT_CZ + cos(th) * (_verdant_rc(th) + 1.2))
	# 皮绳
	for i in range(0, 17):
		var q: Vector3 = p0 + d * (float(i) * 0.25)
		D(0, int(floor(q.y)), int(floor(q.z)), cord)
	# 小金珠 + 红色大珠 + 金箍
	var c1: Vector3 = p0 + d * 4.6
	_verdant_ball(c1, 1.0, au, au2, au)
	var c2: Vector3 = p0 + d * 7.6
	_verdant_ball(c2, 2.1, red, red2, red3)
	var c3: Vector3 = p0 + d * 10.4
	_verdant_ball(c3, 1.1, au, au2, au)
	# 兽牙：根部 3 格粗，往外收成尖，微微弯
	var bend := Vector3(0.0, -0.71, -0.71)
	var f0: Vector3 = p0 + d * 11.0
	for i2 in range(0, 41):
		var u: float = float(i2) / 40.0
		var ax: Vector3 = f0 + d * (u * 9.0) + bend * (1.2 * u * u)
		var rr: float = 1.45 * pow(1.0 - u, 0.8) + 0.2
		var ir: int = int(ceil(rr)) + 1
		for x in range(-ir, ir + 1):
			for y in range(int(floor(ax.y)) - ir, int(floor(ax.y)) + ir + 1):
				for z in range(int(floor(ax.z)) - ir, int(floor(ax.z)) + ir + 1):
					var pp := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - ax
					var along: float = pp.dot(d)
					var perp: Vector3 = pp - d * along
					if absf(along) > 0.5 or perp.length() > rr:
						continue
					var col := fg
					if u < 0.12:
						col = fg3
					elif perp.dot(bend) > 0.3 or x < 0:
						col = fg2
					D(x, y, z, col)


func _verdant_ball(c: Vector3, r: float, col: int, hi: int, dk: int) -> void:
	var ri: int = int(ceil(r)) + 1
	for x in range(-ri, ri + 1):
		for y in range(int(floor(c.y)) - ri, int(floor(c.y)) + ri + 1):
			for z in range(int(floor(c.z)) - ri, int(floor(c.z)) + ri + 1):
				var p := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - c
				if p.length() > r:
					continue
				var cc := col
				if p.y > 0.4 and p.z < 0.6:
					cc = hi
				elif p.y < -0.6:
					cc = dk
				D(x, y, z, cc)


## 乱数(奇兴节点的专属双手长武器)：她角色卡上那根骰子法杖——近黑(微带棕)的木杖身；杖头一圈金色圆环(外沿一圈短金刺)，
## 环心由上下两根金轴架着一颗大白骰子(圆角方块、深色点数，六面按真骰子排：对面相加 = 7)；环顶一颗多面紫水晶尖顶，
## 环下一颗金色棱边的紫水晶；杖尾两道金箍 + 金棱紫晶 + 金色长尖；杖头下系着一根紫绳：一颗小骰子 + 紫流苏；
## 环外漂着三颗小骰子，各拖一道绕环心转的紫色光痕(= 卡上的紫雾；不连任何东西，同幻彩镰刀刃边的小方块)。
## 颜色全用固定色值(不用 cyan 强调色)：金 / 紫晶 = 她身上的同一套金边与紫晶(tools/chars/arcanist.gd)，骰子的白与点数同她腰间的骰子。
## 长柄武器约定：+Y 沿杖身，握点在原点，-10..22 是两只手的位置(杖身是直的 2×2，没有箍)；持枪姿势里杖差不多是横着拿的、
## 武器 +Z ≈ 世界的下方，所以骰子朝上(-Z)的一面是 5、两个侧面(±X)是 4 / 3，挂坠往 +Z(略往 -Y)垂
const DICE_CY := 72.0             # 圆环 / 大骰子的中心(局部 Y；X / Z 的中心 = 杖身中心 0)
const DICE_R := 10.0              # 圆环中线的半径
const DICE_N := 12                # 大骰子边长(格)
const DICE_FACES := {"-z": 5, "+z": 2, "+x": 4, "-x": 3, "+y": 1, "-y": 6}
const DICE_PIPS := {
	1: [Vector2i(1, 1)],
	2: [Vector2i(0, 0), Vector2i(2, 2)],
	3: [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2)],
	4: [Vector2i(0, 0), Vector2i(0, 2), Vector2i(2, 0), Vector2i(2, 2)],
	5: [Vector2i(0, 0), Vector2i(0, 2), Vector2i(2, 0), Vector2i(2, 2), Vector2i(1, 1)],
	6: [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)],
}


func dice_staff() -> void:
	_begin(false)
	var wd := VGrid.hexc("#2e2624")
	var wd2 := VGrid.hexc("#3c312c")
	var wd3 := VGrid.hexc("#221b1a")
	var au := VGrid.hexc("#c4893a")
	var au2 := VGrid.hexc("#e0ac58")
	var au3 := VGrid.hexc("#8e5f26")
	var cy := DICE_CY
	# ---- 杖身：2×2 的近黑木棍，木纹深浅成竖条(按 3 格高的块随机)
	var c0: int = int(cy)
	for y in range(-30, c0 - 28):
		for x in range(-1, 1):
			for z in range(-1, 1):
				var h: int = _vhash(x, y / 3, z)
				D(x, y, z, wd3 if h < 22 else (wd2 if h > 80 else wd))
	# ---- 杖尾：两道金箍 → 金色棱边的紫晶 → 金环 → 金色长尖
	_dice_collar(-26, -25, 2, au, au2)
	_dice_collar(-30, -29, 2, au, au2)
	_dice_collar(-32, -31, 3, au3, au)
	_dice_gem(-37.0, 4.0, 4.0, 2.5, au)
	_dice_collar(-42, -41, 2, au, au2)
	_dice_collar(-43, -43, 3, au3)
	for yb in range(-50, -43):
		var tb: int = -44 - yb                         # 0..6：越往下越细
		if tb < 4:
			B(-1, yb, -1, 0, yb, 0, au2 if (yb % 2) == 0 else au)
			D(-1, yb, -1, au3)
		elif tb < 6:
			D(0, yb, 0, au2)
			D(-1, yb, 0, au)
		else:
			D(0, yb, 0, au2)
	# ---- 杖头下：金箍 → 金色棱边的紫晶 → 接进圆环的金颈
	_dice_collar(c0 - 28, c0 - 27, 2, au3, au)
	_dice_collar(c0 - 26, c0 - 26, 3, au, au2)
	_dice_gem(cy - 19.5, 5.0, 5.0, 3.0, au)
	_dice_collar(c0 - 14, c0 - 14, 3, au, au2)
	_dice_collar(c0 - 13, c0 - 12, 2, au, au2)
	# ---- 圆环(Y-Z 平面，厚 4 格) + 外沿的短金刺
	_dice_ring(cy, au, au2, au3)
	for sp: Array in [[0.0, 3.4], [45.0, 4.8], [135.0, 4.8], [180.0, 3.4], [225.0, 4.8], [315.0, 4.8]]:
		_dice_spike(deg_to_rad(float(sp[0])), float(sp[1]), au, au2)
	# ---- 大骰子 + 上下两根金轴(把它架在环心)
	var h0: int = DICE_N / 2
	_dice_die(-h0, int(cy) - h0, -h0, DICE_N, DICE_FACES, true)
	B(-1, int(cy) + h0, -1, 0, int(cy) + h0 + 2, 0, au2)
	B(-1, int(cy) - h0 - 3, -1, 0, int(cy) - h0 - 1, 0, au)
	# ---- 环顶：金托 + 多面紫水晶尖顶
	_dice_collar(c0 + 11, c0 + 12, 2, au, au2)
	_dice_collar(c0 + 13, c0 + 13, 3, au3, au)
	_dice_crystal(cy + 16.5, 8.3, 2.6, 3.1)
	# ---- 挂坠与漂浮的小骰子
	_dice_charm(cy - 27.5, au, au2)
	_dice_float(Vector3i(3, int(cy) + 10, -15), {"-z": 6, "+z": 1, "+x": 3, "-x": 4, "+y": 2, "-y": 5})
	_dice_float(Vector3i(-7, int(cy) - 12, 12), {"-z": 4, "+z": 3, "+x": 2, "-x": 5, "+y": 6, "-y": 1})
	_dice_float(Vector3i(2, int(cy) + 13, 14), {"-z": 3, "+z": 4, "+x": 5, "-x": 2, "+y": 1, "-y": 6})
	_end()


## 一道金箍：y0..y1，截面 (2hw)×(2hw)，hw ≥ 2 时切掉四个角；顶上一层用 c_top(亮一点)
func _dice_collar(y0: int, y1: int, hw: int, c: int, c_top: int = 0) -> void:
	for y in range(y0, y1 + 1):
		for x in range(-hw, hw):
			for z in range(-hw, hw):
				if hw >= 2 and (x == -hw or x == hw - 1) and (z == -hw or z == hw - 1):
					continue
				D(x, y, z, c_top if (c_top != 0 and y == y1 and y1 > y0) else c)


## 紫水晶：方截面的双锥(中心 (0, cy, 0)，往上 up 格、往下 dn 格收成尖，腰部半宽 hw)；按刻面上色(光从 +X / -Z 的上方来)，微微发光；
## rim ≠ 0 时四条竖棱(截面的四个角)和两头的尖用金色 = 镶在金框里(卡上杖头下、杖尾那两颗)
func _dice_gem(cy: float, up: float, dn: float, hw: float, rim: int = 0) -> void:
	var am := VGrid.hexc("#7a2cc8")
	var am2 := VGrid.hexc("#d4a8ff")
	var am3 := VGrid.hexc("#4c1a86")
	var am4 := VGrid.hexc("#a468ec")
	var ri: int = int(ceil(hw)) + 1
	for y in range(int(floor(cy - dn)), int(ceil(cy + up)) + 1):
		var dy: float = float(y) + 0.5 - cy
		var w: float = hw * (1.0 - dy / up) if dy >= 0.0 else hw * (1.0 + dy / dn)
		if w < 0.35:
			continue
		for x in range(-ri, ri):
			for z in range(-ri, ri):
				var dx: float = float(x) + 0.5
				var dz: float = float(z) + 0.5
				if maxf(absf(dx), absf(dz)) > w + 0.2:
					continue
				if rim != 0 and absf(dx) > w - 0.9 and absf(dz) > w - 0.9:
					D(x, y, z, rim)
					continue
				var on_x: bool = absf(dx) > absf(dz)
				var lit: bool = (on_x and dx > 0.0) or ((not on_x) and dz < 0.0)
				var c := am
				var gl := 18
				if dy >= 0.0:
					c = am4 if lit else am
				else:
					c = am if lit else am3
					gl = 12
				# 朝光那一面上半的一点高光
				if lit and dy > 0.4 and dy < 2.6 and absf(dx if not on_x else dz) < 0.6:
					c = am2
					gl = 40
				D(x, y, z, c, gl)


## 杖顶的紫水晶尖：截面是转了 45° 的方(菱形)的双锥，正看是一颗竖着的菱形、中间一道棱(左亮右暗，同卡上)；
## 四个刻面按象限上色(光从 +X / -Z 的上方来)，微微发光
func _dice_crystal(cy: float, up: float, dn: float, hw: float) -> void:
	var am := VGrid.hexc("#7a2cc8")
	var am2 := VGrid.hexc("#d4a8ff")
	var am3 := VGrid.hexc("#4c1a86")
	var am4 := VGrid.hexc("#a468ec")
	var am5 := VGrid.hexc("#3a1268")
	var ri: int = int(ceil(hw)) + 1
	for y in range(int(floor(cy - dn)), int(ceil(cy + up)) + 1):
		var dy: float = float(y) + 0.5 - cy
		var w: float = hw * (1.0 - dy / up) if dy >= 0.0 else hw * (1.0 + dy / dn)
		if w < 0.4:
			continue
		for x in range(-ri, ri):
			for z in range(-ri, ri):
				var dx: float = float(x) + 0.5
				var dz: float = float(z) + 0.5
				if absf(dx) + absf(dz) > w + 0.5:
					continue
				var q: int = (2 if dx > 0.0 else 0) + (1 if dz < 0.0 else 0)       # 3 = 朝光(+X -Z)，0 = 背光(-X +Z)
				var c: int = [am3, am, am, am4][q] if dy >= 0.0 else [am5, am3, am3, am][q]
				var gl: int = 18 if dy >= 0.0 else 10
				if q == 3 and dy > 0.5 and dy < 3.5 and absf(absf(dx) - absf(dz)) < 1.1:
					c = am2
					gl = 40
				D(x, y, z, c, gl)


## 圆环：Y-Z 平面里中心 (cy, 0)、中线半径 DICE_R；截面 = 径向 ±1.6、X 方向 ±2 的椭圆(两个平面略窄 = 看着圆润)；
## 内沿暗金、外沿上半亮金
func _dice_ring(cy: float, au: int, au2: int, au3: int) -> void:
	var ro: float = DICE_R + 1.7
	for y in range(int(floor(cy - ro)), int(ceil(cy + ro)) + 1):
		for z in range(-int(ceil(ro)), int(ceil(ro)) + 1):
			var dy: float = float(y) + 0.5 - cy
			var dz: float = float(z) + 0.5
			var dr: float = sqrt(dy * dy + dz * dz) - DICE_R
			for x in range(-2, 2):
				var dx: float = float(x) + 0.5
				if pow(dr / 1.6, 2.0) + pow(dx / 2.05, 2.0) > 1.0:
					continue
				var c := au
				if dr < -0.7:
					c = au3
				elif dr > 0.7 and dy > -2.0:
					c = au2
				D(x, y, z, c)


## 圆环外沿的一根金刺：方向角 th(Y-Z 平面里从 +Z 往 +Y 量)，长 ln，根部 2~3 格宽、收成尖
func _dice_spike(th: float, ln: float, au: int, au2: int) -> void:
	var d := Vector2(cos(th), sin(th))             # (z, y)
	var r0: float = DICE_R + 1.0
	var ext: int = int(ceil(r0 + ln)) + 1
	for y in range(int(DICE_CY) - ext, int(DICE_CY) + ext + 1):
		for z in range(-ext, ext + 1):
			var p := Vector2(float(z) + 0.5, float(y) + 0.5 - DICE_CY)
			var along: float = p.dot(d) - r0
			if along < 0.0 or along > ln:
				continue
			var perp: float = absf(p.x * d.y - p.y * d.x)
			var w: float = lerpf(1.45, 0.3, along / ln)
			if perp > w:
				continue
			B(-1, y, z, 0, y, z, au2 if (p.y > 0.0 or along > ln - 1.2) else au)


## 骰子：最小角 (x0, y0, z0)、边长 n；圆角(edge = true：12 条棱各削一格；false：只削 8 个角)；
## faces = {"+x": 点数, ...}，点是平贴的深色方块(n ≥ 10：2×2 的点，否则 1 格)
func _dice_die(x0: int, y0: int, z0: int, n: int, faces: Dictionary, edge: bool, glow: int = 0) -> void:
	var wh := VGrid.hexc("#f0ebe0")
	var wh2 := VGrid.hexc("#e2d9ca")
	var pip := VGrid.hexc("#3a2a2a")
	for i in range(n):
		for j in range(n):
			for k in range(n):
				var ex: bool = i == 0 or i == n - 1
				var ey: bool = j == 0 or j == n - 1
				var ez: bool = k == 0 or k == n - 1
				var ne: int = int(ex) + int(ey) + int(ez)
				if ne >= 3 or (edge and ne >= 2):
					continue
				var c := wh
				if ne == 2:
					c = wh2
				elif ne == 1:
					var key := ""
					var u := 0
					var v := 0
					if ex:
						key = "+x" if i == n - 1 else "-x"
						u = j
						v = k
					elif ey:
						key = "+y" if j == n - 1 else "-y"
						u = i
						v = k
					else:
						key = "+z" if k == n - 1 else "-z"
						u = i
						v = j
					if _dice_pip(int(faces.get(key, 0)), u, v, n):
						c = pip
					elif edge and (u == 1 or u == n - 2 or v == 1 or v == n - 2):
						c = wh2                        # 削掉的棱旁边一圈：暗一点(圆角)
				D(x0 + i, y0 + j, z0 + k, c, glow if c != pip else 0)


## 骰子一面上 (u, v) 这一格是不是点：点排在 3×3 的格位上(DICE_PIPS)
static func _dice_pip(val: int, u: int, v: int, n: int) -> bool:
	if not DICE_PIPS.has(val):
		return false
	var ps: int = 2 if n >= 10 else 1
	var gap: int = 1 if n >= 7 else 0
	var m: int = (n - (3 * ps + 2 * gap)) / 2
	var a: int = u - m
	var b: int = v - m
	if a < 0 or b < 0 or a % (ps + gap) >= ps or b % (ps + gap) >= ps:
		return false
	var cell := Vector2i(a / (ps + gap), b / (ps + gap))
	if cell.x > 2 or cell.y > 2:
		return false
	return (DICE_PIPS[val] as Array).has(cell)


## 漂在环外的小骰子(5 格，只削角；微微发光，像在施法)，身后拖一道绕着环心转的紫色光痕(卡上骰子周围的紫雾；所有骰子同一个转向)
func _dice_float(c: Vector3i, faces: Dictionary) -> void:
	_dice_die(c.x - 2, c.y - 2, c.z - 2, 5, faces, false, 8)
	var tr := VGrid.hexc("#b27ef0")
	var tr2 := VGrid.hexc("#9150e0")
	var tr3 := VGrid.hexc("#6a2cc0")
	var dy0: float = float(c.y) + 0.5 - DICE_CY
	var dz0: float = float(c.z) + 0.5
	var r: float = sqrt(dy0 * dy0 + dz0 * dz0)
	var th0: float = atan2(dy0, dz0)
	var a := 9.0
	while a <= 36.0:
		var th: float = th0 + deg_to_rad(a)
		var u: float = (a - 9.0) / 27.0
		var cc: int = tr if u < 0.3 else (tr2 if u < 0.65 else tr3)
		var gl: int = int(lerpf(24.0, 10.0, u))
		# 靠近骰子的那一段粗一点(径向 2 格)，越往后越细、越稀
		for k in range(2 if u < 0.45 else 1):
			var rr: float = r - 0.8 * u - float(k)
			var y: int = int(floor(DICE_CY + rr * sin(th)))
			var z: int = int(floor(rr * cos(th)))
			if u < 0.7 or _vhash(y, z, c.x) < 55:
				D(c.x, y, z, cc, gl)
		a += 1.2


## 挂坠：从环下金箍(+Z 一侧)垂下的紫绳 → 一颗小骰子 → 金帽 → 紫流苏(往 +Z、略往 -Y 垂，横拿时朝下)
func _dice_charm(y0: float, au: int, au2: int) -> void:
	var cord := VGrid.hexc("#5a2e80")
	var tas := VGrid.hexc("#7444a0")
	var tas2 := VGrid.hexc("#5a2e80")
	var tas3 := VGrid.hexc("#46225f")
	var d := Vector3(0.0, -0.6, 0.8)
	var pp := Vector3(0.0, 0.8, 0.6)              # Y-Z 平面里垂直于 d(流苏往两边散开)
	var p0 := Vector3(0.5, y0, 2.2)
	for i in range(0, 13):
		var q: Vector3 = p0 + d * (float(i) * 0.25)
		D(0, int(floor(q.y)), int(floor(q.z)), cord)
	var cd: Vector3 = p0 + d * 5.4
	_dice_die(-2, int(floor(cd.y)) - 2, int(floor(cd.z)) - 2, 5, {"-z": 3, "+z": 4, "+x": 2, "-x": 5, "+y": 1, "-y": 6}, false)
	var ct: Vector3 = p0 + d * 8.6
	for i2 in range(0, 9):
		var q3: Vector3 = ct + d * (float(i2) * 0.25)
		B(-1, int(floor(q3.y)), int(floor(q3.z)), 0, int(floor(q3.y)), int(floor(q3.z)), au if i2 < 6 else au2)
	# 流苏：2 层 × 3 缕，往下散开一点，长短不一
	var lens: Array = [5.5, 7.0, 6.0, 6.5, 5.0, 7.0]
	for xs in range(-1, 1):
		for k in range(-1, 2):
			var ln: float = float(lens[(xs + 1) * 3 + k + 1])
			var t := 0.0
			while t <= ln:
				var q2: Vector3 = ct + d * (t + 2.4) + pp * (float(k) * (0.55 + 0.13 * t))
				var cc: int = tas if (k + xs + 2) % 2 == 0 else tas2
				if t > ln - 1.0:
					cc = tas3
				D(xs, int(floor(q2.y)), int(floor(q2.z)), cc)
				t += 0.3


## 开与闭(锁芯节点的专属双手长武器)：她角色卡上那把巨大的钥匙 ——
##   杆：近黑的暗绿方杆(3×3，比别的长柄粗一圈，同卡上)，两段金色 X 纹(每个 X 3 行高、隔 1 行)，两只手的位置是素杆，两头各一道细金箍；
##   钥匙头(+Y = 长柄的头，攻击时打出去的那端)：粗金箍(两侧各一颗小红珠) → 一根穿过钥匙柄的扁金条(上下金边、中间一道暗绿线)；
##     钥匙柄 = 一条盘成环的金蛇(扭绳纹的青铜身子，靠杖身那一侧开口：左上端探出蛇头、朝杖身吐信，左下端蛇尾卷成一个钩)，
##     环心是金框里的红色菱形宝石；扁金条伸出环外，末端下面挂着方块钥匙齿(2 格一笔的凹凸回纹)；
##   杖尾(-Y)：金箍 → 金色十字饰(菱形金框 + 红宝石，往后、往上各一个尖)，下面垂着一挂暗红流苏(金帽、两道金色人字纹)。
## 颜色全用固定色值(不用 cyan 强调色)：金 = 她身上同一套金(tools/chars/keeper.gd)，红宝石同她的项圈 / 臂环，杆的暗绿取近黑一档(渲染会提亮)。
## 长柄武器约定：+Y 沿杖身，握点在原点，-10..22 是两只手的位置；持枪姿势里杖差不多是横着拿的、武器 +Z ≈ 世界的下方，
## 所以钥匙齿、流苏往 +Z 垂，蛇头在环的 -Z(上方)。3×3 的杆中心在 (0.5, 0.5)：和 2×2 杆的握点差半格(6 mm)，看不出来。
const KEY_CY := 68.5          # 钥匙柄(蛇环 / 红宝石)中心的局部 Y；Z 的中心 = 杆的中心 0.5
const KEY_R := 10.5           # 蛇环中线的半径
const KEY_TY := -48.5         # 杖尾十字饰(红宝石)中心的局部 Y
const KEY_BIT := [            # 钥匙齿：每格 = 2×2 体素；列 = 局部 Y 从 82 往杖头，行 = 从扁金条下沿往 +Z
	"######",
	"#..#.#",
	"#.##.#",
	"#....#",
	"##.###",
	"#..#.#",
]


func key_staff() -> void:
	_begin(false)
	var gk := VGrid.hexc("#253a2c")
	var gk2 := VGrid.hexc("#1c2e22")
	var gk3 := VGrid.hexc("#2e4535")
	var au := VGrid.hexc("#c4893a")
	var au2 := VGrid.hexc("#e0ac58")
	var au3 := VGrid.hexc("#8e5f26")
	var rb := VGrid.hexc("#c81e2a")
	# ---- 杆身：3×3 暗绿方杆(按 3 格高的块随机深浅)；两段暗金 X 纹(X 3 行高、隔 2 行)：X 的四角落在杆的四条棱上、交叉点在每个面的正中
	for y in range(-38, 49):
		var k: int = -1
		if y >= -36 and y <= -12:
			k = posmod(y + 36, 5)
		elif y >= 23 and y <= 47:
			k = posmod(y - 23, 5)
		for x in range(-1, 2):
			for z in range(-1, 2):
				var corner: bool = x != 0 and z != 0
				var h: int = _vhash(x, y / 3, z)
				var c := gk2 if h < 22 else (gk3 if h > 84 else gk)
				if (k == 0 or k == 2) and corner:
					c = au3
				elif k == 1 and not corner and (x != 0 or z != 0):
					c = au
				D(x, y, z, c)
	# ---- 杖尾金箍 + 两只手两边的细金箍
	_key_band(-37, 2, au2)
	_key_band(-38, 3, au)
	_key_band(-39, 3, au)
	_key_band(-40, 3, au3)
	_key_band(-41, 2, au)
	_key_band(-42, 1, au3)
	_key_band(-43, 1, au)
	_key_band(-44, 1, au)
	for yb: int in [-10, -9, 20, 21]:
		_key_band(yb, 2, au2 if (yb == -10 or yb == 21) else au)
	# ---- 杖头粗金箍(两侧一颗小红珠)
	_key_band(48, 2, au3)
	_key_band(49, 2, au)
	_key_band(50, 2, au2)
	for yc in range(51, 55):
		_key_band(yc, 3, au3 if yc == 51 else (au2 if yc == 54 else au))
	_key_band(55, 2, au)
	_key_band(56, 2, au3)
	for v: Vector3i in [Vector3i(4, 52, 0), Vector3i(4, 53, 0), Vector3i(-4, 52, 0), Vector3i(-4, 53, 0)]:
		D(v.x, v.y, v.z, rb, 30)
	# ---- 扁金条：从金箍穿过蛇环伸到杖头(截面 3×5：上下金边、中间一道暗绿线) + 末端金帽
	for y2 in range(57, 94):
		for z2 in range(-2, 3):
			B(-1, y2, z2, 1, y2, z2, [au2, au, gk, au, au3][z2 + 2])
	for y3 in range(94, 96):
		for x3 in range(-2, 3):
			for z3 in range(-3, 4):
				if absi(x3) == 2 and absi(z3) == 3:
					continue
				D(x3, y3, z3, au2 if (y3 == 95 or z3 == -3) else (au3 if z3 == 3 else au))
	# ---- 钥匙柄：蛇环(左侧开口) + 左上探出的蛇头 + 左下卷起的蛇尾钩(蛇身是偏棕的青铜金)
	var br := VGrid.hexc("#a9733a")
	_key_ring(br, au, au3)
	var a0: float = deg_to_rad(115.0)
	var p0 := Vector2(KEY_CY + KEY_R * cos(a0), 0.5 - KEY_R * sin(a0))           # (局部 Y, 局部 Z)
	_key_tube([p0, p0 + Vector2(-1.8, -0.6), p0 + Vector2(-3.6, -1.9), p0 + Vector2(-5.0, -2.5)], 1.9, 1.7, a0 * KEY_R, 1.0, br, au, au3)
	_key_head(p0 + Vector2(-8.2, -3.0), br, au, au3)
	var a1: float = deg_to_rad(-140.0)
	var p1 := Vector2(KEY_CY + KEY_R * cos(a1), 0.5 - KEY_R * sin(a1))
	_key_tube([p1, Vector2(58.8, 5.6), Vector2(56.5, 5.2), Vector2(54.5, 6.6), Vector2(53.8, 9.2), Vector2(54.8, 11.6), Vector2(57.2, 12.6),
		Vector2(59.4, 11.6), Vector2(60.0, 9.6), Vector2(58.8, 8.4)], 1.9, 0.9, a1 * KEY_R, -1.0, br, au, au3)
	# ---- 环心的红色菱形宝石(金框)
	_key_gem(KEY_CY, 3.0, 5.0, au, au2, au3)
	# ---- 钥匙齿
	for r in range(KEY_BIT.size()):
		var row: String = KEY_BIT[r]
		for kk in range(row.length()):
			if row[kk] != "#":
				continue
			var open_up: bool = r == 0 or str(KEY_BIT[r - 1])[kk] != "#"
			var open_dn: bool = r == KEY_BIT.size() - 1 or str(KEY_BIT[r + 1])[kk] != "#"
			for yy in range(2):
				for zz in range(2):
					var cb := au
					if zz == 0 and open_up and r > 0:
						cb = au2
					elif zz == 1 and open_dn:
						cb = au3
					B(-1, 82 + kk * 2 + yy, 3 + r * 2 + zz, 1, 82 + kk * 2 + yy, 3 + r * 2 + zz, cb)
	# ---- 杖尾：金色十字饰(菱形金框 + 红宝石)，往后(-Y)、往上(-Z)各一个尖，下面(+Z)挂流苏
	_key_gem(KEY_TY, 2.0, 4.0, au, au2, au3)
	var ty: int = int(floor(KEY_TY))
	_key_band(ty - 5, 1, au)
	for v2: Vector3i in [Vector3i(0, 0, 0), Vector3i(-1, 0, 0), Vector3i(1, 0, 0), Vector3i(0, 0, -1), Vector3i(0, 0, 1)]:
		D(v2.x, ty - 6, v2.z, au2)
	D(0, ty - 7, 0, au2)
	B(-1, ty - 1, -5, 1, ty + 1, -5, au)
	B(-1, ty, -6, 1, ty, -6, au2)
	D(0, ty, -7, au2)
	B(-1, ty - 1, 5, 1, ty + 1, 5, au)
	B(-1, ty, 6, 1, ty, 6, au3)
	B(-1, ty - 1, 7, 1, ty + 1, 7, VGrid.hexc("#2e2420"))
	B(-1, ty - 1, 8, 1, ty + 1, 8, au)
	B(-1, ty, 9, 1, ty, 9, au2)
	_key_tassel(ty, 10, au)
	_end()


## 一圈金箍：局部 Y = y，截面 (2hw+1)² 以杆心 (0.5, 0.5) 为中心；hw ≥ 2 削角(hw ≥ 3 削成八角)
func _key_band(y: int, hw: int, c: int) -> void:
	var cut: int = 2 * hw - (1 if hw >= 3 else 0)
	for x in range(-hw, hw + 1):
		for z in range(-hw, hw + 1):
			if hw >= 2 and absi(x) + absi(z) >= cut:
				continue
			D(x, y, z, c)


## 蛇身的颜色：s = 沿中线的弧长，xo = X 偏移，ro = 离中线的径向偏移(> 0 = 外沿)；c = 底色，c_hi = 上沿(-Z)外侧的亮色，
## c_dk = 内沿(环心那侧)的暗色，底色上还有斜着的一道道细暗纹(鳞片的接缝，按弧长 + X 错开)
func _key_twist(s: float, xo: float, ro: float, top: bool, c: int, c_hi: int, c_dk: int) -> int:
	if ro < -0.7:
		return c_dk
	if top and ro > 0.3:
		return c_hi
	if fposmod(s / 2.4 + xo * 0.5, 1.0) < 0.22:
		return c_dk
	return c


## 蛇环：Y-Z 平面里中心 (KEY_CY, 0.5)、中线半径 KEY_R，从左下(-140°)绕过右边到左上(115°)，靠杖身那一侧开口；
## 截面 = 径向 ±1.9、X ±1.5 的椭圆；蛇身用偏棕的青铜金(同卡上，和金条 / 金箍分开)，上沿亮一档 = 金条的金
func _key_ring(br: int, au: int, au3: int) -> void:
	var ro: float = KEY_R + 2.0
	for y in range(int(floor(KEY_CY - ro)), int(ceil(KEY_CY + ro)) + 1):
		for z in range(-int(ceil(ro)), int(ceil(ro)) + 2):
			var dy: float = float(y) + 0.5 - KEY_CY
			var dz: float = float(z)
			var th: float = atan2(-dz, dy)
			if th > deg_to_rad(115.0) or th < deg_to_rad(-140.0):
				continue
			var dr: float = sqrt(dy * dy + dz * dz) - KEY_R
			for x in range(-1, 2):
				if pow(dr / 1.9, 2.0) + pow(float(x) / 1.5, 2.0) > 1.0:
					continue
				D(x, y, z, _key_twist(th * KEY_R, float(x), dr, dr > 0.4 and dz < -1.0, br, au, au3))


## 一段蛇身圆管：Y-Z 平面里的折线 pts = [Vector2(局部 Y, 局部 Z), ...](X 中心 0.5)，半径从 r0 收到 r1；
## 每格取离它最近的那个采样点上色(扭绳纹接着蛇环：s0 = 起点的弧长，sgn = 往哪个方向数)
func _key_tube(pts: Array, r0: float, r1: float, s0: float, sgn: float, c: int, c_hi: int, c_dk: int) -> void:
	var total := 0.0
	for i in range(pts.size() - 1):
		total += (pts[i + 1] as Vector2).distance_to(pts[i])
	var best := {}
	var s := 0.0
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var ln: float = a.distance_to(b)
		var t := 0.0
		while t <= ln:
			var p: Vector2 = a.lerp(b, t / ln)
			var r: float = lerpf(r0, r1, (s + t) / total)
			var n: int = int(ceil(r)) + 1
			for y in range(int(floor(p.x)) - n, int(floor(p.x)) + n + 1):
				for z in range(int(floor(p.y)) - n, int(floor(p.y)) + n + 1):
					var dyz: float = Vector2(float(y) + 0.5, float(z) + 0.5).distance_to(p)
					for x in range(-2, 3):
						var e: float = pow(dyz / r, 2.0) + pow(float(x) / (r * 0.94), 2.0)
						if e > 1.0:
							continue
						var key := Vector3i(x, y, z)
						if not best.has(key) or e < float(best[key][0]):
							best[key] = [e, s0 + sgn * (s + t), dyz - r * 0.5, float(z) + 0.5 < p.y - 0.4]
			t += 0.25
		s += ln
	for key: Vector3i in best:
		var v: Array = best[key]
		D(key.x, key.y, key.z, _key_twist(float(v[1]), float(key.x), float(v[2]), bool(v[3]), c, c_hi, c_dk))


## 蛇头：中心 hc = (局部 Y, 局部 Z)，朝 -Y、略往上(-Z)抬；往吻部收窄的椭球(底色 c)，头顶亮(c_hi)、下颚暗(c_dk)，嘴缝一道暗线，
## 两侧一对凸出来的暗色眼睛，吐一根分叉的红信子
func _key_head(hc: Vector2, c0: int, c_hi: int, c_dk: int) -> void:
	var fwd := Vector2(-1.0, -0.18).normalized()
	var up := Vector2(-fwd.y, fwd.x)                       # 指向 -Z(上)
	var eye := VGrid.hexc("#2a1416")
	for y in range(int(hc.x) - 5, int(hc.x) + 6):
		for z in range(int(hc.y) - 5, int(hc.y) + 6):
			var d := Vector2(float(y) + 0.5, float(z) + 0.5) - hc
			var a: float = d.dot(fwd)
			var b: float = d.dot(up)
			var taper: float = 1.0 - 0.4 * clampf(a / 3.8, 0.0, 1.0)
			for x in range(-2, 3):
				if pow(a / 4.0, 2.0) + pow(b / (2.5 * taper), 2.0) + pow(float(x) / (2.2 * taper), 2.0) > 1.0:
					continue
				var c := c0
				if b > 0.9:
					c = c_hi
				elif b < -0.9:
					c = c_dk
				if a > 0.9 and absf(b + 0.15) < 0.5:
					c = c_dk                                  # 嘴缝
				D(x, y, z, c)
	var ep: Vector2 = hc + fwd * 0.5 + up * 0.9
	D(2, int(floor(ep.x)), int(floor(ep.y)), eye)
	D(-2, int(floor(ep.x)), int(floor(ep.y)), eye)
	var tg := VGrid.hexc("#b01e2a")
	var tp: Vector2 = hc + fwd * 4.4
	for i in range(3):
		var q: Vector2 = tp + fwd * float(i)
		D(0, int(floor(q.x)), int(floor(q.y)), tg)
	var tq: Vector2 = tp + fwd * 3.0
	D(0, int(floor(tq.x)), int(floor(tq.y - 1.0)), tg)
	D(0, int(floor(tq.x)), int(floor(tq.y + 1.0)), tg)


## 菱形红宝石：Y-Z 平面里中心 (cy, 0.5) 的菱形，|dy| + |dz| ≤ rg 是宝石(中心往 ±X 鼓出一格)，到 rf 是金框；
## 宝石上半亮、下半暗，左上一格高光，微微发光
func _key_gem(cy: float, rg: float, rf: float, au: int, au2: int, au3: int) -> void:
	var rb := VGrid.hexc("#c81e2a")
	var rb2 := VGrid.hexc("#ff7a6a")
	var rb3 := VGrid.hexc("#8a1420")
	var n: int = int(ceil(rf)) + 1
	for y in range(int(floor(cy)) - n, int(floor(cy)) + n + 1):
		for z in range(-n, n + 1):
			var dy: float = float(y) + 0.5 - cy
			var dz: float = float(z)
			var d: float = absf(dy) + absf(dz)
			if d > rf + 0.01:
				continue
			if d > rg + 0.01:
				var cf := au
				if dz < -0.1 and dy < 0.6:
					cf = au2
				elif dz > 0.1 and dy > -0.6:
					cf = au3
				B(-1, y, z, 1, y, z, cf)
				continue
			var xr: int = 2 if d <= rg * 0.45 else 1
			var c := rb if dz <= 0.0 else rb3
			var gl: int = 30 if dz <= 0.0 else 16
			if dz < 0.0 and dy < 0.0 and d > rg * 0.3 and d < rg * 0.75:
				c = rb2
				gl = 50
			B(-xr, y, z, xr, y, z, c, gl)


## 暗红流苏：从杖尾十字饰下面(局部 Y 中心 = ty + 0.5)往 +Z 垂，z0 起；上窄、中间宽、下面收成尖，竖缕深浅交替，两道金色人字纹
func _key_tassel(ty: int, z0: int, au: int) -> void:
	var rd := VGrid.hexc("#7a1e26")
	var rd2 := VGrid.hexc("#5e161d")
	var rd3 := VGrid.hexc("#4a1016")
	var hws := [1, 1, 1, 2, 2, 3, 3, 3, 3, 3, 3, 2, 2, 2, 1, 1, 0]
	for i in range(hws.size()):
		var z: int = z0 + i
		var hw: int = hws[i]
		for dyc in range(-hw, hw + 1):
			var c := rd if posmod(dyc, 2) == 0 else rd2
			if i == 0 or i == hws.size() - 1:
				c = rd3
			var v1: int = i - 5
			var v2: int = i - 10
			if (v1 >= 0 and v1 <= 3 and absi(dyc) == v1) or (v2 >= 0 and v2 <= 2 and absi(dyc) == v2):
				c = au
			B(-1, ty + dyc, z, 1, ty + dyc, z, c)


## 幻彩镰刀(幻彩节点的专属武器，双手重)：她角色卡上那把——比人还高的紫色长柄 + 几道银箍，柄尾垂着金链和一颗小星星坠，
## 柄头是银色的刃座和一颗粉色的星星，一弯发光的淡紫色月牙刃(往 +Z 伸出去、末端往下弯，内弧是发光的刃口)，刃边漂着几颗小方块
const PRISM_STAR := [
	"...#...",
	"..###..",
	"#######",
	".#####.",
	"..###..",
	".##.##.",
	".#...#.",
]


func _prism_star(cy: int, cz: int, x0: int, x1: int, c: int, c2: int, glow: int) -> void:
	for r in range(PRISM_STAR.size()):
		var row: String = PRISM_STAR[r]
		for k in range(row.length()):
			if row[k] == "#":
				B(x0, cy + 3 - r, cz + k - 3, x1, cy + 3 - r, cz + k - 3, c2 if r == 2 and k == 3 else c, glow)


func prism_scythe() -> void:
	_begin(false)
	var o := 14                                # 握点在长柄偏下的位置：整把往上挪(刃离手更远)
	var pu := VGrid.hexc("#6a3fc0")
	var pu2 := VGrid.hexc("#7d52d6")
	var pu3 := VGrid.hexc("#4c2c8f")
	var ag := VGrid.hexc("#e2e4ee")
	var ag2 := VGrid.hexc("#b9bccb")
	var pk := VGrid.hexc("#ff8fd0")
	var pk2 := VGrid.hexc("#ffd0ec")
	var bl := VGrid.hexc("#9b5cff")
	var bl1 := VGrid.hexc("#c49bff")
	var bl2 := VGrid.hexc("#e6ccff")
	var gd := _c("gold")
	var ye := VGrid.hexc("#ffe27a")
	# 长柄：紫色(带一点纹路)，四道银箍
	for y in range(-44 + o, 64 + o):
		B(-1, y, -1, 0, y, 0, pu if (y % 9) < 6 else pu2)
	for ry: int in [-30 + o, -6 + o, 22 + o, 46 + o]:
		B(-2, ry, -2, 1, ry + 1, 1, ag)
		B(-2, ry + 2, -2, 1, ry + 2, 1, ag2)
	# 柄尾：银帽 + 金链 + 小星星坠
	B(-2, -47 + o, -2, 1, -45 + o, 1, ag)
	B(-1, -48 + o, -1, 0, -48 + o, 0, ag2)
	for cy in range(-53 + o, -48 + o):
		D(-1, cy, 1 if cy % 2 == 0 else 0, gd)
	_prism_star(-57 + o, 1, -1, -1, ye, VGrid.hexc("#fff4c0"), 40)
	# 刃座：银色方块 + 柄头的粉色星星(两面都有)
	B(-2, 63 + o, -3, 1, 68 + o, 3, ag)
	B(-2, 64 + o, -4, 1, 67 + o, -4, ag2)
	B(-3, 65 + o, -2, 2, 66 + o, 1, ag2)
	_prism_star(73 + o, 0, -2, 1, pk, pk2, 70)
	# 月牙刃：从刃座往 +Z 伸出去、先微微上拱再往下弯，越往外越细；外弧是深紫的刃背，内弧(下沿)是发光的刃口
	for z in range(3, 45):
		var u: float = float(z - 3) / 41.0
		var cy2: float = 68.0 + o + 5.0 * sin(u * PI * 0.85) - 26.0 * u * u
		var half: float = lerpf(7.0, 0.6, pow(u, 0.85))
		var y0: int = int(round(cy2 - half))
		var y1: int = int(round(cy2 + half))
		for y in range(y0, y1 + 1):
			var c: int = bl
			var glow: int = 35
			if y == y1:
				c = pu3
				glow = 0
			elif y == y0:
				c = bl2
				glow = 90
			elif y == y0 + 1 and half > 2.5:
				c = bl1
				glow = 60
			B(-1, y, z, 0, y, z, c, glow)
	# 刃背往柄的另一侧伸出一小截尖刺(-Z)
	for z2 in range(-9, -3):
		var k2: float = float(-4 - z2) / 5.0
		B(-1, 66 + o + int(round(2.0 * k2)), z2, 0, 67 + o + int(round(1.0 * k2)), z2, pu3 if z2 > -8 else ag2)
	# 刃边漂着的小方块(粉 / 淡紫 / 淡蓝，自发光)
	for cube: Array in [[Vector3i(-1, 58, 14), pk], [Vector3i(-1, 48, 25), VGrid.hexc("#bfe7ff")], [Vector3i(0, 61, 33), bl2],
			[Vector3i(-1, 40, 37), pk2], [Vector3i(0, 78, 18), VGrid.hexc("#bfe7ff")], [Vector3i(-1, 81, 8), bl2], [Vector3i(0, 33, 44), bl1]]:
		var cv: Vector3i = cube[0]
		B(cv.x, cv.y + o, cv.z, cv.x, cv.y + o + 1, cv.z + 1, int(cube[1]), 90)
	_end()


## 闪电手套(迅游节点的专属武器，双持近战)：他角色卡上那副——黑色露指手套包住整只拳头，两侧银色护板 + 铆钉，
## 手腕一圈发光的紫色能量环，手背一颗紫色能量核，两侧各伸出一道锯齿形的闪电小鳍。(手套中心在手掌上：握点往手腕那边偏 y +1.5、z -1)
func volt_glove(p_left: bool) -> void:
	_begin(p_left)
	var blk := VGrid.hexc("#232228")
	var blk2 := VGrid.hexc("#18171c")
	var sil := VGrid.hexc("#b9bdc8")
	var sil2 := VGrid.hexc("#8c909b")
	var vio := VGrid.hexc("#b56cff")
	var vio2 := VGrid.hexc("#e2c4ff")
	# 手套本体：圆角的块(去掉 8 个角)
	for x in range(-3, 3):
		for y in range(-2, 5):
			for z in range(-4, 3):
				var corner: bool = (x == -3 or x == 2) and (y == -2 or y == 4) and (z == -4 or z == 2)
				if not corner:
					D(x, y, z, blk if (x + y + z) % 3 != 0 else blk2)
	# 两侧银色护板 + 铆钉
	for sx: int in [-4, 3]:
		B(sx, -1, -3, sx, 3, 1, sil)
		D(sx, 0, -2, sil2)
		D(sx, 2, 0, sil2)
	# 手背的紫色能量核(前后两面都有：哪面朝外都看得见)
	for sz: int in [-5, 3]:
		B(-2, 0, sz, 1, 3, sz, blk2)
		B(-1, 0, sz, 0, 3, sz, vio, 45)
		B(-2, 1, sz, 1, 2, sz, vio, 45)
		B(-1, 1, sz, 0, 2, sz, vio2, 70)
	# 手腕的能量环(绕一圈)
	for x in range(-4, 4):
		for z in range(-5, 4):
			if x == -4 or x == 3 or z == -5 or z == 3:
				D(x, 5, z, vio, 45)
	B(-3, 6, -4, 2, 6, 2, sil2)
	# 两侧锯齿闪电鳍(往外、往手腕方向斜着伸)
	for sx2: int in [-1, 1]:
		var bx: int = 4 if sx2 > 0 else -5
		var pts := [Vector3i(0, 1, 0), Vector3i(1, 2, 0), Vector3i(1, 3, 0), Vector3i(2, 3, 0), Vector3i(2, 4, 0), Vector3i(3, 5, 0), Vector3i(3, 6, 0), Vector3i(4, 7, 0)]
		for q: Vector3i in pts:
			D(bx + q.x * sx2, q.y, -1, vio2 if q.y >= 5 else vio, 60)
	_end()


## 万语千言(幻形节点的专属武器，双持近战)：一捆卷起来的白色竹简(握在卷中间、往拳头上方伸出去)，竹片一条条的缝、
## 上面是看不清的灰色字样纹路，两道深色的绳子捆着，顶上露出竹片的截面
func bamboo_slips(p_left: bool) -> void:
	_begin(p_left)
	var w1 := VGrid.hexc("#f3efe4")
	var w2 := VGrid.hexc("#e4ddcc")
	var w3 := VGrid.hexc("#d2c9b4")
	var ink := VGrid.hexc("#8a8494")
	var ink2 := VGrid.hexc("#6c6678")
	var cord := VGrid.hexc("#5a4a3c")
	for y in range(-6, 22):
		for x in range(-4, 4):
			for z in range(-4, 4):
				var dx: float = float(x) + 0.5
				var dz: float = float(z) + 0.5
				var r2: float = dx * dx + dz * dz
				if r2 > 8.5:
					continue
				var shell: bool = r2 > 3.5
				var ang: float = atan2(dz, dx)
				var slat: int = int(floor((ang + PI) / (TAU / 12.0)))
				var c: int = w1 if slat % 2 == 0 else w2
				if not shell:
					c = w3                                            # 里面(顶上的截面看得到一圈圈)
				elif (y * 7 + slat * 5) % 11 == 0 and y > -4 and y < 20:
					c = ink if (y + slat) % 2 == 0 else ink2          # 看不清的字
				if y == 21 and shell and (slat % 3 == 0):
					c = w3
				D(x, y, z, c)
	for cy: int in [1, 14]:
		for x2 in range(-5, 5):
			for z2 in range(-5, 5):
				var ex: float = float(x2) + 0.5
				var ez: float = float(z2) + 0.5
				var rr: float = ex * ex + ez * ez
				if rr > 8.5 and rr <= 14.0:
					D(x2, cy, z2, cord)
	_end()


## 匕首与金币(巧运节点的专属双持近战)：他角色卡上那一套。右手是一把直刃双锋短匕——浅灰钢刃一路收成尖、两侧白亮刃口、中间一道深一点的血槽，
## 金色护手横杆两端翘起成块、卷尖往外翻，中间一块金色舌片包住刃根，深棕斜缠的握柄(点着两排金钉)，金色圆柄头(金色同他身上的金扣)；
## 左手是一枚厚金币(直径 9 格，比真钱币大，战斗镜头里看得见)：深金色的边 + 亮金币面(微微发光) + 两面深金色的王冠纹 + 一点高光，
## 夹在拇指和食指之间、从拳头上方(+Y，刃出来的那一侧)露出大半，币面朝 ±X(待机时朝上)。王冠纹不凸出：凸出的话侧着看像齿轮。
## 两件都是固定配色(不随武器颜色换色)。
## 刃沿 +Y，握点在原点；左手那件(Weapon_L)自动镜像
const COIN_CROWN := ["..#..", "#.#.#", "#####"]


func coin_dagger(p_left: bool) -> void:
	_begin(p_left)
	if p_left:
		_gold_coin(5, 0)
		_end()
		return
	var st := VGrid.hexc("#aeb4bf")       # 钢刃
	var st2 := VGrid.hexc("#eef1f6")      # 刃口高光
	var st3 := VGrid.hexc("#858c99")      # 血槽
	var wr := VGrid.hexc("#2c201b")       # 缠柄
	var wr2 := VGrid.hexc("#4a362b")
	var au := VGrid.hexc("#c99040")
	var au2 := VGrid.hexc("#e8b860")
	var au3 := VGrid.hexc("#8e5f26")
	# 握柄：深棕皮绳斜缠，两排小金钉
	for y in range(-5, 3):
		for x in range(-1, 1):
			for z in range(-1, 1):
				D(x, y, z, wr2 if posmod(y + x - z, 3) == 0 else wr)
	for sp: Vector3i in [Vector3i(-1, -3, -1), Vector3i(0, -3, 0), Vector3i(0, 0, -1), Vector3i(-1, 0, 0)]:
		D(sp.x, sp.y, sp.z, au3)
	# 柄头：金色圆球(去角的 4×4) + 底下一小块
	B(-2, -7, -1, 1, -6, 0, au)
	B(-1, -7, -2, 0, -6, 1, au)
	B(-1, -8, -1, 0, -8, 0, au3)
	D(-2, -6, 0, au2)
	D(1, -6, -1, au2)
	# 护手：金色横杆 + 中间舌片；两端往刃那边翘起、卷尖往外翻
	B(-2, 3, -5, 1, 4, 4, au)
	B(-2, 5, -2, 1, 5, 1, au)
	B(-2, 4, -1, 1, 4, 0, au2)
	for zz: Array in [[-6, -7], [5, 6]]:
		var ze: int = int(zz[0])
		var zo: int = int(zz[1])
		B(-2, 3, ze, 1, 5, ze, au)
		B(-2, 3, ze, 1, 3, ze, au3)
		B(-1, 6, zo, 0, 6, zo, au2)
		B(-1, 5, zo, 0, 5, zo, au)
	# 刃：直的双锋刃，从护手往外一路收成尖(6 格宽 → 4 → 2)，两侧白亮刃口，中间一道血槽
	for y2 in range(6, 27):
		var hw: int = 3 if y2 <= 15 else (2 if y2 <= 22 else 1)
		for z2 in range(-hw, hw):
			var edge: bool = z2 == -hw or z2 == hw - 1
			var c: int = st2 if edge else st
			if not edge and (z2 == -1 or z2 == 0) and y2 >= 7 and y2 <= 19:
				c = st3
			B(-1, y2, z2, 0, y2, z2, c)
	_end()


## 金币：直径 9 格(币面在 Y-Z 平面，沿 X 厚 2 格)，圆心(cy, cz)。外圈一格深金的边，里面亮金币面(微微发光)；
## 两面正中一个深金色的王冠纹(raised=true 时凸出币面一格)，左上一点高光
func _gold_coin(cy: int, cz: int, raised: bool = false) -> void:
	var face := VGrid.hexc("#eaae42")
	var face2 := VGrid.hexc("#ffdc80")
	var rim := VGrid.hexc("#b3772a")
	var emb := VGrid.hexc("#b87a24")
	for dy in range(-4, 5):
		for dz in range(-4, 5):
			var r2: int = dy * dy + dz * dz
			if r2 > 20:
				continue
			if r2 > 12:
				B(-1, cy + dy, cz + dz, 0, cy + dy, cz + dz, rim)
			else:
				B(-1, cy + dy, cz + dz, 0, cy + dy, cz + dz, face, 10)
	# 王冠纹(两面都有)
	for r in range(COIN_CROWN.size()):
		var row: String = COIN_CROWN[r]
		for k in range(row.length()):
			if row[k] == "#":
				var yy: int = cy + 1 - r
				var zz2: int = cz - 2 + k
				if raised:
					D(-2, yy, zz2, emb)
					D(1, yy, zz2, emb)
				else:
					B(-1, yy, zz2, 0, yy, zz2, emb)
	# 高光
	for x: int in [-1, 0]:
		D(x, cy + 2, cz - 2, face2, 45)
		D(x, cy + 3, cz - 1, face2, 30)


## 魔典(幻灵节点的专属法器)：她角色卡上那本——黑色封面、金色包边和包角、封面正中一颗紫宝石(金托)、侧面一道金扣，
## 书边飘着两团紫色的骷髅灵火(自发光)。法器约定：书放在拳头上方(+Z)，书脊沿 Y
const SKULL_WISP := [".###.", "#.#.#", "#####", ".#.#.", "..#.."]


func _skull_wisp(x0: int, y0: int, z: int, c: int, eye: int) -> void:
	for r in range(SKULL_WISP.size()):
		var row: String = SKULL_WISP[r]
		for k in range(row.length()):
			var ch: String = row[k]
			if ch == "#":
				D(x0 + k, y0 - r, z, c, 70)
			elif r == 1 and ch == ".":
				D(x0 + k, y0 - r, z, eye)


func grimoire() -> void:
	_begin(false)
	var cov := VGrid.hexc("#1e1a24")
	var cov2 := VGrid.hexc("#2a2432")
	var page := VGrid.hexc("#efe6d2")
	var au := _c("gold")
	var au2 := _c("gold2")
	var gem := VGrid.hexc("#9b4dff")
	var gem2 := VGrid.hexc("#d7b8ff")
	var wisp := VGrid.hexc("#c9a6ff")
	var eye := VGrid.hexc("#3a2060")
	B(-7, -12, 3, 6, 5, 3, cov)
	B(-7, -12, 9, 6, 5, 9, cov)
	B(-6, -11, 4, 6, 4, 8, page)
	for yy in range(-11, 5, 3):
		B(6, yy, 4, 6, yy, 8, VGrid.hexc("#d8ccb2"))
	# 书脊 + 金边 + 四个金包角
	B(-7, -12, 3, -7, 5, 9, cov2)
	B(-7, -12, 9, 6, -12, 9, au2)
	B(-7, 5, 9, 6, 5, 9, au2)
	for cc: Array in [[-7, -12], [5, -12], [-7, 4], [5, 4]]:
		B(cc[0], cc[1], 9, cc[0] + 1, cc[1] + 1, 10, au)
	# 封面正中的紫宝石(金托)
	B(-3, -6, 10, 2, -1, 10, au2)
	B(-2, -5, 11, 1, -2, 11, gem, 60)
	B(-1, -4, 11, 0, -3, 11, gem2, 110)
	# 侧面的金扣
	B(6, -5, 5, 7, -2, 9, au)
	# 两团骷髅灵火
	_skull_wisp(9, 6, 6, wisp, eye)
	for ty in range(1, 4):
		D(11 + (ty % 2), 1 - ty, 6, wisp, 50)
	_skull_wisp(-14, -9, 7, wisp, eye)
	for ty2 in range(1, 3):
		D(-12 - (ty2 % 2), -14 - ty2, 7, wisp, 50)
	_end()


func hunt_flag() -> void:
	_begin(false)
	var pole := VGrid.hexc("#7e1016")
	var au := _c("gold")
	var cloth := VGrid.hexc("#d02a34")
	var cloth2 := VGrid.hexc("#a81e28")
	var paw := VGrid.hexc("#f4c84a")
	for y in range(-6, 34):
		B(-1, y, -1, 0, y, 0, pole)
	B(-2, 34, -2, 1, 36, 1, au)
	B(-2, -8, -2, 1, -7, 1, au)
	# 三角旗：顶边 y 32，往 +Z 伸 18 格，越往外越窄
	for z in range(1, 19):
		var half: float = 8.0 * (1.0 - float(z - 1) / 18.0)
		for y2 in range(int(32.0 - 2.0 * half), 33):
			B(0, y2, z, 0, y2, z, cloth if (y2 + z) % 4 != 0 else cloth2)
	for r in range(PAW.size()):
		for k in range(5):
			if PAW[r][k] == "X":
				B(-1, 29 - r, 3 + k, 0, 29 - r, 3 + k, paw)
	_end()


# ====================================================================== 木弓(朴素款弓；骨骼与华丽款相同，弓臂可弯、弓弦可拉)
## 虹光花(巫术节点)：法器——一根棕色细杖(握点在原点，杖身沿 -Y 指向前方)，金色杖尾，银色叶状护手，杖尖一朵六色彩虹花
## (花盘朝上 +Z，从俯视的镜头看得见)；六片花瓣红 / 橙 / 黄 / 绿 / 蓝 / 紫，金色花心
const FLOWER_TIP := -44                                   # 花心的局部 Y


func rainbow_flower() -> void:
	_begin(false)
	var wood := VGrid.hexc("#6b4426")
	var wood2 := VGrid.hexc("#54331c")
	var au := _c("gold")
	var au2 := _c("gold2")
	var sil := _c("white3")
	var sil2 := _c("iron2")
	# 杖尾(金) + 杖身
	B(-1, 6, -1, 0, 8, 0, au)
	D(0, 9, 0, au2)
	for y in range(-36, 6):
		B(-1, y, -1, 0, y, 0, wood if (y % 6) != 0 else wood2)
	# 银色叶状护手：花托下面朝前伸出的几片叶子
	for k in range(0, 4):
		var yy: int = -32 - k
		B(-2 - k / 2, yy, -1, 1 + k / 2, yy, 0, sil if k % 2 == 0 else sil2)
		D(-3 - k / 2, yy - 1, 0, sil2)
		D(2 + k / 2, yy - 1, 0, sil2)
	B(-1, -38, -1, 0, -37, 1, sil)
	# 花：花盘在 X-Y 平面里、朝上(+Z)；六片花瓣绕花心一圈
	var petals: Array = [VGrid.hexc("#e8333a"), VGrid.hexc("#f08a24"), VGrid.hexc("#f2d33a"), VGrid.hexc("#4cc85a"), VGrid.hexc("#3a8be8"), VGrid.hexc("#8a4ad8")]
	var cy: int = FLOWER_TIP
	for i in range(6):
		var ang: float = TAU * float(i) / 6.0 + 0.26
		var px: float = cos(ang) * 4.2
		var py: float = sin(ang) * 4.2
		for dx in range(-2, 2):
			for dy in range(-2, 2):
				var qx: float = px + float(dx) + 0.5
				var qy: float = py + float(dy) + 0.5
				if Vector2(qx - px, qy - py).length() > 1.9:
					continue
				B(int(floor(qx)), cy + int(floor(qy)), 0, int(floor(qx)), cy + int(floor(qy)), 1, petals[i], 25)
	B(-2, cy - 1, 0, 1, cy + 1, 2, au, 20)
	D(0, cy, 2, au2, 40)
	D(-1, cy, 2, au2, 40)
	_end()


## 易用短弓(追猎节点)：比普通的弓短一截的反曲弓——深棕木弓臂、几道金箍、弓梢往前卷，浅色弓弦；结构同 bow_plain(弓臂分段绑 Bow_U1/U2、Bow_D1/D2，弦在端帽与搭箭点之间插值)
const SHORT_TIP := 43


func bow_short() -> void:
	g.tx = -16
	g.ty = 44
	g.tz = 3
	g.sym = false
	g.mode = VGrid.FILL
	g.use("Bow")
	left = false
	var wood := VGrid.hexc("#4e301e")
	var wood2 := VGrid.hexc("#633d26")
	var au := _c("gold")
	var au2 := _c("gold2")
	# 握把(皮革缠绕 + 上下两道金箍)
	g.box(-2, -7, -2, 1, 7, 2, wood)
	g.box(-2, -5, -3, 1, 5, 3, _c("leather"))
	g.box(-3, 6, -3, 2, 7, 3, au)
	g.box(-3, -7, -3, 2, -6, 3, au)
	# 弓臂(沿 model_bow 的曲线，短一截)；几道金箍
	for sgn: float in [1.0, -1.0]:
		for a in range(8, SHORT_TIP):
			var y0 := float(a) * sgn
			var y1 := float(a + 1) * sgn
			var r := lerpf(1.8, 1.0, float(a - 8) / float(SHORT_TIP - 8))
			var col: int = wood if (a % 8) < 6 else wood2
			if a == 16 or a == 30:
				col = au
			g.seg(Vector3(0.0, y0, BowModel.zc(y0)), Vector3(0.0, y1, BowModel.zc(y1)), r + (0.4 if (a == 16 or a == 30) else 0.0), r, col, true)
		# 反曲：弓梢往前(+Z)卷起
		for k in range(0, 5):
			var yy: float = float(SHORT_TIP - 1 + k / 2) * sgn
			var zz: float = BowModel.zc(float(SHORT_TIP) * sgn) + 1.0 + float(k)
			g.seg(Vector3(0.0, yy, zz - 1.0), Vector3(0.0, yy + 0.8 * sgn, zz), 1.0, 1.0, wood2, true)
	# 分配弓臂骨骼
	var bow_id: int = rig.ids["Bow"]
	for z in range(-24, 20):
		for y in range(-58, 58):
			for x in range(-14, 14):
				if not g.inb(x, y, z):
					continue
				var i: int = g.idx(x, y, z)
				if g.col[i] == 0 or g.bn[i] != bow_id:
					continue
				var aa := absf(float(y) + 0.5)
				if aa >= 26.0:
					g.bn[i] = rig.ids["Bow_U2"] if y >= 0 else rig.ids["Bow_D2"]
				elif aa >= 9.0:
					g.bn[i] = rig.ids["Bow_U1"] if y >= 0 else rig.ids["Bow_D1"]
	# 端帽(金) + 弦(浅麻色)，权重在端帽骨与搭箭点之间线性分配
	var sz: int = BowModel.STRING_Z
	for sgn2: float in [1.0, -1.0]:
		var bone := "Bow_U2" if sgn2 > 0.0 else "Bow_D2"
		var b_id: int = rig.ids[bone]
		var nock_id: int = rig.ids["Bow_Nock"]
		g.use(bone)
		var ytip := SHORT_TIP - 1 if sgn2 > 0.0 else -SHORT_TIP
		g.box(-1, ytip - 1, sz - 1, 0, ytip + 1, sz + 1, au2)
		for a2 in range(0, SHORT_TIP - 1):
			var y := a2 if sgn2 > 0.0 else -a2 - 1
			var t := (float(a2) + 0.5) / float(SHORT_TIP - 1)
			g._put(0, y, sz, _c("paper"), b_id, 0)
			g.set_weights(0, y, sz, [[b_id, t], [nock_id, 1.0 - t]])
	g.use("Bow_Nock")
	g.box(-1, -1, sz - 1, 0, 0, sz, _c("leather2"))
	# 箭(与其它弓同一根 Arrow 骨，局部 z=0 为箭尾)：木杆、白羽、铁箭头
	g.tx = -14
	g.ty = 45
	g.tz = -10
	g.use("Arrow")
	g.box(0, 0, 0, 1, 1, 40, wood2)
	for z2 in range(1, 7):
		g.box(0, 2, z2, 0, 3, z2, _c("white2"))
		g.box(0, -2, z2, 0, -1, z2, _c("white2"))
		g.box(2, 0, z2, 3, 0, z2, _c("white2"))
		g.box(-2, 0, z2, -1, 0, z2, _c("white2"))
	g.box(-1, -1, 41, 2, 2, 42, _c("iron3"))
	g.box(0, 0, 43, 1, 1, 44, _c("iron"))
	g.box(-2, 0, -1, 1, 1, 0, _c("leather2"))
	_end()


## 至远的弓弦(真望节点的专属弓)：她角色卡上那张反曲弓，做得更繁复华丽——深色木弓臂上一圈圈缠着金色卷草(弓背一侧每隔一段一朵金卷涡)，
## 弓梢是大的金色卷涡并往前卷，握把上下两道金箍中间嵌一颗青色宝石，两侧伸出一对小金翼；弓弦是发光的青白色，弓梢边飘着几点星光。
## 箭是金色的(金杆、白羽、发光的金箭头)。结构同 bow_short(弓臂分段绑 Bow_U1/U2、Bow_D1/D2，弦在端帽与搭箭点之间插值)
const FARTHEST_TIP := 52


func bow_farthest() -> void:
	g.tx = -16
	g.ty = 44
	g.tz = 3
	g.sym = false
	g.mode = VGrid.FILL
	g.use("Bow")
	left = false
	var wood := VGrid.hexc("#3e2416")
	var wood2 := VGrid.hexc("#55321e")
	var au := _c("gold")
	var au2 := _c("gold2")
	var au3 := _c("gold3")
	var cy := VGrid.hexc("#2ec4d0")
	var cy2 := VGrid.hexc("#bff6ff")
	# 握把：皮革 + 上下金箍 + 青色宝石 + 一对小金翼
	g.box(-2, -8, -2, 1, 8, 2, wood)
	g.box(-2, -6, -3, 1, 6, 3, _c("leather"))
	g.box(-3, 7, -3, 2, 8, 3, au)
	g.box(-3, -8, -3, 2, -7, 3, au)
	g.cur_glow = 70
	g.box(-1, -2, -4, 0, 1, -4, cy)
	g.cur_glow = 120
	g.box(-1, -1, -5, 0, 0, -5, cy2)
	g.cur_glow = 0
	for sgn0: int in [1, -1]:
		for k0 in range(5):
			g.box(-1, 9 * sgn0 + k0 * sgn0, -3 - k0, 0, 9 * sgn0 + k0 * sgn0, -2 - k0, au2 if k0 < 4 else au3)
	# 弓臂：缠金色卷草；弓背一侧每隔一段一朵金卷涡
	for sgn: float in [1.0, -1.0]:
		for a in range(9, FARTHEST_TIP):
			var y0 := float(a) * sgn
			var y1 := float(a + 1) * sgn
			var r := lerpf(2.0, 1.1, float(a - 9) / float(FARTHEST_TIP - 9))
			var col: int = wood if (a % 7) < 5 else wood2
			if (a % 6) == 0:
				col = au
			g.seg(Vector3(0.0, y0, BowModel.zc(y0)), Vector3(0.0, y1, BowModel.zc(y1)), r + (0.35 if (a % 6) == 0 else 0.0), r, col, true)
		for ca: int in [15, 27, 39]:
			var yc := float(ca) * sgn
			var zc0: float = BowModel.zc(yc) - 2.0
			for k in range(6):
				var ang: float = float(k) * 0.9
				var yy0: float = yc + sgn * cos(ang) * 1.6
				var zz0: float = zc0 - 1.0 - sin(ang) * 1.6 - float(k) * 0.25
				g.seg(Vector3(0.0, yy0, zz0), Vector3(0.0, yy0 + 0.6 * sgn, zz0 - 0.4), 0.7, 0.7, au2, true)
		# 大金卷涡弓梢(往前卷)
		for k2 in range(0, 8):
			var yy: float = float(FARTHEST_TIP - 1) * sgn + float(k2) * 0.35 * sgn
			var zz: float = BowModel.zc(float(FARTHEST_TIP) * sgn) + 1.0 + float(k2) * 0.9
			g.seg(Vector3(0.0, yy, zz - 1.0), Vector3(0.0, yy + 0.8 * sgn, zz), 1.1, 1.1, au if k2 < 6 else au3, true)
		# 弓梢边的星光
		g.cur_glow = 130
		var ys: int = int((FARTHEST_TIP + 3) * sgn)
		var zs: int = int(BowModel.zc(float(FARTHEST_TIP) * sgn)) + 9
		g.box(0, ys, zs, 0, ys, zs, cy2)
		g.box(0, ys - 4 * int(sgn), zs + 3, 0, ys - 4 * int(sgn), zs + 3, cy2)
		g.cur_glow = 0
	# 分配弓臂骨骼
	var bow_id: int = rig.ids["Bow"]
	for z in range(-24, 24):
		for y in range(-60, 60):
			for x in range(-14, 14):
				if not g.inb(x, y, z):
					continue
				var i: int = g.idx(x, y, z)
				if g.col[i] == 0 or g.bn[i] != bow_id:
					continue
				var aa := absf(float(y) + 0.5)
				if aa >= 30.0:
					g.bn[i] = rig.ids["Bow_U2"] if y >= 0 else rig.ids["Bow_D2"]
				elif aa >= 10.0:
					g.bn[i] = rig.ids["Bow_U1"] if y >= 0 else rig.ids["Bow_D1"]
	# 端帽(金) + 发光的青白色弓弦
	var sz: int = BowModel.STRING_Z
	for sgn2: float in [1.0, -1.0]:
		var bone := "Bow_U2" if sgn2 > 0.0 else "Bow_D2"
		var b_id: int = rig.ids[bone]
		var nock_id: int = rig.ids["Bow_Nock"]
		g.use(bone)
		var ytip := FARTHEST_TIP - 1 if sgn2 > 0.0 else -FARTHEST_TIP
		g.box(-1, ytip - 1, sz - 1, 0, ytip + 1, sz + 1, au2)
		for a2 in range(0, FARTHEST_TIP - 1):
			var y := a2 if sgn2 > 0.0 else -a2 - 1
			var t := (float(a2) + 0.5) / float(FARTHEST_TIP - 1)
			g._put(0, y, sz, cy2, b_id, 60)
			g.set_weights(0, y, sz, [[b_id, t], [nock_id, 1.0 - t]])
	g.use("Bow_Nock")
	g.box(-1, -1, sz - 1, 0, 0, sz, au3)
	# 金箭
	g.tx = -14
	g.ty = 45
	g.tz = -10
	g.use("Arrow")
	g.box(0, 0, 0, 1, 1, 40, au2)
	for z2 in range(1, 7):
		g.box(0, 2, z2, 0, 3, z2, _c("white2"))
		g.box(0, -2, z2, 0, -1, z2, _c("white2"))
		g.box(2, 0, z2, 3, 0, z2, _c("white2"))
		g.box(-2, 0, z2, -1, 0, z2, _c("white2"))
	g.cur_glow = 90
	g.box(-1, -1, 41, 2, 2, 42, au)
	g.box(0, 0, 43, 1, 1, 44, VGrid.hexc("#fff2b0"))
	g.cur_glow = 0
	g.box(-2, 0, -1, 1, 1, 0, _c("leather2"))
	_end()


## 钓鱼竿(追猎节点·意外渔获的钓鱼动作)：握在左手里(绑 Hand_L，不绑 Weapon_L——双持武器收起时竿子还在)，平时隐藏，钓鱼时由 BattleView 显示。
## 局部坐标同左手武器：原点 = 左手握点，+Y = 竿身方向；ROD_LEN = 竿尖(画鱼线的起点)
const ROD_LEN := 78


func hunter_rod() -> void:
	left = true
	g.sym = false
	g.mode = VGrid.FILL
	g.cur_glow = 0
	g.tx = 16
	g.ty = 44
	g.tz = 3
	g.use("Hand_L")
	var cork := VGrid.hexc("#c9a46a")
	var cork2 := VGrid.hexc("#a8844f")
	var cane := VGrid.hexc("#d7bf7a")
	var cane2 := VGrid.hexc("#9c7f40")
	var reel := VGrid.hexc("#8c8f96")
	# 竿柄(软木) + 竿尾帽
	B(-1, -10, -1, 0, 3, 0, cork)
	for ry: int in [-8, -4, 0]:
		B(-1, ry, -1, 0, ry, 0, cork2)
	B(-1, -12, -1, 0, -11, 0, cane2)
	# 卷线轮(挂在竿柄下方)
	B(-2, -3, 1, 1, 0, 3, reel)
	D(-2, -2, 4, cane2)
	# 竿身：越往上越细(2 格 → 1 格)，每 10 格一个竹节
	for y in range(4, ROD_LEN + 1):
		var c: int = cane2 if y % 10 == 0 else cane
		if y < 34:
			B(-1, y, -1, 0, y, 0, c)
		else:
			D(0, y, 0, c)
	D(0, ROD_LEN, 0, VGrid.hexc("#d0303a"))
	_end()


func bow_plain() -> void:
	g.tx = -16
	g.ty = 44
	g.tz = 3
	g.sym = false
	g.mode = VGrid.FILL
	g.use("Bow")
	left = false
	var wood := _c("wood")
	var wood2 := _c("wood2")
	# 握把
	g.box(-2, -8, -2, 1, 8, 2, wood)
	g.box(-2, -5, -3, 1, 5, 3, _c("leather"))
	g.box(-3, 6, -3, 2, 7, 3, _c("leather2"))
	g.box(-3, -7, -3, 2, -6, 3, _c("leather2"))
	# 弓臂(沿 model_bow 的曲线)
	for sgn: float in [1.0, -1.0]:
		for a in range(8, 50):
			var y0 := float(a) * sgn
			var y1 := float(a + 1) * sgn
			var r := lerpf(1.7, 1.0, float(a - 8) / 42.0)
			g.seg(Vector3(0.0, y0, BowModel.zc(y0)), Vector3(0.0, y1, BowModel.zc(y1)), r, r, wood if (a % 10) < 7 else wood2, true)
	# 分配弓臂骨骼
	var bow_id: int = rig.ids["Bow"]
	for z in range(-24, 20):
		for y in range(-58, 58):
			for x in range(-14, 14):
				if not g.inb(x, y, z):
					continue
				var i: int = g.idx(x, y, z)
				if g.col[i] == 0 or g.bn[i] != bow_id:
					continue
				var aa := absf(float(y) + 0.5)
				if aa >= 29.0:
					g.bn[i] = rig.ids["Bow_U2"] if y >= 0 else rig.ids["Bow_D2"]
				elif aa >= 9.0:
					g.bn[i] = rig.ids["Bow_U1"] if y >= 0 else rig.ids["Bow_D1"]
	# 端帽 + 弦(麻绳色，不发光)，权重在端帽骨与搭箭点之间线性分配
	var sz: int = BowModel.STRING_Z
	for sgn2: float in [1.0, -1.0]:
		var bone := "Bow_U2" if sgn2 > 0.0 else "Bow_D2"
		var b_id: int = rig.ids[bone]
		var nock_id: int = rig.ids["Bow_Nock"]
		g.use(bone)
		var ytip := 49 if sgn2 > 0.0 else -50
		g.box(-1, ytip - 1, sz - 1, 0, ytip + 1, sz + 1, _c("iron3"))
		for a2 in range(0, 49):
			var y := a2 if sgn2 > 0.0 else -a2 - 1
			var t := (float(a2) + 0.5) / 49.0
			g._put(0, y, sz, _c("paper2"), b_id, 0)
			g.set_weights(0, y, sz, [[b_id, t], [nock_id, 1.0 - t]])
	g.use("Bow_Nock")
	g.box(-1, -1, sz - 1, 0, 0, sz, _c("leather2"))
	# 朴素的箭(与华丽款同一根 Arrow 骨，局部 z=0 为箭尾)
	g.tx = -14
	g.ty = 45
	g.tz = -10
	g.use("Arrow")
	g.box(0, 0, 0, 1, 1, 40, _c("wood2"))
	for z2 in range(1, 7):
		g.box(0, 2, z2, 0, 3, z2, _c("white2"))
		g.box(0, -2, z2, 0, -1, z2, _c("white2"))
		g.box(2, 0, z2, 3, 0, z2, _c("white2"))
		g.box(-2, 0, z2, -1, 0, z2, _c("white2"))
	g.box(-1, -1, 41, 2, 2, 42, _c("iron3"))
	g.box(0, 0, 43, 1, 1, 44, _c("iron"))
	g.box(-2, 0, -1, 1, 1, 0, _c("leather2"))
	_end()



# ====================================================================== 黑键 / 白键(变奏节点的专属法器)：钢琴
## 别人拿：W_focus_piano —— 托在右手上的小钢琴(黑漆金边、红挂旗)，法器约定(放在拳头上方 +Z、-Y 朝前)，套通用的 idle / run / attack_focus。
## 她本人拿：W_focus_grand(恶魔形态，黑键：黑漆金边、酒红内衬、红挂旗) / W_focus_grand_white(天使形态，白键：白漆金边、淡蓝内衬与挂旗)——
##   一台按棋子比例的大三角钢琴，不挂在手上：整台刚性挂在 Root 骨上(所有体素绑 Root，不用 _begin 的 Bow 坐标系)，
##   放在她身前(模型坐标)：她站在琴后面弹(anim_chars 的 idle / run / attack_pianist_play 把手钉在下面这几个常量给的琴键上)。
##   形状：左侧(+X，低音侧)直边、右侧弧边往里收到琴尾；琴盖铰链在左直边上、右侧被金色撑杆撑起 GRAND_LID_DEG；三条带金箍和宝石的琴腿；
##   右前角琴沿上搭着一面挂旗(金边百合纹 + 流苏)；琴身上下沿金边、左侧一个金色高音谱号、右侧弧边一枚百合纹。
const GRAND_KEY_Y := 52                  # 白键面(白键顶的上表面，体素)：她的腰(~48)和胸(~60)之间
const GRAND_KEY_Z0 := 9                  # 琴键前沿(朝她)
const GRAND_KEY_Z1 := 16                 # 琴键后沿(琴身名牌板前)
const GRAND_KEY_X0 := -18                # 琴键的 x 范围(格子)
const GRAND_KEY_X1 := 17
const GRAND_CASE_Z := 17                 # 琴身前沿(名牌板)
const GRAND_TOP := 56                    # 琴身顶沿(格子)
const GRAND_BOT := 40                    # 琴身底沿(格子)；下面是琴腿
const GRAND_HALF := 21.0                 # 琴身半宽(连续坐标：x -21..21)
const GRAND_LID_DEG := 30.0              # 琴盖掀起的角度
const GRAND_LID_Z0 := 28                 # 掀起的琴盖从这里开始(前段的翻盖折回来叠在琴盖上，琴身前段敞着：别挡着她)
const GRAND_LEGS := [Vector2(16.0, 21.5), Vector2(-16.0, 21.5), Vector2(12.5, 47.0)]   # 琴腿中心(x, z)
const GRAND_TAIL := 54.5                 # 琴尾(连续坐标；体素网格 z 上限 55)
const PIANO_FLEUR := ["...#...", "..###..", ".#.#.#.", "##.#.##", "#..#..#", ".#####.", "...#...", "..#.#.."]
const PIANO_CLEF := ["..##.", ".#..#", ".#..#", "..#.#", "..##.", ".##..", "#.#..", "#.###", "#.#.#", ".###.", "..#..", ".##.."]


func _piano_pal(white: bool) -> Dictionary:
	var h := func(s: String) -> int: return VGrid.hexc(s)
	var p := {"au": h.call("#c4893a"), "au2": h.call("#e0ac58"), "au3": h.call("#8e5f26"),
		"wk": h.call("#f2ede4"), "wk2": h.call("#d2cabd"), "wk3": h.call("#e2dbcf"), "bk": h.call("#1c1820"), "bk2": h.call("#2e2934")}
	if white:
		p.merge({"k": h.call("#e6e1d8"), "k2": h.call("#cfc8bc"), "k3": h.call("#f2eee8"),
			"in": h.call("#7eaed8"), "fl": h.call("#86b6dc"), "fl2": h.call("#6a98c2"), "fl3": h.call("#a8cfea"),
			"tas": h.call("#4a88cc"), "gem": h.call("#3f7fcf"), "gem2": h.call("#a8dcff"), "str": h.call("#b08a40")}, true)
	else:
		p.merge({"k": h.call("#231f28"), "k2": h.call("#18151c"), "k3": h.call("#36303e"),
			"in": h.call("#5c1620"), "fl": h.call("#9a2a36"), "fl2": h.call("#7a1e2a"), "fl3": h.call("#b23440"),
			"tas": h.call("#c81e2a"), "gem": h.call("#c81e2a"), "gem2": h.call("#ff7a6a"), "str": h.call("#8e6430")}, true)
	return p


## 琴身俯视轮廓(x, z)：左直边 x = 21、右侧前段直边 x = -21，从 z 24 起弧边往里收(先凹后凸)，琴尾圆角
static func _grand_outline() -> PackedVector2Array:
	var poly := PackedVector2Array()
	var z0 := float(GRAND_CASE_Z)
	poly.append(Vector2(GRAND_HALF, z0))
	poly.append(Vector2(GRAND_HALF, GRAND_TAIL - 8.5))
	for i in range(1, 9):
		var a: float = deg_to_rad(float(i) * 90.0 / 8.0)
		poly.append(Vector2(13.0 + 8.0 * cos(a), GRAND_TAIL - 8.5 + 8.5 * sin(a)))
	for i in range(1, 21):
		var t: float = 1.0 - float(i) / 20.0
		var s: float = t * t * (3.0 - 2.0 * t)
		poly.append(Vector2(-GRAND_HALF + (13.0 + GRAND_HALF) * s, 24.0 + (GRAND_TAIL - 24.0) * t))
	poly.append(Vector2(-GRAND_HALF, z0))
	return poly


static func _poly_edge(q: Vector2, poly: PackedVector2Array) -> float:
	var best := 1e9
	for i in range(poly.size()):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]
		var ab: Vector2 = b - a
		var t: float = clampf((q - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
		best = minf(best, q.distance_to(a + ab * t))
	return best


## 字符画贴到琴身外壁：沿 -X(dir = -1，从右侧往里) 或 +X(dir = 1，从左侧往里)找第一个实心格改色；rows[0] 在上，(z0, y0) = 左上角，列往 +Z(flip = 往 -Z)
func _piano_decal(rows: Array, z0: int, y0: int, dir: int, c: int, flip: bool = false) -> void:
	for r in range(rows.size()):
		var row: String = rows[r]
		for i in range(row.length()):
			if row[i] != "#":
				continue
			var z: int = z0 + (row.length() - 1 - i if flip else i)
			var y: int = y0 - r
			var x: int = 23 if dir > 0 else -24
			while x > -25 and x < 24:
				if g.solid(x, y, z):
					g.col[g.idx(x, y, z)] = c
					break
				x -= dir


func grand_piano(white: bool) -> void:
	var P2: Dictionary = _piano_pal(white)
	var k: int = P2["k"]
	var k2: int = P2["k2"]
	var k3: int = P2["k3"]
	var au: int = P2["au"]
	var au2: int = P2["au2"]
	var au3: int = P2["au3"]
	g.sym = false
	g.mode = VGrid.FILL
	g.cur_glow = 0
	g.tx = 0
	g.ty = 0
	g.tz = 0
	g.use("Root")
	var poly: PackedVector2Array = _grand_outline()
	# ---- 琴身：外壁两格厚(上下沿金边)，里面是音板(内衬色) + 一排排琴弦 + 一道金色铁骨横梁
	for z in range(GRAND_CASE_Z, 60):
		for x in range(-22, 22):
			var q := Vector2(float(x) + 0.5, float(z) + 0.5)
			if not Geometry2D.is_point_in_polygon(q, poly):
				continue
			var d: float = _poly_edge(q, poly)
			for y in range(GRAND_BOT, GRAND_TOP + 1):
				var c: int = 0
				if d < 2.0:
					if d < 1.0 and (y == GRAND_TOP or y == GRAND_BOT):
						c = au
					elif y == GRAND_TOP:
						c = k3
					elif y == GRAND_BOT + 1 and d < 1.0:
						c = au3
					else:
						c = k
				elif y < 49:
					c = k2
				elif y == 49:
					c = P2["in"]
				elif y == 50:
					# 前段金色铁骨(一排调音钉) → 一道横梁 → 一排排琴弦
					if d < 2.6:
						c = au3
					elif z < GRAND_CASE_Z + 6:
						c = au2 if (z == GRAND_CASE_Z + 3 and x % 2 == 0) else au3
					elif z == GRAND_CASE_Z + 6 or z == GRAND_CASE_Z + 7:
						c = au
					elif x % 3 == 0:
						c = P2["str"]
				if c != 0:
					g.put(x, y, z, c)
	# 名牌板(琴身前壁朝她的一面，琴键后面露出来的那一条)：正中一枚金色小百合纹
	var badge := [".#.#.", "#####", ".###.", "..#.."]
	for r in range(badge.size()):
		var row: String = badge[r]
		for i in range(row.length()):
			if row[i] == "#":
				g.put(-3 + i, 55 - r, GRAND_CASE_Z, au2 if r == 1 else au)
	# 外壁装饰：左侧(直边)金色高音谱号 + 百合纹，右侧弧边一枚百合纹
	_piano_decal(PIANO_CLEF, 29, 54, 1, au, true)
	_piano_decal(PIANO_FLEUR, 37, 51, 1, au, true)
	_piano_decal(PIANO_FLEUR, 32, 51, -1, au)
	# ---- 琴键床 + 两侧琴颊(琴颊前上角削掉一格，顶上金边)
	for z in range(GRAND_KEY_Z0, GRAND_CASE_Z):
		for x in range(GRAND_KEY_X0, GRAND_KEY_X1 + 1):
			for y in range(46, GRAND_KEY_Y - 2):
				g.put(x, y, z, au if (y == GRAND_KEY_Y - 3 and z == GRAND_KEY_Z0) else k)
	for sx: int in [GRAND_KEY_X1 + 1, GRAND_KEY_X0 - 3]:
		for z in range(GRAND_KEY_Z0 - 1, GRAND_CASE_Z):
			for y in range(46, 55):
				if z == GRAND_KEY_Z0 - 1 and y >= 53:
					continue
				for x in range(sx, sx + 3):
					var c2: int = k
					if y == 54 or (z == GRAND_KEY_Z0 - 1 and y == 52):
						c2 = au
					elif y == 46:
						c2 = au3
					g.put(x, y, z, c2)
	# ---- 琴键：白键两格一键(第一列稍暗 = 键缝)，前脸稍暗；黑键一格宽、高出一格，只占琴键后段
	for x in range(GRAND_KEY_X0, GRAND_KEY_X1 + 1):
		var cx: int = x - GRAND_KEY_X0
		for z in range(GRAND_KEY_Z0, GRAND_KEY_Z1 + 1):
			for y in range(GRAND_KEY_Y - 2, GRAND_KEY_Y):
				var c3: int = P2["wk"]
				if cx % 2 == 0:
					c3 = P2["wk2"]
				elif z == GRAND_KEY_Z0:
					c3 = P2["wk3"]
				g.put(x, y, z, c3)
	# 一个八度 7 个白键：第 1-2、2-3、4-5、5-6、6-7 键之间有黑键(从左边低音往右数)
	for wk in range(1, 18):
		var n: int = wk % 7
		if n == 3 or n == 0:
			continue
		var bx: int = GRAND_KEY_X1 - wk * 2 + 1
		if bx < GRAND_KEY_X0 or bx > GRAND_KEY_X1:
			continue
		for z in range(GRAND_KEY_Z0 + 3, GRAND_KEY_Z1 + 1):
			g.put(bx, GRAND_KEY_Y, z, P2["bk2"] if z == GRAND_KEY_Z0 + 3 else P2["bk"])
	# ---- 琴腿(三条)：上端金箍、中段一颗宝石(四面)、下段金环、金色脚套
	for lg: Vector2 in GRAND_LEGS:
		_grand_leg(lg.x, lg.y, P2)
	# ---- 琴盖：铰链在左直边顶上，右侧弧边被撑起；从 GRAND_LID_Z0 开始(前段翻盖折回来叠在上面：多一层、后沿一道金线)，
	# 边缘一圈金、底面正中一枚金色百合纹(整块一个颜色：上下两层分色的话斜面的台阶会变成一条条横纹)
	var a: float = deg_to_rad(GRAND_LID_DEG)
	var hinge := Vector2(GRAND_HALF, float(GRAND_TOP) + 1.0)
	var e := Vector2(-cos(a), sin(a))
	var nrm := Vector2(sin(a), cos(a))
	var flap_z: int = GRAND_LID_Z0 + 8
	for z in range(GRAND_LID_Z0, 60):
		for y in range(GRAND_TOP, GRAND_TOP + 30):
			for x in range(-24, 23):
				var dv: Vector2 = Vector2(float(x) + 0.5, float(y) + 0.5) - hinge
				var u: float = dv.dot(e)
				var hh: float = dv.dot(nrm)
				var top_h: float = 2.9 if z <= flap_z else 1.6
				if hh < -0.25 or hh > top_h or u < -0.5:
					continue
				var q2 := Vector2(GRAND_HALF - u, float(z) + 0.5)
				if not Geometry2D.is_point_in_polygon(q2, poly):
					continue
				var dd: float = _poly_edge(q2, poly)
				var c4: int = k
				if dd < 1.0 or z == GRAND_LID_Z0 or (z == flap_z and hh > 1.6):
					c4 = au
				elif hh <= 0.75:
					# 底面的百合纹(2 格一像素)
					var fu: int = int(floor((u - 11.0) / 2.0)) + 3
					var fz: int = int(floor((float(z) - 33.0) / 2.0))
					if fz >= 0 and fz < PIANO_FLEUR.size() and fu >= 0 and fu < 7 and str(PIANO_FLEUR[fz])[fu] == "#":
						c4 = au
				g.put(x, y, z, c4)
	# 撑杆(金色)：从右侧弧边的琴沿撑到琴盖底面
	var sz: float = 32.5
	var xr: float = 0.0
	for x in range(-21, 21):
		if Geometry2D.is_point_in_polygon(Vector2(float(x) + 0.5, sz), poly):
			xr = float(x) + 2.5
			break
	var tip: Vector2 = hinge + e * (GRAND_HALF - (xr + 3.0))
	g.seg(Vector3(xr, float(GRAND_TOP) + 1.0, sz), Vector3(tip.x, tip.y - 0.6, sz), 0.75, 0.75, au)
	g.seg(Vector3(xr, float(GRAND_TOP) + 1.0, sz), Vector3(xr, float(GRAND_TOP) + 1.5, sz), 1.2, 1.2, au3)
	# ---- 挂旗：搭在右前角的琴沿上，垂到琴身外面；金边、金色百合纹，下端尖 + 金结流苏
	_grand_banner(P2)
	_end()


func _grand_leg(cx: float, cz: float, P2: Dictionary) -> void:
	var k: int = P2["k"]
	var au: int = P2["au"]
	var au2: int = P2["au2"]
	var au3: int = P2["au3"]
	g.ytaper(GRAND_BOT - 3, GRAND_BOT - 1, cx, cz, 3.7, 3.7, cx, cz, 3.7, 3.7, au, 2.8)
	g.ytaper(GRAND_BOT - 4, GRAND_BOT - 4, cx, cz, 3.3, 3.3, cx, cz, 3.3, 3.3, au3, 2.8)
	g.ytaper(22, GRAND_BOT - 5, cx, cz, 2.4, 2.4, cx, cz, 3.3, 3.3, k, 2.6)
	g.ytaper(8, 21, cx, cz, 2.0, 2.0, cx, cz, 2.4, 2.4, k, 2.6)
	g.ytaper(6, 7, cx, cz, 2.6, 2.6, cx, cz, 2.6, 2.6, au, 2.8)
	g.ytaper(2, 5, cx, cz, 2.1, 2.1, cx, cz, 2.1, 2.1, k, 2.6)
	g.ytaper(0, 1, cx, cz, 2.5, 2.5, cx, cz, 2.5, 2.5, au3, 2.8)
	# 宝石：四面各一颗菱形(金框)
	var ix: int = int(floor(cx))
	var iz: int = int(floor(cz))
	for side: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		for dy in range(-2, 3):
			for dw in range(-2, 3):
				var m: int = absi(dy) + absi(dw)
				if m > 2:
					continue
				var c: int = au2 if m == 2 else (P2["gem"] if m == 1 else P2["gem2"])
				var y: int = 27 + dy
				var x: int = ix + dw
				var z: int = iz + dw
				if side.x != 0:
					x = ix + side.x * 3
				else:
					z = iz + side.y * 3
				g.cur_glow = 0 if m == 2 else 35
				g.put(x, y, z, c)
	g.cur_glow = 0


func _grand_banner(P2: Dictionary) -> void:
	var fl: int = P2["fl"]
	var fl2: int = P2["fl2"]
	var fl3: int = P2["fl3"]
	var au: int = P2["au"]
	var au2: int = P2["au2"]
	var z0 := 18
	var z1 := 26
	var x_out: int = -int(GRAND_HALF) - 1
	# 搭在琴沿顶上的一段
	for z in range(z0, z1 + 1):
		for x in range(x_out, x_out + 4):
			g.put(x, GRAND_TOP + 1, z, au if (z == z0 or z == z1) else fl2)
	# 垂下来的旗面(两格厚：外层旗面、里层暗色)，下端尖
	var zc: float = float(z0 + z1 + 1) * 0.5
	for z in range(z0, z1 + 1):
		var bot: float = 26.0 + absf(float(z) + 0.5 - zc) * 1.1
		for y in range(int(ceil(bot)), GRAND_TOP + 2):
			var c: int = fl
			if z == z0 or z == z1 or float(y) < bot + 1.0:
				c = au
			elif y == 52 or y == 31:
				c = fl3
			g.put(x_out, y, z, c)
			g.put(x_out + 1, y, z, fl2)
	# 旗面中间的百合纹(贴在旗面外一格)
	for r in range(PIANO_FLEUR.size()):
		var row: String = PIANO_FLEUR[r]
		for i in range(row.length()):
			if row[i] == "#":
				g.put(x_out, 46 - r, z0 + 1 + i - 1 + 1, au2)
	# 流苏：金结 + 一束(下端略散开)
	var tz: int = int(floor(zc)) - 1
	g.box(x_out - 1, 23, tz, x_out, 26, tz + 1, au)
	g.put(x_out - 1, 26, tz, au2)
	for y in range(15, 23):
		var spread: bool = y < 17
		for dz in range(-1 if spread else 0, 3 if spread else 2):
			g.put(x_out - 1 + (1 if (y + dz) % 2 == 0 else 0), y, tz + dz, P2["tas"] if (dz + y) % 4 != 0 else fl2)


## 别人拿的小钢琴(W_focus_piano)：大三角钢琴的缩小版托在拳头上方(法器约定：+Z = 上，-Y = 朝前)。琴键朝前(-Y：对着前方 / 镜头，一眼看得出是钢琴)，
## 琴尾朝着拿它的人；黑漆金边、琴盖往外侧(右，-X)掀起(金撑杆)、右前角一面红挂旗、三条短琴腿站在拳头上。
## 下面按"琴键朝 +Y"的坐标写(琴键 y 3..6、琴身 y 2..-15)，_ps / _pb 写入时翻到 y' = -y - 10(琴键 y -16..-13、琴身 y -12..5)
func _ps(x: int, y: int, z: int, c: int) -> void:
	D(x, -y - 10, z, c)


func _pb(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, c: int) -> void:
	B(x0, -maxi(y0, y1) - 10, z0, x1, -mini(y0, y1) - 10, z1, c)


func piano_small() -> void:
	_begin(false)
	var P2: Dictionary = _piano_pal(false)
	var k: int = P2["k"]
	var k2: int = P2["k2"]
	var au: int = P2["au"]
	# 俯视轮廓(x, y)：左直边 x = 8，前沿(名牌板) y = 3，右侧弧边往琴尾(-Y)收
	var poly := PackedVector2Array([Vector2(8.0, 3.0), Vector2(8.0, -11.0), Vector2(7.2, -13.5), Vector2(5.0, -15.0), Vector2(2.5, -15.0)])
	for i in range(1, 11):
		var t: float = 1.0 - float(i) / 10.0
		var s: float = t * t * (3.0 - 2.0 * t)
		poly.append(Vector2(-8.0 + 10.5 * s, 0.0 - 15.0 * t))
	poly.append(Vector2(-8.0, 3.0))
	# 琴身 z 6..10：外壁一格、上沿金边；里面红色音板 + 金弦
	for y in range(-16, 3):
		for x in range(-9, 9):
			var q := Vector2(float(x) + 0.5, float(y) + 0.5)
			if not Geometry2D.is_point_in_polygon(q, poly):
				continue
			var d: float = _poly_edge(q, poly)
			for z in range(6, 11):
				var c: int = 0
				if d < 1.0:
					c = au if z == 10 else k
				elif z < 8:
					c = k2
				elif z == 8:
					c = P2["in"] if x % 2 != 0 else P2["str"]
				if c != 0:
					_ps(x, y, z, c)
	# 琴键(朝 +Y)：琴键床 + 白键(一格一键，隔列稍暗) + 黑键(高一格，后段)，两侧琴颊
	_pb(-7, 3, 6, 6, 6, 7, k)
	for x in range(-7, 7):
		_pb(x, 3, 8, x, 6, 8, P2["wk"] if (x + 7) % 2 == 0 else P2["wk3"])
	for x: int in [5, 3, 0, -2, -4, -7]:
		_pb(x, 3, 9, x, 4, 9, P2["bk"])
	_pb(7, 3, 6, 7, 6, 9, k)
	_pb(-8, 3, 6, -8, 6, 9, k)
	_ps(7, 6, 9, au)
	_ps(-8, 6, 9, au)
	# 三条短琴腿(脚套金色)
	for lg: Vector2i in [Vector2i(5, 0), Vector2i(-6, 0), Vector2i(4, -11)]:
		_pb(lg.x, lg.y, 4, lg.x + 1, lg.y + 1, 5, k)
		_pb(lg.x, lg.y, 3, lg.x + 1, lg.y + 1, 3, au)
	# 琴盖：铰链在左直边顶上(x 8, z 11)，右侧撑起 30°
	var a: float = deg_to_rad(30.0)
	var hinge := Vector2(8.0, 11.0)
	var e := Vector2(-cos(a), sin(a))
	var nrm := Vector2(sin(a), cos(a))
	for y in range(-16, 3):
		for z in range(10, 21):
			for x in range(-10, 9):
				var dv: Vector2 = Vector2(float(x) + 0.5, float(z) + 0.5) - hinge
				var u: float = dv.dot(e)
				var hh: float = dv.dot(nrm)
				if hh < -0.2 or hh > 1.2 or u < -0.5:
					continue
				var q2 := Vector2(8.0 - u, float(y) + 0.5)
				if not Geometry2D.is_point_in_polygon(q2, poly):
					continue
				_ps(x, y, z, au if _poly_edge(q2, poly) < 0.8 else k)
	# 撑杆(金)：从右侧琴沿撑到琴盖
	var tip: Vector2 = hinge + e * 12.0
	for i in range(0, 9):
		var p := Vector3(-5.5, -6.5, 11.0).lerp(Vector3(tip.x, -6.5, tip.y - 0.5), float(i) / 8.0)
		_ps(int(floor(p.x)), int(floor(p.y)), int(floor(p.z)), au)
	# 挂旗(右前角，垂在外面)：红底金边，下端金穗 + 红流苏
	for y in range(-3, 1):
		_ps(-9, y, 10, au if (y == -3 or y == 0) else P2["fl2"])
		for z in range(4, 11):
			var c2: int = P2["fl"]
			if y == -3 or y == 0 or z == 4:
				c2 = au
			elif z == 7:
				c2 = P2["fl3"]
			if z == 4 and (y == -3 or y == 0):
				continue
			_ps(-10, y, z, c2)
	_ps(-10, -2, 3, au)
	_ps(-10, -1, 3, au)
	_pb(-10, -2, 1, -10, -1, 2, P2["tas"])
	_end()


# ====================================================================== 通用武器(没有主人、谁都能装的专属外观)
## 这几把都是固定配色(VGrid.hexc 画死，不用 _c("cyan") 系强调色)：不随武器颜色换色。饱和色取暗一档(渲染会把饱和色提亮)。

## 双生烛台(法器，黑)：一座手持的双头烛台，托在拳头上方(法器约定：+Z = 上，-Y = 前，+X = 拇指一侧 / 朝身体中线；
## 拳头约 x -3..3、y -7..0、z -4..3，中心 (-0.5, -3.5))。黑铁烛柱 + 一颗暗金烛节，柱顶一根矮尖顶(哥特式)；
## 两条黑铁烛臂往两侧先往下弯、再往上扬，弯底各垂一颗暗金小尖，臂端暗金烛盘各插一支象牙白蜡烛：
## 外侧(-X)那支烛火暖金色(治愈)，内侧(+X)那支冷紫色(伤害)。底座小圆盘(暗金边)四个尖拱形镂空 + 一圈小拱廊。
## 两条臂所在的竖直面绕 Z 转 CANDLE_ROT：内侧那支往前(-Y)挪，待机举在胸前时不挡脸。全高 z 1..25(z 1..3 藏在拳头里)，宽约 x -9..8
const CANDLE_CX := 7.5                                    # 蜡烛中心离烛柱中心(-0.5, -3.5)的水平距离
const CANDLE_ROT := 25.0                                  # 臂面的转角(度)：+X 那条臂往 -Y(前)偏
const CANDLE_Z := [13, 15, 19]                            # 烛盘 / 蜡烛底 / 蜡烛顶(局部 Z)


func candelabra() -> void:
	_begin(false)
	var fe := VGrid.hexc("#34313b")                        # 黑铁
	var fe2 := VGrid.hexc("#45414e")
	var fe3 := VGrid.hexc("#5e5969")                       # 黑铁高光
	var au := VGrid.hexc("#a07a36")                        # 暗金
	var au2 := VGrid.hexc("#c49b4c")
	var au3 := VGrid.hexc("#6f5322")
	var cx := -0.5
	var cy := -3.5
	# ---- 底座：小圆盘(z 4 暗金外沿 + 黑铁面；z 5 小一圈) + 四个尖拱形镂空(对角方向)；z 6 一圈矮鼓(暗金 / 黑铁相间 = 一圈小拱廊)
	for z in range(4, 7):
		var rr: float = [4.7, 4.1, 2.7][z - 4]
		for x in range(-6, 6):
			for y in range(-9, 3):
				var dx: float = float(x) + 0.5 - cx
				var dy: float = float(y) + 0.5 - cy
				var r: float = sqrt(dx * dx + dy * dy)
				if r > rr:
					continue
				var ang: float = atan2(dy, dx)
				var c: int = fe
				if z < 6:
					# 镂空：对角方向(45° + k·90°)的尖拱孔，靠里窄、靠外宽
					var da: float = absf(wrapf(ang - PI * 0.25, -PI * 0.25, PI * 0.25))
					if r > 1.9 and r < 3.7 and da < 0.16 + 0.11 * (r - 1.9):
						continue
					if r > rr - 0.9:
						c = au if z == 4 else au2
					elif (x + y) % 3 == 0:
						c = fe2
				else:
					c = au3 if int(floor((ang + PI) / (TAU / 8.0))) % 2 == 0 else fe2
				D(x, y, z, c)
	# ---- 烛柱(2×2，z 1..3 藏在拳头里)：中间一颗暗金烛节、臂根一道箍
	for z in range(1, 13):
		for x in range(-1, 1):
			for y in range(-4, -2):
				D(x, y, z, fe3 if (x == -1 and y == -4) else fe)
	_candle_knob(cx, cy, 7, 2.3, au, au2, au3)
	_candle_knob(cx, cy, 11, 2.0, fe2, fe3, fe)
	# ---- 柱顶的矮尖顶：暗金花苞 → 黑铁尖 → 暗金尖头
	_candle_knob(cx, cy, 13, 1.6, au, au2, au3)
	for z in range(15, 18):
		for x in range(-1, 1):
			for y in range(-4, -2):
				if z == 17 and not (x == -1 and y == -4):
					continue
				D(x, y, z, fe2 if z < 17 else au2)
	# ---- 两条烛臂：从臂根(z 11)往两侧先往下弯、再往上扬到烛盘；下弯最低处垂一颗小尖(哥特式的尖饰)
	var av := Vector2(cos(deg_to_rad(CANDLE_ROT)), -sin(deg_to_rad(CANDLE_ROT)))
	for s: int in [-1, 1]:
		var sd: Vector2 = av * float(s)
		var pts := [Vector2(0.6, 11.6), Vector2(2.5, 10.0), Vector2(4.5, 9.7), Vector2(6.3, 10.9), Vector2(7.4, 12.6)]
		for i in range(pts.size() - 1):
			_candle_arm(pts[i], pts[i + 1], sd, cx, cy, fe, fe3)
		var pd := Vector2(cx, cy) + sd * 3.5
		D(int(floor(pd.x)), int(floor(pd.y)), 8, au3)
		D(int(floor(pd.x)), int(floor(pd.y)), 7, au)
		# 烛盘 + 蜡烛 + 烛火
		var pc := Vector2(cx, cy) + sd * CANDLE_CX
		_candle_cup(pc.x, pc.y, au, au2, au3)
		_candle_stick(pc.x, pc.y, s)
		if s < 0:
			_candle_flame(pc.x, pc.y, s, VGrid.hexc("#d8861a"), VGrid.hexc("#f2b636"), VGrid.hexc("#fff0b4"))     # 暖金(治愈)
		else:
			_candle_flame(pc.x, pc.y, s, VGrid.hexc("#6a2cb0"), VGrid.hexc("#9a5ce6"), VGrid.hexc("#ead6ff"))     # 冷紫(伤害)
	_end()


## 一圈截面为圆的"节"(烛节 / 箍 / 花苞)：z、z+1 两层，下层 c(外沿 c3)，上层 c2
func _candle_knob(cx: float, cy: float, z: int, r: float, c: int, c2: int, c3: int) -> void:
	for dz in range(2):
		for x in range(int(floor(cx - r)), int(ceil(cx + r)) + 1):
			for y in range(int(floor(cy - r)), int(ceil(cy + r)) + 1):
				var dx: float = float(x) + 0.5 - cx
				var dy: float = float(y) + 0.5 - cy
				var d: float = sqrt(dx * dx + dy * dy)
				if d > r:
					continue
				D(x, y, z + dz, c3 if d > r - 0.8 and dz == 0 else (c2 if dz == 1 else c))


## 烛臂的一段：从 a 到 b(a/b = (离柱心的水平距离, z))，水平方向 sd(单位向量，X-Y 平面)，截面约 2×2；上面一层是高光
func _candle_arm(a: Vector2, b: Vector2, sd: Vector2, cx: float, cy: float, c: int, c_hi: int) -> void:
	var n: int = int(ceil(a.distance_to(b) * 2.0)) + 1
	for i in range(n + 1):
		var p: Vector2 = a.lerp(b, float(i) / float(n))
		var q: Vector2 = Vector2(cx, cy) + sd * p.x
		var x0: int = int(floor(q.x - 0.5))
		var y0: int = int(floor(q.y - 0.5))
		var z0: int = int(floor(p.y - 0.5))
		for x in range(x0, x0 + 2):
			for y in range(y0, y0 + 2):
				for z in range(z0, z0 + 2):
					D(x, y, z, c_hi if z == z0 + 1 else c)


## 烛盘(暗金托盘，外沿一圈上翻) + 插口
func _candle_cup(xc: float, cy: float, au: int, au2: int, au3: int) -> void:
	var z0: int = CANDLE_Z[0]
	for x in range(int(floor(xc - 2.3)), int(ceil(xc + 2.3)) + 1):
		for y in range(int(floor(cy - 2.3)), int(ceil(cy + 2.3)) + 1):
			var dx: float = float(x) + 0.5 - xc
			var dy: float = float(y) + 0.5 - cy
			var d: float = sqrt(dx * dx + dy * dy)
			if d > 2.3:
				continue
			D(x, y, z0, au3 if d > 1.6 else au)
			if d > 1.6:
				D(x, y, z0 + 1, au2)
			elif d <= 1.5:
				D(x, y, z0 + 1, au)


## 蜡烛：2×2 象牙白，顶上一圈略暗的烛口，外侧挂一道蜡泪
func _candle_stick(xc: float, cy: float, s: int) -> void:
	var wx := VGrid.hexc("#e8dfc8")
	var wx2 := VGrid.hexc("#d3c7aa")
	var wx3 := VGrid.hexc("#f6f0e0")
	var x0: int = int(floor(xc - 0.5))
	var y0: int = int(floor(cy - 0.5))
	for z in range(CANDLE_Z[1], CANDLE_Z[2] + 1):
		for x in range(x0, x0 + 2):
			for y in range(y0, y0 + 2):
				var c: int = wx
				if z == CANDLE_Z[2]:
					c = wx2
				elif y == y0 and x == x0 + (1 if s > 0 else 0):
					c = wx3
				D(x, y, z, c)
	# 蜡泪(外侧)
	var xo: int = x0 + 2 if s > 0 else x0 - 1
	D(xo, y0, CANDLE_Z[2] - 1, wx3)
	D(xo, y0, CANDLE_Z[2] - 2, wx)
	D(xo, y0 + 1, CANDLE_Z[2], wx3)


## 烛火：泪滴形——底 2×2 → 中段十字形外焰包着亮芯 → 往上收成尖(尖往外侧偏一格，像在晃)
func _candle_flame(xc: float, cy: float, s: int, c_out: int, c_mid: int, c_core: int) -> void:
	var x0: int = int(floor(xc - 0.5))
	var y0: int = int(floor(cy - 0.5))
	var z0: int = CANDLE_Z[2] + 1
	for x in range(x0, x0 + 2):
		for y in range(y0, y0 + 2):
			D(x, y, z0, c_mid, 70)
			D(x, y, z0 + 1, c_core, 110)
			D(x, y, z0 + 2, c_core, 100)
			D(x, y, z0 + 3, c_mid, 80)
	for z in range(z0 + 1, z0 + 3):
		for k in range(2):
			D(x0 - 1, y0 + k, z, c_out, 50)
			D(x0 + 2, y0 + k, z, c_out, 50)
			D(x0 + k, y0 - 1, z, c_out, 50)
			D(x0 + k, y0 + 2, z, c_out, 50)
	var xt: int = x0 + (1 if s > 0 else 0)
	D(xt, y0, z0 + 4, c_out, 60)
	D(xt, y0 + 1, z0 + 4, c_mid, 70)
	D(xt, y0, z0 + 5, c_out, 50)


## 号令短剑(单手剑，青)：军官佩剑式的短剑。剑身比普通单手剑短一点、宽一点(刃 y 7..52，半宽 4.6 收到 3.3；华丽长剑 6..62 / 3.4)，
## 银色刃面、白亮刃口，中线一道发光的青色刻线(两侧一道暗槽)；护手是一对展开的银色小翼(往刃的方向扬起、下沿一片片羽毛，翼上嵌青线)，
## 正中嵌青宝石；深藏青皮革缠银丝的剑柄、银色柄头，柄头下挂一条青色短飘带(往 -Z = 待机时往下垂，末端燕尾分叉)。
## 刀光：刃 7..52(默认 sword 刀光 18..58)
const RALLY_BLADE := [6, 52]


func rally_sword() -> void:
	_begin(false)
	var st := VGrid.hexc("#c3cad4")                        # 刃面
	var st2 := VGrid.hexc("#eef2f6")                       # 刃口
	var st3 := VGrid.hexc("#97a1ae")                       # 刻线两侧的暗槽
	var sv := VGrid.hexc("#cfd5de")                        # 银
	var sv2 := VGrid.hexc("#9ba5b2")
	var sv3 := VGrid.hexc("#f2f5f9")
	var nv := VGrid.hexc("#1f2b3b")                        # 深藏青皮革
	var cy := VGrid.hexc("#1d9cae")                        # 青(不用调色板的 cyan：不换色)
	var cy2 := VGrid.hexc("#3fc2d0")
	var cy3 := VGrid.hexc("#126f7c")
	# ---- 剑柄：深藏青皮革斜缠银丝
	for y in range(-8, 4):
		for x in range(-1, 1):
			for z in range(-1, 1):
				D(x, y, z, sv2 if posmod(y + x - z, 3) == 0 else nv)
	# ---- 柄头(银，去角的 4×4) + 底下挂飘带的小环
	for y in range(-11, -8):
		for x in range(-2, 2):
			for z in range(-2, 2):
				if (x == -2 or x == 1) and (z == -2 or z == 1):
					continue
				D(x, y, z, sv3 if y == -9 else (sv2 if y == -11 else sv))
	B(-1, -12, -1, 0, -12, 0, sv2)
	# ---- 飘带：从柄头小环往 -Z 垂出去，微微起伏；中间一道亮青，末端燕尾分叉
	for k in range(12):
		var zr: int = -1 - k
		var yc: int = -12 - int(round(1.1 * sin(float(k) * 0.65)))
		for dy in range(-1, 2):
			if k == 0 and dy != 0:
				continue
			if k >= 9 and dy == 0:
				continue                                       # 燕尾的缺口
			var c: int = cy2 if dy == 0 else (cy3 if dy == -1 else cy)
			if k >= 9:
				c = cy if dy == 1 else cy3
			B(-1, yc + dy, zr, 0, yc + dy, zr, c)
	# ---- 护手：正中一块银座(两面嵌青宝石) + 两侧展开的小翼
	B(-2, 4, -2, 1, 6, 1, sv)
	B(-2, 6, -2, 1, 6, 1, sv3)
	for gx: int in [-2, 1]:
		B(gx, 4, -1, gx, 5, 0, cy2, 80)
	# 小翼 = 三片从根部(刃根两侧)扇形展开的羽：[仰角(度), 长度, 根部半宽]；最上面一片扬得最高(贴着刃往上)，
	# 羽与羽之间根部连成一片、梢部分叉；每片羽下沿暗一线(看得出一片片)，羽尖一格青色，最上面那片羽的中线嵌青
	var feathers := [[58.0, 12.5, 1.7], [33.0, 12.0, 1.6], [8.0, 10.0, 1.4]]
	var wc := [sv3, sv, VGrid.hexc("#b9c1cc")]
	for s: int in [-1, 1]:
		for k in range(0, 15):
			var z2: int = (2 + k) if s > 0 else (-3 - k)
			for y2 in range(2, 19):
				var px: float = float(k) + 0.5
				var py: float = float(y2) + 0.5 - 5.0
				for fi in range(feathers.size()):
					var fd: Array = feathers[fi]
					var fa: float = deg_to_rad(float(fd[0]))
					var ln: float = float(fd[1])
					var tt: float = px * cos(fa) + py * sin(fa)
					var pp: float = px * sin(fa) - py * cos(fa)               # >0 = 羽的下沿一侧
					if tt < -0.5 or tt > ln:
						continue
					var ww: float = float(fd[2]) * (1.0 - pow(maxf(tt, 0.0) / ln, 2.2)) + 0.35
					if absf(pp) > ww:
						continue
					var c2: int = wc[fi]
					if tt > ln - 1.3:
						c2 = cy2
					elif pp > ww - 0.9:
						c2 = sv2
					elif fi == 0 and tt > 3.0 and tt < 8.0 and absf(pp) < 0.6:
						c2 = cy
					B(-1, y2, z2, 0, y2, z2, c2)
					break
	# ---- 剑身：宽一点的直刃，最后 8 格收成尖；中线青色刻线(微光)，两侧暗槽；刃根一道银箍
	var y0: int = RALLY_BLADE[0]
	var y1: int = RALLY_BLADE[1]
	B(-1, y0, -5, 0, y0, 4, sv2)
	for y3 in range(y0 + 1, y1 + 1):
		var t: float = float(y3 - y0) / float(y1 - y0)
		var half: float = lerpf(4.6, 3.3, t)
		if y3 > y1 - 8:
			half = lerpf(half, 0.5, float(y3 - (y1 - 8)) / 8.0)
		var za: int = int(floor(-half))
		var zb: int = int(ceil(half)) - 1
		for z3 in range(za, zb + 1):
			var c3: int = st
			var gl := 0
			if z3 == za or z3 == zb:
				c3 = st2
			elif (z3 == -1 or z3 == 0) and y3 >= y0 + 3 and y3 <= y1 - 9:
				c3 = cy2 if (y3 % 6) == 0 else cy
				gl = 25 if (y3 % 6) == 0 else 8
			elif (z3 == -2 or z3 == 1) and y3 >= y0 + 3 and y3 <= y1 - 9:
				c3 = st3
			B(-1, y3, z3, 0, y3, z3, c3, gl)
	_end()


## 标定步枪(步枪大类 = 双手远程，黄)：利落的工具感——黄色烤漆的机匣 / 护木侧板 / 枪托 + 黑色握把、导轨、弹匣、护木、托底；
## 机匣上架一支黄铜测距瞄准镜(前端大一圈的物镜 + 蓝色镜片、后端黑目镜、侧面一颗旋钮)，镜筒顶上一条刻度尺(每 2 格一道刻度，每 4 格一道长刻度)；
## 枪口(黑色制退器)下方挂一枚朝前的黄色十字标定灯(发光)。尺寸 / 握点照 rifle() 与 sniper_rifle()：手枪式握把在原点，
## 弹匣 y -9..-6，护木 y -32..-13(底 z 1：左手托在 y -13 附近)，枪管到 y -51，制退器 -55..-52，枪托 y 7..19(往下加深到 z -3，短托)。
## 枪械约定：-Y = 枪口，+Z = 上
func spotter_rifle() -> void:
	_begin(false)
	var yl := VGrid.hexc("#c99a14")                        # 工具黄
	var yl2 := VGrid.hexc("#e0b42c")
	var yl3 := VGrid.hexc("#8f6c0c")
	var bk := VGrid.hexc("#2a2c32")
	var bk2 := VGrid.hexc("#3c3f47")
	var rb := VGrid.hexc("#18191d")                        # 橡胶 / 孔
	var gm := VGrid.hexc("#5d626c")
	var gm2 := VGrid.hexc("#7a808b")
	var br := VGrid.hexc("#b08a3c")                        # 黄铜
	var br2 := VGrid.hexc("#d2ab5a")
	var br3 := VGrid.hexc("#7c5f26")
	var lamp := VGrid.hexc("#f2c418")
	var lamp2 := VGrid.hexc("#fff09a")
	var glass := VGrid.hexc("#3f74a8")
	# ---- 手枪式握把(黑色橡胶，一道道防滑纹) + 扳机护圈 + 黄色扳机
	for z in range(-5, 3):
		B(-1, -1, z, 0, 2, z, bk if posmod(z, 2) == 0 else bk2)
	B(-1, 3, -4, 0, 3, 2, bk2)
	B(-1, -1, -6, 0, 3, -6, gm)
	B(-1, -5, 0, 0, -5, 2, gm)
	B(-1, -4, 0, 0, -2, 0, gm)
	D(-1, -3, 1, yl2)
	D(0, -3, 1, yl2)
	# ---- 机匣：黄色烤漆的方盒子(z 2..5)，每 6 格一道接缝，两侧枪灰螺丝 + 右侧黑色抛壳口；顶上黑色导轨(z 6，一格一个缺口)
	for y in range(-12, 7):
		B(-2, y, 2, 1, y, 5, yl3 if posmod(y, 6) == 0 else yl)
		B(-1, y, 6, 0, y, 6, bk2 if posmod(y, 2) == 0 else bk)
	B(-2, -12, 6, -2, 6, 6, bk)
	B(1, -12, 6, 1, 6, 6, bk)
	for sy: int in [-10, -2, 4]:
		D(-3, sy, 3, gm)
		D(2, sy, 3, gm)
	B(-3, -6, 4, -3, -3, 5, rb)
	B(-4, -4, 4, -4, -4, 4, gm2)                            # 拉机柄
	# ---- 直弹匣(握把前面)：黑，底板黄
	B(-1, -9, -4, 0, -6, 1, bk2)
	B(-1, -9, -5, 0, -6, -5, yl3)
	# ---- 护木(y -32..-13)：黑色方护木，两侧黄色侧板 + 一排散热孔，底下一条防滑纹(左手托在这里)
	B(-2, -32, 1, 1, -13, 5, bk)
	for y2 in range(-31, -14):
		B(-3, y2, 2, -3, y2, 4, yl if posmod(y2, 5) != 0 else yl3)
		B(2, y2, 2, 2, y2, 4, yl if posmod(y2, 5) != 0 else yl3)
	for y3 in range(-29, -15, 4):
		D(-3, y3, 3, rb)
		D(2, y3, 3, rb)
	for y4 in range(-31, -13, 2):
		B(-1, y4, 1, 0, y4, 1, bk2)
	# ---- 枪管(枪灰，几道亮箍) + 黑色制退器(两侧开槽，口沿一道黄)
	for y5 in range(-51, -32):
		B(-1, y5, 3, 0, y5, 4, gm2 if posmod(y5, 6) == 0 else gm)
	B(-2, -55, 2, 1, -52, 5, bk2)
	B(-2, -52, 2, 1, -52, 5, yl)
	for y6: int in [-54, -53]:
		B(-2, y6, 3, -2, y6, 4, rb)
		B(1, y6, 3, 1, y6, 4, rb)
	B(-1, -55, 3, 0, -55, 4, rb)
	# ---- 十字标定灯：挂在制退器下方(黑色灯座 + 卡箍)，朝前(-Y)一枚亮黄十字(芯更亮)
	B(-1, -50, 1, 0, -48, 2, bk)
	B(-2, -51, -3, 1, -47, 1, bk2)
	B(-2, -47, -3, 1, -47, 1, yl3)
	for x7 in range(-3, 3):
		for z7 in range(-4, 2):
			var vbar: bool = x7 >= -1 and x7 <= 0
			var hbar: bool = z7 >= -2 and z7 <= -1
			if not (vbar or hbar):
				continue
			var core: bool = vbar and hbar
			B(x7, -53, z7, x7, -52, z7, lamp2 if core else lamp, 130 if core else 90)
	# ---- 枪托：往后(+Y)并往下加深(Q 版短托)，黄漆 + 黑色托腮板，黑橡胶托底
	for y8 in range(7, 18):
		var t: float = float(y8 - 7) / 10.0
		var zlo: int = int(round(lerpf(1.0, -3.0, t)))
		B(-1, y8, zlo, 0, y8, 5, yl3 if posmod(y8, 6) == 0 else yl)
	B(-1, 9, 6, 0, 14, 6, bk2)
	B(-2, 18, -3, 1, 19, 5, rb)
	# ---- 瞄准镜(黄铜)：两只镜座(黑) → 圆镜筒(y -19..-4) → 前端大一圈的物镜(蓝镜片) / 后端黑目镜；侧面一颗旋钮
	for my: int in [-16, -7]:
		B(-2, my, 7, 1, my, 7, bk)
	for y9 in range(-19, -3):
		for x9 in range(-2, 2):
			for z9 in range(8, 12):
				if (x9 == -2 or x9 == 1) and (z9 == 8 or z9 == 11):
					continue
				var c: int = br
				if z9 == 11:
					c = br2
				elif z9 == 8:
					c = br3
				if y9 == -16 or y9 == -7:
					c = br3                                    # 镜座的箍
				D(x9, y9, z9, c)
	for x10 in range(-3, 3):
		for z10 in range(7, 13):
			if (x10 == -3 or x10 == 2) and (z10 == 7 or z10 == 12):
				continue
			B(x10, -22, z10, x10, -20, z10, br2 if z10 == 12 else br)
			if x10 >= -1 and x10 <= 0 and z10 >= 9 and z10 <= 10:
				D(x10, -23, z10, glass, 40)
			else:
				D(x10, -23, z10, br3)
	B(-2, -3, 8, 1, -2, 11, bk)
	B(-1, -2, 9, 0, -2, 10, bk2)
	B(2, -12, 9, 3, -11, 10, br3)                          # 侧面旋钮
	# 测距标尺：镜筒顶上一条(z 12)，每 2 格一道刻度、每 4 格一道长刻度(两格宽)；两头各一个小立柱
	for y11 in range(-18, -4):
		var tick: bool = posmod(y11, 2) == 0
		var major: bool = posmod(y11, 4) == 0
		D(-1, y11, 12, bk if tick else br2)
		D(0, y11, 12, bk if major else br2)
	B(-1, -18, 13, 0, -18, 13, br3)
	B(-1, -5, 13, 0, -5, 13, br3)
	_end()


## 碎岩巨剑(双手大剑，蓝)：像从岩石里凿出来的大剑。宽厚的灰蓝色石质剑身(6 格厚、16 格宽，比普通大剑厚重得多；刃口一侧薄、
## 边上一些崩口)，刃尖是斜着凿出来的(+Z 一侧直通到尖，-Z 一侧斜削上去)；几道裂纹贯穿剑身，裂纹里透出冷蓝色的光(芯亮、边暗)；
## 剑格是一整块粗犷的方石(倒角、两面各一道发光裂纹)，皮革缠柄(双手握在 y -10..+4：右手 0、左手 -6)，柄尾一块方石。
## 刃 y 11..80(默认 heavy 刀光 16..78)
const ROCK_BLADE := [11, 80]
const ROCK_CRACKS := [
	[Vector2(13, 1), Vector2(18, -1), Vector2(23, 2), Vector2(30, 0), Vector2(36, -2), Vector2(43, 1), Vector2(50, -1), Vector2(56, 1), Vector2(61, -1)],
	[Vector2(23, 2), Vector2(27, 5), Vector2(29, 8)],
	[Vector2(36, -2), Vector2(39, -5), Vector2(41, -8)],
	[Vector2(50, -1), Vector2(53, 3), Vector2(55, 5)],
	[Vector2(61, -1), Vector2(65, -3), Vector2(68, -2)],
]


func rockbreaker() -> void:
	_begin(false)
	var le := VGrid.hexc("#4e3322")                        # 皮革
	var le2 := VGrid.hexc("#6a4630")
	var le3 := VGrid.hexc("#36231a")
	# ---- 柄：皮革斜缠(2×2，藏在两只拳头里)，每 5 格一道暗色绑绳
	for y in range(-16, 4):
		for x in range(-1, 1):
			for z in range(-1, 1):
				var c: int = le2 if posmod(y + x + z, 4) == 0 else le
				if posmod(y, 5) == 0:
					c = le3
				D(x, y, z, c)
	# ---- 柄尾的方石 + 剑格的方石(倒角，石纹)
	_rock_block(-3, -22, -3, 2, -17, 2)
	_rock_block(-4, 4, -10, 3, 10, 9)
	# 剑格两面各一道发光裂纹
	var gc := VGrid.hexc("#3a86dc")
	for p: Vector2i in [Vector2i(5, 3), Vector2i(6, 4), Vector2i(7, 4), Vector2i(7, 5), Vector2i(8, 6), Vector2i(9, 7), Vector2i(6, -5), Vector2i(7, -6), Vector2i(8, -6), Vector2i(8, -7)]:
		D(-4, p.x, p.y, gc, 80)
		D(3, p.x, p.y, gc, 80)
	# ---- 剑身
	var y0: int = ROCK_BLADE[0]
	var y1: int = ROCK_BLADE[1]
	var tip0 := 66                                         # 斜削的刃尖从这里开始
	for y2 in range(y0, y1 + 1):
		var t: float = float(y2 - y0) / float(y1 - y0)
		var hw: float = lerpf(7.6, 5.8, t)
		var zb: int = int(ceil(hw)) - 1
		var za: int = int(floor(-hw))
		if y2 > tip0:
			var u: float = float(y2 - tip0) / float(y1 - tip0)
			za = int(round(lerpf(float(za), float(zb), pow(u, 0.8))))   # -Z 一侧斜削到尖
			zb -= int(floor(u * u * 2.0))
		# 崩口：刃缘随机缺一格
		if _vhash(3, y2, 7) < 14 and y2 < tip0:
			za += 1
		if _vhash(5, y2, 11) < 14 and y2 < tip0:
			zb -= 1
		for z2 in range(za, zb + 1):
			var e: int = mini(z2 - za, zb - z2)
			var xr: int = 3 if e >= 2 else (2 if e == 1 else 1)
			if y2 > y1 - 4:
				xr = mini(xr, 2)
			for x2 in range(-xr, xr):
				D(x2, y2, z2, _rock_col(x2, y2, z2, e == 1, e == 0))
	# ---- 裂纹：贯穿剑身(两面和刃缘都看得见)；离裂纹线 < 0.55 = 亮芯，< 1.15 = 蓝光。只改已有的石头
	var lt := VGrid.hexc("#a4dcff")
	var lb := VGrid.hexc("#3a86dc")
	g.mode = VGrid.PAINT
	for y3 in range(y0, y1 + 1):
		for z3 in range(-9, 9):
			var d: float = _rock_crack_dist(Vector2(float(y3) + 0.5, float(z3) + 0.5))
			if d > 1.15:
				continue
			for x3 in range(-3, 3):
				D(x3, y3, z3, lt if d < 0.55 else lb, 120 if d < 0.55 else 70)
	g.mode = VGrid.FILL
	_end()


## 石块(倒角：切掉 12 条棱)，石纹；靠棱的一圈暗一点
func _rock_block(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			for z in range(z0, z1 + 1):
				var ex: int = mini(x - x0, x1 - x)
				var ey: int = mini(y - y0, y1 - y)
				var ez: int = mini(z - z0, z1 - z)
				var n0: int = (1 if ex == 0 else 0) + (1 if ey == 0 else 0) + (1 if ez == 0 else 0)
				if n0 >= 2:
					continue
				var n1: int = (1 if ex <= 1 else 0) + (1 if ey <= 1 else 0) + (1 if ez <= 1 else 0)
				D(x, y, z, _rock_col(x, y, z, n1 >= 2, false))


## 石头的颜色：灰蓝，按块状噪声深浅；棱(edge)暗一点，刃口(lip)再暗
func _rock_col(x: int, y: int, z: int, edge: bool, lip: bool) -> int:
	var n: int = _vhash(x / 2, y / 3, z / 2)
	var n2: int = _vhash(x, y, z)
	if lip:
		return VGrid.hexc("#4a5461") if n2 < 50 else VGrid.hexc("#56606e")
	if edge and n2 < 40:
		return VGrid.hexc("#566170")
	if n < 18:
		return VGrid.hexc("#5c6775")
	if n > 80:
		return VGrid.hexc("#7f8b98")
	if n2 < 8:
		return VGrid.hexc("#4d5764")
	return VGrid.hexc("#6b7684") if (n % 3) != 0 else VGrid.hexc("#727e8c")


## 点 p(局部 y, z)到最近一道裂纹(折线)的距离
static func _rock_crack_dist(p: Vector2) -> float:
	var best := 1e9
	for line: Array in ROCK_CRACKS:
		for i in range(line.size() - 1):
			var a: Vector2 = line[i]
			var b: Vector2 = line[i + 1]
			var ab: Vector2 = b - a
			var t: float = clampf((p - a).dot(ab) / ab.dot(ab), 0.0, 1.0)
			best = minf(best, p.distance_to(a + ab * t))
	return best


## 蚀月(单手剑，紫)：一把弯月形的单刃弯刀(延续蚀月双刃的设计语言)——刀身沿 +Y 长、越往刀尖越往刀背一侧(-Z)弯(刀背到刀尖弯出 MOON_SORI 格)，
## 刃口一侧(+Z)外弧鼓出来、中段最宽、刀尖收成月牙的尖角：暗紫刀身、银白刃口(微光)、刀背一线更暗；
## 刀背靠刀根处嵌一枚满月形的银色圆片(外圈暗银、月面亮银、几点月坑，两面凸起一层)；短柄(紫黑缠绳)、银色小护手(两端往刃那边翘)，柄尾一个银色小环。
## 握点在原点、刃沿 +Y(和其他单手剑同一套握法)。刀身 y 7..58(刀尖处离握点轴线往 -Z 偏约 16 格)，柄 y -7..3，柄尾环 y -14..-8
const MOON_BLADE := [7, 58]
const MOON_SORI := 14.0                                   # 刀背到刀尖往 -Z 弯出的格数


func moon_sword() -> void:
	_begin(false)
	var pu := VGrid.hexc("#432460")                        # 暗紫刀身
	var pu2 := VGrid.hexc("#55307a")
	var pu3 := VGrid.hexc("#28152f")                       # 刀背
	var ed := VGrid.hexc("#e6e8f0")                        # 刃口
	var ed2 := VGrid.hexc("#b7bccb")
	var sv := VGrid.hexc("#c6cad6")                        # 银
	var sv2 := VGrid.hexc("#959bab")
	var wr := VGrid.hexc("#251a30")                        # 缠绳
	var wr2 := VGrid.hexc("#4a3366")
	# ---- 短柄：紫黑缠绳
	for y in range(-7, 4):
		for x in range(-1, 1):
			for z in range(-1, 1):
				D(x, y, z, wr2 if posmod(y + x - z, 3) == 0 else wr)
	# ---- 柄尾小环(Y-Z 平面的圆环) + 环颈
	B(-1, -8, -1, 0, -8, 0, sv2)
	for y2 in range(-15, -7):
		for z2 in range(-4, 3):
			var dy: float = float(y2) + 0.5 + 11.5
			var dz: float = float(z2) + 0.5 + 0.5
			var r: float = sqrt(dy * dy + dz * dz)
			if r >= 1.5 and r <= 2.9:
				B(-1, y2, z2, 0, y2, z2, sv if dy > -0.5 else sv2)
	# ---- 护手：银色小横档(z -4..3)，两端往刃那边翘一格
	B(-2, 4, -4, 1, 5, 3, sv2)
	B(-2, 5, -3, 1, 5, 2, sv)
	B(-1, 6, -5, 0, 6, -5, sv)
	B(-1, 6, 4, 0, 6, 4, sv)
	# ---- 刀身：月牙
	var y0: int = MOON_BLADE[0]
	var y1: int = MOON_BLADE[1]
	for y3 in range(y0, y1 + 1):
		var t: float = float(y3 - y0) / float(y1 - y0)
		var zs: float = _moon_spine(t)
		var w: float = 3.6 + 6.4 * sin(PI * pow(t, 0.8))
		if t > 0.72:
			w *= 1.0 - pow((t - 0.72) / 0.28, 1.6)
		w = maxf(w, 0.6)
		var za: int = int(round(zs))
		var zb: int = int(round(zs + w))
		for z3 in range(za, zb + 1):
			var e: int = zb - z3
			var c3: int = pu if _vhash(y3, z3, 3) % 4 != 0 else pu2
			var gl := 0
			if e == 0:
				c3 = ed
				gl = 15
			elif e == 1 and zb - za >= 4:
				c3 = ed2
			elif z3 == za:
				c3 = pu3
			B(-1, y3, z3, 0, y3, z3, c3, gl)
	# ---- 刀背靠刀根处嵌的满月(圆心在刀背外侧一点：一半嵌进刀身)
	var tm := 0.3
	_moon_disc(Vector2(float(y0) + tm * float(y1 - y0), _moon_spine(tm) - 2.0), 4.4)
	_end()


## 刀背(-Z 一侧)在刀身第 t(0..1)处的 z：越往刀尖弯得越多
static func _moon_spine(t: float) -> float:
	return -2.0 - MOON_SORI * pow(t, 1.5)


## 满月(Y-Z 平面，厚 2 格)：外圈暗银、月面亮银微光、上方一道高光、几点月坑，两面再凸起一层小一圈的月面
func _moon_disc(c: Vector2, r: float) -> void:
	var rim := VGrid.hexc("#9da3b3")
	var face := VGrid.hexc("#d9dce6")
	var hi := VGrid.hexc("#f6f7fb")
	var crater := VGrid.hexc("#b6bbc8")
	for y in range(int(floor(c.x - r)) - 1, int(ceil(c.x + r)) + 1):
		for z in range(int(floor(c.y - r)) - 1, int(ceil(c.y + r)) + 1):
			var p := Vector2(float(y) + 0.5, float(z) + 0.5)
			var d: float = p.distance_to(c)
			if d > r:
				continue
			var q: Vector2 = p - c
			var col: int = rim if d > r - 0.9 else face
			if d <= r - 0.9 and q.x > 0.6 and q.y < -0.6 and d > r - 2.2:
				col = hi
			var cr: bool = posmod(y + 3 * z, 7) == 0 and d < r - 1.2
			if cr:
				col = crater
			B(-1, y, z, 0, y, z, col, 20)
			if d < r - 1.0:
				D(-2, y, z, crater if cr else face, 20)
				D(1, y, z, crater if cr else face, 20)


# ====================================================================== 通用武器 · 第二批(牵丝提灯 / 殉魂幡 / 猩红獠牙 / 锐眼步枪 / 回响刃 / 蓄能法典)
## 规矩同上一批：全部固定配色(VGrid.hexc 画死，不用 _c() 调色板)，不随武器颜色换色；饱和色取暗一档。
## 下面说的坐标都是武器局部的格子序号；"中心"是连续坐标(格子 i 占 [i, i+1])。

## 牵丝提灯(法器，蓝)：木偶师的提灯。拳头握着一根深蓝铜的提杆(沿 -Y 往前伸；法器约定 +Z = 上、-Y = 前，拳头约 x -3..3、y -7..0、z -4..3)，
## 杆头往上拱成倒 U 形的弯钩，钩顶垂一小段铜链挂着灯笼——灯笼吊在拳头前方、比拳头低一点。
## 方灯笼：深蓝铜的四根角柱 + 上下横框 + 四坡顶(出檐，四个檐角铜色上翘)，四面淡蓝色的灯罩，罩上透出一团更亮的灯火(发光)；
## 灯笼底下垂着四根银白丝线，其中两根末端各挂一个木偶的十字操纵杆(水平的木十字，俯视镜头看得出"十")。
## 提杆 y -17..6(出了拳头往外侧斜拐三格)，弯钩到 y -25；灯笼 x -8..1、y -25..-16(出檐)，z -4(顶钮)..-19(底钮)；丝线 / 十字最低到 z -28。
## 灯笼吊得离拳头远一点、偏外一点：跑步时右大腿往前抬也几乎碰不到
const LANTERN_C := Vector2(-3.0, -20.0)                    # 灯笼中轴(连续坐标 x, y)


func focus_lantern() -> void:
	_begin(false)
	var fr := VGrid.hexc("#22385c")                        # 深蓝铜
	var fr2 := VGrid.hexc("#355383")                       # 亮面
	var fr3 := VGrid.hexc("#14223a")                       # 暗面
	var cu := VGrid.hexc("#9c6034")                        # 铜饰件
	var cu2 := VGrid.hexc("#c4844c")
	var cu3 := VGrid.hexc("#6a3e20")
	var lx: int = int(LANTERN_C.x)                         # 灯笼中轴(下面的 x、y 都相对它写)
	var ly: int = int(LANTERN_C.y)
	# ---- 提杆：2×2，从拳头后面伸出来，出了拳头往外侧(-X)斜拐三格再伸到弯钩(灯笼离右腿远一点)；顶面亮一线，每 4 格一道暗箍；尾端一颗铜帽
	for y in range(ly + 3, 4):
		var xo: int = 0 if y >= -6 else maxi(-3, y + 6)
		for x in range(-1, 1):
			for z in range(-1, 1):
				var c: int = fr2 if z == 0 else fr
				if posmod(y, 4) == 0:
					c = fr3
				D(x + xo, y, z, c)
	B(-2, 4, -1, 1, 5, 0, cu)
	B(-1, 4, -2, 0, 5, 1, cu)
	B(-1, 6, -1, 0, 6, 0, cu3)
	D(-1, 5, 1, cu2)
	# ---- 弯钩：倒 U(Y-Z 平面，圆心 (y ly, z 0)、半径 2.4..4.4)，钩尖往下垂一格、一颗铜珠
	for y2 in range(ly - 5, ly + 4):
		for z2 in range(-1, 5):
			var p := Vector2(float(y2) + 0.5 - LANTERN_C.y, float(z2) + 0.5)
			var d: float = p.length()
			if d < 2.4 or d > 4.4 or p.y < -0.6:
				continue
			for x2 in range(lx - 1, lx + 1):
				D(x2, y2, z2, fr2 if (d > 3.5 and p.y > 0.0) else fr)
	B(lx - 1, ly - 4, -2, lx, ly - 3, -2, fr)
	B(lx - 1, ly - 4, -3, lx, ly - 3, -3, cu)
	# ---- 吊链：钩顶底下往下 5 节(两股斜着交错)，挂到灯笼顶钮
	for zc in range(-3, 2):
		if posmod(zc, 2) == 0:
			D(lx - 1, ly - 1, zc, cu)
			D(lx, ly, zc, cu)
		else:
			D(lx, ly - 1, zc, cu3)
			D(lx - 1, ly, zc, cu3)
	# ---- 顶：顶钮(铜) → 四坡顶 → 出檐(四角上翘)
	B(lx - 1, ly - 1, -4, lx, ly, -4, cu2)
	_lantern_layer(-5, 2, fr2, fr2)
	_lantern_layer(-6, 3, fr2, fr)
	_lantern_layer(-7, 5, fr, fr3)
	for cxy: Vector2i in [Vector2i(lx - 5, ly - 5), Vector2i(lx + 4, ly - 5), Vector2i(lx - 5, ly + 4), Vector2i(lx + 4, ly + 4)]:
		D(cxy.x, cxy.y, -6, cu)
	_lantern_layer(-8, 4, fr3, cu3)                        # 上框(外沿一圈铜)
	# ---- 灯身(z -9..-15)：四根角柱 + 四面灯罩(里面也填满灯火色)
	for z3 in range(-15, -8):
		for x3 in range(lx - 4, lx + 4):
			for y3 in range(ly - 4, ly + 4):
				var ex: bool = x3 == lx - 4 or x3 == lx + 3
				var ey: bool = y3 == ly - 4 or y3 == ly + 3
				if ex and ey:
					D(x3, y3, z3, fr2 if (x3 == lx - 4 and y3 == ly - 4) else fr)
				elif ex or ey:
					var u: float = (float(y3) + 0.5 - LANTERN_C.y) if ex else (float(x3) + 0.5 - LANTERN_C.x)
					var pc: Array = _lantern_pane(u, z3 + 12)
					D(x3, y3, z3, int(pc[0]), int(pc[1]))
				else:
					D(x3, y3, z3, VGrid.hexc("#9fd0f0"), 40)
	# ---- 底：下框 → 底座 → 底钮(挂丝线)
	_lantern_layer(-16, 4, fr3, cu3)
	_lantern_layer(-17, 3, fr, fr3)
	_lantern_layer(-18, 2, fr3, fr3)
	B(lx - 1, ly - 1, -19, lx, ly, -19, cu)
	# ---- 丝线(银白，1 格粗，微微发亮)：两根挂十字操纵杆，两根短一点、散着
	var silk := VGrid.hexc("#dfe3ec")
	var silk2 := VGrid.hexc("#b9bfcc")
	_lantern_string(Vector3(lx - 2, ly - 2, -19), Vector3(lx - 4, ly - 4, -26), silk)
	_lantern_string(Vector3(lx + 1, ly + 1, -19), Vector3(lx + 3, ly + 3, -24), silk)
	_lantern_string(Vector3(lx + 1, ly - 2, -19), Vector3(lx + 2, ly - 4, -23), silk2)
	_lantern_string(Vector3(lx - 2, ly + 1, -19), Vector3(lx - 3, ly + 3, -22), silk2)
	_puppet_cross(lx - 4, ly - 4, -27)
	_puppet_cross(lx + 3, ly + 3, -25)
	_end()


## 灯笼的一层方板：中心 LANTERN_C、半边长 h(格)，外沿一圈 c_edge
func _lantern_layer(z: int, h: int, c: int, c_edge: int) -> void:
	var x0: int = int(LANTERN_C.x) - h
	var y0: int = int(LANTERN_C.y) - h
	for x in range(x0, x0 + 2 * h):
		for y in range(y0, y0 + 2 * h):
			var edge: bool = x == x0 or x == x0 + 2 * h - 1 or y == y0 or y == y0 + 2 * h - 1
			D(x, y, z, c_edge if edge else c)


## 灯罩上的一格：u = 离这面中线的距离(±0.5..±2.5)，zr = z + 12(-3..3，上正)。中间一团泪滴形的亮灯火，外面一圈淡蓝，再外面深一点的蓝
func _lantern_pane(u: float, zr: int) -> Array:
	var core := {2: 0.5, 1: 0.5, 0: 1.5, -1: 1.5, -2: 0.5}
	var au: float = absf(u)
	var cw: float = float(core.get(zr, -1.0))
	if au <= cw:
		return [VGrid.hexc("#cdebff"), 52]
	var halo := false
	for dz in range(-1, 2):
		var w2: float = float(core.get(zr + dz, -1.0))
		if w2 >= 0.0 and au <= w2 + (1.0 if dz == 0 else 0.0):
			halo = true
	if halo:
		return [VGrid.hexc("#7ab3e0"), 32]
	return [VGrid.hexc("#45739f"), 16]


## 一根 1 格粗的丝线(a → b，连续坐标取整)
func _lantern_string(a: Vector3, b: Vector3, c: int) -> void:
	var n: int = int(maxf(absf(b.x - a.x), maxf(absf(b.y - a.y), absf(b.z - a.z))))
	for i in range(n + 1):
		var p: Vector3 = a.lerp(b, float(i) / float(maxi(n, 1)))
		D(int(round(p.x)), int(round(p.y)), int(round(p.z)), c, 12)


## 木偶的十字操纵杆：水平的木十字(长杆沿 Y 7 格、短杆沿 X 5 格，2 格厚)，正中一颗挂丝线的小钮
func _puppet_cross(x: int, y: int, z: int) -> void:
	var wd := VGrid.hexc("#8a5a34")
	var wd2 := VGrid.hexc("#a8744a")
	var wd3 := VGrid.hexc("#5e3a20")
	for k in range(-3, 4):
		D(x, y + k, z, wd2 if absi(k) < 3 else wd)
		D(x, y + k, z - 1, wd3 if absi(k) == 3 else wd)
	for k2 in range(-2, 3):
		if k2 == 0:
			continue
		D(x + k2, y, z, wd2 if absi(k2) < 2 else wd)
		D(x + k2, y, z - 1, wd3 if absi(k2) == 2 else wd)
	D(x, y, z + 1, wd3)


## 殉魂幡(法器，青)：手持的短柄招魂幡(原来那面长幡缩成单手拿的，全长约原来的 1/3)。法器约定：+Z = 上、-Y = 前，
## 拳头约 x -3..3、y -7..0、z -4..3；短杆从拳心穿过(杆心 x 0、y -3，和双生烛台的烛柱一样)，出了拳头往外侧(-X)微微斜(每 RQF_LEAN 格歪一格)：
## 暗色木杆(z -5..RQF_TOP)配两道青铜箍，杆尾一截青铜镦；杆顶一圈青铜套，倒扣一口青铜钟(钟口朝下、钟里暗，一道弦纹、四颗乳钉、几块铜绿，
## 杆顶伸进去当钟舌的轴；钟顶一个小环)；套上往外侧伸一根横杆(外头青铜钮)，挂一面青白长条幡(9 格宽、15 格高，1 格厚，正面朝前 -Y)：
## 上沿一道青纹、两个青色符纹串在一道竖笔上(微微发光)，下沿中间一个缺口；幡尾两条飘带往外飘。幡和飘带都在拳头外侧两格以上。
## 斜着 + 不太高：攻击动作把法器收到胸前时钟不会戳进脑袋太多，跑步时杆尾也不碰大腿
const REQUIEM_RUNES := [
	["#####", "..#..", "#.#.#", "#.#.#", "..#.."],
	[".###.", "#...#", "#####", "#...#", ".###."],
	["#.#.#", "#####", "..#..", ".###.", "#.#.#"],
	["..#..", ".#.#.", "#.#.#", ".#.#.", "..#.."],
]
const RQF_TOP := 21                                       # 杆顶(青铜套顶)的 z；钟在它上面 1..7 格，小环到 +11
const RQF_LEAN := 5                                       # 出了拳头(z > 2)每升高几格往外侧歪一格
const RQF_BELL := [3.7, 3.45, 3.2, 3.05, 2.9, 2.6, 1.8]   # 钟的外半径(钟口 → 钟顶)


## 杆在高度 z 处往外侧(-X)歪了几格
static func _rqf_xo(z: int) -> int:
	return -int(floor(float(maxi(z - 2, 0)) / float(RQF_LEAN)))


func requiem_focus() -> void:
	_begin(false)
	var wd := VGrid.hexc("#3b2b22")                        # 暗色木
	var wd2 := VGrid.hexc("#2b1f19")
	var wd3 := VGrid.hexc("#4c392c")
	var br := VGrid.hexc("#76683c")                        # 青铜(偏绿的暗铜)
	var br2 := VGrid.hexc("#9a8a52")
	var br3 := VGrid.hexc("#4c4226")
	var vg := VGrid.hexc("#4d7d70")                        # 铜绿
	var dark := VGrid.hexc("#2b2318")
	var zt: int = RQF_TOP
	var xt: int = _rqf_xo(zt)                              # 杆顶的 x 偏移(钟、横杆、幡都跟着它)
	# ---- 短杆(2×2，y -4..-3)：木纹深浅交替，出了拳头往外侧斜
	for z in range(-5, zt + 1):
		var xo: int = _rqf_xo(z)
		for x in range(-1, 1):
			for y in range(-4, -2):
				var c: int = wd if posmod(z, 7) < 5 else wd2
				if x == -1 and y == -4 and posmod(z, 7) == 2:
					c = wd3
				D(x + xo, y, z, c)
	# 青铜箍(4×4 去角，2 格高，一点铜绿)：拳头上面一道、杆中间一道
	for zb: int in [5, 11]:
		for dz in range(2):
			var xo2: int = _rqf_xo(zb + dz)
			for x2 in range(-2, 2):
				for y2 in range(-5, -1):
					if (x2 == -2 or x2 == 1) and (y2 == -5 or y2 == -2):
						continue
					var c2: int = br2 if dz == 1 else br
					if _vhash(x2, zb + dz, y2) < 14:
						c2 = vg
					D(x2 + xo2, y2, zb + dz, c2)
	# 杆尾：一截青铜镦(只露出拳头底下两格，和杆一样细：跑步时不碰大腿)
	B(-1, -4, -6, 0, -3, -5, br)
	B(-1, -4, -6, 0, -3, -6, br3)
	D(-1, -4, -5, br2)
	# ---- 杆顶的青铜套(zt-3..zt) + 往外侧伸的横杆(zt-2..zt-1) + 外头的青铜钮
	for z3 in range(zt - 3, zt + 1):
		var xo3: int = _rqf_xo(z3)
		for x3 in range(-2, 2):
			for y3 in range(-5, -1):
				if (x3 == -2 or x3 == 1) and (y3 == -5 or y3 == -2):
					continue
				D(x3 + xo3, y3, z3, br2 if z3 == zt else (br3 if z3 == zt - 3 else br))
	B(xt - 12, -4, zt - 2, xt - 3, -3, zt - 1, wd2)
	B(xt - 12, -4, zt - 1, xt - 3, -3, zt - 1, wd)
	B(xt - 14, -5, zt - 3, xt - 13, -2, zt, br)
	B(xt - 14, -5, zt, xt - 13, -2, zt, br2)
	B(xt - 15, -4, zt - 2, xt - 15, -3, zt - 1, br3)
	# ---- 倒扣的青铜钟(钟口朝下)：钟口里是空的、暗的，杆顶伸进去当钟舌的轴
	B(xt - 1, -4, zt + 1, xt, -3, zt + 4, br3)
	for i in range(RQF_BELL.size()):
		var z4: int = zt + 1 + i
		var ro: float = float(RQF_BELL[i])
		if i == 2:
			ro += 0.4                                          # 弦纹
		var ri: float = (ro - 1.2) if i <= 2 else -1.0
		for x4 in range(-5, 5):
			for y4 in range(-8, 2):
				var q := Vector2(float(x4) + 0.5, float(y4) + 0.5 + 3.0)
				var d: float = q.length()
				if d > ro or d < ri:
					continue
				var nd: float = q.normalized().dot(Vector2(-0.6, -0.8)) if d > 0.1 else 0.0
				var c4: int = br
				if nd > 0.45:
					c4 = br2
				elif nd < -0.5:
					c4 = br3
				if i == RQF_BELL.size() - 1 and d < 1.0:
					c4 = br2
				if i == 2:
					c4 = br3 if nd < 0.2 else br
				elif i == 0:
					c4 = br3 if d > ro - 0.8 else dark          # 钟唇 / 唇里
				elif (i == 3 and d < 2.0) or (ri > 0.0 and d < ri + 0.5):
					c4 = dark                                      # 钟里面
				elif _vhash(x4, z4, y4) < 7 and d > ro - 1.0 and i >= 3:
					c4 = vg                                        # 铜绿斑
				D(x4 + xt, y4, z4, c4)
	for k in range(4):
		var a: float = TAU * float(k) / 4.0 + PI / 4.0
		D(int(floor(cos(a) * 2.7)) + xt, int(floor(sin(a) * 2.7 - 3.0)), zt + 5, br2)   # 乳钉
	# 钟顶小环(X-Z 平面，正面朝前)
	B(xt - 1, -4, zt + 8, xt, -3, zt + 8, br)
	for zr in range(zt + 9, zt + 11):
		B(xt - 2, -4, zr, xt - 2, -3, zr, br)
		B(xt + 1, -4, zr, xt + 1, -3, zr, br)
	B(xt - 1, -4, zt + 11, xt, -3, zt + 11, br2)
	# ---- 幡(y -4，1 格厚)：竖褶深浅 + 两侧收边；上沿青纹；两个符纹串在竖笔上；下沿中间缺口 + 两条飘带
	var cl := VGrid.hexc("#c9dcda")                        # 青白
	var cl2 := VGrid.hexc("#b2c8c6")
	var cl3 := VGrid.hexc("#dde9e6")
	var hem := VGrid.hexc("#98b2b2")
	var rn := VGrid.hexc("#2a8a88")                        # 青色符纹
	var rn2 := VGrid.hexc("#1e6766")
	var zh: int = zt - 3                                   # 幡顶(紧贴横杆底下)
	for dz5 in range(0, 22):
		var z5: int = zh - dz5
		for dx5 in range(0, 10):
			var x5: int = xt - 4 - dx5
			if not _rqf_cloth(dx5, dz5):
				continue
			var c5: int = cl
			var g5 := 0
			var fold: int = posmod(x5 + int(floor(float(z5) / 7.0)), 3)
			if fold == 0:
				c5 = cl2
			elif fold == 1:
				c5 = cl3
			if dz5 == 0 or (dz5 <= 14 and (dx5 == 0 or dx5 == 8)):
				c5 = hem
			if dz5 == 2 and dx5 > 0 and dx5 < 8:
				c5 = rn
				g5 = 10
			elif dz5 > 14:
				c5 = cl2 if posmod(z5, 2) == 0 else cl            # 飘带
			D(x5, -4, z5, c5, g5)
	for dz6 in range(3, 13):
		D(xt - 8, -4, zh - dz6, rn2, 6)
	for gi: int in [0, 2]:
		var rows: Array = REQUIEM_RUNES[gi]
		var top: int = zh - (4 if gi == 0 else 9)
		for r in range(rows.size()):
			var row: String = rows[r]
			for kk in range(row.length()):
				if row[kk] == "#":
					D(xt - 6 - kk, -4, top - r, rn, 12)
	_end()


## 短柄殉魂幡的布(dx = 从幡的内侧边往外数的列 0..8，dz = 从幡顶往下数的行)：幡面 dz 0..13，第 14 行中间缺一个口；
## 两条飘带(外侧 dx 7..8 到 dz 21、内侧 dx 1..2 到 dz 20)，越往下越往外(+dx)飘一格
func _rqf_cloth(dx: int, dz: int) -> bool:
	if dz <= 13:
		return dx >= 0 and dx <= 8
	if dz == 14:
		return (dx >= 0 and dx <= 3) or (dx >= 5 and dx <= 8)
	var sh: int = 1 if dz >= 18 else 0                         # 往外飘一格
	if dz <= 21 and dx >= 7 + sh and dx <= 8 + sh and not (dz == 21 and dx == 7 + sh):
		return true
	if dz <= 20 and dx >= 1 + sh and dx <= 2 + sh and not (dz == 20 and dx == 1 + sh):
		return true
	return false


## 猩红獠牙(双匕，紫)：一对獠牙形的短刃。刃身像兽牙：根部粗(半宽 4、中间 4 格厚)，一路收成锐利的尖，并往 -Z 弯出 FANG_SORI 格
## (双持待机时局部 -Z 朝身体中线：左右两颗牙尖相对弯，像一张嘴的两颗獠牙)；骨白色(外弧亮、内弧暗、牙尖更白)，
## 刃根渗着暗红(像血：根部一圈深红，往上渗开成参差的边，再往上两道细细的血丝)；暗紫铁的牙箍，握柄缠深紫色皮绳，
## 柄尾暗紫铁箍 + 一小截骨质尖头。刃 y 6..33(牙尖往 -Z 偏约 9 格)，牙箍 y 3..5，柄 y -7..2；左手那把自动镜像(两把对称)。
## 刀光：刃 6..33(默认 dual 刀光 8..27；牙尖弯离了 +Y 轴，刀光取到 30 就好)
const FANG_BLADE := [6, 33]
const FANG_SORI := 9.0                                    # 牙尖往 -Z 弯出的格数
const FANG_W := 3.7                                       # 刃根半宽(另加 0.45)


func fang_dagger(p_left: bool) -> void:
	_begin(p_left)
	var bn := VGrid.hexc("#e3d8bf")                        # 骨白
	var bn2 := VGrid.hexc("#f3ecdc")                       # 外弧(亮)
	var bn3 := VGrid.hexc("#bcae90")                       # 内弧(暗)
	var bd := VGrid.hexc("#300a12")                        # 暗红(刃根)
	var bd2 := VGrid.hexc("#44101a")
	var bd3 := VGrid.hexc("#5a1a22")                       # 渗开的边 / 血丝
	var cd := VGrid.hexc("#33203d")                        # 深紫皮绳
	var cd2 := VGrid.hexc("#4b2d59")
	var cd3 := VGrid.hexc("#22152a")
	var fe := VGrid.hexc("#2c2531")                        # 暗紫铁
	var fe2 := VGrid.hexc("#463c50")
	# ---- 握柄(y -7..2)：深紫皮绳斜缠
	for y in range(-7, 3):
		for x in range(-1, 1):
			for z in range(-1, 1):
				var k: int = posmod(y + x - z, 3)
				D(x, y, z, cd2 if k == 0 else (cd3 if k == 2 else cd))
	# ---- 柄尾：暗紫铁箍(4×4 去角) + 骨质小尖头
	for x1 in range(-2, 2):
		for z1 in range(-2, 2):
			if (x1 == -2 or x1 == 1) and (z1 == -2 or z1 == 1):
				continue
			D(x1, -8, z1, fe2 if z1 == 1 else fe)
	B(-1, -10, -1, 0, -9, 0, bn3)
	D(-1, -11, -1, bn)
	# ---- 牙箍(y 3..5)：比刃根宽一圈的暗紫铁，顶上一圈小一点
	for y2 in range(3, 6):
		var hx: int = 3 if y2 < 5 else 2
		var hz: int = 5 if y2 < 5 else 4
		for x2 in range(-hx, hx):
			for z2 in range(-hz, hz):
				if (x2 == -hx or x2 == hx - 1) and (z2 == -hz or z2 == hz - 1):
					continue
				D(x2, y2, z2, fe2 if (y2 == 4 and (z2 == -hz or z2 == hz - 1)) else fe)
	# ---- 刃：獠牙(截面是扁圆：中间厚、两侧薄)
	var y0: int = FANG_BLADE[0]
	var y1: int = FANG_BLADE[1]
	for y3 in range(y0, y1 + 1):
		var t: float = float(y3 - y0) / float(y1 - y0)
		var zc: float = -FANG_SORI * pow(t, 1.5)
		var w: float = FANG_W * pow(1.0 - pow(t, 1.4), 0.9) + 0.45
		var hxf: float = clampf(w * 0.55, 1.0, 2.0)
		for z3 in range(int(floor(zc - w)) - 1, int(ceil(zc + w)) + 1):
			var dz: float = (float(z3) + 0.5 - zc) / w
			if absf(dz) > 1.0:
				continue
			var hxx: float = maxf(1.0, hxf * sqrt(maxf(0.0, 1.0 - dz * dz)) + 0.25)
			# 血：根部一圈深红，往上渗开(每列的高度不一样)；再往上两道细血丝
			var thr: float = 0.07 + 0.09 * float(_vhash(z3, 3, 5)) / 97.0
			var streak: bool = (absf(dz - 0.3) < 0.18 or absf(dz + 0.4) < 0.16) and t < 0.4 and _vhash(z3, y3, 9) > 25
			for x3 in range(-2, 2):
				if absf(float(x3) + 0.5) > hxx:
					continue
				var c: int = bn
				if dz > 0.55:
					c = bn2
				elif dz < -0.55:
					c = bn3
				if t > 0.86:
					c = bn2 if dz > -0.3 else bn
				if t < thr * 0.5:
					c = bd
				elif t < thr * 0.8:
					c = bd2
				elif t < thr:
					c = bd3
				elif t < thr + 0.07 and _vhash(x3, y3, z3) < 30:
					c = bd3                                        # 渗开的斑点
				elif streak:
					c = bd3 if t < 0.3 else bd2
				D(x3, y3, z3, c)
	_end()


## 锐眼步枪(步枪 = 双手远程，紫)：延续锐眼的设计语言。深紫的握把 / 护木 / 枪托 + 黄铜的机匣、护圈、枪管箍、枪口和托底板；
## 最显眼的是机匣上那支黄铜瞄准镜：镜筒(y -17..-4)后端黑目镜，前端(物镜那头)做成一只睁开的眼睛——Y-Z 平面里杏仁形的黄铜眼眶
## (加厚凸起、上眼睑四根睫毛)，里面眼白 + 暗黄虹膜，眼瞳是一颗发光的黄宝石(左右两面都凸出来)，和锐眼长枪护环上那只一样，左右两侧都看得见。
## 尺寸 / 握点照 spotter_rifle()：手枪式握把在原点，弹匣 y -9..-6，护木 y -32..-13(底 z 1：左手托在 y -13 附近)，枪管到 y -51，
## 枪口 -55..-52，枪托 y 7..19(往下加深到 z -3)。眼睛 y -30..-18、z 6..13(睫毛到 z 15)。枪械约定：-Y = 枪口，+Z = 上
const KEENEYE_SCOPE_EYE := Vector2(-24.0, 10.0)           # 瞄准镜眼睛的中心(连续坐标 y, z)


func keeneye_rifle() -> void:
	_begin(false)
	var pu := VGrid.hexc("#2e1f3e")                        # 深紫
	var pu2 := VGrid.hexc("#3c2a52")
	var pu3 := VGrid.hexc("#21162d")
	var br := VGrid.hexc("#8e6a2a")                        # 黄铜(压暗一档)
	var br2 := VGrid.hexc("#b08844")
	var br3 := VGrid.hexc("#5e4416")
	var gm := VGrid.hexc("#3a3440")                        # 枪管(带紫的枪灰)
	var gm2 := VGrid.hexc("#4c4555")
	var dk := VGrid.hexc("#16121b")                        # 孔 / 目镜
	var ew := VGrid.hexc("#dcc48c")                        # 眼白
	var ei := VGrid.hexc("#8a6a10")                        # 虹膜
	var en := VGrid.hexc("#38250a")                        # 刻线
	# ---- 手枪式握把(深紫，一道道防滑纹) + 黄铜握把底 + 黄铜护圈和扳机
	for z in range(-5, 3):
		B(-1, -1, z, 0, 2, z, pu if posmod(z, 2) == 0 else pu3)
	B(-1, 3, -4, 0, 3, 2, pu2)
	B(-1, -1, -6, 0, 3, -6, br3)
	B(-1, -5, 0, 0, -5, 2, br)
	B(-1, -4, 0, 0, -2, 0, br)
	D(-1, -3, 1, br2)
	D(0, -3, 1, br2)
	# ---- 机匣(黄铜，z 2..5)：每 6 格一道暗缝，两侧几颗暗铜螺丝，右侧抛壳口；顶上深紫导轨(z 6)
	for y in range(-12, 7):
		B(-2, y, 2, 1, y, 5, br3 if posmod(y, 6) == 0 else br)
		B(-2, y, 5, 1, y, 5, br3 if posmod(y, 6) == 0 else br2)
		B(-1, y, 6, 0, y, 6, pu2 if posmod(y, 2) == 0 else pu)
	for sy: int in [-10, -2, 4]:
		D(-3, sy, 3, br3)
		D(2, sy, 3, br3)
	B(-3, -6, 4, -3, -3, 5, dk)
	B(-4, -4, 4, -4, -4, 4, br2)                           # 拉机柄
	# ---- 直弹匣(深紫，底板黄铜)
	B(-1, -9, -4, 0, -6, 1, pu3)
	B(-1, -9, -5, 0, -6, -5, br)
	# ---- 护木(y -32..-13)：深紫方护木，两侧亮一点的侧板，三道黄铜箍；底下一条防滑纹(左手托在这里)
	B(-2, -32, 1, 1, -13, 5, pu)
	for y2 in range(-31, -14):
		B(-3, y2, 2, -3, y2, 4, pu2 if posmod(y2, 5) != 0 else pu3)
		B(2, y2, 2, 2, y2, 4, pu2 if posmod(y2, 5) != 0 else pu3)
	for yb: int in [-31, -23, -15]:
		B(-3, yb, 1, 2, yb, 5, br)
		B(-3, yb, 5, 2, yb, 5, br2)
	for y4 in range(-31, -13, 2):
		B(-1, y4, 1, 0, y4, 1, pu3)
	# ---- 枪管(带紫的枪灰，两道黄铜箍) + 黄铜枪口(两侧开槽，口里深色膛口)
	for y5 in range(-51, -32):
		B(-1, y5, 3, 0, y5, 4, gm2 if posmod(y5, 6) == 0 else gm)
	for yb2: int in [-46, -39]:
		B(-2, yb2, 2, 1, yb2, 5, br)
	B(-2, -55, 2, 1, -52, 5, br)
	B(-2, -52, 2, 1, -52, 5, br2)
	B(-2, -55, 2, 1, -55, 5, br3)
	for y6: int in [-54, -53]:
		B(-2, y6, 3, -2, y6, 4, dk)
		B(1, y6, 3, 1, y6, 4, dk)
	B(-1, -55, 3, 0, -55, 4, dk)
	# ---- 枪托：往后(+Y)并往下加深，深紫(一侧亮)，托腮板，黄铜托底板
	for y8 in range(7, 18):
		var t: float = float(y8 - 7) / 10.0
		var zlo: int = int(round(lerpf(1.0, -3.0, t)))
		B(-1, y8, zlo, 0, y8, 5, pu3 if posmod(y8, 6) == 0 else pu)
		D(-1, y8, 5, pu2)
	B(-1, 9, 6, 0, 14, 6, pu2)
	B(-2, 18, -3, 1, 19, 5, br)
	B(-2, 19, -3, 1, 19, 5, br3)
	# ---- 瞄准镜(黄铜)：两只镜座 → 圆镜筒(y -17..-4) → 后端黑目镜；侧面一颗旋钮；前端是眼睛
	for my: int in [-14, -7]:
		B(-2, my, 7, 1, my, 7, br3)
	for y9 in range(-17, -3):
		for x9 in range(-2, 2):
			for z9 in range(8, 12):
				if (x9 == -2 or x9 == 1) and (z9 == 8 or z9 == 11):
					continue
				var c: int = br
				if z9 == 11:
					c = br2
				elif z9 == 8:
					c = br3
				if y9 == -14 or y9 == -7:
					c = br3                                    # 镜座的箍
				D(x9, y9, z9, c)
	B(-2, -3, 8, 1, -2, 11, dk)
	B(-1, -2, 9, 0, -2, 10, VGrid.hexc("#2a2238"))
	B(2, -11, 9, 3, -10, 10, br3)                          # 侧面旋钮
	# 眼睛：杏仁形(半长 6.6、半高 3.8)，眼眶 x -3..2 加厚凸起，里面(眼白 / 虹膜) x -2..1，瞳孔的黄宝石 x -3..2，两面再各凸一格宝石面
	var ec: Vector2 = KEENEYE_SCOPE_EYE
	for y10 in range(-31, -17):
		for z10 in range(5, 15):
			var u: float = (float(y10) + 0.5 - ec.x) / 6.6
			var v: float = float(z10) + 0.5 - ec.y
			if absf(u) > 1.0:
				continue
			var h: float = 3.8 * pow(1.0 - u * u, 0.8)
			if absf(v) > h:
				continue
			var rim: bool = absf(v) > h - 1.1 or absf(u) > 0.84
			var r: float = Vector2(float(y10) + 0.5 - ec.x, v).length()
			if rim:
				B(-3, y10, z10, 2, y10, z10, br2 if v > 0.0 else br)
			elif r < 1.0:
				B(-3, y10, z10, 2, y10, z10, VGrid.hexc("#e8bc1c"), 70)    # 瞳孔：黄宝石
			elif r < 2.4:
				B(-2, y10, z10, 1, y10, z10, ei if r < 1.9 else en)
			else:
				B(-2, y10, z10, 1, y10, z10, ew)
	for sx: int in [-4, 3]:
		B(sx, -25, 9, sx, -24, 10, VGrid.hexc("#d8a614"), 60)
		D(sx, -25, 10, VGrid.hexc("#fff0a0"), 95)
	# 上眼睑四根睫毛(往上、往外斜)
	for ly: int in [-29, -26, -23, -20]:
		var dy: int = -1 if ly < -24 else 1
		var u2: float = (float(ly) + 0.5 - ec.x) / 6.6
		var top: int = int(floor(ec.y + 3.8 * pow(1.0 - u2 * u2, 0.8)))
		B(-1, ly, top, 0, ly, top + 1, br2)
		B(-1, ly + dy, top + 2, 0, ly + dy, top + 2, br)
	_end()


## 回响刃(单手剑，黑)：延续回响双刃设计语言的一把科技单手剑。哑光黑的单刃直剑(刃身 z -3..3、2 格厚，刃口 +Z 一线暗灰)，
## 刀尖是斜切的 tanto 尖(最后 9 格刃口一侧斜削到刀脊)；刀脊(-Z，z -5..-4)是一条 4 格厚的脊梁，嵌一排 5 格发光的青色电容格(y 10..37)
## (枪灰格框隔开，靠剑根那格最亮)，刃面一道暗青的电路细线，每格电容往脊梁伸一根小支线；护手是枪灰横档 + 两端一对往刃那边伸的小电极
## (绝缘环 + 发光的电极头)；黑色胶柄两道灰箍，柄头一颗青色指示灯。握点在原点、刃沿 +Y(和其他单手剑同一套握法)。
## 刃 y 7..54，护手 y 4..6(电极头到 y 10)，柄 y -8..3，柄头 y -11..-9(指示灯 y -12)。刀光：刃 7..54(默认 sword 刀光 18..58)
const ECHO_BLADE := [7, 54]
const ECHO_CELLS := [10, 16, 22, 28, 34]                  # 电容格(每格 4 格高，格框 2 格)的起始 y


func echo_sword() -> void:
	_begin(false)
	var bk := VGrid.hexc("#17181d")                        # 哑光黑
	var bk2 := VGrid.hexc("#1d1f25")
	var bk3 := VGrid.hexc("#111215")                       # 刀脊
	var eg := VGrid.hexc("#3b404a")                        # 刃口(暗灰)
	var gm := VGrid.hexc("#3a3e47")                        # 枪灰
	var gm2 := VGrid.hexc("#5a606c")
	var rb := VGrid.hexc("#18191d")                        # 胶柄
	var rb2 := VGrid.hexc("#24262c")
	var ce := VGrid.hexc("#13909e")                        # 电容(青)
	var ce2 := VGrid.hexc("#45c4d2")
	var ce3 := VGrid.hexc("#0d4a52")
	# ---- 柄(y -8..3)：黑色胶柄(一道道防滑纹) + 两道灰箍
	for y in range(-8, 4):
		for x in range(-1, 1):
			for z in range(-1, 1):
				D(x, y, z, rb2 if posmod(y, 2) == 0 else rb)
	for yb: int in [-6, 1]:
		B(-2, yb, -1, 1, yb, 0, gm)
		B(-1, yb, -2, 0, yb, 1, gm)
	# 柄头：去角的小方块(y -11..-9) + 一颗青色指示灯
	B(-2, -11, -1, 1, -9, 0, gm)
	B(-1, -11, -2, 0, -9, 1, gm)
	B(-1, -9, -1, 0, -9, 0, gm2)
	B(-1, -12, -1, 0, -12, 0, ce2, 60)
	# ---- 护手：枪灰横档(y 4..6，z -7..6) + 两端的小电极(往 +Y 伸：绝缘环 → 电极 → 发光电极头)
	B(-2, 4, -7, 1, 6, 6, gm)
	B(-2, 6, -6, 1, 6, 5, gm2)
	B(-3, 5, -1, 2, 5, 0, ce3)                             # 护手正中一道暗青(两面)
	for ez: int in [-7, 6]:
		B(-1, 7, ez, 0, 7, ez, ce3)
		B(-1, 8, ez, 0, 9, ez, gm2)
		B(-1, 10, ez, 0, 10, ez, ce2, 90)
	# ---- 剑身：哑光黑，刃口一线暗灰；最后 9 格刃口一侧斜削到刀脊(tanto 尖)；刃面一道电路细线(z -2)
	var y0: int = ECHO_BLADE[0]
	var y1: int = ECHO_BLADE[1]
	var clip := 9
	for y2 in range(y0, y1 + 1):
		var zb: int = 3
		if y2 > y1 - clip:
			zb = int(round(lerpf(3.0, -4.0, float(y2 - (y1 - clip)) / float(clip))))
		for z2 in range(-3, zb + 1):
			var c: int = bk if posmod(y2 + z2, 5) != 0 else bk2
			var gl := 0
			if z2 == zb:
				c = eg
			elif z2 == -2 and y2 >= y0 + 2 and y2 <= y1 - clip - 1:
				c = ce3
				gl = 8
			B(-1, y2, z2, 0, y2, z2, c, gl)
		# 刀脊(z -5..-4)：到 y1-4 是 4 格厚的脊梁，往刀尖收成 2 格
		var hx: int = 2 if y2 <= y1 - 4 else 1
		for z3 in range(-5, -3):
			if y2 == y1 and z3 == -4:
				continue
			for x3 in range(-hx, hx):
				D(x3, y2, z3, bk3)
	# 脊梁上的电容格：格框(枪灰) + 4 格高的发光格(中间两行最亮)；靠剑根那格最亮。每格往刃面的电路线伸一根小支线(z -3)
	for i in range(ECHO_CELLS.size()):
		var cy0: int = ECHO_CELLS[i]
		for x4 in range(-2, 2):
			for z4 in range(-5, -3):
				D(x4, cy0 - 1, z4, gm)
				D(x4, cy0 - 2, z4, bk3 if i > 0 else gm)
				for dy in range(4):
					var bright: bool = dy == 1 or dy == 2
					D(x4, cy0 + dy, z4, ce2 if bright else ce, (85 if bright else 55) - i * 5)
				if i == ECHO_CELLS.size() - 1:
					D(x4, cy0 + 4, z4, gm)
		B(-1, cy0 + 1, -3, 0, cy0 + 2, -3, ce3, 8)
	_end()


## 蓄能法典(法器，紫)：一本合着的厚法典(比魔典厚一点：x -8..6、y -12..5、z 3..11)，托在拳头上方(法器约定：+Z = 上，书脊在 -X 一侧沿 Y)。
## 深紫灰的皮面、圆鼓的书脊、铜包角；书页的翻口微微凹进去(书的样子)，一层层页边。封面(朝上)正中嵌一块大的发光电容：
## 横卧在封面的铜框凹槽里，一半陷进书里——铜色的两端端盖、青紫色发光的玻璃管(分成三节，顶上一线青色的亮芯)，一端一根铜极柱；
## 书脊上绕三道铜线圈(每道两匝)；书页的缝里透出几小段紫色电光，翻口上一道锯齿形的紫电(发光)；书头垂一条暗紫书签丝带。电容顶到 z 14
func focus_capacitor() -> void:
	_begin(false)
	var cv := VGrid.hexc("#2b2434")                        # 深紫灰皮面
	var cv2 := VGrid.hexc("#3a3046")
	var cv3 := VGrid.hexc("#1d1824")
	var cu := VGrid.hexc("#7a4428")                        # 铜
	var cu2 := VGrid.hexc("#9a5a34")
	var cu3 := VGrid.hexc("#4e2a16")
	var pg := VGrid.hexc("#e2d8c0")                        # 书页
	var pg2 := VGrid.hexc("#c8bb9c")
	var vi := VGrid.hexc("#6a2cc0")                        # 紫电
	var vi2 := VGrid.hexc("#b98aff")
	# ---- 封面：上下各 1 格厚，比书页大一圈；外沿一圈亮一点
	for y in range(-12, 6):
		for x in range(-7, 7):
			var rim: bool = y == -12 or y == 5 or x == 6
			D(x, y, 3, cv3 if rim else cv)
			D(x, y, 11, cv2 if rim else cv)
	# ---- 书页(z 4..10)：翻口(x 5)中间三层凹进去一格；页边一层深一层浅
	for z in range(4, 11):
		var xmax: int = 4 if (z >= 6 and z <= 8) else 5
		for y2 in range(-11, 5):
			for x2 in range(-6, xmax + 1):
				var c: int = pg
				if x2 == xmax or y2 == -11 or y2 == 4:
					c = pg2 if posmod(z, 2) == 0 else pg
				D(x2, y2, z, c)
	# ---- 圆鼓的书脊(x -7 整列 + x -8 的 z 5..9 鼓出来)
	B(-7, -12, 3, -7, 5, 11, cv3)
	B(-8, -12, 5, -8, 5, 9, cv3)
	B(-8, -12, 6, -8, 5, 8, cv)
	# ---- 书页缝里透出的紫光(几小段) + 翻口上一道锯齿紫电
	for seg: Array in [[4, -9, -7, 7], [4, -1, 1, 7], [4, 3, 3, 6], [5, -6, -5, 9], [5, 1, 2, 5]]:
		for ys in range(int(seg[1]), int(seg[2]) + 1):
			D(int(seg[0]), ys, int(seg[3]), vi, 40)
	for xs: int in [-4, 1]:
		D(xs, -11, 7, vi, 40)
		D(xs + 1, 4, 8, vi, 40)
	var zig := [[-4, 9], [-3, 8], [-3, 7], [-2, 7], [-2, 6], [-1, 5]]
	for i in range(zig.size()):
		var zp: Array = zig[i]
		var xz: int = 4 if (int(zp[1]) >= 6 and int(zp[1]) <= 8) else 5
		D(xz, int(zp[0]), int(zp[1]), vi2 if (i == 2 or i == 3) else vi, 75 if (i == 2 or i == 3) else 50)
	# ---- 铜包角(上下封面的四个角：L 形 3 格)
	for cc: Vector2i in [Vector2i(-7, -12), Vector2i(6, -12), Vector2i(-7, 5), Vector2i(6, 5)]:
		var sxx: int = 1 if cc.x < 0 else -1
		var syy: int = 1 if cc.y < 0 else -1
		for zc: int in [2, 12]:
			for k in range(3):
				D(cc.x + sxx * k, cc.y, zc, cu2 if k == 0 else (cu if k == 1 else cu3))
				D(cc.x, cc.y + syy * k, zc, cu2 if k == 0 else (cu if k == 1 else cu3))
	# ---- 书脊上的三道铜线圈(每道两匝，中间一道暗缝)：绕着圆鼓的书脊、搭到上下封面上
	var coil := [Vector2i(-6, 12), Vector2i(-7, 12), Vector2i(-8, 11), Vector2i(-8, 10), Vector2i(-9, 9), Vector2i(-9, 8), Vector2i(-9, 7), Vector2i(-9, 6),
		Vector2i(-9, 5), Vector2i(-8, 4), Vector2i(-8, 3), Vector2i(-7, 2), Vector2i(-6, 2)]
	for yc: int in [-9, -3, 3]:
		for dy in range(-1, 2):
			for i2 in range(coil.size()):
				var cp: Vector2i = coil[i2]
				var cw: int = cu3
				if dy != 0:
					cw = cu2 if cp.y >= 8 else (cu if cp.y >= 4 else cu3)
				D(cp.x, yc + dy, cp.y, cw)
	# ---- 封面上的电容凹槽：铜框(z 12，x -4 / 3 两条 + y -11 / 4 两头)
	for y3 in range(-11, 5):
		D(-4, y3, 12, cu3)
		D(3, y3, 12, cu3)
	for x3 in range(-4, 4):
		D(x3, -11, 12, cu3)
		D(x3, 4, 12, cu3)
	# ---- 电容(沿 Y 横卧，轴心 x 0、z 12；一半陷进书里)：端盖铜色，玻璃管青紫发光，顶上一线青色亮芯
	for y4 in range(-10, 4):
		var cap: bool = y4 <= -9 or y4 >= 2
		var r2: float = 9.0 if cap else 7.3
		for x4 in range(-3, 3):
			for z4 in range(9, 15):
				var dx: float = float(x4) + 0.5
				var dz: float = float(z4) + 0.5 - 12.0
				if dx * dx + dz * dz > r2:
					continue
				if cap:
					D(x4, y4, z4, cu2 if dz > 1.0 else (cu if dz > -1.0 else cu3))
					continue
				var c4: int = VGrid.hexc("#4a3bb8")
				var g4 := 34
				if y4 == -5 or y4 == -2 or y4 == 1:
					c4 = VGrid.hexc("#2f2678")                     # 节与节之间的箍
					g4 = 14
				elif dz > 1.8:
					c4 = VGrid.hexc("#58b8e0") if x4 != -1 else VGrid.hexc("#bfeeff")
					g4 = 58 if x4 != -1 else 80
				elif dz > 0.8 and dx < 0.0:
					c4 = VGrid.hexc("#6252cc")
					g4 = 44
				D(x4, y4, z4, c4, g4)
	# 极柱(+ 端，y 4..5)
	B(-1, 4, 12, 0, 5, 13, cu2)
	B(-1, 5, 14, 0, 5, 14, cu)
	# ---- 书签丝带(暗紫)：从书头(-Y)的书页里伸出来，搭过前沿往下垂，末端燕尾
	var rbn := VGrid.hexc("#4a2a78")
	var rbn2 := VGrid.hexc("#5e3a96")
	B(1, -12, 8, 2, -12, 10, rbn2)
	for zr in range(1, 10):
		B(1, -13, zr, 2, -13, zr, rbn if posmod(zr, 3) != 0 else rbn2)
	D(1, -13, 0, rbn)
	D(2, -13, 0, rbn)
	D(1, -14, -1, rbn2)
	D(2, -12, -1, rbn2)
	_end()


# ====================================================================== 通用武器 · 第三批：法器(万花镜 / 星屑法球 / 和弦音叉 / 晶壁手镜 / 博闻书匣)
## 规矩同前两批：全部固定配色(VGrid.hexc 画死，不用 _c() 调色板)，不随武器颜色换色；饱和色取暗一档。
## 握法照现有法器：+Z = 上、-Y = 前(正面朝前)，拳头约 x -3..3、y -7..0、z -4..3；杆 / 柄竖着从拳心穿过(轴心 x 0、y -3，和双生烛台的烛柱一样)。
## 下面说的坐标都是武器局部的格子序号；"中心"是连续坐标(格子 i 占 [i, i+1])。
const F3_AXIS := Vector2(0.0, -3.0)                       # 柄 / 筒的轴心(连续坐标 x, y)


## 绕轴心的一层圆片(z 层，半径 r；lit 方向打亮、背光一侧压暗)：c 正常、c_hi 亮面、c_lo 暗面
func _f3_disc(z: int, r: float, c: int, c_hi: int, c_lo: int, glow: int = 0) -> void:
	for x in range(int(floor(F3_AXIS.x - r)) - 1, int(ceil(F3_AXIS.x + r)) + 1):
		for y in range(int(floor(F3_AXIS.y - r)) - 1, int(ceil(F3_AXIS.y + r)) + 1):
			var q := Vector2(float(x) + 0.5 - F3_AXIS.x, float(y) + 0.5 - F3_AXIS.y)
			var d: float = q.length()
			if d > r:
				continue
			var nd: float = q.normalized().dot(Vector2(-0.6, -0.8)) if d > 0.1 else 0.0
			D(x, y, z, c_hi if nd > 0.45 else (c_lo if nd < -0.45 else c), glow)


## 1 格粗的折线(连续坐标点列，逐段取整)
func _f3_line(pts: Array, c: int, glow: int = 0) -> void:
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var n: int = int(ceil(maxf(absf(b.x - a.x), maxf(absf(b.y - a.y), absf(b.z - a.z))) * 1.5))
		for k in range(n + 1):
			var p: Vector3 = a.lerp(b, float(k) / float(maxi(n, 1)))
			D(int(floor(p.x)), int(floor(p.y)), int(floor(p.z)), c, glow)


## 万花镜(法器，青)：一支黄铜万花筒，竖着握在拳头里。下端(z -6)一只小目镜(暗色镜片 + 黄铜目镜圈)，
## 握的那段(z -5..3)细一圈，往上是主镜筒(z 4..13，半径 2.9)：几道暗铜箍、螺旋刻纹；顶上一圈外翻的黄铜镜口(z 14..15)，
## 镜口上冒出一圈会发光的彩色碎晶：六片花瓣形的碎晶往外斜着张开(青 / 品红 / 黄轮流，瓣尖和瓣边更亮)，正中一颗淡青的小晶尖。
## 全高 z -6..22，宽约 x -7..6(不做太高：攻击动作把法器收到胸前时碎晶不戳进脑袋太多)
const KALEIDO_PETALS := [["#1aa0ae", "#7ad6e0"], ["#a42e7c", "#dc78b4"], ["#c4961a", "#ecca5a"]]   # 青 / 品红 / 黄(暗、亮)


func kaleido_focus() -> void:
	_begin(false)
	var br := VGrid.hexc("#8e6a2a")                        # 黄铜
	var br2 := VGrid.hexc("#b08844")
	var br3 := VGrid.hexc("#5e4416")
	var en := VGrid.hexc("#4a3410")                        # 刻纹
	# ---- 目镜(z -6：暗色镜片带一点青色反光，外圈一道黄铜目镜圈)
	_f3_disc(-6, 1.6, br3, br, br3)
	B(-1, -4, -6, 0, -3, -6, VGrid.hexc("#1a2a33"))
	D(-1, -4, -6, VGrid.hexc("#3a6a74"), 12)
	# ---- 握的那段(z -5..3，半径 2)：一道道细纹
	for z in range(-5, 4):
		_f3_disc(z, 2.05, br3 if posmod(z, 3) == 0 else br, br2, br3)
	# ---- 主镜筒(z 4..13，半径 2.9)：两头一圈箍，中间一道箍；螺旋刻纹
	for z2 in range(4, 14):
		var r: float = 3.3 if (z2 == 4 or z2 == 13) else (3.15 if z2 == 9 else 2.9)
		for x in range(-4, 4):
			for y in range(-7, 1):
				var q := Vector2(float(x) + 0.5 - F3_AXIS.x, float(y) + 0.5 - F3_AXIS.y)
				var d: float = q.length()
				if d > r:
					continue
				var nd: float = q.normalized().dot(Vector2(-0.6, -0.8)) if d > 0.1 else 0.0
				var c: int = br2 if nd > 0.45 else (br3 if nd < -0.45 else br)
				if z2 == 4 or z2 == 13 or z2 == 9:
					c = br3 if nd < 0.3 else br
				elif d > r - 1.0:
					var ph: float = atan2(q.y, q.x) / TAU * 2.0 + float(z2) / 6.0
					if ph - floor(ph) < 0.13:
						c = en                                     # 螺旋刻纹
				D(x, y, z2, c)
	# ---- 镜口：外翻的黄铜圈(z 14 半径 3.4、z 15 半径 3.8，中间空着放碎晶)
	_f3_disc(14, 3.4, br, br2, br3)
	for x3 in range(-5, 5):
		for y3 in range(-8, 2):
			var q3 := Vector2(float(x3) + 0.5 - F3_AXIS.x, float(y3) + 0.5 - F3_AXIS.y)
			var d3: float = q3.length()
			if d3 <= 3.8 and d3 > 2.4:
				D(x3, y3, 15, br2 if q3.normalized().dot(Vector2(-0.6, -0.8)) > 0.0 else br)
	# ---- 一圈发光的彩色碎晶：六片往外斜着张开的花瓣(z 15..22)
	for z4 in range(15, 23):
		var s: float = float(z4 - 15) * 1.15
		var inner: float = 0.9 + 0.62 * s
		var outer: float = inner + 1.7
		var hw: float = 1.55 * sin(PI * (s + 0.6) / 9.2) + 0.35
		for x4 in range(-9, 9):
			for y4 in range(-12, 6):
				var q4 := Vector2(float(x4) + 0.5 - F3_AXIS.x, float(y4) + 0.5 - F3_AXIS.y)
				var rr: float = q4.length()
				if rr < inner or rr > outer:
					continue
				var a: float = atan2(q4.y, q4.x)
				var k: int = int(round(a / (TAU / 6.0) - 0.5))
				var th: float = (float(k) + 0.5) * TAU / 6.0
				var da: float = absf(wrapf(a - th, -PI, PI)) * rr
				if da > hw:
					continue
				var col: Array = KALEIDO_PETALS[posmod(k, 3)]
				var tip: bool = s >= 7.0 or da > hw - 0.7 or rr > outer - 0.6
				D(x4, y4, z4, VGrid.hexc(col[1] if tip else col[0]), 38 if tip else 24)
	# 正中一颗淡青的小晶尖(z 15..19)
	for z5 in range(15, 20):
		var r5: float = 1.3 if z5 < 18 else 0.7
		for x5 in range(-2, 2):
			for y5 in range(-5, -1):
				var d5: float = Vector2(float(x5) + 0.5 - F3_AXIS.x, float(y5) + 0.5 - F3_AXIS.y).length()
				if d5 <= r5:
					D(x5, y5, z5, VGrid.hexc("#c4ecf0") if z5 >= 17 else VGrid.hexc("#7cccd6"), 40)
	_end()


## 星屑法球(法器，黑)：一颗深色玻璃球(近黑的深蓝紫，球心 z 15、半径 6.3)托在一圈细细的白镴托架上，下面接一根短握柄(竖着穿过拳心)。
## 玻璃的"半透明"用深浅表现：左前上方被照亮的一面浅一点、背光的一面更深，左上一小块高光 + 一道弧形反光，下沿一圈透过来的淡紫；
## 球面上散着几颗发光的白 / 淡金星点，三颗四角小星(十字形)，一道淡淡的星云带。托架：握柄顶上一圈白镴箍，
## 四根细爪从箍上伸出来、托住球的下半(z 10 一圈细环)，爪尖贴着球面往上包到 z 17。握柄 z -6..6，柄尾一小截白镴。全高 z -8..21
const STAR_C := Vector3(0.0, -3.0, 15.0)                 # 球心(连续坐标)
const STAR_R := 6.3


func stardust_focus() -> void:
	_begin(false)
	var pw := VGrid.hexc("#7d808c")                        # 白镴(托架)
	var pw2 := VGrid.hexc("#a8acb8")
	var pw3 := VGrid.hexc("#55586a")
	var hd := VGrid.hexc("#26222e")                        # 握柄(黑木)
	var hd2 := VGrid.hexc("#352f40")
	# ---- 握柄(2×2，z -6..6)：黑木，两道白镴细箍；柄尾一颗白镴小球
	for z in range(-6, 7):
		for x in range(-1, 1):
			for y in range(-4, -2):
				D(x, y, z, hd2 if posmod(z + x - y, 3) == 0 else hd)
	for zb: int in [-3, 4]:
		_f3_disc(zb, 1.6, pw, pw2, pw3)
	B(-1, -4, -7, 0, -3, -7, pw)
	D(-1, -4, -7, pw2)
	D(0, -3, -8, pw3)
	# ---- 托架：柄顶一圈箍(z 7..8) + 球下的细环(z 10) + 四根细爪(从箍伸到细环，再贴着球面往上到 z 17)
	_f3_disc(7, 2.2, pw, pw2, pw3)
	_f3_disc(8, 2.6, pw2, pw2, pw)
	# ---- 玻璃球
	var lt := Vector3(-0.45, -0.65, 0.62).normalized()     # 光从左前上方来
	for z3 in range(8, 23):
		for x3 in range(-7, 7):
			for y3 in range(-10, 4):
				var p := Vector3(float(x3) + 0.5, float(y3) + 0.5, float(z3) + 0.5) - STAR_C
				var dd: float = p.length()
				if dd > STAR_R:
					continue
				var n: Vector3 = p / maxf(dd, 0.01)
				var nd: float = n.dot(lt)
				var c3: int = VGrid.hexc("#191630")
				var g3 := 0
				if nd > 0.35:
					c3 = VGrid.hexc("#262248")
				elif nd < -0.45:
					c3 = VGrid.hexc("#0f0d1e")
				if n.z < -0.55 and n.y < 0.2:
					c3 = VGrid.hexc("#2c2458")                     # 下沿透过来的淡紫
					g3 = 10
				if nd > 0.95:
					c3 = VGrid.hexc("#7c7cc0")                     # 高光
					g3 = 22
				elif nd > 0.74 and nd < 0.8:
					c3 = VGrid.hexc("#3e3a72")                     # 弧形反光
				# 星云带：一圈斜着的大圆附近，淡紫
				var band: float = absf(n.dot(Vector3(0.35, 0.25, 0.9).normalized()) - 0.12)
				if band < 0.09 and nd <= 0.7:
					c3 = VGrid.hexc("#2a1f4c")
					g3 = 8
				# 星点(只在球面上)
				if dd > STAR_R - 1.0 and nd <= 0.85:
					var hsh: int = _vhash(x3 + 3, y3 + 7, z3)
					if hsh < 3:
						c3 = VGrid.hexc("#f4f2ff")
						g3 = 90
					elif hsh < 5:
						c3 = VGrid.hexc("#f0d890")
						g3 = 80
				D(x3, y3, z3, c3, g3)
	# 托架的细环和细爪(画在球之后：贴着球面)
	for x2 in range(-7, 7):
		for y2 in range(-10, 4):
			var q := Vector2(float(x2) + 0.5 - STAR_C.x, float(y2) + 0.5 - STAR_C.y)
			var d: float = q.length()
			if d >= 4.3 and d <= 5.2:
				D(x2, y2, 10, pw2 if q.normalized().dot(Vector2(-0.6, -0.8)) > 0.2 else pw)
	for k in range(4):
		var a: float = PI * 0.25 + float(k) * PI * 0.5
		var dir := Vector2(cos(a), sin(a))
		var pts: Array = [Vector3(STAR_C.x + dir.x * 2.0, STAR_C.y + dir.y * 2.0, 8.6), Vector3(STAR_C.x + dir.x * 4.7, STAR_C.y + dir.y * 4.7, 10.4)]
		for zc in range(11, 18):
			var rz: float = sqrt(maxf(0.0, STAR_R * STAR_R - pow(float(zc) + 0.5 - STAR_C.z, 2.0))) + 0.55
			pts.append(Vector3(STAR_C.x + dir.x * rz, STAR_C.y + dir.y * rz, float(zc) + 0.5))
		_f3_line(pts, pw2 if k == 1 or k == 2 else pw)
	# 三颗四角小星(十字形，贴在正面的球面上)
	for sc: Vector2 in [Vector2(-2.5, 17.5), Vector2(2.5, 12.5), Vector2(3.5, 18.5)]:
		for o: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var xs: float = sc.x + float(o.x)
			var zs: float = sc.y + float(o.y)
			var rr2: float = STAR_R * STAR_R - pow(xs - STAR_C.x, 2.0) - pow(zs - STAR_C.z, 2.0)
			if rr2 <= 0.0:
				continue
			var ys: float = STAR_C.y - sqrt(rr2) + 0.3
			var core: bool = o == Vector2i(0, 0)
			D(int(floor(xs)), int(floor(ys)), int(floor(zs)), VGrid.hexc("#fffbe8") if core else VGrid.hexc("#f0dc9a"), 110 if core else 75)
	_end()


## 和弦音叉(法器，紫)：一把紫铜音叉，竖着握。叉柄(z -6..6)缠紫色握带(斜纹)，两头紫铜箍；往上一截紫铜颈(z 7..9)，
## 接一个 U 形叉弯(X-Z 平面，正面朝前)，两股长叉(x -4..-3 / 2..3，2×2)一直伸到 z 23；叉尖之间连一道淡紫发光的"音波"细弧(z 24..27)，
## 两股叉外侧各浮着两道小弧(声波，淡紫微光)。柄尾一小截链子挂一枚金色音符(♪)挂饰(z -8..-12，挂在外侧)。全高 z -12..27，宽约 x -10..9
const CHORD_NOTE := ["..#.", "..##", "..#.", "###.", "##.."]   # 音符挂饰(z -8 → -12 行，x -3..0 列：挂在外侧，跑步时不碰大腿)


func chord_focus() -> void:
	_begin(false)
	var cu := VGrid.hexc("#93452e")                        # 紫铜
	var cu2 := VGrid.hexc("#b8613f")
	var cu3 := VGrid.hexc("#62291a")
	var wr := VGrid.hexc("#4b2a6a")                        # 紫色握带
	var wr2 := VGrid.hexc("#62388a")
	var wr3 := VGrid.hexc("#331c4a")
	var wv := VGrid.hexc("#9474cc")                        # 音波(淡紫)
	var wv2 := VGrid.hexc("#cdb6f4")
	var au := VGrid.hexc("#c09040")                        # 音符(金)
	var au2 := VGrid.hexc("#e0c070")
	# ---- 叉柄：紫色握带斜缠(z -5..5)，两头紫铜箍
	for z in range(-5, 6):
		for x in range(-1, 1):
			for y in range(-4, -2):
				var k: int = posmod(z + x - y, 3)
				D(x, y, z, wr2 if k == 0 else (wr3 if k == 2 else wr))
	_f3_disc(-6, 1.6, cu, cu2, cu3)
	_f3_disc(6, 1.6, cu, cu2, cu3)
	# ---- 紫铜颈(z 7..9) + U 形叉弯(圆心 x 0、z 13，外半径 4.1、内半径 1.9，只要下半圈)
	B(-1, -4, 7, 0, -3, 9, cu)
	B(-1, -4, 9, 0, -4, 9, cu2)
	for x2 in range(-5, 5):
		for z2 in range(8, 14):
			var q := Vector2(float(x2) + 0.5, float(z2) + 0.5 - 13.0)
			var d: float = q.length()
			if d < 1.9 or d > 4.1 or q.y > 0.5:
				continue
			for y2 in range(-4, -2):
				D(x2, y2, z2, cu2 if (y2 == -4 and q.x < 0.0) else (cu3 if q.y < -3.0 else cu))
	# ---- 两股长叉(z 13..23)：正面左边一线亮，背面暗；叉尖收一点
	for sx: int in [-4, 2]:
		for z3 in range(13, 24):
			for x3 in range(sx, sx + 2):
				for y3 in range(-4, -2):
					if z3 == 23 and ((sx < 0 and x3 == sx) or (sx > 0 and x3 == sx + 1)):
						continue
					var c3: int = cu
					if y3 == -4 and x3 == sx:
						c3 = cu2
					elif y3 == -3 and x3 == sx + 1:
						c3 = cu3
					D(x3, y3, z3, c3)
	# ---- 叉尖之间的音波细弧(椭圆的上半圈：圆心 x 0、z 23.5，横半轴 3.1、竖半轴 4.5；顶上几格最亮)
	for x4 in range(-5, 5):
		for z4 in range(23, 29):
			var q4 := Vector2((float(x4) + 0.5) / 3.1, (float(z4) + 0.5 - 23.5) / 4.5)
			if q4.y < 0.08 or absf(q4.length() - 1.0) > 0.2:
				continue
			var top: bool = q4.y > 0.85
			for y4 in range(-4, -2):
				D(x4, y4, z4, wv2 if top else wv, 60 if top else 40)
	# 叉外侧的两道小弧(声波)：")"、"))"
	for side: int in [-1, 1]:
		for ri: int in range(2):
			var rad: float = 2.6 + 2.0 * float(ri)
			for z5 in range(12, 27):
				var dzv: float = float(z5) + 0.5 - 19.0
				if absf(dzv) > rad * 0.8:
					continue
				var xo: float = sqrt(maxf(0.0, rad * rad - dzv * dzv))
				var xw: float = (3.0 + 0.5 + xo) if side > 0 else (-3.0 - 0.5 - xo)
				for y5 in range(-4, -2):
					D(int(floor(xw)), y5, z5, wv if ri == 0 else VGrid.hexc("#7c5eb0"), 34 if ri == 0 else 24)
	# ---- 柄尾的小链 + 金色音符挂饰
	D(-1, -4, -7, cu3)
	for r in range(CHORD_NOTE.size()):
		var row: String = CHORD_NOTE[r]
		for k2 in range(row.length()):
			if row[k2] == "#":
				for y6 in range(-4, -2):
					D(k2 - 3, y6, -8 - r, au2 if (r >= 3 and k2 <= 1 and y6 == -4) else au)
	_end()


## 晶壁手镜(法器，青)：一面手持镜，竖着握，镜面朝前(-Y)。椭圆的青色晶面(x 半径 4.9、z 半径 6.3，中心 z 16)：
## 左上亮、右下深，两道斜着的高光纹(微微发光)；一圈银色镜框(比晶面凸出一格)，背面是银色背板；镜框顶上、左右两侧各一簇小晶簇(往外支棱)。
## 镜框下沿收成银色镜颈(z 7..9)，短手柄(z -5..6，银色，几道细纹)竖着穿过拳心，柄尾一颗小晶珠。全高 z -7..27，宽约 x -9..8
const MIRROR_C := Vector2(0.0, 16.0)                      # 镜面中心(连续坐标 x, z)
const MIRROR_GLASS := Vector2(4.9, 6.3)                   # 晶面半轴(x, z)
const MIRROR_FRAME := Vector2(6.2, 7.6)                   # 镜框外沿半轴(x, z)


func mirror_focus() -> void:
	_begin(false)
	var sv := VGrid.hexc("#b8bcc6")                        # 银
	var sv2 := VGrid.hexc("#dfe2e8")
	var sv3 := VGrid.hexc("#7c808c")
	var cr := VGrid.hexc("#2fa4b2")                        # 晶簇
	var cr2 := VGrid.hexc("#9ae0e8")
	# ---- 手柄(z -5..6，2×2 银，几道细纹) + 柄尾小晶珠
	for z in range(-5, 7):
		for x in range(-1, 1):
			for y in range(-4, -2):
				D(x, y, z, sv3 if posmod(z, 3) == 0 else (sv2 if x == -1 and y == -4 else sv))
	_f3_disc(-6, 1.6, sv, sv2, sv3)
	B(-1, -4, -7, 0, -3, -7, cr)
	D(-1, -4, -7, cr2, 40)
	# ---- 镜颈(z 7..9，往上张开)
	_f3_disc(7, 1.7, sv, sv2, sv3)
	for z2 in range(8, 10):
		for x2 in range(-2, 2):
			for y2 in range(-5, -1):
				D(x2, y2, z2, sv2 if x2 < 0 else sv)
	# ---- 镜身：镜框(y -5..-2) + 晶面(y -4，比镜框凹一格) + 背板(y -3..-2)
	for z3 in range(8, 25):
		for x3 in range(-8, 8):
			var px: float = float(x3) + 0.5 - MIRROR_C.x
			var pz: float = float(z3) + 0.5 - MIRROR_C.y
			var eo: float = pow(px / MIRROR_FRAME.x, 2.0) + pow(pz / MIRROR_FRAME.y, 2.0)
			if eo > 1.0:
				continue
			var eg: float = pow(px / MIRROR_GLASS.x, 2.0) + pow(pz / MIRROR_GLASS.y, 2.0)
			if eg <= 1.0:
				# 晶面：左上亮、右下深；两道斜高光纹
				var t: float = (-px / MIRROR_GLASS.x + pz / MIRROR_GLASS.y) * 0.5
				var c: int = VGrid.hexc("#258c9a")
				var gl := 20
				if t > 0.35:
					c = VGrid.hexc("#5cc0cc")
					gl = 26
				elif t < -0.35:
					c = VGrid.hexc("#176470")
					gl = 14
				var s: float = px + pz * 0.75
				if absf(s + 1.6) < 0.8 or absf(s - 1.9) < 0.45:
					c = VGrid.hexc("#c8f0f4")
					gl = 45
				D(x3, -4, z3, c, gl)
				B(x3, -3, z3, x3, -2, z3, sv3)
			else:
				var lit: bool = px < 0.0 and pz > -2.0
				B(x3, -5, z3, x3, -2, z3, sv2 if lit else (sv3 if (px > 0.0 and pz < 0.0) else sv))
	# ---- 小晶簇：镜框顶上一簇(三根)、左右两侧各一簇(两根)，往外支棱
	var spikes := [
		[Vector3(-0.5, -3.5, 23.0), Vector3(-0.5, -3.5, 27.5)], [Vector3(-2.5, -3.5, 22.5), Vector3(-4.0, -3.5, 25.5)], [Vector3(1.5, -3.5, 22.5), Vector3(3.0, -3.5, 25.0)],
		[Vector3(-6.0, -3.5, 16.5), Vector3(-9.0, -3.5, 18.5)], [Vector3(-6.0, -3.5, 14.5), Vector3(-8.5, -3.5, 13.5)],
		[Vector3(5.5, -3.5, 16.5), Vector3(8.5, -3.5, 18.5)], [Vector3(5.5, -3.5, 14.5), Vector3(8.0, -3.5, 13.5)],
	]
	for sp: Array in spikes:
		var a: Vector3 = sp[0]
		var b: Vector3 = sp[1]
		var n: int = int(ceil(a.distance_to(b) * 1.5))
		for k in range(n + 1):
			var t2: float = float(k) / float(maxi(n, 1))
			var p: Vector3 = a.lerp(b, t2)
			var tip: bool = t2 > 0.65
			for dy in range(0, 2):
				D(int(floor(p.x)), int(floor(p.y)) + dy, int(floor(p.z)), cr2 if tip else cr, 50 if tip else 30)
			if t2 < 0.4:
				D(int(floor(p.x)) + 1, int(floor(p.y)), int(floor(p.z)), cr, 30)
	_end()


## 博闻书匣(法器，紫)：一只紫木小书匣，竖着托在拳头上方(底在 z 3)。匣身 x -7..6、y -8..-1、z 3..20，顶上一圈压边(z 21)；
## 正面两扇门：左扇关着(门上一道黄铜锁扣 + 锁眼)，右扇往外开到 90°(铰链在右前角，门板竖在 x 6、往前伸到 y -14)，露出里面两层书架上的几册书：
## 书脊朝前、颜色各不一样(深红 / 藏青 / 墨绿 / 赭黄 / 青 / 梅紫)，书脊上下各一道金线，有一本斜靠着；
## 八个角都包黄铜包角；匣顶插一支发光的羽毛笔(淡紫白的羽片，笔尖插进匣顶的小铜座里)，往后斜，顶到 z 30
const ERUDITE_BOOKS := [                                  # [x0, 宽, 底 z, 高, 颜色, 斜靠(格)]
	[0, 2, 4, 6, "#8a2430", 0], [2, 1, 4, 7, "#24407e", 0], [3, 2, 4, 5, "#2c6a3a", 0], [5, 1, 4, 6, "#a07a28", 0],
	[0, 1, 12, 7, "#1f6e72", 0], [1, 2, 12, 6, "#6a2a6a", 0], [3, 1, 12, 7, "#8a2430", 0], [4, 2, 12, 5, "#24407e", 1],
	[-6, 2, 4, 6, "#2c6a3a", 0], [-4, 2, 4, 7, "#6a2a6a", 0], [-2, 2, 4, 6, "#a07a28", 0],
	[-6, 2, 12, 6, "#24407e", 0], [-4, 1, 12, 7, "#8a2430", 0], [-3, 2, 12, 6, "#1f6e72", 0],
]


func erudite_focus() -> void:
	_begin(false)
	var pw := VGrid.hexc("#4a2a5c")                        # 紫木
	var pw2 := VGrid.hexc("#5e3a72")
	var pw3 := VGrid.hexc("#331c42")
	var inr := VGrid.hexc("#1f1228")                       # 匣里(暗)
	var br := VGrid.hexc("#8e6a2a")                        # 黄铜
	var br2 := VGrid.hexc("#b08844")
	var br3 := VGrid.hexc("#5e4416")
	var gd := VGrid.hexc("#c8a050")                        # 书脊金线
	# ---- 匣身：背板(y -1)、两侧板(x -7 / 6)、底板(z 3)、顶板(z 20) + 顶上一圈压边(z 21)；木纹竖着深浅交替
	for z in range(3, 21):
		for x in range(-7, 7):
			for y in range(-8, 0):
				var shell: bool = y == -1 or x == -7 or x == 6 or z == 3 or z == 20
				if not shell:
					if y > -8:
						D(x, y, z, inr)                        # 匣里(正面 y -8 那一层空着：开着的那半边看得见书)
					continue
				var c: int = pw if posmod(x + y, 3) != 0 else pw3
				if z == 20 or (x == -7 and y == -8):
					c = pw2
				D(x, y, z, c)
	for x1 in range(-7, 7):
		for y1 in range(-8, 0):
			var rim: bool = x1 == -7 or x1 == 6 or y1 == -8 or y1 == -1
			if rim:
				D(x1, y1, 21, pw2)
	# 中间一层隔板(z 11)
	B(-6, -7, 11, 5, -2, 11, pw3)
	B(-6, -7, 11, 5, -7, 11, pw)
	# ---- 书(书脊朝前 y -7，往里到 y -3)
	for bk: Array in ERUDITE_BOOKS:
		var x0: int = bk[0]
		var w: int = bk[1]
		var z0: int = bk[2]
		var h: int = bk[3]
		var c0 := VGrid.hexc(str(bk[4]))
		var c_hi := VGrid.shade(c0, 1.25)
		var lean: int = bk[5]
		for dz in range(h):
			var zz: int = z0 + dz
			var xo: int = -lean if dz >= h / 2 else 0
			for dx in range(w):
				for y2 in range(-7, -2):
					var c2: int = c0
					if y2 == -7 and (dz == 1 or dz == h - 2):
						c2 = gd                                # 书脊上下两道金线
					elif y2 == -7 and dx == 0:
						c2 = c_hi
					D(x0 + dx + xo, y2, zz, c2)
	# ---- 正面：左扇门关着(x -6..-1，y -8)，门边一道黄铜锁扣；右扇开到 90°(x 6 外侧，y -9..-14)
	for z3 in range(4, 20):
		for x3 in range(-6, 0):
			var c3: int = pw if posmod(x3, 3) != 0 else pw3
			if z3 == 4 or z3 == 19 or x3 == -6 or x3 == -1:
				c3 = pw2                                       # 门框
			D(x3, -8, z3, c3)
		for y3 in range(-14, -8):
			var c4: int = pw if posmod(y3, 3) != 0 else pw3
			if z3 == 4 or z3 == 19 or y3 == -14 or y3 == -9:
				c4 = pw2
			D(6, y3, z3, c4)
	# 门内侧的小格(右扇门板内面朝 -X：一道浅色嵌板)
	B(5, -13, 7, 5, -10, 16, pw3)
	# 锁扣(左扇门右边缘，z 10..13) + 锁眼；右扇门边一个扣环
	B(-1, -9, 10, 0, -9, 13, br)
	B(-1, -9, 13, 0, -9, 13, br2)
	D(-1, -9, 11, VGrid.hexc("#1a120a"))
	B(5, -14, 11, 5, -14, 12, br3)
	# ---- 黄铜包角(八个角：三条棱各包 2 格)
	for cx: int in [-7, 6]:
		for cy: int in [-8, -1]:
			for cz: int in [3, 21]:
				var sxx: int = 1 if cx < 0 else -1
				var syy: int = 1 if cy < 0 else -1
				var szz: int = 1 if cz < 10 else -1
				for k in range(2):
					D(cx + sxx * k, cy, cz, br if k == 0 else br3)
					D(cx, cy + syy * k, cz, br if k == 0 else br3)
					D(cx, cy, cz + szz * k, br2 if k == 0 else br)
	# 右扇门的两片铰链
	for zh: int in [6, 17]:
		D(6, -8, zh, br2)
		D(6, -9, zh, br)
	# ---- 匣顶的羽毛笔：小铜座(z 22) → 笔杆往后上斜 → 羽片(淡紫白，微微发光)
	var qw := VGrid.hexc("#e6dcff")
	var qw2 := VGrid.hexc("#b9a2ee")
	var qs := VGrid.hexc("#d8c8a0")
	B(1, -4, 22, 2, -3, 22, br)
	D(1, -4, 23, VGrid.hexc("#2a2230"))
	for i in range(0, 8):
		var zq: int = 23 + i
		var xq: int = 1 - i / 4
		var yq: int = -4 + i / 3
		D(xq, yq, zq, qs if i < 3 else qw2, 0 if i < 3 else 30)
		if i >= 3:
			var wv: int = 2 if (i >= 4 and i <= 7) else 1
			for k2 in range(1, wv + 1):
				D(xq - k2, yq, zq, qw if k2 < wv else qw2, 45 if k2 < wv else 30)
			if i >= 4 and i <= 6:
				D(xq + 1, yq, zq, qw2, 30)
	_end()


# ====================================================================== 通用武器 · 第四批：手枪(双子燧发枪 / 回旋双轮 / 命运双牌 / 泡泡枪 / 共振双铃)
## 规矩同前几批：全部固定配色(VGrid.hexc 画死)，不随武器颜色换色；饱和色取暗一档。
## 手枪大类 = 双持：右手 W_pistols_<外观>(挂 Bow)、左手 L_pistols_<外观>(挂 Weapon_L，自动镜像)。
## 枪械约定：-Y = 枪口(朝前)，+Z = 上，握把沿 Z 穿过拳心(握把在 x -1..0、y -1..2 附近，和 pistol() / 锐眼左轮一样)。
## 不射子弹的几种(刃轮 / 纸牌 / 泡泡 / 声波)投射物外观在 game/view/fx.gd 的 make_projectile。


## 双子燧发枪(手枪，黄)：黄铜 + 胡桃木的燧发手枪。八角长枪管(黄铜，两道箍)，枪口往外张成喇叭口(里面是暗的膛口)，
## 胡桃木枪身一直托到枪管下面(下面一根通条)，枪管尾巴上一只弯弯的燧石击锤(钳口夹着一块灰黑的燧石)、前面一片竖着的火镰，
## 外侧一块黄铜机板 + 药池；弯弯往后勾的木握把(鸟头形)，黄铜柄底帽；黄铜护圈 + 钢扳机。
## 握把 z -8..2，枪管 y -27..0(z 5..8)，喇叭口 y -31..-28，击锤顶到 z 10
func flintlock_pistol(p_left: bool) -> void:
	_begin(p_left)
	var br := VGrid.hexc("#8e6a2a")                        # 黄铜
	var br2 := VGrid.hexc("#b08844")
	var br3 := VGrid.hexc("#5e4416")
	var wn := VGrid.hexc("#5a3a22")                        # 胡桃木
	var wn2 := VGrid.hexc("#6e4a2c")
	var wn3 := VGrid.hexc("#3e2616")
	var st := VGrid.hexc("#6a6e78")                        # 钢
	var st2 := VGrid.hexc("#8c909a")
	var fl := VGrid.hexc("#4a4652")                        # 燧石
	var dk := VGrid.hexc("#1a140c")
	# ---- 弯握把(鸟头形)：越往下越往后(+Y)勾；木纹斜着深浅交替；两侧握把片
	var off_at := func(z: int) -> int: return int(round(pow(float(maxi(0, 2 - z)), 1.4) * 0.28))
	for z in range(-7, 3):
		var off: int = off_at.call(z)
		for y in range(off - 1, off + 3):
			for x in range(-1, 1):
				D(x, y, z, wn2 if posmod(y + z, 3) == 0 else wn)
			if z <= 0:
				D(-2, y, z, wn3 if posmod(y - z, 2) == 0 else wn)
				D(1, y, z, wn3 if posmod(y - z, 2) == 0 else wn)
	# 黄铜柄底帽(往后勾出一点鸟嘴)
	var ob: int = off_at.call(-7)
	B(-2, ob - 1, -8, 1, ob + 2, -8, br)
	B(-1, ob + 3, -8, 0, ob + 3, -7, br2)
	# ---- 枪身(胡桃木)：握把顶上一直托到枪管下面(y -18..4，z 2..4)，机板那一段宽一格
	for y2 in range(-18, 5):
		B(-1, y2, 2, 0, y2, 4, wn if posmod(y2, 5) != 0 else wn3)
		D(-1, y2, 4, wn2)
	B(-2, -4, 2, 1, 3, 4, wn)
	B(-2, -4, 4, 1, 3, 4, wn2)
	# 外侧(-X)的黄铜机板 + 药池
	B(-3, -4, 3, -3, 2, 4, br)
	B(-3, -4, 4, -3, 2, 4, br2)
	B(-3, -1, 5, -3, 0, 5, br3)
	# ---- 八角枪管(黄铜，x -2..1、z 5..8 去四角)：顶面亮、底面暗；两道箍
	for y3 in range(-27, 1):
		for x3 in range(-2, 2):
			for z3 in range(5, 9):
				if (x3 == -2 or x3 == 1) and (z3 == 5 or z3 == 8):
					continue
				var c: int = br
				if z3 == 8:
					c = br2
				elif z3 == 5:
					c = br3
				D(x3, y3, z3, c)
	for yb: int in [-20, -10]:
		for x4 in range(-3, 3):
			for z4 in range(4, 10):
				if (x4 == -3 or x4 == 2) and (z4 == 4 or z4 == 9):
					continue
				if x4 > -3 and x4 < 2 and z4 > 4 and z4 < 9:
					continue
				D(x4, yb, z4, br3)
	# ---- 喇叭口(y -31..-28：一圈圈往外张，里面是暗的膛口)
	var bell := {-28: 2.6, -29: 3.0, -30: 3.4, -31: 3.8}
	for yf: int in bell.keys():
		var ro: float = float(bell[yf])
		for x5 in range(-5, 5):
			for z5 in range(1, 12):
				var d: float = Vector2(float(x5) + 0.5, float(z5) + 0.5 - 7.0).length()
				if d > ro:
					continue
				if d < ro - 1.3:
					D(x5, yf, z5, dk)
				else:
					D(x5, yf, z5, br2 if (z5 >= 7 or yf == -31) else br)
	D(-1, -27, 9, br2)                                     # 准星
	D(0, -27, 9, br2)
	# ---- 通条(枪管下面，y -26..-19) + 两个通条管
	B(-1, -26, 4, 0, -19, 4, st)
	B(-1, -27, 4, 0, -27, 4, br)
	for yp: int in [-24, -21]:
		B(-1, yp, 3, 0, yp, 4, br3)
	# ---- 枪尾：黄铜尾栓，一只弯弯的燧石击锤(Y-Z 平面，x -1..0)，前面一片竖着的钢火镰
	B(-1, 1, 5, 0, 3, 6, br)
	for pt: Vector2i in [Vector2i(3, 7), Vector2i(4, 8), Vector2i(4, 9), Vector2i(3, 10), Vector2i(2, 10), Vector2i(2, 11)]:
		B(-1, pt.x, pt.y, 0, pt.x, pt.y, st2 if pt.y >= 10 else st)
	B(-1, 1, 10, 0, 1, 10, fl)                             # 燧石
	D(-1, 1, 11, VGrid.hexc("#6a6672"))
	B(-1, -1, 9, 0, -1, 11, st)                            # 火镰
	B(-1, 0, 9, 0, 0, 9, st2)
	# ---- 黄铜护圈 + 钢扳机
	B(-1, -6, 0, 0, -6, 1, br)
	B(-1, -6, -1, 0, -2, -1, br)
	B(-1, -3, 0, 0, -3, 1, st2)
	_end()


## 回旋双轮(手枪，黑)：两手各一只刃轮。深色钢环(2 格厚，内沿一道亮线；环面绕握杆转 45°，靠身体的一侧往前偏)，外缘一圈锯齿刃
## (10 颗，每颗斜着往前翘，齿尖带一点青白冷光)；中间一根竖着的横握杆(皮绳缠的，上下两头接到环上)穿过拳心。
## 环心在握把正中(x 0、z -1.5)，内半径 4.6、外半径 5.9，齿尖到 7.2(再大，待机 / 跑步时环的内侧会戳进大腿)
const CHAKRAM_C := Vector2(0.0, -1.5)                    # 环心(连续坐标 x, z；y 在握杆中心 1.0)
const CHAKRAM_TILT := 45.0                                # 环面绕握杆转的角度(度)


func chakram_ring(p_left: bool) -> void:
	_begin(p_left)
	var fe := VGrid.hexc("#3a3e48")                        # 深色钢
	var fe2 := VGrid.hexc("#555b66")
	var fe3 := VGrid.hexc("#262a32")
	var ed := VGrid.hexc("#7fa8b4")                        # 刃口(冷光)
	var ed2 := VGrid.hexc("#bfe4ec")
	var le := VGrid.hexc("#3a2a22")                        # 皮绳
	var le2 := VGrid.hexc("#55402f")
	# ---- 握杆(z -6..2)：皮绳斜缠，两头一圈钢箍
	for z in range(-6, 3):
		for x in range(-1, 1):
			for y in range(0, 2):
				D(x, y, z, le2 if posmod(z + x + y, 3) == 0 else le)
	for zb: int in [-5, 1]:
		B(-2, 0, zb, 1, 1, zb, fe2)
	# ---- 钢环 + 锯齿刃：环面绕握杆(Z)转 CHAKRAM_TILT 度——靠身体那一侧(+X)往前(-Y)偏，待机 / 跑步时不戳进腰和大腿
	var ct: float = cos(deg_to_rad(CHAKRAM_TILT))
	var stl: float = sin(deg_to_rad(CHAKRAM_TILT))
	for x2 in range(-8, 8):
		for y2 in range(-7, 9):
			for z2 in range(-10, 8):
				var px: float = float(x2) + 0.5 - CHAKRAM_C.x
				var py: float = float(y2) + 0.5 - 1.0
				var u: float = px * ct - py * stl                  # 环面里的横向
				var w: float = px * stl + py * ct                  # 环面的法向(厚度)
				if absf(w) > 1.0:
					continue
				var q := Vector2(u, float(z2) + 0.5 - CHAKRAM_C.y)
				var r: float = q.length()
				if r < 4.6 or r > 7.4:
					continue
				var a: float = atan2(q.y, q.x)
				var ph: float = wrapf(a / (TAU / 10.0), 0.0, 1.0)
				var r_tooth: float = 5.9 + 1.3 * ph               # 锯齿：一路往外翘、到齿尖一下落回去
				var c: int
				var gl := 0
				if r <= 5.9:
					c = fe
					if r < 5.3:
						c = fe2                                   # 内沿一道亮线
					elif q.y > 0.0 and q.x < 0.0:
						c = fe2 if posmod(x2 + z2, 2) == 0 else fe
					elif q.y < -2.0:
						c = fe3
				elif r <= r_tooth:
					c = fe2 if ph > 0.5 else fe
					if r > r_tooth - 0.7 and ph > 0.45:
						c = ed2 if ph > 0.8 else ed               # 刃口：齿尖一点青白冷光
						gl = 26 if ph > 0.8 else 14
				else:
					continue
				D(x2, y2, z2, c, gl)
	_end()


## 命运双牌(手枪，青)：两手各握一扇展开的扑克牌——五张牌(每张 7×11、1 格厚)从拳头里往上扇形张开(±34°)，
## 两边的牌在后、中间那张在最前(y 0 / -1 / -2)；牌背是青色带细金边、正中一个金菱形(里面一点浅青)；最前面(正中)那张露出牌面：
## 米白的牌面、浅灰边、正中一个红色方块(♦)，两个对角各一个红色小角标。牌底(扇子的轴)捏在拳头里
const CARD_ANGLES := [-36.0, 36.0, -18.0, 18.0, 0.0]       # 先画后面的；最后一张(0°)在最前面、露出牌面
const CARD_LAYER := [0, 0, -1, -1, -2]
const CARD_PIVOT := Vector2(0.0, -1.0)                  # 扇轴(连续坐标 x, z)


func fortune_cards(p_left: bool) -> void:
	_begin(p_left)
	var cb := VGrid.hexc("#1f8e9a")                        # 牌背(青)
	var cb2 := VGrid.hexc("#5ac0c8")
	var au := VGrid.hexc("#c8a050")                        # 金
	var au2 := VGrid.hexc("#e6c070")
	var fc := VGrid.hexc("#eeeae0")                        # 牌面(米白)
	var fc2 := VGrid.hexc("#c8c2b4")
	var rd := VGrid.hexc("#b82a3a")
	for i in range(CARD_ANGLES.size()):
		var th: float = deg_to_rad(float(CARD_ANGLES[i]))
		var face: bool = i == CARD_ANGLES.size() - 1
		var yl: int = CARD_LAYER[i]
		for x in range(-12, 12):
			for z in range(-2, 13):
				var q := Vector2(float(x) + 0.5 - CARD_PIVOT.x, float(z) + 0.5 - CARD_PIVOT.y)
				var v: float = q.x * sin(th) + q.y * cos(th)
				var u: float = q.x * cos(th) - q.y * sin(th)
				if absf(u) > 3.5 or v < 0.0 or v > 11.0:
					continue
				var c: int
				if face:
					c = fc
					if absf(u) > 2.8 or v > 10.3 or v < 0.7:
						c = fc2
					if absf(u) / 1.6 + absf(v - 5.5) / 2.6 < 1.0:
						c = rd                                     # ♦
					elif (absf(u + 2.0) < 0.6 and absf(v - 9.2) < 0.8) or (absf(u - 2.0) < 0.6 and absf(v - 1.8) < 0.8):
						c = rd                                     # 角标
				else:
					c = cb
					if absf(u) > 3.0 or v > 10.5 or v < 0.5:
						c = au                                     # 细金边
					elif absf(u) + absf(v - 5.5) < 0.9:
						c = cb2
					elif absf(u) + absf(v - 5.5) < 2.0:
						c = au2 if v > 5.5 else au                 # 金菱形
					elif posmod(int(floor(u + 10.0)) + int(floor(v)), 2) == 0 and absf(u) < 2.2:
						c = VGrid.hexc("#1a7d88")                  # 暗格纹
				D(x, yl, z, c)
	_end()


## 泡泡枪(手枪，红)：一把胖乎乎的红色半透明玩具泡泡枪。圆滚滚的枪身(y -14..4，椭圆截面)：半透明用深浅表现——
## 边沿浅、中间深，顶上一道浅色高光、一点白色反光；短粗的枪管(y -18..-15，深红)，枪口一个黄色的泡泡圈(X-Z 平面，
## 圈里一层淡淡的彩色皂膜，微微发光)；背上一个装肥皂水的小罐(透明的淡青罐子，下半截蓝色皂水，白色瓶盖)；
## 胖握把(深红)、黄色扳机 + 红色护圈
const BUBBLE_C := Vector2(0.0, 5.0)                       # 枪身轴心(连续坐标 x, z)


func bubble_blaster(p_left: bool) -> void:
	_begin(p_left)
	var rd := VGrid.hexc("#b8262e")                        # 红(半透明的中间)
	var rd2 := VGrid.hexc("#d8484f")                       # 边沿(薄的地方浅)
	var rd3 := VGrid.hexc("#7e161e")                       # 背光 / 深处
	var hl := VGrid.hexc("#f08a8a")                        # 高光
	var yl := VGrid.hexc("#e0b030")                        # 黄
	var yl2 := VGrid.hexc("#f0d060")
	# ---- 胖握把(z -5..1，4×4 去角)
	for z in range(-5, 2):
		for x in range(-2, 2):
			for y in range(-1, 3):
				if (x == -2 or x == 1) and (y == -1 or y == 2):
					continue
				D(x, y, z, rd3 if (z == -5 or x == 1) else rd)
	# ---- 圆滚滚的枪身(y -14..4)：截面椭圆(x 半径 3、z 半径 4)，两头收圆
	for y2 in range(-14, 5):
		var t: float = absf((float(y2) + 0.5) - (-4.5)) / 9.5
		var k: float = sqrt(maxf(0.0, 1.0 - pow(t, 4.0)))
		var rx: float = 3.0 * k
		var rz: float = 4.0 * k
		if rx < 0.6:
			continue
		for x2 in range(-4, 4):
			for z2 in range(0, 10):
				var qx: float = (float(x2) + 0.5 - BUBBLE_C.x) / rx
				var qz: float = (float(z2) + 0.5 - BUBBLE_C.y) / rz
				var e: float = qx * qx + qz * qz
				if e > 1.0:
					continue
				var c: int = rd
				if e > 0.62:
					c = rd2                                        # 边沿浅
				if qz < -0.55:
					c = rd3
				if qz > 0.62 and absf(qx) < 0.45 and y2 > -12 and y2 < 2:
					c = hl                                         # 顶上一道高光
				D(x2, y2, z2, c)
	D(-1, -9, 9, VGrid.hexc("#fff0f0"))                    # 一点白色反光
	D(-1, -10, 9, VGrid.hexc("#fff0f0"))
	# ---- 短粗枪管(y -18..-15) + 泡泡圈(y -19，X-Z 平面) + 圈里的皂膜
	for y3 in range(-18, -14):
		for x3 in range(-2, 2):
			for z3 in range(3, 7):
				if (x3 == -2 or x3 == 1) and (z3 == 3 or z3 == 6):
					continue
				D(x3, y3, z3, rd3 if y3 == -15 else rd)
	for x4 in range(-5, 5):
		for z4 in range(0, 10):
			var d: float = Vector2(float(x4) + 0.5, float(z4) + 0.5 - 5.0).length()
			if d >= 2.9 and d <= 4.1:
				D(x4, -19, z4, yl2 if z4 >= 5 else yl)
			elif d < 2.9:
				var film: Array = ["#c8e8f0", "#e0c8f0", "#f0e8c0"]
				D(x4, -19, z4, VGrid.hexc(film[posmod(x4 + z4, 3)]), 12)
	# ---- 背上的皂水罐(y -8..-2，z 9..13)：透明淡青罐子，下半截蓝色皂水，白色瓶盖
	for y5 in range(-8, -1):
		for x5 in range(-2, 2):
			for z5 in range(8, 14):
				if (x5 == -2 or x5 == 1) and (y5 == -8 or y5 == -2):
					continue
				var c5: int = VGrid.hexc("#a8dce8")
				if z5 <= 10:
					c5 = VGrid.hexc("#4aa6cc") if (x5 + y5) % 3 != 0 else VGrid.hexc("#62b8da")
				elif x5 == -2 or y5 == -8:
					c5 = VGrid.hexc("#c8eef4")
				D(x5, y5, z5, c5)
	B(-1, -6, 14, 0, -4, 14, VGrid.hexc("#e8e8ea"))
	B(-1, -5, 15, 0, -5, 15, VGrid.hexc("#c8c8cc"))
	# ---- 黄色扳机 + 红色护圈
	B(-1, -3, -1, 0, -3, 0, yl)
	B(-1, -6, -2, 0, -6, 0, rd3)
	B(-1, -6, -2, 0, -2, -2, rd3)
	_end()


## 共振双铃(手枪，黑)：两手各一只手铃。木柄(z -2..6)竖着握在拳头里，柄顶一颗圆木钮；柄底一圈黄铜箍接铃顶，
## 深青铜的铃身挂在拳头下面(铃口朝下，z -4..-12，口沿半径 4.25)：铃身中间一圈发光的符文带(青色的一段段符文 + 暗铜的间隔，
## 上下各一道暗铜弦纹)，几块铜绿；铃口里是暗的，正中垂一颗铃舌
const BELL_C := Vector2(0.0, 0.5)                         # 铃 / 柄的轴心(连续坐标 x, y)
const BELL_PROF := {-4: 1.8, -5: 2.5, -6: 2.8, -7: 3.1, -8: 3.3, -9: 3.5, -10: 3.75, -11: 4.0, -12: 4.25}
const BELL_RUNES := "1011010011101001"


func resonance_bell(p_left: bool) -> void:
	_begin(p_left)
	var bz := VGrid.hexc("#5e5836")                        # 深青铜
	var bz2 := VGrid.hexc("#7c7448")
	var bz3 := VGrid.hexc("#3c3622")
	var vg := VGrid.hexc("#4d7d70")                        # 铜绿
	var wd := VGrid.hexc("#6a4428")                        # 木柄
	var wd2 := VGrid.hexc("#4e3018")
	var rn := VGrid.hexc("#26a8b0")                        # 符文(青)
	var rn2 := VGrid.hexc("#8ee6ea")
	var dark := VGrid.hexc("#1e1a12")
	# ---- 木柄(2×3，z -2..6) + 柄顶圆木钮(z 7..8) + 柄底黄铜箍(z -3)
	for z in range(-2, 7):
		for x in range(-1, 1):
			for y in range(-1, 2):
				D(x, y, z, wd2 if posmod(z, 4) == 0 else wd)
	for zk: int in [7, 8]:
		for x1 in range(-2, 2):
			for y1 in range(-2, 3):
				if (x1 == -2 or x1 == 1) and (y1 == -2 or y1 == 2):
					continue
				if zk == 8 and (x1 == -2 or x1 == 1 or y1 == -2 or y1 == 2):
					continue
				D(x1, y1, zk, wd if zk == 7 else VGrid.hexc("#8a5c36"))
	for x2 in range(-2, 2):
		for y2 in range(-2, 3):
			if (x2 == -2 or x2 == 1) and (y2 == -2 or y2 == 2):
				continue
			D(x2, y2, -3, VGrid.hexc("#8e6a2a"))
	# ---- 铃身(铃口朝下)：外半径按 z，下半截里面是空的(暗)；中间一圈符文带
	for z3: int in BELL_PROF.keys():
		var ro: float = float(BELL_PROF[z3])
		var ri: float = (ro - 1.2) if z3 <= -9 else -1.0
		for x3 in range(-6, 6):
			for y3 in range(-6, 7):
				var q := Vector2(float(x3) + 0.5 - BELL_C.x, float(y3) + 0.5 - BELL_C.y)
				var d: float = q.length()
				if d > ro or d < ri:
					continue
				var nd: float = q.normalized().dot(Vector2(-0.6, -0.8)) if d > 0.1 else 0.0
				var c: int = bz2 if nd > 0.45 else (bz3 if nd < -0.45 else bz)
				var gl := 0
				if z3 == -7 or z3 == -10:
					c = bz3                                        # 弦纹
				elif z3 == -8 or z3 == -9:
					if d > ro - 1.0:
						var k: int = int(floor(wrapf(atan2(q.y, q.x), 0.0, TAU) / (TAU / 16.0)))
						if BELL_RUNES[k] == "1":
							c = rn2 if (z3 == -8 and k % 3 == 0) else rn
							gl = 60 if c == rn2 else 40
						else:
							c = bz3
				elif z3 == -12:
					c = bz3 if d > ro - 0.8 else dark              # 铃口唇
				elif ri > 0.0 and d < ri + 0.5:
					c = dark
				elif _vhash(x3, z3, y3) < 6 and d > ro - 1.0:
					c = vg
				D(x3, y3, z3, c, gl)
	# 铃舌(铃口正中垂下来)
	B(-1, 0, -11, 0, 1, -9, bz3)
	B(-1, 0, -12, 0, 1, -12, bz2)
	_end()
