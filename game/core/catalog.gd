class_name Catalog
extends RefCounted
## 内容目录：从 res://game/data/ 读取 JSON(单位/装备/羁绊/关卡/商店)，并做"契约校验"：
##  · 每个被动能力必须能与本单位某个触发器配对(效果必须由触发器触发)
##  · 每件装备(武器)的载荷必须要求 equipment_payload tag；每个武器大类恰好有一把"基础武器"
##  · 单位的基础武器大类必须存在；章节遭遇里的敌人/方位/武器/晶球档位必须合法
##  · 羁绊的触发器必须带 trait_payload tag 并能与其能力配对
##  · 引用的 id / 本地化键 必须存在

const DATA_DIR := "res://game/data"

var units: Dictionary = {}          # id -> UnitDef
var equipment: Dictionary = {}      # id -> EquipmentDef(武器)
var _fit_cache := {}                  # 武器 id -> 适配角色(fit_units)
var basic_weapons: Dictionary = {}  # 武器大类 -> 基础武器 EquipmentDef
var traits: Dictionary = {}         # id -> TraitDef
var relics: Dictionary = {}         # id -> {trigger, ability, ...}
var shop: Dictionary = {}
var chapters: Dictionary = {}       # id -> 章节字典(地图节点 / 遭遇 / 起始资源)
var loot: Dictionary = {}           # 晶球掉落表
var meta: Dictionary = {}           # 卡车零件等局外数据(meta.json)
var mods: Dictionary = {}           # 卡车改装：id -> {color, rarity, t_min, t_max, who, stats, pairs, rule, params, layout}(mods.json，tools/author_mods.py)
var mod_cfg: Dictionary = {}        # 改装池的参数：rarity_weights(稀有度 → 出现权重)、offer(每次选几项)
var workshop: Dictionary = {}       # 车间：材料、装备制造的概率曲线、分解(workshop.json，规则见 Crafting)
var events: Dictionary = {}         # 事件节点：id -> 事件(events.json，规则见 Events)
var arenas: Dictionary = {}         # 事件战斗的专属战场：id -> {theme, set, regions, obstacles, embers, hazards}(events.json 的 arenas)
var event_cfg: Dictionary = {}      # 事件的全局参数(稀有度权重)
var terrain_pairs: Array[Dictionary] = []   # 地形效果的"触发器 + 能力"(terrain.json)：有地形的战斗里挂到每个单位身上
var raw_units: Dictionary = {}


static func load_all() -> Catalog:
	var c := Catalog.new()
	c._load_dir("units", func(d: Dictionary) -> void:
		var u: UnitDef = UnitDef.from_dict(d)
		c.units[u.id] = u
		c.raw_units[u.id] = d)
	c._load_dir("equipment", func(d: Dictionary) -> void:
		var e: EquipmentDef = EquipmentDef.from_dict(d)
		c.equipment[e.id] = e
		if e.basic:
			c.basic_weapons[e.class_id] = e)
	c._load_dir("traits", func(d: Dictionary) -> void:
		var t: TraitDef = TraitDef.from_dict(d)
		c.traits[t.id] = t)
	c._load_dir("chapters", func(d: Dictionary) -> void:
		c.chapters[str(d["id"])] = d)
	c.shop = _read_json("%s/shop.json" % DATA_DIR)
	c.loot = _read_json("%s/loot.json" % DATA_DIR)
	c.meta = _read_json("%s/meta.json" % DATA_DIR)
	var mj: Dictionary = _read_json("%s/mods.json" % DATA_DIR)
	for m: Variant in mj.get("mods", []):
		c.mods[str((m as Dictionary)["id"])] = m
	c.mod_cfg = {"rarity_weights": mj.get("rarity_weights", {"1": 7, "2": 3, "3": 1}), "offer": int(mj.get("offer", 3))}
	c.workshop = _read_json("%s/workshop.json" % DATA_DIR)
	var evj: Dictionary = _read_json("%s/events.json" % DATA_DIR)
	for ev: Variant in evj.get("events", []):
		c.events[str((ev as Dictionary)["id"])] = ev
	c.event_cfg = {"rarity_weights": evj.get("rarity_weights", {"1": 6, "2": 3, "3": 1})}
	c.arenas = evj.get("arenas", {})
	for p: Variant in _read_json("%s/terrain.json" % DATA_DIR).get("pairs", []):
		c.terrain_pairs.append({"trigger": TriggerDef.from_dict((p as Dictionary).get("trigger", {})),
			"ability": AbilityDef.from_dict((p as Dictionary).get("ability", {}))})
	Loc.load_all()
	return c


