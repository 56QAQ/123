class_name Events
extends RefCounted
## 事件节点的规则(纯逻辑，Run 调它)：事件池、按稀有度抽取、选项条件。数据在 game/data/events.json(tools/author_events.py)。
##   事件池 pool.type：
##     common     通用：总是可以出现；出现后移出事件池(本局不再出现)
##     chapter    特定章节：只在第 n 章出现(章节数据的 chapter_no；第一章 = 红 / 绿 / 蓝之章)；出现后移出事件池
##     color      特定颜色：只在包含这种颜色的章节出现(章节颜色按 GC.FACTION_CONTRIBUTIONS 展开：紫之章 = 红 + 蓝 + 紫，黑之章 = 全部)；本章不再重复
##     exclusive  限定：只在某一个章节(章节 id)出现；本章不再重复
##     fallback   兜底：池子里没有能出的事件时用(不参与抽取)
##   稀有度 1~3：抽取权重 rarity_weights(1 最常见)

const POOL_TYPES: Array[String] = ["common", "chapter", "color", "exclusive", "fallback"]
const REQ_TYPES: Array[String] = ["truck_hp_above", "ranged_attack_at_least", "gold_at_least", "materials_at_least", "level_at_least", "ap_at_least",
	"roster_at_least", "has_weapon", "has_part", "picked_at_least", "picked_below"]
const EFFECT_TYPES: Array[String] = ["truck_damage", "materials", "gold", "xp", "ap", "reveal", "battle",
	"truck_heal", "truck_max", "unit", "weapon", "orb", "perm", "star_up", "lose_unit", "lose_weapon", "lose_part", "part", "flag"]
const HAZARD_TYPES: Array[String] = ["sweep", "eruption"]
## 局内状态(诅咒 / 祝福，Run.flags)：下一场敌人强度 ± / 本章节点制造按高(低)几级的概率抽 / 本章每个节点的收入 ±
const FLAG_IDS: Array[String] = ["next_battle_intensity", "shop_odds_shift", "income_bonus"]
const FLAG_UNTIL: Array[String] = ["next_battle", "chapter", "run"]
## 收益类效果(纯负面事件里不许出现)
const GAIN_EFFECTS: Array[String] = ["xp", "reveal", "truck_heal", "unit", "weapon", "orb", "perm", "star_up", "part"]


## 章节包含的颜色：红之章 = [red]；紫之章 = [red, blue, purple]；黑之章 = 全部
static func chapter_colors(chapter: Dictionary) -> Array:
	return GC.faction_contributions(str(chapter.get("color", "white")))


## 这个效果是不是收益(纯负面事件里不许有)：正的金币 / 材料 / 行动力，或者任何给东西的效果
static func is_gain(ef: Dictionary) -> bool:
	var et: String = str(ef.get("type", ""))
	if GAIN_EFFECTS.has(et):
		return true
	match et:
		"gold", "ap":
			return int(ef.get("amount", 0)) > 0
		"materials":
			for m: String in Crafting.MATS:
				if int(ef.get(m, 0)) > 0:
					return true
		"truck_max":
			return int(ef.get("amount", 0)) > 0
		"flag":
			return str(ef.get("id", "")) != "next_battle_intensity" or float(ef.get("value", 0)) < 0.0
	return false


## 这个事件的池子允不允许它在这个章节出现(不看出没出现过)
static func pool_fits(ev: Dictionary, chapter_id: String, chapter: Dictionary) -> bool:
	var pool: Dictionary = ev.get("pool", {})
	match str(pool.get("type", "")):
		"common":
			return true
		"chapter":
			return int(pool.get("chapter", -1)) == int(chapter.get("chapter_no", -2))
		"color":
			return chapter_colors(chapter).has(str(pool.get("color", "")))
		"exclusive":
			return str(pool.get("chapter", "")) == chapter_id
	return false


## 出现过以后是不是整局都移出池子(通用 / 特定章节)；颜色 / 限定事件只是同一章里不再出现
static func removed_for_run(ev: Dictionary) -> bool:
	var t: String = str((ev.get("pool", {}) as Dictionary).get("type", ""))
	return t == "common" or t == "chapter"


