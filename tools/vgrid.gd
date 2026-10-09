extends RefCounted
## VGrid — 稠密体素网格。每个体素保存：颜色(打包整数)、所属骨骼、发光强度。
## 坐标约定：体素格子索引 (x,y,z) 覆盖连续空间 [x,x+1)×[y,y+1)×[z,z+1)；
## 角色朝 +Z，左手侧为 +X，脚底 y=0。左右镜像：x -> -1-x。

const SOLID := 0x01000000

# 涂装模式
const FILL := 0        # 覆盖颜色/骨骼/发光
const ADD := 1         # 只填空格子
const PAINT := 2       # 只改已有体素的颜色(和发光)，保留骨骼
const PAINT_SURF := 3  # 同 PAINT 但只处理表面体素
const CLEAR := 4       # 删除
const BONE_ONLY := 5   # 只改骨骼归属

var ox: int
var oy: int
var oz: int
var sx: int
var sy: int
var sz: int
var col: PackedInt32Array
var bn: PackedByteArray
var gl: PackedByteArray

var ids: Dictionary = {}                 # 骨骼名 -> 序号
var mirror_of: PackedInt32Array = PackedInt32Array()
var cur_bone: int = 0
var cur_glow: int = 0
var sym: bool = false
var mode: int = FILL
var oob_count: int = 0
# 局部坐标平移：雕刻时写入 (x+tx, y+ty, z+tz)，用于在"弓坐标系"里雕刻
var tx: int = 0
var ty: int = 0
var tz: int = 0
# 逐体素权重覆盖: 线性索引 -> [[bone, weight], ...]
var wover: Dictionary = {}


func _init(min_c: Vector3i, max_c: Vector3i, p_ids: Dictionary, p_mirror: PackedInt32Array) -> void:
	ox = -min_c.x
	oy = -min_c.y
	oz = -min_c.z
	sx = max_c.x - min_c.x + 1
	sy = max_c.y - min_c.y + 1
	sz = max_c.z - min_c.z + 1
	col = PackedInt32Array()
	col.resize(sx * sy * sz)
	bn = PackedByteArray()
	bn.resize(sx * sy * sz)
	gl = PackedByteArray()
	gl.resize(sx * sy * sz)
	ids = p_ids
	mirror_of = p_mirror


# ---------------------------------------------------------------- 颜色工具
static func pack(c: Color) -> int:
	return SOLID | (int(c.r * 255.0 + 0.5) << 16) | (int(c.g * 255.0 + 0.5) << 8) | int(c.b * 255.0 + 0.5)


static func unpack(v: int) -> Color:
	return Color(float((v >> 16) & 255) / 255.0, float((v >> 8) & 255) / 255.0, float(v & 255) / 255.0)


static func hexc(h: String) -> int:
	return pack(Color(h))


static func mix(a: int, b: int, t: float) -> int:
	var ca := unpack(a)
	var cb := unpack(b)
	return pack(ca.lerp(cb, clampf(t, 0.0, 1.0)))


static func shade(a: int, f: float) -> int:
	var c := unpack(a)
	return pack(Color(clampf(c.r * f, 0.0, 1.0), clampf(c.g * f, 0.0, 1.0), clampf(c.b * f, 0.0, 1.0)))


# ---------------------------------------------------------------- 画笔
func use(bone_name: String, glow: int = 0) -> void:
	assert(ids.has(bone_name), "unknown bone: " + bone_name)
	cur_bone = ids[bone_name]
	cur_glow = glow


func set_mode(m: int) -> void:
	mode = m


func idx(x: int, y: int, z: int) -> int:
	return ((z + tz + oz) * sy + (y + ty + oy)) * sx + (x + tx + ox)


func inb(x: int, y: int, z: int) -> bool:
	var X := x + tx + ox
	var Y := y + ty + oy
	var Z := z + tz + oz
	return X >= 0 and Y >= 0 and Z >= 0 and X < sx and Y < sy and Z < sz


