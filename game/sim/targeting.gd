class_name Targeting
extends RefCounted
## 目标解析：触发器的 target_rule 给出候选序列(有序数组)，能力的 [群攻 n] 决定取前几个。
## 没有 [群攻] 的能力只会取第一个目标(即使触发器给出了全体)。

static func resolve(b: Battle, ev: Dictionary, trig: TriggerDef, ability: AbilityDef, unit: BUnit) -> Array[BUnit]:
	var cands: Array[BUnit] = _candidates(b, ev, trig, unit)
	# 过滤：死亡
	var alive: Array[BUnit] = []
	# 战斗结束时：倒下的自己也算(永恒成长之类"每场战斗结束后"的结算)
	var end_self: bool = str(ev.get("timing", "")) in ["OnBattleEnd", "OnTeamWiped", "OnUnitDied"]
	# allow_dead：这个触发器的目标可以是已阵亡的(执剑节点·与你，再度飞翔：攻击力最高的已阵亡队友)
	var dead_ok: bool = bool(trig.target_filter.get("allow_dead", false))
	for c: BUnit in cands:
		if c != null and (c.alive or (end_self and c == unit) or dead_ok):
			if trig.target_filter.has("has_status") and c.status_count(str(trig.target_filter["has_status"])) <= 0:
				continue
			if trig.target_filter.has("missing_status") and c.status_count(str(trig.target_filter["missing_status"])) > 0:
				continue
			# no_harm_allies：这个触发器的目标可能是队友(艺术性批判 = 演奏对象)——会伤害人的能力(伤害 / 负面状态，双模的除外)不打队友
			if bool(trig.target_filter.get("no_harm_allies", false)) and c.team == unit.team and ability != null and Pipeline.harmful(ability):
				continue
			alive.append(c)
	if trig.team_filter == "any" and unit.has_flag("enemies_only"):
		var only: Array[BUnit] = []
		for c2: BUnit in alive:
			if c2.team != unit.team or c2 == unit:
				only.append(c2)
		alive = only                                   # 黄金的指引："敌我不分"改为"仅限敌人"
	var limit := 1
	if ability != null and ability.has_keyword("multi_attack"):
		limit = maxi(1, Pipeline.kw_value(unit, ability, "multi_attack", 1))
	if ability != null and bool(ability.effect_config.get("all_targets", false)):
		limit = alive.size()                       # "所有队友获得…"这类全体效果：不受[群攻]限制
	if trig.target_rule == "weapon_attack" and str((ev.get("meta", {}) as Dictionary).get("attack_variant", "")) == "breath":
		limit = alive.size()                       # 龙息：射线上的所有敌人都吃这一下(和[群攻]无关)
	if trig.target_rule == "weapon_attack" and str((ev.get("meta", {}) as Dictionary).get("attack_variant", "")) == "cone":
		limit = cone_limit(unit)                   # 花蕊的光刃：锥形里最多【群攻 N】个(N = 再绽之花的群攻数)
	if trig.target_rule == "weapon_attack" and float((ev.get("meta", {}) as Dictionary).get("chant_scale", 1.0)) >= 1.999:
		limit += int(round(unit.get_stats().full_draw_extra_targets))     # 至远的弓弦：拉满弦的普攻额外的目标
	if trig.max_targets > 0:
		limit = mini(limit, trig.max_targets)
	if alive.size() > limit:
		alive = alive.slice(0, limit)
	return alive


