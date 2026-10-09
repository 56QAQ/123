extends "res://tools/chars/_ember.gd"
## 虚荣的余烬(Ember Vanity，第一章·红之章的精英)：盘在熔岩里的一条玄武岩巨龙，浑身挂满抢来的黄金与宝石——"镀金的龙"。
## 下半身是蛇一样盘起来的两圈身子(尾巴尖从右前方绕出来)，上半身直立：胸腹是一片片叠着的腹鳞(鳞缝里透出熔岩光)+ 正中一道熔岩脊线，
## 胸前两圈 V 字金项链(红宝石大坠子 + 绿宝石 / 蓝宝石)，脖子上两道金颈环；一双带金臂环(嵌宝石)的爪子搭在盘起的身子上(金爪尖、金戒指)，
## 背后一对蝙蝠翼(翼骨的前缘包金鳞、翼膜暗红带熔岩翼脉、焦黑的外缘和烧穿的洞，翼骨上挂着一串串金链和宝石吊坠)，
## 头上戴一圈金冠(五个尖 + 宝石)，两只弯角各三道金箍、金角尖，金耳环；眉骨突出、眼睛发光、满口獠牙、张着发光的大嘴。
## 盘起的身子：上圈顶上一列金鳞甲，底圈绕着一道道嵌宝石的金箍、箍间垂着金链，上面放着三顶小王冠和两堆金币。背脊正中也是一列金鳞 + 一排(金尖的)骨刺。
## 俯视的标志：巨大的火红双翼 + 满身的金(翼骨前缘的金鳞 + 金链宝石、盘身的金箍 / 王冠 / 金币堆、头上的金冠和金箍角)。
## 挂骨：盘起的身子(含金饰)挂 Root(不动)，躯干 Hips / Spine / Chest，脖子 Neck，上颌和头 Head(张嘴 = 头往后仰)，下颌挂 Neck，
##   手臂挂手臂骨链，翅膀挂 Wing_L / Wing_R(扑动由 anim_chars 的 *_vanity 动作直接控制)。全部刚体。
## 单位数据 scale = 2(直径是普通单位的两倍)；虚荣状态下表现层再放大 √2。
## 精细化：两种尺度的熔岩裂纹(大块岩板 + 细发丝缝，只裂玄武岩)，最后一遍"倒角"按局部的凸凹把棱边提亮一档、凹处压暗一档(玄武岩 / 金 / 角 / 骨刺)。

const IDENTITY := {"rim": "#ffb02e", "rim_k": 0.18, "pulse": 0.55}

# 盘起的身子：底圈 / 上圈的圆心、半径(到管子中心)、管子半径
const C1 := Vector3(0.0, 9.0, -2.0)
const R1 := 25.0
const T1 := 9.5
const C2 := Vector3(-1.0, 22.0, -5.0)
const R2 := 16.0
const T2 := 7.5
const TAIL := [Vector3(-22.0, 9.0, 12.0), Vector3(-30.0, 7.0, 22.0), Vector3(-36.0, 7.0, 28.0), Vector3(-41.0, 10.0, 27.0), Vector3(-44.0, 15.0, 22.0)]
# 左翼(右翼镜像)：肩 / 肘 / 腕 / 四个指尖
const W_SH := Vector3(8.0, 66.0, -10.0)
const W_EL := Vector3(28.0, 98.0, -15.0)
const W_WR := Vector3(44.0, 112.0, -14.0)
const W_TIPS := [Vector3(60.0, 104.0, -13.0), Vector3(58.0, 78.0, -14.0), Vector3(46.0, 58.0, -14.0), Vector3(30.0, 54.0, -13.0)]

var G0: int        # 金：本色
var G1: int        # 暗
var G2: int        # 亮(棱)
var G3: int        # 最暗(片与片之间的缝)
var K0: int        # 金链：亮的环
var K1: int        # 金链：暗的扣
var CN0: int       # 金币
var CN1: int
var CN2: int
var BL0: int       # 腹鳞
var BL1: int       # 腹鳞的下缘(凸出来的一圈)
var BN0: int       # 骨刺 / 翼骨 / 爪 / 眉骨(不裂的玄武岩)
var BN1: int
var BN2: int
var HN0: int       # 角
var HN1: int
var HN2: int
var TT0: int       # 牙
var TT1: int
var WC: int        # 翼膜焦黑的外缘 / 翼骨下的岩壳(不参与倒角，免得两格厚的膜整片被当成棱边提亮)
var WC2: int
var GEMS := {}     # 宝石：名字 -> [深色外圈, 本色, 切面高光]
var _fam := {}     # 倒角：颜色 -> [亮一档, 暗一档, 最暗]
var _wpoly := PackedVector2Array()
var _veins: Array = []       # 翼脉：[Vector2 起点, Vector2 终点, 半宽]
var _holes: Array = []       # 烧穿的洞：Vector3(x, y, 半径)


