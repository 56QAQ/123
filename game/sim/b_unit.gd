class_name BUnit
extends RefCounted
## 战斗中的棋子实例(纯逻辑，无节点)。位置为连续坐标 Vector2(x, z)，单位米。

var uid: String = ""
var def: UnitDef
var team: int = 0
var star: int = 1
var alive: bool = true
var is_summon: bool = false
var roster_id: String = ""                 # 对应玩家花名册实例(用于永恒成长回写)
var spawn_time: float = 0.0

# ---- 数值
var base: StatBlock                        # 星级缩放后的基础值
var stats: StatBlock                       # 当前有效值(基础+装备+羁绊+状态)
var perm_flat: Dictionary = {}             # 永恒成长(来自花名册)
var trait_flat: Dictionary = {}            # trait_id -> {stat: v}
var trait_pct: Dictionary = {}
var _dirty: bool = true

# ---- 生命
var hp: float = 1.0
var shield: float = 0.0
var shield_peak: float = 0.0

# ---- 武器(= 装备)
var weapon: EquipmentDef = null            # 手里的武器：装备的武器或基础武器；null = 空手(不能攻击)

# ---- 触发/能力运行时状态
var runtime_triggers: Array[TriggerDef] = []     # 羁绊/遗物挂上来的触发器
var runtime_abilities: Array[AbilityDef] = []
var counters: Dictionary = {}              # trigger_id -> 已计事件数
var trig_cd: Dictionary = {}               # trigger_id -> 可再次触发的时间
var trig_acts: Dictionary = {}             # trigger_id -> 本场已触发次数
var ability_cd: Dictionary = {}
var ability_charges: Dictionary = {}
var learning: Dictionary = {}              # ability_id -> 学习计数
var awakened: Dictionary = {}              # awakening_key -> true
var awakening_progress: Dictionary = {}
var statuses: Dictionary = {}              # status_id -> BStatus
var hits_since_reload: int = -1            # 上次装弹完成后的普攻命中次数(-1 = 这场还没装过弹)
var meta: Dictionary = {}

# ---- 空间 / AI
var pos: Vector2 = Vector2.ZERO
var prev_pos: Vector2 = Vector2.ZERO
var prev_facing: float = 0.0
var vel: Vector2 = Vector2.ZERO
var facing: float = 0.0                    # 朝向角：atan2(dx, dz)，0 = 面向 +z
var radius: float = 0.42
var base_radius: float = 0.42             # 数据里的半径；状态改体型时 radius = base_radius × 体型倍率
var target: BUnit = null
var forced_target: BUnit = null
var forced_until: float = 0.0
var last_target_check: float = -10.0
var attack_cd: float = 0.0
var phase: String = "idle"                 # idle / windup / recover / chant / stun
var phase_t: float = 0.0
var phase_dur: float = 0.0
var recover_dur: float = 0.0
var attack_target: BUnit = null
var attack_copy_of: BUnit = null
var attack_variant: String = ""           # 这一下普攻的招式："" 普通 / "multi" 群攻招式(贯穿/旋斩)
var draw_dur: float = 0.0                 # 普攻载荷 [吟唱] 的拉弓时长(秒)
var rest_after_release: float = 0.0       # 出手后这一轮攻击还剩的时间(拉弓插在出手之前，出手后照常走完)
var chant_until: float = 0.0
var chant_ability: AbilityDef = null
var chant_event: Dictionary = {}
var move_goal: Vector2 = Vector2.ZERO
var anchor: Vector2 = Vector2.ZERO         # 开局格子位置
var cast_windup: float = 0.0

# ---- 战斗统计
var st_damage: float = 0.0
var st_taken: float = 0.0
var st_heal: float = 0.0
var st_shield: float = 0.0
var st_kills: int = 0
var st_dmg_by_kind: Dictionary = {"physical": 0.0, "magic": 0.0, "true": 0.0}
var st_dmg_by_surface: Dictionary = {}


