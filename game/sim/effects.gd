class_name Effects
extends RefCounted
## 效果应用层：只负责"把已经算好的数值施加到单位上"并发出后续事件(OnDamageDealt 等)。
## 不含任何具体单位/装备的名字——所有差异都来自数据。

var b: Battle
var _neutral: StatBlock = StatBlock.new()


func _init(p_battle: Battle) -> void:
	b = p_battle


func _stats_of(u: BUnit) -> StatBlock:
	return u.get_stats() if u != null else _neutral


# ---------------------------------------------------------------- 伤害
## o: can_crit, crit_roll, cfg(穿透/无视减伤等), surface, ability_id, equip_id, trigger_id, is_copy, tags
## 施加者身上"针对某个敌人"的加成(猎人笔记：status.meta.vs_target = 那个敌人的 uid)：{amp, pen, dodge}，没有就空
static func vs_bonus(holder: BUnit, other: BUnit) -> Dictionary:
	if holder == null or other == null:
		return {}
	for st: BStatus in holder.statuses.values():
		if str(st.meta.get("vs_target", "")) == other.uid:
			return st.meta
	return {}


## 背后攻击的增幅(踏影节点·凝暗：每层 +x%)：从目标背后造成的普攻 / 技能伤害(持续伤害不算)，并进针对目标的增伤(同一个乘区)
static func _back_bonus(src: BUnit, dst: BUnit, vb: Dictionary, o: Dictionary) -> Dictionary:
	if src == null or dst == null or src == dst:
		return vb
	var ba: float = src.get_stats().backstab_amp
	if ba <= 0.0 or damage_category(o) == "dot" or not Pipeline.is_behind(src, dst):
		return vb
	var r: Dictionary = vb.duplicate()
	r["amp"] = float(r.get("amp", 0.0)) + ba
	return r


func damage(src: BUnit, dst: BUnit, raw: float, kind: String, o: Dictionary = {}) -> float:
	if dst == null or not dst.alive:
		return 0.0
	if dst != null and dst.has_flag("invulnerable"):
		return 0.0                                      # 魂体存在：不受伤害
	if bool(o.get("hp_loss", false)):
		return _hp_loss(src, dst, raw, o)
	# 颜料(幻彩节点·闪耀色彩)：这一次伤害强制转成颜料的类型(增幅由颜料的属性给)，结算完就消耗
	var paint: BStatus = paint_of(src)
	if paint != null:
		kind = str(paint.meta["convert"])
	# 普攻伤害与技能伤害的固定值加成(天空视野)：加在原始伤害上(持续伤害不加)
	if src != null and src.get_stats().na_skill_flat_damage > 0.0 and damage_category(o) != "dot":
		raw += src.get_stats().na_skill_flat_damage
	# 针对这个目标的增伤与百分比穿透(猎人笔记)：增伤乘在原始伤害上，穿透并进这一下的计算配置
	var vb: Dictionary = _back_bonus(src, dst, vs_bonus(src, dst), o)
	o = o.duplicate()
	o["cfg"] = calc_cfg(o, vb)
	# 【燃烧】的伤害对"燃烧转治疗"的单位(色欲的余烬·蠕生)：按减免后的伤害量改为回复它的若干倍(和吸血一样是属性带来的规则)
	if str(o.get("status_base", "")) == "burning" and dst.get_stats().burn_to_heal > 0.0:
		var res0: Dictionary = _stats_of(src).calc_damage_against(dst.get_stats(), raw, kind, false, 1.0, o.get("cfg", {}))
		var h: float = float(res0["amount"]) * dst.get_stats().burn_to_heal
		if h > 0.0:
			heal(dst, dst, h, {"surface": "regen", "raw": true, "ability_id": "burn_to_heal"})
		return 0.0
	var can_crit: bool = bool(o.get("can_crit", false))
	var roll: float = float(o.get("crit_roll", -1.0))
	# 卡车改装·珠光力场：我方的非持续伤害都能暴击(本来不能的按暴击率掷一次)；本来就能的在下面再掷一次
	var pearl: bool = src != null and damage_category(o) != "dot" and not bool(o.get("no_crit", false)) and not Pipeline.mod_rule(src, "pearl_field").is_empty()
	if pearl and not can_crit and not bool(o.get("force_crit", false)):
		can_crit = true
		roll = b.roll_good(src)
	if roll < 0.0:
		roll = b.roll_good(src) if can_crit else 1.0
	if bool(o.get("force_crit", false)):
		can_crit = true
		roll = -1.0                                  # 必定暴击(大口径子弹)
	elif bool(o.get("no_crit", false)):
		can_crit = false
	var res: Dictionary = _stats_of(src).calc_damage_against(dst.get_stats(), raw, kind, can_crit, roll, o.get("cfg", {}))
	var amount: float = float(res["amount"])
	if pearl and bool(o.get("can_crit", false)) and b.roll_good(src) < clampf(src.get_stats().crit_chance, 0.0, 1.0):
		amount *= maxf(1.0, src.get_stats().crit_damage)   # 再次暴击
		res["crit"] = true
	# 花蕊(正行节点)：普攻伤害获得等同于治疗量加成的最终伤害加成(最终伤害：单独一个乘区，不和增伤相加)
	if src != null and amount > 0.0 and is_na_damage(o) and src.has_flag("na_heal_final"):
		amount *= 1.0 + maxf(0.0, src.get_stats().healing_done_pct)
	# 受到的持续伤害 + 固定值(崩裂)：每一跳加一次，减伤之后加
	if damage_category(o) == "dot" and dst.get_stats().dot_taken_flat > 0.0:
		amount += dst.get_stats().dot_taken_flat
	# 对普攻伤害的固定减免(护甲、减伤之后再减)；"视为普攻伤害"的装备效果(爱心针剂)也吃
	if is_na_damage(o):
		# cfg.na_flat_floor(实验开关，默认 0 = 不保底)：固定减免最多把这一下减到原来的这么多
		amount = maxf(amount * float(b.cfg.get("na_flat_floor", 0.0)), amount - dst.get_stats().na_damage_taken_flat)
	# 最终减免(初星之光)：来自友军(同队，包括自己)的伤害，减免效能 ×3，最多 99%
	var fdr: float = dst.get_stats().final_dmg_reduction
	if fdr > 0.0:
		if src != null and src.team == dst.team:
			fdr *= 3.0
		amount *= 1.0 - clampf(fdr, 0.0, 0.99)
	# 温柔地(共歌节点)：开局一段时间里所有单位受到的伤害最终降低(不分敌我)
	var gk: float = b.gentle_factor()
	if gk > 0.0:
		amount *= 1.0 - gk
	var crit: bool = bool(res["crit"])
	# 卡车改装·针对性保护：吟唱中(含拉弓)的节点承受的伤害，一半改由其他节点平均分摊(流失生命：不吃护甲 / 护盾 / 减伤)
	if amount > 0.0 and dst.team == GC.TEAM_PLAYER and (dst.phase == "chant" or dst.phase == "draw"):
		var cg: Dictionary = Pipeline.mod_rule(dst, "cast_guard")
		if not cg.is_empty():
			var mates: Array[BUnit] = []
			for m: BUnit in b.alive_units(dst.team):
				if m != dst and not m.is_summon:
					mates.append(m)
			if not mates.is_empty():
				var share: float = amount * clampf(float(cg.get("share", 0.5)), 0.0, 1.0)
				amount -= share
				var each: float = share / float(mates.size())
				for m2: BUnit in mates:
					_hp_loss(src, m2, each, {"surface": "shared", "ability_id": "mod_cast_guard"})
				b.fx({"t": "cast_guard", "unit": dst, "amount": share})
	# 这一下最多造成多少伤害(飞蝶：普攻至多造成触发数值的伤害)
	if o.has("dmg_cap"):
		amount = minf(amount, maxf(0.0, float(o["dmg_cap"])))
	if paint != null and src.statuses.has(paint.id):
		end_status(src, paint.id)                     # 颜料用掉了(增幅已经算进这一下)
		b.fx({"t": "paint_used", "unit": src, "target": dst, "color": str(paint.meta.get("color", ""))})
	if amount <= 0.0 and raw <= 0.0:
		return 0.0
	# 护盾吸收
	var absorbed: float = minf(dst.shield, amount)
	var broke := false
	if absorbed > 0.0:
		dst.shield -= absorbed
		if dst.shield <= 0.001:
			dst.shield = 0.0
			broke = true
	var to_hp: float = amount - absorbed
	var overkill: float = maxf(0.0, to_hp - dst.hp)
	dst.hp -= to_hp
	dst.meta["last_hit"] = amount                     # 最近一次受到的伤害(致求生的意志：致命伤害每 y 点叠一层送葬)
	# 统计
	var surface: String = str(o.get("surface", "other"))
	dst.st_taken += amount
	if src != null:
		src.st_damage += amount
		src.st_dmg_by_kind[kind] = float(src.st_dmg_by_kind.get(kind, 0.0)) + amount
		src.st_dmg_by_surface[surface] = float(src.st_dmg_by_surface.get(surface, 0.0)) + amount
	var cat: String = damage_category(o)
	if cat == "dot" and amount > 0.0:
		b.dot_dealt += amount                         # 全场造成的持续伤害累计(血嗜节点·血宴)
	b.fx({"t": "damage", "src": src, "dst": dst, "amount": amount, "kind": kind, "crit": crit,
		"surface": surface, "ability": o.get("ability_id", ""), "equip": o.get("equip_id", ""),
		"absorbed": absorbed, "splash": bool(o.get("splash", false)), "overkill": overkill,
		"mitigated": maxf(0.0, float(res.get("pre", amount)) - amount), "category": cat})
	# 普攻物理伤害附带原伤害若干比例的魔法伤害(狩胜节点·光荣)：原伤害 = 这一下打出去时的伤害(暴击、增伤算进去，对方的护甲不算)
	if src != null and kind == "physical" and is_na_damage(o) and not bool(o.get("bonus_magic", false)) and dst.alive and dst.hp > 0.0:
		var bm: float = src.get_stats().na_bonus_magic_pct
		if bm > 0.0:
			var orig: float = float(src.get_stats().calc_damage_boosts_only(dst.get_stats(), raw, crit, 0.0 if crit else 1.0, o.get("cfg", {}))["amount"])
			damage(src, dst, orig * bm, "magic", {"surface": surface0_of(o), "ability_id": "glory_magic", "bonus_magic": true, "splash": bool(o.get("splash", false))})
	# 吸血(成品完工的真实伤害：物理吸血和法术吸血都算)
	if src != null and src.alive and amount > 0.0:
		var ls: float = src.get_stats().calc_lifesteal(amount, kind, bool((o.get("cfg", {}) as Dictionary).get("dual_kind", false)) if o.get("cfg") is Dictionary else false)
		if ls > 0.0:
			heal(src, src, ls, {"surface": "lifesteal", "raw": true})
	# 后续事件
	var meta: Dictionary = {"kind": kind, "surface": surface, "crit": crit, "ability_id": o.get("ability_id", ""), "overkill": overkill,
		"category": cat}
	var tags: Array[String] = [surface, kind + "_damage"]
	var ctag: String = category_tag(cat)
	if not tags.has(ctag):
		tags.append(ctag)                     # 普攻伤害 normal_attack / 技能伤害 skill_damage / 持续伤害 dot_damage
	if src != null:
		b.pipeline.emit("OnDamageDealt", src, dst, amount, tags, meta)
	b.pipeline.emit("OnDamageTaken", dst, src, amount, tags, meta)
	if broke:
		b.pipeline.emit("OnShieldBroken", dst, src, dst.shield_peak, ["shield_broken"], {})
		dst.shield_peak = 0.0
	_after_hp_drop(dst, src, overkill)
	return amount