static func fallback_id(cat: Catalog) -> String:
	var ids: Array = cat.events.keys()
	ids.sort()
	for id: Variant in ids:
		if str(((cat.events[id] as Dictionary).get("pool", {}) as Dictionary).get("type", "")) == "fallback":
			return str(id)
	return ""


## 当前能抽到的事件(按 id 排序，保证同一个种子结果一样)
static func candidates(cat: Catalog, run: Run) -> Array[String]:
	var r: Array[String] = []
	var ids: Array = cat.events.keys()
	ids.sort()
	for id: Variant in ids:
		var ev: Dictionary = cat.events[id]
		if str((ev.get("pool", {}) as Dictionary).get("type", "")) == "fallback":
			continue
		if not pool_fits(ev, run.chapter_id, run.chapter):
			continue
		if run.events_gone.has(str(id)) or run.events_this_chapter.has(str(id)):
			continue
		r.append(str(id))
	return r


static func rarity_weight(cat: Catalog, ev: Dictionary, luck: Dictionary = {}) -> float:
	var w: float = float((cat.event_cfg.get("rarity_weights", {}) as Dictionary).get(str(int(ev.get("rarity", 1))), 1.0))
	# 真骰(巧运节点)：高稀有度的事件更容易遇到(cfg.event_rarity_mult：稀有度 → 权重倍率)
	return w * float((luck.get("event_rarity_mult", {}) as Dictionary).get(str(int(ev.get("rarity", 1))), 1.0))


## 按稀有度加权抽一个；池子空了就用兜底事件
static func pick(cat: Catalog, run: Run, rng: RandomNumberGenerator) -> String:
	var c: Array[String] = candidates(cat, run)
	if c.is_empty():
		return fallback_id(cat)
	var luck: Dictionary = run.luck_cfg() if run != null else {}
	var total := 0.0
	for id: String in c:
		total += rarity_weight(cat, cat.events[id], luck)
	var x: float = rng.randf() * total
	for id2: String in c:
		x -= rarity_weight(cat, cat.events[id2], luck)
		if x <= 0.0:
			return id2
	return c.back()


## 手持远程武器的节点里攻击力最高的一个(场上的和仓库里的都算)：{roster_id, def, attack}；没有 = {}
static func best_ranged(run: Run) -> Dictionary:
	var best: Dictionary = {}
	var ids: Array = run.roster.keys()
	ids.sort()
	for rid: Variant in ids:
		var u: Dictionary = run.roster[rid]
		var w: EquipmentDef = run.weapon_of(u)
		if w == null or not run.unit_def(u).ranged_with(w):       # 单位自己改成远程的武器也算(清扫节点的飞刀)
			continue
		var atk: float = run.unit_attack(u)
		if best.is_empty() or atk > float(best["attack"]):
			best = {"roster_id": str(rid), "def": str(u["def"]), "attack": atk}
	return best


## 这个选项已经选过几次(可重复的选项)
static func picked(run: Run, opt_id: String) -> int:
	return int((run.event_state.get("picks", {}) as Dictionary).get(opt_id, 0))


