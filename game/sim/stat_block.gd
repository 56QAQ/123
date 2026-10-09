class_name StatBlock
extends RefCounted
## 单位数值块 + 伤害/治疗公式(公式与源项目 stat_block.gd 一致)。

var attack_power: float = 10.0
var ability_power: float = 0.0
var defense: float = 0.0
var magic_resistance: float = 0.0
var max_health: float = 100.0
var health_regen_per_second: float = 0.0
var physical_lifesteal: float = 0.0
var spell_lifesteal: float = 0.0
var omnivamp: float = 0.0
var crit_chance: float = 0.0
var crit_damage: float = 1.5
var physical_flat_penetration: float = 0.0
var physical_percent_penetration: float = 0.0
var magic_flat_penetration: float = 0.0
var magic_percent_penetration: float = 0.0
var move_speed: float = 1.0
var attack_base_interval_seconds: float = 1.0
var attack_speed_multiplier: float = 1.0
var attack_range: float = 1.0
var damage_dealt_pct: float = 0.0          # 伤害增幅(通用)：进伤害增幅乘区(amp_sum)
var damage_dealt_flat: float = 0.0
var damage_taken_pct: float = 0.0          # 伤害减免(百分比)：正数 = 受到的伤害减少(上限 GC.MAX_DAMAGE_TAKEN_PCT = 90%)，负数 = 受到的伤害增加。名字里的 taken 指"承受"，不是"增加"
var damage_taken_flat: float = 0.0
var healing_done_pct: float = 0.0
var healing_received_pct: float = 0.0
var reload_time_pct: float = 0.0
var shield_received_pct: float = 0.0
var na_damage_taken_flat: float = 0.0
var damage_taken_amp: float = 0.0
var na_dodge: float = 0.0
var backstab_amp: float = 0.0
var haste: float = 0.0
var na_damage_per_ap_pct: float = 0.0
var aoe_hit_amp_pct: float = 0.0
var extra_stacks: float = 0.0
var final_dmg_reduction: float = 0.0
var crit_from_healing: float = 0.0
var crit_overflow_cd: float = 0.0
var burn_to_heal: float = 0.0
var na_ally_heal_pct: float = 0.0
var na_bonus_magic_pct: float = 0.0
var passive_amplify_bonus: float = 0.0
var passive_charges_bonus: float = 0.0
var summon_star_bonus: float = 0.0
var full_draw_extra_targets: float = 0.0
var dot_taken_flat: float = 0.0
var na_skill_flat_damage: float = 0.0
var na_mult_pct: float = 0.0            # 普攻倍率加成(卡车改装·锐利武装)
var physical_damage_pct: float = 0.0
var magic_damage_pct: float = 0.0
var true_damage_pct: float = 0.0
var na_damage_pct: float = 0.0
var skill_damage_pct: float = 0.0
var dot_damage_pct: float = 0.0
var amp_efficacy: float = 0.0            # 伤害增幅效能：自己的伤害增幅乘区(amp_sum)× (1 + 它)(沉沦之梦)
var dr_efficacy: float = 0.0             # 伤害减免效能：自己的伤害减免(damage_taken_pct，正负都算)× (1 + 它)(沉沦之梦)


static func from_dict(d: Dictionary) -> StatBlock:
	var s := StatBlock.new()
	for id: String in GC.STAT_IDS:
		if d.has(id):
			s.set(id, float(d[id]))
	return s


func get_stat(id: String) -> float:
	if id in GC.STAT_IDS:
		return float(get(id))
	return 0.0


func set_stat(id: String, value: float) -> void:
	if id in GC.STAT_IDS:
		set(id, value)


func duplicate_block() -> StatBlock:
	var s := StatBlock.new()
	for id: String in GC.STAT_IDS:
		s.set(id, get(id))
	return s


func to_dict() -> Dictionary:
	var d := {}
	for id: String in GC.STAT_IDS:
		d[id] = get(id)
	return d


## 星级缩放：只缩放 STAR_SCALING_STATS
func scaled_for_star(star: int, scaling: Array = GC.STAR_SCALING_STATS) -> StatBlock:
	var s := duplicate_block()
	var m: float = GC.star_mult(star)
	for id: Variant in scaling:
		s.set(str(id), float(get(str(id))) * m)
	return s


func attack_interval() -> float:
	return maxf(0.08, attack_base_interval_seconds / maxf(0.05, attack_speed_multiplier))


func range_meters() -> float:
	return attack_range * GC.RANGE_UNIT


func speed_mps() -> float:
	return maxf(0.0, move_speed) * GC.SPEED_UNIT


## 攻击方视角伤害：raw + 固定增伤 → 暴击 → 百分比增伤；再走目标减伤。
## kind: physical / magic / true。crit_roll<crit_chance 则暴击。
func calc_damage_against(target: StatBlock, raw: float, kind: String, can_crit: bool, crit_roll: float, cfg: Dictionary = {}) -> Dictionary:
	var amount: float = maxf(0.0, raw + damage_dealt_flat)
	var crit := false
	var cc: float = clampf(crit_chance + float(cfg.get("crit_chance_bonus", 0.0)), 0.0, 1.0)
	if can_crit and crit_roll < cc:
		amount *= maxf(1.0, crit_damage + float(cfg.get("crit_damage_bonus", 0.0)))
		crit = true
	amount *= maxf(0.0, 1.0 + amp_sum(kind, cfg) * amp_eff() + target.damage_taken_amp)      # 目标的易伤(标定)和攻击者的增幅同一个乘区
	if bool(cfg.get("ignore_target_mitigation", false)) or kind == "true":
		return {"amount": maxf(0.0, amount), "crit": crit, "pre": maxf(0.0, amount)}
	var pre: float = maxf(0.0, amount)          # 目标的护甲 / 魔抗 / 减伤之前(战报的"减免"从这里算)
	amount *= _resist_factor(target, kind, cfg)
	amount *= maxf(0.0, 1.0 - minf(target.dr_total(), GC.MAX_DAMAGE_TAKEN_PCT))
	amount -= maxf(0.0, target.damage_taken_flat)
	return {"amount": maxf(0.0, amount), "crit": crit, "pre": pre}


