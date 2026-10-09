class_name UnitSkin
extends RefCounted
## 棋子模型皮肤：按"手里的武器"显隐武器网格(9 大类 × 外观；双持武器另有左手那把)与副手盾，
## 身体按阵营换色(强调色) + 按单位换发色/肤色，华丽武器按武器颜色换色，并给出该武器大类的动画名(普攻模组，所有棋子通用)；
## 待机小动作/胜利动作跟着身体模型走(char_anim)。
## 部件命名见 tools/build_kits.gd：Body(通用身体) / Body_<专属模型> / Shield / W_<大类>_<外观> / L_<大类>_<外观> / A_<大类>_<外观>(身上的附件)。
## 专属身体不在场景里：第一次用到时从 assets/unit_body_<模型>.res 加载，建一个 Body_<模型> 节点挂到骨骼上(ensure_body)。


## 外观描述：{wclass, model, color, shield, body, hair, skin}。weapon 为 null = 空手
const SKIN_REF := Color("#f8cdb8")      # 模型里的基础肤色(与着色器 SKIN_REF 一致)


static func look_for(def: UnitDef, weapon: EquipmentDef) -> Dictionary:
	var cls: String = weapon.class_id if weapon != null else ""
	var wc: Dictionary = GC.weapon_class(cls)
	var look := {
		"wclass": cls,
		# 她本人拿这件武器时的外观(变奏节点：黑键 → 大三角钢琴，按形态黑 / 白)，没写就是武器自己的外观
		"model": (def.weapon_look if weapon.basic and def.weapon_look != "" else str(def.weapon_models.get(weapon.id, weapon.model))) if weapon != null else "",
		"color": weapon.color_id if weapon != null and not weapon.basic else def.faction_id,
		# 副手盾："tower" = 大盾(武器大类有 tower_anims 时)；其他(shield / lily…) = 单手武器 + 盾(有 guard_anims 时；长枪 / 法器也单手拿)
		"shield": (def.offhand == "tower" and wc.has("tower_anims")) or (def.offhand != "" and def.offhand != "tower" and wc.has("guard_anims")),
		"shield_kind": def.offhand,
		"body": def.model,
		"skin": GC.skin_color_of(def.skin),
		"male": is_male_body(def.model),
		"overrides": (def.anim_overrides.get(cls, {}) as Dictionary).duplicate(),   # 这个棋子用这类武器时替换的动作
		"hide_weapon": def.hide_weapon,       # 武器长在身体上的怪物：手里不显示武器
	}
	set_weapon_model(look, def, str(look["model"]))
	# 发色：数据里写了就用；通用身体没写就按 id 在本色系里挑；专属模型没写就保持模型原本的发色
	if def.hair != "" or def.model == "":
		look["hair"] = GC.hair_color_of(def.id, def.faction_id, def.hair)
	return look


## 换武器外观(无我节点拔刀：odachi → odachi_drawn)，并按外观合并这个棋子"拿着这件武器时"的专属动作
## (anim_overrides["<大类>@<外观>"]：idle / run / attack，或者把某个动作名直接换成别的，例如 attack_heavy_whirl)
static func set_weapon_model(look: Dictionary, def: UnitDef, model: String) -> void:
	var cls: String = str(look.get("wclass", ""))
	look["model"] = model
	var ov: Dictionary = (def.anim_overrides.get(cls, {}) as Dictionary).duplicate()
	ov.merge(def.anim_overrides.get(cls + "@" + model, {}) as Dictionary, true)
	look["overrides"] = ov


static func skeleton_of(model: Node) -> Skeleton3D:
	return model.get_node("Skeleton3D") as Skeleton3D


## 专属身体是不是男性款(网格元数据 "male"，由 tools/chars/<模型>.gd 的 const MALE 决定)
static func is_male_body(body: String) -> bool:
	if body == "":
		return false
	var path: String = "res://assets/unit_body_%s.res" % body
	if not ResourceLoader.exists(path):
		return false
	return bool((load(path) as Resource).get_meta("male", false))


