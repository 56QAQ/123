extends SceneTree
## 构建世界静态模型：工坊卡车、第零章的断壁残垣(各款)、终点祭坛、第一章的城市、车间材料(图标用) → assets/world/<名字>.res(单位：米)。
## 体素 5 cm(角色的 4 倍)，网格器按角色体素 1.25 cm 输出，这里把顶点放大 4 倍再存。
## 用法: godot --path . --script res://tools/build_world.gd   (需要非 headless，才能正确存网格)
const Rig = preload("res://tools/rig.gd")
const VGrid = preload("res://tools/vgrid.gd")
const Mesher = preload("res://tools/mesher.gd")
const World = preload("res://tools/model_world.gd")
const City = preload("res://tools/model_city.gd")
const Items = preload("res://tools/model_items.gd")
const Events = preload("res://tools/model_events.gd")
const Frost = preload("res://tools/model_frost.gd")
const Spirits = preload("res://tools/model_spirits.gd")
const Dome = preload("res://tools/model_dome.gd")

const SCALE := 4.0
## 名字 -> [网格边界最小角, 最大角, 雕刻函数名, 模型库("" = model_world / "city" = model_city), 缩放(默认 SCALE)]
const MODELS := {
	"truck": [Vector3i(-36, -2, -24), Vector3i(36, 54, 24), "truck"],
	"rubble_a": [Vector3i(-14, -2, -14), Vector3i(14, 14, 14), "rubble_a"],
	"rubble_b": [Vector3i(-14, -2, -14), Vector3i(14, 14, 14), "rubble_b"],
	"rubble_big": [Vector3i(-24, -2, -24), Vector3i(24, 16, 24), "rubble_big"],
	"wall_low_a": [Vector3i(-24, -2, -14), Vector3i(24, 20, 20), "wall_low_a"],
	"wall_low_b": [Vector3i(-24, -2, -14), Vector3i(24, 20, 20), "wall_low_b"],
	"column_fallen": [Vector3i(-34, -2, -14), Vector3i(34, 20, 14), "column_fallen"],
	"column_a": [Vector3i(-12, -2, -12), Vector3i(12, 68, 12), "column_a"],
	"column_b": [Vector3i(-14, -2, -14), Vector3i(14, 48, 14), "column_b"],
	"statue": [Vector3i(-12, -2, -12), Vector3i(12, 60, 12), "statue"],
	"wall_a": [Vector3i(-24, -2, -10), Vector3i(24, 52, 10), "wall_a"],
	"wall_b": [Vector3i(-24, -2, -20), Vector3i(24, 52, 20), "wall_b"],
	"arch": [Vector3i(-34, -2, -22), Vector3i(34, 62, 22), "arch"],
	"altar": [Vector3i(-34, -2, -24), Vector3i(34, 72, 24), "altar"],
	# 第一章·红之章：死灰废墟(普通障碍) / 燃烧废墟(地形效果)
	"ash_rubble_a": [Vector3i(-14, -2, -14), Vector3i(14, 18, 14), "ash_rubble_a", "city"],
	"ash_rubble_b": [Vector3i(-14, -2, -14), Vector3i(14, 18, 14), "ash_rubble_b", "city"],
	"ash_car": [Vector3i(-24, -2, -14), Vector3i(24, 22, 14), "ash_car", "city"],
	"ash_heap": [Vector3i(-24, -2, -24), Vector3i(24, 22, 24), "ash_heap", "city"],
	"ash_wall_low": [Vector3i(-34, -2, -14), Vector3i(34, 18, 14), "ash_wall_low", "city"],
	"ash_pillar": [Vector3i(-14, -2, -14), Vector3i(14, 62, 14), "ash_pillar", "city"],
	"ash_wall": [Vector3i(-24, -2, -14), Vector3i(24, 56, 14), "ash_wall", "city"],
	"ash_corner": [Vector3i(-24, -2, -24), Vector3i(24, 62, 24), "ash_corner", "city"],
	"ash_shopfront": [Vector3i(-34, -2, -14), Vector3i(34, 54, 14), "ash_shopfront", "city"],
	"burn_debris": [Vector3i(-14, -2, -14), Vector3i(14, 18, 14), "burn_debris", "city"],
	"burn_car": [Vector3i(-24, -2, -14), Vector3i(24, 22, 14), "burn_car", "city"],
	"burn_house": [Vector3i(-24, -2, -24), Vector3i(24, 58, 24), "burn_house", "city"],
	"burn_shopfront": [Vector3i(-34, -2, -14), Vector3i(34, 54, 14), "burn_shopfront", "city"],
	# 第一章·红之章的大地图建筑：体素 25 cm(缩放 20)
	"bld_house_a": [Vector3i(-18, -2, -16), Vector3i(18, 26, 16), "bld_house_a", "city", 20.0],
	"bld_house_b": [Vector3i(-18, -2, -16), Vector3i(18, 26, 16), "bld_house_b", "city", 20.0],
	"bld_danchi": [Vector3i(-44, -2, -14), Vector3i(44, 48, 18), "bld_danchi", "city", 20.0],
	"bld_school": [Vector3i(-50, -2, -14), Vector3i(42, 44, 16), "bld_school", "city", 20.0],
	"bld_goal": [Vector3i(-10, -2, -6), Vector3i(10, 12, 3), "bld_goal", "city", 20.0],
	"bld_office_a": [Vector3i(-22, -2, -22), Vector3i(24, 56, 24), "bld_office_a", "city", 20.0],
	"bld_office_b": [Vector3i(-22, -2, -22), Vector3i(24, 108, 24), "bld_office_b", "city", 20.0],
	"bld_fallen": [Vector3i(-52, -2, -18), Vector3i(50, 20, 18), "bld_fallen", "city", 20.0],
	"bld_shops": [Vector3i(-34, -2, -12), Vector3i(32, 20, 14), "bld_shops", "city", 20.0],
	"bld_factory": [Vector3i(-36, -2, -26), Vector3i(36, 34, 26), "bld_factory", "city", 20.0],
	"bld_chimney": [Vector3i(-8, -2, -8), Vector3i(8, 98, 8), "bld_chimney", "city", 20.0],
	"bld_tank": [Vector3i(-16, -2, -16), Vector3i(16, 38, 16), "bld_tank", "city", 20.0],
	"bld_furnace": [Vector3i(-24, -2, -24), Vector3i(24, 68, 24), "bld_furnace", "city", 20.0],
	"bld_rubble": [Vector3i(-24, -2, -20), Vector3i(24, 18, 20), "bld_rubble", "city", 20.0],
	"bld_roadblock": [Vector3i(-18, -2, -14), Vector3i(18, 14, 14), "bld_roadblock", "city", 20.0],
	"bld_pole": [Vector3i(-6, -2, -2), Vector3i(7, 34, 5), "bld_pole", "city", 20.0],
	"bld_vending": [Vector3i(-4, -2, -3), Vector3i(3, 8, 4), "bld_vending", "city", 20.0],
	"bld_torii": [Vector3i(-11, -2, -2), Vector3i(11, 20, 3), "bld_torii", "city", 20.0],
	# 事件场景 / 事件战场(体素 5 cm，尺寸按棋子定)：燃烧喷泉(战场上 5×4 格) + 公园的道具
	"burn_fountain": [Vector3i(-50, -2, -50), Vector3i(50, 70, 50), "burn_fountain", "events"],
	"evt_bench": [Vector3i(-17, -2, -8), Vector3i(16, 22, 7), "evt_bench", "events"],
	"evt_tree": [Vector3i(-28, -2, -20), Vector3i(28, 78, 20), "evt_tree", "events"],
	"evt_lamp": [Vector3i(-5, -2, -4), Vector3i(12, 72, 8), "evt_lamp", "events"],
	"evt_swing": [Vector3i(-28, -2, -13), Vector3i(27, 42, 13), "evt_swing", "events"],
	# 事件「末班电车」：燃烧的路面电车 + 电车站的道具
	"burn_tram": [Vector3i(-102, -2, -27), Vector3i(102, 80, 24), "burn_tram", "events"],
	"evt_track": [Vector3i(-41, -2, -25), Vector3i(41, 4, 25), "evt_track", "events"],
	"evt_tram_stop": [Vector3i(-122, -2, -27), Vector3i(121, 64, 25), "evt_tram_stop", "events"],
	"evt_crossing": [Vector3i(-14, -2, -10), Vector3i(13, 78, 6), "evt_crossing", "events"],
	"evt_crossing_arm": [Vector3i(-11, -10, -3), Vector3i(68, 4, 3), "evt_crossing_arm", "events"],
	"evt_wire_pole": [Vector3i(-5, -2, -5), Vector3i(4, 92, 80), "evt_wire_pole", "events"],
	# 第二批事件(街景套件 roadside 的主角道具)
	"evt_gacha": [Vector3i(-12, -2, -12), Vector3i(12, 46, 14), "evt_gacha", "events"],
	"evt_dig": [Vector3i(-40, -2, -36), Vector3i(40, 34, 36), "evt_dig", "events"],
	"evt_well": [Vector3i(-24, -2, -24), Vector3i(24, 52, 24), "evt_well", "events"],
	"evt_barricade": [Vector3i(-50, -2, -14), Vector3i(50, 30, 14), "evt_barricade", "events"],
	"evt_searchlight": [Vector3i(-12, -2, -12), Vector3i(12, 50, 12), "evt_searchlight", "events"],
	"evt_tire_kit": [Vector3i(-24, -2, -20), Vector3i(24, 16, 20), "evt_tire_kit", "events"],
	"evt_canisters": [Vector3i(-24, -2, -16), Vector3i(30, 28, 26), "evt_canisters", "events"],
	"evt_sign": [Vector3i(-14, -2, -6), Vector3i(20, 60, 8), "evt_sign", "events"],
	"evt_bunker": [Vector3i(-54, -2, -44), Vector3i(54, 58, 42), "evt_bunker", "events"],
	"evt_pickup": [Vector3i(-50, -2, -26), Vector3i(50, 50, 26), "evt_pickup", "events"],
	"evt_crater": [Vector3i(-52, -2, -48), Vector3i(52, 10, 48), "evt_crater", "events"],
	"evt_friend": [Vector3i(-12, -2, -18), Vector3i(18, 38, 22), "evt_friend", "events"],
	# 第二章-A·紫之章：坚冰(战斗内，体素 5 cm)
	"ice_rubble_a": [Vector3i(-14, -2, -14), Vector3i(14, 20, 14), "ice_rubble_a", "frost"],
	"ice_rubble_b": [Vector3i(-14, -2, -14), Vector3i(14, 20, 14), "ice_rubble_b", "frost"],
	"ice_block": [Vector3i(-24, -2, -14), Vector3i(24, 24, 14), "ice_block", "frost"],
	"ice_heap": [Vector3i(-24, -2, -24), Vector3i(24, 28, 24), "ice_heap", "frost"],
	"ice_wall_low": [Vector3i(-34, -2, -14), Vector3i(34, 24, 14), "ice_wall_low", "frost"],
	"ice_pillar": [Vector3i(-14, -2, -14), Vector3i(14, 66, 14), "ice_pillar", "frost"],
	"ice_wall": [Vector3i(-24, -2, -14), Vector3i(24, 60, 14), "ice_wall", "frost"],
	"ice_corner": [Vector3i(-24, -2, -24), Vector3i(24, 66, 24), "ice_corner", "frost"],
	"ice_spire": [Vector3i(-34, -2, -14), Vector3i(34, 72, 14), "ice_spire", "frost"],
	# 紫之章的大地图：和风建筑 / 大冰晶(体素 25 cm，缩放 20)，紫色冰山(体素 50 cm，缩放 40)
	"jp_shrine": [Vector3i(-42, -2, -30), Vector3i(42, 48, 30), "jp_shrine", "frost", 20.0],
	"jp_pagoda": [Vector3i(-30, -2, -30), Vector3i(30, 114, 30), "jp_pagoda", "frost", 20.0],
	"jp_house": [Vector3i(-28, -2, -22), Vector3i(28, 32, 22), "jp_house", "frost", 20.0],
	"jp_lantern": [Vector3i(-5, -2, -5), Vector3i(5, 17, 5), "jp_lantern", "frost", 20.0],
	"jp_wall": [Vector3i(-27, -2, -5), Vector3i(27, 14, 5), "jp_wall", "frost", 20.0],
	"jp_pine": [Vector3i(-18, -2, -18), Vector3i(18, 44, 18), "jp_pine", "frost", 20.0],
	"ice_shard_a": [Vector3i(-14, -2, -14), Vector3i(14, 38, 14), "ice_shard_a", "frost", 20.0],
	"ice_shard_b": [Vector3i(-22, -2, -18), Vector3i(22, 58, 18), "ice_shard_b", "frost", 20.0],
	"ice_shard_c": [Vector3i(-30, -2, -26), Vector3i(30, 32, 26), "ice_shard_c", "frost", 20.0],
	"ice_berg": [Vector3i(-62, -2, -52), Vector3i(62, 112, 52), "ice_berg", "frost", 40.0],
	# 第一章-B·蓝之章：战斗内的科技障碍(体素 5 cm)
	"tech_planter": [Vector3i(-12, -2, -12), Vector3i(12, 24, 12), "tech_planter", "dome"],
	"tech_crate": [Vector3i(-10, -2, -10), Vector3i(10, 18, 10), "tech_crate", "dome"],
	"tech_bench": [Vector3i(-22, -2, -10), Vector3i(22, 26, 10), "tech_bench", "dome"],
	"tech_crates": [Vector3i(-22, -2, -22), Vector3i(22, 28, 22), "tech_crates", "dome"],
	"tech_barrier": [Vector3i(-32, -2, -8), Vector3i(32, 28, 8), "tech_barrier", "dome"],
	"tech_pillar": [Vector3i(-10, -2, -10), Vector3i(10, 64, 10), "tech_pillar", "dome"],
	"tech_kiosk": [Vector3i(-22, -2, -12), Vector3i(22, 50, 12), "tech_kiosk", "dome"],
	"tech_server": [Vector3i(-22, -2, -22), Vector3i(22, 54, 22), "tech_server", "dome"],
	"tech_gate": [Vector3i(-32, -2, -8), Vector3i(32, 60, 8), "tech_gate", "dome"],
	# 蓝之章的大地图：未来风的楼 / 高杆 / 树 / 路灯 / 路牌(体素 25 cm，缩放 20)，城北的巨大信标(体素 50 cm，缩放 40)
	"sf_tower_a": [Vector3i(-12, -2, -12), Vector3i(12, 158, 12), "sf_tower_a", "dome", 20.0],
	"sf_tower_b": [Vector3i(-16, -2, -16), Vector3i(16, 146, 16), "sf_tower_b", "dome", 20.0],
	"sf_block": [Vector3i(-24, -2, -16), Vector3i(24, 32, 16), "sf_block", "dome", 20.0],
	"sf_pylon": [Vector3i(-8, -2, -8), Vector3i(8, 68, 8), "sf_pylon", "dome", 20.0],
	"sf_tree": [Vector3i(-10, -2, -10), Vector3i(10, 32, 10), "sf_tree", "dome", 20.0],
	"sf_lamp": [Vector3i(-4, -2, -4), Vector3i(4, 30, 10), "sf_lamp", "dome", 20.0],
	"sf_sign": [Vector3i(-12, -2, -4), Vector3i(12, 36, 4), "sf_sign", "dome", 20.0],
	"sf_beacon": [Vector3i(-34, -2, -34), Vector3i(34, 232, 34), "sf_beacon", "dome", 40.0],
	# 车间材料(体素 1.25 cm，缩放 1)：只用来渲染像素图标
	"item_mat_red": [Vector3i(-17, -2, -15), Vector3i(17, 41, 15), "mat_red", "items", 1.0],
	"item_mat_green": [Vector3i(-16, -2, -10), Vector3i(16, 42, 10), "mat_green", "items", 1.0],
	"item_mat_blue": [Vector3i(-10, -2, -10), Vector3i(10, 42, 10), "mat_blue", "items", 1.0],
	# 守林节点的背后灵(体素 5 cm)：狮子 / 巨蛛 / 巨蟾，拆成部件，原点 = 关节(game/view/beast_spirit.gd 拼起来)
	"spirit_lion_body": [Vector3i(-10, -9, -17), Vector3i(10, 10, 18), "spirit_lion_body", "spirits"],
	"spirit_lion_head": [Vector3i(-16, -14, -6), Vector3i(16, 16, 17), "spirit_lion_head", "spirits"],
	"spirit_lion_jaw": [Vector3i(-5, -4, -1), Vector3i(5, 2, 9), "spirit_lion_jaw", "spirits"],
	"spirit_lion_leg_f": [Vector3i(-5, -19, -5), Vector3i(5, 4, 8), "spirit_lion_leg_f", "spirits"],
	"spirit_lion_leg_b": [Vector3i(-5, -19, -8), Vector3i(5, 4, 6), "spirit_lion_leg_b", "spirits"],
	"spirit_lion_tail": [Vector3i(-3, -6, -19), Vector3i(3, 5, 2), "spirit_lion_tail", "spirits"],
	"spirit_spider_abdomen": [Vector3i(-12, -7, -27), Vector3i(12, 15, 2), "spirit_spider_abdomen", "spirits"],
	"spirit_spider_ceph": [Vector3i(-9, -5, -9), Vector3i(9, 7, 13), "spirit_spider_ceph", "spirits"],
	"spirit_spider_fang": [Vector3i(-2, -7, -2), Vector3i(2, 2, 4), "spirit_spider_fang", "spirits"],
	"spirit_spider_leg": [Vector3i(-2, -15, -3), Vector3i(22, 10, 3), "spirit_spider_leg", "spirits"],
	"spirit_toad_body": [Vector3i(-14, -10, -15), Vector3i(14, 13, 18), "spirit_toad_body", "spirits"],
	"spirit_toad_jaw": [Vector3i(-12, -4, -2), Vector3i(12, 2, 12), "spirit_toad_jaw", "spirits"],
	"spirit_toad_tongue": [Vector3i(-4, -3, -1), Vector3i(4, 3, 23), "spirit_toad_tongue", "spirits"],
	"spirit_toad_leg_f": [Vector3i(-3, -10, -3), Vector3i(8, 3, 8), "spirit_toad_leg_f", "spirits"],
	"spirit_toad_leg_b": [Vector3i(-6, -10, -10), Vector3i(11, 5, 10), "spirit_toad_leg_b", "spirits"],
}