func build() -> void:
	ember_init()
	_colors()
	var bf := Callable(self, "basalt")
	g.sym = false
	# ================================================================ 形体(先搭身子，裂纹画完再挂金饰)
	# ---------------------------------------------------------------- 盘起来的身子(Root)：底下一大圈 + 上面一小圈 + 绕出来的尾巴
	g.use("Root")
	g.ring(C1, Vector3.UP, R1, T1 * 2.0, bf)
	g.ring(C2, Vector3.UP, R2, T2 * 2.0, bf)
	# 尾巴：从底圈的右前方绕出来，尖端是一截熔岩
	tube(TAIL, 7.5, 1.8, false, 0.22, 3)
	# ---------------------------------------------------------------- 躯干(Hips / Spine / Chest)：从盘身前面立起来
	g.use("Hips")
	g.sq(0.0, 34.0, 4.0, 13.0, 14.0, 12.0, bf, 2.2)
	g.use("Spine")
	g.sq(0.0, 51.0, 3.0, 14.0, 9.0, 12.5, bf, 2.2)
	g.use("Chest")
	g.sq(0.0, 63.0, 2.0, 16.0, 9.0, 13.0, bf, 2.2)
	g.sq(0.0, 70.0, 0.0, 12.0, 5.0, 10.0, bf, 2.2)
	# ---------------------------------------------------------------- 脖子 + 下颌(Neck)
	g.use("Neck")
	g.seg(Vector3(0.0, 70.0, 1.0), Vector3(0.0, 84.0, 6.0), 9.0, 7.0, bf)
	g.sq(0.0, 82.0, 17.0, 6.5, 3.2, 10.0, bf, 2.2)
	# ---------------------------------------------------------------- 头(Head)：头骨 + 往前伸的上颌 + 鼻头 + 鼻梁上一道骨棱
	g.use("Head")
	g.sq(0.0, 95.0, 6.0, 9.5, 8.0, 10.0, bf, 2.3)
	g.sq(0.0, 92.0, 19.0, 7.0, 4.5, 9.0, bf, 2.2)
	g.sq(0.0, 95.0, 25.0, 4.5, 3.0, 3.0, bf, 2.0)                  # 鼻头
	# ---------------------------------------------------------------- 手臂(对称)：粗壮的鳞臂 + 肩头 + 手掌
	g.sym = true
	g.use("UpperArm_L")
	g.seg(Vector3(14.0, 65.0, 2.0), Vector3(19.0, 54.0, 7.0), 6.5, 5.5, bf)
	g.sq(15.0, 66.0, 1.0, 6.0, 5.0, 6.0, bf, 2.2)               # 肩头
	g.use("LowerArm_L")
	g.seg(Vector3(19.0, 54.0, 7.0), Vector3(20.0, 44.0, 14.0), 5.5, 4.8, bf)
	g.use("Hand_L")
	g.sq(20.0, 42.0, 16.0, 5.5, 4.0, 5.5, bf, 2.2)
	g.sym = false
	# ================================================================ 两种尺度的熔岩裂纹：大块岩板(缝宽、烧穿的发亮) + 细发丝缝(大多是暗缝)
	_fissures(-50, -2, -40, 50, 112, 36, 9.5, 0.95, 0.22, 11, 0.5, false)
	_fissures(-50, -2, -40, 50, 112, 36, 3.4, 0.42, 0.0, 37, 0.08, true)
	# ================================================================ 细节与金饰
	# ---------------------------------------------------------------- 盘身(Root)
	g.use("Root")
	_coil_belly(C1, R1, T1)
	_coil_scutes(C2, R2, T2, deg_to_rad(80.0), 1.7, 5.5)
	# 底圈的金箍(各嵌一颗宝石) + 箍与箍之间垂下来的金链
	var bands: Array = [0.35, 1.25, 2.3, 3.4, 4.6, 5.5]
	var band_gems: Array = ["ruby", "sapphire", "topaz", "ruby", "emerald", "sapphire"]
	for i in [0, 1, 3, 4]:
		var a0: float = bands[i]
		var a1: float = bands[(i + 1) % bands.size()]
		_coil_chain(C1, R1, T1, a0 + 0.07, a1 - 0.07)
	for i2 in range(bands.size()):
		_coil_band(C1, R1, T1, bands[i2], band_gems[i2], deg_to_rad(48.0))
	# 上圈的金箍(前面被躯干挡住的地方不放)
	var ub: Array = [0.15, 2.85, 4.55]
	var ub_gems: Array = ["emerald", "ruby", "sapphire"]
	for i3 in range(ub.size()):
		_coil_band(C2, R2, T2, ub[i3], ub_gems[i3], deg_to_rad(70.0))
	# 小王冠(放在盘身顶上) + 一堆堆金币
	_crown(_on_coil(C1, R1, T1, 1.57, 90.0) + Vector3(0.0, -0.8, 0.0), 4.4, 0.0, 4.0)
	_crown(_on_coil(C2, R2, T2, 0.85, 90.0) + Vector3(0.0, -0.6, 0.0), 3.8, 0.5, 3.0)
	_crown(_on_coil(C1, R1, T1, 5.1, 90.0) + Vector3(0.0, -0.8, 0.0), 4.0, 3.4, 3.5)
	_coins(_on_coil(C1, R1, T1, 2.0, 84.0), 3.6, 2.4, 5)
	_coins(_on_coil(C1, R1, T1, 4.05, 84.0), 3.4, 2.2, 13)
	# 尾巴上两道金箍
	_tail_band(1, 0.3, "ruby")
	_tail_band(2, 0.1, "")
	# ---------------------------------------------------------------- 躯干：腹鳞(鳞缝透光) + 背脊金鳞 + 骨刺
	_belly_scutes(30, 78, 9)
	_dorsal_plates(28, 84, 3)
	for k in range(9):
		var y: float = 31.0 + float(k) * 5.2
		var bone: String = "Hips" if y < 46.0 else ("Spine" if y < 56.0 else "Chest")
		g.use(bone)
		var big: bool = k % 2 == 0
		var base := Vector3(0.0, y, -8.0 - (1.5 if y > 56.0 else 0.0))
		var tip := Vector3(0.0, y + (4.0 if big else 2.5), -18.0 if big else -14.5)
		g.seg(base, base.lerp(tip, 0.72), 2.6 if big else 1.8, 1.0 if big else 0.7, BN0)
		g.seg(base.lerp(tip, 0.72), tip, 1.0 if big else 0.7, 0.3, G0 if big else BN1)
	# 脖子背面的三根骨刺
	g.use("Neck")
	for k2 in range(3):
		var yn: float = 72.5 + float(k2) * 4.5
		var zb: float = lerpf(-7.5, -2.5, float(k2) / 2.0)
		g.seg(Vector3(0.0, yn, zb), Vector3(0.0, yn + 3.0, zb - 7.0), 2.0, 0.6, BN0)
		g.seg(Vector3(0.0, yn + 2.2, zb - 5.2), Vector3(0.0, yn + 3.4, zb - 8.0), 0.7, 0.25, G0)
	# 金项链：三圈 V 字链子 + 红宝石大坠子(金托 + 一圈小金珠) + 下面一颗绿宝石，短的那圈挂一颗蓝宝石
	_necklace(11.5, 71.0, 59.5, "Chest")
	_necklace(14.0, 69.0, 50.5, "Spine")
	g.use("Chest")
	_gem(_surf(Vector3(0.0, 57.8, 0.0), Vector3(0, 0, 1)) + Vector3(0.0, 0.0, 0.6), Vector3(0, 0.1, 1), 1.3, 1.5, "sapphire")
	g.use("Spine")
	_medallion(_surf(Vector3(0.0, 47.5, 0.0), Vector3(0, 0, 1)) + Vector3(0.0, 0.0, 0.2), 3.2)
	_gem(_surf(Vector3(0.0, 40.5, 0.0), Vector3(0, 0, 1)) + Vector3(0.0, 0.0, 0.6), Vector3(0, 0.15, 1), 1.5, 2.0, "emerald")
	# ---------------------------------------------------------------- 脖子：两道金颈环(带宝石) + 下颌里的熔岩、舌头、獠牙、下巴的骨刺
	g.use("Neck")
	var nd := Vector3(0.0, 14.0, 5.0).normalized()
	for t: float in [0.22, 0.58]:
		var nc := Vector3(0.0, 70.0, 1.0).lerp(Vector3(0.0, 84.0, 6.0), t)
		var nr: float = lerpf(9.0, 7.0, t)
		g.ring(nc, nd, nr + 0.2, 2.6, G0)
		g.ring(nc + nd * 1.3, nd, nr + 0.6, 1.0, G2)
		g.ring(nc - nd * 1.3, nd, nr + 0.6, 1.0, G2)
	var nc0 := Vector3(0.0, 70.0, 1.0).lerp(Vector3(0.0, 84.0, 6.0), 0.22)
	var nf: Vector3 = (Vector3(0.0, 0.0, 1.0) - nd * nd.z).normalized()
	_gem(nc0 + nf * (lerpf(9.0, 7.0, 0.22) + 1.4), nf, 1.3, 1.5, "ruby")
	_paint_mouth_floor()
	g.use("Neck", 70)
	g.box(-1, 85, 13, 0, 85, 21, L1)                               # 发光的舌头
	g.cur_glow = 0
	for k3 in range(3):
		var zf: float = 14.0 + float(k3) * 4.0
		for sx: float in [5.0, -5.0]:
			_fang(Vector3(sx, 84.5, zf), Vector3(sx * 0.92, 87.2, zf + 0.5), 0.85)
	for sx2: float in [2.2, -2.2]:
		_fang(Vector3(sx2, 84.5, 25.5), Vector3(sx2, 86.5, 26.0), 0.6)
	for sx3: float in [3.5, -3.5]:
		g.seg(Vector3(sx3, 80.0, 20.0), Vector3(sx3 * 1.15, 75.5, 17.5), 1.5, 0.35, BN0)        # 下巴的骨刺
	# ---------------------------------------------------------------- 头：上颚 / 獠牙 / 鼻梁 / 眉骨 / 眼睛 / 鼻孔 / 颊刺 / 头顶刺 / 金冠 / 角 / 耳环
	g.use("Head")
	_paint_mouth_roof()
	for k4 in range(4):
		var zt: float = 12.0 + float(k4) * 4.0
		for sx4: float in [5.4, -5.4]:
			_fang(Vector3(sx4, 88.5, zt), Vector3(sx4 * 0.92, 84.5 if k4 % 2 == 0 else 86.0, zt + 0.5), 0.95)
	g.seg(Vector3(0.0, 97.6, 12.0), Vector3(0.0, 97.6, 24.5), 1.7, 1.3, BN0)                    # 鼻梁的骨棱
	g.seg(Vector3(0.0, 98.0, 23.0), Vector3(0.0, 100.5, 21.5), 1.3, 0.3, BN1)                    # 鼻尖的小角
	g.sym = true
	# 眉骨：压在眼睛上方、往后上方翘成刺
	g.seg(Vector3(3.5, 100.0, 14.5), Vector3(7.5, 101.0, 10.0), 1.9, 1.9, BN0)
	g.seg(Vector3(7.5, 101.0, 10.0), Vector3(11.0, 104.0, 3.0), 1.9, 0.5, BN0)
	# 眼眶(炭黑的凹坑) + 发光的眼睛(白热的芯 + 橙红的一圈 + 往后拖的一道光)
	var sm0: int = g.mode
	g.mode = VGrid.PAINT
	g.box(3, 96, 12, 7, 99, 15, CH)
	g.mode = sm0
	g.cur_glow = 170
	g.box(4, 97, 14, 6, 98, 14, L3)
	g.cur_glow = 130
	g.box(4, 97, 13, 6, 98, 13, L2)
	g.put(7, 98, 13, L2)
	g.cur_glow = 110
	g.put(8, 98, 12, L1)
	g.cur_glow = 0
	# 颊后的骨刺(往后扫，最上面一根金尖)
	for k5 in range(3):
		var yy: float = 90.0 + float(k5) * 4.0
		g.seg(Vector3(8.5, yy, 0.0), Vector3(13.0, yy + 3.0, -9.0), 2.0, 0.4, BN0)
	g.seg(Vector3(12.0, 100.5, -7.0), Vector3(13.2, 101.6, -9.6), 0.8, 0.25, G0)
	# 金耳环：颊刺下挂一只金圈，底下一颗红宝石
	g.ring(Vector3(9.9, 88.6, -2.7), Vector3(1.0, 0.0, 0.2), 2.2, 1.0, G0)
	g.cur_glow = 50
	g.box(9, 85, -3, 9, 85, -3, GEMS["ruby"][1])
	g.cur_glow = 0
	g.sym = false
	# 鼻孔里的火光
	g.cur_glow = 200
	g.put(2, 96, 27, L2)
	g.put(-3, 96, 27, L2)
	g.cur_glow = 0
	# 头顶后面一排小刺
	for k6 in range(4):
		g.seg(Vector3(0.0, 102.0 - float(k6) * 2.0, 2.0 - float(k6) * 3.0), Vector3(0.0, 108.0 - float(k6) * 2.5, -3.0 - float(k6) * 3.0), 1.8, 0.4, BN0)
	_circlet()
	# 两只弯角(往后上方再往前卷)：三道金箍 + 金角尖
	g.sym = true
	_horn([Vector3(6.0, 101.0, 3.0), Vector3(9.0, 109.0, -2.0), Vector3(11.0, 117.0, -2.0), Vector3(11.0, 123.0, 3.0), Vector3(9.5, 125.0, 7.0)])
	g.sym = false
	# ---------------------------------------------------------------- 手臂(对称)：上臂 / 前臂两道金臂环(嵌宝石) + 金尖的爪 + 金戒指
	g.sym = true
	g.use("UpperArm_L")
	var ua := (Vector3(19.0, 54.0, 7.0) - Vector3(14.0, 65.0, 2.0)).normalized()
	var uc := Vector3(14.0, 65.0, 2.0).lerp(Vector3(19.0, 54.0, 7.0), 0.62)
	g.ring(uc, ua, 5.9, 2.4, G0)
	var uo: Vector3 = (Vector3(1.0, 0.0, 0.6) - ua * ua.dot(Vector3(1.0, 0.0, 0.6))).normalized()
	_gem(uc + uo * 7.0, uo, 1.2, 1.4, "sapphire")
	g.use("LowerArm_L")
	var la := Vector3(0.1, 1.0, -0.7).normalized()
	g.ring(Vector3(19.6, 48.0, 11.0), la, 5.0, 2.6, G0)
	var lo2: Vector3 = (Vector3(0.2, 0.0, 1.0) - la * la.dot(Vector3(0.2, 0.0, 1.0))).normalized()
	_gem(Vector3(19.6, 48.0, 11.0) + lo2 * 6.2, lo2, 1.4, 1.6, "ruby")
	g.use("Fingers_L")
	for f in range(3):
		var fx: float = 17.0 + float(f) * 3.0
		g.seg(Vector3(fx, 41.0, 19.0), Vector3(fx + 0.3, 37.0, 24.0), 1.6, 1.1, BN0)
		g.seg(Vector3(fx + 0.3, 37.0, 24.0), Vector3(fx + 0.3, 33.0, 25.5), 1.1, 0.3, G0)
	g.ring(Vector3(20.15, 39.0, 21.5), Vector3(0.0, -0.8, 1.0), 1.7, 0.9, G2)           # 中指上的金戒指
	g.use("Thumb_L")
	g.seg(Vector3(15.5, 43.0, 18.0), Vector3(14.6, 41.0, 20.0), 1.4, 1.0, BN0)
	g.seg(Vector3(14.6, 41.0, 20.0), Vector3(14.0, 39.0, 22.0), 1.0, 0.35, G0)
	g.sym = false
	# ---------------------------------------------------------------- 翅膀(对称，挂 Wing_L / Wing_R)
	g.sym = true
	g.use("Wing_L")
	_wing()
	g.sym = false
	# ================================================================ 倒角：棱边亮一档、凹处暗一档
	_bevel(Vector3i(-62, -2, -44), Vector3i(62, 128, 40))
	rigid_all()


