extends "res://tools/chars/_ember.gd"
## 贪婪的余烬(Ember Greed)：一本悬在半空、摊开的魔典。玄武岩(近黑的皮革)封面上爬着细细的熔岩裂纹，四角包着金角、
## 边上一道金边，金托里嵌着紫宝石；两摞羊皮纸书页上写满发光的紫色符文，书缝里蹿起一团紫火(外紫、芯子粉白)，
## 书脊底下垂着黑铁链、书角挂着短坠子，链子末端坠着紫宝石。后排法师：把火吞进书里、再吐出来。
## 配色(俯视的战斗镜头里一眼认出来 = "摊开的书 + 紫火 + 金")：紫焰(ember_init("greed")，封面玄武岩上的裂纹也是紫的)；
## 金饰加重：封面边缘上下两道金边、L 形的大金包角(带宝石)、书口正中一块包住书口的金扣(带宝石，两半合上时两块金扣在顶上对齐)、
## 书角的短链子是金链(书脊底下的长链还是黑铁)、吊坠宝石外面一圈金框。
## 姿态：书页朝上并朝前(+Z)仰起 TILT 度(俯视 3/4 的战斗镜头正好看到书页上的符文和火)，两半往上翘成浅 V 形(VEE 度)。
## 挂骨(全部刚体)。build_anims 只给 Root / Hips / Chest / Halo / Eyelid_* 烘位移、只给 Eyelid_* / 武器骨烘缩放，
## 其余骨头在动作里只能绕自己的关节转，所以部件是照着关节的位置挂的：
##   书脊 + 链子最上面一截 = Chest(整本书的飘、倾由 Hips 绕书本中心转出来)；
##   左半(封面 + 书页 + 符文 + 金角 + 宝石 + 两个书角坠子) = Shoulder_L，右半 = Shoulder_R：
##     Shoulder 的关节 (±3.5, 67, 0) 正好在书缝两侧，绕书脊方向(DEP)转 = 开合，转 ~86° 两半合上立起来(书页在中间相碰)；
##   书缝里的主火 = Eyelid_L、两页上的小火苗 + 火星 = Eyelid_R(都绕 FLAME_BASE 缩放 / 摆：缩到 0 = 火被吞回书里)；
##   书脊前端那条链子 = Halo(绕挂点 FRONT_HANG 摆)；
##   书脊两侧两条链子：x = ±5.5、z = 0.5 正好穿过 Thigh / Shin 的关节 → 大腿骨(y 46)以下一截挂 Thigh、小腿骨(y 27)以下挂 Shin，
##     关节处像链节一样弯。动作见 anim_chars 的 *_greed。

const IDENTITY := {"rim": "#b46cff", "rim_k": 0.15, "pulse": 0.55}

const TILT := 30.0                       # 书页朝前仰起的角度
const VEE := 10.0                        # 两半往上翘的角度
const ORG := Vector3(0.0, 62.0, 0.0)     # 书本原点：书脊中线上、封面顶面的中心(整本书转动的支点)
const COVER_A := 26.5                    # 封面从书脊往外的长度
const COVER_W := 18.5                    # 封面前后半长
const COVER_T := 3.0                     # 封面厚度
const PAGE_A0 := 0.6
const PAGE_A1 := 22.5
const PAGE_W := 15.5
const FLAME_BASE := Vector3(0.0, 68.0, 2.0)   # 火焰根部(书缝正中的书页表面)：两团火缩放的支点
const FRONT_HANG := Vector3(0.5, 46.0, 8.5)   # 书脊前端那条链子的关节(= 动作里 Halo 的转动支点)：y >= 46 的挂环和第一节顶跟着书脊，以下挂 Halo

var NRM: Vector3          # 书页法线(朝上、朝前)
var DEP: Vector3          # 书本"往前"的方向(沿书脊，朝前、往下)
var CB: float
var SB: float

var G0: int
var G1: int
var G2: int
var G3: int
var GEM: int
var GEM_DK: int
var GEM_HI: int
var GEM_CORE: int
var V0: int
var V1: int
var V2: int
var V3: int
var P0: int
var P1: int
var P2: int
var P3: int
var RUNE: int
var RUNE_HI: int
# 链子分段挂骨：y >= _cy_mid 挂 _cb_top，y >= _cy_low 挂 _cb_mid，再往下挂 _cb_low
var _cb_top: int
var _cb_mid: int
var _cb_low: int
var _cy_mid: int
var _cy_low: int
var _chain_gold := false      # true = 金链(书角的短链)，false = 黑铁链