func setup(p_def: UnitDef, p_team: int, p_star: int, p_uid: String) -> BUnit:
	def = p_def
	team = p_team
	star = maxi(1, p_star)
	uid = p_uid
	base = def.stats_for_star(star)
	radius = def.radius
	base_radius = def.radius
	stats = base.duplicate_block()
	_dirty = true
	recompute()
	hp = stats.max_health
	return self


## 换武器(null = 空手)。武器大类决定射程/攻击间隔/普攻倍率，所以要重算数值
func set_weapon(e: EquipmentDef) -> void:
	weapon = e
	_dirty = true


func weapon_class() -> String:
	return weapon.class_id if weapon != null else ""


## 武器大类参数(GC.WEAPON_CLASSES)；空手返回 {}
var engaged: bool = false              # 近战已经贴上目标(在射程内)：站定对着它打——不被分离力推开、碰撞时更"重"、不随便换目标、朝向一直对着目标
var _wc_cache: Dictionary = {}
var _wc_for: String = ""


## 武器大类参数；单位数据 wclass_overrides 里写了这类武器的节奏就并进去(炽照节点的拔刀连斩：间隔 / 出手时刻 / 追击副本的间隔)；
## 变身形态(守林节点：状态 meta.wclass_form)最后并进去——攻击形态与所携带的武器无关
func wclass() -> Dictionary:
	if weapon == null:
		return {}
	var ov: Dictionary = def.wclass_overrides.get(weapon.class_id, {})
	var fo: Dictionary = form_override()
	if ov.is_empty() and fo.is_empty():
		return weapon.wclass()
	var key: String = weapon.id + "|" + str(fo.get("form", ""))
	if _wc_for != key:
		_wc_cache = weapon.wclass().duplicate()
		_wc_cache.merge(ov, true)
		_wc_cache.merge(fo, true)
		_wc_for = key
	return _wc_cache


## 变身形态的攻击模组(守林节点：狮子 / 巨蜘蛛 / 巨蟾蜍；状态 meta.wclass_form)；不在形态里 = {}
func form_override() -> Dictionary:
	for st: BStatus in statuses.values():
		if st.stacks > 0 and st.meta.has("wclass_form"):
			return st.meta["wclass_form"]
	return {}


func can_attack() -> bool:
	return weapon != null


func is_ranged() -> bool:
	return weapon != null and bool(wclass().get("ranged", false))      # 单位自己的 wclass_overrides 算进去(清扫节点的飞刀)


## AI 风格：由单位职业 + 手里的武器决定
func style() -> String:
	# 射程被改到近战长度的远程武器(如攻击范围归零的电击器)按近战走位：贴上去打，不风筝
	return def.style_for_weapon(is_ranged() and get_stats().range_meters() >= 1.0)


## 参与配对的装备载荷：只有装备的(非基础)武器带效果
func active_payload_equipment() -> Array[EquipmentDef]:
	var r: Array[EquipmentDef] = []
	if weapon != null and not weapon.basic and not weapon.abilities.is_empty():
		r.append(weapon)
	return r


func mark_dirty() -> void:
	_dirty = true