## 卡车改装的契约：颜色 / 稀有度 / 出现时间窗合法；开局改装的摆法规则 TruckLayout 认识；属性键存在；配对的触发器带 mod_payload 并能和能力配对；
## 改写规则的名字是引擎认识的；每个改装有名字 / 说明的文本；开局(出现时间 0)必须正好是三个摆法改装
const MOD_RULES: Array[String] = ["arcane_growth", "time_management", "pearl_field", "potent_dose", "cast_guard"]


func _validate_mods() -> Array[String]:
	var errs: Array[String] = []
	var start := 0
	for id: String in mods.keys():
		var m: Dictionary = mods[id]
		if not GC.FACTIONS.has(str(m.get("color", ""))):
			errs.append("mod %s: unknown color %s" % [id, str(m.get("color", ""))])
		if int(m.get("rarity", 0)) < 1:
			errs.append("mod %s: rarity must be >= 1" % id)
		if int(m.get("t_min", 0)) > int(m.get("t_max", 0)) or int(m.get("t_min", 0)) < 0:
			errs.append("mod %s: bad appearance window %d..%d" % [id, int(m.get("t_min", 0)), int(m.get("t_max", 0))])
		if not ["all", "ranged", "melee", "enemy"].has(str(m.get("who", "all"))):
			errs.append("mod %s: unknown beneficiary %s" % [id, str(m.get("who", ""))])
		if m.has("layout"):
			if not TruckLayout.MODS.has(str(m["layout"])):
				errs.append("mod %s: unknown truck layout rule %s" % [id, str(m["layout"])])
			if int(m.get("t_min", 0)) == 0:
				start += 1
		if m.has("rule") and not MOD_RULES.has(str(m["rule"])):
			errs.append("mod %s: unknown rule %s" % [id, str(m["rule"])])
		for mode: String in ["flat", "pct"]:
			for sk: Variant in ((m.get("stats", {}) as Dictionary).get(mode, {}) as Dictionary).keys():
				if not GC.STAT_IDS.has(str(sk)):
					errs.append("mod %s: unknown stat %s" % [id, str(sk)])
		for p: Variant in m.get("pairs", []):
			var tt := TriggerDef.from_dict((p as Dictionary).get("trigger", {}))
			var ta := AbilityDef.from_dict((p as Dictionary).get("ability", {}))
			errs.append_array(tt.validate())
			errs.append_array(ta.validate())
			if not tt.tags.has("mod_payload"):
				errs.append("mod %s: trigger %s must carry the mod_payload tag" % [id, tt.id])
			if not tt.can_pair(ta):
				errs.append("mod %s: trigger %s cannot pair with ability %s" % [id, tt.id, ta.id])
			var sid: String = str(ta.effect_config.get("status_id", ""))
			if sid != "" and not Loc.has_key("status." + sid):
				errs.append("mod %s: missing loc key status.%s" % [id, sid])
		if not m.has("stats") and not m.has("pairs") and not m.has("rule") and not m.has("layout"):
			errs.append("mod %s: does nothing" % id)
		for key: String in ["name", "desc"]:
			if not Loc.has_key("mod.%s.%s" % [id, key]):
				errs.append("mod %s: missing loc key mod.%s.%s" % [id, id, key])
	if start != 3:
		errs.append("mods: the opening choice needs exactly three truck-layout mods at time 0 (has %d)" % start)
	return errs


func _load_dir(sub: String, cb: Callable) -> void:
	var path := "%s/%s" % [DATA_DIR, sub]
	var da := DirAccess.open(path)
	if da == null:
		push_error("Catalog: cannot open %s" % path)
		return
	var files: PackedStringArray = da.get_files()
	files.sort()
	for f: String in files:
		if not f.ends_with(".json"):
			continue
		var d: Dictionary = _read_json("%s/%s" % [path, f])
		if d.is_empty():
			push_error("Catalog: bad json %s/%s" % [path, f])
			continue
		cb.call(d)


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var txt: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(txt)
	if parsed is Dictionary:
		return parsed
	return {}


func get_unit(id: String) -> UnitDef:
	return units.get(id, null) as UnitDef


func get_equipment(id: String) -> EquipmentDef:
	return equipment.get(id, null) as EquipmentDef


## 某武器大类的基础武器(没有则 null)
func basic_weapon(cls: String) -> EquipmentDef:
	return basic_weapons.get(cls, null) as EquipmentDef