func build() -> void:
	ember_init("greed")
	_palette()
	var t: float = deg_to_rad(TILT)
	NRM = Vector3(0.0, cos(t), sin(t))
	DEP = Vector3(0.0, -sin(t), cos(t))
	CB = cos(deg_to_rad(VEE))
	SB = sin(deg_to_rad(VEE))
	g.sym = false
	# ---------------------------------------------------------------- 两半(封面 + 书页)
	_half(1, "Shoulder_L")
	_half(-1, "Shoulder_R")
	# ---------------------------------------------------------------- 书脊(Chest)：封面底下一道圆鼓鼓的书脊，金箍 + 金包头 + 两端各一颗宝石
	_spine()
	# 熔岩裂纹：只爬在玄武岩(封面、书脊)上
	_basalt_cracks()
	# ---------------------------------------------------------------- 符文、金角、宝石(画在两半上)
	_runes(1, "Shoulder_L", 11)
	_runes(-1, "Shoulder_R", 23)
	_ornaments(1, "Shoulder_L")
	_ornaments(-1, "Shoulder_R")
	# ---------------------------------------------------------------- 火焰(主火 Eyelid_L，小火苗 + 火星 Eyelid_R)
	_flames()
	# ---------------------------------------------------------------- 链子 + 紫宝石坠子
	# 书角：短短一截链子 + 坠子(跟着两半)
	for s2: int in [1, -1]:
		var hb: String = "Shoulder_L" if s2 > 0 else "Shoulder_R"
		for f: int in [1, -1]:
			_chain_gold = true
			_chain_seg(hang_point(s2, f), 4.0 if f * s2 > 0 else 6.0, 1.8, 0 if f < 0 else 1, hb)
			_chain_gold = false
	# 书脊两侧：书脊底下 → 大腿骨关节 → 小腿骨关节
	for s3: int in [1, -1]:
		var sfx: String = "_L" if s3 > 0 else "_R"
		var cx: int = 5 if s3 > 0 else -6
		var top: Vector3 = Vector3(float(cx) + 0.5, float(_bottom_y(cx, 0)), 0.5)
		_chain_seg(top, 32.0 if s3 > 0 else 28.0, 2.4 if s3 > 0 else 2.2, 0 if s3 > 0 else 1, "Chest", "Thigh" + sfx, 46, "Shin" + sfx, 27)
	# 书脊前端(Halo)
	var ft: Vector3 = Vector3(FRONT_HANG.x, float(_bottom_y(int(floor(FRONT_HANG.x)), int(floor(FRONT_HANG.z)))), FRONT_HANG.z)
	_chain_seg(ft, 20.0, 3.0, 1, "Chest", "Halo", int(ft.y) - 1)
	rigid_all()


func _palette() -> void:
	G0 = H("#d8aa47")
	G1 = H("#a47a2f")
	G2 = H("#f3d27a")
	G3 = H("#fff0b8")          # 金饰棱角上的高光
	GEM = H("#9a3ce0")
	GEM_DK = H("#5e1f9e")
	GEM_HI = H("#e2b8ff")
	GEM_CORE = H("#c27cff")
	V0 = H("#3e1478")
	V1 = H("#6e22c8")
	V2 = H("#a24cf2")
	V3 = H("#e6bcff")
	P0 = H("#dccaa0")
	P1 = H("#c4ad80")
	P2 = H("#a48c62")
	P3 = H("#e8d8b0")
	RUNE = H("#8a36ea")
	RUNE_HI = H("#c88cff")


# ======================================================================= 坐标
## 书本坐标(u 横向、v 沿书页法线、w 沿书脊朝前) → 模型坐标
func bk(u: float, v: float, w: float) -> Vector3:
	return ORG + Vector3(u, 0.0, 0.0) + NRM * v + DEP * w


func to_bk(p: Vector3) -> Vector3:
	var q: Vector3 = p - ORG
	return Vector3(q.x, q.dot(NRM), q.dot(DEP))


