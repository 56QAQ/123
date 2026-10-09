extends RefCounted
## 骨骼定义：角色 + 弓 + 箭 共用一个 Skeleton3D。
## 所有位置都是"体素连续坐标"(单位=1体素)，y 向上，角色朝 +Z，角色左侧为 +X。
## 骨骼静止旋转全部为单位旋转，只有平移偏移，这样动画里的欧拉角就是"绕世界轴"的直观旋转。

const VOX := 0.0125   # 1 体素 = 1.25cm

var names: PackedStringArray = PackedStringArray()
var parent: PackedInt32Array = PackedInt32Array()
var pos: PackedVector3Array = PackedVector3Array()
var ids: Dictionary = {}
var mirror_of: PackedInt32Array = PackedInt32Array()
var zones: Array = []          # 软权重区
var leaf: PackedByteArray = PackedByteArray()   # 末端骨(无网格)

## 二次运动链(弹簧骨)定义：{ "name":..., "bones":[idx...], "stiff":..., "drag":..., "grav":... }
var chains: Array = []


func add(bname: String, parent_name: String, p: Vector3, is_leaf: bool = false) -> int:
	assert(not ids.has(bname), "duplicate bone " + bname)
	var i := names.size()
	names.append(bname)
	parent.append(ids[parent_name] if parent_name != "" else -1)
	pos.append(p)
	leaf.append(1 if is_leaf else 0)
	ids[bname] = i
	return i


func has(n: String) -> bool:
	return ids.has(n)


func id(n: String) -> int:
	return ids[n]


static func mir(p: Vector3) -> Vector3:
	return Vector3(-p.x, p.y, p.z)


## 左右成对骨骼。base 会加 _L/_R 后缀，父骨骼若有 L/R 版本则取同侧
func pair(base: String, parent_base: String, pl: Vector3, is_leaf: bool = false) -> void:
	var pL := parent_base + "_L"
	var pR := parent_base + "_R"
	if ids.has(pL):
		add(base + "_L", pL, pl, is_leaf)
		add(base + "_R", pR, mir(pl), is_leaf)
	else:
		add(base + "_L", parent_base, pl, is_leaf)
		add(base + "_R", parent_base, mir(pl), is_leaf)


## 链：pts 依次是每节骨骼的头部位置，最后一个点是末端骨(叶子)。
## 命名 prefix+"1".."n"，末端 prefix+"End"。返回骨骼名列表。
func chain(prefix: String, parent_name: String, pts: Array, half: float = 2.5, rmax: float = 1e9) -> PackedStringArray:
	var out := PackedStringArray()
	var prev := parent_name
	for i in range(pts.size()):
		var is_end := i == pts.size() - 1
		var n := prefix + ("End" if is_end else str(i + 1))
		add(n, prev, pts[i], is_end)
		out.append(n)
		prev = n
	# 相邻两节之间的软权重区(在下一节头部位置)
	for i in range(1, pts.size() - 1):
		var a: Vector3 = pts[i - 1]
		var b: Vector3 = pts[i]
		var c: Vector3 = pts[i + 1]
		var axis := (c - a).normalized()
		zone(out[i - 1], out[i], b, axis, half, rmax)
	return out


func chain_pair(prefix: String, parent_base: String, pts_l: Array, half: float = 2.5, rmax: float = 1e9) -> void:
	var pl: Array = []
	var pr: Array = []
	for p in pts_l:
		pl.append(p)
		pr.append(mir(p))
	var par_l := parent_base
	var par_r := parent_base
	if parent_base.find("%s") >= 0:
		par_l = parent_base % "L"
		par_r = parent_base % "R"
	elif ids.has(parent_base + "_L"):
		par_l = parent_base + "_L"
		par_r = parent_base + "_R"
	chain(prefix + "_L", par_l, pl, half, rmax)
	chain(prefix + "_R", par_r, pr, half, rmax)


## 软权重区：a→b 沿 axis 方向，在 center 处交叉，半宽 half；rmax 限制横向半径；clipx: 1 仅 x>=0，-1 仅 x<0
func zone(a: String, b: String, center: Vector3, axis: Vector3, half: float, rmax: float = 1e9, clipx: int = 0) -> void:
	zones.append({"a": ids[a], "b": ids[b], "c": center, "n": axis.normalized(), "h": half, "r": rmax, "clipx": clipx})