func recompute() -> void:
	var s: StatBlock = base.duplicate_block()
	# 射程与基础攻击间隔来自武器大类(间隔 = 普攻动画模组时长)；空手没有有效射程
	var wc: Dictionary = wclass()
	s.attack_range = float(wc.get("range", 0.0))
	s.attack_base_interval_seconds = float(wc.get("interval", 1.0))
	var flat := {}
	var pct := {}
	for k: String in perm_flat.keys():
		flat[k] = float(flat.get(k, 0.0)) + float(perm_flat[k])
	if weapon != null:
		for k2: String in weapon.flat_mods.keys():
			flat[k2] = float(flat.get(k2, 0.0)) + float(weapon.flat_mods[k2])
		for k3: String in weapon.pct_mods.keys():
			pct[k3] = float(pct.get(k3, 0.0)) + float(weapon.pct_mods[k3])
	for tid: String in trait_flat.keys():
		for k4: String in (trait_flat[tid] as Dictionary).keys():
			flat[k4] = float(flat.get(k4, 0.0)) + float((trait_flat[tid] as Dictionary)[k4])
	for tid2: String in trait_pct.keys():
		for k5: String in (trait_pct[tid2] as Dictionary).keys():
			pct[k5] = float(pct.get(k5, 0.0)) + float((trait_pct[tid2] as Dictionary)[k5])
	var size := 1.0
	for sid: String in statuses.keys():
		var st: BStatus = statuses[sid]
		size *= st.size if st.stacks > 0 else 1.0
		# 被另一个状态取代时不再提供数值(正行节点：有【花】= 满层的花瓣加成，花瓣自己的加成不再另算)
		if st.meta.has("off_with") and status_stacks(str(st.meta["off_with"])) > 0:
			continue
		for k6: String in st.flat_per_stack.keys():
			flat[k6] = float(flat.get(k6, 0.0)) + st.total_flat(k6)
		for k7: String in st.pct_per_stack.keys():
			pct[k7] = float(pct.get(k7, 0.0)) + st.total_pct(k7)
		# 层数到了阈值才有的加成(花瓣：4 层起生命上限，8 层起护甲与魔抗)：{"4": {stat: {"flat"|"pct": v}}}，不随层数再叠
		if st.meta.has("stats_at"):
			var sat: Dictionary = st.meta["stats_at"]
			for th: Variant in sat.keys():
				if st.stacks < int(th):
					continue
				for k8: Variant in (sat[th] as Dictionary).keys():
					var e8: Dictionary = (sat[th] as Dictionary)[k8]
					if e8.has("flat"):
						flat[str(k8)] = float(flat.get(str(k8), 0.0)) + float(e8["flat"])
					if e8.has("pct"):
						pct[str(k8)] = float(pct.get(str(k8), 0.0)) + float(e8["pct"])
	for id: String in GC.STAT_IDS:
		var b: float = float(s.get(id))
		var f: float = float(flat.get(id, 0.0))
		var p: float = float(pct.get(id, 0.0))
		s.set(id, (b + f) * (1.0 + p))
	# 暴击率跟着治疗量加成走(监护人的智与力)
	if s.crit_from_healing > 0.0:
		s.crit_chance += s.healing_done_pct * s.crit_from_healing
	# 暴击率溢出转暴击伤害(屏息节点·集中呼吸：超过 100% 的部分 × 2 加到暴击伤害上)
	if s.crit_overflow_cd > 0.0 and s.crit_chance > 1.0:
		s.crit_damage += (s.crit_chance - 1.0) * s.crit_overflow_cd
		s.crit_chance = 1.0
	# 生命上限变化时按比例保持当前生命
	if stats != null and hp > 0.0 and stats.max_health > 0.0 and absf(s.max_health - stats.max_health) > 0.001:
		hp = clampf(hp * s.max_health / stats.max_health, 1.0, s.max_health)
	stats = s
	radius = base_radius * size
	_dirty = false


func get_stats() -> StatBlock:
	if _dirty:
		recompute()
	return stats


func hp_ratio() -> float:
	return hp / maxf(1.0, get_stats().max_health)


func all_triggers() -> Array[TriggerDef]:
	var r: Array[TriggerDef] = []
	for t: TriggerDef in def.triggers:
		if t.unlock_star <= star:
			r.append(t)
	r.append_array(runtime_triggers)
	# 普攻也是"触发器+能力"：单位自带 OnNormalAttackPerform 触发器，触发数值 = 攻击力 × 武器大类的普攻倍率
	if weapon != null:
		var fo: Dictionary = form_override()
		if not fo.is_empty():
			# 变身形态：普攻触发器按形态的大类 / 取值方式(狮子：以生命值计算) / 倍率
			r.append(Pipeline.na_trigger(str(fo.get("na_class", "sword")), str(fo.get("na_scaling", "")), float(fo.get("na_mult", 1.0))))
			return r
		var own_mult: bool = def.wclass_overrides.has(weapon.class_id) or weapon.wclass_override.has("na_mult")
		r.append(Pipeline.na_trigger(weapon.class_id, def.na_scaling, float(wclass().get("na_mult", -1.0)) if own_mult else -1.0))
	return r