## 流失生命(某已不知名的星星的旗帜：流失当前生命的百分比)：不是"受到伤害"的那套算法——不暴击、不吃增伤 / 护甲 / 减伤、
## 不被护盾挡；照样算一次技能伤害(战报 / OnDamageDealt / OnDamageTaken 都有，标签多一个 hp_loss)
func _hp_loss(src: BUnit, dst: BUnit, amount: float, o: Dictionary) -> float:
	amount = maxf(0.0, amount)
	if amount <= 0.0:
		return 0.0
	var overkill: float = maxf(0.0, amount - dst.hp)
	dst.hp -= amount
	dst.meta["last_hit"] = amount
	var surface: String = str(o.get("surface", "other"))
	dst.st_taken += amount
	if src != null:
		src.st_damage += amount
		src.st_dmg_by_kind["true"] = float(src.st_dmg_by_kind.get("true", 0.0)) + amount
		src.st_dmg_by_surface[surface] = float(src.st_dmg_by_surface.get(surface, 0.0)) + amount
	b.fx({"t": "damage", "src": src, "dst": dst, "amount": amount, "kind": "true", "crit": false, "surface": surface,
		"ability": o.get("ability_id", ""), "equip": o.get("equip_id", ""), "absorbed": 0.0, "splash": false, "overkill": overkill,
		"mitigated": 0.0, "category": "skill", "hp_loss": true})
	var meta: Dictionary = {"kind": "true", "surface": surface, "crit": false, "ability_id": o.get("ability_id", ""), "overkill": overkill, "category": "skill"}
	var tags: Array[String] = [surface, "true_damage", "skill_damage", "hp_loss"]
	if src != null:
		b.pipeline.emit("OnDamageDealt", src, dst, amount, tags, meta)
	b.pipeline.emit("OnDamageTaken", dst, src, amount, tags, meta)
	_after_hp_drop(dst, src, overkill)
	return amount


## 生命掉到 0 以下之后：无法被击杀的(外神之貌的锁血)留 1 点；否则进入阵亡流程
func _after_hp_drop(dst: BUnit, src: BUnit, overkill: float) -> void:
	if dst.hp > 0.0:
		return
	if dst.has_flag("undying") and not bool(dst.meta.get("_doomed", false)):
		dst.hp = 1.0
		return
	try_kill(dst, src, overkill)


## 身上的颜料(带 meta.convert 的状态)；没有 = null
static func paint_of(u: BUnit) -> BStatus:
	if u == null:
		return null
	for st: BStatus in u.statuses.values():
		if st.meta.has("convert"):
			return st
	return null


## 算伤害用的配置：能力自己的配置(穿透等) + 这一下的伤害分类(增伤乘区按它取普攻 / 技能 / 持续增幅) + 这一下额外的增伤(o.amp_bonus：完美时计)
## + 针对目标的增伤 / 穿透(vb：猎人笔记)。不改能力数据本身
static func calc_cfg(o: Dictionary, vb: Dictionary = {}) -> Dictionary:
	var c: Dictionary = (o.get("cfg", {}) as Dictionary).duplicate() if o.get("cfg") is Dictionary else {}
	c["category"] = damage_category(o)
	var amp: float = float(c.get("amp_bonus", 0.0)) + float(o.get("amp_bonus", 0.0)) + float(vb.get("amp", 0.0))
	if amp != 0.0:
		c["amp_bonus"] = amp
	if float(vb.get("pen", 0.0)) > 0.0:
		c["percent_penetration_bonus"] = float(c.get("percent_penetration_bonus", 0.0)) + float(vb["pen"])
	return c


static func surface0_of(o: Dictionary) -> String:
	return str(o.get("surface", "other"))


## 引爆会引爆的[叠加]状态(剑痕：到期或叠满)：先把状态拿掉，再按层数各发一次 OnStatusBurst 给施加者
## (目标 = 持有者，事件数值 = 引爆时的层数)。施加者已经倒下就只是消失
func burst_status(holder: BUnit, st: BStatus) -> void:
	var sid: String = st.id
	var base_sid: String = str(st.meta.get("base_id", sid))
	var n: int = st.stacks
	holder.statuses.erase(sid)
	holder.mark_dirty()
	var src: BUnit = b.get_unit_by_uid(st.source_id)
	b.fx({"t": "status_burst", "unit": holder, "src": src, "id": base_sid, "stacks": n})       # 画面：先把刀痕炸开，再清状态
	b.fx({"t": "status", "unit": holder, "id": sid, "base_id": base_sid, "stacks": 0, "created": false, "flags": []})
	if src == null or not src.alive or n <= 0:
		return
	for i in range(n):
		b.pipeline.emit("OnStatusBurst", src, holder, float(n), ["status_burst", base_sid], {"status_id": base_sid, "stacks": n, "index": i})


## 伤害分类(每一下伤害三选一，事件标签 / 战报都带着)：
##   normal_attack 普攻伤害：普攻本身，或效果配置写了 as_normal_attack(视为普攻伤害)的
##   dot           持续伤害：状态的周期伤害(燃烧等，surface = status)
##   skill         技能伤害：其余一切——被动、武器效果、羁绊、地形与战场机制的打击、投掷、引爆……
## 能力的效果配置里写 damage_category 可以强制指定
const DAMAGE_CATEGORIES: Array[String] = ["normal_attack", "skill", "dot"]


static func damage_category(o: Dictionary) -> String:
	var cfgc: Dictionary = o.get("cfg", {}) if o.get("cfg") is Dictionary else {}
	if cfgc.has("damage_category"):
		return str(cfgc["damage_category"])
	if is_na_damage(o):
		return "normal_attack"
	if str(o.get("surface", "")) == "status":
		return "dot"
	return "skill"