## 选项能不能选：{ok, reqs: [{type, value, ok, who(满足条件的节点 def), who_value}]}
## 可重复的选项(repeat.max)选满了、或者被某个结果关掉了(closed)，也算条件不满足(reqs 里有一条 repeat_done / closed)
static func check_option(cat: Catalog, run: Run, ev_id: String, i: int) -> Dictionary:
	var ev: Dictionary = cat.events.get(ev_id, {})
	var opts: Array = ev.get("options", [])
	if i < 0 or i >= opts.size():
		return {"ok": false, "reqs": []}
	var opt: Dictionary = opts[i]
	var oid: String = str(opt.get("id", ""))
	var n_picked: int = picked(run, oid)
	var all_ok := true
	var reqs: Array = []
	if opt.has("repeat"):
		var mx: int = int((opt["repeat"] as Dictionary).get("max", 0))
		if mx > 0 and n_picked >= mx:
			reqs.append({"type": "repeat_done", "value": mx, "ok": false})
			all_ok = false
	if (run.event_state.get("closed", []) as Array).has(oid):
		reqs.append({"type": "closed", "value": 0, "ok": false})
		all_ok = false
	for rq: Dictionary in opt.get("requires", []):
		var e: Dictionary = {"type": str(rq.get("type", "")), "value": rq.get("value", 0), "ok": false}
		match e["type"]:
			"truck_hp_above":
				e["ok"] = run.truck_hp > int(rq.get("value", 0))
				e["who_value"] = run.truck_hp
			"ranged_attack_at_least":
				var b: Dictionary = best_ranged(run)
				if not b.is_empty():
					e["who"] = b["def"]
					e["who_value"] = int(floor(float(b["attack"])))
					e["ok"] = float(b["attack"]) + 0.001 >= float(rq.get("value", 0))
			"gold_at_least":
				# 可重复的选项每选一次涨 per_pick 金币
				var need: int = int(rq.get("value", 0)) + int(rq.get("per_pick", 0)) * n_picked
				e["value"] = need
				e["ok"] = run.gold >= need
				e["who_value"] = run.gold
			"materials_at_least":
				var col: String = str(rq.get("color", ""))
				var least := 999999
				for m: String in Crafting.MATS:
					if col == "" or col == m:
						least = mini(least, int(run.materials.get(m, 0)))
				e["who"] = col
				e["who_value"] = least
				e["ok"] = least >= int(rq.get("value", 0))
			"level_at_least":
				e["ok"] = run.level >= int(rq.get("value", 0))
				e["who_value"] = run.level
			"ap_at_least":
				e["ok"] = run.ap >= int(rq.get("value", 0))
				e["who_value"] = run.ap
			"roster_at_least":
				e["ok"] = run.roster.size() >= int(rq.get("value", 0))
				e["who_value"] = run.roster.size()
			"has_weapon":
				e["ok"] = not run.spare_weapons().is_empty()
				e["who_value"] = run.spare_weapons().size()
			"has_part":
				e["ok"] = not run.parts.is_empty()
				e["who_value"] = run.parts.size()
			"picked_at_least":
				e["who"] = str(rq.get("option", ""))
				e["who_value"] = picked(run, str(rq.get("option", "")))
				e["ok"] = int(e["who_value"]) >= int(rq.get("value", 0))
			"picked_below":
				e["who"] = str(rq.get("option", ""))
				e["who_value"] = picked(run, str(rq.get("option", "")))
				e["ok"] = int(e["who_value"]) < int(rq.get("value", 0))
		if not bool(e["ok"]):
			all_ok = false
		reqs.append(e)
	return {"ok": all_ok, "reqs": reqs}


## 这个选项第 n_picked + 1 次选时用哪一组结果：by_pick = 按次数的几组结果(超出用最后一组)，否则就是 outcomes
static func option_outcomes(opt: Dictionary, n_picked: int) -> Array:
	if opt.has("by_pick"):
		var bp: Array = opt["by_pick"]
		if not bp.is_empty():
			return bp[mini(maxi(0, n_picked), bp.size() - 1)]
	return opt.get("outcomes", [])


## 一个选项全部可能的结果(所有次数的)：校验 / 纯负面检查用
static func all_outcomes(opt: Dictionary) -> Array:
	var r: Array = []
	if opt.has("by_pick"):
		for outs: Variant in opt["by_pick"]:
			r.append_array(outs as Array)
	else:
		r.append_array(opt.get("outcomes", []))
	return r


## 按权重抽一个结果
## lucky(真骰)：结果有明确好坏(结果写了 luck：越大越好)时掷两次，取好的那个
static func roll_outcome(opt: Dictionary, rng: RandomNumberGenerator, n_picked: int = 0, lucky: bool = false) -> Dictionary:
	var outs: Array = option_outcomes(opt, n_picked)
	var r: Dictionary = roll_from(outs, rng)
	var ranked := false
	for o: Variant in outs:
		if (o as Dictionary).has("luck"):
			ranked = true
	if lucky and ranked and outs.size() > 1:
		var r2: Dictionary = roll_from(outs, rng)
		if int(r2.get("luck", 0)) > int(r.get("luck", 0)):
			r = r2
	return r


static func roll_from(outs: Array, rng: RandomNumberGenerator) -> Dictionary:
	if outs.is_empty():
		return {"id": "", "effects": []}
	var total := 0.0
	for o: Dictionary in outs:
		total += float(o.get("w", 1))
	var x: float = rng.randf() * total
	for o2: Dictionary in outs:
		x -= float(o2.get("w", 1))
		if x <= 0.0:
			return o2
	return outs.back()