static func _candidates(b: Battle, ev: Dictionary, trig: TriggerDef, unit: BUnit) -> Array[BUnit]:
	var out: Array[BUnit] = []
	var rule: String = trig.target_rule
	match rule:
		"self":
			out.append(unit)
		"current_attack_target":
			var t: Variant = (ev.get("meta", {}) as Dictionary).get("current_attack_target", null)
			if t is BUnit:
				out.append(t as BUnit)
			elif unit.target != null and unit.target.alive:
				out.append(unit.target)
			elif ev.get("target") is BUnit:
				out.append(ev["target"] as BUnit)
		"weapon_attack":
			# 普攻：当前攻击目标；打出"群攻招式"时再按武器的出招形状加上别的敌人(直线贯穿 / 射程内)，[群攻 N] 决定最多取几个。
			# 打地板(meta 里有落点、没有目标)时没有直接目标
			var meta: Dictionary = ev.get("meta", {})
			var t0: BUnit = null
			if meta.has("current_attack_target"):
				t0 = meta["current_attack_target"] as BUnit
			elif unit.target != null and unit.target.alive:
				t0 = unit.target
			elif ev.get("target") is BUnit:
				t0 = ev["target"] as BUnit
			if t0 != null:
				out.append(t0)
				# 拉满弦的普攻额外选几个目标(至远的弓弦)：射向队友的金矢 = 再挑几个该补充能的队友；射向敌人 = 离目标最近的几个敌人
				var fx_n: int = int(round(unit.get_stats().full_draw_extra_targets))
				if fx_n > 0 and float(meta.get("chant_scale", 1.0)) >= 1.999:
					var picked: Array = [t0]
					for k3 in range(fx_n):
						var ex: BUnit = null
						if t0.team == unit.team:
							ex = b.pipeline.golden_target(unit, picked)
						else:
							var ebd := 1.0e9
							for e3: BUnit in b.enemies_of(unit):
								if not picked.has(e3) and t0.pos.distance_to(e3.pos) < ebd:
									ebd = t0.pos.distance_to(e3.pos)
									ex = e3
						if ex == null:
							break
						picked.append(ex)
						out.append(ex)
				if str(meta.get("attack_variant", "")) == "multi":
					out.append_array(multi_extra(b, unit, t0))
				elif str(meta.get("attack_variant", "")) == "cone" and meta.get("cone_dir") is Vector2:
					# 花蕊的光刃 / 光炮：锥形里的所有敌人(近的优先)
					for ec: BUnit in cone_targets(b, unit, meta["cone_dir"] as Vector2, unit.cone_cfg()):
						if ec != t0:
							out.append(ec)
				elif str(meta.get("attack_variant", "")) == "breath" and meta.get("breath_dir") is Vector2:
					# 龙息：射线上的所有敌人
					for e: BUnit in breath_targets(b, unit, meta["breath_dir"] as Vector2, unit.breath_cfg()):
						if e != t0:
							out.append(e)
		"event_target":
			if ev.get("target") is BUnit:
				out.append(ev["target"] as BUnit)
		"enemies_in_splash":
			# 自己被动【溅射】范围内的敌人(星旅节点：渡星而来的范围 = 外神之貌 / 真实形态的范围)，近的优先
			var rad_s: float = b.pipeline.passive_splash_radius(unit)
			var keyed_s: Array = []
			for es: BUnit in b.enemies_of(unit):
				var ds: float = unit.pos.distance_to(es.pos)
				if ds <= rad_s + es.radius:
					keyed_s.append([ds, es])
			keyed_s.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
			for ks: Array in keyed_s:
				out.append(ks[1] as BUnit)
		"nearest_enemy_to_dead":
			# 离刚阵亡的那个单位最近的敌人(遗愿)
			var dd: BUnit = (ev.get("meta", {}) as Dictionary).get("dead") as BUnit
			var dpos: Vector2 = dd.pos if dd != null else unit.pos
			var best: BUnit = null
			var bd := 1.0e9
			for e: BUnit in b.enemies_of(unit):
				if dpos.distance_to(e.pos) < bd:
					bd = dpos.distance_to(e.pos)
					best = e
			if best != null:
				out.append(best)
		"others_in_splash":
			# 自己被动【溅射】范围内的所有其他人(不分敌我；少女幻终)；有黄金的指引就只算敌人
			var rad_o: float = b.pipeline.passive_splash_radius(unit)
			var eo: bool = unit.has_flag("enemies_only")
			for uo: BUnit in b.units:
				if uo.alive and uo != unit and not bool(uo.meta.get("dropping", false)) and not uo.has_flag("untargetable") and not (eo and uo.team == unit.team) \
						and unit.pos.distance_to(uo.pos) <= rad_o + uo.radius:
					out.append(uo)
		"taunted_by_self":
			# 正被自己嘲讽着的敌人(外神之貌：每秒驱散它们一个状态)
			for et: BUnit in b.enemies_of(unit):
				if et.forced_target == unit and b.time < et.forced_until:
					out.append(et)
		"enemies_in_reach":
			# 自己攻击范围内、打得到(远程要看得见：不被高墙 / 卡车挡住)的敌人，近的优先(清洁世界)
			var reach: float = unit.get_stats().range_meters()
			var keyed: Array = []
			for e: BUnit in b.enemies_of(unit):
				var de: float = unit.pos.distance_to(e.pos)
				if BattleAI.in_reach(unit, e, de, reach) and b.ai.can_hit(unit, e):
					keyed.append([de, e])
			keyed.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
			for kk: Array in keyed:
				out.append(kk[1] as BUnit)
		"enemies_in_sight":
			# 全场不被掩体(高墙 / 卡车)挡住视线的敌人，不管射程，近的优先(清洁世界·2026-10-07 改)
			var keyed2: Array = []
			for e2: BUnit in b.enemies_of(unit):
				if b.map.has_los(unit.pos, e2.pos, unit.team):
					keyed2.append([unit.pos.distance_to(e2.pos), e2])
			keyed2.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
			for kk2: Array in keyed2:
				out.append(kk2[1] as BUnit)
		"event_source":
			if ev.get("source") is BUnit:
				out.append(ev["source"] as BUnit)
		"summon_center":
			# 以"周围人数最多的召唤物队友"为中心，半径内所有人(不分敌我、不含自己)，中心本人最优先；
			# 没有召唤物队友就用非召唤物队友(ev.meta.center_no_summon = true，触发数值另行减少)
			var rad3: float = trig.target_radius if trig.target_radius > 0.0 else 6.0
			var center: BUnit = _busiest_ally(b, unit, rad3, true)
			var no_summon := false
			if center == null:
				center = _busiest_ally(b, unit, rad3, false)
				no_summon = true
			(ev["meta"] as Dictionary)["center_no_summon"] = no_summon
			if center == null:
				return out
			out.append(center)
			var ring: Array = []
			for u6: BUnit in b.units:
				if u6.alive and u6 != center and u6 != unit and u6.pos.distance_to(center.pos) <= rad3 + u6.radius:
					ring.append([u6.pos.distance_to(center.pos), u6])
			ring.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
			for r6: Array in ring:
				out.append(r6[1] as BUnit)
			return out
		"ally_cleanse_priority":
			# 一个队友(不含自己)：身上可驱散的负面状态最多的优先，其次当前生命最低的(清心符)
			var keyed: Array = []
			for a0: BUnit in b.units:
				if a0.alive and a0.team == unit.team and a0 != unit:
					keyed.append([b.pipeline.fx.dispellable(a0, "debuff").size(), a0.hp, a0])
			keyed.sort_custom(func(x: Array, y: Array) -> bool: return int(x[0]) > int(y[0]) or (int(x[0]) == int(y[0]) and float(x[1]) < float(y[1])))
			for k0: Array in keyed:
				out.append(k0[2] as BUnit)
			return out
		"blood_circle":
			# 血嗜节点·也是我等的至亲的故事：一个半径 r 米的圆(圆心 = 他正在打的敌人，没有就挑最近的敌人)里的敌人，离圆心近的在前
			var ctr: BUnit = unit.target if unit.target != null and unit.target.alive and unit.target.team != unit.team else null
			if ctr == null:
				var cd := 1.0e9
				for e0: BUnit in b.enemies_of(unit):
					if e0.pos.distance_to(unit.pos) < cd:
						cd = e0.pos.distance_to(unit.pos)
						ctr = e0
			if ctr != null:
				var rr: float = trig.target_radius if trig.target_radius > 0.0 else 5.0
				var inside: Array = []
				for e1: BUnit in b.enemies_of(unit):
					var dd: float = e1.pos.distance_to(ctr.pos)
					if dd <= rr + e1.radius:
						inside.append([dd, e1])
				inside.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
				for it: Array in inside:
					out.append(it[1] as BUnit)
		"ranged_threat":
			# 踏影节点·逆光：远程敌人里威胁最高的(预估输出 (攻击力 × 普攻倍率 + 法强) / 攻击间隔)排在最前
			var rk: Array = []
			for re: BUnit in b.enemies_of(unit):
				if not re.is_ranged() or not re.can_attack():
					continue
				var rst: StatBlock = re.get_stats()
				var rkv: float = (rst.attack_power * float(re.wclass().get("na_mult", 1.0)) + rst.ability_power) / maxf(0.2, rst.attack_interval())
				rk.append([rkv, re])
			rk.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) > float(y[0]))
			for ri: Array in rk:
				out.append(ri[1] as BUnit)
		"melee_near_support":
			# 止息节点·掩护支援：离我方攻击力最高的远程友军 radius 米以内的近战敌人(离那个友军近的在前；已经是她目标的不算)
			var sup: BUnit = b.pipeline.support_shooter(unit)
			if sup != null:
				var mn: Array = []
				for me: BUnit in b.enemies_of(unit):
					if me == unit.target or me.is_ranged() or not me.can_attack():
						continue
					var md: float = me.pos.distance_to(sup.pos)
					if md <= trig.target_radius:
						mn.append([md, me])
				mn.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
				for mi: Array in mn:
					out.append(mi[1] as BUnit)
		"light_beam_area":
			# 灭罪节点·她必尽灭邪恶：光束溅射范围(随照亮长夜增长)里的敌人，离光束中心近的在前
			var lbm: Dictionary = unit.meta.get("light_beam", {})
			if not lbm.is_empty():
				var lbc: Vector2 = lbm["pos"]
				var lbr: float = float(lbm.get("rad", 0.0))
				var lbin: Array = []
				for le: BUnit in b.enemies_of(unit):
					var ld: float = le.pos.distance_to(lbc)
					if ld <= lbr + le.radius:
						lbin.append([ld, le])
				lbin.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
				for li: Array in lbin:
					out.append(li[1] as BUnit)
		"performance_pick":
			# 演奏(心音节点·纤心的乐奏)：开始吟唱时现挑这一段演奏的对象和效果(Pipeline.perform_pick)
			var pk: Dictionary = b.pipeline.perform_pick(unit)
			if not pk.is_empty():
				out.append(pk["target"] as BUnit)
		"highest_threat":
			# 追猎节点·猎人笔记：本场威胁最高的敌人——有首领锁首领，有精英锁精英，否则按预估输出(攻击力 × 普攻倍率 + 法术强度)/ 攻击间隔
			# 最高的(一样时取近的)。选定后整场记住(unit.meta.threat_mark)，它倒下了才重新选
			var tm: BUnit = unit.meta.get("threat_mark") as BUnit
			if tm == null or not tm.alive or b.ai.shadow_hidden(unit, tm):
				tm = threat_pick(b, unit)
				unit.meta["threat_mark"] = tm
			if tm != null:
				out.append(tm)
		"hunt_target":
			# 狩胜节点的狩猎对象(同一队共用；没有就现选)
			var ht: BUnit = b.hunt_target_of(unit)
			if ht != null:
				out.append(ht)
		"target_or_nearest_enemy":
			# 当前目标(活着的敌人)；没有就最近的敌人(执剑节点·勇者，圣剑：开战那一刻还没有目标)
			var tg0: BUnit = unit.target
			if tg0 == null or not tg0.alive or tg0.team == unit.team or not b.enemies_of(unit).has(tg0):
				tg0 = null
				var bd0 := 1.0e9
				for e0: BUnit in b.enemies_of(unit):
					var d0: float = unit.pos.distance_to(e0.pos)
					if d0 < bd0:
						bd0 = d0
						tg0 = e0
			if tg0 != null:
				out.append(tg0)
		"self_and_top_dead_ally":
			# 自己 + 攻击力最高的已阵亡队友(召唤物不算)；没有阵亡的队友就只有自己(执剑节点·与你，再度飞翔；触发器要带 target_filter.allow_dead)
			out.append(unit)
			var top: BUnit = null
			for du: BUnit in b.units:
				if du.alive or du == unit or du.team != unit.team or du.is_summon:
					continue
				if top == null or du.get_stats().attack_power > top.get_stats().attack_power:
					top = du
			if top != null:
				out.append(top)
		"around_current_target":
			# 以自己当前的目标为圆心、target_radius 米内的单位(team_filter；奇兴节点的触发器)；没有目标 = 离自己最近的敌人为圆心
			var ct: BUnit = unit.attack_target if unit.attack_target != null and unit.attack_target.alive else unit.target
			if ct == null or not ct.alive:
				var bd: float = INF
				for e9: BUnit in b.enemies_of(unit):
					if e9.pos.distance_to(unit.pos) < bd:
						bd = e9.pos.distance_to(unit.pos)
						ct = e9
			if ct != null:
				var rad9: float = trig.target_radius if trig.target_radius > 0.0 else 2.0
				var keyed9: Array = []
				for u9: BUnit in b.units:
					if not u9.alive:
						continue
					if trig.team_filter == "enemy" and u9.team == unit.team:
						continue
					if trig.team_filter == "ally" and u9.team != unit.team:
						continue
					var d9: float = u9.pos.distance_to(ct.pos)
					if d9 <= rad9 + u9.radius:
						keyed9.append([d9, u9])
				keyed9.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
				for k9: Array in keyed9:
					out.append(k9[1] as BUnit)
		"dead_ally":
			# 一个已阵亡的友方单位：非召唤物优先，同类里最近倒下的优先(同一帧倒下的取后倒下的；心连节点·奇迹；触发器要带 target_filter.allow_dead)
			var best_d: BUnit = null
			for dd: BUnit in b.units:
				if dd.alive or dd.team != unit.team:
					continue
				if best_d == null or (best_d.is_summon and not dd.is_summon) or (best_d.is_summon == dd.is_summon
						and float(dd.meta.get("died_at", 0.0)) >= float(best_d.meta.get("died_at", 0.0))):
					best_d = dd
			if best_d != null:
				out.append(best_d)
		"first_star_allies":
			# 所有友方初星系节点(含自己)
			for u7: BUnit in b.units:
				if u7.alive and u7.team == unit.team and u7.def.first_star:
					out.append(u7)
		"event_meta_targets":
			# 事件 meta.targets 里的单位(引雷的连锁闪电：弹跳结束时 = 这一串打到的所有敌人，按命中顺序)
			for u8: Variant in (ev.get("meta", {}) as Dictionary).get("targets", []):
				var uu: BUnit = u8 as BUnit
				if uu == null or not uu.alive:
					continue
				if trig.team_filter == "enemy" and uu.team == unit.team:
					continue
				if trig.team_filter == "ally" and uu.team != unit.team:
					continue
				out.append(uu)
		"all_allies_except_self":
			# 所有队友(不含自己)
			for u5: BUnit in b.units:
				if u5.alive and u5.team == unit.team and u5 != unit:
					out.append(u5)
		"all_enemies", "all_allies", "all_units":
			for u: BUnit in b.units:
				if not u.alive:
					continue
				if rule == "all_enemies" and u.team == unit.team:
					continue
				if rule == "all_allies" and u.team != unit.team:
					continue
				out.append(u)
		"nearby_units", "nearby_event_target_units":
			var center: Vector2 = unit.pos
			if rule == "nearby_event_target_units" and ev.get("target") is BUnit:
				center = (ev["target"] as BUnit).pos
			var exclude: BUnit = null
			if rule == "nearby_units":
				exclude = unit
			elif ev.get("target") is BUnit:
				exclude = ev["target"] as BUnit
			var rad: float = trig.target_radius if trig.target_radius > 0.0 else 2.4
			for u2: BUnit in b.units:
				if not u2.alive or u2 == exclude:
					continue
				if trig.team_filter == "enemy" and u2.team == unit.team:
					continue
				if trig.team_filter == "ally" and u2.team != unit.team:
					continue
				if u2.pos.distance_to(center) <= rad + u2.radius:
					out.append(u2)
		"self_then_nearby_units":
			# 自身排第一，再按远近接上半径内的单位(team_filter)；配合[群攻 N]：没有群攻 / 个数不够时自身最优先
			out.append(unit)
			var rad2: float = trig.target_radius if trig.target_radius > 0.0 else 2.4
			var near: Array = []
			for u4: BUnit in b.units:
				if not u4.alive or u4 == unit:
					continue
				if trig.team_filter == "enemy" and u4.team == unit.team:
					continue
				if trig.team_filter == "ally" and u4.team != unit.team:
					continue
				var d4: float = u4.pos.distance_to(unit.pos)
				if d4 <= rad2 + u4.radius:
					near.append([d4, u4])
			near.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
			for n4: Array in near:
				out.append(n4[1] as BUnit)
			return out
		"entangled_with_self":
			# 和自己缠在一起的单位(色欲的侵蚀)：自己(身上有这个状态时) + 被自己缠住的对象
			for u6: BUnit in b.units:
				if not u6.alive:
					continue
				for st6: BStatus in u6.status_instances("lust_bind"):
					if u6 == unit or (st6.meta.get("partners", []) as Array).has(unit.uid):
						out.append(u6)
						break
		"stunned_enemies":
			# 所有曾被【眩晕】过的敌人(活着的；锁芯节点·打开深空之门)
			for us: BUnit in b.units:
				if us.alive and us.team != unit.team and bool(us.meta.get("was_stunned", false)):
					out.append(us)
		"random_enemy":
			for u3: BUnit in b.units:
				if u3.alive and u3.team != unit.team:
					out.append(u3)
			if not out.is_empty():
				var pick: BUnit = out[b.rng.randi() % out.size()]
				out = [pick]
		_:
			# 未知规则：退化为当前目标，避免静默失效
			if unit.target != null:
				out.append(unit.target)
	if trig.target_sort_rule != "":
		sort_units(out, trig.target_sort_rule, unit, b)
	return out