## 半本书的局部坐标：a = 从书脊往外，b = 离封面顶面的高度，w 同上；s = +1 左半(+X)，-1 右半
func to_half(p: Vector3, s: int) -> Vector3:
	var k: Vector3 = to_bk(p)
	var uu: float = k.x * float(s)
	return Vector3(uu * CB + k.y * SB, -uu * SB + k.y * CB, k.z)


func half_pt(a: float, b: float, w: float, s: int) -> Vector3:
	var uu: float = a * CB - b * SB
	var v: float = a * SB + b * CB
	return bk(uu * float(s), v, w)


## 书角链子的挂点(金角底下)：s = 左右，f = +1 前角 / -1 后角
func hang_point(s: int, f: int) -> Vector3:
	return half_pt(COVER_A - 2.6, -COVER_T - 1.4, float(f) * (COVER_W - 2.6), s)


## 书页顶面的高度(半本书局部坐标)：书缝处往下凹，往外缘、前后边缘圆下去
func page_top(a: float, w: float) -> float:
	var top: float = 9.0 - 4.2 * exp(-a / 2.2) - 2.0 * smoothstep(5.0, 22.5, a)
	top -= 0.55 * pow(maxf(a - 20.5, 0.0), 2.0)
	top -= 0.5 * pow(maxf(absf(w) - 13.5, 0.0), 2.0)
	return top


# ======================================================================= 部件
func _half(s: int, bone: String) -> void:
	g.use(bone)
	var sg: int = g.cur_glow
	g.cur_glow = 0
	var x0: int = 0 if s > 0 else -30
	var x1: int = 29 if s > 0 else -1
	for z in range(-26, 28):
		for y in range(40, 88):
			for x in range(x0, x1 + 1):
				var p := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5)
				var h: Vector3 = to_half(p, s)
				var a: float = h.x
				var b: float = h.y
				var w: float = h.z
				var uu: float = (p.x) * float(s)
				# 封面
				if a >= 0.0 and a <= COVER_A and b >= -COVER_T and b <= 0.0 and absf(w) <= COVER_W and uu > -0.6:
					var c: int = basalt(x, y, z)
					if a > COVER_A - 0.9 or absf(w) > COVER_W - 0.9:
						if b > -0.9:
							c = G2 if h01(x, y, z) > 0.7 else G0   # 封面顶面外缘一道亮金边
						elif b < -COVER_T + 0.9:
							c = G0 if h01(x, y, z) > 0.3 else G1   # 底面外缘一道金边(侧面看：上下两道金线夹着黑皮)
					g.put(x, y, z, c)
					continue
				# 书页
				if a >= PAGE_A0 and a <= PAGE_A1 and absf(w) <= PAGE_W and b > 0.0 and uu > 0.3:
					var top: float = page_top(a, w)
					if b > top:
						continue
					var depth: float = top - b
					var c2: int
					if depth < 1.4:
						var r: float = h01(x, y, z)
						c2 = P3 if r > 0.75 else P0
						if a < 2.6:
							c2 = P2 if a < 1.6 else P1          # 书缝里暗一点
						elif r < 0.12:
							c2 = P1
					else:
						# 书口(侧面)：一页一页的纸边
						c2 = P0 if (int(floor(b * 1.4)) % 2 == 0) else P1
						if depth > 4.5 or a < 1.5:
							c2 = P2 if (int(floor(b * 1.4)) % 2 == 0) else P1
					g.put(x, y, z, c2)
	g.cur_glow = sg


