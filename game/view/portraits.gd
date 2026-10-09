class_name Portraits
extends Node
## 启动时离屏渲染 2D 界面用的贴图：
##  · 单位头像：真实 3D 模型(3/4 半身、拿着基础武器的待机姿势)，商店卡/单位卡用
##  · 武器图标：真实的体素武器网格(与装备到棋子手里时完全一样，按武器颜色换色)，背包/武器槽/提示/奖励用
##  · 车间材料图标：材料的体素模型(assets/world/item_mat_*.res，tools/model_items.gd)按原始像素尺寸渲染、不抗锯齿，
##    再描一圈 1 像素的深色外框 = 像素图标；小号(26 px)/大号(48 px)两套，界面按整数倍放大(最近邻)
## 结果同时写进 UIKit.portraits / UIKit.weapon_icons / UIKit.material_icons，供静态 UI 构建函数使用。

const MODEL_SCENE := preload("res://scenes/unit_model.tscn")

## 各武器大类的图标摆法：rot = 武器骨骼的旋转(度，XYZ 欧拉)，cam = 相机方向(从武器看向相机)
## 相机在 -X 一侧：画面右 ≈ +Z，上 = +Y。近战(+Y=刃)转 45° 成对角线；枪械(-Y=枪口)转 -90° 让枪口朝右。
const ICON_POSE := {
	"sword": {"rot": Vector3(45, 0, 0), "cam": Vector3(-1.0, 0.22, 0.12)},
	"polearm": {"rot": Vector3(45, 0, 0), "cam": Vector3(-1.0, 0.22, 0.12)},
	"heavy": {"rot": Vector3(45, 0, 0), "cam": Vector3(-1.0, 0.22, 0.12)},
	"dual": {"rot": Vector3(40, 0, 0), "rot_l": Vector3(-40, 0, 0), "cam": Vector3(-1.0, 0.22, 0.12)},
	"bow": {"rot": Vector3(30, 0, 0), "cam": Vector3(-1.0, 0.18, -0.25)},
	"crossbow": {"rot": Vector3(-90, 0, 0), "cam": Vector3(-0.55, 0.85, 0.2)},
	"pistols": {"rot": Vector3(-80, 0, 0), "rot_l": Vector3(-80, 0, 0), "off_l": Vector3(0.0, -0.10, -0.07), "cam": Vector3(-1.0, 0.25, 0.1)},
	"rifle": {"rot": Vector3(-78, 0, 0), "cam": Vector3(-1.0, 0.25, 0.08)},
	"focus": {"rot": Vector3(-90, 0, 0), "cam": Vector3(-0.7, 0.55, 0.35)},
}

var textures: Dictionary = {}
var weapon_textures: Dictionary = {}
var material_textures: Dictionary = {}     # 材料 -> {"s": 小号, "l": 大号}
var _sv: SubViewport


func render_all(cat: Catalog) -> void:
	await _render_units(cat)
	await _render_weapons(cat)
	await render_materials()
	UIKit.portraits = textures
	UIKit.weapon_icons = weapon_textures
	UIKit.material_icons = material_textures


# ---------------------------------------------------------------- 单位头像
func _render_units(cat: Catalog) -> void:
	_sv = _make_viewport(Vector2i(280, 190))
	var cam := Camera3D.new()
	cam.fov = 21.0
	_sv.add_child(cam)
	cam.position = Vector3(0.62, 1.12, 2.55)
	cam.look_at(Vector3(0.02, 1.0, 0.0), Vector3.UP)
	var ids: Array = cat.units.keys()
	ids.sort()
	for id: String in ids:
		var def: UnitDef = cat.get_unit(id)
		var v := UnitView.new()
		_sv.add_child(v)
		v.setup(def, 1, 0, false, cat.resolve_weapon(def, ""))
		v.set_bar_visible(false)
		v.set_team_ring_visible(false)
		v.rotation.y = 0.0
		v.ap.play(UnitSkin.anim(v.look, "idle"))
		v.ap.seek(1.1, true)
		v.ap.advance(0.0)
		textures[id] = await _snap()
		v.queue_free()
		await get_tree().process_frame
	_sv.queue_free()