func solid(x: int, y: int, z: int) -> bool:
	var X := x + tx + ox
	var Y := y + ty + oy
	var Z := z + tz + oz
	if X < 0 or Y < 0 or Z < 0 or X >= sx or Y >= sy or Z >= sz:
		return false
	return col[(Z * sy + Y) * sx + X] != 0


func get_col(x: int, y: int, z: int) -> int:
	if not inb(x, y, z):
		return 0
	return col[idx(x, y, z)]


func get_bone(x: int, y: int, z: int) -> int:
	if not inb(x, y, z):
		return 0
	return bn[idx(x, y, z)]


func is_surface(x: int, y: int, z: int) -> bool:
	return not (solid(x + 1, y, z) and solid(x - 1, y, z) and solid(x, y + 1, z) and solid(x, y - 1, z) and solid(x, y, z + 1) and solid(x, y, z - 1))


func _put(x: int, y: int, z: int, c: int, b: int, g: int) -> void:
	var X := x + tx + ox
	var Y := y + ty + oy
	var Z := z + tz + oz
	if X < 0 or Y < 0 or Z < 0 or X >= sx or Y >= sy or Z >= sz:
		oob_count += 1
		return
	var i := (Z * sy + Y) * sx + X
	match mode:
		FILL:
			col[i] = c
			bn[i] = b
			gl[i] = g
		ADD:
			if col[i] == 0:
				col[i] = c
				bn[i] = b
				gl[i] = g
		PAINT:
			if col[i] != 0:
				col[i] = c
				gl[i] = g
		PAINT_SURF:
			if col[i] != 0 and is_surface(x, y, z):
				col[i] = c
				gl[i] = g
		CLEAR:
			col[i] = 0
			bn[i] = 0
			gl[i] = 0
		BONE_ONLY:
			if col[i] != 0:
				bn[i] = b


## 通用写入：c 可以是颜色整数或 Callable(x,y,z)->int(0 = 跳过)
func put(x: int, y: int, z: int, c: Variant) -> void:
	if typeof(c) == TYPE_CALLABLE:
		var fn: Callable = c
		var cc: int = fn.call(x, y, z)
		if cc == 0:
			return
		_put(x, y, z, cc, cur_bone, cur_glow)
		if sym:
			_put(-1 - x, y, z, cc, mirror_of[cur_bone], cur_glow)
	else:
		var ci: int = c
		_put(x, y, z, ci, cur_bone, cur_glow)
		if sym:
			_put(-1 - x, y, z, ci, mirror_of[cur_bone], cur_glow)


# ---------------------------------------------------------------- 基础形体
func box(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, c: Variant = 0) -> void:
	var ax := mini(x0, x1)
	var bx := maxi(x0, x1)
	var ay := mini(y0, y1)
	var by := maxi(y0, y1)
	var az := mini(z0, z1)
	var bz := maxi(z0, z1)
	for z in range(az, bz + 1):
		for y in range(ay, by + 1):
			for x in range(ax, bx + 1):
				put(x, y, z, c)


## 超椭球：n=2 为椭球，n 越大越接近方块。中心/半径为连续坐标。
func sq(cx: float, cy: float, cz: float, rx: float, ry: float, rz: float, c: Variant, n: float = 2.0) -> void:
	var x0 := int(floor(cx - rx))
	var x1 := int(ceil(cx + rx))
	var y0 := int(floor(cy - ry))
	var y1 := int(ceil(cy + ry))
	var z0 := int(floor(cz - rz))
	var z1 := int(ceil(cz + rz))
	for z in range(z0, z1 + 1):
		var dz := absf((z + 0.5 - cz) / rz)
		for y in range(y0, y1 + 1):
			var dy := absf((y + 0.5 - cy) / ry)
			for x in range(x0, x1 + 1):
				var dx := absf((x + 0.5 - cx) / rx)
				var v: float
				if n == 2.0:
					v = dx * dx + dy * dy + dz * dz
				else:
					v = pow(dx, n) + pow(dy, n) + pow(dz, n)
				if v <= 1.0:
					put(x, y, z, c)