func _spine() -> void:
	g.use("Chest")
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.cur_glow = 0
	g.mode = VGrid.ADD
	for z in range(-26, 28):
		for y in range(36, 80):
			for x in range(-13, 13):
				var p := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5)
				var k: Vector3 = to_bk(p)
				var u: float = k.x
				var v: float = k.y
				var w: float = k.z
				if v > -1.0 or absf(w) > COVER_W + 0.6:
					continue
				var e: float = (u / 9.5) * (u / 9.5) + ((v + 1.0) / 7.6) * ((v + 1.0) / 7.6)
				var band: bool = false
				for bc: float in [-9.0, 9.0]:
					if absf(w - bc) < 1.1:
						band = true
				var cap: bool = absf(w) > COVER_W - 1.6
				var lim: float = 1.0
				if band:
					lim = 1.22
				elif cap:
					lim = 1.12
				if absf(w) > COVER_W and not cap:
					continue
				if e > lim:
					continue
				var c: int = basalt(x, y, z)
				if band or cap:
					var r: float = h01(x, y, z)
					c = G2 if r > 0.8 else (G1 if r < 0.2 else G0)
				g.put(x, y, z, c)
	g.mode = VGrid.FILL
	# 书脊前后两端：金托 + 紫宝石(前端那颗大一点)
	_gem_round(bk(0.0, -5.0, COVER_W + 0.9), DEP, 2.4, 1.4)
	_gem_round(bk(0.0, -5.0, -COVER_W - 0.9), -DEP, 1.9, 1.2)
	# 书脊底面正中一颗
	_gem_round(bk(0.0, -8.9, -1.0), -NRM, 2.0, 1.2)
	g.mode = sm
	g.cur_glow = sg


## 熔岩裂纹只爬在玄武岩上：先把别的颜色(金、纸、宝石)存起来，跑完 cracks 再放回去
func _basalt_cracks() -> void:
	var keep: Dictionary = {}
	for z in range(-28, 30):
		for y in range(34, 90):
			for x in range(-32, 32):
				if not g.solid(x, y, z):
					continue
				var c: int = g.get_col(x, y, z)
				if c != B0 and c != B1 and c != B2:
					var i: int = g.idx(x, y, z)
					keep[i] = [c, g.gl[i]]
	cracks(-32, 34, -28, 31, 89, 29, 6.0, 0.6, 0.36, 17, 0.42)
	for i2: int in keep.keys():
		g.col[i2] = keep[i2][0]
		g.gl[i2] = keep[i2][1]


## 书页上的紫色符文：每页 4 列 × 5 行的小字(3×4 格的字形，随机几笔)，个别字缺省；外面一圈细线框
func _runes(s: int, bone: String, seed_i: int) -> void:
	var b_id: int = rig.ids[bone]
	var x0: int = 0 if s > 0 else -30
	var x1: int = 29 if s > 0 else -1
	for z in range(-26, 28):
		for y in range(40, 88):
			for x in range(x0, x1 + 1):
				if not g.solid(x, y, z) or g.get_bone(x, y, z) != b_id or not g.is_surface(x, y, z):
					continue
				var p := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5)
				var h: Vector3 = to_half(p, s)
				var a: float = h.x
				var b: float = h.y
				var w: float = h.z
				if a < 2.0 or a > PAGE_A1 - 0.8 or absf(w) > PAGE_W - 0.8 or b <= 0.0:
					continue
				if page_top(a, w) - b > 1.9:
					continue
				var lit: int = _rune_at(a, w, seed_i)
				if lit == 0:
					continue
				var i: int = g.idx(x, y, z)
				if lit == 2:
					g.col[i] = RUNE_HI
					g.gl[i] = 70
				elif lit == 1:
					g.col[i] = RUNE
					g.gl[i] = 48
				else:
					g.col[i] = V1
					g.gl[i] = 28