# ================================================================ 颜色
func _colors() -> void:
	G0 = H("#dca23a")
	G1 = H("#9a6820")
	G2 = H("#f4cc62")
	G3 = H("#5e3c12")
	K0 = H("#e8b446")
	K1 = H("#8e5f1c")
	CN0 = H("#e8b64a")
	CN1 = H("#c48f2c")
	CN2 = H("#ffe49a")
	BL0 = H("#4a3d37")
	BL1 = H("#5a4b43")
	BN0 = H("#352d2a")
	BN1 = H("#2a2321")
	BN2 = H("#4e433e")
	HN0 = H("#2e2624")
	HN1 = H("#221c1b")
	HN2 = H("#4a3e3a")
	TT0 = H("#ecd6a6")
	TT1 = H("#b89868")
	WC = H("#2a1a15")
	WC2 = H("#30292a")
	GEMS = {
		"ruby": [H("#6e0614"), H("#cc1230"), H("#ff9aa8")],
		"emerald": [H("#0a5a2a"), H("#1eae58"), H("#c4ffd8")],
		"sapphire": [H("#0c2070"), H("#2a5ae6"), H("#c6daff")],
		"topaz": [H("#9a4208"), H("#ff9a2a"), H("#ffeab0")],
	}
	_fam = {
		B0: [B2, B1, B3], B1: [B2, B1, B3], B2: [B2, B1, B3],
		BN0: [BN2, BN1, B3], BN1: [BN2, BN1, B3],
		G0: [G2, G1, G3], G1: [G2, G1, G3], G2: [G2, G1, G3],
		BL0: [BL1, B0, B1], BL1: [BL1, B0, B1],
		HN0: [HN2, HN1, HN1], HN1: [HN2, HN1, HN1],
	}