func zone_pair(a: String, b: String, center: Vector3, axis: Vector3, half: float, rmax: float = 1e9) -> void:
	# 左右镜像成对(a,b 为 base 名，自动加 _L/_R)
	var ax := axis
	var a_l := a + "_L" if ids.has(a + "_L") else a
	var a_r := a + "_R" if ids.has(a + "_R") else a
	zone(a_l, b + "_L", center, ax, half, rmax, 1)
	zone(a_r, b + "_R", mir(center), Vector3(-ax.x, ax.y, ax.z), half, rmax, -1)


func build() -> void:
	# ---------------------------------------------------------- 躯干
	add("Root", "", Vector3(0, 0, 0))
	add("Hips", "Root", Vector3(0, 46, 0))
	add("Spine", "Hips", Vector3(0, 51, 0))
	add("Chest", "Spine", Vector3(0, 58, 0))
	add("Neck", "Chest", Vector3(0, 69, -1))
	add("Head", "Neck", Vector3(0, 73, -1))

	# ---------------------------------------------------------- 手臂 (L=+X)
	pair("Shoulder", "Chest", Vector3(3.5, 67, 0))
	pair("UpperArm", "Shoulder", Vector3(10.5, 66, 0.5))
	pair("LowerArm", "UpperArm", Vector3(13.0, 56, 0.5))
	pair("Hand", "LowerArm", Vector3(16.0, 47, 0.5))
	pair("Fingers", "Hand", Vector3(17.0, 43, 2.0))
	pair("Thumb", "Hand", Vector3(14.0, 45.5, 3.0))

	# ---------------------------------------------------------- 腿
	pair("Thigh", "Hips", Vector3(5.5, 46, 0.5))
	pair("Shin", "Thigh", Vector3(5.5, 27, 0.5))
	pair("Foot", "Shin", Vector3(5.5, 7.5, -0.5))
	pair("Toe", "Foot", Vector3(5.5, 3, 4.5))

	# ---------------------------------------------------------- 头部附件
	add("Halo", "Head", Vector3(0, 93, -9))
	pair("Eyelid", "Head", Vector3(5.5, 82.0, 9.5))

	# 耳坠(青色水晶)
	chain_pair("EarDrop", "Head", [Vector3(14, 81, 2), Vector3(14, 75, 2)], 1.5)

	# 发鬓(脸侧两缕)
	chain_pair("SideLock", "Head", [Vector3(12.5, 85, 4), Vector3(12.5, 78, 6), Vector3(12.5, 71, 7), Vector3(12.5, 62, 7)], 2.5)

	# 马尾：三列 × 七段，头部为父
	var cz := [-13.0, -16.0, -19.0, -20.5, -21.0, -21.5, -21.5, -21.0]
	var ys := [92.0, 84.0, 75.0, 66.0, 57.0, 48.0, 39.0, 30.0]
	for col in ["C", "L", "R"]:
		var pts: Array = []
		for i in range(ys.size()):
			var x := 0.0
			if col == "L":
				x = 7.5 + float(i) * 0.25
			elif col == "R":
				x = -7.5 - float(i) * 0.25
			pts.append(Vector3(x, ys[i], cz[i]))
		chain("Tail" + col, "Head", pts, 3.0)
	# 列与列之间的软权重(每一段)
	for i in range(1, 8):
		var y: float = ys[i - 1]
		var z: float = cz[i - 1]
		var seg_name := str(i) if i < 8 else "End"
		zone("TailC" + seg_name, "TailL" + seg_name, Vector3(3.6, y - 4.0, z), Vector3(1, 0, 0), 2.5, 1e9, 0)
		zone("TailC" + seg_name, "TailR" + seg_name, Vector3(-3.6, y - 4.0, z), Vector3(-1, 0, 0), 2.5, 1e9, 0)

	# ---------------------------------------------------------- 腰侧裙甲(羽刃) + 流苏 + 大腿垂饰
	chain_pair("Panel", "Hips", [Vector3(10.0, 49, 0), Vector3(14.0, 38, -4), Vector3(18.0, 27, -8), Vector3(22.0, 15, -12)], 3.0)
	chain_pair("PTassel", "Panel_%s2", [Vector3(19.0, 34, -5.0), Vector3(19.0, 26, -5.0)], 1.0)
	chain_pair("PTassel2", "Panel_%s3", [Vector3(22.5, 20, -10.0), Vector3(22.5, 12, -10.0)], 1.0)
	chain_pair("ATassel", "LowerArm", [Vector3(15.6, 52.0, 4.5), Vector3(15.6, 44.0, 4.5)], 1.0)
	chain_pair("Dangle", "Thigh", [Vector3(12.5, 40, 2.5), Vector3(12.5, 34, 2.5), Vector3(12.5, 25, 2.5)], 1.5)

	# ---------------------------------------------------------- 弓(挂在右手上)、弓弦、箭
	add("Bow", "Hand_R", Vector3(-16, 44, 3))
	add("Bow_U1", "Bow", Vector3(-16, 53, 3))
	add("Bow_U2", "Bow_U1", Vector3(-16, 73, -1.1))
	add("Bow_D1", "Bow", Vector3(-16, 35, 3))
	add("Bow_D2", "Bow_D1", Vector3(-16, 15, -1.1))
	add("Bow_Gear", "Bow", Vector3(-16, 44, 8))
	add("Bow_Nock", "Bow", Vector3(-16, 44, -10.3))
	add("Arrow", "Root", Vector3(-13.5, 46.0, -10.0))
	# 左手武器(双持武器的左手那把)：与右手的 "Bow" 骨镜像，握点 = 左手前方
	add("Weapon_L", "Hand_L", Vector3(16, 44, 3))
	# 副手盾：挂在左手上的独立骨，待机小动作/胜利动作时缩到 0 = 收起
	add("Shield", "Hand_L", Vector3(17, 51, 1))
	# 翅膀(护理节点的妖精翅膀)：挂在胸口后方，扑动由 build_anims 程序化烘焙；其它模型不用这两根骨
	pair("Wing", "Chest", Vector3(3.5, 63, -6))
	# 兽尾(腰后)：一条 5 节的弹簧链，静止时向后平伸、末端微翘；专属模型用 model_chars.btail_bone() 把尾巴体素挂上去
	chain("BTail", "Hips", BTAIL_PTS, 2.5)
	# 披风/长外套后摆(胸口背后)：左中右三列 × 4 节的弹簧链；专属模型用 model_chars.cape_bone() 挂披风体素
	chain("CapeC", "Chest", _cape_pts(0.0), 3.0)
	chain_pair("Cape", "Chest", _cape_pts(1.0), 3.0)
	for i in range(1, 4):
		var y: float = CAPE_Y[i]
		zone("CapeC" + str(i), "Cape_L" + str(i), Vector3(3.5, y - 5.0, CAPE_Z[i]), Vector3(1, 0, 0), 2.0, 1e9, 1)
		zone("CapeC" + str(i), "Cape_R" + str(i), Vector3(-3.5, y - 5.0, CAPE_Z[i]), Vector3(-1, 0, 0), 2.0, 1e9, -1)

	# ---------------------------------------------------------- 镜像表
	mirror_of.resize(names.size())
	for i in range(names.size()):
		mirror_of[i] = i
		var n := names[i]
		var k := n.find("_L")
		if k >= 0:
			var m := n.substr(0, k) + "_R" + n.substr(k + 2)
			if ids.has(m):
				mirror_of[i] = ids[m]
		else:
			k = n.find("_R")
			if k >= 0:
				var m2 := n.substr(0, k) + "_L" + n.substr(k + 2)
				if ids.has(m2):
					mirror_of[i] = ids[m2]

	# ---------------------------------------------------------- 躯干/四肢软权重区
	zone("Hips", "Spine", Vector3(0, 49, 0), Vector3.UP, 2.5)
	zone("Spine", "Chest", Vector3(0, 56, 0), Vector3.UP, 2.5)
	zone("Chest", "Neck", Vector3(0, 69, -1), Vector3.UP, 1.5, 4.5)
	zone("Neck", "Head", Vector3(0, 73, -1), Vector3.UP, 1.5, 4.5)
	# 肩：胸 → 上臂(横向)
	zone("Chest", "UpperArm_L", Vector3(8.0, 65.5, 0), Vector3(1, 0, 0), 2.0, 6.0, 1)
	zone("Chest", "UpperArm_R", Vector3(-8.0, 65.5, 0), Vector3(-1, 0, 0), 2.0, 6.0, -1)
	# 肘/腕/指、膝/踝/趾的软权重区只作用在相邻两段骨的体素上，半径放宽到能罩住厚袖子、靴子
	zone_pair("UpperArm", "LowerArm", Vector3(13.0, 56, 0.5), Vector3.DOWN, 1.6, 12.0)
	zone_pair("LowerArm", "Hand", Vector3(16.0, 47, 0.5), Vector3.DOWN, 1.3, 10.0)
	zone_pair("Hand", "Fingers", Vector3(17.0, 43, 2.0), Vector3.DOWN, 1.0, 8.0)
	# 髋 → 大腿 → 小腿 → 脚 → 脚趾
	zone_pair("Hips", "Thigh", Vector3(5.5, 43, 0.5), Vector3.DOWN, 2.5, 7.0)
	zone_pair("Thigh", "Shin", Vector3(5.5, 27, 0.5), Vector3.DOWN, 1.6, 12.0)
	zone_pair("Shin", "Foot", Vector3(5.5, 7.5, -0.5), Vector3.DOWN, 1.5, 12.0)
	zone_pair("Foot", "Toe", Vector3(5.5, 3, 4), Vector3(0, 0, 1), 1.2, 10.0)
	# 弓臂弯曲
	zone("Bow", "Bow_U1", Vector3(-16, 53, 3), Vector3.UP, 4.0)
	zone("Bow_U1", "Bow_U2", Vector3(-16, 73, -1.1), Vector3.UP, 8.0)
	zone("Bow", "Bow_D1", Vector3(-16, 35, 3), Vector3.DOWN, 4.0)
	zone("Bow_D1", "Bow_D2", Vector3(-16, 15, -1.1), Vector3.DOWN, 8.0)