## 所有可被触发器配对的能力(被动 + 普攻载荷 + 武器效果载荷 + 羁绊/遗物能力)。
## 返回 [{ability, surface, equip}]
func all_ability_entries() -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for a: AbilityDef in def.passives:
		if a.unlock_star <= star:
			r.append({"ability": a, "surface": "passive", "equip": null})
	# 普攻载荷由武器提供(武器大类的伤害类型)；单位可用自定义普攻(如护士的治疗)替换效果。空手没有普攻载荷。
	if weapon != null:
		r.append({"ability": na_payload(), "surface": "normal_attack", "equip": null})
	for e: EquipmentDef in active_payload_equipment():
		for a2: AbilityDef in e.abilities:
			r.append({"ability": a2, "surface": "equipment", "equip": e})
	for a3: AbilityDef in runtime_abilities:
		var surf := "trait"
		if a3.required_trigger_tags.has("relic_payload"):
			surf = "relic"
		elif a3.required_trigger_tags.has("terrain_payload"):
			surf = "terrain"
		r.append({"ability": a3, "surface": surf, "equip": null})
	return r


## 普攻载荷：单位的自定义普攻(如护士的治疗)，否则是武器大类的默认普攻(带这个大类自带的关键词)；空手 null
func na_payload() -> AbilityDef:
	if weapon == null:
		return null
	if def.normal_attack != null:
		return def.normal_attack
	# 变身形态：按形态的大类(伤害类型)和形态自己的普攻关键词(狮子的【追击】)
	var fo: Dictionary = form_override()
	if not fo.is_empty():
		return Pipeline.na_ability_for(str(fo.get("na_class", "sword")), fo.get("na_keywords", {}))
	# 单位自己的 wclass_overrides(嫉妒的余烬的射线：法器但不溅射)或武器自己(黑色战场：弹匣【叠加 1】)改了这类武器的普攻关键词
	var ov: Dictionary = def.wclass_overrides.get(weapon.class_id, {})
	var kw: Variant = null
	if ov.has("na_keywords") or weapon.wclass_override.has("na_keywords"):
		kw = wclass()["na_keywords"]
	# 瞄准眉心(屏息节点)：普攻额外带【吟唱】= 被动的吟唱数(弓照常先拉弓，之后再瞄)
	var aim: AbilityDef = aim_passive()
	if aim != null:
		var nk: Dictionary = ((kw if kw != null else wclass().get("na_keywords", {})) as Dictionary).duplicate()
		nk["chant"] = int(nk.get("chant", 0)) + Pipeline.kw_value(self, aim, "chant", 0)
		kw = nk
	# 逆时幻影(无我节点)：普攻会连续攻击——额外带【追击 N】(规则状态 meta.na_pursuit)
	var np: Variant = Pipeline.status_meta(self, "na_pursuit")
	if np != null and int(np) > 0:
		var nk3: Dictionary = ((kw if kw != null else wclass().get("na_keywords", {})) as Dictionary).duplicate()
		nk3["pursuit"] = int(nk3.get("pursuit", 0)) + int(np)
		kw = nk3
	# 引雷(导向节点)：普攻需要吟唱——额外带【吟唱 N】(规则状态 meta.na_chant)，拉满 = ×2(和弓的拉弓同一套)
	var nc: Variant = Pipeline.status_meta(self, "na_chant")
	if nc != null:
		var nk2: Dictionary = ((kw if kw != null else wclass().get("na_keywords", {})) as Dictionary).duplicate()
		nk2["chant"] = int(nk2.get("chant", 0)) + int(nc)
		kw = nk2
	if kw != null:
		return Pipeline.na_ability_for(weapon.class_id, kw)
	return Pipeline.na_ability_for(weapon.class_id)


## 连锁闪电普攻(导向节点·引雷：规则状态 meta.na_chain = {bounces_by_star, radius})；没有 = {}
func chain_cfg() -> Dictionary:
	var c: Variant = Pipeline.status_meta(self, "na_chain")
	return c if c is Dictionary else {}