## 棋子实际拿在手里的武器：装备了就用装备的，否则用单位的基础武器；都没有 = 空手(null)
func resolve_weapon(def: UnitDef, weapon_id: String) -> EquipmentDef:
	if weapon_id != "":
		var e: EquipmentDef = get_equipment(weapon_id)
		if e != null:
			return e
	if def == null or def.base_weapon_class == "":
		return null
	return basic_weapon(def.base_weapon_class)


func get_trait(id: String) -> TraitDef:
	return traits.get(id, null) as TraitDef


func shop_unit_ids() -> Array[String]:
	var r: Array[String] = []
	for id: String in units.keys():
		if (units[id] as UnitDef).available_in_shop:
			r.append(id)
	r.sort()
	return r


## 武器的适配角色(FitTags：触发器和武器的三组内置标签都对上、而且装得上的棋子)；第一次问时算好缓存
func fit_units(eid: String) -> Array[String]:
	if not _fit_cache.has(eid):
		_fit_cache[eid] = FitTags.fit_units(self, get_equipment(eid))
	return _fit_cache[eid]


## 随机来源(晶球 / 黑市 / 车间)能出的武器(不含基础武器、特殊物品和 no_drop 的)
func equipment_ids() -> Array[String]:
	var r: Array[String] = []
	for id: String in equipment.keys():
		if (equipment[id] as EquipmentDef).is_gear() and not (equipment[id] as EquipmentDef).no_drop:
			r.append(id)
	r.sort()
	return r


## 车间：材料 / 装备种类 / 门类 / 颜色配比 / 分解表都要合法，文本键齐全
func _validate_workshop() -> Array[String]:
	var errs: Array[String] = []
	if workshop.is_empty():
		errs.append("workshop.json is missing")
		return errs
	for m: Variant in workshop.get("materials", []):
		if not Crafting.MATS.has(str(m)):
			errs.append("workshop: unknown material %s" % str(m))
		for key: String in ["name", "desc"]:
			if not Loc.has_key("material.%s.%s" % [str(m), key]):
				errs.append("workshop: missing loc key material.%s.%s" % [str(m), key])
	for col: String in (workshop.get("color_mix", {}) as Dictionary).keys():
		var mix: Array = workshop["color_mix"][col]
		if not GC.FACTIONS.has(col) or mix.size() != 3:
			errs.append("workshop: bad color_mix entry %s" % col)
	for id: String in equipment_ids():
		var e: EquipmentDef = get_equipment(id)
		if not (workshop.get("color_mix", {}) as Dictionary).has(e.color_id):
			errs.append("workshop: equipment %s has color %s with no color_mix (it could never be crafted)" % [id, e.color_id])
		if not (workshop.get("salvage", {}) as Dictionary).has(str(e.cost)):
			errs.append("workshop: no salvage amount for cost %d (%s)" % [e.cost, id])
	var has_weapon := false
	for k: Dictionary in workshop.get("kinds", []):
		var kid: String = str(k.get("id", ""))
		has_weapon = has_weapon or kid == "weapon"
		if not Loc.has_key("ui.workshop.kind.%s" % kid):
			errs.append("workshop: missing loc key ui.workshop.kind.%s" % kid)
		for c: Variant in k.get("categories", []):
			if kid == "weapon" and not GC.WEAPON_CLASSES.has(str(c)):
				errs.append("workshop: weapon category %s is not a weapon class" % str(c))
		if not bool(k.get("locked", false)) and (k.get("categories", []) as Array).size() < int(k.get("min_categories", 3)):
			errs.append("workshop: kind %s has fewer categories than min_categories" % kid)
	if not has_weapon:
		errs.append("workshop: the weapon kind is missing")
	return errs