## 专属身体的身份表现(网格元数据 "identity"，由 tools/chars/<模型>.gd 的 const IDENTITY 决定)：{rim, rim_k, pulse}
static func identity_of(body: String) -> Dictionary:
	if body == "":
		return {}
	var path: String = "res://assets/unit_body_%s.res" % body
	if not ResourceLoader.exists(path):
		return {}
	return (load(path) as Resource).get_meta("identity", {})


## 确保专属身体节点存在(按需从 assets/unit_body_<body>.res 加载)；没有这个模型就返回 false(退回通用身体)
static func ensure_body(model: Node, body: String) -> bool:
	var sk: Skeleton3D = skeleton_of(model)
	var nm: String = "Body_" + body
	if sk.has_node(nm):
		return true
	var path: String = "res://assets/unit_body_%s.res" % body
	if not ResourceLoader.exists(path):
		return false
	var base: MeshInstance3D = sk.get_node("Body") as MeshInstance3D
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = load(path) as Mesh
	mi.skin = base.skin
	mi.custom_aabb = base.custom_aabb
	mi.visible = false
	sk.add_child(mi)
	mi.skeleton = NodePath("..")
	return true


## 该外观需要显示的部件名
static func part_names(model: Node, look: Dictionary) -> Array[String]:
	var sk: Skeleton3D = skeleton_of(model)
	var body: String = "Body"
	if str(look.get("body", "")) != "" and ensure_body(model, str(look["body"])):
		body = "Body_" + str(look["body"])
	var r: Array[String] = [body]
	var cls: String = str(look.get("wclass", ""))
	if bool(look.get("hide_weapon", false)):
		return r
	if cls != "":
		var m: String = str(look.get("model", "ornate"))
		if not sk.has_node("W_%s_%s" % [cls, m]):
			m = "ornate"
		r.append("W_%s_%s" % [cls, m])
		# 双持武器的左手那把；左手拿着盾时不显示(例如架盾节点拿手枪：右手一把 + 大盾)
		if int(GC.weapon_class(cls).get("hands", 1)) == 3 and not bool(look.get("shield", false)):
			r.append("L_%s_%s" % [cls, m])
		# 挂在身上的附件(炽霞的刀鞘：插在腰带上)
		if sk.has_node("A_%s_%s" % [cls, m]):
			r.append("A_%s_%s" % [cls, m])
	if bool(look.get("shield", false)):
		# 自己的盾(正行节点的百合盾 Shield_lily)：套件里有 Shield_<种类> 就用它，否则通用的盾
		var sk_name: String = "Shield_" + str(look.get("shield_kind", ""))
		r.append(sk_name if str(look.get("shield_kind", "")) != "shield" and sk.has_node(sk_name) else "Shield")
	return r


