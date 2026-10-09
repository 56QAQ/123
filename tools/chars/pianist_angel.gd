extends "res://tools/chars/_sculpt.gd"
## Pianist · 天使形态(变奏节点的白键形态，2026-10-08)：和 pianist.gd(恶魔形态)是同一个人 —— 身体、头、脸、青色波波头、精灵耳、
## 礼服的剪裁全部照搬 pianist.gd 的构造(内部类 _Angelic 继承它再 build)，只换"属性"：
##   · 头顶两只角 → 头顶上方一圈悬浮的金色光环(挂 Halo 骨：待机时跟着上下浮、轻轻晃)
##   · 酒红蝙蝠翼 → 一对白色羽翼(挂 Wing_L/R；三排羽毛一排压一排，羽根白、羽尖淡天蓝；比白羽节点的大羽翼小一号，和蝙蝠翼差不多大)
##   · 黑红金礼服 → 白、金、淡天蓝(结构不变，配色整体换表：黑 → 白，酒红 → 淡天蓝，红宝石 → 蓝宝石，深棕长袜 → 白色长袜；金色不变)
##   · 桃心尾巴去掉
## 钩子：pianist.gd 的 build() 依次调用 _tail / bat_wing / _horns 画尾巴、翅膀、角 —— 内部类把这三个换掉(尾巴不画、翅膀改羽翼、角改光环)，
## build 完再把整个网格按 SWAP 表换色(只换礼服用到的那几种颜色；皮肤、头发、眼睛、金色都不在表里)。
const Pianist = preload("res://tools/chars/pianist.gd")
const HAIR := Pianist.HAIR          # build_kits 只读本文件自己声明的常量(发色类别 / 原发色)，所以这里再声明一次

## 恶魔形态的礼服颜色 → 天使形态
const SWAP := {
	"#24202a": "#e6e0d6",       # 黑(礼服主色) → 象牙白(比羽翼暖一点，两者分得开)
	"#342e3a": "#cdc5b9",       # 黑(背面 / 侧面) → 象牙白(暗)
	"#18141c": "#aba395",       # 鞋底
	"#7a1e2a": "#6ea4d4",       # 酒红 → 淡天蓝
	"#5c1620": "#5284ba",       # 酒红(深) → 天蓝(深)
	"#9a2a36": "#92c0e6",       # 酒红(亮) → 天蓝(亮)
	"#c81e2a": "#3f7fcf",       # 红宝石 → 蓝宝石
	"#ff7a6a": "#a8dcff",       # 红宝石高光 → 蓝宝石高光
	"#3e2c2a": "#c2cfe4",       # 深棕长袜 → 淡蓝白长袜
	"#4e3a36": "#dbe3f0",       # 袜口
}


func build() -> void:
	_Angelic.new(g, rig).build()