## 分类对应的事件标签(普攻沿用原来的 normal_attack)
static func category_tag(cat: String) -> String:
	return {"normal_attack": "normal_attack", "skill": "skill_damage", "dot": "dot_damage"}.get(cat, "skill_damage")


## 这一下算不算"普攻伤害"：普攻本身，或者效果配置里写了 as_normal_attack(视为普攻伤害)的
static func is_na_damage(o: Dictionary) -> bool:
	return str(o.get("surface", "")) == "normal_attack" or bool((o.get("cfg", {}) as Dictionary).get("as_normal_attack", false))


## 这一下"本应造成"的最终伤害值(不真的打)：只算能提升伤害的东西——暴击、施加者的增伤、目标的易伤；
## 会减少伤害的一概不算(护甲 / 魔抗、减伤、护盾、普攻固定减免、初星之光)。护理节点·广义治疗把它换成治疗。返回 {amount, crit}
func preview_damage(src: BUnit, dst: BUnit, raw: float, _kind: String, o: Dictionary = {}) -> Dictionary:
	var can_crit: bool = bool(o.get("can_crit", false))
	var roll: float = float(o.get("crit_roll", -1.0))
	if roll < 0.0:
		roll = b.rng.randf() if can_crit else 1.0
	var pc: Dictionary = calc_cfg(o, vs_bonus(src, dst))
	pc["kind"] = _kind
	return _stats_of(src).calc_damage_boosts_only(dst.get_stats(), raw, can_crit, roll, pc)


## 一下伤害打到 dst 身上大概会是多少(不真的打，没有任何副作用)：和 damage() 同一套算法——固定加成、针对性增伤 / 穿透、
## 暴击(按暴击率取期望)、增伤、护甲 / 魔抗 / 减伤、普攻固定减免、最终减免。完美时计用它判断"停着的飞刀够不够打死目标"
func estimate_damage(src: BUnit, dst: BUnit, raw: float, kind: String, o: Dictionary = {}) -> float:
	if dst == null or not dst.alive:
		return 0.0
	if src != null and src.get_stats().na_skill_flat_damage > 0.0 and damage_category(o) != "dot":
		raw += src.get_stats().na_skill_flat_damage
	var cfg: Dictionary = calc_cfg(o, _back_bonus(src, dst, vs_bonus(src, dst), o))
	var ss: StatBlock = _stats_of(src)
	var normal: float = float(ss.calc_damage_against(dst.get_stats(), raw, kind, false, 1.0, cfg)["amount"])
	var amount: float = normal
	if bool(o.get("can_crit", false)):
		var cc: float = clampf(ss.crit_chance + float(cfg.get("crit_chance_bonus", 0.0)), 0.0, 1.0)
		var crit: float = float(ss.calc_damage_against(dst.get_stats(), raw, kind, true, -1.0, cfg)["amount"])
		amount = lerpf(normal, crit, cc)
	if is_na_damage(o):
		amount = maxf(amount * float(b.cfg.get("na_flat_floor", 0.0)), amount - dst.get_stats().na_damage_taken_flat)
	var fdr: float = dst.get_stats().final_dmg_reduction
	if fdr > 0.0:
		if src != null and src.team == dst.team:
			fdr *= 3.0
		amount *= 1.0 - clampf(fdr, 0.0, 0.99)
	amount *= 1.0 - b.gentle_factor()
	return maxf(0.0, amount)


## 投掷(狩胜节点·必胜)：先摆出投掷的前摇(windup 秒，不受 AI 控制)，然后武器离手飞向目标(Battle._step_throws)；
## 命中造成 amount 的伤害(o 决定能否暴击、是否视为普攻伤害)，投掷者立刻位移到目标身边。正在投掷 / 冲刺时先记下来，落地后再投
func weapon_throw(src: BUnit, t: BUnit, amount: float, ability: AbilityDef, o: Dictionary) -> void:
	if src == null or not src.alive or t == null or not t.alive:
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	if src.phase == "throw" or src.phase == "dash":
		src.meta["queued_throw"] = {"amount": amount, "ability": ability, "o": o}
		return
	b.interrupt(src)
	src.phase = "throw"
	src.vel = Vector2.ZERO
	src.facing = atan2(t.pos.x - src.pos.x, t.pos.y - src.pos.y)
	var od: Dictionary = o.duplicate()
	od["can_crit"] = ability.has_keyword("crit")
	var windup: float = float(cfg.get("windup", 0.34))
	src.meta["throw"] = {"target": t, "at": b.time + windup, "amount": amount, "o": od, "speed": float(cfg.get("speed", 18.0)),
		"dash_speed": float(cfg.get("dash_speed", 16.0))}
	b.fx({"t": "throw_start", "unit": src, "target": t, "windup": windup, "weapon_class": src.weapon_class()})


## 制造晶球(打工小帮手)：在 at 身边放 round(amount) 个晶球，战斗结束后和敌人掉的一起领取。
## cfg.tier = 默认档次；cfg.upgrades = [[档次, 概率], ...] 按顺序判定(概率互不重叠；彩色 / 金色 / 蓝色)
func create_orbs(src: BUnit, at: BUnit, amount: float, cfg: Dictionary) -> void:
	var n: int = int(round(amount))
	if n <= 0 or at == null:
		return
	for i in range(n):
		var tier: String = str(cfg.get("tier", "white"))
		var roll: float = b.roll_good(src)
		var acc := 0.0
		for up: Variant in cfg.get("upgrades", []):
			acc += float((up as Array)[1])
			if roll < acc:
				tier = str((up as Array)[0])
				break
		var ang: float = TAU * float(i) / float(maxi(1, n)) + 0.6
		var pos: Vector2 = at.pos + Vector2(cos(ang), sin(ang)) * 0.6
		b.drops.append({"tier": tier, "pos": pos, "made_by": src.def.id if src != null else ""})
		b.fx({"t": "orb_made", "unit": at, "tier": tier, "pos": pos})


func try_kill(victim: BUnit, killer: BUnit, overkill: float = 0.0) -> void:
	if not victim.alive:
		return
	# 濒死时机：允许装备/被动在死亡前响应(例如治疗、护盾)
	if not victim.meta.get("_before_death_done", false) and not bool(victim.meta.get("_doomed", false)):
		victim.meta["_before_death_done"] = true
		b.pipeline.emit_now("OnBeforeDeath", victim, killer, 0.0, ["before_death"], {"overkill": overkill})
		# 被视为它的召唤物的单位(守誓节点)也能在它倒下之前响应(光色誓约)
		if victim.hp <= 0.0:
			for g: BUnit in b.units:
				if g.alive and g != victim and g.summoner() == victim:
					b.pipeline.emit_now("OnSummonerBeforeDeath", g, victim, 0.0, ["summoner_before_death"], {"overkill": overkill})
					if victim.hp > 0.0:
						break
		# 同一队的其他人也能在它倒下之前响应(白羽节点·致求生的意志)；事件数值 = 这一下致命的伤害
		if victim.hp <= 0.0:
			for g2: BUnit in b.units:
				if g2.alive and g2 != victim and g2.team == victim.team and b.pipeline._listens(g2, "OnAllyBeforeDeath"):
					b.pipeline.emit_now("OnAllyBeforeDeath", g2, victim, float(victim.meta.get("last_hit", 0.0)), ["ally_before_death"], {"overkill": overkill})
					if victim.hp > 0.0:
						break
		if victim.hp > 0.0:
			victim.meta["_before_death_done"] = false
			return
	victim.alive = false
	victim.hp = 0.0
	victim.phase = "dead"
	victim.meta["died_at"] = b.time               # 阵亡时刻(在发阵亡事件之前记下：心连节点·奇迹挑"最近倒下的")
	victim.meta["has_died"] = true                # 本场阵亡过(被复活也算；黑键只杀"本场战斗未阵亡过的友军")
	victim.vel = Vector2.ZERO
	if killer != null:
		killer.st_kills += 1
		# 记下"这个单位击杀过某一方的人"(暗色誓约的觉醒任务：击杀战斗中击杀过队友的敌人)
		if killer.team != victim.team:
			(killer.meta.get_or_add("killed_team", {}) as Dictionary)[victim.team] = true
	b.fx({"t": "death", "unit": victim, "killer": killer})
	# hunted：被击杀的是凶手那一队的狩猎对象(凯旋：击杀狩猎对象时获得更多光荣)
	var hunted: bool = killer != null and b.hunt_targets.get(killer.team, null) == victim
	var meta := {"overkill": overkill, "killer": killer, "dead": victim, "hunted": hunted}
	if killer != null:
		b.pipeline.emit("OnUnitKilled", killer, victim, overkill, ["unit_killed"], meta)
	# 被斩杀的(光之心)：不触发它自己的阵亡时效果
	if not bool(victim.meta.get("no_death_fx", false)):
		b.pipeline.emit("OnUnitDied", victim, killer, overkill, ["unit_died"], meta)
	for u: BUnit in b.units:
		if not u.alive or u == victim:
			continue
		if killer != null and u.team == killer.team and u != killer:
			b.pipeline.emit("OnAllyUnitKilled", u, victim, overkill, ["ally_unit_killed"], meta)
		if u.team == victim.team:
			b.pipeline.emit("OnAllyUnitDied", u, killer, overkill, ["ally_unit_died"], meta)
		elif b.pipeline._listens(u, "OnEnemyUnitDied"):
			b.pipeline.emit("OnEnemyUnitDied", u, killer, overkill, ["enemy_unit_died"], meta)
	b.on_unit_died(victim)