const BTAIL_PTS := [Vector3(0, 44, -6.5), Vector3(0, 40.5, -12.0), Vector3(0, 37.5, -17.5), Vector3(0, 36.5, -23.0), Vector3(0, 37.5, -28.5), Vector3(0, 40.5, -33.5)]
const CAPE_Y := [66.0, 56.0, 46.0, 36.0, 26.0]
const CAPE_Z := [-6.5, -8.0, -9.0, -10.0, -10.5]


## 披风一列的节点：side 0 = 中列，1 = 左列(x>0；右列由 chain_pair 镜像)
static func _cape_pts(side: float) -> Array:
	var r: Array = []
	for i in range(CAPE_Y.size()):
		r.append(Vector3(side * (6.5 + float(i) * 0.6), CAPE_Y[i], CAPE_Z[i]))
	return r


## 用于环境光遮蔽的分组：只有同组体素互相产生 AO
func ao_group(bone_index: int) -> int:
	var n := names[bone_index]
	if n.begins_with("Bow") or n == "Arrow" or n.begins_with("Weapon"):
		return 10
	if n == "Shield":
		return 4
	if n.begins_with("Wing"):
		return 11
	if n.begins_with("BTail"):
		return 12
	if n.begins_with("Cape"):
		return 13
	if n.begins_with("ATassel"):
		return 4 if n.find("_L") > 0 else 5
	if n == "Root" or n == "Hips" or n == "Spine" or n == "Chest" or n == "Neck" or n.begins_with("Shoulder"):
		return 1
	if n == "Head" or n == "Halo" or n.begins_with("Eyelid") or n.begins_with("EarDrop") or n.begins_with("SideLock"):
		return 2
	if n.begins_with("Tail"):
		return 3
	if n.ends_with("_L") or n.find("_L") > 0:
		if n.begins_with("UpperArm") or n.begins_with("LowerArm") or n.begins_with("Hand") or n.begins_with("Fingers") or n.begins_with("Thumb"):
			return 4
		if n.begins_with("Panel") or n.begins_with("PTassel"):
			return 8
		return 6
	if n.find("_R") > 0:
		if n.begins_with("UpperArm") or n.begins_with("LowerArm") or n.begins_with("Hand") or n.begins_with("Fingers") or n.begins_with("Thumb"):
			return 5
		if n.begins_with("Panel") or n.begins_with("PTassel"):
			return 9
		return 7
	if n.begins_with("Bow") or n == "Arrow":
		return 10
	return 1


# ---------------------------------------------------------------- Skeleton3D
func make_skeleton() -> Skeleton3D:
	var sk := Skeleton3D.new()
	sk.name = "Skeleton3D"
	for i in range(names.size()):
		sk.add_bone(names[i])
	for i in range(names.size()):
		if parent[i] >= 0:
			sk.set_bone_parent(i, parent[i])
			sk.set_bone_rest(i, Transform3D(Basis.IDENTITY, (pos[i] - pos[parent[i]]) * VOX))
		else:
			sk.set_bone_rest(i, Transform3D(Basis.IDENTITY, pos[i] * VOX))
	sk.reset_bone_poses()
	return sk