## 一个效果(含 fallback 里的那个)合不合法；errs 里加说明
static func _validate_effect(cat: Catalog, id: String, ef: Dictionary, errs: Array[String]) -> void:
	var et: String = str(ef.get("type", ""))
	if not EFFECT_TYPES.has(et):
		errs.append("event %s: unknown effect %s" % [id, et])
	match et:
		"unit":
			if ef.has("id"):
				if not cat.units.has(str(ef["id"])):
					errs.append("event %s: unit effect names an unknown unit %s" % [id, str(ef["id"])])
			else:
				var any := false
				for uid: String in cat.shop_unit_ids():
					if cat.get_unit(uid).cost == int(ef.get("cost", 1)):
						any = true
				if not any:
					errs.append("event %s: no shop unit costs %d" % [id, int(ef.get("cost", 1))])
		"weapon":
			if ef.has("id") and not cat.equipment.has(str(ef["id"])):
				errs.append("event %s: weapon effect names an unknown weapon %s" % [id, str(ef["id"])])
		"orb":
			if not (cat.loot.get("orbs", {}) as Dictionary).has(str(ef.get("tier", ""))):
				errs.append("event %s: unknown orb tier %s" % [id, str(ef.get("tier", ""))])
		"perm":
			var probe := StatBlock.new()
			for st: String in (ef.get("stats", {}) as Dictionary).keys():
				if probe.get(st) == null:
					errs.append("event %s: perm effect uses an unknown stat %s" % [id, st])
		"part":
			if ef.has("id") and str(ef["id"]) != "random" and not (cat.meta.get("parts", {}) as Dictionary).has(str(ef["id"])):
				errs.append("event %s: part effect names an unknown part %s" % [id, str(ef["id"])])
		"flag":
			if not FLAG_IDS.has(str(ef.get("id", ""))):
				errs.append("event %s: unknown flag %s" % [id, str(ef.get("id", ""))])
			if not FLAG_UNTIL.has(str(ef.get("until", "chapter"))):
				errs.append("event %s: flag %s has a bad duration %s" % [id, str(ef.get("id", "")), str(ef.get("until", ""))])
	for orb: Variant in ef.get("orbs", []):
		if not (cat.loot.get("orbs", {}) as Dictionary).has(str(orb)):
			errs.append("event %s: unknown orb tier %s" % [id, str(orb)])
	for fo: Dictionary in ef.get("fixed", []):
		if not ResourceLoader.exists("res://assets/world/%s.res" % str(fo.get("style", ""))):
			errs.append("event %s: fixed obstacle %s has no model" % [id, str(fo.get("style", ""))])
	if ef.has("fallback"):
		_validate_effect(cat, id, ef["fallback"], errs)


