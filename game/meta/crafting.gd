class_name Crafting
extends RefCounted
## 车间(装备制造)的规则：纯函数，不依赖场景树(Run 调它，界面也用它来画预测)。数值都在 game/data/workshop.json(author_chapters.py 的 WORKSHOP)。
##  · 三种材料，内部名 = 颜色：red 燃素 / green 有机物 / blue 液态负熵。
##  · 装备种类(kind)：现在只有武器；别的种类留接口——装备数据写 "slot" = 种类 id，门类 = 它的 class_id，workshop.json 里登记门类即可。
##  · 颜色：材料配比 p = (r, g, b) / 合计；每种装备颜色有一个理想配比(color_mix)，权重 = prior × exp(-|p - 理想|² / 2σ²)，配比连续变化概率也连续变化。
##  · 稀有度(费用)：材料合计 N 越多越贵，权重 = exp(-(费用 - μ)² / 2σ²)，μ = base + (N - min_total) × per_material。
##  · 联合分布只在选中门类里实际存在的(颜色, 费用)格子之间归一化；同一格子里的装备等概率。

const MATS: Array[String] = ["red", "green", "blue"]
const COSTS: Array[int] = [1, 2, 3, 4, 5]


static func cfg(cat: Catalog) -> Dictionary:
	return cat.workshop


static func kinds(cat: Catalog) -> Array:
	return cfg(cat).get("kinds", [])


static func kind_cfg(cat: Catalog, kind: String) -> Dictionary:
	for k: Dictionary in kinds(cat):
		if str(k.get("id", "")) == kind:
			return k
	return {}


static func min_categories(cat: Catalog, kind: String) -> int:
	return int(kind_cfg(cat, kind).get("min_categories", 3))


static func total(mats: Dictionary) -> int:
	var n := 0
	for m: String in MATS:
		n += int(mats.get(m, 0))
	return n


static func empty_mats() -> Dictionary:
	return {"red": 0, "green": 0, "blue": 0}


## 某件装备属于哪个种类(装备数据的 slot；武器 = "weapon")
static func slot_of(e: EquipmentDef) -> String:
	return e.slot


## 选中门类里能造出来的装备(和晶球掉落同一个池子：不含基础武器、不含示例武器)
static func candidates(cat: Catalog, kind: String, cats: Array) -> Array[String]:
	var r: Array[String] = []
	var kc: Dictionary = kind_cfg(cat, kind)
	if kc.is_empty() or bool(kc.get("locked", false)):
		return r
	for id: String in cat.equipment_ids():
		var e: EquipmentDef = cat.get_equipment(id)
		if id.begins_with("sample_") or slot_of(e) != kind:
			continue
		if cats.has(e.class_id):
			r.append(id)
	return r


## 颜色权重(未归一化，不看有没有这种颜色的装备)：配比落在三角形里，离哪种颜色的理想配比越近权重越大
static func color_weights(cat: Catalog, mats: Dictionary) -> Dictionary:
	var c: Dictionary = cfg(cat)
	var n: int = total(mats)
	var w: Dictionary = {}
	if n <= 0:
		return w
	var p := Vector3(float(mats.get("red", 0)), float(mats.get("green", 0)), float(mats.get("blue", 0))) / float(n)
	var s: float = float(c.get("color_sigma", 0.35))
	var prior: Dictionary = c.get("color_prior", {})
	var mix: Dictionary = c.get("color_mix", {})
	for col: String in mix.keys():
		var m: Array = mix[col]
		var ideal := Vector3(float(m[0]), float(m[1]), float(m[2]))
		w[col] = float(prior.get(col, 1.0)) * exp(-p.distance_squared_to(ideal) / (2.0 * s * s))
	return w


## 稀有度(费用)权重(未归一化)
static func rarity_weights(cat: Catalog, n: int) -> Dictionary:
	var rc: Dictionary = cfg(cat).get("rarity", {})
	var mu: float = rarity_center(cat, n)
	var s: float = float(rc.get("sigma", 0.55))
	var w: Dictionary = {}
	for k: int in COSTS:
		w[k] = exp(-pow(float(k) - mu, 2.0) / (2.0 * s * s))
	return w


## 材料合计 N 时稀有度曲线的中心(期望的费用)
static func rarity_center(cat: Catalog, n: int) -> float:
	var c: Dictionary = cfg(cat)
	var rc: Dictionary = c.get("rarity", {})
	return float(rc.get("base", 1.0)) + float(n - int(c.get("min_total", 3))) * float(rc.get("per_material", 1.0 / 7.0))


## 投入检查：返回本地化键(空串 = 可以制造)。owned = 持有的材料
static func problem(cat: Catalog, kind: String, cats: Array, mats: Dictionary, owned: Dictionary) -> String:
	var kc: Dictionary = kind_cfg(cat, kind)
	if kc.is_empty() or bool(kc.get("locked", false)):
		return "ui.err.craft_locked"
	var valid: Array = kc.get("categories", [])
	var nc := 0
	for c2: Variant in cats:
		if valid.has(str(c2)):
			nc += 1
	if nc < min_categories(cat, kind):
		return "ui.err.craft_categories"
	for m: String in MATS:
		if int(mats.get(m, 0)) < 0 or int(mats.get(m, 0)) > int(owned.get(m, 0)):
			return "ui.err.craft_materials"
	var n: int = total(mats)
	if n < int(cfg(cat).get("min_total", 3)):
		return "ui.err.craft_too_few"
	if n > int(cfg(cat).get("max_total", 30)):
		return "ui.err.craft_too_many"
	if candidates(cat, kind, cats).is_empty():
		return "ui.err.craft_nothing"
	return ""