# ---------------------------------------------------------------- 治疗
func heal(src: BUnit, dst: BUnit, raw: float, o: Dictionary = {}) -> Dictionary:
	if dst != null and dst.alive and dst.has_flag("no_heal"):
		return {"amount": 0.0, "overheal": 0.0}             # 无法被治疗(外神之貌的锁血)
	if dst == null or not dst.alive:
		return {"applied": 0.0, "overheal": 0.0}
	var amount: float = raw
	if not bool(o.get("raw", false)):
		amount = _stats_of(src).calc_heal(dst.get_stats(), raw)
	else:
		amount = maxf(0.0, raw) * maxf(0.0, 1.0 + dst.get_stats().healing_received_pct)
	# 站在稻田(地形)上：每次回复额外 + 固定值
	if amount > 0.0:
		amount += b.field_heal_bonus(dst)
	var missing: float = maxf(0.0, dst.get_stats().max_health - dst.hp)
	var applied: float = minf(missing, amount)
	var over: float = maxf(0.0, amount - applied)
	dst.hp += applied
	if src != null:
		src.st_heal += applied
	var surface: String = str(o.get("surface", "other"))
	b.fx({"t": "heal", "src": src, "dst": dst, "amount": applied, "over": over, "surface": surface,
		"ability": o.get("ability_id", ""), "equip": o.get("equip_id", ""), "splash": bool(o.get("splash", false)),
		"crit": bool(o.get("crit", false)), "na_heal": bool(o.get("na_heal", false))})
	if surface != "lifesteal" and surface != "regen" and src != null:
		var tags: Array[String] = [surface, "heal"]
		b.pipeline.emit("OnHealApplied", src, dst, applied, tags, {"overheal": over, "surface": surface, "requested": amount})
		if over > 0.0:
			b.pipeline.emit("OnHealOverflow", src, dst, over, ["heal_overflow"], {"surface": surface, "applied": applied})
	return {"applied": applied, "overheal": over, "requested": amount}


# ---------------------------------------------------------------- 护盾
func add_shield(src: BUnit, dst: BUnit, amount: float, o: Dictionary = {}) -> void:
	if dst == null or not dst.alive or amount <= 0.0:
		return
	amount *= maxf(0.0, 1.0 + dst.get_stats().shield_received_pct)
	dst.shield += amount
	dst.shield_peak = maxf(dst.shield_peak, dst.shield)
	if src != null:
		src.st_shield += amount
	b.fx({"t": "shield", "src": src, "dst": dst, "amount": amount, "surface": o.get("surface", "other"),
		"ability": o.get("ability_id", ""), "equip": o.get("equip_id", "")})


# ---------------------------------------------------------------- 状态
## 结束一个状态实例(引爆、吞掉、缠绕解除)：移除并发出状态结束的事件
func end_status(u: BUnit, sid: String) -> void:
	if not u.statuses.has(sid):
		return
	var st: BStatus = u.statuses[sid]
	u.statuses.erase(sid)
	u.mark_dirty()
	b.fx({"t": "status", "unit": u, "id": sid, "base_id": str(st.meta.get("base_id", sid)), "stacks": 0, "created": false, "flags": []})