## 普攻前再瞄准的被动(单位数据 na_aim；屏息节点·瞄准眉心)；没有 / 星级不够 = null
func aim_passive() -> AbilityDef:
	if def.na_aim == "":
		return null
	for a: AbilityDef in def.passives:
		if a.id == def.na_aim and a.unlock_star <= star:
			return a
	return null


func is_enemy_of(o: BUnit) -> bool:
	return o != null and o.team != team


# ---------------------------------------------------------------- 状态
func get_status(id: String) -> BStatus:
	return statuses.get(id, null) as BStatus


func status_stacks(id: String) -> int:
	var s: BStatus = statuses.get(id, null) as BStatus
	return s.stacks if s != null else 0


## 某种状态的全部实例(每次施加独立的状态，如【燃烧】，实例 id = 状态 id#编号)
func status_instances(base_id: String) -> Array[BStatus]:
	var r: Array[BStatus] = []
	for sid: String in statuses.keys():
		var st: BStatus = statuses[sid]
		if sid == base_id or str(st.meta.get("base_id", "")) == base_id:
			r.append(st)
	return r


func status_count(base_id: String) -> int:
	return status_instances(base_id).size()


## 被视为谁的召唤物(真正的召唤物，或守誓节点绑定的稀有度 5 棋子)；没有 = null
func summoner() -> BUnit:
	var s: Variant = meta.get("summoner", null)
	return s as BUnit if s is BUnit else null


## 身上任何一个状态带着这个标记
func has_status_flag(f: String) -> bool:
	for st: BStatus in statuses.values():
		if st.stacks > 0 and st.has_flag(f):
			return true
	return false


## 龙息(虚荣)：普攻变成一条射线 {width 宽度(米), length 从自己中心算起的长度(米)}；没有 = {}
func breath_cfg() -> Dictionary:
	for st: BStatus in statuses.values():
		if st.stacks > 0 and st.has_flag("na_breath"):
			return st.meta.get("breath", {"width": 2.0, "length": 7.0})
	return {}


## 花蕊(正行节点)：普攻变成一道大范围的锥形光刃 / 光炮 {angle 张角(度), length 从自己中心算起的长度(米), passive 读【群攻 N】的被动}，
## 状态 meta.cone_scale = 这一下造成原普攻的几倍；没有 = {}
func cone_cfg() -> Dictionary:
	for st: BStatus in statuses.values():
		if st.stacks > 0 and st.meta.has("cone"):
			var c: Dictionary = (st.meta["cone"] as Dictionary).duplicate()
			c["scale"] = float(st.meta.get("cone_scale", 1.0))
			return c
	return {}


## 队友提供的属性提升类状态的倍率(执剑节点·梦想，未来：状态 meta.ally_buff_amp)；没有 = 1
func ally_buff_amp() -> float:
	var k := 1.0
	for st: BStatus in statuses.values():
		if st.stacks > 0 and st.meta.has("ally_buff_amp"):
			k = maxf(k, float(st.meta["ally_buff_amp"]))
	return k


## 普通怪物：怪物(mob_ 开头的单位，包括被召唤出来的小怪)，而且不是精英 / 首领(执剑节点·勇者，圣剑直接击杀)
func is_common_monster() -> bool:
	return def.id.begins_with("mob_") and not bool(meta.get("elite", false)) and not bool(meta.get("boss", false))


## 体型倍率(直径)：给表现层缩放模型用
func size_mult() -> float:
	return radius / maxf(0.01, base_radius)


func has_flag(flag: String) -> bool:
	for id: String in statuses.keys():
		if (statuses[id] as BStatus).has_flag(flag):
			return true
	return false


func is_stunned() -> bool:
	return has_flag("stun")


## 精英 / 首领：免疫自相残杀(误导)，从眩晕里恢复得快一倍
func cc_resistant() -> bool:
	return bool(meta.get("elite", false)) or bool(meta.get("boss", false))


## 身上的【误导】(meta.misled)；没有 = null
func misled_status() -> BStatus:
	for st: BStatus in statuses.values():
		if bool(st.meta.get("misled", false)):
			return st
	return null


func is_disarmed() -> bool:
	return has_flag("disarm") or has_flag("stun")