# ---------------------------------------------------------------- 武器图标
func _render_weapons(cat: Catalog) -> void:
	_sv = _make_viewport(Vector2i(144, 144))
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.near = 0.05
	cam.far = 20.0
	_sv.add_child(cam)
	var model: Node3D = MODEL_SCENE.instantiate()
	_sv.add_child(model)
	var ap: AnimationPlayer = model.get_node("AnimationPlayer")
	ap.autoplay = ""
	ap.stop()
	var sk: Skeleton3D = UnitSkin.skeleton_of(model)
	var ids: Array = cat.equipment.keys()
	ids.sort()
	for id: String in ids:
		var e: EquipmentDef = cat.get_equipment(id)
		var look: Dictionary = {"wclass": e.class_id, "model": e.model, "color": e.color_id if not e.basic else "white", "shield": false}
		UnitSkin.apply(model, look, "white")
		(sk.get_node("Body") as MeshInstance3D).visible = false
		_pose_weapon(sk, e.class_id)
		var parts: Array[MeshInstance3D] = []
		for nm: String in UnitSkin.part_names(model, look):
			if nm != "Body":
				parts.append(sk.get_node(nm) as MeshInstance3D)
		_fit_camera(cam, sk, parts, (ICON_POSE[e.class_id]["cam"] as Vector3).normalized())
		weapon_textures[id] = await _snap()
		await get_tree().process_frame
	_sv.queue_free()


# ---------------------------------------------------------------- 车间材料的像素图标
const MAT_ICON_PX := {"s": 24, "l": 46}          # 渲染尺寸(加上外框 +2)
const MAT_ICON_DIR := Vector3(-0.3, 0.34, 1.0)   # 从正面偏左上方看(瓶子的高光在左前方)
const ICON_OUTLINE := Color("#121318")


func render_materials() -> void:
	for m: String in Crafting.MATS:
		var path: String = "res://assets/world/item_mat_%s.res" % m
		if not ResourceLoader.exists(path):
			continue
		var mesh: Mesh = load(path) as Mesh
		var set := {}
		for k: String in MAT_ICON_PX.keys():
			var px: int = int(MAT_ICON_PX[k])
			_sv = _make_viewport(Vector2i(px, px))
			_sv.msaa_3d = Viewport.MSAA_DISABLED
			var cam := Camera3D.new()
			cam.projection = Camera3D.PROJECTION_ORTHOGONAL
			cam.near = 0.01
			cam.far = 10.0
			_sv.add_child(cam)
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			_sv.add_child(mi)
			_fit_aabb(cam, mesh.get_aabb(), MAT_ICON_DIR.normalized())
			var tex: ImageTexture = await _snap()
			set[k] = ImageTexture.create_from_image(pixel_icon(tex.get_image(), ICON_OUTLINE))
			_sv.queue_free()
			await get_tree().process_frame
		material_textures[m] = set


## 正交相机对准一个包围盒(按 8 个角在相机平面上的投影取景)
func _fit_aabb(cam: Camera3D, box: AABB, dir: Vector3) -> void:
	var basis := Basis.looking_at(-dir, Vector3.UP)
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	var center: Vector3 = box.get_center()
	for i in range(8):
		var p: Vector3 = box.get_endpoint(i) - center
		var q := Vector2(p.dot(basis.x), p.dot(basis.y))
		lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
		hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
	var mid: Vector2 = (lo + hi) * 0.5
	cam.size = maxf(hi.x - lo.x, hi.y - lo.y) * 0.96
	cam.global_transform = Transform3D(basis, center + basis.x * mid.x + basis.y * mid.y + dir * 3.0)


