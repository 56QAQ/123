class_name Pipeline
extends RefCounted
## 触发管线：这是整个玩法的唯一"效果入口"。
##   事件(时机) → 事件源单位的触发器(计数/冷却/条件) → 与"被动/装备载荷/羁绊能力"按 tag 配对
##   → 目标解析(触发器 target_rule + 能力 [群攻]) → 触发值(触发器 base_value) → 按装备大类语义执行
## 没有配对能力的触发器不会产生任何效果。战斗层不会绕过它直接改数值。

const MAX_DEPTH_EVENTS := 4000
## 冷却判定的容差(半个逻辑步长)：OnBattleFrame 的帧边界会因浮点累加差一个步长，"每 3 秒触发"配"冷却 3 秒"时不能被卡掉
const CD_EPS := GC.SIM_DT * 0.5

var b: Battle
var fx: Effects
var queue: Array[Dictionary] = []
var draining: bool = false
var processed_in_step: int = 0

static var _na_triggers: Dictionary = {}     # 武器大类 -> 普攻触发器
static var _na_abilities: Dictionary = {}    # 武器大类 -> 默认普攻载荷


## 普攻触发器：每个拿着武器的单位都自带一个，触发数值 = 攻击力 × 该武器大类的普攻倍率
## (mult >= 0 = 单位自己的普攻倍率，单位数据 wclass_overrides 的 na_mult：炽照节点的拔刀连斩一刀比普通的斩击轻)
static func na_trigger(weapon_class: String, scaling: String = "", mult: float = -1.0) -> TriggerDef:
	var key: String = weapon_class + "|" + scaling + "|" + str(mult)
	if not _na_triggers.has(key):
		_na_triggers[key] = TriggerDef.from_dict({
			"id": "__normal_attack", "timing": "OnNormalAttackPerform", "event_count_threshold": 1,
			"base_value_mode": {"ability_power": "ability_power_ratio", "max_health": "max_health_ratio"}.get(scaling, "attack_ratio"),
			"base_value_ratio": mult if mult >= 0.0 else float(GC.weapon_class(weapon_class).get("na_mult", 1.0)),
			"target_rule": "weapon_attack", "team_filter": "enemy", "tags": ["normal_attack_perform"]})
	return _na_triggers[key]


## 武器提供的默认普攻载荷：按武器大类的伤害类型造成 触发数值×1 的伤害，外加这个大类自带的普攻关键词(GC na_keywords)。
## 这些关键词和被动/装备上的关键词完全一样地走管线(吟唱/追击/叠加/群攻/溅射)，以后关键词数值的修正也同样作用于它们。
static func na_ability_for(weapon_class: String, kw_override: Variant = null) -> AbilityDef:
	var key: String = weapon_class if kw_override == null else "%s|%s" % [weapon_class, str(kw_override)]
	if not _na_abilities.has(key):
		var wc: Dictionary = GC.weapon_class(weapon_class)
		var kind: String = str(wc.get("dmg", "physical"))
		var kws: Array = ["basic", "crit", "normal_attack"]
		var kv := {}
		var nk: Dictionary = wc.get("na_keywords", {}) if kw_override == null else kw_override
		for k: String in nk.keys():
			kws.append(k)
			kv[k] = int(nk[k])
		var cfg := {}
		if wc.has("ammo"):
			cfg["ammo"] = (wc["ammo"] as Dictionary).duplicate(true)
		_na_abilities[key] = AbilityDef.from_dict({
			"id": "__na_" + weapon_class, "ability_class": "blade", "effect_type": kind + "_damage",
			"value_multiplier": 1.0, "keywords": kws, "keyword_values": kv, "effect_config": cfg,
			"accepted_timings": ["OnNormalAttackPerform"], "required_trigger_tags": ["normal_attack_perform"]})
	return _na_abilities[key]


# ---------------------------------------------------------------- 关键词数值
## 关键词数值 N 的唯一入口。以后改装、装备、角色技能对关键词数值的修正都挂在这里，
## 所有用到 N 的地方(结算、目标、落点规划、拉弓时长、弹匣容量…)都必须经过它，不能直接读能力数据。
static func kw_value(unit: BUnit, ability: AbilityDef, k: String, fallback: int = 0) -> int:
	if ability == null:
		return fallback
	var v: int = ability.keyword_value(k, unit.star if unit != null else 1, fallback)
	# 被动技能的【增幅】可以被装备加(虹光花：携带者被动技能增幅 +1)
	if k == "amplify" and unit != null and ability.has_keyword("amplify") and unit.def.passives.has(ability):
		v += int(round(unit.get_stats().passive_amplify_bonus))
	# 被动技能的【充能】上限可以被装备加(万语千言：携带者充能数 +2)
	if k == "charged" and unit != null and ability.has_keyword("charged") and unit.def.passives.has(ability):
		v += int(round(unit.get_stats().passive_charges_bonus))
	# 卡车改装·时间管理：被动 / 装备效果的[叠加]数 +25%(向下取整，至少 +1)；武器大类自带的普攻[叠加](弹匣)不算
	if k == "stacking" and v > 0 and unit != null and ability.has_keyword("stacking") and not ability.required_trigger_tags.has("normal_attack_perform"):
		var tm: Dictionary = mod_rule(unit, "time_management")
		if not tm.is_empty():
			v += maxi(1, int(floor(float(v) * float(tm.get("pct", 0.25)))))
	return v


# ---------------------------------------------------------------- 卡车改装(改写规则的那几个)
## 这个单位身上生效的改写规则改装的参数(Battle.mod_rules，开战时写进我方单位的 meta.mod_rules)；没有 = {}
static func mod_rule(unit: BUnit, rule: String) -> Dictionary:
	if unit == null:
		return {}
	var mr: Variant = unit.meta.get("mod_rules")
	if mr == null or not (mr is Dictionary) or not (mr as Dictionary).has(rule):
		return {}
	return (mr as Dictionary)[rule]


## 这个能力是单位手里法典(法器武器)的效果载荷
static func focus_payload(unit: BUnit, ability: AbilityDef) -> bool:
	return unit != null and unit.weapon != null and not unit.weapon.basic and unit.weapon.class_id == "focus" and unit.weapon.abilities.has(ability)


## 这个能力会[学习](每次发动学习计数 +1，触发数值按计数成长)：典籍、带【学习】的能力，以及卡车改装·魔力增长技巧下的法典效果
static func learns(unit: BUnit, ability: AbilityDef) -> bool:
	if ability.ability_class == "tome" or ability.has_keyword("learning"):
		return true
	return focus_payload(unit, ability) and not mod_rule(unit, "arcane_growth").is_empty()


## 每层学习计数让触发数值多多少：能力自己的 bonus_per_learning(默认 4%)+ 魔力增长技巧给法典的每层 +10%
static func learn_bonus_per(unit: BUnit, ability: AbilityDef) -> float:
	var lcfg: Dictionary = ability.cfg("learning", {})
	var per: float = float(lcfg.get("bonus_per_learning", 0.04)) if (ability.ability_class == "tome" or ability.has_keyword("learning")) else 0.0
	if focus_payload(unit, ability):
		per += float(mod_rule(unit, "arcane_growth").get("per_learning", 0.0))
	return per


## 关键词数值 N(允许小数：【溅射 1.5】)。修正挂载点同 kw_value
static func kw_value_f(unit: BUnit, ability: AbilityDef, k: String, fallback: float = 0.0) -> float:
	if ability == null:
		return fallback
	return ability.keyword_value_f(k, unit.star if unit != null else 1, fallback)


## [溅射 N] 的半径(米)
static func splash_radius(unit: BUnit, ability: AbilityDef) -> float:
	var n: float = kw_value_f(unit, ability, "splash", 1.0)
	return (n if n > 0.0 else 1.0) * GC.SPLASH_M_PER_POINT


## 普攻拉弓 / 瞄准了 drawn 秒(最多 dur 秒)的倍率。瞄准眉心(屏息节点)：武器大类自己的拉弓先照常算(弓：拉满 ×2)，
## 之后每多瞄 1 秒 +x%(被动配置 aim_pct_by_star，连续计时)
static func na_draw_scale(u: BUnit, drawn: float, dur: float) -> float:
	if u.aim_passive() == null:
		return chant_scale(u.na_payload(), drawn, dur)
	var base_n: float = na_base_chant(u)
	var s := 1.0
	if base_n > 0.0:
		s = 1.0 + clampf(drawn / base_n, 0.0, 1.0)
	return s * (1.0 + aim_pct(u) * maxf(0.0, drawn - base_n))


## 武器大类自己的普攻【吟唱】(弓 = 1 秒拉弓)，不算瞄准眉心加的
static func na_base_chant(u: BUnit) -> float:
	return float(int((u.wclass().get("na_keywords", {}) as Dictionary).get("chant", 0)))


## 瞄准眉心：每多瞄 1 秒提升的攻击力比例
static func aim_pct(u: BUnit) -> float:
	var aim: AbilityDef = u.aim_passive()
	if aim == null:
		return 0.0
	var by: Dictionary = aim.effect_config.get("aim_pct_by_star", {})
	return float(by.get(str(mini(u.star, 3)), aim.effect_config.get("aim_pct", 0.0)))


## [吟唱 N] 的倍率：吟唱了 chanted 秒(满 N 秒)。能力可以自带每秒加成的配置；没有配置时满吟唱 = ×2
static func chant_scale(ability: AbilityDef, chanted: float, n: float) -> float:
	if ability != null and bool(ability.effect_config.get("chant_proportional", false)):
		return chanted                                 # 演奏：结算量正比于吟唱了几秒
	if ability != null and ability.effect_config.has("chant_pct_per_second"):
		return 1.0 + float(ability.effect_config["chant_pct_per_second"]) * chanted
	return 1.0 + clampf(chanted / maxf(0.01, n), 0.0, 1.0)


# ---------------------------------------------------------------- [叠加]的资源状态(弹量)
## 普攻载荷配置了 ammo 时：单位带一个资源状态，层数上限 = 载荷的 [叠加 N]，开战满层；每发普攻消耗 1 层，打空后要装弹。
## 没有这类载荷返回 null
func ammo(unit: BUnit) -> BStatus:
	var na: AbilityDef = unit.na_payload()
	var ov: BStatus = ammo_source(unit)
	var sid := "ammo"
	var cap := 1
	if ov != null:
		cap = maxi(1, int(ov.meta["ammo_cap"]))
	elif na == null or not na.effect_config.has("ammo"):
		return null
	else:
		sid = str((na.effect_config["ammo"] as Dictionary).get("status_id", "ammo"))
		cap = maxi(1, kw_value(unit, na, "stacking", 1))
	var st: BStatus = unit.get_status(sid)
	if st == null:
		st = BStatus.new()
		st.id = sid
		st.stacks = cap
		st.flags = ["resource"]
		st.expires_at = -1.0
		unit.statuses[sid] = st
	st.max_stacks = cap
	st.stacks = mini(st.stacks, cap)
	return st


## 给单位弹匣的状态(meta.ammo_cap / ammo_reload；开枪最快之人)；没有 = null(用普攻载荷自己的 ammo)
static func ammo_source(unit: BUnit) -> BStatus:
	for st: BStatus in unit.statuses.values():
		if st.meta.has("ammo_cap"):
			return st
	return null


## 状态给的规则参数(第一个带 key 的状态)；没有 = fallback
static func status_meta(unit: BUnit, key: String, fallback: Variant = null) -> Variant:
	for st: BStatus in unit.statuses.values():
		if st.meta.has(key):
			return st.meta[key]
	return fallback


func spend_ammo(unit: BUnit) -> void:
	var st: BStatus = ammo(unit)
	if st != null:
		st.stacks = maxi(0, st.stacks - 1)
		b.fx({"t": "ammo", "unit": unit, "stacks": st.stacks, "max": st.max_stacks})


## 装弹完成：弹量回满，重新开始数"装弹后的第几次命中"，并发出 OnReloadComplete(供"装弹时…"的触发器监听)
func refill_ammo(unit: BUnit) -> void:
	var st: BStatus = ammo(unit)
	if st != null:
		st.stacks = st.max_stacks
		unit.hits_since_reload = 0
		b.fx({"t": "ammo", "unit": unit, "stacks": st.stacks, "max": st.max_stacks})
		emit("OnReloadComplete", unit, unit, float(st.stacks), ["reload"], {"weapon_class": unit.weapon_class()})


func _init(p_battle: Battle) -> void:
	b = p_battle
	fx = Effects.new(b)


# ---------------------------------------------------------------- 事件
func make_event(timing: String, source: BUnit, target: BUnit, value: float, tags: Array, meta: Dictionary) -> Dictionary:
	var t: Array[String] = []
	for x: Variant in tags:
		t.append(str(x))
	return {"timing": timing, "source": source, "target": target, "value": value, "tags": t, "meta": meta}


func emit(timing: String, source: BUnit, target: BUnit = null, value: float = 0.0, tags: Array = [], meta: Dictionary = {}) -> void:
	queue.append(make_event(timing, source, target, value, tags, meta))
	if timing == "OnTargeting" and target != null and target != source and target.alive and _listens(target, "OnTargeted"):
		queue.append(make_event("OnTargeted", target, source, 0.0, ["targeted"], {}))
	if not draining:
		drain()


## 立即处理(不排队)：用于"必须同步拿到结果"的场合，如濒死、普攻结算
func emit_now(timing: String, source: BUnit, target: BUnit = null, value: float = 0.0, tags: Array = [], meta: Dictionary = {}) -> Dictionary:
	var ev: Dictionary = make_event(timing, source, target, value, tags, meta)
	process_event(ev)
	return ev


func drain() -> void:
	draining = true
	while not queue.is_empty():
		var ev: Dictionary = queue.pop_front()
		processed_in_step += 1
		if processed_in_step > MAX_DEPTH_EVENTS:
			push_warning("Pipeline: event storm cut off")
			queue.clear()
			break
		process_event(ev)
	draining = false


func process_event(ev: Dictionary) -> void:
	var unit: BUnit = ev.get("source") as BUnit
	if unit == null:
		return
	var timing: String = ev["timing"]
	if not unit.alive and timing != "OnUnitDied" and timing != "OnBattleEnd" and timing != "OnTeamWiped":
		return
	# 免费普攻弹道(标定)：不视为攻击——只让普攻自己的触发器结算伤害，别的"普攻时"触发器、觉醒任务都不算
	var free: bool = timing == "OnNormalAttackPerform" and bool((ev.get("meta", {}) as Dictionary).get("free", false))
	if not free:
		_evaluate_awakening(unit, ev)
	for trig: TriggerDef in unit.all_triggers():
		if trig.timing != timing:
			continue
		if free and trig.id != "__normal_attack":
			continue
		# OnEnemyNear 是按触发器分别跟踪的(各自的范围 / 停留时间)：只给发出这个事件的那个触发器
		if timing == "OnEnemyNear" and str((ev["meta"] as Dictionary).get("trigger", trig.id)) != trig.id:
			continue
		if not _conditions_pass(trig, ev, unit):
			continue
		# 计时加速(蓝色羁绊)："每 x 秒"(每 N 个战斗帧)的计时器一帧走 1 + haste 格，多出来的带到下一轮；
		# haste 也可以是负的(变奏节点·沮丧：计时器充能变慢)，最慢走到 0.1 格
		var th: int = trig.threshold_for(unit.star)
		var hs: float = clampf(unit.get_stats().haste, -0.9, 1000.0) if timing == "OnBattleFrame" and th > 1 else 0.0
		var c: float = float(unit.counters.get(trig.id, 0)) + 1.0 + hs
		var reached: bool = c >= float(th) - 0.0001
		# 计数没到，但备选条件满足也触发(计数照常累计，不清零)
		var alt: bool = not reached and not trig.alt_conditions.is_empty() and _conds_pass(trig.alt_conditions, ev, unit)
		if reached:
			unit.counters[trig.id] = clampf(c - float(th), 0.0, float(th) - 1.0) if hs != 0.0 else 0
		else:
			unit.counters[trig.id] = c if hs != 0.0 else int(c)
		if not reached and not alt:
			continue
		if float(unit.trig_cd.get(trig.id, -1.0)) > b.time + CD_EPS:
			continue
		if trig.max_activations > 0 and int(unit.trig_acts.get(trig.id, 0)) >= trig.max_activations:
			continue
		_fire(ev, trig, unit)
		# 连续触发 N 次(extra.repeat；致将亡而未亡者：每 5 秒连续 4 次，间隔 repeat_gap 秒，每次重新选目标)
		var rep: int = int(trig.extra.get("repeat", 1))
		for ri in range(1, rep):
			b.schedule(b.time + float(trig.extra.get("repeat_gap", 0.12)) * float(ri), _refire.bind(ev, trig, unit))


func _refire(ev: Dictionary, trig: TriggerDef, unit: BUnit) -> void:
	if unit.alive and b.state != "ended":
		_fire(ev, trig, unit)


# ---------------------------------------------------------------- 条件
func _conditions_pass(trig: TriggerDef, ev: Dictionary, unit: BUnit) -> bool:
	return _conds_pass(trig.conditions, ev, unit)


func _conds_pass(conds: Array[Dictionary], ev: Dictionary, unit: BUnit) -> bool:
	for c: Dictionary in conds:
		match str(c.get("type", "")):
			"source_health_above_ratio":
				if not (unit.hp_ratio() > float(c.get("ratio", 0.0))):
					return false
			"source_health_below_or_equal_ratio":
				if not (unit.hp_ratio() <= float(c.get("ratio", 1.0))):
					return false
			"event_has_tag":
				if not (ev["tags"] as Array).has(str(c.get("tag", ""))):
					return false
			"source_chanting":
				if unit.phase != "chant":
					return false
			"source_not_chanting":
				# 自己现在没在吟唱、也没被控住(虹光飞弹：吟唱被打断后，晕完再重新开始)
				if unit.phase == "chant" or unit.is_stunned():
					return false
			"event_has_any_tag":
				# 事件带着 tags 里任何一个(重燃：承受普攻伤害或技能伤害)
				var any_t := false
				for tg: Variant in c.get("tags", []):
					if (ev["tags"] as Array).has(str(tg)):
						any_t = true
				if not any_t:
					return false
			"event_value_at_least":
				if float(ev.get("value", 0.0)) + 0.00001 < float(c.get("value", 0.0)):
					return false
			"source_has_status":
				if unit.status_stacks(str(c.get("status_id", ""))) < int(c.get("min_stacks", 1)):
					return false
			"source_missing_status":
				if unit.status_stacks(str(c.get("status_id", ""))) > 0:
					return false
			"source_weapon_color":
				# 装备的(非基础)武器颜色在 colors 里
				if unit.weapon == null or unit.weapon.basic or not (c.get("colors", []) as Array).has(unit.weapon.color_id):
					return false
			"source_attack_range_above":
				# 实际攻击距离(米)大于 value
				if not (unit.get_stats().range_meters() > float(c.get("value", 2.0))):
					return false
			"battle_running":
				if b.state != "running":
					return false
			"enemies_in_reach_gathered":
				# 射程里(看得见)的敌人凑够了：够 [群攻 N](N 读 passive 这个被动的关键词数值；场上敌人不到 N 个就是全部)，
				# 或者射程里有人已经满 patience 秒了(清洁世界：开局别一看到第一个敌人就转，等人进射程)
				# global：不看射程，全场看得见(不被掩体挡住)的都算
				var cnt_in := 0
				var reach_c: float = unit.get_stats().range_meters()
				var foes: Array[BUnit] = b.enemies_of(unit)
				var glob: bool = bool(c.get("global", false))
				for fe: BUnit in foes:
					if glob:
						if b.map.has_los(unit.pos, fe.pos, unit.team):
							cnt_in += 1
					elif BattleAI.in_reach(unit, fe, unit.pos.distance_to(fe.pos), reach_c) and b.ai.can_hit(unit, fe):
						cnt_in += 1
				var wkey: String = "_gather_" + str(c.get("passive", ""))
				if cnt_in == 0:
					unit.meta.erase(wkey)
					return false
				if glob:
					continue                              # 全场：看得见的都已经算上了，不用等人进射程
				if not unit.meta.has(wkey):
					unit.meta[wkey] = b.time
				var pa_g: AbilityDef = unit.def.passive_by_id(str(c.get("passive", "")))
				var want: int = mini(foes.size(), maxi(1, kw_value(unit, pa_g, "multi_attack", 1)))
				if cnt_in < want and b.time - float(unit.meta[wkey]) < float(c.get("patience", 1.0)) - CD_EPS:
					return false
			"has_enemies":
				if b.enemies_of(unit).is_empty():
					return false
			"event_missing_tag":
				if (ev["tags"] as Array).has(str(c.get("tag", ""))):
					return false
			"payload_ready":
				# 武器(装备载荷)有效果、而且都不在冷却：血嗜节点的触发器在武器冷却时不触发、也不消耗血欲
				if not payload_ready(unit):
					return false
			"source_target_not_ranged":
				# 自己现在的目标不是远程敌人(没有目标也算；踏影节点·逆光)
				var srt: BUnit = unit.target
				if srt != null and srt.alive and srt.team != unit.team and srt.is_ranged():
					return false
			"source_target_missing_status":
				# 自己现在的目标(活着的敌人)身上没有某个状态(止息节点：索敌目标没有标定 → 突进)
				var stg: BUnit = unit.target
				if stg == null or not stg.alive or stg.team == unit.team or stg.status_count(str(c.get("status_id", ""))) > 0:
					return false
			"event_dead_def_is":
				# 倒下的是某种单位(心连节点·奇迹：每阵亡 2 只心连节点；复制品也算)
				var ed: BUnit = (ev.get("meta", {}) as Dictionary).get("dead") as BUnit
				if ed == null or ed.def.id != str(c.get("def", "")):
					return false
			"team_dead_at_least_alive":
				# 自己这一队(不算召唤物)已阵亡的人数 ≥ 还活着的人数(奇兴节点·自久远的过去而来：苏醒)
				var da: Array[int] = b.team_dead_alive(unit.team)
				if da[0] < da[1]:
					return false
			"has_hurt_ally":
				# 有没满血的友军(含自己；圣战节点·圣疗：有人掉血才计时)
				var hurt := false
				for a: BUnit in b.units:
					if a.alive and a.team == unit.team and a.hp < a.get_stats().max_health - 0.5:
						hurt = true
						break
				if not hurt:
					return false
			"enemy_near":
				# 身边 radius 米以内(边到边)有敌人(圣战节点·裂地猛击：有敌人在锥形够得着的地方才计时)
				if not b.enemy_near(unit, float(c.get("radius", 2.5))):
					return false
			"no_enemy_near":
				# 身边 radius 米以内(边到边)没有敌人(屏息节点·集中呼吸)
				if b.enemy_near(unit, float(c.get("radius", 2.5))):
					return false
			"in_melee_enemy_reach":
				# 被拿着近战武器的敌人够得着(集中呼吸重置)
				if not b.melee_threat(unit):
					return false
			"light_beam_active":
				# 光束在场(灭罪节点·她必尽灭邪恶：光束每持续 0.25 秒触发一次；降临的那一帧不算)
				var lb0: Dictionary = unit.meta.get("light_beam", {})
				if lb0.is_empty() or unit.phase != "chant" or float(lb0.get("born", 0.0)) >= b.time - 0.001:
					return false
			"has_allies":
				# 除了自己还有活着的队友(召唤物也算)
				if b.allies_of(unit).is_empty():
					return false
			"source_can_act":
				# 能行动：没被控住，也没在冲刺 / 投掷 / 转圈扔飞刀(清洁世界)
				if unit.is_stunned() or unit.phase == "dash" or unit.phase == "throw" or unit.phase == "storm":
					return false
			"source_shield_at_most":
				if unit.shield > float(c.get("value", 0.0)) + 0.0001:
					return false
			"field_missing_unit_id":
				if b.has_unit_id(str(c.get("unit_id", "")), unit.team):
					return false
			"event_metadata_equals":
				if str((ev["meta"] as Dictionary).get(str(c.get("key", "")), "")) != str(c.get("value", "")):
					return false
			"source_has_active_equipment_class":
				var okc := false
				for e: EquipmentDef in unit.active_payload_equipment():
					if e.class_id == str(c.get("class_id", "")):
						okc = true
				if not okc:
					return false
			"source_weapon_class":
				if not (c.get("classes", [c.get("class_id", "")]) as Array).has(unit.weapon_class()):
					return false
			"source_is_summon":
				if unit.is_summon != bool(c.get("value", true)):
					return false
			"source_status_awakened":
				var sta: BStatus = unit.get_status(str(c.get("status_id", "")))
				if sta == null or not bool(sta.meta.get("awakened", false)):
					return false
			"source_status_below_cap":
				# 自己的某个[叠加]状态还没满(没有这个状态也算没满)
				var stc: BStatus = unit.get_status(str(c.get("status_id", "")))
				if stc != null and stc.stacks >= stc.max_stacks:
					return false
			"event_target_has_status":
				var et: BUnit = ev.get("target") as BUnit
				if et == null or et.status_count(str(c.get("status_id", ""))) <= 0:
					return false
			"event_dead_is_summon":
				# 刚阵亡的是召唤物(遗愿)
				var dsu: BUnit = (ev.get("meta", {}) as Dictionary).get("dead") as BUnit
				if dsu == null or not dsu.is_summon:
					return false
			"source_form":
				# 自己现在是这个形态(变奏节点：恶魔 / 天使各有各的被动 2)
				if unit.def.form != str(c.get("form", "")):
					return false
			"source_meta_has":
				# 自己的 meta 里有这个键(圣战节点·裂地猛击：到点时没敌人、蓄着的那一锤)
				if not unit.meta.has(str(c.get("key", ""))):
					return false
			"source_meta_missing":
				# 自己的 meta 里没有这个键(少女幻葬召出来的幽灵带 no_spectral：没有魂体存在)
				if unit.meta.has(str(c.get("key", ""))):
					return false
			"source_alive":
				# 自己还活着(OnBattleEnd 对倒下的棋子也会发)
				if not unit.alive:
					return false
			"event_target_enemy":
				# 事件对象是敌人(灭罪节点·照亮长夜：击杀敌人才算，光束溅死队友不算)
				var ete: BUnit = ev.get("target") as BUnit
				if ete == null or ete.team == unit.team:
					return false
			"event_target_not_source":
				# 事件对象不是自己(为"队友"做什么时)
				if ev.get("target") is BUnit and (ev["target"] as BUnit) == unit:
					return false
			"source_status_capped":
				# 自己的某个[叠加]状态满层了(正行节点：花瓣满层 → 开始吟唱再绽之花)
				var scp: BStatus = unit.get_status(str(c.get("status_id", "")))
				if scp == null or scp.stacks < scp.max_stacks:
					return false
			"source_chanting_ability":
				# 自己正在吟唱某个能力(再绽之花：吟唱中每秒消耗花瓣)
				if unit.phase != "chant" or unit.chant_ability == null or unit.chant_ability.id != str(c.get("ability_id", "")):
					return false
			"event_dead_not_summon":
				# 刚阵亡的不是召唤物(正色百合：队友阵亡才算，召唤物散掉不算)
				var dns: BUnit = (ev.get("meta", {}) as Dictionary).get("dead") as BUnit
				if dns != null and dns.is_summon:
					return false
			"event_target_has_dispellable":
				# 事件对象身上有可被驱散的负面(what = debuff)/ 增益(what = buff)状态
				var edt: BUnit = ev.get("target") as BUnit
				if edt == null or not edt.alive or fx.dispellable(edt, str(c.get("what", "debuff"))).is_empty():
					return false
			_:
				pass
	return true


# ---------------------------------------------------------------- 触发
func _fire(ev: Dictionary, trig: TriggerDef, unit: BUnit) -> void:
	var pairs: Array[Dictionary] = []
	for entry: Dictionary in unit.all_ability_entries():
		if trig.can_pair(entry["ability"] as AbilityDef):
			pairs.append(entry)
	if pairs.is_empty():
		return                                    # 没有配对能力 = 什么都不发生
	pairs.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return (x["ability"] as AbilityDef).priority < (y["ability"] as AbilityDef).priority)
	var shared: Dictionary = {"rewrites": []}
	var activated := 0
	var surfaces: Array[String] = []
	var equips: Array[String] = []
	var passive_targets: Array[BUnit] = []
	var hit_targets: Array = []                   # 这次触发真正作用到的目标(表现层用：没有事件目标的每帧触发器也知道打的是谁)
	for entry: Dictionary in pairs:
		shared["last_targets"] = []
		if _run_ability(ev, trig, unit, entry, shared):
			activated += 1
			for ht: BUnit in shared["last_targets"]:
				if not hit_targets.has(ht):
					hit_targets.append(ht)
			var sf: String = str(entry["surface"])
			if not surfaces.has(sf):
				surfaces.append(sf)
			if entry["equip"] != null:
				equips.append((entry["equip"] as EquipmentDef).id)
			if sf == "passive":
				for pt: BUnit in shared["last_targets"]:
					if not passive_targets.has(pt):
						passive_targets.append(pt)
	if activated > 0:
		unit.trig_cd[trig.id] = b.time + hasted(unit, trig.cooldown_seconds)
		unit.trig_acts[trig.id] = int(unit.trig_acts.get(trig.id, 0)) + 1
		# 发动了被动技能：对它的每个目标发 OnPassiveActivated(道法自然：目标 = 被动技能的目标)
		if not passive_targets.is_empty() and _listens(unit, "OnPassiveActivated"):
			for pt2: BUnit in passive_targets:
				queue.append(make_event("OnPassiveActivated", unit, pt2, float(shared.get("value", 0.0)), ["passive_activated"], {"trigger": trig.id}))
		if surfaces.has("equipment") or surfaces.has("trait") or surfaces.has("relic"):
			b.fx({"t": "trigger", "unit": unit, "trigger": trig.id, "timing": trig.timing, "surfaces": surfaces,
				"equips": equips, "target": ev.get("target"), "targets": hit_targets, "value": float(shared.get("value", 0.0))})


## 单位身上有没有监听某个时机的触发器(缓存在 meta 里；用来少发没人听的事件)
func _listens(unit: BUnit, timing: String) -> bool:
	var key: String = "_listens_" + timing
	if not unit.meta.has(key):
		var yes := false
		for tr: TriggerDef in unit.all_triggers():
			if tr.timing == timing:
				yes = true
		unit.meta[key] = yes
	return bool(unit.meta[key])