static func apply(model: Node, look: Dictionary, faction: String) -> void:
	var want: Array[String] = part_names(model, look)
	for c: Node in skeleton_of(model).get_children():
		var mi: MeshInstance3D = c as MeshInstance3D
		if mi == null:
			continue
		mi.visible = want.has(String(mi.name))
		if not mi.visible:
			continue
		var weapon_part: bool = String(mi.name).begins_with("W_") or String(mi.name).begins_with("L_") or String(mi.name).begins_with("A_")
		_tint(mi, str(look.get("color", faction)) if weapon_part else faction)
		if String(mi.name).begins_with("Body"):
			var native: Color = mi.mesh.get_meta("hair_native", Color("#eeeae9")) if mi.mesh != null else Color("#eeeae9")
			mi.set_instance_shader_parameter("hair_color", _srgb4(look.get("hair", native)))
			mi.set_instance_shader_parameter("hair_ref", native.r * 0.299 + native.g * 0.587 + native.b * 0.114)
			mi.set_instance_shader_parameter("skin_color", _srgb4(look.get("skin", SKIN_REF)))
			# 怪物的身份表现(模型的 IDENTITY)：轮廓光 + 熔岩脉动(余烬：每一种烧的火颜色不同，俯视镜头里靠它分辨)
			var ident: Dictionary = mi.mesh.get_meta("identity", {}) if mi.mesh != null else {}
			var rc: Color = Color(str(ident.get("rim", "#000000")))
			mi.set_instance_shader_parameter("rim_color", Vector4(rc.r, rc.g, rc.b, float(ident.get("rim_k", 0.0))))
			mi.set_instance_shader_parameter("lava_pulse", float(ident.get("pulse", 0.0)))
			if ident.has("rim"):
				mi.set_instance_shader_parameter("dissolve_color", rc.lightened(0.25))     # 崩解的边 = 那一种火的颜色
		else:
			mi.set_instance_shader_parameter("rim_color", Vector4(0, 0, 0, 0))
			mi.set_instance_shader_parameter("lava_pulse", 0.0)
			mi.set_instance_shader_parameter("hair_ref", 0.0)
			mi.set_instance_shader_parameter("skin_color", _srgb4(SKIN_REF))


## 顶点色是 sRGB，发色/肤色也要以 sRGB 数值进着色器：传 Vector4(传 Color 会被自动转成线性色，等于做了两次 gamma)
static func _srgb4(c: Color) -> Vector4:
	return Vector4(c.r, c.g, c.b, 1.0)


static func tint(mi: MeshInstance3D, faction: String) -> void:
	_tint(mi, faction)


static func _tint(mi: MeshInstance3D, faction: String) -> void:
	var st: Dictionary = GC.FACTION_STYLE.get(faction, GC.FACTION_STYLE["white"])
	mi.set_instance_shader_parameter("accent_hue", float(st["accent_hue"]))
	mi.set_instance_shader_parameter("accent_sat", float(st["accent_sat"]))
	mi.set_instance_shader_parameter("accent_val", float(st["accent_val"]))
	mi.set_instance_shader_parameter("dissolve_color", (st["color"] as Color).lightened(0.35))


## 对所有可见部件设置着色器参数(受击闪白/溶解/发光)
static func set_param(model: Node, name: String, value: Variant) -> void:
	for c: Node in skeleton_of(model).get_children():
		var mi: MeshInstance3D = c as MeshInstance3D
		if mi != null and mi.visible:
			mi.set_instance_shader_parameter(name, value)


## 跟着身体模型走的动作(与武器无关)：kind = fidget(待机小动作) / victory(胜利)；
## 专属模型用自己那套(fidget_dancer…)，通用模型用不带后缀的；AnimationPlayer 里没有就退回通用的
static func char_anim(look: Dictionary, kind: String) -> String:
	var body: String = str(look.get("body", ""))
	return kind if body == "" else "%s_%s" % [kind, body]


## 动画名：which = idle / run / attack
static func anim(look: Dictionary, which: String) -> String:
	var cls: String = str(look.get("wclass", ""))
	if cls == "":
		return _gendered(str(GC.UNARMED_ANIMS.get(which, "idle_unarmed")), look, which)
	var ov: Dictionary = look.get("overrides", {})
	if ov.has(which):
		return _gendered(str(ov[which]), look, which)
	var wc: Dictionary = GC.weapon_class(cls)
	var set: Dictionary = wc["anims"]
	if bool(look.get("shield", false)):
		var key: String = "tower_anims" if str(look.get("shield_kind", "")) == "tower" else "guard_anims"
		set = wc.get(key, wc.get("guard_anims", wc["anims"]))
	return _gendered(str(set.get(which, "idle")), look, which)


## 男性模型的待机/跑步用 *_m 版(站姿、摆臂不同)；攻击男女共用
static func _gendered(nm: String, look: Dictionary, which: String) -> String:
	return nm + "_m" if bool(look.get("male", false)) and (which == "idle" or which == "run") else nm