## 群攻招式能额外打到的敌人(不含 t0)：按武器大类 multi.shape
##   line  双手长：攻击者 → 目标这条线往后延长，射程内、离线不远(身体半径 + 0.35 m)的敌人，按远近
##   area  双手重：射程内的其他敌人，按远近
## 龙息(虚荣的余烬)：从自己中心沿 dir 的一条射线，宽 width 米、长 length 米(从中心算)，压到的所有敌人(按远近排序)
static func breath_targets(b: Battle, u: BUnit, dir: Vector2, cfg: Dictionary) -> Array[BUnit]:
	var out: Array[BUnit] = []
	if dir.length() < 0.001:
		return out
	var d: Vector2 = dir.normalized()
	var half: float = float(cfg.get("width", 2.0)) * 0.5
	var length: float = float(cfg.get("length", 7.0))
	var keyed: Array = []
	for e: BUnit in b.units:
		if not e.alive or e.team == u.team:
			continue
		var rel: Vector2 = e.pos - u.pos
		var along: float = rel.dot(d)
		var side: float = absf(rel.x * d.y - rel.y * d.x)
		if along >= -e.radius and along <= length + e.radius and side <= half + e.radius * 0.5:
			keyed.append([along, e])
	keyed.sort_custom(func(a: Array, c: Array) -> bool: return float(a[0]) < float(c[0]))
	for k: Array in keyed:
		out.append(k[1] as BUnit)
	return out