## 0 = 空白，1 = 笔画，2 = 笔画上的亮点，3 = 线框
func _rune_at(a: float, w: float, seed_i: int) -> int:
	# 线框
	if (absf(a - 2.6) < 0.5 or absf(a - 21.0) < 0.5) and absf(w) < 13.9:
		return 3
	if absf(absf(w) - 13.9) < 0.5 and a > 2.6 and a < 21.0:
		return 3
	var ca: float = (a - 4.0) / 4.25
	var cw: float = (w + 12.4) / 5.0
	if ca < 0.0 or cw < 0.0:
		return 0
	var ia: int = int(floor(ca))
	var iw: int = int(floor(cw))
	if ia > 3 or iw > 4:
		return 0
	var ga: int = int(floor(a - 4.0 - float(ia) * 4.25))
	var gw: int = int(floor(w + 12.4 - float(iw) * 5.0))
	if ga > 2 or gw > 3 or ga < 0 or gw < 0:
		return 0
	var hs: int = (ia * 7 + iw * 13 + seed_i * 31) & 0xffff
	if h01(ia, iw, seed_i) < 0.1:
		return 0                       # 空一个字
	var on := false
	var segs: int = int(h01(ia + 3, iw, seed_i + 5) * 255.0) | 0x100
	if (segs & 1) != 0 and gw == 0:
		on = true
	if (segs & 2) != 0 and gw == 3:
		on = true
	if (segs & 4) != 0 and (gw == 1 or gw == 2) and ga != 1 and (hs & 1) == 0:
		on = true
	if (segs & 4) != 0 and gw == 2 and (hs & 1) == 1:
		on = true
	if (segs & 8) != 0 and ga == 0:
		on = true
	if (segs & 16) != 0 and ga == 2:
		on = true
	if (segs & 32) != 0 and ga == 1 and gw >= 1:
		on = true
	if (segs & 64) != 0 and ga == int(round(float(gw) * 2.0 / 3.0)):
		on = true
	if (segs & 128) != 0 and ga == 1 and gw == 1:
		on = true
	if (segs & 0x100) != 0 and ga == 1 and gw == 0 and (segs & 1) == 0:
		on = true
	if not on:
		return 0
	return 2 if h01(ia * 5 + ga, iw * 5 + gw, seed_i) > 0.86 else 1


## 金角(四个外角)、前后边正中的金饰片 + 紫宝石、封面底面正中的大宝石、链子的挂环
func _ornaments(s: int, bone: String) -> void:
	g.use(bone)
	var sg: int = g.cur_glow
	g.cur_glow = 0
	var x0: int = 0 if s > 0 else -32
	var x1: int = 31 if s > 0 else -1
	for z in range(-28, 30):
		for y in range(38, 90):
			for x in range(x0, x1 + 1):
				var p := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5)
				var h: Vector3 = to_half(p, s)
				var a: float = h.x
				var b: float = h.y
				var w: float = h.z
				# 金角：包住封面外角的三角形金片 + 沿两条边伸出去的 L 形金条(上下各多出一层)
				var da: float = COVER_A - a
				var dw: float = COVER_W - absf(w)
				var on_page: bool = a <= PAGE_A1 + 0.2 and absf(w) <= PAGE_W + 0.2 and b > 0.0
				var tri: bool = da + dw <= 7.4
				var arm: bool = (da <= 2.2 and dw <= 8.0) or (dw <= 2.2 and da <= 8.0)
				if da >= -0.9 and dw >= -0.9 and (tri or arm) and b >= -COVER_T - 0.9 and b <= 0.9 and not on_page:
					var edge: bool = (tri and da + dw > 6.3) or da < 0.0 or dw < 0.0 or (not tri and (da > 1.4 and dw > 1.4))
					var cg: int = G0
					if b < -COVER_T:
						cg = G1
					elif edge and b > 0.0:
						cg = G3 if (da < 0.0 or dw < 0.0) else G2
					g.put(x, y, z, cg)
					continue
				# 书口正中的金扣：一块金板包住书口(顶面、外侧面、底面)，比书口再探出一点
				if absf(w) <= 3.6 and da >= -1.5 and da <= 4.6 and b >= -COVER_T - 0.9 and b <= 0.9 and not on_page:
					var cc: int = G0
					if b < -COVER_T:
						cc = G1
					elif absf(w) > 2.7 or da < -0.6 or da > 3.8:
						cc = G2 if b > 0.0 else G0
					g.put(x, y, z, cc)
					continue
				# 前后边正中的金饰片
				if absf(a - 13.0) <= 3.6 and dw >= -0.7 and dw <= 3.0 and b >= -0.3 and b <= 0.9:
					g.put(x, y, z, G0 if absf(a - 13.0) < 2.8 else G1)
					continue
				# 封面底面正中：菱形金框
				var dd: float = absf(a - 13.0) / 7.5 + absf(w) / 10.0
				if dd <= 1.0 and dd >= 0.78 and b < -COVER_T + 0.2 and b >= -COVER_T - 0.9:
					g.put(x, y, z, G0)
	g.cur_glow = sg
	# 宝石
	for f: int in [1, -1]:
		_gem_round(half_pt(COVER_A - 1.9, 1.0, float(f) * (COVER_W - 1.9), s), half_n(s), 1.5, 1.0)
		_gem_round(half_pt(13.0, 1.0, float(f) * (COVER_W - 1.3), s), half_n(s), 1.5, 1.0)
	_gem_round(half_pt(13.0, -COVER_T - 0.6, 0.0, s), -half_n(s), 3.4, 1.5)
	_gem_round(half_pt(COVER_A - 1.6, 1.0, 0.0, s), half_n(s), 1.7, 1.1)
	# 链子的挂环
	g.use(bone)
	for f2: int in [1, -1]:
		var hp: Vector3 = hang_point(s, f2)
		g.box(int(floor(hp.x)), int(floor(hp.y)), int(floor(hp.z)), int(floor(hp.x)), int(floor(hp.y)) + 1, int(floor(hp.z)), G1)


