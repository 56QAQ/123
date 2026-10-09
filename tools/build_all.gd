extends SceneTree
## 重建 模型网格 + 角色场景。用法: godot --path . --script res://tools/build_all.gd
## (动画由 build_anims.gd 单独烘焙，场景通过路径引用 res://assets/archer_anims.res)
const Rig = preload("res://tools/rig.gd")
const VGrid = preload("res://tools/vgrid.gd")
const Mesher = preload("res://tools/mesher.gd")


func _init() -> void:
	var t0 := Time.get_ticks_msec()
	var rig = Rig.new()
	rig.build()
	print("bones: ", rig.names.size(), "  zones: ", rig.zones.size())
	var g = VGrid.new(Vector3i(-64, -12, -56), Vector3i(63, 124, 55), rig.ids, rig.mirror_of)
	var model = load("res://tools/model_archer.gd").new()
	model.build(g, rig)
	print("solid voxels: ", g.count_solid(), "  oob writes: ", g.oob_count, "  (", Time.get_ticks_msec() - t0, " ms)")
	var mesher = Mesher.new(g, rig)
	var mesh: ArrayMesh = mesher.build()
	print("mesh cells:", mesher.stats["cells"], " quads:", mesher.stats["quads"], "  (", Time.get_ticks_msec() - t0, " ms)")
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/voxel.gdshader")
	mesh.surface_set_material(0, mat)
	mesh.custom_aabb = AABB(Vector3(-2, -0.5, -2), Vector3(4, 4, 4))
	ResourceSaver.save(mesh, "res://assets/archer_mesh.res")
	var mesh2 = load("res://assets/archer_mesh.res")
	mesh2.surface_set_material(0, mat)

	# ---------------------------------------------------------- 场景
	var root := Node3D.new()
	root.name = "Archer"
	var sk: Skeleton3D = rig.make_skeleton()
	root.add_child(sk)
	var mi := MeshInstance3D.new()
	mi.name = "Body"
	mi.mesh = mesh2
	sk.add_child(mi)
	mi.skin = sk.create_skin_from_rest_transforms()
	mi.skeleton = NodePath("..")
	mi.custom_aabb = AABB(Vector3(-2, -0.5, -2), Vector3(4, 4, 4))
	_add_fx(sk)
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	root.add_child(ap)
	if ResourceLoader.exists("res://assets/archer_anims.res"):
		ap.add_animation_library("", load("res://assets/archer_anims.res"))
		ap.autoplay = "idle"
	_own(root, root)
	var ps := PackedScene.new()
	ps.pack(root)
	ResourceSaver.save(ps, "res://scenes/archer.tscn")
	_build_bow_prop(g, rig, mat)
	print("scene saved. total ", Time.get_ticks_msec() - t0, " ms")
	quit()


func _own(n: Node, o: Node) -> void:
	for c in n.get_children():
		c.owner = o
		_own(c, o)


# ---------------------------------------------------------------- 粒子：弓上/光环的青色微粒
func _sparkle_mesh() -> BoxMesh:
	var bm := BoxMesh.new()
	bm.size = Vector3(0.007, 0.007, 0.007)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.1, 0.1, 0.1)
	m.emission_enabled = true
	m.emission = Color("#7df0ff")
	m.emission_energy_multiplier = 2.6
	bm.material = m
	return bm


func _shrink_curve() -> CurveTexture:
	var c := Curve.new()
	c.add_point(Vector2(0, 0.0))
	c.add_point(Vector2(0.15, 1.0))
	c.add_point(Vector2(1, 0.0))
	var t := CurveTexture.new()
	t.curve = c
	return t