## cfg: status_id, stat_id, flat(每层), pct(每层), duration(秒,0=战斗内), max_stacks, flags[], eternal, dot{}
func apply_status(src: BUnit, dst: BUnit, cfg: Dictionary, o: Dictionary = {}) -> BStatus:
	if dst == null or not dst.alive:
		return null
	var sid: String = str(cfg.get("status_id", "status"))
	var flg0: Array = cfg.get("flags", [])
	# 免疫负面状态(执剑节点·梦想，未来)：带 debuff 标记的状态一律挂不上(可不可驱散都一样)
	if flg0.has("debuff") and dst.has_flag("debuff_immune_all"):
		b.fx({"t": "immune", "unit": dst, "id": sid})
		return null
	# 队友提供的属性提升类状态 × 倍率(梦想，未来)：施加者是同一队的别人、不是负面状态 → 这一次带来的属性数值都乘上去
	if src != null and src != dst and src.team == dst.team and not flg0.has("debuff"):
		var amp: float = dst.ally_buff_amp()
		if amp != 1.0:
			cfg = amp_stats_cfg(cfg, amp)
	# modify_only：只给已有的状态追加属性/每层回血(不加层、不刷新时间)；状态不在就什么都不做。
	# 用于"被动 2 强化被动 1 的状态"，驱散那个状态时强化一起消失
	if bool(cfg.get("modify_only", false)):
		var st0: BStatus = dst.get_status(sid)
		if st0 == null:
			return null
		_merge_status_stats(st0, cfg, src)
		dst.mark_dirty()
		return st0
	# 免疫可驱散的负面状态(光荣 5 层起)
	var flg: Array = cfg.get("flags", [])
	# 免疫燃烧(龙的余烬)
	if flg.has("burning") and dst.has_flag("burn_immune"):
		return null
	if flg.has("debuff") and flg.has("dispellable") and not flg.has("no_dispel") and dst.has_flag("debuff_immune"):
		b.fx({"t": "immune", "unit": dst, "id": sid})
		return null
	var maxs: int = maxi(1, int(cfg.get("max_stacks", 1)))
	# independent：每次施加都是一个新的实例(不叠加、不刷新、不合并)，实例 id = 状态 id#编号
	var base_sid: String = sid
	if bool(cfg.get("independent", false)):
		sid = "%s#%d" % [sid, b.next_status_serial()]
	# per_source：每个施加者各自维持一份(实例 id = 状态 id@施加者)，同一个状态最多 max_sources 份(天空视野：每只鸟 1 层，最多 3 层)
	if bool(cfg.get("per_source", false)) and src != null:
		sid = "%s@%s" % [base_sid, src.uid]
		if not dst.statuses.has(sid):
			var have := 0
			for st_k: String in dst.statuses.keys():
				if str((dst.statuses[st_k] as BStatus).meta.get("base_id", st_k)) == base_sid:
					have += 1
			if have >= int(cfg.get("max_sources", 1)):
				return null
	var st: BStatus = dst.get_status(sid)
	var created := false
	if st == null:
		st = BStatus.new()
		st.id = sid
		st.stacks = 0
		st.meta["base_id"] = base_sid
		created = true
		dst.statuses[sid] = st
	st.max_stacks = maxs
	var was_capped: bool = st.stacks >= maxs
	var add: int = int(cfg.get("add_stacks", 1))
	# 下一乐章(变奏节点)：想加层但已经叠满了 → 告诉施加者
	if was_capped and maxs > 1 and src != null and src.alive and b.pipeline._listens(src, "OnStackCapped"):
		b.pipeline.emit("OnStackCapped", src, dst, float(st.stacks), ["stack_capped"], {"status_id": base_sid})
	if src != null and maxs > 1:
		add += int(round(src.get_stats().extra_stacks))       # 魔女的火与冰(蓝色武器)：[叠加]状态额外多叠
		# 卡车改装·强效药物：施加者身上有【强效药物】标记时这一次多叠 1 层，然后用掉
		if sid != "potent_dose" and src.statuses.has("potent_dose"):
			add += 1
			end_status(src, "potent_dose")
	var overflow: int = maxi(0, st.stacks + add - maxs) if maxs > 1 else 0
	st.stacks = mini(maxs, st.stacks + add)
	if cfg.has("flags_at"):
		st.meta["flags_at"] = (cfg["flags_at"] as Dictionary).duplicate(true)
	st.source_id = src.uid if src != null else ""
	var dur: float = float(cfg.get("duration", 0.0))
	if cfg.has("duration_by_star"):
		# 持续时间按施加者星级取(虚荣的余烬·煌然：{★3/4/5} 秒)
		var dbs: Dictionary = cfg["duration_by_star"]
		var sk: int = src.star if src != null else 1
		dur = float(dbs.get(str(sk), dbs.get(sk, dur)))
	# 【眩晕】：精英 / 首领从里面恢复的速度加倍(时长减半)
	if dur > 0.0 and (cfg.get("flags", []) as Array).has("stun") and dst.cc_resistant() and not bool(cfg.get("no_cc_halving", false)):
		dur *= 0.5
	# 血色仪式(锁芯节点)：施加者那一队的【眩晕】持续时间 + 活着的【血色仪式】加成之和
	if dur > 0.0 and base_sid == "stun" and src != null:
		dur *= 1.0 + b.stun_amp(src.team)
	# 变天·下雨(导向节点)：所有人被施加的【燃烧】持续时间减半
	if dur > 0.0 and b.weather == "rain" and (flg.has("burning") or base_sid == "burning"):
		dur *= 0.5
	# 【眩晕】再次施加：取剩下的和新的里更长的(短的不会把长的截短)
	var keep: bool = base_sid == "stun" and not created and dur > 0.0 and st.expires_at > b.time + dur
	if not keep:
		st.expires_at = b.time + dur if dur > 0.0 else -1.0
	if base_sid == "stun":
		dst.meta["was_stunned"] = true                # 曾被眩晕过(打开深空之门的目标)
	st.stack_effect = bool(cfg.get("stack_effect", true))
	# 觉醒状态(暗色誓约 / 光色誓约)：先只是挂着，完成觉醒任务后才生效(awaken.stats 在觉醒时并进来；见 Pipeline._evaluate_awakening)
	if cfg.has("awaken") and created:
		st.meta["awaken"] = (cfg["awaken"] as Dictionary).duplicate(true)
		st.meta["awakened"] = false
	# 状态附带的"触发器 + 能力"(光色誓约的濒死回满)：第一次挂上时加到单位身上
	if cfg.has("pairs") and created:
		for pr: Variant in cfg["pairs"]:
			var pd: Dictionary = pr
			var tid: String = str((pd["trigger"] as Dictionary).get("id", ""))
			var dup := false
			for rt: TriggerDef in dst.runtime_triggers:
				if rt.id == tid:
					dup = true
			if dup:
				continue
			dst.runtime_triggers.append(TriggerDef.from_dict(pd["trigger"]))
			dst.runtime_abilities.append(AbilityDef.from_dict(pd["ability"]))
	st.size = float(cfg.get("size", 1.0))
	# 层数阈值加成(stats_at，stats_at_by_star 按施加者星级取)与"被谁取代"(off_with)：见 BUnit.recompute
	if cfg.has("stats_at") or cfg.has("stats_at_by_star"):
		st.meta["stats_at"] = stats_at_of(cfg, src.star if src != null else 1)
	if cfg.has("off_with"):
		st.meta["off_with"] = str(cfg["off_with"])
	if cfg.has("breath"):
		st.meta["breath"] = (cfg["breath"] as Dictionary).duplicate()
	_merge_status_stats(st, cfg, src)
	# 变天·晴天(导向节点)：【寒气】的攻速削减减半(冻结照原来的量算：meta.chill_nominal)
	if flg.has("chill") and b.weather == "sunny" and st.flat_per_stack.has("attack_speed_multiplier"):
		st.meta["chill_nominal"] = -float(st.flat_per_stack["attack_speed_multiplier"])
		st.flat_per_stack["attack_speed_multiplier"] = float(st.flat_per_stack["attack_speed_multiplier"]) * 0.5
	for f: Variant in cfg.get("flags", []):
		if not st.flags.has(str(f)):
			st.flags.append(str(f))
	st.eternal = bool(cfg.get("eternal", false))
	if cfg.has("end_when_shield_above"):
		st.meta["end_when_shield_above"] = float(cfg["end_when_shield_above"])
		if created:
			st.meta["min_until"] = b.time + float(cfg.get("min_duration", 0.0))
	if cfg.has("dot"):
		# 重复施加(刷新持续时间)时不打断持续伤害的节奏：已经在跳的 dot 保留下一跳的时刻
		var next_at: float = float(st.dot.get("next_at", -1.0)) if not created else -1.0
		st.dot = (cfg["dot"] as Dictionary).duplicate(true)
		st.dot["next_at"] = next_at if next_at > 0.0 else b.time + float(st.dot.get("interval", 1.0))
	# 状态附带的规则参数(开枪最快之人：固定普攻间隔、弹匣、换弹时间、远距离打空)：meta 原样抄，meta_by_star 按施加者星级取
	for mk: Variant in (cfg.get("meta", {}) as Dictionary).keys():
		st.meta[str(mk)] = (cfg["meta"] as Dictionary)[mk]
	for mk2: Variant in (cfg.get("meta_by_star", {}) as Dictionary).keys():
		var mb: Dictionary = (cfg["meta_by_star"] as Dictionary)[mk2]
		var msk: int = mini(src.star if src != null else 1, 3)
		st.meta[str(mk2)] = mb.get(str(msk), mb.get(msk, null))
	# 强化普攻(大口径子弹)：接下来 count 次普攻必定暴击、基础伤害 + bonus；再次获得时重置次数
	if cfg.has("empower"):
		st.meta["empower"] = (cfg["empower"] as Dictionary).duplicate(true)
	if bool(cfg.get("burst", false)):
		st.meta["burst"] = true
	if bool(cfg.get("doom", false)):
		st.meta["doom"] = true                       # 到期必定死亡(外神之貌)
	if cfg.has("pulse_interval") or st.meta.has("pulse_interval"):
		if cfg.has("pulse_interval"):
			st.meta["pulse_interval"] = float(cfg["pulse_interval"])
		if created:
			st.meta["pulse_next"] = b.time            # 挂上就先脉冲一次，之后每 pulse_interval 秒一次
	if cfg.has("variant"):
		st.meta["variant"] = str(cfg["variant"])
		st.meta["variant_value"] = float(cfg.get("variant_value", 0.0))
	dst.mark_dirty()
	b.fx({"t": "status", "unit": dst, "id": sid, "base_id": base_sid, "stacks": st.stacks, "created": created, "flags": st.flags, "src": src,
		"variant": str(st.meta.get("variant", "")), "variant_value": float(st.meta.get("variant_value", 0.0))})
	if not was_capped and st.stacks >= maxs and maxs > 1:
		b.pipeline.emit("OnStatusCapReached", dst, src, float(st.stacks), ["status_cap"], {"status_id": sid})
		# 会引爆的状态(剑痕)：叠满当场引爆
		if bool(st.meta.get("burst", false)):
			burst_status(dst, st)
			return null
	# 满层之后还要再加层(光荣 10 层再获得层数 → 投掷)：发 OnStatusOverflow，事件数值 = 溢出的层数
	if overflow > 0:
		b.pipeline.emit("OnStatusOverflow", dst, src, float(overflow), ["status_overflow"], {"status_id": base_sid})
	if st.has_flag("stun") and dst.phase != "dead":
		b.interrupt(dst)
	# 【寒气】：身上所有寒气降低的攻速加起来超过 freeze_over 时全部消耗，变成【冻结】
	if st.has_flag("chill") and st.meta.has("freeze_over"):
		_check_freeze(src, dst, float(st.meta["freeze_over"]), float(st.meta.get("freeze_dur", 5.0)))
	if bool(st.meta.get("misled", false)):
		b.ai.on_misled(dst, st)
	return st


## 把状态配置里的属性数值都 × k(stats / stats_by_star / stat_id 的 flat、pct / stats_at / stats_at_by_star)，其余不动
static func amp_stats_cfg(cfg: Dictionary, k: float) -> Dictionary:
	var c: Dictionary = cfg.duplicate(true)
	for key: String in ["stats", "stats_by_star"]:
		for st: Variant in (c.get(key, {}) as Dictionary).keys():
			_amp_entry((c[key] as Dictionary)[st], k)
	for key2: String in ["stats_at", "stats_at_by_star"]:
		for th: Variant in (c.get(key2, {}) as Dictionary).keys():
			for st2: Variant in ((c[key2] as Dictionary)[th] as Dictionary).keys():
				_amp_entry(((c[key2] as Dictionary)[th] as Dictionary)[st2], k)
	if c.has("stat_id"):
		for m: String in ["flat", "pct"]:
			if c.has(m):
				c[m] = float(c[m]) * k
	return c


static func _amp_entry(e: Dictionary, k: float) -> void:
	for m: Variant in e.keys():
		if e[m] is Dictionary:
			var by: Dictionary = e[m]
			for sk: Variant in by.keys():
				by[sk] = float(by[sk]) * k
		else:
			e[m] = float(e[m]) * k