## 花蕊(正行节点)：从自己中心朝 dir 张开的锥形(张角 angle 度、长 length 米)，身体有一部分在锥形里的敌人都算，按远近排序
static func cone_targets(b: Battle, u: BUnit, dir: Vector2, cfg: Dictionary) -> Array[BUnit]:
	var out: Array[BUnit] = []
	if dir.length() < 0.001 or cfg.is_empty():
		return out
	var d: Vector2 = dir.normalized()
	var half: float = deg_to_rad(float(cfg.get("angle", 120.0)) * 0.5)
	var length: float = float(cfg.get("length", 4.5))
	var keyed: Array = []
	for e: BUnit in b.units:
		if not e.alive or e.team == u.team or e.has_flag("untargetable") or bool(e.meta.get("dropping", false)):
			continue
		var rel: Vector2 = e.pos - u.pos
		var dist: float = rel.length()
		if dist - e.radius > length:
			continue
		if dist > e.radius + u.radius:
			var ang: float = absf(d.angle_to(rel))
			if ang > half + atan2(e.radius, dist):
				continue
		keyed.append([dist, e])
	keyed.sort_custom(func(a: Array, c: Array) -> bool: return float(a[0]) < float(c[0]))
	for k: Array in keyed:
		out.append(k[1] as BUnit)
	return out