## 产出预测：{colors: {颜色: 概率}, costs: {费用: 概率}, items: [[id, 概率], …](从高到低)}；投入为空 / 没有候选 = 全空
static func forecast(cat: Catalog, kind: String, cats: Array, mats: Dictionary) -> Dictionary:
	var out := {"colors": {}, "costs": {}, "items": []}
	var ids: Array[String] = candidates(cat, kind, cats)
	var n: int = total(mats)
	if ids.is_empty() or n <= 0:
		return out
	var cw: Dictionary = color_weights(cat, mats)
	var rw: Dictionary = rarity_weights(cat, n)
	# (颜色, 费用) 格子 → 里面的装备
	var cells: Dictionary = {}
	for id: String in ids:
		var e: EquipmentDef = cat.get_equipment(id)
		var key: String = "%s|%d" % [e.color_id, e.cost]
		if not cells.has(key):
			cells[key] = []
		(cells[key] as Array).append(id)
	var wsum := 0.0
	var cell_w: Dictionary = {}
	for key2: String in cells.keys():
		var parts: PackedStringArray = key2.split("|")
		var w: float = float(cw.get(parts[0], 0.0)) * float(rw.get(int(parts[1]), 0.0))
		cell_w[key2] = w
		wsum += w
	if wsum <= 0.0:
		# 极端配比下所有格子的权重都下溢成 0：退回只按稀有度
		for key3: String in cells.keys():
			cell_w[key3] = float(rw.get(int(key3.split("|")[1]), 0.0)) + 1e-9
			wsum += float(cell_w[key3])
	var colors: Dictionary = {}
	var costs: Dictionary = {}
	var items: Array = []
	for key4: String in cells.keys():
		var p: float = float(cell_w[key4]) / wsum
		var parts2: PackedStringArray = key4.split("|")
		colors[parts2[0]] = float(colors.get(parts2[0], 0.0)) + p
		costs[int(parts2[1])] = float(costs.get(int(parts2[1]), 0.0)) + p
		var list: Array = cells[key4]
		for id2: Variant in list:
			items.append([str(id2), p / float(list.size())])
	items.sort_custom(func(a: Array, b: Array) -> bool:
		return float(a[1]) > float(b[1]) if not is_equal_approx(float(a[1]), float(b[1])) else str(a[0]) < str(b[0]))
	out["colors"] = colors
	out["costs"] = costs
	out["items"] = items
	return out


## 按预测抽一件
static func roll(cat: Catalog, kind: String, cats: Array, mats: Dictionary, rng: RandomNumberGenerator) -> String:
	var items: Array = forecast(cat, kind, cats, mats)["items"]
	if items.is_empty():
		return ""
	var x: float = rng.randf()
	for it: Array in items:
		x -= float(it[1])
		if x <= 0.0:
			return str(it[0])
	return str((items.back() as Array)[0])


## 分解一件装备得到的材料：份数按费用，按装备颜色的理想配比分(余数给小数部分最大的，平手按 红 → 绿 → 蓝)
static func salvage_yield(cat: Catalog, equip_id: String) -> Dictionary:
	var e: EquipmentDef = cat.get_equipment(equip_id)
	var out: Dictionary = empty_mats()
	if e == null or e.basic:
		return out
	var c: Dictionary = cfg(cat)
	var amount: int = int((c.get("salvage", {}) as Dictionary).get(str(e.cost), e.cost * 2))
	var mix: Array = (c.get("color_mix", {}) as Dictionary).get(e.color_id, [0.3333, 0.3333, 0.3333])
	var fsum := 0.0
	for v: Variant in mix:
		fsum += float(v)
	var given := 0
	var fracs: Array = []
	for i in range(MATS.size()):
		var share: float = float(amount) * float(mix[i]) / maxf(0.0001, fsum)
		var whole: int = int(floor(share + 1e-6))
		out[MATS[i]] = whole
		given += whole
		fracs.append([share - float(whole), i])
	fracs.sort_custom(func(a: Array, b: Array) -> bool:
		return float(a[0]) > float(b[0]) + 1e-6 or (absf(float(a[0]) - float(b[0])) <= 1e-6 and int(a[1]) < int(b[1])))
	var k := 0
	while given < amount and k < fracs.size():
		var mi: int = int(fracs[k][1])
		if float(mix[mi]) > 0.0:
			out[MATS[mi]] = int(out[MATS[mi]]) + 1
			given += 1
		k += 1
	return out


## 晶球附带的材料：n 份，每份按章节的 material_weights 随机颜色
static func roll_orb_materials(cat: Catalog, tier: String, weights: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var out: Dictionary = empty_mats()
	var n: int = int((cfg(cat).get("orb_materials", {}) as Dictionary).get(tier, 0))
	var wsum := 0.0
	for m: String in MATS:
		wsum += float(weights.get(m, 1.0))
	for i in range(n):
		var x: float = rng.randf() * wsum
		var pick: String = MATS[MATS.size() - 1]
		for m2: String in MATS:
			x -= float(weights.get(m2, 1.0))
			if x <= 0.0:
				pick = m2
				break
		out[pick] = int(out[pick]) + 1
	return out


## 配比在三角形里的位置(界面画图用)：顶点 = 燃素，左下 = 有机物，右下 = 液态负熵；返回重心坐标的权重 (r, g, b)
static func ratio(mats: Dictionary) -> Vector3:
	var n: int = total(mats)
	if n <= 0:
		return Vector3(1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0)
	return Vector3(float(mats.get("red", 0)), float(mats.get("green", 0)), float(mats.get("blue", 0))) / float(n)
