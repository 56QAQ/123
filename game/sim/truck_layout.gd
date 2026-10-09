class_name TruckLayout
extends RefCounted
## 卡车摆法(纯逻辑)：卡车占的格子矩形、朝向、我方部署区。开局选的卡车改装决定它能怎么动(Run.truck_mods 里只会有其中一个)：
##   truck_zone  卡车可以在初始部署区(GC.DEPLOY_RECT)内移动 / 旋转，部署区跟着卡车走(卡车在部署区里的相对位置不变，棋子也跟着走)
##   truck_free  卡车可以在初始部署区内移动 / 旋转，部署区不动(卡车在部署区里的相对位置会变；被卡车压住的棋子挪开)
##   truck_wide  卡车不能动，初始部署区四周各加 1 排(11 × 8)
## 没有改装("")= 初始摆法且不能动(测试 / 跑分 / 测试场)。
## rot：0 = 车头朝 +X(东)，占 3 × 2；1 = 顺时针转 90°(车头朝 +Z，靠近镜头)，占 2 × 3；2 = 朝 -X；3 = 朝 -Z。
## 旋转 = 保持左上角、长宽互换，再夹回初始部署区——连转四次回到原位。
## 部署区里有地形的格子(truck_zone 把部署区推到障碍物上)不能放棋子：能不能站以 BattleMap.is_deploy_cell 为准，这里只管几何。

const MODS: Array[String] = ["truck_zone", "truck_free", "truck_wide"]
const ZONE_PAD := Vector2i(3, 2)       # 初始部署区比卡车四周多出的格数(沿卡车自己的长 / 宽)

var mod: String = ""
var truck: Rect2i = GC.TRUCK_RECT
var rot: int = 0
var deploy: Rect2i = GC.DEPLOY_RECT


static func make(p_mod: String) -> TruckLayout:
	var t := TruckLayout.new()
	t.mod = p_mod if MODS.has(p_mod) else ""
	t._refresh_zone()
	return t


## 从战斗地图布局里读(Run.current_layout() 写进去的 truck_rect / truck_rot / deploy_rect / truck_mod)；没写 = 初始摆法
static func from_layout(layout: Dictionary) -> TruckLayout:
	var t := TruckLayout.new()
	t.mod = str(layout.get("truck_mod", ""))
	if layout.has("truck_rect"):
		t.truck = _rect(layout["truck_rect"])
	t.rot = int(layout.get("truck_rot", 0)) % 4
	if layout.has("deploy_rect"):
		t.deploy = _rect(layout["deploy_rect"])
	return t


static func _rect(v: Variant) -> Rect2i:
	if v is Rect2i:
		return v
	var a: Array = v
	return Rect2i(int(a[0]), int(a[1]), int(a[2]), int(a[3]))


## 写进战斗地图布局(BattleMap.from_layout / 表现层都从这里读)
func write_into(layout: Dictionary) -> Dictionary:
	layout["truck_rect"] = [truck.position.x, truck.position.y, truck.size.x, truck.size.y]
	layout["truck_rot"] = rot
	layout["deploy_rect"] = [deploy.position.x, deploy.position.y, deploy.size.x, deploy.size.y]
	layout["truck_mod"] = mod
	return layout


func duplicate_layout() -> TruckLayout:
	var t := TruckLayout.new()
	t.mod = mod
	t.truck = truck
	t.rot = rot
	t.deploy = deploy
	return t


func equals(o: TruckLayout) -> bool:
	return o != null and o.truck == truck and o.rot == rot and o.deploy == deploy and o.mod == mod


## 这种改装的卡车能不能动
func can_move() -> bool:
	return mod == "truck_zone" or mod == "truck_free"


## 卡车能停的范围 = 初始部署区
static func movable_rect() -> Rect2i:
	return GC.DEPLOY_RECT


static func size_for(r: int) -> Vector2i:
	return GC.TRUCK_RECT.size if (r % 4) % 2 == 0 else Vector2i(GC.TRUCK_RECT.size.y, GC.TRUCK_RECT.size.x)


static func fits(r: Rect2i) -> bool:
	return movable_rect().encloses(r)


## 把左上角夹进初始部署区(这个朝向的卡车要整个装得下)
static func clamp_pos(pos: Vector2i, r: int) -> Vector2i:
	var sz: Vector2i = size_for(r)
	var mr: Rect2i = movable_rect()
	return Vector2i(clampi(pos.x, mr.position.x, mr.end.x - sz.x), clampi(pos.y, mr.position.y, mr.end.y - sz.y))


## 新摆法：卡车左上角放到 pos、朝向 r(位置会被夹进初始部署区)。不能动的改装 = 原样的副本
func with_truck(pos: Vector2i, r: int) -> TruckLayout:
	var t: TruckLayout = duplicate_layout()
	if not can_move():
		return t
	t.rot = posmod(r, 4)
	t.truck = Rect2i(clamp_pos(pos, t.rot), size_for(t.rot))
	t._refresh_zone()
	return t


func moved_to(pos: Vector2i) -> TruckLayout:
	return with_truck(pos, rot)


## 顺时针转 steps 个 90°(负数 = 逆时针)：保持左上角、长宽互换
func rotated(steps: int = 1) -> TruckLayout:
	return with_truck(truck.position, rot + steps)


func _refresh_zone() -> void:
	match mod:
		"truck_zone":
			var pad: Vector2i = ZONE_PAD if rot % 2 == 0 else Vector2i(ZONE_PAD.y, ZONE_PAD.x)
			deploy = Rect2i(truck.position - pad, truck.size + pad * 2)
		"truck_wide":
			deploy = GC.DEPLOY_RECT.grow(1)
		_:
			deploy = GC.DEPLOY_RECT


func truck_center() -> Vector2:
	return GC.rect_center(truck)


## 车头朝向(表现层；模型车头朝 +X)
func facing_yaw() -> float:
	return -float(rot) * PI * 0.5


## 几何上能放棋子的格子：部署区内、不是卡车占的格子、在地图里(地形另由 BattleMap 判断)
func is_deploy_cell(c: Vector2i) -> bool:
	return deploy.has_point(c) and not truck.has_point(c) and c.x >= 0 and c.y >= 0 and c.x < GC.MAP_W and c.y < GC.MAP_H


func deploy_cells() -> Array[Vector2i]:
	var r: Array[Vector2i] = []
	for y in range(deploy.position.y, deploy.end.y):
		for x in range(deploy.position.x, deploy.end.x):
			if is_deploy_cell(Vector2i(x, y)):
				r.append(Vector2i(x, y))
	return r


## 部署区从这个摆法换成 to 时，站在格子 c 的棋子应该站到哪(truck_zone：部署区跟着卡车平移 / 旋转，棋子保持在部署区里的相对位置；
## 其它改装：原地不动)。旋转按顺时针 90° 的倍数把部署区整个转过去，卡车自己的格子转过去正好落在新卡车的格子上。
func map_cell(c: Vector2i, to: TruckLayout) -> Vector2i:
	if mod != "truck_zone" or to.mod != "truck_zone":
		return c
	var k: int = posmod(to.rot - rot, 4)
	var rel: Vector2i = c - deploy.position
	var sz: Vector2i = deploy.size
	for _i in range(k):
		rel = Vector2i(sz.y - 1 - rel.y, rel.x)
		sz = Vector2i(sz.y, sz.x)
	return to.deploy.position + rel