## 半本书书页的法线
func half_n(s: int) -> Vector3:
	var nb: Vector3 = Vector3(-SB * float(s), CB, 0.0)
	return (Vector3(nb.x, 0.0, 0.0) + NRM * nb.y).normalized()


## 圆宝石：金托(扁的圆盘) + 往外鼓的紫宝石(朝 n 方向)，朝上、朝左前的那半亮，芯子发光
func _gem_round(c: Vector3, n: Vector3, r: float, hgt: float) -> void:
	var sg: int = g.cur_glow
	var sm: int = g.mode
	g.mode = VGrid.FILL
	var nn: Vector3 = n.normalized()
	var rm: float = r + 1.6
	var light: Vector3 = Vector3(-0.45, 0.75, 0.5).normalized()
	for z in range(int(floor(c.z - rm)) - 1, int(ceil(c.z + rm)) + 2):
		for y in range(int(floor(c.y - rm)) - 1, int(ceil(c.y + rm)) + 2):
			for x in range(int(floor(c.x - rm)) - 1, int(ceil(c.x + rm)) + 2):
				var q: Vector3 = Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - c
				var hh: float = q.dot(nn)
				var rad: float = (q - nn * hh).length()
				# 金托：半径 r+1.1、厚 1.4 的圆盘(在宝石底下)
				if hh >= -1.2 and hh <= 0.2 and rad <= r + 1.1:
					g.cur_glow = 0
					g.put(x, y, z, G0 if rad > r - 0.2 else G1)
					continue
				# 宝石：半椭球
				if hh > 0.2:
					var e: float = (rad / r) * (rad / r) + ((hh - 0.2) / hgt) * ((hh - 0.2) / hgt)
					if e > 1.0:
						continue
					var side: float = q.normalized().dot(light)
					var col: int = GEM
					var gl: int = 30
					if e < 0.35:
						col = GEM_CORE
						gl = 70
					elif side > 0.45:
						col = GEM_HI
						gl = 50
					elif side < -0.25:
						col = GEM_DK
						gl = 12
					g.cur_glow = gl
					g.put(x, y, z, col)
	g.cur_glow = sg
	g.mode = sm


## 吊坠宝石：上短下长的八面体(菱形)，金扣在上；大一点的(r >= 2)外面一圈金框(正面 / 侧面看都是金边框着紫宝石)
func _gem_drop(c: Vector3, r: float, up: float, dn: float) -> void:
	var sg: int = g.cur_glow
	for z in range(int(floor(c.z - r)) - 1, int(ceil(c.z + r)) + 1):
		for y in range(int(floor(c.y - dn)) - 1, int(ceil(c.y + up)) + 1):
			for x in range(int(floor(c.x - r)) - 1, int(ceil(c.x + r)) + 1):
				var dx: float = float(x) + 0.5 - c.x
				var dy: float = float(y) + 0.5 - c.y
				var dz: float = float(z) + 0.5 - c.z
				var e: float = absf(dx) / r + absf(dz) / r + (dy / up if dy > 0.0 else -dy / dn)
				if e > 1.0:
					continue
				var col: int = GEM
				var gl: int = 35
				var ef: float = maxf(absf(dx), absf(dz)) / r + (dy / up if dy > 0.0 else -dy / dn)
				if r >= 2.0 and ef > 0.8:
					col = G2 if (dy > 0.0 and dx < 0.3) else G0
					gl = 0
				elif e < 0.45:
					col = GEM_CORE
					gl = 75
				elif dy > 0.0 and dx < 0.3:
					col = GEM_HI
					gl = 55
				elif dy < 0.0 and dx > 0.0 and dz < 0.5:
					col = GEM_DK
					gl = 15
				g.cur_glow = gl
				g.put(x, y, z, col)
	g.cur_glow = sg