## 花蕊的光刃最多打几个：再绽之花的【群攻 N】(状态 cone.passive)；没有就不限
static func cone_limit(u: BUnit) -> int:
	var pa: AbilityDef = u.def.passive_by_id(str(u.cone_cfg().get("passive", "")))
	if pa == null or not pa.has_keyword("multi_attack"):
		return 99
	return maxi(1, Pipeline.kw_value(u, pa, "multi_attack", 1))


## 花蕊的光刃朝哪挥：候选 = 朝每个够得着的敌人、朝每两个敌人的中点；锥形里(前【群攻 N】个)敌人最多的那个方向，
## 平手时优先压到 must(这一下本来的目标)、再看离自己近的。返回 {dir, targets}；锥形长度内没有敌人 = {}
static func best_cone_aim(b: Battle, u: BUnit, cfg: Dictionary, must: BUnit = null) -> Dictionary:
	var length: float = float(cfg.get("length", 4.5))
	var near: Array[BUnit] = []
	for e: BUnit in b.units:
		if e.alive and e.team != u.team and not e.has_flag("untargetable") and u.pos.distance_to(e.pos) - e.radius <= length:
			near.append(e)
	if near.is_empty():
		return {}
	var dirs: Array[Vector2] = []
	if must != null and must.alive:
		dirs.append(must.pos - u.pos)
	for i in range(near.size()):
		dirs.append(near[i].pos - u.pos)
		for j in range(i + 1, near.size()):
			dirs.append((near[i].pos + near[j].pos) * 0.5 - u.pos)
	var cap: int = cone_limit(u)
	var best: Dictionary = {}
	var best_s := -1e9
	for dv: Vector2 in dirs:
		if dv.length() < 0.05:
			continue
		var hits: Array[BUnit] = cone_targets(b, u, dv, cfg)
		if hits.is_empty():
			continue
		var s: float = float(mini(cap, hits.size())) * 100.0
		if must != null and hits.has(must):
			s += 50.0
		s -= u.pos.distance_to(hits[0].pos)
		if s > best_s:
			best_s = s
			best = {"dir": dv.normalized(), "targets": hits}
	return best