## 契约校验；返回错误列表(空 = 通过)
func validate_all() -> Array[String]:
	var errs: Array[String] = []
	for id: String in units.keys():
		var u: UnitDef = units[id]
		errs.append_array(u.validate())
		for key: String in ["name", "desc"]:
			if not Loc.has_key("unit.%s.%s" % [id, key]):
				errs.append("unit %s: missing loc key unit.%s.%s" % [id, id, key])
		if u.base_weapon_class != "" and basic_weapon(u.base_weapon_class) == null:
			errs.append("unit %s: no basic weapon for its base class %s" % [id, u.base_weapon_class])
		for a: AbilityDef in u.passives:
			if a.effect_type == "summon":
				var sus: Array = a.effect_config.get("unit_pool", [a.effect_config.get("unit_id", "")])
				for su: Variant in sus:
					if not units.has(str(su)):
						errs.append("unit %s: ability %s summons unknown unit %s" % [id, a.id, str(su)])
		# 进商店的棋子：武器触发器都要有内置适配标签(FitTags；新棋子 / 改了触发器 → ./run_fitprobe.sh && python tools/author_data.py)
		if u.available_in_shop:
			for tr: TriggerDef in FitTags.payload_triggers(u):
				var ft: Dictionary = tr.fit
				if ft.is_empty():
					errs.append("unit %s: trigger %s has no fit_tags (run ./run_fitprobe.sh)" % [id, tr.id])
				elif not FitTags.SIDES.has(str(ft.get("side", ""))) or not ["multi", "single"].has(str(ft.get("count", ""))) or not ["high", "low", "never"].has(str(ft.get("freq", ""))):
					errs.append("unit %s: trigger %s has bad fit_tags %s" % [id, tr.id, str(ft)])
	for id2: String in equipment.keys():
		var e: EquipmentDef = equipment[id2]
		errs.append_array(e.validate())
		for fu: String in e.fit_add + e.fit_remove:
			if not units.has(fu):
				errs.append("equipment %s: fit_add / fit_remove names unknown unit %s" % [id2, fu])
		if not e.fit_override.is_empty() and (not FitTags.WEAPON_SIDES.has(str(e.fit_override.get("side", ""))) or not e.fit_override.has("multi") or not e.fit_override.has("basic")):
			errs.append("equipment %s: bad fit_tags %s" % [id2, str(e.fit_override)])
		for key2: String in ["name", "desc"]:
			if not Loc.has_key("equipment.%s.%s" % [id2, key2]):
				errs.append("equipment %s: missing loc key" % id2)
	for wc: String in GC.WEAPON_CLASS_IDS:
		var n := 0
		for e2: EquipmentDef in equipment.values():
			if e2.basic and e2.class_id == wc:
				n += 1
		if n != 1:
			errs.append("weapon class %s: needs exactly one basic weapon (has %d)" % [wc, n])
		for key3: String in ["name", "desc"]:
			if not Loc.has_key("wclass.%s.%s" % [wc, key3]):
				errs.append("weapon class %s: missing loc key wclass.%s.%s" % [wc, wc, key3])
	errs.append_array(_validate_mods())
	for cid: String in chapters.keys():
		var ch: Dictionary = chapters[cid]
		if not Loc.has_key("chapter.%s.name" % cid):
			errs.append("chapter %s: missing loc key" % cid)
		# 方格网章节：配怪用的怪物、阵型、精英 / 首领 / 追猎
		for mid: String in (ch.get("monsters", {}) as Dictionary).keys():
			if get_unit(mid) == null:
				errs.append("%s: unknown monster %s" % [cid, mid])
		var flist: Array = []
		var fv: Variant = ch.get("formations", [])
		if fv is Array:
			flist = fv
		else:
			for fp: String in (fv as Dictionary).keys():
				flist.append_array((fv as Dictionary)[fp])
		for fo: Variant in flist:
			for fid: Variant in ((fo as Dictionary).get("req", []) as Array) + ((fo as Dictionary).get("extra", []) as Array):
				if not (ch.get("monsters", {}) as Dictionary).has(str(fid)):
					errs.append("%s: formation uses %s which has no power entry" % [cid, str(fid)])
		for el: Variant in ch.get("elites", []):
			if get_unit(str((el as Dictionary).get("unit", ""))) == null:
				errs.append("%s: unknown elite" % cid)
			# 战斗强度是绝对刻度：精英 / 首领的本体也要有强度点数(和余烬同一个刻度)
			if ch.has("monsters") and not bool(((ch["monsters"] as Dictionary).get(str((el as Dictionary).get("unit", "")), {}) as Dictionary).get("head", false)):
				errs.append("%s: elite %s needs a monsters entry with power and head: true" % [cid, str((el as Dictionary).get("unit", ""))])
			for efo: Variant in (el as Dictionary).get("forms", []):
				for efid: Variant in ((efo as Dictionary).get("req", []) as Array) + ((efo as Dictionary).get("extra", []) as Array):
					if not (ch.get("monsters", {}) as Dictionary).has(str(efid)):
						errs.append("%s: elite formation uses %s which has no power entry" % [cid, str(efid)])
		for bk: String in ["boss", "hunt"]:
			if ch.has(bk) and get_unit(str((ch[bk] as Dictionary).get("unit", ""))) == null:
				errs.append("%s: unknown %s unit" % [cid, bk])
			if ch.has(bk) and ch.has("monsters") and not bool(((ch["monsters"] as Dictionary).get(str((ch[bk] as Dictionary).get("unit", "")), {}) as Dictionary).get("head", false)):
				errs.append("%s: %s unit needs a monsters entry with power and head: true" % [cid, bk])
		# 方格网章节：各遭遇池里的条目
		for pool: String in (ch.get("pools", {}) as Dictionary).keys():
			var pi := 0
			for pe: Variant in (ch["pools"] as Dictionary)[pool]:
				pi += 1
				for w2: Variant in (pe as Dictionary).get("units", []):
					errs.append_array(_check_wave_entry(w2 as Array, "%s pool %s #%d" % [cid, pool, pi]))
		var ni := 0
		for nd: Variant in ch.get("nodes", []):
			ni += 1
			var enc: Dictionary = (nd as Dictionary).get("encounter", {})
			for w: Variant in enc.get("units", []):
				errs.append_array(_check_wave_entry(w as Array, "%s node %d" % [cid, ni]))
				var opt: Dictionary = (w as Array)[4] if (w as Array).size() > 4 else {}
				if opt.has("orb") and not (loot.get("orbs", {}) as Dictionary).has(str(opt["orb"])):
					errs.append("%s node %d: unknown orb tier %s" % [cid, ni, str(opt["orb"])])
	for pid: String in (meta.get("parts", {}) as Dictionary).keys():
		for key4: String in ["name", "desc"]:
			if not Loc.has_key("part.%s.%s" % [pid, key4]):
				errs.append("part %s: missing loc key part.%s.%s" % [pid, pid, key4])
	errs.append_array(_validate_workshop())
	errs.append_array(Events.validate(self))
	for pair: Dictionary in terrain_pairs:
		var tt: TriggerDef = pair["trigger"]
		var ta: AbilityDef = pair["ability"]
		errs.append_array(tt.validate())
		errs.append_array(ta.validate())
		if not tt.tags.has("terrain_payload"):
			errs.append("terrain: trigger %s must carry the terrain_payload tag" % tt.id)
		if not tt.can_pair(ta):
			errs.append("terrain: trigger %s cannot pair with ability %s" % [tt.id, ta.id])
		var sid: String = str(ta.effect_config.get("status_id", ""))
		if sid != "" and not Loc.has_key("status." + sid):
			errs.append("terrain: missing loc key status.%s" % sid)
	for id3: String in traits.keys():
		var t: TraitDef = traits[id3]
		errs.append_array(t.validate())
		if not Loc.has_key("trait.%s.name" % id3):
			errs.append("trait %s: missing loc key" % id3)
	return errs


