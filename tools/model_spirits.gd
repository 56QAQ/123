extends "res://tools/model_world.gd"
## 守林节点的背后灵(三个兽形各一只)：狮子 / 巨蛛 / 巨蟾的灵体。体素 5 cm(build_world.gd 缩放 4，单位直接是米)，
## 每只拆成几个部件分别存盘(assets/world/spirit_<兽>_<部件>.res)，原点 = 这个部件的转轴(关节)，由 game/view/beast_spirit.gd 拼起来、按关节动。
## 只用灰阶(亮 → 暗)雕明暗：颜色由灵体着色器按形态上色(狮子金、巨蛛紫、巨蟾青绿)；发光体素(眼睛、爪尖、背上的纹)的 glow 让它们在灵体里更亮。
## 朝 +Z，左手侧 +X，y 朝上。比例：她身高 1.3 m，灵体大一圈(狮子肩高约 1.1 m、身长约 1.8 m)。

const SPIRIT := {
	"g1": "#f4f4f4", "g2": "#d6d6d6", "g3": "#b2b2b2", "g4": "#8a8a8a", "g5": "#626262", "g6": "#3e3e3e", "eye": "#ffffff",
}


func _init(grid) -> void:
	super(grid)
	for k: String in SPIRIT.keys():
		P[k] = VGrid.hexc(SPIRIT[k])


## 毛皮：两档亮度的小块 + 零星的深色
func fur_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x >> 1, y >> 1, z >> 1)
	if r < 0.12:
		return c("g4")
	return c("g2") if r < 0.6 else c("g3")


## 鬃毛：深一档，顺着往后的条纹
func mane_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x >> 1, y, z >> 2)
	if r < 0.25:
		return c("g6")
	return c("g4") if r < 0.7 else c("g5")


## 甲壳(巨蛛)：深色、带一点亮的斑
func shell_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x >> 1, y >> 1, z >> 1)
	if r > 0.9:
		return c("g3")
	return c("g5") if r < 0.55 else c("g6")


## 巨蛛的肚子：甲壳 + 一圈圈亮一档的环纹
func abd_fn(x: int, y: int, z: int) -> int:
	if posmod(z + 30, 6) == 0:
		return c("g4")
	return shell_fn(x, y, z)


## 疣皮(巨蟾)：亮的底，零星的深色疣粒
func wart_fn(x: int, y: int, z: int) -> int:
	var r: float = _hash(x >> 1, y >> 1, z >> 1)
	if r > 0.86:
		return c("g5")
	return c("g2") if r < 0.5 else c("g3")


func _glow(on: int) -> void:
	g.cur_glow = on


# ================================================================ 狮子
## 身体(转轴 = 身体中心)：长长的躯干、胸口厚、背上一道深色的脊线、肚子亮
func spirit_lion_body() -> void:
	g.sq(0, 0, 0, 7.5, 7.0, 15.0, Callable(self, "fur_fn"))
	g.sq(0, 1, 9, 8.5, 8.0, 7.5, Callable(self, "fur_fn"))           # 胸
	g.sq(0, -1, -9, 7.5, 7.0, 7.0, Callable(self, "fur_fn"))         # 臀
	g.sq(0, -5, 0, 5.5, 2.5, 11.0, c("g1"))                         # 肚子
	g.seg(Vector3(0, 7, -12), Vector3(0, 8, 10), 1.2, 1.4, c("g5"))   # 脊线
	# 胸口和肩上的鬃毛延伸
	g.sq(0, 3, 12, 9.0, 8.0, 5.0, Callable(self, "mane_fn"))


## 头(转轴 = 脖子)：方方的头、短吻、鼻头、发光的眼睛和额头的纹，外面一大圈蓬起来的鬃毛
func spirit_lion_head() -> void:
	g.sq(0, 1, 2, 12.0, 11.0, 8.0, Callable(self, "mane_fn"))        # 鬃毛
	for i in range(14):
		var a: float = TAU * float(i) / 14.0
		g.seg(Vector3(cos(a) * 9.0, 1.0 + sin(a) * 8.5, 1), Vector3(cos(a) * 13.5, 1.0 + sin(a) * 12.5, -3), 2.2, 0.8, Callable(self, "mane_fn"))
	g.sq(0, 2, 7, 6.5, 6.0, 6.0, Callable(self, "fur_fn"))           # 脸
	g.sq(0, -1, 12, 4.0, 3.2, 3.5, c("g2"))                         # 吻
	g.sq(0, 0, 15, 1.8, 1.4, 1.0, c("g6"))                          # 鼻头
	g.sq(0, -3.5, 11.5, 3.2, 1.2, 3.0, c("g1"))                     # 上唇下沿
	for s in [-1.0, 1.0]:
		g.sq(s * 4.5, 8.5, 4, 2.0, 2.4, 1.6, c("g3"))               # 耳朵
		_glow(220)
		g.box(int(s * 3.0) - (1 if s < 0 else 0), 3, 12, int(s * 3.0) + (0 if s < 0 else 1), 4, 12, c("eye"))   # 眼睛
		_glow(0)
	_glow(160)
	g.box(-1, 6, 12, 0, 8, 12, c("eye"))                            # 额头的纹
	_glow(0)


