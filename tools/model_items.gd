extends "res://tools/model_world.gd"
## 车间材料的体素模型(用来渲染高辨识度的像素图标，游戏启动时由 Portraits 离屏渲染)：
##   燃素(内部名 red)：一团火——圆滚滚的火底 + 往上窜的三条火舌，外红内黄、芯子发白，几粒火星
##   有机物(内部名 green)：一粒发芽的种子——棕色的豆子裂开一道口，冒出弯弯的嫩茎和两片子叶，底下一截白根
##   液态负熵(内部名 blue)：一瓶矿泉水——带瓶肩和横纹的塑料瓶、蓝色瓶盖、白色标签上一道蓝条，瓶里是发光的蓝色液体
## 体素 1.25 cm(和角色一样，build_world.gd 的缩放 1)；原点 = 底面中心。剪影要粗壮、配色要饱和：缩到 26 px 也认得出来。

const ITEM := {
	# 燃素
	"f0": "#9c1a12", "f1": "#e0361a", "f2": "#ff6a1c", "f3": "#ffa52a", "f4": "#ffd85a", "f5": "#fff6cc",
	# 有机物
	"s0": "#5a3519", "s1": "#7c4c26", "s2": "#9c6634", "s3": "#c08a4e", "s4": "#e2c08a",
	"g0": "#2f7a2c", "g1": "#4aa63a", "g2": "#78cf4e", "g3": "#b4ec7a", "root": "#efe4c8", "root2": "#d2c2a0",
	# 液态负熵
	"w0": "#1648a8", "w1": "#1f6fe0", "w2": "#3a9cff", "w3": "#9ad6ff", "w4": "#d8f0ff", "w5": "#ffffff",
	"cap": "#1d4fae", "cap2": "#2f6fd8", "lab": "#f2f6fa", "lab2": "#d8e2ec", "labb": "#2468d8",
}


func _init(grid) -> void:
	super(grid)
	for k: String in ITEM.keys():
		P[k] = VGrid.hexc(ITEM[k])


# ---------------------------------------------------------------- 燃素：一团火
func mat_red() -> void:
	# 主火舌：底下是个圆球(半径 10)，往上收成尖；两条副火舌从两侧斜着窜出来。中心线左右摆一下(S 形)。
	# 颜色按"离火舌中心线的水平距离"算(正面看过去：中间黄白、往外橙、边上深红)，越往上越红
	var tongues := [[0.0, 36.0, 8.6, 0.0], [-12.5, 28.0, 5.4, 7.0], [12.0, 30.0, 5.8, 8.0]]   # [顶端 x 偏移, 顶高, 根部半径, 根部高度]
	for y in range(0, 38):
		for z in range(-13, 14):
			for x in range(-17, 18):
				var fy: float = float(y) + 0.5
				var best3 := 99.0
				var best_h := 99.0
				for tg: Array in tongues:
					var top: float = float(tg[1])
					var base_y: float = float(tg[3])
					var r0: float = float(tg[2])
					if fy > top:
						continue
					var t: float = clampf((fy - base_y) / (top - base_y), 0.0, 1.0)
					var cx: float = float(tg[0]) * pow(t, 1.3) + sin(fy * 0.3 + float(tg[0]) * 0.4) * 1.3 * t
					var r: float
					if tg[3] == 0.0 and fy < 10.0:
						r = sqrt(maxf(0.0, 100.0 - pow(10.0 - fy, 2.0)))
					elif tg[3] == 0.0:
						r = lerpf(10.0, r0, clampf((fy - 10.0) / 4.0, 0.0, 1.0)) * pow(1.0 - clampf((fy - 10.0) / (top - 10.0), 0.0, 1.0), 0.7)
					else:
						if fy < base_y:
							continue
						r = r0 * pow(1.0 - t, 0.85) * clampf((fy - base_y + 2.0) / 3.0, 0.0, 1.0)
					if r <= 0.4:
						continue
					var dx: float = float(x) + 0.5 - cx
					var dz: float = float(z) + 0.5
					var d3: float = Vector2(dx, dz).length() / r
					if d3 < best3:
						best3 = d3
						best_h = absf(dx) / r
				if best3 > 1.0:
					continue
				var hot: float = (1.0 - best_h) * 1.2 - clampf((float(y) - 12.0) / 24.0, 0.0, 1.0) * 0.6 - clampf((2.0 - float(y)) / 2.0, 0.0, 1.0) * 0.3
				var k: String = "f0"
				if hot > 0.9:
					k = "f5"
				elif hot > 0.66:
					k = "f4"
				elif hot > 0.42:
					k = "f3"
				elif hot > 0.24:
					k = "f2"
				elif hot > 0.06:
					k = "f1"
				g.cur_glow = 255 if k == "f5" or k == "f4" else (190 if k == "f3" else (140 if k == "f2" else 90))
				g.put(x, y, z, c(k))
	# 火星
	for sp: Vector3i in [Vector3i(-14, 33, 2), Vector3i(13, 35, -1), Vector3i(-4, 39, 0)]:
		g.cur_glow = 220
		g.box(sp.x, sp.y, sp.z, sp.x + 1, sp.y + 1, sp.z + 1, c("f4"))
	g.cur_glow = 0