## 层数阈值加成：cfg.stats_at({"4": {stat: {"flat"|"pct": v}}}) + cfg.stats_at_by_star({"4": {stat: {"flat"|"pct": {"1": v, …}}}}，按星级取，超过 3 星按 3 星)
static func stats_at_of(cfg: Dictionary, star: int) -> Dictionary:
	var r: Dictionary = (cfg.get("stats_at", {}) as Dictionary).duplicate(true)
	var sk: int = mini(maxi(1, star), 3)
	var by: Dictionary = cfg.get("stats_at_by_star", {})
	for th: Variant in by.keys():
		var dst: Dictionary = r.get(str(th), {})
		for stat: Variant in (by[th] as Dictionary).keys():
			var e: Dictionary = (by[th] as Dictionary)[stat]
			var o: Dictionary = dst.get(str(stat), {})
			for mode: Variant in e.keys():
				var bs: Dictionary = e[mode]
				o[str(mode)] = float(bs.get(str(sk), bs.get(sk, 0.0)))
			dst[str(stat)] = o
		r[str(th)] = dst
	return r


## 状态的数值部分：stat_id+flat/pct、stats、stats_by_star(按施加者星级)、hot(每层持续回血，按施加者星级)
func _merge_status_stats(st: BStatus, cfg: Dictionary, src: BUnit) -> void:
	if cfg.has("stat_id"):
		var stat: String = str(cfg["stat_id"])
		if float(cfg.get("flat", 0.0)) != 0.0:
			st.flat_per_stack[stat] = float(cfg["flat"])
		if float(cfg.get("pct", 0.0)) != 0.0:
			st.pct_per_stack[stat] = float(cfg["pct"])
	var star: int = src.star if src != null else 1
	# stats_by_star：{stat: {"flat"|"pct": {"1": v, "2": v, "3": v}}}，按施加者的星级取值(重复施加时以最新一次为准)
	if cfg.has("stats_by_star"):
		for ks: String in (cfg["stats_by_star"] as Dictionary).keys():
			var es: Dictionary = (cfg["stats_by_star"] as Dictionary)[ks]
			for mode: String in ["flat", "pct"]:
				if es.has(mode):
					var byst: Dictionary = es[mode]
					var v: float = float(byst.get(str(star), byst.get(star, 0.0)))
					if mode == "flat":
						st.flat_per_stack[ks] = v
					else:
						st.pct_per_stack[ks] = v
	# accumulate：重复施加时数值累加到同一个状态上(赤焰战旗：每次强化都叠上去，永久)
	var acc: bool = bool(cfg.get("accumulate", false))
	if cfg.has("stats"):
		for k: String in (cfg["stats"] as Dictionary).keys():
			var e: Dictionary = (cfg["stats"] as Dictionary)[k]
			if e.has("flat"):
				st.flat_per_stack[k] = float(e["flat"]) + (float(st.flat_per_stack.get(k, 0.0)) if acc else 0.0)
			if e.has("pct"):
				st.pct_per_stack[k] = float(e["pct"]) + (float(st.pct_per_stack.get(k, 0.0)) if acc else 0.0)
	if cfg.has("hot"):
		var h: Dictionary = cfg["hot"]
		var byst: Dictionary = h.get("pct_by_star", {})
		var pct: float = float(byst.get(str(star), byst.get(star, h.get("pct", 0.0))))
		var keep_next: float = float(st.hot.get("next_at", -1.0))
		st.hot = {"pct": pct, "flat": float(h.get("flat", 0.0)), "interval": float(h.get("interval", 0.5))}
		if bool(h.get("src_heal", false)):
			st.hot["src_heal"] = true                 # 算施加者的治疗(吃她的治疗加成，记进她的治疗量：变奏节点·亢奋)
		st.hot["next_at"] = keep_next if keep_next > 0.0 else b.time + float(st.hot["interval"])


## 通用状态【寒气】：每个独立计时，可驱散，降低攻速 GC.CHILL_AS；加起来超过 GC.FREEZE_OVER 就冻结(见 _check_freeze)
func apply_chill(src: BUnit, dst: BUnit, dur: float, extra_flags: Array = []) -> BStatus:
	var flags: Array = ["debuff", "dispellable", "chill"]
	flags.append_array(extra_flags)
	return apply_status(src, dst, {"status_id": "chill", "duration": dur, "max_stacks": 1, "independent": true, "flags": flags,
		"stats": {"attack_speed_multiplier": {"flat": -GC.CHILL_AS}}, "meta": {"freeze_over": GC.FREEZE_OVER, "freeze_dur": GC.FREEZE_DUR}})


## 通用状态【再生】：每个独立计时，可驱散，每秒回复 GC.REGEN_HPS(× 我方在场调香节点的飘香叠加数，Battle.regen_mult)。
## sid 给了就用这个 id 维持一份(不独立；恒古的常驻再生)
func apply_regen(src: BUnit, dst: BUnit, dur: float, extra_flags: Array = [], sid: String = "") -> BStatus:
	var flags: Array = ["buff", "dispellable", "regen"]
	flags.append_array(extra_flags)
	return apply_status(src, dst, {"status_id": sid if sid != "" else "regen", "duration": dur, "max_stacks": 1, "independent": sid == "",
		"flags": flags, "hot": {"flat": GC.REGEN_HPS, "interval": 0.5}, "meta": {"base_id": "regen"}})


## 寒气 → 冻结：寒气各自独立计时，每个降低一定攻速；加起来超过 over(0.4 = 40%)就全部消耗，冻结 base 秒。
## 冻结 = 眩晕(flag stun)，但精英 / 首领不减半(no_cc_halving)；同一个单位每场战斗每次被冻结的时长减半(5 → 2.5 → 1.25 …)；
## 已经冻着时再冻结 = 叠加持续时间
func _check_freeze(src: BUnit, dst: BUnit, over: float, base: float) -> void:
	var total := 0.0
	var chills: Array[String] = []
	for sid: String in dst.statuses.keys():
		var s: BStatus = dst.statuses[sid]
		if s.has_flag("chill"):
			total += float(s.meta["chill_nominal"]) if s.meta.has("chill_nominal") else -s.total_flat("attack_speed_multiplier")
			chills.append(sid)
	if total <= over + 0.0001:
		return
	for sid2: String in chills:
		end_status(dst, sid2)
	freeze(src, dst, base)


func freeze(src: BUnit, dst: BUnit, base: float) -> void:
	if dst == null or not dst.alive:
		return
	var n: int = int(dst.meta.get("freeze_n", 0))
	dst.meta["freeze_n"] = n + 1
	var dur: float = base * pow(0.5, float(n))
	var cur: BStatus = dst.get_status("frozen")
	if cur != null:
		cur.expires_at = maxf(cur.expires_at, b.time) + dur
		b.fx({"t": "freeze", "unit": dst, "src": src, "duration": dur, "until": cur.expires_at})
		return
	var st: BStatus = apply_status(src, dst, {"status_id": "frozen", "duration": dur, "max_stacks": 1,
		"flags": ["debuff", "dispellable", "stun", "frozen"], "no_cc_halving": true})
	if st != null:
		b.fx({"t": "freeze", "unit": dst, "src": src, "duration": dur, "until": st.expires_at})


## 移除生命上限(龙的余烬在场时的燃烧)：生命上限和当前生命一起减少 amount——不是伤害，不吃魔抗 / 护盾 / 减伤，也治疗不回来。
## 累计在一个不可驱散的负面状态【龙焰灼痕】上；生命扣到 0 就倒下(算施加燃烧的人击杀)
## sid：累计在哪个状态上(默认龙焰灼痕；送葬到期失去生命上限用 funeral_scar)
func wither(src: BUnit, dst: BUnit, amount: float, o: Dictionary = {}, sid: String = "ember_wither") -> void:
	if dst == null or not dst.alive or amount <= 0.0:
		return
	if dst.has_flag("debuff_immune_all"):
		return                                      # 免疫负面状态(梦想，未来)：龙焰灼痕挂不上
	var st: BStatus = dst.get_status(sid)
	if st == null:
		st = BStatus.new()
		st.id = sid
		st.stacks = 1
		st.flags = ["debuff", "no_dispel"]
		st.meta["base_id"] = sid
		st.expires_at = -1.0
		dst.statuses[sid] = st
		b.fx({"t": "status", "unit": dst, "id": sid, "base_id": sid, "stacks": 1, "created": true, "flags": st.flags, "src": src})
	var mh0: float = dst.get_stats().max_health
	var hp0: float = dst.hp
	var cut: float = minf(amount, mh0)
	st.flat_per_stack["max_health"] = float(st.flat_per_stack.get("max_health", 0.0)) - cut
	st.meta["total"] = float(st.meta.get("total", 0.0)) + cut
	dst.mark_dirty()
	var mh: float = dst.get_stats().max_health      # (重算时会按比例缩放当前生命——这里不要，直接减掉同样多)
	dst.hp = minf(hp0 - cut, mh)
	b.fx({"t": "wither", "unit": dst, "src": src, "amount": cut, "ability": str(o.get("ability_id", "")), "surface": str(o.get("surface", "status"))})
	if dst.hp <= 0.0 or mh <= 1.0:
		dst.hp = 0.0
		try_kill(dst, src)