## 契约校验：池子 / 稀有度 / 条件 / 效果都合法，文本键齐全，战斗地图上固定放的障碍要有模型，专属战场存在且和事件画面是同一个布景
static func validate(cat: Catalog) -> Array[String]:
	var errs: Array[String] = []
	var has_fallback := false
	for id: String in cat.events.keys():
		var ev: Dictionary = cat.events[id]
		var pt: String = str((ev.get("pool", {}) as Dictionary).get("type", ""))
		if not POOL_TYPES.has(pt):
			errs.append("event %s: unknown pool type %s" % [id, pt])
		has_fallback = has_fallback or pt == "fallback"
		if pt == "exclusive" and not cat.chapters.has(str(ev["pool"].get("chapter", ""))):
			errs.append("event %s: exclusive to unknown chapter %s" % [id, str(ev["pool"].get("chapter", ""))])
		var rar: int = int(ev.get("rarity", 0))
		if rar < 1 or rar > 3:
			errs.append("event %s: rarity must be 1~3" % id)
		if str(ev.get("scene", "")) == "":
			errs.append("event %s: needs a scene" % id)
		for key: String in ["title", "body"]:
			if not Loc.has_key("event.%s.%s" % [id, key]):
				errs.append("event %s: missing loc key event.%s.%s" % [id, id, key])
		var opts: Array = ev.get("options", [])
		if opts.is_empty():
			errs.append("event %s: needs at least one option" % id)
		var opt_ids: Array[String] = []
		for o0: Dictionary in opts:
			opt_ids.append(str(o0.get("id", "")))
		var has_repeat := false
		var has_exit := false
		for o: Dictionary in opts:
			var oid: String = str(o.get("id", ""))
			if not Loc.has_key("event.%s.opt.%s" % [id, oid]):
				errs.append("event %s: missing loc key event.%s.opt.%s" % [id, id, oid])
			for rq: Dictionary in o.get("requires", []):
				if not REQ_TYPES.has(str(rq.get("type", ""))):
					errs.append("event %s: unknown requirement %s" % [id, str(rq.get("type", ""))])
				if (str(rq.get("type", "")) == "picked_at_least" or str(rq.get("type", "")) == "picked_below") and not opt_ids.has(str(rq.get("option", ""))):
					errs.append("event %s option %s: counts picks of an unknown option %s" % [id, oid, str(rq.get("option", ""))])
			if o.has("repeat"):
				has_repeat = true
				if int((o["repeat"] as Dictionary).get("max", 0)) <= 0:
					errs.append("event %s option %s: a repeatable option needs repeat.max" % [id, oid])
			else:
				has_exit = true
			var lists: Array = o["by_pick"] if o.has("by_pick") else [o.get("outcomes", [])]
			if lists.is_empty():
				errs.append("event %s option %s: needs an outcome" % [id, oid])
			for outs: Variant in lists:
				if (outs as Array).is_empty():
					errs.append("event %s option %s: needs an outcome" % [id, oid])
			for oc: Dictionary in all_outcomes(o):
				if not Loc.has_key("event.%s.res.%s" % [id, str(oc.get("id", ""))]):
					errs.append("event %s: missing loc key event.%s.res.%s" % [id, id, str(oc.get("id", ""))])
				for cid: Variant in oc.get("close", []):
					if not opt_ids.has(str(cid)):
						errs.append("event %s option %s: closes an unknown option %s" % [id, oid, str(cid)])
				for ef: Dictionary in oc.get("effects", []):
					_validate_effect(cat, id, ef, errs)
					if ef.has("arena"):
						if not cat.arenas.has(str(ef["arena"])):
							errs.append("event %s: unknown arena %s" % [id, str(ef["arena"])])
						elif str(ev.get("scene", "")) != str((cat.arenas[str(ef["arena"])] as Dictionary).get("set", "")):
							errs.append("event %s: its scene must be the set of its arena %s (the event picture and the battlefield are one place)" % [id, str(ef["arena"])])
		if has_repeat and not has_exit:
			errs.append("event %s: a repeatable option needs a plain option to leave by" % id)
		if bool(ev.get("negative", false)):
			for o2: Dictionary in opts:
				for oc2: Dictionary in all_outcomes(o2):
					for ef2: Dictionary in oc2.get("effects", []):
						if is_gain(ef2):
							errs.append("event %s is purely negative but option %s gains something (%s)" % [id, str(o2.get("id", "")), str(ef2.get("type", ""))])
		for pr: Dictionary in ev.get("props", []):
			if str(pr.get("kind", "model")) == "model" and not ResourceLoader.exists("res://assets/world/%s.res" % str(pr.get("model", ""))):
				errs.append("event %s: scene prop %s has no model" % [id, str(pr.get("model", ""))])
	if not cat.events.is_empty() and not has_fallback:
		errs.append("events: a fallback event is required")
	errs.append_array(validate_arenas(cat))
	return errs


# ------------------------------------------------------------------ 事件战斗的专属战场(Catalog.arenas，数据在 author_events.py 的 ARENAS)
## 专属战场的战斗地图：障碍 / 余烬地块 / 战场机制都是定好的(不随机生成)。layout.arena / layout.set 给表现层搭布景用
static func arena_layout(cat: Catalog, arena_id: String) -> Dictionary:
	var a: Dictionary = cat.arenas.get(arena_id, {})
	return {"obstacles": (a.get("obstacles", []) as Array).duplicate(true), "embers": (a.get("embers", []) as Array).duplicate(true),
		"hazards": (a.get("hazards", []) as Array).duplicate(true), "theme": str(a.get("theme", "white")),
		"arena": arena_id, "set": str(a.get("set", "")), "cam_z": float(a.get("cam_z", 0.0)), "seed": 0}