# ---------------------------------------------------------------- 有机物：发芽的种子
func mat_green() -> void:
	# 种子：斜躺的豆子(椭球)，背上一道浅色的种脐线
	var cen := Vector3(0.0, 11.0, 0.0)
	var ax := Vector3(cos(0.35), sin(0.35), 0.0)          # 长轴微微翘起
	for y in range(2, 22):
		for z in range(-9, 10):
			for x in range(-14, 15):
				var p := Vector3(float(x) + 0.5, float(y) + 0.5, float(z) + 0.5) - cen
				var a: float = p.dot(ax)
				var rest: Vector3 = p - ax * a
				var v: float = pow(a / 12.0, 2.0) + pow(rest.y / 8.0, 2.0) + pow(rest.z / 7.5, 2.0)
				if v > 1.0:
					continue
				var shade: String = "s2"
				if rest.y < -3.5:
					shade = "s1"
				elif rest.y > 3.0 and absf(rest.z) < 2.6:
					shade = "s3"
				if v > 0.8 and rest.y < 0.0:
					shade = "s0"
				# 种脐线：沿长轴的一道浅色细线
				if absf(rest.z) < 0.8 and rest.y > 5.5 and absf(a) < 8.0:
					shade = "s4"
				g.put(x, y, z, c(shade))
	# 顶上裂开一道口(嫩芽从这里出来)
	var sm: int = g.mode
	g.mode = VGrid.CLEAR
	g.sq(1.5, 18.5, 0.0, 3.0, 2.2, 2.6, 0, 2.0)
	g.mode = sm
	# 嫩茎：从裂口往上，先往右弯再回来
	var pts: Array = [Vector3(1.5, 16.0, 0.0), Vector3(3.0, 21.0, 0.0), Vector3(3.5, 25.0, 0.0), Vector3(1.5, 29.0, 0.0), Vector3(0.0, 31.0, 0.0)]
	for i in range(pts.size() - 1):
		g.seg(pts[i], pts[i + 1], 1.9 - 0.15 * float(i), 1.9 - 0.15 * float(i + 1), c("g1"))
	# 两片子叶：圆圆的、翘起来
	for side: float in [-1.0, 1.0]:
		var lc := Vector3(side * 6.5, 33.0 + (1.0 if side > 0 else 0.0), 0.0)
		for y2 in range(27, 40):
			for z2 in range(-6, 7):
				for x2 in range(-14, 15):
					var q := Vector3(float(x2) + 0.5, float(y2) + 0.5, float(z2) + 0.5) - lc
					# 叶子绕 z 轴朝外翘 30°
					var ang: float = -side * 0.5
					var qx: float = q.x * cos(ang) - q.y * sin(ang)
					var qy: float = q.x * sin(ang) + q.y * cos(ang)
					var lv: float = pow(qx / 6.2, 2.0) + pow(qy / 2.4, 2.0) + pow(q.z / 4.6, 2.0)
					if lv > 1.0:
						continue
					var k: String = "g2"
					if qy > 0.9:
						k = "g3"
					elif qy < -1.0:
						k = "g0"
					if absf(q.z) < 0.6 and qy > 0.0:
						k = "g1"                          # 叶脉
					g.put(x2, y2, z2, c(k))
	# 白根：从豆子底下伸出来，打个弯
	var rp: Array = [Vector3(-7.0, 6.0, 0.0), Vector3(-9.5, 2.5, 0.5), Vector3(-8.0, 0.5, 1.0), Vector3(-5.0, 0.5, 1.0)]
	for j in range(rp.size() - 1):
		g.seg(rp[j], rp[j + 1], 1.2, 0.9, c("root") if j % 2 == 0 else c("root2"))