## 生命上限提升 amount(一个只增不减的隐藏状态累计)，提升的那部分立刻回复
func max_health_up(src: BUnit, dst: BUnit, amount: float) -> void:
	if dst == null or not dst.alive or amount <= 0.0:
		return
	var before: float = dst.hp
	var st: BStatus = dst.get_status("max_health_up")
	if st == null:
		st = BStatus.new()
		st.id = "max_health_up"
		st.stacks = 1
		st.flags = ["hidden", "no_dispel"]
		st.meta["base_id"] = "max_health_up"
		dst.statuses["max_health_up"] = st
	st.flat_per_stack["max_health"] = float(st.flat_per_stack.get("max_health", 0.0)) + amount
	dst.mark_dirty()
	dst.get_stats()
	dst.hp = minf(dst.get_stats().max_health, before + amount)
	b.fx({"t": "max_hp_up", "unit": dst, "src": src, "amount": amount})


## 驱散：去掉目标身上最多 count 个可驱散(dispellable)的状态。what = "buff"(驱散增益，对敌人用) / "debuff"(净化负面，对友军用)。
## order = "longest"：剩余持续时间最长的先驱散(永久的算最长)；默认按状态 id 顺序。
## 带 dispel_one 标记的状态(虚荣)每次只去掉 1 层，层数归零才结束；其余状态整个去掉。返回实际驱散了几次
func dispel(src: BUnit, dst: BUnit, what: String = "buff", count: int = 1, order: String = "") -> int:
	if dst == null or not dst.alive or count <= 0:
		return 0
	var sids: Array = dispellable(dst, what)
	if order == "longest":
		var rem := func(sid: Variant) -> float:
			var st0: BStatus = dst.statuses[sid]
			return 1.0e9 if st0.expires_at < 0.0 else st0.expires_at - b.time
		sids.sort_custom(func(x: Variant, y: Variant) -> bool:
			var rx: float = rem.call(x)
			var ry: float = rem.call(y)
			return rx > ry or (rx == ry and str(x) < str(y)))
	var done := 0
	for sid: Variant in sids:
		if done >= count:
			break
		var st: BStatus = dst.statuses.get(sid, null) as BStatus
		if st == null:
			continue
		done += 1
		if st.has_flag("dispel_one") and st.stacks > 1:
			st.stacks -= 1
			dst.mark_dirty()
			b.fx({"t": "status", "unit": dst, "id": str(sid), "base_id": str(st.meta.get("base_id", sid)), "stacks": st.stacks, "created": false,
				"flags": st.flags, "src": src, "dispelled": true})
		else:
			end_status(dst, str(sid))
	if done > 0:
		b.fx({"t": "dispel", "unit": dst, "src": src, "count": done, "what": what})
	return done


## 身上可以被驱散的状态 id(按 id 排序)。what = "buff" / "debuff"
func dispellable(u: BUnit, what: String = "debuff") -> Array:
	var out: Array = []
	var sids: Array = u.statuses.keys()
	sids.sort()
	for sid: Variant in sids:
		var st: BStatus = u.statuses[sid]
		if not st.has_flag("dispellable") or st.has_flag("no_dispel"):
			continue
		if (what == "buff") == st.has_flag("debuff"):
			continue
		out.append(sid)
	return out


func remove_status(u: BUnit, sid: String) -> void:
	if u.statuses.has(sid):
		u.statuses.erase(sid)
		u.mark_dirty()
		b.fx({"t": "status", "unit": u, "id": sid, "stacks": 0, "created": false, "flags": []})


# ---------------------------------------------------------------- 地形
## 在 pos 创造一块地形(例如稻田 / 增幅力场)：不能被选中、不能被破坏、不分阵营；amount = 这块地形的效果值
## (稻田：每次回复的额外固定值；增幅力场 kind = amp：场内单位被动技能的增幅 +amount)
func create_field(src: BUnit, pos: Vector2, cfg: Dictionary, amount: float) -> void:
	var kind: String = str(cfg.get("kind", "paddy"))
	var f := {"kind": kind, "pos": pos, "radius": float(cfg.get("radius", 1.2)),
		"until": b.time + float(cfg.get("duration", 8.0)), "heal_bonus": amount if kind == "paddy" else 0.0,
		"amp": amount if kind == "amp" else 0.0, "src": src}
	b.add_field(f)


# ---------------------------------------------------------------- 嘲讽 / 位移 / 召唤
func taunt(src: BUnit, radius: float, duration: float) -> void:
	for u: BUnit in b.units:
		if not u.alive or u.team == src.team:
			continue
		if radius <= 0.0 or u.pos.distance_to(src.pos) <= radius + u.radius:
			u.forced_target = src
			u.forced_until = b.time + duration
			u.target = src
	b.fx({"t": "taunt", "unit": src, "radius": radius})


## 冲锋斩(狼狩)：挑一个"落地后身边一圈能砍到最多敌人"的位置，沿直线冲过去(无视碰撞体积，冲锋中不受 AI 控制)，
## 落地时由 Pipeline.dash_arrive 对身边至多 N 个敌人([群攻 N]，最近的优先)造成 amount 伤害。
## 候选落点 = 敌人位置 / 两两中点 / 每三个的重心(推出障碍物、夹进场地后评分)：先比能砍到几个(最多 N 个算满)，再比身边总共有几个，再比近
func dash_strike(src: BUnit, ability: AbilityDef, amount: float, o: Dictionary) -> void:
	var enemies: Array[BUnit] = b.enemies_of(src)
	if enemies.is_empty() or src.phase == "dash":
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var rad: float = float(cfg.get("radius", 1.9))
	var n: int = maxi(1, Pipeline.kw_value(src, ability, "multi_attack", 1))
	var cands: Array[Vector2] = []
	for i in range(enemies.size()):
		cands.append(enemies[i].pos)
		for j in range(i + 1, enemies.size()):
			cands.append((enemies[i].pos + enemies[j].pos) * 0.5)
			for k in range(j + 1, enemies.size()):
				cands.append((enemies[i].pos + enemies[j].pos + enemies[k].pos) / 3.0)
	var best: Vector2 = src.pos
	var best_score := -1.0e9
	for c: Vector2 in cands:
		var p: Vector2 = b.map.push_out(b.clamp_to_arena(c, src.radius), src.radius)
		var ds: Array[float] = []
		for e: BUnit in enemies:
			var de: float = e.pos.distance_to(p)
			if de <= rad + e.radius:
				ds.append(de)
		ds.sort()
		var cnt: int = ds.size()
		var near_sum := 0.0
		for q in range(mini(cnt, n)):
			near_sum += ds[q]
		# 同样能砍到的人数里：落点离要砍的那几个越近越好(落在人堆中间)，其次离自己近
		var score: float = float(mini(cnt, n)) * 1000.0 + float(cnt) * 10.0 - near_sum - p.distance_to(src.pos) * 0.05
		if score > best_score:
			best_score = score
			best = p
	var from: Vector2 = src.pos
	var dist: float = from.distance_to(best)
	var dur: float = clampf(dist / float(cfg.get("speed", 15.0)), 0.12, 0.5)
	b.interrupt(src)
	src.phase = "dash"
	src.vel = Vector2.ZERO
	if dist > 0.05:
		src.facing = atan2(best.x - from.x, best.y - from.y)
	var od: Dictionary = o.duplicate()
	od["can_crit"] = ability.has_keyword("crit")
	src.meta["dash"] = {"from": from, "to": best, "t0": b.time, "dur": dur, "amount": amount, "radius": rad, "n": n,
		"ability": ability, "o": od, "kind": str(cfg.get("damage_kind", "physical"))}
	b.fx({"t": "dash_start", "unit": src, "from": from, "to": best, "dur": dur})