# ================================================================ 材质
## 翼膜：火红 / 暗红的斑驳，熔岩翼脉(白热的芯 + 橙色的晕)，外缘一圈焦黑 + 一圈暗红，翼骨下面一条暗色的岩壳；烧穿的洞边一圈白热
func membrane_fn(x: int, y: int, _z: int) -> int:
	var q := Vector2(float(x) + 0.5, float(y) + 0.5)
	for hc: Vector3 in _holes:
		var dh: float = q.distance_to(Vector2(hc.x, hc.y)) - hc.z
		if dh < 0.0:
			return 0
		if dh < 1.1:
			g.cur_glow = 120
			return L3
		if dh < 2.0:
			g.cur_glow = 30
			return L2
	var de: float = _poly_dist(q, _wpoly)
	if de < 1.2:
		g.cur_glow = 0
		return WC
	var dv := 99.0
	for vn: Array in _veins:
		dv = minf(dv, _seg_dist(q, vn[0], vn[1]) - float(vn[2]))
	if dv < 0.4:
		g.cur_glow = 100
		return L3 if h01(x, y, 5) > 0.5 else L2
	if dv < 0.95:
		g.cur_glow = 35
		return L2
	# 翼骨下面一条暗色的岩壳(和卡上一样：翼的上半截发黑)
	var da: float = minf(_seg_dist(q, Vector2(W_SH.x, W_SH.y), Vector2(W_EL.x, W_EL.y)), _seg_dist(q, Vector2(W_EL.x, W_EL.y), Vector2(W_WR.x, W_WR.y)))
	var n: float = h01(x >> 1, y >> 1, 7)
	if da < 3.6 + 1.6 * n:
		g.cur_glow = 0
		return WC2 if h01(x, y, 2) > 0.3 else WC
	if de < 2.4:
		g.cur_glow = 0
		return L0
	# 膜本身：越往下越热，按 2 体素的斑块深浅交错(远看是一片火红，近看有层次)，翼脉旁边亮一点
	var low: float = clampf((100.0 - float(y)) / 44.0, 0.0, 1.0)
	var heat: float = 0.2 + 0.25 * low + 0.35 * n + 0.2 * clampf(1.0 - (dv - 1.1) / 3.0, 0.0, 1.0)
	if heat > 0.88:
		g.cur_glow = 20
		return L2
	if heat > 0.42:
		g.cur_glow = 8
		return L1
	g.cur_glow = 0
	return L0


## 金币堆：随机的亮 / 本色 / 暗金，零星混着几颗宝石
func coin_fn(x: int, y: int, z: int) -> int:
	var r: float = h01(x, y * 3, z)
	if r > 0.965:
		var ks: Array = ["ruby", "emerald", "sapphire"]
		return GEMS[ks[int(h01(z, x, y) * 2.99)]][1]
	if r > 0.7:
		return CN2
	if r < 0.22:
		return CN1
	return CN0


# ================================================================ 盘身
## 盘身上一点的位置：a = 绕竖轴的角度(0 = +X 左侧，π/2 = 正前方)，phi_deg = 管子截面上的角度(0 朝外，90 朝上)
static func _on_coil(c: Vector3, rr: float, tr: float, a: float, phi_deg: float) -> Vector3:
	var phi: float = deg_to_rad(phi_deg)
	return c + Vector3(cos(a), 0.0, sin(a)) * (rr + tr * cos(phi)) + Vector3(0.0, tr * sin(phi), 0.0)


static func _coil_n(a: float, phi: float) -> Vector3:
	return Vector3(cos(a) * cos(phi), sin(phi), sin(a) * cos(phi))


## 盘身外下沿的腹鳞：一片片横着的宽鳞(浅一点的岩色)，鳞缝里透出暗红的熔岩光
func _coil_belly(c: Vector3, rr: float, tr: float) -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.PAINT_SURF
	var reff: float = rr + tr * 0.85
	for z in range(int(c.z - rr - tr) - 2, int(c.z + rr + tr) + 3):
		for x in range(int(c.x - rr - tr) - 2, int(c.x + rr + tr) + 3):
			var px: float = float(x) + 0.5 - c.x
			var pz: float = float(z) + 0.5 - c.z
			var hr: float = sqrt(px * px + pz * pz)
			if hr < rr + tr * 0.35:
				continue
			var a: float = fposmod(atan2(pz, px), TAU)
			var s: float = a * reff / 3.4
			var u: float = s - floor(s)
			for y in range(int(c.y - tr) - 1, int(c.y - 1.0)):
				if not g.solid(x, y, z):
					continue
				var c0: int = g.get_col(x, y, z)
				if c0 == L0 or c0 == L1 or c0 == L2 or c0 == L3:
					continue
				var phi: float = atan2(float(y) + 0.5 - c.y, hr - rr)
				if phi < deg_to_rad(-62.0) or phi > deg_to_rad(-8.0):
					continue
				if u < 0.2:
					var lit: bool = h01(int(floor(s)), 3, 1) < 0.6
					g.cur_glow = 70 if lit else 0
					g.put(x, y, z, L1 if lit else B3)
				else:
					g.cur_glow = 0
					g.put(x, y, z, BL1 if u < 0.42 else BL0)
	g.mode = sm
	g.cur_glow = sg


## 盘身背上的一列金鳞甲：沿盘身一片接一片(plate = 每片沿盘身的长度)，前缘平、后缘收尖(盾形)，片的中间凸起一格，片与片之间一道暗缝。
## phi_c = 这列鳞甲在管子截面上的角度(0 朝外、90° 朝上)，half_w = 半宽(体素)
func _coil_scutes(c: Vector3, rr: float, tr: float, phi_c: float, half_w: float, plate: float) -> void:
	var reff: float = rr + tr * cos(phi_c)
	var raise: Array[Vector3i] = []
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.PAINT
	g.cur_glow = 0
	var ro: float = rr + tr + 2.0
	for z in range(int(floor(c.z - ro)), int(ceil(c.z + ro)) + 1):
		for x in range(int(floor(c.x - ro)), int(ceil(c.x + ro)) + 1):
			var px: float = float(x) + 0.5 - c.x
			var pz: float = float(z) + 0.5 - c.z
			var hr: float = sqrt(px * px + pz * pz)
			if absf(hr - rr) > tr + 1.5:
				continue
			var a: float = fposmod(atan2(pz, px), TAU)
			var s: float = a * reff / plate
			var u: float = s - floor(s)
			for y in range(int(c.y - 1.0), int(c.y + tr) + 3):
				if not g.solid(x, y, z) or not g.is_surface(x, y, z):
					continue
				var qy: float = float(y) + 0.5 - c.y
				var qr: float = hr - rr
				if absf(sqrt(qy * qy + qr * qr) - tr) > 1.4:
					continue
				var phi: float = atan2(qy, qr)
				var v: float = (phi - phi_c) * tr
				var w: float = half_w * (1.0 - 0.6 * clampf((u - 0.6) / 0.4, 0.0, 1.0))
				if absf(v) > w + 0.4:
					continue
				if u < 0.3:
					continue
				g.put(x, y, z, G0)
				if u > 0.38 and u < 0.85 and absf(v) < w - 0.8:
					var q: Vector3 = Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) + _coil_n(a, phi) * 1.0
					raise.append(Vector3i(int(floor(q.x)), int(floor(q.y)), int(floor(q.z))))
	g.mode = VGrid.ADD
	for p: Vector3i in raise:
		g.put(p.x, p.y, p.z, G0)
	g.mode = sm
	g.cur_glow = sg


## 盘身上的一道金箍：在角度 a 处绕着盘身的管子一圈(中间宽带 + 两道凸起的边)，phi_gem 处嵌一颗宝石
func _coil_band(c: Vector3, rr: float, tr: float, a: float, gem_kind: String, phi_gem: float) -> void:
	var ctr: Vector3 = c + Vector3(cos(a) * rr, 0.0, sin(a) * rr)
	var tangent := Vector3(-sin(a), 0.0, cos(a))
	g.ring(ctr, tangent, tr + 0.3, 3.2, G0)
	g.ring(ctr + tangent * 1.6, tangent, tr + 0.9, 1.1, G2)
	g.ring(ctr - tangent * 1.6, tangent, tr + 0.9, 1.1, G2)
	var n: Vector3 = _coil_n(a, phi_gem)
	_gem(ctr + n * (tr + 1.1), n, 1.6, 1.6, gem_kind)


## 两道金箍之间垂下来的金链：两端系在盘身的上外侧(phi 35°)，中间垂到外侧偏下(phi -6°)
func _coil_chain(c: Vector3, rr: float, tr: float, a0: float, a1: float) -> void:
	var pts: Array = []
	var n_pts: int = int(absf(a1 - a0) * rr / 1.2) + 2
	for i in range(n_pts + 1):
		var t: float = float(i) / float(n_pts)
		var a: float = lerpf(a0, a1, t)
		var phi: float = deg_to_rad(lerpf(35.0, -6.0, 4.0 * t * (1.0 - t)))
		var n: Vector3 = _coil_n(a, phi)
		pts.append(_surf(c + Vector3(cos(a) * rr, 0.0, sin(a) * rr) + n * (tr - 2.0), n))
	_chain(pts)