## 专属战场的契约：障碍物有模型、在地图里、不占我方部署区和敌人出生点，地图连通；余烬地块在空地上；战场机制的类型认识、
## 喷发的落点是存在的余烬地块；名字和规则说明的文本键齐全
static func validate_arenas(cat: Catalog) -> Array[String]:
	var errs: Array[String] = []
	for aid: String in cat.arenas.keys():
		var a: Dictionary = cat.arenas[aid]
		for key: String in ["name", "rule"]:
			if not Loc.has_key("arena.%s.%s" % [aid, key]):
				errs.append("arena %s: missing loc key arena.%s.%s" % [aid, aid, key])
		var keep: Array[Vector2i] = []
		for rg: Variant in a.get("regions", []):
			if not GC.REGION_ANGLE.has(str(rg)):
				errs.append("arena %s: unknown spawn region %s" % [aid, str(rg)])
			else:
				keep.append(GC.world_to_cell(GC.region_anchor(str(rg))))
		if (a.get("regions", []) as Array).is_empty():
			errs.append("arena %s: needs spawn regions" % aid)
		var bounds := Rect2i(0, 0, GC.MAP_W, GC.MAP_H)
		for o: Dictionary in a.get("obstacles", []):
			var r := Rect2i(int(o.get("x", 0)), int(o.get("y", 0)), int(o.get("w", 1)), int(o.get("h", 1)))
			var style: String = str(o.get("style", ""))
			if not ResourceLoader.exists("res://assets/world/%s.res" % style):
				errs.append("arena %s: obstacle %s has no model" % [aid, style])
			if not bounds.encloses(r):
				errs.append("arena %s: obstacle %s is outside the map" % [aid, style])
			if r.intersects(GC.DEPLOY_RECT):
				errs.append("arena %s: obstacle %s overlaps the deploy zone" % [aid, style])
			for kc: Vector2i in keep:
				if r.has_point(kc):
					errs.append("arena %s: obstacle %s sits on a spawn point" % [aid, style])
		var m: BattleMap = BattleMap.from_layout(arena_layout(cat, aid))
		if m.reachable_count(GC.DEPLOY_RECT.position) != m.free_count():
			errs.append("arena %s: the map is not connected" % aid)
		for e: Dictionary in a.get("embers", []):
			var er := Rect2i(int(e.get("x", 0)), int(e.get("y", 0)), int(e.get("w", 1)), int(e.get("h", 1)))
			if not bounds.encloses(er) or m.blocks_move(er.position):
				errs.append("arena %s: an ember patch is not on open ground" % aid)
		for hz: Dictionary in a.get("hazards", []):
			var ht: String = str(hz.get("type", ""))
			if not HAZARD_TYPES.has(ht):
				errs.append("arena %s: unknown hazard type %s" % [aid, ht])
			if not Loc.has_key("hazard.%s.label" % str(hz.get("id", ""))):
				errs.append("arena %s: missing loc key hazard.%s.label" % [aid, str(hz.get("id", ""))])
			var tagged := false
			for pair: Dictionary in cat.terrain_pairs:
				for rc: Dictionary in (pair["trigger"] as TriggerDef).conditions:
					if str(rc.get("tag", "")) == str(hz.get("tag", "")) and (pair["trigger"] as TriggerDef).timing == "OnTerrainHit":
						tagged = true
			if not tagged:
				errs.append("arena %s: hazard %s has no terrain trigger for its tag %s (terrain.json)" % [aid, str(hz.get("id", "")), str(hz.get("tag", ""))])
			for eid: Variant in hz.get("embers", []):
				if int(eid) < 0 or int(eid) >= (a.get("embers", []) as Array).size():
					errs.append("arena %s: hazard %s lands on a missing ember patch %d" % [aid, str(hz.get("id", "")), int(eid)])
			if ht == "sweep":
				var z: float = float(hz.get("z", 0.0))
				var hw: float = float(hz.get("half_width", 1.0))
				for o2: Dictionary in a.get("obstacles", []):
					var wr: Rect2 = m.rect_world(Rect2i(int(o2.get("x", 0)), int(o2.get("y", 0)), int(o2.get("w", 1)), int(o2.get("h", 1))))
					if wr.position.y < z + hw and wr.end.y > z - hw:
						errs.append("arena %s: obstacle %s is on the track" % [aid, str(o2.get("style", ""))])
	return errs