func trigger_value(trig: TriggerDef, ev: Dictionary, unit: BUnit, ability: AbilityDef) -> float:
	var st: StatBlock = unit.get_stats()
	var r: float = trig.ratio_for(unit.star)
	var f: float = trig.flat_for(unit.star)
	# 普攻倍率加成(卡车改装·锐利武装)：普攻触发器的比例 ×(1 + na_mult_pct)
	if st.na_mult_pct != 0.0 and trig.tags.has("normal_attack_perform"):
		r *= 1.0 + st.na_mult_pct
	match trig.base_value_mode:
		"fixed":
			return f
		"attack_ratio":
			return st.attack_power * r + f
		"ability_power_ratio":
			return st.ability_power * r + f
		"attack_times_ability_power_pct":
			return st.attack_power * (1.0 + st.ability_power / 100.0) * r + f
		"summoner_ability_power_ratio":
			# 召唤者的法术强度 × r + f(脆弱使魔：攻击力额外受召唤者的法强增益)
			var smr: BUnit = unit.meta.get("summoner") as BUnit
			return (smr.get_stats().ability_power if smr != null else 0.0) * r + f
		"splash_enemy_count_ap":
			# 自己被动溅射范围内的敌人数 × r × (100 + 法术强度)% + f(渡星而来 / 真实形态)
			return float(enemies_in_splash(unit)) * r * (1.0 + st.ability_power / 100.0) + f
		"attack_times_crit_damage":
			# 攻击力 × 暴击伤害 × r + f(女仆护身术)
			return st.attack_power * st.crit_damage * r + f
		"attack_ratio_event_stacks":
			# 攻击力 × r × (100 + f × 事件里的层数)%(残光：剑痕引爆时每层 +5%)
			return st.attack_power * r * (1.0 + f * float((ev["meta"] as Dictionary).get("stacks", 0)))
		"attack_plus_ap_ratio":
			# (攻击力 + 法术强度) × r + f(紫色羁绊·紫电)
			return (st.attack_power + st.ability_power) * r + f
		"self_cost_lost":
			# 刚才自己付出的生命(踏影节点·淬血：这次流失的生命值，Pipeline._self_cost 记下的) × r + f
			return float(unit.meta.get("self_cost_lost", 0.0)) * r + f
		"source_heal_done":
			# 自己本场施加的治疗量(不含溢出，战报的 heal) × r + f：调香节点·焚花
			return float((b.report.rows.get(unit.uid, {}) as Dictionary).get("heal", 0.0)) * r + f
		"status_stacks_atk_ap":
			# 某状态的层数 × 攻击力 × (100 + 法强)% × r + f：血嗜节点(血宴层数)
			return float(unit.status_stacks(trig.base_value_status_id)) * st.attack_power * (1.0 + st.ability_power / 100.0) * r + f
		"target_status_stacks":
			# 按目标算(Pipeline.execute 里每个目标各算一次)：r × 目标身上某状态的层数 + f；这里没有目标，只给 f
			return f
		"attack_times_ap_pct":
			# 攻击力 × r × (100 + 法强)% + f(奇兴节点的触发器)
			return st.attack_power * r * (1.0 + maxf(0.0, st.ability_power) / 100.0) + f
		"max_health_times_ap_pct":
			# 最大生命 × r × (100 + 法强)% + f(守林节点·荒野意志的护盾 / 原初血脉)
			return st.max_health * r * (1.0 + st.ability_power / 100.0) + f
		"attack_times_healing_bonus":
			# 攻击力 × 治疗量加成 × r + f(正行节点·百合骑士的骑士：治疗量加成 0 时触发数值也是 0)
			return st.attack_power * maxf(0.0, st.healing_done_pct) * r + f
		"flat_times_ability_power_pct":
			# x × (100 + 法术强度)%
			return f * (1.0 + st.ability_power / 100.0)
		"weapon_learning_count":
			# 所携带武器本场的学习计数 × r + f
			var lc := 0
			for e: EquipmentDef in unit.active_payload_equipment():
				for ea: AbilityDef in e.abilities:
					lc += int(unit.learning.get(ea.id, 0))
			return float(lc) * r + f
		"defense_ratio":
			return st.defense * r + f
		"max_health_ratio":
			return st.max_health * r + f
		"current_health_ratio":
			return unit.hp * r + f
		"event_value":
			return float(ev.get("value", 0.0)) * r + f
		"event_target_stat_ratio":
			var tgt: BUnit = ev.get("target") as BUnit
			var sid: String = trig.base_value_stat_id if trig.base_value_stat_id != "" else "max_health"
			return (tgt.get_stats().get_stat(sid) if tgt != null else 0.0) * r + f
		"source_missing_health_ratio":
			return maxf(0.0, st.max_health - unit.hp) * r + f
		"source_status_stacks_times_stat":
			var sid2: String = trig.base_value_stat_id if trig.base_value_stat_id != "" else "attack_power"
			return float(unit.status_stacks(trig.base_value_status_id)) * st.get_stat(sid2) * r + f
		"ability_keyword_value":
			# 配对能力自己带这个关键词就用它的，否则用本单位被动里的(例如"触发数值 = 25 × 护盾充能的增幅")；
			# 还没解锁的被动(星级不够)里的关键词数值视为 0
			return float(_kw_of(unit, ability, trig.base_value_keyword)) * r + f
		"ability_power_ratio_center":
			# 法强 × r；找不到召唤物队友当中心(改用普通队友)时减到三分之一(魔女的笑与泪)
			var vc: float = st.ability_power * r + f
			if bool((ev.get("meta", {}) as Dictionary).get("center_no_summon", false)):
				vc /= 3.0
			return vc
		"team_unit_count":
			# r × 我方场上(活着、非召唤物)和自己同一种棋子的个数(含自己) + f(拖后腿：每上阵一个空白节点 -10%)
			var cnt := 0
			for tu: BUnit in b.units:
				if tu.alive and tu.team == unit.team and not tu.is_summon and tu.def.id == unit.def.id:
					cnt += 1
			return r * float(cnt) + f
		"event_target_star_rank":
			# r × 事件对象的星级，精英 ×2、首领 ×3(我已得胜：被击杀者的星级)
			var vt: BUnit = ev.get("target") as BUnit
			if vt == null:
				return f
			var rank: float = 3.0 if bool(vt.meta.get("boss", false)) else (2.0 if bool(vt.meta.get("elite", false)) else 1.0)
			return r * float(vt.star) * rank + f
		"summoner_na_value":
			# 召唤者的普通攻击伤害(攻击力 × 召唤者武器大类的普攻倍率) × r + f(最好的伙伴)
			var sm: BUnit = unit.meta.get("summoner") as BUnit
			if sm == null:
				return f
			return sm.get_stats().attack_power * float(sm.wclass().get("na_mult", 1.0)) * r + f
		"dead_max_health":
			# 刚阵亡的那个单位的最大生命值 × r + f(遗愿)
			var dd: BUnit = (ev["meta"] as Dictionary).get("dead") as BUnit
			return (dd.get_stats().max_health if dd != null else 0.0) * r + f
		"charges_spent":
			# 带【充能】的被动已经用掉的充能数 × r + f(小小收获)
			return float(charges_spent(unit)) * r + f
		"kick_mult":
			# 攻击力 × r × 这一脚的倍率(飞身踢：(100 + 法强)% × f(路程)，事件 meta.kick_mult) + f(别粘我鞋底上)
			return st.attack_power * r * float((ev["meta"] as Dictionary).get("kick_mult", 1.0)) + f
		"attack_ratio_keyword_plus_one":
			# 攻击力 × r × (关键词数值 + 1)(例如"攻击力 × 0.15 × (舞与歌的增幅 + 1)")
			return st.attack_power * r * (float(_kw_of(unit, ability, trig.base_value_keyword)) + 1.0) + f
		"attack_ratio_keyword":
			# 攻击力 × r × 关键词数值(蓝之章的输出终端："攻击力 × 25% × 增幅"；增幅吃链路 / 力场的加成)
			return st.attack_power * r * float(_kw_of(unit, ability, trig.base_value_keyword)) + f
		"ability_keyword_base":
			# 关键词的基础数值 × r(不吃增幅的加成：增幅的"来源"——中继广播、增幅力场——自己放出去的数值不被自己放大，否则会无限自增)
			var base_kw: int = ability.keyword_value(trig.base_value_keyword, unit.star, 0) if ability != null and ability.has_keyword(trig.base_value_keyword) else 0
			if base_kw == 0 and ability != null and not ability.has_keyword(trig.base_value_keyword):
				for pa0: AbilityDef in unit.def.passives:
					if pa0.has_keyword(trig.base_value_keyword) and pa0.unlock_star <= unit.star:
						base_kw = pa0.keyword_value(trig.base_value_keyword, unit.star, 0)
						break
			return float(base_kw) * r + f
		_:
			return f


## 触发数值要用的关键词数值：配对能力自己带就用它的，否则找本单位已解锁的被动；都没有 = 0
func _kw_of(unit: BUnit, ability: AbilityDef, kw: String) -> int:
	if ability != null and ability.has_keyword(kw):
		return kw_value(unit, ability, kw)
	for pa: AbilityDef in unit.def.passives:
		if pa.has_keyword(kw) and pa.unlock_star <= unit.star:
			return kw_value(unit, pa, kw)
	return 0


func _gate_ok(unit: BUnit, ability: AbilityDef, ev: Dictionary) -> bool:
	var cfg: Dictionary = ability.effect_config
	if bool(cfg.get("once_per_battle", false)) and bool((unit.meta.get("once_used", {}) as Dictionary).get(ability.id, false)):
		return false                                 # 每场战斗限一次(至远的弓弦能刷新)
	if ability.has_keyword("awakening"):
		var key: String = str(cfg.get("awakening_key", ability.id))
		if not unit.awakened.get(key, false):
			return false
	if ability.has_keyword("limited"):
		var want: Array = cfg.get("limited_event_tags", [])
		if not want.is_empty():
			var okt := false
			for t: Variant in want:
				if (ev["tags"] as Array).has(str(t)):
					okt = true
			if not okt:
				return false
		var timings: Array = cfg.get("limited_timings", [])
		if not timings.is_empty() and not timings.has(ev["timing"]):
			return false
		if float(ev.get("value", 0.0)) < float(cfg.get("min_event_value", -1.0)):
			return false
	if bool((ev["meta"] as Dictionary).get("is_copy", false)) and ability.has_keyword("pursuit") and not ability.has_keyword("normal_attack"):
		return false                              # 追击的副本不再触发追击(普攻载荷自带的追击：副本照常造成伤害，只是不再复制)
	# 充能 / 冷却
	var maxc: int = _max_charges(ability, unit)
	if maxc > 0:
		_recharge(unit, ability, maxc)
		if int(unit.ability_charges.get(ability.id, maxc)) <= 0:
			return false
	elif not ability.has_keyword("basic") and ability.cooldown > 0.0:
		if float(unit.ability_cd.get(ability.id, -1.0)) > b.time + CD_EPS:
			return false
	return true


func _max_charges(ability: AbilityDef, unit: BUnit) -> int:
	if ability.has_keyword("charged"):
		return maxi(1, kw_value(unit, ability, "charged", ability.max_charges))
	return ability.max_charges


## 这个单位所有带【充能】的被动已经用掉的充能数(小小收获)
func charges_spent(unit: BUnit) -> int:
	var n := 0
	for pa: AbilityDef in unit.def.passives:
		if pa.has_keyword("charged") and pa.unlock_star <= unit.star:
			var mx: int = _max_charges(pa, unit)
			n += maxi(0, mx - int(unit.ability_charges.get(pa.id, mx)))
	return n


func _recharge(unit: BUnit, ability: AbilityDef, maxc: int) -> void:
	if not unit.ability_charges.has(ability.id):
		# 初始充能(默认满)；少于上限时从开战(时间 0)起按冷却回充能(流星爆魔杖：初始 0 层，冷却 8 秒 → 第 8 秒才有第一层)
		var init: int = mini(maxc, int(ability.cfg("initial_charges", maxc)))
		unit.ability_charges[ability.id] = init
		if init >= maxc:
			return
		unit.ability_cd[ability.id] = ability.cooldown
	var cur: int = int(unit.ability_charges[ability.id])
	if cur >= maxc or ability.cooldown <= 0.0:
		return
	var cdh: float = hasted(unit, ability.cooldown)
	var nxt: float = float(unit.ability_cd.get(ability.id, b.time + cdh))
	while cur < maxc and b.time + CD_EPS >= nxt:
		cur += 1
		nxt += cdh
	unit.ability_charges[ability.id] = cur
	unit.ability_cd[ability.id] = nxt


func _commit(unit: BUnit, ability: AbilityDef) -> void:
	var maxc: int = _max_charges(ability, unit)
	if maxc > 0:
		var cur: int = int(unit.ability_charges.get(ability.id, maxc))
		if cur >= maxc:
			unit.ability_cd[ability.id] = b.time + hasted(unit, ability.cooldown)
		unit.ability_charges[ability.id] = cur - 1
		if cur - 1 <= 0 and _listens(unit, "OnChargesEmpty"):
			queue.append(make_event("OnChargesEmpty", unit, unit, 0.0, ["charges_empty"], {"ability_id": ability.id}))
	elif ability.cooldown > 0.0 and not ability.has_keyword("basic"):
		unit.ability_cd[ability.id] = b.time + hasted(unit, ability.cooldown)


## 冷却 / 计时按计时加速(蓝色羁绊)缩短
func hasted(unit: BUnit, secs: float) -> float:
	var h: float = maxf(0.0, unit.get_stats().haste) if unit != null else 0.0
	return secs / (1.0 + h) if h > 0.0 else secs


func _run_ability(ev: Dictionary, trig: TriggerDef, unit: BUnit, entry: Dictionary, shared: Dictionary) -> bool:
	var ability: AbilityDef = entry["ability"]
	if not _gate_ok(unit, ability, ev):
		return false
	var targets: Array[BUnit] = Targeting.resolve(b, ev, trig, ability, unit)
	var meta: Dictionary = ev["meta"]
	# 打地板(法器溅射的落点不在任何单位身上)：没有直接目标，但有落点就照样在落点溅射
	var ground: bool = targets.is_empty() and meta.get("aim_point") is Vector2 and ability.has_keyword("splash")
	if targets.is_empty() and not ground:
		return false
	var value: float = trigger_value(trig, ev, unit, ability)
	shared["value"] = value
	shared["last_targets"] = targets
	# 芯片：改写后续载荷的规则，本身不直接造成数值
	if ability.ability_class == "chip":
		_commit(unit, ability)
		(shared["rewrites"] as Array).append(ability.effect_config.duplicate(true))
		b.fx({"t": "chip", "unit": unit, "ability": ability.id})
		return true
	# 吟唱：进入吟唱状态，稍后释放。普攻载荷的吟唱在"出手前"由攻击状态机完成(拉弓)，这里只吃它带来的倍率
	var na_chant: bool = ability.has_keyword("normal_attack")
	if ability.has_keyword("chant") and not na_chant and unit.phase != "chant":
		return _begin_chant(ev, trig, unit, entry, value, targets[0] if not targets.is_empty() else null)
	_commit(unit, ability)
	if bool(ability.effect_config.get("once_per_battle", false)):
		(unit.meta.get_or_add("once_used", {}) as Dictionary)[ability.id] = true
	var ctx: Dictionary = {"ev": ev, "trig": trig, "unit": unit, "entry": entry, "value": value,
		"targets": targets, "rewrites": shared["rewrites"],
		"chant_scale": float(meta.get("chant_scale", 1.0)) if ability.has_keyword("chant") else 1.0,
		"aim_point": meta.get("aim_point")}
	execute(ctx)
	# 追击：把本次触发的效果再来 N 次
	# (停在半空的飞刀：另一只手扔出去时就跟着扔了，copies_sent，命中时不再复制)
	if ability.has_keyword("pursuit") and not bool(meta.get("is_copy", false)) and not bool(meta.get("free", false)) \
			and not (ability.has_keyword("normal_attack") and bool(meta.get("copies_sent", false))):
		var n: int = maxi(1, kw_value(unit, ability, "pursuit", 1))
		for i in range(n):
			_pursuit_copy(ev, trig, unit, entry, targets, value, i)
	return true


## 追击 = 复制原触发效果。触发效果本身就是一次普攻时(普攻载荷自己带追击，或挂在普攻事件上、自身不带数值的追击被动)，
## 副本是一次完整的普攻：走和普攻一样的出手方式(远程会真的再飞一发)，也会产生命中事件，只是副本不会再追击。
func _pursuit_copy(ev: Dictionary, trig: TriggerDef, unit: BUnit, entry: Dictionary, targets: Array[BUnit], value: float, idx: int = 0) -> void:
	var ability: AbilityDef = entry["ability"]
	var copies_attack: bool = ability.has_keyword("normal_attack") or \
		(ability.effect_type == "none" and (ev["tags"] as Array).has("normal_attack"))
	if copies_attack:
		var tgt: BUnit = ev.get("target") as BUnit
		var meta0: Dictionary = ev["meta"]
		# 致向死的渴望(白羽节点)：双枪的第二发(追击那发；追击 N 时是第 2、4……发)改打射程里生命低于 97% 的队友
		if ability.has_keyword("normal_attack") and idx % 2 == 0 and status_meta(unit, "angel_alt") != null:
			var aly: BUnit = angel_ally(unit)
			if aly != null:
				tgt = aly
		if unit.alive and ((tgt != null and tgt.alive) or meta0.get("aim_point") is Vector2):
			b.deliver_copy(unit, tgt, meta0, ability.has_keyword("normal_attack"), idx)
	else:
		var meta: Dictionary = (ev["meta"] as Dictionary).duplicate()
		meta["is_copy"] = true
		var ev2: Dictionary = make_event(ev["timing"], ev["source"], ev.get("target"), ev.get("value", 0.0), ev["tags"], meta)
		var alive_targets: Array[BUnit] = []
		for t: BUnit in targets:
			if t.alive:
				alive_targets.append(t)
		if alive_targets.is_empty():
			return
		execute({"ev": ev2, "trig": trig, "unit": unit, "entry": entry, "value": value, "targets": alive_targets,
			"rewrites": [], "chant_scale": 1.0})


# ---------------------------------------------------------------- 吟唱
func _begin_chant(ev: Dictionary, trig: TriggerDef, unit: BUnit, entry: Dictionary, value: float, target: BUnit = null) -> bool:
	var ability: AbilityDef = entry["ability"]
	if unit.is_stunned():
		return false
	var dur: float = float(maxi(1, kw_value(unit, ability, "chant", 1)))
	unit.phase = "chant"
	unit.phase_t = 0.0
	unit.phase_dur = dur
	unit.chant_until = b.time + dur
	if b.state == "countdown":
		unit.chant_until = GC.START_DELAY + dur     # 开战时机就开始的吟唱：从倒计时结束、真正开打才开始计时
	unit.chant_ability = ability
	unit.chant_event = {"ev": ev, "trig": trig, "entry": entry, "target": target}
	unit.vel = Vector2.ZERO
	if target != null and target.team != unit.team:
		unit.target = target                        # 吟唱时转身朝着它(猎人笔记：盯着威胁最高的敌人)
	b.fx({"t": "chant_start", "unit": unit, "duration": dur, "ability": ability.id, "target": target})
	if ability.has_keyword("performance"):
		_perform_start(unit, ability, target)
	emit("OnChantStart", unit, target, dur, ["chant_start"], {"ability_id": ability.id})
	return true


## interrupted = 被打断(能力配置 release_on_interrupt 的吟唱被打断时也按已吟唱的秒数结算；猎人笔记)
func release_chant(unit: BUnit, chanted: float, interrupted: bool = false) -> void:
	var data: Dictionary = unit.chant_event
	var dur0: float = unit.phase_dur
	unit.phase = "idle"
	unit.chant_ability = null
	unit.chant_event = {}
	if data.is_empty() or not unit.alive:
		return
	var ev: Dictionary = data["ev"]
	var trig: TriggerDef = data["trig"]
	var entry: Dictionary = data["entry"]
	var ability: AbilityDef = entry["ability"]
	var targets: Array[BUnit] = Targeting.resolve(b, ev, trig, ability, unit)
	if ability.has_keyword("performance"):
		var pf: Dictionary = unit.meta.get("perf", {})
		var pt: BUnit = pf.get("target") as BUnit
		targets = [] as Array[BUnit]
		if pt != null and pt.alive:
			targets.append(pt)
		_perform_end(unit)
	if targets.is_empty():
		return
	var value: float = trigger_value(trig, ev, unit, ability)
	var scale: float = chant_scale(ability, chanted, float(maxi(1, kw_value(unit, ability, "chant", 1))))
	if ability.effect_config.has("chant_flat_per_second"):
		value += float(ability.effect_config["chant_flat_per_second"]) * chanted
	_commit(unit, ability)
	var complete: bool = not interrupted and chanted >= dur0 - 0.001
	b.fx({"t": "chant_release", "unit": unit, "ability": ability.id, "chanted": chanted, "interrupted": interrupted, "complete": complete,
		"target": targets[0]})
	execute({"ev": ev, "trig": trig, "unit": unit, "entry": entry, "value": value, "targets": targets,
		"rewrites": [], "chant_scale": scale, "chanted": chanted})
	# 吟唱完整结束(没被打断)：意外渔获之类听这个
	if complete and unit.alive:
		emit("OnChantComplete", unit, targets[0], chanted, ["chant_complete"], {"ability_id": ability.id})


# ---------------------------------------------------------------- 执行(按大类语义)
func execute(ctx: Dictionary) -> void:
	var unit: BUnit = ctx["unit"]
	var ability: AbilityDef = (ctx["entry"] as Dictionary)["ability"]
	# 投射物送达(光箭等)：先画一支飞向目标的投射物，按距离 / 速度算好的时间到了再结算(跟着目标走)
	if str(ability.effect_config.get("delivery", "")) == "projectile" and not bool(ctx.get("landed", false)):
		var spd: float = float(ability.effect_config.get("speed", 14.0))
		var far := 0.0
		for pt0: BUnit in ctx["targets"]:
			if pt0.alive:
				far = maxf(far, unit.pos.distance_to(pt0.pos))
				b.fx({"t": "skill_projectile", "unit": unit, "target": pt0, "kind": str(ability.effect_config.get("projectile", "light_arrow")),
					"flight": far / spd})
		ctx["landed"] = true
		b.pending_exec.append({"at": b.time + far / spd, "ctx": ctx})
		(ctx["ev"]["meta"] as Dictionary)["executed"] = true
		return
	# 天降流星：先画流星落下，fall_time 秒后再按落地时的位置结算(目标位置实时跟随)。
	# 能力配置 stagger > 0：多个目标时一颗接一颗错开落地(第 i 颗晚 i × 间隔，间隔 = min(stagger, stagger_span / (n-1)))，每颗各自结算；
	# 范围命中加成(魔女的火与冰)仍按整次发动在第一颗落地时数好，学习计数也只算一次(meteor_group)
	if str(ability.effect_config.get("delivery", "")) == "meteor" and not bool(ctx.get("landed", false)):
		var fall: float = float(ability.effect_config.get("fall_time", 0.7))
		var live: Array[BUnit] = []
		for mt: BUnit in ctx["targets"]:
			if mt.alive:
				live.append(mt)
		var pts: Array = []
		for mt2: BUnit in live:
			pts.append(mt2.pos)
		var stg: float = float(ability.effect_config.get("stagger", 0.0))
		(ctx["ev"]["meta"] as Dictionary)["executed"] = true
		if stg <= 0.0 or live.size() <= 1:
			b.fx({"t": "meteor_cast", "unit": unit, "points": pts, "fall": fall, "radius": splash_radius(unit, ability)})
			ctx["landed"] = true
			b.pending_exec.append({"at": b.time + fall, "ctx": ctx})
			return
		var gap: float = minf(stg, float(ability.effect_config.get("stagger_span", 1.0)) / float(live.size() - 1))
		var delays: Array = []
		var group := {"aoe": -1.0, "targets": live.duplicate(), "learned": false}
		for i in range(live.size()):
			var dl: float = gap * float(i) + gap * 0.3 * sin(float(i) * 2.7)      # 一颗接一颗，带一点不规则(错落)
			dl = maxf(0.0, dl)
			delays.append(dl)
			var one: Array[BUnit] = [live[i]]
			var c2: Dictionary = ctx.duplicate()
			c2["targets"] = one
			c2["landed"] = true
			c2["meteor_group"] = group
			b.pending_exec.append({"at": b.time + fall + dl, "ctx": c2})
		b.fx({"t": "meteor_cast", "unit": unit, "points": pts, "fall": fall, "delays": delays, "radius": splash_radius(unit, ability)})
		return
	# 投掷送达(血嗜节点·至亲的故事：触发器 extra.delivery = "throw")：装备的武器效果等血球砸到地上才结算——
	# 吟唱完 throw_time 秒(往前一推扔出去 + 飞过去)，没有吟唱再加 cast_time(先抬手做出一颗小血球)。
	# 表现层按 throw_cast 的 land 把血球扔出去、正好这时落地；落地结算时发 throw_land(真正被打到的人)
	var trg0: TriggerDef = ctx.get("trig") as TriggerDef
	if trg0 != null and str(trg0.extra.get("delivery", "")) == "throw" and str((ctx["entry"] as Dictionary)["surface"]) == "equipment":
		if not bool(ctx.get("landed", false)):
			var land: float = float(trg0.extra.get("throw_time", 0.4)) + (0.0 if ctx.has("chanted") else float(trg0.extra.get("cast_time", 0.26)))
			ctx["landed"] = true
			b.fx({"t": "throw_cast", "unit": unit, "land": land, "chanted": ctx.has("chanted")})
			b.pending_exec.append({"at": b.time + land, "ctx": ctx})
			(ctx["ev"]["meta"] as Dictionary)["executed"] = true
			return
		var alive_hit: Array[BUnit] = []
		for th: BUnit in ctx["targets"]:
			if th.alive:
				alive_hit.append(th)
		ctx["targets"] = alive_hit
		b.fx({"t": "throw_land", "unit": unit, "targets": alive_hit.duplicate(), "big": ctx.has("chanted")})
		if alive_hit.is_empty():
			return
	var surface: String = str((ctx["entry"] as Dictionary)["surface"])
	var equip: EquipmentDef = (ctx["entry"] as Dictionary)["equip"] as EquipmentDef
	var value: float = float(ctx["value"])
	# 芯片改写
	var rewrite_target_pct := -1.0
	for rw: Dictionary in ctx["rewrites"]:
		if rw.has("value_from_target_max_health_pct"):
			rewrite_target_pct = float(rw["value_from_target_max_health_pct"])
		if rw.has("value_multiplier"):
			value *= float(rw["value_multiplier"])
	var cls: String = ability.ability_class
	var learn_bonus := 1.0
	if learns(unit, ability):
		learn_bonus = 1.0 + float(unit.learning.get(ability.id, 0)) * learn_bonus_per(unit, ability)
	# 药剂：大成功/大失败方差
	var variance_mult := 1.0
	var variance_tag := ""
	if cls == "potion" and b.cfg.get("potion_variance", true):
		var vc: Dictionary = ability.cfg("variance", {"success": 0.05, "fail": 0.05, "success_mult": 2.0, "fail_mult": 0.0})
		var roll: float = b.roll_good(unit)              # 小 = 大成功、大 = 大失败：真骰取小的
		if roll < float(vc.get("success", 0.05)):
			variance_mult = float(vc.get("success_mult", 2.0))
			variance_tag = "great"
		elif roll > 1.0 - float(vc.get("fail", 0.05)):
			variance_mult = float(vc.get("fail_mult", 0.0))
			variance_tag = "fail"
	var o_base: Dictionary = {"surface": surface, "ability_id": ability.id, "equip_id": equip.id if equip != null else "",
		"is_copy": bool((ctx["ev"]["meta"] as Dictionary).get("is_copy", false))}
	# 普攻：每点法术强度增伤(知识轰炸)
	var na_amp := 1.0          # (知识轰炸的每点法强 +x 普攻伤害现在在增伤乘区里：StatBlock.amp_sum)
	# 前置效果：先作用于触发者自己(例如"先获得状态，再造成伤害")，每次发动一次
	for pre: Variant in ability.effect_config.get("pre_effects", []):
		var pd: Dictionary = pre
		var op: Dictionary = o_base.duplicate()
		op["cfg"] = pd
		_apply_effect(unit, unit, str(pd.get("effect_type", "none")), float(pd.get("fixed_value", 0.0)), ability, op, ctx)
	if ability.effect_config.has("cast_fx"):
		var dead0: BUnit = ((ctx["ev"] as Dictionary).get("meta", {}) as Dictionary).get("dead") as BUnit
		for ct: BUnit in ctx["targets"]:
			b.fx({"t": "cast_fx", "kind": str(ability.effect_config["cast_fx"]), "unit": unit, "target": ct,
				"from": dead0.pos if dead0 != null else unit.pos})
	# 打空的普攻(开枪最快之人：1 米外的目标有概率打空)：普攻载荷什么都不造成
	var ev_meta: Dictionary = (ctx["ev"] as Dictionary)["meta"]
	if surface == "normal_attack" and bool(ev_meta.get("missed", false)):
		ev_meta["executed"] = true
		return
	var allow_dead: bool = str((ctx["ev"] as Dictionary).get("timing", "")) in ["OnBattleEnd", "OnTeamWiped", "OnUnitDied"] \
		or bool(ability.effect_config.get("revive_dead", false))         # 希望：已阵亡的触发目标 = 复活它
	var aoe_mult: float
	var mgroup: Dictionary = ctx.get("meteor_group", {})
	if mgroup.is_empty():
		aoe_mult = _aoe_mult(unit, ability, ctx)
	else:
		# 错开落地的流星：整次发动的范围命中加成在第一颗落地时按当时还活着的全部目标数好，之后每颗都用它
		if float(mgroup["aoe"]) < 0.0:
			var all_t: Array[BUnit] = []
			for gt: BUnit in mgroup["targets"]:
				if gt.alive:
					all_t.append(gt)
			mgroup["aoe"] = _aoe_mult(unit, ability, {"targets": all_t})
		aoe_mult = float(mgroup["aoe"])
	# 触发时施加者血量低于某比例 → 倍率(例如"低于 10% 时伤害 ×3"；濒死结算时血量可能已经 ≤ 0，也算)。
	# 在发动的那一刻判定一次：第一下的吸血把血吸回来，也不影响同一次发动里后面几个目标
	var hp_mult := 1.0
	var hb: Dictionary = ability.effect_config.get("mult_if_source_hp_below", {})
	if not hb.is_empty() and unit.hp_ratio() < float(hb.get("ratio", 0.1)):
		hp_mult = float(hb.get("mult", 1.0))
	# 连锁(炽霞)：window 秒内这个能力每已发动一次，数值 × mult(同一刻引爆 10 层剑痕 = ×1、×1.05、×1.05² …)
	var chain: Dictionary = ability.effect_config.get("chain", {})
	if not chain.is_empty():
		var ck: String = "chain_" + ability.id
		var recent: Array = []
		for ct0: Variant in unit.meta.get(ck, []):
			if b.time - float(ct0) <= float(chain.get("window", 0.1)) + 0.0001:
				recent.append(ct0)
		hp_mult *= pow(float(chain.get("mult", 1.0)), float(recent.size()))
		recent.append(b.time)
		unit.meta[ck] = recent
	# 同一次发动里所有落点先记下来：前面的溅射打死了后面的主目标，后面那一发照样在原地炸开(流星一起落地)
	var start_pos: Dictionary = {}
	for t0: BUnit in ctx["targets"]:
		if t0.alive:
			start_pos[t0] = t0.pos
		elif ctx.has("meteor_group"):
			start_pos[t0] = t0.pos                  # 错开落地的流星：主目标先被前面那颗炸死了，这一颗照样在它倒下的地方炸开
	for t: BUnit in ctx["targets"]:
		var t_alive: bool = t.alive or allow_dead
		if not t_alive and not (start_pos.has(t) and ability.has_keyword("splash")):
			continue
		var eff_type: String = ability.effect_type
		if surface == "normal_attack" and eff_type == "physical_damage" and (unit.has_flag("na_magic") or unit.def.na_scaling == "ability_power"):
			eff_type = "magic_damage"               # 知识轰炸 / 按法强算的普攻(灾星节点的火流星)：法术伤害
		var mag_kind: String = magazine_kind(unit) if surface == "normal_attack" and eff_type.ends_with("_damage") else ""
		if mag_kind != "":
			eff_type = mag_kind + "_damage"          # 适应改造 / 成品完工：这个弹匣的伤害类型
		if surface == "normal_attack" and t != null and t.team == unit.team and t != unit:
			var nae: Variant = status_meta(unit, "na_ally_effect")
			if nae != null:
				eff_type = str(nae)                  # 金矢：射向队友的普攻 = 给他回充能 + 黄金的指引(不造成伤害)
		var backstab: bool = surface == "normal_attack" and eff_type.ends_with("_damage") and unit.has_flag("backstab") and is_behind(unit, t)
		if backstab:
			eff_type = "true_damage"                 # 无声无息：从背后发动的普攻 = 真实伤害、必定暴击
		var mult: float = ability.value_multiplier
		var branch_cfg: Dictionary = {}
		# 护符：按目标阵营分支(双模转化)
		if ability.effect_config.has("ally_effect") or ability.effect_config.has("enemy_effect"):
			var key: String = "ally_effect" if t.team == unit.team else "enemy_effect"
			if ability.effect_config.has(key):
				var br: Dictionary = ability.effect_config[key]
				eff_type = str(br.get("effect_type", eff_type))
				mult = float(br.get("value_multiplier", mult))
				if br.has("cfg"):
					branch_cfg = br["cfg"]
		var amount: float
		if cls == "bullet":
			amount = ability.fixed_value
		else:
			var v: float = value
			if rewrite_target_pct >= 0.0:
				v = t.get_stats().max_health * rewrite_target_pct
			# 按目标算的触发数值(善良地：r × 目标身上沉醉的层数 + f)
			var trg: TriggerDef = ctx.get("trig") as TriggerDef
			if trg != null and trg.base_value_mode == "target_status_stacks":
				v = trg.ratio_for(unit.star) * float(t.status_stacks(trg.base_value_status_id)) + trg.flat_for(unit.star)
			amount = v * mult
		amount *= learn_bonus * variance_mult * na_amp * float(ctx.get("chant_scale", 1.0))
		# 施加者身上有某状态时翻倍(例如"缩头"时护盾充能翻倍)
		for sid: String in (ability.effect_config.get("mult_if_source_status", {}) as Dictionary).keys():
			if unit.status_stacks(sid) > 0:
				amount *= float(ability.effect_config["mult_if_source_status"][sid])
		if ability.effect_config.has("scale_by_missing_health"):
			amount *= 1.0 + float(ability.effect_config["scale_by_missing_health"]) * (1.0 - unit.hp_ratio())
		amount *= hp_mult * aoe_mult
		var o: Dictionary = o_base.duplicate()
		o["can_crit"] = ability.has_keyword("crit")
		# 强化普攻：基础伤害(所有增减伤之前)加上固定值、必定暴击；次数用完后必定不暴击、伤害打折
		if surface == "normal_attack":
			var nm: Dictionary = (ctx["ev"] as Dictionary)["meta"]
			if nm.has("na_scale"):
				amount *= float(nm["na_scale"])
			if nm.has("na_amp_bonus"):
				o["amp_bonus"] = float(nm["na_amp_bonus"])      # 完美时计：停顿的增伤(和其它增伤同一个乘区)
			if nm.has("dmg_cap"):
				o["dmg_cap"] = float(nm["dmg_cap"])
			if nm.has("na_bonus_raw"):
				amount += float(nm["na_bonus_raw"])
			if bool(nm.get("na_force_crit", false)) or backstab:
				o["force_crit"] = true
				if backstab:
					o["can_crit"] = true
					b.fx({"t": "backstab", "unit": unit, "target": t})
			if bool(nm.get("na_no_crit", false)):
				o["no_crit"] = true
				amount *= float(nm.get("na_after_mult", 1.0))
		o["cfg"] = ability.effect_config
		if not branch_cfg.is_empty():
			var bc: Dictionary = ability.effect_config.duplicate(true)
			bc.merge(branch_cfg, true)
			o["cfg"] = bc
		if mag_kind == "true" and bool(unit.meta.get("na_dual", false)):
			var dcfg: Dictionary = ability.effect_config.duplicate()
			dcfg["dual_kind"] = true                 # 成品完工：真实伤害，同时吃物理和魔法伤害的加成 / 吸血
			o["cfg"] = dcfg
		o["ev_meta"] = (ctx["ev"] as Dictionary)["meta"]
		o["variance"] = variance_tag
		if t_alive:
			_apply_effect(unit, t, eff_type, amount, ability, o, ctx)
		# 溅射：对目标周围(不分敌我)造成 50% 效果(目标已经倒下就在它原来的位置炸)
		# (splash_is_range：这个【溅射】只是一个范围，效果自己处理——渡星而来)
		if ability.has_keyword("splash") and not bool(ability.effect_config.get("splash_is_range", false)) and not bool(ev_meta.get("no_splash", false)):
			_splash(unit, t.pos if t.alive else start_pos.get(t, t.pos), t, eff_type, amount, ability, o, ctx, surface)
		if not t_alive:
			continue
		# 额外效果(同一载荷里的附带效果，如"造成伤害并回复自身")
		for extra: Variant in ability.effect_config.get("extra_effects", []):
			var ex: Dictionary = extra
			var ex_targets: Array[BUnit] = []
			match str(ex.get("target", "target")):
				"self":
					ex_targets = [unit]
				"target":
					ex_targets = [t]
				_:
					ex_targets = [t]
			var ex_amount: float = float(ex.get("fixed_value", 0.0)) + amount * float(ex.get("value_multiplier", 0.0))
			for et: BUnit in ex_targets:
				var o3: Dictionary = o.duplicate()
				o3["cfg"] = ex
				_apply_effect(unit, et, str(ex.get("effect_type", "none")), ex_amount, ability, o3, ctx)
	# 打地板：没有直接目标，落点周围照样溅射
	if (ctx["targets"] as Array).is_empty() and ctx.get("aim_point") is Vector2 and ability.has_keyword("splash"):
		var gv: float = value * ability.value_multiplier * learn_bonus * variance_mult * na_amp * aoe_mult * float(ctx.get("chant_scale", 1.0))
		if cls == "bullet":
			gv = ability.fixed_value * learn_bonus * variance_mult * float(ctx.get("chant_scale", 1.0))
		var og: Dictionary = o_base.duplicate()
		og["can_crit"] = ability.has_keyword("crit")
		og["cfg"] = ability.effect_config
		og["ev_meta"] = (ctx["ev"] as Dictionary)["meta"]
		og["variance"] = variance_tag
		_splash(unit, ctx["aim_point"], null, ability.effect_type, gv, ability, og, ctx, surface)
	# 学习计数(典籍等；魔力增长技巧下的法典效果也学)；错开落地的一组流星只算一次
	var mg2: Dictionary = ctx.get("meteor_group", {})
	if learns(unit, ability) and not bool(mg2.get("learned", false)):
		if not mg2.is_empty():
			mg2["learned"] = true
		var lc: Dictionary = ability.cfg("learning", {})
		var cap: int = int(lc.get("cap", 99))
		unit.learning[ability.id] = mini(cap, int(unit.learning.get(ability.id, 0)) + int(lc.get("per_activation", 1)))
	(ctx["ev"]["meta"] as Dictionary)["executed"] = true