## 护送冲刺(舞与歌)：朝敌人那边直线冲刺 distance 米，同时把同伴(我方的 partner 单位，最近的那个)拉到身边一起冲；
## 落地后(Pipeline.dash_arrive)同伴获得 增幅 × dr_per_amp 的伤害减免，并嘲讽大范围内的敌人
func escort_dash(src: BUnit, ability: AbilityDef, o: Dictionary) -> void:
	if src.phase == "dash":
		return
	var cfg: Dictionary = o.get("cfg", ability.effect_config)
	var enemies: Array[BUnit] = b.enemies_of(src)
	var dir := Vector2(0.0, 1.0 if src.team == GC.TEAM_PLAYER else -1.0)
	if not enemies.is_empty():
		var c := Vector2.ZERO
		for e: BUnit in enemies:
			c += e.pos
		c /= float(enemies.size())
		if c.distance_to(src.pos) > 0.3:
			dir = (c - src.pos).normalized()
	var dist: float = float(cfg.get("distance", 3.5))
	var to: Vector2 = b.map.push_out(b.clamp_to_arena(src.pos + dir * dist, src.radius), src.radius)
	var partner: BUnit = null
	var best := 1.0e9
	for u: BUnit in b.units:
		if u.alive and u.team == src.team and u.def.id == str(cfg.get("partner", "")) and u.pos.distance_to(src.pos) < best:
			best = u.pos.distance_to(src.pos)
			partner = u
	var dur: float = clampf(src.pos.distance_to(to) / float(cfg.get("speed", 9.0)), 0.15, 0.6)
	var amp: int = Pipeline.kw_value(src, ability, "amplify", 0)
	b.interrupt(src)
	src.phase = "dash"
	src.vel = Vector2.ZERO
	src.facing = atan2(dir.x, dir.y)
	src.meta["dash"] = {"from": src.pos, "to": to, "t0": b.time, "dur": dur, "escort": partner,
		"escort_dr": float(amp) * float(cfg.get("dr_per_amp", 0.05)), "escort_status": str(cfg.get("status_id", "idol_guard")),
		"taunt_radius": float(cfg.get("taunt_radius", 5.0)), "taunt_duration": float(cfg.get("taunt_duration", 3.0))}
	b.fx({"t": "dash_start", "unit": src, "from": src.pos, "to": to, "dur": dur, "escort": true})
	if partner != null and partner.phase != "dash":
		# 同伴站在她身边(朝前方向的右侧)，同时冲过去
		var side := Vector2(dir.y, -dir.x) * (src.radius + partner.radius + 0.15)
		var pto: Vector2 = b.map.push_out(b.clamp_to_arena(to + side, partner.radius), partner.radius)
		b.interrupt(partner)
		partner.phase = "dash"
		partner.vel = Vector2.ZERO
		partner.facing = src.facing
		partner.meta["dash"] = {"from": partner.pos, "to": pto, "t0": b.time, "dur": dur, "quiet": true}
		b.fx({"t": "dash_start", "unit": partner, "from": partner.pos, "to": pto, "dur": dur, "escort": true})


func blink_best_cleave(src: BUnit, max_dist: float, cleave_radius: float) -> void:
	var best: Vector2 = src.pos
	var best_score := -1.0
	var enemies: Array[BUnit] = b.enemies_of(src)
	if enemies.is_empty():
		return
	for i in range(24):
		var ang: float = TAU * float(i) / 24.0
		for dist_f: float in [0.5, 1.0]:
			var p: Vector2 = src.pos + Vector2(sin(ang), cos(ang)) * max_dist * dist_f
			p = b.clamp_to_arena(p, src.radius)
			if b.position_blocked(p, src.radius, src):
				continue
			var score := 0.0
			for e: BUnit in enemies:
				if e.pos.distance_to(p) <= cleave_radius + e.radius:
					score += 1.0
			score -= p.distance_to(src.pos) * 0.01   # 同分优先近的
			if score > best_score:
				best_score = score
				best = p
	if best != src.pos:
		var from: Vector2 = src.pos
		src.pos = best
		b.fx({"t": "blink", "unit": src, "from": from, "to": best})


## 召唤者给召唤物加的星级(魔典：作为召唤者时视为 +1 星)
static func summon_star_bonus(src: BUnit) -> int:
	return int(round(src.get_stats().summon_star_bonus)) if src != null else 0


## 召唤一个到指定的位置(幻灵节点：目标背后的幽灵 / 目标脚下的幽灵犬)。meta 在 OnSummoned 之前并进去(no_spectral / feral / leash / first_hit_bonus)；
## target = 一出来就盯着它打
func summon_one(src: BUnit, uid: String, pos: Vector2, meta: Dictionary = {}, target: BUnit = null) -> BUnit:
	var def: UnitDef = b.catalog.get_unit(uid)
	if def == null or src == null:
		return null
	var star: int = mini(GC.MAX_SUMMON_STAR, src.star + summon_star_bonus(src))
	var nu: BUnit = b.spawn_unit(def, src.team, star, b.clamp_to_arena(pos, def.radius), true)
	nu.meta["summoner"] = src
	nu.meta["summoners"] = [src]
	nu.meta.merge(meta, true)
	if target != null and target.alive:
		nu.target = target
		nu.attack_target = target
		var dv: Vector2 = target.pos - nu.pos
		if dv.length() > 0.01:
			nu.facing = atan2(dv.x, dv.y)
	b.fx({"t": "summon", "unit": nu, "summoner": src, "spectral": not bool(meta.get("no_spectral", false))})
	b.pipeline.emit("OnSummonCompleted", src, nu, 1.0, ["summon_completed"], {"summoned": nu})
	b.pipeline.emit("OnSummoned", nu, src, 1.0, ["summoned"], {"summoner": src})
	return nu


func summon(src: BUnit, cfg: Dictionary, o: Dictionary = {}) -> Array[BUnit]:
	var made: Array[BUnit] = []
	var uid: String = str(cfg.get("unit_id", ""))
	# unit_pool：从几种单位里随机召唤一种(傲慢的余烬召唤小怪)
	var pool: Array = cfg.get("unit_pool", [])
	if not pool.is_empty():
		uid = str(pool[b.rng.randi() % pool.size()])
	# max_alive：自己召唤的、还活着的同类召唤物(召唤池里的任何一种)最多这么多个
	if int(cfg.get("max_alive", 0)) > 0:
		var ids: Array = pool if not pool.is_empty() else [uid]
		var alive_n := 0
		for su: BUnit in b.units:
			if su.alive and su.is_summon and su.summoner() == src and ids.has(su.def.id):
				alive_n += 1
		if alive_n >= int(cfg["max_alive"]):
			return made
	var def: UnitDef = b.catalog.get_unit(uid)
	if def == null:
		return made
	var count: int = maxi(1, int(cfg.get("count", 1)))
	var star: int = mini(GC.MAX_SUMMON_STAR, src.star + summon_star_bonus(src)) if bool(cfg.get("inherit_star", true)) else 1
	# 共享召唤(护星节点)：我方场上已经有了就不再召唤，而是把自己的星级加给它(它同时算所有尝试召唤它的人的召唤物)，最高 9 星
	if bool(cfg.get("shared", false)):
		for ex: BUnit in b.units:
			if ex.alive and ex.team == src.team and ex.def.id == uid:
				var old: int = ex.star
				ex.star = mini(GC.MAX_SUMMON_STAR, ex.star + src.star)
				ex.base = ex.def.stats_for_star(ex.star)      # 基础数值按新星级重新缩放
				(ex.meta.get_or_add("summoners", []) as Array).append(src)
				if ex.star != old:
					var ratio: float = ex.hp_ratio()
					ex.mark_dirty()
					ex.recompute()
					ex.hp = ex.get_stats().max_health * ratio
					b.fx({"t": "summon_star", "unit": ex, "summoner": src, "star": ex.star})
				return made
	for i in range(count):
		var offset: Vector2 = Vector2.ZERO
		var placement: String = str(cfg.get("placement", "near"))
		var dir_x: float = 1.0 if src.team == GC.TEAM_PLAYER else -1.0
		match placement:
			"behind":
				offset = Vector2(-dir_x * 1.3, (float(i) - float(count - 1) * 0.5) * 1.2)
			"front":
				offset = Vector2(dir_x * 1.3, (float(i) - float(count - 1) * 0.5) * 1.2)
			_:
				offset = Vector2(0.0, 1.3 if (i % 2 == 0) else -1.3)
		var pos: Vector2 = b.find_free_position(src.pos + offset, def.radius, src)
		var nu: BUnit = b.spawn_unit(def, src.team, star, pos, true)
		nu.meta["summoner"] = src
		nu.meta["summoners"] = [src]
		made.append(nu)
		b.fx({"t": "summon", "unit": nu, "summoner": src})
		b.pipeline.emit("OnSummonCompleted", src, nu, 1.0, ["summon_completed"], {"summoned": nu})
		b.pipeline.emit("OnSummoned", nu, src, 1.0, ["summoned"], {"summoner": src})
	return made