## 小王冠：一圈两格高的金箍 + 五个尖(尖上一颗亮金珠) + 箍上一圈小宝石，front = 正面(大红宝石)朝的角度
func _crown(c: Vector3, r: float, front: float, tall: float) -> void:
	var ks: Array = ["sapphire", "emerald", "ruby", "emerald", "sapphire"]
	var n_seg: int = int(TAU * r * 1.6)
	for i in range(n_seg):
		var a: float = float(i) * TAU / float(n_seg)
		var p: Vector3 = c + Vector3(cos(a) * r, 0.0, sin(a) * r)
		g.box(int(floor(p.x)), int(floor(c.y)) - 1, int(floor(p.z)), int(floor(p.x)), int(floor(c.y)) + 1, int(floor(p.z)), G0)
	# 箍里面塞满(从上面看不透)
	var sm: int = g.mode
	g.mode = VGrid.ADD
	g.ytaper(int(floor(c.y)) - 1, int(floor(c.y)), c.x, c.z, r - 0.4, r - 0.4, c.x, c.z, r - 0.4, r - 0.4, G1)
	g.mode = sm
	for k in range(5):
		var a2: float = front + float(k) * TAU / 5.0
		var o := Vector3(sin(a2), 0.0, cos(a2))
		var base: Vector3 = c + o * r + Vector3(0.0, 1.5, 0.0)
		var h: float = tall if k == 0 else tall * 0.75
		g.seg(base, base + Vector3(0.0, h, 0.0) + o * 0.4, 1.2, 0.35, G0)
		g.put(int(floor(base.x + o.x * 0.4)), int(floor(base.y + h)) + 1, int(floor(base.z + o.z * 0.4)), G2)
		var am: float = a2 + TAU / 10.0
		var om := Vector3(sin(am), 0.0, cos(am))
		_gem(c + om * (r + 0.6) + Vector3(0.0, 0.2, 0.0), om, 0.7, 0.7, ks[k])
	var of := Vector3(sin(front), 0.0, cos(front))
	_gem(c + of * (r + 0.7) + Vector3(0.0, 0.4, 0.0), of, 1.1, 1.3, "ruby")


## 一堆金币(圆顶，ADD 模式只填空格)：顶上再立几枚侧放的金币
func _coins(c: Vector3, r: float, h: float, seed_i: int) -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.ADD
	g.cur_glow = 0
	var cf := Callable(self, "coin_fn")
	for z in range(int(floor(c.z - r)) - 1, int(ceil(c.z + r)) + 1):
		for x in range(int(floor(c.x - r)) - 1, int(ceil(c.x + r)) + 1):
			var dx: float = (float(x) + 0.5 - c.x) / r
			var dz: float = (float(z) + 0.5 - c.z) / r
			var d2: float = dx * dx + dz * dz
			if d2 > 1.0:
				continue
			var top: float = c.y + h * sqrt(1.0 - d2) * (0.8 + 0.4 * h01(x + seed_i, 1, z))
			for y in range(int(floor(c.y)) - 3, int(top) + 1):
				g.put(x, y, z, cf)
	g.mode = sm
	# 立着的金币(1 格厚的小圆片)
	for k in range(3):
		var a: float = float(seed_i) + float(k) * 2.1
		var p := c + Vector3(cos(a) * r * 0.55, h * 0.75, sin(a) * r * 0.55)
		var t := Vector3(-sin(a), 0.0, cos(a))
		for du in range(-1, 2):
			for dv in range(-1, 2):
				if absi(du) + absi(dv) > 1 and k != 0:
					continue
				var q: Vector3 = p + t * float(du) + Vector3(0.0, float(dv), 0.0)
				g.put(int(floor(q.x)), int(floor(q.y)), int(floor(q.z)), CN2 if dv > 0 else CN0)
	g.cur_glow = sg


## 尾巴上的金箍：套在尾巴第 i 个控制点附近
func _tail_band(i: int, lift: float, gem_kind: String) -> void:
	var p0: Vector3 = TAIL[i - 1]
	var p1: Vector3 = TAIL[i]
	var p2: Vector3 = TAIL[i + 1]
	var d: Vector3 = (p2 - p0).normalized()
	var u: float = float(i) / float(TAIL.size() - 1)
	var r: float = lerpf(7.5, 1.8, u * 0.95)
	var c: Vector3 = p1 + Vector3(0.0, lift, 0.0)
	g.ring(c, d, r + 0.2, 2.6, G0)
	g.ring(c + d * 1.3, d, r + 0.6, 1.0, G2)
	g.ring(c - d * 1.3, d, r + 0.6, 1.0, G2)
	if gem_kind != "":
		var up: Vector3 = (Vector3.UP - d * d.dot(Vector3.UP)).normalized()
		_gem(c + up * (r + 1.0), up, 1.3, 1.3, gem_kind)


# ================================================================ 躯干
## 胸腹的腹鳞：一排排 Λ 形的横鳞(往下叠，下缘凸出一格、颜色亮一档)，鳞缝透出熔岩光，正中一道最亮的熔岩脊线
func _belly_scutes(y0: int, y1: int, half: int) -> void:
	var ok_b: Array = [rig.ids["Hips"], rig.ids["Spine"], rig.ids["Chest"], rig.ids["Neck"]]
	var lips: Array = []
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.PAINT
	for y in range(y0, y1 + 1):
		for x in range(-half, half):
			var z: int = 34
			while z > -4 and not g.solid(x, y, z):
				z -= 1
			if z <= -4:
				continue
			var b: int = g.get_bone(x, y, z)
			if not (b in ok_b):
				continue
			if b == rig.ids["Neck"] and y > 75:
				continue
			var ax: float = absf(float(x) + 0.5)
			var yv: float = float(y) + ax * 0.45
			var v: float = fposmod(yv - 1.0, 4.5) / 4.5
			if ax < 1.0:
				g.cur_glow = 140 if v < 0.24 else 100
				g.put(x, y, z, L3 if v < 0.24 else L2)
			elif v < 0.24:
				g.cur_glow = 80 if ax < 4.0 else 55
				g.put(x, y, z, L2 if ax < 3.0 else L1)
			elif v < 0.48:
				g.cur_glow = 0
				g.put(x, y, z, BL1)
				if ax < float(half) - 1.5:
					lips.append([Vector3i(x, y, z + 1), b])
			else:
				g.cur_glow = 0
				g.put(x, y, z, BL0)
	g.mode = VGrid.ADD
	g.cur_glow = 0
	for lp: Array in lips:
		var p: Vector3i = lp[0]
		g.cur_bone = int(lp[1])
		g.put(p.x, p.y, p.z, BL1)
	g.mode = sm
	g.cur_glow = sg


## 背脊正中的一列金鳞(躯干 + 脖子的背面)：V 形一片片往下叠，片间一道暗缝，片中间凸起一格
func _dorsal_plates(y0: int, y1: int, half: int) -> void:
	var ok_b: Array = [rig.ids["Hips"], rig.ids["Spine"], rig.ids["Chest"], rig.ids["Neck"]]
	var raise: Array = []
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.PAINT
	g.cur_glow = 0
	for y in range(y0, y1 + 1):
		for x in range(-half, half):
			var z: int = -30
			while z < 8 and not g.solid(x, y, z):
				z += 1
			if z >= 8:
				continue
			var b: int = g.get_bone(x, y, z)
			if not (b in ok_b):
				continue
			var ax: float = absf(float(x) + 0.5)
			var v: float = fposmod(float(y) - ax * 0.8, 5.0) / 5.0
			if v < 0.2:
				g.put(x, y, z, G3)
				continue
			g.put(x, y, z, G0)
			if v > 0.32 and ax < float(half) - 0.6:
				raise.append([Vector3i(x, y, z - 1), b])
	g.mode = VGrid.ADD
	for r: Array in raise:
		var p: Vector3i = r[0]
		g.cur_bone = int(r[1])
		g.put(p.x, p.y, p.z, G0)
	g.mode = sm
	g.cur_glow = sg