## 像素图标：半透明的边缘二值化(没有抗锯齿的灰边)，四周描一圈 1 像素的深色外框
static func pixel_icon(src: Image, outline: Color) -> Image:
	var img: Image = src.duplicate() as Image
	img.convert(Image.FORMAT_RGBA8)
	var w: int = img.get_width()
	var h: int = img.get_height()
	var out := Image.create(w + 2, h + 2, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var solid := PackedByteArray()
	solid.resize((w + 2) * (h + 2))
	for y in range(h):
		for x in range(w):
			var c: Color = img.get_pixel(x, y)
			if c.a >= 0.5:
				out.set_pixel(x + 1, y + 1, Color(c.r / maxf(c.a, 0.001), c.g / maxf(c.a, 0.001), c.b / maxf(c.a, 0.001), 1.0) if c.a < 0.999 else Color(c.r, c.g, c.b, 1.0))
				solid[(y + 1) * (w + 2) + x + 1] = 1
	for y2 in range(h + 2):
		for x2 in range(w + 2):
			if solid[y2 * (w + 2) + x2] == 1:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x2 + d.x
				var ny: int = y2 + d.y
				if nx >= 0 and ny >= 0 and nx < w + 2 and ny < h + 2 and solid[ny * (w + 2) + nx] == 1:
					out.set_pixel(x2, y2, outline)
					break
	return out


func _pose_weapon(sk: Skeleton3D, cls: String) -> void:
	sk.reset_bone_poses()
	var cfg: Dictionary = ICON_POSE.get(cls, ICON_POSE["sword"])
	var r: Vector3 = cfg["rot"]
	var bi: int = sk.find_bone("Bow")
	sk.set_bone_pose_rotation(bi, Quaternion.from_euler(Vector3(deg_to_rad(r.x), deg_to_rad(r.y), deg_to_rad(r.z))))
	var li: int = sk.find_bone("Weapon_L")
	var rl: Vector3 = cfg.get("rot_l", r)
	sk.set_bone_pose_rotation(li, Quaternion.from_euler(Vector3(deg_to_rad(rl.x), deg_to_rad(rl.y), deg_to_rad(rl.z))))
	# 左手那把挪到右手那把旁边(静止时两手相距 40cm)
	var gr: Vector3 = sk.get_bone_global_rest(bi).origin
	var gl: Vector3 = sk.get_bone_global_rest(li).origin
	var shift: Vector3 = gr - gl + (cfg.get("off_l", Vector3.ZERO) as Vector3)
	sk.set_bone_pose_position(li, sk.get_bone_rest(li).origin + shift)
	var ai: int = sk.find_bone("Arrow")
	sk.set_bone_pose_scale(ai, Vector3.ONE * 0.001)
	sk.force_update_all_bone_transforms()


## 按"蒙皮后的真实顶点"在相机平面上的投影包围盒取景(正交相机)
func _fit_camera(cam: Camera3D, sk: Skeleton3D, parts: Array[MeshInstance3D], dir: Vector3) -> void:
	var skin_x: Array[Transform3D] = []
	for b in range(sk.get_bone_count()):
		skin_x.append(sk.get_bone_global_pose(b) * sk.get_bone_global_rest(b).affine_inverse())
	var pts: PackedVector3Array = PackedVector3Array()
	for mi: MeshInstance3D in parts:
		var arr: Array = mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arr[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
		var step: int = maxi(1, verts.size() / 1500)
		for i in range(0, verts.size(), step):
			var v: Vector3 = verts[i]
			var acc := Vector3.ZERO
			var wsum := 0.0
			for k in range(4):
				var w: float = weights[i * 4 + k]
				if w > 0.0:
					acc += (skin_x[bones[i * 4 + k]] * v) * w
					wsum += w
			pts.append(acc / wsum if wsum > 0.0 else v)
	var center := Vector3.ZERO
	for p: Vector3 in pts:
		center += p
	center /= maxf(1.0, float(pts.size()))
	var up_hint := Vector3.UP if absf(dir.y) < 0.95 else Vector3.FORWARD
	var basis := Basis.looking_at(-dir, up_hint)
	var right: Vector3 = basis.x
	var up: Vector3 = basis.y
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for p2: Vector3 in pts:
		var q := Vector2((p2 - center).dot(right), (p2 - center).dot(up))
		lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
		hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
	var mid: Vector2 = (lo + hi) * 0.5
	var c: Vector3 = center + right * mid.x + up * mid.y
	cam.size = maxf(hi.x - lo.x, hi.y - lo.y) * 1.14 + 0.02
	cam.global_transform = Transform3D(basis, c + dir * 4.0)


# ---------------------------------------------------------------- 共用
func _make_viewport(sz: Vector2i) -> SubViewport:
	var sv := SubViewport.new()
	sv.size = sz
	sv.transparent_bg = true
	sv.own_world_3d = true
	sv.msaa_3d = Viewport.MSAA_4X
	sv.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(sv)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#efe6dc")
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	sv.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -50, 0)
	sun.light_energy = 1.0
	sv.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, 130, 0)
	fill.light_energy = 0.4
	fill.light_color = Color("#cfe0ff")
	sv.add_child(fill)
	return sv


func _snap() -> ImageTexture:
	await get_tree().process_frame
	await get_tree().process_frame
	_sv.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = _sv.get_texture().get_image()
	return ImageTexture.create_from_image(img)