## 下巴(转轴 = 颌关节)：张嘴吼的时候往下转
func spirit_lion_jaw() -> void:
	g.sq(0, -1.5, 4, 3.6, 1.6, 4.5, c("g2"))
	_glow(140)
	for s in [-1.0, 1.0]:
		g.box(int(s * 2.0), 0, 7, int(s * 2.0), 1, 7, c("eye"))     # 獠牙
	_glow(0)


## 前腿(转轴 = 肩)：粗壮的前腿 + 大爪子，爪尖发光
func spirit_lion_leg_f() -> void:
	g.sq(0, -2, 0, 3.6, 5.0, 4.0, Callable(self, "fur_fn"))
	g.seg(Vector3(0, -4, 0.5), Vector3(0, -15, 1.5), 3.0, 2.4, Callable(self, "fur_fn"))
	g.sq(0, -16.5, 3, 3.2, 1.8, 4.2, c("g2"))
	_glow(200)
	for i in range(3):
		g.box(-2 + i * 2, -18, 7, -2 + i * 2, -17, 7, c("eye"))
	_glow(0)


## 后腿(转轴 = 髋)：大腿肌肉、往后弯的小腿、爪子
func spirit_lion_leg_b() -> void:
	g.sq(0, -3, -1, 4.0, 6.0, 5.5, Callable(self, "fur_fn"))
	g.seg(Vector3(0, -7, -2), Vector3(0, -12, -4.5), 2.6, 2.0, Callable(self, "fur_fn"))
	g.seg(Vector3(0, -12, -4.5), Vector3(0, -16, -1.5), 2.0, 2.0, Callable(self, "fur_fn"))
	g.sq(0, -17, 0.5, 2.8, 1.6, 3.6, c("g2"))


## 尾巴(转轴 = 尾根)：往后上翘再垂下的长尾，尾尖一撮深色的毛
func spirit_lion_tail() -> void:
	g.seg(Vector3(0, 0, 0), Vector3(0, 3, -7), 1.4, 1.2, Callable(self, "fur_fn"))
	g.seg(Vector3(0, 3, -7), Vector3(0, -1, -14), 1.2, 1.0, Callable(self, "fur_fn"))
	g.sq(0, -2.5, -15.5, 2.2, 2.8, 2.2, Callable(self, "mane_fn"))


# ================================================================ 巨蛛
## 腹部(转轴 = 腹柄)：圆滚滚的大肚子，背上一个发光的沙漏 / 符纹、一圈圈的环纹
func spirit_spider_abdomen() -> void:
	g.sq(0, 4, -12, 11.0, 9.5, 13.0, Callable(self, "abd_fn"))
	_glow(200)
	g.poly("xz", PackedVector2Array([Vector2(-3, -5), Vector2(3, -5), Vector2(0.5, -11), Vector2(3, -17), Vector2(-3, -17), Vector2(-0.5, -11)]), 13, 14, c("eye"))
	_glow(0)
	g.sq(0, 2, -24, 3.0, 3.0, 2.0, c("g4"))                         # 吐丝器


## 头胸(转轴 = 头胸中心)：扁扁的头胸甲，前面一簇发光的眼睛(两大六小)，触肢
func spirit_spider_ceph() -> void:
	g.sq(0, 0, 0, 7.5, 4.5, 8.0, Callable(self, "shell_fn"))
	g.sq(0, 2, 2, 5.0, 2.5, 5.5, c("g4"))
	_glow(230)
	for e: Array in [[-2, 3, 7], [1, 3, 7], [-4, 2, 6], [3, 2, 6], [-1, 5, 6], [0, 5, 6], [-3, 4, 5], [2, 4, 5]]:
		g.box(int(e[0]), int(e[1]), int(e[2]), int(e[0]) + (1 if absi(int(e[0])) <= 2 else 0), int(e[1]), int(e[2]) + 1, c("eye"))
	_glow(0)
	for s in [-1.0, 1.0]:
		g.seg(Vector3(s * 3, -1, 7), Vector3(s * 4.5, -2, 11), 1.2, 0.9, c("g4"))    # 触肢