## 龙息的最优方向：候选 = 朝每个够得着的敌人、朝每两个敌人的中点；压到的敌人最多的那条(平手时优先压到 must 这个目标、再看总生命比例低的)。
## 返回 {dir, targets}；没有敌人 = {}
static func best_breath_aim(b: Battle, u: BUnit, cfg: Dictionary, must: BUnit = null) -> Dictionary:
	var length: float = float(cfg.get("length", 7.0))
	var near: Array[BUnit] = []
	for e: BUnit in b.units:
		if e.alive and e.team != u.team and u.pos.distance_to(e.pos) <= length + e.radius:
			near.append(e)
	if near.is_empty():
		return {}
	var dirs: Array[Vector2] = []
	for i in range(near.size()):
		dirs.append(near[i].pos - u.pos)
		for j in range(i + 1, near.size()):
			dirs.append((near[i].pos + near[j].pos) * 0.5 - u.pos)
	var best: Dictionary = {}
	var best_s := -1e9
	for dv: Vector2 in dirs:
		if dv.length() < 0.05:
			continue
		var hits: Array[BUnit] = breath_targets(b, u, dv, cfg)
		if hits.is_empty():
			continue
		var s: float = float(hits.size()) * 100.0
		if must != null and hits.has(must):
			s += 50.0
		for h: BUnit in hits:
			s += (1.0 - h.hp_ratio()) * 2.0
		if s > best_s:
			best_s = s
			best = {"dir": dv.normalized(), "targets": hits}
	return best


static func multi_extra(b: Battle, u: BUnit, t0: BUnit) -> Array[BUnit]:
	var out: Array[BUnit] = []
	# 天降施法者：[群攻] 的其余目标 = 离主目标最近的其他敌人(4 米内)
	if u.def.sky_caster and t0 != null:
		var near: Array = []
		for e0: BUnit in b.units:
			if e0.alive and e0 != t0 and e0.team != u.team and e0.pos.distance_to(t0.pos) <= 4.0 + e0.radius:
				near.append([e0.pos.distance_to(t0.pos), e0])
		near.sort_custom(func(a: Array, c: Array) -> bool: return float(a[0]) < float(c[0]))
		for nr: Array in near:
			out.append(nr[1] as BUnit)
		return out
	var m: Dictionary = u.wclass().get("multi", {})
	if m.is_empty() or t0 == null:
		return out
	var reach: float = u.get_stats().range_meters()
	var dir: Vector2 = t0.pos - u.pos
	var d0: float = dir.length()
	if d0 < 0.001:
		return out
	dir /= d0
	var keyed: Array = []
	for e: BUnit in b.units:
		if not e.alive or e == t0 or e.team == u.team:
			continue
		var rel: Vector2 = e.pos - u.pos
		match str(m.get("shape", "area")):
			"line":
				var along: float = rel.dot(dir)
				var side: float = absf(rel.x * dir.y - rel.y * dir.x)
				if along >= d0 - e.radius and along <= reach + e.radius + t0.radius and side <= e.radius + 0.35:
					keyed.append([along, e])
			_:
				var dist: float = rel.length()
				if dist <= reach + e.radius:
					keyed.append([dist, e])
	keyed.sort_custom(func(a: Array, c: Array) -> bool: return float(a[0]) < float(c[0]))
	for k: Array in keyed:
		out.append(k[1] as BUnit)
	return out