# ---------------------------------------------------------------- 液态负熵：一瓶矿泉水
func mat_blue() -> void:
	var r_body := 7.5
	for y in range(0, 40):
		var fy: float = float(y) + 0.5
		var r: float = r_body
		if fy < 1.5:
			r = r_body - 1.0                    # 瓶底收一点
		elif fy > 27.0 and fy <= 32.0:
			r = lerpf(r_body, 3.4, smoothstep(27.0, 32.0, fy))     # 瓶肩
		elif fy > 32.0:
			r = 3.4
		# 下半截的横纹：每 4 格往里收 1 格
		var ridge: bool = fy > 3.0 and fy < 12.0 and y % 4 == 0
		if ridge:
			r -= 0.9
		var is_cap: bool = fy > 34.0
		if is_cap:
			r = 4.0
		if fy > 39.0:
			continue
		for z in range(-9, 10):
			for x in range(-9, 10):
				var d: float = Vector2(float(x) + 0.5, float(z) + 0.5).length()
				if d > r:
					continue
				var k: String
				if is_cap:
					# 瓶盖：竖条防滑纹
					var a: float = atan2(float(z) + 0.5, float(x) + 0.5)
					k = "cap2" if int(floor(a * 8.0 / PI)) % 2 == 0 or fy > 38.0 else "cap"
					g.cur_glow = 0
				elif fy > 14.0 and fy < 22.0:
					# 标签：白底 + 中间一道蓝条
					k = "labb" if fy > 16.5 and fy < 19.5 else ("lab" if (int(fy) + int(x)) % 7 != 0 else "lab2")
					g.cur_glow = 0
				else:
					# 瓶身 = 发光的蓝色液体(上面留一截空气)，边缘浅、中间深
					# 只看得到表面：按绕瓶子的方位角上色(右后方暗、正面亮)，像光透过装满液体的瓶子
					var air: bool = fy > 29.0
					var ang: float = atan2(float(x) + 0.5, float(z) + 0.5)       # 0 = 正前方，+ = 右侧
					if air:
						k = "w4" if ang < 0.6 else "w3"
						g.cur_glow = 0
					else:
						k = "w2" if ang < 0.4 and ang > -1.6 else ("w1" if ang < 1.6 else "w0")
						if ridge:
							k = "w0" if k != "w2" else "w1"
						g.cur_glow = 150 if k == "w2" else 110
						# 液体里飘着几颗发亮的负熵粒子
						if _hash(x, y, z) > 0.94 and not ridge:
							k = "w5"
							g.cur_glow = 255
				g.put(x, y, z, c(k))
	g.cur_glow = 0
	# 竖着的高光条(瓶身左前方)
	for y2 in range(2, 30):
		if y2 > 13 and y2 < 23:
			continue
		var hx: float = -0.62 * r_body
		var hz: float = 0.78 * r_body
		var yy: float = float(y2) + 0.5
		var rr: float = r_body if yy <= 27.0 else lerpf(r_body, 3.4, smoothstep(27.0, 32.0, yy))
		var sx: int = int(floor(hx * rr / r_body))
		var szz: int = int(floor(hz * rr / r_body))
		if g.solid(sx, y2, szz):
			g.cur_glow = 160
			g.put(sx, y2, szz, c("w5"))
	g.cur_glow = 0
