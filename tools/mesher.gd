extends RefCounted
## 体素网格器：VGrid + Rig -> 带蒙皮的 ArrayMesh
## - 只输出可见面；不同骨骼之间的接触面也输出(封盖)，这样关节弯曲时不会露出空洞
## - 顶点色 = 体素颜色 × 体素 AO × 微弱随机抖动；alpha = 发光强度
## - 逐体素蒙皮权重：默认 100% 属于所属骨骼，落在软权重区内则与相邻骨骼线性混合

const VOX := 0.0125
const AO_TABLE := [0.66, 0.80, 0.90, 1.0]

# 面表: n, u, v 满足 u × v = n
const FACES := [
	[Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 0, 1)],
	[Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 1, 0)],
	[Vector3i(0, 1, 0), Vector3i(0, 0, 1), Vector3i(1, 0, 0)],
	[Vector3i(0, -1, 0), Vector3i(1, 0, 0), Vector3i(0, 0, 1)],
	[Vector3i(0, 0, 1), Vector3i(1, 0, 0), Vector3i(0, 1, 0)],
	[Vector3i(0, 0, -1), Vector3i(0, 1, 0), Vector3i(1, 0, 0)],
]

var g
var rig
var zones_by_bone: Array = []
var grp: PackedByteArray = PackedByteArray()
var noise_amp: float = 0.022
var ao_enabled: bool = true
var skinned: bool = true
var _vcache: Dictionary = {}               # 顶点权重缓存 (位置, 骨) -> [bones, weights]
var color_class: Dictionary = {}          # 打包颜色整数 -> 材质类别(0中性 1强调色 2发梢 3发色)，供阵营换色着色器使用
var no_ao_bone: PackedByteArray = PackedByteArray()   # 这些骨骼的面不烘焙 AO(如藏在头里的眼睑板)
var stats := {"cells": 0, "quads": 0}


func _init(p_grid, p_rig) -> void:
	g = p_grid
	rig = p_rig


func _prepare() -> void:
	zones_by_bone.clear()
	for i in range(rig.names.size()):
		zones_by_bone.append([])
	for zn in rig.zones:
		zones_by_bone[zn["a"]].append(zn)
		zones_by_bone[zn["b"]].append(zn)
	no_ao_bone = PackedByteArray()
	for i in range(rig.names.size()):
		no_ao_bone.append(1 if String(rig.names[i]).begins_with("Eyelid") else 0)
	var gcache := PackedByteArray()
	for i in range(rig.names.size()):
		gcache.append(rig.ao_group(i))
	grp = PackedByteArray()
	grp.resize(g.col.size())
	for i in range(g.col.size()):
		if g.col[i] != 0:
			grp[i] = gcache[g.bn[i]]


func _grp_at(x: int, y: int, z: int) -> int:
	var X: int = x + g.ox
	var Y: int = y + g.oy
	var Z: int = z + g.oz
	if X < 0 or Y < 0 or Z < 0 or X >= g.sx or Y >= g.sy or Z >= g.sz:
		return 0
	return grp[(Z * g.sy + Y) * g.sx + X]