## 溅射普攻的落点规划：在射程内(且看得见)的候选点里找收益最高的——
##   候选 = 每个敌人的位置(直接命中它) + 每两个敌人的中点(打地板)
##   收益 = 直接命中 GC.SPLASH_AIM.direct + 每个被溅到的敌人 .enemy + 每个会被溅到的友军(含自己) .ally
## 溅射半径来自 Pipeline.splash_radius(关键词数值可能被修正，这里不写死)。返回 {point, target(可为 null), score}；没有候选返回 {}
static func best_splash_aim(b: Battle, u: BUnit, ability: AbilityDef, reach: float) -> Dictionary:
	var rad: float = Pipeline.splash_radius(u, ability)
	var foes: Array[BUnit] = []
	for e: BUnit in b.units:
		if e.alive and e.team != u.team and u.pos.distance_to(e.pos) <= reach + e.radius and b.map.has_los(u.pos, e.pos, u.team):
			foes.append(e)
	if foes.is_empty():
		return {}
	var cands: Array = []
	for f: BUnit in foes:
		cands.append([f.pos, f])
	for i in range(foes.size()):
		for j in range(i + 1, foes.size()):
			var mid: Vector2 = (foes[i].pos + foes[j].pos) * 0.5
			if u.pos.distance_to(mid) <= reach and b.map.has_los(u.pos, mid, u.team):
				cands.append([mid, null])
	var best: Dictionary = {}
	# 普攻溅到友方会被转成治疗(护理节点·广义治疗)：溅到受伤的队友是好事，溅到满血的无所谓
	var heals_allies: bool = u.get_stats().na_ally_heal_pct > 0.0
	for c: Array in cands:
		var pt: Vector2 = c[0]
		var direct: BUnit = c[1]
		var score: float = float(GC.SPLASH_AIM["direct"]) if direct != null else 0.0
		for o: BUnit in b.units:
			if not o.alive or o == direct:
				continue
			if o.pos.distance_to(pt) <= rad + o.radius:
				if o.team != u.team:
					score += float(GC.SPLASH_AIM["enemy"])
				elif heals_allies:
					score += float(GC.SPLASH_AIM["ally_heal"]) if o.hp < o.get_stats().max_health - 0.5 else 0.0
				else:
					score += float(GC.SPLASH_AIM["ally"])
		# 同分时优先直接打当前目标，其次近的
		var tie: float = 0.001 if direct != null and direct == u.target else 0.0
		tie -= u.pos.distance_to(pt) * 0.0001
		if best.is_empty() or score + tie > float(best["score"]) + float(best["tie"]):
			best = {"point": pt, "target": direct, "score": score, "tie": tie}
	return best


## 周围(半径 rad)人数最多的队友(summons = true 只看召唤物，false 只看非召唤物；不含自己)
static func _busiest_ally(b: Battle, unit: BUnit, rad: float, summons: bool) -> BUnit:
	var best: BUnit = null
	var best_n := -1
	for a: BUnit in b.units:
		if not a.alive or a == unit or a.team != unit.team or a.is_summon != summons:
			continue
		var n := 0
		for o: BUnit in b.units:
			if o.alive and o != unit and o.pos.distance_to(a.pos) <= rad + o.radius:
				n += 1
		if n > best_n:
			best_n = n
			best = a
	return best


static func sort_units(list: Array[BUnit], rule: String, ref: BUnit, b: Battle) -> void:
	# status_remaining_desc:<状态>：身上这个状态剩余时间最长的(一个实例)排前面
	if rule.begins_with("status_remaining_desc:"):
		var sid: String = rule.get_slice(":", 1)
		var rem := func(u: BUnit) -> float:
			var best := 0.0
			for st: BStatus in u.status_instances(sid):
				if st.expires_at >= 0.0:
					best = maxf(best, st.expires_at - b.time)
			return best
		list.sort_custom(func(x: BUnit, y: BUnit) -> bool: return float(rem.call(x)) > float(rem.call(y)))
		return
	# status_stacks_desc:<状态>：这个状态层数多的排前面，一样多时离自己近的在前(善良地：沉醉层数多的先)
	if rule.begins_with("status_stacks_desc:"):
		var sid2: String = rule.get_slice(":", 1)
		list.sort_custom(func(x: BUnit, y: BUnit) -> bool:
			var sx: int = x.status_stacks(sid2)
			var sy: int = y.status_stacks(sid2)
			return sx > sy or (sx == sy and x.pos.distance_squared_to(ref.pos) < y.pos.distance_squared_to(ref.pos)))
		return
	match rule:
		"nearest":
			list.sort_custom(func(x: BUnit, y: BUnit) -> bool: return x.pos.distance_squared_to(ref.pos) < y.pos.distance_squared_to(ref.pos))
		"farthest":
			list.sort_custom(func(x: BUnit, y: BUnit) -> bool: return x.pos.distance_squared_to(ref.pos) > y.pos.distance_squared_to(ref.pos))
		"health_asc":
			list.sort_custom(func(x: BUnit, y: BUnit) -> bool: return x.hp < y.hp)
		"health_ratio_asc":
			list.sort_custom(func(x: BUnit, y: BUnit) -> bool: return x.hp_ratio() < y.hp_ratio())
		"health_desc":
			list.sort_custom(func(x: BUnit, y: BUnit) -> bool: return x.hp > y.hp)
		"defense_desc":
			list.sort_custom(func(x: BUnit, y: BUnit) -> bool: return x.get_stats().defense > y.get_stats().defense)
		"attack_desc":
			list.sort_custom(func(x: BUnit, y: BUnit) -> bool: return x.get_stats().attack_power > y.get_stats().attack_power)
		"damage_dealt_desc":
			list.sort_custom(func(x: BUnit, y: BUnit) -> bool: return x.st_damage > y.st_damage)
		"physical_output_desc":
			# 本场至今造成的物理伤害最多的排前面；一样多时攻击力高的在前(弱体符：当前物理输出最高的敌人)
			list.sort_custom(func(x: BUnit, y: BUnit) -> bool:
				var px: float = float(x.st_dmg_by_kind.get("physical", 0.0))
				var py: float = float(y.st_dmg_by_kind.get("physical", 0.0))
				return px > py or (px == py and x.get_stats().attack_power > y.get_stats().attack_power))
		"status_remaining_desc":
			pass
		"random":
			for i in range(list.size() - 1, 0, -1):
				var j: int = b.rng.randi() % (i + 1)
				var tmp: BUnit = list[i]
				list[i] = list[j]
				list[j] = tmp
		_:
			pass