var rig
var mat: ShaderMaterial


func _init() -> void:
	var t0 := Time.get_ticks_msec()
	rig = Rig.new()
	rig.build()
	mat = ShaderMaterial.new()
	mat.shader = load("res://assets/voxel.gdshader")
	mat.set_shader_parameter("rim_strength", 0.0)
	DirAccess.make_dir_recursive_absolute("res://assets/world")
	for nm: String in MODELS.keys():
		var spec: Array = MODELS[nm]
		var g = VGrid.new(spec[0], spec[1], rig.ids, rig.mirror_of)
		var lib: String = str(spec[3]) if spec.size() > 3 else ""
		var w = City.new(g) if lib == "city" else (Items.new(g) if lib == "items" else (Events.new(g) if lib == "events" else (Frost.new(g) if lib == "frost" else (Spirits.new(g) if lib == "spirits" else (Dome.new(g) if lib == "dome" else World.new(g))))))
		var scale: float = float(spec[4]) if spec.size() > 4 else SCALE
		match str(spec[2]):
			"wall_low_a":
				w.wall_low(false)
			"wall_low_b":
				w.wall_low(true)
			"column_a":
				w.column(false)
			"column_b":
				w.column(true)
			"wall_a":
				w.wall_high(true)
			"wall_b":
				w.wall_high(false)
			"bld_house_a":
				w.bld_house(false, 3)
			"bld_house_b":
				w.bld_house(true, 7)
			"bld_danchi":
				w.bld_danchi(11)
			"bld_school":
				w.bld_school(13)
			"bld_goal":
				w.bld_goal()
			"bld_office_a":
				w.bld_office(17, 7)
			"bld_office_b":
				w.bld_office(19, 14)
			"bld_fallen":
				w.bld_fallen_tower(23)
			"bld_shops":
				w.bld_shops(29)
			"bld_factory":
				w.bld_factory(31)
			"bld_chimney":
				w.bld_chimney(37)
			"bld_tank":
				w.bld_tank(41)
			"bld_furnace":
				w.bld_furnace(43)
			"bld_rubble":
				w.bld_rubble(47)
			"bld_roadblock":
				w.bld_roadblock(53)
			"bld_pole":
				w.bld_pole()
			"bld_vending":
				w.bld_vending()
			"bld_torii":
				w.bld_torii()
			_:
				w.call(str(spec[2]))
		var m = Mesher.new(g, rig)
		m.skinned = false
		var raw: ArrayMesh = m.build()
		var arr: Array = raw.surface_get_arrays(0)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for i in range(verts.size()):
			verts[i] = verts[i] * scale
		arr[Mesh.ARRAY_VERTEX] = verts
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(0, mat)
		ResourceSaver.save(mesh, "res://assets/world/%s.res" % nm)
		print("  ", nm, ": voxels ", g.count_solid(), " oob ", g.oob_count, " quads ", m.stats["quads"])
	print("world built in ", Time.get_ticks_msec() - t0, " ms")
	quit()