static func _hash01(x: int, y: int, z: int) -> float:
	var h: int = (x * 73856093) ^ (y * 19349663) ^ (z * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(h & 1023) / 1023.0


## 返回 [bones(4 ints), weights(4 floats)]：按体素中心算
func cell_weights(x: int, y: int, z: int, b: int) -> Array:
	return weights_at(Vector3(x + 0.5, y + 0.5, z + 0.5), b)


## 按顶点位置算权重(带缓存)：相邻体素共用的角点得到同一组权重，关节弯曲时网格不会裂开一道道缝
func vertex_weights(px: int, py: int, pz: int, b: int) -> Array:
	var key: int = ((((px + 128) * 512 + (py + 128)) * 512 + (pz + 128)) * 256) + b
	var hit: Variant = _vcache.get(key)
	if hit != null:
		return hit
	var r: Array = weights_at(Vector3(px, py, pz), b)
	_vcache[key] = r
	return r


## 位置 q(体素坐标)处、属于骨 b 的点的蒙皮权重
func weights_at(q: Vector3, b: int) -> Array:
	var zs: Array = zones_by_bone[b]
	if zs.is_empty():
		return [[b, 0, 0, 0], [1.0, 0.0, 0.0, 0.0]]
	var w := {b: 1.0}
	for zn in zs:
		var p: Vector3 = q - zn["c"]
		var n: Vector3 = zn["n"]
		var s: float = p.dot(n)
		var h: float = zn["h"]
		if absf(s) >= h:
			continue
		var cx: int = zn["clipx"]
		if cx == 1 and q.x < 0.0:
			continue
		if cx == -1 and q.x >= 0.0:
			continue
		var rmax: float = zn["r"]
		if rmax < 1e8:
			var rad := (p - n * s).length()
			if rad > rmax:
				continue
		var f := clampf(0.5 + s / (2.0 * h), 0.0, 1.0)
		var other: int
		var w_other: float
		if zn["a"] == b:
			other = zn["b"]
			w_other = f
		else:
			other = zn["a"]
			w_other = 1.0 - f
		var cur: float = w[b]
		var move := cur * w_other
		w[b] = cur - move
		w[other] = float(w.get(other, 0.0)) + move
	# 取权重最大的 4 个
	var keys: Array = w.keys()
	keys.sort_custom(func(a, c): return w[a] > w[c])
	var bones := [0, 0, 0, 0]
	var wts := [0.0, 0.0, 0.0, 0.0]
	var total := 0.0
	for i in range(mini(4, keys.size())):
		bones[i] = keys[i]
		wts[i] = w[keys[i]]
		total += wts[i]
	if total <= 0.0:
		return [[b, 0, 0, 0], [1.0, 0.0, 0.0, 0.0]]
	for i in range(4):
		wts[i] = wts[i] / total
	return [bones, wts]


func _pack_over(arr: Array) -> Array:
	var bones := [0, 0, 0, 0]
	var wts := [0.0, 0.0, 0.0, 0.0]
	var total := 0.0
	for i in range(mini(4, arr.size())):
		bones[i] = arr[i][0]
		wts[i] = arr[i][1]
		total += wts[i]
	for i in range(4):
		wts[i] = wts[i] / total
	return [bones, wts]


func build() -> ArrayMesh:
	_prepare()
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	var bone_arr := PackedInt32Array()
	var wt_arr := PackedFloat32Array()
	var idx := PackedInt32Array()

	var sx: int = g.sx
	var sy: int = g.sy
	var sz: int = g.sz
	var quads := 0
	var cells := 0
	for Z in range(sz):
		for Y in range(sy):
			var row := (Z * sy + Y) * sx
			for X in range(sx):
				var i := row + X
				var cv: int = g.col[i]
				if cv == 0:
					continue
				var x: int = X - g.ox
				var y: int = Y - g.oy
				var z: int = Z - g.oz
				var b: int = g.bn[i]
				# 先判断哪些面可见
				var vis: Array = []
				for fi in range(6):
					var n: Vector3i = FACES[fi][0]
					var nx := x + n.x
					var ny := y + n.y
					var nz := z + n.z
					if not g.inb(nx, ny, nz):
						vis.append(fi)
						continue
					var ni: int = g.idx(nx, ny, nz)
					if g.col[ni] == 0:
						vis.append(fi)
					elif g.bn[ni] != b:
						vis.append(fi)
				if vis.is_empty():
					continue
				cells += 1
				var cw: Array = cell_weights(x, y, z, b)
				var over: bool = g.wover.has(i)
				if over:
					cw = _pack_over(g.wover[i])
				var cb: Array = cw[0]
				var cwt: Array = cw[1]
				var base: Color = g.unpack(cv)
				var nz01 := _hash01(x, y, z)
				var bright := 1.0 + (nz01 - 0.5) * noise_amp * 2.0
				var alpha := minf(float(g.gl[i]), 255.0) / 255.0
				var cls: float = float(color_class.get(cv, 0))
				var vh: float = _hash01(x + 91, y + 17, z + 53)
				var my_grp: int = grp[i]
				for fi in vis:
					var fn: Vector3i = FACES[fi][0]
					var fu: Vector3i = FACES[fi][1]
					var fv: Vector3i = FACES[fi][2]
					var bx := x + (1 if fn.x > 0 else 0)
					var by := y + (1 if fn.y > 0 else 0)
					var bz := z + (1 if fn.z > 0 else 0)
					if fn.x < 0:
						bx = x
					if fn.y < 0:
						by = y
					if fn.z < 0:
						bz = z
					var ao := [3, 3, 3, 3]
					if ao_enabled and no_ao_bone[b] == 0:
						for k in range(4):
							var su := 1 if (k == 1 or k == 2) else -1
							var sv := 1 if (k == 2 or k == 3) else -1
							var ax := x + fn.x
							var ay := y + fn.y
							var az := z + fn.z
							var s1 := 1 if _grp_at(ax + fu.x * su, ay + fu.y * su, az + fu.z * su) == my_grp else 0
							var s2 := 1 if _grp_at(ax + fv.x * sv, ay + fv.y * sv, az + fv.z * sv) == my_grp else 0
							var c3 := 1 if _grp_at(ax + fu.x * su + fv.x * sv, ay + fu.y * su + fv.y * sv, az + fu.z * su + fv.z * sv) == my_grp else 0
							if s1 == 1 and s2 == 1:
								ao[k] = 0
							else:
								ao[k] = 3 - (s1 + s2 + c3)
					var v0 := verts.size()
					var nrm := Vector3(fn.x, fn.y, fn.z)
					for k in range(4):
						var su2 := 1 if (k == 1 or k == 2) else 0
						var sv2 := 1 if (k == 2 or k == 3) else 0
						var px := bx + fu.x * su2 + fv.x * sv2
						var py := by + fu.y * su2 + fv.y * sv2
						var pz := bz + fu.z * su2 + fv.z * sv2
						verts.append(Vector3(px, py, pz) * VOX)
						norms.append(nrm)
						var m: float = AO_TABLE[ao[k]] * bright
						cols.append(Color(base.r * m, base.g * m, base.b * m, alpha))
						uvs.append(Vector2(cls, vh))
						if skinned:
							var vb: Array = cb
							var vw: Array = cwt
							if not over:
								var vv: Array = vertex_weights(px, py, pz, b)
								vb = vv[0]
								vw = vv[1]
							for j in range(4):
								bone_arr.append(vb[j])
								wt_arr.append(vw[j])
					if ao[0] + ao[2] < ao[1] + ao[3]:
						idx.append_array([v0 + 1, v0 + 3, v0 + 2, v0 + 1, v0 + 0, v0 + 3])
					else:
						idx.append_array([v0 + 0, v0 + 2, v0 + 1, v0 + 0, v0 + 3, v0 + 2])
					quads += 1
	stats["cells"] = cells
	stats["quads"] = quads

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	if skinned:
		arrays[Mesh.ARRAY_BONES] = bone_arr
		arrays[Mesh.ARRAY_WEIGHTS] = wt_arr
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