## 恶魔形态的构造 + 换掉角 / 翅膀 / 尾巴 + 换色
class _Angelic extends Pianist:
	func build() -> void:
		super.build()
		_swap_colors()

	func _swap_colors() -> void:
		var m := {}
		for k: String in SWAP.keys():
			m[H(k)] = H(str(SWAP[k]))
		for i in range(g.col.size()):
			var c: int = g.col[i]
			if c != 0 and m.has(c):
				g.col[i] = m[c]

	## 尾巴：天使形态没有
	func _tail(_blk: int, _blk2: int, _wr: int, _wr3: int) -> void:
		pass

	## 角 → 头顶上方悬浮的金色光环(水平的一圈，前沿略低：从前面和斜上方都能看到环面)
	func _horns(_blk: int, _blk2: int, _wr: int, _wr3: int) -> void:
		var au := H("#d9a648")
		var au2 := H("#f4d27e")
		var au3 := H("#a8762e")
		var c := Vector3(0.0, 106.5, -2.0)
		var n := Vector3(0.0, 1.0, 0.18).normalized()
		g.sym = false
		g.use("Halo")
		var sm: int = g.mode
		g.set_mode(VGrid.ADD)
		var col := func(x: int, y: int, z: int) -> int:
			var q := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - c
			var h: float = q.dot(n)
			var rr: float = (q - n * h).length()
			if h > 0.25:
				g.cur_glow = 55
				return au2
			g.cur_glow = 25
			return au3 if (h < -0.6 and rr > 7.6) else au
		g.ring(c, n, 7.6, 2.1, col)
		g.cur_glow = 0
		g.set_mode(sm)

	## 酒红蝙蝠翼 → 白色羽翼(参数不用：位置按蝙蝠翼的翼根，翼展略大一点)
	func bat_wing(_root: Vector3, _yaw: float, _arm: Array, _fingers: Array, _bone_c: int, _mem_c: int, _mem2: int, _scallop: float = 2.6) -> void:
		_feather_wings()

	## 翼面坐标：u = 沿翼展往外(斜往后 26°)，v = 往上(0 = 翼根，肩胛骨高度)。前缘从翼根升到翼顶(驼峰)，再往外下折成外缘；
	## 羽毛一排排往下垂、略向外斜，下面的排先画、上面的排往背后错一格盖在上面 → 每排羽尖一道锯齿台阶(同白羽节点的做法，小一号)
	const LE := [Vector2(0.0, 1.0), Vector2(2.2, 6.5), Vector2(5.0, 11.0), Vector2(8.2, 14.0), Vector2(11.8, 15.0), Vector2(15.0, 13.6),
		Vector2(17.4, 10.4), Vector2(18.8, 5.8), Vector2(19.6, 0.5)]

	static func _pw(u: float) -> float:
		if u <= float((LE[0] as Vector2).x):
			return float((LE[0] as Vector2).y)
		for i in range(LE.size() - 1):
			var p: Vector2 = LE[i]
			var q: Vector2 = LE[i + 1]
			if u <= q.x:
				return lerpf(p.y, q.y, (u - p.x) / (q.x - p.x))
		return float((LE[LE.size() - 1] as Vector2).y)

	## 下缘(羽尖连成的线)：内侧短、外侧长
	static func _wbot(u: float) -> float:
		return lerpf(-3.0, -11.5, clampf(u / 19.6, 0.0, 1.0))

	func _feather_wings() -> void:
		var f0 := H("#f1efed")
		var f1 := H("#d2e0f1")
		var f2 := H("#a4c2e6")
		var root := Vector3(4.5, 62.5, -7.5)
		var a: float = deg_to_rad(26.0)
		var U := Vector3(cos(a), 0.0, -sin(a))
		var D := Vector3(-sin(a), 0.0, -cos(a))       # 朝背后
		var wid: int = rig.ids["Wing_L"]
		var bonef := func(_x: int, _y: int, _z: int) -> int: return wid
		var wp := func(u: float, v: float, lay: float) -> Vector3: return root + U * u + Vector3(0.0, v, 0.0) + D * lay
		var outf := func(_p: Vector3) -> Vector3: return D
		var sm: int = g.mode
		g.set_mode(VGrid.ADD)
		g.sym = false
		var NT := 4
		for tier in range(NT - 1, -1, -1):
			var lay: float = float(NT - 1 - tier)
			var u: float = 0.5 + float(tier % 2) * 1.5
			var k := 0
			while u < 20.0:
				var le: float = _pw(u)
				var v0: float = le - float(tier) * 5.0
				var bot: float = _wbot(u)
				if v0 < bot + 2.5:
					u += 3.0
					continue
				var ln: float = 7.0 + (1.5 if k % 2 == 0 else 0.0)
				var last: bool = tier == NT - 1
				if last:
					ln = minf(v0 - bot + (1.2 if k % 2 == 0 else 0.0), 12.0)
				ln = minf(ln, v0 - bot + 1.2)
				var slant: float = 0.3 + u * 0.06 + (1.1 if last else 0.0)
				var w: float = 2.0
				var fcol := func(t: float, aa: float, _d: float) -> int:
					if t > 0.88:
						return f2
					if t > 0.72:
						return f1
					if last and t > 0.45 and absf(aa) > 0.55:
						return f1
					return f0
				var pf := func(t: float) -> Vector2:
					var ww: float = w
					if t > 0.8:
						ww = lerpf(w, 0.8, (t - 0.8) / 0.2)
					return Vector2(ww, 1.5)
				var pts := [wp.call(u, v0 + 1.0, lay), wp.call(u + slant * 0.5, v0 - ln * 0.5, lay), wp.call(u + slant, v0 - ln, lay)]
				sweep2(pts, pf, outf, fcol, bonef)
				u += 3.0
				k += 1
		# 翼臂前缘：白色圆棱压在最上面，靠里一段描一道细金边(和礼服的金边呼应)
		var ridge: Array = []
		for i in range(LE.size() - 1):
			var q: Vector2 = LE[i]
			ridge.append(wp.call(q.x, q.y + 0.5, 3.6))
		var rpf := func(t: float) -> Vector2: return Vector2(lerpf(1.7, 1.2, t), 2.0)
		var au := H("#d9a648")
		var rcol := func(t: float, aa: float, d: float) -> int:
			if t < 0.55 and aa > 0.45 and d < 0.5:
				return au
			return f0 if d < 0.5 else f1
		sweep2(ridge, rpf, outf, rcol, bonef)
		g.set_mode(sm)