## 沿 Y 的锥形/柱形（截面为超椭圆），y0..y1 含端点(格子)。
func ytaper(y0: int, y1: int, cx0: float, cz0: float, rx0: float, rz0: float, cx1: float, cz1: float, rx1: float, rz1: float, c: Variant, n: float = 2.0) -> void:
	var span := float(y1 - y0 + 1)
	for y in range(y0, y1 + 1):
		var t := (y - y0 + 0.5) / span
		var cx := lerpf(cx0, cx1, t)
		var cz := lerpf(cz0, cz1, t)
		var rx := lerpf(rx0, rx1, t)
		var rz := lerpf(rz0, rz1, t)
		if rx <= 0.0 or rz <= 0.0:
			continue
		for z in range(int(floor(cz - rz)), int(ceil(cz + rz)) + 1):
			var dz := absf((z + 0.5 - cz) / rz)
			for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
				var dx := absf((x + 0.5 - cx) / rx)
				var v: float
				if n == 2.0:
					v = dx * dx + dz * dz
				else:
					v = pow(dx, n) + pow(dz, n)
				if v <= 1.0:
					put(x, y, z, c)


## 粗线段（胶囊）。square=true 时使用切比雪夫距离(方形截面)。
func seg(p0: Vector3, p1: Vector3, r0: float, r1: float, c: Variant, square: bool = false) -> void:
	var rm := maxf(r0, r1) + 0.5
	var lo := Vector3(minf(p0.x, p1.x) - rm, minf(p0.y, p1.y) - rm, minf(p0.z, p1.z) - rm)
	var hi := Vector3(maxf(p0.x, p1.x) + rm, maxf(p0.y, p1.y) + rm, maxf(p0.z, p1.z) + rm)
	var d := p1 - p0
	var dd := d.dot(d)
	for z in range(int(floor(lo.z)), int(ceil(hi.z)) + 1):
		for y in range(int(floor(lo.y)), int(ceil(hi.y)) + 1):
			for x in range(int(floor(lo.x)), int(ceil(hi.x)) + 1):
				var q := Vector3(x + 0.5, y + 0.5, z + 0.5)
				var t := 0.0
				if dd > 0.0001:
					t = clampf((q - p0).dot(d) / dd, 0.0, 1.0)
				var cl := p0 + d * t
				var r := lerpf(r0, r1, t)
				var off := q - cl
				var dist: float
				if square:
					dist = maxf(absf(off.x), maxf(absf(off.y), absf(off.z)))
				else:
					dist = off.length()
				if dist <= r:
					put(x, y, z, c)


## 多边形挤出。plane: "xy"(沿z挤出, pts=(x,y)) / "zy"(沿x挤出, pts=(z,y)) / "xz"(沿y挤出, pts=(x,z))
func poly(plane: String, pts: PackedVector2Array, a0: int, a1: int, c: Variant) -> void:
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for p in pts:
		lo.x = minf(lo.x, p.x)
		lo.y = minf(lo.y, p.y)
		hi.x = maxf(hi.x, p.x)
		hi.y = maxf(hi.y, p.y)
	var amin := mini(a0, a1)
	var amax := maxi(a0, a1)
	for v in range(int(floor(lo.y)), int(ceil(hi.y)) + 1):
		for u in range(int(floor(lo.x)), int(ceil(hi.x)) + 1):
			if not Geometry2D.is_point_in_polygon(Vector2(u + 0.5, v + 0.5), pts):
				continue
			for a in range(amin, amax + 1):
				match plane:
					"xy":
						put(u, v, a, c)
					"zy":
						put(a, v, u, c)
					"xz":
						put(u, a, v, c)


## 环/圆环体：中心 center，法线 normal，半径 radius，管径 thick(直径)。
func ring(center: Vector3, normal: Vector3, radius: float, thick: float, c: Variant) -> void:
	var n := normal.normalized()
	var rm := radius + thick
	for z in range(int(floor(center.z - rm)), int(ceil(center.z + rm)) + 1):
		for y in range(int(floor(center.y - rm)), int(ceil(center.y + rm)) + 1):
			for x in range(int(floor(center.x - rm)), int(ceil(center.x + rm)) + 1):
				var q := Vector3(x + 0.5, y + 0.5, z + 0.5) - center
				var h := q.dot(n)
				var rr := (q - n * h).length()
				var dist := sqrt((rr - radius) * (rr - radius) + h * h)
				if dist <= thick * 0.5:
					put(x, y, z, c)