## 螯牙(转轴 = 牙根)：往下往前弯的尖牙，牙尖发光(滴毒)
func spirit_spider_fang() -> void:
	g.seg(Vector3(0, 0, 0), Vector3(0, -3, 2), 1.5, 1.1, c("g5"))
	g.seg(Vector3(0, -3, 2), Vector3(0, -5.5, 1), 1.1, 0.5, c("g6"))
	_glow(220)
	g.box(0, -6, 1, 0, -6, 1, c("eye"))
	_glow(0)


## 一条腿(转轴 = 根部；沿 +X 伸出去)：先往外往上拱到膝盖，再往外往下戳到地上；关节一圈深色，脚尖发光
func spirit_spider_leg() -> void:
	g.seg(Vector3(0, 0, 0), Vector3(9, 7, 0), 1.6, 1.3, Callable(self, "shell_fn"))
	g.sq(9, 7, 0, 1.8, 1.8, 1.8, c("g6"))
	g.seg(Vector3(9, 7, 0), Vector3(18, -6, 0), 1.3, 0.9, Callable(self, "shell_fn"))
	g.seg(Vector3(18, -6, 0), Vector3(20, -13, 0), 0.9, 0.5, c("g5"))
	_glow(200)
	g.box(20, -14, 0, 20, -14, 0, c("eye"))
	_glow(0)


# ================================================================ 巨蟾
## 身体(转轴 = 身体中心偏下)：又宽又扁的身子、往前的大头(上颌)、鼓起来的眼睛(发光的竖瞳)、背上发光的疣、亮的肚皮
func spirit_toad_body() -> void:
	g.sq(0, 0, -2, 13.0, 8.5, 12.0, Callable(self, "wart_fn"))
	g.sq(0, 2, 8, 12.0, 6.5, 8.0, Callable(self, "wart_fn"))          # 头
	g.sq(0, -5, 1, 11.0, 3.5, 11.0, c("g1"))                        # 肚皮
	g.sq(0, -1.5, 13, 10.5, 1.2, 4.0, c("g5"))                      # 嘴缝
	for s in [-1.0, 1.0]:
		g.sq(s * 6.5, 8.5, 7, 3.6, 3.4, 3.6, c("g2"))               # 眼球
		_glow(230)
		g.box(int(s * 6.5) - (1 if s < 0 else 0), 8, 10, int(s * 6.5) + (0 if s < 0 else 1), 10, 10, c("eye"))   # 竖瞳
		_glow(0)
	_glow(170)
	for i in range(9):
		var wx: float = (_hash(i, 3, 7) - 0.5) * 18.0
		var wz: float = (_hash(i, 5, 1) - 0.5) * 18.0 - 3.0
		g.sq(wx, 8.0 - absf(wx) * 0.15, wz, 1.2, 0.9, 1.2, c("eye"))
	_glow(0)


## 下颌(转轴 = 嘴角)：张嘴吐舌头时往下转
func spirit_toad_jaw() -> void:
	g.sq(0, -1.5, 5, 10.5, 1.8, 6.0, c("g2"))
	g.sq(0, -0.2, 5, 8.0, 0.8, 4.5, c("g5"))                        # 嘴里


## 舌头(转轴 = 舌根；沿 +Z 长 1 米，表现层按距离拉长)：扁平的长舌，舌尖一团发光的黏球
func spirit_toad_tongue() -> void:
	g.box(-2, -1, 0, 1, 0, 17, c("g2"))
	_glow(220)
	g.sq(0, -0.5, 19, 2.6, 2.0, 2.6, c("eye"))
	_glow(0)


## 前腿(转轴 = 肩)：短短的前腿往外撑着，蹼掌摊在地上
func spirit_toad_leg_f() -> void:
	g.seg(Vector3(0, 0, 0), Vector3(2, -7, 2), 2.2, 1.8, Callable(self, "wart_fn"))
	g.poly("xz", PackedVector2Array([Vector2(-1, 1), Vector2(6, 2), Vector2(5, 6), Vector2(2, 7), Vector2(-1, 5)]), -9, -8, c("g3"))


## 后腿(转轴 = 髋)：折起来的粗大后腿(大腿往后、小腿往前叠回来)，大蹼脚
func spirit_toad_leg_b() -> void:
	g.sq(0, -1, -2, 4.5, 4.5, 6.5, Callable(self, "wart_fn"))
	g.seg(Vector3(1, -3, -7), Vector3(3, -6, 3), 2.2, 1.6, Callable(self, "wart_fn"))
	g.poly("xz", PackedVector2Array([Vector2(0, 0), Vector2(8, 1), Vector2(9, 6), Vector2(4, 8), Vector2(0, 5)]), -9, -8, c("g3"))