## 伤害类行动的"范围命中加成"(魔女的火与冰)：这一次发动里以[群攻]打到的目标 + 被[溅射]波及的单位(去重)，
## 每个 +aoe_hit_amp_pct 的最终伤害，友方算 2 个。在发动(落地)那一刻按当时的位置先数好，这一发里所有伤害都乘同一个倍率
func _aoe_mult(unit: BUnit, ability: AbilityDef, ctx: Dictionary) -> float:
	var amp: float = unit.get_stats().aoe_hit_amp_pct
	if amp <= 0.0:
		return 1.0
	var dmg: bool = ability.effect_type.ends_with("_damage") or ability.effect_config.has("enemy_effect")
	var sp: bool = ability.has_keyword("splash")
	var ma: bool = ability.has_keyword("multi_attack")
	if not dmg or not (sp or ma):
		return 1.0
	var hit: Dictionary = {}
	var mains: Array[BUnit] = []
	for t: BUnit in ctx["targets"]:
		if t.alive:
			mains.append(t)
	if ma:
		for t2: BUnit in mains:
			hit[t2] = true
	if sp:
		var rad: float = splash_radius(unit, ability)
		var centers: Array = []
		for t3: BUnit in mains:
			centers.append([t3.pos, t3])
		if mains.is_empty() and ctx.get("aim_point") is Vector2:
			centers.append([ctx["aim_point"], null])
		for c: Array in centers:
			for o: BUnit in b.units:
				if o.alive and o != c[1] and o.pos.distance_to(c[0]) <= rad + o.radius:
					hit[o] = true
	var cnt := 0
	for o2: BUnit in hit.keys():
		cnt += 2 if o2.team == unit.team else 1
	return 1.0 + amp * float(cnt)


## [溅射]：以 center 为圆心、半径 splash_radius 内的所有单位(不分敌我，exclude 除外)受 50% 效果。
## 能力配置可以改：splash_ratio(溅射出去的比例，赤焰战旗 = 1/4)、splash_filter = "target_allies"(只波及直接目标的队友，不影响敌人)
func _splash(unit: BUnit, center: Vector2, exclude: BUnit, eff_type: String, amount: float, ability: AbilityDef, o: Dictionary, ctx: Dictionary, surface: String) -> void:
	# (黄金的指引：持有者的"敌我不分"改为"仅限敌人"——溅射不再波及队友，见下面的 enemies_only)
	var rad: float = splash_radius(unit, ability) * float(o.get("splash_rad_mult", 1.0))     # 灭罪节点的光束：半径随"照亮长夜"增长
	var scfg: Dictionary = o.get("cfg", ability.effect_config)
	var ratio: float = float(scfg.get("splash_ratio", 0.5))
	var only_team: int = -1
	if str(scfg.get("splash_filter", "")) == "target_allies":
		only_team = exclude.team if exclude != null else unit.team
	for other: BUnit in b.units.duplicate():
		if not other.alive or other == exclude:
			continue
		if only_team >= 0 and other.team != only_team:
			continue
		if only_team < 0 and other.team == unit.team and eff_type.ends_with("_damage") and unit.has_flag("enemies_only"):
			continue                                   # 黄金的指引：伤害溅射不再波及队友
		if other.pos.distance_to(center) <= rad + other.radius:
			var o2: Dictionary = o.duplicate()
			o2["splash"] = true
			_apply_effect(unit, other, eff_type, amount * ratio, ability, o2, ctx)
	# style：能力配置的溅射外观(爱心针剂 = heart)；heal_ally：直接目标是友方、这一发被广义治疗转成了治疗(表现层画治疗的溅射，不画爆炸)
	var heal_ally: bool = exclude != null and exclude.team == unit.team and unit.get_stats().na_ally_heal_pct > 0.0 and Effects.is_na_damage(o)
	b.fx({"t": "splash", "pos": center, "radius": rad, "surface": surface, "src": unit, "target": exclude, "effect": eff_type,
		"style": str((o.get("cfg", ability.effect_config) as Dictionary).get("splash_fx", "")), "heal_ally": heal_ally})