## V 字项链：从两侧锁骨(半宽 hw、高 top_y)垂到胸前 bottom_y，贴着身体表面，一节节的金链
func _necklace(hw: float, top_y: float, bottom_y: float, bone: String) -> void:
	g.use(bone)
	var pts: Array = []
	for i in range(17):
		var t: float = float(i) / 16.0
		var x: float = lerpf(-hw, hw, t)
		var sag: float = 1.0 - pow(2.0 * t - 1.0, 2.0)
		var y: float = lerpf(top_y, bottom_y, sag)
		pts.append(_surf(Vector3(x, y, -2.0), Vector3(0.0, 0.0, 1.0)))
	_chain(pts)


## 大坠子：金托(一圈小金珠) + 正中一颗大红宝石
func _medallion(c: Vector3, r: float) -> void:
	g.sq(c.x, c.y, c.z, r + 0.6, r + 1.0, 0.9, G0, 2.0)
	for k in range(10):
		var a: float = float(k) * TAU / 10.0
		var p: Vector3 = c + Vector3(cos(a) * (r + 1.2), sin(a) * (r + 1.6), 0.8)
		g.put(int(floor(p.x)), int(floor(p.y)), int(floor(p.z)), G2)
	_gem(c + Vector3(0.0, 0.0, 0.8), Vector3(0, 0.1, 1), r - 1.0, r - 0.4, "ruby")


# ================================================================ 头
## 下颌里面(嘴底)涂成熔岩
func _paint_mouth_floor() -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.PAINT
	for z in range(9, 27):
		for x in range(-5, 6):
			for y in range(82, 87):
				if g.solid(x, y, z) and not g.solid(x, y + 1, z):
					g.cur_glow = 110 if absi(x) <= 1 else 70
					g.put(x, y, z, L2 if absi(x) <= 1 else L1)
	g.mode = sm
	g.cur_glow = sg


## 上颚：上颌的底面涂成熔岩
func _paint_mouth_roof() -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.PAINT
	for z in range(9, 27):
		for x in range(-6, 7):
			for y in range(86, 92):
				if g.solid(x, y, z) and not g.solid(x, y - 1, z):
					g.cur_glow = 110
					g.put(x, y, z, L2 if absi(x) <= 2 else L1)
	g.mode = sm
	g.cur_glow = sg


## 獠牙：象牙色、牙根暗一档
func _fang(root: Vector3, tip: Vector3, r: float) -> void:
	g.seg(root, root.lerp(tip, 0.35), r, r * 0.8, TT1)
	g.seg(root.lerp(tip, 0.35), tip, r * 0.8, 0.2, TT0)


## 金冠：一圈金箍套在头顶(眉骨上方)，前面五个尖(正中最高，尖上金珠)，箍上嵌宝石(正中大红宝石，两边蓝 / 绿宝石)
func _circlet() -> void:
	var c := Vector3(0.0, 101.4, 5.6)
	g.ring(c, Vector3.UP, 7.3, 2.6, G0)
	g.ring(c + Vector3(0.0, 1.3, 0.0), Vector3.UP, 7.7, 1.0, G2)
	var sm: int = g.mode
	g.mode = VGrid.ADD
	g.ytaper(101, 102, c.x, c.z, 6.4, 6.4, c.x, c.z, 6.0, 6.0, B0)
	g.mode = sm
	var tines: Array = [[0.0, 6.5, "ruby"], [0.62, 4.6, "sapphire"], [-0.62, 4.6, "sapphire"], [1.2, 3.4, "emerald"], [-1.2, 3.4, "emerald"]]
	for tn: Array in tines:
		var a: float = float(tn[0])
		var o := Vector3(sin(a), 0.0, cos(a))
		var base: Vector3 = c + o * 7.4 + Vector3(0.0, 1.2, 0.0)
		var h: float = float(tn[1])
		g.seg(base, base + Vector3(0.0, h, 0.0) + o * 0.6, 1.3, 0.35, G0)
		g.put(int(floor(base.x + o.x * 0.6)), int(floor(base.y + h)) + 1, int(floor(base.z + o.z * 0.6)), G2)
		_gem(c + o * 8.3 + Vector3(0.0, -0.1, 0.0), o, 1.0 if a != 0.0 else 1.3, 1.0 if a != 0.0 else 1.5, str(tn[2]))


## 弯角：深色带一圈圈细棱，三道金箍(中间那道嵌宝石)，金角尖
func _horn(pts: Array) -> void:
	g.use("Head")
	var hn := Callable(self, "horn_fn")
	for i in range(pts.size() - 1):
		var r0: float = lerpf(3.6, 0.7, float(i) / float(pts.size() - 1))
		var r1: float = lerpf(3.6, 0.7, float(i + 1) / float(pts.size() - 1))
		g.seg(pts[i], pts[i + 1], r0, r1, hn)
	# 角尖包金
	var tip: Vector3 = pts[pts.size() - 1]
	var pre: Vector3 = pts[pts.size() - 2]
	g.seg(pre.lerp(tip, 0.55), tip + (tip - pre).normalized() * 0.8, 1.1, 0.35, G0)
	# 三道金箍
	for k: Array in [[0, 0.8, 3.4], [1, 0.6, 2.6], [2, 0.55, 1.9]]:
		var i0: int = int(k[0])
		var p: Vector3 = (pts[i0] as Vector3).lerp(pts[i0 + 1] as Vector3, float(k[1]))
		var d: Vector3 = ((pts[i0 + 1] as Vector3) - (pts[i0] as Vector3)).normalized()
		g.ring(p, d, float(k[2]), 1.6, G0)
	var p1: Vector3 = (pts[1] as Vector3).lerp(pts[2] as Vector3, 0.55)
	g.put(int(floor(p1.x + 3.5)), int(floor(p1.y)), int(floor(p1.z)), GEMS["ruby"][1])


func horn_fn(x: int, y: int, z: int) -> int:
	return HN1 if (y + (z >> 1)) % 3 == 0 else HN0