## 在区域内对每个体素调用 fn(x,y,z)->颜色/0，配合 PAINT 等模式做贴花
func each(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, fn: Callable) -> void:
	for z in range(mini(z0, z1), maxi(z0, z1) + 1):
		for y in range(mini(y0, y1), maxi(y0, y1) + 1):
			for x in range(mini(x0, x1), maxi(x0, x1) + 1):
				var cc: int = fn.call(x, y, z)
				if cc != 0:
					put(x, y, z, cc)


func count_solid() -> int:
	var n := 0
	for v in col:
		if v != 0:
			n += 1
	return n


## 贴花：沿 axis(0=x,1=y,2=z) 的方向 dir(+1/-1) 从外向内找每个 (u,v) 上最外层的实体体素，改色。
## fn(u,v) -> 颜色(0=跳过)。u,v 对应: axis=2 -> (x,y); axis=0 -> (z,y); axis=1 -> (x,z)
## depth: 连续涂几层。glow 使用画笔当前发光值。
func decal(axis: int, dir: int, u0: int, v0: int, u1: int, v1: int, fn: Callable, depth: int = 1, bone_too: bool = false) -> void:
	for v in range(mini(v0, v1), maxi(v0, v1) + 1):
		for u in range(mini(u0, u1), maxi(u0, u1) + 1):
			var cc: int = fn.call(u, v)
			if cc == 0:
				continue
			# 找最外层
			var found := false
			var lo := 0
			var hi := 0
			match axis:
				2:
					lo = -oz - tz
					hi = sz - 1 - oz - tz
				0:
					lo = -ox - tx
					hi = sx - 1 - ox - tx
				_:
					lo = -oy - ty
					hi = sy - 1 - oy - ty
			var a := hi if dir > 0 else lo
			var stepv := -dir
			var n := 0
			while a >= lo and a <= hi:
				var x: int
				var y: int
				var z: int
				match axis:
					2:
						x = u
						y = v
						z = a
					0:
						x = a
						y = v
						z = u
					_:
						x = u
						y = a
						z = v
				if solid(x, y, z):
					_decal_cell(x, y, z, cc, bone_too)
					n += 1
					if n >= depth:
						found = true
						break
				a += stepv
			if found and sym:
				pass


func _decal_cell(x: int, y: int, z: int, c: int, bone_too: bool) -> void:
	var i := idx(x, y, z)
	col[i] = c
	gl[i] = cur_glow
	if bone_too:
		bn[i] = cur_bone
	if sym:
		var mx := -1 - x
		if inb(mx, y, z) and mx != x:
			var j := idx(mx, y, z)
			if col[j] != 0:
				col[j] = c
				gl[j] = cur_glow
				if bone_too:
					bn[j] = mirror_of[cur_bone]


## 把另一个网格整体复制进来(偏移 dx,dy,dz)
func blit(o, dx: int, dy: int, dz: int) -> void:
	for Z in range(o.sz):
		for Y in range(o.sy):
			for X in range(o.sx):
				var i: int = (Z * o.sy + Y) * o.sx + X
				if o.col[i] == 0:
					continue
				var x: int = X - o.ox + dx
				var y: int = Y - o.oy + dy
				var z: int = Z - o.oz + dz
				var save_sym := sym
				var save_mode := mode
				sym = false
				mode = FILL
				_put(x, y, z, o.col[i], o.bn[i], o.gl[i])
				sym = save_sym
				mode = save_mode


## 逐体素权重覆盖(局部坐标)。arr: [[bone_index, weight], ...]
func set_weights(x: int, y: int, z: int, arr: Array) -> void:
	if inb(x, y, z):
		wover[idx(x, y, z)] = arr