## 威胁最高的敌人：首领 > 精英 > 预估输出(攻击力 × 普攻倍率 + 法术强度)/ 攻击间隔(一样时取近的)
## 落点：能用半径 radius 的圆罩住最多点(敌人)的位置——候选 = 每个点 / 两两中点 / 每三个的重心；罩住的一样多时取更紧凑的(到被罩住的点的距离和小)，
## 再推出障碍物、夹进场地(星旅节点·渡星而来；备战时的预计落点和开战时的真实落点都用它)
static func densest_point(points: Array[Vector2], radius: float, map: BattleMap, body: float = 0.42) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var cands: Array[Vector2] = []
	for i in range(points.size()):
		cands.append(points[i])
		for j in range(i + 1, points.size()):
			cands.append((points[i] + points[j]) * 0.5)
			for k in range(j + 1, points.size()):
				cands.append((points[i] + points[j] + points[k]) / 3.0)
	var best: Vector2 = points[0]
	var best_s := -1.0e9
	for c: Vector2 in cands:
		var p: Vector2 = GC.clamp_to_arena(c, body)
		if map != null:
			p = map.push_out(p, body)
		var cnt := 0
		var dsum := 0.0
		for q: Vector2 in points:
			var d: float = q.distance_to(p)
			if d <= radius + 0.42:
				cnt += 1
				dsum += d
		var s: float = float(cnt) * 1000.0 - dsum
		if s > best_s:
			best_s = s
			best = p
	return best


## 敌方最强的单位：首领 > 精英 > 费用 × 星级倍率最高 > 预估输出最高(灭罪节点：光束降临的位置)
static func strongest_pick(b: Battle, unit: BUnit) -> BUnit:
	var best: BUnit = null
	var best_k := -1.0e30
	for e: BUnit in b.enemies_of(unit):
		if b.ai.shadow_hidden(unit, e):
			continue
		var st: StatBlock = e.get_stats()
		var na_mult: float = float(e.wclass().get("na_mult", 1.0)) if e.can_attack() else 0.0
		var k: float = float(e.def.cost) * GC.star_mult(e.star) * 1.0e5 + (st.attack_power * na_mult + st.ability_power) / maxf(0.2, st.attack_interval())
		if e.meta.has("boss"):
			k += 1.0e12
		elif e.meta.has("elite"):
			k += 1.0e11
		if k > best_k:
			best_k = k
			best = e
	return best


## 敌方本场造成伤害最多的单位(战报的 dealt)；还没人打出伤害时 = 最强的单位。灭罪节点的光束一直锁定它
static func top_damage_pick(b: Battle, unit: BUnit) -> BUnit:
	var best: BUnit = null
	var bd := 0.0
	for e: BUnit in b.enemies_of(unit):
		if b.ai.shadow_hidden(unit, e):
			continue
		var d: float = float((b.report.rows.get(e.uid, {}) as Dictionary).get("dealt", 0.0))
		if d > bd:
			bd = d
			best = e
	return best if best != null else strongest_pick(b, unit)


static func threat_pick(b: Battle, unit: BUnit) -> BUnit:
	var best: BUnit = null
	var best_k := -1.0e30
	for e: BUnit in b.enemies_of(unit):
		if b.ai.shadow_hidden(unit, e):
			continue                                   # 凝暗(踏影节点)：不能被索敌
		var st: StatBlock = e.get_stats()
		var na_mult: float = float(e.wclass().get("na_mult", 1.0)) if e.can_attack() else 0.0
		var k: float = (st.attack_power * na_mult + st.ability_power) / maxf(0.2, st.attack_interval())
		if e.meta.has("boss"):
			k += 1.0e9
		elif e.meta.has("elite"):
			k += 1.0e8
		k -= e.pos.distance_to(unit.pos) * 0.01
		if k > best_k:
			best_k = k
			best = e
	return best