func _apply_effect(unit: BUnit, t: BUnit, eff_type: String, amount: float, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	match eff_type:
		"physical_damage", "magic_damage", "true_damage":
			var kind: String = eff_type.replace("_damage", "")
			# sourceless：没有施加者(地形效果：被电车撞、被喷泉的火弧砸中)——不算任何单位造成的，也不吃它的属性
			var dsrc: BUnit = null if bool((o.get("cfg", ability.effect_config) as Dictionary).get("sourceless", false)) else unit
			# 广义治疗(护理节点)：对友方本应造成的普攻伤害(包括"视为普攻伤害"的效果)改为治疗；溅射到敌人的那部分照常是伤害
			if dsrc != null and t.team == unit.team and unit.get_stats().na_ally_heal_pct > 0.0 and Effects.is_na_damage(o):
				_na_heal(unit, t, amount, kind, ability, o)
				return
			var dealt: float = fx.damage(dsrc, t, amount, kind, o)
			var em: Dictionary = o.get("ev_meta", {})
			em["dealt"] = float(em.get("dealt", 0.0)) + dealt
			# 伤害打出去后，给当前血量最少的非满血队友回复等量生命(监护人的光箭)
			if bool((o.get("cfg", ability.effect_config) as Dictionary).get("heal_lowest_ally", false)) and dealt > 0.0:
				var low: BUnit = null
				for a: BUnit in b.units:
					if a.alive and a.team == unit.team and a != unit and a.hp < a.get_stats().max_health - 0.5 and (low == null or a.hp < low.hp):
						low = a
				if low != null:
					fx.heal(unit, low, dealt, {"surface": "equipment" if o.get("surface", "") == "equipment" else "passive", "raw": true,
						"ability_id": ability.id})
		"heal":
			var can_crit: bool = bool(o.get("can_crit", false))
			var amt: float = amount
			if can_crit and b.roll_good(unit) < clampf(unit.get_stats().crit_chance, 0.0, 1.0):
				amt *= maxf(1.0, unit.get_stats().crit_damage)
			# 希望(revive_dead)：对象已阵亡 → 以这次的回复量复活(回复量照常吃治疗量加成 / 受治疗加成)
			if not t.alive:
				# revive_summons：召唤物也能复活(祝福之心)；revive_mult：复活时的生命 = 回复量 × 这么多(祝福之心 n)；revive_kind：表现
				var rcfg: Dictionary = o.get("cfg", ability.effect_config)
				if bool(rcfg.get("revive_dead", false)) and t.team == unit.team and (not t.is_summon or bool(rcfg.get("revive_summons", false))):
					var rv: float = unit.get_stats().calc_heal(t.get_stats(), amt * float(rcfg.get("revive_mult", 1.0)))
					var rkind: String = str(rcfg.get("revive_kind", "hope"))
					b.revive(t, 0.0, rv, rkind)
					unit.st_heal += t.hp
					b.fx({"t": rkind + "_revive", "unit": unit, "target": t, "hp": t.hp})
					b.fx({"t": "heal", "src": unit, "dst": t, "amount": t.hp, "over": 0.0, "surface": str(o.get("surface", "equipment")),
						"ability": ability.id, "equip": o.get("equip_id", ""), "splash": false, "crit": false, "na_heal": false})
				return
			var hr: Dictionary = fx.heal(unit, t, amt, o)
			# 溢出的治疗转成护盾(硬质手杖)
			var ocfg: Dictionary = o.get("cfg", ability.effect_config)
			if bool(ocfg.get("overheal_to_shield", false)) and float(hr.get("overheal", 0.0)) > 0.5:
				# 护盾上限(目标最大生命的比例)：溢出转来的护盾最多把护盾补到这么多
				var room: float = float(hr["overheal"])
				if ocfg.has("shield_cap_pct"):
					room = minf(room, maxf(0.0, t.get_stats().max_health * float(ocfg["shield_cap_pct"]) - t.shield))
				if room > 0.5:
					fx.add_shield(unit, t, room, o)
		"shield":
			fx.add_shield(unit, t, amount, o)
		"stat_status":
			var cfg: Dictionary = (o.get("cfg", ability.effect_config) as Dictionary).duplicate(true)
			cfg["status_id"] = str(cfg.get("status_id", ability.id))
			# mult_if_chanting：触发者正在吟唱(拉弓蓄力也算吟唱)或这次是蓄过力的普攻时，状态数值 × 倍率(无声琴)
			if cfg.has("mult_if_chanting") and is_chanting(unit, o):
				_scale_status_cfg(cfg, float(cfg["mult_if_chanting"]))
				cfg["chant_doubled"] = true
			# 数值来自触发数值的强化可以暴击(赤焰战旗【暴击】：强化量 × 暴击伤害)；溅射出去的那部分沿用主目标这一下的结果
			var amt_used: bool = str(cfg.get("value_mode", "")) == "amount_pct" or cfg.has("amount_pct_stats")
			if amt_used and bool(o.get("can_crit", false)):
				if not o.has("status_crit"):
					o["status_crit"] = b.roll_good(unit) < clampf(unit.get_stats().crit_chance, 0.0, 1.0)
				if bool(o["status_crit"]):
					amount *= maxf(1.0, unit.get_stats().crit_damage)
					cfg["crit"] = true
			# 持续伤害每跳 = 触发数值(守林节点·中毒：x × (100 + 法强)%)
			if bool(cfg.get("dot_from_value", false)) and cfg.has("dot"):
				(cfg["dot"] as Dictionary)["amount"] = amount
				cfg["stats"] = {}
			# 加几层 = 触发数值(正色百合：每 3 秒 1 层、队友阵亡 3 层、治疗队友 2 层……都配同一个能力)
			if bool(cfg.get("add_stacks_from_value", false)):
				cfg["add_stacks"] = maxi(1, int(round(amount)))
			# 按施加者星级加几层(凯旋：1/1/2 层)
			if cfg.has("add_stacks_by_star"):
				var abs_: Dictionary = cfg["add_stacks_by_star"]
				cfg["add_stacks"] = int(abs_.get(str(mini(unit.star, 3)), abs_.get(mini(unit.star, 3), 1)))
			# 弹匣容量 = 这个被动的【叠加 N】(开枪最快之人)
			if bool(cfg.get("ammo_from_stacking", false)):
				var mm: Dictionary = (cfg.get("meta", {}) as Dictionary).duplicate(true)
				mm["ammo_cap"] = maxi(1, kw_value(unit, ability, "stacking", 1))
				cfg["meta"] = mm
				cfg["max_stacks"] = 1
			if cfg.has("amount_flat_stats"):
				# 触发数值 × 系数，当作这几项属性的固定加成(拖后腿：伤害增幅、伤害减免各 -触发数值)
				var stf: Dictionary = {}
				for sk2: Variant in (cfg["amount_flat_stats"] as Dictionary).keys():
					stf[str(sk2)] = {"flat": amount * float(cfg["amount_flat_stats"][sk2])}
				cfg["stats"] = stf
			elif cfg.has("amount_pct_stats"):
				# 触发数值当作这几项属性的百分比加成(赤焰战旗：攻击力与攻速)
				var sts: Dictionary = {}
				for sk: Variant in cfg["amount_pct_stats"]:
					sts[str(sk)] = {"pct": amount}
				cfg["stats"] = sts
			elif str(cfg.get("value_mode", "")) == "amount_pct":
				cfg["pct"] = amount                       # 触发数值当作百分比加成(0.1 = +10%)
			elif not cfg.has("flat") and not cfg.has("pct") and not cfg.has("stats") and not cfg.has("stats_by_star"):
				cfg["flat"] = amount
			if cfg.has("max_stacks_from_passive"):
				# 层数上限 = 另一个被动的【叠加 N】(剑痕与不灭共用；不灭还没解锁时也按它的数值，写在 max_stacks 里的是兜底)
				var pa: AbilityDef = unit.def.passive_by_id(str(cfg["max_stacks_from_passive"]))
				cfg["max_stacks"] = kw_value(unit, pa, "stacking", int(cfg.get("max_stacks", 1)))
			cfg["max_stacks"] = maxi(1, kw_value(unit, ability, "stacking", int(cfg.get("max_stacks", 1))))
			if bool(cfg.get("per_source", false)):
				# 每个施加者各自维持 1 层；【叠加 N】= 最多几个施加者的份(天空视野：每只鸟 1 层，最多 3 层)
				cfg["max_sources"] = int(cfg.get("max_sources", cfg["max_stacks"]))
				cfg["max_stacks"] = 1
			cfg["eternal"] = ability.has_keyword("eternal")
			# sourceless：没有施加者(地形效果)——状态的持续伤害不算任何单位造成的，也不吃施加者的属性
			# repeat：一次施加 N 次(每次独立的状态如【燃烧】= N 个实例；虚荣的余烬·煌然 带着虚荣时施加 3 次)
			for _i in range(maxi(1, int(cfg.get("repeat", 1)))):
				fx.apply_status(null if bool(cfg.get("sourceless", false)) else unit, t, cfg, o)
		"dispel":
			# 驱散：目标是敌人 = 驱散增益，是友军 = 净化负面；每次最多 count 个(count_by_star 按星级取；带 dispel_one 的状态每次只去 1 层)；
			# order = "longest" 时剩余持续时间最长的先驱散(一对一看护)
			var dcfg: Dictionary = o.get("cfg", ability.effect_config)
			var dcount: int = int(dcfg.get("count", 1))
			if dcfg.has("count_by_star"):
				var cbs: Dictionary = dcfg["count_by_star"]
				dcount = int(cbs.get(str(mini(unit.star, 3)), cbs.get(mini(unit.star, 3), dcount)))
			fx.dispel(unit, t, str(dcfg.get("what", "buff" if t.team != unit.team else "debuff")), maxi(1, dcount), str(dcfg.get("order", "")))
		"flag_status":
			var cfg2: Dictionary = (o.get("cfg", ability.effect_config) as Dictionary).duplicate(true)
			cfg2["status_id"] = str(cfg2.get("status_id", ability.id))
			cfg2["max_stacks"] = 1
			fx.apply_status(unit, t, cfg2, o)
		"health_cost_damage":
			# 流失当前生命的 health_cost_current_pct，或最大生命的 health_cost_max_pct(守誓节点·誓血仇)；最多流失到剩 1 点
			var cost: float = unit.hp * float(ability.cfg("health_cost_current_pct", 0.1))
			if ability.effect_config.has("health_cost_max_pct"):
				cost = minf(unit.get_stats().max_health * float(ability.cfg("health_cost_max_pct", 0.1)), maxf(0.0, unit.hp - 1.0))
			unit.hp = maxf(1.0, unit.hp - cost)
			var mults: Dictionary = ability.cfg("damage_multiplier_by_star", {})
			var m: float = float(mults.get(str(mini(unit.star, 3)), mults.get(mini(unit.star, 3), 2.0)))
			b.fx({"t": "self_cost", "unit": unit, "amount": cost})
			fx.damage(unit, t, cost * m, str(ability.cfg("damage_kind", "physical")), o)
		"summon":
			fx.summon(unit, ability.effect_config, o)
		"max_health_up":
			fx.max_health_up(unit, t, amount)
		"heal_to_full":
			# 回复生命至上限(光色誓约：即将阵亡时)；不吃治疗加成
			fx.heal(unit, t, maxf(0.0, t.get_stats().max_health - t.hp), {"raw": true, "surface": "passive", "ability_id": ability.id})
			b.fx({"t": "oath_save", "unit": t, "src": unit})
		"weapon_throw":
			fx.weapon_throw(unit, t, amount, ability, o)
		"create_orbs":
			fx.create_orbs(unit, t, amount, o.get("cfg", ability.effect_config))
		"edict":
			_edict(unit, t, amount, ability, o)
		"empower_shots":
			# 大口径子弹：不可叠加、不可驱散、无限持续；再次获得时重置次数(基础伤害加成按这一次的触发数值)
			var ecfg: Dictionary = o.get("cfg", ability.effect_config)
			fx.apply_status(unit, t, {"status_id": str(ecfg.get("status_id", ability.id)), "flags": ["buff", "no_dispel"], "max_stacks": 1,
				"empower": {"left": int(ecfg.get("count", 6)), "count": int(ecfg.get("count", 6)), "bonus": amount,
					"after_mult": float(ecfg.get("after_mult", 0.7))}}, o)
		"status_cost_heal":
			_status_cost_heal(unit, t, ability, o)
		"status_stack_heal":
			_status_stack_heal(unit, t, ability, o)
		"hunter_notes":
			_hunter_notes(unit, t, ability, o, ctx)
		"rainbow_missiles":
			_rainbow_missiles(unit, amount, ability, o, ctx)
		"familiar_marks":
			_familiar_marks(unit, ability, o, ctx)
		"rainbow_spark":
			_rainbow_spark(unit, t, amount, ability, o)
		"fish_pull":
			_fish_pull(unit, t, ability, o)
		"blade_storm":
			_blade_storm(unit, ability, o, ctx)
		"starfall_impact":
			_starfall_impact(unit, amount, ability, o)
		"adapt_magazine":
			_adapt_magazine(unit, ability, o)
		"paint":
			_paint(unit, ability, o, ctx)
		"knockback":
			_knockback(unit, t, amount, o)
		"mislead":
			_mislead(unit, t, ability, o)
		"golden_arrow":
			_golden_arrow(unit, t, o)
		"team_revive":
			_team_revive(unit, ability, o)
		"refresh_once":
			# 至远的弓弦：刷新触发目标"每场战斗限一次"的技能
			if t != null and (t.meta.get("once_used", {}) as Dictionary).size() > 0:
				t.meta["once_used"] = {}
				b.fx({"t": "refresh_once", "unit": t, "src": unit})
		"medium_summon":
			_medium_summon(unit, t, ability, o, ctx)
		"medium_wisp":
			_medium_wisp(unit, ability, o)
		"medium_funeral":
			_medium_funeral(unit, ability, o, ctx)
		"summon_ghost_behind":
			# 魔典：在触发目标背后召唤一只幽灵，首次攻击额外 触发数值 × n 的伤害
			if t != null and t.alive and t.team != unit.team:
				var cfgg: Dictionary = o.get("cfg", ability.effect_config)
				var gd: UnitDef = b.catalog.get_unit(str(cfgg.get("unit_id", "node_ghost")))
				if gd != null:
					fx.summon_one(unit, gd.id, behind_pos(t, gd.radius), {"first_hit_bonus": amount}, t)
		"spy_hush":
			_spy_hush(unit, ability, o, ctx)
		"grant_reward":
			# 获得 触发数值 点金币和经验(万语千言)
			var amt: int = int(round(amount))
			if amt > 0:
				b.grant_gold(unit.team, amt, unit)
				b.grant_xp(unit.team, amt, unit)
		"magi_finale":
			_magi_finale(unit, amount, ability, o, ctx)
		"bonus_shots":
			_bonus_shots(unit, ability, o)
		"lose_stack":
			_lose_stack(unit, t, ability, o)
		"aura_taunt":
			_aura_taunt(unit, ability, o)
		"death_delay":
			_death_delay(unit, ability, o)
		"hp_loss_pct":
			_hp_loss_pct(unit, t, amount, ability, o, ctx)
		"blink_strike":
			_blink_strike(unit, t, amount, ability, o)
		"instant_attack":
			# 易用短弓：以一发免前后摇的普攻立刻攻击目标；触发数值每 100 点，这一发造成原伤害的 n%(n = 能力倍率)
			if t != null and t.alive and unit.alive and unit.can_attack():
				b.fx({"t": "instant_shot", "unit": unit, "target": t})
				var ic: Dictionary = o.get("cfg", ability.effect_config)
				var iopts := {"instant": true, "na_scale": float(ic["na_scale"]) if ic.has("na_scale") else amount / 100.0}
				if bool(ic.get("cap_by_value", false)):
					iopts["dmg_cap"] = amount            # 飞蝶：这次普攻至多造成触发数值的伤害(追击那发也是)
				b.deliver_normal_attack(unit, t, false, iopts)
		"oath_bestow":
			_oath_bestow(unit, t, amount, ability)
		"oath_bind":
			_oath_bind(unit)
		"status_detonate":
			_detonate(unit, t, amount, ability, o)
		"consume_status":
			_consume(unit, t, ability, o)
		"entangle":
			_entangle(unit, t, ability)
		"taunt":
			fx.taunt(unit, float(ability.cfg("radius", 0.0)), float(ability.cfg("duration", 4.0)))
		"blink":
			fx.blink_best_cleave(unit, float(ability.cfg("max_distance", 3.0)), float(ability.cfg("cleave_radius", 1.6)))
		"grant_gold":
			b.grant_gold(unit.team, int(round(amount)), unit)
		"create_field":
			var fcfg: Dictionary = o.get("cfg", ability.effect_config)
			fx.create_field(unit, t.pos, fcfg, amount)
		"dash_strike":
			fx.dash_strike(unit, ability, amount, o)
		"escort_dash":
			fx.escort_dash(unit, ability, o)
		"reset_uses":
			# 重置若干触发器本场已用的次数(例如"击杀后重置狼狩与再来一次")
			var rcf: Dictionary = o.get("cfg", ability.effect_config)
			var did := false
			for tid: Variant in rcf.get("triggers", []):
				if int(unit.trig_acts.get(str(tid), 0)) > 0:
					did = true
				unit.trig_acts[str(tid)] = 0
			if did:
				b.fx({"t": "uses_reset", "unit": unit})
		"random_status":
			# 从几种效果里随机取一种施加(每次施加相互独立)；强度 = base + per_learning × 本次发动时的学习计数
			var rcfg: Dictionary = o.get("cfg", ability.effect_config)
			var opts: Array = rcfg.get("options", [])
			if opts.is_empty():
				return
			var pick: Dictionary = opts[b.rng.randi() % opts.size()]
			var lcfg2: Dictionary = ability.cfg("learning", {})
			var learn_now: int = int(unit.learning.get(ability.id, 0)) + int(lcfg2.get("per_activation", 1))
			var v2: float = float(pick.get("base", 0.0)) + float(pick.get("per_learning", 0.0)) * float(learn_now)
			var scfg := {"status_id": str(rcfg.get("status_id", ability.id)), "duration": float(rcfg.get("duration", 6.0)),
				"flags": rcfg.get("flags", []), "independent": bool(rcfg.get("independent", false)),
				"stats": {str(pick["stat"]): {str(pick.get("mode", "flat")): v2}},
				"variant": str(pick.get("tag", "")), "variant_value": v2}
			fx.apply_status(unit, t, scfg, o)
		"bleed":
			_bleed(unit, t, ability, o)
		"blood_feast":
			_blood_feast(unit, ability, o)
		"kin_consume":
			_kin_consume(unit, t, ability, o, ctx)
		"blood_rupture":
			_blood_rupture(unit, t, amount, ability, o, ctx)
		"charged_strike":
			# 紫电：身上有蓄能 → 对目标造成触发数值的魔法伤害，然后消耗蓄能
			var csid2: String = str((o.get("cfg", ability.effect_config) as Dictionary).get("status_id", ""))
			if t != null and t.alive and unit.statuses.has(csid2):
				fx.remove_status(unit, csid2)
				var od: Dictionary = o.duplicate()
				od["can_crit"] = false
				fx.damage(unit, t, amount, "magic", od)
				b.fx({"t": "charged_strike", "unit": unit, "target": t})
		"bump_buff_stacks":
			_bump_buff_stacks(unit, ability, o)
		"shadow_step":
			_shadow_step(unit, t, ability, o)
		"self_cost":
			_self_cost(unit, ability, o)
		"shadow_slay":
			_shadow_slay(unit, amount, ability, o)
		"shadow_rot":
			_shadow_rot(unit, t, ability, o)
		"commando_lunge":
			_commando_lunge(unit, ability, o)
		"mark_volley":
			_mark_volley(unit, ability, o)
		"cover_retarget":
			_cover_retarget(unit, t)
		"clear_own_status":
			# 把自己身上的某个状态整个清掉(集中呼吸：被近战敌人够得着时重置)
			var csid: String = str((o.get("cfg", ability.effect_config) as Dictionary).get("status_id", ""))
			if unit.statuses.has(csid):
				fx.remove_status(unit, csid)
				b.fx({"t": "status_reset", "unit": unit, "status": csid})
		"lily_rebloom":
			_lily_rebloom(unit, ability, ctx)
		"lily_tick":
			_lily_tick(unit, ability)
		"lily_cone_heal":
			_lily_cone_heal(unit, amount, ability, o)
		"warden_shift":
			_warden_shift(unit, ability, o)
		"wild_will":
			# 荒野意志：恢复 1 点生命(本该倒下的这一刻)，获得 触发数值 的护盾
			if t != null and t.alive:
				t.hp = maxf(t.hp, 0.0) + 1.0
				fx.add_shield(unit, t, amount, o)
		"verdant_grove":
			_verdant_grove(unit, t, amount, ability, o)
		"weather_change":
			# 变天(导向节点)：按这一场所在的章节换天气(cfg.by_chapter：章节颜色 → 天气；没写的章节没有效果)
			var wcfg: Dictionary = o.get("cfg", ability.effect_config)
			var wk: String = str((wcfg.get("by_chapter", {}) as Dictionary).get(b.chapter_color, ""))
			if wk != "":
				b.set_weather(wk, unit, (wcfg.get("params", {}) as Dictionary).get(wk, {}))
		"paralyze":
			_paralyze(unit, t, amount, ability, o)
		"quake_slam":
			_quake_slam(unit, amount, ability, o)
		"pickpocket":
			_pickpocket(unit, ability, o)
		"world_dice":
			_world_dice(unit, amount, ability, o)
		"petrify_wake":
			_petrify_wake(unit, ability, o)
		"dice_damage":
			_dice_damage(unit, t, amount, ability, o)
		"pianist_form":
			_pianist_form(unit, ability, o)
		"pianist_flip":
			_pianist_flip(unit, ability, o)
		"mood_stack":
			_mood_stack(unit, t, amount, ability, o)
		"black_keys":
			_black_keys(unit, t, amount, ability, o)
		"summon_aura":
			_summon_aura(unit, amount, ability, o, ctx)
		"charge_refill":
			_charge_refill(unit, ability, o, ctx)
		"charge_scaled_damage":
			_charge_scaled_damage(unit, t, amount, ability, o)
		"lock_all":
			_lock_all(unit, amount, ability, o)
		"gather_stun":
			_gather_stun(unit, t, amount, ability, o, ctx)
		"mass_production":
			_mass_production(unit, ability, o)
		"phantom_strike":
			_phantom_strike(unit, ability, o, ctx)
		"selfless_purge":
			_selfless_purge(unit, ability, o)
		"sever":
			# 杀：目标是召唤物 → 移除(不触发阵亡效果)；否则移除其 n% 生命上限(Effects.wither，累计在【斩断之痕】)
			if t != null and t.alive:
				if t.is_summon:
					t.meta["_doomed"] = true
					t.meta["no_death_fx"] = true
					t.hp = 0.0
					b.fx({"t": "sever", "unit": unit, "target": t, "summon": true})
					fx.try_kill(t, unit)
				else:
					var pct: float = float((o.get("cfg", ability.effect_config) as Dictionary).get("pct", 0.06))
					b.fx({"t": "sever", "unit": unit, "target": t, "summon": false})
					fx.wither(unit, t, t.get_stats().max_health * pct, o, "sever_scar")
		"prayer_heal":
			# 治疗祈愿：回复触发数值 + 驱散一个剩余时间最长的(可驱散)负面状态
			if t != null and t.alive:
				fx.heal(unit, t, amount, o)
				fx.dispel(unit, t, "debuff", 1, "longest")
				b.fx({"t": "prayer_heal", "unit": unit, "target": t})
		"true_dice":
			# 真骰：战斗里自己的概率掷两次取好的(规则状态的 flag lucky；Battle.roll_good / roll_bad)；事件里的部分由 Run 读这个被动的配置
			fx.apply_status(unit, unit, {"status_id": "true_dice", "duration": 0.0, "max_stacks": 1, "flags": ["buff", "no_dispel", "hidden", "lucky"]}, o)
		"money_bag":
			_money_bag(unit, t, amount, ability, o)
		"money_bag_tick":
			_money_bag_tick(unit, o)
		"money_bag_cashout":
			_money_bag_cashout(unit)
		"stun_from_value":
			# 每 n 点触发数值眩晕 1 秒(大锤；精英 / 首领照通用规则减半)
			if t != null and t.alive:
				var sdur: float = amount / maxf(1.0, float((o.get("cfg", ability.effect_config) as Dictionary).get("n", 100.0)))
				if sdur > 0.05:
					fx.apply_status(unit, t, {"status_id": "stun", "flags": ["debuff", "dispellable", "stun"], "max_stacks": 1, "duration": sdur}, o)
		"angel_heal":
			# 致向死的渴望：打向队友的普攻 = 回复其最大生命的 heal_pct(她的治疗加成照算)；送葬由"普攻命中"的被动另外叠
			var ac: Variant = status_meta(unit, "angel_alt")
			if t != null and t.alive and ac != null:
				fx.heal(unit, t, t.get_stats().max_health * float((ac as Dictionary).get("heal_pct", 0.03)), {"surface": "normal_attack", "ability_id": "angel_heal"})
		"funeral_mark":
			_funeral_mark(unit, t, ability, o)
		"funeral_save":
			_funeral_save(unit, t, ability, o)
		"gentle_field":
			# 温柔地：开局 duration 秒，所有单位受到的伤害最终降低(按星级)
			var gcfg: Dictionary = o.get("cfg", ability.effect_config)
			var gby: Dictionary = gcfg.get("reduce_by_star", {})
			b.add_gentle(unit, float(gby.get(str(mini(unit.star, 3)), gcfg.get("reduce", 0.5))), float(gcfg.get("duration", 10.0)))
		"intox_song":
			_intox_song(unit, ability, o)
		"holy_sword":
			_holy_sword(unit, t, amount, ability, o)
		"brave_legacy":
			_brave_legacy(unit, ability, o)
		"light_beam":
			_light_beam(unit, amount, ability, o, ctx)
		"light_ramp":
			_light_ramp(unit, ability, o, ctx)
		"absolve":
			_absolve(unit, t, amount, ability, o)
		"regen":
			# 施加【再生】(调香节点：飘香每 x 秒一个，恒古维持一个)
			var rc: Dictionary = o.get("cfg", ability.effect_config)
			if t != null and t.alive:
				fx.apply_regen(unit, t, float(rc.get("duration", 5.0)), [], str(rc.get("regen_id", "")))
		"infuse":
			_infuse(unit, t, amount, ability, o)
		"infusion_pop":
			_infusion_pop(unit, t, ability)
		"perform_tick":
			_perform_tick(unit)
		"perform_echo":
			_perform_echo(unit, ability)
		"ignite_embers":
			_ignite_embers(unit, t, o.get("cfg", ability.effect_config))
		"spread_embers":
			_spread_embers(unit, o.get("cfg", ability.effect_config))
		"permanent_growth":
			var gcfg: Dictionary = o.get("cfg", ability.effect_config)
			b.add_permanent_growth(t if str(gcfg.get("apply_to", "target")) == "target" else unit, str(gcfg.get("stat_id", "max_health")), amount)
		"none":
			pass
		_:
			push_warning("unknown effect_type: %s" % eff_type)


# ---------------------------------------------------------------- 守林节点
const WARDEN_FORMS: Array[String] = ["lion", "spider", "toad", "base"]


## 现在是哪个形态(状态 meta.form)；不在变身形态 = "base"
static func warden_form(u: BUnit) -> String:
	for st: BStatus in u.statuses.values():
		if st.stacks > 0 and st.meta.has("wclass_form"):
			return str((st.meta["wclass_form"] as Dictionary).get("form", "base"))
	return "base"


## 护林狂怒：开战进入 cfg.to(狮子)；本该阵亡时(cfg.next)换成下一个形态：狮子 → 巨蜘蛛 → 巨蟾蜍 → 基础形态(之后再倒下就真的倒下)。
## 形态 = 状态(cfg.forms.<形态>：status_id / stats / wclass_form(攻击模组：攻击形态与所携带的武器无关) / pursuit_by_star)；
## 切换后立刻发 OnFormShift(荒野意志的 1 点生命 + 护盾、原初血脉都在这一刻结算)；还是 ≤ 0 血就留 1 点(形态切换了就是没倒下)
func _warden_shift(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var cur: String = warden_form(unit)
	var to: String = str(cfg.get("to", ""))
	if to == "":
		if cur == "base" or unit.hp > 0.0:
			return                                    # 已经是基础形态：这次就是真的倒下
		to = WARDEN_FORMS[mini(WARDEN_FORMS.find(cur) + 1, WARDEN_FORMS.size() - 1)]
	var forms: Dictionary = cfg.get("forms", {})
	for st: BStatus in unit.statuses.values().duplicate():
		if st.meta.has("wclass_form"):
			fx.end_status(unit, st.id)
	if cur == "toad":
		b.release_binds(unit)                         # 巨蟾蜍的长舌：离开这个形态就松开
	var fd: Dictionary = (forms.get(to, {}) as Dictionary).duplicate(true)
	if not fd.is_empty():
		var wf: Dictionary = (fd.get("wclass_form", {}) as Dictionary).duplicate(true)
		wf["form"] = to
		if fd.has("pursuit_by_star"):
			var kw: Dictionary = (wf.get("na_keywords", {}) as Dictionary).duplicate()
			kw["pursuit"] = int((fd["pursuit_by_star"] as Dictionary).get(str(mini(unit.star, 3)), 1))
			wf["na_keywords"] = kw
		var scfg: Dictionary = {"status_id": str(fd.get("status_id", "form_" + to)), "duration": 0.0, "max_stacks": 1, "flags": ["buff", "no_dispel"],
			"meta": {"wclass_form": wf}}
		if fd.has("stats_by_star"):
			scfg["stats_by_star"] = fd["stats_by_star"]
		fx.apply_status(unit, unit, scfg, o)
	unit.mark_dirty()
	unit.attack_cd = maxf(unit.attack_cd, 0.4)
	if unit.phase in ["windup", "recover", "draw", "reload"]:
		unit.phase = "idle"                           # 换了攻击模组：手上这一招不打了
	var reason: String = "start" if str(cfg.get("to", "")) != "" else "death"
	b.fx({"t": "form_shift", "unit": unit, "form": to, "from": cur, "reason": reason})
	emit_now("OnFormShift", unit, unit, 0.0, ["form_shift"], {"form": to, "reason": reason})
	if unit.hp <= 0.0:
		unit.hp = 1.0


# ---------------------------------------------------------------- 奇兴节点
## 自无数个世界之中【增幅 N】【无数世界】：掷 2d10，结果 = 两颗骰子 + 增幅数 + 已阵亡的队友人数(不算召唤物)。
## 两颗骰子加起来是 2(双 1)：所有人随机交换位置、所有人身上施加随机通用负面状态、所有人受到高额魔法伤害(不分敌我)，别的不再发生；
## 否则——奇数：所有敌人随机交换位置；偶数：所有敌人身上施加一个随机通用负面状态(这一掷抽一种)；
## 再按大小：< 10 小额魔法伤害；≥ 10 中等物理伤害(视为普攻伤害)；≥ 20 高额真实伤害(视为普攻伤害)。伤害 = 档位系数 × (攻击力 + 法术强度)
func _world_dice(unit: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	if not unit.alive:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var d1: int = b.rng.randi_range(1, 10)
	var d2: int = b.rng.randi_range(1, 10)
	var fd: Array = cfg.get("force_dice", [])          # 测试用：指定两颗骰子
	if fd.size() == 2:
		d1 = int(fd[0])
		d2 = int(fd[1])
	var amp: int = kw_value(unit, ability, "amplify", 0)
	var dead: int = b.team_dead_alive(unit.team)[0]
	var total: int = d1 + d2 + amp + dead
	var st: StatBlock = unit.get_stats()
	var base: float = maxf(0.0, st.attack_power) + maxf(0.0, st.ability_power)
	var tiers: Dictionary = cfg.get("tiers", {"low": 0.8, "mid": 1.3, "high": 2.0})
	var pool: Array = cfg.get("debuffs", [])
	var od: Dictionary = {"surface": "passive", "ability_id": ability.id, "cfg": {"damage_category": "skill"}}
	var foes: Array = b.enemies_of(unit)
	var chaos: bool = d1 + d2 == 2
	var tier := ""
	var debuff := ""
	if chaos:
		var everyone: Array = b.units.filter(func(u0: BUnit) -> bool: return u0.alive and not bool(u0.meta.get("dropping", false)))
		b.fx({"t": "dice_roll", "unit": unit, "d1": d1, "d2": d2, "amp": amp, "dead": dead, "total": total, "chaos": true})
		b.shuffle_positions(everyone, unit)
		if not pool.is_empty():
			var dc: Dictionary = pool[b.rng.randi() % pool.size()]
			debuff = str(dc.get("status_id", ""))
			for u1: BUnit in everyone:
				if u1.alive:
					fx.apply_status(unit, u1, dc, od)
		for u2: BUnit in everyone:
			if u2.alive:
				fx.damage(unit, u2, base * float(tiers.get("high", 2.0)), "magic", od)
		return
	tier = "low" if total < 10 else ("mid" if total < 20 else "high")
	b.fx({"t": "dice_roll", "unit": unit, "d1": d1, "d2": d2, "amp": amp, "dead": dead, "total": total, "chaos": false, "tier": tier,
		"odd": total % 2 == 1})
	if total % 2 == 1:
		b.shuffle_positions(foes, unit)
	elif not pool.is_empty():
		var dc2: Dictionary = pool[b.rng.randi() % pool.size()]
		debuff = str(dc2.get("status_id", ""))
		for f0: BUnit in foes:
			if f0.alive:
				fx.apply_status(unit, f0, dc2, od)
	var kind: String = "magic" if tier == "low" else ("physical" if tier == "mid" else "true")
	var ok: Dictionary = od.duplicate(true)
	if tier != "low":
		(ok["cfg"] as Dictionary)["damage_category"] = "normal_attack"      # 视为普攻伤害(吃普攻增伤；不是普攻，不发普攻事件)
	for f1: BUnit in foes:
		if f1.alive:
			fx.damage(unit, f1, base * float(tiers.get(tier, 1.0)), kind, ok)


## 自久远的过去而来：结束石化，获得 当前时间(开打后的秒数) × y 的法术强度和攻击力
func _petrify_wake(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	if unit.get_status("petrified") == null:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var byst: Dictionary = cfg.get("per_sec_by_star", {})
	var per: float = float(byst.get(str(mini(unit.star, 3)), cfg.get("per_sec", 4.0)))
	var secs: float = maxf(0.0, b.time - GC.START_DELAY)
	fx.end_status(unit, "petrified")
	var gain: float = per * secs
	fx.apply_status(unit, unit, {"status_id": "ancient_awake", "duration": 0.0, "max_stacks": 1, "flags": ["buff", "no_dispel"],
		"stats": {"attack_power": {"flat": gain}, "ability_power": {"flat": gain}}}, o)
	unit.attack_cd = minf(unit.attack_cd, 0.3)
	b.fx({"t": "petrify_wake", "unit": unit, "gain": gain, "secs": secs})


## 乱数：每个目标各掷 1d20 → 造成 0.05 × 点数 × n × 触发数值的伤害；1~5 物理、6~15 魔法、16~20 真实。
## 自己这一队已阵亡的人数 ≥ 还活着的人数时必定掷出 20
func _dice_damage(unit: BUnit, t: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	if t == null or not t.alive:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var da: Array[int] = b.team_dead_alive(unit.team)
	var roll: int = 20 if da[0] >= da[1] else b.rng.randi_range(1, 20)
	var kind: String = "physical" if roll <= 5 else ("magic" if roll <= 15 else "true")
	var dmg: float = 0.05 * float(roll) * float(cfg.get("n", 2.0)) * amount
	var od: Dictionary = o.duplicate()
	od["cfg"] = {"damage_category": "skill"}
	b.fx({"t": "d20", "unit": unit, "target": t, "roll": roll, "kind": kind})
	fx.damage(unit, t, dmg, kind, od)


# ---------------------------------------------------------------- 通用武器(召唤 / 充能)
## 自己(携带者)活着的召唤物(召唤者是自己的)
func own_summons(unit: BUnit) -> Array[BUnit]:
	var r: Array[BUnit] = []
	for u: BUnit in b.units:
		if u.alive and u != unit and u.summoner() == unit:
			r.append(u)
	return r


## 召唤物光环(牵丝提灯 / 殉魂幡)：不管触发目标是谁，给携带者所有活着的召唤物挂 cfg.status，并回复 触发数值 × cfg.heal_ratio 生命。
## 一次触发只结算一次(ctx.summon_aura_done)：多目标的插槽也不会重复挂
func _summon_aura(unit: BUnit, amount: float, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	if bool(ctx.get("summon_aura_done", false)):
		return
	ctx["summon_aura_done"] = true
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var hr: float = float(cfg.get("heal_ratio", 0.0))
	var hit: Array = []
	for sm: BUnit in own_summons(unit):
		if cfg.has("status"):
			fx.apply_status(unit, sm, (cfg["status"] as Dictionary).duplicate(true), o)
		if hr > 0.0 and amount > 0.0:
			fx.heal(unit, sm, amount * hr, {"surface": "equipment", "ability_id": ability.id})
		hit.append(sm)
	if not hit.is_empty():
		b.fx({"t": "summon_aura", "unit": unit, "targets": hit, "style": str(cfg.get("style", ""))})


## 回响刃：携带者(不管触发目标是谁)充能比例最低、没满的一个【充能】效果回复 cfg.count 层(被动和武器效果都算；武器自己的不算)
func _charge_refill(unit: BUnit, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	if bool(ctx.get("charge_refill_done", false)) or not unit.alive:
		return
	ctx["charge_refill_done"] = true
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var pick: Dictionary = {}
	for ce: Dictionary in charged_entries(unit):
		var ab: AbilityDef = ce["ability"]
		if ab == ability or int(ce["cur"]) >= int(ce["max"]):
			continue
		var ratio: float = float(ce["cur"]) / maxf(1.0, float(ce["max"]))
		if pick.is_empty() or ratio < float(pick["ratio"]):
			pick = {"ability": ab, "cur": int(ce["cur"]), "max": int(ce["max"]), "ratio": ratio}
	if pick.is_empty():
		return
	var ab2: AbilityDef = pick["ability"]
	var n: int = mini(int(pick["max"]), int(pick["cur"]) + maxi(1, int(cfg.get("count", 1))))
	unit.ability_charges[ab2.id] = n
	b.fx({"t": "charge_refill", "unit": unit, "ability": ab2.id, "charges": n})


## 蓄能法典：触发数值 × (cfg.base + cfg.per × 携带者所有【充能】效果当前剩余的层数之和) 的魔法伤害(武器自己的不算)；目标是友方时改为 触发数值 × (cfg.ally_base + cfg.ally_per × 层数) 的治疗
func _charge_scaled_damage(unit: BUnit, t: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	if t == null or not t.alive:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var n := 0
	for ce: Dictionary in charged_entries(unit):
		if ce["ability"] != ability:
			n += int(ce["cur"])
	var k: float = float(cfg.get("base", 0.4)) + float(cfg.get("per", 0.08)) * float(n)
	b.fx({"t": "charge_burst", "unit": unit, "target": t, "charges": n})
	if t.team == unit.team:
		k = float(cfg.get("ally_base", k)) + float(cfg.get("ally_per", 0.0)) * float(n)
		fx.heal(unit, t, amount * k, {"surface": "equipment", "ability_id": ability.id})
	else:
		fx.damage(unit, t, amount * k, "magic", o)


# ---------------------------------------------------------------- 变奏节点
## 表里之间：开战按她现在的形态挂上形态状态(恶魔：伤害增幅 / 天使：治疗量加成，cfg.forms[形态] = 状态配置)；先拿掉另一个形态的
func _pianist_form(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var forms: Dictionary = cfg.get("forms", {})
	for f: Variant in forms.keys():
		var sid: String = str((forms[f] as Dictionary).get("status_id", ""))
		if str(f) != unit.def.form and unit.statuses.has(sid):
			fx.end_status(unit, sid)
	if forms.has(unit.def.form):
		var sc: Dictionary = (forms[unit.def.form] as Dictionary).duplicate(true)
		sc["max_stacks"] = 1
		fx.apply_status(unit, unit, sc, o)


## 表里之间：阵亡时(濒死，每场一次)回满生命并切换为另一形态(部门、被动 2、形态加成跟着换；这一场的羁绊不重算)。算"本场阵亡过"
func _pianist_flip(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	if unit.hp > 0.0 or unit.def.forms.is_empty():
		return
	var nd: UnitDef = unit.def.form_def(unit.def.other_form())
	unit.def = nd
	unit.meta["has_died"] = true
	unit.hp = unit.get_stats().max_health
	unit.mark_dirty()
	unit.hp = unit.get_stats().max_health
	# 换形态状态
	for e: Dictionary in unit.all_ability_entries():
		var a: AbilityDef = e["ability"]
		if a.effect_type == "pianist_form":
			_pianist_form(unit, a, {"surface": "passive", "ability_id": a.id, "cfg": a.effect_config})
			break
	b.fx({"t": "pianist_flip", "unit": unit, "form": nd.form})


## 悲怆 / 热情：给目标加 cfg.add_stacks 层【沮丧】/【亢奋】(层数上限 = 这个能力的【叠加 N】)；
## 触发数值 = 每层每秒的持续伤害(value_to = dot)或持续治疗(value_to = hot，算她的治疗)
func _mood_stack(unit: BUnit, t: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	if t == null or not t.alive:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var sc: Dictionary = (cfg.get("status", {}) as Dictionary).duplicate(true)
	sc["max_stacks"] = maxi(1, kw_value(unit, ability, "stacking", int(sc.get("max_stacks", 9))))
	sc["add_stacks"] = maxi(1, int(cfg.get("add_stacks", 1)))
	match str(cfg.get("value_to", "")):
		"dot":
			(sc["dot"] as Dictionary)["amount"] = amount
		"hot":
			(sc["hot"] as Dictionary)["flat"] = amount
	fx.apply_status(unit, t, sc, o)


## 黑键 / 白键【永恒】【叠加 20】：触发目标是本场战斗没阵亡过的友军(自己也算)→ 先给它 每 cfg.n 点触发数值 1 层【渐强】(跨战斗保留，
## 层数上限 = 【叠加 N】)，再立刻击杀它(走正常的濒死 / 阵亡：她自己会被表里之间救回来、换形态)
func _black_keys(unit: BUnit, t: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	if t == null or not t.alive or t.team != unit.team or bool(t.meta.get("has_died", false)):
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var n: int = int(floor(amount / maxf(1.0, float(cfg.get("n", 150.0)))))
	b.fx({"t": "black_keys", "unit": unit, "target": t, "stacks": n, "white": unit.def.weapon_names.has(unit.weapon.id if unit.weapon != null else "")})
	if n > 0:
		var sc: Dictionary = (cfg.get("status", {}) as Dictionary).duplicate(true)
		sc["max_stacks"] = maxi(1, kw_value(unit, ability, "stacking", 20))
		sc["add_stacks"] = n
		sc["eternal"] = true
		fx.apply_status(unit, t, sc, o)
	t.hp = 0.0
	fx.try_kill(t, unit)


# ---------------------------------------------------------------- 锁芯节点
## 万物闭锁：智能选一个半径 cfg.radius 的圆(罩住最多敌人的位置，Targeting.densest_point)，cfg.impact 秒后锁上：
## 圆里所有敌人受到 amount 魔法(技能)伤害，活着的再【眩晕】stun_by_star 秒(血色仪式加时、精英 / 首领减半照通用规则)
func _lock_all(unit: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	if not unit.alive:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var rad: float = float(cfg.get("radius", 1.8))
	var pts: Array[Vector2] = []
	for e: BUnit in b.enemies_of(unit):
		if e.has_flag("untargetable") or bool(e.meta.get("dropping", false)) or b.ai.shadow_hidden(unit, e):
			continue
		pts.append(e.pos)
	if pts.is_empty():
		return
	var center: Vector2 = Targeting.densest_point(pts, rad, b.map)
	var sby: Dictionary = cfg.get("stun_by_star", {})
	var stun: float = float(sby.get(str(mini(unit.star, 3)), cfg.get("stun", 1.5)))
	var impact: float = float(cfg.get("impact", 0.35))
	b.fx({"t": "lock_cast", "unit": unit, "pos": center, "radius": rad, "impact": impact})
	var od: Dictionary = {"surface": "passive", "ability_id": ability.id, "cfg": {"damage_category": "skill"}}
	b.schedule(b.time + impact, _lock_impact.bind(unit, center, rad, amount, stun, od))


func _lock_impact(unit: BUnit, center: Vector2, rad: float, amount: float, stun: float, od: Dictionary) -> void:
	if not unit.alive or b.state == "ended":
		return
	var hits: Array[BUnit] = []
	for e: BUnit in b.enemies_of(unit):
		if not e.has_flag("untargetable") and not bool(e.meta.get("dropping", false)) and e.pos.distance_to(center) <= rad + e.radius:
			hits.append(e)
	b.fx({"t": "lock_close", "unit": unit, "pos": center, "radius": rad, "targets": hits})
	for t: BUnit in hits:
		if not t.alive:
			continue
		fx.damage(unit, t, amount, "magic", od)
		if t.alive and stun > 0.0:
			fx.apply_status(unit, t, {"status_id": "stun", "flags": ["debuff", "dispellable", "stun"], "max_stacks": 1, "duration": stun}, od)


## 开与闭：这一次发动的所有目标往同一个点(它们的中心，推出障碍物)大力拉拽、聚到一起(各停在离那个点 cfg.gap 米处，路上有墙就停在墙前)，
## 然后【眩晕】每 cfg.n 点触发数值 1 秒。中心按这一次的目标算一次(ctx.gather_pt)，每个目标各结算一次
func _gather_stun(unit: BUnit, t: BUnit, amount: float, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	if t == null or not t.alive:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	if not ctx.has("gather_pt"):
		var sum := Vector2.ZERO
		var cnt := 0
		var tg: Array = []
		for u0: Variant in ctx.get("targets", []):
			var uu: BUnit = u0 as BUnit
			if uu != null and uu.alive:
				sum += uu.pos
				cnt += 1
				tg.append(uu)
		var pt: Vector2 = sum / float(maxi(1, cnt)) if cnt > 0 else t.pos
		pt = b.map.push_out(b.clamp_to_arena(pt, 0.42), 0.42)
		ctx["gather_pt"] = pt
		b.fx({"t": "key_gate", "unit": unit, "pos": pt, "targets": tg})
	var gp: Vector2 = ctx["gather_pt"]
	var d: float = t.pos.distance_to(gp)
	var gap: float = float(cfg.get("gap", 0.55))
	if d > gap + 0.05:
		_knockback(unit, t, d - gap, {"cfg": {"max_dist": 30.0}, "dir": gp - t.pos, "style": "chain"})
	var dur: float = amount / maxf(1.0, float(cfg.get("n", 200.0)))
	if dur > 0.05:
		fx.apply_status(unit, t, {"status_id": "stun", "flags": ["debuff", "dispellable", "stun"], "max_stacks": 1, "duration": dur}, o)


# ---------------------------------------------------------------- 无我节点
## 逆时幻影：她每次普攻(不算追击副本 / 幻影自己那一下)——幻影还在：0.08 秒后幻影也普攻一次(以她的普攻计算事件和伤害：
## Pipeline.normal_attack(她, 目标, 副本)，目标 = 她这次的攻击目标(幻影够得着时)，否则幻影身边最近的敌人)；
## 幻影不在(还没召唤 / 被消灭了)：在这次的攻击目标附近召唤一个(cfg.unit_id，血量极低、不会动、自己不攻击)
func _phantom_strike(unit: BUnit, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	if not unit.alive:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var ev: Dictionary = ctx.get("ev", {})
	var tgt: BUnit = ((ev.get("meta", {}) as Dictionary).get("current_attack_target", ev.get("target"))) as BUnit
	var ph: BUnit = null
	for u0: BUnit in b.units:
		if u0.alive and u0.meta.get("phantom_of") == unit:
			ph = u0
	if ph == null:
		if tgt == null or not tgt.alive:
			return
		var away: Vector2 = tgt.pos - unit.pos
		away = away.normalized() if away.length() > 0.01 else Vector2(0, 1)
		var side: Vector2 = Vector2(-away.y, away.x) * (1.0 if b.rng.randf() < 0.5 else -1.0)
		var pdef: UnitDef = b.catalog.get_unit(str(cfg.get("unit_id", "killer_phantom")))
		if pdef == null:
			return
		var pos: Vector2 = b.find_free_position(tgt.pos + side * (tgt.radius + 0.7) + away * 0.3, pdef.radius, null)
		var nu: BUnit = b.spawn_unit(pdef, unit.team, unit.star, pos, true)
		nu.meta["summoner"] = unit
		nu.meta["summoners"] = [unit]
		nu.meta["phantom_of"] = unit
		var dv: Vector2 = tgt.pos - nu.pos
		if dv.length() > 0.01:
			nu.facing = atan2(dv.x, dv.y)
		b.fx({"t": "summon", "unit": nu, "summoner": unit, "kind": "phantom"})
		emit("OnSummonCompleted", unit, nu, 1.0, ["summon_completed"], {"summoned": nu})
		emit("OnSummoned", nu, unit, 1.0, ["summoned"], {"summoner": unit})
		return
	b.schedule(b.time + float(cfg.get("delay", 0.08)), _phantom_hit.bind(unit, ph, tgt, float(cfg.get("reach", 1.6))))


func _phantom_hit(unit: BUnit, ph: BUnit, tgt: BUnit, reach: float) -> void:
	if not unit.alive or not ph.alive or b.state == "ended" or not unit.can_attack():
		return
	var t: BUnit = tgt if tgt != null and tgt.alive and ph.pos.distance_to(tgt.pos) - tgt.radius <= reach else null
	if t == null:
		var bd: float = INF
		for e: BUnit in b.enemies_of(ph):
			var d: float = ph.pos.distance_to(e.pos) - e.radius
			if d <= reach and d < bd:
				bd = d
				t = e
	if t == null:
		return
	var dv: Vector2 = t.pos - ph.pos
	if dv.length() > 0.01:
		ph.facing = atan2(dv.x, dv.y)
	b.fx({"t": "phantom_strike", "unit": ph, "owner": unit, "target": t})
	normal_attack(unit, t, true, {"phantom": true})


## 无我(在战斗开始时)：这一场她身上带着 meta.selfless(Run 在备战时点了按钮、移除了一个仓库里的无我节点)——
## 所有普通敌人移除(不触发阵亡效果、不掉晶球)，精英 / 首领失去 y% 生命上限(Effects.wither，累计在【无我之痕】)；她拔刀
func _selfless_purge(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var byst: Dictionary = cfg.get("cut_by_star", {})
	var cut: float = float(byst.get(str(mini(unit.star, 3)), cfg.get("cut", 0.2)))
	var gone: Array = []
	var hurt: Array = []
	for e: BUnit in b.units.duplicate():
		if not e.alive or e.team == unit.team:
			continue
		if bool(e.meta.get("elite", false)) or bool(e.meta.get("boss", false)):
			hurt.append(e)
			fx.wither(unit, e, e.get_stats().max_health * cut, o, "selfless_scar")
		else:
			gone.append(e)
			e.meta.erase("orb")
			e.meta["selfless_cut"] = true            # 表现层：不倒地，定格后崩散
			e.meta["_doomed"] = true
			e.meta["no_death_fx"] = true
			e.hp = 0.0
			fx.try_kill(e, unit)
	b.fx({"t": "selfless_draw", "unit": unit, "removed": gone, "cut": hurt, "pct": cut})


# ---------------------------------------------------------------- 心连节点
## 量产型号【召唤】：召唤一个自身的复制(同一种单位、同星级 + 召唤星级加成)。复制品 meta.sister_copy = true(没有量产型号：触发器条件
## source_meta_missing)，装备 cfg.weapon(基础单手剑)；出现在自己身边、朝敌人那一侧
func _mass_production(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	if not unit.alive:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var star: int = mini(GC.MAX_SUMMON_STAR, unit.star + Effects.summon_star_bonus(unit))
	var toward: Vector2 = Vector2(0, 1) if unit.team == GC.TEAM_PLAYER else Vector2(0, -1)
	var foe: BUnit = null
	for e0: BUnit in b.enemies_of(unit):
		if foe == null or e0.pos.distance_to(unit.pos) < foe.pos.distance_to(unit.pos):
			foe = e0
	if foe != null and foe.pos.distance_to(unit.pos) > 0.1:
		toward = (foe.pos - unit.pos).normalized()
	var side: Vector2 = Vector2(-toward.y, toward.x) * (1.0 if b.rng.randf() < 0.5 else -1.0)
	var pos: Vector2 = b.find_free_position(unit.pos + toward * 0.9 + side * 0.9, unit.def.radius, unit)
	var nu: BUnit = b.spawn_unit(unit.def, unit.team, star, pos, true)
	nu.meta["summoner"] = unit
	nu.meta["summoners"] = [unit]
	nu.meta["sister_copy"] = true
	var wid: String = str(cfg.get("weapon", "basic_sword"))
	var we: EquipmentDef = b.catalog.get_equipment(wid)
	if we != null:
		nu.set_weapon(we)
	nu.mark_dirty()
	nu.recompute()
	nu.hp = nu.get_stats().max_health
	nu.facing = atan2(toward.x, toward.y)
	b.fx({"t": "summon", "unit": nu, "summoner": unit, "kind": "sister_copy"})
	emit("OnSummonCompleted", unit, nu, 1.0, ["summon_completed"], {"summoned": nu})
	emit("OnSummoned", nu, unit, 1.0, ["summoned"], {"summoner": unit})


# ---------------------------------------------------------------- 巧运节点
## 妙手：每次普攻命中，有 x% 的几率(cfg.chance_by_star；真骰取好)摸到 1 金币(Battle.grant_gold，战后入账)；摸到时发 OnGoldGain(meta.source = 这个能力)
func _pickpocket(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var byst: Dictionary = cfg.get("chance_by_star", {})
	var p: float = float(byst.get(str(mini(unit.star, 3)), cfg.get("chance", 0.05)))
	if b.roll_good(unit) >= p:
		return
	var n: int = int(cfg.get("amount", 1))
	b.grant_gold(unit.team, n, unit)
	b.fx({"t": "pickpocket", "unit": unit, "amount": n})
	emit("OnGoldGain", unit, unit, float(n), ["gold_gain"], {"source": ability.id, "amount": n})


## 匕首与金币【基本】【学习】【永恒】：携带者还没有【钱袋】就施加(从 0 枚开始)，否则金币计数 + 触发数值。
## 【钱袋】：不可叠加、不可驱散、无限持续；每 2 秒(pulse)按学习计数的收敛曲线翻倍 / 清空(bag_odds；一次掷骰，真骰取好)；
## 战斗结束时清空，获得等同计数的金币(倒下了也照样结算)。两件事都是钱袋自带的触发器(cfg.pairs)发起的
func _money_bag(unit: BUnit, t: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	var tgt: BUnit = t if t != null else unit
	var st: BStatus = tgt.get_status("money_bag")
	if st == null:
		var cfg: Dictionary = (o.get("cfg", ability.effect_config) as Dictionary)
		var scfg: Dictionary = (cfg.get("bag", {}) as Dictionary).duplicate(true)
		scfg["status_id"] = "money_bag"
		var meta: Dictionary = scfg.get("meta", {})
		meta["coins"] = 0
		meta["learn_ability"] = ability.id
		meta["learn_src"] = unit.uid
		scfg["meta"] = meta
		fx.apply_status(unit, tgt, scfg, o)
		b.fx({"t": "money_bag", "unit": tgt, "coins": 0, "change": "new"})
		return
	var add: int = maxi(0, int(round(amount)))
	st.meta["coins"] = int(st.meta.get("coins", 0)) + add
	b.fx({"t": "money_bag", "unit": tgt, "coins": int(st.meta["coins"]), "change": "add", "delta": add})


func _money_bag_tick(unit: BUnit, o: Dictionary) -> void:
	var st: BStatus = unit.get_status("money_bag")
	if st == null or int(st.meta.get("coins", 0)) <= 0:
		return
	var cfg: Dictionary = o.get("cfg", {})
	var src: BUnit = b.get_unit_by_uid(str(st.meta.get("learn_src", unit.uid)))
	var learn: int = int((src if src != null else unit).learning.get(str(st.meta.get("learn_ability", "")), 0))
	var odds: Vector2 = bag_odds(cfg, learn)
	var pd: float = odds.x
	var pc: float = odds.y
	# 一次掷骰：< pd 翻倍，< pd + pc 清空，否则不变；真骰掷两次取好的(翻倍 > 不变 > 清空)
	var rank := func(r: float) -> int: return 2 if r < pd else (0 if r < pd + pc else 1)
	var best: int = rank.call(b.rng.randf())
	if unit.has_flag("lucky"):
		best = maxi(best, int(rank.call(b.rng.randf())))
	if best == 2:
		st.meta["coins"] = int(st.meta["coins"]) * 2
		b.fx({"t": "money_bag", "unit": unit, "coins": int(st.meta["coins"]), "change": "double"})
	elif best == 0:
		var lost: int = int(st.meta["coins"])
		st.meta["coins"] = 0
		b.fx({"t": "money_bag", "unit": unit, "coins": 0, "change": "clear", "delta": lost})


## 钱袋的 (翻倍, 清空) 概率：学习计数 L 越多越好，但收敛到固定值(用户 2026-10-08：不再线性)——
## f = L / (L + learn_half)(0 → 1，学习 learn_half 次时走到一半)；翻倍 double_base → double_max、清空 clear_base → clear_min 按 f 插值
static func bag_odds(cfg: Dictionary, learn: int) -> Vector2:
	var k: float = maxf(0.001, float(cfg.get("learn_half", 10.0)))
	var f: float = float(maxi(0, learn)) / (float(maxi(0, learn)) + k)
	var pd: float = lerpf(float(cfg.get("double_base", 5.0)), float(cfg.get("double_max", 25.0)), f)
	var pc: float = lerpf(float(cfg.get("clear_base", 25.0)), float(cfg.get("clear_min", 5.0)), f)
	return Vector2(maxf(0.0, pd) / 100.0, maxf(0.0, pc) / 100.0)


func _money_bag_cashout(unit: BUnit) -> void:
	var st: BStatus = unit.get_status("money_bag")
	if st == null:
		return
	var n: int = int(st.meta.get("coins", 0))
	fx.end_status(unit, st.id)
	if n > 0:
		b.grant_gold(unit.team, n, unit)
	b.fx({"t": "money_bag", "unit": unit, "coins": 0, "change": "cash", "delta": n})


# ---------------------------------------------------------------- 圣战节点
## 裂地猛击：智能地朝锥形(cfg.angle 度、cfg.length 米)里压到最多敌人的方向砸地(Targeting.best_cone_aim)。
## 到点时锥形够得着的地方没有敌人 → 蓄着(meta.slam_pending)，有敌人进来立刻砸(另一个每帧触发器)；砸了就把 5 秒的计时(cfg.timer 触发器)归零。
## 出手时定下方向、停下来(cfg.lock 秒定身、不普攻；手上这一招不打了)，cfg.impact 秒后(动作砸到地上的那一刻)结算：
## 锥形里的所有敌人受到 触发数值 的魔法伤害(x × (100 + 法强)%)，锥形里的地形打碎(Battle.break_terrain_in_cone)；
## 结算完发一次 OnSkillHit(meta.skill = 这个能力，meta.targets = 受到伤害的敌人)：神圣战争
func _quake_slam(unit: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var cone: Dictionary = {"angle": float(cfg.get("angle", 100.0)), "length": float(cfg.get("length", 3.5))}
	if not unit.alive:
		return
	var aim: Dictionary = Targeting.best_cone_aim(b, unit, cone)
	if aim.is_empty():
		unit.meta["slam_pending"] = true
		return
	unit.meta.erase("slam_pending")
	if str(cfg.get("timer", "")) != "":
		unit.counters[str(cfg["timer"])] = 0
	var dir: Vector2 = aim["dir"]
	var impact: float = float(cfg.get("impact", 0.3))
	var lock: float = float(cfg.get("lock", 0.8))
	unit.facing = atan2(dir.x, dir.y)
	unit.vel = Vector2.ZERO
	if unit.phase in ["windup", "recover"]:
		unit.phase = "idle"                           # 手上这一招不打了
	unit.attack_cd = maxf(unit.attack_cd, lock)
	fx.apply_status(unit, unit, {"status_id": "quake_stance", "duration": lock, "max_stacks": 1, "flags": ["buff", "no_dispel", "rooted", "hidden"]}, o)
	b.fx({"t": "quake_windup", "unit": unit, "dir": dir, "impact": impact, "weapon_class": unit.weapon_class(),
		"angle": float(cone["angle"]), "length": float(cone["length"])})
	var od: Dictionary = {"surface": "passive", "ability_id": ability.id, "cfg": {"damage_category": "skill"}}
	b.schedule(b.time + impact, _quake_impact.bind(unit, dir, cone, amount, od))


func _quake_impact(unit: BUnit, dir: Vector2, cone: Dictionary, amount: float, od: Dictionary) -> void:
	if not unit.alive or b.state == "ended":
		return
	var hits: Array[BUnit] = Targeting.cone_targets(b, unit, dir, cone)
	var broke: int = b.break_terrain_in_cone(unit.pos, dir, cone, unit)
	b.fx({"t": "quake_slam", "unit": unit, "dir": dir, "angle": float(cone["angle"]), "length": float(cone["length"]), "targets": hits, "broke": broke})
	var damaged: Array = []
	for t: BUnit in hits:
		if not t.alive:
			continue
		if fx.damage(unit, t, amount, "magic", od) > 0.0:
			damaged.append(t)
	if not damaged.is_empty() and unit.alive:
		emit("OnSkillHit", unit, damaged[0] as BUnit, amount, ["skill_hit"], {"skill": str(od.get("ability_id", "")), "targets": damaged})


## 麻痹(电磁学导论)：不可叠加、可驱散、负面；数值 p = 每 n 点触发数值 (1 + 学习计数)%(学习计数 = 这次发动之前的)：
## 承受的伤害的增幅 +p(和攻击者的伤害增幅同一个乘区)，普攻前摇完成时有 p 的几率被打断(BattleAI._release)。重复施加取较高的数值，持续时间刷新
func _paralyze(unit: BUnit, t: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	if t == null or not t.alive:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var learn: int = int(unit.learning.get(ability.id, 0))
	var p: float = float(1 + learn) * amount / maxf(1.0, float(cfg.get("n", 20.0))) / 100.0
	var old: BStatus = t.get_status("paralysis")
	if old != null:
		p = maxf(p, float(old.meta.get("paralyze", 0.0)))
	p = minf(p, 1.0)
	var st: BStatus = fx.apply_status(unit, t, {"status_id": "paralysis", "duration": float(cfg.get("duration", 8.0)), "max_stacks": 1,
		"flags": ["debuff", "dispellable", "paralysis"], "stats": {"damage_taken_amp": {"flat": p}}, "meta": {"paralyze": p}}, o)
	if st != null:
		b.fx({"t": "paralyze", "unit": unit, "target": t, "p": p})


## 翠绿之林【学习】：每 n1 点触发数值 (4 − 学习计数)% 攻击速度(永久累加，不低于 0)，每 n2 点触发数值 (0 + 学习计数)% 最大生命的回复
## (学习计数 = 这次发动之前的；发动完 Pipeline.execute 再 +1；触发数值本身不随学习计数变大：learning.bonus_per_learning = 0)
func _verdant_grove(unit: BUnit, t: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	if t == null or not t.alive:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var learn: int = int(unit.learning.get(ability.id, 0))
	var as_pct: float = maxf(0.0, float(int(cfg.get("as_base", 4)) - learn)) * amount / maxf(1.0, float(cfg.get("n1", 40.0))) / 100.0
	var heal_pct: float = float(learn) * amount / maxf(1.0, float(cfg.get("n2", 30.0))) / 100.0
	if as_pct > 0.0:
		fx.apply_status(unit, t, {"status_id": "verdant_haste", "duration": 0.0, "max_stacks": 1, "flags": ["buff", "dispellable"], "accumulate": true,
			"stats": {"attack_speed_multiplier": {"pct": as_pct}}}, o)
	if heal_pct > 0.0:
		fx.heal(unit, t, t.get_stats().max_health * heal_pct, o)
	b.fx({"t": "verdant_grove", "unit": unit, "target": t, "as": as_pct, "heal": heal_pct, "learn": learn})


# ---------------------------------------------------------------- 白羽节点
## 致向死的渴望：普攻改打的那个队友——射程里(× 1.45 的容差，和打空判定一样)生命比例低于 below 的队友里生命比例最低的；没有 = null
func angel_ally(u: BUnit) -> BUnit:
	var ac: Variant = status_meta(u, "angel_alt")
	if ac == null:
		return null
	var below: float = float((ac as Dictionary).get("below", 0.97))
	var reach: float = u.get_stats().range_meters() * 1.45
	var best: BUnit = null
	for a: BUnit in b.units:
		if not a.alive or a == u or a.team != u.team or a.has_flag("untargetable") or bool(a.meta.get("dropping", false)):
			continue
		if a.hp_ratio() >= below or u.pos.distance_to(a.pos) > reach + a.radius:
			continue
		if best == null or a.hp_ratio() < best.hp_ratio():
			best = a
	return best


## 送葬：给普攻打中的目标(敌我都算)叠一层；叠到【叠加 z】层时结算(_funeral_end)
func _funeral_mark(unit: BUnit, t: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	if t == null or not t.alive:
		return
	var cfg: Dictionary = ((o.get("cfg", ability.effect_config) as Dictionary).get("status", {}) as Dictionary).duplicate(true)
	var z: int = maxi(1, kw_value(unit, ability, "stacking", 1))
	cfg["max_stacks"] = z
	var st: BStatus = fx.apply_status(unit, t, cfg, o)
	if st != null and st.stacks >= z:
		_funeral_end(unit, t, ability, o)


## 送葬满层：普通怪物和棋子(node_ 开头的单位，包括召唤物)立刻死亡、不触发阵亡效果；
## 否则(精英 / 首领)失去 x% 生命上限(按施加者星级，状态【送葬之痕】累计)，送葬全部消耗
func _funeral_end(unit: BUnit, t: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var sid: String = str(((o.get("cfg", ability.effect_config) as Dictionary).get("status", {}) as Dictionary).get("status_id", "funeral"))
	fx.end_status(t, sid)
	if t.def.id.begins_with("node_") or t.is_common_monster():
		t.meta["_doomed"] = true
		t.meta["no_death_fx"] = true
		b.fx({"t": "funeral", "unit": unit, "target": t, "pos": t.pos, "kill": true})
		fx._hp_loss(unit, t, t.hp, o)
		return
	var by: Dictionary = (o.get("cfg", ability.effect_config) as Dictionary).get("loss_by_star", {})
	var x: float = float(by.get(str(mini(unit.star, 3)), 0.1))
	b.fx({"t": "funeral", "unit": unit, "target": t, "pos": t.pos, "kill": false})
	fx.wither(unit, t, t.get_stats().max_health * x, o, "funeral_scar")


## 致求生的意志(2 星)：持有送葬的队友(含自己)承受致命伤害时不阵亡(留 1 点生命)，这一下伤害每有 y 点再叠一层送葬；
## 叠到满层就照送葬的规则立刻死亡(不触发阵亡效果)——这时不救，让它就这样倒下
func _funeral_save(unit: BUnit, t: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	if t == null or t.hp > 0.0:
		return
	var song: AbilityDef = unit.def.passive_by_id(str((o.get("cfg", ability.effect_config) as Dictionary).get("mark_passive", "")))
	if song == null:
		return
	var scfg: Dictionary = (song.effect_config.get("status", {}) as Dictionary).duplicate(true)
	var sid: String = str(scfg.get("status_id", "funeral"))
	var st: BStatus = t.get_status(sid)
	if st == null or st.stacks <= 0:
		return
	var z: int = maxi(1, kw_value(unit, song, "stacking", 1))
	var by: Dictionary = (o.get("cfg", ability.effect_config) as Dictionary).get("per_by_star", {})
	var per: float = maxf(1.0, float(by.get(str(mini(unit.star, 3)), 100.0)))
	var extra: int = int(floor(float(t.meta.get("last_hit", 0.0)) / per))
	if st.stacks + extra >= z and (t.def.id.begins_with("node_") or t.is_common_monster()):
		fx.end_status(t, sid)
		t.meta["no_death_fx"] = true                # 叠满了：照送葬的规则就此倒下(外面的阵亡流程继续)，不触发阵亡效果
		b.fx({"t": "funeral", "unit": unit, "target": t, "pos": t.pos, "kill": true})
		return
	t.hp = 1.0
	if extra > 0:
		scfg["max_stacks"] = z
		scfg["add_stacks"] = mini(extra, z - 1 - st.stacks) if not (t.def.id.begins_with("node_") or t.is_common_monster()) else extra
		if int(scfg["add_stacks"]) > 0:
			fx.apply_status(unit, t, scfg, o)
	b.fx({"t": "funeral_save", "unit": unit, "target": t, "stacks": t.status_stacks(sid), "of": z})


# ---------------------------------------------------------------- 共歌节点
## 美妙地：这一次普攻 = 给场上所有其他人(不分敌我)各叠一层沉醉(层数上限 = 这个被动的【叠加 N】；【永恒】= 跨战斗保留)
func _intox_song(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = ((o.get("cfg", ability.effect_config) as Dictionary).get("status", {}) as Dictionary).duplicate(true)
	cfg["max_stacks"] = maxi(1, kw_value(unit, ability, "stacking", 1))
	cfg["eternal"] = ability.has_keyword("eternal")
	var got: Array = []
	for u: BUnit in b.units.duplicate():
		if not u.alive or u == unit or bool(u.meta.get("dropping", false)) or u.has_flag("untargetable"):
			continue
		if fx.apply_status(unit, u, cfg, o) != null:
			got.append(u)
	b.fx({"t": "intox_song", "unit": unit, "targets": got})


# ---------------------------------------------------------------- 执剑节点
## 勇者，圣剑：对目标发动——普通怪物(BUnit.is_common_monster)直接击杀(不经过濒死响应)；否则造成 amount(= x × (100 + 法强)%)× 目标最大生命 的真实伤害
func _holy_sword(unit: BUnit, t: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	if t == null or not t.alive:
		return
	var hcfg: Dictionary = o.get("cfg", ability.effect_config)
	var slay: bool = t.is_common_monster() and bool(hcfg.get("slay_common", true))
	# (可选规则：slay_first_only = 只有开战那一下直接击杀；slay_below = 目标生命比例不高于这个值才直接击杀)
	if slay and bool(hcfg.get("slay_first_only", false)) and bool(unit.meta.get("holy_struck", false)):
		slay = false
	if slay and hcfg.has("slay_below") and t.hp_ratio() > float(hcfg["slay_below"]) + 0.0001:
		slay = false
	unit.meta["holy_struck"] = true
	if slay:
		t.meta["_doomed"] = true
		b.fx({"t": "holy_sword", "unit": unit, "target": t, "pos": t.pos, "kill": true})
		fx._hp_loss(unit, t, t.hp, o)
		return
	b.fx({"t": "holy_sword", "unit": unit, "target": t, "pos": t.pos, "kill": false})
	fx.damage(unit, t, t.get_stats().max_health * maxf(0.0, amount), "true", o)


## 梦想，未来(阵亡时)：把她身上所有属性提升类的状态(不是负面、不是隐藏的，按当时的层数与阈值)加在一起，
## 做成一个持续时间无限的【未来】施加给全体活着的队友(cfg.legacy；accumulate：她被复活后再阵亡，会再叠一次)
func _brave_legacy(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var flat := {}
	var pct := {}
	for st: BStatus in unit.statuses.values():
		if st.stacks <= 0 or st.has_flag("debuff") or st.has_flag("hidden"):
			continue
		if st.meta.has("off_with") and unit.status_stacks(str(st.meta["off_with"])) > 0:
			continue
		for k: String in st.flat_per_stack.keys():
			flat[k] = float(flat.get(k, 0.0)) + st.total_flat(k)
		for k2: String in st.pct_per_stack.keys():
			pct[k2] = float(pct.get(k2, 0.0)) + st.total_pct(k2)
		var sat: Dictionary = st.meta.get("stats_at", {})
		for th: Variant in sat.keys():
			if st.stacks < int(th):
				continue
			for k3: Variant in (sat[th] as Dictionary).keys():
				var e3: Dictionary = sat[th][k3]
				if e3.has("flat"):
					flat[str(k3)] = float(flat.get(str(k3), 0.0)) + float(e3["flat"])
				if e3.has("pct"):
					pct[str(k3)] = float(pct.get(str(k3), 0.0)) + float(e3["pct"])
	var stats := {}
	for k4: String in flat.keys():
		if absf(float(flat[k4])) > 0.00001:
			stats[k4] = {"flat": float(flat[k4])}
	for k5: String in pct.keys():
		if absf(float(pct[k5])) > 0.00001:
			var e5: Dictionary = stats.get(k5, {})
			e5["pct"] = float(pct[k5])
			stats[k5] = e5
	if stats.is_empty():
		return
	var cfg: Dictionary = ((o.get("cfg", ability.effect_config) as Dictionary).get("legacy", {}) as Dictionary).duplicate(true)
	cfg["stats"] = stats
	cfg["accumulate"] = true
	var got: Array = []
	for a: BUnit in b.units:
		if not a.alive or a == unit or a.team != unit.team or bool(a.meta.get("dropping", false)):
			continue
		if fx.apply_status(unit, a, cfg, o) != null:
			got.append(a)
	if not got.is_empty():
		b.fx({"t": "brave_legacy", "unit": unit, "targets": got, "stats": stats})


# ---------------------------------------------------------------- 正行节点
## 从 who 身上拿走某个[叠加]状态的 n 层(拿到 0 层就移除)；返回实际拿走的层数
func _take_stacks(who: BUnit, sid: String, n: int, src: BUnit) -> int:
	var st: BStatus = who.get_status(sid)
	if st == null or n <= 0:
		return 0
	var took: int = mini(n, st.stacks)
	st.stacks -= took
	if st.stacks <= 0:
		fx.end_status(who, sid)
	else:
		who.mark_dirty()
		b.fx({"t": "status", "unit": who, "id": sid, "base_id": sid, "stacks": st.stacks, "created": false, "flags": st.flags, "src": src})
	return took


## 再绽之花吟唱完(没被打断)：把还没走完的"每秒"补齐(第 3 秒那一下常常和吟唱结束落在同一刻)
func _lily_rebloom(unit: BUnit, ability: AbilityDef, ctx: Dictionary) -> void:
	_lily_advance(unit, ability, float(ctx.get("chanted", unit.phase_dur)))


## 再绽之花吟唱中的每个战斗帧：按已经吟唱的秒数，每满 1 秒消耗 per_tick 层花瓣、获得 1 层花蕊
func _lily_tick(unit: BUnit, ability: AbilityDef) -> void:
	var pa: AbilityDef = unit.def.passive_by_id(str(ability.effect_config.get("rebloom", "")))
	if pa == null or unit.phase != "chant" or unit.chant_ability != pa:
		return
	_lily_advance(unit, pa, clampf(unit.phase_dur - (unit.chant_until - b.time), 0.0, unit.phase_dur))


## pa = 再绽之花(带【吟唱 N】【叠加 M】)。同一次吟唱用 chant_until 认(被打断后重新吟唱是新的一轮)
func _lily_advance(unit: BUnit, pa: AbilityDef, chanted: float) -> void:
	var cfg: Dictionary = pa.effect_config
	var bl: Dictionary = unit.meta.get("bloom", {})
	if not is_equal_approx(float(bl.get("key", -1.0)), unit.chant_until):
		bl = {"key": unit.chant_until, "ticks": 0}
	var n: int = maxi(1, kw_value(unit, pa, "chant", 1))
	var due: int = mini(n, int(floor(chanted + 0.01)))
	var petal: String = str(cfg.get("petal_status", "lily_petal"))
	while int(bl["ticks"]) < due:
		bl["ticks"] = int(bl["ticks"]) + 1
		var took: int = _take_stacks(unit, petal, int(cfg.get("per_tick", 4)), unit)
		var scfg: Dictionary = (cfg.get("stamen", {}) as Dictionary).duplicate(true)
		scfg["max_stacks"] = maxi(1, kw_value(unit, pa, "stacking", 1))
		fx.apply_status(unit, unit, scfg, {"surface": "passive", "ability_id": pa.id})
		var total: int = int(unit.meta.get("lily_consumed", 0)) + took
		unit.meta["lily_consumed"] = total
		b.fx({"t": "lily_tick", "unit": unit, "took": took, "tick": int(bl["ticks"]), "of": n})
		# 累计消耗满 bloom_after 层：获得【花】(满层的花瓣加成，之后一直有)
		if total >= int(cfg.get("bloom_after", 12)) and unit.status_stacks(str(cfg.get("bloom_status", "lily_bloom"))) <= 0:
			_lily_full_bloom(unit, pa)
	unit.meta["bloom"] = bl


## 【花】：把花瓣满层时的全部加成(每层的治疗量加成 × 叠加上限 + 所有层数阈值的加成)做成一个不可驱散、无限持续的状态；
## 花瓣状态带 off_with = 花，有花之后花瓣自己的加成不再另算(BUnit.recompute)
func _lily_full_bloom(unit: BUnit, pa: AbilityDef) -> void:
	var cfg: Dictionary = pa.effect_config
	var lp: AbilityDef = unit.def.passive_by_id(str(cfg.get("petal_passive", "")))
	if lp == null:
		return
	var pc: Dictionary = lp.effect_config
	var cap: int = maxi(1, kw_value(unit, lp, "stacking", 1))
	var sk: int = mini(unit.star, 3)
	var stats := {}
	for k: Variant in (pc.get("stats_by_star", {}) as Dictionary).keys():
		var e: Dictionary = pc["stats_by_star"][k]
		for mode: Variant in e.keys():
			var bs: Dictionary = e[mode]
			var o0: Dictionary = stats.get(str(k), {})
			o0[str(mode)] = float(o0.get(str(mode), 0.0)) + float(bs.get(str(sk), bs.get(sk, 0.0))) * float(cap)
			stats[str(k)] = o0
	var sat: Dictionary = Effects.stats_at_of(pc, unit.star)
	for th: Variant in sat.keys():
		if int(th) > cap:
			continue
		for k2: Variant in (sat[th] as Dictionary).keys():
			var e2: Dictionary = sat[th][k2]
			var o2: Dictionary = stats.get(str(k2), {})
			for mode2: Variant in e2.keys():
				o2[str(mode2)] = float(o2.get(str(mode2), 0.0)) + float(e2[mode2])
			stats[str(k2)] = o2
	fx.apply_status(unit, unit, {"status_id": str(cfg.get("bloom_status", "lily_bloom")), "max_stacks": 1, "duration": 0.0,
		"flags": ["buff", "no_dispel"], "stats": stats}, {"surface": "passive", "ability_id": pa.id})
	b.fx({"t": "lily_full_bloom", "unit": unit})


## 花蕊的光刃 / 光炮打完(普攻命中，事件数值 = 这一下对所有目标造成的伤害)：消耗 1 层花蕊，再把等量的治疗智能分配给全场受伤的友军
func _lily_cone_heal(unit: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	_take_stacks(unit, str(cfg.get("status_id", "lily_stamen")), 1, unit)
	smart_heal(unit, amount, ability)


## 智能分配治疗(注水)：受伤的友军(含自己、召唤物)里生命比例最低的先抬，几个人一起往上抬到同一个比例，治疗量用完或者都满了为止——
## 不会有溢出的治疗。total = 原始治疗量(不再吃治疗量加成，只吃对方的受治疗加成)
func smart_heal(unit: BUnit, total: float, ability: AbilityDef) -> void:
	if total <= 0.5:
		return
	var hurt: Array[BUnit] = []
	for a: BUnit in b.units:
		if not a.alive or a.team != unit.team or a.has_flag("no_heal") or a.has_flag("untargetable") or bool(a.meta.get("dropping", false)):
			continue
		if a.hp < a.get_stats().max_health - 0.5:
			hurt.append(a)
	if hurt.is_empty():
		return
	var lvl := 1.0
	if _fill_need(hurt, 1.0) > total:
		var lo := 0.0
		var hi := 1.0
		for _i in range(32):
			var mid: float = (lo + hi) * 0.5
			if _fill_need(hurt, mid) > total:
				hi = mid
			else:
				lo = mid
		lvl = lo
	var got: Array = []
	for h2: BUnit in hurt:
		var amt: float = maxf(0.0, lvl * h2.get_stats().max_health - h2.hp)
		if amt > 0.5:
			got.append(h2)
			fx.heal(unit, h2, amt, {"surface": "passive", "raw": true, "ability_id": ability.id})
	if not got.is_empty():
		b.fx({"t": "lily_heal", "unit": unit, "targets": got, "amount": total})


## 注水需要的治疗量：把 hurt 里每个人都抬到 level 比例的生命
static func _fill_need(hurt: Array[BUnit], level: float) -> float:
	var s0 := 0.0
	for h: BUnit in hurt:
		s0 += maxf(0.0, level * h.get_stats().max_health - h.hp)
	return s0


# ---------------------------------------------------------------- 血嗜节点
## 武器(装备载荷)至少有一个效果，而且都不在冷却 / 有充能
func payload_ready(unit: BUnit) -> bool:
	var any := false
	for e: Dictionary in unit.all_ability_entries():
		if str(e["surface"]) != "equipment":
			continue
		var ab: AbilityDef = e["ability"]
		if not ab.required_trigger_tags.has("equipment_payload"):
			continue
		any = true
		var maxc: int = _max_charges(ab, unit)
		if maxc > 0:
			_recharge(unit, ab, maxc)
			if int(unit.ability_charges.get(ab.id, maxc)) <= 0:
				return false
		elif ab.cooldown > 0.0 and float(unit.ability_cd.get(ab.id, -1.0)) > b.time + CD_EPS:
			return false
	return any


## 血欲 → 失血：造成 / 承受非持续伤害时，身上每有一层血欲，就给对方叠一层失血(上限 = 被动 1 的【叠加 N】)，持续 duration 秒；
## 失血每 0.25 秒每层 x 点物理持续伤害，血嗜节点回复最终伤害量(状态 meta.drain，Battle._update_statuses)
func _bleed(unit: BUnit, t: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	if t == null or not t.alive or t.team == unit.team:
		return
	var n: int = unit.status_stacks("bloodlust")
	if n <= 0:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var cap := 12
	for pa: AbilityDef in unit.def.passives:
		if pa.id == str(cfg.get("stack_from", "")):
			cap = maxi(1, kw_value(unit, pa, "stacking", 12))
	var x: float = float((cfg.get("x_by_star", {}) as Dictionary).get(str(mini(unit.star, 3)), 2.0))
	fx.apply_status(unit, t, {"status_id": "bleed", "duration": float(cfg.get("duration", 10.0)), "max_stacks": cap, "add_stacks": n,
		"flags": ["debuff", "dispellable", "bleed"], "dot": {"kind": "physical", "amount": x, "interval": 0.25}, "meta": {"drain": true}})


## 血宴：在场时全场每造成 per 点持续伤害，就获得一层(上限【叠加 N】)；从他上场(开战)时开始算
func _blood_feast(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var per: float = maxf(1.0, float(cfg.get("per", 150.0)))
	if not unit.meta.has("feast_base"):
		unit.meta["feast_base"] = b.dot_dealt
	var n: int = int(floor((b.dot_dealt - float(unit.meta["feast_base"])) / per + 0.0001))
	if n <= 0:
		return
	unit.meta["feast_base"] = float(unit.meta["feast_base"]) + float(n) * per
	var cap: int = maxi(1, kw_value(unit, ability, "stacking", 12))
	var have: int = unit.status_stacks("blood_feast")
	n = mini(n, cap - have)
	if n <= 0:
		return
	var sc: Dictionary = (cfg.get("status", {}) as Dictionary).duplicate(true)
	sc["add_stacks"] = n
	sc["max_stacks"] = cap
	fx.apply_status(unit, unit, sc, o)
	b.fx({"t": "blood_feast", "unit": unit, "stacks": unit.status_stacks("blood_feast")})


## 也是我等的至亲的故事：消耗 count 层血欲；告诉表现层这次武器效果有没有吟唱 / 群攻(决定血球的演法)
func _kin_consume(unit: BUnit, t: BUnit, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var st: BStatus = unit.get_status("bloodlust")
	if st == null:
		return
	st.stacks -= mini(st.stacks, int(cfg.get("count", 12)))
	if st.stacks <= 0:
		fx.end_status(unit, "bloodlust")
	else:
		unit.mark_dirty()
		b.fx({"t": "status", "unit": unit, "id": "bloodlust", "base_id": "bloodlust", "stacks": st.stacks, "created": false, "flags": st.flags, "src": unit})
	var chant := false
	var multi := false
	for e: Dictionary in unit.all_ability_entries():
		if str(e["surface"]) == "equipment" and (e["ability"] as AbilityDef).required_trigger_tags.has("equipment_payload"):
			chant = chant or (e["ability"] as AbilityDef).has_keyword("chant")
			multi = multi or (e["ability"] as AbilityDef).has_keyword("multi_attack")
	var tg: Array = []
	for u2: BUnit in ctx.get("targets", []):
		tg.append(u2)
	var trg: TriggerDef = ctx.get("trig") as TriggerDef
	var rad: float = trg.target_radius if trg != null and trg.target_radius > 0.0 else 5.0
	b.fx({"t": "kin_tale", "unit": unit, "target": t, "targets": tg, "chant": chant, "multi": multi, "center": t.pos if t != null else unit.pos, "radius": rad})


## 凝血的崩裂之血：吟唱了几秒就打几下(至少 1 下)，每下 = 触发数值 × n%(能力倍率)的法术伤害(技能伤害)，每下给目标叠一层崩裂(上限【叠加 N】)
func _blood_rupture(unit: BUnit, t: BUnit, amount: float, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	if t == null or not t.alive:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var hits: int = maxi(1, int(floor(float(ctx.get("chanted", 1.0)) + 0.001)))
	var cap: int = maxi(1, kw_value(unit, ability, "stacking", 6))
	for i in range(hits):
		if not t.alive:
			return
		var od: Dictionary = o.duplicate()
		od["can_crit"] = false
		fx.damage(unit, t, amount, "magic", od)
		if t.alive:
			var cc: Dictionary = (cfg.get("crack", {}) as Dictionary).duplicate(true)
			cc["max_stacks"] = cap
			cc["add_stacks"] = 1
			fx.apply_status(unit, t, cc, o)


# ---------------------------------------------------------------- 调香节点：旧香炉的浸染
## 浸染：每 per 点数值叠一层(最多【叠加 N】层)，持续 duration 秒；受到普攻时消耗一层(状态附带的触发器 → infusion_pop)
# ---------------------------------------------------------------- 颜色羁绊
## 沧澜(青色羁绊 4 档)：自己身上每个已经有层数、还没满的可叠加增益状态各 +1 层(弹匣 / 隐藏状态 / 排除列表里的不算)
func _bump_buff_stacks(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var ex: Array = cfg.get("exclude", [])
	var n := 0
	for st: BStatus in unit.statuses.values():
		if st.stacks <= 0 or st.max_stacks <= 1 or st.stacks >= st.max_stacks or not st.has_flag("buff") or st.has_flag("hidden"):
			continue
		if ex.has(str(st.meta.get("base_id", st.id))) or ex.has(st.id) or st.meta.has("ammo_cap") or st.id == "ammo":
			continue
		st.stacks += 1
		n += 1
		b.fx({"t": "status", "unit": unit, "id": st.id, "stacks": st.stacks, "created": false, "flags": []})
	if n > 0:
		unit.mark_dirty()
		b.fx({"t": "tide_surge", "unit": unit, "count": n})


# ---------------------------------------------------------------- 踏影节点
## 逆光：瞬移到那个远程敌人背后(没有中间过程；表现是沉进影子、再从影子里出来)，索敌它，获得 1 层【凝暗】(上限 = 【叠加 N】)；然后发 OnBlink(淬血)
func _shadow_step(unit: BUnit, t: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	if t == null or not t.alive or t.team == unit.team or unit.phase == "dash":
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var spot: Vector2 = b.map.push_out(behind_pos(t, unit.radius), unit.radius)
	var from: Vector2 = unit.pos
	b.interrupt(unit)
	unit.pos = spot
	unit.prev_pos = spot
	unit.vel = Vector2.ZERO
	unit.facing = atan2(t.pos.x - spot.x, t.pos.y - spot.y)
	unit.prev_facing = unit.facing
	unit.target = t
	unit.attack_target = t
	unit.engaged = false
	unit.last_target_check = b.time
	unit.meta["backlit"] = true                        # 索敌改为先找远程敌人(BattleAI nearest_melee_first)
	var vcfg: Dictionary = (cfg.get("veil", {}) as Dictionary).duplicate(true)
	if not vcfg.is_empty():
		vcfg["max_stacks"] = maxi(1, kw_value(unit, ability, "stacking", 3))
		fx.apply_status(unit, unit, vcfg)
	b.fx({"t": "shadow_step", "unit": unit, "from": from, "to": spot, "target": t})
	emit("OnBlink", unit, unit, 0.0, ["blink"], {"target": t})


## 淬血的代价：对自己造成 z × 攻击力 × (100 + 法强)% 的真实持续伤害(没有施加者：不吃自己的增幅；不会把自己打死，我定的)，
## 记下这次流失的生命值(护盾挡掉的不算)给触发数值用(self_cost_lost)
func _self_cost(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var by: Dictionary = cfg.get("ratio_by_star", {})
	var r: float = float(by.get(str(mini(unit.star, 3)), cfg.get("ratio", 0.5)))
	var st: StatBlock = unit.get_stats()
	var amt: float = r * st.attack_power * (1.0 + st.ability_power / 100.0)
	amt = minf(amt, maxf(0.0, unit.hp - 1.0) / maxf(1.0, 1.0 + st.damage_taken_amp))
	var hp0: float = unit.hp
	if amt > 0.0:
		fx.damage(null, unit, amt, "true", {"surface": "passive", "ability_id": ability.id, "cfg": {"damage_category": "dot"}})
	var lost: float = maxf(0.0, hp0 - unit.hp)
	unit.meta["self_cost_lost"] = lost
	b.fx({"t": "self_cost", "unit": unit, "amount": lost})


## 青影：携带者获得 1 层【诛影】(上限 = 【叠加 N】)；每层记下这一次的 触发数值 × n(先进先出)，命中时附带的持续伤害 = 各层加起来
func _shadow_slay(unit: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var maxs: int = maxi(1, kw_value(unit, ability, "stacking", 3))
	var scfg: Dictionary = (cfg.get("status", {}) as Dictionary).duplicate(true)
	if scfg.is_empty():
		return
	scfg["max_stacks"] = maxs
	var st: BStatus = fx.apply_status(unit, unit, scfg)
	if st == null:
		return
	var per: Array = st.meta.get("per", [])
	per.append(amount)
	while per.size() > maxs:
		per.pop_front()
	var tot := 0.0
	for v: Variant in per:
		tot += float(v)
	st.meta["per"] = per
	st.meta["total"] = tot
	b.fx({"t": "shadow_slay", "unit": unit, "stacks": st.stacks, "total": tot})


## 诛影附带的持续伤害：普攻 / 技能伤害命中时，给目标一个独立的魔法持续伤害(2 秒、每 0.5 秒一跳，总量 = 诛影各层加起来)
func _shadow_rot(unit: BUnit, t: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var st: BStatus = unit.get_status("shadow_slay")
	if st == null or t == null or not t.alive:
		return
	var tot: float = float(st.meta.get("total", 0.0))
	if tot <= 0.0:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var dur: float = float(cfg.get("duration", 2.0))
	var iv: float = float(cfg.get("interval", 0.5))
	var ticks: float = maxf(1.0, round(dur / iv))
	fx.apply_status(unit, t, {"status_id": "shadow_rot", "independent": true, "duration": dur + 0.05, "max_stacks": 1,
		"flags": ["debuff", "dispellable"], "dot": {"kind": "magic", "amount": tot / ticks, "interval": iv}})


# ---------------------------------------------------------------- 止息节点
## 我方攻击力最高的远程友军(不含自己；普攻要是伤害、不是打队友的)：标定的免费弹道、掩护支援都看它
func support_shooter(unit: BUnit) -> BUnit:
	var best: BUnit = null
	for a: BUnit in b.allies_of(unit):
		if not a.alive or not a.is_ranged() or not a.can_attack() or a.has_flag("na_target_hurt_ally") or a.has_flag("untargetable"):
			continue
		var na: AbilityDef = a.na_payload()
		if na == null or not na.effect_type.ends_with("_damage"):
			continue
		if best == null or a.get_stats().attack_power > best.get_stats().attack_power:
			best = a
	return best


## 画上句点：突进。先把目标从它现在打的人那里击退(没有目标就从她身边推开)，再冲到它背后(击退方向那一侧)恰好够得着的位置；
## 落地(dash_arrive)立刻普攻、强制它索敌自己、施加【标定】。拿近战武器时空翻过它头顶，拿远程武器时从它身侧划过(表现：lunge_start.style)
func _commando_lunge(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var t: BUnit = unit.target
	if t == null or not t.alive or t.team == unit.team or unit.phase == "dash":
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var away: Vector2 = unit.pos
	var tt: BUnit = t.target
	if tt != null and tt.alive and tt != t and tt.team != t.team:
		away = tt.pos
	var kdir: Vector2 = t.pos - away
	if kdir.length() < 0.05:
		kdir = t.pos - unit.pos
	if kdir.length() < 0.05:
		kdir = Vector2(sin(unit.facing), cos(unit.facing))
	kdir = kdir.normalized()
	var kd: float = float(cfg.get("knock", 2.0))
	_knockback(unit, t, kd, {"cfg": {"max_dist": kd}, "dir": kdir})
	var tpos: Vector2 = (t.meta["knock"] as Dictionary)["to"] if t.meta.has("knock") else t.pos
	var land: float = maxf(unit.get_stats().range_meters() + t.radius * 0.6, BattleAI.touch_reach(unit, t)) - 0.05
	var spot: Vector2 = b.map.push_out(b.clamp_to_arena(tpos + kdir * land, unit.radius), unit.radius)
	var from: Vector2 = unit.pos
	var dur: float = clampf(from.distance_to(spot) / float(cfg.get("speed", 9.0)), 0.3, 0.7)
	b.interrupt(unit)
	unit.phase = "dash"
	unit.vel = Vector2.ZERO
	unit.engaged = false
	if from.distance_to(spot) > 0.05:
		unit.facing = atan2(spot.x - from.x, spot.y - from.y)
	unit.meta["dash"] = {"from": from, "to": spot, "t0": b.time, "dur": dur, "lunge": t, "mark": cfg.get("mark", {})}
	b.fx({"t": "lunge_start", "unit": unit, "target": t, "from": from, "to": spot, "dur": dur, "style": "slide" if unit.is_ranged() else "flip"})
	emit("OnLunge", unit, t, 0.0, ["lunge"], {})


## 突进落地：立刻普攻(不走弹道)，强制目标索敌自己(到标定被消耗为止)，施加【标定】
func _lunge_arrive(u: BUnit, d: Dictionary) -> void:
	var t: BUnit = d.get("lunge") as BUnit
	if t == null or not t.alive:
		return
	u.facing = atan2(t.pos.x - u.pos.x, t.pos.y - u.pos.y)
	u.target = t
	u.attack_target = t
	u.last_target_check = b.time
	normal_attack(u, t, false, {"instant": true})
	u.attack_cd = maxf(u.attack_cd, u.get_stats().attack_interval())
	if not t.alive:
		return
	t.forced_target = u
	t.forced_until = b.time + 600.0
	t.target = u
	var mcfg: Dictionary = (d.get("mark", {}) as Dictionary).duplicate(true)
	if not mcfg.is_empty():
		var mm: Dictionary = mcfg.get("meta", {})
		mm["by"] = u.uid
		mm["t0"] = b.time
		mcfg["meta"] = mm
		fx.apply_status(u, t, mcfg)
	b.fx({"t": "lunge_end", "unit": u, "target": t})


## 标定累计 3 秒：我方攻击力最高的远程友军立刻对它打出一发免费普攻弹道(按当次普攻的一切加成——正在拉弓 / 瞄准就按已经瞄了的倍率；
## 不消耗弹药、不算攻击、不打断它的拉弓 / 瞄准)。命中时消耗标定(Pipeline._free_shot_landed)
func _mark_volley(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var sid: String = str(cfg.get("status_id", "commando_mark"))
	var wait: float = float(cfg.get("delay", 3.0))
	for e: BUnit in b.enemies_of(unit):
		var st: BStatus = e.get_status(sid)
		if st == null or str(st.meta.get("by", "")) != unit.uid:
			continue
		# 已经打出去了：等它命中(弹道被高障碍挡住 / 打出去的人倒下了就打不到——2 秒后再打一发)
		if st.meta.has("fired_at") and b.time - float(st.meta["fired_at"]) < 2.0:
			continue
		if b.time - float(st.meta.get("t0", b.time)) < wait - 0.001:
			continue
		var sh: BUnit = support_shooter(unit)
		if sh == null:
			continue
		st.meta["fired_at"] = b.time
		var sc := 1.0
		if sh.phase == "draw":
			sc = Pipeline.na_draw_scale(sh, sh.phase_t, sh.draw_dur)
		b.fx({"t": "mark_volley", "unit": unit, "shooter": sh, "target": e, "chant_scale": sc})
		b.deliver_normal_attack(sh, e, false, {"free": true, "consume_mark": sid, "chant_scale": sc})


## 免费弹道打到了：命中就消耗标定(并解除它对止息节点的强制索敌)；被闪开就下一帧再打一发
func _free_shot_landed(attacker: BUnit, defender: BUnit, opts: Dictionary, missed: bool) -> void:
	if defender == null:
		return
	var sid: String = str(opts.get("consume_mark", ""))
	var st: BStatus = defender.get_status(sid) if sid != "" else null
	if st == null:
		return
	if missed or not defender.alive:
		st.meta.erase("fired_at")
		return
	var by: BUnit = b.get_unit_by_uid(str(st.meta.get("by", "")))
	fx.remove_status(defender, sid)
	if by != null and defender.forced_target == by:
		defender.forced_until = b.time
	b.fx({"t": "mark_consumed", "unit": defender, "shooter": attacker})


## 掩护支援：近战敌人靠近攻击力最高的远程友军，立刻改为索敌它(它没有标定 → 下一帧画上句点突进过去)
func _cover_retarget(unit: BUnit, t: BUnit) -> void:
	if t == null or not t.alive or t == unit.target:
		return
	unit.target = t
	unit.engaged = false
	unit.last_target_check = b.time
	b.fx({"t": "cover", "unit": unit, "target": t, "ally": support_shooter(unit)})
	emit("OnTargeting", unit, t, 0.0, ["targeting"], {})


# ---------------------------------------------------------------- 灭罪节点
## 她是唯一的光：吟唱期间的光束(unit.meta.light_beam)。吟唱开始后的第一个战斗帧降临在敌方最强的单位所在的位置(Targeting.strongest_pick)；
## 之后 Battle._step_light_beams 每一步把它慢慢挪向敌方本场伤害最高的单位(不避让友军、不管地形)；她不在吟唱(被打断 / 倒下)时光束消失。
## 之后每个战斗帧：中心的主目标受到 触发数值 × 增长倍率 的法术伤害；有没有主目标，中心都照常溅射(不分敌我，半径 × 增长倍率)
func _light_beam(unit: BUnit, amount: float, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	if unit.phase != "chant":
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var lb: Dictionary = unit.meta.get("light_beam", {})
	if lb.is_empty() or not is_equal_approx(float(lb["chant"]), unit.chant_until):
		var st0: BUnit = Targeting.strongest_pick(b, unit)
		if st0 == null:
			return
		lb = {"pos": st0.pos, "prev": st0.pos, "lock": st0, "chant": unit.chant_until, "born": b.time, "t0": b.time,
			"steps": 0, "bonus": 0, "ramp": 0.0, "mult": 1.0, "speed": float(cfg.get("speed", 1.0)), "core": float(cfg.get("core", 0.3)),
			"base_rad": splash_radius(unit, ability)}
		lb["rad"] = lb["base_rad"]
		unit.meta["light_beam"] = lb
		b.fx({"t": "light_beam_start", "unit": unit, "pos": st0.pos, "radius": float(lb["rad"])})
		return
	var m: float = light_beam_mult(unit)
	var c: Vector2 = lb["pos"]
	var main: BUnit = light_beam_main(unit)
	var o2: Dictionary = o.duplicate()
	o2["splash_rad_mult"] = m
	var dmg: float = amount * m
	if main != null:
		_apply_effect(unit, main, "magic_damage", dmg, ability, o2, ctx)
	_splash(unit, c, main, "magic_damage", dmg, ability, o2, ctx, str(o.get("surface", "passive")))
	b.fx({"t": "light_beam_tick", "unit": unit, "pos": c, "radius": float(lb["rad"]), "target": main, "mult": m})


## 光束现在的增长倍率(她将照亮长夜：每吟唱 0.5 秒 +y%，造成击杀直接 +2 秒的量；被打断时随光束一起重置)
func light_beam_mult(unit: BUnit) -> float:
	var lb: Dictionary = unit.meta.get("light_beam", {})
	if lb.is_empty():
		return 1.0
	return 1.0 + float(lb.get("ramp", 0.0)) * float(int(lb.get("steps", 0)) + int(lb.get("bonus", 0)))


## 光束中心的主目标：锁定的那个敌人在中心就是它，否则是中心范围里离得最近的敌人；没有 = null
func light_beam_main(unit: BUnit) -> BUnit:
	var lb: Dictionary = unit.meta.get("light_beam", {})
	if lb.is_empty():
		return null
	var c: Vector2 = lb["pos"]
	var core: float = float(lb.get("core", 0.3))
	var lk: BUnit = lb.get("lock") as BUnit
	if lk != null and lk.alive and lk.team != unit.team and lk.pos.distance_to(c) <= core + lk.radius:
		return lk
	var best: BUnit = null
	var bd := 1.0e9
	for e: BUnit in b.enemies_of(unit):
		var d: float = e.pos.distance_to(c)
		if d <= core + e.radius and d < bd:
			bd = d
			best = e
	return best


## 她将照亮长夜(2 星)：战斗帧 = 按光束在场了多久更新"每 0.5 秒一层"；造成击杀 = 直接加 2 秒的层数(kill_steps)。层数存在光束上，光束没了就清零
func _light_ramp(unit: BUnit, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	var lb: Dictionary = unit.meta.get("light_beam", {})
	if lb.is_empty() or unit.phase != "chant":
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	lb["ramp"] = float(cfg.get("ramp_pct", 0.0))
	if str((ctx["ev"] as Dictionary).get("timing", "")) == "OnUnitKilled":
		lb["bonus"] = int(lb.get("bonus", 0)) + int(cfg.get("kill_steps", 4))
		b.fx({"t": "light_boost", "unit": unit, "pos": lb["pos"]})
	else:
		lb["steps"] = int(floor((b.time - float(lb["t0"])) / maxf(0.05, float(cfg.get("ramp_step", 0.5))) + 0.0001))
	lb["mult"] = light_beam_mult(unit)
	lb["rad"] = float(lb["base_rad"]) * float(lb["mult"])


## 光之心：触发目标当前生命低于 n × 触发数值就斩杀它(不触发它自己的阵亡时效果：濒死 / 阵亡时机都不发，锁血也挡不住)
func _absolve(unit: BUnit, t: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	if t == null or not t.alive:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	if t.hp >= amount * float(cfg.get("n", 1.0)):
		return
	t.meta["_doomed"] = true
	t.meta["no_death_fx"] = true
	b.fx({"t": "absolve", "unit": unit, "target": t, "pos": t.pos})
	fx._hp_loss(unit, t, t.hp, o)


func _infuse(unit: BUnit, t: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	if t == null or not t.alive:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var n: int = int(floor(amount / maxf(1.0, float(cfg.get("per", 100.0))) + 0.0001))
	var cap: int = maxi(1, kw_value(unit, ability, "stacking", 6))
	n = mini(n, cap)
	if n <= 0:
		return
	var sc: Dictionary = (cfg.get("status", {}) as Dictionary).duplicate(true)
	sc["add_stacks"] = n
	sc["max_stacks"] = cap
	var mm: Dictionary = sc.get("meta", {})
	mm["pop"] = float(cfg.get("pop", 50.0))
	sc["meta"] = mm
	fx.apply_status(unit, t, sc, o)


## 浸染被打到(unit = 持有者，t = 攻击者)：消耗一层，给攻击者回复 pop 点生命，再对持有者造成等量的法术伤害(都算施加浸染的人的)
func _infusion_pop(unit: BUnit, t: BUnit, ability: AbilityDef) -> void:
	var st: BStatus = unit.get_status("infusion")
	if st == null or st.stacks <= 0:
		return
	var src: BUnit = b.get_unit_by_uid(st.source_id)
	var pop: float = float(st.meta.get("pop", 50.0))
	st.stacks -= 1
	if st.stacks <= 0:
		fx.end_status(unit, "infusion")
	else:
		unit.mark_dirty()
		b.fx({"t": "status", "unit": unit, "id": "infusion", "base_id": "infusion", "stacks": st.stacks, "created": false, "flags": st.flags, "src": src})
	b.fx({"t": "infusion_pop", "unit": unit, "attacker": t, "src": src, "amount": pop})
	if t != null and t.alive:
		fx.heal(src if src != null and src.alive else t, t, pop, {"surface": "status", "ability_id": "infusion"})
	if unit.alive:
		fx.damage(src, unit, pop, "magic", {"surface": "status", "ability_id": "infusion", "can_crit": false})


# ---------------------------------------------------------------- 心音节点：演奏
## 会伤害人的能力(伤害、带 debuff 标记的状态)；双模(护符大类)的不算——它对队友会自动换成增益
static func harmful(ability: AbilityDef) -> bool:
	if ability.ability_class == "amulet":
		return false
	if ability.effect_type.ends_with("_damage") or ability.effect_type in ["hp_loss_pct", "status_detonate", "knockback", "mislead", "gather_stun"]:
		return true
	return ability.effect_type == "stat_status" and (ability.effect_config.get("flags", []) as Array).has("debuff")


## 触发者正在吟唱：吟唱中 / 拉弓蓄力中，或者这次触发来自一发蓄过力的普攻(事件 meta.chant_scale > 1)
func is_chanting(unit: BUnit, o: Dictionary = {}) -> bool:
	if unit.phase == "chant" or unit.phase == "draw":
		return true
	var em: Dictionary = o.get("ev_meta", {})
	return float(em.get("chant_scale", 1.0)) > 1.01


func _scale_status_cfg(cfg: Dictionary, m: float) -> void:
	for key: String in ["stats", "stats_by_star"]:
		if not cfg.has(key):
			continue
		var sts: Dictionary = cfg[key]
		for sk: String in sts.keys():
			var e: Dictionary = sts[sk]
			for mode: String in ["flat", "pct"]:
				if not e.has(mode):
					continue
				if e[mode] is Dictionary:
					for k2: Variant in (e[mode] as Dictionary).keys():
						e[mode][k2] = float(e[mode][k2]) * m
				else:
					e[mode] = float(e[mode]) * m


func _perform_ability(unit: BUnit) -> AbilityDef:
	for pa: AbilityDef in unit.def.passives:
		if pa.has_keyword("performance"):
			return pa
	return null


func _pcfg(unit: BUnit, key: String, fallback: float = 0.0) -> float:
	var ab: AbilityDef = _perform_ability(unit)
	if ab == null:
		return fallback
	var pc: Dictionary = ab.effect_config.get("performance", {})
	var v: Variant = pc.get(key, fallback)
	if v is Dictionary:
		return float((v as Dictionary).get(str(mini(unit.star, 3)), fallback))
	return float(v)


## 挑这一段演奏：七种效果各自找最合适的对象、打个分，挑分最高的(和上一段不同)。结果记在 unit.meta.perf_next
## might 攻击力 / 法强最高的队友加攻 / 法强；burn 生命最低的敌人燃烧；chill 本场输出最高的敌人寒气；regen 生命比例最低的友方再生；
## repel 贴近我方后排的敌方近战击退 + 减速；wound 本场回复最多的敌人减疗；shred 本场承伤最多的敌人削甲 / 魔抗
func perform_pick(unit: BUnit) -> Dictionary:
	var last: String = str(unit.meta.get("perf_last", ""))
	var allies: Array[BUnit] = b.allies_of(unit)
	var allies_self: Array[BUnit] = b.allies_of(unit, true)
	var foes: Array[BUnit] = b.enemies_of(unit)
	var cands: Array = []                               # [分, 效果, 对象]
	var best_ally: BUnit = might_target(unit)
	if best_ally != null:
		cands.append([1.0, "might", best_ally])
	var low: BUnit = null
	for e: BUnit in foes:
		if low == null or e.hp < low.hp:
			low = e
	if low != null:
		cands.append([0.5 + 0.9 * (1.0 - low.hp_ratio()), "burn", low])
	var top: BUnit = null
	var top_v := -1.0
	for e2: BUnit in foes:
		var dv: float = float((b.report.rows.get(e2.uid, {}) as Dictionary).get("dealt", 0.0))
		if dv > top_v or (dv == top_v and top != null and e2.get_stats().attack_power > top.get_stats().attack_power):
			top_v = dv
			top = e2
	if top != null:
		cands.append([(1.1 if top_v > 0.0 else 0.6) * (0.3 if top.has_flag("frozen") else 1.0), "chill", top])
	var weak: BUnit = null
	for a: BUnit in allies_self:
		if weak == null or a.hp_ratio() < weak.hp_ratio():
			weak = a
	if weak != null and weak.hp_ratio() < 0.9:
		cands.append([0.3 + 1.6 * (1.0 - weak.hp_ratio()), "regen", weak])
	var reach: float = _pcfg(unit, "repel_reach", 2.5)
	var rep: BUnit = null
	var rep_d := 1.0e9
	for e3: BUnit in foes:
		if e3.is_ranged() or not e3.can_attack() or e3.cc_resistant() and e3.def.radius * e3.def.scale > 0.8:
			continue
		for a2: BUnit in allies_self:
			if not a2.is_ranged():
				continue
			var d: float = e3.pos.distance_to(a2.pos) - e3.radius - a2.radius
			if d < reach and d < rep_d:
				rep_d = d
				rep = e3
	if rep != null:
		cands.append([1.6, "repel", rep])
	var heal_t: BUnit = null
	var heal_v := 0.0
	for e4: BUnit in foes:
		var hv: float = float((b.report.rows.get(e4.uid, {}) as Dictionary).get("healed", 0.0))
		if hv > heal_v:
			heal_v = hv
			heal_t = e4
	if heal_t != null and heal_v >= 100.0:
		cands.append([0.6 + minf(0.7, heal_v / 800.0), "wound", heal_t])
	var tank_t: BUnit = null
	var tank_v := 0.0
	for e5: BUnit in foes:
		var tv: float = float((b.report.rows.get(e5.uid, {}) as Dictionary).get("taken", 0.0))
		if tv > tank_v:
			tank_v = tv
			tank_t = e5
	if tank_t != null and tank_v >= 150.0:
		cands.append([0.85, "shred", tank_t])
	var pick: Array = []
	for c: Array in cands:
		if str(c[1]) == last:
			continue
		if pick.is_empty() or float(c[0]) > float(pick[0]):
			pick = c
	if pick.is_empty():
		unit.meta.erase("perf_next")
		return {}
	var r := {"opt": str(pick[1]), "target": pick[2]}
	unit.meta["perf_next"] = r
	return r


## 攻击力 / 法术强度最高的队友(不含自己)
func might_target(unit: BUnit) -> BUnit:
	var best: BUnit = null
	var bv := -1.0
	for a: BUnit in b.allies_of(unit):
		var st: StatBlock = a.get_stats()
		var v: float = maxf(st.attack_power, st.ability_power)
		if v > bv:
			bv = v
			best = a
	return best


## 加攻还是加法强："选较优的一方"——普攻按法强算、或者法强比攻击力的一半还高的加法强，否则加攻击力
func _might_cfg(unit: BUnit, t: BUnit, dur: float) -> Dictionary:
	var st: StatBlock = t.get_stats()
	var ap: bool = t.def.na_scaling == "ability_power" or st.ability_power > st.attack_power * 0.5
	if ap:
		return {"status_id": "bard_might_ap", "duration": dur, "max_stacks": 1, "flags": ["buff", "dispellable", "performance"],
			"stats": {"ability_power": {"flat": _pcfg(unit, "ap_flat", 20.0)}}}
	return {"status_id": "bard_might_atk", "duration": dur, "max_stacks": 1, "flags": ["buff", "dispellable", "performance"],
		"stats": {"attack_power": {"pct": _pcfg(unit, "atk_pct", 0.15)}}}


## 演奏开始(吟唱开始时)：施加这一段的效果，维持到吟唱结束(状态的持续时间 = 吟唱剩下的时间)；记下施加的状态，结束 / 不绝的回响时用
func _perform_start(unit: BUnit, ability: AbilityDef, target: BUnit) -> void:
	var pk: Dictionary = unit.meta.get("perf_next", {})
	unit.meta.erase("perf_next")
	if pk.is_empty() or target == null or pk.get("target") != target:
		return
	var opt: String = str(pk["opt"])
	var pf := {"opt": opt, "target": target, "sts": [], "until": unit.chant_until, "next_tick": maxf(b.time, unit.chant_until - unit.phase_dur) + 1.0}
	unit.meta["perf"] = pf
	var dur: float = maxf(0.1, unit.chant_until - b.time + 0.05)
	match opt:
		"might":
			_perform_status(unit, target, _might_cfg(unit, target, dur))
		"burn":
			for i in range(int(_pcfg(unit, "burns", 1.0))):
				_perform_status(unit, target, {"status_id": "burning", "duration": dur, "max_stacks": 1, "independent": true,
					"flags": ["debuff", "burning", "dispellable", "performance"], "dot": {"kind": "magic", "amount": 25.0, "interval": 1.0}})
		"chill":
			_perform_chill(unit, target, int(_pcfg(unit, "chill_first", 1.0)))
		"regen":
			_perform_regen(unit, target, int(_pcfg(unit, "regen_first", 1.0)))
		"repel":
			# 从离它最近的我方后排那边把它往外推，再维持减速
			var from: BUnit = unit
			var fd := 1.0e9
			for a: BUnit in b.allies_of(unit, true):
				if a.is_ranged() and a.pos.distance_to(target.pos) < fd:
					fd = a.pos.distance_to(target.pos)
					from = a
			_knockback(from, target, _pcfg(unit, "repel_dist", 2.0), {"cfg": {"max_dist": 3.0}})
			_perform_status(unit, target, {"status_id": "bard_slow", "duration": dur, "max_stacks": 1, "flags": ["debuff", "dispellable", "performance"],
				"stats": {"move_speed": {"pct": -_pcfg(unit, "slow", 0.3)}}})
		"wound":
			_perform_status(unit, target, {"status_id": "bard_wound", "duration": dur, "max_stacks": 1, "flags": ["debuff", "dispellable", "performance"],
				"stats": {"healing_received_pct": {"flat": -_pcfg(unit, "heal_cut", 0.35)}}})
		"shred":
			var sp: float = _pcfg(unit, "shred", 0.15)
			_perform_status(unit, target, {"status_id": "bard_shred", "duration": dur, "max_stacks": 1, "flags": ["debuff", "dispellable", "performance"],
				"stats": {"defense": {"pct": -sp}, "magic_resistance": {"pct": -sp}}})
	b.fx({"t": "perform_start", "unit": unit, "target": target, "opt": opt, "duration": dur})


func _perform_status(unit: BUnit, t: BUnit, cfg: Dictionary) -> void:
	var st: BStatus = fx.apply_status(unit, t, cfg)
	if st != null:
		(unit.meta["perf"]["sts"] as Array).append([t, st.id])


func _perform_chill(unit: BUnit, t: BUnit, n: int = 1) -> void:
	var pf: Dictionary = unit.meta.get("perf", {})
	for i in range(n):
		if not t.alive:
			return
		var st: BStatus = fx.apply_chill(unit, t, maxf(0.1, float(pf.get("until", b.time)) - b.time + 0.05), ["performance"])
		if st != null and unit.meta.has("perf"):
			(unit.meta["perf"]["sts"] as Array).append([t, st.id])


func _perform_regen(unit: BUnit, t: BUnit, n: int = 1) -> void:
	var pf: Dictionary = unit.meta.get("perf", {})
	for i in range(n):
		var st: BStatus = fx.apply_regen(unit, t, maxf(0.1, float(pf.get("until", b.time)) - b.time + 0.05), ["performance"])
		if st != null and unit.meta.has("perf"):
			(unit.meta["perf"]["sts"] as Array).append([t, st.id])


## 每个战斗帧：演奏中，寒气 / 再生每秒再叠一个(维持 = 越叠越多)
func _perform_tick(unit: BUnit) -> void:
	var pf: Dictionary = unit.meta.get("perf", {})
	if pf.is_empty() or unit.phase != "chant" or b.time < float(pf["next_tick"]) - 0.001 or b.time >= float(pf["until"]) - 0.05:
		return
	pf["next_tick"] = float(pf["next_tick"]) + 1.0
	var t: BUnit = pf.get("target") as BUnit
	if t == null or not t.alive:
		return
	match str(pf["opt"]):
		"chill":
			_perform_chill(unit, t)
		"regen":
			_perform_regen(unit, t)


## 演奏结束(吟唱结束 / 被打断)：收掉维持的效果
func _perform_end(unit: BUnit) -> void:
	var pf: Dictionary = unit.meta.get("perf", {})
	if pf.is_empty():
		return
	unit.meta.erase("perf")
	unit.meta["perf_last"] = str(pf["opt"])
	for e: Array in pf["sts"]:
		var t: BUnit = e[0]
		if t != null and t.statuses.has(str(e[1])):
			fx.end_status(t, str(e[1]))


## 不绝的回响(自己阵亡)：当时演奏维持的效果此后永久持续；其中没有"加攻 / 法强"就也给攻击力 / 法强最高的队友永久加上
func _perform_echo(unit: BUnit, ability: AbilityDef) -> void:
	var pf: Dictionary = unit.meta.get("perf", {})
	unit.meta.erase("perf")
	var kept: Array = []
	for e: Array in pf.get("sts", []):
		var t: BUnit = e[0]
		var st: BStatus = t.get_status(str(e[1])) if t != null and t.alive else null
		if st != null:
			st.expires_at = -1.0
			kept.append(t)
	if str(pf.get("opt", "")) != "might":
		var mt: BUnit = might_target(unit)
		if mt != null:
			var cfg: Dictionary = _might_cfg(unit, mt, 0.0)
			fx.apply_status(unit, mt, cfg)
			kept.append(mt)
	b.fx({"t": "perform_echo", "unit": unit, "targets": kept, "opt": str(pf.get("opt", ""))})


# ---------------------------------------------------------------- 龙的余烬(红之章首领)：点燃格子、余烬扩散
## 在目标脚下烧起一块余烬(那一格已经在烧 / 烧不了就挑旁边一格)；亮着的余烬超过 cap 格就不再烧
func _ignite_embers(unit: BUnit, t: BUnit, cfg: Dictionary) -> void:
	if t == null or not t.alive or b.map.lit_ember_cells() >= int(cfg.get("cap", 48)):
		return
	var c0: Vector2i = GC.world_to_cell(t.pos)
	var cands: Array[Vector2i] = [c0]
	var ring: Array[Vector2i] = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx != 0 or dy != 0:
				ring.append(c0 + Vector2i(dx, dy))
	_shuffle_cells(ring)
	cands.append_array(ring)
	for c: Vector2i in cands:
		var id: int = b.ignite_cell(c, unit)
		if id >= 0:
			b.fx({"t": "dragon_ignite", "unit": unit, "target": t, "id": id, "pos": GC.cell_to_world(c.x, c.y)})
			return


## 余烬扩散：随机挑 count 块亮着的余烬，各往旁边(上下左右)一格烧过去；亮着的余烬超过 cap 格就停
func _spread_embers(unit: BUnit, cfg: Dictionary) -> void:
	var cap: int = int(cfg.get("cap", 48))
	var n: int = int(cfg.get("count", 2))
	var lit: Array = []
	for e: Dictionary in b.map.embers:
		if bool(e["lit"]):
			lit.append(e)
	if lit.is_empty():
		return
	var spread: Array = []
	for k in range(n):
		if b.map.lit_ember_cells() >= cap:
			break
		var e2: Dictionary = lit[b.rng.randi() % lit.size()]
		var r: Rect2i = e2["rect"]
		var side: Array[Vector2i] = []
		for x in range(r.position.x, r.end.x):
			side.append(Vector2i(x, r.position.y - 1))
			side.append(Vector2i(x, r.end.y))
		for y in range(r.position.y, r.end.y):
			side.append(Vector2i(r.position.x - 1, y))
			side.append(Vector2i(r.end.x, y))
		_shuffle_cells(side)
		for c: Vector2i in side:
			var id: int = b.ignite_cell(c, unit)
			if id >= 0:
				spread.append([int(e2["id"]), id])
				lit.append(b.map.embers[id])
				break
	if not spread.is_empty():
		b.fx({"t": "ember_spread", "unit": unit, "pairs": spread})


func _shuffle_cells(a: Array[Vector2i]) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j: int = b.rng.randi() % (i + 1)
		var tmp: Vector2i = a[i]
		a[i] = a[j]
		a[j] = tmp


# ---------------------------------------------------------------- 真望节点
## 一个单位所有的【充能】效果(被动 / 普攻载荷 / 武器效果；同一个 id 只算一次)：[{ability, max, cur}]
func charged_entries(u: BUnit, passives_only: bool = false) -> Array:
	var out: Array = []
	var seen := {}
	for e: Dictionary in u.all_ability_entries():
		var ab: AbilityDef = e["ability"]
		if not ab.has_keyword("charged") or seen.has(ab.id):
			continue
		if passives_only and str(e["surface"]) == "equipment":
			continue
		seen[ab.id] = true
		var mx: int = _max_charges(ab, u)
		_recharge(u, ab, mx)                         # 充能是用到时才初始化 / 回复的(流星爆魔杖开战 0 层)：先按规则补到现在
		out.append({"ability": ab, "max": mx, "cur": int(u.ability_charges.get(ab.id, mx))})
	return out


## 我方活着的单位的【充能】一共还有多少层
func team_charges(team: int) -> int:
	var n := 0
	for u: BUnit in b.units:
		if u.alive and u.team == team:
			for ce: Dictionary in charged_entries(u):
				n += int(ce["cur"])
	return n


## 金矢该射给谁：其它队友里，有充能不满的【充能】效果的；优先没有黄金的指引的，再按那个效果的冷却时间最长；一样就挑近的。exclude = 已经选了的
func golden_target(u: BUnit, exclude: Array = []) -> BUnit:
	var best: BUnit = null
	var best_s := -1.0e9
	for a: BUnit in b.allies_of(u):
		if a == u or exclude.has(a):
			continue
		var cd := -1.0
		for ce: Dictionary in charged_entries(a):
			if int(ce["cur"]) < int(ce["max"]):
				cd = maxf(cd, (ce["ability"] as AbilityDef).cooldown)
		if cd < 0.0:
			continue
		var s: float = cd + (0.0 if a.status_stacks("golden_guidance") > 0 else 10000.0) - u.pos.distance_to(a.pos) * 0.001
		if s > best_s:
			best_s = s
			best = a
	return best


## 金矢命中队友：消耗一层金矢，给他冷却时间最长的、充能不满的【充能】效果回 1 层，再给一层黄金的指引(和金矢同样的【叠加】上限、每层减伤)
func _golden_arrow(unit: BUnit, t: BUnit, o: Dictionary) -> void:
	if t == null or not t.alive or unit.status_stacks("golden_arrow") <= 0:
		return
	var pick: Dictionary = {}
	for ce: Dictionary in charged_entries(t):
		if int(ce["cur"]) < int(ce["max"]) and (pick.is_empty() or (ce["ability"] as AbilityDef).cooldown > (pick["ability"] as AbilityDef).cooldown):
			pick = ce
	if pick.is_empty():
		return
	var ga: BStatus = unit.get_status("golden_arrow")
	ga.stacks -= 1
	unit.mark_dirty()
	b.fx({"t": "status", "unit": unit, "id": "golden_arrow", "base_id": "golden_arrow", "stacks": ga.stacks, "created": false, "flags": ga.flags})
	if ga.stacks <= 0:
		fx.end_status(unit, "golden_arrow")
	var ab: AbilityDef = pick["ability"]
	t.ability_charges[ab.id] = int(pick["cur"]) + 1
	var cap: int = int(ga.max_stacks)
	fx.apply_status(unit, t, {"status_id": "golden_guidance", "flags": ["buff", "no_dispel", "enemies_only"], "max_stacks": cap,
		"stats_by_star": ga.meta.get("dr_stats", {})}, o)
	b.fx({"t": "golden_arrow", "unit": unit, "target": t, "ability": ab.id, "charges": int(t.ability_charges[ab.id])})


## 少女真心：我方全灭时，复活所有具有【充能】的友方单位，被动(不含武器效果)的充能补满；每 1 点充能上限回复 10% 生命
func _team_revive(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var per: float = float(cfg.get("hp_per_charge", 0.1))
	var revived: Array = []
	for u: BUnit in b.units:
		if u.alive or u.team != unit.team or u.is_summon:
			continue
		var ces: Array = charged_entries(u)
		if ces.is_empty():
			continue
		var cap := 0
		for ce: Dictionary in ces:
			cap += int(ce["max"])
		for ce2: Dictionary in charged_entries(u, true):
			u.ability_charges[(ce2["ability"] as AbilityDef).id] = int(ce2["max"])
		b.revive(u, clampf(per * float(cap), 0.05, 1.0))
		revived.append(u)
	b.fx({"t": "team_revive", "unit": unit, "revived": revived})


# ---------------------------------------------------------------- 幻灵节点
## a 在 t 的背后(t 朝向的反方向那半边)
static func is_behind(a: BUnit, t: BUnit) -> bool:
	if a == null or t == null:
		return false
	var fwd := Vector2(sin(t.facing), cos(t.facing))
	var d: Vector2 = a.pos - t.pos
	return d.length() > 0.01 and fwd.dot(d.normalized()) < 0.0


## t 背后贴着它的位置(召唤半径 r 的东西)
func behind_pos(t: BUnit, r: float) -> Vector2:
	var fwd := Vector2(sin(t.facing), cos(t.facing))
	return b.clamp_to_arena(t.pos - fwd * (t.radius + r + 0.15), r)


## 魂体存在：普攻一次后立刻阵亡(留 0.3 秒给攻击动作，期间不再行动)
func spectral_spent(u: BUnit) -> void:
	u.meta["spent"] = true
	u.attack_cd = 99.0
	b.schedule(b.time + 0.3, _spectral_vanish.bind(u))


func _spectral_vanish(u: BUnit) -> void:
	if u.alive:
		u.meta["_doomed"] = true
		u.hp = 0.0
		fx.try_kill(u, null)


## 无形伙伴：开局 / 每 4 秒 → 当前目标背后召唤一个幽灵；普攻(取代原有普攻)→ 目标脚下召唤一只幽灵犬，令它发动普攻。都消耗一层充能
func _medium_summon(unit: BUnit, t: BUnit, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var timing: String = str((ctx["ev"] as Dictionary).get("timing", ""))
	if timing == "OnNormalAttackPerform":
		if t == null or not t.alive or t.team == unit.team:
			return
		var dog: BUnit = fx.summon_one(unit, str(cfg.get("dog", "node_dog")), t.pos, {}, t)
		if dog != null:
			b.schedule(b.time + 0.12, _dog_bite.bind(dog, t))
		return
	var tgt: BUnit = unit.target if unit.target != null and unit.target.alive and unit.target.team != unit.team else null
	if tgt == null:
		var bd := 1.0e9
		for e: BUnit in b.enemies_of(unit):
			if unit.pos.distance_to(e.pos) < bd:
				bd = unit.pos.distance_to(e.pos)
				tgt = e
	if tgt == null:
		return
	var gd: UnitDef = b.catalog.get_unit(str(cfg.get("ghost", "node_ghost")))
	if gd != null:
		fx.summon_one(unit, gd.id, behind_pos(tgt, gd.radius), {}, tgt)


## 幽灵犬一出来就扑上去咬(普攻)；目标已经没了就找身边 2 米内的敌人，没有就散掉
func _dog_bite(dog: BUnit, t: BUnit) -> void:
	if not dog.alive:
		return
	var tgt: BUnit = t if t != null and t.alive else null
	if tgt == null:
		for e: BUnit in b.enemies_of(dog):
			if dog.pos.distance_to(e.pos) < 2.0:
				tgt = e
	if tgt == null:
		spectral_spent(dog)
		return
	var dv: Vector2 = tgt.pos - dog.pos
	if dv.length() > 0.01:
		dog.facing = atan2(dv.x, dv.y)
	dog.attack_target = tgt
	b.fx({"t": "attack_start", "unit": dog, "target": tgt, "windup": 0.0, "recover": 0.3, "weapon_class": dog.weapon_class(),
		"speed_scale": 1.0, "anim": "", "variant": ""})
	b.deliver_normal_attack(dog, tgt, false, {"released_at": b.time})
	if dog.alive and not bool(dog.meta.get("spent", false)):
		spectral_spent(dog)


## 少女幻葬吟唱中(每秒)：溅射范围里随便一个人背后召唤一个幽灵——没有魂体存在(能被打、不会打一下就死)，攻击不分敌我，出不了溅射范围
func _medium_wisp(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var rad: float = passive_splash_radius(unit)
	var pool: Array[BUnit] = []
	var eo: bool = unit.has_flag("enemies_only")
	for u2: BUnit in b.units:
		if u2.alive and u2 != unit and not u2.has_flag("untargetable") and not bool(u2.meta.get("dropping", false)) and not (eo and u2.team == unit.team) \
				and unit.pos.distance_to(u2.pos) <= rad + u2.radius:
			pool.append(u2)
	if pool.is_empty():
		return
	var who: BUnit = pool[b.rng.randi() % pool.size()]
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var gd: UnitDef = b.catalog.get_unit(str(cfg.get("unit_id", "node_ghost")))
	if gd == null:
		return
	# 黄金的指引：这些幽灵的"攻击不分敌我"也改为"仅限敌人"(不再是谁都打的野幽灵)
	fx.summon_one(unit, gd.id, behind_pos(who, gd.radius), {"no_spectral": true, "feral": not eo, "leash": {"c": unit.pos, "r": rad}}, who)


## 少女幻葬(吟唱结束 / 被打断)：每吟唱满 3 秒，就在战场上随机的地方召唤 吟唱期间全场阵亡的单位数 个幽灵(有魂体存在)；然后强制阵亡
func _medium_funeral(unit: BUnit, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	if bool(ctx.get("funeral_done", false)) or not unit.alive:
		return
	ctx["funeral_done"] = true
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var chanted: float = float(ctx.get("chanted", 0.0))
	var t0: float = b.time - chanted
	var deaths := 0
	for dt: float in b.death_times:
		if dt >= t0 - 0.001:
			deaths += 1
	var per: float = float(cfg.get("per_seconds", 3.0))
	var n: int = mini(int(cfg.get("max_ghosts", 30)), int(floor(chanted / per + 0.001)) * deaths)
	var gd: UnitDef = b.catalog.get_unit(str(cfg.get("unit_id", "node_ghost")))
	var spots: Array = []
	var half: Vector2 = GC.map_half() - Vector2(0.8, 0.8)
	for i in range(n):
		var p := Vector2(b.rng.randf_range(-half.x, half.x), b.rng.randf_range(-half.y, half.y))
		spots.append(b.map.push_out(p, gd.radius if gd != null else 0.4))
	b.fx({"t": "medium_funeral", "unit": unit, "radius": passive_splash_radius(unit), "chanted": chanted, "deaths": deaths, "spots": spots})
	for st: String in (cfg.get("end_statuses", []) as Array):
		if unit.statuses.has(st):
			fx.end_status(unit, st)
	if gd != null:
		for sp: Vector2 in spots:
			var tgt: BUnit = null
			var bd := 1.0e9
			for e: BUnit in b.enemies_of(unit):
				if sp.distance_to(e.pos) < bd:
					bd = sp.distance_to(e.pos)
					tgt = e
			fx.summon_one(unit, gd.id, sp, {}, tgt)
	if unit.alive:
		unit.meta["_doomed"] = true
		unit.meta["funeral_death"] = true
		unit.hp = 0.0
		fx.try_kill(unit, null)


# ---------------------------------------------------------------- 幻形节点
## 误导(可驱散、不可叠加、负面)：立刻取消对方当前的索敌，强制改为索敌它自己的一个队友(自相残杀，BattleAI._retarget)；
## 精英 / 首领免疫自相残杀，但照样重新索敌(误导期间不会再选中施加者)
func _mislead(unit: BUnit, t: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	if t == null or not t.alive or t == unit:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var sid: String = str(cfg.get("status_id", "misled"))
	var fresh: bool = not t.statuses.has(sid)
	fx.apply_status(unit, t, {"status_id": sid, "flags": ["debuff", "dispellable"], "max_stacks": 1, "duration": float(cfg.get("duration", 4.0)),
		"meta": {"misled": true, "by": unit}}, o)
	if fresh and t.statuses.has(sid):
		b.fx({"t": "misled", "unit": t, "src": unit, "resist": t.cc_resistant()})


## 少女幻嘘(吟唱结束 / 被打断)：溅射范围里所有其他人(不分敌我)【眩晕】实际吟唱秒数 × x% 秒，然后强制阵亡
func _spy_hush(unit: BUnit, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	if bool(ctx.get("hush_done", false)) or not unit.alive:
		return
	ctx["hush_done"] = true
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var chanted: float = float(ctx.get("chanted", 0.0))
	var x: float = float((cfg.get("x_by_star", {}) as Dictionary).get(str(mini(unit.star, 3)), 0.0))
	var dur: float = chanted * x / 100.0
	var rad: float = passive_splash_radius(unit)
	var hit: Array[BUnit] = []
	var eo: bool = unit.has_flag("enemies_only")
	for u2: BUnit in b.units:
		if u2.alive and u2 != unit and not bool(u2.meta.get("dropping", false)) and not u2.has_flag("untargetable") and not (eo and u2.team == unit.team) \
				and unit.pos.distance_to(u2.pos) <= rad + u2.radius:
			hit.append(u2)
	b.fx({"t": "spy_hush", "unit": unit, "radius": rad, "chanted": chanted, "dur": dur, "hits": hit})
	for st: String in (cfg.get("end_statuses", []) as Array):
		if unit.statuses.has(st):
			fx.end_status(unit, st)
	if dur > 0.0:
		for u3: BUnit in hit:
			fx.apply_status(unit, u3, {"status_id": "stun", "flags": ["debuff", "dispellable", "stun"], "max_stacks": 1, "duration": dur}, o)
	if unit.alive:
		unit.meta["_doomed"] = true
		unit.meta["hush_death"] = true
		unit.hp = 0.0
		fx.try_kill(unit, null)


# ---------------------------------------------------------------- 迅游节点
## 飞身踢的倍率：(100 + 法强)% × (路程 / d0) ^ pow(参数在隐藏状态【飞身踢】的 meta 里；没有这个状态 = 1)
static func kick_mult(u: BUnit, dist: float) -> float:
	var d0: Variant = status_meta(u, "kick_d0")
	if d0 == null:
		return 1.0
	var pw: float = float(status_meta(u, "kick_pow"))
	return (1.0 + maxf(0.0, u.get_stats().ability_power) / 100.0) * pow(maxf(0.0, dist) / maxf(0.1, float(d0)), pw)


## 击退(闪电手套)：把目标往远离施加者的方向推 amount 米(cfg.max_dist 封顶)，0.12~0.3 秒滑过去；路上有墙 / 卡车就停在墙前。
## 只是位移(Battle._step_knocks 每一步叠加)：不打断出招 / 吟唱，也不改它的状态机
func _knockback(unit: BUnit, t: BUnit, amount: float, o: Dictionary) -> void:
	if t == null or not t.alive or t == unit or t.phase == "dash" or t.phase == "throw" or t.phase == "drop":
		return
	var cfg: Dictionary = o.get("cfg", {})
	var dist: float = minf(amount, float(cfg.get("max_dist", 3.0)))
	if dist < 0.05:
		return
	var dir: Vector2 = o.get("dir", t.pos - unit.pos)          # o.dir：指定击退方向(画上句点：从它正在打的人那里推开)
	if dir.length() < 0.01:
		dir = Vector2(sin(unit.facing), cos(unit.facing))
	dir = dir.normalized()
	var to: Vector2 = t.pos
	var walked := 0.0
	while walked < dist - 0.001:
		var stp: float = minf(0.1, dist - walked)
		var nxt: Vector2 = b.clamp_to_arena(to + dir * stp, t.radius)
		if nxt.distance_to(to) < stp * 0.5 or not b.map.circle_free(nxt, t.radius * 0.9):
			break
		to = nxt
		walked += stp
	if walked < 0.05:
		return
	var dur: float = clampf(walked / 10.0, 0.12, 0.3)
	t.meta["knock"] = {"from": t.pos, "to": to, "t0": b.time, "dur": dur, "done": 0.0}
	b.fx({"t": "knockback", "unit": t, "src": unit, "from": t.pos, "to": to, "dur": dur, "style": str(o.get("style", ""))})


# ---------------------------------------------------------------- 幻彩节点
## 闪耀色彩(造成伤害、还有充能)：造成的是物理伤害 → 换上蓝色颜料(魔法伤害增幅，下一次伤害转成魔法)，魔法伤害 → 红色颜料(物理增幅，转成物理)；
## 增幅 = (200 + 2 × 法强 + x)%(进增伤乘区)。颜料只有一份：换新的先把旧的拿掉。不可驱散
func _paint(unit: BUnit, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var kind: String = str(((ctx["ev"] as Dictionary)["meta"] as Dictionary).get("kind", ""))
	if kind != "physical" and kind != "magic":
		return
	var conv: String = "magic" if kind == "physical" else "physical"
	var color: String = "blue" if conv == "magic" else "red"
	var x: float = float((cfg.get("x_by_star", {}) as Dictionary).get(str(mini(unit.star, 3)), 0.0))
	var amp: float = (200.0 + 2.0 * unit.get_stats().ability_power + x) / 100.0
	var sid: String = str(cfg.get("status_id", "paint"))
	if unit.statuses.has(sid):
		fx.end_status(unit, sid)
	fx.apply_status(unit, unit, {"status_id": sid, "flags": ["buff"], "max_stacks": 1,
		"stats": {conv + "_damage_pct": {"flat": amp}}, "meta": {"convert": conv, "color": color}, "variant": color}, o)


## 少女幻终(吟唱结束 / 被打断)：对溅射范围内所有其他人(不分敌我)造成 触发数值 × 实际吟唱秒数 的真实伤害(技能伤害)，然后强制阵亡
func _magi_finale(unit: BUnit, amount: float, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	if bool(ctx.get("finale_done", false)) or not unit.alive:
		return
	ctx["finale_done"] = true
	var chanted: float = float(ctx.get("chanted", 0.0))
	var rad: float = passive_splash_radius(unit)
	var hit: Array[BUnit] = []
	var eo: bool = unit.has_flag("enemies_only")
	for u2: BUnit in b.units:
		if u2.alive and u2 != unit and not bool(u2.meta.get("dropping", false)) and not u2.has_flag("untargetable") and not (eo and u2.team == unit.team) \
				and unit.pos.distance_to(u2.pos) <= rad + u2.radius:
			hit.append(u2)
	b.fx({"t": "magi_finale", "unit": unit, "radius": rad, "chanted": chanted, "count": hit.size(), "hits": hit})
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	for st: String in (cfg.get("end_statuses", []) as Array):
		if unit.statuses.has(st):
			fx.end_status(unit, st)
	for u3: BUnit in hit:
		var od: Dictionary = o.duplicate()
		od["can_crit"] = false
		fx.damage(unit, u3, amount * chanted, "true", od)
	if unit.alive:
		unit.meta["_doomed"] = true
		unit.meta["finale_death"] = true
		unit.hp = 0.0
		fx.try_kill(unit, null)


# ---------------------------------------------------------------- 改修节点
## 普攻这一发的伤害类型被弹匣改过没有(适应改造 / 成品完工)：返回 "" / physical / magic / true
static func magazine_kind(unit: BUnit) -> String:
	return str(unit.meta.get("na_kind", "")) if unit != null else ""


## 即时改装(换弹完成)：成品完工之后 → 下一个弹匣是真实伤害、同时吃物理和魔法的加成；
## 否则按对当前目标(没有就最近的敌人)的预计伤害，在物理 / 魔法里挑高的(一样高 = 物理)
func _adapt_magazine(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	if unit.status_stacks(str(ability.cfg("finish_status", "finished_product"))) > 0:
		unit.meta["na_kind"] = "true"
		unit.meta["na_dual"] = true
		b.fx({"t": "magazine", "unit": unit, "kind": "true"})
		return
	var t: BUnit = unit.target if unit.target != null and unit.target.alive and unit.target.team != unit.team else null
	if t == null:
		var bd := 1.0e9
		for e: BUnit in b.enemies_of(unit):
			if e.pos.distance_to(unit.pos) < bd:
				bd = e.pos.distance_to(unit.pos)
				t = e
	if t == null:
		return
	var raw: float = unit.get_stats().attack_power * float(unit.wclass().get("na_mult", 1.0))
	var ph: float = fx.estimate_damage(unit, t, raw, "physical", {"surface": "normal_attack", "can_crit": true, "cfg": {"kind": "physical"}})
	var mg: float = fx.estimate_damage(unit, t, raw, "magic", {"surface": "normal_attack", "can_crit": true, "cfg": {"kind": "magic"}})
	unit.meta["na_kind"] = "magic" if mg > ph + 0.01 else "physical"
	unit.meta["na_dual"] = false
	b.fx({"t": "magazine", "unit": unit, "kind": str(unit.meta["na_kind"]), "target": t})


## 即时改装(叠满后再叠)：立刻对当前目标连开 count 枪普攻(免前后摇)，每枪消耗 1 发子弹，子弹不够就少开(在装弹 / 冲刺 / 被控时不开)
func _bonus_shots(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	if not unit.alive or not unit.can_attack() or unit.is_disarmed():
		return
	if unit.phase in ["reload", "dash", "throw", "drop", "storm", "chant"]:
		return
	var reach: float = unit.get_stats().range_meters()
	var t: BUnit = unit.target
	if t == null or not t.alive or t.team == unit.team or not BattleAI.in_reach(unit, t, unit.pos.distance_to(t.pos), reach) or not b.ai.can_hit(unit, t):
		t = null
		var bd := 1.0e9
		for e: BUnit in b.enemies_of(unit):
			var de: float = unit.pos.distance_to(e.pos)
			if de < bd and BattleAI.in_reach(unit, e, de, reach) and b.ai.can_hit(unit, e):
				bd = de
				t = e
	if t == null:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var am: BStatus = ammo(unit)
	var gap: float = float(cfg.get("gap", 0.12))
	var shots := 0
	for i in range(maxi(1, int(cfg.get("count", 2)))):
		if am != null and am.stacks <= 0:
			break
		spend_ammo(unit)
		var idx: int = shots
		shots += 1
		b.schedule(b.time + gap * float(idx), func() -> void:
			if unit.alive and t.alive and unit.can_attack():
				unit.facing = atan2(t.pos.x - unit.pos.x, t.pos.y - unit.pos.y)
				b.fx({"t": "bonus_shot", "unit": unit, "target": t, "index": idx})
				b.fx({"t": "attack_release", "unit": unit, "target": t, "weapon_class": unit.weapon_class(), "drawn": false, "chant_scale": 1.0})
				b.deliver_normal_attack(unit, t, false, {"instant": true, "released_at": b.time}))


## 失去状态的 count 层(应急道具：触发时先失去一层适应改造)
func _lose_stack(unit: BUnit, t: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var who: BUnit = t if t != null else unit
	var sid: String = str(cfg.get("status_id", ""))
	var st: BStatus = who.get_status(sid)
	if st == null:
		return
	st.stacks -= st.stacks if bool(cfg.get("all", false)) else maxi(1, int(cfg.get("count", 1)))
	if st.stacks <= 0:
		fx.end_status(who, sid)
	else:
		who.mark_dirty()
		b.fx({"t": "status", "unit": who, "id": sid, "base_id": sid, "stacks": st.stacks, "created": false, "flags": st.flags, "src": unit})


# ---------------------------------------------------------------- 星旅节点
## 被动里【溅射 N】的半径(米)：第一个带溅射的已解锁被动(渡星而来)；关键词数值走 kw_value_f
func passive_splash_radius(unit: BUnit) -> float:
	for pa: AbilityDef in unit.def.passives:
		if pa.has_keyword("splash"):
			return splash_radius(unit, pa)
	return 0.0


## 自己被动溅射范围里的敌人个数
func enemies_in_splash(unit: BUnit) -> int:
	var rad: float = passive_splash_radius(unit)
	var n := 0
	for e: BUnit in b.enemies_of(unit):
		if unit.pos.distance_to(e.pos) <= rad + e.radius:
			n += 1
	return n


## 渡星而来(落地)：自己获得 amount 的护盾，范围里的敌人各受 amount × splash_ratio 的伤害(没有主目标，人人都是溅射的那一半)
func _starfall_impact(unit: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var rad: float = passive_splash_radius(unit)
	var hit: Array[BUnit] = []
	for e: BUnit in b.enemies_of(unit):
		if unit.pos.distance_to(e.pos) <= rad + e.radius:
			hit.append(e)
	if amount > 0.0:
		fx.add_shield(unit, unit, amount, o)
	b.fx({"t": "starfall_impact", "unit": unit, "radius": rad, "count": hit.size(), "shield": amount})
	for e2: BUnit in hit:
		var od: Dictionary = o.duplicate()
		od["splash"] = true
		od["can_crit"] = false
		fx.damage(unit, e2, amount * float(cfg.get("splash_ratio", 0.5)), str(cfg.get("damage_kind", "magic")), od)


## 外神之貌(维持嘲讽)：范围里的敌人强制以自己为目标，持续 duration 秒(每个战斗帧刷新)；刚被嘲讽上的发一个表现事件
func _aura_taunt(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var rad: float = passive_splash_radius(unit)
	var dur: float = float(cfg.get("duration", 0.4))
	for e: BUnit in b.enemies_of(unit):
		if unit.pos.distance_to(e.pos) > rad + e.radius:
			continue
		var fresh: bool = e.forced_target != unit or b.time >= e.forced_until
		e.forced_target = unit
		e.forced_until = b.time + dur
		if e.target != unit:
			e.target = unit
		if fresh:
			b.fx({"t": "aura_taunt", "unit": e, "src": unit})


## 外神之貌(锁血)：本应阵亡时留 1 点生命，挂上【外神之貌】——无法被治疗、无法被击杀，duration 秒(按星级)后必定死亡；
## 期间每 pulse_interval 秒(按星级)发一次 OnStatusPulse(真实形态)
func _death_delay(unit: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	if not unit.alive:
		return
	var cfg: Dictionary = (o.get("cfg", ability.effect_config) as Dictionary).duplicate(true)
	unit.hp = maxf(unit.hp, 1.0)
	var sc := {"status_id": str(cfg.get("status_id", ability.id)), "flags": ["undying", "no_heal", "no_dispel"], "max_stacks": 1, "doom": true}
	var s3: String = str(mini(unit.star, 3))
	sc["duration"] = float((cfg.get("duration_by_star", {}) as Dictionary).get(s3, cfg.get("duration", 3.0)))
	sc["pulse_interval"] = float((cfg.get("pulse_by_star", {}) as Dictionary).get(s3, cfg.get("pulse_interval", 0.5)))
	b.fx({"t": "outer_form", "unit": unit, "duration": float(sc["duration"])})
	fx.apply_status(unit, unit, sc, o)


## 流失当前生命的百分比(某已不知名的星星的旗帜)：max(固定值 n1 × 增幅，触发数值每 100 点 n2 × 增幅)%；
## n1 是能力的固定值(amount，和其它固定值修正走同一处)，n2 = 能力倍率
func _hp_loss_pct(unit: BUnit, t: BUnit, amount: float, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	if t == null or not t.alive:
		return
	var amp: float = float(maxi(1, kw_value(unit, ability, "amplify", 1)))
	var pct: float = maxf(amount * amp, ability.value_multiplier * float(ctx.get("value", 0.0)) / 100.0 * amp)
	var od: Dictionary = o.duplicate()
	od["hp_loss"] = true
	fx.damage(unit, t, t.hp * pct / 100.0, "true", od)


# ---------------------------------------------------------------- 清扫节点
## 一发普攻打到 t 身上大概会造成多少伤害(不真的打；完美时计判断"停着的飞刀够不够打死它")：触发数值 = 攻击力(或法强) × 普攻倍率 × na_scale，
## 再按 Effects.estimate_damage 算暴击(期望)、增伤、目标的护甲 / 减伤。只算普攻本身，不算命中后再触发的东西
func estimate_na(u: BUnit, t: BUnit, na_scale: float = 1.0, amp_bonus: float = 0.0) -> float:
	var na: AbilityDef = u.na_payload() if u != null and u.alive else null
	if na == null or t == null or not t.alive or not na.effect_type.ends_with("_damage"):
		return 0.0
	var st: StatBlock = u.get_stats()
	var raw: float = (st.ability_power if u.def.na_scaling == "ability_power" else st.attack_power) * float(u.wclass().get("na_mult", 1.0))
	raw *= na.value_multiplier * na_scale * (1.0 + st.na_mult_pct)
	var kind: String = na.effect_type.replace("_damage", "")
	if kind == "physical" and (u.has_flag("na_magic") or u.def.na_scaling == "ability_power"):
		kind = "magic"
	var ecfg: Dictionary = na.effect_config
	if magazine_kind(u) != "":
		kind = magazine_kind(u)
		ecfg = ecfg.duplicate()
		ecfg["dual_kind"] = kind == "true" and bool(u.meta.get("na_dual", false))
	return fx.estimate_damage(u, t, raw, kind, {"surface": "normal_attack", "can_crit": na.has_keyword("crit"), "cfg": ecfg, "amp_bonus": amp_bonus})


## 清洁世界：对这次选中的几个敌人([群攻 N]：射程内、看得见，近的优先)原地转着圈乱扔飞刀——
## 进入 storm 阶段(BattleAI._do_storm)，到 times 里的每个出手时刻，对每个目标各发动一次普攻
func _blade_storm(unit: BUnit, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	if bool(ctx.get("storm_started", false)) or not unit.alive:
		return
	ctx["storm_started"] = true
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var tg: Array[BUnit] = []
	for t: BUnit in ctx["targets"]:
		if t.alive:
			tg.append(t)
	if tg.is_empty():
		return
	b.interrupt(unit)
	var times: Array = cfg.get("times", [0.35, 0.75])
	unit.phase = "storm"
	unit.phase_t = 0.0
	unit.phase_dur = float(cfg.get("duration", 1.2))
	unit.vel = Vector2.ZERO
	unit.meta["storm"] = {"targets": tg, "times": times, "fired": 0}
	unit.meta.erase("_gather_" + ability.id)          # 等人进射程的计时从下一次重新开始
	b.fx({"t": "storm_start", "unit": unit, "targets": tg, "duration": unit.phase_dur, "times": times,
		"ability": ability.id, "ultimate": bool(cfg.get("ultimate", false))})


## 闪烁刀刃：瞬移(没有中间过程)到刚好能打到 t 的地方，原本盯着自己的敌人重新索敌；然后立刻对 t 连发 ⌊amount⌋ 次普攻(每 gap 秒一次)。
## amount = 触发数值 × 能力倍率(= 1/n：每 n 点触发数值 1 次)。落点见 _blink_spot
func _blink_strike(unit: BUnit, t: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	if not unit.alive or t == null or not t.alive or unit.phase == "dash" or unit.phase == "throw" or not unit.can_attack():
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var from: Vector2 = unit.pos
	var to: Vector2 = _blink_spot(unit, t)
	b.interrupt(unit)
	unit.pos = to
	unit.prev_pos = to
	unit.vel = Vector2.ZERO
	unit.facing = atan2(t.pos.x - to.x, t.pos.y - to.y)
	unit.target = t
	unit.attack_cd = maxf(unit.attack_cd, 0.2)
	for e: BUnit in b.enemies_of(unit):
		if e.forced_target == unit:
			continue                                  # 被嘲讽的照样打她
		if e.target == unit:
			e.target = null
			e.last_target_check = -10.0
		if e.attack_target == unit and e.phase == "windup":
			b.interrupt(e)
	var n: int = maxi(1, int(floor(amount + 0.0001)))
	b.fx({"t": "blink", "unit": unit, "from": from, "to": to, "style": str(cfg.get("blink_fx", "")), "target": t, "count": n})
	var gap: float = float(cfg.get("gap", 0.08))
	for i in range(n):
		b.schedule(b.time + gap * float(i), func() -> void:
			if unit.alive and t.alive and unit.can_attack() and not unit.is_stunned():
				b.fx({"t": "blink_throw", "unit": unit, "target": t, "index": i})
				b.deliver_normal_attack(unit, t, false, {"instant": true, "released_at": b.time}))


## 瞬移落点：远程 = 以 t 为圆心、射程 0.55~0.92 倍的几圈候选点里，能站(不在墙里、不和别人重叠)、看得见 t 的位置中挑最好的——
## 射程里(看得见)的其他敌人越多越好；别比哪个敌人现在的目标离它更近(会把它吸过来)，尤其别靠近拿近战武器的；同分取离敌人更远、离自己近的。
## 近战(其他棋子拿着它) = 贴着 t 站(刚好够得着)，身边能打到的其他敌人多的优先
func _blink_spot(unit: BUnit, t: BUnit) -> Vector2:
	var reach: float = unit.get_stats().range_meters()
	var ranged: bool = unit.is_ranged() and reach >= 1.0
	var rings: Array[float] = []
	if ranged:
		for f: float in [0.55, 0.68, 0.8, 0.92]:
			rings.append(reach * f + t.radius * 0.5)
	else:
		rings.append(BattleAI.touch_reach(unit, t) - 0.04)
	var enemies: Array[BUnit] = b.enemies_of(unit)
	var allies: Array[BUnit] = b.allies_of(unit, false)
	var best: Vector2 = unit.pos
	var best_s := -1.0e9
	for r: float in rings:
		for i in range(24):
			var ang: float = TAU * float(i) / 24.0
			var p: Vector2 = t.pos + Vector2(sin(ang), cos(ang)) * r
			if b.clamp_to_arena(p, unit.radius).distance_to(p) > 0.01 or b.position_blocked(p, unit.radius, unit):
				continue
			if ranged and not b.map.has_los(p, t.pos, unit.team):
				continue
			var s := 0.0
			var nearest := 1.0e9
			for e: BUnit in enemies:
				var de: float = e.pos.distance_to(p)
				nearest = minf(nearest, de)
				if e != t and BattleAI.in_reach(unit, e, de, reach) and (not ranged or b.map.has_los(p, e.pos, unit.team)):
					s += 3.0
				if not ranged:
					continue
				# 会不会把它吸过来：它离这里比离它现在的目标(没有就是离我方最近的队友)还近
				var cur := 1.0e9
				if e.target != null and e.target.alive and e.target != unit:
					cur = e.pos.distance_to(e.target.pos)
				else:
					for a: BUnit in allies:
						cur = minf(cur, e.pos.distance_to(a.pos))
				if de < cur + 0.6:
					s -= 4.0 if e.is_ranged() else 9.0
				if not e.is_ranged() and de < e.get_stats().range_meters() + 1.6:
					s -= 6.0
			if ranged:
				s += minf(nearest, 5.0) * 0.4
			s -= p.distance_to(unit.pos) * 0.05
			if s > best_s:
				best_s = s
				best = p
	if best_s <= -1.0e8:
		best = b.find_free_position(t.pos + (unit.pos - t.pos).normalized() * rings[0], unit.radius, unit)
	return best


# ---------------------------------------------------------------- 律令(如律所令)
## 按规则表挑一种：rules 按顺序取第一条匹配的(team = 目标是施加者的队友 / 敌人；roles = 目标的定位；ap_user = 目标靠法术强度打伤害)，
## 给目标挂这条规则的状态：stat ± amount% / 层(sign 决定提升还是降低；降低的是负面状态)，【叠加 N】，可驱散，duration 秒。
## 最大生命变化时当前生命按比例跟着变(BUnit.recompute 的通用规则)
func _edict(unit: BUnit, t: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var ally: bool = t.team == unit.team
	var st: StatBlock = t.get_stats()
	var ap_user: bool = t.def.na_scaling == "ability_power" or t.def.attack_as_ap or st.ability_power > st.attack_power
	var rule: Dictionary = {}
	for r0: Variant in cfg.get("rules", []):
		var r: Dictionary = r0
		if (str(r.get("team", "ally")) == "ally") != ally:
			continue
		if r.has("roles") and not (r["roles"] as Array).has(t.def.role):
			continue
		if bool(r.get("ap_user", false)) and not ap_user:
			continue
		rule = r
		break
	if rule.is_empty():
		return
	var up: bool = float(rule.get("sign", 1)) > 0.0
	var stat: String = str(rule["stat"])
	var scfg := {"status_id": str(rule["status_id"]), "duration": float(cfg.get("duration", 7.0)),
		"max_stacks": maxi(1, kw_value(unit, ability, "stacking", 1)),
		"flags": ["buff", "dispellable"] if up else ["debuff", "dispellable"],
		"stats": {stat: {"pct": (1.0 if up else -1.0) * amount / 100.0}}}
	fx.apply_status(unit, t, scfg, o)


# ---------------------------------------------------------------- 狩胜节点
## 光荣 8 层的"本应阵亡时"：失去 lose 层，回复最大生命的 heal_pct(从 0 开始算，过量的伤害不扣)
func _status_cost_heal(unit: BUnit, t: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var sid: String = str(cfg.get("status_id", ""))
	var st: BStatus = t.get_status(sid)
	if st == null or st.stacks < int(cfg.get("min_stacks", 1)):
		return
	st.stacks -= int(cfg.get("lose", 1))
	t.mark_dirty()
	if st.stacks <= 0:
		fx.end_status(t, sid)
	else:
		b.fx({"t": "status", "unit": t, "id": sid, "base_id": sid, "stacks": st.stacks, "created": false, "flags": st.flags, "src": unit})
	t.hp = maxf(t.hp, 0.0)
	fx.heal(unit, t, t.get_stats().max_health * float(cfg.get("heal_pct", 0.25)), {"raw": true, "surface": "passive", "ability_id": ability.id})
	b.fx({"t": "glory_save", "unit": t, "stacks": st.stacks})


## 虹光飞弹：施放 1 + ⌊增幅 × 实际吟唱秒数⌋ 发魔法飞弹，每发颜色在红 / 蓝 / 绿 / 白里随机、各自全场随机锁定目标；
## 飞弹先在天上绕一会儿(launch 依次错开，flight 秒后命中，落点跟着目标)，命中时才结算：
##   红 = 物理伤害 + 【燃烧】(8 秒)；蓝 = ×1.2 的魔法伤害；绿 = 改为瞄准队友并回复生命；白 = 真实伤害。伤害 / 治疗量 = 触发数值(法强 × x)
const MISSILE_COLORS: Array[String] = ["red", "blue", "green", "white"]


func _rainbow_missiles(unit: BUnit, amount: float, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var amp: int = kw_value(unit, ability, "amplify", 0)
	var n: int = 1 + int(floorf(float(amp) * float(ctx.get("chanted", 0.0)) + 0.001))
	var gap: float = float(cfg.get("launch_gap", 0.06))
	for i in range(n):
		var col: String = MISSILE_COLORS[b.rng.randi() % MISSILE_COLORS.size()]
		var tgt: BUnit = _missile_target(unit, col)
		if tgt == null:
			continue
		var launch: float = b.time + gap * float(i)
		var flight: float = b.rng.randf_range(float(cfg.get("flight_min", 0.85)), float(cfg.get("flight_max", 1.3)))
		var mid := {"unit": unit, "target": tgt, "color": col, "amount": amount, "ability": ability, "cfg": cfg}
		b.schedule(launch + flight, Callable(self, "_missile_hit").bind(mid))
		b.fx({"t": "missile", "unit": unit, "target": tgt, "color": col, "delay": gap * float(i), "flight": flight, "index": i})


## 飞弹的目标：绿 = 随机一个活着的队友(含自己)，其余 = 随机一个活着的敌人
func _missile_target(unit: BUnit, col: String) -> BUnit:
	var pool: Array[BUnit] = b.allies_of(unit, true) if col == "green" else b.enemies_of(unit)
	if pool.is_empty():
		return null
	return pool[b.rng.randi() % pool.size()]


func _missile_hit(mid: Dictionary) -> void:
	var unit: BUnit = mid["unit"]
	var t: BUnit = mid["target"]
	var col: String = str(mid["color"])
	var cfg: Dictionary = mid["cfg"]
	var ability: AbilityDef = mid["ability"]
	var amount: float = float(mid["amount"])
	if t == null or not t.alive:
		t = _missile_target(unit, col)          # 原来的目标倒下了：飞向另一个
		if t == null:
			return
	b.fx({"t": "missile_hit", "unit": unit, "target": t, "color": col})
	var o := {"surface": "passive", "ability_id": ability.id, "cfg": {"damage_category": "skill"}, "missile": col}
	match col:
		"red":
			fx.damage(unit, t, amount, "physical", o)
			if t.alive:
				fx.apply_status(unit, t, (cfg.get("burn", {}) as Dictionary).duplicate(true), {})
		"blue":
			fx.damage(unit, t, amount * float(cfg.get("blue_mult", 1.2)), "magic", o)
		"green":
			fx.heal(unit, t, amount, {"surface": "passive", "ability_id": ability.id})
		_:
			fx.damage(unit, t, amount, "true", o)
	drain()


## 黑羽使魔：造成普攻伤害 / 持续伤害 / 技能伤害 / 法术伤害 / 物理伤害 / 真实伤害 / 治疗时，各得一种标记(同一种只算一个)；
## 集齐 need(6)种时全部消耗，召唤一只鸟(场上最多 max_birds 只；满了也照样消耗)
func _familiar_marks(unit: BUnit, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var ev: Dictionary = ctx["ev"]
	var marks: Dictionary = unit.meta.get_or_add("familiar_marks", {})
	var before: int = marks.size()
	if str(ev["timing"]) == "OnHealApplied":
		# 施放了治疗就算(对满血的队友全是溢出也算)
		if float(ev.get("value", 0.0)) + float((ev["meta"] as Dictionary).get("overheal", 0.0)) > 0.0:
			marks["heal"] = true
	else:
		var m: Dictionary = ev["meta"]
		marks[str(m.get("category", "skill"))] = true
		marks[str(m.get("kind", "physical"))] = true
	if marks.size() == before:
		return
	b.fx({"t": "familiar_marks", "unit": unit, "marks": marks.keys(), "need": int(cfg.get("need", 6))})
	if marks.size() < int(cfg.get("need", 6)):
		return
	marks.clear()
	var alive := 0
	for u0: BUnit in b.units:
		if u0.alive and u0.team == unit.team and u0.is_summon and u0.def.id == str(cfg.get("unit_id", "")):
			alive += 1
	if alive < int(cfg.get("max_birds", 5)):
		fx.summon(unit, cfg, o)


## 虹光花：从 物理普攻伤害 / 法术技能伤害 / 真实持续伤害 里随机造成一种(数值都是 amount)；真实持续伤害 = 1 秒后跳一下的独立状态
func _rainbow_spark(unit: BUnit, t: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	if t == null or not t.alive:
		return
	var pick: int = b.rng.randi() % 3
	b.fx({"t": "rainbow_spark", "unit": unit, "target": t, "kind": ["physical", "magic", "true"][pick]})
	match pick:
		0:
			var o0: Dictionary = o.duplicate()
			o0["cfg"] = {"as_normal_attack": true}
			fx.damage(unit, t, amount, "physical", o0)
		1:
			var o1: Dictionary = o.duplicate()
			o1["cfg"] = {"damage_category": "skill"}
			fx.damage(unit, t, amount, "magic", o1)
		_:
			fx.apply_status(unit, t, {"status_id": "rainbow_rot", "duration": 1.0, "independent": true, "max_stacks": 1,
				"flags": ["debuff", "dispellable"], "dot": {"kind": "true", "amount": amount, "interval": 1.0}}, {})


## 猎人笔记：吟唱结束 / 被打断时，每吟唱了 1 秒，针对目标获得 per_sec_by_star 的普攻闪避率、伤害增幅、百分比护甲穿透(不叠加，重复获得以新的为准)
func _hunter_notes(unit: BUnit, t: BUnit, ability: AbilityDef, o: Dictionary, ctx: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var per: Dictionary = cfg.get("per_sec_by_star", {})
	var each: float = float(per.get(str(mini(unit.star, 3)), per.get(mini(unit.star, 3), 0.0)))
	var secs: float = floorf(float(ctx.get("chanted", 0.0)) + 0.001)
	var v: float = each * secs
	if t == null or v <= 0.0:
		return
	fx.apply_status(unit, unit, {"status_id": str(cfg.get("status_id", "hunter_notes")), "flags": ["buff"], "stats": {},
		"meta": {"vs_target": t.uid, "dodge": minf(v, float(cfg.get("dodge_cap", 0.95))), "amp": v, "pen": minf(v, 1.0), "secs": secs}})
	b.fx({"t": "hunter_notes", "unit": unit, "target": t, "value": v, "secs": secs})


## 意外渔获：把吟唱的目标拽到面前(强制位移)，嘲讽它；攻击范围够得着它(按拽过来之后的位置)的队友，当前目标都改成它
func _fish_pull(unit: BUnit, t: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	if t == null or not t.alive or not unit.alive:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var dir: Vector2 = t.pos - unit.pos
	if dir.length() < 0.01:
		dir = Vector2(sin(unit.facing), cos(unit.facing))
	dir = dir.normalized()
	var gap: float = unit.radius + t.radius + 0.15
	var to: Vector2 = b.map.push_out(b.clamp_to_arena(unit.pos + dir * gap, t.radius), t.radius)
	var dist: float = t.pos.distance_to(to)
	var dur: float = clampf(dist / float(cfg.get("speed", 14.0)), 0.2, 0.5)
	b.interrupt(t)
	t.phase = "dash"
	t.vel = Vector2.ZERO
	t.meta["dash"] = {"from": t.pos, "to": to, "t0": b.time, "dur": dur, "quiet": true, "pulled": true}
	unit.facing = atan2(dir.x, dir.y)
	b.fx({"t": "fish_pull", "unit": unit, "target": t, "dur": dur})
	b.fx({"t": "dash_start", "unit": t, "from": t.pos, "to": to, "dur": dur, "pulled": true})
	# 嘲讽
	var td: float = float(cfg.get("taunt", 3.0))
	t.forced_target = unit
	t.forced_until = b.time + td
	t.target = unit
	b.fx({"t": "taunt", "unit": unit, "radius": 0.0, "single": t})
	# 够得着它的队友都改打它
	for a: BUnit in b.allies_of(unit, false):
		if a.alive and a != unit and a.can_attack() and BattleAI.in_reach(a, t, a.pos.distance_to(to), a.get_stats().range_meters()):
			if a.target != t:
				a.target = t
				a.last_target_check = b.time
				emit("OnTargeting", a, t, 0.0, ["targeting"], {})


## 重燃(炽照节点·不灭)：消耗目标身上某状态的全部层数，每层回复 per_stack_by_star(按施加者星级)点生命
func _status_stack_heal(unit: BUnit, t: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var sid: String = str(cfg.get("status_id", ""))
	var st: BStatus = t.get_status(sid)
	if st == null or st.stacks <= 0:
		return
	var n: int = st.stacks
	var per: Dictionary = cfg.get("per_stack_by_star", {})
	var each: float = float(per.get(str(mini(unit.star, 3)), per.get(mini(unit.star, 3), cfg.get("per_stack", 0.0))))
	fx.end_status(t, sid)
	fx.heal(unit, t, each * float(n), {"raw": true, "surface": "passive", "ability_id": ability.id})
	b.fx({"t": "stack_heal", "unit": t, "id": sid, "stacks": n})


# ---------------------------------------------------------------- 护理节点
## 广义治疗：这一下本应对友方 t 造成的普攻伤害，先算出最终伤害值(Effects.preview_damage：只算暴击、增伤、易伤这些提升伤害的，护甲/魔抗等减伤不算)，
## 再按施加者的 na_ally_heal_pct 换成治疗(治疗量加成照常生效)。是一次真正的治疗：发 OnHealApplied(一对一看护监听它)
func _na_heal(unit: BUnit, t: BUnit, amount: float, kind: String, ability: AbilityDef, o: Dictionary) -> void:
	var res: Dictionary = fx.preview_damage(unit, t, amount, kind, o)
	var h: float = float(res["amount"]) * unit.get_stats().na_ally_heal_pct
	fx.heal(unit, t, h, {"surface": str(o.get("surface", "normal_attack")), "ability_id": ability.id, "equip_id": o.get("equip_id", ""),
		"splash": bool(o.get("splash", false)), "crit": bool(res["crit"]), "na_heal": true})


# ---------------------------------------------------------------- 冲锋落地
## 冲锋斩落地：对身边一圈至多 N 个敌人(最近的优先)造成冲锋时定好的伤害，再发出 OnDashEnd(供"冲锋后嘲讽"之类响应)
## 引爆(愤怒的余烬·解放)：目标身上剩余时间最长的那一个状态实例，把它剩下的持续伤害一次结清(× 触发数值 amount)，然后结束它
func _detonate(unit: BUnit, t: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	var sid: String = str(ability.effect_config.get("status_id", "burning"))
	var best: BStatus = null
	for st: BStatus in t.status_instances(sid):
		if st.expires_at >= 0.0 and (best == null or st.expires_at > best.expires_at):
			best = st
	if best == null:
		return
	var remain: float = maxf(0.0, best.expires_at - b.time)
	var per_sec: float = float(best.dot.get("amount", 0.0)) / maxf(0.05, float(best.dot.get("interval", 1.0))) * float(best.stacks)
	var dmg: float = per_sec * remain * amount
	fx.end_status(t, best.id)
	b.fx({"t": "detonate", "unit": t, "src": unit, "status": sid, "amount": dmg})
	var od: Dictionary = o.duplicate()
	od["can_crit"] = false
	fx.damage(unit, t, dmg, str(ability.effect_config.get("damage_kind", "magic")), od)


## 吞掉(怠惰的余烬·引火)：移除目标身上某状态的全部实例；每吞掉一个，自己多叠一层 gain 状态
func _consume(unit: BUnit, t: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	var sid: String = str(ability.effect_config.get("status_id", "burning"))
	var list: Array[BStatus] = t.status_instances(sid)
	if list.is_empty():
		return
	for st: BStatus in list:
		fx.end_status(t, st.id)
	b.fx({"t": "consume", "unit": t, "src": unit, "status": sid, "count": list.size(), "style": str(ability.effect_config.get("consume_fx", ""))})
	var gain: Dictionary = (ability.effect_config.get("gain", {}) as Dictionary).duplicate(true)
	if gain.is_empty():
		return
	gain["add_stacks"] = list.size()
	gain["max_stacks"] = maxi(1, kw_value(unit, ability, "stacking", int(gain.get("max_stacks", 1))))
	fx.apply_status(unit, unit, gain, o)


## 缠绕(色欲的余烬·色欲的热意)：自己和目标互相缠住——双方都带上这个状态(定身、不可驱散)，强制以彼此为索敌目标，一直维持到其中一方倒下
func _entangle(unit: BUnit, t: BUnit, ability: AbilityDef) -> void:
	if t == null or not t.alive or t == unit:
		return
	var sid: String = str(ability.effect_config.get("status_id", "lust_bind"))
	for pair: Array in [[unit, t], [t, unit]]:
		var a: BUnit = pair[0]
		var other: BUnit = pair[1]
		var st: BStatus = a.get_status(sid)
		var fresh: bool = st == null
		if fresh:
			st = fx.apply_status(null, a, {"status_id": sid, "duration": 0.0, "max_stacks": 1,
				"flags": (ability.effect_config.get("flags", ["rooted", "no_dispel"]) as Array).duplicate()})
			if st == null:
				continue
		var partners: Array = st.meta.get("partners", [])
		if not partners.has(other.uid):
			partners.append(other.uid)
		st.meta["partners"] = partners
		if a.forced_target == null or not a.forced_target.alive:
			a.forced_target = other
			a.forced_until = 1.0e9
			a.target = other
		if fresh:
			b.fx({"t": "entangle", "unit": a, "other": other})


func dash_arrive(u: BUnit, d: Dictionary) -> void:
	# 投掷后的位移落地：拿回武器；投掷中又攒到一次投掷(光荣满层再获得层数)就接着投下一个狩猎对象
	if bool(d.get("after_throw", false)) and u.alive:
		b.fx({"t": "weapon_return", "unit": u})
		var q: Dictionary = u.meta.get("queued_throw", {})
		if not q.is_empty():
			u.meta.erase("queued_throw")
			var nt: BUnit = b.hunt_target_of(u)
			if nt != null:
				fx.weapon_throw(u, nt, float(q["amount"]), q["ability"] as AbilityDef, q["o"] as Dictionary)
	if not u.alive or bool(d.get("quiet", false)):
		return
	# 画上句点(止息节点)：落地立刻普攻 + 强制索敌 + 标定
	if d.has("lunge"):
		_lunge_arrive(u, d)
		return
	# 护送冲刺(舞与歌)：落地后给同伴加减伤、同伴嘲讽大范围内的敌人
	if d.has("escort"):
		var pt: BUnit = d.get("escort") as BUnit
		if pt != null and pt.alive:
			var dr: float = float(d.get("escort_dr", 0.0))
			if dr > 0.0:
				# (damage_taken_pct 正数 = 伤害减免；以前写成 -dr，护星节点反而多受伤害——2026-10-07 修正)
				fx.apply_status(u, pt, {"status_id": str(d.get("escort_status", "idol_guard")), "flags": ["buff"],
					"stats": {"damage_taken_pct": {"flat": dr}}})
			if float(d.get("taunt_radius", 0.0)) > 0.0:
				fx.taunt(pt, float(d["taunt_radius"]), float(d.get("taunt_duration", 3.0)))
		b.fx({"t": "escort_end", "unit": u, "partner": pt})
		emit("OnDashEnd", u, null, 0.0, ["dash_end"], {})
		return
	var rad: float = float(d["radius"])
	var near: Array = []
	for e: BUnit in b.enemies_of(u):
		var dd: float = e.pos.distance_to(u.pos)
		if dd <= rad + e.radius:
			near.append([dd, e])
	near.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
	var hit := 0
	for pr: Array in near.slice(0, int(d["n"])):
		fx.damage(u, pr[1] as BUnit, float(d["amount"]), str(d.get("kind", "physical")), d["o"])
		hit += 1
	b.fx({"t": "dash_strike", "unit": u, "radius": rad, "hits": hit})
	emit("OnDashEnd", u, null, float(hit), ["dash_end"], {})


# ---------------------------------------------------------------- 普攻
## 普攻 = 单位自有的触发器 + 能力(默认物理伤害；可被单位的自定义普攻替换)。
## 同样经过管线：Perform(结算) → Hit / HitBy(供被动、装备、羁绊监听)。
## opts(出手时由攻击状态机给出)：chant_scale 拉弓倍率 / aim_point 落点(defender = null 时 = 打地板) /
##   attack_variant 招式("multi" = 群攻招式) / released_at 出手时刻(追击副本按它对齐另一只手)
## 变天·起雾(导向节点，蓝之章)：敌我双方拿远程武器(法器除外)的普攻，被闪避的额外几率
func fog_dodge(attacker: BUnit) -> float:
	if b.weather != "fog" or not attacker.is_ranged() or attacker.weapon_class() == "focus":
		return 0.0
	return float(b.weather_params.get("dodge", 0.0))


func normal_attack(attacker: BUnit, defender: BUnit, is_copy: bool = false, opts: Dictionary = {}) -> void:
	if not attacker.alive or not attacker.can_attack():
		return                                     # 空手：没有普攻载荷，也不产生命中事件
	if defender == null and not (opts.get("aim_point") is Vector2):
		return
	if defender != null and not defender.alive:
		return
	defender = _oath_redirect(attacker, defender)
	var was_draining: bool = draining
	draining = true                                # 结算期间产生的后续事件先入队，保证 Hit 事件排在伤害事件之后
	var meta: Dictionary = {"is_copy": is_copy, "current_attack_target": defender, "dealt": 0.0}
	for k: String in ["chant_scale", "aim_point", "attack_variant", "released_at", "breath_dir", "missed", "na_scale", "instant", "copies_sent", "na_amp_bonus",
			"kick_mult", "run_dist", "free", "cone_dir", "no_splash", "dmg_cap", "chain_hop"]:
		if opts.has(k):
			meta[k] = opts[k]
	var free: bool = bool(meta.get("free", false))
	# 针对性闪避(猎人笔记)：被笔记盯上的那个敌人打过来的普攻，有几率被闪开(不造成伤害、不算命中)；加上普攻闪避率(战场感知)
	if defender != null and not bool(meta.get("missed", false)):
		var dg: float = minf(0.95, float(Effects.vs_bonus(defender, attacker).get("dodge", 0.0)) + maxf(0.0, defender.get_stats().na_dodge) + fog_dodge(attacker))
		if dg > 0.0 and b.roll_good(defender) < dg:
			meta["missed"] = true
			meta["dodged"] = true
	# 强化普攻(大口径子弹)：还有次数 → 必定暴击 + 基础伤害加成，用掉一次；用完了 → 必定不暴击、伤害打折
	for est: BStatus in attacker.statuses.values():
		if free:
			break                                      # 免费弹道：不消耗任何资源(强化普攻的次数)
		if est.meta.has("empower"):
			var emp: Dictionary = est.meta["empower"]
			if int(emp["left"]) > 0:
				meta["na_bonus_raw"] = float(emp["bonus"])
				meta["na_force_crit"] = true
				emp["left"] = int(emp["left"]) - 1
				b.fx({"t": "empower_shot", "unit": attacker, "left": int(emp["left"]), "count": int(emp.get("count", 6))})
			else:
				meta["na_no_crit"] = true
				meta["na_after_mult"] = float(emp.get("after_mult", 0.7))
			break
	if attacker.meta.has("first_hit_bonus") and not is_copy and not free:
		meta["na_bonus_raw"] = float(meta.get("na_bonus_raw", 0.0)) + float(attacker.meta["first_hit_bonus"])   # 魔典：这只幽灵首次攻击的额外伤害
		attacker.meta.erase("first_hit_bonus")
	emit_now("OnNormalAttackPerform", attacker, defender, 0.0, ["normal_attack"], meta)
	if attacker.has_flag("spectral") and not bool(attacker.meta.get("spent", false)) and not free:
		spectral_spent(attacker)
	var dealt: float = float(meta.get("dealt", 0.0))
	if free:
		_free_shot_landed(attacker, defender, opts, bool(meta.get("missed", false)))
		draining = was_draining
		if not was_draining:
			drain()
		return
	if bool(meta.get("dodged", false)):
		b.fx({"t": "dodge", "unit": defender, "attacker": attacker})
		queue.append(make_event("OnDodge", defender, attacker, 0.0, ["dodge"], {"attacker": attacker}))
	elif bool(meta.get("missed", false)):
		b.fx({"t": "miss", "unit": attacker, "target": defender})
	if defender != null and not bool(meta.get("missed", false)):
		var hm: Dictionary = {"is_copy": is_copy, "current_attack_target": defender}
		if attacker.hits_since_reload >= 0:
			attacker.hits_since_reload += 1
			hm["hits_since_reload"] = attacker.hits_since_reload      # 1 = 装弹后的第一次命中
		for k2: String in ["chant_scale", "released_at", "kick_mult", "run_dist", "attack_variant"]:
			if meta.has(k2):
				hm[k2] = meta[k2]
		queue.append(make_event("OnNormalAttackHit", attacker, defender, dealt, ["normal_attack"], hm))
		queue.append(make_event("OnHitByNormalAttack", defender, attacker, dealt, ["normal_attack"], {"is_copy": is_copy, "attacker": attacker}))
		# 召唤物的普攻命中：也告诉召唤者(使魔之喙)
		if attacker.is_summon:
			var smn: BUnit = attacker.meta.get("summoner") as BUnit
			if smn != null and smn.alive:
				queue.append(make_event("OnSummonNormalAttackHit", smn, defender, dealt, ["summon_hit"], {"summon": attacker, "is_copy": is_copy}))
	draining = was_draining
	if not was_draining:
		drain()


# ---------------------------------------------------------------- 守誓节点 / 黑剑
## 黑剑：给触发目标【暗色誓约】，再提升触发数值 n% 的生命上限；目标是(被视为)召唤物时，再给【光色誓约】并再提升一次
func _oath_bestow(unit: BUnit, t: BUnit, amount: float, ability: AbilityDef) -> void:
	var cfg: Dictionary = ability.effect_config
	var pct: float = float(cfg.get("hp_pct", 0.5))
	fx.apply_status(unit, t, (cfg.get("dark", {}) as Dictionary).duplicate(true))
	fx.max_health_up(unit, t, amount * pct)
	if t.is_summon or t.summoner() != null:
		fx.apply_status(unit, t, (cfg.get("light", {}) as Dictionary).duplicate(true))
		fx.max_health_up(unit, t, amount * pct)


## 誓绶身：绑定最近的稀有度 5 队友，视为它的召唤物，额外获得它的星级；它承受的普攻都转到自己身上
func _oath_bind(unit: BUnit) -> void:
	if unit.summoner() != null:
		return
	var best: BUnit = null
	for a: BUnit in b.units:
		if a.alive and a != unit and a.team == unit.team and not a.is_summon and a.def.cost >= 5:
			if best == null or a.pos.distance_to(unit.pos) < best.pos.distance_to(unit.pos):
				best = a
	if best == null:
		return
	unit.meta["summoner"] = best
	unit.meta["summoners"] = [best]
	(best.meta.get_or_add("oath_guards", []) as Array).append(unit)
	var ratio: float = unit.hp_ratio()
	unit.star = mini(GC.MAX_SUMMON_STAR, unit.star + best.star)
	unit.base = unit.def.stats_for_star(unit.star)
	unit.mark_dirty()
	unit.hp = unit.get_stats().max_health * ratio
	b.fx({"t": "oath_bind", "unit": unit, "summoner": best, "star": unit.star})


## 普攻打向一个有守誓节点绑定的单位：改打守誓节点(无视距离；是一次真正的普攻事件，命中类触发器在守誓节点身上算)
func _oath_redirect(attacker: BUnit, defender: BUnit) -> BUnit:
	if defender == null or not defender.meta.has("oath_guards"):
		return defender
	for g: Variant in defender.meta["oath_guards"]:
		var gu: BUnit = g as BUnit
		if gu != null and gu.alive and gu.team != attacker.team:
			if gu != defender:
				b.fx({"t": "oath_redirect", "unit": gu, "from": defender, "attacker": attacker})
			return gu
	return defender


## 誓血仇：队友被击杀时，把凶手设为优先目标(凶手还活着、而且现在没有别的仇人时)
func _note_vendetta(unit: BUnit, ev: Dictionary) -> void:
	var killer: BUnit = ev.get("target") as BUnit
	if killer == null or not killer.alive or killer.team == unit.team:
		return
	var wants := false
	for entry: Dictionary in unit.all_ability_entries():
		if bool((entry["ability"] as AbilityDef).effect_config.get("prefer_ally_killer", false)):
			wants = true
	if not wants:
		return
	var cur: BUnit = unit.meta.get("vendetta", null) as BUnit if unit.meta.get("vendetta", null) is BUnit else null
	if cur != null and cur.alive:
		return
	unit.meta["vendetta"] = killer
	unit.forced_target = killer
	unit.forced_until = 1.0e9
	b.fx({"t": "vendetta", "unit": unit, "target": killer})


# ---------------------------------------------------------------- 觉醒
func _evaluate_awakening(unit: BUnit, ev: Dictionary) -> void:
	if ev["timing"] == "OnAllyUnitDied":
		_note_vendetta(unit, ev)
	# 状态上的觉醒任务(黑剑的暗色誓约 / 光色誓约)：完成后状态生效，也算"自身完成了觉醒任务"
	for sid: Variant in unit.statuses.keys():
		var st: BStatus = unit.statuses[sid]
		if not st.meta.has("awaken") or bool(st.meta.get("awakened", false)):
			continue
		var aw: Dictionary = st.meta["awaken"]
		var skey: String = str(aw.get("key", sid))
		var sdone := true
		for task2: Variant in aw.get("tasks", []):
			if not _task_done(unit, task2 as Dictionary, ev, skey):
				sdone = false
		if sdone:
			st.meta["awakened"] = true
			for k: String in (aw.get("stats", {}) as Dictionary).keys():
				var e: Dictionary = aw["stats"][k]
				if e.has("flat"):
					st.flat_per_stack[k] = float(e["flat"])
				if e.has("pct"):
					st.pct_per_stack[k] = float(e["pct"])
			unit.mark_dirty()
			b.fx({"t": "awakened", "unit": unit, "key": skey, "status": str(sid)})
			queue.append(make_event("OnAwakeningCompleted", unit, null, 1.0, ["awakening", "equipment_payload"], {"awakening_key": skey}))
	for entry: Dictionary in unit.all_ability_entries():
		var ab: AbilityDef = entry["ability"]
		if not ab.has_keyword("awakening"):
			continue
		var key: String = str(ab.cfg("awakening_key", ab.id))
		if unit.awakened.get(key, false):
			continue
		var done := true
		for task: Variant in ab.cfg("awakening_tasks", []):
			if not _task_done(unit, task as Dictionary, ev, key):
				done = false
		if done:
			unit.awakened[key] = true
			b.fx({"t": "awakened", "unit": unit, "key": key})
			queue.append(make_event("OnAwakeningCompleted", unit, null, 1.0, ["awakening", "equipment_payload"], {"awakening_key": key}))


func _task_done(unit: BUnit, task: Dictionary, ev: Dictionary, key: String) -> bool:
	var pk: String = "%s:%s" % [key, str(task.get("type", ""))]
	if unit.awakening_progress.get(pk, false):
		return true
	var ok := false
	match str(task.get("type", "")):
		"ally_death":
			ok = ev["timing"] == "OnAllyUnitDied"
		"own_kills_at_least":
			ok = unit.st_kills >= int(task.get("count", 1))
		"health_below":
			ok = unit.hp_ratio() <= float(task.get("ratio", 0.5))
		"battle_time_at_least":
			ok = b.time >= float(task.get("seconds", 10.0))
		"team_has_cost":
			# 队伍里有稀有度(费用)≥ cost 的棋子(不算召唤物)
			for a: BUnit in b.units:
				if a.alive and a.team == unit.team and not a.is_summon and a.def.cost >= int(task.get("cost", 5)):
					ok = true
		"kill_ally_killer":
			# 击杀一个本场击杀过我方单位的敌人
			if ev["timing"] == "OnUnitKilled" and ev.get("target") is BUnit:
				ok = bool(((ev["target"] as BUnit).meta.get("killed_team", {}) as Dictionary).get(unit.team, false))
		"enemies_at_most":
			# 场上(活着的)敌人不超过 count 个(杀：场上仅剩一个敌人)
			ok = b.enemies_of(unit).size() <= int(task.get("count", 1))
		"team_charges_at_least":
			# 我方(活着的)所有【充能】效果当前的充能加起来 ≥ count(少女真心：27)
			ok = team_charges(unit.team) >= int(task.get("count", 27))
		"na_taken_at_least":
			# 承受 count 次普攻(从这个觉醒任务出现时开始数)
			if ev["timing"] == "OnHitByNormalAttack":
				var ck: String = "%s:na_taken" % key
				unit.awakening_progress[ck] = int(unit.awakening_progress.get(ck, 0)) + 1
				ok = int(unit.awakening_progress[ck]) >= int(task.get("count", 20))
	if ok:
		unit.awakening_progress[pk] = true
	return ok