## 一条竖直垂下的黑铁链 / 金链(_chain_gold；一节正面 O 形、一节侧面 | 形交替，每节 3 格高) + 金扣 + 末端的紫宝石坠子。
## 挂骨按高度分段：y >= y_mid 挂 b_top，y >= y_low 挂 b_mid，再往下挂 b_low(分段处就是骨头的关节，链子在那里弯)
func _chain_seg(top: Vector3, length: float, gem_r: float, phase: int, b_top: String, b_mid: String = "", y_mid: int = -999, b_low: String = "", y_low: int = -999) -> void:
	_cb_top = rig.ids[b_top]
	_cb_mid = rig.ids[b_mid] if b_mid != "" else _cb_top
	_cb_low = rig.ids[b_low] if b_low != "" else _cb_mid
	_cy_mid = y_mid
	_cy_low = y_low
	var sg: int = g.cur_glow
	g.cur_glow = 0
	var lit: int = G2 if _chain_gold else H("#a49cb0")
	var mid: int = G0 if _chain_gold else H("#6c6476")
	var dk: int = G1 if _chain_gold else H("#36303c")
	var cx: int = int(floor(top.x))
	var cz: int = int(floor(top.z))
	var y0: int = int(floor(top.y)) - 1
	# 挂环(插进书里一格)
	_cput(cx, y0 + 1, cz, G1)
	var n: int = int(length / 2.0)
	for i in range(n):
		var yc: int = y0 - 2 * i
		if (i + phase) % 2 == 0:
			# 正面 O 形的一节：亮
			for yy in range(yc - 2, yc + 1):
				_cput(cx - 1, yy, cz, lit)
				_cput(cx + 1, yy, cz, mid)
			_cput(cx, yc, cz, lit)
			_cput(cx, yc - 2, cz, mid)
		else:
			# 侧面 | 形的一节：暗
			for yy2 in range(yc - 2, yc + 1):
				_cput(cx, yy2, cz - 1, dk)
				_cput(cx, yy2, cz + 1, dk)
			_cput(cx, yc, cz, dk)
			_cput(cx, yc - 2, cz, dk)
	var yb: int = y0 - 2 * n
	# 金扣
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			_cput(cx + dx, yb - 1, cz + dz, G0)
	_cput(cx, yb, cz, mid)
	_cput(cx, yb - 2, cz, G1)
	g.cur_bone = _cb_low if yb - 3 < _cy_low else (_cb_mid if yb - 3 < _cy_mid else _cb_top)
	_gem_drop(Vector3(float(cx) + 0.5, float(yb) - 2.0 - gem_r * 0.9, float(cz) + 0.5), gem_r, gem_r * 0.9, gem_r * 2.1)
	g.cur_glow = sg


func _cput(x: int, y: int, z: int, c: int) -> void:
	g.cur_bone = _cb_low if y < _cy_low else (_cb_mid if y < _cy_mid else _cb_top)
	g.put(x, y, z, c)


## 这一列最低的实体体素(书的底面)
func _bottom_y(x: int, z: int) -> int:
	for y in range(36, 90):
		if g.solid(x, y, z):
			return y
	return int(ORG.y) - 8