func _check_wave_entry(wu: Array, where_s: String) -> Array[String]:
	var errs: Array[String] = []
	var ud: UnitDef = get_unit(str(wu[0]))
	if ud == null:
		errs.append("%s: unknown unit %s" % [where_s, str(wu[0])])
		return errs
	var where: Variant = wu[2] if wu.size() > 2 else null
	if not (where is Array or GC.REGION_ANGLE.has(str(where))):
		errs.append("%s: %s has an unknown spawn region %s" % [where_s, ud.id, str(where)])
	var wid: String = wave_weapon_id(wu)
	if wid != "":
		var we: EquipmentDef = get_equipment(wid)
		if we == null:
			errs.append("%s: unknown weapon %s" % [where_s, wid])
		elif not ud.can_use_weapon_class(we.class_id):
			errs.append("%s: %s cannot use weapon %s" % [where_s, ud.id, wid])
	return errs


## 遭遇里敌人的出生位置(战斗坐标)：同一方位的敌人近战在前、远程在后；给出地图时避开障碍物
func wave_positions(entries: Array, map: BattleMap = null) -> Array[Vector2]:
	return GC.wave_spawn_positions(entries, func(e: Array) -> bool:
		var ud: UnitDef = get_unit(str(e[0]))
		var w: EquipmentDef = resolve_weapon(ud, wave_weapon_id(e))
		return ud != null and ud.ranged_with(w), map)


## 关卡数据里敌人的武器：[def, star, cell, weapon, {opts}]，weapon 为 id 字符串("" = 基础武器；
## 敌人也可以直接拿别的大类的基础武器，如 basic_rifle，用来展示不同武器)
static func wave_weapon_id(entry: Array) -> String:
	if entry.size() < 4:
		return ""
	var w: Variant = entry[3]
	if w is Array:
		return str((w as Array)[0]) if not (w as Array).is_empty() else ""
	return str(w)