# ================================================================ 翅膀
## 一只翅膀(左翼，x > 0；sym 镜像出右翼)：翼骨(肩 → 肘 → 腕，前缘包一排金鳞)、四根指骨往下张开(指尖金爪)、骨间的翼膜(熔岩翼脉 + 焦黑外缘 + 烧穿的洞)、
## 翼骨上挂两串金链(正面) + 一串(背面)、腕上垂下一条带宝石的金链
func _wing() -> void:
	var sh := W_SH
	var el := W_EL
	var wr := W_WR
	var tips: Array = W_TIPS
	# 翼膜的外轮廓：肩—肘—腕—各指尖，指尖之间往里收的弧(锯齿)
	var poly_pts := PackedVector2Array([Vector2(sh.x, sh.y), Vector2(el.x, el.y), Vector2(wr.x, wr.y)])
	for i in range(tips.size()):
		var ti: Vector3 = tips[i]
		poly_pts.append(Vector2(ti.x, ti.y))
		if i < tips.size() - 1:
			var tn: Vector3 = tips[i + 1]
			var mid: Vector3 = (ti + tn) * 0.5
			var inward: Vector3 = (Vector3(wr.x, wr.y, mid.z) - mid).normalized()
			var m2: Vector3 = mid + inward * 7.0
			poly_pts.append(Vector2(m2.x, m2.y))
	poly_pts.append(Vector2(14.0, 56.0))
	_wpoly = poly_pts
	# 熔岩翼脉：腕 → 两指之间(到 7 成处分叉)，指骨上斜出的小脉，肘 → 内侧那片膜
	var w2 := Vector2(wr.x, wr.y)
	_veins = []
	for i2 in range(tips.size() - 1):
		var ta: Vector3 = tips[i2]
		var tb: Vector3 = tips[i2 + 1]
		var m3 := Vector2((ta.x + tb.x) * 0.5, (ta.y + tb.y) * 0.5)
		var e: Vector2 = w2 + (m3 - w2) * 0.66
		_veins.append([w2 + (m3 - w2) * 0.12, e, 0.15])
		_veins.append([e, e + (Vector2(ta.x, ta.y) - e) * 0.3 + (m3 - w2).normalized() * 3.0, 0.0])
		_veins.append([e, e + (Vector2(tb.x, tb.y) - e) * 0.3 + (m3 - w2).normalized() * 3.0, 0.0])
	for i3 in range(tips.size()):
		var tt: Vector3 = tips[i3]
		var dirv: Vector2 = (Vector2(tt.x, tt.y) - w2).normalized()
		var side := Vector2(-dirv.y, dirv.x)
		if side.y > 0.0:
			side = -side
		for f: float in [0.42, 0.7]:
			var p := w2.lerp(Vector2(tt.x, tt.y), f)
			_veins.append([p, p + side * 4.5 + dirv * 2.0, 0.0])
	var e2 := Vector2(el.x, el.y)
	_veins.append([e2 + Vector2(-1.0, -4.0), Vector2(22.0, 64.0), 0.1])
	_veins.append([Vector2(22.0, 64.0), Vector2(17.0, 59.0), 0.0])
	_veins.append([Vector2(22.0, 64.0), Vector2(27.0, 58.0), 0.0])
	_holes = [Vector3(40.0, 73.0, 1.4), Vector3(51.0, 88.0, 1.2), Vector3(31.0, 65.0, 1.1), Vector3(49.5, 96.5, 1.0)]
	g.poly("xy", poly_pts, -15, -14, Callable(self, "membrane_fn"))
	g.cur_glow = 0
	# 翼骨与指骨(不裂的玄武岩)，指根一圈金环，指尖金爪
	g.seg(sh, el, 3.4, 2.6, BN0)
	g.seg(el, wr, 2.6, 2.1, BN0)
	g.sq(wr.x, wr.y, wr.z, 2.6, 2.6, 2.6, BN0, 2.0)
	g.sq(el.x, el.y, el.z, 3.0, 3.0, 3.0, BN0, 2.0)
	for t: Vector3 in tips:
		g.seg(wr, t, 1.7, 0.8, BN1)
		var dt: Vector3 = (t - wr).normalized()
		g.ring(wr + dt * 4.2, dt, 1.7, 1.0, G0)
		g.seg(t - dt * 0.5, t + dt * 2.6, 0.9, 0.25, G0)
	# 翼骨前缘的一排金鳞
	_bone_plates(sh.lerp(el, 0.14), el, 3.4, 2.6, 6)
	_bone_plates(el, wr, 2.6, 2.1, 4)
	# 肘 / 腕上的金爪
	g.seg(el, Vector3(el.x - 2.5, el.y + 7.5, el.z), 1.8, 0.4, G0)
	g.seg(wr, Vector3(wr.x + 1.0, wr.y + 6.5, wr.z), 1.5, 0.3, G0)
	# 肘上的宝石(正面红宝石、背面蓝宝石)，腕上绿宝石
	_gem(el + Vector3(0.0, -0.5, 2.6), Vector3(0, 0, 1), 1.4, 1.6, "ruby")
	_gem(el + Vector3(0.0, -0.5, -2.6), Vector3(0, 0, -1), 1.4, 1.6, "sapphire")
	_gem(wr + Vector3(0.0, -0.5, 2.3), Vector3(0, 0, 1), 1.1, 1.3, "emerald")
	# 翼骨上挂的金链：肘—腕(正面，中间吊一颗绿宝石)、肩—肘(正面，吊红宝石)、肘—腕(背面，吊蓝宝石)
	_wing_swag(el, wr, 12.0, -12.6, "emerald")
	_wing_swag(el, wr, 9.0, -15.8, "sapphire")
	# 腕上垂下来的一条金链，末端一颗红宝石
	var drop: Array = []
	for k in range(8):
		drop.append(Vector3(wr.x - 1.0, wr.y - 3.0 - float(k) * 2.0, -12.6))
	_chain(drop)
	_gem(Vector3(wr.x - 1.0, wr.y - 20.5, -12.2), Vector3(0, 0, 1), 1.0, 1.4, "ruby")


## 翼骨前缘(上沿)的一排金鳞：每片一小段粗线段，压在骨头上半边
func _bone_plates(a: Vector3, b: Vector3, ra: float, rb: float, n: int) -> void:
	var d: Vector3 = b - a
	var up := Vector3(-d.y, d.x, 0.0).normalized()
	for k in range(n):
		var t0: float = (float(k) + 0.08) / float(n)
		var t1: float = (float(k) + 0.78) / float(n)
		var r0: float = lerpf(ra, rb, t0)
		var r1: float = lerpf(ra, rb, t1)
		g.seg(a.lerp(b, t0) + up * r0 * 0.55, a.lerp(b, t1) + up * r1 * 0.45, r0 * 0.62, r1 * 0.5, G0)


## 翼骨上垂下来的一串金链(两端系在 a、b，中间垂 sag)，最低处吊一颗宝石；z = 链子挂在翼膜前(> -14)还是后(< -15)
func _wing_swag(a: Vector3, b: Vector3, sag: float, z: float, gem_kind: String) -> void:
	var pts: Array = []
	var nz := Vector3(0.0, 0.0, 1.0 if z > -14.0 else -1.0)
	for i in range(13):
		var t: float = float(i) / 12.0
		var p: Vector3 = a.lerp(b, t)
		p.y -= sag * (1.0 - pow(2.0 * t - 1.0, 2.0))
		p.z = z
		pts.append(p)
	_chain(pts)
	var m: Vector3 = pts[6]
	_gem(m + Vector3(0.0, -2.2, 0.4 * nz.z), nz, 1.1, 1.4, gem_kind)


# ================================================================ 通用的小部件
## 宝石(带金托)：c = 中心，n = 朝外的方向；金托一圈 + 凸出一格的宝石(外圈深色、里面本色、左上角一格亮的切面高光，再往外一层小台面)
func _gem(c: Vector3, n: Vector3, rx: float, ry: float, kind: String) -> void:
	var cols: Array = GEMS[kind]
	n = n.normalized()
	var upv := Vector3.UP
	if absf(n.dot(upv)) > 0.8:
		upv = Vector3(0.0, 0.0, -1.0) if n.y > 0.0 else Vector3(0.0, 0.0, 1.0)
	var rt: Vector3 = upv.cross(n).normalized()
	var u2: Vector3 = n.cross(rt).normalized()
	var rr: float = maxf(rx, ry) + 2.5
	var sg: int = g.cur_glow
	for z in range(int(floor(c.z - rr)), int(ceil(c.z + rr)) + 1):
		for y in range(int(floor(c.y - rr)), int(ceil(c.y + rr)) + 1):
			for x in range(int(floor(c.x - rr)), int(ceil(c.x + rr)) + 1):
				var q := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - c
				var a: float = q.dot(rt)
				var b: float = q.dot(u2)
				var h: float = q.dot(n)
				var e: float = pow(absf(a) / rx, 2.2) + pow(absf(b) / ry, 2.2)
				if h >= 0.4 and h < 1.4 and e <= 1.0:
					var facet: bool = a <= -0.4 and b >= 0.4 and absf(a + b) < 0.9
					if facet:
						g.cur_glow = 110
						g.put(x, y, z, cols[2])
					else:
						g.cur_glow = 45 if e < 0.55 else 25
						g.put(x, y, z, cols[1] if e < 0.55 else cols[0])
				elif h >= 1.4 and h < 2.2 and e <= 0.3:
					g.cur_glow = 60
					g.put(x, y, z, cols[1])
				elif h >= -1.0 and h < 0.4:
					var eb: float = pow(absf(a) / (rx + 1.1), 2.2) + pow(absf(b) / (ry + 1.1), 2.2)
					if eb <= 1.0:
						g.cur_glow = 0
						g.put(x, y, z, G0)
	g.cur_glow = sg