func _add_fx(sk: Skeleton3D) -> void:
	# 弓：沿弓身的漂浮微粒
	var att := BoneAttachment3D.new()
	att.name = "BowFX"
	att.bone_name = "Bow"
	sk.add_child(att)
	var pt := GPUParticles3D.new()
	pt.name = "Sparkles"
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.05, 0.55, 0.12)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.01
	pm.initial_velocity_max = 0.05
	pm.gravity = Vector3(0, 0.06, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.6
	pm.scale_curve = _shrink_curve()
	pt.process_material = pm
	pt.amount = 42
	pt.lifetime = 2.0
	pt.preprocess = 1.5
	pt.local_coords = false
	pt.draw_pass_1 = _sparkle_mesh()
	pt.visibility_aabb = AABB(Vector3(-1.5, -1.5, -1.5), Vector3(3, 3, 3))
	pt.position = Vector3(0, 0, -0.03)
	att.add_child(pt)
	# 光环：绕环的小光点
	var att2 := BoneAttachment3D.new()
	att2.name = "HaloFX"
	att2.bone_name = "Halo"
	sk.add_child(att2)
	var pt2 := GPUParticles3D.new()
	pt2.name = "Sparkles"
	var pm2 := ParticleProcessMaterial.new()
	pm2.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm2.emission_ring_axis = Vector3(0, 0, 1)
	pm2.emission_ring_radius = 0.108
	pm2.emission_ring_inner_radius = 0.104
	pm2.emission_ring_height = 0.01
	pm2.direction = Vector3(0, 1, 0)
	pm2.spread = 60.0
	pm2.initial_velocity_min = 0.01
	pm2.initial_velocity_max = 0.04
	pm2.gravity = Vector3(0, 0.05, 0)
	pm2.scale_min = 0.5
	pm2.scale_max = 1.2
	pm2.scale_curve = _shrink_curve()
	pt2.process_material = pm2
	pt2.amount = 18
	pt2.lifetime = 1.6
	pt2.preprocess = 1.0
	pt2.local_coords = false
	pt2.draw_pass_1 = _sparkle_mesh()
	pt2.visibility_aabb = AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
	att2.add_child(pt2)


# ---------------------------------------------------------------- 独立的弓(道具场景，静态网格，弦为直线)
func _build_bow_prop(g, rig, mat: ShaderMaterial) -> void:
	var bow_ids := {}
	for nm in rig.names:
		if String(nm).begins_with("Bow"):
			bow_ids[rig.ids[nm]] = true
	var g2 = VGrid.new(Vector3i(-64, -12, -56), Vector3i(63, 124, 55), rig.ids, rig.mirror_of)
	for i in range(g.col.size()):
		if g.col[i] != 0 and bow_ids.has(int(g.bn[i])):
			g2.col[i] = g.col[i]
			g2.bn[i] = g.bn[i]
			g2.gl[i] = g.gl[i]
	var m2 = Mesher.new(g2, rig)
	m2.skinned = false
	var bm: ArrayMesh = m2.build()
	bm.surface_set_material(0, mat)
	ResourceSaver.save(bm, "res://assets/bow_mesh.res")
	var bm2 = load("res://assets/bow_mesh.res")
	bm2.surface_set_material(0, mat)
	var root := Node3D.new()
	root.name = "Bow"
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = bm2
	# 让握把中心位于原点
	mi.position = -Vector3(-16.0, 44.0, 3.0) * 0.0125
	root.add_child(mi)
	var att := Node3D.new()
	att.name = "FX"
	root.add_child(att)
	var pt := _bow_particles()
	att.add_child(pt)
	_own(root, root)
	var ps := PackedScene.new()
	ps.pack(root)
	ResourceSaver.save(ps, "res://scenes/bow.tscn")


func _bow_particles() -> GPUParticles3D:
	var pt := GPUParticles3D.new()
	pt.name = "Sparkles"
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.05, 0.55, 0.12)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.01
	pm.initial_velocity_max = 0.05
	pm.gravity = Vector3(0, 0.06, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.6
	pm.scale_curve = _shrink_curve()
	pt.process_material = pm
	pt.amount = 42
	pt.lifetime = 2.0
	pt.preprocess = 1.5
	pt.local_coords = false
	pt.draw_pass_1 = _sparkle_mesh()
	pt.visibility_aabb = AABB(Vector3(-1.5, -1.5, -1.5), Vector3(3, 3, 3))
	return pt