## 书缝里蹿起的一团紫火(Eyelid_L) + 两页上各几簇小火苗、几颗飞散的火星(Eyelid_R)。
## 每根火舌：根部略收、往上先鼓再收尖，越高越往外弯(lean)、左右扭；颜色按"从正面看离火舌轴线多远"分层：轴线附近粉白、往外紫、边缘深紫
func _flames() -> void:
	# [x, z, 半径, 高, 相位, 往外弯 x, 往外弯 z]
	var tongues: Array = [
		[0.0, 2.0, 8.5, 32.0, 0.0, 0.0, -1.0],
		[-4.0, 1.0, 4.2, 19.0, 1.7, -7.0, -1.0],
		[4.0, 1.5, 4.4, 21.0, 3.1, 7.0, -1.5],
		[0.5, -3.5, 3.8, 16.0, 2.3, 1.0, -4.0],
		[-1.0, 6.0, 3.0, 11.0, 4.4, -2.0, 2.5],
		# 书页上的小火苗
		[-14.0, -3.0, 3.0, 11.0, 0.9, -1.5, 0.0],
		[13.5, -4.0, 3.1, 12.0, 2.6, 1.5, 0.0],
		[-16.5, 8.0, 2.4, 7.0, 4.0, -1.0, 0.0],
		[16.5, 7.0, 2.4, 8.0, 5.1, 1.0, 0.0],
	]
	var main_n := 5                       # 前 5 根是书缝里的主火
	var id_main: int = rig.ids["Eyelid_L"]
	var id_page: int = rig.ids["Eyelid_R"]
	var sg: int = g.cur_glow
	var sm: int = g.mode
	g.mode = VGrid.ADD
	# 每根火舌的根部高度 = 它正下方书页表面的高度
	var bases: Array[float] = []
	for tg: Array in tongues:
		bases.append(float(_surface_y(int(floor(float(tg[0]))), int(floor(float(tg[1]))))))
	for z in range(-16, 22):
		for x in range(-26, 26):
			var col_base: int = _surface_y(x, z)
			for y in range(col_base - 1, 104):
				var best: float = 9.0
				var bt: float = 0.0
				var bkx: float = 1.0
				var bj: int = 0
				for j in range(tongues.size()):
					var tg2: Array = tongues[j]
					var hgt: float = float(tg2[3])
					var t: float = (float(y) + 0.5 - bases[j]) / hgt
					if t > 1.0 or t < -0.6:
						continue
					var tc: float = maxf(t, 0.0)
					var ph: float = float(tg2[4])
					var r0: float = float(tg2[2])
					var swx: float = sin(tc * 5.0 + ph) * r0 * 0.3 * tc + float(tg2[5]) * tc * tc
					var swz: float = cos(tc * 3.6 + ph * 1.3) * r0 * 0.2 * tc + float(tg2[6]) * tc * tc
					var dx: float = float(x) + 0.5 - float(tg2[0]) - swx
					var dz: float = float(z) + 0.5 - float(tg2[1]) - swz
					var nz: float = 0.84 + 0.32 * h01(x >> 1, (y + j * 5) >> 1, z >> 1)
					var rad: float = r0 * minf(1.0, 0.78 + tc * 2.0) * pow(1.0 - tc, 0.8) * nz
					if rad <= 0.35:
						continue
					var k: float = sqrt(dx * dx + dz * dz) / rad
					if k < best:
						best = k
						bt = tc
						bkx = absf(dx) / rad
						bj = j
				if best > 1.0:
					continue
				var hot: float = 1.0 - 0.9 * bt - 0.6 * bkx + (h01(x, y, z) - 0.5) * 0.12
				var c: int = V0
				var gl: int = 32
				if hot > 0.68:
					c = V3
					gl = 85
				elif hot > 0.4:
					c = V2
					gl = 62
				elif hot > 0.06:
					c = V1
					gl = 46
				g.cur_glow = gl
				g.cur_bone = id_main if bj < main_n else id_page
				g.put(x, y, z, c)
	# 飞散的火星
	g.cur_bone = id_page
	var sparks: Array = [Vector3(-3, 99, 1), Vector3(5, 95, -2), Vector3(-8, 91, 3), Vector3(2, 103, 4), Vector3(9, 88, 4), Vector3(-11, 84, -1),
		Vector3(-15, 76, -3), Vector3(15, 78, -4), Vector3(-1, 106, -1)]
	for i in range(sparks.size()):
		var sp: Vector3 = sparks[i]
		g.cur_glow = 80 if i % 2 == 0 else 55
		g.put(int(sp.x), int(sp.y), int(sp.z), V3 if i % 2 == 0 else V2)
		if i % 3 == 0:
			g.cur_glow = 40
			g.put(int(sp.x), int(sp.y) - 1, int(sp.z), V1)
	g.mode = sm
	g.cur_glow = sg


## 这一列最高的实体体素的上一格(书页表面)；没有就返回书本原点高度
func _surface_y(x: int, z: int) -> int:
	for y in range(96, 40, -1):
		if g.solid(x, y, z):
			return y + 1
	return int(ORG.y) + 4