## 金链：沿折线 pts 每隔 1.8 体素一节——亮金的粗节和细一点的暗金扣交替
func _chain(pts: Array) -> void:
	var path: Array = []
	var carry: float = 0.0
	var step: float = 1.8
	path.append(pts[0])
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var ln: float = a.distance_to(b)
		if ln < 0.001:
			continue
		var t: float = step - carry
		while t <= ln:
			path.append(a.lerp(b, t / ln))
			t += step
		carry = ln - (t - step)
	var sg: int = g.cur_glow
	g.cur_glow = 0
	for j in range(path.size() - 1):
		var a2: Vector3 = path[j]
		var b2: Vector3 = path[j + 1]
		if j % 2 == 0:
			g.seg(a2, b2, 0.95, 0.95, K0)
		else:
			g.seg(a2.lerp(b2, 0.2), a2.lerp(b2, 0.8), 0.55, 0.55, K1)
	g.cur_glow = sg


## 从 p 沿 dir 穿过身体，返回刚出表面的第一个空格(把链子 / 宝石贴在表面上)
func _surf(p: Vector3, dir: Vector3) -> Vector3:
	var d: Vector3 = dir.normalized()
	var q: Vector3 = p
	var was_in := false
	for i in range(80):
		var s: bool = g.solid(int(floor(q.x)), int(floor(q.y)), int(floor(q.z)))
		if s:
			was_in = true
		elif was_in:
			return q
		q += d * 0.5
	return p


static func _seg_dist(q: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var t: float = clampf((q - a).dot(ab) / maxf(0.0001, ab.length_squared()), 0.0, 1.0)
	return q.distance_to(a + ab * t)


# ================================================================ 精细化的两遍
## 熔岩裂纹(同 _ember.gd 的 cracks：3D Voronoi 的边)，但只裂玄武岩(B0/B1/B2)——金饰、骨刺、角、翼膜、腹鳞都不碰。
## fine = false：大块的岩板，缝宽，烧穿的缝亮；fine = true：细发丝缝，暗缝用 B1(浅浅一道)，少数烧穿的是暗红的细火线
func _fissures(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, cell: float, width: float, heat: float, seed_i: int, density: float, fine: bool) -> void:
	var sm: int = g.mode
	var sg: int = g.cur_glow
	g.mode = VGrid.PAINT
	for z in range(z0, z1 + 1):
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				if not g.solid(x, y, z):
					continue
				var c0: int = g.get_col(x, y, z)
				if c0 != B0 and c0 != B1 and c0 != B2:
					continue
				if not g.is_surface(x, y, z):
					continue
				var p := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) / cell
				var ci := Vector3i(int(floor(p.x)), int(floor(p.y)), int(floor(p.z)))
				var f1 := 9.0
				var f2 := 9.0
				var c1 := Vector3i.ZERO
				var c2 := Vector3i.ZERO
				for dz in range(-1, 2):
					for dy in range(-1, 2):
						for dx in range(-1, 2):
							var c := Vector3i(ci.x + dx, ci.y + dy, ci.z + dz)
							var fp: Vector3 = Vector3(c) + _h3(c.x + seed_i, c.y, c.z) * 0.85 + Vector3.ONE * 0.075
							var d: float = p.distance_to(fp)
							if d < f1:
								f2 = f1
								c2 = c1
								f1 = d
								c1 = c
							elif d < f2:
								f2 = d
								c2 = c
				var e: float = (f2 - f1) * cell
				if e > width:
					continue
				var a: Vector3i = c1 if (c1.x * 7 + c1.y * 13 + c1.z * 29) < (c2.x * 7 + c2.y * 13 + c2.z * 29) else c2
				var bb: Vector3i = c2 if a == c1 else c1
				var lit: bool = h01(a.x * 3 + bb.x + seed_i, a.y * 5 + bb.y, a.z * 7 + bb.z) < density
				if not lit:
					g.cur_glow = 0
					g.put(x, y, z, B1 if fine else B3)
					continue
				var k: float = 1.0 - e / maxf(0.01, width)
				var hot: float = clampf(k * 0.5 + heat * 0.45 + (h01(x, y, z) - 0.5) * 0.3, 0.0, 1.0)
				var col: int
				if fine:
					col = L0
					g.cur_glow = int(20.0 + 30.0 * hot)
				else:
					col = L3 if hot > 0.93 else (L2 if hot > 0.7 else (L1 if hot > 0.36 else L0))
					g.cur_glow = int(30.0 + 90.0 * hot)
				g.put(x, y, z, col)
	g.mode = sm
	g.cur_glow = sg


## 倒角：用 5×5×5 的邻域里实体格的比例估计表面的凸凹(平面 ≈ 0.6，凸棱 ≈ 0.36，凹角 ≈ 0.84)，
## 凸的棱边亮一档、凹处暗一档(玄武岩 / 骨刺 / 金 / 腹鳞 / 角各自的色阶，见 _fam)。太细的部件(链子、尖)不动。积分体一次算完。
func _bevel(lo: Vector3i, hi: Vector3i) -> void:
	var nx: int = hi.x - lo.x + 1
	var ny: int = hi.y - lo.y + 1
	var nz: int = hi.z - lo.z + 1
	var sx1: int = nx + 1
	var sxy: int = (nx + 1) * (ny + 1)
	var P := PackedInt32Array()
	P.resize(sxy * (nz + 1))
	for z in range(nz):
		for y in range(ny):
			var gi: int = g.idx(lo.x, lo.y + y, lo.z + z)
			var base: int = (z + 1) * sxy + (y + 1) * sx1 + 1
			for x in range(nx):
				var v: int = 1 if g.col[gi + x] != 0 else 0
				var i: int = base + x
				P[i] = v + P[i - 1] + P[i - sx1] + P[i - sxy] - P[i - 1 - sx1] - P[i - 1 - sxy] - P[i - sx1 - sxy] + P[i - 1 - sx1 - sxy]
	var changes: Array = []
	for z in range(2, nz - 2):
		for y in range(2, ny - 2):
			for x in range(2, nx - 2):
				var wx: int = lo.x + x
				var wy: int = lo.y + y
				var wz: int = lo.z + z
				var gi2: int = g.idx(wx, wy, wz)
				var c0: int = g.col[gi2]
				if c0 == 0 or not _fam.has(c0):
					continue
				if not g.is_surface(wx, wy, wz):
					continue
				# 盒子 [x-2, x+2] 在 P 里的下标是 x-1 .. x+4(P 比体素多一格偏移)
				var xa: int = x - 2
				var xb: int = x + 3
				var ya: int = y - 2
				var yb: int = y + 3
				var za: int = z - 2
				var zb: int = z + 3
				var s: int = P[zb * sxy + yb * sx1 + xb] - P[za * sxy + yb * sx1 + xb] - P[zb * sxy + ya * sx1 + xb] - P[zb * sxy + yb * sx1 + xa] \
					+ P[za * sxy + ya * sx1 + xb] + P[za * sxy + yb * sx1 + xa] + P[zb * sxy + ya * sx1 + xa] - P[za * sxy + ya * sx1 + xa]
				var f: float = float(s) / 125.0
				var fam: Array = _fam[c0]
				if f < 0.16:
					continue
				if f < (0.36 if c0 == G0 or c0 == G1 or c0 == G2 else 0.43):
					changes.append([gi2, int(fam[0])])
				elif f > 0.8:
					changes.append([gi2, int(fam[2])])
				elif f > 0.72:
					changes.append([gi2, int(fam[1])])
	for ch: Array in changes:
		g.col[int(ch[0])] = int(ch[1])