## 只算"能提升伤害"的部分(护理节点·广义治疗的最终伤害值)：固定增伤、暴击、百分比增伤、目标的易伤(受伤修正为负)；
## 护甲 / 魔抗、减伤、施加者的负面增伤这些会减少伤害的一概不算
func calc_damage_boosts_only(target: StatBlock, raw: float, can_crit: bool, crit_roll: float, cfg: Dictionary = {}) -> Dictionary:
	var amount: float = maxf(0.0, raw + maxf(0.0, damage_dealt_flat))
	var crit := false
	var cc: float = clampf(crit_chance + float(cfg.get("crit_chance_bonus", 0.0)), 0.0, 1.0)
	if can_crit and crit_roll < cc:
		amount *= maxf(1.0, crit_damage + float(cfg.get("crit_damage_bonus", 0.0)))
		crit = true
	amount *= 1.0 + maxf(0.0, amp_sum(_kind_of(cfg), cfg) * amp_eff() + target.damage_taken_amp)
	amount *= 1.0 - minf(0.0, target.dr_total())
	amount += maxf(0.0, -target.damage_taken_flat)
	return {"amount": amount, "crit": crit}


func _resist_factor(target: StatBlock, kind: String, cfg: Dictionary) -> float:
	if kind == "physical":
		var fp: float = physical_flat_penetration + float(cfg.get("flat_penetration_bonus", 0.0))
		var pp: float = physical_percent_penetration + float(cfg.get("percent_penetration_bonus", 0.0))
		var eff: float = maxf(0.0, target.defense * (1.0 - clampf(pp, 0.0, 1.0)) - maxf(0.0, fp))
		return 100.0 / (100.0 + eff)
	if kind == "magic":
		var fm: float = magic_flat_penetration + float(cfg.get("flat_penetration_bonus", 0.0))
		var pm: float = magic_percent_penetration + float(cfg.get("percent_penetration_bonus", 0.0))
		var effm: float = maxf(0.0, target.magic_resistance * (1.0 - clampf(pm, 0.0, 1.0)) - maxf(0.0, fm))
		return 100.0 / (100.0 + effm)
	return 1.0


## dual = 同时享受物理和魔法伤害的好处(成品完工的真实伤害)：两种吸血都算
func calc_lifesteal(damage: float, kind: String, dual: bool = false) -> float:
	var rate: float = omnivamp
	if kind == "physical" or dual:
		rate += physical_lifesteal
	if kind == "magic" or dual:
		rate += spell_lifesteal
	return maxf(0.0, damage) * maxf(0.0, rate)


## 伤害增幅效能的倍率(1 + amp_efficacy，不低于 0)
func amp_eff() -> float:
	return maxf(0.0, 1.0 + amp_efficacy)


## 实际的伤害减免 = damage_taken_pct × (1 + 伤害减免效能)(负的伤害减免也一起放大)
func dr_total() -> float:
	return damage_taken_pct * maxf(0.0, 1.0 + dr_efficacy)


## 伤害增幅乘区(同一个乘区里全部加起来)：通用增伤 + 伤害类型的增幅 + 伤害分类的增幅(cfg.category：normal_attack / skill / dot)
## + cfg.amp_bonus(针对这个目标的增伤：猎人笔记；飞刀停顿的增伤：完美时计)
func amp_sum(kind: String, cfg: Dictionary = {}) -> float:
	var s: float = damage_dealt_pct + kind_amp(kind, cfg) + float(cfg.get("amp_bonus", 0.0))
	match str(cfg.get("category", "")):
		"normal_attack":
			s += na_damage_pct + na_damage_per_ap_pct * maxf(0.0, ability_power)     # 知识轰炸：每点法强 +x 普攻伤害
		"skill":
			s += skill_damage_pct
		"dot":
			s += dot_damage_pct
	return s


## 按伤害类型的增幅：物理 / 魔法 / 真实各加各的；cfg.dual_kind(成品完工的真实伤害)= 真实 + 物理 + 魔法都加
func kind_amp(kind: String, cfg: Dictionary = {}) -> float:
	if bool(cfg.get("dual_kind", false)):
		return true_damage_pct + physical_damage_pct + magic_damage_pct
	if kind == "physical":
		return physical_damage_pct
	if kind == "magic":
		return magic_damage_pct
	if kind == "true":
		return true_damage_pct
	return 0.0


static func _kind_of(cfg: Dictionary) -> String:
	return str(cfg.get("kind", ""))


func calc_heal(target: StatBlock, base_heal: float) -> float:
	return maxf(0.0, base_heal) * maxf(0.0, 1.0 + healing_done_pct) * maxf(0.0, 1.0 + target.healing_received_pct)
